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
  (fighter-system)                      ; vpad → commands → state machine → physics
  (unless *cine* (hazard-system))       ; projectiles, pillars, skeletons move
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

;;; ---------------------------------------------------------------- drawing
(declaim (type f32vec *tip* *base*))
(defvar *tip* (make-f32 3))
(defvar *base* (make-f32 3))
(defvar *super-rim* (rim-vec #xFFFFFF 3.0) "SP start: the rim-light super flash.")
(defparameter *evolution-rgb* '(1.0 0.85 0.3))

(defun draw-fighter (e rdt)
  "Pose and queue fighter E: body, weapon (or the planted one), blade look, aura, trail."
  (let* ((m (model e)) (f (fighter e)) (kit (fighter-kit f)) (b (model-body m)) (p (pos-of e)) (yaw (yaw-of e))
         (mv (and (eq (fighter-state f) :move) (fighter-move f)))
         (planted (and mv (mv-planted mv) (eq (fighter-phase f) :main)))
         (weapon (if planted nil (model-weapon m))) (x (aref p 0)) (y (aref p 1)) (z (aref p 2)))
    (setf (model-flash m) (f32 (max 0.0 (- (model-flash m) rdt))) (model-super m) (f32 (max 0.0 (- (model-super m) rdt))))
    (pose-fk! (model-joints m) (anim-eval (model-anim m)) x y z yaw (body-scale b) (body-hunch b) (body-props b))
    (draw-body b (model-joints m) x y z yaw :weapon weapon :hide (model-hide m) :tint (model-tint m)
                                          :rim (if (> (model-super m) 0) *super-rim* (model-rim m))
                                          :flash (if (> (model-flash m) 0) 0.45 0.0) :alpha (model-alpha m))
    (when (and planted (model-weapon m))
      (draw-planted-weapon (model-weapon m) (+ x (* 0.7 (fwd-x yaw))) (+ z (* 0.7 (fwd-z yaw))) yaw))
    (when (and weapon (> (model-alpha m) 0.5))
      (body-weapon-tip b weapon (model-joints m) *tip*)
      (body-weapon-base b weapon (model-joints m) *base*)
      (let ((look (kit-blade kit)))
        (case (first look)
          (:fire (vfx-blade-fire (aref *base* 0) (aref *base* 1) (aref *base* 2) (aref *tip* 0) (aref *tip* 1) (aref *tip* 2)
                                 rdt :power (second look)))
          (:embers (vfx-blade-embers (aref *base* 0) (aref *base* 1) (aref *base* 2) (aref *tip* 0) (aref *tip* 1) (aref *tip* 2) rdt))))
      (when (and mv (eq (fighter-phase f) :hold) (not (member :stance (mv-flags mv))))
        (vfx-charge (aref *tip* 0) (aref *tip* 1) (aref *tip* 2)
                    (min 1.0 (/ (fighter-hold f) (float (second (mv-hold mv))))) rdt))
      (let* ((tr (blade-points (blade e))) (n (f->i (trail-count tr))))
        (declare (type f32vec tr))
        (if (and mv (eq (fighter-phase f) :main) (>= (fighter-sf f) (- (mv-s mv) 4)) (< (fighter-sf f) (+ (mv-s mv) (mv-a mv) 3)))
            (trail-push tr (aref *base* 0) (aref *base* 1) (aref *base* 2) (aref *tip* 0) (aref *tip* 1) (aref *tip* 2))
            (trail-decay tr))
        (when (>= n 2) (fx-trail tr n 1.0 0.75 0.5 0.8))))
    ;; auras: the form's, EVOLUTION ready, the Breaker (brightens over the strike startup)
    (let ((age (elapsed-time)))
      (when (kit-aura kit) (vfx-aura x y z (* 1.1 (body-hurt-h b)) (kit-aura kit) age rdt :rgb (and (eq (kit-aura kit) :reiatsu) '(1.0 0.9 0.3))))
      (when (gauges-evolution (gauges e)) (vfx-aura x y z (body-hurt-h b) :evolution age rdt :rgb *evolution-rgb* :k 0.5))
      (when (and mv (eq (mv-kind mv) :breaker) (not (eq (fighter-phase f) :main)))
        (vfx-aura x y z (body-hurt-h b) :breaker age rdt :k (if (eq (fighter-phase f) :dash) 1.0 0.5))
        (vfx-breaker-ring x z age))
      (when (and mv (eq (mv-kind mv) :breaker) (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))
        (vfx-aura x y z (body-hurt-h b) :breaker age rdt :k (+ 1.0 (/ (fighter-sf f) (float (mv-s mv)))))))
    (unless (and mv (eq (mv-kind mv) :breaker)) (stop-hum e))))

(defun draw-scene (rdt)
  (unless (svref *no-draw* 2) (stage-draw rdt))
  (unless *cine* (setf *grade-desat* 0.0))              ; a cinematic's script owns the grade
  (dolist (e (list *p1* *p2*))
    (when (entity-alive-p e)
      (unless *cine* (setf *grade-desat* (max *grade-desat* (kit-grade (kit-of e)))))
      (unless (svref *no-draw* 1) (draw-fighter e rdt))))
  (unless (svref *no-draw* 3) (hazard-draw rdt) (cine-draw))
  (when *hitboxes* (draw-hitboxes))
  (fx-update (if *paused* 0f0 (f32 rdt)))
  (fx-draw-particles)
  (fx-rings-update (f32 rdt))
  (lights-flush))

;;; ---------------------------------------------------------------- the frame
(defun menu-camera ()
  "Title: a slow orbit of the burning plaza; results: the winner from his front-right, on the right
of the screen (the stats take the left third); select: both fighters from the front."
  (case *flow*
    ((:title :mode :controls) (let ((a (* 0.05 (elapsed-time))))
                                (camera-look-at (* 11 (sin a)) 3.2 (* 11 (cos a)) 0 1.4 0)))
    (:results (let* ((w (if (eql *winner* 1) *p2* *p1*)) (p (pos-of w)) (yaw (yaw-of w))
                     (fx (fwd-x yaw)) (fz (fwd-z yaw)) (rx (- fz)) (rz fx))   ; his forward, his right
                (camera-look-at (+ (aref p 0) (* 3.6 fx) (* 2.4 rx)) 1.7 (+ (aref p 2) (* 3.6 fz) (* 2.4 rz))
                                (+ (aref p 0) (* 0.9 rx)) 1.15 (+ (aref p 2) (* 0.9 rz)))))
    (t (let* ((p (pos-of *p1*)) (q (pos-of *p2*))
              (mx (* 0.5 (+ (aref p 0) (aref q 0)))) (mz (* 0.5 (+ (aref p 2) (aref q 2)))))
         (camera-look-at mx 1.6 (+ mz 6.8) mx 1.15 mz)))))

(defun game-frame (rdt)
  "One frame (the engine runs it between BEGIN-FRAME and END-FRAME; RDT = real seconds)."
  (flow-update rdt)
  (gate-update)
  (perf-mark)                                               ; stats: "sim" = the fixed steps
  (if (sim-running-p)
      (advance-sim rdt)
      (progn (setf *step-acc* 0.0)
             (unless (or *paused* (not (entity-alive-p *p1*)))       ; menus: fighters idle on real time
               (dolist (e (list *p1* *p2*)) (anim-advance (model-anim (model e)) (f32 rdt))))))
  (if (member *flow* '(:intro :battle :finish))
      (duel-camera *p1* *p2* rdt)
      (menu-camera))
  (shake-update (f32 rdt))
  (update-camera)
  (perf-mark)                                               ; "queue" = scene + HUD
  (unless *turbo* (draw-scene rdt))
  (unless (svref *no-draw* 0) (hud-draw)))

(defun stats-tail ()
  (if (entity-alive-p *p1*)
      (format nil " | ~a t ~d p1 ~a ~d p2 ~a ~d | heap ~,1f MB" *flow* *match-tick*
              (state-of *p1*) (gauges-reishi (gauges *p1*)) (state-of *p2*) (gauges-reishi (gauges *p2*))
              (/ (ffi:c-inline () () :int "(int)GC_get_heap_size()" :one-liner t) 1048576.0))
      ""))

(defun start-game ()
  "After loading: the dusk plaza, keyboard-friendly pointer, the title screen."
  (setf *pointer-lock* nil)
  (stage-env)
  (go-title))

(run-game :title "SOUL DUEL"
          :load (list #'bodies-init #'stage-init)
          :start #'start-game
          :frame #'game-frame
          :debug #'debug-command
          :stats #'stats-tail)
