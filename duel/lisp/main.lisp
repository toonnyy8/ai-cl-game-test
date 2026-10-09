;;;; main.lisp — SOUL DUEL's entry and the whole frame at a glance (design-v1 §12):
;;;;   per frame:  flow (menus, pause) → fixed steps → camera → draw (stage, fighters, hazards, fx)
;;;;               → HUD
;;;;   per step:   devices → vpads (humans) ; then either the running cinematic (CINE-STEP) or the
;;;;               sim: brain → fighter → hazard → hit → gauge → match ; then feedback
;;;; Hitstop freezes the sim (TIME-STEP); slow motion runs the sim on a fraction of the steps
;;;; (SLOW-ACC), so a sim frame is always a whole frame and the same seed replays the same match at
;;;; any frame rate.
(in-package :duel)

;;; ---------------------------------------------------------------- the fixed step
(defvar *slow-acc* 0.0 "Slow motion: sim frames owed (a sim frame runs each time it reaches 1).")
(defun reset-slow-clock ()
  "A new match owes no slow-motion frames (START-MATCH). A perfect Hoho leaves a fraction here; carried
over, it shifted the next match's first slow motion by a step: a seed's result then depended on the
matches run before it in the page."
  (setf *slow-acc* 0.0))

(defun sim-systems ()
  "One sim frame: the systems in order (a Kikon / Soul Break may start a cinematic mid-way; the
rest of the frame then waits for it)."
  (brain-system)                        ; CPU players write their vpads
  (assist-system)                       ; ASSIST presses for a human (assist.lisp)
  (fighter-system)                      ; vpad → commands → state machine → physics
  (unless *cine* (hazard-system))       ; projectiles, pillars, South's grab and hands
  (unless *cine* (hit-system))          ; collect every hit, then apply them together
  (unless *cine* (gauge-system))        ; regen, burns, form timers, Hellfire, EVOLUTION
  (unless *cine* (match-system)))       ; timer, time-up

(defun sim-step ()
  "One fixed 1/60 s step of a running match."
  (incf *match-tick*)
  (cond (*cine* (pilot-read) (cine-step))
        ((not (time-step)) (pilot-read))                  ; hitstop: devices only
        (t (setf *slow-acc* (+ *slow-acc* (slowmo-scale nil)))
           (if (>= *slow-acc* 1.0)
               (progn (decf *slow-acc* 1.0) (pilot-system) (sim-systems))
               (pilot-read))))
  (god-update)
  (probe-update)
  (feedback-system)
  (hash-log))

(defun pilot-read ()
  "A step without a sim frame (hitstop, slow motion, cinematic): the humans' devices are read into
their vpads without advancing the vpad clock, so a press made now is still buffered afterwards."
  (do-entities (e (pl pilot))
    (let ((r (vpad-reader (pilot-vpad pl)))) (when r (funcall r (pilot-vpad pl))))))

(defun advance-sim (rdt)
  "This frame's fixed steps: the engine's RUN-FIXED-STEPS (at most 6 per frame, stopping when the
match leaves the running state), or 120 steps in turbo (debug fast-forward)."
  (if *turbo*
      (dotimes (i 120) (when (sim-running-p) (sim-step)))
      (run-fixed-steps rdt #'sim-step :while #'sim-running-p)))

;;; ---------------------------------------------------------------- the frame
(defun menu-camera ()
  "Title: a slow orbit of the burning plaza; results: the winner from his front-right, on the right
of the screen (the stats take the left third); select: both fighters from the front. Portrait: see below."
  (landscape-lens)
  (case *flow*
    ((:title :mode :settings :controls) (let ((a (* 0.05 (elapsed-time))))
                                (camera-look-at (* 11 (sin a)) 3.2 (* 11 (cos a)) 0 1.4 0)))
    ((:results :clear) (let* ((w (if (eql *winner* 1) *p2* *p1*)) (p (pos-of w)) (yaw (yaw-of w))
                     (fx (fwd-x yaw)) (fz (fwd-z yaw)) (rx (- fz)) (rz fx))   ; his forward, his right
                (if (portrait-p)                         ; portrait: from his front, in the top part (the card below)
                    (progn (camera-look-at (+ (aref p 0) (* 5.2 fx) (* 1.2 rx)) 1.6 (+ (aref p 2) (* 5.2 fz) (* 1.2 rz))
                                           (aref p 0) 1.0 (aref p 2))
                           (portrait-lens 60 0.5))
                    (camera-look-at (+ (aref p 0) (* 3.6 fx) (* 2.4 rx)) 1.7 (+ (aref p 2) (* 3.6 fz) (* 2.4 rz))
                                    (+ (aref p 0) (* 0.9 rx)) 1.15 (+ (aref p 2) (* 0.9 rz))))))
    (t (let* ((p (pos-of *p1*)) (q (pos-of *p2*))
              (mx (* 0.5 (+ (aref p 0) (aref q 0)))) (mz (* 0.5 (+ (aref p 2) (aref q 2)))))
         (if (portrait-p)                                 ; portrait select: farther, the pair above the names
             (progn (camera-look-at (- mx 11.5) 2.4 (+ mz 9.0) mx 1.0 mz) (portrait-lens 60 0.35))   ; a diagonal: the pair overlaps
             (camera-look-at mx 1.6 (+ mz 6.8) mx 1.15 mz))))))

(defun game-frame (rdt)
  "One frame (the engine runs it between BEGIN-FRAME and END-FRAME; RDT = real seconds). The effects run
on FDT: RDT, or 0 while paused (the fx clock, particles, stamps, shake, camera and HUD animation stop)."
  (screen-fx-update (if (or *paused* (cine-held-p)) 0.0 rdt))   ; last frame's impact frames / lines / silence run out
  (onehand-frame)                                           ; the page, the deck, this frame's fingers
  (flow-update rdt)
  (gate-update)
  (perf-mark)                                               ; stats: "sim" = the fixed steps
  (if (sim-running-p)
      (advance-sim rdt)
      (progn (setf *step-acc* 0.0)
             (unless (or *paused* (not (entity-alive-p *p1*)))       ; menus: fighters idle on real time
               (do-sides (e) (anim-advance (model-anim (model e)) (f32 rdt))))))
  (let ((fdt (cond ((fx-frozen-p) 0.0) ((= *cine-time-scale* 1f0) rdt) (t (* rdt *cine-time-scale*)))))   ; (CINE-SLOW)
    (fx-clock-advance (f32 fdt))
    (if (member *flow* '(:intro :battle :finish))
        (duel-camera *p1* *p2* fdt)
        (menu-camera))
    (shake-update (f32 fdt))
    (update-camera)
    (perf-mark)                                             ; "queue" = scene + HUD
    (unless *turbo* (draw-scene fdt))
    (unless (svref *no-draw* 0) (hud-draw))
    (when *frame-probe* (frame-probe-step))))

(defun stats-tail ()
  (if (entity-alive-p *p1*)
      (format nil " | ~a t ~d p1 ~a ~d p2 ~a ~d | heap ~,1f MB" *flow* *match-tick*
              (state-of *p1*) (gauges-reishi (gauges *p1*)) (state-of *p2*) (gauges-reishi (gauges *p2*))
              (/ (ffi:c-inline () () :int "(int)GC_get_heap_size()" :one-liner t) 1048576.0))
      ""))

(defun start-game ()
  "After loading: the dusk plaza, keyboard-friendly pointer, the title screen."
  (setf *pointer-lock* nil
        *key-ease* 1 *shake-hz* 12f0)                       ; pose-to-pose easing, a drawn (stepped) shake
  (stage-env)
  (onehand-init)
  (go-title))

(run-game :title "SOUL DUEL"
          :load (append (list #'bodies-init) (body-load-steps) (list #'stage-init #'brush-init))
          :start #'start-game
          :frame #'game-frame
          :debug #'debug-command
          :stats #'stats-tail)
