;;;; combat.lisp — what happens when fighters touch (design-v1 §1, §3, §4): HIT-SYSTEM (clash check,
;;;; then COLLECT every fighter's and hazard's hits, then APPLY them all: a trade is a trade, no side
;;;; goes first; then settle the souls they broke), APPLY-HIT (the triangle, damage, reactions, chip,
;;;; gauges, hitstop), Kikon / Soul Break / awakening / form changes (all settled here, at connect
;;;; time; cinema.lisp only presents them), the perfect-Hoho test and GAUGE-SYSTEM (regen, burns,
;;;; form timers, Hellfire, EVOLUTION). Decisions are rules.lisp's; effects are EMITted for feedback.lisp.
(in-package :duel)

;;; ---------------------------------------------------------------- damage and gauges
(defvar *soul-breaks* nil
  "(attacker . victim) of every Reishi that reached 0 during this step's HIT-SYSTEM: settled together
at its end (SETTLE-SOUL-BREAKS), so a lethal trade breaks both souls and no side goes first.")

(defun gain-gauges (e dealt taken)
  "Reiatsu and Fighting Spirit for dealing DEALT / taking TAKEN damage."
  (let ((g (gauges e)))
    (setf (gauges-reiatsu g) (f32 (gauge-add (gauges-reiatsu g) (reiatsu-gain dealt taken) *reiatsu-max*)))
    (unless (gauges-awakened g)
      (setf (gauges-awaken g) (f32 (gauge-add (gauges-awaken g) (awakening-gain dealt taken 0) *awaken-max*))))))

(defun deal-damage (att def dmg)
  "DEF loses DMG Reishi (ATT dealt it; a CPU attacker's anti-stall heat resets). Reishi at 0 is an
automatic Soul Break, settled at the end of the step (*SOUL-BREAKS*): returns T then."
  (let ((ga (gauges att)) (gd (gauges def)) (b (brain att)))
    (setf (gauges-reishi gd) (max 0 (- (gauges-reishi gd) dmg)))
    (incf (gauges-dealt ga) dmg)
    (when b (setf (brain-heat b) 0f0))
    (incf (fighter-combo-dmg (fighter def)) dmg)
    (gain-gauges att dmg 0)
    (gain-gauges def 0 dmg)
    (when (soul-break-p (gauges-reishi gd))
      (unless (rassoc def *soul-breaks*) (push (cons att def) *soul-breaks*))
      t)))

(defun add-meter (e amount)
  "The kit meter (Inferno) of E's form, if it has one and isn't running as a timer."
  (let ((g (gauges e)) (m (kit-meter (kit-of e))))
    (when (and m (plusp amount) (zerop (gauges-form-left g)))
      (setf (gauges-meter g) (f32 (gauge-add (gauges-meter g) amount (getf m :max)))))))

;;; ---------------------------------------------------------------- one hit
(defun apply-hit (att def hw sx sz &key mv hazard def-state (bonus 0) crush x z)
  "Apply hit HW of ATT (a fighter) to DEF, coming from (SX SZ) (the attacker or the HAZARD: guard
facing and push direction). MV, BONUS (damage added: the stance's stored) and CRUSH: ATT's move
and its state when the hit was collected (in a trade the first hit applied may already have put ATT
in hitstun). DEF-STATE: DEF's triangle state when collected. X Z: where to show it. Sets the global
hitstop (sim timing). Returns RESOLVE-CONTACT's result (NIL = no effect)."
  (let* ((fa (fighter att)) (fd (fighter def)) (flags (hw-flags hw))
         (p (pos-of def))
         (res (resolve-contact def-state
                               :breaker (member :breaker flags)
                               :guard-crush (or (member :guard-crush flags) crush)
                               :quick (and mv (eq (mv-kind mv) :quick))
                               :ignore-armor (passive-p att :ignore-armor)
                               :in-front (in-front-p (yaw-of def) (aref p 0) (aref p 2) sx sz *guard-arc*)
                               :armor-vs-quick (passive-p def :armor-vs-quick)))
         (x (or x (aref p 0))) (z (or z (aref p 2))) (y (+ (aref p 1) 1.1))
         (base (+ (hw-dmg hw) bonus))
         (own (and mv (eq (fighter-move fa) mv))))      ; the attacker is still in that move
    (when res
      (let ((first (and own (null (fighter-contact fa)))))
        (when own
          (setf (fighter-contact fa) (if (eq res :blocked) (or (fighter-contact fa) :block) :hit))
          (when (< (fighter-land-sf fa) 0) (setf (fighter-land-sf fa) (fighter-sf fa))))
        (clog "~a ~a -> ~a ~a ~d" (side-name att) (if mv (mv-name mv) (if hazard (hazard-kind hazard) :counter))
              (side-name def) res base)
        (ecase res
          ((:hit :counter)
           (multiple-value-bind (react hits launches air)
               (combo-step (hw-react hw) (eq (fighter-state fd) :air) (fighter-combo-hits fd)
                           (fighter-combo-launches fd) (fighter-combo-air fd))
             (setf (fighter-combo-hits fd) hits (fighter-combo-launches fd) launches (fighter-combo-air fd) air)
             (let* ((lost (- *konpaku-max* (gauges-konpaku (gauges att))))
                    (dmg (hit-damage base (kit-atk-mods (kit-of att) lost) nil hits (eq res :counter)))
                    (stun (or (hw-stun hw) (hitstun react (eq res :counter)))))
               (setf (gauges-best-combo (gauges att)) (max hits (gauges-best-combo (gauges att))))
               (add-meter att (hw-meter hw))
               (hitstop (hw-hs hw))
               (emit :hit att def x y z (hw-hs hw) (eq res :counter) dmg (if hazard :fire (if mv (mv-kind mv) :counter)))
               (unless (deal-damage att def dmg)          ; (a broken soul crumples in its cinematic)
                 (set-reaction def react stun sx sz (hw-kb hw))))))
          (:armored
           (hitstop *hitstop-block*)
           (emit :armored def x y z)
           (deal-damage att def (hit-damage base (kit-atk-mods (kit-of att) 0) nil 1 nil)))
          (:absorbed
           (let ((dmg (hit-damage base (kit-atk-mods (kit-of att) 0) nil 1 nil)))
             (setf (fighter-stored fd) (stance-store (fighter-stored fd) dmg))
             (hitstop *hitstop-block*)
             (emit :absorbed def x y z)
             (deal-damage att def dmg)))
          (:blocked
           (let* ((adv (if (and mv (integerp (mv-adv-block mv))) (mv-adv-block mv) 0))
                  (stun (if mv (blockstun (mv-total mv) (fighter-sf fa) adv) *hazard-blockstun*))
                  (chip (chip-damage base (or (hw-chip hw) (and mv (kit-blade-chip (kit-of att))))
                                     (gauges-reishi (gauges def)))))
             (set-blockstun def stun sx sz adv)
             (when (plusp chip) (deal-damage att def chip))
             (when (and hazard (plusp (hw-meter hw))) (add-meter att *meter-on-block*))
             (hitstop *hitstop-block*)
             (emit :blocked att def x y z)))
          (:guard-break
           (set-reaction def :guard-break *guard-break-stun* sx sz *guard-break-kb*)
           (hitstop *hitstop-breaker*)
           (emit :guard-break att def x y z))
          (:stance-break
           (set-reaction def :crumple *stance-break-stun* sx sz *stance-break-kb*)
           (hitstop *hitstop-breaker*)
           (emit :stance-break att def x y z)))
        (when (and first (mv-on-land mv) (not *cine*)) (funcall (mv-on-land mv) att)))
      res)))

;;; ---------------------------------------------------------------- the system
(defstruct pending
  "One hit collected this step, with what it needs of the attacker as he was then (they are applied
after all are collected). I: the move's window index; HAZARD: the hazard dealing it (NIL = melee);
STATE: the defender's triangle state; MV BONUS CRUSH: the attacker's move, stored damage, guard crush."
  att def hw (i 0) (sx 0f0) (sz 0f0) hazard state mv (bonus 0) crush)

(defvar *pending* nil "Hits collected this step, applied together.")

(defun collect-melee (e f)
  "E's move windows open this frame that touch the opponent (each window hits once), and a perfect
Hoho's counter strike on its frame (it always connects)."
  (let ((mv (fighter-move f)) (o (fighter-opp f)) (p (pos-of e)))
    (when (entity-alive-p o)
      (when (and (eq (fighter-state f) :hoho) (fighter-perfect f) (= (fighter-sf f) *hoho-counter-strike*))
        (push (make-pending :att e :def o :hw *perfect-hw* :sx (aref p 0) :sz (aref p 2) :state (defender-state o))
              *pending*))
      (when (and (eq (fighter-state f) :move) (eq (fighter-phase f) :main))
        (let* ((sf (fighter-sf f)) (q (pos-of o)) (yaw (yaw-of e))
               (fx (f32 (fwd-x yaw))) (fz (f32 (fwd-z yaw))) (ob (model-body (model o))))
          (loop for w across (mv-hits mv) for i from 0
                when (and (<= (hw-from w) sf) (< sf (hw-to w)) (not (logbitp i (fighter-hits f)))
                          (loop for v in (hw-vols w)
                                thereis (vol-hit-p v (aref p 0) (aref p 1) (aref p 2) fx fz (aref q 0) (aref q 1) (aref q 2)
                                                   (body-hurt-r ob) (body-hurt-h ob) 0f0)))
                  do (push (make-pending :att e :def o :hw w :i i :sx (aref p 0) :sz (aref p 2)
                                         :state (defender-state o) :mv mv
                                         :bonus (fighter-dmg-bonus f) :crush (fighter-crush f))
                           *pending*)))))))

(defun cut-hazards (e f)
  "Nozarashi (:projectile-cut): an open window of E's move destroys the opponent's hazards it touches."
  (let ((mv (fighter-move f)))
    (when (and (passive-p e :projectile-cut) (eq (fighter-state f) :move) (eq (fighter-phase f) :main))
      (let* ((sf (fighter-sf f)) (p (pos-of e)) (yaw (yaw-of e)) (fx (f32 (fwd-x yaw))) (fz (f32 (fwd-z yaw))))
        (loop for w across (mv-hits mv)
              when (and (<= (hw-from w) sf) (< sf (hw-to w)))
                do (do-entities (h (hz hazard))
                     (when (and (not (eql (hazard-owner hz) e)) (member (hazard-kind hz) '(:wave :fireball :skeleton))
                                (<= (hazard-delay hz) 0)
                                (loop for v in (hw-vols w)
                                      thereis (vol-hit-p v (aref p 0) (aref p 1) (aref p 2) fx fz
                                                         (hazard-x hz) 0f0 (hazard-z hz) (f32 (max 0.5 (hazard-size hz)))
                                                         1.8f0 0f0)))
                       (emit :hazard-cut (hazard-x hz) (f32 (+ 1.0 (hazard-y hz))) (hazard-z hz))
                       (clog "~a cuts ~a" (side-name e) (hazard-kind hz))
                       (destroy-entity h))))))))

(defun clash! (a b)
  "Breaker vs Breaker: both pushed *CLASH-PUSH* apart and stunned *CLASH-STUN*, no damage."
  (let* ((p (pos-of a)) (q (pos-of b)))
    (set-reaction a :clash *clash-stun* (aref q 0) (aref q 2) (* 0.5 *clash-push*))
    (set-reaction b :clash *clash-stun* (aref p 0) (aref p 2) (* 0.5 *clash-push*))
    (hitstop *hitstop-breaker*)
    (emit :clash (* 0.5 (+ (aref p 0) (aref q 0))) 1.2 (* 0.5 (+ (aref p 2) (aref q 2))))
    (clog "CLASH")))

(defun hit-system ()
  "Clash first; then collect every melee and hazard hit of this step; then apply them all; then
settle the souls they broke."
  (let ((a nil) (b nil))
    (do-entities (e (f fighter)) (if a (setf b e) (setf a e)))
    (when (and a b)
      (let ((pa (breaker-phase a)) (pb (breaker-phase b)))
        (when (and pa pb (breaker-clash-p pa pb (fighter-dist (fighter a))))
          (clash! a b)))))
  (do-entities (e (f fighter)) (cut-hazards e f))
  (do-entities (e (f fighter)) (collect-melee e f))
  (collect-hazard-hits)
  (let ((hits (nreverse *pending*)))
    (setf *pending* nil)
    (dolist (h hits)
      (let* ((hz (pending-hazard h)) (fa (fighter (pending-att h))) (mv (pending-mv h))
             (res (apply-hit (pending-att h) (pending-def h) (pending-hw h) (pending-sx h) (pending-sz h)
                             :mv mv :hazard hz :def-state (pending-state h)
                             :bonus (pending-bonus h) :crush (pending-crush h))))
        (when res
          (cond (hz (hazard-connected hz))
                ((and mv (eq mv (fighter-move fa)))   ; (an on-land hook may have started the next move)
                 (setf (fighter-hits fa) (logior (fighter-hits fa) (ash 1 (pending-i h))))))))))
  (settle-soul-breaks))

;;; ---------------------------------------------------------------- perfect Hoho
(defun perfect-now-p (e)
  "Would a Hoho started now by E be PERFECT? An opponent hit volume (move or hazard) active now or
within *PERFECT-LEAD* frames overlaps E's hurt cylinder grown by *PERFECT-INFLATE* (rules.lisp)."
  (let* ((o (opp-of e)) (fo (fighter o)) (mv (fighter-move fo)) (p (pos-of e)) (q (pos-of o))
         (b (model-body (model e))) (yaw (yaw-of o)))
    (or (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :main)
             (loop for w across (mv-hits mv)
                   thereis (perfect-hoho-p (fighter-sf fo) (hw-from w) (hw-to w) (hw-vols w)
                                           (aref q 0) (aref q 1) (aref q 2) (f32 (fwd-x yaw)) (f32 (fwd-z yaw))
                                           (aref p 0) (aref p 1) (aref p 2) (body-hurt-r b) (body-hurt-h b))))
        (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :dash)      ; a Breaker about to strike
             (<= (fighter-dist fo) (+ *breaker-trigger* 0.5)))
        (hazard-threat-p o e))))

;;; ---------------------------------------------------------------- Burst Reverse
(defun burst-ok-p (e)
  "May E Burst now (rules BURST-ALLOWED-P): in a reaction or airborne, inputs not locked, past the
combo's 2nd hit, 2 bars."
  (let ((f (fighter e)))
    (burst-allowed-p (and (member (fighter-state f) '(:stun :air)) (zerop (fighter-lock f)))
                     (fighter-combo-hits f) (gauges-reiatsu (gauges e)))))

(defun burst! (e)
  "Burst Reverse (FIGHTER-SYSTEM applies it once both fighters have stepped): E spends
*COST-BURST* bars and is neutral at once (on the ground), invulnerable *BURST-INVULN* f, his combo
over; the attacker's move / Hoho / step / run ends and he slides *BURST-PUSH* away, not stunned.
A short global hitstop."
  (let* ((f (fighter e)) (g (gauges e)) (mo (motion e)) (o (fighter-opp f)) (p (pos-of e)) (q (pos-of o)))
    (setf (gauges-reiatsu g) (f32 (spend-bars (gauges-reiatsu g) *cost-burst*))
          (aref p 1) 0f0 (motion-grounded mo) t (motion-kb-left mo) 0)
    (to-idle e 0)
    (setf (fighter-invuln f) *burst-invuln*)
    (when (member (state-of o) '(:move :hoho :step :run))
      (to-idle o 0)
      (setf (model-alpha (model o)) 1f0))
    (set-slide o *burst-push* *burst-push-frames* (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)))
    (hitstop *burst-hitstop*)
    (emit :burst e o)
    (clog "~a BURST" (side-name e))))

;;; ---------------------------------------------------------------- forms, awakening
(defun set-form (e form)
  "E's character changes to FORM: the old form's exit hook, the new kit, its timer, look and entry hook."
  (let* ((f (fighter e)) (g (gauges e)) (old (fighter-kit f)) (new (find-kit (fighter-character f) form)))
    (when (and (kit-exit-hook old) (not (eq old new))) (funcall (kit-exit-hook old) e))
    (setf (fighter-kit f) new (fighter-form f) form (gauges-burn-step g) 0
          (gauges-form-left g) (if (kit-duration new) (seconds->frames (kit-duration new)) 0)
          (gauges-form-total g) (gauges-form-left g))
    (refresh-look e)
    (when (kit-enter-hook new) (funcall (kit-enter-hook new) e))
    (emit :form e form)
    (clog "~a form ~a" (side-name e) form)))

(defun awaken! (e)
  "Awakening (once per match): the kit's awakened form and its heal, then the form's :cine if it has
one (both fighters idle after it)."
  (let* ((g (gauges e)) (o (opp-of e)))
    (setf (gauges-awakened g) t (gauges-awaken g) 0f0 (gauges-evolution g) nil)
    (set-form e (kit-awaken-form (kit-of e)))
    (setf (gauges-reishi g) (min (gauges-reishi-max g) (+ (gauges-reishi g) (kit-heal (kit-of e)))))
    (emit :awaken e)
    (if (kit-cine (kit-of e))
        (start-cine (kit-cine (kit-of e)) e o :after (lambda () (to-idle e 0) (to-idle o 0)))
        (to-idle e 0))))

;;; ---------------------------------------------------------------- Kikon, Soul Break, reset
(defun victim-stun-left (v)
  "Frames of hitstun V has left (0 when not in a reaction)."
  (let ((f (fighter v)))
    (case (fighter-state f)
      (:stun (max 0 (- (fighter-stun f) (fighter-sf f))))
      (:air 1)
      (t 0))))

(defun kikon-ok-p (e)
  "May E press Kikon now (rules KIKON-AVAILABLE-P): the opponent is red, and E's move landed and is
in its cancel window, or the opponent is still in hitstun."
  (let* ((f (fighter e)) (o (opp-of e)) (go (gauges o)) (mv (fighter-move f)) (moving (eq (fighter-state f) :move)))
    (kikon-available-p (gauges-reishi go) (gauges-reishi-max go)
                       :landed (and moving (eq (fighter-contact f) :hit))
                       :sf (fighter-sf f) :hit-frame (fighter-land-sf f) :total (if moving (mv-total mv) 0)
                       :victim-stun (victim-stun-left o))))

(defun settle-konpaku (att def soul-break)
  "Konpaku at connect time (KIKON-RESULT): DEF loses 2 / 3 (+1 on a Soul Break), his Reishi refills.
Returns T when DEF is out of Konpaku."
  (let ((gd (gauges def)))
    (multiple-value-bind (left lost ko) (kikon-result (gauges-konpaku gd) (kit-awakening (kit-of att)) soul-break)
      (setf (gauges-konpaku gd) left (gauges-reishi gd) (gauges-reishi-max gd))
      (unless (gauges-awakened gd)
        (setf (gauges-awaken gd) (f32 (gauge-add (gauges-awaken gd) (awakening-gain 0 0 lost) *awaken-max*))))
      (incf (gauges-kikons (gauges att)))
      (emit :konpaku def lost)
      (clog "~a ~a on ~a: -~d konpaku, ~d left" (side-name att) (if soul-break "SOUL BREAK" "KIKON") (side-name def) lost left)
      ko)))

(defun kikon! (e)
  "Kikon: settled now, then its cinematic, then the reset (or the finish). The hazards still out are
cleared first: the reset clears them anyway, and frozen through the cinematic their looks would hang
in its shots."
  (let* ((o (opp-of e)) (mv (kit-command-move (kit-of e) :kikon)) (ko (settle-konpaku e o nil)))
    (when (mv-callout mv) (callout e (mv-callout mv)))
    (emit :kikon e o)
    (clear-hazards)
    (start-cine (mv-cine mv) e o :after (lambda () (if ko (match-over e) (reset-round e o))))))

(defun settle-soul-breaks ()
  "Reishi reached 0 (*SOUL-BREAKS*): automatic Soul Break (Kikon count + 1) for every victim of this
step at once, so a lethal trade breaks both; one cinematic, then the reset, or the finish (a draw
when both souls ran out)."
  (let ((sb (reverse *soul-breaks*)))
    (setf *soul-breaks* nil)
    (when sb
      (let ((kos (loop for (att . def) in sb when (settle-konpaku att def t) collect def))
            (a (car (first sb))) (v (cdr (first sb))))
        (loop for (att . def) in sb do (emit :soul-break att def))
        (clear-hazards)
        (start-cine 'soul-break-cine a v
                    :after (lambda () (cond ((null kos) (reset-round a v))
                                            ((rest kos) (match-over nil))
                                            (t (match-over (opp-of (first kos)))))))))))

(defun reset-round (a v)
  "After a Kikon / Soul Break (§1): both placed *RESET-DISTANCE* apart facing, *RESET-NEUTRAL* frames
of neutral, P1 on the left of the view again, hazards cleared, the kit's :reset-reiatsu (Kenpachi)."
  (let ((p (pos-of a)) (q (pos-of v)))
    (multiple-value-bind (ax az bx bz) (reset-placement (aref p 0) (aref p 2) (aref q 0) (aref q 2))
      (v3-set! p (f32 ax) 0f0 (f32 az)) (v3-set! q (f32 bx) 0f0 (f32 bz))))
  (face-each-other a v)
  (if (zerop (fighter-side (fighter a))) (view-step a v t) (view-step v a t))
  (clear-hazards)
  (dolist (e (list a v))
    (let ((f (fighter e)) (g (gauges e)) (mo (motion e)))
      (setf (motion-grounded mo) t (motion-kb-left mo) 0 (fighter-lock f) *reset-neutral* (fighter-combo-dmg f) 0
            (gauges-reiatsu g) (f32 (gauge-add (gauges-reiatsu g) (kit-reset-reiatsu (kit-of e)) *reiatsu-max*)))
      (fill (motion-vel mo) 0f0)
      (vpad-clear! (pilot-vpad (pilot e)))
      (to-idle e 0)))
  (emit :reset))

;;; ---------------------------------------------------------------- gauges per step
(defun gauge-system ()
  "Regen, timed forms (burn, drain, end), the meter's full form (Hellfire), EVOLUTION."
  (do-entities (e (f fighter) (g gauges))
    (let ((kit (fighter-kit f)))
      (setf (gauges-reiatsu g) (f32 (gauge-add (gauges-reiatsu g) (reiatsu-gain 0 0 1) *reiatsu-max*)))
      (when (> (fighter-combo-dmg f) 0)                  ; the combo's damage shows until he is up again
        (unless (member (fighter-state f) '(:stun :air :down :wakeup :guard-hit)) (setf (fighter-combo-dmg f) 0)))
      (when (plusp (gauges-form-left g))
        (let ((burn (kit-burn kit)))
          (when (plusp burn)
            (setf (gauges-reishi g) (burn (gauges-reishi g) (burn-amount (gauges-reishi-max g) burn (gauges-burn-step g)))))
          (incf (gauges-burn-step g))
          (when (zerop (decf (gauges-form-left g)))
            (set-form e (kit-inherit kit)))))
      (let ((m (kit-meter kit)))
        (when (and m (zerop (gauges-form-left g)) (>= (gauges-meter g) (getf m :max)) (getf m :full-form))
          (setf (gauges-meter g) 0f0)                    ; the bar now shows the form's timer
          (set-form e (getf m :full-form))
          (emit :hellfire e)))
      (when (and (not (gauges-awakened g)) (not (gauges-evolution g)) (>= (gauges-awaken g) *awaken-max*))
        (setf (gauges-evolution g) t)
        (emit :evolution e)
        (clog "~a EVOLUTION" (side-name e))))))
