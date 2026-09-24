;;;; world-demo.lisp — the rooftop arena with stand-in characters, camera presets, perf HUD and a
;;;; collision self-test. Build:
;;;;   ./build.sh world-demo game/lisp/package.lisp game/lisp/world.lisp game/c/world.c tests/world-demo.lisp
;;;; Keys: arrows = orbit (yaw/pitch), W A S D = move the pivot, Q/E or wheel = zoom, R/F = pivot up/down,
;;;;       T = next camera preset (1..7 jump directly), B = bloom, H = haze, N = rain on/off, M = rain ×1.5 + crimson.
(in-package :raven)   ; the game's world module (game/lisp/world.lisp)

(defvar *d-cam* (fv 0 1.5 8 0 0.26 5.5))    ; pivot xyz, yaw, pitch, dist
(defvar *d-preset* 0)
(defparameter +d-presets+
  ;; name pivot xyz yaw pitch dist
  '(("SPAWN 3RD PERSON" 0 1.5 8 0 0.26 5.5)
    ("NW CORNER" -8 1.5 -6 -2.356 0.3 7.5)
    ("EAST SKYLINE" 4 2.0 -2 -1.571 0.06 6)
    ("TOP DOWN" 0 0 0 0.35 1.05 34)
    ("PUDDLES LOW" -3 0.9 1 0.15 0.1 6.5)
    ("LOOKING SOUTH" 0 1.5 -8 3.1416 0.24 5.5)
    ("NW LOOKOUT" -13 2.2 -13 0.785 0.1 5)))
(defvar *d-stats* (make-f32 6))            ; frame-cons acc, world-cons acc, frames, timer, avg frame, avg world
(defvar *d-m* (m4))
(defvar *d-rain-on* t)
(defvar *d-actors* nil)                     ; (body-mesh glow-mesh x z yaw)
(declaim (type f32vec *d-cam* *d-stats* *d-m*))

;;; ---------------------------------------------------------------- stand-ins (readability test)
(defun stand-in (h body trim glow &key (w 1.0) horns)
  "A capsule character of height H: body color, trim band color, emissive eye/visor color."
  (values
   (build-mesh (mb :jitter 0.06 :color (hexc body))
     (at (mb :y (* .5 h) :sx w :sz (* 0.8 w)) (mb-capsule mb (* 0.16 h) h :segments 10 :rings 6))
     (mbc mb trim)
     (at (mb :y (* 0.8 h) :sx w :sz (* 0.8 w)) (mb-cylinder mb (* 0.17 h) (* 0.06 h) :segments 10))
     (at (mb :y (* 0.72 h) :z (* 0.14 h)) (mb-box mb (* 0.1 h) (* 0.18 h) 0.05))
     (when horns
       (mbc mb horns)
       (dolist (s '(-1 1)) (at (mb :x (* s 0.12 h) :y (* 0.98 h) :roll (* s -0.6)) (mb-cone mb 0.06 (* 0.18 h) :segments 5)))))
   (build-mesh (mb :color (hexc glow))
     (at (mb :y (* 0.92 h) :z (* 0.15 h w)) (mb-box mb (* 0.14 h) (* 0.025 h) 0.04)))))

(defun make-actors ()
  (loop for (x z yaw h body trim glow w horns) in
        '((0 8 0 1.8 #x15171D #xC0142B #x7FF3FF 1.0 nil)          ; REN at spawn, facing north
          (-6 -14 3.14 1.78 #x4A5140 #xD8D2C4 #xFF3030 1.1 nil)   ; rainblades
          (6 -14 3.14 1.78 #x4A5140 #xD8D2C4 #xFF3030 1.1 nil)
          (-15 -2 -1.57 1.7 #x262B4A #x3A3F55 #x19E6FF 0.85 nil)  ; needler
          (15 -2 1.57 2.6 #x3A2A26 #xC21A1A #xFF3030 1.45 #xE6DCC8) ; oxhead
          (0 -10 3.14 2.4 #x9E0F1C #xD4A437 #xFFB02E 1.2 #xF0E6D0)) ; enra
        collect (multiple-value-bind (b g) (stand-in h body trim glow :w w :horns horns) (list b g x z yaw))))

;;; ---------------------------------------------------------------- collision self-test
(defun d-overlap (x z r)
  "Depth of the deepest overlap of circle (x z r) with any collider (0 = clear)."
  (let ((c *w-colliders*) (worst 0.0))
    (dotimes (i (floor (length c) 8) worst)
      (let* ((o (* i 8)) (dx (- x (aref c (+ o 1)))) (dz (- z (aref c (+ o 2)))))
        (setf worst
              (max worst
                   (if (zerop (aref c o))
                       (let* ((ex (- (abs dx) (aref c (+ o 3)))) (ez (- (abs dz) (aref c (+ o 4)))))
                         (- r (if (and (<= ex 0) (<= ez 0)) (max ex ez) (sqrt (+ (expt (max ex 0) 2) (expt (max ez 0) 2))))))
                       (- (+ r (aref c (+ o 3))) (sqrt (+ (* dx dx) (* dz dz)))))))))))

(defun collision-self-test ()
  (let ((fails 0) (p (make-f32 3)) (c *w-colliders*))
    (flet ((check (name ok) (unless ok (incf fails)) (log-msg "collision ~a: ~a" (if ok "PASS" "FAIL") name)))
      (dotimes (i (floor (length c) 8))
        (dolist (r '(0.35 0.75))
          (dolist (off '((0 0) (0.3 0.2) (-0.5 0.1)))
            (let ((x (+ (aref c (+ (* i 8) 1)) (first off))) (z (+ (aref c (+ (* i 8) 2)) (second off))))
              (v3-set! p x 0.0 z)
              (let ((moved (arena-resolve p (f32 r))))
                (check (format nil "prop ~d r ~a from (~,1f ~,1f) -> (~,2f ~,2f)" i r x z (aref p 0) (aref p 2))
                       (and moved (< (d-overlap (aref p 0) (aref p 2) r) 0.002)
                            (<= (abs (aref p 0)) (- *arena-half* r -0.001)) (<= (abs (aref p 2)) (- *arena-half* r -0.001)))))))))
      ;; grazing an AC unit edge: pushed out exactly to contact
      (v3-set! p -11.0 0.0 -7.9)
      (check "AC A south face graze" (and (arena-resolve p 0.35) (< (abs (- (aref p 2) (+ -9 0.8 0.35))) 0.01)))
      ;; walls clamp
      (v3-set! p 25.0 0.0 -30.0)
      (check "walls clamp" (and (arena-resolve p 0.35) (< (abs (- (aref p 0) 17.25)) 1e-4) (< (abs (+ (aref p 2) 17.25)) 1e-4)))
      ;; free space untouched
      (v3-set! p 0.0 0.0 0.0)
      (check "free space untouched" (and (not (arena-resolve p 0.35)) (zerop (aref p 0)) (zerop (aref p 2))))
      (v3-set! p -9.25 0.0 -9.0)
      (check "player fits between AC A and B" (not (arena-resolve p 0.35)))
      ;; raycasts
      (check "raycast hits AC A" (< (arena-raycast 0 1.2 0 -11 1.2 -9) 0.95))
      (check "raycast hits stair housing" (< (arena-raycast 12 1.5 -5 12 1.5 -20) 0.4))
      (check "raycast hits tank" (< (arena-raycast -5 3 5 -12 3 12) 0.9))
      (check "raycast clear" (= (arena-raycast 0 1.5 0 0 1.5 6) 1.0))
      (check "raycast floor" (< (abs (- (arena-raycast 0 1 0 0 -1 0) 0.5)) 1e-4))
      (log-msg "collision self-test: ~a (~d failures)" (if (zerop fails) "ALL PASS" "FAILED") fails))))

;;; ---------------------------------------------------------------- camera
(defun d-apply-preset (i)
  (let ((p (nth i +d-presets+)))
    (setf *d-preset* i)
    (loop for v in (rest p) for k from 0 do (setf (aref *d-cam* k) (f32 v)))
    (log-msg "view ~d: ~a" (1+ i) (first p))))

(defun-fast d-camera (dt)
  (declare (single-float dt))
  (let* ((c *d-cam*) (yaw (aref c 3)) (fx (- (sin yaw))) (fz (- (cos yaw))))
    (declare (single-float yaw fx fz))
    (when (key-down :left) (setf (aref c 3) (+ (aref c 3) (* 1.4 dt))))
    (when (key-down :right) (setf (aref c 3) (- (aref c 3) (* 1.4 dt))))
    (when (key-down :up) (setf (aref c 4) (+ (aref c 4) (* 0.8 dt))))
    (when (key-down :down) (setf (aref c 4) (- (aref c 4) (* 0.8 dt))))
    (let* ((mv (* 8.0 dt)) (f (if (key-down :w) mv (if (key-down :s) (- mv) 0.0))) (r (if (key-down :d) mv (if (key-down :a) (- mv) 0.0))))
      (declare (single-float mv f r))
      (setf (aref c 0) (+ (aref c 0) (* f fx) (* r (- fz))) (aref c 2) (+ (aref c 2) (* f fz) (* r fx))))
    (when (key-down :r) (setf (aref c 1) (+ (aref c 1) (* 4.0 dt))))
    (when (key-down :f) (setf (aref c 1) (- (aref c 1) (* 4.0 dt))))
    (when (key-down :q) (setf (aref c 5) (- (aref c 5) (* 8.0 dt))))
    (when (key-down :e) (setf (aref c 5) (+ (aref c 5) (* 8.0 dt))))
    (setf (aref c 5) (- (aref c 5) (* 0.8 (the single-float (mouse-wheel)))))
    (when (or (mouse-down :left) (pointer-locked-p))
      (setf (aref c 3) (- (aref c 3) (* 0.005 (the single-float (mouse-dx))))
            (aref c 4) (+ (aref c 4) (* 0.005 (the single-float (mouse-dy))))))
    (setf (aref c 4) (clamp (aref c 4) -0.3 1.5) (aref c 5) (clamp (aref c 5) 1.0 80.0))
    (let* ((yaw (aref c 3)) (p (aref c 4)) (d (aref c 5)) (cp (cos p)))
      (declare (single-float yaw p d cp))
      (camera-look-at (+ (aref c 0) (* d cp (sin yaw))) (max 0.4 (+ (aref c 1) (* d (sin p)))) (+ (aref c 2) (* d cp (cos yaw)))
                      (aref c 0) (aref c 1) (aref c 2)))))

;;; ---------------------------------------------------------------- frame
(defun demo-init ()
  (let ((c0 (cons-bytes)))
    (world-init)
    (log-msg "world-init consed ~,1f MB" (/ (- (cons-bytes) c0) 1048576.0)))
  (setf (camera-fov *camera*) (deg 62))
  (setf *d-actors* (make-actors))
  (collision-self-test)
  (d-apply-preset 0))

(defun d-draw-actors ()
  (let ((m *d-m*))
    (dolist (a *d-actors*)
      (destructuring-bind (b g x z yaw) a
        (m4-euler! m (f32 x) 0.0 (f32 z) (f32 yaw) 0.0 0.0)
        (draw-mesh b m)
        (draw-mesh g m :emissive 3.0)
        (fx-decal x 0 z 0.6 0 0 0 0.55)))))

(defun demo-frame (rdt)
  (declare (ignore rdt))                ; the demo animates with FRAME-DT (clamped to *MAX-DT*)
  (let* ((c0 (cons-bytes)) (dt (frame-dt)) (st *d-stats*) (cw 0))
    (when (key-pressed :t) (d-apply-preset (mod (1+ *d-preset*) (length +d-presets+))))
    (loop for k in '(:1 :2 :3 :4 :5 :6 :7) for i from 0 when (key-pressed k) do (d-apply-preset i))
    (when (key-pressed :b) (setf (env-bloom *env*) (not (env-bloom *env*))))
    (when (key-pressed :h) (setf *world-haze* (not *world-haze*)) (log-msg "haze ~a" *world-haze*))
    (when (key-pressed :n) (setf *d-rain-on* (not *d-rain-on*) *rain-count* (if *d-rain-on* 1500 0)))
    (when (key-pressed :m)
      (if (> *rain-count* 1500)
          (setf *rain-count* 1500 (aref *rain-color* 0) 0.624 (aref *rain-color* 1) 0.706 (aref *rain-color* 2) 0.816)
          (setf *rain-count* 2250 (aref *rain-color* 0) 0.816 (aref *rain-color* 1) 0.439 (aref *rain-color* 2) 0.502)))
    (d-camera dt)
    (let ((w0 (cons-bytes)))
      (world-update dt)
      (world-draw)
      (setf cw (- (cons-bytes) w0)))
    (d-draw-actors)
    (let* ((s (ui-scale)) (pad (* 8 s)))
      (ui-gradient 0 0 (* 260 s) (* 50 s) '(0.02 0.02 0.06 0.75) '(0.02 0.02 0.06 0) :vertical nil)
      (ui-text (format nil "FPS ~,1f  DRAWS ~d  TRIS ~d  FX-DROP ~d" (fps) *draw-count* *tri-count* *fx-dropped*) pad pad :scale s :shadow t)
      (ui-text (format nil "CONS/FRAME ~d B  WORLD ~d B  RAIN ~d" (round (aref st 4)) (round (aref st 5)) *rain-count*)
               pad (+ pad (* 12 s)) :scale s :color '(0.6 0.9 1 1) :shadow t)
      (ui-text (format nil "VIEW ~d ~a  [T] next  arrows/WASD/QE/RF" (1+ *d-preset*) (first (nth *d-preset* +d-presets+)))
               pad (+ pad (* 24 s)) :scale s :color '(0.8 0.8 0.9 1) :shadow t))
    (setf (aref st 0) (+ (aref st 0) (float (max 0 (- (cons-bytes) c0)) 1.0))
          (aref st 1) (+ (aref st 1) (float (max 0 cw) 1.0))
          (aref st 2) (+ (aref st 2) 1.0) (aref st 3) (+ (aref st 3) dt))
    (when (>= (aref st 3) 2.0)
      (setf (aref st 4) (/ (aref st 0) (aref st 2)) (aref st 5) (/ (aref st 1) (aref st 2)))
      (log-msg "stats: fps ~,1f draws ~d tris ~d cons/frame ~d B world ~d B fx-dropped ~d view ~d"
               (fps) *draw-count* *tri-count* (round (aref st 4)) (round (aref st 5)) *fx-dropped* (1+ *d-preset*))
      (fill st 0.0 :end 4))))

(run-game :title "RAVEN EDGE world demo" :load (list #'demo-init) :frame #'demo-frame)
