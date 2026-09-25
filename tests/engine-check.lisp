;;;; engine-check.lisp — in-browser checks of the engine APIs added for SOUL DUEL (phase E):
;;;; pads with a slot index, *POINTER-LOCK* NIL, numpad key names, the SIM-RND stream and seeds,
;;;; FX-CLEAR / TIME-RESET, MUSIC-PLAY with a key, the DEFSOUND / au_load slot limit, +P-FLAME+,
;;;; *GRADE-DESAT* and the stats line's fx-dropped field.
;;;; Phase E2: zero-cons FX-EMIT / UI quads / block text / AU-STATS (cons-bytes deltas), FX-EMIT's
;;;; ALPHA (flame intensity), *GRADE-SPLIT*, ENV-SUN-SIZE / -GLOW, DRAW-MESH :ENV-RIM, light
;;;; PRIORITY, DEFCLIP :FPS / :MARKS, LIST-CLIPS / LIST-SOUNDS / FIND-CLIP NIL / ANIM-BLEND,
;;;; MB-XFORM, MAKE-RIG-PROPORTIONS with POSE-FK!.
;;;; Restyle phase 1a (docs/STYLE_STORM_DESIGN.md §2): DRAW-MESH :TOON lanes (and 0 without), zero-cons
;;;; toon draws and toon frame lanes, the camera-space key light, analytic smooth normals, the RAVEN
;;;; defaults of *PART-JITTER* / *PART-SMOOTH*; debug 12 = the toon look (ec-toon.png: fs_toon stage +
;;;; character draws, one mirrored = RP_TOON_CW, and fs_sky_toon's moon) for the WGSL smoke test.
;;;; Restyle phase 1b (§2.4): MB-HULL extrusions (a box corner moves every face out 1 width, the cone
;;;; cap), BUILD-PARTS :INK (hull colours by key, the size rule, no hulls without :INK), zero-cons
;;;; DRAW-PARTS with hulls; ec-toon.png also draws the balls' ink hulls (RP_HULL, RP_HULL_CW).
;;;; Restyle phase 2 (§3): zero-cons toon primitives (FX-STAR / -SHARD / -CRESCENT / -WALL, toon FX-RIBBON /
;;;; FX-SECTOR / FX-BILLBOARD, the toon particle kinds, FX-ENVELOPE + SAGE, the screen punctuation
;;;; UI-FOCUS-LINES / UI-SPEED-LINES / UI-INK-SPLASH), the fx clock lane, *KEY-EASE*, *SHAKE-HZ* and
;;;; GRADE-IMPACT defaults; debug 13 = ec-fxtoon.png (every toon primitive in every palette over the toon
;;;; stage: RP_FXT with alpha-to-coverage) and debug 14..17 = ec-impact-1..4.png (RP_COMP_FX modes).
;;;;   tests/engine-check.sh          (= ./build.sh echeck tests/engine-check.lisp, then the run below)
;;;;   node tools/run.mjs dist/echeck --secs 28 --script tests/scripts/engine-check.json
;;;; Every check logs "check PASS|FAIL name"; debug command 9 logs "engine-check: N pass, M fail".
;;;; Screenshots (look at them): tests/shots/ec-flame.png (three flame columns), ec-grey.png
;;;; (*grade-desat* 1), ec-color.png (back to 0), ec-cleared.png (after FX-CLEAR: no flames),
;;;; ec-flame-high.png / ec-flame-low.png (bright sky, flame ALPHA 1 / 0.35), ec-split.png
;;;; (*grade-split* 24), ec-sun-1.png / ec-sun-3.png (env-sun-size 1 / 3, glow 0.25 / 0.8),
;;;; ec-rig.png (left: standard rig, right: shoulders 1.3 arms 1.15 legs 1.2 spine 1.1, same pose;
;;;; floor :env-rim 0, boxes behind: env rim on (left) / :env-rim 0 (right)).
(defpackage :engine-check (:use :cl :engine))
(in-package :engine-check)

(defsound :ec-tune (:peak 0.4 :loop t)
  (let ((b (au-buf 1.0)))
    (au-ping! b 0.0 440 0.2 0.8)
    (au-ping! b 0.5 660 0.2 0.6)
    b))

;;; ---------------------------------------------------------------- bookkeeping
(defvar *pass* 0) (defvar *fail* 0)
(defun check (name ok &optional (fmt "") &rest args)
  (if ok (incf *pass*) (incf *fail*))
  (log-msg "check ~:[FAIL~;PASS~] ~a~@[ ~a~]" ok name (and (plusp (length fmt)) (apply #'format nil fmt args))))

;;; ---------------------------------------------------------------- startup checks
(defun take (n fn) (loop repeat n collect (funcall fn)))
(defun sim5 () (take 5 (lambda () (sim-rnd01))))
(defun cos5 () (take 5 (lambda () (rnd01))))

(defun check-rng ()
  (let* ((cosmetic (cos5))
         (a (progn (sim-rnd-seed 42) (sim5)))
         (b (progn (sim-rnd-seed 42) (sim5))))
    (log-msg "sim-rnd01 after (sim-rnd-seed 42), twice:~%  ~{~,6f ~}~%  ~{~,6f ~}~%rnd01 (own stream): ~{~,6f ~}" a b cosmetic)
    (check "sim-rnd-seed 42 twice gives the same 5 values" (equal a b))
    (check "sim-rnd01 differs from the rnd01 stream" (not (equal a cosmetic)))
    (check "sim-rnd01 values in [0,1)" (every (lambda (x) (and (>= x 0) (< x 1))) a))
    ;; consuming rnd01 (fx, shake) must not move the sim stream
    (sim-rnd-seed 42) (take 2 (lambda () (sim-rnd01))) (cos5) (cos5)
    (check "rnd01 use leaves the sim stream alone" (equal (take 3 (lambda () (sim-rnd01))) (subseq a 2)))
    ;; state: a non-negative integer that SETF restores
    (let* ((s (sim-rnd-state)) (x (take 3 (lambda () (sim-rnd01)))))
      (setf (sim-rnd-state) s)
      (check "sim-rnd-state read / setf replays" (equal x (take 3 (lambda () (sim-rnd01)))) "state ~d" s)
      (check "sim-rnd-state is a positive integer" (and (integerp s) (plusp s))))
    (rnd-seed 7)
    (let ((c (cos5)) (s (rnd-state)))
      (rnd-seed 7)
      (check "rnd-seed 7 replays rnd01" (equal c (cos5)) "rnd-state after 5 draws ~d" s))
    (sim-rnd-seed -5) (sim-rnd-seed 0) (sim-rnd-seed most-positive-fixnum)
    (check "sim-rnd-seed accepts 0 / negative / max fixnum" (< (sim-rnd01) 1))))

(defun check-pads ()
  (log-msg "pad-count ~d" (pad-count))
  (check "pad-count 0 headless" (= 0 (pad-count)))
  (check "pad readers with a slot index" (and (not (pad-connected-p)) (not (pad-connected-p 3)) (not (pad-connected-p 9))
                                              (not (pad-down :a 2)) (not (pad-pressed :b 1)) (not (pad-down :x))
                                              (= 0 (pad-lx) (pad-ly 1) (pad-rx 2) (pad-ry 3) (pad-lt) (pad-rt 1)))))

(defun check-keys ()
  (check "new key names resolve"
         (progn (dolist (k '(:kp-0 :kp-1 :kp-2 :kp-3 :kp-4 :kp-5 :kp-6 :kp-7 :kp-8 :kp-9 :kp-enter :kp-plus :kp-minus
                             :kp-multiply :kp-divide :kp-period :quote :backslash :grave :delete :insert :home :end
                             :pageup :pagedown :capslock :rshift))
                  (key-down k))
                t)))

(defun check-time ()
  (hitstop 10) (slowmo 0.2 5.0)
  (let ((before (list *hitstop* (slowmo-scale nil) (slowmo-scale t))))
    (time-reset)
    (check "time-reset clears hitstop and slow-mo" (and (= *hitstop* 0) (= 1.0 (slowmo-scale nil) (slowmo-scale t)))
           "before ~s after ~s" before (list *hitstop* (slowmo-scale nil) (slowmo-scale t)))))

(defun check-audio ()
  (let ((id (music-play :ec-tune)))
    (check "music-play :ec-tune" (and (>= id 0) (music-playing-p)) "voice ~d" id))
  (check "music-play of an unknown key is a no-op" (music-play :ec-nothing))   ; returns the playing voice
  (check "music-intensify :ec-tune" (>= (music-intensify :ec-tune) 0))
  (check "music-play again while playing: no-op" (music-play :ec-tune))
  ;; au_load ignores an out-of-range slot (the log shows "audio: sound slot 200 out of range")
  (ffi:c-inline () () :void "au_load(200, 0, 0)" :one-liner t)
  (check "defsound past the slot count signals" (defsound-over-limit-message) "~a" (defsound-over-limit-message)))

(defun defsound-over-limit-message ()
  "Pretend 128 sounds exist, define one more: DEFSOUND must signal (the real list is untouched)."
  (let ((engine::*au-defs* (loop for i below 128 collect (list i 0.9 nil nil))))
    (handler-case (progn (defsound :ec-over () (au-buf 0.01)) nil)
      (error (e) (princ-to-string e)))))

;;; ---------------------------------------------------------------- phase E2: data / API checks
(defvar *floor*) (defvar *box*)                    ; meshes (BUILD-MESHES, below)
(defpose :ec-pose ()
  (:arms :side 40 :flex 20) (:elbows :flex 60) (:thighs :flex 20) (:knees :flex 35) (:spine :flex 10))
(defpose :ec-hit () (:arm-r :flex 120) (:elbow-r :flex 10))
;; the same attack twice: DEFSTRIKE-style seconds (frame / 60.0) and DEFCLIP :FPS 60 :MARKS
(defclip :ec-strike-sec (#.(/ 22 60.0) :base :ec-pose)
  (#.(/ 4 60.0) (:arm-r :flex 80)) (#.(/ 7 60.0) :snap :ec-hit) (#.(/ 10 60.0) (:arm-r :flex 100)) (#.(/ 22 60.0) :ec-pose))
(defclip :ec-strike-fps (22 :fps 60 :base :ec-pose :marks (:s 7 :a 10))
  (4 (:arm-r :flex 80)) (:s :snap :ec-hit) (:a (:arm-r :flex 100)) (:end :ec-pose))

(defun check-anim-api ()
  (let ((a (find-clip :ec-strike-sec)) (b (find-clip :ec-strike-fps)))
    (check "defclip :fps 60 / :marks = the same clip in seconds"
           (and (= (clip-dur a) (clip-dur b)) (equalp (engine::clip-times a) (engine::clip-times b))
                (equalp (engine::clip-snaps a) (engine::clip-snaps b)) (equalp (engine::clip-poses a) (engine::clip-poses b)))
           "dur ~a times ~a" (clip-dur b) (engine::clip-times b))
    (check "clip-mark :s / :a / :end in seconds"
           (and (= (clip-mark :ec-strike-fps :s) (/ 7 60.0)) (= (clip-mark b :a) (/ 10 60.0)) (= (clip-mark b :end) (clip-dur b))
                (null (clip-mark b :nope)))
           "~a ~a ~a" (clip-mark b :s) (clip-mark b :a) (clip-mark b :end)))
  (check "list-clips sorted, has both" (and (member :ec-strike-fps (list-clips)) (member :ec-strike-sec (list-clips))
                                            (equal (list-clips) (sort (copy-list (list-clips)) #'string< :key #'symbol-name))))
  (check "find-clip NIL for an unknown name when ERRORP is NIL" (and (null (find-clip :ec-nothing nil)) (find-clip :ec-strike-fps nil)))
  (check "list-sounds / sound-loop-p" (and (member :ec-tune (list-sounds)) (sound-loop-p :ec-tune) (not (sound-loop-p :ec-nothing)))
         "~s" (list-sounds))
  (let ((an (make-anim)) (ref (make-f32 +pose-n+)))
    (anim-play an :ec-strike-fps :blend 0) (anim-advance an 0.05) (anim-eval an)
    (anim-play an :ec-strike-sec :blend 8)                 ; start a crossfade ...
    (setf (anim-blend an) 0.0)                             ; ... and cut it
    (clip-sample! ref (find-clip :ec-strike-sec) 0.0)
    (check "anim-blend exported: setf 0 cuts the crossfade" (equalp (anim-eval an) ref)))
  (let ((mb (make-mesh-builder)))
    (with-xform (mb (xform :y 1.5)) (check "mb-xform is the builder's current transform" (= 1.5 (aref (mb-xform mb) 13))))
    (check "mb-xform restored after with-xform" (= 0 (aref (mb-xform mb) 13)))))

(defvar *props* (make-rig-proportions :shoulders 1.3 :arms 1.15 :legs 1.2 :spine 1.1))
(defvar *jm-a* (make-f32 (* 16 +nj+)))
(defvar *jm-b* (make-f32 (* 16 +nj+)))
(defun jy (jm j) (aref jm (+ (* 16 j) 13)))
(defun jx (jm j) (aref jm (+ (* 16 j) 12)))

(defun check-rig ()
  (let ((zero (make-f32 +pose-n+)) (a *jm-a*) (b *jm-b*))
    (pose-fk! a (find-pose :ec-pose) 0.3 0.0 -0.2 0.4 1.1 0.05)
    (pose-fk! b (find-pose :ec-pose) 0.3 0.0 -0.2 0.4 1.1 0.05 (make-rig-proportions))
    (check "pose-fk! with all-1 proportions = the standard rig, bit for bit" (equalp a b))
    (funcall #'pose-fk! b (find-pose :ec-pose) 0.3 0.0 -0.2 0.4 1.1 0.05)
    (check "#'pose-fk! (no compiler macro) = the direct call" (equalp a b))
    (pose-fk! a zero 0.0 0.0 0.0 0.0 1.0 0.0)
    (pose-fk! b zero 0.0 0.0 0.0 0.0 1.0 0.0 *props*)
    (let ((fa (jy a (ji :foot-r))) (fb (jy b (ji :foot-r)))
          (wa (- (jx a (ji :shoulder-r)) (jx a (ji :shoulder-l)))) (wb (- (jx b (ji :shoulder-r)) (jx b (ji :shoulder-l))))
          (la (- (jy a (ji :upper-arm-r)) (jy a (ji :hand-r)))) (lb (- (jy b (ji :upper-arm-r)) (jy b (ji :hand-r)))))
      (check "legs 1.2: pelvis follows, the feet stay on the ground" (< (abs (- fa fb)) 1e-4) "foot y ~,4f / ~,4f" fa fb)
      (check "shoulders 1.3: shoulder width x1.3" (< (abs (- wb (* 1.3 wa))) 1e-4) "~,4f -> ~,4f" wa wb)
      (check "arms 1.15: arm length x1.15" (< (abs (- lb (* 1.15 la))) 1e-4) "~,4f -> ~,4f" la lb)
      (check "legs 1.2: pelvis higher" (> (jy b 0) (+ (jy a 0) 0.15)) "pelvis y ~,3f -> ~,3f" (jy a 0) (jy b 0)))
    (check "pose-fk! rejects a wrong proportions vector"
           (handler-case (progn (pose-fk! a zero 0.0 0.0 0.0 0.0 1.0 0.0 (make-f32 3)) nil) (error () t)))))

;;; zero-cons checks: bytes consed by N calls (CONS-BYTES = bytes allocated since the last GC)
(defun-fast ec-emit-n (n x)
  (declare (fixnum n) (single-float x))
  (dotimes (i n) (fx-emit +p-glow+ x 1f0 -2f0 0f0 0f0 0f0 0.5f0 0.05f0 0f0 1f0 1f0 1f0 0.5f0)))
(defvar *emit-fn* #'fx-emit)
(defun-fast ec-emit-funcall-n (n x)   ; the same through the function object: the floats get boxed
  (declare (fixnum n) (single-float x))
  (dotimes (i n) (funcall *emit-fn* +p-glow+ x (+ x 1f0) -2f0 (* x 0.1f0) 0f0 0f0 0.5f0 0.05f0 0f0 1f0 1f0 1f0 0.5f0)))
(defun-fast ec-poly-n (n x)
  (declare (fixnum n) (single-float x))
  (dotimes (i n) (%ui-poly4 x 10f0 (+ x 5f0) 10f0 (+ x 6f0) 20f0 (+ x 1f0) 20f0 '(1 1 1 0) '(1 1 1 0))))
(defun-fast ec-verts-n (n x)
  (declare (fixnum n) (single-float x))
  (dotimes (i n) (with-ui-verts (d o 6)
                   (uvtx x 0f0 1f0 1f0 1f0 0f0) (uvtx (+ x 4f0) 0f0 1f0 1f0 1f0 0f0) (uvtx x 4f0 1f0 1f0 1f0 0f0)
                   (uvtx x 0f0 1f0 1f0 1f0 0f0) (uvtx x 4f0 1f0 1f0 1f0 0f0) (uvtx (+ x 4f0) 4f0 1f0 1f0 1f0 0f0))))
(defun-fast ec-ribbon-n (n x)
  (declare (fixnum n) (single-float x))
  (dotimes (i n) (fx-ribbon x 0f0 -3f0 0f0 1f0 0f0 0.2f0 0.05f0 1f0 0.5f0 0.1f0 -0.5f0 1f0 0.2f0 0f0 0f0 x 0.1f0)))
(defparameter *ec-bits* '(#b1110 #b1001 #b1110 #b1001 #b1110) "a 4 x 5 test bitmap (B)")
(defmacro consed (&body body) `(let ((c0 (cons-bytes))) ,@body (- (cons-bytes) c0)))

(defun check-consing ()
  (let* ((live *plive*) (ui0 (engine::stream-buffer-fill engine::*ui-batch*))
         (emit (consed (ec-emit-n 100 0.5)))
         (old (consed (ec-emit-funcall-n 100 0.5)))
         (poly (consed (ec-poly-n 100 20f0)))
         (verts (consed (ec-verts-n 100 20f0)))
         (rect (consed (dotimes (i 100) (ui-rect 10.5 12.5 30.25 8.5 '(1 1 1 0)))))
         (text (consed (ui-block-text "ZANKA NO TACHI" 40 200 6 :color '(1 1 1 0) :color2 '(1 0.5 0 0) :shear 0.2)))
         (utext (consed (ui-text "ZANKA NO TACHI / SOUL DUEL" 40 260 :scale 2 :color '(1 1 1 0))))
         (bm0 (ui-bitmap *ec-bits* 40 300 4 :color '(1 1 1 0)))      ; first call builds the cached rectangles
         (bm (consed (dotimes (i 100) (ui-bitmap *ec-bits* 40 300 4 :color '(1 1 1 0)))))
         (rib (consed (ec-ribbon-n 100 0.5))))
    (declare (ignore bm0))
    (log-msg "consed: 100 fx-emit ~d B (100 via #'fx-emit ~d B), 100 %ui-poly4 ~d B, 100 with-ui-verts quads ~d B, 100 ui-rect ~d B, block text ZANKA NO TACHI ~d B, ui-text 26 chars ~d B, 100 ui-bitmap ~d B, 100 fx-ribbon ~d B"
             emit old poly verts rect text utext bm rib)
    (check "fx-emit (direct call, unboxed floats) conses nothing" (= emit 0) "~d B / 100" emit)
    (check "#'fx-emit still spawns (function object kept)" (>= *plive* live))
    (check "%ui-poly4 (direct call, unboxed floats) conses nothing" (= poly 0) "~d B / 100" poly)
    (check "with-ui-verts conses nothing" (= verts 0) "~d B / 100" verts)
    (check "ui-rect with float arguments conses nothing itself" (= rect 0) "~d B / 100" rect)
    (check "ui-block-text: no consing per font pixel" (< text 1024) "~d B for 14 chars" text)
    (check "ui-text: no consing per glyph (harvest)" (< utext 512) "~d B for 26 chars" utext)
    (check "ui-bitmap: cached rectangles, a few boxed numbers per call (harvest)" (< bm (* 100 256)) "~d B / 100" bm)
    (check "fx-ribbon (macro, unboxed floats) conses nothing (harvest)" (= rib 0) "~d B / 100" rib)
    (check "ui quads written (6 verts x 8 floats each)" (> (engine::stream-buffer-fill engine::*ui-batch*) (+ ui0 (* 300 48))))
    (setf (engine::stream-buffer-fill engine::*ui-batch*) ui0))       ; keep the invisible test quads off screen anyway
  (let* ((buf (make-f32 960000)))                                      ; 20 s of samples
    (dotimes (i (length buf)) (setf (aref buf i) (* 0.5 (sin (* i 0.01)))))
    (let ((c (consed (engine::au-stats :ec-20s buf 0))))
      (check "au-stats (*audio-debug*) on 20 s of samples: no per-sample consing" (< c 65536) "~d B" c))))

(defun check-alpha-column ()
  (let* ((p engine::*parts*) (c engine::*pcursor*))
    (fx-emit +p-flame+ 0.0 -5.0 0.0 0.0 0.0 0.0 0.1 0.1 0.0 1.0 1.0 1.0 0.35)
    (fx-emit +p-flame+ 0.0 -5.0 0.0 0.0 0.0 0.0 0.1 0.1 0.0 1.0 1.0 1.0)
    (check "fx-emit ALPHA stored (0.35), default 1" (and (= (aref p (+ (* c engine::+pstride+) 14)) (f32 0.35))
                                                         (= (aref p (+ (* (mod (1+ c) engine::+pmax+) engine::+pstride+) 14)) 1.0)))))

(defun check-light-priority ()
  "8 lights at the camera target and 1 far one with priority 1: the far one must be picked first."
  (let ((n engine::*light-n*))
    (dotimes (i 8) (add-point-light (* 0.1 i) 0.9 0.0 1.0 1.0 1.0 3.0))
    (add-point-light 2.5 0.5 -2.5 0.2 0.4 1.0 3.0 1.0 1)
    (let ((k (engine::select-lights)) (lp engine::*lp*))
      (check "light priority: the far priority-1 light takes slot 0" (and (= k 8) (= (aref lp 0) 2.5) (= (aref lp 2) -2.5))
             "slot 0 at ~,2f ~,2f ~,2f" (aref lp 0) (aref lp 1) (aref lp 2)))
    (setf engine::*light-n* n)
    (dotimes (i 8) (add-point-light (* 0.1 i) 0.9 0.0 1.0 1.0 1.0 3.0))
    (add-point-light 2.5 0.5 -2.5 0.2 0.4 1.0 3.0 1.0)
    (let ((lp engine::*lp*))
      (engine::select-lights)
      (check "light priority 0 (default): nearest first, the far light dropped"
             (loop for i below 8 never (= (aref lp (* 4 i)) 2.5))))
    (setf engine::*light-n* n)))

(defun check-env-rim-lane ()
  (let ((n engine::*dq-n*) (q engine::*dq*) (m (m4)))
    (draw-mesh *box* m) (draw-mesh *box* m :env-rim 0.0)
    (check "draw-mesh :env-rim -> record lane 27 (default 1)"
           (and (= 1.0 (aref q (+ (* n engine::+dq-stride+) 27))) (= 0.0 (aref q (+ (* (1+ n) engine::+dq-stride+) 27)))))
    (setf engine::*dq-n* n)))

(defvar *toon-lanes* (fv 2 0.1 0.2 0) "DRAW-MESH :toon lanes: character mode, feet 0.1, fog x 0.2")
(defun-fast ec-toon-draws (n m)
  (declare (fixnum n) (type f32vec m))
  (dotimes (i n) (draw-mesh *box* m :toon *toon-lanes*)))

(defvar *hull-lanes* (fv 3 0.012 0.2 3.0) "DRAW-MESH :toon lanes of an ink hull: mode 3, push, fog, 3 px")
(defvar *ec-parts* nil)
(defun-fast ec-hull-draws (n jm hulls)
  (declare (fixnum n) (type f32vec jm))
  (let ((p *ec-parts*))
    (dotimes (i n) (draw-parts (first p) (second p) jm :toon *toon-lanes* :hulls (and hulls (third p)) :ink-tint '(1 1 1)))))

(defun check-hull ()
  (flet ((es (build &rest keys)            ; every hull vertex's extrusion (the normal slot)
           (let ((src (make-mesh-builder)) (dst (make-mesh-builder)))
             (funcall build src) (apply #'mb-hull dst src keys)
             (loop for o from 0 below (engine::mb-fill dst) by 9
                   collect (let ((d (engine::mb-data dst))) (list (aref d (+ o 3)) (aref d (+ o 4)) (aref d (+ o 5))))))))
    (let ((box (es (lambda (mb) (mb-box mb 0.4 0.2 0.3)) :k 1.0))
          (cone (es (lambda (mb) (mb-cone mb 0.05 0.4 :segments 4)) :c 0.8)))
      (check "mb-hull: a box corner's extrusion is (+-1 +-1 +-1): every face moves out one width"
             (every (lambda (e) (every (lambda (x) (< (abs (- (abs x) 1)) 1e-4)) e)) box) "~d vertices" (length box))
      (check "mb-hull: no spike longer than 1/C at a cone tip"
             (every (lambda (e) (<= (sqrt (reduce #'+ (mapcar #'* e e))) (+ (/ 1 0.8) 1e-4))) cone))))
  (multiple-value-bind (parts extras hulls)
      (build-parts '((:chest (:box 0.4 0.3 0.2 :c :robe) (:box 0.08 0.08 0.08 :at (0 0.3 0) :c :skin)
                             (:box 0.02 0.2 0.01 :at (0 0 0.11) :c :robe) (:box 0.1 0.1 0.1 :at (0.3 0 0) :c :robe :tag :tagged)))
                   '((:robe #x16161E) (:skin #xD8B4A0)) 1.0 :ink '((:skin . #x3A1E1A) (t . #x4A5062)))
    (setf *ec-parts* (list parts extras hulls))
    (check "build-parts :ink -> one hull per joint mesh and tagged part" (and (= (length hulls) 2) (find :tagged hulls :key (lambda (h) (svref h 2)))))
    (check "build-parts without :ink -> no hulls" (null (nth-value 2 (build-parts '((:chest (:box 0.4 0.3 0.2))) nil 1.0))))
    (let* ((jm (make-f32 (* 16 +nj+))) (n engine::*dq-n*) (c0 (consed (ec-hull-draws 100 jm nil)))
           (c (progn (setf engine::*dq-n* n) (consed (ec-hull-draws 100 jm t)))))   ; (a growing *dq* would count)
      (setf engine::*dq-n* n)
      (check "100 draw-parts with hulls cons nothing more than without" (= c c0) "~d B (without hulls ~d B)" c c0))))

;;; phase 2: toon primitives
(defvar *wall-x* (fv -2.4 -1.2 0.0 1.2 2.4)) (defvar *wall-z* (fv -2.0 -2.4 -2.5 -2.4 -2.0))
(defun-fast ec-toon-fx (n x)
  "N rounds of every toon primitive (and toon particles), all palettes."
  (declare (fixnum n) (single-float x))
  (dotimes (i n)
    (let* ((p (i->f (mod i 12))))
      (declare (single-float p))
      (fx-star x 1.4f0 0f0 0.12f0 0.45f0 7 0.2f0 1f0 0.3f0 0.1f0 (i->f i) p 0.98f0)
      (fx-shard x 1.0f0 0f0 0.7f0 0.7f0 0f0 0.3f0 0.07f0 0.1f0 3f0 p 0.9f0)
      (fx-crescent (- x 0.5f0) 0.6f0 0f0 (+ x 0.5f0) 0.6f0 0f0 x 1.0f0 0f0 0.12f0 :comet 0.1f0 5f0 p 0.9f0)
      (fx-wall *wall-x* *wall-z* 5 1.2f0 6 0.2f0 2f0 p 0.9f0)
      (fx-ribbon x 0f0 0f0 0f0 1f0 0f0 0.2f0 0f0 1f0 -3f0 0.2f0 (toon-a p 0.9f0) 0.2f0 -3f0 0.2f0 (toon-a p 0.9f0) 0f0 0f0
                 :mode :toon)
      (fx-emit +p-t-blob+ x 1f0 0f0 0f0 0f0 0f0 0.5f0 0.2f0 0f0 0.2f0 0f0 0f0 p)
      (fx-envelope (sc k fl ph) ((sage 0.1f0 2f0) 1 2 2 6 :anticipate 4)
        (fx-disc x 2f0 0f0 (* sc 0.2f0) 0.1f0 7f0 p k)))))
(defun-fast ec-punct (n)
  (declare (fixnum n))
  (dotimes (i n)
    (ui-focus-lines 640f0 360f0 40 200f0 900f0 '(0 0 0 0) i)
    (ui-speed-lines 0.3f0 20 '(0 0 0 0) i)
    (ui-ink-splash 300f0 300f0 80f0 3f0 '(0 0 0 0) i)))

(defun check-toon-fx ()
  (let* ((ft (stream-buffer-fill *fx-toon*)) (ui0 (stream-buffer-fill engine::*ui-batch*))
         (c (consed (ec-toon-fx 12 0.5f0))) (dp (consed (fx-draw-particles))) (u (consed (ec-punct 5))))
    (log-msg "consed: 12 rounds of every toon primitive ~d B, fx-draw-particles with toon kinds ~d B, 5 x focus / speed lines + ink splash ~d B" c dp u)
    (check "toon primitives, 12 rounds: 0 B" (= c 0) "~d B" c)
    (check "fx-draw-particles with toon particles: 0 B" (= dp 0) "~d B" dp)
    (check "ui-focus-lines / ui-speed-lines / ui-ink-splash: 0 B" (= u 0) "~d B" u)
    (check "toon batch written" (> (stream-buffer-fill *fx-toon*) (+ ft (* 9 1000))))
    (setf (stream-buffer-fill *fx-toon*) ft (stream-buffer-fill engine::*ui-batch*) ui0))
  (fx-envelope (sc k fl ph) (0.5f0 1 2 2 6)        ; frame 30 of (1 2 2 6): done
    (check "fx-envelope: past flash+grow+hold+out -> phase 5, k 0" (and (= ph 5) (= k 0f0))))
  (fx-envelope (sc k fl ph) ((/ 0.5f0 60f0) 1 2 2 6)
    (check "fx-envelope: frame 0.5 -> the flash, scale 0.6" (and (= ph 1) (= fl 1f0) (= sc 0.6f0))))
  (fx-envelope (sc k fl ph) ((/ 8f0 60f0) 1 2 2 6)
    (check "fx-envelope: frame 8 of (1 2 2 6) -> half way out, k ~0.49" (and (= ph 4) (< 0.4 k 0.6)) "k ~,3f" k))
  (let ((c0 (aref *fx-clock* 0)))
    (setf (aref *fx-clock* 0) 1.0)
    (check "sage: age quantised to the fx clock's twos" (< (abs (- (sage 0.5f0 2f0) (- 0.5 (mod 1.0 (/ 2 24.0))))) 1e-5))
    (setf (aref *fx-clock* 0) c0))
  (check "RAVEN defaults: *key-ease* 0, *shake-hz* 30, *grade-impact* 0" (and (= *key-ease* 0) (= *shake-hz* 30) (= *grade-impact* 0))))

(defun check-toon ()
  (let* ((n engine::*dq-n*) (q engine::*dq*) (m (m4)) (st engine::+dq-stride+) (e *env*))
    (draw-mesh *box* m) (draw-mesh *box* m :toon *toon-lanes*)
    (check "draw-mesh: no :toon -> lanes 28..31 are 0 (RAVEN's records unchanged)"
           (every #'zerop (subseq q (+ (* n st) 28) (+ (* n st) 32))))
    (check "draw-mesh :toon -> lanes 28..31" (equalp (subseq q (+ (* (1+ n) st) 28) (+ (* (1+ n) st) 32)) *toon-lanes*))
    (setf engine::*dq-n* n)
    (let ((c (consed (ec-toon-draws 100 m))))
      (setf engine::*dq-n* n)
      (check "100 toon draw-mesh calls cons nothing" (= c 0) "~d B" c))
    (setf (env-toon e) t)
    (let ((c (consed (dotimes (i 100) (engine::fill-toon-uniforms engine::*fu* e *camera*)))) (u engine::*fu*)
          (fw (camera-forward *camera*)))
      (check "100 fill-toon-uniforms cons nothing" (= c 0) "~d B" c)
      (let ((kl (sqrt (+ (expt (aref u 136) 2) (expt (aref u 137) 2) (expt (aref u 138) 2))))
            (kv (- (+ (* (aref u 136) (aref fw 0)) (* (aref u 137) (aref fw 1)) (* (aref u 138) (aref fw 2))))))
        (check "key light: unit, from the camera side (lit share (1+L.V)/2 ~ 73 %)" (and (< (abs (- kl 1)) 1e-4) (< 0.4 kv 0.5))
               "|key| ~,4f L.V ~,3f" kl kv)))
    (setf (env-toon e) nil))
  (check "RAVEN defaults: *part-jitter* 0.06, *part-smooth* NIL" (and (= *part-jitter* 0.06) (null *part-smooth*)))
  (flet ((normals-ok (build radial)       ; every vertex normal = the unit RADIAL of its position
           (let ((mb (make-mesh-builder)) (worst 0.0))
             (funcall build mb)
             (loop for o from 0 below (engine::mb-fill mb) by 9
                   do (let* ((d (engine::mb-data mb)) (r (funcall radial (aref d o) (aref d (+ o 1)) (aref d (+ o 2))))
                             (l (sqrt (reduce #'+ (mapcar (lambda (x) (* x x)) r)))))
                        (when (> l 1e-3)
                          (setf worst (max worst (loop for k below 3 maximize (abs (- (aref d (+ o 3 k)) (/ (nth k r) l)))))))))
             worst)))
    (let ((sph (normals-ok (lambda (mb) (with-xform (mb (xform :y 1 :yaw 0.7)) (mb-sphere mb 0.3 :stretch 0.4 :smooth t)))
                           (lambda (x y z) (list x (- y 1 (max -0.2 (min 0.2 (- y 1)))) z))))
          (cyl (normals-ok (lambda (mb) (mb-cylinder mb 0.3 0.6 :top-radius 0.1 :caps nil :smooth t))
                           (lambda (x y z) (declare (ignore y)) (list x (* (/ 0.2 0.6) (sqrt (+ (* x x) (* z z)))) z)))))
      (check "smooth capsule normals: p - (0, clamp(y), 0), turned by the transform" (< sph 1e-3) "worst ~,5f" sph)
      (check "smooth tapered cylinder normals: (x, slope r, z)" (< cyl 1e-3) "worst ~,5f" cyl))))

;;; ---------------------------------------------------------------- scene
(defvar *m* (m4))
(defvar *emit* t "Flame columns emitting.")
(defvar *flame-alpha* 1.0 "FX-EMIT ALPHA of the flame columns.")
(defvar *mode* :flames ":flames / :sun (camera on the sky disc) / :rig (two posed rigs + rim boxes)")
(defvar *seen* nil "Keys / clicks seen so far (checked by debug command 9).")
(defvar *log-plive-next* nil)
(defvar *frame-no* 0)

(defvar *ball* nil)
(defvar *ball-hull* nil)
(defun build-meshes ()
  (setf *floor* (build-mesh (mb :color '(0.10 0.10 0.13)) (mb-plane mb 16 16 :nx 8 :nz 8 :color2 '(0.14 0.13 0.18)))
        *box* (build-mesh (mb :color '(1 1 1)) (mb-box mb 0.8 0.8 0.8))
        *ball* (build-mesh (mb :color '(0.94 0.94 0.92)) (mb-sphere mb 0.45 :segments 12 :rings 8 :smooth t)))
  (let ((mb (make-mesh-builder)))
    (mb-sphere mb 0.45 :segments 12 :rings 8)
    (setf *ball-hull* (mb-build (mb-hull (make-mesh-builder) mb :color '(0.06 0.06 0.09))))))

(defvar *toon-stage* (fv 1 0 1 0))
(defun toon-look ()
  "Debug 12: the toon look (fs_sky_toon + fs_toon), as SOUL DUEL's stage sets it."
  (let ((e *env*))
    (v3-set! (env-sky-top e) 0.03 0.035 0.055) (v3-set! (env-fog-color e) 0.11 0.125 0.19) (v3-set! (env-moon-color e) 0.95 0.96 0.97)
    (v3-set! (env-moon-dir e) -0.3 0.16 -0.92) (v3-normalize! (env-moon-dir e) (env-moon-dir e))
    (setf (env-toon e) t (env-sun-size e) 6.0 (env-sun-glow e) 0.012 (env-moon-intensity e) 1.0 (env-fog-density e) 0.012
          (env-bloom-threshold e) 0.97
          *mode* :toon *emit* nil)
    (fx-clear)))

(defun dusk-look ()
  (let ((e *env*))                                    ; a dark dusk look, like a fire stage
    (v3-set! (env-sky-top e) 0.02 0.015 0.03) (v3-set! (env-fog-color e) 0.10 0.05 0.04)
    (v3-set! (env-ambient-sky e) 0.35 0.25 0.2) (v3-set! (env-moon-color e) 1.0 0.6 0.35)
    (setf (env-ambient-intensity e) 0.3 (env-moon-intensity e) 0.25 (env-rim-intensity e) 0.0)))

(defun bright-look ()
  (let ((e *env*))                                    ; a bright evening sky behind the flames
    (v3-set! (env-sky-top e) 0.3 0.42 0.7) (v3-set! (env-fog-color e) 0.62 0.5 0.36)
    (v3-set! (env-ambient-sky e) 0.8 0.75 0.7) (setf (env-ambient-intensity e) 0.6)))

(defun start ()
  (setf *stats-log* t *pointer-lock* nil)
  (dusk-look)
  (check-pads) (check-keys) (check-rng) (check-time) (check-audio)
  (check-anim-api) (check-rig) (check-alpha-column)
  (log-msg "engine-check: startup checks done"))

(defun emit-flames (dt)
  "Three flame columns (widths 0.8 / 1.1 / 1.4): hot white-yellow emit color, rising on a negative GRAV."
  (dotimes (c 3)
    (let ((x (* 2.2 (- c 1))) (w (+ 0.8 (* 0.3 c))))
      (dotimes (k (max 1 (round (* dt 55 w))))
        (fx-emit +p-flame+ (+ x (* w (rnd-range -0.15 0.15))) 0.15 (* w (rnd-range -0.15 0.15))
                 (rnd-range -0.2 0.2) (rnd-range 1.0 1.8) (rnd-range -0.2 0.2)
                 (rnd-range 0.6 1.0) (* w (rnd-range 0.16 0.26)) -3.0
                 1.0 0.9 0.55 *flame-alpha*)))))

(defun draw-rig (jm x)
  "Joint cubes + bones of a posed rig (for the proportions shot)."
  (dotimes (j +nj+)
    (let ((o (* 16 j)) (p (aref engine::*rig-parent* j)))
      (draw-mesh *box* (m4-euler! *m* (aref jm (+ o 12)) (aref jm (+ o 13)) (aref jm (+ o 14)) 0.0 0.0 0.0 0.07 0.07 0.07)
                 :tint '(1.0 0.8 0.3) :emissive 0.3)
      (when (>= p 0)
        (let ((q (* 16 p)))
          (fx-line (aref jm (+ o 12)) (aref jm (+ o 13)) (aref jm (+ o 14)) (aref jm (+ q 12)) (aref jm (+ q 13)) (aref jm (+ q 14))
                   0.012 0.5 0.8 1.0 1.0 :mode :alpha)))))
  (fx-decal x 0 0 0.4 0 0 0 0.5))

(defun frame (dt)
  (incf *frame-no*)
  (dolist (k '(:kp-1 :kp-enter :kp-plus))
    (when (key-pressed k) (log-msg "key-pressed ~s" k) (pushnew k *seen*)))
  (when (mouse-pressed :left)
    (log-msg "mouse-pressed :left (pointer locked: ~a)" (pointer-locked-p)) (pushnew :click *seen*))
  (case *mode*
    (:sun (let ((d (env-moon-dir *env*)))             ; look straight at the sky disc
            (camera-look-at 0.0 1.3 4.6 (* 10 (aref d 0)) (+ 1.3 (* 10 (aref d 1))) (+ 4.6 (* 10 (aref d 2))))))
    (:rig (camera-look-at 0.0 1.1 3.2 0.0 0.95 0.0))
    ((:toon :fxtoon) (camera-look-at 0.0 1.4 4.6 0.0 0.9 -1.0))
    (t (camera-look-at 0.0 1.3 4.6 0.0 0.9 0.0)))
  (when (= *frame-no* 30) (check-consing) (check-light-priority) (check-env-rim-lane) (check-toon) (check-hull) (check-toon-fx))
  (when *emit* (emit-flames dt))
  (fx-clock-advance dt)
  (when (eq *mode* :fxtoon) (fxtoon-scene))
  (fx-update dt)
  (when *log-plive-next*
    (setf *log-plive-next* nil)
    (check "fx-clear: nothing left a frame later" (= *plive* 0) "*plive* ~d" *plive*))
  (if (member *mode* '(:toon :fxtoon))
      (draw-mesh *floor* (m4-identity! *m*) :toon *toon-stage*)
      (draw-mesh *floor* (m4-identity! *m*) :specular 0.1 :env-rim (if (eq *mode* :rig) 0.0 1.0)))   ; the stage opts out
  (when (eq *mode* :toon)                             ; left: a character ball; right: the same mirrored (RP_TOON_CW)
    (draw-mesh *ball* (m4-euler! *m* -0.8 0.5 0.0 0.0 0.0 0.0) :toon *toon-lanes*)
    (draw-mesh *ball* (m4-euler! *m* 0.8 0.5 0.0 0.0 0.0 0.0 -1.0 1.0 1.0) :toon *toon-lanes*)
    (draw-mesh *ball-hull* (m4-euler! *m* -0.8 0.5 0.0 0.0 0.0 0.0) :toon *hull-lanes*)          ; ink outlines
    (draw-mesh *ball-hull* (m4-euler! *m* 0.8 0.5 0.0 0.0 0.0 0.0 -1.0 1.0 1.0) :toon *hull-lanes*))
  (if (eq *mode* :rig)
      (let ((pose (find-pose :ec-pose)))
        (pose-fk! *jm-a* pose -0.75 0.0 0.0 0.0 1.0 0.0)
        (pose-fk! *jm-b* pose 0.75 0.0 0.0 0.0 1.0 0.0 *props*)
        (draw-rig *jm-a* -0.75) (draw-rig *jm-b* 0.75)
        (draw-mesh *box* (m4-euler! *m* -1.9 0.4 -2.5 0.6 0.0 0.0) :tint '(0.5 0.5 0.55))
        (draw-mesh *box* (m4-euler! *m* 1.9 0.4 -2.5 0.6 0.0 0.0) :tint '(0.5 0.5 0.55) :env-rim 0.0))
      (loop for (x z r g b) in '((-3.4 -1.5 1.0 0.1 0.1) (3.4 -1.5 0.1 0.9 0.2) (0.0 -3.0 0.15 0.3 1.0))
            do (draw-mesh *box* (m4-euler! *m* x 0.4 z 0.6 0.0 0.0) :tint (list r g b))))
  (add-point-light 0.0 1.0 0.0 1.0 0.5 0.15 6.0 2.0)
  (fx-draw-particles)
  (fx-rings-update dt)
  (ui-text (format nil "ENGINE CHECK  PARTICLES ~d  DESAT ~,1f  SPLIT ~,1f" *plive* *grade-desat* *grade-split*) 12 12 :scale 2 :shadow t))

(defun fxtoon-scene ()
  "Debug 13: every toon primitive, one palette each, over the toon stage (the pipeline's smoke still)."
  (let ((row '((0 -2.2) (1 -1.3) (2 -0.4) (3 0.5) (4 1.4) (5 2.3))))
    (loop for (p x) in row
          do (fx-star (f32 x) 1.9f0 -0.5f0 0.1f0 0.33f0 7 0.3f0 1f0 0.2f0 0.1f0 (f32 (* 3 p)) (f32 p) 0.98f0 :push 0f0)
             (fx-crescent (f32 (- x 0.35)) 1.2f0 -0.5f0 (f32 (+ x 0.35)) 1.2f0 -0.5f0 (f32 x) 1.5f0 -0.5f0 0.1f0 :comet
                          0.1f0 (f32 p) (f32 (+ p 6)) 0.98f0 :push 0f0)
             (fx-shard (f32 x) 0.75f0 -0.5f0 0.6f0 0.8f0 0f0 0.35f0 0.07f0 0.1f0 2f0 (f32 (+ p 6)) 0.98f0 :push 0f0)
             (fx-billboard x 0.35 -0.5 0.22 1.0 (f32 p) 0.15 (toon-a (f32 (+ p 6)) 0.9f0) :mode :toon)
             (fx-ribbon (f32 (+ x 0.25)) 0f0 -0.8f0 0f0 0.9f0 0f0 0.12f0 0f0 1f0 -2f0 0.2f0 (toon-a (f32 p) 0.9f0)
                        0.2f0 -2f0 0.2f0 (toon-a (f32 p) 0.9f0) 0f0 0f0 :mode :toon))
    (fx-wall *wall-x* *wall-z* 5 1.0f0 6 0.25f0 4f0 0f0 0.95f0)
    (fx-sector 0.0 0.0 -0.5 1.9 2.1 0.0 3.2 1.0 5.0 0.1 (toon-a 10 0.9f0) :mode :toon)
    (ui-focus-lines 640f0 360f0 48 260f0 900f0 '(0.05 0.05 0.07 0.9) 3)
    (ui-ink-splash 140f0 560f0 70f0 5f0 '(0.03 0.03 0.05 1) 2)
    (ui-speed-lines 0f0 14 '(1 1 1 0.8) 1)))

(defun debug-command (n)
  (case n
    (13 (toon-look) (setf *mode* :fxtoon) (log-msg "toon fx: every primitive, palettes 0..11"))
    ((14 15 16 17) (grade-impact (- n 13)) (log-msg "grade-impact ~d" (- n 13)))
    (18 (grade-impact 0))
    (2 (setf *grade-desat* 1.0) (log-msg "*grade-desat* 1.0"))
    (3 (setf *grade-desat* 0.0) (log-msg "*grade-desat* 0.0"))
    (4 (let ((before *plive*))
         (setf *emit* nil)
         (fx-ring 0.0 0.5 0.0 0.2 1.0 5.0 1.0 1.0 1.0)
         (shake 0.3 2.0)
         (fx-clear)
         (check "fx-clear empties the particle pool" (and (> before 0) (= *plive* 0)) "*plive* before ~d after ~d" before *plive*)
         (setf *log-plive-next* t)))
    (5 (bright-look) (setf *emit* t *flame-alpha* 1.0) (log-msg "bright sky, flame alpha 1.0"))
    (6 (setf *flame-alpha* 0.35) (log-msg "flame alpha 0.35"))
    (7 (setf *grade-split* 24.0) (log-msg "*grade-split* 24"))
    (8 (setf *grade-split* 0.0 *emit* nil *mode* :sun) (fx-clear)
       (v3-set! (env-moon-dir *env*) 0.0 0.2 -1.0) (v3-normalize! (env-moon-dir *env*) (env-moon-dir *env*))
       (log-msg "sun: size ~,2f glow ~,2f" (env-sun-size *env*) (env-sun-glow *env*)))
    (10 (setf (env-sun-size *env*) 3.0 (env-sun-glow *env*) 0.8) (log-msg "sun: size 3 glow 0.8"))
    (12 (toon-look) (log-msg "toon look: fs_sky_toon, fs_toon stage + characters (one mirrored)"))
    (11 (dusk-look) (setf *mode* :rig (env-rim-intensity *env*) 1.5 (env-sun-size *env*) 1.0 (env-sun-glow *env*) 0.25)
        (log-msg "rig: standard (left) / proportions (right); boxes: env rim / :env-rim 0"))
    (9 (check "numpad keys seen (:kp-1 :kp-enter :kp-plus)" (subsetp '(:kp-1 :kp-enter :kp-plus) *seen*) "~s" *seen*)
       (check "click is a press with *pointer-lock* NIL" (and (member :click *seen*) (not (pointer-locked-p))))
       (log-msg "engine-check: ~d pass, ~d fail" *pass* *fail*))))

(run-game :title "engine check" :load (list #'build-meshes) :start #'start :frame #'frame :debug #'debug-command)
