;;;; main.lisp — RAVEN EDGE's entry and the whole frame at a glance: the fixed 60 Hz simulation
;;;; step (its systems, in order), the per-frame work (input -> game flow -> sim -> camera -> draw
;;;; -> HUD), and the RUN-GAME registration (startup steps, frame, debug hook). The engine side of
;;;; the loop is engine/lisp/app.lisp.
(in-package :raven)

;;; ---------------------------------------------------------------- the fixed-step simulation
(defvar *acc* 0.0 "Real seconds not yet simulated.")
(defvar *sim-dt* 0.0 "Player-scale sim seconds simulated this frame (debris, world).")

(defun sim-step ()
  "One fixed 1/60 s step: the gameplay systems in order. Hitstop freezes the whole step (TIME-STEP);
slow-mo scales each side: KP for REN, KE for everyone else."
  (when (time-step)
    (let ((kp (slowmo-scale nil)) (ke (slowmo-scale t)))
      (setf *ptick* (+ *ptick* (max 1 (round (* 16 kp)))))   ; the input buffer's clock
      (player-system kp)                ; REN: input buffer -> state machine -> physics -> pose
      (enemy-system ke)                 ; each enemy / dummy in turn: AI -> move -> physics -> pose
      (projectile-system ke)            ; kunai, blast kunai, blade waves
      (separation-system)               ; push overlapping bodies apart
      (token-system (* ke +step+))      ; aggression token timers
      (feedback-system)                 ; sounds, blood, shake, hitstop ... for this step's events
      (incf *sim-dt* (* kp +step+)))))

(defun accumulate-and-step (rdt)
  "Fixed-step accumulator: at most 6 steps per frame; a longer backlog is dropped."
  (setf *acc* (+ *acc* rdt) *sim-dt* 0.0)
  (let ((n 0))
    (loop while (and (>= *acc* +step+) (< n 6)) do
      (decf *acc* +step+) (incf n) (sim-step))
    (when (>= *acc* +step+) (setf *acc* 0.0))))

;;; ---------------------------------------------------------------- drawing
(defun fighter-draw-system (rdt)
  "Hit-flash / HP-bar timers (real time), then every living fighter and every blade trail."
  (do-entities (e (m model) (h health) (tr blade-trail))
    (let ((fl (model-flash m)))
      (when (> fl 0) (setf (model-flash m) (f32 (max 0.0 (- fl rdt))))))
    (when (> (health-bar-t h) 0) (setf (health-bar-t h) (f32 (max 0.0 (- (health-bar-t h) rdt)))))
    (when (health-alive h)
      (if (eql e *player*)
          (draw-fighter e :tint (and (< (player-guard-meter (pl)) 35) (member (state-of e) '(:guard :parry)) '(1.0 0.6 0.24)))
          (draw-enemy e)))
    (trail-draw (blade-trail-points tr) (and (eql e *player*) (raven-form-p)))))

(defun draw-scene (rdt)
  (world-update (if (sim-active-p) (* rdt (slowmo-scale nil)) 0.0))
  (world-draw)
  (fighter-draw-system rdt)
  (draw-projectiles)
  (fx-debris-update (f32 *sim-dt*))
  (fx-update (if (or *paused* *controls*) 0f0 (f32 rdt)))
  (fx-rings-update (f32 rdt))
  (fx-draw-particles))

;;; ---------------------------------------------------------------- the frame
(defun game-frame (rdt)
  "One frame (the engine runs it between BEGIN-FRAME and END-FRAME; RDT = real seconds, <= 0.1)."
  (handle-debug-keys)
  (if (input-active-p) (player-read-input) (clear-stick (pl)))
  (when (and *bot* (input-active-p)) (bot-input))
  (game-input)
  (perf-mark)                           ; stats: "sim" = from here to the next mark
  (if (sim-active-p) (accumulate-and-step rdt) (setf *sim-dt* 0.0 *acc* 0.0))
  (when *soak* (soak-update rdt))
  (game-update rdt)
  (feedback-system)                     ; events from game flow / debug commands (kills, BROKEN ...)
  (player-frame-update rdt)
  (game-camera rdt)
  (shake-update rdt)
  (update-camera)
  (perf-mark)                           ; "queue" = the rest (scene + HUD); END-FRAME = "render"
  (draw-scene rdt)
  (hud-draw rdt))

(defun stats-tail ()
  "Game part of the engine's 2 s \"stats:\" line (dev sessions)."
  (format nil " | player ~a hp ~,1f raven ~,1f" (state-of *player*) (health-hp (health *player*)) (player-raven (pl))))

;;; ---------------------------------------------------------------- startup
(defun start-game ()
  "After loading: rain loop, music, dynamic resolution, title screen."
  (setf *rain-voice* (start-loop :rain :gain 0.6))
  (music-play)
  (setf *auto-render-scale* t)
  (go-title))

;; Startup steps (one per browser frame, GC between them): engine init, then these, then the audio
;; device and one step per sound (sounds.lisp), then START-GAME. See engine/lisp/app.lisp.
(run-game :title "RAVEN EDGE"
          :load (list #'world-init-1 #'world-init-2 #'bodies-init)
          :start #'start-game
          :frame #'game-frame
          :debug #'debug-command
          :stats #'stats-tail)
