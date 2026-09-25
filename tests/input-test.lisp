;;;; input-test.lisp — checks the engine's virtual controller (engine/lisp/input.lisp) on the host,
;;;; no browser, no build: buffering, consume, holds, the modifier, the stick, flush / clear, a
;;;; command table, and that a device read through bindings equals direct injection.
;;;;   $ECL_HOST --norc --load tests/input-test.lisp
;;;; (SOUL DUEL's own buttons, commands and bindings: tests/duel-control-test.lisp.)
(dolist (f '("package" "math" "input"))
  (load (merge-pathnames (format nil "../engine/lisp/~a.lisp" f) *load-truename*)))
(defpackage :input-test (:use :cl :engine))
(in-package :input-test)

(defvar *fails* 0)
(defvar *checks* 0)
(defmacro check (form)
  `(progn (incf *checks*) (unless ,form (incf *fails*) (format t "FAIL: ~s~%" ',form))))
(defun pad (&rest keys) (apply #'make-vpad :actions '(:shift :attack :jump :guard) :modifier :shift keys))
(defun steps (vp n) (dotimes (i n) (vpad-begin-step! vp)))
(defparameter *table* '((:super :attack t) (:jump :jump :any) (:attack :attack nil))
  "A toy command table, highest priority first.")

;;; buffer window (BUFFER steps, this one included), WITHIN, consume
(let ((vp (pad :buffer 5)))
  (vpad-begin-step! vp) (vpad-set! vp :attack t) (vpad-set! vp :attack nil)
  (check (vpad-pressed vp :attack))
  (steps vp 4) (check (vpad-pressed vp :attack))                  ; 5th step: still buffered
  (steps vp 1) (check (not (vpad-pressed vp :attack)))            ; 6th: gone
  (vpad-begin-step! vp) (vpad-set! vp :jump t)
  (steps vp 1) (check (and (vpad-pressed vp :jump) (not (vpad-pressed vp :jump 1))))
  (vpad-consume! vp :jump) (check (not (vpad-pressed vp :jump))))

;;; holds: steps held, no re-press while held, release
(let ((vp (pad)))
  (vpad-begin-step! vp) (vpad-set! vp :guard t) (vpad-consume! vp :guard)
  (steps vp 3) (vpad-set! vp :guard t)
  (check (and (vpad-down vp :guard) (= (vpad-held vp :guard) 4) (not (vpad-pressed vp :guard))))
  (vpad-set! vp :guard nil)
  (check (and (not (vpad-down vp :guard)) (= (vpad-held vp :guard) 0))))

;;; the modifier: held before, pressed in the same step (either order), released later
(flet ((pressed (&rest actions) (let ((vp (pad))) (vpad-begin-step! vp) (dolist (a actions) (vpad-set! vp a t)) vp)))
  (check (not (vpad-modded-p (pressed :attack) :attack)))
  (check (vpad-modded-p (pressed :shift :attack) :attack))
  (check (vpad-modded-p (pressed :attack :shift) :attack))
  (let ((vp (pressed :attack)))                                     ; modifier a step later: not modded
    (vpad-begin-step! vp) (vpad-set! vp :shift t)
    (check (not (vpad-modded-p vp :attack))))
  ;; the command table: priority, MOD T / NIL / :ANY, ALLOWED, the button to consume
  (check (equal (multiple-value-list (vpad-command (pressed :attack) *table*)) '(:attack :attack)))
  (check (equal (multiple-value-list (vpad-command (pressed :shift :attack) *table*)) '(:super :attack)))
  (check (eq (vpad-command (pressed :shift :jump :attack) *table*) :super))
  (check (eq (vpad-command (pressed :shift :jump) *table*) :jump))  ; :any ignores the modifier
  (check (null (vpad-command (pressed :shift :attack) *table* '(:attack))))   ; modded never falls back
  (let ((vp (pressed :jump :attack)))
    (vpad-consume! vp (nth-value 1 (vpad-command vp *table*)))
    (check (eq (vpad-command vp *table*) :attack))))

;;; a vpad without a modifier; unknown names signal
(let ((vp (make-vpad :actions #(:a :b))))
  (vpad-begin-step! vp) (vpad-set! vp :a t)
  (check (and (vpad-pressed vp :a) (not (vpad-modded-p vp :a))))
  (check (null (ignore-errors (vpad-set! vp :c t))))
  (check (null (ignore-errors (make-vpad :actions '(:a) :modifier :b)))))

;;; stick: clamped to unit length, analog below it passes
(let ((vp (pad)))
  (vpad-stick! vp 3.0 4.0)
  (check (and (< (abs (- (vpad-sx vp) 0.6)) 1e-4) (< (abs (- (vpad-sy vp) 0.8)) 1e-4)))
  (vpad-stick! vp 0.3 0.0)
  (check (= (vpad-sx vp) 0.3)))

;;; flush keeps holds, clear releases everything
(let ((vp (pad)))
  (vpad-begin-step! vp) (vpad-set! vp :guard t) (vpad-set! vp :attack t) (vpad-stick! vp 1.0 0.0)
  (vpad-flush! vp)
  (check (and (vpad-down vp :guard) (not (vpad-pressed vp :attack))))
  (vpad-clear! vp)
  (check (and (not (vpad-down vp :guard)) (= (vpad-sx vp) 0.0))))

;;; device read through bindings == direct injection, step by step (chords, directions, analog)
(let* ((held nil)
       (bindings '(:shift ((:key :lshift)) :attack ((:key :j) (:pad :x)) :jump ((:key :space))
                   :guard ((:pad :lb :rb)) :up ((:key :w)) :down ((:key :s)) :left ((:key :a)) :right ((:key :d))))
       (down-p (lambda (device name) (member (list device name) held :test #'equal)))
       (dev (pad :reader (lambda (vp) (vpad-read! vp bindings down-p))))
       (inj (pad)))
  (dolist (frame '(((:key :j)) nil ((:key :lshift) (:pad :x)) ((:pad :lb)) ((:key :w) (:key :d) (:pad :lb) (:pad :rb))))
    (setf held frame)
    (vpad-begin-step! dev) (vpad-begin-step! inj)
    (loop for a in '(:guard :jump :attack :shift)                   ; any order
          do (vpad-set! inj a (inputs-down-p (getf bindings a) down-p)))
    (check (and (equalp (vpad-downs dev) (vpad-downs inj)) (equalp (vpad-press dev) (vpad-press inj))
                (equalp (vpad-modded dev) (vpad-modded inj)))))
  (check (and (vpad-down dev :guard) (vpad-pressed dev :guard)))   ; the LB+RB chord
  (check (and (< (abs (- (vpad-sx dev) 0.7071)) 1e-3) (< (abs (- (vpad-sy dev) 0.7071)) 1e-3))))

(format t "input-test: ~d checks, ~a~%" *checks* (if (zerop *fails*) "ALL PASS" (format nil "~d FAILED" *fails*)))
(ext:quit (if (zerop *fails*) 0 1))
