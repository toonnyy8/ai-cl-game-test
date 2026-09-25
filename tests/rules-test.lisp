;;;; rules-test.lisp — checks game/lisp/rules.lisp (the pure game rules) on the host, no browser, no build:
;;;;   $ECL_HOST --norc --load tests/rules-test.lisp
;;;; The rules file is plain Common Lisp over the engine's plain-CL math and hit volumes, so it loads
;;;; here after engine/lisp/{package,math,hitvol}.lisp (no build, no GPU).
(dolist (f '("package" "math" "hitvol"))
  (load (merge-pathnames (format nil "../engine/lisp/~a.lisp" f) *load-truename*)))
(defpackage :raven (:use :cl :engine))
(load (merge-pathnames "../game/lisp/rules.lisp" *load-truename*))
(in-package :raven)

(defvar *fails* 0)
(defmacro check (form)
  `(unless ,form (incf *fails*) (format t "FAIL: ~s~%" ',form)))
(defun ~= (a b) (< (abs (- a b)) 1e-3))
(defun vol (&rest xs)
  (let ((v (make-array 5 :element-type 'single-float :initial-element 0f0)))
    (loop for x in xs for i from 0 do (setf (aref v i) (float x 1f0)))
    v))
(defun hit (&rest keys) (apply #'make-hitdef keys))

;;; hit volumes: attacker at the origin facing -Z; target cylinder r 0.38 h 1.8 (a grunt)
(flet ((hits (v x z &key (y 0f0) (extra 0f0))
         (vol-hit-p v 0f0 0f0 0f0 0f0 -1f0 (float x 1f0) y (float z 1f0) 0.38f0 1.8f0 extra)))
  (let ((arc (vol 0 2.3 (* 55 (/ pi 180)) 0.2 2.0)))    ; L1: 110 deg, 2.3 m
    (check (hits arc 0 -2))                               ; straight ahead
    (check (not (hits arc 0 2)))                          ; behind
    (check (not (hits arc 0 -3)))                         ; out of reach
    (check (hits arc 0 -3 :extra 0.9f0))                  ; Raven Form reach
    (check (hits arc (* 2 (sin (/ pi 3))) (* -2 (cos (/ pi 3)))))        ; 60 deg off: the body pokes in
    (check (not (hits arc 2 0)))                          ; 90 deg off
    (check (not (hits arc 0 -2 :y 3f0))))                 ; above the slice
  (let ((cap (vol 1 0 1.6 1.1 0.5)))                      ; Rainblade lunge
    (check (hits cap 0 -1.5))
    (check (not (hits cap 0 -2.6))))
  (let ((sph (vol 2 2.0 0.0 3.5)))                        ; Oxhead slam, 2 m ahead, r 3.5
    (check (hits sph 0 -5))
    (check (not (hits sph 0 -5 :y 4f0))))
  (check (hits (vol 3 1.2) 0 -0.5)))                      ; TSPH: (ax ay az) is the target point

;;; a hit on an enemy
(let ((l1 (hit :dmg 10f0 :imp 10f0 :react :flinch :hs 3))
      (h1 (hit :dmg 24f0 :imp 35f0 :react :stagger :hs 6 :hw t))
      (oblit (hit :dmg 999f0 :hs 9 :hw t :flags '(:no-poise :obliterate :unblockable))))
  (flet ((grunt (hd &rest keys)
           (apply #'enemy-hit-outcome hd (append keys '(:poise 10.0 :body-poise 10.0 :hp 60.0 :max-hp 60.0)))))
    (let ((r (grunt l1)))                                 ; poise 10 - 10 breaks: a flinch
      (check (and (eq (eh-result r) :hit) (eq (eh-react r) :flinch) (~= (eh-hp r) 50) (~= (eh-poise r) 10)
                  (eh-poise-hit r) (= (eh-hitstop r) 3) (not (eh-heavy r)))))
    (let ((r (grunt l1 :poise 60.0 :body-poise 60.0)))    ; a brute's poise absorbs it: armored
      (check (and (eq (eh-result r) :armored) (~= (eh-poise r) 50) (= (eh-hitstop r) 2))))
    (check (eq (eh-result (grunt h1 :hp 20.0)) :killed))
    (let ((r (grunt h1 :hp 40.0)))                        ; heavy leaves 16 <= 30 %: crippled
      (check (and (eq (eh-result r) :crippled) (eh-fx-heavy r))))
    (check (eq (eh-result (grunt h1 :hp 40.0 :no-cripple t)) :hit))
    (check (eq (eh-result (grunt h1 :hp 10.0 :boss t :no-cripple t)) :broken))
    (let ((r (grunt l1 :crippled t)))                     ; crippled: any hit kills
      (check (and (eq (eh-result r) :killed) (~= (eh-hp r) 0) (eh-heavy r) (eh-ender r) (= (eh-hitstop r) 6))))
    (check (null (eh-result (grunt l1 :crippled t :boss t))))   ; BROKEN boss: Obliterate only
    (check (eq (eh-result (grunt oblit :crippled t :boss t)) :killed))
    (check (eq (eh-result (grunt l1 :guarding t)) :blocked))
    (let ((r (grunt h1 :guarding t)))
      (check (and (eq (eh-result r) :guard-break) (~= (eh-stun r) 48))))
    (check (~= (eh-stun (grunt h1 :guarding t :boss t)) 30))
    (check (eq (eh-result (grunt (hit :dmg 30f0 :imp 20f0 :flags '(:unblockable)) :guarding t)) :hit))
    (check (~= (eh-damage (grunt l1 :raven t)) 15))       ; Raven Form: x1.5
    (let ((r (grunt l1 :raven t :ravenable t)))           ; RL string: heavy, impact x2
      (check (and (eh-heavy r) (~= (eh-poise r) 10))))
    (let ((r (grunt l1 :raven t :red-windup t :windup-frac 0.8)))   ; Raven Break
      (check (and (eh-raven-break r) (~= (eh-damage r) 35) (eq (eh-react r) :stagger) (~= (eh-stun r) 120))))
    (check (eq (eh-result (grunt l1 :red-windup t)) :armored))      ; red windup: hyper armor
    (check (~= (eh-damage (grunt l1 :downed t)) 6))))

(check (eq (reaction-for :flinch t nil) :air-flinch))
(check (eq (reaction-for :air-flinch nil nil) :flinch))
(check (eq (reaction-for :launch nil t) :knockdown))
(check (eq (reaction-for :stagger nil nil) :stagger))

;;; a hit on REN
(let ((slash (hit :dmg 14f0 :react :flinch :hs 3)))
  (flet ((ren (hd &rest keys) (apply #'player-hit-outcome hd (append keys '(:tick 1000 :hp 200.0)))))
    (check (eq (ph-result (ren slash :just-dodge t)) :just-dodge))
    (check (eq (ph-result (ren slash :invulnerable t)) :dodged))
    (check (null (ph-result (ren slash :last-hurt 980 :prev-hurt 960))))     ; 3rd hit within 1 s
    (check (eq (ph-result (ren slash :last-hurt 900 :prev-hurt 880)) :hit))
    (check (eq (ph-result (ren slash :guarding t :red t :raven-form t :raven 20.0)) :raven-guard))
    (check (eq (ph-reaction (ren slash :guarding t :red t)) :guard-break))  ; red breaks the guard
    (check (eq (ph-result (ren slash :guarding t :guard-age 5)) :parried))
    (let ((r (ren slash :guarding t)))
      (check (and (eq (ph-result r) :blocked) (~= (ph-guard-meter r) 65) (not (ph-guard-broken r)))))
    (let ((r (ren slash :guarding t :guard-meter 20.0)))
      (check (and (~= (ph-guard-meter r) 0) (ph-guard-broken r))))
    (let ((r (ren slash)))
      (check (and (eq (ph-reaction r) :flinch) (= (ph-hitstop r) 4) (~= (ph-hp r) 186))))
    (check (eq (ph-reaction (ren (hit :dmg 18f0))) :stagger))
    (check (eq (ph-reaction (ren (hit :dmg 30f0))) :knockdown))
    (check (eq (ph-reaction (ren slash :hp 10.0)) :dead))
    (check (~= (ph-damage (ren slash :dmg-mult 2.0)) 28))))

;;; REN's moves
(check (and (~= (dodge-speed 0) 18) (~= (dodge-speed 11) 18) (~= (dodge-speed 15) 12) (~= (dodge-speed 25) 0)))
(check (eq (action-priority t t t t) :dodge))
(check (eq (action-priority nil nil t t) :heavy))
(check (null (action-priority nil nil nil nil)))
(let ((l1 (make-move :name :l1 :s 6 :a 4 :r 14 :light :l2 :heavy :rising-crow :abort 3
                     :hits (vector (hit :from 6 :to 10))))
      (l5 (make-move :name :l5 :s 12 :a 5 :r 28 :jump :on-hit :hits (vector (hit :from 12 :to 17)))))
  (flet ((cancels (mv sf landed) (multiple-value-list (move-cancels mv sf landed nil))))
    (check (equal (cancels l1 2 nil) '(t nil nil nil)))   ; dodge-abort in the first 3 f
    (check (equal (cancels l1 5 nil) '(nil nil nil nil)))
    (check (equal (cancels l1 7 t) '(t nil nil nil)))     ; connected: dodge from the first hit frame
    (check (equal (cancels l1 10 nil) '(t nil t t)))      ; A_end: chains open
    (check (second (cancels l5 13 t)))                    ; jump cancel on hit
    (check (not (second (cancels l5 13 nil))))
    (check (third (multiple-value-list (move-cancels l5 17 nil t))))))   ; heavy -> Obliterate
(check (~= (raven-gauge-after 98.0 5 nil nil) 100))
(check (~= (raven-gauge-after 50.0 5 t :kill) 50))
(check (~= (raven-gauge-after 50.0 10 t :obliterate) 60))
(check (and (= (landed-hit-gain :mirage t) 6) (= (landed-hit-gain :thunderfall t) 0)
            (= (landed-hit-gain :h1 t) 4) (= (landed-hit-gain :l1 nil) 2)))

;;; enemies
(check (eq (token-decision :melee :held :melee) :keep))
(check (null (token-decision :melee :delay 0.1)))
(check (null (token-decision :melee :paused t)))
(check (eq (token-decision :melee :melee 1) :melee))
(check (null (token-decision :melee :melee 2)))
(check (eq (token-decision :melee :melee 2 :punishable t :dist 2.0) :punish))
(check (null (token-decision :melee :melee 2 :punishable t :dist 2.0 :punish-cd 1.0)))
(check (null (token-decision :melee :melee 2 :punishable t :dist 3.0)))
(check (eq (token-decision :ranged) :ranged))
(check (null (token-decision :ranged :ranged 1)))
(check (~= (windup-skip 27 nil 0.8 0.0) 5.4))
(check (~= (windup-skip 48 t 0.8 0.0) 6))                 ; red windups keep 42 f
(check (~= (windup-skip 30 nil 1.0 10.0) 10))
(check (eq (weighted-pick 0.0 :a 1 :b 1) :a))
(check (eq (weighted-pick 0.5 :a 1 :b 1) :b))
(check (eq (weighted-pick 0.1 :a 0 :b 1) :b))
(check (null (weighted-pick 0.5 :a 0)))
(check (eq (enra-attack-choice 2.0 nil 0.0 0.0) :en-triple))
(check (null (enra-attack-choice 5.0 nil 0.0 0.7)))        ; mid range: sometimes just walks in
(check (eq (enra-attack-choice 10.0 nil 0.0 0.99) :en-iai)) ; no leap in phase 1
(check (eq (enra-attack-choice 10.0 t 0.0 0.99) :en-leap))

;;; waves, score, rank
(check (eq (wave-progress '((:rainblade 0 0)) nil t 2) :reinforce))
(check (null (wave-progress '((:rainblade 0 0)) nil t 3)))
(check (eq (wave-progress '((:rainblade 0 0)) t t 0) :clear))
(check (eq (wave-progress nil nil t 0) :clear))
(check (null (wave-progress nil nil nil 0)))               ; still dropping in
(check (= (run-score 20 50 2 300.5 100.0) 4700))
(check (string= (run-rank 4700 0) "A"))
(check (string= (run-rank 6100 0) "S"))
(check (string= (run-rank 6100 1) "A"))
(check (string= (run-rank 2000 0) "C"))

(if (zerop *fails*)
    (format t "rules-test: ALL PASS~%")
    (format t "rules-test: ~d FAILED~%" *fails*))
(ext:quit (if (zerop *fails*) 0 1))
