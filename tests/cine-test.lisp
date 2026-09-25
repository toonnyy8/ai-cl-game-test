;;;; cine-test.lisp — checks the engine's cinematic director (engine/lisp/cine.lisp) on the host, no
;;;; browser, no build: AT fires once on its frame, DURING runs in draw mode with U 0..1, the length,
;;;; the debug hold, skip / abort, *SKIP-CINES*, the three game hooks and CINE-CAM.
;;;;   $ECL_HOST --norc --load tests/cine-test.lisp
(dolist (f '("package" "math" "time"))
  (load (merge-pathnames (format nil "../engine/lisp/~a.lisp" f) *load-truename*)))
(in-package :engine)
(defvar *grade-split* 0.0) (defvar *grade-desat* 0.0)   ; render.lisp's (not host-loadable)
(load (merge-pathnames "../engine/lisp/cine.lisp" *load-truename*))
(defpackage :cine-test (:use :cl :engine))
(in-package :cine-test)

(defvar *fails* 0)
(defvar *checks* 0)
(defmacro check (form)
  `(progn (incf *checks*) (unless ,form (incf *fails*) (format t "FAIL: ~s~%" ',form))))
(defvar *log* nil)
(defun note (x) (push x *log*))

(defcine demo (a v :len 5 :hold 3)
  (at 0 (note (list :at0 cf a v)))
  (at 2 (note :at2) (cine-cam 1 2 3 4 5 6))
  (during (1 3) (note (list :during cf u)))
  (during (0 2 k) (note (list :k k)))
  (when step-p (note (list :step cf))))

(defun run (&optional (frames 10))
  (dotimes (i frames) (when *cine* (cine-draw) (cine-step))))

(setf *cine-begin-hook* (lambda (name a v) (note (list :begin name a v)))
      *cine-actor-hook* (lambda (e) (note (list :actor e)))
      *cine-end-hook* (lambda (c) (note (list :end (and c (cine-name c))))))

;;; a whole run: frame 0 at the start, AT once, DURING in draw mode, the end after LEN frames
(setf *log* nil)
(start-cine 'demo :a :v :after (lambda () (note :after)))
(check (and *cine* (= (cine-cf *cine*) 0) (not *cine-cam*)))
(run)
(let ((log (reverse *log*)))
  (check (equal (first log) '(:begin demo :a :v)))
  (check (= 1 (count '(:at0 0 :a :v) log :test #'equal)))
  (check (= 1 (count :at2 log)))
  (check (equal (remove-if-not (lambda (x) (and (consp x) (eq (car x) :during))) log) '((:during 1 0.0) (:during 2 0.5))))
  (check (equal (remove-if-not (lambda (x) (and (consp x) (eq (car x) :k))) log) '((:k 0.0) (:k 0.5))))
  (check (equal (remove-if-not (lambda (x) (and (consp x) (eq (car x) :step))) log)
                '((:step 0) (:step 1) (:step 2) (:step 3) (:step 4) (:step 5))))
  (check (= 10 (count-if (lambda (x) (and (consp x) (eq (car x) :actor))) log)))   ; 2 actors x 5 steps
  (check (equal (last log 2) '((:end demo) :after))))                             ; end hook, then AFTER
(check (and (null *cine*) (null *cine-cam*)))
(check (equalp *cine-eye* (make-array 3 :element-type 'single-float :initial-contents '(1.0 2.0 3.0))))

;;; the debug hold: stops at frame 3 until released
(setf *log* nil *cine-hold* t)
(start-cine 'demo :a :v)
(run 8)
(check (and *cine* (= (cine-cf *cine*) 3)))
(setf (cine-hold *cine*) nil *cine-hold* nil)
(run 8)
(check (null *cine*))

;;; skip ends on the next step (AFTER runs); abort drops AFTER; *skip-cines* ends at once
(setf *log* nil)
(start-cine 'demo :a :v :after (lambda () (note :after)))
(skip-cine)
(check *cine*)                                    ; still running until the next fixed step
(cine-step)
(check (and (null *cine*) (member :after *log*)))
(setf *log* nil)
(start-cine 'demo :a :v :after (lambda () (note :after)))
(abort-cine)
(check (and (null *cine*) (not (member :after *log*)) (member '(:end demo) *log* :test #'equal)))
(setf *log* nil *skip-cines* t)
(start-cine 'demo :a :v :after (lambda () (note :after)))
(check (and (null *cine*) (member :after *log*) (not (find-if (lambda (x) (and (consp x) (eq (car x) :at0))) *log*))))
(setf *skip-cines* nil)
(check (= (cine-hold-frame 'demo) 3))

(format t "cine-test: ~d checks, ~a~%" *checks* (if (zerop *fails*) "ALL PASS" (format nil "~d FAILED" *fails*)))
(ext:quit (if (zerop *fails*) 0 1))
