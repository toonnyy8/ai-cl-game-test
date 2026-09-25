;;;; feedback.lisp — FEEDBACK-SYSTEM: the rules decide, events report, this shows (design-v1 §10–§11).
;;;; Fighters, combat and hazards EMIT small events; once per step (last system) this takes them all
;;;; and plays the sounds, sparks (vfx.lisp), shake, callouts and big words. Everything here is
;;;; cosmetic (RND01, real time): nothing the sim reads is decided here (hitstop is combat.lisp's).
;;;;
;;;; Events (positions captured when they happen):
;;;;   (:swing e kind)  (:super e)  (:breaker e) (:breaker-end e)  (:step e)
;;;;   (:hit att def x y z hitstop counter-p dmg kind)  (:blocked att def x y z)  (:armored def x y z)
;;;;   (:absorbed def x y z)  (:guard-break att def x y z)  (:stance-break att def x y z)  (:clash x y z)
;;;;   (:hazard-cut x y z)  (:hoho-out e x z) (:hoho-in e x z) (:perfect e victim)  (:launch e) (:land e)
;;;;   (:konpaku victim lost) (:kikon att victim) (:soul-break att victim)  (:awaken e) (:form e form)
;;;;   (:evolution e) (:hellfire e) (:bankai-end e)  (:skeleton-rise x z)  (:sfx key e)  (:reset)
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
  (multiple-value-bind (dx dz) (hit-dir att def)
    (let ((blade (first (kit-blade (kit-of att)))))
      (vfx-hit x y z (cond (counter :counter) ((eq kind :breaker) :breaker) ((eq kind :fire) :fire)
                           ((eq blade :fire) (if (eq kind :quick) :fire :heavy)) ((eq kind :quick) :cut) (t :heavy))
               :dx dx :dz dz)
      (sfx-at (cond ((eq kind :breaker) :punch) ((eq kind :fire) :explode) ((eq blade :embers) :sizzle)
                    ((eq kind :quick) :cut) (t :cut-heavy))
              x y z :gain (if (eq kind :quick) 0.8 1.0))))
  (setf (model-flash (model def)) (max 0.06 (/ hs 60.0)))
  (flash-light x y z 1.0 0.55 0.3)
  (cond ((>= dmg 150) (shake 0.22 0.3)) ((>= dmg 60) (shake 0.09 0.18)) (t (shake 0.03 0.1)))
  (when counter (announce "COUNTER" :color '(1 0.8 0.3 1) :secs 0.6 :small t)))

(defun feedback-system ()
  "Show every event emitted since the last call, oldest first."
  (dolist (ev (take-events))
    (destructuring-bind (kind &rest args) ev
      (case kind
        (:swing (destructuring-bind (e k) args
                  (sfx-on (if (eq k :quick) :whoosh-light (or (kit-swing-sfx (kit-of e)) :whoosh-heavy)) e :gain 0.7)))
        (:super (let ((e (first args)))
                  (setf (model-super (model e)) (/ *super-flash* 60.0)) (sfx-on :whoosh-heavy e :pitch 0.7)))
        (:breaker (let ((e (first args)))
                    (stop-hum e)
                    (setf (svref *hums* (fighter-side (fighter e))) (start-loop :breaker-hum :gain 0.7))))
        (:breaker-end (stop-hum (first args)))
        (:hit (apply #'show-hit args))
        (:blocked (destructuring-bind (att def x y z) args
                    (multiple-value-bind (dx dz) (hit-dir att def) (vfx-hit x y z :guard :dx dx :dz dz))
                    (sfx-at :clang x y z)))
        (:armored (destructuring-bind (def x y z) args
                    (declare (ignore def)) (vfx-hit x y z :fire) (sfx-at :sizzle x y z)))
        (:absorbed (destructuring-bind (def x y z) args
                     (vfx-hit x y z :guard) (sfx-at :cut x y z :gain 0.7)
                     (let ((k (kit-absorb-sfx (kit-of def)))) (when (and k (< (rnd01) 0.5)) (sfx-on k def :gain 0.8)))))
        (:guard-break (destructuring-bind (att def x y z) args
                        (declare (ignore att def))
                        (vfx-hit x y z :breaker) (sfx-at :guard-break x y z) (shake 0.2 0.3)
                        (announce "GUARD BREAK" :color '(1 0.35 0.75 1) :secs 1.0)))
        (:stance-break (destructuring-bind (att def x y z) args
                         (declare (ignore att def))
                         (vfx-hit x y z :breaker) (sfx-at :guard-break x y z)
                         (announce "BROKEN" :color '(1 0.35 0.75 1) :secs 0.9 :small t)))
        (:clash (destructuring-bind (x y z) args
                  (vfx-hit x y z :clash) (sfx-at :clash x y z) (shake 0.25 0.3)
                  (announce "CLASH" :color '(1 1 1 1) :secs 0.9)))
        (:hazard-cut (destructuring-bind (x y z) args (vfx-hit x y z :heavy) (sfx-at :cut-heavy x y z)))
        (:step (sfx-on :step (first args) :gain 0.6))
        (:hoho-out (destructuring-bind (e x z) args (vfx-hoho x 1.0 z nil) (sfx-on :hoho-out e)))
        (:hoho-in (destructuring-bind (e x z) args (vfx-hoho x 1.0 z t) (sfx-on :hoho-in e)))
        (:perfect (play-sfx :perfect) (setf *punch-t* 0.5)
         (announce "PERFECT" :color '(0.5 0.9 1 1) :secs 0.9))
        (:launch (sfx-on :launch (first args) :gain 0.8))
        (:land (let ((e (first args))) (sfx-on :land e) (let ((p (pos-of e))) (vfx-shockwave (aref p 0) (aref p 2) 1.2 0.3))))
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
        (:bankai-end (let* ((e (first args)) (p (pos-of e)))
                       (vfx-awaken-burst (aref p 0) 1.0 (aref p 2) :bankai-burst) (sfx-on :fire-roar e)))
        (:skeleton-rise (destructuring-bind (x z) args (vfx-skeleton-dust x z) (sfx-at :bones x 0.5 z)))
        (:sfx (destructuring-bind (key e) args (sfx-on key e)))
        (:reset (play-sfx :bell :gain 0.6))))))
