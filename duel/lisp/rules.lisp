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
  (let ((d (hypot x z)))
    (if (<= d r) (values x z) (values (* x (/ r d)) (* z (/ r d))))))

(defun stick-toward-strafe (sx sy cam-yaw px pz ox oz)
  "Opponent-relative movement (§2): stick (SX right, SY up) read through a camera with yaw CAM-YAW
(camera-relative, like any third-person game) and converted for a fighter at (PX PZ) whose
opponent stands at (OX OZ). Values: TOWARD (+ = at the opponent) and STRAFE (+ = to the fighter's
right while he faces the opponent). One code path for every camera."
  (let* ((fx (fwd-x cam-yaw)) (fz (fwd-z cam-yaw))
         (wx (+ (* sy fx) (* sx (- fz))))            ; camera right = (-fz, fx)
         (wz (+ (* sy fz) (* sx fx)))
         (ax (- ox px)) (az (- oz pz)) (d (hypot ax az)))
    (if (< d 1e-4)
        (values sy sx)
        (let ((ux (/ ax d)) (uz (/ az d)))
          (values (+ (* wx ux) (* wz uz)) (+ (* wx (- uz)) (* wz ux)))))))

(defun toward-strafe-dir (toward strafe px pz ox oz)
  "The inverse of STICK-TOWARD-STRAFE's projection: world direction (values dx dz) of moving
TOWARD / STRAFE relative to the opponent at (OX OZ)."
  (let* ((ax (- ox px)) (az (- oz pz)) (d (max 1e-4 (hypot ax az)))
         (ux (/ ax d)) (uz (/ az d)))
    (values (+ (* toward ux) (* strafe (- uz))) (+ (* toward uz) (* strafe ux)))))

(defun in-front-p (yaw px pz ax az arc-deg)
  "Is the point (AX AZ) within the ARC-DEG wide cone in front of a fighter at (PX PZ) facing YAW?
Guard uses *GUARD-ARC* (200 deg)."
  (let* ((dx (- ax px)) (dz (- az pz)) (d (hypot dx dz)))
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
  (let* ((dx (- bx ax)) (dz (- bz az)) (d (hypot dx dz))
         (h (/ *reset-distance* 2.0)))
    (if (< d 1e-3) (setf dx 0.0 dz 1.0) (setf dx (/ dx d) dz (/ dz d)))
    (values (* dx (- h)) (* dz (- h)) (* dx h) (* dz h))))

(defun step-direction (toward strafe &optional (neutral -1.0))
  "Step direction (values toward strafe, unit length): the stick's, or straight back when the
stick is neutral. NEUTRAL 1.0: straight at the opponent instead (the run)."
  (let ((m (hypot toward strafe)))
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
;;;   :parry     a parry move inside *PARRY-WINDOW* (Bankai West's GOKUI GAESHI)
;;; Bankai West's ward (passive :ward) reports :guard in his free states and own moves (fighter.lisp DEFENDER-STATE)
(defun resolve-contact (def-state &key breaker guard-crush (in-front t) unguardable hazard ward rend)
  "What one hit that touched the defender does. The attack: BREAKER (a Breaker strike),
GUARD-CRUSH (Breaker property on another move),
UNGUARDABLE (guard, stance, armour and a parry don't stop it, Step / Hoho iframes still do: the South
bind; the Kikon rush's strike is guardable, KIKON-OUTCOME), HAZARD (a projectile / ground hit: a parry
doesn't catch it; a :ranged hit window counts as one).
The defender: DEF-STATE (above), IN-FRONT (the attacker is inside his guard arc; armour covers every
side), WARD (Bankai West's ward: his guard covers 360 deg, and a hazard in his parry's window is blocked, not a hit).
REND (Kenpachi's Bankai, docs/duel/DUEL_KEN_BANKAI.md): armour and a stance don't stop it (armour -> a hit, a stance -> a
stance break, like a Breaker); a guard, the ward and a parry still do. Returns
  NIL           no effect (invulnerable)
  :hit          damage + the move's reaction
  :counter      :hit with x*COUNTER-MULT* damage and +*COUNTER-STUN* frames
  :blocked      blockstun + pushback (+ chip)
  :guard-break  *GUARD-BREAK-STUN*
  :stance-break the stance crumples (*STANCE-BREAK-STUN*)
  :absorbed     the stance takes the damage, no reaction, and stores it
  :armored      damage, no reaction (a move's armour); a Breaker and
                UNGUARDABLE go through it (nothing ignores armour)
  :parried      caught by a parry: no damage; the attacker staggers and the parry counters (a Breaker
                breaks it: :stance-break; a hazard or UNGUARDABLE hits)
Breaker vs Breaker is a CLASH, decided before any contact (BREAKER-CLASH-P)."
  (let* ((crush (or breaker guard-crush))
         (state (cond ((and (eq def-state :guard) (not in-front) (not ward)) :neutral)
                     ((and unguardable (member def-state '(:guard :stance-in :stance :parry))) :neutral)
                     ((and hazard (eq def-state :parry)) (if ward :guard :neutral))
                     (t def-state))))
    (ecase state
      (:invuln nil)
      (:parry (if breaker :stance-break :parried))
      (:guard (if crush :guard-break :blocked))
      (:breaker :counter)
      (:stance-in (if (or breaker rend) :stance-break :counter))
      (:stance (if (or breaker rend) :stance-break :absorbed))
      (:armor (if (or breaker unguardable rend) :hit :armored))
      (:neutral :hit))))

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

(defun parry-frame-p (sf &optional window)
  "Is move frame SF of a parry move inside its WINDOW (lo hi), inclusive (the move's :params :window), else the shared
*PARRY-WINDOW* (it catches a melee hit: RESOLVE-CONTACT :parry)?"
  (invulnerable-frame-p sf (or window *parry-window*)))

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
  "May the next link of a string start at move frame SF? Only after CONTACT (the string gate, docs/duel/DUEL_STRINGS.md
§2.2): this link's own :hit / :block, or T when it is a follow-up link (an earlier link of the string touched him, so
the string carries on even if this one whiffed); NIL (link 1 whiffed) never chains. On :hit from the end of the active
frames (the string combos); otherwise (:block, or T) only in the last *CHAIN-LEAD* frames of recovery, so a -2 link
leaves a gap (Step / Hoho yes, J1 no)."
  (let ((total (+ s a r)))
    (and contact (< sf total)
         (if (eq contact :hit) (>= sf (+ s a)) (>= sf (- total *chain-lead*))))))

(defun string-chase-speed (d reach left &optional (cap *chase-max*))
  "The follow-up link's chase (docs/duel/DUEL_STRINGS.md §2.2): the speed (m/s, toward him) in its startup at distance D
with LEFT frames to its hit, so it arrives *CHASE-MARGIN* inside its REACH (never nearer than *LUNGE-STOP*) exactly as
the hit window opens: no faster than CAP (*CHASE-MAX*; *ENDER-CHASE-MAX* off a pushing ender), 0 once he is that close. Each frame covers at most the gap left, so it
never passes or overshoots him."
  (let ((goal (max *lunge-stop* (- reach *chase-margin*))))
    (if (and (> d goal) (> left 0))
        (min cap (* 60.0 (/ (- d goal) left)))
        0.0)))

(defun ray-room (x z ux uz r)
  "How far a point (X Z) inside the circle of radius R may move along the unit vector (UX UZ) before it reaches the
circle (0 when it is already on or outside it): the arena's room for a push (PUSH-APART)."
  (let* ((b (+ (* x ux) (* z uz))) (c (- (+ (* x x) (* z z)) (* r r))) (disc (- (* b b) c)))
    (if (or (>= c 0) (< disc 0)) 0.0 (max 0.0 (+ (- b) (sqrt disc))))))

(defun cancel-open-p (sf hit-frame total landed)
  "On-hit cancel window (SP1 / SP2 / Hoho / a :cancel L from any J / K link, the O ender from a link-3 hit): the move
LANDED, from its first hit frame HIT-FRAME until its recovery ends (TOTAL)."
  (and landed (>= sf hit-frame) (< sf total)))

(defun guard-cancel-open-p (sf s a r contact &optional quick)
  "The guard cancel: may a move with S / A / R whose own hit landed (CONTACT :hit; a whiff never; a block only for a
QUICK (J) move, the user 2026-10-02: J and guard trade places fast) end in a guard at move frame SF? From the frame
*GUARD-CANCEL* of its recovery is left (the last floor(R x *GUARD-CANCEL*) frames) to its end."
  (let ((total (+ s a r)))
    (and (or (eq contact :hit) (and quick (eq contact :block)))
         (>= sf (- total (floor (* r *guard-cancel*)))) (< sf total))))

;; ---------------------------------------------------------------- the guard lock (the user 2026-09-30)
(defun guard-locked-p (def-state was chain-left state phase sf s a r touched more)
  "The guard lock (docs/duel/DUEL_DESIGN.md \"Guard lock\"): does a defender in blockstun (DEF-STATE :guard-hit) stay there,
guarding and unable to act, once his blockstun would end, because his attacker may still chain? Judged after both
stepped, for the defender's next step. The attacker: ORANGE's window open (CHAIN-LEFT > 0) while he is free (STATE
:idle / :guard: the next move he starts is the chain); or in a :move (PHASE, move frame SF of S / A / R) that TOUCHED him
(a hit or a block, or it is a string follow-up) with MORE it may still start (a J / K link, an L link, an on-hit cancel,
ORANGE) and a frame left to start it on (SF + 1 < S + A + R: CHAIN-OPEN-P / CANCEL-OPEN-P end there); or, WAS locked
last step, a follow-up he just started that has not passed its active frames (its pre-strike PHASE, or SF < S + A). The
escapes (a BLUE burst, the awakening) leave blockstun, so the lock is over. Hazards never hold it."
  (and (eq def-state :guard-hit)
       (or (and (plusp chain-left) (member state '(:idle :guard)))
           (and (eq state :move)
                (or (and was (or (not (eq phase :main)) (< sf (+ s a))))
                    (and touched more (< (1+ sf) (+ s a r))))))
       t))

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
attacker's multipliers, all stacked multiplicatively: :mult (the form's: Hellfire 1.30, RYOTE 1.15, x(1 + k) of
Bankai East's pierce), :cornered / :cornered-max / :lost (Cornered: +per Konpaku lost, capped).
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

;;; ---------------------------------------------------------------- Bankai East's pierce (docs/duel/DUEL_YAMA_REWORK.md)
(defun pierce-rate (gg &optional (mult 1.0))
  "East's pierce k at guard gauge GG: *PIERCE-MIN* (empty) .. *PIERCE-MAX* (full), x a move's :pierce-mult MULT
(KYOKKO 2.0). A hit deals x(1 + k); a blocked hit lets k x its damage through as chip (CHIP-DAMAGE: never kills)."
  (* mult (+ *pierce-min* (* (- *pierce-max* *pierce-min*) (/ gg *gg-max*)))))

(defun cast-point (px pz tx tz range)
  "Where a cast aimed from (PX PZ) at a target at (TX TZ) lands: on the target, or RANGE along the line
when he is farther (South's bind). Values: x z."
  (let* ((dx (- tx px)) (dz (- tz pz)) (d (hypot dx dz)))
    (if (<= d range) (values tx tz) (values (+ px (* dx (/ range d))) (+ pz (* dz (/ range d)))))))

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

;;; ---------------------------------------------------------------- KOSEI (攻勢), the aggression reward (docs/duel/DUEL_STRINGS.md §5)
(defun kosei-mult (gg)
  "KOSEI's multiplier at the attacker's guard gauge GG: 1 + *KOSEI-BONUS* x (1 - GG / *GG-MAX*), x1 full .. x3 empty."
  (+ 1.0 (* *kosei-bonus* (- 1.0 (/ gg *gg-max*)))))

(defun kosei-gain (g gg)
  "What one paying contact of guard value G earns an attacker at guard gauge GG. Values: Reiatsu, flash-step, the
multiplier."
  (let ((m (kosei-mult gg)))
    (values (* *kosei-reiatsu* g m) (* *kosei-fs* g m) m)))

;;; ================================================================ Kikon, Konpaku, time-up (§1)
(defun red-p (reishi max-reishi)
  "Red: Reishi below *RED-THRESHOLD* of max."
  (< reishi (* max-reishi *red-threshold*)))

(defun kikon-outcome (held contact follow)
  "What a Kikon rush strike that connected with CONTACT (RESOLVE-CONTACT's result) leads to. The first
strike is always guardable: guarded (blocked, absorbed, armoured, parried) or dodged, nothing more.
  :FOLLOW  it hit with the button still HELD on that step: the victim is knocked back *KIKON-FOLLOW-KB* into
           a short stagger and the rusher dashes in after him (phase :follow, KIKON-FOLLOW-WAIT) to the
           follow-up strike: guardable during the dash unless he is red (KIKON-FOLLOW-UNGUARDABLE-P)
  :KIKON   it is that FOLLOW-up and it hit: the Kikon (KIKON-RESULT)
  NIL      guarded, whiffed, or the button released: a plain hit (maybe a Soul Break)"
  (when (member contact '(:hit :counter))
    (cond (follow :kikon)
          (held :follow))))

(defun kikon-follow-unguardable-p (red)
  "The follow-up strike (the Kikon) on a RED victim can't be guarded (guard, stance, armour, a parry); on one
who isn't red a guard held during the dash blocks it. Iframes dodge it either way."
  (and red t))

(defun kikon-follow-wait (s)
  "Frames the rush dashes in (phase :follow) after its strike hit, the button held, before the follow-up
strike (startup S) starts: it then hits *KIKON-FOLLOW-GAP* frames after a non-red victim can act again."
  (max 0 (- (+ *kikon-follow-stun* 1 *kikon-follow-gap*) s)))

(defun kikon-follow-stun (red s)
  "The follow-up's victim reels this long (after the knockback): *KIKON-FOLLOW-STUN* (then he is free for
*KIKON-FOLLOW-GAP* frames to guard or dodge the strike), or, RED, until the strike (startup S) has landed:
the Kikon is certain unless something stops the rusher."
  (if red (+ (kikon-follow-wait s) s 2) *kikon-follow-stun*))

(defun kikon-follow-speed (dist frames-left cap)
  "The dash-in's speed (m/s) this frame: arrive at *KIKON-TRIGGER* from DIST exactly when the FRAMES-LEFT
of the wait run out, never faster than the module's CAP."
  (if (<= dist *kikon-trigger*) 0.0 (min cap (* 60.0 (/ (- dist *kikon-trigger*) (max 1 frames-left))))))

(defun soul-break-p (reishi) "Reishi reached 0: automatic Soul Break." (<= reishi 0))

(defun kikon-result (konpaku count soul-break)
  "Konpaku settled at connect time: a Kikon removes COUNT (the attacker's kit :kikon-konpaku, read when his
rush started: *KIKON-KONPAKU* 2, awakened *KIKON-KONPAKU-AWAKENED* 3, Nozarashi's cups 2 / 3 / 4); a SOUL-BREAK
removes one more (COUNT is then the attacker's KIKON-WORTH: his form's count, KESSA's by his clones); a Kikon never more than *KIKON-MAX-EVENT*, a Soul
Break never more than *SOUL-BREAK-MAX-EVENT* (the user's decision 2026-09-27). Values: konpaku-left lost ko-p. After it
the victim's Reishi resets to max and both are placed by RESET-PLACEMENT."
  (let* ((lost (min konpaku (if soul-break *soul-break-max-event* *kikon-max-event*)
                    (+ count (if soul-break *soul-break-extra* 0))))
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

(defun hit-gains (dealt taken siphoned &optional (mult 1.0))
  "What dealing DEALT / taking TAKEN damage pays (combat.lisp GAIN-GAUGES). Values: his Reiatsu, flash-step and Fighting
Spirit, then the Reiatsu and flash-step of the side SIPHONED says takes his gains (the opponent's kit's :siphon hook): he
keeps none of them, his Reiatsu and flash-step go to that side, the Fighting Spirit is lost. MULT scales the Reiatsu and
Fighting Spirit of the DEALT part (ORANGE: BURST-GAIN-MULT)."
  (let ((r (+ (* mult dealt *reiatsu-dealt*) (reiatsu-gain 0 taken))) (fs (* taken *fs-taken*)))
    (if siphoned
        (values 0.0 0.0 0.0 r fs)
        (values r fs (+ (* mult (awakening-gain dealt 0 0)) (awakening-gain 0 taken 0)) 0.0 0.0))))

(defun gauge-move (from amount to max)
  "Take up to AMOUNT out of gauge FROM (never below 0) into gauge TO (kept at most MAX): values FROM and TO after. TO gets
what was really taken, not AMOUNT."
  (let ((took (max 0.0 (min from amount))))
    (values (- from took) (gauge-add to took max))))

(defun spend-bars (reiatsu bars)
  "Spend BARS of Reiatsu. Values: reiatsu-after ok (NIL = not enough, nothing spent)."
  (let ((cost (* bars *reiatsu-bar*)))
    (if (>= reiatsu cost) (values (- reiatsu cost) t) (values reiatsu nil))))

(defun seconds->frames (s) (round (* s 60)))

(defun play-ticks (match-seconds frames-left)
  "A match's length in frames without its cinematics: the frames its MATCH-SECONDS timer ran down to FRAMES-LEFT (a
cinematic stops the timer). The user, 2026-10-08: 「毀魂技演出不計入對戰時長」 (every cinematic)."
  (- (* 60 match-seconds) (max 0 frames-left)))

(defun timer-fill (frames-left total-frames max)
  "Display value of a gauge that drains as a timer (Inferno in Hellfire, Awakening in a timed awakening)."
  (if (<= total-frames 0) 0.0 (* max (/ (float frames-left) total-frames))))

(defun bankai-allowed-p (free konpaku)
  "Kenpachi's Bankai (docs/duel/DUEL_KEN_BANKAI.md §1.1): P in a form with :bankai-form (cup 3), FREE as for the first
awakening (fighter.lisp AWAKEN-STATE-P: idle, guard, blockstun, a combo reaction past the Burst's hit; DRINK included;
the user 2026-10-09, DUEL_KEN_REWORK §7) with at most *BANKAI-KONPAKU* of his own KONPAKU left (the user's decision
2026-09-28; it was: red). No gauge; once a match by construction (no later form has :bankai-form)."
  (and free (<= konpaku *bankai-konpaku*) t))

;;; ---------------------------------------------------------------- the arm meter UDE (Kenpachi's Bankai)
(defun pip-spend (pips)
  "Spend one of PIPS (a pip command's frame 0). Values: pips-after ok (NIL at 0: the command is refused)."
  (if (>= pips 1) (values (1- pips) t) (values pips nil)))

(defun pip-step (pips idle locked)
  "The crack clock one frame later: IDLE (frames since the last spend or crack) counts unless LOCKED (the reset's
neutral); at *ARM-CRACK* a pip cracks by itself. Values: pips idle cracked-p."
  (cond (locked (values pips idle nil))
        ((and (plusp pips) (>= (1+ idle) *arm-crack*)) (values (1- pips) 0 t))
        (t (values pips (min 9999 (1+ idle)) nil))))

(defun string-pip-due-p (owed state kind)
  "Is the pip a J / K string owes charged now (the playtest decision 2026-09-28: one pip per string, charged when it
ends)? OWED: a K link or the O ender ran in it. It is charged once he is out of the string: anything but a move of KIND
:quick / :flash (a link) or :kikon (the O ender; a neutral O can't start inside a string)."
  (and owed (not (and (eq state :move) (member kind '(:quick :flash :kikon)))) t))

(defun burst-due-p (pending current state)
  "Does the pending arm burst fire now? PENDING: the move running when the last pip went (:NONE = none; NIL = no
burst pending). It waits while he is still in that move (the 4th strike comes out in full, a Kikon rush started
earlier finishes) and while he is in a reaction, blockstun, the air, down, waking up, a Hoho or a cinematic (STATE);
any later move is interrupted by it (a masher can't dodge it)."
  (and pending
       (not (member state '(:stun :guard-hit :air :down :wakeup :hoho :cine :intro :win :lose)))
       (not (and (eq state :move) (eq current pending)))
       t))

;;; ---------------------------------------------------------------- Rukia (docs/duel/DUEL_RUKIA.md): frost, the temperature
(defun frost-next (cur n)
  "The frost timer after a real hit that frosts N frames: max(CUR, N), capped at *FROST-CAP* (it never stacks)."
  (min *frost-cap* (max cur n)))

(defun frost-speed (speed frost)
  "Walk / run SPEED of a fighter with FROST frames of frost left: x *FROST-SLOW* while it lasts."
  (if (plusp frost) (* speed *frost-slow*) speed))

(defun optic-p (ward optic ranged)
  "Does a hit bypass the defender's ward (Rukia's absolute zero, passive :optic)? A RANGED hit (a hazard, a :ranged window
beyond its :melee-range) on a WARD with OPTIC: it lands as on an open defender (the canon's optical loophole)."
  (and ward optic ranged t))

(defun temp-next (c guarding warm)
  "Her cold C one frame later, clamped to 0 .. *COLD-MAX*: GUARDING (the GUARD HOLD test, or bracing at zero) cools her
*RU-COOL-RATE* per second, else she warms WARM per second (the band's)."
  (max 0.0 (min *cold-max* (if guarding (+ c (/ *ru-cool-rate* 60.0)) (- c (/ warm 60.0))))))

(defun temp-band (c band)
  "The band cold C asks for, from BAND (:m18 :m50 :zero): two stacked bars with hysteresis by bars (the user's decision
2026-09-28). -18 -> -50 at C >= *COLD-BAR*; -50 -> -18 at C <= 0; -50 -> zero at C >= *COLD-MAX*; zero -> -50 at C <=
*COLD-BAR* (several steps at once when C jumped)."
  (ecase band
    (:m18 (cond ((>= c *cold-max*) :zero) ((>= c *cold-bar*) :m50) (t :m18)))
    (:m50 (cond ((>= c *cold-max*) :zero) ((<= c 0) :m18) (t :m50)))
    (:zero (cond ((<= c 0) :m18) ((<= c *cold-bar*) :m50) (t :zero)))))

(defun temp-band-at (c band state)
  "The band after this step (the combo band lock, the user's decision 2026-09-28): while she is in a combo (any STATE but
free: :idle :guard :run) BAND holds, so every link, the K -> L chain, the O ender and an SP cancel play the band the
string began in; once free, the band cold C asks for (TEMP-BAND: several at once, -273 with C 0 -> -18)."
  (if (member state '(:idle :guard :run)) (temp-band c band) band))

(defun cold-ok-p (c cost combo)
  "May a move costing COST cold start at cold C? Outside a combo only with the cost in hand; inside one (COMBO: a chained
follow-up) on credit while any cold is left (the overdraft: C > 0, the spend clamps at 0)."
  (or (>= c cost) (and combo (> c 0))))

(defun temp-cool-frames (c)
  "Frames of guarding from cold C to the next band's entry (a full bar)."
  (ceiling (- (if (< c *cold-bar*) *cold-bar* *cold-max*) c) (/ *ru-cool-rate* 60.0)))

(defun field-k (away frosted)
  "The cold field's factor on the away part of a walk / run (already x*FROST-SLOW* when FROSTED): AWAY, but the two
together never below *FIELD-FLOOR*."
  (if frosted (max away (/ *field-floor* *frost-slow*)) away))

(defun field-velocity (vx vz ux uz k)
  "A walk / run velocity (VX VZ) inside her field: only its part along (UX UZ), the unit vector from her to him (moving
away), is scaled by K; approaching and strafing are untouched. Values vx vz."
  (let ((a (* (- 1.0 k) (max 0.0 (+ (* vx ux) (* vz uz))))))
    (values (- vx (* a ux)) (- vz (* a uz)))))

(defun field-step (dist toward s)
  "A Step's DIST inside her field: TOWARD = cos of the angle between the hop and the way to her; a straight back Step x
S, a diagonal one part of it, a side Step (TOWARD 0) or one toward her untouched."
  (* dist (- 1.0 (* (- 1.0 s) (max 0.0 (- toward))))))

(defun hoho-allowed-p (stunned fs lockout-left &optional bursting)
  "Hoho needs *FS-HOHO* flash-step (FS; during a burst, BURSTING, any FS > 0: the burst modes), no block/hitstun
(STUNNED) and the *HOHO-LOCKOUT* over."
  (and (not stunned) (if bursting (> fs 0.0) (>= fs *fs-hoho*)) (<= lockout-left 0)))

(defun hoho-cost (fs bursting)
  "Flash-step a Hoho spends: *FS-HOHO*, or during a burst what is left of it when less (the gauge to 0 ends the burst)."
  (if bursting (min fs *fs-hoho*) *fs-hoho*))

(defun awaken-allowed-p (free gauge used)
  "Awaken: FREE (idle / walk / guard only), the gauge full, not USED yet this match."
  (and free (not used) (>= gauge *awaken-max*)))

(defun burst-mode (state locked combo-hits chain-open)
  "The burst a press would start from fighter STATE (docs/duel/DUEL_DESIGN.md \"Burst modes\"), or NIL: never while LOCKED;
:BLUE in a reaction / airborne past the combo's *BURST-MIN-HITS*th hit (COMBO-HITS) or in blockstun; :ORANGE in a move
whose own hit landed, while its cancel window is open (CHAIN-OPEN: the shell's CANCEL-OPEN-P); :WHITE free (idle / walk,
guard, run)."
  (unless locked
    (case state
      ((:stun :air) (and (>= combo-hits *burst-min-hits*) :blue))
      (:guard-hit :blue)
      (:move (and chain-open :orange))
      ((:idle :guard :run) :white))))

(defun burst-allowed-p (mode fs active)
  "May a burst start: a MODE (BURST-MODE), none ACTIVE, *FS-BURST* flash-step (FS: every mode, the user's two bars). A
Kikon connecting on the same step wins (the shell applies a burst only when no cinematic started)."
  (and mode (not active) (>= fs *fs-burst*)))

(defun burst-drain (fs)
  "Flash-step one frame into a running burst: -*BURST-DRAIN*/s, never below 0 (at 0 the burst ends)."
  (max 0.0 (- fs (/ *burst-drain* 60.0))))

(defun burst-fs-gain (gain mode)
  "The flash-step a GAIN pays while burst MODE runs: nothing (no gain of any kind during a burst)."
  (if mode 0.0 gain))

(defun burst-heal (n rate)
  "Integer points a per-second RATE pays on frame N (1-based) of a burst: the whole points crossed on that frame."
  (- (floor (* n rate) 60) (floor (* (1- n) rate) 60)))

(defun burst-gain-mult (mode) "Reiatsu / awakening from hits dealt x this in burst MODE (ORANGE's *ORANGE-GAIN*)." (if (eq mode :orange) *orange-gain* 1.0))

(defun chain-startup-cut (s enter)
  "ORANGE's startup cut: frames skipped at the start of a move of startup S entered on frame ENTER: *CHAIN-CUT* of its
startup, leaving at least 1 f."
  (max 0 (min (floor (* *chain-cut* (- s enter))) (- s enter 1))))

(defun kikon-refund (fs reiatsu)
  "A Kikon connected (or a Soul Break, since 2026-09-30): its user's flash-step and Reiatsu after the refund (*KIKON-FS-REFUND*, *KIKON-REIATSU-REFUND*),
clamped. Values: fs reiatsu."
  (values (gauge-add fs *kikon-fs-refund* *fs-max*) (gauge-add reiatsu *kikon-reiatsu-refund* *reiatsu-max*)))

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

(defun gg-regen (gg idle guardless guarding &optional blue (mult 1.0))
  "The guard gauge one frame later: nothing while GUARDING (GUARD HOLD) or before *GG-DELAY* frames without a
drain (IDLE), then *GG-REGEN*/s (*GG-REGEN-GUARDLESS*/s while GUARDLESS), capped at *GG-MAX*. Bankai West's ward
counts as guarding (combat.lisp GAUGE-SYSTEM): he refills only in East. In a BLUE burst there is no delay and the rate
is x*BLUE-GG-MULT*, x*BLUE-GG-GUARDING* while guarding. MULT: the form's :gg-regen (Bankai East's *EAST-GG-REGEN*), not while guardless."
  (let ((rate (/ (if guardless *gg-regen-guardless* (* mult *gg-regen*)) 60.0)))
    (cond (blue (min *gg-max* (+ gg (* rate (if guarding *blue-gg-guarding* *blue-gg-mult*)))))
          ((or guarding (< idle *gg-delay*)) gg)
          (t (min *gg-max* (+ gg rate))))))

(defun gg-idle-next (idle guarding)
  "GUARD HOLD: the refill delay counter (frames since the last drain) one frame later: frozen while GUARDING
(:guard / :guard-hit), not restarted, so a guard released picks up where it left off."
  (if guarding idle (min 9999 (1+ idle))))

(defun can-guard-p (gg guardless)
  "May a fighter guard? Not at gauge 0, and not while GUARDLESS (from 0 until the gauge is full again)."
  (and (> gg 0.0) (not guardless)))

;;; ---------------------------------------------------------------- NOME: Nozarashi's three-cup ladder (v2)
;;; A kit meter with a :ladder: ((form drain/s delay-f up-at down-below) ...), one rung per kit form, cup 1 first.
(defun nome-gain (dealt taken drunk gains)
  "NOME from DEALT, TAKEN and DRUNK damage points at the kit's GAINS plist (:dealt :taken :drunk)."
  (+ (* dealt (getf gains :dealt 0.0)) (* taken (getf gains :taken 0.0)) (* drunk (getf gains :drunk 0.0))))

(defun meter-drain (nome rate delay idle)
  "NOME one frame later at a rung draining RATE per second once IDLE (frames since the last gain) reaches
DELAY (0 = always: NOMIHOSE drains even while he drinks); never below 0."
  (if (and (plusp rate) (>= idle delay)) (max 0.0 (- nome (/ rate 60.0))) nome))

(defun ladder-rung (nome rung ladder)
  "The rung (index into LADDER) for NOME from RUNG: up while NOME reaches the next rung's up-at, down while
it is below this rung's down-below (hysteresis; several steps at once: 0 at the top rung is cup 1)."
  (let ((i rung) (n (length ladder)))
    (loop while (and (< (1+ i) n) (>= nome (fourth (nth (1+ i) ladder)))) do (incf i))
    (loop while (and (> i 0) (< nome (fifth (nth i ladder)))) do (decf i))
    i))

(defun ranged-hit-p (hazard flags melee-range d2)
  "Is a hit ranged (not the attacker's own blade: a parry can't catch it)? A HAZARD's always; a window with :ranged in FLAGS unless its move's
MELEE-RANGE covers the defender (D2: his squared distance from the attacker): the blade near, the line / crack beyond.
One window decides it per hit, so a hit never lands twice."
  (and (or hazard (and (member :ranged flags) (not (and melee-range (<= d2 (* melee-range melee-range)))))) t))

(defun drink-split (dmg)
  "DRINK: a drunk hit worth DMG. Values: the half he takes (rounded up: real damage) and the half the
cleaver drinks."
  (values (ceiling dmg 2) (floor dmg 2)))

(defun drink-adv (adv)
  "The attacker's advantage after a drunk melee hit of block advantage ADV: ADV - *DRINK-ADV* (Q1 -2 -> -6,
enders -12 -> -16): the drinker's blockstun is shorter, so a drunk string leaves gaps and every ender is
punishable, but his own 10 f R-Q1 only trades into the next hit."
  (- adv *drink-adv*))

(defun cut-value (v kind &optional (mult *cut-mult*))
  "The cut: the guard gauge a blocked hit of move KIND drains when its attacker has the :cut passive: V x MULT
(rounded) for :flash :sig :sp, else V."
  (if (member kind '(:flash :sig :sp)) (round (* v mult)) v))

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
far. The combo limits turn REACT: a 2nd launch -> :knockback, the *COMBO-AIR-HITS*th airborne hit -> :knockdown (no
hit-count cap since the user 2026-09-30: the hidden stun tolerance ends long combos). A :bind (South) only opens a combo: on a victim already in one it
is a :flinch; as the opener it books *BURST-MIN-HITS* hits, so the bound victim may Burst at once.
Values: react hits launches air-hits (the new HITS is this hit's COMBO-INDEX for HIT-DAMAGE)."
  (let* ((bind (and (eq react :bind) (zerop hits)))
         (hits (if bind *burst-min-hits* (1+ hits)))
         (air-hits (if airborne (1+ air-hits) air-hits))
         (react (cond (bind :bind)
                      ((eq react :bind) :flinch)
                      ((and airborne (>= air-hits *combo-air-hits*)) :knockdown)
                      ((and (eq react :launch) (>= launches *combo-launches*)) :knockback)
                      (t react))))
    (values react hits (if (eq react :launch) (1+ launches) launches) air-hits)))

;;; ================================================================ the hidden hit-stun tolerance (DUEL_DESIGN.md)
(defun stun-weight (react heavy)
  "The stun points of a connected hit with written reaction REACT (*STUN-WEIGHTS*, any other 1); HEAVY (an SP / Kikon-rush
strike) is worth at least :heavy."
  (max (getf *stun-weights* react 1) (if heavy (getf *stun-weights* :heavy 3) 0)))

(defun stun-add (stun react heavy) "STUN after one more connected hit (STUN-WEIGHT)." (+ stun (stun-weight react heavy)))

(defun stun-decay (stun idle)
  "STUN one frame later, IDLE frames after the last hit: -*STUN-DECAY* per second from *STUN-DELAY*, never below 0."
  (if (>= idle *stun-delay*) (max 0.0 (- stun (/ *stun-decay* 60.0))) stun))

(defun stun-over-p (stun tolerance) "Is STUN past TOLERANCE (the hit that did it is the blow-away)?" (> stun tolerance))

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

;;; ---------------------------------------------------------------- :x-axis lines (DUEL_LILLE §11.3, gap G1 / G8)
(defun line-dist (ax az yaw a b tx tz)
  "Distance on the ground from (TX TZ) to the segment A .. B metres along facing YAW from (AX AZ): a :cap volume's axis
(hitvol.lisp CAP without its height), so how far a fighter's feet are from a line hit."
  (let* ((fx (fwd-x (float yaw 1f0))) (fz (fwd-z (float yaw 1f0))) (dx (- tx ax)) (dz (- tz az))
         (along (+ (* dx fx) (* dz fz))) (s (max a (min b along)))
         (ex (- tx (+ ax (* fx s)))) (ez (- tz (+ az (* fz s)))))
    (hypot ex ez)))

(defun line-off-strafe (ax az yaw px pz ox oz)
  "The strafe (+1.0 / -1.0: the CPU stick's x, relative to the opponent at (OX OZ), TOWARD-STRAFE-DIR) that takes a fighter
at (PX PZ) off the line through (AX AZ) along facing YAW, away from it: to the side he is on already (exactly on it: +1)."
  (let* ((fx (fwd-x (float yaw 1f0))) (fz (fwd-z (float yaw 1f0))) (dx (- px ax)) (dz (- pz az))
         (along (+ (* dx fx) (* dz fz))) (lx (- dx (* along fx))) (lz (- dz (* along fz))))
    (if (>= (+ (* lx (- pz oz)) (* lz (- ox px))) 0) 1.0 -1.0)))   ; (lateral . strafe direction (-uz, ux), u to him)

(defun opp-chance (p difficulty)
  "A chance P read off the opponent's kit (:opp-aim, :opp-reflect) at DIFFICULTY: x *AI-OPP-DIFF*, at most 1."
  (min 1.0 (* p (getf *ai-opp-diff* difficulty 1.0))))

(defun reflect-action (now blast guard)
  "The planned reflect (:opp-reflect) at his move frame NOW (as perceived) of a blast at frame BLAST: :guard (GUARD: a guard
is up to it) pressed *AI-REFLECT-GUARD-LEAD* before the blast, else :hoho *AI-REFLECT-HOHO-LEAD* before; :wait in the
*AI-REFLECT-QUIET* frames before that press; :late past the blast; else NIL (not yet)."
  (let ((at (- blast (if guard *ai-reflect-guard-lead* *ai-reflect-hoho-lead*))))
    (cond ((> now blast) :late)
          ((>= now at) (if guard :guard :hoho))
          ((>= now (- at *ai-reflect-quiet*)) :wait))))

(defun heat-after (heat far)
  "Heat one frame later: +*AI-HEAT-RATE* per second, twice that when FAR (beyond *AI-HEAT-FAR*).
Dealing damage resets it to 0 (combat.lisp DEAL-DAMAGE)."
  (+ heat (* (if far 2.0 1.0) (/ *ai-heat-rate* 60.0))))
