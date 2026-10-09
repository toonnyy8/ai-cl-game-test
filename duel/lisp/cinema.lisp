;;;; cinema.lisp — SOUL DUEL's cinematics on the engine's director (engine/lisp/cine.lisp: DEFCINE
;;;; with AT / DURING, START-CINE, CINE-STEP ...; design-v1 §12, critique-tech §13). The rules decide,
;;;; cinematics present: by the time a script starts, the Konpaku / Reishi / form it shows are already
;;;; settled, so skipping one (Start / Esc, debug 2100) loses nothing.
;;;; While *CINE* is set, main.lisp runs CINE-STEP instead of the sim systems (fighters, hazards,
;;;; gauges and the match timer are frozen). This file holds the duel's side of it: the director's
;;;; hooks (actors enter / leave the :cine state, their animations advance, the look is restored:
;;;; STAGE-ENV, caption, UI flash), the shot helpers on fighters (SHOT-ON, SHOT-PAIR), script helpers
;;;; (captions, flashes, clips), the cinematic language of docs/style/STYLE_STORM_DESIGN.md §5 (black / white cards,
;;;; lenses, dutch angles, silhouettes, pose holds with the effects frozen, impact frames, silence, ink splashes)
;;;; and the generic scripts (soul break, intro, K.O., time); the characters' scripts live in yama.lisp / ken.lisp.
;;;; Every look here is cosmetic: only AT events that move the actors (FACE-EACH-OTHER) touch the sim state.
(in-package :duel)

(declaim (type f32vec *ui-flash*))
(defvar *ui-flash* (make-f32 5) "Full-screen UI flash: r g b alpha, fade per second (hud.lisp).")
(defvar *card* nil "The beat's background card: :black, :white or NIL (the stage; CARD).")
(defvar *card-only* nil "The one actor drawn on the card (CARD's ONLY), or NIL = both.")
(defvar *cine-grade* nil "The running cinematic's base grade (an *IMPACT-PRESETS* key, e.g. :spot) or NIL (CINE-GRADE).")
(declaim (single-float *dutch*))
(defvar *dutch* 0f0 "The shot's roll, degrees (LENS; camera.lisp DUEL-CAMERA applies it to a cinematic shot).")
(declaim (single-float *lens-fov*))
(defvar *lens-fov* (f32 (deg 60)) "The shot's LENS (radians) as the script set it: a portrait screen widens it (camera.lisp %PORTRAIT-DOLLY).")
(defvar *cine-close* nil "The shot is a close-up of one fighter (SHOT-ON within *PT-CLOSE-SHOT*): a portrait screen keeps its
lens, no dolly-back (camera.lisp %PORTRAIT-DOLLY; the user's decision 2026-09-28).")
(defparameter *pt-close-shot* 5.0 "Portrait: a SHOT-ON at most this many metres from its fighter is a close-up.")
(defvar *cine-subject* nil "The fighter the current SHOT-ON frames (NIL: a SHOT-PAIR): camera.lisp %KEEP-SUBJECT keeps his
body in the frame whatever the script's aim offsets and the clip's root motion do (docs/duel/DUEL_KEN_BANKAI.md §1.3).")
(defvar *caption* nil "The running cinematic's brush title (a BCAP, brush.lisp), shown until it ends (hud.lisp).")
(defvar *caption-out* nil "The title of a cinematic that just ended, slicing out over what follows (hud.lisp; Phase 6).")
(defvar *aura-off* nil "An actor whose form aura is not drawn (a cinematic's shots before it bursts on), or NIL (CINE-END).")
(defvar *draw-scale-e* nil "A cinematic actor drawn larger or smaller (CINE-SCALE: a look, the sim never reads it), or NIL.")
(declaim (single-float *draw-scale*))
(defvar *draw-scale* 1f0 "... and its scale: his rig, lift and shadow in DRAW-FIGHTER, his kit's own looks (LILLE-DRAW).")
(declaim (single-float *cine-time-scale*))
(defvar *cine-time-scale* 1f0
  "A cinematic's slow motion (CINE-SLOW): its actors' clips and the effect time (the fx clock, particles, shake, the
camera's easing) run at this rate; the script's frames do not (a look: the sim never reads it). CINE-END resets it.")
(defmacro draw-scale-of (e)
  "The drawn scale of fighter E: *DRAW-SCALE* while it is the scaled cinematic actor, else 1 (a single-float; 0 B)."
  `(if (eql ,e *draw-scale-e*) *draw-scale* 1f0))

;;; ---------------------------------------------------------------- the director's hooks
(defun cine-begin (name a v)
  "A cinematic starts: no caption yet, the actors leave their sim states (standing still)."
  (setf *caption* nil *caption-out* nil *lens-fov* (f32 (deg 60)) *cine-close* nil *cine-subject* nil)
  (dolist (e (list a v))
    (when (fighter e)
      (setf (fighter-state (fighter e)) :cine (fighter-sf (fighter e)) 0 (motion-kb-left (motion e)) 0)
      (halt! e)))
  (clog "cine ~a" name))

(defun cine-actor-step (e)
  "One fixed step of a cinematic actor: his animation advances."
  (let ((m (model e))) (when m (anim-advance (model-anim m) (* +step+ *cine-time-scale*)))))   ; (CINE-SLOW)

(declaim (type f32vec *cine-placed*))
(defvar *cine-placed* (make-f32 4) "CINE-PLACE: A's place before it (x y z) and [3] 1 while it is to be given back.")
(defvar *cine-placed-e* nil "CINE-PLACE's actor.")
(defun cine-end (c)
  "A cinematic ended (C, or NIL when none ran): restore the stage look, clear the caption and the
flash, give the actors back (the presses buffered during it forgotten: mashing through a
cinematic fires nothing)."
  (setf *caption-out* (and *caption* (bcap-exit *caption*))   ; a title still up slices out over what follows
        *caption* nil *card* nil *card-only* nil *cine-grade* nil *dutch* 0f0 (camera-fov *camera*) (f32 (deg 60))
        *aura-off* nil *cine-subject* nil *draw-scale-e* nil *draw-scale* 1f0   ; (played, skipped or aborted)
        *cine-time-scale* 1f0)
  (v3-set! (camera-up *camera*) 0f0 1f0 0f0)
  (when (and *cine-placed-e* (> (aref *cine-placed* 3) 0f0))   ; CINE-PLACE: A back where he stood
    (let ((p (pos-of *cine-placed-e*)) (s *cine-placed*))
      (setf (aref p 0) (aref s 0) (aref p 1) (aref s 1) (aref p 2) (aref s 2) (aref s 3) 0f0)))
  (setf *cine-placed-e* nil)
  (unsilhouette)
  (fill *ui-flash* 0f0)
  (screen-fx-clear)
  (stage-env)
  (when c
    (dolist (e (list (cine-a c) (cine-v c)))
      (when (fighter e) (refresh-look e) (vpad-flush! (pilot-vpad (pilot e)))))))

(setf *cine-begin-hook* #'cine-begin *cine-actor-hook* #'cine-actor-step *cine-end-hook* #'cine-end)

;;; ---------------------------------------------------------------- script helpers
(defun shot-on (e ang dist h &key (look 1.1) (ahead 0.0) (off 0.0))
  "Camera at ANG degrees around fighter E's facing (0 = in front of him, 90 = his left), DIST metres
away, H high, looking at his body LOOK metres up, AHEAD metres in front of him. OFF > 0 aims the camera
OFF metres to the shot's left of him, so he stands in the right part of the frame (< 0: the left part), leaving
the other third to a caption."
  (setf *cine-close* (<= dist *pt-close-shot*) *cine-subject* e)
  (when (and (/= off 0) (portrait-p))                             ; portrait (P2): the subject nearer the middle of the tall
    (setf off (* (if *cine-close* 0.25 0.5) off)))               ; frame (a close-up keeps the lens: nearer still)
  (let* ((p (pos-of e)) (yaw (+ (yaw-of e) (deg ang)))
         (fx (fwd-x (yaw-of e))) (fz (fwd-z (yaw-of e)))
         (tx (- (+ (aref p 0) (* ahead fx)) (* off (fwd-z yaw)))) (tz (+ (aref p 2) (* ahead fz) (* off (fwd-x yaw)))))
    (cine-cam (+ tx (* dist (fwd-x yaw))) h (+ tz (* dist (fwd-z yaw))) tx look tz)))

(defun shot-pair (a v side dist h)
  "Both fighters from the SIDE (+1 / -1) of the A->V line, DIST metres from their midpoint."
  (setf *cine-close* nil *cine-subject* nil)
  (let* ((p (pos-of a)) (q (pos-of v)) (mx (* 0.5 (+ (aref p 0) (aref q 0)))) (mz (* 0.5 (+ (aref p 2) (aref q 2))))
         (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (d (max 0.01 (hypot dx dz))))
    (cine-cam (+ mx (* side dist (/ (- dz) d))) h (+ mz (* side dist (/ dx d))) mx 1.1 mz)))

(defun face-each-other (a v &optional (gap nil))
  "Turn A and V to face each other; with GAP, first put A GAP metres in front of V (a flash step)."
  (let ((p (pos-of a)) (q (pos-of v)))
    (when gap
      (let* ((dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2))) (d (max 0.01 (hypot dx dz))))
        (setf (aref p 0) (+ (aref q 0) (* gap (/ dx d))) (aref p 2) (+ (aref q 2) (* gap (/ dz d))) (aref p 1) 0f0)))
    (setf (transform-yaw (transform a)) (f32 (dir-yaw (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2))))
          (transform-yaw (transform v)) (f32 (dir-yaw (- (aref p 0) (aref q 0)) (- (aref p 2) (aref q 2)))))
    (setf (aref q 1) 0f0)))

(defun cine-place (a v gap)
  "Stage the shot at a set distance: put A GAP metres in front of V (FACE-EACH-OTHER's flash step) for the cinematic's
camera, and give A its place back when it ends (CINE-END, however it ends): a look only, the match goes on from where
they stood (the user, 2026-10-08: 「應該進入毀魂技過場動畫時就要先調整演員的位置才對」). Their facings are FACE-EACH-OTHER's
either way (the same line)."
  (let ((p (pos-of a)) (s *cine-placed*))
    (setf (aref s 0) (aref p 0) (aref s 1) (aref p 1) (aref s 2) (aref p 2) (aref s 3) 1f0 *cine-placed-e* a)
    (face-each-other a v gap)))

(defun cine-clip (e clip &key (blend 3) (speed 1.0) (time 0.0))
  "Play CLIP on actor E (falls back to the stance with a log line if the art lacks it)."
  (play-clip e clip :blend blend :speed speed :time time))

(defun cine-scale (e s)
  "Draw actor E S times his size from now on, about his feet (his place kept), until CINE-SCALE again or the cinematic's
end (CINE-END clears it, however it ends). A look: the sim never reads it (decision 56, the Jilliel Kikon's giant)."
  (if (= s 1) (setf *draw-scale-e* nil *draw-scale* 1f0) (setf *draw-scale-e* e *draw-scale* (f32 s))))

(defun cine-slow (k)
  "Slow motion from now on: the actors' clips and the effects at K x speed (1 = back to speed), until CINE-SLOW again or
the cinematic's end (decision 56's Kikon: its first shots' hits)."
  (setf *cine-time-scale* (f32 k)))

(defun ui-flash (r g b a &optional (fade 3.0))
  "A full-screen flash of colour (r g b), alpha A, fading at FADE per second."
  (let ((f *ui-flash*)) (setf (aref f 0) (f32 r) (aref f 1) (f32 g) (aref f 2) (f32 b) (aref f 3) (f32 a) (aref f 4) (f32 fade))))

(defun caption (kanji &rest keys)
  "The cinematic's brush title, stamped in now (brush.lisp MAKE-BCAP keys: :kanji2 :reading :sub :mark :side :ink
:hanko): stays up until the next caption, CAPTION-EXIT or the end (it then slices out over what follows)."
  (setf *caption* (apply #'make-bcap kanji :layout :cine keys)))

(defun caption-exit ()
  "The title slices out now (Phase 6, §5: a brush cut through the column, the halves sliding apart, 0.3 s)."
  (when *caption* (bcap-exit *caption*)))

(defun actor-point (e up)
  "X Y Z (values) of fighter E's body, UP metres above the feet."
  (let ((p (pos-of e))) (values (aref p 0) (+ (aref p 1) up) (aref p 2))))

(defun cine-shatter (v n &key (up 1.1) (dy 0.0))
  "The Konpaku shatter's look on fighter V (VFX-KONPAKU-SHATTER of N souls at UP metres above his feet, DY higher); the
beat's sound and shake stay at the call site."
  (multiple-value-bind (x y z) (actor-point v up)
    (vfx-konpaku-shatter x (if (= dy 0.0) y (+ y dy)) z n)))

(defmacro push-in-on (a v from d0 dd h0 dh &optional (len 22))
  "The held push-in before a finishing blow, inside DEFCINE: both held LEN frames in silence under a 70 degree lens, while
the shot on V closes from D0 metres / H0 high by DD / DH (U runs 0..1 across the beat), FROM to FROM + LEN."
  `(progn (at ,from (hold-both ,a ,v ,len) (silence ,len) (lens 70))
          (during (,from ,(+ from len)) (shot-on ,v 150 (- ,d0 (* ,dd u)) (+ ,h0 (* ,dh u)) :look 1.4))))

;;; ---------------------------------------------------------------- screen punctuation
;;; Impact frames (the engine's *GRADE-IMPACT* composite modes), focus lines, the Burst's back-rim and
;;; silence beats, each for a number of 60 Hz frames of effect time (paused = frozen). A request made
;;; during a frame's steps is drawn by that frame at least: SCREEN-FX-UPDATE runs down the previous
;;; frame's time at the start of the next one (main.lisp GAME-FRAME).
(declaim (type f32vec *screen-fx* *fl-scr*))
(defvar *fl-scr* (make-f32 3) "FOCUS-LINES' projected centre.")
(defvar *screen-fx* (make-f32 8)
  "Seconds left: [0] impact frame [1] focus lines [2] silence [3] back-rim; [4 5] the focus lines' centre (window
px; < 0 = the screen centre); [6] effects frozen (FREEZE); [7] the impact splash (IMPACT-SPLASH).")
(defvar *splash-args* nil "The impact splash's UI-INK-SPLASH arguments (cx cy r seed), boxed once when it is set.")
(defparameter *impact-presets*
  '((:negative 1)
    (:two-tone 2 :threshold 0.4)                                            ; white / ink
    (:ink 2 :threshold 0.4 :ink (1 1 1) :paper (0.031 0.031 0.047))         ; ink / white (on a white card)
    (:red 2 :threshold 0.4 :paper (0.816 0.063 0.11))                       ; red / ink
    (:fire 2 :threshold 0.4 :paper (1.0 0.353 0.118))                       ; fire / ink
    (:manga 3 :threshold 0.4 :keep-sat 0.45)                                ; two-tone, the spot colour kept
    (:spot 4 :keep-sat 0.45 :keep-hue 10.0 :keep-hue-2 48.0))               ; grey but the ember hue (Bankai) and
                                                                            ; Kenpachi's REIATSU yellow (user review 2)
  "IMPACT-FRAME kinds -> GRADE-IMPACT mode and parameters (docs/style/STYLE_STORM_DESIGN.md §3.6 presets).")

(defvar *impact-next* nil "(kind . frames): an impact frame to start when the running one ends (main.lisp; feedback :rung).")

(defun impact-frame (kind frames)
  "Screen punctuation KIND (a key of *IMPACT-PRESETS*: :negative, :two-tone, :ink, :red, :fire, :manga,
:spot) for FRAMES 60 Hz frames (at least one drawn frame). A later request replaces a running one; when it
ends, the cinematic's base grade (CINE-GRADE) comes back."
  (apply #'grade-impact (rest (or (assoc kind *impact-presets*) (error "no impact preset ~s" kind))))
  (setf (aref *screen-fx* 0) (f32 (/ frames 60.0))))

(defun cine-grade (kind)
  "The cinematic's base grade from now on (KIND a preset key, or NIL = none), under its impact frames."
  (setf *cine-grade* kind)
  (when (<= (aref *screen-fx* 0) 0f0)
    (if kind (impact-frame kind 0) (grade-impact 0))))

(defun card (kind &optional only)
  "A card beat (§5, Kubo's negative space as an anime background drop): KIND :black or :white fills the frame
behind the fighters and effects (the stage is not drawn; sky, horizon and fog take the card's value, no moon, no
vignette), NIL brings the stage back. ONLY: the one actor drawn on it (the other one would crowd the shot).
Yamamoto (white haori) goes on black, Kenpachi (black robe) on white."
  (setf *card* kind *card-only* (and kind only))
  (when kind (fx-clear))                                 ; the card is empty: no flame, ash or spark left over
  (if kind
      (let ((e *env*) (c (if (eq kind :white) 0.955f0 0.031f0)))
        (v3-set! (env-sky-top e) c c c) (v3-set! (env-fog-color e) c c c) (v3-set! (env-moon-color e) c c c)
        (setf (env-fog-density e) 0.0 (env-vignette e) 0.0 (env-sun-glow e) 0.0))
      (stage-env)))

(defun lens (fov &optional (roll 0))
  "The shot's vertical field of view FOV (degrees: 38 for a stand-off, 85-95 close and low for a thrust or a
reveal: forced perspective) and its dutch ROLL (degrees). The end of the cinematic restores 60 and 0."
  (setf (camera-fov *camera*) (f32 (deg fov)) *lens-fov* (camera-fov *camera*) *dutch* (f32 roll)))

(defun freeze (frames)
  "A held beat: the effects stop (particles, the fx clock's drawings, shake) for FRAMES 60 Hz frames of real
time; pair it with HOLD-POSE on the actors."
  (setf (aref *screen-fx* 6) (f32 (/ frames 60.0))))

(defun hold-both (a v frames)
  "Hold both actors' drawn poses and freeze the effects for FRAMES (§5's hold beat)."
  (hold-pose a frames) (hold-pose v frames) (freeze frames))

(defun impact-splash (x y z frames &optional (r 0.1))
  "An ink splash (black) at world point (X Y Z) for FRAMES, R x the screen height: the Kikon impact still (§5)."
  (let ((v *fl-scr*))
    (when (world-to-screen v (f32 x) (f32 y) (f32 z))
      (setf *splash-args* (list (aref v 0) (aref v 1) (f32 (* r (window-height))) (f32 (mod (* 13.7 x) 50.0)))
            (aref *screen-fx* 7) (f32 (/ frames 60.0))))))

(defvar *silhouette* nil "(actor . tint) while an actor is drawn as a black silhouette (SILHOUETTE-BLACK).")
(defun silhouette-black (e)
  "Draw actor E as a solid black silhouette (a near-black tint on body and ink) until UNSILHOUETTE: the Bankai
reveal on a white card. The effects (the ember line) keep their colour."
  (unsilhouette)
  (setf *silhouette* (cons e (model-tint (model e))) (model-tint (model e)) '(0.06 0.06 0.075)))
(defun unsilhouette ()
  (when *silhouette* (setf (model-tint (model (car *silhouette*))) (cdr *silhouette*) *silhouette* nil)))

(defun focus-lines (frames &optional x y z)
  "Ink focus lines for FRAMES 60 Hz frames, converging on world point (X Y Z) (default the screen centre)."
  (let ((f *screen-fx*) (v *fl-scr*))
    (setf (aref f 1) (f32 (/ frames 60.0)) (aref f 4) -1f0 (aref f 5) -1f0)
    (when (and x (world-to-screen v (f32 x) (f32 y) (f32 z)))
      (setf (aref f 4) (aref v 0) (aref f 5) (aref v 1)))))

(defun silence (frames)
  "A silence beat (TYBW: the sound drops out before the impact): the music down to 0.1 of its level and
the sfx bus muted for FRAMES 60 Hz frames (no engine change: the mixer's bus gains)."
  (setf (aref *screen-fx* 2) (f32 (/ frames 60.0)))
  (set-music-volume 0.055)
  (set-sfx-volume 0.0))
(defun silence-end ()
  "The silence beat is over: the music back to its level, the sfx bus on."
  (set-music-volume 0.55) (set-sfx-volume 1.0))

(defun back-rim (frames &optional (r 0.91) (g 0.93) (b 0.96))
  "Both fighters silhouetted (all in their shadow tone) with a hard back-rim (R G B, default white) for FRAMES:
the Burst, a cinematic's silhouette shot (§5: white in the mono world, the owner's spot colour when awakened)."
  (setf (aref *screen-fx* 3) (f32 (/ frames 60.0)) (env-toon-threshold *env*) 1.5)
  (v3-set! (env-cin-rim *env*) (f32 r) (f32 g) (f32 b)))
(defun back-rim-end ()
  "The back-rim shot is over: the toon threshold and the cinematic rim back to normal."
  (setf (env-toon-threshold *env*) 0.5) (v3-set! (env-cin-rim *env*) 0f0 0f0 0f0))

(defun screen-fx-update (dt)
  "Run the screen punctuation down by DT effect seconds (0 while paused); end what ran out."
  (let ((f *screen-fx*))
    (flet ((run (i) (let ((was (aref f i))) (setf (aref f i) (f32 (max 0.0 (- was dt)))) (and (> was 0) (<= (aref f i) 0)))))
      (when (run 0) (if *cine-grade* (impact-frame *cine-grade* 0) (grade-impact 0)))
      (run 1) (run 6) (run 7)
      (when (run 2) (silence-end))
      (when (run 3) (back-rim-end)))))

(defun screen-fx-clear ()
  "End every screen punctuation now (a new match, the end of a cinematic)."
  (let ((f *screen-fx*))
    (when (> (aref f 2) 0) (silence-end))
    (fill f 0f0) (grade-impact 0) (back-rim-end)))

(defun draw-screen-fx (w h)
  "The UI part of the punctuation: focus lines (ink, reshuffled every drawing on twos), the impact splash."
  (let ((f *screen-fx*))
    (declare (type f32vec f))
    (when (and (> (aref f 7) 0f0) *splash-args*)
      (let ((a *splash-args*))
        (ui-ink-splash (first a) (second a) (third a) (fourth a) '(0.03 0.03 0.047 1) 1)))
    (when (> (aref f 1) 0f0)
      (let ((cx (if (< (aref f 4) 0) (* 0.5 w) (aref f 4))) (cy (if (< (aref f 5) 0) (* 0.5 h) (aref f 5))))
        (ui-focus-lines (f32 cx) (f32 cy) 56 (f32 (* 0.16 h)) (f32 (* 1.4 (max w h))) '(0.03 0.03 0.05 0.92)
                        (f->i (* 12f0 (fx-clock))))))))

;;; ---------------------------------------------------------------- generic scripts
;;; The grammar of every script (docs/style/STYLE_STORM_DESIGN.md §5): beat 0 (the gameplay shot frozen: poses held, effects
;;; frozen, a 2 f negative), a wind-up (a card, a low dutch shot, the brush stamp, silence), cuts on the action (no
;;; orbits but one), a held beat before the impact (silence), the impact (a negative, then a manga page), the aftermath.
(defun cine-dt () "This frame's effect seconds for a cinematic's DURING effects: 0 while the effects are frozen." (if (fx-frozen-p) 0.0 (frame-dt)))

(defun brush-name (e)
  "Values: fighter E's name in kanji and its reading (brush.lisp *BRUSH-NAMES*)."
  (values-list (rest (assoc (kit-character (kit-of e)) *brush-names*))))

(defcine soul-break-cine (a v :len 96 :hold 44)
  "Reishi hit 0 (Konpaku already settled): beat 0; the victim crumples in a low shot under the 魂 / SOUL BREAK stamp;
a held close wide-angle beat in silence; his souls shatter: a negative, then a manga page (the red soul flame stays);
a wide."
  (at 0 (face-each-other a v)
      (cine-clip v :sh-crumple :blend 2) (cine-clip a (kit-stance (kit-of a)) :blend 6)
      (hold-both a v 6) (impact-frame :negative 2) (play-sfx :kikon-slash))
  (at 6 (shot-on v 60 3.4 0.8 :look 0.9 :off -0.7) (lens 50 -6)
      (caption "魂" :reading "SOUL BREAK" :side 1))
  (at 28 (hold-both a v 12) (silence 12) (shot-on v 60 1.9 0.45 :look 0.9) (lens 82))
  (at 40 (cine-shatter v 4)
      (impact-frame :negative 2) (lens 55)
      (play-sfx :konpaku-shatter) (shake 0.15 0.3))
  (at 42 (impact-frame :manga 10))
  (during (0 96) (let ((p (pos-of v))) (vfx-soul-flame (aref p 0) 2.2 (aref p 2) (/ cf 60.0))))
  (at 60 (shot-pair a v 1 7.0 2.2) (lens 50) (caption-exit)))

(defcine intro-cine (a v :len 300 :hold 200)
  "Match intro: A (P1) then V (P2) play their intro clips beside their names in vertical brush kanji (the reading and
the intro line under it), a negative cut between them; then the pair and FIGHT!"
  (at 0 (face-each-other a v)
      (dolist (e (list a v)) (cine-clip e (kit-stance (kit-of e)) :blend 0))
      (cine-clip a (or (kit-intro (kit-of a)) (kit-stance (kit-of a))) :blend 0)
      (shot-on a 25 3.6 1.5 :look 1.2 :off -0.7) (intro-weapon a 0)
      (multiple-value-bind (kanji reading) (brush-name a)
        (caption kanji :reading reading :sub (kit-intro-callout (kit-of a)) :side 1)))
  (during (0 120) (shot-on a (+ 25 (* 20 u)) (- 3.6 (* 0.6 u)) 1.5 :look 1.2 :off -0.7))
  (at 120 (cine-clip v (or (kit-intro (kit-of v)) (kit-stance (kit-of v))) :blend 0) (impact-frame :negative 2)
      (multiple-value-bind (kanji reading) (brush-name v)
        (caption kanji :reading reading :sub (kit-intro-callout (kit-of v)) :side 0)))
  (during (120 240) (shot-on v (- -25 (* 20 u)) (- 3.6 (* 0.6 u)) 1.5 :look 1.2 :off 0.7))
  (during (240 300) (shot-pair a v (camera-side) (+ 6.0 (* 2.0 u)) 2.4))
  (when step-p (intro-weapon a cf) (intro-weapon v (- cf 120)))
  (at 240 (caption-exit))
  (at 250 (announce "FIGHT!" :color '(1 0.85 0.3 1) :secs 1.0) (play-sfx :fight)))

(defun intro-weapon (e frame)
  "The intro prop in hand until the kit's hand-off frame (Yamamoto's cane), then the weapon."
  (let ((iw (kit-intro-weapon (kit-of e))) (m (model e)))
    (setf (model-weapon m) (if (and iw (<= 0 frame) (< frame (second iw))) (first iw) (kit-weapon (kit-of e))))))

(defcine ko-cine (a v :len 150 :hold 40)
  "K.O.: a white / ink two-tone frame on the last hit; the winner held 20 f in a low shot under the 決着 / K.O. stamp;
then the one slow orbit round the kneeling loser while rain begins (the 勝 stamp waits on the results screen)."
  (at 0 (face-each-other a v)
      (cine-clip v :sh-lose :blend 8) (cine-clip a (or (kit-win (kit-of a)) (kit-stance (kit-of a))) :blend 8)
      (impact-frame :two-tone 3) (hold-pose a 20) (play-sfx :ko)
      (shot-on a 30 3.0 0.8 :look 1.3 :off -0.8) (lens 42)
      (caption "決着" :reading "K.O." :side 1))
  (at 20 (lens 55))
  (during (20 150) (shot-on v (+ 40 (* 50 u)) (- 5.0 (* 1.2 u)) (+ 1.0 (* 0.6 u)) :look 0.8)
    (let ((p (pos-of v)))                                  ; the rain begins as the fight ends (Phase 6, §6)
      (vfx-rain (aref p 0) (aref p 2) (/ (- cf 20) 60.0) (min 0.9 (/ (- cf 20) 20.0))))))

(defcine time-cine (a v :len 120 :hold 60)
  "TIME: the timer ran out; A won on Konpaku / Reishi (or a draw). 時間切れ."
  (at 0 (caption "時間切れ" :reading "TIME" :side 0) (impact-frame :negative 2) (play-sfx :ko))
  (during (0 120) (shot-pair a v (camera-side a) (+ 8.0 u) 2.6)))
