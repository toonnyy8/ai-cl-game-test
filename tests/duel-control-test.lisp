;;;; duel-control-test.lisp — checks SOUL DUEL's controls (duel/lisp/control.lisp over the engine's
;;;; vpad, engine/lisp/input.lisp) on the host: buffer window, consume, command priority, modifier
;;;; combos, opponent-relative directions, and that a device read through the binding tables equals
;;;; direct injection (VPAD-SET!). The vpad itself is also checked by tests/input-test.lisp.
;;;;   $ECL_HOST --norc --load tests/duel-control-test.lisp
(dolist (f '("package" "math" "hitvol" "input"))
  (load (merge-pathnames (format nil "../engine/lisp/~a.lisp" f) *load-truename*)))
(defpackage :duel (:use :cl :engine))
(dolist (f '("tuning" "rules" "control"))
  (load (merge-pathnames (format nil "../duel/lisp/~a.lisp" f) *load-truename*)))
(in-package :duel)

(defvar *fails* 0)
(defvar *checks* 0)
(defmacro check (form)
  `(progn (incf *checks*) (unless ,form (incf *fails*) (format t "FAIL: ~s~%" ',form))))
(defun ~= (a b) (< (abs (- a b)) 1e-3))
(defun steps (vp n) (dotimes (i n) (vpad-begin-step! vp)))
(defun tap (vp action)
  "Press ACTION for one step (down this step, released at the next)."
  (vpad-begin-step! vp) (vpad-set! vp action t) (vpad-begin-step! vp) (vpad-set! vp action nil))
(defun command (vp &optional allowed) (multiple-value-list (vpad-command vp *commands* allowed)))

(check (= (length *vpad-actions*) 9 (length (vpad-press (new-vpad)))))

;;; ---------------------------------------------------------------- buffer window, consume, hold
(let ((vp (new-vpad)))
  (vpad-begin-step! vp)
  (vpad-set! vp :quick t)
  (check (and (vpad-pressed vp :quick) (vpad-down vp :quick) (= (vpad-held vp :quick) 1)))
  (vpad-set! vp :quick nil)
  (steps vp 9)
  (check (vpad-pressed vp :quick))                            ; 10th step: still buffered
  (steps vp 1)
  (check (not (vpad-pressed vp :quick)))                      ; 11th: gone
  (check (not (vpad-pressed vp :flash)))
  (tap vp :flash)
  (check (and (vpad-pressed vp :flash) (not (vpad-pressed vp :flash 1))))   ; WITHIN narrows it
  (vpad-consume! vp :flash)
  (check (not (vpad-pressed vp :flash)))
  ;; holding does not re-press: a consumed held button needs a release
  (vpad-begin-step! vp) (vpad-set! vp :guard t)
  (vpad-consume! vp :guard)
  (steps vp 3) (vpad-set! vp :guard t)
  (check (and (vpad-down vp :guard) (not (vpad-pressed vp :guard)) (= (vpad-held vp :guard) 4)))
  (vpad-set! vp :guard nil)
  (check (and (not (vpad-down vp :guard)) (= (vpad-held vp :guard) 0)))
  (vpad-set! vp :guard t)
  (check (vpad-pressed vp :guard))
  (vpad-clear! vp)
  (check (and (not (vpad-down vp :guard)) (not (vpad-pressed vp :guard)) (null (vpad-command vp *commands*)))))

;;; ---------------------------------------------------------------- priority and modifier combos
(flet ((pressed (&rest actions)
         (let ((vp (new-vpad)))
           (vpad-begin-step! vp)
           (dolist (a actions) (vpad-set! vp a t))
           vp)))
  (check (equal (command (pressed :quick)) '(:q :quick)))
  (check (equal (command (pressed :quick :flash)) '(:f :flash)))        ; mash J+K = Flash
  (check (equal (command (pressed :flash :sig)) '(:sig :sig)))
  (check (equal (command (pressed :quick :step)) '(:step :step)))       ; escape first
  (check (equal (command (pressed :breaker :sig)) '(:breaker :breaker)))
  (check (equal (command (pressed :quick :kikon :step)) '(:kikon :kikon)))
  (check (equal (command (pressed :awaken :step)) '(:awaken :awaken)))
  (check (equal (command (pressed :mod :flash)) '(:sp1 :flash)))
  (check (equal (command (pressed :mod :sig)) '(:sp2 :sig)))
  (check (equal (command (pressed :mod :step)) '(:hoho :step)))
  (check (equal (command (pressed :mod :quick)) '(:burst :quick)))
  (check (equal (command (pressed :mod :breaker)) '(:breaker :breaker)))   ; :any
  (check (equal (command (pressed :mod :quick :sig)) '(:burst :quick)))   ; escapes before SPs
  (check (equal (command (pressed :mod :flash :sig)) '(:sp2 :sig)))
  ;; the modifier is taken at press time (order within a step does not matter)
  (let ((vp (new-vpad)))
    (vpad-begin-step! vp) (vpad-set! vp :flash t) (vpad-set! vp :mod t)
    (check (equal (command vp) '(:sp1 :flash))))
  (let ((vp (pressed :flash)))                                          ; Flash first, mod later
    (vpad-begin-step! vp) (vpad-set! vp :mod t)
    (check (equal (command vp) '(:f :flash))))
  (let ((vp (pressed :mod :flash)))                                     ; mod released: still SP1
    (vpad-begin-step! vp) (vpad-set! vp :mod nil)
    (check (equal (command vp) '(:sp1 :flash))))
  ;; ALLOWED filters (a cancel window only takes SP / Hoho); a modified press never falls back
  (check (null (vpad-command (pressed :quick) *commands* '(:sp1 :sp2 :hoho))))
  (check (equal (command (pressed :quick :mod :flash) '(:sp1 :sp2 :hoho)) '(:sp1 :flash)))
  (check (null (vpad-command (pressed :mod :flash) *commands* '(:q :f))))
  (check (equal (command (pressed :quick :flash) '(:q)) '(:q :quick)))
  ;; consume the button the command reports, then the next command comes up
  (let ((vp (pressed :quick :flash)))
    (vpad-consume! vp (second (command vp)))
    (check (equal (command vp) '(:q :quick)))))

;;; ---------------------------------------------------------------- stick, relative directions
(let ((vp (new-vpad)))
  (vpad-stick! vp 3.0 4.0)
  (check (and (~= (vpad-sx vp) 0.6) (~= (vpad-sy vp) 0.8)))           ; clamped to unit length
  (vpad-stick! vp 0.3 0.0)
  (check (~= (vpad-sx vp) 0.3))
  ;; stick right with the camera behind P1 (yaw 0) and the opponent ahead: strafe right
  (vpad-stick! vp 1.0 0.0)
  (multiple-value-bind (to st) (stick-toward-strafe (vpad-sx vp) (vpad-sy vp) 0.0 0.0 0.0 0.0 -5.0)
    (check (and (~= to 0.0) (~= st 1.0))))
  ;; the same stick seen from a side camera (yaw 90 deg, looking along -X) moves him at the opponent
  (vpad-stick! vp 0.0 1.0)
  (multiple-value-bind (to st) (stick-toward-strafe (vpad-sx vp) (vpad-sy vp) (deg 90) 0.0 0.0 -5.0 0.0)
    (check (and (~= to 1.0) (~= st 0.0)))))

;;; ---------------------------------------------------------------- injection == device
;;; A fake device: a list of (device name) currently down. VP-DEV reads it through the P1 bindings,
;;; VP-INJ gets the same presses through VPAD-SET!. Their state must match step by step.
(let* ((held nil)
       (down-p (lambda (device name) (member (list device name) held :test #'equal)))
       (vp-dev (new-vpad :reader (lambda (vp) (vpad-read! vp *p1-bindings* down-p))))
       (vp-inj (new-vpad))
       (script '((:key :j) nil ((:key :lshift) (:key :k)) ((:key :lshift)) nil ((:pad :ls) (:pad :rs))
                 ((:key :space) (:key :w) (:key :d)) nil)))
  (dolist (frame script)
    (setf held frame)
    (vpad-begin-step! vp-dev)
    (vpad-begin-step! vp-inj)
    (flet ((on (action) (inputs-down-p (getf *p1-bindings* action) down-p)))
      (loop for a in (reverse (coerce *vpad-actions* 'list)) do (vpad-set! vp-inj a (on a))))   ; any order
    (check (and (equalp (vpad-downs vp-dev) (vpad-downs vp-inj))
                (equalp (vpad-press vp-dev) (vpad-press vp-inj))
                (equalp (vpad-modded vp-dev) (vpad-modded vp-inj))
                (equal (command vp-dev) (command vp-inj)))))
  ;; what the device produced: J = Q, Shift+K = SP1, LS+RS = Awaken, W+D = diagonal stick
  (check (vpad-pressed vp-dev :awaken 3))
  (check (and (~= (vpad-sx vp-dev) 0.0) (~= (vpad-sy vp-dev) 0.0)))  ; last frame: nothing held
  (setf held '((:key :w) (:key :d)))
  (vpad-begin-step! vp-dev)
  (check (and (~= (vpad-sx vp-dev) 0.7071) (~= (vpad-sy vp-dev) 0.7071))))
(let* ((held '((:key :kp-enter) (:key :kp-3)))                      ; P2: numpad mod + Signature
       (vp (new-vpad :reader (lambda (vp) (vpad-read! vp *p2-bindings*
                                                       (lambda (d n) (member (list d n) held :test #'equal))
                                                       0.0 -1.0)))))
  (vpad-begin-step! vp)
  (check (equal (command vp) '(:sp2 :sig)))
  (check (~= (vpad-sy vp) -1.0)))                                     ; analog stick passes through
;; every action has a binding for both players
(check (loop for a across *vpad-actions* always (and (getf *p1-bindings* a) (getf *p2-bindings* a))))

;; a refused top command doesn't hide the next one: both entries are pressed, walked in priority order
(let ((vp (new-vpad)))
  (vpad-begin-step! vp) (vpad-set! vp :kikon t) (vpad-set! vp :quick t)
  (check (equal (loop for (cmd button mod) in *commands* when (vpad-command-pressed-p vp button mod) collect cmd)
                '(:kikon :q))))
;; flush: presses forgotten, holds kept
(let ((vp (new-vpad)))
  (vpad-begin-step! vp) (vpad-set! vp :guard t) (vpad-set! vp :quick t) (vpad-flush! vp)
  (check (and (vpad-down vp :guard) (not (vpad-pressed vp :quick)) (null (vpad-command vp *commands*)))))

(format t "duel-control-test: ~d checks, ~a~%" *checks*
        (if (zerop *fails*) "ALL PASS" (format nil "~d FAILED" *fails*)))
(ext:quit (if (zerop *fails*) 0 1))
