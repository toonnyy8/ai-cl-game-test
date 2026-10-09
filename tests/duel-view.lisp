;;;; duel-view.lisp — SOUL DUEL art viewer: both characters (every form and weapon), the skeleton,
;;;; clip strips, the stage, and every sound. A test target, not part of the game:
;;;;   ./build.sh duelview duel/lisp/package.lisp duel/lisp/body.lisp duel/lisp/yama-art.lisp \
;;;;     duel/lisp/ken-art.lisp duel/lisp/sounds.lisp duel/lisp/stage.lisp tests/duel-view.lisp
;;;;   python3 tests/scripts/duel-view.py   (writes tests/scripts/duel-view-*.json, see its header)
;;;;   node tools/run.mjs dist/duelview --secs 60 --script tests/scripts/duel-view-looks.json
;;;; Keys: 1-5 scenes, LEFT/RIGHT turn, SPACE spin, N/P next/previous clip strip, G stage on/off.
;;;; Debug commands (Module._debug_cmd):
;;;;   2000+k  scene k: 0 base forms, 1 awakened forms, 2 cane + skeletons, 3 mirror match, 4 duel on the stage,
;;;;           5 the expressions: actors 0-2 Yamamoto neutral / shout / hurt, 3-5 Kenpachi (6200+i: each face)
;;;;   6000+i / 6100+i / 6200+i  camera on actor i: full body / head and chest / face (0.7 m, eye level);
;;;;   6210+i  the face from 35 degrees to its left
;;;;   6300+k  every actor's expression: 0 neutral, 1 shout, 2 hurt (DRAW-BODY :face; scene 5 shows all three)
;;;;   7000+k  grip strip of *GRIP-CLIPS* k: its 4 worst-drift frames, each a pair: keys only, then with GRIP-LEFT!
;;;;   3000+d  turntable angle d degrees (0 = facing the camera)     4000 stage off/on   4001 spin on/off
;;;;   4100+k / 4110+k  weapon k (0 katana, 1 Nozarashi, 2 the broken cleaver) alone, side on, one face / the other
;;;;   4002 / 4003  add three Bankai cracks / clear them    4004 actors off/on (cons baseline)
;;;;   4005  log every body's proportions (standing, no hunch): crown, head length, heads, head width,
;;;;         shoulder span, fingertips, hips (legs / height), from the joints and the shape extents
;;;;   5000+i  play sound i (LIST-SOUNDS order) and log it
;;;;   1000000+1000*i+k  strip of clip i (clips sorted by name): the owner posed at 4 frames side by side; k 1: 8 frames
;;;;           (the anticipation too), k 2: the 8 from 33 degrees off the front
;;;;           (0, S, S+A, end for DEFSTRIKE clips; 0, 1/3, 2/3, end otherwise; :sh- clips on both)
;;;;   900000+i  play clip i live (looping) on the current scene's matching actors
(in-package :duel)

(setf *audio-debug* t *stats-log* t)

(defstruct (actor (:constructor %make-actor))
  (body nil) (weapon nil) (hide nil) (tint nil) (rim nil)
  (x 0f0 :type single-float) (z 0f0 :type single-float) (yaw 0f0 :type single-float)
  (anim (make-anim)) (joints (make-f32 (* 16 +nj+)) :type f32vec)
  (frame -1 :type fixnum)                           ; >= 0: frozen at this frame
  (face :neutral)                                   ; the expression (6300+k, scene 5)
  (grip nil))                                       ; the left fist held on the handle (GRIP-LEFT!, 7000+k)

(defun make-actor (body weapon clip &key hide tint rim (x 0.0) (z 0.0) (yaw 0.0) (frame -1))
  (let ((a (%make-actor :body (find-body body) :weapon weapon :hide hide :tint tint :rim rim
                        :x (f32 x) :z (f32 z) :yaw (f32 yaw) :frame frame)))
    (anim-play (actor-anim a) clip :blend 0)
    a))

(defvar *actors* nil)
(defvar *v-yaw* 0.0 "turntable angle (radians, 0 = facing the camera)")
(defvar *v-spin* nil)
(defvar *v-stage* t)
(defvar *v-hide-actors* nil "4004: skip the actors (cons/frame baseline)")
(defvar *v-label* "")
(defvar *v-cam* (list 0.0 1.2 5.5 0.0 1.0 0.0) "camera eye xyz, target xyz")
(defvar *v-clip* 0)
(defvar *v-weapon* nil "4100+k / 4110+k: the weapon shown alone, side on (its +Y along the screen, its edge up), one face
or the other (the weapon reviews, DUEL_KEN_REWORK §6.1); NIL: none")
(defvar *v-weapon-m* (make-f32 16))
(defun clip-names () (list-clips))
(defun strike-sar (name)
  "(S A R) frames of a DEFSTRIKE clip (its :s / :a marks), NIL for other clips."
  (let ((s (clip-mark name :s)) (a (clip-mark name :a)))
    (when s (let ((fr (lambda (x) (round (* 60 x))))) (list (funcall fr s) (- (funcall fr a) (funcall fr s))
                                                            (- (funcall fr (clip-mark name :end)) (funcall fr a)))))))

(defun prefix-p (name p) (let ((s (symbol-name name))) (and (> (length s) (length p)) (string= p s :end2 (length p)))))

(defun clip-owners (name)
  "((body weapon hide) ...) that show clip NAME."
  (let ((awake-ya '(:ya-kyoku :ya-kaka :ya-tenchi :ya-bankai))
        (awake-ke '(:ke-meteor :ke-kikon-n :ke-nome :ke-n-stance :ke-n-leap :ke-r-stance :ke-drink :ke-r-q1 :ke-r-q3 :ke-r-f1
                   :ke-r-f2 :ke-n-f1)))
    (cond ((member name awake-ya) '((:yamamoto :zanka nil)))
          ((eq name :ya-intro) '((:yamamoto :ya-cane nil)))
          ((eq name :ya-ikkotsu) '((:yamamoto nil nil)))
          ((prefix-p name "YA-") '((:yamamoto :ryujin-jakka nil)))
          ((prefix-p name "KE-X-") '((:kenpachi-nomi :nozarashi nil)))   ; (cup 3's set and lifted hair, DUEL_KEN_REWORK §6.2)
          ((or (member name awake-ke) (prefix-p name "KE-K-") (member name '(:ke-r-kote :ke-r-tsuki)))
           '((:kenpachi :nozarashi nil)))     ; (cup 1's own clips, DUEL_KEN_REWORK §6.2)
          ((prefix-p name "KE-B-") '((:kenpachi-oni :ke-broken (:arm-wreck :crack-1 :crack-2 :crack-3 :crack-4))))
          ((prefix-p name "KE-") '((:kenpachi :ken-katana nil)))
          ((prefix-p name "SK-") '((:skeleton nil nil)))
          (t '((:yamamoto :ryujin-jakka nil) (:kenpachi :ken-katana nil))))))

(defun look-at (ex ey ez tx ty tz) (setf *v-cam* (list ex ey ez tx ty tz)))

(defun scene (k)
  (setf *v-yaw* 0.0 *v-stage* t)
  (look-at 0 1.25 5.6 0 1.0 0)
  (setf *actors*
        (ecase k
          (0 (setf *v-label* "BASE FORMS: RYUJIN JAKKA / KATANA")
           (list (make-actor :yamamoto :ryujin-jakka :ya-stance :x -1.1 :yaw pi)
                 (make-actor :kenpachi :ken-katana :ke-stance :x 1.1 :yaw pi)))
          (1 (setf *v-label* "AWAKENED: BANKAI ZANKA NO TACHI / NOZARASHI")
           (list (make-actor :yamamoto :zanka :ya-stance :x -1.1 :yaw pi)
                 (make-actor :kenpachi :nozarashi (if (find-clip :ke-n-stance nil) :ke-n-stance :ke-stance) :x 1.1 :yaw pi)))
          (2 (setf *v-label* "CANE / SKELETONS")
           (list (make-actor :yamamoto :ya-cane (if (find-clip :ya-intro nil) :ya-intro :ya-stance) :x -1.2 :yaw pi :frame 0)
                 (make-actor :skeleton nil (if (find-clip :sk-grab nil) :sk-grab :ya-stance) :x 0.3 :yaw pi :frame 20)
                 (make-actor :skeleton nil (if (find-clip :sk-grab nil) :sk-grab :ya-stance) :x 1.5 :yaw pi :frame 60)))
          (3 (setf *v-label* "MIRROR MATCH: P2 TINT + RIM")
           (look-at 0 1.4 7.5 0 1.0 0)
           (list (make-actor :yamamoto :ryujin-jakka :ya-stance :x -2.7 :yaw pi)
                 (make-actor :yamamoto :ryujin-jakka :ya-stance :x -1.0 :yaw pi :tint *mirror-tint* :rim *mirror-rim*)
                 (make-actor :kenpachi :ken-katana :ke-stance :x 0.9 :yaw pi)
                 (make-actor :kenpachi :ken-katana :ke-stance :x 2.8 :yaw pi :tint *mirror-tint* :rim *mirror-rim*)))
          (5 (setf *v-label* "EXPRESSIONS: NEUTRAL / SHOUT / HURT")
           (look-at 0 1.5 7.5 0 1.3 0)
           (loop for (body weapon clip) in '((:yamamoto :ryujin-jakka :ya-stance) (:kenpachi :ken-katana :ke-stance))
                 for row from 0
                 nconc (loop for face in '(:neutral :shout :hurt) for col from 0
                             collect (let ((a (make-actor body weapon clip :x (+ (* 1.3 col) (* 4.2 row) -3.4) :yaw pi)))
                                       (setf (actor-face a) face) a))))
          (4 (setf *v-label* "SEIREITEI RUINS AT NIGHT")
           (look-at 7.5 2.6 7.0 0 1.1 -0.5)
           (list (make-actor :yamamoto :ryujin-jakka :ya-stance :x -2.5 :z 0 :yaw (/ pi -2))
                 (make-actor :kenpachi :ken-katana :ke-stance :x 2.5 :z 0 :yaw (/ pi 2)))))))

(defun strip (i &optional (mode 0))
  "Clip I posed at 4 frames side by side (8 actors for shared clips: Yama row, Ken row). MODE 1: 8 frames (0, the
anticipation at S/3, 2S/3 and S-2, S, S+A, mid-recovery, end) from the side; MODE 2: the same 8 from 33 degrees off
the front (the strike reworks' stills, DUEL_KEN_REWORK §5.2)."
  (let* ((names (clip-names)) (i (mod i (length names))) (name (nth i names))
         (clip (find-clip name)) (end (round (* 60 (clip-dur clip))))
         (sar (strike-sar name))
         (frames (cond ((and sar (plusp mode))
                        (destructuring-bind (s a r) sar
                          (list 0 (round s 3) (round (* 2 s) 3) (max 0 (- s 2)) s (+ s a) (+ s a (round r 2)) (+ s a r))))
                       ((plusp mode) (loop for k below 8 collect (round (* k end) 7)))
                       (sar (destructuring-bind (s a r) sar (list 0 s (+ s a) (+ s a r))))
                       (t (list 0 (round end 3) (round (* 2 end) 3) end))))
         (n (length frames)) (dx (if (plusp mode) 1.25 1.7))
         (owners (clip-owners name)) (acts nil))
    (setf *v-clip* i *v-yaw* 0.0)
    (loop for (body weapon hide) in owners for row from 0 do
      (loop for f in frames for col from 0 do
        (push (make-actor body weapon name :hide hide :frame f :x (* dx (- col (/ (1- n) 2.0)))
                          :z (* -3.4 row) :yaw (- (/ pi -2) (if (= mode 2) 1.0 0.45)))
              acts)))
    (setf *actors* (nreverse acts)
          *v-label* (format nil "~d ~a  ~,2f S  FRAMES ~{~d~^ ~}~@[  S/A/R ~{~d~^/~}~]" i name (clip-dur clip) frames sar))
    (cond ((cdr owners) (look-at 0 3.4 6.8 0 0.7 -1.7))
          ((plusp mode) (look-at 0 1.2 6.6 0 1.0 0))
          (t (look-at 0 1.3 5.0 0 1.0 0)))
    (log-msg "view: strip ~a" *v-label*)))

(defvar *v-one* (fv 1) "GRIP-LEFT!'s weight 1.")
(defun grip-strip (k)
  "Grip clip K (*GRIP-CLIPS*) at the 4 frames where the left fist drifts furthest off the handle between the keys, each a
pair: as the keys interpolate it (raw), then as the game draws it (GRIP-LEFT!, Phase 6)."
  (let* ((name (nth (mod k (length *grip-clips*)) *grip-clips*)) (b (find-body :kenpachi)) (jm (make-f32 (* 16 +nj+)))
         (an (make-anim)) (gaps '()))
    (anim-play an name :blend 0)
    (dotimes (f (round (* 60 (clip-dur (find-clip name)))))
      (setf (anim-time an) (/ f 60.0))
      (pose-fk! jm (anim-eval an) 0.0 0.0 0.0 0.0 (body-scale b) (body-hunch b) (body-props b))
      (push (cons (grip-gap jm) f) gaps))
    (let ((frames (sort (mapcar #'cdr (subseq (sort gaps #'> :key #'car) 0 4)) #'<)) (acts nil))
      (loop for f in frames for col from 0 do                ; a pair per frame: keys only, then held
        (dotimes (held 2)
          (let ((a (make-actor :kenpachi :nozarashi name :frame f :x (+ (* 3.4 (- col 1.5)) (* 1.45 (- held 0.5))) :yaw (- (/ pi -2) 0.5))))
            (setf (actor-grip a) (= held 1)) (push a acts))))
      (setf *actors* (nreverse acts)
            *v-label* (format nil "GRIP ~a  FRAMES ~{~d~^ ~}  EACH PAIR: KEYS ONLY | FIST HELD ON THE HANDLE" name frames))
      (look-at 0 2.2 11.5 0 1.2 0)
      (log-msg "view: ~a" *v-label*))))

(defun close-up (i head)
  "Camera on actor I: full body, or HEAD (face) close-up."
  (let* ((a (nth (mod i (length *actors*)) *actors*)) (x (actor-x a)) (z (actor-z a))
         (h (* 1.8 (body-scale (actor-body a)))))
    (if head
        (look-at x (* 0.88 h) (+ z 1.6) x (* 0.82 h) z)
        (look-at x (* 0.6 h) (+ z (* 1.9 h)) x (* 0.5 h) z))))

(defun face-cam (i deg)
  "Camera 0.7 m from actor I's face, level with it, DEG degrees round from the front (the actor faces +z
at turntable 0)."
  (let* ((a (nth (mod i (length *actors*)) *actors*)) (p (make-f32 3)) (r (deg deg)))
    (joint-point! p (actor-joints a) (ji :head) 0f0 (* 0.12 (body-scale (actor-body a))) 0f0)
    (look-at (+ (aref p 0) (* 0.7 (sin r))) (aref p 1) (+ (aref p 2) (* 0.7 (cos r))) (aref p 0) (aref p 1) (aref p 2))))

(defun play-live (i)
  (let* ((names (clip-names)) (name (nth (mod i (length names)) names)))
    (dolist (a *actors*)
      (when (member (body-name (actor-body a)) (mapcar #'first (clip-owners name)))
        (setf (actor-frame a) -1)
        (anim-play (actor-anim a) name :blend 4)))
    (setf *v-label* (format nil "LIVE ~a" name))))

(defun measure-body (key)
  "Log KEY's proportions: zero pose, no hunch; shape extents ignore :rot (a close estimate)."
  (let* ((b (find-body key)) (jm (make-f32 (* 16 +nj+))) (p (make-f32 3)) (w (body-width b))
         (spec (girth-spec (body-spec b) (body-girth b))))
    (pose-fk! jm (make-f32 +pose-n+) 0.0 0.0 0.0 0.0 (body-scale b) 0.0 (body-props b))
    (labels ((half (sh)                  ; half extents (x y z) in the joint frame
               (let ((n (ldiff (cdr sh) (member-if #'keywordp (cdr sh)))))
                 (ecase (first sh)
                   ((:box :bevel :wedge) (list (* 0.5 w (first n)) (* 0.5 (second n)) (* 0.5 w (third n))))
                   ((:cyl :cone) (list (* w (first n)) (* 0.5 (second n)) (* w (first n))))
                   (:sphere (list (* w (first n)) (+ (first n) (* 0.5 (getf (member-if #'keywordp (cdr sh)) :stretch 0))) (* w (first n)))))))
             (edge (j sh sy)             ; world y of the shape's top (SY 1) or bottom (-1)
               (let ((at (or (getf (member-if #'keywordp (cdr sh)) :at) '(0 0 0))))
                 (joint-point! p jm (joint-index j) (f32 (or (first at) 0)) (f32 (+ (or (second at) 0) (* sy (second (half sh))))) 0f0)
                 (aref p 1)))
             (shapes (j) (remove :glow (rest (assoc j spec)) :key #'first))
             (jy (j) (joint-point! p jm (joint-index j) 0f0 0f0 0f0) (aref p 1)))
      (let* ((skull (first (shapes :head)))
             (crown (loop for sh in (shapes :head)                  ; tilted hair spikes left out
                          unless (getf (member-if #'keywordp (cdr sh)) :rot) maximize (edge :head sh 1)))
             (chin (edge :head skull -1)) (hl (- (edge :head skull 1) chin))
             (tip (loop for sh in (shapes :hand-r) minimize (edge :hand-r sh -1)))
             (sw (progn (joint-point! p jm (joint-index :upper-arm-r) 0f0 0f0 0f0)
                        (let ((x (aref p 0))) (joint-point! p jm (joint-index :upper-arm-l) 0f0 0f0 0f0) (- x (aref p 0)))))
             (hip (jy :thigh-r)))
        (log-msg "proportions ~a: crown ~,3f m, head ~,3f m (~,2f heads), head width ~,3f m, shoulder joints ~,3f m, ~
fingertips ~,3f m (~,2f of height), hips ~,3f m (legs ~,2f of height), neck gap chin-shoulder ~,3f m"
                 key crown hl (/ crown hl) (* 2 (body-scale b) (first (half skull))) sw tip (/ tip crown) hip (/ hip crown)
                 (- chin (jy :upper-arm-r)))))))

(defun view-debug (c)
  (cond ((>= c 1000000) (multiple-value-bind (i k) (floor (- c 1000000) 1000) (strip i k)))
        ((>= c 900000) (play-live (- c 900000)))
        ((<= 7000 c 7099) (grip-strip (- c 7000)))
        ((>= c 6300) (let ((f (nth (min 2 (- c 6300)) '(:neutral :shout :hurt)))) (dolist (a *actors*) (setf (actor-face a) f))))
        ((>= c 6210) (face-cam (- c 6210) 35))
        ((>= c 6200) (face-cam (- c 6200) 0))
        ((>= c 6100) (close-up (- c 6100) t))
        ((>= c 6000) (close-up (- c 6000) nil))
        ((>= c 5000) (let ((k (nth (- c 5000) (list-sounds))))
                       (when k (log-msg "view: play sound ~d ~a" (- c 5000) k)
                         (if (sound-loop-p k) (music-play k) (play-sfx k :pitch-jitter 0.0)))))
        ((<= 4100 c 4119)
         (let* ((k (mod (- c 4100) 10)) (back (>= c 4110)) (w (nth (mod k 3) '(:ken-katana :nozarashi :ke-broken)))
                (s (if back -1f0 1f0)) (m *v-weapon-m*))
           (fill m 0f0)
           (setf (aref m 2) s (aref m 4) s (aref m 9) 1f0 (aref m 15) 1f0      ; x -> +-z, y -> +-x, z -> y
                 (aref m 12) (* s -0.47) (aref m 13) 1.0)
           (setf *v-weapon* w *v-hide-actors* t *v-stage* nil *v-label* (format nil "WEAPON ~a~:[~; (OTHER FACE)~]" w back))
           (look-at 0 1.0 3.3 0 1.0 0)))
        ((= c 4004) (setf *v-hide-actors* (not *v-hide-actors*)))
        ((= c 4005) (dolist (k '(:yamamoto :kenpachi)) (measure-body k)))
        ((= c 4003) (stage-clear-cracks))
        ((= c 4002) (stage-crack-add -2.5 0.5 2.2) (stage-crack-add 1.0 -1.5 3.0) (stage-crack-add 3.5 2.0 1.6))
        ((= c 4001) (setf *v-spin* (not *v-spin*)))
        ((= c 4000) (setf *v-stage* (not *v-stage*)))
        ((>= c 3000) (setf *v-yaw* (deg (- c 3000))))
        ((>= c 2000) (scene (- c 2000)))))

(defun view-start ()
  (stage-env)
  (loop for n in (clip-names) for i from 0
        do (log-msg "clip ~d ~a ~,3f~@[ S/A/R ~{~d~^/~}~]" i n (clip-dur (find-clip n)) (strike-sar n)))
  (scene 0))

(defun view-keys ()
  (loop for k in '(:1 :2 :3 :4 :5) for i from 0 do (when (key-pressed k) (scene i)))
  (when (key-pressed :space) (setf *v-spin* (not *v-spin*)))
  (when (key-pressed :g) (setf *v-stage* (not *v-stage*)))
  (when (key-pressed :n) (strip (1+ *v-clip*)))
  (when (key-pressed :p) (strip (1- *v-clip*)))
  (when (key-down :left) (setf *v-yaw* (- *v-yaw* (* 2.0 (frame-dt)))))
  (when (key-down :right) (setf *v-yaw* (+ *v-yaw* (* 2.0 (frame-dt))))))

(defun view-frame (rdt)
  (view-keys)
  (when *v-spin* (setf *v-yaw* (+ *v-yaw* (* 0.8 rdt))))
  (apply #'camera-look-at *v-cam*)
  (perf-mark)
  (dolist (a (unless *v-hide-actors* *actors*))
    (let ((an (actor-anim a)) (b (actor-body a)))
      (if (>= (actor-frame a) 0)
          (setf (anim-time an) (/ (actor-frame a) 60.0))
          (progn (anim-advance an (f32 rdt))
                 (let ((c (anim-clip an)))
                   (when (and (not (clip-loop c)) (> (anim-time an) (+ 0.6 (clip-dur c))))
                     (setf (anim-time an) 0.0)))))
      (pose-fk! (actor-joints a) (anim-eval an) (actor-x a) 0.0 (actor-z a) (+ (actor-yaw a) *v-yaw*)
                (body-scale b) (body-hunch b) (body-props b))
      (when (actor-grip a) (grip-left! (actor-joints a) *v-one*))
      (draw-body b (actor-joints a) (actor-x a) 0.0 (actor-z a) (actor-yaw a)
                 :weapon (actor-weapon a) :hide (actor-hide a) :face (actor-face a) :tint (actor-tint a) :rim (actor-rim a))))
  (when *v-weapon* (draw-weapon *v-weapon* *v-weapon-m*))
  (perf-mark)
  (when *v-stage* (stage-draw rdt))
  (fx-update (f32 rdt))
  (fx-draw-particles)
  (fx-rings-update (f32 rdt))
  (let ((s (ui-scale)))
    (ui-text *v-label* (* 10 s) (* 10 s) :scale s :shadow t)))

(run-game :title "SOUL DUEL VIEW"
          :load (append (list #'bodies-init) (body-load-steps) (list #'stage-init))
          :start #'view-start
          :frame #'view-frame
          :debug #'view-debug)
