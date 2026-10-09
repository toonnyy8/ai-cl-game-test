;;;; fighters.lisp — fighter entities (REN, enemies, dummies): creating one, the geometry helpers
;;;; every system uses (distance, facing; FWD-X / YAW-TO / TURN-TOWARD are the engine's), posing (animation -> joint matrices) and drawing a posed
;;;; fighter (tint / hit flash / emissive / hidden parts), plus throwing parts off as debris.
(in-package :raven)

;;; ---------------------------------------------------------------- creation
(defun spawn-fighter (body-name &key (x 0.0) (z 0.0) (yaw 0.0) (team :enemy))
  "A new fighter entity of BODY-NAME standing at (X, 0, Z): transform, motion, model, health,
fighter and blade-trail. PLAYER-INIT adds the player component, SPAWN-ENEMY / SPAWN-DUMMY a brain."
  (let* ((b (find-body body-name))
         (tf (make-transform :yaw (f32 yaw)))
         (e (spawn-entity tf (make-motion) (make-model :body b)
                          (make-health :hp (body-max-hp b) :max-hp (body-max-hp b) :poise (body-poise b))
                          (make-fighter :team team) (make-blade-trail))))
    (v3-set! (transform-pos tf) (f32 x) 0f0 (f32 z))
    (setf (fighter-name (fighter e))
          (if (eq team :player) "REN" (format nil "~a#~d" body-name (mod e +max-entities+))))
    (anim-play (model-anim (model e)) :idle :blend 0f0)
    (pose-update e)
    e))

(defun play-clip (e clip &key (blend 4f0) (speed 1f0) (restart t) (time 0f0))
  "Start animation CLIP on fighter E (see ANIM-PLAY: BLEND in frames, RESTART NIL keeps a running clip)."
  (anim-play (model-anim (model e)) clip :blend blend :speed speed :restart restart :time time))

(defun-fast pose-update (e)
  "Evaluate E's animation and run forward kinematics into its joint matrices."
  (let* ((m (model e)) (tf (transform e)) (p (transform-pos tf)) (b (model-body m)))
    (declare (type f32vec p))
    (pose-fk! (model-joints m) (anim-eval (model-anim m)) (aref p 0) (aref p 1) (aref p 2)
              (transform-yaw tf) (body-scale b) (body-hunch b))))

;;; ---------------------------------------------------------------- geometry
;;; (POS-OF / YAW-OF: engine/lisp/ecs.lisp)

(defun distance (a b)
  "Horizontal distance between entities A and B."
  (let* ((p (pos-of a)) (q (pos-of b)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))))
    (hypot dx dz)))

(defun face-toward (a b)
  "Turn A to face B at once."
  (let ((p (pos-of a)) (q (pos-of b)))
    (when (> (distance a b) 0.01)
      (setf (transform-yaw (transform a)) (yaw-to (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)))))))

(defun facing-p (a b half-deg)
  "Is B within HALF-DEG of A's facing?"
  (let* ((p (pos-of a)) (q (pos-of b)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (l (hypot dx dz)) (yaw (yaw-of a)))
    (or (< l 0.01)
        (>= (/ (+ (* dx (fwd-x yaw)) (* dz (fwd-z yaw))) l) (cos (deg half-deg))))))

(defun downed-p (e)
  "Knocked down and lying on the floor."
  (let ((f (fighter e))) (and (eq (fighter-state f) :knockdown) (>= (fighter-phase f) 1))))

(defun red-windup-p (e)
  "E is winding up a red (unblockable, telegraphed) attack."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (and (eq (fighter-state f) :move) mv (mv-red mv) (< (fighter-sf f) (mv-s mv)))))

(defun-fast blade-points! (e base tip)
  "World positions of E's blade base (0.25 m from the grip) and tip, for trails and sparks."
  (declare (type f32vec base tip))
  (let* ((b (body-of e)) (jm (model-joints (model e)))
         (len (if (and (eql e *player*) (raven-form-p)) (* 1.8f0 (body-blade-len b)) (body-blade-len b)))
         (bz (if (blade-trail-heavy (blade-trail e)) -0.05f0 -0.25f0)))
    (declare (type f32vec jm) (single-float len bz))
    (joint-point! base jm (ji :weapon-r) 0f0 0f0 bz)
    (joint-point! tip jm (ji :weapon-r) 0f0 0f0 (- -0.04f0 len))))

;;; ---------------------------------------------------------------- drawing
(declaim (type f32vec *dm* *dm2* *scarf-m*))
(defvar *dm* (m4))
(defvar *dm2* (m4))
(defvar *scarf-m* (m4))
(defvar *raven-red* '(1.0 0.12 0.24))
(defvar *raven-visor* (cons :visor *raven-red*) "Raven Form: the visor glow turns red (DRAW-PARTS :recolor).")

(defun draw-fighter (e &key (alpha 1f0) tint (emissive 0f0) hide-role rim)
  "Queue every visible part of fighter E (one draw-mesh per joint part + glows + weapon + scarf)
and its ground shadow. HIDE-ROLE skips glow parts with that role (boss phase-2 glows, brute red
maul core). RIM overrides the body's silhouette rim (f32vec, see RIM-VEC)."
  (let* ((m (model e)) (b (model-body m)) (jm (model-joints m)) (hid (model-hidden m)) (dm *dm*)
         (rim (or rim (body-rim b)))
         (fl (if (> (model-flash m) 0f0) 0.7f0 0f0))
         (raven (and (eql e *player*) (raven-form-p))))
    (declare (type f32vec jm dm) (fixnum hid))
    (draw-parts (body-parts b) (body-glows b) jm :hidden hid :hide hide-role :recolor (and raven *raven-visor*)
                :tint tint :flash fl :emissive emissive :alpha alpha :rim rim)
    (let ((w (ji :weapon-r)))
      (when (and (body-hilt b) (not (logbitp w hid)))
        (replace dm jm :start2 (* w 16) :end2 (+ 16 (* w 16)))
        (m4-mul! *dm2* dm (body-weapon-m b))
        (draw-mesh (body-hilt b) *dm2* :flash fl :alpha alpha :rim rim)
        (if raven
            (draw-mesh (body-raven-blade b) *dm2* :emissive 1.6 :alpha alpha)
            (draw-mesh (body-blade b) *dm2* :flash fl :alpha alpha :emissive 0.15))))
    (when (and (body-scarf b) (not (logbitp (ji :chest) hid)))
      (draw-scarf e raven alpha))
    (let ((p (pos-of e)))
      (fx-decal (aref p 0) (arena-ground-height (aref p 0) (aref p 2)) (aref p 2)
                (* 1.4 (body-hurt-r b)) 0 0 0 (* 0.5 alpha (max 0.0 (- 1.0 (* 0.3 (aref p 1)))))))))

(defun draw-scarf (e raven alpha)
  "Two trailing segments on the chest; they lift with horizontal speed and flutter."
  (let* ((b (body-of e)) (jm (model-joints (model e))) (v (motion-vel (motion e))) (m *scarf-m*) (dm *dm*)
         (spd (min 9.0 (hypot (aref v 0) (aref v 2))))
         (tm (elapsed-time))
         (a1 (- 1.25 (* 0.12 spd) (* 0.1 (sin (* tm (+ 5 spd)))))) (a2 (* 0.3 (sin (* tm (+ 7 spd))))))
    (replace dm jm :start2 (* (ji :chest) 16) :end2 (+ 16 (* (ji :chest) 16)))
    (m4-mul! m dm (m4-euler! *dm2* -0.05 0.18 0.12 0.15 (f32 a1) 0.0))
    (draw-mesh (body-scarf b) m :tint (and raven *raven-red*) :emissive (if raven 0.6 0.0) :alpha alpha)
    (m4-mul! m m (m4-euler! *dm2* 0.0 0.0 0.25 0.1 (f32 a2) 0.0))
    (draw-mesh (body-scarf b) m :tint (and raven *raven-red*) :emissive (if raven 0.6 0.0) :alpha alpha)))

(defun detach-parts (e mask vx vy vz &key (spin 6.0) (spread 1.5))
  "Hide the joints in MASK and throw their parts (and the weapon, if included) as debris."
  (let* ((m (model e)) (b (model-body m)) (jm (model-joints m)) (parts (body-parts b)))
    (dotimes (j +nj+)
      (when (and (logbitp j mask) (not (logbitp j (model-hidden m))))
        (let ((mesh (svref parts j))
              (sx (rnd-range (- spread) spread)) (sz (rnd-range (- spread) spread)))
          (when mesh
            (fx-debris mesh jm (* j 16) (+ (f32 vx) sx) (+ (f32 vy) (rnd-range 0f0 1.5f0)) (+ (f32 vz) sz) (f32 spin)))
          (dolist (g (body-glows b))
            (when (= (svref g 0) j) (fx-debris (svref g 1) jm (* j 16) (+ (f32 vx) sx) (f32 vy) (+ (f32 vz) sz) (f32 spin))))
          (when (and (= j (ji :weapon-r)) (body-hilt b))
            (m4-mul! *dm2* (replace *dm* jm :start2 (* j 16) :end2 (+ 16 (* j 16))) (body-weapon-m b))
            (fx-debris (body-hilt b) *dm2* 0 (f32 vx) (+ (f32 vy) 1f0) (f32 vz) (f32 spin))
            (fx-debris (body-blade b) *dm2* 0 (f32 vx) (+ (f32 vy) 1f0) (f32 vz) (f32 spin))))))
    (setf (model-hidden m) (logior (model-hidden m) mask))))
