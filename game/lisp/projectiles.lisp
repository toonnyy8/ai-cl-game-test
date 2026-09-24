;;;; projectiles.lisp — thrown things as entities (transform + projectile): the NEEDLER's kunai fan
;;;; and red blast kunai (sticks in the floor, explodes 0.9 s later) and ENRA's blade wave. Throwing
;;;; them (called from the throwers' move events), PROJECTILE-SYSTEM (per fixed step), drawing.
;;;; A projectile's hit belongs to its OWNER, so guard, parry and just dodge work as for melee.
(in-package :raven)

(defun spawn-projectile (kind owner x y z vx vy vz life)
  (let ((tf (make-transform)) (pr (make-projectile :kind kind :owner owner :life (f32 life))))
    (v3-set! (transform-pos tf) (f32 x) (f32 y) (f32 z))
    (v3-set! (projectile-vel pr) (f32 vx) (f32 vy) (f32 vz))
    (spawn-entity tf pr)))

(defun clear-projectiles ()
  (do-entities (e projectile) (destroy-entity e)))

(defun hand-point (e)
  "Values x y z: roughly the throwing hand (in front of the chest)."
  (let* ((p (pos-of e)) (y (yaw-of e)) (s (body-scale (body-of e))))
    (values (+ (aref p 0) (* 0.5 (fwd-x y))) (+ (aref p 1) (* 1.4 s)) (+ (aref p 2) (* 0.5 (fwd-z y))))))

(defun throw-fan (e)
  "3 kunai at -10/0/+10 deg, 22 m/s, aimed where the player will be in 0.2 s."
  (when (alive-p *player*)
    (multiple-value-bind (x y z) (hand-point e)
      (let* ((q (pos-of *player*)) (pv (motion-vel (motion *player*)))
             (tx (+ (aref q 0) (* 0.2 (aref pv 0)))) (tz (+ (aref q 2) (* 0.2 (aref pv 2)))) (ty (+ (aref q 1) 1.1))
             (dx (- tx x)) (dz (- tz z)) (dh (max 0.1 (sqrt (+ (* dx dx) (* dz dz)))))
             (base (atan (- dx) (- dz))) (vy (* 22.0 (/ (- ty y) dh))))
        (dolist (off '(-0.1745 0.0 0.1745))
          (let ((yaw (+ base off)))
            (spawn-projectile :kunai e x y z (* 22.0 (- (sin yaw))) vy (* 22.0 (- (cos yaw))) 1.2)))
        (sfx-at :kunai-throw x y z)
        (clog "~a kunai fan from ~,1f ~,1f (player at ~,1f dist)" (name-of e) x z dh)))))

(defun throw-blast (e)
  "Red blast kunai: 16 m/s arc to the player's position; sticks, detonates 0.9 s later."
  (when (alive-p *player*)
    (multiple-value-bind (x y z) (hand-point e)
      (let* ((q (pos-of *player*)) (dx (- (aref q 0) x)) (dz (- (aref q 2) z))
             (dh (max 0.5 (sqrt (+ (* dx dx) (* dz dz))))) (tt (/ dh 16.0))
             (vy (+ (/ (- 0.02 y) tt) (* 0.5 12.0 tt))))
        (spawn-projectile :blast e x y z (/ dx tt) vy (/ dz tt) 6.0)
        (sfx-at :kunai-throw x y z :pitch 0.8)))))

(defun throw-wave (e)
  "Blade Wave: a crescent 3 m wide, 18 m/s for 1.5 s, straight at the player."
  (let* ((p (pos-of e)) (yaw (if (alive-p *player*)
                                 (multiple-value-bind (dx dz) (to-player e) (yaw-to (f32 dx) (f32 dz)))
                                 (yaw-of e)))
         (fx (fwd-x yaw)) (fz (fwd-z yaw)))
    (spawn-projectile :wave e (+ (aref p 0) (* 1.2 fx)) 0.9 (+ (aref p 2) (* 1.2 fz)) (* 18.0 fx) 0.0 (* 18.0 fz) 1.5)
    (sfx-at :slash-heavy (aref p 0) 1.0 (aref p 2) :pitch 0.55 :gain 1.3)))

;;; ---------------------------------------------------------------- the per-step system
(defun projectile-system (k)
  "Advance every projectile one fixed step (K = enemy time scale)."
  (let ((dt (* k +step+)))
    (do-entities (e (pr projectile) (tf transform))
      (setf (projectile-life pr) (f32 (- (projectile-life pr) dt)))
      (ecase (projectile-kind pr)
        (:kunai (kunai-step e pr (transform-pos tf) dt))
        (:blast (blast-step e pr (transform-pos tf) dt))
        (:wave (wave-step e pr (transform-pos tf) dt))))))

(defun proj-move (pr p dt grav)
  "Ballistic step of position P with the projectile's velocity and gravity GRAV."
  (let ((v (projectile-vel pr)))
    (setf (aref v 1) (f32 (- (aref v 1) (* grav dt)))
          (aref p 0) (f32 (+ (aref p 0) (* dt (aref v 0))))
          (aref p 1) (f32 (+ (aref p 1) (* dt (aref v 1))))
          (aref p 2) (f32 (+ (aref p 2) (* dt (aref v 2)))))))

(defun proj-hits-prop-p (x z)
  (let ((tp *e-tmp*))
    (setf (aref tp 0) (f32 x) (aref tp 1) 0f0 (aref tp 2) (f32 z))
    (arena-resolve tp 0.05)))

(defun player-touch-p (x y z r)
  (let* ((e *player*) (q (pos-of e)) (b (body-of e)) (dx (- x (aref q 0))) (dz (- z (aref q 2))))
    (and (alive-p e)
         (< (+ (* dx dx) (* dz dz)) (expt (+ r (body-hurt-r b)) 2))
         (> y (- (aref q 1) r)) (< y (+ (aref q 1) (body-hurt-h b) r)))))

(defun player-slash-p (x y z reach &optional move-name)
  "Is a player attack's active window open with (x y z) in front of REN within REACH?"
  (let* ((e *player*) (f (fighter e)) (mv (fighter-move f)))
    (and (eq (fighter-state f) :move) mv (plusp (length (mv-hits mv)))
         (or (null move-name) (eq (mv-name mv) move-name))
         (let ((sf (fighter-sf f)) (hs (mv-hits mv)))
           (and (>= sf (hd-from (svref hs 0))) (< sf (hd-to (svref hs (1- (length hs)))))))
         (< y 2.6)
         (let* ((q (pos-of e)) (dx (- x (aref q 0))) (dz (- z (aref q 2))) (d (sqrt (+ (* dx dx) (* dz dz))))
                (yaw (yaw-of e)))
           (and (< d reach) (or (< d 0.7) (> (/ (+ (* dx (fwd-x yaw)) (* dz (fwd-z yaw))) d) 0.34)))))))

(defun proj-sparks (x y z)
  (fx-sparks (f32 x) (f32 y) (f32 z) 6 1.0 0.88 0.54))

(defun proj-hit (pr hd)
  "The owner's hit HD lands on REN (RESOLVE-HIT); NIL when the owner is gone."
  (let ((owner (projectile-owner pr)))
    (when (entity-alive-p owner) (resolve-hit owner *player* hd))))

(defun kunai-step (e pr p dt)
  (proj-move pr p dt 0.0)
  (let ((x (aref p 0)) (y (aref p 1)) (z (aref p 2)))
    (cond ((or (<= (projectile-life pr) 0) (< y 0.05))
           (when (< y 0.05) (sfx-at :kunai-hit x y z :gain 0.5) (proj-sparks x 0.05 z))
           (destroy-entity e))
          ((proj-hits-prop-p x z) (proj-sparks x y z) (destroy-entity e))
          ((player-slash-p x y z 2.4)                     ; cut out of the air
           (proj-sparks x y z) (sfx-at :clang x y z :gain 0.8) (destroy-entity e)
           (clog "kunai cut"))
          ((player-touch-p x y z 0.25)
           (let ((r (proj-hit pr *hd-kunai*)))
             (unless (eq r :dodged)
               (if (eq r :hit) (sfx-at :kunai-hit x y z) (proj-sparks x y z))
               (destroy-entity e)))))))

(defun blast-step (e pr p dt)
  (cond ((not (projectile-stuck pr))                       ; flying
         (proj-move pr p dt 12.0)
         (when (< (aref p 1) 0.05)
           (setf (aref p 1) 0.03f0 (projectile-stuck pr) t (projectile-fuse pr) 0.9f0)
           (fill (projectile-vel pr) 0f0)
           (when *freeze-on-stick* (setf *freeze-on-stick* nil *freeze-at* *tick*))
           (sfx-at :kunai-hit (aref p 0) 0.0 (aref p 2))
           (play-sfx :warn :gain 0.5 :pitch 1.3)))
        (t (setf (projectile-fuse pr) (f32 (- (projectile-fuse pr) dt)))
           (when (<= (projectile-fuse pr) 0) (blast-detonate e pr p)))))

(defun blast-detonate (e pr p)
  (let* ((x (aref p 0)) (z (aref p 2)) (pl *player*) (q (pos-of pl))
         (dx (- (aref q 0) x)) (dz (- (aref q 2) z)))
    (when (and (alive-p pl) (< (+ (* dx dx) (* dz dz)) (expt (+ 2.5 (body-hurt-r (body-of pl))) 2))
               (< (aref q 1) 2.5))
      (proj-hit pr *hd-blast*))
    (clog "blast kunai detonates at ~,1f ~,1f" x z)
    (sfx-at :brute-slam x 0.0 z :pitch 1.3)
    (shake 0.2 0.35)
    (fx-dust x z 20)
    (fx-burst +p-spark+ 30 x 0.3 z 0f0 1f0 0f0 0.9f0 5f0 10f0 0.4f0 0.05f0 1f0 0.45f0 0.2f0)
    (fx-ring x 0.0 z 0.3 2.5 0.3 1.0 0.3 0.15 :flat t :width 0.14)
    (add-point-light x 0.6 z 1.0 0.4 0.15 7.0 2.5)
    (destroy-entity e)))

(defun wave-step (e pr p dt)
  (proj-move pr p dt 0.0)
  (let* ((v (projectile-vel pr)) (x (aref p 0)) (y (aref p 1)) (z (aref p 2))
         (vx (aref v 0)) (vz (aref v 2)) (vl (max 0.01 (sqrt (+ (* vx vx) (* vz vz)))))
         (ux (/ vx vl)) (uz (/ vz vl)) (pl *player*) (q (pos-of pl))
         (dx (- (aref q 0) x)) (dz (- (aref q 2) z))
         (lon (+ (* dx ux) (* dz uz))) (lat (- (* dz ux) (* dx uz))))
    (cond ((<= (projectile-life pr) 0) (destroy-entity e))
          ((proj-hits-prop-p x z) (proj-sparks x y z) (destroy-entity e))
          ((player-slash-p x y z 6.5 :crimson-lance)
           (fx-burst +p-spark+ 20 x y z 0f0 0.3f0 0f0 1f0 5f0 9f0 0.3f0 0.04f0 1f0 0.3f0 0.3f0)
           (sfx-at :clang x y z) (destroy-entity e) (clog "blade wave destroyed by Crimson Lance"))
          ((and (alive-p pl) (< (abs lon) 0.8) (< (abs lat) 1.85) (< (aref q 1) 1.4))
           (let ((r (proj-hit pr *hd-wave*)))
             (unless (eq r :dodged) (destroy-entity e)))))))

;;; ---------------------------------------------------------------- drawing
(defun draw-projectiles ()
  (let ((pulse (+ 0.5 (* 0.5 (sin (* 50.265 (elapsed-time)))))))
    (do-entities (e (pr projectile) (tf transform))
      (let* ((p (transform-pos tf)) (v (projectile-vel pr)) (x (aref p 0)) (y (aref p 1)) (z (aref p 2))
             (vx (aref v 0)) (vy (aref v 1)) (vz (aref v 2))
             (vl (max 0.01 (sqrt (+ (* vx vx) (* vy vy) (* vz vz))))))
        (ecase (projectile-kind pr)
          (:kunai
           (fx-line x y z (- x (* 0.35 (/ vx vl))) (- y (* 0.35 (/ vy vl))) (- z (* 0.35 (/ vz vl)))
                    0.035 0.85 0.9 0.95 1.0 :end-width 0.012)
           (fx-line x y z (- x (* 1.6 (/ vx vl))) (- y (* 1.6 (/ vy vl))) (- z (* 1.6 (/ vz vl)))
                    0.045 0.1 0.9 1.0 0.45 :end-alpha 0.0)
           (fx-billboard x y z 0.16 0.6 0.95 1.0 0.9))
          (:blast
           (fx-billboard x (+ y 0.05) z (+ 0.12 (* 0.08 pulse)) 1.0 0.15 0.1 1.0)
           (when (projectile-stuck pr)
             (draw-red-ring x z 2.5 (+ 0.5 (* 0.5 pulse)))))
          (:wave
           (let* ((ux (/ vx vl)) (uz (/ vz vl)) (lx (- uz)) (lz ux) (n 8))
             (dotimes (j n)
               (let* ((s0 (- (* 2 (/ j (float n))) 1)) (s1 (- (* 2 (/ (1+ j) (float n))) 1))
                      (b0 (* -0.5 s0 s0)) (b1 (* -0.5 s1 s1))
                      (x0 (+ x (* 1.5 s0 lx) (* b0 ux))) (z0 (+ z (* 1.5 s0 lz) (* b0 uz)))
                      (x1 (+ x (* 1.5 s1 lx) (* b1 ux))) (z1 (+ z (* 1.5 s1 lz) (* b1 uz))))
                 (fx-line x0 y z0 x1 y z1 0.32 1.0 0.1 0.15 0.55)     ; red crescent + white core
                 (fx-line x0 y z0 x1 y z1 0.08 1.0 0.9 0.9 0.9))))))))))
