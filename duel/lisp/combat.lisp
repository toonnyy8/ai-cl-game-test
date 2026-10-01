;;;; combat.lisp — what happens when fighters touch (design-v1 §1, §3, §4): HIT-SYSTEM (clash check,
;;;; then COLLECT every fighter's and hazard's hits, then APPLY them all: a trade is a trade, no side
;;;; goes first; then settle the souls they broke), APPLY-HIT (the triangle, damage, reactions, chip,
;;;; gauges, hitstop, KOSEI; the Kikon rush's strike becomes the Kikon here; the Bankai stances: East's pierce, West's ward
;;;; (360 deg, no blockstun, a crush / Guard Break drops him to East), the parry and its refill), Kikon / Soul Break / awakening
;;;; / form changes (all settled here, at connect time; cinema.lisp only presents them), the perfect-Hoho test and GAUGE-SYSTEM (regen, GUARD HOLD, burns,
;;;; form timers, Hellfire, EVOLUTION). Decisions are rules.lisp's; effects are EMITted for feedback.lisp.
(in-package :duel)

;;; ---------------------------------------------------------------- damage and gauges
(defvar *blow-aways* 0 "Blow-aways (the hidden stun past a tolerance) this match: the gate rows' count.")
(defvar *kikons* nil
  "(attacker victim move) of every Kikon rush strike confirmed during this step's HIT-SYSTEM
(KIKON-CONFIRM-P): settled with the Soul Breaks at its end (SETTLE-SOULS).")

(defvar *soul-breaks* nil
  "(attacker . victim) of every Reishi that reached 0 during this step's HIT-SYSTEM: settled together
at its end (SETTLE-SOULS), so a lethal trade breaks both souls and no side goes first.")

(defun siphon-of (e)
  "The fighter taking E's gains now, or NIL: the opponent's kit's :siphon hook (o e) is true while something of his drains
E (a zone he stands in). Asked at every gain, so it ends the frame the zone ends or E leaves it. Siphoned, E gains nothing
from a hit, a block, a parry or his own blade (GAIN-GAUGES, KOSEI!, NOME-GAIN!, ADD-METER, COLD-ADD!, the parry's
refill, SETTLE-KONPAKU's Fighting Spirit); his Reiatsu and flash-step gains go to that fighter, the rest is lost."
  (let* ((o (opp-of e)) (h (and (entity-alive-p o) (kit-hook (kit-of o) :siphon))))
    (and h (funcall h o e) o)))

(defun pay-gauges (e r fs)
  "E gains R Reiatsu and FS flash-step (each kept at its max; no flash-step during a burst: BURST-FS-GAIN)."
  (let ((g (gauges e)))
    (setf (gauges-reiatsu g) (f32 (gauge-add (gauges-reiatsu g) r *reiatsu-max*))
          (gauges-fs g) (f32 (gauge-add (gauges-fs g) (burst-fs-gain fs (gauges-burst g)) *fs-max*)))))

(defun gain-gauges (e dealt taken)
  "Reiatsu, flash-step and Fighting Spirit for dealing DEALT / taking TAKEN damage (HIT-GAINS; siphoned: SIPHON-OF)."
  (let ((g (gauges e)) (to (siphon-of e)))
    (multiple-value-bind (r fs aw sr sfs) (hit-gains dealt taken to (burst-gain-mult (gauges-burst g)))
      (pay-gauges e r fs)
      (when to (pay-gauges to sr sfs))
      (unless (gauges-awakened g)
        (setf (gauges-awaken g) (f32 (gauge-add (gauges-awaken g) aw *awaken-max*)))))))

(defun deal-damage (att def dmg)
  "DEF loses DMG Reishi (ATT dealt it; a CPU attacker's anti-stall heat resets). Reishi at 0 is an automatic Soul
Break, settled at the end of the step (*SOUL-BREAKS*): returns T then."
  (let ((ga (gauges att)) (gd (gauges def)) (b (brain att)))
    (setf (gauges-reishi gd) (max 0 (- (gauges-reishi gd) dmg)))
    (incf (gauges-dealt ga) dmg)
    (when b (setf (brain-heat b) 0f0))
    (incf (fighter-combo-dmg (fighter def)) dmg)
    (gain-gauges att dmg 0)
    (gain-gauges def 0 dmg)
    (nome-gain! att dmg 0 0)
    (nome-gain! def 0 dmg 0)
    (when (soul-break-p (gauges-reishi gd))
      (unless (rassoc def *soul-breaks*) (push (cons att def) *soul-breaks*))
      t)))

(defun nome-gain! (e dealt taken drunk)
  "NOME (a form with :meter-gain: Nozarashi's cups) for DEALT / TAKEN / DRUNK points; a gain restarts RYOTE's
drain delay."
  (let ((mg (kit-meter-gain (kit-of e))))
    (when (and mg (not (siphon-of e)))
      (let ((n (nome-gain dealt taken drunk mg)) (g (gauges e)))
        (when (plusp n)
          (setf (gauges-meter g) (f32 (gauge-add (gauges-meter g) n (getf (kit-meter (kit-of e)) :max 100.0)))
                (gauges-meter-idle g) 0))))))

(defun respect (e)
  "The opponent outplayed E (his counter-hit, perfect Hoho, parry or Burst against E): E's :respect-callout
(Nozarashi: \"OMOSHIREE!\", a callout only: no meter)."
  (let ((c (kit-respect-callout (kit-of e)))) (when c (callout e c))))

(defun add-meter (e amount)
  "The kit meter (Inferno) of E's form, if it has one and isn't running as a timer."
  (let ((g (gauges e)) (m (kit-meter (kit-of e))))
    (when (and m (plusp amount) (zerop (gauges-form-left g)) (not (siphon-of e)))
      (setf (gauges-meter g) (f32 (gauge-add (gauges-meter g) amount (getf m :max)))))))

(defun kosei! (att g x y z)
  "KOSEI (docs/DUEL_STRINGS.md §5): a contact of ATT's own melee hit window worth guard value G pays him Reiatsu and
flash-step, x KOSEI-MULT of his guard gauge (x1 full .. x3 empty); the :kosei event (the HUD's mote from X Y Z). Siphoned
(SIPHON-OF), it pays the siphoning side."
  (let ((to (or (siphon-of att) att)))
    (multiple-value-bind (r fs m) (kosei-gain g (gauges-gg (gauges att)))
      (pay-gauges to (* r (burst-gain-mult (gauges-burst (gauges att)))) fs)   ; ORANGE: x1.5 Reiatsu
      (emit :kosei to m x y z))))

;;; ---------------------------------------------------------------- one hit
(defun drain-guard (e v &optional (why :block))
  "E's guard gauge loses V (its regen waits *GG-DELAY* again). At 0 he is guardless until it is full (CAN-GUARD-P).
T when this drain emptied it."
  (let ((g (gauges e)))
    (multiple-value-bind (n crushed) (gg-drain (gauges-gg g) v)
      (setf (gauges-gg g) (f32 n) (gauges-gg-idle g) 0)
      (when (and crushed (not (gauges-guardless g)))
        (setf (gauges-guardless g) t)
        (clog "~a GUARDLESS ~a" (side-name e) why))
      crushed)))

(defun ward-drop (e)
  "E's ward is broken (a GUARD CRUSH or a Guard Break): Bankai West drops to his kit's :drop-to form (East), the garb
blown off (the :ward-crush event); a kit with a :crush-hook calls it instead (Rukia's CRACK)."
  (when (passive-p e :ward)
    (let ((h (kit-crush-hook (kit-of e))))
      (if h
          (funcall h e)
          (progn (set-form e (kit-drop-to (kit-of e))) (emit :ward-crush e))))
    (clog "~a WARD BROKEN" (side-name e))))

(defun cold-add! (e n)
  "E's cold gauge (a :temp kit meter) changes by N (a blocked melee hit cools her, a real hit warms her), clamped to
0 .. *COLD-MAX*; the band follows once she is free (TEMP-STEP)."
  (when (and (getf (kit-meter (kit-of e)) :temp) (or (<= n 0) (not (siphon-of e))))   ; (siphoned: no cooling)
    (let ((g (gauges e)))
      (setf (gauges-meter g) (f32 (max 0.0 (min *cold-max* (+ (gauges-meter g) n))))))))

(defun scorch (att def &optional (n *scorch*))
  "DEF's :scorch (Bankai West): a melee hit his parry caught burns ATT N (a burn: never kills, no gauges, no heat
reset)."
  (when (and (passive-p def :scorch) (plusp n))
    (let ((g (gauges att))) (setf (gauges-reishi g) (burn (gauges-reishi g) n)))
    (emit :scorch att)
    (clog "~a scorched ~d" (side-name att) n)))

(defun freeze-touch! (e att)
  "E's absolute zero (passive :freeze-touch, once per zero window): the melee hit her ward just blocked freezes ATT, a
:bind hazard at his feet a frame later (unguardable, no damage, *FREEZE-TOUCH* frames: an opener that books 2 combo hits,
so he may Burst)."
  (let ((q (pos-of att)))
    (setf (gauges-froze (gauges e)) t)
    (spawn-hazard :freeze e :x (aref q 0) :z (aref q 2) :size 0.7 :y 2.2 :delay 1 :life 2
                          :hw (make-hitwin :dmg 0 :react :bind :stun *freeze-touch* :hs *hitstop-heavy* :frost *freeze-touch*
                                           :flags '(:unguardable :ice)))
    (emit :sfx :freeze e)
    (clog "~a FREEZE-TOUCH ~a" (side-name e) (side-name att))))

(defun apply-hit (att def hw sx sz &key mv hazard def-state (bonus 0) crush x z red)
  "Apply hit HW of ATT (a fighter) to DEF, coming from (SX SZ) (the attacker or the HAZARD: guard
facing and push direction). MV, BONUS (damage added: the stance's stored) and CRUSH: ATT's move
and its state when the hit was collected (in a trade the first hit applied may already have put ATT
in hitstun). DEF-STATE and RED: DEF's triangle state and red-ness when collected. X Z: where to show
it. Sets the global hitstop (sim timing). A ranged hit (a HAZARD, or a window flagged :ranged beyond its move's
:melee-range) can't be parried. A defender with the :ward (Bankai West) blocks from every side with no blockstun (what
he does goes on: super armour); a crush or a Guard Break drops him to East (WARD-DROP). An attacker with :pierce
(Bankai East) deals x(1 + k) (PIERCE-RATE of his guard gauge, x the move's :pierce-mult), and a block lets k x the
damage through as chip (on top of a DRINK's taken half). A Kikon rush strike (MV of kind :kikon) is guardable like any
hit; one that hits with ATT still holding the button that started it (KIKON-OUTCOME) knocks DEF back into
a short stagger and ATT's rush dashes in after him to the follow-up strike (phase :follow), whose hit is the
Kikon (no damage, queued in *KIKONS* for SETTLE-SOULS): a guard held during the dash blocks it unless DEF
is RED (KIKON-FOLLOW-UNGUARDABLE-P). Returns RESOLVE-CONTACT's result (NIL = no effect)."
  (let* ((fa (fighter att)) (fd (fighter def)) (flags (hw-flags hw))
         (p (pos-of def))
         (d2 (+ (expt (- (aref p 0) sx) 2) (expt (- (aref p 2) sz) 2)))   ; DEF's distance (squared) from the attacker
         ;; ranged: not the attacker's own blade (a projectile, a line, a cone); a :ranged window with a :melee-range
         ;; (the Meteor, the cash-out, Buttagiru, Nadegiri) is the blade within it: one window, one hit
         (ranged (ranged-hit-p hazard flags (and mv (getf (mv-params mv) :melee-range)) d2))
         (optic (optic-p (passive-p def :ward) (passive-p def :optic) ranged))   ; Rukia's absolute zero: ranged hits pass
         (def-state (if (and optic (eq def-state :guard)) :neutral def-state))
         (ward (and (or (passive-p def :ward)           ; Bankai West's ward; a :parry-block parry blocks what it can't catch
                        (and (eq def-state :parry) (passive-p def :parry-block)))
                    (not optic)))
         (k (if (passive-p att :pierce)                 ; Bankai East's pierce
                (pierce-rate (gauges-gg (gauges att)) (or (and mv (getf (mv-params mv) :pierce-mult)) 1.0))
                0.0))
         (rush (and mv (eq (mv-kind mv) :kikon)))
         (own (and mv (eq (fighter-move fa) mv)))       ; the attacker is still in that move
         (fstrike (and rush own (fighter-follow fa)))   ; the dash-in's strike: the Kikon if it hits
         (res (resolve-contact def-state
                               :breaker (member :breaker flags)
                               :guard-crush (or (member :guard-crush flags) crush
                                                (let ((r (and mv (getf (mv-params mv) :crush-range))))   ; NOMIHOSE: near only
                                                  (and r (< d2 (* r r)))))
                               :in-front (in-front-p (yaw-of def) (aref p 0) (aref p 2) sx sz *guard-arc*)
                               :unguardable (or (member :unguardable flags) (and fstrike (kikon-follow-unguardable-p red)))
                               :hazard ranged :ward ward :rend (member :rend flags)))
         (atk (kit-atk-mods (kit-of att) (- *konpaku-max* (gauges-konpaku (gauges att)))
                            (* (if (eq res :blocked) 1.0 (+ 1.0 k)) (if (and own (fighter-assisted fa)) *assist-mult* 1.0))))   ; ASSIST
         (dmods (if optic '(:mult 1.0) (kit-def-mods (kit-of def))))   ; (a ranged hit through Rukia's ward: x1.0 taken)
         (x (or x (aref p 0))) (z (or z (aref p 2))) (y (+ (aref p 1) 1.1))
         (base (+ (hw-dmg hw) bonus))
         (outcome (and rush (kikon-outcome (vpad-down (pilot-vpad (pilot att)) :kikon) res fstrike)))
         (follow (eq outcome :follow)))                 ; knocked back, then the rusher dashes in to the follow-up
    (when (eq outcome :kikon)
      (setf res :kikon)
      (unless (find def *kikons* :key #'second) (push (list att def mv) *kikons*)))
    (when res
      (let ((first (and own (not (eq (fighter-contact fa) :hit)) (eq (contact-of res) :hit))))   ; its first real hit
        (when own                                       ; only a real hit counts as one (CONTACT-OF)
          (setf (fighter-contact fa) (if (eq (contact-of res) :hit) :hit (or (fighter-contact fa) :block)))
          (when (< (fighter-land-sf fa) 0) (setf (fighter-land-sf fa) (fighter-sf fa))))
        (clog "~a ~a -> ~a ~a ~d" (side-name att) (if mv (mv-name mv) (if hazard (hazard-kind hazard) :counter))
              (side-name def) res base)
        (when (eq (contact-of res) :hit) (close-rifts def))   ; a rift closes if its owner is hit before it cuts
        (when (and own (not ranged) (not (member res '(:parried :kikon))))   ; KOSEI: his own blade touched him
          (kosei! att (or (hw-guard hw) 0) x y z))
        (when (eq res :counter) (respect def) (incf (gauges-counters (gauges att))))
        (ecase res
          (:kikon nil)                                  ; settled at the end of the step (SETTLE-SOULS)
          ((:hit :counter)
           (multiple-value-bind (react hits launches air)
               (combo-step (if follow :stagger (hw-react hw)) (eq (fighter-state fd) :air) (fighter-combo-hits fd)
                           (fighter-combo-launches fd) (fighter-combo-air fd))
             (setf (fighter-combo-hits fd) hits (fighter-combo-launches fd) launches (fighter-combo-air fd) air)
             ;; the hidden stun (every connected hit, hazards and clones too); past his tolerance this hit blows him away:
             ;; a knockdown sliding ~5 m, the gauge back to 0. A Kikon rush's strike never does (its Kikon / follow-up
             ;; resolves first), nor a Soul Break's hit (DEAL-DAMAGE: no reaction)
             (let* ((gd (gauges def))
                    (st (stun-add (gauges-stun gd) (if follow :stagger (hw-react hw)) (and mv (member (mv-kind mv) '(:sp :kikon)))))
                    (blow (and (not rush) (not (eq (gauges-burst (gauges att)) :orange))   ; ORANGE lifts his tolerance
                               (stun-over-p st (stun-tolerance-of (kit-of def)))))
                    (react (if blow :knockdown react))
                    (dmg (let ((d (hit-damage base atk dmods hits (eq res :counter))))   ; :spare never takes the last point
                           (if (member :spare flags) (min d (max 0 (1- (gauges-reishi (gauges def))))) d)))
                    (stun (cond (follow (kikon-follow-stun red (mv-s mv)))
                                ((and (hw-stun hw) (eq react (hw-react hw))) (hw-stun hw))   ; (a bind in a combo: a flinch)
                                (t (hitstun react (eq res :counter)))))
                    (frost (max (hw-frost hw) (kit-frost-touch (kit-of att)))))
               (setf (gauges-stun gd) (if blow 0f0 (f32 st)) (gauges-stun-idle gd) 0)
               (when (plusp frost) (setf (fighter-frost fd) (frost-next (fighter-frost fd) frost)))   ; Rukia's ice
               (if ranged (incf (gauges-taken-ranged (gauges def)) dmg) (incf (gauges-taken-melee (gauges def)) dmg))
               (cold-add! def (- (* *ru-hit-warm* dmg)))  ; Rukia: a real hit warms her
               (setf (gauges-best-combo (gauges att)) (max hits (gauges-best-combo (gauges att))))
               (add-meter att (hw-meter hw))
               (hitstop (hw-hs hw))
               (emit :hit att def x y z (hw-hs hw) (eq res :counter) dmg
                     (cond ((member :ice flags) :ice) ((eq react :bind) :bind) ((member :blade flags) :flash)
                           ((member :thread flags) :quick) (hazard :fire)
                           (mv (mv-kind mv)) (t :counter)))
               (unless (deal-damage att def dmg)          ; (a broken soul crumples in its cinematic)
                 (if blow
                     (progn (set-reaction def react stun sx sz *stun-blow-kb*)   ; the blow-away
                            (incf *blow-aways*)
                            (clog "~a BLOWN AWAY by ~a (stun tolerance ~,1f, combo hit ~d)" (side-name def) (side-name att)
                                  (stun-tolerance-of (kit-of def)) hits))
                     (progn (set-reaction def react stun sx sz (if follow *kikon-follow-kb* (hw-kb hw)))
                            (when (and own (not hazard) (not (fighter-chained fa))   ; a string's opener (J1 / K1) hit:
                                       (member (mv-kind mv) '(:quick :flash))         ; the attacker dashes in to
                                       (eq mv (kit-command-move (kit-of att) (if (eq (mv-kind mv) :quick) :q :f))))
                              (let ((pull (- (sqrt d2) *string-pull-to*)))         ; point-blank, so the string's links
                                (when (> pull 0.01)                                ; reach him (the user 2026-10-02:
                                  (set-slide att pull *string-pull-frames* (- (aref p 0) sx) (- (aref p 2) sz))))))))   ; no chase)
               (when (and follow own)                     ; the rush dashes in, then strikes again (KIKON-RUSH-STEP)
                 (setf (fighter-phase fa) :follow (fighter-hold fa) 0 (fighter-follow fa) t)
                 (emit :kikon-follow att def)
                 (emit :rush-dash att)
                 (clog "~a KIKON FOLLOW-UP on ~a~:[~; (red)~]" (side-name att) (side-name def) red)))))
          (:armored                                     ; a move's armour (one hit spent)
           (when (eq def-state :armor) (decf (fighter-armor-left fd)))
           (hitstop *hitstop-block*)
           (emit :armored def x y z)
           (deal-damage att def (hit-damage base atk dmods 1 nil)))
          (:parried                                     ; the attacker staggers, the parry counters (its :land string)
           (hitstop *hitstop-breaker*)
           (respect att)
           (set-reaction att :stagger *parry-stun* (aref p 0) (aref p 2) *parry-slide*)
           (setf (fighter-armor-left fa) 0)
           (scorch att def)
           (when (and (passive-p def :ward) (not (siphon-of def)))   ; West's GOKUI GAESHI: the catch refills his guard gauge
             (setf (gauges-gg (gauges def)) (f32 *gg-max*) (gauges-gg-idle (gauges def)) 0))
           (let ((h (kit-hook (kit-of def) :parried))) (when (and h (not (siphon-of def))) (funcall h def att)))   ; its own catch
           (emit :parried att def x y z)
           (let ((c (and (fighter-move fd) (kit-next (kit-of def) (mv-name (fighter-move fd)) :land))))
             (when c (start-move def c))))
          (:absorbed
           (let ((dmg (hit-damage base atk dmods 1 nil)))
             (setf (fighter-stored fd) (stance-store (fighter-stored fd) dmg))
             (hitstop *hitstop-block*)
             (emit :absorbed def x y z)
             (deal-damage att def dmg)
             (nome-gain! def 0 0 dmg)))                 ; the stance drinks what it absorbs (NOME)
          (:blocked                                     ; blockstun, chip, the guard gauge (at 0: GUARD CRUSH);
                                                        ; DRINK (NOMIHOSE's U): half the hit taken for real, half drunk;
                                                        ; the ward (Bankai West): x*WARD-MULT* of the gauge, no blockstun;
                                                        ; East's pierce: k x the hit goes through (chip)
           (let* ((drink (passive-p def :drink))
                  (catch (and ranged (fighter-move fd) (getf (mv-params (fighter-move fd)) :catch)))   ; a :shield move's catch
                  (adv (let ((a (if (and mv (integerp (mv-adv-block mv))) (mv-adv-block mv) 0)))
                         (- (if (and drink mv) (drink-adv a) a)          ; (the attacker's advantage: a blocked J's
                            (if (and mv (eq (mv-kind mv) :quick)) *quick-block-adv* 0))))   ; defender is free sooner)
                  (stun (if mv (blockstun (mv-total mv) (fighter-sf fa) adv) *hazard-blockstun*))
                  (v (let* ((v0 (or (hw-guard hw) *gg-hazard*)) (v1 (if (and mv (passive-p att :cut)) (cut-value v0 (mv-kind mv)) v0)))
                       (if (and ward (passive-p def :ward)) (* *ward-mult* v1) v1)))
                  (pierce (and (plusp k) k))
                  (chip (if (or catch (passive-p def :chipless))   ; Rukia awakened: no chip on her
                            0
                            (chip-damage base (if drink pierce (or (hw-chip hw) (and mv (kit-blade-chip (kit-of att))) pierce))
                                         (gauges-reishi (gauges def))))))
             (cond (catch (funcall catch def base) (hitstop *hitstop-block*) (emit :blocked att def x y z))   ; no gauge, no stun
                   ((drain-guard def v)
                    (ward-drop def)
                    (set-reaction def :guard-break *guard-crush-stun* sx sz *block-pushback*)
                    (hitstop *hitstop-breaker*)
                    (emit :guard-crush att def x y z)
                    (clog "~a GUARD CRUSH~:[~; (drinking)~]" (side-name def) drink))
                   (ward                                ; super armour: no blockstun, what he does goes on
                    (set-slide def *block-pushback* 6 (- (aref p 0) sx) (- (aref p 2) sz))
                    (setf (fighter-warded fd) *match-tick*)
                    (when (and (passive-p def :freeze-touch) (not ranged) (not (gauges-froze (gauges def))))
                      (freeze-touch! def att))           ; Rukia's absolute zero: whatever touches her freezes
                    (hitstop *hitstop-block*)
                    (emit :blocked att def x y z))
                   (t (set-blockstun def stun sx sz adv (and drink (kit-drink-clip (kit-of def))))
                      (hitstop *hitstop-block*)
                      (emit (if drink :drink :blocked) att def x y z)))
             (when drink                                ; the drink: real damage (it may Soul Break him), NOME
               (multiple-value-bind (taken drunk) (drink-split (hit-damage base atk dmods 1 nil))
                 (deal-damage att def taken)
                 (nome-gain! def 0 0 drunk)
                 (clog "~a DRINK ~d (+~d drunk)" (side-name def) taken drunk)))
             (when (plusp chip) (deal-damage att def chip))
             (when (and mv (not ranged)) (cold-add! def (* *ru-block-cool* (or (hw-guard hw) 0))))   ; Rukia: a blocked blade cools her
             (when (and hazard (plusp (hw-meter hw))) (add-meter att *meter-on-block*))))
          (:guard-break
           (drain-guard def *gg-breaker* :breaker)
           (ward-drop def)                              ; a Breaker blows West's ward off: East
           (set-reaction def :guard-break *guard-break-stun* sx sz *guard-break-kb*)
           (hitstop *hitstop-breaker*)
           (emit :guard-break att def x y z))
          (:stance-break
           (set-reaction def :crumple *stance-break-stun* sx sz *stance-break-kb*)
           (hitstop *hitstop-breaker*)
           (emit :stance-break att def x y z)))
        (let ((h (kit-hook (kit-of att) :hit))) (when h (funcall h att def res hw mv hazard ranged)))   ; a character's
        (let ((h (kit-hook (kit-of def) :struck))) (when h (funcall h def att res hw mv hazard ranged)))   ; own hit rules
        (when (and first (mv-on-land mv) (not *cine*)) (funcall (mv-on-land mv) att)))
      res)))

;;; ---------------------------------------------------------------- the system
(defstruct pending
  "One hit collected this step, with what it needs of the attacker as he was then (they are applied
after all are collected). I: the move's window index; HAZARD: the hazard dealing it (NIL = melee);
STATE RED: the defender's triangle state and red-ness; MV BONUS CRUSH: the attacker's move, stored
damage, guard crush."
  att def hw (i 0) (sx 0f0) (sz 0f0) hazard state red mv (bonus 0) crush)

(defvar *pending* nil "Hits collected this step, applied together.")

(defun collect-melee (e f)
  "E's move windows open this frame that touch the opponent (each window hits once), and a perfect
Hoho's counter strike on its frame (it always connects)."
  (let ((mv (fighter-move f)) (o (fighter-opp f)) (p (pos-of e)))
    (when (entity-alive-p o)
      (when (and (eq (fighter-state f) :hoho) (fighter-perfect f) (= (fighter-sf f) *hoho-counter-strike*))
        (push (make-pending :att e :def o :hw *perfect-hw* :sx (aref p 0) :sz (aref p 2) :state (defender-state o))
              *pending*))
      (when (and (eq (fighter-state f) :move) (eq (fighter-phase f) :main))
        (let* ((sf (fighter-sf f)) (q (pos-of o)) (yaw (yaw-of e)) (go (gauges o))
               (fx (f32 (fwd-x yaw))) (fz (f32 (fwd-z yaw))) (ob (model-body (model o))))
          (loop for w across (mv-hits mv) for i from 0
                when (and (<= (hw-from w) sf) (< sf (hw-to w)) (not (logbitp i (fighter-hits f)))
                          (loop for v in (hw-vols w)
                                thereis (vol-hit-p v (aref p 0) (aref p 1) (aref p 2) fx fz (aref q 0) (aref q 1) (aref q 2)
                                                   (body-hurt-r ob) (body-hurt-h ob) 0f0)))
                  do (push (make-pending :att e :def o :hw w :i i :sx (aref p 0) :sz (aref p 2)
                                         :state (defender-state o) :mv mv
                                         :red (red-p (gauges-reishi go) (gauges-reishi-max go))
                                         :bonus (fighter-dmg-bonus f) :crush (fighter-crush f))
                           *pending*)))))))

(defun cut-hazards (e f)
  "Nozarashi (:projectile-cut): an open window of E's move destroys the opponent's hazards it touches."
  (let ((mv (fighter-move f)))
    (when (and (passive-p e :projectile-cut) (eq (fighter-state f) :move) (eq (fighter-phase f) :main))
      (let* ((sf (fighter-sf f)) (p (pos-of e)) (yaw (yaw-of e)) (fx (f32 (fwd-x yaw))) (fz (f32 (fwd-z yaw))))
        (loop for w across (mv-hits mv)
              when (and (<= (hw-from w) sf) (< sf (hw-to w)))
                do (do-entities (h (hz hazard))
                     (when (and (not (eql (hazard-owner hz) e)) (member (hazard-kind hz) '(:wave :fireball :bind))
                                (<= (hazard-delay hz) 0)
                                (loop for v in (hw-vols w)
                                      thereis (vol-hit-p v (aref p 0) (aref p 1) (aref p 2) fx fz
                                                         (hazard-x hz) 0f0 (hazard-z hz) (f32 (max 0.5 (hazard-size hz)))
                                                         1.8f0 0f0)))
                       (emit :hazard-cut (hazard-x hz) (f32 (+ 1.0 (hazard-y hz))) (hazard-z hz))
                       (clog "~a cuts ~a" (side-name e) (hazard-kind hz))
                       (destroy-entity h))))))))

(defun clash! (a b)
  "Breaker vs Breaker: both pushed *CLASH-PUSH* apart and stunned *CLASH-STUN*, no damage."
  (let* ((p (pos-of a)) (q (pos-of b)))
    (set-reaction a :clash *clash-stun* (aref q 0) (aref q 2) (* 0.5 *clash-push*))
    (set-reaction b :clash *clash-stun* (aref p 0) (aref p 2) (* 0.5 *clash-push*))
    (hitstop *hitstop-breaker*)
    (emit :clash (* 0.5 (+ (aref p 0) (aref q 0))) 1.2 (* 0.5 (+ (aref p 2) (aref q 2))))
    (clog "CLASH")))

(defun hit-system ()
  "Clash first; then collect every melee and hazard hit of this step; then apply them all; then
settle the souls they broke."
  (let ((a nil) (b nil))
    (do-entities (e (f fighter)) (if a (setf b e) (setf a e)))
    (when (and a b)
      (let ((pa (breaker-phase a)) (pb (breaker-phase b)))
        (when (and pa pb (breaker-clash-p pa pb (fighter-dist (fighter a))))
          (clash! a b)))))
  (do-entities (e (f fighter)) (cut-hazards e f))
  (do-entities (e (f fighter)) (collect-melee e f))
  (collect-hazard-hits)
  (let ((hits (nreverse *pending*)))
    (setf *pending* nil)
    (dolist (h hits)
      (let* ((hz (pending-hazard h)) (fa (fighter (pending-att h))) (mv (pending-mv h))
             (res (apply-hit (pending-att h) (pending-def h) (pending-hw h) (pending-sx h) (pending-sz h)
                             :mv mv :hazard hz :def-state (pending-state h) :red (pending-red h)
                             :bonus (pending-bonus h) :crush (pending-crush h))))
        (when res
          (cond (hz (hazard-connected hz))
                ((and mv (eq mv (fighter-move fa)))   ; (an on-land hook may have started the next move)
                 (setf (fighter-hits fa) (logior (fighter-hits fa) (ash 1 (pending-i h))))))))))
  (settle-souls))

;;; ---------------------------------------------------------------- perfect Hoho
(defun perfect-now-p (e)
  "Would a Hoho started now by E be PERFECT? An opponent hit volume (move or hazard) active now or
within *PERFECT-LEAD* frames overlaps E's hurt cylinder grown by *PERFECT-INFLATE* (rules.lisp), or
his Breaker / Kikon rush dash is within 0.5 m of its trigger range."
  (let* ((o (opp-of e)) (fo (fighter o)) (mv (fighter-move fo)) (p (pos-of e)) (q (pos-of o))
         (b (model-body (model e))) (yaw (yaw-of o)))
    (or (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :main)
             (loop for w across (mv-hits mv)
                   thereis (perfect-hoho-p (fighter-sf fo) (hw-from w) (hw-to w) (hw-vols w)
                                           (aref q 0) (aref q 1) (aref q 2) (f32 (fwd-x yaw)) (f32 (fwd-z yaw))
                                           (aref p 0) (aref p 1) (aref p 2) (body-hurt-r b) (body-hurt-h b))))
        (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :dash)      ; a Breaker / Kikon rush about to strike
             (<= (fighter-dist fo) (+ (if (eq (mv-kind mv) :kikon) *kikon-trigger* *breaker-trigger*) 0.5)))
        (hazard-threat-p o e))))

;;; ---------------------------------------------------------------- Burst Reverse
(defun burst-mode-of (e)
  "The burst mode E's state gives a press now (rules BURST-MODE), or NIL. ORANGE: his move's own hit landed and its
cancel window is open; or his L / O (a :sig or :kikon move, hazards included) has the opponent in hitstun or blockstun
right now (a blocked L / O counts too); or, free or in any move, while the opponent reels (hitstun / airborne) from one of
his hazards (KESSA's clones hitting while his own swing missed, a zone: the user 2026-09-30); free, that replaces WHITE."
  (let* ((f (fighter e)) (mv (fighter-move f)) (st (fighter-state f)) (o (fighter-opp f))
         (os (and o (entity-alive-p o) (fighter-state (fighter o)))))
    (if (and (member st '(:idle :guard :run)) (member os '(:stun :air)) (zerop (fighter-lock f)))
        :orange
        (burst-mode st (plusp (fighter-lock f)) (fighter-combo-hits f)
                    (and (eq st :move) mv (eq (fighter-phase f) :main)
                         (if (member (mv-kind mv) '(:sig :kikon))
                             (member os '(:stun :guard-hit :air))
                             (or (member os '(:stun :air))   ; he reels from my hazard / clone though this move missed
                                 (cancel-open-p (fighter-sf f) (fighter-land-sf f) (mv-total mv) (eq (fighter-contact f) :hit)))))))))

(defun burst-ok-p (e)
  "May E burst now (rules BURST-ALLOWED-P): the mode (:white :blue :orange) or NIL."
  (let ((m (burst-mode-of e)) (g (gauges e)))
    (and (burst-allowed-p m (gauges-fs g) (gauges-burst g)) m)))

(defun repel! (e)
  "E breaks free (a Burst Reverse, an awakening): neutral at once (on the ground), invulnerable *BURST-INVULN* f, his
combo over; the opponent's move / Hoho / step / run ends and he slides *BURST-PUSH* away, not stunned."
  (let* ((f (fighter e)) (mo (motion e)) (o (fighter-opp f)) (p (pos-of e)) (q (pos-of o)))
    (setf (aref p 1) 0f0 (motion-grounded mo) t (motion-kb-left mo) 0)
    (to-idle e 0)
    (setf (fighter-invuln f) *burst-invuln*)
    (when (member (state-of o) '(:move :hoho :step :run))
      (to-idle o 0)
      (setf (model-alpha (model o)) 1f0))
    (set-slide o *burst-push* *burst-push-frames* (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)))
    (respect o)))

(defun burst! (e mode)
  "A burst of MODE starts (FIGHTER-SYSTEM applies it once both fighters have stepped; docs/DUEL_DESIGN.md \"Burst
modes\"): nothing spent, the flash-step drains from now (GAUGE-SYSTEM). BLUE breaks free (REPEL!); ORANGE cancels his
move's recovery, the next move started within *CHAIN-WINDOW* f has its startup cut (START-MOVE). A short global hitstop."
  (let ((o (opp-of e)) (g (gauges e)) (f (fighter e)))
    (setf (gauges-burst g) mode (gauges-burst-t g) 0 (gauges-fs-idle g) 0)
    (case mode
      (:blue (repel! e)                                   ; + one Reiatsu bar, as RoS does (the user 2026-09-30)
       (setf (gauges-reiatsu g) (f32 (gauge-add (gauges-reiatsu g) *reiatsu-bar* *reiatsu-max*))))
      (:orange (to-idle e 0) (setf (fighter-chain f) *chain-window*)))
    (hitstop *burst-hitstop*)
    (emit :burst e o mode)
    (clog "~a BURST ~a fs ~,1f" (side-name e) mode (gauges-fs g))))

(defun burst-end! (e)
  "E's burst ends (its flash-step ran out, or a Kikon / Soul Break reset): the regen delay restarts."
  (let ((g (gauges e)))
    (when (gauges-burst g)
      (clog "~a BURST END ~a" (side-name e) (gauges-burst g))
      (setf (gauges-burst g) nil (gauges-burst-t g) 0 (gauges-fs-idle g) 0 (fighter-chain (fighter e)) 0)
      (emit :burst-end e))))

(defun white-regen! (g n)
  "WHITE's regen on its frame N (1-based): Reishi, Reiatsu and (not yet awakened) the awakening gauge."
  (setf (gauges-reishi g) (min (gauges-reishi-max g) (+ (gauges-reishi g) (burst-heal n *white-reishi*)))
        (gauges-reiatsu g) (f32 (gauge-add (gauges-reiatsu g) (/ *white-reiatsu* 60.0) *reiatsu-max*)))
  (unless (gauges-awakened g)
    (setf (gauges-awaken g) (f32 (gauge-add (gauges-awaken g) (/ *white-awaken* 60.0) *awaken-max*)))))

(defun burst-step (e g)
  "A running burst, one frame: the flash-step drains (BURST-DRAIN), WHITE's regen (WHITE-REGEN!); at 0 it ends."
  (let ((n (incf (gauges-burst-t g))))
    (setf (gauges-fs g) (f32 (burst-drain (gauges-fs g))))
    (when (eq (gauges-burst g) :white) (white-regen! g n))
    (when (<= (gauges-fs g) 0.0) (burst-end! e))))

(defun awake-regen-frames ()
  "How long the awakening's regen runs: as long as a burst from a full flash-step gauge (*FS-MAX* / *BURST-DRAIN*)."
  (round (* 60 (/ *fs-max* *burst-drain*))))

(defun start-awake-regen! (g)
  "An awakening (or Kenpachi's Bankai) starts WHITE's regen for AWAKE-REGEN-FRAMES, on its own clock: it overlaps a burst
and spends no flash-step (the user 2026-09-30)."
  (setf (gauges-awake-regen g) (awake-regen-frames) (gauges-awake-t g) 0))

;;; ---------------------------------------------------------------- forms, awakening
(defun set-form (e form)
  "E's character changes to FORM: the old form's exit hook, the new kit, its timer, look and entry hook."
  (let* ((f (fighter e)) (g (gauges e)) (old (fighter-kit f)) (new (find-kit (fighter-character f) form)))
    (when (and (kit-exit-hook old) (not (eq old new))) (funcall (kit-exit-hook old) e))
    (setf (fighter-kit f) new (fighter-form f) form (gauges-burn-step g) 0
          (gauges-form-left g) (if (kit-duration new) (seconds->frames (kit-duration new)) 0)
          (gauges-form-total g) (gauges-form-left g))
    (refresh-look e)
    (when (kit-enter-hook new) (funcall (kit-enter-hook new) e))
    (emit :form e form)
    (clog "~a form ~a" (side-name e) form)))

(defun awaken! (e)
  "Awakening (once per match): E breaks free as a Burst does (REPEL!), the kit's awakened form, *AWAKEN-HEAL* of max Reishi, then the
form's :cine if it has one (both fighters idle after it). The guard gauge is left as it is."
  (let* ((g (gauges e)) (o (opp-of e)))
    (repel! e)                                          ; the moment breaks his attack, as a Burst (the user 2026-09-29)
    (start-awake-regen! g)                              ; then WHITE's regen for a full burst's time (the user 2026-09-30)
    (setf (gauges-awakened g) t (gauges-awaken g) 0f0 (gauges-evolution g) nil)
    (set-form e (kit-awaken-form (kit-of e)))
    (let ((st (getf (kit-meter (kit-of e)) :start)))    ; NOME starts at 10
      (when st (setf (gauges-meter g) (f32 st) (gauges-meter-idle g) 0)))
    (setf (gauges-reishi g) (min (gauges-reishi-max g) (+ (gauges-reishi g) (round (* *awaken-heal* (gauges-reishi-max g))))))
    (emit :awaken e)
    (if (kit-cine (kit-of e))
        (start-cine (kit-cine (kit-of e)) e o :after (lambda () (to-idle e 0) (to-idle o 0)))
        (to-idle e 0))))

;;; ---------------------------------------------------------------- Kenpachi's Bankai: the arm meter (docs/DUEL_KEN_BANKAI.md)
(defun bankai! (e)
  "The Bankai (P in cup 3, red, free: rules BANKAI-ALLOWED-P): the kit's :bankai-form, its arm meter full (the kit meter
holds the pips, the crack clock at 0), his OWN Konpaku set to 1 and his Reishi refilled (the user's decisions
2026-09-28: all his remaining souls for one full bar fought with the Bankai); the guard gauge, Reiatsu and flash-step as
they are; then the form's :cine (both fighters idle after it)."
  (let* ((g (gauges e)) (o (opp-of e)) (lost (- (gauges-konpaku g) 1)))
    (repel! e)                                          ; the second awakening breaks his attack too
    (start-awake-regen! g)
    (set-form e (kit-bankai-form (kit-of e)))
    (setf (gauges-meter g) (f32 (getf (kit-pips (kit-of e)) :n)) (gauges-meter-idle g) 0 (gauges-arm-pending g) nil
          (gauges-arm-owed g) nil
          (gauges-konpaku g) 1 (gauges-reishi g) (gauges-reishi-max g))
    (refresh-look e)
    (when (plusp lost) (emit :konpaku e lost))
    (emit :bankai e)
    (clog "~a BANKAI (konpaku -> 1, -~d)" (side-name e) lost)
    (if (kit-cine (kit-of e))
        (start-cine (kit-cine (kit-of e)) e o :after (lambda () (to-idle e 0) (to-idle o 0)))
        (to-idle e 0))))

(defun arm-spend! (e mv)
  "A pip command starts MV (or a J / K string's pip is charged as it ends: MV the move running then, NIL none): one pip of
the arm spent, the crack clock restarted, *ARM-SELF* burnt
(BURN: never below 1). The last one: the burst is pending until MV is over (ARM-STEP)."
  (let ((g (gauges e)))
    (multiple-value-bind (n ok) (pip-spend (round (gauges-meter g)))
      (when ok
        (setf (gauges-meter g) (f32 n) (gauges-meter-idle g) 0 (gauges-reishi g) (burn (gauges-reishi g) *arm-self*))
        (when (zerop n) (setf (gauges-arm-pending g) (or mv :none)))
        (refresh-look e)
        (emit :arm-spend e n)
        (clog "~a UDE -~a ~d left" (side-name e) (if mv (mv-name mv) "") n)))))

(defun arm-burst! (e)
  "The arm bursts (the pending burst fired: rules BURST-DUE-P): the kit's :pips :to form (片腕), *ARM-BURST-SELF* burnt
and a self-inflicted *ARM-BURST-STUN* crumple in place (hits on him during it are ordinary hits)."
  (let ((g (gauges e)) (p (pos-of e)))
    (setf (gauges-arm-pending g) nil (gauges-arm-owed g) nil)
    (set-form e (getf (kit-pips (kit-of e)) :to))
    (setf (gauges-meter g) 0f0 (gauges-meter-idle g) 0 (gauges-reishi g) (burn (gauges-reishi g) *arm-burst-self*))
    (set-reaction e :crumple *arm-burst-stun* (aref p 0) (aref p 2) 0.0)
    (callout e "GOMEN NE, KEN-CHAN")
    (emit :arm-burst e)
    (clog "~a ARM BURST r~d" (side-name e) (gauges-reishi g))))

(defun arm-step (e f g)
  "The arm meter per step (a form with :pips): the pip a finished J / K string owes is charged (rules STRING-PIP-DUE-P);
the crack clock (rules PIP-STEP: paused while locked) cracks a pip every *ARM-CRACK* frames without a spend; once the
last pip went, the pending burst fires when BURST-DUE-P says."
  (let ((mv (and (eq (fighter-state f) :move) (fighter-move f))) (pend (gauges-arm-pending g)))
    (when (string-pip-due-p (gauges-arm-owed g) (fighter-state f) (and mv (mv-kind mv)))
      (setf (gauges-arm-owed g) nil)
      (arm-spend! e mv))                                ; (a cancel out of the string: the burst waits for it too)
    ;; the last pip's move goes on as a chain (a latched link, SP2's punch, the O ender): the burst waits for the chain
    (when (and (typep pend 'move) mv (not (eq mv pend)) (move-follows-p (fighter-kit f) pend mv))
      (setf (gauges-arm-pending g) mv)))
  (let ((pend (gauges-arm-pending g)))
    (if pend
        (when (burst-due-p pend (fighter-move f) (fighter-state f)) (arm-burst! e))
        (multiple-value-bind (n idle cracked) (pip-step (round (gauges-meter g)) (gauges-meter-idle g) (plusp (fighter-lock f)))
          (setf (gauges-meter g) (f32 n) (gauges-meter-idle g) idle)
          (when cracked
            (when (zerop n) (setf (gauges-arm-pending g) (or (and (eq (fighter-state f) :move) (fighter-move f)) :none)))
            (refresh-look e)
            (emit :arm-crack e n)
            (clog "~a UDE cracked, ~d left" (side-name e) n))))))

;;; ---------------------------------------------------------------- Kikon, Soul Break, reset
(defun bankai-ready-p (e)
  "May E enter his form's :bankai-form now (P: rules BANKAI-ALLOWED-P, free with <= *BANKAI-KONPAKU* Konpaku)? (The
HUD's P BANKAI prompt, the phone's AWAKEN chip.)"
  (let ((f (fighter e)))
    (and (kit-bankai-form (fighter-kit f))
         (bankai-allowed-p (awaken-state-p e f) (gauges-konpaku (gauges e))))))

(defun kikon-worth (e)
  "Konpaku E's Kikon would take now: a running rush's worth (fixed at its start), else the kit's :kikon-worth hook (E) (a
worth that follows the fighter's state), else the kit's :kikon-konpaku. (The red Konpaku hint: hud.lisp AT-STAKE; a Soul Break takes this + 1: SETTLE-KONPAKU.)"
  (let* ((f (fighter e)) (mv (fighter-move f)) (h (kit-hook (kit-of e) :kikon-worth)))
    (cond ((and mv (eq (fighter-state f) :move) (eq (mv-kind mv) :kikon)) (fighter-kikon-n f))
          (h (funcall h e))
          (t (kit-kikon-konpaku (kit-of e))))))

(defun kikon-ready-p (e)
  "Is E's opponent red: would E's Kikon rush, connecting now with the button held, be the Kikon?
(The HUD's HOLD O prompt, the CPU's rush.)"
  (let ((go (gauges (opp-of e)))) (red-p (gauges-reishi go) (gauges-reishi-max go))))

(defun settle-konpaku (att def soul-break)
  "Konpaku at connect time (KIKON-RESULT): DEF loses the Kikon's count (ATT's rush's, read when it started:
FIGHTER-KIKON-N), or on a Soul Break ATT's KIKON-WORTH now + 1 (at most *SOUL-BREAK-MAX-EVENT*: KESSA's follows his
clones, 3 clones 4 + 1 = 5, the user 2026-09-30); his Reishi refills.
Returns T when DEF is out of Konpaku."
  (let ((gd (gauges def)))
    (multiple-value-bind (left lost ko) (kikon-result (gauges-konpaku gd)
                                                      (if soul-break (kikon-worth att) (fighter-kikon-n (fighter att)))
                                                      soul-break)
      (setf (gauges-konpaku gd) left (gauges-reishi gd) (gauges-reishi-max gd))
      (unless (or (gauges-awakened gd) (siphon-of def))
        (setf (gauges-awaken gd) (f32 (gauge-add (gauges-awaken gd) (awakening-gain 0 0 lost) *awaken-max*))))
      (incf (gauges-kikons (gauges att)))
      (emit :konpaku def lost)
      (clog "~a ~a on ~a: -~d konpaku, ~d left (~a)" (side-name att) (if soul-break "SOUL BREAK" "KIKON") (side-name def) lost left
            (fighter-form (fighter att)))
      ko)))

(defun settle-souls ()
  "The souls broken during this step's HIT-SYSTEM, settled together so no side goes first: every
confirmed Kikon (*KIKONS*: the Kikon count) and every Reishi that reached 0 (*SOUL-BREAKS*: the
count + 1; a Kikon's victim has no Soul Break on top, the Kikon refills his Reishi). Then one
cinematic (the first Kikon's move :cine, else the first Soul Break's attacker's Kikon cinematic: KIT-KIKON-CINE),
then the reset, or the finish (a draw when both souls ran out). The hazards still out are cleared first: the reset clears them anyway,
and frozen through the cinematic their looks would hang in its shots."
  (let* ((kk (reverse *kikons*))
         (sb (remove-if (lambda (s) (find (cdr s) kk :key #'second)) (reverse *soul-breaks*))))
    (setf *kikons* nil *soul-breaks* nil)
    (when (or kk sb)
      (do-entities (e (f fighter)) (burst-end! e))   ; the reset ends every burst, before the Kikon's refund
      (dolist (att (remove-duplicates (append (mapcar #'first kk) (mapcar #'car sb))))   ; a Kikon that connected, or
        (let ((g (gauges att)))                         ; a Soul Break (the user 2026-09-30): a flash-step bar and a Reiatsu bar back
          (multiple-value-bind (fs r) (kikon-refund (gauges-fs g) (gauges-reiatsu g))
            (setf (gauges-fs g) (f32 fs) (gauges-reiatsu g) (f32 r)))))
      (let ((kos (append (loop for (att def nil) in kk when (settle-konpaku att def nil) collect def)
                         (loop for (att . def) in sb when (settle-konpaku att def t) collect def)))
            (a (if kk (first (first kk)) (car (first sb))))
            (v (if kk (second (first kk)) (cdr (first sb)))))
        (loop for (att def mv) in kk
              do (when (mv-callout mv) (callout att (mv-callout mv)))
                 (emit :kikon att def))
        (loop for (att . def) in sb do (emit :soul-break att def))
        (clear-hazards)
        (start-cine (if kk (mv-cine (third (first kk))) (kit-kikon-cine (kit-of a))) a v
                    :after (lambda () (cond ((null kos) (reset-round a v))
                                            ((rest kos) (match-over nil))
                                            (t (match-over (opp-of (first kos)))))))))))

(defun reset-round (a v)
  "After a Kikon / Soul Break (§1): both placed *RESET-DISTANCE* apart facing, *RESET-NEUTRAL* frames
of neutral, P1 on the left of the view again, hazards cleared, the guard gauges full (and guardless cleared) for
everyone, the hidden stun cleared, the forms kept, flash-step and Reiatsu kept, the kit's :reset-reiatsu (Kenpachi)."
  (let ((p (pos-of a)) (q (pos-of v)))
    (multiple-value-bind (ax az bx bz) (reset-placement (aref p 0) (aref p 2) (aref q 0) (aref q 2))
      (v3-set! p (f32 ax) 0f0 (f32 az)) (v3-set! q (f32 bx) 0f0 (f32 bz))))
  (face-each-other a v)
  (if (zerop (fighter-side (fighter a))) (view-step a v t) (view-step v a t))
  (clear-hazards)
  (dolist (e (list a v))
    (let ((f (fighter e)) (g (gauges e)) (mo (motion e)))
      (setf (motion-grounded mo) t (motion-kb-left mo) 0 (fighter-lock f) *reset-neutral* (fighter-combo-dmg f) 0
            (gauges-reiatsu g) (f32 (gauge-add (gauges-reiatsu g) (kit-reset-reiatsu (kit-of e)) *reiatsu-max*)))
      (setf (gauges-gg g) (f32 *gg-max*) (gauges-gg-idle g) 0 (gauges-guardless g) nil (gauges-stun g) 0f0)
      (let ((rf (kit-reset-form (kit-of e))))          ; Rukia: absolute zero never carries over the reset (-18, C 0)
        (when rf (set-form e rf) (setf (gauges-meter g) 0f0 (gauges-meter-idle g) 0)))
      (fill (motion-vel mo) 0f0)
      (vpad-clear! (pilot-vpad (pilot e)))
      (let ((b (brain e))) (when b (setf (brain-press-left b) 0)))   ; a CPU lets go of what it held (a rush's O)
      (to-idle e 0)))
  (emit :reset))

;;; ---------------------------------------------------------------- Rukia's cold gauge (docs/DUEL_RUKIA.md §4)
(defun temp-step (e f g kit)
  "A :temp kit meter per step: the cold C (rules TEMP-NEXT) cools while she guards (:guard / :guard-hit; at absolute zero,
where the ward is always up, bracing: U held while free, which drains the guard gauge *ZERO-BRACE-DRAIN* per second and
ends in the CRACK when it runs out) and warms at the form's :warm otherwise. The THAW lock (GAUGES-METER-IDLE frames
after a CRACK) stops the cooling. The band (the form, rules TEMP-BAND-AT) follows C only while she is free, so a combo
(a string and everything chained to it) or a special finishes in the band it started in, and the band then re-resolves
from what is left (an overdrawn -273 combo at C 0 lands at -18)."
  (let* ((st (fighter-state f)) (free (member st '(:idle :guard :run))) (lock (gauges-meter-idle g))
         (brace (and free (passive-p e :ward) (not (gauges-guardless g)) (vpad-down (pilot-vpad (pilot e)) :guard)))
         (guarding (and (zerop lock) (or (member st '(:guard :guard-hit)) brace))))
    (when (plusp lock) (setf (gauges-meter-idle g) (1- lock)))
    (setf (gauges-meter g) (f32 (temp-next (gauges-meter g) guarding (kit-warm kit))))
    (if (and brace (drain-guard e (/ *zero-brace-drain* 60.0) :brace))
        (ward-drop e)                                   ; braced on credit until the gauge ran out: the CRACK
        (let ((band (temp-band-at (gauges-meter g) (fighter-form f) st)))   ; locked while she is in a combo
          (unless (eq band (fighter-form f))
            (set-form e band)
            (emit :sfx :frost-tick e))))))

;;; ---------------------------------------------------------------- gauges per step
(defun nome-step (e f g m)
  "A meter with a :ladder (Nozarashi's NOME, meter M): only while he is free (idle, walk, guard, run: never under
a string), the rung NOME asks for (LADDER-RUNG, several steps at once), which is his form; then the rung's drain
(METER-DRAIN; the rung is read before the drain, so a gain to exactly 100 is cup 3 on the first free frame)."
  (let* ((ladder (getf m :ladder)) (i (or (position (fighter-form f) ladder :key #'first) 0)))
    (when (member (fighter-state f) '(:idle :guard :run))
      (let ((j (ladder-rung (gauges-meter g) i ladder)))
        (unless (= i j)
          (set-form e (first (nth j ladder)))
          (emit :rung e (> j i))
          (setf i j))))
    (let ((r (nth i ladder)))
      (setf (gauges-meter g) (f32 (meter-drain (gauges-meter g) (second r) (third r) (gauges-meter-idle g)))
            (gauges-meter-idle g) (min 9999 (1+ (gauges-meter-idle g)))))))


(defun gauge-system ()
  "Regen (Reiatsu; flash-step and the guard gauge after their delays: a full guard gauge ends
guardless), timed forms (burn, drain, end), the meter's full form (Hellfire), EVOLUTION. GUARD HOLD: one
guarding test (:guard / :guard-hit, or Bankai West's ward, not guardless) gates both the guard gauge's refill and its
delay counter (frozen): West never refills."
  (do-entities (e (f fighter) (g gauges))
    (let* ((kit (fighter-kit f))
           (guarding (and (or (member (fighter-state f) '(:guard :guard-hit)) (passive-p e :ward)) (not (gauges-guardless g)))))
      (setf (gauges-reiatsu g) (f32 (gauge-add (gauges-reiatsu g) (reiatsu-gain 0 0 1) *reiatsu-max*)))
      (if (gauges-burst g)
          (burst-step e g)                               ; a burst: the gauge drains, no regen
          (setf (gauges-fs g) (f32 (fs-regen (gauges-fs g) (gauges-fs-idle g)))
                (gauges-fs-idle g) (min 9999 (1+ (gauges-fs-idle g)))))
      (when (plusp (gauges-awake-regen g))                ; the awakening's regen (overlaps a burst)
        (decf (gauges-awake-regen g))
        (white-regen! g (incf (gauges-awake-t g))))
      (setf (gauges-gg g) (f32 (gg-regen (gauges-gg g) (gauges-gg-idle g) (gauges-guardless g) guarding
                                         (eq (gauges-burst g) :blue) (kit-gg-regen kit))))
      (setf (gauges-gg-idle g) (gg-idle-next (gauges-gg-idle g) guarding))
      (setf (gauges-stun g) (f32 (stun-decay (gauges-stun g) (gauges-stun-idle g)))   ; the hidden stun's decay
            (gauges-stun-idle g) (min 9999 (1+ (gauges-stun-idle g))))
      (when (and (gauges-guardless g) (>= (gauges-gg g) *gg-max*))
        (setf (gauges-guardless g) nil)
        (emit :guard-back e)
        (clog "~a GUARD BACK" (side-name e)))
      (when (> (fighter-combo-dmg f) 0)                  ; the combo's damage shows until he is up again
        (unless (member (fighter-state f) '(:stun :air :down :wakeup :guard-hit)) (setf (fighter-combo-dmg f) 0)))
      (when (plusp (gauges-form-left g))
        (let ((burn (kit-burn kit)))
          (when (plusp burn)
            (setf (gauges-reishi g) (burn (gauges-reishi g) (burn-amount (gauges-reishi-max g) burn (gauges-burn-step g)))))
          (incf (gauges-burn-step g))
          (when (zerop (decf (gauges-form-left g)))
            (set-form e (kit-inherit kit)))))
      (when (kit-pips kit) (arm-step e f g))
      (let ((h (kit-hook kit :tick))) (when h (funcall h e f g)))   ; the form's own per-step mechanics (a meter, a cut)
      (when (getf (kit-meter kit) :temp) (temp-step e f g kit))
      (let ((m (kit-meter kit)))
        (when (getf m :ladder) (nome-step e f g m))
        (when (and m (zerop (gauges-form-left g)) (>= (gauges-meter g) (getf m :max)) (getf m :full-form))
          (setf (gauges-meter g) 0f0)                    ; the bar now shows the form's timer
          (set-form e (getf m :full-form))
          (emit :hellfire e)))
      (when (and (not (gauges-awakened g)) (not (gauges-evolution g)) (>= (gauges-awaken g) *awaken-max*))
        (setf (gauges-evolution g) t)
        (when (minusp (gauges-evo-t g)) (setf (gauges-evo-t g) *match-tick*))
        (emit :evolution e)
        (clog "~a EVOLUTION" (side-name e))))))
