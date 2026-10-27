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

;;; ---------------------------------------------------------------- zero-cons float twins (the sim's per-step paths)
;;; ECL boxes every float that a generic operation or a non-inlined call returns (8 B each; docs/engine/ARCHITECTURE.md
;;; "ECL: consing and boxing"). The hot sim paths compute in declared single-float locals under SIM-FAST instead, with these
;;; twins of the CL / rules operations: the same IEEE operations in the same order and the same choice on ties, zeros and
;;; NaN, so every result is bit-identical to the generic code they replace (the seeded replays, native and wasm alike).
;;; Arguments: single-float forms (a twin binds each once, in order).
(defmacro sim-fast (&body body)
  "BODY at (SAFETY 0): typed float LET* locals compile to plain C (at SAFETY 1 ECL boxes their initializers)."
  `(locally (declare (optimize (speed 3) (safety 0))) ,@body))
(defmacro %sqrt (x)
  "CL's SQRT of a non-negative single-float (ECL: sqrtf; F-SQRT's clamp at 0 would turn a NaN into 0)."
  `(ffi:c-inline (,x) (:float) :float "sqrtf(#0)" :one-liner t))
(defmacro %dir-yaw (dx dz)
  "rules DIR-YAW of two single-floats: CL's ATAN in double, rounded to single (ECL's ecl_atan2)."
  `(ffi:c-inline (,dx ,dz) (:float :float) :float "(float)atan2((double)(-(#0)),(double)(-(#1)))" :one-liner t))
(defmacro %max (a b)
  "CL's MAX of two single-floats as ECL compiles it: A unless B is NaN-free and greater (a tie keeps A)."
  (let ((x (gensym "X")) (y (gensym "Y")))
    `(let* ((,x ,a) (,y ,b)) (declare (single-float ,x ,y)) (if (or (/= ,y ,y) (>= ,x ,y)) ,x ,y))))
(defmacro %min (a b)
  "CL's MIN of two single-floats as ECL compiles it: A unless B is NaN-free and smaller (a tie keeps A)."
  (let ((x (gensym "X")) (y (gensym "Y")))
    `(let* ((,x ,a) (,y ,b)) (declare (single-float ,x ,y)) (if (or (/= ,y ,y) (<= ,x ,y)) ,x ,y))))
(defmacro %floor-div (x y)
  "The first value of FFLOOR X Y (single-floats, |X/Y| < 2^24): floorf of the single quotient (ECL's ecl_floor2; the
integer it goes through only turns a -0.0 into 0.0, and no caller here divides a -0.0)."
  `(ffi:c-inline ((/ ,x ,y)) (:float) :float "floorf(#0)" :one-liner t))
(defmacro %angle-wrap (a)
  "The engine's ANGLE-WRAP: A into [-pi, pi)."
  (let ((v (gensym "A")))
    `(let* ((,v ,a)) (declare (single-float ,v))
       (- ,v (* #.(float (* 2 pi) 1f0) (%floor-div (+ ,v #.(float pi 1f0)) #.(float (* 2 pi) 1f0)))))))
(defmacro %turn-toward (cur target step)
  "The engine's TURN-TOWARD: CUR turned toward TARGET by at most STEP radians, the short way round."
  (let ((c (gensym "C")) (tg (gensym "T")) (s (gensym "S")) (d (gensym "D")))
    `(let* ((,c ,cur) (,tg ,target) (,s ,step) (,d (%angle-wrap (- ,tg ,c))))
       (declare (single-float ,c ,tg ,s ,d))
       (+ ,c (%max (- ,s) (%min ,s ,d))))))
(defmacro %set-float (place value)
  "(SETF PLACE VALUE) of a single-float VALUE into a single-float PLACE (a slot, a special), skipped when PLACE holds the same
bits already: it keeps its box, and no new one is made. PLACE is read before it is written (keep it free of side effects)."
  (let ((new (gensym "NEW")) (old (gensym "OLD")))
    `(let* ((,new ,value) (,old ,place))
       (declare (single-float ,new ,old))
       (unless (ffi:c-inline (,new ,old) (:float :float) :bool "((#0)==(#1) && !signbit(#0)==!signbit(#1))" :one-liner t)
         (setf ,place ,new)))))
(defmacro %deg (d)
  "The engine's DEG (degrees to radians) of a real D, in typed floats: one boxed result where a value is needed."
  `(sim-fast (* (f32 ,d) #.(float (/ pi 180) 1f0))))
(defmacro %track-step (deg-per-second)
  "rules TRACK-STEP: degrees per second as radians per frame (the engine's DEG of /60)."
  `(* (/ ,deg-per-second 60f0) #.(float (/ pi 180) 1f0)))

;;; ---------------------------------------------------------------- small helpers (pure reads; the kits, ai and assist use them)
(defun hoho-ready-p (e)
  "May E Hoho now (rules HOHO-ALLOWED-P over his flash-step, Hoho lockout and burst)?"
  (let ((f (fighter e)) (g (gauges e)))
    (hoho-allowed-p nil (gauges-fs g) (fighter-hoho-lock f) (gauges-burst g) (rmod-x e :hoho-cost *fs-hoho*))))
(defun hoho-open-p (e) "May E Hoho at all: his form is not rooted and HOHO-READY-P?" (and (not (kit-rooted (kit-of e))) (hoho-ready-p e)))
(defun current-move (f) "The move fighter F is in (his MOVE while his state is :move), else NIL." (and (eq (fighter-state f) :move) (fighter-move f)))
(defun reishi-frac (g) "Gauges G's Reishi as a fraction of its maximum." (/ (gauges-reishi g) (float (gauges-reishi-max g))))
(defun gauges-red-p (g) "Is gauges G's Reishi in the red (rules RED-P)?" (red-p (gauges-reishi g) (gauges-reishi-max g)))
(defun reiatsu-bars (e) "E's full Reiatsu bars (REIATSU-OF: a bind's shared pool)." (floor (reiatsu-of e) *reiatsu-bar*))
(defun halt! (e) "Stop E's motion (velocity zeroed)." (fill (motion-vel (motion e)) 0f0))
;;; ---------------------------------------------------------------- DANGAI's run modifiers (run-mods.lisp, DUEL_ROGUE §4.4)
;;; The fighter-side rule points' glue; every caller is behind (WHEN *RUN-MODS* ...) or RMOD's own test.
(defun rm-of (e)
  "Fighter E's run state (RMST), made on first use (once a match: a fresh fighter every match)."
  (let ((f (fighter e))) (or (fighter-rm f) (setf (fighter-rm f) (make-rmst)))))

(defun run-armor-p (e)
  "Has E a run armour hit up now: a timed one (:armor-on-soul-loss / :armor-on-awaken running), or :red-armor's while he
is red and it is back?"
  (and (run-mods-on-p e)
       (let ((st (rm-of e)))
         (or (plusp (rmst-armor-t st))
             (and (rmod e :red-armor nil) (zerop (rmst-red-cd st)) (gauges-red-p (gauges e)))))))

(defun run-armor-spend! (e)
  "E's run armour took a hit (APPLY-HIT :armored): the timed one first (gone), else the red one (back in :red-armor s)."
  (let ((st (rm-of e)))
    (if (plusp (rmst-armor-t st))
        (setf (rmst-armor-t st) 0)
        (setf (rmst-red-cd st) (seconds->frames (rmod e :red-armor 0))))
    (log-msg "duel runmod armor hit side ~d" (fighter-side (fighter e)))))

(defun run-armor-give! (e key)
  "E's timed armour hit for KEY's seconds (:armor-on-soul-loss, :armor-on-awaken), when he holds KEY."
  (let ((s (rmod e key nil)))
    (when s
      (setf (rmst-armor-t (rm-of e)) (max (rmst-armor-t (rm-of e)) (seconds->frames s)))
      (log-msg "duel runmod ~(~a~) ~,1f s" key s))))

(defun run-move-start! (e mv)
  "E starts MV: an SP inside the window after his link-3 ender's hit is marked (:ender-sp-dmg)."
  (when (run-mods-on-p e)
    (let ((st (rm-of e)))
      (setf (rmst-ender-sp st) (and (eq (mv-kind mv) :sp) (plusp (rmst-ender-left st)))))))

(defun run-perfect! (e g)
  "E's perfect Hoho (gauges G): :perfect-fs (of max) and :perfect-reiatsu (bars) back, the :perfect-taken window opens."
  (when (run-mods-on-p e)
    (let ((fs (rmod e :perfect-fs nil)) (r (rmod e :perfect-reiatsu nil)))
      (when fs (setf (gauges-fs g) (f32 (gauge-add (gauges-fs g) (* fs *fs-max*) *fs-max*))))
      (when r (reiatsu-gain! e (* r *reiatsu-bar*)))
      (setf (rmst-perfect-left (rm-of e)) *run-perfect-window*)
      (log-msg "duel runmod perfect fs ~,1f reiatsu ~,1f" (gauges-fs g) (gauges-reiatsu g)))))

(defun run-post-burst! (e)
  "E Hohos or bursts: his next hit that lands is the first after it (:post-burst-dmg / :post-burst-fs)."
  (when (run-mods-on-p e)
    (setf (rmst-post-burst (rm-of e)) t)
    (log-msg "duel runmod post-burst armed fs ~,1f" (gauges-fs (gauges e)))))

(defun run-no-guard-p (e g vp)
  "DANGAI's :red-no-guard: E (gauges G, vpad VP) is red and may not guard (a log line every 30 frames he tries)."
  (and (rmod e :red-no-guard nil) (gauges-red-p g)
       (progn (when (and (vpad-down vp :guard) (zerop (mod *match-tick* 30))) (log-msg "duel runmod red-no-guard"))
              t)))

(defun world-dir (e f to st)
  "The world XZ direction (two values) of stick TO / ST relative to E's opponent (fighter F's OX OZ): TOWARD-STRAFE-DIR."
  (let ((p (pos-of e))) (toward-strafe-dir to st (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f))))

;;; ---------------------------------------------------------------- creation
(defun p1-down-p (device name)
  (case device (:key (key-down name)) (:touch (touch-button name)) (t (pad-down name 0))))
(defun p2-down-p (device name) (if (eq device :key) (key-down name) (pad-down name 1)))
(defun p1-reader (vp)
  (touch-read-begin)                                     ; this read's gesture pulses (onehand.lisp)
  (vpad-read! vp *p1-bindings* #'p1-down-p (+ (pad-lx 0) (touch-sx *touch*)) (+ (pad-ly 0) (touch-sy *touch*))))
(defun p2-reader (vp) (vpad-read! vp *p2-bindings* #'p2-down-p (pad-lx 1) (pad-ly 1)))
(defun pilot-system ()
  "Every human fighter's vpad reads its devices this step (inside the step: determinism)."
  (do-entities (e (pl pilot) (f fighter))
    (unless (brain e) (vpad-begin-step! (pilot-vpad pl)))))

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
  "Start CLIP on E's model (BLEND frames of crossfade; see ANIM-PLAY); his form may play its own version of it (its kit's
:look-clips: Lille II's awakened guard), else a body variant (BODY-CLIPS). A look: the sim never reads a clip."
  (let* ((b (model-body (model e))) (f (fighter e)) (lc (and f (kit-look-clips (fighter-kit f)))))
    (anim-play (model-anim (model e)) (clip-or-fallback e (or (and lc (getf lc clip)) (and b (getf (body-clips b) clip)) clip))
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
  "The yaw from E toward the point (X Z). (Single-floats: the twins, one boxed result.)"
  (let ((p (pos-of e)))
    (if (and (typep x 'single-float) (typep z 'single-float))
        (sim-fast (let* ((q p) (a x) (c z) (v (%dir-yaw (- a (aref q 0)) (- c (aref q 2)))))
                    (declare (type f32vec q) (single-float a c v))
                    v))
        (dir-yaw (- x (aref p 0)) (- z (aref p 2))))))

(defun turn-to-opp (e f max-step)
  "Turn E toward his opponent by at most MAX-STEP radians."
  (let ((tf (transform e)))
    (when (> (fighter-dist f) 0.01)
      (if (typep max-step 'single-float)
          (sim-fast                                 ; (the zero-cons twins: bit-identical)
            (let* ((p (pos-of e)) (s max-step) (yaw (transform-yaw tf)) (ox (fighter-ox f)) (oz (fighter-oz f)))
              (declare (type f32vec p) (single-float s yaw ox oz))
              (let* ((to (%dir-yaw (- ox (aref p 0)) (- oz (aref p 2)))))
                (declare (single-float to))
                (%set-float (transform-yaw tf) (%angle-wrap (%turn-toward yaw to s))))))
          (setf (transform-yaw tf) (f32 (angle-wrap (turn-toward (transform-yaw tf) (face-yaw-to e (fighter-ox f) (fighter-oz f)) max-step))))))))

(defun set-slide (e dist frames dx dz)
  "Slide E DIST metres over FRAMES along (DX DZ) (knockback, pushback, Step, clash)."
  (let* ((mo (motion e)) (kb (motion-kb mo)) (l (max 1e-4 (hypot dx dz))) (k (/ dist (max 1 frames) l)))
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
  (sim-fast                                       ; (zero-cons twins of HYPOT, DIR-YAW, TURN-TOWARD ...: bit-identical)
    (let* ((p (pos-of a)) (q (pos-of b)) (turn (f32 *behind-turn*)))
      (declare (type f32vec p q) (single-float turn))
      (let* ((dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (d (%sqrt (+ (* dx dx) (* dz dz)))))
        (declare (single-float dx dz d))
        (when (> d 0.01)
          (let* ((nx (/ (- dz) d)) (nz (/ dx d))
                 (side (if (or reset (>= (+ (* nx *view-x*) (* nz *view-z*)) 0f0)) 1f0 -1f0))
                 (yaw (%dir-yaw dx dz)))
            (declare (single-float nx nz side yaw))
            (setf *view-side* side)
            (%set-float *view-x* (* side nx))
            (%set-float *view-z* (* side nz))
            (%set-float *behind-yaw* (if reset yaw (%angle-wrap (%turn-toward *behind-yaw* yaw (%track-step turn)))))))))))

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
          (fighter-crush f) nil (fighter-dmg-bonus f) 0 (fighter-assist-next f) nil
          (fighter-combo-hits f) 0 (fighter-combo-launches f) 0 (fighter-combo-air f) 0 (fighter-combo-from f) 0)
    (halt! e)
    (play-clip e (kit-stance (fighter-kit f)) :blend blend)))

(defun callout (e text)
  (let ((f (fighter e))) (setf (fighter-callout f) text (fighter-callout-t f) *callout-frames*)))

(defun start-move (e mv &optional button)
  "Enter move MV (a MOVE of E's kit). Frame (MV-ENTER mv) is this step; MOVE-STEP advances it."
  (let* ((f (fighter e)) (enter (mv-enter mv)) (old (current-move f))
         (off-ender (or (plusp (fighter-chain f))                       ; ORANGE's restart, or a move started off a J / K
                        (and old (member :ender (mv-flags old)) (member (mv-kind old) '(:quick :flash))   ; ender that hit
                             (eq (fighter-contact f) :hit))
                        (and old (eq (mv-kind old) :breaker) (eq (fighter-contact f) :hit)))))   ; J1 / K1 off a Breaker
                                                                ; that landed (pushed away: it chases him, MAIN-PHASE-STEP)
    (setf (fighter-end-chase f) off-ender)
    (when *run-mods* (run-move-start! e mv))
    (setf (fighter-state f) :move (fighter-move f) mv (fighter-sf f) enter (fighter-hits f) 0
          (fighter-contact f) nil (fighter-hz-hit f) nil (fighter-queued f) nil (fighter-chained f) nil (fighter-land-sf f) -1 (fighter-dmg-bonus f) 0 (fighter-crush f) nil
          (fighter-stored f) 0                           ; an interrupted stance keeps nothing
          (fighter-button f) button (fighter-hold f) 0 (fighter-perfect f) nil
          (fighter-assisted f) (fighter-assist-next f) (fighter-assist-next f) nil   ; ASSIST: pressed for him
          (fighter-follow f) nil
          (fighter-armor-left f) (if (and *run-foe-mods* (eq (mv-kind mv) :sp) (rmod e :sp-armor nil))   ; DANGAI's FOE SP
                                     (max 1 (mv-armor-hits mv))                                          ; ARMOR (§5)
                                     (mv-armor-hits mv))
          (fighter-phase f) (cond ((member (mv-kind mv) '(:breaker :kikon)) :aura) ((mv-hold mv) :hold) (t :main)))
    (halt! e)
    (play-clip e (kit-move-clip (fighter-kit f) (mv-clip mv)) :blend (mv-blend mv) :speed (mv-clip-speed mv)   ; (the
                              :time (/ (* enter (mv-clip-speed mv)) 60.0))                                   ;  form's look)
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
    (when (plusp (fighter-chain f))                     ; ORANGE: the first move after the cancel starts later in its
      (setf (fighter-chain f) 0)                        ; startup (the skipped frames' hooks run now, in order)
      (let ((cut (if (eq (fighter-phase f) :main) (chain-startup-cut (mv-s mv) enter) 0)))
        (when (plusp cut)
          (loop for fr from (1+ enter) to (+ enter cut) while (eq (fighter-move f) mv)
                do (loop for (hf hook) in (mv-on-frame mv) when (= hf fr) do (funcall hook e)))
          (when (eq (fighter-move f) mv)
            (setf (fighter-sf f) (+ enter cut))
            (play-clip e (kit-move-clip (fighter-kit f) (mv-clip mv)) :blend 0 :speed (mv-clip-speed mv)
                       :time (/ (* (+ enter cut) (mv-clip-speed mv)) 60.0))
            (clog "~a chain cut ~d f" (side-name e) cut)))))
    mv))

(defun enter-main (e f mv)
  "A hold / Breaker move leaves its pre-strike phase: the move proper starts at frame 0."
  (setf (fighter-phase f) :main (fighter-sf f) 0)
  (halt! e)
  (when (mv-clip-2 mv) (play-clip e (kit-move-clip (fighter-kit f) (mv-clip-2 mv)) :blend 0 :speed (mv-clip-speed mv)))
  (when (eq (mv-kind mv) :breaker) (emit :breaker-end e)))

(defun start-step (e f)
  "Step: a 2.5 m hop in the stick direction (neutral = back), iframes f3-f9, 24 f."
  (multiple-value-bind (to st) (stick-relative e f)
    (multiple-value-bind (to st) (step-direction to st)
      (multiple-value-bind (dx dz) (world-dir e f to st)
        (set-slide e (let ((len (multiple-value-bind (k ux uz) (opp-field e f)   ; her cold field shortens a Step away from her
                                  (if k
                                      (field-step *step-distance* (/ (- (+ (* dx ux) (* dz uz))) (max 1e-4 (hypot dx dz)))
                                                  (getf k :step))
                                      *step-distance*)))
                           (h (kit-hook (fighter-kit f) :step-dist)))   ; a form's own landing (Hisagi's chain tips)
                       (if h (funcall h e f to st len) len))
                   12 dx dz))
      (setf (fighter-state f) :step (fighter-sf f) 0 (fighter-move f) nil (fighter-queued f) nil   ; (the J latch)
            (fighter-step-open f) nil)
      (halt! e)
      (let ((h (kit-hook (fighter-kit f) :step))) (when h (funcall h e)))   ; the form's own take-off (a clone)
      (play-clip e (cond ((> (abs st) (abs to)) (if (> st 0) :sh-step-r :sh-step-l)) ((> to 0) :sh-step-f) (t :sh-step-b))
                 :blend 2)
      (clog "~a step~@[ ~a~]" (side-name e) (let ((b (brain e))) (and b (brain-why b))))
      (emit :step e))))

(defun run-yaw (e f)
  "The yaw a runner wants: the stick direction relative to the opponent (neutral = at him)."
  (multiple-value-bind (to st) (stick-relative e f)
    (multiple-value-bind (to st) (step-direction to st 1.0)
      (multiple-value-bind (dx dz) (world-dir e f to st)
        (dir-yaw dx dz)))))

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
  "Hoho: spend *FS-HOHO* flash-step (during a burst what is left, if less: HOHO-COST), vanish, reappear behind the
opponent (HOHO-STEP). Checks PERFECT now (one the assist pressed is never perfect; no flash-step refund since 2026-10-18)."
  (let ((g (gauges e)))
    (spend-fs g (rmod-x e :hoho-cost (hoho-cost (gauges-fs g) (gauges-burst g))))
    (when *run-mods* (run-post-burst! e))
    (setf (fighter-perfect f) (and (not (fighter-assist-next f)) (perfect-now-p e))   ; (before leaving the move: a cancel
          (fighter-assist-next f) nil                                                ; Hoho; an assisted one: never)
          (fighter-state f) :hoho (fighter-sf f) 0 (fighter-move f) nil
          (fighter-hoho-lock f) (+ *hoho-frames* *hoho-lockout*))
    (halt! e)
    (let ((p (pos-of e))) (emit :hoho-out e (aref p 0) (aref p 2)))
    (clog "~a hoho" (side-name e))
    (when (fighter-perfect f)
      (let ((o (opp-of e)))
        (incf (gauges-perfects g))
        (when *run-mods* (run-perfect! e g))
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
      (let ((g (gauges e))) (countdown! (gauges-meter g) c)))))

(defun kit-command-ok-p (e command &optional (kit (kit-of e)) ender combo)
  "Can E start COMMAND's move (of KIT, default his form's) now: Reiatsu bars, not cooling down (its :cooldown), a pip of
the arm meter left when the command spends one (Kenpachi's Bankai: KIT-PIP-CMD-P; one more while the string he is in
owes its pip, unless it is that string's O ENDER), and L's cold (Rukia: only L is refused by cold; COMBO, a chained
follow-up, overdraws while any cold is left: rules COLD-OK-P)? (The bars: REIATSU-OF, a bind's shared pool.)"
  (let ((i (position command *kit-commands*)) (g (gauges e)))
    (and (>= (reiatsu-of e) (* (kit-command-cost kit command) *reiatsu-bar*))
         (not (and (eq command :kikon) (rmod *run-mods-who* :kikon-seal nil)))   ; DANGAI's :kikon-seal: no side's O
         (or (null i) (zerop (aref (fighter-cd (fighter e)) i)))
         (or (not (kit-pip-cmd-p kit command)) (>= (gauges-meter g) (if (and (gauges-arm-owed g) (not ender)) 2f0 1f0)))
         (or (not (eq command :sig)) (cold-ok-p (gauges-meter g) (cold-cost kit :sig) combo))
         (let ((h (kit-hook kit :ok))) (or (null h) (funcall h e command combo))))))   ; the form's own price / refusal

(defun try-command (e f cmd &optional button ender with)
  "Start command CMD (pressed with vpad BUTTON: a hold / Breaker move watches it) if the rules allow
it now. A command the form drops (KIT-DROP) switches the form first, on the move's frame 0, and starts that
form's move; a refused one doesn't switch. ENDER: the O ender of a string (its pip is the string's). WITH: the move
to start instead of the command's own (L after a K link, KIT-L-LINK), under the command's checks and costs. T when
something started (a :command hook's non-move answer, :HOLD: nothing starts and, unrefused, the press stays buffered:
Hisagi's K while his sickle returns). P (:awaken): the awakening, Kenpachi's Bankai, else the form's :p hook (e free), which decides,
starts its own move or refuses with the cue (T when it took the press; Hisagi's bind throw and release)."
  (let ((g (gauges e)) (kit (fighter-kit f)))
    (case cmd
      (:step (unless (kit-rooted kit) (cold-spend! e kit :step) (start-step e f) t))   ; a rooted form (Rukia's zero) refuses
      (:hoho (when (and (not (kit-rooted kit)) (hoho-ready-p e))   ; Step and Hoho
               (start-hoho e f) t))
      (:awaken (let ((free (awaken-state-p e f)))
                 (cond ((awaken-allowed-p free (gauges-awaken g) (gauges-awakened g)) (awaken! e) t)
                       ((and (kit-bankai-form kit) (bankai-allowed-p free (gauges-konpaku g)) (bankai-ok-p e))
                        (bankai! e) t)
                       ((let ((h (kit-hook kit :p))) (and h (funcall h e free) t))))))
      (:burst (let ((m (burst-ok-p e))) (when m (setf (fighter-burst f) m) t)))   ; applied after both stepped
      (t (let* ((to (kit-drop kit cmd))
                (kit (if to (fighter-find-kit e to) kit))
                (mv (if (and with (not to)) with (kit-command-move kit cmd e))))   ; (E: the kit's :command hook)
           (when (and (move-p mv) (kit-command-ok-p e cmd kit ender with))   ; (WITH: a chained L, inside a combo; a
                                                                             ;  :command hook's :hold: nothing, the press stays)
             (when to (set-form e to))
             (let ((cost (kit-command-cost kit cmd)))
               (when (plusp cost) (reiatsu-spend! e cost)))
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

(defparameter *neutral-commands* '(:kikon :awaken :hoho :burst :step :breaker :sp2 :sp1 :sig :f :q)
  "Commands from idle / walk / guard (:burst: WHITE). :kikon starts the Kikon rush at any time (whether it becomes a
Kikon is decided when its strike connects: combat.lisp APPLY-HIT).")

(defparameter *run-commands* '(:kikon :hoho :burst :step :breaker :sp2 :sp1 :sig :f :q)
  "Commands a run cancels into at once (neutral's, without Awaken); Step again = a new hop.")

(defparameter *run-commands-p* (cons :awaken *run-commands*)
  "A run's commands for a form with a :p hook: P too (Hisagi's bind throw from a run, DUEL_HISAGI §17.2).")

(defun command! (e f vp allowed)
  "The highest-priority buffered command among ALLOWED that can start now; consumes its press. A
buffered command that can't start (Kikon too early, no bar, cooling down) doesn't hide the ones below it. Out of a
guard cancel no attack starts before the cancelled move's recovery would have ended (FIGHTER-GC-LEFT; the press stays
buffered): the cancel is a guard, never a faster restart (the user 2026-10-02: J3 -> guard cancel -> J1 looped J strings)."
  (loop for (cmd button mod) in *commands*
        thereis (and (member cmd allowed) (vpad-command-pressed-p vp button mod)
                     (not (and (plusp (fighter-gc-left f)) (member cmd *kit-commands*)))
                     (or (try-command e f cmd button) (refused-cue e f cmd vp button))
                     (progn (vpad-consume! vp button) t))))

(defun refused-cue (e f cmd vp button &optional combo)
  "A kit command pressed while it cools down (its :cooldown: L, South, the O module), or L without its cold (Rukia), or
one its kit's :ok hook refuses (COMBO: the chained L link, as KIT-COMMAND-OK-P got it): the press is eaten with a cue,
the :refused event (a flash of its HUD bar, a dud tick). NIL: the commands below it may still start."
  (let ((i (position cmd *kit-commands*)) (kit (fighter-kit f)))
    (cond ((and i (plusp (aref (fighter-cd f) i)))
           (vpad-consume! vp button)
           (emit :refused e cmd)
           (clog "~a refused ~a: cooling ~d" (side-name e) cmd (aref (fighter-cd f) i)))
          ((and (eq cmd :sig) (kit-command-move kit :sig) (< (gauges-meter (gauges e)) (cold-cost kit :sig)))
           (vpad-consume! vp button)
           (emit :refused e cmd)
           (clog "~a refused ~a: cold ~d" (side-name e) cmd (round (gauges-meter (gauges e)))))
          ((let ((h (kit-hook kit :ok))) (and h (kit-command-move kit cmd) (not (funcall h e cmd combo))))
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
         (not (and *run-mods* (run-no-guard-p e g vp)))   ; DANGAI's :red-no-guard
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
  "Idle / walk / strafe / guard: commands, then guard or walk, auto-facing. While guarding, and for *GUARD-EXIT* frames
after a guard is let go, no attack starts (Step, Hoho, the burst and the awakening do; the attack's press stays buffered)
and after the guard he stands (a guard may go up again). A form with :guard-to (Bankai East)
switches to that form while U is held instead of guarding (from idle / walk; a run stops into this step too): its
ward is up after *GUARD-RAISE* frames (FIGHTER-GUARD-T counts them, and keeps counting while he walks in it). Under a
Kikon lock (FIGHTER-KIKON-LOCK, 2026-10-24) no command and no walk: 1 the guard only, 2 not even that."
  (unless (and (zerop (fighter-lock f)) (zerop (fighter-kikon-lock f))         ; (a Kikon lock: no command, 2026-10-24)
               (if (or (plusp (fighter-guard-exit f)) (eq (fighter-state f) :guard))   ; guarding or just out of a guard:
                   (command! e f vp '(:awaken :burst :hoho :step))      ;  no attack (*GUARD-EXIT*, the user 2026-10-23;
                                                                        ;  the press stays buffered)
                   (or (command! e f vp *neutral-commands*) (u-press! e f vp))))
    (let ((v (motion-vel (motion e))))
      (when (and (zerop (fighter-lock f)) (< (fighter-kikon-lock f) 2) (kit-guard-to (fighter-kit f)) (guard-held-p e vp))
        (set-form e (kit-guard-to (fighter-kit f)))
        (setf (fighter-guard-t f) 0))
      (if (and (zerop (fighter-lock f)) (< (fighter-kikon-lock f) 2) (guard-p e vp))   ; (a red Kikon lock: no guard)
          (progn
            (unless (eq (fighter-state f) :guard)
              (setf (fighter-state f) :guard (fighter-guard-t f) 0)
              (when (pilot-cam-relative (pilot e)) (clog "~a guard" (side-name e)))
              (play-clip e :sh-guard :blend 3))
            (incf (fighter-guard-t f))
            (fill v 0f0))
          (multiple-value-bind (to st) (if (and (zerop (fighter-lock f)) (zerop (fighter-guard-exit f)) (zerop (fighter-kikon-lock f)))
                                           (stick-relative e f) (values 0.0 0.0))
            (when (eq (fighter-state f) :guard)
              (to-idle e 4)
              (setf (fighter-guard-exit f) *guard-exit*))
            (setf (fighter-guard-t f) (if (passive-p e :ward) (min 9999 (1+ (fighter-guard-t f))) 0))
            (neutral-walk! e f v to st)))
      (turn-to-opp e f (%deg *face-rate*)))))

(defun neutral-walk! (e f v to st)
  "NEUTRAL-STEP's walk / strafe at stick TO / ST relative to the opponent (or stand: a stick under 0.2, a walk speed of 0):
velocity V and the clip. Single-float sticks and speed (the sim's): typed, nothing boxed (the twins: bit-identical);
else the generic code."
  (let* ((kit (fighter-kit f))
         (speed (layer-speed (frost-speed (kit-walk kit) (fighter-frost f)) (fighter-layers f))))
    (if (and (typep to 'single-float) (typep st 'single-float) (typep (kit-walk kit) 'single-float) (typep speed 'single-float))
        (sim-fast
          (let* ((a to) (b st) (m (%sqrt (+ (* a a) (* b b)))) (walk (kit-walk kit)))
            (declare (single-float a b m walk))
            (if (or (< m 0.2) (<= walk 0f0))   ; (absolute zero: rooted where she stands)
                (progn (fill v 0f0) (play-clip e (kit-stance kit) :blend 6 :restart nil))
                (let* ((p (pos-of e)) (vv v) (sp speed))
                  (declare (type f32vec p vv) (single-float sp))
                  (with-toward-strafe-dir (dx dz) (a b (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f))
                    (let* ((s (* (* sp (%min 1.0 m)) (/ 1.0 m))))
                      (declare (single-float s))
                      (setf (aref vv 0) (* s dx) (aref vv 2) (* s dz))))
                  (field-slow! e f v)
                  (play-clip e (if (> (f-abs b) (f-abs a)) (if (> b 0f0) :sh-strafe-r :sh-strafe-l) (if (> a 0f0) :sh-walk-f :sh-walk-b))
                             :blend 6 :restart nil)))))
        (let ((m (hypot to st)))
          (if (or (< m 0.2) (<= (kit-walk kit) 0))
              (progn (fill v 0f0) (play-clip e (kit-stance kit) :blend 6 :restart nil))
              (multiple-value-bind (dx dz) (world-dir e f to st)
                (let ((s (* speed (min 1.0 m) (/ 1.0 m))))
                  (setf (aref v 0) (f32 (* s dx)) (aref v 2) (f32 (* s dz)))
                  (field-slow! e f v))
                (play-clip e (cond ((> (abs st) (abs to)) (if (> st 0) :sh-strafe-r :sh-strafe-l))
                                   ((> to 0) :sh-walk-f) (t :sh-walk-b))
                           :blend 6 :restart nil)))))))

(defun hold-phase-step (e f vp mv)
  "Charge / stance: hold until the button is released (min..max frames), then the move proper."
  (incf (fighter-hold f))
  (when (mv-tick mv) (funcall (mv-tick mv) e))
  (destructuring-bind (lo hi) (mv-hold mv)
    (when (and (eq (fighter-move f) mv) (eq (fighter-phase f) :hold)   ; (its tick may have started another move: Lille II's
               (or (>= (fighter-hold f) hi)                              ;  Step out of the snipe's charge, R18)
                   (and (>= (fighter-hold f) lo) (not (vpad-down vp (fighter-button f))))))
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
                                           :aura (rush-param mv :aura) :dash-max (rush-dash-max f mv))))
          (when (and (eq next :strike) (eq phase :dash) (fighter-end-chase f) (< (fighter-hold f) (rush-dash-max f mv))
                     (plusp (motion-kb-left (motion (fighter-opp f)))))   ; off a pushing ender: he still slides away,
            (setf next :dash))                                             ; dash on (the strike would miss him)
          (cond ((eq next :strike) (enter-main e f mv))
                (t (unless (eq next phase)
                     (setf (fighter-phase f) next (fighter-hold f) 0)
                     (emit :rush-dash e))
                   (if (eq next :dash)
                       (progn (turn-to-opp e f (track-step (rush-param mv :dash-track)))
                              (run-velocity e (rush-dash-speed f mv)))
                       (turn-to-opp e f (track-step (rush-param mv :aim))))))))))

(defun main-phase-step (e f vp mv)
  "The move proper, one frame: tracking and lunge in the startup, frame hooks, chains and cancels,
the end (MOVE-END-FRAME)."
  (let ((sf (incf (fighter-sf f))) (s (mv-s mv)) (v (motion-vel (motion e))))
    (fill v 0f0)
    (when (< sf s)
      (let* ((chained (fighter-chained f)) (rooted (kit-rooted (fighter-kit f)))   ; (rooted: her reach is the ice's)
             (chase (if (and (not rooted)
                             (or (fighter-end-chase f)                                            ; off a pushing ender
                                 (and chained (not (member (mv-kind mv) '(:quick :flash))))))    ; J / K links: no chase
                        (string-chase-speed (fighter-dist f) (mv-reach mv) (- s sf)               ; (the user 2026-10-02)
                                            (if (fighter-end-chase f) *ender-chase-max* *chase-max*))
                        0.0))
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
    (when (eq (fighter-move f) mv)                        ; a hook may have started another move
      (cond ((and (zerop (fighter-lock f)) (move-commands e f vp mv sf)))
            ((and (zerop (fighter-lock f)) (guard-cancel-open-p sf s (mv-a mv) (mv-r mv) (fighter-contact f) (mv-kind mv) (mv-whiff mv) (getf (mv-params mv) :gc-from))
                  (guard-held-p e vp))                  ; the guard cancel: U held late in its recovery (a hit; a J / K / O
             (clog "~a guard cancel ~a f~d" (side-name e) (mv-name mv) sf)   ;  blocked or whiffed too)
             (to-idle e)                                ; (a :guard-to / :ward form: neutral, whose U does the rest)
             (setf (fighter-gc-left f) (- (move-end-frame s (mv-a mv) (mv-r mv) (mv-whiff mv) (fighter-contact f)   ; no attack before
                                                          (zerop (length (mv-hits mv))) (mv-kind mv))           ;  its recovery
                                          sf))                                                                  ;  would have ended
             (when (guard-p e vp)
               (setf (fighter-state f) :guard (fighter-guard-t f) 0)
               (play-clip e :sh-guard :blend 3)))
            ((>= sf (move-end-frame s (mv-a mv) (mv-r mv) (mv-whiff mv) (fighter-contact f)
                                    (zerop (length (mv-hits mv))) (mv-kind mv)))
             (to-idle e))))))

(defun push-apart (a b dist frames)
  "Push fighter B DIST metres away from A over FRAMES; what the arena's edge leaves no room for pushes A back instead (the
user 2026-10-02: a victim against the wall can't be moved, so the attacker is). Values B's and A's share."
  (let* ((p (pos-of a)) (q (pos-of b)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (l (max 1e-4 (hypot dx dz))) (ux (/ dx l)) (uz (/ dz l))
         (room (ray-room (aref q 0) (aref q 2) ux uz (- *arena-radius* (body-hurt-r (model-body (model b))))))
         (mb (min dist room)) (ma (- dist mb)))
    (when (> mb 0.01) (set-slide b mb frames ux uz))
    (when (> ma 0.01) (set-slide a ma frames (- ux) (- uz)))
    (values mb ma)))

(defun ender-push (e o mv)
  "E's J / K string ender MV (J3 / K3) just hit O: O is pushed out of the reach of E's J1 (after J3) or K1 (after K3) --
its far edge (its reach, + a capsule's radius: MOVE-EDGE; a K ender: the kit's :push-reach in its place when set, ENDER-PUSH-REACH) + its own lunge + O's body + *ENDER-PUSH* (the user 2026-10-02: a restarted string must not reach him; pushed
at the hit). E doesn't move, unless the arena's edge holds O (PUSH-APART). What E starts off the ender chases him
(START-MOVE: FIGHTER-END-CHASE)."
  (let* ((f (fighter e)) (opener (kit-command-move (fighter-kit f) (if (eq (mv-kind mv) :quick) :q :f) e))
         (push (and opener (- (+ (ender-push-reach (fighter-kit f) mv opener) (mv-slide opener) (body-hurt-r (model-body (model o)))
                                 *ender-push*)
                              (fighter-dist f)))))
    (when (and push (plusp push))
      (multiple-value-bind (mb ma) (push-apart e o push *ender-push-frames*)
        (clog "~a ender push ~a ~,1f m (attacker ~,1f)" (side-name e) (mv-name mv) mb ma)))))

(defun move-step (e f vp)
  "Advance the current move one frame: its pre-strike phase, or the move proper."
  (let ((mv (fighter-move f)))
    (case (fighter-phase f)
      (:hold (hold-phase-step e f vp mv))
      ((:aura :dash :follow) (if (eq (mv-kind mv) :kikon) (kikon-rush-step e f mv) (breaker-phase-step e f vp mv)))
      (t (main-phase-step e f vp mv)))))

(defun rush-dash-max (f mv)
  "The rush MV's dash frames: its module's :dash-max, at least *ENDER-O-DASH* for an O ender off a J3 / K3 that pushed
him away (FIGHTER-END-CHASE; the user 2026-10-02: K3 -> O whiffed), so it reaches him; a module whose strike reaches him
from where it stands sets its own floor :ender-dash (Lille's 12 m lane shots: 0, DUEL_LILLE_V3 §27)."
  (if (fighter-end-chase f)
      (max (or (rush-param mv :ender-dash) *ender-o-dash*) (rush-param mv :dash-max))
      (rush-param mv :dash-max)))
(defun rush-dash-speed (f mv)
  "The rush MV's dash speed: its module's :speed, at least *ENDER-O-SPEED* off a pushing ender (RUSH-DASH-MAX)."
  (if (fighter-end-chase f) (max *ender-o-speed* (rush-param mv :speed)) (rush-param mv :speed)))

(defun skip-aura (e f)
  "The O ender (docs/duel/DUEL_STRINGS.md §2.4): the Kikon rush just started off a link-3 hit skips its aura: its strike
at once within *KIKON-TRIGGER* (or a module with no dash), else its dash."
  (let ((mv (fighter-move f)))
    (if (and (not (fighter-end-chase f))                    ; (off a pushing ender: always the dash, he is sliding away)
             (eq (kikon-rush-next-phase :aura 0 (fighter-dist f) :aura 0 :dash-max (rush-dash-max f mv)) :strike))
        (enter-main e f mv)
        (progn (setf (fighter-phase f) :dash (fighter-hold f) 0) (emit :rush-dash e)))))

(defun move-commands (e f vp mv sf)
  "Chains (string follow-ups) and cancels during a move, walked in *COMMANDS* priority order (a
refused one doesn't hide the next). A J / K press during a string link is latched (STRING-LATCH: the last allowed
press wins, a press of the button the string switched away from is eaten) and consumed at once; the latched link
starts when the chain opens (CHAIN-OPEN-P: once any link of the string touched him, docs/duel/DUEL_STRINGS.md §2.2) and
chases him in its startup (STRING-CHASE-SPEED). A Breaker that landed (a hit or a Guard Break) cancels into J1 / K1 (the
string's opener, chasing him; docs/duel/DUEL_STRINGS.md §17). O is the ender: only off a link-3 (:ender) hit, the
rush's aura skipped. L during a K link of a form with :l-after-k (a J link: :l-after-j) is latched too (KIT-L-LINK,
docs/duel/DUEL_STRINGS.md §12): it starts when that link's own contact opens the chain, as a follow-up (the chase), under
L's own checks (cooldown, cold, the kit's :ok with the link as COMBO; a refused one gets the cue). T when a new move /
action started."
  (let ((kit (fighter-kit f)) (landed (fighter-contact f)) (name (mv-name mv)))
    (or (loop for (cmd button mod) in *commands*
              thereis (and (member cmd '(:kikon :q :f :sp1 :sp2 :sig :hoho :burst))
                           (vpad-command-pressed-p vp button mod)
                           (case cmd
                             (:kikon (and (member :ender (mv-flags mv))   ; the O ender: a completed string
                                          (cancel-open-p sf (fighter-land-sf f) (mv-total mv) (eq landed :hit))
                                          (try-command e f cmd button t)
                                          (progn (skip-aura e f) t)))
                             ((:q :f) (cond ((string-link-p kit name)   ; the latch takes every J / K press
                                             (setf (fighter-queued f) (string-latch kit name cmd (fighter-queued f)))
                                             (vpad-consume! vp button)
                                             nil)
                                            ((eq (mv-kind mv) :breaker)   ; the Breaker opens a string: J1 / K1 off its
                                             (and (cancel-open-p sf (fighter-land-sf f) (mv-total mv) (eq landed :hit))   ; hit
                                                  (try-command e f cmd button)))   ; or Guard Break (the user 2026-10-02)
                                            ((member cmd (getf (mv-params mv) :r-cancel))   ; its recovery cancelled into
                                             (and (let ((from (getf (mv-params mv) :r-cancel-from)))   ;  J1 / K1 once it hit
                                                    (if from                ; (Rukia's awakened L: from move frame FROM,
                                                        (and (>= sf from) (or (eq landed :hit) (fighter-hz-hit f)))   ; its
                                                        (and (>= sf (+ (mv-s mv) (mv-a mv))) (eq landed :hit))))   ; disc's
                                                  (try-command e f cmd button)))))   ; hit; Hisagi's ranged L, DUEL_HISAGI
                                                                                     ; §25.5 / §25.8)
                             (:sig (let ((l (kit-l-link kit name)))   ; L after a J / K link: latched like a link
                                     (if l
                                         (progn (if (kit-command-ok-p e :sig (fighter-kit f) nil l)
                                                    (progn (setf (fighter-queued f) :sig)
                                                           (vpad-consume! vp button))
                                                    (refused-cue e f :sig vp button l))   ; refused: the cue, eaten
                                                nil)
                                         (cancel-into e f kit mv sf landed cmd button))))
                             (:burst (try-command e f cmd button))   ; ORANGE (BURST-OK-P: his hit landed)
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
                    ((let ((h (kit-hook kit :link-ok))) (and h (not (funcall h e next))))   ; the kit refuses this link
                     (setf (fighter-queued f) nil)                                      ;  (Hisagi: one leap a combo): it ends
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

(defun kikon-lock-holds-p (f)
  "Does F's opponent still hold F's Kikon lock (rules KIKON-LOCK-P on the rusher's move)?"
  (let* ((o (fighter-opp f)) (fo (and o (entity-alive-p o) (fighter o))) (mv (and fo (eq (fighter-state fo) :move) (fighter-move fo))))
    (and mv (kikon-lock-p (fighter-state fo) (fighter-follow fo) (fighter-phase fo) (fighter-contact fo) (fighter-sf fo)
                          (mv-s mv) (mv-a mv)))))

(defun stun-step (e f vp)
  "A reaction / blockstun counts down (Burst Reverse may be pressed); then neutral (guard again if
Guard is held). Blockstun past its end waits while the guard lock holds him (FIGHTER-GLOCK: his attacker may still
chain); only BLUE and the awakening break it. Under a Kikon lock (FIGHTER-KIKON-LOCK, 2026-10-24) no Burst or
awakening; lock 1 (not red): U cancels the reel into a guard (the follow-up's strike is then blocked)."
  (when (and (= (fighter-kikon-lock f) 1) (eq (fighter-state f) :stun) (guard-p e vp))
    (setf (fighter-state f) :guard (fighter-guard-t f) 0 (fighter-sf f) 0)
    (play-clip e :sh-guard :blend 3)
    (return-from stun-step nil))
  (when (and (zerop (fighter-lock f)) (zerop (fighter-kikon-lock f))) (command! e f vp '(:burst :awaken)))
  (when (and (>= (incf (fighter-sf f)) (fighter-stun f)) (not (and (eq (fighter-state f) :guard-hit) (fighter-glock f))))
    (to-idle e)
    (when (guard-p e vp) (setf (fighter-state f) :guard (fighter-guard-t f) *guard-raise*) (play-clip e :sh-guard :blend 3))))

(defun chain-more-p (e f mv)
  "Can E's move MV still go on into a follow-up (the guard lock's MORE): a next J / K link, an L link L may start, the
on-hit cancels (its hit landed: SP, Hoho, a :cancel L, the O ender), or ORANGE (BURST-OK-P, a blocked L / O included)?"
  (let ((kit (fighter-kit f)) (name (mv-name mv)))
    (or (string-link-p kit name)
        (let ((l (kit-l-link kit name))) (and l (kit-command-ok-p e :sig kit nil l)))
        (and (eq (fighter-contact f) :hit) (member (mv-kind mv) '(:quick :flash)))
        (eq (burst-ok-p e) :orange))))

(defun guard-lock-of (f)
  "Does the guard lock hold F (in blockstun) on his next step (rules GUARD-LOCKED-P, his attacker's side read here)?"
  (let* ((o (fighter-opp f)) (fo (and o (entity-alive-p o) (fighter o))) (mv (and fo (eq (fighter-state fo) :move) (fighter-move fo))))
    (and fo
         (guard-locked-p (fighter-state f) (fighter-glock f) (fighter-chain fo) (fighter-state fo) (fighter-phase fo)
                         (fighter-sf fo) (if mv (mv-s mv) 0) (if mv (mv-a mv) 0) (if mv (mv-r mv) 0)
                         (and mv (or (fighter-contact fo) (fighter-chained fo)))
                         (and mv (eq (fighter-state f) :guard-hit) (chain-more-p o fo mv))))))

(defun guard-locked-now-p (f)
  "Is F held past his blockstun's end by the guard lock right now (the HUD's LOCK tint, the CPU)?"
  (and (eq (fighter-state f) :guard-hit) (fighter-glock f) (>= (fighter-sf f) (fighter-stun f))))

(defun step-step (e f vp)
  "The hop; at its end a Step still held becomes a run (so holding never shortens a Step). From *STEP-J-CANCEL* (the
hop landed) J cancels the rest into J1 (the user 2026-10-02); a J pressed earlier in the hop is latched for it."
  (let ((j (find :q *commands* :key #'first)))
    (when (and (zerop (fighter-lock f)) (vpad-command-pressed-p vp (second j) (third j)))
      (vpad-consume! vp (second j))
      (setf (fighter-queued f) :q))
    (unless (and (fighter-queued f) (>= (fighter-sf f) *step-j-cancel*) (zerop (fighter-gc-left f))
                 (try-command e f :q (second j)))
      (when (>= (incf (fighter-sf f)) *step-frames*)
        (setf (fighter-queued f) nil)
        (if (and (zerop (fighter-lock f)) (vpad-down vp :step)) (start-run e f) (to-idle e))))))

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
         (speed (layer-speed (frost-speed (kit-run (fighter-kit f)) (fighter-frost f)) (fighter-layers f))) (sf (incf (fighter-sf f))) (free (zerop (fighter-lock f))))
    (cond ((eq (fighter-phase f) :brake)
           (let ((s (if (run-stop-p (fighter-dist f) (run-closing e f) speed) 0.0 (brake-speed speed sf))))
             (turn-to-opp e f (%deg *face-rate*))
             (if (or (<= s 0) (>= sf *run-brake*)) (to-idle e) (run-velocity e s (fighter-run-yaw f)))))
          ((and free (or (command! e f vp (if (kit-hook (fighter-kit f) :p) *run-commands-p* *run-commands*)) (u-press! e f vp)))
           (when (eq (fighter-state f) :move)
             (set-slide e (run-carry (fighter-dist f)) *run-carry-frames* vx vz)
             (clog "~a run -> ~a, carry ~,1f m" (side-name e) (mv-name (fighter-move f)) (run-carry (fighter-dist f)))))
          ((and free (guard-held-p e vp) (not (passive-p e :ward))) (to-idle e 3) (neutral-step e f vp))
          ((not (and free (vpad-down vp :step)))
           (setf (fighter-phase f) :brake (fighter-sf f) 0)
           (play-clip e (kit-stance (fighter-kit f)) :blend 6))
          (t (setf (fighter-run-yaw f) (f32 (angle-wrap (turn-toward (fighter-run-yaw f) (run-yaw e f) (track-step *run-turn*)))))
             (turn-to-opp e f (%deg *face-rate*))
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
      (let ((p (pos-of e))) (emit :hoho-in e (aref p 0) (aref p 2)))
      (let ((h (kit-hook (fighter-kit f) :hoho))) (when h (funcall h e))))   ; the form's own arrival (Rukia's cold)
    (when (and (= sf *hoho-counter-pose*) (fighter-perfect f))
      (play-clip e (kit-move-clip (fighter-kit f) (mv-clip (kit-command-move (fighter-kit f) :q))) :blend 0 :time 0.1))
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
    (halt! e)
    (set-slide e *block-pushback* 6 (- (aref p 0) from-x) (- (aref p 2) from-z))
    (play-clip e (or clip :sh-guard-hit) :blend 0)))

(defun own-armor-p (e f mv)
  "Is E's move MV armoured now (DEFENDER-STATE's :armor): its own armour (:armor-hits left, from move frame *ARMOR-FROM* to
its startup's end, or a Kikon rush's dash), or a kit's :armor hook (Lille II's wings: DUEL_LILLE_V3 R1)?"
  (or (and (plusp (fighter-armor-left f))
           (if (eq (mv-kind mv) :kikon)
               (eq (fighter-phase f) :dash)
               (and (eq (fighter-phase f) :main) (<= *armor-from* (fighter-sf f)) (< (fighter-sf f) (mv-s mv)))))
      (let ((h (kit-hook (kit-of e) :armor))) (and h (funcall h e f mv) t))))

(defun defender-state (e)
  "E's side of the triangle for RESOLVE-CONTACT (rules.lisp): :neutral :guard :breaker :stance-in
:stance :armor :parry :invuln. Bankai West's ward (passive :ward, up *GUARD-RAISE* frames after U) is :guard in his
free states (idle, walk, run), the non-invulnerable frames of Step / Hoho and his own moves (a parry's window is
still :parry); never in a reaction (a bind, a Guard Break, a crush reel: no armoured combos) -- except DANGAI's run
armour (RUN-ARMOR-P: :armor wherever he would be :neutral)."
  (let* ((f (fighter e)) (sf (fighter-sf f)) (mv (fighter-move f))
         (open (if (and (passive-p e :ward) (>= (fighter-guard-t f) *guard-raise*)) :guard :neutral)))
    (let ((s (case (if (> (fighter-invuln f) 0) :invuln (fighter-state f))
      ((:idle :run) open)
      (:invuln :invuln)                                  ; after a Burst
      (:guard (if (and (>= (fighter-guard-t f) *guard-raise*) (can-guard-p (gauges-gg (gauges e)) (gauges-guardless (gauges e))))
                  :guard :neutral))
      (:guard-hit :guard)
      (:step (if (and (invulnerable-frame-p sf *step-iframes*) (not (fighter-step-open f))) :invuln open))
      (:hoho (if (invulnerable-frame-p sf *hoho-iframes*) :invuln open))
      ((:down :wakeup :cine :intro :win :lose) :invuln)
      (:air (if (eq (fighter-phase f) :knockdown) :invuln :neutral))   ; the combo limits' forced knockdown
      (:move (cond ((and (eq (mv-kind mv) :breaker) (or (member (fighter-phase f) '(:aura :dash)) (< sf (mv-s mv))))
                    :breaker)
                   ((own-armor-p e f mv) :armor)
                   ((and (member :stance (mv-flags mv)) (eq (fighter-phase f) :hold))
                    (if (< (fighter-hold f) *stance-in*) :stance-in :stance))
                   ((and (member :parry (mv-flags mv)) (eq (fighter-phase f) :main) (parry-frame-p sf (getf (mv-params mv) :window))) :parry)
                   ((and (member :shield (mv-flags mv)) (eq (fighter-phase f) :main) (<= (mv-s mv) sf) (< sf (+ (mv-s mv) (mv-a mv))))
                    :guard)                                        ; a :shield move's window is a guard (its catch: APPLY-HIT)
                   (t open)))
      (t :neutral))))
      (if (and (eq s :neutral) *run-mods* (run-armor-p e)) :armor s))))   ; DANGAI's run armour (one hit, any open state)

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
         (r (- (f32 *arena-radius*) (the single-float (body-hurt-r (model-body (model e)))))))   ; (typed: no boxed temp)
    (declare (type f32vec p v kb) (single-float dt r))
    (setf (aref p 0) (+ (aref p 0) (* dt (aref v 0))) (aref p 2) (+ (aref p 2) (* dt (aref v 2))))
    (when (> (the fixnum (motion-kb-left mo)) 0)
      (setf (aref p 0) (+ (aref p 0) (aref kb 0)) (aref p 2) (+ (aref p 2) (aref kb 2))
            (motion-kb-left mo) (1- (the fixnum (motion-kb-left mo)))))
    (unless (motion-grounded mo)
      (setf (aref v 1) (- (aref v 1) (* (the single-float *gravity*) dt)) (aref p 1) (+ (aref p 1) (* dt (aref v 1))))
      (when (and (<= (aref p 1) 0f0) (<= (aref v 1) 0f0))
        (setf (aref p 1) 0f0 (aref v 1) 0f0 (motion-grounded mo) t)))
    (let* ((x (aref p 0)) (z (aref p 2)) (d (f-hypot x z)))
      (declare (single-float x z d))
      (when (> d r) (setf (aref p 0) (* x (/ r d)) (aref p 2) (* z (/ r d)))))
    nil))

(defun through-move-p (e)
  "Is fighter E in a move flagged :through (a dash that passes through the opponent: no body push while it runs)?"
  (let ((f (fighter e))) (and (eq (fighter-state f) :move) (fighter-move f) (member :through (mv-flags (fighter-move f))) t)))

(defun separate-fighters (a b)
  "Two grounded, visible fighters never overlap: push both apart equally (symmetric); not while either is in a Hoho, a
cinematic or a :through move."
  (unless (or (member (state-of a) '(:hoho :cine)) (member (state-of b) '(:hoho :cine)) (through-move-p a) (through-move-p b))
    (sim-fast                                     ; (typed: the same float operations, no boxing)
      (let* ((p (pos-of a)) (q (pos-of b)) (ra (body-hurt-r (model-body (model a)))) (rb (body-hurt-r (model-body (model b)))))
        (declare (type f32vec p q) (single-float ra rb))
        (let* ((dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (d (%sqrt (+ (* dx dx) (* dz dz))))
               (min-d (+ ra rb)))
          (declare (single-float dx dz d min-d))
          (when (and (< d min-d) (< (f-abs (- (aref p 1) (aref q 1))) 1.2))
            (let* ((push (* 0.5 (- min-d d))) (ux (if (> d 1e-3) (/ dx d) 1.0)) (uz (if (> d 1e-3) (/ dz d) 0.0)))
              (declare (single-float push ux uz))
              (setf (aref p 0) (- (aref p 0) (* push ux)) (aref p 2) (- (aref p 2) (* push uz))
                    (aref q 0) (+ (aref q 0) (* push ux)) (aref q 2) (+ (aref q 2) (* push uz))))))))))

;;; ---------------------------------------------------------------- the system
(defun fighter-step (e f)
  "One fixed step of fighter E."
  (when (> (fighter-freeze f) 0) (decf (fighter-freeze f)) (return-from fighter-step nil))
  (when (> (fighter-lock f) 0) (decf (fighter-lock f)))
  (when (> (fighter-hoho-lock f) 0) (decf (fighter-hoho-lock f)))
  (when (> (fighter-gc-left f) 0) (decf (fighter-gc-left f)))
  (when (> (fighter-guard-exit f) 0) (decf (fighter-guard-exit f)))
  (when (and (plusp (fighter-kikon-lock f)) (not (kikon-lock-holds-p f))) (setf (fighter-kikon-lock f) 0))
  (when (> (fighter-invuln f) 0) (decf (fighter-invuln f)))
  (when (> (fighter-callout-t f) 0) (decf (fighter-callout-t f)))
  (when (> (fighter-frost f) 0) (decf (fighter-frost f)))
  (when (> (fighter-seal f) 0) (decf (fighter-seal f)))
  (setf (fighter-kikon-lock f) (kikon-lock-after-seal (fighter-kikon-lock f) (fighter-seal f) (gauges-red-p (gauges e))))
  (when (or (plusp (fighter-layers f)) (plusp (fighter-chill f)))   ; 霜の層 thaw (Rukia's Shikai: rules LAYERS-THAW)
    (multiple-value-bind (l th c) (layers-thaw (fighter-layers f) (fighter-thaw f) (fighter-chill f))
      (setf (fighter-layers f) l (fighter-thaw f) th (fighter-chill f) c)))
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
  (when (> (fighter-chain f) 0) (decf (fighter-chain f)))   ; ORANGE's window: *CHAIN-WINDOW* steps after the cancel
  (fighter-physics e)
  (anim-advance (model-anim (model e)) +step+))

(defun fighter-system ()
  "Every fighter: snapshot the opponents' positions first (nobody sees the other's move of this
step: a symmetric sim), step each, then keep them apart."
  (let ((a nil) (b nil))
    (do-entities (e (f fighter))
      (let ((o (fighter-opp f)))
        (when (entity-alive-p o)
          (sim-fast
            (let* ((p (pos-of e)) (q (pos-of o)))
              (declare (type f32vec p q))
              (let* ((dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (d (%sqrt (+ (* dx dx) (* dz dz)))))
                (declare (single-float dx dz d))
                (%set-float (fighter-ox f) (aref q 0))
                (%set-float (fighter-oz f) (aref q 2))
                (%set-float (fighter-dist f) d))))))
      (if a (setf b e) (setf a e)))
    (when (and a b) (view-step a b))
    (do-entities (e (f fighter)) (unless (eq (fighter-state f) :cine) (fighter-step e f)))
    ;; freezes / locks one fighter put on the other take effect now that both have stepped
    (do-entities (e (f fighter))
      (setf (fighter-freeze f) (max (fighter-freeze f) (fighter-freeze-next f))
            (fighter-lock f) (max (fighter-lock f) (fighter-lock-next f))
            (fighter-freeze-next f) 0 (fighter-lock-next f) 0))
    ;; a burst pressed this step applies now, unless a cinematic began (an awakening on the same step
    ;; wins); BLUE ends the attacker's move, so a Kikon rush that hasn't connected yet is escaped
    (do-entities (e (f fighter))
      (let ((m (fighter-burst f)))
        (when m
          (setf (fighter-burst f) nil)
          (unless *cine* (burst! e m)))))
    (unless *cine* (bind-step! a :release))   ; the bind's release applies here too (DUEL_HISAGI §17.3), before the hits
    ;; the guard lock, judged once both stepped (and any burst applied), read by the blockstun on the next step
    (do-entities (e (f fighter)) (setf (fighter-glock f) (guard-lock-of f)))
    (when (and a b) (separate-fighters a b))))
