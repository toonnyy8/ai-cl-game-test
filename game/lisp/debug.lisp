;;;; debug.lisp — developer tools: the Module._debug_cmd(n) commands (the test scripts drive the
;;;; game with them; list in docs/raven-edge/GAMEPLAY.md), the F3 / T keys, the autoplay bot (runs at the
;;;; nearest enemy and mashes; end-to-end tests) and soak mode (bot runs forever, heap log).
(in-package :raven)

;;; ---------------------------------------------------------------- autoplay bot
(defun bot-target () (nearest-enemy (lambda (e) (not (eq (state-of e) :spawn)))))

(defun bot-threat ()
  "An enemy about to land a red attack within 5 m."
  (let ((hit nil))
    (do-entities (e (f fighter))
      (when (and (not hit) (enemy-p e) (red-windup-p e) (< (distance *player* e) 5.0)
                 (>= (fighter-sf f) (- (mv-s (fighter-move f)) 14)))
        (setf hit e)))
    hit))

(defun bot-input ()
  "Fake inputs: run at the nearest enemy, mash J (K every few swings), E when the gauge allows,
K on an Obliterate prompt, roll away from red windups."
  (let* ((a *player*) (s (pl)) (tg (bot-target)) (tk *ptick*))
    (clear-stick s)
    (when (and tg (alive-p a))
      (let* ((p (pos-of a)) (q (pos-of tg)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
             (d (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (threat (bot-threat)))
        (setf (player-stick-x s) (f32 (/ dx d)) (player-stick-z s) (f32 (/ dz d)) (player-stick-mag s) 1f0 (player-stick-on s) t)
        (cond (threat (setf (player-stick-x s) (f32 (- (/ dx d))) (player-stick-z s) (f32 (- (/ dz d))) (player-press-dodge s) tk))
              ((obliterate-target a) (setf (player-press-heavy s) tk))
              ((and (>= (player-raven s) 60) (not (player-raven-form s))) (setf (player-press-raven s) tk))
              ((< d (+ 2.2 (body-hurt-r (body-of tg))))
               (if (zerop (mod (floor *tick* 7) 5)) (setf (player-press-heavy s) tk) (setf (player-press-light s) tk))))))))

;;; ---------------------------------------------------------------- soak mode
(defvar *soak* nil "Debug 61: loop full bot runs forever and log the GC heap every ~30 s (leak test).")
(defvar *soak-t* 0.0) (defvar *soak-log-t* 0.0) (defvar *soak-runs* 0)

(defun soak-update (rdt)
  (incf *soak-t* rdt)
  (when (>= *soak-t* *soak-log-t*)
    (setf *soak-log-t* (+ *soak-t* 30.0))
    (log-msg "soak: ~,0f s real, run ~d (~a wave ~d), heap ~,1f MB, wasm ~,1f MB, since-gc ~,1f MB"
             *soak-t* *soak-runs* *game* *wave*
             (/ (ffi:c-inline () () :int "(int)GC_get_heap_size()" :one-liner t) 1048576.0)
             (/ (ffi:c-inline () () :int "(int)__builtin_wasm_memory_size(0)" :one-liner t) 16.0)
             (/ (cons-bytes) 1048576.0)))
  (when (or (and (eq *game* :results) (> *gt* 3.0)) (eq *game* :title) (eq *game* :over))
    (incf *soak-runs*)
    (start-run)
    (setf *bot* t *god* t)))

;;; ---------------------------------------------------------------- keys
(defun handle-debug-keys ()
  (when (and *combat-log* (key-pressed :f3)) (setf *debug-overlay* (not *debug-overlay*)))   ; dev sessions only
  (when (and *training* (key-pressed :t))
    (setf *dummies-attack* (not *dummies-attack*))
    (clog "dummies attack ~a" *dummies-attack*)))

;;; ---------------------------------------------------------------- Module._debug_cmd
(defun first-enemy (kind)
  "Nearest free enemy of KIND (debug commands)."
  (nearest-enemy (lambda (e) (and (eq (kind-of e) kind) (not (member (state-of e) '(:spawn :grabbed :dead)))))))

(defun force-attack (kind move)
  (let ((e (first-enemy kind)))
    (if e (progn (setf (motion-grounded (motion e)) t (motion-grav (motion e)) 1f0 (fighter-state (fighter e)) :idle
                       *freeze-actor* e)
                 (enemy-attack e move) (clog "debug: ~a forced ~a" (name-of e) move))
        (clog "debug: no free ~a" kind))))

(defun ensure-run ()
  (when (or *training* (member *game* '(:title :results :over)))
    (start-run))
  (setf *paused* nil *controls* nil))

(defun debug-command (c)
  "Test hook, from JS: Module._debug_cmd(N) (queued by the engine, see app.lisp). 1 raven gauge full,
2 toggle dummies attack, 3 / 4 the dummy REN faces (else nearest) slashes / red-slashes now,
5 player HP full; 10+ = game flow / enemy commands (GAME-DEBUG-COMMAND)."
  (setf *combat-log* t *stats-log* t)   ; using the debug hook = dev session: verbose logs on
  (clog "debug cmd ~d" c)
  (case c
    (1 (setf (player-raven (pl)) 100f0))
    (2 (setf *dummies-attack* (not *dummies-attack*)))
    ((3 4) (let* ((y (yaw-of *player*))
                  (e (or (pick-target *player* (fwd-x y) (fwd-z y) nil
                                      :range 7.0 :pred (lambda (x) (member (state-of x) '(:idle :run))))
                         (nearest-enemy (lambda (x) (not (crippled-p x)))))))
             (when (and e (member (state-of e) '(:idle :run)))
               (face-toward e *player*) (fill (motion-vel (motion e)) 0f0)
               (start-move e (if (= c 3) :rb-slash :rb-red)))))
    (5 (let ((h (health *player*))) (setf (health-hp h) (health-max-hp h))))
    (t (game-debug-command c))))

(defun game-debug-command (c)
  "Commands 10+ of Module._debug_cmd; the list is in docs/raven-edge/GAMEPLAY.md (Debug commands)."
  (case c
    (10 (start-run))
    ((11 12 13 14) (ensure-run) (begin-wave (- c 10)))
    (15 (when (alive-p *boss*) (let ((h (health *boss*))) (setf (health-hp h) (f32 (* 0.5 (health-max-hp h)))))))
    (16 (setf *god* (not *god*)) (clog "god ~a" *god*))
    (17 (do-entities (e fighter)
          (when (enemy-p e)
            (if (eql e *boss*) (progn (setf (health-hp (health e)) 1f0) (boss-break e)) (enemy-kill e *player*)))))
    (18 (setf *bot* (not *bot*) *god* *bot*) (clog "bot ~a" *bot*))
    (19 (when (alive-p *boss*) (boss-break *boss*)))
    (21 (force-attack :rainblade :rb-slash))
    (22 (force-attack :needler :nd-fan))
    (23 (force-attack :needler :nd-blast))
    (24 (force-attack :oxhead :ox-slam))
    (25 (force-attack :oxhead :ox-charge))
    (26 (force-attack :enra :en-crescent))
    (27 (force-attack :enra :en-leap))
    (28 (force-attack :enra :en-wave))
    (29 (force-attack :enra :en-iai))
    (30 (force-attack :enra :en-triple))
    (31 (force-attack :oxhead :ox-swing))
    (32 (let ((e (first-enemy :rainblade)))
          (when e (setf (health-hp (health e)) 10f0) (enemy-cripple e *player*))))
    (33 (let ((e nil))
          (do-entities (x fighter)
            (when (and (not e) (enemy-p x) (eq (state-of x) :idle) (offscreen-p x)) (setf e x)))
          (if e (progn (enemy-attack e (if (eq (kind-of e) :needler) :nd-fan :rb-slash))
                       (clog "debug: ~a off-screen attack forced" (name-of e)))
              (clog "debug: nobody off-screen"))))
    (40 (unless *training* (start-training)))
    (41 (when (alive-p *player*) (setf (health-hp (health *player*)) 0f0) (player-die *player* *player*)))
    (42 (when (eq *game* :over) (retry-wave)))
    (43 (go-title))
    (50 (slowmo 0.05 3.0))
    (51 (log-msg "tick ~d" *tick*)
        (do-entities (e (pr projectile) (tf transform))
          (let ((p (transform-pos tf)) (v (projectile-vel pr)))
            (log-msg "  proj ~d kind ~a at ~,1f ~,1f ~,1f v ~,1f ~,1f ~,1f life ~,2f" e (projectile-kind pr)
                     (aref p 0) (aref p 1) (aref p 2) (aref v 0) (aref v 1) (aref v 2) (projectile-life pr))))
        (do-entities (e (f fighter))
          (let ((p (pos-of e)) (b (brain e)))
            (log-msg "  ~a ~a mode ~a pos ~,1f ~,1f ~,1f dist ~,1f cd ~,2f tok ~a hp ~,1f"
                     (fighter-name f) (fighter-state f) (and b (brain-mode b))
                     (aref p 0) (aref p 1) (aref p 2) (distance e *player*) (if b (brain-cooldown b) 0.0)
                     (and b (brain-token b)) (health-hp (health e))))))
    ((52 53 54) (setf *freeze-on-event* (case c (52 1) (53 10) (t 24))))
    (55 (setf *freeze-on-stick* t))
    (56 (setf *ai-off* (not *ai-off*)) (clog "ai-off ~a" *ai-off*))
    ((57 58 59 60) (let* ((p (pos-of *player*)) (y (yaw-of *player*)))   ; model check: spawn 4.5 m ahead
                     (spawn-enemy (nth (- c 57) '(:rainblade :needler :oxhead :enra))
                                  (+ (aref p 0) (* 4.5 (fwd-x y))) (+ (aref p 2) (* 4.5 (fwd-z y))) :drop 0.0)))
    (61 (setf *soak* (not *soak*) *soak-t* 0.0 *soak-log-t* 0.0 *soak-runs* 0 *combat-log* nil *stats-log* nil))   ; release logging
    (62 (setf *perf-log* (not *perf-log*)))
    (63 (setf *frame-budget-ms* (if (> *frame-budget-ms* 100) 18f0 1000f0)))   ; pretend a fast GPU (auto-scale test)
    (64 (error "debug command 64: forced error (tests the error overlay)"))))
