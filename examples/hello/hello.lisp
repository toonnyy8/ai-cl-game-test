;;;; hello.lisp — the smallest complete game on the engine, meant to be read top to bottom.
;;;; You are a glowing cube; walk into the spinning gems to collect them.
;;;; Keys: W A S D or arrows = move, SPACE = ping.
;;;; Build: ./build.sh examples/hello      Run: node tools/run.mjs dist/hello --secs 10 --shot hello.png
;;;; Walkthrough: docs/TUTORIAL.zh-TW.md, step 2.
(defpackage :hello (:use :cl :engine))   ; our own package, seeing the engine's exported API
(in-package :hello)

;;; ---------------------------------------------------------------- 1. sounds and meshes
;;; A DEFSOUND body returns a sample buffer; the engine synthesizes it during startup.
(defsound :ding (:peak 0.5)
  (let ((b (au-buf 0.5)))
    (au-ping! b 0.0 1320 0.15 1.0)       ; at 0 s: 1320 Hz, 0.15 s decay
    (au-ping! b 0.06 1980 0.2 0.6)))     ; a fifth higher, 60 ms later

(defvar *floor*) (defvar *cube*) (defvar *gem*)

(defun build-meshes ()
  "Startup step: build the three meshes once (meshgen conses a lot; that's fine at load time)."
  (setf *floor* (build-mesh (mb :jitter 0.1 :color '(0.16 0.15 0.22))
                  (mb-plane mb 20 20 :nx 10 :nz 10 :color2 '(0.21 0.19 0.29)))
        *cube* (build-mesh (mb :color '(0.2 0.8 1.0))
                 (mb-bevel-box mb 0.8 0.8 0.8 0.08))
        *gem* (build-mesh (mb :jitter 0.15 :color '(1.0 0.3 0.6))    ; two cones = a diamond
                (with-xform (mb (xform :y 0.25)) (mb-cone mb 0.3 0.5 :segments 6))
                (with-xform (mb (xform :y -0.25 :roll pi)) (mb-cone mb 0.3 0.5 :segments 6)))))

;;; ---------------------------------------------------------------- 2. components
;;; An entity is only a handle. What it is follows from the components it carries:
;;;   the player = pos + player        a gem = pos + gem
(defcomponent pos "Where it stands on the floor (metres)."
  (x 0.0 :type single-float) (z 0.0 :type single-float))
(defcomponent player "Moved by the keyboard." (speed 5.0 :type single-float))
(defcomponent gem "Collectable; spins." (angle 0.0 :type single-float) (value 10 :type fixnum))

(defun spawn-gem ()
  (spawn-entity (make-pos :x (rnd-range -8.0 8.0) :z (rnd-range -8.0 8.0)) (make-gem)))

(defun start ()
  "Runs once, after loading: create the world."
  (spawn-entity (make-pos) (make-player))
  (dotimes (i 8) (spawn-gem)))

;;; ---------------------------------------------------------------- 3. a pure rule
(defun touching-p (ax az bx bz reach)
  "Are two floor points within REACH metres? Arguments in, answer out, nothing else: easy to test."
  (<= (+ (expt (- ax bx) 2) (expt (- az bz) 2)) (* reach reach)))

;;; ---------------------------------------------------------------- 4. systems
;;; A system visits every entity that has the components it names (DO-ENTITIES).
(defun axis (minus plus)
  "-1.0, 0.0 or 1.0 from two lists of keys."
  (- (if (some #'key-down plus) 1.0 0.0) (if (some #'key-down minus) 1.0 0.0)))

(defun move-system (dt)
  (let ((dx (axis '(:a :left) '(:d :right)))
        (dz (axis '(:w :up) '(:s :down))))              ; -Z is "forward", away from the camera
    (do-entities (e pos player)
      (setf (pos-x pos) (clamp (+ (pos-x pos) (* dx (player-speed player) dt)) -9.5 9.5)
            (pos-z pos) (clamp (+ (pos-z pos) (* dz (player-speed player) dt)) -9.5 9.5))))
  (when (key-pressed :space) (play-sfx :ding :pitch 0.5)))

(defun spin-system (dt)
  (do-entities (e gem)
    (incf (gem-angle gem) (* 2.0 dt))))

(defun pickup-system ()
  "The rule decides, an event reports: this system doesn't play sounds or keep score."
  (do-entities (p (me pos) player)
    (do-entities (g (at pos) gem)
      (when (touching-p (pos-x me) (pos-z me) (pos-x at) (pos-z at) 0.8)
        (emit :picked (pos-x at) (pos-z at) (gem-value gem))
        (destroy-entity g)))))

;;; ---------------------------------------------------------------- 5. reacting to events
(defvar *score* 0)

(defun feedback-system ()
  "Everything the player sees and hears because of this frame's events."
  (dolist (ev (take-events))
    (destructuring-bind (kind &rest args) ev
      (case kind
        (:picked (destructuring-bind (x z value) args
                   (incf *score* value)
                   (play-sfx :ding)
                   (fx-ring x 0.05 z 0.2 1.6 0.4 1.0 0.3 0.6 :flat t)
                   (spawn-gem)))))))

;;; ---------------------------------------------------------------- 6. drawing
(defvar *m* (m4) "Scratch matrix: DRAW-MESH copies it, so one is enough.")

(defun draw-system (dt)
  (do-entities (e pos player)                           ; camera first: fx use it
    (camera-look-at (pos-x pos) 7.0 (+ (pos-z pos) 8.0) (pos-x pos) 0.0 (pos-z pos))
    (draw-mesh *cube* (m4-euler! *m* (pos-x pos) 0.4 (pos-z pos) 0.0 0.0 0.0))
    (add-point-light (pos-x pos) 2.0 (pos-z pos) 0.2 0.8 1.0 7.0 1.5)
    (fx-decal (pos-x pos) 0.0 (pos-z pos) 0.7 0.0 0.0 0.0 0.5))   ; blob shadow
  (draw-mesh *floor* (m4-identity! *m*) :specular 0.2)       ; a dull floor, not a wet one
  (do-entities (e pos gem)
    (let ((y (+ 0.7 (* 0.15 (sin (* 2 (gem-angle gem)))))))       ; bob up and down
      (draw-mesh *gem* (m4-euler! *m* (pos-x pos) y (pos-z pos) (gem-angle gem) 0.0 0.0) :emissive 1.2))
    (fx-decal (pos-x pos) 0.0 (pos-z pos) 0.35 0.0 0.0 0.0 0.4))
  (fx-rings-update dt))                                 ; grow and draw the pickup rings

(defun hud ()
  (let ((s (ui-scale)))
    (ui-text (format nil "SCORE ~d" *score*) (* 12 s) (* 12 s) :scale (* 2 s) :shadow t)
    (ui-text "WASD / ARROWS MOVE   SPACE PING" (* 12 s) (* 34 s) :scale s :color '(0.7 0.8 1 1))))

;;; ---------------------------------------------------------------- 7. the frame
(defun frame (dt)
  "Every frame, between the engine's BEGIN-FRAME and END-FRAME. The order is the design."
  (move-system dt)
  (spin-system dt)
  (pickup-system)
  (feedback-system)
  (draw-system dt)
  (hud))

(run-game :title "HELLO"
          :load (list #'build-meshes)   ; startup steps, one per browser frame
          :start #'start
          :frame #'frame)
