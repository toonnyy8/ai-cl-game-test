;;;; meshgen.lisp — procedural low-poly mesh builders (flat normals, per-vertex color).
;;;; Build CPU-side into a MESH-BUILDER, then (mb-build mb) uploads once and returns a MESH.
;;;; All primitives are centered on the builder's current origin; compose parts with WITH-XFORM.
;;;; Setup-time code: allocates freely, not meant for per-frame use.
(in-package :engine)

(defstruct (mesh-builder (:conc-name mb-) (:constructor make-mesh-builder ()))
  (data (make-f32 4096) :type f32vec)
  (fill 0 :type fixnum)
  (xform (m4) :type f32vec)            ; current local→mesh transform
  (flip nil)                           ; xform mirrors → swap winding
  (cur-color (v3 0.7 0.7 0.7) :type f32vec)
  (jitter 0f0 :type single-float)      ; per-face random brightness ±jitter (low-poly shading variety)
  (seed 12345 :type fixnum))

(defun mb-color (mb r g b)
  "Set the current color (sRGB 0..1) for following primitives."
  (v3-set! (mb-cur-color mb) (f32 r) (f32 g) (f32 b)) mb)

(defun m4-det3 (m)
  (declare (type f32vec m))
  (- (+ (* (aref m 0) (- (* (aref m 5) (aref m 10)) (* (aref m 9) (aref m 6))))
        (* (aref m 8) (- (* (aref m 1) (aref m 6)) (* (aref m 5) (aref m 2)))))
     (* (aref m 4) (- (* (aref m 1) (aref m 10)) (* (aref m 9) (aref m 2))))))

(defmacro with-xform ((mb matrix) &body body)
  "Run BODY with MB's transform = current * MATRIX (e.g. (xform :y 1 :yaw 0.3 :sx 2))."
  (let ((old (gensym)) (b (gensym)))
    `(let* ((,b ,mb) (,old (m4-copy! (make-f32 16) (mb-xform ,b))))
       (m4-mul! (mb-xform ,b) ,old ,matrix)
       (setf (mb-flip ,b) (minusp (m4-det3 (mb-xform ,b))))
       ;; ponytail: no unwind-protect — it compiles to setjmp, and many nested ones make
       ;; clang's wasm backend take minutes (irreducible CFG). A non-local exit mid-build is a bug anyway.
       (multiple-value-prog1 (progn ,@body)
         (m4-copy! (mb-xform ,b) ,old)
         (setf (mb-flip ,b) (minusp (m4-det3 ,old)))))))

(defun-fast mb-rand (mb)
  "Deterministic 0..1 random (LCG in C: the Lisp version consed bignums on 32-bit fixnums)."
  (let* ((seed (mb-seed mb)))
    (declare (fixnum seed))
    (setf (mb-seed mb) (ffi:c-inline (seed) (:int) :int
                                     "(int)((((long long)#0 * 1103515245LL + 12345LL) % 2147483648LL) % MOST_POSITIVE_FIXNUM)" :one-liner t))
    (ffi:c-inline (seed) (:int) :float
                  "(float)(((((long long)#0 * 1103515245LL + 12345LL) % 2147483648LL) >> 8) & 0xFFFF) / 65536.0f" :one-liner t)))

(declaim (type f32vec *mb-fc*))
(defvar *mb-fc* (make-f32 3))   ; face color of the triangle(s) being emitted

(defun-fast %mb-face-color (mb color)
  "*MB-FC* := COLOR (r g b list/vector) or the current color, with jitter applied."
  (let* ((fc *mb-fc*) (c (or color (mb-cur-color mb))) (j (mb-jitter mb))
         (k (if (> j 0f0) (+ 1f0 (* j (- (* 2f0 (the single-float (mb-rand mb))) 1f0))) 1f0)))
    (declare (type f32vec fc) (single-float j k))
    (if (f32vec-p c)
        (let* ((c c)) (declare (type f32vec c))
          (dotimes (i 3) (setf (aref fc i) (f-min 1f0 (* k (aref c i))))))
        (dotimes (i 3) (setf (aref fc i) (f-min 1f0 (* k (the single-float (f32 (elt c i))))))))
    fc))

(defun mb-ensure (mb nfloats)
  (let ((need (+ (mb-fill mb) nfloats)))
    (when (> need (length (mb-data mb)))
      (setf (mb-data mb) (replace (make-f32 (max need (* 2 (length (mb-data mb))))) (mb-data mb))))))

(defun-fast %mb-tri (mb a b c)
  "Append triangle A B C (local vec3s, CCW = front) in color *MB-FC*. Conses nothing.
The math is spelled out (same formulas and order as m4-transform-point!, v3-cross!, v3-normalize!):
calling those from here boxed every float through the out-of-line V3-SET!."
  (declare (type f32vec a b c))
  (let* ((m (mb-xform mb)) (fc *mb-fc*))
    (declare (type f32vec m fc))
    (when (mb-flip mb) (rotatef b c))
    (macrolet ((xf (v i) `(+ (* (aref m ,i) (aref ,v 0)) (* (aref m ,(+ i 4)) (aref ,v 1)) (* (aref m ,(+ i 8)) (aref ,v 2)) (aref m ,(+ i 12)))))
      (let* ((x0 (xf a 0)) (y0 (xf a 1)) (z0 (xf a 2))
             (x1 (xf b 0)) (y1 (xf b 1)) (z1 (xf b 2))
             (x2 (xf c 0)) (y2 (xf c 1)) (z2 (xf c 2))
             (ax (- x1 x0)) (ay (- y1 y0)) (az (- z1 z0))
             (bx (- x2 x0)) (by (- y2 y0)) (bz (- z2 z0))
             (nx (- (* ay bz) (* az by))) (ny (- (* az bx) (* ax bz))) (nz (- (* ax by) (* ay bx)))
             (l (f-sqrt (+ (* nx nx) (* ny ny) (* nz nz)))))
        (declare (single-float x0 y0 z0 x1 y1 z1 x2 y2 z2 ax ay az bx by bz nx ny nz l))
        (if (> l 1f-12)
            (let* ((k (/ 1f0 l))) (declare (single-float k)) (setf nx (* nx k) ny (* ny k) nz (* nz k)))
            (setf nx 0f0 ny 0f0 nz 0f0))
        (mb-ensure mb 27)
        (let* ((d (mb-data mb)) (o (mb-fill mb)) (r (aref fc 0)) (g (aref fc 1)) (bl (aref fc 2)))
          (declare (type f32vec d) (fixnum o) (single-float r g bl))
          (macrolet ((vert (x y z) `(setf (aref d o) ,x (aref d (+ o 1)) ,y (aref d (+ o 2)) ,z
                                          (aref d (+ o 3)) nx (aref d (+ o 4)) ny (aref d (+ o 5)) nz
                                          (aref d (+ o 6)) r (aref d (+ o 7)) g (aref d (+ o 8)) bl
                                          o (+ o 9))))
            (vert x0 y0 z0) (vert x1 y1 z1) (vert x2 y2 z2))
          (setf (mb-fill mb) o))))
    nil))

(defun mb-quad (mb a b c d &optional color)
  "Quad A B C D (CCW from the front) as two triangles sharing one face color."
  (%mb-face-color mb color) (%mb-tri mb a b c) (%mb-tri mb a c d))

(defun-fast outward-p (a b c cx cy cz)
  "Is triangle A B C wound CCW as seen from outside, relative to interior point C*?"
  (declare (type f32vec a b c) (single-float cx cy cz))
  (let* ((ux (- (aref b 0) (aref a 0))) (uy (- (aref b 1) (aref a 1))) (uz (- (aref b 2) (aref a 2)))
         (vx (- (aref c 0) (aref a 0))) (vy (- (aref c 1) (aref a 1))) (vz (- (aref c 2) (aref a 2)))
         (nx (- (* uy vz) (* uz vy))) (ny (- (* uz vx) (* ux vz))) (nz (- (* ux vy) (* uy vx))))
    (declare (single-float ux uy uz vx vy vz nx ny nz))
    (>= (+ (* nx (- (+ (aref a 0) (aref b 0) (aref c 0)) (* 3f0 cx)))
           (* ny (- (+ (aref a 1) (aref b 1) (aref c 1)) (* 3f0 cy)))
           (* nz (- (+ (aref a 2) (aref b 2) (aref c 2)) (* 3f0 cz))))
        0f0)))

(defun mb-poly-out (mb pts &key color (center '(0 0 0)))
  "Convex planar polygon PTS (list of vec3, either winding) facing away from interior point CENTER."
  (let* ((pts (if (outward-p (first pts) (second pts) (third pts) (f32 (first center)) (f32 (second center)) (f32 (third center)))
                  pts (reverse pts))))
    (%mb-face-color mb color)
    (loop for (p q) on (rest pts) while q do (%mb-tri mb (first pts) p q))))

;;; ---------------------------------------------------------------- primitives
(defun mb-box (mb w h d &key colors)
  "Box W x H x D centered at origin. COLORS: optional list of 6 (r g b) for faces +X -X +Y -Y +Z -Z (NIL = current)."
  (mb-bevel-box mb w h d 0 :colors colors))

(defvar *mb-q* (vector (make-f32 3) (make-f32 3) (make-f32 3) (make-f32 3)))
(defun-fast %mb-box-faces (mb full in colors)
  "The 6 faces +X -X +Y -Y +Z -Z of a box: FULL half extents along the face axis, IN (inset) on the
other two. Same triangles as MB-POLY-OUT on the corner quads, without allocating."
  (declare (type f32vec full in))
  (let* ((q *mb-q*))
    (declare (simple-vector q))
    (dotimes (fi 6)
      (let* ((axis (floor fi 2)) (i (mod (1+ axis) 3)) (j (mod (+ 2 axis) 3))
             (q0 (svref q 0)) (q1 (svref q 1)) (q2 (svref q 2)) (q3 (svref q 3)))
        (declare (fixnum axis i j) (type f32vec q0 q1 q2 q3))
        (dotimes (qi 4)                 ; corners (-1 -1) (1 -1) (1 1) (-1 1) on axes i, j
          (let* ((v (svref q qi)))
            (declare (type f32vec v))
            (setf (aref v axis) (if (oddp fi) (- (aref full axis)) (aref full axis))
                  (aref v i) (if (or (= qi 1) (= qi 2)) (aref in i) (- (aref in i)))
                  (aref v j) (if (>= qi 2) (aref in j) (- (aref in j))))))
        (%mb-face-color mb (nth fi colors))
        (if (outward-p q0 q1 q2 0f0 0f0 0f0)
            (progn (%mb-tri mb q0 q1 q2) (%mb-tri mb q0 q2 q3))
            (progn (%mb-tri mb q3 q2 q1) (%mb-tri mb q3 q1 q0)))))))

(defun mb-bevel-box (mb w h d bevel &key colors)
  "Box with chamfered edges of size BEVEL (0 = plain box). Chamfer faces use the current color."
  (let* ((he (vector (* .5 w) (* .5 h) (* .5 d))) (bv (min bevel (* .49 (min w h d)))))
    (labels ((pt (sx sy sz axis)
               ;; corner (sx sy sz) pushed out to face AXIS, inset on the other two axes
               (let ((s (vector sx sy sz)) (v (make-f32 3)))
                 (dotimes (i 3 v)
                   (setf (aref v i) (f32 (* (aref s i) (if (= i axis) (aref he i) (- (aref he i) bv)))))))))
      ;; 6 faces
      (let ((full (make-f32 3)) (in (make-f32 3)))
        (dotimes (k 3) (setf (aref full k) (f32 (aref he k)) (aref in k) (f32 (- (aref he k) bv))))
        (%mb-box-faces mb full in colors))
      (when (plusp bv)
        ;; 12 edge chamfers: edge along axis e at signs (si, sj) on the other two axes
        (dotimes (e 3)
          (let ((i (mod (1+ e) 3)) (j (mod (+ 2 e) 3)))
            (dolist (si '(-1 1))
              (dolist (sj '(-1 1))
                (flet ((c (se) (let ((s (vector 0 0 0))) (setf (aref s e) se (aref s i) si (aref s j) sj) s)))
                  (let ((lo (c -1)) (hi (c 1)))
                    (mb-poly-out mb (list (pt (aref lo 0) (aref lo 1) (aref lo 2) i) (pt (aref hi 0) (aref hi 1) (aref hi 2) i)
                                          (pt (aref hi 0) (aref hi 1) (aref hi 2) j) (pt (aref lo 0) (aref lo 1) (aref lo 2) j)))))))))
        ;; 8 corner triangles
        (dolist (sx '(-1 1))
          (dolist (sy '(-1 1))
            (dolist (sz '(-1 1))
              (mb-poly-out mb (list (pt sx sy sz 0) (pt sx sy sz 1) (pt sx sy sz 2))))))))
    mb))

(defun mb-cylinder (mb radius height &key (segments 8) (top-radius radius) (caps t) top-color)
  "Cylinder / frustum along Y, centered. TOP-RADIUS 0 makes a cone. SEGMENTS 3..6 give prisms."
  (let* ((hy (* .5 height)) (n segments)
         (ring (lambda (r y) (loop for k below n
                                   collect (let ((a (/ (* 2 pi k) n))) (v3 (* r (cos a)) y (* r (- (sin a)))))))))
    (let ((bot (funcall ring radius (- hy))) (top (funcall ring top-radius hy)))
      (loop for k below n
            for k2 = (mod (1+ k) n)
            do (if (< top-radius 1e-6)
                   (mb-poly-out mb (list (nth k bot) (nth k2 bot) (nth k top)))
                   (mb-poly-out mb (list (nth k bot) (nth k2 bot) (nth k2 top) (nth k top)))))
      (when caps
        (mb-poly-out mb bot)
        (when (> top-radius 1e-6) (mb-poly-out mb top :color top-color))))
    mb))

(defun mb-cone (mb radius height &key (segments 8))
  (mb-cylinder mb radius height :segments segments :top-radius 0))

(defun mb-prism (mb radius height sides)
  "N-sided prism along Y (e.g. 6 = hex pillar)."
  (mb-cylinder mb radius height :segments sides))

(defun mb-sphere (mb radius &key (segments 8) (rings 6) (stretch 0))
  "Low-poly UV sphere. STRETCH > 0 splits it at the equator and inserts a cylinder of that length."
  (let* ((n segments) (hs (* .5 stretch)) (half (floor rings 2))
         (spec (append (loop for i from 0 to half collect (cons i hs))
                       (when (plusp stretch) (list (cons half (- hs))))
                       (loop for i from (1+ half) to rings collect (cons i (- hs)))))
         (rows (loop for (i . dy) in spec
                     collect (let* ((phi (* pi (/ i rings))) (y (+ dy (* radius (cos phi)))) (r (* radius (sin phi))))
                               (cons (or (= i 0) (= i rings))
                                     (loop for k below n collect (let ((a (/ (* 2 pi k) n))) (v3 (* r (cos a)) y (* r (- (sin a)))))))))))
    (loop for ((up-pole . up) (dn-pole . dn)) on rows while dn do
      (loop for k below n for k2 = (mod (1+ k) n) do
        (cond (up-pole (mb-poly-out mb (list (nth k up) (nth k dn) (nth k2 dn))))
              (dn-pole (mb-poly-out mb (list (nth k up) (nth k dn) (nth k2 up))))
              (t (mb-poly-out mb (list (nth k up) (nth k dn) (nth k2 dn) (nth k2 up)))))))
    mb))

(defun mb-capsule (mb radius height &key (segments 8) (rings 4))
  "Capsule along Y, total HEIGHT including the rounded ends."
  (mb-sphere mb radius :segments segments :rings rings :stretch (max 0 (- height (* 2 radius)))))

(defun mb-wedge (mb w h d)
  "Ramp: W x D footprint, full height H at the back (-Z), sloping down to the front (+Z)."
  (let* ((hx (* .5 w)) (hy (* .5 h)) (hz (* .5 d))
         (c (list 0 (- (/ hy 3)) (- (/ hz 3))))
         (lb (v3 (- hx) (- hy) hz)) (rb (v3 hx (- hy) hz))          ; front bottom
         (lk (v3 (- hx) (- hy) (- hz))) (rk (v3 hx (- hy) (- hz)))  ; back bottom
         (lt (v3 (- hx) hy (- hz))) (rt (v3 hx hy (- hz))))         ; back top
    (mb-poly-out mb (list lb rb rk lk) :center c)      ; bottom
    (mb-poly-out mb (list lk rk rt lt) :center c)      ; back
    (mb-poly-out mb (list lb rb rt lt) :center c)      ; slope
    (mb-poly-out mb (list lb lk lt) :center c)         ; sides
    (mb-poly-out mb (list rb rk rt) :center c)
    mb))

(defun mb-plane (mb w d &key (nx 1) (nz 1) color2)
  "Flat grid W x D on XZ facing +Y, NX x NZ cells. COLOR2 = checker alternate color."
  (let ((cw (/ w nx)) (cd (/ d nz)) (x0 (* -.5 w)) (z0 (* -.5 d)))
    (dotimes (i nx)
      (dotimes (k nz)
        (let ((xa (+ x0 (* i cw))) (xb (+ x0 (* (1+ i) cw))) (za (+ z0 (* k cd))) (zb (+ z0 (* (1+ k) cd))))
          (mb-quad mb (v3 xa 0 zb) (v3 xb 0 zb) (v3 xb 0 za) (v3 xa 0 za)
                   (and color2 (oddp (+ i k)) color2)))))
    mb))

(defun mb-blade (mb &key (length 0.95) (width 0.034) (thickness 0.008) (curve 0.025) (segments 6)
                      (blade-color '(0.82 0.86 0.92)) (edge-color '(0.97 0.98 1.0))
                      (guard-color '(0.55 0.42 0.18)) (handle-color '(0.12 0.08 0.10)) (wrap-color '(0.55 0.05 0.08))
                      (blade t) (hilt t))
  "Katana. Origin at the guard; blade along +Y (edge toward +Z, gentle curve), handle along -Y.
Use :hilt nil / :blade nil to build the parts as separate meshes (e.g. to make the blade emissive)."
  (when blade
    (let* ((secs (loop for i from 0 to segments
                       collect (let* ((u (/ i segments)) (y (* u length))
                                      (z (* curve (- (* u u))))          ; sori: tip bends back (-Z)
                                      (wd (* width (- 1 (* 0.25 u))))
                                      (th (* thickness (- 1 (* 0.4 u)))))
                                 ;; diamond: spine (-Z), left, edge (+Z), right
                                 (list (v3 0 y (- z (* .5 wd))) (v3 (- (* .5 th)) y (+ z (* .1 wd)))
                                       (v3 0 y (+ z (* .5 wd))) (v3 (* .5 th) y (+ z (* .1 wd)))))))
           (tip-y (+ length (* 0.09 length))) (tip (v3 0 tip-y (- (+ curve (* 0.3 width))))))
      (loop for (a b) on secs while b do
        (let* ((cy (* .5 (+ (aref (first a) 1) (aref (first b) 1))))
               (cz (* .25 (+ (aref (first a) 2) (aref (third a) 2) (aref (first b) 2) (aref (third b) 2))))
               (c (list 0 cy cz)))
          (dotimes (k 4)
            (let ((k2 (mod (1+ k) 4)))
              (mb-poly-out mb (list (nth k a) (nth k2 a) (nth k2 b) (nth k b)) :center c
                           :color (if (or (= k 1) (= k2 3) ) edge-color blade-color))))))
      (let* ((last (car (last secs)))
             (c (list 0 (* .5 (+ tip-y (aref (first last) 1))) (* .5 (+ (aref tip 2) (aref (first last) 2))))))
        (dotimes (k 4)
          (mb-poly-out mb (list (nth k last) (nth (mod (1+ k) 4) last) tip) :center c :color edge-color)))))
  (when hilt
    (let ((saved (v3-copy (mb-cur-color mb))))
      (mb-color mb 0.75 0.7 0.55)                                              ; habaki collar
      (with-xform (mb (xform :y 0.025)) (mb-box mb (* 1.6 thickness) 0.04 (* 1.15 width)))
      (apply #'mb-color mb guard-color)                                        ; tsuba
      (with-xform (mb (xform :y -0.004 :sx 0.8)) (mb-cylinder mb 0.045 0.01 :segments 8))
      (apply #'mb-color mb handle-color)                                       ; tsuka core
      (with-xform (mb (xform :y -0.14)) (mb-bevel-box mb 0.026 0.26 0.034 0.006))
      (apply #'mb-color mb wrap-color)                                         ; wrap diamonds
      (loop for i from 0 below 5 do
        (with-xform (mb (xform :y (- -0.035 (* i 0.05)) :roll 0.785))
          (mb-box mb 0.02 0.02 0.036)))
      (apply #'mb-color mb guard-color)                                        ; kashira
      (with-xform (mb (xform :y -0.277)) (mb-bevel-box mb 0.03 0.016 0.038 0.004))
      (v3-copy! (mb-cur-color mb) saved)))
  mb)

;;; ---------------------------------------------------------------- helpers
(defun hexc (h &optional (k 1.0))
  "#xRRGGBB -> (r g b) list, 0..1, each channel times K (capped at 1)."
  (list (min 1.0 (* k (/ (ldb (byte 8 16) h) 255.0))) (min 1.0 (* k (/ (ldb (byte 8 8) h) 255.0)))
        (min 1.0 (* k (/ (ldb (byte 8 0) h) 255.0)))))
(defun mbc (mb h &optional (k 1.0))
  "MB-COLOR from a #xRRGGBB color (see HEXC)."
  (apply #'mb-color mb (hexc h k)))

(defun mb-tube (mb x0 y0 z0 x1 y1 z1 r &key (sides 4) (caps t))
  "Prism of SIDES around the segment (x0 y0 z0)→(x1 y1 z1): pipes, beams, wires, cables."
  (let* ((d (v3 (- x1 x0) (- y1 y0) (- z1 z0))))
    (when (> (v3-len d) 1e-4)
      (v3-normalize! d d)
      (let* ((u (v3-normalize! (make-f32 3) (v3-cross! (make-f32 3) d (if (> (abs (aref d 1)) 0.9) (v3 1 0 0) (v3 0 1 0)))))
             (w (v3-cross! (make-f32 3) d u))
             (c (list (* .5 (+ x0 x1)) (* .5 (+ y0 y1)) (* .5 (+ z0 z1))))
             (ring (lambda (x y z)
                     (loop for k below sides
                           collect (let* ((a (+ (/ pi sides) (/ (* 2 pi k) sides))) (ca (* r (cos a))) (sa (* r (sin a))))
                                     (v3 (+ x (* ca (aref u 0)) (* sa (aref w 0))) (+ y (* ca (aref u 1)) (* sa (aref w 1)))
                                         (+ z (* ca (aref u 2)) (* sa (aref w 2))))))))
             (ra (funcall ring x0 y0 z0)) (rb (funcall ring x1 y1 z1)))
        (loop for k below sides for k2 = (mod (1+ k) sides)
              do (mb-poly-out mb (list (nth k ra) (nth k2 ra) (nth k2 rb) (nth k rb)) :center c))
        (when caps (mb-poly-out mb ra :center c) (mb-poly-out mb rb :center c))))))

(defun mb-flat-quad (mb x0 z0 x1 z1 y &optional color)
  "Upward-facing rectangle at height Y."
  (mb-quad mb (v3 x0 y z1) (v3 x1 y z1) (v3 x1 y z0) (v3 x0 y z0) color))

(defun mb-build (mb)
  "Upload builder contents as a new MESH."
  (make-mesh (mb-data mb) (mb-fill mb)))

(defmacro build-mesh ((mb &key (jitter 0) (color ''(0.7 0.7 0.7))) &body body)
  "Evaluate BODY with a fresh builder bound to MB, return the uploaded mesh."
  `(let ((,mb (make-mesh-builder)))
     (setf (mb-jitter ,mb) (f32 ,jitter))
     (apply #'mb-color ,mb ,color)
     ,@body
     (mb-build ,mb)))
