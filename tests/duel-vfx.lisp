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
    (3.0 6.0 13.0 1.0 1.4 0.0)))

(defparameter *scene-names*
  #("BLADE FIRE" "HELLFIRE: BLADE 1.3 + FIRE AURA" "BANKAI: BLADE EMBERS + HEAT AURA" "FIRE WAVE"
    "SHIRANUI: CHARGE -> FIREBALL" "ENNETSU JIGOKU: 7 PILLARS" "JOKAKU ENJO: DOME" "AURAS: EVOLUTION / REIATSU"
    "BREAKER: AURA + RING" "LINE CUTS: SUN / METEOR / CRACK" "NOZARASHI KIKON: SKY SPLIT"
    "TENCHI KAIJIN: SLASH + ASH" "SOUL FLAME + SKELETON DUST" "HITS" "HOHO / SHATTER / AWAKEN / SHOCKWAVE / FIRE CONE"
    "UI: KANJI / BITMAP / BAR" "WORST CASE"))

(defun scene (k)
  (setf *scene* (mod k (length *scene-names*)) *age* 0.0 *prev-age* 0.0 *grade-desat* 0.0 *grade-split* 0.0
        *label* (format nil "~d ~a" *scene* (aref *scene-names* *scene*)))
  (fx-clear)
  (setf *actors*
        (case *scene*
          ((0 1 4 5 15 16) (list (yama :x -1.5) (ken :x 4.0)))
          (2 (list (yama :x -1.5 :weapon :zanka) (ken :x 4.0)))
          (3 (list (yama :x -5.0) (ken :x 7.0)))
          ((6 10 11 12 13) (list (yama :x -2.0) (ken :x 1.5)))
          (7 (list (yama :x -0.9 :yaw pi) (ken :x 0.9 :yaw pi)))
          (8 (list (ken :x 1.5 :yaw (/ pi -2))))
          (9 (list (yama :x -3.0 :z 1.5) (ken :x 3.0 :z -1.5 :weapon :nozarashi :hide :eyepatch)))
          (14 (list (yama :x -1.5) (ken :x 1.5)))))
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
       (let ((u (cycle 1.2))) (when (< u 0.9) (vfx-fire-wave (+ -4.0 (* 14.0 u)) 0.0 (/ pi -2) u 3.5 dt))))
      (4 (multiple-value-bind (a b c d e f) (blade ya)
           (declare (ignore a b c))
           (let ((u (cycle 2.4)))
             (if (< u 1.2)
                 (vfx-charge d e f (/ u 1.2) dt)
                 (let ((s (- u 1.2))) (vfx-fireball (+ d (* 10.0 s)) e f 0.45 dt))))))
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
           (vfx-line-cut -2.0 1.5 7.0 1.5 u 0.8 :sun :dt dt)
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
      (16 (multiple-value-bind (a b c d e f) (blade ya) (vfx-blade-fire a b c d e f dt :power 1.3))
       (vfx-aura (actor-x ya) 0 (actor-z ya) 1.68 :hellfire age dt)
       (let ((u (cycle 1.2))) (when (< u 0.9) (vfx-fire-wave (+ -1.0 (* 14.0 u)) 2.0 (/ pi -2) u 3.5 dt)))
       (dotimes (i 7)
         (let ((an (* i (/ (* 2 pi) 7))))
           (vfx-fire-pillar (+ (actor-x ya) (* 4.0 (cos an))) (+ (actor-z ya) (* 4.0 (sin an))) 0.4 10.0 dt)))))))

(defun draw-ui ()
  (let ((s (ui-scale)) (w (window-width)) (h (window-height)))
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
      (draw-body b (actor-joints a) (actor-x a) 0.0 (actor-z a) (actor-yaw a) :weapon (actor-weapon a) :hide (actor-hide a))))
  (when *stage-on* (stage-draw rdt))
  (scene-fx (f32 rdt))
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

(defun vfx-debug (c)
  (cond ((= c 4999) (setf *hold* nil))
        ((>= c 4000) (setf *hold* (/ (- c 4000) 1000.0)))
        ((= c 3000) (setf *stats-on* (not *stats-on*)))
        ((= c 3001) (setf *stage-on* (not *stage-on*)))
        ((>= c 2000) (setf *hold* nil) (scene (- c 2000)))))

(defun vfx-start () (stage-env) (scene 0))

(run-game :title "SOUL DUEL VFX"
          :load (list #'bodies-init #'stage-init)
          :start #'vfx-start
          :frame #'vfx-frame
          :debug #'vfx-debug
          :stats (lambda () (format nil " | vfx scene ~d plive ~d" *scene* *plive*)))
