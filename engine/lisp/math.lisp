;;;; math.lisp — scalars, facing angles, vec3 / mat4 on (simple-array single-float (*)). Pure CL
;;;; (host-loadable: tests load it natively; YAW-TO is the one C-inline call, never used there).
;;;; Conventions: Y up, right-handed, meters, radians.
;;;;   vec3 = 3 floats, mat4 = 16 floats COLUMN-MAJOR
;;;;   (element row r, col c at index c*4+r — same layout WGSL mat4x4f uses).
;;;; Functions ending in ! write into their first argument (OUT) and return it;
;;;; they never allocate. OUT may alias an input unless noted.
(in-package :engine)

(defmacro fv (&rest xs)
  "Fresh single-float vector with the given contents."
  `(let* ((v (make-array ,(length xs) :element-type 'single-float)))
     ,@(loop for x in xs for i from 0 collect `(setf (aref v ,i) (float ,x 1f0)))
     v))

(declaim (inline make-f32 v3 v3-set! v3-copy! v3-dot v3-len v3-len2 v3-dist deg
                 v3-add! v3-sub! v3-scale! v3-madd! v3-lerp! v3-cross! v3-normalize!
                 angle-wrap angle-lerp approach smoothstep))

(defun-fast make-f32 (n) (make-array n :element-type 'single-float :initial-element 0f0))
(defun-fast deg (d) (* (float d 1f0) #.(float (/ pi 180) 1f0)))

;;; ---------------------------------------------------------------- scalars
(defun-fast angle-wrap (a)
  "Wrap angle into [-pi, pi)."
  (declare (single-float a))
  (let* ((tau #.(float (* 2 pi) 1f0)))
    (- a (* tau (ffloor (+ a #.(float pi 1f0)) tau)))))
(defun-fast angle-lerp (a b u)
  "Interpolate angles along the shortest arc."
  (declare (single-float a b u))
  (+ a (* (angle-wrap (- b a)) u)))
(defun-fast approach (x target step)
  "Move X toward TARGET by at most STEP."
  (declare (single-float x target step))
  (if (< x target) (min target (+ x step)) (max target (- x step))))
(defun-fast smoothstep (e0 e1 x)
  (declare (single-float e0 e1 x))
  (let* ((u (max 0f0 (min 1f0 (/ (- x e0) (- e1 e0))))))
    (* u u (- 3f0 (* 2f0 u)))))
(defmacro hypot (a b &optional c)
  "Length of (A B [C]) with CL's SQRT: exactly (SQRT (+ (* A A) (* B B) [(* C C)])), the sim's float order (a macro, so
the native sim and wasm compile the same operations). Symbols and literals are used as they are; any other form is
bound once, in order. F-HYPOT (package.lisp) is the F-SQRT twin: never swap one for the other at a site."
  (%hypot-form 'sqrt (if c (list a b c) (list a b)) nil))
(defmacro countdown! (place dt)
  "Run the timer PLACE down by DT, stopping at 0: (SETF PLACE (F32 (MAX 0.0 (- PLACE DT)))). PLACE is evaluated twice
(keep it free of side effects)."
  `(setf ,place (f32 (max 0.0 (- ,place ,dt)))))

;;; ---------------------------------------------------------------- facing (yaw on the ground plane)
;;; A character's facing is one angle, YAW, about +Y. Yaw 0 faces -Z; the facing direction is
;;; (FWD-X yaw, 0, FWD-Z yaw) = (-sin yaw, 0, -cos yaw).
(declaim (inline fwd-x fwd-z))
(defun-fast fwd-x (yaw) "X of the facing (forward) direction of YAW." (declare (single-float yaw)) (- (sin yaw)))
(defun-fast fwd-z (yaw) "Z of the facing (forward) direction of YAW." (declare (single-float yaw)) (- (cos yaw)))
(defun-fast yaw-to (dx dz)
  "The yaw that faces direction (DX DZ) (float atan2: plain C, no consing)."
  (declare (single-float dx dz))
  (f-atan2 (- dx) (- dz)))
(defun turn-toward (cur target step)
  "Angle CUR turned toward TARGET by at most STEP radians (the short way round)."
  (let ((d (angle-wrap (f32 (- target cur)))))
    (f32 (+ cur (clamp d (- step) step)))))

(defun weighted-pick (r &rest kv)
  "KV = key weight ...; the key whose share of the total weight contains R (0 <= R < 1). NIL keys
are allowed (\"do nothing\"); NIL if all weights are 0. For AI choices: pass a SIM-RND01 as R."
  (let ((sum 0.0))
    (loop for (nil w) on kv by #'cddr do (incf sum w))
    (when (> sum 0)
      (let ((x (* sum r)))
        (loop for (key w) on kv by #'cddr
              do (decf x w) (when (and (< x 0) (> w 0)) (return key)))))))

;;; ---------------------------------------------------------------- vec3
(defun-fast v3 (x y z)
  (let* ((v (make-array 3 :element-type 'single-float)))
    (setf (aref v 0) (float x 1f0) (aref v 1) (float y 1f0) (aref v 2) (float z 1f0))
    v))
(defun-fast v3-set! (o x y z)
  (declare (type f32vec o) (single-float x y z))
  (setf (aref o 0) x (aref o 1) y (aref o 2) z) o)
(defun-fast v3-copy! (o a)
  (declare (type f32vec o a))
  (setf (aref o 0) (aref a 0) (aref o 1) (aref a 1) (aref o 2) (aref a 2)) o)
(defun-fast v3-add! (o a b)
  (declare (type f32vec o a b))
  (v3-set! o (+ (aref a 0) (aref b 0)) (+ (aref a 1) (aref b 1)) (+ (aref a 2) (aref b 2))))
(defun-fast v3-sub! (o a b)
  (declare (type f32vec o a b))
  (v3-set! o (- (aref a 0) (aref b 0)) (- (aref a 1) (aref b 1)) (- (aref a 2) (aref b 2))))
(defun-fast v3-scale! (o a s)
  (declare (type f32vec o a) (single-float s))
  (v3-set! o (* (aref a 0) s) (* (aref a 1) s) (* (aref a 2) s)))
(defun-fast v3-madd! (o a b s)
  "o = a + b*s"
  (declare (type f32vec o a b) (single-float s))
  (v3-set! o (+ (aref a 0) (* (aref b 0) s)) (+ (aref a 1) (* (aref b 1) s)) (+ (aref a 2) (* (aref b 2) s))))
(defun-fast v3-lerp! (o a b u)
  (declare (type f32vec o a b) (single-float u))
  (v3-set! o (+ (aref a 0) (* (- (aref b 0) (aref a 0)) u))
           (+ (aref a 1) (* (- (aref b 1) (aref a 1)) u))
           (+ (aref a 2) (* (- (aref b 2) (aref a 2)) u))))
(defun-fast v3-dot (a b)
  (declare (type f32vec a b))
  (+ (* (aref a 0) (aref b 0)) (* (aref a 1) (aref b 1)) (* (aref a 2) (aref b 2))))
(defun-fast v3-len2 (a) (declare (type f32vec a)) (v3-dot a a))
(defun-fast v3-len (a) (declare (type f32vec a)) (sqrt (the (single-float 0f0) (v3-dot a a))))
(defun-fast v3-dist (a b)
  (declare (type f32vec a b))
  (let* ((dx (- (aref a 0) (aref b 0))) (dy (- (aref a 1) (aref b 1))) (dz (- (aref a 2) (aref b 2))))
    (sqrt (the (single-float 0f0) (+ (* dx dx) (* dy dy) (* dz dz))))))
(defun-fast v3-cross! (o a b)
  (declare (type f32vec o a b))
  (let* ((ax (aref a 0)) (ay (aref a 1)) (az (aref a 2)) (bx (aref b 0)) (by (aref b 1)) (bz (aref b 2)))
    (v3-set! o (- (* ay bz) (* az by)) (- (* az bx) (* ax bz)) (- (* ax by) (* ay bx)))))
(defun-fast v3-normalize! (o a)
  "o = a/|a| (zero vector stays zero)."
  (declare (type f32vec o a))
  (let* ((l (v3-len a)))
    (if (> l 1f-12) (v3-scale! o a (/ 1f0 l)) (v3-set! o 0f0 0f0 0f0))))

;; allocating conveniences (setup code, not hot loops)
(defun-fast v3-normalize (a) (v3-normalize! (make-f32 3) a))
(defun-fast v3-copy (a) (v3-copy! (make-f32 3) a))

;;; ---------------------------------------------------------------- mat4 (column-major)
(defmacro m@ (m r c) `(aref ,m ,(+ (* c 4) r)))

(defun-fast m4 ()
  "Fresh identity matrix."
  (let* ((m (make-f32 16))) (setf (aref m 0) 1f0 (aref m 5) 1f0 (aref m 10) 1f0 (aref m 15) 1f0) m))
(defun-fast m4-identity! (o)
  (declare (type f32vec o))
  (fill o 0f0) (setf (aref o 0) 1f0 (aref o 5) 1f0 (aref o 10) 1f0 (aref o 15) 1f0) o)
(defun-fast m4-copy! (o a)
  (declare (type f32vec o a))
  (replace o a :end1 16) o)

(defvar *m4-tmp* (make-f32 16))
(defun-fast m4-mul! (o a b)
  "o = a*b (b applied first). O may alias A or B."
  (declare (type f32vec o a b) (optimize (speed 3) (safety 0)))
  (let* ((tmp *m4-tmp*))
    (declare (type f32vec tmp))
    (dotimes (c 4)
      (let* ((b0 (aref b (* c 4))) (b1 (aref b (+ (* c 4) 1))) (b2 (aref b (+ (* c 4) 2))) (b3 (aref b (+ (* c 4) 3))))
        (dotimes (r 4)
          (setf (aref tmp (+ (* c 4) r))
                (+ (* (aref a r) b0) (* (aref a (+ 4 r)) b1) (* (aref a (+ 8 r)) b2) (* (aref a (+ 12 r)) b3))))))
    (replace o tmp :end1 16) o))

(defun-fast m4-translation! (o x y z)
  (declare (type f32vec o) (single-float x y z))
  (m4-identity! o) (setf (aref o 12) x (aref o 13) y (aref o 14) z) o)
(defun-fast m4-euler! (o px py pz yaw pitch roll &optional (sx 1f0) (sy 1f0) (sz 1f0))
  "o = T * R * S with R = Ry(yaw) * Rx(pitch) * Rz(roll).
The workhorse for rigid parts: one call, no allocation."
  (declare (type f32vec o) (single-float px py pz yaw pitch roll sx sy sz))
  (let* ((cy (cos yaw)) (sny (sin yaw)) (cp (cos pitch)) (sp (sin pitch)) (cr (cos roll)) (sr (sin roll)))
    (declare (single-float cy sny cp sp cr sr))
    (setf (m@ o 0 0) (* sx (+ (* cy cr) (* sny sp sr))) (m@ o 1 0) (* sx cp sr) (m@ o 2 0) (* sx (- (* cy sp sr) (* sny cr))) (m@ o 3 0) 0f0
          (m@ o 0 1) (* sy (- (* sny sp cr) (* cy sr))) (m@ o 1 1) (* sy cp cr) (m@ o 2 1) (* sy (+ (* sny sr) (* cy sp cr))) (m@ o 3 1) 0f0
          (m@ o 0 2) (* sz sny cp) (m@ o 1 2) (* sz (- sp)) (m@ o 2 2) (* sz cy cp) (m@ o 3 2) 0f0
          (m@ o 0 3) px (m@ o 1 3) py (m@ o 2 3) pz (m@ o 3 3) 1f0)
    o))

(defun-fast m4-perspective! (o fovy aspect near far)
  "WebGPU clip space (z in [0,1]: near -> 0, far -> 1); FOVY vertical, radians."
  (declare (type f32vec o) (single-float fovy aspect near far))
  (let* ((f (/ 1f0 (tan (* 0.5f0 fovy)))) (nf (/ 1f0 (- near far))))
    (fill o 0f0)
    (setf (m@ o 0 0) (/ f aspect) (m@ o 1 1) f
          (m@ o 2 2) (* far nf) (m@ o 2 3) (* far near nf)
          (m@ o 3 2) -1f0)
    o))
(defun-fast m4-look-at! (o eye target up)
  "View matrix (camera looks down -Z). EYE TARGET UP are vec3."
  (declare (type f32vec o eye target up))
  (let* ((fx (- (aref target 0) (aref eye 0))) (fy (- (aref target 1) (aref eye 1))) (fz (- (aref target 2) (aref eye 2)))
         (fl (sqrt (the (single-float 0f0) (+ (* fx fx) (* fy fy) (* fz fz))))))
    (when (< fl 1f-9) (setf fz -1f0 fl 1f0))
    (setf fx (/ fx fl) fy (/ fy fl) fz (/ fz fl))
    ;; s = f x up
    (let* ((ux (aref up 0)) (uy (aref up 1)) (uz (aref up 2))
           (sx (- (* fy uz) (* fz uy))) (sy (- (* fz ux) (* fx uz))) (sz (- (* fx uy) (* fy ux)))
           (sl (sqrt (the (single-float 0f0) (+ (* sx sx) (* sy sy) (* sz sz))))))
      (when (< sl 1f-9) (setf sx 1f0 sy 0f0 sz 0f0 sl 1f0)) ; looking straight along up
      (setf sx (/ sx sl) sy (/ sy sl) sz (/ sz sl))
      (let* ((vx (- (* sy fz) (* sz fy))) (vy (- (* sz fx) (* sx fz))) (vz (- (* sx fy) (* sy fx)))
            (ex (aref eye 0)) (ey (aref eye 1)) (ez (aref eye 2)))
        (setf (m@ o 0 0) sx (m@ o 0 1) sy (m@ o 0 2) sz (m@ o 0 3) (- (+ (* sx ex) (* sy ey) (* sz ez)))
              (m@ o 1 0) vx (m@ o 1 1) vy (m@ o 1 2) vz (m@ o 1 3) (- (+ (* vx ex) (* vy ey) (* vz ez)))
              (m@ o 2 0) (- fx) (m@ o 2 1) (- fy) (m@ o 2 2) (- fz) (m@ o 2 3) (+ (* fx ex) (* fy ey) (* fz ez))
              (m@ o 3 0) 0f0 (m@ o 3 1) 0f0 (m@ o 3 2) 0f0 (m@ o 3 3) 1f0)
        o))))

(defun-fast m4-invert! (o a)
  "General 4x4 inverse. Returns O, or NIL (O untouched) if singular. O may alias A."
  (declare (type f32vec o a))
  (let* ((inv *m4-tmp*))
    (declare (type f32vec inv))
    (macrolet ((a (i) `(aref a ,i)))
      (setf (aref inv 0) (+ (* (a 5) (a 10) (a 15)) (- (* (a 5) (a 11) (a 14))) (- (* (a 9) (a 6) (a 15))) (* (a 9) (a 7) (a 14)) (* (a 13) (a 6) (a 11)) (- (* (a 13) (a 7) (a 10))))
            (aref inv 4) (+ (- (* (a 4) (a 10) (a 15))) (* (a 4) (a 11) (a 14)) (* (a 8) (a 6) (a 15)) (- (* (a 8) (a 7) (a 14))) (- (* (a 12) (a 6) (a 11))) (* (a 12) (a 7) (a 10)))
            (aref inv 8) (+ (* (a 4) (a 9) (a 15)) (- (* (a 4) (a 11) (a 13))) (- (* (a 8) (a 5) (a 15))) (* (a 8) (a 7) (a 13)) (* (a 12) (a 5) (a 11)) (- (* (a 12) (a 7) (a 9))))
            (aref inv 12) (+ (- (* (a 4) (a 9) (a 14))) (* (a 4) (a 10) (a 13)) (* (a 8) (a 5) (a 14)) (- (* (a 8) (a 6) (a 13))) (- (* (a 12) (a 5) (a 10))) (* (a 12) (a 6) (a 9)))
            (aref inv 1) (+ (- (* (a 1) (a 10) (a 15))) (* (a 1) (a 11) (a 14)) (* (a 9) (a 2) (a 15)) (- (* (a 9) (a 3) (a 14))) (- (* (a 13) (a 2) (a 11))) (* (a 13) (a 3) (a 10)))
            (aref inv 5) (+ (* (a 0) (a 10) (a 15)) (- (* (a 0) (a 11) (a 14))) (- (* (a 8) (a 2) (a 15))) (* (a 8) (a 3) (a 14)) (* (a 12) (a 2) (a 11)) (- (* (a 12) (a 3) (a 10))))
            (aref inv 9) (+ (- (* (a 0) (a 9) (a 15))) (* (a 0) (a 11) (a 13)) (* (a 8) (a 1) (a 15)) (- (* (a 8) (a 3) (a 13))) (- (* (a 12) (a 1) (a 11))) (* (a 12) (a 3) (a 9)))
            (aref inv 13) (+ (* (a 0) (a 9) (a 14)) (- (* (a 0) (a 10) (a 13))) (- (* (a 8) (a 1) (a 14))) (* (a 8) (a 2) (a 13)) (* (a 12) (a 1) (a 10)) (- (* (a 12) (a 2) (a 9))))
            (aref inv 2) (+ (* (a 1) (a 6) (a 15)) (- (* (a 1) (a 7) (a 14))) (- (* (a 5) (a 2) (a 15))) (* (a 5) (a 3) (a 14)) (* (a 13) (a 2) (a 7)) (- (* (a 13) (a 3) (a 6))))
            (aref inv 6) (+ (- (* (a 0) (a 6) (a 15))) (* (a 0) (a 7) (a 14)) (* (a 4) (a 2) (a 15)) (- (* (a 4) (a 3) (a 14))) (- (* (a 12) (a 2) (a 7))) (* (a 12) (a 3) (a 6)))
            (aref inv 10) (+ (* (a 0) (a 5) (a 15)) (- (* (a 0) (a 7) (a 13))) (- (* (a 4) (a 1) (a 15))) (* (a 4) (a 3) (a 13)) (* (a 12) (a 1) (a 7)) (- (* (a 12) (a 3) (a 5))))
            (aref inv 14) (+ (- (* (a 0) (a 5) (a 14))) (* (a 0) (a 6) (a 13)) (* (a 4) (a 1) (a 14)) (- (* (a 4) (a 2) (a 13))) (- (* (a 12) (a 1) (a 6))) (* (a 12) (a 2) (a 5)))
            (aref inv 3) (+ (- (* (a 1) (a 6) (a 11))) (* (a 1) (a 7) (a 10)) (* (a 5) (a 2) (a 11)) (- (* (a 5) (a 3) (a 10))) (- (* (a 9) (a 2) (a 7))) (* (a 9) (a 3) (a 6)))
            (aref inv 7) (+ (* (a 0) (a 6) (a 11)) (- (* (a 0) (a 7) (a 10))) (- (* (a 4) (a 2) (a 11))) (* (a 4) (a 3) (a 10)) (* (a 8) (a 2) (a 7)) (- (* (a 8) (a 3) (a 6))))
            (aref inv 11) (+ (- (* (a 0) (a 5) (a 11))) (* (a 0) (a 7) (a 9)) (* (a 4) (a 1) (a 11)) (- (* (a 4) (a 3) (a 9))) (- (* (a 8) (a 1) (a 7))) (* (a 8) (a 3) (a 5)))
            (aref inv 15) (+ (* (a 0) (a 5) (a 10)) (- (* (a 0) (a 6) (a 9))) (- (* (a 4) (a 1) (a 10))) (* (a 4) (a 2) (a 9)) (* (a 8) (a 1) (a 6)) (- (* (a 8) (a 2) (a 5)))))
      (let* ((det (+ (* (a 0) (aref inv 0)) (* (a 1) (aref inv 4)) (* (a 2) (aref inv 8)) (* (a 3) (aref inv 12)))))
        (when (< (abs det) 1f-20) (return-from m4-invert! nil))
        (let* ((d (/ 1f0 det)))
          (dotimes (i 16 o) (setf (aref o i) (* (aref inv i) d))))))))

(defun-fast m4-transform-point! (o m v)
  "o = M * (v,1) (affine; no perspective divide). O may alias V."
  (declare (type f32vec o m v))
  (let* ((x (aref v 0)) (y (aref v 1)) (z (aref v 2)))
    (v3-set! o (+ (* (aref m 0) x) (* (aref m 4) y) (* (aref m 8) z) (aref m 12))
             (+ (* (aref m 1) x) (* (aref m 5) y) (* (aref m 9) z) (aref m 13))
             (+ (* (aref m 2) x) (* (aref m 6) y) (* (aref m 10) z) (aref m 14)))))
(defun-fast m4-transform-dir! (o m v)
  "o = M3x3 * v (no translation). O may alias V."
  (declare (type f32vec o m v))
  (let* ((x (aref v 0)) (y (aref v 1)) (z (aref v 2)))
    (v3-set! o (+ (* (aref m 0) x) (* (aref m 4) y) (* (aref m 8) z))
             (+ (* (aref m 1) x) (* (aref m 5) y) (* (aref m 9) z))
             (+ (* (aref m 2) x) (* (aref m 6) y) (* (aref m 10) z)))))
;; allocating convenience for setup code (mesh building, static props)
(defun-fast xform (&key (x 0) (y 0) (z 0) (yaw 0) (pitch 0) (roll 0) (s 1) (sx s) (sy s) (sz s))
  "Fresh mat4 = T(x,y,z) * R(yaw,pitch,roll) * S(sx,sy,sz)."
  (m4-euler! (make-f32 16) (f32 x) (f32 y) (f32 z) (f32 yaw) (f32 pitch) (f32 roll) (f32 sx) (f32 sy) (f32 sz)))
