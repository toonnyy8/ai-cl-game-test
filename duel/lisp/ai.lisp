;;;; ai.lisp — BRAIN-SYSTEM: the CPU player (design-v1 §8, critique-design §5). Generic code: a
;;;; character's identity is the :AI table of its kit form (intents, ranges, weighted moves per
;;;; distance band, guard / Hoho chances, reactions). The CPU plays by writing its fighter's vpad
;;;; exactly like a keyboard (VPAD-SET!, VPAD-STICK!), once per fixed step, and draws every random
;;;; number from SIM-RND01: a seed replays the same match.
;;;;   perception  the opponent as he was DELAY steps ago (a ring buffer of SNAPs; EASY 24,
;;;;               NORMAL 14, HARD 8) — reaction time is the difficulty. What happens to the CPU
;;;;               itself (its own hit, its own blockstun) it feels at once.
;;;;   reflexes    first: the O ender off a completed string (red always, else the kit's :o-ender) / the next
;;;;               link / an SP cancel on hit; the rush on a red opponent in hitstun; punish a blocked ender; follow up a
;;;;               stunned opponent (Guard Break); punish a recovering one; answer an incoming Breaker
;;;;               or Kikon rush (guard it unless red); the kit's reactions (Kenpachi's stance);
;;;;               Breaker a long guard; guard or Hoho a committed move; awaken
;;;;   kikon       the rush on a red opponent (the O ender, on his hitstun, or at a neutral decision
;;;;               within the kit's :kikon-range), the button held through the strike: always the Kikon;
;;;;               on one who isn't red as the O ender (:o-ender) or a poke (the kit's :moves), which a hit
;;;;               turns into the follow-up. As the victim of a follow-up it guards it (*AI-FOLLOW-GUARD-P*)
;;;;   intents     APPROACH / PRESSURE / ZONE / DEFEND re-picked every *AI-REPICK* f: a preferred range
;;;;               to walk to, then a weighted move for the distance band
;;;;   heat        +*AI-HEAT-RATE*/s without dealing damage (x2 far apart): the preferred range
;;;;               shrinks, the Breaker weight doubles at 8 — this is what makes matches end
;;;;   gauges      guards less as its guard gauge runs low (steps aside instead), never guardless;
;;;;               presses a guardless opponent; keeps a Burst's flash-step when a Burst would be worth it
;;;;   cold        Rukia's kit keys: :cool (hold U to the next band), :brace (hold U at absolute zero)
;;;;   stances     kit keys: :cancel (end a landed string with L), :l-after-k (L after a K link that hit, p), :low (L more often at low Reishi),
;;;;               :gg-low (below it: back off and zone), :block-string (go on with a string the opponent
;;;;               blocks: guard pressure), :sig-gg (L halved below it of the guard gauge: KYOKKO pierces with a
;;;;               full edge), :ward-reversal (Bankai West: L when the ward just took a hit up close); a parry is
;;;;               never attacked into; South's tell is stepped out of (the trap reflex); an opponent in a ward
;;;;               (Bankai West) is seen as guarding (SNAP-TAKE!): the Breaker reflex breaks it
;;;;   J beats K   out of a blocked link, J1 into the string's next K link while it has the frames (J-BEATS-K-P)
;;;;   burst       combo'd past its 2nd hit for its perception delay, *FS-BURST* flash-step, and worth it
;;;;               (AI-BURST-WANTED-P): one roll per combo (*AI-BURST-P* by difficulty)
;;;;   dash        far outside its range: hold Step toward it (the kit's :dash chance), or away from a
;;;;               too-close opponent (:dash-back), released once the range is reached
(in-package :duel)

(defstruct snap
  "What the CPU sees of its opponent at one step."
  (x 0f0 :type single-float) (z 0f0 :type single-float)
  (state :idle) (kind nil) (phase nil)
  (sf 0 :type fixnum) (s 0 :type fixnum) (active-end 0 :type fixnum)
  (left 0 :type fixnum)                 ; frames left of his move (99 = still charging / dashing) or stun
  (start 0 :type fixnum)                ; tick his current move / guard began (one roll per event)
  (reach 0f0 :type single-float) (guard-t 0 :type fixnum) (projectile nil)
  (flags nil)                           ; his move's :flags (:parry :bind ...)
  (tell nil))                           ; a :bind move's tell frames (its :params :tell; NIL = South's 21-30)

(defun snap-take! (s o)
  "Fill SNAP S with fighter O as he is now."
  (let* ((f (fighter o)) (p (pos-of o)) (mv (fighter-move f))
         (st (let ((st (fighter-state f)))                ; Bankai West's ward is a held guard (its time in West)
               (if (and (passive-p o :ward) (member st '(:idle :run))) :guard st))))
    (setf (snap-x s) (aref p 0) (snap-z s) (aref p 2) (snap-state s) st (snap-sf s) (fighter-sf f)
          (snap-guard-t s) (fighter-guard-t f) (snap-projectile s) (incoming-projectile-p o))
    (if (and (eq st :move) mv)
        (let ((total (move-end-frame (mv-s mv) (mv-a mv) (mv-r mv) (mv-whiff mv) (fighter-contact f)
                                     (zerop (length (mv-hits mv))))))
          (setf (snap-kind s) (mv-kind mv) (snap-phase s) (fighter-phase f) (snap-s s) (mv-s mv) (snap-flags s) (mv-flags mv)
                (snap-tell s) (getf (mv-params mv) :tell)
                (snap-active-end s) (+ (mv-s mv) (mv-a mv)) (snap-reach s) (f32 (mv-reach mv))
                (snap-left s) (if (eq (fighter-phase f) :main) (max 0 (- total (fighter-sf f))) 99)
                (snap-start s) (- *match-tick* (fighter-sf f) (fighter-hold f))))
        (setf (snap-kind s) nil (snap-phase s) nil (snap-reach s) 0f0 (snap-flags s) nil
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

(defun ai-dash (b dir to)
  "Hold Step (the hop, then the run) with the stick toward (DIR 1) or away from (-1) the opponent,
until the distance passes TO (BRAIN-STEP lets go)."
  (ai-press b :step *ai-dash-frames* :act :dash)
  (setf (brain-dash b) (f32 dir) (brain-dash-to b) (f32 to)))

(defun ai-burst-roll (e b)
  "Burst Reverse now? No sooner than the perception delay after the combo's 2nd hit (BRAIN-BURST-T),
allowed (BURST-OK-P) and worth it (AI-BURST-WANTED-P, the next hit estimated as the combo's average
so far): one roll per combo at the difficulty's *AI-BURST-P*."
  (let ((f (fighter e)) (g (gauges e)))
    (when (and (not (brain-burst-rolled b)) (>= (brain-burst-t b) (brain-delay b)) (burst-ok-p e)
               (ai-burst-wanted-p (gauges-reishi g) (gauges-reishi-max g)
                                  (floor (fighter-combo-dmg f) (max 1 (fighter-combo-hits f)))))
      (setf (brain-burst-rolled b) t)
      (< (sim-rnd01) (getf *ai-burst-p* (brain-difficulty b) 0.4)))))

(defun ai-command (b kit cmd d)
  "Press the buttons of kit command CMD at distance D (holding charge / stance / Breaker moves a
while: a charge move is held to its full charge from beyond 7 m, where it has the time)."
  (let ((r (sim-rnd01))
        (cmd (if (and (kit-rooted kit) (member cmd '(:hoho :side-step :step))) :q cmd)))   ; rooted (Rukia's zero / THAW)
    (flet ((hold-for (mv lo spread) (if (and mv (mv-hold mv)) (+ lo (floor (* r spread))) 1)))   ; (NIL: a form without it)
      (case cmd
        (:q (ai-press b :quick 1))
        (:f (ai-press b :flash 1))
        (:sig (ai-press b :sig (hold-for (kit-command-move kit :sig) 12 40)))
        ((:sp1 :sp1-full)                                 ; :sp1-full: a charge move held to its end
         (let ((mv (kit-command-move kit :sp1)))
           (ai-press b :flash (if (and mv (mv-hold mv) (or (eq cmd :sp1-full) (> d 7.0))) (+ 2 (second (mv-hold mv)))
                                  (hold-for mv 14 46))
                     :modded t :act :sp1)))
        (:sp2 (ai-press b :sig (if (< r 0.4) 20 1) :modded t :act :sp2))
        (:breaker (ai-press b :breaker (+ 12 (floor (* r 30)))))
        (:step (ai-press b :step 1))
        (:side-step (ai-press b :step 1 :act :side-step))  ; BRAIN-STEP holds the stick sideways
        (:hoho (ai-press b :step 1 :modded t :act :hoho))
        (:guard (ai-press b :guard (+ 10 (floor (* r 20)))))
        (:guard-long (ai-press b :guard 40 :act :guard))    ; through a stagger and the dash-in after it
        (:kikon (let ((mv (kit-command-move kit :kikon)))                ; held through the strike (aura + dash + S)
                  (ai-press b :kikon (+ (rush-param mv :aura) (rush-param mv :dash-max) (mv-s mv) 4))))
        (:awaken (ai-press b :awaken 1))))))

;;; ---------------------------------------------------------------- decisions
(defun ai-table (e key &optional default) (getf (kit-ai (kit-of e)) key default))

(defun why (b reason cmd) "Note REASON (debug) and return CMD." (setf (brain-why b) reason) cmd)

(defun ai-gg (e) "E's guard gauge as a fraction." (/ (gauges-gg (gauges e)) *gg-max*))

(defun ai-gg-low-p (e)
  "Below the kit's :gg-low of its guard gauge: back off, zone while it refills."
  (let ((k (ai-table e :gg-low))) (and k (< (ai-gg e) k))))

(defun guarding-p (e)
  "E holds a guard: :guard / :guard-hit, or Bankai West's ward."
  (or (member (state-of e) '(:guard :guard-hit)) (passive-p e :ward)))

(defun ai-cancel-p (e kit)
  "End a landed string with the kit's :cancel command (L, a :cancel Signature) now? Its chance, and it may start."
  (let* ((c (ai-table e :cancel)) (p (getf c :sig)) (mv (kit-command-move kit :sig)))
    (and p mv (member :cancel (mv-flags mv)) (kit-command-ok-p e :sig) (< (sim-rnd01) p))))

(defun string-reflex (e b f mv)
  "Our link hit: go on with the string (the next link K *AI-STRING-FLASH-P* of the time, among the links KIT-NEXT
allows: after a switch only one; pressed once, the latch does the rest), or end it with L (the kit's :cancel), else
cancel into SP2 when the victim is on the ground (a launched victim would drop out of it) and the kit's
:sp-cancel-bars are there, *AI-SP-CANCEL-P* of the time (link 3 staggers / crumples: SP2 always combos off it)."
  (let* ((kit (fighter-kit f))
         (nq (kit-next kit (mv-name mv) :q))
         (nf (kit-next kit (mv-name mv) :f))
         (bars (floor (gauges-reiatsu (gauges e)) *reiatsu-bar*)))
    (setf (brain-why b) :string)
    (when (and nf (kit-pip-cmd-p kit :f) (< (gauges-meter (gauges e)) 1f0)) (setf nf nil))   ; no pip: no K link
    (cond ((fighter-queued f) nil)                      ; the next link is latched already
          ((let ((p (ai-table e :l-after-k 0.0)))       ; L after a K link (the kit's :l-after-k): one roll per hit
             (and (plusp p) (= (fighter-sf f) (fighter-land-sf f)) (kit-l-link kit (mv-name mv)) (kit-command-ok-p e :sig kit nil t)
                  (< (sim-rnd01) p)))
           (why b :l-after-k :sig))
          ((and nf (< (sim-rnd01) (ai-table e :string-k *ai-string-flash-p*))) :f)
          (nq :q)
          (nf :f)
          ((and (>= (fighter-sf f) (fighter-land-sf f)) (ai-cancel-p e kit)) (why b :cancel :sig))
          ((and (>= bars (ai-table e :sp-cancel-bars 1)) (kit-command-ok-p e :sp2)
                (= (fighter-sf f) (fighter-land-sf f)) (not (eq (state-of (opp-of e)) :air))
                (< (sim-rnd01) *ai-sp-cancel-p*))              ; one roll, on the first step we see the hit
           :sp2))))

(defvar *ai-bankai-mode* (vector nil nil)
  "Per side, the CPU's Bankai entry: NIL = the kit's :bankai rule (AI-BANKAI-P), :SURE = the rule with its chance 1,
:ALWAYS = whenever allowed, :NEVER (debug 31000 + 10 a + b: the gamble A/B, docs/DUEL_KEN_BANKAI.md).")

(defun ai-bankai-p (e b bk)
  "Enter the Bankai now (the kit's :bankai (:p :opp-below :opp-konpaku :own-konpaku); BANKAI-ALLOWED-P holds: he has
<= *BANKAI-KONPAKU* left, no longer red, the user's decision 2026-09-28)? One roll per cup-3 stay. The entry leaves him 1 Konpaku, so he weighs his own: nothing to lose when he has no more than the
opponent's next Soul Break would take (its count + 1, capped); else only as a finisher (the opponent at <= :opp-below of
his Reishi or <= :opp-konpaku Konpaku) with <= :own-konpaku left."
  (case (svref *ai-bankai-mode* (fighter-side (fighter e)))
    (:always t)
    (:never nil)
    (t (unless (brain-bankai-rolled b)
         (let* ((o (opp-of e)) (go (gauges o)) (k (gauges-konpaku (gauges e)))
                (threat (min *soul-break-max-event* (+ (kit-kikon-konpaku (kit-of o)) *soul-break-extra*))))
           (when (or (<= k threat)
                     (and (<= k (getf bk :own-konpaku 9))
                          (or (<= (gauges-reishi go) (* (getf bk :opp-below 0.0) (gauges-reishi-max go)))
                              (<= (gauges-konpaku go) (getf bk :opp-konpaku 0)))))
             (setf (brain-bankai-rolled b) t)
             (< (sim-rnd01) (if (eq (svref *ai-bankai-mode* (fighter-side (fighter e))) :sure) 1.0 (getf bk :p 0.0)))))))))

(defvar *ai-awaken-mode* (vector nil nil)
  "Per side, the CPU's awakening on EVOLUTION: NIL = the kit's :awaken rule (AI-AWAKEN-P), :ALWAYS, :NEVER (debug 39000 + 10 a
+ b: Rukia's awaken A/B, docs/DUEL_RUKIA.md §9).")

(defun ai-awaken-p (e)
  "Awaken now (EVOLUTION)? The debug mode, else the kit's :awaken (:melee-share :min-taken): only once E has taken
>= :min-taken damage, >= :melee-share of it from blades (Rukia: her cold body answers a melee opponent); no key: yes."
  (case (svref *ai-awaken-mode* (fighter-side (fighter e)))
    (:always t)
    (:never nil)
    (t (let ((r (ai-table e :awaken)) (g (gauges e)))
         (or (null r)
             (let* ((m (gauges-taken-melee g)) (all (+ m (gauges-taken-ranged g))))
               (and (>= all (getf r :min-taken 0)) (>= m (* (getf r :melee-share 0.0) all)))))))))

(defun ai-cool-p (e s d)
  "The kit's :cool (:p :near :no-projectile :min-gg): at a neutral decision within :near m (no projectile of his out, with
:no-projectile; the guard gauge at least :min-gg %: the crack comes from crushes), hold U to cool to the next band
(Rukia's cold gauge), :p of the time."
  (let ((c (ai-table e :cool)))
    (and c (< d (getf c :near 3.0)) (not (and (getf c :no-projectile) (snap-projectile s)))
         (>= (gauges-gg (gauges e)) (getf c :min-gg 0)) (< (sim-rnd01) (getf c :p 0.0)))))

(defun ai-brace-p (e d)
  "The kit's :brace (:p :near :min-gg): at absolute zero, hold U (bracing stops the warming, drains the guard gauge) while
he is within :near m and the guard gauge is at least :min-gg %, :p of the decisions."
  (let ((c (ai-table e :brace)))
    (and c (< d (getf c :near 5.5)) (>= (gauges-gg (gauges e)) (getf c :min-gg 0)) (< (sim-rnd01) (getf c :p 1.0)))))

(defun ai-reflex (e b s d)
  "The reflexes (checked before the intent): a command keyword or NIL. S = the perceived opponent,
D = the perceived distance."
  (let* ((f (fighter e)) (g (gauges e)) (kit (fighter-kit f)) (st (fighter-state f)) (mv (fighter-move f))
         (free (member st '(:idle :guard :run)))
         (red (red-p (gauges-reishi g) (gauges-reishi-max g)))
         (hoho-ok (and (zerop (fighter-hoho-lock f)) (>= (gauges-fs g) *fs-hoho*)))      ; flash-step for one
         (guard-k (ai-guard-mult (gauges-gg g) (gauges-guardless g)))                  ; the guard gauge left
         (q (kit-command-move kit :q)) (new-event (/= (snap-start s) (brain-roll-key b))))
    (when new-event                                       ; one roll per opponent action
      (setf (brain-roll-key b) (snap-start s) (brain-guard-roll b) (sim-rnd01) (brain-hoho-roll b) (sim-rnd01)
            (brain-react-roll b) (sim-rnd01)))
    (cond
      ;; our completed string (a link-3 hit): the O ender, on a red opponent always, else the kit's :o-ender chance;
      ;; one roll, on the first step we see the hit (its land frame)
      ((and (eq st :move) (eq (fighter-contact f) :hit) (member :ender (mv-flags mv))
            (= (fighter-sf f) (fighter-land-sf f)) (kit-command-ok-p e :kikon kit t)
            (or (kikon-ready-p e) (< (sim-rnd01) (ai-table e :o-ender *ai-o-ender*))))
       (why b :o-ender :kikon))
      ;; our own hit: finish the string, else an SP / L cancel
      ((and (eq st :move) (eq (fighter-contact f) :hit) (member (mv-kind mv) '(:quick :flash)))
       (string-reflex e b f mv))
      ;; guard pressure (the kit's :block-string): a link the opponent blocked goes on, pressed just before the chain
      ;; opens (one roll per link): a J link, a K link only *AI-BLOCK-K-P* of the time (his J interrupts it), never a
      ;; punishable ender (K3): the string resets instead (below); not below :gg-low or into a parry
      ((and (eq st :move) (eq (fighter-contact f) :block) (member (mv-kind mv) '(:quick :flash))
            (ai-pressure-p e) (= (fighter-sf f) (- (mv-total mv) *chain-lead* 1)))
       (let* ((kit (fighter-kit f)))
         (flet ((ok (m) (and m (integerp (mv-adv-block m)) (> (mv-adv-block m) *gg-ender-adv*))))
           (let ((nq (kit-next kit (mv-name mv) :q)) (nf (kit-next kit (mv-name mv) :f)))
             (why b :pressure (cond ((and (ok nf) (< (sim-rnd01) *ai-block-k-p*)) :f) ((ok nq) :q)))))))
      ((eq st :move) nil)
      ;; a Kikon rush's strike hit us, O held, and it dashes in after us: not red, hold guard from inside the
      ;; stagger (*AI-FOLLOW-GUARD-P* by difficulty); red, nothing guards it
      ((and (eq st :stun) (eq (snap-kind s) :kikon) (eq (snap-phase s) :follow) (not red) (plusp guard-k)
            (< (brain-react-roll b) (getf *ai-follow-guard-p* (brain-difficulty b) 0.85)))
       (why b :anti-kikon :guard-long))
      ((not free) nil)
      ;; Bankai West's reversal: the ward just blocked a hit up close (no blockstun): SHONETSU JIGOKU (L) now and then
      ((let ((p (ai-table e :ward-reversal)))
         (and p (passive-p e :ward) (<= (- *match-tick* (fighter-warded f)) 1) (< (fighter-dist f) 3.0)
              (kit-command-ok-p e :sig) (< (brain-react-roll b) p)))
       (why b :ward-reversal :sig))
      ;; the reset: our blocked string just ended (no safe hit left in it) and he still guards: Q1 again
      ((and (eq (brain-was b) :move) (eq (fighter-contact f) :block) (< d (+ (mv-reach q) 0.2)) (ai-pressure-p e))
       (why b :pressure :q))
      ;; a red opponent still reeling from our hits (or bound): rush him
      ((and (kikon-ready-p e) (member (snap-state s) '(:stun :air)) (< d (ai-table e :kikon-range 7.0))
            (kit-command-ok-p e :kikon))
       (why b :kikon :kikon))
      ;; the Bankai (cup 3, red, free: the kit's :bankai), before the cash-out
      ((let ((bk (ai-table e :bankai)))
         (and bk (kit-bankai-form kit) (member st '(:idle :guard)) (bankai-allowed-p t (gauges-konpaku g)) (ai-bankai-p e b bk)))
       (why b :bankai :awaken))
      ;; NOMIHOSE's cash-out (the kit's :cashout): Shift+K only as a punish (he has >= :punish frames of recovery
      ;; or stun left, in the 12 m lane) or within :near m while NOME is below :below (it would drain away anyway)
      ((let ((c (ai-table e :cashout)))
         (and c (kit-command-ok-p e :sp1) (< d 12.0)
              (setf (brain-why b)
                    (cond ((and (member (snap-state s) '(:move :stun)) (< (snap-left s) 99)
                                (>= (- (snap-left s) (brain-delay b)) (getf c :punish)))
                           :cashout-punish)
                          ((and (< d (getf c :near)) (< (gauges-meter g) (getf c :below))) :cashout-near)))))
       :sp1)
      ;; South's tell under us: its grab comes 16 f after the stab (real move frame 36); from what we see
      ;; (delayed), step sideways out of it (the anti-rush chance) or Hoho it (the Hoho roll; perfect late)
      ((and (member :bind (snap-flags s)) (eq (snap-phase s) :main)
            (<= (first (or (snap-tell s) '(21 30))) (+ (snap-sf s) (brain-delay b)) (second (or (snap-tell s) '(21 30)))))
       (cond ((and hoho-ok (< (brain-hoho-roll b) (ai-table e :hoho 0.2))) (why b :anti-bind :hoho))
             ((< (brain-react-roll b) (getf *ai-anti-breaker-p* (brain-difficulty b) 0.5)) (why b :anti-bind :side-step))))
      ;; a parry up close: don't feed it; a Breaker breaks it (half the time), else wait
      ((and (member :parry (snap-flags s)) (eq (snap-phase s) :main) (< d 4.0))
       (and (< (brain-react-roll b) 0.5) (why b :anti-parry :breaker)))
      ((and (gauges-evolution g) (>= (/ (gauges-reishi g) (float (gauges-reishi-max g))) (ai-table e :awaken-above 0.0))
            (ai-awaken-p e))
       :awaken)
      ;; we just blocked an ender (-12 ...): it's our turn, felt at once (no perception delay); a K3 (-20) HARD
      ;; punishes with K1 when it reaches
      ((and (eq (brain-was b) :guard-hit) (<= (fighter-block-adv f) *ai-punish-adv*)
            (< (fighter-dist f) (+ (mv-reach q) 0.4))
            (< (sim-rnd01) (getf *ai-block-punish-p* (brain-difficulty b) 0.5)))
       (why b :block-punish
            (if (and (eq (brain-difficulty b) :hard) (<= (fighter-block-adv f) -20)
                     (< (fighter-dist f) (mv-reach (kit-command-move kit :f))))
                :f :q)))
      ;; a stunned opponent (Guard Break, broken stance, our knockback) still stunned when Q1 lands
      ((and (eq (snap-state s) :stun) (>= (- (snap-left s) (brain-delay b)) (mv-s q)) (< d (+ (mv-reach q) 0.6)))
       (why b :follow-up :q))
      ;; ... farther, the kit's :stun-follow (cmd lo hi): its move if it lands before he is free (Rukia: Shirafune, SOSEN)
      ((let* ((sf (ai-table e :stun-follow)) (c (first sf)))
         (and sf (eq (snap-state s) :stun) (<= (second sf) d (third sf)) (kit-command-ok-p e c)
              (>= (- (snap-left s) (brain-delay b)) (mv-s (kit-command-move kit c)))))
       (why b :stun-follow (first (ai-table e :stun-follow))))
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
      ;; an incoming Breaker, a Kikon rush, or a rush's follow-up strike coming (it hit us, not red): guard
      ;; a rush when not red (the chance by difficulty); else Hoho through its dash (flash-step), Q1 it
      ;; while it has the room, else Step sideways (a Hoho in the aura only reappears in front of the dash)
      ((and (member (snap-kind s) '(:breaker :kikon)) (member (snap-phase s) '(:aura :dash :follow))
            (< d (if (eq (snap-phase s) :follow) (+ (snap-reach s) *ai-threat-margin*) *ai-anti-breaker-range*))
            (< (brain-react-roll b) (getf *ai-anti-breaker-p* (brain-difficulty b) 0.5)))
       (why b :anti-breaker
            (cond ((and (eq (snap-kind s) :kikon) (not red) (plusp guard-k)) :guard)
                  ((and (eq (snap-phase s) :dash) hoho-ok (< (brain-hoho-roll b) (ai-table e :hoho 0.2)))
                   :hoho)
                  ((> d *ai-anti-breaker-q*) :q)
                  (t :side-step))))
      ;; the kit's reactions: stance vs a projectile / a Flash startup it can still beat (stance-in
      ;; must end before the Flash hits, after our perception delay); a parry (West) vs a Flash startup
      ;; whose hit falls in its window (the SP's super freeze holds him *SUPER-FREEZE* f more)
      ((let ((r (ai-table e :react)))
         (and r (< (brain-react-roll b) *ai-react-p*)
              (or (and (snap-projectile s) (getf r :projectile))
                  (and (eq (snap-kind s) :flash) (< d 4.0) (getf r :flash-startup) (kit-command-ok-p e (getf r :flash-startup))
                       (let ((lead (- (snap-s s) (snap-sf s) (brain-delay b)))
                             (mv (kit-command-move kit (getf r :flash-startup))))
                         (if (member :parry (mv-flags mv))
                             (and (eq (snap-phase s) :main) (parry-frame-p (+ lead *super-freeze*)))
                             (>= lead (+ *stance-in* 2))))))))
       (let ((r (ai-table e :react)))
         (why b :react (if (snap-projectile s) (getf r :projectile) (getf r :flash-startup)))))
      ;; a long guard up close: Breaker it
      ((and (eq (snap-state s) :guard) (>= (snap-guard-t s) *ai-guard-break-hold*) (< d *ai-guard-break-range*)
            (/= (brain-break-key b) (snap-start s)))
       (setf (brain-break-key b) (snap-start s))
       (and (< (sim-rnd01) *ai-guard-break-p*) (why b :guard-break :breaker)))
      ;; a committed move coming: Hoho it (flash-step to spare) or guard it; a low guard gauge guards
      ;; less and steps aside instead (AI-GUARD-MULT); a Kikon rush on us red: Hoho or Step
      ((and (eq (snap-state s) :move) (member (snap-kind s) '(:quick :flash :sig :sp :breaker :kikon))
            (< (snap-sf s) (snap-active-end s)) (< d (+ (snap-reach s) *ai-threat-margin*)))
       (let ((chance (+ (ai-table e :guard 0.3) (if (eq (brain-intent b) :defend) 0.25 0.0))))
         (cond ((and hoho-ok (ai-hoho-spare-p (gauges-fs g) (gauges-reishi g) (gauges-reishi-max g))
                     (>= (- (snap-s s) (snap-sf s)) 6) (< (brain-hoho-roll b) (ai-table e :hoho 0.2)))
                (why b :hoho :hoho))
               ((and red (eq (snap-kind s) :kikon)) (why b :anti-kikon :side-step))
               ((member :grab (snap-flags s)) (why b :anti-grab :side-step))   ; a grab: nothing guards it
               ((< (brain-guard-roll b) (* chance guard-k)) :guard)
               ((< (brain-guard-roll b) chance) (why b :low-guard :side-step))))))))

(defun j-beats-k-p (e b)
  "J beats K (docs/DUEL_STRINGS.md §4): on the first free step after our blockstun, the string's next link is a K link
(no armour) still at least S(J1) + 2 frames from its hit, inside our J1's reach: J1 gets there first. Felt at once,
like the block punish (the gap of a blocked string, not a read through the perception delay: a K link's startup is
shorter than NORMAL's delay); one roll (*AI-J-BEATS-K-P* by difficulty), also out of a guard held through the string."
  (let* ((f (fighter e)) (o (fighter-opp f)) (fo (fighter o)) (om (fighter-move fo)) (q (kit-command-move (fighter-kit f) :q)))
    (and (eq (brain-was b) :guard-hit) (member (fighter-state f) '(:idle :guard)) (zerop (fighter-lock f))
         (eq (fighter-state fo) :move) (eq (fighter-phase fo) :main) (eq (mv-kind om) :flash)
         (>= (- (mv-s om) (fighter-sf fo)) (+ (mv-s q) 2)) (< (fighter-dist f) (+ (mv-reach q) 0.2))
         (< (sim-rnd01) (getf *ai-j-beats-k-p* (brain-difficulty b) 0.45)))))

(defun ai-neutral (e b s d)
  "No reflex fired: walk to the intent's range, and now and then decide (AI-DECIDE)."
  (let* ((kit (kit-of e)) (vp (pilot-vpad (pilot e))) (heat (brain-heat b)))
    (when (<= (decf (brain-intent-t b)) 0)
      (setf (brain-intent-t b) *ai-repick*)
      (let ((w (ai-table e :intents)) (hot (min 3.0 (/ heat 4.0))) (r (sim-rnd01)))
        (setf (brain-intent b)
              (cond ((ai-gg-low-p e) (weighted-pick r :zone 3 :defend 2))   ; low guard gauge: zone (the cone), no pressure
                    (t (let ((oi (getf (kit-ai (kit-of (opp-of e))) :opp-intent)))   ; facing a form a CPU waits out
                         (or (weighted-pick r :approach (getf w :approach 1)
                                            :pressure (+ (getf w :pressure 1) hot (if (or (opp-guardless-p e) (opp-gg-low-p e)) 3 0))
                                            :zone (+ (getf w :zone 1) (getf oi :zone 0))
                                            :defend (+ (getf w :defend 1) (getf oi :defend 0)))
                             :approach)))))))
    (when (<= (decf (brain-strafe-t b)) 0)
      (setf (brain-strafe-t b) (+ (first *ai-strafe-time*) (floor (* (second *ai-strafe-time*) (sim-rnd01))))
            (brain-strafe b) (if (< (sim-rnd01) 0.5) -1f0 1f0)))
    (destructuring-bind (lo hi) (getf (ai-table e :ranges) (brain-intent b) '(2.0 4.0))
      (multiple-value-bind (lo hi) (heat-range lo hi heat)
        (vpad-stick! vp (if (<= lo d hi) (brain-strafe b) (* 0.3 (brain-strafe b)))
                     (cond ((> d hi) 1f0) ((< d lo) -1f0) (t 0f0)))
        (when (<= (decf (brain-decide-t b)) 0)
          (setf (brain-decide-t b) (+ (getf *ai-think* (brain-difficulty b) 24) (floor (* 40 (sim-rnd01)))))
          (ai-decide e b kit s d lo hi heat))))))

(defun opp-guardless-p (e)
  "E's opponent can't guard (his guard gauge ran out): press him (AI-NEUTRAL, AI-DECIDE)."
  (gauges-guardless (gauges (opp-of e))))

(defun ai-pressure-p (e)
  "Keep a blocked string going (the kit's :block-string chance; always while hunting a low guard gauge,
OPP-GG-LOW-P)? Only while the opponent really holds guard (or a ward), never below :gg-low of our own gauge."
  (let ((p (ai-table e :block-string)))
    (and p (guarding-p (opp-of e)) (not (ai-gg-low-p e))
         (< (sim-rnd01) (if (opp-gg-low-p e) 1.0 p)))))

(defun opp-gg-low-p (e)
  "E's opponent's guard gauge (on the HUD) is under half: hunt the crush (press him; a blocked string goes on)."
  (< (gauges-gg (gauges (opp-of e))) (* 0.5 *gg-max*)))

(defun ai-decide (e b kit s d lo hi heat)
  "A neutral decision, at distance D with the preferred range LO..HI (S: the perceived opponent):
the Kikon rush on a red opponent within its range (*AI-KIKON-P*), dash to / from that range (until
its middle), guard, attack (a weighted pick from the kit's band for D), or wait."
  (cond ((and (kikon-ready-p e) (< d (ai-table e :kikon-range 7.0)) (not (member (snap-state s) '(:down :wakeup :hoho)))
              (kit-command-ok-p e :kikon) (< (sim-rnd01) (ai-kikon-p e)))
         (ai-command b kit :kikon d) (setf (brain-why b) :kikon))
        ((ai-pip-hurry-p e)                                ; the arm's next crack is near: spend the pip now
         (ai-attack e b kit s d heat t))
        ((ai-cool-p e s d)                                 ; Rukia: hold U the frames the next colder band still needs
         (ai-press b :guard (+ 2 (temp-cool-frames (gauges-meter (gauges e)))) :act :cool)
         (setf (brain-why b) :cool))
        ((ai-brace-p e d)                                  ; Rukia at zero: brace a while (the warming stops)
         (ai-press b :guard 20 :act :brace)
         (setf (brain-why b) :brace))
        ((and (> d (+ hi *ai-dash-gap*)) (< (sim-rnd01) (ai-table e :dash 0.0)))
         (ai-dash b 1.0 (* 0.5 (+ lo hi))) (setf (brain-why b) :dash))
        ((and (< d (- lo *ai-dash-gap*))
              (< (sim-rnd01) (if (ai-gg-low-p e) 0.6 (ai-table e :dash-back 0.0))))
         (ai-dash b -1.0 (* 0.5 (+ lo hi))) (setf (brain-why b) :dash-back))
        ((and (< d 3.4) (< (sim-rnd01) (* (min 0.9 (+ (ai-table e :guard 0.3) (if (eq (brain-intent b) :defend) 0.2 0.0)))
                                          (ai-guard-mult (gauges-gg (gauges e)) (gauges-guardless (gauges e))))))
         (ai-press b :guard (+ (first *ai-guard-hold*) (floor (* (second *ai-guard-hold*) (sim-rnd01))))))
        ((< (sim-rnd01) (min 0.9 (+ (getf *ai-aggression* (brain-intent b) 0.3) (* 0.04 heat)
                                    (* *ai-kosei-aggression* (- 1.0 (ai-gg e)))   ; KOSEI: a low gauge pays to attack
                                    (cond ((opp-guardless-p e) 0.3) ((opp-gg-low-p e) 0.2) (t 0.0)))))
         (ai-attack e b kit s d heat nil))))

(defun ai-pip-hurry-p (e)
  "The kit's :pip-hurry: a pip of the arm is left and its crack is at most that many frames away."
  (let ((h (ai-table e :pip-hurry)) (g (gauges e)))
    (and h (kit-pips (kit-of e)) (>= (gauges-meter g) 1f0) (null (gauges-arm-pending g))
         (>= (gauges-meter-idle g) (- *arm-crack* h)))))

(defun ai-attack (e b kit s d heat hurry)
  "A weighted pick from the kit's band for D, pressed when it may start (not a J / K out of its reach). HURRY: only the
pip commands of the band (the arm's crack is near: AI-PIP-HURRY-P). T when something was pressed."
  (let* ((weights (copy-list (band-weights (ai-table e :moves) d))))
    (when (getf weights :breaker)                  ; (a guardless opponent has no guard to break)
      (setf (getf weights :breaker) (if (opp-guardless-p e) 0 (* (getf weights :breaker) (heat-breaker-mult heat)))))
    (ai-stance-weights e s d weights)
    (when hurry
      (loop for (cmd nil) on weights by #'cddr unless (and cmd (kit-pip-cmd-p kit cmd)) do (setf (getf weights cmd) 0)))
    (let ((cmd (apply #'weighted-pick (sim-rnd01) weights)))
      (when (and cmd (or (not (member cmd *kit-commands*)) (and (kit-command-move kit cmd) (kit-command-ok-p e cmd)))
                 (or (not (member cmd '(:q :f)))                  ; don't whiff a string at range
                     (<= d (+ 0.2 (mv-reach (kit-command-move kit cmd))))))
        (ai-command b kit cmd d) (setf (brain-why b) (if hurry :pip-hurry :neutral))
        t))))

(defun ai-kikon-p (e)
  "The chance a neutral decision rushes a red opponent: the kit's :kikon-p (Nozarashi's cups 0.25 / 0.5 / 0.9:
a later Kikon is worth more), at least *AI-KIKON-P* once the match has under a minute left; else *AI-KIKON-P*."
  (let ((k (ai-table e :kikon-p)))
    (cond ((null k) *ai-kikon-p*)
          ((< (match-frames-left) 3600) (max k *ai-kikon-p*))
          (t k))))

(defun ai-stance-weights (e s d weights)
  "The stance keys on a neutral pick's WEIGHTS (a fresh plist, edited in place): no Q / F into a guard within 3 m
below :gg-low; none into a parry; L x the kit's :low factor below its Reishi fraction, halved below its :sig-gg
fraction of the guard gauge."
  (loop for (cmd w) on weights by #'cddr
        when (and (member cmd '(:q :f))
                  (or (and (ai-gg-low-p e) (< d 3.0) (member (snap-state s) '(:guard :guard-hit)))
                      (member :parry (snap-flags s))))
          do (setf (getf weights cmd) 0))
  (let ((low (ai-table e :low)) (sg (ai-table e :sig-gg)) (g (gauges e)))
    (when (and low (getf weights :sig) (< (/ (gauges-reishi g) (float (gauges-reishi-max g))) (first low)))
      (setf (getf weights :sig) (* (getf weights :sig) (getf (rest low) :sig 1))))
    (when (and sg (getf weights :sig) (< (ai-gg e) sg))
      (setf (getf weights :sig) (* 0.5 (getf weights :sig)))))
  weights)

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
      (unless (kit-bankai-form (fighter-kit f)) (setf (brain-bankai-rolled b) nil))   ; a new cup-3 stay rolls again
      (when (member (fighter-state f) '(:stun :air :down :wakeup :guard-hit))   ; just took it: respect
        (setf (brain-intent b) :defend (brain-intent-t b) *ai-respect*))
      (when (and (eq (fighter-state f) :guard-hit) (zerop (fighter-sf f)) (not (brain-off b)))   ; blocked: hold on through the string?
        (when (< (sim-rnd01) (getf *ai-hold-guard* (brain-difficulty b) 0.85))
          (ai-press b :guard (+ (fighter-stun f) 20) :act :hold)))   ; (no reflex drops it: BRAIN-STEP)
      (if (and (member (fighter-state f) '(:stun :air)) (>= (fighter-combo-hits f) *burst-min-hits*))
          (incf (brain-burst-t b))                                                ; the Burst clock
          (setf (brain-burst-t b) 0 (brain-burst-rolled b) nil))
      (when (and (eq (brain-act b) :dash) (> (brain-press-left b) 0)              ; a dash reached its range:
                 (if (> (brain-dash b) 0) (<= d (brain-dash-to b)) (>= d (brain-dash-to b))))
        (setf (brain-press-left b) 0 (brain-decide-t b) 1))                      ; decide now (out of the run)
      (unless (or (brain-off b) (> (fighter-lock f) 0) (eq (fighter-state f) :cine))
        (cond ((ai-burst-roll e b) (ai-press b :quick 1 :modded t :act :burst) (setf (brain-why b) :burst))
              ((j-beats-k-p e b) (ai-press b :quick 1) (setf (brain-why b) :j-beats-k))
              ((and (> (brain-press-left b) 0)                                    ; a reflex may drop a guard / a dash,
                    (or (eq (brain-act b) :hold)                                   ; not a guard held through a string
                        (not (or (eq (brain-press b) :guard) (eq (brain-act b) :dash)))))
               (decf (brain-press-left b)))
              (t (let ((cmd (ai-reflex e b s d)))
                   (cond ((and cmd (not (and (eq cmd :guard) (eq (brain-press b) :guard) (> (brain-press-left b) 0))))
                          (ai-command b (kit-of e) cmd d))
                         ((> (brain-press-left b) 0) (decf (brain-press-left b)))
                         ((member (fighter-state f) '(:idle :run)) (ai-neutral e b s d)))))))
      (setf (brain-was b) (fighter-state f))
      ;; the buttons of this step
      (loop for a across *vpad-actions*
            do (vpad-set! vp a (or (and (> (brain-press-left b) 0) (eq a (brain-press b)))
                                   (and (eq a :mod) (> (brain-press-left b) 0) (brain-press-mod b)))))
      (when (> (brain-press-left b) 0)
        (case (brain-act b)
          (:guard (vpad-stick! vp 0f0 0f0))
          (:side-step (vpad-stick! vp (brain-strafe b) 0f0))
          (:dash (vpad-stick! vp 0f0 (brain-dash b))))))))

(defun brain-system ()
  "Every CPU fighter decides this step (before FIGHTER-SYSTEM reads the vpads)."
  (do-entities (e (b brain) (f fighter)) (brain-step e b)))

(defun pilot-system ()
  "Every human fighter's vpad reads its devices this step (inside the step: determinism)."
  (do-entities (e (pl pilot) (f fighter))
    (unless (brain e) (vpad-begin-step! (pilot-vpad pl)))))
