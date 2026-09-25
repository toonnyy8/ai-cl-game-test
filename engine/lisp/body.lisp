;;;; body.lisp — rigid-part characters: a character's look is a list of simple shapes per rig joint
;;;; (anim.lisp's humanoid), built once into one mesh per joint (+ separate glowing / tagged parts),
;;;; then drawn every frame with the joint matrices POSE-FK! filled. The shape spec is data:
;;;;   ((joint shape ...) ...)   e.g. (:head (:bevel 0.21 0.24 0.23 0.03 :at (0 0.12 0) :c :skin)
;;;;                                         (:glow 2.6 (:box 0.16 0.03 0.02 :at (0 0.13 0.116) :c :visor) :visor))
;;;; Shapes (joint frame, unscaled rig metres; the bone hangs along -up):
;;;;   (:box w h d) (:bevel w h d bevel) (:cyl r h) (:cone r h) (:sphere r) (:wedge w h d)
;;;;   options :at (right up fwd) m, :rot (yaw pitch roll) deg, :c palette key or #xRRGGBB,
;;;;   :seg n (cyl / cone / sphere sides), :top r (cyl top radius), :stretch m (sphere -> capsule),
;;;;   :tag key (a solid part built as its own mesh, so a draw can hide it: an eyepatch, a mask).
;;;;   (:glow e shape [tag]) = a separate emissive part (strength E), drawn tinted by its colour.
;;;; API:  (build-parts spec palette width) -> parts extras   at load time (needs the GPU device)
;;;;       (draw-parts parts extras joints &key hidden hide recolor tint rim emissive flash alpha)
;;;;       (pal-rgb c palette)   a palette key / #xRRGGBB / list -> (r g b)
;;;; Each game keeps its own body struct (stats, weapons, extras) holding PARTS and EXTRAS and
;;;; builds / draws them through here.
(in-package :engine)

(defun pal-rgb (c palette)
  "Colour C as an rgb list: a PALETTE key (PALETTE = ((key #xRRGGBB) ...)), #xRRGGBB, or already a
list (NIL stays NIL)."
  (cond ((keywordp c) (hexc (or (second (assoc c palette)) (error "no colour ~s in palette" c))))
        ((integerp c) (hexc c)) (t c)))

(defun shape-xform (at rot)
  "A shape's placement: AT (right up fwd) metres, ROT (yaw pitch roll) degrees."
  (destructuring-bind (&optional (r 0) (u 0) (f 0)) at
    (destructuring-bind (&optional (yw 0) (pt 0) (rl 0)) rot
      (xform :x r :y u :z (- f) :yaw (deg yw) :pitch (deg pt) :roll (deg rl)))))

(defun shape-opts (shape)
  "The keyword options of SHAPE (everything after its numbers)."
  (member-if #'keywordp (cdr shape)))

(defun build-shape (mb shape palette w &optional color)
  "Add one shape to MB, girth (x and z) scaled by W (COLOR overrides its :c)."
  (destructuring-bind (kind &rest args) shape
    (let* ((opts (shape-opts shape))
           (nums (ldiff args opts))
           (col (pal-rgb (or color (getf opts :c)) palette))
           (seg (getf opts :seg 8)))
      (when col (apply #'mb-color mb col))
      (with-xform (mb (shape-xform (getf opts :at) (getf opts :rot)))
        (ecase kind
          (:box (destructuring-bind (x y z) nums (mb-box mb (* w x) y (* w z))))
          (:bevel (destructuring-bind (x y z b) nums (mb-bevel-box mb (* w x) y (* w z) b)))
          (:cyl (destructuring-bind (r h) nums
                  (mb-cylinder mb (* w r) h :segments seg :top-radius (* w (getf opts :top r)))))
          (:cone (destructuring-bind (r h) nums (mb-cone mb (* w r) h :segments seg)))
          (:sphere (destructuring-bind (r) nums
                     (mb-sphere mb (* w r) :segments seg :rings 5 :stretch (getf opts :stretch 0))))
          (:wedge (destructuring-bind (x y z) nums (mb-wedge mb (* w x) y (* w z)))))))))

(defun build-parts (spec palette width)
  "Build SPEC's meshes (girth x WIDTH). Values: PARTS, a simple-vector of one mesh (or NIL) per
joint for its untagged solid shapes, and EXTRAS, a list of #(joint mesh tint emissive tag): one per
(joint, tag) of tagged solid shapes (tint NIL) and one per glow (tint = its colour)."
  (let ((parts (make-array +nj+ :initial-element nil)) (extras nil))
    (dolist (entry spec)
      (destructuring-bind (jname &rest shapes) entry
        (let* ((j (joint-index jname))
               (glows (remove :glow shapes :key #'first :test-not #'eq))
               (solid (remove :glow shapes :key #'first))
               (plain (remove-if (lambda (s) (getf (shape-opts s) :tag)) solid))
               (tags (remove-duplicates (remove nil (mapcar (lambda (s) (getf (shape-opts s) :tag)) solid)))))
          (when plain
            (setf (svref parts j) (build-mesh (mb :jitter 0.06) (dolist (sh plain) (build-shape mb sh palette width)))))
          (dolist (tag tags)
            (push (vector j (build-mesh (mb :jitter 0.06)
                              (dolist (sh solid) (when (eq (getf (shape-opts sh) :tag) tag) (build-shape mb sh palette width))))
                          nil 0f0 tag)
                  extras))
          (dolist (g glows)                   ; (:glow e shape [tag])
            (destructuring-bind (e shape &optional tag) (rest g)
              (let ((col (pal-rgb (getf (shape-opts shape) :c) palette)))
                (push (vector j (build-mesh (mb :color '(1 1 1)) (build-shape mb shape palette width '(1 1 1)))
                              (coerce col 'simple-vector) (f32 e) tag)
                      extras)))))))
    (values parts extras)))

(declaim (type f32vec *part-m*))
(defvar *part-m* (m4) "DRAW-PARTS' scratch matrix.")

(defun draw-parts (parts extras joints &key (hidden 0) hide recolor tint rim (emissive 0f0) (flash 0f0) (alpha 1f0))
  "Queue every visible part of a built body (BUILD-PARTS) posed by JOINTS (the f32vec POSE-FK!
filled). HIDDEN: joint bitmask (JOINT-MASK ...) whose parts and extras are skipped. HIDE: a tag or
list of tags of extras to skip. RECOLOR: NIL or (tag . rgb), glows with that tag drawn in RGB.
TINT (r g b) multiplies the solid parts' colours, RIM (f32vec, RIM-VEC) is their silhouette rim,
EMISSIVE adds glow, FLASH 0..1 = hit flash to white, ALPHA < 1 = transparent. Glows keep their own
colour and emissive strength (ALPHA applies)."
  (declare (type f32vec joints) (fixnum hidden))
  (let ((dm *part-m*))
    (dotimes (j +nj+)
      (let ((mesh (svref parts j)))
        (when (and mesh (not (logbitp j hidden)))
          (replace dm joints :start2 (* j 16) :end2 (+ 16 (* j 16)))
          (draw-mesh mesh dm :tint tint :flash flash :emissive emissive :alpha alpha :rim rim))))
    (dolist (g extras)
      (let ((j (svref g 0)) (tag (svref g 4)))
        (unless (or (logbitp j hidden) (and tag hide (if (listp hide) (member tag hide) (eq tag hide))))
          (replace dm joints :start2 (* j 16) :end2 (+ 16 (* j 16)))
          (if (svref g 2)
              (draw-mesh (svref g 1) dm :tint (if (and recolor (eq tag (car recolor))) (cdr recolor) (svref g 2))
                         :emissive (svref g 3) :alpha alpha)
              (draw-mesh (svref g 1) dm :tint tint :flash flash :emissive emissive :alpha alpha :rim rim)))))))
