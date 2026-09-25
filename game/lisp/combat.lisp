;;;; combat.lisp — what every fighter shares (GAME_DESIGN §0, §3.2–3.4, §4): running a move and
;;;; scanning its hit volumes, applying a hit to an enemy, enemy hit reactions, body physics, the
;;;; generic enemy step, SEPARATION-SYSTEM, soft-lock targeting and the aggression tokens
;;;; (TOKEN-SYSTEM). The decisions are rules.lisp's (VOL-HIT-P, ENEMY-HIT-OUTCOME, TOKEN-DECISION);
;;;; this file gathers their inputs from the components and applies the results. The effects are
;;;; reported as events for FEEDBACK-SYSTEM. REN's side of a hit is PLAYER-TAKE-HIT (player.lisp).
(in-package :raven)

;;; ---------------------------------------------------------------- move runner (player + enemies)
(defun start-move (e name &key blend)
  "Enter move NAME (a DEFMOVE keyword or a MOVE). Frame 0 is this call; MOVE-TICK advances it."
  (let ((mv (if (move-p name) name (find-move name))) (f (fighter e)) (tr (blade-trail e)))
    (setf (fighter-state f) :move (fighter-move f) mv (fighter-sf f) 0f0 (fighter-phase f) 0 (fighter-landed f) nil
          (blade-trail-heavy tr) (mv-hw mv) (blade-trail-on tr) 0f0)
    (fill (fighter-hit-log f) nil)
    (play-clip e (mv-clip mv) :blend (or blend (mv-blend mv)) :speed (mv-clip-speed mv))
    (when (mv-red mv)
      (play-sfx :warn)
      (clog "~a red windup ~a" (fighter-name f) (mv-name mv)))
    (clog "~a move ~a" (fighter-name f) (mv-name mv))
    mv))

(defun move-tick (e k)
  "Advance E's current move by K frames: slide, sounds, trail window, hit scan.
Returns T when the move's total duration is over."
  (let* ((f (fighter e)) (mv (fighter-move f)) (f0 (fighter-sf f)) (f1 (+ f0 k)))
    (setf (fighter-sf f) f1)
    (let ((sl (mv-slide mv)))
      (when sl
        (destructuring-bind (from to dist) sl
          (when (and (>= f0 from) (< f0 to))
            (let* ((step (* (/ dist (- to from)) k)) (yaw (yaw-of e)) (p (pos-of e)))
              (setf (aref p 0) (+ (aref p 0) (* step (fwd-x yaw))) (aref p 2) (+ (aref p 2) (* step (fwd-z yaw)))))))))
    (loop for h across (mv-hits mv)
          when (and (< f0 (hd-from h)) (>= f1 (hd-from h)) (mv-sfx mv))
            do (play-sfx (if (hd-hw h) :slash-heavy (mv-sfx mv)) :pitch (mv-pitch mv)
                         :gain (if (member :quiet (hd-flags h)) 0.6 1.0)))
    (setf (blade-trail-on (blade-trail e)) (if (and (>= f1 (mv-trail-from mv)) (< f1 (mv-trail-to mv))) 1f0 0f0))
    (move-hit-scan e)
    (>= f1 (+ (mv-s mv) (mv-a mv) (mv-r mv)))))

(defun hitdef-scan (a h i &optional (extra 0f0))
  "Test hitdef H (hit-log slot I) of attacker A against every opponent now (VOL-HIT-P, rules.lisp),
ignoring H's frame window. Each target is hit at most once per slot until START-MOVE clears the log."
  (let* ((fa (fighter a)) (log (fighter-hit-log fa)) (team (fighter-team fa))
         (p (pos-of a)) (yaw (yaw-of a)) (fx (fwd-x yaw)) (fz (fwd-z yaw)))
    (do-entities (o (fo fighter) (ho health) (to transform) (mo model))
      (when (and (not (eq (fighter-team fo) team)) (health-alive ho)
                 (not (member o (svref log i)))
                 (< (aref (transform-pos to) 1) (hd-feet h))
                 (let* ((q (transform-pos to)) (ob (model-body mo))
                        (tr (f32 (+ (body-hurt-r ob) (if (and (eql o *player*) (just-dodge-window-p)) *just-dodge-reach* 0.0)))))
                   (loop for v in (hd-vols h)
                         thereis (if (> (aref v 0) 2.5)
                                     (let* ((tg (fighter-target fa))
                                            (c (pos-of (if (entity-alive-p tg) tg o))))
                                       (vol-hit-p v (aref c 0) (aref c 1) (aref c 2) 0f0 0f0
                                                  (aref q 0) (aref q 1) (aref q 2) tr (body-hurt-h ob) 0f0))
                                     (vol-hit-p v (aref p 0) (aref p 1) (aref p 2) fx fz (aref q 0) (aref q 1) (aref q 2)
                                                tr (body-hurt-h ob) extra)))))
        (push o (svref log i))
        (resolve-hit a o h)))))

(defun move-hit-scan (e)
  "Scan every hit window of E's move that is open at the current frame."
  (let* ((f (fighter e)) (mv (fighter-move f)) (sf (fighter-sf f))
         (extra (if (and (eql e *player*) (mv-ravenable mv) (raven-form-p)) 0.9f0 0f0)))
    (loop for h across (mv-hits mv) for i from 0
          when (and (>= sf (hd-from h)) (< sf (hd-to h)))
            do (hitdef-scan e h i extra))))

(defun resolve-hit (att tgt hd)
  "Apply hit HD from ATT to TGT. Returns :hit :killed :crippled :armored :blocked :guard-break
:parried :dodged or NIL (ignored)."
  (let ((res (if (eq (fighter-team (fighter tgt)) :player) (player-take-hit att hd) (enemy-take-hit att tgt hd))))
    (when (member res '(:hit :killed :crippled :armored))
      (setf (fighter-landed (fighter att)) t))
    res))

;;; ---------------------------------------------------------------- feedback helpers
(declaim (type f32vec *hitp* *trail-tip*))
(defvar *hitp* (make-f32 3))
(defvar *trail-tip* (make-f32 3))

(defun-fast hit-point! (att tgt)
  "Contact point: target chest, pulled toward the attacker by the hurt radius."
  (let* ((p (pos-of att)) (q (pos-of tgt)) (out *hitp*) (b (body-of tgt))
         (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2))) (d (f-max 0.01f0 (f-sqrt (+ (* dx dx) (* dz dz)))))
         (r (body-hurt-r b)))
    (declare (type f32vec p q out) (single-float dx dz d r))
    (setf (aref out 0) (+ (aref q 0) (* r (/ dx d)))
          (aref out 1) (+ (aref q 1) (* 0.62f0 (body-hurt-h b)))
          (aref out 2) (+ (aref q 2) (* r (/ dz d))))
    out))

;;; Combat reports what happened as events (EMIT, engine/lisp/ecs.lisp); FEEDBACK-SYSTEM (feedback.lisp)
;;; turns them into blood, sparks, sounds, shake, hitstop and slow-mo at the end of the step.
;;; Positions are taken now, where the hit happened.
(defun emit-hit (att tgt heavy hitstop ender)
  "Report that ATT's hit landed on enemy TGT."
  (let ((p (hit-point! att tgt)) (yaw (yaw-of att)))
    (emit :hit att tgt (aref p 0) (aref p 1) (aref p 2) (fwd-x yaw) (fwd-z yaw) heavy hitstop ender)))

(defun emit-block (att tgt &optional (gain 1.0))
  "Report that TGT blocked ATT's hit (GAIN: louder for a guard break)."
  (let ((p (hit-point! att tgt)))
    (emit :blocked (aref p 0) (aref p 1) (aref p 2) gain)))

;;; ---------------------------------------------------------------- enemy reactions
(defun set-kb (e dx dz dist)
  "Push E by DIST metres along (dx dz) over 6 frames."
  (let* ((l (max 0.001 (sqrt (+ (* dx dx) (* dz dz))))) (k (/ (f32 dist) 6.0)) (mo (motion e)) (kb (motion-kb mo)))
    (setf (aref kb 0) (f32 (* k (/ dx l))) (aref kb 2) (f32 (* k (/ dz l))) (motion-kb-left mo) 6f0)))

(defun enemy-react (e kind &key (stun 0.0) (vy 0.0))
  "Put enemy E into reaction KIND (§4.1). STUN overrides the duration in frames."
  (token-release e)
  (let* ((f (fighter e)) (mo (motion e)) (v (motion-vel mo)) (stun (f32 stun))
         (kind (reaction-for kind (not (motion-grounded mo)) (downed-p e))))
    (setf (fighter-sf f) 0f0 (fighter-phase f) 0 (fighter-move f) nil (aref v 0) 0f0 (aref v 2) 0f0)
    (ecase kind
      (:flinch (setf (fighter-state f) :flinch (fighter-stun f) (if (> stun 0) stun 18f0))
       (incf (brain-flinches (brain e)))
       (play-clip e :hurt-flinch :blend 2f0 :speed (/ 0.25 (/ (fighter-stun f) 60.0))))
      (:stagger (setf (fighter-state f) :stagger (fighter-stun f) (if (> stun 0) stun 42f0))
       (play-clip e :hurt-stagger :blend 2f0 :speed (/ 0.5 (/ (fighter-stun f) 60.0))))
      (:knockdown (setf (fighter-state f) :knockdown (motion-grounded mo) nil)
       (setf (aref v 1) 3.5f0 (motion-grav mo) 1f0)
       (play-clip e :kd-air :blend 2f0))
      (:launch (setf (fighter-state f) :launched (motion-grounded mo) nil (motion-grav mo) 1f0 (brain-flinches (brain e)) 0)
       (setf (aref v 1) (f32 vy))
       (play-clip e :launched :blend 2f0))
      (:air-flinch (setf (fighter-state f) :launched (motion-grounded mo) nil (motion-grav mo) 0.3f0 (motion-grav-t mo) 21f0)
       (setf (aref v 1) 2f0)
       (play-clip e :air-flinch :blend 1f0))
      (:crumple (setf (fighter-state f) :crumple (fighter-stun f) 60f0)
       (play-clip e :crumple :blend 2f0))
      (:guard-hit (setf (fighter-state f) :guard-hit (fighter-stun f) 8f0)
       (play-clip e :block-hit :blend 1f0))
      (:guard-break (setf (fighter-state f) :guard-break (fighter-stun f) (if (> stun 0) stun 48f0))
       (play-clip e :guard-break :blend 2f0 :speed (/ 1.0 (/ (fighter-stun f) 60.0)))))
    (clog "~a react ~a" (fighter-name f) kind)))

(defun die (e)
  "Mark fighter E dead: it stops acting and drawing; the corpse timer starts (ENEMY-TICK removes it)."
  (let ((f (fighter e)) (h (health e)))
    (token-release e)
    (setf (health-alive h) nil (health-hp h) 0f0 (fighter-state f) :dead (fighter-sf f) 0f0
          (fighter-corpse-t f) (f32 (if (dummy e) *dummy-respawn* *corpse-time*))
          (fighter-crippled f) nil (fighter-grabbed f) nil)))

(defun enemy-kill (e att &key obliterate)
  "Kill enemy E: its parts fly (or the upper body is bisected); gauge +3 for REN. The mist,
orbs and sound are the :KILLED event's."
  (let* ((p (pos-of e)) (x (aref p 0)) (y (+ (aref p 1) 1.1)) (z (aref p 2)) (q (pos-of att))
         (dx (- x (aref q 0))) (dz (- z (aref q 2)))
         (l (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (ux (/ dx l)) (uz (/ dz l)))
    (die e)
    (setf (trail-count (blade-trail-points (blade-trail e))) 0f0)   ; no ribbon left behind
    (if obliterate
        (let ((upper (body-upper-mask (body-of e))))
          (detach-parts e upper (* 2.5 ux) 5.0 (* 2.5 uz) :spin 7.0 :spread 1.2)
          (detach-parts e (logandc2 #x1FFFFF upper) (* 0.6 ux) 0.5 (* 0.6 uz) :spin 2.0 :spread 0.4))
        (detach-parts e #x1FFFFF (* 2.0 ux) 3.0 (* 2.0 uz) :spin 6.3 :spread 2.0))
    (emit :killed (eql att *player*) (and obliterate t) x y z ux uz)
    (when (eql att *player*) (raven-gain 3 :kill))
    (clog "~a KILLED~:[~; (obliterated)~]" (name-of e) obliterate)))

(defun enemy-cripple (e att)
  "Weapon arm flies off (a mist burst: the :CRIPPLED event); crumple 60 f, then crippled (§4.4)."
  (let* ((p (pos-of e)) (q (pos-of att)) (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2)))
         (l (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))))
    (setf (fighter-crippled (fighter e)) t)
    (detach-parts e (body-arm-mask (body-of e)) (* 3 (/ dx l)) 3.5 (* 3 (/ dz l)) :spin 9.0 :spread 1.0)
    (let ((jp (joint-point! (make-f32 3) (model-joints (model e)) (ji :shoulder-r) 0f0 0f0 0f0)))
      (emit :crippled (aref jp 0) (aref jp 1) (aref jp 2) (/ dx l) (/ dz l)))
    (enemy-react e :crumple)
    (clog "~a CRIPPLED hp ~,1f" (name-of e) (health-hp (health e)))))

(defun enemy-try-block (att tgt hd raven)
  "Grunt block rule: a light hit from the front 120 deg on an idle enemy with BLOCK-CHANCE,
rolled once per player string. Returns T when the enemy blocks."
  (let ((b (brain tgt)))
    (when (and (> (brain-block-chance b) 0) (eql att *player*) (not raven) (not (hd-hw hd))
               (member (state-of tgt) '(:idle :guard :guard-hit)) (facing-p tgt att 60.0))
      (let ((sid (player-string-id (player *player*))))
        (unless (= (brain-block-string b) sid)
          (setf (brain-block-string b) sid
                (brain-blocked-roll b) (< (rnd01) (brain-block-chance b)))))
      (brain-blocked-roll b))))

(defun enemy-take-hit (att tgt hd)
  "Hit HD from ATT reaches enemy TGT: the rule (ENEMY-HIT-OUTCOME, rules.lisp) decides; this applies
it (HP, poise, reaction, cripple / kill / BROKEN) and shows it. Returns the result keyword (the
BROKEN boss counts as :hit)."
  (let* ((h (health tgt)) (ft (fighter tgt)) (b (body-of tgt)) (kind (kind-of tgt))
         (pl (eql att *player*)) (raven (and pl (raven-form-p))) (mv (fighter-move (fighter att)))
         (crippled (fighter-crippled ft)) (red (red-windup-p tgt)))
    (when (or (not (health-alive h)) (> (health-invuln h) 0) (eq (fighter-state ft) :dead))
      (return-from enemy-take-hit nil))
    (let* ((out (enemy-hit-outcome
                 hd :raven raven :ravenable (and mv (mv-ravenable mv)) :boss (eq kind :enra)
                    :crippled crippled
                    :guarding (and (not crippled) (not (member :unblockable (hd-flags hd)))
                                   (or (and (eq (fighter-state ft) :guard) (facing-p tgt att 60.0))
                                       (enemy-try-block att tgt hd raven)))
                    :downed (downed-p tgt) :red-windup red
                    :windup-frac (if red (/ (fighter-sf ft) (max 1 (mv-s (fighter-move ft)))) 0.0)
                    :poise (health-poise h) :body-poise (body-poise b) :hp (health-hp h) :max-hp (health-max-hp h)
                    :cripple-frac (body-cripple-frac b) :no-cripple (body-no-cripple b)))
           (result (eh-result out)) (name (fighter-name ft)))
      (case result
        ((nil) nil)
        (:guard-break
         (emit-block att tgt 2.0)
         (enemy-react tgt :guard-break :stun (eh-stun out))
         (clog "~a GUARD BREAK" name)
         :guard-break)
        (:blocked
         (emit-block att tgt)
         (incf (brain-blocks (brain tgt)))
         (enemy-react tgt :guard-hit)
         (clog "~a blocked" name)
         :blocked)
        (t
         (cond (crippled                                  ; finishing a crippled enemy
                (setf (health-hp h) 0f0))
               (t
                (when (eh-raven-break out)
                  (let ((q (pos-of tgt))) (emit :raven-break (aref q 0) (aref q 2)))
                  (clog "~a RAVEN BREAK" name))
                (setf (health-poise h) (f32 (eh-poise out)) (health-hp h) (f32 (eh-hp out)) (health-bar-t h) 3f0)
                (when (eh-poise-hit out) (setf (health-poise-t h) 0f0))
                (clog "hit ~a -> ~a dmg ~,1f hp ~,1f~:[~; HW~]~:[~; armored~]" (name-of att) name (eh-damage out)
                      (health-hp h) (eh-heavy out) (eq result :armored))))
         (emit-hit att tgt (eh-fx-heavy out) (eh-hitstop out) (eh-ender out))
         (ecase result
           (:broken (boss-break tgt))
           (:killed (enemy-kill tgt att :obliterate (member :obliterate (hd-flags hd))))
           (:crippled (enemy-cripple tgt att))
           (:armored (when (eq kind :oxhead)                ; super armor reads as metal
                       (let ((p (hit-point! att tgt))) (emit :sfx :clang (aref p 0) (aref p 1) (aref p 2) 0.6))))
           (:hit (let* ((p (pos-of att)) (q (pos-of tgt)))
                   (enemy-react tgt (eh-react out) :stun (eh-stun out) :vy (hd-vy hd))
                   (set-kb tgt (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)) (hd-kb hd)))))
         (when pl (player-landed-hit (eh-heavy out)))
         (if (eq result :broken) :hit result))))))

;;; ---------------------------------------------------------------- physics & reaction ticks
(defun-fast physics-step (e k grav)
  "Knockback, velocity, gravity (GRAV m/s^2 x the body's multiplier), ground, arena walls.
K = frames this step (time scale)."
  (declare (single-float k grav))
  (let* ((mo (motion e)) (p (pos-of e)) (v (motion-vel mo)) (kb (motion-kb mo)) (dt (* k +step+))
         (kl (motion-kb-left mo)))
    (declare (type f32vec p v kb) (single-float dt kl))
    (when (> kl 0f0)
      (let* ((s (f-min k kl)))
        (declare (single-float s))
        (setf (aref p 0) (+ (aref p 0) (* s (aref kb 0))) (aref p 2) (+ (aref p 2) (* s (aref kb 2)))
              (motion-kb-left mo) (- kl s))))
    (setf (aref p 0) (+ (aref p 0) (* dt (aref v 0))) (aref p 2) (+ (aref p 2) (* dt (aref v 2))))
    (unless (motion-grounded mo)
      (let* ((gm (motion-grav mo)) (gt (motion-grav-t mo)))
        (declare (single-float gm gt))
        (when (> gt 0f0)
          (setf gt (- gt k) (motion-grav-t mo) gt)
          (when (<= gt 0f0) (setf (motion-grav mo) 1f0)))
        (setf (aref v 1) (f-max -25f0 (- (aref v 1) (* grav gm dt)))
              (aref p 1) (+ (aref p 1) (* dt (aref v 1)))
              (motion-air-t mo) (+ (the single-float (motion-air-t mo)) dt))))
    (let* ((gh (the single-float (arena-ground-height (aref p 0) (aref p 2)))))
      (declare (single-float gh))
      (cond ((and (not (motion-grounded mo)) (<= (aref p 1) gh) (<= (aref v 1) 0f0))
             (setf (aref p 1) gh (aref v 1) 0f0 (motion-grounded mo) t (motion-grav mo) 1f0 (motion-grav-t mo) 0f0))
            ((motion-grounded mo) (setf (aref p 1) gh (motion-air-t mo) 0f0))))
    (arena-resolve p (body-hurt-r (body-of e)))
    nil))

(defun enemy-react-tick (e k)
  "Advance a reaction state of enemy E. Returns T while E is in a reaction (the AI waits)."
  (let* ((f (fighter e)) (st (fighter-state f)))
    (case st
      ((:flinch :stagger :guard-hit :guard-break)
       (setf (fighter-sf f) (+ (fighter-sf f) k))
       (when (>= (fighter-sf f) (fighter-stun f)) (enemy-to-idle e))
       t)
      (:knockdown
       (setf (fighter-sf f) (+ (fighter-sf f) k))
       (case (fighter-phase f)
         (0 (when (and (motion-grounded (motion e)) (>= (fighter-sf f) 6))
              (setf (fighter-phase f) 1 (fighter-sf f) 0f0) (play-clip e :kd-down :blend 3f0) (fx-dust-at e 10)))
         (1 (when (>= (fighter-sf f) 54) (setf (fighter-phase f) 2 (fighter-sf f) 0f0 (health-invuln (health e)) 18f0)
              (play-clip e :kd-getup :blend 3f0 :speed (/ 0.4 0.5))))
         (t (when (>= (fighter-sf f) 30) (enemy-to-idle e))))
       t)
      (:launched
       (setf (fighter-sf f) (+ (fighter-sf f) k))
       (when (and (motion-grounded (motion e)) (> (fighter-sf f) 2))
         (setf (fighter-state f) :knockdown (fighter-phase f) 1 (fighter-sf f) 18f0)   ; 0.6 s down
         (play-clip e :kd-down :blend 3f0) (fx-dust-at e 12))
       (let ((gt (motion-grav-t (motion e))))
         (when (and (eq (fighter-state f) :launched) (> gt 0) (<= (- gt k) 0))
           (play-clip e :launched :blend 4f0)))
       t)
      (:crumple
       (setf (fighter-sf f) (+ (fighter-sf f) k))
       (when (>= (fighter-sf f) (fighter-stun f))
         (setf (fighter-state f) :crippled (fighter-sf f) 0f0) (play-clip e :crippled :blend 6f0 :restart nil))
       t)
      ((:grabbed :dead) t)
      (t nil))))

(defun fx-dust-at (e n) (let ((p (pos-of e))) (fx-dust (aref p 0) (aref p 2) n)))

(defun enemy-to-idle (e)
  (let ((f (fighter e)))
    (setf (fighter-state f) :idle (fighter-sf f) 0f0 (fighter-phase f) 0 (fighter-move f) nil))
  (play-clip e :idle :blend 6f0))

(defun-fast trail-step (e)
  "Record a blade sample while the trail window is open, else shrink the ribbon."
  (let* ((bt (blade-trail e)) (tr (blade-trail-points bt)))
    (declare (type f32vec tr))
    (if (> (the single-float (blade-trail-on bt)) 0f0)
        (let* ((b *hitp*) (tp *trail-tip*))
          (declare (type f32vec b tp))
          (blade-points! e b tp)
          (trail-push tr (aref b 0) (aref b 1) (aref b 2) (aref tp 0) (aref tp 1) (aref tp 2)))
        (trail-decay tr))))

;;; ---------------------------------------------------------------- generic enemy step
(defun enemy-step (e k think)
  "One fixed step of a living enemy E (K = enemy time scale): timers, poise regen (full 1.5 s
after the last hit), current move (token released at its end), hit reactions, physics,
animation, FK and trail. THINK (fn e k) runs only when E is free (not in a move/reaction):
that is the AI. Dead enemies are the caller's business (removal / respawn)."
  (let ((h (health e)))
    (when (> (health-invuln h) 0) (setf (health-invuln h) (f32 (max 0.0 (- (health-invuln h) k)))))
    (setf (health-poise-t h) (+ (health-poise-t h) k))
    (when (> (health-poise-t h) 90) (setf (health-poise h) (body-poise (body-of e))))
    (case (state-of e)
      (:move (when (move-tick e k) (token-release e) (enemy-to-idle e)))
      (t (unless (enemy-react-tick e k) (funcall think e k))))
    (when (health-alive h)
      (unless (eq (state-of e) :grabbed) (physics-step e k *enemy-gravity*))
      (anim-advance (model-anim (model e)) (* k +step+))
      (pose-update e)
      (trail-step e))))

;;; ---------------------------------------------------------------- separation (§4.8)
(defvar *sep* (make-array +max-entities+ :initial-element nil) "Scratch: the fighters to separate.")

(defun separation-system ()
  "Push overlapping hurt cylinders apart: the player pushes enemies at 50 %, enemies push the player at 30 %."
  (let ((n 0) (v *sep*))
    (declare (fixnum n) (simple-vector v))
    (do-entities (e fighter) (setf (svref v n) e) (incf n))
    (dotimes (i n)
      (let ((a (svref v i)))
        (loop for j from (1+ i) below n do
          (let ((b (svref v j)))
            (when (and (alive-p a) (alive-p b) (not (fighter-grabbed (fighter a))) (not (fighter-grabbed (fighter b))))
              (let* ((p (pos-of a)) (q (pos-of b))
                     (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
                     (d (sqrt (+ (* dx dx) (* dz dz))))
                     (rr (+ (body-hurt-r (body-of a)) (body-hurt-r (body-of b))))
                     (ov (- rr d)))
                (when (and (> ov 0) (< (abs (- (aref p 1) (aref q 1))) 1.5))
                  (when (< d 1e-3) (setf dx 1.0 dz 0.0 d 1.0))
                  (let* ((nx (/ dx d)) (nz (/ dz d))
                         (ka (if (eql a *player*) 0.3 0.5)) (kb (if (eql b *player*) 0.3 0.5)))
                    (decf (aref p 0) (f32 (* ov ka nx))) (decf (aref p 2) (f32 (* ov ka nz)))
                    (incf (aref q 0) (f32 (* ov kb nx))) (incf (aref q 2) (f32 (* ov kb nz)))
                    (arena-resolve p (body-hurt-r (body-of a)))
                    (arena-resolve q (body-hurt-r (body-of b)))))))))))
    (fill v nil :end n)))

;;; ---------------------------------------------------------------- soft-lock (§3.4)
(defun pick-target (a dx dz has-input &key range half pred)
  "Best opponent for A's attack: within RANGE and HALF-angle (deg) of direction (dx dz) — defaults
7 m / 60 deg, or 4.5 m / 90 deg without input. Score = distance + 0.05 x angle(deg)."
  (let* ((range (or range (if has-input *softlock-range* 4.5)))
         (half (or half (if has-input *softlock-angle* 90.0)))
         (team (fighter-team (fighter a)))
         (p (pos-of a)) (dl (max 1e-4 (sqrt (+ (* dx dx) (* dz dz))))) (best nil) (bs 1e9))
    (do-entities (e (f fighter) (h health))
      (when (and (not (eq (fighter-team f) team)) (health-alive h) (not (eq (fighter-state f) :spawn))
                 (or (null pred) (funcall pred e)))
        (let* ((q (pos-of e)) (ex (- (aref q 0) (aref p 0))) (ez (- (aref q 2) (aref p 2)))
               (d (sqrt (+ (* ex ex) (* ez ez))))
               (ang (if (< d 0.01) 0.0 (/ (* 180 (acos (clamp (/ (+ (* ex dx) (* ez dz)) (* d dl)) -1.0 1.0))) pi)))
               (score (+ d (* 0.05 ang))))
          (when (and (<= d range) (<= ang half) (< score bs)) (setf best e bs score)))))
    best))

;;; ---------------------------------------------------------------- aggression tokens (§4.6)
;;; Enemy AI: (token-request e :melee) before starting a windup; T / :PUNISH when granted
;;; (:punish = the free 3rd token: use windup x0.8). Release with (token-release e) at recovery
;;; end. Reactions and death release automatically.
(defvar *token-delay* 0.0 "Seconds until a token can be issued again (0.25 s after a return).")
(defvar *punish-cd* 0.0)

(defun token-count (kind)
  (let ((n 0))
    (do-entities (e (b brain) (h health))
      (when (and (health-alive h) (eq (brain-token b) kind)) (incf n)))
    n))

(defun token-request (e kind)
  "Ask for an aggression token. KIND :melee or :ranged. Returns T, :PUNISH or NIL."
  (let ((b (brain e)))
    (ecase (token-decision kind :held (brain-token b) :delay *token-delay* :paused (attacks-paused-p)
                                :melee (token-count :melee) :punish (token-count :punish) :ranged (token-count :ranged)
                                :melee-max *melee-tokens* :ranged-max *ranged-tokens* :punish-cd *punish-cd*
                                :punishable (player-punishable-p) :dist (distance e *player*))
      (:keep t)
      ((nil) nil)
      (:melee (setf (brain-token b) :melee) (clog "~a token melee" (name-of e)) t)
      (:ranged (setf (brain-token b) :ranged) t)
      (:punish (setf (brain-token b) :punish *punish-cd* 1.5) (clog "~a token PUNISH" (name-of e)) :punish))))

(defun token-release (e)
  (let ((b (brain e)))
    (when (and b (brain-token b))
      (setf (brain-token b) nil *token-delay* 0.25))))

(defun token-system (dt)
  "Count down the token timers (enemy time)."
  (setf *token-delay* (max 0.0 (- *token-delay* dt)) *punish-cd* (max 0.0 (- *punish-cd* dt))))
