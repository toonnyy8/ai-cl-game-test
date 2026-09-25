;;;; platform.lisp — SDL3 window, frame timing, input state (the GPU device lives in render.lisp).
;;;; All input state lives in C (engine/c/platform.c) and the f32vec *INPUT*; queries never cons.
(in-package :engine)

(ffi:clines "#include \"engine/c/engine.h\"")   ; every engine C declaration, for the whole unit

(declaim (type f32vec *input*))
(defvar *input* (make-f32 13) "Per-frame float input/timing block written by PLATFORM-POLL.")
(defvar *max-dt* (/ 1f0 15) "FRAME-DT is clamped to this (seconds).")
(defvar *pointer-lock* t
  "T: a mouse click without the pointer lock requests it and is not reported as a press (mouse-look
games). NIL: clicks are ordinary presses and the pointer is never locked (menus, fighters).")

(defun platform-init (&key (title "game") (width 1280) (height 720))
  "Create the window. Size is only the initial/fallback size: on the web the canvas follows the
page (CSS 100vw x 100vh) and device pixel ratio."
  (unless (ffi:c-inline ((coerce title 'base-string) width height) (:cstring :int :int) :bool
                        "pf_init(#0,#1,#2)" :one-liner t)
    (error "platform-init failed")))

(defun platform-poll ()
  "Pump events, update input edges and timing. Returns NIL when the app should quit."
  (ffi:c-inline (*input* (float *max-dt* 1f0) (if *pointer-lock* 1 0)) (t :float :int) :bool
                "pf_pump(#0->vector.self.sf,#1,#2)" :one-liner t))

;;; ---------------------------------------------------------------- window / time
(declaim (inline window-width window-height frame-dt elapsed-time fps raw-dt
                 mouse-dx mouse-dy mouse-wheel))
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
                         :backslash 49 :quote 52 :grave 53 :capslock 57
                         :insert 73 :home 74 :pageup 75 :delete 76 :end 77 :pagedown 78
                         :right 79 :left 80 :down 81 :up 82
                         :kp-divide 84 :kp-multiply 85 :kp-minus 86 :kp-plus 87 :kp-enter 88
                         :kp-1 89 :kp-2 90 :kp-3 91 :kp-4 92 :kp-5 93 :kp-6 94 :kp-7 95 :kp-8 96 :kp-9 97
                         :kp-0 98 :kp-period 99
                         :lctrl 224 :lshift 225 :lalt 226 :rctrl 228 :rshift 229 :ralt 230
                         :ctrl 224 :shift 225 :alt 226)
          by #'cddr do (setf (gethash k h) v))
    h)
  "Keyword -> SDL scancode (US layout positions).")

(defun scancode (k)
  (if (integerp k) k (or (gethash k *scancodes*) (error "unknown key ~s" k))))
(defun key-down (k)
  "K: keyword like :w :space :left :lshift :escape :1 :f1 :kp-1 :kp-enter, or an SDL scancode integer
(the table *SCANCODES* lists every name)."
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

;;; ---------------------------------------------------------------- gamepads
;;; Up to 4 open pads in stable slots 0..3: a newly connected pad takes the first free slot and keeps
;;; it until it is unplugged (the others do not move). Every reader takes an optional PAD slot
;;; (default 0). Pad 0's sticks/triggers are also in *INPUT*, so the zero-argument readers stay inline.
(defun pad-button (b)
  (if (integerp b) b
      (ecase b ((:a :south) 0) ((:b :east) 1) ((:x :west) 2) ((:y :north) 3) (:back 4) (:guide 5) (:start 6)
        (:ls 7) (:rs 8) (:lb 9) (:rb 10) (:dpad-up 11) (:dpad-down 12) (:dpad-left 13) (:dpad-right 14)
        (:lt 16) (:rt 17))))
(defun pad-count () "Number of open pads (0..4)." (ffi:c-inline () () :int "pf_pad_count()" :one-liner t))
(defun pad-connected-p (&optional (pad 0)) (ffi:c-inline (pad) (:int) :bool "pf_pad_connected(#0)" :one-liner t))
(defun pad-down (b &optional (pad 0))
  "B: :a :b :x :y :lb :rb :lt :rt :back :start :ls :rs :dpad-up/-down/-left/-right."
  (ffi:c-inline (pad (pad-button b)) (:int :int) :bool "pf_pad_down(#0,#1)" :one-liner t))
(defun pad-pressed (b &optional (pad 0)) (ffi:c-inline (pad (pad-button b)) (:int :int) :bool "pf_pad_pressed(#0,#1)" :one-liner t))
(defmacro %pad-axis (pad lane axis)
  "Pad 0 (a literal 0) reads *INPUT*[LANE] inline; any other pad asks C. Both give an unboxed float."
  (if (eql pad 0)
      `(aref *input* ,lane)
      `(ffi:c-inline (,pad) (:int) :float ,(format nil "pf_pad_axis(#0,~d)" axis) :one-liner t)))
;; Sticks: -1..1 after the radial deadzone, +Y = up. Triggers: 0..1.
;; Each reader is a function plus a compiler macro, so a call like (pad-lx) or (pad-lx 1) compiles to
;; %PAD-AXIS in place: no call and no boxed float (an inline defun with an optional argument boxes).
(macrolet ((def-pad-axis (name lane axis)
             `(progn (defun ,name (&optional (pad 0)) (%pad-axis pad ,lane ,axis))
                     (eval-when (:compile-toplevel :load-toplevel :execute)   ; ECL: else not seen by the compiler
                       (define-compiler-macro ,name (&optional (pad 0)) `(%pad-axis ,pad ,',lane ,',axis))))))
  (def-pad-axis pad-lx 3 0) (def-pad-axis pad-ly 4 1) (def-pad-axis pad-rx 5 2)
  (def-pad-axis pad-ry 6 3) (def-pad-axis pad-lt 7 4) (def-pad-axis pad-rt 8 5))
