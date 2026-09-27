;;;; flow.lisp — the screens (design-v1 §6): TITLE → MODE (VS CPU / VS PLAYER / CPU VS CPU / CONTROLS)
;;;; → SELECT (P1, then P2 / the CPU, then difficulty and, VS CPU, the camera; both models on the plaza)
;;;; → INTRO → BATTLE (pause: RESUME / RESTART / CHARACTER SELECT / TITLE, VS CPU also CAMERA) → FINISH (K.O. / TIME) → RESULTS (REMATCH /
;;;; SELECT / TITLE). Menus read the devices directly (either player's keys / pads); fighters only
;;;; ever read their vpad. MATCH-SYSTEM (the timer, time-up) is the last sim system; the KO comes from
;;;; a Kikon / Soul Break (combat.lisp AFTER-KIKON → MATCH-OVER). Log: "duel -> STATE" per change.
(in-package :duel)

(defparameter *difficulties* '(:easy :normal :hard))

(defvar *flow* :title "Screen: :title :mode :controls :select :intro :battle :finish :results")
(defvar *ft* 0.0 "Real seconds on the current screen.")
(defvar *menu* 0)
(defvar *paused* nil)
(defvar *mode* :vs-cpu "Match mode: :vs-cpu :vs-player :cpu-cpu")
(defvar *picks* (list (first *roster*) (car (last *roster*))) "Characters of P1 and P2 (kit.lisp *ROSTER*).")
(defvar *difficulty* :normal)
(defvar *cam-behind* t "The CAMERA option of VS CPU: BEHIND (P1's shoulder, the default) or SIDE (the pair camera).")
(defvar *select-phase* 0 "SELECT: 0 P1 picks, 1 P2 picks, 2 difficulty.")
(defvar *p1* nil) (defvar *p2* nil)
(defvar *timer* 0 "Match frames left.")
(defun match-frames-left () "Frames left on the match timer (the CPU's last-minute rules)." *timer*)
(defvar *winner* nil "0, 1 or :draw once the match is over.")
(defvar *match-seed* 1 "SIM-RND-SEED of the current match (seeded CPU matches: the debug command's).")
(defvar *konpaku-start* *konpaku-max* "Debug 2101: start the match with fewer Konpaku (smoke runs).")

(defvar *music* nil "Key of the loop that PLAY-MUSIC started last.")
(defun play-music (key &optional (fade 0.3))
  "Switch the music to loop KEY (nothing if it is already the one playing)."
  (unless (and (eq key *music*) (music-playing-p))
    (music-stop fade) (music-play key) (setf *music* key)))

(defun set-flow (st)
  (setf *flow* st *ft* 0.0 *menu* 0)
  (log-msg "duel -> ~a" st))

(defun go-mode ()
  "The MODE screen; ONE-HAND VS CPU is preselected on a touch-first device held in portrait, VS CPU otherwise."
  (set-flow :mode)
  (when (and (one-hand-offered-p) (not (and *coarse* (portrait-p)))) (setf *menu* 2)))

(defun set-cam-behind (on)
  "Set the CAMERA option. Humans steer by the behind view only in VS CPU (fighter.lisp *VIEW-BEHIND*);
VS PLAYER and CPU VS CPU keep the pair camera."
  (setf *cam-behind* on *view-behind* (and on (eq *mode* :vs-cpu)) *cam-cut* t))

(defun camera-label () (if *cam-behind* "CAMERA  BEHIND" "CAMERA  SIDE"))

(defun toggle-cam ()
  "The CAMERA option flips (pause menu, select screen, debug 2109)."
  (set-cam-behind (not *cam-behind*))
  (log-msg "duel camera ~a" (camera-label)))

(defun battle-p () (member *flow* '(:intro :battle :finish)))
(defun sim-running-p () (and (battle-p) (not *paused*)))

;;; ---------------------------------------------------------------- menu input (devices, per frame)
(defun any-pad-pressed (b) (loop for i below 4 thereis (pad-pressed b i)))
(defun menu-up-p () (or (key-pressed :w) (key-pressed :up) (any-pad-pressed :dpad-up)))
(defun menu-down-p () (or (key-pressed :s) (key-pressed :down) (any-pad-pressed :dpad-down)))
(defun menu-left-p () (or (key-pressed :a) (key-pressed :left) (any-pad-pressed :dpad-left)))
(defun menu-right-p () (or (key-pressed :d) (key-pressed :right) (any-pad-pressed :dpad-right)))
(defun confirm-p () (or (key-pressed :return) (key-pressed :j) (key-pressed :kp-1) (key-pressed :kp-enter) (any-pad-pressed :a)))
(defun back-p () (or (key-pressed :escape) (key-pressed :k) (key-pressed :kp-2) (any-pad-pressed :b) *back-press*))
(defun pause-p () (or (key-pressed :escape) (any-pad-pressed :start) *back-press*))   ; + the browser's back (onehand.lisp)

(defun menu-nav (n)
  "Up / down move the cursor over N items; returns the index on confirm, or on a tap on a row (HUD-MENU notes them)."
  (when (menu-up-p) (setf *menu* (mod (1- *menu*) n)) (play-sfx :select))
  (when (menu-down-p) (setf *menu* (mod (1+ *menu*) n)) (play-sfx :select))
  (let ((r (tapped-row n)))
    (cond (r (setf *menu* r) (play-sfx :confirm) r)
          ((confirm-p) (play-sfx :confirm) *menu*))))

;;; ---------------------------------------------------------------- scenes
(defun cycle (item list dir) (nth (mod (+ (position item list) dir) (length list)) list))

(defun spawn-pair (&key cpu1 cpu2)
  "A fresh plaza with the two picked fighters 8 m apart, facing."
  (clear-entities)
  (take-events)
  (fx-clear) (time-reset) (stage-clear-cracks)
  (let* ((c1 (first *picks*)) (c2 (second *picks*)) (h (/ *reset-distance* 2.0)))
    (setf *p1* (spawn-fighter 0 c1 (- h) 0.0 (deg -90) :cpu cpu1 :difficulty *difficulty*)
          *p2* (spawn-fighter 1 c2 h 0.0 (deg 90) :cpu cpu2 :difficulty *difficulty* :mirror (eq c1 c2)))
    (setf (fighter-opp (fighter *p1*)) *p2* (fighter-opp (fighter *p2*)) *p1*)
    (face-each-other *p1* *p2*)))

(defun go-title ()
  (setf *paused* nil)
  (abort-cine)
  (spawn-pair)
  (dolist (e (list *p1* *p2*)) (setf (fighter-state (fighter e)) :intro))
  (play-music :music-title)
  (set-flow :title))

(defun go-select ()
  (setf *paused* nil *select-phase* 0)
  (abort-cine)
  (spawn-pair)
  (dolist (e (list *p1* *p2*)) (setf (fighter-state (fighter e)) :intro))
  (play-music :music-title)
  (set-flow :select))

(defun new-seed ()
  "A fresh match seed from the clock (menu matches vary; debug seeds replay)."
  (setf *match-seed* (mod (floor (now-ms)) 100000)))

(defun start-match ()
  "Spawn the fighters for *MODE* / *PICKS*, seed the sim stream, play the intro."
  (setf *paused* nil *winner* nil *match-tick* 0 *timer* (* 60 *match-seconds*)
        *pending* nil *soul-breaks* nil)          ; nothing of the last match may leak in
  (reset-slow-clock)
  (abort-cine)
  (clear-words)
  (sim-rnd-seed *match-seed*)
  (set-cam-behind *cam-behind*)
  (spawn-pair :cpu1 (eq *mode* :cpu-cpu) :cpu2 (member *mode* '(:vs-cpu :cpu-cpu)))
  (dolist (e (list *p1* *p2*))
    (setf (gauges-konpaku (gauges e)) *konpaku-start*)
    (setf (fighter-state (fighter e)) :intro))
  (play-music :music 0.2)
  (log-msg "duel match seed ~d ~a ~a vs ~a ~a" *match-seed* *mode* (first *picks*) (second *picks*) *difficulty*)
  (set-flow :intro)
  (start-cine 'intro-cine *p1* *p2* :after #'begin-battle))

(defun begin-battle ()
  "The intro ended: FIGHT (P1 on the left of the view; END-CINE already forgot the presses made
during the intro, e.g. the menu's confirm)."
  (dolist (e (list *p1* *p2*)) (refresh-look e) (to-idle e 0))
  (setf *match-tick* 0)
  (view-step *p1* *p2* t)
  (duel-camera *p1* *p2* 0.0 :snap t)
  (set-flow :battle))

(defun match-over (winner)
  "A Kikon / Soul Break took the last Konpaku: FINISH (K.O.), then RESULTS. WINNER: the fighter who
won, NIL = a draw (a lethal trade took both souls' last Konpaku)."
  (let* ((w (cond ((null winner) :draw) ((eql winner *p1*) 0) (t 1)))
         (we (if (eql w 1) *p2* *p1*)) (le (if (eql w 1) *p1* *p2*)))
    (setf *winner* w)
    (set-flow :finish)
    (start-cine 'ko-cine we le :after #'go-results)))

(defun time-up ()
  (let* ((g1 (gauges *p1*)) (g2 (gauges *p2*))
         (w (time-up-winner (gauges-konpaku g1) (gauges-reishi g1) (gauges-reishi-max g1)
                            (gauges-konpaku g2) (gauges-reishi g2) (gauges-reishi-max g2))))
    (setf *winner* w)
    (set-flow :finish)
    (start-cine 'time-cine (if (eql w 1) *p2* *p1*) (if (eql w 1) *p1* *p2*) :after #'go-results)))

(defun go-results ()
  (let* ((g1 (gauges *p1*)) (g2 (gauges *p2*)))
    (set-flow :results)
    (log-msg "duel -> RESULTS winner ~a konpaku ~d-~d ticks ~d secs ~,1f"
             (case *winner* (0 "P1") (1 "P2") (t "DRAW")) (gauges-konpaku g1) (gauges-konpaku g2)
             *match-tick* (/ *match-tick* 60.0)))
  (dolist (e (list *p1* *p2*))
    (let ((f (fighter e)) (won (eql *winner* (fighter-side (fighter e)))))
      (setf (fighter-state f) (if won :win :lose))
      (refresh-look e)
      (play-clip e (if won (or (kit-win (fighter-kit f)) (kit-stance (fighter-kit f))) :sh-lose) :blend 8)))
  (face-each-other *p1* *p2*)
  (music-stop 1.0) (setf *music* nil))

(defun match-system ()
  "The match timer (sim frames) and time-up; the periodic determinism hash."
  (when (eq *flow* :battle)
    (when (<= (decf *timer*) 0) (time-up))))

;;; ---------------------------------------------------------------- per-frame flow
(defun select-update ()
  "SELECT: P1 picks, then P2 / the CPU, then the CPU difficulty (either player's keys, like every menu)."
  (let ((side (min 1 *select-phase*)))
    (flet ((respawn () (spawn-pair) (dolist (e (list *p1* *p2*)) (setf (fighter-state (fighter e)) :intro))))
      (case *select-phase*
        ((0 1)
         (when (or (menu-left-p) (menu-right-p) (member (tap-third) '(-1 1)))   ; a tap: left / right third
           (setf (nth side *picks*) (cycle (nth side *picks*) *roster* (if (or (menu-left-p) (eql (tap-third) -1)) -1 1)))
           (play-sfx :select) (respawn))
         (when (or (confirm-p) (eql (tap-third) 0))           ; ... or the middle: confirm
           (play-sfx :confirm)
           (let ((e (if (zerop side) *p1* *p2*)))
             (play-clip e (or (kit-intro (kit-of e)) (kit-stance (kit-of e))) :blend 4))
           (setf *select-phase* (if (and (= *select-phase* 1) (eq *mode* :vs-player)) 3 (1+ *select-phase*))
                 *menu* 0)))
        (2 (let ((cam (and (eq *mode* :vs-cpu) (not *one-hand*))))   ; row 0 the difficulty, row 1 (VS CPU) the camera
             (when (and cam (or (menu-up-p) (menu-down-p))) (setf *menu* (- 1 *menu*)) (play-sfx :select))
             (when (or (menu-left-p) (menu-right-p) (member (tap-third) '(-1 1)))
               (if (and cam (= *menu* 1))
                   (toggle-cam)
                   (setf *difficulty* (cycle *difficulty* *difficulties* (if (or (menu-left-p) (eql (tap-third) -1)) -1 1))))
               (play-sfx :select)))
           (when (or (confirm-p) (eql (tap-third) 0)) (play-sfx :confirm) (setf *select-phase* 3))))
      (when (>= *select-phase* 3) (new-seed) (start-match))
      (when (back-p)
        (play-sfx :back)
        (if (zerop *select-phase*) (go-mode) (decf *select-phase*))))))

(defparameter *mode-menu* '("VS CPU" "VS PLAYER" "CPU VS CPU" "CONTROLS"))
(defun mode-items ()
  "The MODE menu: ONE-HAND VS CPU and its HAND option first when ONE-HAND is offered (onehand.lisp)."
  (if (one-hand-offered-p)
      (list* "ONE-HAND VS CPU" (if (eq *hand* :left) "HAND  LEFT" "HAND  RIGHT") *mode-menu*)
      *mode-menu*))
(defparameter *pause-menu* '("RESUME" "RESTART" "CHARACTER SELECT" "TITLE"))
(defun pause-items ()
  "The pause menu: VS CPU adds the CAMERA toggle."
  (if (and (eq *mode* :vs-cpu) (not *one-hand*)) (append *pause-menu* (list (camera-label))) *pause-menu*))
(defparameter *results-menu* '("REMATCH" "CHARACTER SELECT" "TITLE"))

(defun flow-update (rdt)
  "Menus, pause and screen timers (once per frame, real time)."
  (unless *paused* (incf *ft* rdt))
  (case *flow*
    (:title (when (and (> *ft* 0.3) (or (confirm-p) (key-pressed :space) (any-pad-pressed :start) (tap-p)))
              (play-sfx :confirm) (go-mode)))
    (:mode (let* ((off (if (one-hand-offered-p) 2 0)) (i (menu-nav (+ 4 off))))
             (cond ((null i))
                   ((and (= off 2) (= i 0))                   ; ONE-HAND VS CPU: the behind camera, the thumb deck
                    (setf *one-hand* t *mode* :vs-cpu) (set-cam-behind t) (go-select))
                   ((and (= off 2) (= i 1)) (set-hand (if (eq *hand* :left) :right :left)))
                   (t (case (- i off)
                        ((0 1 2) (setf *one-hand* nil *mode* (nth (- i off) '(:vs-cpu :vs-player :cpu-cpu))) (go-select))
                        (3 (set-flow :controls))))))
           (when (back-p) (play-sfx :back) (go-title)))
    (:controls (when (or (back-p) (confirm-p) (tap-p)) (play-sfx :back) (go-mode)))
    (:select (select-update))
    ((:intro :finish) (when (and *cine* (or (pause-p) (confirm-p) (tap-p))) (skip-cine)))
    (:battle
     (cond (*paused*
            (if (pause-p)
                (setf *paused* nil)
                (case (menu-nav (length (pause-items)))
                  (0 (setf *paused* nil))
                  (1 (start-match))
                  (2 (go-select))
                  (3 (go-title))
                  (4 (toggle-cam)))))
           ;; battle cinematics (awakening, Kikon, Soul Break) can't be skipped (the user's decision
           ;; 2026-09-28): Start pauses them like play, a tap does nothing
           ((or (pause-p) (focus-lost-p) (touch-pause-p)
                (and *one-hand* (not (portrait-p))))              ; ONE-HAND turned to landscape: ROTATE TO PORTRAIT
            (setf *paused* t *menu* 0) (play-sfx :select))))
    (:results (when (> *ft* 2.5)                         ; a masher doesn't skip the results
                (case (menu-nav 3)
                  (0 (new-seed) (start-match))
                  (1 (go-select))
                  (2 (go-title)))))))
