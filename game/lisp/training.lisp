;;;; training.lisp — the TRAINING scene: three RAINBLADE dummies (fighter + brain + dummy) that idle,
;;;; face REN, react, can be crippled / obliterated, and respawn 3 s after death. T toggles
;;;; "dummies attack": they walk in, take tokens and slash (30 % red). ENEMY-SYSTEM ticks them.
(in-package :raven)

(defvar *dummies-attack* nil "T toggles: dummies take tokens and attack when the player is close.")

(defun spawn-dummy (x z yaw)
  (let ((e (spawn-fighter :rainblade :x x :z z :yaw yaw)))
    (add-component e (make-brain :kind :rainblade))
    (add-component e (make-dummy :home-x (f32 x) :home-z (f32 z) :home-yaw (f32 yaw)))
    e))

(defun training-init ()
  "REN and three dummies on an empty roof."
  (clear-entities)
  (take-events)
  (player-init 0.0 8.0 0.0)
  (loop for (x z) in '((-3.5 3.0) (0.0 4.5) (3.5 3.0)) do (spawn-dummy x z pi))
  (clog "training: REN + ~d dummies" 3))

(defun dummy-think (e k)
  "Face the player; with *DUMMIES-ATTACK*, walk in, request a melee token and slash (30 % red)."
  (when (crippled-p e) (return-from dummy-think nil))    ; crippled dummies just kneel
  (let* ((b (brain e)) (pl *player*) (d (distance e pl)) (dt (* k +step+)))
    (when (and (alive-p pl) (< d 10.0))
      (let* ((p (pos-of e)) (q (pos-of pl))
             (want (yaw-to (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)))))
        (setf (transform-yaw (transform e)) (turn-toward (yaw-of e) want (* (deg 360) dt)))))
    (countdown! (brain-cooldown b) dt)
    (let ((v (motion-vel (motion e))) (walk (and *dummies-attack* (alive-p pl) (> d 2.0) (< d 12.0))))
      (setf (aref v 0) (if walk (* 3.0 (fwd-x (yaw-of e))) 0f0) (aref v 2) (if walk (* 3.0 (fwd-z (yaw-of e))) 0f0))
      (play-clip e (if walk :walk :idle) :blend 8f0 :restart nil))
    (when (and *dummies-attack* (alive-p pl) (<= (brain-cooldown b) 0) (<= d 2.4))
      (let ((tok (token-request e :melee)))
        (when tok
          (face-toward e pl)
          (fill (motion-vel (motion e)) 0f0)
          (let ((mv (start-move e (if (< (rnd01) 0.3) :rb-red :rb-slash))))
            (when (eq tok :punish) (setf (fighter-sf (fighter e)) (* 0.2 (mv-s mv)))))
          (setf (brain-cooldown b) (f32 (* *enemy-cooldown-mult* (+ 1.2 (* 0.8 (rnd01)))))))))))

(defun dummy-tick (e k)
  "One fixed step of a training dummy (K = enemy time scale); respawns 3 s after death."
  (if (eq (state-of e) :dead)
      (let ((f (fighter e)))
        (setf (fighter-corpse-t f) (f32 (- (fighter-corpse-t f) (* k +step+))))
        (when (<= (fighter-corpse-t f) 0) (dummy-respawn e)))
      (enemy-step e k #'dummy-think)))

(defun dummy-respawn (e)
  (let* ((d (dummy e)) (b (body-of e)) (h (health e)) (mo (motion e)) (x (dummy-home-x d)) (z (dummy-home-z d)))
    (v3-set! (pos-of e) x 0f0 z)
    (fill (motion-vel mo) 0f0)
    (setf (transform-yaw (transform e)) (dummy-home-yaw d) (health-alive h) t (health-hp h) (body-max-hp b)
          (health-poise h) (body-poise b) (model-hidden (model e)) 0 (fighter-crippled (fighter e)) nil
          (motion-grounded mo) t (health-invuln h) 18f0 (motion-kb-left mo) 0f0 (brain-cooldown (brain e)) 1.5)
    (enemy-to-idle e)
    (fx-burst +p-glow+ 14 x 1.0f0 z 0f0 0.5f0 0f0 1f0 0.5f0 2.5f0 0.5f0 0.2f0 0.62f0 0.78f0 1f0)
    (clog "~a respawn" (name-of e))))
