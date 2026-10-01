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
;;;;   LEARNING     (the user, 2026-10-02: no row of its own) while any of the three is on, the assist learns HIS habits as the
;;;;                learning CPU learns a human's (learn.lisp's model, LEARN-STEP on what it perceives at HARD's delay), one
;;;;                table per opponent character (*ASSIST-LEARN-TABLES*, saved apart). AUTO COMBO then also answers a J
;;;;                pressed in neutral with the counter to his predicted next move (AUTO-READ: K against his K / I, a Hoho
;;;;                against his SP), and baits a predicted burst out of our string (its 2nd hit, then a guard)
;;;;   SP in neutral (the user, 2026-10-02) AUTO COMBO's J pressed while free first asks the CPU's own SP rules (AUTO-SP): the
;;;;                kit's :oki on a downed opponent, its :stun-follow on a stunned one
;;;;   J back        (the user, 2026-10-02) AUTO GUARD also presses J on the first free step out of blocking his J (or K) link
;;;;                that still recovers (J-BEATS-OPEN-P, the CPU's own window): guard -> J at once, J mashing answered
;;;; A CPU never has it, except the debug gate's button-masher (habit :dumb, *ASSIST-DEBUG*): CPU-vs-CPU gates are unchanged.
(in-package :duel)

(defvar *assist-debug* nil "Debug 81000+k: the :dumb scripted player's assist (guard combo break), as ASSIST-CONFIG returns.")
(defvar *assist-brains* (vector nil nil) "Per side, the brain the assist borrows (AI-COMMAND's press, STRING-REFLEX's fields).")
(defvar *assist-plan* (vector nil nil) "Per side, (move . command): AUTO COMBO's choice for that move's hit (NIL: none left).")
(defvar *assist-tag* (vector 0 0) "Per side, frames the AUTO tag still shows over the fighter.")
(defvar *assist-tick* (vector 0 0) "Per side, the match tick of its last step (a smaller one: a new match, a fresh brain).")
(defvar *assist-learn* t "Debug 81030+i: the assist's learner on (1) / off (0) (ASSIST's gate A/B).")

(defun assist-brain (e side)
  "SIDE's assist brain: a fresh one each match (HARD's perception), with a learner over his character's table."
  (let ((b (svref *assist-brains* side)))
    (when (or (null b) (< *match-tick* (svref *assist-tick* side)))
      (let ((o (opp-of e)))
        (setf b (make-brain :difficulty :hard :delay (getf *ai-delay* :hard))
              (svref *assist-brains* side) b (svref *assist-plan* side) nil)
        (when *assist-learn*
          (setf (brain-learn b)
                (make-lrn :tab (learn-table (position (fighter-character (fighter o)) *roster*)
                                            *assist-learn-tables* +pg-assist-learn+)
                          :hx (aref (pos-of o) 0) :hz (aref (pos-of o) 2)
                          :rng (1+ (mod (* 7907 (sim-rnd-state)) 2147483647)))))))
    (setf (svref *assist-tick* side) *match-tick*)
    b))

(defun assist-learn-end (winner)
  "The match is over (LEARN-MATCH-END, WINNER its side, :draw or NIL): each assist learner's opponent's form takes the
result, its table is saved."
  (dolist (e (list *p1* *p2*))
    (let* ((side (fighter-side (fighter e))) (b (svref *assist-brains* side)) (l (and b (brain-learn b))))
      (when (and l (entity-alive-p e) (assist-config e))
        (let ((tab (lrn-tab l)))
          (setf (ltab-form tab) (learn-form-after (ltab-form tab) (cond ((eql winner side) -1.0) ((eql winner :draw) 0.0) (t 1.0))
                                                  *learn-form-match*))
          (learn-save (position (fighter-character (fighter (opp-of e))) *roster*) *assist-learn-tables* +pg-assist-learn+))))))

(defun assist-config (e)
  "E's assist as (guard combo break), GUARD 0 off / 1 HOLD U / 2 ALWAYS, or NIL: a human's SETTINGS, the :dumb CPU's
*ASSIST-DEBUG*, no other CPU."
  (let ((b (brain e)))
    (cond ((null b) (list (setting :auto-guard) (= 1 (setting :auto-combo)) (= 1 (setting :auto-break))))
          ((and (eq (brain-habit b) :dumb) (zerop (fighter-side (fighter e)))) *assist-debug*))))   ; (P1's: the gate's)

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
                           (prog1 (or (string-reflex e b f mv)
                                      (and (eq (brain-why b) :bait) (setf (lrn-cmd (brain-learn b)) nil) :guard-long))   ; the bait
                             (setf (fighter-queued f) q)))))))
    (let ((cmd (cdr (svref *assist-plan* side))))
      (when (and cmd (not (eq cmd :q)) (or (fighter-queued f) (vpad-pressed vp :quick) (eq cmd :guard-long)))
        (setf (svref *assist-plan* side) nil)
        (unless (member cmd '(:f :sig)) (setf (fighter-queued f) nil))   ; a cancel / burst / ender replaces the latched link
        cmd))))

(defun auto-sp (e b s d)
  "AUTO COMBO's SP in neutral (the user, 2026-10-02), by the CPU's own rules as AI-REFLEX uses them: the kit's :oki on a
launched / downed opponent (a full-charge SP1: Yamamoto's Shiranui, Rukia's), its :stun-follow on a stunned one it still
reaches (Rukia's SP2, Ichigo's SP1). NIL: none. Not the SP share of the kit's :moves band (AI-ATTACK's neutral pick): on
every J it turned ~1 in 6 into an SP2 into his guard (129 of 435 blocked, the Reiatsu gone; the gate 51 -> 40 %)."
  (let* ((kit (kit-of e)) (g (gauges e)) (sf (ai-table e :stun-follow)) (c (first sf)))
    (cond ((and (member (snap-state s) '(:air :down)) (eq (ai-table e :oki) :sp1-full) (mv-hold (kit-command-move kit :sp1))
                (kit-command-ok-p e :sp1) (> d 3.0)
                (>= (/ (gauges-reishi g) (float (gauges-reishi-max g))) (ai-table e :oki-above 0.0)))
           :sp1-full)
          ((and sf (eq (snap-state s) :stun) (<= (second sf) d (third sf)) (kit-command-ok-p e c)
                (>= (- (snap-left s) (brain-delay b)) (mv-s (kit-command-move kit c))))
           c))))

(defun auto-read (e f b d)
  "AUTO COMBO's read: J pressed while free, the learner's counter to his predicted next move (an event's planned one, else
his distance band's, when confident and its roll says read him): K (he presses K or I: J's own answer is J), a Hoho (an
SP coming); NIL for the rest (J stays his). Not the Breaker the learning CPU answers a guard with: a CPU sees it coming
and J's it (the gate, 2026-10-02: 404 of them in 40 matches, the masher's wins 51 -> 42 %); AUTO BREAK is that answer."
  (let ((l (brain-learn b)))
    (when l
      (let ((c (or (and (lrn-cmd l) (<= (lrn-delay l) 0) (prog1 (lrn-cmd l) (setf (lrn-cmd l) nil)))
                   (multiple-value-bind (act p n) (learn-predict (lrn-tab l) (learn-band d))
                     (and act (learn-confident-p p n) (learn-roll-p l) (learn-counter act)))))
            (g (gauges e)) (kit (fighter-kit f)))
        (case c
          (:hoho (and (not (kit-rooted kit)) (hoho-allowed-p nil (gauges-fs g) (fighter-hoho-lock f) (gauges-burst g)) :hoho))
          (:q (let ((mv (kit-command-move kit :f)))      ; J beats K / I: his J; a K reaching further than J, ours
                (and mv (kit-command-ok-p e :f) (<= (mv-reach (kit-command-move kit :q)) d (+ (mv-reach mv) 0.4)) :f))))))))

(defun auto-break (e f vp)
  "AUTO BREAK: J pressed while free and he holds a long guard close by: the Breaker, or NIL."
  (let ((o (opp-of e)))
    (and (vpad-command-pressed-p vp :quick nil) (guarding-p o) (not (gauges-guardless (gauges o)))
         (>= (fighter-guard-t (fighter o)) *ai-guard-break-hold*) (< (fighter-dist f) *ai-guard-break-range*)
         (kit-command-ok-p e :breaker)
         :breaker)))

(defun assist-step (e cfg)
  "One step of E's assist CFG (ASSIST-CONFIG): its learner watches him; a press it holds goes on, else AUTO GUARD / COMBO /
BREAK may press one."
  (let* ((f (fighter e)) (side (fighter-side f)) (vp (pilot-vpad (pilot e))) (b (assist-brain e side))
         (st (fighter-state f)) (free (and (member st '(:idle :guard :run)) (zerop (fighter-lock f)))))
    (multiple-value-bind (s d) (brain-perceive e b (opp-of e))   ; him as HARD's delay sees him
      (when (brain-learn b) (learn-step e b s d))
      (when (plusp (svref *assist-tag* side)) (decf (svref *assist-tag* side)))
      (if (plusp (brain-press-left b))
          (progn (decf (brain-press-left b))                 ; a held press (the Breaker's dash, O through the strike, a
                 (vpad-hold! vp (brain-press b))             ; charge, the bait's guard: his J mashing doesn't restart the string)
                 (when (eq (brain-press b) :guard) (vpad-consume! vp :quick) (setf (fighter-queued f) nil)))
          (let ((cmd (or (and free (plusp (first cfg)) (or (= 2 (first cfg)) (vpad-down vp :guard))
                              (or (auto-guard e f)
                                  (and (j-beats-open-p e b) (why b :j-back :q))))   ; guard -> J out of his blocked string
                         (and (second cfg) (eq st :move) (auto-combo e f b side vp))
                         (and (third cfg) free (auto-break e f vp))
                         (and (second cfg) free (vpad-command-pressed-p vp :quick nil)
                              (or (auto-sp e b s d) (auto-read e f b d))))))
            (when cmd
              (vpad-consume! vp :quick)                     ; the J it answered (a guard's press: none)
              (ai-command b (fighter-kit f) cmd (fighter-dist f) e)
              (vpad-stamp! vp (brain-press b) (brain-press-mod b))
              (decf (brain-press-left b))
              (setf (fighter-assist-next f) t (svref *assist-tag* side) *assist-tag-frames*)
              (clog "~a assist ~a" (side-name e) cmd))))
      (setf (brain-was b) st))))   ; (J-BEATS-OPEN-P: the step after blockstun)

(defun assist-system ()
  "Every assisted fighter's step (between BRAIN-SYSTEM and FIGHTER-SYSTEM)."
  (do-entities (e (pl pilot) (f fighter))
    (let ((cfg (assist-config e)))
      (when (and cfg (or (plusp (first cfg)) (second cfg) (third cfg)) (not (member (fighter-state f) '(:cine :intro :win :lose))))
        (assist-step e cfg)))))
