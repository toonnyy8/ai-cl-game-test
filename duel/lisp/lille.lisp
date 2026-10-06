;;;; lille.lisp — LILLE BARRO (Schutzstaffel, TYBW), docs/duel/DUEL_LILLE.md: his moves (DEFMOVE) and his six forms
;;;; (DEFKIT): :base 万物貫通 THE X-AXIS (a sniper: L is the shooting stance 狙撃構え SOGEKI-GAMAE, after Ichigo's
;;;; TSUKIMACHI: a quick or a charged X-axis shot through guard, the leaping triple shot HOSHA, the backstep shot TAISHA,
;;;; the HIRENKYAKU dash; the left eye's
;;;; three openings on U), the awakening 神の裁き JILLIEL in two modes L switches between with the flash-step dash 転身
;;;; TENSHIN: 遠 EN (:jilliel, ranged: J / K / SP1 walk and lay X-axis traces, materialised by the switch) and 近 KIN
;;;; (:jilliel-kin, melee: the wing-blade strings), U in either the intangible stance (:jilliel-mujittai /
;;;; :jilliel-kin-mujittai, Yamamoto's West with the :intangible flag), and the second awakening, the owl 真の姿 (:shin,
;;;; P with <= 4 Konpaku in any Jilliel form: Kenpachi's Bankai path with the kit's :bankai-ok; decision 16). Everything of
;;;; his is here (the user's code layout, 2026-09-28): the knobs, the pure rules (host-tested), the kits, his per-side state
;;;; (reset with every match), the kit hooks (kit.lisp KIT-HOOK: :tick :ok :hit :struck :bankai-ok :draw), his hazards'
;;;; hook, the CPU, the debug range 79000-79999, the pacing log and the cinematics. The looks, bodies, clips and props are
;;;; lille-art.lisp's (the traces' floor look is here: LB-TRACE-LOOK). Plain CL above the hooks: the host rules test loads it.
(in-package :duel)

;;; ================================================================ knobs (docs/duel/DUEL_LILLE.md §4-§6, §13)
(defparameter *walk-lille* 3.4 "Walk m/s, the base form (design 2026-10-06).")
(defparameter *run-lille* 8.5 "Run m/s, the base form (design 2026-10-06).")
(defparameter *lille-mult* 1.3
  "Damage dealt x, the base form: 1.0 -> 1.3 (gate 2026-10-06, batch 4: §13's first \"too little\" knob; Lille won 16 / 100 of
his cross pairings at seeds 1-20, 24 / 100 after; DUEL_LILLE \"Measured: batch 4\").")
(defparameter *lille-taken* 1.0 "Damage taken x, the base form (design 2026-10-06).")
(defparameter *walk-jilliel* 3.0 "Walk m/s, JILLIEL (design 2026-10-06, §5.1).")
(defparameter *run-jilliel* 8.0 "Run m/s, JILLIEL (design 2026-10-06).")
(defparameter *jilliel-mult* 1.0 "Damage dealt x, JILLIEL (design 2026-10-06).")
(defparameter *jilliel-taken* 1.1 "Damage taken x, JILLIEL: when he is solid, he is fragile (design 2026-10-06, §5.6).")
(defparameter *jilliel-gg-regen* 0.36
  "JILLIEL's guard gauge refill x (outside the stance; the stance never refills): 0.36 x 5.5 / s = 2.0 / s (design
2026-10-06; the user's decision 14, 「正常狀態防禦槽恢復量大減」).")
;; the owl (decision 36, 2026-10-06: 「請讓梟頭型態的系統設計完全與 Jilliel 對齊 … 與 Jilliel 的主要差異是具有更高的攻擊力、更高的
;; 軌跡命中回收比例與更優異的優勢幀。」, 「小」): Jilliel's system in four forms (EN :shin, KIN :shin-kin, their MUJITTAI), walking as
;; Jilliel's modes (its own 4.0 / 9.0 m/s, *WALK-SHIN* / *RUN-SHIN*, went with it)
(defparameter *shin-mult* 1.1
  "Damage dealt x, the owl (design 2026-10-06: 1.2; decision 36, 2026-10-06, the user picked 「小」: 1.2 -> 1.1, Jilliel's
1.0 + a small step).")
(defparameter *shin-taken* 1.1
  "Damage taken x, the owl (design 2026-10-06: 1.0; decision 36, 2026-10-06: Jilliel's 1.1, the owl runs Jilliel's
system: §23.14 「taken x1.1」).")
(defparameter *shin-adv* 1
  "The owl's frame advantage over Jilliel (decision 36, 2026-10-06, 「更優異的優勢幀」, 「小」): every owl J / K / SP is
this many frames shorter in its recovery (and its :adv-block this much higher), so +1 on hit and on block. The moves
carry the numbers (DEFMOVE takes literals); the host test checks them against Jilliel's.")

;; the left eye (§4.1; decisions 7, 13)
(defparameter *lb-eyes* 3 "The eye's pips: full at the start, never refilled in the match (design 2026-10-06; decision 7).")
(defparameter *lb-eye-rest* 10
  "A U press opens the eye only after U was up this many frames (a deliberate tap; design 2026-10-06, decision 13).")
(defparameter *lb-eye-lead* 8
  "... while an opponent hit window is active now or within this many frames and touches him (the perfect-Hoho test with
a shorter look-ahead; design 2026-10-06, decision 13).")
(defparameter *lb-eye-phase* 16 "Frames he is intangible after the eye opens (FIGHTER-INVULN; design 2026-10-06).")

;; the X-axis shot (§4.3; decisions 10, 12): since the rework (decision 17, §22.1) the stance's L, locked on the press
(defparameter *lb-aim-track* 60.0 "Degrees / s he turns in the shooting stance (design 2026-10-06; the Signature rate).")
(defparameter *lb-lock-min* 10
  "The shot fires this many frames after its lock (design 2026-10-06; decision 12: the visible lock; the rework's stance L
locks on the press and fires 10 f later, §22.1).")
(defparameter *lb-x-near* 4.0 "Distance damage: the minimum at or under this many metres (design 2026-10-06; decision 10)...")
(defparameter *lb-x-far* 20.0 "... the maximum at or beyond this many (design 2026-10-06).")
(defparameter *lb-x-min* 40 "The shot's damage at *LB-X-NEAR* (design 2026-10-06; the stance's quick shot: flat, §22.1).")
(defparameter *lb-x-max* 120 "The shot's damage at *LB-X-FAR* (design 2026-10-06; §13: 120 -> 100 if he wins too much).")
(defparameter *lb-x-chip* 0.15 "Through guard: the fraction of a blocked X-axis hit that goes through as chip (design 2026-10-06; decision 2).")
(defparameter *lb-x-guard* 30 "Through guard: the guard gauge a blocked shot drains (4 crush a full gauge; design 2026-10-06; decision 2).")
(defparameter *lb-far-kb* 12.0 "A shot that hits from this many metres knocks back 2.0 m, not 1.0 (design 2026-10-06).")

;; L 狙撃構え SOGEKI-GAMAE, the shooting stance (§22.1, decision 17; Ichigo's TSUKIMACHI pattern)
(defparameter *lb-kamae-up* 6 "The stance's frame where it is up: the follow-ups fire from here (rework R, 2026-10-06).")
(defparameter *lb-kamae-tap* 30 "Frames the stance holds past its f6 on a tap of L (rework R, 2026-10-06) ...")
(defparameter *lb-kamae-max* 90 "... and at most while L is held; then R 14 (rework R, 2026-10-06).")
(defparameter *lb-charge-f* 24
  "The stance's L is the charged shot (the distance curve) after this many frames in the stance, the dash's included;
before, the quick shot (*LB-X-MIN* flat) (rework R, 2026-10-06; decision 17).")
(defparameter *lb-kamae-dash* 3.5 "HIRENKYAKU (the stance's Step): metres over its 12 f (rework R, 2026-10-06).")
(defparameter *lb-kamae-dash-fs* 10.0 "... its flash-step price, once per stance (rework R, 2026-10-06).")
;; the stance's J / K after the second playtest (§23.1, decisions 21, 22; 「L 射擊架勢接 J 改成向前跳飛並在空中射出連射三發短程子彈
;; （擊中後可與 j/k 串成 combo）；接 K 則會向後拉開距離打出一發中程子彈」)
(defparameter *lb-jilliel-lift* 0.5
  "Jilliel (EN, KIN and their stances) is drawn this many metres up in every clip (kit :lift; a look). His own clips
were posed at root :u 0.5 and the shared walk / run / step / reaction clips at 0, so he sank 0.5 m whenever he moved (the
user, 2026-10-06: 「覺醒狀態移動的時候整個角色很明顯下沉，請修改回正常高度」); the float moved out of his clips to here.")
(defparameter *lb-owl-lift* 0.35
  "The owl's 遠 EN (:shin and its MUJITTAI) is drawn this many metres up (kit :lift; a look), its ㄇ legs folded up under the
column; KIN (:shin-kin and its MUJITTAI) stands on them (lift 0). Decision 38 (the user, 2026-10-06: 「梟頭模式幫我設計更明顯的
遠程和近戰視覺差異，目前看不出『遠程模式翼張開、站直，近戰模式翼往後收、身體前傾』這樣的設計。」): 0 (every owl form on its legs) -> 0.35
(the design said Jilliel EN's 0.5; the owl is a metre taller, so 0.5 put its head under the HUD in the behind and side
cameras; with the legs tucked its lowest point still clears the floor by ~0.8 m). The owl's own clips stand at root :u ~0,
so nothing double-lifts; TENSHIN's clips (lille-art.lisp) step their root by this at the form's frame.")
(defparameter *lb-hosha-leap* 5.0
  "J 跳射 HOSHA: the forward leap, metres over its frames 0-14 (*LB-HOSHA-LEAP-F*); it stops *LUNGE-STOP* short of him
(round 2, 2026-10-06: 3.0; the user's third playtest 2026-10-06 「L > J 前跳距離加長&射程縮短」: 3.0 -> 5.0; REIKYORI's 2.0 m
lunge before).")
(defparameter *lb-hosha-leap-f* 14 "... over this many frames (round 2, 2026-10-06).")
(defparameter *lb-hosha-stun* 30
  "HOSHA's first two bullets flinch this many frames (the :stun override; a flinch is 18): from the 1st bullet (f6) his
recovery's cancel (f16) + K1's startup (17) still lands inside it, a combo (round 2, 2026-10-06; the 3rd bullet staggers,
26).")
(defparameter *lb-taisha-slide* 3.0 "K 退射 TAISHA: the back-slide, metres over its frames 0-12 (round 2, 2026-10-06).")
(defparameter *lb-taisha-slide-f* 12 "... over this many frames; the line then locks (round 2, 2026-10-06).")

;; JILLIEL: 遠 EN and 近 KIN, L 転身 TENSHIN switches (§22.2, decision 18)
(defparameter *walk-kin* 3.8 "Walk m/s, JILLIEL KIN (the owl's legs; rework R, 2026-10-06).")
(defparameter *run-kin* 8.5 "Run m/s, JILLIEL KIN (rework R, 2026-10-06).")
(defparameter *lb-en-walk* 3.0 "EN: m/s the stick walks him through J / K / SP1 (facing kept on the opponent; rework R, 2026-10-06).")
(defparameter *lb-switch-in* 8.0
  "TENSHIN in (EN -> KIN): the dash at him, at most this many metres over *LB-SWITCH-F*, stopping *LB-SWITCH-STOP* short
(round 2, 2026-10-06, decision 25 「大幅提升變換戰型後的衝刺距離」: 3.5 before, both ways).")
(defparameter *lb-switch-stop* 1.5 "... this many metres short of him (KIN's J1 reaches 1.6; round 2, 2026-10-06).")
(defparameter *lb-switch-out* 7.0 "TENSHIN out (KIN -> EN): the dash away, metres over *LB-SWITCH-F* (round 2, 2026-10-06; 3.5 before).")
(defparameter *lb-switch-f* 14
  "TENSHIN's dash frames (12 before): from its end his J / K cancel the recovery (round 2, 2026-10-06).")
(defparameter *lb-switch-windup* 16
  "TENSHIN in (EN -> KIN) from EN's neutral (idle, walk, run, MUJITTAI): this many frames of a visible, hittable wind-up
before the traces materialise and the dash starts (round 2, 2026-10-06, decision 30: 「0.1-0.15 s」, 8; decision 34,
2026-10-06, the user: 「遠程模式從中立按 L 的前搖的前搖增加到 16 f」: 8 -> 16) ...")
(defparameter *lb-switch-windup-c* 2
  "... and this many as a cancel out of an EN attack (J / K / SP1 / SP2: the move entered at its f14); KIN -> EN has none
(round 2, decision 30; kept by decision 34). TENSHIN has no cooldown (decision 34: 「L 切換戰型取消冷卻限制」; 30 f before).")
(defparameter *lb-switch-fs* 10.0
  "TENSHIN out (KIN -> EN): its flash-step price; refused without it (rework R, 2026-10-06). TENSHIN in (EN -> KIN) is
free (decision 34, 2026-10-06: 「從『遠』變『近』不消耗閃步量表」; 10 before, both ways).")
(defparameter *lb-trace-fs* 3.0
  "EN's J / K: the flash step each trace line laid costs (a J 3, a K's fan of three 9); a line is laid only while this
much is left, checked line by line (the swing still plays); SP1 / SP2's traces are free (decision 34, 2026-10-06, the
user: 「遠程 J/K 每條軌跡消耗 3 點閃步量表」; free before).")
(defparameter *lb-nick-dmg* 1 "A trace's laying shot: its damage (decision 39, 2026-10-06; the user's 1).")
(defparameter *lb-nick-stun* 10 "... the light flinch it holds, frames (decision 39: 「輕微硬直」; the lead's number).")
(defparameter *lb-nick-guard* 2 "... the guard gauge a blocked one drains (decision 39: guardable; the lead's number).")
(defparameter *lb-trace-refund-block* 2.0
  "... and a guarded one this much (the user, 2026-10-06: 「擋下回收 2」; it was nothing).")
(defparameter *lb-trace-refund* 4.0
  "A materialised trace that hits a fighter gives him this much flash step back (a K fan's hit group hits once: once;
a guarded one nothing; kept at the max, none during a burst: PAY-GAUGES) (decision 34, 2026-10-06, the user: 「每打中一條
軌跡會額外回收 2 點閃步量表」; 2 -> 4 the same day: 「我希望能將軌跡命中回收量上調到 4」).")
(defparameter *shin-trace-refund* 5.0
  "The owl's materialised trace that hits gives this much flash step back (decision 36, 2026-10-06, 「更高的軌跡命中回收比例」,
「小」: Jilliel's *LB-TRACE-REFUND* 4 + 1) ...")
(defparameter *shin-trace-refund-block* 2.0 "... and a guarded one this much (decision 36: Jilliel's 2, kept).")
(defparameter *lb-dash-iframes* 9
  "Both flash-step dashes (HIRENKYAKU in the stance, TENSHIN) are invulnerable on their frames 0-8 (rework R, 2026-10-06;
TSUKIWATARI's).")
(defparameter *lb-trace-max* 16
  "EN's traces: at most this many live; a 17th drops the oldest (round 2, 2026-10-06, decision 29: 8 -> 16; rework R's
「最多 8 條」 before).")
(defparameter *lb-trace-fan* 6.0 "EN K's fan: three traces at -this, 0, +this degrees (rework R, 2026-10-06).")
(defparameter *lb-trace-len* 31.0 "A trace's length, metres from 0.6 m ahead of where it was laid (the arena is 30 m across).")
(defparameter *lb-trace-r* 0.6 "A trace's radius, metres (rework R, 2026-10-06) ...")
(defparameter *lb-trace-r-thick* 1.2 "... EN SP2's thick trace (rework R, 2026-10-06; 「遠程模式留粗軌道」).")
(defparameter *lb-trace-dmg* '(:j 30 :k 24 :sp1 30 :sp2 180)
  "A materialised trace's damage by what laid it, before *JILLIEL-MULT* (rework R, 2026-10-06, §22.2).")
(defparameter *lb-trace-guard* '(:j 18 :k 18 :sp1 18 :sp2 45)
  "... and the guard gauge it drains when blocked (the X-axis rule: chip *LB-X-CHIP*; rework R, 2026-10-06).")
(defparameter *lb-trace-stun* 26
  "A materialised trace (not SP2's) staggers this many frames with no knockback: >= TENSHIN's dash (*LB-SWITCH-F* 14) + a
J1's startup (8) + a margin (4), so a trace hit -> TENSHIN in -> J is a combo (round 2, 2026-10-06, decision 25; it
knocked back 1.0 m before).")
(defparameter *lb-trace-life* 1000000 "Frames a trace lasts unmaterialised: kept until his next switch (a reset clears it).")

;; the owl (§6)
(defparameter *lb-sabaki-from* 1.0 "SABAKI NO KOMYO's ground line starts this many metres ahead (design 2026-10-06)...")
(defparameter *lb-sabaki-to* 18.0 "... and runs to this many (design 2026-10-06).")
(defparameter *lb-sabaki-speed* 40.0 "... erupting outward at this many m/s (design 2026-10-06).")
(defparameter *lb-sabaki-life* 24 "Frames each point of the line burns (0.4 s; design 2026-10-06).")
(defparameter *lb-sabaki-width* 0.6 "The line's width, metres (design 2026-10-06).")
(defparameter *lb-misuji-fan* 20.0 "MISUJI's lines: -this, 0, +this degrees (design 2026-10-06).")
(defparameter *lb-reflect-hoho* '(48 59)
  "Trompete's reflect by a perfect Hoho started on these Trompete frames (design 2026-10-06, decision 9; f60 can't dodge
the beam's first frame: Built, deviations).")
(defparameter *lb-reflect-guard* '(2 10)
  "... or by a guard whose FIGHTER-GUARD-T at the end of Trompete's f59 is in this range (a press on f50-f58; design
2026-10-06, decision 9).")
(defparameter *lb-reflect-k* 0.5 "The reflect: he takes this share of Trompete's damage, x his form's damage (design 2026-10-06).")
(defparameter *lb-reflect-stun* 60 "... and staggers this many frames (design 2026-10-06).")

;;; ================================================================ rules (pure: host-tested)
(defun lb-x-damage (d)
  "The X-axis shot's damage at D metres (centre to centre at the fire frame), before the form's multiplier: *LB-X-MIN*
at <= *LB-X-NEAR*, rising linearly to *LB-X-MAX* at >= *LB-X-FAR* (decision 10)."
  (let ((k (max 0.0 (min 1.0 (/ (- d *lb-x-near*) (- *lb-x-far* *lb-x-near*))))))
    (round (+ *lb-x-min* (* k (- *lb-x-max* *lb-x-min*))))))
(defun lb-x-bonus (d) "What the shot's hit window (*LB-X-MIN*) gets added at D metres (FIGHTER-DMG-BONUS)." (- (lb-x-damage d) *lb-x-min*))
(defun lb-eye-window-p (sf from to)
  "An opponent hit window [FROM, TO) of his move at frame SF is active, or becomes active within *LB-EYE-LEAD* frames
(THREAT-WINDOW-P's eye version)."
  (and (< sf to) (<= (- from sf) *lb-eye-lead*)))
(defun lb-eye-state-p (state sf)
  "May a U tap open the eye from STATE (SF its frame): idle, walk, guard, run and a Step's recovery; never a move, a reaction
or blockstun."
  (or (member state '(:idle :guard :run))
      (and (eq state :step) (> sf (second *step-iframes*)))))
(defun lb-eye-tap-p (rest pips state sf)
  "Does a U press after U rested REST frames open the eye (PIPS left, STATE / SF)? (The threat is the shell's test.)"
  (and (>= rest *lb-eye-rest*) (plusp pips) (lb-eye-state-p state sf) t))
(defun lb-eye-open (pips awakened)
  "One opening of PIPS: values the pips left and whether it fills the awakening gauge (the third opening, unless
AWAKENED already; decision 7)."
  (let ((n (max 0 (1- pips)))) (values n (and (zerop n) (plusp pips) (not awakened)))))
(defun lb-reflect-hoho-p (start)
  "Is a perfect Hoho started on Trompete frame START a reflect (*LB-REFLECT-HOHO*)?"
  (<= (first *lb-reflect-hoho*) start (second *lb-reflect-hoho*)))
(defun lb-reflect-guard-p (guard-t)
  "Is a guard with FIGHTER-GUARD-T = GUARD-T at the end of Trompete's f59 a reflect (*LB-REFLECT-GUARD*: a press f50-f58)?"
  (<= (first *lb-reflect-guard*) guard-t (second *lb-reflect-guard*)))
(defun lb-reflect-damage (dmg mult) "What a reflected Trompete of DMG deals him, MULT his form's damage x." (round (* *lb-reflect-k* dmg mult)))
(defun lb-sabaki-span (age)
  "The burning part of a SABAKI line AGE frames after it erupted: values from to (metres ahead; FROM = TO: none yet)."
  (let* ((front (min *lb-sabaki-to* (+ *lb-sabaki-from* (* *lb-sabaki-speed* (/ age 60.0)))))
         (tail (max *lb-sabaki-from* (+ *lb-sabaki-from* (* *lb-sabaki-speed* (/ (- age *lb-sabaki-life*) 60.0))))))
    (values (min tail front) front)))
(defun lb-sabaki-frames ()
  "A SABAKI line's life: its eruption to *LB-SABAKI-TO* and the last point's burn."
  (+ (ceiling (* 60 (- *lb-sabaki-to* *lb-sabaki-from*)) *lb-sabaki-speed*) *lb-sabaki-life*))
;; the rework (decisions 16-18, §22)
(defun lb-kamae-charged-p (charge)
  "Is the stance's L the charged shot after CHARGE frames in the stance (the dash's included): >= *LB-CHARGE-F*?"
  (>= charge *lb-charge-f*))
(defun lb-k-shot-damage (charge d)
  "The stance's L at D metres after CHARGE frames, before the form's multiplier: the quick shot *LB-X-MIN* flat, the
charged one the distance curve (LB-X-DAMAGE; decision 17)."
  (if (lb-kamae-charged-p charge) (lb-x-damage d) *lb-x-min*))
(defun lb-kamae-hold-over-p (sf held)
  "Does the stance (move frame SF, L HELD) end its hold now: past its tap (*LB-KAMAE-TAP* after f6) with L up, before
the held maximum? (Then it jumps to its recovery, R 14: TSUKIMACHI's rule.)"
  (and (<= (+ *lb-kamae-up* *lb-kamae-tap*) sf) (< sf (+ *lb-kamae-up* *lb-kamae-max*)) (not held)))
(defun lb-jilliel-form-p (form) "Is FORM one of Jilliel's four (EN, KIN and their stances)?"
  (and (member form '(:jilliel :jilliel-mujittai :jilliel-kin :jilliel-kin-mujittai)) t))
(defun lb-owl-form-p (form) "Is FORM one of the owl's four (EN :shin, KIN :shin-kin and their stances; decision 36)?"
  (and (member form '(:shin :shin-mujittai :shin-kin :shin-kin-mujittai)) t))
(defun lb-mode-form-p (form)
  "Is FORM one of the eight that run Jilliel's system (EN / KIN, MUJITTAI, TENSHIN, the traces): Jilliel's four or the
owl's (decision 36)?"
  (or (lb-jilliel-form-p form) (lb-owl-form-p form)))
(defun lb-kin-form-p (form) "Is FORM a KIN (Jilliel's or the owl's, or its stance)?"
  (and (member form '(:jilliel-kin :jilliel-kin-mujittai :shin-kin :shin-kin-mujittai)) t))
(defun lb-en-form-p (form) "Is FORM an EN (Jilliel's or the owl's, or its stance)?"
  (and (member form '(:jilliel :jilliel-mujittai :shin :shin-mujittai)) t))
(defun lb-stance-form-p (form) "Is FORM a MUJITTAI (the four stances: Jilliel's and the owl's EN / KIN)?"
  (and (member form '(:jilliel-mujittai :jilliel-kin-mujittai :shin-mujittai :shin-kin-mujittai)) t))
(defun lb-revive-ok-p (form state konpaku)
  "May P revive him into the owl (decision 16): any Jilliel FORM, free (STATE idle / guard: the stance included), with at
most *BANKAI-KONPAKU* of his own KONPAKU (Kenpachi's rule exactly; no beheading needed)."
  (and (lb-jilliel-form-p form) (member state '(:idle :guard)) (<= konpaku *bankai-konpaku*) t))
(defun lb-switch-target (form)
  "The form TENSHIN switches FORM to: EN (or its stance) -> KIN, KIN (or its stance) -> EN; Jilliel's pair or the owl's
(decision 36)."
  (if (lb-owl-form-p form)
      (if (lb-kin-form-p form) :shin :shin-kin)
      (if (lb-kin-form-p form) :jilliel :jilliel-kin)))
(defun lb-hoho-target (form)
  "Decision 37 (2026-10-06, the user: 「覺醒後在遠攻狀態使用閃步就會自動切換成近戰狀態」, then 「只有 Hoho 會切換」): the form a
Hoho starting in FORM switches him to: an EN (Jilliel's or the owl's) -> its pair's KIN, its MUJITTAI -> the KIN MUJITTAI;
NIL for every other form. A Step (a tap, a run's hop, a back-step) doesn't. No price (the Hoho pays its own flash step),
no materialise (the traces wait for L)."
  (case form
    (:jilliel :jilliel-kin) (:jilliel-mujittai :jilliel-kin-mujittai)
    (:shin :shin-kin) (:shin-mujittai :shin-kin-mujittai)))
(defun lb-switch-price (form)
  "The flash step TENSHIN costs from FORM: out of KIN (or its stance) *LB-SWITCH-FS*; in from EN (or its stance) none
(decision 34)."
  (if (lb-kin-form-p form) *lb-switch-fs* 0.0))
(defun lb-switch-ok-p (form fs)
  "Has he, in FORM with FS flash step, what TENSHIN costs (LB-SWITCH-PRICE)? EN -> KIN always (decision 34)."
  (>= fs (lb-switch-price form)))
(defun lb-trace-cost (src) "The flash step one trace line laid by SRC costs: EN's J / K *LB-TRACE-FS*, SP1 / SP2 none (decision 34)."
  (if (member src '(:j :k)) *lb-trace-fs* 0.0))
(defun lb-trace-pay (fs src n)
  "N trace lines of SRC with FS flash step, paid line by line (one is laid only while its LB-TRACE-COST is left): values
how many are laid and the flash step left (decision 34: a K fan with 7 lays two, with 2 none)."
  (let ((c (lb-trace-cost src)) (laid 0))
    (dotimes (i n) (when (>= fs c) (setf fs (- fs c)) (incf laid)))
    (values laid fs)))
(defun lb-sp2-sealed-p (command form sealed)
  "Is COMMAND refused in FORM because the halo is SEALED: the owl's SP2, in EN (the thick trace) and in KIN (Trompete)
alike (decisions 9, 36: 「保留反射與封印」)?"
  (and (eq command :sp2) (lb-owl-form-p form) sealed t))
(defun lb-en-dry-p (fs)
  "Is EN's J / K refused at FS flash step: under *LB-TRACE-FS* (decision 35: no line to pay, no swing)?"
  (< fs *lb-trace-fs*))
(defun lb-trace-refund (contact &optional owl)
  "The flash step a materialised trace's CONTACT gives him back: *LB-TRACE-REFUND* on a hit, *LB-TRACE-REFUND-BLOCK* when
guarded (decision 34; a K fan is one hit group, so it is asked once); the OWL's *SHIN-TRACE-REFUND* /
*SHIN-TRACE-REFUND-BLOCK* (decision 36)."
  (case contact
    (:hit (if owl *shin-trace-refund* *lb-trace-refund*))
    (:block (if owl *shin-trace-refund-block* *lb-trace-refund-block*))
    (t 0.0)))
(defun lb-trace-pick (fans laid)
  "The yaw offsets (FANS, LB-TRACE-FANS order) of the LAID lines when not all are paid: the middle one first, then the
fan's sides in order; laid in FANS' order."
  (if (>= laid (length fans))
      fans
      (let ((want (subseq (stable-sort (copy-list fans) #'< :key #'abs) 0 laid)))
        (remove-if-not (lambda (a) (member a want)) fans))))
(defun lb-trace-fans (kind)
  "The yaw offsets (degrees) of the traces one EN line of KIND lays: a K a fan of three, else one."
  (if (eq kind :k) (list (- *lb-trace-fan*) 0.0 *lb-trace-fan*) (list 0.0)))
(defun lb-trace-drop-p (live) "Must a new trace drop the oldest first: LIVE traces already at *LB-TRACE-MAX*?" (>= live *lb-trace-max*))
(defun lb-trace-oldest (ids) "The oldest of live trace IDS (the smallest: they count up per side), or NIL." (and ids (reduce #'min ids)))
(defun lb-trace-lay (ids id)
  "The FIFO of live trace IDS (oldest first) after trace ID is laid: values the new list and the id dropped (the oldest,
when *LB-TRACE-MAX* were live) or NIL. (The sim keeps its traces as hazards: LB-LAY-TRACE drops by LB-TRACE-OLDEST.)"
  (let ((drop (and (lb-trace-drop-p (length ids)) (lb-trace-oldest ids))))
    (values (append (remove drop ids) (list id)) drop)))
(defun lb-nick-hitwin ()
  "The shot a trace's laying fires along it (decision 39, the user 2026-10-06: 「覺醒後在遠程狀態產生軌道時，軌道上會對敵人造成傷害為
1 的射擊傷害」, then 「輕微硬直但可防禦」): *LB-NICK-DMG* (1), a flinch held *LB-NICK-STUN*, no hitstop, guardable as a
plain ranged hit (no chip, *LB-NICK-GUARD* drained; not the X-Axis), :ranged (no parry catches it)."
  (make-hitwin :dmg *lb-nick-dmg* :react :flinch :stun *lb-nick-stun* :hs 0 :guard *lb-nick-guard* :flags (list :ranged)))
(defun lb-trace-hitwin (kind mult)
  "The hit a materialised trace of KIND deals (one 2-frame window, once): *LB-TRACE-DMG* x MULT, through guard (the
X-axis rule: chip *LB-X-CHIP*, drain *LB-TRACE-GUARD*), :ranged :x-axis :uncatchable; a stagger of *LB-TRACE-STUN* in
place (round 2: TENSHIN in then J combos), SP2's a knockback."
  (let ((sp2 (eq kind :sp2)))
    (make-hitwin :dmg (round (* (getf *lb-trace-dmg* kind 30) mult)) :react (if sp2 :knockback :stagger) :kb (if sp2 2.0 0.0)
                 :stun (if sp2 nil *lb-trace-stun*)
                 :hs (if sp2 *hitstop-heavy* *hitstop-light*) :chip *lb-x-chip* :guard (getf *lb-trace-guard* kind 18)
                 :flags (list :ranged :x-axis :uncatchable))))

;;; ================================================================ base 万物貫通 THE X-AXIS (§4)
;;; the J / K strings (docs/duel/DUEL_STRINGS.md §2.1 budget; the lightest in the roster): the plank (the butt) swung at
;;; close range for J1 / J2, the muzzle cross for J3 and every K. Every reach is where the art strikes (lille-art.lisp; the
;;; host FK test: the plank at a negative weapon-length point, the muzzle at the weapon tip)
(defmove :lb-j1 :kind :quick :clip :lb-q1 :startup 8 :active 3 :recovery 12 :dmg 26 :adv-block -2
  :reach 1.45 :arc 100 :on-hit :flinch)  ; 床尾打 SHOBI-UCHI: the plank swung up from the hip (dmg 22 -> 26: gate 2026-10-06, batch 4, §13 "too little")
(defmove :lb-j2 :kind :quick :clip :lb-q2 :startup 7 :active 3 :recovery 13 :dmg 22 :adv-block -2
  :reach 1.45 :arc 110 :on-hit :flinch)                              ; 返し KAESHI: the plank's backhand
(defmove :lb-j3 :kind :quick :clip :lb-jab :startup 9 :active 3 :recovery 18 :dmg 28 :adv-block -4
  :reach 1.6 :arc 70 :on-hit :stagger :flags (:ender))               ; 銃口突 JUKO-TSUKI: the muzzle cross jabbed
(defmove :lb-k1 :kind :flash :clip :lb-f1 :startup 17 :active 4 :recovery 21 :dmg 48 :adv-block -3
  :reach 2.05 :arc 150 :on-hit :stagger)                             ; 銃身薙 JUSHIN-NAGI: the barrel swept flat
(defmove :lb-k2 :kind :flash :clip :lb-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 48 :adv-block -3
  :reach 2.05 :arc 100 :on-hit :stagger)                             ; 振り下ろし FURIOROSHI: the barrel brought down
(defmove :lb-k3 :kind :flash :clip :lb-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 70 :adv-block -20
  :reach 2.15 :arc 60 :on-hit :crumple :flags (:ender))             ; 零距離 REI-KYORI: the muzzle pressed in, fired (melee)
(defmove-copy :lb-j2s :lb-j2)
(defmove-copy :lb-k2s :lb-k2)
;; L 狙撃構え SOGEKI-GAMAE, the shooting stance (§22.1, decision 17; Ichigo's TSUKIMACHI): Diagramm levelled, the grey aim
;; line drawn; up at f6, then held 30 f (90 while L is held), R 14; no defence (hit as neutral); turning 60 deg/s; planted.
;; From f6 the first L / J / K / Step (LB-KAMAE-TICK) fires the X-axis shot (quick, or charged after 24 f in the stance),
;; HOSHA, TAISHA or the HIRENKYAKU dash; the follow-ups are its non-button :strings (:kamae-l ...). L after a K link
;; opens it at f4 (the K-link copy), every branch combos. The dash comes back into the stance at f6 (the re-entry copy:
;; a fresh window, the charge kept), once per stance
(defmove :lb-kamae :kind :sig :clip :lb-kamae :startup 6 :active 0 :recovery 104 :track 60.0 :tick lb-kamae-tick
  :flags (:step-branch) :on-frame ((0 lb-kamae-enter)))
(defmove-copy :lb-kamae-k :lb-kamae :enter 4 :on-frame ((4 lb-kamae-enter)))
(defmove-copy :lb-kamae-re :lb-kamae :enter 6 :on-frame nil)
;; L 万物貫通 (the stance's L): locked on the press (jade, track 0), fires 10 f later (*LB-LOCK-MIN*: the visible lock), a
;; line 31 m long through guard (chip 15 %, drain 30), through KASA (:uncatchable); quick 40 flat, charged 40 + the
;; distance bonus (LB-K-FIRE)
(defmove :lb-k-shot :kind :sig :clip :lb-k-shot :callout "X-AXIS" :startup 10 :active 2 :recovery 26 :dmg 40 :adv-block -14
  :track 0 :vol (:cap 0.6 31.0 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *lb-x-chip* :guard *lb-x-guard*
  :flags (:ranged :x-axis :uncatchable) :on-frame ((0 lb-k-lock) (10 lb-k-fire)) :params (:lock 0 :bonus t))
;; J 跳射 HOSHA (round 2, §23.1, decision 21; REIKYORI's lunge before): a forward leap of 3 m over f0-14 (airborne look, the
;; hurt cylinder as ever, no iframes), turning 90 deg/s at him, three short bullets from the muzzle at f6 / f10 / f14: each
;; a line to 3.6 m (6.6 before the third playtest), 16, guardable (:ranged: no parry catches it; not the X-axis), its own window (three hits): flinches
;; held *LB-HOSHA-STUN*, the third a stagger; R 16 after he lands. On any bullet's hit his recovery (from f16) cancels into
;; J1 or K1, a combo (LB-LINK-TICK); a J / K pressed earlier is latched for it
(defmove :lb-k-j :kind :sig :clip :lb-k-hosha :callout "HOSHA" :startup 6 :active 10 :recovery 16 :dmg 16 :adv-block -8
  :guard 6 :track 90 :vol (:cap 0.6 3.0 1.2 0.25) :on-hit :flinch :hs *hitstop-light* :flags (:ranged)
  :hits ((6 8 :stun *lb-hosha-stun*) (10 12 :stun *lb-hosha-stun*) (14 16 :on-hit :stagger))
  :tick lb-hosha-tick :on-frame ((0 lb-hosha-leap) (6 lb-bullet) (10 lb-bullet) (14 lb-bullet)) :params (:link 16 :len 3.6))
;; K 退射 TAISHA (round 2, §23.1, decision 22; NAGIHARAI's sweep before): a back-slide of 3 m over f0-12 (turning 90 deg/s
;; at him, then the line locks), one bullet at f16: a 6 m line (12 before the third playtest, 「L > K 射程縮短」), 60 flat x his damage, through guard as the shot (:x-axis:
;; chip 15 %, drain 30), a stagger knocking back 1 m; R 24
(defmove :lb-k-k :kind :sig :clip :lb-k-taisha :callout "TAISHA" :startup 16 :active 2 :recovery 24 :dmg 60 :adv-block -14
  :track 0 :vol (:cap 0.6 6.0 1.2 0.3) :on-hit :stagger :kb 1.0 :chip *lb-x-chip* :guard *lb-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick lb-hiren-tick :on-frame ((0 lb-hiren-slide) (16 lb-taisha-fire))
  :params (:slide *lb-taisha-slide* :slide-f *lb-taisha-slide-f* :lock *lb-taisha-slide-f* :len 6.6))
;; Step 飛廉脚 HIRENKYAKU: 3.5 m in the stick direction (neutral: away from him) over 12 f, iframes f0-8, back in the stance
;; at f6 with the charge kept, its aim snapped onto him (LB-KAMAE-DASH, LB-KAMAE-BACK; round 2, decision 23)
(defmove :lb-k-dash :kind :sig :clip :lb-k-dash :startup 12 :active 0 :recovery 0 :tick lb-k-dash-tick
  :on-frame ((0 lb-kamae-dash) (11 lb-kamae-back)))
;; Shift+K SP1 三連 SANREN: three unaimed lines f12 / f22 / f32 (each 20 m, hits once), turning 90 deg/s between them
(defmove :lb-sanren :kind :sp :clip :lb-sanren :callout "SANREN" :startup 12 :active 22 :recovery 24 :dmg 30 :adv-block -14
  :track 90 :vol (:cap 0.6 20.0 1.2 0.25) :on-hit :flinch :kb 0.5 :chip *lb-x-chip* :guard 12
  :flags (:ranged :x-axis :uncatchable) :hits ((12 14) (22 24) (32 34)) :tick lb-sanren-tick
  :on-frame ((12 lb-line-shot) (22 lb-line-shot) (32 lb-line-shot)) :params (:len 20.0))
;; Shift+L SP2 飛廉脚 HIRENKYAKU: a 6 m back-slide over f0-14 (no iframes), then the X-axis shot at f20 from where he lands
(defmove :lb-hiren :kind :sp :clip :lb-hiren :callout "HIRENKYAKU" :startup 20 :active 2 :recovery 22 :dmg 40 :adv-block -14
  :track 0 :vol (:cap 0.6 31.0 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *lb-x-chip* :guard *lb-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick lb-hiren-tick :on-frame ((0 lb-hiren-slide) (20 lb-x-fire))
  :params (:bonus t :slide 6.0 :slide-f 14 :lock 14))
(defmove :lb-breaker :kind :breaker :clip :lb-breaker :clip-2 :lb-butt :callout "SHOBI-UCHI")
;; O 照準 SHOJUN, the Kikon module: the lane (Rukia's / Senjumaru's shape): aura 8, a 12 m lane, guardable (no :x-axis)
(defmove :lb-kikon :kind :kikon :clip :lb-aim :clip-2 :lb-fire :clip-s 4 :callout "BANBUTSU KANTSU" :cine lb-kikon-cine
  :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0 :vol (:cap 0.5 12.0 1.2 1.2)
  :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 lb-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))

;;; ================================================================ 神の裁き JILLIEL (§5)
;; the wing blades (the front pair: the rig's arms; the base budget, a little longer, a little heavier)
(defmove :lb-w-j1 :kind :quick :clip :lb-w-q1 :startup 8 :active 3 :recovery 12 :dmg 24 :adv-block -2
  :reach 1.6 :arc 110 :on-hit :flinch)                               ; 翼刃 YOKUJIN 1
(defmove :lb-w-j2 :kind :quick :clip :lb-w-q2 :startup 7 :active 3 :recovery 13 :dmg 24 :adv-block -2
  :reach 1.6 :arc 110 :on-hit :flinch)                               ; 翼刃 YOKUJIN 2
(defmove :lb-w-j3 :kind :quick :clip :lb-w-q3 :startup 9 :active 3 :recovery 18 :dmg 30 :adv-block -4
  :reach 1.7 :arc 120 :on-hit :stagger :flags (:ender))              ; 翼刃 YOKUJIN 3
(defmove :lb-w-k1 :kind :flash :clip :lb-w-f1 :startup 17 :active 4 :recovery 21 :dmg 50 :adv-block -3
  :reach 2.2 :arc 150 :on-hit :stagger)                              ; 双翼 SOYOKU 1
(defmove :lb-w-k2 :kind :flash :clip :lb-w-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 50 :adv-block -3
  :reach 2.2 :arc 110 :on-hit :stagger)                              ; 双翼 SOYOKU 2
(defmove :lb-w-k3 :kind :flash :clip :lb-w-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 72 :adv-block -20
  :reach 2.3 :arc 90 :on-hit :crumple :flags (:ender))              ; 双翼 SOYOKU 3
(defmove-copy :lb-w-j2s :lb-w-j2)
(defmove-copy :lb-w-k2s :lb-w-k2)
;; Shift+L SP2 二十四孔 NIJUSHI-KO (2 bars): all 24 holes glow 40 f (turning 60 deg/s until f20, then planted), one 1.2 m
;; radius beam to the wall
(defmove :lb-nijushi :kind :sp :clip :lb-w-nijushi :callout "NIJUSHI-KO" :startup 40 :active 6 :recovery 30 :dmg 180
  :adv-block -14 :track 0 :vol (:cap 0.6 31.0 1.2 1.2) :on-hit :knockback :kb 2.0 :chip *lb-x-chip* :guard 45
  :flags (:ranged :x-axis :uncatchable) :tick lb-nijushi-tick :on-frame ((0 lb-nijushi-tell) (40 lb-beam-shot))
  :params (:lock 20 :track 60.0 :width 1.2))
(defmove :lb-w-breaker :kind :breaker :clip :lb-w-breaker :clip-2 :lb-w-ram :callout "JILLIEL")
(defmove :lb-w-kikon :kind :kikon :clip :lb-w-aim :clip-2 :lb-w-fire :clip-s 4 :callout "KAMI NO SABAKI"
  :cine lb-jilliel-kikon-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.2 1.2) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 lb-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))

;;; ---------------------------------------------------------------- 遠 EN and 転身 TENSHIN (§22.2, decision 18)
;; EN's J / K / SP1: no hit window; on its first active frame each lays an X-axis trace (J one line, K a fan of three, SP1
;; SANREN's three), and the stick walks him at *LB-EN-WALK* through the whole move, facing kept on the opponent (LB-EN-TICK);
;; from the active end L cancels it into TENSHIN. Round 2 (decision 28, 2026-10-06, 「覺醒的遠程模式 J/K/SP1/SP2 的前後搖都
;; 大幅縮短。」): their startups and recoveries roughly halved, the active frames kept (the wing strings' were J 8/3/12, 7/3/13,
;; 9/3/18, K 17/4/21, 20/4/24 enter 6, 21/5/34 enter 7; SP1 12/22/24 lines f12/22/32; SP2 40/6/30); the wing clips play at
;; :clip-s / S speed (their hit poses on the new first active frame); KIN and the base form keep theirs
(defmove :lb-e-j1 :kind :quick :clip :lb-w-q1 :clip-s 8 :startup 4 :active 3 :recovery 6 :reach 1.6 :tick lb-en-tick
  :on-frame ((4 lb-en-lay)) :params (:trace :j))
(defmove :lb-e-j2 :kind :quick :clip :lb-w-q2 :clip-s 7 :startup 4 :active 3 :recovery 6 :reach 1.6 :tick lb-en-tick
  :on-frame ((4 lb-en-lay)) :params (:trace :j))
(defmove :lb-e-j3 :kind :quick :clip :lb-w-q3 :clip-s 9 :startup 5 :active 3 :recovery 9 :reach 1.7 :flags (:ender)
  :tick lb-en-tick :on-frame ((5 lb-en-lay)) :params (:trace :j))
(defmove :lb-e-k1 :kind :flash :clip :lb-w-f1 :clip-s 17 :startup 9 :active 4 :recovery 10 :reach 2.2 :tick lb-en-tick
  :on-frame ((9 lb-en-lay)) :params (:trace :k))
(defmove :lb-e-k2 :kind :flash :clip :lb-w-f2 :clip-s 20 :enter 3 :startup 10 :active 4 :recovery 12 :reach 2.2
  :tick lb-en-tick :on-frame ((10 lb-en-lay)) :params (:trace :k))
(defmove :lb-e-k3 :kind :flash :clip :lb-w-f3 :clip-s 21 :enter 4 :startup 11 :active 5 :recovery 17 :reach 2.3
  :flags (:ender) :tick lb-en-tick :on-frame ((11 lb-en-lay)) :params (:trace :k))
(defmove-copy :lb-e-j2s :lb-e-j2)
(defmove-copy :lb-e-k2s :lb-e-k2)
(defmove :lb-e-sanren :kind :sp :clip :lb-w-aim :callout "SANREN" :startup 6 :active 14 :recovery 12 :reach 2.2
  :tick lb-en-tick :on-frame ((6 lb-en-lay) (12 lb-en-lay) (18 lb-en-lay)) :params (:trace :sp1))
;; EN's SP2 NIJUSHI-KO (2 bars): the 20 f tell (planted, turning 60 deg/s until f10), then one thick trace (round 2: 40 f,
;; locked at f20, R 30 before)
(defmove :lb-e-nijushi :kind :sp :clip :lb-w-nijushi :clip-s 40 :callout "NIJUSHI-KO" :startup 20 :active 6 :recovery 15
  :track 0 :tick lb-nijushi-tick :on-frame ((0 lb-nijushi-tell) (20 lb-en-lay)) :params (:lock 10 :track 60.0 :trace :sp2))
;; L 転身 TENSHIN (both modes): the dash's frame 0 materialises every live trace; a flash-step dash over 14 f, up to 8 m at
;; him stopping 1.5 m short (EN -> KIN, free) or 7 m away (KIN -> EN, 10 flash step), iframes for its frames 0-8; the form
;; changes 6 f into the dash; R 8; no cooldown (decision 34; 30 f before). From the dash's end his J / K cancel the
;; recovery (LB-LINK-TICK; a press before is latched): a trace hit -> TENSHIN in -> J is a combo (round 2, decision 25).
;; EN -> KIN starts with a wind-up (decision 30; decision 34: 8 -> 16 f from neutral): 16 f from EN's neutral
;; (:lb-switch-in, EN's L), 2 f as a cancel out of an EN attack (:lb-switch-in-c, the same move entered at its f14:
;; LB-EN-TICK); KIN -> EN (:lb-switch, KIN's L) has none
(defmove :lb-switch :kind :sig :clip :lb-w-tenshin :callout "TENSHIN" :startup *lb-switch-f* :active 0 :recovery 8
  :tick lb-link-tick :on-frame ((0 lb-switch-go) (6 lb-switch-form))
  :params (:link *lb-switch-f*))
(defmove :lb-switch-in :kind :sig :clip :lb-w-tenshin-in :callout "TENSHIN" :startup 30 :active 0 :recovery 8
  :tick lb-link-tick :on-frame ((16 lb-switch-go) (22 lb-switch-form))
  :params (:link 30 :go 16))
(defmove-copy :lb-switch-in-c :lb-switch-in :enter 14)

;;; ================================================================ the owl 真の姿 (§6; decision 36: Jilliel's system, §23.14)
;;; Every owl J / K / SP recovers *SHIN-ADV* (1) frame sooner than Jilliel's, its :adv-block 1 higher (+1 on hit and on
;;; block: decision 36, 「更優異的優勢幀」); the KIN strings keep their links (DUEL_STRINGS's budget + 1, host-tested).
;; 近 KIN: the claws (the long arms), the owl's strings as built with R - 1, adv + 1
(defmove :lb-o-j1 :kind :quick :clip :lb-o-q1 :startup 8 :active 3 :recovery 11 :dmg 26 :adv-block -1
  :reach 1.7 :arc 110 :on-hit :flinch)                               ; 鉤爪 KAGIZUME 1: the long arms (R 12, -2 before)
(defmove :lb-o-j2 :kind :quick :clip :lb-o-q2 :startup 7 :active 3 :recovery 12 :dmg 26 :adv-block -1
  :reach 1.7 :arc 110 :on-hit :flinch)                               ; (R 13, -2)
(defmove :lb-o-j3 :kind :quick :clip :lb-o-q3 :startup 9 :active 3 :recovery 17 :dmg 32 :adv-block -3
  :reach 1.7 :arc 120 :on-hit :stagger :flags (:ender))              ; (R 18, -4)
(defmove :lb-o-k1 :kind :flash :clip :lb-o-f1 :startup 17 :active 4 :recovery 20 :dmg 54 :adv-block -2
  :reach 2.3 :arc 150 :on-hit :stagger)                              ; (R 21, -3)
(defmove :lb-o-k2 :kind :flash :clip :lb-o-f2 :enter 6 :startup 20 :active 4 :recovery 23 :dmg 54 :adv-block -2
  :reach 2.3 :arc 110 :on-hit :stagger)                              ; (R 24, -3)
(defmove :lb-o-k3 :kind :flash :clip :lb-o-f3 :enter 7 :startup 21 :active 5 :recovery 33 :dmg 78 :adv-block -19
  :reach 2.3 :arc 90 :on-hit :crumple :flags (:ender))              ; (R 34, -20)
(defmove-copy :lb-o-j2s :lb-o-j2)
(defmove-copy :lb-o-k2s :lb-o-k2)
;; KIN's Shift+K SP1 裁きの光明 SABAKI NO KOMYO (審判光明; decision 36: 「SP1 特效與動作用審判光明」): the chop bursts three
;; SABAKI ground lines at -20 / 0 / +20 deg at once, one hit group (one line at most hits him); R 25 (26, MISUJI before)
(defmove :lb-misuji :kind :sp :clip :lb-o-chop :clip-s 16 :callout "SABAKI NO KOMYO" :startup 18 :active 0 :recovery 25
  :reach 18.0 :track 90 :on-frame ((18 lb-sabaki)) :params (:dmg 70 :guard 18 :fan (-20.0 0.0 20.0)))
;; KIN's Shift+L SP2 神の喇叭 TROMPETE (2 bars): 60 f wind-up (the fist at the beak, the trumpet forming; turning 30 deg/s
;; until f40, then locked), a 2.4 m-wide beam 30 f; reflected by a perfect Hoho f48-f59 / guard f50-f58 (LB-REFLECT-CHECK:
;; the halo breaks, SP2 sealed in both modes); R 39, -13 (40, -14 before: decision 36's +1; the rest as built)
(defmove :lb-trompete :kind :sp :clip :lb-o-trompete :callout "TROMPETE" :startup 60 :active 30 :recovery 39 :dmg 240
  :adv-block -13 :track 0 :vol (:cap 0.6 31.0 1.4 1.2) :on-hit :knockback :kb 3.0 :chip *lb-x-chip* :guard 60
  :flags (:ranged :x-axis :uncatchable :reflectable) :tick lb-trompete-tick :on-frame ((0 lb-trompete-tell) (60 lb-beam-shot))
  :params (:lock 40 :blast 60 :track 30.0 :width 1.2))
(defmove :lb-o-breaker :kind :breaker :clip :lb-o-breaker :clip-2 :lb-o-stamp :callout "KAGIZUME")
(defmove :lb-o-kikon :kind :kikon :clip :lb-o-trompete :clip-2 :lb-o-chop :clip-s 4 :callout "TROMPETE"
  :cine lb-trompete-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 80 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.4 1.4) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 lb-lane-shot))
  :params (:aura 10 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))
;; 遠 EN (decision 36): Jilliel EN's J / K / SP1 / SP2 (decision 28's frames) with R - 1, the claw clips at :clip-s / S;
;; no hit window: each lays traces (J one line, K a fan of three) on its first active frame while the stick walks him
;; (LB-EN-TICK, LB-EN-LAY); the owl's traces materialise as 裁きの光明's gold ground blasts (the look)
(defmove :lb-oe-j1 :kind :quick :clip :lb-o-q1 :clip-s 8 :startup 4 :active 3 :recovery 5 :reach 1.7 :tick lb-en-tick
  :on-frame ((4 lb-en-lay)) :params (:trace :j))
(defmove :lb-oe-j2 :kind :quick :clip :lb-o-q2 :clip-s 7 :startup 4 :active 3 :recovery 5 :reach 1.7 :tick lb-en-tick
  :on-frame ((4 lb-en-lay)) :params (:trace :j))
(defmove :lb-oe-j3 :kind :quick :clip :lb-o-q3 :clip-s 9 :startup 5 :active 3 :recovery 8 :reach 1.7 :flags (:ender)
  :tick lb-en-tick :on-frame ((5 lb-en-lay)) :params (:trace :j))
(defmove :lb-oe-k1 :kind :flash :clip :lb-o-f1 :clip-s 17 :startup 9 :active 4 :recovery 9 :reach 2.3 :tick lb-en-tick
  :on-frame ((9 lb-en-lay)) :params (:trace :k))
(defmove :lb-oe-k2 :kind :flash :clip :lb-o-f2 :clip-s 20 :enter 3 :startup 10 :active 4 :recovery 11 :reach 2.3
  :tick lb-en-tick :on-frame ((10 lb-en-lay)) :params (:trace :k))
(defmove :lb-oe-k3 :kind :flash :clip :lb-o-f3 :clip-s 21 :enter 4 :startup 11 :active 5 :recovery 16 :reach 2.3
  :flags (:ender) :tick lb-en-tick :on-frame ((11 lb-en-lay)) :params (:trace :k))
(defmove-copy :lb-oe-j2s :lb-oe-j2)
(defmove-copy :lb-oe-k2s :lb-oe-k2)
;; EN's SP1 裁きの光明 (SANREN's frames: lines at f6 / f12 / f18, R 11): three chops, each laying a trace (the ground line)
(defmove :lb-oe-sabaki :kind :sp :clip :lb-oe-sabaki :callout "SABAKI NO KOMYO" :startup 6 :active 14 :recovery 11 :reach 2.3
  :tick lb-en-tick :on-frame ((6 lb-en-lay) (12 lb-en-lay) (18 lb-en-lay)) :params (:trace :sp1))
;; EN's SP2 神の喇叭 (2 bars): Trompete's wind-up as a 12 f tell (planted, turning 100 deg/s until f6, the trumpet forming
;; at 5x), then one thick trace (A 6); R 8. Not the blast: nothing to reflect (sealed: refused). Decision 38 (the user,
;; 2026-10-06: 「SP2 神之喇叭在遠程模式的前後搖再縮短」): S 20 -> 12, R 14 -> 8 (NIJUSHI-KO EN's 20 / 6 / 15 before, R - 1);
;; the lock f10 -> f6 and the turn 60 -> 100 deg/s (the same 10 deg at most), the clip 3x -> 5x (its 60 f wind-up in 12)
(defmove :lb-oe-trompete :kind :sp :clip :lb-o-trompete :clip-s 60 :callout "TROMPETE" :startup 12 :active 6 :recovery 8
  :track 0 :tick lb-trompete-tick :on-frame ((0 lb-trompete-tell) (12 lb-en-lay)) :params (:lock 6 :track 100.0 :trace :sp2))
;; L 転身 TENSHIN for the owl's body (Jilliel's three moves, the owl's clips; decision 36)
(defmove-copy :lb-o-switch :lb-switch :clip :lb-o-tenshin)
(defmove-copy :lb-o-switch-in :lb-switch-in :clip :lb-o-tenshin-in)
(defmove-copy :lb-o-switch-in-c :lb-switch-in :clip :lb-o-tenshin-in :enter 14)

;;; ================================================================ forms
(defparameter *lille-hooks* '(:tick lille-tick :ok lille-ok :hit lille-hit :struck lille-struck :draw lille-draw)
  "His mechanics (kit.lisp KIT-HOOK): the eye, the reflect, the stance's own perfect-Hoho drop, the traces' end on the
revival (:tick); the sealed SP2, TENSHIN's flash-step, EN's dry J / K (:ok); the pacing log (:hit :struck); the aim line (:draw). (The
revive's condition is the Jilliel kits' :bankai-ok, LILLE-BANKAI-OK.)")

(defparameter *lb-kamae-strings*
  (append (loop for s in '(:lb-kamae :lb-kamae-k :lb-kamae-re)
                append `((,s :kamae-l :lb-k-shot) (,s :kamae-j :lb-k-j) (,s :kamae-k :lb-k-k) (,s :kamae-step :lb-k-dash)))
          '((:lb-k-dash :kamae-back :lb-kamae-re)))
  "The shooting stance's follow-ups: non-button strings (KIT-NEXT) its :tick starts (LB-KAMAE-TICK; rework R).")

;; the CPU (DUEL_LILLE §11, §22): bands, intents, the generic Bankai key, the key a CPU facing him reads off his kits
;; (:opp-reflect: ai.lisp AI-OPP-REFLECT; :opp-reflex LB-OPP-TRACE, the traces); his own reflexes (the AI section below:
;; LB-AI-REFLEX): the eye (:eye (:p)), the stance (:stance (:p :max :gg)), Trompete's punish (:trompete (:p :left)), the
;; switch (:switch (:traces :near :whiff :gg)); the shooting stance's branch and EN's walk are picked in the sim's ticks
;; (LB-AI-KAMAE, LB-AI-EN-STICK: Ichigo's TSUKIMACHI pattern)
(defkit :lille :base
  :name "LILLE" :body :lille :weapon :diagramm :stance :lb-stance :calm t
  :intro :lb-intro :win :lb-win :intro-callout "THE X-AXIS"
  :walk *walk-lille* :run *run-lille* :reishi *reishi-max* :swing-sfx :whoosh-light :mult *lille-mult* :taken *lille-taken*
  :commands (:q :lb-j1 :f :lb-k1 :sig :lb-kamae :sp1 :lb-sanren :sp2 :lb-hiren :breaker :lb-breaker :kikon :lb-kikon)
  :grid (:lb-j1 :lb-j2 :lb-j3 :lb-k1 :lb-k2 :lb-k3 :lb-j2s :lb-k2s)
  :strings *lb-kamae-strings*
  :l-after-k :lb-kamae-k                        ; L after K1 / K2 / K3: the stance at f4 (§22.1)
  :awaken-form :jilliel :kikon-konpaku 2 :hooks *lille-hooks*
  :ai (:intents (:approach 1 :pressure 1 :zone 5 :defend 2)
       :ranges (:approach (2.2 8.0) :pressure (1.3 2.2) :zone (8.0 20.0) :defend (5.0 9.0))
       :moves ((0.0 2.2 :q 4 :f 2 :breaker 1 :step 2 :sig 1)       ; (the stance in every band, §22.1)
               (2.2 6.0 :sp2 2 :step 2 :sp1 1 :sig 2 nil 1)
               (6.0 99.0 :sig 6 :sp1 1 nil 1))
       :guard 0.5 :hoho 0.3 :dash 0.3 :dash-back 0.7 :block-string 0.3 :o-ender 0.3 :l-after-k 0.4 :kikon-range 7.7
       :awaken (:min-taken 150) :eye (:p 0.5) :reflex lb-ai-reflex))

;; 神の裁き JILLIEL, 遠 EN (the awakening enters it; floating, as built): J / K / SP1 walk and lay traces, SP2 a thick one,
;; L TENSHIN (to KIN), U MUJITTAI, P the revival (decision 16)
(defkit :lille :jilliel :inherit :base
  :lift *lb-jilliel-lift* :awakening t :form-name "JILLIEL" :walk *walk-jilliel* :run *run-jilliel* :mult *jilliel-mult* :taken *jilliel-taken*
  :kikon-konpaku 3 :guard-to :jilliel-mujittai :gg-regen *jilliel-gg-regen* :bankai-form :shin :bankai-ok lille-bankai-ok
  :l-after-k nil
  :endless-form :jilliel                        ; ENDLESS: the stances, KIN and the owl stay as JILLIEL (never the owl)
  :body :lille-jilliel :weapon nil :stance :lb-w-stance :cine lb-jilliel-cine :u-tag "U: MUJITTAI" :swing-sfx :whoosh-heavy
  :commands (:q :lb-e-j1 :f :lb-e-k1 :sig :lb-switch-in :sp1 :lb-e-sanren :sp2 :lb-e-nijushi :breaker :lb-w-breaker
             :kikon :lb-w-kikon)
  :grid (:lb-e-j1 :lb-e-j2 :lb-e-j3 :lb-e-k1 :lb-e-k2 :lb-e-k3 :lb-e-j2s :lb-e-k2s)
  ;; (:neutral-guard 0: U is the stance, entered only as a reaction, LB-AI-STANCE-IN; batch 3a)
  :ai (:intents (:approach 1 :pressure 0 :zone 5 :defend 2)
       :ranges (:approach (6.0 12.0) :pressure (6.0 9.0) :zone (6.0 12.0) :defend (8.0 12.0))
       :moves ((0.0 3.0 :step 2 :q 1 :f 1 nil 1)
               (3.0 14.0 :f 4 :q 3 :sp1 1 :sp2 1 nil 1)
               (14.0 99.0 :f 2 :q 2 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.4 :dash-back 0.6 :kikon-range 8.5
       :bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1) :stance (:p 0.6 :max 180 :gg 30)
       :switch (:traces 3 :near 0.6 :whiff 1.5) :opp-trace (:p 0.5) :opp-reflex lb-opp-trace :reflex lb-ai-reflex))

;; U in Jilliel: 無実体 MUJITTAI, West's ward with the :intangible flag (§5.2): every attack drops it (no :keep)
(defkit :lille :jilliel-mujittai :inherit :jilliel
  :guard-to nil :drop-to :jilliel :passives (:ward :intangible) :stance :lb-w-fold :u-tag "U: MUJITTAI")

;; 近 KIN (§22.2): the owl's forked legs (body :lille-jilliel-kin, rework A), the
;; wing-blade strings (normal hits), SP1 SANREN and SP2 NIJUSHI-KO direct as built, L TENSHIN (to EN) also after a K link
(defkit :lille :jilliel-kin :inherit :jilliel
  :form-name "JILLIEL KIN" :walk *walk-kin* :run *run-kin* :guard-to :jilliel-kin-mujittai :l-after-k t
  :body :lille-jilliel-kin
  :commands (:q :lb-w-j1 :f :lb-w-k1 :sig :lb-switch :sp1 :lb-sanren :sp2 :lb-nijushi)
  :grid (:lb-w-j1 :lb-w-j2 :lb-w-j3 :lb-w-k1 :lb-w-k2 :lb-w-k3 :lb-w-j2s :lb-w-k2s)
  :ai (:intents (:approach 3 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.4 6.0) :pressure (1.4 2.4) :zone (3.0 6.0) :defend (3.0 6.0))
       :moves ((0.0 2.4 :q 4 :f 4 :breaker 1)
               (2.4 8.0 :step 1 :sp1 1 nil 1)
               (8.0 99.0 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.8 :block-string 0.3 :o-ender 0.5 :kikon-range 8.5
       :bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1) :stance (:p 0.6 :max 180 :gg 30)
       :switch (:gg 40) :reflex lb-ai-reflex))

(defkit :lille :jilliel-kin-mujittai :inherit :jilliel-kin
  :guard-to nil :drop-to :jilliel-kin :passives (:ward :intangible) :stance :lb-w-fold :u-tag "U: MUJITTAI")

;; the owl (P with <= 4 Konpaku in any Jilliel form, Kenpachi's Bankai path: Konpaku -> 1, Reishi full; decisions 15, 16),
;; on Jilliel's system (decision 36, 2026-10-06; DUEL_LILLE §23.14): 遠 EN :shin (the revival enters it) and 近 KIN
;; :shin-kin, L TENSHIN between them, U MUJITTAI in both (「也是無實體」), the owl's body (lift 0) in all four, EN's J / K
;; laying traces that materialise as 裁きの光明's gold ground blasts, SP1 裁きの光明 (EN lays its lines, KIN bursts them), SP2
;; 神の喇叭 (EN a thick trace after its wind-up, KIN the blast: reflect and seal kept, 「保留反射與封印」). x1.1 dealt, x1.1
;; taken, refunds 5 / 2, +1 on every attack; Kikon 4; no revival from here (no :bankai-form)
(defkit :lille :shin :inherit :jilliel
  :lift *lb-owl-lift* :form-name "SHIN" :mult *shin-mult* :taken *shin-taken* :kikon-konpaku 4
  :guard-to :shin-mujittai :bankai-form nil :bankai-ok nil
  :body :lille-shin :stance :lb-oe-stance :cine lb-revive-cine :swing-sfx :whoosh-heavy
  :commands (:q :lb-oe-j1 :f :lb-oe-k1 :sig :lb-o-switch-in :sp1 :lb-oe-sabaki :sp2 :lb-oe-trompete :breaker :lb-o-breaker
             :kikon :lb-o-kikon)
  :grid (:lb-oe-j1 :lb-oe-j2 :lb-oe-j3 :lb-oe-k1 :lb-oe-k2 :lb-oe-k3 :lb-oe-j2s :lb-oe-k2s)
  :ai (:intents (:approach 1 :pressure 0 :zone 5 :defend 2)                 ; (Jilliel EN's, no revival)
       :ranges (:approach (6.0 12.0) :pressure (6.0 9.0) :zone (6.0 12.0) :defend (8.0 12.0))
       :moves ((0.0 3.0 :step 2 :q 1 :f 1 nil 1)
               (3.0 14.0 :f 4 :q 3 :sp1 1 :sp2 1 nil 1)
               (14.0 99.0 :f 2 :q 2 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.4 :dash-back 0.6 :kikon-range 9.0 :stance (:p 0.6 :max 180 :gg 30)
       :switch (:traces 3 :near 0.6 :whiff 1.5) :opp-trace (:p 0.5) :opp-reflex lb-opp-trace :reflex lb-ai-reflex))

(defkit :lille :shin-mujittai :inherit :shin
  :guard-to nil :drop-to :shin :passives (:ward :intangible) :stance :lb-oe-fold :u-tag "U: MUJITTAI")   ; (EN's: upright, afloat)

(defkit :lille :shin-kin :inherit :shin
  :lift 0.0 :form-name "SHIN KIN" :walk *walk-kin* :run *run-kin* :guard-to :shin-kin-mujittai :l-after-k t :stance :lb-o-stance
  :commands (:q :lb-o-j1 :f :lb-o-k1 :sig :lb-o-switch :sp1 :lb-misuji :sp2 :lb-trompete)
  :grid (:lb-o-j1 :lb-o-j2 :lb-o-j3 :lb-o-k1 :lb-o-k2 :lb-o-k3 :lb-o-j2s :lb-o-k2s)
  :ai (:intents (:approach 3 :pressure 4 :zone 0 :defend 1)                 ; (Jilliel KIN's, no revival; + Trompete)
       :ranges (:approach (2.6 6.0) :pressure (1.4 2.6) :zone (3.0 6.0) :defend (3.0 6.0))
       :moves ((0.0 2.6 :q 4 :f 4 :breaker 1)
               (2.6 8.0 :step 1 :sp1 1 nil 1)
               (8.0 99.0 :sp2 2 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.8 :block-string 0.3 :o-ender 0.6 :kikon-range 9.0
       :stance (:p 0.6 :max 180 :gg 30) :switch (:gg 40) :opp-reflect (:p 0.3) :trompete (:p 0.5 :left 30)
       :reflex lb-ai-reflex))

(defkit :lille :shin-kin-mujittai :inherit :shin-kin
  :guard-to nil :drop-to :shin-kin :passives (:ward :intangible) :stance :lb-o-fold :u-tag "U: MUJITTAI")

;; his names in the brush tables (brush.lisp): the intro's column and the technique columns at his side (not on the host)
(when (boundp '*brush-names*)
  (setf *brush-names* (append (remove :lille *brush-names* :key #'first) '((:lille "リジェ・バロ" "LILLE BARRO")))
        *brush-callouts*
        (append (remove-if (lambda (c) (member (first c) '(:lb-k-shot :lb-k-j :lb-k-k :lb-k-dash :lb-sanren :lb-e-sanren :lb-hiren
                                                            :lb-nijushi :lb-e-nijushi :lb-misuji :lb-oe-sabaki :lb-trompete
                                                            :lb-oe-trompete)))
                           *brush-callouts*)
                '((:lb-k-shot "万物貫通" "THE X-AXIS" nil) (:lb-k-j "跳射" "HOSHA" nil) (:lb-k-k "退射" "TAISHA" nil)
                  (:lb-k-dash "飛廉脚" "HIRENKYAKU" nil) (:lb-sanren "三連" "SANREN" nil)
                  (:lb-e-sanren "三連" "SANREN" nil) (:lb-hiren "飛廉脚" "HIRENKYAKU" nil) (:lb-nijushi "二十四孔" "NIJUSHI-KO" nil)
                  (:lb-e-nijushi "二十四孔" "NIJUSHI-KO" nil) (:lb-misuji "裁きの光明" "SABAKI NO KOMYO" nil)
                  (:lb-oe-sabaki "裁きの光明" "SABAKI NO KOMYO" nil) (:lb-trompete "神の喇叭" "TROMPETE" nil)
                  (:lb-oe-trompete "神の喇叭" "TROMPETE" nil)))))

;;; ================================================================ per-side state (the sim's; reset with every match)
(defstruct (lbs (:conc-name lbs-))
  (e nil)                                 ; the fighter it belongs to: a new match's fighter gets a fresh state (LB)
  (eyes *lb-eyes* :type fixnum)           ; the eye's pips left (never refilled)
  (u-up 0 :type fixnum)                   ; frames U has been up (the eye's rest rule)
  (eye-t -1 :type fixnum)                 ; *MATCH-TICK* of the last opening (the look)
  (sealed nil)                            ; the halo broke: Trompete is sealed for the match
  (stance 0 :type fixnum)                 ; frames of the current stance (MUJITTAI)
  ;; the shooting stance (§22.1): up yet, the step last counted, the charge (frames in it, the dash's included), the dash
  ;; spent, the CPU's plan (LB-AI-KAMAE); the shot's charge read at its press
  (k-up nil) (k-tick -1 :type fixnum) (charge 0 :type fixnum) (dashed nil) (k-plan nil) (k-charged nil)
  ;; Jilliel's modes (§22.2): TENSHIN's target form; the traces laid (their ids count up); the newest trace the opponent's
  ;; CPU rolled for (LB-OPP-TRACE); KIN's last string (its last link, its contact) for his CPU's switch out
  (switch-to nil) (trace-n 0 :type fixnum) (opp-roll 0 :type fixnum) (kin-last nil) (kin-contact nil)
  ;; round 2 (§23): the J / K latched in HOSHA / TENSHIN for their cancel (LB-LINK-TICK); ticks of TENSHIN's start and of
  ;; his last materialised trace's hit (his CPU's J after a switch in, the pacing log); the tick a J1 / K1 started from a
  ;; link and what it came from (:hosha / :tenshin: the pacing log's combos)
  (latch nil) (switch-t -1 :type fixnum) (trace-hit-t -1 :type fixnum) (link-t -1 :type fixnum) (link-from nil)
  (awake-t -1 :type fixnum) (revive-t -1 :type fixnum)   ; ticks of the awakening and the revival (the pacing log)
  (acc nil))                              ; the pacing log's counters (debug)
(defvar *lb* (vector (make-lbs) (make-lbs)) "Per side: his eye, the seal, the shooting stance, the traces.")
(defvar *lb-reflect-test* nil "Debug 79007 / 79008: P2 reflects P1's Trompete by a guard (:guard) / a perfect Hoho (:hoho).")
(defun lb (e)
  "E's state; a new fighter entity (a new match) gets a fresh one, keeping only the pacing log's counters (Senjumaru's
carry-over bug, DEVLOG §38-§39)."
  (let* ((i (fighter-side (fighter e))) (st (svref *lb* i)))
    (if (eql (lbs-e st) e) st (setf (svref *lb* i) (make-lbs :e e :acc (lbs-acc st))))))
(defmacro lb-count (e key &optional (n 1)) `(incf (getf (lbs-acc (lb ,e)) ,key 0) ,n))
(defun lb-band (d) "The pacing log's distance band of D metres: :near (< 8) :mid (8-14) :far (>= 14)." (cond ((< d 8.0) :near) ((< d 14.0) :mid) (t :far)))
(defun lb-band-key (prefix d) (intern (format nil "~a-~a" prefix (lb-band d)) :keyword))

;;; hazard data: his hazards (the SABAKI lines, the shots' looks) carry one of these and LB-HZ as their hook
(defstruct (lbh (:conc-name lbh-))
  (kind nil)                              ; :sabaki (a hit) :shot :beam :lane (looks) :trace (EN's, §22.2)
  (len 0f0 :type single-float) (width 0f0 :type single-float)
  (lock nil)                              ; a look's colour: T jade (a locked shot), NIL ink
  ;; a trace: what laid it (:j :k :sp1 :sp2: its damage and drain, LB-TRACE-HITWIN), its id (they count up per side),
  ;; live (laid, not yet materialised), its line (a :cap volume in its own frame)
  (src nil) (id 0 :type fixnum) (live nil) (vol nil))

;;; ================================================================ hooks (called through the data's symbols)
(defun lille-ok (e command combo)
  "His kit's refusals: the owl's SP2 once the halo broke (sealed for the match, decision 9; EN's and KIN's, decision 36);
TENSHIN out of KIN (Jilliel's or the owl's) without its
flash-step (*LB-SWITCH-FS*; the cue; EN -> KIN is free: decision 34). EN's J / K under *LB-TRACE-FS* flash step (no
swing: an empty J / K can't buy TENSHIN's 2 f cancel; the user 2026-10-06, decision 35); his CPU's also while their lines
would eat into its reserve (LB-AI-LAY-OK-P)."
  (declare (ignore combo))
  (let ((form (fighter-form (fighter e))) (fs (gauges-fs (gauges e))))
    (not (or (lb-sp2-sealed-p command form (lbs-sealed (lb e)))   ; (sealed: SP2 in both modes, decision 36)
             (and (eq command :sig) (lb-mode-form-p form) (not (lb-switch-ok-p form fs)))
             (and (member command '(:q :f)) (lb-en-form-p form)
                  (or (lb-en-dry-p fs) (and (brain e) (not (lb-ai-lay-ok-p fs (if (eq command :q) :j :k))))))))))

(defun lille-bankai-ok (e)
  "His kit's :bankai-ok (combat.lisp BANKAI-OK-P): P revives him into the owl from any Jilliel form, free: idle, guard or
the stance (the generic AWAKEN-STATE-P would also allow blockstun and a combo reaction), with <= *BANKAI-KONPAKU* Konpaku
(decision 16: no beheading needed; LB-REVIVE-OK-P)."
  (let ((f (fighter e))) (lb-revive-ok-p (fighter-form f) (fighter-state f) (gauges-konpaku (gauges e)))))

(defun lille-tick (e f g)
  "Per step (his kit's :tick, after the fighters stepped): EN's Hoho into KIN (decision 37: a Hoho started in an EN form,
LB-HOHO-TARGET), the eye (base), the stances' own perfect-Hoho drop (MUJITTAI), Trompete's reflect
check on its f59, the traces' end on the revival, KIN's last string (his CPU's switch out), the pacing log's clocks."
  (declare (ignore g))
  (let ((st (lb e)) (form (fighter-form f)))
    (let ((to (and (eq (fighter-state f) :hoho) (lb-hoho-target form))))   ; decision 37: a Hoho in EN lands in KIN (this
      (when to                                              ; step: the Hoho's frame 0, START-HOHO ran in the fighter system;
        (set-form e to)                                     ; the traces stay live for the next L)
        (lb-count e (if (lb-owl-form-p to) :owl-hoho-kin :hoho-kin))
        (setf form to)))
    (when (and (not (eq form :base)) (minusp (lbs-awake-t st)))
      (setf (lbs-awake-t st) *match-tick*) (lb-count e :awaken-tick *match-tick*))
    (when (and (lb-owl-form-p form) (minusp (lbs-revive-t st)))
      (setf (lbs-revive-t st) *match-tick*) (lb-count e :revive-tick *match-tick*)
      (lb-clear-traces e))                                  ; (gone on the revival, §22.2)
    (if (eq form :base) (lb-eye-step e f st) (setf (lbs-u-up st) 0))
    (cond ((lb-stance-form-p form)
           (when (and (eq (fighter-state f) :hoho) (fighter-perfect f))   ; his own counter strike is an attack: solid
             (set-form e (kit-drop-to (fighter-kit f)))
             (clog "~a MUJITTAI dropped: the perfect Hoho's counter" (side-name e)))
           (incf (lbs-stance st))
           (lb-count e :stance-frames)
           (setf (getf (lbs-acc st) :stance-max) (max (getf (lbs-acc st) :stance-max 0) (lbs-stance st))))
          (t (setf (lbs-stance st) 0)))
    (let ((mv (and (eq (fighter-state f) :move) (fighter-move f))))   ; KIN's string (LB-AI-KIN): its last link, contact
      (when (and mv (member form '(:jilliel-kin :shin-kin)) (member (mv-kind mv) '(:quick :flash)))
        (setf (lbs-kin-last st) (mv-name mv) (lbs-kin-contact st) (fighter-contact f))))
    (let ((mv (fighter-move f)))
      (when (and (eq (fighter-state f) :move) mv (eq (mv-name mv) :lb-trompete) (eq (fighter-phase f) :main))
        (when *lb-reflect-test* (lille-reflect-test-step e f))   ; (debug 79007 / 79008: a scripted reflector)
        (when (= (fighter-sf f) 59) (lb-reflect-check e f st mv))))))

;;; ---------------------------------------------------------------- the eye (§4.1)
(defun lb-eye-step (e f st)
  "The base form's eye: a U press after U rested *LB-EYE-REST* frames, from a free state, while a threat is <= *LB-EYE-LEAD*
frames away (LB-THREAT-P) opens it: *LB-EYE-PHASE* frames intangible, a pip spent; the third fills the awakening gauge.
A press with no threat spends nothing (it is a plain guard)."
  (let ((vp (pilot-vpad (pilot e))))
    (if (vpad-down vp :guard)
        (progn
          (when (and (lb-eye-tap-p (lbs-u-up st) (lbs-eyes st) (fighter-state f) (fighter-sf f)) (lb-threat-p e))
            (lb-open-eye e f st))
          (setf (lbs-u-up st) 0))
        (setf (lbs-u-up st) (min 9999 (1+ (lbs-u-up st)))))))

(defun lb-threat-p (e)
  "PERFECT-NOW-P's eye version (lead *LB-EYE-LEAD*): an opponent hit volume (move or hazard) active now or within the lead
overlaps his hurt cylinder grown by *PERFECT-INFLATE*, or the opponent's Breaker / Kikon rush dash is about to strike."
  (let* ((o (opp-of e)) (fo (fighter o)) (mv (fighter-move fo)) (p (pos-of e)) (q (pos-of o))
         (b (model-body (model e))) (yaw (yaw-of o))
         (r (f32 (+ (body-hurt-r b) *perfect-inflate*))) (h (f32 (+ (body-hurt-h b) *perfect-inflate*))))
    (or (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :main)
             (loop for w across (mv-hits mv)
                   thereis (and (lb-eye-window-p (fighter-sf fo) (hw-from w) (hw-to w))
                                (loop for v in (hw-vols w)
                                      thereis (vol-hit-p v (aref q 0) (aref q 1) (aref q 2) (f32 (fwd-x yaw)) (f32 (fwd-z yaw))
                                                         (aref p 0) (aref p 1) (aref p 2) r h 0f0)))))
        (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :dash)
             (<= (fighter-dist fo) (+ (if (eq (mv-kind mv) :kikon) *kikon-trigger* *breaker-trigger*) 0.5)))
        (let ((found nil))
          (do-entities (hh (hz hazard))
            (when (and (not found) (eql (hazard-owner hz) o) (hazard-hw hz) (> (hazard-hits-left hz) 0)
                       (<= (hazard-delay hz) *lb-eye-lead*)
                       (hazard-touches-p hz (aref p 0) (aref p 1) (aref p 2) r h))
              (setf found t)))
          found))))

(defun lb-open-eye (e f st)
  "The left eye opens: intangible *LB-EYE-PHASE* frames (FIGHTER-INVULN: every hit resolves to nothing, a whiff), one pip
spent; the third opening sets the awakening gauge to EVOLUTION unless he is awakened (decision 7)."
  (let ((g (gauges e)))
    (multiple-value-bind (left evo) (lb-eye-open (lbs-eyes st) (gauges-awakened g))
      (setf (lbs-eyes st) left (lbs-eye-t st) *match-tick* (fighter-invuln f) (max (fighter-invuln f) *lb-eye-phase*))
      (lb-count e :eyes)
      (emit :sfx :hoho-out e)
      (when evo
        (setf (gauges-awaken g) (f32 *awaken-max*))
        (lb-count e :eye-evolution *match-tick*)
        (callout e "SANDO MO ME WO..."))           ; 「三度も眼を開かされるとは…」 (the brush line: batch 3)
      (clog "~a EYE opens, ~d left~:[~; (EVOLUTION)~]" (side-name e) left evo))))

;;; ---------------------------------------------------------------- the shooting stance 狙撃構え (§22.1, decision 17)
(defun lb-kamae-clock (st sf now)
  "One step of the stance's charge (ST his state; SF the stance's move frame, NIL in the dash; NOW the step's tick): up at
*LB-KAMAE-UP* (charge 0), then +1 a step, counted once a step (the dash's last frame ticks twice) and through the dash.
Values the charge."
  (unless (= (lbs-k-tick st) now)
    (setf (lbs-k-tick st) now)
    (cond ((lbs-k-up st) (incf (lbs-charge st)))
          ((and sf (>= sf *lb-kamae-up*)) (setf (lbs-k-up st) t (lbs-charge st) 0))))
  (lbs-charge st))

(defun lb-kamae-enter (e)
  "A fresh stance (L from neutral at f0, or after a K link at f4): not up, no charge, its dash unspent, no CPU plan."
  (let ((st (lb e)))
    (setf (lbs-k-up st) nil (lbs-k-tick st) -1 (lbs-charge st) 0 (lbs-dashed st) nil (lbs-k-plan st) nil)
    (lb-count e :kamae)))

(defun lb-kamae-pressed (vp)
  "The stance's follow-up a human pressed (buffered, unmodified): :kamae-j / -k / -l / -step, or NIL."
  (cond ((vpad-command-pressed-p vp :quick nil) :kamae-j) ((vpad-command-pressed-p vp :flash nil) :kamae-k)
        ((vpad-command-pressed-p vp :sig nil) :kamae-l) ((vpad-command-pressed-p vp :step nil) :kamae-step)))

(defun lb-kamae-tick (e)
  "One step of the stance (TSUKIMACHI's TSUKI-STEP): it turns at *LB-AIM-TRACK* and counts the charge; from f6 the first
L / J / K / Step fires its branch (his CPU's: LB-AI-KAMAE's plan); the shot reads the charge at its press (quick or
charged); a Step without its flash-step or after the stance's one dash waits; past the hold (30 f, 90 while L is held)
the stance recovers (R 14)."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (when (and (eq (fighter-state f) :move) mv (member (mv-name mv) '(:lb-kamae :lb-kamae-k :lb-kamae-re)))
      (let* ((st (lb e)) (sf (fighter-sf f)) (vp (pilot-vpad (pilot e))) (b (brain e)))
        (turn-to-opp e f (track-step *lb-aim-track*))
        (lb-kamae-clock st sf *match-tick*)
        (when (>= sf *lb-kamae-up*)
          (let* ((cmd (if b (lb-ai-kamae e f st) (lb-kamae-pressed vp)))
                 (ok (case cmd
                       (:kamae-step (and (not (lbs-dashed st)) (>= (gauges-fs (gauges e)) *lb-kamae-dash-fs*)))
                       ((nil) nil)
                       (t t))))
            (when ok
              (unless b (vpad-consume! vp (getf '(:kamae-j :quick :kamae-k :flash :kamae-l :sig :kamae-step :step) cmd)))
              (case cmd
                (:kamae-step (spend-fs (gauges e) *lb-kamae-dash-fs*) (setf (lbs-dashed st) t))
                (:kamae-l (setf (lbs-k-charged st) (lb-kamae-charged-p (lbs-charge st)))))
              (start-move e (kit-next (fighter-kit f) (mv-name mv) cmd))
              (return-from lb-kamae-tick nil))))
        (when (lb-kamae-hold-over-p sf (vpad-down vp :sig))
          (setf (fighter-sf f) (+ *lb-kamae-up* *lb-kamae-max*)))))))

(defun lb-kamae-dash (e)
  "HIRENKYAKU (the stance's Step) f0: *LB-KAMAE-DASH* m in the stick direction (neutral: away from him; his CPU: straight
back) over its 12 f, iframes f0-8, the flash step's vanish (TSUKIWATARI's, the other way)."
  (let* ((f (fighter e)) (p (pos-of e)))
    (multiple-value-bind (to st) (if (brain e) (values -1.0 0.0) (stick-relative e f))
      (multiple-value-bind (to st) (step-direction to st -1.0)
        (multiple-value-bind (dx dz) (toward-strafe-dir to st (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f))
          (set-slide e *lb-kamae-dash* 12 dx dz))))
    (setf (fighter-invuln f) (max (fighter-invuln f) *lb-dash-iframes*))
    (lb-count e :k-dash)
    (emit :hoho-out e (aref p 0) (aref p 2))
    (emit :sfx :whoosh-light e)))
(defun lb-kamae-back (e)
  "HIRENKYAKU f11: back in the stance at f6, the charge kept, the aim snapped onto him (the 60 deg/s tracking goes on from
there: round 2, decision 23 「在 step 飛廉腳完之後會直接將準心重新對準對手」)."
  (start-move e (kit-next (kit-of e) :lb-k-dash :kamae-back))
  (turn-to-opp e (fighter e) 10.0))
(defun lb-k-dash-tick (e) "HIRENKYAKU: its frames count in the charge (LB-KAMAE-CLOCK)." (lb-kamae-clock (lb e) nil *match-tick*))

(defun lb-k-lock (e)
  "The stance's L, f0: locked on the press (track 0): the jade lane drawn along it (the 10 f before it fires: the visible
lock), the pacing log (quick / charged)."
  (lb-count e (if (lbs-k-charged (lb e)) :shot-charged :shot-quick))
  (lb-spawn-look e :lane *lb-trace-len* 0.5 t)
  (emit :sfx :lb-lock e))

(defun lb-k-fire (e)
  "The stance's L fires (f10): the charged shot adds the distance bonus (FIGHTER-DMG-BONUS: the window's 40 + LB-X-BONUS),
the quick one is flat; the line's look (jade charged, ink quick)."
  (let* ((f (fighter e)) (d (fighter-dist f)) (charged (lbs-k-charged (lb e))))
    (setf (fighter-dmg-bonus f) (if charged (lb-x-bonus d) 0))
    (lb-count e (lb-band-key "FIRED" d))
    (lb-spawn-look e :shot 31.0 0.05 charged)
    (emit :sfx :lb-crack e)))

;;; ---------------------------------------------------------------- 遠 EN: the mobile lines and their traces (§22.2)
(defun lb-en-tick (e)
  "EN's J / K / SP1, each step: the stick walks him at *LB-EN-WALK* (frost and a cold field slow it as a walk; his CPU's
stick: LB-AI-EN-STICK), facing kept on the opponent; from the move's active end L cancels it into TENSHIN with its 2 f
wind-up (:lb-switch-in-c, decision 30; a human's press; his CPU's switch rule, LB-AI-SWITCH-IN-P)."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (when (and (eq (fighter-state f) :move) mv (eq (mv-tick mv) 'lb-en-tick) (eq (fighter-phase f) :main))
      (let ((v (motion-vel (motion e))) (p (pos-of e)) (b (brain e)))
        (multiple-value-bind (to st) (if b (lb-ai-en-stick e f) (stick-relative e f))
          (let ((m (sqrt (+ (* to to) (* st st)))))
            (when (>= m 0.2)
              (multiple-value-bind (dx dz) (toward-strafe-dir to st (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f))
                (let ((sp (* (frost-speed *lb-en-walk* (fighter-frost f)) (min 1.0 m) (/ 1.0 m))))
                  (setf (aref v 0) (f32 (* sp dx)) (aref v 2) (f32 (* sp dz)))
                  (field-slow! e f v))))))
        (turn-to-opp e f (deg *face-rate*))
        (when (and (>= (fighter-sf f) (+ (mv-s mv) (mv-a mv))) (zerop (fighter-lock f)))
          (let ((vp (pilot-vpad (pilot e))))
            (cond (b (when (lb-ai-switch-in-p e b (lb-ai-seen b) *lb-switch-windup-c*)
                       (lb-count e :ai-switch-trace)
                       (try-command e f :sig nil nil (lb-switch-cancel-move f))))   ; (the 2 f cancel, decision 30)
                  ((vpad-command-pressed-p vp :sig nil)
                   (if (try-command e f :sig nil nil (lb-switch-cancel-move f))
                       (vpad-consume! vp :sig)
                       (refused-cue e f :sig vp :sig))))))))))

(defun lb-switch-cancel-move (f)
  "TENSHIN in's 2 f cancel out of an EN attack for F's form: Jilliel's :lb-switch-in-c, the owl's :lb-o-switch-in-c."
  (find-move (if (lb-owl-form-p (fighter-form f)) :lb-o-switch-in-c :lb-switch-in-c)))

(defun lb-en-lay (e)
  "EN's line frame: the move's traces (J one, K a fan of three, SP1 one a shot, SP2 one thick: LB-LAY-TRACE); a J / K line
costs *LB-TRACE-FS* flash step and is laid only while that is left, line by line (LB-TRACE-PAY; a K fan short of it lays
its middle line first: LB-TRACE-PICK; the swing plays either way; decision 34). A J / K link then chains on as if it had
touched him (the lines never hit: FIGHTER-CHAINED opens the string gate), and his CPU latches the same button's next link
while its reserve allows (LB-AI-EN-NEXT)."
  (let* ((f (fighter e)) (mv (fighter-move f)) (src (getf (mv-params mv) :trace)) (g (gauges e)))
    (let* ((fans (lb-trace-fans src)) (group (and (rest fans) (make-hit-group 1)))   ; a K's fan hits a fighter once
           (nick (and (rest fans) (make-hit-group 1)))                                ; (its laying shot too: decision 39)
           (laid (lb-trace-pay (gauges-fs g) src (length fans))) (cost (lb-trace-cost src)))
      (dolist (a (lb-trace-pick fans laid))
        (when (plusp cost) (spend-fs g cost))
        (lb-lay-trace e src a group nick))
      (when (< laid (length fans)) (lb-count e :traces-unpaid (- (length fans) laid)))
      (when (and (plusp laid) (lb-owl-form-p (fighter-form f))) (lb-count e :owl-traces laid)))
    (emit :sfx :rift-cut e)
    (when (member (mv-kind mv) '(:quick :flash))
      (setf (fighter-chained f) t)
      (when (brain e) (lb-ai-en-next e f mv)))))

(defun lb-live-traces (e)
  "His live traces: values how many and the oldest one's entity (the smallest id), or NIL."
  (let ((n 0) (old nil) (oid 0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (lbh-p d) (lbh-live d))
          (incf n)
          (when (or (null old) (< (lbh-id d) oid)) (setf old h oid (lbh-id d))))))
    (values n old)))

(defun lb-lay-trace (e src yaw-off &optional group nick)
  "One trace of SRC (:j :k :sp1 :sp2) from where he stands, at his facing + YAW-OFF degrees, *LB-TRACE-LEN* long: a hazard
with no hit (drawn by LB-TRACE-LOOK, faint jade on the floor) until his switch materialises it; at most *LB-TRACE-MAX*
live (the oldest dropped first: LB-TRACE-DROP-P). Laying it fires the line's shot along it (LB-NICK-HITWIN, a 2-frame
hazard of its own: decision 39; NICK a K fan's hit group, so the fan's shot hits a fighter once)."
  (let ((st (lb e)) (p (pos-of e)) (r (if (eq src :sp2) *lb-trace-r-thick* *lb-trace-r*)))
    (spawn-hazard :lb-nick e :x (aref p 0) :z (aref p 2) :yaw (+ (yaw-of e) (deg yaw-off)) :size *lb-trace-len*
                             :life 2 :hits 1 :hw (lb-nick-hitwin) :hook 'lb-hz :group nick
                             :data (make-lbh :kind :nick :src src :len (f32 *lb-trace-len*) :width (f32 r)
                                             :vol (make-vol :cap (list 0.6 *lb-trace-len* 1.2 r))))
    (multiple-value-bind (n old) (lb-live-traces e)
      (when (lb-trace-drop-p n) (destroy-entity old) (lb-count e :traces-dropped)))
    (spawn-hazard :lb-trace e :x (aref p 0) :z (aref p 2) :yaw (+ (yaw-of e) (deg yaw-off)) :size *lb-trace-len*
                              :life *lb-trace-life* :hook 'lb-hz :look 'lb-trace-look :group group
                              :data (make-lbh :kind :trace :src src :id (incf (lbs-trace-n st)) :live t
                                              :len (f32 *lb-trace-len*) :width (f32 r)
                                              :vol (make-vol :cap (list 0.6 *lb-trace-len* 1.2 r))))
    (lb-count e :traces)))

(defun lb-trace-materialise! (d mult)
  "Trace data D at a switch: a live one stops being live and gives the hit it deals now (LB-TRACE-HITWIN x MULT); a
materialised one, NIL (each materialises once)."
  (when (lbh-live d)
    (setf (lbh-live d) nil)
    (lb-trace-hitwin (lbh-src d) mult)))

(defun lb-materialise (e)
  "TENSHIN's frame 0: every live trace of his becomes a 2-frame hit (once; the hits of one switch count as one combo), the
X-axis line's look flashes along it (the owl's: 裁きの光明's gold ground blasts, :judge; decision 36), and it is gone after."
  (let ((mult (kit-mult (kit-of e))) (looks nil))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (lbh-p d))
          (let ((hw (lb-trace-materialise! d mult)))
            (when hw
              (setf (hazard-hw hz) hw (hazard-hits-left hz) 1 (hazard-life hz) (+ (hazard-age hz) 3))
              (push (list (if (eq (lbh-src d) :sp2) :beam :shot) (hazard-x hz) (hazard-z hz) (hazard-yaw hz) (lbh-width d)) looks))))))
    (if (lb-owl-form-p (fighter-form (fighter e)))              ; the owl's: 裁きの光明, gold blasts along the ground (decision 36)
        (dolist (l looks) (destructuring-bind (kind x z yaw w) l (declare (ignore kind)) (lb-spawn-look-at e :judge x z yaw 31.0 w (if (> w 0.9) :thick t))))
        (dolist (l looks) (destructuring-bind (kind x z yaw w) l (declare (ignore w)) (lb-spawn-look-at e kind x z yaw 31.0 0.05 t))))
    (when looks (lb-count e :materialised (length looks)))))

(defun lb-clear-traces (e)
  "His traces vanish (the revival, §22.2; a reset's CLEAR-HAZARDS takes them too)."
  (let ((gone nil))
    (do-entities (h (hz hazard)) (when (and (eql (hazard-owner hz) e) (lbh-p (hazard-data hz)) (eq (hazard-kind hz) :lb-trace)) (push h gone)))
    (dolist (h gone) (destroy-entity h))))

;;; ---------------------------------------------------------------- 転身 TENSHIN (§22.2)
(defun lb-switch-ready-p (e)
  "Could E's TENSHIN start now: a Jilliel or owl form, the flash-step for it (none from EN; no cooldown: decision 34)?"
  (let ((form (fighter-form (fighter e))))
    (and (lb-mode-form-p form) (lb-switch-ok-p form (gauges-fs (gauges e))))))

(defun lb-switch-dist (in d)
  "TENSHIN's dash, metres: IN (EN -> KIN) at him D metres away, at most *LB-SWITCH-IN*, stopping *LB-SWITCH-STOP* short
(none when he is nearer); out (KIN -> EN) *LB-SWITCH-OUT* away (round 2, decision 25)."
  (if in (max 0.0 (min *lb-switch-in* (- d *lb-switch-stop*))) *lb-switch-out*))

(defun lb-switch-go (e)
  "TENSHIN f0: every live trace materialises (LB-MATERIALISE); the flash-step dash over *LB-SWITCH-F* at him (EN -> KIN,
LB-SWITCH-DIST, free) or away (KIN -> EN, *LB-SWITCH-FS* flash step: LB-SWITCH-PRICE), iframes f0-8; the target form
fixed now (LB-SWITCH-FORM at f6); the J / K latch cleared (LB-LINK-TICK)."
  (let* ((f (fighter e)) (st (lb e)) (p (pos-of e)) (to (lb-switch-target (fighter-form f)))
         (in (lb-kin-form-p to)) (k (if in 1.0 -1.0)) (dist (lb-switch-dist in (fighter-dist f))))
    (setf (lbs-switch-to st) to (lbs-switch-t st) *match-tick* (lbs-latch st) nil)
    (lb-materialise e)
    (when (> dist 0.01)
      (set-slide e dist *lb-switch-f* (* k (- (fighter-ox f) (aref p 0))) (* k (- (fighter-oz f) (aref p 2)))))
    (setf (fighter-invuln f) (max (fighter-invuln f) *lb-dash-iframes*))
    (let ((price (lb-switch-price (fighter-form f)))) (when (plusp price) (spend-fs (gauges e) price)))
    (lb-count e (if in :switch-in :switch-out))
    (when (lb-owl-form-p to) (lb-count e (if in :owl-switch-in :owl-switch-out)))
    (emit :hoho-out e (aref p 0) (aref p 2))
    (emit :sfx :whoosh-light e)))

(defun lb-switch-form (e)
  "TENSHIN f6: the form changes (EN <-> KIN)."
  (let ((to (lbs-switch-to (lb e)))) (when to (setf (lbs-switch-to (lb e)) nil) (set-form e to))))

;;; ---------------------------------------------------------------- the other shots
(defun lb-x-fire (e)
  "The X-axis shot's fire frame (the aimed shot, HIRENKYAKU's): its distance bonus on the hit (FIGHTER-DMG-BONUS: the
window's 40 + LB-X-BONUS), the line's look, the pacing log."
  (let* ((f (fighter e)) (d (fighter-dist f)))
    (setf (fighter-dmg-bonus f) (lb-x-bonus d))
    (lb-count e (lb-band-key "FIRED" d))
    (lb-spawn-look e :shot 31.0 0.05 t)
    (emit :sfx :lb-crack e)))

(defun lb-line-shot (e)
  "SANREN's shots (f12, f22, f32): the line's look."
  (lb-count e :sanren-shots)
  (lb-spawn-look e :shot (move-param e :len) 0.04 nil)
  (emit :sfx :rift-cut e))

(defun lb-lane-shot (e)
  "A Kikon module's lane (照準, 神の裁き, 神の喇叭): its look (the hit is the move's lane)."
  (lb-spawn-look e :lane (move-param e :len) 0.5 t)
  (emit :sfx :kikon-slash e))

(defun lb-beam-shot (e)
  "NIJUSHI-KO's / Trompete's first active frame: the beam's look."
  (lb-count e (if (eq (mv-name (fighter-move (fighter e))) :lb-trompete) :trompete-fired :nijushi-fired))
  (lb-spawn-look e :beam 31.0 (move-param e :width) t)
  (emit :sfx :explode e))

(defun lb-spawn-look (e kind len width lock)
  "A look-only hazard of his (kind :lb-fx, no hit) along his facing: a shot, a beam or a lane (drawn by LB-LOOK,
lille-art.lisp)."
  (let ((p (pos-of e))) (lb-spawn-look-at e kind (aref p 0) (aref p 2) (yaw-of e) len width lock)))
(defun lb-spawn-look-at (e kind x z yaw len width lock)
  "LB-SPAWN-LOOK from (X Z) along YAW (a materialised trace's flash; the owl's :judge, LOCK :thick for SP2's wide one)."
  (spawn-hazard :lb-fx e :x x :z z :yaw yaw :size len :life (case kind ((:beam :judge) 30) (t 16))
                         :hook 'lb-hz :data (make-lbh :kind kind :len (f32 len) :width (f32 width) :lock lock)
                         :look 'lb-look))

(defun lb-sanren-tick (e)
  "SANREN: he turns 90 deg/s between the shots (the 2nd and 3rd follow a Step)."
  (let* ((f (fighter e)) (sf (fighter-sf f)))
    (when (and (eq (fighter-phase f) :main) (< 14 sf 32) (not (<= 22 sf 24)))
      (turn-to-opp e f (track-step 90.0)))))

(defun lb-hiren-slide (e)
  "SP2 HIRENKYAKU / the stance's K TAISHA f0: the back-slide, the move's :slide metres over :slide-f frames (6 m / 14 f;
3 m / 12 f), no iframes (decision 1)."
  (let* ((p (pos-of e)) (f (fighter e)))
    (set-slide e (move-param e :slide) (move-param e :slide-f) (- (aref p 0) (fighter-ox f)) (- (aref p 2) (fighter-oz f)))
    (lb-count e (if (eq (mv-name (fighter-move f)) :lb-k-k) :taisha :hiren))
    (emit :sfx :hoho-out e)))

(defun lb-taisha-fire (e)
  "TAISHA f16: the mid-range bullet (the move's 12 m line, 60 flat: no distance bonus), the line's look."
  (lb-count e (lb-band-key "FIRED" (fighter-dist (fighter e))))
  (lb-spawn-look e :shot (move-param e :len) 0.05 nil)
  (emit :sfx :lb-crack e))

(defun lb-hosha-leap (e)
  "HOSHA f0: the forward leap, *LB-HOSHA-LEAP* m along his facing over *LB-HOSHA-LEAP-F* frames, stopping *LUNGE-STOP*
short of him (a lunge's rule); the J / K latch cleared."
  (let* ((f (fighter e)) (yaw (yaw-of e)) (dist (min *lb-hosha-leap* (max 0.0 (- (fighter-dist f) *lunge-stop*)))))
    (when (> dist 0.01) (set-slide e dist *lb-hosha-leap-f* (fwd-x yaw) (fwd-z yaw)))
    (setf (lbs-latch (lb e)) nil)
    (lb-count e :hosha)
    (emit :sfx :whoosh-light e)))

(defun lb-bullet (e)
  "HOSHA's bullets (f6, f10, f14): the short line's look from the muzzle (the hit is the move's window)."
  (lb-count e :hosha-shots)
  (lb-spawn-look e :shot (move-param e :len) 0.04 nil)
  (emit :sfx :rift-cut e))

(defun lb-hosha-tick (e)
  "HOSHA, each step: he turns at the move's :track while he leaps (to f14, the last bullet); the J / K link (LB-LINK-TICK)."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (<= (fighter-sf f) *lb-hosha-leap-f*))
      (turn-to-opp e f (track-step (mv-track (fighter-move f)))))
    (lb-link-tick e)))

(defun lb-link-tick (e)
  "HOSHA and TENSHIN (round 2, decisions 21, 25): a J / K pressed during the move is latched (a human's consumed; the last
press wins) and, from the move's :link frame (HOSHA: its recovery, f16, once a bullet hit; TENSHIN: the dash's end,
f14, always), cancels the rest into his form's J1 / K1 (TRY-COMMAND: EN's lay traces, KIN's and the base form's hit).
A HOSHA link and a KIN one after TENSHIN in chase him in their startup (FIGHTER-END-CHASE, the Breaker's J1 / K1 rule).
His CPU's link (LB-AI-LINK) is picked once."
  (let* ((f (fighter e)) (mv (fighter-move f)) (st (lb e)) (b (brain e)))
    (when (and (eq (fighter-state f) :move) mv (eq (fighter-phase f) :main) (zerop (fighter-lock f)))
      (let ((hosha (eq (mv-name mv) :lb-k-j)) (vp (pilot-vpad (pilot e))))
        (unless b
          (cond ((vpad-command-pressed-p vp :quick nil) (vpad-consume! vp :quick) (setf (lbs-latch st) :q))
                ((vpad-command-pressed-p vp :flash nil) (vpad-consume! vp :flash) (setf (lbs-latch st) :f))))
        (when (and (>= (fighter-sf f) (getf (mv-params mv) :link 99)) (or (not hosha) (eq (fighter-contact f) :hit)))
          (when (and b (null (lbs-latch st))) (setf (lbs-latch st) (lb-ai-link e f st hosha)))
          (let ((c (lbs-latch st)) (in (and (not hosha) (member (fighter-form f) '(:jilliel-kin :shin-kin)))))
            (when (and (member c '(:q :f)) (try-command e f c))
              (setf (lbs-latch st) nil (lbs-link-t st) *match-tick* (lbs-link-from st) (if hosha :hosha :tenshin))
              (when (or hosha in) (setf (fighter-end-chase (fighter e)) t))
              (lb-count e (if hosha :hosha-link :tenshin-link)))))))))

(defun lb-hiren-tick (e)
  "HIRENKYAKU / TAISHA: he keeps turning to the opponent while he slides, then the line is fixed (track 0 from :lock)."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (move-param e :lock))) (turn-to-opp e f (track-step 90.0)))))

(defun lb-planted-tick (e)
  "A planted wind-up (NIJUSHI-KO, Trompete): turning at the move's :track until its :lock frame, then locked."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (move-param e :lock)))
      (turn-to-opp e f (track-step (move-param e :track))))))
(defun lb-nijushi-tick (e) "NIJUSHI-KO's wind-up (LB-PLANTED-TICK)." (lb-planted-tick e))
(defun lb-trompete-tick (e) "Trompete's wind-up (LB-PLANTED-TICK)." (lb-planted-tick e))

(defun lb-nijushi-tell (e)
  "NIJUSHI-KO f0: all 24 holes glow (the tell)."
  (setf (model-super (model e)) 0.6)
  (emit :sfx :awaken-rise e))

(defun lb-trompete-tell (e)
  "Trompete f0: the fist at the beak, the trumpet forming overhead, the rising pitch (the tell)."
  (setf (model-super (model e)) 1.0)
  (emit :sfx :lb-trumpet e))

;;; ---------------------------------------------------------------- SABAKI NO KOMYO / MISUJI (§6.2)
(defun lb-sabaki (e)
  "The chop's frame: a SABAKI ground line per :fan angle (MISUJI's three share one hit group: one line at most hits him;
gap G12); each erupts outward from 1 m to 18 m (LB-SABAKI-SPAN), through guard (chip 15 %, the :guard drain), once."
  (let* ((p (pos-of e)) (fan (move-param e :fan)) (group (and (rest fan) (make-hit-group 1))))
    (dolist (a fan)
      (spawn-hazard :lb-sabaki e :x (aref p 0) :z (aref p 2) :yaw (+ (yaw-of e) (deg a)) :size *lb-sabaki-to*
                                 :life (lb-sabaki-frames) :group group :hook 'lb-hz :data (make-lbh :kind :sabaki :len (f32 *lb-sabaki-to*)
                                                                                                    :width (f32 *lb-sabaki-width*))
                                 :look 'lb-look
                                 :hw (make-hitwin :dmg (move-param e :dmg) :react :stagger :kb 1.0 :hs *hitstop-heavy*
                                                  :chip *lb-x-chip* :guard (move-param e :guard)
                                                  :flags '(:ranged :x-axis :uncatchable))))
    (lb-count e (if group :misuji :sabaki))
    (emit :sfx :ground-crack e)))

(defun lb-hz (h hz ev &optional a b c dd ee)
  "His hazards' hook (HAZARD-HOOK): a SABAKI line's volume (:touches): the burning span of the line (LB-SABAKI-SPAN), a box
*LB-SABAKI-WIDTH* wide; a trace's line (only a materialised one has a hit); the looks touch nothing."
  (declare (ignore h))
  (let ((d (hazard-data hz)))
    (case ev
      (:touches (case (lbh-kind d)
                  (:sabaki
                   (multiple-value-bind (from to) (lb-sabaki-span (hazard-age hz))
                     (and (> to from)
                          (let* ((yaw (hazard-yaw hz)) (mid (* 0.5 (+ from to))))
                            (obox-cyl-hit-p (f32 (+ (hazard-x hz) (* mid (fwd-x yaw)))) 1f0 (f32 (+ (hazard-z hz) (* mid (fwd-z yaw))))
                                            yaw (f32 (* 0.5 (lbh-width d))) 1.2f0 (f32 (* 0.5 (- to from)))
                                            a b c dd ee)))))
                  ((:trace :nick)                       ; a trace's line (its :cap from where it was laid), its laying shot
                   (let ((yaw (hazard-yaw hz)))
                     (vol-hit-p (lbh-vol d) (hazard-x hz) 0f0 (hazard-z hz) (f32 (fwd-x yaw)) (f32 (fwd-z yaw))
                                (f32 a) (f32 b) (f32 c) (f32 dd) (f32 ee) 0f0)))))
      (t nil))))

;;; ---------------------------------------------------------------- Trompete's reflect (§6.3, decision 9)
(defun lb-reflect-check (e f st mv)
  "Trompete at the end of its f59 (the beam comes next step): the opponent in a perfect Hoho started f48-f59, or in a guard
pressed f50-f58 (FIGHTER-GUARD-T 2-10, facing him, not a ward: West, KESSA and zero Rukia can't) reflects it."
  (declare (ignore f))
  (let* ((o (opp-of e)) (fo (fighter o)) (go (gauges o)) (p (pos-of e)) (q (pos-of o))
         (src (cond ((and (eq (fighter-state fo) :hoho) (fighter-perfect fo) (lb-reflect-hoho-p (- 59 (fighter-sf fo)))) :hoho)
                    ((and (eq (fighter-state fo) :guard) (not (passive-p o :ward)) (lb-reflect-guard-p (fighter-guard-t fo))
                          (can-guard-p (gauges-gg go) (gauges-guardless go))
                          (in-front-p (yaw-of o) (aref q 0) (aref q 2) (aref p 0) (aref p 2) *guard-arc*))
                     :guard))))
    (when src (lb-reflect! e o st mv src))))

(defun lb-reflect! (e o st mv src)
  "The reflect: the beam turns back along its line before it fires: he takes *LB-REFLECT-K* of it x his form's damage as a
real hit (it may Soul Break him; not a Kikon), staggers *LB-REFLECT-STUN*; his halo breaks: Trompete is sealed for the
match. The reflector takes nothing (a Hoho's counter strike is replaced by the reflect)."
  (let* ((dmg (lb-reflect-damage (hw-dmg (svref (mv-hits mv) 0)) (kit-mult (kit-of e)))) (q (pos-of o)) (p (pos-of e)))
    (setf (lbs-sealed st) t (fighter-perfect (fighter o)) nil)
    (callout o "REFLECT")
    (lb-count e (if (eq src :hoho) :reflect-hoho :reflect-guard))
    (hitstop *hitstop-breaker*)
    (emit :hit o e (aref p 0) (+ (aref p 1) 1.1) (aref p 2) *hitstop-breaker* nil dmg :sp)
    (unless (deal-damage o e dmg)
      (set-reaction e :stagger *lb-reflect-stun* (aref q 0) (aref q 2) 1.0))
    (clog "~a TROMPETE REFLECTED by ~a (~a): ~d, sealed" (side-name e) (side-name o) src dmg)))

;;; ---------------------------------------------------------------- the pacing log's hit hooks
(defun lille-hit (att def res hw mv hazard ranged)
  "After a hit he dealt (his kit's :hit): a shot from >= *LB-FAR-KB* knocks back 2.0 m; the pacing log (shots hit / guarded
by band, damage by band, Trompete)."
  (declare (ignore ranged))
  (let ((x (member :x-axis (hw-flags hw))) (d (fighter-dist (fighter att))))
    (when x
      (case (contact-of res)
        (:hit (lb-count att (lb-band-key "HIT" d))
         (when (and mv (not hazard) (getf (mv-params mv) :bonus))
           (lb-count att (lb-band-key "DMG" d) (+ (hw-dmg hw) (fighter-dmg-bonus (fighter att))))
           (when (>= d *lb-far-kb*)
             (let ((p (pos-of att)) (q (pos-of def))) (set-slide def 2.0 12 (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)))))))
        (:block (lb-count att (lb-band-key "GUARDED" d))))
      (when (and mv (eq (mv-name mv) :lb-trompete))
        (lb-count att (if (eq (contact-of res) :hit) :trompete-hit :trompete-guarded))))
    (when (and hazard (lbh-p (hazard-data hazard)) (eq (lbh-kind (hazard-data hazard)) :trace))   ; a materialised trace
      (when (eq (contact-of res) :hit) (setf (lbs-trace-hit-t (lb att)) *match-tick*))
      (let* ((owl (lb-owl-form-p (fighter-form (fighter att)))) (fs (lb-trace-refund (contact-of res) owl)))
        (when (plusp fs)                                    ; its flash step back (decision 34; a fan's group: once;
          (pay-gauges (or (siphon-of att) att) 0.0 fs)      ; the owl's 5 / 2, decision 36)
          (lb-count att :trace-refund)
          (when owl (lb-count att :owl-trace-refund fs)))
        (when owl (lb-count att (if (eq (contact-of res) :hit) :owl-trace-hit :owl-trace-guarded))))
      (lb-count att (if (eq (contact-of res) :hit) :trace-hit :trace-guarded)))
    (when (and mv (member (mv-name mv) '(:lb-k-shot :lb-k-j :lb-k-k)))   ; the stance's branches
      (lb-count att (intern (format nil "~a-~a" (mv-name mv) (if (eq (contact-of res) :hit) "HIT" "BLK")) :keyword)))
    (let ((st (lb att)) (f (fighter att)))                  ; a J1 / K1 started from a link (round 2): its hit in the combo
      (when (and mv (not hazard) (lbs-link-from st) (eq (fighter-move f) mv) (eq (contact-of res) :hit)
                 (>= (lbs-link-t st) (- *match-tick* (fighter-sf f) 1)))
        (lb-count att (if (> (fighter-combo-hits (fighter def)) 1)
                          (if (eq (lbs-link-from st) :hosha) :hosha-combo :tenshin-combo)
                          (if (eq (lbs-link-from st) :hosha) :hosha-drop :tenshin-drop)))
        (setf (lbs-link-from st) nil)))))

(defun lille-struck (def att res hw mv hazard ranged)
  "After a hit he took (his kit's :struck): the stance's pacing (passes, Breaker breaks, crushes)."
  (declare (ignore att hw mv hazard ranged))
  (when (lb-stance-form-p (fighter-form (fighter def)))
    (case res
      (:blocked (lb-count def :passes)))
    (when (gauges-guardless (gauges def)) (lb-count def :stance-crushed)))
  (when (and (eq res :guard-break) (member (fighter-form (fighter def)) '(:jilliel :jilliel-kin :shin :shin-kin)))
    (lb-count def :stance-broken)))

;;; ================================================================ AI: his own CPU (DUEL_LILLE §11.2, §22; batch 3a, rework R)
;;; The kits' :reflex (LB-AI-REFLEX, ai.lisp AI-REFLEX: free states, before the generic answers). Every lead is the
;;; perceived one (his move frame as seen, SNAP-SF, + the perception delay), every chance x *LB-AI-DIFF* (EASY <= NORMAL
;;; <= HARD), and every roll is made once per event: per threatening window (his move's start tick, or a hazard's spawn
;;; tick: LBAI-KEY), per opponent action (the generic BRAIN-REACT-ROLL), per stance (the plan at its f6).
;;;   base      the eye takes over from the generic guard reflex: a threat's roll taps U (the eye) where the sim's eye test
;;;             will see it, else a guard held from now, or a sideways Step off a lane (LB-AI-EYE); the shooting stance's
;;;             branch is planned once at its f6 in the sim's tick (LB-AI-KAMAE: TSUKIMACHI's pattern)
;;;   jilliel   EN: TENSHIN in when >= 3 traces are live and he stands on one, or reels / recovers near one (LB-AI-EN; in
;;;             EN's moves the tick checks the same rule; from neutral through a J1's 2 f cancel when its line is paid,
;;;             else the 16 f wind-up), or when starved of flash step; the walk through the lines (LB-AI-EN-STICK) and the
;;;             string's next link (LB-AI-EN-NEXT) are the tick's; a J / K only above the flash-step reserve
;;;             (*LB-AI-FS-RESERVE*, LILLE-OK). KIN: TENSHIN out after a string or with the gauge low, with the flash step
;;;             for EN's lines (LB-AI-KIN). Both: the stance as a reaction only: a threat within reach + 1 m or a hazard within 12 f
;;;             rolls :stance -> U (LB-AI-STANCE-IN); in it he leaves by attacking: his whiff / recovery, :max frames, the
;;;             gauge under :gg, or he out of reach and idle (LB-AI-STANCE-OUT)
;;;   shin      Trompete (SP2) as a punish from beyond J's reach (LB-AI-TROMPETE); the neutral bands give it >= 8 m only
;;;   revive    the generic :bankai reflex (ai.lisp) with the Jilliel kits' :bankai-ok
;;;   opponents a CPU facing EN steps off a trace while his TENSHIN is ready, one roll per new trace (LB-OPP-TRACE)
(defparameter *lb-ai-diff* '(:easy 0.5 :normal 1.0 :hard 1.5)
  "His CPU's chances (:eye :p, :stance :p, :trompete :p) x this by difficulty, at most 1: :eye 0.5 -> 0.25 / 0.5 / 0.75
(DUEL_LILLE §11.2; design 2026-10-06).")
(defparameter *lb-ai-eye-tap* 4
  "His CPU taps the eye when the threat's perceived lead is 1..this frames (inside the sim's *LB-EYE-LEAD* 8, with room
for a lead seen a frame off; batch 3a, 2026-10-06).")
(defparameter *lb-ai-fs-reserve* 10.0
  "His CPU's flash-step budget in EN (decision 34, 2026-10-06; the lines cost *LB-TRACE-FS* each): a J / K starts (and
its next link is latched) only while the flash step left after its lines stays >= this: TENSHIN out's price
(*LB-SWITCH-FS*), so the KIN string after a switch in can always switch back out. Below a J's worth (starved) EN switches
in from neutral (free; LB-SWITCH-IN-RULE's STARVED), and KIN switches out after a string only with the price + this + a
K fan (LB-AI-OUT-OK-P), so EN never arrives starved.")

;; pure: host-tested (tests/duel-rules-test.lisp)
(defun lb-ai-chance (p difficulty) "A chance P of his kit's :ai at DIFFICULTY: x *LB-AI-DIFF*, at most 1." (min 1.0 (* p (getf *lb-ai-diff* difficulty 1.0))))
(defun lb-ai-eye-ready-p (lead u-up pips)
  "Can his CPU still make the eye on a threat LEAD frames away (perceived), U up U-UP frames, PIPS left: a pip, the threat
not already on him, and U rested *LB-EYE-REST* by the tap (at lead *LB-AI-EYE-TAP*: U is let go until then)?"
  (and (plusp pips) (>= lead 1) (>= (+ u-up (max 0 (- lead *lb-ai-eye-tap*))) *lb-eye-rest*)))
(defun lb-ai-eye-tap-p (lead) "Tap now: the perceived lead is 1..*LB-AI-EYE-TAP*." (<= 1 lead *lb-ai-eye-tap*))
(defun lb-ai-eye-plan (r p ready dodge guard-k)
  "The base form's answer to one threatening window, from its one roll R: :EYE (R < P, READY: LB-AI-EYE-READY-P), else
:STEP when DODGE (a lane, a Breaker / grab, a Kikon on him red: nothing guards it), else :GUARD with GUARD-K's share of R's
remainder (AI-GUARD-K: a low gauge guards less), :STEP the rest."
  (cond ((and ready (< r p)) :eye)
        (dodge :step)
        (t (let ((r2 (if (< r p) (/ r (max p 1e-6)) (/ (- r p) (max (- 1.0 p) 1e-6)))))
             (if (< r2 guard-k) :guard :step)))))
(defun lb-ai-stance-plan (r p line)
  "Jilliel's answer to one threatening window, from its one roll R: :STANCE (R < P), else :STEP off a LINE, else :PASS (a
Hoho on the generic roll, or nothing: he has no other guard)."
  (cond ((< r p) :stance) (line :step) (t :pass)))
(defun lb-stance-exit (busy frames max gg gg-min idle-far)
  "Why his CPU leaves MUJITTAI now (by attacking), or NIL: :WHIFF (he is BUSY: recovering or reeling), :MAX (FRAMES in
it >= MAX), :GAUGE (the guard gauge GG under GG-MIN), :IDLE (he is out of reach and idle: IDLE-FAR)."
  (cond (busy :whiff) ((>= frames max) :max) ((< gg gg-min) :gauge) (idle-far :idle)))
(defun lb-ai-kamae-plan (r d reeling guarding gg-low whiffed dash-ok)
  "His CPU's branch in the shooting stance, picked once at its f6 from one roll R (DUEL_LILLE §22.1, §23.1): the opponent
REELING (after a K link's hit) L 0.6 (:L, the quick shot) / J 0.4 (HOSHA); from 8 m the charged shot (:CHARGE); 6-8 m the
quick shot on a WHIFFED recovery, else the dash back then the charged shot (:DASH, when DASH-OK), else :CHARGE; 3-6 m the
quick shot (through guard) on a GUARDING opponent or a whiff, else J (HOSHA: the 5 m leap, the 3 m bullets); within 3 m K
(TAISHA: room; its 6 m bullet after the 3 m back-slide reaches only from there; the third playtest moved the guard case
off TAISHA). (GG-LOW is no longer read: round 2.)"
  (declare (ignore gg-low))
  (cond (reeling (if (< r 0.6) :l :j))
        ((>= d 8.0) :charge)
        ((> d 6.0) (cond (whiffed :l) (dash-ok :dash) (t :charge)))
        ((> d 3.0) (cond ((or guarding whiffed) :l) (t :j)))
        (t :k)))
(defun lb-ai-link-plan (hosha r in trace-hit)
  "His CPU's J / K link (LB-LINK-TICK), once a move: after HOSHA's hit (HOSHA) J1 (:Q) under R < 0.5, else K1 (:F); after
TENSHIN, J1 when it switched IN (to KIN) and a materialised trace hit (TRACE-HIT: the combo), else :NONE."
  (cond (hosha (if (< r 0.5) :q :f))
        ((and in trace-hit) :q)
        (t :none)))
(defun lb-switch-in-rule (n gap busy k &optional moving starved)
  "EN's switch in (DUEL_LILLE §22.2): N live traces, the opponent GAP m from the nearest (its line, a thick one's extra
width off), BUSY (perceived reeling or recovering, long enough to outlast the switch's wind-up): >= :traces traces with
GAP <= :near unless he is MOVING (running, stepping, a Hoho: the 16 f wind-up from neutral would let him off it,
decisions 30, 34), or BUSY with GAP <= :whiff; or STARVED (his CPU can't pay a J line above its reserve: KIN, free,
regains it; decision 34) unless he is MOVING."
  (and (or (and (plusp n) (or (and (>= n (getf k :traces 3)) (<= gap (getf k :near 0.6)) (not moving))
                              (and busy (<= gap (getf k :whiff 1.5)))))
           (and starved (not moving)))
       t))
(defun lb-ai-lay-ok-p (fs src &optional (reserve *lb-ai-fs-reserve*))
  "May his CPU start an EN J (SRC :j) / K (:k) link with FS flash step: what its lines cost (LB-TRACE-COST x LB-TRACE-FANS)
leaves >= RESERVE (decision 34)?"
  (>= (- fs (* (lb-trace-cost src) (length (lb-trace-fans src)))) reserve))
(defun lb-ai-out-ok-p (fs)
  "May his CPU's KIN switch out after a string with FS flash step: TENSHIN out's price, then EN's reserve and a K fan's
lines left (decision 34; LB-AI-LAY-OK-P once back)?"
  (lb-ai-lay-ok-p (- fs *lb-switch-fs*) :k))

;; the shell (the sim's state, the perceived SNAPs)
(defstruct (lbai (:conc-name lbai-))
  (e nil) (b nil)                         ; the fighter and the brain it belongs to (a new match: a fresh one)
  (key -1 :type fixnum)                   ; the threatening window rolled for (his move's start tick; a hazard's: -2 - spawn)
  (plan nil)                              ; its answer: :eye :tapped :guard :step :stepped / :stance :step :pass :done
  (tap -1 :type fixnum)                   ; *MATCH-TICK* of the eye's tap
  (exit -1 :type fixnum))                 ; the stance whose exit was counted (its start tick)
(defvar *lb-ai* (vector (make-lbai) (make-lbai)) "Per side: his CPU's plan for the current threat.")
(defun lb-ai-state (e b)
  (let* ((i (fighter-side (fighter e))) (st (svref *lb-ai* i)))
    (if (and (eql (lbai-e st) e) (eq (lbai-b st) b)) st (setf (svref *lb-ai* i) (make-lbai :e e :b b)))))

(defun lb-ai-reflex (e b s d)
  "Every form's :reflex (ai.lisp AI-REFLEX, free states): the eye (base), TENSHIN in (EN) / out (KIN) and the stance in /
out (Jilliel, MUJITTAI), Trompete's punish (the owl). A command, :NONE (hands off: the generic guard must not answer), or
NIL."
  (case (kit-form (kit-of e))
    (:base (lb-ai-eye e b s d))
    ((:jilliel :shin) (lb-ai-en e b s d))                     ; (the owl runs Jilliel's EN / KIN CPU: decision 36)
    (:jilliel-kin (lb-ai-kin e b s d))
    (:shin-kin (or (lb-ai-trompete e b s d) (lb-ai-kin e b s d)))   ; (+ Trompete's punish, as built)
    ((:jilliel-mujittai :jilliel-kin-mujittai :shin-mujittai :shin-kin-mujittai) (lb-ai-stance-out e b s d))))

(defun lb-ai-threat-p (e s d margin)
  "Is his perceived move S a threat the generic guard reflex would answer: an attack in its main phase with hit frames,
still to hit and within its reach + MARGIN (an :x-axis line: E on it, in its real window: SNAP-LIVE-P / SNAP-NEAR-P), not
a parry, a bind's tell or a :reflectable blast (:opp-reflect's)? An aim (the hold) is :opp-aim's."
  (and (eq (snap-state s) :move) (eq (snap-phase s) :main)
       (member (snap-kind s) '(:quick :flash :sig :sp :breaker :kikon))
       (> (snap-active-end s) (snap-s s))
       (snap-live-p s) (snap-near-p s e d margin)
       (not (intersection '(:parry :bind :reflectable) (snap-flags s)))))

(defun lb-ai-line-p (s)
  "Is his perceived move a lane: an :x-axis line or a Kikon module's lane (:params :look :lane)? A Step clears it."
  (or (snap-x-axis-p s) (and (snap-move s) (eq (getf (mv-params (snap-move s)) :look) :lane))))

(defun lb-ai-side-step (e b s)
  "A sideways Step off his perceived line (LINE-OFF-STRAFE; anything else: the current strafe)."
  (when (lb-ai-line-p s)
    (let ((p (pos-of e)))
      (setf (brain-strafe b) (f32 (line-off-strafe (snap-x s) (snap-z s) (snap-yaw s) (aref p 0) (aref p 2) (snap-x s) (snap-z s))))))
  :side-step)

(defun lb-ai-eye (e b s d)
  "The base form (DUEL_LILLE §11.2, the eye): on a threat (LB-AI-THREAT-P), one roll per window: :eye :p x the difficulty
with a pip and U rested by the tap (LB-AI-EYE-READY-P): U is let go, then tapped at a perceived lead 1..*LB-AI-EYE-TAP*
(the sim opens the eye: LB-EYE-STEP); a tap the sim didn't take (the lead seen wrong) turns into a guard. Else a guard
held from now (its share by AI-GUARD-K), or a sideways Step off a lane / from a Breaker or a Kikon on him red."
  (when (lb-ai-threat-p e s d *ai-threat-margin*)
    (let* ((ai (lb-ai-state e b)) (st (lb e)) (g (gauges e)) (lead (- (snap-s s) (snap-sf s) (brain-delay b))))
      (when (/= (snap-start s) (lbai-key ai))           ; a new window: its one roll
        (let* ((r (sim-rnd01))
               (dodge (or (lb-ai-line-p s) (eq (snap-kind s) :breaker) (member :grab (snap-flags s))
                          (and (eq (snap-kind s) :kikon) (red-p (gauges-reishi g) (gauges-reishi-max g)))))
               (plan (lb-ai-eye-plan r (lb-ai-chance (getf (ai-table e :eye) :p 0.0) (brain-difficulty b))
                                     (lb-ai-eye-ready-p lead (lbs-u-up st) (lbs-eyes st)) dodge (ai-guard-k e))))
          (setf (lbai-key ai) (snap-start s) (lbai-plan ai) plan)
          (lb-count e (case plan (:eye :ai-eye-plan) (:guard :ai-guard) (t :ai-step)))))
      (case (lbai-plan ai)
        (:eye (cond ((and (lb-ai-eye-tap-p lead) (>= (lbs-u-up st) *lb-eye-rest*) (plusp (lbs-eyes st)))
                     (setf (lbai-plan ai) :tapped (lbai-tap ai) *match-tick*)
                     (lb-count e :ai-eye-tap)
                     (ai-press b :guard 2 :act :hold)    ; the tap (LB-EYE-STEP opens it on this step's tick)
                     (why b :eye :none))
                    ((> lead *lb-ai-eye-tap*)            ; not yet: hands off U (it must rest)
                     (when (eq (brain-press b) :guard) (setf (brain-press-left b) 0))
                     (why b :eye-wait :none))
                    (t (setf (lbai-plan ai) :guard) (why b :eye-late :guard))))
        (:tapped (if (>= (lbs-eye-t st) (lbai-tap ai))
                     (why b :eye-open :none)              ; intangible: nothing to do till it passes
                     (progn (setf (lbai-plan ai) :guard) (lb-count e :ai-eye-miss) (why b :eye-miss :guard))))
        (:guard (why b :eye-guard :guard))
        (:step (setf (lbai-plan ai) :stepped) (why b :eye-step (lb-ai-side-step e b s)))
        (t (why b :eye-stepped :none))))))

(defun lb-ai-hazard-key (e lead)
  "One of his opponent's hazards about to hit E within LEAD frames: a wave / fireball flying at him (INCOMING-HAZARD-IN's
test), or a delayed one under him (a pillar, a line) whose delay is at most LEAD; its key (-2 - its spawn tick), or NIL."
  (let* ((o (opp-of e)) (q (pos-of e)) (b (model-body (model e))) (key nil))
    (do-entities (h (hz hazard))
      (when (and (null key) (eql (hazard-owner hz) o) (hazard-hw hz) (> (hazard-hits-left hz) 0)
                 (if (and (member (hazard-kind hz) '(:wave :fireball)) (<= (hazard-delay hz) 0) (> (hazard-speed hz) 0.1))
                     (let ((dist (sqrt (+ (expt (- (aref q 0) (hazard-x hz)) 2) (expt (- (aref q 2) (hazard-z hz)) 2)))))
                       (<= (/ (* 60 (max 0.0 (- dist 1.0))) (hazard-speed hz)) lead))
                     (and (< 0 (hazard-delay hz) (1+ lead))
                          (hazard-touches-p hz (aref q 0) (aref q 1) (aref q 2) (body-hurt-r b) (body-hurt-h b)))))
        (setf key (- -2 (- *match-tick* (hazard-age hz))))))
    key))

(defun lb-ai-stance-in (e b s d)
  "Jilliel (DUEL_LILLE §11.2, the stance): a move of his starting within its reach + 1 m (an :x-axis line: E on it), not a
Breaker / grab (it lands on the stance: the generic answers it), or a hazard of his within 12 f: one roll per window,
:stance :p x the difficulty (0 with the guard gauge under :gg: the stance would be left at once): U (MUJITTAI, the kit's
:guard-to). Else a sideways Step off a lane, or a Hoho on the generic Hoho roll (the generic chance, his move >= 6 f
out), or nothing: the generic guard would enter the stance, so the window is his (:NONE), as is a move only within the
generic guard's wider margin. (It can't catch a J1: the perception delay + the 2 f raise exceed J1's startup, §5.5.)"
  (let* ((solid (not (or (eq (snap-kind s) :breaker) (member :grab (snap-flags s)))))
         (mv-threat (and solid (lb-ai-threat-p e s d 1.0)))
         (key (if mv-threat (snap-start s) (lb-ai-hazard-key e 12))))
    (if (null key)
        (and solid (lb-ai-threat-p e s d *ai-threat-margin*) (why b :stance-out-of-reach :none))   ; (the generic guard's
                                                                                                     ; wider margin: no)
      (let ((ai (lb-ai-state e b)) (k (ai-table e :stance)) (g (gauges e)) (f (fighter e)))
        (when (/= key (lbai-key ai))
          (setf (lbai-key ai) key
                (lbai-plan ai) (lb-ai-stance-plan (sim-rnd01)
                                                  (if (or (gauges-guardless g) (< (gauges-gg g) (getf k :gg 30))) 0.0   ; (it
                                                      (lb-ai-chance (getf k :p 0.0) (brain-difficulty b)))   ; would drop at once)
                                                  (and mv-threat (lb-ai-line-p s))))
          (lb-count e (case (lbai-plan ai) (:stance :ai-stance) (:step :ai-step) (t :ai-pass))))
        (case (lbai-plan ai)
          (:stance (setf (lbai-plan ai) :done) (ai-press b :guard 4 :act :hold) (why b :stance :none))
          (:step (setf (lbai-plan ai) :done) (why b :stance-step (lb-ai-side-step e b s)))
          (:pass (setf (lbai-plan ai) :done)
                 (if (and mv-threat (>= (- (snap-s s) (snap-sf s)) 6)
                          (hoho-allowed-p nil (gauges-fs g) (fighter-hoho-lock f) (gauges-burst g))
                          (ai-hoho-spare-p (gauges-fs g) (gauges-reishi g) (gauges-reishi-max g))
                          (< (brain-hoho-roll b) (ai-table e :hoho 0.2)))
                     (why b :stance-hoho :hoho)
                     (why b :stance-pass :none)))
          (t (why b :stance-pass :none)))))))

(defun lb-ai-opp-reach (e)
  "His longest J / K reach (his current kit): what 'in reach' means for the stance's idle rule."
  (let ((kit (kit-of (opp-of e))))
    (loop for c in '(:q :f) for mv = (kit-command-move kit c) maximize (if mv (mv-reach mv) 0.0))))

(defun lb-ai-busy-p (s delay frames)
  "Is he, as perceived, recovering (his move past its active frames) or reeling, with at least FRAMES of it left after
DELAY? (FRAMES 0: just busy.)"
  (and (< (snap-left s) 99)
       (or (eq (snap-state s) :stun)
           (and (eq (snap-state s) :move) (eq (snap-phase s) :main) (>= (snap-sf s) (snap-active-end s))))
       (>= (- (snap-left s) delay) frames)))

(defun lb-ai-exit-cmd (e b s d)
  "The attack that ends MUJITTAI: K1 when he stays busy for its startup within its reach, J1 within its, else L (TENSHIN;
EN's J / K lay traces)."
  (let* ((kit (kit-of e)) (q (kit-command-move kit :q)) (fm (kit-command-move kit :f)))
    (cond ((and fm (<= d (+ (mv-reach fm) 0.2)) (lb-ai-busy-p s (brain-delay b) (mv-s fm)) (kit-command-ok-p e :f)) :f)
          ((and q (<= d (+ (mv-reach q) 0.2)) (kit-command-ok-p e :q)) :q)
          ((and fm (<= d (+ (mv-reach fm) 0.2)) (kit-command-ok-p e :f)) :f)
          ((kit-command-ok-p e :sig) :sig)
          ((kit-command-ok-p e :q) :q))))

(defun lb-ai-stance-out (e b s d)
  "MUJITTAI (DUEL_LILLE §11.2): he leaves the stance only by attacking (every attack drops it): on his whiff or recovery
(as perceived), after :max frames in it, with the guard gauge under :gg, or with him out of reach (+ 1 m) and idle (no
turtling); the whiff and the idle rule wait while a hazard of his is still coming (LB-AI-HAZARD-KEY). Deterministic rules
on what it sees, no roll."
  (let* ((k (ai-table e :stance)) (st (lb e)) (calm (not (lb-ai-hazard-key e 12)))   ; (none of his hazards coming)
         (why (lb-stance-exit (and calm (lb-ai-busy-p s (brain-delay b) 0)) (lbs-stance st) (getf k :max 180)
                              (gauges-gg (gauges e)) (getf k :gg 30)
                              (and calm (member (snap-state s) '(:idle :guard)) (> d (+ (lb-ai-opp-reach e) 1.0))))))
    (when why
      (let ((cmd (lb-ai-exit-cmd e b s d)) (ai (lb-ai-state e b)) (t0 (- *match-tick* (lbs-stance st))))
        (when cmd
          (when (/= (lbai-exit ai) t0)
            (setf (lbai-exit ai) t0)
            (lb-count e (case why (:whiff :ai-exit-whiff) (:max :ai-exit-max) (:gauge :ai-exit-gauge) (t :ai-exit-idle))))
          (why b :stance-exit cmd))))))

(defun lb-ai-trompete (e b s d)
  "The owl (DUEL_LILLE §11.2, Trompete): SP2 as a punish, beyond J's reach (the generic punish has it) and within the beam's
30 m, on him recovering or reeling for :left more frames (as perceived), one roll per his action (the react roll) at :p x
the difficulty. The neutral bands give SP2 only from 8 m: never into an idle opponent closer."
  (let ((k (ai-table e :trompete)) (q (kit-command-move (kit-of e) :q)))
    (and k q (> d (+ (mv-reach q) 0.4)) (<= d 30.0) (kit-command-ok-p e :sp2)
         (lb-ai-busy-p s (brain-delay b) (getf k :left 30))
         (< (brain-react-roll b) (lb-ai-chance (getf k :p 0.0) (brain-difficulty b)))
         (progn (lb-count e :ai-trompete) (why b :trompete :sp2)))))

(defun lb-ai-seen (b)
  "The SNAP brain B perceives this step (BRAIN-PERCEIVE's: its ring at the delay; NIL before it holds one): for his ticks,
which run inside moves where the reflexes don't."
  (let* ((ring (brain-ring b)) (n (length ring)))
    (and (plusp n) (svref ring (mod (- (brain-head b) 1 (brain-delay b)) n)))))

(defun lb-ai-kamae (e f st)
  "His CPU's follow-up in the shooting stance (LB-KAMAE-TICK, from f6): the plan picked once, on the first step it is up
(one roll, LB-AI-KAMAE-PLAN; TSUKIMACHI's pattern: the sim's state at its f6), then carried out: the shot now (:L), J, K,
the dash back (then the charged shot), or the charged shot once the charge reaches *LB-CHARGE-F*."
  (unless (lbs-k-plan st)
    (let* ((o (opp-of e)) (fo (fighter o)) (mo (and (eq (fighter-state fo) :move) (fighter-move fo)))
           (plan (lb-ai-kamae-plan (sim-rnd01) (fighter-dist f) (member (fighter-state fo) '(:stun :air))
                                   (member (fighter-state fo) '(:guard :guard-hit)) (< (gauges-gg (gauges o)) 50)
                                   (and mo (eq (fighter-phase fo) :main) (>= (fighter-sf fo) (+ (mv-s mo) (mv-a mo)))
                                        (null (fighter-contact fo)))
                                   (and (not (lbs-dashed st)) (>= (gauges-fs (gauges e)) *lb-kamae-dash-fs*)))))
      (setf (lbs-k-plan st) plan)
      (lb-count e (intern (format nil "AI-KAMAE-~a" plan) :keyword))))
  (case (lbs-k-plan st)
    (:l :kamae-l) (:j :kamae-j) (:k :kamae-k)
    (:dash (setf (lbs-k-plan st) :charge) :kamae-step)
    (:charge (and (lb-kamae-charged-p (lbs-charge st)) :kamae-l))))

(defun lb-ai-link (e f st hosha)
  "His CPU's link out of HOSHA (after a bullet's hit: one roll) or TENSHIN (J after a switch in whose traces hit; no roll):
LB-AI-LINK-PLAN; called once a move (the latch holds the answer)."
  (declare (ignore e))
  (lb-ai-link-plan hosha (if hosha (sim-rnd01) 0.0) (and (member (fighter-form f) '(:jilliel-kin :shin-kin)) t)
                   (>= (lbs-trace-hit-t st) (lbs-switch-t st) 0)))

(defun lb-ai-trace-gap (e x z)
  "His live traces seen from (X Z): values how many and the distance to the nearest one's line (a thick trace's extra width
off: LB-SWITCH-IN-RULE's gap)."
  (let ((n 0) (gap 99.0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (lbh-p d) (lbh-live d))
          (incf n)
          (setf gap (min gap (- (line-dist (hazard-x hz) (hazard-z hz) (hazard-yaw hz) 0.6 *lb-trace-len* x z)
                                (- (lbh-width d) *lb-trace-r*)))))))
    (values n gap)))

(defun lb-ai-switch-in-p (e b s windup &optional starved)
  "EN's switch in (his CPU; DUEL_LILLE §22.2): TENSHIN ready (LB-SWITCH-READY-P), and the opponent as perceived (S) on one
of >= 3 live traces (not running / stepping when the wind-up is the neutral one), or reeling / recovering near one for at
least the WINDUP frames still to come (LB-SWITCH-IN-RULE, the kit's :switch; decisions 30, 34: 16 f from neutral, 2 f as a
cancel, J1's 7 + 2 through a J), or STARVED (not running / stepping). Deterministic: no roll."
  (let ((k (ai-table e :switch)))
    (and k s (lb-switch-ready-p e)
         (multiple-value-bind (n gap) (lb-ai-trace-gap e (snap-x s) (snap-z s))
           (lb-switch-in-rule n gap (lb-ai-busy-p s (brain-delay b) windup) k
                              (and (> windup *lb-switch-windup-c*) (member (snap-state s) '(:run :step :hoho)) t)
                              starved)))))

(defun lb-ai-en (e b s d)
  "EN (free): the switch rule (LB-AI-SWITCH-IN-P) through the 2 f cancel when it can (decision 34: a J1, its line paid
above the reserve, then TENSHIN from its active end: 7 + 2 f to the materialise, not the neutral 16), else TENSHIN in from
neutral; else the stance reflex (LB-AI-STANCE-IN); else, STARVED (no J line above the reserve), TENSHIN in (free: KIN
regains the flash step). No roll."
  (let ((j1 (kit-command-move (kit-of e) :q)) (fs (gauges-fs (gauges e))))
    (cond ((and j1 (lb-ai-lay-ok-p fs :j) (kit-command-ok-p e :q)
                (lb-ai-switch-in-p e b s (+ (mv-s j1) (mv-a j1) *lb-switch-windup-c*)))
           (lb-count e :ai-switch-via-j) (why b :switch-via-j :q))
          ((lb-ai-switch-in-p e b s *lb-switch-windup*)
           (lb-count e :ai-switch-trace) (why b :switch-in :sig))
          ((lb-ai-stance-in e b s d))
          ((lb-ai-switch-in-p e b s *lb-switch-windup* (not (lb-ai-lay-ok-p fs :j)))
           (lb-count e :ai-switch-starved) (why b :switch-starved :sig)))))

(defun lb-ai-kin (e b s d)
  "KIN (free; DUEL_LILLE §22.2): TENSHIN out (to EN) after a string (its last link run out, LILLE-TICK's record; a blocked
one counted apart) or with the guard gauge under :gg (40), when it can start and (decision 34) with the flash step for
EN's lines after it (LB-AI-OUT-OK-P: EN never arrives starved); else the stance reflex."
  (let* ((st (lb e)) (k (ai-table e :switch))
         (why (and (lb-ai-out-ok-p (gauges-fs (gauges e)))
                   (cond ((lbs-kin-last st) (if (eq (lbs-kin-contact st) :block) :block :string))
                         ((< (gauges-gg (gauges e)) (getf k :gg 40)) :gauge)))))
    (if (and why (kit-command-ok-p e :sig))
        (progn (setf (lbs-kin-last st) nil)
               (lb-count e (case why (:block :ai-switch-block) (:string :ai-switch-string) (t :ai-switch-gauge)))
               (why b :switch-out :sig))
        (lb-ai-stance-in e b s d))))

(defun lb-ai-en-stick (e f)
  "His CPU's stick through EN's mobile lines (values toward strafe): out past its :zone range's far end in (12 m), under its
near end back (6 m), and always across the opponent's line on its current strafe (BRAIN-STRAFE). No roll."
  (let* ((b (brain e)) (d (fighter-dist f)) (z (getf (ai-table e :ranges) :zone '(6.0 12.0))))
    (values (cond ((< d (first z)) -1.0) ((> d (second z)) 1.0) (t 0.0)) (if b (brain-strafe b) 1.0))))

(defun lb-ai-en-next (e f mv)
  "His CPU in an EN string, on a line frame: the same button's next link is latched (J lines, K fans: to the third), unless
one is already or its lines would eat into the reserve (LB-AI-LAY-OK-P, decision 34). No roll: the string is finished
while he walks (DUEL_LILLE §22.2)."
  (let ((c (if (eq (mv-kind mv) :quick) :q :f)))
    (when (and (null (fighter-queued f)) (kit-next (fighter-kit f) (mv-name mv) c)
               (lb-ai-lay-ok-p (gauges-fs (gauges e)) (if (eq c :q) :j :k)))
      (setf (fighter-queued f) c))))

(defun lb-opp-trace (e b s d)
  "A CPU facing EN (his kit's :opp-reflex, :opp-trace (:p)): while his TENSHIN is ready (it would materialise every
trace), standing on one of his traces it has seen (laid at least its perception delay ago) newer than the ones it rolled
for: one roll for the new ones, :p x the difficulty (OPP-CHANCE): a sideways Step off that line (LINE-OFF-STRAFE). Rooted
forms can't."
  (declare (ignore s d))
  (let* ((o (opp-of e)) (k (getf (kit-ai (kit-of o)) :opp-trace)))
    (when (and k (not (kit-rooted (kit-of e))) (lb-switch-ready-p o))
      (let* ((st (lb o)) (p (pos-of e)) (hr (+ (body-hurt-r (model-body (model e))) *ai-line-margin*)) (on nil) (newest 0))
        (do-entities (h (hz hazard))
          (let ((dd (hazard-data hz)))
            (when (and (eql (hazard-owner hz) o) (lbh-p dd) (lbh-live dd) (>= (hazard-age hz) (brain-delay b)))
              (setf newest (max newest (lbh-id dd)))
              (when (and (> (lbh-id dd) (lbs-opp-roll st))
                         (<= (line-dist (hazard-x hz) (hazard-z hz) (hazard-yaw hz) 0.6 *lb-trace-len* (aref p 0) (aref p 2))
                             (+ (lbh-width dd) hr))
                         (or (null on) (> (lbh-id dd) (lbh-id (hazard-data on)))))
                (setf on hz)))))
        (when on
          (setf (lbs-opp-roll st) newest)
          (lb-count o :opp-trace-roll)
          (when (< (sim-rnd01) (opp-chance (getf k :p 0.0) (brain-difficulty b)))
            (lb-count o :opp-trace-step)
            (let ((q (pos-of o)))
              (setf (brain-strafe b) (f32 (line-off-strafe (hazard-x on) (hazard-z on) (hazard-yaw on) (aref p 0) (aref p 2)
                                                           (aref q 0) (aref q 2)))))
            (why b :trace-step :side-step)))))))

;;; ================================================================ debug: tests, the pacing log (debug.lisp dispatches)
(defun lille-acc-reset () (dolist (st (coerce *lb* 'list)) (setf (lbs-acc st) nil)))

(defun lille-acc-line ()
  "After a gate row: a \"duel lille\" line per side that played him (the pacing log, docs/duel/DUEL_LILLE.md §13)."
  (dolist (e (list *p1* *p2*))
    (when (and (entity-alive-p e) (eq (fighter-character (fighter e)) :lille))
      (let ((st (lb e)))
        (log-msg "duel lille ~a seed ~d awakened ~a form ~a eyes ~d sealed ~a ~{~(~a~) ~a~^ ~}" (side-name e) *match-seed*
                 (gauges-awakened (gauges e)) (fighter-form (fighter e)) (lbs-eyes st) (lbs-sealed st) (lbs-acc st))))))

(defun lille-probe-line (tag)
  (let ((g1 (gauges *p1*)) (g2 (gauges *p2*)) (st (lb *p1*)))
    (log-msg "duel probe lille ~a t ~d p1 ~a ~a r~d k~d eyes ~d revive ~a sealed ~a gg ~d | p2 ~a r~d gg ~d"
             tag *match-tick* (fighter-form (fighter *p1*)) (state-of *p1*) (gauges-reishi g1) (gauges-konpaku g1)
             (lbs-eyes st) (bankai-ready-p *p1*) (lbs-sealed st) (round (gauges-gg g1))
             (state-of *p2*) (gauges-reishi g2) (round (gauges-gg g2)))))

(defun lille-test (k)
  "79000+k (human P1 Lille, P2's CPU off unless noted; a \"duel probe lille\" line): 0 the base form 2.2 m from Kenpachi;
1 the base form 14 m from Kenpachi (the stance with L); 2 / 3 / 4 forced JILLIEL EN / its MUJITTAI / the owl 5 m from
Kenpachi (4: the owl's EN, decision 36); 5 JILLIEL EN with 3 Konpaku (P revives: decision 16); 6 the base form 12 m from a
Kenpachi CPU; 7 / 8 the owl KIN 6 m from Kenpachi, Trompete started, P2 reflecting it by a guard pressed on f54 / a Hoho on
f52 (*LB-REFLECT-TEST*); 9 the base form 10 m from a Yamamoto CPU (the eye); 10-13 eye pips 0-3 (in the running match);
14 / 15 forced JILLIEL KIN / its MUJITTAI 5 m from Kenpachi (rework R); 16 / 17 / 18 forced owl KIN / owl EN MUJITTAI / owl
KIN MUJITTAI 5 m from Kenpachi (decision 36); 20 P1 and P2 both Lille CPUs (the mirror) 12 m apart."
  (flet ((setup (c2 form dist &key cpu)
           (ensure-battle :lille c2 :cpu cpu)
           (when (brain *p1*) (setf (brain-off (brain *p1*)) (not cpu)))
           (unless (eq (fighter-form (fighter *p1*)) form) (force-form *p1* form))
           (place *p1* *p2* dist)
           (setf (gauges-reiatsu (gauges *p1*)) *reiatsu-max*)))
    (setf *lb-reflect-test* nil)
    (case k
      (0 (setup :kenpachi :base 2.2))
      (1 (setup :kenpachi :base 14.0))
      (2 (setup :kenpachi :jilliel 5.0))
      (3 (setup :kenpachi :jilliel-mujittai 5.0))
      (4 (setup :kenpachi :shin 5.0))
      (5 (setup :kenpachi :jilliel 5.0) (setf (gauges-konpaku (gauges *p1*)) 3))   ; (decision 16: <= 4 Konpaku is enough)
      (6 (setup :kenpachi :base 12.0) (setf (brain-off (brain *p2*)) nil))
      ((7 8) (setup :kenpachi :shin-kin 6.0) (setf *lb-reflect-test* (if (= k 7) :guard :hoho))
       (force-cmd *p1* :sp2))
      (9 (setup :yamamoto :base 10.0) (setf (brain-off (brain *p2*)) nil))
      ((10 11 12 13) (setf (lbs-eyes (lb *p1*)) (- k 10)))
      (14 (setup :kenpachi :jilliel-kin 5.0))
      (15 (setup :kenpachi :jilliel-kin-mujittai 5.0))
      (16 (setup :kenpachi :shin-kin 5.0))
      (17 (setup :kenpachi :shin-mujittai 5.0))
      (18 (setup :kenpachi :shin-kin-mujittai 5.0))
      (20 (setup :lille :base 12.0 :cpu t)))
    (lille-probe-line (format nil "test ~d" k))))

(defun lille-reflect-test-step (e f)
  "Debug 79007 / 79008 (*LB-REFLECT-TEST*), from E's Trompete (F his fighter): the opponent's (CPU-off) brain presses guard
on Trompete's f54 and holds it, or Hoho on f52 (pressed at the end of the step before: a scripted reflector)."
  (let* ((o (opp-of e)) (b (brain o)) (sf (fighter-sf f)))
    (when b
      (cond ((and (eq *lb-reflect-test* :guard) (= sf 53)) (ai-press b :guard 200 :act :hold))
            ((and (eq *lb-reflect-test* :hoho) (= sf 51)) (ai-press b :step 1 :modded t :act :hoho))))))

(defun lille-debug (c)
  "His debug commands (debug.lisp *CHAR-DEBUG*, the range 79000-79999, docs/duel/DUEL_GAMEPLAY.md): 79000+k LILLE-TEST k."
  (cond ((< c 79100) (lille-test (- c 79000)))
        (t (log-msg "duel lille: no debug command ~d" c))))
(pushnew '(79000 79999 lille-debug) *char-debug* :test #'equal)

;;; ================================================================ batch 3b (2026-10-06): the HUD hooks, the cinematics, stills
;;; (DUEL_LILLE §9, §10, "Built: art, HUD, cinematics"). Cosmetic only: the art, the HUD and the cinematics' looks live in
;;; lille-art.lisp; this section hangs them on his kits (after DEFKIT) and holds the five scripts.

;; his kit meter (hud.lisp: the :draw row, the portrait :label, the BANKAI prompt renamed 「P  REVIVE」 in gold) and the HUD /
;; look hooks (:hud-guard MUJITTAI's jade outline, :deck the one-hand ring's eye ticks, :body-alpha MUJITTAI's see-through
;; column, :charge his muzzle glint instead of the fire charge), on every form. Not on the host (no lille-art there).
(when (fboundp 'lille-hud-meter)
  (let ((meter (list :name "ME" :max 3 :draw 'lille-hud-meter :label 'lille-hud-label
                     :bankai-prompt (list :key "P  REVIVE" :right "KP+  REVIVE" :pad "BACK  REVIVE" :one-hand "AWAKEN  REVIVE"
                                          :rgb (symbol-value '*c-lb-revive*)))))
    (dolist (form '(:base :jilliel :jilliel-mujittai :jilliel-kin :jilliel-kin-mujittai :shin :shin-mujittai :shin-kin
                    :shin-kin-mujittai))
      (let ((k (find-kit :lille form)))
        (setf (kit-meter k) meter
              (kit-hooks k) (list* :hud-guard 'lille-hud-guard :deck 'lille-ring :body-alpha 'lille-body-alpha
                                   :charge 'lille-charge (kit-hooks k)))))))

;;; The cinematics (60 Hz, review-3 pacing: fewer, longer shots; unskippable; every shot SHOT-ON its subject). He wears
;;; white: the black card, the back-rim in his form's colour (jade, the owl's gold). Each script's looks are driven from
;;; its frame by LILLE-DRAW (lille-art.lisp: the wings unfolding, the jade turning gold, the trumpet forming), so a
;;; skipped or aborted script leaves nothing behind (CINE-END's REFRESH-LOOK restores his body).
(defcine lb-jilliel-cine (a v :len 186 :hold 90)
  "The awakening 神の裁き JILLIEL (§10.1, ch. 646): close on the face, the left eye shut under the mark, silence; the eye
opens (the third time), the mark flares jade, a 1 f negative; the black card, jade back-rim: 「三度も眼を開かされるとは 異端に
等しい」, then the brush 神の裁き / JILLIEL as he becomes the column; the cocoon: eight wings unfold one pair per 8 f, the
halo draws itself; from below, the winged column hovering, the opponent small."
  (at 0 (setf (model-body (model a)) (find-body :lille) (model-weapon (model a)) :diagramm)   ; the base face first
      (cine-clip a :lb-stance :blend 0) (cine-clip v (kit-stance (kit-of v)) :blend 6)   ; (no held pose: the
      (hold-pose v 12) (freeze 12) (impact-frame :negative 2) (silence 30)                  ; gameplay one is Jilliel's)
      (shot-on a 14 0.95 1.74 :look 1.72) (lens 36))
  (during (0 30) (shot-on a 14 (- 0.95 (* 0.12 u)) 1.74 :look 1.72))
  (at 30 (impact-frame :negative 1) (play-sfx :lb-lock) (play-sfx :hoho-out))
  (during (30 60) (shot-on a 14 (- 0.83 (* 0.13 u)) 1.74 :look 1.73))
  (at 60 (card :black a) (back-rim 60 0.61 0.77 0.67) (shot-on a 20 4.4 0.9 :look 1.3 :off 0.9) (lens 42)
      (caption "三度も眼を開かされるとは" :kanji2 "異端に等しい" :reading "SANDO MO ME WO HIRAKASARERU TO WA" :sub "ITAN NI HITOSHII"
               :side 0)
      (play-sfx :awaken-rise :pitch 0.8))
  (at 92 (setf (model-body (model a)) (find-body :lille-jilliel) (model-weapon (model a)) nil)
      (cine-clip a :lb-w-fold :blend 4) (impact-frame :negative 1) (play-sfx :awaken-boom)
      (caption "神の裁き" :reading "JILLIEL" :sub "VOLLSTANDIG" :side 0))
  (at 120 (card nil) (caption-exit) (shot-on a 32 3.6 1.4 :look 1.9) (lens 55) (cine-clip a :lb-w-stance :blend 12)
      (play-sfx :hoho-out))
  (at 128 (play-sfx :hoho-out)) (at 136 (play-sfx :hoho-out))
  (during (120 160) (shot-on a 32 (+ 3.6 (* 0.8 u)) 1.4 :look 1.9))
  (at 160 (shot-on a 165 6.5 0.25 :look 2.2) (lens 62)))

(defcine lb-kikon-cine (a v :len 168 :hold 90)
  "The base Kikon 万物貫通 (§10.2, ch. 601-602): beat 0, the aim held; over his shoulder down the barrel, the reticle (the
eye mark) closing round him, silence; the shot: the jade line through everything; on him: his silhouette on the white
card, a cross-shaped hole of light through it, held; the Konpaku shatter; the last card 万物貫通 / THE X-AXIS."
  (at 0 (face-each-other a v) (cine-clip a :lb-aim :blend 2) (cine-clip v :sh-bound :blend 4)
      (hold-both a v 10) (impact-frame :negative 2) (play-sfx :lb-lock))
  (at 10 (if (portrait-p)                       ; over his shoulder, the barrel (portrait: from straight behind and above,
             (shot-on a 162 5.4 2.6 :look 1.2 :ahead 2.5)  ; his back low in the tall frame, the line rising to the reticle)
             (shot-on a 152 2.7 1.9 :look 1.4 :ahead 2.2))
      (lens 40) (silence 50))
  (during (10 60) (vfx-lb-reticle-view v (- 1.0 (/ (- cf 10) 50.0))))
  (at 60 (cine-clip a :lb-fire :blend 1) (impact-frame :negative 2) (play-sfx :lb-crack) (shake 0.25 0.3))
  (during (60 76) (vfx-lb-shot-line a (- 1.0 (/ (- cf 60) 16.0))))
  (at 66 (shot-on v 20 3.2 1.25 :look 1.2) (lens 50) (cine-clip v :sh-kikon-victim :blend 3) (card :white v) (silhouette-black v))
  (during (66 120) (vfx-lb-cross-hole v (min 0.95 (/ (- cf 64) 6.0))))
  (at 72 (hold-both a v 44) (silence 44))
  (at 118 (impact-frame :negative 2) (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 2))
      (play-sfx :konpaku-shatter) (shake 0.2 0.3))
  (at 122 (unsilhouette) (card nil) (impact-frame :manga 10))
  (at 130 (card :black a) (back-rim 38 0.61 0.77 0.67) (shot-on a 20 4.2 0.9 :look 1.25 :off 0.9) (lens 42)
      (cine-clip a :lb-stance :blend 8)
      (caption "万物貫通" :reading "THE X-AXIS" :sub "BANBUTSU KANTSU  KIKON" :side 0)))

(defcine lb-revive-cine (a v :len 180 :hold 120)
  "The revival 真の姿 (§10.3, ch. 649-650): the headless column falls still, silence 30 f; it rises into the air, the jade
turning to gold over 30 f, and the owl head grows on the S-neck from light; the caption 「武器では死なず 霊圧で首を落としても
尚死なない」; the wide shot: four stilt legs, the small spiked halo, one long arm raised."
  (at 0 (setf (model-body (model a)) (find-body :lille-jilliel) (model-weapon (model a)) nil
              (model-hide (model a)) (hide-set '(:jl-head)))   ; beheaded
      (cine-clip a :lb-w-fold :blend 3) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (hold-both a v 30) (silence 30) (shot-on a 35 4.2 1.1 :look 1.3) (lens 50))
  (at 30 (cine-clip a :lb-rise :blend 6) (play-sfx :awaken-rise :pitch 0.6) (shot-on a 25 5.4 0.6 :look 2.1) (lens 55))
  (during (52 94) (multiple-value-bind (x y z) (actor-point a 2.95)
                    (vfx-lb-light x y z (* 0.28 (min 1.0 (/ (- cf 52) 12.0))) (if (< cf 82) 0.9 (* 0.9 (/ (- 94 cf) 12.0))))))
  (at 66 (setf (model-body (model a)) (find-body :lille-shin) (model-hide (model a)) nil)
      (cine-clip a (kit-stance (kit-of a)) :blend 10) (impact-frame :negative 1) (play-sfx :awaken-boom))   ; (EN's: decision 38)
  (at 96 (card :black a) (back-rim 54 0.72 0.6 0.35) (shot-on a 20 5.4 1.3 :look 2.0 :off 0.9) (lens 42)
      (caption "武器では死なず" :kanji2 "霊圧で首を落としても尚死なない" :reading "BUKI DEWA SHINAZU" :sub "SHIN NO SUGATA" :side 0))
  (at 150 (card nil) (caption-exit) (shot-on a 28 7.5 0.6 :look 1.9) (lens 55) (cine-clip a :lb-o-reveal :blend 8)))

(defcine lb-jilliel-kikon-cine (a v :len 162 :hold 80)
  "The Jilliel Kikon 神の裁き (§10.4): beat 0, the wings aimed; the black card, 神の裁き / KAMI NO SABAKI, the 24 holes lit;
from the side, 24 jade lines out of the wings, the opponent pinned at their crossing; on him, held in silence; the
Konpaku shatter; the winged column."
  (at 0 (face-each-other a v) (cine-clip a :lb-w-aim :blend 2) (cine-clip v :sh-bound :blend 4)
      (hold-both a v 10) (impact-frame :negative 2) (play-sfx :awaken-rise))
  (at 10 (card :black a) (back-rim 50 0.61 0.77 0.67) (shot-on a 20 4.6 1.2 :look 1.8 :off 0.9) (lens 42)
      (caption "神の裁き" :reading "KAMI NO SABAKI" :sub "KIKON" :side 0))
  (at 60 (card nil) (caption-exit) (shot-on a 100 7.0 2.2 :look 1.6 :ahead 3.0) (lens 50) (play-sfx :lb-crack))
  (during (60 128) (vfx-lb-converge a v (min 0.95 (/ (- cf 58) 8.0))))
  (at 64 (cine-clip v :sh-kikon-victim :blend 3))
  (at 96 (shot-on v 25 3.4 1.4 :look 1.2) (lens 52) (hold-both a v 24) (silence 24))
  (at 120 (impact-frame :negative 2) (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3))
      (play-sfx :konpaku-shatter) (shake 0.25 0.35))
  (at 124 (impact-frame :manga 10))
  (at 132 (shot-on a 30 5.6 1.3 :look 1.7) (lens 50) (cine-clip a :lb-w-stance :blend 8)))

(defcine lb-trompete-cine (a v :len 186 :hold 90)
  "The owl Kikon 神の喇叭 (§10.4): beat 0, the fist at the beak, the note; the trumpet forming over him; the sound card,
神の喇叭 / TROMPETE, silence; the beam erases the horizon; the Konpaku shatter; and then there is silence."
  (at 0 (face-each-other a v) (cine-clip a :lb-o-trompete :blend 2) (cine-clip v :sh-bound :blend 4)
      (hold-both a v 10) (impact-frame :negative 2) (play-sfx :lb-trumpet))
  (at 10 (shot-on a 30 3.6 2.6 :look 2.4) (lens 50))
  (at 60 (card :black a) (back-rim 50 0.72 0.6 0.35) (shot-on a 62 6.0 1.6 :look 2.2 :off 0.9) (lens 42)
      (caption "神の喇叭" :reading "TROMPETE" :sub "KAMI NO RAPPA  KIKON" :side 0) (silence 50))
  (at 110 (card nil) (caption-exit) (shot-on a 118 9.0 3.0 :look 2.0 :ahead 8.0) (lens 60) (impact-frame :negative 2)
      (play-sfx :explode) (shake 0.4 0.5) (ui-flash 1.0 0.95 0.8 0.8 2.5))
  (during (110 150) (vfx-lb-horizon a (min 0.98 (- 1.6 (/ (- cf 110) 25.0)))))
  (at 116 (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 4)) (play-sfx :konpaku-shatter)
      (impact-frame :manga 10))
  (at 140 (silence 46) (shot-on a 30 8.5 1.0 :look 1.8) (lens 50) (cine-clip a (kit-stance (kit-of a)) :blend 10))
  (during (140 186) (setf *grade-desat* (min 0.5 (* 0.02 (- cf 140))))))

;;; stills and the consing probe (debug 79100-79199, DUEL_GAMEPLAY "Debug commands")
(defparameter *lb-cines* '(lb-jilliel-cine lb-kikon-cine lb-revive-cine lb-jilliel-kikon-cine lb-trompete-cine))
(defun lille-cine-at (i f)
  "Stills: cinematic I (*LB-CINES*) with P1 Lille 6 m from Kenpachi, in its form, held at frame F; when it already runs it
continues to F."
  (let ((name (nth i *lb-cines*)))
    (unless (and *cine* (eq (cine-name *cine*) name))
      (abort-cine)
      (setf *cine-hold* nil)
      (ensure-battle :lille :kenpachi) (place *p1* *p2* 6.0)
      (force-form *p1* (nth i '(:jilliel :base :shin :jilliel :shin)))
      (start-cine name *p1* *p2*))
    (when *cine* (setf *cine-hold* t (cine-hold *cine*) f))))

(defun lille-cons-probe ()
  "79195: bytes consed by 10 draws of his :draw hook, of each of his live hazards' looks (the traces' LB-TRACE-LOOK
included) and of his HUD meter, guard outline and ring, in the running scene (a \"lille consing\" line; the scripts call it
in each form and look)."
  (let* ((e *p1*) (kit (kit-of e)) (hz-n 0))
    (macrolet ((per (form) `(let ((c0 (cons-bytes))) (dotimes (i 10) ,form) (- (cons-bytes) c0))))
      (let ((draw (per (lille-draw e 0.016f0)))
            (looks (let ((c0 (cons-bytes)))
                     (dotimes (i 10) (do-entities (h (hz hazard))
                                       (when (eql (hazard-owner hz) e)
                                         (incf hz-n)
                                         (if (eq (hazard-look hz) 'lb-trace-look) (lb-trace-look hz 0.016f0) (lb-look hz 0.016f0)))))
                     (- (cons-bytes) c0)))
            (meter (per (lille-hud-meter e kit 10.0 10.0 100.0 4.0 nil 1.0 nil nil nil)))
            (guard (per (lille-hud-guard e 10.0 10.0 100.0 4.0 nil 2 1.0)))
            (ring (per (lille-ring e 100.0 100.0 2.0))))
        (log-msg "lille consing (10 draws, B): form ~a draw ~d looks ~d (~d hazards) meter ~d guard ~d ring ~d"
                 (fighter-form (fighter e)) draw looks (floor hz-n 10) meter guard ring)
        (log-msg "lille consing reads (10 calls, B): fighter ~d pos ~d yaw ~d lb ~d alpha ~d eye-t ~d"   ; (an entity
                 (per (%lbt-fighter e)) (per (%lbt-pos e)) (per (%lbt-yaw e)) (per (%lbt-lb e)) (per (%lbt-alpha e)) ; lookup's cost)
                 (per (%lbt-eyet e)))))))

(defun lille-kin-look (e)
  "E (a Lille) as JILLIEL KIN for a still: the :jilliel-kin form once its kit exists (the rules batch), else JILLIEL wearing
the KIN body (:lille-jilliel-kin, until the next form change)."
  (if (assoc :jilliel-kin (gethash :lille *kits*))
      (force-form e :jilliel-kin)
      (progn (force-form e :jilliel) (setf (model-body (model e)) (find-body :lille-jilliel-kin)))))

(defvar *lb-front-k* 0 "Debug 79198's next look: 0 JILLIEL, 1 KIN, 2 the owl EN, 3 the owl KIN.")
(defun lille-art-debug (c)
  "79100 + 19 i + k (k 0-18): cinematic i (*LB-CINES*) held at frame 10 k; 79195 his looks' consing (LILLE-CONS-PROBE);
79196 P1's eye opens now (its look: a pip spent, nothing dodged); 79197 P1 Lille as JILLIEL KIN 5 m from Kenpachi (the
rework's rig, DUEL_LILLE §22.5); 79198 Lille as P2 facing the behind camera 4 m from Kenpachi, each call the next of JILLIEL
/ KIN / the owl EN / the owl KIN (the front view)."
  (let ((n (- c 79100)))
    (cond ((< n 95) (lille-cine-at (floor n 19) (* 10 (mod n 19))))
          ((= n 95) (lille-cons-probe))
          ((= n 96) (let ((st (lb *p1*)))                   ; a still of the eye opening (its look; nothing dodged)
                      (setf (lbs-eye-t st) *match-tick* (lbs-eyes st) (max 0 (1- (lbs-eyes st))))))
          ((= n 97) (ensure-battle :lille :kenpachi) (lille-kin-look *p1*) (place *p1* *p2* 5.0))
          ((= n 98) (ensure-battle :kenpachi :lille)
           (let ((k *lb-front-k*))
             (setf *lb-front-k* (mod (1+ k) 4))
             (case k (0 (force-form *p2* :jilliel)) (1 (lille-kin-look *p2*)) (2 (force-form *p2* :shin)) (t (force-form *p2* :shin-kin))))
           (place *p1* *p2* 4.0))
          (t (log-msg "duel lille: no debug command ~d" c)))))
(pushnew '(79100 79199 lille-art-debug) *char-debug* :test #'equal)

;;; ================================================================ rework R (2026-10-06): the traces' look (cosmetic, 0 B a frame)
(defun-fast lb-trace-look (hz rdt)
  "A live trace's look (HAZARD-DRAW; DUEL_LILLE §22.2): a faint jade line (the owl's gold, decision 36) on the floor from 0.6 m ahead of where it was
laid to the wall, its width pulsing (SP2's thick one wider); nothing once materialised (the X-axis line's flash, LB-LOOK,
takes over). Its numbers go through *LB-V* (lille-art.lisp's %LB-FLOOR-LINE): 0 B."
  (declare (single-float rdt))
  (setf rdt 0f0)                                        ; (unused: HAZARD-DRAW's signature)
  (let ((d (hazard-data hz)))
    (when (and (lbh-p d) (lbh-live d))
      (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
             (x0 (+ x (* 0.6f0 ux))) (z0 (+ z (* 0.6f0 uz)))
             (pulse (+ 0.8f0 (* 0.2f0 (f-sin (+ (* 5f0 (fx-clock)) (* 0.7f0 (i->f (mod (lbh-id d) 9))))))))
             (w (* pulse (if (eq (lbh-src d) :sp2) 0.14f0 0.04f0))))
        (declare (single-float x z yaw ux uz x0 z0 pulse w))
        (%lb-floor-line (if (> (lb-fxs (if (eql (hazard-owner hz) *p1*) 0 1) 15) 0.5f0) 3 1)   ; (the owl's: gold, decision 36;
                        x0 z0 ux uz (%lb-wall x0 z0 ux uz) w))))                                ;  LILLE-DRAW's flag, no lookup)
  nil)
