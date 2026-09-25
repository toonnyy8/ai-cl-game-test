;;;; stage.lisp — "Burning Seireitei at dusk" (design §9): a round flagstone plaza (r 15 m) with a
;;;; low curb, a ring of broken white walls with tiled caps, tiled-roof buildings around it, three
;;;; burning buildings in the distance (flame / smoke / spark particles, 2 point lights, halo sprites),
;;;; falling ash and drifting embers, and the dusk sky (purple zenith, orange horizon, a low red sun).
;;;; Bankai dries and cracks the plaza: STAGE-CRACK-ADD keeps a few ember-crack decals.
;;;; API: (stage-init) :load step (meshes) · (stage-env) sets *ENV* · (stage-draw rdt) every frame
;;;;      after the camera (RDT = real seconds; fire keeps burning through hitstop and cinematics)
;;;;      · (stage-crack-add x z r) · (stage-clear-cracks). The plaza radius (15 m) is the gameplay's.
;;;; Budget: ≤ ~250 live stage particles, 2 point lights, 7 mesh draws; conses ~1 KB/frame (FX-EMIT).
(in-package :duel)

;;; ---------------------------------------------------------------- data
(defparameter *stage-fires*
  ;; x y z scale (m): the three burning buildings, far outside the walls
  '((-24.0 5.0 -34.0 1.0) (36.0 4.0 -14.0 0.85) (-6.0 6.0 42.0 1.1)))

(declaim (type f32vec *st-fires* *st-acc* *st-lights* *st-m* *st-cracks*) (type fixnum *st-ncracks*))
(defvar *st-fires* (let ((v (make-f32 16)))
                     (loop for (x y z s) in *stage-fires* for o from 0 by 4
                           do (setf (aref v o) x (aref v (+ o 1)) y (aref v (+ o 2)) z (aref v (+ o 3)) s))
                     v))
(defvar *st-acc* (make-f32 8) "emission accumulators: 0-2 flame per fire, 3 smoke, 4 spark, 5 ash, 6 ember")
(defvar *st-lights* (fv -24 6 -34 1.0 0.5 0.18 48 2.2   36 5 -14 1.0 0.45 0.15 44 2.0)
  "The two stage fire lights (x y z r g b radius intensity); intensities flicker in place.")
(defvar *st-m* (m4))
(defvar *st-floor* nil) (defvar *st-walls* nil) (defvar *st-town* nil) (defvar *st-burnt* nil)
(defvar *st-embers* nil) (defvar *st-sky* nil)

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

(defun build-floor ()
  "Mortar disc, rings of flagstones (a pale seal ring at r 3), the curb, dusty ground outside."
  (build-mesh (mb :jitter 0.05 :color (hexc #x3A322C))
    (st-annulus mb 0.0 15.4 0.0 48)
    (loop with r = 1.3
          while (< r 14.9) do
            (let* ((r1 (min 14.9 (+ r (st-r 0.9 1.3)))) (n (max 6 (round (* 2 pi r1) 1.25)))
                   (seal (< 2.6 r 3.9)) (off (st-rnd)))
              (dotimes (k n)
                (let* ((a0 (* 2 pi (/ (+ k off 0.03) n))) (a1 (* 2 pi (/ (+ k off 0.97) n)))
                       (ra (+ r 0.04)) (rb (- r1 0.04)) (y (st-r 0.012 0.03))
                       (g (if seal (st-r 0.62 0.7) (st-r 0.44 0.56))) (warm (st-r 0.0 0.04)))
                  (when (< (st-rnd) 0.08) (setf g (* g 0.6)))            ; scorched stones
                  (mb-color mb (+ g warm 0.03) (+ g (* 0.5 warm)) (- g 0.02))
                  (st-up-quad mb (list (list (* ra (cos a0)) (* ra (sin a0))) (list (* rb (cos a0)) (* rb (sin a0)))
                                       (list (* rb (cos a1)) (* rb (sin a1))) (list (* ra (cos a1)) (* ra (sin a1))))
                              y)))
              (setf r r1)))
    (mbc mb #x6A6058)                                    ; the center seal
    (st-at (mb :y 0.02) (mb-cylinder mb 1.2 0.04 :segments 8))
    (mbc mb #x77706A)                                    ; the curb
    (st-at (mb :y 0.06) (mb-cylinder mb 15.6 0.12 :segments 48 :caps nil))
    (st-annulus mb 15.1 15.6 0.12 48)
    (mbc mb #x4A3B30)                                    ; dusty ground
    (st-annulus mb 15.6 160.0 -0.01 48)))

(defun st-wall-segment (mb len h broken)
  "One white wall panel of LEN x H on a stone footing, with a dark tile cap unless BROKEN."
  (mbc mb #x5A544E) (st-at (mb :y 0.2) (mb-box mb (+ len 0.1) 0.4 0.6))
  (mbc mb #xC2BAAE)                                    ; plaster (not white: the low sun would blow it out)
  (if broken
      (let ((h1 (st-r 0.8 (* 0.8 h))) (h2 (st-r 0.5 (* 0.6 h))))
        (st-at (mb :x (* -0.25 len) :y (+ 0.4 (* 0.5 h1))) (mb-box mb (* 0.5 len) h1 0.45))
        (st-at (mb :x (* 0.25 len) :y (+ 0.4 (* 0.5 h2))) (mb-box mb (* 0.5 len) h2 0.45))
        (mbc mb #x8A8278)                                ; rubble
        (dotimes (i 4) (st-at (mb :x (st-r (- len) len) :y 0.15 :z (st-r 0.4 1.4) :yaw (st-r 0 3)) (mb-box mb (st-r 0.3 0.7) 0.3 (st-r 0.3 0.6)))))
      (progn
        (st-at (mb :y (+ 0.4 (* 0.5 h))) (mb-box mb len h 0.45))
        (mbc mb #x2E3038)
        (st-at (mb :y (+ 0.5 h)) (mb-box mb (+ len 0.2) 0.2 0.9))
        (st-at (mb :y (+ 0.68 h) :pitch 0.785) (mb-box mb (+ len 0.2) 0.22 0.22))
        (mbc mb #x3E4048)
        (st-at (mb :y (+ 0.62 h) :pitch 0.3 :z 0.25) (mb-box mb (+ len 0.3) 0.06 0.5))
        (st-at (mb :y (+ 0.62 h) :pitch -0.3 :z -0.25) (mb-box mb (+ len 0.3) 0.06 0.5)))))

(defun build-walls ()
  "The ring of white walls at r 19 (no collision): intact, broken or missing panels."
  (build-mesh (mb :jitter 0.05)
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

(defun st-house (mb w d h &key (roof #x353843) (wall #xBEB6A8) (beam #x3A2A20) (storeys 1))
  "A Seireitei house: plastered walls with dark beams, a hipped tiled roof with eaves."
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
  (build-mesh (mb :jitter 0.06)
    (dotimes (k 16)
      (let* ((a (+ (* 2 pi (/ k 16)) (st-r -0.12 0.12))) (r (st-r 25 34)))
        (st-at (mb :x (* r (sin a)) :z (* r (cos a)) :yaw (+ a pi (st-r -0.2 0.2)))
          (st-house mb (st-r 6 10) (st-r 5 7) (st-r 2.8 3.6) :storeys (if (< (st-rnd) 0.3) 2 1)))))
    (dotimes (k 12)
      (let* ((a (+ (* 2 pi (/ (+ k 0.5) 12)) (st-r -0.1 0.1))) (r (st-r 40 50)))
        (st-at (mb :x (* r (sin a)) :z (* r (cos a)) :yaw (+ a pi (st-r -0.3 0.3)))
          (st-house mb (st-r 8 14) (st-r 6 9) (st-r 3.5 5) :storeys (if (< (st-rnd) 0.5) 2 1)
                       :wall #xB0A898))))
    (dotimes (k 40)                                      ; far skyline silhouettes
      (let* ((a (* 2 pi (/ k 40))) (r (st-r 80 110)) (w (st-r 10 22)) (h (st-r 4 12)))
        (st-at (mb :x (* r (sin a)) :z (* r (cos a)) :yaw a)
          (mbc mb #x2A2430) (st-at (mb :y (* 0.5 h)) (mb-box mb w h 8))
          (mbc mb #x1E1C26) (st-roof mb (+ h 1.2) (* 1.05 w) 8.5 2.4))))))

(defun build-burnt ()
  "The three burning buildings: charred frames and broken roofs, and (second value) the glowing
gaps in their walls, drawn emissive."
  (let ((embers (make-mesh-builder)))
    (mb-color embers 1 1 1)
    (values
     (build-mesh (mb :jitter 0.1)
       (loop for (x y z s) in *stage-fires* do
         (let ((place (xform :x x :z z :yaw (st-r 0 3) :s s)))
           (with-xform (mb place)
             (mbc mb #x1C1714) (st-at (mb :y 2.2) (mb-box mb 10 4.4 7))
             (mbc mb #x100D0C)
             (dotimes (i 6) (st-at (mb :x (st-r -5 5) :y (st-r 4.5 7) :z (st-r -3.5 3.5) :pitch (st-r -0.6 0.6) :roll (st-r -0.6 0.6))
                              (mb-box mb 0.3 (st-r 2 4) 0.3)))                              ; charred beams
             (mbc mb #x2A2622) (st-at (mb :x -2 :roll 0.25) (st-roof mb 5.2 7 5.5 1.6)))
           (with-xform (embers place)
             (dotimes (i 5)
               (let ((gy (st-r 0.8 3.6)) (gw (st-r 0.8 2.2)))
                 (st-at (embers :x (st-r -4 4) :y gy :z 3.52) (mb-box embers gw (st-r 0.5 1.4) 0.05))
                 (st-at (embers :x 5.02 :y gy :z (st-r -2.5 2.5)) (mb-box embers 0.05 (st-r 0.5 1.2) gw))))))))
     (mb-build embers))))

(defun stage-init ()
  "Startup (:load) step: build the stage meshes (deterministic)."
  (let ((*st-rng* 7771))
    (setf *st-floor* (build-floor) *st-walls* (build-walls) *st-town* (build-town))
    (multiple-value-setq (*st-burnt* *st-embers*) (build-burnt))
    (stage-clear-cracks)))

;;; ---------------------------------------------------------------- environment
(defun stage-env ()
  "Dusk: purple zenith, orange horizon fog, a big low red-orange sun (the moon disc, 2.4x size, strong
halo), warm rim, bloom."
  (let ((e *env*))
    (flet ((set3 (v h) (destructuring-bind (r g b) (hexc h) (v3-set! v (f32 r) (f32 g) (f32 b)))))
      (set3 (env-sky-top e) #x2A1848)
      (set3 (env-fog-color e) #xC8683A)
      (set3 (env-ambient-sky e) #x6A6478)
      (set3 (env-ambient-ground e) #x3A2A22)
      (set3 (env-moon-color e) #xFF8E58)
      (set3 (env-rim-color e) #xFF9A5A))
    (v3-normalize! (env-moon-dir e) (v3 -0.75 0.14 -0.65))
    (setf (env-fog-density e) 0.008 (env-fog-base e) 0.0 (env-fog-falloff e) 0.06 (env-fog-max e) 0.92
          (env-ambient-intensity e) 0.55 (env-moon-intensity e) 0.8
          (env-rim-intensity e) 0.3 (env-rim-power e) 3.5 (env-sun-size e) 2.4 (env-sun-glow e) 0.5
          (env-specular e) 0.12 (env-shininess e) 24.0 (env-exposure e) 1.08
          (env-bloom e) t (env-bloom-threshold e) 0.75 (env-bloom-strength e) 0.6 (env-vignette e) 0.38)))

;;; ---------------------------------------------------------------- cracks (Bankai)
(defun stage-clear-cracks () (setf *st-ncracks* 0))

(defun stage-crack-add (x z r)
  "A dried, cracked patch of radius R at (X Z): a dark decal plus branching ember cracks. Keeps the
newest +CRACK-MAX+ (the oldest is replaced)."
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

(defmacro st-ground-seg (x0 z0 x1 z1 w r g b a mode)
  "Queue a flat quad on the ground from (x0 z0) to (x1 z1), half-width W, in fx batch MODE.
A macro so the caller's unboxed floats stay unboxed (a function call would box 10 floats)."
  `(let* ((x0 ,x0) (z0 ,z0) (x1 ,x1) (z1 ,z1) (w ,w) (r ,r) (g ,g) (b ,b) (a ,a)
          (dx (- x1 x0)) (dz (- z1 z0)) (l (f-sqrt (+ (* dx dx) (* dz dz)))) (y 0.035f0))
     (declare (single-float x0 z0 x1 z1 w r g b a dx dz l y))
     (when (> l 1f-4)
       (let* ((nx (* w (/ (- dz) l))) (nz (* w (/ dx l))))
         (declare (single-float nx nz))
         (with-fx-verts (d o ,mode 6)
           (vtx (- x0 nx) y (- z0 nz) 0f0 -1f0 r g b a)
           (vtx (+ x0 nx) y (+ z0 nz) 0f0 1f0 r g b a)
           (vtx (+ x1 nx) y (+ z1 nz) 0f0 1f0 r g b a)
           (vtx (- x0 nx) y (- z0 nz) 0f0 -1f0 r g b a)
           (vtx (+ x1 nx) y (+ z1 nz) 0f0 1f0 r g b a)
           (vtx (- x1 nx) y (- z1 nz) 0f0 -1f0 r g b a))))))

(defun-fast st-draw-cracks (tm)
  (declare (single-float tm))
  (let* ((c *st-cracks*) (n (min *st-ncracks* +crack-max+)))
    (declare (type f32vec c) (fixnum n))
    (dotimes (i n)
      (let* ((o (* i +crack-stride+)) (x (aref c o)) (z (aref c (+ o 1))) (r (aref c (+ o 2)))
             (pulse (+ 0.8f0 (* 0.2f0 (f-sin (+ (* 2.3f0 tm) (i->f i)))))))
        (declare (fixnum o) (single-float x z r pulse))
        (fx-decal x 0.01 z (* 1.25 r) 0.13 0.08 0.05 0.6)
        (dotimes (k +crack-segs+)
          (let* ((s (+ o 4 (* k 4))))
            (declare (fixnum s))
            (st-ground-seg (aref c s) (aref c (+ s 1)) (aref c (+ s 2)) (aref c (+ s 3)) 0.11f0 0.04f0 0.015f0 0.01f0 0.95f0 :alpha)
            (st-ground-seg (aref c s) (aref c (+ s 1)) (aref c (+ s 2)) (aref c (+ s 3)) 0.07f0 1f0 0.38f0 0.08f0 pulse :add)))))))

;;; ---------------------------------------------------------------- per-frame fire, smoke, ash
(defmacro st-every ((acc-index rate dt) &body body)
  "Run BODY RATE times per second on average (accumulator slot ACC-INDEX of *ST-ACC*)."
  `(let* ((acc *st-acc*))
     (declare (type f32vec acc))
     (setf (aref acc ,acc-index) (+ (aref acc ,acc-index) (* ,rate ,dt)))
     (loop while (>= (aref acc ,acc-index) 1f0) do
       (setf (aref acc ,acc-index) (- (aref acc ,acc-index) 1f0))
       ,@body)))

(defun-fast st-fire-fx (dt)
  (declare (single-float dt))
  (let* ((f *st-fires*) (tg (camera-target *camera*)))
    (declare (type f32vec f tg))
    (dotimes (i 3)
      (let* ((o (* i 4)) (x (aref f o)) (y (aref f (+ o 1))) (z (aref f (+ o 2))) (s (aref f (+ o 3))))
        (declare (fixnum o) (single-float x y z s))
        (st-every (i 30f0 dt)                           ; flames: rising, shrinking additive glow
          (fx-emit +p-glow+ (+ x (* s (rnd-range -4f0 4f0))) (+ y (rnd-range -1.5f0 1.5f0)) (+ z (* s (rnd-range -3f0 3f0)))
                   (rnd-range -0.4f0 0.4f0) (rnd-range 1.5f0 3f0) (rnd-range -0.4f0 0.4f0)
                   (rnd-range 0.8f0 1.2f0) (* s (rnd-range 1.6f0 2.6f0)) -3f0
                   1f0 (rnd-range 0.35f0 0.6f0) 0.08f0))
        (fx-billboard x (+ y 1.5) z (* s 9.0) 1.0 0.38 0.1 0.22)))   ; the glow halo
    (st-every (3 24f0 dt)                               ; smoke columns (dark, rising, spreading)
      (let* ((o (* 4 (the fixnum (min 2 (f->i (* 3f0 (rnd01))))))) (s (aref f (+ o 3))))
        (declare (fixnum o) (single-float s))
        (fx-emit +p-mist+ (+ (aref f o) (* s (rnd-range -3f0 3f0))) (+ (aref f (+ o 1)) 3f0) (+ (aref f (+ o 2)) (* s (rnd-range -3f0 3f0)))
                 (rnd-range 0.3f0 1.2f0) (rnd-range 1f0 2f0) (rnd-range -0.4f0 0.4f0)
                 (rnd-range 2.6f0 3.4f0) (* s (rnd-range 2.2f0 3.2f0)) -6f0
                 0.2f0 0.15f0 0.14f0)))
    (st-every (4 18f0 dt)                               ; sparks shooting out of the fires
      (let* ((o (* 4 (the fixnum (min 2 (f->i (* 3f0 (rnd01))))))))
        (declare (fixnum o))
        (fx-emit +p-spark+ (aref f o) (+ (aref f (+ o 1)) 2f0) (aref f (+ o 2))
                 (rnd-range -3f0 3f0) (rnd-range 5f0 9f0) (rnd-range -3f0 3f0)
                 (rnd-range 1f0 1.6f0) 0.08f0 3f0 1f0 0.55f0 0.15f0)))
    (st-every (5 6f0 dt)                                ; ash: grey flakes falling over the plaza
      (fx-emit +p-feather+ (+ (aref tg 0) (rnd-range -12f0 12f0)) (rnd-range 5f0 9f0) (+ (aref tg 2) (rnd-range -12f0 12f0))
               (rnd-range 0.2f0 0.6f0) (rnd-range -0.3f0 0f0) (rnd-range -0.2f0 0.2f0)
               6f0 0.05f0 1f0 0.55f0 0.52f0 0.5f0))
    (st-every (6 10f0 dt)                               ; embers drifting up and sideways
      (fx-emit +p-glow+ (+ (aref tg 0) (rnd-range -12f0 12f0)) (rnd-range 0.2f0 2f0) (+ (aref tg 2) (rnd-range -12f0 12f0))
               (rnd-range 0.3f0 0.9f0) (rnd-range 0.2f0 0.6f0) (rnd-range -0.3f0 0.3f0)
               3f0 0.035f0 -0.25f0 1f0 0.45f0 0.1f0))
    ;; two flickering fire lights
    (let* ((l *st-lights*) (tm (the single-float (elapsed-time))))
      (declare (type f32vec l) (single-float tm))
      (setf (aref l 7) (+ 2.0f0 (* 0.35f0 (f-sin (* 9.1f0 tm))) (* 0.2f0 (f-sin (* 23.7f0 tm))))
            (aref l 15) (+ 1.8f0 (* 0.3f0 (f-sin (* 7.3f0 tm))) (* 0.2f0 (f-sin (* 19.3f0 tm)))))
      (add-point-light-v l 0 10)                        ; priority 10: effects never push them out
      (add-point-light-v l 8 10))))

(defun stage-draw (rdt)
  "Queue the stage for this frame (after the camera is set). RDT = real seconds."
  (let ((m (m4-identity! *st-m*)))
    (draw-mesh *st-floor* m :specular 0.1 :env-rim 0.0)  ; no grazing-angle rim on the set: it read as haze
    (draw-mesh *st-walls* m :specular 0.0 :env-rim 0.0)
    (draw-mesh *st-town* m :specular 0.0 :env-rim 0.0)
    (draw-mesh *st-burnt* m :specular 0.0 :env-rim 0.0)
    (draw-mesh *st-embers* m :tint '(1.0 0.3 0.07) :emissive (+ 1.3 (* 0.3 (sin (* 11.0 (elapsed-time))))) :specular 0.0))
  (st-fire-fx (f32 rdt))
  (st-draw-cracks (the single-float (elapsed-time))))
