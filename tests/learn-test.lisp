;;;; learn-test.lisp — checks the learning CPU's pure part (duel/lisp/learn.lisp, docs/duel/DUEL_LEARNING.md) on the host:
;;;;   $ECL_HOST --norc --load tests/learn-test.lisp
;;;; n-gram counting and backoff, decay, prediction and its counter, the situations and action classes, the EXP3
;;;; update, p_exploit's clamp, the form, the own random stream and the storage round-trip.
(load (merge-pathnames "../engine/lisp/package.lisp" *load-truename*))
(defpackage :duel (:use :cl :engine))
(load (merge-pathnames "../duel/lisp/learn.lisp" *load-truename*))
(in-package :duel)

(defvar *fails* 0)
(defvar *checks* 0)
(defmacro check (form)
  `(progn (incf *checks*) (unless ,form (incf *fails*) (format t "FAIL: ~s~%" ',form))))
(defun ~= (a b &optional (eps 1e-3)) (< (abs (- a b)) eps))
(defun s (k) (learn-sit k))
(defun a (k) (learn-act k))

;;; ---------------------------------------------------------------- counting, decay, backoff, prediction
(let ((tab (make-ltab)))
  (check (null (learn-predict tab (s :wake))))                      ; nothing seen: no prediction
  (learn-observe! tab (s :wake) (a :j))
  (check (~= (aref (ltab-c0 tab) (+ (* 10 (s :wake)) (a :j))) 1.0))
  (check (= (aref (ltab-prev tab) (s :wake)) (a :j)))
  (learn-observe! tab (s :wake) (a :j))                             ; decay then count: 0.97 + 1
  (check (~= (aref (ltab-c0 tab) (+ (* 10 (s :wake)) (a :j))) 1.97))
  (check (~= (aref (ltab-c1 tab) (+ (* 100 (s :wake)) (* 10 (a :j)) (a :j))) 1.0))   ; order 1: J after J
  (multiple-value-bind (act p n) (learn-predict tab (s :wake))
    (check (and (= act (a :j)) (~= p 1.0) (~= n 1.97)))
    (check (learn-confident-p p n)))
  (check (null (learn-predict tab (s :far))))                       ; other situations untouched
  ;; a decayed count: 30 more of I fade J to 0.97^30 of it
  (dotimes (i 30) (learn-observe! tab (s :wake) (a :i)))
  (check (~= (aref (ltab-c0 tab) (+ (* 10 (s :wake)) (a :j))) (* 1.97 (expt 0.97 30)) 1e-3))
  (check (= (learn-predict tab (s :wake)) (a :i))))

;; backoff: order 1 given his last class wins over order 0 when it has evidence
(let ((tab (make-ltab)) (sit (s :close)))
  (dotimes (i 6) (learn-observe! tab sit (a :guard)) (learn-observe! tab sit (a :i)))   ; guard, I, guard, I ...
  ;; his last was I: after I comes guard (order 1), although order 0 is 50 / 50
  (multiple-value-bind (act p) (learn-predict tab sit)
    (check (= act (a :guard)))
    (check (> p 0.6)))
  (learn-observe! tab sit (a :guard))                               ; now his last is guard: after guard comes I
  (check (= (learn-predict tab sit) (a :i)))
  ;; a lone order-1 cell is shrunk toward order 0 (the pseudo-count)
  (let ((t2 (make-ltab)))
    (dotimes (i 4) (learn-observe! t2 sit (a :k)))
    (learn-observe! t2 sit (a :hoho))                                 ; last = hoho: no order-1 row yet
    (multiple-value-bind (p n) (learn-dist t2 sit)
      (check (~= (loop for x across p sum x) 1.0))
      (check (> (aref p (a :k)) (aref p (a :hoho))))
      (check (> n 4.0)))))
(check (not (learn-confident-p 0.9 1.0)))                           ; too little evidence
(check (not (learn-confident-p 0.3 10.0)))                          ; too flat

;;; ---------------------------------------------------------------- counters, situations, classes
(check (eq (learn-counter (a :guard)) :breaker))                    ; I beats guard
(check (eq (learn-counter (a :j)) :guard))                          ; guard beats J
(check (eq (learn-counter (a :i)) :q))                              ; J beats I
(check (eq (learn-counter (a :hoho)) :hoho-punish))
(check (null (learn-counter (a :back))))                           ; backing off: no read
(check (every (lambda (k) (or (eq k :back) (learn-counter (a k)))) *learn-actions*))
(check (eq (learn-counter (a :burst)) :dash-in))                    ; a burst in neutral (WHITE) is rushed
(check (eq (learn-counter (a :burst) (s :c-hit)) :bait))            ; ... while our string hits him, baited
(check (null (learn-counter (a :guard) (s :c-hit))))                ; he took it: go on as usual
(check (eq (learn-counter (a :guard) (s :close)) :breaker))         ; no override elsewhere
(check (and (= (learn-band 1.0) (s :close)) (= (learn-band 3.0) (s :mid)) (= (learn-band 9.0) (s :far))))
(check (and (= (learn-bin 0.5) 0) (= (learn-bin 2.0) 1) (= (learn-bin 20.0) 4)))
(check (= (learn-onset :down :wakeup nil :idle :idle -1 3.0) (s :wake)))
(check (= (learn-onset :idle :idle nil :down :wakeup 5 3.0) (s :knock)))            ; an event overrides neutral
(check (= (learn-onset :guard-hit :guard nil :move :move -1 2.0) (s :h-blocked)))
(check (= (learn-onset :move :move :hit :guard-hit :idle -1 2.0) (s :c-blocked)))
(check (= (learn-onset :move :idle nil :idle :idle 6 2.0) (s :whiff)))
(check (null (learn-onset :move :idle :block :idle :idle 6 2.0)))                   ; a blocked move is no whiff
(check (= (learn-onset :idle :idle nil :idle :idle -1 4.0) (s :mid)))               ; neutral opens when none is
(check (null (learn-onset :idle :idle nil :idle :idle 6 4.0)))
(check (null (learn-onset :idle :move nil :idle :idle -1 4.0)))                     ; not while he is busy
(check (= (learn-onset :stun :stun nil :move :move -1 2.0 t) (s :c-hit)))           ; our hit opened his burst
(check (= (learn-onset :stun :air nil :move :move 7 2.0 t) (s :c-hit)))             ; (an event: overrides neutral)
(check (null (learn-onset :stun :stun nil :move :move 5 2.0 t)))                    ; open already
(check (null (learn-onset :idle :stun nil :move :move -1 2.0 nil)))                 ; no burst possible yet
(check (= (learn-action :idle :move :quick nil 0.0) (a :j)))
(check (= (learn-action :move :move :breaker t 0.0) (a :i)))                        ; a new move
(check (null (learn-action :move :move :breaker nil 0.0)))                          ; the same one
(check (= (learn-action :guard-hit :guard nil nil 0.0) (a :guard)))
(check (= (learn-action :idle :hoho nil nil 0.0) (a :hoho)))
(check (= (learn-action :idle :step nil nil 0.0) (a :hoho)))
(check (= (learn-action :idle :run nil nil 1.5) (a :back)))
(check (null (learn-action :idle :idle nil nil 0.5)))
(check (= (learn-action :stun :stun nil nil 0.0 t) (a :burst)))                    ; a burst begun
(check (= (learn-action :idle :move :quick nil 0.0 t) (a :burst)))                  ; (it wins over the move)
(check (and (= (learn-ctx 0 0.0) 0) (= (learn-ctx 1 0.9) 5) (= (learn-ctx 20 1.0) 23) (= (learn-ctx 2 0.34) 7)))
(check (= (learn-row 3 4) 19))
(check (and (= (learn-episode (s :wake)) 75) (= (learn-episode (s :far)) 60)))

;;; ---------------------------------------------------------------- EXP3
(let ((tab (make-ltab)) (arm (position :breaker *learn-arms*)))
  (check (~= (learn-mult tab 0 arm) 1.0))
  (learn-reward! tab 0 arm 0.5 1.0)                                 ; +eta r / p = 0.3
  (check (~= (aref (ltab-arms tab) arm) 0.3))
  (check (> (learn-mult tab 0 arm) 1.3))
  (check (~= (learn-mult tab 1 arm) 1.0))                           ; other bins untouched
  (learn-reward! tab 0 0 0.5 0.0)                                   ; another arm: the scores decay x gamma
  (check (~= (aref (ltab-arms tab) arm) (* 0.3 0.98)))
  (dotimes (i 50) (learn-reward! tab 0 arm 0.01 -1.0))               ; the floor and the clamp
  (check (~= (learn-mult tab 0 arm) 0.25 1e-3))
  (dotimes (i 50) (learn-reward! tab 0 arm 0.01 1.0))
  (check (~= (learn-mult tab 0 arm) 4.0 1e-2)))
(check (and (= (learn-reward 300 0) 1.0) (= (learn-reward 0 300) -1.0) (~= (learn-reward 75 0) 0.5)))

;; the burst bandits: fresh = the base chance; a paying use raises it, a paying "don't" lowers it
(let ((tab (make-ltab)))
  (check (~= (learn-burst-p tab 1 0.6) 0.6))
  (learn-burst-reward! tab 1 t 0.6 1.0)
  (check (> (learn-burst-p tab 1 0.6) 0.6))
  (check (~= (learn-burst-p tab 0 0.3) 0.3))                        ; other colours untouched
  (dotimes (i 40) (learn-burst-reward! tab 2 nil 0.8 1.0))
  (check (< (learn-burst-p tab 2 0.25) 0.08))                        ; (the clamp: x4 at most)
  (check (~= (learn-burst-p tab 1 0.0) 0.0)))
(check (~= (learn-reward 0 0 75) 0.5))                              ; a heal counts

;;; ---------------------------------------------------------------- p_exploit, form, the own stream
(check (~= (learn-p-exploit 0.0) 0.35))
(check (~= (learn-p-exploit -1.0) 0.15))                            ; he loses a lot: read less (the floor)
(check (~= (learn-p-exploit 1.0) 0.6))                              ; he wins: read more (the cap)
(check (< (learn-p-exploit -0.5) (learn-p-exploit 0.0) (learn-p-exploit 0.5)))
(check (~= (learn-form-after 0.0 1.0 0.2) 0.2))
(check (~= (learn-form-after 0.9 1.0 1.0) 1.0))
(let ((f 0.0)) (dotimes (i 50) (setf f (learn-form-after f -1.0 0.2))) (check (~= f -1.0 1e-3)))
(multiple-value-bind (r1 s1) (learn-rnd 12345)
  (multiple-value-bind (r2 s2) (learn-rnd 12345)
    (check (and (= r1 r2) (= s1 s2) (<= 0 r1) (< r1 1))))             ; deterministic
  (let ((sum 0.0) (st s1)) (dotimes (i 2000) (multiple-value-bind (r n) (learn-rnd st) (incf sum r) (setf st n)))
    (check (< 0.45 (/ sum 2000) 0.55))))

;;; ---------------------------------------------------------------- storage round-trip
(let ((tab (make-ltab)))
  (dotimes (i 20) (learn-observe! tab (s :wake) (a :j)) (learn-observe! tab (s :close) (mod i 3)))
  (learn-observe! tab (s :far) (a :back))
  (learn-reward! tab 2 3 0.25 0.8) (learn-reward! tab 117 9 0.5 -0.6) (learn-burst-reward! tab 1 t 0.5 0.7)
  (setf (ltab-form tab) -0.437)
  (let* ((codes (learn-encode tab)) (back (learn-decode codes)))
    (check (every #'integerp codes))
    (check (every (lambda (c) (< -1 c (expt 2 31))) codes))           ; the page's 32-bit integers
    (check (< (length codes) 999))
    (check (every (lambda (x y) (~= x y 0.051)) (ltab-c0 tab) (ltab-c0 back)))
    (check (every (lambda (x y) (~= x y 0.051)) (ltab-c1 tab) (ltab-c1 back)))
    (check (every (lambda (x y) (~= x y 6e-4)) (ltab-arms tab) (ltab-arms back)))
    (check (every (lambda (x y) (~= x y 6e-4)) (ltab-bursts tab) (ltab-bursts back)))
    (check (equalp (ltab-prev tab) (ltab-prev back)))
    (check (~= (ltab-form back) -0.437))
    (check (equal (learn-predict tab (s :close)) (learn-predict back (s :close))))
    (check (equal codes (learn-encode back)))))                      ; stable
(check (equalp (learn-decode nil) (make-ltab)))                     ; nothing saved: a fresh table
(check (equalp (learn-decode (list 0 -5 (+ (* 3000 65536) 7))) (make-ltab)))     ; garbage: no negative count, unknown entries skipped
(let ((tab (make-ltab)))                                            ; the size cap keeps the largest order-1 cells
  (let ((*learn-decay* 1.0))
    (dotimes (sit 9) (dotimes (p 10) (dotimes (x 10) (learn-observe! tab sit p) (learn-observe! tab sit x)))))
  (let ((*learn-cap* 50)) (check (<= (count-if (lambda (c) (<= 100 (floor c 65536) 999)) (learn-encode tab)) 50)))
  (dotimes (r +learn-rows+) (learn-reward! tab r (mod r 10) 0.5 0.5))
  (let ((*learn-arm-cap* 40)) (check (<= (count-if (lambda (c) (<= 1000 (floor c 65536) 2199)) (learn-encode tab)) 40)))
  (check (< (length (learn-encode tab)) 999)))

;; format 1 (8 situations, 9 classes) read into format 2: the model and the form carried, the old bandit dropped
(flet ((code (i v) (+ (* i 65536) (round v) 32768)))
  (let ((back (learn-decode (list (code 999 1) (code (+ (* 5 9) 1) 20) (code (+ 100 (* 81 7) (* 9 2) 3) 15)
                                  (code 905 3) (code 950 -250) (code 820 400)))))
    (check (~= (aref (ltab-c0 back) (+ (* 10 (s :close)) (a :j))) 2.0))          ; v1 :close (5) is v2's 6
    (check (~= (aref (ltab-c1 back) (+ (* 100 (s :far)) (* 10 (a :k)) (a :i))) 1.5))
    (check (= (aref (ltab-prev back) (s :close)) (a :k)))
    (check (~= (ltab-form back) -0.25))
    (check (every #'zerop (ltab-arms back)))))

(format t "learn-test: ~d checks, ~a~%" *checks* (if (zerop *fails*) "ALL PASS" (format nil "~d FAILED" *fails*)))
(ext:quit (if (zerop *fails*) 0 1))
