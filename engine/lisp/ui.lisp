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

(defun-fast %ui-quad (x0 y0 x1 y1 u0 v0 u1 v1 c0 c1 vertical)
  "Quad with color C0 at top/left and C1 at bottom/right (VERTICAL chooses the axis)."
  (let ((sb *ui-batch*))
    (when (stream-room-p sb 6)
      (let* ((d (stream-buffer-data sb)) (o (stream-buffer-fill sb))
            (x0 (f32 x0)) (y0 (f32 y0)) (x1 (f32 x1)) (y1 (f32 y1))
            (u0 (f32 u0)) (v0 (f32 v0)) (u1 (f32 u1)) (v1 (f32 v1))
            (r0 (f32 (elt c0 0))) (g0 (f32 (elt c0 1))) (b0 (f32 (elt c0 2))) (a0 (col-a c0))
            (r1 (f32 (elt c1 0))) (g1 (f32 (elt c1 1))) (b1 (f32 (elt c1 2))) (a1 (col-a c1)))
        (declare (type f32vec d) (fixnum o) (single-float x0 y0 x1 y1 u0 v0 u1 v1 r0 g0 b0 a0 r1 g1 b1 a1))
        (macrolet ((v (x y u vv second)
                     `(progn (setf (aref d o) ,x (aref d (+ o 1)) ,y (aref d (+ o 2)) ,u (aref d (+ o 3)) ,vv)
                             (if ,second
                                 (setf (aref d (+ o 4)) r1 (aref d (+ o 5)) g1 (aref d (+ o 6)) b1 (aref d (+ o 7)) a1)
                                 (setf (aref d (+ o 4)) r0 (aref d (+ o 5)) g0 (aref d (+ o 6)) b0 (aref d (+ o 7)) a0))
                             (incf o 8))))
          ;; corners: TL TR BR / TL BR BL; "second" color = bottom (vertical) or right (horizontal)
          (v x0 y0 u0 v0 nil) (v x1 y0 u1 v0 (not vertical)) (v x1 y1 u1 v1 t)
          (v x0 y0 u0 v0 nil) (v x1 y1 u1 v1 t) (v x0 y1 u0 v1 vertical))
        (setf (stream-buffer-fill sb) o)))))

(defun ui-rect (x y w h color)
  "Filled rectangle."
  (%ui-quad x y (+ x w) (+ y h) +white-u+ +white-v+ +white-u+ +white-v+ color color t))

(defun ui-gradient (x y w h color1 color2 &key (vertical t))
  "Rectangle blending COLOR1 → COLOR2 top→bottom (or left→right with :vertical nil)."
  (%ui-quad x y (+ x w) (+ y h) +white-u+ +white-v+ +white-u+ +white-v+ color1 color2 vertical))

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
(defun-fast %ui-poly4 (x0 y0 x1 y1 x2 y2 x3 y3 c0 c1)
  "Solid quad TL TR BR BL (any shape, e.g. a sheared pixel or a slash); C0 on TL/TR, C1 on BR/BL."
  (let ((sb *ui-batch*))
    (when (stream-room-p sb 6)
      (let* ((d (stream-buffer-data sb)) (o (stream-buffer-fill sb)) (u +white-u+) (v +white-v+)
             (x0 (f32 x0)) (y0 (f32 y0)) (x1 (f32 x1)) (y1 (f32 y1)) (x2 (f32 x2)) (y2 (f32 y2)) (x3 (f32 x3)) (y3 (f32 y3))
             (r0 (f32 (elt c0 0))) (g0 (f32 (elt c0 1))) (b0 (f32 (elt c0 2))) (a0 (col-a c0))
             (r1 (f32 (elt c1 0))) (g1 (f32 (elt c1 1))) (b1 (f32 (elt c1 2))) (a1 (col-a c1)))
        (declare (type f32vec d) (fixnum o) (single-float u v x0 y0 x1 y1 x2 y2 x3 y3 r0 g0 b0 a0 r1 g1 b1 a1))
        (macrolet ((vx (x y second)
                     `(progn (setf (aref d o) ,x (aref d (+ o 1)) ,y (aref d (+ o 2)) u (aref d (+ o 3)) v)
                             (if ,second
                                 (setf (aref d (+ o 4)) r1 (aref d (+ o 5)) g1 (aref d (+ o 6)) b1 (aref d (+ o 7)) a1)
                                 (setf (aref d (+ o 4)) r0 (aref d (+ o 5)) g0 (aref d (+ o 6)) b0 (aref d (+ o 7)) a0))
                             (incf o 8))))
          (vx x0 y0 nil) (vx x1 y1 nil) (vx x2 y2 t) (vx x0 y0 nil) (vx x2 y2 t) (vx x3 y3 t))
        (setf (stream-buffer-fill sb) o)))))

(declaim (type f32vec *bt-c0* *bt-c1*))
(defvar *bt-c0* (make-f32 4))
(defvar *bt-c1* (make-f32 4))

(defun ui-block-text (str x y px &key (color '(1 1 1 1)) color2 (shear 0.0) (align :left))
  "Large text drawn as solid font-pixel blocks of PX pixels (crisp at any size, no atlas sampling).
Y = top edge. SHEAR leans it (px per px of height, italic). Rows blend COLOR (top) -> COLOR2 (bottom).
Returns the width in pixels."
  (let* ((n (length str)) (px (f32 px)) (sh (* (f32 shear) px)) (w (* px (max 0 (- (* 6 n) 1))))
         (c1 (or color2 color)) (ca *bt-c0*) (cb *bt-c1*)
         (x0 (- (f32 x) (ecase align (:left 0.0) (:center (/ (+ w (* 7 sh)) 2)) (:right (+ w (* 7 sh)))))))
    (dotimes (row 7)
      (dotimes (k 4)                     ; this row's color band
        (let ((a (if (< k 3) (elt color k) (col-a color))) (b (if (< k 3) (elt c1 k) (col-a c1))))
          (setf (aref ca k) (f32 (lerp a b (/ row 7.0))) (aref cb k) (f32 (lerp a b (/ (1+ row) 7.0))))))
      (let ((ty (+ (f32 y) (* px row))) (st (* sh (- 7 row))) (sb (* sh (- 6 row))))
        (dotimes (i n)
          (let* ((code (char-code (char str i))) (g (if (<= 32 code 126) (- code 32) 31)))
            (dotimes (col 5)
              (when (logbitp row (aref +font-5x7+ (+ (* g 5) col)))
                (let ((cx (+ x0 (* px (+ (* i 6) col)))))
                  (%ui-poly4 (+ cx st) ty (+ cx st px) ty (+ cx sb px) (+ ty px) (+ cx sb) (+ ty px) ca cb))))))))
    w))

;;; ---------------------------------------------------------------- text
(defun text-width (str &optional (scale 2))
  "Pixel width of the widest line of STR."
  (let ((best 0) (cur 0))
    (loop for ch across str do (if (char= ch #\Newline) (setf cur 0) (setf best (max best (incf cur)))))
    (max 0 (- (* best +glyph-w+ scale) scale))))

(defun ui-text (str x y &key (scale 2) (color '(1 1 1 1)) (align :left) shadow)
  "Draw STR with its top edge at Y. ALIGN :left/:center/:right is relative to X (per line).
SHADOW: T or a color → 1-scale drop shadow. Returns the width in pixels."
  (let ((s (max 1 (round scale))))
    (when shadow
      (ui-text str (+ x s) (+ y s) :scale s :align align :color (if (eq shadow t) '(0 0 0 0.75) shadow)))
    (let ((cy y) (start 0) (n (length str)))
      (loop
        (let* ((end (or (position #\Newline str :start start) n))
               (lw (max 0 (- (* (- end start) +glyph-w+ s) s)))
               (cx (round (ecase align (:left x) (:center (- x (/ lw 2))) (:right (- x lw))))))
          (loop for i from start below end
                for code = (char-code (char str i))
                for g = (if (<= 32 code 126) (- code 32) (- (char-code #\?) 32))
                do (unless (= g 0)
                     (let ((u (/ (float (* (mod g 16) +glyph-w+)) +atlas-w+)) (v (/ (float (* (floor g 16) +glyph-h+)) +atlas-h+)))
                       (%ui-quad cx cy (+ cx (* 5 s)) (+ cy (* 7 s)) u v (+ u (/ 5f0 +atlas-w+)) (+ v (/ 7f0 +atlas-h+))
                                 color color t)))
                   (incf cx (* +glyph-w+ s)))
          (when (>= end n) (return))
          (setf start (1+ end) cy (+ cy (* 10 s))))))
    (text-width str scale)))
