;;;; rules.lisp — SOUL DUEL's rules as pure functions (the "functional core", design-v1 §1–§4, §8):
;;;; inputs are arguments, results are return values (numbers, keywords, multiple values),
;;;; randomness comes in as a number in [0,1). They read the knobs in tuning.lisp and nothing else:
;;;; no components, no side effects. The systems (fighter, combat, hazards, ai: the "imperative
;;;; shell") gather the inputs, call a rule and apply its result.
;;;; Conventions: frames are 60 Hz steps; a move frame SF counts the frames since the move began
;;;; (0 = its first frame), so a move with startup S is active on SF = S .. S+A-1. Yaw 0 faces -Z
;;;; (the engine's FWD-X / FWD-Z). Reishi is an integer; gauges are floats.
;;;; Plain Common Lisp over the engine's plain-CL math (DEG, ANGLE-WRAP, FWD-X, TURN-TOWARD,
;;;; WEIGHTED-PICK in engine/lisp/math.lisp; volumes in engine/lisp/hitvol.lisp): no engine macros,
;;;; so tests/duel-rules-test.lisp loads it on the host ECL. No character names in here:
;;;; characters are kit data (kit.lisp).
(in-package :duel)

;;; ================================================================ angles and positions
;;; CL's PI is a long-float: arithmetic with it conses doubles. Use these single-floats instead.
(defconstant +pi+ #.(float pi 1f0))
(defconstant +two-pi+ #.(float (* 2 pi) 1f0))

(defun dir-yaw (dx dz)
  "The yaw that faces direction (DX DZ). The engine's YAW-TO is the same angle computed in float
C (atan2f); this one is CL's ATAN (double atan2, rounded), which the seeded replays were recorded
with, so the sim keeps it."
  (atan (- dx) (- dz)))

(defun track-step (deg-per-second)
  "A :track value (degrees per second) as radians per frame."
  (deg (/ deg-per-second 60.0)))

(defun clamp-to-circle (x z r)
  "(X Z) moved inside the circle of radius R around the origin (the arena's invisible wall).
Values: x z."
  (let ((d (sqrt (+ (* x x) (* z z)))))
    (if (<= d r) (values x z) (values (* x (/ r d)) (* z (/ r d))))))

(defun stick-toward-strafe (sx sy cam-yaw px pz ox oz)
  "Opponent-relative movement (§2): stick (SX right, SY up) read through a camera with yaw CAM-YAW
(camera-relative, like any third-person game) and converted for a fighter at (PX PZ) whose
opponent stands at (OX OZ). Values: TOWARD (+ = at the opponent) and STRAFE (+ = to the fighter's
right while he faces the opponent). One code path for every camera."
  (let* ((fx (fwd-x cam-yaw)) (fz (fwd-z cam-yaw))
         (wx (+ (* sy fx) (* sx (- fz))))            ; camera right = (-fz, fx)
         (wz (+ (* sy fz) (* sx fx)))
         (ax (- ox px)) (az (- oz pz)) (d (sqrt (+ (* ax ax) (* az az)))))
    (if (< d 1e-4)
        (values sy sx)
        (let ((ux (/ ax d)) (uz (/ az d)))
          (values (+ (* wx ux) (* wz uz)) (+ (* wx (- uz)) (* wz ux)))))))

(defun toward-strafe-dir (toward strafe px pz ox oz)
  "The inverse of STICK-TOWARD-STRAFE's projection: world direction (values dx dz) of moving
TOWARD / STRAFE relative to the opponent at (OX OZ)."
  (let* ((ax (- ox px)) (az (- oz pz)) (d (max 1e-4 (sqrt (+ (* ax ax) (* az az)))))
         (ux (/ ax d)) (uz (/ az d)))
    (values (+ (* toward ux) (* strafe (- uz))) (+ (* toward uz) (* strafe ux)))))

(defun in-front-p (yaw px pz ax az arc-deg)
  "Is the point (AX AZ) within the ARC-DEG wide cone in front of a fighter at (PX PZ) facing YAW?
Guard uses *GUARD-ARC* (200 deg)."
  (let* ((dx (- ax px)) (dz (- az pz)) (d (sqrt (+ (* dx dx) (* dz dz)))))
    (or (< d 1e-4)
        (>= (/ (+ (* dx (fwd-x yaw)) (* dz (fwd-z yaw))) d)
            (cos (deg (/ arc-deg 2.0)))))))

(defun hoho-destination (ox oz oyaw)
  "Where a Hoho reappears: *HOHO-DISTANCE* behind the opponent at (OX OZ) facing OYAW, facing his
back, clamped into the arena. Values: x z yaw."
  (multiple-value-bind (x z)
      (clamp-to-circle (- ox (* *hoho-distance* (fwd-x oyaw)))
                       (- oz (* *hoho-distance* (fwd-z oyaw))) *arena-radius*)
    (values x z oyaw)))

(defun reset-placement (ax az bx bz)
  "Post-Kikon reset (§1): A and B placed *RESET-DISTANCE* apart around the arena centre, on the
line they stood on (A keeps his side). Values: ax az bx bz (each then faces the other)."
  (let* ((dx (- bx ax)) (dz (- bz az)) (d (sqrt (+ (* dx dx) (* dz dz))))
         (h (/ *reset-distance* 2.0)))
    (if (< d 1e-3) (setf dx 0.0 dz 1.0) (setf dx (/ dx d) dz (/ dz d)))
    (values (* dx (- h)) (* dz (- h)) (* dx h) (* dz h))))

(defun step-direction (toward strafe &optional (neutral -1.0))
  "Step direction (values toward strafe, unit length): the stick's, or straight back when the
stick is neutral. NEUTRAL 1.0: straight at the opponent instead (the run)."
  (let ((m (sqrt (+ (* toward toward) (* strafe strafe)))))
    (if (< m 0.3) (values neutral 0.0) (values (/ toward m) (/ strafe m)))))

;;; ---------------------------------------------------------------- the run (Step held)
(defun run-stop-p (dist closing speed)
  "Does a run moving at SPEED m/s, CLOSING (the fraction of it toward the opponent, -1..1), stop
this frame at DIST from him? It stops before it would come within *RUN-STOP*."
  (and (> closing 0) (< (- dist (* speed closing (/ 1.0 60))) *run-stop*)))

(defun run-carry (dist)
  "Momentum of a move started out of a run: *RUN-CARRY* metres, never past *RUN-STOP* from the
opponent at DIST."
  (max 0.0 (min *run-carry* (- dist *run-stop*))))

(defun brake-speed (speed frame)
  "Speed on brake FRAME (1-based) of *RUN-BRAKE* after a run at SPEED: linear down to 0."
  (* speed (max 0.0 (- 1.0 (/ frame (float *run-brake*))))))

;;; ================================================================ the triangle (§3)
;;; Defender states the shell reports for a contact:
;;;   :neutral   idle, walk, any move, stun      :guard     guard up (held >= *GUARD-RAISE* f)
;;;   :breaker   Breaker aura / dash / strike startup (hit = counter-hit)
;;;   :stance-in entering a stance (counter-hit)  :stance   holding a stance (super armour)
;;;   :armor     a move's armour with hits left (:armor-hits: from move frame *ARMOR-FROM* to its startup's
;;;              end, or a Kikon rush's dash)   :invuln    Step / Hoho iframes, down, wake-up
(defun resolve-contact (def-state &key breaker guard-crush quick ignore-armor (in-front t) armor-vs-quick unguardable)
  "What one hit that touched the defender does. The attack: BREAKER (a Breaker strike),
GUARD-CRUSH (Breaker property on another move), QUICK (a Quick move), IGNORE-ARMOR (Nozarashi),
UNGUARDABLE (guard and stance don't stop it, Step / Hoho iframes still do; no move uses it now: the
Kikon rush's strike is guardable, KIKON-OUTCOME).
The defender: DEF-STATE (above), IN-FRONT (the attacker is inside his guard arc), ARMOR-VS-QUICK
(Bankai West). Returns
  NIL           no effect (invulnerable)
  :hit          damage + the move's reaction
  :counter      :hit with x*COUNTER-MULT* damage and +*COUNTER-STUN* frames
  :blocked      blockstun + pushback (+ chip)
  :guard-break  *GUARD-BREAK-STUN*
  :stance-break the stance crumples (*STANCE-BREAK-STUN*)
  :absorbed     the stance takes the damage, no reaction, and stores it
  :armored      damage, no reaction (a move's armour, or armour vs Quick); a Breaker, UNGUARDABLE and
                IGNORE-ARMOR go through a move's armour
Breaker vs Breaker is a CLASH, decided before any contact (BREAKER-CLASH-P)."
  (let ((crush (or breaker guard-crush))
        (state (cond ((and (eq def-state :guard) (not in-front)) :neutral)
                     ((and unguardable (member def-state '(:guard :stance-in :stance))) :neutral)
                     (t def-state))))
    (ecase state
      (:invuln nil)
      (:guard (if crush :guard-break :blocked))
      (:breaker :counter)
      (:stance-in (if breaker :stance-break :counter))
      (:stance (if breaker :stance-break :absorbed))
      (:armor (if (or breaker unguardable ignore-armor) :hit :armored))
      (:neutral (if (and quick armor-vs-quick (not ignore-armor) (not breaker)) :armored :hit)))))

(defun contact-of (res)
  "What a hit's RESOLVE-CONTACT result counts as for the attacker (design v2 §0, the contact rule):
:HIT only when it really landed (:hit :counter :guard-break :stance-break, and the Kikon); armour, a
stance absorb, a parry and a block are :BLOCK. Only :HIT opens the string's hit timing, the cancels
and a move's on-land hook; NIL (a whiff or iframes) stays NIL."
  (case res
    ((:hit :counter :guard-break :stance-break :kikon) :hit)
    ((nil) nil)
    (t :block)))

(defun breaker-clash-p (phase-a phase-b dist)
  "Both fighters' Breakers in :dash or :strike (strike startup/active) within *CLASH-RANGE*: CLASH
(both pushed *CLASH-PUSH*, no damage). Phases: :aura :dash :strike :recover or NIL."
  (and (member phase-a '(:dash :strike)) (member phase-b '(:dash :strike)) (<= dist *clash-range*) t))

(defun breaker-next-phase (phase frames held dist)
  "The Breaker's pre-strike state machine. PHASE :aura or :dash, FRAMES spent in it, HELD = the
button is still down, DIST to the opponent. Returns the phase for the next frame: the aura lasts
*BREAKER-AURA*; the dash lasts while held (at least *BREAKER-DASH-MIN*, at most *BREAKER-DASH-MAX*)
and becomes :strike as soon as the opponent is within *BREAKER-TRIGGER*."
  (ecase phase
    (:aura (if (>= frames *breaker-aura*) :dash :aura))
    (:dash (if (or (<= dist *breaker-trigger*) (>= frames *breaker-dash-max*)
                   (and (not held) (>= frames *breaker-dash-min*)))
               :strike :dash))))

(defun kikon-rush-next-phase (phase frames dist &key aura dash-max)
  "The Kikon rush's pre-strike state machine (the Breaker's without the hold: the button only
matters at the strike, KIKON-OUTCOME). PHASE :aura or :dash, FRAMES spent in it, DIST to the
opponent; AURA and DASH-MAX are the module's (its move :params). The aura lasts AURA frames, then the
strike if he is already within *KIKON-TRIGGER* or the module has no dash (DASH-MAX 0), else the dash;
the dash strikes within *KIKON-TRIGGER* or after DASH-MAX frames (its range)."
  (ecase phase
    (:aura (cond ((< frames aura) :aura) ((or (zerop dash-max) (<= dist *kikon-trigger*)) :strike) (t :dash)))
    (:dash (if (or (<= dist *kikon-trigger*) (>= frames dash-max)) :strike :dash))))

(defun kikon-rush-reach (speed dash-max)
  "How far a rush module reaches: its dash (SPEED m/s for DASH-MAX frames) + *KIKON-TRIGGER*."
  (+ *kikon-trigger* (* speed (/ dash-max 60.0))))

(defun breaker-speed (frames)
  "Dash speed after FRAMES of dashing: *BREAKER-SPEED-MIN* rising to *BREAKER-SPEED-MAX*."
  (+ *breaker-speed-min* (* (- *breaker-speed-max* *breaker-speed-min*)
                            (min 1.0 (/ frames (float *breaker-dash-max*))))))

;;; ================================================================ frame advantage (§3)
(defun blockstun (total hit-frame adv)
  "Blockstun that gives the move its block advantage ADV: the attacker's frames left after the
hit (TOTAL = S+A+R, hit on move frame HIT-FRAME) + ADV, at least 1. Timeline (both sides count the
same way, see MOVE-END-FRAME): the attacker idles on move frame TOTAL and acts on the step after;
the defender, blocking on the step of frame HIT-FRAME, idles STUN steps later and acts on the step
after. So he acts TOTAL - HIT-FRAME + ADV steps after the hit, the attacker TOTAL - HIT-FRAME:
ADV frames of advantage exactly."
  (max 1 (+ (- total hit-frame) adv)))

(defun move-end-frame (s a r whiff contact hitless)
  "Move frame on which a move with S / A / R ends (back to idle). R after a hit or block (CONTACT) or
for a move with no hit windows (HITLESS: its hits are hazards), else the whiff recovery WHIFF."
  (+ s a (if hitless r (recovery-frames r contact whiff))))

(defun hitstun (react &optional counter)
  "Stun frames of reaction REACT (*REACTION-FRAMES*), +*COUNTER-STUN* on a counter-hit."
  (+ (getf *reaction-frames* react 0) (if counter *counter-stun* 0)))

(defun recovery-frames (r contact &optional whiff)
  "Recovery actually played: R after a hit or block (CONTACT), else WHIFF (a move's own whiff
recovery, e.g. the Breaker's 30) or R + *WHIFF-EXTRA*."
  (if contact r (or whiff (+ r *whiff-extra*))))

(defun chain-open-p (sf s a r contact)
  "May the next hit of a string start at move frame SF? On :hit from the end of the active frames
(the string combos); on :block or a whiff (NIL) only in the last *CHAIN-LEAD* frames of recovery,
so a -2 string hit leaves a gap (Step / Hoho yes, Q1 no)."
  (let ((total (+ s a r)))
    (and (< sf total)
         (if (eq contact :hit) (>= sf (+ s a)) (>= sf (- total *chain-lead*))))))

(defun cancel-open-p (sf hit-frame total landed)
  "On-hit cancel window (SP1 / SP2 / Hoho from Quick/Flash strings, the Kikon rush from any other
landed move): the move
LANDED, from its first hit frame HIT-FRAME until its recovery ends (TOTAL)."
  (and landed (>= sf hit-frame) (< sf total)))

(defun invulnerable-frame-p (sf window)
  "Is move frame SF inside the inclusive iframe WINDOW (from to), e.g. *STEP-IFRAMES*?"
  (and window (<= (first window) sf (second window))))

;;; ================================================================ damage (§4)
(defun combo-scale (n)
  "Damage fraction of the Nth hit of a combo (1-based): 100 % for hits 1..*COMBO-FULL-HITS*, then
-*COMBO-DECAY* per hit, floored at *COMBO-FLOOR*."
  (if (<= n *combo-full-hits*)
      1.0
      (max *combo-floor* (- 1.0 (* *combo-decay* (- n *combo-full-hits*))))))

(defun cornered-mult (per lost cap)
  "Cornered passive: 1 + PER per Konpaku LOST, the bonus capped at CAP."
  (+ 1.0 (min cap (* per lost))))

(defun hit-damage (base atk-mods def-mods combo-index counter-hit)
  "Damage (integer, >= 1 for a damaging hit) of a hit with BASE damage. ATK-MODS, a plist of the
attacker's multipliers, all stacked multiplicatively: :mult (the form's: Hellfire 1.30, Bankai 1.20,
Nozarashi 1.15), :cornered / :cornered-max / :lost (Cornered: +per Konpaku lost, capped).
DEF-MODS: :mult on the defender's side (1 in v1). COMBO-INDEX: this hit's number in the combo
(1-based, COMBO-SCALE). COUNTER-HIT: x*COUNTER-MULT*."
  (if (<= base 0)
      0
      (max 1 (round (* base
                       (getf atk-mods :mult 1.0)
                       (cornered-mult (getf atk-mods :cornered 0.0) (getf atk-mods :lost 0)
                                      (getf atk-mods :cornered-max 0.0))
                       (getf def-mods :mult 1.0)
                       (combo-scale combo-index)
                       (if counter-hit *counter-mult* 1.0))))))

(defun chip-damage (dmg rate reishi)
  "Chip of a blocked hit worth DMG at chip fraction RATE (NIL = none) on a defender with REISHI:
chip never kills (leaves at least 1)."
  (if (or (null rate) (<= rate 0))
      0
      (max 0 (min (round (* dmg rate)) (1- reishi)))))

(defun burn-amount (max-reishi fraction-per-second step)
  "Reishi a form's burn takes on its STEPth frame (0-based): FRACTION-PER-SECOND of MAX-REISHI
spread over 60 steps in whole points, so a whole second burns exactly the rate (5 % of 1000 = 50)."
  (let ((per-second (round (* max-reishi fraction-per-second))))
    (- (floor (* per-second (1+ step)) 60) (floor (* per-second step) 60))))

(defun burn (reishi amount)
  "REISHI after a self-burn of AMOUNT (Hellfire, Ennetsu): never below 1."
  (if (<= reishi 1) reishi (max 1 (- reishi amount))))

;;; ================================================================ Kikon, Konpaku, time-up (§1)
(defun red-p (reishi max-reishi)
  "Red: Reishi below *RED-THRESHOLD* of max."
  (< reishi (* max-reishi *red-threshold*)))

(defun kikon-outcome (red held contact follow)
  "What a Kikon rush strike that connected with CONTACT (RESOLVE-CONTACT's result) leads to. The
strike is always guardable: guarded (blocked, absorbed, armoured, parried) or dodged, nothing more.
  :KIKON   it HIT a RED victim with the button still HELD on that step (guaranteed), or it is the
           FOLLOW-up and it hit: the Kikon (KIKON-RESULT)
  :FOLLOW  it hit a victim who is not red, the button held: a follow-up strike comes after his hitstun
           (*KIKON-FOLLOW-STUN*, then *KIKON-FOLLOW-GAP* frames free: he can guard or dodge it)
  NIL      guarded, whiffed, or the button released: a plain hit (maybe a Soul Break)"
  (when (member contact '(:hit :counter))
    (cond (follow :kikon)
          ((not held) nil)
          (red :kikon)
          (t :follow))))

(defun kikon-follow-wait (s)
  "Frames the rush waits (phase :follow) after its strike hit a non-red victim before the follow-up
strike (startup S) starts: it then hits *KIKON-FOLLOW-GAP* frames after the victim can act again."
  (max 0 (- (+ *kikon-follow-stun* 1 *kikon-follow-gap*) s)))

(defun soul-break-p (reishi) "Reishi reached 0: automatic Soul Break." (<= reishi 0))

(defun kikon-result (konpaku awakened soul-break)
  "Konpaku settled at connect time: a Kikon removes *KIKON-KONPAKU* (*KIKON-KONPAKU-AWAKENED* if the
attacker is AWAKENED); a SOUL-BREAK removes one more. Values: konpaku-left lost ko-p. After it the
victim's Reishi resets to max and both are placed by RESET-PLACEMENT."
  (let* ((lost (min konpaku (+ (if awakened *kikon-konpaku-awakened* *kikon-konpaku*)
                               (if soul-break *soul-break-extra* 0))))
         (left (- konpaku lost)))
    (values left lost (<= left 0))))

(defun time-up-winner (konpaku-0 reishi-0 max-0 konpaku-1 reishi-1 max-1)
  "Winner at time-up: 0 or 1 (the side with more Konpaku, then the higher Reishi %), or :DRAW."
  (cond ((> konpaku-0 konpaku-1) 0)
        ((< konpaku-0 konpaku-1) 1)
        ((> (* reishi-0 max-1) (* reishi-1 max-0)) 0)   ; integer cross-multiply: exact %
        ((< (* reishi-0 max-1) (* reishi-1 max-0)) 1)
        (t :draw)))

;;; ================================================================ gauges (§3, §5)
(defun gauge-add (g n max)
  "Gauge G after adding N (may be negative), kept in [0, MAX]."
  (max 0.0 (min max (+ g n))))

(defun reiatsu-gain (dealt taken &optional (frames 0))
  "Reiatsu earned by dealing DEALT and taking TAKEN damage, plus FRAMES of regen."
  (+ (* dealt *reiatsu-dealt*) (* taken *reiatsu-taken*) (* frames (/ *reiatsu-regen* 60.0))))

(defun awakening-gain (dealt taken lost)
  "Fighting Spirit earned by dealing / taking damage and losing LOST Konpaku."
  (+ (* dealt *awaken-dealt*) (* taken *awaken-taken*) (* lost *awaken-per-konpaku*)))

(defun spend-bars (reiatsu bars)
  "Spend BARS of Reiatsu. Values: reiatsu-after ok (NIL = not enough, nothing spent)."
  (let ((cost (* bars *reiatsu-bar*)))
    (if (>= reiatsu cost) (values (- reiatsu cost) t) (values reiatsu nil))))

(defun seconds->frames (s) (round (* s 60)))

(defun timer-fill (frames-left total-frames max)
  "Display value of a gauge that drains as a timer (Inferno in Hellfire, Awakening in a timed awakening)."
  (if (<= total-frames 0) 0.0 (* max (/ (float frames-left) total-frames))))

(defun hoho-allowed-p (stunned fs lockout-left)
  "Hoho needs *FS-HOHO* flash-step (FS), no block/hitstun (STUNNED) and the *HOHO-LOCKOUT* over."
  (and (not stunned) (>= fs *fs-hoho*) (<= lockout-left 0)))

(defun awaken-allowed-p (free gauge used)
  "Awaken: FREE (idle / walk / guard only), the gauge full, not USED yet this match."
  (and free (not used) (>= gauge *awaken-max*)))

(defun burst-allowed-p (in-hitstun combo-hits fs)
  "Burst Reverse: IN-HITSTUN (a grounded reaction or airborne, inputs not locked) after the
*BURST-MIN-HITS*th hit of the combo (COMBO-HITS), *FS-BURST* flash-step (FS). A Kikon connecting on
the same step wins (the shell applies a Burst only when no cinematic started)."
  (and in-hitstun (>= combo-hits *burst-min-hits*) (>= fs *fs-burst*)))

(defun fs-regen (fs idle)
  "Flash-step one frame later: +*FS-REGEN*/s once IDLE (frames since the last spend) reaches
*FS-DELAY*, capped at *FS-MAX*. (Damage taken adds *FS-TAKEN* per point: combat.lisp GAIN-GAUGES.)"
  (if (>= idle *fs-delay*) (min *fs-max* (+ fs (/ *fs-regen* 60.0))) fs))

;;; ---------------------------------------------------------------- the guard gauge (design v3 G.2)
(defun guard-value (kind adv &optional override)
  "The guard gauge a blocked hit drains: OVERRIDE (a hitwin's / move's :guard), else by the move KIND
(*GG-KIND*; NIL = a hazard, *GG-HAZARD*), + *GG-ENDER* for a Quick / Flash / Signature ender (block
advantage ADV <= *GG-ENDER-ADV*)."
  (or override
      (if kind
          (+ (getf *gg-kind* kind 0)
             (if (and (member kind '(:quick :flash :sig)) (integerp adv) (<= adv *gg-ender-adv*)) *gg-ender* 0))
          *gg-hazard*)))

(defun gg-drain (gg v)
  "The guard gauge GG after a drain of V. Values: new-gg crushed-p (it reached 0: GUARD CRUSH / guardless)."
  (let ((n (max 0.0 (- gg v)))) (values n (<= n 0.0))))

(defun gg-regen (gg idle guardless)
  "The guard gauge one frame later: nothing before *GG-DELAY* frames without a drain (IDLE), then
*GG-REGEN*/s (*GG-REGEN-GUARDLESS*/s while GUARDLESS), capped at *GG-MAX*. From 0: 285 f to full."
  (if (< idle *gg-delay*)
      gg
      (min *gg-max* (+ gg (/ (if guardless *gg-regen-guardless* *gg-regen*) 60.0)))))

(defun can-guard-p (gg guardless)
  "May a fighter guard? Not at gauge 0, and not while GUARDLESS (from 0 until the gauge is full again)."
  (and (> gg 0.0) (not guardless)))

;;; ---------------------------------------------------------------- stance (a Signature kind)
(defun stance-store (stored taken)
  "Damage stored by a stance after absorbing TAKEN: + TAKEN x *STANCE-STORE-RATE*, capped."
  (min *stance-store-cap* (+ stored (round (* taken *stance-store-rate*)))))

(defun stance-release (stored)
  "The stance cut. Values: damage (*STANCE-BASE-DAMAGE* + STORED) and crush-p (guard-crushing
when STORED >= *STANCE-CRUSH-AT*)."
  (values (+ *stance-base-damage* stored) (>= stored *stance-crush-at*)))

;;; ================================================================ combos (§3)
(defun combo-step (react airborne hits launches air-hits)
  "Book one more connected hit of a combo (counters reset when the victim returns to neutral).
REACT the move's reaction, AIRBORNE the victim's state, HITS / LAUNCHES / AIR-HITS the combo so
far. The combo limits turn REACT: a 2nd launch -> :knockback, the *COMBO-AIR-HITS*th airborne hit
or the *COMBO-CAP*th hit -> :knockdown. Values: react hits launches air-hits (the new HITS is this
hit's COMBO-INDEX for HIT-DAMAGE)."
  (let* ((hits (1+ hits))
         (air-hits (if airborne (1+ air-hits) air-hits))
         (react (cond ((>= hits *combo-cap*) :knockdown)
                      ((and airborne (>= air-hits *combo-air-hits*)) :knockdown)
                      ((and (eq react :launch) (>= launches *combo-launches*)) :knockback)
                      (t react))))
    (values react hits (if (eq react :launch) (1+ launches) launches) air-hits)))

;;; ================================================================ perfect Hoho (§3)
(defun threat-window-p (sf from to)
  "An opponent hit window [FROM, TO) of his move now at frame SF is active, or becomes active
within *PERFECT-LEAD* frames."
  (and (< sf to) (<= (- from sf) *perfect-lead*)))

(defun perfect-hoho-p (sf from to vols ax ay az fx fz tx ty tz tr th)
  "Is a Hoho started now PERFECT against the opponent's hit window [FROM, TO) with volumes VOLS
(his move at frame SF, him at (AX AY AZ) facing (FX 0 FZ))? THREAT-WINDOW-P and a volume overlaps
our hurt cylinder (TX TY TZ, radius TR, height TH) grown by *PERFECT-INFLATE*. Hazards: the shell
uses THREAT-WINDOW-P and a world-space test with the inflated cylinder. Floats: single-floats."
  (let ((r (+ tr (float *perfect-inflate* 1f0))) (h (+ th (float *perfect-inflate* 1f0))))
    (and (threat-window-p sf from to)
         (loop for v in vols thereis (vol-hit-p v ax ay az fx fz tx ty tz r h 0f0)))))

;;; ================================================================ CPU AI helpers (§8)
(defun band-weights (bands d)
  "The weight plist of the first distance band (LO HI . weights) of a kit's AI table with
LO <= D < HI, or NIL."
  (loop for (lo hi . weights) in bands
        when (and (>= d lo) (< d hi)) return weights))

(defun heat-range (lo hi heat)
  "Preferred range (LO HI) shrunk by anti-stall HEAT: -*AI-HEAT-RANGE* m per point, never below
*AI-MIN-RANGE*. Values: lo hi."
  (let ((cut (* heat *ai-heat-range*)))
    (values (max *ai-min-range* (- lo cut)) (max *ai-min-range* (- hi cut)))))

(defun heat-breaker-mult (heat)
  "Breaker weight factor: 2 once HEAT reaches *AI-HEAT-BREAKER*."
  (if (>= heat *ai-heat-breaker*) 2 1))

(defun ai-burst-wanted-p (reishi reishi-max next-hit)
  "Is a Burst worth its bars to the CPU? Below *AI-BURST-LOW* of its Reishi, or the NEXT-HIT
(estimated: the combo's average hit so far) would put it in red."
  (or (< reishi (* *ai-burst-low* reishi-max)) (red-p (- reishi next-hit) reishi-max)))

(defun ai-guard-mult (gg guardless)
  "How much of its guard chance a CPU uses at guard gauge GG: all of it at >= 50 %, half at 25-50 %,
0.15 below, none when it can't guard (CAN-GUARD-P)."
  (cond ((not (can-guard-p gg guardless)) 0.0)
        ((>= gg (* 0.5 *gg-max*)) 1.0)
        ((>= gg (* 0.25 *gg-max*)) 0.5)
        (t 0.15)))

(defun ai-hoho-spare-p (fs reishi reishi-max)
  "Flash-step budgeting: may a CPU spend a Hoho on a routine dodge? It needs *FS-HOHO*, and while a
Burst would be worth it (below *AI-BURST-LOW* of its Reishi) it keeps *FS-BURST* on top."
  (>= fs (+ *fs-hoho* (if (< reishi (* *ai-burst-low* reishi-max)) *fs-burst* 0.0))))

(defun heat-after (heat far)
  "Heat one frame later: +*AI-HEAT-RATE* per second, twice that when FAR (beyond *AI-HEAT-FAR*).
Dealing damage resets it to 0 (combat.lisp DEAL-DAMAGE)."
  (+ heat (* (if far 2.0 1.0) (/ *ai-heat-rate* 60.0))))
