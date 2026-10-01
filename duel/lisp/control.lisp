;;;; control.lisp — SOUL DUEL's controls (design-v1 §2) on the engine's virtual controller (the
;;;; vpad, engine/lisp/input.lisp): the nine buttons, the command table and both players' device
;;;; bindings, all data. Fighter code reads only vpads; devices, the CPU brain and test scripts
;;;; write them the same way, once per fixed step (VPAD-SET!, VPAD-STICK!), so a replay or a CPU
;;;; press is indistinguishable from a key.
;;;;   (new-vpad &key reader)                a vpad with these buttons (:MOD = the Reiatsu modifier)
;;;;   (vpad-command vp *commands* allowed)  buttons + modifier -> one command keyword
;;;;   (vpad-command-pressed-p vp button mod)   is one *COMMANDS* entry's button buffered?
;;;; Also the SETTINGS rows (*SETTINGS*, ONE-HAND-ON-P) and the PRACTICE dummy's guard rule (DUMMY-GUARD-LEFT).
;;;; Plain CL, host-tested (tests/duel-control-test.lisp).
(in-package :duel)

(defparameter *vpad-actions*
  #(:mod :quick :flash :sig :guard :breaker :kikon :step :awaken)
  "Every vpad button. :MOD is the modifier: a button pressed while :MOD is down, or in the same
step, is modified.")

(defun new-vpad (&key reader)
  "A SOUL DUEL vpad: *VPAD-ACTIONS*, :MOD as the modifier, presses buffered *INPUT-BUFFER* steps."
  (make-vpad :actions *vpad-actions* :modifier :mod :buffer *input-buffer* :reader reader))

;;; ---------------------------------------------------------------- commands
(defparameter *commands*
  '((:kikon   :kikon   :any)
    (:awaken  :awaken  :any)
    (:hoho    :step    t)
    (:burst   :quick   t)
    (:step    :step    nil)
    (:breaker :breaker :any)
    (:sp2     :sig     t)
    (:sp1     :flash   t)
    (:sig     :sig     nil)
    (:f       :flash   nil)
    (:q       :quick   nil))
  "Command table, HIGHEST PRIORITY FIRST: (command button mod), MOD = T needs the press modified
(pressed with :MOD down), NIL needs it unmodified, :ANY ignores the modifier. Order: the decisive
and rare (Kikon, Awaken) first, then escapes (Hoho, Burst, Step, like RAVEN's dodge > attacks),
the Breaker, the modified buttons before the plain ones (a modified Flash is SP1, never F), and
heavier before lighter (Signature > Flash > Quick), so mashing J+K gives the Flash. Fighter code
walks it with VPAD-COMMAND-PRESSED-P (fighter.lisp COMMAND!), so a refused command doesn't hide
the ones below it.")

;;; ---------------------------------------------------------------- devices (bindings as data)
;;; Binding plists for VPAD-READ! (engine): action -> list of inputs, an input (device name ...) =
;;; all names down together (a chord). :key names are engine key keywords, :pad names pad buttons;
;;; the DOWN-P function fighter.lisp passes knows which pad slot belongs to the player.
(defparameter *p1-default-bindings*
  '(:up ((:key :w) (:pad :dpad-up)) :down ((:key :s) (:pad :dpad-down))
    :left ((:key :a) (:pad :dpad-left)) :right ((:key :d) (:pad :dpad-right))
    :quick ((:key :j) (:pad :x) (:touch :quick)) :flash ((:key :k) (:pad :y) (:touch :flash))
    :sig ((:key :l) (:pad :b) (:touch :sig)) :guard ((:key :u) (:pad :lb) (:touch :guard))
    :breaker ((:key :i) (:pad :rb) (:touch :breaker)) :kikon ((:key :o) (:pad :rt) (:touch :kikon))
    :step ((:key :space) (:pad :a) (:touch :step)) :mod ((:key :lshift) (:pad :lt) (:touch :mod))
    :awaken ((:key :p) (:pad :back) (:pad :ls :rs) (:touch :awaken)))
  "Player 1: left keyboard + pad 0 (design-v1 §2) + the ONE-HAND thumb deck ((:touch name): onehand.lisp
TOUCH-BUTTON; its drag stick is added like pad 0's). Menus read the devices directly (flow.lisp). The defaults: the
live *P1-BINDINGS* is a copy CONTROLS rebinds.")

(defparameter *p2-default-bindings*
  '(:up ((:key :up) (:pad :dpad-up)) :down ((:key :down) (:pad :dpad-down))
    :left ((:key :left) (:pad :dpad-left)) :right ((:key :right) (:pad :dpad-right))
    :quick ((:key :kp-1) (:pad :x)) :flash ((:key :kp-2) (:pad :y)) :sig ((:key :kp-3) (:pad :b))
    :guard ((:key :kp-4) (:pad :lb)) :breaker ((:key :kp-5) (:pad :rb)) :kikon ((:key :kp-6) (:pad :rt))
    :step ((:key :kp-0) (:pad :a)) :mod ((:key :kp-enter) (:pad :lt))
    :awaken ((:key :kp-plus) (:pad :back) (:pad :ls :rs)))
  "Player 2: arrows + numpad + pad 1 (design-v1 §2). The defaults of *P2-BINDINGS*.")

;;; ---------------------------------------------------------------- CONTROLS: rebinding (the user, 2026-10-01)
;;; Keyboard and pad only (the touch deck is the gestures'). Each player's binding of an action on a device is its first
;;; one-name input of that device ((:key :j), (:pad :x)); chords ((:pad :ls :rs)) and touch inputs stay as they are.
(defvar *p1-bindings* (copy-tree *p1-default-bindings*) "Player 1's live bindings (CONTROLS changes them in place).")
(defvar *p2-bindings* (copy-tree *p2-default-bindings*) "Player 2's live bindings.")
(defvar *bind-pair* (vector *p1-bindings* *p2-bindings*) "Both players' live bindings (REBIND's PAIR).")
(defparameter *bind-actions* '(:up :down :left :right :quick :flash :sig :guard :breaker :kikon :step :mod :awaken)
  "The CONTROLS rows, in order (the page saves them by this index).")
(defparameter *bind-row-names*
  '("MOVE UP" "MOVE DOWN" "MOVE LEFT" "MOVE RIGHT" "QUICK  J" "FLASH  K" "SIGNATURE  L" "GUARD  U" "BREAKER  I"
    "KIKON RUSH  O" "STEP  SPACE" "REIATSU  SHIFT" "AWAKEN  P")
  "Each *BIND-ACTIONS* row's label (the button's name in the manual after it).")
(defparameter *bind-keys*
  (append (loop for c across "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" collect (intern (string c) :keyword))
          '(:space :return :tab :backspace :minus :equals :lbracket :rbracket :semicolon :quote :grave :comma :period :slash
            :backslash :capslock :insert :home :pageup :delete :end :pagedown :up :down :left :right
            :kp-0 :kp-1 :kp-2 :kp-3 :kp-4 :kp-5 :kp-6 :kp-7 :kp-8 :kp-9 :kp-divide :kp-multiply :kp-minus :kp-plus
            :kp-enter :kp-period :lshift :rshift :lctrl :rctrl :lalt :ralt :f1 :f2 :f3 :f4 :f5 :f6 :f7 :f8 :f9 :f10 :f11 :f12))
  "Keys CONTROLS may bind (engine *SCANCODES* names, no alias; Escape is the pause and the cancel).")
(defparameter *bind-pads* '(:a :b :x :y :lb :rb :lt :rt :ls :rs :back :dpad-up :dpad-down :dpad-left :dpad-right)
  "Pad buttons CONTROLS may bind (Start is the pause and the cancel).")
(defparameter *bind-labels*
  '(:lshift "SHIFT" :rshift "RSHIFT" :lctrl "CTRL" :rctrl "RCTRL" :lalt "ALT" :ralt "RALT" :return "ENTER"
    :kp-enter "KP ENTER" :kp-plus "KP +" :kp-minus "KP -" :kp-multiply "KP *" :kp-divide "KP /" :kp-period "KP ."
    :lbracket "[" :rbracket "]" :semicolon ";" :quote "'" :grave "`" :comma "," :period "." :slash "/" :backslash "\\"
    :minus "-" :equals "=" :dpad-up "D-UP" :dpad-down "D-DOWN" :dpad-left "D-LEFT" :dpad-right "D-RIGHT")
  "Screen names that differ from the keyword's own.")

(defun bind-label (name)
  "How a bound key / pad button NAME reads on screen: SHIFT, KP1, D-UP, J ..., \"-\" for none."
  (cond ((null name) "-")
        ((getf *bind-labels* name))
        ((and (> (length (symbol-name name)) 3) (string= "KP-" (symbol-name name) :end2 3)) (remove #\- (symbol-name name)))
        (t (symbol-name name))))

(defun binding-input (bindings action device)
  "ACTION's first one-name input of DEVICE in BINDINGS (a list (device name)), or NIL."
  (find-if (lambda (in) (and (eq (first in) device) (null (cddr in)))) (getf bindings action)))
(defun binding-name (bindings action device) "ACTION's bound name on DEVICE (:key / :pad), or NIL." (second (binding-input bindings action device)))

(defvar *prompt-cache* (make-array 4 :initial-element nil)
  "KEY-PROMPT's texts per side x device (:key, :pad), rebuilt after a rebind (NIL).")

(defun rebind (pair side action device name)
  "SIDE's (0 / 1, PAIR: the two players' bindings) ACTION on DEVICE becomes NAME. An action already on NAME takes ACTION's
old one (a swap, never two actions on one key): on the keyboard over both players' (one keyboard), on a pad over this
player's (his own pad). Changes PAIR's plists in place; T when something changed."
  (let* ((b (svref pair side)) (in (binding-input b action device)) (old (second in)))
    (when (and in (not (eql old name)))
      (dolist (s (if (eq device :key) '(0 1) (list side)))
        (dolist (a *bind-actions*)
          (let ((other (binding-input (svref pair s) a device)))
            (when (and other (eql (second other) name) (not (and (= s side) (eq a action))))
              (setf (second other) old)))))
      (setf (second in) name)
      (fill *prompt-cache* nil)
      t)))

(defun reset-bindings (pair)
  "Every CONTROLS binding of PAIR back to the defaults."
  (loop for b across pair for d in (list *p1-default-bindings* *p2-default-bindings*)
        do (dolist (a *bind-actions*)
             (dolist (dev '(:key :pad))
               (let ((in (binding-input b a dev))) (when in (setf (second in) (binding-name d a dev)))))))
  (fill *prompt-cache* nil))

(defun bind-code (side action device pair)
  "What the page saves for SIDE's ACTION on DEVICE: 0 = the default, else 1 + the name's place in *BIND-KEYS* /
*BIND-PADS*."
  (let ((n (binding-name (svref pair side) action device))
        (d (binding-name (if (zerop side) *p1-default-bindings* *p2-default-bindings*) action device)))
    (if (eql n d) 0 (1+ (or (position n (if (eq device :key) *bind-keys* *bind-pads*)) -1)))))
(defun bind-from-code (code device)
  "The name a saved CODE stands for on DEVICE (NIL: the default, or a code out of range)."
  (and (plusp code) (nth (1- code) (if (eq device :key) *bind-keys* *bind-pads*))))

(defun key-prompt (pair side device kind)
  "The HUD's prompt KIND (:chain :burst :kikon) for SIDE pressing on DEVICE (:key / :pad), from his bindings (cached)."
  (let ((i (+ (* 2 side) (if (eq device :pad) 1 0))))
    (getf (or (svref *prompt-cache* i)
              (setf (svref *prompt-cache* i)
                    (flet ((n (a) (bind-label (binding-name (svref pair side) a device))))
                      (list :chain (format nil "~a+~a  CHAIN" (n :mod) (n :quick))
                            :burst (format nil "~a+~a  BURST" (n :mod) (n :quick))
                            :kikon (format nil "HOLD ~a  KIKON" (n :kikon))))))
          kind)))

;;; ---------------------------------------------------------------- SETTINGS (the 2026-09-28 SETTINGS screen)
;;; The rows as data: flow.lisp shows and changes them, onehand.lisp puts them into effect and saves each one
;;; through the page (duel/web/pwa.js: localStorage "soulduel.<name>", the page value = option index + 1, 0 = never
;;; saved or storage blocked -> the default). The page names the rows in this order.
(defparameter *settings*
  '((:one-hand "ONE-HAND" ("AUTO" "ON" "OFF") 0 nil "AUTO: ON FOR A TOUCH PHONE HELD UPRIGHT")
    (:hand "HAND" ("RIGHT" "LEFT") 0 nil "THE THUMB DECK'S SIDE")
    (:tap-split "TAP SPLIT" ("40%" "45%" "50%" "55%" "60%") 2 (0.4 0.45 0.5 0.55 0.6) "THE PAD'S TOP PART THAT TAPS K")
    (:flick "SENSITIVITY" ("1" "2" "3" "4" "5") 2 (40 34 28 23 18) "HIGHER: A SHORTER FLICK")
    (:camera "CAMERA" ("BEHIND" "SIDE") 0 nil "VS CPU AND PRACTICE, TWO HANDS")
    (:learn "LEARNING CPU" ("ON" "OFF") 0 nil "VS CPU AND ENDLESS: THE CPU LEARNS YOUR HABITS")
    (:hint "PERFECT HINT" ("OFF" "ON") 0 nil "HOHO! OVER YOU WHEN A HOHO NOW IS PERFECT"))   ; the user 2026-10-01
  "SETTINGS rows: (key label option-labels default-index values note). VALUES (else the labels) are what the options
mean: TAP SPLIT the recogniser's tap-split, SENSITIVITY its flick-min in CSS px (28 = the design's §3.8 default).")

(defvar *setting-ix* (coerce (mapcar #'fourth *settings*) 'simple-vector) "Each row's chosen option index.")

(defun setting-pos (key) (position key *settings* :key #'first))
(defun setting (key) "KEY's chosen option index." (svref *setting-ix* (setting-pos key)))
(defun setting-value (key) "What KEY's chosen option means (its VALUES entry, else its label)."
  (let ((row (nth (setting-pos key) *settings*))) (nth (setting key) (or (fifth row) (third row)))))
(defun setting-from-page (key v)
  "The option index a page value V stands for: V - 1 when it names an option of KEY, else KEY's default."
  (let ((row (nth (setting-pos key) *settings*)))
    (if (< 0 v (1+ (length (third row)))) (1- v) (fourth row))))

(defun one-hand-on-p (choice coarse portrait)
  "Is a VS CPU / PRACTICE match one-handed, for ONE-HAND MODE option CHOICE (0 AUTO, 1 ON, 2 OFF), a touch-first
device (COARSE) and a PORTRAIT window? Only where one-hand is offered (coarse or portrait: a landscape desktop never);
AUTO: a touch-first device held in portrait (the old ONE-HAND VS CPU preselection)."
  (and (or coarse portrait) (case choice (0 (and coarse portrait)) (1 t)) t))

;;; ---------------------------------------------------------------- the PRACTICE dummy (flow.lisp PRACTICE-STEP)
(defparameter *dummy-guard-hold* 60 "PRACTICE, GUARD AFTER HIT: frames the dummy keeps its guard once it is free again.")

(defun dummy-guard-left (dummy state left)
  "Frames the PRACTICE dummy goes on holding guard, for its DUMMY option, its fighter STATE and LEFT (frames still
held). :GUARD-ALL always; :GUARD-HIT from a hit landing on it (a hit state) or a blocked one, until *DUMMY-GUARD-HOLD*
frames after that (a string's first hit lands, the rest is blocked unless it combos); :STAND / :CPU never (the CPU
guards by itself)."
  (case dummy
    (:guard-all 999)
    (:guard-hit (if (member state '(:stun :air :down :wakeup :guard-hit)) *dummy-guard-hold* (max 0 (1- left))))
    (t 0)))

;;; PRACTICE's HP / KONPAKU rows (the user's request 2026-09-28): the values RESET POSITION and every refill restore
(defparameter *practice-hp* '(100 75 50 25 10) "The P1 HP / DUMMY HP steps, % of the fighter's Reishi maximum.")
(defun practice-reishi (reishi-max pct) "Reishi for PCT % of REISHI-MAX (never 0: 0 would be a Soul Break)." (max 1 (ceiling (* reishi-max pct) 100)))
(defun konpaku-step (k dir kmax) "The P1 / DUMMY KONPAKU row moved by DIR: 1 .. KMAX, wrapping." (1+ (mod (+ (1- k) dir) kmax)))

;;; the HUD's Konpaku at stake (the user's request 2026-09-28: the flames a Kikon would take now, in red)
(defun konpaku-at-stake (konpaku count)
  "How many of KONPAKU flames a Kikon worth COUNT (the attacker's current form's :kikon-konpaku) would take if it landed
now: the settle's own rule (rules.lisp KIKON-RESULT: at most *KIKON-MAX-EVENT*, at most what is left). The HP-0 Soul
Break's + 1 is not shown."
  (nth-value 1 (kikon-result konpaku count nil)))
