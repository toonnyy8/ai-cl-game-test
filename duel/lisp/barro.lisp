;;;; barro.lisp — LILLE BARRO II (roster index 6, kit :barro, display name "LILLE II"), docs/duel/DUEL_LILLE_V2.md: the
;;;; rebuilt Lille, a separate fighter built from a copy of lille.lisp (the old Lille stays as he is, index 5). The user's
;;;; rules (2026-10-09): 萬物貫通 THE X-AXIS on the lines (a block drains 40 of the guard gauge and lets 30 % through, the
;;;; line runs 31 m); the base form's L is the shooting stance whose L / SP1 / SP2 carry it and fill the 狙擊 gauge (3 pips,
;;;; +1 a hit), whose J spends a pip for a snap shot, its K every pip for a shot by their count (TAISHA / 穿甲弾 / 破陣弾,
;;;; decision V9); the awakening JILLIEL in two modes: melee (:jilliel-kin)
;;;; and ranged (:jilliel, its L / SP1 / SP2 lay trace lines for flash step); J / K go back to melee; J touching him or any
;;;; K's first active frame materialises the traces near him (萬物貫通 hits); J3 -> L the backstep into ranged, K3 -> L the
;;;; recall (every trace taken back, a derivative string by their count); U in every awakened form the intangible stance
;;;; MUJITTAI (the user 2026-10-09: 「覺醒後的 U 還是保持開了就進入無敵的狀態」); melee SP1 / SP2 fire directly as the old KIN's
;;;; (the user 2026-10-09: 「近戰模式的 SP1／SP2 跟原版一樣會直接放出，只有遠程才會變成軌跡」); the owl's revival (P at <= 4
;;;; Konpaku) on the same two modes, the old owl's numbers (x1.1 / x1.1, R - 1, refunds 5 / 2, Kikon 4, Trompete's reflect
;;;; and seal kept on the owl's melee SP2).
;;;; Sim code shares nothing with lille.lisp (every function, knob, struct, move and hazard here is BR- / :BR-: a change to
;;;; either file never moves the other's gate rows). The art is shared by reference (the user: 「角色動畫可以將之前的版本進行
;;;; 重新組織」): his moves name Lille's clips, bodies (:lille :lille-jilliel :lille-jilliel-kin :lille-shin), weapon :diagramm,
;;;; his kits Lille's cinematics and draw hook (LILLE-DRAW: it reads only the form and the move's clip), his look-only hazards
;;;; Lille's LB-LOOK (their data an LBH, read by nothing in the sim). barro-art.lisp holds his own looks (the trace lines, the
;;;; stance's aim line, the 狙擊 pips) and, later, the clips Lille never had (*BR-STAND-INS*).
;;;; Plain CL above the hooks: the host rules test loads it.
(in-package :duel)

;;; ================================================================ knobs (DUEL_LILLE_V2 §3-§6)
;; 萬物貫通 THE X-AXIS (§3, decision V1)
(defparameter *br-x-guard* 40
  "萬物貫通: the guard gauge a blocked line drains (gauge 100, a usual block ~30; the 3rd blocked one breaks guard). New,
2026-10-09, the user's decision V1 「被擋扣 40、穿透 30%」 (the old Lille's *LB-X-GUARD* 30).")
(defparameter *br-x-chip* 0.30
  "萬物貫通: the fraction of a blocked line's damage that goes through (the chip rule: it never kills). New, 2026-10-09, the
user's decision V1 (the old 0.15).")
(defparameter *br-x-len* 31.0
  "萬物貫通 「射程距離無限」: a line's length, metres (the arena's diameter, radius 15, + 1; the old shot's). New, 2026-10-09,
the user (as metres).")

;; the base form (§4)
(defparameter *br-walk* 3.4 "Walk m/s, the base form (the old Lille's *WALK-LILLE*, copied 2026-10-09).")
(defparameter *br-run* 8.5 "Run m/s, the base form (copied 2026-10-09).")
(defparameter *br-mult* 1.3 "Damage dealt x, the base form (the old *LILLE-MULT* 1.3, copied 2026-10-09; [G] a gate knob).")
(defparameter *br-taken* 1.0 "Damage taken x, the base form (copied 2026-10-09).")
(defparameter *br-aim-track* 60.0 "Degrees / s he turns in the shooting stance (copied 2026-10-09).")
(defparameter *br-kamae-up* 6 "The stance's frame where it is up: its follow-ups fire from here (copied 2026-10-09).")
(defparameter *br-kamae-tap* 30 "Frames the stance holds past its f6 on a tap of L (copied 2026-10-09) ...")
(defparameter *br-kamae-max* 90 "... and at most while L is held; then R 14 (copied 2026-10-09).")
(defparameter *br-snipe-max* 3
  "The 狙擊 gauge's pips (BRS-SNIPE): 0-3; +1 when the stance's L / SP1 / SP2 hits (once a move, not on a block), -1 for
each J / K conversion. New, 2026-10-09, the user's decision V1 「3 格，命中 +1，轉換一次 -1」.")
(defparameter *br-shot-dmg* 50 "The stance's L 万物貫通: damage, flat (new 2026-10-09 [G]; the old quick shot 40).")
(defparameter *br-snipe-close* 3.0
  "The stance's L 万物貫通 that hits him within this many metres fills 2 狙擊 pips, farther 1 (cap *BR-SNIPE-MAX*) (new
2026-10-10, decision V8, the user: 「普攻累積的資源少，並增加額外高風險高回報率的資源回收手段」, close sniping 3 m: +2).")
(defparameter *br-snipe-close-n* 2 "... the pips a close hit fills (new 2026-10-10, decision V8: +2; a far hit +1).")
(defparameter *br-k-sanren-dmg* 30 "The stance's SP1: each of its three 萬物貫通 lines (new 2026-10-09 [G]).")
(defparameter *br-k-hiren-dmg* 50 "The stance's SP2: the shot after the 6 m back-slide (new 2026-10-09 [G]).")
(defparameter *br-snap-dmg* 40
  "The stance's J at >= 1 pip, 速射 the snap shot (new 2026-10-09 [G]; kept by decision V9b, the user 2026-10-10:
「等等，取消跳射改回用速射」).")
;; the snap shot's links (decision V9c, the user 2026-10-10: 「透過以下更改強化速射的性能：1. 減少 step 跟速射之間的切換硬直 2. 讓速射跟
;; J 可以互相銜接」; 「兩邊都可取消」, 「J 連段→L 開架→J 速射；速射命中→J1」)
(defparameter *br-dash-snap-f* 3
  "The stance Step's frame from which a J fires the stance's J (the snap shot; J1 at 0 pips) (new 2026-10-10, decision V9c
「減少 step 跟速射之間的切換硬直」, 「兩邊都可取消」; f3 [G]; before: the Step's f11, back in the stance at its f6).")
(defparameter *br-step-snap-delay* 3
  "The stance Step: a J at >= 1 pip from its *BR-DASH-SNAP-F* fires the snap shot this many frames later WHILE the Step
slides on (decision V9i, the user 2026-10-10: 「常態 L > J 的速射幫我改成可以在 step 的過程中使用，達成類似原本跳射的效果」; 「繼續滑完」,
「照 Step 回到架勢」, 「一槍」, 「開槍就取消」 the iframes) [G 3 f], at the latest on *BR-STEP-SNAP-LAST*.")
(defparameter *br-step-snap-last* 10
  "... the Step's last frame a shot fires on (its f11 is back in the stance, *BR-KAMAE-BACK*) (new 2026-10-10, decision V9i).")
(defparameter *br-snap-step-f* 8
  "The snap shot's frame from which its recovery cancels into the stance Step 飛廉脚 (once per stance, its 10 flash step; it
returns to the stance as usual) (new 2026-10-10, decision V9c 「兩邊都可取消」; f8 = after its shot, S 6 + A 2 [G]).")
(defparameter *br-snap-link* 8
  "The snap shot's frame from which, on its hit, its recovery cancels into J1 (a J pressed during it is latched; no chase: J1
connects only up close) (new 2026-10-10, decision V9c 「速射命中→J1」; f8 [G]).")
;; the stance's K: a shot by the pips spent (decision V9, the user 2026-10-10: 「K 改成依據累積的資源數打出不同效果的槍擊」, 「四段效果」);
;; every pip is spent; the numbers [G]. At 0 pips the plain K1 (decision V9d, the user 2026-10-10: 「0 格時不能用架式 J / K」,
;; 「照你最初的規則：變成普通 J1／K1」: V9's row 0, 退射 40 without 萬物貫通 (*BR-TAISHA0-DMG* 40, R *BR-TAISHA0-R* 24), is gone)
(defparameter *br-taisha-dmg* 70
  "Stance K at 1 pip: 退射 TAISHA with 萬物貫通 (new 2026-10-09 [G]; the old 60 on a 6 m line; decision V9 row 1 keeps it).")
(defparameter *br-senko-dmg* 110
  "Stance K at 2 pips: 穿甲弾 SENKO-DAN, 萬物貫通, a knockdown on hit (new 2026-10-10, decision V9 row 2 [G]).")
(defparameter *br-hajin-dmg* 150
  "Stance K at 3 pips: 破陣弾 HAJIN-DAN, 萬物貫通, a guard break on block (:guard-crush) (new 2026-10-10, decision V9 row 3 [G]).")
(defparameter *br-taisha-r* 28 "... at 1 pip (24 -> 28, 2026-10-10, decision V9 [G]) ...")
(defparameter *br-senko-r* 32 "... at 2 pips (new 2026-10-10, decision V9 [G]) ...")
(defparameter *br-hajin-r* 36 "... at 3 pips (new 2026-10-10, decision V9 [G]).")
(defparameter *br-sanren-dmg* 30 "SP1 outside the stance: each of three lines, 20 m, no 萬物貫通 (new 2026-10-09 [G]).")
(defparameter *br-hiren-dmg* 40 "SP2 outside the stance: the shot after the slide, 20 m, no 萬物貫通 (new 2026-10-09 [G]).")
(defparameter *br-plain-len* 20.0 "SP1 / SP2 outside the stance: their lines' length, metres (new 2026-10-09 [G]).")

;; the two routes (decision V8, the user 2026-10-10: 「我想將設計轉成具有兩種不同特性的戰鬥風格 — 高速循環：特徵是高速、低攻、破綻小，
;; 能取用部分累積的資源進行小爆發並不斷循環。 — 高攻循環：特徵是高攻、低速、破綻大，爆發時會將所有的資源一次輸出」; 「J / K feel split in every
;; form」): every J / K string of every form (base J1-J3 / K1-K3, JILLIEL's wings, the owl's claws, their J2s / K2s copies)
;; is written with its old numbers and BR-DEFSTRING applies these (BR-V8-SPEC); the clip plays at old-S / new-S (:clip-s),
;; so it still reaches its hit pose on the new hit frame
(defparameter *br-j-speed* 2
  "Decision V8, the J route 「高速、低攻、破綻小」: a J's startup and recovery each this many frames shorter (new 2026-10-10;
floors *BR-J-MIN-S* / *BR-J-MIN-R*) ...")
(defparameter *br-j-min-s* 4 "... the startup at least this (new 2026-10-10, decision V8) ...")
(defparameter *br-j-min-r* 6 "... the recovery at least this (new 2026-10-10, decision V8) ...")
(defparameter *br-j-mult* 0.85 "... its damage x this, rounded (new 2026-10-10, decision V8) ...")
(defparameter *br-j-adv* 2
  "... and its block advantage this many frames higher (new 2026-10-10, decision V8 「raised toward ±0」 [G]: + 2 for every
J, so J1 / J2 -2 -> 0, J3 -4 -> -2; the owl's +1 kept on top: -1 -> +1, -3 -> -1).")
(defparameter *br-k-slow* 2
  "Decision V8, the K route 「高攻、低速、破綻大」: a K's startup and recovery each this many frames longer (new 2026-10-10)
...")
(defparameter *br-k-link-slow* 1
  "... but a K link's (K2 / K3 / K2s) effective startup (S - :enter, the budget's 14) only this many longer, 14 -> 15: its
:enter grows by *BR-K-SLOW* - this (new 2026-10-10, decision V8 [G]: at + 2, 16, a J's 18 f flinch ends as K2s / K3
hits (J's A 3 + 16 - 1 = 18): J -> K would no longer combo; 15 is the most that still does, host-tested) ...")
(defparameter *br-k-mult* 1.20 "... its damage x this, rounded (new 2026-10-10, decision V8) ...")
(defparameter *br-k-adv* -4
  "... and its block advantage this many frames lower (new 2026-10-10, decision V8 「-4 more (punishable)」: K1 / K2 -3 -> -7,
K3 -20 -> -24; the owl's -2 -> -6, -19 -> -23).")

;; JILLIEL (§5)
(defparameter *br-walk-en* 3.0 "Walk m/s, ranged (EN, afloat; the old *WALK-JILLIEL*, copied 2026-10-09).")
(defparameter *br-run-en* 8.0 "Run m/s, ranged (the old *RUN-JILLIEL*, copied 2026-10-09).")
(defparameter *br-walk-kin* 3.8 "Walk m/s, melee (KIN's legs; the old *WALK-KIN*, copied 2026-10-09).")
(defparameter *br-run-kin* 8.5 "Run m/s, melee (the old *RUN-KIN*, copied 2026-10-09).")
(defparameter *br-jilliel-mult* 1.0 "Damage dealt x, JILLIEL (copied 2026-10-09).")
(defparameter *br-jilliel-taken* 1.1 "Damage taken x, JILLIEL (copied 2026-10-09).")
(defparameter *br-gg-regen* 0.36
  "JILLIEL's (and the owl's) guard gauge refill x outside MUJITTAI (the stance never refills): the old *JILLIEL-GG-REGEN*,
copied 2026-10-09 with MUJITTAI (the user: 「覺醒後的 U 還是保持開了就進入無敵的狀態」).")
(defparameter *br-jilliel-lift* 0.5 "JILLIEL is drawn this many metres up (kit :lift; a look; copied 2026-10-09).")
(defparameter *br-owl-lift* 0.35 "The owl's ranged form is drawn this many metres up (a look; copied 2026-10-09).")
(defparameter *br-to-en-f* 12 "Melee L: the turn into ranged mode, frames (new 2026-10-09 [G]).")
;; the pendulum (decision V6, 2026-10-10): J3 -> L backsteps into ranged, ranged J dashes in (the old Lille's TENSHIN in;
;; decision V6a, 2026-10-10: only a J in a ranged L / SP1 / SP2's window, any other ranged J is J1 in place)
(defparameter *br-backstep* 5.0 "J3 -> L 後撤: metres back over *BR-BACKSTEP-F* (new 2026-10-09 [G]; kept by decision V6) ...")
(defparameter *br-backstep-f* 14
  "... frames (new 2026-10-09 [G]); a ranged lay (L / SP1 / SP2) may start only from this frame on, the dash's end (decision
V6, the user 2026-10-10: 「衝刺結束才能接」; the backstep's 8 f recovery is cancelled by it) ...")
(defparameter *br-backstep-iframes* 9
  "... invulnerable on its frames 0-8 (new 2026-10-09 [G] 7, frames 0-6; decision V6, the user 2026-10-10: 7 -> 9). He is
ranged from its f0 (f13 before, decision V6: 「後撤瞬間會變回遠程」).")
;; (*BR-BACKSTEP-FS* 10, decision V6, is gone: decision V8a, the user 2026-10-10: 「覺醒後的 L>J / J > L 前後衝刺都需要消耗一條軌跡才能
;; 發動」, 「後撤不再扣閃步」: the backstep's price is one trace, BR-SPEND-FAR)
(defparameter *br-tenshin-in* 7.0
  "Ranged J 転身 TENSHIN in (decision V6, the user 2026-10-10: 「我想把鐘擺循環重新帶入 L -> J 與 J -> L 的設計中」, 「照原版」;
decision V6a: only out of a lay's window):
the dash at him, at most this many metres (the old Lille's *LB-SWITCH-IN* 7.0, copied 2026-10-10) ...")
(defparameter *br-tenshin-stop* 1.0 "... stopping this many metres short of him (the old *LB-SWITCH-STOP*, copied 2026-10-10) ...")
(defparameter *br-tenshin-speed* 30.0
  "... at this many m/s: the dash takes its distance / this, rounded up to whole frames, at most *BR-TENSHIN-F* (the old
*LB-SWITCH-SPEED*, copied 2026-10-10) ...")
(defparameter *br-tenshin-f* 14 "... its longest dash, frames (the old *LB-SWITCH-F*, copied 2026-10-10) ...")
(defparameter *br-tenshin-windup* 16
  "... the move's frame where the dash starts: its wind-up from ranged neutral was this many frames (the old
*LB-SWITCH-WINDUP*, copied 2026-10-10; decision V6a, the user 2026-10-10: 「L 放軌跡後快速連結 J 才會前衝」: no neutral TENSHIN
in since, the knob places the dash in the move the cancel copy enters, *BR-TENSHIN-ENTER*) ...")
(defparameter *br-tenshin-windup-c* 2
  "... and TENSHIN in comes only as this many frames' cancel out of a ranged L / SP1 / SP2, a J from its active end to the
end of its recovery (the old *LB-SWITCH-WINDUP-C* and its cancel window, copied 2026-10-10; the only way in since decision
V6a, 2026-10-10, BR-DASH-WINDOW-P) ...")
(defparameter *br-dash-late* 10
  "... and a J pressed within this many frames after that lay ends (its frame S + A + R is the end's + 0: L's f13, so L's J
window is f0-f22, 23 f) dashes too, as one pressed at any frame of the lay (latched, it dashes on the frame the move's last
point is set) (new 2026-10-10, decision V6c, the user: 「L 接 J 的判定再寬鬆一點」, the window 「整個放點招式＋收招後 10 幀」).
Elsewhere a ranged J is J1 in place (decision V6a).")
(defparameter *br-tenshin-iframes* 9
  "... invulnerable on the dash's frames 0-8 (the old *LB-DASH-IFRAMES*, copied 2026-10-10); free (no flash step). He turns
melee *BR-TENSHIN-FORM* frames into the dash (or at its end if sooner) and J1 comes out at the dash's end (a K pressed
during the dash makes it K1: the old link, the last press wins).")
(defparameter *br-tenshin-form* 6 "TENSHIN in: the frame into the dash where he turns melee (the old f22 = go + 6, copied 2026-10-10).")
(defparameter *br-tenshin-s* (+ *br-tenshin-windup* *br-tenshin-f*)
  "TENSHIN in's startup: the dash's start frame and the longest dash (derived: 16 + 14 = 30, the old :lb-switch-in's).")
(defparameter *br-tenshin-enter* (- *br-tenshin-windup* *br-tenshin-windup-c*)
  "TENSHIN in's cancel copy (the only TENSHIN in since decision V6a) enters at this frame (derived: 16 - 2 = 14, the old
:lb-switch-in-c's).")
;; the base stance's Step (decision V6, the user 2026-10-10: 「常態進入 L 架勢後可以靠 Step 消耗 10 點閃步量表快速位移（就如同原版
;; lille 一樣）」): the old HIRENKYAKU (:lb-k-dash), copied
(defparameter *br-kamae-dash* 3.5
  "The stance's Step 飛廉脚: metres in the stick direction (neutral: away from him) over *BR-KAMAE-DASH-F* (the old
*LB-KAMAE-DASH*, copied 2026-10-10, decision V6) ...")
(defparameter *br-kamae-dash-f* 12 "... frames; back in the stance on its f6 at *BR-KAMAE-BACK* (copied 2026-10-10) ...")
(defparameter *br-kamae-back* 11 "... this frame of the step (the old :lb-k-dash's f11 -> the stance's f6, a fresh window; copied 2026-10-10) ...")
(defparameter *br-kamae-dash-iframes* 8
  "... invulnerable on its frames 0-7 (decision V6's table 「iframes f0–7」; the old *LB-DASH-IFRAMES* 9 was f0-8) ...")
(defparameter *br-kamae-dash-fs* 10.0
  "... its flash-step price, once per stance; refused (the press ignored) when short or already used (the old
*LB-KAMAE-DASH-FS*, copied 2026-10-10, decision V6). No charge (Lille II has none).")
(defparameter *br-lay-l* 3.0
  "Ranged L: the flash step its one aim point costs; a lay is refused when the flash step is short of its price (new
2026-10-09, the user: 「留下軌跡會消耗閃步量表」, 3 a line). (Decision V8 made L a 7 f / 1.8 m / 16 swing whose hit set the point;
decision V8b, the user 2026-10-10: 「L 改回 v9 的不帶傷害 可以直接放」, put this plain lay back: no damage, its point at f4.)")
(defparameter *br-lay-sp1* 9.0 "Ranged SP1: three lines, 3 each (new 2026-10-09, the user's rule; [G] the price).")
(defparameter *br-lay-sp2* 9.0 "Ranged SP2: one thick line (new 2026-10-09 [G]).")
(defparameter *br-trace-max* 16 "Live traces at most; a 17th drops the oldest (the old *LB-TRACE-MAX*, copied 2026-10-09).")
(defparameter *br-trace-len* 31.0
  "A trace's line, metres: from its aim point through his current position and on (*BR-X-LEN*; 2026-10-09: from 0.6 m
ahead of where it was laid; decision V7, the user 2026-10-10: 「穿過利捷」).")
(defparameter *br-trace-r* 0.6 "A trace's radius, metres (copied 2026-10-09) ...")
(defparameter *br-trace-r-thick* 1.2 "... ranged SP2's thick one (copied 2026-10-09).")
(defparameter *br-sp1-fan* '((6 -6.0) (12 0.0) (18 6.0))
  "Ranged SP1's three aim points: (move frame, yaw offset in degrees) each: the point goes 0.5 m behind him along his facing
+ the offset, so the three lines part by 6 deg about him (new 2026-10-09 [G] as a fan of fixed lines; decision V7 [G]: the
same frames, each an aim point).")
(defparameter *br-aim-back* 0.5
  "A ranged lay's aim point: this many metres behind him along his facing at that frame (decision V7, the user 2026-10-10:
「設在自己後方 0.5 m 處」).")
(defparameter *br-aim-freeze* 0.3
  "A trace's line runs from its aim point through his current position, recomputed every step; within this many metres of
the point it keeps its last direction (decision V7 [G], 2026-10-10).")
(defparameter *br-near-r* 2.5
  "Materialising picks the one live trace whose line (point-to-segment on the ground) passes nearest the opponent, within
this many metres; a tie: the newer (decision V6, the user 2026-10-10: 「「附近」的判定條件改成 2.5 公尺內，然後每次只會觸發一條」;
decision V4's 10 deg snap before, *BR-NEAR-DEG*, gone; the user 2026-10-10 「維持 2.5 m」 with the aim points).")
(defparameter *br-mat-dmg* 30 "A materialised L / SP1 line's damage, before the form's x (new 2026-10-09 [G]; the old 30).")
(defparameter *br-mat-thick* 90 "A materialised SP2 thick line's damage, before the form's x (new 2026-10-09 [G]; the old 180).")
(defparameter *br-mat-stun* 26 "A materialised line (not SP2's) staggers this many frames in place (the old, 2026-10-09).")
(defparameter *br-refund* 0.0
  "A materialised trace that hits gives this much flash step back (the old 4, 2026-10-09; decision V6, the user 2026-10-10:
「改成 0」: 4 -> 0) ...")
(defparameter *br-refund-block* 0.0 "... a blocked one this much (the old 2, 2026-10-09; decision V6: 2 -> 0).")
(defparameter *br-owl-refund* 0.0 "The owl's materialised trace that hits: flash step back (the old owl's 5, 2026-10-09; decision V6: 5 -> 0) ...")
(defparameter *br-owl-refund-block* 0.0 "... blocked (the old owl's 2, 2026-10-09; decision V6: 2 -> 0).")
(defparameter *br-recall-f* 8 "K3 -> L 回收: the recall's frames before its derivative string (new 2026-10-09 [G]).")
(defparameter *br-recall-tiers* '((0 0) (1 1) (2 1) (3 2) (4 2) (5 2) (6 3) (7 3) (8 3) (9 3))
  "The recall's tier by the traces counted (n tier); 10 and up: tier 4 (new 2026-10-09 [G]: 0 / 1-2 / 3-5 / 6+; decision V8,
the user 2026-10-10: five super-linear tiers 0 / 1-2 / 3-5 / 6-9 / 10+ = 30 / 70 / 160 / 300 / 480, 10+ a new move :BR-RC4).")
(defparameter *br-rc0-dmg* 30 "Recall tier 0 空收 (n = 0): one 萬物貫通 line (new 2026-10-09 [G]; the gate's lever; decision V8: 30 kept).")
(defparameter *br-rc1-dmg* 35
  "Recall tier 1 二連 (n 1-2): each of two lines (new 2026-10-09 [G] 40; decision V8, 2026-10-10: the tier's 80 -> 70, 40 -> 35).")
(defparameter *br-rc2-dmg* 37
  "Recall tier 2 四連 (n 3-5): each of the first three lines ... (new 2026-10-09 [G] 35; decision V8: the tier's 150 -> 160, 35 -> 37)")
(defparameter *br-rc2-last* 49 "... and the launching fourth (new 2026-10-09 [G] 45; decision V8: 45 -> 49, 3 x 37 + 49 = 160).")
(defparameter *br-rc3-dmg* 43
  "Recall tier 3 裁き (n 6-9, 6+ before V8): each of the first four lines ... (new 2026-10-09 [G] 30; decision V8: the tier's
210 -> 300, 30 -> 43)")
(defparameter *br-rc3-last* 128 "... and the fifth (new 2026-10-09 [G] 90; decision V8: 90 -> 128, 4 x 43 + 128 = 300).")
(defparameter *br-rc4-dmg* 40
  "Recall tier 4 裁き・極 (n >= 10, decision V8, the user 2026-10-10: 「畫新的動作」): each of the six beats at f6 / f12 / f18 /
f24 / f30 / f36, 萬物貫通 lines from the wing tips ... (new 2026-10-10 [G])")
(defparameter *br-rc4-last* 240
  "... and the beam at f48 (NIJUSHI-KO's ring f38-f47 before it), 萬物貫通, a knockdown; 6 x 40 + 240 = 480; recovery 30 (new
2026-10-10, decision V8 [G]).")
(defparameter *br-rc4-clip* :br-rc4
  "The clip :BR-RC4 plays: its own 裁き・極 clip :br-rc4 (the owl's :br-o-rc4 through *BR-OWL-CLIP-MAP*), drawn 2026-10-10
(decision V8 「畫新的動作」, DUEL_LILLE_V2 §22); :br-rc3 before (the stand-in).")
(defparameter *br-rc-stun* 28 "The recall strings' lines before the last stagger this many frames: the next line combos (new 2026-10-09 [G]).")
(defparameter *br-rc-track* 360.0 "Degrees / s he turns at the opponent through the recall strings (new 2026-10-09 [G]).")

;; MUJITTAI's and the old KIN SPs' (copied from lille.lisp under BR- names, 2026-10-09, the user's two changes)
(defparameter *br-misuji-from* 1.0 "Owl melee SP1 裁きの光明: the ground line starts this many metres ahead (copied 2026-10-09) ...")
(defparameter *br-misuji-to* 18.0 "... and runs to this many (copied 2026-10-09).")
(defparameter *br-misuji-speed* 40.0 "... erupting outward at this many m/s (copied 2026-10-09).")
(defparameter *br-misuji-life* 24 "Frames each point of the line burns (copied 2026-10-09).")
(defparameter *br-misuji-width* 0.6 "The line's width, metres (copied 2026-10-09).")
(defparameter *br-reflect-hoho* '(48 59) "Owl melee SP2 Trompete: reflected by a perfect Hoho started on these frames (copied 2026-10-09).")
(defparameter *br-reflect-guard* '(2 10) "... or a guard whose FIGHTER-GUARD-T at its f59 is in this range (copied 2026-10-09).")
(defparameter *br-reflect-k* 0.5 "The reflect: he takes this share of Trompete's damage x his form's (copied 2026-10-09) ...")
(defparameter *br-reflect-stun* 60 "... and staggers this many frames (copied 2026-10-09).")

;; the owl (§6)
(defparameter *br-owl-mult* 1.1 "Damage dealt x, the owl (the old *SHIN-MULT*, copied 2026-10-09).")
(defparameter *br-owl-taken* 1.1 "Damage taken x, the owl (the old *SHIN-TAKEN*, copied 2026-10-09).")
(defparameter *br-owl-adv* 1
  "The owl's J / K strings and lays recover this many frames sooner than JILLIEL's (+1 on hit and block; the old *SHIN-ADV*,
copied 2026-10-09; the moves carry the numbers).")

;;; ================================================================ rules (pure: host-tested)
(defun br-owl-form-p (form) "Is FORM one of the owl's (melee, ranged, their MUJITTAI)?"
  (and (member form '(:shin-kin :shin :shin-kin-mujittai :shin-mujittai)) t))
(defun br-awake-form-p (form) "Is FORM awakened (JILLIEL's or the owl's, either mode, MUJITTAI too)?"
  (and (member form '(:jilliel-kin :jilliel :jilliel-kin-mujittai :jilliel-mujittai
                      :shin-kin :shin :shin-kin-mujittai :shin-mujittai))
       t))
(defun br-jilliel-form-p (form) "Is FORM one of JILLIEL's four (the revival's sources)?"
  (and (member form '(:jilliel-kin :jilliel :jilliel-kin-mujittai :jilliel-mujittai)) t))
(defun br-ranged-form-p (form) "Is FORM a ranged mode (JILLIEL's or the owl's, not MUJITTAI)?" (and (member form '(:jilliel :shin)) t))
(defun br-melee-form-p (form) "Is FORM a melee mode (JILLIEL's or the owl's, not MUJITTAI)?" (and (member form '(:jilliel-kin :shin-kin)) t))
(defun br-ranged-of (form) "The ranged mode of FORM's pair (melee -> ranged; else FORM)."
  (case form (:jilliel-kin :jilliel) (:shin-kin :shin) (t form)))
(defun br-melee-of (form) "The melee mode of FORM's pair (ranged -> melee; else FORM)."
  (case form (:jilliel :jilliel-kin) (:shin :shin-kin) (t form)))

(defun br-x-hit-p (hw)
  "Does hit window HW carry 萬物貫通 (§3): an :x-axis line through guard (:uncatchable) with *BR-X-GUARD* / *BR-X-CHIP*?"
  (and (member :x-axis (hw-flags hw)) (member :uncatchable (hw-flags hw)) (member :ranged (hw-flags hw))
       (eql (hw-guard hw) *br-x-guard*) (hw-chip hw) (< (abs (- (hw-chip hw) *br-x-chip*)) 1e-6) t))

(defun br-snipe-after (n contact &optional dist close)
  "The 狙擊 gauge after one of the stance's L / SP1 / SP2 moves made CONTACT (:hit / :block / NIL) for the first time: +1 on a
hit, at most *BR-SNIPE-MAX*; a block or a whiff nothing (decision V1). A CLOSE move (the stance's L, its :snipe-close) hitting
him DIST <= *BR-SNIPE-CLOSE* m away fills *BR-SNIPE-CLOSE-N* (decision V8: close sniping, +2 within 3 m)."
  (if (eq contact :hit)
      (min *br-snipe-max* (+ n (if (and close dist (<= dist *br-snipe-close*)) *br-snipe-close-n* 1)))
      n))
(defun br-snipe-spend (n)
  "The stance's J (the snap shot) at N pips: values the pips left and whether it converts (N >= 1, one spent); at 0 the
stance drops into J1 (「一般攻擊」)."
  (if (>= n 1) (values (1- n) t) (values n nil)))
(defun br-k-tier (n)
  "The stance's K at N pips (decision V9): the tier it fires, 1-3 (every pip spent: the gauge is 0 after); 0 none: the
plain K1 (decision V9d)."
  (max 0 (min 3 n)))
(defun br-k-tier-move (tier)
  "The stance's K's move for TIER 1-3 (decision V9): 1 退射 TAISHA (萬物貫通), 2 穿甲弾, 3 破陣弾 (tier 0 has none since decision
V9d: the stance drops into K1)."
  (svref #(:br-k-taisha :br-k-senko :br-k-hajin) (1- tier)))
(defun br-kamae-pick (cmd snipe)
  "The move the stance's follow-up CMD (:kamae-l -sp1 -sp2 -j -k) starts at SNIPE pips (§4, decision V9): L the 万物貫通 shot,
SP1 / SP2 the stance's 萬物貫通 SPs, J the snap shot at >= 1 pip, K the shot of its tier (every pip: BR-K-TIER); at 0 pips
the stance drops into the plain J1 / K1 (「一般攻擊」, V1; decision V9d: 「0 格時不能用架式 J / K」)."
  (case cmd
    (:kamae-l :br-k-shot) (:kamae-sp1 :br-k-sanren) (:kamae-sp2 :br-k-hiren)
    (:kamae-j (if (>= snipe 1) :br-k-snap :br-j1))
    (:kamae-k (if (>= snipe 1) (br-k-tier-move (br-k-tier snipe)) :br-k1))))
(defun br-kamae-left (cmd snipe)
  "The 狙擊 pips left after the stance's follow-up CMD at SNIPE (decision V9): J one spent (the snap shot; none at 0, J1), K
every one, else none."
  (case cmd
    (:kamae-j (values (br-snipe-spend snipe)))
    (:kamae-k 0)
    (t snipe)))
(defun br-dash-snap-p (sf)
  "May a J in the stance Step at its frame SF fire the stance's J (decision V9c): from *BR-DASH-SNAP-F*?"
  (>= sf *br-dash-snap-f*))
(defun br-snap-step-p (sf dashed fs)
  "May the snap shot at frame SF cancel into the stance Step (decision V9c): from *BR-SNAP-STEP-F*, this stance's Step unused
(DASHED) and FS flash step for it (BR-KAMAE-STEP-OK-P)?"
  (and (>= sf *br-snap-step-f*) (br-kamae-step-ok-p dashed fs)))
(defun br-snap-link-p (sf contact)
  "May the snap shot at frame SF link into J1 (decision V9c): from *BR-SNAP-LINK*, once it hit (CONTACT :hit)?"
  (and (>= sf *br-snap-link*) (eq contact :hit)))
(defun br-kamae-hold-over-p (sf held)
  "Does the stance (move frame SF, L HELD) end its hold now: past its tap with L up, before the held maximum?"
  (and (<= (+ *br-kamae-up* *br-kamae-tap*) sf) (< sf (+ *br-kamae-up* *br-kamae-max*)) (not held)))

(defun br-lay-price (form command)
  "The flash step COMMAND lays traces for in FORM (§5.2): a ranged mode's L *BR-LAY-L*, SP1 *BR-LAY-SP1*, SP2 *BR-LAY-SP2*;
anything else 0 (melee SP1 / SP2 fire directly, the user 2026-10-09; L's 3 back since decision V8b: the plain lay again)."
  (if (br-ranged-form-p form)
      (case command (:sig *br-lay-l*) (:sp1 *br-lay-sp1*) (:sp2 *br-lay-sp2*) (t 0.0))
      0.0))
(defun br-lay-ok-p (form command fs) "May COMMAND start in FORM with FS flash step (BR-LAY-PRICE: refused when short)?"
  (>= fs (br-lay-price form command)))
(defun br-line-cost (src) "The flash step one trace line of SRC (:l :sp1 :sp2) costs when laid."
  (case src (:sp2 *br-lay-sp2*) (:sp1 (/ *br-lay-sp1* (length *br-sp1-fan*))) (t *br-lay-l*)))
(defun br-trace-lay (ids id)
  "The FIFO of live trace IDS (oldest first) after trace ID is laid: values the new list and the id dropped (the oldest,
when *BR-TRACE-MAX* were live) or NIL."
  (let ((drop (and (>= (length ids) *br-trace-max*) (reduce #'min ids))))
    (values (append (remove drop ids) (list id)) drop)))
(defun br-aim-point (x z yaw)
  "A ranged lay's aim point for him at (X Z) facing YAW: *BR-AIM-BACK* m behind him (decision V7). Values x z (single)."
  (values (f32 (- x (* *br-aim-back* (fwd-x yaw)))) (f32 (- z (* *br-aim-back* (fwd-z yaw))))))
(defun br-line-dir (px pz lx lz ux uz)
  "A trace's line direction with its aim point at (PX PZ) and him at (LX LZ): the unit vector from the point through him;
within *BR-AIM-FREEZE* m of the point its last direction (UX UZ) is kept (decision V7). Values ux uz (single)."
  (let* ((dx (f32 (- lx px))) (dz (f32 (- lz pz))) (m (sqrt (+ (* dx dx) (* dz dz)))))
    (if (> m *br-aim-freeze*)
        (values (f32 (/ dx m)) (f32 (/ dz m)))
        (values (f32 ux) (f32 uz)))))
(defun br-seg-dist (px pz ux uz ox oz)
  "The ground distance from (OX OZ) to a trace's line: the segment from its point (PX PZ) along (UX UZ), *BR-TRACE-LEN*
long (point-to-segment, decision V6)."
  (let* ((dx (- ox px)) (dz (- oz pz)) (along (max 0.0 (min *br-trace-len* (+ (* dx ux) (* dz uz)))))
         (ex (- ox (+ px (* along ux)))) (ez (- oz (+ pz (* along uz)))))
    (sqrt (+ (* ex ex) (* ez ez)))))
(defun br-near-p (dist) "Is a trace whose line passes DIST m from the opponent near him (<= *BR-NEAR-R*, decision V6)?"
  (<= dist *br-near-r*))
(defun br-pick (cands)
  "The trace a materialise takes (decision V6: one per trigger): CANDS a list of (id dist) for the live traces; the nearest
within *BR-NEAR-R* (BR-NEAR-P), a tie the newer (the larger id). Its id, or NIL."
  (let ((best nil) (bd 0.0))
    (dolist (c cands)
      (destructuring-bind (id d) c
        (when (and (br-near-p d) (or (null best) (< d bd) (and (= d bd) (> id best))))
          (setf best id bd d))))
    best))
(defun br-trace-vol (src)
  "A trace's hit volume: a :cap from its aim point (0) along its line, *BR-TRACE-LEN* long, radius *BR-TRACE-R* (SP2's
*BR-TRACE-R-THICK*) (decision V7: the shot runs from the point through him and on)."
  (make-vol :cap (list 0.0 *br-trace-len* 1.2 (if (eq src :sp2) *br-trace-r-thick* *br-trace-r*))))
(defun br-tenshin-dist (d)
  "TENSHIN in's dash, metres, at him D metres away: at most *BR-TENSHIN-IN*, stopping *BR-TENSHIN-STOP* short (none when
he is nearer) (the old LB-SWITCH-DIST's in-case, copied 2026-10-10)."
  (max 0.0 (min *br-tenshin-in* (- d *br-tenshin-stop*))))
(defun br-tenshin-dash-f (dist)
  "Frames TENSHIN in's dash of DIST metres takes at *BR-TENSHIN-SPEED* (rounded up, at most *BR-TENSHIN-F*; 0 for none)."
  (if (> dist 0.01) (min *br-tenshin-f* (max 1 (ceiling (* 60.0 dist) *br-tenshin-speed*))) 0))
(defun br-dash-window-p (sf last end)
  "Is move frame SF of a ranged lay (L / SP1 / SP2, its last point set on frame LAST, over on frame END = S + A + R) inside
TENSHIN in's window in the move: from the frame its last point is set to its end (decision V6c, the user 2026-10-10:
「整個放點招式＋收招後 10 幀」; V6a's window started at the active end). A J latched earlier in the move or pressed now dashes
here (the 2 f cancel); *BR-DASH-LATE* frames after the end too (BR-DASH-FRAME); any other ranged J is J1 in place."
  (and (<= last sf end) t))
(defun br-dash-frame (press last end)
  "A J pressed on frame PRESS of a ranged lay whose last point is set on frame LAST and which ends on frame END (S + A + R;
frames past it count on: END + k is k frames after the end): the move frame its TENSHIN in starts (the 2 f cancel), or
NIL (J1 in place). Before LAST it is latched and dashes at LAST; from LAST to END + *BR-DASH-LATE* - 1 at once (decision
V6c). A lay that set no point (refused for lack of flash step) never dashes: its latched J is J1 in place at its end."
  (cond ((< press last) last)
        ((< press (+ end *br-dash-late*)) press)))
(defun br-last-point (mv)
  "The move frame a ranged lay MV sets its last point on (its last BR-LAY on-frame: L f4, SP1 f18, SP2 f20, the owl's SP2 f12;
the L's f4 again since decision V8b)."
  (let ((last 0)) (loop for (fr fn) in (mv-on-frame mv) when (and (eq fn 'br-lay) (> fr last)) do (setf last fr)) last))
(defun br-pick-far (cands)
  "The trace a dash spends (decision V8a, the user 2026-10-10: 「覺醒後的 L>J / J > L 前後衝刺都需要消耗一條軌跡才能發動」,
「最遠那條，不射出」): CANDS a list of (id dist) for the live traces (dist: the line's ground distance to the opponent); the
FARTHEST, a tie the older (the smaller id). Its id, or NIL (no trace: no dash)."
  (let ((best nil) (bd 0.0))
    (dolist (c cands)
      (destructuring-bind (id d) c
        (when (or (null best) (> d bd) (and (= d bd) (< id best)))
          (setf best id bd d))))
    best))
(defun br-tenshin-pay (cands)
  "TENSHIN in's traces (decision V9f, the user 2026-10-10: 「覺醒 L > J 優先級改成實體化先於前衝」, 「不前衝，原地出 J1」):
CANDS as BR-PICK's. The one that fires comes first (BR-PICK: the nearest within *BR-NEAR-R*), the dash's price is the
farthest of the rest (BR-PICK-FAR). Values the price's id (NIL: no dash, the J is J1 in place, its own first active frame
fires the near one) and the id that fires (NIL: none near)."
  (let ((fire (br-pick cands)))
    (values (br-pick-far (if fire (remove fire cands :key #'first) cands)) fire)))
(defun br-backstep-lay-ok-p (sf) "May a ranged lay start on the backstep's frame SF: from the dash's end (*BR-BACKSTEP-F*, decision V6)?"
  (>= sf *br-backstep-f*))
(defun br-kamae-step-ok-p (dashed fs)
  "May the stance's Step (飛廉脚) start: not yet used in this stance (DASHED) and FS >= *BR-KAMAE-DASH-FS* (decision V6)?"
  (and (not dashed) (>= fs *br-kamae-dash-fs*)))
(defun br-trace-hitwin (src mult)
  "The hit a materialised trace of SRC deals (once): *BR-MAT-DMG* (SP2's *BR-MAT-THICK*) x MULT with 萬物貫通 (chip
*BR-X-CHIP*, drain *BR-X-GUARD*, :ranged :x-axis :uncatchable); a *BR-MAT-STUN* stagger in place, SP2's a knockback."
  (let ((sp2 (eq src :sp2)))
    (make-hitwin :dmg (round (* (if sp2 *br-mat-thick* *br-mat-dmg*) mult)) :react (if sp2 :knockback :stagger)
                 :kb (if sp2 2.0 0.0) :stun (if sp2 nil *br-mat-stun*) :hs (if sp2 *hitstop-heavy* *hitstop-light*)
                 :chip *br-x-chip* :guard *br-x-guard* :flags (list :ranged :x-axis :uncatchable))))
(defun br-refund (contact &optional owl)
  "The flash step a materialised trace's CONTACT gives back: a hit *BR-REFUND* (the owl's *BR-OWL-REFUND*), a block
*BR-REFUND-BLOCK* (*BR-OWL-REFUND-BLOCK*), else 0."
  (case contact
    (:hit (if owl *br-owl-refund* *br-refund*))
    (:block (if owl *br-owl-refund-block* *br-refund-block*))
    (t 0.0)))
(defun br-recall-tier (n) "The recall's tier (0-4) for N traces taken back (*BR-RECALL-TIERS*: 0 / 1-2 / 3-5 / 6-9 / 10+, decision V8)."
  (or (second (assoc n *br-recall-tiers*)) 4))
(defun br-recall-move (tier) "The derivative string's move for TIER." (svref #(:br-rc0 :br-rc1 :br-rc2 :br-rc3 :br-rc4) tier))
(defun br-recall-damage (tier)
  "The damages of TIER's lines in order, before the form's x (the host test's view of the moves' windows)."
  (case tier
    (0 (list *br-rc0-dmg*)) (1 (list *br-rc1-dmg* *br-rc1-dmg*))
    (2 (list *br-rc2-dmg* *br-rc2-dmg* *br-rc2-dmg* *br-rc2-last*))
    (3 (list *br-rc3-dmg* *br-rc3-dmg* *br-rc3-dmg* *br-rc3-dmg* *br-rc3-last*))
    (t (append (make-list 6 :initial-element *br-rc4-dmg*) (list *br-rc4-last*)))))
(defun br-l-link-ok-p (l-name cur-name cur-kind cur-ender)
  "May the L link L-NAME start off the running move (CUR-NAME, CUR-KIND, CUR-ENDER its :ender flag): the recall only off a
K3 (a :flash ender), the backstep only off a J3 (a :quick ender); the stance after any K link (the old rule); anything else
yes (§5.1: 「K 連段的結尾接入 L」, 「J 連段的結尾接入 L」)."
  (declare (ignore cur-name))
  (case l-name
    (:br-recall (and cur-ender (eq cur-kind :flash)))
    (:br-backstep (and cur-ender (eq cur-kind :quick)))
    (t t)))
(defun br-kamae-link-ok-p (l-name snipe)
  "May L-NAME, an L pressed in a base J / K link, open the stance there (the :l-after-j / :l-after-k copies :BR-KAMAE-J /
:BR-KAMAE-K at f4): only with >= 1 狙擊 pip (SNIPE). Decision V9e (the user 2026-10-10, 「在麼有資源的情況下 J / K 攻擊中快速按 L
會打斷後搖接入架式然後又可以繼續 J / K => L 這樣無限循環到對手倒地」, the pick 「0 格時連段中的 L 不能開架」): at 0 pips the stance's J / K are
J1 / K1 (V9d), so the link closed a loop that cost nothing; with pips each turn spends one (the snap) or all (the K)."
  (or (not (member l-name '(:br-kamae-k :br-kamae-j))) (>= snipe 1)))
(defun br-l-route (cur-kind cur-ender &optional (live 1))
  "The move L pressed in a melee string link starts (the kit's :l-after-k / :l-after-j name the router :BR-L-LINK): off K3
(a :flash ender, CUR-ENDER) the recall, off J3 (a :quick ender) the backstep while a trace is LIVE (decision V8a: it spends
one; none: the plain mode turn in place, 「不衝刺」), off J1 / J2 / K1 / K2 the plain L, the mode turn into ranged, as a cancel
in the window the enders' links use (batch 4, 2026-10-09: the press was refused and eaten)."
  (cond ((and cur-ender (eq cur-kind :flash)) :br-recall)
        ((and cur-ender (eq cur-kind :quick) (plusp live)) :br-backstep)
        (t :br-to-en)))
(defun br-revive-ok-p (form free konpaku)
  "May P revive him into the owl (§6): any JILLIEL FORM (melee, ranged, MUJITTAI), FREE as for the first awakening, at most
*BANKAI-KONPAKU* Konpaku."
  (and (br-jilliel-form-p form) free (<= konpaku *bankai-konpaku*) t))
(defun br-sp2-sealed-p (command form sealed)
  "Is COMMAND refused in FORM because Trompete was reflected (SEALED): the owl's SP2 in every owl form (the old rule)."
  (and (eq command :sp2) (br-owl-form-p form) sealed t))
(defun br-reflect-hoho-p (start) "A perfect Hoho started on Trompete frame START reflects it (*BR-REFLECT-HOHO*)?"
  (<= (first *br-reflect-hoho*) start (second *br-reflect-hoho*)))
(defun br-reflect-guard-p (guard-t) "A guard at FIGHTER-GUARD-T = GUARD-T on Trompete's f59 reflects it (*BR-REFLECT-GUARD*)?"
  (<= (first *br-reflect-guard*) guard-t (second *br-reflect-guard*)))
(defun br-misuji-span (age)
  "The burning part of a 裁きの光明 ground line AGE frames after it erupted: values from to (metres ahead)."
  (let* ((front (min *br-misuji-to* (+ *br-misuji-from* (* *br-misuji-speed* (/ age 60.0)))))
         (tail (max *br-misuji-from* (+ *br-misuji-from* (* *br-misuji-speed* (/ (- age *br-misuji-life*) 60.0))))))
    (values (min tail front) front)))
(defun br-misuji-frames () "A 裁きの光明 line's life." (+ (ceiling (* 60 (- *br-misuji-to* *br-misuji-from*)) *br-misuji-speed*) *br-misuji-life*))
(defun br-ai-kamae-plan (r d reeling snipe sp-ok &optional k (difficulty :normal) jlink step-ok safe)
  "His CPU's follow-up in the stance, picked once at its f6 from one roll R (§8; K: the stance's :ai :kamae, chances x the
DIFFICULTY): at 3 pips the K (破陣弾, decision V9: every pip's shot) under :full; a stance opened off a J link (JLINK) with
a pip the snap shot under :snap-link (decision V9c: J string -> L -> J); a REELING opponent the shot (it combos); SAFE (his
attack not coming) at <= 1 pip inside :close-in m the close snipe, the shot (+2 on a hit within 3 m, decision V8), under
:close-shot (when it does not fire, the roll is rescaled for the rest);
>= 1 pip and inside 4 m the K (its tier's back-slide shot) or the snap shot, half each; 0 pips inside :escape-in m the
stance Step straight back (:KAMAE-STEP) under :escape while this stance's Step is there (STEP-OK: unused, its flash step;
decision V9d: the K at 0 pips is the plain K1, no longer TAISHA's back-slide); with the bars (SP-OK) a quarter of the time
the stance's SP2 (inside 5 m) or SP1; else the shot."
  (cond ((and k (>= snipe 3) (< r (br-ai-chance (getf k :full 0.0) difficulty))) :kamae-k)
        ((and k jlink (>= snipe 1) (< r (br-ai-chance (getf k :snap-link 0.0) difficulty))) :kamae-j)
        (reeling :kamae-l)
        ((and k safe (<= snipe 1) (< d (getf k :close-in 3.0))
              (let ((p (br-ai-chance (getf k :close-shot 0.0) difficulty)))
                (or (< r p) (progn (setf r (/ (- r p) (max 1e-6 (- 1.0 p)))) nil))))
         :kamae-l)
        ((and (>= snipe 1) (< d 4.0)) (if (< r 0.5) :kamae-k :kamae-j))
        ((and k step-ok (< snipe 1) (< d (getf k :escape-in 3.0)) (< r (br-ai-chance (getf k :escape 0.0) difficulty)))
         :kamae-step)
        ((and sp-ok (< r 0.25)) (if (< d 5.0) :kamae-sp2 :kamae-sp1))
        (t :kamae-l)))

(defun br-ai-hard-kamae (why snipe)
  "The HARD layer's stance plan for its WHY (:punish / :crush, or NIL: none) at SNIPE pips: a guard to crush at 3 pips the K
(破陣弾 breaks it on block, decision V9), else the snap shot with a pip, else the shot."
  (when why
    (cond ((and (eq why :crush) (>= snipe 3)) :kamae-k)
          ((>= snipe 1) :kamae-j)
          (t :kamae-l))))

;;; ================================================================ the two routes' strings (decision V8)
(defun br-v8-shift (on-frame s0 ds)
  "ON-FRAME ((frame hook) ...) with every frame from the old startup S0 on moved by DS (the hit-frame hooks follow the hit)."
  (loop for (fr fn) in on-frame collect (list (if (>= fr s0) (+ fr ds) fr) fn)))
(defun br-v8-spec (route spec)
  "Decision V8 (the user 2026-10-10, the two routes): a J / K string move's SPEC (written with its old numbers, the
DUEL_STRINGS §2.1 budget's) for ROUTE :J (startup and recovery - *BR-J-SPEED*, floors *BR-J-MIN-S* / *BR-J-MIN-R*, damage x
*BR-J-MULT*, block advantage + *BR-J-ADV*) or :K (startup and recovery + *BR-K-SLOW*, damage x *BR-K-MULT*, block advantage +
*BR-K-ADV*); a K link's :enter + (*BR-K-SLOW* - *BR-K-LINK-SLOW*) (its effective startup 14 -> 15), a J's unchanged; its
hit-frame hooks follow the new startup; :clip-s the old startup (the clip, authored at it,
plays at old / new speed and still reaches its hit pose on the new hit frame). A new plist, each key once."
  (let* ((j (eq route :j)) (s0 (getf spec :startup)) (r0 (getf spec :recovery))
         (s1 (if j (max *br-j-min-s* (- s0 *br-j-speed*)) (+ s0 *br-k-slow*)))
         (r1 (if j (max *br-j-min-r* (- r0 *br-j-speed*)) (+ r0 *br-k-slow*)))
         (new (list :startup s1 :recovery r1
                    :dmg (round (* (getf spec :dmg) (if j *br-j-mult* *br-k-mult*)))
                    :adv-block (+ (getf spec :adv-block) (if j *br-j-adv* *br-k-adv*))
                    :on-frame (br-v8-shift (getf spec :on-frame) s0 (- s1 s0))
                    :enter (let ((n (or (getf spec :enter) 0)))
                             (if (and (not j) (plusp n)) (+ n (- *br-k-slow* *br-k-link-slow*)) n))
                    :clip-s (or (getf spec :clip-s) s0))))
    (append new (loop for (k v) on spec by #'cddr unless (member k '(:startup :recovery :dmg :adv-block :on-frame :clip-s :enter))
                      append (list k v)))))
(defmacro br-defstring (route name &rest spec)
  "DEFMOVE for one of his J (ROUTE :J) / K (:K) string links: SPEC with the old numbers, BR-V8-SPEC applies decision V8."
  `(register-move ',name (br-v8-spec ,route ',spec)))

;;; ================================================================ base 万物貫通 (§4)
;; the J / K strings: the old Lille's frames and clips, literal numbers (DUEL_STRINGS §2.1's budget), decision V8 on top
;; (BR-DEFSTRING: J S 6 / 5 / 7, R 10 / 11 / 16, 22 / 19 / 24, adv 0 / 0 / -2; K S 19 / 22 / 23 (:enter 7 / 8: S_eff 15),
;; R 23 / 26 / 36, 58 / 58 / 84, adv -7 / -7 / -24)
(br-defstring :j :br-j1 :kind :quick :clip :lb-q1 :startup 8 :active 3 :recovery 12 :dmg 26 :adv-block -2
  :reach 1.45 :arc 100 :on-hit :flinch)
(br-defstring :j :br-j2 :kind :quick :clip :lb-q2 :startup 7 :active 3 :recovery 13 :dmg 22 :adv-block -2
  :reach 1.45 :arc 110 :on-hit :flinch)
(br-defstring :j :br-j3 :kind :quick :clip :lb-jab :startup 9 :active 3 :recovery 18 :dmg 28 :adv-block -4
  :reach 1.6 :arc 70 :on-hit :stagger :flags (:ender))
(br-defstring :k :br-k1 :kind :flash :clip :lb-f1 :startup 17 :active 4 :recovery 21 :dmg 48 :adv-block -3
  :reach 2.05 :arc 150 :on-hit :stagger)
(br-defstring :k :br-k2 :kind :flash :clip :lb-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 48 :adv-block -3
  :reach 2.05 :arc 100 :on-hit :stagger)
(br-defstring :k :br-k3 :kind :flash :clip :lb-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 70 :adv-block -20
  :reach 2.15 :arc 60 :on-hit :crumple :flags (:ender))
(defmove-copy :br-j2s :br-j2)
(defmove-copy :br-k2s :br-k2)
;; L 狙擊架式: up at f6, held 30 f (90 while L is held), R 14; turning 60 deg/s; from f6 the first L / SP1 / SP2 / J / K
;; picks the follow-up (BR-KAMAE-TICK through the non-button :strings). L after a K link opens it at f4
;; Step (decision V6): 飛廉脚, the old HIRENKYAKU: *BR-KAMAE-DASH* m in the stick direction (neutral: back) over 12 f, iframes
;; f0-7, back in the stance at f6 (:br-kamae-re, a fresh window, the aim snapped onto him), once per stance, 10 flash step
(defmove :br-kamae :kind :sig :clip :lb-kamae :startup 6 :active 0 :recovery 104 :track 60.0 :tick br-kamae-tick
  :flags (:step-branch) :on-frame ((0 br-kamae-enter)))
(defmove-copy :br-kamae-k :br-kamae :enter 4 :on-frame ((4 br-kamae-enter)))
(defmove-copy :br-kamae-j :br-kamae :enter 4 :on-frame ((4 br-kamae-enter)))   ; (L after a J link, decision V9c)
(defmove-copy :br-kamae-re :br-kamae :enter *br-kamae-up* :on-frame nil)
(defmove :br-k-dash :kind :sig :clip :lb-k-dash :startup *br-kamae-dash-f* :active 0 :recovery 0 :tick br-k-dash-tick
  :on-frame ((0 br-kamae-dash) (*br-kamae-back* br-kamae-back)))
;; stance -> L 万物貫通: locked on the press, fired 10 f later; 50 flat, 萬物貫通; a hit fills a pip, within 3 m two (:snipe-close,
;; decision V8: close sniping)
(defmove :br-k-shot :kind :sig :clip :lb-k-shot :callout "X-AXIS" :startup 10 :active 2 :recovery 26 :dmg *br-shot-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :on-frame ((0 br-k-lock) (10 br-shot-fire)) :params (:lock 0 :snipe t :snipe-close t :len *br-x-len*))
;; stance -> SP1: three 萬物貫通 lines (f12 / f22 / f32), turning 90 deg/s between them
(defmove :br-k-sanren :kind :sp :clip :lb-sanren :callout "SANREN" :startup 12 :active 22 :recovery 24 :dmg *br-k-sanren-dmg*
  :adv-block -14 :track 90 :vol (:cap 0.6 *br-x-len* 1.2 0.25) :on-hit :flinch :kb 0.5 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :hits ((12 14) (22 24) (32 34)) :tick br-sanren-tick
  :on-frame ((12 br-line-shot) (22 br-line-shot) (32 br-line-shot)) :params (:len *br-x-len* :snipe t))
;; stance -> SP2: the 6 m back-slide (no iframes), then one 萬物貫通 shot at f20
(defmove :br-k-hiren :kind :sp :clip :lb-hiren :callout "HIRENKYAKU" :startup 20 :active 2 :recovery 22 :dmg *br-k-hiren-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick br-slide-tick :on-frame ((0 br-slide) (20 br-shot-fire))
  :params (:slide 6.0 :slide-f 14 :lock 14 :snipe t :len *br-x-len*))
;; stance -> J at >= 1 pip: 速射 the snap shot from the hip (Lille's unused :lb-snap), 40, 萬物貫通, a pip spent (decision V9b
;; kept it: the user 2026-10-10 「等等，取消跳射改回用速射」). Decision V9c: also from the stance Step's f3; its recovery from f8
;; cancels into the Step (once per stance) and, on its hit, into J1 (BR-SNAP-TICK)
(defmove :br-k-snap :kind :sig :clip :lb-snap :callout "SOKUSHA" :startup 6 :active 2 :recovery 20 :dmg *br-snap-dmg*
  :adv-block -12 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :on-frame ((0 br-snap-enter) (6 br-shot-fire)) :tick br-snap-tick
  :params (:lock 0 :len *br-x-len*))
;; stance -> K: a shot by EVERY pip spent (decision V9, the user 2026-10-10, 「四段效果」), the TAISHA clip for all three: the 3 m
;; back-slide over f0-12 (turning 90 deg/s, then the line locks), one shot at f16; more pips, a longer recovery
;; (*BR-TAISHA-R* / *BR-SENKO-R* / *BR-HAJIN-R*). 0 pips: the plain K1 (decision V9d; V9's 0-pip 退射 40 is gone)
;; ... 1 pip: 退射 TAISHA 70 with 萬物貫通 (as before V9)
(defmove :br-k-taisha :kind :sig :clip :lb-k-taisha :callout "TAISHA" :startup 16 :active 2 :recovery *br-taisha-r* :dmg *br-taisha-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick br-slide-tick :on-frame ((0 br-slide) (16 br-shot-fire))
  :params (:slide 3.0 :slide-f 12 :lock 12 :len *br-x-len* :pips 1))
;; ... 2 pips: 穿甲弾 SENKO-DAN 110, 萬物貫通, a knockdown on hit
(defmove :br-k-senko :kind :sig :clip :lb-k-taisha :callout "SENKO-DAN" :startup 16 :active 2 :recovery *br-senko-r* :dmg *br-senko-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :knockdown :kb 1.5 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick br-slide-tick :on-frame ((0 br-slide) (16 br-shot-fire))
  :params (:slide 3.0 :slide-f 12 :lock 12 :len *br-x-len* :pips 2))
;; ... 3 pips: 破陣弾 HAJIN-DAN 150, 萬物貫通, a guard break on block (:guard-crush), a knockdown on hit [G]
(defmove :br-k-hajin :kind :sig :clip :lb-k-taisha :callout "HAJIN-DAN" :startup 16 :active 2 :recovery *br-hajin-r* :dmg *br-hajin-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :knockdown :kb 2.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable :guard-crush) :tick br-slide-tick :on-frame ((0 br-slide) (16 br-shot-fire))
  :params (:slide 3.0 :slide-f 12 :lock 12 :len *br-x-len* :pips 3))
;; SP1 / SP2 outside the stance: no 萬物貫通 (the kind's chip and drain), 20 m lines, no pip
(defmove :br-sanren :kind :sp :clip :lb-sanren :callout "SANREN" :startup 12 :active 22 :recovery 24 :dmg *br-sanren-dmg*
  :adv-block -14 :track 90 :vol (:cap 0.6 *br-plain-len* 1.2 0.25) :on-hit :flinch :kb 0.5 :flags (:ranged)
  :hits ((12 14) (22 24) (32 34)) :tick br-sanren-tick
  :on-frame ((12 br-line-shot) (22 br-line-shot) (32 br-line-shot)) :params (:len *br-plain-len*))
(defmove :br-hiren :kind :sp :clip :lb-hiren :callout "HIRENKYAKU" :startup 20 :active 2 :recovery 22 :dmg *br-hiren-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-plain-len* 1.2 0.25) :on-hit :stagger :kb 1.0 :flags (:ranged)
  :tick br-slide-tick :on-frame ((0 br-slide) (20 br-shot-fire)) :params (:slide 6.0 :slide-f 14 :lock 14 :len *br-plain-len*))
(defmove :br-breaker :kind :breaker :clip :lb-breaker :clip-2 :lb-butt :callout "SHOBI-UCHI")
(defmove :br-kikon :kind :kikon :clip :lb-aim :clip-2 :lb-fire :clip-s 4 :callout "BANBUTSU KANTSU" :cine lb-kikon-cine
  :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0 :vol (:cap 0.5 12.0 1.2 1.2)
  :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 br-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))

;;; ================================================================ JILLIEL (§5)
;; melee: the wing blades. Every J materialises one trace at its first active frame, hit or whiff (BR-J-MAT); a K one when it
;; touches him, hit or block, never on a whiff (BARRO-HIT, :params :mat-k) (decision V6, the user 2026-10-10: 「把 J 改成就算
;; 近攻沒打中也會出發最近實體化」, 「只有 J，然後 K 揮空不再觸發實體化」). J1 / K1 start by putting him in melee (BR-MELEE-IN: J / K
;; pressed in ranged mode or its MUJITTAI, in place; decision V6a: a ranged J is TENSHIN in only in a lay's window)
(br-defstring :j :br-w-j1 :kind :quick :clip :lb-w-q1 :startup 8 :active 3 :recovery 12 :dmg 24 :adv-block -2
  :reach 1.6 :arc 110 :on-hit :flinch :on-frame ((0 br-melee-in) (8 br-j-mat)))
(br-defstring :j :br-w-j2 :kind :quick :clip :lb-w-q2 :startup 7 :active 3 :recovery 13 :dmg 24 :adv-block -2
  :reach 1.6 :arc 110 :on-hit :flinch :on-frame ((7 br-j-mat)))
(br-defstring :j :br-w-j3 :kind :quick :clip :lb-w-q3 :startup 9 :active 3 :recovery 18 :dmg 30 :adv-block -4
  :reach 1.7 :arc 120 :on-hit :stagger :flags (:ender) :on-frame ((9 br-j-mat)))
;; (decision V8, the user 2026-10-10: 「K never fires a trace」: the K route keeps the pool for the recall; :mat-k gone)
(br-defstring :k :br-w-k1 :kind :flash :clip :lb-w-f1 :startup 17 :active 4 :recovery 21 :dmg 50 :adv-block -3
  :reach 2.2 :arc 150 :on-hit :stagger :on-frame ((0 br-melee-in)))
(br-defstring :k :br-w-k2 :kind :flash :clip :lb-w-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 50 :adv-block -3
  :reach 2.2 :arc 110 :on-hit :stagger)
(br-defstring :k :br-w-k3 :kind :flash :clip :lb-w-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 72 :adv-block -20
  :reach 2.3 :arc 90 :on-hit :crumple :flags (:ender))
(defmove-copy :br-w-j2s :br-w-j2)
(defmove-copy :br-w-k2s :br-w-k2)
;; melee SP1 / SP2: the old KIN's, fired directly (the user 2026-10-09: 「近戰模式的 SP1／SP2 跟原版一樣會直接放出」): SANREN
;; on his wings (3 lines 20 m, 30 each, chip 15 %, guard 12) and NIJUSHI-KO (the 40 f tell, a 1.2 m beam, 180)
(defmove :br-w-sanren :kind :sp :clip :lb-w-sanren :clip-s 12 :callout "SANREN" :startup 12 :active 22 :recovery 24 :dmg 30
  :adv-block -14 :track 90 :vol (:cap 0.6 20.0 1.2 0.25) :on-hit :flinch :kb 0.5 :chip 0.15 :guard 12
  :flags (:ranged :x-axis :uncatchable) :hits ((12 14) (22 24) (32 34)) :tick br-sanren-tick
  :on-frame ((12 br-line-shot) (22 br-line-shot) (32 br-line-shot)) :params (:len 20.0))
(defmove :br-w-nijushi :kind :sp :clip :lb-w-nijushi :callout "NIJUSHI-KO" :startup 40 :active 6 :recovery 30 :dmg 180
  :adv-block -14 :track 0 :vol (:cap 0.6 31.0 1.2 1.2) :on-hit :knockback :kb 2.0 :chip 0.15 :guard 45
  :flags (:ranged :x-axis :uncatchable) :tick br-planted-tick :on-frame ((0 br-nijushi-tell) (40 br-beam-shot))
  :params (:lock 20 :track 60.0 :width 1.2))
;; melee L: the turn into ranged mode (12 f); J3 -> L 後撤 the backstep (5 m / 14 f, iframes f0-8, 10 flash step, ranged from
;; its f0, a lay from its f14: decision V6) into ranged; K3 -> L
;; 回收 the recall (every live trace taken back, counted, then the derivative string for the count: :strings :rc0 .. :rc3)
(defmove :br-to-en :kind :sig :clip :br-to-en :callout "EN" :startup *br-to-en-f* :active 0 :recovery 0 :tick br-halt-tick
  :on-frame ((11 br-go-ranged)))
;; L latched in a melee J / K link (the kits' :l-after-k / :l-after-j): a router that lives no frame: its f0 starts the
;; move BARRO-OK routed off the link it was pressed in (BR-L-ROUTE: K3 the recall, J3 the backstep, else :br-to-en; batch 4)
(defmove :br-l-link :kind :sig :clip :lb-w-fold :startup 1 :active 0 :recovery 0 :on-frame ((0 br-l-link-go)))
(defmove :br-backstep :kind :sig :clip :lb-w-tenshin :callout "KOTAI" :startup *br-backstep-f* :active 0 :recovery 8
  :tick br-backstep-tick :on-frame ((0 br-backstep-go)))
;; 転身 TENSHIN in (decision V6: the old Lille's :lb-switch-in, 「照原版」), since decision V6a (the user 2026-10-10: 「L 放軌跡後
;; 快速連結 J 才會前衝」) only as the 2 f cancel of a J in a ranged L / SP1 / SP2's window (the copy entered at f14: BR-LAY-TICK,
;; BR-DASH-WINDOW-P; since decision V6c a J at any frame of the lay, latched to its last point, or within *BR-DASH-LATE* f after
;; it: BR-MELEE-IN; :br-tenshin itself is only the copies' template, no command starts it): the dash's f0 fires one line (the
;; nearest within 2.5 m of him, BR-TENSHIN-FIRE: decision V6c, 「照原版：前衝第 0 幀觸發」), then the dash at him at 30 m/s, at
;; most 7 m, stopping 1 m short, iframes f0-8, free; melee 6 f into the dash (or at its end); J1 at the dash's end (a K pressed
;; during it: K1), and J1's first active frame materialises one more (BR-J-MAT). R 8 when nothing links. Any other ranged
;; J: melee in place and J1 (the ranged kits' :q is the melee J1, BR-MELEE-IN at its f0), as the ranged K
(defmove :br-tenshin :kind :sig :clip :lb-w-tenshin-in :callout "TENSHIN" :startup *br-tenshin-s* :active 0 :recovery 8
  :tick br-tenshin-tick :on-frame ((*br-tenshin-windup* br-tenshin-fire) (*br-tenshin-windup* br-tenshin-go)))
(defmove-copy :br-tenshin-c :br-tenshin :enter *br-tenshin-enter*)
(defmove :br-recall :kind :sig :clip :br-recall :callout "KAISHU" :startup *br-recall-f* :active 0 :recovery 0
  :tick br-halt-tick :on-frame ((0 br-recall-go) (7 br-recall-fire)))
;; the recall's derivative strings (§5.4): every line 萬物貫通 from him at the opponent (BR-RC-TICK keeps him on him)
(defmove :br-rc0 :kind :sig :clip :br-rc0 :callout "KAISHU" :startup 6 :active 2 :recovery 24 :dmg *br-rc0-dmg* :adv-block -14
  :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick br-rc-tick :on-frame ((6 br-rc-shot)) :params (:lock 0 :len *br-x-len*))
(defmove :br-rc1 :kind :sig :clip :br-rc1 :callout "NIREN" :startup 6 :active 12 :recovery 24 :dmg *br-rc1-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 0.5 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :hits ((6 8 :stun *br-rc-stun*) (16 18)) :tick br-rc-tick
  :on-frame ((6 br-rc-shot) (16 br-rc-shot)) :params (:lock 0 :len *br-x-len*))
(defmove :br-rc2 :kind :sig :clip :br-rc2 :callout "YONREN" :startup 6 :active 28 :recovery 24 :dmg *br-rc2-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 0.3 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable)
  :hits ((6 8 :stun *br-rc-stun*) (14 16 :stun *br-rc-stun*) (22 24 :stun *br-rc-stun*) (32 34 :dmg *br-rc2-last* :on-hit :launch))
  :tick br-rc-tick :on-frame ((6 br-rc-shot) (14 br-rc-shot) (22 br-rc-shot) (32 br-rc-shot)) :params (:lock 0 :len *br-x-len*))
(defmove :br-rc3 :kind :sig :clip :br-rc3 :callout "SABAKI" :startup 6 :active 32 :recovery 26 :dmg *br-rc3-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 0.3 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable)
  :hits ((6 8 :stun *br-rc-stun*) (12 14 :stun *br-rc-stun*) (18 20 :stun *br-rc-stun*) (24 26 :stun *br-rc-stun*)
         (36 38 :dmg *br-rc3-last* :on-hit :knockback :kb 2.0))
  :tick br-rc-tick :on-frame ((6 br-rc-shot) (12 br-rc-shot) (18 br-rc-shot) (24 br-rc-shot) (36 br-beam-shot))
  :params (:lock 0 :len *br-x-len* :width 1.2))
;; 裁き・極 (n >= 10, decision V8, the user 2026-10-10: five tiers, 10+ 「畫新的動作」): six 40 beats at f6 / f12 / f18 / f24 /
;; f30 / f36 (萬物貫通 lines from the wing tips at him), NIJUSHI-KO's ring f38-f47 (its tell at f38), the beam at f48, 240,
;; 萬物貫通, a knockdown; recovery 30. Its clip *BR-RC4-CLIP* (:br-rc3 until the art agent's :br-rc4)
(defmove :br-rc4 :kind :sig :clip *br-rc4-clip* :callout "SABAKI KIWAMI" :startup 6 :active 44 :recovery 30 :dmg *br-rc4-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 0.3 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable)
  :hits ((6 8 :stun *br-rc-stun*) (12 14 :stun *br-rc-stun*) (18 20 :stun *br-rc-stun*) (24 26 :stun *br-rc-stun*)
         (30 32 :stun *br-rc-stun*) (36 38 :stun *br-rc-stun*)
         (48 50 :dmg *br-rc4-last* :on-hit :knockdown :kb 2.0))
  :tick br-rc-tick :on-frame ((6 br-rc-shot) (12 br-rc-shot) (18 br-rc-shot) (24 br-rc-shot) (30 br-rc-shot) (36 br-rc-shot)
                              (38 br-nijushi-tell) (48 br-beam-shot))
  :params (:lock 0 :len *br-x-len* :width 1.2))
(defmove :br-w-breaker :kind :breaker :clip :lb-w-breaker :clip-2 :lb-w-ram :callout "JILLIEL")
(defmove :br-w-kikon :kind :kikon :clip :lb-w-kikon :clip-2 :lb-w-kikon-fire :callout "KAMI NO SABAKI"
  :cine lb-jilliel-kikon-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.2 1.2) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 br-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))
;; ranged: L sets one aim point (3), SP1 three, one a shot (9), SP2 one thick (9) (decision V7: 0.5 m behind him, its line
;; through him, BR-LAY); laying deals nothing; refused when short. From the frame its last point is set to 10 f after its end
;; J cancels into TENSHIN in (BR-LAY-TICK, BR-DASH-WINDOW-P: the only TENSHIN in, decisions V6a / V6c), which spends a trace
;; (decision V8a). (Decision V8's L swing, 7 f / 1.8 m / 16, is gone: decision V8b, the user 2026-10-10: 「L 改回 v9 的不帶傷害
;; 可以直接放」)
(defmove :br-e-lay :kind :sig :clip :lb-e-q1 :startup 4 :active 3 :recovery 6 :tick br-lay-tick :on-frame ((4 br-lay))
  :params (:trace :l))
(defmove :br-e-sanren :kind :sp :clip :lb-e-sanren :callout "SANREN" :startup 6 :active 14 :recovery 12 :tick br-lay-tick
  :on-frame ((6 br-lay) (12 br-lay) (18 br-lay)) :params (:trace :sp1))
(defmove :br-e-nijushi :kind :sp :clip :lb-w-nijushi :clip-s 40 :callout "NIJUSHI-KO" :startup 20 :active 6 :recovery 15
  :track 0 :tick br-lay-tick :on-frame ((0 br-nijushi-tell) (20 br-lay)) :params (:lock 10 :track 60.0 :trace :sp2))

;;; ================================================================ the owl (§6): the old owl's numbers (R - 1, adv + 1)
(br-defstring :j :br-o-j1 :kind :quick :clip :lb-o-q1 :startup 8 :active 3 :recovery 11 :dmg 26 :adv-block -1
  :reach 1.7 :arc 110 :on-hit :flinch :on-frame ((0 br-melee-in) (8 br-j-mat)))
(br-defstring :j :br-o-j2 :kind :quick :clip :lb-o-q2 :startup 7 :active 3 :recovery 12 :dmg 26 :adv-block -1
  :reach 1.7 :arc 110 :on-hit :flinch :on-frame ((7 br-j-mat)))
(br-defstring :j :br-o-j3 :kind :quick :clip :lb-o-q3 :startup 9 :active 3 :recovery 17 :dmg 32 :adv-block -3
  :reach 1.7 :arc 120 :on-hit :stagger :flags (:ender) :on-frame ((9 br-j-mat)))
(br-defstring :k :br-o-k1 :kind :flash :clip :lb-o-f1 :startup 17 :active 4 :recovery 20 :dmg 54 :adv-block -2
  :reach 2.3 :arc 150 :on-hit :stagger :on-frame ((0 br-melee-in)))
(br-defstring :k :br-o-k2 :kind :flash :clip :lb-o-f2 :enter 6 :startup 20 :active 4 :recovery 23 :dmg 54 :adv-block -2
  :reach 2.3 :arc 110 :on-hit :stagger)
(br-defstring :k :br-o-k3 :kind :flash :clip :lb-o-f3 :enter 7 :startup 21 :active 5 :recovery 33 :dmg 78 :adv-block -19
  :reach 2.3 :arc 90 :on-hit :crumple :flags (:ender))
(defmove-copy :br-o-j2s :br-o-j2)
(defmove-copy :br-o-k2s :br-o-k2)
;; owl melee SP1 裁きの光明 (the old MISUJI: three SABAKI ground lines at -20 / 0 / +20 deg, one hit group, 70 each, 18 m)
(defmove :br-misuji :kind :sp :clip :lb-o-chop :clip-s 16 :callout "SABAKI NO KOMYO" :startup 18 :active 0 :recovery 25
  :reach 18.0 :track 90 :on-frame ((18 br-misuji)) :params (:dmg 70 :guard 18 :fan (-20.0 0.0 20.0)))
;; owl melee SP2 神の喇叭 TROMPETE (the old: 60 f wind-up, a 2.4 m-wide beam 30 f, 240; reflected by a perfect Hoho f48-f59
;; or a guard f50-f58: he takes half, staggers, SP2 sealed in both owl modes for the match)
(defmove :br-trompete :kind :sp :clip :lb-o-trompete :callout "TROMPETE" :startup 60 :active 30 :recovery 39 :dmg 240
  :adv-block -13 :track 0 :vol (:cap 0.6 31.0 1.4 1.2) :on-hit :knockback :kb 3.0 :chip 0.15 :guard 60
  :flags (:ranged :x-axis :uncatchable :reflectable) :tick br-planted-tick :on-frame ((0 br-trompete-tell) (60 br-beam-shot))
  :params (:lock 40 :blast 60 :track 30.0 :width 1.2))
(defmove :br-o-breaker :kind :breaker :clip :lb-o-breaker :clip-2 :lb-o-stamp :callout "KAGIZUME")
(defmove :br-o-kikon :kind :kikon :clip :lb-o-trompete :clip-2 :lb-o-chop :clip-s 4 :callout "TROMPETE"
  :cine lb-trompete-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 80 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.4 1.4) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 br-lane-shot))
  :params (:aura 10 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))
;; owl ranged: the old owl EN's casts with R - 1, laying as JILLIEL ranged's; J in a lay's window the owl's TENSHIN in (the old
;; :lb-o-switch-in-c), any other J the claws' J1 in place (decision V6a)
(defmove :br-oe-lay :kind :sig :clip :lb-oe-q1 :startup 4 :active 3 :recovery 5 :tick br-lay-tick :on-frame ((4 br-lay))
  :params (:trace :l))   ; (the plain lay again, decision V8b)
(defmove :br-oe-sabaki :kind :sp :clip :lb-oe-sabaki :callout "SABAKI NO KOMYO" :startup 6 :active 14 :recovery 11
  :tick br-lay-tick :on-frame ((6 br-lay) (12 br-lay) (18 br-lay)) :params (:trace :sp1))
(defmove :br-oe-trompete :kind :sp :clip :lb-o-trompete :clip-s 60 :callout "TROMPETE" :startup 12 :active 6 :recovery 8
  :track 0 :tick br-lay-tick :on-frame ((0 br-trompete-tell) (12 br-lay)) :params (:lock 6 :track 100.0 :trace :sp2))
(defmove-copy :br-o-tenshin-c :br-tenshin :clip :lb-o-tenshin-in :enter *br-tenshin-enter*)

;;; The moves Lille never had and their clips (barro-art.lisp, DUEL_LILLE_V2 §7, §12): move -> (the clip JILLIEL plays, the
;;; owl's through its kits' :clip-map, the stand-in it replaced). Batch 1 played Lille's clips; the art batch (2026-10-09)
;;; drew his own (the backstep keeps Lille's TENSHIN in JILLIEL: a 14 f fold, dash and open that reads as it is).
(defparameter *br-stand-ins*
  '((:br-recall :br-recall :br-o-recall :lb-w-fold) (:br-rc0 :br-rc0 :br-o-rc0 :lb-w-q3)
    (:br-rc1 :br-rc1 :br-o-rc1 :lb-w-sanren) (:br-rc2 :br-rc2 :br-o-rc2 :lb-e-sanren) (:br-rc3 :br-rc3 :br-o-rc3 :lb-w-nijushi)
    (:br-rc4 :br-rc4 :br-o-rc4 :br-rc3)   ; (decision V8: to be drawn; *BR-RC4-CLIP* plays :br-rc3 / :br-o-rc3 till then)
    (:br-to-en :br-to-en :br-o-to-en :lb-w-fold) (:br-backstep :lb-w-tenshin :br-o-backstep :lb-w-tenshin))
  "His own moves' clips (JILLIEL's, the owl's) and the batch-1 stand-ins they replaced (the art batch, 2026-10-09).")
(defparameter *br-owl-clip-map* '(:br-recall :br-o-recall :br-rc0 :br-o-rc0 :br-rc1 :br-o-rc1 :br-rc2 :br-o-rc2
                                  :br-rc3 :br-o-rc3 :br-rc4 :br-o-rc4 :br-to-en :br-o-to-en :lb-w-tenshin :br-o-backstep)
  "The owl kits' :clip-map: the shared moves (the recall, its strings, the mode turns) on the claws' own clips
(*BR-STAND-INS*; the owl's backstep steps its lift with ranged from f0 (art §17.1), not Lille's TENSHIN's f6).")

;;; ================================================================ forms
(defparameter *barro-hooks* '(:tick barro-tick :ok barro-ok :hit barro-hit :struck barro-struck :draw br-draw
                               :body-alpha lille-body-alpha :hud-guard lille-hud-guard)
  "His mechanics (kit.lisp KIT-HOOK): the trace count, MUJITTAI's perfect-Hoho drop, Trompete's reflect, the revival's
clearing (:tick); the lay prices, the L links, the seal (:ok); the 狙擊 gauge, the J's materialise, the refunds (:hit); the
pacing log (:struck); his looks (:draw, barro-art.lisp); the old Lille's MUJITTAI looks, by form only (lille-art.lisp):
the column half see-through (:body-alpha) and the guard bar's jade outline (:hud-guard) (missing from the copy until
2026-10-10: the user, 「目前的 U 無實體防禦模式只有腿部特效正確」).")

(defparameter *br-kamae-strings*
  (append (loop for s in '(:br-kamae :br-kamae-k :br-kamae-j :br-kamae-re)
                append `((,s :kamae-l :br-k-shot) (,s :kamae-sp1 :br-k-sanren) (,s :kamae-sp2 :br-k-hiren)
                         (,s :kamae-j :br-k-snap) (,s :kamae-k :br-k-taisha) (,s :kamae-step :br-k-dash)
                         (,s :kamae-k2 :br-k-senko) (,s :kamae-k3 :br-k-hajin)))
          '((:br-k-dash :kamae-back :br-kamae-re) (:br-k-snap :kamae-step :br-k-dash)))
  "The shooting stance's follow-ups: non-button strings (KIT-NEXT) its :tick starts (BR-KAMAE-TICK); the Step and its way
back into the stance (decision V6; the snap shot's cancel into it, V9c); the K's three tiers by the pips (:kamae-k / -k2 / -k3, BR-KAMAE-PICK picks one:
decision V9; at 0 pips the plain K1, V9d).")
(defparameter *br-recall-strings*
  '((:br-recall :rc0 :br-rc0) (:br-recall :rc1 :br-rc1) (:br-recall :rc2 :br-rc2) (:br-recall :rc3 :br-rc3)
    (:br-recall :rc4 :br-rc4))
  "The recall's derivative strings: non-button strings its f7 starts (BR-RECALL-FIRE).")
(defparameter *br-melee-strings*
  (append *br-recall-strings*
          '((:br-l-link :br-recall :br-recall) (:br-l-link :br-backstep :br-backstep) (:br-l-link :br-to-en :br-to-en)))
  "The melee forms' non-button strings: the recall's, and the L router's three targets (BR-L-LINK-GO; batch 4).")

(defkit :barro :base
  :name "LILLE II" :body :lille :weapon :diagramm :stance :lb-stance :calm t
  :intro :lb-intro :win :lb-win :intro-callout "THE X-AXIS"
  :walk *br-walk* :run *br-run* :reishi *reishi-max* :swing-sfx :whoosh-light :mult *br-mult* :taken *br-taken*
  :commands (:q :br-j1 :f :br-k1 :sig :br-kamae :sp1 :br-sanren :sp2 :br-hiren :breaker :br-breaker :kikon :br-kikon)
  :grid (:br-j1 :br-j2 :br-j3 :br-k1 :br-k2 :br-k3 :br-j2s :br-k2s)
  :strings *br-kamae-strings*
  :l-after-k :br-kamae-k                        ; L after K1 / K2 / K3: the stance at f4 (the old rule)
  :l-after-j :br-kamae-j                        ; L after J1 / J2 / J3 (hit or block): the same (decision V9c)
  :awaken-form :jilliel-kin :kikon-konpaku 2 :hooks *barro-hooks*
  :ai (:intents (:approach 1 :pressure 1 :zone 5 :defend 2)
       :ranges (:approach (2.2 8.0) :pressure (1.3 2.2) :zone (8.0 20.0) :defend (5.0 9.0))
       :moves ((0.0 2.2 :q 4 :f 2 :breaker 1 :step 2 :sig 1)
               (2.2 6.0 :sp2 1 :step 2 :sp1 1 :sig 3 nil 1)
               (6.0 99.0 :sig 6 :sp1 1 nil 1))
       :guard 0.5 :hoho 0.3 :dash 0.3 :dash-back 0.7 :block-string 0.3 :o-ender 0.3 :l-after-k 0.6 :l-after-j 0.3 :kikon-range 7.7
       :awaken (:min-taken 150)
       :zone (:p 0.5 :near 6.0) :pip (:p 0.6 :near 4.0) :reflex br-ai-reflex   ; (his CPU: batch 4, §13)
       :close (:p 0.4 :near 3.0)                           ; (the stance for the close snipe, +2: decision V8)
       :kamae (:full 0.9 :escape 0.4 :escape-in 3.0        ; (the stance's K by pips: decision V9; :escape the Step at 0 pips: V9d)
               :close-shot 0.5 :close-in 3.0               ; (the close snipe at <= 1 pip, safe: decision V8)
               :snap-link 0.8 :snap-j1 0.8 :snap-step 0.5 :snap-step-in 4.0 :dash-snap 0.6)   ; (the snap's links: V9c)
       :kamae-step (:p 0.4 :threat 0.5 :close 3.0 :rush 5.0)                     ; (the stance's Step: batch 6, §16)
       :hard (:near 2.5 :punish-f 18 :crush 40.0)))                              ; (the HARD layer: *BR-AI-HARD*)

;; JILLIEL melee (the awakening enters it [G]): the wing strings, SP1 / SP2 the old KIN's, L to ranged, J3 -> L the
;; backstep, K3 -> L the recall, U MUJITTAI, P the revival
(defkit :barro :jilliel-kin :inherit :base
  :lift *br-jilliel-lift* :awakening t :form-name "JILLIEL KIN" :walk *br-walk-kin* :run *br-run-kin*
  :mult *br-jilliel-mult* :taken *br-jilliel-taken* :kikon-konpaku 3 :guard-to :jilliel-kin-mujittai :gg-regen *br-gg-regen*
  :bankai-form :shin :bankai-ok barro-bankai-ok :endless-form :jilliel-kin
  :body :lille-jilliel-kin :weapon nil :stance :lb-w-stance :cine lb-jilliel-cine :u-tag "U: MUJITTAI" :swing-sfx :whoosh-heavy
  :commands (:q :br-w-j1 :f :br-w-k1 :sig :br-to-en :sp1 :br-w-sanren :sp2 :br-w-nijushi :breaker :br-w-breaker
             :kikon :br-w-kikon)
  :grid (:br-w-j1 :br-w-j2 :br-w-j3 :br-w-k1 :br-w-k2 :br-w-k3 :br-w-j2s :br-w-k2s)
  :strings *br-melee-strings*
  :l-after-k :br-l-link :l-after-j :br-l-link     ; (the router: K3 the recall, J3 the backstep, else the mode turn: BR-L-ROUTE)
  :ai (:intents (:approach 3 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.4 6.0) :pressure (1.4 2.4) :zone (3.0 6.0) :defend (3.0 6.0))
       :moves ((0.0 2.4 :q 4 :f 4 :breaker 1)
               (2.4 8.0 :sig 2 :step 1 :sp1 1 nil 1)
               (8.0 99.0 :sig 4 :step 1 nil 1))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.8 :block-string 0.3 :o-ender 0.3 :kikon-range 8.5
       :string-k 0.6 :recall (:p 0.6 :n 2 :low-n 1 :low 0.35 :off-n 1) :backstep (:p 0.6 :min 2)
       :route (:p 0.6 :bank 6) :hard (:near 0.0 :punish-f 12 :crush 40.0)
       :stance (:p 0.4 :max 120 :gg 30) :bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1)
       :sp-ender br-ai-sp-ender :opp-trace (:p 0.5) :opp-reflex br-opp-trace :reflex br-ai-reflex))

;; U in every awakened form: 無実体 MUJITTAI (the old Lille's, the user 2026-10-09): West's ward with :intangible; every
;; command drops it (no :keep)
(defkit :barro :jilliel-kin-mujittai :inherit :jilliel-kin
  :guard-to nil :drop-to :jilliel-kin :passives (:ward :intangible) :stance :lb-w-fold :u-tag "U: MUJITTAI")

;; JILLIEL ranged (EN, afloat): L / SP1 / SP2 lay traces, J / K back to melee in place (their moves are melee's J1 / K1,
;; BR-MELEE-IN); J in a lay's window: TENSHIN in (decision V6a)
(defkit :barro :jilliel :inherit :jilliel-kin
  :form-name "JILLIEL" :walk *br-walk-en* :run *br-run-en* :guard-to :jilliel-mujittai :body :lille-jilliel
  :commands (:q :br-w-j1 :sig :br-e-lay :sp1 :br-e-sanren :sp2 :br-e-nijushi)   ; (J: J1 in place, decision V6a)
  :ai (:intents (:approach 1 :pressure 0 :zone 5 :defend 2)
       :ranges (:approach (6.0 12.0) :pressure (6.0 9.0) :zone (6.0 12.0) :defend (8.0 12.0))
       :moves ((0.0 3.0 :q 2 :f 2 :step 1)                 ; (decision V8b: the pre-V8 bands, L lays from range again)
               (3.0 14.0 :sig 4 :sp1 1 :sp2 1 :f 1 nil 1)
               (14.0 99.0 :sig 2 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.4 :dash-back 0.6 :kikon-range 8.5
       :fire (:p 0.8 :n 1 :in 8.0 :far-in 13.0 :close 3.0 :busy 0.5 :busy-f 30)
       :lay (:far 4.0 :reserve 10.0 :every 12 :sp1 0.3 :near 6.0 :goal (2 4) :close-goal 1 :bank-p 0.25 :bank-goal 6
             :big-p 0.2 :big-goal 10 :safe 0.5 :patience 90)
       :steer (:p 0.4) :hard (:near 2.0 :punish-f 30 :crush 40.0)
       :stance (:p 0.4 :max 120 :gg 30) :bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1)
       :opp-trace (:p 0.5) :opp-reflex br-opp-trace :reflex br-ai-reflex))

(defkit :barro :jilliel-mujittai :inherit :jilliel
  :guard-to nil :drop-to :jilliel :passives (:ward :intangible) :stance :lb-w-fold :u-tag "U: MUJITTAI")

;; the owl (P at <= 4 Konpaku in any JILLIEL form, Kenpachi's Bankai path: Konpaku -> 1, Reishi full, the traces cleared;
;; the revival enters its ranged mode, as the old): melee the claws, SP1 裁きの光明, SP2 Trompete (reflect and seal); ranged
;; the old owl EN's casts laying traces. x1.1 dealt, x1.1 taken, R - 1, refunds 5 / 2, Kikon 4, no revival from here
(defkit :barro :shin-kin :inherit :jilliel-kin
  :lift 0.0 :form-name "SHIN KIN" :mult *br-owl-mult* :taken *br-owl-taken* :kikon-konpaku 4
  :guard-to :shin-kin-mujittai :bankai-form nil :bankai-ok nil :body :lille-shin :stance :lb-o-stance :cine lb-revive-cine
  :clip-map *br-owl-clip-map*
  :commands (:q :br-o-j1 :f :br-o-k1 :sp1 :br-misuji :sp2 :br-trompete :breaker :br-o-breaker :kikon :br-o-kikon)
  :grid (:br-o-j1 :br-o-j2 :br-o-j3 :br-o-k1 :br-o-k2 :br-o-k3 :br-o-j2s :br-o-k2s)
  :ai (:intents (:approach 3 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.6 6.0) :pressure (1.4 2.6) :zone (3.0 6.0) :defend (3.0 6.0))
       :moves ((0.0 2.6 :q 4 :f 4 :breaker 1)
               (2.6 8.0 :step 1 :sp1 1 nil 1)
               (8.0 99.0 :sp2 2 :sig 1 :step 1 nil 1))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.8 :block-string 0.3 :o-ender 0.3 :kikon-range 9.0
       :string-k 0.6 :recall (:p 0.6 :n 2 :low-n 1 :low 0.35 :off-n 1) :backstep (:p 0.6 :min 2)
       :route (:p 0.6 :bank 6) :hard (:near 0.0 :punish-f 12 :crush 40.0)
       :stance (:p 0.4 :max 120 :gg 30) :opp-reflect (:p 0.3)
       :sp-ender br-ai-sp-ender :opp-trace (:p 0.5) :opp-reflex br-opp-trace :reflex br-ai-reflex))

(defkit :barro :shin-kin-mujittai :inherit :shin-kin
  :guard-to nil :drop-to :shin-kin :passives (:ward :intangible) :stance :lb-o-fold :u-tag "U: MUJITTAI")

(defkit :barro :shin :inherit :shin-kin
  :lift *br-owl-lift* :form-name "SHIN" :walk *br-walk-en* :run *br-run-en* :guard-to :shin-mujittai :stance :lb-oe-stance
  :commands (:q :br-o-j1 :sig :br-oe-lay :sp1 :br-oe-sabaki :sp2 :br-oe-trompete)   ; (J: J1 in place, decision V6a)
  :ai (:intents (:approach 1 :pressure 0 :zone 5 :defend 2)
       :ranges (:approach (6.0 12.0) :pressure (6.0 9.0) :zone (6.0 12.0) :defend (8.0 12.0))
       :moves ((0.0 3.0 :q 2 :f 2 :step 1)                 ; (decision V8b: the pre-V8 bands, L lays from range again)
               (3.0 14.0 :sig 4 :sp1 1 :sp2 1 :f 1 nil 1)
               (14.0 99.0 :sig 2 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.4 :dash-back 0.6 :kikon-range 9.0
       :fire (:p 0.8 :n 1 :in 8.0 :far-in 13.0 :close 3.0 :busy 0.5 :busy-f 30)
       :lay (:far 4.0 :reserve 10.0 :every 12 :sp1 0.3 :near 6.0 :goal (2 4) :close-goal 1 :bank-p 0.25 :bank-goal 6
             :big-p 0.2 :big-goal 10 :safe 0.5 :patience 90)
       :steer (:p 0.4) :hard (:near 2.0 :punish-f 30 :crush 40.0)
       :stance (:p 0.4 :max 120 :gg 30) :opp-trace (:p 0.5) :opp-reflex br-opp-trace :reflex br-ai-reflex))

(defkit :barro :shin-mujittai :inherit :shin
  :guard-to nil :drop-to :shin :passives (:ward :intangible) :stance :lb-oe-fold :u-tag "U: MUJITTAI")

(defparameter *br-forms* '(:base :jilliel-kin :jilliel-kin-mujittai :jilliel :jilliel-mujittai :shin-kin :shin-kin-mujittai
                           :shin :shin-mujittai)
  "Every form of his (the HUD meter, the host tests).")

;; his names in the brush tables (brush.lisp): the intro's column and the technique columns (not on the host); the new
;; moves' glyphs (速 遠 後 回 収; 穿 甲 弾 破 for decision V9's K tiers) are in glyphs-extra.lisp (the art batch, DUEL_LILLE_V2 §12)
(when (boundp '*brush-names*)
  (setf *brush-names* (append (remove :barro *brush-names* :key #'first) '((:barro "リジェ・バロ" "LILLE II")))
        *brush-callouts*
        (append (remove-if (lambda (c) (member (first c) '(:br-k-shot :br-k-sanren :br-k-hiren :br-k-taisha :br-sanren :br-hiren
                                                            :br-k-senko :br-k-hajin
                                                            :br-e-sanren :br-e-nijushi :br-w-sanren :br-w-nijushi :br-misuji
                                                            :br-trompete :br-oe-sabaki :br-oe-trompete :br-k-snap :br-to-en
                                                            :br-backstep :br-recall :br-rc0 :br-rc1 :br-rc2 :br-rc3 :br-rc4 :br-k-dash)))
                           *brush-callouts*)
                '((:br-k-shot "万物貫通" "THE X-AXIS" nil) (:br-k-sanren "三連" "SANREN" nil) (:br-k-hiren "飛廉脚" "HIRENKYAKU" nil)
                  (:br-k-taisha "退射" "TAISHA" nil) (:br-k-senko "穿甲弾" "SENKO-DAN" nil)
                  (:br-k-hajin "破陣弾" "HAJIN-DAN" nil) (:br-sanren "三連" "SANREN" nil) (:br-hiren "飛廉脚" "HIRENKYAKU" nil)
                  (:br-e-sanren "三連" "SANREN" nil) (:br-e-nijushi "二十四孔" "NIJUSHI-KO" nil)
                  (:br-w-sanren "三連" "SANREN" nil) (:br-w-nijushi "二十四孔" "NIJUSHI-KO" nil)
                  (:br-misuji "裁きの光明" "SABAKI NO KOMYO" nil) (:br-trompete "神の喇叭" "TROMPETE" nil)
                  (:br-oe-sabaki "裁きの光明" "SABAKI NO KOMYO" nil) (:br-oe-trompete "神の喇叭" "TROMPETE" nil)
                  (:br-k-snap "速射" "SOKUSHA" nil) (:br-to-en "遠" "EN" nil) (:br-backstep "後退" "KOTAI" nil)
                  (:br-recall "回収" "KAISHU" nil) (:br-rc0 "回収" "KAISHU" nil) (:br-rc1 "二連" "NIREN" nil)
                  (:br-rc2 "四連" "YONREN" nil) (:br-rc3 "裁き" "SABAKI" nil)
                  (:br-rc4 "裁き" "SABAKI KIWAMI" nil)   ; (極 has no glyph yet: the art batch may bake it, glyphs-extra.lisp)
                  (:br-k-dash "飛廉脚" "HIRENKYAKU" nil)))))

;;; ================================================================ his state (the sim's): a component on his fighter entity
(defcomponent brs
  "Lille II's state: on his fighter entity, made on its first use, so a new match's fighter starts fresh."
  (snipe 0 :type fixnum)                  ; the 狙擊 gauge, 0-3
  (armed nil)                             ; the running stance L / SP1 / SP2 may still fill a pip (once a move)
  (k-plan nil)                            ; his CPU's stance follow-up (picked once at its f6)
  (l-to :br-to-en)                        ; the melee L router's target (BARRO-OK, BR-L-ROUTE), started at its f0
  (opp-roll 0 :type fixnum)               ; a CPU facing him: the newest trace id it rolled for (BR-OPP-TRACE)
  (opp-on nil)                            ; ... it stood on one of his lines last look (a crossing rolls again: batch 6)
  (opp-t -999 :type fixnum)               ; ... the tick it last rolled (*BR-OPP-GAP*)
  (dash-dir 0f0 :type single-float)       ; his CPU's stance Step: the strafe (+1 / -1: back and aside, 0: straight back)
  (trace-n 0 :type fixnum)                ; the traces laid (their ids count up)
  (live 0 :type fixnum)                   ; live traces now (counted each step: the HUD, his CPU)
  (recall-n 0 :type fixnum)               ; the recall's count (its f0) for its string (its f7)
  (stance 0 :type fixnum)                 ; frames of the current MUJITTAI
  (sealed nil)                            ; the owl's Trompete was reflected: SP2 sealed for the match
  (dashed nil)                            ; the stance's Step used (once per stance; decision V6)
  (snap-j nil)                            ; a J pressed during the snap shot: its J1 link on the hit (decision V9c)
  (dash-end 99 :type fixnum)              ; TENSHIN in: the move frame its dash ends (the link frame)
  (latch nil)                             ; ... the J1 / K1 it links into (:q, a K pressed during it :f)
  (switch-to nil)                         ; ... the melee form it turns into (6 f into the dash, or at its end)
  (dash-j nil)                            ; ... the J1 it started (that move while it runs): it fires no trace (V9g)
  (step-shot nil)                         ; the stance Step: the frame its latched moving snap fires (V9i) ...
  (step-fired nil)                        ; ... it fired (one a Step)
  (dash-took nil)                         ; ... a J / K pressed during the dash taken for the link (V9h) ...
  (dash-next nil)                         ; ... and the next one (:q / :f), pressed again at the J1's hit frame (V9h)
  (dash-q nil)                            ; a ranged lay: a J latched before its last point (it dashes there; V6c)
  (laid nil)                              ; ... its latest BR-LAY set a point (paid; a refused one sets none: no dash)
  (late 0 :type fixnum)                   ; frames left after a lay that set its points: a J dashes (*BR-DASH-LATE*; V6c)
  (awake-t -1 :type fixnum) (revive-t -1 :type fixnum))   ; ticks of the awakening and the revival (the pacing log)
(defvar *br-test-awake* nil
  "Debug 82041 (82040 off): the ASSIST gate's masher as him (P1, habit :dumb) plays every match from JILLIEL melee (forced at
its first free step: the masher never awakens itself), so the gate measures his melee / ranged routes (batch 6).")
(defvar *br-test-diff* nil
  "Debug 82050 / 82051 / 82052 (82053 off): his CPU plays EASY / NORMAL / HARD (difficulty and perception delay) whatever
the gate's *DIFFICULTY* (the others' stays): his own difficulty ladder against fixed opponents (batch 6, §16).")

(defvar *br-reflect-test* nil "Debug 82007 / 82008: P2 reflects P1's Trompete by a guard (:guard) / a perfect Hoho (:hoho).")
(defun br (e)
  "E's Lille II state (his BRS component, attached on the first call: a new fighter entity, a new match, gets a fresh one)."
  (or (brs e) (let ((st (make-brs))) (add-component e st) st)))

;;; hazard data: his traces carry one of these and BR-HZ as their hook (his look-only hazards carry Lille's LBH, LB-LOOK)
(defstruct (brh (:conc-name brh-))
  (src nil)                               ; what laid it: :l :sp1 :sp2 (its damage, its width)
  (id 0 :type fixnum)                     ; they count up per side (the oldest drops first)
  (live t)                                ; laid, not yet materialised
  (width 0f0 :type single-float)          ; its radius (0.6, SP2's 1.2)
  (ux 0f0 :type single-float) (uz -1f0 :type single-float)   ; its line's direction: from the aim point (the hazard's x z)
                                          ;  through him, recomputed every step (BR-TRACES-AIM; decision V7)
  (vol nil))                              ; its line: a :cap volume from the point along (ux uz)

;;; ================================================================ hooks
(defun br-tick-brain (e)
  "The brain his ticks decide on (the stance's follow-up): his own CPU's; NIL for a human (no brain, or one switched off) and
for the ASSIST gate's button-masher (habit :dumb, read as a human)."
  (let ((b (brain e))) (and b (not (brain-off b)) (not (eq (brain-habit b) :dumb)) b)))

(defun barro-ok (e command combo)
  "His kit's refusals: a lay short of its flash step (BR-LAY-OK-P: ranged L 3, SP1 9, SP2 9; L's 3 back since decision V8b);
the melee L router (an L latched in a J / K link) routed off the link it was pressed in (BR-L-ROUTE, kept in BRS-L-TO for
its f0): off J3 the backstep only with a live trace to spend, else the mode turn in place (decision V8a; no flash step since),
his CPU's only when it pays (BR-AI-L-OK-P: the recall at its count, the backstep with its traces); the owl's SP2 once sealed."
  (let* ((f (fighter e)) (form (fighter-form f)) (g (gauges e)) (b (br-tick-brain e))
         (cur (and (eq (fighter-state f) :move) (fighter-move f))))
    (cond ((br-sp2-sealed-p command form (brs-sealed (br e))) nil)
          ((and (eq command :sig) (typep combo 'move))
           (let ((l (mv-name combo)))
             (and cur
                  (if (eq l :br-l-link)
                      (let ((to (br-l-route (mv-kind cur) (and (member :ender (mv-flags cur)) t) (br-live-traces e))))
                        (setf (brs-l-to (br e)) to)                                   ; (decision V8a: no trace, no backstep)
                        (or (null b) (br-ai-l-ok-p e to)))
                      (and (br-l-link-ok-p l (mv-name cur) (mv-kind cur) (member :ender (mv-flags cur)))
                           (br-kamae-link-ok-p l (brs-snipe (br e)))))                ; (decision V9e: no pip, no stance link)
                  t)))
          (t (br-lay-ok-p (or (kit-drop-to (fighter-kit f)) form) command (gauges-fs g))))))   ; (MUJITTAI: its mode's price)

(defun barro-bankai-ok (e)
  "His kit's :bankai-ok: P revives him into the owl from any JILLIEL form where the first awakening could be taken, with <=
*BANKAI-KONPAKU* Konpaku (BR-REVIVE-OK-P)."
  (let ((f (fighter e))) (br-revive-ok-p (fighter-form f) (awaken-state-p e f) (gauges-konpaku (gauges e)))))

(defun barro-tick (e f g)
  "Per step (his kit's :tick): his traces' lines turned through him (BR-TRACES-AIM) and counted; the awakening's and the revival's clocks (the revival clears every
trace); MUJITTAI's own perfect-Hoho drop (his counter strike is an attack: solid) and its frame count; Trompete's reflect
check on its f59."
  (declare (ignore g))
  (when (or *br-test-awake* *br-test-diff*) (br-test-tick e f))   ; (debug 82041 / 82050-52: the gates' flags, batch 6)
  (let ((st (br e)) (form (fighter-form f)))
    (br-traces-aim e)                                     ; (every line through him, decision V7)
    (let ((mv (fighter-move f)))                          ; (decision V6c: the J latch lives in a lay only; the
      (unless (and (eq (fighter-state f) :move) mv (eq (mv-tick mv) 'br-lay-tick)) (setf (brs-dash-q st) nil))   ; late
      (cond ((not (member (fighter-state f) '(:idle :guard :run))) (setf (brs-late st) 0))                       ;  window
            ((and (plusp (brs-late st)) (zerop (fighter-freeze f))) (decf (brs-late st)))))                       ;  counts down free)
    (unless (and (brs-dash-j st) (eq (fighter-state f) :move) (eq (fighter-move f) (brs-dash-j st)))
      (setf (brs-dash-j st) nil))                         ; (decision V9g: only while TENSHIN in's own J1 runs)
    (unless (or (brs-dash-j st) (and (eq (fighter-state f) :move) (fighter-move f) (eq (mv-tick (fighter-move f)) 'br-tenshin-tick)))
      (setf (brs-dash-next st) nil))                      ; (decision V9h: a kept press lives through the dash and its J1)
    (setf (brs-live st) (br-live-traces e))
    (when (and (br-awake-form-p form) (minusp (brs-awake-t st)))
      (setf (brs-awake-t st) *match-tick*) (pace e :awaken-tick *match-tick*))
    (when (and (br-owl-form-p form) (minusp (brs-revive-t st)))
      (setf (brs-revive-t st) *match-tick*) (pace e :revive-tick *match-tick*)
      (br-clear-traces e)
      (setf (brs-live st) 0))
    (cond ((member :intangible (kit-passives (fighter-kit f)))
           (when (and (eq (fighter-state f) :hoho) (fighter-perfect f))
             (set-form e (kit-drop-to (fighter-kit f)))
             (clog "~a MUJITTAI dropped: the perfect Hoho's counter" (side-name e)))
           (incf (brs-stance st))
           (pace e :stance-frames))
          (t (setf (brs-stance st) 0)))
    (let ((mv (fighter-move f)))
      (when (and (eq (fighter-state f) :move) mv (eq (mv-name mv) :br-trompete) (eq (fighter-phase f) :main))
        (when *br-reflect-test* (br-reflect-test-step e f))
        (when (= (fighter-sf f) 59) (br-reflect-check e st mv))))))

(defun barro-hit (att def res hw mv hazard ranged)
  "After a hit he dealt (his kit's :hit): the stance's L / SP1 / SP2 fill a pip on their first hit (BR-SNIPE-AFTER; the L
two within 3 m, decision V8); a K fires no trace (decision V8; a J does at its first active frame, BR-J-MAT); a
materialised trace's flash step back (BR-REFUND: 0 since decision V6); the pacing log. (Decision V8's ranged L swing, its
hit setting the point, is gone: decision V8b, the plain lay again.)"
  (declare (ignore def ranged))
  (let ((st (br att)) (c (contact-of res)))
    (when (and mv (not hazard) (getf (mv-params mv) :snipe) (brs-armed st) (eq c :hit))   ; (a block fills nothing and
      (setf (brs-armed st) nil)                                                           ;  leaves the move armed)
      (let ((n (br-snipe-after (brs-snipe st) c (fighter-dist (fighter att)) (getf (mv-params mv) :snipe-close))))
        (when (> n (brs-snipe st)) (pace att (if (> n (1+ (brs-snipe st))) :snipe-fill2 :snipe-fill)))   ; (V8: +2 close)
        (setf (brs-snipe st) n)))
    (when (and mv (not hazard) (eq c :hit) (member (mv-kind mv) '(:quick :flash)) (br-melee-form-p (fighter-form (fighter att))))
      (let ((b (br-tick-brain att))) (when b (br-ai-route-latch att b mv))))             ; (his CPU's route: batch 6)
    (when (and hazard (brh-p (hazard-data hazard)))
      (let* ((owl (br-owl-form-p (fighter-form (fighter att)))) (fs (br-refund c owl)))
        (when (plusp fs) (pay-gauges (or (siphon-of att) att) 0.0 fs) (pace att :trace-refund)))
      (pace att (if (eq c :hit) :trace-hit :trace-guarded)))
    (when (and hw (br-x-hit-p hw))
      (pace att (if (eq c :hit) :x-hit :x-guarded)))))

(defun barro-struck (def att res hw mv hazard ranged)
  "After a hit he took (his kit's :struck): MUJITTAI's pacing (passes)."
  (declare (ignore att hw mv hazard ranged))
  (when (and (member :intangible (kit-passives (kit-of def))) (eq res :blocked)) (pace def :passes)))

;;; ---------------------------------------------------------------- the shooting stance (§4)
(defun br-kamae-enter (e)
  "A fresh stance (L from neutral at f0, or after a K link at f4): no CPU plan yet, its Step unspent."
  (setf (brs-k-plan (br e)) nil (brs-dashed (br e)) nil)
  (pace e :kamae))

(defun br-kamae-pressed (vp)
  "The stance's follow-up a human pressed (buffered): :kamae-sp2 / -sp1 (Shift+L / Shift+K) / -j / -k / -l / -step, or NIL."
  (cond ((vpad-command-pressed-p vp :sig t) :kamae-sp2) ((vpad-command-pressed-p vp :flash t) :kamae-sp1)
        ((vpad-command-pressed-p vp :quick nil) :kamae-j) ((vpad-command-pressed-p vp :flash nil) :kamae-k)
        ((vpad-command-pressed-p vp :sig nil) :kamae-l) ((vpad-command-pressed-p vp :step nil) :kamae-step)))

(defun br-kamae-go (e f st mv cmd)
  "Start the stance's follow-up CMD from stance move MV: L / SP1 / SP2 armed to fill a pip (SP1 / SP2 under their command's
bars, TRY-COMMAND's WITH); J the snap shot for a pip, K the shot of every pip's tier (decision V9), at 0 the plain J1 / K1 (V9d); Step 飛廉脚 once per
stance for its flash step (BR-KAMAE-STEP-OK-P; refused: the press is ignored). T when it started."
  (let* ((kit (fighter-kit f)) (snipe (brs-snipe st)) (name (br-kamae-pick cmd snipe)))
    (case cmd
      (:kamae-step (when (br-kamae-step-ok-p (brs-dashed st) (gauges-fs (gauges e)))   ; (decision V6: once, 10 FS)
                     (spend-fs (gauges e) *br-kamae-dash-fs*) (setf (brs-dashed st) t)
                     (start-move e (kit-next kit (mv-name mv) cmd)) t))
      (:kamae-l (start-move e (kit-next kit (mv-name mv) cmd)) (setf (brs-armed st) t) (pace e :k-shot) t)
      ((:kamae-sp1 :kamae-sp2)
       (when (try-command e f (if (eq cmd :kamae-sp1) :sp1 :sp2) nil nil (kit-next kit (mv-name mv) cmd))
         (setf (brs-armed st) t) (pace e (if (eq cmd :kamae-sp1) :k-sanren :k-hiren)) t))
      ((:kamae-j :kamae-k)   ; (decision V9: J the snap shot for a pip, K the shot of every pip's tier; V9d: at 0 J1 / K1)
       (let ((mv2 (kit-move kit name)))
         (setf (brs-snipe st) (br-kamae-left cmd snipe))
         (start-move e mv2)
         (pace e (case name ((:br-j1 :br-k1) :kamae-drop) (:br-k-snap :snap) (:br-k-taisha :k-tier1)
                   (:br-k-senko :k-tier2) (t :k-tier3)))
         t)))))

(defun br-kamae-tick (e)
  "One step of the stance: it turns at *BR-AIM-TRACK*; from f6 the first L / SP1 / SP2 / J / K fires its follow-up (his
CPU's: BR-AI-KAMAE's plan); past the hold (30 f, 90 while L is held) the stance recovers (R 14)."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (when (and (eq (fighter-state f) :move) mv (member (mv-name mv) '(:br-kamae :br-kamae-k :br-kamae-j :br-kamae-re)))
      (let* ((st (br e)) (sf (fighter-sf f)) (vp (pilot-vpad (pilot e))) (b (br-tick-brain e)))
        (turn-to-opp e f (track-step *br-aim-track*))
        (when (>= sf *br-kamae-up*)
          (let ((cmd (if b (br-ai-kamae e f st b) (br-kamae-pressed vp))))
            (when cmd
              (let ((button (getf '(:kamae-j :quick :kamae-k :flash :kamae-l :sig :kamae-sp1 :flash :kamae-sp2 :sig
                                    :kamae-step :step)
                                  cmd)))
                (if (br-kamae-go e f st mv cmd)
                    (progn (unless b (vpad-consume! vp button)) (return-from br-kamae-tick nil))
                    (if b (setf (brs-k-plan st) :kamae-l) (vpad-consume! vp button)))))))
        (when (br-kamae-hold-over-p sf (vpad-down vp :sig))
          (setf (fighter-sf f) (+ *br-kamae-up* *br-kamae-max*)))))))

(defun br-kamae-dash (e)
  "The stance's Step 飛廉脚 f0 (decision V6, the old LB-KAMAE-DASH): *BR-KAMAE-DASH* m in the stick direction (neutral: away
from him; his CPU's: BR-AI-STEP-STICK, straight back or back and aside off a line, batch 6) over *BR-KAMAE-DASH-F*,
iframes f0-7 (*BR-KAMAE-DASH-IFRAMES*), the flash step's vanish."
  (let* ((f (fighter e)) (p (pos-of e)))
    (multiple-value-bind (to st) (if (br-tick-brain e) (br-ai-step-stick (brs-dash-dir (br e))) (stick-relative e f))
      (multiple-value-bind (to st) (step-direction to st -1.0)
        (multiple-value-bind (dx dz) (world-dir e f to st)
          (set-slide e *br-kamae-dash* *br-kamae-dash-f* dx dz))))
    (setf (fighter-invuln f) (max (fighter-invuln f) *br-kamae-dash-iframes*))
    (setf (brs-step-shot (br e)) nil (brs-step-fired (br e)) nil)   ; (decision V9i: one moving shot a Step)
    (pace e :k-dash)
    (emit :hoho-out e (aref p 0) (aref p 2))
    (emit :sfx :whoosh-light e)))
(defun br-kamae-back (e)
  "The Step's f11: back in the stance at its f6 (:br-kamae-re: a fresh window, the Step spent), the aim snapped onto him."
  (start-move e (kit-next (kit-of e) :br-k-dash :kamae-back))
  (turn-to-opp e (fighter e) 10.0))

(defun br-step-snap-frame (press)
  "The Step frame the moving snap shot latched on Step frame PRESS fires (decision V9i): *BR-STEP-SNAP-DELAY* later, at the
latest *BR-STEP-SNAP-LAST*."
  (min (+ press *br-step-snap-delay*) *br-step-snap-last*))

(defun br-k-dash-tick (e)
  "The stance Step (decision V9c): from its *BR-DASH-SNAP-F* a J (a human's press, buffered; his CPU's one roll at that frame,
:kamae :dash-snap x the difficulty, with a pip) at >= 1 pip latches the moving snap shot (decision V9i): it fires
BR-STEP-SNAP-FRAME while the Step slides on (BR-STEP-SNAP), once a Step, and the Step returns to the stance as usual; at 0
pips the J is J1 at once (V9c / V9d), the Step cancelled."
  (let* ((f (fighter e)) (mv (fighter-move f)) (st (br e)))
    (when (and (eq (fighter-state f) :move) mv (eq (fighter-phase f) :main) (br-dash-snap-p (fighter-sf f)))
      (let ((sf (fighter-sf f)))
        (when (and (brs-step-shot st) (>= sf (brs-step-shot st)))
          (setf (brs-step-shot st) nil (brs-step-fired st) t)
          (br-step-snap e f st))
        (unless (or (brs-step-shot st) (brs-step-fired st) (> sf *br-step-snap-last*))
          (let* ((b (br-tick-brain e)) (vp (pilot-vpad (pilot e)))
                 (go (if b
                         (and (= sf *br-dash-snap-f*) (>= (brs-snipe st) 1)
                              (< (sim-rnd01) (br-ai-chance (getf (ai-table e :kamae) :dash-snap 0.0) (brain-difficulty b))))
                         (vpad-command-pressed-p vp :quick nil))))
            (when go
              (unless b (vpad-consume! vp :quick))
              (cond ((>= (brs-snipe st) 1)
                     (setf (brs-step-shot st) (br-step-snap-frame sf))
                     (pace e :step-snap-latch))
                    (t (turn-to-opp e f 10.0)
                       (br-kamae-go e f st mv :kamae-j)
                       (pace e :dash-snap))))))))))

(defun br-step-snap (e f st)
  "The moving snap shot's frame (decision V9i): a pip spent (BR-KAMAE-LEFT); the snap shot's hit (:br-k-snap's window, 萬物貫通)
as a 2-frame line from him straight at the opponent (a hazard: the Step keeps sliding), his facing turned onto him; the
Step's iframes end (「開槍就取消」)."
  (let* ((kit (fighter-kit f)) (snap (kit-move kit :br-k-snap)) (hw (copy-hitwin (svref (mv-hits snap) 0)))
         (p (pos-of e)) (q (pos-of (opp-of e)))
         (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (d (max 0.001 (sqrt (+ (* dx dx) (* dz dz)))))
         (ux (/ dx d)) (uz (/ dz d)) (yaw (f32 (dir-yaw ux uz))))
    (setf (brs-snipe st) (br-kamae-left :kamae-j (brs-snipe st)) (hw-vols hw) nil)
    (turn-to-opp e f 10.0)
    (setf (fighter-invuln f) 0)
    (let ((h (spawn-hazard :br-step-snap e :x (aref p 0) :z (aref p 2) :yaw yaw :size *br-x-len* :life 3 :hw hw :hook 'br-hz
                                           :data (make-brh :src :snap :live nil :width 0.25f0 :ux (f32 ux) :uz (f32 uz)
                                                           :vol (make-vol :cap (list 0.6 *br-x-len* 1.2 0.25))))))
      (declare (ignore h)))
    (br-spawn-look-at e :shot (aref p 0) (aref p 2) yaw *br-x-len* 0.05 t)
    (emit :sfx :lb-crack e)
    (pace e :step-snap)))

(defun br-snap-enter (e) "The snap shot's f0: no J latched yet (decision V9c)." (setf (brs-snap-j (br e)) nil))

(defun br-snap-tick (e)
  "The snap shot (decision V9c): a J pressed during it is latched (a human's, consumed); from *BR-SNAP-LINK* on its hit the
latch links into J1 (no chase); else from *BR-SNAP-STEP-F* a Step cancels its recovery into the stance Step (BR-SNAP-STEP-P:
once per stance), which returns to the stance. His CPU: J1 on the hit inside J1's reach + 0.2 m (:kamae :snap-j1), the Step
off a whiff or a block inside :snap-step-in m (:snap-step), one roll each at that frame, x the difficulty."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (when (and (eq (fighter-state f) :move) mv (eq (fighter-phase f) :main) (zerop (fighter-lock f)))
      (let* ((st (br e)) (b (br-tick-brain e)) (vp (pilot-vpad (pilot e))) (sf (fighter-sf f)) (k (ai-table e :kamae))
             (kit (fighter-kit f)) (q (kit-command-move kit :q)))
        (when (and (null b) (vpad-command-pressed-p vp :quick nil))
          (vpad-consume! vp :quick) (setf (brs-snap-j st) t))
        (when (and b (= sf *br-snap-link*) (eq (fighter-contact f) :hit) q (<= (fighter-dist f) (+ (mv-reach q) 0.2))
                   (< (sim-rnd01) (br-ai-chance (getf k :snap-j1 0.0) (brain-difficulty b))))
          (setf (brs-snap-j st) t))
        (cond ((and (brs-snap-j st) (br-snap-link-p sf (fighter-contact f)))
               (setf (brs-snap-j st) nil)
               (when (try-command e f :q) (pace e :snap-j1)))
              ((br-snap-step-p sf (brs-dashed st) (gauges-fs (gauges e)))
               (when (if b
                         (and (= sf *br-snap-step-f*) (not (eq (fighter-contact f) :hit))
                              (< (fighter-dist f) (getf k :snap-step-in 4.0))
                              (< (sim-rnd01) (br-ai-chance (getf k :snap-step 0.0) (brain-difficulty b)))
                              (progn (setf (brs-dash-dir st) 0f0) t))
                         (and (vpad-command-pressed-p vp :step nil) (progn (vpad-consume! vp :step) t)))
                 (spend-fs (gauges e) *br-kamae-dash-fs*) (setf (brs-dashed st) t)
                 (start-move e (kit-next kit :br-k-snap :kamae-step))
                 (pace e :snap-step))))))))

(defun br-ai-kamae (e f st b)
  "His CPU's follow-up in the stance (BR-KAMAE-TICK, from f6): the plan picked once, on the first step it is up (one roll,
BR-AI-KAMAE-PLAN), then carried out. First the Step 飛廉脚 (batch 6, once a stance, BR-AI-KAMAE-STEP): a :kamae-step plan
clears itself, so the fresh window after the Step picks again (with the Step spent)."
  (unless (brs-k-plan st)
    (let* ((o (opp-of e)) (fo (fighter o)) (step (br-ai-kamae-step e f st b)))
      (setf (brs-k-plan st)
            (or step
                (br-ai-hard-kamae (br-ai-take-hard-plan e b) (brs-snipe st))   ; (the HARD layer's stance)
                (br-ai-kamae-plan (sim-rnd01) (fighter-dist f) (and (member (fighter-state fo) '(:stun :air)) t) (brs-snipe st)
                                  (>= (gauges-reiatsu (gauges e)) (* (kit-command-cost (fighter-kit f) :sp1) *reiatsu-bar*))
                                  (ai-table e :kamae) (brain-difficulty b)
                                  (eq (mv-name (fighter-move f)) :br-kamae-j)
                                  (br-kamae-step-ok-p (brs-dashed st) (gauges-fs (gauges e)))
                                  (let ((s (br-ai-seen b)))           ; (safe: his attack not coming, the close snipe: V8)
                                    (and s (not (br-ai-threat-p e s (fighter-dist f) *ai-threat-margin*)))))))
      (unless step (setf (brs-k-plan st) (br-learn-kamae e b (brs-k-plan st))))   ; (a learner's read of the shot, §13)
      (when (and (not step) (eq (brs-k-plan st) :kamae-step))   ; (decision V9d: the 0-pip escape / the learner's Step: straight back)
        (setf (brs-dash-dir st) 0f0)
        (pace e :ai-step-back))
      (pace e (intern (format nil "AI-~a" (brs-k-plan st)) :keyword))
      (why b :kamae (brs-k-plan st))))
  (let ((plan (brs-k-plan st)))
    (when (eq plan :kamae-step) (setf (brs-k-plan st) nil))   ; (the window after the Step picks again)
    plan))

(defun br-ai-kamae-step (e f st b)
  "The stance's Step for his CPU (batch 6, the stance's :ai :kamae-step; one roll a stance, BR-AI-KAMAE-STEP-PLAN): his
attack coming (perceived, BR-AI-THREAT-P), or him closing in (inside :close m, or running at him inside :rush m) with no
pip to answer it: :KAMAE-STEP, its direction kept in BRS-DASH-DIR (off a lane: back and aside, else straight back), or NIL."
  (let* ((k (ai-table e :kamae-step)) (s (br-ai-seen b)) (d (fighter-dist f)))
    (when (and k s)
      (let* ((threat (br-ai-threat-p e s d *ai-threat-margin*))
             (close (or (< d (getf k :close 3.0))
                        (and (< d (getf k :rush 5.0)) (member (snap-state s) '(:run :step)))))
             (plan (br-ai-kamae-step-plan (sim-rnd01) threat (and threat (br-ai-line-p s)) close
                                          (and (member (snap-state s) '(:stun :air :down)) t) (brs-snipe st)
                                          (brs-dashed st) (gauges-fs (gauges e)) k (brain-difficulty b))))
        (when plan
          (setf (brs-dash-dir st)
                (if (eq plan :side)
                    (let ((p (pos-of e)))
                      (f32 (line-off-strafe (snap-x s) (snap-z s) (snap-yaw s) (aref p 0) (aref p 2) (snap-x s) (snap-z s))))
                    0f0))
          (pace e (if (eq plan :side) :ai-step-side :ai-step-back))
          :kamae-step)))))

(defun br-k-lock (e)
  "The stance's L, f0: locked on the press: the jade lane along it (the 10 f before it fires)."
  (br-spawn-look e :lane *br-x-len* 0.5 t)
  (emit :sfx :lb-lock e))

(defun br-shot-fire (e)
  "A shot's fire frame (the stance's L, SP2, the snap shot, TAISHA, SP2 outside the stance): the line's look (jade with
萬物貫通), the crack."
  (let ((mv (fighter-move (fighter e))))
    (br-spawn-look e :shot (move-param e :len) 0.05 (and (member :x-axis (mv-flags mv)) t))
    (emit :sfx :lb-crack e)))

(defun br-line-shot (e)
  "SANREN's shots (f12, f22, f32): the line's look."
  (br-spawn-look e :shot (move-param e :len) 0.04 (and (member :uncatchable (mv-flags (fighter-move (fighter e)))) t))
  (emit :sfx :rift-cut e))

(defun br-lane-shot (e)
  "A Kikon module's lane: its look (the hit is the move's lane)."
  (br-spawn-look e :lane (move-param e :len) 0.5 t)
  (emit :sfx :kikon-slash e))

(defun br-beam-shot (e)
  "NIJUSHI-KO's / Trompete's / the recall's last line: the beam's look."
  (br-spawn-look e :beam 31.0 (or (move-param e :width) 1.2) t)
  (emit :sfx :explode e))

(defun br-sanren-tick (e)
  "SANREN: he turns 90 deg/s between the shots."
  (let* ((f (fighter e)) (sf (fighter-sf f)))
    (when (and (eq (fighter-phase f) :main) (< 14 sf 32) (not (<= 22 sf 24)))
      (turn-to-opp e f (track-step 90.0)))))

(defun br-slide (e)
  "The stance's SP2 / TAISHA / SP2 f0: the back-slide, the move's :slide metres over :slide-f frames (no iframes)."
  (let* ((p (pos-of e)) (f (fighter e)))
    (set-slide e (move-param e :slide) (move-param e :slide-f) (- (aref p 0) (fighter-ox f)) (- (aref p 2) (fighter-oz f)))
    (emit :sfx :hoho-out e)))

(defun br-slide-tick (e)
  "The back-slides: he keeps turning to the opponent while he slides, then the line is fixed (from :lock)."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (move-param e :lock))) (turn-to-opp e f (track-step 90.0)))))

(defun br-planted-tick (e)
  "A planted wind-up (NIJUSHI-KO, Trompete, their lays): turning at the move's :track until its :lock frame, then locked."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (move-param e :lock)))
      (turn-to-opp e f (track-step (move-param e :track))))))

(defun br-nijushi-tell (e) "NIJUSHI-KO f0: the 24 holes glow (the tell)." (setf (model-super (model e)) 0.6) (emit :sfx :awaken-rise e))
(defun br-trompete-tell (e) "Trompete f0: the rising pitch (the tell)." (setf (model-super (model e)) 1.0) (emit :sfx :lb-trumpet e))

(defun br-spawn-look (e kind len width lock)
  "A look-only hazard of his along his facing: a shot, a beam or a lane (Lille's LB-LOOK draws it; no hit)."
  (let ((p (pos-of e))) (br-spawn-look-at e kind (aref p 0) (aref p 2) (yaw-of e) len width lock)))
(defun br-spawn-look-at (e kind x z yaw len width lock)
  "BR-SPAWN-LOOK from (X Z) along YAW (a materialised trace's flash; the owl's :judge, LOCK :thick for SP2's wide one)."
  (spawn-hazard :br-fx e :x x :z z :yaw yaw :size len :life (case kind ((:beam :judge) 30) (t 16))
                         :hook 'br-hz :data (make-lbh :kind kind :len (f32 len) :width (f32 width) :lock lock) :look 'lb-look))

;;; ---------------------------------------------------------------- JILLIEL: the modes, the traces (§5)
(defun br-melee-in (e)
  "A melee J1's / K1's frame 0: pressed in a ranged mode (or its MUJITTAI, dropped there first), he is back in melee (the move goes
on: the same move is melee's). A ranged J within *BR-DASH-LATE* frames after a lay that set its points (BRS-LATE) is
TENSHIN in instead: its 2 f cancel copy starts here (decision V6c, the user 2026-10-10: 「整個放點招式＋收招後 10 幀」), spending a
trace (decision V8a; V9f: not the one that fires, BR-TENSHIN-OK-P; with none to spare, the J1 in place goes on)."
  (let* ((f (fighter e)) (st (br e)) (form (fighter-form f)) (to (br-melee-of form)))
    (cond ((and (plusp (brs-late st)) (br-ranged-form-p form) (eq (mv-kind (fighter-move f)) :quick) (br-tenshin-ok-p e))
           (setf (brs-late st) 0)
           (start-move e (br-tenshin-cancel-move f))
           (br-spend-far e t)
           (pace e :tenshin-late))
          ((not (eq to form)) (set-form e to) (pace e :to-melee)))))

(defun br-go-ranged (e)
  "The turn's last frame / the backstep's first: ranged mode."
  (let* ((form (fighter-form (fighter e))) (to (br-ranged-of form)))
    (unless (eq to form) (set-form e to) (pace e :to-ranged))))

(defun br-l-link-go (e)
  "The melee L router's f0: the move BARRO-OK routed it to (the recall off K3, the backstep off J3, else the mode turn)."
  (let ((f (fighter e)))
    (start-move e (kit-next (fighter-kit f) :br-l-link (brs-l-to (br e))))
    (pace e (case (brs-l-to (br e)) (:br-recall :l-recall) (:br-backstep :l-backstep) (t :l-to-en)))))

(defun br-halt-tick (e) "The mode turns, the recall: no string chase (the slide is their only movement)." (halt! e))

(defun br-backstep-go (e)
  "J3 -> L f0 (decision V6): one trace spent (decision V8a, the user 2026-10-10: 「後撤不再扣閃步」: no flash step; BARRO-OK
routed it here only with a trace): since decision V9h (the user 2026-10-10: 「後撤的代價改成射出」) the nearest within
*BR-NEAR-R* FIRES (BR-MATERIALISE-ONE: a fresh 26 f stagger, so the next round's TENSHIN in still combos), only with none
near the farthest is removed unfired (V8a's 「最遠那條，不射出」); *BR-BACKSTEP* m straight back from him over *BR-BACKSTEP-F*,
iframes f0-8, ranged now."
  (let* ((f (fighter e)) (p (pos-of e)))
    (if (br-materialise-one e) (pace e :backstep-fire) (br-spend-far e))
    (set-slide e *br-backstep* *br-backstep-f* (- (aref p 0) (fighter-ox f)) (- (aref p 2) (fighter-oz f)))
    (setf (fighter-invuln f) (max (fighter-invuln f) *br-backstep-iframes*))
    (br-go-ranged e)
    (pace e :backstep)
    (emit :hoho-out e (aref p 0) (aref p 2))
    (emit :sfx :whoosh-light e)))

(defun br-backstep-tick (e)
  "The backstep: no string chase; from the dash's end (BR-BACKSTEP-LAY-OK-P, f14) a ranged L / SP1 / SP2 (a human's press,
buffered) cancels its recovery: 「衝刺結束才能接」 (decision V6). His CPU lays from neutral after it."
  (halt! e)
  (let ((f (fighter e)))
    (when (and (eq (fighter-state f) :move) (br-backstep-lay-ok-p (fighter-sf f)) (zerop (fighter-lock f))
               (null (br-tick-brain e)))
      (let ((vp (pilot-vpad (pilot e))))
        (loop for (cmd button modded) in '((:sp2 :sig t) (:sp1 :flash t) (:sig :sig nil))
              when (vpad-command-pressed-p vp button modded)
                do (when (try-command e f cmd) (vpad-consume! vp button) (pace e :backstep-lay))
                   (return))))))

;;; ---------------------------------------------------------------- 転身 TENSHIN in: a J in a lay's window (decisions V6, V6a, V6c)
(defun br-tenshin-fire (e)
  "TENSHIN in's dash f0 (before BR-TENSHIN-GO): one line materialises, the nearest within *BR-NEAR-R* of him along its line
(BR-MATERIALISE-ONE: a 26 f stagger, 萬物貫通), none when no line is near; the dash and J1 follow (decision V6c, the user
2026-10-10: 「照原版：前衝第 0 幀觸發」: the old Lille's TENSHIN in fired at its f0, 26 > the dash + J1's 8 f, a real combo).
The order (decision V9f, the user 2026-10-10: 「覺醒 L > J 優先級改成實體化先於前衝」): the near line is kept for this; the
dash's price, the farthest of the others, was spent when it started (BR-SPEND-FAR, 2 f before); with no other trace there
was no TENSHIN in (BR-TENSHIN-OK-P: J1 in place, 「不前衝，原地出 J1」). (V8a's order spent first: a lone trace paid, none fired.)"
  (when (br-materialise-one e) (pace e :tenshin-fire)))

(defun br-tenshin-go (e)
  "TENSHIN in at its wind-up's end: the dash at him (BR-TENSHIN-DIST at *BR-TENSHIN-SPEED*, BR-TENSHIN-DASH-F frames), its
end kept (the link frame), iframes f0-8, free; the melee form to turn into; J1 latched (a K pressed during the dash: K1)."
  (let* ((f (fighter e)) (st (br e)) (p (pos-of e)) (dist (br-tenshin-dist (fighter-dist f))) (n (br-tenshin-dash-f dist)))
    (setf (brs-switch-to st) (br-melee-of (fighter-form f)) (brs-latch st) :q (brs-dash-end st) (+ (fighter-sf f) n)
          (brs-dash-took st) nil (brs-dash-next st) nil)
    (when (plusp n)
      (set-slide e dist n (- (fighter-ox f) (aref p 0)) (- (fighter-oz f) (aref p 2))))
    (setf (fighter-invuln f) (max (fighter-invuln f) *br-tenshin-iframes*))
    (let ((b (br-tick-brain e))) (when b (br-ai-route-in e b)))   ; (his CPU's melee route: the K route latches K1, batch 6)
    (pace e :tenshin)
    (emit :hoho-out e (aref p 0) (aref p 2))
    (emit :sfx :whoosh-light e)))

(defun br-tenshin-form (e)
  "TENSHIN in, *BR-TENSHIN-FORM* frames into the dash (or at its end): melee."
  (let ((to (brs-switch-to (br e)))) (when to (setf (brs-switch-to (br e)) nil) (set-form e to) (pace e :to-melee))))

(defun br-tenshin-tick (e)
  "TENSHIN in's frames (the old LB-SWITCH-TICK + LB-LINK-TICK): no string chase; a human's first J / K after the wind-up
latched (J1 by default; decision V9h, the user 2026-10-10: presses after it are not eaten, they stay buffered for J2 / K2;
until then the last press won and every press was consumed); melee *BR-TENSHIN-FORM* frames into the dash or at its end; from the dash's end the
latch starts the melee J1 / K1 (TRY-COMMAND), else the rest of the startup is skipped (R 8 after the dash)."
  (halt! e)
  (let* ((f (fighter e)) (mv (fighter-move f)) (st (br e)) (go *br-tenshin-windup*) (sf (fighter-sf f)))
    (when (< sf go) (setf (brs-dash-end st) 99))
    (when (and (eq (fighter-phase f) :main) (> sf go) (brs-switch-to st)
               (or (>= sf (brs-dash-end st)) (>= sf (+ go *br-tenshin-form*))))
      (br-tenshin-form e))
    (when (and (eq (fighter-phase f) :main) (zerop (fighter-lock f)))
      (unless (br-tick-brain e)
        (let ((vp (pilot-vpad (pilot e))))
          (when (> sf go)                                  ; (decision V9h: the first press is the link, the next one is
            (cond ((vpad-command-pressed-p vp :quick nil)  ;  kept for the J1's own J2 / K2: BR-J-MAT presses it again)
                   (vpad-consume! vp :quick)
                   (if (brs-dash-took st) (setf (brs-dash-next st) :q) (setf (brs-latch st) :q (brs-dash-took st) t)))
                  ((vpad-command-pressed-p vp :flash nil)
                   (vpad-consume! vp :flash)
                   (if (brs-dash-took st) (setf (brs-dash-next st) :f) (setf (brs-latch st) :f (brs-dash-took st) t)))))))
      (when (and (> sf go) (>= sf (brs-dash-end st)) (member (brs-latch st) '(:q :f)))
        (let ((c (brs-latch st)))
          (setf (brs-latch st) nil)
          (when (try-command e f c)
            (when (eq c :q) (setf (brs-dash-j st) (fighter-move f)))   ; (decision V9g: this J1 fires no trace)
            (pace e (if (eq c :q) :tenshin-j1 :tenshin-k1))))))
    (when (and (eq (fighter-state f) :move) (eq (fighter-move f) mv) (eq (fighter-phase f) :main)
               (>= (fighter-sf f) go) (>= (fighter-sf f) (brs-dash-end st)) (< (fighter-sf f) (1- (mv-s mv))))
      (setf (fighter-sf f) (1- (mv-s mv))))))

(defun br-tenshin-cancel-move (f)
  "TENSHIN in's 2 f cancel for F's form: JILLIEL's :br-tenshin-c, the owl's :br-o-tenshin-c."
  (find-move (if (br-owl-form-p (fighter-form f)) :br-o-tenshin-c :br-tenshin-c)))

(defun br-lay-tick (e)
  "A ranged lay (L / SP1 / SP2): the planted ones turn until their :lock (BR-PLANTED-TICK); TENSHIN in (decision V6c): a
human's J pressed at any frame of it is latched (consumed) and cancels it into TENSHIN in's 2 f wind-up on the frame its last
point is set, or at once from there to its end (BR-DASH-WINDOW-P; his CPU's BR-AI-CANCEL-P in the same window); its end
opens *BR-DASH-LATE* more frames (BRS-LATE: a ranged J then dashes, BR-MELEE-IN). A lay whose last point was refused for lack
of flash step sets none: no dash, its latched J is J1 in place at its end. TENSHIN in has no other way in (decision V6a)."
  (let* ((f (fighter e)) (mv (fighter-move f)) (st (br e)))
    (when (and (eq (fighter-state f) :move) mv (eq (fighter-phase f) :main))
      (when (move-param e :lock) (br-planted-tick e))
      (let* ((sf (fighter-sf f)) (last (br-last-point mv)) (end (+ (mv-s mv) (mv-a mv) (mv-r mv)))
             (paid (brs-laid st))                                ; (decision V8b: L sets its point at f4 again)
             (open (and (br-dash-window-p sf last end) paid)))
        (when (zerop (fighter-lock f))
          (let ((b (br-tick-brain e)) (vp (pilot-vpad (pilot e))))
            (cond (b (when (and open (br-tenshin-ok-p e) (br-ai-cancel-p e b))
                       (when (br-tenshin-start e f) (pace e :ai-tenshin-cancel))))
                  (t (when (vpad-command-pressed-p vp :quick nil)       ; (any frame: latched, decision V6c)
                       (vpad-consume! vp :quick)
                       (unless (brs-dash-q st) (pace e (if (< sf last) :tenshin-latch :tenshin-press)))
                       (setf (brs-dash-q st) t))
                     (when (and open (brs-dash-q st) (br-tenshin-ok-p e))  ; (decision V9f: a trace to spend besides the one
                       (setf (brs-dash-q st) nil)                          ;  that fires, else J1 at the end, below)
                       (br-tenshin-start e f))
                     (when (and (>= sf end) (brs-dash-q st) (eq (fighter-move f) mv))   ; (no point set: J1 in place)
                       (setf (brs-dash-q st) nil)
                       (when (try-command e f :q) (pace e :tenshin-unpaid-j1)))))))
        (when (and (>= sf end) (eq (fighter-move f) mv))
          (setf (brs-late st) (if paid *br-dash-late* 0)))))))

(defun br-tenshin-start (e f)
  "Start TENSHIN in's 2 f cancel copy (a J in a lay's window) and pay its price, the farthest trace but the one its f0 fires,
unfired (BR-SPEND-FAR; decisions V8a, V9f). T when it started."
  (when (try-command e f :q nil nil (br-tenshin-cancel-move f))
    (br-spend-far e t)
    t))
(defun br-dash-ok-p (e) "May the backstep start: a live trace to spend (decision V8a)?" (plusp (br-live-traces e)))
(defun br-tenshin-ok-p (e)
  "May TENSHIN in start: a live trace to spend besides the one its f0 fires (BR-TENSHIN-PAY; decision V9f)?"
  (and (br-tenshin-pay (br-trace-cands e)) t))

;;; ---------------------------------------------------------------- the traces: aim points (decision V7)
(defun br-live-traces (e)
  "His live traces: values how many and the oldest one's entity (the smallest id), or NIL."
  (let ((n 0) (old nil) (oid 0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d))
          (incf n)
          (when (or (null old) (< (brh-id d) oid)) (setf old h oid (brh-id d))))))
    (values n old)))

(defun br-traces-aim (e)
  "Every live trace of E turned through his current position (BR-LINE-DIR: from its aim point through him; frozen within
*BR-AIM-FREEZE* m of it): its direction (BRH-UX / -UZ, the hit's) and the hazard's yaw (the looks', the CPUs')."
  (let* ((p (pos-of e)) (lx (aref p 0)) (lz (aref p 2)))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d))
          (multiple-value-bind (ux uz) (br-line-dir (hazard-x hz) (hazard-z hz) lx lz (brh-ux d) (brh-uz d))
            (unless (and (= ux (brh-ux d)) (= uz (brh-uz d)))
              (setf (brh-ux d) ux (brh-uz d) uz (hazard-yaw hz) (f32 (dir-yaw ux uz))))))))))

(defun br-lay-trace (e src yaw-off)
  "One aim point of SRC (:l :sp1 :sp2): *BR-AIM-BACK* m behind him along his facing + YAW-OFF degrees (BR-AIM-POINT), its
line through him (decision V7); a hazard with no hit (drawn by BR-TRACE-LOOK) until materialised; at most *BR-TRACE-MAX*
live (the oldest dropped)."
  (let* ((st (br e)) (p (pos-of e)) (r (if (eq src :sp2) *br-trace-r-thick* *br-trace-r*)) (yaw (f32 (+ (yaw-of e) (deg yaw-off)))))
    (multiple-value-bind (n old) (br-live-traces e)
      (when (>= n *br-trace-max*) (destroy-entity old) (pace e :traces-dropped)))
    (multiple-value-bind (px pz) (br-aim-point (aref p 0) (aref p 2) yaw)
      (spawn-hazard :br-trace e :x px :z pz :yaw yaw :size *br-trace-len*
                                :life 1000000 :hook 'br-hz :look 'br-trace-look
                                :data (make-brh :src src :id (incf (brs-trace-n st)) :live t :width (f32 r)
                                                :ux (f32 (fwd-x yaw)) :uz (f32 (fwd-z yaw))
                                                :vol (br-trace-vol src))))
    (pace e :traces)))

(defun br-lay (e)
  "A ranged lay's frame: he faces the opponent, pays the point (BR-LINE-COST; short of it, none) and sets it (SP1's by its
frame, *BR-SP1-FAN*). Laying deals nothing."
  (let* ((f (fighter e)) (g (gauges e)) (src (move-param e :trace)) (cost (br-line-cost src))
         (off (if (eq src :sp1) (or (second (assoc (fighter-sf f) *br-sp1-fan*)) 0.0) 0.0)))
    (turn-to-opp e f 10.0)
    (if (>= (gauges-fs g) cost)
        (progn (spend-fs g cost) (br-lay-trace e src off) (setf (brs-laid (br e)) t))
        (progn (pace e :traces-unpaid) (setf (brs-laid (br e)) nil)))
    (emit :sfx :rift-cut e)))

(defun br-materialise! (e hz d)
  "Trace D (hazard HZ) of E materialises: a 2-frame hit (BR-TRACE-HITWIN x his form's damage) along its line as it is now
(no snap: decision V7), then gone; its flash (the owl's: 裁きの光明's gold)."
  (let ((owl (br-owl-form-p (fighter-form (fighter e)))))
    (setf (brh-live d) nil
          (hazard-hw hz) (br-trace-hitwin (brh-src d) (kit-mult (kit-of e)))
          (hazard-hits-left hz) 1 (hazard-life hz) (+ (hazard-age hz) 3))
    (cond (owl (br-spawn-look-at e :judge (hazard-x hz) (hazard-z hz) (hazard-yaw hz) 31.0 (brh-width d)
                                 (if (eq (brh-src d) :sp2) :thick t)))
          (t (br-spawn-look-at e (if (eq (brh-src d) :sp2) :beam :shot) (hazard-x hz) (hazard-z hz) (hazard-yaw hz) 31.0
                               (if (eq (brh-src d) :sp2) 1.2 0.05) t)))))

(defun br-trace-dist (hz d x z) "The ground distance from (X Z) to trace D's (hazard HZ) line (BR-SEG-DIST)."
  (br-seg-dist (hazard-x hz) (hazard-z hz) (brh-ux d) (brh-uz d) x z))

(defun br-trace-cands (e)
  "The lines turned through him now (BR-TRACES-AIM), his live traces as BR-PICK's CANDS ((id dist), dist the line's ground
distance to the opponent); second value an alist id -> (entity . hazard)."
  (br-traces-aim e)
  (let ((q (pos-of (opp-of e))) (cands nil) (hs nil))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d))
          (push (list (brh-id d) (br-trace-dist hz d (aref q 0) (aref q 2))) cands)
          (push (list* (brh-id d) h hz) hs))))
    (values cands hs)))

(defun br-materialise-one (e)
  "One trigger (decision V6: every J at its first active frame, a K on its touch): the lines turned through him now
(BR-TRACES-AIM), the live trace whose line passes nearest the opponent within *BR-NEAR-R* (BR-PICK; a tie the newer)
materialises along it. T when one did."
  (multiple-value-bind (cands hs) (br-trace-cands e)
    (let ((id (br-pick cands)))
      (when id
        (let ((hz (cddr (assoc id hs))))
          (br-materialise! e hz (hazard-data hz))
          (pace e :materialised)
          (emit :sfx :lb-crack e)
          t)))))

(defun br-j-mat (e)
  "A melee J's first active frame: one trace materialises, hit or whiff (decision V6); not the J1 TENSHIN in links into
(BRS-DASH-J: decision V9g, the user 2026-10-10: 「前衝後的 J1 不射」; its dash's f0 fired one already, so a dash spends 2)."
  (let ((st (br e)))
    (cond ((brs-dash-j st)
           (pace e :dash-j1-no-mat)
           (when (and (brs-dash-next st) (null (br-tick-brain e)))   ; (decision V9h: the press kept during the dash, made
             (vpad-stamp! (pilot-vpad (pilot e)) (if (eq (brs-dash-next st) :q) :quick :flash))   ;  now: J2 / K2 buffered)
             (setf (brs-dash-next st) nil)
             (pace e :dash-next)))
          (t (br-materialise-one e)))))

(defun br-spend-far (e &optional tenshin)
  "A dash's price (decision V8a, the user 2026-10-10: 「覺醒後的 L>J / J > L 前後衝刺都需要消耗一條軌跡才能發動」, 「最遠那條，不射出」):
the lines turned through him now (BR-TRACES-AIM), the live trace whose line passes FARTHEST from the opponent (BR-PICK-FAR;
a tie the older) is removed without firing; TENSHIN in's (TENSHIN true) never the one its f0 fires (BR-TENSHIN-PAY, decision
V9f). T when one was."
  (multiple-value-bind (cands hs) (br-trace-cands e)
    (let ((id (if tenshin (br-tenshin-pay cands) (br-pick-far cands))))
      (when id
        (destroy-entity (cadr (assoc id hs)))
        (setf (brs-live (br e)) (max 0 (1- (brs-live (br e)))))
        (pace e :trace-spent)
        t))))

(defun br-clear-traces (e)
  "His live traces vanish (the revival, the recall). Values how many."
  (let ((gone nil))
    (do-entities (h (hz hazard)) (let ((d (hazard-data hz))) (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d)) (push h gone))))
    (dolist (h gone) (destroy-entity h))
    (length gone)))

(defun br-recall-go (e)
  "K3 -> L, f0: every live trace taken back and counted (§5.4)."
  (let ((n (br-clear-traces e)))
    (setf (brs-recall-n (br e)) n (brs-live (br e)) 0)
    (pace e :recall) (pace e (intern (format nil "RECALL-T~d" (br-recall-tier n)) :keyword))
    (emit :sfx :rift-open e)))

(defun br-recall-fire (e)
  "The recall's f7: the derivative string for its count (BR-RECALL-TIER), facing him."
  (let* ((f (fighter e)) (tier (br-recall-tier (brs-recall-n (br e)))))
    (turn-to-opp e f 10.0)
    (start-move e (kit-next (fighter-kit f) :br-recall (svref #(:rc0 :rc1 :rc2 :rc3 :rc4) tier)))))

(defun br-rc-tick (e) "The recall strings: he keeps on the opponent (*BR-RC-TRACK*)." (halt! e) (turn-to-opp e (fighter e) (track-step *br-rc-track*)))
(defun br-rc-shot (e) "A recall string's line: its look." (br-spawn-look e :shot *br-x-len* 0.05 t) (emit :sfx :lb-crack e))

(defun br-hz (h hz ev &optional a b c dd ee)
  "His hazards' hook: a trace's line from its aim point along BRH-UX / -UZ (only a materialised one has a hit), a 裁きの光明 ground line's burning span; the looks
touch nothing."
  (declare (ignore h))
  (let ((d (hazard-data hz)))
    (case ev
      (:touches
       (cond ((brh-p d)
              (vol-hit-p (brh-vol d) (hazard-x hz) 0f0 (hazard-z hz) (brh-ux d) (brh-uz d)   ; (its line through him: V7)
                         (f32 a) (f32 b) (f32 c) (f32 dd) (f32 ee) 0f0))
             ((and (eq (hazard-kind hz) :br-misuji))
              (multiple-value-bind (from to) (br-misuji-span (hazard-age hz))
                (and (> to from)
                     (let* ((yaw (hazard-yaw hz)) (mid (* 0.5 (+ from to))))
                       (obox-cyl-hit-p (f32 (+ (hazard-x hz) (* mid (fwd-x yaw)))) 1f0 (f32 (+ (hazard-z hz) (* mid (fwd-z yaw))))
                                       yaw (f32 (* 0.5 *br-misuji-width*)) 1.2f0 (f32 (* 0.5 (- to from)))
                                       a b c dd ee)))))))
      (t nil))))

;;; ---------------------------------------------------------------- the owl's melee SPs (the old KIN's, copied)
(defun br-misuji (e)
  "The chop's frame: a 裁きの光明 ground line per :fan angle (one hit group: one line at most hits him), each erupting from
1 m to 18 m (BR-MISUJI-SPAN), through guard (chip 15 %, the :guard drain), once."
  (let* ((p (pos-of e)) (fan (move-param e :fan)) (group (make-hit-group 1)))
    (dolist (a fan)
      (spawn-hazard :br-misuji e :x (aref p 0) :z (aref p 2) :yaw (+ (yaw-of e) (deg a)) :size *br-misuji-to*
                                 :life (br-misuji-frames) :group group :hook 'br-hz :look 'lb-look
                                 :data (make-lbh :kind :sabaki :len (f32 *br-misuji-to*) :width (f32 *br-misuji-width*))
                                 :hw (make-hitwin :dmg (move-param e :dmg) :react :stagger :kb 1.0 :hs *hitstop-heavy*
                                                  :chip 0.15 :guard (move-param e :guard)
                                                  :flags '(:ranged :x-axis :uncatchable))))
    (pace e :misuji)
    (emit :sfx :ground-crack e)))

(defun br-reflect-check (e st mv)
  "Trompete at the end of its f59: the opponent in a perfect Hoho started f48-f59, or in a guard pressed f50-f58 (facing
him, not a ward) reflects it."
  (let* ((o (opp-of e)) (fo (fighter o)) (go (gauges o)) (p (pos-of e)) (q (pos-of o))
         (src (cond ((and (eq (fighter-state fo) :hoho) (fighter-perfect fo) (br-reflect-hoho-p (- 59 (fighter-sf fo)))) :hoho)
                    ((and (eq (fighter-state fo) :guard) (not (passive-p o :ward)) (br-reflect-guard-p (fighter-guard-t fo))
                          (can-guard-p (gauges-gg go) (gauges-guardless go))
                          (in-front-p (yaw-of o) (aref q 0) (aref q 2) (aref p 0) (aref p 2) *guard-arc*))
                     :guard))))
    (when src (br-reflect! e o st mv src))))

(defun br-reflect! (e o st mv src)
  "The reflect: he takes *BR-REFLECT-K* of Trompete x his form's damage as a real hit, staggers *BR-REFLECT-STUN*; SP2 is
sealed in the owl's modes for the match. The reflector takes nothing."
  (let* ((dmg (round (* *br-reflect-k* (hw-dmg (svref (mv-hits mv) 0)) (kit-mult (kit-of e))))) (q (pos-of o)) (p (pos-of e)))
    (setf (brs-sealed st) t (fighter-perfect (fighter o)) nil)
    (callout o "REFLECT")
    (pace e (if (eq src :hoho) :reflect-hoho :reflect-guard))
    (hitstop *hitstop-breaker*)
    (emit :hit o e (aref p 0) (+ (aref p 1) 1.1) (aref p 2) *hitstop-breaker* nil dmg :sp)
    (unless (deal-damage o e dmg)
      (set-reaction e :stagger *br-reflect-stun* (aref q 0) (aref q 2) 1.0))
    (clog "~a TROMPETE REFLECTED by ~a (~a): ~d, sealed" (side-name e) (side-name o) src dmg)))

(defun br-reflect-test-step (e f)
  "Debug 82007 / 82008 (*BR-REFLECT-TEST*): the opponent's (CPU-off) brain presses guard on Trompete's f54, or Hoho on f52."
  (let* ((o (opp-of e)) (b (brain o)) (sf (fighter-sf f)))
    (when b
      (cond ((and (eq *br-reflect-test* :guard) (= sf 53)) (ai-press b :guard 200 :act :hold))
            ((and (eq *br-reflect-test* :hoho) (= sf 51)) (ai-press b :step 1 :modded t :act :hoho))))))

;;; ================================================================ AI (batch 4, 2026-10-09: DUEL_LILLE_V2 §8, §13; batch 6,
;;; 2026-10-10: §16, the pendulum and the aim points)
;;; His CPU: his kits' :ai keys (every chance a :p there, x *BR-AI-DIFF* by difficulty: EASY <= NORMAL <= HARD) and these
;;; reflexes (the kits' :reflex BR-AI-REFLEX, ai.lisp AI-REFLEX: free states, before the generic answers). Every roll is
;;; made once per event: a decision window (the base form's every *BR-AI-EVERY* f), a threat window (his move's start tick,
;;; a hazard's spawn), his action (the react roll), a point set or a line crossing (the fire roll), a ranged stay (its goal,
;;; its steering), a TENSHIN in (the route), a link's land frame (the enders), a stance (its plan and its Step at f6).
;;;   base      the stance at range (:zone: L, then its plan: the 萬物貫通 shot), the stance in close with a 狙擊 pip (:pip:
;;;             its plan the K / the snap shot; decision V9: the K at 3 pips first (:kamae :full); at 0 pips the stance Step
;;;             back as an escape inside :escape-in m (:kamae :escape; decision V9d: the 0-pip K is K1)); strings up close (the generic bands); L after a K link (:l-after-k, the
;;;             stance at f4, its plan the shot on the reeling opponent); the stance's Step once a stance (:kamae-step: his
;;;             attack coming, aside off a lane else back; him closing in with no pip, back; then the plan again)
;;;   ranged    a stay picks its goal (:lay :goal 2-4 points from :near m, the bank :bank-goal 6 under :bank-p, else 1) and
;;;             whether it steers (:steer); lays at him (L, SP1 the fan) below the goal over :reserve; goes in (TENSHIN in
;;;             out of a lay's window: an L pressed for it and its 2 f cancel, or the cancel of a lay of the goal's; J1 in
;;;             place within its reach; decision V6a: BR-AI-GO-IN) on a line on him at the dash's end with the goal set
;;;             (:fire, one roll per point set within :in m or crossing; up to :far-in m on a crossing: the long dash), on
;;;             his recovery (:busy), close, starved; points set and no line on him: the strafe walks a line onto him
;;;             (BR-AI-STEER), :patience frames then a new point
;;;   melee     TENSHIN in rolls the route (:route): the K links with :bank points (K3 -> L the recall), else the J links
;;;             (J3 -> L the backstep: the pendulum), latched on each hit; free, the opener in reach on his action's roll
;;;             (K1 with the bank, J1 with a line on him); K3 -> L the recall at :recall's count (n >= :n, >= :low-n under
;;;             :low of his Reishi, >= :off-n with no line on him), J3 -> L the backstep with fewer than :n traces and
;;;             :backstep :fs (BR-AI-SP-ENDER on the ender's hit)
;;;   MUJITTAI  U as a reaction to a threat (:stance :p, one roll per window: BR-AI-STANCE-IN, the old stance rule's shape);
;;;             out by attacking on his whiff, after :max frames, under :gg of the guard gauge, or him idle out of reach
;;;   HARD      *BR-AI-HARD* (0 / 0 / 1): a 萬物貫通 line on his recovery or into a guard gauge one line breaks (:hard)
;;;   the owl   the same rules; the revival (P) is the generic :bankai key with the JILLIEL kits' :bankai-ok
;;;   opponents a CPU facing his awakened forms steps off his lines, one roll per crossing or new line (BR-OPP-TRACE)
(defparameter *br-ai-diff* '(:easy 0.5 :normal 1.0 :hard 1.5)
  "His CPU's chances (his kits' :ai :p values) x this by difficulty, at most 1 (new 2026-10-09, batch 4: the old Lille's
*LB-AI-DIFF*).")
(defparameter *br-ai-hard* '(:easy 0.0 :normal 0.0 :hard 1.0)
  "His HARD layer's level by difficulty (BR-AI-HARD: the 萬物貫通 punish and guard crush, the kits' :hard): 0 at EASY and
NORMAL, 1 at HARD (EASY <= NORMAL <= HARD; new 2026-10-10, batch 6, DUEL_LILLE_V2 §16).")
(defparameter *br-ai-every* 30
  "Frames between two of the base form's stance decisions (:zone / :pip, one roll each; new 2026-10-09, batch 4).")

;; pure: host-tested (tests/duel-rules-test.lisp)
(defun br-ai-chance (p difficulty) "A chance P of his kit's :ai at DIFFICULTY: x *BR-AI-DIFF*, at most 1." (min 1.0 (* p (getf *br-ai-diff* difficulty 1.0))))
(defun br-ai-base-plan (r d snipe threat zone pip difficulty &optional close)
  "The base form's stance decision from one roll R (§8): with a 狙擊 pip (SNIPE >= 1) and him inside PIP's :near m, PIP's
:p: :PIP (the stance; its plan TAISHA / the snap); no pip and him inside CLOSE's :near m, CLOSE's :p: :CLOSE (the stance; its
plan the close snipe, +2: decision V8); from ZONE's :near m, ZONE's :p: :ZONE (the stance; its plan the shot); none while
THREAT (his attack coming: the generic answers it) or without the keys."
  (cond (threat nil)
        ((and pip (>= snipe 1) (< d (getf pip :near 4.0)) (< r (br-ai-chance (getf pip :p 0.0) difficulty))) :pip)
        ((and close (< snipe 1) (< d (getf close :near 3.0)) (< r (br-ai-chance (getf close :p 0.0) difficulty))) :close)
        ((and zone (>= d (getf zone :near 6.0)) (< r (br-ai-chance (getf zone :p 0.0) difficulty))) :zone)))
(defun br-ai-recall-p (n reishi-frac k &optional (on 1))
  "Does his CPU recall (K3 -> L) with N traces live at REISHI-FRAC of his Reishi (K: the kit's :recall): N >= :n, or N >=
:low-n under :low (§8: 「n >= 3 (or n >= 1 at low HP)」), or N >= :off-n with none of them ON him (batch 6: lines that would
miss, taken back)?"
  (and k (or (>= n (getf k :n 3)) (and (>= n (getf k :low-n 1)) (< reishi-frac (getf k :low 0.35)))
             (and (getf k :off-n) (>= n (getf k :off-n)) (zerop on)))
       t))
(defun br-ai-backstep-p (n k)
  "Does his CPU back off (J3 -> L) with N traces live (K: the kit's :backstep): at least :min (decision V8a: the backstep spends
one, and TENSHIN in back needs another: :min 2 keeps one for it; no flash step since)?"
  (and k (>= n (getf k :min 1)) t))
(defun br-ai-lay-plan (fs bars d near r k)
  "His ranged CPU's lay (K: the kit's :lay) at D metres with FS flash step and BARS Reiatsu bars, NEAR traces near him: from
:far m while fewer than :n of :fire lie near (passed as NEAR's cap by the caller), the price leaving >= :reserve: SP1's fan
(:SP1) on one roll R under :sp1 with a bar, else L (:SIG); NIL. (Decision V8b: L lays from range again, as before V8.)"
  (when (and k (>= d (getf k :far 4.0)) (< near (getf k :cap 99)))
    (let ((res (getf k :reserve 15.0)))
      (cond ((and (>= bars 1) (>= (- fs *br-lay-sp1*) res) (< r (getf k :sp1 0.0))) :sp1)
            ((>= (- fs *br-lay-l*) res) :sig)))))
(defun br-ai-stance-plan (r p line)
  "An awakened form's answer to one threatening window, from its one roll R: :STANCE (R < P: U, MUJITTAI), else :STEP off a
LINE, else :PASS (a Hoho on the generic roll, or nothing)."
  (cond ((< r p) :stance) (line :step) (t :pass)))
(defun br-stance-exit (busy frames max gg gg-min idle-far)
  "Why his CPU leaves MUJITTAI now (by attacking), or NIL: :WHIFF (he is BUSY), :MAX (FRAMES in it >= MAX), :GAUGE (the
guard gauge GG under GG-MIN), :IDLE (he is out of reach and idle: IDLE-FAR)."
  (cond (busy :whiff) ((>= frames max) :max) ((< gg gg-min) :gauge) (idle-far :idle)))

;; batch 6 (2026-10-10, DUEL_LILLE_V2 §16): the pendulum and the aim points
(defun br-ai-kamae-step-plan (r threat line close reeling snipe dashed fs k difficulty)
  "The stance's Step for his CPU from one roll R (K: the stance's :kamae-step): none once used in this stance (DASHED), short
of its flash step (FS), or on a REELING opponent (the plan cashes him); his attack coming (THREAT): :threat x the
difficulty, :SIDE off a LINE (a lane, an :x-axis line), else :BACK; him CLOSE with no pip (SNIPE 0: no TAISHA / snap to
answer): :p x the difficulty, :BACK. NIL."
  (cond ((or (null k) dashed (< fs *br-kamae-dash-fs*) reeling) nil)
        (threat (and (< r (br-ai-chance (getf k :threat 0.0) difficulty)) (if line :side :back)))
        ((and close (< snipe 1)) (and (< r (br-ai-chance (getf k :p 0.0) difficulty)) :back))))
(defun br-ai-step-stick (dir)
  "His CPU's stance Step as a stick (values toward strafe): DIR 0 straight back, +1 / -1 back and aside (60 deg off back)."
  (if (zerop dir) (values -1.0 0.0) (values -0.5 (* 0.866 (signum dir)))))
(defun br-ai-goal (r d k difficulty &optional safe)
  "The aim points his ranged CPU sets before going in, picked once a ranged stay from one roll R at D metres (K: the kit's
:lay): from :near m, SAFE (his Reishi at least :safe of its max), the big bank (:big-goal 10, the recall's 480: decision V8)
under :big-p x the difficulty; else the bank (:bank-goal points, for the K route and the recall) under :bank-p x the
difficulty (on the roll's rest), else one of :goal (lo hi), evenly over the rest; closer :close-goal (1)."
  (if (>= d (getf k :near 6.0))
      (let* ((bp (if safe (br-ai-chance (getf k :big-p 0.0) difficulty) 0.0))
             (r (if (< r bp) -1.0 (/ (- r bp) (max 1e-6 (- 1.0 bp)))))
             (q (br-ai-chance (getf k :bank-p 0.0) difficulty)))
        (cond ((< r 0.0) (getf k :big-goal 10))
              ((< r q) (getf k :bank-goal 6))
              (t (destructuring-bind (lo hi) (getf k :goal '(2 4))
                   (min hi (+ lo (floor (* (/ (- r q) (max 1e-6 (- 1.0 q))) (1+ (- hi lo))))))))))
      (getf k :close-goal 1)))
(defun br-dash-line-gap (px pz ux uz lx lz ox oz)
  "The ground distance from him at (OX OZ) to a trace's line (its aim point (PX PZ), its direction (UX UZ) now) once TENSHIN
in's dash (BR-TENSHIN-DIST) carried Lille from (LX LZ) at him: the line from the point through Lille's spot at the dash's
end (BR-LINE-DIR), point-to-segment (BR-SEG-DIST). What his J1 at the dash's end materialises along (decision V7: the dash
keeps a line on him that ran through him from a point behind Lille)."
  (let* ((dx (- ox lx)) (dz (- oz lz)) (d (sqrt (+ (* dx dx) (* dz dz)))) (s (br-tenshin-dist d))
         (ex (if (> d 1e-3) (+ lx (* s (/ dx d))) lx)) (ez (if (> d 1e-3) (+ lz (* s (/ dz d))) lz)))
    (multiple-value-bind (vx vz) (br-line-dir px pz ex ez ux uz)
      (br-seg-dist px pz vx vz ox oz))))
(defun br-steer (px pz lx lz ox oz)
  "Steering a line onto him (batch 6): Lille at (LX LZ) puts the trace whose aim point is (PX PZ) through him at (OX OZ)
by standing on the ray from the point through him. Values Lille's distance off that line and the strafe (+1 / -1, the CPU
stick's x relative to him, TOWARD-STRAFE-DIR) that closes it."
  (let* ((vx (- ox px)) (vz (- oz pz)) (vm (max 1e-4 (sqrt (+ (* vx vx) (* vz vz))))) (vx (/ vx vm)) (vz (/ vz vm))
         (wx (- lx px)) (wz (- lz pz)) (along (+ (* wx vx) (* wz vz)))
         (ex (- wx (* along vx))) (ez (- wz (* along vz)))           ; Lille's offset off the line
         (ux (- ox lx)) (uz (- oz lz)) (um (max 1e-4 (sqrt (+ (* ux ux) (* uz uz))))) (ux (/ ux um)) (uz (/ uz um)))
    (values (sqrt (+ (* ex ex) (* ez ez)))
            (if (>= (- (+ (* ex (- uz)) (* ez ux))) 0) 1.0 -1.0))))   ; (the strafe direction (-uz, ux), against the offset)
(defun br-ai-in-why (near live goal d starved busy k)
  "Why his ranged CPU goes in (TENSHIN in out of a lay's window, or J1 in place within its reach: BR-AI-GO-IN, decision V6a)
now, or NIL (K: the kit's :fire), D metres from him (perceived): within :in
m (the dash's 7 m + its 1 m stop: J1 reaches) :BUSY (he is perceived recovering / reeling for the dash and J1), :CLOSE
(inside :close m), :LINE (NEAR >= :n lines on him at the dash's end and LIVE >= GOAL points set), :STARVED (no lay above the
reserve); beyond it up to :far-in m only :LINE (the long dash: J1 whiffs short of him, the line it spends does not)."
  (when k
    (cond ((> d (getf k :far-in (getf k :in 8.0))) nil)
          ((> d (getf k :in 8.0)) (and (>= near (getf k :n 1)) (>= live goal) :line))
          (busy :busy)
          ((< d (getf k :close 3.0)) :close)
          ((and (>= near (getf k :n 1)) (>= live goal)) :line)
          (starved :starved))))
(defun br-ai-in-cmd (d reach q-ok sig-ok)
  "How his ranged CPU goes in from neutral D metres from him (decision V6a, 2026-10-10: TENSHIN in only out of a lay's
window): within J1's REACH + 0.2 m :Q (J1 in place, Q-OK); else :SIG (an L whose window his CPU cancels into TENSHIN in,
SIG-OK: its flash step there; the L's own point always pays the dash, decisions V8a / V8b); else NIL (walk in)."
  (cond ((and q-ok (<= d (+ reach 0.2))) :q)
        ((and sig-ok (> d (+ reach 0.2))) :sig)))
(defun br-ai-route (r live k difficulty)
  "His CPU's melee route as it goes in (TENSHIN in, a melee opener), one roll R (K: the melee kit's :route): :p x the
difficulty: :K (the K links, then K3 -> L the recall) with LIVE >= :bank points set, else :J (the J links, then J3 -> L the
backstep: the pendulum); else NIL (the generic strings)."
  (and k (< r (br-ai-chance (getf k :p 0.0) difficulty)) (if (>= live (getf k :bank 6)) :k :j)))

;; the shell
(defstruct (brai (:conc-name brai-))
  (e nil) (b nil)                         ; the fighter and the brain it belongs to (a new match: a fresh one)
  (key -1 :type fixnum)                   ; MUJITTAI: the threatening window rolled for (his move's start; a hazard's -2 - spawn)
  (plan nil)                              ; ... its answer: :stance :step :pass :done
  (exit -1 :type fixnum)                  ; the MUJITTAI whose exit was counted (its start tick)
  (base-t 0 :type fixnum)                 ; the base form's next stance decision tick
  (lay-t 0 :type fixnum)                  ; the ranged form's next lay tick
  (seen-n 0 :type fixnum) (fire-go nil)   ; the points set at the last look (a new one: an event) and the fire roll's answer
  ;; batch 6 (§16): the ranged stay's plan, the line crossings, the melee route
  (ranged nil)                            ; he was in a ranged mode at his last ranged decision (a new stay: a new goal)
  (goal 1 :type fixnum)                   ; the points to set this stay before going in on a line (BR-AI-GOAL, one roll)
  (on nil)                                ; a line was on him (now: BR-NEAR-COUNT) at the last look
  (cross 0 :type fixnum)                  ; ... the times one came onto him (a crossing: a new fire roll)
  (steer nil)                             ; ... he steers the lines onto him this stay (one roll)
  (steer-t -1 :type fixnum)               ; the tick the steering began (no line on him): BR-AI-LAY's patience
  (route nil)                             ; the melee route he goes in with: :j / :k / NIL (BR-AI-ROUTE)
  (dash-t -999 :type fixnum)              ; the tick he pressed a lay to go in by (decision V6a: lay, then its 2 f cancel)
  (hard-plan nil))                        ; the base form's HARD stance: :punish / :crush (its plan the shot / the snap)
(defvar *br-ai* (vector (make-brai) (make-brai)) "Per side: his CPU's state.")
(defun br-ai-state (e b)
  (let* ((i (fighter-side (fighter e))) (st (svref *br-ai* i)))
    (if (and (eql (brai-e st) e) (eq (brai-b st) b)) st (setf (svref *br-ai* i) (make-brai :e e :b b)))))

(defparameter *br-ai-on* 0.5
  "The CPUs' 'on a trace's line': within its radius + this many metres of it (BR-ON-LINE-P: his CPU's going in and laying,
the opponents' Step off it, the learner's :trace) (batch 5, 2026-10-10 [G]: the lines turn through him, decision V7).")
(defun br-on-line-p (hz d x z) "Is (X Z) on trace D's (hazard HZ) line: within its radius + *BR-AI-ON* (the CPUs' reading)?"
  (<= (br-trace-dist hz d x z) (+ (brh-width d) *br-ai-on*)))
(defun br-near-count (e x z)
  "How many of E's live traces have (X Z) on their line (BR-ON-LINE-P): what a J's materialise would hit there."
  (let ((n 0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d) (br-on-line-p hz d x z))
          (incf n))))
    n))
(defun br-end-count (e x z)
  "How many of E's live traces would have (X Z) on their line once TENSHIN in's dash carried him at it (BR-DASH-LINE-GAP
within the radius + *BR-AI-ON*): what the J1 at the dash's end would hit there (batch 6)."
  (let ((n 0) (p (pos-of e)))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d)
                   (<= (br-dash-line-gap (hazard-x hz) (hazard-z hz) (brh-ux d) (brh-uz d) (aref p 0) (aref p 2) x z)
                       (+ (brh-width d) *br-ai-on*)))
          (incf n))))
    n))
(defun br-steer-target (e x z)
  "The live trace of E's whose ray from its aim point through (X Z) (him) passes nearest Lille (BR-STEER), the point
beyond him excluded (Lille would have to pass him): values Lille's distance off it and the strafe that closes it, or NIL."
  (let ((p (pos-of e)) (best nil) (bs 0.0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d)
                   (> (+ (* (- x (hazard-x hz)) (- (aref p 0) (hazard-x hz))) (* (- z (hazard-z hz)) (- (aref p 2) (hazard-z hz)))) 0))
          (multiple-value-bind (gap s) (br-steer (hazard-x hz) (hazard-z hz) (aref p 0) (aref p 2) x z)
            (when (or (null best) (< gap best)) (setf best gap bs s))))))
    (and best (values best bs))))

(defun br-ai-threat-p (e s d margin)
  "Is his perceived move S a threat: an attack in its main phase with hit frames, still to hit and within its reach + MARGIN
(an :x-axis line: E on it), not a parry, a bind's tell or a :reflectable blast?"
  (and (eq (snap-state s) :move) (eq (snap-phase s) :main)
       (member (snap-kind s) '(:quick :flash :sig :sp :breaker :kikon))
       (> (snap-active-end s) (snap-s s))
       (snap-live-p s) (snap-near-p s e d margin)
       (not (intersection '(:parry :bind :reflectable) (snap-flags s)))))

(defun br-ai-line-p (s)
  "Is his perceived move a lane: an :x-axis line or a Kikon module's lane? A Step clears it."
  (or (snap-x-axis-p s) (and (snap-move s) (eq (getf (mv-params (snap-move s)) :look) :lane))))

(defun br-ai-side-step (e b s)
  "A sideways Step off his perceived line (LINE-OFF-STRAFE; anything else: the current strafe)."
  (when (br-ai-line-p s)
    (let ((p (pos-of e)))
      (setf (brain-strafe b) (f32 (line-off-strafe (snap-x s) (snap-z s) (snap-yaw s) (aref p 0) (aref p 2) (snap-x s) (snap-z s))))))
  :side-step)

(defun br-ai-hazard-key (e lead)
  "One of his opponent's hazards about to hit E within LEAD frames (a wave / fireball flying at him, or a delayed one under
him whose delay is at most LEAD): its key (-2 - its spawn tick), or NIL."
  (let* ((o (opp-of e)) (q (pos-of e)) (bd (model-body (model e))) (key nil))
    (do-entities (h (hz hazard))
      (when (and (null key) (eql (hazard-owner hz) o) (hazard-hw hz) (> (hazard-hits-left hz) 0)
                 (if (and (member (hazard-kind hz) '(:wave :fireball)) (<= (hazard-delay hz) 0) (> (hazard-speed hz) 0.1))
                     (let ((dist (sqrt (+ (expt (- (aref q 0) (hazard-x hz)) 2) (expt (- (aref q 2) (hazard-z hz)) 2)))))
                       (<= (/ (* 60 (max 0.0 (- dist 1.0))) (hazard-speed hz)) lead))
                     (and (< 0 (hazard-delay hz) (1+ lead))
                          (hazard-touches-p hz (aref q 0) (aref q 1) (aref q 2) (body-hurt-r bd) (body-hurt-h bd)))))
        (setf key (- -2 (- *match-tick* (hazard-age hz))))))
    key))

(defun br-ai-busy-p (s delay frames)
  "Is he, as perceived, recovering or reeling, with at least FRAMES of it left after DELAY? (FRAMES 0: just busy.)"
  (and (< (snap-left s) 99) (snap-punishable-p s) (>= (- (snap-left s) delay) frames)))

(defun br-ai-stance-in (e b s d)
  "An awakened mode (§8, the old Lille's stance rule): a move of his starting within its reach + 1 m (an :x-axis line: E on
it), not a Breaker / grab, or a hazard of his within 12 f: one roll per window, :stance :p x the difficulty (0 under :gg of
the guard gauge): U (MUJITTAI, the kit's :guard-to). Else a sideways Step off a lane, or a Hoho on the generic Hoho roll
(his move >= 6 f out), else the generic answers (its guard is U: MUJITTAI as well)."
  (let* ((solid (not (or (eq (snap-kind s) :breaker) (member :grab (snap-flags s)))))
         (mv-threat (and solid (br-ai-threat-p e s d 1.0)))
         (key (if mv-threat (snap-start s) (br-ai-hazard-key e 12))))
    (if (null key)
        (and solid (br-ai-threat-p e s d *ai-threat-margin*) (why b :stance-out-of-reach :none))
        (let ((ai (br-ai-state e b)) (k (ai-table e :stance)) (g (gauges e)))
          (when (/= key (brai-key ai))
            (setf (brai-key ai) key
                  (brai-plan ai) (br-ai-stance-plan (sim-rnd01)
                                                    (if (or (gauges-guardless g) (< (gauges-gg g) (getf k :gg 30))) 0.0
                                                        (br-ai-chance (getf k :p 0.0) (brain-difficulty b)))
                                                    (and mv-threat (br-ai-line-p s))))
            (pace e (case (brai-plan ai) (:stance :ai-stance) (:step :ai-step) (t :ai-pass))))
          (case (brai-plan ai)
            (:stance (setf (brai-plan ai) :done) (ai-press b :guard 4 :act :hold) (why b :stance :none))
            (:step (setf (brai-plan ai) :done) (why b :stance-step (br-ai-side-step e b s)))
            (:pass (setf (brai-plan ai) :done)
                   (if (and mv-threat (>= (- (snap-s s) (snap-sf s)) 6) (hoho-ready-p e)
                            (ai-hoho-spare-p (gauges-fs g) (gauges-reishi g) (gauges-reishi-max g))
                            (< (brain-hoho-roll b) (ai-table e :hoho 0.2)))
                       (why b :stance-hoho :hoho)
                       nil))                              ; (the generic answers: a guard is U, MUJITTAI too)
            (t nil))))))

(defun br-ai-opp-reach (e)
  "His longest J / K reach (his current kit): what 'in reach' means for MUJITTAI's idle rule."
  (let ((kit (kit-of (opp-of e))))
    (loop for c in '(:q :f) for mv = (kit-command-move kit c) maximize (if mv (mv-reach mv) 0.0))))

(defun br-ai-exit-cmd (e b s d)
  "The attack that ends MUJITTAI: K1 when he stays busy for its startup within its reach, J1 within its, the traces near him
J (:fire; a K fires none since decision V8), else L (ranged: a lay; melee: the turn to ranged) when it may start, else K1."
  (let* ((kit (kit-of e)) (q (kit-command-move kit :q)) (fm (kit-command-move kit :f)))
    (cond ((and fm (<= d (+ (mv-reach fm) 0.2)) (br-ai-busy-p s (brain-delay b) (mv-s fm)) (kit-command-ok-p e :f)) :f)
          ((and q (<= d (+ (mv-reach q) 0.2)) (kit-command-ok-p e :q)) :q)
          ((and fm (<= d (+ (mv-reach fm) 0.2)) (kit-command-ok-p e :f)) :f)
          ((and (>= (br-near-count e (snap-x s) (snap-z s)) (getf (ai-table e :fire) :n 1)) (kit-command-ok-p e :q)) :q)   ; (V8: J fires)
          ((kit-command-ok-p e :sig) :sig)
          ((kit-command-ok-p e :f) :f))))

(defun br-ai-stance-out (e b s d)
  "MUJITTAI (§8): he leaves it only by attacking: on his whiff or recovery (as perceived), after :max frames in it, under :gg
of the guard gauge, or with him out of reach (+ 1 m) and idle; the whiff and idle rules wait while a hazard of his is
coming. Deterministic on what it sees, no roll."
  (let* ((k (ai-table e :stance)) (st (br e)) (calm (not (br-ai-hazard-key e 12))) (read (br-learn-mujittai b))
         (why (br-stance-exit (and calm (br-ai-busy-p s (brain-delay b) 0)) (brs-stance st)
                              (if (eq read :stay) 9999 (getf k :max 120))   ; (a learner's read: §13)
                              (gauges-gg (gauges e)) (getf k :gg 30)
                              (and calm (not (eq read :stay))
                                   (or (eq read :leave)
                                       (and (member (snap-state s) '(:idle :guard)) (> d (+ (br-ai-opp-reach e) 1.0))))))))
    (when why
      (let ((cmd (br-ai-exit-cmd e b s d)) (ai (br-ai-state e b)) (t0 (- *match-tick* (brs-stance st))))
        (when cmd
          (when (/= (brai-exit ai) t0)
            (setf (brai-exit ai) t0)
            (pace e (case why (:whiff :ai-exit-whiff) (:max :ai-exit-max) (:gauge :ai-exit-gauge) (t :ai-exit-idle))))
          (why b :br-stance-exit cmd))))))

(defun br-ai-hard-why (busy-left guarding gg d level r k)
  "His HARD layer's 萬物貫通 (batch 6, *BR-AI-HARD*; K: the kit's :hard), from his action's react roll R under LEVEL: :PUNISH
him perceived busy with BUSY-LEFT >= :punish-f frames left (the line's startup from neutral and the delay), :CRUSH him
guarding (GUARDING) with GG <= :crush of his guard gauge (one 萬物貫通 block breaks it: *BR-X-GUARD*), from :near m; NIL."
  (when (and k (< r level) (>= d (getf k :near 2.0)))
    (cond ((>= busy-left (getf k :punish-f 99)) :punish)
          ((and guarding (<= gg (getf k :crush 0.0))) :crush))))

(defun br-ai-hard (e b s d)
  "His HARD layer (batch 6, BR-AI-HARD-WHY on the form's :hard): the base form presses L (the stance, its plan the shot, the
snap with a pip: BRAI-HARD-PLAN), ranged goes in (BR-AI-GO-IN: J1 in place, else a lay and TENSHIN in: J1's line, 萬物貫通;
decision V6a), melee J with a line on him. A command or NIL."
  (let ((k (ai-table e :hard)))
    (when k
      (let* ((form (fighter-form (fighter e))) (o (opp-of e))
             (why (br-ai-hard-why (if (br-ai-busy-p s (brain-delay b) 0) (- (snap-left s) (brain-delay b)) 0)
                                  (and (member (snap-state s) '(:guard :guard-hit)) t) (gauges-gg (gauges o)) d
                                  (getf *br-ai-hard* (brain-difficulty b) 0.0) (brain-react-roll b) k)))
        (when why
          (cond ((and (eq form :base) (kit-command-ok-p e :sig))
                 (setf (brai-hard-plan (br-ai-state e b)) why) (pace e (if (eq why :punish) :ai-hard-punish :ai-hard-crush))
                 (why b why :sig))
                ((and (br-ranged-form-p form) (plusp (br-end-count e (snap-x s) (snap-z s))) (<= d (getf (ai-table e :fire) :in 8.0)))
                 (let ((c (br-ai-go-in e b d)))   ; (J1 in place, else a lay and its TENSHIN in: decision V6a)
                   (when c (pace e (if (eq why :punish) :ai-hard-punish :ai-hard-crush)) (why b why c))))
                ((and (br-melee-form-p form) (plusp (br-near-count e (snap-x s) (snap-z s)))
                      (<= d (+ (mv-reach (kit-command-move (kit-of e) :q)) 0.2)) (kit-command-ok-p e :q))
                 (pace e (if (eq why :punish) :ai-hard-punish :ai-hard-crush)) (why b why :q))))))))

(defun br-ai-take-hard-plan (e b)
  "The HARD layer's stance plan (BR-AI-HARD: :punish / :crush), taken once by the stance's plan (BR-AI-KAMAE), or NIL."
  (let ((ai (br-ai-state e b))) (prog1 (brai-hard-plan ai) (setf (brai-hard-plan ai) nil))))

(defun br-ai-base (e b s d)
  "The base form (§8): every *BR-AI-EVERY* f one roll (BR-AI-BASE-PLAN): the stance with a pip close (its plan TAISHA / the
snap), at range (its plan the shot); L pressed (the stance), or NIL."
  (let ((ai (br-ai-state e b)))
    (when (and (>= *match-tick* (brai-base-t ai)) (kit-command-ok-p e :sig))
      (setf (brai-base-t ai) (+ *match-tick* *br-ai-every*))
      (let ((plan (br-ai-base-plan (sim-rnd01) d (brs-snipe (br e)) (br-ai-threat-p e s d *ai-threat-margin*)
                                   (ai-table e :zone) (ai-table e :pip) (brain-difficulty b) (ai-table e :close))))
        (when plan
          (pace e (case plan (:pip :ai-pip) (:close :ai-close) (t :ai-zone)))
          (why b plan :sig))))))

(defun br-ai-starved-p (e)
  "Can his CPU no longer lay an L above its :lay :reserve (then he goes in: an L into the reserve and its TENSHIN in, free
past the lay; decision V6a; L lays from range again since decision V8b)?"
  (let ((k (ai-table e :lay))) (and k (< (- (gauges-fs (gauges e)) *br-lay-l*) (getf k :reserve 10.0)))))

(defun br-ai-stay (e b d)
  "His ranged CPU's stay (batch 6): coming into a ranged mode (the turn, the backstep, MUJITTAI's drop, the revival) picks
the points to set before going in on a line (BR-AI-GOAL, one roll) and whether he steers the lines this stay (:steer :p x
the difficulty, one roll); the melee forms end the stay (BR-AI-ROUTE-RESET). Its state (BRAI)."
  (let ((ai (br-ai-state e b)) (k (ai-table e :lay)) (ks (ai-table e :steer)))
    (unless (brai-ranged ai)
      (setf (brai-ranged ai) t (brai-goal ai) (if k (br-ai-goal (sim-rnd01) d k (brain-difficulty b)
                                                                (>= (reishi-frac (gauges e)) (getf k :safe 0.5)))
                                                    1)
            (brai-steer-t ai) -1
            (brai-steer ai) (and ks (< (sim-rnd01) (br-ai-chance (getf ks :p 0.0) (brain-difficulty b))) t))
      (pace e (case (brai-goal ai) (1 :ai-goal-1) (2 :ai-goal-2) (3 :ai-goal-3) (4 :ai-goal-4) (10 :ai-goal-big) (t :ai-goal-bank))))
    ai))

(defun br-ai-in-p (e b s d)
  "Ranged (batch 6): go in now (TENSHIN in out of a lay's window, J1 in place within reach: BR-AI-GO-IN, decision V6a)?
BR-AI-IN-WHY at his perceived spot S, D metres: a line on him at the
dash's end (BR-END-COUNT) with the stay's points set: one roll per event (:fire :p x the difficulty; a no waits for the
next): a crossing (a line swung onto him now, BR-NEAR-COUNT, by his walk with no point set: BR-AI-STEER), or a point set
within :in m in a stay that does not steer; beyond :in m (the long dash), or in a steering stay, a point set waits for the
crossing. Him perceived busy for :busy-f frames (the dash and J1): his action's react roll under :busy x the difficulty;
close, starved: the react roll under :p."
  (let ((k (ai-table e :fire)))
    (when (and k s (not (br-learn-hold-p e b s)))   ; (a learner's Hoho read holds it: §13)
      (let* ((ai (br-ai-stay e b d)) (st (br e)) (diff (brain-difficulty b))
             (near (br-end-count e (snap-x s) (snap-z s)))
             (why (br-ai-in-why near (brs-live st) (brai-goal ai) d (br-ai-starved-p e)
                                (br-ai-busy-p s (brain-delay b) (getf k :busy-f 30)) k)))
        (let* ((now (plusp (br-near-count e (snap-x s) (snap-z s))))        ; (a line on him now)
               (new (/= (brs-trace-n st) (brai-seen-n ai)))               ; (a point set since the last look)
               (cross (and now (not (brai-on ai)) (not new))))              ; (a line walked onto him: a crossing)
          (when cross (incf (brai-cross ai)) (pace e :ai-cross))
          (when (or new cross)                                                ; (one roll per event, :line only)
            (setf (brai-fire-go ai) (and (eq why :line) (or cross (and (not (brai-steer ai)) (<= d (getf k :in 8.0))))
                                         (< (sim-rnd01) (br-ai-chance (getf k :p 0.0) diff)))))
          (setf (brai-on ai) now (brai-seen-n ai) (brs-trace-n st)))
        (case why
          (:line (brai-fire-go ai))
          (:busy (< (brain-react-roll b) (br-ai-chance (getf k :busy 0.0) diff)))
          ((:close :starved) (< (brain-react-roll b) (br-ai-chance (getf k :p 0.0) diff))))))))

(defparameter *br-ai-dash-life* 20
  "Frames a lay his ranged CPU pressed to go in by (BR-AI-GO-IN) keeps its planned cancel: the lay's window opens within
them (L: f4 after the press's step, its point's frame since decision V6c; f7 before), and a lay cut short leaves no plan
for a later one (decision V6a, 2026-10-10 [G]).")
(defun br-ai-go-in (e b d)
  "Going in from ranged neutral (decision V6a, 2026-10-10: TENSHIN in only out of a lay's window): him within J1's reach
(+ 0.2 m): J, J1 in place; else L, an aim point at him whose window cancels into TENSHIN in (BRAI-DASH-T, taken by
BR-AI-CANCEL-P; the new line runs from behind Lille through him, so J1 at the dash's end spends it); short of the lay's
flash step: NIL (the neutral walk goes in). :Q, :SIG or NIL."
  (let* ((q (kit-command-move (kit-of e) :q))
         (c (br-ai-in-cmd d (if q (mv-reach q) 0.0) (and q (kit-command-ok-p e :q)) (kit-command-ok-p e :sig))))
    (case c
      (:q (pace e :ai-in-j1))
      (:sig (setf (brai-dash-t (br-ai-state e b)) *match-tick*) (pace e :ai-lay-dash)))
    c))

(defun br-ai-take-dash (e b)
  "A lay's window (BR-LAY-TICK): did his CPU press this lay to go in by (BR-AI-GO-IN, within *BR-AI-DASH-LIFE* frames)? Taken
once (the points set so far count as seen: BR-AI-IN-P's next look is no new event)."
  (let ((ai (br-ai-state e b)))
    (when (<= (- *match-tick* (brai-dash-t ai)) *br-ai-dash-life*)
      (setf (brai-dash-t ai) -999 (brai-seen-n ai) (brs-trace-n (br e)))
      t)))

(defun br-ai-fire (e b s d)
  "Ranged (§8, batch 6; decision V6a): going in when BR-AI-IN-P says so: J1 in place within its reach, else a lay and its
2 f cancel into TENSHIN in (BR-AI-GO-IN). :Q, :SIG, or NIL."
  (when (br-ai-in-p e b s d)
    (let ((c (br-ai-go-in e b d)))
      (when c (pace e (if (> d (getf (ai-table e :fire) :in 8.0)) :ai-in-far :ai-in)) (why b :br-in c)))))

(defun br-ai-seen (b)
  "The SNAP brain B perceives this step (BRAIN-PERCEIVE's ring at the delay; NIL before it holds one): for his ticks, which
run inside moves where the reflexes don't (the old LB-AI-SEEN)."
  (let* ((ring (brain-ring b)) (n (length ring)))
    (and (plusp n) (svref ring (mod (- (brain-head b) 1 (brain-delay b)) n)))))

(defun br-ai-cancel-p (e b)
  "A ranged lay's window (BR-LAY-TICK, BR-DASH-WINDOW-P): his CPU cancels it into TENSHIN in (2 f) when he pressed the lay to
go in by (BR-AI-TAKE-DASH), or when he would go in now (BR-AI-IN-P)."
  (let ((s (br-ai-seen b)))
    (or (br-ai-take-dash e b)
        (and s (br-ai-in-p e b s (fighter-dist (fighter e)))))))

(defun br-ai-lay (e b s d)
  "The ranged form (§8, batch 6): a lay at him every :lay :every f (BR-AI-LAY-PLAN: SP1's fan on one roll per lay, else L)
while fewer than the stay's goal of points are set, or the steering ran out of :patience frames with no line on him; the
flash step staying over :reserve. L / SP1, or NIL."
  (declare (ignore s))
  (let ((k (ai-table e :lay)) (ai (br-ai-stay e b d)))
    (when (and k (>= *match-tick* (brai-lay-t ai)))
      (let* ((g (gauges e)) (live (brs-live (br e)))
             (bored (and (>= (brai-steer-t ai) 0) (> (- *match-tick* (brai-steer-t ai)) (getf k :patience 90))))
             (plan (br-ai-lay-plan (gauges-fs g) (reiatsu-bars e) d (if bored 0 live) (sim-rnd01)
                                   (list* :cap (brai-goal ai) k))))
        (setf (brai-lay-t ai) (+ *match-tick* (getf k :every 12)))
        (when (and plan (kit-command-ok-p e plan))
          (when bored (setf (brai-steer-t ai) -1) (pace e :ai-lay-bored))
          (pace e (if (eq plan :sp1) :ai-lay-fan :ai-lay))
          (why b :br-lay plan))))))

(defun br-ai-steer (e b s d)
  "The ranged form (batch 6, decision V7): points set and no line on him: walk a line onto him: the strafe toward the ray
from the nearest point through him (BR-STEER-TARGET; the line from a point through Lille swings as he walks), the neutral
walk carries it (BRAIN-STRAFE). Only in a stay that rolled to steer (BR-AI-STAY); its start kept for BR-AI-LAY's patience.
NIL (the neutral walk goes on)."
  (declare (ignore d))
  (let ((ai (br-ai-state e b)))
    (if (or (brai-on ai) (zerop (brs-live (br e))))
        (setf (brai-steer-t ai) -1)
        (multiple-value-bind (gap dir) (br-steer-target e (snap-x s) (snap-z s))
          (when gap
            (when (< (brai-steer-t ai) 0) (setf (brai-steer-t ai) *match-tick*) (when (brai-steer ai) (pace e :ai-steer)))
            (when (brai-steer ai) (setf (brain-strafe b) (f32 (if (< gap 0.1) 0.0 dir)))))))
    nil))

(defun br-ai-route-reset (e b)
  "Free in melee or the base form: the melee route is over, the ranged stay too (the next one picks again)."
  (let ((ai (br-ai-state e b))) (setf (brai-route ai) nil (brai-ranged ai) nil)))

(defun br-ai-melee (e b s d)
  "The melee forms free (batch 6): the opener in reach, on his action's react roll (BR-AI-ROUTE's :route :p x the
difficulty): K1 with :bank points set (the K links to K3 -> L the recall), J1 with a line on him (each J spends the nearest
line: the J links to J3 -> L the backstep, the pendulum). A command, or NIL (the generic bands)."
  (let* ((ai (br-ai-state e b)) (kit (kit-of e)) (live (brs-live (br e))) (k (ai-table e :route))
         (q (kit-command-move kit :q)) (fm (kit-command-move kit :f)))
    (when (and k (not (member (snap-state s) '(:down :wakeup :hoho)))
               (< (brain-react-roll b) (br-ai-chance (getf k :p 0.0) (brain-difficulty b))))
      (cond ((and fm (>= live (getf k :bank 6)) (<= d (+ (mv-reach fm) 0.2)) (kit-command-ok-p e :f))
             (setf (brai-route ai) :k) (pace e :ai-route-k) (why b :br-route :f))
            ((and q (plusp (br-near-count e (snap-x s) (snap-z s))) (<= d (+ (mv-reach q) 0.2)) (kit-command-ok-p e :q))
             (setf (brai-route ai) :j) (pace e :ai-route-j) (why b :br-route :q))))))

(defun br-ai-route-in (e b)
  "TENSHIN in by his CPU (BR-TENSHIN-GO): the melee route it goes in with, one roll (BR-AI-ROUTE on the melee kit's :route):
the K route latches K1 at the dash's end (a K during the dash, the old latch), the J route J1 (the default)."
  (let* ((ai (br-ai-state e b)) (st (br e))
         (k (getf (kit-ai (find-kit :barro (br-melee-of (fighter-form (fighter e))))) :route))
         (r (br-ai-route (sim-rnd01) (brs-live st) k (brain-difficulty b))))
    (setf (brai-route ai) r (brai-ranged ai) nil)
    (when (eq r :k) (setf (brs-latch st) :f))
    (pace e (case r (:k :ai-route-k) (:j :ai-route-j) (t :ai-route-none)))))

(defun br-ai-route-latch (e b mv)
  "His CPU's melee route on a link that hit (BARRO-HIT): the route's button latched for the next link (K: the K links, J:
the J links) when the grid has one and nothing is latched yet (the old Lille's LB-AI-ROUTE latch). No roll."
  (let* ((f (fighter e)) (ai (br-ai-state e b)) (c (case (brai-route ai) (:k :f) (:j :q))))
    (when (and c (null (fighter-queued f)) (kit-next (fighter-kit f) (mv-name mv) c))
      (setf (fighter-queued f) c))))

(defun br-ai-reflex (e b s d)
  "Every form's :reflex (ai.lisp AI-REFLEX, free states): the base form's stance (BR-AI-BASE); MUJITTAI's exit
(BR-AI-STANCE-OUT); ranged: MUJITTAI on a threat, going in (a lay and TENSHIN in, J1 in place: BR-AI-GO-IN), laying, steering the lines (batch 6); melee:
MUJITTAI on a threat, the route's opener (batch 6; the J strings materialise on their own, decision V6).
A command, :NONE (the window is his), or NIL."
  (let* ((kit (kit-of e)) (form (kit-form kit)))
    (cond ((eq form :base) (br-ai-route-reset e b) (or (br-ai-hard e b s d) (br-ai-base e b s d)))
          ((member :intangible (kit-passives kit)) (br-ai-stance-out e b s d))
          ((br-ranged-form-p form)
           (br-ai-stay e b d)
           (or (br-ai-stance-in e b s d) (br-learn-trace e b s d) (br-ai-hard e b s d) (br-ai-fire e b s d) (br-ai-lay e b s d)
               (br-ai-steer e b s d)))
          ((br-melee-form-p form)
           (br-ai-route-reset e b)
           (or (br-ai-stance-in e b s d) (br-learn-trace e b s d) (br-ai-hard e b s d) (br-ai-melee e b s d))))))

(defun br-on-him (e) "How many of E's live lines are on his opponent now (BR-NEAR-COUNT at his real spot: the recall's :off-n)."
  (let ((q (pos-of (opp-of e)))) (br-near-count e (aref q 0) (aref q 2))))

(defun br-ai-l-ok-p (e to)
  "His CPU's L link (BARRO-OK's CPU clause) to TO: the recall at :recall's count (BR-AI-RECALL-P), the backstep with no
trace and the flash step for lines (BR-AI-BACKSTEP-P), the mode turn always."
  (let ((st (br e)) (g (gauges e)))
    (case to
      (:br-recall (br-ai-recall-p (brs-live st) (reishi-frac g) (ai-table e :recall) (br-on-him e)))
      (:br-backstep (br-ai-backstep-p (brs-live st) (ai-table e :backstep)))
      (t t))))

(defun br-ai-sp-ender (e kit)
  "The melee forms' :sp-ender (ai.lisp STRING-REFLEX: a landed J3 / K3, no O ender rolled; AI-BRAIN: his CPU's, or the
ASSIST's for a human): K3 -> L the recall (BR-AI-RECALL-P), J3 -> L the backstep (BR-AI-BACKSTEP-P), one roll on the land
frame at :recall / :backstep :p x the difficulty. :SIG, or NIL (the generic SP2 cancel)."
  (let* ((b (ai-brain e)) (f (fighter e)) (mv (fighter-move f)) (st (br e)) (g (gauges e)))
    (when (and b mv (member :ender (mv-flags mv)) (br-melee-form-p (kit-form kit)))
      (let* ((to (br-l-route (mv-kind mv) t)) (key (if (eq to :br-recall) :recall :backstep)) (k (getf (kit-ai kit) key)))
        (when (and (if (eq to :br-recall)
                       (br-ai-recall-p (brs-live st) (reishi-frac g) k (br-on-him e))
                       (br-ai-backstep-p (brs-live st) k))
                   (kit-command-ok-p e :sig kit nil (kit-l-link kit (mv-name mv)))
                   (< (sim-rnd01) (br-ai-chance (getf k :p 0.0) (brain-difficulty b))))
          (pace e (if (eq to :br-recall) :ai-recall :ai-backstep))
          :sig)))))

(defparameter *br-opp-gap* 30
  "Frames between two of a CPU's rolls to Step off his lines for a line swinging back onto it (a new line laid onto it
rolls at once) (batch 6, 2026-10-10 [G]: the lines turn through him, so a CPU crosses them as he walks).")
(defun br-opp-trace (e b s d)
  "A CPU facing his awakened forms (his kits' :opp-reflex, :opp-trace (:p)): standing on the line (BR-ON-LINE-P: its radius
+ *BR-AI-ON*) of one of his traces it has seen (laid at least its perception delay ago): one roll per crossing (onto a
line after being off every line, at most once in *BR-OPP-GAP* frames: the lines swing with him, decision V7) or per line
newer than the ones it rolled for, :p x the difficulty (OPP-CHANCE): a sideways Step off that line (LINE-OFF-STRAFE: the
line from its point through him, the Step across it). Rooted forms can't. (The old Lille's LB-OPP-TRACE, copied 2026-10-09;
crossings since batch 6.)"
  (declare (ignore s d))
  (let* ((o (opp-of e)) (k (getf (kit-ai (kit-of o)) :opp-trace)))
    (when (and k (not (kit-rooted (kit-of e))) (br-awake-form-p (fighter-form (fighter o))))
      (let* ((st (br o)) (p (pos-of e)) (on nil))
        (do-entities (h (hz hazard))
          (let ((dd (hazard-data hz)))
            (when (and (eql (hazard-owner hz) o) (brh-p dd) (brh-live dd) (>= (hazard-age hz) (brain-delay b))
                       (br-on-line-p hz dd (aref p 0) (aref p 2))
                       (or (null on) (> (brh-id dd) (brh-id (hazard-data on)))))
              (setf on hz))))
        (cond ((null on) (setf (brs-opp-on st) nil) nil)
              ((or (> (brh-id (hazard-data on)) (brs-opp-roll st))
                   (and (not (brs-opp-on st)) (>= (- *match-tick* (brs-opp-t st)) *br-opp-gap*)))
               (setf (brs-opp-on st) t (brs-opp-roll st) (max (brs-opp-roll st) (brh-id (hazard-data on))) (brs-opp-t st) *match-tick*)
               (pace o :opp-trace-roll)
               (when (< (sim-rnd01) (opp-chance (getf k :p 0.0) (brain-difficulty b)))
                 (pace o :opp-trace-step)
                 (let ((q (pos-of o)))
                   (setf (brain-strafe b) (f32 (line-off-strafe (hazard-x on) (hazard-z on) (hazard-yaw on) (aref p 0) (aref p 2)
                                                                (aref q 0) (aref q 2)))))
                 (why b :trace-step :side-step)))
              (t (setf (brs-opp-on st) t) nil))))))

;;; ================================================================ AI: the learning CPU's situations (DUEL_LILLE_V2 §13)
;;; The old Lille's pattern (DUEL_LILLE §24.9): only a learner runs this (a CPU facing a human: VS CPU, ENDLESS, the learning
;;; gate; LRN-KIT); CPU VS CPU and the gates never get here. A read is one roll of the learner's own stream per event
;;; (LEARN-KIT-READ: p_exploit x *BR-LEARN-DIFF*), every answer a command of his kit.
;;;   :shot      his stance's 萬物貫通 shot on a free opponent (the stance's plan :kamae-l): the human's answer (:guard :hoho
;;;              :step :attack :back :take). Read at that plan: a guard -> the stance's SP1 (three lines, 120 of guard);
;;;              a Step / backing off -> the snap shot (S6) with a pip, else SP1 (it turns 90 deg/s); a Hoho / an attack ->
;;;              TAISHA's back-slide with a pip, else the stance's SP2 (the 6 m slide)
;;;   :trace     awakened, the human on one of his lines (perceived, laid >= the delay ago; batch 6: a crossing, the lines
;;;              swing with him, BR-ON-LINE-P) : his answer (:step off it by >= *BR-LEARN-OFF* m, :guard, :hoho, :attack,
;;;              :back along it, :take). Read at the onset: a guard -> in now (a lay and TENSHIN in / a melee J: the line on him, 萬物貫通
;;;              through it; batch 6, a K spends one only on a touch); a Step -> SP1's fan at him (ranged, the bar and the flash step there); a Hoho -> the fire held while
;;;              he is free (*BR-LEARN-HOLD* f); an attack -> MUJITTAI (U) once he is inside 4 m
;;;   :mujittai  his MUJITTAI with the human inside 5 m: his answer (:attack into it, :guard, :hoho, :step, :back, :take). Read
;;;              at the onset: an attack -> he stays (no :max / idle exit: the whiff exit only); waiting (:guard :back :take)
;;;              -> he leaves at once (MUJITTAI's exit command)
(defparameter *br-learn-diff* '(:easy 0.5 :normal 1.0 :hard 1.5)
  "His learning CPU's read chance x this by difficulty (on the learner's p_exploit): EASY <= NORMAL <= HARD (new 2026-10-09,
batch 4; the old Lille's *LB-LEARN-DIFF*).")
(defparameter *br-learn-episode* '(:shot 24 :trace 40 :mujittai 60)
  "Frames a situation waits for his answer, + the perception delay (new 2026-10-09, batch 4).")
(defparameter *br-learn-hold* 60 "Frames a :trace read of a Hoho holds the fire at most (new 2026-10-09, batch 4).")
(defparameter *br-learn-off* 0.5
  "Metres he must have moved from the :trace onset's spot for leaving every line to count as his :step (the lines swing
with Lille, decision V7: one swinging off him is not his answer) (new 2026-10-10, batch 6 [G]).")

;; pure: host-tested
(defun br-learn-answer (hprev hs new away)
  "His answer starting this step (perceived HPREV -> HS, NEW: a new move of his, AWAY: metres he moved away since the onset):
:HOHO, :STEP, :ATTACK, :GUARD, :BACK, or NIL (the old Lille's LB-LEARN-ANSWER)."
  (cond ((and (eq hs :hoho) (not (eq hprev :hoho))) :hoho)
        ((and (eq hs :step) (not (eq hprev :step))) :step)
        ((and (eq hs :move) (or (not (eq hprev :move)) new)) :attack)
        ((and (eq hs :guard) (not (eq hprev :guard))) :guard)
        ((> away *learn-back*) :back)))
(defun br-learn-onset-answer (hs) "His answer already under way at the onset (perceived HS): a guard, a Hoho, a Step, or NIL."
  (case hs ((:guard :guard-hit) :guard) (:hoho :hoho) (:step :step)))
(defun br-learn-kamae-plan (read snipe sp-ok plan &optional step-ok)
  "The stance's follow-up instead of PLAN (the shot) for his predicted answer READ to it (SNIPE pips, SP-OK the bars): a
guard the stance's SP1; a Step / backing off the snap shot (a pip) else SP1; a Hoho / an attack the K (its tier's
back-slide shot, decision V9) with a pip, else the stance's SP2, else the stance Step straight back while this stance's
Step is there (STEP-OK; decision V9d: the 0-pip K is the plain K1, no longer TAISHA's slide), else PLAN; else PLAN
(no read)."
  (case read
    (:guard (if sp-ok :kamae-sp1 plan))
    ((:step :back) (cond ((>= snipe 1) :kamae-j) (sp-ok :kamae-sp1) (t plan)))
    ((:hoho :attack) (cond ((>= snipe 1) :kamae-k) (sp-ok :kamae-sp2) (step-ok :kamae-step) (t plan)))   ; (0 pips: V9d)
    (t plan)))
(defun br-learn-trace-plan (read)
  "The :trace read's answer: a guard :FIRE (K now), a Step :FAN (SP1 at him), a Hoho :HOLD (the fire waits), an attack
:STANCE (MUJITTAI), else NIL."
  (case read (:guard :fire) (:step :fan) (:hoho :hold) (:attack :stance)))
(defun br-learn-mujittai-plan (read)
  "The :mujittai read's answer: an attack :STAY (only the whiff exit), waiting (:guard :back :take) :LEAVE (out at once)."
  (case read (:attack :stay) ((:guard :back :take) :leave)))

;; the shell
(defstruct (brl (:conc-name brl-))
  "His learner's own state within a match (LRN-KDATA)."
  (own-mv nil) (own-sf 0 :type fixnum)                      ; his move last step (the shot's onset)
  (ox 0f0 :type single-float) (oz 0f0 :type single-float)   ; the open situation's onset: his perceived position,
  (ux 0f0 :type single-float) (uz 0f0 :type single-float)   ; ... the way from Lille II to him (his :back)
  (len 0 :type fixnum)                                      ; ... its episode's frames
  (on-id 0 :type fixnum)                                    ; the newest trace he was perceived near (id; 0 none)
  (on-was nil)                                              ; ... he was on a line at the last step (a crossing opens: batch 6)
  (trace-plan nil) (trace-until -1 :type fixnum) (trace-done nil)   ; the :trace read's answer, its life, acted
  (mu-t0 -1 :type fixnum) (mu-plan nil))                    ; the MUJITTAI read (its start tick) and its answer
(defun br-learn-state (l) (or (lrn-kdata l) (setf (lrn-kdata l) (make-brl))))
(defun br-learn-l (b) "Brain B's learner when it reads his situations (LRN-KIT), else NIL." (let ((l (and b (brain-learn b)))) (and l (lrn-kit l) l)))
(defun br-learn-scale (b) (float (getf *br-learn-diff* (brain-difficulty b) 1.0) 1.0))
(defun br-learn-acted (e l cmd)
  "A read of his situations acted on with CMD: the learner's count (LEARN-COUNT-READ), the log."
  (learn-count-read e l cmd)
  (pace e cmd)
  (clog "~a read ~a" (side-name e) cmd))

(defun br-learn-open (e s l k key)
  "Open his situation KEY at the perceived SNAP S: the onset's position, the way to him; an answer already under way
(BR-LEARN-ONSET-ANSWER) counts at once."
  (let* ((dx (- (snap-x s) (aref (pos-of e) 0))) (dz (- (snap-z s) (aref (pos-of e) 2))) (m (max 1e-3 (hypot dx dz))))
    (setf (brl-ox k) (snap-x s) (brl-oz k) (snap-z s) (brl-ux k) (f32 (/ dx m)) (brl-uz k) (f32 (/ dz m))
          (brl-len k) (+ (getf *br-learn-episode* key 30) (brain-delay (brain e)))))
  (learn-kit-open l key)
  (let ((now (br-learn-onset-answer (snap-state s))))
    (when now (learn-kit-close l now))))

(defun br-learn-near-id (e x z age)
  "The newest of E's live traces at least AGE frames old with (X Z) inside its snap (BR-NEAR-P): its id, 0 for none."
  (let ((id 0))
    (do-entities (h (hz hazard))
      (let ((dd (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p dd) (brh-live dd) (>= (hazard-age hz) age) (> (brh-id dd) id)
                   (br-on-line-p hz dd x z))
          (setf id (brh-id dd)))))
    id))

(defun br-learn-step (e b s d l)
  "His learner's step (LEARN-DEF-KIT's :step): the onsets (his stance's shot; MUJITTAI with him inside 5 m; the human inside
a trace's snap, perceived), the open situation's answer (BR-LEARN-ANSWER; :trace's :step when he left every snap; at its
end :TAKE, or :GUARD held through), the :trace and :mujittai reads at their onsets (one roll each)."
  (let* ((k (br-learn-state l)) (f (fighter e)) (mv (and (eq (fighter-state f) :move) (fighter-move f)))
         (hs (snap-state s)) (hprev (lrn-hstate l)) (new (/= (snap-start s) (lrn-hstart l))) (st (br e))
         (x (snap-x s)) (z (snap-z s)))
    (when (and mv (or (not (eq mv (brl-own-mv k))) (< (fighter-sf f) (brl-own-sf k)))
               (eq (mv-name mv) :br-k-shot) (< (lrn-ksit l) 0) (member hs '(:idle :run :guard)))
      (br-learn-open e s l k :shot))
    (setf (brl-own-mv k) mv (brl-own-sf k) (if mv (fighter-sf f) 0))
    (when (and (member :intangible (kit-passives (fighter-kit f))) (< d 5.0))
      (let ((t0 (- *match-tick* (brs-stance st))))
        (when (/= t0 (brl-mu-t0 k))
          (setf (brl-mu-t0 k) t0
                (brl-mu-plan k) (br-learn-mujittai-plan (learn-kit-read l :mujittai (br-learn-scale b))))
          (when (brl-mu-plan k) (br-learn-acted e l (if (eq (brl-mu-plan k) :stay) :br-mu-stay :br-mu-leave)))
          (when (< (lrn-ksit l) 0) (br-learn-open e s l k :mujittai)))))
    (when (and (br-awake-form-p (fighter-form f)) (plusp (brs-live st)))
      (let ((id (br-learn-near-id e x z (brain-delay b))))
        (when (and (plusp id) (or (> id (brl-on-id k)) (not (brl-on-was k))) (< (lrn-ksit l) 0))   ; (a crossing: batch 6)
          (br-learn-open e s l k :trace)
          (setf (brl-trace-plan k) (br-learn-trace-plan (learn-kit-read l :trace (br-learn-scale b)))
                (brl-trace-until k) (+ *match-tick* (if (eq (brl-trace-plan k) :hold) *br-learn-hold* (brl-len k)))
                (brl-trace-done k) nil))
        (setf (brl-on-id k) (max id (brl-on-id k)) (brl-on-was k) (plusp id))))
    (when (>= (lrn-ksit l) 0)
      (let ((sit (aref (getf (lrn-kit l) :situations) (lrn-ksit l))) (end (>= (incf (lrn-kep-t l)) (brl-len k)))
            (away (+ (* (- x (brl-ox k)) (brl-ux k)) (* (- z (brl-oz k)) (brl-uz k)))))
        (cond ((member hs '(:stun :air :down :wakeup)) (learn-kit-close l (if (eq sit :trace) nil :take)))
              (t (let ((ans (or (br-learn-answer hprev hs new away)
                                (and (eq sit :trace) (zerop (br-near-count e x z))   ; (off every line by his own
                                     (> (hypot (- x (brl-ox k)) (- z (brl-oz k))) *br-learn-off*) :step))))   ;  move: batch 6)
                   (cond (ans (learn-kit-close l ans))
                         (end (learn-kit-close l (if (member hs '(:guard :guard-hit)) :guard :take)))))))))))

(defun br-learn-trace (e b s d)
  "Melee / ranged free (BR-AI-REFLEX, before BR-AI-FIRE): the :trace read's answer, once a read: J with a line on him (a
guard read: ranged BR-AI-GO-IN, a lay and TENSHIN in with a line on him at the dash's end or J1 in place (decision V6a),
melee J1; batch 6), SP1's fan at him (a Step read, ranged), U (an attack read, him inside 4 m). A command, or NIL. (A Hoho read
holds the fire: BR-LEARN-HOLD-P.)"
  (let ((l (br-learn-l b)))
    (when l
      (let* ((k (br-learn-state l)) (p (brl-trace-plan k)))
        (when (and p (not (brl-trace-done k)) (<= *match-tick* (brl-trace-until k)))
          (case p
            (:fire (if (br-ranged-form-p (fighter-form (fighter e)))      ; (ranged: J1 in place, else a lay and TENSHIN in
                       (when (plusp (br-end-count e (snap-x s) (snap-z s)))   ;  (decision V6a); melee J: each spends the line
                         (let ((c (br-ai-go-in e b d)))                       ;  on him: batch 6; K only on a touch)
                           (when c (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-fire) (why b :learn-fire c))))
                       (when (and (plusp (br-near-count e (snap-x s) (snap-z s))) (kit-command-ok-p e :q))
                         (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-fire) (why b :learn-fire :q))))
            (:fan (when (and (br-ranged-form-p (fighter-form (fighter e))) (kit-command-ok-p e :sp1))
                    (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-fan) (why b :learn-fan :sp1)))
            (:stance (when (< d 4.0)
                       (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-stance)
                       (ai-press b :guard 4 :act :hold) (why b :learn-stance :none)))))))))

(defun br-learn-hold-p (e b s)
  "Does a :trace read of a Hoho hold his fire now (the read's window, him free: BR-AI-FIRE waits)?"
  (let ((l (br-learn-l b)))
    (and l (let ((k (br-learn-state l)))
             (and (eq (brl-trace-plan k) :hold) (<= *match-tick* (brl-trace-until k))
                  (not (br-ai-busy-p s (brain-delay b) 0))
                  (progn (unless (brl-trace-done k) (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-hold)) t))))))

(defun br-learn-mujittai (b)
  "The :mujittai read's answer for MUJITTAI's exit (BR-AI-STANCE-OUT): :STAY, :LEAVE, or NIL."
  (let ((l (br-learn-l b))) (and l (brl-mu-plan (br-learn-state l)))))

(defun br-learn-kamae (e b plan)
  "The stance's PLAN (BR-AI-KAMAE, once a stance, his CPU): the shot on a free opponent is read (one roll: :shot) and
answered (BR-LEARN-KAMAE-PLAN); anything else, or no learner, as planned."
  (let ((l (br-learn-l b)))
    (if (and l (eq plan :kamae-l) (not (member (state-of (opp-of e)) '(:stun :air))))
        (let* ((r (learn-kit-read l :shot (br-learn-scale b)))
               (p (br-learn-kamae-plan r (brs-snipe (br e))
                                       (>= (gauges-reiatsu (gauges e)) (* (kit-command-cost (kit-of e) :sp1) *reiatsu-bar*)) plan
                                       (br-kamae-step-ok-p (brs-dashed (br e)) (gauges-fs (gauges e))))))
          (unless (eq p plan) (br-learn-acted e l (intern (format nil "BR-SHOT-~a" r) :keyword)))
          p)
        plan)))

(learn-def-kit :barro :situations #(:shot :trace :mujittai) :actions #(:guard :hoho :step :attack :back :take)
               :step 'br-learn-step)

;;; ================================================================ ASSIST AUTO COMBO's routes (DUEL_LILLE_V2 §8, §13)
;;; His kits' :ai name BR-ASSIST-COMBO as :assist-combo (assist.lisp AUTO-ROUTE: asked every step AUTO COMBO is on, before
;;; the generic AUTO COMBO; the old Lille's LB-ASSIST-COMBO's shape). "You press J, the CPU chooses": the routes press his
;;; buttons as a human's (his ticks read his vpad: BR-TICK-BRAIN is NIL for a human), x*ASSIST-MULT*, the AUTO tag.
;;;   base    J -> K -> L -> L: his J in a link that hit -> its K link (J1 -> K2s) -> L latched on the K link (the stance at
;;;           f4, KIT-L-LINK: a combo) -> its plan (BR-AI-KAMAE-PLAN: the 萬物貫通 shot on the reeling opponent; TAISHA /
;;;           the snap with a pip close) pressed once it is up; his J eaten meanwhile. (J J J -> L measured first: the
;;;           stance off J3 comes from neutral, after his stagger: the masher's wins 36 % -> 24 %, §13)
;;;   melee   (batch 6) his J in a melee link that hit, on the land frame: K K K -> L the recall while the points left after
;;;           the K touches still number 3, else J J J -> L the backstep (10 flash step + a lay's 3); his J eaten after a press
;;;   ranged  (batch 6; decision V6a) L point -> J dash -> J1: his J pressed while free in ranged mode beyond J1's reach -> an
;;;           aim point at him (L) with 10 flash step left (else his J: J1 in place); his J in the backstep from its f14 ->
;;;           that L at once; his next J cancels it into TENSHIN in (2 f) along that line
(defstruct (bras (:conc-name bras-))
  (b nil)                                 ; the assist brain it belongs to (a new match: a fresh one)
  (mv nil) (sf -1 :type fixnum)           ; the move instance seen
  (j nil)                                 ; his J seen during it (pressed, buffered or latched)
  (done nil)                              ; the route pressed in it (his J eaten after)
  (route nil)                             ; a route runs (the stance's)
  (plan nil))                             ; the base route: the stance's plan
(defvar *br-as* (vector (make-bras) (make-bras)) "Per side: the ASSIST routes' state (BR-ASSIST-COMBO).")

(defun br-as-track (f b vp)
  "The route state of F's side for brain B, its move instance brought up to date, his J this step noted."
  (let* ((side (fighter-side f)) (a (svref *br-as* side)) (mv (and (eq (fighter-state f) :move) (fighter-move f))))
    (unless (eq (bras-b a) b) (setf a (make-bras :b b) (svref *br-as* side) a))
    (cond ((null mv) (setf (bras-mv a) nil (bras-j a) nil (bras-done a) nil))
          ((or (not (eq mv (bras-mv a))) (< (fighter-sf f) (bras-sf a)))
           (setf (bras-mv a) mv (bras-j a) nil (bras-done a) nil)
           (unless (member (mv-name mv) '(:br-kamae :br-kamae-k :br-kamae-j :br-kamae-re)) (setf (bras-route a) nil (bras-plan a) nil))))
    (when mv
      (setf (bras-sf a) (fighter-sf f))
      (when (or (vpad-command-pressed-p vp :quick nil) (eq (fighter-queued f) :q)) (setf (bras-j a) t)))
    a))

(defun br-as-press (e a key cmd)
  "A route press: counted in his pacing log (the gates' route counts), his J eaten after it in this move. CMD."
  (setf (bras-done a) t)
  (pace e key)
  cmd)

(defun br-as-kamae (e f vp a)
  "Route base, the stance of the route's: his J eaten till it is up, then its plan (one roll, BR-AI-KAMAE-PLAN) pressed once."
  (cond ((bras-done a) (vpad-consume! vp :quick) :none)
        ((< (1+ (fighter-sf f)) *br-kamae-up*) (vpad-consume! vp :quick) :none)
        (t (unless (bras-plan a)
             (setf (bras-plan a) (br-ai-kamae-plan (sim-rnd01) (fighter-dist f) (member (state-of (opp-of e)) '(:stun :air))
                                                   (brs-snipe (br e))
                                                   (>= (gauges-reiatsu (gauges e)) (* (kit-command-cost (fighter-kit f) :sp1) *reiatsu-bar*))
                                                   (ai-table e :kamae) (if (bras-b a) (brain-difficulty (bras-b a)) :normal))))
           (br-as-press e a :as-stance-plan
                        (case (bras-plan a) (:kamae-j :q) (:kamae-k :f) (:kamae-sp1 :sp1) (:kamae-sp2 :sp2) (t :sig))))))

(defun br-as-base (e f vp a mv)
  "Route base, a J / K link that hit with his J in it: on its land frame a K link's L (the stance at f4: KIT-L-LINK), else
its K link (J1 -> K2s); his J eaten after a press. A command, :NONE, or NIL (the generic AUTO COMBO)."
  (let* ((kit (fighter-kit f)) (name (mv-name mv)) (l (kit-l-link kit name)))
    (cond ((bras-done a) (vpad-consume! vp :quick) (when (eq (fighter-queued f) :q) (setf (fighter-queued f) nil)) :none)
          ((not (and (bras-j a) (eq (fighter-contact f) :hit) (= (fighter-sf f) (fighter-land-sf f)))) nil)
          ((and l (kit-k-link-p kit name) (kit-command-ok-p e :sig kit nil l))
           (setf (bras-route a) t)
           (br-as-press e a :as-stance :sig))
          ((kit-next kit name :f) (br-as-press e a :as-k-link :f)))))

(defun br-as-k-route-p (live)
  "The ASSIST's melee route (batch 6): K links on with LIVE >= 3 points set (the recall's tier 2 and up; decision V8: a K
spends none, the recall takes them all)."
  (>= live 3))

(defun br-as-melee (e f vp a mv)
  "Route melee (batch 6), a link that hit with his J in it, on its land frame: the K links with 3 points set for the recall
(BR-AS-K-ROUTE-P; a K spends none, decision V8), else the J links (J J J: each J spends a line on him); K3 -> L the recall
with a point to take back (n >= 1), J3 -> L the backstep with 2 (it spends one, TENSHIN in back another: decision V8a); his
J eaten after a press. A command, :NONE, or NIL (the generic AUTO COMBO)."
  (let* ((kit (fighter-kit f)) (st (br e)) (name (mv-name mv)) (nf (kit-next kit name :f)) (nq (kit-next kit name :q)))
    (cond ((bras-done a) (vpad-consume! vp :quick) (when (eq (fighter-queued f) :q) (setf (fighter-queued f) nil)) :none)
          ((not (and (bras-j a) (eq (fighter-contact f) :hit) (= (fighter-sf f) (fighter-land-sf f)))) nil)
          ((and nf (br-as-k-route-p (brs-live st))) (br-as-press e a :as-k-link :f))
          (nq (br-as-press e a :as-j-link :q))
          (nf (br-as-press e a :as-k-link :f))
          ((and (member :ender (mv-flags mv)) (not (eq (state-of (opp-of e)) :air))
                (>= (brs-live st) (if (eq (mv-kind mv) :flash) 1 2))   ; (V8a: the backstep spends one, the dash back another)
                (kit-command-ok-p e :sig kit nil (kit-l-link kit name)))
           (br-as-press e a (if (eq (mv-kind mv) :flash) :as-recall :as-backstep) :sig)))))

(defun br-as-ranged (e f s vp)
  "Route ranged (batch 6; decision V6a, 2026-10-10: TENSHIN in only out of a lay), his J pressed while free beyond J1's reach
(+ 0.2 m): L (an aim point at him) with the flash step over 10 after it: his next J in it (latched at any frame, decision
V6c) cancels into TENSHIN in (2 f, BR-LAY-TICK): the farthest trace spent (decision V8a), its f0 fires the nearest of the
rest, J1 at the dash's end (L point -> J dash -> J1 ...); within *BR-DASH-LATE* f after a lay (BRS-LATE) his J is left
alone: it dashes (BR-MELEE-IN); else NIL (his J: J1 in place). (Decision V8's swing route gone: decision V8b.)"
  (when (and s (zerop (brs-late (br e))) (vpad-command-pressed-p vp :quick nil))
    (let ((q (kit-command-move (fighter-kit f) :q)))
      (when (and q (> (fighter-dist f) (+ (mv-reach q) 0.2)) (>= (- (gauges-fs (gauges e)) *br-lay-l*) 10.0)
                 (kit-command-ok-p e :sig))
        (pace e :as-lay) :sig))))

(defun br-as-backstep (e f vp a)
  "Route ranged out of the backstep (J3 -> L; batch 6): his J from its f14 (the lay's window, BR-BACKSTEP-LAY-OK-P) -> an aim
point at him (L: BR-BACKSTEP-TICK cancels the recovery into it) with 10 flash step left after it; his J eaten after; his
next J cancels that lay into TENSHIN in (2 f; it spends the farthest trace and fires the nearest, decision V8a: the
pendulum). A command, :NONE or NIL. (The L again since decision V8b; SP1's fan under V8.)"
  (cond ((bras-done a) (vpad-consume! vp :quick) :none)
        ((and (br-backstep-lay-ok-p (fighter-sf f)) (vpad-command-pressed-p vp :quick nil)
              (>= (- (gauges-fs (gauges e)) *br-lay-l*) 10.0))
         (br-as-press e a :as-lay :sig))))

(defun br-assist-combo (e f b s d vp)
  "His kits' :assist-combo (assist.lisp AUTO-ROUTE): the routes above on the assist's brain B (S, D as it perceives him), his
vpad VP: a command, :NONE (the route holds the step) or NIL (the generic AUTO COMBO)."
  (declare (ignore d))
  (let* ((a (br-as-track f b vp)) (mv (bras-mv a)) (form (fighter-form f))
         (free (and (member (fighter-state f) '(:idle :guard :run)) (zerop (fighter-lock f)))))
    (cond ((and mv (member (mv-name mv) '(:br-kamae :br-kamae-k :br-kamae-j :br-kamae-re)) (bras-route a)) (br-as-kamae e f vp a))
          ((and mv (eq (mv-name mv) :br-backstep)) (br-as-backstep e f vp a))
          ((and mv (eq form :base) (member (mv-kind mv) '(:quick :flash))) (br-as-base e f vp a mv))
          ((and mv (br-melee-form-p form) (member (mv-kind mv) '(:quick :flash))) (br-as-melee e f vp a mv))
          ((and free (br-ranged-form-p form)) (br-as-ranged e f s vp)))))

;; every form of his names it (assist.lisp AUTO-ROUTE reads the key off the form's kit)
(dolist (form *br-forms*)
  (let ((k (find-kit :barro form)))
    (unless (getf (kit-ai k) :assist-combo)
      (setf (kit-ai k) (list* :assist-combo 'br-assist-combo (kit-ai k))))))

;;; ================================================================ debug: tests, the pacing log (debug.lisp dispatches)
(defun barro-acc-line ()
  "After a gate row: a \"duel barro\" line per side that played him (the pacing log, DUEL_LILLE_V2 §11)."
  (dolist (e (list *p1* *p2*))
    (when (and (entity-alive-p e) (eq (fighter-character (fighter e)) :barro))
      (let ((st (br e)))
        (log-msg "duel barro ~a seed ~d awakened ~a form ~a snipe ~d live ~d sealed ~a ~{~(~a~) ~a~^ ~}" (side-name e) *match-seed*
                 (gauges-awakened (gauges e)) (fighter-form (fighter e)) (brs-snipe st) (brs-live st) (brs-sealed st)
                 (svref *pacing* (fighter-side (fighter e))))))))

(defun barro-probe-line (tag)
  (let ((g1 (gauges *p1*)) (g2 (gauges *p2*)) (st (br *p1*)))
    (log-msg "duel probe barro ~a t ~d p1 ~a ~a r~d k~d fs ~d snipe ~d live ~d revive ~a | p2 ~a r~d gg ~d | d ~,2f"
             tag *match-tick* (fighter-form (fighter *p1*)) (state-of *p1*) (gauges-reishi g1) (gauges-konpaku g1)
             (round (gauges-fs g1)) (brs-snipe st) (br-live-traces *p1*) (bankai-ready-p *p1*)
             (state-of *p2*) (gauges-reishi g2) (round (gauges-gg g2)) (fighter-dist (fighter *p1*)))))

(defun barro-test (k)
  "82000+k (human P1 Lille II, P2's CPU off unless noted; a \"duel probe barro\" line): 0 the base form 2.2 m from Kenpachi;
1 the base form 14 m out; 2 forced JILLIEL melee 5 m out; 3 forced ranged 8 m out; 4 forced owl melee 5 m out; 5 ranged
8 m out with 6 traces laid through P2 (the recall: J / K in, then K K K L); 6 the base form 4 m out with 3 狙擊 pips;
7 / 8 the owl melee 6 m out, Trompete started, P2 reflecting it by a guard on f54 / a Hoho on f52; 9 forced owl ranged
8 m out; 10 JILLIEL melee with 3 Konpaku (P revives); 11 / 12 forced melee / ranged MUJITTAI 5 m out; 13 forced ranged
6 m out with 3 aim points set around him (facing P2 -30 / 0 / +30 deg: the middle line through P2; L then J: the lay's 2 f
cancel, TENSHIN in -> J1 -> a trace hits; J alone: J1 in place, decision V6a); 14 the base form 6 m out, the shooting stance started (Step: 飛廉脚); 15 forced melee 1.4 m out (J J J
L: the backstep); 16 as 13 with the owl; 20 both CPUs (the mirror) 12 m apart; 24 / 25 / 26 the base form 4 m out with
0 / 1 / 2 狙擊 pips (decision V9: L then K, the K's tiers; 6 has 3); 27 / 28 the same with 3 / 2 pips, P2 holding guard
(破陣弾's guard break / 穿甲弾's block); 29 the base form 1.3 m out with 1 pip (V9c: J, L, J the snap, J: J1); 17 forced melee 1.4 m
out with 10 aim points (decision V8: K K K L, 裁き・極); 18 forced ranged 1.5 m out, no point (decision V8b: L sets its own
point at f4; L then J: the dash spends that one, nothing fires, decision V8a); 19 the same with two points (-40 / 0 deg, L's
own a third: L then J, the dash spends the farthest, fires the nearest); 30 a \"duel probe barro-trace\" line per
live trace of P1's (its point, direction, distance to P2); any other k (31) the probe line only (batch 5, DUEL_LILLE_V2 §15)."
  (flet ((setup (c2 form dist &key cpu)
           (ensure-battle :barro c2 :cpu cpu)
           (when (brain *p1*) (setf (brain-off (brain *p1*)) (not cpu)))
           (unless (eq (fighter-form (fighter *p1*)) form) (force-form *p1* form))
           (place *p1* *p2* dist)
           (setf (gauges-reiatsu (gauges *p1*)) *reiatsu-max* (gauges-fs (gauges *p1*)) (f32 *fs-max*))))
    (setf *br-reflect-test* nil)
    (case k
      (0 (setup :kenpachi :base 2.2))
      (1 (setup :kenpachi :base 14.0))
      (2 (setup :kenpachi :jilliel-kin 5.0))
      (3 (setup :kenpachi :jilliel 8.0))
      (4 (setup :kenpachi :shin-kin 5.0))
      (5 (setup :kenpachi :jilliel 8.0)
       (dolist (a '(-6.0 -3.6 -1.2 1.2 3.6 6.0)) (br-lay-trace *p1* :l a)))
      (6 (setup :kenpachi :base 4.0) (setf (brs-snipe (br *p1*)) 3))
      ((7 8) (setup :kenpachi :shin-kin 6.0) (setf *br-reflect-test* (if (= k 7) :guard :hoho)) (force-cmd *p1* :sp2))
      (9 (setup :kenpachi :shin 8.0))
      (10 (setup :kenpachi :jilliel-kin 5.0) (setf (gauges-konpaku (gauges *p1*)) 3))
      (11 (setup :kenpachi :jilliel-kin-mujittai 5.0))
      (12 (setup :kenpachi :jilliel-mujittai 5.0))
      ((13 16) (setup :kenpachi (if (= k 13) :jilliel :shin) 6.0)
       (setf (brs-revive-t (br *p1*)) *match-tick*)   ; (the owl forced: no revival's clearing of the traces below)
       (dolist (a '(-30.0 0.0 30.0)) (br-lay-trace *p1* :l a)))
      (14 (setup :kenpachi :base 6.0) (force-cmd *p1* :sig))
      (15 (setup :kenpachi :jilliel-kin 1.4))
      (20 (setup :barro :base 12.0 :cpu t))
      ((24 25 26) (setup :kenpachi :base 4.0) (setf (brs-snipe (br *p1*)) (- k 24)))   ; (decision V9: the K's tiers 1-2; 0: K1, V9d)
      ((27 28) (setup :kenpachi :base 4.0) (setf (brs-snipe (br *p1*)) (if (= k 27) 3 2))   ; (... into P2's held guard)
       (when (brain *p2*) (ai-press (brain *p2*) :guard 600 :act :hold)))
      (29 (setup :kenpachi :base 1.3) (setf (brs-snipe (br *p1*)) 1))   ; (decision V9c: J -> L -> J the snap -> J1)
      (17 (setup :kenpachi :jilliel-kin 1.4)                            ; (decision V8: K K K -> L with 10 points: 裁き・極)
       (dotimes (i 10) (br-lay-trace *p1* :l (- (* 4.0 i) 18.0))))
      (18 (setup :kenpachi :jilliel 1.5))                               ; (no point: L sets one (V8b), L then J spends it)
      (19 (setup :kenpachi :jilliel 1.5)                                ; (... with two points: the dash spends the
       (dolist (a '(-40.0 0.0)) (br-lay-trace *p1* :l a)))              ;  farthest, fires the nearest: decision V8a)
      (30 (br-trace-probe)))
    (barro-probe-line (format nil "test ~d" k))))

(defun br-trace-probe ()
  "82030: a \"duel probe barro-trace\" line per live trace of P1's: its id, aim point, direction and line's distance to P2."
  (let ((q (pos-of *p2*)))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) *p1*) (brh-p d) (brh-live d))
          (log-msg "duel probe barro-trace t ~d id ~d src ~a point ~,2f ~,2f dir ~,3f ~,3f dist-p2 ~,2f" *match-tick* (brh-id d)
                   (brh-src d) (hazard-x hz) (hazard-z hz) (brh-ux d) (brh-uz d) (br-trace-dist hz d (aref q 0) (aref q 2))))))))

(defun br-test-tick (e f)
  "His per-step debug overrides (BARRO-TICK): *BR-TEST-AWAKE*, *BR-TEST-DIFF*. Nothing when both are off (the gates)."
  (let ((b (brain e)))
    (when (and *br-test-awake* b (eq (brain-habit b) :dumb) (zerop (fighter-side f)) (eq (fighter-form f) :base)
               (member (fighter-state f) '(:idle :run :guard)) (zerop (fighter-lock f)))
      (force-form e :jilliel-kin))
    (when (and *br-test-diff* b (not (brain-habit b)) (not (eq (brain-difficulty b) *br-test-diff*)))
      (setf (brain-difficulty b) *br-test-diff* (brain-delay b) (getf *ai-delay* *br-test-diff*)))))

(defun barro-debug (c)
  "His debug commands (debug.lisp *CHAR-DEBUG*, the range 82000-82999, docs/duel/DUEL_GAMEPLAY.md): 82000+k BARRO-TEST k;
82040 / 82041 *BR-TEST-AWAKE* off / on; 82050-82052 *BR-TEST-DIFF* EASY / NORMAL / HARD, 82053 off (batch 6: gate flags,
no probe line)."
  (cond ((<= 82040 c 82041) (setf *br-test-awake* (= c 82041)))
        ((<= 82050 c 82053) (setf *br-test-diff* (nth (- c 82050) '(:easy :normal :hard nil))))
        ((< c 82100) (barro-test (- c 82000)))
        (t (log-msg "duel barro: no debug command ~d" c))))
(pushnew '(82000 82999 barro-debug) *char-debug* :test #'equal)
(pushnew '(82100 82399 barro-art-debug) *char-debug* :test #'equal)   ; (the art stills, barro-art.lisp: ahead of the above)

;;; ================================================================ the HUD (barro-art.lisp's functions; not on the host)
(when (fboundp 'br-hud-meter)
  (let ((meter (list :name "SN" :max 3 :draw 'br-hud-meter :label 'br-hud-label
                     :bankai-prompt (list :key "P  REVIVE" :right "KP+  REVIVE" :pad "BACK  REVIVE" :one-hand "AWAKEN  REVIVE"
                                          :rgb (symbol-value '*c-lb-revive*)))))
    (dolist (form *br-forms*)
      (setf (kit-meter (find-kit :barro form)) meter))))
