;;;; enemy.lisp — the enemies' behaviour (GAME_DESIGN §5): spawning, the per-step ENEMY-SYSTEM,
;;;; drop-in, crippled crawl / Death Grip / Rampage, the AI brains of the RAINBLADE grunt, NEEDLER
;;;; kunai thrower, OXHEAD brute and ENRA the boss (2 phases), and drawing enemies with their red
;;;; telegraphs. Bodies, clips and moves are data files; projectiles are projectiles.lisp; waves
;;;; and game flow are game.lisp.
(in-package :raven)

;;; ---------------------------------------------------------------- debug switches (debug.lisp sets them)
(defvar *freeze-on-event* nil "Debug: ticks after the next enemy move event to near-freeze (screenshots).")
(defvar *freeze-at* nil)
(defvar *freeze-on-stick* nil)
(defvar *freeze-actor* nil "Only this enemy's move event triggers *FREEZE-ON-EVENT* (the last forced one).")
(defvar *ai-off* nil "Debug: enemies stand still (model checks).")

;;; ================================================================ helpers
(defun e-stop (e) (let ((v (motion-vel (motion e)))) (setf (aref v 0) 0f0 (aref v 2) 0f0)))

(defun e-vel (e dx dz speed)
  "Horizontal velocity along (DX DZ) at SPEED m/s."
  (let ((l (hypot dx dz)) (v (motion-vel (motion e))))
    (if (< l 1e-4)
        (setf (aref v 0) 0f0 (aref v 2) 0f0)
        (setf (aref v 0) (f32 (* speed (/ dx l))) (aref v 2) (f32 (* speed (/ dz l)))))))

(defun e-face (e x z rate dt)
  (let ((p (pos-of e)))
    (setf (transform-yaw (transform e))
          (turn-toward (yaw-of e) (yaw-to (f32 (- x (aref p 0))) (f32 (- z (aref p 2)))) (* rate dt)))))

(defun e-face-player (e dt &optional (rate (turn-rate e)))
  (let ((q (pos-of *player*))) (e-face e (aref q 0) (aref q 2) rate dt)))

(defun to-player (e)
  "Values dx dz from E to the player."
  (let ((p (pos-of e)) (q (pos-of *player*)))
    (values (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)))))

(defun turn-rate (e)
  "Yaw rate (rad/s) of the enemy kind."
  (case (kind-of e) (:oxhead 3.1416) (:enra 9.4248) (t 6.2832)))

(defun set-mode (e mode) (let ((b (brain e))) (setf (brain-mode b) mode (brain-mode-t b) 0.0)))

(defun e-move (e name)
  "Start a non-attack move (backstep, flip, taunt...): no token, no off-screen rule."
  (e-stop e)
  (start-move e name))

(defun e-backflip (e name)
  "Invulnerable backflip away from the player (grunt Escape, needler after its swipe)."
  (face-toward e *player*)
  (e-move e name)
  (setf (health-invuln (health e)) 18f0)
  (let ((p (pos-of e))) (sfx-at :jump (aref p 0) 1.0 (aref p 2))))

(declaim (type f32vec *e-scr* *e-tmp* *red-tint*))
(defvar *e-scr* (make-f32 3))
(defvar *e-tmp* (make-f32 3))
(defvar *red-tint* (make-f32 3))

(defun offscreen-p (e)
  "Off-screen rule (§4.6): the attacker's chest projects outside the screen (or behind the camera)."
  (let ((p (pos-of e)) (v *e-scr*))
    (or (not (world-to-screen v (aref p 0) (+ (aref p 1) 1.0) (aref p 2)))
        (< (aref v 0) 0.0) (> (aref v 0) (float (window-width))))))

(defun enemy-attack (e name &key (mult 1.0) (skip 0.0))
  "Start attack NAME facing the player. MULT < 1 shortens the windup by skipping its start
(punish token x0.8, boss phase 2 x0.85; red windups never drop below 42 f); SKIP drops that many
frames more. Off-screen attackers get +10 f windup, :warn and a HUD chevron."
  (let* ((mv (find-move name)) (s (mv-s mv)) (sk (windup-skip s (mv-red mv) mult skip)))
    (face-toward e *player*)
    (e-stop e)
    (start-move e mv)
    (when (and (> s 0) (offscreen-p e))
      (decf sk 10.0)
      (setf (brain-chevron-t (brain e)) 0.6)
      (unless (mv-red mv) (play-sfx :warn :gain 0.7))
      (clog "~a off-screen attack ~a" (name-of e) name))
    (setf (fighter-sf (fighter e)) (f32 sk)
          (anim-time (model-anim (model e))) (f32 (* (/ sk 60.0) (mv-clip-speed mv))))
    mv))

;;; ================================================================ spawning & the per-step system
(defun spawn-enemy (kind x z &key (drop 6.0))
  "New enemy of KIND dropping in at (X, DROP, Z) facing the player (state :spawn, invulnerable
until it lands)."
  (let* ((e (spawn-fighter kind :x x :z z))
         (p (pos-of e)) (f (fighter e)))
    (add-component e (make-brain :kind kind :block-chance (case kind (:rainblade 0.35) (:enra 0.6) (t 0f0))
                                 :cooldown (f32 (+ 1.0 (rnd01))) :strafe-dir (if (< (rnd01) 0.5) 1.0 -1.0)))
    (setf (aref p 1) (f32 drop) (motion-grounded (motion e)) (<= drop 0)
          (fighter-state f) :spawn (health-invuln (health e)) 9999f0)
    (when (eq kind :enra)
      (let ((h (health e))) (setf (health-hp h) (f32 *boss-hp*) (health-max-hp h) (f32 *boss-hp*))))
    (when (entity-alive-p *player*) (face-toward e *player*))
    (play-clip e (if (member kind '(:rainblade :needler)) :drop-in :fall) :blend 0f0)
    (clog "spawn ~a at ~,1f ~,1f" (fighter-name f) x z)
    e))

(defun enemy-system (k)
  "One fixed step of every AI fighter (K = enemy time scale): enemies think with their kind's
brain, training dummies with theirs (training.lisp)."
  (do-entities (e brain) (if (dummy e) (dummy-tick e k) (enemy-tick e k))))

(defun enemy-tick (e k)
  "One fixed step of enemy E. A dead one lies there until its corpse timer runs out."
  (if (eq (state-of e) :dead)
      (let ((f (fighter e)))
        (setf (fighter-corpse-t f) (f32 (- (fighter-corpse-t f) (* k +step+))))
        (when (<= (fighter-corpse-t f) 0) (destroy-entity e)))
      (let* ((f (fighter e)) (st0 (fighter-state f)) (mv0 (fighter-move f)) (sf0 (fighter-sf f)))
        (enemy-pre e k)
        (enemy-step e k #'enemy-think)
        (when (alive-p e) (enemy-post e st0 mv0 sf0)))))

(defun enemy-pre (e k)
  "Move-time behaviour enemy-step doesn't do: windup tracking (stops 8 f before the strike),
the brute's charge run, stopping after it."
  (let ((f (fighter e)))
    (when (eq (fighter-state f) :move)
      (let* ((mv (fighter-move f)) (sf (fighter-sf f)) (s (mv-s mv)) (dt (* k +step+)))
        (when (and (< sf (- s 8)) (alive-p *player*))
          (e-face-player e dt))
        (when (eq (mv-special mv) :charge)
          (if (and (>= sf s) (< sf (+ s (mv-a mv))))
              (charge-step e)
              (e-stop e)))))))

(defun enemy-post (e st0 mv0 sf0)
  "Move events (crossing the strike frame), move ends, reaction exits, crumple entry, boss phase."
  (let* ((f (fighter e)) (st (fighter-state f)) (b (brain e)) (last (brain-last-state b)))
    (when (> (brain-chevron-t b) 0) (countdown! (brain-chevron-t b) +step+))
    (cond ((and (eq st :move) (eq st0 :move) (eq mv0 (fighter-move f)))
           (let ((s (mv-s mv0)) (sf (fighter-sf f)))
             (when (and (< sf0 s) (>= sf s)) (move-event e mv0))
             (when (and (eq (mv-special mv0) :leap) (brain-leaping b) (motion-grounded (motion e)) (> sf (+ s 3)))
               (leap-land e))))
          ((and (eq st0 :move) mv0 (member st '(:idle :crippled)))
           (on-move-end e mv0)))
    (when (and (member last '(:flinch :stagger :knockdown :launched :guard-break)) (eq (fighter-state f) :idle))
      (setf (brain-cooldown b) (f32 (max (brain-cooldown b) 0.5)) (brain-mode b) :recover (brain-free-t b) 0.0))
    (when (and (eq (fighter-state f) :crumple) (not (eq last :crumple)))
      (setf (brain-mode-t b) 0.0 (brain-block-chance b) 0f0 (brain-cooldown b) 1.2))
    (when (eq (brain-kind b) :enra) (enra-post e))
    (setf (brain-last-state b) (fighter-state f))))

(defun enemy-think (e k)
  "AI for a free enemy (enemy-step calls it only outside moves and reactions)."
  (cond ((eq (state-of e) :spawn) (spawn-tick e k))
        ((crippled-p e) (crippled-think e k))
        ((or *ai-off* (not (alive-p *player*))) (e-stop e) (play-clip e :idle :blend 8f0 :restart nil))
        (t (case (brain-kind (brain e))
             (:rainblade (rainblade-think e k))
             (:needler (needler-think e k))
             (:oxhead (oxhead-think e k))
             (:enra (enra-think e k))))))

(defun spawn-tick (e k)
  "Drop-in: invulnerable while falling; on landing dust (+ shockwave for the big ones), 0.3 s
(boss 0.6 s) invulnerable, then the AI starts."
  (when (motion-grounded (motion e))
    (let* ((b (brain e)) (p (pos-of e)) (x (aref p 0)) (z (aref p 2)) (kind (brain-kind b))
           (big (member kind '(:oxhead :enra))))
      (cond ((not (brain-touched-down b))
             (setf (brain-touched-down b) t (brain-mode-t b) 0.0 (health-invuln (health e)) 18f0)
             (e-stop e)
             (sfx-at :land x 0.0 z :gain (if big 1.4 0.9) :pitch (if big 0.6 1.0))
             (fx-dust x z (if big 30 12))
             (when big
               (shake (if (eq kind :oxhead) 0.25 0.2) 0.35)
               (fx-ring x 0.0 z 0.4 3.5 0.45 0.8 0.8 0.75 :flat t :width 0.14))
             (play-clip e (if big :land-heavy :land) :blend 2f0))
            (t (setf (brain-mode-t b) (f32 (+ (brain-mode-t b) (* k +step+))))
               (when (>= (brain-mode-t b) (if (eq kind :enra) 0.6 0.3))
                 (setf (brain-touched-down b) nil (brain-mode-t b) 0.0 (brain-mode b) :start)
                 (enemy-to-idle e)
                 (when (entity-alive-p *player*) (face-toward e *player*))))))))

(defun move-event (e mv)
  "Frame S of a move (release / impact / takeoff)."
  (when (and *freeze-on-event* (or (null *freeze-actor*) (eql e *freeze-actor*)))
    (setf *freeze-at* (+ *tick* *freeze-on-event*) *freeze-on-event* nil))
  (case (mv-special mv)
    (:kunai-fan (throw-fan e))
    (:kunai-blast (throw-blast e))
    (:blade-wave (throw-wave e))
    (:slam (slam-fx e))
    (:stomp (stomp-fx e))
    (:charge (play-clip e :ox-run :blend 3f0))
    (:leap (leap-start e))
    (:roar (enra-roar e))
    (:summon (enra-summon e))))

(defun on-move-end (e mv)
  (let ((b (brain e)) (name (mv-name mv)))
    (cond ((eq name :death-grip) (enemy-expire e))
          ((crippled-p e))
          (t (case (brain-kind b)
               (:rainblade
                (setf (brain-mode b) :circle)
                (when (and (member name '(:rb-slash :rb-double :rb-lunge)) (< (rnd01) 0.4))
                  (e-move e :rb-backstep)))
               (:needler
                (setf (brain-mode b) :hold)
                (when (eq name :nd-swipe) (e-backflip e :nd-flip)))
               (:enra (enra-move-end e name)))))))

(defun enemy-expire (e)
  "Crippled enemy dies after its Death Grip: no drops, no kill credit."
  (let* ((p (pos-of e)))
    (die e)
    (detach-parts e #x1FFFFF 0.0 2.5 0.0 :spin 5.0 :spread 1.5)
    (emit :expired (aref p 0) (aref p 2))
    (clog "~a expired after Death Grip" (name-of e))))

;;; ================================================================ crippled: crawl -> Death Grip (§4.4)
(defun crippled-think (e k)
  (let ((dt (* k +step+)) (b (brain e)))
    (case (brain-kind b)
      (:enra (e-stop e) (play-clip e :en-broken :blend 6f0 :restart nil))
      (:oxhead (rampage-think e dt))
      (t (setf (brain-mode-t b) (f32 (+ (brain-mode-t b) dt)))
         (when (alive-p *player*) (e-face-player e dt 2.0))
         (cond ((and (>= (brain-mode-t b) *death-grip-delay*) (alive-p *player*) (not (attacks-paused-p)))
                (enemy-attack e :death-grip)
                (clog "~a DEATH GRIP" (name-of e)))
               ((and (alive-p *player*) (> (distance e *player*) 1.4))
                (multiple-value-bind (dx dz) (to-player e) (e-vel e dx dz 1.2))
                (play-clip e :crawl :blend 8f0 :restart nil))
               (t (e-stop e) (play-clip e :crawl :blend 8f0 :restart nil :speed 0.3)))))))

(defun rampage-think (e dt)
  "Crippled brute: chains red Bull Charges (cooldown 1.0 s) until it dies."
  (let ((b (brain e)))
    (setf (brain-cooldown b) (f32 (- (brain-cooldown b) dt)))
    (e-stop e)
    (play-clip e :idle :blend 8f0 :restart nil)
    (when (alive-p *player*)
      (e-face-player e dt)
      (when (and (<= (brain-cooldown b) 0) (not (attacks-paused-p)))
        (enemy-attack e :ox-charge)
        (setf (brain-cooldown b) 1f0)))))

;;; ================================================================ RAINBLADE (§5.1)
(defun grunt-cooldown () (f32 (* *enemy-cooldown-mult* (rnd-range 1.2 2.0))))

(defun rainblade-think (e k)
  (let* ((dt (* k +step+)) (b (brain e)) (d (distance e *player*)))
    (setf (brain-cooldown b) (f32 (- (brain-cooldown b) dt))
          (brain-free-t b) (f32 (+ (brain-free-t b) dt))
          (brain-mode-t b) (f32 (+ (brain-mode-t b) dt)))
    (when (> (brain-free-t b) 0.6) (setf (brain-flinches b) 0))
    (cond ((>= (brain-flinches b) 6)                     ; Escape: 50 % backflip after 6 flinches
           (setf (brain-flinches b) 0)
           (when (< (rnd01) 0.5)
             (e-backflip e :rb-escape)
             (clog "~a ESCAPE" (name-of e))))
          (t (case (brain-mode b)
               ((:start :approach) (grunt-approach e d))
               (:engage (grunt-engage e d))
               (:feint (grunt-feint e))
               (t (grunt-circle e d dt)))))))

(defun grunt-approach (e d)
  "Run in to the 4.5 m ring around the player."
  (multiple-value-bind (dx dz) (to-player e)
    (e-face-player e +step+)
    (e-vel e dx dz 5.5)
    (play-clip e :run :blend 6f0 :restart nil :speed 0.8)
    (when (<= d 5.0) (set-mode e :circle))))

(defun grunt-circle (e d dt)
  "Strafe on the 3.5-5 m ring facing the player; flip every 1.2-2.5 s; ask for a token when the
cooldown is ready (punish token if the player is recovering close by); 20 % feints otherwise."
  (multiple-value-bind (dx dz) (to-player e)
    (let* ((b (brain e)) (l (max 0.01 d)) (ux (/ dx l)) (uz (/ dz l)) (dir (brain-strafe-dir b))
           (radial (cond ((> d 5.0) 0.9) ((< d 3.5) -0.9) (t 0.0))))
      (e-face-player e dt)
      (e-vel e (+ (* dir (- uz)) (* radial ux)) (+ (* dir ux) (* radial uz)) 2.2)
      (play-clip e :walk :blend 8f0 :restart nil :speed 1.1)
      (setf (brain-flip-t b) (f32 (- (brain-flip-t b) dt)))
      (when (<= (brain-flip-t b) 0) (setf (brain-flip-t b) (f32 (rnd-range 1.2 2.5)) (brain-strafe-dir b) (f32 (- dir))))
      (setf (brain-zone-t b) (if (and (>= d 3.5) (<= d 6.0)) (f32 (+ (brain-zone-t b) dt)) 0f0))
      (cond ((> d 8.0) (set-mode e :approach))
            ((and (<= (brain-cooldown b) 0) (not (attacks-paused-p)))
             (let ((lunge (and (>= d 3.5) (<= d 6.0) (or (> (brain-zone-t b) 2.0) (< (rnd01) 0.2))))
                   (tok (token-request e :melee)))
               (cond ((and tok lunge)
                      (setf (brain-zone-t b) 0.0 (brain-cooldown b) (grunt-cooldown))
                      (enemy-attack e :rb-lunge :mult (if (eq tok :punish) 0.8 1.0)))
                     ((and tok (<= d 2.2)) (grunt-strike e tok))
                     (tok (set-mode e :engage))
                     (t (setf (brain-cooldown b) (f32 (rnd-range 0.3 0.6)))
                        (when (< (rnd01) 0.2) (set-mode e :feint))))))))))

(defun grunt-strike (e tok)
  (setf (brain-cooldown (brain e)) (grunt-cooldown))
  (set-mode e :circle)
  (enemy-attack e (if (< (rnd01) 0.625) :rb-slash :rb-double) :mult (if (eq tok :punish) 0.8 1.0)))

(defun grunt-engage (e d)
  "Holding a token: run in to 2 m (max 1.5 s, else give the token back), then strike."
  (multiple-value-bind (dx dz) (to-player e)
    (let ((b (brain e)))
      (e-face-player e +step+)
      (cond ((<= d 2.0) (grunt-strike e (brain-token b)))
            ((or (> (brain-mode-t b) 1.5) (not (brain-token b)))
             (token-release e) (setf (brain-cooldown b) 0.5f0) (set-mode e :circle))
            (t (e-vel e dx dz 5.5) (play-clip e :run :blend 6f0 :restart nil :speed 0.8))))))

(defun grunt-feint (e)
  "0.3 s lunge in and back with the sword raised: visible pressure, no hitbox."
  (multiple-value-bind (dx dz) (to-player e)
    (let ((tm (brain-mode-t (brain e))))
      (e-face-player e +step+)
      (play-clip e :rb-slash :blend 4f0 :restart nil :speed 0f0 :time 0.28)
      (cond ((< tm 0.15) (e-vel e dx dz 5.0))
            ((< tm 0.3) (e-vel e (- dx) (- dz) 5.0))
            (t (set-mode e :circle))))))

;;; ================================================================ NEEDLER (§5.2)
(defun needler-think (e k)
  (let* ((dt (* k +step+)) (b (brain e)) (d (distance e *player*)))
    (setf (brain-cooldown b) (f32 (- (brain-cooldown b) dt)) (brain-mode-t b) (f32 (+ (brain-mode-t b) dt)))
    (cond ((and (< d 2.5) (<= (brain-cooldown b) 0) (token-request e :melee)) (needler-swipe e))
          (t (case (brain-mode b)
               ((:start :reposition) (needler-reposition e d))
               (:retreat (needler-retreat e d))
               (t (needler-hold e d dt)))))))

(defun needler-swipe (e)
  (setf (brain-cooldown (brain e)) 1.0f0)
  (enemy-attack e :nd-swipe))

(defun needler-spot (e)
  "A point 10 m from the player on the needler's side, biased into the camera view."
  (let* ((p (pos-of e)) (q (pos-of *player*)) (f (camera-forward *camera*))
         (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2))) (l (max 0.01 (hypot dx dz)))
         (cx (aref f 0)) (cz (aref f 2)) (cl (max 0.01 (hypot cx cz)))
         (ux (+ (/ dx l) (* 0.8 (/ cx cl)))) (uz (+ (/ dz l) (* 0.8 (/ cz cl)))) (ul (max 0.01 (hypot ux uz)))
         (lim *arena-inner*))
    (values (f32 (clamp (+ (aref q 0) (* 10 (/ ux ul))) (- lim) lim))
            (f32 (clamp (+ (aref q 2) (* 10 (/ uz ul))) (- lim) lim)))))

(defun needler-reposition (e d)
  (let ((b (brain e)))
    (when (or (eq (brain-mode b) :start) (> (brain-mode-t b) 1.0))
      (multiple-value-bind (x z) (needler-spot e) (setf (brain-goal-x b) x (brain-goal-z b) z))
      (set-mode e :reposition))
    (let* ((p (pos-of e)) (dx (- (brain-goal-x b) (aref p 0))) (dz (- (brain-goal-z b) (aref p 2))))
      (e-face e (brain-goal-x b) (brain-goal-z b) (turn-rate e) +step+)
      (e-vel e dx dz 4.5)
      (play-clip e :run :blend 6f0 :restart nil :speed 0.7)
      (when (or (< (+ (* dx dx) (* dz dz)) 1.0) (and (> d 7.5) (< d 12.0) (> (brain-mode-t b) 0.8)))
        (set-mode e :hold)))))

(defun los-p (e)
  "Clear line from E's chest to the player's chest (props block)."
  (let ((p (pos-of e)) (q (pos-of *player*)))
    (>= (arena-raycast (aref p 0) 1.3 (aref p 2) (aref q 0) 1.3 (aref q 2)) 0.98)))

(defun needler-hold (e d dt)
  "Strafe at 1.5 m/s; retreat if the player closes to < 6 m; throw when token + cooldown allow."
  (multiple-value-bind (dx dz) (to-player e)
    (let* ((b (brain e)) (l (max 0.01 d)) (dir (brain-strafe-dir b)))
      (e-face-player e dt)
      (e-vel e (* dir (- (/ dz l))) (* dir (/ dx l)) 1.5)
      (keep-inside e)
      (play-clip e :walk :blend 8f0 :restart nil :speed 0.8)
      (setf (brain-flip-t b) (f32 (- (brain-flip-t b) dt)))
      (when (<= (brain-flip-t b) 0) (setf (brain-flip-t b) (f32 (rnd-range 1.5 3.0)) (brain-strafe-dir b) (f32 (- dir))))
      (cond ((< d 6.0) (set-mode e :retreat))
            ((> d 14.0) (set-mode e :reposition))
            ((and (<= (brain-cooldown b) 0) (not (attacks-paused-p)) (los-p e) (token-request e :ranged))
             (setf (brain-cooldown b) (f32 (* *enemy-cooldown-mult* (rnd-range 2.3 3.3))))
             (enemy-attack e (if (< (rnd01) 0.3) :nd-blast :nd-fan)))))))

(defun keep-inside (e)
  "Zero the velocity component that would leave the inner box. Returns T if clamped (cornered)."
  (let* ((p (pos-of e)) (v (motion-vel (motion e))) (lim (- *arena-inner* 0.3)) (hit nil))
    (when (or (and (> (aref p 0) lim) (> (aref v 0) 0)) (and (< (aref p 0) (- lim)) (< (aref v 0) 0)))
      (setf (aref v 0) 0f0 hit t))
    (when (or (and (> (aref p 2) lim) (> (aref v 2) 0)) (and (< (aref p 2) (- lim)) (< (aref v 2) 0)))
      (setf (aref v 2) 0f0 hit t))
    hit))

(defun needler-retreat (e d)
  (multiple-value-bind (dx dz) (to-player e)
    (let ((b (brain e)))
      (e-face-player e +step+)
      (e-vel e (- dx) (- dz) 4.5)
      (let* ((cl (keep-inside e)) (v (motion-vel (motion e)))
             (cornered (and cl (< (+ (expt (aref v 0) 2) (expt (aref v 2) 2)) 4.0))))
        (when cornered                                 ; slide along the wall, away from the player
          (let ((tx (* (brain-strafe-dir b) (- dz))) (tz (* (brain-strafe-dir b) dx)))
            (e-vel e tx tz 4.5) (keep-inside e)))
        (play-clip e :run :blend 6f0 :restart nil :speed 0.7)
        (cond ((>= d 9.5) (set-mode e :hold))
              ((and cornered (< d 3.0) (<= (brain-cooldown b) 0) (not (attacks-paused-p))) (needler-swipe e))
              ((> (brain-mode-t b) 2.5) (set-mode e :reposition)))))))

;;; ================================================================ OXHEAD (§5.3)
(defun oxhead-think (e k)
  (let* ((dt (* k +step+)) (b (brain e)) (d (distance e *player*)) (behind (not (facing-p e *player* 70.0))))
    (setf (brain-cooldown b) (f32 (- (brain-cooldown b) dt)))
    (e-face-player e dt)
    (setf (brain-zone-t b) (if (or (< d 2.4) (and behind (< d 3.5))) (f32 (+ (brain-zone-t b) dt)) 0f0))
    (cond ((and (> (brain-zone-t b) 1.0) (not (attacks-paused-p)))   ; Stomp: crowd / flank answer
           (setf (brain-zone-t b) 0.0)
           (enemy-attack e :ox-stomp))
          ((and (<= (brain-cooldown b) 0) (not (attacks-paused-p)) (ox-choose e d)))
          ((> d 2.8)
           (let ((y (yaw-of e)))
             (e-vel e (fwd-x y) (fwd-z y) 2.8)
             (play-clip e :walk :blend 8f0 :restart nil :speed 0.7)
             (setf (brain-step-t b) (f32 (- (brain-step-t b) dt)))
             (when (<= (brain-step-t b) 0)
               (setf (brain-step-t b) 0.55)
               (let ((p (pos-of e))) (sfx-at :footstep (aref p 0) 0.0 (aref p 2) :pitch 0.6 :gain 1.2)))))
          (t (e-stop e) (play-clip e :idle :blend 8f0 :restart nil)))))

(defun ox-choose (e d)
  "Taunt after 2 attacks; Swing/Slam in close, Bull Charge at 5-14 m. T if it acted."
  (let ((b (brain e)))
    (flet ((attack (name tok)
             (setf (brain-attacks b) (1+ (brain-attacks b))
                   (brain-cooldown b) (f32 (* *enemy-cooldown-mult* (rnd-range 2.5 3.5))))
             (enemy-attack e name :mult (if (eq tok :punish) 0.8 1.0))
             t))
      (cond ((>= (brain-attacks b) 2)
             (setf (brain-attacks b) 0 (brain-cooldown b) 1.5f0)
             (e-move e :ox-taunt)
             (let ((p (pos-of e))) (sfx-at :boss-roar (aref p 0) 2.0 (aref p 2) :pitch 1.5 :gain 0.6))
             t)
            ((and (<= d 4.0) (facing-p e *player* 45.0))
             (let ((tok (token-request e :melee)))
               (when tok (attack (if (and (<= d 3.2) (< (rnd01) 0.5)) :ox-swing :ox-slam) tok))))
            ((and (>= d 5.0) (<= d 14.0) (facing-p e *player* 20.0))
             (let ((tok (token-request e :melee)))
               (when tok (attack :ox-charge tok))))
            (t (setf (brain-cooldown b) 0.3f0) nil)))))

(defun charge-step (e)
  (let* ((y (yaw-of e)) (fx (fwd-x y)) (fz (fwd-z y)) (p (pos-of e)) (tp *e-tmp*))
    (e-vel e fx fz 10.0)
    (setf (aref tp 0) (+ (aref p 0) (* 0.4 fx)) (aref tp 1) 0f0 (aref tp 2) (+ (aref p 2) (* 0.4 fz)))
    (when (arena-resolve tp (* 0.8 (body-hurt-r (body-of e))))
      (charge-wall e))))

(defun charge-wall (e)
  "Bull Charge into a wall/prop: slam, big shake, stunned 90 f (punish window)."
  (let ((p (pos-of e)))
    (sfx-at :brute-slam (aref p 0) 1.0 (aref p 2))
    (shake 0.25 0.4)
    (fx-dust (aref p 0) (aref p 2) 20)
    (fx-sparks (aref p 0) 1.6 (aref p 2) 16 1.0 0.88 0.54))
  (enemy-react e :stagger :stun 90)
  (clog "~a charge hit a wall: stunned" (name-of e)))

(defun slam-fx (e)
  (let* ((y (yaw-of e)) (p (pos-of e)) (x (+ (aref p 0) (* 2.0 (fwd-x y)))) (z (+ (aref p 2) (* 2.0 (fwd-z y)))))
    (sfx-at :brute-slam x 0.0 z)
    (shake 0.25 0.4)
    (fx-dust (f32 x) (f32 z) 30)
    (fx-ring x 0.0 z 0.4 3.5 0.4 1.0 0.5 0.3 :flat t :width 0.16)
    (fx-sparks (f32 x) 0.2 (f32 z) 12 1.0 0.5 0.3)
    (add-point-light x 0.5 z 1.0 0.4 0.2 6.0 2.0)))

(defun stomp-fx (e)
  (let* ((p (pos-of e)) (x (aref p 0)) (z (aref p 2)))
    (sfx-at :land x 0.0 z :pitch 0.5 :gain 1.5)
    (shake 0.1 0.2)
    (fx-dust x z 18)
    (fx-ring x 0.0 z 0.3 2.2 0.3 0.8 0.8 0.75 :flat t :width 0.1)
    (when (and (alive-p *player*) (< (distance e *player*) 2.6)
               (or (fighter-landed (fighter e)) (member (state-of *player*) '(:guard :parry))))
      (let ((q (pos-of *player*)))                     ; pushes the player 3 m
        (set-kb *player* (- (aref q 0) x) (- (aref q 2) z) 3.0)))))

;;; ================================================================ ENRA (§5.4)
(defun enra-p2-p (e) (= (brain-boss-phase (brain e)) 2))

(defun enra-think (e k)
  (let* ((dt (* k +step+)) (b (brain e)) (d (distance e *player*)) (p2 (enra-p2-p e)))
    (case (brain-mode b)
      (:start (setf (brain-mode b) :stalk (brain-cooldown b) 1.0f0) (e-move e :en-roar))
      (t
       (e-face-player e dt)
       (setf (brain-cooldown b) (f32 (- (brain-cooldown b) dt))
             (brain-zone-t b) (if (<= d 3.5) (f32 (+ (brain-zone-t b) dt)) 0f0))
       (multiple-value-bind (dx dz) (to-player e)
         (cond ((> d 3.5) (e-vel e dx dz (if p2 4.2 3.5)) (play-clip e :walk :blend 8f0 :restart nil))
               (t (e-stop e) (play-clip e :guard :blend 8f0 :restart nil))))
       (cond ((attacks-paused-p))                          ; never during the player's getup
             ((>= (brain-blocks b) 3)                      ; 3 blocked hits: counter-shove (15 f)
              (setf (brain-blocks b) 0)
              (enemy-attack e :en-shove))
             ((and p2 (not (brain-summoned b)) (<= (health-hp (health e)) (* 0.35 (health-max-hp (health e)))))
              (setf (brain-summoned b) t)
              (e-move e :en-summon))
             ((<= (brain-cooldown b) 0) (enra-choose e d p2)))))))

(defun enra-choose (e d p2)
  (let* ((b (brain e)) (m (enra-attack-choice d p2 (brain-zone-t b) (rnd01))))
    (setf (brain-cooldown b) (f32 (* *enemy-cooldown-mult* (if p2 (rnd-range 0.5 1.0) (rnd-range 0.8 1.4)))))
    (cond ((null m) (setf (brain-cooldown b) 0.3f0))          ; walk in
          ((eq m :en-backstep) (e-move e m))
          (t (enemy-attack e m :mult (if p2 0.85 1.0))
             (when (and p2 (eq m :en-iai)) (setf (brain-iai-again b) t))))))

(defun enra-move-end (e name)
  (let ((b (brain e)))
    (cond ((and (eq name :en-iai) (brain-iai-again b))     ; phase 2: Iai x2, re-aimed, 20 f windup
           (setf (brain-iai-again b) nil)
           (enemy-attack e :en-iai :skip 10.0))
          ((member name '(:en-backstep :en-roar :en-summon)))
          ((< (rnd01) 0.3) (e-move e :en-backstep)))))

(defun enra-post (e)
  "Phase change at 50 % HP (hard clamp, 2 s invulnerable, kneel -> roar)."
  (let* ((b (brain e)) (f (fighter e)) (h (health e))
         (mv (and (eq (fighter-state f) :move) (fighter-move f))))
    (unless (eq (fighter-state f) :spawn)                  ; an interrupted leap / Iai x2 is over
      (unless (and mv (eq (mv-special mv) :leap)) (setf (brain-leaping b) nil))
      (unless (and mv (eq (mv-name mv) :en-iai)) (setf (brain-iai-again b) nil)))
    (when (and (= (brain-boss-phase b) 1) (not (fighter-crippled f)) (<= (health-hp h) (* 0.5 (health-max-hp h))))
      (setf (brain-boss-phase b) 2 (brain-roar-pending b) t
            (health-hp h) (f32 (* 0.5 (health-max-hp h))) (health-invuln h) 120f0 (brain-blocks b) 0
            (motion-grav (motion e)) 1f0)
      (e-move e :en-roar)
      (clog "ENRA PHASE 2"))))

(defun enra-roar (e)
  (let* ((b (brain e)) (p (pos-of e)) (x (aref p 0)) (z (aref p 2)))
    (play-sfx :boss-roar)
    (shake 0.12 1.0)
    (fx-ring x 1.5 z 0.5 6.0 0.6 1.0 0.12 0.24 :flat t :width 0.2)
    (fx-dust x z 30)
    (when (brain-roar-pending b)                           ; the phase-2 roar
      (setf (brain-roar-pending b) nil)
      (when (alive-p *player*)
        (let ((d (distance e *player*)) (q (pos-of *player*)))
          (when (< d 6.0)
            (set-kb *player* (- (aref q 0) x) (- (aref q 2) z) (- 6.0 d))
            (clog "ENRA roar shockwave pushes REN ~,1f m" (- 6.0 d)))))
      (slowmo 0.3 1.0)
      (setf *rain-count* 2250)
      (v3-set! *rain-color* 0.816 0.439 0.502)
      (fx-burst +p-glow+ 30 x 1.5 z 0f0 0.3f0 0f0 1f0 2f0 5f0 0.8f0 0.15f0 1f0 0.12f0 0.24f0)
      (music-intensify))))

(defun enra-summon (e)
  (declare (ignore e))
  (spawn-enemy :rainblade -8.0 -15.0)
  (spawn-enemy :rainblade 8.0 -15.0)
  (clog "ENRA SUMMON"))

(defun leap-start (e)
  "Bloodrain Leap takeoff: arc (0.78 s) to where the player stands now; the ring marks it."
  (let* ((b (brain e)) (mo (motion e)) (p (pos-of e)) (q (pos-of *player*)) (lim 16.5)
         (tx (clamp (aref q 0) (- lim) lim)) (tz (clamp (aref q 2) (- lim) lim))
         (v (motion-vel mo)) (tt 0.78))
    (setf (brain-goal-x b) (f32 tx) (brain-goal-z b) (f32 tz) (brain-leaping b) t
          (aref v 0) (f32 (/ (- tx (aref p 0)) tt)) (aref v 2) (f32 (/ (- tz (aref p 2)) tt))
          (aref v 1) (f32 (* 0.5 40.0 tt)) (motion-grounded mo) nil (motion-grav mo) (f32 (/ 40.0 *enemy-gravity*))
          (motion-grav-t mo) 0f0)
    (face-toward e *player*)
    (sfx-at :jump (aref p 0) 1.0 (aref p 2) :pitch 0.6 :gain 1.3)
    (fx-dust (aref p 0) (aref p 2) 16)))

(defun leap-land (e)
  (let* ((f (fighter e)) (p (pos-of e)) (x (aref p 0)) (z (aref p 2)) (mv (fighter-move f)))
    (setf (brain-leaping (brain e)) nil)
    (e-stop e)
    (setf (svref (fighter-hit-log f) 11) nil)
    (hitdef-scan e *hd-leap* 11)
    (sfx-at :land x 0.0 z :pitch 0.6 :gain 1.5) (sfx-at :hit-heavy x 0.0 z)
    (shake 0.2 0.35)
    (fx-dust x z 30)
    (fx-ring x 0.0 z 0.4 3.2 0.35 1.0 0.3 0.3 :flat t :width 0.15)
    (setf (fighter-sf f) (f32 (+ (mv-s mv) (mv-a mv))) (anim-time (model-anim (model e))) 1.7f0)))

(defun boss-break (e)
  "Called by ENEMY-TAKE-HIT when the boss hits 0 HP: kneels BROKEN, drops the sword; only
Obliterate finishes him (the prompt shows because he counts as crippled)."
  (let ((f (fighter e)) (h (health e)))
    (token-release e)
    (setf (health-hp h) 1f0 (fighter-crippled f) t (brain-block-chance (brain e)) 0f0 (health-invuln h) 0f0
          (fighter-state f) :crippled (fighter-sf f) 0f0 (fighter-move f) nil (motion-grav (motion e)) 1f0))
  (e-stop e)
  (detach-parts e (joint-mask :weapon-r) 0.5 2.0 0.5 :spin 4.0 :spread 0.3)
  (play-clip e :en-broken :blend 6f0)
  (emit :broken)
  (clog "ENRA BROKEN"))

;;; ================================================================ drawing
(defun draw-red-ring (x z r a)
  "Red ground marker for AoE red attacks (§4.5)."
  (fx-decal x 0.0 z r 1.0 0.08 0.06 (* 0.45 a) :mode :add)
  (let ((n 28) (x (float x)) (z (float z)) (r (float r)))
    (dotimes (i n)
      (let ((a0 (* i (/ 6.2832 n))) (a1 (* (1+ i) (/ 6.2832 n))))
        (fx-line (+ x (* r (sin a0))) 0.06 (+ z (* r (cos a0))) (+ x (* r (sin a1))) 0.06 (+ z (* r (cos a1)))
                 0.09 1.0 0.15 0.1 a)))))

(defun draw-telegraph (e mv pulse)
  (let* ((p (pos-of e)) (y (yaw-of e)) (x (aref p 0)) (z (aref p 2)))
    (case (mv-name mv)
      (:ox-slam (draw-red-ring (+ x (* 2.0 (fwd-x y))) (+ z (* 2.0 (fwd-z y))) 3.5 pulse))
      (:en-crescent (draw-red-ring x z 4.0 pulse))
      (:en-leap (let ((q (pos-of *player*))) (draw-red-ring (aref q 0) (aref q 2) 3.0 pulse)))
      (:ox-charge (fx-line x 0.06 z (+ x (* 12.0 (fwd-x y))) 0.06 (+ z (* 12.0 (fwd-z y)))
                           0.9 1.0 0.1 0.08 (* 0.25 pulse) :end-alpha 0.0)))))

(declaim (type f32vec *eye-p* *enra-p2-rim*))
(defvar *eye-p* (make-f32 3))
(defvar *enra-p2-rim* (rim-vec #xFF1E3C 0.35))

(defun draw-eye-glow (e kind)
  "Additive eye glow (blooms): enemies read as eyes in the dark from any distance."
  (unless (logbitp (ji :head) (model-hidden (model e)))
    (multiple-value-bind (lz ly r g b sz)
        (case kind
          (:rainblade (values -0.14 0.14 1.0 0.19 0.19 0.07))
          (:needler (values -0.125 0.13 0.1 0.9 1.0 0.07))
          (:oxhead (values -0.15 0.13 1.0 0.2 0.12 0.1))
          (t (values -0.125 0.14 1.0 0.69 0.18 0.1)))
      (let ((q (joint-point! *eye-p* (model-joints (model e)) (ji :head) 0f0 (f32 ly) (f32 lz))))
        (fx-billboard (aref q 0) (aref q 1) (aref q 2) sz r g b 0.9)))))

(defun draw-enemy (e)
  "Enemy with hit flash, red telegraph (8 Hz pulse #FF1A1A + glint + ground ring), boss aura."
  (let* ((f (fighter e)) (b (brain e)) (mv (fighter-move f)) (red (red-windup-p e)) (kind (kind-of e))
         (moving (and mv (eq (fighter-state f) :move)))
         (pulse (+ 0.5 (* 0.5 (sin (* 50.265 (elapsed-time))))))
         (p2 (and (eq kind :enra) b (enra-p2-p e)))
         (tint nil) (em 0.0))
    (when red
      (v3-set! *red-tint* (f32 (+ 1.2 (* 0.8 pulse))) 0.25 0.22)
      (setf tint *red-tint* em (* 0.5 pulse)))
    (draw-fighter e :tint tint :emissive em :rim (and p2 *enra-p2-rim*)
                    :hide-role (case kind
                                 (:enra (if p2 nil :p2))
                                 (:oxhead (if (and moving (mv-red mv) (< (fighter-sf f) (+ (mv-s mv) 10))) nil :red))))
    (when (and moving (>= (fighter-sf f) (- (mv-s mv) 9)) (< (fighter-sf f) (mv-s mv)))
      (blade-points! e *hitp* *trail-tip*)                ; glint on the weapon before the strike
      (let ((tp *trail-tip*))
        (fx-billboard (aref tp 0) (aref tp 1) (aref tp 2) (if red 0.35 0.22)
                      1.0 (if red 0.2 1.0) (if red 0.15 1.0) 0.9)))
    (when red (draw-telegraph e mv pulse))
    (draw-eye-glow e kind)
    (when (and moving (eq (mv-special mv) :leap) b (brain-leaping b))
      (draw-red-ring (brain-goal-x b) (brain-goal-z b) 3.0 (+ 0.6 (* 0.4 pulse))))
    (when (and p2 (not (fighter-crippled f)))              ; phase-2 red aura
      (let ((p (pos-of e)))
        (dotimes (i 2)
          (fx-emit +p-glow+ (+ (aref p 0) (rnd-range -0.6f0 0.6f0)) (+ (aref p 1) (rnd-range 0.3f0 2.4f0))
                   (+ (aref p 2) (rnd-range -0.6f0 0.6f0)) 0f0 (rnd-range 0.5f0 1.5f0) 0f0
                   0.6f0 (rnd-range 0.05f0 0.12f0) 0f0 1f0 0.12f0 0.2f0))))))
