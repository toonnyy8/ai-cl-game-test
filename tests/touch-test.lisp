;;;; touch-test.lisp — checks the one-thumb gesture recogniser (engine/lisp/touch.lisp) on the host:
;;;; the main rows of docs/DUEL_MOBILE_DESIGN.md §3.2 (tap, rest, flick, up-flick = F with the lift confirm,
;;;; rest then up = Hoho, drag and drag far, back to rest), CANCELED (never a tap, idempotent), the
;;;; focus-loss clear, the latest-contact rule, chips (held until lift, the hold chip) and the pulse latch.
;;;;   $ECL_HOST --norc --load tests/touch-test.lisp
(dolist (f '("package" "math" "input" "touch"))
  (load (merge-pathnames (format nil "../engine/lisp/~a.lisp" f) *load-truename*)))
(defpackage :touch-test (:use :cl :engine))
(in-package :touch-test)

(defvar *fails* 0)
(defvar *checks* 0)
(defmacro check (form)
  `(progn (incf *checks*) (unless ,form (incf *fails*) (format t "FAIL: ~s~%" ',form))))

(defun new ()
  "A recogniser at DPR 1: pad 16..276 x 600..794, chips O (220 548 r36) and AWAKEN (120 548, hold 300 ms)."
  (touch-layout! (make-touch) 1 '(16 600 276 794) '((220 548 36) (120 548 26)) '(0 300)))

(defun feed (tr now &rest events)
  "Feed EVENTS ((type slot x y ms) ...; type 0 down 1 motion 2 up 3 canceled 4 cancel-all), then the clock at NOW."
  (let ((q (engine::touch-q tr)))
    (loop for e in events for i from 0
          do (loop for v in e for j from 0 do (setf (aref q (+ (* 5 i) j)) (float v 1f0))))
    (setf (engine::touch-now tr) (float now 1f0))
    (touch-feed! tr (length events))
    tr))

(defun take (tr) (touch-take! tr) tr)
(defun pulse (tr bit) (touch-pulse-p (take tr) bit))
(defmacro fresh ((tr) &body body) `(let ((,tr (new))) ,@body))

;;; TAP: a short lift inside the slop = one Quick pulse, live for exactly one read
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0) '(1 0 104 702 30) '(2 0 104 702 90))
  (check (pulse tr engine::+tp-tap+))
  (check (not (pulse tr engine::+tp-tap+)))                 ; the next read: released
  (check (touch-tapped-p tr)))                              ; also a menu tap
;;; pulse latch: a frame with no fixed step keeps the pulse pending
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0) '(2 0 100 700 50))
  (feed tr 33)                                               ; a frame, no read
  (check (pulse tr engine::+tp-tap+)))
;;; a long press is no tap; REST: still for tap-ms = guard, and the lift does nothing
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0))
  (check (not (touch-resting-p tr)))
  (feed tr 125)
  (check (touch-resting-p tr))
  (feed tr 140 '(2 0 100 700 140))
  (check (and (not (touch-resting-p tr)) (zerop (engine::touch-pend tr)))))
;;; FLICK (down / side): fires at the crossing, Step + the stroke's direction, before any lift
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0) '(1 0 100 712 10) '(1 0 100 732 30))
  (take tr)
  (check (touch-pulse-p tr engine::+tp-flick+))
  (check (and (touch-flick-down-p tr) (< (touch-sy tr) -0.99) (< (abs (touch-sx tr)) 0.01)))
  (check (touch-step-held-p tr)))                           ; held until the thumb stops or comes back
(fresh (tr)                                                 ; a slow stroke is a drag, not a flick
  (feed tr 16 '(0 0 100 700 0) '(1 0 112 700 20) '(1 0 125 700 200) '(1 0 140 700 260))
  (check (not (pulse tr engine::+tp-flick+)))
  (check (and (> (touch-sx tr) 0.8) (not (touch-step-held-p tr)))))
;;; FLICK UP = F only when the thumb lifts within up-lift-ms of the crossing
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0) '(1 0 100 688 10) '(1 0 100 668 30) '(2 0 100 668 90))
  (check (pulse tr engine::+tp-up+)))
(fresh (tr)                                                 ; not lifted in time: a forward drag
  (feed tr 16 '(0 0 100 700 0) '(1 0 100 688 10) '(1 0 100 668 30))
  (feed tr 200)
  (check (> (touch-sy tr) 0.5))
  (feed tr 216 '(2 0 100 668 210))
  (check (not (pulse tr engine::+tp-up+))))
;;; the 2026-09-27 playtest: a neutral up-flick walked / dashed (the stick and the run ring were live before the
;;; F confirm) and lost its F. Now nothing moves until the flick resolves, even for a long, slow-lifting stroke.
(fresh (tr)
  (feed tr 16 '(0 0 100 780 0) '(1 0 100 768 8) '(1 0 98 750 16))   ; left the slop: undecided, no stick
  (check (and (zerop (touch-sy tr)) (not (touch-step-held-p tr))))
  (feed tr 33 '(1 0 96 730 24) '(1 0 94 700 32) '(1 0 92 670 40) '(1 0 90 640 48))   ; 140 px: past the run ring
  (take tr)
  (check (and (zerop (touch-sy tr)) (zerop (touch-sx tr)) (not (touch-step-held-p tr))
              (not (touch-pulse-p tr engine::+tp-flick+))))
  (feed tr 150 '(2 0 90 640 140))                           ; lifted 116 ms after the crossing
  (let ((l (engine::touch-live (take tr))))
    (check (and (logtest l engine::+tp-up+) (not (logtest l engine::+tp-flick+))))))
(fresh (tr)                                                 ; a right thumb's slanted up-flick (50 deg) is still up
  (feed tr 16 '(0 0 200 750 0) '(1 0 190 742 8) '(1 0 175 732 16) '(1 0 170 725 24) '(2 0 170 725 60))
  (let ((l (engine::touch-live (take tr))))
    (check (and (logtest l engine::+tp-up+) (not (logtest l engine::+tp-flick+))))))
(fresh (tr)                                                 ; a slow drag up still walks, once the window closes
  (feed tr 16 '(0 0 100 700 0) '(1 0 100 694 40) '(1 0 100 688 80))
  (check (zerop (touch-sy tr)))                             ; undecided (a flick could still come)
  (feed tr 250 '(1 0 100 682 120) '(1 0 100 676 160) '(1 0 100 668 240))
  (check (and (> (touch-sy tr) 0.6) (not (touch-step-held-p tr)) (not (pulse tr engine::+tp-up+))))
  (feed tr 300)                                             ; the window also closes on the clock, no motion needed
  (check (> (touch-sy tr) 0.6)))
(fresh (tr)                                                 ; the clock alone ends the undecided phase
  (feed tr 16 '(0 0 100 700 0) '(1 0 100 686 10))
  (feed tr 200)
  (check (> (touch-sy tr) 0.2)))
;;; HOHO: rest, then an up-stroke fires at the crossing when the game allows it (neutral / guard) ...
(fresh (tr)
  (setf (engine::touch-rest-up-ok tr) t)
  (feed tr 16 '(0 0 100 700 0))
  (feed tr 150)
  (feed tr 166 '(1 0 100 688 155) '(1 0 100 668 165))
  (check (pulse tr engine::+tp-hoho+)))
;;; ... and is F otherwise (e.g. mid-move)
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0))
  (feed tr 150)
  (feed tr 166 '(1 0 100 688 155) '(1 0 100 668 165) '(2 0 100 668 180))
  (let ((l (engine::touch-live (take tr))))
    (check (and (logtest l engine::+tp-up+) (not (logtest l engine::+tp-hoho+))))))
;;; DRAG far: Step held beyond the run ring, released back inside 1.3 r; back to rest
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0) '(1 0 110 700 40) '(1 0 125 700 200) '(1 0 140 700 330) '(1 0 190 700 360))
  (check (and (touch-step-held-p tr) (not (pulse tr engine::+tp-flick+))))
  (feed tr 380 '(1 0 150 700 370))
  (check (not (touch-step-held-p tr)))
  (feed tr 400 '(1 0 103 700 390))
  (feed tr 520)
  (check (touch-resting-p tr)))
;;; CANCELED: never a tap; a second cancel (or one for an unknown finger) is harmless
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0) '(3 0 100 700 40) '(3 0 100 700 41) '(3 5 0 0 42))
  (check (and (not (pulse tr engine::+tp-tap+)) (not (touch-tapped-p tr)) (= -1 (engine::touch-gid tr)))))
;;; focus lost: everything released (a resting guard, a held chip)
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0) '(0 1 220 548 0))
  (feed tr 200)
  (check (and (touch-resting-p tr) (touch-chip-down-p tr 0)))
  (feed tr 216 '(4 -1 0 0 210))
  (check (and (not (touch-resting-p tr)) (not (touch-chip-down-p tr 0)))))
;;; the latest contact in the pad wins; the old one's lift is ignored
(fresh (tr)
  (feed tr 16 '(0 0 100 700 0) '(0 1 200 700 5) '(2 0 100 700 40))
  (check (not (pulse tr engine::+tp-tap+)))
  (feed tr 60 '(2 1 200 700 60))
  (check (pulse tr engine::+tp-tap+)))
;;; chips: down on touch, held while the finger slides off, released on lift; the hold chip needs 300 ms
(fresh (tr)
  (feed tr 16 '(0 0 220 548 0) '(1 0 300 450 10))
  (check (and (touch-chip-down-p tr 0) (touch-chip-hit-p tr 0) (= -1 (engine::touch-gid tr))))
  (feed tr 40 '(2 0 300 450 30))
  (check (not (touch-chip-down-p tr 0)))
  (feed tr 60 '(0 2 120 548 50))
  (check (not (touch-chip-down-p tr 1)))
  (feed tr 360)
  (check (touch-chip-down-p tr 1)))
;;; chips inside the pad (the 2026-09-27 deck: the pad spans the whole thumb area, chips win their hit circles):
;;; a touch just inside a chip's hit circle holds the chip; one just outside starts a gesture, whose up-flick
;;; crossing the chip is still an F (a chip only claims touch-downs)
(let ((tr (touch-layout! (make-touch) 1 '(16 364 358 794) '((318 564 26)))))  ; L at the right edge, hit r 34
  (feed tr 16 '(0 0 318 597 0))                                                 ; 33 px below its centre
  (check (and (touch-chip-down-p tr 0) (= -1 (engine::touch-gid tr))))
  (feed tr 40 '(2 0 318 597 30))
  (feed tr 60 '(0 1 318 600 50) '(1 1 318 588 58) '(1 1 318 568 66) '(1 1 318 540 74) '(2 1 318 540 100))
  (let ((l (engine::touch-live (take tr))))
    (check (and (logtest l engine::+tp-up+) (not (touch-chip-down-p tr 0)))))
  (feed tr 200 '(0 2 280 564 190) '(1 2 268 564 198) '(1 2 250 564 206))       ; beside it: a sidestep flick
  (check (and (pulse tr engine::+tp-flick+) (touch-step-held-p tr))))
;;; a touch outside the pad and the chips starts no gesture (still a menu tap)
(fresh (tr)
  (feed tr 16 '(0 0 50 100 0) '(2 0 50 100 40))
  (check (and (not (pulse tr engine::+tp-tap+)) (touch-tapped-p tr))))

(format t "~&touch-test: ~d checks, ~d failures~%" *checks* *fails*)
(ext:quit (if (zerop *fails*) 0 1))
