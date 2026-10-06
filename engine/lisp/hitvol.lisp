;;;; hitvol.lisp — hit-volume geometry for melee and hazards: does an attack's volume touch a
;;;; target's hurt cylinder? Pure functions of numbers, no state. Plain Common Lisp (no C-inline, no
;;;; engine macros), so the games' host tests load it natively (tests/*rules-test.lisp); it needs
;;;; only math.lisp (DEG, FWD-X / FWD-Z). Debug drawing of the same volumes is DRAW-VOL /
;;;; DRAW-CIRCLE in fx.lisp.
;;;;
;;;; Hurt volumes are vertical cylinders (radius TR, height TH) standing on the target's feet
;;;; (TX TY TZ). Attack volumes come in two kinds:
;;;;   * attacker-relative (melee swings): a 5-float vector #(type p1 p2 p3 p4) in the attacker's
;;;;     frame, made once by MAKE-VOL and tested with VOL-HIT-P given his feet and facing:
;;;;       0 ARC   r half-angle(rad) y0 y1   a pie slice around him, from height y0 to y1
;;;;       1 CAP   a b h r [yaw]             a capsule along his facing from a to b metres, height h (YAW, radians in
;;;;                                         slot 5: the capsule's axis turned that far off the facing; 0 = along it)
;;;;       2 SPH   fwd up r                  a sphere fwd metres ahead, up metres high
;;;;       3 TSPH  r                         a sphere at the attacker's target point (chest height)
;;;;   * world-space (projectiles, walls, pillars): CAPSULE-CYL-HIT-P, OBOX-CYL-HIT-P, CYL-CYL-HIT-P.
;;;; Every coordinate is a single-float (metres, y up); yaw 0 faces -Z (math.lisp).
(in-package :engine)

(defun make-vol (kind args)
  "Volume KIND from ARGS: (:arc r deg y0 y1) (the ARC takes its full angle in degrees),
(:cap a b h r [yaw-deg]) (YAW-DEG: the capsule turned that many degrees off the facing, + = toward his left, default 0),
(:sph fwd up r) or (:tsph r). Setup code (DEFMOVE / kit parsing). Six floats (slot 5: the cap's yaw in radians)."
  (flet ((v (&rest xs) (let ((a (make-f32 6))) (loop for x in xs for i from 0 do (setf (aref a i) (f32 x))) a)))
    (ecase kind
      (:arc (destructuring-bind (r deg y0 y1) args (v 0 r (deg (/ deg 2)) y0 y1)))
      (:cap (destructuring-bind (a b h r &optional (yaw 0)) args (v 1 a b h r (deg yaw))))
      (:sph (destructuring-bind (f u r) args (v 2 f u r)))
      (:tsph (destructuring-bind (r) args (v 3 r))))))

(defun vol-hit-p (v ax ay az fx fz tx ty tz tr th extra)
  "Does volume V of an attacker at (AX AY AZ) facing (FX 0 FZ) touch the hurt cylinder at
(TX TY TZ), radius TR, height TH? EXTRA widens ARC radii (e.g. a reach buff). For TSPH, (AX AY AZ)
is the target point. All floats are single-floats (hot path: compiled with safety 0)."
  (declare (optimize (speed 3) (safety 0))
           (type (simple-array single-float (*)) v)
           (single-float ax ay az fx fz tx ty tz tr th extra))
  (let ((type (aref v 0)))
    (cond
      ((< type 0.5f0)                                   ; ARC
       (let* ((r (+ (aref v 1) extra)) (half (aref v 2)) (y0 (+ ay (aref v 3))) (y1 (+ ay (aref v 4)))
              (dx (- tx ax)) (dz (- tz az)) (d (sqrt (the (single-float 0f0) (+ (* dx dx) (* dz dz))))))
         (declare (single-float r half y0 y1 dx dz d))
         (and (<= d (+ r tr)) (<= y0 (+ ty th)) (>= y1 ty)
              (or (>= half 3.1f0) (< d (+ tr 0.05f0))
                  ;; the cylinder's edge is inside the slice: angle to its centre <= half + its angular radius
                  (let ((c (/ (+ (* dx fx) (* dz fz)) d)) (s (/ tr d)))
                    (declare (single-float c s))
                    (<= (acos (if (> c 1f0) 1f0 (if (< c -1f0) -1f0 c)))
                        (+ half (asin (if (> s 1f0) 1f0 s)))))))))
      ((< type 1.5f0)                                   ; CAP: closest point on the segment
       (let ((yo (if (> (length v) 5) (aref v 5) 0f0))) ; a yawed cap (a fan of lines): its own axis (a 5-float vol: none)
         (declare (single-float yo))
         (unless (= yo 0f0)
           (let ((c (cos yo)) (sn (sin yo)))
             (declare (single-float c sn))
             (psetf fx (+ (* fx c) (* fz sn)) fz (- (* fz c) (* fx sn))))))
       (let* ((a (aref v 1)) (b (aref v 2)) (h (+ ay (aref v 3))) (r (aref v 4))
              (dx (- tx ax)) (dz (- tz az)) (along (+ (* dx fx) (* dz fz)))
              (s (if (< along a) a (if (> along b) b along)))
              (ex (- tx (+ ax (* fx s)))) (ez (- tz (+ az (* fz s)))))
         (declare (single-float a b h r dx dz along s ex ez))
         (and (<= (+ (* ex ex) (* ez ez)) (* (+ r tr) (+ r tr)))
              (>= h (- ty r)) (<= h (+ ty th r)))))
      (t                                                ; SPH / TSPH: sphere vs cylinder
       (let* ((sph (< type 2.5f0))
              (f (if sph (aref v 1) 0f0)) (u (if sph (aref v 2) 1.1f0)) (r (if sph (aref v 3) (aref v 1)))
              (cx (+ ax (* fx f))) (cy (+ ay u)) (cz (+ az (* fz f)))
              (dx (- tx cx)) (dz (- tz cz)) (lo (+ ty tr)) (hi (- (+ ty th) tr))
              (dy (cond ((< cy lo) (- lo cy)) ((> cy hi) (- cy hi)) (t 0f0))))
         (declare (single-float f u r cx cy cz dx dz lo hi dy))
         (<= (+ (* dx dx) (* dz dz) (* dy dy)) (* (+ r tr) (+ r tr))))))))

;;; ---------------------------------------------------------------- world-space volumes
(defun capsule-cyl-hit-p (ax ay az bx by bz r tx ty tz tr th)
  "Does the capsule from (AX AY AZ) to (BX BY BZ) with radius R touch the hurt cylinder at
(TX TY TZ) (radius TR, height TH)? The cylinder is taken as the capsule of radius TR around its
axis from TY+TR to TY+TH-TR (ponytail: rounded top/bottom rims, exact enough for hits)."
  (declare (single-float ax ay az bx by bz r tx ty tz tr th))
  (let* ((lo (+ ty (min tr (* 0.5 th)))) (hi (max lo (- (+ ty th) tr)))
         ;; closest points of segment P = A + s(B-A) and the axis Q = (tx, lo + t(hi-lo), tz)
         (d1x (- bx ax)) (d1y (- by ay)) (d1z (- bz az)) (d2y (- hi lo))
         (rx (- ax tx)) (ry (- ay lo)) (rz (- az tz))
         (a (+ (* d1x d1x) (* d1y d1y) (* d1z d1z))) (e (* d2y d2y))
         (f (* d2y ry)) (c (+ (* d1x rx) (* d1y ry) (* d1z rz))) (b (* d1y d2y))
         (s 0.0) (u 0.0))
    (flet ((unit (x) (max 0.0 (min 1.0 x))))
      (cond ((and (<= a 1e-8) (<= e 1e-8)))
            ((<= a 1e-8) (setf u (unit (/ f e))))
            ((<= e 1e-8) (setf s (unit (/ (- c) a))))
            (t (let ((den (- (* a e) (* b b))))
                 (setf s (if (> den 1e-8) (unit (/ (- (* b f) (* c e)) den)) 0.0)
                       u (/ (+ (* b s) f) e))
                 (cond ((< u 0.0) (setf u 0.0 s (unit (/ (- c) a))))
                       ((> u 1.0) (setf u 1.0 s (unit (/ (- b c) a))))))))
      (let ((dx (+ rx (* d1x s))) (dy (- (+ ry (* d1y s)) (* d2y u))) (dz (+ rz (* d1z s))) (rr (+ r tr)))
        (<= (+ (* dx dx) (* dy dy) (* dz dz)) (* rr rr))))))

(defun obox-cyl-hit-p (cx cy cz yaw hw hh hl tx ty tz tr th)
  "Does the box centred at (CX CY CZ), turned by YAW, with half-width HW (its right), half-height
HH and half-length HL (its facing) touch the hurt cylinder at (TX TY TZ) (radius TR, height TH)?
Exact for a yaw-only box and a vertical cylinder."
  (declare (single-float cx cy cz yaw hw hh hl tx ty tz tr th))
  (let* ((fx (fwd-x yaw)) (fz (fwd-z yaw))
         (dx (- tx cx)) (dz (- tz cz))
         (lx (+ (* dx (- fz)) (* dz fx)))                ; along the box's right
         (lz (+ (* dx fx) (* dz fz)))                    ; along its facing
         (ex (- lx (max (- hw) (min hw lx)))) (ez (- lz (max (- hl) (min hl lz)))))
    (and (<= (+ (* ex ex) (* ez ez)) (* tr tr))
         (<= (- cy hh) (+ ty th)) (>= (+ cy hh) ty))))

(defun cyl-cyl-hit-p (ax ay az ar ah bx by bz br bh)
  "Do two vertical cylinders (feet, radius, height) overlap?"
  (declare (single-float ax ay az ar ah bx by bz br bh))
  (let ((dx (- bx ax)) (dz (- bz az)) (rr (+ ar br)))
    (and (<= (+ (* dx dx) (* dz dz)) (* rr rr))
         (<= ay (+ by bh)) (<= by (+ ay ah)))))
