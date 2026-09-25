;;;; input.lisp — the virtual controller ("vpad"): the only input a game's fighter code needs to read.
;;;; Devices, a CPU brain and test scripts all write it the same way, once per fixed step, so a
;;;; replay or a CPU press is indistinguishable from a key press (and a seeded match replays).
;;;;   make:   (make-vpad :actions #(:mod :attack :jump) :modifier :mod :buffer 10 :reader fn)
;;;;   step:   (vpad-begin-step! vp)          advance the vpad clock, run the device READER (if any)
;;;;   write:  (vpad-set! vp :attack t)       button state this step (going down stamps a press)
;;;;           (vpad-stick! vp x y)           stick, x right / y up, clamped to |s| <= 1
;;;;   read:   (vpad-down vp :guard)  (vpad-held vp :charge)  (vpad-pressed vp :attack)
;;;;           (vpad-command vp commands allowed)   buttons + modifier -> one command keyword
;;;;           (vpad-command-pressed-p vp button mod)   is one command-table entry buffered?
;;;;           (vpad-consume! vp :attack)     a buffered press was used
;;;; A press stays buffered for BUFFER steps until consumed (input buffering). The optional MODIFIER
;;;; button (e.g. a shoulder button) marks presses made while it is held, or in the same step, as
;;;; "modified", so one button can mean two commands.
;;;; Device reading is data + one function: a binding plist per player and VPAD-READ!, which asks a
;;;; DOWN-P function the game supplies (e.g. over KEY-DOWN / PAD-DOWN): nothing here touches a
;;;; device, so the file is plain CL and host-tested (tests/input-test.lisp). No consing per step.
(in-package :engine)

(defconstant +no-press+ -1000000 "Press stamp of 'no unconsumed press'.")

(defun %fixnums (n init) (make-array n :element-type 'fixnum :initial-element init))

(defstruct (vpad (:constructor %make-vpad))
  "One player's virtual controller. Per button (index = position in ACTIONS): DOWNS 1/0, SINCE =
tick the hold began, PRESS = tick of the last unconsumed press, MODDED 1 = that press was made with
the MODIFIER held. READER: NIL or a function of the vpad, called by VPAD-BEGIN-STEP! (a device)."
  (actions #() :type simple-vector)
  (mod-index -1 :type fixnum)            ; index of the modifier button, -1 = none
  (buffer 10 :type fixnum)               ; steps a press stays buffered
  (tick 0 :type fixnum)
  (downs (%fixnums 0 0) :type (simple-array fixnum (*)))
  (since (%fixnums 0 0) :type (simple-array fixnum (*)))
  (press (%fixnums 0 0) :type (simple-array fixnum (*)))
  (modded (%fixnums 0 0) :type (simple-array fixnum (*)))
  (sx 0f0 :type single-float) (sy 0f0 :type single-float)
  (reader nil))

(defun make-vpad (&key actions modifier (buffer 10) reader)
  "A vpad with buttons ACTIONS (a list or vector of keywords). MODIFIER: one of them (or NIL) whose
hold marks other presses as modified. BUFFER: steps a press stays buffered. READER: see above."
  (let* ((acts (coerce actions 'simple-vector)) (n (length acts)))
    (%make-vpad :actions acts :buffer buffer :reader reader
                :mod-index (if modifier (or (position modifier acts) (error "modifier ~s is not an action" modifier)) -1)
                :downs (%fixnums n 0) :since (%fixnums n 0) :press (%fixnums n +no-press+) :modded (%fixnums n 0))))

(defun vpad-index (vp action)
  "Button index of ACTION in VP (an error for an unknown action)."
  (or (position action (vpad-actions vp)) (error "unknown vpad action ~s" action)))

(defun vpad-begin-step! (vp)
  "Start a fixed step: advance the tick, then let the device reader (if any) write the state."
  (incf (vpad-tick vp))
  (let ((r (vpad-reader vp))) (when r (funcall r vp)))
  vp)

(defun vpad-set! (vp action down)
  "Button ACTION is DOWN (generalized boolean) this step. Going down stamps a press (buffered for
the vpad's BUFFER steps) and records whether the modifier is down (or goes down in the same step)."
  (let ((i (vpad-index vp action)) (d (vpad-downs vp)) (m (vpad-mod-index vp)))
    (cond ((and down (zerop (aref d i)))
           (setf (aref d i) 1
                 (aref (vpad-since vp) i) (vpad-tick vp)
                 (aref (vpad-press vp) i) (vpad-tick vp)
                 (aref (vpad-modded vp) i) (if (>= m 0) (aref d m) 0))
           (when (= i m)                                   ; the modifier now: presses of this step count too
             (dotimes (j (length d))
               (when (= (aref (vpad-press vp) j) (vpad-tick vp)) (setf (aref (vpad-modded vp) j) 1)))))
          ((and (not down) (= 1 (aref d i)))
           (setf (aref d i) 0)))
    down))

(defun vpad-stick! (vp x y)
  "Set the stick (X right, Y up; any reals, e.g. 0 or 0.5), clamped to unit length."
  (declare (optimize (speed 3) (safety 0)))            ; safety 0: no boxed temporaries
  (let* ((x (float x 1f0)) (y (float y 1f0)) (m2 (+ (* x x) (* y y))))
    (declare (single-float x y m2))
    (when (> m2 1f0)
      (let ((m (sqrt m2))) (declare (single-float m)) (setf x (/ x m) y (/ y m))))
    (setf (vpad-sx vp) x (vpad-sy vp) y)
    vp))

(defun vpad-clear! (vp)
  "Release everything and forget buffered presses (a reset, a cinematic, a menu)."
  (fill (vpad-downs vp) 0) (fill (vpad-press vp) +no-press+) (fill (vpad-modded vp) 0)
  (setf (vpad-sx vp) 0f0 (vpad-sy vp) 0f0)
  vp)

(defun vpad-flush! (vp)
  "Forget buffered presses but keep what is held (e.g. the end of a cinematic: a button mashed
during it must not fire, a guard still held stays up)."
  (fill (vpad-press vp) +no-press+)
  vp)

(defun vpad-down (vp action) "Is ACTION held now?" (= 1 (aref (vpad-downs vp) (vpad-index vp action))))

(defun vpad-held (vp action)
  "Steps ACTION has been held (1 on the step it went down), 0 if up."
  (let ((i (vpad-index vp action)))
    (if (= 1 (aref (vpad-downs vp) i)) (1+ (- (vpad-tick vp) (aref (vpad-since vp) i))) 0)))

(defun vpad-pressed (vp action &optional within)
  "Was ACTION pressed within the last WITHIN steps (default the vpad's BUFFER; this step
included) and not consumed?"
  (< (- (vpad-tick vp) (aref (vpad-press vp) (vpad-index vp action))) (or within (vpad-buffer vp))))

(defun vpad-modded-p (vp action)
  "Was ACTION's buffered press made with the modifier held?"
  (= 1 (aref (vpad-modded vp) (vpad-index vp action))))

(defun vpad-consume! (vp action)
  "Use up ACTION's buffered press."
  (setf (aref (vpad-press vp) (vpad-index vp action)) +no-press+)
  vp)

;;; ---------------------------------------------------------------- commands
;;; A command table is a list of (command button mod), HIGHEST PRIORITY FIRST. MOD = T needs the
;;; press modified, NIL unmodified, :ANY either way. A game whose top command may be refused (not
;;; enough gauge ...) walks its table with VPAD-COMMAND-PRESSED-P, trying each entry in turn, so a
;;; refused press doesn't block the ones below it.
(defun vpad-command-pressed-p (vp button mod)
  "Is the command-table entry (BUTTON MOD) buffered: BUTTON pressed, with the modifier as MOD asks?"
  (and (vpad-pressed vp button)
       (or (eq mod :any) (eq mod (vpad-modded-p vp button)))))

(defun vpad-command (vp commands &optional allowed)
  "The highest-priority buffered command of the table COMMANDS among ALLOWED (a list; NIL = all).
Values: command button — pass BUTTON to VPAD-CONSUME! once the command is taken."
  (loop for (cmd button mod) in commands
        when (and (or (null allowed) (member cmd allowed)) (vpad-command-pressed-p vp button mod))
          do (return (values cmd button))))

;;; ---------------------------------------------------------------- devices (bindings as data)
;;; A binding plist maps an action (and :up :down :left :right for the stick) to a list of inputs;
;;; an input is (device name ...), all names down together (a chord), e.g. (:key :j) or
;;; (:pad :ls :rs). The DOWN-P function the game passes decides what a device name means (which
;;; pad slot belongs to the player, KEY-DOWN for :key ...).
(defun inputs-down-p (inputs down-p)
  "Is any input of INPUTS down? (An input is (device name ...), every name down.)"
  (loop for (device . names) in inputs
        thereis (loop for n in names always (funcall down-p device n))))

(defun vpad-read! (vp bindings down-p &optional (ax 0f0) (ay 0f0))
  "Device reader: set every button of VP from BINDINGS, asking DOWN-P (device name) -> boolean,
and the stick from the direction inputs plus the analog stick (AX AY). Wrap it in the vpad's
READER, e.g. (lambda (vp) (vpad-read! vp *p1-bindings* #'my-down-p (pad-lx) (pad-ly)))."
  (declare (single-float ax ay))
  (loop for a across (vpad-actions vp)
        do (vpad-set! vp a (inputs-down-p (getf bindings a) down-p)))
  (flet ((dir (plus minus)
           (- (if (inputs-down-p (getf bindings plus) down-p) 1f0 0f0)
              (if (inputs-down-p (getf bindings minus) down-p) 1f0 0f0))))
    (vpad-stick! vp (+ ax (dir :right :left)) (+ ay (dir :up :down)))))
