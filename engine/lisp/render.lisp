;;;; render.lisp — 3D renderer on SDL_GPU (WebGPU backend): meshes, camera, lit shader, draw queue,
;;;; fx batch, post (bloom). Frame: (platform-poll) → (begin-frame) → set camera / draw-mesh /
;;;; add-point-light / fx-* / ui-* → (end-frame). Draws are queued and recorded in END-FRAME by one
;;;; C call (r_frame, engine/c/render.c): copy pass → scene pass (MSAA) → bloom passes → composite + UI → submit.
(in-package :engine)

;;; C side: engine/c/render.c (r_init, r_make_pipe, r_mesh_new, r_frame, r_timing). Never call a
;;; blocking SDL_GPU function (WaitAndAcquire..., WaitForGPUFences/Idle): they spin and need
;;; ASYNCIFY/JSPI, which ECL's setjmp/longjmp rule out. See docs/ARCHITECTURE.md.

;;; ---------------------------------------------------------------- shaders (WGSL)
;;; Every shader program is a file in engine/shaders/ (*.vert.wgsl, *.frag.wgsl; plain *.wgsl files
;;; are shared pieces). (WGSL "lit.frag.wgsl") reads it at COMPILE time and expands to the final
;;; source string: a line `// #include "frame.wgsl"` is replaced by that file (same directory), and
;;; all // comments and blank lines are dropped.
;;; Why drop comments: SDL_GPU's WebGPU backend derives bind group layouts by scanning each shader's
;;; source text (it counts "var<storage", "var<uniform>", ": sampler;" and reads @group/@binding), so
;;; every stage gets its own source that declares only that stage's bindings: vertex storage = group 0,
;;; vertex uniforms = group 1, fragment textures/samplers = group 2, fragment uniforms = group 3.
;;; Comments never reach it, but don't put 'sampler' / 'read' / 'write' in binding names.
;;; Relative paths are resolved against *DEFAULT-PATHNAME-DEFAULTS* = the project root (tools/build.lisp).
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun read-wgsl (path)
    "The text of WGSL file PATH for SDL: each line `// #include \"F\"` is replaced by the text of
file F (same directory, recursively), every // comment is removed, and so are blank lines."
    (with-output-to-string (out)
      (with-open-file (in path)
        (loop with inc = "// #include \""
              for line = (read-line in nil) while line
              for code = (string-right-trim " " (subseq line 0 (search "//" line)))
              do (cond ((eql 0 (search inc (string-left-trim " " line)))
                        (let* ((l (string-left-trim " " line))
                               (name (subseq l (length inc) (position #\" l :start (length inc)))))
                          (write-string (read-wgsl (merge-pathnames name path)) out)))
                       ((plusp (length code)) (write-line code out))))))))

(defmacro wgsl (file)
  "Compile-time: the source string of engine/shaders/FILE (includes resolved, comments stripped)."
  (read-wgsl (merge-pathnames file "engine/shaders/")))

(defun make-pipeline (slot vs vs-entry fs fs-entry layout target depth blend cull)
  "Compile a pipeline into C slot SLOT; see r_make_pipe (render.c) for the encoding."
  (unless (ffi:c-inline (slot (coerce vs 'base-string) (coerce vs-entry 'base-string) (coerce fs 'base-string)
                              (coerce fs-entry 'base-string) layout target depth blend cull)
                        (:int :cstring :cstring :cstring :cstring :int :int :int :int :int) :bool
                        "r_make_pipe(#0,#1,#2,#3,#4,#5,#6,#7,#8,#9)" :one-liner t)
    (error "render: pipeline ~a/~a failed (see log above)" vs-entry fs-entry)))

;;; ---------------------------------------------------------------- mesh
(defconstant +vertex-floats+ 9 "Mesh vertex: position xyz, normal xyz, color rgb (sRGB 0..1).")

(defstruct (mesh (:constructor %make-mesh))
  (id 0 :type fixnum)                       ; index into the renderer's C mesh table
  (count 0 :type fixnum))                   ; vertices (3 per triangle)

(defun make-mesh (data nfloats)
  "Upload NFLOATS of interleaved vertex DATA (9 floats per vertex) as an immutable mesh."
  (declare (type f32vec data) (fixnum nfloats))
  (let* ((n (floor nfloats +vertex-floats+))
         (id (ffi:c-inline (data n) (t :int) :int "r_mesh_new(#0->vector.self.sf,#1)" :one-liner t)))
    (when (< id 0) (error "render: out of mesh vertex buffers"))
    (%make-mesh :id id :count n)))

;;; ---------------------------------------------------------------- camera
(defstruct (camera (:constructor make-camera ()))
  (pos (v3 0 3 8) :type f32vec)
  (target (v3 0 1 0) :type f32vec)
  (up (v3 0 1 0) :type f32vec)
  (shake (v3 0 0 0) :type f32vec)          ; world offset added to pos and target (screen shake)
  (fov (deg 60) :type single-float)        ; vertical, radians
  (near 0.1f0 :type single-float)
  (far 400f0 :type single-float)
  ;; derived by UPDATE-CAMERA
  (eye (make-f32 3) :type f32vec)           ; pos + shake
  (right (v3 1 0 0) :type f32vec)           ; world-space camera axes
  (upv (v3 0 1 0) :type f32vec)
  (forward (v3 0 0 -1) :type f32vec)
  (view (m4) :type f32vec) (proj (m4) :type f32vec)
  (view-proj (m4) :type f32vec) (inv-view-proj (m4) :type f32vec))

(defvar *camera* (make-camera))
(defvar *cam-tmp* (make-f32 3))

(defun update-camera ()
  "Recompute derived vectors and matrices. Call after moving the camera, before fx-* calls."
  (let* ((cam *camera*) (eye (camera-eye cam)) (tgt *cam-tmp*) (v (camera-view cam)))
    (v3-add! eye (camera-pos cam) (camera-shake cam))
    (v3-add! tgt (camera-target cam) (camera-shake cam))
    (m4-look-at! v eye tgt (camera-up cam))
    (v3-set! (camera-right cam) (aref v 0) (aref v 4) (aref v 8))
    (v3-set! (camera-upv cam) (aref v 1) (aref v 5) (aref v 9))
    (v3-set! (camera-forward cam) (- (aref v 2)) (- (aref v 6)) (- (aref v 10)))
    (m4-perspective! (camera-proj cam) (camera-fov cam) (window-aspect) (camera-near cam) (camera-far cam))
    (m4-mul! (camera-view-proj cam) (camera-proj cam) v)
    (m4-invert! (camera-inv-view-proj cam) (camera-view-proj cam))
    cam))

(defun camera-look-at (px py pz tx ty tz)
  "Place the camera and update it."
  (v3-set! (camera-pos *camera*) (f32 px) (f32 py) (f32 pz))
  (v3-set! (camera-target *camera*) (f32 tx) (f32 ty) (f32 tz))
  (update-camera))

(defun-fast world-to-screen (out x y z)
  "Project world point to framebuffer pixels: OUT[0]=x, OUT[1]=y (top-left origin), OUT[2]=depth (0 near .. 1 far).
Returns T if the point is in front of the camera."
  (declare (type f32vec out) (single-float x y z))
  (let ((m (camera-view-proj *camera*)))
    (declare (type f32vec m))
    (let* ((cx (+ (* (aref m 0) x) (* (aref m 4) y) (* (aref m 8) z) (aref m 12)))
           (cy (+ (* (aref m 1) x) (* (aref m 5) y) (* (aref m 9) z) (aref m 13)))
           (cz (+ (* (aref m 2) x) (* (aref m 6) y) (* (aref m 10) z) (aref m 14)))
           (cw (+ (* (aref m 3) x) (* (aref m 7) y) (* (aref m 11) z) (aref m 15))))
      (declare (single-float cx cy cz cw))
      (when (> cw 1f-5)
        (setf (aref out 0) (* (+ (/ cx cw) 1f0) 0.5f0 (float (window-width) 1f0))
              (aref out 1) (* (- 1f0 (/ cy cw)) 0.5f0 (float (window-height) 1f0))
              (aref out 2) (/ cz cw))
        t))))

;;; ---------------------------------------------------------------- environment (look)
(defstruct (environment (:conc-name env-))
  ;; all colors sRGB 0..1; intensities multiply them
  (sky-top (v3 0.035 0.03 0.10) :type f32vec)       ; zenith
  (fog-color (v3 0.20 0.13 0.34) :type f32vec)      ; fog + horizon
  (fog-density 0.028f0 :type single-float)          ; per meter
  (fog-base 0f0 :type single-float)                 ; fog is densest below this height
  (fog-falloff 0.08f0 :type single-float)           ; per meter above base
  (fog-max 1f0 :type single-float)
  (ambient-sky (v3 0.30 0.30 0.55) :type f32vec)
  (ambient-ground (v3 0.12 0.07 0.14) :type f32vec)
  (ambient-intensity 0.45f0 :type single-float)
  (moon-dir (v3-normalize (v3 -0.35 0.55 -0.75)) :type f32vec) ; direction TO the moon
  (moon-color (v3 0.65 0.72 1.0) :type f32vec)
  (moon-intensity 0.5f0 :type single-float)
  (rim-color (v3 0.35 0.55 1.0) :type f32vec)
  (rim-intensity 0.35f0 :type single-float)
  (rim-power 3f0 :type single-float)
  (specular 0.5f0 :type single-float)               ; wet-surface highlight strength (0 = matte)
  (shininess 48f0 :type single-float)
  (exposure 1.2f0 :type single-float)
  (bloom t)
  (bloom-threshold 0.62f0 :type single-float)       ; on tonemapped color, 0..1
  (bloom-strength 0.9f0 :type single-float)
  (vignette 0.35f0 :type single-float))

(defvar *env* (make-environment))
(defvar *render-scale* 1f0 "Offscreen scene resolution relative to the window.")
(defvar *auto-render-scale* nil
  "T: dynamic quality. When frames average over *FRAME-BUDGET-MS*, lower *RENDER-SCALE* in 0.1 steps
down to *RENDER-SCALE-MIN*, then *PIXEL-LIGHTS* to 3 and 1; raise it back when there is headroom
(hysteresis + backoff, see r_timing). Off by default (keeps screenshots deterministic).")
(defvar *auto-level* 0)
(defvar *render-scale-min* 0.7f0)
(defvar *frame-budget-ms* 18f0 "Target frame time for *AUTO-RENDER-SCALE* (60 Hz + slack).")
(defvar *pixel-lights* 8
  "Point lights shaded per pixel (0..8, nearest the camera target first); the others are shaded per
vertex (Gouraud: cheap, but light pools on big low-poly faces blur out). Fill-rate knob for weak GPUs.")
(defvar *perf-log* nil "T: log a perf line (startup, frame time, render scale) every ~5 s.")


;;; ---------------------------------------------------------------- state
(defconstant +dq-stride+ 28 "Draw record floats = WGSL struct Draw (uploaded as is).")
(defconstant +max-lights+ 8)
(defconstant +max-light-candidates+ 64)
(defconstant +fu-floats+ 136 "Frame uniform floats = WGSL struct Frame.")
(declaim (type f32vec *dq* *light-cand* *lp* *lc* *fu* *rp*) (type fixnum *dq-n* *light-n* *draw-count* *tri-count*))
(defvar *dq* (make-f32 (* +dq-stride+ 512)))
(defvar *dq-n* 0)
(defvar *light-cand* (make-f32 (* 8 +max-light-candidates+)))  ; x y z radius r g b score
(defvar *light-n* 0)
(defvar *lp* (make-f32 (* 4 +max-lights+)))
(defvar *lc* (make-f32 (* 4 +max-lights+)))
(defvar *fu* (make-f32 +fu-floats+) "Frame uniforms, filled by FILL-FRAME-UNIFORMS.")
(defvar *rp* (make-f32 8) "r_frame parameters (see r_frame).")
(defvar *draw-count* 0 "Mesh draws issued last frame.")
(defvar *tri-count* 0 "Mesh triangles drawn last frame.")
(defvar *fx-alpha*) (defvar *fx-add*) (defvar *ui-batch*)
(defvar *fx-dropped* 0)

;;; Dynamic vertex batch: filled on the CPU each frame, uploaded and drawn by END-FRAME.
(defstruct (stream-buffer (:constructor %make-stream-buffer))
  (stride 0 :type fixnum)                 ; floats per vertex
  (data (make-f32 0) :type f32vec)        ; CPU staging
  (fill 0 :type fixnum))                  ; floats written this frame

(defun make-stream-buffer (stride max-vertices)
  (%make-stream-buffer :stride stride :data (make-f32 (* stride max-vertices))))

(defun stream-room-p (sb nverts)
  (<= (+ (stream-buffer-fill sb) (* nverts (stream-buffer-stride sb))) (length (stream-buffer-data sb))))

(defun render-init (msaa)
  (unless (ffi:c-inline (msaa) (:int) :bool "r_init(#0)" :one-liner t)
    (error "render: no SDL_GPU device (WebGPU unavailable?)"))
  (let ((lit-vs (wgsl "lit.vert.wgsl")) (lit-fs (wgsl "lit.frag.wgsl"))
        (tri (wgsl "fullscreen.vert.wgsl")) (fx-vs (wgsl "fx.vert.wgsl")) (fx-fs (wgsl "fx.frag.wgsl")))
    ;; slot vs entry fs entry layout target depth blend cull   (enum order in render.c)
    (make-pipeline 0 lit-vs "vs_main" lit-fs "fs_main" #x333 0 1 0 1)       ; RP_LIT
    (make-pipeline 1 lit-vs "vs_main" lit-fs "fs_main" #x333 0 1 0 2)       ; RP_LIT_CW (mirrored)
    (make-pipeline 2 lit-vs "vs_main" lit-fs "fs_main" #x333 0 2 1 1)       ; RP_LIT_T (alpha < 1)
    (make-pipeline 3 lit-vs "vs_main" lit-fs "fs_main" #x333 0 2 1 2)       ; RP_LIT_T_CW
    (make-pipeline 4 tri "vs_tri" (wgsl "sky.frag.wgsl") "fs_sky" 0 0 0 0 0)            ; RP_SKY
    (make-pipeline 5 fx-vs "vs_fx" fx-fs "fs_fx_alpha" #x324 0 2 1 0)       ; RP_FXA
    (make-pipeline 6 fx-vs "vs_fx" fx-fs "fs_fx_add" #x324 0 2 2 0)         ; RP_FXB
    (make-pipeline 7 tri "vs_tri" (wgsl "bright.frag.wgsl") "fs_bright" 0 1 0 0 0)      ; RP_BRIGHT
    (make-pipeline 8 tri "vs_tri" (wgsl "blur.frag.wgsl") "fs_blur" 0 1 0 0 0)          ; RP_BLUR
    (make-pipeline 9 tri "vs_tri" (wgsl "composite.frag.wgsl") "fs_comp" 0 2 0 0 0))    ; RP_COMP (RP_UI: ui.lisp)
  (setf *fx-alpha* (make-stream-buffer 9 16384)
        *fx-add* (make-stream-buffer 9 16384)))

(defun engine-init (&key (title "game") (msaa 4))
  "Platform + renderer + UI. MSAA (1 or 4) applies to the offscreen scene target."
  (platform-init :title title)
  (render-init msaa)
  (ui-init))

;;; ---------------------------------------------------------------- frame API
(defun begin-frame ()
  "Reset per-frame queues. Call once per frame after PLATFORM-POLL."
  (setf *dq-n* 0 *light-n* 0
        (stream-buffer-fill *fx-alpha*) 0 (stream-buffer-fill *fx-add*) 0 (stream-buffer-fill *ui-batch*) 0)
  (update-camera))

;; macros, not inline defuns: an inline defun boxes its float argument before the c-inline
(defmacro srgb->lin (c) `(ffi:c-inline (,c) (:float) :float "powf(fmaxf(#0,0.0f),2.2f)" :one-liner t))

(defun-fast draw-mesh (mesh model &key tint (emissive 0f0) (flash 0f0) (alpha 1f0) (specular -1f0) rim)
  "Queue MESH with world matrix MODEL (mat4, copied). TINT: (r g b) list/vector multiplies vertex
colors. EMISSIVE: self-illumination (0 = lit only, 1..4 = glowing neon). FLASH: 0..1 lerp to white.
ALPHA < 1 draws in the transparent pass (after opaque, no depth write).
SPECULAR: wet-highlight strength for this draw (0 = matte, skips the specular math);
negative (default) = (env-specular *env*).
RIM: f32vec of 3 LINEAR rgb floats (strength baked in) added as a (1-N.V)^3 rim light (silhouettes)."
  (declare (type f32vec model))
  (unless (mesh-p mesh) (error 'type-error :datum mesh :expected-type 'mesh))
  (let* ((n *dq-n*) (q *dq*))
    (declare (fixnum n) (type f32vec q))
    (when (> (* (1+ n) +dq-stride+) (length q))
      (setf q (replace (make-f32 (* 2 (length q))) q) *dq* q))
    ;; record = WGSL Draw: [0..15 model][16..19 tint rgba][20 emissive 21 flash 22 specular 23 mesh id][24..26 rim, 27 unused]
    (let* ((o (* n +dq-stride+)))
      (declare (fixnum o))
      (replace q model :start1 o :end1 (+ o 16))
      (if tint
          (setf (aref q (+ o 16)) (srgb->lin (elt tint 0))
                (aref q (+ o 17)) (srgb->lin (elt tint 1))
                (aref q (+ o 18)) (srgb->lin (elt tint 2)))
          (setf (aref q (+ o 16)) 1f0 (aref q (+ o 17)) 1f0 (aref q (+ o 18)) 1f0))
      (setf (aref q (+ o 19)) (f32 alpha) (aref q (+ o 20)) (f32 emissive) (aref q (+ o 21)) (f32 flash)
            (aref q (+ o 22)) (f32 specular) (aref q (+ o 23)) (float (mesh-id mesh) 1f0) (aref q (+ o 27)) 0f0)
      (if rim
          (let ((rv rim)) (declare (type f32vec rv))
            (setf (aref q (+ o 24)) (aref rv 0) (aref q (+ o 25)) (aref rv 1) (aref q (+ o 26)) (aref rv 2)))
          (setf (aref q (+ o 24)) 0f0 (aref q (+ o 25)) 0f0 (aref q (+ o 26)) 0f0))
      (setf *dq-n* (1+ n))
      nil)))

(defmacro %add-light (x y z r g b radius k)
  "Body shared by the ADD-POINT-LIGHT variants (a macro: an inline defun-fast re-checked and boxed its args)."
  `(let* ((x ,x) (y ,y) (z ,z) (r ,r) (g ,g) (b ,b) (radius ,radius) (k ,k) (n *light-n*) (c *light-cand*))
     (declare (single-float x y z r g b radius k) (fixnum n) (type f32vec c))
     (when (and (< n +max-light-candidates+) (> k 0f0) (> radius 0f0))   ; dark lights take no slot
       (let* ((o (* n 8)) (tg (camera-target *camera*))
              (dx (- x (aref tg 0))) (dy (- y (aref tg 1))) (dz (- z (aref tg 2))))
         (declare (fixnum o) (single-float dx dy dz) (type f32vec tg))
         (setf (aref c o) x (aref c (+ o 1)) y (aref c (+ o 2)) z (aref c (+ o 3)) radius
               (aref c (+ o 4)) (* k (srgb->lin r)) (aref c (+ o 5)) (* k (srgb->lin g))
               (aref c (+ o 6)) (* k (srgb->lin b))
               (aref c (+ o 7)) (- (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz))) radius))
         (setf *light-n* (1+ n))))
     nil))

(defun-fast add-point-light (x y z r g b radius &optional (intensity 1f0))
  "Point light for this frame only (call every frame). Up to 8 are used; when more are added,
the ones nearest the camera target win. Color sRGB, RADIUS meters (light reaches 0 there).
Each float argument is boxed at the call site; hot callers can use ADD-POINT-LIGHT-V."
  (%add-light (f32 x) (f32 y) (f32 z) (f32 r) (f32 g) (f32 b) (f32 radius) (f32 intensity)))

(defun-fast add-point-light-v (v &optional (offset 0))
  "ADD-POINT-LIGHT reading 8 floats x y z r g b radius intensity from f32vec V at OFFSET.
Conses nothing: keep one f32vec of light records and update intensities in place."
  (declare (type f32vec v) (fixnum offset))
  (%add-light (aref v offset) (aref v (+ offset 1)) (aref v (+ offset 2)) (aref v (+ offset 3))
              (aref v (+ offset 4)) (aref v (+ offset 5)) (aref v (+ offset 6)) (aref v (+ offset 7))))

(defun-fast select-lights ()
  "Pick up to 8 best candidates into *LP*/*LC*; returns count. Lights whose sphere lies outside the
view frustum light no visible pixel, so they are dropped first (each costs a full shader loop pass)."
  (let* ((c *light-cand*) (n *light-n*) (k 0) (lp *lp*) (lc *lc*) (m (camera-view-proj *camera*)))
    (declare (fixnum n k) (type f32vec c lp lc m))
    (dotimes (i n)
      (let* ((o (* i 8)) (x (aref c o)) (y (aref c (+ o 1))) (z (aref c (+ o 2))) (r (aref c (+ o 3))))
        (declare (fixnum o) (single-float x y z r))
        (dotimes (j 3)                  ; planes row3 +/- row j (Gribb-Hartmann), column-major M; for z, row3+row2 is a looser near plane than the [0,1] one (row2): harmless
          (dolist (sg '(1f0 -1f0))
            (let* ((sg sg) (pa (+ (aref m 3) (* sg (aref m j)))) (pb (+ (aref m 7) (* sg (aref m (+ 4 j)))))
                   (pc (+ (aref m 11) (* sg (aref m (+ 8 j))))) (pd (+ (aref m 15) (* sg (aref m (+ 12 j))))))
              (declare (single-float sg pa pb pc pd))
              (when (< (+ (* pa x) (* pb y) (* pc z) pd) (- (* r (f-sqrt (+ (* pa pa) (* pb pb) (* pc pc))))))
                (setf (aref c (+ o 7)) most-positive-single-float)))))))
    (loop while (and (< k +max-lights+) (< k n)) do
      (let* ((best -1) (bs most-positive-single-float))
        (declare (fixnum best) (single-float bs))
        (dotimes (i n)
          (let* ((s (aref c (+ (* i 8) 7))))
            (when (< s bs) (setf bs s best i))))
        (when (< best 0) (return))
        (let* ((o (* best 8)) (d (* k 4)))
          (declare (fixnum o d))
          (dotimes (j 4) (setf (aref lp (+ d j)) (aref c (+ o j))))
          (dotimes (j 3) (setf (aref lc (+ d j)) (aref c (+ o 4 j))))
          (let* ((r (aref c (+ o 3))))
            (declare (single-float r))
            (setf (aref lc (+ d 3)) (/ 1f0 (* r r)) (aref c (+ o 7)) most-positive-single-float))
          (incf k))))
    k))

;;; ---------------------------------------------------------------- frame uniforms
(defun-fast fill-frame-uniforms (nl)
  "Write the WGSL Frame struct into *FU* (NL = point lights used)."
  (declare (fixnum nl))
  (let* ((u *fu*) (e *env*) (cam *camera*) (eye (camera-eye cam)))
    (declare (type f32vec u eye))
    (macrolet ((lin3 (o v k w)          ; u[o..o+3] = k * linear(v), w
                 `(let* ((v ,v) (k ,k))
                    (declare (type f32vec v) (single-float k))
                    (setf (aref u ,o) (* k (srgb->lin (aref v 0))) (aref u (+ ,o 1)) (* k (srgb->lin (aref v 1)))
                          (aref u (+ ,o 2)) (* k (srgb->lin (aref v 2))) (aref u (+ ,o 3)) ,w))))
      (replace u (camera-view-proj cam) :start1 0)
      (replace u (camera-inv-view-proj cam) :start1 16)
      (setf (aref u 32) (aref eye 0) (aref u 33) (aref eye 1) (aref u 34) (aref eye 2) (aref u 35) (env-exposure e))
      (lin3 36 (env-fog-color e) 1f0 (env-fog-density e))
      (setf (aref u 40) (env-fog-base e) (aref u 41) (env-fog-falloff e) (aref u 42) (env-fog-max e) (aref u 43) 0f0)
      (lin3 44 (env-ambient-sky e) (env-ambient-intensity e) 0f0)
      (lin3 48 (env-ambient-ground e) (env-ambient-intensity e) 0f0)
      (let* ((d (env-moon-dir e))) (declare (type f32vec d))
        (setf (aref u 52) (aref d 0) (aref u 53) (aref d 1) (aref u 54) (aref d 2) (aref u 55) 0f0))
      (lin3 56 (env-moon-color e) (env-moon-intensity e) 0f0)
      (lin3 60 (env-rim-color e) (env-rim-intensity e) (env-rim-power e))
      (lin3 64 (env-sky-top e) 1f0 0f0)
      (setf (aref u 68) (env-specular e) (aref u 69) (env-shininess e)
            (aref u 70) (ffi:c-inline (nl) (:int) :float "(float)(#0)" :one-liner t)
            (aref u 71) (ffi:c-inline ((min +max-lights+ (max 0 (the fixnum *pixel-lights*)))) (:int) :float "(float)(#0)" :one-liner t))
      (replace u *lp* :start1 72)
      (replace u *lc* :start1 104)
      u)))

(defun end-frame ()
  "Render everything queued this frame (scene → fx → post → UI) and present."
  (update-camera)
  (fill-frame-uniforms (select-lights))
  (let* ((e *env*) (p *rp*) (ww (window-width)) (wh (window-height)))
    (declare (type f32vec p))
    (setf (aref p 0) (if (env-bloom e) 1f0 0f0) (aref p 1) (env-bloom-threshold e) (aref p 2) (env-bloom-strength e)
          (aref p 3) (env-vignette e)
          (aref p 4) (f32 (max 1 (round (* ww *render-scale*)))) (aref p 5) (f32 (max 1 (round (* wh *render-scale*))))
          (aref p 6) (f32 ww) (aref p 7) (f32 wh))
    (let* ((fa *fx-alpha*) (fb *fx-add*) (ui *ui-batch*)
           (n (ffi:c-inline (*fu* p *dq* *dq-n* (stream-buffer-data fa) (stream-buffer-fill fa)
                             (stream-buffer-data fb) (stream-buffer-fill fb) (stream-buffer-data ui) (stream-buffer-fill ui))
                            (t t t :int t :int t :int t :int) :int
                            "r_frame(#0->vector.self.sf,#1->vector.self.sf,#2->vector.self.sf,#3,#4->vector.self.sf,#5,#6->vector.self.sf,#7,#8->vector.self.sf,#9)"
                            :one-liner t)))
      (declare (fixnum n))
      (when (>= n 0)                  ; -1: no swapchain texture this frame (skipped)
        (setf *draw-count* n *tri-count* (ffi:c-inline () () :int "r_tri_count()" :one-liner t)))))
  (let* ((lv (ffi:c-inline ((if *auto-render-scale* 1 0) *frame-budget-ms* *render-scale-min* (if *perf-log* 1 0)
                            *draw-count* *tri-count* *render-scale* *pixel-lights*)
                           (:int :float :float :int :int :int :float :int) :int
                           "r_timing(#0,#1,#2,#3,#4,#5,#6,#7)" :one-liner t)))
    (declare (fixnum lv))
    (unless (= lv (the fixnum *auto-level*))   ; auto off -> C returns 0 -> back to full quality
      ;; ladder: resolution 1.0 -> *render-scale-min* in 0.1 steps, then 3, then 1 per-pixel lights
      (let ((steps (max 0 (round (- 1 *render-scale-min*) 0.1))))
        (setf *auto-level* lv
              *render-scale* (f32 (max *render-scale-min* (- 1 (* 0.1 (min lv steps)))))
              *pixel-lights* (case (- lv steps) (1 3) (2 1) (t 8)))))))

;;; ---------------------------------------------------------------- fx batch
;;; Vertex: pos xyz, uv (radial softness: |uv|=0 opaque .. 1 transparent), rgba (sRGB, not tonemapped).
(defmacro with-fx-verts ((data o mode nverts) &body body)
  "Reserve NVERTS in the MODE batch; inside BODY (VTX x y z u v r g b a) appends one vertex."
  (let* ((sb (gensym)))
    `(let* ((,sb (if (eq ,mode :alpha) *fx-alpha* *fx-add*)))
       (if (not (stream-room-p ,sb ,nverts))
           (progn (incf *fx-dropped*) nil)
           (let* ((,data (stream-buffer-data ,sb)) (,o (stream-buffer-fill ,sb)))
             (declare (type f32vec ,data) (fixnum ,o))
             (macrolet ((vtx (x y z u v r g b a)
                          `(setf (aref ,',data ,',o) ,x (aref ,',data (+ ,',o 1)) ,y (aref ,',data (+ ,',o 2)) ,z
                                 (aref ,',data (+ ,',o 3)) ,u (aref ,',data (+ ,',o 4)) ,v
                                 (aref ,',data (+ ,',o 5)) ,r (aref ,',data (+ ,',o 6)) ,g (aref ,',data (+ ,',o 7)) ,b
                                 (aref ,',data (+ ,',o 8)) ,a
                                 ,',o (+ ,',o 9))))
               ,@body)
             (setf (stream-buffer-fill ,sb) ,o)
             t)))))

(defun-fast fx-billboard (x y z size r g b a &key (mode :add) (rot 0f0))
  "Camera-facing soft round sprite of radius SIZE at (x y z). MODE :add or :alpha."
  (let* ((x (f32 x)) (y (f32 y)) (z (f32 z)) (s (f32 size)) (r (f32 r)) (g (f32 g)) (b (f32 b)) (a (f32 a))
        (rt (camera-right *camera*)) (up (camera-upv *camera*)) (rot (f32 rot)))
    (declare (single-float x y z s r g b a rot) (type f32vec rt up))
    (let* ((c (cos rot)) (sn (sin rot))
           (rx (* s (- (* c (aref rt 0)) (* sn (aref up 0))))) (ry (* s (- (* c (aref rt 1)) (* sn (aref up 1))))) (rz (* s (- (* c (aref rt 2)) (* sn (aref up 2)))))
           (ux (* s (+ (* sn (aref rt 0)) (* c (aref up 0))))) (uy (* s (+ (* sn (aref rt 1)) (* c (aref up 1))))) (uz (* s (+ (* sn (aref rt 2)) (* c (aref up 2))))))
      (declare (single-float c sn rx ry rz ux uy uz))
      (with-fx-verts (d o mode 6)
        (vtx (- x rx ux) (- y ry uy) (- z rz uz) -1f0 -1f0 r g b a)
        (vtx (- (+ x rx) ux) (- (+ y ry) uy) (- (+ z rz) uz) 1f0 -1f0 r g b a)
        (vtx (+ x rx ux) (+ y ry uy) (+ z rz uz) 1f0 1f0 r g b a)
        (vtx (- x rx ux) (- y ry uy) (- z rz uz) -1f0 -1f0 r g b a)
        (vtx (+ x rx ux) (+ y ry uy) (+ z rz uz) 1f0 1f0 r g b a)
        (vtx (+ (- x rx) ux) (+ (- y ry) uy) (+ (- z rz) uz) -1f0 1f0 r g b a)))))

(defun-fast fx-line (x0 y0 z0 x1 y1 z1 width r g b a &key (mode :add) (end-width width) (end-alpha a))
  "Camera-facing segment (soft edges). WIDTH is the half-width in meters at the start,
END-WIDTH/END-ALPHA at the end (taper sparks / slashes)."
  (let* ((x0 (f32 x0)) (y0 (f32 y0)) (z0 (f32 z0)) (x1 (f32 x1)) (y1 (f32 y1)) (z1 (f32 z1))
         (w0 (f32 width)) (w1 (f32 end-width)) (r (f32 r)) (g (f32 g)) (b (f32 b)) (a0 (f32 a)) (a1 (f32 end-alpha))
         (eye (camera-eye *camera*))
         (dx (- x1 x0)) (dy (- y1 y0)) (dz (- z1 z0))
         (ex (- (aref eye 0) x0)) (ey (- (aref eye 1) y0)) (ez (- (aref eye 2) z0))
         (sx (- (* dy ez) (* dz ey))) (sy (- (* dz ex) (* dx ez))) (sz (- (* dx ey) (* dy ex)))
         (sl (sqrt (+ (* sx sx) (* sy sy) (* sz sz)))))
    (declare (single-float x0 y0 z0 x1 y1 z1 w0 w1 r g b a0 a1 dx dy dz ex ey ez sx sy sz sl) (type f32vec eye))
    (when (> sl 1f-9)
      (setf sx (/ sx sl) sy (/ sy sl) sz (/ sz sl))
      (with-fx-verts (d o mode 6)
        (vtx (- x0 (* sx w0)) (- y0 (* sy w0)) (- z0 (* sz w0)) 0f0 -1f0 r g b a0)
        (vtx (+ x0 (* sx w0)) (+ y0 (* sy w0)) (+ z0 (* sz w0)) 0f0 1f0 r g b a0)
        (vtx (+ x1 (* sx w1)) (+ y1 (* sy w1)) (+ z1 (* sz w1)) 0f0 1f0 r g b a1)
        (vtx (- x0 (* sx w0)) (- y0 (* sy w0)) (- z0 (* sz w0)) 0f0 -1f0 r g b a0)
        (vtx (+ x1 (* sx w1)) (+ y1 (* sy w1)) (+ z1 (* sz w1)) 0f0 1f0 r g b a1)
        (vtx (- x1 (* sx w1)) (- y1 (* sy w1)) (- z1 (* sz w1)) 0f0 -1f0 r g b a1)))))

(defun-fast fx-trail (samples n r g b a &key (mode :add))
  "Sword-trail ribbon. SAMPLES: f32vec of N samples, 6 floats each (base xyz, tip xyz), oldest
first. Alpha ramps 0 (oldest) → A (newest); soft toward the base, solid at the tip."
  (declare (type f32vec samples) (fixnum n))
  (let* ((r (f32 r)) (g (f32 g)) (b (f32 b)) (a (f32 a)))
    (declare (single-float r g b a))
    (when (>= n 2)
      (with-fx-verts (d o mode (* 6 (1- n)))
        (loop for i fixnum from 0 below (1- n)
              for p = (* i 6) and q = (* (1+ i) 6)
              for a0 single-float = (* a (/ (float i 1f0) (float (1- n) 1f0)))
              for a1 single-float = (* a (/ (float (1+ i) 1f0) (float (1- n) 1f0)))
              do (macrolet ((s (k) `(aref samples ,k)))
                   (vtx (s p) (s (+ p 1)) (s (+ p 2)) 0f0 1f0 r g b a0)
                   (vtx (s (+ p 3)) (s (+ p 4)) (s (+ p 5)) 0f0 0f0 r g b a0)
                   (vtx (s (+ q 3)) (s (+ q 4)) (s (+ q 5)) 0f0 0f0 r g b a1)
                   (vtx (s p) (s (+ p 1)) (s (+ p 2)) 0f0 1f0 r g b a0)
                   (vtx (s (+ q 3)) (s (+ q 4)) (s (+ q 5)) 0f0 0f0 r g b a1)
                   (vtx (s q) (s (+ q 1)) (s (+ q 2)) 0f0 1f0 r g b a1)))))))

(defun-fast fx-decal (x y z radius r g b a &key (mode :alpha))
  "Soft horizontal disc lying at height Y (+2 cm). Blob shadow: (fx-decal x 0 z 0.6 0 0 0 0.55)."
  (let* ((x (f32 x)) (y (+ (f32 y) 0.02f0)) (z (f32 z)) (s (f32 radius)) (r (f32 r)) (g (f32 g)) (b (f32 b)) (a (f32 a)))
    (declare (single-float x y z s r g b a))
    (with-fx-verts (d o mode 6)
      (vtx (- x s) y (- z s) -1f0 -1f0 r g b a)
      (vtx (+ x s) y (- z s) 1f0 -1f0 r g b a)
      (vtx (+ x s) y (+ z s) 1f0 1f0 r g b a)
      (vtx (- x s) y (- z s) -1f0 -1f0 r g b a)
      (vtx (+ x s) y (+ z s) 1f0 1f0 r g b a)
      (vtx (- x s) y (+ z s) -1f0 1f0 r g b a))))
