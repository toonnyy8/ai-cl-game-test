;;;; ui.lisp — 2D UI layer: pixel-space batch of rects, gradients, bars and bitmap text.
;;;; Coordinates are framebuffer pixels, origin top-left, y down. Drawn last (over the composite), no depth.
;;;; Colors: (r g b [a]) list or vector, sRGB 0..1.
(in-package :engine)

;;; Classic 5x7 font, ASCII 32..126. 5 column bytes per glyph, bit 0 = top row.
(defparameter +font-5x7+
  #(#x00 #x00 #x00 #x00 #x00  #x00 #x00 #x5F #x00 #x00  #x00 #x07 #x00 #x07 #x00  #x14 #x7F #x14 #x7F #x14
    #x24 #x2A #x7F #x2A #x12  #x23 #x13 #x08 #x64 #x62  #x36 #x49 #x56 #x20 #x50  #x00 #x00 #x07 #x00 #x00
    #x00 #x1C #x22 #x41 #x00  #x00 #x41 #x22 #x1C #x00  #x14 #x08 #x3E #x08 #x14  #x08 #x08 #x3E #x08 #x08
    #x00 #x50 #x30 #x00 #x00  #x08 #x08 #x08 #x08 #x08  #x00 #x60 #x60 #x00 #x00  #x20 #x10 #x08 #x04 #x02
    #x3E #x51 #x49 #x45 #x3E  #x00 #x42 #x7F #x40 #x00  #x42 #x61 #x51 #x49 #x46  #x21 #x41 #x45 #x4B #x31
    #x18 #x14 #x12 #x7F #x10  #x27 #x45 #x45 #x45 #x39  #x3C #x4A #x49 #x49 #x30  #x01 #x71 #x09 #x05 #x03
    #x36 #x49 #x49 #x49 #x36  #x06 #x49 #x49 #x29 #x1E  #x00 #x36 #x36 #x00 #x00  #x00 #x56 #x36 #x00 #x00
    #x08 #x14 #x22 #x41 #x00  #x14 #x14 #x14 #x14 #x14  #x00 #x41 #x22 #x14 #x08  #x02 #x01 #x51 #x09 #x06
    #x32 #x49 #x79 #x41 #x3E  #x7E #x11 #x11 #x11 #x7E  #x7F #x49 #x49 #x49 #x36  #x3E #x41 #x41 #x41 #x22
    #x7F #x41 #x41 #x22 #x1C  #x7F #x49 #x49 #x49 #x41  #x7F #x09 #x09 #x09 #x01  #x3E #x41 #x49 #x49 #x7A
    #x7F #x08 #x08 #x08 #x7F  #x00 #x41 #x7F #x41 #x00  #x20 #x40 #x41 #x3F #x01  #x7F #x08 #x14 #x22 #x41
    #x7F #x40 #x40 #x40 #x40  #x7F #x02 #x0C #x02 #x7F  #x7F #x04 #x08 #x10 #x7F  #x3E #x41 #x41 #x41 #x3E
    #x7F #x09 #x09 #x09 #x06  #x3E #x41 #x51 #x21 #x5E  #x7F #x09 #x19 #x29 #x46  #x46 #x49 #x49 #x49 #x31
    #x01 #x01 #x7F #x01 #x01  #x3F #x40 #x40 #x40 #x3F  #x1F #x20 #x40 #x20 #x1F  #x3F #x40 #x38 #x40 #x3F
    #x63 #x14 #x08 #x14 #x63  #x07 #x08 #x70 #x08 #x07  #x61 #x51 #x49 #x45 #x43  #x00 #x7F #x41 #x41 #x00
    #x02 #x04 #x08 #x10 #x20  #x00 #x41 #x41 #x7F #x00  #x04 #x02 #x01 #x02 #x04  #x40 #x40 #x40 #x40 #x40
    #x00 #x01 #x02 #x04 #x00  #x20 #x54 #x54 #x54 #x78  #x7F #x48 #x44 #x44 #x38  #x38 #x44 #x44 #x44 #x20
    #x38 #x44 #x44 #x48 #x7F  #x38 #x54 #x54 #x54 #x18  #x08 #x7E #x09 #x01 #x02  #x0C #x52 #x52 #x52 #x3E
    #x7F #x08 #x04 #x04 #x78  #x00 #x44 #x7D #x40 #x00  #x20 #x40 #x44 #x3D #x00  #x7F #x10 #x28 #x44 #x00
    #x00 #x41 #x7F #x40 #x00  #x7C #x04 #x18 #x04 #x78  #x7C #x08 #x04 #x04 #x78  #x38 #x44 #x44 #x44 #x38
    #x7C #x14 #x14 #x14 #x08  #x08 #x14 #x14 #x18 #x7C  #x7C #x08 #x04 #x04 #x08  #x48 #x54 #x54 #x54 #x20
    #x04 #x3F #x44 #x40 #x20  #x3C #x40 #x40 #x20 #x7C  #x1C #x20 #x40 #x20 #x1C  #x3C #x40 #x30 #x40 #x3C
    #x44 #x28 #x10 #x28 #x44  #x0C #x50 #x50 #x50 #x3C  #x44 #x64 #x54 #x4C #x44  #x00 #x08 #x36 #x41 #x00
    #x00 #x00 #x7F #x00 #x00  #x00 #x41 #x36 #x08 #x00  #x08 #x04 #x08 #x10 #x08))

(defconstant +glyph-w+ 6)   ; cell incl. 1px spacing
(defconstant +glyph-h+ 8)
(defconstant +atlas-w+ 96)  ; 16 x 6 cells; cell 95 (char 127) is solid white
(defconstant +atlas-h+ 48)

(defun font-atlas-bytes ()
  (let ((img (make-array (* +atlas-w+ +atlas-h+) :element-type '(unsigned-byte 8) :initial-element 0)))
    (dotimes (g 96 img)
      (let ((cx (* (mod g 16) +glyph-w+)) (cy (* (floor g 16) +glyph-h+)))
        (dotimes (col 6)
          (dotimes (row 8)
            (when (if (= g 95)
                      t
                      (and (< col 5) (< row 7) (logbitp row (aref +font-5x7+ (+ (* g 5) col)))))
              (setf (aref img (+ (* (+ cy row) +atlas-w+) cx col)) 255))))))))

(defun ui-init ()
  "UI pipeline (drawn over the composite in the swapchain pass), font atlas, batch."
  (make-pipeline 10 (wgsl "ui.vert.wgsl") "vs_ui" (wgsl "ui.frag.wgsl") "fs_ui" #x224 2 0 1 0)   ; RP_UI
  (let ((px (font-atlas-bytes)))
    (unless (ffi:c-inline (px +atlas-w+ +atlas-h+) (t :int :int) :bool "r_font_new(#0->vector.self.b8,#1,#2)" :one-liner t)
      (error "ui-init: font texture failed")))
  (setf *ui-batch* (make-stream-buffer 8 32768)))

(defun ui-scale ()
  "Suggested integer text/UI scale for the current window: 1 per ~360 px of height, capped at
1 per 480 px of width so narrow / portrait windows keep text inside the screen."
  (max 1 (min (round (window-height) 360) (floor (window-width) 480))))

(defun fit-scale (str want max-w)
  "Largest integer text scale <= WANT (>= 1) at which STR's widest line fits in MAX-W pixels."
  (max 1 (min (round want) (floor max-w (max 1 (text-width str 1))))))

;;; ---------------------------------------------------------------- primitives
(declaim (inline col-a))
(defun col-a (c) (if (> (length c) 3) (f32 (elt c 3)) 1f0))

(defconstant +white-u+ (/ (+ (* 15 6) 3f0) 96))  ; center of the solid cell
(defconstant +white-v+ (/ (+ (* 5 8) 4f0) 48))

(defmacro with-ui-verts ((data o nverts) &body body)
  "Reserve NVERTS in the UI batch (skipped, NIL, when it is full); inside BODY
(UVTX x y r g b a [u v]) appends one vertex: framebuffer pixels, sRGB color, atlas uv (default the
solid white cell = a flat color). The UI twin of WITH-FX-VERTS: in DEFUN-FAST code with float
locals it conses nothing. 6 vertices = one quad (two triangles)."
  (let* ((sb (gensym)))
    `(let* ((,sb *ui-batch*))
       (when (stream-room-p ,sb ,nverts)
         (let* ((,data (stream-buffer-data ,sb)) (,o (stream-buffer-fill ,sb)))
           (declare (type f32vec ,data) (fixnum ,o))
           (macrolet ((uvtx (x y r g b a &optional (u '+white-u+) (v '+white-v+))
                        `(setf (aref ,',data ,',o) ,x (aref ,',data (+ ,',o 1)) ,y
                               (aref ,',data (+ ,',o 2)) ,u (aref ,',data (+ ,',o 3)) ,v
                               (aref ,',data (+ ,',o 4)) ,r (aref ,',data (+ ,',o 5)) ,g
                               (aref ,',data (+ ,',o 6)) ,b (aref ,',data (+ ,',o 7)) ,a
                               ,',o (+ ,',o 8))))
             ,@body)
           (setf (stream-buffer-fill ,sb) ,o)
           t)))))

(defmacro %col-floats ((r g b a) c &body body)
  "Bind R G B A (single-floats) to color C, a list or vector of 3-4 numbers."
  (let ((cv (gensym)))
    `(let* ((,cv ,c) (,r (f32 (elt ,cv 0))) (,g (f32 (elt ,cv 1))) (,b (f32 (elt ,cv 2))) (,a (col-a ,cv)))
       (declare (single-float ,r ,g ,b ,a))
       ,@body)))

(defmacro %quad-verts (x0 y0 x1 y1 u0 v0 u1 v1 c0 c1 vertical)
  "Body of %UI-QUAD / %UI-RECT on single-float corner and uv forms: color C0 at top/left, C1 at
bottom/right (VERTICAL chooses the axis). Corners TL TR BR / TL BR BL."
  `(%col-floats (r0 g0 b0 a0) ,c0
     (%col-floats (r1 g1 b1 a1) ,c1
       (let* ((x0 ,x0) (y0 ,y0) (x1 ,x1) (y1 ,y1) (u0 ,u0) (v0 ,v0) (u1 ,u1) (v1 ,v1) (vert ,vertical))
         (declare (single-float x0 y0 x1 y1 u0 v0 u1 v1))
         (macrolet ((v (x y u vv second)   ; "second" color = bottom (vertical) or right (horizontal)
                      `(if ,second (uvtx ,x ,y r1 g1 b1 a1 ,u ,vv) (uvtx ,x ,y r0 g0 b0 a0 ,u ,vv))))
           (with-ui-verts (d o 6)
             (v x0 y0 u0 v0 nil) (v x1 y0 u1 v0 (not vert)) (v x1 y1 u1 v1 t)
             (v x0 y0 u0 v0 nil) (v x1 y1 u1 v1 t) (v x0 y1 u0 v1 vert)))))))

(defun-fast %ui-rect (x y w h c0 c1 vertical)
  "A solid-cell quad from a pixel rect (the + happens here, on unboxed floats)."
  (let* ((x (f32 x)) (y (f32 y)) (w (f32 w)) (h (f32 h)))
    (declare (single-float x y w h))
    (%quad-verts x y (+ x w) (+ y h) +white-u+ +white-v+ +white-u+ +white-v+ c0 c1 vertical)))

(defun ui-rect (x y w h color)
  "Filled rectangle."
  (%ui-rect x y w h color color t))

(defun ui-gradient (x y w h color1 color2 &key (vertical t))
  "Rectangle blending COLOR1 → COLOR2 top→bottom (or left→right with :vertical nil)."
  (%ui-rect x y w h color1 color2 vertical))

(defun ui-rect-outline (x y w h color &optional (thickness 1))
  (let ((tk thickness))
    (ui-rect x y w tk color) (ui-rect x (- (+ y h) tk) w tk color)
    (ui-rect x (+ y tk) tk (- h (* 2 tk)) color) (ui-rect (- (+ x w) tk) (+ y tk) tk (- h (* 2 tk)) color)))

(defun ui-bar (x y w h fraction color &key color2 (bg '(0 0 0 0.55)) border (border-width 1))
  "Horizontal meter: BG, fill FRACTION (0..1) with COLOR (→ COLOR2 gradient left→right), optional BORDER color."
  (let ((f (max 0 (min 1 fraction))))
    (when bg (ui-rect x y w h bg))
    (when (plusp f) (ui-gradient x y (* w f) h color (or color2 color) :vertical nil))
    (when border (ui-rect-outline (- x border-width) (- y border-width) (+ w (* 2 border-width)) (+ h (* 2 border-width))
                                  border border-width))))

;;; ---------------------------------------------------------------- free quads & block text
(defmacro %poly4-verts (x0 y0 x1 y1 x2 y2 x3 y3 r0 g0 b0 a0 r1 g1 b1 a1)
  "Inside WITH-UI-VERTS (6): quad TL TR BR BL, color 0 on TL/TR, color 1 on BR/BL."
  `(progn (uvtx ,x0 ,y0 ,r0 ,g0 ,b0 ,a0) (uvtx ,x1 ,y1 ,r0 ,g0 ,b0 ,a0) (uvtx ,x2 ,y2 ,r1 ,g1 ,b1 ,a1)
          (uvtx ,x0 ,y0 ,r0 ,g0 ,b0 ,a0) (uvtx ,x2 ,y2 ,r1 ,g1 ,b1 ,a1) (uvtx ,x3 ,y3 ,r1 ,g1 ,b1 ,a1)))

(defmacro %ui-poly4-inline (x0 y0 x1 y1 x2 y2 x3 y3 c0 c1)
  (let ((vs (loop repeat 8 collect (gensym "P"))) (k0 (gensym "C")) (k1 (gensym "C")))
    `(let* (,@(mapcar (lambda (v e) `(,v (f32 ,e))) vs (list x0 y0 x1 y1 x2 y2 x3 y3)) (,k0 ,c0) (,k1 ,c1))
       (declare (single-float ,@vs))
       (%col-floats (r0 g0 b0 a0) ,k0
         (%col-floats (r1 g1 b1 a1) ,k1
           (with-ui-verts (d o 6) (%poly4-verts ,@vs r0 g0 b0 a0 r1 g1 b1 a1))))
       nil)))

;; A function (for #') plus a compiler macro: a direct call is expanded in place, so float
;; coordinates are not boxed (the call boxed 8 floats).
(defun %ui-poly4 (x0 y0 x1 y1 x2 y2 x3 y3 c0 c1)
  "Solid quad TL TR BR BL (any shape, e.g. a sheared pixel or a slash); C0 on TL/TR, C1 on BR/BL."
  (%ui-poly4-inline x0 y0 x1 y1 x2 y2 x3 y3 c0 c1))
(eval-when (:compile-toplevel :load-toplevel :execute)   ; ECL: else not seen by the compiler
  (define-compiler-macro %ui-poly4 (&rest args) `(%ui-poly4-inline ,@args)))

(declaim (type f32vec *bt-c0* *bt-c1*))
(defvar *bt-c0* (make-f32 4) "UI-BLOCK-TEXT: rgba of COLOR (top row)")
(defvar *bt-c1* (make-f32 4) "UI-BLOCK-TEXT: rgba of COLOR2 (bottom row)")

(defun-fast %block-text (str x0 y px sh)
  "UI-BLOCK-TEXT's pixel loop (unboxed floats: no consing). Row colors lerp *BT-C0* -> *BT-C1*."
  (declare (single-float x0 y px sh))
  (let* ((font +font-5x7+) (ca *bt-c0*) (cb *bt-c1*) (n (length str)))
    (declare (simple-vector font) (type f32vec ca cb) (fixnum n))
    (dotimes (row 7)
      (let* ((u0 (/ (i->f row) 7f0)) (u1 (/ (i->f (1+ row)) 7f0))
             (r0 (+ (aref ca 0) (* (- (aref cb 0) (aref ca 0)) u0))) (g0 (+ (aref ca 1) (* (- (aref cb 1) (aref ca 1)) u0)))
             (b0 (+ (aref ca 2) (* (- (aref cb 2) (aref ca 2)) u0))) (a0 (+ (aref ca 3) (* (- (aref cb 3) (aref ca 3)) u0)))
             (r1 (+ (aref ca 0) (* (- (aref cb 0) (aref ca 0)) u1))) (g1 (+ (aref ca 1) (* (- (aref cb 1) (aref ca 1)) u1)))
             (b1 (+ (aref ca 2) (* (- (aref cb 2) (aref ca 2)) u1))) (a1 (+ (aref ca 3) (* (- (aref cb 3) (aref ca 3)) u1)))
             (ty (+ y (* px (i->f row)))) (by (+ ty px))
             (st (* sh (i->f (- 7 row)))) (sb (* sh (i->f (- 6 row)))))
        (declare (single-float u0 u1 r0 g0 b0 a0 r1 g1 b1 a1 ty by st sb))
        (dotimes (i n)
          (let* ((code (char-code (char str i))) (g (if (<= 32 code 126) (- code 32) 31)))
            (declare (fixnum code g))
            (dotimes (col 5)
              (when (logbitp row (the fixnum (svref font (+ (* g 5) col))))
                (let* ((cx (+ x0 (* px (i->f (+ (* i 6) col))))) (xa (+ cx st)) (xb (+ cx sb)))
                  (declare (single-float cx xa xb))
                  (with-ui-verts (d o 6)
                    (%poly4-verts xa ty (+ xa px) ty (+ xb px) by xb by r0 g0 b0 a0 r1 g1 b1 a1)))))))))))

(defun ui-block-text (str x y px &key (color '(1 1 1 1)) color2 (shear 0.0) (align :left))
  "Large text drawn as solid font-pixel blocks of PX pixels (crisp at any size, no atlas sampling).
Y = top edge. SHEAR leans it (px per px of height, italic). Rows blend COLOR (top) -> COLOR2 (bottom).
Returns the width in pixels. Conses a few boxed floats per call, nothing per font pixel."
  (let* ((n (length str)) (px (f32 px)) (sh (* (f32 shear) px)) (w (* px (max 0 (- (* 6 n) 1))))
         (c1 (or color2 color)) (ca *bt-c0*) (cb *bt-c1*)
         (x0 (- (f32 x) (ecase align (:left 0.0) (:center (/ (+ w (* 7 sh)) 2)) (:right (+ w (* 7 sh)))))))
    (dotimes (k 4)
      (setf (aref ca k) (f32 (if (< k 3) (elt color k) (col-a color)))
            (aref cb k) (f32 (if (< k 3) (elt c1 k) (col-a c1)))))
    (%block-text str (f32 x0) (f32 y) px sh)
    w))

(defun ui-big-text (str x y scale color shadow s &key (shear 0.18))
  "Large centred block text (UI-BLOCK-TEXT, slight italic SHEAR) with a drop SHADOW colour offset
2 px x the UI scale S; Y is the text's vertical centre, SCALE the block size in pixels. Shrinks to
fit the window width (never below 1 px blocks). Titles, banners, big words (both games)."
  (let* ((w (window-width)) (px (max 1 (min scale (floor (* 0.92 w) (max 1 (+ 2 (text-width str 1)))))))
         (y (- y (* 3.5 px))) (d (* 2 s)))
    (ui-block-text str (+ x d) (+ y d) px :color shadow :shear shear :align :center)
    (ui-block-text str x y px :color color :shear shear :align :center)))

;;; ---------------------------------------------------------------- bitmaps (hand-made glyphs, icons)
;;; A bitmap is drawn as merged rectangles (runs extended downward), computed once per ROWS list and
;;; cached; the per-frame loop is float math in DEFUN-FAST writing WITH-UI-VERTS quads (0 bytes).
;;; Hand-made glyphs (e.g. kanji rasterised to rows once) and icons.
(declaim (type f32vec *bm-col*))
(defvar *bm-col* (make-f32 8) "top rgba, bottom rgba of the bitmap being drawn")
(defvar *bm-cache* (make-hash-table :test 'eq) "rows list -> merged rectangles")

(defun %bm-rects (rows w)
  "Rectangles covering the set bits of ROWS (W bits wide, MSB left) as a fixnum vector of
col0 row0 col1 row1 (exclusive ends): each row run is extended down while the rows below are set."
  (or (gethash rows *bm-cache*)
      (setf (gethash rows *bm-cache*)
            (let* ((n (length rows)) (g (make-array (list n w) :initial-element nil)) (out nil))
              (loop for bits in rows for r from 0 do (dotimes (c w) (setf (aref g r c) (logbitp (- w 1 c) bits))))
              (dotimes (r n)
                (let ((c 0))
                  (loop while (< c w) do
                    (if (aref g r c)
                        (let ((c0 c) (r1 (1+ r)))
                          (loop while (and (< c w) (aref g r c)) do (incf c))
                          (loop while (and (< r1 n) (loop for k from c0 below c always (aref g r1 k))) do (incf r1))
                          (loop for rr from r below r1 do (loop for k from c0 below c do (setf (aref g rr k) nil)))
                          (push (list c0 r c r1) out))
                        (incf c)))))
              (coerce (apply #'append (nreverse out)) '(simple-array fixnum (*)))))))

(defun-fast %bm-draw (rects x y px sh n)
  (declare (type (simple-array fixnum (*)) rects) (single-float x y px sh) (fixnum n))
  (let* ((col *bm-col*) (inv (/ 1f0 (i->f n))))
    (declare (type f32vec col) (single-float inv))
    (loop for i fixnum from 0 below (length rects) by 4 do
      (let* ((c0 (aref rects i)) (r0 (aref rects (+ i 1))) (c1 (aref rects (+ i 2))) (r1 (aref rects (+ i 3)))
             (u0 (* (i->f r0) inv)) (u1 (* (i->f r1) inv))
             (x0 (+ x (* px (i->f c0)))) (x1 (+ x (* px (i->f c1))))
             (ty (+ y (* px (i->f r0)))) (by (+ y (* px (i->f r1))))
             (st (* sh (i->f (- n r0)))) (sb (* sh (i->f (- n r1)))))
        (declare (fixnum c0 r0 c1 r1) (single-float u0 u1 x0 x1 ty by st sb))
        (macrolet ((lerp (k u) `(+ (aref col ,k) (* ,u (- (aref col (+ ,k 4)) (aref col ,k))))))
          (let* ((r0 (lerp 0 u0)) (g0 (lerp 1 u0)) (b0 (lerp 2 u0)) (a0 (lerp 3 u0))
                 (r1 (lerp 0 u1)) (g1 (lerp 1 u1)) (b1 (lerp 2 u1)) (a1 (lerp 3 u1))
                 (xa (+ x0 st)) (xb (+ x1 st)) (xc (+ x1 sb)) (xd (+ x0 sb)))
            (declare (single-float r0 g0 b0 a0 r1 g1 b1 a1 xa xb xc xd))
            (with-ui-verts (d o 6)            ; TL TR BR / TL BR BL, top colour -> bottom colour
              (uvtx xa ty r0 g0 b0 a0) (uvtx xb ty r0 g0 b0 a0) (uvtx xc by r1 g1 b1 a1)
              (uvtx xa ty r0 g0 b0 a0) (uvtx xc by r1 g1 b1 a1) (uvtx xd by r1 g1 b1 a1))))))))

(defun ui-bitmap (rows x y px &key (color '(1 1 1 1)) color2 (shear 0.0) width)
  "Draw ROWS (a list of integers, one per row, MSB = leftmost column) as solid PX-pixel blocks
with the top-left at (x y): UI-BLOCK-TEXT for any bitmap. WIDTH (bits) defaults to the widest
row's INTEGER-LENGTH. COLOR (top) → COLOR2 (bottom); SHEAR leans it (italic). Pass the same
(EQ) ROWS list every frame: its merged rectangles are cached. Returns the width in pixels."
  (let* ((w (or width (reduce #'max rows :key #'integer-length :initial-value 0)))
         (c1 (or color2 color)) (col *bm-col*))
    (dotimes (k 4)
      (setf (aref col k) (f32 (if (< k (length color)) (elt color k) 1))
            (aref col (+ k 4)) (f32 (if (< k (length c1)) (elt c1 k) 1))))
    (%bm-draw (%bm-rects rows w) (f32 x) (f32 y) (f32 px) (f32 (* shear px)) (length rows))
    (* w px)))

;;; ---------------------------------------------------------------- text
(defun text-width (str &optional (scale 2))
  "Pixel width of the widest line of STR."
  (let ((best 0) (cur 0))
    (loop for ch across str do (if (char= ch #\Newline) (setf cur 0) (setf best (max best (incf cur)))))
    (max 0 (- (* best +glyph-w+ scale) scale))))

(defun-fast %glyph-run (str start end x y s r g b a)
  "UI-TEXT's glyph loop for one line: STR[START, END) from pixel X at top Y, glyph scale S, colour
(R G B A); atlas-textured quads written with WITH-UI-VERTS (unboxed floats: no consing)."
  (declare (fixnum start end s) (single-float x y r g b a))
  (let* ((w (i->f (* 5 s))) (h (i->f (* 7 s))) (du (/ 5f0 +atlas-w+)) (dv (/ 7f0 +atlas-h+))
         (y1 (+ y h)) (cx x))
    (declare (single-float w h du dv y1 cx))
    (loop for i fixnum from start below end do
      (let* ((code (char-code (char str i))) (gl (if (<= 32 code 126) (- code 32) 31)))   ; 31 = #\?
        (declare (fixnum code gl))
        (unless (= gl 0)
          (let* ((u (/ (i->f (* (mod gl 16) +glyph-w+)) (i->f +atlas-w+)))
                 (v (/ (i->f (* (floor gl 16) +glyph-h+)) (i->f +atlas-h+)))
                 (u1 (+ u du)) (v1 (+ v dv)) (x1 (+ cx w)))
            (declare (single-float u v u1 v1 x1))
            (with-ui-verts (d o 6)
              (uvtx cx y r g b a u v) (uvtx x1 y r g b a u1 v) (uvtx x1 y1 r g b a u1 v1)
              (uvtx cx y r g b a u v) (uvtx x1 y1 r g b a u1 v1) (uvtx cx y1 r g b a u v1))))
        (setf cx (+ cx (i->f (* +glyph-w+ s))))))))

(defun ui-text (str x y &key (scale 2) (color '(1 1 1 1)) (align :left) shadow)
  "Draw STR with its top edge at Y. ALIGN :left/:center/:right is relative to X (per line).
SHADOW: T or a color → 1-scale drop shadow. Returns the width in pixels. Conses only a few boxed
numbers per line (the glyphs are written by %GLYPH-RUN)."
  (let ((s (max 1 (round scale))))
    (when shadow
      (ui-text str (+ x s) (+ y s) :scale s :align align :color (if (eq shadow t) '(0 0 0 0.75) shadow)))
    (%col-floats (r g b a) color
      (let ((cy y) (start 0) (n (length str)))
        (loop
          (let* ((end (or (position #\Newline str :start start) n))
                 (lw (max 0 (- (* (- end start) +glyph-w+ s) s)))
                 (cx (round (ecase align (:left x) (:center (- x (/ lw 2))) (:right (- x lw))))))
            (%glyph-run str start end (f32 cx) (f32 cy) s r g b a)
            (when (>= end n) (return))
            (setf start (1+ end) cy (+ cy (* 10 s))))))))
  (text-width str scale))
