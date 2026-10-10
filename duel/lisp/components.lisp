;;;; components.lisp — every kind of data a SOUL DUEL entity can carry (DEFCOMPONENT, engine/lisp/ecs.lisp).
;;;; What an entity is follows from its components:
;;;;
;;;;   a fighter        transform motion model blade fighter gauges pilot   (+ brain when the CPU plays it;
;;;;                    + ics / sjs / lbs: Ichigo's / Senjumaru's / Lille's state, defined in their files)
;;;;   a hazard         hazard                     (fire wave, Shiranui, pillars, line cuts, Kaka)
;;;;   a South hand     hazard transform model     (a hazard with a body: a look of Bankai South)
;;;;
;;;; "Human vs CPU" is only "has a BRAIN or not": BRAIN-SYSTEM (ai.lisp) writes the same PILOT vpad a
;;;; keyboard does. Systems and their order: main.lisp. Fighters hold each other by handle
;;;; (FIGHTER-OPP); hazards hold their owner. Check (ENTITY-ALIVE-P e) before following a handle.
(in-package :duel)

;; TRANSFORM (feet position + facing; POS-OF / YAW-OF) is the engine's (engine/lisp/ecs.lisp).

(defcomponent motion
  "How a fighter's body moves (FIGHTER-PHYSICS): walk / dash velocity, a knockback slide, airborne."
  (vel (make-f32 3) :type f32vec)       ; m/s (x z walking or dashing; y while airborne)
  (kb (make-f32 3) :type f32vec)        ; slide, metres per frame (x z): knockback, pushback, Step
  (kb-left 0 :type fixnum)              ; slide frames left
  (grounded t))

(defcomponent model
  "What is drawn: the body (body.lisp), its animation, the posed joints and per-draw looks."
  (body nil)
  (anim (make-anim))
  (joints (make-f32 (* +nj+ 16)) :type f32vec)   ; +NJ+ world matrices, filled by POSE-FK! in the draw
  (weapon nil)                          ; weapon key in the right hand, NIL = none
  (hide nil)                            ; body part tags not drawn: NIL or a HIDE-SET (fighter.lisp REFRESH-LOOK)
  (tint nil) (rim nil)                  ; mirror match: P2's tint / rim
  (flash 0f0 :type single-float)        ; real seconds of hit flash left
  (super 0f0 :type single-float)        ; real seconds of the SP rim-light "super flash" left
  (alpha 1f0 :type single-float)        ; < 1 = vanishing (Hoho): the body is not drawn (its afterimage is)
  ;; drawn motion (docs/style/STYLE_STORM_DESIGN.md §2.6; effect seconds, cosmetic: the sim never reads them)
  (hold 0f0 :type single-float)         ; > 0: the pose is held (ANIM-EVAL skipped), e.g. an attacker on a heavy hit
  (smear 0f0 :type single-float)        ; > 0: the squash / stretch smear drawing (1 frame)
  (smear-dir (make-f32 2) :type f32vec) ; its direction on the ground (x z, unit)
  (ghost (make-f32 (* +nj+ 16)) :type f32vec)   ; the Hoho afterimage: the joints at the vanish
  (ghost-age -1f0 :type single-float)   ; effect seconds since the vanish (< 0 = none)
  ;; Phase 5 looks (docs/style/STYLE_STORM_DESIGN.md §2.5 faces, §4; cosmetic)
  (face :neutral)                       ; a held expression (:neutral :shout :hurt) while FACE-T > 0 (else chosen by state)
  (face-t 0f0 :type single-float)       ; effect seconds the held FACE lasts
  (beat 0f0 :type single-float)         ; effect seconds left of the head-thrown-back overlay (cup 3's entry: the grin)
  (flare 0f0 :type single-float)        ; effect seconds left of the garb's flare (a warded hit, SHONETSU's tell)
  (last-sf -1 :type fixnum)             ; the move frame the last draw saw (draw-side move beats: Nadegiri's cut)
  ;; Phase 6 looks (cosmetic)
  (face-was :neutral)                   ; the expression drawn last frame (FACE-ACCENT)
  (looks (make-f32 2) :type f32vec)     ; [0] 0..1 the left fist held on the handle (GRIP-STEP), [1] the fx clock when
                                        ; FACE-WAS last changed (an f32vec: set every frame at 0 B)
  (t3 0 :type fixnum))                  ; cup-3 entries this match (the first gets the full pillar, later ones half)

(defcomponent blade
  "The sword ribbon (engine MAKE-TRAIL layout): sampled in the draw while a move is active.
(Not named TRAIL: its constructor would be MAKE-TRAIL, the engine's.)"
  (points (make-trail) :type f32vec)
  (smear (make-f32 12) :type f32vec))    ; the comet smear held for the current drawing (vfx.lisp VFX-SMEAR)

(defcomponent fighter
  "One side of the duel: its kit (character + form), state machine and combo bookkeeping.
States (fighter.lisp): :idle (stand / walk / strafe) :guard :guard-hit (blockstun) :step :run
(Step held: phase :run / :brake) :hoho :move :stun (flinch stagger knockback guard-break crumple clash) :air (launched / knocked down)
:down :wakeup :cine (a cinematic owns it) :intro :win :lose."
  (side 0 :type fixnum)                 ; 0 = P1, 1 = P2
  (opp nil)                             ; the opponent's handle
  (character nil) (form :base) (kit nil)
  (state :idle)
  (sf 0 :type fixnum)                   ; frames in the state; in :move the move frame (0 = first)
  (phase nil)                           ; :move → :hold :aura :dash :follow :main; :stun → the reaction kind
  (move nil)                            ; the MOVE (kit.lisp) while in :move
  (button nil)                          ; the vpad button that started the move (holds, releases)
  (hold 0 :type fixnum)                 ; frames in the pre-strike phase (hold / aura / dash / follow)
  (follow nil)                          ; this Kikon rush strike is the follow-up (its hit = the Kikon)
  (armor-left 0 :type fixnum)           ; hits the move's armour may still take (:armor-hits)
  (kikon-n 2 :type fixnum)              ; Konpaku his current Kikon rush is worth (the kit's, read at rush start)
  (cd (make-array 7 :element-type 'fixnum :initial-element 0) :type (simple-array fixnum (7)))
                                        ; frames each *KIT-COMMANDS* slot (7 of them) still cools down (kept through resets)
  (hits 0 :type fixnum)                 ; bitmask: hit windows of the current move that connected
  (contact nil)                         ; what the move's hits did: NIL (whiff) :hit :block
  (queued nil)                          ; the latch: the J / K link (:q / :f) pressed during this string link
                                        ; (fires when its chain opens after contact; dropped on a whiff)
  (chained nil)                         ; this move is a string follow-up link started by the latch: an earlier link of
                                        ; the string touched him, so it chases (STRING-CHASE) and carries the gate
  (land-sf -1 :type fixnum)             ; move frame of the first connect (cancel windows open)
  (dmg-bonus 0 :type fixnum)            ; added to the move's damage (stance: stored)
  (crush nil)                           ; this move now crushes guard (stance >= 150, SP2 held)
  (stun 0 :type fixnum)                 ; frames the reaction / blockstun lasts
  (glock nil)                           ; blockstun: the guard lock holds him (his attacker may still chain; GUARD-LOCK-OF)
  (block-adv 0 :type fixnum)            ; block advantage of the last melee hit blocked (CPU punish)
  (freeze 0 :type fixnum)               ; frames this fighter alone is frozen (super freeze)
  (lock 0 :type fixnum)                 ; frames inputs are ignored (reset neutral, perfect Hoho victim)
  (freeze-next 0 :type fixnum) (lock-next 0 :type fixnum)   ; set by the opponent during FIGHTER-SYSTEM,
                                        ; applied after both stepped (no side acts first)
  (hoho-lock 0 :type fixnum)            ; frames until the next Hoho is allowed
  (guard-t 0 :type fixnum)              ; frames Guard has been held (raised at *GUARD-RAISE*)
                                        ; (Bankai West: frames in the ward, which is up at *GUARD-RAISE*)
  (warded -1 :type fixnum)              ; the tick his ward (Bankai West) last blocked a hit (the CPU's reversal)
  (stored 0 :type fixnum)               ; stance: damage absorbed
  (charge 0 :type fixnum)               ; hold frames when a charge move was released (Shiranui)
  (perfect nil)                         ; this Hoho was perfect: its counter strike is pending
  (assist-next nil)                     ; the assist pressed for him: the next move / Hoho he starts is assisted (assist.lisp)
  (assisted nil)                        ; the current move is assisted: x*ASSIST-MULT* damage
  (end-chase nil)                       ; this move started off a J / K ender's hit (or ORANGE's restart): it chases (ENDER-PUSH)
  (gc-left 0 :type fixnum)              ; frames a guard cancel still keeps attacks out (COMMAND!: its recovery's rest)
  (burst nil)                           ; the burst mode pressed this step (:white :blue :orange; applied after both stepped)
  (chain 0 :type fixnum)                ; ORANGE: frames the next move started still has its startup cut
  (invuln 0 :type fixnum)               ; frames of invulnerability left (after a Burst)
  (step-open nil)                       ; this Step's iframes ended early (a kit's shot from it: Lille II, DUEL_LILLE_V2 V9l)
  (ox 0f0 :type single-float) (oz 0f0 :type single-float)   ; the opponent at the start of this step
  (dist 0f0 :type single-float)         ; ... and the distance to him
  (run-yaw 0f0 :type single-float)      ; the run's heading (he faces the opponent; this is where he goes)
  ;; as a victim: the running combo (reset when back to neutral)
  (combo-hits 0 :type fixnum) (combo-launches 0 :type fixnum) (combo-air 0 :type fixnum)
  (combo-dmg 0 :type fixnum)
  (frost 0 :type fixnum)                ; frames of frost left: walk and run x*FROST-SLOW* (Rukia's ice, rules FROST-NEXT)
  ;; HUD (sim frames)
  (callout nil) (callout-t 0 :type fixnum))

(defcomponent gauges
  "A fighter's numbers (design-v1 §1, §3, §5) and his match stats."
  (reishi *reishi-max* :type fixnum) (reishi-max *reishi-max* :type fixnum)
  (konpaku *konpaku-max* :type fixnum)
  (reiatsu 0f0 :type single-float)      ; 0..300 (3 bars): SPs
  (fs *fs-max* :type single-float)      ; flash-step 0..100: Hoho, Burst (kept through resets)
  (fs-idle 0 :type fixnum)              ; frames since the last flash-step spend
  (burst nil)                           ; the running burst: :white :blue :orange, NIL = none (it drains FS to 0)
  (burst-t 0 :type fixnum)              ; frames it has run (WHITE's integer Reishi regen)
  (awake-regen 0 :type fixnum)          ; frames left of the awakening's WHITE-like regen (overlaps a burst)
  (awake-t 0 :type fixnum)              ; frames it has run (its integer Reishi regen)
  (gg *gg-max* :type single-float)      ; guard gauge 0..100 (full again at every reset)
  (gg-idle 0 :type fixnum)              ; frames since the last guard drain
  (guardless nil)                       ; the guard gauge hit 0: no guard until it is full again
  (awaken 0f0 :type single-float)       ; Fighting Spirit 0..100
  (awakened nil)                        ; the awakening of this match is used
  (evolution nil)                       ; EVOLUTION was announced
  (meter 0f0 :type single-float)        ; the kit meter (Inferno, NOME)
  (meter-idle 0 :type fixnum)           ; frames since NOME last grew (RYOTE's drain waits for it)
  (form-left 0 :type fixnum)            ; frames left in a timed form (Hellfire)
  (form-total 0 :type fixnum)
  (burn-step 0 :type fixnum)            ; frames of the current form's burn so far
  (arm-pending nil)                     ; Kenpachi's Bankai: the arm's last pip went: the move running then (:NONE = none),
                                        ; until the burst fires (rules BURST-DUE-P); NIL = none pending
  (arm-owed nil)                        ; Kenpachi's Bankai: the J / K string he is in owes its one pip (charged when it ends)
  (taken-melee 0 :type fixnum) (taken-ranged 0 :type fixnum)   ; damage taken from blades / ranged hits (the CPU's
                                        ; :awaken rule: Rukia awakens against a melee opponent, ai.lisp AI-AWAKEN-P)
  (froze nil)                           ; this absolute-zero visit's freeze-touch is spent (Rukia; cleared entering zero)
  (stun 0f0 :type single-float)         ; the hidden hit-stun (rules STUN-ADD / STUN-DECAY; no HUD)
  (stun-idle 0 :type fixnum)            ; frames since it last grew
  ;; results
  (dealt 0 :type fixnum) (kikons 0 :type fixnum) (perfects 0 :type fixnum) (best-combo 0 :type fixnum)
  (counters 0 :type fixnum)             ; counter-hits dealt (the learning CPU's gate rows)
  (evo-t -1 :type fixnum))              ; *MATCH-TICK* of the first EVOLUTION (-1 none; the gate's "duel evo" line)

(defcomponent pilot
  "Who drives the fighter: a vpad (engine input.lisp). A human's has a device READER; the CPU's brain
writes it. CAM-RELATIVE: the stick is camera-relative (humans); else it is already
(strafe, toward) relative to the opponent (the CPU)."
  (vpad (new-vpad) :type vpad)
  (cam-relative t))

(defcomponent brain
  "The CPU player (ai.lisp): delayed perception, the current intent, anti-stall heat, the button it
is holding. Identity comes from the kit's :AI tables."
  (difficulty :normal)
  (delay 14 :type fixnum)               ; perception delay, frames
  (ring (make-array 32) :type simple-vector)   ; SNAPs of the opponent, one per step
  (head 0 :type fixnum)
  (intent :approach) (intent-t 0 :type fixnum)
  (heat 0f0 :type single-float)
  (strafe 1f0 :type single-float) (strafe-t 0 :type fixnum)
  (press nil) (press-mod nil) (press-left 0 :type fixnum)  ; button being held and for how long
  (decide-t 0 :type fixnum)             ; frames until the next neutral decision
  (roll-key -1 :type fixnum)            ; the opponent move start the reflex rolls were made for
  (guard-roll 1f0 :type single-float) (hoho-roll 1f0 :type single-float)   ; this event's rolls
  (react-roll 1f0 :type single-float)   ; (1 = never)
  (was :idle)                           ; its fighter's state at the previous step (block punish)
  (break-key -1 :type fixnum)           ; the guard episode the Breaker roll was made for
  (burst-t 0 :type fixnum) (burst-rolled nil)   ; frames in a combo past its 2nd hit; the Burst roll made
  (dash 0f0 :type single-float) (dash-to 0f0 :type single-float)   ; a held dash: +1 toward / -1 away, until this distance
  (bankai-rolled nil)                   ; the Bankai entry roll of this cup-3 stay is made (ai.lisp AI-BANKAI-P)
  (aim-key -1 :type fixnum) (aim-plan nil) (aim-t -1 :type fixnum)   ; :opp-aim: the aim rolled for (his move's start tick),
                                        ; its answer (:hoho :rush :step NIL) and a pre-Step's tick (-1: on the perceived lock)
  (reflect-key -1 :type fixnum) (reflect-go nil)   ; :opp-reflect: the move rolled for (its start tick), the roll said yes
  (act nil) (why nil)                   ; the last thing it decided and why (debug overlay, log)
  (learn nil)                           ; the learning CPU (ai-learn.lisp LRN; NIL = off: nothing of it runs)
  (habit nil)                           ; debug: a scripted player's habit (debug.lisp HABIT-FIRE)
  (jkey -1 :type fixnum) (jstarts nil)  ; his last perceived J's start; the ticks his J's started (AI-MASH-P)
  (off nil))                            ; debug: this CPU does nothing

(defcomponent hazard
  "A hit that is not a fighter's melee: fire wave, Shiranui, Ennetsu pillars, line cuts (looks only),
South's bind and hands. World-space volume + a HITWIN (kit.lisp) for the hit itself. KIND picks its update,
its volume test and its look (hazards.lisp)."
  (kind nil)
  (owner nil)                           ; the fighter whose hit this is
  (x 0f0 :type single-float) (y 0f0 :type single-float) (z 0f0 :type single-float)
  (px 0f0 :type single-float) (pz 0f0 :type single-float)   ; position last step (projectile sweep)
  (yaw 0f0 :type single-float)
  (speed 0f0 :type single-float) (turn 0f0 :type single-float)   ; m/s, homing rad/frame
  (size 0f0 :type single-float)         ; radius / half-width / length, per kind
  (age 0 :type fixnum) (life 0 :type fixnum) (delay 0 :type fixnum)   ; frames
  (hits-left 1 :type fixnum) (rehit 0 :type fixnum)   ; hits it may still deal; frames to the next
  (hw nil)                              ; the HITWIN it deals (NIL = a look only)
  (src nil)                             ; T: a hit comes from the owner's position (a guard facing him blocks it)
  (fragile nil)                         ; T: it closes while it waits if its owner is hit (CLOSE-RIFTS)
  (hook nil) (data nil)                 ; a character's own hazard: HOOK (h hz event ...) and the DATA it keeps (hazards.lisp)
  (group nil)                           ; NIL, or a hit group shared by several hazards (MAKE-HIT-GROUP): they hit once together
  (look nil))                           ; a look keyword, or a draw function symbol (HAZARD-DRAW)

;;; ---------------------------------------------------------------- small helpers every file uses
(defun opp-of (e) (fighter-opp (fighter e)))
(defun kit-of (e) (fighter-kit (fighter e)))
(defun state-of (e) (fighter-state (fighter e)))
(defun side-name (e) (if (zerop (fighter-side (fighter e))) "P1" "P2"))
(defun cpu-p (e) (and (brain e) t))
(defun passive-p (e p)
  "Does E's current form have passive P (:ward :pierce :projectile-cut :scorch :cut :drink)?"
  (and (member p (kit-passives (kit-of e))) t))

(declaim (special *p1* *p2*))                           ; (flow.lisp's)
(defmacro do-sides ((e) &body body)
  "Run BODY with E bound to P1's fighter handle, then to P2's (no alive check: keep that at the site). BODY is written
out twice: keep it to a call or two."
  `(progn (let ((,e *p1*)) ,@body) (let ((,e *p2*)) ,@body)))

;;; The gate's pacing counters (debug.lisp's per-match "duel ichigo / senju / lille ..." lines): off in play.
(defvar *pacing-log* nil "T while the gate runs (START-CVC sets it): PACE counts; else PACE does nothing.")
(defvar *pacing* (vector nil nil) "Per side (0 P1, 1 P2): a plist of pacing keys -> counts this match.")
(defmacro pace (e key &optional (n 1))
  "Add N to fighter E's pacing count KEY while *PACING-LOG* is on (KEY and N are not evaluated otherwise)."
  `(when *pacing-log* (incf (getf (svref *pacing* (fighter-side (fighter ,e))) ,key 0) ,n)))
(defun pacing-reset () "A gate match starts (START-CVC): both sides' counts empty." (fill *pacing* nil))

(defvar *combat-log* nil
  "Dev logging: moves, hits, reactions, Kikons (CLOG lines). The first Module._debug_cmd turns it on.")
(defmacro clog (fmt &rest args)
  "Combat log line \"[tick] ...\" while *COMBAT-LOG* is on (arguments aren't evaluated otherwise)."
  `(when *combat-log* (log-msg ,(concatenate 'string "[~6d] " fmt) *match-tick* ,@args)))

(declaim (type fixnum *match-tick*))
(defvar *match-tick* 0 "Fixed steps since the battle began (determinism hash, logs).")

;;; ONE-HAND (onehand.lisp), declared here because fighter.lisp and flow.lisp read them
(defvar *touch* (make-touch) "P1's gesture recogniser (engine/lisp/touch.lisp).")
(defvar *one-hand* nil "The current match is ONE-HAND (VS CPU, portrait, the thumb deck).")
(defvar *hand* :right "HAND setting: :RIGHT (default) or :LEFT (the deck mirrored). Saved by the page.")
(defvar *coarse* nil "The page reports a touch-first device ((pointer: coarse)).")
(defvar *back-press* nil "The browser's back (the history trap of duel/web/pwa.js) fired this frame.")
