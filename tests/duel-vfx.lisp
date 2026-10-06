;;;; duel-vfx.lisp — SOUL DUEL VFX gallery: every effect of duel/lisp/vfx.lisp on the dusk stage
;;;; with posed fighters for scale, looping over time, plus a worst-case scene with a stats line.
;;;; A test target, not part of the game:
;;;;   ./build.sh duelvfx duel/lisp/package.lisp duel/lisp/body.lisp duel/lisp/yama-art.lisp \
;;;;     duel/lisp/ken-art.lisp duel/lisp/stage.lisp duel/lisp/vfx.lisp tests/duel-vfx.lisp
;;;;   python3 tests/scripts/duel-vfx.py   (writes tests/scripts/duel-vfx.json)
;;;;   node tools/run.mjs dist/duelvfx --secs 150 --script tests/scripts/duel-vfx.json
;;;; Keys: N / P next / previous scene. Debug commands (Module._debug_cmd):
;;;;   2000+k scene k (restarts its clock)    3000 stats overlay on/off    3001 stage fx off/on
;;;   4000+ms run the scene clock to MS milliseconds, then freeze everything (deterministic shots;
;;;           another 4000+ms resumes up to the new time)    4999 unfreeze
;;;   3002 fighters off/on (a still without them = the fighter mask of tools/toon_check.py --bg)
;;;   3003 label + stats text off/on (measured stills)    3004 stage fx (ash) off/on
;;;   3006 the fighters' ink shadow discs off/on (the outline measure: the mask's edge is then the figure's)
;;;   3010+m *GRADE-IMPACT* mode m (0 off, 1 negative, 2 two-tone, 3 manga page, 4 spot-keep hue 10)
;;;   Scenes 18-31: the phase-2 toon universal effects (docs/style/STYLE_STORM_DESIGN.md §4.3), each fired at the scene's
;;;   start (and again every 2.4 s), for frozen stills at chosen ages (tests/style-2-shots.py)
;;;   3007 scene 17 with the phase-3 signature looks on/off: Yamamoto's blade fire and Kenpachi's base yellow aura (the
;;;        neutral still of docs/style/STYLE_STORM_DESIGN.md §9 row 3: spot share <= 15 %)
;;;   3020 consing of the phase-2 per-frame paths; 3021 the phase-3 ones (blade fire / embers, smears, fire wave, auras,
;;;        line cuts, Bankai cracks), 100 calls each
;;;   3005 flat measuring mode on/off: no character gradient, character / shadow fog or vignette, so every lit or shadow pixel
;;;        is exactly a palette tone (tools/toon_check.py --palette: two tones per colour)
;;; The frozen duel still (tests/style-gates.py duelstill): scene 17 NEUTRAL, 3003, 3004, 4000+500, then
;;; a shot with and one without the fighters, under run.mjs --fixed-dt.
(in-package :duel)

(setf *stats-log* t *pixel-lights* 3 *auto-render-scale* nil)

(defstruct (actor (:constructor %make-actor))
  (body nil) (weapon nil) (hide nil)
  (x 0f0 :type single-float) (z 0f0 :type single-float) (yaw 0f0 :type single-float)
  (anim (make-anim)) (joints (make-f32 (* 16 +nj+)) :type f32vec))

(defun make-actor (body weapon clip &key hide (x 0.0) (z 0.0) (yaw 0.0))
  (let ((a (%make-actor :body (find-body body) :weapon weapon :hide hide :x (f32 x) :z (f32 z) :yaw (f32 yaw))))
    (anim-play (actor-anim a) clip :blend 0)
    a))

(defvar *actors* nil)
(defvar *scene* 0)
(defvar *age* 0.0 "seconds since the scene started")
(defvar *prev-age* 0.0)
(defvar *stats-on* t)
(defvar *hold* nil "NIL or the scene time (s) at which the gallery freezes")
(defvar *stage-on* t)
(defvar *actors-on* t "3002: draw the fighters")
(defvar *text-on* t "3003: draw the label and stats text")
(defvar *shadows-on* t "3006: draw the fighters' shadow discs")
(defvar *looks-on* nil "3007: scene 17 with Yamamoto's blade fire and Kenpachi's base aura")
(defvar *vignette* 0.25 "3005: the stage's vignette, restored when the flat mode ends")
(defvar *label* "")
(defvar *stat-str* "")
(defvar *stat-t* 0.0)
(defvar *ms* 0.0)
(defvar *base* (make-f32 3)) (defvar *tip* (make-f32 3))

(defun yama (&key (x -1.5) (z 0.0) (yaw (/ pi -2)) (weapon :ryujin-jakka))
  (make-actor :yamamoto weapon :ya-stance :x x :z z :yaw yaw))
(defun ken (&key (x 1.5) (z 0.0) (yaw (/ pi 2)) (weapon :ken-katana) hide)
  (make-actor :kenpachi weapon :ke-stance :x x :z z :yaw yaw :hide hide))

(defun blade (a)
  "Base / tip of actor A's held weapon into *BASE* / *TIP*; returns the six floats."
  (body-weapon-base (actor-body a) (actor-weapon a) (actor-joints a) *base*)
  (body-weapon-tip (actor-body a) (actor-weapon a) (actor-joints a) *tip*)
  (values (aref *base* 0) (aref *base* 1) (aref *base* 2) (aref *tip* 0) (aref *tip* 1) (aref *tip* 2)))

(defun crossed (tm) "The scene clock passed TM this frame." (and (<= *prev-age* tm) (< tm *age*)))
(defun cycle (period) "Scene clock modulo PERIOD." (mod *age* period))
(defun cyc-crossed (period tm)
  (let ((a (mod *prev-age* period)) (b (mod *age* period)))
    (if (<= a b) (and (<= a tm) (< tm b)) (or (<= a tm) (< tm b)))))

(defparameter *cams*
  ;; eye xyz target xyz per scene
  #((-0.3 1.5 2.4 -0.9 1.0 0.0) (-0.2 1.7 3.6 -1.0 1.1 0.0) (-0.3 1.5 2.4 -0.9 1.0 0.0) (-3.0 2.4 7.0 2.5 1.0 0.0)
    (2.0 1.8 6.5 1.5 1.1 0.0) (0.0 7.0 14.0 -1.0 1.8 0.0) (-1.0 4.0 11.0 1.5 1.4 0.0) (0.0 1.6 5.2 0.0 1.1 0.0)
    (0.5 1.6 5.0 1.5 1.0 0.0) (2.0 6.0 11.0 1.0 0.0 -1.0) (10.0 3.0 0.0 -6.0 1.5 0.0) (0.0 1.6 5.2 0.0 1.1 0.0)
    (0.5 2.2 5.0 1.5 1.7 0.0) (1.5 1.4 3.2 1.5 1.1 0.0) (0.0 2.0 6.0 0.0 0.8 0.0) (0.0 1.6 5.2 0.0 1.1 0.0)
    (3.0 6.0 13.0 1.0 1.4 0.0) (0.3 2.95 5.64 0.0 1.05 0.0)    ; 17: the pair camera at 3 m (x 0.8 closer)
    ;; 18-31: the universal effects, a mid shot of the pair (Yamamoto at x 0, Kenpachi at 1.5), impact at x 1.2
    (0.9 1.55 3.9 0.9 1.1 0.0) (0.9 1.55 3.9 0.9 1.1 0.0) (0.9 1.55 3.9 0.9 1.1 0.0) (0.9 1.55 3.9 0.9 1.1 0.0)
    (0.9 1.55 3.9 0.9 1.1 0.0) (0.9 1.55 3.9 0.9 1.1 0.0) (0.9 1.9 5.2 0.9 1.0 0.0) (0.9 1.6 4.6 0.9 1.0 0.0)
    (0.9 2.2 5.6 0.9 0.9 0.0) (0.9 1.55 3.9 0.9 1.1 0.0) (1.5 1.7 4.6 1.5 1.0 0.0) (0.9 1.4 3.9 0.9 0.6 0.0)
    (1.5 2.0 4.2 1.5 1.6 0.0) (0.9 1.55 3.9 0.9 1.1 0.0)))

(defparameter *scene-names*
  #("BLADE FIRE" "HELLFIRE: BLADE 1.3 + FIRE AURA" "BANKAI: BLADE EMBERS + HEAT AURA" "FIRE WAVE"
    "SHIRANUI: CHARGE -> FIREBALL" "ENNETSU JIGOKU: 7 PILLARS" "JOKAKU ENJO: DOME" "AURAS: EVOLUTION / REIATSU"
    "BREAKER: AURA + RING" "LINE CUTS: KYOKU / METEOR / CRACK" "NOZARASHI KIKON: SKY SPLIT"
    "TENCHI KAIJIN: SLASH + ASH" "SOUL FLAME + SKELETON DUST" "HITS" "HOHO / SHATTER / AWAKEN / SHOCKWAVE / FIRE CONE"
    "UI: KANJI / BITMAP / BAR" "WORST CASE" "NEUTRAL"
    "HIT: CUT" "HIT: HEAVY" "HIT: FIRE" "COUNTER" "GUARD" "GUARD BREAK" "CLASH" "HOHO: VANISH / APPEAR"
    "BURST REVERSE" "KONPAKU SHATTER" "KIKON RUSH: AURA + RING" "STEP DUST / LAND" "SOUL FLAME" "PUNCTUATION"))

(defun scene (k)
  (stamps-clear)
  (setf *scene* (mod k (length *scene-names*)) *age* 0.0 *prev-age* 0.0 *grade-desat* 0.0 *grade-split* 0.0
        *label* (format nil "~d ~a" *scene* (aref *scene-names* *scene*)))
  (fx-clear)
  (setf *actors*
        (case *scene*
          ((0 1 4 5 15 16) (list (yama :x -1.5) (ken :x 4.0)))
          (17 (list (yama :x -1.5) (ken :x 1.5)))
          (2 (list (yama :x -1.5 :weapon :zanka) (ken :x 4.0)))
          (3 (list (yama :x -5.0) (ken :x 7.0)))
          ((6 10 11 12 13) (list (yama :x -2.0) (ken :x 1.5)))
          (7 (list (yama :x -0.9 :yaw pi) (ken :x 0.9 :yaw pi)))
          (8 (list (ken :x 1.5 :yaw (/ pi -2))))
          (9 (list (yama :x -3.0 :z 1.5) (ken :x 3.0 :z -1.5 :weapon :nozarashi)))
          (14 (list (yama :x -1.5) (ken :x 1.5)))
          (28 (list (ken :x 1.5 :yaw (/ pi -2))))
          ((18 19 20 21 22 23 24 25 26 27 29 30 31) (list (yama :x 0.0) (ken :x 1.5)))))
  (log-msg "vfx: scene ~a" *label*))

(defun scene-fx (dt)
  "The current scene's effects for this frame."
  (let* ((age *age*) (ya (first *actors*)) (ke (second *actors*)))
    (case *scene*
      (0 (multiple-value-bind (a b c d e f) (blade ya) (vfx-blade-fire a b c d e f dt)))
      (1 (multiple-value-bind (a b c d e f) (blade ya) (vfx-blade-fire a b c d e f dt :power 1.3))
       (vfx-aura (actor-x ya) 0 (actor-z ya) 1.68 :hellfire age dt))
      (2 (multiple-value-bind (a b c d e f) (blade ya) (vfx-blade-embers a b c d e f dt))
       (vfx-aura (actor-x ya) 0 (actor-z ya) 1.68 :heat age dt))
      (3 (multiple-value-bind (a b c d e f) (blade ya) (vfx-blade-fire a b c d e f dt))
       (let ((u (cycle 1.2))) (when (< u 0.9) (vfx-fire-wave (+ -4.0 (* 14.0 u)) 0.0 (/ pi -2) u 3.5 dt :life 0.9))))
      (4 (multiple-value-bind (a b c d e f) (blade ya)
           (declare (ignore a b c))
           (let ((u (cycle 2.4)))
             (if (< u 1.2)
                 (vfx-charge d e f (/ u 1.2) dt)
                 (let ((s (- u 1.2))) (vfx-fireball (+ d (* 10.0 s)) e f 0.45 1.0 0.0 dt))))))
      (5 (multiple-value-bind (a b c d e f) (blade ya) (vfx-blade-fire a b c d e f dt :power 1.3))
       (let ((u (cycle 1.6)))
         (when (< u 0.8)
           (dotimes (i 7)
             (let ((an (* i (/ (* 2 pi) 7))))
               (vfx-fire-pillar (+ (actor-x ya) (* 4.0 (cos an))) (+ (actor-z ya) (* 4.0 (sin an))) u 0.8 dt))))))
      (6 (let ((u (cycle 2.6))) (when (< u 2.0) (vfx-fire-dome (actor-x ke) (actor-z ke) 2.5 u 2.0 dt))))
      (7 (vfx-aura (actor-x ya) 0 (actor-z ya) 1.68 :evolution age dt :rgb '(1.0 0.6 0.3))
       (vfx-aura (actor-x ke) 0 (actor-z ke) 2.02 :reiatsu age dt))
      (8 (let ((u (cycle 1.0)))
           (vfx-aura (actor-x ya) 0 (actor-z ya) 2.02 :breaker age dt :k (max 0.0 (/ (- u 0.6) 0.4)))
           (vfx-breaker-ring (actor-x ya) (actor-z ya) age)))
      (9 (let ((u (cycle 2.0)))
           (vfx-line-cut -2.0 1.5 7.0 1.5 u 0.67 :kyoku :dt dt)
           (vfx-line-cut 2.0 -1.5 -10.0 -1.5 u 1.5 :meteor :dt dt)
           (when (< u 1.0) (vfx-line-cut 0.0 4.0 0.0 1.0 u 1.0 :crack :dt dt))))
      (10 (let ((u (cycle 2.0)) (x (actor-x ke)) (z (actor-z ke)))    ; the cut runs along -x, the camera sits on it
            (if (< u 1.2)
                (vfx-sky-split x z (/ pi 2) u 1.2)
                (setf *grade-split* 0.0))))
      (11 (let ((u (cycle 2.5)))
            (setf *grade-desat* (if (< u 1.6) 1.0 0.0))
            (when (cyc-crossed 2.5 0.08) (vfx-ash-burst (actor-x ke) 0 (actor-z ke)))
            (when (< u 1.0) (vfx-tenchi-slash u 1.0))))
      (12 (vfx-soul-flame (actor-x ke) 2.45 (actor-z ke) age)
       (when (cyc-crossed 0.7 0.0) (vfx-skeleton-dust (+ (actor-x ke) (rnd-range -1.5 1.5)) (+ 1.5 (rnd-range -1.0 1.0)))))
      (13 (let ((kinds #(:cut :heavy :fire :guard :clash :counter :breaker)))
            (dotimes (i 7)
              (when (cyc-crossed 2.8 (* i 0.4))
                (setf *label* (format nil "13 HITS: ~a" (aref kinds i)))
                (vfx-hit (actor-x ke) 1.2 (actor-z ke) (aref kinds i) :dx 1.0 :dz 0.0)))))
      (14 (let ((x (actor-x ya)) (z (actor-z ya)))
            (flet ((at (tm what) (when (cyc-crossed 8.0 tm) (setf *label* (format nil "14 ~a" what)) t)))
              (when (at 0.0 "HOHO VANISH") (vfx-hoho x 1.0 z nil))
              (when (at 1.0 "HOHO APPEAR") (vfx-hoho (actor-x ke) 1.0 (actor-z ke) t))
              (when (at 2.0 "KONPAKU SHATTER") (vfx-konpaku-shatter (actor-x ke) 1.3 (actor-z ke) 6))
              (when (at 3.0 "AWAKEN BANKAI (SUCK)") (vfx-awaken-burst x 0 z :bankai))
              (when (at 3.5 "AWAKEN BANKAI BURST") (vfx-awaken-burst x 0 z :bankai-burst))
              (when (at 5.0 "AWAKEN NOZARASHI") (vfx-awaken-burst (actor-x ke) 0 (actor-z ke) :nozarashi))
              (when (at 6.0 "SHOCKWAVE") (vfx-shockwave 0 0 6 0.6))
              (when (at 6.6 "TAIMATSU FIRE CONE") (vfx-fire-cone x z (/ pi -2))))))
      (15 nil)
      (17 (when *looks-on*
            (multiple-value-bind (a b c d e f) (blade ya) (vfx-blade-fire a b c d e f dt))
            (vfx-aura (actor-x ke) 0 (actor-z ke) 2.02 :reiatsu age dt)))
      ((18 19 20 21 22 23 24) (when (cyc-crossed 2.4 0.0)
                                (vfx-hit 1.2 1.25 0.0 (nth (- *scene* 18) '(:cut :heavy :fire :counter :guard :guard-break :clash))
                                         :dx 1.0 :dz 0.0)))
      (25 (when (cyc-crossed 2.4 0.0) (vfx-hoho 0.0 1.0 0.0 nil :dx 1.0 :dz 0.0))
          (when (cyc-crossed 2.4 0.6) (vfx-hoho 0.9 1.0 0.3 t :dx 1.0 :dz 0.0)))
      (26 (when (cyc-crossed 2.4 0.0) (vfx-burst (actor-x ke) 0.0 (actor-z ke))))
      (27 (when (cyc-crossed 2.4 0.0) (vfx-konpaku-shatter (actor-x ke) 1.3 (actor-z ke) 4)))
      (28 (when (cyc-crossed 2.4 0.0) (vfx-kikon-rush (actor-x ya) (actor-z ya)))
          (vfx-aura (actor-x ya) 0 (actor-z ya) 2.02 :kikon age dt :k 1.0))
      (29 (when (cyc-crossed 2.4 0.0) (vfx-step-dust (actor-x ya) (actor-z ya) -1.0 0.0))
          (when (cyc-crossed 2.4 0.0) (vfx-shockwave (actor-x ke) (actor-z ke) 1.2 0.3 :pal +pal-dust+)))
      (30 (vfx-soul-flame (actor-x ke) 2.3 (actor-z ke) age))
      (31 nil)
      (16 (multiple-value-bind (a b c d e f) (blade ya) (vfx-blade-fire a b c d e f dt :power 1.3))
       (vfx-aura (actor-x ya) 0 (actor-z ya) 1.68 :hellfire age dt)
       (let ((u (cycle 1.2))) (when (< u 0.9) (vfx-fire-wave (+ -1.0 (* 14.0 u)) 2.0 (/ pi -2) u 3.5 dt :life 0.9)))
       (dotimes (i 7)
         (let ((an (* i (/ (* 2 pi) 7))))
           (vfx-fire-pillar (+ (actor-x ya) (* 4.0 (cos an))) (+ (actor-z ya) (* 4.0 (sin an))) 0.4 10.0 dt)))))))

(defun draw-ui ()
  (let ((s (ui-scale)) (w (window-width)) (h (window-height)))
    (when (= *scene* 31)
      (ui-rect 0 0 (* 0.5 w) h '(0.03 0.03 0.047 1)) (ui-rect (* 0.5 w) 0 (* 0.5 w) h '(1 1 1 1))
      (ui-ink-splash (* 0.25 w) (* 0.5 h) (* 0.12 h) 3f0 '(0.95 0.95 0.95 1) (f->i (* 12 *age*)))
      (ui-ink-splash (* 0.75 w) (* 0.5 h) (* 0.12 h) 8f0 '(0.03 0.03 0.047 1) (f->i (* 12 *age*)))
      (ui-speed-lines 0f0 18 '(0.95 0.95 0.95 0.9) (f->i (* 12 *age*)))
      (ui-focus-lines (* 0.75 w) (* 0.5 h) 48 (* 0.2 h) (* 1.2 w) '(0.03 0.03 0.047 0.9) (f->i (* 12 *age*))))
    (when (= *scene* 24)
      (ui-focus-lines (* 0.5 w) (* 0.45 h) 56 (* 0.16 h) (* 1.4 w) '(0.03 0.03 0.05 0.92) (f->i (* 12 *age*))))
    (unless *text-on* (return-from draw-ui nil))
    (ui-text *label* (* 10 s) (* 10 s) :scale s :shadow t)
    (when (= *scene* 15)
      (ui-kanji :bankai (* 0.5 w) (* 0.12 h) (* 2 s) :align :center :color '(1 0.95 0.8 1) :color2 '(1 0.45 0.1 1))
      (ui-block-text "ZANKA NO TACHI" (* 0.5 w) (+ (* 0.12 h) (* 52 s)) (* 2 s) :align :center :color '(1 1 1 1))
      (ui-kanji :nozarashi (* 0.27 w) (* 0.45 h) (* 2 s) :align :center :color '(1 0.95 0.5 1) :color2 '(0.9 0.6 0.1 1) :shear 0.15)
      (ui-kanji :kikon (* 0.73 w) (* 0.45 h) (* 2 s) :align :center :color '(1 0.3 0.3 1) :color2 '(0.5 0 0.05 1))
      (ui-kanji :kikon (* 0.73 w) (* 0.62 h) s :align :center)
      (ui-bitmap '(#b0110110 #b1111111 #b1111111 #b0111110 #b0011100 #b0001000) (* 0.5 w) (* 0.64 h) (* 4 s)
                 :color '(1 0.3 0.4 1) :color2 '(0.6 0 0.1 1))
      (let ((bw (* 160 s)) (bh (* 10 s)) (y (* 0.82 h)) (f (/ (+ 1 (sin (* 2 *age*))) 2)))
        (ui-bar (* 20 s) y bw bh f '(1 0.2 0.2) :color2 '(1 0.6 0.3) :border '(1 1 1 0.6))))
    (when *stats-on*
      (ui-text *stat-str* (* 10 s) (- h (* 14 s)) :scale s :shadow t))))

(defun vfx-frame (real-dt)
  (when (key-pressed :n) (scene (1+ *scene*)))
  (when (key-pressed :p) (scene (1- *scene*)))
  (let ((rdt (if *hold* (max 0.0 (min real-dt (- *hold* *age*))) real-dt)))
    (setf *prev-age* *age* *age* (+ *age* rdt)
          *ms* (+ (* 0.9 *ms*) (* 100.0 real-dt)))
    (vfx-draw rdt)))

(defun vfx-draw (rdt)
  (let ((c (aref *cams* *scene*))) (apply #'camera-look-at (coerce c 'list)))
  (perf-mark)
  (dolist (a *actors*)
    (let ((an (actor-anim a)) (b (actor-body a)))
      (anim-advance an (f32 rdt))
      (pose-fk! (actor-joints a) (anim-eval an) (actor-x a) 0.0 (actor-z a) (actor-yaw a) (body-scale b) (body-hunch b) (body-props b))
      (when *actors-on*
        (draw-body b (actor-joints a) (actor-x a) 0.0 (actor-z a) (actor-yaw a) :weapon (actor-weapon a) :hide (actor-hide a)
                   :shadow *shadows-on*))))
  (when *stage-on* (stage-draw rdt))
  (fx-clock-advance (f32 rdt))
  (scene-fx (f32 rdt))
  (stamps-draw (f32 rdt))
  (lights-flush)
  (fx-update (f32 rdt))
  (fx-draw-particles)
  (fx-rings-update (f32 rdt))
  (perf-mark)
  (when (> (- *age* *stat-t*) 0.5)                      ; refresh the text twice a second (FORMAT conses)
    (setf *stat-t* *age*
          *stat-str* (format nil "cons/frame ~d B  particles ~d  fx-dropped ~d  ~,1f ms  draws ~d"
                             (round (cons-per-frame)) *plive* *fx-dropped* *ms* *draw-count*)))
  (when (< *age* *stat-t*) (setf *stat-t* 0.0))
  (draw-ui))

(defmacro consed (&body body) `(let ((c0 (cons-bytes))) ,@body (- (cons-bytes) c0)))
(defun-fast cons-stamps (n) (declare (fixnum n)) (dotimes (i n) (stamps-draw 0f0)))
(defun-fast cons-kikon (n) (declare (fixnum n)) (dotimes (i n) (%kikon-aura 1f0 0f0 0f0 1.9f0 1f0)))
(defun-fast cons-soul (n) (declare (fixnum n)) (dotimes (i n) (vfx-soul-flame 1f0 2.3f0 0f0 0.5f0)))
(defvar *t-trail* (let ((tr (make-trail)))          ; a synthetic swing: 6 samples on an arc
                    (dotimes (i 6 tr)
                      (let ((a (* 0.3 i)))
                        (trail-push tr 0.0 1.2 0.0 (f32 (* 0.9 (cos a))) (f32 (+ 1.2 (* 0.9 (sin a)))) 0.3)))))
(defvar *t-smear* (make-f32 12))
(defun-fast cons-p3 (n what)
  (declare (fixnum n what))
  (dotimes (i n)
    (fx-clock-advance 0.02f0)                             ; new drawings, so the smear re-captures
    (case what
      (0 (vfx-blade-fire 0f0 1f0 0f0 0.9f0 1.2f0 0f0 0.016f0 :power 1.3f0))
      (1 (vfx-blade-embers 0f0 1f0 0f0 0.9f0 1.2f0 0f0 0.016f0))
      (2 (vfx-smear *t-trail* *t-smear* 0) (vfx-smear *t-trail* *t-smear* 1) (vfx-smear *t-trail* *t-smear* 2))
      (3 (vfx-fire-wave 1f0 0f0 -1.57f0 0.3f0 3.5f0 0.016f0 :life 0.9f0))
      (4 (vfx-aura 1f0 0f0 0f0 2f0 :reiatsu 0f0 0.016f0) (vfx-aura 1f0 0f0 0f0 2f0 :nozarashi 0f0 0.016f0)
         (vfx-aura 1f0 0f0 0f0 2f0 :heat 0f0 0.016f0))
      (5 (vfx-line-cut 0f0 0f0 6f0 0f0 0.1f0 1f0 :meteor :dt 0.016f0) (vfx-line-cut 0f0 1f0 3f0 1f0 0.1f0 1f0 :crack :dt 0.016f0)
         (vfx-line-cut 0f0 2f0 9f0 2f0 0.3f0 0.57f0 :enjo :dt 0.016f0))
      (t (st-draw-cracks)))))
(defun cons-check-3 ()
  "3021: bytes consed by 100 calls of each phase-3 per-frame path."
  (stage-clear-cracks) (stage-crack-add 0.0 0.0 3.0) (stage-crack-add 2.0 1.0 2.0)
  (dotimes (w 7)
    (let* ((ft (stream-buffer-fill *fx-toon*)) (fa (stream-buffer-fill *fx-add*)) (fb (stream-buffer-fill *fx-alpha*))
           (a (consed (cons-p3 100 w))))
      (setf (stream-buffer-fill *fx-toon*) ft (stream-buffer-fill *fx-add*) fa (stream-buffer-fill *fx-alpha*) fb)
      (log-msg "phase-3 consing: 100 x ~a ~d B" (nth w '(blade-fire blade-embers smear-x3 fire-wave auras-x3 line-cuts-x3 cracks)) a)))
  (stage-clear-cracks) (fx-clear))

(defun cons-check ()
  "3020: bytes consed by 100 calls of each new per-frame path (with one stamp of every kind live)."
  (dolist (k '(:cut :heavy :fire :counter :guard :guard-break :clash :hoho-out :hoho-in :burst :konpaku :rush :land :guard-crush :reiatsu))
    (stamps-clear) (stamp k 1.2 1.2 0.0 :dx 1.0 :dz 0.0)
    (let* ((ft (stream-buffer-fill *fx-toon*)) (a (consed (cons-stamps 100))))
      (setf (stream-buffer-fill *fx-toon*) ft)
      (log-msg "phase-2 consing: 100 stamps-draw of ~a ~d B" k a)))
  (stamps-clear)
  (dolist (k '(:cut :heavy :fire :counter :guard :guard-break :clash :hoho-out :hoho-in :burst :konpaku :rush :land))
    (stamp k 1.2 1.2 0.0 :dx 1.0 :dz 0.0))
  (let* ((ft (stream-buffer-fill *fx-toon*)) (a (consed (cons-stamps 100))) (b (consed (cons-kikon 100))) (c (consed (cons-soul 100))))
    (setf (stream-buffer-fill *fx-toon*) ft)
    (log-msg "phase-2 consing: 100 stamps-draw (13 stamps live) ~d B, 100 kikon aura ~d B, 100 soul flame ~d B" a b c)))

(defun vfx-debug (c)
  (cond ((= c 4999) (setf *hold* nil))
        ((<= 3010 c 3014) (grade-impact (- c 3010)))
        ((= c 3020) (cons-check))
        ((= c 3021) (cons-check-3))
        ((= c 3007) (setf *looks-on* (not *looks-on*)))
        ((>= c 4000) (setf *hold* (/ (- c 4000) 1000.0)))
        ((= c 3000) (setf *stats-on* (not *stats-on*)))
        ((= c 3001) (setf *stage-on* (not *stage-on*)))
        ((= c 3002) (setf *actors-on* (not *actors-on*)))
        ((= c 3003) (setf *text-on* (not *text-on*)))
        ((= c 3006) (setf *shadows-on* (not *shadows-on*)))
        ((= c 3004) (setf *stage-fx* (not *stage-fx*)))
        ((= c 3005) (let ((on (> (env-toon-gradient *env*) 0)))
                      (when on (setf *vignette* (env-vignette *env*)))
                      (setf (env-toon-gradient *env*) (if on 0.0 0.14) (env-vignette *env*) (if on 0.0 *vignette*)
                            (aref *toon-body* 2) (if on 0f0 0.2f0) (aref *toon-ground* 2) (if on 0f0 1f0))))
        ((>= c 2000) (setf *hold* nil) (scene (- c 2000)))))

(defun vfx-start () (stage-env) (scene 0))

(run-game :title "SOUL DUEL VFX"
          :load (append (list #'bodies-init) (body-load-steps) (list #'stage-init))
          :start #'vfx-start
          :frame #'vfx-frame
          :debug #'vfx-debug
          :stats (lambda () (format nil " | vfx scene ~d plive ~d" *scene* *plive*)))
