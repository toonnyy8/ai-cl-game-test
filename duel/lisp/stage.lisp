;;;; stage.lisp — "Seireitei ruins at night" (docs/STYLE_STORM_DESIGN.md §6): a round plaza of
;;;; moonlit stone (r 15 m), a near-blank mid-grey page with a few ink cracks and faint joints in its
;;;; outer ring; a low curb; a ring of broken walls and the ruined town around it as cold-grey paper
;;;; cut-outs whose moon-facing caps catch a thin edge light; a cold dark sky with a huge flat moon
;;;; behind the arena (seen from the pair camera); white ash falling through still air. Sky, ruins and
;;;; ground share one cold mid-dark value range (user review 1), so the fighters' black robes and
;;;; white haori are the strongest contrast on screen. No fires
;;;; and no stage lights: warm colour belongs to the effects (their lights pool on the white ground).
;;;; Everything is drawn toon (fs_toon, stage mode: lit by the moon). Bankai dries and cracks the plaza:
;;;; STAGE-CRACK-ADD keeps a few ember-crack decals.
;;;; API: (stage-init) :load step (meshes) · (stage-env) sets *ENV* (the toon look) · (stage-draw rdt)
;;;;      every frame after the camera (RDT = real seconds; the ash keeps falling through hitstop and
;;;;      cinematics) · (stage-crack-add x z r) · (stage-clear-cracks). The plaza radius (15 m) is the gameplay's.
;;;; Budget: ~60 live stage particles, no lights, 4 mesh draws; FX-EMIT conses nothing.
(in-package :duel)

;;; ---------------------------------------------------------------- data
(defparameter *stage-ruins*
  ;; x z scale: the burnt-out frames of three buildings far outside the walls
  '((-24.0 -34.0 1.0) (36.0 -14.0 0.85) (-6.0 42.0 1.1)))

(defparameter *plaza-cracks*
  ;; the ink cracks: polylines (x z x z ...) in metres, 5 cm wide at the first point tapering to 1.5 cm;
  ;; few and hand-placed, so the page stays mostly blank
  '((0.9 -1.6  1.8 -2.1  2.3 -3.4  3.4 -4.0  3.9 -5.6)
    (2.3 -3.4  1.6 -4.3  1.8 -5.2)
    (-3.8 2.6  -4.9 3.1  -5.4 4.4  -6.9 4.9)
    (-4.9 3.1  -5.9 2.4)
    (6.2 3.3  7.4 3.9  8.1 5.4  9.7 6.0  10.4 7.6)
    (-8.4 -4.6  -7.2 -5.9  -7.5 -7.4  -6.3 -8.8)
    (-11.5 -1.0  -10.1 -0.2  -9.2 -1.3)
    (4.4 9.6  3.6 10.9  4.1 12.6)))

(declaim (type f32vec *st-acc* *st-m* *st-cracks* *st-toon* *st-toon-far*) (type fixnum *st-ncracks*))
(defvar *st-acc* (make-f32 1) "emission accumulator of the ash")
(defvar *st-m* (m4))
(defvar *st-toon* (fv 1 0 1 0) "DRAW-MESH :toon lanes of the plaza: mode 1 (moonlit), full fog ...")
(defvar *st-toon-far* (fv 1 0 0.6 0) "... and of the ruins: less fog, so their silhouettes still read against the sky.")
(defvar *st-floor* nil) (defvar *st-walls* nil) (defvar *st-town* nil) (defvar *st-burnt* nil)
(defvar *stage-fx* t "NIL: no stage particles (frozen test stills, tests/duel-vfx.lisp 3004).")

;;; cracks: +CRACK-MAX+ decals, each a center + radius and +CRACK-SEGS+ ground segments (x0 z0 x1 z1)
(defconstant +crack-max+ 8)
(defconstant +crack-segs+ 20)
(defconstant +crack-stride+ (+ 4 (* 4 +crack-segs+)))    ; x z r age, then segments
(defvar *st-cracks* (make-f32 (* +crack-max+ +crack-stride+)))
(defvar *st-ncracks* 0)

;;; ---------------------------------------------------------------- setup helpers (allocate freely)
(defvar *st-rng* 7771)
(defun st-rnd () "Deterministic 0..1 (setup only)."
  (setf *st-rng* (mod (+ (* *st-rng* 1103515245) 12345) 2147483648))
  (/ (float (ldb (byte 24 6) *st-rng*) 1.0) 16777216.0))
(defun st-r (a b) (+ a (* (- b a) (st-rnd))))
(defmacro st-at ((mb &rest xf) &body body) `(with-xform (,mb (xform ,@xf)) ,@body))

(defun st-up-quad (mb pts y)
  "Upward-facing polygon through PTS ((x z) ...) at height Y."
  (mb-poly-out mb (mapcar (lambda (p) (v3 (first p) y (second p))) pts)
               :center (list (first (first pts)) (- y 1) (second (first pts)))))

(defun st-annulus (mb r0 r1 y n)
  (dotimes (k n)
    (let ((a0 (* 2 pi (/ k n))) (a1 (* 2 pi (/ (1+ k) n))))
      (st-up-quad mb (list (list (* r0 (cos a0)) (* r0 (sin a0))) (list (* r1 (cos a0)) (* r1 (sin a0)))
                           (list (* r1 (cos a1)) (* r1 (sin a1))) (list (* r0 (cos a1)) (* r0 (sin a1))))
                  y))))

(defun st-strip (mb x0 z0 x1 z1 w0 w1 y)
  "A flat strip on the ground from (X0 Z0) to (X1 Z1), half-width W0 tapering to W1, at height Y."
  (let* ((dx (- x1 x0)) (dz (- z1 z0)) (l (max 1e-4 (sqrt (+ (* dx dx) (* dz dz))))) (nx (/ (- dz) l)) (nz (/ dx l)))
    (st-up-quad mb (list (list (- x0 (* w0 nx)) (- z0 (* w0 nz))) (list (+ x0 (* w0 nx)) (+ z0 (* w0 nz)))
                         (list (+ x1 (* w1 nx)) (+ z1 (* w1 nz))) (list (- x1 (* w1 nx)) (- z1 (* w1 nz))))
                y)))

(defun st-crack (mb pts)
  "One ink crack along the polyline PTS (x z x z ...), 5 cm wide at its start, 1.5 cm at its end."
  (let* ((xs (loop for (x z) on pts by #'cddr collect (list x z))) (n (1- (length xs))))
    (loop for (p q) on xs while q for i from 0
          do (st-strip mb (first p) (second p) (first q) (second q)
                       (- 0.025 (* 0.0175 (/ i n))) (- 0.025 (* 0.0175 (/ (1+ i) n))) 0.006))))

(defun build-floor ()
  "The page: one disc of moonlit stone (V2), the ink cracks, faint joints in the outer ring only,
the curb, and the darker ground outside."
  (build-mesh (mb :color (hexc #x767D8E))
    (st-annulus mb 0.0 15.1 0.0 64)
    (mbc mb #x6A7182)                                    ; stone joints: two rings and radial lines, ~1 px
    (dolist (r '(11.3 13.2)) (st-annulus mb (- r 0.008) (+ r 0.008) 0.003 96))
    (dotimes (k 40)
      (let ((a (* 2 pi (/ (+ k 0.5) 40))))
        (st-strip mb (* 11.3 (cos a)) (* 11.3 (sin a)) (* 15.05 (cos a)) (* 15.05 (sin a)) 0.008 0.008 0.003)))
    (mbc mb #x262A36)                                    ; ink cracks
    (dolist (c *plaza-cracks*) (st-crack mb c))
    (mbc mb #x5C6272)                                    ; the curb
    (st-at (mb :y 0.06) (mb-cylinder mb 15.6 0.12 :segments 64 :caps nil))
    (st-annulus mb 15.1 15.6 0.12 64)
    (mbc mb #x3C4150)                                    ; the ground outside
    (st-annulus mb 15.6 160.0 -0.01 64)))

(defun st-wall-segment (mb len h broken)
  "One wall panel of LEN x H on a stone footing: a cold-grey silhouette; unless BROKEN, its tiled cap
catches the moon (the thin edge light of the skyline)."
  (mbc mb #x30343F) (st-at (mb :y 0.2) (mb-box mb (+ len 0.1) 0.4 0.6))
  (mbc mb #x464B5C)
  (if broken
      (let ((h1 (st-r 0.8 (* 0.8 h))) (h2 (st-r 0.5 (* 0.6 h))))
        (st-at (mb :x (* -0.25 len) :y (+ 0.4 (* 0.5 h1))) (mb-box mb (* 0.5 len) h1 0.45))
        (st-at (mb :x (* 0.25 len) :y (+ 0.4 (* 0.5 h2))) (mb-box mb (* 0.5 len) h2 0.45))
        (mbc mb #x30343F)                                ; rubble
        (dotimes (i 4) (st-at (mb :x (st-r (- len) len) :y 0.15 :z (st-r 0.4 1.4) :yaw (st-r 0 3)) (mb-box mb (st-r 0.3 0.7) 0.3 (st-r 0.3 0.6)))))
      (progn
        (st-at (mb :y (+ 0.4 (* 0.5 h))) (mb-box mb len h 0.45))
        (mbc mb #x50566A)
        (st-at (mb :y (+ 0.5 h)) (mb-box mb (+ len 0.2) 0.2 0.9))
        (st-at (mb :y (+ 0.68 h) :pitch 0.785) (mb-box mb (+ len 0.2) 0.22 0.22))
        (st-at (mb :y (+ 0.62 h) :pitch 0.3 :z 0.25) (mb-box mb (+ len 0.3) 0.06 0.5))
        (st-at (mb :y (+ 0.62 h) :pitch -0.3 :z -0.25) (mb-box mb (+ len 0.3) 0.06 0.5)))))

(defun build-walls ()
  "The ring of broken walls at r 19 (no collision): intact, broken or missing panels."
  (build-mesh (mb)
    (let ((n 30) (r 19.0))
      (dotimes (k n)
        (let* ((a (* 2 pi (/ (+ k 0.5) n))) (roll (st-rnd)))
          (unless (< roll 0.18)
            (st-at (mb :x (* r (sin a)) :z (* r (cos a)) :yaw a)
              (st-wall-segment mb 3.9 2.4 (< roll 0.45)))))))))

(defun st-roof (mb y w d h)
  "Hipped roof: a 4-sided pyramid of base W x D and height H centred at height Y."
  (st-at (mb :y y :sx (* 0.7071 w) :sz (* 0.7071 d))
    (st-at (mb :yaw (/ pi 4)) (mb-cone mb 1.0 h :segments 4))))

(defun st-house (mb w d h &key (roof #x363A48) (wall #x484D60) (beam #x2C303C) (storeys 1))
  "A Seireitei house in silhouette: grey walls with darker beams, a dark hipped roof with eaves."
  (dotimes (s storeys)
    (let* ((k (- 1 (* 0.25 s))) (w (* w k)) (d (* d k)) (y0 (* s (+ h 0.9))))
      (mbc mb wall) (st-at (mb :y (+ y0 (* 0.5 h))) (mb-box mb w h d))
      (mbc mb beam)
      (dolist (sx '(-0.5 -0.17 0.17 0.5))
        (st-at (mb :x (* sx (- w 0.1)) :y (+ y0 (* 0.5 h)) :z (* 0.5 d)) (mb-box mb 0.14 h 0.06)))
      (st-at (mb :y (+ y0 (* 0.8 h)) :z (* 0.5 d)) (mb-box mb w 0.14 0.06))
      (mbc mb roof)
      (st-at (mb :y (+ y0 h 0.05)) (mb-box mb (+ w 1.2) 0.1 (+ d 1.2)))                        ; eaves
      (st-roof mb (+ y0 h 0.75) (+ w 1.2) (+ d 1.2) 1.4))))

(defun build-town ()
  "Houses around the plaza (r 25-48) and a far skyline of dark roofs (r 80-110)."
  (build-mesh (mb)
    (dotimes (k 16)
      (let* ((a (+ (* 2 pi (/ k 16)) (st-r -0.12 0.12))) (r (st-r 25 34)))
        (st-at (mb :x (* r (sin a)) :z (* r (cos a)) :yaw (+ a pi (st-r -0.2 0.2)))
          (st-house mb (st-r 6 10) (st-r 5 7) (st-r 2.8 3.6) :storeys (if (< (st-rnd) 0.3) 2 1)))))
    (dotimes (k 12)
      (let* ((a (+ (* 2 pi (/ (+ k 0.5) 12)) (st-r -0.1 0.1))) (r (st-r 40 50)))
        (st-at (mb :x (* r (sin a)) :z (* r (cos a)) :yaw (+ a pi (st-r -0.3 0.3)))
          (st-house mb (st-r 8 14) (st-r 6 9) (st-r 3.5 5) :storeys (if (< (st-rnd) 0.5) 2 1)
                       :wall #x3E4354))))
    (dotimes (k 40)                                      ; far skyline silhouettes
      (let* ((a (* 2 pi (/ k 40))) (r (st-r 80 110)) (w (st-r 10 22)) (h (st-r 4 12)))
        (st-at (mb :x (* r (sin a)) :z (* r (cos a)) :yaw a)
          (mbc mb #x343846) (st-at (mb :y (* 0.5 h)) (mb-box mb w h 8))
          (mbc mb #x262A34) (st-roof mb (+ h 1.2) (* 1.05 w) 8.5 2.4))))))

(defun build-burnt ()
  "Three burnt-out buildings beyond the town: charred frames and broken roofs."
  (build-mesh (mb)
    (loop for (x z s) in *stage-ruins* do
      (st-at (mb :x x :z z :yaw (st-r 0 3) :s s)
        (mbc mb #x2E3240) (st-at (mb :y 2.2) (mb-box mb 10 4.4 7))
        (mbc mb #x262A34)
        (dotimes (i 6) (st-at (mb :x (st-r -5 5) :y (st-r 4.5 7) :z (st-r -3.5 3.5) :pitch (st-r -0.6 0.6) :roll (st-r -0.6 0.6))
                         (mb-box mb 0.3 (st-r 2 4) 0.3)))                              ; charred beams
        (mbc mb #x343846) (st-at (mb :x -2 :roll 0.25) (st-roof mb 5.2 7 5.5 1.6))))))

(defun stage-init ()
  "Startup (:load) step: build the stage meshes (deterministic)."
  (let ((*st-rng* 7771))
    (setf *st-floor* (build-floor) *st-walls* (build-walls) *st-town* (build-town) *st-burnt* (build-burnt))
    (stage-clear-cracks)))

;;; ---------------------------------------------------------------- environment
(defun stage-env ()
  "Night (§6): the toon look on; a cold dark sky (zenith #1A1E2A to horizon #363B4C = the fog), a
huge flat moon low behind the arena (seen from the pair camera) with two faint halo rings, which
also gives the stage its light direction; cold fog that sinks the far ground into the horizon tone; bloom only
on effect cores; a vignette."
  (let ((e *env*))
    (flet ((set3 (v h) (destructuring-bind (r g b) (hexc h) (v3-set! v (f32 r) (f32 g) (f32 b)))))
      (set3 (env-sky-top e) #x1A1E2A)
      (set3 (env-fog-color e) #x363B4C)
      (set3 (env-moon-color e) #xD6DAE0))
    (v3-normalize! (env-moon-dir e) (v3 -0.3 0.16 -0.92))           ; behind-left, 9 deg up: behind the rooftops
    (setf (env-toon e) t
          (env-fog-density e) 0.012 (env-fog-base e) 0.0 (env-fog-falloff e) 0.06 (env-fog-max e) 0.92
          (env-moon-intensity e) 1.0 (env-sun-size e) 6.0 (env-sun-glow e) 0.012
          (env-exposure e) 1.0 (env-bloom e) t (env-bloom-threshold e) 0.97 (env-bloom-strength e) 0.6
          (env-vignette e) 0.25)))

;;; ---------------------------------------------------------------- cracks (Bankai)
(defun stage-clear-cracks () (setf *st-ncracks* 0))

(defun stage-crack-add (x z r)
  "A cracked patch of radius R at (X Z): 5 branching ink gashes with ember cores (ST-DRAW-CRACKS). Keeps
the newest +CRACK-MAX+ (the oldest is replaced)."
  (let* ((c *st-cracks*) (i (mod *st-ncracks* +crack-max+)) (o (* i +crack-stride+)) (s 4))
    (setf (aref c o) (f32 x) (aref c (+ o 1)) (f32 z) (aref c (+ o 2)) (f32 r) (aref c (+ o 3)) 0f0)
    ;; 5 jagged rays from the centre, 4 segments each, bending randomly
    (dotimes (ray 5)
      (let* ((a (+ (* ray 1.2566) (rnd-range -0.4 0.4))) (px (f32 x)) (pz (f32 z)) (step (/ (f32 r) 4.0)))
        (dotimes (k 4)
          (let* ((a2 (+ a (rnd-range -0.6 0.6))) (nx (+ px (* step (cos a2)))) (nz (+ pz (* step (sin a2)))))
            (setf (aref c (+ o s)) px (aref c (+ o s 1)) pz (aref c (+ o s 2)) (f32 nx) (aref c (+ o s 3)) (f32 nz))
            (incf s 4) (setf px (f32 nx) pz (f32 nz))))))
    (incf *st-ncracks*)
    nil))

(defmacro st-glow-seg (x0 z0 x1 z1 y w r g b a)
  "Queue a soft additive strip on the ground (x0 z0)->(x1 z1) at height Y, half-width W, colour (R G B), alpha A:
a glowing core line (T光) over a drawn gash. A macro: 0 B."
  `(let* ((x0 ,x0) (z0 ,z0) (x1 ,x1) (z1 ,z1) (gy ,y) (w ,w) (r ,r) (g ,g) (b ,b) (a ,a)
          (dx (- x1 x0)) (dz (- z1 z0)) (l (f-sqrt (+ (* dx dx) (* dz dz)))))
     (declare (single-float x0 z0 x1 z1 gy w r g b a dx dz l))
     (when (> l 1f-4)
       (let* ((nx (* w (/ (- dz) l))) (nz (* w (/ dx l))))
         (declare (single-float nx nz))
         (with-fx-verts (d o :add 6)
           (vtx (- x0 nx) gy (- z0 nz) 0f0 -1f0 r g b a) (vtx (+ x0 nx) gy (+ z0 nz) 0f0 1f0 r g b a)
           (vtx (+ x1 nx) gy (+ z1 nz) 0f0 1f0 r g b a) (vtx (- x0 nx) gy (- z0 nz) 0f0 -1f0 r g b a)
           (vtx (+ x1 nx) gy (+ z1 nz) 0f0 1f0 r g b a) (vtx (- x1 nx) gy (- z1 nz) 0f0 -1f0 r g b a))))))

(defmacro toon-ground-seg (x0 z0 x1 z1 y w h0 h1 seed wob pk)
  "Queue a flat toon strip on the ground (the toon fx batch, docs/STYLE_STORM_DESIGN.md §3.2) from (x0 z0) to
(x1 z1) at height Y, half-width W: an along shape (SEED is made negative) whose field runs across it, heat H0
at the start .. H1 at the end (the low-heat end erodes first as the presence in PK fades). A macro: 0 B."
  `(let* ((x0 ,x0) (z0 ,z0) (x1 ,x1) (z1 ,z1) (gy ,y) (w ,w) (h0 ,h0) (h1 ,h1) (sd (- -1f0 (f-abs ,seed))) (wb ,wob) (pk ,pk)
          (dx (- x1 x0)) (dz (- z1 z0)) (l (f-sqrt (+ (* dx dx) (* dz dz)))))
     (declare (single-float x0 z0 x1 z1 gy w h0 h1 sd wb pk dx dz l))
     (when (> l 1f-4)
       (let* ((nx (* w (/ (- dz) l))) (nz (* w (/ dx l))))
         (declare (single-float nx nz))
         (with-fx-verts (d o :toon 6)
           (vtx (- x0 nx) gy (- z0 nz) -1f0 0f0 h0 sd wb pk)
           (vtx (+ x0 nx) gy (+ z0 nz) 1f0 0f0 h0 sd wb pk)
           (vtx (+ x1 nx) gy (+ z1 nz) 1f0 0f0 h1 sd wb pk)
           (vtx (- x0 nx) gy (- z0 nz) -1f0 0f0 h0 sd wb pk)
           (vtx (+ x1 nx) gy (+ z1 nz) 1f0 0f0 h1 sd wb pk)
           (vtx (- x1 nx) gy (- z1 nz) -1f0 0f0 h1 sd wb pk))))))

(defun-fast st-draw-cracks ()
  "Bankai's cracks (docs/STYLE_STORM_DESIGN.md §4.1): each ray an ink gash (BLACK SMOKE, a white hairline on the
mid-grey page) narrowing and eroding toward the ray's end, with a glowing ember core (a thin additive line: a drawn
toon line this thin would be all edge) whose brightness breathes on threes (the fx clock)."
  (let* ((tm (fx-clock)) (c *st-cracks*) (n (min *st-ncracks* +crack-max+)) (d3 (i->f (logand (f->i (* 8f0 tm)) 63))))
    (declare (single-float tm) (type f32vec c) (fixnum n) (single-float d3))
    (dotimes (i n)
      (let* ((o (* i +crack-stride+)) (fi (i->f i))
             (pk (+ 0.6f0 (* 0.4f0 (f-abs (f-sin (+ (* 1.7f0 d3) (* 2.3f0 fi))))))))
        (declare (fixnum o) (single-float fi pk))
        (dotimes (k +crack-segs+)
          (let* ((s (+ o 4 (* k 4))) (j (i->f (mod k 4))) (h0 (- 1f0 (* 0.2f0 j))) (h1 (- h0 0.2f0))
                 (w (* 0.09f0 (- 1f0 (* 0.18f0 j)))) (sd (+ (* 5f0 fi) (i->f k))))
            (declare (fixnum s) (single-float j h0 h1 w sd))
            (toon-ground-seg (aref c s) (aref c (+ s 1)) (aref c (+ s 2)) (aref c (+ s 3)) 0.035f0 w h0 h1 sd 0.25f0
                             (toon-a +pal-black-smoke+ 0.98f0))
            (st-glow-seg (aref c s) (aref c (+ s 1)) (aref c (+ s 2)) (aref c (+ s 3)) 0.042f0 (* 0.4f0 w) 1f0 0.3f0 0.08f0 (- pk))))))))

;;; ---------------------------------------------------------------- per-frame ash
(defmacro st-every ((acc-index rate dt) &body body)
  "Run BODY RATE times per second on average (accumulator slot ACC-INDEX of *ST-ACC*)."
  `(let* ((acc *st-acc*))
     (declare (type f32vec acc))
     (setf (aref acc ,acc-index) (+ (aref acc ,acc-index) (* ,rate ,dt)))
     (loop while (>= (aref acc ,acc-index) 1f0) do
       (setf (aref acc ,acc-index) (- (aref acc ,acc-index) 1f0))
       ,@body)))

(defun-fast st-ash-fx (dt)
  "White ash drifting down over the plaza around the camera target (10 flakes/s x 6 s = ~60 live)."
  (declare (single-float dt))
  (let* ((tg (camera-target *camera*)))
    (declare (type f32vec tg))
    (st-every (0 10f0 dt)
      (fx-emit +p-feather+ (+ (aref tg 0) (rnd-range -12f0 12f0)) (rnd-range 5f0 9f0) (+ (aref tg 2) (rnd-range -12f0 12f0))
               (rnd-range 0.1f0 0.3f0) (rnd-range -0.3f0 0f0) (rnd-range -0.2f0 0.2f0)
               6f0 0.06f0 1f0 0.93f0 0.94f0 0.96f0))))

(defun stage-draw (rdt)
  "Queue the stage for this frame (after the camera is set). RDT = real seconds."
  (let ((m (m4-identity! *st-m*)) (far *st-toon-far*))
    (draw-mesh *st-floor* m :toon *st-toon*)
    (draw-mesh *st-walls* m :toon far)
    (draw-mesh *st-town* m :toon far)
    (draw-mesh *st-burnt* m :toon far))
  (when *stage-fx* (st-ash-fx (f32 rdt)))
  (st-draw-cracks))
