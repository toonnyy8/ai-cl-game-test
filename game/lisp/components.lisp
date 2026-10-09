;;;; components.lisp — every kind of data a RAVEN EDGE entity can carry (DEFCOMPONENT: see the header
;;;; of engine/lisp/ecs.lisp). An entity is only a handle; what it *is* follows from its components:
;;;;
;;;;   REN            transform motion model health fighter blade-trail player
;;;;   an enemy       transform motion model health fighter blade-trail brain
;;;;   a dummy        the enemy set + dummy                                   (training scene)
;;;;   a projectile   transform projectile                           (kunai, blast kunai, blade wave)
;;;;
;;;; Systems (player.lisp, enemy.lisp, projectiles.lisp, combat.lisp ...) visit the entities that have
;;;; the components they need; the order they run in is the list in main.lisp.
;;;; Entities hold each other by handle (a fighter's TARGET, a projectile's OWNER, *BOSS*). A handle
;;;; outlives its entity safely: every getter then returns NIL, so check (ENTITY-ALIVE-P e) or the
;;;; getter's result before following one. *PLAYER* is REN's handle.
;;;;
;;;; Not entities: particles, rain, debris, rings and trail vertices. There are thousands of them and
;;;; they carry a few floats each, so they live in the engine's flat float pools (engine/lisp/fx.lisp,
;;;; game/c/world.c), which cost nothing per item. Entities are for game objects.
(in-package :raven)

(defvar *player* nil "REN's entity handle.")

;; TRANSFORM (position + facing; POS-OF / YAW-OF) is the engine's (engine/lisp/ecs.lisp).

(defcomponent motion
  "How a body moves: velocity, knockback push, gravity and ground contact (PHYSICS-STEP, combat.lisp)."
  (vel (make-f32 3) :type f32vec)       ; m/s
  (kb (make-f32 3) :type f32vec)        ; knockback, metres per frame (x z); dodges keep their direction here
  (kb-left 0f0 :type single-float)      ; knockback frames left
  (grounded t)
  (air-t 0f0 :type single-float)        ; seconds airborne
  (grav 1f0 :type single-float)         ; gravity multiplier
  (grav-t 0f0 :type single-float))      ; frames the multiplier lasts (0 = until landing)

(defcomponent model
  "What is drawn: the body type (bodies.lisp), its animation and the posed joint matrices."
  (body nil)
  (anim (make-anim))
  (joints (make-f32 (* +nj+ 16)) :type f32vec)   ; +NJ+ world matrices, filled by POSE-UPDATE
  (hidden 0 :type fixnum)               ; bitmask of joints not drawn (lost limbs, Mirage vanish)
  (flash 0f0 :type single-float))       ; real seconds of hit flash left

(defcomponent health
  "Hit points, poise (resistance to flinching) and invulnerability."
  (alive t)
  (hp 60f0 :type single-float)
  (max-hp 60f0 :type single-float)
  (poise 0f0 :type single-float)
  (poise-t 0f0 :type single-float)      ; frames since the last poise hit (full regen at 90)
  (invuln 0f0 :type single-float)       ; frames of invulnerability left
  (bar-t 0f0 :type single-float))       ; HUD: seconds to keep showing the enemy's HP bar

(defcomponent fighter
  "A combatant's state machine: state, current move and its frame, hit log, target."
  (name "")                             ; combat-log name: "REN", "RAINBLADE#3"
  (team :enemy)                         ; :player or :enemy (who can hit whom)
  (state :idle)                         ; :idle :run :move :flinch :knockdown ... (see player.lisp / combat.lisp)
  (sf 0f0 :type single-float)           ; frames in the current state (advances by time scale)
  (phase 0 :type fixnum)                ; sub-phase of multi-part states
  (move nil)                            ; current MOVE while (eq state :move)
  (hit-log (make-array 12 :initial-element nil) :type simple-vector)
                                        ; per hit slot: handles this move already hit (cleared at move start)
  (landed nil)                          ; the current move connected
  (target nil)                          ; handle: soft-lock / attack target
  (stun 0f0 :type single-float)         ; frames the current reaction (or landing) lasts
  (crippled nil)
  (grabbed nil)                         ; held by REN's Thunderfall
  (corpse-t 0f0 :type single-float))    ; dead: seconds until the body is removed (dummy: respawns)

(defcomponent blade-trail
  "The sword ribbon: recent blade base/tip samples (the engine's MAKE-TRAIL layout)."
  (points (make-trail) :type f32vec)
  (on 0f0 :type single-float)           ; > 0: sample the blade this step
  (heavy nil))                          ; heavy move: the ribbon starts nearer the guard

(defcomponent player
  "REN only: buffered button presses, stick input, defense timers, Raven gauge, combo and run stats."
  ;; input. Presses are stamped with *PTICK* (1/16 player frames) and stay buffered *INPUT-BUFFER* frames.
  (press-light -100000 :type fixnum) (press-heavy -100000 :type fixnum)
  (press-jump -100000 :type fixnum) (press-dodge -100000 :type fixnum)
  (press-raven -100000 :type fixnum)
  (guard-press -1000 :type fixnum)      ; last fresh guard press that opens a parry window
  (guard-last -1000 :type fixnum)       ; last guard press of any kind (anti-mash)
  (prev-lt 0f0 :type single-float) (prev-rt 0f0 :type single-float)   ; triggers last frame
  (stick-x 0f0 :type single-float) (stick-z 0f0 :type single-float)   ; camera-relative direction
  (stick-mag 0f0 :type single-float)    ; 0..1 (keys: 1)
  (stick-on nil)                        ; a direction is held
  ;; defense
  (guard-meter 100f0 :type single-float)
  (guard-idle 0f0 :type single-float)   ; seconds since the last block
  (dodge-end -1000 :type fixnum)        ; tick the last dodge ended (anti roll-spam)
  (dodge-iframes t)
  (air-dodge nil)                       ; the air dash is used up
  (jd-cd 0f0 :type single-float)        ; just-dodge cooldown, seconds
  (jd-until -1000 :type fixnum)         ; Mirage Counter allowed until this tick ...
  (jd-attacker nil)                     ; ... against this handle
  (riposte-until -1000 :type fixnum)
  (last-hurt -1000 :type fixnum) (prev-hurt -1000 :type fixnum)   ; ticks of the last two damaging hits
  (dead-t 0f0 :type single-float)
  ;; attacks
  (run-t 0f0 :type single-float)        ; seconds at full run (Gale Thrust)
  (air-cuts 0 :type fixnum)
  (string-id 0 :type fixnum)            ; +1 per new attack string (enemy block rolls)
  (mag-step 0f0 :type single-float) (mag-frames 0f0 :type single-float)   ; soft-lock magnetism
  (grab nil)                            ; handle held by Thunderfall
  (step-t 0f0 :type single-float)       ; footstep timer
  ;; Raven gauge / form
  (raven 0f0 :type single-float)
  (raven-form nil)
  (feather-t 0f0 :type single-float)
  (fov-punch 0f0 :type single-float)
  ;; combo and run stats (HUD, results)
  (combo 0 :type fixnum) (combo-t 0f0 :type single-float) (combo-punch 0f0 :type single-float)
  (max-combo 0 :type fixnum) (kills 0 :type fixnum) (obliterations 0 :type fixnum)
  (damage-taken 0f0 :type single-float)
  (hp-trail 200f0 :type single-float) (hp-hold 0f0 :type single-float))   ; HUD damage trail

(defcomponent brain
  "An AI-driven fighter (enemies and training dummies): the kind's mode, timers, aggression token,
blocking. The fighter state stays the body's state (:idle :move reactions :spawn :crippled); the
brain holds what the AI is trying to do."
  (kind :rainblade)                     ; enemy kind = its body name
  (mode :start)                         ; grunt :approach :circle :engage :feint, needler :reposition ...
  (last-state :spawn)                   ; fighter state at the end of the previous tick
  (mode-t 0f0 :type single-float)       ; seconds in the current mode (crippled: crawl time; spawn: landing)
  (cooldown 0f0 :type single-float)     ; seconds until the next attack decision
  (token nil)                           ; aggression token held: :melee :ranged :punish
  (strafe-dir 1f0 :type single-float)   ; +1 / -1
  (flip-t 1.5f0 :type single-float)     ; seconds until the strafe direction flips
  (zone-t 0f0 :type single-float)       ; seconds in the kind's trigger zone: grunt lunge band, brute
                                        ; hugged / flanked, boss crescent range
  (free-t 0f0 :type single-float)       ; seconds free of reactions (resets the flinch count)
  (flinches 0 :type fixnum)             ; consecutive flinches (grunt Escape rule)
  (blocks 0 :type fixnum)               ; blocked player hits (boss counter-shove rule)
  (block-chance 0f0 :type single-float)
  (block-string -1 :type fixnum)        ; player string the block roll was made for
  (blocked-roll nil)
  (chevron-t 0f0 :type single-float)    ; HUD: off-screen attack chevron seconds left
  (attacks 0 :type fixnum)              ; attacks since the last taunt (brute)
  (boss-phase 1 :type fixnum)           ; ENRA 1 / 2
  (touched-down nil)                    ; spawn: landed, waiting to start
  (leaping nil)                         ; ENRA: Bloodrain Leap airborne
  (iai-again nil)                       ; ENRA phase 2: a second Iai Dash follows
  (roar-pending nil)                    ; ENRA: the next roar is the phase-2 roar
  (summoned nil)                        ; ENRA: adds summoned
  (goal-x 0f0 :type single-float) (goal-z 0f0 :type single-float)   ; reposition spot / leap landing
  (step-t 0f0 :type single-float))      ; brute footstep timer

(defcomponent dummy
  "Training dummy: where it respawns."
  (home-x 0f0 :type single-float) (home-z 0f0 :type single-float) (home-yaw 0f0 :type single-float))

(defcomponent projectile
  "A thrown kunai, a red blast kunai (sticks, then explodes) or ENRA's blade wave."
  (kind :kunai)                         ; :kunai :blast :wave
  (owner nil)                           ; handle of the thrower: the hit is his
  (vel (make-f32 3) :type f32vec)
  (life 0f0 :type single-float)         ; seconds left
  (stuck nil)                           ; blast kunai: landed, fuse burning
  (fuse 0f0 :type single-float))

;;; ---------------------------------------------------------------- small helpers every file uses
(defun alive-p (e) "E exists and is a living fighter." (let ((h (health e))) (and h (health-alive h))))
(defun state-of (e) (fighter-state (fighter e)))
(defun body-of (e) (model-body (model e)))
(defun kind-of (e) "Enemy kind (= body name) of E." (body-name (body-of e)))
(defun name-of (e) (fighter-name (fighter e)))
(defun crippled-p (e) (fighter-crippled (fighter e)))
(defun enemy-p (e) "E is a living fighter on the enemies' side." (and (alive-p e) (eq (fighter-team (fighter e)) :enemy)))
