;;;; feedback.lisp — FEEDBACK-SYSTEM: the rules decide, events report, this shows (design-v1 §10–§11).
;;;; Fighters, combat and hazards EMIT small events; once per step (last system) this takes them all
;;;; and plays the sounds, sparks (vfx.lisp), shake, callouts and big words. Everything here is
;;;; cosmetic (RND01, real time): nothing the sim reads is decided here (hitstop is combat.lisp's).
;;;;
;;;; Events (positions captured when they happen):
;;;;   (:swing e kind)  (:super e)  (:breaker e) (:breaker-end e)  (:rush e) (:rush-dash e) (:kikon-follow att def)  (:step e)
;;;;   (:hit att def x y z hitstop counter-p dmg kind)  (:blocked att def x y z)  (:armored def x y z)
;;;;   (:absorbed def x y z)  (:guard-crush att def x y z) (:guard-back e)  (:guard-break att def x y z)  (:stance-break att def x y z)  (:clash x y z)
;;;;   (:hazard-cut x y z)  (:hoho-out e x z) (:hoho-in e x z) (:perfect e victim)  (:burst e attacker)
;;;;   (:launch e) (:land e)
;;;;   (:konpaku victim lost) (:kikon att victim) (:soul-break att victim)  (:awaken e) (:form e form)
;;;;   (:evolution e) (:hellfire e)  (:skeleton-rise x z)  (:sfx key e)  (:reset)
(in-package :duel)

(defun sfx-on (key e &key (gain 1.0) (pitch 1.0))
  (let ((p (pos-of e))) (sfx-at key (aref p 0) (+ (aref p 1) 1.0) (aref p 2) :gain gain :pitch pitch)))

(defun hit-dir (att def)
  "Values dx dz: unit direction from ATT to DEF."
  (let* ((p (pos-of att)) (q (pos-of def)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (d (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))))
    (values (/ dx d) (/ dz d))))

(defvar *hums* (make-array 2 :initial-element -1) "Breaker hum loop voice per side.")

(defun stop-hum (e)
  (let ((i (fighter-side (fighter e))))
    (when (>= (svref *hums* i) 0) (stop-loop (svref *hums* i) 0.1) (setf (svref *hums* i) -1))))

(defun show-hit (att def x y z hs counter dmg kind)
  "A hit (docs/STYLE_STORM_DESIGN.md §4.3): the drawn spark; a heavy hit also holds the attacker's pose 3 f
and smears the victim along the hit; a counter turns the frame to a manga page for 2 f (red stays)."
  (multiple-value-bind (dx dz) (hit-dir att def)
    (let* ((blade (first (kit-blade (kit-of att))))
           (look (cond (counter :counter) ((eq kind :breaker) :breaker) ((eq kind :fire) :fire)
                       ((eq blade :fire) (if (eq kind :quick) :fire :heavy)) ((eq kind :quick) :cut) (t :heavy))))
      (vfx-hit x y z look :dx dx :dz dz)
      (when (member look '(:heavy :counter :breaker))
        (hold-pose att 3) (smear def dx dz))
      (sfx-at (cond ((eq kind :breaker) :punch) ((eq kind :fire) :explode) ((eq blade :embers) :sizzle)
                    ((eq kind :quick) :cut) (t :cut-heavy))
              x y z :gain (if (eq kind :quick) 0.8 1.0))))
  (setf (model-flash (model def)) (max 0.06 (/ hs 60.0)))
  (cond ((>= dmg 150) (shake 0.22 0.3)) ((>= dmg 60) (shake 0.09 0.18)) (t (shake 0.03 0.1)))
  (when counter
    (impact-frame :manga 2)
    (announce "COUNTER" :color '(0.82 0.06 0.11 1) :secs 0.6 :small t)))

(defun feedback-system ()
  "Show every event emitted since the last call, oldest first."
  (dolist (ev (take-events))
    (destructuring-bind (kind &rest args) ev
      (case kind
        (:swing (destructuring-bind (e k) args
                  (unless (eq k :quick) (smear e (fwd-x (yaw-of e)) (fwd-z (yaw-of e))))   ; a heavy swing starts
                  (sfx-on (if (eq k :quick) :whoosh-light (or (kit-swing-sfx (kit-of e)) :whoosh-heavy)) e :gain 0.7)))
        (:super (let ((e (first args)))
                  (setf (model-super (model e)) (/ *super-flash* 60.0)) (sfx-on :whoosh-heavy e :pitch 0.7)))
        (:breaker (let ((e (first args)))
                    (stop-hum e)
                    (setf (svref *hums* (fighter-side (fighter e))) (start-loop :breaker-hum :gain 0.7))))
        (:breaker-end (stop-hum (first args)))
        (:rush (let* ((e (first args)) (p (pos-of e)))       ; the Kikon rush starts: a red ring at his feet
                 (vfx-kikon-rush (aref p 0) (aref p 2))
                 (smear e (fwd-x (yaw-of e)) (fwd-z (yaw-of e)))
                 (setf (model-super (model e)) 0.12)
                 (sfx-on :whoosh-heavy e :pitch 0.6)))
        (:rush-dash (let* ((e (first args)) (mv (fighter-move (fighter e))) (p (pos-of e)))   ; a rush module takes off
                      (when mv
                        (let ((sfx (getf (mv-params mv) :sfx)) (look (getf (mv-params mv) :look)))
                          (when sfx (sfx-on sfx e))
                          (vfx-rush-dash (aref p 0) (aref p 2) (fwd-x (yaw-of e)) (fwd-z (yaw-of e)) look)
                          (when (eq look :flash-step) (start-ghost e))))))
        (:kikon-follow (destructuring-bind (att def) args   ; the strike hit, O held, not red: guard the next one
                         (declare (ignore def))
                         (let ((p (pos-of att))) (vfx-kikon-rush (aref p 0) (aref p 2)))
                         (sfx-on :whoosh-heavy att :pitch 0.6)
                         (announce "KIKON" :sub "GUARD IT!" :color '(0.82 0.06 0.11 1) :secs 0.6 :small t)))
        (:hit (apply #'show-hit args))
        (:blocked (destructuring-bind (att def x y z) args
                    (multiple-value-bind (dx dz) (hit-dir att def) (vfx-hit x y z :guard :dx dx :dz dz))
                    (sfx-at :clang x y z)))
        (:armored (destructuring-bind (def x y z) args     ; the owner's spot colour: fire, else REIATSU (+ his absorb sound)
                    (if (member (first (kit-blade (kit-of def))) '(:fire :embers))
                        (progn (vfx-hit x y z :fire) (sfx-at :sizzle x y z))
                        (progn (vfx-hit x y z :reiatsu) (sfx-at :cut x y z :gain 0.7)
                               (let ((k (kit-absorb-sfx (kit-of def)))) (when k (sfx-on k def :gain 0.8)))))))
        (:absorbed (destructuring-bind (def x y z) args
                     (vfx-hit x y z :guard) (sfx-at :cut x y z :gain 0.7)
                     (let ((k (kit-absorb-sfx (kit-of def)))) (when (and k (< (rnd01) 0.5)) (sfx-on k def :gain 0.8)))))
        (:guard-crush (destructuring-bind (att def x y z) args        ; the guard gauge ran out on a block
                        (multiple-value-bind (dx dz) (hit-dir att def) (vfx-hit x y z :guard-crush :dx dx :dz dz))
                        (sfx-at :guard-break x y z :pitch 1.2) (sfx-at :clang x y z :pitch 0.8)
                        (shake 0.15 0.25) (impact-frame :negative 1)
                        (announce "GUARD CRUSH" :color '(0.78 0.83 0.89 1) :secs 1.0)))
        (:guard-back (let ((e (first args)))                           ; full again: he can guard
                       (sfx-on :clang e :gain 0.5 :pitch 1.4)
                       (announce "GUARD" :color '(0.78 0.83 0.89 1) :secs 0.7 :side (fighter-side (fighter e)))))
        (:guard-break (destructuring-bind (att def x y z) args
                        (multiple-value-bind (dx dz) (hit-dir att def) (vfx-hit x y z :guard-break :dx dx :dz dz))
                        (sfx-at :guard-break x y z) (shake 0.2 0.3) (ui-flash 1 1 1 0.9 50.0)      ; a 1 f white flash
                        (announce "GUARD BREAK" :color '(1 1 1 1) :secs 1.0)))
        (:stance-break (destructuring-bind (att def x y z) args
                         (multiple-value-bind (dx dz) (hit-dir att def) (vfx-hit x y z :guard-break :dx dx :dz dz))
                         (sfx-at :guard-break x y z)
                         (announce "BROKEN" :color '(1 1 1 1) :secs 0.9 :small t)))
        (:clash (destructuring-bind (x y z) args
                  (vfx-hit x y z :clash) (sfx-at :clash x y z) (shake 0.25 0.3)
                  (impact-frame :negative 2) (focus-lines 20 x y z)
                  (announce "CLASH" :color '(1 1 1 1) :secs 0.9)))
        (:hazard-cut (destructuring-bind (x y z) args (vfx-hit x y z :heavy) (sfx-at :cut-heavy x y z)))
        (:step (let* ((e (first args)) (p (pos-of e)) (v (motion-kb (motion e))) (vx (aref v 0)) (vz (aref v 2))
                      (l (sqrt (+ (* vx vx) (* vz vz)))))
                 (multiple-value-bind (dx dz) (if (> l 1e-4) (values (/ vx l) (/ vz l)) (values (fwd-x (yaw-of e)) (fwd-z (yaw-of e))))
                   (vfx-step-dust (aref p 0) (aref p 2) (- dx) (- dz)) (smear e dx dz))
                 (sfx-on :step e :gain 0.6)))
        (:hoho-out (destructuring-bind (e x z) args
                     (vfx-hoho x 1.0 z nil :dx (fwd-x (yaw-of e)) :dz (fwd-z (yaw-of e)))
                     (start-ghost e)
                     (sfx-on :hoho-out e)))
        (:hoho-in (destructuring-bind (e x z) args
                    (vfx-hoho x 1.0 z t :dx (fwd-x (yaw-of e)) :dz (fwd-z (yaw-of e))) (sfx-on :hoho-in e)))
        (:perfect (play-sfx :perfect) (setf *punch-t* 0.5)
         (announce "PERFECT" :color '(1 1 1 1) :secs 0.9))
        (:burst (let* ((e (first args)) (p (pos-of e)) (x (aref p 0)) (z (aref p 2)))   ; mono in the notan world (STEEL)
                  (vfx-burst x (aref p 1) z)
                  (sfx-on :clash e :pitch 0.7) (sfx-on :hoho-in e)
                  (shake 0.15 0.25)
                  (announce "BURST REVERSE" :color '(0.78 0.83 0.89 1) :secs 1.0 :small t)))
        (:launch (sfx-on :launch (first args) :gain 0.8))
        (:land (let ((e (first args))) (sfx-on :land e)
                 (let ((p (pos-of e))) (vfx-shockwave (aref p 0) (aref p 2) 1.2 0.3 :pal +pal-dust+))))
        (:konpaku (destructuring-bind (v lost) args (pips-shatter v lost)))
        (:kikon (destructuring-bind (att v) args
                  (declare (ignore v))
                  (play-sfx :bell)
                  (setf (model-super (model att)) 0.15)))
        (:soul-break nil)                                   ; the cinematic says it
        (:awaken (let ((e (first args))) (sfx-on :awaken-boom e)))
        (:form (destructuring-bind (e form) args
                 (declare (ignore form))
                 (when (kit-callout (kit-of e)) (announce (kit-callout (kit-of e)) :color '(1 0.5 0.15 1) :secs 1.0 :small t))))
        (:evolution (let ((e (first args))) (play-sfx :evolution)
                      (announce "EVOLUTION" :color '(1 0.85 0.3 1) :secs 1.0 :small t :side (fighter-side (fighter e)))))
        (:hellfire (let* ((e (first args)) (p (pos-of e)))
                     (vfx-shockwave (aref p 0) (aref p 2) 6.0 0.5 :rgb '(1.0 0.5 0.15)) (shake 0.2 0.4)))
        (:skeleton-rise (destructuring-bind (x z) args (vfx-skeleton-dust x z) (sfx-at :bones x 0.5 z)))
        (:sfx (destructuring-bind (key e) args (sfx-on key e)))
        (:reset (play-sfx :bell :gain 0.6))))))
