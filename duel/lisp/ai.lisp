;;;; ai.lisp — BRAIN-SYSTEM: the CPU player (design-v1 §8, critique-design §5). Generic code: a
;;;; character's identity is the :AI table of its kit form (intents, ranges, weighted moves per
;;;; distance band, guard / Hoho chances, reactions). The CPU plays by writing its fighter's vpad
;;;; exactly like a keyboard (VPAD-SET!, VPAD-STICK!), once per fixed step, and draws every random
;;;; number from SIM-RND01: a seed replays the same match.
;;;;   perception  the opponent as he was DELAY steps ago (a ring buffer of SNAPs; EASY 24,
;;;;               NORMAL 14, HARD 8) — reaction time is the difficulty. What happens to the CPU
;;;;               itself (its own hit, its own blockstun) it feels at once.
;;;;   reflexes    first: Kikon / finish the string / SP cancel on hit; punish a blocked ender; follow
;;;;               up a stunned opponent (Guard Break); punish a recovering one; answer an incoming
;;;;               Breaker; the kit's reactions (Kenpachi's stance); Breaker a long guard; guard or
;;;;               Hoho a committed move; awaken
;;;;   intents     APPROACH / PRESSURE / ZONE / DEFEND re-picked every *AI-REPICK* f: a preferred range
;;;;               to walk to, then a weighted move for the distance band
;;;;   heat        +*AI-HEAT-RATE*/s without dealing damage (x2 far apart): the preferred range
;;;;               shrinks, the Breaker weight doubles at 8 — this is what makes matches end
(in-package :duel)

(defstruct snap
  "What the CPU sees of its opponent at one step."
  (x 0f0 :type single-float) (z 0f0 :type single-float)
  (state :idle) (kind nil) (phase nil)
  (sf 0 :type fixnum) (s 0 :type fixnum) (active-end 0 :type fixnum)
  (left 0 :type fixnum)                 ; frames left of his move (99 = still charging / dashing) or stun
  (start 0 :type fixnum)                ; tick his current move / guard began (one roll per event)
  (reach 0f0 :type single-float) (guard-t 0 :type fixnum) (projectile nil))

(defun snap-take! (s o)
  "Fill SNAP S with fighter O as he is now."
  (let* ((f (fighter o)) (p (pos-of o)) (mv (fighter-move f)) (st (fighter-state f)))
    (setf (snap-x s) (aref p 0) (snap-z s) (aref p 2) (snap-state s) st (snap-sf s) (fighter-sf f)
          (snap-guard-t s) (fighter-guard-t f) (snap-projectile s) (incoming-projectile-p o))
    (if (and (eq st :move) mv)
        (let ((total (move-end-frame (mv-s mv) (mv-a mv) (mv-r mv) (mv-whiff mv) (fighter-contact f)
                                     (zerop (length (mv-hits mv))))))
          (setf (snap-kind s) (mv-kind mv) (snap-phase s) (fighter-phase f) (snap-s s) (mv-s mv)
                (snap-active-end s) (+ (mv-s mv) (mv-a mv)) (snap-reach s) (f32 (mv-reach mv))
                (snap-left s) (if (eq (fighter-phase f) :main) (max 0 (- total (fighter-sf f))) 99)
                (snap-start s) (- *match-tick* (fighter-sf f) (fighter-hold f))))
        (setf (snap-kind s) nil (snap-phase s) nil (snap-reach s) 0f0
              (snap-left s) (if (eq st :stun) (max 0 (- (fighter-stun f) (fighter-sf f))) 0)
              (snap-start s) (if (eq st :guard) (- *match-tick* (fighter-guard-t f)) -1)))
    s))

(defun incoming-projectile-p (o)
  "Is one of O's projectiles flying at his opponent within *AI-PROJECTILE-RANGE*?"
  (let ((v (fighter-opp (fighter o))) (hit nil))
    (when (entity-alive-p v)
      (let ((q (pos-of v)) (r2 (* *ai-projectile-range* *ai-projectile-range*)))
        (do-entities (h (hz hazard))
          (when (and (eql (hazard-owner hz) o) (member (hazard-kind hz) '(:wave :fireball)) (> (hazard-hits-left hz) 0)
                     (< (+ (expt (- (hazard-x hz) (aref q 0)) 2) (expt (- (hazard-z hz) (aref q 2)) 2)) r2))
            (setf hit t)))))
    hit))

;;; ---------------------------------------------------------------- pressing buttons
(defun ai-press (b button frames &key modded (act button))
  "Hold BUTTON (with :MOD when MODDED) for FRAMES steps, starting now."
  (setf (brain-press b) button (brain-press-mod b) modded (brain-press-left b) (max 1 frames) (brain-act b) act))

(defun ai-command (b kit cmd d)
  "Press the buttons of kit command CMD at distance D (holding charge / stance / Breaker moves a
while: a charge move is held to its full charge from beyond 7 m, where it has the time)."
  (let ((r (sim-rnd01)))
    (flet ((hold-for (mv lo spread) (if (mv-hold mv) (+ lo (floor (* r spread))) 1)))
      (case cmd
        (:q (ai-press b :quick 1))
        (:f (ai-press b :flash 1))
        (:sig (ai-press b :sig (hold-for (kit-command-move kit :sig) 12 40)))
        ((:sp1 :sp1-full)                                 ; :sp1-full: a charge move held to its end
         (let ((mv (kit-command-move kit :sp1)))
           (ai-press b :flash (if (and (mv-hold mv) (or (eq cmd :sp1-full) (> d 7.0))) (+ 2 (second (mv-hold mv)))
                                  (hold-for mv 14 46))
                     :modded t :act :sp1)))
        (:sp2 (ai-press b :sig (if (< r 0.4) 20 1) :modded t :act :sp2))
        (:breaker (ai-press b :breaker (+ 12 (floor (* r 30)))))
        (:step (ai-press b :step 1))
        (:side-step (ai-press b :step 1 :act :side-step))  ; BRAIN-STEP holds the stick sideways
        (:hoho (ai-press b :step 1 :modded t :act :hoho))
        (:guard (ai-press b :guard (+ 10 (floor (* r 20)))))
        (:kikon (ai-press b :kikon 1))
        (:awaken (ai-press b :awaken 1))))))

;;; ---------------------------------------------------------------- decisions
(defun ai-table (e key &optional default) (getf (kit-ai (kit-of e)) key default))

(defun why (b reason cmd) "Note REASON (debug) and return CMD." (setf (brain-why b) reason) cmd)

(defun string-reflex (e b f mv)
  "Our move hit: go on with the string (F branch *AI-STRING-FLASH-P* of the time), else cancel into
SP2 when the victim is on the ground (a launched victim would drop out of it) and the kit's
:sp-cancel-bars are there."
  (let* ((kit (fighter-kit f)) (nq (kit-next kit (mv-name mv) :q)) (nf (kit-next kit (mv-name mv) :f))
         (bars (floor (gauges-reiatsu (gauges e)) *reiatsu-bar*)))
    (setf (brain-why b) :string)
    (cond ((and nf (< (sim-rnd01) *ai-string-flash-p*)) :f)
          (nq :q)
          (nf :f)
          ((and (>= bars (ai-table e :sp-cancel-bars 1)) (kit-command-ok-p e :sp2)
                (>= (fighter-sf f) (fighter-land-sf f)) (not (eq (state-of (opp-of e)) :air)))
           :sp2))))

(defun ai-reflex (e b s d)
  "The reflexes (checked before the intent): a command keyword or NIL. S = the perceived opponent,
D = the perceived distance."
  (let* ((f (fighter e)) (g (gauges e)) (kit (fighter-kit f)) (st (fighter-state f)) (mv (fighter-move f))
         (bars (floor (gauges-reiatsu g) *reiatsu-bar*)) (free (member st '(:idle :guard)))
         (q (kit-command-move kit :q)) (new-event (/= (snap-start s) (brain-roll-key b))))
    (when new-event                                       ; one roll per opponent action
      (setf (brain-roll-key b) (snap-start s) (brain-guard-roll b) (sim-rnd01) (brain-hoho-roll b) (sim-rnd01)
            (brain-react-roll b) (sim-rnd01)))
    (cond
      ;; our own hit: Kikon, else finish the string, else an SP cancel
      ((kikon-ok-p e) (why b :kikon :kikon))
      ((and (eq st :move) (eq (fighter-contact f) :hit) (member (mv-kind mv) '(:quick :flash)))
       (string-reflex e b f mv))
      ((eq st :move) nil)
      ((not free) nil)
      ((and (gauges-evolution g) (>= (/ (gauges-reishi g) (float (gauges-reishi-max g))) (ai-table e :awaken-above 0.0)))
       :awaken)
      ;; we just blocked an ender (-12 ...): it's our turn, felt at once (no perception delay)
      ((and (eq (brain-was b) :guard-hit) (<= (fighter-block-adv f) *ai-punish-adv*)
            (< (fighter-dist f) (+ (mv-reach q) 0.4))
            (< (sim-rnd01) (getf *ai-block-punish-p* (brain-difficulty b) 0.5)))
       (why b :block-punish :q))
      ;; a stunned opponent (Guard Break, broken stance, our knockback) still stunned when Q1 lands
      ((and (eq (snap-state s) :stun) (>= (- (snap-left s) (brain-delay b)) (mv-s q)) (< d (+ (mv-reach q) 0.6)))
       (why b :follow-up :q))
      ;; the opponent is launched / down (untouchable for a while): the kit's :oki command
      ;; (Yamamoto: a full-charge Shiranui, which also fills Inferno -> Hellfire, whose burn he
      ;; only risks above :oki-above of his Reishi)
      ((and (member (snap-state s) '(:air :down)) (eq (ai-table e :oki) :sp1-full) (mv-hold (kit-command-move kit :sp1))
            (kit-command-ok-p e :sp1) (> d 3.0)
            (>= (/ (gauges-reishi g) (float (gauges-reishi-max g))) (ai-table e :oki-above 0.0)))
       (why b :oki (ai-table e :oki)))
      ;; a recovering opponent in reach: punish
      ((and (eq (snap-state s) :move) (eq (snap-phase s) :main) (>= (snap-sf s) (snap-active-end s))
            (>= (- (snap-left s) (brain-delay b)) (mv-s q)) (< d (+ (mv-reach q) 0.4)))
       (why b :punish :q))
      ;; an incoming Breaker: Hoho through its dash (a bar), Q1 it while it has the room, else Step
      ;; sideways (a Hoho in the aura only reappears in front of the dash)
      ((and (eq (snap-kind s) :breaker) (member (snap-phase s) '(:aura :dash)) (< d *ai-anti-breaker-range*)
            (< (brain-react-roll b) (getf *ai-anti-breaker-p* (brain-difficulty b) 0.5)))
       (why b :anti-breaker
            (cond ((and (eq (snap-phase s) :dash) (>= bars 1) (zerop (fighter-hoho-lock f))
                        (< (brain-hoho-roll b) (ai-table e :hoho 0.2)))
                   :hoho)
                  ((> d *ai-anti-breaker-q*) :q)
                  (t :side-step))))
      ;; the kit's reactions: stance vs a projectile / a Flash startup it can still beat (stance-in
      ;; must end before the Flash hits, after our perception delay)
      ((let ((r (ai-table e :react)))
         (and r (< (brain-react-roll b) *ai-react-p*)
              (or (and (snap-projectile s) (getf r :projectile))
                  (and (eq (snap-kind s) :flash) (< d 4.0) (getf r :flash-startup)
                       (>= (- (snap-s s) (snap-sf s) (brain-delay b)) (+ *stance-in* 2))))))
       (let ((r (ai-table e :react)))
         (why b :react (if (snap-projectile s) (getf r :projectile) (getf r :flash-startup)))))
      ;; a long guard up close: Breaker it
      ((and (eq (snap-state s) :guard) (>= (snap-guard-t s) *ai-guard-break-hold*) (< d *ai-guard-break-range*)
            (/= (brain-break-key b) (snap-start s)))
       (setf (brain-break-key b) (snap-start s))
       (and (< (sim-rnd01) *ai-guard-break-p*) (why b :guard-break :breaker)))
      ;; a committed move coming: Hoho it (1 bar) or guard it
      ((and (eq (snap-state s) :move) (member (snap-kind s) '(:quick :flash :sig :sp :breaker))
            (< (snap-sf s) (snap-active-end s)) (< d (+ (snap-reach s) *ai-threat-margin*)))
       (cond ((and (>= bars 1) (zerop (fighter-hoho-lock f)) (>= (- (snap-s s) (snap-sf s)) 6)
                   (< (brain-hoho-roll b) (ai-table e :hoho 0.2)))
              (why b :hoho :hoho))
             ((< (brain-guard-roll b) (+ (ai-table e :guard 0.3) (if (eq (brain-intent b) :defend) 0.25 0.0)))
              :guard))))))

(defun ai-neutral (e b d)
  "No reflex fired: walk to the intent's range, and now and then pick a move for the distance."
  (let* ((kit (kit-of e)) (vp (pilot-vpad (pilot e))) (heat (brain-heat b)))
    (when (<= (decf (brain-intent-t b)) 0)
      (setf (brain-intent-t b) *ai-repick*)
      (let ((w (ai-table e :intents)) (hot (min 3.0 (/ heat 4.0))))
        (setf (brain-intent b)
              (or (weighted-pick (sim-rnd01) :approach (getf w :approach 1) :pressure (+ (getf w :pressure 1) hot)
                                 :zone (getf w :zone 1) :defend (getf w :defend 1))
                  :approach))))
    (when (<= (decf (brain-strafe-t b)) 0)
      (setf (brain-strafe-t b) (+ (first *ai-strafe-time*) (floor (* (second *ai-strafe-time*) (sim-rnd01))))
            (brain-strafe b) (if (< (sim-rnd01) 0.5) -1f0 1f0)))
    (destructuring-bind (lo hi) (getf (ai-table e :ranges) (brain-intent b) '(2.0 4.0))
      (multiple-value-bind (lo hi) (heat-range lo hi heat)
        (vpad-stick! vp (if (<= lo d hi) (brain-strafe b) (* 0.3 (brain-strafe b)))
                     (cond ((> d hi) 1f0) ((< d lo) -1f0) (t 0f0)))))
    (when (<= (decf (brain-decide-t b)) 0)
      (setf (brain-decide-t b) (+ (getf *ai-think* (brain-difficulty b) 24) (floor (* 40 (sim-rnd01)))))
      (cond ((and (< d 3.4) (< (sim-rnd01) (min 0.9 (+ (ai-table e :guard 0.3) (if (eq (brain-intent b) :defend) 0.2 0.0)))))
             (ai-press b :guard (+ (first *ai-guard-hold*) (floor (* (second *ai-guard-hold*) (sim-rnd01))))))
            ((< (sim-rnd01) (min 0.9 (+ (getf *ai-aggression* (brain-intent b) 0.3) (* 0.04 heat))))
             (let* ((weights (copy-list (band-weights (ai-table e :moves) d))))
               (when (getf weights :breaker) (setf (getf weights :breaker) (* (getf weights :breaker) (heat-breaker-mult heat))))
               (let ((cmd (apply #'weighted-pick (sim-rnd01) weights)))
                 (when (and cmd (or (not (member cmd *kit-commands*)) (kit-command-ok-p e cmd))
                            (or (not (member cmd '(:q :f)))                  ; don't whiff a string at range
                                (<= d (+ 0.2 (mv-reach (kit-command-move kit cmd))))))
                   (ai-command b kit cmd d) (setf (brain-why b) :neutral)))))))))

(defun brain-step (e b)
  "One step of the CPU: perceive, then hold / reflex / neutral, written to the vpad."
  (let* ((f (fighter e)) (vp (pilot-vpad (pilot e))) (o (fighter-opp f)) (ring (brain-ring b)) (n (length ring)))
    (vpad-begin-step! vp)
    (let ((cur (or (svref ring (brain-head b)) (setf (svref ring (brain-head b)) (make-snap)))))
      (snap-take! cur o))
    (let* ((s (or (svref ring (mod (- (brain-head b) (brain-delay b)) n)) (svref ring (brain-head b))))
           (p (pos-of e)) (d (sqrt (+ (expt (- (snap-x s) (aref p 0)) 2) (expt (- (snap-z s) (aref p 2)) 2)))))
      (setf (brain-head b) (mod (1+ (brain-head b)) n)
            (brain-heat b) (f32 (heat-after (brain-heat b) (> d *ai-heat-far*))))
      (vpad-stick! vp 0f0 0f0)
      (when (member (fighter-state f) '(:stun :air :down :wakeup :guard-hit))   ; just took it: respect
        (setf (brain-intent b) :defend (brain-intent-t b) *ai-respect*))
      (unless (or (brain-off b) (> (fighter-lock f) 0) (eq (fighter-state f) :cine))
        (if (and (> (brain-press-left b) 0) (not (eq (brain-press b) :guard)))   ; a reflex may drop a guard
            (decf (brain-press-left b))
            (let ((cmd (ai-reflex e b s d)))
              (cond ((and cmd (not (and (eq cmd :guard) (eq (brain-press b) :guard) (> (brain-press-left b) 0))))
                     (ai-command b (kit-of e) cmd d))
                    ((> (brain-press-left b) 0) (decf (brain-press-left b)))
                    ((eq (fighter-state f) :idle) (ai-neutral e b d))))))
      (setf (brain-was b) (fighter-state f))
      ;; the buttons of this step
      (loop for a across *vpad-actions*
            do (vpad-set! vp a (or (and (> (brain-press-left b) 0) (eq a (brain-press b)))
                                   (and (eq a :mod) (> (brain-press-left b) 0) (brain-press-mod b)))))
      (when (> (brain-press-left b) 0)
        (case (brain-act b)
          (:guard (vpad-stick! vp 0f0 0f0))
          (:side-step (vpad-stick! vp (brain-strafe b) 0f0)))))))

(defun brain-system ()
  "Every CPU fighter decides this step (before FIGHTER-SYSTEM reads the vpads)."
  (do-entities (e (b brain) (f fighter)) (brain-step e b)))

(defun pilot-system ()
  "Every human fighter's vpad reads its devices this step (inside the step: determinism)."
  (do-entities (e (pl pilot) (f fighter))
    (unless (brain e) (vpad-begin-step! (pilot-vpad pl)))))
