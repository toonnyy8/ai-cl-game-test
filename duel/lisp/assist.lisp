;;;; assist.lisp — ASSIST (the user, 2026-10-01; docs/DUEL_ASSIST.md): the SETTINGS rows AUTO GUARD / AUTO COMBO / AUTO
;;;; BREAK. A layer on a human's vpad, after the devices (PILOT-SYSTEM) and the CPUs (BRAIN-SYSTEM), before FIGHTER-SYSTEM
;;;; reads it: the player gives the intent (U held, J pressed), the CPU's own rules pick the move and press its buttons
;;;; (AI-COMMAND on a borrowed brain). A move it pressed is ASSISTED (FIGHTER-ASSIST-NEXT, taken by START-MOVE / START-HOHO):
;;;; x*ASSIST-MULT* damage (APPLY-HIT), and its Hoho is never PERFECT. The AUTO tag shows over him (HUD-HINT).
;;;;   AUTO GUARD   OFF / HOLD U / ALWAYS: free (and U held, for HOLD U) and a hit about to land (PERFECT-NOW-P, unperceived:
;;;;                the price is the x0.8): the form's parry against a melee move, else a Hoho
;;;;   AUTO COMBO   J pressed during a J / K link that hit: the CPU's choice, made on the hit's land frame (STRING-REFLEX: a
;;;;                link, L, SP2, ORANGE; the O ender off a link-3 hit on a red opponent: the Kikon); J itself is left as his own press
;;;;   AUTO BREAK   J pressed, free, while he has guarded >= *AI-GUARD-BREAK-HOLD* f within *AI-GUARD-BREAK-RANGE*: the Breaker
;;;; A CPU never has it, except the debug gate's button-masher (habit :dumb, *ASSIST-DEBUG*): CPU-vs-CPU gates are unchanged.
(in-package :duel)

(defvar *assist-debug* nil "Debug 81000+k: the :dumb scripted player's assist (guard combo break), as ASSIST-CONFIG returns.")
(defvar *assist-brains* (vector nil nil) "Per side, the brain the assist borrows (AI-COMMAND's press, STRING-REFLEX's fields).")
(defvar *assist-plan* (vector nil nil) "Per side, (move . command): AUTO COMBO's choice for that move's hit (NIL: none left).")
(defvar *assist-tag* (vector 0 0) "Per side, frames the AUTO tag still shows over the fighter.")

(defun assist-config (e)
  "E's assist as (guard combo break), GUARD 0 off / 1 HOLD U / 2 ALWAYS, or NIL: a human's SETTINGS, the :dumb CPU's
*ASSIST-DEBUG*, no other CPU."
  (let ((b (brain e)))
    (cond ((null b) (list (setting :auto-guard) (= 1 (setting :auto-combo)) (= 1 (setting :auto-break))))
          ((eq (brain-habit b) :dumb) *assist-debug*))))

(defun parry-command (e kit)
  "The command of KIT's parry move (a :parry flag) E may start now, or NIL."
  (find-if (lambda (c) (let ((mv (kit-command-move kit c))) (and mv (member :parry (mv-flags mv)) (kit-command-ok-p e c kit))))
           *kit-commands*))

(defun auto-guard (e f)
  "AUTO GUARD: a hit about to land (PERFECT-NOW-P): the parry against his melee move, else a Hoho when allowed; or NIL."
  (when (perfect-now-p e)
    (let ((kit (fighter-kit f)) (g (gauges e)) (fo (fighter (opp-of e))))
      (or (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :main) (parry-command e kit))
          (and (not (kit-rooted kit)) (hoho-allowed-p nil (gauges-fs g) (fighter-hoho-lock f) (gauges-burst g)) :hoho)))))

(defun auto-combo (e f b side vp)
  "AUTO COMBO: on a J / K link's land frame, the CPU's next step (the O ender off a link-3 hit on a red opponent, else
STRING-REFLEX with the latch emptied); pressed once J was pressed in this move (latched or buffered). J (:q) stays his own."
  (let ((mv (fighter-move f)) (kit (fighter-kit f)))
    (unless (eq (car (svref *assist-plan* side)) mv) (setf (svref *assist-plan* side) nil))
    (when (and (eq (fighter-contact f) :hit) (= (fighter-sf f) (fighter-land-sf f)) (member (mv-kind mv) '(:quick :flash)))
      (setf (svref *assist-plan* side)
            (cons mv (if (and (member :ender (mv-flags mv)) (kikon-ready-p e) (not (ai-sb-finish-p e)) (kit-command-ok-p e :kikon kit t))
                         :kikon
                         (let ((q (fighter-queued f)))
                           (setf (fighter-queued f) nil)
                           (prog1 (string-reflex e b f mv) (setf (fighter-queued f) q)))))))
    (let ((cmd (cdr (svref *assist-plan* side))))
      (when (and cmd (not (eq cmd :q)) (or (fighter-queued f) (vpad-pressed vp :quick)))
        (setf (svref *assist-plan* side) nil)
        (unless (member cmd '(:f :sig)) (setf (fighter-queued f) nil))   ; a cancel / burst / ender replaces the latched link
        cmd))))

(defun auto-break (e f vp)
  "AUTO BREAK: J pressed while free and he holds a long guard close by: the Breaker, or NIL."
  (let ((o (opp-of e)))
    (and (vpad-command-pressed-p vp :quick nil) (guarding-p o) (not (gauges-guardless (gauges o)))
         (>= (fighter-guard-t (fighter o)) *ai-guard-break-hold*) (< (fighter-dist f) *ai-guard-break-range*)
         (kit-command-ok-p e :breaker)
         :breaker)))

(defun assist-step (e cfg)
  "One step of E's assist CFG (ASSIST-CONFIG): a press it holds goes on, else AUTO GUARD / COMBO / BREAK may press one."
  (let* ((f (fighter e)) (side (fighter-side f)) (vp (pilot-vpad (pilot e)))
         (b (or (svref *assist-brains* side) (setf (svref *assist-brains* side) (make-brain :difficulty :hard :delay 8))))
         (st (fighter-state f)) (free (and (member st '(:idle :guard :run)) (zerop (fighter-lock f)))))
    (when (plusp (svref *assist-tag* side)) (decf (svref *assist-tag* side)))
    (if (plusp (brain-press-left b))
        (progn (decf (brain-press-left b))                   ; a held press (the Breaker's dash, O through the strike)
               (vpad-hold! vp (brain-press b)))
        (let ((cmd (or (and free (plusp (first cfg)) (or (= 2 (first cfg)) (vpad-down vp :guard)) (auto-guard e f))
                       (and (second cfg) (eq st :move) (auto-combo e f b side vp))
                       (and (third cfg) free (auto-break e f vp)))))
          (when cmd
            (vpad-consume! vp :quick)                       ; the J it answered (a guard's press: none)
            (ai-command b (fighter-kit f) cmd (fighter-dist f) e)
            (vpad-stamp! vp (brain-press b) (brain-press-mod b))
            (decf (brain-press-left b))
            (setf (fighter-assist-next f) t (svref *assist-tag* side) *assist-tag-frames*)
            (clog "~a assist ~a" (side-name e) cmd))))))

(defun assist-system ()
  "Every assisted fighter's step (between BRAIN-SYSTEM and FIGHTER-SYSTEM)."
  (do-entities (e (pl pilot) (f fighter))
    (let ((cfg (assist-config e)))
      (when (and cfg (or (plusp (first cfg)) (second cfg) (third cfg)) (not (member (fighter-state f) '(:cine :intro :win :lose))))
        (assist-step e cfg)))))
