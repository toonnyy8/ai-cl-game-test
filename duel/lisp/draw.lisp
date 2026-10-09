;;;; draw.lisp — SOUL DUEL's fighters on screen: pose, ghost afterimages, faces, auras, the 3D scene queue (DRAW-SCENE).
;;;; Moved out of main.lisp (refactor 2026-10, PLAN B13); main.lisp keeps the fixed step, the frame and the entry.
;;;; Presentation only: the sim never reads anything defined here.
(in-package :duel)

;;; ---------------------------------------------------------------- drawing
(declaim (type f32vec *tip* *base*))
(defvar *tip* (make-f32 3))
(defvar *base* (make-f32 3))
(defvar *super-rim* (rim-vec #xFFFFFF 3.0) "SP start: the rim-light super flash.")
(defparameter *evolution-rgb* '(1.0 0.85 0.3))
(defvar *no-parts* (make-array +nj+ :initial-element nil) "DRAW-PARTS with no solids: the hulls alone (ink afterimage).")
(defparameter *ghost-ink* '(0.35 0.35 0.4) "Ink afterimage tint: the keyline grey of black parts darkened to ink.")

(defun-fast smear-joints! (joints cx cy cz dx dz)
  "The squash / stretch smear drawing: premultiply every joint matrix by T(c) S T(-c), S = x1.5 along the
ground direction (DX DZ) (unit) and x0.7 across it, about the body centre C (docs/style/STYLE_STORM_DESIGN.md §2.6).
The hulls follow (they are drawn from the same joints)."
  (declare (type f32vec joints) (single-float cx cy cz dx dz))
  (let* ((a 0.7f0) (b 0.8f0))                          ; S = a I + b d d^T
    (declare (single-float a b))
    (dotimes (j +nj+)
      (let* ((o (* j 16)))
        (declare (fixnum o))
        (dotimes (col 4)
          (let* ((k (+ o (* 4 col))) (tr (= col 3))
                 (vx (if tr (- (aref joints k) cx) (aref joints k))) (vy (if tr (- (aref joints (+ k 1)) cy) (aref joints (+ k 1))))
                 (vz (if tr (- (aref joints (+ k 2)) cz) (aref joints (+ k 2))))
                 (dd (* b (+ (* dx vx) (* dz vz)))))
            (declare (fixnum k) (single-float vx vy vz dd))
            (setf (aref joints k) (+ (* a vx) (* dd dx) (if tr cx 0f0))
                  (aref joints (+ k 1)) (+ (* a vy) (if tr cy 0f0))
                  (aref joints (+ k 2)) (+ (* a vz) (* dd dz) (if tr cz 0f0)))))))
    nil))

(defun hold-pose (e frames)
  "Hold fighter E's drawn pose for FRAMES (60 Hz, effect time; visual only: the sim runs on)."
  (let ((m (model e))) (setf (model-hold m) (f32 (max (model-hold m) (/ frames 60.0))))))

(defun smear (e dx dz)
  "One squash / stretch smear drawing of fighter E along the ground direction (DX DZ)."
  (let* ((m (model e)) (l (max 1e-4 (hypot dx dz))) (v (model-smear-dir m)))
    (setf (model-smear m) (/ 1.0 60.0) (aref v 0) (f32 (/ dx l)) (aref v 1) (f32 (/ dz l)))))

(defun start-ghost (e)
  "The Hoho afterimage: the pose E vanishes in, smeared sideways (the squash / stretch drawing), drawn
white (drawing 1) then as a solid ink silhouette (2)."
  (let* ((m (model e)) (g (model-ghost m)) (p (pos-of e)) (yaw (yaw-of e)))
    (replace g (model-joints m))
    (smear-joints! g (aref p 0) (+ (aref p 1) 1f0) (aref p 2) (fwd-z yaw) (- (fwd-x yaw)))
    (setf (model-ghost-age m) 0f0)))

(defun draw-ghost (e dt)
  "Draw fighter E's Hoho afterimage while it lasts (2 drawings white, 2 ink: twos on the fx clock)."
  (let* ((m (model e)) (age (model-ghost-age m)) (b (model-body m)))
    (when (>= age 0.0)
      (let ((q (sage age 2f0)))
        (cond ((< q (/ 2 24.0)) (draw-body b (model-ghost m) 0.0 0.0 0.0 0.0 :hide (face-hide-list m :neutral) :tint (model-tint m) :flash 1.0 :shadow nil))
              ((< q (/ 4 24.0)) (draw-parts *no-parts* nil (model-ghost m) :toon *toon-body* :hulls (body-hulls b) :ink-tint *ghost-ink*))
              (t (setf age -2.0))))
      (setf (model-ghost-age m) (if (< age -1.0) -1f0 (f32 (+ age dt)))))))

(defun rush-dashing-p (f)
  "Is F's Kikon rush travelling now: its dash, or the dash-in after the victim of a held strike (until it
reaches the trigger range)?"
  (case (fighter-phase f)
    (:dash t)
    (:follow (> (fighter-dist f) (+ *kikon-trigger* 0.05)))))

(defun rush-lift (f mv)
  "The drawn height of a Kikon rush module's leap (its :lift, metres; a look: the sim stays on the
ground): up over the first 8 f of the dash (or the dash-in), down over the strike's startup."
  (let ((h (and mv (eq (mv-kind mv) :kikon) (getf (mv-params mv) :lift))))
    (cond ((null h) 0.0)
          ((member (fighter-phase f) '(:dash :follow)) (* h (min 1.0 (/ (fighter-hold f) 8.0))))
          ((and (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))
           (* h (- 1.0 (/ (fighter-sf f) (float (mv-s mv))))))
          (t 0.0))))

(defparameter *hurt-cines* '(yama-kikon-cine yama-tenchi-cine ken-kikon-cine ken-sky-split-cine ken-oni-kikon-cine soul-break-cine
                             ko-cine)
  "The cinematics whose victim (V) shows the hurt face; their attacker (A) shouts (every cinematic's A does but the intro's,
TIME's and the K.O.'s winner).")

(defun face-of (e f m mv)
  "Fighter E's expression this frame (docs/style/STYLE_STORM_DESIGN.md §2.5, Phase 5; a look, read from the state): a held
face (MODEL-FACE-T) first; in a cinematic the attacker shouts and a Kikon's / Soul Break's / K.O.'s victim is hurt; hurt
while stunned, airborne, down or lost; shouting through a non-Quick move from 10 f before its hit to 12 f after it (and
through its charge, aura or dash phases). A :calm form (the white Rukia) never shouts."
  (let ((st (fighter-state f)))
    (cond ((> (model-face-t m) 0f0) (model-face m))
          ((eq st :cine)
           (let ((c *cine*))
             (cond ((null c) :neutral)
                   ((eql e (cine-a c)) (if (or (kit-calm (fighter-kit f)) (member (cine-name c) '(intro-cine time-cine ko-cine)))
                                           :neutral :shout))
                   ((member (cine-name c) *hurt-cines*) :hurt)
                   (t :neutral))))
          ((member st '(:stun :air :down :lose)) :hurt)
          ((and mv (eq st :move) (not (eq (mv-kind mv) :quick))
                (or (not (eq (fighter-phase f) :main)) (<= (- (mv-s mv) 10) (fighter-sf f) (+ (mv-s mv) (mv-a mv) 12))))
           (if (kit-calm (fighter-kit f)) :neutral :shout))
          (t :neutral))))

(defun face-beat (e face secs &optional head-back)
  "Hold fighter E's expression FACE for SECS (effect seconds); HEAD-BACK: also throw his head back over them (the
overlay pose of DRAW-FIGHTER: cup 3's grin on entry). A look."
  (let ((m (model e)))
    (setf (model-face m) face (model-face-t m) (f32 secs))
    (when head-back (setf (model-beat m) (f32 secs)))))

(declaim (type f32vec *beat-pose*))
(defvar *beat-pose* (make-f32 +pose-n+) "DRAW-FIGHTER's pose with the head-back overlay added (a copy: the anim's own pose stays).")

(defun-fast beat-pose! (pose beat)
  "*BEAT-POSE* = POSE with the head thrown back (head -35, chest -10, spine -8 degrees of flex) by the envelope of a
beat with BEAT s left of its 0.9 s: up over 0.12 s, held, down over the last 0.3 s. Returns it. 0 B."
  (declare (type f32vec pose) (single-float beat))
  (let* ((out *beat-pose*) (u (- 0.9f0 beat)) (w (f-min (f-clamp (/ u 0.12f0) 0f0 1f0) (f-clamp (/ beat 0.3f0) 0f0 1f0))))
    (declare (type f32vec out) (single-float u w))
    (replace out pose)
    (setf (aref out (* 3 (ji :head))) (+ (aref out (* 3 (ji :head))) (* w -0.61f0))
          (aref out (* 3 (ji :chest))) (+ (aref out (* 3 (ji :chest))) (* w -0.175f0))
          (aref out (* 3 (ji :spine))) (+ (aref out (* 3 (ji :spine))) (* w -0.14f0)))
    out))

(defun-fast grip-step (m on dt)
  "The left fist on the handle (Phase 6): MODEL-LOOKS [0] eases toward 1 while ON (a grip clip plays, the weapon in hand), to
0 otherwise, over 0.1 s of effect time (DT), and GRIP-LEFT! holds it there by that much. 0 B."
  (declare (single-float dt))
  (let* ((lk (model-looks m)) (g (aref lk 0)) (to (if on 1f0 0f0))
         (n (if (> to g) (f-min to (+ g (* 10f0 dt))) (f-max to (- g (* 10f0 dt))))))
    (declare (type f32vec lk) (single-float g to n))
    (setf (aref lk 0) n)
    (when (> n 0f0) (grip-left! (model-joints m) lk))
    nil))

(defun-fast face-accent (m face)
  "FACE (FACE-OF's expression), noting when it changed; outside a cinematic a shout or a hurt face just put on shows its
accent over the head for a few drawings (VFX-FACE-ACCENT: the faces are too small at gameplay distance). Returns FACE."
  (let* ((lk (model-looks m)))
    (declare (type f32vec lk))
    (unless (eq face (model-face-was m)) (setf (model-face-was m) face (aref lk 1) (fx-clock))))
  (unless (or *cine* (eq face :neutral))
    (let* ((lk (model-looks m)) (ms (f->i (* 1000f0 (- (fx-clock) (aref lk 1))))))
      (declare (type f32vec lk))
      (declare (fixnum ms))
      (when (< ms 400) (vfx-face-accent (model-joints m) (if (eq face :shout) 1 2) ms))))
  face)

(defun move-beats (e f m mv x y z yaw)
  "Draw-side looks keyed on a move frame (the sim's on-frame hooks stay as they are): Nadegiri's cut at its S, the
focus lines as Shiranui's charge starts, Kenpachi's SP2 dash leaving an afterimage every 10 f (§4.2 SP2 dash). Each fires
once, on the draw that first sees the frame (MODEL-LAST-SF)."
  (let ((prev (model-last-sf m)) (now (if (and mv (eq (fighter-state f) :move)) (fighter-sf f) -1)))
    (setf (model-last-sf m) now)
    (when (and mv (/= now prev))
      (case (mv-name mv)
        (:ya-nadegiri (when (and (eq (fighter-phase f) :main) (< prev (mv-s mv)) (<= (mv-s mv) now))
                        (vfx-nadegiri x z (fwd-x yaw) (fwd-z yaw))))
        (:ya-shiranui (when (and (eq (fighter-phase f) :hold) (= (fighter-hold f) 2)) (focus-lines 14 x (+ y 1.2) z)))
        (:ya-e-k3 (when (and (eq (fighter-phase f) :main) (< prev (mv-s mv)) (<= (mv-s mv) now))   ; RAKUJITSU: the plaza
                    (let ((ex (+ x (* 2.2 (fwd-x yaw)))) (ez (+ z (* 2.2 (fwd-z yaw)))))           ; takes the setting sun
                      (vfx-ember ex 0.1 ez :dx (fwd-x yaw) :dz (fwd-z yaw) :scale 1.4)
                      (stage-mark :scorch ex ez 0.7))))
        (:ke-charge (when (and (eq (fighter-phase f) :main) (<= (mv-s mv) now) (< now (+ (mv-s mv) (mv-a mv)))
                               (zerop (mod (- now (mv-s mv)) 10)))
                      (start-ghost e)))))))

(defun body-lift (kit b)
  "The drawn height of KIT's :lift for body B: the lift while B is the form's own body (a cinematic that still shows the
form before, e.g. an awakening's first beats, stands on the ground)."
  (let ((h (kit-lift kit))) (if (and (/= h 0) (kit-body kit) (eq b (find-body (kit-body kit)))) h 0.0)))

(defun draw-fighter (e rdt)
  "Pose and queue fighter E: body, weapon (or the planted one), blade look, aura, trail. RDT = this
frame's effect seconds (0 while paused). A Kikon rush module's look (its :look): :flash-step shows only
ink afterimages during the dash, :charge a stronger aura, :leap lifts the drawing (RUSH-LIFT)."
  (let* ((m (model e)) (f (fighter e)) (kit (fighter-kit f)) (b (model-body m)) (p (pos-of e)) (yaw (yaw-of e))
         (mv (and (eq (fighter-state f) :move) (fighter-move f)))
         (look (and mv (eq (mv-kind mv) :kikon) (getf (mv-params mv) :look)))
         (flashing (and (eq look :flash-step) (rush-dashing-p f)))   ; the flash step: afterimages only
         (planted (and mv (mv-planted mv) (eq (fighter-phase f) :main)))
         (sc (draw-scale-of e))                           ; (a cinematic's giant: CINE-SCALE, about his feet)
         (weapon (if (or planted flashing) nil (model-weapon m))) (x (aref p 0))
         (y (+ (aref p 1) (rush-lift f mv) (if (= sc 1f0) (body-lift kit b) (* sc (body-lift kit b))))) (z (aref p 2)))
    (progn (countdown! (model-flash m) rdt)
           (countdown! (model-super m) rdt))
    (let ((pose (if (> (model-hold m) 0) (anim-pose (model-anim m)) (anim-eval (model-anim m)))))
      (pose-fk! (model-joints m) (if (> (model-beat m) 0f0) (beat-pose! pose (model-beat m)) pose)
                x y z yaw (if (= sc 1f0) (body-scale b) (* sc (body-scale b))) (body-hunch b) (body-props b)))
    (let ((c (anim-clip (model-anim m))))                  ; a two-handed clip: the left fist on the handle
      (grip-step m (and weapon c (member (clip-name c) *grip-clips*)) (f32 rdt)))
    (countdown! (model-hold m) rdt)
    (when (> rdt 0)                                       ; the Phase 5 look timers (effect seconds)
      (progn (countdown! (model-face-t m) rdt)
             (countdown! (model-beat m) rdt)
             (countdown! (model-flare m) rdt)))
    (move-beats e f m mv x y z yaw)
    (when (> (model-smear m) 0)
      (let ((v (model-smear-dir m)))
        (smear-joints! (model-joints m) (f32 x) (+ (f32 y) 1f0) (f32 z) (aref v 0) (aref v 1)))
      (when (> rdt 0) (setf (model-smear m) 0f0)))
    (when (and flashing (> rdt 0) (zerop (mod (fighter-hold f) 4))) (start-ghost e))   ; a new afterimage every 4 f
    (draw-ghost e rdt)
    (when (and (>= (model-alpha m) 0.999) (not flashing))   ; a vanishing Hoho body is not drawn: its afterimage is
      (let ((face (face-accent m (face-of e f m mv))))    ; (a form's hidden parts: FACE-HIDE-LIST)
        (draw-body b (model-joints m) x y z yaw :weapon weapon :hide (face-hide-list m face) :face face
                                              :tint (model-tint m)
                                              :rim (if (> (model-super m) 0) *super-rim* (model-rim m))
                                              :flash (if (> (model-flash m) 0) 0.45 0.0)
                                              :alpha (let ((ba (kit-hook kit :body-alpha)))   ; a form drawn see-through
                                                       (if ba (funcall ba e) 1f0))
                                              :shadow (= sc 1f0))
        (unless (= sc 1f0) (draw-shadow x y z (* 1.2 sc (body-hurt-r b))))))   ; (the giant's shadow)
    (let ((h (kit-hook kit :draw))) (when h (funcall h e rdt)))   ; a character's own looks on the posed body (KIT-HOOK)
    (when (and mv (eq (mv-clip mv) :ya-sleeve) (eq (fighter-phase f) :main)   ; SODEBI: the empty left sleeve burns
               (< (- (mv-s mv) 4) (fighter-sf f) (+ (mv-s mv) (mv-a mv) 10)))
      (joint-point! *base* (model-joints m) (ji :lower-arm-l) 0f0 0f0 0f0)
      (joint-point! *tip* (model-joints m) (ji :lower-arm-l) 0f0 -0.42f0 0f0)
      (vfx-blade-fire (aref *base* 0) (aref *base* 1) (aref *base* 2) (aref *tip* 0) (aref *tip* 1) (aref *tip* 2) rdt :power 1.4))
    (when (and planted (model-weapon m))
      (draw-planted-weapon (model-weapon m) (+ x (* 0.7 (fwd-x yaw))) (+ z (* 0.7 (fwd-z yaw))) yaw))
    (when (and weapon (> (model-alpha m) 0.5))
      (body-weapon-tip b weapon (model-joints m) *tip*)
      (body-weapon-base b weapon (model-joints m) *base*)
      (let ((look (kit-blade kit)))
        (case (first look)
          (:fire (vfx-blade-fire (aref *base* 0) (aref *base* 1) (aref *base* 2) (aref *tip* 0) (aref *tip* 1) (aref *tip* 2)
                                 rdt :power (second look)))
          (:embers (vfx-blade-embers (aref *base* 0) (aref *base* 1) (aref *base* 2) (aref *tip* 0) (aref *tip* 1) (aref *tip* 2) rdt))))
      (when (and mv (eq (fighter-phase f) :hold) (not (member :stance (mv-flags mv))))
        (let ((ch (kit-hook kit :charge)))                 ; a form's own charge look replaces the fire one
          (if ch
              (funcall ch e rdt)
              (vfx-charge (aref *tip* 0) (aref *tip* 1) (aref *tip* 2)
                          (min 1.0 (/ (fighter-hold f) (float (second (mv-hold mv))))) rdt))))
      (let* ((tr (blade-points (blade e))))
        (declare (type f32vec tr))
        (if (and mv (eq (fighter-phase f) :main) (>= (fighter-sf f) (- (mv-s mv) 4)) (< (fighter-sf f) (+ (mv-s mv) (mv-a mv) 3)))
            (trail-push tr (aref *base* 0) (aref *base* 1) (aref *base* 2) (aref *tip* 0) (aref *tip* 1) (aref *tip* 2))
            (trail-decay tr))
        (vfx-smear tr (blade-smear (blade e)) (case (first (kit-blade kit)) (:fire 0) ((:embers :charcoal) 2) (t 1)))))
    ;; auras: the form's, EVOLUTION ready, the Breaker (brightens over the strike startup), the Kikon rush
    (let ((age (fx-clock)))
      (unless (or flashing (<= (model-alpha m) 0f0) (eql e *aura-off*))   ; the form's aura, crossfaded; none round a body
                                                          ; turned to ash (Tenchi Kaijin) or before a cinematic bursts it on
        (draw-aura f (kit-aura kit) x y z (* 1.1 (body-hurt-h b)) age rdt
                   (cond ((> (model-flare m) 0f0) (+ 1.0 (* 2.0 (model-flare m))))   ; West's garb flaring (a warded hit, SHONETSU)
                         ((and (eq look :charge) (not (eq (fighter-phase f) :main))) 1.5)
                         ((and mv (eq (mv-kind mv) :kikon) (eq (kit-aura kit) :oni)) 0.15)   ; the oni pillar smoulders in
                         (t 1.0))))                                                           ; his rush (its trail is the tell)
      (if (plusp (fighter-frost f))                        ; frosted (Rukia's ice): the crust at his feet
          (vfx-frost x z (/ (fighter-frost f) 60.0) rdt)
          (when (and (eq (fighter-state f) :stun) (eq (fighter-phase f) :bind))   ; bound by South: ash drifting at the feet
            (vfx-aura x y z (body-hurt-h b) :bound age rdt)))
      (when (gauges-evolution (gauges e)) (vfx-aura x y z (body-hurt-h b) :evolution age rdt :rgb *evolution-rgb* :k 0.5))
      (let ((bm (gauges-burst (gauges e))))              ; a running burst: its colour (docs/duel/DUEL_DESIGN.md "Burst modes")
        (when (and bm (> (model-alpha m) 0f0) (not (eq (fighter-state f) :cine)))
          (vfx-aura x y z (body-hurt-h b) (case bm (:white :burst-white) (:blue :burst-blue) (t :burst-orange)) age rdt))
        (when (and (not bm) (plusp (gauges-awake-regen (gauges e))) (> (model-alpha m) 0f0) (not (eq (fighter-state f) :cine)))
          (vfx-aura x y z (body-hurt-h b) :burst-white age rdt :k 0.6)))   ; the awakening's regen: a fainter white
      (when (and mv (eq (mv-kind mv) :breaker))            ; the owner's colour over ink (§4 mapping)
        (let ((bk (case (first (kit-blade kit)) (:fire :breaker-fire) ((:embers :charcoal) :breaker-ember) (t :breaker))))
          (unless (eq (fighter-phase f) :main)
            (vfx-aura x y z (body-hurt-h b) bk age rdt :k (if (eq (fighter-phase f) :dash) 1.0 0.5))
            (vfx-breaker-ring x z age))
          (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))
            (vfx-aura x y z (body-hurt-h b) bk age rdt :k (+ 1.0 (/ (fighter-sf f) (float (mv-s mv))))))))
      (when (and mv (eq (mv-kind mv) :kikon) (eq (fighter-state f) :move) (not flashing)   ; the Kikon rush: BLOOD tongues + ring
                 (or (not (eq (fighter-phase f) :main)) (< (fighter-sf f) (mv-s mv))))
        (vfx-aura x y z (body-hurt-h b) :kikon age rdt :k 1.0)))
    (unless (and mv (eq (mv-kind mv) :breaker)) (stop-hum e))))

(defun-fast %aura-ms (i)
  "Milliseconds of fx clock since side I's aura changed (a fixnum: no boxed float in DRAW-AURA's steady state)."
  (declare (fixnum i))
  (min 100000 (f->i (* 1000f0 (- (fx-clock) (aref (the f32vec *aura-t*) i))))))

(defun draw-aura (f aura x y z h age rdt k)
  "Fighter F's body AURA (a VFX-AURA kind or NIL) at his feet, HEIGHT H, presence K. When it changes (a stance
switch) the old one dies down over 350 ms while the new one flares up (grows 35 % and
settles over 300 ms): e.g. the West garb's flames flaring on. Cosmetic, fx clock (AGE:
the caller's reading of it); once settled it passes H and K through as they came (no float math per frame)."
  (let ((i (fighter-side f)))
    (unless (eq aura (svref *aura-now* i))
      (setf (svref *aura-was* i) (svref *aura-now* i) (svref *aura-now* i) aura (aref *aura-t* i) (fx-clock)))
    (let ((ms (%aura-ms i)) (was (svref *aura-was* i)))
      (when (and was (< ms 350))
        (vfx-aura x y z h was age rdt :k (* k (- 1.0 (/ ms 350.0)))))
      (when aura
        (if (>= ms 300)
            (vfx-aura x y z h aura age rdt :k k)
            (vfx-aura x y z (* h (+ 1.0 (* 0.35 (- 1.0 (/ ms 300.0))))) aura age rdt :k (* k (min 1.0 (+ 0.2 (/ ms 120.0))))))))))

(defvar *form-grade* nil "The form grade preset shown now (:spot) or NIL.")

(defun form-grade ()
  "A form's world grade (kit :GRADE): Bankai's :SPOT keeps the whole world grey except the ember hue (the composite's
spot-keep mode 4, docs/style/STYLE_STORM_DESIGN.md §3.6) while the form is on. An impact frame takes the composite over for its frames
(IMPACT-FRAME); the form's grade comes back when it ends. Changes the mode only when needed."
  (flet ((spot-p (e) (and (entity-alive-p e) (eq (kit-grade (kit-of e)) :spot))))
    (let* ((want (and (or (spot-p *p1*) (spot-p *p2*)) :spot))
           (mode (if want 4 0)))
      (when (and (<= (aref *screen-fx* 0) 0f0) (or (/= *grade-impact* mode) (not (eq want *form-grade*))))
        (setf *form-grade* want)
        (if want (impact-frame want 0) (grade-impact 0))))))

(defun draw-scene (rdt)
  "Queue the 3D scene. RDT = this frame's effect seconds (0 while paused: nothing moves, no particle is born)."
  (unless (or (svref *no-draw* 2) *card*) (stage-draw rdt))   ; a card beat (cinema.lisp CARD) hides the stage
  (unless *cine* (setf *grade-desat* 0.0) (form-grade))   ; a cinematic's script owns the grade
  (do-sides (e)
    (when (entity-alive-p e)
      (unless (or (svref *no-draw* 1) (and *card-only* (not (eq e *card-only*)))) (draw-fighter e rdt))))
  (unless (svref *no-draw* 3) (hazard-draw rdt) (cine-draw))
  (when *hitboxes* (draw-hitboxes))
  (stamps-draw (f32 rdt))
  (when (and *impact-next* (<= (aref *screen-fx* 0) 0f0))   ; a queued impact frame (NOMIHOSE: the manga page)
    (impact-frame (car *impact-next*) (cdr *impact-next*)) (setf *impact-next* nil))
  (when (> (aref *burst-flag* 0) 0)                     ; a Burst ring fired: its beat, drawn this frame
    (setf (aref *burst-flag* 0) 0f0) (impact-frame :negative 1) (back-rim 3))
  (fx-update (f32 rdt))
  (fx-draw-particles)
  (fx-rings-update (f32 rdt))
  (lights-flush))

(defun fx-frozen-p ()
  "Effect time stops this frame: paused, a held beat (FREEZE), or a debug-held cinematic at its hold frame (stills)."
  (or *paused* (> (aref *screen-fx* 6) 0f0) (cine-held-p)))

(defun cine-held-p () "A debug-held cinematic stands at its hold frame." (and *cine* (cine-hold *cine*) (>= (cine-cf *cine*) (cine-hold *cine*))))
