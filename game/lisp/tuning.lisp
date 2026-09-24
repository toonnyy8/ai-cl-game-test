;;;; tuning.lisp — the game's balance knobs in one place (GAME_DESIGN §12). Change a number here and
;;;; rebuild; nothing else needs to know. Frame counts are 60 Hz frames, distances metres, times
;;;; seconds. Per-move frame data (startup, damage, hit volumes) lives with the moves (moves.lisp),
;;;; body stats (HP, poise, size) with the bodies (bodies.lisp).
(in-package :raven)

;;; ---------------------------------------------------------------- REN: movement
(defparameter *player-max-hp* 200.0)
(defparameter *run-speed* 7.5)
(defparameter *walk-speed* 3.0)
(defparameter *accel* 60.0 "m/s^2 toward the stick speed")
(defparameter *decel* 50.0)
(defparameter *turn-rate* (deg 900) "rad/s on the ground")
(defparameter *jump-vy* 9.5)
(defparameter *gravity* 28.0 "m/s^2 for REN")
(defparameter *air-accel* 20.0)
(defparameter *air-turn* (deg 540))

;;; ---------------------------------------------------------------- REN: defense & input
(defparameter *dodge-iframes* 16 "roll frames 1..this are invulnerable")
(defparameter *just-dodge-window* 10 "dodge frames 1..this count as a just dodge")
(defparameter *just-dodge-reach* 0.8 "Extra hurt radius used only to DETECT a just dodge (dodge f1-10).")
(defparameter *parry-window* 8 "frames after a fresh guard press that parry")
(defparameter *input-buffer* 12 "frames a press stays buffered")
(defparameter *guard-cost-mult* 2.5 "guard meter lost per point of blocked damage")
(defparameter *guard-regen* 30.0 "guard meter per second, after 0.8 s without blocking")

;;; ---------------------------------------------------------------- REN: Raven gauge / form
(defparameter *raven-threshold* 40.0 "gauge needed for Raven Burst")
(defparameter *raven-drain* 10.0 "gauge per second in Raven Form")

;;; ---------------------------------------------------------------- camera (§7.7)
(defparameter *cam-dist* 5.5)
(defvar *cam-fight-dist* 6.5 "Camera distance with an enemy within 12 m (set per wave: 7.0 in the boss fight).")
(defparameter *cam-fov* 62.0)

;;; ---------------------------------------------------------------- soft-lock (§3.4)
(defparameter *softlock-range* 7.0)
(defparameter *softlock-angle* 60.0)
(defparameter *magnet-light* 1.5 "max metres a light attack slides toward its target")
(defparameter *magnet-heavy* 2.0)

;;; ---------------------------------------------------------------- enemies (§4, §5)
(defparameter *enemy-dmg-mult* 1.0 "scales every enemy hit on REN")
(defparameter *enemy-cooldown-mult* 1.0 "scales AI attack cooldowns")
(defparameter *enemy-gravity* 22.0)
(defparameter *melee-tokens* 2 "enemies allowed to wind up a melee attack at once (+1 punish token)")
(defparameter *ranged-tokens* 1)
(defparameter *boss-hp* 1400.0)
(defparameter *death-grip-delay* 3.0 "seconds a crippled grunt crawls before its Death Grip")
(defparameter *arena-inner* 16.6 "Needlers stay 1 m inside the walls.")
(defparameter *corpse-time* 2.5
  "seconds a dead enemy stays in the world before it is removed (> a blast kunai's 1.5 s flight + 0.9 s
fuse: its explosion is resolved with the thrower as attacker)")
(defparameter *dummy-respawn* 3.0 "seconds before a dead training dummy comes back")

;;; ---------------------------------------------------------------- waves (§6.3)
(defparameter *max-alive* 6 "the spawner never has more enemies alive than this")
