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
(defparameter *p1-bindings*
  '(:up ((:key :w) (:pad :dpad-up)) :down ((:key :s) (:pad :dpad-down))
    :left ((:key :a) (:pad :dpad-left)) :right ((:key :d) (:pad :dpad-right))
    :quick ((:key :j) (:pad :x) (:touch :quick)) :flash ((:key :k) (:pad :y) (:touch :flash))
    :sig ((:key :l) (:pad :b) (:touch :sig)) :guard ((:key :u) (:pad :lb) (:touch :guard))
    :breaker ((:key :i) (:pad :rb) (:touch :breaker)) :kikon ((:key :o) (:pad :rt) (:touch :kikon))
    :step ((:key :space) (:pad :a) (:touch :step)) :mod ((:key :lshift) (:pad :lt) (:touch :mod))
    :awaken ((:key :p) (:pad :back) (:pad :ls :rs) (:touch :awaken)))
  "Player 1: left keyboard + pad 0 (design-v1 §2) + the ONE-HAND thumb deck ((:touch name): onehand.lisp
TOUCH-BUTTON; its drag stick is added like pad 0's). Menus read the devices directly (flow.lisp).")

(defparameter *p2-bindings*
  '(:up ((:key :up) (:pad :dpad-up)) :down ((:key :down) (:pad :dpad-down))
    :left ((:key :left) (:pad :dpad-left)) :right ((:key :right) (:pad :dpad-right))
    :quick ((:key :kp-1) (:pad :x)) :flash ((:key :kp-2) (:pad :y)) :sig ((:key :kp-3) (:pad :b))
    :guard ((:key :kp-4) (:pad :lb)) :breaker ((:key :kp-5) (:pad :rb)) :kikon ((:key :kp-6) (:pad :rt))
    :step ((:key :kp-0) (:pad :a)) :mod ((:key :kp-enter) (:pad :lt))
    :awaken ((:key :kp-plus) (:pad :back) (:pad :ls :rs)))
  "Player 2: arrows + numpad + pad 1 (design-v1 §2).")

;;; ---------------------------------------------------------------- SETTINGS (the 2026-09-28 SETTINGS screen)
;;; The rows as data: flow.lisp shows and changes them, onehand.lisp puts them into effect and saves each one
;;; through the page (duel/web/pwa.js: localStorage "soulduel.<name>", the page value = option index + 1, 0 = never
;;; saved or storage blocked -> the default). The page names the rows in this order.
(defparameter *settings*
  '((:one-hand "ONE-HAND" ("AUTO" "ON" "OFF") 0 nil "AUTO: ON FOR A TOUCH PHONE HELD UPRIGHT")
    (:hand "HAND" ("RIGHT" "LEFT") 0 nil "THE THUMB DECK'S SIDE")
    (:tap-split "TAP SPLIT" ("40%" "45%" "50%" "55%" "60%") 2 (0.4 0.45 0.5 0.55 0.6) "THE PAD'S TOP PART THAT TAPS K")
    (:flick "SENSITIVITY" ("1" "2" "3" "4" "5") 2 (40 34 28 23 18) "HIGHER: A SHORTER FLICK")
    (:camera "CAMERA" ("BEHIND" "SIDE") 0 nil "VS CPU AND PRACTICE, TWO HANDS"))
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
