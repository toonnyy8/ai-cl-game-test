;;;; duel-control-test.lisp — checks SOUL DUEL's controls (duel/lisp/control.lisp over the engine's
;;;; vpad, engine/lisp/input.lisp) on the host: buffer window, consume, command priority, modifier
;;;; combos, opponent-relative directions, and that a device read through the binding tables equals
;;;; direct injection (VPAD-SET!). The vpad itself is also checked by tests/input-test.lisp.
;;;;   $ECL_HOST --norc --load tests/duel-control-test.lisp
(dolist (f '("package" "math" "hitvol" "input" "touch"))
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
;; CONTROLS (the user, 2026-10-01): a rebind swaps (one keyboard over both players, a pad per player), changes the
;; live bindings the readers use, saves as codes (0 = default) and resets; the prompts follow
(let ((pair (vector (copy-tree *p1-default-bindings*) (copy-tree *p2-default-bindings*))))
  (flet ((n (side a dev) (binding-name (svref pair side) a dev)))
    (check (equal (key-prompt pair 0 :key :chain) "SHIFT+J  CHAIN"))
    (check (equal (key-prompt pair 0 :pad :burst) "LT+X  BURST"))
    (check (equal (key-prompt pair 1 :key :kikon) "HOLD KP6  KIKON"))
    (check (rebind pair 0 :quick :key :k))                          ; J -> K: FLASH takes J
    (check (and (eq :k (n 0 :quick :key)) (eq :j (n 0 :flash :key)) (equal (key-prompt pair 0 :key :chain) "SHIFT+K  CHAIN")))
    (check (not (rebind pair 0 :quick :key :k)))                    ; the same key: nothing
    (check (rebind pair 0 :guard :key :up))                         ; P2's UP: P2 takes U
    (check (and (eq :up (n 0 :guard :key)) (eq :u (n 1 :up :key))))
    (check (rebind pair 1 :quick :pad :a))                          ; P2's pad: STEP takes X, P1's pad untouched
    (check (and (eq :a (n 1 :quick :pad)) (eq :x (n 1 :step :pad)) (eq :x (n 0 :quick :pad)) (eq :a (n 0 :step :pad))))
    (check (and (= 0 (bind-code 0 :sig :key pair)) (= (1+ (position :k *bind-keys*)) (bind-code 0 :quick :key pair))
                (eq :k (bind-from-code (bind-code 0 :quick :key pair) :key)) (null (bind-from-code 0 :key))
                (null (bind-from-code 999 :pad))))
    (check (member '(:pad :ls :rs) (getf (svref pair 0) :awaken) :test #'equal))   ; chords untouched
    (reset-bindings pair)
    (check (and (equal (svref pair 0) *p1-default-bindings*) (equal (svref pair 1) *p2-default-bindings*)))
    (check (every (lambda (a) (and (member (n 0 a :key) *bind-keys*) (member (n 1 a :key) *bind-keys*)
                                   (member (n 0 a :pad) *bind-pads*) (member (n 1 a :pad) *bind-pads*)))
                  *bind-actions*))
    (check (and (= (length *bind-actions*) (length *bind-row-names*)) (string= "SHIFT" (bind-label :lshift))
                (string= "KP1" (bind-label :kp-1)) (string= "D-UP" (bind-label :dpad-up)) (string= "-" (bind-label nil))))))
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

;;; ---------------------------------------------------------------- SETTINGS and the merged VS CPU (2026-09-28)
;; the defaults are the old behaviour: AUTO, RIGHT, the recogniser's tap-split 0.5 and flick-min 28, BEHIND
(check (equal (map 'list (lambda (row) (nth (fourth row) (third row))) *settings*) '("AUTO" "RIGHT" "50%" "3" "BEHIND" "ON" "OFF" "OFF" "OFF" "OFF")))   ; PERFECT HINT off by default (2026-10-01)
(check (and (= (setting-value :tap-split) 0.5) (= (setting-value :flick) 28) (equal (setting-value :camera) "BEHIND")))
;; every row: VALUES (when given) match the options one to one; 3-5 SENSITIVITY steps
(check (loop for row in *settings* always (or (null (fifth row)) (= (length (fifth row)) (length (third row))))))
(check (<= 3 (length (third (assoc :flick *settings*))) 5))
;; the page value: option index + 1; 0 (never saved, blocked storage) or out of range -> the default
(check (and (= (setting-from-page :hand 2) 1) (= (setting-from-page :hand 1) 0) (= (setting-from-page :hand 0) 0)
            (= (setting-from-page :hand 3) 0) (= (setting-from-page :hand -1) 0) (= (setting-from-page :tap-split 0) 2)
            (= (setting-from-page :tap-split 5) 4) (= (setting-from-page :tap-split 6) 2)))
;; ONE-HAND MODE: AUTO = a touch-first device held in portrait (the old preselection); ON only where it is offered
;; (coarse or portrait: a landscape desktop never); OFF never. VS CPU and PRACTICE take the deck exactly then.
(check (equal (loop for choice below 3
                    collect (loop for (coarse portrait) in '((t t) (t nil) (nil t) (nil nil))
                                  collect (one-hand-on-p choice coarse portrait)))
              '((t nil nil nil) (t t t nil) (nil nil nil nil))))
(let ((old (copy-seq *setting-ix*)))                     ; SETTING-VALUE follows the chosen index
  (setf (svref *setting-ix* (setting-pos :flick)) 4 (svref *setting-ix* (setting-pos :hand)) 1)
  (check (and (= (setting-value :flick) 18) (= (setting :hand) 1) (equal (setting-value :hand) "LEFT")))
  (setf *setting-ix* old))

;;; ---------------------------------------------------------------- ONE-HAND: what an up-flick is (UP-FLICK-HOHO-P)
;; a Hoho while attacking (no dash there, the user 2026-09-30), or when it would be perfect (2026-10-01); a Step from
;; neutral; and a Step in a stance whose Step is a follow-up (:step-branch: Lille's SOGEKI-GAMAE, Ichigo's TSUKIMACHI; the
;; bug of 2026-10-06, docs/duel/DUEL_LILLE.md decision 24: the flick read as a Hoho the stance never took)
(check (and (up-flick-hoho-p :move nil nil) (not (up-flick-hoho-p :move t nil)) (not (up-flick-hoho-p :idle nil nil))
            (up-flick-hoho-p :idle nil t) (up-flick-hoho-p :guard nil t) (not (up-flick-hoho-p :stun nil nil))
            (eq t (up-flick-hoho-p :move nil nil))))
;; the whole path on the recogniser and the vpad: in the stance (UP-HOHO from the rule, a rested thumb, REST-UP-OK off in a
;; move) an up-flick pulses the dash flick, straight ahead, not a Hoho; read as onehand.lisp TOUCH-BUTTON does (:step on a
;; flick, :mod on a Hoho), the command is the unmodified :step the stance reads, never :hoho
(flet ((up-flick (state branch)
         (let ((tr (touch-layout! (make-touch) 1 '(16 600 276 794) nil)) (vp (new-vpad)))
           (setf (engine::touch-up-hoho tr) (up-flick-hoho-p state branch nil) (engine::touch-rest-up-ok tr) nil)
           (flet ((feed (now &rest events)
                    (let ((q (engine::touch-q tr)))
                      (loop for e in events for i from 0
                            do (loop for v in e for j from 0 do (setf (aref q (+ (* 5 i) j)) (float v 1f0))))
                      (setf (engine::touch-now tr) (float now 1f0))
                      (touch-feed! tr (length events)))))
             (feed 16 '(0 0 100 700 0))
             (feed 150)                                                         ; rested
             (feed 166 '(1 0 100 688 155) '(1 0 100 668 165)))
           (touch-take! tr)
           (let ((hoho (touch-pulse-p tr engine::+tp-hoho+)) (flick (touch-pulse-p tr engine::+tp-flick+)))
             (vpad-begin-step! vp)
             (vpad-set! vp :step (or flick hoho))
             (vpad-set! vp :mod hoho)
             (values (vpad-command vp *commands*) flick (touch-sy tr) (touch-sx tr) vp)))))
  (multiple-value-bind (cmd flick sy sx vp) (up-flick :move t)                  ; the stance: the Step, forward
    (check (and (eq cmd :step) flick (> sy 0.9) (zerop sx) (vpad-command-pressed-p vp :step nil)
                (not (vpad-command-pressed-p vp :step t)))))
  (check (eq :hoho (up-flick :move nil))))                                      ; any other move: the Hoho (unchanged)

;;; ---------------------------------------------------------------- the PRACTICE dummy's guard
(check (every (lambda (st) (= 999 (dummy-guard-left :guard-all st 0))) '(:idle :stun :guard-hit)))
(check (loop for d in '(:stand :cpu) always (loop for st in '(:idle :stun :guard-hit) always (zerop (dummy-guard-left d st 50)))))
;; GUARD AFTER HIT: nothing before a hit; a hit (or a blocked one) holds it *DUMMY-GUARD-HOLD* frames; free, it counts down
(check (zerop (dummy-guard-left :guard-hit :idle 0)))
(check (every (lambda (st) (= *dummy-guard-hold* (dummy-guard-left :guard-hit st 3))) '(:stun :air :down :wakeup :guard-hit)))
(check (let ((left *dummy-guard-hold*) (n 0))
         (loop while (plusp left) do (setf left (dummy-guard-left :guard-hit :guard left)) (incf n))
         (= n *dummy-guard-hold*)))

;;; ---------------------------------------------------------------- PRACTICE's HP / KONPAKU rows
(check (and (= (practice-reishi 1300 100) 1300) (= (practice-reishi 1300 50) 650) (= (practice-reishi 1300 10) 130)
            (plusp (practice-reishi 1 10))))
(check (< (practice-reishi 1300 25) (* 1300 *red-threshold*) (practice-reishi 1300 50)))   ; 25 %: red (the Kikon is live)
(check (equal (first *practice-hp*) 100))                                                  ; the default row is full
(check (and (= (konpaku-step 9 1 9) 1) (= (konpaku-step 1 -1 9) 9) (= (konpaku-step 4 1 9) 5) (= (konpaku-step 5 -1 9) 4)))

;;; ---------------------------------------------------------------- the HUD's Konpaku at stake
;; the attacker's form's Kikon worth (2 base, 3 awakened, 4 Kenpachi's Bankai), capped at what is left and at a Kikon's max
(check (equal (mapcar (lambda (c) (konpaku-at-stake 9 c)) '(2 3 4 5)) (list 2 3 4 (min 5 *kikon-max-event*))))
(check (and (= (konpaku-at-stake 3 4) 3) (= (konpaku-at-stake 1 2) 1) (= (konpaku-at-stake 0 3) 0)))

(format t "duel-control-test: ~d checks, ~a~%" *checks*
        (if (zerop *fails*) "ALL PASS" (format nil "~d FAILED" *fails*)))
(ext:quit (if (zerop *fails*) 0 1))
