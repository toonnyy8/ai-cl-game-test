;;;; fighter.lisp — FIGHTER-SYSTEM: the generic fighter (design-v1 §3). Each fixed step, per fighter:
;;;; vpad → command (vpad-command) → state machine → move tick + the kit's hooks → physics → arena
;;;; clamp. What a character does is data (kit.lisp) plus hook symbols; this file never names one.
;;;; The rules (rules.lisp) decide windows, costs and advantages; this file applies them.
;;;;
;;;; States (FIGHTER-STATE):
;;;;   :idle   stand / walk / strafe (auto-faces)      :guard      guard held (blocks after *GUARD-RAISE*)
;;;;   :guard-hit  blockstun                           :step       24 f hop, iframes f3-f9
;;;;   :run    Step held past the hop: run (phase :run), then :brake on release (no iframes)
;;;;   :hoho   vanish, reappear behind (iframes f1-f14; perfect → counter strike)
;;;;   :move   a kit move; phase :hold (charge / stance) :aura :dash (Breaker, Kikon rush) :main (S / A / R)
;;;;   :stun   a grounded reaction (phase = :flinch :stagger :knockback :guard-break :crumple :clash)
;;;;   :air    launched / knocked down, until landing  :down :wakeup  (invulnerable)
;;;;   :cine :intro :win :lose   owned by a cinematic / the flow
;;;; Hits are not here: combat.lisp resolves them after every fighter has moved.
(in-package :duel)

(defparameter *perfect-hw*
  (make-hitwin :dmg *perfect-counter-damage* :react :stagger :stun *perfect-counter-stun* :hs *hitstop-heavy*)
  "The perfect Hoho's automatic counter strike.")

;;; ---------------------------------------------------------------- creation
(defun p1-down-p (device name)
  (case device (:key (key-down name)) (:touch (touch-button name)) (t (pad-down name 0))))
(defun p2-down-p (device name) (if (eq device :key) (key-down name) (pad-down name 1)))
(defun p1-reader (vp)
  (touch-read-begin)                                     ; this read's gesture pulses (onehand.lisp)
  (vpad-read! vp *p1-bindings* #'p1-down-p (+ (pad-lx 0) (touch-sx *touch*)) (+ (pad-ly 0) (touch-sy *touch*))))
(defun p2-reader (vp) (vpad-read! vp *p2-bindings* #'p2-down-p (pad-lx 1) (pad-ly 1)))

(defun spawn-fighter (side character x z yaw &key cpu (difficulty :normal) mirror)
  "A fighter entity for SIDE (0 / 1) playing CHARACTER's :base kit at (X 0 Z) facing YAW. CPU:
add a brain of DIFFICULTY (else the side's keyboard / pad drives the vpad). MIRROR: P2 of a mirror
match (tinted)."
  (let* ((kit (find-kit character :base))
         (e (spawn-entity (make-transform :yaw (f32 yaw)) (make-motion)
                          (make-model :body (find-body (kit-body kit))
                                      :tint (and mirror *mirror-tint*) :rim (and mirror *mirror-rim*))
                          (make-blade)
                          (make-fighter :side side :character character :kit kit)
                          (make-gauges :reishi (kit-reishi kit) :reishi-max (kit-reishi kit) :konpaku *konpaku-max*)
                          (make-pilot :vpad (new-vpad :reader (and (not cpu) (if (zerop side) #'p1-reader #'p2-reader)))
                                      :cam-relative (not cpu)))))
    (v3-set! (pos-of e) (f32 x) 0f0 (f32 z))
    (when cpu (add-component e (make-brain :difficulty difficulty :delay (getf *ai-delay* difficulty 14))))
    (refresh-look e)
    (play-clip e (kit-stance kit) :blend 0)
    e))

(defvar *hide-sets* (make-hash-table :test 'equal) "Hidden part tags -> HIDE-SET (made once per list).")

(defun hide-set (tags)
  "The DRAW-BODY :hide lists of a body with TAGS hidden, one per expression (:neutral :shout :hurt: the other two faces'
tags added, since a non-NIL :hide replaces the face list): a vector made once per TAGS, or NIL when TAGS is empty."
  (and tags
       (or (gethash tags *hide-sets*)
           (setf (gethash tags *hide-sets*)
                 (coerce (loop for face in '(:neutral :shout :hurt) collect (append tags (face-hide face))) 'simple-vector)))))

(defun face-hide-list (m face)
  "The DRAW-BODY :hide list of model M (its HIDE-SET) with expression FACE shown, or NIL (the body's own face list)."
  (let ((h (model-hide m))) (and h (svref h (case face (:shout 1) (:hurt 2) (t 0))))))

(defun refresh-look (e)
  "Body, weapon and hidden parts of E's current form (the kit's :body, :weapon, :hide; a form with the arm meter shows
one forearm crack per spent pip: :crack-1 .. :crack-4)."
  (let* ((kit (kit-of e)) (m (model e)) (hide (kit-hide kit)))
    (when (kit-pips kit)
      (let ((spent (- (getf (kit-pips kit) :n) (round (gauges-meter (gauges e))))))
        (setf hide (remove-if (lambda (tag) (let ((k (position tag '(:crack-1 :crack-2 :crack-3 :crack-4)))) (and k (< k spent))))
                              hide))))
    (setf (model-body m) (find-body (kit-body kit))
          (model-weapon m) (kit-weapon kit) (model-hide m) (hide-set hide) (model-alpha m) 1f0)))

;;; ---------------------------------------------------------------- animation
(defvar *missing-clips* nil "Clip names already reported missing.")

(defun clip-or-fallback (e clip)
  "CLIP if the art defines it, else E's stance (logged once per name: never crash on missing art)."
  (if (and clip (find-clip clip nil))
      clip
      (progn (when (and clip (not (member clip *missing-clips*)))
               (push clip *missing-clips*) (log-msg "missing clip ~s" clip))
             (let ((f (fighter e))) (if f (kit-stance (fighter-kit f)) :stance)))))

(defun play-clip (e clip &key (blend 4) (speed 1.0) (time 0.0) (restart t))
  "Start CLIP on E's model (BLEND frames of crossfade; see ANIM-PLAY); a body variant may play its own version of it
(BODY-CLIPS)."
  (let ((b (model-body (model e))))
    (anim-play (model-anim (model e)) (clip-or-fallback e (or (and b (getf (body-clips b) clip)) clip))
               :blend blend :speed speed :time time :restart restart)))

;;; ---------------------------------------------------------------- geometry
(defun move-param (e key)
  "For hooks: parameter KEY of E's current move (its :params plist)."
  (getf (mv-params (fighter-move (fighter e))) key))

(defun ahead (e d)
  "Values x z of the point D metres in front of fighter E."
  (let ((p (pos-of e)) (yaw (yaw-of e)))
    (values (+ (aref p 0) (* d (fwd-x yaw))) (+ (aref p 2) (* d (fwd-z yaw))))))

(defun face-yaw-to (e x z)
  "The yaw from E toward the point (X Z)."
  (let ((p (pos-of e))) (dir-yaw (- x (aref p 0)) (- z (aref p 2)))))

(defun turn-to-opp (e f max-step)
  "Turn E toward his opponent by at most MAX-STEP radians."
  (let ((tf (transform e)))
    (when (> (fighter-dist f) 0.01)
      (setf (transform-yaw tf) (f32 (angle-wrap (turn-toward (transform-yaw tf) (face-yaw-to e (fighter-ox f) (fighter-oz f)) max-step)))))))

(defun set-slide (e dist frames dx dz)
  "Slide E DIST metres over FRAMES along (DX DZ) (knockback, pushback, Step, clash)."
  (let* ((mo (motion e)) (kb (motion-kb mo)) (l (max 1e-4 (sqrt (+ (* dx dx) (* dz dz))))) (k (/ dist (max 1 frames) l)))
    (setf (aref kb 0) (f32 (* dx k)) (aref kb 2) (f32 (* dz k)) (motion-kb-left mo) frames)))

;;; ---------------------------------------------------------------- the view humans steer by
;;; A human's stick is camera-relative. The sim must not read the render camera (it lags on real
;;; time: a replay would differ), so the sim owns the view's DIRECTION: VIEW-STEP keeps it on its side
;;; of the fighter axis each step, and camera.lisp smooths the render camera toward it. Two views:
;;; the pair camera (side-on, *VIEW-X* / *VIEW-Z*) and the camera behind P1 (*BEHIND-YAW*, looking
;;; from P1 at P2, turned at most *BEHIND-TURN* per step: after a Hoho it swings round instead of
;;; snapping). *VIEW-BEHIND* says which one humans steer by (flow.lisp sets it: VS CPU with the
;;; BEHIND option); CPU pilots never read the view, so a CPU match can't depend on it.
(declaim (single-float *view-x* *view-z* *view-side* *behind-yaw*))
(defvar *view-x* 0f0 "Unit direction (x z) from the fighters' midpoint toward the pair camera ...")
(defvar *view-z* 1f0 "... z.")
(defvar *view-side* 1f0 "+1: the view shows P1 on the left of the screen; -1: on the right.")
(defvar *behind-yaw* 0f0 "The behind camera's view yaw: from P1 toward P2, rate-limited.")
(defvar *view-behind* nil "Humans steer by the behind camera (else the pair camera).")
(defparameter *behind-turn* 300.0
  "Degrees per second the behind view turns toward P1->P2: a Hoho behind P1 swings it round in ~0.6 s.")

(defun view-step (a b &optional reset)
  "Keep the pair view on its side of the A (P1) -> B axis: of the two perpendiculars take the one
nearest last step's, so it never swings 180 deg after a Hoho. RESET: P1 on the left (battle start,
every Kikon reset). Screen right is SIDE x (A->B) for a right-handed look-at."
  (let* ((p (pos-of a)) (q (pos-of b)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (d (sqrt (+ (* dx dx) (* dz dz)))))
    (when (> d 0.01)
      (let* ((nx (/ (- dz) d)) (nz (/ dx d))
             (side (if (or reset (>= (+ (* nx *view-x*) (* nz *view-z*)) 0)) 1f0 -1f0)))
        (setf *view-side* side *view-x* (f32 (* side nx)) *view-z* (f32 (* side nz))
              *behind-yaw* (f32 (if reset
                                    (dir-yaw dx dz)
                                    (angle-wrap (turn-toward *behind-yaw* (dir-yaw dx dz) (track-step *behind-turn*))))))))))

(defun stick-relative (e f)
  "E's stick as (values toward strafe) relative to his opponent: a human's stick is read through the
view (camera-relative, VIEW-STEP); the CPU writes (strafe, toward) directly."
  (let* ((vp (pilot-vpad (pilot e))) (sx (vpad-sx vp)) (sy (vpad-sy vp)))
    (if (pilot-cam-relative (pilot e))
        (let ((p (pos-of e)))
          (stick-toward-strafe sx sy (if *view-behind* *behind-yaw* (dir-yaw (- *view-x*) (- *view-z*)))
                               (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f)))
        (values sy sx))))

;;; ---------------------------------------------------------------- state changes
(defun to-idle (e &optional (blend 6))
  "Back to neutral: stance clip, combo over (a victim leaving his reaction ends the combo)."
  (let ((f (fighter e)))
    (setf (fighter-state f) :idle (fighter-sf f) 0 (fighter-phase f) nil (fighter-move f) nil
          (fighter-crush f) nil (fighter-dmg-bonus f) 0
          (fighter-combo-hits f) 0 (fighter-combo-launches f) 0 (fighter-combo-air f) 0)
    (fill (motion-vel (motion e)) 0f0)
    (play-clip e (kit-stance (fighter-kit f)) :blend blend)))

(defun callout (e text)
  (let ((f (fighter e))) (setf (fighter-callout f) text (fighter-callout-t f) *callout-frames*)))

(defun start-move (e mv &optional button)
  "Enter move MV (a MOVE of E's kit). Frame (MV-ENTER mv) is this step; MOVE-STEP advances it."
  (let ((f (fighter e)) (enter (mv-enter mv)))
    (setf (fighter-state f) :move (fighter-move f) mv (fighter-sf f) enter (fighter-hits f) 0
          (fighter-contact f) nil (fighter-queued f) nil (fighter-chained f) nil (fighter-land-sf f) -1 (fighter-dmg-bonus f) 0 (fighter-crush f) nil
          (fighter-stored f) 0                           ; an interrupted stance keeps nothing
          (fighter-button f) button (fighter-hold f) 0 (fighter-perfect f) nil
          (fighter-follow f) nil (fighter-armor-left f) (mv-armor-hits mv)
          (fighter-phase f) (cond ((member (mv-kind mv) '(:breaker :kikon)) :aura) ((mv-hold mv) :hold) (t :main)))
    (fill (motion-vel (motion e)) 0f0)
    (play-clip e (mv-clip mv) :blend (mv-blend mv) :speed (mv-clip-speed mv)
                              :time (/ (* enter (mv-clip-speed mv)) 60.0))
    (if (eq (mv-kind mv) :kikon)
        (callout e "KIKON")                             ; its own name shows if it becomes the Kikon
        (when (mv-callout mv) (callout e (mv-callout mv))))
    (case (mv-kind mv)
      (:sp (let ((o (opp-of e)))                        ; super flash: the opponent alone freezes
             (setf (fighter-freeze-next (fighter o)) (max (fighter-freeze-next (fighter o)) *super-freeze*))
             (emit :super e)))
      (:breaker (emit :breaker e))
      (:kikon (emit :rush e)))
    (clog "~a move ~a~@[ ~a~]" (side-name e) (mv-name mv) (let ((b (brain e))) (and b (brain-why b))))
    (when (eq (fighter-phase f) :main)                 ; a hook on the move's first frame (NOMIHOSE's cash-out)
      (loop for (fr hook) in (mv-on-frame mv) when (= fr enter) do (funcall hook e)))
    mv))

(defun enter-main (e f mv)
  "A hold / Breaker move leaves its pre-strike phase: the move proper starts at frame 0."
  (setf (fighter-phase f) :main (fighter-sf f) 0)
  (fill (motion-vel (motion e)) 0f0)
  (when (mv-clip-2 mv) (play-clip e (mv-clip-2 mv) :blend 0 :speed (mv-clip-speed mv)))
  (when (eq (mv-kind mv) :breaker) (emit :breaker-end e)))

(defun start-step (e f)
  "Step: a 2.5 m hop in the stick direction (neutral = back), iframes f3-f9, 24 f."
  (multiple-value-bind (to st) (stick-relative e f)
    (multiple-value-bind (to st) (step-direction to st)
      (let ((p (pos-of e)))
        (multiple-value-bind (dx dz) (toward-strafe-dir to st (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f))
          (set-slide e (multiple-value-bind (k ux uz) (opp-field e f)   ; her cold field shortens a Step away from her
                         (if k
                             (field-step *step-distance* (/ (- (+ (* dx ux) (* dz uz))) (max 1e-4 (sqrt (+ (* dx dx) (* dz dz)))))
                                         (getf k :step))
                             *step-distance*))
                     12 dx dz)))
      (setf (fighter-state f) :step (fighter-sf f) 0 (fighter-move f) nil)
      (fill (motion-vel (motion e)) 0f0)
      (let ((h (kit-hook (fighter-kit f) :step))) (when h (funcall h e)))   ; the form's own take-off (a clone)
      (play-clip e (cond ((> (abs st) (abs to)) (if (> st 0) :sh-step-r :sh-step-l)) ((> to 0) :sh-step-f) (t :sh-step-b))
                 :blend 2)
      (clog "~a step~@[ ~a~]" (side-name e) (let ((b (brain e))) (and b (brain-why b))))
      (emit :step e))))

(defun run-yaw (e f)
  "The yaw a runner wants: the stick direction relative to the opponent (neutral = at him)."
  (multiple-value-bind (to st) (stick-relative e f)
    (multiple-value-bind (to st) (step-direction to st 1.0)
      (let ((p (pos-of e)))
        (multiple-value-bind (dx dz) (toward-strafe-dir to st (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f))
          (dir-yaw dx dz))))))

(defun run-clip (e f)
  "The run clip of E's kit for the way he goes relative to where he faces (the opponent): forward run,
back-skate, or a side slide (the kit's :run-clips)."
  (let* ((hy (fighter-run-yaw f)) (fy (yaw-of e)) (hx (fwd-x hy)) (hz (fwd-z hy)) (fx (fwd-x fy)) (fz (fwd-z fy))
         (ahead (+ (* hx fx) (* hz fz))) (right (- (* hz fx) (* hx fz))) (clips (kit-run-clips (fighter-kit f))))
    (cond ((> ahead 0.5) (first clips)) ((< ahead -0.5) (second clips)) ((> right 0) (third clips)) (t (fourth clips)))))

(defun start-run (e f)
  "Step still held when the hop ends: run (RUN-STEP) toward the stick direction at once, facing the opponent."
  (setf (fighter-state f) :run (fighter-sf f) 0 (fighter-phase f) :run (fighter-run-yaw f) (f32 (run-yaw e f)))
  (play-clip e (run-clip e f) :blend 5 :speed (/ (kit-run (fighter-kit f)) 8.0))
  (clog "~a dash~@[ ~a~]" (side-name e) (let ((b (brain e))) (and b (brain-why b))))
  (emit :step e))

(defun spend-fs (g amount)
  "Spend AMOUNT of flash-step (the regen waits *FS-DELAY* again)."
  (setf (gauges-fs g) (f32 (max 0.0 (- (gauges-fs g) amount))) (gauges-fs-idle g) 0))

(defun start-hoho (e f)
  "Hoho: spend *FS-HOHO* flash-step, vanish, reappear behind the opponent (HOHO-STEP). Checks PERFECT
now (a perfect one refunds *FS-REFUND*)."
  (let ((g (gauges e)))
    (spend-fs g *fs-hoho*)
    (setf (fighter-perfect f) (perfect-now-p e)          ; (before leaving the move: a cancel Hoho)
          (fighter-state f) :hoho (fighter-sf f) 0 (fighter-move f) nil
          (fighter-hoho-lock f) (+ *hoho-frames* *hoho-lockout*))
    (fill (motion-vel (motion e)) 0f0)
    (let ((p (pos-of e))) (emit :hoho-out e (aref p 0) (aref p 2)))
    (clog "~a hoho" (side-name e))
    (when (fighter-perfect f)
      (let ((o (opp-of e)))
        (incf (gauges-perfects g))
        (setf (gauges-fs g) (f32 (min *fs-max* (+ (gauges-fs g) *fs-refund*))))
        (setf (fighter-lock-next (fighter o)) *perfect-lock*)
        (respect o)
        (slowmo *perfect-slowmo-scale* *perfect-slowmo-seconds*)
        (emit :perfect e o)
        (clog "~a PERFECT HOHO" (side-name e))))))

(defun cold-cost (kit command) "The cold COMMAND spends in KIT (its :cold; 0 without)." (getf (kit-cold kit) command 0))

(defun cold-spend! (e kit command)
  "COMMAND starts in KIT: its cold is spent (Rukia's cold gauge, the kit meter; never below 0)."
  (let ((c (cold-cost kit command)))
    (when (plusp c)
      (let ((g (gauges e))) (setf (gauges-meter g) (f32 (max 0.0 (- (gauges-meter g) c))))))))

(defun kit-command-ok-p (e command &optional (kit (kit-of e)) ender combo)
  "Can E start COMMAND's move (of KIT, default his form's) now: Reiatsu bars, not cooling down (its :cooldown), a pip of
the arm meter left when the command spends one (Kenpachi's Bankai: KIT-PIP-CMD-P; one more while the string he is in
owes its pip, unless it is that string's O ENDER), and L's cold (Rukia: only L is refused by cold; COMBO, a chained
follow-up, overdraws while any cold is left: rules COLD-OK-P)?"
  (let ((i (position command *kit-commands*)) (g (gauges e)))
    (and (>= (gauges-reiatsu g) (* (kit-command-cost kit command) *reiatsu-bar*))
         (or (null i) (zerop (aref (fighter-cd (fighter e)) i)))
         (or (not (kit-pip-cmd-p kit command)) (>= (gauges-meter g) (if (and (gauges-arm-owed g) (not ender)) 2f0 1f0)))
         (or (not (eq command :sig)) (cold-ok-p (gauges-meter g) (cold-cost kit :sig) combo))
         (let ((h (kit-hook kit :ok))) (or (null h) (funcall h e command combo))))))   ; the form's own price / refusal

(defun try-command (e f cmd &optional button ender with)
  "Start command CMD (pressed with vpad BUTTON: a hold / Breaker move watches it) if the rules allow
it now. A command the form drops (KIT-DROP) switches the form first, on the move's frame 0, and starts that
form's move; a refused one doesn't switch. ENDER: the O ender of a string (its pip is the string's). WITH: the move
to start instead of the command's own (L after a K link, KIT-L-LINK), under the command's checks and costs. T when
something started."
  (let ((g (gauges e)) (kit (fighter-kit f)))
    (case cmd
      (:step (unless (kit-rooted kit) (cold-spend! e kit :step) (start-step e f) t))   ; a rooted form (Rukia's zero) refuses
      (:hoho (when (and (not (kit-rooted kit)) (hoho-allowed-p nil (gauges-fs g) (fighter-hoho-lock f)))   ; Step and Hoho
               (cold-spend! e kit :hoho) (start-hoho e f) t))
      (:awaken (let ((free (awaken-state-p e f)))
                 (cond ((awaken-allowed-p free (gauges-awaken g) (gauges-awakened g)) (awaken! e) t)
                       ((and (kit-bankai-form kit) (bankai-allowed-p free (gauges-konpaku g)))
                        (bankai! e) t))))
      (:burst (when (burst-ok-p e) (setf (fighter-burst f) t) t))   ; applied after both stepped
      (t (let* ((to (kit-drop kit cmd))
                (kit (if to (find-kit (fighter-character f) to) kit))
                (mv (if (and with (not to)) with (kit-command-move kit cmd))))
           (when (and mv (kit-command-ok-p e cmd kit ender with))   ; (WITH: a chained L, inside a combo)
             (when to (set-form e to))
             (let ((cost (kit-command-cost kit cmd)))
               (when (plusp cost) (setf (gauges-reiatsu g) (f32 (spend-bars (gauges-reiatsu g) cost)))))
             (when (plusp (mv-cooldown mv))
               (setf (aref (fighter-cd f) (position cmd *kit-commands*)) (mv-cooldown mv)))
             (when (eq cmd :kikon) (setf (fighter-kikon-n f) (kit-kikon-konpaku kit)))   ; its worth, fixed now
             (when (kit-pip-cmd-p kit cmd)                                       ; the arm meter (Kenpachi's Bankai):
               (if (or (eq cmd :f) ender) (setf (gauges-arm-owed g) t) (arm-spend! e mv)))   ; a string owes one pip
             (cold-spend! e kit cmd)                                             ; Rukia's cold
             (start-move e mv button)
             t))))))

(defun awaken-state-p (e f)
  "May E awaken (or take Kenpachi's Bankai) from its state: free (idle / guard / blockstun), or where a Burst could be
pressed (a reaction or airborne, inputs not locked, past the combo's *BURST-MIN-HITS*th hit), no flash-step needed: the
awakening breaks his attack as a Burst does (REPEL!; the user 2026-09-29)."
  (declare (ignore e))
  (let ((s (fighter-state f)))
    (or (member s '(:idle :guard :guard-hit))
        (and (member s '(:stun :air)) (zerop (fighter-lock f)) (>= (fighter-combo-hits f) *burst-min-hits*)))))

(defparameter *neutral-commands* '(:kikon :awaken :hoho :step :breaker :sp2 :sp1 :sig :f :q)
  "Commands from idle / walk / guard. :kikon starts the Kikon rush at any time (whether it becomes a
Kikon is decided when its strike connects: combat.lisp APPLY-HIT).")

(defparameter *run-commands* '(:kikon :hoho :step :breaker :sp2 :sp1 :sig :f :q)
  "Commands a run cancels into at once (neutral's, without Awaken); Step again = a new hop.")

(defun command! (e f vp allowed)
  "The highest-priority buffered command among ALLOWED that can start now; consumes its press. A
buffered command that can't start (Kikon too early, no bar, cooling down) doesn't hide the ones below it."
  (loop for (cmd button mod) in *commands*
        thereis (and (member cmd allowed) (vpad-command-pressed-p vp button mod)
                     (or (try-command e f cmd button) (refused-cue e f cmd vp button))
                     (progn (vpad-consume! vp button) t))))

(defun refused-cue (e f cmd vp button)
  "A kit command pressed while it cools down (its :cooldown: L, South, the O module), or L without its cold (Rukia): the
press is eaten with a cue, the :refused event (a flash of its HUD bar, a dud tick). NIL: the commands below it may
still start."
  (let ((i (position cmd *kit-commands*)) (kit (fighter-kit f)))
    (cond ((and i (plusp (aref (fighter-cd f) i)))
           (vpad-consume! vp button)
           (emit :refused e cmd)
           (clog "~a refused ~a: cooling ~d" (side-name e) cmd (aref (fighter-cd f) i)))
          ((and (eq cmd :sig) (kit-command-move kit :sig) (< (gauges-meter (gauges e)) (cold-cost kit :sig)))
           (vpad-consume! vp button)
           (emit :refused e cmd)
           (clog "~a refused ~a: cold ~d" (side-name e) cmd (round (gauges-meter (gauges e)))))
          ((let ((h (kit-hook kit :ok))) (and h (kit-command-move kit cmd) (not (funcall h e cmd nil))))
           (vpad-consume! vp button)
           (emit :refused e cmd)
           (clog "~a refused ~a: kit" (side-name e) cmd))))
  nil)

(defun opp-field (e f)
  "The opponent's cold field acting on E now (the :field of her form, she upright, E within its :r): values the field
plist and the unit vector (UX UZ) from her to E; NIL without one."
  (let* ((o (fighter-opp f)) (fo (and o (entity-alive-p o) (fighter o))) (k (and fo (kit-field (fighter-kit fo)))))
    (when (and k (<= (fighter-dist f) (getf k :r)) (not (member (fighter-state fo) '(:stun :air :down :wakeup :cine))))
      (let ((p (pos-of e)) (d (max 1e-3 (fighter-dist f))))
        (values k (/ (- (aref p 0) (fighter-ox f)) d) (/ (- (aref p 2) (fighter-oz f)) d))))))

(defun field-slow! (e f v)
  "E's walk / run velocity V inside the opponent's cold field: its part away from her x the field's :away (FIELD-K)."
  (multiple-value-bind (k ux uz) (opp-field e f)
    (when k
      (multiple-value-bind (vx vz) (field-velocity (aref v 0) (aref v 2) ux uz (field-k (getf k :away) (plusp (fighter-frost f))))
        (setf (aref v 0) (f32 vx) (aref v 2) (f32 vz))))))

;;; ---------------------------------------------------------------- per-state steps
(defun guard-held-p (e vp)
  "Guard is held and E may guard (the guard gauge: CAN-GUARD-P). Guardless, holding it does nothing. U is a guard
in most forms; cup 3's guard drinks (DRINK: combat.lisp); Bankai East's U switches to West (the kit's :guard-to),
and West's ward is always up, so there U does nothing more (GUARD-P)."
  (let ((g (gauges e)))
    (and (vpad-down vp :guard) (can-guard-p (gauges-gg g) (gauges-guardless g))
         (not (kit-hook (kit-of e) :u)))))              ; a form whose U is a move never guards (U-PRESS!)

(defun u-press! (e f vp)
  "A form with a :u hook (its U is a move, not a guard): a buffered U press calls it; T (the press used) when it started
something."
  (let ((h (kit-hook (fighter-kit f) :u)))
    (and h (vpad-command-pressed-p vp :guard :any) (funcall h e) (progn (vpad-consume! vp :guard) t))))

(defun guard-p (e vp)
  "Does U raise a guard now (held, allowed: GUARD-HELD-P)? Not in a form whose U switches (:guard-to) or whose ward
is always up (:ward)."
  (and (guard-held-p e vp) (not (kit-guard-to (kit-of e))) (not (passive-p e :ward))))

(defun neutral-step (e f vp)
  "Idle / walk / strafe / guard: commands, then guard or walk, auto-facing. A form with :guard-to (Bankai East)
switches to that form while U is held instead of guarding (from idle / walk; a run stops into this step too): its
ward is up after *GUARD-RAISE* frames (FIGHTER-GUARD-T counts them, and keeps counting while he walks in it)."
  (unless (and (zerop (fighter-lock f)) (or (command! e f vp *neutral-commands*) (u-press! e f vp)))
    (let ((v (motion-vel (motion e))))
      (when (and (zerop (fighter-lock f)) (kit-guard-to (fighter-kit f)) (guard-held-p e vp))
        (set-form e (kit-guard-to (fighter-kit f)))
        (setf (fighter-guard-t f) 0))
      (if (and (zerop (fighter-lock f)) (guard-p e vp))
          (progn
            (unless (eq (fighter-state f) :guard)
              (setf (fighter-state f) :guard (fighter-guard-t f) 0)
              (when (pilot-cam-relative (pilot e)) (clog "~a guard" (side-name e)))
              (play-clip e :sh-guard :blend 3))
            (incf (fighter-guard-t f))
            (fill v 0f0))
          (multiple-value-bind (to st) (if (zerop (fighter-lock f)) (stick-relative e f) (values 0.0 0.0))
            (when (eq (fighter-state f) :guard) (to-idle e 4))
            (setf (fighter-guard-t f) (if (passive-p e :ward) (min 9999 (1+ (fighter-guard-t f))) 0))
            (let ((m (sqrt (+ (* to to) (* st st)))) (p (pos-of e)) (kit (fighter-kit f)))
              (if (or (< m 0.2) (<= (kit-walk kit) 0))   ; (absolute zero: rooted where she stands)
                  (progn (fill v 0f0) (play-clip e (kit-stance kit) :blend 6 :restart nil))
                  (multiple-value-bind (dx dz) (toward-strafe-dir to st (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f))
                    (let ((s (* (frost-speed (kit-walk kit) (fighter-frost f)) (min 1.0 m) (/ 1.0 m))))
                      (setf (aref v 0) (f32 (* s dx)) (aref v 2) (f32 (* s dz)))
                      (field-slow! e f v))
                    (play-clip e (cond ((> (abs st) (abs to)) (if (> st 0) :sh-strafe-r :sh-strafe-l))
                                       ((> to 0) :sh-walk-f) (t :sh-walk-b))
                               :blend 6 :restart nil))))))
      (turn-to-opp e f (deg *face-rate*)))))

(defun hold-phase-step (e f vp mv)
  "Charge / stance: hold until the button is released (min..max frames), then the move proper."
  (incf (fighter-hold f))
  (when (mv-tick mv) (funcall (mv-tick mv) e))
  (destructuring-bind (lo hi) (mv-hold mv)
    (when (or (>= (fighter-hold f) hi)
              (and (>= (fighter-hold f) lo) (not (vpad-down vp (fighter-button f)))))
      (setf (fighter-charge f) (fighter-hold f))
      (when (mv-release mv) (funcall (mv-release mv) e))
      (when (eq (fighter-move f) mv) (enter-main e f mv)))))

(defun breaker-phase-step (e f vp mv)
  "Breaker: the aura, then the dash while held (BREAKER-NEXT-PHASE), then the strike."
  (incf (fighter-hold f))
  (let ((next (breaker-next-phase (fighter-phase f) (fighter-hold f) (vpad-down vp (fighter-button f))
                                  (fighter-dist f)))
        (v (motion-vel (motion e))))
    (cond ((eq next :strike) (enter-main e f mv))
          (t (unless (eq next (fighter-phase f)) (setf (fighter-phase f) next (fighter-hold f) 0))
             (fill v 0f0)
             (when (eq next :dash)
               (turn-to-opp e f (track-step (mv-track mv)))
               (let ((sp (breaker-speed (fighter-hold f))) (yaw (yaw-of e)))
                 (setf (aref v 0) (f32 (* sp (fwd-x yaw))) (aref v 2) (f32 (* sp (fwd-z yaw))))))))))

(defun rush-param (mv key)
  "A Kikon rush module's number KEY (:aura :aim :speed :dash-max :dash-track) from its move :params."
  (getf (mv-params mv) key))

(defun kikon-rush-step (e f mv)
  "Kikon rush: the aura (turning at the module's :aim), then its dash toward the opponent at :speed
(turning at :dash-track; 0 = locked at take-off) until KIKON-RUSH-NEXT-PHASE says strike (no dash:
:dash-max 0). The button isn't read here: only when the strike connects (combat.lisp). After a strike
that hit with the button held (phase :follow, KIKON-OUTCOME): dash in after the knocked-back victim for
KIKON-FOLLOW-WAIT frames (KIKON-FOLLOW-SPEED: arriving at the trigger range as the wait ends, at most the
module's :follow-speed, else its :speed, else 14 m/s), then the strike again, the follow-up."
  (incf (fighter-hold f))
  (let ((v (motion-vel (motion e))) (phase (fighter-phase f)))
    (fill v 0f0)
    (if (eq phase :follow)
        (let ((left (- (kikon-follow-wait (mv-s mv)) (fighter-hold f))))
               (turn-to-opp e f (track-step (rush-param mv :aim)))
               (run-velocity e (kikon-follow-speed (fighter-dist f) left
                                                   (or (rush-param mv :follow-speed) (max 14.0 (rush-param mv :speed)))))
               (when (<= left 0)
                 (setf (fighter-hits f) 0 (fighter-contact f) nil (fighter-land-sf f) -1)
                 (enter-main e f mv)))
        (let ((next (kikon-rush-next-phase phase (fighter-hold f) (fighter-dist f)
                                           :aura (rush-param mv :aura) :dash-max (rush-param mv :dash-max))))
          (cond ((eq next :strike) (enter-main e f mv))
                (t (unless (eq next phase)
                     (setf (fighter-phase f) next (fighter-hold f) 0)
                     (emit :rush-dash e))
                   (if (eq next :dash)
                       (progn (turn-to-opp e f (track-step (rush-param mv :dash-track)))
                              (run-velocity e (rush-param mv :speed)))
                       (turn-to-opp e f (track-step (rush-param mv :aim))))))))))

(defun main-phase-step (e f vp mv)
  "The move proper, one frame: tracking and lunge in the startup, frame hooks, chains and cancels,
the end (MOVE-END-FRAME)."
  (let ((sf (incf (fighter-sf f))) (s (mv-s mv)) (v (motion-vel (motion e))))
    (fill v 0f0)
    (when (< sf s)
      (let* ((chained (fighter-chained f)) (rooted (kit-rooted (fighter-kit f)))   ; (rooted: her reach is the ice's)
             (chase (if (and chained (not rooted)) (string-chase-speed (fighter-dist f) (mv-reach mv) (- s sf)) 0.0))
             (slide (if (and (> (mv-slide mv) 0) (> (fighter-dist f) *lunge-stop*) (not rooted)) (* 60.0 (/ (mv-slide mv) s)) 0.0))
             (sp (max chase slide)))                  ; a lunge stopping at the opponent; a follow-up link's chase
        (turn-to-opp e f (track-step (if chained (max (mv-track mv) *chase-track*) (mv-track mv))))
        (when (> sp 0)
          (let ((yaw (yaw-of e)))
            (setf (aref v 0) (f32 (* sp (fwd-x yaw))) (aref v 2) (f32 (* sp (fwd-z yaw))))))))
    (loop for (fr hook) in (mv-on-frame mv) when (= fr sf) do (funcall hook e))
    (when (mv-tick mv) (funcall (mv-tick mv) e))
    (loop for w across (mv-hits mv) when (= sf (hw-from w))
          do (emit :swing e (mv-kind mv)) (return))
    (when (and (eq (fighter-move f) mv)                   ; a hook may have started another move
               (not (and (zerop (fighter-lock f)) (move-commands e f vp mv sf)))
               (>= sf (move-end-frame s (mv-a mv) (mv-r mv) (mv-whiff mv) (fighter-contact f)
                                      (zerop (length (mv-hits mv))))))
      (to-idle e))))

(defun move-step (e f vp)
  "Advance the current move one frame: its pre-strike phase, or the move proper."
  (let ((mv (fighter-move f)))
    (case (fighter-phase f)
      (:hold (hold-phase-step e f vp mv))
      ((:aura :dash :follow) (if (eq (mv-kind mv) :kikon) (kikon-rush-step e f mv) (breaker-phase-step e f vp mv)))
      (t (main-phase-step e f vp mv)))))

(defun skip-aura (e f)
  "The O ender (docs/DUEL_STRINGS.md §2.4): the Kikon rush just started off a link-3 hit skips its aura: its strike
at once within *KIKON-TRIGGER* (or a module with no dash), else its dash."
  (let ((mv (fighter-move f)))
    (if (eq (kikon-rush-next-phase :aura 0 (fighter-dist f) :aura 0 :dash-max (rush-param mv :dash-max)) :strike)
        (enter-main e f mv)
        (progn (setf (fighter-phase f) :dash (fighter-hold f) 0) (emit :rush-dash e)))))

(defun move-commands (e f vp mv sf)
  "Chains (string follow-ups) and cancels during a move, walked in *COMMANDS* priority order (a
refused one doesn't hide the next). A J / K press during a string link is latched (STRING-LATCH: the last allowed
press wins, a press of the button the string switched away from is eaten) and consumed at once; the latched link
starts when the chain opens (CHAIN-OPEN-P: once any link of the string touched him, docs/DUEL_STRINGS.md §2.2) and
chases him in its startup (STRING-CHASE-SPEED). O is the ender: only off a link-3 (:ender) hit, the
rush's aura skipped. L during a K link of a form with :l-after-k is latched too (KIT-L-LINK, docs/DUEL_STRINGS.md §12):
it starts when that K link's own contact opens the chain, as a follow-up (the chase), under L's own checks (cooldown,
cold). T when a new move / action started."
  (let ((kit (fighter-kit f)) (landed (fighter-contact f)) (name (mv-name mv)))
    (or (loop for (cmd button mod) in *commands*
              thereis (and (member cmd '(:kikon :q :f :sp1 :sp2 :sig :hoho))
                           (vpad-command-pressed-p vp button mod)
                           (case cmd
                             (:kikon (and (member :ender (mv-flags mv))   ; the O ender: a completed string
                                          (cancel-open-p sf (fighter-land-sf f) (mv-total mv) (eq landed :hit))
                                          (try-command e f cmd button t)
                                          (progn (skip-aura e f) t)))
                             ((:q :f) (when (string-link-p kit name)   ; the latch takes every J / K press
                                        (setf (fighter-queued f) (string-latch kit name cmd (fighter-queued f)))
                                        (vpad-consume! vp button))
                                      nil)
                             (:sig (if (kit-l-link kit name)   ; L after a K link: latched like a link
                                       (progn (when (kit-command-ok-p e :sig (fighter-kit f) nil t)
                                                (setf (fighter-queued f) :sig)
                                                (vpad-consume! vp button))
                                              nil)
                                       (cancel-into e f kit mv sf landed cmd button)))
                             (t (cancel-into e f kit mv sf landed cmd button)))
                           (progn (vpad-consume! vp button) t)))
        (let ((q (fighter-queued f)))                   ; the latched link, once the chain opens
          (when (and q (chain-open-p sf (mv-s mv) (mv-a mv) (mv-r mv) (if (eq q :sig) landed (or landed (fighter-chained f)))))
            (if (eq q :sig)                             ; L after a K link: its own checks and costs, a follow-up
                (progn (setf (fighter-queued f) nil)
                       (when (try-command e f :sig nil nil (kit-l-link kit name))
                         (setf (fighter-chained f) t)))
            (let ((next (kit-next kit name q)) (pip (kit-pip-cmd-p kit q)))
              (cond ((and pip (< (gauges-meter (gauges e)) 1f0))   ; a K link with no pip left: the string ends here
                     (setf (fighter-queued f) nil)
                     nil)
                    (t (when pip (setf (gauges-arm-owed (gauges e)) t))   ; the string's one pip, charged when it ends
                       (cold-spend! e kit q)                             ; each link's cold (Rukia)
                       (start-move e next (if (eq q :q) :quick :flash))
                       (setf (fighter-chained f) t)
                       t)))))))))

(defun cancel-into (e f kit mv sf landed cmd button)
  "An on-hit cancel out of J / K link MV: SPs, Hoho, a :cancel Signature (L)."
  (and (member (mv-kind mv) '(:quick :flash))
       (or (not (eq cmd :sig)) (let ((l (kit-command-move kit :sig))) (and l (member :cancel (mv-flags l)))))
       (cancel-open-p sf (fighter-land-sf f) (mv-total mv) (eq landed :hit))
       (try-command e f cmd button)))

(defun stun-step (e f vp)
  "A reaction / blockstun counts down (Burst Reverse may be pressed); then neutral (guard again if
Guard is held)."
  (when (zerop (fighter-lock f)) (command! e f vp '(:burst :awaken)))
  (when (>= (incf (fighter-sf f)) (fighter-stun f))
    (to-idle e)
    (when (guard-p e vp) (setf (fighter-state f) :guard (fighter-guard-t f) *guard-raise*) (play-clip e :sh-guard :blend 3))))

(defun step-step (e f vp)
  "The hop; at its end a Step still held becomes a run (so holding never shortens a Step)."
  (when (>= (incf (fighter-sf f)) *step-frames*)
    (if (and (zerop (fighter-lock f)) (vpad-down vp :step)) (start-run e f) (to-idle e))))

(defun run-velocity (e speed &optional (yaw (yaw-of e)))
  "E moves at SPEED along YAW (default his facing)."
  (let ((v (motion-vel (motion e))))
    (setf (aref v 0) (f32 (* speed (fwd-x yaw))) (aref v 2) (f32 (* speed (fwd-z yaw))))))

(defun run-closing (e f)
  "The fraction (-1..1) of E's run heading that points at his opponent."
  (let* ((p (pos-of e)) (yaw (fighter-run-yaw f)) (d (fighter-dist f)))
    (if (< d 0.01)
        0.0
        (/ (+ (* (fwd-x yaw) (- (fighter-ox f) (aref p 0))) (* (fwd-z yaw) (- (fighter-oz f) (aref p 2)))) d))))

(defun run-step (e f vp)
  "The run: a command cancels it at once (a move keeps RUN-CARRY of momentum), Guard stops it,
releasing Step brakes (*RUN-BRAKE* f, committed); else run at the kit's :run speed toward the stick
direction relative to the opponent (neutral = at him), the heading turning at *RUN-TURN*, stopping
*RUN-STOP* from him (RUN-STOP-P). He faces the opponent throughout (as in neutral, *FACE-RATE*), so the
clip follows the heading: forward run, side slide or back-skate (RUN-CLIP)."
  (let* ((v (motion-vel (motion e))) (vx (aref v 0)) (vz (aref v 2))
         (speed (frost-speed (kit-run (fighter-kit f)) (fighter-frost f))) (sf (incf (fighter-sf f))) (free (zerop (fighter-lock f))))
    (cond ((eq (fighter-phase f) :brake)
           (let ((s (if (run-stop-p (fighter-dist f) (run-closing e f) speed) 0.0 (brake-speed speed sf))))
             (turn-to-opp e f (deg *face-rate*))
             (if (or (<= s 0) (>= sf *run-brake*)) (to-idle e) (run-velocity e s (fighter-run-yaw f)))))
          ((and free (or (command! e f vp *run-commands*) (u-press! e f vp)))
           (when (eq (fighter-state f) :move)
             (set-slide e (run-carry (fighter-dist f)) *run-carry-frames* vx vz)
             (clog "~a run -> ~a, carry ~,1f m" (side-name e) (mv-name (fighter-move f)) (run-carry (fighter-dist f)))))
          ((and free (guard-held-p e vp) (not (passive-p e :ward))) (to-idle e 3) (neutral-step e f vp))
          ((not (and free (vpad-down vp :step)))
           (setf (fighter-phase f) :brake (fighter-sf f) 0)
           (play-clip e (kit-stance (fighter-kit f)) :blend 6))
          (t (setf (fighter-run-yaw f) (f32 (angle-wrap (turn-toward (fighter-run-yaw f) (run-yaw e f) (track-step *run-turn*)))))
             (turn-to-opp e f (deg *face-rate*))
             (if (run-stop-p (fighter-dist f) (run-closing e f) speed)
                 (to-idle e 4)
                 (progn (run-velocity e speed (fighter-run-yaw f))
                        (field-slow! e f (motion-vel (motion e)))
                        (play-clip e (run-clip e f) :blend 5 :speed (/ speed 8.0) :restart nil)))))))

(defun hoho-step (e f)
  "Vanish, reappear behind the opponent on frame *HOHO-APPEAR* facing him; a perfect Hoho swings on
*HOHO-COUNTER-POSE* (its strike, on *HOHO-COUNTER-STRIKE*, is collected by combat.lisp like any hit)."
  (let ((sf (incf (fighter-sf f))) (o (opp-of e)))
    (setf (model-alpha (model e)) (if (< sf *hoho-appear*) (f32 (- 1.0 (/ sf (float *hoho-appear*)))) 1f0))
    (when (= sf *hoho-appear*)
      (let ((q (pos-of o)) (p (pos-of e)))
        (multiple-value-bind (x z yaw) (hoho-destination (aref q 0) (aref q 2) (yaw-of o))
          (setf (aref p 0) (f32 x) (aref p 2) (f32 z) (transform-yaw (transform e)) (f32 yaw))))
      (play-clip e :sh-hoho-in :blend 0)
      (let ((p (pos-of e))) (emit :hoho-in e (aref p 0) (aref p 2))))
    (when (and (= sf *hoho-counter-pose*) (fighter-perfect f))
      (play-clip e (mv-clip (kit-command-move (fighter-kit f) :q)) :blend 0 :time 0.1))
    (when (>= sf *hoho-frames*) (to-idle e 3))))

(defun air-step (e f vp)
  "Airborne until landing (Burst Reverse may be pressed), then :down 30 f and :wakeup 30 f (both
invulnerable)."
  (when (and (eq (fighter-state f) :air) (zerop (fighter-lock f))) (command! e f vp '(:burst :awaken)))
  (let ((sf (incf (fighter-sf f))) (mo (motion e)))
    (case (fighter-state f)
      (:air (when (and (motion-grounded mo) (> sf 2))
              (setf (fighter-state f) :down (fighter-sf f) 0)
              (play-clip e :sh-down :blend 3)
              (emit :land e)))
      (:down (when (>= sf (getf *reaction-frames* :down))
               (setf (fighter-state f) :wakeup (fighter-sf f) 0)
               (play-clip e :sh-wakeup :blend 2)))
      (:wakeup (when (>= sf (getf *reaction-frames* :wakeup)) (to-idle e))))))

;;; ---------------------------------------------------------------- reactions (called by combat.lisp)
(defun set-reaction (e react stun from-x from-z kb)
  "Put E into reaction REACT (STUN frames for grounded ones), pushed KB metres away from (FROM-X FROM-Z)."
  (let* ((f (fighter e)) (mo (motion e)) (p (pos-of e)) (v (motion-vel mo))
         (dx (- (aref p 0) from-x)) (dz (- (aref p 2) from-z)) (air (eq (fighter-state f) :air)))
    (when (member (fighter-state f) '(:down :wakeup)) (return-from set-reaction nil))
    (setf (fighter-move f) nil (fighter-sf f) 0 (fighter-phase f) react)
    (fill v 0f0)
    (cond ((or air (member react '(:launch :knockdown)))
           (setf (fighter-state f) :air (motion-grounded mo) nil
                 (aref v 1) (f32 (getf *air-vy* (if (member react '(:launch :knockdown)) react :air))))
           (set-slide e (if (> kb 0) (* *air-slide* kb) 1.0) *air-slide-frames* dx dz)
           (play-clip e :sh-launch :blend 2)
           (when (eq react :launch) (emit :launch e)))
          (t (setf (fighter-state f) :stun (fighter-stun f) stun)
             (when (> kb 0) (set-slide e kb (min stun *knockback-slide-frames*) dx dz))
             (play-clip e (case react (:stagger :sh-stagger) (:knockback :sh-knockback) (:guard-break :sh-guard-break)
                                      (:crumple :sh-crumple) (:clash :sh-clash) (:bind :sh-bound) (t :sh-flinch))
                        :blend 0)))))

(defun set-blockstun (e stun from-x from-z adv &optional clip)
  "Blockstun of STUN frames, pushed back from (FROM-X FROM-Z); ADV = the blocked move's advantage. CLIP: its
clip (a drunk hit's), else the guard's."
  (let* ((f (fighter e)) (p (pos-of e)))
    (setf (fighter-state f) :guard-hit (fighter-sf f) 0 (fighter-stun f) stun (fighter-move f) nil
          (fighter-block-adv f) adv)
    (fill (motion-vel (motion e)) 0f0)
    (set-slide e *block-pushback* 6 (- (aref p 0) from-x) (- (aref p 2) from-z))
    (play-clip e (or clip :sh-guard-hit) :blend 0)))

(defun defender-state (e)
  "E's side of the triangle for RESOLVE-CONTACT (rules.lisp): :neutral :guard :breaker :stance-in
:stance :armor :parry :invuln. Bankai West's ward (passive :ward, up *GUARD-RAISE* frames after U) is :guard in his
free states (idle, walk, run), the non-invulnerable frames of Step / Hoho and his own moves (a parry's window is
still :parry); never in a reaction (a bind, a Guard Break, a crush reel: no armoured combos)."
  (let* ((f (fighter e)) (sf (fighter-sf f)) (mv (fighter-move f))
         (open (if (and (passive-p e :ward) (>= (fighter-guard-t f) *guard-raise*)) :guard :neutral)))
    (case (if (> (fighter-invuln f) 0) :invuln (fighter-state f))
      ((:idle :run) open)
      (:invuln :invuln)                                  ; after a Burst
      (:guard (if (and (>= (fighter-guard-t f) *guard-raise*) (can-guard-p (gauges-gg (gauges e)) (gauges-guardless (gauges e))))
                  :guard :neutral))
      (:guard-hit :guard)
      (:step (if (invulnerable-frame-p sf *step-iframes*) :invuln open))
      (:hoho (if (invulnerable-frame-p sf *hoho-iframes*) :invuln open))
      ((:down :wakeup :cine :intro :win :lose) :invuln)
      (:air (if (eq (fighter-phase f) :knockdown) :invuln :neutral))   ; the combo limits' forced knockdown
      (:move (cond ((and (eq (mv-kind mv) :breaker) (or (member (fighter-phase f) '(:aura :dash)) (< sf (mv-s mv))))
                    :breaker)
                   ((and (plusp (fighter-armor-left f))           ; the move's armour (:armor-hits)
                         (if (eq (mv-kind mv) :kikon)
                             (eq (fighter-phase f) :dash)
                             (and (eq (fighter-phase f) :main) (<= *armor-from* sf) (< sf (mv-s mv)))))
                    :armor)
                   ((and (member :stance (mv-flags mv)) (eq (fighter-phase f) :hold))
                    (if (< (fighter-hold f) *stance-in*) :stance-in :stance))
                   ((and (member :parry (mv-flags mv)) (eq (fighter-phase f) :main) (parry-frame-p sf (getf (mv-params mv) :window))) :parry)
                   ((and (member :shield (mv-flags mv)) (eq (fighter-phase f) :main) (<= (mv-s mv) sf) (< sf (+ (mv-s mv) (mv-a mv))))
                    :guard)                                        ; a :shield move's window is a guard (its catch: APPLY-HIT)
                   (t open)))
      (t :neutral))))

(defun breaker-phase (e)
  "E's Breaker phase for BREAKER-CLASH-P: :aura :dash :strike (strike startup / active) or NIL."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (when (and (eq (fighter-state f) :move) (eq (mv-kind mv) :breaker))
      (case (fighter-phase f)
        ((:aura :dash) (fighter-phase f))
        (t (when (< (fighter-sf f) (+ (mv-s mv) (mv-a mv))) :strike))))))

;;; ---------------------------------------------------------------- physics
(defun-fast fighter-physics (e)
  "Walk / dash velocity, the slide, gravity and landing, the arena wall."
  (let* ((mo (motion e)) (p (pos-of e)) (v (motion-vel mo)) (kb (motion-kb mo)) (dt +step+)
         (r (- *arena-radius* (body-hurt-r (model-body (model e))))))
    (declare (type f32vec p v kb) (single-float dt r))
    (setf (aref p 0) (+ (aref p 0) (* dt (aref v 0))) (aref p 2) (+ (aref p 2) (* dt (aref v 2))))
    (when (> (the fixnum (motion-kb-left mo)) 0)
      (setf (aref p 0) (+ (aref p 0) (aref kb 0)) (aref p 2) (+ (aref p 2) (aref kb 2))
            (motion-kb-left mo) (1- (the fixnum (motion-kb-left mo)))))
    (unless (motion-grounded mo)
      (setf (aref v 1) (- (aref v 1) (* (the single-float *gravity*) dt)) (aref p 1) (+ (aref p 1) (* dt (aref v 1))))
      (when (and (<= (aref p 1) 0f0) (<= (aref v 1) 0f0))
        (setf (aref p 1) 0f0 (aref v 1) 0f0 (motion-grounded mo) t)))
    (let* ((x (aref p 0)) (z (aref p 2)) (d (f-sqrt (+ (* x x) (* z z)))))
      (declare (single-float x z d))
      (when (> d r) (setf (aref p 0) (* x (/ r d)) (aref p 2) (* z (/ r d)))))
    nil))

(defun separate-fighters (a b)
  "Two grounded, visible fighters never overlap: push both apart equally (symmetric)."
  (unless (or (member (state-of a) '(:hoho :cine)) (member (state-of b) '(:hoho :cine)))
    (let* ((p (pos-of a)) (q (pos-of b)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
           (d (sqrt (+ (* dx dx) (* dz dz))))
           (min-d (+ (body-hurt-r (model-body (model a))) (body-hurt-r (model-body (model b))))))
      (when (and (< d min-d) (< (abs (- (aref p 1) (aref q 1))) 1.2))
        (let* ((push (* 0.5 (- min-d d))) (ux (if (> d 1e-3) (/ dx d) 1.0)) (uz (if (> d 1e-3) (/ dz d) 0.0)))
          (setf (aref p 0) (f32 (- (aref p 0) (* push ux))) (aref p 2) (f32 (- (aref p 2) (* push uz)))
                (aref q 0) (f32 (+ (aref q 0) (* push ux))) (aref q 2) (f32 (+ (aref q 2) (* push uz)))))))))

;;; ---------------------------------------------------------------- the system
(defun fighter-step (e f)
  "One fixed step of fighter E."
  (when (> (fighter-freeze f) 0) (decf (fighter-freeze f)) (return-from fighter-step nil))
  (when (> (fighter-lock f) 0) (decf (fighter-lock f)))
  (when (> (fighter-hoho-lock f) 0) (decf (fighter-hoho-lock f)))
  (when (> (fighter-invuln f) 0) (decf (fighter-invuln f)))
  (when (> (fighter-callout-t f) 0) (decf (fighter-callout-t f)))
  (when (> (fighter-frost f) 0) (decf (fighter-frost f)))
  (let ((cd (fighter-cd f))) (dotimes (i (length cd)) (when (plusp (aref cd i)) (decf (aref cd i)))))
  (let ((vp (pilot-vpad (pilot e))))
    (case (fighter-state f)
      ((:idle :guard) (neutral-step e f vp))
      (:move (move-step e f vp))
      ((:stun :guard-hit) (stun-step e f vp))
      (:step (step-step e f vp))
      (:run (run-step e f vp))
      (:hoho (hoho-step e f))
      ((:air :down :wakeup) (air-step e f vp))))
  (fighter-physics e)
  (anim-advance (model-anim (model e)) +step+))

(defun fighter-system ()
  "Every fighter: snapshot the opponents' positions first (nobody sees the other's move of this
step: a symmetric sim), step each, then keep them apart."
  (let ((a nil) (b nil))
    (do-entities (e (f fighter))
      (let ((o (fighter-opp f)))
        (when (entity-alive-p o)
          (let* ((p (pos-of e)) (q (pos-of o)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))))
            (setf (fighter-ox f) (aref q 0) (fighter-oz f) (aref q 2) (fighter-dist f) (f32 (sqrt (+ (* dx dx) (* dz dz))))))))
      (if a (setf b e) (setf a e)))
    (when (and a b) (view-step a b))
    (do-entities (e (f fighter)) (unless (eq (fighter-state f) :cine) (fighter-step e f)))
    ;; freezes / locks one fighter put on the other take effect now that both have stepped
    (do-entities (e (f fighter))
      (setf (fighter-freeze f) (max (fighter-freeze f) (fighter-freeze-next f))
            (fighter-lock f) (max (fighter-lock f) (fighter-lock-next f))
            (fighter-freeze-next f) 0 (fighter-lock-next f) 0))
    ;; a Burst pressed this step applies now, unless a cinematic began (an awakening on the same step
    ;; wins); it ends the attacker's move, so a Kikon rush that hasn't connected yet is escaped
    (do-entities (e (f fighter))
      (when (fighter-burst f)
        (setf (fighter-burst f) nil)
        (unless *cine* (burst! e))))
    (when (and a b) (separate-fighters a b))))
