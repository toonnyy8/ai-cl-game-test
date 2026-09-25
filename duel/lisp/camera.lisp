;;;; camera.lisp — the one duel camera (design-v1 §7, critique-design §4.5): a 3/4 side view framing
;;;; both fighters, farther as they separate. Which side of the fighter axis it stands on is sim state
;;;; (fighter.lisp VIEW-STEP: P1 on the left at every start / reset, and it never swings 180° after a
;;;; Hoho); this file only places the render camera there, smoothing the ORBIT ANGLE around the
;;;; fighters' midpoint (so a strafing pair stays framed side-on instead of the eye trailing behind),
;;;; the distance and the midpoint separately. A cinematic shot (cinema.lisp) overrides it; the first
;;;; frame after one cuts back. A perfect Hoho punches in. Runs once per frame on real time.
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

(defun camera-side (&optional (a nil))
  "For a cinematic's SHOT-PAIR from actor A (default P1) to the other: the side (+1 / -1) of that
line the duel camera is on."
  (if (and a (= 1 (fighter-side (fighter a)))) (- *view-side*) *view-side*))

(defun duel-camera (a b rdt &key snap)
  "Place the camera for this frame: the cinematic shot if one is set, else the pair camera (SNAP: no
smoothing, e.g. a new round)."
  (setf *punch-t* (max 0f0 (- *punch-t* (f32 rdt))))
  (cond (*cine-cam*
         (v3-copy! *cam-eye* *cine-eye*) (v3-copy! *cam-at* *cine-target*)
         (setf *cam-cut* t))
        ((and a b)
         (let* ((p (pos-of a)) (q (pos-of b))
                (mx (* 0.5 (+ (aref p 0) (aref q 0)))) (mz (* 0.5 (+ (aref p 2) (aref q 2))))
                (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (sep (sqrt (+ (* dx dx) (* dz dz))))
                (ux (if (> sep 0.01) (/ dx sep) 1.0)) (uz (if (> sep 0.01) (/ dz sep) 0.0))
                (ang (atan *view-z* *view-x*))
                (dist (* (max 6.0 (+ 4.5 (* 0.85 sep))) (if (> *punch-t* 0) 0.6 1.0)))
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
  (let ((e *cam-eye*) (c *cam-at*))
    (camera-look-at (aref e 0) (aref e 1) (aref e 2) (aref c 0) (aref c 1) (aref c 2))))
