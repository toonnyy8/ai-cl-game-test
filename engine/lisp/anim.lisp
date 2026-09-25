;;;; anim.lisp — humanoid rig (GAME_DESIGN §11), poses in f32vecs, keyframe clips with per-key
;;;; easing, crossfade blending and allocation-free forward kinematics.
;;;; The pose / clip library itself is game data (DEFPOSE / DEFCLIP, e.g. game/lisp/clips.lisp);
;;;; DEFCLIP's default base pose is the one named :STANCE, so a game defines that one first.
;;;;
;;;; Pose layout (f32vec of +POSE-N+ floats, radians / metres):
;;;;   joint j: [3j] flex, [3j+1] twist, [3j+2] side      (§11.2 channel meanings)
;;;;   [63] root r, [64] root u, [65] root f (m), [66] root yaw, [67] root pitch (rad)
;;;; Engine space: character fwd = -Z, right = +X, up = +Y.
(in-package :engine)

;;; ---------------------------------------------------------------- rig
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *rig*
    ;; name parent (r u f) flex-sign mirror      (flex sign: + = Rx(+) swings a DOWN bone forward)
    '((:pelvis nil (0 0 0) -1 1)
      (:spine :pelvis (0 0.08 0) -1 1)
      (:chest :spine (0 0.22 0) -1 1)
      (:neck :chest (0 0.20 0) -1 1)
      (:head :neck (0 0.08 0) -1 1)
      (:shoulder-r :chest (0.20 0.14 0) 1 1)
      (:upper-arm-r :shoulder-r (0.02 0 0) 1 1)
      (:lower-arm-r :upper-arm-r (0 -0.30 0) 1 1)
      (:hand-r :lower-arm-r (0 -0.27 0) 1 1)
      (:weapon-r :hand-r (0 -0.05 0) 1 1)
      (:shoulder-l :chest (-0.20 0.14 0) 1 -1)
      (:upper-arm-l :shoulder-l (-0.02 0 0) 1 -1)
      (:lower-arm-l :upper-arm-l (0 -0.30 0) 1 -1)
      (:hand-l :lower-arm-l (0 -0.27 0) 1 -1)
      (:weapon-l :hand-l (0 -0.05 0) 1 -1)
      (:thigh-r :pelvis (0.10 -0.05 0) 1 1)
      (:shin-r :thigh-r (0 -0.44 0) -1 1)
      (:foot-r :shin-r (0 -0.43 0) 1 1)
      (:thigh-l :pelvis (-0.10 -0.05 0) 1 -1)
      (:shin-l :thigh-l (0 -0.44 0) -1 -1)
      (:foot-l :shin-l (0 -0.43 0) 1 -1)))
  (defparameter *joint-alias*
    '((:arm-r :upper-arm-r) (:arm-l :upper-arm-l) (:elbow-r :lower-arm-r) (:elbow-l :lower-arm-l)
      (:knee-r :shin-r) (:knee-l :shin-l)
      (:arms :upper-arm-r :upper-arm-l) (:elbows :lower-arm-r :lower-arm-l) (:hands :hand-r :hand-l)
      (:thighs :thigh-r :thigh-l) (:knees :shin-r :shin-l) (:feet :foot-r :foot-l)))
  (defun joint-index (name)
    (or (position name *rig* :key #'first) (error "unknown joint ~s" name)))
  (defun joint-mask (&rest names)
    (let ((m 0)) (dolist (n names m) (setf m (logior m (ash 1 (joint-index n))))))))

(defmacro ji (name) "Joint index, resolved at compile time." (joint-index name))
(defconstant +nj+ 21)
(defconstant +pose-n+ 68)
(defconstant +root+ 63)

(declaim (type (simple-array fixnum (*)) *rig-parent*) (type f32vec *rig-off* *rig-fsign* *rig-mirror*))
(defvar *rig-parent* (make-array +nj+ :element-type 'fixnum :initial-element -1))
(defvar *rig-off* (make-f32 (* 3 +nj+)))     ; engine coords (x=r, y=u, z=-f)
(defvar *rig-fsign* (make-f32 +nj+))
(defvar *rig-mirror* (make-f32 +nj+))
(loop for (name parent (r u f) fs mir) in *rig* for j from 0 do
  (setf (aref *rig-parent* j) (if parent (joint-index parent) -1)
        (aref *rig-off* (* 3 j)) (f32 r) (aref *rig-off* (+ 1 (* 3 j))) (f32 u) (aref *rig-off* (+ 2 (* 3 j))) (f32 (- f))
        (aref *rig-fsign* j) (f32 fs) (aref *rig-mirror* j) (f32 mir)))

;;; ---------------------------------------------------------------- poses (setup-time DSL)
;;; spec = (group chan val chan val ...). Group: joint name, alias (:arm-r :knees ...) or :root.
;;; Joint channels :flex :twist :side in degrees. Root channels :r :u :f (m) :yaw :pitch (deg).
(defvar *poses* (make-hash-table :test 'eq))

(defun spec-joints (g)
  (let ((a (assoc g *joint-alias*))) (if a (mapcar #'joint-index (rest a)) (list (joint-index g)))))

(defun apply-spec! (pose spec)
  (declare (type f32vec pose))
  (destructuring-bind (group &rest kv) spec
    (loop for (ch v) on kv by #'cddr do
      (if (eq group :root)
          (setf (aref pose (+ +root+ (ecase ch (:r 0) (:u 1) (:f 2) (:yaw 3) (:pitch 4))))
                (if (member ch '(:yaw :pitch)) (deg v) (f32 v)))
          (dolist (j (spec-joints group))
            (setf (aref pose (+ (* 3 j) (ecase ch (:flex 0) (:twist 1) (:side 2)))) (deg v))))))
  pose)

(defun find-pose (name) (or (gethash name *poses*) (error "unknown pose ~s" name)))

(defmacro defpose (name (&key base) &body specs)
  `(setf (gethash ,name *poses*)
         (let ((p ,(if base `(copy-seq (find-pose ,base)) `(make-f32 +pose-n+))))
           (dolist (s ',specs p) (apply-spec! p s)))))

;;; ---------------------------------------------------------------- clips
(defstruct (clip (:constructor %make-clip))
  (name nil)
  (dur 1f0 :type single-float)
  (loop nil)
  (n 0 :type fixnum)
  (times (make-f32 1) :type f32vec)
  (snaps (make-f32 1) :type f32vec)   ; 1.0 = key reached with a linear snap
  (poses (make-f32 1) :type f32vec)   ; n x +pose-n+
  (marks nil))                        ; plist: mark name -> seconds (DEFCLIP :MARKS)

(defvar *clips* (make-hash-table :test 'eq))
(defun find-clip (name &optional (errorp t))
  "The clip named NAME; unknown: an error, or NIL when ERRORP is NIL (e.g. art not written yet)."
  (or (gethash name *clips*) (and errorp (error "unknown clip ~s" name))))
(defun list-clips ()
  "Names of every defined clip, sorted alphabetically (viewers, tests)."
  (sort (loop for k being the hash-keys of *clips* collect k) #'string< :key #'symbol-name))
(defun clip-mark (clip name)
  "Time in seconds of mark NAME of CLIP (a clip or its name), :END = its duration; NIL if unknown."
  (let ((c (if (clip-p clip) clip (find-clip clip))))
    (if (eq name :end) (clip-dur c) (getf (clip-marks c) name))))

(defun build-clip (name dur loop base keys &key fps marks)
  "KEYS: list of (time [:snap] [pose-name] spec...). Each key starts from the previous key's
pose (the first from BASE); a pose-name keyword resets it to that named pose. FPS: DUR, key times
and MARKS are frames at FPS per second. A key time may also be a MARKS name or :END (= DUR)."
  (let* ((sec (lambda (x) (if fps (/ (f32 x) (f32 fps)) (f32 x))))   ; single-float frame / fps
         (marks (loop for (k v) on marks by #'cddr append (list k (funcall sec v))))
         (dur (funcall sec dur))
         (cur (copy-seq (find-pose base))) (acc nil))
    (dolist (k keys)
      (let ((snap nil) (tm (first k)))
        (dolist (e (rest k))
          (cond ((eq e :snap) (setf snap t))
                ((keywordp e) (setf cur (copy-seq (find-pose e))))
                (t (apply-spec! cur e))))
        (push (list (cond ((numberp tm) (funcall sec tm)) ((eq tm :end) dur)
                          (t (or (getf marks tm) (error "clip ~s: unknown key time ~s" name tm))))
                    snap (copy-seq cur))
              acc)))
    (setf acc (nreverse acc))
    (when (and loop (< (first (car (last acc))) (f32 dur)))
      (setf acc (append acc (list (list (f32 dur) nil (third (first acc)))))))
    (let* ((n (length acc)) (c (%make-clip :name name :dur (f32 dur) :loop loop :n n :marks marks
                                           :times (make-f32 n) :snaps (make-f32 n) :poses (make-f32 (* n +pose-n+)))))
      (loop for (tm snap p) in acc for i from 0 do
        (setf (aref (clip-times c) i) tm (aref (clip-snaps c) i) (if snap 1f0 0f0))
        (replace (clip-poses c) p :start1 (* i +pose-n+)))
      (setf (gethash name *clips*) c))))

(defmacro defclip (name (dur &key loop (base :stance) fps marks) &body keys)
  "Keyframe clip. Keys: (time [:snap] [pose-name] (group chan val ...) ...). See §11.2.
DUR and key times are seconds, or frames with :FPS n (e.g. :fps 60 to match move frame data).
MARKS: plist of named times in the same unit, e.g. (:hit 7 :recover 10); a key's time may be a mark
name or :END (= DUR), and (CLIP-MARK clip :hit) returns it in seconds. An attack in frames:
  (defclip :q1 (22 :fps 60 :base :my-stance :marks (:hit 7 :recover 10))
    (4 (:arm-r :flex 120)) (:hit :snap (:arm-r :flex -30)) (:recover (:arm-r :flex -40)) (:end :my-stance))"
  `(build-clip ,name ,dur ,loop ,base ',keys :fps ,fps :marks ',marks))

;;; DEFSTRIKE: the attack-clip form of DEFCLIP, timed by a move's startup / active / recovery frames.
(defmacro defstrike (name (s a r &key (base :stance)) &body keys)
  "An attack clip timed to its move's frame data (60 Hz): the hit pose lands at frame S, the
follow-through holds through S+A, and the character is back in BASE at S+A+R (the clip's end).
KEYS are DEFCLIP keys whose time is a frame number or :S / :A (= S+A) / :END (= S+A+R); the
last key is usually (:end BASE-POSE). DEFCLIP :fps 60 with marks :s / :a; (CLIP-MARK clip :s)
reads them back in seconds."
  `(defclip ,name (,(+ s a r) :fps 60 :base ,base :marks (:s ,s :a ,(+ s a))) ,@keys))

(defvar *key-ease* 0
  "How CLIP-SAMPLE! eases between two keys that are not :SNAP: 0 (default, RAVEN) smoothstep, 1 ease-out
cubic 1-(1-u)^3 (the pose snaps into the key and settles: pose-to-pose timing, SOUL DUEL).")
(declaim (type fixnum *key-ease*))

(defun-fast clip-sample! (out clip time)
  "Sample CLIP at TIME (seconds; wraps for loops, clamps otherwise) into pose OUT."
  (declare (type f32vec out) (single-float time))
  (let* ((times (clip-times clip)) (snaps (clip-snaps clip)) (poses (clip-poses clip))
         (n (clip-n clip)) (dur (clip-dur clip)) (tm time))
    (declare (type f32vec times snaps poses) (fixnum n) (single-float dur tm))
    (when (clip-loop clip)
      (setf tm (f-mod tm dur))
      (when (< tm 0f0) (setf tm (+ tm dur))))
    (cond ((or (= n 1) (<= tm (aref times 0))) (replace out poses :end2 +pose-n+))
          ((>= tm (aref times (1- n))) (replace out poses :start2 (* (1- n) +pose-n+)))
          (t (let* ((i 0))
               (declare (fixnum i))
               (loop while (and (< (+ i 2) n) (>= tm (aref times (1+ i)))) do (incf i))
               (let* ((t0 (aref times i)) (t1 (aref times (1+ i)))
                      (u (/ (- tm t0) (f-max 1f-5 (- t1 t0))))
                      (w (cond ((> (aref snaps (1+ i)) 0.5f0) u)
                               ((> (the fixnum *key-ease*) 0) (- 1f0 (* (- 1f0 u) (- 1f0 u) (- 1f0 u))))   ; ease-out cubic
                               (t (* u u (- 3f0 (* 2f0 u))))))
                      (oa (* i +pose-n+)) (ob (+ oa +pose-n+)))
                 (declare (single-float t0 t1 u w) (fixnum oa ob))
                 (dotimes (c +pose-n+)
                   (let* ((a (aref poses (+ oa c))))
                     (declare (single-float a))
                     (setf (aref out c) (+ a (* w (- (aref poses (+ ob c)) a))))))))))
    out))

;;; ---------------------------------------------------------------- playback + crossfade
(defstruct (anim (:constructor make-anim ()))
  (clip nil)
  (time 0f0 :type single-float)
  (speed 1f0 :type single-float)
  (blend 0f0 :type single-float)        ; seconds of crossfade left
  (blend-dur 0f0 :type single-float)
  (from (make-f32 +pose-n+) :type f32vec)
  (pose (make-f32 +pose-n+) :type f32vec)
  (tmp (make-f32 +pose-n+) :type f32vec))

(defun anim-play (an name &key (blend 4f0) (speed 1f0) (time 0f0) (restart t))
  "Start clip NAME. BLEND is the crossfade in frames (60 Hz); 0 = snap (attacks). With
RESTART NIL, keeps playing when NAME is already the current clip."
  (let ((c (find-clip name)))
    (unless (and (not restart) (eq c (anim-clip an)))
      (let ((from (anim-from an)) (pose (anim-pose an)))
        (replace from pose)
        ;; spins author root yaw past 360: wrap so the fade takes the short way
        (setf (aref from (+ +root+ 3)) (f-wrap (aref from (+ +root+ 3)))
              (aref from (+ +root+ 4)) (f-wrap (aref from (+ +root+ 4)))))
      (setf (anim-clip an) c (anim-time an) (f32 time)
            (anim-blend-dur an) (/ (f32 blend) 60f0) (anim-blend an) (/ (f32 blend) 60f0)))
    (setf (anim-speed an) (f32 speed))
    an))

(defun-fast anim-advance (an dt)
  (declare (single-float dt))
  (setf (anim-time an) (+ (the single-float (anim-time an)) (* dt (the single-float (anim-speed an))))
        (anim-blend an) (f-max 0f0 (- (the single-float (anim-blend an)) dt))))

(defun-fast anim-eval (an)
  "Sample the current clip (+ crossfade) into (ANIM-POSE AN)."
  (let* ((pose (anim-pose an)) (tmp (anim-tmp an)) (from (anim-from an))
         (bl (anim-blend an)) (bd (anim-blend-dur an)))
    (declare (type f32vec pose tmp from) (single-float bl bd))
    (when (anim-clip an)
      (clip-sample! tmp (anim-clip an) (anim-time an))
      (if (and (> bl 0f0) (> bd 0f0))
          (let* ((u (- 1f0 (/ bl bd))) (w (* u u (- 3f0 (* 2f0 u)))))
            (declare (single-float u w))
            (dotimes (c +pose-n+)
              (let* ((a (aref from c))) (declare (single-float a))
                (setf (aref pose c) (+ a (* w (- (aref tmp c) a)))))))
          (replace pose tmp)))
    pose))

;;; ---------------------------------------------------------------- forward kinematics
;;; Joint matrices: f32vec of +NJ+ x 16 (column-major world matrices).
(defmacro %euler! (m o px py pz yaw pitch roll s)
  "Write T(p) * Ry(yaw) * Rx(pitch) * Rz(roll) * S(s) into M at offset O (inline, no calls)."
  `(let* ((cy (f-cos ,yaw)) (sy (f-sin ,yaw)) (cp (f-cos ,pitch)) (sp (f-sin ,pitch))
          (cr (f-cos ,roll)) (sr (f-sin ,roll)) (ss ,s) (o ,o))
     (declare (single-float cy sy cp sp cr sr ss) (fixnum o))
     (setf (aref ,m o) (* ss (+ (* cy cr) (* sy sp sr))) (aref ,m (+ o 1)) (* ss cp sr)
           (aref ,m (+ o 2)) (* ss (- (* cy sp sr) (* sy cr))) (aref ,m (+ o 3)) 0f0
           (aref ,m (+ o 4)) (* ss (- (* sy sp cr) (* cy sr))) (aref ,m (+ o 5)) (* ss cp cr)
           (aref ,m (+ o 6)) (* ss (+ (* sy sr) (* cy sp cr))) (aref ,m (+ o 7)) 0f0
           (aref ,m (+ o 8)) (* ss sy cp) (aref ,m (+ o 9)) (* ss (- sp))
           (aref ,m (+ o 10)) (* ss cy cp) (aref ,m (+ o 11)) 0f0
           (aref ,m (+ o 12)) ,px (aref ,m (+ o 13)) ,py (aref ,m (+ o 14)) ,pz (aref ,m (+ o 15)) 1f0)))

(defmacro %affine-mul! (out oo a oa b ob)
  "OUT[oo] = A[oa] * B[ob] for affine column-major 4x4s. OUT must not overlap A or B."
  `(let* ((oo ,oo) (oa ,oa) (ob ,ob))
     (declare (fixnum oo oa ob))
     (dotimes (c 4)
       (let* ((b0 (aref ,b (+ ob (* c 4)))) (b1 (aref ,b (+ ob (* c 4) 1))) (b2 (aref ,b (+ ob (* c 4) 2)))
              (b3 (aref ,b (+ ob (* c 4) 3))))
         (declare (single-float b0 b1 b2 b3))
         (dotimes (r 3)
           (setf (aref ,out (+ oo (* c 4) r))
                 (+ (* (aref ,a (+ oa r)) b0) (* (aref ,a (+ oa 4 r)) b1) (* (aref ,a (+ oa 8 r)) b2)
                    (* (aref ,a (+ oa 12 r)) b3))))
         (setf (aref ,out (+ oo (* c 4) 3)) b3)))))

(defmacro %joint-rot! (m px py pz tw fl sd)
  "Write T(p) * Rz(side) * Rx(flex) * Ry(twist) into M[0..15]: twist about the bone first,
then flex, then side, in the parent's axes (§11.2)."
  `(let* ((ca (f-cos ,fl)) (sa (f-sin ,fl)) (cb (f-cos ,tw)) (sb (f-sin ,tw)) (cc (f-cos ,sd)) (sc (f-sin ,sd)))
     (declare (single-float ca sa cb sb cc sc))
     (setf (aref ,m 0) (- (* cc cb) (* sc sa sb)) (aref ,m 1) (+ (* sc cb) (* cc sa sb)) (aref ,m 2) (- (* ca sb))
           (aref ,m 3) 0f0
           (aref ,m 4) (- (* sc ca)) (aref ,m 5) (* cc ca) (aref ,m 6) sa (aref ,m 7) 0f0
           (aref ,m 8) (+ (* cc sb) (* sc sa cb)) (aref ,m 9) (- (* sc sb) (* cc sa cb)) (aref ,m 10) (* ca cb)
           (aref ,m 11) 0f0
           (aref ,m 12) ,px (aref ,m 13) ,py (aref ,m 14) ,pz (aref ,m 15) 1f0)))

(declaim (type f32vec *fk-a* *fk-b*))
(defvar *fk-a* (make-f32 16))
(defvar *fk-b* (make-f32 16))

;;; Rig proportions: an f32vec of the +NJ+ x 3 bone offsets (the *RIG-OFF* layout) + the pelvis height,
;;; made once by MAKE-RIG-PROPORTIONS and passed to POSE-FK! (NIL = the standard rig).
(defconstant +rig-props-n+ (1+ (* 3 +nj+)))

(defun make-rig-proportions (&key (shoulders 1) (arms 1) (legs 1) (spine 1))
  "Per-chain proportions for POSE-FK!, multipliers of the standard rig (1 = unchanged; POSE-FK!'s
uniform SCALE still applies on top). SHOULDERS: shoulder width (a broad chest pushes the arms out
of a wide sleeve / haori); ARMS: upper arm + forearm length; LEGS: thigh + shin length, and the
pelvis rises or sinks with them so the feet stay on the ground; SPINE: pelvis-to-neck length.
Bones get longer, meshes do not stretch: parts are rigid in their joint's frame. Setup-time
(allocates): make one per body and keep it."
  (let ((v (make-f32 +rig-props-n+)))
    (replace v *rig-off*)
    (flet ((stretch (joints axis k)
             (dolist (j joints)
               (let ((i (+ (* 3 (joint-index j)) axis))) (setf (aref v i) (* (aref v i) (f32 k)))))))
      (stretch '(:shoulder-r :shoulder-l :upper-arm-r :upper-arm-l) 0 shoulders)   ; x
      (stretch '(:lower-arm-r :lower-arm-l :hand-r :hand-l) 1 arms)                ; y (down the bone)
      (stretch '(:shin-r :shin-l :foot-r :foot-l) 1 legs)
      (stretch '(:spine :chest :neck) 1 spine))
    ;; standard pelvis height 0.98 = 0.05 hip + 0.44 thigh + 0.43 shin + ~0.06 foot
    (setf (aref v (* 3 +nj+)) (f32 (+ 0.98 (* 0.87 (- legs 1)))))
    v))

(defun-fast %pose-fk! (jm pose px py pz yaw scale hunch props)
  "POSE-FK! with its optional argument made positional (see POSE-FK!)."
  (declare (type f32vec jm pose) (single-float px py pz yaw scale hunch))
  (when props
    (unless (and (f32vec-p props) (= (length (the f32vec props)) +rig-props-n+))
      (error "pose-fk!: ~s is not a MAKE-RIG-PROPORTIONS vector" props)))
  (let* ((la *fk-a*) (lb *fk-b*) (par *rig-parent*) (off (if props props *rig-off*)) (fs *rig-fsign*) (mir *rig-mirror*)
         (ph (if props (aref (the f32vec props) (* 3 +nj+)) 0.98f0)))
    (declare (type f32vec la lb off fs mir) (type (simple-array fixnum (*)) par) (single-float ph))
    ;; root: T(p) Ry(yaw + root yaw) S(scale) · T(root r, pelvis height + u, -f) Rx(-root pitch) · pelvis channels
    (%euler! la 0 px py pz (+ yaw (aref pose 66)) 0f0 0f0 scale)
    (%euler! lb 0 (aref pose 63) (+ ph (aref pose 64)) (- (aref pose 65)) 0f0 (- (aref pose 67)) 0f0 1f0)
    (%affine-mul! jm 0 la 0 lb 0)
    (replace la jm :end2 16)
    (%joint-rot! lb 0f0 0f0 0f0 (aref pose 1) (- (aref pose 0)) (aref pose 2))
    (%affine-mul! jm 0 la 0 lb 0)
    (loop for j fixnum from 1 below +nj+ do
      (let* ((p (aref par j)) (m (aref mir j)) (o3 (* 3 j))
             (fl (* (aref fs j) (aref pose o3)))
             (tw (* m (aref pose (+ o3 1))))
             (sd (* m (aref pose (+ o3 2)))))
        (declare (fixnum p o3) (single-float m fl tw sd))
        (when (= j 1) (setf fl (- fl hunch)))
        (when (or (= j 17) (= j 20))       ; foot: cancel pelvis + thigh + knee pitch
          (let* ((tj (* 3 (- j 2))) (kj (* 3 (- j 1))))
            (declare (fixnum tj kj))
            (setf fl (+ fl (aref pose 0) (- (aref pose tj)) (aref pose kj)))))
        (%joint-rot! lb (aref off o3) (aref off (+ o3 1)) (aref off (+ o3 2)) tw fl sd)
        (%affine-mul! jm (* j 16) jm (* p 16) lb 0)))
    jm))

(defun pose-fk! (jm pose px py pz yaw scale hunch &optional props)
  "World matrix per joint into JM from POSE, character at (px py pz) facing YAW, uniform rig
SCALE. HUNCH (rad) adds spine flex. Feet are auto-levelled against thigh/knee/pelvis flex.
PROPS: NIL (the standard rig) or a MAKE-RIG-PROPORTIONS vector (per-chain bone lengths).
A direct call compiles to %POSE-FK! (compiler macro): no optional-argument parsing."
  (%pose-fk! jm pose px py pz yaw scale hunch props))
(eval-when (:compile-toplevel :load-toplevel :execute)   ; ECL: else not seen by the compiler
  (define-compiler-macro pose-fk! (jm pose px py pz yaw scale hunch &optional props)
    `(%pose-fk! ,jm ,pose ,px ,py ,pz ,yaw ,scale ,hunch ,props)))

(defun-fast joint-point! (out jm j lx ly lz)
  "OUT = world position of local point (lx ly lz) in joint J's frame."
  (declare (type f32vec out jm) (fixnum j) (single-float lx ly lz))
  (let* ((o (* j 16)))
    (declare (fixnum o))
    (setf (aref out 0) (+ (* (aref jm o) lx) (* (aref jm (+ o 4)) ly) (* (aref jm (+ o 8)) lz) (aref jm (+ o 12)))
          (aref out 1) (+ (* (aref jm (+ o 1)) lx) (* (aref jm (+ o 5)) ly) (* (aref jm (+ o 9)) lz) (aref jm (+ o 13)))
          (aref out 2) (+ (* (aref jm (+ o 2)) lx) (* (aref jm (+ o 6)) ly) (* (aref jm (+ o 10)) lz) (aref jm (+ o 14))))
    out))
