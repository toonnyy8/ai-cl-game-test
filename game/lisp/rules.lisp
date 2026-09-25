;;;; rules.lisp — RAVEN EDGE's game rules as pure functions (the "functional core"): inputs are
;;;; arguments, results are return values (numbers, keywords, small structs), randomness is passed
;;;; in as a number. No components, no special variables, no side effects. The systems (the
;;;; "imperative shell": combat.lisp, player.lisp, enemy.lisp, game.lisp) gather the inputs, call
;;;; a rule and apply its result to the entities.
;;;; Plain Common Lisp (no engine macros), so tests/rules-test.lisp loads this file on the host ECL
;;;; and checks every rule natively, without a build or a browser.
(in-package :raven)

;;; ---------------------------------------------------------------- the records the rules read
;;; A MOVE is one attack (or scripted action) with its frame data; each HITDEF is one active window
;;; of it. DEFMOVE (moves.lisp) builds them from a declarative spec.
(defstruct (hitdef (:conc-name hd-))
  (from 0 :type fixnum) (to 0 :type fixnum)   ; active frames [from, to)
  (vols nil)                                   ; list of hit volumes (see VOL-HIT-P)
  (dmg 0f0 :type single-float) (imp 0f0 :type single-float)   ; damage, impact (poise damage)
  (react :flinch)                              ; :flinch :stagger :knockdown :launch :air-flinch
  (kb 0f0 :type single-float)                  ; push distance over 6 f
  (hs 3 :type fixnum)                          ; hitstop frames
  (hw nil)                                     ; heavy-weight: can cripple
  (stun 0f0 :type single-float)                ; reaction frames override (0 = default)
  (vy 0f0 :type single-float)                  ; launch velocity
  (feet 99f0 :type single-float)               ; only targets with feet below this (ground shock)
  (flags nil))       ; :ender :no-poise :no-raven :unblockable :guard-break :obliterate :ranged :quiet

(defstruct (move (:conc-name mv-))
  (name nil) (clip nil) (clip-speed 1f0 :type single-float) (blend 0f0 :type single-float)
  (s 0 :type fixnum) (a 0 :type fixnum) (r 0 :type fixnum)   ; startup, active, recovery frames
  (hits #() :type simple-vector)               ; HITDEFs
  (light nil) (heavy nil)                      ; chain targets
  (chain-at -1 :type fixnum)                   ; frame the light/heavy chain opens (-1 = A_end)
  (heavy-at -1 :type fixnum)
  (abort 0 :type fixnum)                       ; dodge-abort allowed for sf < abort
  (sfx nil) (pitch 1f0 :type single-float)
  (hw nil) (magnet 0f0 :type single-float) (reach 0f0 :type single-float)
  (inv-from -1 :type fixnum) (inv-to -1 :type fixnum)
  (slide nil)                                  ; (from to metres) scripted forward displacement
  (air nil) (hang nil) (red nil) (ravenable nil) (jump nil) (special nil)
  (trail-from 0 :type fixnum) (trail-to 0 :type fixnum))

;;; Hit volumes (§0): MAKE-VOL / VOL-HIT-P are the engine's (engine/lisp/hitvol.lisp); a HITDEF's
;;; VOLS are those attacker-relative volumes (EXTRA widens ARC radii in Raven Form).

;;; ================================================================ a hit on an enemy (§4)
(defstruct (enemy-hit (:conc-name eh-))
  "What one hit does to an enemy. RESULT: NIL (no effect), :blocked, :guard-break, :armored (took
damage, no reaction), :hit (damage + REACT), :crippled, :killed, :broken (the boss at 0 HP)."
  (result nil)
  (damage 0.0) (hp 0.0) (poise 0.0)      ; HP lost, HP and poise after the hit
  (poise-hit nil)                        ; the poise took damage (its regen timer restarts)
  (react :flinch) (stun 0.0)             ; reaction for :hit (stun 0 = the reaction's default)
  (hitstop 0)                            ; frames
  (heavy nil)                            ; heavy-weight: the combo gauge gain and the big feedback
  (fx-heavy nil) (ender nil)             ; feedback: heavy mist / sound, big shake
  (raven-break nil))                     ; the hit broke a red windup (Raven Form)

(defun enemy-hit-outcome (hd &key raven ravenable boss crippled guarding downed
                                  red-windup (windup-frac 0.0) (poise 0.0) (body-poise 0.0)
                                  (hp 0.0) (max-hp 1.0) (cripple-frac 0.3) no-cripple)
  "Rule for hit HD landing on an enemy that can be hit. RAVEN: REN hit it in Raven Form; RAVENABLE: his move gets the Raven buffs (heavy, x2 impact); BOSS: ENRA (never crippled,
BROKEN instead of dead); GUARDING: it blocks this hit (guard stance facing him, or its block roll);
DOWNED: lying on the floor; RED-WINDUP / WINDUP-FRAC: winding up a red attack, and how far.
Returns an ENEMY-HIT."
  (let* ((flags (hd-flags hd))
         (oblit (member :obliterate flags))
         (rl (and raven ravenable))
         (hw (and (or (hd-hw hd) rl) t))
         (dmg (* (hd-dmg hd) (if (and raven (not (member :no-raven flags))) 1.5 1.0) (if downed 0.6 1.0)))
         (imp (* (hd-imp hd) (if rl 2.0 1.0)))
         (hs (hd-hs hd))
         (out (make-enemy-hit :hp hp :poise poise :react (hd-react hd) :stun (hd-stun hd) :hitstop hs
                              :heavy hw :fx-heavy hw :ender (and (member :ender flags) t))))
    (flet ((result (r &key (hitstop hs) (fx-heavy hw) (ender (eh-ender out)))
             (setf (eh-result out) r (eh-hitstop out) hitstop (eh-fx-heavy out) fx-heavy (eh-ender out) ender)
             out))
      (cond
        ;; crippled: any hit kills it (the BROKEN boss only dies to Obliterate)
        (crippled (if (and boss (not oblit))
                      out
                      (progn (setf (eh-hp out) 0.0 (eh-heavy out) t)
                             (result :killed :hitstop (+ hs 3) :fx-heavy t :ender t))))
        ;; blocked: heavy-weight / Raven / guard-break hits break the guard
        ((and guarding (not (member :unblockable flags)))
         (if (or hw raven (member :guard-break flags))
             (progn (setf (eh-stun out) (if boss 30.0 48.0)) (result :guard-break))
             (result :blocked)))
        (t
         (let ((armored nil))
           (cond ((and red-windup raven)                ; Raven Break: +20 dmg, long stagger
                  (setf dmg (+ dmg 20) (eh-react out) :stagger
                        (eh-stun out) (+ 90.0 (if (> windup-frac 0.7) 30.0 0.0)) (eh-raven-break out) t))
                 (red-windup (setf armored t))          ; red windups have hyper armor
                 ((member :no-poise flags))
                 (t (let ((left (- poise imp)))         ; poise absorbs the reaction until it breaks
                      (setf (eh-poise-hit out) t)
                      (if (> left 0) (setf armored t (eh-poise out) left) (setf (eh-poise out) body-poise)))))
           (let ((hp2 (- hp dmg)))
             (setf (eh-damage out) dmg (eh-hp out) hp2)
             (cond ((and (<= hp2 0) boss) (result :broken :hitstop (+ hs 3) :fx-heavy t :ender t))
                   ((<= hp2 0) (result :killed :hitstop (+ hs 3)))
                   ((and hw (not no-cripple) (<= hp2 (* cripple-frac max-hp))) (result :crippled :fx-heavy t))
                   (armored (result :armored :hitstop (max 2 (floor hs 2)) :ender nil))
                   (t (result :hit))))))))))

(defun reaction-for (kind airborne downed)
  "The reaction an enemy actually plays: flinch / stagger become an air flinch in the air, an
air flinch on the ground is a flinch, and a launch on someone lying down is a knockdown."
  (cond ((and airborne (member kind '(:flinch :stagger))) :air-flinch)
        ((and (not airborne) (eq kind :air-flinch)) :flinch)
        ((and (eq kind :launch) downed) :knockdown)
        (t kind)))

;;; ================================================================ a hit on REN (§3.2 Defense, §3.5)
(defstruct (player-hit (:conc-name ph-))
  "What one enemy hit does to REN. RESULT: :just-dodge, :dodged (i-frames), NIL (anti-juggle),
:raven-guard, :parried, :blocked, :hit. REACTION (for :hit): :dead :guard-break :knockdown
:stagger :flinch; GUARD-BROKEN: a :blocked hit emptied the guard meter."
  (result nil)
  (damage 0.0) (hp 0.0) (guard-meter 0.0) (guard-broken nil)
  (reaction nil) (hitstop 0) (heavy nil))

(defun player-hit-outcome (hd &key red just-dodge invulnerable (tick 0) (last-hurt -1000) (prev-hurt -1000)
                                   guarding raven-form (raven 0.0) (guard-age 1000) (parry-window 8)
                                   (guard-meter 100.0) (guard-cost-mult 2.5) (dmg-mult 1.0) (hp 0.0))
  "Rule for enemy hit HD reaching REN. RED: red / unblockable attack. JUST-DODGE: he is in the
just-dodge window. GUARDING: guard stance facing the attacker. GUARD-AGE: frames since the fresh
guard press (a parry within PARRY-WINDOW). LAST-HURT / PREV-HURT: ticks of his last two damaging
hits (anti-juggle: at most 2 per second). Returns a PLAYER-HIT."
  (let* ((dmg (* (hd-dmg hd) dmg-mult))
         (out (make-player-hit :hp hp :guard-meter guard-meter :damage dmg)))
    (flet ((result (r) (setf (ph-result out) r) out))
      (cond
        (just-dodge (result :just-dodge))
        (invulnerable (result :dodged))
        ((and (> (- tick last-hurt) 0) (<= (- tick last-hurt) 60) (<= (- tick prev-hurt) 60)) (result nil))
        ((and guarding red raven-form (>= raven 15)) (result :raven-guard))
        ((and guarding (not red) (<= guard-age parry-window)) (result :parried))
        ((and guarding (not red))
         (let ((meter (- guard-meter (* dmg guard-cost-mult))))
           (setf (ph-guard-meter out) (if (<= meter 0) 0.0 meter) (ph-guard-broken out) (<= meter 0))
           (result :blocked)))
        (t                                              ; damage (a red attack breaks the guard)
         (let* ((kd (or red (>= dmg 30) (eq (hd-react hd) :knockdown)))
                (hp2 (max 0.0 (- hp dmg))))
           (setf (ph-hp out) hp2
                 (ph-hitstop out) (cond (red 9) ((or kd (>= dmg 16)) 7) (t 4))
                 (ph-heavy out) (or kd (>= dmg 16))
                 (ph-reaction out) (cond ((<= hp2 0) :dead)
                                         ((and guarding red) :guard-break)
                                         (kd :knockdown)
                                         ((>= dmg 16) :stagger)
                                         (t :flinch)))
           (result :hit)))))))

;;; ================================================================ REN's moves (§2, §3.2)
(defun dodge-speed (sf)
  "Ground roll speed (m/s) at frame SF: 18 for 12 f, then down to 0 at f21 (5 m in all)."
  (if (< sf 12) 18.0 (* 18.0 (max 0.0 (/ (- 21 sf) 9.0)))))

(defun action-priority (dodge jump heavy light)
  "The buffered action to act on (each argument: pressed and allowed now): dodge > jump > heavy > light."
  (cond (dodge :dodge) (jump :jump) (heavy :heavy) (light :light)))

(defun move-cancels (mv sf landed obliterate-ready)
  "Which actions may cancel move MV at frame SF. LANDED: it hit something; OBLITERATE-READY: a
crippled enemy is in reach. Values: dodge-ok jump-ok heavy-ok light-ok."
  (let* ((aend (+ (mv-s mv) (mv-a mv)))
         (first-hit (if (plusp (length (mv-hits mv))) (hd-from (svref (mv-hits mv) 0)) (mv-s mv)))
         (chain-at (if (>= (mv-chain-at mv) 0) (mv-chain-at mv) aend))
         (heavy-at (if (>= (mv-heavy-at mv) 0) (mv-heavy-at mv) chain-at))
         (j (mv-jump mv)))
    (values (or (>= sf aend) (and landed (>= sf first-hit)) (< sf (mv-abort mv)))
            (cond ((eq j :on-hit) (and landed (>= sf first-hit))) ((numberp j) (>= sf j)))
            (and (>= sf heavy-at) (or (mv-heavy mv) (mv-air mv) obliterate-ready) t)
            (and (>= sf chain-at) (mv-light mv) t))))

(defun raven-gauge-after (gauge n form source)
  "Raven gauge after gaining N (0..100). Nothing is gained in Raven Form except from Obliterate."
  (if (and form (not (eq source :obliterate))) gauge (min 100.0 (+ gauge n))))

(defun landed-hit-gain (move-name heavy)
  "Raven gauge for one connected hit of REN's (§3.3): counters 6, heavy-weight 4, else 2;
Obliterate and Thunderfall pay out separately."
  (cond ((member move-name '(:riposte :mirage)) 6)
        ((member move-name '(:obliterate :thunderfall)) 0)
        (heavy 4)
        (t 2)))

;;; ================================================================ enemies (§4.6, §5)
(defun token-decision (kind &key held (delay 0.0) paused (melee 0) (punish 0) (ranged 0)
                                 (melee-max 2) (ranged-max 1) (punish-cd 0.0) punishable (dist 99.0))
  "Aggression tokens: may an enemy asking for a KIND (:melee / :ranged) token start a windup?
HELD: it already holds one. DELAY: seconds until tokens are handed out again; PAUSED: REN's pause
rule. MELEE / PUNISH / RANGED: tokens out now. A punish token (a free third melee token, windup
x0.8) goes to one enemy within 2.5 m of REN while he recovers. Returns :keep, :melee, :ranged,
:punish or NIL."
  (cond (held :keep)
        ((or (> delay 0) paused) nil)
        ((and (eq kind :melee) (< (+ melee punish) melee-max)) :melee)
        ((and (eq kind :ranged) (< ranged ranged-max)) :ranged)
        ((and (eq kind :melee) (<= punish-cd 0) punishable (<= dist 2.5) (zerop punish)) :punish)))

(defun windup-skip (s red mult skip)
  "Frames of an enemy windup of S frames to skip: MULT < 1 shortens it (punish x0.8, boss phase
2 x0.85) but a RED windup keeps at least 42 f; SKIP frames more."
  (max 0.0 (min (if red (float (- s 42)) (float s)) (+ skip (* s (- 1.0 mult))))))

(defun enra-attack-choice (d p2 zone-t r)
  "ENRA's pick at distance D (m): close = Triple Cut / Crimson Crescent (after 1.5 s in range) /
shove / backstep; mid = Iai Dash or walk in (NIL); far = Blade Wave / Iai / Bloodrain Leap (phase 2)."
  (cond ((<= d 3.0) (weighted-pick r :en-triple 45 :en-crescent (if (> zone-t 1.5) 25 0) :en-shove 10 :en-backstep 20))
        ((<= d 8.0) (weighted-pick r :en-iai 60 nil 40))
        (t (weighted-pick r :en-wave 50 :en-iai 50 :en-leap (if (and p2 (<= d 15.0)) 40 0)))))

;;; ================================================================ waves, score, rank (§6.3, §6.4)
(defun wave-progress (reinforcements reinforced queue-empty living)
  "What the wave spawner does next: :reinforce (send the reinforcements once 2 or fewer are
left), :clear (the wave is won) or NIL."
  (cond ((and reinforcements (not reinforced) queue-empty (<= living 2)) :reinforce)
        ((and queue-empty (or reinforced (null reinforcements)) (zerop living)) :clear)))

(defun run-score (kills max-combo obliterations run-time damage-taken)
  "Kills x50 + best combo x20 + Obliterations x100 + 10 per second under 10 minutes - damage x5."
  (round (+ (* 50 kills) (* 20 max-combo) (* 100 obliterations)
            (* 10 (max 0 (- 600 (floor run-time)))) (- (* 5 damage-taken)))))

(defun run-rank (score retries)
  "S >= 6000, A >= 4500, B >= 3000, else C; a run with retries can't be S."
  (let ((r (cond ((>= score 6000) "S") ((>= score 4500) "A") ((>= score 3000) "B") (t "C"))))
    (if (and (plusp retries) (string= r "S")) "A" r)))
