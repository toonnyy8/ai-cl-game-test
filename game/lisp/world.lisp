;;;; world.lisp — the rooftop arena: environment look, static scenery, skyline, rain, collision.
;;;; GAME_DESIGN §6.2 (props), §7.6 (rain), §9 (palette/lighting). Docs: docs/engine/WORLD.md.
;;;; Public API: WORLD-INIT, WORLD-UPDATE, WORLD-DRAW, ARENA-RESOLVE, ARENA-RAYCAST,
;;;;             ARENA-GROUND-HEIGHT, *ARENA-HALF*, *RAIN-COUNT*, *RAIN-COLOR*.
;;;; Static scenery = a handful of merged meshes; per-frame fx (rain, splashes, neon reflections,
;;;; sky traffic, blinkers) are written straight into the engine's fx stream buffers by C (w_*,
;;;; game/c/world.c) so the whole module conses ~nothing per frame.
(in-package :raven)

(defparameter *arena-half* 17.6 "Invisible walls at x,z = ±this (m).")
(defparameter *rain-count* 1500 "Rain streaks (0–3000). Boss phase 2: ×1.5.")
(defvar *rain-color* (fv 0.624 0.706 0.816 0.35)
  "Rain streak/splash color r g b a (sRGB). Boss phase 2: (v3-set! *rain-color* 0.816 0.439 0.502).")

;;; ---------------------------------------------------------------- C side (per-frame fx, collision)
(ffi:clines "#include \"game/c/world.h\"")   ; w_rain, w_splash, w_reflect, w_sky, w_resolve ... (game/c/world.c)

;;; ---------------------------------------------------------------- data
(defun w-f32 (rows width)
  "Flatten ROWS (lists of numbers, padded with 0 to WIDTH) into an f32vec."
  (let ((v (make-f32 (max 1 (* width (length rows))))))
    (loop for row in rows for o from 0 by width
          do (loop for x in row for k from 0 do (setf (aref v (+ o k)) (f32 x))))
    v))

(defparameter +w-colliders+
  ;; kind cx cz hx|r hz y0 y1        (§6.2 + extra clutter that gets its own collider)
  '((0 -11 -9 1.2 0.8 0 1.75)        ; AC unit A
    (0 -7.5 -9 1.2 0.8 0 1.75)       ; AC unit B
    (0 11 6 0.8 1.2 0 1.75)          ; AC unit C
    (0 11 9.5 0.8 1.2 0 1.75)        ; AC unit D
    (1 -12 12 1.8 0 0 5.0)           ; water tank (legs + tank)
    (0 12 -12 2.0 1.75 0 3.3)        ; stair housing
    (1 15 15 0.3 0 0 9.3)            ; antenna mast
    (0 -17.35 0 0.3 8.2 0 1.1)))     ; pipe rack along the west parapet

(defparameter +w-puddles+
  ;; x z r stretch angle (§6.2 positions)
  '((-4 3 1.3 1.4 0.4) (5 -5 1.1 1.2 1.2) (-8 -2 1.6 1.5 2.0) (2 11 0.9 1.3 0.2)
    (9 -1 1.2 1.6 0.9) (-3 -10 1.0 1.2 2.6) (7 13 1.4 1.3 1.7) (-13 5 0.8 1.2 0.6)))

(defvar *w-colliders* (w-f32 +w-colliders+ 8))
(defvar *w-puddles* (w-f32 (mapcar (lambda (p) (subseq p 0 3)) +w-puddles+) 8))
(defvar *w-emitters* (w-f32 '((-6 5 -19.4 1 0.17 0.84 0.6 0.5 0) (-3 5 -19.4 1 0.17 0.84 0.6 0.5 0)
                              (0 5 -19.4 1 0.3 0.9 0.6 0.5 0) (3 5 -19.4 1 0.17 0.84 0.6 0.5 0)
                              (6 5 -19.4 1 0.17 0.84 0.6 0.5 0)
                              (19.2 3 0 0.1 0.9 1 0.4 0.3 1) (19.2 6 0 0.1 0.9 1 0.4 0.3 1)
                              (19.2 9 0 0.1 0.9 1 0.35 0.3 1)
                              (-12 3 10.1 1 0.6 0.24 0.45 0.3 0) (12.6 2.55 -10.0 1 0.6 0.24 0.4 0.3 0)
                              (17 4.0 12.5 1 0.62 0.3 0.4 0.35 0) (-17 4.0 -12.5 0.75 0.9 1 0.3 0.35 0)
                              (15 9.15 15 1 0.16 0.16 0.5 0.3 2))
                            10))
(defvar *w-lanes* (w-f32 '((-260 30 -78 260 30 -78 18 22 0.7 1 0.9 0.75 0)       ; sky-traffic lane N
                           (260 33 -84 -260 33 -84 18 22 0.7 1 0.2 0.2 0)
                           (-72 24 -260 -72 24 260 14 18 0.7 1 0.9 0.75 0)      ; lane W
                           (-67 27 260 -67 27 -260 14 18 0.7 1 0.25 0.25 0)
                           (85 44 -260 85 44 260 12 20 0.8 0.55 0.9 1 0)        ; lane E
                           (-300 140 -150 300 120 -60 1 15 1.6 1 1 1 1.1)       ; airliner
                           (280 100 200 -280 90 -120 1 13 1.4 1 1 1 0.9))       ; airliner
                         16))
(defparameter *world-haze* t "Horizon haze sprites (big additive quads: turn off if fill rate hurts).")
(defvar *w-mirrors* (w-f32 '((-8.3 2.3 -19.4 8.3 7.7 -19.4 1 0.17 0.84 0.28 0)    ; billboard N
                             (-8.3 4.2 -19.4 8.3 6.2 -19.4 1 0.6 0.95 0.18 0)     ; its bright text band
                             (19.2 0.8 1.1 19.2 10.2 -1.1 0.1 0.9 1 0.3 1))       ; cyan sign E (flickers)
                           12))
(defvar *w-haze* (w-f32 (loop for i below 14
                             for a = (* i (/ (* 2 pi) 14))
                             for c = (case (mod i 7) (0 '(1 0.17 0.84)) (2 '(0.1 0.9 1)) (4 '(1 0.6 0.24)) (t '(0.55 0.3 1)))
                             collect (list* (* 150 (sin a)) (+ 18 (* 6 (sin (* 3 a)))) (* -150 (cos a)) 70 (append c '(0.09))))
                       8)
  "Horizon haze sprites: x y z size r g b a (additive). i=0 sits behind the magenta billboard (north).")
(defvar *w-drones* (w-f32 '((-40 22 -30 12 0.18 0 45) (45 18 35 10 -0.22 2.1 40)) 8))
(defvar *w-blinkers* (make-f32 8)
  "Red blinkers: x y z size r g b phase (phase < 0 = roof beacon). Filled by WORLD-INIT-2 (beacon + skyline).")
(defvar *w-splash* (make-f32 (* 4 24)))
(defvar *w-p* (make-f32 32))
(defvar *w-anim* (make-f32 8) "0 fan angle, 1 flicker timer, 2 cyan flicker mult.")
(defvar *w-ray* (make-f32 6))
(defvar *w-fans* (fv -11.45 1.66 -9  -7.95 1.66 -9  11 1.66 6.45  11 1.66 9.95))
(defvar *world-m* (m4))
(defvar *w-floor* nil) (defvar *w-static* nil) (defvar *w-city* nil) (defvar *w-windows* nil) (defvar *w-neon* nil)
(defvar *w-sign* nil) (defvar *w-beacon* nil) (defvar *w-fan* nil)
(defvar *w-rng* 1337)
(declaim (type f32vec *w-colliders* *w-puddles* *w-emitters* *w-lanes* *w-drones* *w-blinkers*
               *w-haze* *w-mirrors* *w-splash* *w-p* *w-anim* *w-ray* *w-fans* *world-m* *rain-color*))

;;; ---------------------------------------------------------------- setup helpers (allocate freely)
(defun wrnd () "Deterministic 0..1." (setf *w-rng* (mod (+ (* *w-rng* 1103515245) 12345) 2147483648))
  (/ (float (ldb (byte 24 6) *w-rng*) 1.0) 16777216.0))
(defun wr (a b) (+ a (* (- b a) (wrnd))))
(defmacro at ((mb &rest xf) &body body) `(with-xform (,mb (xform ,@xf)) ,@body))

(defun mb-blob (mb x z r stretch ang y)
  "Irregular flat puddle blob (star-shaped, upward)."
  (let* ((n 16) (ca (cos ang)) (sa (sin ang))
         (pts (loop for k below n
                    collect (let* ((a (* 2 pi (/ k n))) (rr (* r (+ 0.8 (* 0.3 (wrnd)))))
                                   (lx (* rr stretch (cos a))) (lz (* rr (sin a))))
                              (v3 (+ x (* ca lx) (- (* sa lz))) y (+ z (* sa lx) (* ca lz)))))))
    (loop for (p q) on (append pts (list (first pts))) while q
          do (mb-poly-out mb (list (v3 x y z) p q) :center (list x (- y 1) z)))))

(defun mb-ring (mb r0 r1 y n &key (gaps 0.0))
  "Flat annulus (helipad paint). GAPS = chance of a worn-out segment."
  (dotimes (k n)
    (unless (< (wrnd) gaps)
      (let* ((a0 (* 2 pi (/ k n))) (a1 (* 2 pi (/ (1+ k) n))))
        (mb-poly-out mb (list (v3 (* r0 (cos a0)) y (* r0 (sin a0))) (v3 (* r1 (cos a0)) y (* r1 (sin a0)))
                              (v3 (* r1 (cos a1)) y (* r1 (sin a1))) (v3 (* r0 (cos a1)) y (* r0 (sin a1))))
                     :center (list 0 (- y 1) 0))))))

(defun glyph-strokes (seed)
  "Pseudo-kanji: strokes (x0 y0 x1 y1) in a unit cell, y up."
  (let ((*w-rng* (+ 7 (* seed 7919))) (s nil) (g '(0.0 0.33 0.66 1.0)))
    (wrnd)
    (dotimes (i (+ 1 (floor (* 3 (wrnd)))))                     ; horizontals
      (let ((y (nth (floor (* 4 (wrnd))) g)) (a (if (< (wrnd) 0.5) 0.0 0.33)) (b (if (< (wrnd) 0.6) 1.0 0.66)))
        (push (list a y b y) s)))
    (dotimes (i (+ 1 (floor (* 2 (wrnd)))))                     ; verticals
      (let ((x (nth (floor (* 4 (wrnd))) g)) (a (if (< (wrnd) 0.6) 0.0 0.33)) (b (if (< (wrnd) 0.5) 1.0 0.66)))
        (push (list x a x b) s)))
    (when (< (wrnd) 0.45)                                      ; a box radical
      (let ((x0 (if (< (wrnd) 0.5) 0.0 0.33)) (y0 (if (< (wrnd) 0.5) 0.0 0.33)))
        (setf s (append (list (list x0 y0 (+ x0 0.66) y0) (list x0 (+ y0 0.66) (+ x0 0.66) (+ y0 0.66))
                              (list x0 y0 x0 (+ y0 0.66)) (list (+ x0 0.66) y0 (+ x0 0.66) (+ y0 0.66)))
                        s))))
    (when (< (wrnd) 0.5) (push (list 0.15 0.1 0.45 0.45) s))   ; a slanted sweep
    s))

(defun mb-glyph (mb seed size th)
  "Pseudo-kanji of SIZE (m) centered at the origin in the local XY plane (facing +Z)."
  (dolist (st (glyph-strokes seed))
    (destructuring-bind (x0 y0 x1 y1) st
      (let ((ax (* size (- x0 .5))) (ay (* size (- y0 .5))) (bx (* size (- x1 .5))) (by (* size (- y1 .5))))
        (mb-tube mb ax ay 0 bx by 0 (* .5 th) :sides 4)))))

(defun mb-text (mb str cell y0 &key (gap 0.18))
  "5x7 font text as pixel bars in local XY (facing +Z), centered on x=0, bottom at Y0."
  (let* ((cols (1- (* 6 (length str)))) (x0 (* -0.5 cols cell)) (h (* cell (- 1 gap))))
    (loop for ch across str for i from 0
          do (let ((g (- (char-code ch) 32)))
               (dotimes (row 7)
                 (let ((run nil))
                   (dotimes (col 6)
                     (let ((on (and (< col 5) (logbitp row (aref +font-5x7+ (+ (* g 5) col))))))
                       (cond ((and on (not run)) (setf run col))
                             ((and (not on) run)
                              (let* ((xa (+ x0 (* cell (+ (* i 6) run)))) (xb (+ x0 (* cell (+ (* i 6) col))))
                                     (y (+ y0 (* cell (- 6 row)))))
                                (at (mb :x (* .5 (+ xa xb)) :y (+ y (* .5 cell)))
                                  (mb-box mb (- (- xb xa) (* gap cell)) h 0.06)))
                              (setf run nil)))))))))))

;;; ---------------------------------------------------------------- the roof (one lit mesh)
(defun build-floor (mb)
  (dotimes (i 18)
    (dotimes (k 18)
      (let* ((x0 (- (* i 2) 18)) (z0 (- (* k 2) 18))
             (lf (+ 0.93 (* 0.06 (sin (* 0.45 x0)) (cos (* 0.37 z0)))))
             (kk (* lf (+ 0.93 (* 0.1 (wrnd))) (if (< (wrnd) 0.06) 0.8 1.0) (if (evenp (+ i k)) 1.0 0.96))))
        (mb-flat-quad mb x0 z0 (+ x0 2) (+ z0 2) 0 (hexc #x3A3F4A kk)))))
  ;; drains, hatch plates, tar seams, safety paint by the stair door
  (mbc mb #x16181E)
  (loop for (x z) in '((-16.8 -16.8) (16.8 -16.8) (-16.8 16.8) (16.8 16.8) (0 -16.9) (0 16.9))
        do (mb-flat-quad mb (- x 0.25) (- z 0.25) (+ x 0.25) (+ z 0.25) 0.006))
  (mbc mb #x2B2F38)
  (loop for (x z w d) in '((-3 -6 1.4 1.0) (6 3 1.0 1.4) (-9 9 1.2 1.2))
        do (at (mb :x x :y 0.02 :z z) (mb-bevel-box mb w 0.04 d 0.015)))
  (mbc mb #x2E323B)
  (loop for x from -16 to 16 by 8 do (mb-flat-quad mb (- x 0.05) -17.8 (+ x 0.05) 17.8 0.002))
  (loop for z from -16 to 16 by 8 do (mb-flat-quad mb -17.8 (- z 0.05) 17.8 (+ z 0.05) 0.002))
  (loop for i below 6
        do (mb-flat-quad mb (+ 10.5 (* i 0.5)) -9.95 (+ 10.75 (* i 0.5)) -9.1 0.007 (hexc #xC9A227 0.55))))

(defun build-parapets (mb)
  (mbc mb #x4A4E58)
  (dolist (s '(-1 1))
    (at (mb :z (* s 18) :y 0.55) (mb-box mb 36.4 1.1 0.4))
    (at (mb :x (* s 18) :y 0.55) (mb-box mb 0.4 1.1 35.6)))
  (mbc mb #x5E6370)
  (dolist (s '(-1 1))
    (at (mb :z (* s 18) :y 1.14) (mb-box mb 36.6 0.08 0.56))
    (at (mb :x (* s 18) :y 1.14) (mb-box mb 0.56 0.08 36.0)))
  ;; wet stain along the inner base
  (mbc mb #x2C3039)
  (dolist (s '(-1 1))
    (at (mb :z (* s 17.79) :y 0.1) (mb-box mb 35.5 0.2 0.02))
    (at (mb :x (* s 17.79) :y 0.1) (mb-box mb 0.02 0.2 35.5)))
  ;; railings on the south and west caps
  (mbc mb #x2F333C)
  (loop for x from -17 to 17 by 2 do (mb-tube mb x 1.18 18 x 2.15 18 0.03))
  (loop for z from -15 to 17 by 2 do (mb-tube mb -18 1.18 z -18 2.15 z 0.03))
  (mb-tube mb -17.5 2.15 18 17.5 2.15 18 0.04 :sides 6)
  (mb-tube mb -17.5 1.65 18 17.5 1.65 18 0.025)
  (mb-tube mb -18 2.15 -15.5 -18 2.15 17.5 0.04 :sides 6)
  (mb-tube mb -18 1.65 -15.5 -18 1.65 17.5 0.025)
  ;; the building below: facade, cornice
  (mbc mb #x141824)
  (dolist (s '(-1 1))
    (at (mb :z (* s 18.1) :y -30.2) (mb-box mb 36.2 60 0.2))
    (at (mb :x (* s 18.1) :y -30.2) (mb-box mb 0.2 60 36.2)))
  (mbc mb #x3A3E48)
  (dolist (s '(-1 1))
    (at (mb :z (* s 18.3) :y -0.3) (mb-box mb 37.0 0.3 0.25))
    (at (mb :x (* s 18.3) :y -0.3) (mb-box mb 0.25 0.3 37.0))))

(defun build-ac (mb x z yaw)
  (at (mb :x x :z z :yaw yaw)
    (mbc mb #x2A2D33)
    (dolist (s '(-1 1)) (at (mb :y 0.06 :z (* s 0.6)) (mb-box mb 2.3 0.12 0.14)))
    (mbc mb #x6B7078)
    (at (mb :y 0.845) (mb-bevel-box mb 2.4 1.45 1.6 0.05))
    (dolist (s '(-1 1))
      (mbc mb #x1B1D22)
      (at (mb :x 0.25 :y 0.8 :z (* s 0.802)) (mb-box mb 1.6 0.9 0.01))
      (mbc mb #x50555D)
      (loop for i below 7 do (at (mb :x 0.25 :y (+ 0.42 (* i 0.13)) :z (* s 0.81)) (mb-box mb 1.6 0.035 0.03))))
    (mbc mb #x2A2D33)
    (at (mb :x -0.45 :y 1.64) (mb-cylinder mb 0.66 0.14 :segments 14 :caps nil))
    (mbc mb #x08090B)
    (at (mb :x -0.45 :y 1.585) (mb-cylinder mb 0.64 0.01 :segments 14))
    (mbc mb #x3A3E45)
    (mb-tube mb -1.1 1.74 0 0.2 1.74 0 0.015)
    (mb-tube mb -0.45 1.74 -0.65 -0.45 1.74 0.65 0.015)
    (mbc mb #x585D66)
    (at (mb :x 0.7 :y 1.66 :z -0.25) (mb-bevel-box mb 0.6 0.2 0.5 0.03))
    (mbc mb #x8A5A36)                                          ; copper lines into the roof
    (mb-tube mb 1.22 1.0 0.3 1.22 0.0 0.3 0.04 :sides 6)
    (mb-tube mb 1.22 0.8 -0.3 1.22 0.0 -0.3 0.03 :sides 6)))

(defun build-fan ()
  (build-mesh (mb :color (hexc #x2A2D33 1.2))
    (mb-cylinder mb 0.1 0.08 :segments 8)
    (dotimes (i 5)
      (at (mb :yaw (* i (/ (* 2 pi) 5)))
        (at (mb :z 0.3 :roll 0.35) (mb-box mb 0.2 0.02 0.46))))))

(defun build-tank (mb)
  (at (mb :x -12 :z 12)
    (mbc mb #x3B3530)
    (dolist (sx '(-1 1)) (dolist (sz '(-1 1)) (at (mb :x (* sx 1.2) :y 0.9 :z (* sz 1.2)) (mb-box mb 0.2 1.8 0.2))))
    (mbc mb #x2E2A27)
    (dolist (s '(-1 1))                                        ; X braces
      (mb-tube mb -1.2 0.2 (* s 1.2) 1.2 1.6 (* s 1.2) 0.035)
      (mb-tube mb -1.2 1.6 (* s 1.2) 1.2 0.2 (* s 1.2) 0.035)
      (mb-tube mb (* s 1.2) 0.2 -1.2 (* s 1.2) 1.6 1.2 0.035)
      (mb-tube mb (* s 1.2) 1.6 -1.2 (* s 1.2) 0.2 1.2 0.035))
    (mbc mb #x3B3530)
    (at (mb :y 1.83) (mb-cylinder mb 1.85 0.1 :segments 14))
    (setf (mb-jitter mb) 0.12)
    (mbc mb #x7A5A3E)
    (at (mb :y 3.12) (mb-cylinder mb 1.7 2.55 :segments 14))
    (mbc mb #x7A5A3E 0.85)
    (at (mb :y 4.7) (mb-cylinder mb 1.8 0.6 :segments 14 :top-radius 0.15))
    (setf (mb-jitter mb) 0.05)
    (mbc mb #x5A402C)
    (dolist (y '(2.2 3.0 3.8)) (at (mb :y y) (mb-cylinder mb 1.73 0.08 :segments 14 :caps nil)))
    (mbc mb #x3A3E45)                                          ; ladder (east side)
    (dolist (s '(-0.22 0.22)) (mb-tube mb 1.78 0.0 s 1.78 4.5 s 0.025))
    (loop for y from 0.3 to 4.3 by 0.3 do (mb-tube mb 1.78 y -0.22 1.78 y 0.22 0.015))
    (mbc mb #x3B3530)
    (mb-tube mb 0 0 0 0 1.8 0 0.12 :sides 6)                   ; outlet pipe
    (mbc mb #x2A2D33)                                          ; lamp housing (bulb is in the neon mesh)
    (at (mb :y 3.2 :z -1.78) (mb-bevel-box mb 0.36 0.16 0.3 0.03))
    (mb-tube mb 0 3.25 -1.7 0 3.25 -1.64 0.05)))

(defun build-stair-house (mb)
  (at (mb :x 12 :z -12)
    (setf (mb-jitter mb) 0.07)
    (mbc mb #x464A55)
    (at (mb :y 1.5) (mb-bevel-box mb 4.0 3.0 3.5 0.04))
    (mbc mb #x4A4E58)
    (at (mb :y 3.08) (mb-box mb 4.3 0.16 3.8))
    (setf (mb-jitter mb) 0.04)
    (mbc mb #x2A2D33)                                          ; door frame + leaf
    (at (mb :x 0.6 :y 1.16 :z 1.76) (mb-box mb 1.3 2.32 0.06))
    (mbc mb #x16181E)
    (at (mb :x 0.6 :y 1.1 :z 1.79) (mb-box mb 1.1 2.15 0.04))
    (mbc mb #x8A8F98)
    (at (mb :x 0.2 :y 1.05 :z 1.83) (mb-box mb 0.05 0.2 0.04))
    (mbc mb #x3C4048)
    (at (mb :x 0.6 :y 0.06 :z 1.86) (mb-box mb 1.5 0.12 0.22))
    (mbc mb #x2A2D33)                                          ; door lamp housing
    (at (mb :x 0.6 :y 2.62 :z 1.86) (mb-bevel-box mb 0.4 0.14 0.24 0.03))
    (mbc mb #x3C4048)                                          ; louvre on the east wall
    (loop for i below 5 do (at (mb :x 2.02 :y (+ 1.6 (* i 0.16)) :z -0.6) (mb-box mb 0.04 0.06 1.2)))
    (mbc mb #x5A5F66)                                          ; conduit
    (mb-tube mb -1.4 0.0 1.78 -1.4 2.9 1.78 0.04 :sides 6)
    (mb-tube mb -1.4 2.9 1.78 1.9 2.9 1.78 0.04 :sides 6)
    ;; roof: exhaust stacks, dish, mast
    (mbc mb #x3A3E45)
    (loop for (x z h) in '((-1.3 -1.0 1.8) (-0.7 -1.1 1.3) (-1.2 -0.3 1.0))
          do (mb-tube mb x 3.16 z x (+ 3.16 h) z 0.16 :sides 8)
             (at (mb :x x :y (+ 3.24 h) :z z) (mb-cylinder mb 0.26 0.1 :segments 8)))
    (mbc mb #x6B7078)
    (at (mb :x 1.2 :y 3.2 :z 0.8) (mb-bevel-box mb 1.0 0.3 0.8 0.05))
    (mbc mb #xA0A5AE)
    (at (mb :x 1.3 :y 3.9 :z -0.9 :pitch 0.7 :yaw -0.6)
      (mb-cylinder mb 0.55 0.12 :segments 10 :top-radius 0.2))
    (mbc mb #x3A3E45)
    (mb-tube mb 1.3 3.16 -0.9 1.3 3.8 -0.9 0.05)
    (mb-tube mb 1.7 3.16 0.3 1.7 6.2 0.3 0.03)))

(defun build-mast (mb)
  (at (mb :x 15 :z 15)
    (mbc mb #x3A3E45)
    (at (mb :y 0.15) (mb-cylinder mb 0.34 0.3 :segments 8))
    (mbc mb #x5A6070)
    (mb-tube mb 0 0.3 0 0 9.0 0 0.13 :sides 6)
    (mbc mb #x4A505C)
    (dolist (y '(5.8 7.4)) (mb-tube mb -0.7 y 0 0.7 y 0 0.03) (mb-tube mb 0 y -0.7 0 y 0.7 0.03))
    (mbc mb #x9AA0AA)
    (loop for (x z) in '((-0.7 0) (0.7 0) (0 -0.7) (0 0.7)) do (at (mb :x x :y 7.4 :z z) (mb-box mb 0.12 0.9 0.12)))
    (at (mb :x -0.25 :y 4.6 :z -0.25 :yaw 0.8 :pitch 1.2) (mb-cylinder mb 0.45 0.1 :segments 10 :top-radius 0.15))
    (mbc mb #x1E2026)
    (at (mb :y 9.05) (mb-cylinder mb 0.14 0.12 :segments 8)))
  (mbc mb #x2A2D33)                                            ; guy wires to the parapet caps
  (loop for (x z) in '((18 10.5) (10.5 18) (18 18))
        do (mb-tube mb 15 7.0 15 x 1.18 z 0.012 :caps nil)))

(defun build-billboard-frame (mb)
  (mbc mb #x2A2D33)
  (dolist (x '(-5 5))
    (at (mb :x x :y -1 :z -19.85) (mb-box mb 0.35 17 0.35))
    (dolist (y '(-2 -6))
      (mb-tube mb x y -19.85 x y -18.2 0.08)))
  (mbc mb #x0C0D13)
  (at (mb :y 5 :z -19.6) (mb-box mb 16.4 5.4 0.3))
  (mbc mb #x2A2D33)                                            ; catwalk + railing + floodlights
  (at (mb :y 2.2 :z -19.0) (mb-box mb 16.4 0.08 0.9))
  (loop for x from -8 to 8 by 2 do (mb-tube mb x 2.24 -18.58 x 3.1 -18.58 0.025))
  (mb-tube mb -8.1 3.1 -18.58 8.1 3.1 -18.58 0.03)
  (loop for x in '(-6 -2 2 6)
        do (mb-tube mb x 2.24 -18.8 x 2.6 -18.9 0.03)
           (at (mb :x x :y 2.62 :z -18.95 :pitch 0.6) (mb-bevel-box mb 0.4 0.12 0.3 0.03))))

(defun build-sign-frame (mb)
  (mbc mb #x0C0D13)
  (at (mb :x 19.45 :y 5.5) (mb-box mb 0.3 9.2 2.2))
  (mbc mb #x2A2D33)
  (dolist (y '(2 5.5 9)) (dolist (z '(-0.7 0.7)) (mb-tube mb 18.2 y z 19.3 y z 0.06))))

(defun build-lamp-poles (mb)
  (mbc mb #x2F333C)
  (loop for (x z s) in '((18 12.5 -1) (-18 -12.5 1) (0.5 18 0))
        do (mb-tube mb x 1.18 z x 4.3 z 0.06 :sides 6)
           (if (zerop s)
               (progn (mb-tube mb x 4.25 z x 4.25 (- z 1.1) 0.04)
                      (at (mb :x x :y 4.15 :z (- z 1.15)) (mb-bevel-box mb 0.35 0.14 0.55 0.03)))
               (progn (mb-tube mb x 4.25 z (+ x (* s 1.1)) 4.25 z 0.04)
                      (at (mb :x (+ x (* s 1.15)) :y 4.15 :z z) (mb-bevel-box mb 0.55 0.14 0.35 0.03))))))

(defun build-clutter (mb)
  ;; pipe rack along the west parapet (collider: 0 -17.35 0 0.3 8.2)
  (mbc mb #x2F333C)
  (loop for z from -8 to 8 by 2 do (at (mb :x -17.35 :y 0.5 :z z) (mb-box mb 0.5 1.0 0.1)))
  (loop for (y r c) in '((0.45 0.1 #x4A5A52) (0.72 0.08 #x6B7078) (0.95 0.12 #x7A5A3E))
        do (mbc mb c) (mb-tube mb -17.35 y -8.1 -17.35 y 8.1 r :sides 6)
           (mb-tube mb -17.35 y 8.1 -17.8 y 8.1 r :sides 6))
  ;; cables on the floor (flat, walkable)
  (mbc mb #x111216)
  (mb-tube mb 10.2 0.03 -10.25 10.2 0.03 4.8 0.03 :caps nil)
  (mb-tube mb 10.2 0.03 4.8 10.9 0.03 4.8 0.03 :caps nil)
  (mb-tube mb 14.8 0.03 14.8 14.8 0.03 -10.3 0.025 :caps nil)
  (mb-tube mb -12 0.03 -8.2 -12 0.03 10.2 0.025 :caps nil)
  ;; junction boxes and a vent on the parapets (inside the parapet thickness)
  (mbc mb #x585D66)
  (loop for (x z yaw) in '((17.7 -4 0) (17.7 7 0) (-5 -17.7 1.5708) (7 17.7 1.5708) (-17.7 12 0))
        do (at (mb :x x :y 0.6 :z z :yaw yaw) (mb-bevel-box mb 0.12 0.6 0.5 0.02))))

(defun build-paint (mb)
  (mbc mb #xC9A227 0.8)
  (mb-ring mb 5.875 6.125 0.005 64 :gaps 0.06)
  (mbc mb #xC9A227 0.55)
  (mb-ring mb 5.3 5.4 0.005 64 :gaps 0.5)
  (mb-flat-quad mb -1.3 -1.6 -0.8 1.6 0.005)
  (mb-flat-quad mb 0.8 -1.6 1.3 1.6 0.005)
  (mb-flat-quad mb -0.8 -0.25 0.8 0.25 0.005)
  (mbc mb #x2A3350)
  (loop for (x z r st ang) in +w-puddles+ do (mb-blob mb x z r st ang 0.004)))

(defun build-static ()
  "Two meshes: the wet floor (slabs, paint, puddles: strong specular) and everything standing on it
(walls, props: near matte). The build order fixes the RNG sequence, and so the look."
  (let ((fb (make-mesh-builder)) (mb (make-mesh-builder)))
    (setf (mb-jitter fb) 0.0)
    (build-floor fb)
    (setf (mb-jitter mb) 0.05)
    (build-parapets mb)
    (loop for (x z yaw) in '((-11 -9 0) (-7.5 -9 0) (11 6 1.5708) (11 9.5 1.5708)) do (build-ac mb x z yaw))
    (build-tank mb)
    (build-stair-house mb)
    (build-mast mb)
    (build-billboard-frame mb)
    (build-sign-frame mb)
    (build-lamp-poles mb)
    (build-clutter mb)
    (build-paint fb)
    (values (mb-build fb) (mb-build mb))))

;;; ---------------------------------------------------------------- emissive meshes
(defun build-neon ()
  "Constant-on emissive: billboard N, lamp bulbs, floodlight lenses, corner markers."
  (let ((mb (make-mesh-builder)))
    (at (mb :y 5 :z -19.42)
      (mbc mb #xFF2BD6)
      (dolist (s '(-1 1))                                       ; frame
        (mb-tube mb -8.0 (* s 2.5) 0 8.0 (* s 2.5) 0 0.07 :sides 6)
        (mb-tube mb (* s 8.0) -2.5 0 (* s 8.0) 2.5 0 0.07 :sides 6))
      (dolist (s '(-1 1))
        (mb-tube mb -7.7 (* s 2.2) 0.02 7.7 (* s 2.2) 0.02 0.03 :sides 4))
      (mbc mb #xFF2BD6)                                         ; two big glyphs, left
      (at (mb :x -6.1 :y 0.1) (mb-glyph mb 3 2.6 0.2))
      (at (mb :x -3.2 :y 0.1) (mb-glyph mb 11 2.6 0.2))
      (mbc mb #xFFB0F0)                                         ; brand text
      (at (mb :x 3.0 :z 0.02) (mb-text mb "KUROSAME" 0.2 -0.1))
      (mbc mb #xFF2BD6)                                         ; glyph bars
      (loop for x from -1.7 below 7.6 by 0.62
            do (mb-tube mb x -0.75 0 (+ x (wr 0.2 0.5)) -0.75 0 0.06))
      (mbc mb #x19E6FF)
      (mb-tube mb -1.7 -1.35 0 7.6 -1.35 0 0.05 :sides 4)
      (mbc mb #xFF2BD6)
      (mb-tube mb -1.7 1.75 0 1.4 1.75 0 0.05 :sides 4)
      (mb-tube mb 1.9 1.75 0 7.6 1.75 0 0.05 :sides 4))
    ;; lamp bulbs (amber), floodlight lenses (white), NW lamp (cool)
    (mbc mb #xFF9A3C)
    (at (mb :x -12 :y 3.1 :z 10.21) (mb-box mb 0.26 0.06 0.2))
    (at (mb :x 12.6 :y 2.53 :z -10.14) (mb-box mb 0.32 0.05 0.18))
    (at (mb :x 16.85 :y 4.07 :z 12.5) (mb-box mb 0.45 0.04 0.26))
    (at (mb :x 0.5 :y 4.07 :z 16.85) (mb-box mb 0.26 0.04 0.45))
    (mbc mb #xBFE8FF)
    (at (mb :x -16.85 :y 4.07 :z -12.5) (mb-box mb 0.45 0.04 0.26))
    (mbc mb #xFFE6F8)
    (loop for x in '(-6 -2 2 6) do (at (mb :x x :y 2.7 :z -18.85 :pitch 0.6) (mb-box mb 0.32 0.03 0.22)))
    ;; small red markers on the parapet corners
    (mbc mb #xFF2A2A)
    (loop for (x z) in '((-18 -18) (18 -18) (-18 18)) do (at (mb :x x :y 1.24 :z z) (mb-box mb 0.12 0.06 0.12)))
    (mb-build mb)))

(defun build-sign ()
  "Cyan vertical sign E (flickers as a whole). Faces -X."
  (let ((mb (make-mesh-builder)))
    (at (mb :x 19.28 :y 5.5 :yaw (/ pi -2))
      (mbc mb #x19E6FF)
      (dolist (s '(-1 1))
        (mb-tube mb -1.0 (* s 4.5) 0 1.0 (* s 4.5) 0 0.06 :sides 6)
        (mb-tube mb (* s 1.0) -4.5 0 (* s 1.0) 4.5 0 0.06 :sides 6))
      (loop for i below 5 for y from 3.45 by -1.72
            do (if (= i 0) (mbc mb #xDFFBFF) (mbc mb #x19E6FF))
               (at (mb :y y :z 0.02) (mb-glyph mb (+ 20 i) 1.3 0.13))))
    (mb-build mb)))

(defun build-beacon ()
  (build-mesh (mb :color (hexc #xFF2A2A))
    (at (mb :x 15 :y 9.2 :z 15) (mb-sphere mb 0.13 :segments 8 :rings 4))))

;;; ---------------------------------------------------------------- the city
(defun window-color ()
  (let ((u (wrnd))) (cond ((< u 0.4) #xFFD89A) ((< u 0.7) #x7FE9FF) (t #xFF6AD5))))

(defun facade-windows (win cx cz hx hz y0 y1 style color density)
  "Emissive window runs on the faces of box (cx cz ±hx ±hz, y0..y1) that look toward the arena."
  (loop for (nx nz) in '((1 0) (-1 0) (0 1) (0 -1))
        when (< (+ (* nx cx) (* nz cz)) 0)
          do (let* ((half (if (zerop nx) hx hz)) (off (if (zerop nx) hz hx))
                    (fx (+ cx (* nx (+ off 0.08)))) (fz (+ cz (* nz (+ off 0.08))))
                    (tx (- nz)) (tz nx) (c (list cx (* .5 (+ y0 y1)) cz))
                    (lo (max y0 -40)))
               (flet ((quad (s0 s1 ya yb k)
                        (mbc win color k)
                        (mb-poly-out win (list (v3 (+ fx (* tx s0)) ya (+ fz (* tz s0))) (v3 (+ fx (* tx s1)) ya (+ fz (* tz s1)))
                                               (v3 (+ fx (* tx s1)) yb (+ fz (* tz s1))) (v3 (+ fx (* tx s0)) yb (+ fz (* tz s0))))
                                     :center c)))
                 (case style
                   (0 (let* ((pitch 2.2) (m (floor (- (* 2 half) 1.2) pitch)))
                        (loop for y from (- y1 2.6) downto lo by 3.3
                              do (let ((run nil) (k (wr 0.45 1.0)))
                                   (dotimes (j (1+ m))
                                     (let ((on (and (< j m) (< (wrnd) density))))
                                       (cond ((and on (not run)) (setf run j))
                                             ((and (not on) run)
                                              (quad (+ (- half) 0.9 (* run pitch)) (+ (- half) 0.9 (* (1- j) pitch) 1.3)
                                                    y (+ y 1.4) k)
                                              (setf run nil)))))))))
                   (1 (loop for y from (- y1 2.0) downto lo by 3.6
                            when (< (wrnd) density)
                              do (quad (- 0.4 half) (- half 0.4) y (+ y 0.45) (wr 0.35 0.7))))
                   (t (loop for s from (+ (- half) 1.2) below (- half 0.8) by 3.0
                            when (< (wrnd) (+ 0.3 density))
                              do (quad s (+ s 0.25) (max lo (- y1 (wr 8 30))) (- y1 1.5) (wr 0.3 0.55)))))))))

(defun city-block (sk win cx cz hx hz top &key color crown (density (wr 0.2 0.55)))
  (apply #'mb-color sk color)
  (at (sk :x cx :y (* .5 (+ top -60)) :z cz) (mb-box sk (* 2 hx) (+ top 60) (* 2 hz)))
  (facade-windows win cx cz hx hz -60 top (floor (* 3 (wrnd))) (window-color) density)
  (when crown
    (mbc win crown)
    (dolist (s '(-1 1))
      (at (win :x cx :y (+ top 0.1) :z (+ cz (* s (+ hz 0.05)))) (mb-box win (+ (* 2 hx) 0.1) 0.15 0.08))
      (at (win :x (+ cx (* s (+ hx 0.05))) :y (+ top 0.1) :z cz) (mb-box win 0.08 0.15 (+ (* 2 hz) 0.1))))))

(defun build-city ()
  "Skyline ring (§6.2, seed 1337), far silhouette layer, neighbor roofs below us. Returns blinkers."
  (let ((sk (make-mesh-builder)) (win (make-mesh-builder)) (blink nil) (*w-rng* 1337))
    (setf (mb-jitter sk) 0.2)
    ;; 70-box ring, 45-180 m
    (dotimes (i 70)
      (let* ((a (+ (* i (/ (* 2 pi) 70)) (wr -0.03 0.03))) (r (wr 45 180))
             (cx (* r (cos a))) (cz (* r (sin a))) (hx (* .5 (wr 8 25))) (hz (* .5 (wr 8 25)))
             (top (wr -30 70)) (col (let ((u (wrnd))) (mapcar (lambda (p q) (+ p (* u (- q p)))) (hexc #x0E1220) (hexc #x1A2034)))))
        (city-block sk win cx cz hx hz top :color col
                    :crown (when (< (wrnd) 0.2) (if (< (wrnd) 0.5) #xFF2BD6 #x19E6FF)))
        (when (< (wrnd) 0.35)                                   ; setback tier
          (let ((t2 (+ top (wr 6 16))))
            (apply #'mb-color sk col)
            (at (sk :x cx :y (* .5 (+ top t2)) :z cz) (mb-box sk (* 1.2 hx) (- t2 top) (* 1.2 hz)))
            (facade-windows win cx cz (* .6 hx) (* .6 hz) top t2 2 (window-color) 0.5)
            (setf top t2)))
        (when (and (> top 20) (< (wrnd) 0.4))                   ; antenna + blinker
          (let ((h (wr 6 14)))
            (mbc sk #x10131C)
            (mb-tube sk cx top cz cx (+ top h) cz 0.25)
            (push (list cx (+ top h 0.3) cz 1.6 1 0.12 0.1 (wrnd)) blink)))))
    ;; two landmark towers (+110 m) with red blinkers
    (loop for (cx cz) in '((-90 -140) (120 -60)) for k from 0
          do (let ((col (hexc #x121828)))
               (city-block sk win cx cz 11 11 60 :color col :density 0.5)
               (apply #'mb-color sk col)
               (at (sk :x cx :y 80 :z cz) (mb-box sk 16 40 16))
               (facade-windows win cx cz 8 8 60 100 2 (if (zerop k) #x7FE9FF #xFF6AD5) 0.6)
               (at (sk :x cx :y 105 :z cz) (mb-box sk 10 10 10))
               (mbc win (if (zerop k) #x19E6FF #xFF2BD6))
               (dolist (y '(100.1 110.1)) (at (win :x cx :y y :z cz) (mb-box win (if (< y 105) 16.2 10.2) 0.3 (if (< y 105) 16.2 10.2))))
               (mbc sk #x10131C)
               (mb-tube sk cx 110 cz cx 128 cz 0.5 :sides 6)
               (push (list cx 128.5 cz 3.0 1 0.12 0.1 (* 0.5 k)) blink)
               (push (list cx 110.5 (+ cz 5) 2.0 1 0.12 0.1 (+ 0.25 (* 0.5 k))) blink)))
    ;; far silhouette layer (fog eats most of it)
    (dotimes (i 48)
      (let* ((a (* i (/ (* 2 pi) 48))) (r (wr 220 320)))
        (city-block sk win (* r (cos a)) (* r (sin a)) (wr 8 18) (wr 8 18) (wr 0 90)
                    :color (hexc #x12162A) :density 0.25)))
    ;; neighbor roofs below us (mid-ground)
    (loop for (cx cz hx hz top) in '((-34 -6 7 10 -6) (-32 26 9 7 -11) (33 22 8 8 -9) (31 -30 9 8 -4)
                                     (-5 38 11 7 -13) (8 -42 10 8 -16) (-30 -33 8 8 -8) (42 0 7 9 -14))
          do (city-block sk win cx cz hx hz top :color (hexc #x181D2C) :density 0.35)
             (mbc sk #x262B38)
             (dolist (s '(-1 1))
               (at (sk :x cx :y (+ top 0.4) :z (+ cz (* s hz))) (mb-box sk (* 2 hx) 0.8 0.3))
               (at (sk :x (+ cx (* s hx)) :y (+ top 0.4) :z cz) (mb-box sk 0.3 0.8 (* 2 hz))))
             (mbc sk #x3A3F4A)
             (at (sk :x (+ cx (* 0.3 hx)) :y (+ top 0.7) :z (- cz (* 0.3 hz))) (mb-box sk 2.4 1.4 1.6))
             (at (sk :x (- cx (* 0.4 hx)) :y (+ top 0.5) :z (+ cz (* 0.4 hz))) (mb-box sk 1.6 1.0 1.6))
             (mbc win #xFFD89A)
             (at (win :x (- cx (* 0.4 hx)) :y (+ top 1.1) :z (+ cz (* 0.4 hz))) (mb-box win 0.3 0.12 0.3)))
    (values (mb-build sk) (mb-build win) blink)))

;;; ---------------------------------------------------------------- environment (§9)
(defun world-env ()
  (let ((e *env*))
    (flet ((set3 (v h &optional (k 1.0)) (destructuring-bind (r g b) (hexc h k) (v3-set! v (f32 r) (f32 g) (f32 b)))))
      (set3 (env-sky-top e) #x070A14)
      (set3 (env-fog-color e) #x231F3A)
      (set3 (env-ambient-sky e) #x2A3660)
      (set3 (env-ambient-ground e) #x14121C)
      (set3 (env-moon-color e) #x7F93C9)
      (set3 (env-rim-color e) #x9FB4D0))
    (v3-normalize! (env-moon-dir e) (v3 0.4 1.0 0.3))
    (setf (env-fog-density e) 0.012 (env-fog-base e) 0.0 (env-fog-falloff e) 0.05 (env-fog-max e) 0.97
          (env-ambient-intensity e) 0.55 (env-moon-intensity e) 0.45
          (env-rim-intensity e) 0.22 (env-rim-power e) 4.5
          (env-specular e) 0.6 (env-shininess e) 60.0 (env-exposure e) 1.25
          (env-bloom e) t (env-bloom-threshold e) 0.6 (env-bloom-strength e) 0.95 (env-vignette e) 0.4)))

;;; ---------------------------------------------------------------- API
(defun world-init ()
  "Build scenery meshes and set *env*. Call once after ENGINE-INIT.
(= WORLD-INIT-1 then WORLD-INIT-2; the game calls them as separate startup steps so the
between-step GC keeps the peak heap down.)"
  (world-init-1)
  (world-init-2))

(defun world-init-1 ()
  (world-env)
  (let ((*w-rng* 4242))
    (multiple-value-setq (*w-floor* *w-static*) (build-static))
    (setf *w-neon* (build-neon))))

(defun world-init-2 ()
  (setf *w-sign* (build-sign) *w-beacon* (build-beacon) *w-fan* (build-fan))
  (multiple-value-bind (city win blink) (build-city)
    (setf *w-city* city *w-windows* win
          *w-blinkers* (w-f32 (cons '(15 9.2 15 1.1 1 0.1 0.1 -1) blink) 8)))
  (fill *w-splash* 1.0))

(defun world-update (dt)
  "Animate scenery (fans, sign flicker). DT is gameplay seconds (slow-mo slows the fans).
Rain and blinkers run on real time inside WORLD-DRAW."
  (w-update (f32 dt)))

(defun-fast w-update (dt)
  (declare (single-float dt))
  (let* ((a *w-anim*))
    (setf (aref a 0) (+ (aref a 0) (* dt 18.85)))                    ; 3 rev/s
    (when (> (aref a 0) 628.3185) (setf (aref a 0) (- (aref a 0) 628.3185)))
    (setf (aref a 1) (+ (aref a 1) dt))
    (when (>= (aref a 1) 0.1)                                         ; §6.2: 5 % per 0.1 s dims 50 % for 0.1 s
      (setf (aref a 1) 0.0
            (aref a 2) (if (< (ffi:c-inline () () :float "w_rnd()" :one-liner t) 0.05) 0.5 1.0)))
    nil))

(declaim (type f32vec *w-lightv*))
(defvar *w-lightv*
  (w-f32 '((0 5 -20.6 1.0 0.17 0.84 21 0.95)             ; magenta billboard N (behind the board: no spec disc on it)
           (20.3 5.5 0 0.1 0.9 1.0 15 1.1)               ; cyan sign E (behind the sign), x flicker
           (-12 3 9.9 1.0 0.6 0.24 9 0.9)                ; amber tank lamp SW
           (12.6 2.6 -9.6 1.0 0.6 0.24 7 0.8)            ; amber stair door NE
           (16.6 3.9 12.5 1.0 0.62 0.3 10 0.8)           ; amber pole SE
           (-16.6 3.9 -12.5 0.75 0.9 1.0 9 0.55)         ; cool work light NW
           (0.5 3.9 16.6 1.0 0.7 0.45 9 0.5)             ; warm pole S (back rim for the player)
           (15 9.2 15 1.0 0.16 0.16 10 0.9)) 8)          ; red beacon, x on/off
  "World point lights (x y z r g b radius intensity); ADD-POINT-LIGHT-V conses nothing.")

(defun-fast w-lights (flick beacon)
  (declare (single-float flick beacon))
  (let ((v *w-lightv*))
    (declare (type f32vec v))
    (setf (aref v 15) (* 1.1 flick) (aref v 63) (* 0.9 beacon))
    (dotimes (i 8) (add-point-light-v v (* i 8)))))

(defun-fast w-fx (flick beacon)
  (declare (single-float flick beacon))
  (let* ((p *w-p*) (cam *camera*) (eye (camera-eye cam)) (rt (camera-right cam)) (up (camera-upv cam))
         (tg (camera-target cam)) (rc *rain-color*) (n *rain-count*))
    (declare (type f32vec p eye rt up tg rc) (fixnum n))
    (dotimes (k 3) (setf (aref p k) (aref eye k) (aref p (+ 3 k)) (aref rt k) (aref p (+ 6 k)) (aref up k)))
    (setf (aref p 9) (the single-float (elapsed-time)) (aref p 10) (the single-float (frame-dt))
          (aref p 12) (aref rc 0) (aref p 13) (aref rc 1) (aref p 14) (aref rc 2) (aref p 15) (aref rc 3)
          (aref p 16) 1.5 (aref p 17) 0.5 (aref p 18) 18.0 (aref p 19) 0.5
          (aref p 20) (aref tg 0) (aref p 21) (aref tg 2) (aref p 22) 40.0 (aref p 23) 15.0
          (aref p 24) flick (aref p 25) beacon)
    (let* ((sb *fx-alpha*) (d (stream-buffer-data sb)) (f (stream-buffer-fill sb)) (cap (length d))
           (s *w-splash*) (pd *w-puddles*))
      (declare (type f32vec d s pd) (fixnum f cap))
      (setf f (ffi:c-inline (d f cap p n) (t :int :int t :int) :int
                            "w_rain(#0->vector.self.sf,#1,#2,#3->vector.self.sf,#4)" :one-liner t))
      (setf f (ffi:c-inline (d f cap p s pd) (t :int :int t t t) :int
                            "w_splash(#0->vector.self.sf,#1,#2,#3->vector.self.sf,#4->vector.self.sf,24,#5->vector.self.sf,8)"
                            :one-liner t))
      (setf (stream-buffer-fill sb) f))
    (let* ((sb *fx-add*) (d (stream-buffer-data sb)) (f (stream-buffer-fill sb)) (cap (length d))
           (em *w-emitters*) (pd *w-puddles*) (bl *w-blinkers*) (ln *w-lanes*) (dr *w-drones*) (hz *w-haze*)
           (ne (floor (length em) 10)) (nb (floor (length bl) 8)) (nl (floor (length ln) 16)) (nd (floor (length dr) 8))
           (nh (floor (length hz) 8)))
      (declare (type f32vec d em pd bl ln dr hz) (fixnum f cap ne nb nl nd nh))
      (setf f (ffi:c-inline (d f cap p em ne pd) (t :int :int t t :int t) :int
                            "w_reflect(#0->vector.self.sf,#1,#2,#3->vector.self.sf,#4->vector.self.sf,#5,#6->vector.self.sf,8)"
                            :one-liner t))
      (setf f (ffi:c-inline (d f cap p bl nb ln nl dr nd) (t :int :int t t :int t :int t :int) :int
                            "w_sky(#0->vector.self.sf,#1,#2,#3->vector.self.sf,#4->vector.self.sf,#5,#6->vector.self.sf,#7,#8->vector.self.sf,#9)"
                            :one-liner t))
      (setf f (ffi:c-inline (d f cap p *w-mirrors* (floor (length *w-mirrors*) 12)) (t :int :int t t :int) :int
                            "w_mirror(#0->vector.self.sf,#1,#2,#3->vector.self.sf,#4->vector.self.sf,#5)" :one-liner t))
      (setf f (ffi:c-inline (d f cap p hz (if *world-haze* nh 0)) (t :int :int t t :int) :int
                            "w_sprites(#0->vector.self.sf,#1,#2,#3->vector.self.sf,#4->vector.self.sf,#5)" :one-liner t))
      (setf (stream-buffer-fill sb) f))
    nil))

(defun-fast world-draw ()
  "Queue scenery draws, point lights and rain/sky fx. Call once per frame after the camera is set."
  (let* ((m *world-m*) (a *w-anim*) (fans *w-fans*)
         (flick (aref a 2))
         (beacon (if (< (ffi:c-inline ((the single-float (elapsed-time))) (:float) :float "fmodf(#0,1.0f)" :one-liner t)
                        0.5)
                     1.0 0.0)))
    (declare (type f32vec m a fans) (single-float flick beacon))
    (m4-identity! m)
    (draw-mesh *w-floor* m :specular 0.75)         ; wet floor mirrors the neon
    (draw-mesh *w-static* m :specular 0.2)         ; walls / props: no mirror glare
    (draw-mesh *w-city* m :specular 0.0)
    (draw-mesh *w-windows* m :emissive 1.6 :specular 0.0)
    (draw-mesh *w-neon* m :emissive 3.0 :specular 0.0)
    (draw-mesh *w-sign* m :emissive (* 3.0 flick) :specular 0.0)
    (draw-mesh *w-beacon* m :emissive (+ 0.2 (* 4.0 beacon)) :specular 0.0)
    (dotimes (i 4)
      (m4-euler! m (aref fans (* i 3)) (aref fans (+ 1 (* i 3))) (aref fans (+ 2 (* i 3)))
                 (+ (aref a 0) (* 0.9 (i->f i))) 0.0 0.0)
      (draw-mesh *w-fan* m :specular 0.2))
    (w-lights flick beacon)
    (w-fx flick beacon)
    nil))

(defun-fast arena-resolve (pos radius)
  "Push the vec3 POS (x,z) out of walls and prop colliders for a circle of RADIUS. Mutates POS;
returns T if it was moved."
  (declare (type f32vec pos) (single-float radius))
  (let* ((c *w-colliders*) (n (floor (length c) 8)) (half *arena-half*))
    (declare (type f32vec c) (fixnum n) (single-float half))
    (ffi:c-inline (pos radius c n half) (t :float t :int :float) :bool
                  "w_resolve(#0->vector.self.sf,#1,#2->vector.self.sf,#3,#4)" :one-liner t)))

(defun arena-raycast (x0 y0 z0 x1 y1 z1)
  "Segment (x0 y0 z0)→(x1 y1 z1) against prop volumes and the floor. Returns the hit fraction
0..1 (1.0 = clear). For a camera: eye = pivot + (cam - pivot) * max(0, t - 0.3/len)."
  (let ((s *w-ray*) (c *w-colliders*))
    (declare (type f32vec s c))
    (setf (aref s 0) (f32 x0) (aref s 1) (f32 y0) (aref s 2) (f32 z0)
          (aref s 3) (f32 x1) (aref s 4) (f32 y1) (aref s 5) (f32 z1))
    (ffi:c-inline (c (floor (length c) 8) s) (t :int t) :float
                  "w_raycast(#0->vector.self.sf,#1,#2->vector.self.sf)" :one-liner t)))

(defun arena-ground-height (x z)
  "Floor height at X,Z (the roof is flat: 0)."
  (declare (ignore x z))
  0.0)
