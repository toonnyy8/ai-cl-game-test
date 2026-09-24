;;;; feedback.lisp — FEEDBACK-SYSTEM: the rules decide, events report, this shows. Combat and the
;;;; AI EMIT small events (engine/lisp/ecs.lisp) instead of calling effects; once per step (and once
;;;; per frame, for game-flow events) this system takes them all and plays the sounds, blood, sparks,
;;;; rings, shake, hitstop, slow-mo and hit flash, and counts the combo and the kills.
;;;; Hitstop and slow-mo set here at the end of a step act from the next step (TIME-STEP), exactly
;;;; as if the rule had set them itself.
;;;;
;;;; Events (positions are captured when the event happens):
;;;;   (:hit att tgt x y z fx fz heavy hitstop ender)  a hit landed on an enemy at (x y z), att facing (fx fz)
;;;;   (:blocked x y z gain)                            a guard (enemy or REN) stopped a hit
;;;;   (:killed by-player obliterated x y z ux uz)      an enemy died; (ux uz) away from the killer
;;;;   (:crippled x y z ux uz)                          an arm flew off at the shoulder (x y z)
;;;;   (:expired x z)                                   a crippled enemy died after its Death Grip
;;;;   (:broken)                                        the boss is BROKEN
;;;;   (:raven-break x z)                               a Raven Form hit broke a red windup
;;;;   (:parried x y z)  (:just-dodge x z)              REN's perfect defense
;;;;   (:player-hurt x y z fx fz heavy hitstop)         REN took damage   (:player-died)
;;;;   (:sfx key x y z gain)                            just a positioned sound
(in-package :raven)

(defun feedback-system ()
  "Show every event emitted since the last call, oldest first."
  (dolist (ev (take-events))
    (destructuring-bind (kind &rest args) ev
      (ecase kind
        (:hit (destructuring-bind (att tgt x y z fx fz heavy hs ender) args
                (show-hit tgt x y z fx fz heavy hs ender)
                (when (eql att *player*) (count-combo))))
        (:blocked (destructuring-bind (x y z gain) args
                    (fx-sparks x y z 12 1.0 0.88 0.54)
                    (hitstop 3)
                    (sfx-at :clang x y z :gain gain)))
        (:killed (destructuring-bind (by-player oblit x y z ux uz) args
                   (show-kill oblit x y z ux uz)
                   (when by-player (count-kill oblit))))
        (:crippled (destructuring-bind (x y z ux uz) args
                     (fx-burst +p-mist+ 35 x y z ux 0.6f0 uz 0.8f0 5f0 8f0 0.6f0 0.18f0 0.70f0 0.07f0 0.18f0)))
        (:expired (destructuring-bind (x z) args
                    (fx-mist x 0.6 z 0.0 0.5 0.0 20)
                    (sfx-at :enemy-death x 0.5 z)))
        (:broken (slowmo 0.3 0.6) (shake 0.2 0.4))
        (:raven-break (destructuring-bind (x z) args
                        (play-sfx :parry)
                        (fx-ring x 1.2 z 0.2 1.6 0.2 1.0 0.12 0.24)))
        (:parried (destructuring-bind (x y z) args
                    (hitstop 8) (slowmo 0.5 0.2)
                    (fx-ring x y z 0.0 1.5 0.15 0.62 0.96 1.0)
                    (fx-burst +p-spark+ 24 x y z 0f0 0.3f0 0f0 1f0 7f0 11f0 0.25f0 0.04f0 0.62f0 0.96f0 1f0)
                    (play-sfx :parry)))
        (:just-dodge (destructuring-bind (x z) args
                       (slowmo 0.3 0.5 t)
                       (play-sfx :dodge :pitch 1.3)
                       (fx-burst +p-glow+ 12 x 1.0f0 z 0f0 0.3f0 0f0 1f0 0.5f0 2f0 0.35f0 0.2f0 0.62f0 0.78f0 1f0)))
        (:player-hurt (destructuring-bind (x y z fx fz heavy hs) args
                        (fx-mist x y z fx 0.3f0 fz 12)
                        (let ((m (model *player*))) (when m (setf (model-flash m) (max 0.05 (/ hs 60.0)))))
                        (hitstop hs) (shake 0.10 0.20) (screen-hurt)
                        (play-sfx :player-hurt) (play-sfx (if heavy :hit-heavy :hit-flesh) :gain 0.8)
                        (let ((s (pl))) (when s (setf (player-combo s) 0)))))
        (:player-died (slowmo 0.3 1.2))
        (:sfx (destructuring-bind (key x y z gain) args (sfx-at key x y z :gain gain)))))))

(defun show-hit (tgt x y z fx fz heavy hs ender)
  "Blood mist along the swing, the target's hit flash, hitstop, shake, a red flash of light, the impact sound."
  (fx-mist x y z fx 0.3f0 fz (if heavy 22 10))
  (let ((m (model tgt))) (when m (setf (model-flash m) (max (/ 3.0 60) (/ hs 60.0)))))
  (hitstop hs)
  (cond (ender (shake 0.2 0.35)) (heavy (shake 0.08 0.18)) (t (shake 0.03 0.10)))
  (add-point-light x y z 1.0 0.25 0.2 3.0 2.0)
  (sfx-at (if heavy :hit-heavy :hit-flesh) x y z))

(defun show-kill (oblit x y z ux uz)
  "Death: a bisecting burst + orbs (Obliterate), or mist, 3-6 essence orbs (60 % gold) and a cry."
  (cond (oblit
         (fx-burst +p-mist+ 60 x y z 0f0 0.5f0 0f0 1f0 6f0 10f0 0.8f0 0.2f0 0.70f0 0.07f0 0.18f0)
         (fx-burst +p-mist+ 10 x y z 0f0 0.5f0 0f0 1f0 5f0 8f0 0.8f0 0.25f0 0.23f0 0f0 0.03f0)
         (fx-orbs x y z 2 3))
        (t
         (fx-mist x y z ux 0.4f0 uz 30)
         (let ((n (+ 3 (floor (* 4 (rnd01))))) (g 0))
           (dotimes (i n) (when (< (rnd01) 0.6) (incf g)))
           (fx-orbs x y z g (- n g)))
         (sfx-at :enemy-death x y z))))

(defun count-combo ()
  "One more hit in REN's combo (HUD counter, results)."
  (let ((s (pl)))
    (incf (player-combo s))
    (setf (player-combo-t s) 2.5 (player-combo-punch s) 0.1 (player-max-combo s) (max (player-max-combo s) (player-combo s)))))

(defun count-kill (obliterated)
  (let ((s (pl)))
    (incf (player-kills s))
    (when obliterated (incf (player-obliterations s)))))
