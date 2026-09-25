;;;; duel-view.lisp — SOUL DUEL art viewer: both characters (every form and weapon), the skeleton,
;;;; clip strips, the stage, and every sound. A test target, not part of the game:
;;;;   ./build.sh duelview duel/lisp/package.lisp duel/lisp/body.lisp duel/lisp/yama-art.lisp \
;;;;     duel/lisp/ken-art.lisp duel/lisp/sounds.lisp duel/lisp/stage.lisp tests/duel-view.lisp
;;;;   python3 tests/scripts/duel-view.py   (writes tests/scripts/duel-view-*.json, see its header)
;;;;   node tools/run.mjs dist/duelview --secs 60 --script tests/scripts/duel-view-looks.json
;;;; Keys: 1-5 scenes, LEFT/RIGHT turn, SPACE spin, N/P next/previous clip strip, G stage on/off.
;;;; Debug commands (Module._debug_cmd):
;;;;   2000+k  scene k: 0 base forms, 1 awakened forms, 2 cane + skeletons, 3 mirror match, 4 duel on the stage
;;;;   6000+i / 6100+i / 6200+i  camera on actor i: full body / head and chest / face (0.7 m, eye level);
;;;;   6210+i  the face from 35 degrees to its left
;;;;   3000+d  turntable angle d degrees (0 = facing the camera)     4000 stage off/on   4001 spin on/off
;;;;   4002 / 4003  add three Bankai cracks / clear them    4004 actors off/on (cons baseline)
;;;;   4005  log every body's proportions (standing, no hunch): crown, head length, heads, head width,
;;;;         shoulder span, fingertips, hips (legs / height), from the joints and the shape extents
;;;;   5000+i  play sound i (LIST-SOUNDS order) and log it
;;;;   1000000+1000*i  strip of clip i (clips sorted by name): the owner posed at 4 frames side by side
;;;;           (0, S, S+A, end for DEFSTRIKE clips; 0, 1/3, 2/3, end otherwise; :sh- clips on both)
;;;;   900000+i  play clip i live (looping) on the current scene's matching actors
(in-package :duel)

(setf *audio-debug* t *stats-log* t)

(defstruct (actor (:constructor %make-actor))
  (body nil) (weapon nil) (hide nil) (tint nil) (rim nil)
  (x 0f0 :type single-float) (z 0f0 :type single-float) (yaw 0f0 :type single-float)
  (anim (make-anim)) (joints (make-f32 (* 16 +nj+)) :type f32vec)
  (frame -1 :type fixnum))                          ; >= 0: frozen at this frame

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
        (awake-ke '(:ke-meteor :ke-kikon-n :ke-nome :ke-n-stance)))
    (cond ((member name awake-ya) '((:yamamoto :zanka nil)))
          ((eq name :ya-intro) '((:yamamoto :ya-cane nil)))
          ((eq name :ya-ikkotsu) '((:yamamoto nil nil)))
          ((prefix-p name "YA-") '((:yamamoto :ryujin-jakka nil)))
          ((member name awake-ke) '((:kenpachi :nozarashi :eyepatch)))
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
                 (make-actor :kenpachi :nozarashi (if (find-clip :ke-n-stance nil) :ke-n-stance :ke-stance)
                             :hide :eyepatch :x 1.1 :yaw pi)))
          (2 (setf *v-label* "CANE / SKELETONS")
           (list (make-actor :yamamoto :ya-cane (if (find-clip :ya-intro nil) :ya-intro :ya-stance) :x -1.2 :yaw pi :frame 0)
                 (make-actor :skeleton nil (if (find-clip :sk-rise nil) :sk-rise :ya-stance) :x 0.3 :yaw pi :frame 200)
                 (make-actor :skeleton nil (if (find-clip :sk-lunge nil) :sk-lunge :ya-stance) :x 1.5 :yaw pi :frame 12)))
          (3 (setf *v-label* "MIRROR MATCH: P2 TINT + RIM")
           (look-at 0 1.4 7.5 0 1.0 0)
           (list (make-actor :yamamoto :ryujin-jakka :ya-stance :x -2.7 :yaw pi)
                 (make-actor :yamamoto :ryujin-jakka :ya-stance :x -1.0 :yaw pi :tint *mirror-tint* :rim *mirror-rim*)
                 (make-actor :kenpachi :ken-katana :ke-stance :x 0.9 :yaw pi)
                 (make-actor :kenpachi :ken-katana :ke-stance :x 2.8 :yaw pi :tint *mirror-tint* :rim *mirror-rim*)))
          (4 (setf *v-label* "SEIREITEI RUINS AT NIGHT")
           (look-at 7.5 2.6 7.0 0 1.1 -0.5)
           (list (make-actor :yamamoto :ryujin-jakka :ya-stance :x -2.5 :z 0 :yaw (/ pi -2))
                 (make-actor :kenpachi :ken-katana :ke-stance :x 2.5 :z 0 :yaw (/ pi 2)))))))

(defun strip (i)
  "Clip I posed at 4 frames side by side (8 actors for shared clips: Yama row, Ken row)."
  (let* ((names (clip-names)) (i (mod i (length names))) (name (nth i names))
         (clip (find-clip name)) (end (round (* 60 (clip-dur clip))))
         (sar (strike-sar name))
         (frames (if sar
                     (destructuring-bind (s a r) sar (list 0 s (+ s a) (+ s a r)))
                     (list 0 (round end 3) (round (* 2 end) 3) end)))
         (owners (clip-owners name)) (acts nil))
    (setf *v-clip* i *v-yaw* 0.0)
    (loop for (body weapon hide) in owners for row from 0 do
      (loop for f in frames for col from 0 do
        (push (make-actor body weapon name :hide hide :frame f :x (* 1.7 (- col 1.5))
                          :z (* -3.4 row) :yaw (- (/ pi -2) 0.45))
              acts)))
    (setf *actors* (nreverse acts)
          *v-label* (format nil "~d ~a  ~,2f S  FRAMES ~{~d~^ ~}~@[  S/A/R ~{~d~^/~}~]" i name (clip-dur clip) frames sar))
    (if (cdr owners) (look-at 0 3.4 6.8 0 0.7 -1.7) (look-at 0 1.3 5.0 0 1.0 0))
    (log-msg "view: strip ~a" *v-label*)))

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
  (cond ((>= c 1000000) (strip (floor (- c 1000000) 1000)))
        ((>= c 900000) (play-live (- c 900000)))
        ((>= c 6210) (face-cam (- c 6210) 35))
        ((>= c 6200) (face-cam (- c 6200) 0))
        ((>= c 6100) (close-up (- c 6100) t))
        ((>= c 6000) (close-up (- c 6000) nil))
        ((>= c 5000) (let ((k (nth (- c 5000) (list-sounds))))
                       (when k (log-msg "view: play sound ~d ~a" (- c 5000) k)
                         (if (sound-loop-p k) (music-play k) (play-sfx k :pitch-jitter 0.0)))))
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
      (draw-body b (actor-joints a) (actor-x a) 0.0 (actor-z a) (actor-yaw a)
                 :weapon (actor-weapon a) :hide (actor-hide a) :tint (actor-tint a) :rim (actor-rim a))))
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
