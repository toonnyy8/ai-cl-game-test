;;;; app.lisp — the application driver. A game registers itself once, at load time:
;;;;
;;;;   (run-game :title "MY GAME"
;;;;             :load (list #'build-level #'build-characters) ; startup steps, one per browser frame
;;;;             :start #'start-game       ; once, when loading (and sound synthesis) is done
;;;;             :frame #'game-frame       ; every frame, between BEGIN-FRAME and END-FRAME; arg = real dt
;;;;             :debug #'debug-command    ; optional: Module._debug_cmd(n) from the page / test scripts
;;;;             :stats #'stats-tail)      ; optional: returns a string appended to the "stats:" log line
;;;;
;;;; engine/c/main.c then calls %INIT-STEP once per browser frame until startup is done, and %FRAME
;;;; every frame after that. Startup steps: ENGINE-INIT (window, GPU, UI) → the :LOAD functions →
;;;; open the audio device → one step per DEFSOUND → :START. main.c collects garbage between steps,
;;;; so meshgen / synthesis temporaries never pile up, and the page's loading bar advances.
;;;; A frame: PLATFORM-POLL → BEGIN-FRAME → queued debug commands → :FRAME → END-FRAME.
;;;; Errors are caught here and shown on the page; the main loop then stops. (Keep HANDLER-CASE rare:
;;;; each one is a setjmp, see docs/ARCHITECTURE.md. The others guard audio startup in audio.lisp.)
(in-package :engine)

(defstruct app
  (title "game") (load nil) (start nil) (frame nil) (debug nil) (stats nil))
(defvar *app* (make-app) "The registered game (RUN-GAME).")

(defun run-game (&key (title "game") load start frame debug stats)
  "Register the game: see the file header. Call it once, at load time."
  (setf *app* (make-app :title title :load load :start start :frame frame :debug debug :stats stats)))

;;; ---------------------------------------------------------------- small utilities
(defun cons-bytes () "Bytes allocated since the last GC (main.c collects between frames)."
  (ffi:c-inline () () :int "(int)GC_get_bytes_since_gc()" :one-liner t))
(defun now-ms () "High-resolution milliseconds since page load."
  (ffi:c-inline () () :double "emscripten_get_now()" :one-liner t))

(defun show-fatal (where e)
  "Report an unhandled condition on the page (the main loop stops afterwards)."
  (let ((msg (remove-if-not (lambda (c) (< 31 (char-code c) 127))
                            (handler-case (format nil "~a: ~a" where e) (error () (format nil "~a: (unprintable error)" where))))))
    (ffi:c-inline ((coerce msg 'base-string)) (:cstring) :void "engine_fatal(#0)" :one-liner t)))

;;; ---------------------------------------------------------------- startup (stepwise)
(defvar *init-step* 0)
(defvar *au-ready* nil "Audio device opened: synthesize the sound bank.")

(defun %init-step ()
  "Called by main.c once per browser frame during startup. Returns 1 while steps remain, 0 when
done, 2 on failure (the error is on the page)."
  (handler-case (if (run-init-step) 1 0)
    (error (e) (show-fatal "startup" e) 2)))

(defun run-init-step ()
  "Run startup step *INIT-STEP*; NIL after the last one."
  (let* ((i *init-step*) (app *app*) (load (app-load app)) (nload (length load))
         (last (+ 2 nload (length *au-defs*))))
    (setf *init-step* (1+ i))
    (ffi:c-inline ((floor (* 100 i) (1+ last))) (:int) :void "engine_loading(#0)" :one-liner t)
    (cond ((= i 0) (engine-init :title (app-title app)))
          ((<= i nload) (funcall (nth (1- i) load)))
          ((= i (1+ nload)) (setf *au-ready* (audio-init-begin)))
          ((< i last) (when *au-ready* (audio-init-sound (- i nload 2))))
          (t (when *au-ready* (audio-init-end))
             (when (app-start app) (funcall (app-start app)))
             (ffi:c-inline () () :void "engine_loading(100)" :one-liner t)
             (return-from run-init-step nil)))
    t))

;;; ---------------------------------------------------------------- frame + stats
(declaim (type f32vec *stats* *perf*) (type (simple-array double-float (2)) *perf-marks*) (type fixnum *perf-n*))
(defvar *stats* (make-f32 4) "cons accumulator, frames, timer, last cons/frame")
(defvar *perf* (make-f32 3) "ms accumulated: sim (between the two PERF-MARKs), queue (rest of :FRAME), render (END-FRAME)")
(defvar *perf-marks* (make-array 2 :element-type 'double-float :initial-element 0d0))
(defvar *perf-n* 0)
(defvar *stats-log* nil "T: log a \"stats:\" line every 2 s (fps, consing, draws, frame time split).")

(defun perf-mark ()
  "Call twice inside the :FRAME function, before and after the simulation: the stats line splits
the frame time there into sim / queue / render."
  (let ((n *perf-n*))
    (when (< n 2) (setf (aref *perf-marks* n) (now-ms) *perf-n* (1+ n)))))

(defun cons-per-frame () "Average bytes consed per frame over the last stats window." (aref *stats* 3))

(defun log-stats (rdt c0)
  (let* ((st *stats*) (dc (- (cons-bytes) c0)))
    (incf (aref st 0) (float (max dc 0) 1f0)) (incf (aref st 1) 1f0) (incf (aref st 2) (f32 rdt))
    (when (>= (aref st 2) 2f0)
      (setf (aref st 3) (/ (aref st 0) (aref st 1)))
      (let ((n (max 1.0 (aref st 1))) (tail (app-stats *app*)))
        (log-msg "stats: fps ~,1f cons/frame ~d B draws ~d tris ~d particles ~d | ms/frame sim ~,2f queue ~,2f render ~,2f~a"
                 (fps) (round (aref st 3)) *draw-count* *tri-count* *plive*
                 (/ (aref *perf* 0) n) (/ (aref *perf* 1) n) (/ (aref *perf* 2) n)
                 (if tail (funcall tail) "")))
      (fill *perf* 0f0)
      (setf (aref st 0) 0f0 (aref st 1) 0f0 (aref st 2) 0f0))))

(defun run-frame ()
  "One frame; NIL when the app should quit."
  (unless (platform-poll) (return-from run-frame nil))
  (let* ((app *app*) (c0 (cons-bytes)) (rdt (f32 (min 0.1 (max 0.0 (raw-dt))))))
    (begin-frame)
    (loop for c = (ffi:c-inline () () :int "debug_take_cmd()" :one-liner t)
          while (plusp c) do (when (app-debug app) (funcall (app-debug app) c)))
    (setf *perf-n* 0)
    (let ((t0 (now-ms)))
      (funcall (app-frame app) rdt)
      (let ((m *perf-marks*) (t2 (now-ms)))
        (case *perf-n* (0 (setf (aref m 0) t0 (aref m 1) t0)) (1 (setf (aref m 1) (aref m 0))))
        (end-frame)
        (setf (aref *perf* 0) (+ (aref *perf* 0) (f32 (- (aref m 1) (aref m 0))))
              (aref *perf* 1) (+ (aref *perf* 1) (f32 (- t2 (aref m 1))))
              (aref *perf* 2) (+ (aref *perf* 2) (f32 (- (now-ms) t2))))))
    (when *stats-log* (log-stats rdt c0))
    t))

(defun %frame ()
  "Called by main.c every browser frame after startup. NIL stops the main loop."
  (handler-case (run-frame)
    (error (e) (show-fatal "game-frame" e) nil)))
