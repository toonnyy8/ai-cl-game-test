;;;; platform.lisp — SDL3 window, frame timing, input state (the GPU device lives in render.lisp).
;;;; All input state lives in C (engine/c/platform.c) and the f32vec *INPUT*; queries never cons.
(in-package :engine)

(ffi:clines "#include \"engine/c/engine.h\"")   ; every engine C declaration, for the whole unit

(declaim (type f32vec *input*))
(defvar *input* (make-f32 13) "Per-frame float input/timing block written by PLATFORM-POLL.")
(defvar *max-dt* (/ 1f0 15) "FRAME-DT is clamped to this (seconds).")

(defun platform-init (&key (title "game") (width 1280) (height 720))
  "Create the window. Size is only the initial/fallback size: on the web the canvas follows the
page (CSS 100vw x 100vh) and device pixel ratio."
  (unless (ffi:c-inline ((coerce title 'base-string) width height) (:cstring :int :int) :bool
                        "pf_init(#0,#1,#2)" :one-liner t)
    (error "platform-init failed")))

(defun platform-poll ()
  "Pump events, update input edges and timing. Returns NIL when the app should quit."
  (ffi:c-inline (*input* (float *max-dt* 1f0)) (t :float) :bool "pf_pump(#0->vector.self.sf,#1)" :one-liner t))

;;; ---------------------------------------------------------------- window / time
(declaim (inline window-width window-height frame-dt elapsed-time fps raw-dt
                 mouse-dx mouse-dy mouse-wheel
                 pad-lx pad-ly pad-rx pad-ry pad-lt pad-rt))
(defun window-width () (ffi:c-inline () () :int "pf_width()" :one-liner t))
(defun window-height () (ffi:c-inline () () :int "pf_height()" :one-liner t))
(defun window-aspect () (/ (float (window-width) 1f0) (float (max 1 (window-height)) 1f0)))
(defun frame-dt () (aref *input* 9))        ; seconds, clamped to *max-dt*
(defun raw-dt () (aref *input* 11))         ; seconds, unclamped
(defun elapsed-time () (aref *input* 10))   ; seconds since platform-init
(defun fps () (aref *input* 12))            ; smoothed

;;; ---------------------------------------------------------------- keyboard
(defparameter *scancodes*
  (let ((h (make-hash-table :test #'eq)))
    (loop for c across "ABCDEFGHIJKLMNOPQRSTUVWXYZ" for i from 4
          do (setf (gethash (intern (string c) :keyword) h) i))
    (loop for c across "1234567890" for i from 30
          do (setf (gethash (intern (string c) :keyword) h) i))
    (loop for i from 1 to 12 do (setf (gethash (intern (format nil "F~d" i) :keyword) h) (+ 57 i)))
    (loop for (k v) on '(:return 40 :enter 40 :escape 41 :backspace 42 :tab 43 :space 44
                         :minus 45 :equals 46 :lbracket 47 :rbracket 48 :semicolon 51 :comma 54 :period 55 :slash 56
                         :right 79 :left 80 :down 81 :up 82
                         :lctrl 224 :lshift 225 :lalt 226 :rctrl 228 :rshift 229 :ralt 230
                         :ctrl 224 :shift 225 :alt 226)
          by #'cddr do (setf (gethash k h) v))
    h)
  "Keyword -> SDL scancode (US layout positions).")

(defun scancode (k)
  (if (integerp k) k (or (gethash k *scancodes*) (error "unknown key ~s" k))))
(defun key-down (k)
  "K: keyword like :w :space :left :lshift :escape :1 :f1, or an SDL scancode integer."
  (ffi:c-inline ((scancode k)) (:int) :bool "pf_key_down(#0)" :one-liner t))
(defun key-pressed (k) (ffi:c-inline ((scancode k)) (:int) :bool "pf_key_pressed(#0)" :one-liner t))

;;; ---------------------------------------------------------------- mouse
(defun mouse-button (b) (if (integerp b) b (ecase b (:left 1) (:middle 2) (:right 3))))
(defun mouse-down (b) "B: :left :middle :right" (ffi:c-inline ((mouse-button b)) (:int) :bool "pf_mouse_down(#0)" :one-liner t))
(defun mouse-pressed (b) (ffi:c-inline ((mouse-button b)) (:int) :bool "pf_mouse_pressed(#0)" :one-liner t))
(defun mouse-dx () (aref *input* 0))   ; relative motion this frame (CSS pixels); works locked or not
(defun mouse-dy () (aref *input* 1))
(defun mouse-wheel () (aref *input* 2))
(defun pointer-locked-p () (ffi:c-inline () () :bool "pf_locked()" :one-liner t))
(defun focus-lost-p () "T for the frame in which the window lost focus / was hidden." (ffi:c-inline () () :bool "pf_focus_lost()" :one-liner t))

;;; ---------------------------------------------------------------- gamepad (first connected)
(defun pad-button (b)
  (if (integerp b) b
      (ecase b ((:a :south) 0) ((:b :east) 1) ((:x :west) 2) ((:y :north) 3) (:back 4) (:guide 5) (:start 6)
        (:ls 7) (:rs 8) (:lb 9) (:rb 10) (:dpad-up 11) (:dpad-down 12) (:dpad-left 13) (:dpad-right 14)
        (:lt 16) (:rt 17))))
(defun pad-connected-p () (ffi:c-inline () () :bool "pf_pad_connected()" :one-liner t))
(defun pad-down (b)
  "B: :a :b :x :y :lb :rb :lt :rt :back :start :ls :rs :dpad-up/-down/-left/-right."
  (ffi:c-inline ((pad-button b)) (:int) :bool "pf_pad_down(#0)" :one-liner t))
(defun pad-pressed (b) (ffi:c-inline ((pad-button b)) (:int) :bool "pf_pad_pressed(#0)" :one-liner t))
(defun pad-lx () (aref *input* 3))   ; sticks: -1..1 after radial deadzone, +Y = up
(defun pad-ly () (aref *input* 4))
(defun pad-rx () (aref *input* 5))
(defun pad-ry () (aref *input* 6))
(defun pad-lt () (aref *input* 7))   ; triggers 0..1
(defun pad-rt () (aref *input* 8))
