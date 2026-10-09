;;;; Host-side checks for engine/lisp/math.lisp:
;;;;   $ECL_HOST --norc --load engine/lisp/package.lisp --load engine/lisp/math.lisp --load tests/test-math.lisp
(in-package :engine)

(defvar *fails* 0)
(defun near (a b &optional (eps 1e-4))
  (if (typep a 'sequence)
      (every (lambda (x y) (< (abs (- x y)) eps)) a b)
      (< (abs (- a b)) eps)))
(defmacro check (form &optional (expect t) (eps 1e-4))
  `(let ((got ,form))
     (unless (if (eq ',expect t) got (near got ,expect ,eps))
       (incf *fails*)
       (format t "~&FAIL: ~s~%   got ~s~%" ',form got))))

(let ((a (v3 1 2 3)) (b (v3 4 5 6)) (o (make-f32 3)))
  (check (v3-add! o a b) #(5 7 9))
  (check (v3-sub! o b a) #(3 3 3))
  (check (v3-dot a b) 32)
  (check (v3-cross! o (v3 1 0 0) (v3 0 1 0)) #(0 0 1))
  (check (v3-len (v3 3 4 0)) 5)
  (check (v3-normalize! o (v3 0 0 5)) #(0 0 1))
  (check (v3-normalize! o (v3 0 0 0)) #(0 0 0))
  (check (v3-lerp! o a b 0.5) #(2.5 3.5 4.5))
  (check (v3-dist a b) (sqrt 27)))

(check (angle-wrap (f32 (* 3 pi))) (f32 (- pi)) 1e-3)
(check (angle-lerp 3.0 -3.0 0.5) (f32 pi) 1e-3)
(check (approach 0.0 1.0 0.25) 0.25)
(check (smoothstep 0.0 1.0 0.5) 0.5)

;; HYPOT / F-HYPOT / COUNTDOWN! are macros whose expansion must be the hand-written form they replace (the native
;; sim and wasm compile the same float operations): symbols stay as they are, other forms are bound once.
(check (equal (macroexpand-1 '(hypot dx dz)) '(sqrt (+ (* dx dx) (* dz dz)))))
(check (equal (macroexpand-1 '(hypot dx dy dz)) '(sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
(check (equal (macroexpand-1 '(f-hypot dx dz)) '(f-sqrt (+ (* dx dx) (* dz dz)))))
(check (equal (macroexpand-1 '(f-hypot ax ay az)) '(f-sqrt (+ (* ax ax) (* ay ay) (* az az)))))
(check (let ((x (macroexpand-1 '(f-hypot (- a b) dz))))
         (and (eq (first x) 'let*) (equal (second (first (second x))) '(- a b))
              (equal (third x) `(declare (single-float ,(first (first (second x))))))
              (equal (fourth x) `(f-sqrt (+ (* ,(first (first (second x))) ,(first (first (second x)))) (* dz dz)))))))
(check (let ((a 5.0) (b 2.0) (c 4.0)) (hypot (- a b) c)) 5.0)
(check (equal (macroexpand-1 '(countdown! (aref v 0) dt)) '(setf (aref v 0) (f32 (max 0.0 (- (aref v 0) dt))))))
(check (let ((x 1.0)) (countdown! x 0.25) x) 0.75)
(check (let ((x 0.1)) (countdown! x 0.25) x) 0.0)

;; m4-euler! axes (right-handed): yaw turns +X to -Z, pitch +Y to +Z, roll +X to +Y;
;; R = Ry(yaw) * Rx(pitch) * Rz(roll)
(let ((o (make-f32 3)) (h (f32 (/ pi 2))))
  (check (m4-transform-dir! o (xform :yaw h) (v3 1 0 0)) #(0 0 -1))
  (check (m4-transform-dir! o (xform :pitch h) (v3 0 1 0)) #(0 0 1))
  (check (m4-transform-dir! o (xform :roll h) (v3 1 0 0)) #(0 1 0))
  (let ((r (make-f32 16)))
    (m4-mul! r (xform :yaw 0.3) (m4-mul! r (xform :pitch 0.7) (xform :roll -1.1)))
    (check (xform :yaw 0.3 :pitch 0.7 :roll -1.1) r)))

;; matrices
(let ((a (xform :x 1 :y 2 :z 3 :yaw 0.4 :pitch -0.2 :roll 0.9 :sx 2 :sy 3 :sz 0.5))
      (inv (make-f32 16)) (o (make-f32 16)))
  (check (m4-invert! inv a) t)
  (check (m4-mul! o a inv) (m4))
  (check (m4-mul! o inv a) (m4))
  ;; aliasing
  (let ((c (m4-copy! (make-f32 16) a))) (m4-mul! c c inv) (check c (m4)))
  (check (null (m4-invert! inv (make-f32 16)))))

(let ((m (m4-translation! (make-f32 16) 1.0 2.0 3.0)) (o (make-f32 3)))
  (check (m4-transform-point! o m (v3 1 1 1)) #(2 3 4))
  (check (m4-transform-dir! o m (v3 1 1 1)) #(1 1 1)))

;; type errors are signalled, not silently misread
(check (handler-case (progn (v3-set! (make-f32 3) 1 2 3) nil) (type-error () t)))
(check (handler-case (progn (m4-mul! (make-f32 16) (m4) #(1 2 3)) nil) (type-error () t)))
;; TRS order: scale, then rotate, then translate
(let ((m (xform :x 10 :yaw (/ pi 2) :sx 2)) (o (make-f32 3)))
  (check (m4-transform-point! o m (v3 1 0 0)) #(10 0 -2)))

;; look-at: eye at +Z looking at origin -> origin maps to (0,0,-5) in view space
(let ((v (m4-look-at! (make-f32 16) (v3 0 0 5) (v3 0 0 0) (v3 0 1 0))) (o (make-f32 3)))
  (check (m4-transform-point! o v (v3 0 0 0)) #(0 0 -5))
  (check (m4-transform-point! o v (v3 1 0 0)) #(1 0 -5)))
(let ((v (m4-look-at! (make-f32 16) (v3 3 4 5) (v3 -1 0 2) (v3 0 1 0))) (o (make-f32 3)))
  (check (m4-transform-point! o v (v3 3 4 5)) #(0 0 0))
  (check (aref (m4-transform-point! o v (v3 -1 0 2)) 2) (- (v3-dist (v3 3 4 5) (v3 -1 0 2)))))

;; perspective (WebGPU depth): point on near plane -> ndc z = 0, far plane -> 1
(let ((p (m4-perspective! (make-f32 16) 1.0 1.5 0.1 100.0)))
  (flet ((ndc-z (z) (let ((cz (+ (* (aref p 10) z) (aref p 14))) (cw (* (aref p 11) z))) (/ cz cw))))
    (check (ndc-z -0.1) 0.0)
    (check (ndc-z -100.0) 1.0 1e-3)))

(if (zerop *fails*)
    (format t "~&test-math: OK~%")
    (progn (format t "~&test-math: ~d FAILURES~%" *fails*) (ext:quit 1)))
(ext:quit 0)
