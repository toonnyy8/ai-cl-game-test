;;;; cinema.lisp — SOUL DUEL's cinematics on the engine's director (engine/lisp/cine.lisp: DEFCINE
;;;; with AT / DURING, START-CINE, CINE-STEP ...; design-v1 §12, critique-tech §13). The rules decide,
;;;; cinematics present: by the time a script starts, the Konpaku / Reishi / form it shows are already
;;;; settled, so skipping one (Start / Esc, debug 2100) loses nothing.
;;;; While *CINE* is set, main.lisp runs CINE-STEP instead of the sim systems (fighters, hazards,
;;;; gauges and the match timer are frozen). This file holds the duel's side of it: the director's
;;;; hooks (actors enter / leave the :cine state, their animations advance, the look is restored:
;;;; STAGE-ENV, caption, UI flash), the shot helpers on fighters (SHOT-ON, SHOT-PAIR), script helpers
;;;; (captions, flashes, clips) and the generic scripts (soul break, intro, K.O., time); the
;;;; characters' scripts live in yama.lisp / ken.lisp.
(in-package :duel)

(declaim (type f32vec *ui-flash*))
(defvar *ui-flash* (make-f32 5) "Full-screen UI flash: r g b alpha, fade per second (hud.lisp).")
(defvar *caption* nil "The running cinematic's typography: (text sub color kanji), shown until it ends (hud.lisp).")

;;; ---------------------------------------------------------------- the director's hooks
(defun cine-begin (name a v)
  "A cinematic starts: no caption yet, the actors leave their sim states (standing still)."
  (setf *caption* nil)
  (dolist (e (list a v))
    (when (fighter e)
      (setf (fighter-state (fighter e)) :cine (fighter-sf (fighter e)) 0 (motion-kb-left (motion e)) 0)
      (fill (motion-vel (motion e)) 0f0)))
  (clog "cine ~a" name))

(defun cine-actor-step (e)
  "One fixed step of a cinematic actor: his animation advances."
  (let ((m (model e))) (when m (anim-advance (model-anim m) +step+))))

(defun cine-end (c)
  "A cinematic ended (C, or NIL when none ran): restore the stage look, clear the caption and the
flash, give the actors back (the presses buffered during it forgotten: mashing through a
cinematic fires nothing)."
  (setf *caption* nil)
  (fill *ui-flash* 0f0)
  (screen-fx-clear)
  (stage-env)
  (when c
    (dolist (e (list (cine-a c) (cine-v c)))
      (when (fighter e) (refresh-look e) (vpad-flush! (pilot-vpad (pilot e)))))))

(setf *cine-begin-hook* #'cine-begin *cine-actor-hook* #'cine-actor-step *cine-end-hook* #'cine-end)

;;; ---------------------------------------------------------------- script helpers
(defun shot-on (e ang dist h &key (look 1.1) (ahead 0.0))
  "Camera at ANG degrees around fighter E's facing (0 = in front of him, 90 = his left), DIST metres
away, H high, looking at his body LOOK metres up, AHEAD metres in front of him."
  (let* ((p (pos-of e)) (yaw (+ (yaw-of e) (deg ang)))
         (fx (fwd-x (yaw-of e))) (fz (fwd-z (yaw-of e)))
         (tx (+ (aref p 0) (* ahead fx))) (tz (+ (aref p 2) (* ahead fz))))
    (cine-cam (+ tx (* dist (fwd-x yaw))) h (+ tz (* dist (fwd-z yaw))) tx look tz)))

(defun shot-pair (a v side dist h)
  "Both fighters from the SIDE (+1 / -1) of the A->V line, DIST metres from their midpoint."
  (let* ((p (pos-of a)) (q (pos-of v)) (mx (* 0.5 (+ (aref p 0) (aref q 0)))) (mz (* 0.5 (+ (aref p 2) (aref q 2))))
         (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (d (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))))
    (cine-cam (+ mx (* side dist (/ (- dz) d))) h (+ mz (* side dist (/ dx d))) mx 1.1 mz)))

(defun face-each-other (a v &optional (gap nil))
  "Turn A and V to face each other; with GAP, first put A GAP metres in front of V (a flash step)."
  (let ((p (pos-of a)) (q (pos-of v)))
    (when gap
      (let* ((dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2))) (d (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))))
        (setf (aref p 0) (+ (aref q 0) (* gap (/ dx d))) (aref p 2) (+ (aref q 2) (* gap (/ dz d))) (aref p 1) 0f0)))
    (setf (transform-yaw (transform a)) (f32 (dir-yaw (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2))))
          (transform-yaw (transform v)) (f32 (dir-yaw (- (aref p 0) (aref q 0)) (- (aref p 2) (aref q 2)))))
    (setf (aref q 1) 0f0)))

(defun cine-clip (e clip &key (blend 3) (speed 1.0) (time 0.0))
  "Play CLIP on actor E (falls back to the stance with a log line if the art lacks it)."
  (play-clip e clip :blend blend :speed speed :time time))

(defun ui-flash (r g b a &optional (fade 3.0))
  "A full-screen flash of colour (r g b), alpha A, fading at FADE per second."
  (let ((f *ui-flash*)) (setf (aref f 0) (f32 r) (aref f 1) (f32 g) (aref f 2) (f32 b) (aref f 3) (f32 a) (aref f 4) (f32 fade))))

(defun caption (text &key sub (color '(1 1 1 1)) kanji)
  "The cinematic's title (a move / form name, a big word): stays up until the next caption or the end."
  (setf *caption* (list text sub color kanji)))

(defun actor-point (e up)
  "X Y Z (values) of fighter E's body, UP metres above the feet."
  (let ((p (pos-of e))) (values (aref p 0) (+ (aref p 1) up) (aref p 2))))

;;; ---------------------------------------------------------------- screen punctuation
;;; Impact frames (the engine's *GRADE-IMPACT* composite modes), focus lines, the Burst's back-rim and
;;; silence beats, each for a number of 60 Hz frames of effect time (paused = frozen). A request made
;;; during a frame's steps is drawn by that frame at least: SCREEN-FX-UPDATE runs down the previous
;;; frame's time at the start of the next one (main.lisp GAME-FRAME).
(declaim (type f32vec *screen-fx* *fl-scr*))
(defvar *fl-scr* (make-f32 3) "FOCUS-LINES' projected centre.")
(defvar *screen-fx* (make-f32 6)
  "Effect seconds left: [0] impact frame [1] focus lines [2] silence [3] back-rim; [4 5] the focus lines'
centre (window px; < 0 = the screen centre).")
(defparameter *impact-presets*
  '((:negative 1)
    (:two-tone 2 :threshold 0.4)                                            ; white / ink
    (:ink 2 :threshold 0.4 :ink (1 1 1) :paper (0.031 0.031 0.047))         ; ink / white (on a white card)
    (:red 2 :threshold 0.4 :paper (0.816 0.063 0.11))                       ; red / ink
    (:fire 2 :threshold 0.4 :paper (1.0 0.353 0.118))                       ; fire / ink
    (:manga 3 :threshold 0.4 :keep-sat 0.45)                                ; two-tone, the spot colour kept
    (:spot 4 :keep-sat 0.45 :keep-hue 10.0))                                ; grey but the ember hue (Bankai)
  "IMPACT-FRAME kinds -> GRADE-IMPACT mode and parameters (docs/STYLE_STORM_DESIGN.md §3.6 presets).")

(defun impact-frame (kind frames)
  "Screen punctuation KIND (a key of *IMPACT-PRESETS*: :negative, :two-tone, :ink, :red, :fire, :manga,
:spot) for FRAMES 60 Hz frames (at least one drawn frame). A later request replaces a running one."
  (apply #'grade-impact (rest (or (assoc kind *impact-presets*) (error "no impact preset ~s" kind))))
  (setf (aref *screen-fx* 0) (f32 (/ frames 60.0))))

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
  (ffi:c-inline () () :void "au_set_volume(1,0.0f)" :one-liner t))

(defun back-rim (frames)
  "Both fighters silhouetted (all in their shadow tone) with a hard white back-rim for FRAMES (the Burst)."
  (setf (aref *screen-fx* 3) (f32 (/ frames 60.0)) (env-toon-threshold *env*) 1.5)
  (v3-set! (env-cin-rim *env*) 0.91f0 0.93f0 0.96f0))

(defun screen-fx-update (dt)
  "Run the screen punctuation down by DT effect seconds (0 while paused); end what ran out."
  (let ((f *screen-fx*))
    (flet ((run (i) (let ((was (aref f i))) (setf (aref f i) (f32 (max 0.0 (- was dt)))) (and (> was 0) (<= (aref f i) 0)))))
      (when (run 0) (grade-impact 0))
      (run 1)
      (when (run 2) (set-music-volume 0.55) (ffi:c-inline () () :void "au_set_volume(1,1.0f)" :one-liner t))
      (when (run 3) (setf (env-toon-threshold *env*) 0.5) (v3-set! (env-cin-rim *env*) 0f0 0f0 0f0)))))

(defun screen-fx-clear ()
  "End every screen punctuation now (a new match, the end of a cinematic)."
  (let ((f *screen-fx*))
    (when (> (aref f 2) 0) (set-music-volume 0.55) (ffi:c-inline () () :void "au_set_volume(1,1.0f)" :one-liner t))
    (fill f 0f0) (grade-impact 0) (setf (env-toon-threshold *env*) 0.5) (v3-set! (env-cin-rim *env*) 0f0 0f0 0f0)))

(defun draw-screen-fx (w h)
  "The UI part of the punctuation: focus lines (ink, reshuffled every drawing on twos)."
  (let ((f *screen-fx*))
    (when (> (aref f 1) 0)
      (let ((cx (if (< (aref f 4) 0) (* 0.5 w) (aref f 4))) (cy (if (< (aref f 5) 0) (* 0.5 h) (aref f 5))))
        (ui-focus-lines (f32 cx) (f32 cy) 56 (f32 (* 0.16 h)) (f32 (* 1.4 (max w h))) '(0.03 0.03 0.05 0.92)
                        (f->i (* 12f0 (fx-clock))))))))

;;; ---------------------------------------------------------------- generic scripts
(defcine soul-break-cine (a v :len 96 :hold 44)
  "Reishi hit 0: the victim crumples, his souls shatter (Konpaku already settled)."
  (at 0 (face-each-other a v)
      (cine-clip v :sh-crumple :blend 2) (cine-clip a (kit-stance (kit-of a)) :blend 6)
      (shot-on v 60 4.2 1.3 :look 0.9)
      (caption "SOUL BREAK" :color '(1.0 0.25 0.3 1))
      (play-sfx :kikon-slash) (ui-flash 1 1 1 0.6))
  (at 40 (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 4))
      (play-sfx :konpaku-shatter) (shake 0.15 0.3))
  (during (0 96) (let ((p (pos-of v))) (vfx-soul-flame (aref p 0) 2.2 (aref p 2) (/ cf 60.0))))
  (at 60 (shot-pair a v 1 7.0 2.2)))

(defcine intro-cine (a v :len 300 :hold 200)
  "Match intro: A (P1) then V (P2) play their intro clips under their names; then FIGHT!"
  (at 0 (face-each-other a v)
      (dolist (e (list a v)) (cine-clip e (kit-stance (kit-of e)) :blend 0))
      (cine-clip a (or (kit-intro (kit-of a)) (kit-stance (kit-of a))) :blend 0)
      (shot-on a 25 3.6 1.5 :look 1.2) (intro-weapon a 0)
      (caption (kit-name (kit-of a)) :sub (kit-intro-callout (kit-of a))))
  (during (0 120) (shot-on a (+ 25 (* 20 u)) (- 3.6 (* 0.6 u)) 1.5 :look 1.2))
  (at 120 (cine-clip v (or (kit-intro (kit-of v)) (kit-stance (kit-of v))) :blend 0)
      (caption (kit-name (kit-of v)) :sub (kit-intro-callout (kit-of v))))
  (during (120 240) (shot-on v (- -25 (* 20 u)) (- 3.6 (* 0.6 u)) 1.5 :look 1.2))
  (during (240 300) (shot-pair a v (camera-side) (+ 6.0 (* 2.0 u)) 2.4))
  (when step-p (intro-weapon a cf) (intro-weapon v (- cf 120)))
  (at 240 (setf *caption* nil))
  (at 250 (announce "FIGHT!" :color '(1 0.85 0.3 1) :secs 1.0) (play-sfx :fight)))

(defun intro-weapon (e frame)
  "The intro prop in hand until the kit's hand-off frame (Yamamoto's cane), then the weapon."
  (let ((iw (kit-intro-weapon (kit-of e))) (m (model e)))
    (setf (model-weapon m) (if (and iw (<= 0 frame) (< frame (second iw))) (first iw) (kit-weapon (kit-of e))))))

(defcine ko-cine (a v :len 150 :hold 70)
  "K.O.: A won, V kneels; slow orbit, K.O."
  (at 0 (face-each-other a v)
      (cine-clip v :sh-lose :blend 8) (cine-clip a (or (kit-win (kit-of a)) (kit-stance (kit-of a))) :blend 8)
      (caption "K.O." :color '(1 0.2 0.25 1)) (play-sfx :ko) (ui-flash 1 1 1 0.8 2.0))
  (during (0 150) (shot-on v (+ 40 (* 50 u)) (- 5.0 (* 1.2 u)) (+ 1.0 (* 0.6 u)) :look 0.8)))

(defcine time-cine (a v :len 120 :hold 60)
  "TIME: the timer ran out; A won on Konpaku / Reishi (or a draw)."
  (at 0 (caption "TIME" :color '(1 0.85 0.3 1)) (play-sfx :ko))
  (during (0 120) (shot-pair a v (camera-side a) (+ 8.0 u) 2.6)))
