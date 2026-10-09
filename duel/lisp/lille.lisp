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
(defparameter *lb-switch-in* 7.0
  "TENSHIN in (EN -> KIN): the dash at him, at most this many metres at *LB-SWITCH-SPEED*, stopping *LB-SWITCH-STOP* short
(round 2, 2026-10-06, decision 25 「大幅提升變換戰型後的衝刺距離」: 3.5 before, both ways; decision 42, the user 2026-10-07:
「另外 L 轉成近戰時能跳躍的範圍要提升 1.3 倍」: 8.0 -> 10.4, the same 14 f; decision 43, the user 2026-10-07:
「接近距離也提升到 13m」: 10.4 -> 13.0; decision 49, the user 2026-10-07: 「覺醒後 L 的近遠切換移動距離減少 3m」: 13.0 -> 10.0;
decision 52, the user 2026-10-07: 「幫我試試看把覺醒後 L 的前衝距離改成 4.5m」: 10.0 -> 4.5; decision 53, the user 2026-10-07:
「前衝距離改成兩個 step + 0.5m 的長度」: two Steps (*STEP-DISTANCE*) + 0.5 = 5.5; decision 54, the user 2026-10-07:
「將前衝距離改成最多 7m」: 5.5 -> 7.0, 14 f at *LB-SWITCH-SPEED*).")
(defparameter *lb-switch-stop* 1.0
  "... this many metres short of him (KIN's J1 reaches 1.6; round 2, 2026-10-06: 1.5; decision 53, the user 2026-10-07:
「L 前衝停在對手前 1m」: 1.5 -> 1.0).")
(defparameter *lb-switch-out* (* 2 *step-distance*)
  "TENSHIN out (KIN -> EN): the dash away, metres at *LB-SWITCH-SPEED* (round 2, 2026-10-06; 3.5 before; decision 43, the
user 2026-10-07: 「後撤距離提升到 10m」: 7.0 -> 10.0; decision 49: 「減少 3m」: 10.0 -> 7.0; decision 53: 「後徹距離改成兩個
step 的長度」: two Steps (*STEP-DISTANCE*) = 5.0).")
(defparameter *lb-switch-speed* 30.0
  "TENSHIN's dash speed, m/s: the dash takes its distance / this (rounded up to whole frames, at most *LB-SWITCH-F*), and
the move goes on to its recovery from the dash's end (decision 53, the user 2026-10-07: 「移動改成固定速度而不是固定時間」,
30 m/s: TENSHIN out's 7 m over 14 f; before, every dash took *LB-SWITCH-F* frames whatever its length).")
(defparameter *lb-switch-f* 14
  "TENSHIN's longest dash, frames (the move's startup after its go frame; 12 before, round 2, 2026-10-06): from the dash's
end (LB-SWITCH-DASH-F; decision 53) his J / K cancel the rest, else the 8 f recovery follows.")
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
(defparameter *lb-snap-max* 10.0
  "A trace materialising turns about where it was laid toward the opponent by at most this many degrees, then hits along
the turned line (decision 41, the user 2026-10-07: 「C」, the materialise snap; the lead's 10: 1.7 m sideways at 10 m).
Decision 39's laying shot (1 damage, a 10 f flinch) is gone: 「我希望去除掉軌道設置時造成的 1 點傷害」.")
(defparameter *lb-fresh-scale* 0.1
  "A trace laid onto the opponent (its first frame touches him) slows the whole match to this time scale (SLOWMO,
everyone), whatever other traces he is on (decision 45, the user 2026-10-07: 「如果是才剛新生成的軌道就算重疊也一樣觸發時緩」; the
0.1 of decision 43: 「抱歉，應該是倍率改 0.1 然後可重複觸發」; a perfect Hoho's is 0.25) ...")
(defparameter *lb-fresh-secs* 0.2
  "... for this many real seconds (decision 47, the user 2026-10-07: 「新軌：0.1 倍速 0.2 秒」; decision 46's 0.1, 0.3 before,
decision 41's; a perfect Hoho's 0.45).")
(defparameter *lb-cross-scale* 0.2
  "The opponent stepping onto his old (already laid) live traces slows the whole match to this time scale (decision 41,
the user 2026-10-07: 「對手經過軌道的瞬間會有時緩」, 「全場慢動作」; 0.35 -> 0.5 -> 0.1 (decision 43); decision 45: 「而經過舊軌道
的時緩參數改成 0.3 倍速持續 1 秒」: 0.3; decision 47, the user 2026-10-07: 「舊軌：0.2 倍速 0.5 秒」: 0.2) ...")
(defparameter *lb-cross-secs* 0.5
  "... for this many real seconds (decision 47, the user 2026-10-07: 「舊軌：0.2 倍速 0.5 秒」; decision 46's 0.3, decision
45's 1.0 before) ...")
(defparameter *lb-cross-off* 10
  "... when he steps onto his live traces from off all of them, after at least this many sim frames off every one (the
traces count as one region: a K fan, lines laid side by side or a gap he crosses in under this many frames slow it once;
decision 44, the user 2026-10-07: plan A, 「用 A，N 先用 10 f」. Decision 43's 「可重複觸發」 had each trace fire on its own
edge, no re-arm; the lead's 30 steps before that).")
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
(defun lb-revive-ok-p (form free konpaku)
  "May P revive him into the owl (decision 16): any Jilliel FORM, FREE as for the first awakening (AWAKEN-STATE-P: idle,
guard, blockstun or a combo reaction past the Burst's hit; the user 2026-10-09, DUEL_KEN_REWORK §7; it was idle / guard),
with at most *BANKAI-KONPAKU* of his own KONPAKU (Kenpachi's rule exactly; no beheading needed)."
  (and (lb-jilliel-form-p form) free (<= konpaku *bankai-konpaku*) t))
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
(defun lb-snap-yaw (yaw x z ox oz)
  "A trace laid at (X Z) along YAW, materialising with the opponent at (OX OZ): its line turned toward him by at most
*LB-SNAP-MAX* degrees (decision 41)."
  (let ((dx (- ox x)) (dz (- oz z)))
    (if (< (+ (* dx dx) (* dz dz)) 1e-4)
        yaw
        (f32 (angle-wrap (turn-toward yaw (dir-yaw dx dz) (deg *lb-snap-max*)))))))
(defun lb-cross-kind (fresh now off)
  "Which slow motion his traces start this frame (decisions 44, 45): :FRESH when a trace laid this frame touches him (FRESH;
*LB-FRESH-SCALE*), else :CROSS when he stepped onto the live traces after OFF frames off all of them (LB-CROSS-P;
*LB-CROSS-SCALE*), else NIL."
  (cond (fresh :fresh) ((lb-cross-p now off) :cross)))
(defun lb-cross-p (now off)
  "Does his crossing slow the match (decisions 41, 44): he is on one of the live traces NOW, after OFF sim frames on none
(0 when he was on one last frame) >= *LB-CROSS-OFF*?"
  (and now (>= off *lb-cross-off*)))
(defun lb-cross-off-next (now off)
  "The frames off every live trace after this frame: 0 when he is on one (NOW), else OFF + 1 (capped at 9999)."
  (if now 0 (min 9999 (1+ off))))
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
;; (its clips: decision 56, 2026-10-08, the aura :lb-w-kikon rising into the ring, the strike :lb-w-kikon-fire at speed 1;
;; :lb-w-aim / :lb-w-fire at :clip-s 4 before)
(defmove :lb-w-kikon :kind :kikon :clip :lb-w-kikon :clip-2 :lb-w-kikon-fire :callout "KAMI NO SABAKI"
  :cine lb-jilliel-kikon-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.2 1.2) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 lb-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))

;;; ---------------------------------------------------------------- 遠 EN and 転身 TENSHIN (§22.2, decision 18)
;; EN's J / K / SP1: no hit window; on its first active frame each lays an X-axis trace (J one line, K a fan of three, SP1
;; SANREN's three), and the stick walks him at *LB-EN-WALK* through the whole move, facing kept on the opponent (LB-EN-TICK);
;; from the active end L cancels it into TENSHIN. Round 2 (decision 28, 2026-10-06, 「覺醒的遠程模式 J/K/SP1/SP2 的前後搖都
;; 大幅縮短。」): their startups and recoveries roughly halved, the active frames kept (the wing strings' were J 8/3/12, 7/3/13,
;; 9/3/18, K 17/4/21, 20/4/24 enter 6, 21/5/34 enter 7; SP1 12/22/24 lines f12/22/32; SP2 40/6/30); their own casts
;; :lb-e-q1 ... :lb-e-f3 at these frames (decision 50, 2026-10-07; KIN's wing clips at :clip-s / S speed before)
(defmove :lb-e-j1 :kind :quick :clip :lb-e-q1 :startup 4 :active 3 :recovery 6 :reach 1.6 :tick lb-en-tick
  :on-frame ((4 lb-en-lay)) :params (:trace :j))
(defmove :lb-e-j2 :kind :quick :clip :lb-e-q2 :startup 4 :active 3 :recovery 6 :reach 1.6 :tick lb-en-tick
  :on-frame ((4 lb-en-lay)) :params (:trace :j))
(defmove :lb-e-j3 :kind :quick :clip :lb-e-q3 :startup 5 :active 3 :recovery 9 :reach 1.7 :flags (:ender)
  :tick lb-en-tick :on-frame ((5 lb-en-lay)) :params (:trace :j))
(defmove :lb-e-k1 :kind :flash :clip :lb-e-f1 :startup 9 :active 4 :recovery 10 :reach 2.2 :tick lb-en-tick
  :on-frame ((9 lb-en-lay)) :params (:trace :k))
(defmove :lb-e-k2 :kind :flash :clip :lb-e-f2 :enter 3 :startup 10 :active 4 :recovery 12 :reach 2.2
  :tick lb-en-tick :on-frame ((10 lb-en-lay)) :params (:trace :k))
(defmove :lb-e-k3 :kind :flash :clip :lb-e-f3 :enter 4 :startup 11 :active 5 :recovery 17 :reach 2.3
  :flags (:ender) :tick lb-en-tick :on-frame ((11 lb-en-lay)) :params (:trace :k))
(defmove-copy :lb-e-j2s :lb-e-j2)
(defmove-copy :lb-e-k2s :lb-e-k2)
(defmove :lb-e-sanren :kind :sp :clip :lb-e-sanren :callout "SANREN" :startup 6 :active 14 :recovery 12 :reach 2.2
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
  :tick lb-switch-tick :on-frame ((0 lb-switch-go) (6 lb-switch-form))
  :params (:link *lb-switch-f*))
(defmove :lb-switch-in :kind :sig :clip :lb-w-tenshin-in :callout "TENSHIN" :startup 30 :active 0 :recovery 8
  :tick lb-switch-tick :on-frame ((16 lb-switch-go) (22 lb-switch-form))
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
;; 遠 EN (decision 36): Jilliel EN's J / K / SP1 / SP2 (decision 28's frames) with R - 1; their own casts :lb-oe-q1 ...
;; :lb-oe-f3 at these frames (decision 56, 2026-10-08, DUEL_LILLE §23.37; KIN's claw clips at :clip-s / S before); no hit
;; window: each lays traces (J one line, K a fan of three) on its first active frame while the stick walks him
;; (LB-EN-TICK, LB-EN-LAY); the owl's traces materialise as 裁きの光明's gold ground blasts (the look)
(defmove :lb-oe-j1 :kind :quick :clip :lb-oe-q1 :startup 4 :active 3 :recovery 5 :reach 1.7 :tick lb-en-tick
  :on-frame ((4 lb-en-lay)) :params (:trace :j))
(defmove :lb-oe-j2 :kind :quick :clip :lb-oe-q2 :startup 4 :active 3 :recovery 5 :reach 1.7 :tick lb-en-tick
  :on-frame ((4 lb-en-lay)) :params (:trace :j))
(defmove :lb-oe-j3 :kind :quick :clip :lb-oe-q3 :startup 5 :active 3 :recovery 8 :reach 1.7 :flags (:ender)
  :tick lb-en-tick :on-frame ((5 lb-en-lay)) :params (:trace :j))
(defmove :lb-oe-k1 :kind :flash :clip :lb-oe-f1 :startup 9 :active 4 :recovery 9 :reach 2.3 :tick lb-en-tick
  :on-frame ((9 lb-en-lay)) :params (:trace :k))
(defmove :lb-oe-k2 :kind :flash :clip :lb-oe-f2 :enter 3 :startup 10 :active 4 :recovery 11 :reach 2.3
  :tick lb-en-tick :on-frame ((10 lb-en-lay)) :params (:trace :k))
(defmove :lb-oe-k3 :kind :flash :clip :lb-oe-f3 :enter 4 :startup 11 :active 5 :recovery 16 :reach 2.3
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
       :awaken (:min-taken 150) :eye (:p 0.5) :sp-ender lb-ai-sp-ender :reflex lb-ai-reflex))

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
  :clip-map (:lb-sanren :lb-w-sanren)           ; SANREN (the base form's move) on his wings (a look; decision 56)
  :grid (:lb-w-j1 :lb-w-j2 :lb-w-j3 :lb-w-k1 :lb-w-k2 :lb-w-k3 :lb-w-j2s :lb-w-k2s)
  :ai (:intents (:approach 3 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.4 6.0) :pressure (1.4 2.4) :zone (3.0 6.0) :defend (3.0 6.0))
       :moves ((0.0 2.4 :q 4 :f 4 :breaker 1)
               (2.4 8.0 :step 1 :sp1 1 nil 1)
               (8.0 99.0 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.8 :block-string 0.3 :o-ender 0.5 :kikon-range 8.5
       :bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1) :stance (:p 0.6 :max 180 :gg 30)
       :switch (:gg 40) :sp-ender lb-ai-sp-ender :reflex lb-ai-reflex))

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

;;; ================================================================ his state (the sim's): a component on his fighter entity
(defcomponent lbs
  "Lille's state (LB): on his fighter entity, made on its first use, so a new match's fighter starts fresh."
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
  (dash-end 99 :type fixnum)             ; TENSHIN's dash ends (the link frame) on this frame of the move (decision 53)
  ;; round 2 (§23): the J / K latched in HOSHA / TENSHIN for their cancel (LB-LINK-TICK); ticks of TENSHIN's start and of
  ;; his last materialised trace's hit (his CPU's J after a switch in, the pacing log); the tick a J1 / K1 started from a
  ;; link and what it came from (:hosha / :tenshin: the pacing log's combos)
  (latch nil) (switch-t -1 :type fixnum) (trace-hit-t -1 :type fixnum) (link-t -1 :type fixnum) (link-from nil)
  (awake-t -1 :type fixnum) (revive-t -1 :type fixnum)   ; ticks of the awakening and the revival (the pacing log)
  (sig-origin nil)                        ; the combat log only: what opened his current combo (LB-SIG-LOG)
  (cross-off 9999 :type fixnum))          ; sim frames the opponent has been off all his live traces (decision 44)
(defvar *lb-reflect-test* nil "Debug 79007 / 79008: P2 reflects P1's Trompete by a guard (:guard) / a perfect Hoho (:hoho).")
(defun lb (e)
  "E's state: his eye, the seal, the shooting stance, the traces (his LBS component, attached on the first call: a new
fighter entity, a new match, gets a fresh one; Senjumaru's carry-over bug, DEVLOG §38-§39)."
  (or (lbs e) (let ((st (make-lbs))) (add-component e st) st)))
(defun lb-band (d) "The pacing log's distance band of D metres: :near (< 8) :mid (8-14) :far (>= 14)." (cond ((< d 8.0) :near) ((< d 14.0) :mid) (t :far)))
(defun lb-band-key (prefix d) (intern (format nil "~a-~a" prefix (lb-band d)) :keyword))

;;; hazard data: his hazards (the SABAKI lines, the shots' looks) carry one of these and LB-HZ as their hook
(defstruct (lbh (:conc-name lbh-))
  (kind nil)                              ; :sabaki (a hit) :shot :beam :lane (looks) :trace (EN's, §22.2)
  (len 0f0 :type single-float) (width 0f0 :type single-float)
  (lock nil)                              ; a look's colour: T jade (a locked shot), NIL ink
  ;; a trace: what laid it (:j :k :sp1 :sp2: its damage and drain, LB-TRACE-HITWIN), its id (they count up per side),
  ;; live (laid, not yet materialised), its line (a :cap volume in its own frame)
  (src nil) (id 0 :type fixnum) (live nil) (vol nil)
  (cross -1 :type fixnum)                 ; the tick his crossing onto it slowed the match (the look's flare)
  (fresh nil))                            ; a trace not yet tested against him (laid this frame: decision 45)

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
                  (or (lb-en-dry-p fs) (and (brain e) (not (lb-ai-lay-ok-p fs (if (eq command :q) :j :k))))))
             (and (brain e) (member command '(:breaker :kikon)) (lb-ai-veto-p e (brain e) command))))))

(defun lille-bankai-ok (e)
  "His kit's :bankai-ok (combat.lisp BANKAI-OK-P): P revives him into the owl from any Jilliel form where the first
awakening could be taken (AWAKEN-STATE-P; the user 2026-10-09: 「希望能像一般覺醒一樣只要達成條件就能發動」), with
<= *BANKAI-KONPAKU* Konpaku (decision 16: no beheading needed; LB-REVIVE-OK-P)."
  (let ((f (fighter e))) (lb-revive-ok-p (fighter-form f) (awaken-state-p e f) (gauges-konpaku (gauges e)))))

(defun lille-tick (e f g)
  "Per step (his kit's :tick, after the fighters stepped): EN's Hoho into KIN (decision 37: a Hoho started in an EN form,
LB-HOHO-TARGET), the eye (base), the stances' own perfect-Hoho drop (MUJITTAI), Trompete's reflect
check on its f59, the traces' end on the revival, KIN's last string (his CPU's switch out), the pacing log's clocks."
  (declare (ignore g))
  (let ((st (lb e)) (form (fighter-form f)))
    (let ((to (and (eq (fighter-state f) :hoho) (lb-hoho-target form))))   ; decision 37: a Hoho in EN lands in KIN (this
      (when to                                              ; step: the Hoho's frame 0, START-HOHO ran in the fighter system;
        (set-form e to)                                     ; the traces stay live for the next L)
        (pace e (if (lb-owl-form-p to) :owl-hoho-kin :hoho-kin))
        (setf form to)))
    (when (and (not (eq form :base)) (minusp (lbs-awake-t st)))
      (setf (lbs-awake-t st) *match-tick*) (pace e :awaken-tick *match-tick*))
    (when (and (lb-owl-form-p form) (minusp (lbs-revive-t st)))
      (setf (lbs-revive-t st) *match-tick*) (pace e :revive-tick *match-tick*)
      (lb-clear-traces e))                                  ; (gone on the revival, §22.2)
    (if (eq form :base) (lb-eye-step e f st) (setf (lbs-u-up st) 0))
    (unless (eq form :base) (lb-trace-cross e))            ; his live traces vs the opponent (decision 44)
    (cond ((lb-stance-form-p form)
           (when (and (eq (fighter-state f) :hoho) (fighter-perfect f))   ; his own counter strike is an attack: solid
             (set-form e (kit-drop-to (fighter-kit f)))
             (clog "~a MUJITTAI dropped: the perfect Hoho's counter" (side-name e)))
           (incf (lbs-stance st))
           (pace e :stance-frames)
           (when *pacing-log*
             (setf (getf (svref *pacing* (fighter-side f)) :stance-max)
                   (max (getf (svref *pacing* (fighter-side f)) :stance-max 0) (lbs-stance st)))))
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
      (pace e :eyes)
      (emit :sfx :hoho-out e)
      (when evo
        (setf (gauges-awaken g) (f32 *awaken-max*))
        (pace e :eye-evolution *match-tick*)
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
    (pace e :kamae)))

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
      (let* ((st (lb e)) (sf (fighter-sf f)) (vp (pilot-vpad (pilot e))) (b (lb-tick-brain e)))
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
    (multiple-value-bind (to st) (if (lb-tick-brain e) (values -1.0 0.0) (stick-relative e f))
      (multiple-value-bind (to st) (step-direction to st -1.0)
        (multiple-value-bind (dx dz) (world-dir e f to st)
          (set-slide e *lb-kamae-dash* 12 dx dz))))
    (setf (fighter-invuln f) (max (fighter-invuln f) *lb-dash-iframes*))
    (pace e :k-dash)
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
  (pace e (if (lbs-k-charged (lb e)) :shot-charged :shot-quick))
  (lb-spawn-look e :lane *lb-trace-len* 0.5 t)
  (emit :sfx :lb-lock e))

(defun lb-k-fire (e)
  "The stance's L fires (f10): the charged shot adds the distance bonus (FIGHTER-DMG-BONUS: the window's 40 + LB-X-BONUS),
the quick one is flat; the line's look (jade charged, ink quick)."
  (let* ((f (fighter e)) (d (fighter-dist f)) (charged (lbs-k-charged (lb e))))
    (setf (fighter-dmg-bonus f) (if charged (lb-x-bonus d) 0))
    (pace e (lb-band-key "FIRED" d))
    (lb-spawn-look e :shot 31.0 0.05 charged)
    (emit :sfx :lb-crack e)))

;;; ---------------------------------------------------------------- 遠 EN: the mobile lines and their traces (§22.2)
(defun lb-en-tick (e)
  "EN's J / K / SP1, each step: the stick walks him at *LB-EN-WALK* (frost and a cold field slow it as a walk; his CPU's
stick: LB-AI-EN-STICK), facing kept on the opponent; from the move's active end L cancels it into TENSHIN with its 2 f
wind-up (:lb-switch-in-c, decision 30; a human's press; his CPU's switch rule, LB-AI-SWITCH-IN-P)."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (when (and (eq (fighter-state f) :move) mv (eq (mv-tick mv) 'lb-en-tick) (eq (fighter-phase f) :main))
      (let ((v (motion-vel (motion e))) (b (lb-tick-brain e)))
        (multiple-value-bind (to st) (if b (lb-ai-en-stick e f) (stick-relative e f))
          (let ((m (sqrt (+ (* to to) (* st st)))))
            (when (>= m 0.2)
              (multiple-value-bind (dx dz) (world-dir e f to st)
                (let ((sp (* (frost-speed *lb-en-walk* (fighter-frost f)) (min 1.0 m) (/ 1.0 m))))
                  (setf (aref v 0) (f32 (* sp dx)) (aref v 2) (f32 (* sp dz)))
                  (field-slow! e f v))))))
        (turn-to-opp e f (deg *face-rate*))
        (when (and (>= (fighter-sf f) (+ (mv-s mv) (mv-a mv))) (zerop (fighter-lock f)))
          (let ((vp (pilot-vpad (pilot e))))
            (cond (b (let ((seen (lb-ai-seen b)))
                       (when (cond ((lb-ai-switch-in-p e b seen *lb-switch-windup-c*) (pace e :ai-switch-trace) t)
                                   ((lb-ai-web-cancel-p e b f seen) (lb-ai-web-fired e b) t)   ; (the web, HARD)
                                   ((lb-ai-xfire-cancel-p e b seen) (pace e :ai-xfire-cancel) t)   ; (the crossfire)
                                   ((lb-learn-cancel-p e b seen)))                  ; (a learner's trace read, §24.9)
                         (try-command e f :sig nil nil (lb-switch-cancel-move f)))))   ; (the 2 f cancel, decision 30)
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
           (laid (lb-trace-pay (gauges-fs g) src (length fans))) (cost (lb-trace-cost src)))
      (dolist (a (lb-trace-pick fans laid))
        (when (plusp cost) (spend-fs g cost))
        (lb-lay-trace e src a group))
      (when (< laid (length fans)) (pace e :traces-unpaid (- (length fans) laid)))
      (when (and (plusp laid) (lb-owl-form-p (fighter-form f))) (pace e :owl-traces laid)))
    (emit :sfx :rift-cut e)
    (when (member (mv-kind mv) '(:quick :flash))
      (setf (fighter-chained f) t)
      (when (lb-tick-brain e) (lb-ai-en-next e f mv)))))

(defun lb-live-traces (e)
  "His live traces: values how many and the oldest one's entity (the smallest id), or NIL."
  (let ((n 0) (old nil) (oid 0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (lbh-p d) (lbh-live d))
          (incf n)
          (when (or (null old) (< (lbh-id d) oid)) (setf old h oid (lbh-id d))))))
    (values n old)))

(defun lb-lay-trace (e src yaw-off &optional group)
  "One trace of SRC (:j :k :sp1 :sp2) from where he stands, at his facing + YAW-OFF degrees, *LB-TRACE-LEN* long: a hazard
with no hit (drawn by LB-TRACE-LOOK, faint jade on the floor) until his switch materialises it; at most *LB-TRACE-MAX*
live (the oldest dropped first: LB-TRACE-DROP-P). Laying it deals nothing (decision 41 took decision 39's laying shot
out); the opponent crossing it slows the match (LB-HZ's :step, LB-CROSS-P)."
  (let ((st (lb e)) (p (pos-of e)) (r (if (eq src :sp2) *lb-trace-r-thick* *lb-trace-r*)))
    (multiple-value-bind (n old) (lb-live-traces e)
      (when (lb-trace-drop-p n) (destroy-entity old) (pace e :traces-dropped)))
    (spawn-hazard :lb-trace e :x (aref p 0) :z (aref p 2) :yaw (+ (yaw-of e) (deg yaw-off)) :size *lb-trace-len*
                              :life *lb-trace-life* :hook 'lb-hz :look 'lb-trace-look :group group
                              :data (make-lbh :kind :trace :src src :id (incf (lbs-trace-n st)) :live t :fresh t
                                              :len (f32 *lb-trace-len*) :width (f32 r)
                                              :vol (make-vol :cap (list 0.6 *lb-trace-len* 1.2 r))))
    (pace e :traces)))

(defun lb-trace-materialise! (d mult)
  "Trace data D at a switch: a live one stops being live and gives the hit it deals now (LB-TRACE-HITWIN x MULT); a
materialised one, NIL (each materialises once)."
  (when (lbh-live d)
    (setf (lbh-live d) nil)
    (lb-trace-hitwin (lbh-src d) mult)))

(defun lb-materialise (e)
  "TENSHIN's frame 0: every live trace of his turns toward the opponent (at most *LB-SNAP-MAX*: LB-SNAP-YAW, decision 41)
and becomes a 2-frame hit along the turned line (once; the hits of one switch count as one combo), the X-axis line's look
flashes along it (the owl's: 裁きの光明's gold ground blasts, :judge; decision 36; its Trompete trace:
KIN Trompete's blast, :beam at the move's width, decision 40), and it is gone after."
  (let ((mult (lb-as-trace-mult e (kit-mult (kit-of e)))) (looks nil) (q (pos-of (opp-of e))))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (lbh-p d))
          (let ((hw (lb-trace-materialise! d mult)))
            (when hw
              (setf (hazard-yaw hz) (lb-snap-yaw (hazard-yaw hz) (hazard-x hz) (hazard-z hz) (aref q 0) (aref q 2))
                    (hazard-hw hz) hw (hazard-hits-left hz) 1 (hazard-life hz) (+ (hazard-age hz) 3))
              (push (list (if (eq (lbh-src d) :sp2) :beam :shot) (hazard-x hz) (hazard-z hz) (hazard-yaw hz) (lbh-width d)) looks))))))
    (if (lb-owl-form-p (fighter-form (fighter e)))              ; the owl's: 裁きの光明, gold blasts along the ground (decision 36)
        (dolist (l looks)
          (destructuring-bind (kind x z yaw w) l
            (if (eq kind :beam)                                   ; EN Trompete's thick trace: KIN Trompete's blast (the user,
                (progn (lb-spawn-look-at e :beam x z yaw 31.0     ; 2026-10-06: 「請改成跟近戰版本一樣」)
                                         (getf (mv-params (find-move :lb-trompete)) :width) t)
                       (emit :sfx :explode e))
                (lb-spawn-look-at e :judge x z yaw 31.0 w (if (> w 0.9) :thick t)))))
        (dolist (l looks) (destructuring-bind (kind x z yaw w) l (declare (ignore w)) (lb-spawn-look-at e kind x z yaw 31.0 0.05 t))))
    (when looks (pace e :materialised (length looks)))))

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

(defun lb-switch-dash-f (dist)
  "Frames TENSHIN's dash of DIST metres takes at *LB-SWITCH-SPEED* (rounded up; at most *LB-SWITCH-F*; 0 for none):
decision 53, a fixed speed instead of a fixed time."
  (if (> dist 0.01) (min *lb-switch-f* (max 1 (ceiling (* 60.0 dist) *lb-switch-speed*))) 0))

(defun lb-switch-go (e)
  "TENSHIN f0: every live trace materialises (LB-MATERIALISE); the flash-step dash over *LB-SWITCH-F* at him (EN -> KIN,
LB-SWITCH-DIST, free) or away (KIN -> EN, *LB-SWITCH-FS* flash step: LB-SWITCH-PRICE) at *LB-SWITCH-SPEED*, its end
(the link frame) kept (LBS-DASH-END; decision 53), iframes f0-8; the target form fixed now (LB-SWITCH-FORM at f6, or at
the dash's end if sooner: LB-SWITCH-TICK); the J / K latch cleared (LB-LINK-TICK)."
  (let* ((f (fighter e)) (st (lb e)) (p (pos-of e)) (to (lb-switch-target (fighter-form f)))
         (in (lb-kin-form-p to)) (k (if in 1.0 -1.0)) (dist (lb-switch-dist in (fighter-dist f))) (n (lb-switch-dash-f dist)))
    (setf (lbs-switch-to st) to (lbs-switch-t st) *match-tick* (lbs-latch st) nil (lbs-dash-end st) (+ (fighter-sf f) n))
    (lb-materialise e)
    (when (plusp n)
      (set-slide e dist n (* k (- (fighter-ox f) (aref p 0))) (* k (- (fighter-oz f) (aref p 2)))))
    (setf (fighter-invuln f) (max (fighter-invuln f) *lb-dash-iframes*))
    (let ((price (lb-switch-price (fighter-form f)))) (when (plusp price) (spend-fs (gauges e) price)))
    (pace e (if in :switch-in :switch-out))
    (when (lb-owl-form-p to) (pace e (if in :owl-switch-in :owl-switch-out)))
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
    (pace e (lb-band-key "FIRED" d))
    (lb-spawn-look e :shot 31.0 0.05 t)
    (emit :sfx :lb-crack e)))

(defun lb-line-shot (e)
  "SANREN's shots (f12, f22, f32): the line's look."
  (pace e :sanren-shots)
  (lb-spawn-look e :shot (move-param e :len) 0.04 nil)
  (emit :sfx :rift-cut e))

(defun lb-lane-shot (e)
  "A Kikon module's lane (照準, 神の裁き, 神の喇叭): its look (the hit is the move's lane)."
  (lb-spawn-look e :lane (move-param e :len) 0.5 t)
  (emit :sfx :kikon-slash e))

(defun lb-beam-shot (e)
  "NIJUSHI-KO's / Trompete's first active frame: the beam's look."
  (pace e (if (eq (mv-name (fighter-move (fighter e))) :lb-trompete) :trompete-fired :nijushi-fired))
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
    (pace e (if (eq (mv-name (fighter-move f)) :lb-k-k) :taisha :hiren))
    (emit :sfx :hoho-out e)))

(defun lb-taisha-fire (e)
  "TAISHA f16: the mid-range bullet (the move's 12 m line, 60 flat: no distance bonus), the line's look."
  (pace e (lb-band-key "FIRED" (fighter-dist (fighter e))))
  (lb-spawn-look e :shot (move-param e :len) 0.05 nil)
  (emit :sfx :lb-crack e))

(defun lb-hosha-leap (e)
  "HOSHA f0: the forward leap, *LB-HOSHA-LEAP* m along his facing over *LB-HOSHA-LEAP-F* frames, stopping *LUNGE-STOP*
short of him (a lunge's rule); the J / K latch cleared."
  (let* ((f (fighter e)) (yaw (yaw-of e)) (dist (min *lb-hosha-leap* (max 0.0 (- (fighter-dist f) *lunge-stop*)))))
    (when (> dist 0.01) (set-slide e dist *lb-hosha-leap-f* (fwd-x yaw) (fwd-z yaw)))
    (setf (lbs-latch (lb e)) nil)
    (pace e :hosha)
    (emit :sfx :whoosh-light e)))

(defun lb-bullet (e)
  "HOSHA's bullets (f6, f10, f14): the short line's look from the muzzle (the hit is the move's window)."
  (pace e :hosha-shots)
  (lb-spawn-look e :shot (move-param e :len) 0.04 nil)
  (emit :sfx :rift-cut e))

(defun lb-hosha-tick (e)
  "HOSHA, each step: he turns at the move's :track while he leaps (to f14, the last bullet); the J / K link (LB-LINK-TICK)."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (<= (fighter-sf f) *lb-hosha-leap-f*))
      (turn-to-opp e f (track-step (mv-track (fighter-move f)))))
    (lb-link-tick e)))

(defun lb-link-frame-at (link switch sf go dash-end)
  "Pure: the link frame of a move whose :link is LINK (NIL: none, 99), at its frame SF: HOSHA's LINK; a TENSHIN's (SWITCH)
its dash's end DASH-END (decision 53: a fixed speed, so the end moves with the dash's length), read only after its dash
began (SF > GO, its :go): before, DASH-END is still the last switch's (a 2 f cancel enters at f14, past a 10 f TENSHIN
out's end: the ASSIST read it and decided in the wind-up, the user 2026-10-07: 「好像是輔助連段的問題？」)."
  (cond ((null link) 99)
        ((not switch) link)
        ((> sf go) dash-end)
        (t 99)))

(defun lb-link-frame (e mv)
  "The frame of MV (E's move) from which a latched J / K links (LB-LINK-FRAME-AT)."
  (let ((p (mv-params mv)))
    (lb-link-frame-at (getf p :link) (eq (mv-tick mv) 'lb-switch-tick) (fighter-sf (fighter e)) (getf p :go 0)
                      (lbs-dash-end (lb e)))))

(defun lb-link-tick (e)
  "HOSHA and TENSHIN (round 2, decisions 21, 25): a J / K pressed during the move is latched (a human's consumed; the last
press wins) and, from the move's link frame (LB-LINK-FRAME; HOSHA: its recovery, f16, once a bullet hit; TENSHIN: the
dash's end, always), cancels the rest into his form's J1 / K1 (TRY-COMMAND: EN's lay traces, KIN's and the base form's
hit). A HOSHA link chases him in its startup (FIGHTER-END-CHASE, the Breaker's J1 / K1 rule); a KIN one after TENSHIN in
did too until decision 53 (the user 2026-10-07: 「完全拿掉追擊」): it starts where the dash left him, 1 m short.
His CPU's link (LB-AI-LINK) is picked once."
  (let* ((f (fighter e)) (mv (fighter-move f)) (st (lb e)) (b (lb-tick-brain e)))
    (when (and (eq (fighter-state f) :move) mv (eq (fighter-phase f) :main) (zerop (fighter-lock f)))
      (let ((hosha (eq (mv-name mv) :lb-k-j)) (vp (pilot-vpad (pilot e))))
        (unless b
          (cond ((vpad-command-pressed-p vp :quick nil) (vpad-consume! vp :quick) (setf (lbs-latch st) :q))
                ((vpad-command-pressed-p vp :flash nil) (vpad-consume! vp :flash) (setf (lbs-latch st) :f))))
        (when (and b hosha (= (fighter-sf f) (lb-link-frame e mv)))   ; (his CPU: the guard read)
          (lb-ai-hosha-read e b (fighter-contact f)))
        (when (and (>= (fighter-sf f) (lb-link-frame e mv)) (or (not hosha) (eq (fighter-contact f) :hit)))
          (when (and b (null (lbs-latch st))) (setf (lbs-latch st) (lb-ai-link e f st hosha)))
          (let ((c (lbs-latch st)) (in (and (not hosha) (member (fighter-form f) '(:jilliel-kin :shin-kin)))))
            (when (and (member c '(:q :f)) (try-command e f c))
              (setf (lbs-latch st) nil (lbs-link-t st) *match-tick* (lbs-link-from st) (if hosha :hosha :tenshin))
              (when (and b hosha) (lb-ai-hosha-loop e (fighter e) b))   ; (HARD: L latched on the K1: HOSHA again)
              (when (and b in (eq c :q)) (lb-ai-route e (fighter e) b))  ; (HARD: J1 -> K2s -> K3, the crossfire's K3)
              (when hosha (setf (fighter-end-chase (fighter e)) t))   ; (TENSHIN's: none, decision 53)
              (pace e (if hosha :hosha-link :tenshin-link)))))))))

(defun lb-switch-tick (e)
  "TENSHIN's frames: no string chase (an L latched after a KIN K link starts as a chained follow-up, and MAIN-PHASE-STEP's
chase ran him at the opponent through the whole 14 f dash, eating the dash away: the bug the user found 2026-10-07,
「現在近戰 K 打完連擊後接到 L 後撤的距離會被限制住」; the dash's slide is the switch's only movement), then LB-LINK-TICK;
then, at the dash's end (LBS-DASH-END) with nothing linked, the rest of the startup is skipped: the 8 f recovery follows the
dash (decision 53, a fixed speed: a short dash, a short move). A dash ending before its f6 changes the form at its end,
before the link (its J / K is the new form's: the user 2026-10-07, the ASSIST's and the CPU's TENSHIN in -> J1 up close)."
  (halt! e)
  (let* ((f (fighter e)) (mv (fighter-move f)) (st (lb e)) (go (getf (mv-params mv) :go 0)))
    (when (< (fighter-sf f) go) (setf (lbs-dash-end st) 99))   ; (the wind-up: no link before this switch's own dash)
    (when (and (eq (fighter-phase f) :main) (> (fighter-sf f) go) (>= (fighter-sf f) (lbs-dash-end st)) (lbs-switch-to st))
      (lb-switch-form e))                                       ; (a dash shorter than 6 f: the form first, its J / K link)
    (lb-link-tick e)
    (when (and (eq (fighter-state f) :move) (eq (fighter-move f) mv) (eq (fighter-phase f) :main)
               (>= (fighter-sf f) go) (>= (fighter-sf f) (lbs-dash-end st)) (< (fighter-sf f) (1- (mv-s mv))))
      (setf (fighter-sf f) (1- (mv-s mv))))))

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
    (pace e (if group :misuji :sabaki))
    (emit :sfx :ground-crack e)))

(defun lb-trace-cross (e)
  "Per sim frame (LILLE-TICK): is the opponent on any of his live traces (each line's :cap against his hurt cylinder, as a
hit would test it)? A trace laid this frame onto him slows the whole match at *LB-FRESH-SCALE* for *LB-FRESH-SECS*,
whatever else he stands on (decision 45); else stepping onto them after *LB-CROSS-OFF* frames off all of them slows it at
*LB-CROSS-SCALE* for *LB-CROSS-SECS* (decisions 41, 44, 45: LB-CROSS-KIND; the user 2026-10-07: 「對手經過軌道的瞬間會有時緩」,
「全場慢動作」); the lines that started it flare (LBH-CROSS)."
  (let* ((o (opp-of e)) (st (lb e)) (now nil) (fresh nil) (on-old nil))
    (when (entity-alive-p o)
      (let ((q (pos-of o)) (b (model-body (model o))))
        (do-entities (h (hz hazard))
          (let ((d (hazard-data hz)))
            (when (and (eql (hazard-owner hz) e) (lbh-p d) (lbh-live d))
              (let ((yaw (hazard-yaw hz)))
                (when (vol-hit-p (lbh-vol d) (hazard-x hz) 0f0 (hazard-z hz) (f32 (fwd-x yaw)) (f32 (fwd-z yaw))
                                 (aref q 0) (aref q 1) (aref q 2) (body-hurt-r b) (body-hurt-h b) 0f0)
                  (setf now t)
                  (if (lbh-fresh d) (progn (setf fresh t) (setf (lbh-cross d) *match-tick*)) (push d on-old))))
              (setf (lbh-fresh d) nil))))
        (case (lb-cross-kind fresh now (lbs-cross-off st))
          (:fresh (slowmo *lb-fresh-scale* *lb-fresh-secs*)
                  (pace e :trace-fresh)
                  (emit :sfx :rift-open e))
          (:cross (dolist (d on-old) (setf (lbh-cross d) *match-tick*))
                  (slowmo *lb-cross-scale* *lb-cross-secs*)
                  (pace e :trace-cross)
                  (emit :sfx :rift-open e)))))
    (setf (lbs-cross-off st) (lb-cross-off-next now (lbs-cross-off st)))))

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
                  (:trace                               ; a trace's line (its :cap from where it was laid)
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
    (pace e (if (eq src :hoho) :reflect-hoho :reflect-guard))
    (hitstop *hitstop-breaker*)
    (emit :hit o e (aref p 0) (+ (aref p 1) 1.1) (aref p 2) *hitstop-breaker* nil dmg :sp)
    (unless (deal-damage o e dmg)
      (set-reaction e :stagger *lb-reflect-stun* (aref q 0) (aref q 2) 1.0))
    (clog "~a TROMPETE REFLECTED by ~a (~a): ~d, sealed" (side-name e) (side-name o) src dmg)))

;;; ---------------------------------------------------------------- the pacing log's hit hooks
(defun lb-sig-log (att def res mv hazard)
  "The combat log only (*COMBAT-LOG*: no sim state reads it): after a hit of his that is his signature by more than its
name (tools/aieval.py's whitelist, DUEL_LILLE §24.2), a \"Px lb-sig TAG\" line tagging the hit line just logged: charged (the
stance's charged X-Axis shot), hosha-link (the J1 / K1 a HOSHA hit linked into), trace-combo (a J / K hit in a combo a
materialised trace opened: trace -> TENSHIN -> J / K). A combo's opener is its first hit."
  (when (member res '(:hit :counter))                        ; (the hit lines tools/aieval.py reads)
    (let* ((st (lb att)) (f (fighter att))
           (kind (cond ((and hazard (lbh-p (hazard-data hazard))) (lbh-kind (hazard-data hazard))) (mv (mv-name mv)) (t :other))))
      (when (<= (fighter-combo-hits (fighter def)) 1)
        (setf (lbs-sig-origin st) kind))
      (let ((tag (cond ((null mv) nil)
                       ((eq (mv-name mv) :lb-k-shot) (and (lbs-k-charged st) "charged"))
                       ((not (member (mv-kind mv) '(:quick :flash))) nil)
                       ((eq (lbs-sig-origin st) :trace) "trace-combo")
                       ((and (not hazard) (eq (lbs-link-from st) :hosha) (eq (fighter-move f) mv)
                             (>= (lbs-link-t st) (- *match-tick* (fighter-sf f) 1)))
                        "hosha-link"))))
        (when tag (clog "~a lb-sig ~a" (side-name att) tag))))))

(defun lille-hit (att def res hw mv hazard ranged)
  "After a hit he dealt (his kit's :hit): a shot from >= *LB-FAR-KB* knocks back 2.0 m; the pacing log (shots hit / guarded
by band, damage by band, Trompete); the combat log's signature tags (LB-SIG-LOG)."
  (declare (ignore ranged))
  (when *combat-log* (lb-sig-log att def res mv hazard))
  (let ((x (member :x-axis (hw-flags hw))) (d (fighter-dist (fighter att))))
    (when x
      (case (contact-of res)
        (:hit (pace att (lb-band-key "HIT" d))
         (when (and mv (not hazard) (getf (mv-params mv) :bonus))
           (pace att (lb-band-key "DMG" d) (+ (hw-dmg hw) (fighter-dmg-bonus (fighter att))))
           (when (>= d *lb-far-kb*)
             (let ((p (pos-of att)) (q (pos-of def))) (set-slide def 2.0 12 (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)))))))
        (:block (pace att (lb-band-key "GUARDED" d))))
      (when (and mv (eq (mv-name mv) :lb-trompete))
        (pace att (if (eq (contact-of res) :hit) :trompete-hit :trompete-guarded))))
    (when (and hazard (lbh-p (hazard-data hazard)) (eq (lbh-kind (hazard-data hazard)) :trace))   ; a materialised trace
      (when (eq (contact-of res) :hit) (setf (lbs-trace-hit-t (lb att)) *match-tick*))
      (let* ((owl (lb-owl-form-p (fighter-form (fighter att)))) (fs (lb-trace-refund (contact-of res) owl)))
        (when (plusp fs)                                    ; its flash step back (decision 34; a fan's group: once;
          (pay-gauges (or (siphon-of att) att) 0.0 fs)      ; the owl's 5 / 2, decision 36)
          (pace att :trace-refund)
          (when owl (pace att :owl-trace-refund fs)))
        (when owl (pace att (if (eq (contact-of res) :hit) :owl-trace-hit :owl-trace-guarded))))
      (pace att (if (eq (contact-of res) :hit) :trace-hit :trace-guarded)))
    (when (and mv (member (mv-name mv) '(:lb-k-shot :lb-k-j :lb-k-k)))   ; the stance's branches
      (pace att (intern (format nil "~a-~a" (mv-name mv) (if (eq (contact-of res) :hit) "HIT" "BLK")) :keyword)))
    (let ((st (lb att)) (f (fighter att)))                  ; a J1 / K1 started from a link (round 2): its hit in the combo
      (when (and mv (not hazard) (lbs-link-from st) (eq (fighter-move f) mv) (eq (contact-of res) :hit)
                 (>= (lbs-link-t st) (- *match-tick* (fighter-sf f) 1)))
        (pace att (if (> (fighter-combo-hits (fighter def)) 1)
                          (if (eq (lbs-link-from st) :hosha) :hosha-combo :tenshin-combo)
                          (if (eq (lbs-link-from st) :hosha) :hosha-drop :tenshin-drop)))
        (setf (lbs-link-from st) nil)))))

(defun lille-struck (def att res hw mv hazard ranged)
  "After a hit he took (his kit's :struck): the stance's pacing (passes, Breaker breaks, crushes)."
  (declare (ignore att hw mv hazard ranged))
  (when (lb-stance-form-p (fighter-form (fighter def)))
    (case res
      (:blocked (pace def :passes)))
    (when (gauges-guardless (gauges def)) (pace def :stance-crushed)))
  (when (and (eq res :guard-break) (member (fighter-form (fighter def)) '(:jilliel :jilliel-kin :shin :shin-kin)))
    (pace def :stance-broken)))

;;; ================================================================ AI: his own CPU (DUEL_LILLE §11.2, §22; batch 3a, rework R)
;; the HARD layers' knobs (dream-rsi round 1, b3a2; DUEL_LILLE §24.8): defined before the functions that read them
(defparameter *lb-ai-close* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The sniper's step (dream-rsi b3a2, 2026-10-07): the hunt's stance on him free within 2 m (the hunt's override began at
2 m, so the shipped plan's TAISHA fired: 1.0 a match, 158 hits in 400 matches, 69 times hit, 31 perfect-Hohoed, ~35
damage a match taken after it) plans HOSHA (the spacing rule then: the HIRENKYAKU dash back, iframes f0-8, then HOSHA; or
TAISHA without the dash), and onto his whiff HOSHA at once (its bullet at f6, the composure holding ORANGE off).")
(defparameter *lb-ai-hunt* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The base form takes the shooting stance for HOSHA at an open opponent in *LB-AI-HUNT-BAND* (dream-rsi b1a0, 2026-10-07;
HOSHA's S6 lands under a HARD CPU's perception + guard raise).")
(defparameter *lb-ai-blow* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The blow-away aim (dream-rsi b3a2, 2026-10-07): the stance latched on a K link (the HOSHA loop's K1, the base K3) whose
hit blew him away planned TAISHA at the air (b3a1: 2.1 a match, the whiff's recovery ate the wake-up shot's window: 1.5
late HIRENKYAKUs, 0.6 hunts into his wake-up); now the stance dashes back (when it can pay) and holds L for the charged
X-Axis shot timed onto his first hittable frame (LB-AI-BLOW-STEP).")
(defparameter *lb-ai-held-aim* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The held aim (b1a2's; dream-rsi b3a1, 2026-10-07): the base form never steps in on a guard within the hunt's band:
within the generic guard-break range (or a long guard) the stance (TAISHA within 3 m, else the charged shot), else a
fresh guard is waited out; the stance never throws the quick shot at HARD (the charged one: his signature).")
(defparameter *lb-ai-link-k* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "HOSHA's link is K1 (dream-rsi b1a0, 2026-10-07): L after a K link reopens the stance (NORMAL: the shipped J1 / K1 roll).")
(defparameter *lb-ai-oki* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The wake-up shot 起き照準 (b1a1's; dream-rsi b3a1, 2026-10-07): a downed opponent gets the fully charged X-Axis shot timed
to land on his first hittable frame, from wherever the base form stands (the stance pressed LB-AI-OKI-LEAD frames before
he can be hit); while it waits for that frame, nothing else (no step-in into his wake-up).")
(defparameter *lb-ai-starve* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "EN starved of flash step switches in (free) only onto an opponent busy for its wind-up, never into KIN's neutral
(dream-rsi b1a0, 2026-10-07; v1's b1a0 rule).")
(defparameter *lb-ai-kin-run* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "KIN as the combo's vehicle (dream-rsi b1a0, 2026-10-07): free, nothing to punish, TENSHIN out as soon as its price +
*LB-AI-KIN-RUN-FS* is there (HARD wins 0.92 -> 0.96 at 80 seeds with the rest on).")
(defparameter *lb-ai-kin-run-fs* 9.0
  "... the flash step kept over TENSHIN out's price: three J lines, EN arrives able to snap (3 / 9 / 19 measured; 9 kept).")
(defparameter *lb-ai-siege* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The patient web (b1a1's; dream-rsi b3a1, 2026-10-07): EN lays its lines at a guarding (or warding) opponent too, and
waits (the web's switch still refuses a guard), instead of standing idle and leaving EN to the generic Breaker.")
(defparameter *lb-ai-rush-wary* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The hunt never answers his rush (b1a1's located bug of b1a0's hunt, which b3a0's file kept; dream-rsi b3a1, 2026-10-07):
a Kikon or Breaker in its aura, dash or follow-up is \"a move\" to the hunt, and the hunt (the kit's reflex) ran before the
generic answers to it (guard, Step a red one's follow-up, J into a Breaker).")
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

;; the sniper's discipline (dream-rsi round 1, cell b3a0, 2026-10-07; DUEL_LILLE §24): HARD-only levels on top of b1a0's
;; layer (the AI section's end), 1 at HARD, 0 at EASY / NORMAL (the shipped CPU, no new roll there); deterministic rules
(defparameter *lb-ai-space* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The spacing rule's level by difficulty (dream-rsi b3a0, 2026-10-07): the shooting stance plans HOSHA only where its first
bullet lands outside the generic ORANGE window (ai.lisp AI-ORANGE-P: a :sig hit with him inside J1's reach + 0.2 m, rolled
0.4 at HARD, then a plain J1 string and ~100 flash step burnt: 2 a match, 5 % of his damage plain, under b1a0's loop); else
TAISHA on a reeling opponent (the back-slide, its bullet from >= 3 m), the HIRENKYAKU dash back then HOSHA on an open one
(LB-AI-SPACE-PLAN).")
(defparameter *lb-ai-space-near* 2.4
  "... HOSHA from under this many metres lands its first bullet (f6, the leap 6/14 done, stopping *LUNGE-STOP* short) inside
J1's reach + 0.2 (1.65 m): from d, d - 6/14 (d - 0.95) <= 1.65 under 2.18 m, + a margin (dream-rsi b3a0, 2026-10-07) ...")
(defparameter *lb-ai-space-rush* 5.0
  "... + this many while he comes in (a run, a Step, a rush's dash, as the stance's f6 sees him: the dash closes the gap in
HOSHA's 6 f; 1.2 measured: more ORANGEs, signature 0.966 / 0.965 vs 0.970 / 0.972 at seeds 1-40 / 41-80; b3a0).")
(defparameter *lb-ai-xfire* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The crossfire's level (dream-rsi b3a0, 2026-10-07): KIN's K3 crumple (40 f) latches L, TENSHIN out (10 m away), its link
EN's J1 laid at him, the line materialised at once, TENSHIN in, the KIN string again: the trace combo carried on through
both modes (LB-AI-XFIRE-P; 5 + 14 + 7 + 2 = 28 f from K3's hit to the materialise, inside the crumple).")
(defparameter *lb-ai-xfire-life* 45
  "Frames from the crossfire's latch during which TENSHIN out's link and EN's cancel belong to it (dream-rsi b3a0).")
(defparameter *lb-ai-clean* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "His CPU's refusals (LILLE-OK's CPU clause, LB-AI-REFUSE-P; dream-rsi b3a0, 2026-10-07): the Breaker (a HARD opponent's
J beats it, ~150 damage a match taken in the punish after it) and a non-red O ender where an SP or the crossfire combos off
the same link instead (a non-red Kikon is guarded or perfect-Hohoed more often than it lands).")
(defparameter *lb-ai-guard-read* 2
  "The guard read (dream-rsi b3a0, 2026-10-07): after this many HOSHAs in a row guarded, the hunt's next stance pierces with
TAISHA (through guard) once, then tries HOSHA again (LB-AI-HOSHA-READ). Inert against the frozen CPUs (0.02 a match); the
answer to a player who guards on seeing the stance.")
(defun lb-ai-space-risk-p (fs bursting d rush)
  "Would a HOSHA from D metres open the generic ORANGE window for his CPU (pure): FS flash step for a burst (*FS-BURST*), none
BURSTING, D under *LB-AI-SPACE-NEAR* (+ *LB-AI-SPACE-RUSH* while he RUSHes in)?"
  (and (>= fs *fs-burst*) (not bursting) (< d (+ *lb-ai-space-near* (if rush *lb-ai-space-rush* 0.0))) t))
(defun lb-ai-space-plan (reeling dash-ok)
  "The stance's branch instead of a HOSHA in ORANGE's window (pure): TAISHA (:K) on a REELING opponent (a combo: the
bullet at f16 from 3 m back), else the HIRENKYAKU dash back then HOSHA (:DASH-J, when DASH-OK: the stance's one dash, its
flash step), else TAISHA."
  (cond (reeling :k) (dash-ok :dash-j) (t :k)))
(defun lb-ai-refuse-p (command red answer)
  "Does his CPU (at *LB-AI-CLEAN*'s level 1) refuse COMMAND (pure): the Breaker always; the Kikon when the opponent isn't RED
(no Konpaku to take) and an ANSWER (an SP or the crossfire) combos off the same link."
  (case command (:breaker t) (:kikon (and (not red) answer t))))

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
  (exit -1 :type fixnum)                  ; the stance whose exit was counted (its start tick)
  (web-t 0 :type fixnum)                  ; the web (HARD): the tick EN's next lay event may come (LB-AI-WEB-LAY)
  (web-sw -1 :type fixnum) (web-seen -1 :type fixnum)   ; ... the tick of its last switch, the last one the wary read counted
  (web-miss 0 :type fixnum)               ; ... web switches in a row whose traces missed (LB-AI-WEB-WARY-P)
  (hunt -9 :type fixnum)                  ; ... the base form's hunt: the tick it took the stance for HOSHA (LB-AI-HUNT)
  (xfire -999 :type fixnum)               ; the crossfire (b3a0): the tick KIN's K3 latched TENSHIN out (LB-AI-XFIRE-P)
  (guarded 0 :type fixnum)                ; the guard read (b3a0): HOSHAs he guarded in a row (LB-AI-HOSHA-READ)
  (oki -9 :type fixnum)                   ; b3a1: the wake-up shot's stance (its tick; LB-AI-OKI-SHOT, b1a1's)
  (turtle -9 :type fixnum)                ; b3a1: the stance against a guard (its tick; LB-AI-TURTLE / -HELD-AIM, b1a2's)
  (burst -99 :type fixnum)                ; b3a2: the tick of his last break-free counted (LB-AI-BURST-WAIT)
  (taisha -9 :type fixnum) (taisha-hp 0 :type fixnum) (taisha-kon 0 :type fixnum)   ; b3a2: his last TAISHA at a
                                          ; guard (its tick, his Reishi and Konpaku then)
  (punished 0 :type fixnum))              ; b3a2: ... those punished in a row (LB-AI-TAISHA-SETTLE)
(defvar *lb-ai* (vector (make-lbai) (make-lbai)) "Per side: his CPU's plan for the current threat.")
(defun lb-ai-state (e b)
  (let* ((i (fighter-side (fighter e))) (st (svref *lb-ai* i)))
    (if (and (eql (lbai-e st) e) (eq (lbai-b st) b)) st (setf (svref *lb-ai* i) (make-lbai :e e :b b)))))

(defun lb-ai-reflex (e b s d)
  "Every form's :reflex (ai.lisp AI-REFLEX, free states): the eye (base), TENSHIN in (EN) / out (KIN) and the stance in /
out (Jilliel, MUJITTAI), Trompete's punish (the owl). A command, :NONE (hands off: the generic guard must not answer), or
NIL. (HARD, b3a2: the base form settles the TAISHA read first and waits out his burst after the eye.)"
  (case (kit-form (kit-of e))
    (:base (or (lb-ai-taisha-settle e b) (lb-ai-eye e b s d) (lb-ai-burst-wait e b s) (lb-ai-turtle e b s d) (lb-ai-oki-shot e b s d)
               (lb-ai-held-aim e b s d) (lb-ai-hunt e b s d)))
    ((:jilliel :shin) (or (lb-ai-turtle e b s d) (lb-learn-en e b s d) (lb-ai-en e b s d)))   ; (the owl runs Jilliel's EN /
                                                                ; KIN CPU: decision 36; a learner's trace read first, §24.9)
    (:jilliel-kin (or (lb-ai-turtle e b s d) (lb-ai-kin-cash e b s d) (lb-ai-kin e b s d)))
    (:shin-kin (or (lb-ai-trompete e b s d) (lb-ai-turtle e b s d) (lb-ai-kin-cash e b s d)
                   (lb-ai-kin e b s d)))                       ; (+ Trompete's punish, as built)
    ((:jilliel-mujittai :jilliel-kin-mujittai :shin-mujittai :shin-kin-mujittai)
     (or (lb-ai-turtle e b s d) (lb-ai-stance-out e b s d) (lb-ai-kin-hold e b s d)))))

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
                          (and (eq (snap-kind s) :kikon) (gauges-red-p g))))
               (plan (lb-ai-eye-plan r (lb-ai-chance (getf (ai-table e :eye) :p 0.0) (brain-difficulty b))
                                     (lb-ai-eye-ready-p lead (lbs-u-up st) (lbs-eyes st)) dodge (ai-guard-k e))))
          (setf (lbai-key ai) (snap-start s) (lbai-plan ai) plan)
          (pace e (case plan (:eye :ai-eye-plan) (:guard :ai-guard) (t :ai-step)))))
      (case (lbai-plan ai)
        (:eye (cond ((and (lb-ai-eye-tap-p lead) (>= (lbs-u-up st) *lb-eye-rest*) (plusp (lbs-eyes st)))
                     (setf (lbai-plan ai) :tapped (lbai-tap ai) *match-tick*)
                     (pace e :ai-eye-tap)
                     (ai-press b :guard 2 :act :hold)    ; the tap (LB-EYE-STEP opens it on this step's tick)
                     (why b :eye :none))
                    ((> lead *lb-ai-eye-tap*)            ; not yet: hands off U (it must rest)
                     (when (eq (brain-press b) :guard) (setf (brain-press-left b) 0))
                     (why b :eye-wait :none))
                    (t (setf (lbai-plan ai) :guard) (why b :eye-late :guard))))
        (:tapped (if (>= (lbs-eye-t st) (lbai-tap ai))
                     (why b :eye-open :none)              ; intangible: nothing to do till it passes
                     (progn (setf (lbai-plan ai) :guard) (pace e :ai-eye-miss) (why b :eye-miss :guard))))
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
      (let ((ai (lb-ai-state e b)) (k (ai-table e :stance)) (g (gauges e)))
        (when (/= key (lbai-key ai))
          (setf (lbai-key ai) key
                (lbai-plan ai) (lb-ai-stance-plan (sim-rnd01)
                                                  (if (or (gauges-guardless g) (< (gauges-gg g) (getf k :gg 30))) 0.0   ; (it
                                                      (lb-ai-chance (getf k :p 0.0) (brain-difficulty b)))   ; would drop at once)
                                                  (and mv-threat (lb-ai-line-p s))))
          (pace e (case (lbai-plan ai) (:stance :ai-stance) (:step :ai-step) (t :ai-pass))))
        (case (lbai-plan ai)
          (:stance (setf (lbai-plan ai) :done) (ai-press b :guard 4 :act :hold) (why b :stance :none))
          (:step (setf (lbai-plan ai) :done) (why b :stance-step (lb-ai-side-step e b s)))
          (:pass (setf (lbai-plan ai) :done)
                 (if (and mv-threat (>= (- (snap-s s) (snap-sf s)) 6)
                          (hoho-ready-p e)
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
       (snap-punishable-p s)
       (>= (- (snap-left s) delay) frames)))

(defun lb-ai-exit-cmd (e b s d &optional why)
  "The attack that ends MUJITTAI (WHY: LB-STANCE-EXIT's reason): K1 when he stays busy for its startup within its reach,
J1 within its, else L (TENSHIN; EN's J / K lay traces). HARD KIN: LB-AI-KIN-EXIT first (b1a1 / b1a2's)."
  (let* ((kit (kit-of e)) (q (kit-command-move kit :q)) (fm (kit-command-move kit :f)))
    (cond ((lb-ai-kin-exit e b s why))
          ((lb-ai-en-exit e b))                                                      ; (HARD, EN: a line, not KIN)
          ((and fm (<= d (+ (mv-reach fm) 0.2)) (lb-ai-busy-p s (brain-delay b) (mv-s fm)) (kit-command-ok-p e :f)) :f)
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
      (let ((cmd (lb-ai-exit-cmd e b s d why)) (ai (lb-ai-state e b)) (t0 (- *match-tick* (lbs-stance st))))
        (when cmd
          (when (and (/= (lbai-exit ai) t0) (not (eq cmd :none)))   ; (:NONE: KIN's stance holds, b1a2)
            (setf (lbai-exit ai) t0)
            (pace e (case why (:whiff :ai-exit-whiff) (:max :ai-exit-max) (:gauge :ai-exit-gauge) (t :ai-exit-idle))))
          (why b :stance-exit cmd))))))

(defun lb-ai-trompete (e b s d)
  "The owl (DUEL_LILLE §11.2, Trompete): SP2 as a punish, beyond J's reach (the generic punish has it) and within the beam's
30 m, on him recovering or reeling for :left more frames (as perceived), one roll per his action (the react roll) at :p x
the difficulty. The neutral bands give SP2 only from 8 m: never into an idle opponent closer."
  (let ((k (ai-table e :trompete)) (q (kit-command-move (kit-of e) :q)))
    (and k q (> d (+ (mv-reach q) 0.4)) (<= d 30.0) (kit-command-ok-p e :sp2)
         (lb-ai-busy-p s (brain-delay b) (getf k :left 30))
         (< (brain-react-roll b) (lb-ai-chance (getf k :p 0.0) (brain-difficulty b)))
         (progn (pace e :ai-trompete) (why b :trompete :sp2)))))

(defun lb-ai-seen (b)
  "The SNAP brain B perceives this step (BRAIN-PERCEIVE's: its ring at the delay; NIL before it holds one): for his ticks,
which run inside moves where the reflexes don't."
  (let* ((ring (brain-ring b)) (n (length ring)))
    (and (plusp n) (svref ring (mod (- (brain-head b) 1 (brain-delay b)) n)))))

(defun lb-ai-hosha-read (e b contact)
  "His CPU's guard read (b3a0), once a HOSHA (LB-LINK-TICK at its link frame: his own move's CONTACT): a guarded one counts,
a hit clears the count (*LB-AI-GUARD-READ*)."
  (let ((ai (lb-ai-state e b)))
    (case contact
      (:hit (setf (lbai-guarded ai) 0))
      (:block (incf (lbai-guarded ai)) (pace e :ai-hosha-guarded)))))

(defun lb-ai-kamae (e f st)
  "His CPU's follow-up in the shooting stance (LB-KAMAE-TICK, from f6): the plan picked once, on the first step it is up
(one roll, LB-AI-KAMAE-PLAN; TSUKIMACHI's pattern: the sim's state at its f6), then carried out: the shot now (:L), J, K,
the dash back (then the charged shot), or the charged shot once the charge reaches *LB-CHARGE-F*."
  (unless (lbs-k-plan st)
    (let* ((o (opp-of e)) (fo (fighter o)) (mo (and (eq (fighter-state fo) :move) (fighter-move fo)))
           (whiffed (and mo (eq (fighter-phase fo) :main) (>= (fighter-sf fo) (+ (mv-s mo) (mv-a mo)))
                         (null (fighter-contact fo))))
           (plan (lb-ai-kamae-plan (sim-rnd01) (fighter-dist f) (member (fighter-state fo) '(:stun :air))
                                   (member (fighter-state fo) '(:guard :guard-hit)) (< (gauges-gg (gauges o)) 50)
                                   whiffed
                                   (and (not (lbs-dashed st)) (>= (gauges-fs (gauges e)) *lb-kamae-dash-fs*))))
           (b (ai-brain e))                                                            ; (his CPU's; the ASSIST's: §24.10)
           (close (>= (lb-ai-level *lb-ai-close* b) 1.0)))                               ; (b3a2: the sniper's step)
      (when (and (>= (lb-ai-level *lb-ai-hunt* b) 1.0)                                ; (the hunt, HARD: HOSHA)
                 (< (if (or close (member (fighter-state fo) '(:stun :air))) 0.0 2.0) (fighter-dist f) 8.0)
                 (or (member (fighter-state fo) '(:stun :air))
                     (<= (- *match-tick* (fighter-sf f)) (+ (lbai-hunt (lb-ai-state e b)) 3)))
                 (let ((sn (lb-ai-seen b))) (and sn (not (member (snap-state sn) '(:guard :guard-hit))))))
        (setf plan :j))
      (when (and (eq plan :j) (>= (lb-ai-level *lb-ai-space* b) 1.0)              ; (the spacing rule, HARD: b3a0)
                 (not (and close whiffed (<= (fighter-dist f) 2.0)))               ; (b3a2: HOSHA onto a close whiff)
                 (lb-ai-space-risk-p (gauges-fs (gauges e)) (gauges-burst (gauges e)) (fighter-dist f)
                                     (or (member (fighter-state fo) '(:run :step))
                                         (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :dash)))))
        (setf plan (lb-ai-space-plan (member (fighter-state fo) '(:stun :air))
                                     (and (not (lbs-dashed st)) (>= (gauges-fs (gauges e)) *lb-kamae-dash-fs*))))
        (pace e :ai-space))
      (when (and (eq plan :j) (>= (lb-ai-level *lb-ai-hunt* b) 1.0) (not (member (fighter-state fo) '(:stun :air)))
                 (>= (lbai-guarded (lb-ai-state e b)) *lb-ai-guard-read*))   ; (the guard read: b3a0)
        (decf (lbai-guarded (lb-ai-state e b)))           ; (one pierce, then HOSHA is tried again)
        (pace e :ai-guard-read)
        (setf plan :k))
      (when (and (>= (lb-ai-level *lb-ai-blow* b) 1.0) (member (fighter-state fo) '(:air :down :wakeup)))
        (setf plan (if (and (not (lbs-dashed st)) (>= (gauges-fs (gauges e)) *lb-kamae-dash-fs*)) :dash-oki :oki)))
      (when (lb-ai-oki-stance-p e b f) (setf plan :charge))                          ; (HARD: the wake-up shot, b1a1)
      (when (and (eq plan :l) (>= (lb-ai-level *lb-ai-held-aim* b) 1.0)) (setf plan :charge))   ; (HARD: charged only)
      (when (lb-ai-turtle-stance-p e b f)                                            ; (HARD: the X-Axis through a guard:
        (setf plan (if (<= (fighter-dist f) 3.0) :k :charge))                        ; TAISHA in its reach, else charged)
        (when (eq plan :k) (setf plan (lb-ai-taisha-read e b))))                     ; (b3a2: his answer to it read)
      (setf plan (lb-learn-kamae e b f plan))                                        ; (a learner's HOSHA read, §24.9)
      (setf (lbs-k-plan st) plan)
      (pace e (intern (format nil "AI-KAMAE-~a" plan) :keyword))))
  (case (lbs-k-plan st)
    (:l (lb-ai-composure e (brain e)) :kamae-l) (:j (lb-ai-composure e (brain e)) :kamae-j)
    (:k (lb-ai-composure e (brain e)) :kamae-k)
    (:dash (setf (lbs-k-plan st) :charge) :kamae-step)
    (:dash-j (setf (lbs-k-plan st) :j) :kamae-step)      ; (the spacing rule: back, then HOSHA)
    (:dash-oki (setf (lbs-k-plan st) :oki) :kamae-step)  ; (b3a2: back, then the held aim on his wake-up)
    (:oki (lb-ai-blow-step e f st))
    (:charge (and (lb-kamae-charged-p (lbs-charge st)) (progn (lb-ai-composure e (brain e)) :kamae-l)))))

(defun lb-link-form (form to)
  "Pure: the form a TENSHIN's J / K link is decided for: TO (the switch's target, while its form change is still to come:
the ASSIST decides a step before the link, a short dash ends before f6), else FORM."
  (or to form))

(defun lb-ai-link (e f st hosha)
  "His CPU's link out of HOSHA (after a bullet's hit: one roll) or TENSHIN (J after a switch in whose traces hit; no roll):
LB-AI-LINK-PLAN; called once a move (the latch holds the answer). HARD: HOSHA's K1 (b1a0), and TENSHIN out's link in a
crossfire EN's J1, laid at him (b3a0). AI-BRAIN: his CPU's, or the ASSIST's for a human (LB-ASSIST-COMBO, §24.10)."
  (let* ((form (lb-link-form (fighter-form f) (and (not hosha) (lbs-switch-to st))))
         (plan (lb-ai-link-plan hosha (if hosha (sim-rnd01) 0.0) (and (member form '(:jilliel-kin :shin-kin)) t)
                                (>= (lbs-trace-hit-t st) (lbs-switch-t st) 0))))
    (cond ((and hosha (>= (lb-ai-level *lb-ai-link-k* (ai-brain e)) 1.0)   ; (b1a1: no K1 into a blown-away opponent)
                (>= (lb-ai-level *lb-ai-oki* (ai-brain e)) 1.0) (member (state-of (opp-of e)) '(:air :down)))
           :none)
          ((and hosha (>= (lb-ai-level *lb-ai-link-k* (ai-brain e)) 1.0)) :f)   ; (K1: L after it reopens the stance)
          ((and (not hosha) (lb-en-form-p form) (ai-brain e) (lb-ai-xfire-live-p e (ai-brain e))   ; (the crossfire)
                (lb-ai-lay-ok-p (gauges-fs (gauges e)) :j))
           (pace e :ai-xfire-link) :q)
          (t plan))))

(defun lb-ai-trace-gap (e x z)
  "His live traces seen from (X Z): values how many and the distance to the nearest one's line as it would materialise (turned
toward (X Z): LB-SNAP-YAW; a thick trace's extra width off: LB-SWITCH-IN-RULE's gap)."
  (let ((n 0) (gap 99.0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (lbh-p d) (lbh-live d))
          (incf n)
          (setf gap (min gap (- (line-dist (hazard-x hz) (hazard-z hz) (lb-snap-yaw (hazard-yaw hz) (hazard-x hz) (hazard-z hz) x z)
                                           0.6 *lb-trace-len* x z)
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
           (pace e :ai-switch-via-j) (why b :switch-via-j :q))
          ((and (lb-ai-switch-in-p e b s *lb-switch-windup*) (not (lb-learn-hold-p e b s)))   ; (a learner's read, §24.9)
           (pace e :ai-switch-trace) (why b :switch-in :sig))
          ((lb-ai-stance-in e b s d))
          ((lb-ai-web-lay e b s d))                                 ; (the web, HARD)
          ((lb-ai-poor-web e b s d))                                ; (b3a1: starved, the bar's three lines)
          ((and (lb-ai-switch-in-p e b s *lb-switch-windup* (not (lb-ai-lay-ok-p fs :j)))
                (or (< (lb-ai-level *lb-ai-starve* b) 1.0) (lb-ai-busy-p s (brain-delay b) *lb-switch-windup*))
                (not (lb-learn-hold-p e b s)))
           (pace e :ai-switch-starved) (why b :switch-starved :sig)))))

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
               (pace e (case why (:block :ai-switch-block) (:string :ai-switch-string) (t :ai-switch-gauge)))
               (why b :switch-out :sig))
        (or (lb-ai-stance-in e b s d) (lb-ai-kin-run e b s d) (lb-ai-kin-snipe e b s d)))))

(defun lb-ai-punish-p (e b s d)
  "Something the generic reflexes cash in now: he reels or recovers within J1's reach for its startup, or a red one reels
within the Kikon range (the rush)."
  (let ((q (kit-command-move (kit-of e) :q)))
    (or (and q (< d (+ (mv-reach q) 0.6)) (lb-ai-busy-p s (brain-delay b) (mv-s q)))
        (and (kikon-ready-p e) (member (snap-state s) '(:stun :air)) (< d (ai-table e :kikon-range 7.0))))))

(defun lb-ai-kin-run (e b s d)
  "KIN free (HARD, *LB-AI-KIN-RUN*): nothing to punish, TENSHIN out back to EN's lines as soon as its price (+
*LB-AI-KIN-RUN-FS*) is there. No roll."
  (when (and (>= (lb-ai-level *lb-ai-kin-run* b) 1.0) (>= (gauges-fs (gauges e)) (+ *lb-switch-fs* *lb-ai-kin-run-fs*))
             (kit-command-ok-p e :sig) (not (lb-ai-punish-p e b s d)))
    (setf (lbs-kin-last (lb e)) nil)
    (pace e :ai-switch-run)
    (why b :switch-run :sig)))

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

;;; ---------------------------------------------------------------- the sniper's HARD layer (dream-rsi round 1, cell b1a0)
;;; DUEL_LILLE §24. Every knob below is a level by difficulty, 1 at HARD and 0 at EASY and NORMAL (EASY <= NORMAL <= HARD),
;;; tested before anything else: EASY and NORMAL play, and draw random numbers, exactly as the shipped CPU. At HARD each is a
;;; deterministic rule on what he perceives (no roll: a level of 1 is a certainty, so nothing is rolled per step).
;;;   the web 照準網 (EN)  decision 41's snap turns every live trace toward him by up to 10 deg when it materialises, so a line
;;;                        laid at him (and every older one still within its 10 deg) converges on him: EN lays a J line at
;;;                        him while it keeps its range (LB-AI-WEB-LAY: the shipped :moves band never fires at range,
;;;                        AI-ATTACK's no-whiff rule) and its tick materialises the web through TENSHIN's 2 f cancel once its
;;;                        hit groups would hit where he will be (LB-AI-WEB-COUNT at his perceived position moved on by his
;;;                        perceived velocity: LB-AI-WEB-AT); one group, or more while he is committed (LB-AI-WEB-K: the
;;;                        volley); after misses in a row only onto a committed opponent (the wary read, LB-AI-WEB-WARY-P)
;;;   the hit-and-run (KIN) KIN is the combo's vehicle: free with nothing to punish, TENSHIN out back to the lines
;;;                        (LB-AI-KIN-RUN); EN starved of flash step switches in only onto a busy opponent (*LB-AI-STARVE*)
;;;   the hunt (base)      the shooting stance for HOSHA at an open opponent in *LB-AI-HUNT-BAND* (LB-AI-HUNT); HOSHA links
;;;                        K1 (LB-AI-LINK) with L latched on it (LB-AI-HOSHA-LOOP): the stance at f4, HOSHA again on the
;;;                        reeling opponent (LB-AI-KAMAE): bullets -> K1 -> the stance -> HOSHA ...
;;;   the cash-out         a landed string's last link cashes out with SP2 (LB-AI-SP-ENDER: HIRENKYAKU / NIJUSHI-KO)
;;; Cell b3a0 (the sniper's discipline: every exchange ends on his own terms; knobs with the AI knobs above, levels as
;;; these) keeps that layer and adds:
;;;   the spacing rule     HOSHA only where its first bullet lands outside the generic ORANGE window (*LB-AI-SPACE*,
;;;                        LB-AI-SPACE-RISK-P), else TAISHA on a reeling opponent (the loop becomes bullets -> K1 -> the
;;;                        stance -> TAISHA from 3 m back, then the hunt again from range) or the HIRENKYAKU dash back then
;;;                        HOSHA on an open one (LB-AI-SPACE-PLAN); the guard read: HOSHA guarded twice -> TAISHA once
;;;   the crossfire        KIN's K3 crumple -> L -> TENSHIN out -> EN's J1 at him -> the 2 f cancel -> TENSHIN in -> J ...
;;;                        (LB-AI-XFIRE-P, LB-AI-LINK, LB-AI-XFIRE-CANCEL-P): the trace combo carried through both modes
;;;   the combo enders     the SP that combos off the last link (LB-AI-ENDER-SP: KIN's J3 SANREN, K3 NIJUSHI-KO), never an
;;;                        SP2 into a guard; nothing (no ORANGE) when none can (LB-AI-SP-ENDER)
;;;   the refusals         LILLE-OK's CPU clause (LB-AI-VETO-P, *LB-AI-CLEAN*): no Breaker; no non-red O ender where the
;;;                        crossfire or SANREN combos off the same link
(defparameter *lb-ai-web* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The web's level by difficulty (dream-rsi b1a0, 2026-10-07): 1 = on (HARD), 0 = the shipped CPU (EASY, NORMAL).")
(defparameter *lb-ai-web-band* '(2.5 7.0)
  "The perceived distance band EN lays its lines at him in: TENSHIN in reaches 7 m and stops 1 m short, so KIN's J1
then reaches him (dream-rsi b1a0, 2026-10-07: 13 at TENSHIN in's 13 m; decision 49 cut TENSHIN in to 10 m: 10; decision
52 to 4.5 m: 4.5; decision 53 to two Steps + 0.5 = 5.5 m: 5.5; decision 54 to 7 m: 7.0).")
(defparameter *lb-ai-web-every* 6
  "Frames between two of EN's lay events, one J each (dream-rsi b1a0, 2026-10-07; 3 and 12 measured the same).")
(defparameter *lb-ai-web-k* 1
  "The web materialises when at least this many hit groups of live traces would hit him: 1, the line just laid (dream-rsi
b1a0, 2026-10-07: 2 fell into the Step his trace reflex takes on seeing the first line; 3, the whole J string, lost a
little: measured 0.75 / 0.47 / 0.78 of his HARD wins at 20 seeds, the hunt off).")
(defparameter *lb-ai-web-volley* '(14 28)
  "The volley by his commitment (as perceived, after the delay): busy >= the first number of frames more, wait for a 2nd
group (J2's line, 12 f after J1's active end); >= the second, a 3rd (dream-rsi b1a0, 2026-10-07).")
(defparameter *lb-ai-web-wary* 2
  "The wary read: after this many web switches in a row whose traces missed him (he stepped off, guarded, blew through),
the web lays its lines only at a committed opponent (running, in a move or reeling) until one hits (dream-rsi b1a0).")
(defparameter *lb-ai-web-margin* 0.15
  "Metres a line must clear inside the hit test (its radius + his hurt radius) to be counted (dream-rsi b1a0, 2026-10-07).")
(defparameter *lb-ai-hunt-band* '(0.0 7.5)
  "... the perceived distance band: HOSHA's 5 m leap + its 3 m bullets ((3 7) / (2 8) / (2.5 6.5) measured; dream-rsi b1a0).")
(defparameter *lb-ai-hosha-loop* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "HOSHA's K1 link latches L at once (dream-rsi b1a0, 2026-10-07): its hit opens the stance at f4, whose plan is HOSHA again
on the reeling opponent (his signature 0.85 -> 0.92 at HARD).")
(defparameter *lb-ai-sp-end* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "A landed string's last link (no O ender rolled) cashes out with SP2: HIRENKYAKU / NIJUSHI-KO (dream-rsi b1a0, 2026-10-07).")
(defun lb-ai-level (plist b) "PLIST's value at brain B's difficulty (0.0 with no brain)." (if b (float (getf plist (brain-difficulty b) 0.0) 1.0) 0.0))

(defun lb-ai-snap-back (b k)
  "The SNAP brain B perceived K steps before the one it perceives now (its ring), or NIL."
  (let* ((ring (brain-ring b)) (n (length ring)))
    (and (< (+ k (brain-delay b) 1) n) (svref ring (mod (- (brain-head b) 1 (brain-delay b) k) n)))))

(defun lb-ai-web-at (b s lead)
  "Where he will be (values x z) LEAD frames from now: his perceived position S moved on by his perceived velocity (two
snaps 4 steps apart) over the perception delay + LEAD; standing still when the older snap is missing."
  (let ((s2 (lb-ai-snap-back b 4)) (k (/ (+ (brain-delay b) lead) 4.0)))
    (if s2
        (values (+ (snap-x s) (* k (- (snap-x s) (snap-x s2)))) (+ (snap-z s) (* k (- (snap-z s) (snap-z s2)))))
        (values (snap-x s) (snap-z s)))))

(defun lb-ai-web-count (e x z hr)
  "How many hit groups of E's live traces would hit a fighter of hurt radius HR at (X Z) if they materialised now: each
line turned toward him (LB-SNAP-YAW), its radius + HR - *LB-AI-WEB-MARGIN* from his feet (a K fan is one group)."
  (let ((n 0) (groups nil))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (lbh-p d) (lbh-live d)
                   (<= (line-dist (hazard-x hz) (hazard-z hz) (lb-snap-yaw (hazard-yaw hz) (hazard-x hz) (hazard-z hz) x z)
                                  0.6 *lb-trace-len* x z)
                       (- (+ (lbh-width d) hr) *lb-ai-web-margin*)))
          (let ((g (hazard-group hz)))
            (cond ((null g) (incf n))
                  ((not (member g groups :test #'eq)) (push g groups) (incf n)))))))
    n))

(defun lb-ai-volley-k (left &optional (v *lb-ai-web-volley*) (k *lb-ai-web-k*))
  "The hit groups the web waits for (pure): K, or with him committed LEFT more frames (as perceived; NIL: free) 2 from V's
first number of frames, 3 from its second (*LB-AI-WEB-VOLLEY*)."
  (cond ((null left) k) ((>= left (second v)) (max k 3)) ((>= left (first v)) (max k 2)) (t k)))
(defun lb-ai-web-wary-p (misses state &optional (wary *lb-ai-web-wary*))
  "May the web lay a line (pure): fewer than WARY web switches in a row missed (MISSES), or him committed (STATE :run
:move :stun, as perceived): the wary read."
  (or (< misses wary) (and (member state '(:run :move :stun)) t)))
(defun lb-ai-web-k (e b s)
  "The volley size his web waits for now (LB-AI-VOLLEY-K): more while he is committed in a move or reeling."
  (declare (ignore e))
  (lb-ai-volley-k (and s (member (snap-state s) '(:move :stun)) (< (snap-left s) 99) (snap-left-seen s b))))
(defun lb-ai-web-fired (e b)
  "EN's tick just cancelled into TENSHIN for the web: its tick, for the wary read (LB-AI-WEB-SETTLE)."
  (setf (lbai-web-sw (lb-ai-state e b)) *match-tick*)
  (pace e :ai-switch-web))
(defun lb-ai-web-settle (e ai)
  "The wary read's count, once per web switch: its traces hit him (LBS-TRACE-HIT-T at or after it) or missed."
  (when (> (lbai-web-sw ai) (lbai-web-seen ai))
    (setf (lbai-web-seen ai) (lbai-web-sw ai))
    (if (>= (lbs-trace-hit-t (lb e)) (lbai-web-sw ai))
        (setf (lbai-web-miss ai) 0)
        (progn (incf (lbai-web-miss ai)) (pace e :ai-web-miss)))))

(defun lb-ai-web-cancel-p (e b f s)
  "EN's tick, an EN attack past its active end (the web, HARD): TENSHIN ready, him not guarding (a guarded line is chip,
no stagger: lay on), and at least LB-AI-WEB-K hit groups would hit where he will be at the materialise (2 f), or at
least one when no link is latched (the string's last line). Deterministic: no roll."
  (when (and s (>= (lb-ai-level *lb-ai-web* b) 1.0) (lb-switch-ready-p e)
             (not (member (snap-state s) '(:guard :guard-hit))))
    (multiple-value-bind (x z) (lb-ai-web-at b s *lb-switch-windup-c*)
      (let ((n (lb-ai-web-count e x z (body-hurt-r (model-body (model (opp-of e)))))))
        (and (plusp n) (or (>= n (lb-ai-web-k e b s)) (null (fighter-queued f))))))))

(defun lb-ai-xfire-cancel-p (e b s)
  "EN's tick in a crossfire (LB-AI-XFIRE-LIVE-P): TENSHIN ready and one hit group would hit where he will be."
  (when (and s (lb-ai-xfire-live-p e b) (lb-switch-ready-p e))
    (multiple-value-bind (x z) (lb-ai-web-at b s *lb-switch-windup-c*)
      (plusp (lb-ai-web-count e x z (body-hurt-r (model-body (model (opp-of e)))))))))

(defun lb-ai-web-lay (e b s d)
  "EN free (the web, HARD): a lay event every *LB-AI-WEB-EVERY* frames while he stands in *LB-AI-WEB-BAND* (not in a Step,
a Hoho or a guard), a J line affordable above the reserve (LILLE-OK): J, its line laid at him (EN faces him); the string's
next links follow (LB-AI-EN-NEXT) until the tick materialises the web (LB-AI-WEB-CANCEL-P). No roll at HARD (level 1)."
  (when (and (>= (lb-ai-level *lb-ai-web* b) 1.0) (<= (first *lb-ai-web-band*) d (second *lb-ai-web-band*))
             (not (member (snap-state s) (if (>= (lb-ai-level *lb-ai-siege* b) 1.0) '(:step :hoho) '(:step :hoho :guard :guard-hit))))
             (kit-command-ok-p e :q))
    (let ((ai (lb-ai-state e b)))
      (lb-ai-web-settle e ai)
      (when (and (>= *match-tick* (lbai-web-t ai)) (lb-ai-web-wary-p (lbai-web-miss ai) (snap-state s)))
        (setf (lbai-web-t ai) (+ *match-tick* *lb-ai-web-every*))
        (pace e :ai-web-lay)
        (why b :web-lay :q)))))

(defun lb-ai-hosha-loop (e f b)
  "His CPU's K1 just linked out of HOSHA (LB-LINK-TICK): at *LB-AI-HOSHA-LOOP*'s level L is latched on it, as a press of L
during the K link would (KIT-L-LINK: the stance at f4 once K1 touches him; the stance's plan, LB-AI-KAMAE, is HOSHA on a
reeling opponent): bullets -> K1 -> the stance -> HOSHA ... No roll."
  (let ((mv (fighter-move f)) (kit (fighter-kit f)))
    (when (and (>= (lb-ai-level *lb-ai-hosha-loop* b) 1.0) mv (null (fighter-queued f))
               (kit-l-link kit (mv-name mv)) (kit-command-ok-p e :sig kit nil (kit-l-link kit (mv-name mv))))
      (setf (fighter-queued f) :sig)
      (pace e :ai-hosha-loop))))

(defun lb-ai-sp-ender (e kit)
  "The base form's and KIN's :sp-ender (ai.lisp STRING-REFLEX: a landed string's last link, no O ender rolled, the victim on
the ground), at *LB-AI-SP-END*'s level (HARD 1: no roll; EASY / NORMAL 0: the generic SP cancel as shipped): first his own
CPU's crossfire off KIN's K3 (LB-AI-XFIRE-P, b3a0), else the SP that still combos off that link (LB-AI-ENDER-SP, b3a0:
KIN's K3 NIJUSHI-KO, its J3 SANREN; the base form's K3 L into the stance (the ASSIST's too: its route plays the stance), else
HIRENKYAKU; b1a0 cashed out with SP2 alone, whose 40 f beam KIN's J3 stagger doesn't hold: 56 hits and 559 guarded of 690
at 40 seeds once the crossfire took the K3s), else (his own CPU in KIN) :NONE: no generic SP cancel or ORANGE off it,
KIN's hit-and-run takes him out. AI-BRAIN: the ASSIST's borrowed brain for a human (the crossfire too, its routes carry it
on, DUEL_LILLE §24.10; never :NONE)."
  (let* ((b (ai-brain e)) (mv (fighter-move (fighter e))) (on (and b (>= (lb-ai-level *lb-ai-sp-end* b) 1.0)))
         (sp (lb-ai-ender-move-sp e kit)))   ; (the stance's branch: his CPU's, or the ASSIST route's, §24.10)
    (or (lb-ai-xfire-p e kit)
        (and on sp
             (if (eq sp :sig)
                 (let ((l (kit-l-link kit (mv-name mv)))) (and l (kit-command-ok-p e :sig kit nil l)))
                 (kit-command-ok-p e sp kit))
             (progn (pace e (case sp (:sp1 :ai-sp-ender-1) (:sig :ai-sp-ender-l) (t :ai-sp-ender))) sp))
        (and on (eq b (brain e)) (lb-kin-form-p (kit-form kit))
             (progn (pace e :ai-sp-ender-none) :none)))))

(defun lb-ai-ender-sp (form react)
  "The follow-up that still combos off a string's last link whose hit is a REACT in FORM (pure; b3a0): KIN's crumple (K3,
40 f) NIJUSHI-KO (:SP2, its beam at f40), a shorter one (J3's stagger, 26 f) SANREN (:SP1, its first line at f12); the base
form's crumple L (:SIG: the stance at f4, HOSHA / TAISHA by the spacing rule), else HIRENKYAKU (:SP2, the shot at f20)."
  (cond ((lb-kin-form-p form) (if (eq react :crumple) :sp2 :sp1))
        ((eq form :base) (if (eq react :crumple) :sig :sp2))))

(defun lb-ai-ender-move-sp (e kit)
  "LB-AI-ENDER-SP for E's current move (its first hit window's reaction), or NIL."
  (let ((mv (fighter-move (fighter e))))
    (and mv (plusp (length (mv-hits mv))) (lb-ai-ender-sp (kit-form kit) (hw-react (svref (mv-hits mv) 0))))))

(defun lb-ai-xfire-ok-p (e kit)
  "Can his own CPU's crossfire start now (no side effect): his level, KIN's K3 (Jilliel's or the owl's) hit, its L link
allowed, the flash step for TENSHIN out's price and then a J line above the reserve?"
  (let* ((b (ai-brain e)) (f (fighter e)) (mv (fighter-move f)) (l (and mv (kit-l-link kit (mv-name mv)))))
    (and b (>= (lb-ai-level *lb-ai-xfire* b) 1.0) mv (member (mv-name mv) '(:lb-w-k3 :lb-o-k3)) l
         (eq (fighter-contact f) :hit)
         (lb-ai-lay-ok-p (- (gauges-fs (gauges e)) *lb-switch-fs*) :j) (kit-command-ok-p e :sig kit nil l))))

(defun lb-ai-xfire-p (e kit)
  "The crossfire 十字砲火 (b3a0; AI-BRAIN: his CPU's, or the ASSIST's for a human since its routes carry it on, §24.10):
KIN's K3 just crumpled him:
L, latched on the K link (KIT-L-LINK), TENSHIN out at the chain's opening; its link is EN's J1 laid at him (LB-AI-LINK), its
line materialised at once through the 2 f cancel (LB-AI-XFIRE-CANCEL-P), then TENSHIN in's J (the shipped trace-hit link)."
  (when (lb-ai-xfire-ok-p e kit)
    (setf (lbai-xfire (lb-ai-state e (ai-brain e))) *match-tick*)
    (pace e :ai-xfire)
    :sig))

(defun lb-ai-xfire-live-p (e b)
  "Is his CPU in a crossfire: its TENSHIN out latched within *LB-AI-XFIRE-LIFE* frames?"
  (<= (- *match-tick* (lbai-xfire (lb-ai-state e b))) *lb-ai-xfire-life*))

(defun lb-ai-veto-p (e b command)
  "LILLE-OK's CPU clause (b3a0, *LB-AI-CLEAN*): B's level, then LB-AI-REFUSE-P on the Breaker / a Kikon, the opponent red
or not (KIKON-READY-P), the answer the same link has: the crossfire (KIN's K3), or SANREN off KIN's J3 when it can start
(LB-AI-ENDER-SP's :SP1; the base form keeps its O ender: its K3 / J3 rarely end a string now)."
  (and (>= (lb-ai-level *lb-ai-clean* b) 1.0)
       (lb-ai-refuse-p command (kikon-ready-p e)
                       (and (eq command :kikon)
                            (let* ((kit (kit-of e)) (sp (lb-ai-ender-move-sp e kit)))
                              (or (lb-ai-xfire-ok-p e kit)
                                  (and (eq sp :sp1) (eq (fighter-contact (fighter e)) :hit) (kit-command-ok-p e :sp1 kit))))))))

(defun lb-ai-hunt (e b s d)
  "The base form free (HARD, *LB-AI-HUNT*): him open (standing, walking, running, in a move or reeling) within
*LB-AI-HUNT-BAND*: the shooting stance, its branch HOSHA (LB-AI-KAMAE reads LBAI-HUNT). No roll."
  (when (and (>= (lb-ai-level *lb-ai-hunt* b) 1.0) (<= (first *lb-ai-hunt-band*) d (second *lb-ai-hunt-band*))
             (member (snap-state s) '(:idle :run :move :stun)) (kit-command-ok-p e :sig)
             (not (and (>= (lb-ai-level *lb-ai-rush-wary* b) 1.0) (lb-ai-rush-p s))))   ; (b1a1: not into his rush)
    (setf (lbai-hunt (lb-ai-state e b)) *match-tick*)
    (pace e :ai-hunt)
    (why b :hunt :sig)))

;;; ---------------------------------------------------------------- the refine (dream-rsi round 1, cell b3a1, from b3a0)
;;; DUEL_LILLE §24. Levels by difficulty as above (HARD 1, EASY / NORMAL 0: the shipped CPU, no new roll), deterministic,
;;; read once per event. b3a0's engines (the spacing rule, the crossfire, the enders, the refusals) kept; the located fixes
;;; of the other lineages brought in, credited (each closed a leak b3a0's file still has):
;;;   the rush-wary hunt   never the stance into his Kikon / Breaker rush (b1a1's LB-AI-RUSH-P)
;;;   the wake-up shot     the charged X-Axis shot timed onto a downed opponent's first hittable frame; HOSHA's link skips
;;;                        the K1 into a blown-away opponent (b1a1's LB-AI-OKI-SHOT)
;;;   the patient web      EN lays its lines at a guard / a ward too, the switch waits for it to drop (b1a1's siege)
;;;   KIN's exits / hold   MUJITTAI in KIN ends in SANREN or TENSHIN out, else holds (b1a1 / b1a2)
;;;   the turtle           the generic guard-break / anti-parry events are his (b0a1 / b1a2's LB-AI-TURTLE)
;;;   the held aim         the base form never steps in on a guard: TAISHA within 3 m, the charged shot on a long one,
;;;                        else waits; never the quick shot at HARD (b1a2's LB-AI-HELD-AIM)
;;;   KIN's cash-in        a reeling / recovering opponent in KIN gets SANREN, not a plain string (b1a2's LB-AI-KIN-CASH)
;;;   the composure        J held through the stance's HOSHA / TAISHA / shot: no generic ORANGE off their hits (b2a0's
;;;                        mechanism; the spacing rule kept for the loop's TAISHA, the hunt now from 0 m)
;;; and new here:
;;;   the pendulum         the trace combo's KIN J1 latches K (b2a0's route) so the string ends in K3's crumple, where b3a0's
;;;                        crossfire swings it back through EN: trace -> KIN J1 K2s K3 -> out -> a line -> in -> J1 ...
;;;                        (LB-AI-ROUTE; crossfires 2 -> 4 a match)
;;;   the lines before KIN EN MUJITTAI's exit is a line at him (J1, or SP1's three when poor), and a starved EN lays SP1's
;;;                        lines before it switches in (LB-AI-EN-EXIT, LB-AI-POOR-WEB; b0a2's located leak)
;;;   KIN's snipe          KIN free with nothing to cash or run on: SANREN, not the generic neutral string (LB-AI-KIN-SNIPE)
;;;   the late wake-up     too late for the charged shot: HIRENKYAKU's X-Axis shot on his first hittable frames
;;;                        (*LB-AI-OKI-HIREN*)
(defun lb-ai-rush-p (s)
  "Is his perceived move a rush on its way: a Kikon or Breaker in its aura, dash or follow-up phase (pure on the SNAP)?"
  (and (eq (snap-state s) :move) (member (snap-kind s) '(:breaker :kikon)) (member (snap-phase s) '(:aura :dash :follow)) t))
;; the lines before KIN (b3a1; b0a2's located leak): EN never enters KIN with nothing
(defparameter *lb-ai-en-exit* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "EN's lines before KIN (dream-rsi b3a1, 2026-10-07; b0a2's located leak, re-found here: b3a0 + the ports, KIN's plain
strings came most from a TENSHIN in that brought no trace hit: EN MUJITTAI's exit, 0.27 a match, 2.9 plain damage a match
after it; the starved switch in, 1.1): EN MUJITTAI's exit is J1, a line laid at him (the web's cancel materialises it when
it would hit), or with no flash step for it SP1's three lines (a bar, no flash step); the starved EN (no J line above the
reserve) lays SP1's lines at him from the web's band before it switches in (LB-AI-POOR-WEB).")
(defun lb-ai-en-sp1-p (e)
  "May EN lay its SP1's three lines now: Jilliel's EN SANREN (the owl's EN: 裁きの光明's lines), a bar for it?"
  (let ((mv (kit-command-move (kit-of e) :sp1)))
    (and mv (member (mv-name mv) '(:lb-e-sanren :lb-oe-sabaki)) (kit-command-ok-p e :sp1))))
(defun lb-ai-en-exit (e b)
  "The stance's exit attack in EN (*LB-AI-EN-EXIT*'s level; NIL: the shipped exit): J1 (a line at him) when it can pay
its line above the reserve, else SP1's three lines. No roll."
  (when (and b (>= (lb-ai-level *lb-ai-en-exit* b) 1.0) (member (kit-form (kit-of e)) '(:jilliel-mujittai :shin-mujittai)))
    (cond ((and (lb-ai-lay-ok-p (gauges-fs (gauges e)) :j) (kit-command-ok-p e :q)) :q)
          ((lb-ai-en-sp1-p e) :sp1))))
(defun lb-ai-poor-web (e b s d)
  "EN free and starved (HARD, *LB-AI-EN-EXIT*: no J line above the reserve), him in the web's band and not stepping /
Hoho-ing / guarding: SP1's three lines at him (the web's cancel materialises them). No roll."
  (when (and (>= (lb-ai-level *lb-ai-en-exit* b) 1.0) (<= (first *lb-ai-web-band*) d (second *lb-ai-web-band*))
             (not (lb-ai-lay-ok-p (gauges-fs (gauges e)) :j))
             (not (member (snap-state s) '(:step :hoho :guard :guard-hit))) (lb-ai-en-sp1-p e))
    (pace e :ai-poor-web)
    (why b :poor-web :sp1)))
;; the pendulum's route (b3a1; b2a0's latch, for b3a0's crossfire)
(defparameter *lb-ai-route* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The pendulum's route (dream-rsi b3a1, 2026-10-07; b2a0's latch, credited): the trace combo's KIN J1 (TENSHIN in's link)
latches K at once, J1 -> K2s -> K3 (K2s has only K3 after it), so the string ends in K3's crumple, where b3a0's crossfire
takes it back through EN (TENSHIN out, a line at him, TENSHIN in, J1 ...): the trace combo swings between the two modes
until the stun tolerance blows him away; NIJUSHI-KO off the crumple when the flash step can't pay the swing. (The shipped
generic string, J1 J2 J3 most of the time, ended in J3's stagger: SANREN or nothing.)")
(defun lb-ai-route (e f b)
  "His CPU's KIN J1 just linked out of TENSHIN in (LB-LINK-TICK): at *LB-AI-ROUTE*'s level K is latched on it (K2s, then
K3). No roll."
  (let ((mv (fighter-move f)))
    (when (and (>= (lb-ai-level *lb-ai-route* b) 1.0) mv (null (fighter-queued f)) (kit-next (fighter-kit f) (mv-name mv) :f))
      (setf (fighter-queued f) :f)
      (pace e :ai-route))))
;; KIN's snipe (b3a1)
(defparameter *lb-ai-kin-snipe* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "KIN's snipe (dream-rsi b3a1, 2026-10-07): KIN free with nothing to cash and no flash step to run (LB-AI-KIN-RUN), him
free (not attacking, rushing, stepping or Hoho-ing): SANREN's three X-Axis lines (a bar; through guard) instead of the
generic neutral's wing-blade string, the largest plain source left once EN stopped entering KIN with nothing (KIN NEUTRAL
3-4 damage a match at HARD).")
(defun lb-ai-kin-snipe (e b s d)
  "Jilliel KIN free (HARD, *LB-AI-KIN-SNIPE*), after the run and the cash: him free within SANREN's lines (no threat of his
within reach + 1 m, no rush, not stepping / Hoho-ing / down): SP1. No roll."
  (when (>= (lb-ai-level *lb-ai-kin-snipe* b) 1.0)
    (let ((sp (kit-command-move (kit-of e) :sp1)))
      (when (and sp (eq (mv-name sp) :lb-sanren) (<= d 18.0)
                 (member (snap-state s) '(:idle :run :guard :guard-hit))
                 (not (lb-ai-threat-p e s d 1.0)) (not (lb-ai-rush-p s)) (kit-command-ok-p e :sp1))
        (pace e :ai-kin-snipe)
        (why b :kin-snipe :sp1)))))
;; the composure (b2a0's mechanism; b3a1): see *LB-AI-COMPOSURE*
(defparameter *lb-ai-composure* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The composure (b2a0's mechanism, as b0a1 / b1a1 carry it; dream-rsi b3a1, 2026-10-07): HOSHA's bullets are his; J (inert
in HOSHA: his CPU's link is LB-AI-LINK's) is held *LB-AI-COMPOSURE-F* frames from HOSHA's start, so no generic reflex runs
on a bullet's hit: the generic ORANGE never turns a HOSHA into a plain J string. b3a0's spacing rule kept the loop's HOSHA
out of ORANGE's window, but not the hunt's: a HOSHA whose first bullet whiffs lands its second at the leap's end, 0.95 m
from him (b3a0's file: 0.17 ORANGEs a match, the base form's largest plain source, CHAIN 14-20 a match).")
(defparameter *lb-ai-composure-f* 18
  "... frames J is held: through the last bullet (f14) and the link (f16).")
(defun lb-ai-composure (e b)
  "The stance's plan fires HOSHA (his CPU, *LB-AI-COMPOSURE*'s level): J held *LB-AI-COMPOSURE-F* frames. No roll."
  (when (>= (lb-ai-level *lb-ai-composure* b) 1.0)
    (ai-press b :quick *lb-ai-composure-f* :act :hold)
    (pace e :ai-composure)))
(defparameter *lb-ai-oki-hiren* '(16 18)
  "The wake-up shot too late for a charge (dream-rsi b3a1, 2026-10-07; b0a2's timing for its execution shot, here on every
late wake-up): SP2 HIRENKYAKU (the 6 m back-slide, the X-Axis shot at its f20) pressed with this many frames (perceived) to
his first hittable frame, so the shot lands on it or just after (b0a2: 18-20 fired on or before it, every one missed).
Measured (HARD, seeds 1-80): 1.9 a match, ~1.6 hits of ~91, HIRENKYAKU 0 -> 4.2 % of his damage, the charged shot 4.3 ->
4.6 %, signature 0.9987 / 0.9979 vs 0.9987 / 0.9981, damage taken 418 / 424 vs 430 / 435 a match.")
(defun lb-wake-left (state sf delay)
  "Frames from now until a fighter perceived DELAY frames ago in STATE at its frame SF can be hit again: down then the
wake-up (*REACTION-FRAMES*, both invulnerable); NIL in any other state (pure)."
  (case state
    (:down (- (+ (getf *reaction-frames* :down 30) (getf *reaction-frames* :wakeup 30)) sf delay))
    (:wakeup (- (getf *reaction-frames* :wakeup 30) sf delay))))
(defun lb-ai-oki-lead ()
  "Frames from the stance's press to the charged shot's fire frame: the stance up, the charge, the shot's startup (pure)."
  (+ *lb-kamae-up* *lb-charge-f* (mv-s (find-move :lb-k-shot))))
(defun lb-ai-oki-shot (e b s d)
  "The base form free (HARD, *LB-AI-OKI*): him perceived down / waking up (LB-WAKE-LEFT): the stance when its charged shot
would fire on his first hittable frame (LEFT within the lead's last 2 frames); too late for that, HIRENKYAKU (a bar) with
LEFT in *LB-AI-OKI-HIREN* (b3a1); before, between and after, hands off till he stands (:NONE). No roll."
  (declare (ignore d))
  (when (>= (lb-ai-level *lb-ai-oki* b) 1.0)
    (let ((left (lb-wake-left (snap-state s) (snap-sf s) (brain-delay b))) (lead (lb-ai-oki-lead)))
      (cond ((null left) nil)
            ((> left lead) (why b :oki-wait :none))
            ((and (>= left (- lead 2)) (kit-command-ok-p e :sig))
             (setf (lbai-oki (lb-ai-state e b)) *match-tick*)
             (pace e :ai-oki-shot)
             (why b :oki-shot :sig))
            ((and (<= (first *lb-ai-oki-hiren*) left (second *lb-ai-oki-hiren*)) (let ((sp (kit-command-move (kit-of e) :sp2))) (and sp (eq (mv-name sp) :lb-hiren)))
                  (kit-command-ok-p e :sp2))                     ; (too late for a charge: HIRENKYAKU's back-slide, its
             (pace e :ai-oki-hiren)                          ; X-Axis shot at f20 on his first hittable frames; b0a2's
             (why b :oki-hiren :sp2))                            ; timing)
            (t (why b :oki-late :none))))))
(defun lb-ai-oki-stance-p (e b f)
  "Was this stance taken for the wake-up shot (LB-AI-OKI-SHOT, its start tick)? Its plan is then the charged shot."
  (and b (>= (lb-ai-level *lb-ai-oki* b) 1.0)
       (<= (- *match-tick* (fighter-sf f)) (+ (lbai-oki (lb-ai-state e b)) 3) (+ (- *match-tick* (fighter-sf f)) 6))))

(defparameter *lb-ai-kin-exit* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "KIN's MUJITTAI ends in his signature (b1a1's; dream-rsi b3a1, 2026-10-07): SP1 onto a recovering / reeling opponent it
still reaches in time, else TENSHIN out back to EN's lines; the wing-blade string only when neither can start.")
(defparameter *lb-ai-kin-hold* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "KIN's hold (b1a2's; dream-rsi b3a1, 2026-10-07): in KIN's MUJITTAI with no exit due, TENSHIN out when it can pay EN's lines
after it, else the stance holds (not the generic neutral's plain step-in); a whiff / idle exit with nothing to exit with
holds too. It yields to his rush (the generic anti-rush answers it).")
(defun lb-ai-kin-exit (e b s &optional why)
  "The stance's exit attack in KIN (*LB-AI-KIN-EXIT*; NIL: the shipped exit): :SP1 when he is perceived busy for its
startup, else :SIG (TENSHIN out) when it can start; else, on a WHY that doesn't force him out (:WHIFF, :IDLE), :NONE (the
stance holds, *LB-AI-KIN-HOLD*). No roll."
  (when (and b (>= (lb-ai-level *lb-ai-kin-exit* b) 1.0) (member (kit-form (kit-of e)) '(:jilliel-kin-mujittai :shin-kin-mujittai)))
    (let ((sp (kit-command-move (kit-of e) :sp1)))
      (cond ((and sp (lb-ai-busy-p s (brain-delay b) (mv-s sp)) (kit-command-ok-p e :sp1)) :sp1)
            ((kit-command-ok-p e :sig) :sig)
            ((and (member why '(:whiff :idle)) (>= (lb-ai-level *lb-ai-kin-hold* b) 1.0)) :none)))))
(defun lb-ai-kin-hold (e b s d)
  "KIN's MUJITTAI (HARD, *LB-AI-KIN-HOLD*), no exit due and no rush of his coming (LB-AI-RUSH-P): TENSHIN out with its price
+ *LB-AI-KIN-RUN-FS*, else :NONE. No roll."
  (declare (ignore d))
  (when (and (>= (lb-ai-level *lb-ai-kin-hold* b) 1.0) (member (kit-form (kit-of e)) '(:jilliel-kin-mujittai :shin-kin-mujittai))
             (not (lb-ai-rush-p s)))
    (if (and (>= (gauges-fs (gauges e)) (+ *lb-switch-fs* *lb-ai-kin-run-fs*)) (kit-command-ok-p e :sig))
        (progn (pace e :ai-kin-hold-out) (why b :kin-hold-out :sig))
        (why b :kin-hold :none))))

(defparameter *lb-ai-turtle* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The turtle (b0a1 / b1a2's; dream-rsi b3a1, 2026-10-07): the generic guard-break event (a guard held *AI-GUARD-BREAK-HOLD*
within *AI-GUARD-BREAK-RANGE*, BRAIN-BREAK-KEY: one per guard) and the anti-parry wait are taken by his kit, so the
refused Breaker (b3a0's LB-AI-VETO-P) is never left as a dead press.")
(defun lb-ai-turtle (e b s d)
  "Any form free (HARD, *LB-AI-TURTLE*): a parry of his up close: hands off (:NONE). A long guard up close (the generic
guard-break's event, consumed): the base form the stance (its plan TAISHA: LB-AI-TURTLE-STANCE-P), KIN TENSHIN out (a hop
back when it can't pay), EN a hop back. No roll."
  (when (>= (lb-ai-level *lb-ai-turtle* b) 1.0)
    (cond ((and (member :parry (snap-flags s)) (eq (snap-phase s) :main) (< d 4.0)) (why b :turtle-parry :none))
          ((and (eq (snap-state s) :guard) (>= (snap-guard-t s) *ai-guard-break-hold*) (< d *ai-guard-break-range*)
                (/= (brain-break-key b) (snap-start s)))
           (setf (brain-break-key b) (snap-start s))
           (pace e :ai-turtle)
           (case (kit-form (kit-of e))
             (:base (when (kit-command-ok-p e :sig)
                      (setf (lbai-turtle (lb-ai-state e b)) *match-tick*)
                      (why b :turtle :sig)))
             ((:jilliel-kin :shin-kin) (if (kit-command-ok-p e :sig) (why b :turtle-out :sig) (why b :turtle-hop :step)))
             ((:jilliel :shin) (why b :turtle-hop :step)))))))
(defun lb-ai-turtle-stance-p (e b f)
  "Was this stance taken against a guard (LB-AI-TURTLE / LB-AI-HELD-AIM, its start tick)? Its plan (LB-AI-KAMAE): TAISHA
within 3 m, else the charged shot."
  (and b (>= (lb-ai-level *lb-ai-turtle* b) 1.0)
       (<= (- *match-tick* (fighter-sf f)) (+ (lbai-turtle (lb-ai-state e b)) 3) (+ (- *match-tick* (fighter-sf f)) 6))))
(defun lb-ai-held-aim (e b s d)
  "The base form free (HARD, *LB-AI-HELD-AIM*): him perceived guarding within *LB-AI-HUNT-BAND*'s far end: close or a long
guard, the stance against it (LB-AI-TURTLE-STANCE-P); else hands off (:NONE). No roll."
  (when (and (>= (lb-ai-level *lb-ai-held-aim* b) 1.0) (member (snap-state s) '(:guard :guard-hit))
             (<= d (second *lb-ai-hunt-band*)))
    (if (and (or (<= d *ai-guard-break-range*) (and (eq (snap-state s) :guard) (>= (snap-guard-t s) *ai-guard-break-hold*)))
             (kit-command-ok-p e :sig))
        (progn (setf (lbai-turtle (lb-ai-state e b)) *match-tick*)
               (pace e :ai-held-aim-shot)
               (why b :held-aim-shot :sig))
        (why b :held-aim :none))))
(defparameter *lb-ai-kin-cash* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "KIN's cash-in (b1a2's; dream-rsi b3a1, 2026-10-07): KIN free with him perceived reeling or recovering long enough for
SP1's startup: SANREN's three X-Axis lines (the owl's KIN: MISUJI's), not the generic follow-up / punish's plain string.")
(defun lb-ai-kin-cash (e b s d)
  "KIN free (HARD, *LB-AI-KIN-CASH*): him perceived reeling / recovering for SP1's startup within its lines' reach, not red
within the Kikon's range (the generic rush takes his Konpaku): SP1. No roll."
  (when (>= (lb-ai-level *lb-ai-kin-cash* b) 1.0)
    (let ((sp (kit-command-move (kit-of e) :sp1)))
      (when (and sp (<= d 18.0) (lb-ai-busy-p s (brain-delay b) (mv-s sp)) (kit-command-ok-p e :sp1)
                 (not (and (kikon-ready-p e) (member (snap-state s) '(:stun :air)) (< d (ai-table e :kikon-range 7.0)))))
        (pace e :ai-kin-cash)
        (why b :kin-cash :sp1)))))

;;; ---------------------------------------------------------------- the refine (dream-rsi round 1, cell b3a2, from b3a1)
;;; DUEL_LILLE §24. Levels by difficulty as above (HARD 1, EASY / NORMAL 0: the shipped CPU, no new roll), deterministic,
;;; read once per event. b3a1's engines kept whole; three leaks located in b3a1's own logs (held-out seeds 41-80), each a
;;; moment the stance (no guard, 6 f up) was raised in front of an opponent who could act first:
;;;   the burst read      his BLUE breaks free (seen through the perceived SNAPs: reeling, then free with his reaction not
;;;                       run out): the base form waits out his burst's free frames (b2a1's idea, credited; b2a1 read the
;;;                       HUD gauge, here the perceived break); the eye still answers a threat first (LB-AI-BURST-WAIT)
;;;   the sniper's step   the hunt's stance on a free opponent within 2 m planned the shipped TAISHA (16 f startup at his
;;;                       feet: a third hit, a fifth was hit or perfect-Hohoed); now the HIRENKYAKU dash back (iframes)
;;;                       then HOSHA, and HOSHA at once onto a whiff (the composure holds off ORANGE)
;;;   the blow-away aim   the loop's latched stance (K1 -> L) on an opponent K1 just blew away planned TAISHA into the air
;;;                       (a whiff whose recovery ate the wake-up shot's window: HIRENKYAKU or a hunt instead); now the
;;;                       stance dashes back and holds the charged X-Axis shot for his first hittable frame (LB-AI-BLOW-STEP)
;;; and one adaptive read: the TAISHA read   a TAISHA at a close guard that got him punished (a perfect Hoho, then the
;;;                       counter and a string) turns the next one into the dash back and the charged shot (LB-AI-TAISHA-READ)
(defparameter *lb-ai-burst-read* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The burst read (dream-rsi b3a2, 2026-10-07; b2a1's located leak, read through the perception): b3a1 took 43 damage a
match within 90 f of the opponent's BLUE, 28 of it right after a hunt's stance (the burster is free and invulnerable 20 f,
Lille repelled to idle: Rukia's ICE-CASH SHIRAFUNE, Kenpachi's KE-STANCE took the stance as a recovery).")
(defparameter *lb-ai-burst-wait* 30
  "... frames after his break-free (real time: the perceived break + the perception delay) the base form waits:
*BURST-INVULN* 20 + 10 (b2a1's 30, measured there: 70 -> 26 damage taken in that window).")
(defun lb-ai-break-free-p (old old-left new)
  "Pure: do two perceived states in a row show him breaking free (REPEL!: a Burst Reverse or an awakening puts him neutral
at once): OLD reeling (:stun with OLD-LEFT >= 2 frames of it still to run, or :air), NEW out of every reaction?"
  (and (or (and (eq old :stun) (>= old-left 2)) (eq old :air))
       (not (member new '(:stun :air :down :wakeup :guard-hit :cine)))
       t))
(defun lb-ai-burst-age (b &optional (wait *lb-ai-burst-wait*))
  "His break-free seen by brain B within WAIT frames (real time): its age (the perceived break K steps back + the delay),
or NIL. (The ring holds 32 SNAPs: WAIT 30 at HARD's delay 8 looks 22 back.)"
  (loop for k from 0 below (- wait (brain-delay b))
        for s1 = (lb-ai-snap-back b k) for s0 = (lb-ai-snap-back b (1+ k))
        while (and s1 s0)
        when (lb-ai-break-free-p (snap-state s0) (snap-left s0) (snap-state s1))
          return (+ k (brain-delay b))))
(defun lb-ai-burst-wait (e b s)
  "The base form free (HARD, *LB-AI-BURST-READ*), after the eye: hands off (:NONE: no stance into his free frames) while
his break-free is younger than *LB-AI-BURST-WAIT* frames: first while REPEL!'s push still slides him (his own state: free,
pushed, MOTION-KB-LEFT; the CPU's first free step comes after the burst's hitstop, before its perception can show the
break), then while the perceived SNAPs show it (LB-AI-BURST-AGE); never against his rush (LB-AI-RUSH-P: the generic
anti-rush answers it). Counted once per break. No roll."
  (when (and (>= (lb-ai-level *lb-ai-burst-read* b) 1.0) (not (lb-ai-rush-p s)))
    (let* ((kb (motion-kb-left (motion e)))
           (age (if (plusp kb) (max 0 (- *burst-push-frames* kb)) (lb-ai-burst-age b))))
      (when age
        (let ((ai (lb-ai-state e b)) (t0 (- *match-tick* age)))
          (when (> (abs (- t0 (lbai-burst ai))) 2)
            (setf (lbai-burst ai) t0)
            (pace e :ai-burst-wait)))
        (why b :burst-wait :none)))))
;; the TAISHA read (adaptive, one read per TAISHA)
(defparameter *lb-ai-taisha-read* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "The TAISHA read (dream-rsi b3a2, 2026-10-07): the held aim / the turtle pierce a guard within 3 m with TAISHA (b1a2's;
16 f startup after the stance's 6, the 3 m back-slide in its view). An opponent who answers it (a HARD Ichigo perfect-Hohos
35 of 50, then COUNTER, his Bankai string and Kikon: ~300 a time) is read: once his Reishi fell between such a TAISHA and
his next free step, the next one is the stance's HIRENKYAKU dash back (iframes) then the charged shot through the guard
(:DASH); a TAISHA not punished clears the read.")
(defparameter *lb-ai-taisha-punished* 1
  "... TAISHAs at a guard punished in a row before the read switches to the dash and the shot (dream-rsi b3a2).")
(defun lb-ai-taisha-plan (punished dash-ok)
  "Pure: the stance's branch against a close guard: TAISHA (:K), or after PUNISHED >= *LB-AI-TAISHA-PUNISHED* in a row the
dash back then the charged shot (:DASH) when DASH-OK."
  (if (and dash-ok (>= punished *lb-ai-taisha-punished*)) :dash :k))
(defun lb-ai-taisha-read (e b)
  "The stance's plan against a close guard (LB-AI-KAMAE, his CPU; *LB-AI-TAISHA-READ*): LB-AI-TAISHA-PLAN; a TAISHA is
remembered (its tick, his Reishi) for LB-AI-TAISHA-SETTLE. No roll."
  (if (< (lb-ai-level *lb-ai-taisha-read* b) 1.0)
      :k
      (let* ((ai (lb-ai-state e b)) (st (lb e))
             (plan (lb-ai-taisha-plan (lbai-punished ai) (and (not (lbs-dashed st))
                                                              (>= (gauges-fs (gauges e)) *lb-kamae-dash-fs*)))))
        (if (eq plan :k)
            (setf (lbai-taisha ai) *match-tick* (lbai-taisha-hp ai) (gauges-reishi (gauges e))
                  (lbai-taisha-kon ai) (gauges-konpaku (gauges e)))
            (pace e :ai-taisha-read))
        plan)))
(defun lb-ai-taisha-settle (e b)
  "His first free step after a TAISHA at a guard (*LB-AI-TAISHA-READ*): punished (his own Reishi or Konpaku fell since)
counts one,
else the count clears; then forgotten. Always NIL (a bookkeeping step in LB-AI-REFLEX)."
  (when (>= (lb-ai-level *lb-ai-taisha-read* b) 1.0)
    (let ((ai (lb-ai-state e b)))
      (when (and (>= (lbai-taisha ai) 0) (> *match-tick* (+ (lbai-taisha ai) 2)))
        (if (or (< (gauges-reishi (gauges e)) (lbai-taisha-hp ai)) (< (gauges-konpaku (gauges e)) (lbai-taisha-kon ai)))
            (progn (incf (lbai-punished ai)) (pace e :ai-taisha-punished))
            (setf (lbai-punished ai) 0))
        (setf (lbai-taisha ai) -9))))
  nil)
(defun lb-ai-blow-fire-p (charged left up sf)
  "Pure: does the held stance fire its shot now: CHARGED, and his first hittable frame LEFT (perceived; NIL: unknown) within
the shot's startup, or him UP (no longer down), or the stance's hold at its end (SF)?"
  (and charged
       (or (and left (<= left (mv-s (find-move :lb-k-shot)))) up (>= sf (+ *lb-kamae-up* *lb-kamae-max*)))
       t))
(defun lb-ai-blow-step (e f st)
  "The stance held on a blown-away opponent (its plan :OKI, *LB-AI-BLOW*): L held (the stance's hold, up to *LB-KAMAE-MAX*),
the charged shot when LB-AI-BLOW-FIRE-P (his wake-up read off the perceived SNAP: LB-WAKE-LEFT). No roll."
  (let* ((b (ai-brain e)) (sn (and b (lb-ai-seen b)))           ; (his CPU's; the ASSIST's: §24.10)
         (left (and sn (lb-wake-left (snap-state sn) (snap-sf sn) (brain-delay b)))))
    (if (lb-ai-blow-fire-p (lb-kamae-charged-p (lbs-charge st)) left
                           (and sn (not (member (snap-state sn) '(:air :down :wakeup))))
                           (fighter-sf f))
        (progn (setf (lbs-k-plan st) :charge) (pace e :ai-blow-shot) (lb-ai-composure e b) :kamae-l)
        (progn (when b (ai-press b :sig 3 :act :hold)) nil))))

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
          (pace o :opp-trace-roll)
          (when (< (sim-rnd01) (opp-chance (getf k :p 0.0) (brain-difficulty b)))
            (pace o :opp-trace-step)
            (let ((q (pos-of o)))
              (setf (brain-strafe b) (f32 (line-off-strafe (hazard-x on) (hazard-z on) (hazard-yaw on) (aref p 0) (aref p 2)
                                                           (aref q 0) (aref q 2)))))
            (why b :trace-step :side-step)))))))

;;; ---------------------------------------------------------------- ASSIST AUTO COMBO's Lille routes (DUEL_LILLE §24.10)
;;; The user (2026-10-06): 「記得要能與玩家輔助 AI 系統結合，以幫助玩家打出更具風格的漂亮連段」 (§24.1 step 5: AUTO COMBO gets his
;;; full signature routes on the player's J). His kits' :ai name LB-ASSIST-COMBO as :assist-combo (assist.lisp AUTO-ROUTE:
;;; asked every step AUTO COMBO is on, before the generic AUTO COMBO; no other character has the key). "You press, the CPU
;;; chooses": the choices are his CPU's (b3a2's own functions, on the assist's borrowed brain through AI-BRAIN: HARD's
;;; levels), pressed as buttons on his vpad that his ticks read as a human's presses: x*ASSIST-MULT*, FIGHTER-ASSIST-NEXT,
;;; the AUTO tag; his own J is left his where it is the choice (HOSHA out of the stance, a link he latched). A route starts
;;; on his J and carries through the moves it or the assist pressed (LBAS-ROUTE, FIGHTER-ASSISTED) until he is free again.
;;;   1 HOSHA   a bullet hit, J latched: the link K1 (LB-AI-LINK; none into a blown-away opponent, whose wake-up gets the
;;;             charged shot: LB-AI-OKI-SHOT) -> L at once (b1a0's loop) -> the stance -> its branch (LB-AI-KAMAE: HOSHA again on
;;;             the reeling opponent, TAISHA, the dash back, the charged shot held for his first hittable frame) -> ...
;;;   2 EN      an EN attack (his J, or J pressed in it), from its active end: TENSHIN's 2 f cancel where his CPU's would fire
;;;             (LB-AI-SWITCH-IN-P: >= 3 traces with him on a line as it would materialise; the web's count; the crossfire)
;;;             -> TENSHIN in's link J1 on a trace hit -> K latched on it (b3a1's route: J1 K2s K3)
;;;   3 KIN     a J3 / K3 that hit: the CPU's ender (LB-AI-SP-ENDER: the crossfire's L -> TENSHIN out -> EN's J1 laid at
;;;             him -> route 2's cancel -> TENSHIN in -> J1 ...; else SANREN / NIJUSHI-KO); a red opponent's Kikon as the
;;;             generic AUTO COMBO's. The base form's enders likewise (K3's crumple: L into the stance; J3: HIRENKYAKU)
;;; The ASSIST gate's button-masher (habit :dumb) has a brain but is a human's stand-in: his ticks read its vpad
;;; (LB-TICK-BRAIN), so the gate measures these routes, not his CPU's tick rules pressed for free.
(defun lb-tick-brain (e)
  "The brain his ticks decide on (the stance's branch, HOSHA's / TENSHIN's link, EN's walk and cancel, HIRENKYAKU's
direction): his own CPU's; NIL for a human and for the ASSIST gate's button-masher (habit :dumb), read as a human."
  (let ((b (brain e))) (and b (not (eq (brain-habit b) :dumb)) b)))

(defun lb-as-trace-mult (e mult)
  "His traces' damage multiplier MULT at a TENSHIN (LB-MATERIALISE): x*ASSIST-MULT* when the assist pressed that TENSHIN
(FIGHTER-ASSISTED; a hazard's hit has no move for APPLY-HIT's x0.8, and the traces it materialises are that press's hits)."
  (if (fighter-assisted (fighter e)) (* mult *assist-mult*) mult))

(defun lb-as-kind (name kind flags en-tick form link)
  "Pure: which route step a move is (LB-ASSIST-COMBO): NAME its name, KIND / FLAGS its kind and flags, EN-TICK an EN attack
(LB-EN-TICK), FORM his form, LINK what linked it (:hosha / :tenshin, just now) or NIL. :EN :TENSHIN :HOSHA :STANCE, :LOOP
(the base K1 out of HOSHA), :KIN-J1 (KIN's J1 out of TENSHIN in), :ENDER (a J3 / K3 of the base form or KIN), :KIN-K (a KIN
K link), or NIL (not a route's)."
  (cond (en-tick :en)
        ((member name '(:lb-switch :lb-switch-in :lb-switch-in-c :lb-o-switch :lb-o-switch-in :lb-o-switch-in-c)) :tenshin)
        ((eq name :lb-k-j) :hosha)
        ((member name '(:lb-kamae :lb-kamae-k :lb-kamae-re)) :stance)
        ((not (member kind '(:quick :flash))) nil)
        ((and (eq form :base) (eq name :lb-k1) (eq link :hosha)) :loop)
        ((and (lb-kin-form-p form) (member name '(:lb-w-j1 :lb-o-j1)) (eq link :tenshin)) :kin-j1)
        ((and (member :ender flags) (or (eq form :base) (lb-kin-form-p form))) :ender)
        ((and (lb-kin-form-p form) (eq kind :flash)) :kin-k)))

(defun lb-as-stance-cmd (kamae his)
  "Pure: the press for the stance's follow-up KAMAE (LB-AI-KAMAE's: :kamae-j / -k / -l / -step, NIL to wait), HIS J
buffered or not: HOSHA is J (NIL: his own press fires it), TAISHA K, the shot L, HIRENKYAKU Step; :HOLD (wait, his J eaten)."
  (case kamae (:kamae-j (if his nil :q)) (:kamae-k :f) (:kamae-l :sig) (:kamae-step :step) (t :hold)))

(defun lb-as-link-cmd (plan latch his)
  "Pure: HOSHA's / TENSHIN's link by his CPU's PLAN (LB-AI-LINK: :q :f :none) against what he LATCHED (:q :f NIL) or HIS J
pressed now: the plan's button, NIL where his own J / K already is the plan (or he latched K: his), :CLEAR where the plan is
none and his J would link (the latch emptied, his J eaten)."
  (cond ((eq latch :f) nil)
        ((eq plan :f) :f)
        ((eq plan :q) (if (or (eq latch :q) his) nil :q))
        ((or (eq latch :q) his) :clear)))

(defstruct (lbas (:conc-name lbas-))
  (b nil)                                 ; the assist brain it belongs to (a new match: a fresh one)
  (mv nil) (sf -1 :type fixnum) (t0 -1 :type fixnum)   ; the move instance seen (its move, frame, the tick first seen)
  (link nil)                              ; what linked it (LB-AS-LINKED at its first step: :hosha / :tenshin)
  (j nil)                                 ; his J seen during it (pressed, buffered or latched)
  (done nil) (plan nil)                   ; its decision made, its plan (a pending ender's press; a link's :none)
  (route nil)                             ; a route runs: from its first press until he is free again
  (oki nil))                              ; HOSHA's link refused on a blown-away opponent: the wake-up shot is due
(defvar *lb-as* (vector (make-lbas) (make-lbas)) "Per side: the ASSIST routes' state (LB-ASSIST-COMBO).")

(defun lb-as-his-j (vp) "Is his J buffered (pressed, not yet consumed, unmodified)?" (vpad-command-pressed-p vp :quick nil))

(defun lb-as-track (e f b vp)
  "The route state of E's side for brain B, its move instance brought up to date (a new move, or the same one restarted:
a fresh instance), his J this step noted; free (or hit), the route ends."
  (let* ((side (fighter-side f)) (a (svref *lb-as* side)) (mv (and (eq (fighter-state f) :move) (fighter-move f))))
    (unless (eq (lbas-b a) b) (setf a (make-lbas :b b) (svref *lb-as* side) a))
    (cond ((null mv) (setf (lbas-mv a) nil (lbas-j a) nil (lbas-done a) nil (lbas-plan a) nil (lbas-route a) nil))
          ((or (not (eq mv (lbas-mv a))) (< (fighter-sf f) (lbas-sf a)))
           (setf (lbas-mv a) mv (lbas-t0 a) *match-tick* (lbas-j a) nil (lbas-done a) nil (lbas-plan a) nil)
           (setf (lbas-link a) (lb-as-linked (lb e) a))))
    (when mv
      (setf (lbas-sf a) (fighter-sf f))
      (when (or (lb-as-his-j vp) (eq (fighter-queued f) :q)
                (and (member (mv-name mv) '(:lb-k-j :lb-switch :lb-switch-in :lb-switch-in-c :lb-o-switch :lb-o-switch-in
                                            :lb-o-switch-in-c))
                     (eq (lbs-latch (lb e)) :q)))     ; (HOSHA / TENSHIN latch his J: LB-LINK-TICK)
        (setf (lbas-j a) t)))
    a))

(defun lb-as-hold-latch (vp a)
  "After a route's link press in this move (its plan): :NONE, his J eaten (the string's latch takes the last press: his J
would replace the route's K / L); else NIL."
  (when (lbas-plan a) (vpad-consume! vp :quick) :none))

(defun lb-as-press (e a key cmd)
  "A route press: the route runs on; KEY counted in his pacing log (the gates' route counts). CMD."
  (setf (lbas-route a) t)
  (pace e key)
  cmd)

(defun lb-as-unhold (e b vp)
  "After LB-AI-KAMAE ran on the assist's brain B: a hold it asked for is played here, this step (the blow-away aim's L:
VPAD-HOLD!; the composure's J is not needed: no generic ORANGE off a :sig move), so the route decides every step; the
gate masher's own brain lets go of the composure LB-AI-KAMAE gives (BRAIN E)."
  (when (plusp (brain-press-left b))
    (when (eq (brain-press b) :sig) (vpad-hold! vp :sig))
    (setf (brain-press-left b) 0))
  (let ((own (brain e)))
    (when (and own (eq (brain-act own) :hold) (eq (brain-press own) :quick)) (setf (brain-press-left own) 0))))

(defun lb-as-linked (st a)
  "What linked the current move just now (HOSHA's / TENSHIN's link, LB-LINK-TICK: its tick within 2 of the instance's
first step): :hosha / :tenshin, or NIL. (Read once, at its first step: the pacing log clears it on the combo's hit.)"
  (and (<= 0 (- (lbas-t0 a) (lbs-link-t st)) 2) (lbs-link-from st)))

(defun lb-as-hosha (e f vp a st)
  "Route 1, HOSHA: a bullet hit and his J latched (or the route's HOSHA): at the link frame (as his CPU, LB-LINK-TICK), his
CPU's link (LB-AI-LINK at HARD: K1; none into a blown-away opponent: the latch emptied, his J eaten, the wake-up shot due)."
  (let ((own (or (lbas-j a) (lbas-route a) (fighter-assisted f))))
    (cond ((lbas-done a)                                  ; (decided: his later J would latch over it, the last press wins)
           (case (lbas-plan a)
             (:none (setf (lbs-latch st) nil) (vpad-consume! vp :quick) :none)
             (:f (vpad-consume! vp :quick) :none)))
          ((and own (eq (fighter-contact f) :hit) (zerop (fighter-lock f))
                (>= (1+ (fighter-sf f)) (getf (mv-params (fighter-move f)) :link 99)))
           (let* ((plan (lb-ai-link e f st t)) (c (lb-as-link-cmd plan (lbs-latch st) (lb-as-his-j vp))))
             (setf (lbas-done a) t (lbas-plan a) (if (eq c :f) :f (and (eq plan :none) :none)) (lbas-route a) t)
             (case c
               (:f (lb-as-press e a :as-hosha-k1 :f))
               (:clear (setf (lbs-latch st) nil (lbas-oki a) t) (vpad-consume! vp :quick) (pace e :as-hosha-none) :none)
               (t (when (eq plan :none) (setf (lbas-oki a) t)) nil)))))))

(defun lb-as-loop (e f b vp a)
  "Route 1, the base K1 out of HOSHA (his J in it, or the route's): L latched at once (b1a0's loop, *LB-AI-HOSHA-LOOP*: the
stance at f4 once K1 touches him); his J eaten after it (a J would latch J2s over it: the last press wins)."
  (when (and (or (lbas-j a) (lbas-route a) (fighter-assisted f)) (not (lbas-done a)))
    (setf (lbas-done a) t)
    (let* ((kit (fighter-kit f)) (l (kit-l-link kit (mv-name (fighter-move f)))))
      (when (and (>= (lb-ai-level *lb-ai-hosha-loop* b) 1.0) l (not (eq (fighter-queued f) :sig))
                 (kit-command-ok-p e :sig kit nil l))
        (setf (lbas-plan a) :sig)
        (return-from lb-as-loop (lb-as-press e a :as-hosha-loop :sig)))))
  (lb-as-hold-latch vp a))                               ; (pressed: K1 is the route's, no generic plan off its hit)

(defun lb-as-stance (e f b vp a st)
  "Route 1, the shooting stance, the route's (its L the assist's, a plan running) or his J pressed in it: from the frame it
is up, his CPU's branch (LB-AI-KAMAE on the assist's brain: picked once, then carried out) pressed for him; till then and
while it waits (a charge, his wake-up) the stance is held (his J eaten)."
  (when (or (lbas-j a) (lbas-route a) (fighter-assisted f) (lbs-k-plan st))
    (setf (lbas-route a) t)
    (if (< (1+ (fighter-sf f)) *lb-kamae-up*)
        :none                                             ; (not up: his J stays buffered for f6)
        (let* ((kamae (lb-ai-kamae e f st)) (c (lb-as-stance-cmd kamae (lb-as-his-j vp))))
          (lb-as-unhold e b vp)
          (case c
            ((nil) :none)                                ; (HOSHA on his own J)
            (:hold (vpad-consume! vp :quick) :none)
            (:step (vpad-stick! vp 0f0 0f0) (lb-as-press e a :as-stance-step :step))   ; (straight back, his CPU's dash)
            (t (lb-as-press e a (case c (:q :as-stance-j) (:f :as-stance-k) (t :as-stance-l)) c)))))))

(defun lb-as-en (e f b a mv)
  "Route 2, an EN attack (his J, his J pressed in it, or the route's): from its active end, TENSHIN's 2 f cancel where his
CPU's EN tick would cancel: >= 3 traces with him on a line (LB-AI-SWITCH-IN-P), the web's count (LB-AI-WEB-CANCEL-P), the
crossfire's line (LB-AI-XFIRE-CANCEL-P); once a move."
  (when (and (or (lbas-j a) (lbas-route a) (eq (mv-kind mv) :quick)) (not (lbas-done a))
             (>= (1+ (fighter-sf f)) (+ (mv-s mv) (mv-a mv))) (zerop (fighter-lock f)))
    (let ((seen (lb-ai-seen b)))
      (cond ((lb-ai-switch-in-p e b seen *lb-switch-windup-c*) (setf (lbas-done a) t) (lb-as-press e a :as-en-trace :sig))
            ((lb-ai-xfire-cancel-p e b seen) (setf (lbas-done a) t) (lb-as-press e a :as-en-xfire :sig))
            ((lb-ai-web-cancel-p e b f seen) (setf (lbas-done a) t) (lb-ai-web-fired e b) (lb-as-press e a :as-en-web :sig))))))

(defun lb-as-tenshin (e f vp a st mv)
  "Routes 2 / 3, a TENSHIN of the route's (or the assist's): at its link frame his CPU's link (LB-AI-LINK: TENSHIN in's J1 on
a trace hit; TENSHIN out's EN J1 in a crossfire), pressed unless his own J already latched it; none: his J emptied."
  (when (or (lbas-route a) (fighter-assisted f))
    (setf (lbas-route a) t)
    (cond ((lbas-done a)
           (when (eq (lbas-plan a) :none) (setf (lbs-latch st) nil) (vpad-consume! vp :quick))
           :none)
          ((and (>= (1+ (fighter-sf f)) (lb-link-frame e mv)) (zerop (fighter-lock f)))
           (let* ((plan (lb-ai-link e f st nil)) (c (lb-as-link-cmd plan (lbs-latch st) (lb-as-his-j vp))))
             (setf (lbas-done a) t (lbas-plan a) plan)
             (case c
               (:q (lb-as-press e a (if (lb-kin-form-p (lb-link-form (fighter-form f) (lbs-switch-to st))) :as-tenshin-in-j :as-tenshin-out-j) :q))
               (:clear (setf (lbs-latch st) nil) (vpad-consume! vp :quick) (pace e :as-tenshin-none) :none)
               (t :none))))
          (t :none))))

(defun lb-as-k-link-p (e f)
  "Can his current link go on into its K link: one after it (KIT-NEXT), and its pip there (a K link with none ends the
string: MOVE-COMMANDS; STRING-REFLEX's rule)?"
  (let ((kit (fighter-kit f)))
    (and (kit-next kit (mv-name (fighter-move f)) :f)
         (not (and (kit-pip-cmd-p kit :f) (< (gauges-meter (gauges e)) 1f0))))))

(defun lb-as-kin-j1 (e f b vp a)
  "Route 2, KIN's J1 out of TENSHIN in (his J in it, or the route's): K latched at once (b3a1's route, *LB-AI-ROUTE*: J1
K2s K3, K3's crumple for the crossfire; with the K link's pip where the form has pips: LB-AS-K-LINK-P); his J eaten after
it (J2 over it: the last press wins)."
  (when (and (or (lbas-j a) (lbas-route a) (fighter-assisted f)) (not (lbas-done a)))
    (setf (lbas-done a) t)
    (when (and (>= (lb-ai-level *lb-ai-route* b) 1.0) (not (eq (fighter-queued f) :f))
               (lb-as-k-link-p e f))
      (setf (lbas-plan a) :f)
      (return-from lb-as-kin-j1 (lb-as-press e a :as-kin-route :f))))
  (lb-as-hold-latch vp a))

(defun lb-as-kin-k (e f vp a)
  "Route 2, a KIN K link of the route's with a K after it (K2s): K at its hit's land frame (the string to K3, as the
CPU's STRING-REFLEX: K2s has only K3); no generic plan off it."
  (when (lbas-route a)
    (cond ((lbas-done a) (lb-as-hold-latch vp a))
          ((and (eq (fighter-contact f) :hit) (>= (fighter-land-sf f) 0) (>= (fighter-sf f) (fighter-land-sf f)))
           (setf (lbas-done a) t)
           (if (and (lb-as-k-link-p e f) (not (eq (fighter-queued f) :f)))
               (progn (setf (lbas-plan a) :f) (lb-as-press e a :as-kin-k :f))
               :none)))))

(defun lb-as-ender (e f a kit)
  "Route 3, a J3 / K3 that hit (the base form's or KIN's): his CPU's choice, made when his J is seen in it (or at once in
the route's): a red opponent's Kikon (the generic AUTO COMBO's rule), else LB-AI-SP-ENDER (KIN's K3 the crossfire's L;
SANREN / NIJUSHI-KO; the base form's K3 L into the stance, its J3 HIRENKYAKU); nothing else (no generic SP cancel or
ORANGE off his ender: his CPU's). The ender is the route's from its hit: no generic plan off it."
  (when (and (eq (fighter-contact f) :hit) (>= (fighter-land-sf f) 0) (>= (fighter-sf f) (fighter-land-sf f)))
    (cond ((lbas-done a) :none)
          ((or (lbas-j a) (lbas-route a) (fighter-assisted f))
           (setf (lbas-done a) t)
           (let ((c (cond ((and (kikon-ready-p e) (not (ai-sb-finish-p e)) (kit-command-ok-p e :kikon kit t)) :kikon)
                          ((not (eq (state-of (opp-of e)) :air)) (lb-ai-sp-ender e kit)))))
             (if (and c (not (eq c :none)))
                 (lb-as-press e a (case c (:kikon :as-ender-kikon) (:sig (if (lb-kin-form-p (kit-form kit)) :as-xfire :as-ender-l))
                                    (t :as-ender-sp))
                              c)
                 :none)))
          (t :none))))

(defun lb-as-free (e f b s d vp a)
  "Route 1, the base form free with him perceived down (LB-WAKE-LEFT): HOSHA's refused link due, or his J pressed: his
CPU's wake-up shot (LB-AI-OKI-SHOT: the stance whose charged shot lands on his first hittable frame, else HIRENKYAKU),
waiting (his J eaten: it would whiff) till its frame; while HOSHA's blow-away still flies, his J eaten too; him up again:
forgotten."
  (when (eq (fighter-form f) :base)
    (let ((state (and s (snap-state s))))
      (cond ((not (member state '(:air :down :wakeup))) (setf (lbas-oki a) nil) nil)
            ((eq state :air) (and (lbas-oki a) (progn (vpad-consume! vp :quick) :none)))   ; (HOSHA's blow-away: his landing)
            ((not (or (lbas-oki a) (lb-as-his-j vp))) nil)
            (t (setf (lbas-oki a) t)
               (let ((c (lb-ai-oki-shot e b s d)))
                 (case c
                   ((:sig :sp2) (setf (lbas-oki a) nil) (lb-as-press e a (if (eq c :sig) :as-oki-shot :as-oki-hiren) c))
                   ((nil) (setf (lbas-oki a) nil) nil)
                   (t (vpad-consume! vp :quick) :none))))))))

(defun lb-assist-combo (e f b s d vp)
  "His kits' :assist-combo (assist.lisp AUTO-ROUTE; DUEL_LILLE §24.10): the ASSIST's AUTO COMBO along his signature routes,
on the assist's brain B (S, D as it perceives him), his vpad VP: a command, :NONE (the route holds the step) or NIL (the
generic AUTO COMBO)."
  (let* ((a (lb-as-track e f b vp)) (mv (lbas-mv a)))
    (if mv
        (let* ((st (lb e)) (kit (fighter-kit f)) (form (fighter-form f)))
          (case (lb-as-kind (mv-name mv) (mv-kind mv) (mv-flags mv) (eq (mv-tick mv) 'lb-en-tick) form (lbas-link a))
            (:en (lb-as-en e f b a mv))
            (:tenshin (lb-as-tenshin e f vp a st mv))
            (:hosha (lb-as-hosha e f vp a st))
            (:stance (lb-as-stance e f b vp a st))
            (:loop (lb-as-loop e f b vp a))
            (:kin-j1 (lb-as-kin-j1 e f b vp a))
            (:ender (lb-as-ender e f a kit))
            (:kin-k (lb-as-kin-k e f vp a))))
        (and (member (fighter-state f) '(:idle :guard :run)) (zerop (fighter-lock f)) (lb-as-free e f b s d vp a)))))

;; every form of his names it (assist.lisp AUTO-ROUTE reads the key off the form's kit)
(dolist (form '(:base :jilliel :jilliel-mujittai :jilliel-kin :jilliel-kin-mujittai :shin :shin-mujittai :shin-kin
                :shin-kin-mujittai))
  (let ((k (find-kit :lille form)))
    (unless (getf (kit-ai k) :assist-combo)
      (setf (kit-ai k) (list* :assist-combo 'lb-assist-combo (kit-ai k))))))

;;; ================================================================ AI: the learning CPU's Lille situations (DUEL_LILLE §24.9)
;;; The user's plan (DUEL_LILLE §24.1 step 5): the learning CPU (learn.lisp, ai-learn.lisp; DUEL_LEARNING §11) gains his own
;;; situations, so a CPU Lille facing a human learns the human's answers to his signature and answers them in character.
;;; Only a learner runs any of this (a CPU facing a human: VS CPU, ENDLESS, the learning gate; LRN-KIT, ai-learn.lisp
;;; LEARN-ATTACH!); CPU VS CPU, the gates and every other character never get here. What the human does is what Lille's CPU
;;; perceives (the delayed SNAP; his own state at once), a read is one roll of the learner's own stream per event
;;; (LEARN-KIT-READ: p_exploit x *LB-LEARN-DIFF*, EASY <= NORMAL <= HARD), and every answer is a command of his kit.
;;;   :trace    he (perceived) stands on one of Lille's live traces he could have seen, Lille in EN: how he leaves it,
;;;             :right / :left of its line as Lille laid it (LB-LEARN-SIDE), :back along it (still on it), a :hoho, a
;;;             :guard raised on it, or :take (still on it at the episode's end; an attack is no answer here). Read at
;;;             the onset (one roll): a side -> the snap timed for his step (TENSHIN
;;;             in once his step off is seen and the live traces, turned toward where he lands, would hit him there:
;;;             LB-LEARN-COVERED-P), else first a K fan at him (its side line plus the 10 deg snap reach his landing from
;;;             ~9 m); :back -> TENSHIN in at once (the lines run 31 m: backing off along one stays on it)
;;;   :tenshin  Lille's TENSHIN in from EN's neutral (the 16 f wind-up he can see): his answer (:guard :hoho :step :attack
;;;             :back :take). Read when the CPU would switch from neutral: :guard -> the materialise is held (no neutral
;;;             switch, *LB-LEARN-HOLD* frames) until he is busy; :hoho -> held until his Hoho is spent (seen within its
;;;             lockout, or no flash step for one: LB-LEARN-HOHO-SPENT-P); the fast cancels (J1's line + 2 f) still go
;;;   :hosha    Lille's HOSHA on a free opponent: his answer (:guard :hoho :step :attack :back :take; a guard, Hoho or Step
;;;             already under way at the stance's plan counts: no reaction beats its first bullet). Read at that plan (one
;;;             roll; LB-LEARN-KAMAE-PLAN, watched only when HOSHA fires): :guard (him standing) and :hoho -> the HIRENKYAKU dash
;;;             back (iframes) then the charged shot (through guard); :step / :back -> the charged shot (its aim follows
;;;             him through the charge); :attack -> the dash back then HOSHA
;;; The debug habits 7-9 (debug.lisp *HABITS*: LB-HABIT-TRACE, -TENSHIN, -HOSHA) are the learning gate's scripted players.
(defparameter *lb-learn-diff* '(:easy 0.5 :normal 1.0 :hard 1.5)
  "His learning CPU's read chance x this by difficulty (on the learner's p_exploit, 0.15-0.6; at most 0.9 at HARD): EASY <=
NORMAL <= HARD (DUEL_LILLE §24.9, the integration agent 2026-10-07).")
(defparameter *lb-learn-episode* '(:trace 45 :tenshin 20 :hosha 18)
  "Frames a situation waits for his answer, + the perception delay (the wind-up's 16 f and HOSHA's last bullet at f14
are what he answers; DUEL_LILLE §24.9).")
(defparameter *lb-learn-hold* 60
  "Frames a :tenshin read holds the neutral switch at most (one read per window; DUEL_LILLE §24.9).")
(defparameter *lb-learn-holds* '(:guard :hoho)
  "The :tenshin reads that hold the neutral switch (LB-LEARN-HOLD; DUEL_LILLE §24.9).")
(defparameter *lb-learn-step-off* 0.6
  "Metres off the onset line toward the read side that count as his step off begun (a walk; a Step is seen as one).")

;; pure: host-tested (tests/duel-rules-test.lisp)
(defun lb-learn-side (lx lz yaw x z)
  "Pure: which side of the line laid at (LX LZ) along YAW the point (X Z) is on, as Lille faces along it: :RIGHT (its right,
(-fz fx), TOWARD-STRAFE-DIR's +1) or :LEFT."
  (if (>= (+ (* (- x lx) (- (fwd-z yaw))) (* (- z lz) (fwd-x yaw))) 0) :right :left))
(defun lb-learn-lateral (yaw side ox oz x z)
  "Pure: metres (X Z) has moved from (OX OZ) toward SIDE (:RIGHT / :LEFT) of a line along YAW."
  (* (if (eq side :right) 1.0 -1.0) (+ (* (- x ox) (- (fwd-z yaw))) (* (- z oz) (fwd-x yaw)))))
(defun lb-learn-landing (yaw side ox oz)
  "Pure: where a Step (*STEP-DISTANCE*) from (OX OZ) off a line along YAW to its SIDE lands: values x z."
  (let ((k (* *step-distance* (if (eq side :right) 1.0 -1.0))))
    (values (+ ox (* k (- (fwd-z yaw)))) (+ oz (* k (fwd-x yaw))))))
(defun lb-learn-answer (hprev hs new away)
  "Pure: his answer starting this step to HOSHA or TENSHIN (perceived states HPREV -> HS, NEW: a new move of his, AWAY:
metres he moved away since the onset): :HOHO, :STEP, :ATTACK, :GUARD, :BACK, or NIL."
  (cond ((and (eq hs :hoho) (not (eq hprev :hoho))) :hoho)
        ((and (eq hs :step) (not (eq hprev :step))) :step)
        ((and (eq hs :move) (or (not (eq hprev :move)) new)) :attack)
        ((and (eq hs :guard) (not (eq hprev :guard))) :guard)
        ((> away *learn-back*) :back)))
(defun lb-learn-onset-answer (hs)
  "Pure: his answer already under way when HOSHA / TENSHIN in begins (perceived state HS): a guard, a Hoho, a Step; NIL (a
move he is in is no answer: only a new one is, LB-LEARN-ANSWER)."
  (case hs ((:guard :guard-hit) :guard) (:hoho :hoho) (:step :step)))
(defun lb-learn-trace-answer (hprev hs off side along)
  "Pure: how he leaves the trace he stands on, starting this step (perceived HPREV -> HS): a :HOHO, a :GUARD raised on it,
OFF the line to its SIDE (:RIGHT / :LEFT), or :BACK ALONG it more than *LEARN-BACK* m; or NIL (an attack is no answer
here: the question is how he leaves the line)."
  (cond ((and (eq hs :hoho) (not (eq hprev :hoho))) :hoho)
        ((and (eq hs :guard) (not (eq hprev :guard))) :guard)
        (off side)
        ((> along *learn-back*) :back)))
(defun lb-learn-kamae-plan (read d dash-ok still)
  "Pure: the stance's branch instead of HOSHA for his predicted answer READ at D m (DASH-OK: the stance's HIRENKYAKU can
go; STILL: he is perceived standing, not running or stepping): a guard, on him STILL, the HIRENKYAKU dash back (iframes)
then the charged shot through it (:DASH; measured against TAISHA within 3 m / the quick shot, whose startup a HARD
opponent punished: §24.9), else HOSHA; a Hoho the dash back then the charged shot (:DASH; :CHARGE without the dash); a
Step or backing off the charged shot (its aim follows him through the charge); an attack the dash back then HOSHA
(:DASH-J; TAISHA's back-slide without the dash); else HOSHA (:J)."
  (declare (ignore d))
  (case read
    (:guard (if (and still dash-ok) :dash :j))
    (:hoho (if dash-ok :dash :charge))
    ((:step :back) :charge)
    (:attack (if dash-ok :dash-j :k))
    (t :j)))
(defun lb-learn-hoho-spent-p (seen-age delay fs)
  "Pure: is his Hoho spent for a materialise pressed now (16 f wind-up): his flash step FS under a Hoho's, or his last
Hoho seen SEEN-AGE frames ago (NIL: none) still locks the next one out past the materialise (*HOHO-LOCKOUT* from its
real start, DELAY frames before it was seen)?"
  (or (< fs *fs-hoho*)
      (and seen-age (< seen-age (- *hoho-lockout* *lb-switch-windup* delay)))
      nil))
(defun lb-learn-hold (read busy spent)
  "Pure: does a :tenshin READ hold the neutral switch now: a :GUARD or :HOHO read unless he is BUSY (recovering / reeling
through the wind-up: no answer), and a Hoho read unless his Hoho is SPENT?"
  (and (member read *lb-learn-holds*) (not busy) (not (and (eq read :hoho) spent)) t))

;; the shell
(defstruct (lbl (:conc-name lbl-))
  "His learner's own state within a match (LRN-KDATA)."
  (own-mv nil) (own-sf 0 :type fixnum)                      ; his move last step (the onsets of HOSHA and TENSHIN in)
  (on-id 0 :type fixnum)                                    ; the trace the human was perceived on last step (id; 0 none)
  (ox 0f0 :type single-float) (oz 0f0 :type single-float)   ; the open situation's onset: his perceived position,
  (ux 0f0 :type single-float) (uz 0f0 :type single-float)   ; ... the way from Lille to him (his :back)
  (lx 0f0 :type single-float) (lz 0f0 :type single-float) (lyaw 0f0 :type single-float) (lw 0f0 :type single-float)   ; :trace's line
  (len 0 :type fixnum)                                      ; ... its episode's frames
  (trace-read nil) (trace-until -1 :type fixnum) (fan nil) (snapped nil)   ; the :trace read, its life, its K fan, its snap
  (ten-read nil) (ten-until -1 :type fixnum)                ; the :tenshin read and its window
  (hoho -9999 :type fixnum))                                ; tick his last Hoho was seen starting
(defun lb-learn-state (l) (or (lrn-kdata l) (setf (lrn-kdata l) (make-lbl))))
(defun lb-learn-l (b) "Brain B's learner when it reads Lille's situations (LRN-KIT), else NIL." (let ((l (and b (brain-learn b)))) (and l (lrn-kit l) l)))
(defun lb-learn-scale (b) (float (getf *lb-learn-diff* (brain-difficulty b) 1.0) 1.0))
(defun lb-learn-acted (e l cmd)
  "A read of his situations acted on with CMD: the learner's count (LEARN-COUNT-READ: the gate's reads, paid), the log."
  (learn-count-read e l cmd)
  (pace e cmd)
  (clog "~a read ~a" (side-name e) cmd))

(defun lb-learn-trace-under (e x z hr &optional (age 0))
  "The newest of E's live traces at least AGE frames old (the perceived position is that old: one he could have seen)
whose line (as laid) passes within its width + HR of (X Z), or NIL (its hazard)."
  (let ((on nil))
    (do-entities (h (hz hazard))
      (let ((dd (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (lbh-p dd) (lbh-live dd) (>= (hazard-age hz) age)
                   (<= (line-dist (hazard-x hz) (hazard-z hz) (hazard-yaw hz) 0.6 *lb-trace-len* x z) (+ (lbh-width dd) hr))
                   (or (null on) (> (lbh-id dd) (lbh-id (hazard-data on)))))
          (setf on hz))))
    on))

(defun lb-learn-open (e s l k key)
  "Open his situation KEY (LEARN-KIT-OPEN) at the perceived SNAP S: the onset's position and the way to him; HOSHA /
TENSHIN in meeting an answer already under way (LB-LEARN-ONSET-ANSWER) counts it at once."
  (let* ((dx (- (snap-x s) (aref (pos-of e) 0))) (dz (- (snap-z s) (aref (pos-of e) 2))) (m (max 1e-3 (sqrt (+ (* dx dx) (* dz dz))))))
    (setf (lbl-ox k) (snap-x s) (lbl-oz k) (snap-z s) (lbl-ux k) (f32 (/ dx m)) (lbl-uz k) (f32 (/ dz m))
          (lbl-len k) (+ (getf *lb-learn-episode* key 30) (brain-delay (brain e)))))
  (learn-kit-open l key)
  (let ((now (and (member key '(:hosha :tenshin)) (lb-learn-onset-answer (snap-state s)))))
    (when now (learn-kit-close l now))))

(defun lb-learn-step (e b s d l)
  "His learner's step (LEARN-DEF-KIT's :step; ai-learn.lisp LEARN-STEP, a learner of his only): the onsets (his own HOSHA and
TENSHIN in at once; the human onto a trace, perceived), the open situation's answer (LB-LEARN-ANSWER /
LB-LEARN-TRACE-ANSWER; at its end :TAKE, or :GUARD held through), the :trace read at its onset (one roll)."
  (declare (ignore d))
  (let* ((k (lb-learn-state l)) (f (fighter e)) (mv (and (eq (fighter-state f) :move) (fighter-move f)))
         (hs (snap-state s)) (hprev (lrn-hstate l)) (new (/= (snap-start s) (lrn-hstart l)))
         (hr (body-hurt-r (model-body (model (opp-of e))))) (x (snap-x s)) (z (snap-z s)))
    (when (and (eq hs :hoho) (not (eq hprev :hoho))) (setf (lbl-hoho k) *match-tick*))
    (when (and mv (or (not (eq mv (lbl-own-mv k))) (< (fighter-sf f) (lbl-own-sf k))))   ; a move of his begins
      (case (mv-name mv)                                     ; (:hosha opens at the stance's plan: LB-LEARN-KAMAE)
        ((:lb-switch-in :lb-o-switch-in) (setf (lbl-ten-until k) -1) (lb-learn-open e s l k :tenshin))
        ((:lb-switch-in-c :lb-o-switch-in-c)                   ; (a cancel's materialise: no answer to it)
         (setf (lbl-ten-until k) -1)
         (when (learn-kit-open-p l :trace) (learn-kit-close l nil)))))
    (setf (lbl-own-mv k) mv (lbl-own-sf k) (if mv (fighter-sf f) 0))
    (let* ((tr (and (lb-en-form-p (fighter-form f)) (lb-learn-trace-under e x z hr (brain-delay b))))
           (id (if tr (lbh-id (hazard-data tr)) 0)))
      (when (and tr (> id (lbl-on-id k)) (< (lrn-ksit l) 0))  ; onto a trace he could see (or a newer one laid on him)
        (setf (lbl-lx k) (hazard-x tr) (lbl-lz k) (hazard-z tr) (lbl-lyaw k) (hazard-yaw tr) (lbl-lw k) (lbh-width (hazard-data tr)))
        (lb-learn-open e s l k :trace)
        (setf (lbl-trace-read k) (learn-kit-read l :trace (lb-learn-scale b)) (lbl-trace-until k) (+ *match-tick* (lbl-len k))
              (lbl-fan k) nil (lbl-snapped k) nil))
      (setf (lbl-on-id k) id))
    (when (>= (lrn-ksit l) 0)
      (let ((sit (aref (getf (lrn-kit l) :situations) (lrn-ksit l))) (end (>= (incf (lrn-kep-t l)) (lbl-len k))))
        (cond ((member hs '(:stun :air :down :wakeup))         ; hit: he took it (on a trace: no answer)
               (learn-kit-close l (if (eq sit :trace) nil :take)))
              ((eq sit :trace)
               (let ((ans (lb-learn-trace-answer hprev hs
                                                 (> (line-dist (lbl-lx k) (lbl-lz k) (lbl-lyaw k) 0.6 *lb-trace-len* x z) (+ (lbl-lw k) hr))
                                                 (lb-learn-side (lbl-lx k) (lbl-lz k) (lbl-lyaw k) x z)
                                                 (+ (* (- x (lbl-ox k)) (fwd-x (lbl-lyaw k))) (* (- z (lbl-oz k)) (fwd-z (lbl-lyaw k)))))))
                 (cond (ans (learn-kit-close l ans)) (end (learn-kit-close l :take)))))
              (t (let ((ans (lb-learn-answer hprev hs new (+ (* (- x (lbl-ox k)) (lbl-ux k)) (* (- z (lbl-oz k)) (lbl-uz k))))))
                   (cond (ans (learn-kit-close l ans))
                         (end (learn-kit-close l (if (member hs '(:guard :guard-hit)) :guard :take)))))))))))

(defun lb-learn-stepped-p (k s side)
  "Is his step off the :trace line toward SIDE seen: a Step, or him LB-LEARN-LATERAL *LB-LEARN-STEP-OFF* that way?"
  (or (eq (snap-state s) :step)
      (>= (lb-learn-lateral (lbl-lyaw k) side (lbl-ox k) (lbl-oz k) (snap-x s) (snap-z s)) *lb-learn-step-off*)))
(defun lb-learn-covered-p (e k side)
  "Would his live traces, turned toward his landing off the :trace line on SIDE (LB-LEARN-LANDING), hit him there?"
  (multiple-value-bind (x z) (lb-learn-landing (lbl-lyaw k) side (lbl-ox k) (lbl-oz k))
    (plusp (lb-ai-web-count e x z (body-hurt-r (model-body (model (opp-of e))))))))
(defun lb-learn-snap-p (e l k s)
  "The :trace read's TENSHIN in now (once per read, TENSHIN ready): :BACK while he is still on a trace; a side once his
step off is seen and the traces cover his landing. Counted (LB-LEARN-ACTED)."
  (let ((r (lbl-trace-read k)))
    (when (and r s (not (lbl-snapped k)) (<= *match-tick* (lbl-trace-until k)) (lb-switch-ready-p e)
               (case r
                 (:back (lb-learn-trace-under e (snap-x s) (snap-z s) (body-hurt-r (model-body (model (opp-of e))))))
                 ((:left :right) (and (lb-learn-stepped-p k s r) (lb-learn-covered-p e k r)))))
      (setf (lbl-snapped k) t)
      (lb-learn-acted e l (if (eq r :back) :lb-snap-back :lb-snap-side))
      t)))

(defun lb-learn-en (e b s d)
  "EN free (LB-AI-REFLEX, before LB-AI-EN): the :trace read's answer: TENSHIN in (LB-LEARN-SNAP-P), or, his side read and
his landing not yet covered, one K fan at him (its lines above the reserve: LB-AI-LAY-OK-P). No roll (the read was made
at the onset)."
  (declare (ignore d))
  (let ((l (lb-learn-l b)))
    (when l
      (let* ((k (lb-learn-state l)) (r (lbl-trace-read k)))
        (cond ((lb-learn-snap-p e l k s) (why b :learn-snap :sig))
              ((and (member r '(:left :right)) (not (lbl-fan k)) (not (lbl-snapped k)) (<= *match-tick* (lbl-trace-until k))
                    (not (lb-learn-stepped-p k s r)) (not (lb-learn-covered-p e k r))
                    (lb-ai-lay-ok-p (gauges-fs (gauges e)) :k) (kit-command-ok-p e :f))
               (setf (lbl-fan k) t)
               (lb-learn-acted e l :lb-fan)
               (why b :learn-fan :f)))))))

(defun lb-learn-cancel-p (e b s)
  "EN's tick, an EN attack past its active end: the :trace read's TENSHIN in through the 2 f cancel (LB-LEARN-SNAP-P)."
  (let ((l (lb-learn-l b))) (and l (lb-learn-snap-p e l (lb-learn-state l) s))))

(defun lb-learn-hold-p (e b s)
  "Where his CPU would TENSHIN in from EN's neutral (LB-AI-EN): the :tenshin read, one per window (made at the first such
moment, standing *LB-LEARN-HOLD* frames or until a TENSHIN starts): hold the switch now (LB-LEARN-HOLD)? NIL without a
learner (the shipped switch)."
  (let ((l (lb-learn-l b)))
    (when l
      (let ((k (lb-learn-state l)))
        (when (> *match-tick* (lbl-ten-until k))
          (let ((r (learn-kit-read l :tenshin (lb-learn-scale b))))
            (setf (lbl-ten-until k) (+ *match-tick* *lb-learn-hold*) (lbl-ten-read k) (and (member r *lb-learn-holds*) r))
            (when (lbl-ten-read k) (lb-learn-acted e l (if (eq r :guard) :lb-hold-guard :lb-hold-hoho)))))
        (lb-learn-hold (lbl-ten-read k) (lb-ai-busy-p s (brain-delay b) *lb-switch-windup*)
                       (lb-learn-hoho-spent-p (- *match-tick* (lbl-hoho k)) (brain-delay b) (gauges-fs (gauges (opp-of e)))))))))

(defun lb-learn-kamae (e b f plan)
  "The stance's PLAN (LB-AI-KAMAE, once a stance, his CPU): HOSHA on a free opponent is read (one roll: LEARN-KIT-READ
:hosha) and answered (LB-LEARN-KAMAE-PLAN); anything else, or no learner, as planned."
  (let ((l (lb-learn-l b)))
    (if (and l (eq plan :j) (not (member (state-of (opp-of e)) '(:stun :air))))   ; (his own hit felt at once: the loop)
        (let* ((r (learn-kit-read l :hosha (lb-learn-scale b))) (s (lb-ai-seen b))
               (p (lb-learn-kamae-plan r (fighter-dist f) (and (not (lbs-dashed (lb e))) (>= (gauges-fs (gauges e)) *lb-kamae-dash-fs*))
                                       (and s (member (snap-state s) '(:idle :guard)) t))))
          (if (eq p :j)
              (when s (lb-learn-open e s l (lb-learn-state l) :hosha))   ; (HOSHA fires: his answer to it is watched)
              (lb-learn-acted e l (case r (:guard :lb-hosha-guard) (:hoho :lb-hosha-hoho) (:attack :lb-hosha-attack) (t :lb-hosha-step))))
          p)
        plan)))

;; the learning gate's scripted players (debug.lisp *HABITS* 7-9: HABIT-FIRE, a CPU P1 facing Lille)
(defun lb-habit-trace (e b)
  "Habit 7: Step off any trace of Lille's it sees under it (laid at least its perception delay ago) while his TENSHIN is
ready, always to the line's right as he laid it (LB-LEARN-SIDE's :RIGHT). T when it pressed."
  (let ((o (opp-of e)))
    (when (and (eq (fighter-character (fighter o)) :lille) (lb-switch-ready-p o) (not (kit-rooted (kit-of e))))
      (let* ((p (pos-of e)) (hr (+ (body-hurt-r (model-body (model e))) *ai-line-margin*)) (on nil))
        (do-entities (h (hz hazard))
          (let ((dd (hazard-data hz)))
            (when (and (eql (hazard-owner hz) o) (lbh-p dd) (lbh-live dd) (>= (hazard-age hz) (brain-delay b))
                       (<= (line-dist (hazard-x hz) (hazard-z hz) (hazard-yaw hz) 0.6 *lb-trace-len* (aref p 0) (aref p 2))
                           (+ (lbh-width dd) hr))
                       (or (null on) (> (lbh-id dd) (lbh-id (hazard-data on)))))
              (setf on hz))))
        (when on
          (let* ((yaw (hazard-yaw on)) (q (pos-of o)) (ux (- (aref q 0) (aref p 0))) (uz (- (aref q 2) (aref p 2))))
            (setf (brain-strafe b) (if (>= (+ (* (- (fwd-z yaw)) (- uz)) (* (fwd-x yaw) ux)) 0) 1f0 -1f0))   ; (strafe +1 is
            (ai-press b :step 1 :act :side-step)                                                               ; (-uz ux))
            (setf (brain-why b) :habit)
            t))))))
(defun lb-habit-tenshin (e b s)
  "Habit 8: a Hoho on seeing Lille's TENSHIN in wind-up (from EN's neutral, before its materialise at f16), when it can
Hoho. T when it pressed."
  (let ((mv (snap-move s)) (f (fighter e)) (g (gauges e)))
    (when (and mv (eq (snap-state s) :move) (member (mv-name mv) '(:lb-switch-in :lb-o-switch-in)) (< (snap-sf s) *lb-switch-windup*)
               (zerop (fighter-hoho-lock f)) (>= (gauges-fs g) *fs-hoho*) (not (kit-rooted (kit-of e))))
      (ai-press b :step 1 :modded t :act :hoho)
      (setf (brain-why b) :habit)
      t)))
(defun lb-habit-hosha (e b s)
  "Habit 9: guard HOSHA as its leap begins (Lille's own move, not the perceived one: a player who expects HOSHA from the
stance; no reaction beats its first bullet at f6, and a guard before the stance's f6 is read by its plan). T when it
pressed."
  (declare (ignore s))
  (let* ((o (opp-of e)) (fo (fighter o)) (mv (fighter-move fo)))
    (when (and mv (eq (fighter-state fo) :move) (eq (mv-name mv) :lb-k-j) (< (fighter-sf fo) 14))
      (ai-press b :guard 24 :act :hold)
      (setf (brain-why b) :habit)
      t)))

(learn-def-kit :lille :situations #(:trace :tenshin :hosha) :actions #(:left :right :back :guard :hoho :step :attack :take)
               :step 'lb-learn-step)

;;; ================================================================ debug: tests, the pacing log (debug.lisp dispatches)
(defun lille-acc-line ()
  "After a gate row: a \"duel lille\" line per side that played him (the pacing log, docs/duel/DUEL_LILLE.md §13)."
  (dolist (e (list *p1* *p2*))
    (when (and (entity-alive-p e) (eq (fighter-character (fighter e)) :lille))
      (let ((st (lb e)))
        (log-msg "duel lille ~a seed ~d awakened ~a form ~a eyes ~d sealed ~a ~{~(~a~) ~a~^ ~}" (side-name e) *match-seed*
                 (gauges-awakened (gauges e)) (fighter-form (fighter e)) (lbs-eyes st) (lbs-sealed st)
                 (svref *pacing* (fighter-side (fighter e))))))))

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
  "His debug commands (debug.lisp *CHAR-DEBUG*, the range 79000-79999, docs/duel/DUEL_GAMEPLAY.md): 79000+k LILLE-TEST k;
79200+f (f 0-399) the Jilliel Kikon cinematic held at frame f (its 305 f, past the 10-frame steps of 79100+; decision 56)."
  (cond ((< c 79100) (lille-test (- c 79000)))
        ((<= 79200 c 79599) (lille-cine-at 3 (- c 79200)))   ; the Jilliel Kikon cinematic held at any frame (decision 56)
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

(defparameter *lb-judge-gap* 6.0
  "The Jilliel Kikon cinematic stages him this far from the opponent (CINE-PLACE; his place given back at its end): its
shots are framed for it (the user, 2026-10-08: 「我發現是隨著進入毀魂技時兩個的距離而影響視角ㄟ」).")
(defparameter *lb-judge-head* 1.65 "LB-SHOT-BEHIND: the opponent's head, metres over his feet ...")
(defparameter *lb-judge-keep* 0.35
  "... kept at most this share of the frame's half-height below its centre (the letterbox's bar starts at 0.82), on a
landscape screen (a portrait one widens the lens and backs off: %PORTRAIT-DOLLY, its framing kept as the user liked it).")

(defun lb-shot-behind (v a back side h look)
  "A shot from behind V toward A (decision 56's acceleration beat): the camera BACK m behind V on the A -> V line, SIDE m to
its right (+), H high, aimed at A's body LOOK m up; A is the subject (kept in the frame), V a silhouette in a low corner."
  (let* ((p (pos-of a)) (q (pos-of v)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (d (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (ux (/ dx d)) (uz (/ dz d)))
    (setf *cine-close* nil *cine-subject* a)
    ;; V's head kept above the letterbox (its bar covers the frame's bottom 9 %): the aim tilted down, if need be, until
    ;; his head sits *LB-JUDGE-KEEP* of the half-height below the centre (the user, 2026-10-08: on a desktop he went off
    ;; the bottom)
    (let* ((ex (+ (aref q 0) (* back ux) (* side (- uz)))) (ez (+ (aref q 2) (* back uz) (* side ux)))
           (dl (max 0.5 (sqrt (+ (expt (- (aref p 0) ex) 2) (expt (- (aref p 2) ez) 2)))))
           (dv (max 0.5 (sqrt (+ (expt (- (aref q 0) ex) 2) (expt (- (aref q 2) ez) 2)))))
           (ev (atan (- (+ (aref q 1) *lb-judge-head*) h) dv))
           (ea0 (atan (- look h) dl))
           (ea (if (> (window-height) (window-width)) ea0
                   (min ea0 (+ ev (atan (* *lb-judge-keep* (tan (* 0.5 *lens-fov*)))))))))
      (cine-cam ex h ez (aref p 0) (+ h (* dl (tan ea))) (aref p 2)))))
(defparameter *lb-judge-giant* 3.0
  "The Jilliel Kikon cinematic draws Lille this many times his size in beats 4-6 (f192-277 since Amendment 2; decision
56's amendment, the user 2026-10-08: 「Lille 放大約 3 倍」「第 4 到 6 段」): a look, CINE-SCALE.")
(defun lb-shot-pierce (a v n ang dist)
  "Close on pierce N's point in V (*LB-JUDGE-PIERCE*, the Kikon cinematic's slowed hits, Amendment 2): the camera DIST m
from it at ANG degrees round V's facing (0 = on the side of A, whom he faces), a little above, looking at it."
  (let* ((p (pos-of a)) (q (pos-of v)) (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2)))
         (d (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (fx (/ dx d)) (fz (/ dz d)) (rx (- fz)) (rz fx)
         (pp *lb-judge-pierce*) (u (aref pp (* 3 n))) (y (+ (aref q 1) (aref pp (1+ (* 3 n)))))
         (tx (+ (aref q 0) (* u rx))) (tz (+ (aref q 2) (* u rz)))
         (c (cos (deg ang))) (sn (sin (deg ang))) (ex (- (* c fx) (* sn rx))) (ez (- (* c fz) (* sn rz))))
    (setf *cine-close* t *cine-subject* nil)
    (cine-cam (+ tx (* dist ex)) (+ y 0.15) (+ tz (* dist ez)) tx y tz)))

(defcine lb-jilliel-kikon-cine (a v :len 305 :hold 215)
  "The Jilliel Kikon 神の裁き (§10.4; decision 56's storyboard and its amendments, DUEL_LILLE §23.37): 1 open (0-40), low
and close in a slow orbit: the wings gathered round him and shaking, snapped open into a ring on f24 (a negative, a
shake), held; 2 the black card (40-90), 神の裁き, from behind him the opponent framed through the ring, the 24 holes
lighting one by one; 3 the first shots (90-192) on the stage: each fired from diagonally behind him or before him (a
recoil, a crack) and on its hit the slow motion (CINE-SLOW: the clips and effects at 1/5 for 40 f, 1/3 for 25 f, 1/2 for
15 f; the lines and holes on the same effect time, *LB-JUDGE-TIME*), the camera close on the pierce, orbiting;
4 the acceleration (192-242): the white card, the opponent a black silhouette, the lines faster and faster (48 pierces in
all, VFX-LB-JUDGE), each a white hole in him, the camera low behind him looking up at Lille drawn x3 (*LB-JUDGE-GIANT*,
beats 4-6), pushing in; 5 the riddled silhouette held in silence before the giant (242-262); 6 the verdict (262-277): low
beside the opponent, the giant's wings close down and on that frame (268) he shatters (合翼即碎), a manga frame; 7 the card
gone, Lille x1 again, a wide shot, the wings settling (277-305). His wings' gathering, ring, lit holes and close are
LILLE-DRAW's, from the frame (%LB-SP-DRIVE!)."
  ;; 1 open: gathered and shaking, the snap on f24, held
  (at 0 (cine-place a v *lb-judge-gap*) (cine-clip a :lb-w-judge-open :blend 0) (cine-clip v :sh-bound :blend 4)
      (play-sfx :awaken-rise) (shot-on a 20 3.6 0.45 :look 2.0) (lens 56))
  (during (0 40) (shot-on a (+ 20 (* 30 u)) (- 3.6 (* 0.3 u)) 0.45 :look 2.0))   ; (the slow orbit)
  (at 24 (impact-frame :negative 2) (shake 0.2 0.25) (play-sfx :lb-lock))
  ;; 2 the card (DIST from the aim, AHEAD on)
  (at 40 (card :black) (back-rim 50 0.61 0.77 0.67) (shot-on a 173 9.6 2.4 :look 1.8 :ahead 6.0) (lens 40)
      (caption "神の裁き" :reading "KAMI NO SABAKI" :sub "KIKON" :side 0) (silence 48))
  (during (40 90) (shot-on a 173 (- 9.6 (* 0.6 u)) 2.4 :look 1.8 :ahead 6.0))
  (at 78 (caption-exit))                                ; (its 0.3 s slice done before the slowed hits)
  ;; 3 the first shots: each fired in view, its hit slowed with the camera on the pierce
  (at 90 (card nil) (shot-on a 148 6.8 1.7 :look 1.9 :ahead 2.4) (lens 46))
  (at 96 (cine-clip a :lb-w-judge-shot :blend 0) (play-sfx :lb-crack) (shake 0.2 0.25))
  (at 99 (cine-slow 0.2) (cine-clip v :sh-kikon-victim :blend 2) (lb-shot-pierce a v 0 40 1.5) (lens 40))
  (during (99 139) (lb-shot-pierce a v 0 (+ 40 (* 30 u)) (- 1.5 (* 0.3 u))))
  (at 139 (cine-slow 1) (shot-on a -142 7.4 1.4 :look 1.9 :ahead 2.6) (lens 44))
  (at 143 (cine-clip a :lb-w-judge-shot :blend 0) (play-sfx :lb-crack) (shake 0.2 0.25))
  (at 146 (cine-slow 0.33333334) (cine-clip v :sh-kikon-victim :blend 2) (lb-shot-pierce a v 1 55 1.6) (lens 40))
  (during (146 171) (lb-shot-pierce a v 1 (+ 55 (* 25 u)) (- 1.6 (* 0.2 u))))
  (at 171 (cine-slow 1) (shot-on a 35 6.0 0.6 :look 2.0) (lens 50))
  (at 174 (cine-clip a :lb-w-judge-shot :blend 0) (play-sfx :lb-crack) (shake 0.2 0.25))
  (at 177 (cine-slow 0.5) (cine-clip v :sh-kikon-victim :blend 2) (lb-shot-pierce a v 2 120 1.3) (lens 40))
  (during (177 192) (lb-shot-pierce a v 2 (+ 120 (* 20 u)) (- 1.3 (* 0.15 u))))
  ;; 4 the acceleration: the white card, his silhouette; Lille drawn x3 (to f277: CINE-SCALE), from low behind the
  ;; opponent looking up past him at the giant (his head and shoulders in a lower corner), pushing in
  (at 192 (cine-slow 1) (card :white) (silhouette-black v) (impact-frame :negative 1) (cine-clip a :lb-w-judge-volley :blend 2)
      (cine-scale a *lb-judge-giant*) (lens 46) (lb-shot-behind v a 5.0 1.8 0.5 6.2))
  (during (192 242) (lb-shot-behind v a (- 5.0 (* 0.8 u)) (- 1.8 (* 0.2 u)) 0.5 (+ 6.2 (* 0.4 u))))
  (when (and step-p (<= 192 cf 241))                    ; a crack for the first shots, then every other one
    (let ((n (position cf *lb-judge-shots*))) (when (and n (or (< n 14) (evenp n))) (play-sfx :lb-crack :pitch (+ 1.0 (* 0.01 (- cf 192)))))))
  (during (90 268) (vfx-lb-judge a v cf))
  ;; 5 the still
  (at 242 (shot-on v 150 3.6 0.5 :look 2.3) (lens 50) (hold-both a v 20) (silence 20))   ; (his back, the giant beyond)
  ;; 6 the verdict: the wings close down; on that frame he shatters
  (at 262 (lens 46) (lb-shot-behind v a 4.6 -1.7 0.5 6.0) (cine-clip a :lb-w-judge-close :blend 0))   ; (the giant's wings
  (at 268 (impact-frame :manga 10) (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3))   ;  close
      (play-sfx :konpaku-shatter) (shake 0.3 0.4))                                                                     ;  over him)
  ;; 7 the end: the card goes with the giant (he never stands on the stage x3)
  (at 277 (unsilhouette) (card nil) (cine-scale a 1) (shot-on a 110 8.5 1.5 :look 1.8) (lens 50)
      (cine-clip a :lb-w-stance :blend 14)))

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
in each form and look); while the Jilliel Kikon cinematic runs, 10 of its VFX-LB-JUDGE too (a \"judge\" line, decision 56)."
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
        (let ((c *cine*))                               ; the Jilliel Kikon cinematic's lines and holes (decision 56)
          (when (and c (eq (cine-name c) 'lb-jilliel-kikon-cine))
            (log-msg "lille consing (10 draws, B): judge ~d at frame ~d"
                     (per (vfx-lb-judge (cine-a c) (cine-v c) (cine-cf c))) (cine-cf c))))
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
(defvar *lb-face-ang* 8 "Debug 79199's camera angle round his facing: each call the next of 8 (front) and 75 (his left side).")
(defcine lb-face-cine (a v :len 900 :hold 900)
  "Debug 79199's still: a long-lens close-up of A's head (the model review), held."
  (at 0 (cine-clip a (kit-stance (kit-of a)) :blend 0) (shot-on a *lb-face-ang* 2.6 2.3 :look 2.25) (lens 24))
  (during (0 900) (shot-on a *lb-face-ang* 2.6 2.3 :look 2.25)))
(defun lille-art-debug (c)
  "79100 + 19 i + k (k 0-18): cinematic i (*LB-CINES*) held at frame 10 k; 79195 his looks' consing (LILLE-CONS-PROBE);
79196 P1's eye opens now (its look: a pip spent, nothing dodged); 79197 P1 Lille as JILLIEL KIN 5 m from Kenpachi (the
rework's rig, DUEL_LILLE §22.5); 79198 Lille as P2 facing the behind camera 4 m from Kenpachi, each call the next of JILLIEL
/ KIN / the owl EN / the owl KIN (the front view); 79199 a close-up of P2's head (LB-FACE-CINE, after 79198: the model review,
2026-10-08)."
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
          ((= n 99) (abort-cine) (start-cine 'lb-face-cine *p2* *p1*) (setf *lb-face-ang* (if (= *lb-face-ang* 8) 75 8)))
          (t (log-msg "duel lille: no debug command ~d" c)))))
(pushnew '(79100 79199 lille-art-debug) *char-debug* :test #'equal)

;;; ================================================================ rework R (2026-10-06): the traces' look (cosmetic, 0 B a frame)
(defun-fast lb-trace-look (hz rdt)
  "A live trace's look (HAZARD-DRAW; DUEL_LILLE §22.2): a faint jade line (the owl's gold, decision 36) on the floor from 0.6 m ahead of where it was
laid to the wall, its width pulsing (SP2's thick one wider; 2.5x for 24 frames after the opponent crossed onto it,
decision 41); nothing once materialised (the X-axis line's flash, LB-LOOK,
takes over). Its numbers go through *LB-V* (lille-art.lisp's %LB-FLOOR-LINE): 0 B."
  (declare (single-float rdt))
  (setf rdt 0f0)                                        ; (unused: HAZARD-DRAW's signature)
  (let ((d (hazard-data hz)))
    (when (and (lbh-p d) (lbh-live d))
      (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
             (x0 (+ x (* 0.6f0 ux))) (z0 (+ z (* 0.6f0 uz)))
             (pulse (+ 0.8f0 (* 0.2f0 (f-sin (+ (* 5f0 (fx-clock)) (* 0.7f0 (i->f (mod (lbh-id d) 9))))))
                       (if (and (>= (lbh-cross d) 0) (< (- *match-tick* (lbh-cross d)) 24)) 1.5f0 0f0)))   ; crossed: flares (decision 41)
             (w (* pulse (if (eq (lbh-src d) :sp2) 0.14f0 0.04f0))))
        (declare (single-float x z yaw ux uz x0 z0 pulse w))
        (%lb-floor-line (if (> (lb-fxs (if (eql (hazard-owner hz) *p1*) 0 1) 15) 0.5f0) 3 1)   ; (the owl's: gold, decision 36;
                        x0 z0 ux uz (%lb-wall x0 z0 ux uz) w))))                                ;  LILLE-DRAW's flag, no lookup)
  nil)
