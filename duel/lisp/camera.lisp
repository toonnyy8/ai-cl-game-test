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
(defparameter *cam-close* 0.6 "Both cameras' distances x this (0.6 = 40 % closer than the original framing; user request, docs/style/STYLE_STORM_DESIGN.md §6).")
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

;;; The PORTRAIT camera (ONE-HAND on a phone; docs/duel/DUEL_MOBILE_DESIGN.md §4.1, P2, the user's request 2026-09-27):
;;; the behind camera's framing re-solved for a tall screen whose arena is only the band between the HUD's top block
;;; and the thumb deck (*BAND*, brush.lisp; onehand.lisp DECK-UPDATE sets it). Render-side only: *BEHIND-YAW* (sim state, it steers the
;;; stick) is read, never written. The eye orbits at the sim yaw plus a lead of at most *PT-LEAD* toward the true
;;; P1 -> P2 direction (the catch-up after a Hoho or a sidestep), farther back and lower than the landscape one; the aim
;;; bisects P1 and P2 (azimuth: their centres; pitch: P1's feet and P2's head), within *PT-LEAD* of the orbit; the lens
;;; is shifted (G6) so that aim lands on the band's middle, with the vertical FOV that gives the band *PT-BAND-FOV*.
(declaim (type f32vec *pcam*))
(defvar *pcam* (make-f32 3) "Portrait camera state: [0] the orbit's lead over *BEHIND-YAW* (radians, smoothed); [1] unused; [2] the
smoothed vertical FOV (radians).")
(defvar *pt-lens* nil "The portrait lens is on (else the landscape one: FOV 60, no shift; LANDSCAPE-LENS).")
(defparameter *pt-back* 9f0 "Portrait: metres behind P1 (x *CAM-CLOSE*, + *BEHIND-WIDEN* per metre past 4 m) ...")
(defparameter *pt-up* 2f0 "... this high ...")
(defparameter *pt-shoulder* 0.5f0 "... this far to his right.")
(defparameter *pt-close* 15f0 "Up close the orbit swings to P1's right by up to this many degrees (landscape: *BEHIND-CLOSE* 40).")
(defparameter *pt-lead* 20f0 "Degrees the orbit may lead the sim yaw toward P2 (the catch-up), and the aim may leave the orbit.")
(defparameter *pt-head* 2.2f0 "The aim's pitch bisects P1's feet and this height over P2.")
(defparameter *pt-frame-bottom* 0.82 "The frame's bottom (a fraction of the height): the fighters stand low, the thumb may cover their feet.")
(defparameter *pt-band-fov* 30f0 "Degrees of view the frame (*BAND* 0..1) spans vertically ...")
(defparameter *pt-fov-min* 40f0 "... the whole screen's vertical FOV kept within these (degrees) ...")
(defparameter *pt-fov-max* 100f0 "... (the fit may widen it past the band's FOV up to this).")
(defparameter *pt-cine-fov* 66f0 "Portrait cinematics: a shot's LENS at least this (degrees) ...")
(defparameter *pt-dolly-max* 2.4f0 "... and its eye backed off the target (at most this factor) so the frame's width holds the landscape frame's
central square: a shot framed for 16:9 is not cropped (§4.3's lens clamp).")

(defmacro %expf (x) `(ffi:c-inline (,x) (:float) :float "expf(#0)" :one-liner t))

(defun-fast %portrait-camera (p q rdt snap)
  "Place *CAM-EYE* / *CAM-AT* and the lens for the portrait camera behind P1 (at P) toward P2 (at Q); SNAP: no
smoothing. 0 B (state in *PCAM* / *CAM-ANCHOR*, knobs read as floats)."
  (declare (type f32vec p q) (single-float rdt))
  (let* ((c *cam-anchor*) (pc *pcam*) (e *cam-eye*) (at *cam-at*) (bd *band*) (cam *camera*)
         (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (sep (f-sqrt (+ (* dx dx) (* dz dz))))
         (sim *behind-yaw*) (lim (* 0.017453292f0 (the single-float *pt-lead*)))
         (want (if (> sep 0.01f0) (f-clamp (f-wrap (- (f-atan2 (- dx) (- dz)) sim)) (- lim) lim) 0f0))
         (k (if snap 1f0 (- 1f0 (%expf (* -8f0 rdt)))))
         (lead (+ (aref pc 0) (* k (- want (aref pc 0)))))
         (yaw (+ sim lead)) (fx (- (f-sin yaw))) (fz (- (f-cos yaw)))
         (wide (* (the single-float *behind-widen*) (f-max 0f0 (- sep 4f0))))
         (back (* (the single-float *cam-close*) (+ (the single-float *pt-back*) wide) (if (> *punch-t* 0f0) 0.8f0 1f0)))
         (off (* 0.017453292f0 (the single-float *pt-close*) (f-clamp (/ (- 6f0 sep) 4f0) 0f0 1f0)))
         (side (+ (the single-float *pt-shoulder*) (* back (f-sin off))))
         (bk (* back (f-cos off)))
         (ka (if snap 1f0 (- 1f0 (%expf (* (- (the single-float *behind-rate*)) rdt))))))
    (declare (type f32vec c pc e at bd) (single-float dx dz sep sim lim want k lead yaw fx fz wide back off side bk ka))
    (setf (aref pc 0) lead
          (aref c 0) (+ (aref c 0) (* ka (- (aref p 0) (aref c 0)))) (aref c 2) (+ (aref c 2) (* ka (- (aref p 2) (aref c 2)))))
    (let* ((ex (+ (aref c 0) (* (- bk) fx) (* side (- fz)))) (ez (+ (aref c 2) (* (- bk) fz) (* side fx)))
           (r (f-sqrt (+ (* ex ex) (* ez ez)))) (kr (f-min 1f0 (/ (the single-float *cam-max-r*) (f-max 0.01f0 r))))
           (h (+ (the single-float *pt-up*) (* 0.33f0 wide) (* 0.4f0 (- r (* kr r))))))   ; pulled in by the wall: rise
      (declare (single-float ex ez r kr h))
      (setf ex (* kr ex) ez (* kr ez))
      (macrolet ((clear-of (o)                          ; never inside a fighter
                   `(let* ((ddx (- ex (aref ,o 0))) (ddz (- ez (aref ,o 2))) (d (f-sqrt (+ (* ddx ddx) (* ddz ddz)))))
                      (declare (single-float ddx ddz d))
                      (when (and (< d 1f0) (> d 0.001f0)) (setf ex (+ (aref ,o 0) (/ ddx d)) ez (+ (aref ,o 2) (/ ddz d)))))))
        (clear-of p) (clear-of q))
      (setf (aref e 0) ex (aref e 1) h (aref e 2) ez)
      ;; the aim: bisect the two fighters (azimuth by their centres, pitch by P1's near feet and over P2's head); the lens
      ;; lands it on the band's middle (the shift) and widens past *PT-BAND-FOV* only when the pair needs more (the eye
      ;; pulled in by the wall, P2 wide after a Hoho): a vertical and a horizontal fit with a margin for their bulk
      (let* ((ax (- (aref p 0) ex)) (az (- (aref p 2) ez)) (bx (- (aref q 0) ex)) (bz (- (aref q 2) ez))
             (d1 (f-sqrt (+ (* ax ax) (* az az)))) (d2 (f-sqrt (+ (* bx bx) (* bz bz))))
             (a1 (f-atan2 (- ax) (- az))) (a2 (f-atan2 (- bx) (- bz))) (da (f-wrap (- a2 a1)))
             (want (f-wrap (- (+ a1 (* 0.5f0 da)) yaw))) (dy (f-clamp want (- lim) lim)) (aim (+ yaw dy))
             (t1 (f-atan2 h (f-max 0.5f0 (- d1 0.6f0)))) (t2 (f-atan2 (- h (the single-float *pt-head*) 0.3f0) (+ d2 0.6f0)))
             (pitch (* 0.5f0 (+ t1 t2))) (cp (* 5f0 (f-cos pitch)))
             (b (f-max 0.1f0 (- (aref bd 1) (aref bd 0))))
             (hb (f-max (* 0.0087266462f0 (the single-float *pt-band-fov*)) (+ (* 0.5f0 (- t1 t2)) 0.026f0)))
             (hz (+ (* 0.5f0 (f-abs da)) (f-abs (- want dy)) (f-atan2 0.7f0 (f-max 0.5f0 (- (f-min d1 d2) 0.6f0)))))
             (asp (/ (i->f (window-width)) (i->f (max 1 (window-height)))))
             (fov (f-clamp (* 2f0 (f-max (f-atan2 (/ (f-sin hb) (f-cos hb)) b)
                                         (f-atan2 (/ (f-sin (f-min hz 1.4f0)) (f-cos (f-min hz 1.4f0))) asp)))
                           (* 0.017453292f0 (the single-float *pt-fov-min*)) (* 0.017453292f0 (the single-float *pt-fov-max*))))
             (sm (if (or snap (not *pt-lens*)) fov (+ (aref pc 2) (* k (- fov (aref pc 2))))))
             (sh (- 1f0 (+ (aref bd 0) (aref bd 1)))))
        (declare (single-float ax az bx bz d1 d2 a1 a2 da want dy aim t1 t2 pitch cp b hb hz asp fov sm sh))
        (setf (aref at 0) (+ ex (* cp (- (f-sin aim)))) (aref at 1) (- h (* 5f0 (f-sin pitch))) (aref at 2) (+ ez (* cp (- (f-cos aim))))
              (aref pc 2) sm *pt-lens* t)
        ;; the camera's slots hold boxed floats: written only on a visible change (0 B on most frames)
        (when (> (f-abs (- (the single-float (camera-fov cam)) sm)) 0.002f0) (setf (camera-fov cam) sm))
        (when (/= (the single-float (camera-shift-y cam)) sh) (setf (camera-shift-y cam) sh))))
    nil))

(defun-fast %portrait-dolly (aspect)
  "Portrait cinematics (§4.3): the vertical FOV at least *PT-CINE-FOV*, no lens shift, and *CAM-EYE* backed off
*CAM-AT* so the frame's width holds what a landscape frame's central square held (x tan(lens/2) / (tan(fov/2) aspect),
at most *PT-DOLLY-MAX*), kept inside the arena ring. A close-up of one fighter (*CINE-CLOSE*) keeps the script's lens and
eye: the frame's height matches the landscape one and the body may be cropped (the user's decision 2026-09-28). 0 B."
  (declare (single-float aspect))
  (let* ((cam *camera*) (e *cam-eye*) (at *cam-at*) (lens *lens-fov*)
         (fov (if *cine-close* lens (f-max lens (* 0.017453292f0 (the single-float *pt-cine-fov*)))))
         (k (if *cine-close*
                1f0
                (f-clamp (/ (/ (f-sin (* 0.5f0 lens)) (f-cos (* 0.5f0 lens)))
                            (* aspect (/ (f-sin (* 0.5f0 fov)) (f-cos (* 0.5f0 fov)))))
                         1f0 (the single-float *pt-dolly-max*))))
         (vx (- (aref e 0) (aref at 0))) (vy (- (aref e 1) (aref at 1))) (vz (- (aref e 2) (aref at 2)))
         (rr (the single-float *cam-max-r*)) (ex (+ (aref at 0) (* k vx))) (ez (+ (aref at 2) (* k vz))))
    (declare (type f32vec e at) (single-float lens fov k vx vy vz rr ex ez))
    (when (> (+ (* ex ex) (* ez ez)) (* rr rr))       ; outside the ring: the largest k (>= 1) that stays in
      (let* ((a (+ (* vx vx) (* vz vz))) (b (+ (* (aref at 0) vx) (* (aref at 2) vz)))
             (cc (- (+ (* (aref at 0) (aref at 0)) (* (aref at 2) (aref at 2))) (* rr rr)))
             (disc (- (* b b) (* a cc))))
        (declare (single-float a b cc disc))
        (setf k (if (and (> a 1f-6) (>= disc 0f0)) (f-clamp (/ (+ (- b) (f-sqrt disc)) a) 1f0 k) 1f0))))
    (setf (aref e 0) (+ (aref at 0) (* k vx)) (aref e 1) (+ (aref at 1) (* k vy)) (aref e 2) (+ (aref at 2) (* k vz))
          *pt-lens* t)
    (when (/= (the single-float (camera-fov cam)) fov) (setf (camera-fov cam) fov))
    (when (/= (the single-float (camera-shift-y cam)) 0f0) (setf (camera-shift-y cam) 0f0))
    nil))

(defparameter *cine-keep* 0.55
  "A cinematic SHOT-ON's subject (his pelvis) stays within this fraction of the frame's half-width of its centre
(%KEEP-SUBJECT; docs/duel/DUEL_KEN_BANKAI.md §1.3). 1 = only keep him from leaving the frame.")
(defparameter *pt-cine-keep* 0.3 "... on a portrait screen (a close-up there keeps its narrow lens: nearer the middle).")

(defun-fast %keep-subject (aspect)
  "A SHOT-ON's aim is scripted (:off / :ahead, tuned on 16:9) and the clip's root motion carries the body away from his
feet (a leap, a charge or a cleave carries it up to 1.4 m): on a narrow frame (portrait keeps a close-up's lens)
he left the shot. Slide *CAM-EYE* and *CAM-AT* sideways so his posed pelvis is within *CINE-KEEP* of the half-width at
his depth; nothing moves while he already is. Render-side; the joints are the last drawn ones (1 frame old). 0 B."
  (declare (single-float aspect))
  (let ((e *cine-subject*))
    (when (and e (model e))
      (let* ((jm (model-joints (model e))) (o (* 16 (ji :pelvis)))
             (eye *cam-eye*) (at *cam-at*)
             (dx (- (aref at 0) (aref eye 0))) (dz (- (aref at 2) (aref eye 2)))
             (l (f-sqrt (+ (* dx dx) (* dz dz)))))
        (declare (type f32vec jm eye at) (fixnum o) (single-float dx dz l))
        (when (> l 1f-3)
          (let* ((ux (/ dx l)) (uz (/ dz l))                          ; the view's ground direction, its right (-uz ux)
                 (sx (- (aref jm (+ o 12)) (aref eye 0))) (sz (- (aref jm (+ o 14)) (aref eye 2)))
                 (depth (+ (* sx ux) (* sz uz))) (side (- (* sz ux) (* sx uz)))
                 (fov (the single-float (camera-fov *camera*)))
                 (lim (* (the single-float (if (< aspect 1f0) *pt-cine-keep* *cine-keep*)) depth aspect (/ (f-sin (* 0.5f0 fov)) (f-cos (* 0.5f0 fov)))))
                 (sh (cond ((> side lim) (- side lim)) ((< side (- lim)) (+ side lim)) (t 0f0))))
            (declare (single-float ux uz sx sz depth side fov lim sh))
            (when (and (> depth 0.3f0) (/= sh 0f0))
              (let ((mx (- (* sh uz))) (mz (* sh ux)))
                (declare (single-float mx mz))
                (setf (aref eye 0) (+ (aref eye 0) mx) (aref eye 2) (+ (aref eye 2) mz)
                      (aref at 0) (+ (aref at 0) mx) (aref at 2) (+ (aref at 2) mz))))))))
    nil))

(defun landscape-lens ()
  "Back to the landscape lens (FOV 60, no shift) after the portrait one (a phone turned; the menus)."
  (when *pt-lens*
    (setf *pt-lens* nil (camera-shift-y *camera*) 0f0 (camera-fov *camera*) (f32 (deg 60)))))

(defun portrait-lens (fov shift)
  "A portrait menu's lens: vertical FOV degrees, the image moved up SHIFT (NDC); LANDSCAPE-LENS undoes it."
  (setf (camera-fov *camera*) (f32 (deg fov)) (camera-shift-y *camera*) (f32 shift) *pt-lens* t))

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
  (unless (or *cine-cam* (not (and a b)) (portrait-p)) (landscape-lens))
  (cond (*cine-cam*
         (v3-copy! *cam-eye* *cine-eye*) (v3-copy! *cam-at* *cine-target*)
         (when (portrait-p) (%portrait-dolly (f32 (window-aspect))))
         (%keep-subject (f32 (window-aspect)))
         (setf *cam-cut* t))
        ((and a b (portrait-p))                           ; a tall screen: the portrait camera, whatever the mode
         (%portrait-camera (pos-of a) (pos-of b) (f32 rdt) (or snap *cam-cut*))
         (setf *cam-cut* nil))
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
