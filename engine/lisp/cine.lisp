;;;; cine.lisp — the cinematic director: scripted in-engine cutscenes (a super move, a K.O., a match
;;;; intro) that run inside the fixed step, so they are part of a deterministic replay.
;;;; While *CINE* is set, the game's step runs CINE-STEP instead of its sim systems (the fighters,
;;;; hazards and timers stay frozen); the director advances the cine frame CF and asks the game to
;;;; advance its actors (*CINE-ACTOR-HOOK*). Particles keep moving on real time.
;;;;
;;;; A script is (DEFCINE name (a v :len frames :hold frame) body...): A and V are the two actors
;;;; (e.g. attacker and victim). The body runs in two modes:
;;;;   step mode, once per fixed step (deterministic):  (AT frame forms...)   events, cuts, clips
;;;;   draw mode, once per rendered frame (cosmetic):   (DURING (from to [u]) forms...)   looks, dollies
;;;; with CF bound to the cine frame (and U to 0..1 across a DURING). Camera: (CINE-CAM ex ey ez tx ty
;;;; tz) sets the shot (*CINE-CAM* T, *CINE-EYE* / *CINE-TARGET*): the game's camera uses it while
;;;; set; a shot set in an AT is a cut. *GRADE-DESAT* and *GRADE-SPLIT* set by a script are reset
;;;; when it ends.
;;;; The game plugs in with three hooks (functions, or NIL):
;;;;   *CINE-BEGIN-HOOK* (name a v)   the actors leave their sim states (called by START-CINE)
;;;;   *CINE-ACTOR-HOOK* (actor)      one fixed step of an actor (e.g. advance its animation)
;;;;   *CINE-END-HOOK*   (cine)       restore the look, give the actors back (CINE is NIL when
;;;;                                   none was running); runs before the cine's AFTER function
(in-package :engine)

(defstruct (cine (:constructor %make-cine))
  "A running cinematic: its script NAME, frame CF of LEN, the HOLD frame (debug freeze) or NIL, the
actors A and V, AFTER (a function run when it ends) and SKIP (end on the next fixed step)."
  (name nil) (cf 0 :type fixnum) (len 60 :type fixnum) (hold nil) (a nil) (v nil) (after nil) (skip nil))

(defvar *cine* nil "The running cinematic (a CINE) or NIL.")
(defvar *skip-cines* nil "Debug: every cinematic ends at once (soak / seeded runs).")
(defvar *cine-hold* nil "Debug: a cinematic stops at its :HOLD frame (screenshots).")
(declaim (type f32vec *cine-eye* *cine-target*))
(defvar *cine-eye* (make-f32 3) "The shot's camera eye ...")
(defvar *cine-target* (make-f32 3) "... and target, valid while *CINE-CAM*.")
(defvar *cine-cam* nil "A shot is set: it overrides the game's camera.")
(defvar *cine-begin-hook* nil "Game hook (name a v): see the file header.")
(defvar *cine-actor-hook* nil "Game hook (actor): see the file header.")
(defvar *cine-end-hook* nil "Game hook (cine-or-nil): see the file header.")

(defmacro defcine (name (a v &key (len 60) (hold 30)) &body body)
  "Define cinematic NAME: a function (CF A V STEP-P) plus its length LEN and debug HOLD frame (see
the file header). Inside BODY (the symbols are taken from NAME's package, so a script in any
package writes plain AT / DURING / CF / U / STEP-P):
  CF                               the cine frame
  STEP-P                           T in step mode (fixed step), NIL in draw mode (rendered frame)
  (AT frame forms...)              step mode: run once, on the fixed step where CF = FRAME
  (DURING (from to [u]) forms...)  draw mode: every rendered frame while FROM <= CF < TO, with U
                                   going 0..1 across it"
  (flet ((sym (s) (intern s (symbol-package name))))
    (let ((at (sym "AT")) (during (sym "DURING")) (cf (sym "CF")) (u (sym "U")) (step-p (sym "STEP-P")))
      `(progn
         (defun ,name (,cf ,a ,v ,step-p)
           (declare (fixnum ,cf) (ignorable ,cf ,a ,v ,step-p))
           (macrolet ((,at (frame &body forms) `(when (and ,',step-p (= ,',cf ,frame)) ,@forms))
                      (,during ((from to &optional (u ',u)) &body forms)
                        `(when (and (not ,',step-p) (<= ,from ,',cf) (< ,',cf ,to))
                           (let ((,u (/ (float (- ,',cf ,from)) ,(float (max 1 (- to from))))))
                             (declare (ignorable ,u))
                             ,@forms))))
             ,@body)
           nil)
         (setf (get ',name 'cine-len) ,len (get ',name 'cine-hold-frame) ,hold)
         ',name))))

(defun cine-hold-frame (name) "Script NAME's debug :HOLD frame." (get name 'cine-hold-frame))

;;; ---------------------------------------------------------------- the director
(defun start-cine (name a v &key after)
  "Start cinematic NAME with actors A and V; AFTER (a function of no arguments) runs when it ends.
Hitstop and slow-mo are cancelled, the split grade reset, *CINE-BEGIN-HOOK* called, then frame 0
runs (or, with *SKIP-CINES*, the cinematic ends at once)."
  (time-reset)
  (setf *grade-split* 0.0
        *cine* (%make-cine :name name :len (get name 'cine-len 60)
                           :hold (and *cine-hold* (cine-hold-frame name)) :a a :v v :after after)
        *cine-cam* nil)
  (when *cine-begin-hook* (funcall *cine-begin-hook* name a v))
  (if (and *skip-cines* (not *cine-hold*))
      (end-cine)
      (funcall name 0 a v t)))

(defun end-cine ()
  "Finish the running cinematic: drop the shot and the grade, *CINE-END-HOOK*, then its AFTER."
  (let ((c *cine*))
    (setf *cine* nil *cine-cam* nil *grade-desat* 0.0 *grade-split* 0.0)
    (when *cine-end-hook* (funcall *cine-end-hook* c))
    (when (and c (cine-after c)) (funcall (cine-after c)))))

(defun abort-cine ()
  "Drop the running cinematic without its AFTER (e.g. the player leaves the battle)."
  (when *cine* (setf (cine-after *cine*) nil) (end-cine)))

(defun skip-cine ()
  "Skip the running cinematic (a Start / Esc press): it ends on the next fixed step, so its AFTER
runs inside the sim like everything else that changes the game state."
  (when *cine* (setf (cine-skip *cine*) t)))

(defun cine-step ()
  "One fixed step of the running cinematic (instead of the sim systems): its AT events, then each
actor's *CINE-ACTOR-HOOK*; it ends after its last frame (or at once when skipped)."
  (when (cine-skip *cine*) (end-cine) (return-from cine-step nil))
  (let* ((c *cine*) (cf (cine-cf c)) (held (and (cine-hold c) (>= cf (cine-hold c)))))
    (unless held (setf cf (1+ cf) (cine-cf c) cf))
    (unless held (funcall (cine-name c) cf (cine-a c) (cine-v c) t))
    (when (and (eq c *cine*) (not held))                ; the script may have ended / replaced it
      (when *cine-actor-hook*
        (funcall *cine-actor-hook* (cine-a c)) (funcall *cine-actor-hook* (cine-v c)))
      (when (>= cf (cine-len c)) (end-cine)))))

(defun cine-draw ()
  "Per rendered frame (after the camera is set): the running script's DURING looks."
  (let ((c *cine*))
    (when c (funcall (cine-name c) (cine-cf c) (cine-a c) (cine-v c) nil))))

(defun cine-cam (ex ey ez tx ty tz)
  "Set the shot: camera eye and target (world metres)."
  (v3-set! *cine-eye* (f32 ex) (f32 ey) (f32 ez))
  (v3-set! *cine-target* (f32 tx) (f32 ty) (f32 tz))
  (setf *cine-cam* t))
