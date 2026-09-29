;;;; feedback.lisp — FEEDBACK-SYSTEM: the rules decide, events report, this shows (design-v1 §10–§11).
;;;; Fighters, combat and hazards EMIT small events; once per step (last system) this takes them all
;;;; and plays the sounds, sparks (vfx.lisp), shake, callouts and big words. Everything here is
;;;; cosmetic (RND01, real time): nothing the sim reads is decided here (hitstop is combat.lisp's).
;;;;
;;;; Events (positions captured when they happen):
;;;;   (:swing e kind)  (:super e)  (:breaker e) (:breaker-end e)  (:rush e) (:rush-dash e) (:kikon-follow att def)  (:step e)
;;;;   (:hit att def x y z hitstop counter-p dmg kind)  (:blocked att def x y z)  (:armored def x y z)
;;;;   (:absorbed def x y z)  (:guard-crush att def x y z) (:guard-back e)  (:guard-break att def x y z)  (:stance-break att def x y z)  (:clash x y z)
;;;;   (:parried att def x y z)  (:scorch att)  (:ward-crush e)  (:cold-crack e)  (:refused e cmd)  (:kosei att m x y z)
;;;;   (:hazard-cut x y z)  (:hoho-out e x z) (:hoho-in e x z) (:perfect e victim)  (:burst e attacker)
;;;;   (:launch e) (:land e)
;;;;   (:konpaku victim lost) (:kikon att victim) (:soul-break att victim)  (:awaken e) (:form e form)
;;;;   (:evolution e) (:hellfire e)  (:skeleton-rise x z)  (:sfx key e)  (:reset)
;;;;   (:rung e up-p) (:drink att def x y z) (:rift-cut owner x z hx hz yaw) (:rift-close x z)   Nozarashi's NOME ladder
;;;;   (:bankai e) (:arm-spend e left) (:arm-crack e left) (:arm-burst e)   Kenpachi's Bankai: the arm meter
(in-package :duel)

(defun sfx-on (key e &key (gain 1.0) (pitch 1.0))
  (let ((p (pos-of e))) (sfx-at key (aref p 0) (+ (aref p 1) 1.0) (aref p 2) :gain gain :pitch pitch)))

(defun hit-dir (att def)
  "Values dx dz: unit direction from ATT to DEF."
  (let* ((p (pos-of att)) (q (pos-of def)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (d (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))))
    (values (/ dx d) (/ dz d))))

(defvar *hums* (make-array 2 :initial-element -1) "Breaker hum loop voice per side.")
(declaim (type f32vec *fb-v*))
(defvar *fb-v* (make-f32 3) "A world point (the scorched hand).")

(defun stop-hum (e)
  (let ((i (fighter-side (fighter e))))
    (when (>= (svref *hums* i) 0) (stop-loop (svref *hums* i) 0.1) (setf (svref *hums* i) -1))))

(defun show-hit (att def x y z hs counter dmg kind)
  "A hit (docs/STYLE_STORM_DESIGN.md §4.3): the drawn spark; a heavy hit also holds the attacker's pose 3 f
and smears the victim along the hit; a counter turns the frame to a manga page for 2 f (red stays)."
  (multiple-value-bind (dx dz) (hit-dir att def)
    (let* ((blade (first (kit-blade (kit-of att))))
           (look (cond (counter :counter) ((eq kind :breaker) :breaker) ((eq kind :fire) :fire) ((eq kind :bind) :cut)
                       ((eq blade :fire) (if (eq kind :quick) :fire :heavy)) ((eq kind :quick) :cut) (t :heavy))))
      (vfx-hit x y z look :dx dx :dz dz)
      (when (member look '(:heavy :counter :breaker))
        (hold-pose att 3) (smear def dx dz))
      (sfx-at (cond ((eq kind :breaker) :punch) ((eq kind :fire) :explode) ((eq kind :bind) :bones) ((eq kind :ice) :freeze) ((member blade '(:embers :charcoal)) :sizzle)
                    ((eq kind :quick) :cut) (t :cut-heavy))
              x y z :gain (if (eq kind :quick) 0.8 1.0))))
  (setf (model-flash (model def)) (max 0.06 (/ hs 60.0)))
  (cond ((>= dmg 150) (shake 0.22 0.3)) ((>= dmg 60) (shake 0.09 0.18)) (t (shake 0.03 0.1)))
  (cond ((eq kind :fire) (stage-mark :scorch x z 0.8))           ; the page keeps the fight (Phase 6): fire scorches,
        ((or (>= dmg 150) (eq kind :breaker))                      ; a heavy blow cracks the stone and throws chips
         (stage-mark :crack x z 0.9) (stage-debris x z 3)))
  (when counter
    (impact-frame :manga 2)
    (announce "COUNTER" :color '(0.82 0.06 0.11 1) :secs 0.6 :small t)))

(declaim (type f32vec *crack-t*))
(defvar *crack-t* (make-f32 2) "Per side: FX-CLOCK of her last CRACK (the cold gauge's BLOOD hairline).")

(defun feedback-system ()
  "Show every event emitted since the last call, oldest first."
  (dolist (ev (take-events))
    (destructuring-bind (kind &rest args) ev
      (case kind
        (:swing (destructuring-bind (e k) args
                  (unless (eq k :quick) (smear e (fwd-x (yaw-of e)) (fwd-z (yaw-of e))))   ; a heavy swing starts
                  (sfx-on (if (eq k :quick) :whoosh-light (or (kit-swing-sfx (kit-of e)) :whoosh-heavy)) e :gain 0.7)))
        (:kosei (apply #'kosei-mote args))                  ; KOSEI paid: the HUD's ember mote
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
        (:kikon-follow (destructuring-bind (att def) args   ; the strike hit, O held: he dashes in (not red: guard it!)
                         (declare (ignore def))
                         (let ((p (pos-of att))) (vfx-kikon-rush (aref p 0) (aref p 2)))
                         (sfx-on :whoosh-heavy att :pitch 0.6)
                         (focus-lines 10)
                         (announce "KIKON" :sub (if (kikon-ready-p att) nil "GUARD IT!") :color '(0.82 0.06 0.11 1) :secs 0.6 :small t)))
        (:hit (apply #'show-hit args))
        (:blocked (destructuring-bind (att def x y z) args
                    (multiple-value-bind (dx dz) (hit-dir att def)
                      (if (and (passive-p def :ward) (not (passive-p def :freeze-touch)))   ; West's ward (not the ice one): the hexagon in fire,
                          (progn (vfx-garb-block x y z (- dx) (- dz)) (sfx-at :sizzle x y z)   ; the garb flares
                                 (setf (model-flare (model def)) (f32 (max (model-flare (model def)) 0.25))))
                          (vfx-hit x y z :guard :dx dx :dz dz))
                      (when (passive-p att :pierce)                ; East's pierce: a white spark out of his back
                        (vfx-hit (+ x (* 0.7 dx)) y (+ z (* 0.7 dz)) :cut :dx dx :dz dz)))
                    (sfx-at :clang x y z)))
        (:armored (destructuring-bind (def x y z) args     ; the owner's spot colour: fire / ember, else REIATSU (+ his absorb sound)
                    (case (first (kit-blade (kit-of def)))
                      ((:embers :charcoal) (vfx-ember x y z) (sfx-at :sizzle x y z))
                      (:fire (vfx-hit x y z :fire) (sfx-at :sizzle x y z))
                      (t
                       (vfx-hit x y z :reiatsu) (sfx-at :cut x y z :gain 0.7)
                       (let ((k (kit-absorb-sfx (kit-of def)))) (when k (sfx-on k def :gain 0.8)))))))
        (:parried (destructuring-bind (att def x y z) args   ; a parry caught it: an ember star, a 1 f negative frame
                    (multiple-value-bind (dx dz) (hit-dir att def) (vfx-ember x y z :dx (- dx) :dz (- dz) :scale 1.3))
                    (sfx-at :clang x y z) (sfx-at :sizzle x y z) (shake 0.12 0.2) (impact-frame :negative 1)
                    (announce "PARRY" :color '(1 0.55 0.2 1) :secs 0.7 :small t)))
        (:scorch (let* ((e (first args)) (v *fb-v*))       ; the attacker's sword arm burns: a white flash, black smoke
                   (joint-point! v (model-joints (model e)) (ji :hand-r) 0f0 0f0 0f0)
                   (vfx-scorch (aref v 0) (aref v 1) (aref v 2)) (vfx-smoke-puffs (aref v 0) (aref v 1) (aref v 2) 1)
                   (sfx-on :sizzle e :gain 0.5 :pitch 1.3)))
        (:ward-crush (let* ((e (first args)) (p (pos-of e)))   ; West's ward broken (crush / Guard Break): the garb
                       (vfx-burnout (aref p 0) (aref p 2) t)          ; gutters out (smoke, an ash ring), he is East
                       (sfx-on :sizzle e :pitch 0.6) (sfx-on :heat-flare e :pitch 0.6 :gain 0.8)))
        (:cold-crack (let ((e (first args)))               ; Rukia's hand cracked at zero: the gauge's BLOOD hairline
                       (setf (aref *crack-t* (fighter-side (fighter e))) (f32 (fx-clock)))
                       (sfx-on :hand-crack e)
                       (announce "CRACK" :color '(0.82 0.06 0.11 1) :secs 0.8 :small t :side (fighter-side (fighter e)))))
        (:refused (destructuring-bind (e cmd) args          ; still cooling: a dud tick, its HUD bar flashes
                    (sfx-on :clang e :gain 0.35 :pitch 1.6)
                    (hud-refused e cmd)))
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
                        (stage-mark :crack x z 1.1) (stage-debris x z 4)
                        (announce "GUARD BREAK" :color '(1 1 1 1) :secs 1.0)))
        (:stance-break (destructuring-bind (att def x y z) args
                         (multiple-value-bind (dx dz) (hit-dir att def) (vfx-hit x y z :guard-break :dx dx :dz dz))
                         (sfx-at :guard-break x y z)
                         (announce "BROKEN" :color '(1 1 1 1) :secs 0.9 :small t)))
        (:clash (destructuring-bind (x y z) args
                  (vfx-hit x y z :clash) (sfx-at :clash x y z) (shake 0.25 0.3) (stage-mark :crack x z 1.2) (stage-debris x z 4)
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
                 (let ((p (pos-of e))) (vfx-shockwave (aref p 0) (aref p 2) 1.2 0.3 :pal +pal-dust+)
                   (stage-mark :crack (aref p 0) (aref p 2) 0.6) (stage-debris (aref p 0) (aref p 2) 2 0.6))))
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
                     (vfx-shockwave (aref p 0) (aref p 2) 6.0 0.5 :rgb '(1.0 0.5 0.15)) (shake 0.2 0.4)
                     (stage-mark :scorch (aref p 0) (aref p 2) 2.0)))
        (:skeleton-rise (destructuring-bind (x z) args (vfx-skeleton-dust x z) (sfx-at :bones x 0.5 z)))
        (:sfx (destructuring-bind (key e) args (sfx-on key e)))
        (:reset (play-sfx :bell :gain 0.6) (stage-clear-marks))   ; a new round: a clean page
        (:rung (destructuring-bind (e up) args               ; a cup up (or down) the NOME ladder
                 (let ((form (fighter-form (fighter e))) (side (fighter-side (fighter e))))
                   (cond ((not up)
                          (let ((p (pos-of e))) (vfx-smoke-puffs (aref p 0) 1.2 (aref p 2) 2))
                          (when (eq form :nozarashi) (callout e "TSUMANNEE...")))
                         ((eq form :nomihose)              ; drink it dry: a negative, then a manga page (yellow kept);
                          (impact-frame :negative 1) (setf *impact-next* '(:manga . 12))   ; the grin, head thrown back
                          (face-beat e :shout 0.9 t)
                          (sfx-on :awaken-boom e) (sfx-on :tier-up e) (shake 0.2 0.3)
                          (announce "NOMIHOSE!" :color '(1 0.85 0.25 1) :secs 1.0 :small t :side side))
                         (t (sfx-on :tier-up e)
                            (announce "RYOTE" :color '(1 0.85 0.25 1) :secs 0.8 :small t :side side))))))
        (:drink (destructuring-bind (att def x y z) args     ; the hit star reversed: flecks sucked into the cleaver
                  (multiple-value-bind (dx dz) (hit-dir att def) (vfx-hit x y z :reiatsu :dx (- dx) :dz (- dz)))
                  (sfx-on :gulp def)
                  (when (< (rnd01) 0.33) (sfx-on :laugh def :gain 0.7))))
        (:rift-cut (destructuring-bind (o x z hx hz yaw) args  ; the white hit and the ink gash left along the rift
                     (declare (ignore o))
                     (vfx-hit x 1.15 z :heavy) (vfx-rift-gash hx hz (fwd-x yaw) (fwd-z yaw))
                     (sfx-at :rift-cut x 1.15 z) (shake 0.08 0.15)))
        (:rift-close (destructuring-bind (x z) args (vfx-smoke-puffs x 1.15 z 1)))
        (:bankai nil)                                        ; the cinematic says it
        ((:arm-spend :arm-crack)                             ; a pip: a BLOOD crack flash along the forearm, a bone creak
         (let ((e (first args)) (v *fb-v*))                  ; (a crack by the clock: dimmer, an ink puff)
           (joint-point! v (model-joints (model e)) (ji :lower-arm-r) 0f0 -0.12f0 0f0)
           (vfx-awaken-burst (aref v 0) (aref v 1) (aref v 2) :arm-crack)
           (sfx-on :arm-crack e :gain (if (eq kind :arm-spend) 0.9 0.6))
           (when (eq kind :arm-crack) (vfx-smoke-puffs (aref v 0) (aref v 1) (aref v 2) 1))))
        (:arm-burst (let ((e (first args)) (v *fb-v*))       ; the arm bursts: a negative, a manga page, the BLOOD spray
                      (joint-point! v (model-joints (model e)) (ji :lower-arm-r) 0f0 -0.12f0 0f0)
                      (vfx-awaken-burst (aref v 0) (aref v 1) (aref v 2) :arm-burst)
                      (impact-splash (aref v 0) (aref v 1) (aref v 2) 16 0.07)
                      (impact-frame :negative 1) (setf *impact-next* '(:manga . 12))
                      (face-beat e :hurt 0.9)
                      (sfx-on :arm-burst e) (shake 0.2 0.3)))))))   ; (Yachiru's apology is his callout: ARM-BURST!)
