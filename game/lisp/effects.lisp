;;;; effects.lisp — RAVEN EDGE's effect presets on top of the engine fx (engine/lisp/fx.lisp):
;;;; blood mist, sparks, dust, essence orbs, the sword-trail colors (steel / Raven Form) and the
;;;; screen effects (hurt flash, Raven Form vignette, low-HP pulse). GAME_DESIGN §7, §9.
(in-package :raven)

;;; ---------------------------------------------------------------- emitters (colors from §9.1 / §7.4)
(defun-fast fx-mist (x y z dx dy dz n)
  "Crimson blood mist cone along (dx dy dz)."
  (declare (single-float x y z dx dy dz) (fixnum n))
  (fx-burst +p-mist+ n x y z dx dy dz 0.6f0 3f0 5.5f0 0.4f0 0.13f0 0.70f0 0.07f0 0.18f0)
  (fx-burst +p-spark+ (ash n -2) x y z dx dy dz 0.8f0 4f0 7f0 0.25f0 0.02f0 1f0 0.25f0 0.25f0))
(defun-fast fx-sparks (x y z n r g b)
  (declare (single-float x y z r g b) (fixnum n))
  (fx-burst +p-spark+ n x y z 0f0 0.4f0 0f0 1f0 6f0 9f0 0.2f0 0.03f0 r g b)
  (fx-burst +p-glow+ 1 x y z 0f0 0f0 0f0 0f0 0f0 0f0 0.12f0 0.35f0 r g b))
(defun-fast fx-dust (x z n)
  (declare (single-float x z) (fixnum n))
  (dotimes (i n)
    (let* ((a (rnd-range 0f0 6.2832f0)) (sp (rnd-range 3f0 5f0)))
      (declare (single-float a sp))
      (fx-emit +p-dust+ (+ x (* 0.4f0 (f-cos a))) 0.1f0 (+ z (* 0.4f0 (f-sin a))) (* sp (f-cos a)) (rnd-range 0.3f0 1.2f0)
               (* sp (f-sin a)) 0.5f0 (rnd-range 0.1f0 0.2f0) -0.3f0 0.42f0 0.44f0 0.5f0))))
(defun-fast fx-orbs (x y z ngold nblue)
  (declare (single-float x y z) (fixnum ngold nblue))
  (fx-burst +p-orb-a+ ngold x y z 0f0 0.8f0 0f0 1f0 1.5f0 2.5f0 6f0 0.14f0 1f0 0.76f0 0.24f0)     ; gold: gauge
  (fx-burst +p-orb-b+ nblue x y z 0f0 0.8f0 0f0 1f0 1.5f0 2.5f0 6f0 0.14f0 0.25f0 0.66f0 1f0))    ; blue: health

;; essence orbs: gold = orb type A, blue = type B (ORB-ABSORBED is in player.lisp)
(setf *on-orb-absorbed* (lambda (kind) (orb-absorbed (if (eq kind :a) :gold :blue))))

;;; ---------------------------------------------------------------- sword trails
(declaim (type f32vec *trail-core*))
(defvar *trail-core* (make-f32 (* 6 +trail-n+)))
(defmacro trail-count (tr)
  "Samples in trail TR: the engine's MAKE-TRAIL layout is +TRAIL-N+ x (base xyz, tip xyz), then the count."
  `(aref ,tr (* 6 +trail-n+)))

(defun trail-draw (tr raven)
  "Additive ribbon: outer #5B8CFF + inner core #E8F4FF (raven: #5A0010 / #FF1E3C)."
  (declare (type f32vec tr))
  (let ((n (floor (trail-count tr))))
    (when (>= n 2)
      (if raven (fx-trail tr n 0.55 0.0 0.06 0.7) (fx-trail tr n 0.36 0.55 1.0 0.55))
      (let ((c *trail-core*))
        (dotimes (i n)
          (let ((o (* i 6)))
            (dotimes (k 3)
              (setf (aref c (+ o k)) (+ (aref tr (+ o k)) (* 0.55 (- (aref tr (+ o 3 k)) (aref tr (+ o k)))))
                    (aref c (+ o 3 k)) (aref tr (+ o 3 k))))))
        (if raven (fx-trail c n 1.0 0.12 0.24 0.7) (fx-trail c n 0.91 0.96 1.0 0.5))))))

;;; ---------------------------------------------------------------- screen effects (UI layer)
(defstruct (screen-fx (:conc-name screen-))
  (hurt-t 0f0 :type single-float)       ; seconds of red hurt flash left
  (raven 0f0 :type single-float)        ; Raven Form vignette 0..1 (fades in and out)
  (time 0f0 :type single-float))        ; clock for the low-HP pulse
(defvar *screen* (make-screen-fx))
(defun screen-hurt () "Start the red hurt flash." (setf (screen-hurt-t *screen*) 0.2))

(defun fx-draw-screen (dt hp-frac raven)
  "Hurt flash, Raven Form vignette (#5A0010 35 %), low-HP pulse (<25 %, 1.1 Hz)."
  (let ((s *screen*))
    (setf (screen-time s) (+ (screen-time s) dt)
          (screen-raven s) (approach (screen-raven s) (if raven 1f0 0f0) (* 3f0 dt)))
    (when (> (screen-raven s) 0.01) (edge-vignette 0.35 0.0 0.06 (* 0.55 (screen-raven s)) 0.3))
    (when (< hp-frac 0.25)
      (edge-vignette 0.7 0.0 0.05 (+ 0.25 (* 0.2 (sin (* 6.9115 (screen-time s))))) 0.22))
    (when (> (screen-hurt-t s) 0)
      (edge-vignette 0.9 0.05 0.1 (* 0.5 (/ (screen-hurt-t s) 0.2)) 0.35)
      (setf (screen-hurt-t s) (max 0.0 (- (screen-hurt-t s) dt))))))
