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
;;;;   :ink k (hull width multiplier, see BUILD-PARTS).
;;;; API:  (build-parts spec palette width &key ink) -> parts extras hulls   at load time (needs the GPU device)
;;;;       (draw-parts parts extras joints &key hidden hide recolor tint rim emissive flash alpha toon
;;;;                   hulls ink-tint ink-px ink-push)   HULLS = ink outlines (toon only, docs/STYLE_STORM_DESIGN.md §2.4)
;;;;       *part-jitter* (per-face brightness noise, 0.06) and *part-smooth* (NIL: flat; T: round normals
;;;;       on :sphere / :cyl) are read at build time: a toon game sets 0 and T (RAVEN keeps the defaults).
;;;;       (pal-rgb c palette)   a palette key / #xRRGGBB / list -> (r g b)
;;;; Each game keeps its own body struct (stats, weapons, extras) holding PARTS and EXTRAS and
;;;; builds / draws them through here.
(in-package :engine)

(defvar *part-jitter* 0.06 "BUILD-PARTS: per-face random brightness (low-poly shading variety); 0 for toon shading.")
(defvar *part-smooth* nil "BUILD-PARTS: T gives :sphere and :cyl shapes analytic smooth normals (toon shading).")

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
                  (mb-cylinder mb (* w r) h :segments seg :top-radius (* w (getf opts :top r)) :smooth *part-smooth*)))
          (:cone (destructuring-bind (r h) nums (mb-cone mb (* w r) h :segments seg)))
          (:sphere (destructuring-bind (r) nums
                     (mb-sphere mb (* w r) :segments seg :rings 5 :stretch (getf opts :stretch 0) :smooth *part-smooth*)))
          (:wedge (destructuring-bind (x y z) nums (mb-wedge mb (* w x) y (* w z)))))))))

(defun shape-ink-k (shape mb start)
  "Ink width multiplier of SHAPE, built into MB from float START: its :ink option, else by its middle
extent (the second largest of its box in the joint frame): 0 under 4 cm (strokes, eye slits: no hull),
0.6 under 10 cm, else 1."
  (or (getf (shape-opts shape) :ink)
      (let ((d (mb-data mb)) (lo (list 1e9 1e9 1e9)) (hi (list -1e9 -1e9 -1e9)))
        (loop for o from start below (mb-fill mb) by 9 do
          (dotimes (i 3) (setf (nth i lo) (min (nth i lo) (aref d (+ o i))) (nth i hi) (max (nth i hi) (aref d (+ o i))))))
        (let ((mid (second (sort (mapcar #'- hi lo) #'>))))
          (cond ((< mid 0.04) 0) ((< mid 0.1) 0.6) (t 1))))))

(defun build-solid (shapes palette width ink)
  "One mesh of SHAPES and, with INK, its hull mesh (or NIL: every shape inkless)."
  (let ((mb (make-mesh-builder)) (ranges nil))
    (setf (mb-jitter mb) (f32 *part-jitter*))           ; = BUILD-MESH's builder
    (mb-color mb 0.7 0.7 0.7)
    (dolist (sh shapes)
      (let ((start (mb-fill mb)))
        (build-shape mb sh palette width)
        (when ink (push (list start (mb-fill mb) sh (shape-ink-k sh mb start)) ranges))))
    (values (mb-build mb)
            (when ink
              (let ((hb (make-mesh-builder)))
                (loop for (start end sh k) in (reverse ranges) when (plusp k) do
                  (let ((c (getf (shape-opts sh) :c)))
                    (mb-hull hb mb :start start :end end :k k :c (if (member (first sh) '(:cone :wedge)) 0.8 0.55)
                             :color (hexc (cdr (or (assoc c ink) (assoc t ink)))))))
                (when (plusp (mb-fill hb)) (mb-build hb)))))))

(defun build-parts (spec palette width &key ink)
  "Build SPEC's meshes (girth x WIDTH). Values: PARTS, a simple-vector of one mesh (or NIL) per
joint for its untagged solid shapes, EXTRAS, a list of #(joint mesh tint emissive tag): one per
(joint, tag) of tagged solid shapes (tint NIL) and one per glow (tint = its colour), and HULLS, a list
of #(joint mesh tag): the ink hulls (MB-HULL) of the solid shapes, one per joint and tagged part.
INK (NIL = no hulls, RAVEN) = ((colour key . #xRRGGBB) ... (t . #xRRGGBB)): the ink colour of a shape
by its :c key (e.g. a grey keyline on black cloth, red-brown on skin), T = every other shape; a shape's
width multiplier is its :ink option or SHAPE-INK-K's size rule; glows get no hull."
  (let ((parts (make-array +nj+ :initial-element nil)) (extras nil) (hulls nil))
    (dolist (entry spec)
      (destructuring-bind (jname &rest shapes) entry
        (let* ((j (joint-index jname))
               (glows (remove :glow shapes :key #'first :test-not #'eq))
               (solid (remove :glow shapes :key #'first))
               (plain (remove-if (lambda (s) (getf (shape-opts s) :tag)) solid))
               (tags (remove-duplicates (remove nil (mapcar (lambda (s) (getf (shape-opts s) :tag)) solid)))))
          (when plain
            (multiple-value-bind (mesh hull) (build-solid plain palette width ink)
              (setf (svref parts j) mesh)
              (when hull (push (vector j hull nil) hulls))))
          (dolist (tag tags)
            (multiple-value-bind (mesh hull)
                (build-solid (remove tag solid :key (lambda (s) (getf (shape-opts s) :tag)) :test-not #'eq) palette width ink)
              (push (vector j mesh nil 0f0 tag) extras)
              (when hull (push (vector j hull tag) hulls))))
          (dolist (g glows)                   ; (:glow e shape [tag])
            (destructuring-bind (e shape &optional tag) (rest g)
              (let ((col (pal-rgb (getf (shape-opts shape) :c) palette)))
                (push (vector j (build-mesh (mb :color '(1 1 1)) (build-shape mb shape palette width '(1 1 1)))
                              (coerce col 'simple-vector) (f32 e) tag)
                      extras)))))))
    (values parts extras hulls)))

(declaim (type f32vec *part-m*))
(defvar *part-m* (m4) "DRAW-PARTS' scratch matrix.")
(declaim (type f32vec *part-ink*))
(defvar *part-ink* (make-f32 4) "DRAW-PARTS' hull lanes: mode 3, depth push m, fog scale, ink px @720.")

(defmacro part-hidden-p (j tag hidden hide)
  `(or (logbitp ,j ,hidden) (and ,tag ,hide (if (listp ,hide) (member ,tag ,hide) (eq ,tag ,hide)))))

(defun draw-parts (parts extras joints &key (hidden 0) hide recolor tint rim (emissive 0f0) (flash 0f0) (alpha 1f0) toon
                                           hulls ink-tint (ink-px 1.8f0) (ink-push 0.012f0))
  "Queue every visible part of a built body (BUILD-PARTS) posed by JOINTS (the f32vec POSE-FK!
filled). HIDDEN: joint bitmask (JOINT-MASK ...) whose parts and extras are skipped. HIDE: a tag or
list of tags of extras to skip. RECOLOR: NIL or (tag . rgb), glows with that tag drawn in RGB.
TINT (r g b) multiplies the solid parts' colours, RIM (f32vec, RIM-VEC) is their silhouette rim,
EMISSIVE adds glow, FLASH 0..1 = hit flash to white, ALPHA < 1 = transparent. Glows keep their own
colour and emissive strength (ALPHA applies). TOON: DRAW-MESH's toon lanes for every part (NIL = lit).
HULLS (BUILD-PARTS' third value) are drawn after the solids when TOON is set and ALPHA is 1: ink
outlines INK-PX pixels wide at 720 lines, tinted INK-TINT, pushed INK-PUSH metres away from the
camera so a line only shows where the part behind is farther than that (thin or no line where parts
touch or overlap closely, none on the seams between abutting panels)."
  (declare (type f32vec joints) (fixnum hidden) (single-float ink-px ink-push))
  (let ((dm *part-m*))
    (dotimes (j +nj+)
      (let ((mesh (svref parts j)))
        (when (and mesh (not (logbitp j hidden)))
          (replace dm joints :start2 (* j 16) :end2 (+ 16 (* j 16)))
          (draw-mesh mesh dm :tint tint :flash flash :emissive emissive :alpha alpha :rim rim :toon toon))))
    (dolist (g extras)
      (let ((j (svref g 0)) (tag (svref g 4)))
        (unless (part-hidden-p j tag hidden hide)
          (replace dm joints :start2 (* j 16) :end2 (+ 16 (* j 16)))
          (if (svref g 2)
              (draw-mesh (svref g 1) dm :tint (if (and recolor (eq tag (car recolor))) (cdr recolor) (svref g 2))
                         :emissive (svref g 3) :alpha alpha :toon toon)
              (draw-mesh (svref g 1) dm :tint tint :flash flash :emissive emissive :alpha alpha :rim rim :toon toon)))))
    (when (and hulls toon (>= alpha 1f0))
      (let* ((lanes *part-ink*) (tl toon))
        (declare (type f32vec lanes tl))
        (setf (aref lanes 0) 3f0 (aref lanes 1) ink-push (aref lanes 2) (aref tl 2) (aref lanes 3) ink-px)
        (dolist (h hulls)
          (let ((j (svref h 0)) (tag (svref h 2)))
            (unless (part-hidden-p j tag hidden hide)
              (replace dm joints :start2 (* j 16) :end2 (+ 16 (* j 16)))
              (draw-mesh (svref h 1) dm :tint ink-tint :toon lanes))))))))
