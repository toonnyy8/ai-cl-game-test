;;;; game.lisp — game flow (GAME_DESIGN §6, §8): TITLE -> INTRO -> WAVE 1-3 -> BOSS -> VICTORY ->
;;;; RESULTS; death -> GAME OVER -> retry the wave from its checkpoint; pause and menus; the wave
;;;; spawner (drop-ins, reinforcements, max 6 alive); score & rank; which camera runs.
;;;; main.lisp calls GAME-INPUT, GAME-UPDATE and GAME-CAMERA once per frame (real time); the HUD
;;;; reads the state below. Debug commands and the autoplay bot are debug.lisp.
(in-package :raven)

;;; ---------------------------------------------------------------- waves (§6.3)
(defparameter *waves*
  '(("THE RAIN LEGION"
     ((:rainblade -6 -14) (:rainblade 6 -14) (:rainblade -15 -2) (:rainblade 15 -2))
     nil)
    ("NEEDLES IN THE DARK"
     ((:rainblade -4 -15) (:rainblade 4 -15) (:rainblade -15 4) (:needler -14 -14) (:needler 14 -14))
     ((:rainblade 15 5) (:rainblade 0 15)))
    ("THE OX WALKS"
     ((:oxhead 0 -14) (:rainblade -14 -6) (:rainblade 14 -6) (:needler 0 16))
     ((:rainblade -10 14) (:rainblade 10 14) (:needler -15 0))))
  "(name initial reinforcements), spawn points (kind x z).")

;;; ---------------------------------------------------------------- state
(defstruct checkpoint (hp 200.0) (gauge 0.0))
(defstruct banner title sub start)                 ; start: ELAPSED-TIME it appeared
(defstruct (spawn-order (:conc-name order-)) (delay 0.0) kind x z)

(defvar *game* :title "Flow state: :title :intro :fight :clear :boss-intro :victory :results :dying :over :training")
(defvar *gt* 0.0 "Real seconds in the current flow state (frozen while paused).")
(defvar *wave* 0 "1-3 = waves, 4 = boss.")
(defvar *paused* nil)
(defvar *controls* nil "CONTROLS overlay open.")
(defvar *menu* 0)
(defvar *run-time* 0.0)
(defvar *retries* 0)
(defvar *ckpt* (make-checkpoint) "HP and Raven gauge at the start of the wave: a retry restores them.")
(defvar *reinforced* nil)
(defvar *spawn-queue* nil "SPAWN-ORDERs waiting, in order.")
(defvar *boss* nil "ENRA's handle during the boss fight.")
(defvar *boss-dead-t* -1.0)
(defvar *boss-trail* 1400.0 "Boss HP damage trail (HUD).")
(defvar *banner* nil "The wave banner on screen (a BANNER) or NIL.")
(defvar *result-rows* 0 "Result rows revealed so far.")
(defvar *training* nil "Training scene (dummies) instead of the run.")
(defvar *god* nil)
(defvar *bot* nil "Autoplay: runs at the nearest enemy and mashes (debug / e2e tests).")

(defun set-game (st)
  (setf *game* st *gt* 0.0 *menu* 0)
  (clog "game -> ~a (wave ~d, run ~,1f s)" st *wave* *run-time*))

(defun sim-active-p ()
  (and (not *paused*) (not *controls*)
       (member *game* '(:intro :fight :clear :boss-intro :victory :dying :training))))

(defun input-active-p ()
  (and (not *paused*) (not *controls*) (member *game* '(:fight :clear :training))))

(defun show-banner (title sub)
  (setf *banner* (make-banner :title title :sub sub :start (elapsed-time)))
  (play-sfx :wave-start))

(defun living-enemies ()
  (let ((n 0)) (do-entities (e fighter) (when (enemy-p e) (incf n))) n))

(defun nearest-enemy (pred)
  "Nearest live enemy to REN that satisfies PRED (bot, debug commands)."
  (let ((best nil) (bd 1e9))
    (do-entities (e fighter)
      (when (and (enemy-p e) (funcall pred e))
        (let ((d (distance *player* e))) (when (< d bd) (setf best e bd d)))))
    best))

;;; ---------------------------------------------------------------- spawning
(defun queue-spawns (list delay)
  (loop for (kind x z) in list for i from 0
        do (setf *spawn-queue* (append *spawn-queue* (list (make-spawn-order :delay (+ delay (* 0.3 i)) :kind kind :x x :z z))))))

(defun spawn-update (dt)
  (dolist (s *spawn-queue*) (decf (order-delay s) dt))
  (let ((s (first *spawn-queue*)))
    (when (and s (<= (order-delay s) 0) (< (living-enemies) *max-alive*))
      (pop *spawn-queue*)
      (spawn-enemy (order-kind s) (order-x s) (order-z s)))))

(defun clear-enemies ()
  "Every entity but REN goes (enemies, projectiles); token timers, the spawn queue and orbs reset."
  (do-entities (e fighter) (unless (eql e *player*) (destroy-entity e)))
  (clear-projectiles)
  (setf *token-delay* 0.0 *punish-cd* 0.0 *spawn-queue* nil)
  (fx-clear-orbs))

(defun reset-look ()
  "Rain / music back to normal (boss phase 2 changes them)."
  (setf *rain-count* 1500)
  (v3-set! *rain-color* 0.624 0.706 0.816)
  (music-play))                                   ; no-op while playing or without audio

;;; ---------------------------------------------------------------- flow
(defun fresh-arena ()
  "A new REN alone on the roof, no debris, normal rain and music."
  (clear-entities)
  (take-events)                                   ; nothing of the old scene is left to show
  (player-init 0.0 8.0 0.0)
  (clear-enemies)
  (fx-clear-debris)
  (reset-look))

(defun go-title ()
  (setf *training* nil *paused* nil *controls* nil *bot* nil *boss* nil *wave* 0)
  (fresh-arena)
  (music-stop 0.5) (music-play)                   ; restart the loop from the top
  (set-music-volume 0.35)
  (set-game :title))

(defun start-run ()
  (setf *training* nil *retries* 0 *run-time* 0.0 *paused* nil *controls* nil)
  (fresh-arena)
  (set-music-volume 0.55)
  (set-game :intro))

(defun start-training ()
  (setf *training* t *paused* nil *controls* nil)
  (clear-enemies)
  (training-init)
  (set-music-volume 0.55)
  (set-game :training))

(defun save-checkpoint ()
  (setf *ckpt* (make-checkpoint :hp (health-hp (health *player*)) :gauge (player-raven (pl)))))

(defun heal-player (amount)
  (let ((h (health *player*))) (setf (health-hp h) (f32 (min (health-max-hp h) (+ (health-hp h) amount))))))

(defun begin-wave (n)
  "Start wave N (4 = boss): clear the arena, save the checkpoint, banner, queue the drop-ins."
  (setf *wave* n *reinforced* nil *boss* nil *boss-dead-t* -1.0 *cam-fight-dist* (if (<= n 3) 6.5 7.0))
  (clear-enemies)
  (if (<= n 3)
      (destructuring-bind (name initial reinf) (nth (1- n) *waves*)
        (declare (ignore reinf))
        (save-checkpoint)
        (show-banner (format nil "WAVE ~d" n) name)
        (queue-spawns initial 1.0)
        (set-game :fight))
      (start-boss)))

(defun start-boss ()
  "Full heal, gauge >= 40, checkpoint; ENRA drops from y 20 to (0, -10)."
  (heal-player 1000.0)
  (setf (player-raven (pl)) (f32 (max 40.0 (player-raven (pl)))))
  (save-checkpoint)
  (reset-look)
  (setf *boss* (spawn-enemy :enra 0.0 -10.0 :drop 20.0) *boss-trail* (health-max-hp (health *boss*)))
  (set-game :boss-intro))

(defun wave-clear ()
  (slowmo 0.3 0.8)
  (show-banner "WAVE CLEAR" "")
  (heal-player (* 0.25 (health-max-hp (health *player*))))
  (set-game :clear))

(defun revive-player (hp gauge)
  (let* ((e *player*) (s (pl)) (h (health e)) (f (fighter e)) (mo (motion e)))
    (setf (health-alive h) t (health-hp h) (f32 hp) (health-invuln h) 120f0 (motion-grounded mo) t (model-hidden (model e)) 0
          (fighter-move f) nil (transform-yaw (transform e)) 0f0 (motion-kb-left mo) 0f0 (motion-grav mo) 1f0
          (player-raven s) (f32 gauge) (player-raven-form s) nil (player-grab s) nil (player-hp-trail s) (f32 hp)
          (player-combo s) 0)
    (v3-set! (pos-of e) 0.0 0.0 8.0)
    (fill (motion-vel mo) 0f0)
    (setf (cam-yaw *cam*) 0f0)
    (pl-to-idle e)))

(defun retry-wave ()
  "Checkpoint HP (at least 60 %), gauge; the wave (or the boss, from 100 %) restarts."
  (incf *retries*)
  (setf *paused* nil)
  (revive-player (max (checkpoint-hp *ckpt*) (* 0.6 (health-max-hp (health *player*)))) (checkpoint-gauge *ckpt*))
  (reset-look)
  (music-stop 0.3) (music-play)
  (set-music-volume 0.55)
  (clog "RETRY wave ~d (retries ~d)" *wave* *retries*)
  (begin-wave *wave*))

;;; ---------------------------------------------------------------- per-frame update
(defvar *rain-gain* -1.0)
(defun rain-volume-update ()
  "Rain loop §10: title 0.6, gameplay 0.45, paused 0.3; boss phase 2 (heavier rain) x1.3."
  (let ((g (cond ((eq *game* :title) 0.6) ((or *paused* *controls*) 0.3) (t 0.45))))
    (when (> *rain-count* 1500) (setf g (* g 1.3)))
    (unless (= g *rain-gain*)
      (setf *rain-gain* g)
      (set-loop-gain *rain-voice* g))))

(defun game-update (rdt)
  "Flow timers and transitions (once per frame, real time)."
  (rain-volume-update)
  (unless (or *paused* *controls*)
    (incf *gt* rdt)
    (when (member *game* '(:fight :clear :boss-intro :dying))
      (incf *run-time* rdt)))
  (when (and *freeze-at* (>= *tick* *freeze-at*)) (setf *freeze-at* nil) (slowmo 0.05 3.0))
  (when *god*
    (let ((h (health *player*))) (when (health-alive h) (setf (health-hp h) (health-max-hp h)))))
  (let ((h (health *boss*)))
    (when (and h (> (health-hp h) 0))
      (let ((hp (health-hp h)))
        (setf *boss-trail* (if (> *boss-trail* hp) (max hp (- *boss-trail* (* 120 rdt))) hp)))))
  (unless (or *paused* *controls*)
    (case *game*
      (:intro (when (>= *gt* 2.0) (begin-wave 1)))
      (:fight (fight-update rdt))
      (:clear (unless (check-death) (when (>= *gt* 2.0) (begin-wave (1+ *wave*)))))
      (:boss-intro (check-death)
       (when (and (< (- *gt* rdt) 1.8) (>= *gt* 1.8)) (show-banner "ENRA" "THE CRIMSON GENERAL"))
       (when (>= *gt* 3.6) (set-game :fight)))
      (:victory (when (>= *gt* 3.0) (setf *result-rows* 0) (set-game :results)))
      (:dying (when (>= *gt* 2.0) (play-sfx :game-over) (set-music-volume 0.25) (set-game :over)))
      (:results (let ((n (min 7 (floor (- *gt* 0.4) 0.25))))
                  (when (> n *result-rows*)
                    (setf *result-rows* n)
                    (play-sfx :ui-move)
                    (when (= n 7) (shake 0.15 0.3) (play-sfx :hit-heavy)))))
      (:training nil))))

(defun check-death ()
  (unless (alive-p *player*)
    (setf *bot* nil)
    (set-game :dying)
    t))

(defun fight-update (rdt)
  (cond ((check-death))
        ((= *wave* 4) (boss-update))
        (t (spawn-update rdt)
           (let ((reinf (third (nth (1- *wave*) *waves*))))
             (case (wave-progress reinf *reinforced* (null *spawn-queue*) (living-enemies))
               (:reinforce (setf *reinforced* t)
                (queue-spawns reinf 0.5)
                (clog "reinforcements wave ~d" *wave*))
               (:clear (wave-clear)))))))

(defun boss-update ()
  (spawn-update 0.0)
  (let ((b *boss*))
    (cond ((not (entity-alive-p b)))
          ((alive-p b)
           (when (crippled-p b)                           ; BROKEN: adds die, auto-Obliterate after 6 s
             (do-entities (e brain)
               (when (and (enemy-p e) (not (eql e b))) (enemy-kill e *player*)))
             (when (< *boss-dead-t* -0.5) (setf *boss-dead-t* -0.5 *gt* 0.0))
             (when (and (>= *gt* 6.0) (member (state-of *player*) '(:idle :run)) (motion-grounded (motion *player*)))
               (pl-start-obliterate *player* b))))
          ((< *boss-dead-t* 0)                            ; the finisher cut just landed
           (setf *boss-dead-t* 0.0 *gt* 0.0)
           (let ((p (pos-of b)))
             (fx-burst +p-mist+ 90 (aref p 0) 1.6f0 (aref p 2) 0f0 0.5f0 0f0 1f0 6f0 10f0 0.8f0 0.2f0 0.70f0 0.07f0 0.18f0))
           (slowmo 0.2 0.8 t)
           (clog "ENRA DEFEATED"))
          ((>= *gt* 1.0)
           (play-sfx :victory)
           (music-stop 2.0)
           (setf *bot* nil)
           (set-game :victory)))))

;;; ---------------------------------------------------------------- score & rank (§6.4)
(defun final-score ()
  "This run's score (RUN-SCORE, rules.lisp)."
  (let ((s (pl)))
    (run-score (player-kills s) (player-max-combo s) (player-obliterations s) *run-time* (player-damage-taken s))))

(defun final-rank () (run-rank (final-score) *retries*))

(defun fmt-time (secs)
  (multiple-value-bind (m s) (floor secs 60)
    (format nil "~2,'0d:~4,1,,,'0f" m s)))

;;; ---------------------------------------------------------------- menus & pause
(defparameter *title-menu* '("START" "TRAINING" "CONTROLS"))
(defparameter *pause-menu* '("RESUME" "RETRY WAVE" "CONTROLS" "QUIT TO TITLE"))
(defparameter *over-menu* '("RETRY WAVE" "QUIT TO TITLE"))

(defun confirm-pressed () (or (key-pressed :return) (key-pressed :j) (key-pressed :space) (pad-pressed :a)))

(defun menu-nav (n)
  "Up/down move the cursor; returns the selected index on confirm."
  (when (or (key-pressed :up) (key-pressed :w) (pad-pressed :dpad-up))
    (setf *menu* (mod (1- *menu*) n)) (play-sfx :ui-move))
  (when (or (key-pressed :down) (key-pressed :s) (pad-pressed :dpad-down))
    (setf *menu* (mod (1+ *menu*) n)) (play-sfx :ui-move))
  (when (confirm-pressed) (play-sfx :ui-select) *menu*))

(defun pause-game (on)
  (setf *paused* on *menu* 0)
  (play-sfx :ui-select)
  (set-music-volume (if on 0.25 0.55)))

(defvar *was-locked* nil)

(defun auto-pause-p ()
  "Focus loss, or losing the pointer lock mid-fight (Chrome's first Esc only exits the lock)."
  (let ((locked (pointer-locked-p)))
    (prog1 (and (or (focus-lost-p) (and *was-locked* (not locked)))
                (not *paused*) (not *controls*) (member *game* '(:fight :clear :training :boss-intro)))
      (setf *was-locked* locked))))

(defun game-input ()
  "Menus, pause and the controls overlay (per frame, real time)."
  (when (auto-pause-p) (pause-game t) (return-from game-input nil))
  (cond (*controls*
         (when (or (key-pressed :escape) (key-pressed :backspace) (pad-pressed :b) (confirm-pressed))
           (setf *controls* nil) (play-sfx :ui-select)))
        ((eq *game* :title)
         (case (menu-nav 3) (0 (start-run)) (1 (start-training)) (2 (setf *controls* t))))
        ((eq *game* :over)                    ; ignore mashed attack keys for the first 0.6 s
         (when (> *gt* 0.6) (case (menu-nav 2) (0 (retry-wave)) (1 (go-title)))))
        ((eq *game* :results)
         (when (and (> *gt* 2.4) (confirm-pressed)) (play-sfx :ui-select) (go-title)))
        (*paused*
         (if (or (key-pressed :escape) (pad-pressed :start) (pad-pressed :b))
             (pause-game nil)
             (case (menu-nav 4)
               (0 (pause-game nil))
               (1 (if *training* (pause-game nil) (retry-wave)))
               (2 (setf *controls* t))
               (3 (go-title)))))
        ((and (member *game* '(:fight :clear :training :boss-intro))
              (or (key-pressed :escape) (key-pressed :return) (pad-pressed :start)))
         (pause-game t))))

;;; ---------------------------------------------------------------- camera
(defun game-camera (rdt)
  "This frame's camera: a slow orbit on the title screen, else the orbit camera (+ the intro sweep)."
  (case *game*
    (:title (let ((a (* 0.06 (elapsed-time))))
              (camera-look-at (* 17 (sin a)) 6.5 (* 17 (cos a)) 0 1.5 0)))
    (t (camera-update rdt)
       (clamp-camera rdt)
       (when (eq *game* :intro)                           ; sweep from the skyline down to REN
         (let* ((cam *camera*) (p (camera-pos cam)) (tg (camera-target cam))
                (u (min 1.0 (/ *gt* 2.0))) (w (* u u (- 3 (* 2 u)))))
           (camera-look-at (lerp 7.0 (aref p 0) w) (lerp 5.0 (aref p 1) w) (lerp 18.0 (aref p 2) w)
                           (lerp 0.0 (aref tg 0) w) (lerp 14.0 (aref tg 1) w) (lerp -60.0 (aref tg 2) w)))))))
