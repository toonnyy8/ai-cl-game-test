;;;; components.lisp — every kind of data a SOUL DUEL entity can carry (DEFCOMPONENT, engine/lisp/ecs.lisp).
;;;; What an entity is follows from its components:
;;;;
;;;;   a fighter        transform motion model blade fighter gauges pilot   (+ brain when the CPU plays it)
;;;;   a hazard         hazard                     (fire wave, Shiranui, pillars, line cuts, Kaka)
;;;;   a skeleton       hazard transform model     (a hazard with a body: Bankai South)
;;;;
;;;; "Human vs CPU" is only "has a BRAIN or not": BRAIN-SYSTEM (ai.lisp) writes the same PILOT vpad a
;;;; keyboard does. Systems and their order: main.lisp. Fighters hold each other by handle
;;;; (FIGHTER-OPP); hazards hold their owner. Check (ENTITY-ALIVE-P e) before following a handle.
(in-package :duel)

(defcomponent transform
  "Where an entity is: feet position (x y z metres, y up) and facing (yaw radians; 0 faces -Z)."
  (pos (make-f32 3) :type f32vec)
  (yaw 0f0 :type single-float))

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
  (hide nil)                            ; body part tags not drawn (:eyepatch)
  (tint nil) (rim nil)                  ; mirror match: P2's tint / rim
  (flash 0f0 :type single-float)        ; real seconds of hit flash left
  (super 0f0 :type single-float)        ; real seconds of the SP rim-light "super flash" left
  (alpha 1f0 :type single-float))       ; < 1 = vanishing (Hoho)

(defcomponent blade
  "The sword ribbon (engine MAKE-TRAIL layout): sampled in the draw while a move is active.
(Not named TRAIL: its constructor would be MAKE-TRAIL, the engine's.)"
  (points (make-trail) :type f32vec))

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
  (phase nil)                           ; :move → :hold :aura :dash :main; :stun → the reaction kind
  (move nil)                            ; the MOVE (kit.lisp) while in :move
  (button nil)                          ; the vpad button that started the move (holds, releases)
  (hold 0 :type fixnum)                 ; frames in the pre-strike phase (hold / aura / dash)
  (hits 0 :type fixnum)                 ; bitmask: hit windows of the current move that connected
  (contact nil)                         ; what the move's hits did: NIL (whiff) :hit :block
  (land-sf -1 :type fixnum)             ; move frame of the first connect (cancel windows open)
  (dmg-bonus 0 :type fixnum)            ; added to the move's damage (stance: stored)
  (crush nil)                           ; this move now crushes guard (stance >= 150, SP2 held)
  (stun 0 :type fixnum)                 ; frames the reaction / blockstun lasts
  (block-adv 0 :type fixnum)            ; block advantage of the last melee hit blocked (CPU punish)
  (freeze 0 :type fixnum)               ; frames this fighter alone is frozen (super freeze)
  (lock 0 :type fixnum)                 ; frames inputs are ignored (reset neutral, perfect Hoho victim)
  (freeze-next 0 :type fixnum) (lock-next 0 :type fixnum)   ; set by the opponent during FIGHTER-SYSTEM,
                                        ; applied after both stepped (no side acts first)
  (hoho-lock 0 :type fixnum)            ; frames until the next Hoho is allowed
  (guard-t 0 :type fixnum)              ; frames Guard has been held (raised at *GUARD-RAISE*)
  (stored 0 :type fixnum)               ; stance: damage absorbed
  (charge 0 :type fixnum)               ; hold frames when a charge move was released (Shiranui)
  (perfect nil)                         ; this Hoho was perfect: its counter strike is pending
  (burst nil)                           ; a Burst Reverse was pressed this step (applied after both stepped)
  (invuln 0 :type fixnum)               ; frames of invulnerability left (after a Burst)
  (ox 0f0 :type single-float) (oz 0f0 :type single-float)   ; the opponent at the start of this step
  (dist 0f0 :type single-float)         ; ... and the distance to him
  ;; as a victim: the running combo (reset when back to neutral)
  (combo-hits 0 :type fixnum) (combo-launches 0 :type fixnum) (combo-air 0 :type fixnum)
  (combo-dmg 0 :type fixnum)
  ;; HUD (sim frames)
  (callout nil) (callout-t 0 :type fixnum))

(defcomponent gauges
  "A fighter's numbers (design-v1 §1, §3, §5) and his match stats."
  (reishi *reishi-max* :type fixnum) (reishi-max *reishi-max* :type fixnum)
  (konpaku *konpaku-max* :type fixnum)
  (reiatsu 0f0 :type single-float)      ; 0..300 (3 bars)
  (awaken 0f0 :type single-float)       ; Fighting Spirit 0..100
  (awakened nil)                        ; the awakening of this match is used
  (evolution nil)                       ; EVOLUTION was announced
  (meter 0f0 :type single-float)        ; the kit meter (Inferno)
  (form-left 0 :type fixnum)            ; frames left in a timed form (Hellfire)
  (form-total 0 :type fixnum)
  (burn-step 0 :type fixnum)            ; frames of the current form's burn so far
  ;; results
  (dealt 0 :type fixnum) (kikons 0 :type fixnum) (perfects 0 :type fixnum) (best-combo 0 :type fixnum))

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
  (act nil) (why nil)                   ; the last thing it decided and why (debug overlay, log)
  (off nil))                            ; debug: this CPU does nothing

(defcomponent hazard
  "A hit that is not a fighter's melee: fire wave, Shiranui, Ennetsu pillars, line cuts (looks only),
Kaka skeletons. World-space volume + a HITWIN (kit.lisp) for the hit itself. KIND picks its update,
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
  (look nil)                            ; look keyword for the draw (:sun :meteor :crack ...)
  (last nil))                           ; skeleton: the last one (its hit stuns longer)

;;; ---------------------------------------------------------------- small helpers every file uses
(declaim (inline pos-of yaw-of))
(defun pos-of (e) (transform-pos (transform e)))
(defun yaw-of (e) (transform-yaw (transform e)))
(defun opp-of (e) (fighter-opp (fighter e)))
(defun kit-of (e) (fighter-kit (fighter e)))
(defun state-of (e) (fighter-state (fighter e)))
(defun side-name (e) (if (zerop (fighter-side (fighter e))) "P1" "P2"))
(defun cpu-p (e) (and (brain e) t))
(defun passive-p (e p) "Does E's current form have passive P (:armor-vs-quick :projectile-cut :ignore-armor)?"
  (member p (kit-passives (kit-of e))))

(defvar *combat-log* nil
  "Dev logging: moves, hits, reactions, Kikons (CLOG lines). The first Module._debug_cmd turns it on.")
(defmacro clog (fmt &rest args)
  "Combat log line \"[tick] ...\" while *COMBAT-LOG* is on (arguments aren't evaluated otherwise)."
  `(when *combat-log* (log-msg ,(concatenate 'string "[~6d] " fmt) *match-tick* ,@args)))

(declaim (type fixnum *match-tick*))
(defvar *match-tick* 0 "Fixed steps since the battle began (determinism hash, logs).")
