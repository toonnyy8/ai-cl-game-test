;;;; control.lisp — SOUL DUEL's controls (design-v1 §2) on the engine's virtual controller (the
;;;; vpad, engine/lisp/input.lisp): the nine buttons, the command table and both players' device
;;;; bindings, all data. Fighter code reads only vpads; devices, the CPU brain and test scripts
;;;; write them the same way, once per fixed step (VPAD-SET!, VPAD-STICK!), so a replay or a CPU
;;;; press is indistinguishable from a key.
;;;;   (new-vpad &key reader)                a vpad with these buttons (:MOD = the Reiatsu modifier)
;;;;   (vpad-command vp *commands* allowed)  buttons + modifier -> one command keyword
;;;;   (vpad-command-pressed-p vp button mod)   is one *COMMANDS* entry's button buffered?
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
