;;;; time.lisp — the time manager: fixed 60 Hz steps, hitstop (global sim freeze) and slow motion
;;;; for hit feedback. Pure bookkeeping: the game decides what a "step" simulates.
(in-package :engine)

;;; ---------------------------------------------------------------- time manager
;;; Real time is cut into fixed 1/60 s steps (+STEP+; the game's frame function runs as many as the
;;; frame's real time covers). Each step: TIME-STEP advances the real timers; if *HITSTOP* > 0 the
;;; gameplay sim is skipped for that step (fx keep running).
;;; Slow-mo gives each of two sides (the main side, e.g. the player, and "the others") a time scale;
;;; the game advances each side's frame counters by it.
(defparameter *hitstop-mult* 1.0 "Scales every HITSTOP request (tuning knob).")
(defconstant +step+ (/ 1f0 60f0))
(declaim (type fixnum *hitstop* *tick*) (type f32vec *slowmo*))
(defvar *hitstop* 0 "Frames of global sim freeze left.")
(defvar *tick* 0 "Fixed steps since start; advances during hitstop too.")
(defconstant +slowmo-n+ 8)
(defvar *slowmo* (make-f32 (* 3 +slowmo-n+)) "scale, real seconds left, who (0 everyone / 1 the others only)")

(defun hitstop (frames)
  "Request a global sim freeze of FRAMES; concurrent requests take the max."
  (let ((f (round (* frames *hitstop-mult*))))
    (when (> f *hitstop*) (setf *hitstop* f))))

(defun slowmo (scale secs &optional others-only)
  "Time-scale the sim (or only the other side, e.g. the opponents) to SCALE for SECS of real time.
Lowest scale wins."
  (let* ((s *slowmo*) (best 0) (bl most-positive-single-float))
    (dotimes (i +slowmo-n+)
      (let ((left (aref s (+ (* i 3) 1))))
        (when (< left bl) (setf bl left best i))))
    (setf (aref s (* best 3)) (f32 scale) (aref s (+ (* best 3) 1)) (f32 secs)
          (aref s (+ (* best 3) 2)) (if others-only 1f0 0f0))))

(defun-fast slowmo-scale (others)
  "Current sim scale for the main side (OTHERS nil) or the other side. Eases to 1 over the last 0.1 s."
  (let* ((s *slowmo*) (sc 1f0))
    (declare (type f32vec s) (single-float sc))
    (dotimes (i +slowmo-n+ sc)
      (let* ((o (* i 3)) (left (aref s (+ o 1))))
        (declare (fixnum o) (single-float left))
        (when (and (> left 0f0) (or others (< (aref s (+ o 2)) 0.5f0)))
          (let* ((k (aref s o)) (e (if (< left 0.1f0) (+ k (* (- 1f0 k) (- 1f0 (* left 10f0)))) k)))
            (declare (single-float k e))
            (setf sc (f-min sc e))))))))

(defun-fast time-step ()
  "Advance real-time timers by one fixed step. Returns T when the sim should run this step."
  (let* ((s *slowmo*))
    (declare (type f32vec s))
    (setf *tick* (1+ *tick*))
    (dotimes (i +slowmo-n+)
      (let* ((o (+ (* i 3) 1))) (declare (fixnum o))
        (setf (aref s o) (f-max 0f0 (- (aref s o) +step+)))))
    (if (> *hitstop* 0) (progn (setf *hitstop* (1- *hitstop*)) nil) t)))
