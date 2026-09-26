;;;; camera.lisp — the duel's two cameras (design-v1 §7, critique-design §4.5). The PAIR camera: a 3/4
;;;; side view framing both fighters, farther as they separate. Which side of the fighter axis it stands on is sim state
;;;; (fighter.lisp VIEW-STEP: P1 on the left at every start / reset, and it never swings 180° after a
;;;; Hoho); this file only places the render camera there, smoothing the ORBIT ANGLE around the
;;;; fighters' midpoint (so a strafing pair stays framed side-on instead of the eye trailing behind),
;;;; the distance and the midpoint separately. A cinematic shot (cinema.lisp) overrides it; the first
;;;; frame after one cuts back. A perfect Hoho punches in. Runs once per frame on real time.
;;;; The BEHIND camera (VS CPU, the default there; fighter.lisp *VIEW-BEHIND*): over P1's right shoulder,
;;;; looking along the sim's *BEHIND-YAW* (P1 -> P2, rate-limited: it swings round after a Hoho), at a
;;;; point between the fighters biased to P2; it follows P1 on a spring and backs off with distance.
(in-package :duel)

(declaim (single-float *cam-ang* *cam-dist* *punch-t*) (type f32vec *cam-eye* *cam-at*))
(defvar *cam-eye* (fv 0 3 12) "The camera eye this frame ...")
(defvar *cam-at* (fv 0 1 0) "... and target (the smoothed midpoint).")
(defvar *cam-ang* 0f0 "Smoothed orbit angle (radians, atan2 of the midpoint->eye direction z x) ...")
(defvar *cam-dist* 7f0 "... and distance.")
(defvar *cam-cut* t "Snap on the next frame (a new battle, the end of a cinematic).")
(defvar *punch-t* 0f0 "Real seconds of the perfect-Hoho punch-in left.")
(defparameter *cam-orbit-rate* 10.0 "Orbit angle and midpoint follow at this rate (1/s) ...")
(defparameter *cam-dist-rate* 5.0 "... the distance at this one.")
(defparameter *cam-max-r* 18.0 "The eye stays this close to the arena centre (the wall ring stands at 19 m).")
(defparameter *cam-close* 0.6 "Both cameras' distances x this (0.6 = 40 % closer than the original framing; user request, docs/STYLE_STORM_DESIGN.md §6).")
(declaim (type f32vec *cam-anchor*))
(defvar *cam-anchor* (fv 0 0 0) "Behind camera: P1's position, followed on a spring.")
(defparameter *behind-back* 5.5 "Behind camera: metres behind P1 ...")
(defparameter *behind-up* 2.0 "... this high ...")
(defparameter *behind-shoulder* 0.9 "... and this far to his right (over the shoulder) ...")
(defparameter *behind-widen* 0.2 "... backing off this much (and rising a third of it) per metre of separation beyond 4 m.")
(defparameter *behind-look* 0.6 "It looks this fraction of the way to P2, 1.1 m up.")
(defparameter *behind-close* 40.0
  "Up close P1 would hide P2: the eye swings round to P1's right by up to this many degrees (full at
2 m, none from 6 m). Only the look; steering keeps the sim's *BEHIND-YAW*.")
(defparameter *behind-rate* 8.0 "The anchor follows P1 at this rate (1/s): a spring, so a Step or a Hoho glides.")

(defun camera-side (&optional (a nil))
  "For a cinematic's SHOT-PAIR from actor A (default P1) to the other: the side (+1 / -1) of that
line the duel camera is on."
  (if (and a (= 1 (fighter-side (fighter a)))) (- *view-side*) *view-side*))

(defun behind-camera (a b rdt snap)
  "Place *CAM-EYE* / *CAM-AT* behind fighter A (P1), looking along *BEHIND-YAW* toward B."
  (let* ((p (pos-of a)) (q (pos-of b)) (c *cam-anchor*)
         (sep (sqrt (+ (expt (- (aref q 0) (aref p 0)) 2) (expt (- (aref q 2) (aref p 2)) 2))))
         (wide (* *behind-widen* (max 0.0 (- sep 4.0))))
         (back (* *cam-close* (+ *behind-back* wide) (if (> *punch-t* 0) 0.6 1.0)))
         (off (deg (* *behind-close* (max 0.0 (min 1.0 (/ (- 6.0 sep) 4.0))))))
         (side (+ *behind-shoulder* (* back (sin off))))     ; to the right of P1 ...
         (fx (fwd-x *behind-yaw*)) (fz (fwd-z *behind-yaw*)))
    (setf back (* back (cos off)))                         ; ... and behind him
    (if (or snap *cam-cut*)
        (setf (aref c 0) (aref p 0) (aref c 2) (aref p 2) *cam-cut* nil)
        (let ((k (- 1.0 (exp (* (- *behind-rate*) rdt)))))
          (setf (aref c 0) (f32 (+ (aref c 0) (* k (- (aref p 0) (aref c 0)))))
                (aref c 2) (f32 (+ (aref c 2) (* k (- (aref p 2) (aref c 2))))))))
    (let* ((ex (+ (aref c 0) (* (- back) fx) (* side (- fz))))   ; right = (-fz, fx)
           (ez (+ (aref c 2) (* (- back) fz) (* side fx)))
           (r (sqrt (+ (* ex ex) (* ez ez))))
           (k (min 1.0 (/ *cam-max-r* (max 0.01 r))))
           (h (+ *behind-up* (* 0.33 wide) (* 0.4 (- r (* k r))))))   ; pulled in by the wall: rise instead
      (setf ex (* k ex) ez (* k ez))
      (dolist (e (list a b))                             ; never inside a fighter
        (let* ((o (pos-of e)) (dx (- ex (aref o 0))) (dz (- ez (aref o 2))) (d (sqrt (+ (* dx dx) (* dz dz))))
               (min-d (+ 0.5 (body-hurt-r (model-body (model e))))))
          (when (and (< d min-d) (> d 0.001))
            (setf ex (+ (aref o 0) (* dx (/ min-d d))) ez (+ (aref o 2) (* dz (/ min-d d)))))))
      (v3-set! *cam-eye* (f32 ex) (f32 h) (f32 ez))
      (v3-set! *cam-at* (f32 (+ (aref c 0) (* *behind-look* sep fx))) 1.1f0 (f32 (+ (aref c 2) (* *behind-look* sep fz)))))))

(defun-fast %roll-up (up eye at roll)
  "UP := the world's up rolled ROLL degrees about the view direction EYE -> AT (a dutch angle)."
  (declare (type f32vec up eye at) (single-float roll))
  (let* ((fx (- (aref at 0) (aref eye 0))) (fz (- (aref at 2) (aref eye 2)))
         (l (f-max 1f-4 (f-sqrt (+ (* fx fx) (* fz fz))))) (r (* roll 0.017453292f0)) (s (f-sin r)))
    (declare (single-float fx fz l r s))
    (setf (aref up 0) (* s (/ (- fz) l)) (aref up 1) (f-cos r) (aref up 2) (* s (/ fx l)))
    nil))

(defun duel-camera (a b rdt &key snap)
  "Place the camera for this frame: the cinematic shot if one is set, else the pair camera (SNAP: no
smoothing, e.g. a new round)."
  (setf *punch-t* (max 0f0 (- *punch-t* (f32 rdt))))
  (cond (*cine-cam*
         (v3-copy! *cam-eye* *cine-eye*) (v3-copy! *cam-at* *cine-target*)
         (setf *cam-cut* t))
        ((and a b *view-behind*) (behind-camera a b rdt snap))
        ((and a b)
         (let* ((p (pos-of a)) (q (pos-of b))
                (mx (* 0.5 (+ (aref p 0) (aref q 0)))) (mz (* 0.5 (+ (aref p 2) (aref q 2))))
                (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (sep (sqrt (+ (* dx dx) (* dz dz))))
                (ux (if (> sep 0.01) (/ dx sep) 1.0)) (uz (if (> sep 0.01) (/ dz sep) 0.0))
                (ang (atan *view-z* *view-x*))
                (dist (* *cam-close* (max 6.0 (+ 4.5 (* 0.85 sep))) (if (> *punch-t* 0) 0.6 1.0)))
                (h (+ 2.5 (* 0.15 sep))) (c *cam-at*))
           (if (or snap *cam-cut*)
               (setf *cam-ang* (f32 ang) *cam-dist* (f32 dist) *cam-cut* nil
                     (aref c 0) (f32 mx) (aref c 2) (f32 mz))
               (let ((k (- 1.0 (exp (* (- *cam-orbit-rate*) rdt)))) (kd (- 1.0 (exp (* (- *cam-dist-rate*) rdt)))))
                 (setf *cam-ang* (f32 (+ *cam-ang* (* k (angle-wrap (- ang *cam-ang*)))))
                       *cam-dist* (f32 (+ *cam-dist* (* kd (- dist *cam-dist*))))
                       (aref c 0) (f32 (+ (aref c 0) (* k (- mx (aref c 0)))))
                       (aref c 2) (f32 (+ (aref c 2) (* k (- mz (aref c 2))))))))
           (let* ((back (* 0.05 *cam-dist*))            ; 3/4: a little behind P1
                  (ex (- (+ (aref c 0) (* *cam-dist* (cos *cam-ang*))) (* back ux)))
                  (ez (- (+ (aref c 2) (* *cam-dist* (sin *cam-ang*))) (* back uz)))
                  (k (min 1.0 (/ *cam-max-r* (max 0.01 (sqrt (+ (* ex ex) (* ez ez))))))))
             (v3-set! *cam-eye* (f32 (* k ex)) (f32 h) (f32 (* k ez)))
             (setf (aref c 1) 1.05f0)))))
  (let ((e *cam-eye*) (c *cam-at*) (up (camera-up *camera*)))
    (if (and *cine-cam* (/= *dutch* 0f0))                ; a dutch shot (cinema.lisp LENS)
        (%roll-up up e c *dutch*)
        (v3-set! up 0f0 1f0 0f0))
    (camera-look-at (aref e 0) (aref e 1) (aref e 2) (aref c 0) (aref c 1) (aref c 2))))
