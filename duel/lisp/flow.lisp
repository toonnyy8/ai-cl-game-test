;;;; flow.lisp — the screens (design-v1 §6): TITLE → MODE (VS CPU / ENDLESS / PRACTICE / VS PLAYER / CPU VS CPU /
;;;; SETTINGS / CONTROLS; ENDLESS: endless.lisp, its STAGE CLEAR is the flow state :clear) → SELECT (P1, then P2 / the CPU, then difficulty and, VS CPU / PRACTICE, the camera; both models on the
;;;; plaza) → INTRO → BATTLE (pause: RESUME / RESTART / CHARACTER SELECT / TITLE, VS CPU also CAMERA; PRACTICE: RESUME /
;;;; RESET POSITION / DUMMY / HP REFILL / GAUGES / P1 HP / P1 KONPAKU / DUMMY HP / DUMMY KONPAKU / CHARACTER SELECT /
;;;; TITLE / CAMERA) → FINISH (K.O. / TIME) → RESULTS
;;;; (REMATCH / SELECT / TITLE). SETTINGS (2026-09-28): ONE-HAND MODE (AUTO / ON / OFF), HAND, TAP SPLIT, SENSITIVITY,
;;;; CAMERA (control.lisp *SETTINGS*, saved by onehand.lisp). VS CPU and PRACTICE are one-handed (the thumb deck,
;;;; onehand.lisp) whenever ONE-HAND MODE is in effect there (ONE-HAND-EFFECTIVE-P); there is no separate one-hand entry.
;;;; PRACTICE: P1 against a dummy (P2's brain: switched off and guarding by DUMMY-GUARD-LEFT, or the CPU), no timer and
;;;; no match end (PRACTICE-STEP refills the dummy to its HP / KONPAKU rows; a K.O. is a reset to both sides' rows). Menus read the devices directly (either
;;;; player's keys / pads); fighters only ever read their vpad. MATCH-SYSTEM (the timer, time-up; PRACTICE-STEP) is
;;;; the last sim system; the KO comes from a Kikon / Soul Break (combat.lisp AFTER-KIKON → MATCH-OVER).
;;;; Log: "duel -> STATE" per change, "duel setting ..." / "duel practice ..." per option change.
(in-package :duel)

(defparameter *difficulties* '(:easy :normal :hard))

(defvar *flow* :title "Screen: :title :mode :settings :controls :select :intro :battle :finish :results :clear (ENDLESS)")
(defvar *ft* 0.0 "Real seconds on the current screen.")
(defvar *menu* 0)
(defvar *paused* nil)
(defvar *mode* :vs-cpu "Match mode: :vs-cpu :endless :practice :vs-player :cpu-cpu")
(defun vs-cpu-p () "A human P1 against the CPU: VS CPU, ENDLESS or PRACTICE (the camera option, the one-hand deck)." (member *mode* '(:vs-cpu :endless :practice)))
(defvar *picks* (list (first *roster*) (second *roster*)) "Characters of P1 and P2 (kit.lisp *ROSTER*): Yamamoto, Kenpachi.")
(defvar *difficulty* :normal)
(defvar *cam-behind* t "The CAMERA setting of VS CPU / PRACTICE: BEHIND (P1's shoulder, the default) or SIDE (the pair camera).")
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

(defun go-mode (&optional (row 0))
  "The MODE screen, the cursor on ROW (VS CPU, row 0, is preselected everywhere; back from SETTINGS / CONTROLS: theirs)."
  (set-flow :mode)
  (setf *menu* row))

(defun set-cam-behind (on)
  "Set the CAMERA option. Humans steer by the behind view only in VS CPU / PRACTICE (fighter.lisp *VIEW-BEHIND*), and
always behind when one-handed (the portrait camera; the setting is kept); VS PLAYER and CPU VS CPU keep the pair camera."
  (setf *cam-behind* on *view-behind* (and (or on *one-hand*) (vs-cpu-p) t) *cam-cut* t))

(defun camera-label () (if *cam-behind* "CAMERA  BEHIND" "CAMERA  SIDE"))

(defun toggle-cam ()
  "The CAMERA option flips (pause menu, select screen, SETTINGS, debug 2109); saved as the CAMERA setting."
  (set-setting :camera (if *cam-behind* 1 0))
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
  (when (eq *mode* :endless) (endless-new-seed))         ; the run's stage-1 opponent stands on the plaza
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
  (spawn-pair :cpu1 (eq *mode* :cpu-cpu) :cpu2 (not (eq *mode* :vs-player)))
  (dolist (e (list *p1* *p2*))
    (setf (gauges-konpaku (gauges e)) *konpaku-start*)
    (setf (fighter-state (fighter e)) :intro))
  (when (eq *mode* :practice) (practice-dummy!) (practice-set! *p1*) (practice-set! *p2*))
  (when (eq *mode* :endless) (endless-apply!))            ; P1's carry, P2's ramp
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
won, NIL = a draw (a lethal trade took both souls' last Konpaku). PRACTICE has no match end: the round resets with
both fighters' Konpaku and Reishi at their practice rows (PRACTICE-SET!)."
  (when (eq *mode* :practice)
    (practice-set! *p1*) (practice-set! *p2*)
    (log-msg "duel practice K.O. -> reset")
    (return-from match-over (reset-round *p1* *p2*)))
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
  (music-stop 1.0) (setf *music* nil)
  (when (eq *mode* :endless) (endless-stage-end)))        ; a win: STAGE CLEAR; else the run's results

(defun match-system ()
  "The match timer (sim frames) and time-up; PRACTICE: no timer, PRACTICE-STEP instead."
  (when (eq *flow* :battle)
    (cond ((eq *mode* :practice) (practice-step))
          ((<= (decf *timer*) 0) (time-up)))))

;;; ---------------------------------------------------------------- PRACTICE (P1 against a dummy)
(defparameter *dummies* '((:stand . "STAND") (:guard-all . "GUARD ALL") (:guard-hit . "GUARD AFTER HIT") (:cpu . "CPU"))
  "The DUMMY option: stands, guards everything, guards after a hit lands (control.lisp DUMMY-GUARD-LEFT), the CPU at
the chosen difficulty.")
(defvar *dummy* :stand "PRACTICE's DUMMY option.")
(defvar *hp-refill* t "PRACTICE's HP REFILL: AUTO (T: the dummy's Reishi is full again once a combo on it ends) / OFF.")
(defvar *gauges-inf* nil "PRACTICE's GAUGES: INFINITE (T: P1's Reishi at its P1 HP row; guard, Reiatsu, flash step, Awakening
full) / NORMAL.")
(defvar *practice-rows* (vector 100 *konpaku-max* 100 *konpaku-max*)
  "PRACTICE's P1 HP (%), P1 KONPAKU, DUMMY HP (%), DUMMY KONPAKU: what RESET POSITION and the refills restore (full by
default: the rows only change what \"full\" means). Indexed by side * 2 (+ 1 for the Konpaku).")

(defun practice-hp (e) "E's Reishi at its practice HP row." (practice-reishi (gauges-reishi-max (gauges e)) (svref *practice-rows* (* 2 (fighter-side (fighter e))))))
(defun practice-set! (e)
  "E's Reishi and Konpaku to its practice rows (a row changed, RESET POSITION, a K.O.)."
  (setf (gauges-reishi (gauges e)) (practice-hp e)
        (gauges-konpaku (gauges e)) (svref *practice-rows* (1+ (* 2 (fighter-side (fighter e)))))))

(defun practice-dummy! ()
  "P2's brain for the DUMMY option: the CPU, or switched off holding nothing (PRACTICE-STEP holds its guard)."
  (let ((b (brain *p2*)))
    (setf (brain-off b) (not (eq *dummy* :cpu)) (brain-press-left b) 0 (brain-act b) nil)))

(defun practice-step ()
  "PRACTICE, each sim frame (MATCH-SYSTEM): the dummy's guard; its Konpaku always full (after a Kikon's reset: no match
end) and, HP REFILL AUTO, its Reishi once it is out of its hit / block reactions; GAUGES INFINITE: P1's gauges full."
  (let* ((f (fighter *p2*)) (g (gauges *p2*)) (b (brain *p2*)))
    (unless (eq *dummy* :cpu)
      (setf (brain-press b) :guard (brain-press-mod b) nil
            (brain-press-left b) (dummy-guard-left *dummy* (fighter-state f) (brain-press-left b))))
    (setf (gauges-konpaku g) (svref *practice-rows* 3))
    (when (and *hp-refill* (not (member (fighter-state f) '(:stun :air :down :wakeup :guard-hit))))
      (setf (gauges-reishi g) (practice-hp *p2*))))
  (when *gauges-inf*
    (let ((g (gauges *p1*)))
      (setf (gauges-reishi g) (practice-hp *p1*)
            (gauges-gg g) *gg-max* (gauges-guardless g) nil (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) *fs-max*)
      (unless (gauges-awakened g) (setf (gauges-awaken g) *awaken-max*)))))

(defun practice-reset ()
  "RESET POSITION: a fresh pair at the start (full resources, first forms), straight into the fight (no intro)."
  (setf *paused* nil *pending* nil *soul-breaks* nil)
  (abort-cine)
  (clear-words)
  (spawn-pair :cpu2 t)
  (practice-dummy!)
  (practice-set! *p1*) (practice-set! *p2*)
  (log-msg "duel practice reset")
  (begin-battle))

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
           (setf *select-phase* (cond ((and (= *select-phase* 1) (eq *mode* :vs-player)) 3)
                                      ((eq *mode* :endless) 2)    ; ENDLESS: no P2 pick (the bag)
                                      (t (1+ *select-phase*)))
                 *menu* 0)))
        (2 (let ((cam (and (vs-cpu-p) (not *one-hand*))))   ; row 0 the difficulty, row 1 (VS CPU) the camera
             (when (and cam (or (menu-up-p) (menu-down-p))) (setf *menu* (- 1 *menu*)) (play-sfx :select))
             (when (or (menu-left-p) (menu-right-p) (member (tap-third) '(-1 1)))
               (if (and cam (= *menu* 1))
                   (toggle-cam)
                   (setf *difficulty* (cycle *difficulty* *difficulties* (if (or (menu-left-p) (eql (tap-third) -1)) -1 1))))
               (play-sfx :select)))
           (when (or (confirm-p) (eql (tap-third) 0)) (play-sfx :confirm) (setf *select-phase* 3))))
      (when (>= *select-phase* 3) (if (eq *mode* :endless) (endless-start) (progn (new-seed) (start-match))))
      (when (back-p)
        (play-sfx :back)
        (cond ((zerop *select-phase*) (go-mode))
              ((eq *mode* :endless) (setf *select-phase* 0))
              (t (decf *select-phase*)))))))

(defparameter *mode-menu* '("VS CPU" "ENDLESS" "PRACTICE" "VS PLAYER" "CPU VS CPU" "SETTINGS" "CONTROLS"))

(defun settings-items ()
  "The SETTINGS rows as shown (label and chosen option), then BACK."
  (append (loop for (key label opts) in *settings* collect (format nil "~a  ~a" label (nth (setting key) opts))) '("BACK")))
(defun settings-note ()
  "The selected SETTINGS row's note (ONE-HAND MODE: whether it is in effect here)."
  (let ((row (nth *menu* *settings*)))
    (cond ((null row) "")
          ((eq (first row) :one-hand) (format nil "~a. HERE: ~:[OFF~;ON~]" (sixth row) (one-hand-effective-p)))
          (t (sixth row)))))
(defun settings-step (i dir)
  "Move SETTINGS row I's option by DIR (it wraps)."
  (let ((row (nth i *settings*))) (set-setting (first row) (mod (+ (setting (first row)) dir) (length (third row))))))

(defun pause-keys ()
  "The pause menu's rows: PRACTICE's options replace RESTART; ENDLESS has RETIRE only (the run's results are one row
away from the rest); VS CPU / ENDLESS / PRACTICE with two hands add the CAMERA toggle."
  (append (case *mode* (:practice '(:resume :reset :dummy :refill :gauges :p1-hp :p1-kon :dm-hp :dm-kon))
                (:endless '(:resume :retire)) (t '(:resume :restart)))
          (unless (eq *mode* :endless) '(:select :title))
          (when (and (vs-cpu-p) (not *one-hand*)) '(:camera))))
(defun pause-label (k)
  (case k
    (:resume "RESUME") (:restart "RESTART") (:retire "RETIRE") (:select "CHARACTER SELECT") (:title "TITLE") (:camera (camera-label))
    (:reset "RESET POSITION") (:dummy (format nil "DUMMY  ~a" (cdr (assoc *dummy* *dummies*))))
    (:refill (if *hp-refill* "HP REFILL  AUTO" "HP REFILL  OFF")) (:gauges (if *gauges-inf* "GAUGES  INFINITE" "GAUGES  NORMAL"))
    ((:p1-hp :p1-kon :dm-hp :dm-kon)
     (let ((i (position k '(:p1-hp :p1-kon :dm-hp :dm-kon))))
       (format nil "~a ~a  ~d~:[~;%~]" (if (< i 2) "P1" "DUMMY") (if (evenp i) "HP" "KONPAKU") (svref *practice-rows* i) (evenp i))))))
(defparameter *practice-option-keys* '(:dummy :refill :gauges :p1-hp :p1-kon :dm-hp :dm-kon) "PRACTICE's option rows.")
(defun pause-items () (mapcar #'pause-label (pause-keys)))
(defun pause-do (k dir)
  "Pause row K chosen (DIR 1), or an option row moved by left / right (DIR -1 / 1)."
  (case k
    (:resume (setf *paused* nil)) (:restart (start-match)) (:retire (endless-retire)) (:select (go-select)) (:title (go-title)) (:camera (toggle-cam))
    (:reset (practice-reset))
    (:dummy (setf *dummy* (cycle *dummy* (mapcar #'car *dummies*) dir)) (practice-dummy!))
    (:refill (setf *hp-refill* (not *hp-refill*))) (:gauges (setf *gauges-inf* (not *gauges-inf*)))
    ((:p1-hp :p1-kon :dm-hp :dm-kon)                      ; the new value in force at once
     (let* ((i (position k '(:p1-hp :p1-kon :dm-hp :dm-kon))) (v (svref *practice-rows* i)))
       (setf (svref *practice-rows* i) (if (evenp i) (cycle v *practice-hp* dir) (konpaku-step v dir *konpaku-max*)))
       (practice-set! (if (< i 2) *p1* *p2*)))))
  (when (member k *practice-option-keys*) (log-msg "duel practice ~a" (pause-label k))))
(defun option-dir () "Left / right this frame: -1 / 1, else NIL (an option row's value)." (cond ((menu-left-p) -1) ((menu-right-p) 1)))
(defparameter *results-menu* '("REMATCH" "CHARACTER SELECT" "TITLE"))

(defun flow-update (rdt)
  "Menus, pause and screen timers (once per frame, real time)."
  (unless *paused* (incf *ft* rdt))
  (case *flow*
    (:title (when (and (> *ft* 0.3) (or (confirm-p) (key-pressed :space) (any-pad-pressed :start) (tap-p)))
              (play-sfx :confirm) (go-mode)))
    (:mode (let ((i (menu-nav (length *mode-menu*))))
             (case i
               ((0 1 2 3 4) (setf *mode* (nth i '(:vs-cpu :endless :practice :vs-player :cpu-cpu))   ; VS CPU / ENDLESS /
                                  *one-hand* (and (< i 3) (one-hand-effective-p)))   ; PRACTICE: one-handed when the
                            (go-select))                                              ; setting is in effect
               (5 (set-flow :settings))
               (6 (set-flow :controls))))
           (when (back-p) (play-sfx :back) (go-title)))
    (:settings (let* ((n (length *settings*)) (i (menu-nav (1+ n))) (d (option-dir)))   ; confirm / a tap: the next option
                 (cond ((eql i n) (go-mode 5))                                           ; BACK
                       (i (settings-step i 1))
                       ((and d (< *menu* n)) (play-sfx :select) (settings-step *menu* d))))
               (when (back-p) (play-sfx :back) (go-mode 5)))
    (:controls (when (or (back-p) (confirm-p) (tap-p)) (play-sfx :back) (go-mode 6)))
    (:select (select-update))
    ((:intro :finish) (when (and *cine* (or (pause-p) (confirm-p) (tap-p))) (skip-cine)))
    (:battle
     (cond (*paused*
            (if (pause-p)
                (setf *paused* nil)
                (let* ((keys (pause-keys)) (i (menu-nav (length keys))) (d (option-dir)) (k (nth (or i *menu*) keys)))
                  (cond (i (pause-do k 1))
                        ((and d (member k (cons :camera *practice-option-keys*))) (play-sfx :select) (pause-do k d))))))
           ;; battle cinematics (awakening, Kikon, Soul Break) can't be skipped (the user's decision
           ;; 2026-09-28): Start pauses them like play, a tap does nothing
           ((or (pause-p) (focus-lost-p) (touch-pause-p)
                (and *one-hand* (not (portrait-p))))              ; ONE-HAND turned to landscape: ROTATE TO PORTRAIT
            (setf *paused* t *menu* 0) (play-sfx :select))))
    (:clear (endless-clear-update))
    (:results (cond ((eq *mode* :endless) (endless-results-update))
                    ((> *ft* 2.5)                        ; a masher doesn't skip the results
                     (case (menu-nav 3)
                       (0 (new-seed) (start-match))
                       (1 (go-select))
                       (2 (go-title))))))))
