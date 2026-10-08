# Lille Barro (利傑巴羅): how he was designed and built, a digest for the character-design playbook

Sources: `docs/duel/DUEL_LILLE.md` (3566 lines; cited as §n), `docs/DEVLOG.zh-TW.md` §84–§134 (cited as DL§n),
headers of `duel/lisp/lille.lisp` / `lille-art.lisp`, and `DUEL_SENJUMARU.md` / `DUEL_ICHIGO.md` for contrast.
Span: 2026-10-06 (request) → 2026-10-08 (decision 56 and its amendments). About 3 calendar days, 56 numbered decisions.

---

## 1. Timeline: every numbered decision

Categories: CK concept/kit, RIG rig/model, MO motion/clip, SYS system/mechanic, AI CPU/AI, BAL balance/gate,
CIN cinematic/presentation, BUG bugfix, UX controls.

Phase 0, the request and the design discussion (10-06, DL§84–§86). Request: 「先與我討論整體設計構想，並在討論期間指派 agent 建制環境」.
Each of 1–10 was an AskUserQuestion with 3 options; the rejected options are recorded (§1).

| # | Date | What changed | User's words | Cat |
|---|---|---|---|---|
| 1 | 10-06 | Role: a pure long-range sniper, the roster's weakest close range | 「純遠距狙擊」 | CK |
| 2 | 10-06 | The X-Axis goes through guard: chip 15 %, big guard-gauge drain | 「穿防但只削防禦槽」 | SYS |
| 3 | 10-06 | Jilliel's intangibility works like Yamamoto's Bankai West: U enters it, any attack drops it | 「設計成跟山本卍解相同…攻擊就解除」 | SYS |
| 4 | 10-06 | MUJITTAI: hits passing through drain the guard gauge (no refill); Breaker / unguardables land | 「穿過的攻擊削防禦槽，Breaker 能破」 | SYS |
| 5 | 10-06 | Moving, Step and Hoho keep the stance; every attack drops it | 「移動與 Step／Hoho 保留，所有攻擊解除」 | SYS |
| 6 | 10-06 | The owl is a second awakening (Kenpachi's Bankai precedent) | 「第二次覺醒（像劍八卍解）」 | CK |
| 7 | 10-06 | The left eye: 3 pips of brief intangibility; the 3rd fills EVOLUTION | 「做：3 格眼，用完第 3 格補滿覺醒槽」 | SYS |
| 8 | 10-06 | The owl entry: a revival after a beheading (Kikon leaves ≤ 4 Konpaku), Konpaku → 1 | 「被斬首後復活」 | SYS |
| 9 | 10-06 | Trompete can be reflected; a reflect breaks the halo (seals SP2) | 「反射成功還會打斷他的形態」 | SYS |
| 10 | 10-06 | The X-Axis reaches the whole arena, more damage the farther (40–120) | 「全場，越遠傷害越高」 | SYS |
| 11 | 10-06 | Colours: Jilliel's green = muted jade (an ink tone); owl gold = Senjumaru's #B89A5A (§17) | 「低彩度玉色」「千手丸的低彩度金」 | RIG |
| 12 | 10-06 | The aim lock (24 f tracking, ≥ 10 f to the shot) as designed (the adversarial review's blocker fix) | 「照設計」 | SYS |
| 13 | 10-06 | The eye needs a deliberate tap after U rested ≥ 10 f | 「U 放開 ≥ 10 f 後的點按」 | SYS/UX |
| 14 | 10-06 | MUJITTAI never refills; Jilliel's refill outside it cut 5.5 → 2.0 /s | 「…正常狀態防禦槽恢復量大減。使整體設計更容易被破防」 | SYS/BAL |
| 15 | 10-06 | No extra cost for the owl (Konpaku → 1 only) | 「不加代價」 | BAL |

Phase 1, the first build (batches 1–4 + 3b, DL§87–§91): no numbered decision; batch 4 failed wins and the awaken A/B,
the user chose 「先試玩再決定」 (§20.7). Playtest link via a private Artifact (DL§91).

First playtest rework (10-06, DL§92–§93), requested as 「請先跟我討論以下幾點後在進行修改」, 4 follow-up questions answered:

| # | Date | What changed | User's words | Cat |
|---|---|---|---|---|
| 16 | 10-06 | Revival at ≤ 4 Konpaku in any Jilliel form, no beheading (supersedes 8): the owl was unreachable in PRACTICE | 「只要魂魄數小於等於 4 就能透過 P 復活，否則在練習模式無法進入梟頭型態」 | SYS/UX |
| 17 | 10-06 | Base L = shooting stance after Ichigo's TSUKIMACHI (quick / charged shot, dash for mobility) | 「把非覺醒的 L 改成擺出射擊架式，並參照一護的架式玩法」 | CK |
| 18 | 10-06 | Jilliel's L switches EN (ranged, mobile, attacks lay damage-less traces) ↔ KIN (melee, owl legs); each switch is a flash-step dash that materialises the traces | 「覺醒的 L 會在近戰…與遠程模式…切換」 | CK |
| 19 | 10-06 | Jilliel's eight wings are the weapons; the arms are hidden in the column | 「現在的建模看起來就像是手臂變成一對翅膀」 | RIG |
| 20 | 10-06 | The owl has two long legs, each forking (reads as four) | 「不是四根高蹺般的腿，而是兩隻細長腿」 | RIG |

Second playtest (10-06, DL§94–§95):

| # | Date | What changed | User's words | Cat |
|---|---|---|---|---|
| 21 | 10-06 | Stance J = HŌSHA, a forward leap with a triple shot; on hit it links into J/K | 「向前跳飛並在空中射出連射三發短程子彈」 | CK/MO |
| 22 | 10-06 | Stance K = TAISHA, a back-slide then one mid-range shot | 「向後拉開距離打出一發中程子彈」 | CK |
| 23 | 10-06 | After the stance's HIRENKYAKU the aim snaps to the opponent | 「直接將準心重新對準對手」 | UX |
| 24 | 10-06 | Touch bug: an up-flick in the stance read as a Hoho; fixed (Ichigo's TSUKIMACHI had it too) | 「這應該算是 bug」 | BUG/UX |
| 25 | 10-06 | TENSHIN's dash much longer (lead: 8 m in / 7 m out); J/K cancel its recovery so a trace → dash → J is a combo | 「請大幅提升變換戰型後的衝刺距離」 | SYS |
| 26 | 10-06 | The legs are ㄇ-shaped (strut back, then down) | 「呈現出 ㄇ 字型」 | RIG |
| 27 | 10-06 | Translucent wings; the owl's model = KIN's + an S-neck owl head + "extra arms" | 「把翅膀調整成半透明以免遮擋視線」 | RIG |
| 28 | 10-06 | EN's J/K/SP1/SP2 startup and recovery about halved | 「前後搖都大幅縮短」 | SYS |
| 29 | 10-06 | Traces cap 8 → 16 | 「留存上限改成 16」 | SYS |
| 30 | 10-06 | TENSHIN in: 8 f wind-up from EN neutral, 2 f as a cancel out of an EN attack | 「增加約 0.1~0.15 的…前搖…大幅減少前搖」 | SYS |

Third playtest onward (10-06, DL§96–§109):

| # | Date | What changed | User's words | Cat |
|---|---|---|---|---|
| 31 | 10-06 | HŌSHA leap 3 → 5 m, bullets 6 → 3 m; TAISHA range 12 → 6 m (+ the owl's extra arm pair removed: 「多了一組手臂喔www」) | 「L > J 前跳距離加長&射程縮短」 | BAL/RIG |
| 32 | 10-06 | Wing rims translucent too; each wing 3 segments / 2 joints | 「每片翅膀改成中間加 2 節可以彎折的連接觸，讓…不會太死板」 | RIG/MO |
| 33 | 10-06 | Jilliel no longer sinks when moving: a generic kit `:lift` | 「覺醒狀態移動的時候整個角色很明顯下沉」 | BUG/RIG |
| 34 | 10-06 | TENSHIN wind-up 8 → 16 f, no cooldown, EN→KIN free, EN J/K lines cost 3 flash step, refund 2 (then 4 / guarded 2, DL§101); legs shortened by 33 fixed | 「遠程 J/K 每條軌跡消耗 3 點閃步量表…每打中一條…回收 2 點」 | SYS/BUG |
| 35 | 10-06 | EN J/K refused under 3 flash step (no free 2 f cancel off an empty swing) | 「藉由這樣設計限制 L 在沒有閃步時量表時就不能靠空揮」 | SYS |
| 36 | 10-06 | The owl runs Jilliel's whole system (EN/KIN, MUJITTAI, traces); differs by ×1.1, refund 5, +1 f advantage | 「請讓梟頭型態的系統設計完全與 Jilliel 對齊」「也是無實體」「保留反射與封印」「小」 | CK |
| 37 | 10-06 | A Hoho in EN switches to KIN (lead first read "any flash step", corrected) | 「只有 Hoho 會切換」 | SYS |
| 38 | 10-06 | The owl's EN and KIN read apart (EN floats upright, wings spread; KIN pitched, wings back); EN Trompete faster | 「目前看不出『遠程模式翼張開、站直，近戰模式翼往後收、身體前傾』」 | RIG/SYS |
| 39 | 10-06 | Laying a trace fires a 1-damage shot along it (10 f flinch, guardable) | 「軌道上會對敵人造成傷害為 1 的射擊傷害」「輕微硬直但可防禦」 | SYS |
| 40 | 10-06 | The owl's EN Trompete trace materialises with KIN Trompete's beam look | 「請改成跟近戰版本一樣」 | CIN |
| – | 10-06 | Accepted: LR 229.6 / LI 216.2 s (60 seeds), then the mirror's time-outs (DL§108–§109, §23.22) | 「接受這兩組例外」「也算進例外」 | BAL |
| – | 10-06 | CPU search: the HARD snap opener (rides 39's flinch) accepted (§24.3) | 「接受，繼續搜尋」 | AI |

Day 2 (10-07, DL§112–§132):

| # | Date | What changed | User's words | Cat |
|---|---|---|---|---|
| 41 | 10-07 | 39 undone; traces snap ≤ 10° toward the opponent on materialise; stepping onto a trace slows the whole match (0.35 for 0.3 s, 30-step re-arm) | 「C+對手經過軌道的瞬間會有時緩」「全場慢動作」 | SYS |
| 42 | 10-07 | TENSHIN in 8.0 → 10.4 m (×1.3) | 「能跳躍的範圍要提升 1.3 倍」 | SYS |
| 43 | 10-07 | TENSHIN out 10 m / in 13 m; the K → L chase bug fixed; slow motion 0.1, every crossing (lead first read 「放慢 1 倍」 as 0.5) | 「後撤距離提升到 10m…這應該是 bug？…時緩改成放慢 1 倍」 | SYS/BUG |
| – | 10-07 | Accepted LR 217.5 s (60 seeds) | 「可以接受」 | BAL |
| 44 | 10-07 | Close traces slow once: all traces one region, fires after ≥ 10 sim frames off | 「用 A，N 先用 10 f」 | SYS |
| 45 | 10-07 | Fresh trace on him always slows (0.1 / 0.3 s); old traces 0.3 for 1 s | 「如果是才剛新生成的軌道就算重疊也一樣觸發時緩」 | SYS |
| 46 | 10-07 | Retimed: fresh 0.1 / 0.1 s, old 0.3 / 0.3 s | 「再稍微換一下時緩參數」 | SYS |
| 47 | 10-07 | Retimed: fresh 0.1 / 0.2 s, old 0.2 / 0.5 s | 「再稍微換一下時緩參數」 | SYS |
| 48 | 10-07 | dream-rsi round 1 closed; b3a2 (the most varied style) ships as the HARD CPU; integrate next | 「直接進入整合」「b3a2 風格最多樣」 | AI |
| 49 | 10-07 | TENSHIN 3 m shorter both ways: in 10, out 7 | 「近遠切換移動距離減少 3m」 | SYS |
| 50 | 10-07 | Jilliel's strikes redone, EN and KIN: whole body, per-strike shapes, tip trails, eight wings converge | 「近戰的動作不太明顯，能跟我討論…」「全身出招」「每招獨立造型」「翼尖斬痕」「八翼一起斬」 | MO |
| 51 | 10-07 | Keep the HARD learner's HOSHA-guard read and the failing awaken A/B as they are | 「兩個問題都維持現狀就行」 | BAL/AI |
| 52 | 10-07 | TENSHIN in 4.5 m, a trial | 「幫我試試看…改成 4.5m」 | SYS |
| 53 | 10-07 | TENSHIN at fixed 30 m/s, stops 1 m short; in = 2 Steps + 0.5 m, out = 2 Steps; its J/K link no longer chases | 「完全拿掉追擊…移動改成固定速度而不是固定時間」 | SYS |
| 54 | 10-07 | TENSHIN in up to 7 m | 「將前衝距離改成最多 7m」 | SYS |
| 55 | 10-07 | No retune: low NORMAL wins (LI 2/20) and the CPU score's drift fail accepted | 「不用調整，玩起來夠強了」 | BAL |
| fix | 10-07 | ASSIST's TENSHIN in → J1 link (two regressions of 53) (§23.36) | 「好像是輔助連段的問題？我自己操作是能連的」 | BUG |

Day 3 (10-08, DL§133–§134):

| # | Date | What changed | User's words | Cat |
|---|---|---|---|---|
| 56 | 10-08 | The owl's KIN/EN J/K redone (raptor claws, gold claw trails, wing beat, eight-wing converge); Jilliel's SP1/SP2/Kikon and the Kikon cinematic redone (storyboard by the user) | 「猛禽爪擊」「全身出招」「金色爪痕」「金翼振翅」「八翼匯聚」「全改，含過場運鏡」 | MO/CIN |
| 56a | 10-08 | Kikon cinematic: Lille drawn ×3 in beats 4–6 (CINE-SCALE) | 「如果改成縮放模型大小來達成「對手小、利捷大」的效果呢？」 | CIN |
| 56b | 10-08 | Kikon cinematic: 40 f opening, the 3 first hits slowed 1/5, 1/3, 1/2 (CINE-SLOW), 305 f | 「第三幕「起射」過的太快…第一幕也幫我拉長時間」 | CIN |
| 56c | 10-08 | Kikon cinematic: actors placed 6 m apart (CINE-PLACE); desktop camera tilted above the letterbox | 「應該進入毀魂技過場動畫時就要先調整演員的位置才對」 | CIN/BUG |
| – | 10-08 | Gate match time excludes every cinematic (DL§134), prompted by the longer Kikon | 「毀魂技演出不計入對戰時長」→「所有過場」 | BAL |

Tally by primary category (56): SYS 30, CK 7, RIG 7, MO 2 (+3 shared), CIN 2 (+3 amendments), BAL 4, AI 1, BUG 2 (+3 shared), UX 2 shared.

---

## 2. Rework hot-spots (aspects changed more than once)

### A. TENSHIN (the EN ↔ KIN switch dash): distance, speed, tempo, price. The longest chain.
- v1 (decision 18, §22.2): 3.5 m in / out over 12 f, 30 f cooldown, 10 flash step.
- v2 (25, §23.2): "much longer": lead picked in ≤ 8 m stopping 1.5 m short, out 7 m, 14 f; J/K cancel its end; the
  latched link **chases** (Breaker J1/K1 rule, ≤ 40 m/s). Rejected v1: too short to use the traces.
- v3 (30): wind-up depends on where it starts: 8 f from neutral, 2 f as an EN cancel.
- v4 (34): neutral wind-up 16 f, no cooldown, EN → KIN free, KIN → EN 10; traces cost 3 FS a line, refund 2 → 4 (DL§101).
- v5 (35): EN J/K refused under 3 FS. Rejected v4: an empty swing bought the 2 f cancel for free (an exploit the user found).
- v6 (37): a Hoho in EN switches to KIN (Step was the lead's over-reading).
- v7–v9 (42, 43, 49): in 10.4 → 13 m, out 10 m → back to 10 / 7 m. Feel-tuning by playtest.
- v10 (52): in 4.5 m trial. The shorter dash changed nothing, because the hidden chase from v2 still carried J1 from ~11 m.
- v11 (53): asked "why does J1 after the dash also dash forward?": **fixed speed 30 m/s**, stop 1 m short, distances in
  Step lengths, no chase on its link. Rejected v2's chase: it made the dash length meaningless.
- v12 (54): in 7 m. 55: accept the lower win rate. Then the §23.36 fix: decision 53 broke the ASSIST link (stale dash
  end, a dash shorter than the 6 f form change).
- Side bug (43): an L latched in a KIN K string was a chained follow-up, so the engine's string chase pulled him forward
  during the dash's startup (a 7 m back dash measured 0.88 m).
- **Cost**: about 13 decisions (18, 25, 28, 30, 34, 35, 37, 42, 43, 49, 52, 53, 54, 55) plus 2 bug fixes; ~11 twenty-seed
  six-pairing gates, ~5 aieval runs, the CPU's web band re-pinned 5 times, and the drift check broken (accepted at 55).

### B. The crossing slow motion (how a trace catches the opponent, as feel)
- 41: 0.35× for 0.3 s, a 30-step re-arm, per trace.
- 43: "放慢 1 倍": the lead's 0.5 was wrong; the user meant 0.1, every crossing re-triggers.
- 44: close traces fired in a chain: all traces became one region with a 10-sim-frame "off" count (the step-counted
  re-arm also ran inside the slow motion, ~18 steps per slow).
- 45: fresh traces always slow (0.1 / 0.3 s), old ones 0.3 / 1 s.
- 46, 47: retimed twice: fresh 0.1 / 0.1 s → 0.1 / 0.2 s; old 0.3 / 0.3 s → 0.2 / 0.5 s.
- Why the earlier versions went: each was judged only by feel in play; the trigger semantics (per trace, region, fresh vs
  old) were never specified up front; and the wording was ambiguous.
- Side effect: the gate timed real time, so each slow motion added seconds and shifted step quantisation, which moved
  win counts. LR / LI kept crossing 210 s, and each crossing needed a 60-seed rerun and a report.
- **Cost**: 6 decisions, 7 twenty-seed gates, about 6 sixty-seed reruns, 1 accepted exception, and 2 CPU-search
  re-freezes (44, 47) plus a restart (41–43). Every round-1 cell was 3-way-merged and re-measured each time (§24.4–§24.6).

### C. How traces get hit: damage-less traces → laying shot → snap + slow motion
- 18: traces deal nothing until L materialises them.
- 39: a 1-damage laying shot with a 10 f flinch made landing them easy.
  - It pushed LR / LI past 210 s (exception accepted).
  - The dream-rsi search found an "almost unreactable" HARD opener on it (J1 nick → 2 f cancel → materialise → KIN
    string) (§24.3).
- 41: the shot was removed (「我希望去除掉軌道設置時造成的 1 點傷害，但這樣的話有會很難讓實體化能打中對手」). The replacement is a
  ≤ 10° snap toward the opponent plus chain B.
- Why 39 was rejected: a chip shot on every trace is a hidden stun-lock, and the opener it gave was unfair.
- **Cost**: 3 decisions, 1 exception accepted and then made moot, and CPU search v1 archived.

### D. The base form's L (the sniper's identity)
- Design (decision 1, §4.3): L held to aim, a 24 f lock, a whole-arena shot for 40–120, the K → L snap shot.
- Batch 4 (§20): every NORMAL opponent rushed him.
  - He spent 83–93 % of the time under 6 m and never fired from ≥ 14 m; his wins were 3–7 of 20 and the awaken A/B 0–4 of 60.
  - Probes: ×1.6 damage or ×0.7 taken did not fix it.
- 17 (§22.1): a stance after Ichigo's TSUKIMACHI: quick / charged shot, REIKYORI, NAGIHARAI, a HIRENKYAKU dash.
- 21–23 (§23.1): HŌSHA (leap + triple shot that links), TAISHA (back-slide shot), the aim snap.
- 31: HŌSHA leaps farther and shoots shorter; TAISHA shoots shorter.
- Why v1 failed: a pure sniper with no escape (decision 1 explicitly refused "long range + strong escape") cannot hold
  range against an all-rushing roster. The user turned the identity into "mobility between melee and range".
- **Cost**: 4 decisions, two full rule rebuilds (rework R, round 2), the base CPU rewritten twice, and §20's whole tuning
  batch (two knobs kept, two measured and put back because they contradicted decisions 12–13).

### E. Jilliel's wings (rig → look → motion)
- Batch 1: the front wing pair was the rig's arm chain (×2.6) and the other six were static parts.
- Batch 3b: drawn from the references, but still the arms-as-wings structure.
- 19 (§22.5): eight independent blades in two fans of four, the arms not drawn; a striking wing is drawn root → rig hand.
- 27 (§23.5): see-through glass at 0.35 with an opaque rim.
- 32 (§23.9): see-through rims; three jointed segments; idle wave, lag/whip springs, MUJITTAI curl, SP unfurl.
- 50 (§23.31): every strike its own whole-body shape; EN gets its own casts; jade tip trails; the six table wings converge.
- 56 (§23.37): SP1 / SP2 / Kikon: the ring, recoil and verdict.
- Why each earlier version went:
  - "arms became a pair of wings, the other three pairs hang stiffly";
  - "the wings hide the fight";
  - "too stiff";
  - "the melee moves don't read" (only the front pair swung, the legs stood still, EN reused KIN's clips sped up).
- **Cost**: 5 decisions over 3 days. Every round was presentation-only (byte-identical gates), so the cost was art
  batches and stills, not gate time.

### F. The owl's body
- Model sheet: four stilt legs (read from the reference images).
- Batch 3b: hind stilts.
- 20: two legs, each forking. 26: ㄇ legs.
- 27: the owl = KIN's model + S-neck + extra arms. The lead added a second cosmetic arm pair; the user laughed it off
  (「多了一組手臂喔www」). "Extra" was relative to KIN, which draws no arms, so one pair (§23.7).
- 33/34 side effect: the lift shortened the legs.
- 38: EN and KIN silhouettes. The owl's lift is 0.35, not 0.5, or its head goes under the HUD. KIN's wings sweep back
  *and down*, or they loom in the behind camera.
- 56: the owl strikes redone.
- Why the earlier versions went: a misread reference (stilts vs forked legs), ambiguous relative wording, and two modes
  that looked the same.
- **Cost**: 6 decisions plus 1 correction, all presentation-only.

### G. The owl's system
- Design: its own kit (U a plain guard, the SABAKI L, Trompete, ×1.2, walk 4.0). Entry: beheading (8), then simply
  ≤ 4 Konpaku (16).
- 36: Jilliel's whole system.
- 38, 40: the EN Trompete's speed and look. 56: its motion.
- Why: once Jilliel had the two-mode system, a separate owl kit read as a different character. The user wanted one system
  with stronger numbers.
- Decisions 8 and 15 ("the owl trades defence for attack") were superseded.
- **Cost**: 4 decisions and a full owl rebuild (§23.15: four new forms, new moves, 425 new host checks).

### H. The revival condition
- 8 (beheading by a Kikon) → 16 (≤ 4 Konpaku). Rejected: PRACTICE mode could not reach the owl, so it could not be
  playtested. 1 rework.

### I. The Jilliel Kikon cinematic (inside decision 56)
- 162 f → storyboard 210 f → giant ×3 → slow-motion first shots, 305 f → CINE-PLACE / letterbox fix.
- 4 iterations in one day, each prompted by the user watching. The framing broke on desktop because the shots were
  framed at the stills' 6 m but a Kikon lands from any distance.

### J. Smaller loops
- Float / lift (33 → the legs-floor fix in 34 → the owl's lift in 38).
- Gold #B89A5A: a subagent "fixed" it to #CDB47A against decision 11; the lead restored it (§21 dev. 4); 27's glow made
  it read gold.
- MUJITTAI's dark phantom (§21 dev. 3 → glass glow in §23.5; the column is still the 0.72 phantom).

---

## 3. For each hot-spot: the question that would have saved the churn, and when to ask it

| Hot-spot | The unknown design intent | The question to ask | When |
|---|---|---|---|
| A TENSHIN | Where he lands relative to the opponent after a gap-closer, by what motion model, and whether the follow-up may travel | "After the dash, how far from him should he stop? Fixed time or fixed speed? In Step lengths? Should the J after it move him?" Also: "list every hidden movement on this move" (chase, lunge-stop, string chase) | Design pass, for any dash or teleport move; recheck the moment a follow-up link is added (25) |
| A, the price | What paces the switches (cooldown, gauge, wind-up) and which cancel could be exploited | "What stops him spamming it? Can an attack cancel skip its wind-up for free?" Run an adversarial pass on every cancel route | Design pass; again whenever a cancel is added (30) |
| B Slow motion | What it is for (a cue, or real time to react) and its trigger unit (per line, per region, fresh vs old) | "Is it a signal or a reaction window? One per crossing or one per approach? Do overlapping lines count once?" Then expose the numbers as live knobs (a debug menu or URL params) so the user tunes feel in play rather than through gate cycles | Before building any feel effect; and before any time-scaled effect touches the gate clock |
| B, wording | 「放慢 1 倍」, "extra arms", 「閃步」 were all ambiguous | Restate the reading as a number ("0.5× speed?") and get a yes before building | Every request with a relative or colloquial quantity |
| C Traces landing | How a materialised trace is supposed to hit: the opponent's mistake, Lille's prediction, or a hold | "When should a trace reliably hit, and what should the opponent do about it?" | Design pass of decision 18, before the economy |
| D Base sniper | What a sniper does with someone in his face, against a roster of rushers | "When he's caught at 2 m, what does he do?" Probe it with a quick sim (time at range) before tuning numbers | Concept stage (decision 1). Batch 4's distance histogram was the evidence; it could have been a 10-seed probe in batch 1 |
| E Wings | What strikes and what the arms do, how the strikes read from the default camera, whether big translucent parts hide the fight | "Which part hits? Are the arms visible? From behind him, should we still see the opponent?" Show a still from the behind camera with one strike at its hit frame | Model sheet / rig stage, before batch 1's functional art fixes the structure |
| E motion | The motion-language bar ("each strike its own shape, whole body") | "Should each strike have its own silhouette and body motion, or one swing reused?" Agree on a reference (here: Jilliel's later J/K became the bar for 56) | Before the art batch; set the bar once for every form |
| F Owl legs | The leg topology from the side | Show a side-view sketch or still of the legs and ask "is this the structure?" | Model sheet review, before the art |
| G Owl system | Is each awakening a different system or the same system upgraded? | "Does form 3 play like form 2 with bigger numbers, or like a new kit?" | Concept stage, right after a mode system is chosen (18) |
| H Revival | Can every form be reached in PRACTICE / debug? | "How does a playtester get to this form in practice mode?" | Design pass of every conditional form |
| I Cinematic framing | Fixed or variable distance between the actors; landscape vs portrait | "Where are the actors when it starts?" Place the actors first (CINE-PLACE) and check both aspect ratios | When storyboarding any Kikon |

The common thread: the user judged by **feel in play**. The decisions that changed four or more times are feel
parameters (distances, durations, slow-motion scales) or silhouettes. Ask about intent and units; don't predict the
numbers.

---

## 4. What worked well (the user's "most satisfying" character)

**Process patterns**
- **Discuss before building.**
  - Phase 0 was a pure design discussion while subagents set up the cloud toolchain, the research and the roster plumbing
    (DL§84).
  - Decisions 1–10 were AskUserQuestion with three options each, the rejected ones written down.
  - The user adopted the pattern too (「請先跟我討論以下幾點後在進行修改」 at 16–20, 「［討論］」 at 44, 「請先跟我討論完後再修改」 at 53).
- **Present 3–4 directions with letters.**
  - 41: A pierce mark / B 0-damage flinch / C snap / D slowing zone; the user combined C with a slow motion.
  - 44: A/B/C/D.
  - 50: four directions, all chosen.
  - 56: style choices plus four extras.
  - The user often picks "all" or combines them, so offer composable options.
- **Explain the cause before offering fixes.** 53 began as "why does J1 dash forward?". The lead explained the hidden
  chase and offered four answers; the user then rewrote the rule.
- **A full written design pass with an adversarial review before code** (§2–§16, 22 findings). It caught a blocker: the
  aim kept tracking after release, so a Step could not dodge at 12–20 m. The lock rule came from it, and so did the
  eye's rest rule (a reactive guard would have spent the pips).
- **Canon research plus a model sheet from 49 reference images** (§17, DL§84). It corrected the cloak, Diagramm and the
  eye mark before any art. The user fixed the colour decision from the contact sheets (11).
- **Playtest loop**: the whole game was published as a private Artifact (DL§91) and updated each round. Commit and push
  went out per milestone; deploys only on request (4 times: DL§115, §120, §130, §132).
- **"Proposals until the gate"**: the lead picked the numbers the user didn't give, labelled them "the lead's, the user
  may move them", and stated its readings (「鬼機會」 → 「軌跡會」). The user could correct cheaply (37, 43).
- **Text storyboards for cinematics**: the user wrote shot lists in prose; the lead turned them into beat tables with
  frames; a shot-by-shot breakdown led to amendment 2.
- **Gate discipline without tuning**: failed gates were reported and other knobs left alone. The user decided:
  「先試玩再決定」, the accepted exceptions, 「不用調整，玩起來夠強了」. Balance followed the user's play, not the window.
- **Worktree fan-out with a lead merge**:
  - batch 1 ‖ batch 2 (AI perception);
  - rework R (rules) ‖ rework A (rig);
  - round 2 rules ‖ art;
  - decision 32 art ‖ 34 rules;
  - decision 56 owl ‖ Jilliel SP. Its merge hit one real conflict: both batches claimed `*LB-WF*` [64]–[66] (§23.37).
  - The lead re-ran every gate after each merge and fixed what the batches missed: the K fan hitting three times (72 for
    one K), the damage tag, the extra ECS lookup.

**Design patterns**
- **Reuse an existing system's shape**:
  - MUJITTAI = Yamamoto's West ward plus one `:intangible` flag;
  - the base stance = Ichigo's TSUKIMACHI;
  - the revival = Kenpachi's Bankai path plus `:bankai-ok`;
  - the eye = the perfect-Hoho threat test.
  - Each reuse is cheap to build, inert for the rest of the roster, and already balanced by precedent.
- **Two modes EN / KIN on one button**: EN lays damage-less traces while walking; L materialises them and dashes. The
  result is a lay → materialise → dash → J combo (the trace stun ≥ dash + J1, host-tested) and a ranged/melee pendulum.
  The CPU search found it on its own (b3a2's KIN → EN → KIN crossfire).
- **Trace laying + materialise**: delayed damage the opponent can read and step off (the opponents' `:opp-trace`
  reflex). The snap (≤ 10°) and the slow motion help a human time it.
- **The stance** as a mobility hub: J leaps in (HŌSHA), K slides out (TAISHA), Step dashes (HIRENKYAKU) with the aim
  snapping back, L shoots. A sniper that moves.
- **The transform chain base → Jilliel → owl**: the 3-pip eye forces the first awakening; ≤ 4 Konpaku allows the second.
  The owl uses the same system with small edges (×1.1, refund 5, +1 f).
- **A flash-step economy** paces the switches: lines cost 3, a hit refunds 4 (5 for the owl), a guarded one 2;
  KIN → EN costs 10. It also pays Step and Hoho, so the CPU keeps a reserve of 10.

**Technical patterns**
- **Character in two files** plus generic, inert hook points (`:vols`, a cap yaw, `:uncatchable`, `:intangible`,
  `:settled`, `:bankai-ok`, `:body-alpha`, `:charge`, `:lift`, `:clip-map`, `:assist-combo`, `:step-branch`, CINE-SCALE /
  -SLOW / -PLACE). Every change was proven inert by the fifteen old pairings being byte-identical plus G2.
- **Presentation-only changes with byte-identical sim gates**: §22.5, §23.5, §23.9, §23.19, §23.31, §23.37 each re-ran
  `--seeds 10 --summary` and `--cvc` and checked them identical. Art iterations cost no balance time. When a cinematic
  changed match seconds, a run with the old `:len` proved the outcomes identical (§23.37).
- **Clips authored at their own frames**: EN's casts (`:lb-e-*`, `:lb-oe-*`) replaced KIN clips sped up with `:clip-s`.
  Each key is written as an aim (azimuth and elevation in the chest frame) with a comment.
- **The wing rig**: three-segment blades with joint frames tilted per segment (`%LB-TILT!`).
  - Damped lag springs (ω 16, ζ 0.45) driven by tip speed plus a virtual strike drive (cock back, zeroed straight on the
    active frames, overshoot).
  - Rodrigues turns the chain so the drawn tip **is** the rig hand (miss 0.00000 m).
  - Convergence of the other wings on a target ring; tip trails via VFX-SMEAR in jade; claw trails as three streaks.
- **Drawn reach = hit reach**: the FK reach test ±0.15 m on every J/K. A **cast check** covers moves with no hit window
  (the tip at `:reach` on S).
- **`:clip-map`**: a form plays a different clip for a shared move (KIN SANREN → the wing clip), and the sim never sees it.
- **Cinematic tools**:
  - CINE-SCALE: an actor drawn ×3, the rig scale multiplied, everything written in metres scaled by hand;
  - CINE-SLOW: actor clips and effect time scaled, script frames run on;
  - CINE-PLACE: the actors placed at a fixed gap and given back at CINE-END however the cinematic ends.
- **Debug still ranges**:
  - 79100 + 19i + k (cinematic i at frame 10k), 79200 + f (one cinematic at frame f);
  - 79195 the consing probe, 79196–79198 looks, 79014–79018 forced forms, 2109 the side camera;
  - contact sheets and before/after strips in the scratchpad, never committed.
- **0 B/frame draws**: f32vec scratch, DEFUN-FAST, macros, pre-boxed alphas.
  - 16 B/frame remained as the engine's ECS-lookup floor (documented, not fixed).
  - Found and fixed: a REPLACE-on-itself allocation in the trail (184 B → 0), and a second ECS lookup (24 → 16 B).
- **Browser scripts as measurement**: the K → L bug was proven at 0.88 m vs 10.0 m with `tools/run.mjs` and hash lines;
  TENSHIN's 4.99 / 5.5 m; the ASSIST route traced in the combat log.
- **Host tests that pin combo arithmetic**: bullet frame + stun > link startup, trace stun ≥ dash + J1 on both wind-up
  paths, one hit per fan group.
- **dream-rsi CPU**: the evaluator is frozen first (score 0.4 strength / 0.2 masher / 0.4 signature, signature a
  whitelist, a NORMAL drift gate). New behaviour is HARD-only, so NORMAL stays bit-identical. A marked LILLE-CPU-TESTS
  section is spliced into the frozen host test.

---

## 5. Modelling notes

**Bodies and rig** (`lille-art.lisp` header, §21, §22.5, §23.5)
- Four bodies on the fixed 21-joint humanoid:
  - `:lille` (182 cm, skin #7A6155, bicorne, stole, the eye mark);
  - `:lille-jilliel` (holed cream column, face window, no arms drawn);
  - `:lille-jilliel-kin` (the column from the hips up on ㄇ legs);
  - `:lille-shin` (KIN's model in white #ECECE8, a 5-segment S-neck, a barn-owl face, rig arms ×2.2, gold wings).
- **Fairness floor**: the hurt cylinder is r 0.38 / h 1.8 in every form; caps, wings, halos and the neck add none. The
  float is visual (the hurt cylinder stays on the floor).
- **Floating lift**: first written into his own clips. The shared `:sh-*` clips (walk, Step, Hoho, hit) play at root 0,
  so he sank whenever he moved.
  - Fix: the kit key `:lift` (0.5 Jilliel, 0.35 owl EN, 0 owl KIN). Drawn only while he wears the form's own `:body`, so
    the awakening cinematic's base body stays grounded. His clips were rebased −0.5.
  - Side bug: the leg floor read the lifted feet height, so the legs shrank. The fix subtracts BODY-LIFT.
- **Arms hidden in the column**: the rig keeps ×2.6 arms whose hands are the strike points. A striking wing is drawn from
  its root to the hand, so the FK reach test still reads the hand.
  - Lesson from batch 1: parenting the *visible* weapon to the arm chain made "arms that look like wings".
  - Keep the rig's strike point invisible and draw the weapon to it.
- **ㄇ legs**: drawn by the draw hook in the thigh frame: a front shank down, a strut back, a rear shank down.
  - Each shank's length is solved to meet the floor (clamped 0.45–1.35 of rest; a knocked-down leg keeps its rest length).
  - Works across floats (0.5, a 0.7 K3, a 0.3 Breaker); the owl's stance thighs were squared so the strut stays level.
- **Translucent jointed wings**: the engine's alpha < 1 path drew a dark phantom.
  - Fix: an emissive glow × own colour (no shader change). Glass 0.35 with the holes cut through, rim 0.6, MUJITTAI
    0.18 / 0.3.
  - Each blade has 3 segments (15 meshes in all); holes and teeth were redistributed so none straddles a joint.
- **The owl's S-neck and claws**: the claw keys in 56 were *solved* from the owl's FK (a target claw position →
  flex / side / elbow), not hand-tuned (§23.37).
  - The same idea as `tools/pose-solve.py`, which RAVEN EDGE introduced for blade angles (DL§8); Lille's docs don't
    name the script.
  - A long arm near the body needs a deeply bent elbow.
- **Drawn reach = hit reach**: FK ±0.15 m on every J/K of all forms; the EN cast check for traces; the lead re-measured
  every art round (e.g. KIN J1 1.65 vs 1.60, owl KIN K3 2.24 vs 2.30).

**Pitfalls hit**
- **Stance poses move strike points**: the owl's new pitched KIN stance (38) would have moved the hands on hit frames.
  The hit poses now set spine, the striking arm and both elbows themselves (§23.19).
- **Spins and root yaw**: a full turn needs two keys 0.0001 f apart with yaw 360° apart, so the clip starts and ends at
  yaw 0 without unwinding (§23.31).
  - The lag springs counted fast tips as a cut (> 1 m/frame); Jilliel's jump threshold was raised to 2 m.
  - The convergence target takes the clip's root offset and turn out, so a spin doesn't move the target.
- **A form lift change inside a dash**: the form flips mid-TENSHIN (f6 / f22), so the lift steps 0.35 m. The clip keys
  hide it (u 0.05 at f6.5 and similar) (§23.19).
- **Letterbox vs portrait framing**: phone looked right, desktop lost the opponent under the bottom bar (9 %). Fix: the
  landscape camera tilts so the head sits ≤ 0.35 half-height below centre (§23.37).
- **Distance-dependent cinematic framing**: the shots were framed at the stills' 6 m, but a Kikon fires from any distance.
  CINE-PLACE puts the actors 6 m apart and gives the place back.
- **Scaling an actor**: anything authored in metres (wing lengths, legs, floor, flashes) must take the scale by hand. The
  joint matrices carry it.
- **Big translucent / foreground parts vs the camera**: KIN's wings straight back loomed in the behind camera; the owl's
  converging wings face-on covered the strike (turned edge-on); a first trail at VFX-SMEAR's own numbers was a "jade plank".
- **The reticle at the wall end** is off screen at 20–30 m: it moved to where the opponent stands on the line (§21 dev. 1).
- **Subagent "improvements" that override a user decision** (#CDB47A gold): the lead must diff against the decision list
  at merge.

---

## 6. Gameplay-system notes

**The kit's systems** (final state)
- **Base**:
  - the eye (3 pips, deliberate tap, 16 f intangible, the 3rd → EVOLUTION);
  - L = the stance SOGEKI-GAMAE: quick 40 / charged 40–120 X-Axis shot locked on press, J HŌSHA, K TAISHA, Step
    HIRENKYAKU (once per stance, aim snap);
  - SP1 SANREN, SP2 HIRENKYAKU + shot, O lane Kikon (2).
- **X-Axis rule**: through guard (chip 15 %, drain 30), `:uncatchable` (KASA can't catch it), goes through summons and
  hazards; stance, armour and DRINK unchanged.
- **Jilliel EN / KIN** (+ two MUJITTAI forms):
  - L TENSHIN (wind-up 16 f / 2 f cancel, 30 m/s, in ≤ 7 m stopping 1 m short, out 5 m);
  - EN mobile J/K/SP lay traces (≤ 16, 3 FS a J/K line); materialise with a ≤ 10° snap, a stun with no knockback;
  - the crossing slow motion (fresh 0.1 / 0.2 s, old 0.2 / 0.5 s, one region, 10 sim frames off);
  - Hoho EN → KIN; U MUJITTAI in both modes (ward + `:intangible`, no refill, refill 2.0 /s outside).
- **The owl**: four forms on the same system; ×1.1, refund 5 / 2, +1 f; SP1 審判光明, SP2 Trompete (reflectable on a
  Hoho f48–59 or a guard f50–58; a reflect seals SP2 for the match); Kikon 4.
- **Revival**: P in any Jilliel form at ≤ 4 Konpaku → owl EN, Konpaku 1, Reishi full, once. Kikons 2 / 3 / 4.

**Interaction with the CPU**
- **Perception gap G1**: the generic threat test and Kenpachi's / Ichigo's reflexes were written for ≤ 12 m. A 31 m line
  would have made every CPU guard through each aim.
  - Fix: point-to-line distance and the real active window, for `:x-axis` moves only, so the old pairings stay identical.
  - Also: the per-character timed perfect Hoho skips reflectable moves, or Ichigo's HARD p 1.0 would reflect every
    Trompete.
- **His reflexes** (§19, §22.4, §23.4, §23.12): the eye replaces the guard reflex; the stance is a reaction only, left by
  attacking (whiff, 180 f, gauge < 30, idle); the stance's plan rolls once at f6; EN switches on traces; KIN switches out
  after a string; the CPU keeps a flash-step reserve (10); the starved switch.
- **Opponent keys read off his kits**: `:opp-aim` (later removed), `:opp-reflect`, `:opp-trace`.
- **The dream-rsi CPU** (§24):
  - frozen evaluator; 12 cells in round 1; the score saturated from the a1 refines (0.995–0.9996);
  - picked by held-out wins and style: b3a2, the most varied (HOSHA loop ~40 %, trace combos ~24 %, X-Axis ~34 %);
  - 3 re-freezes because the rules changed mid-search (41–43 restart, 44, 47), each cell 3-way-merged;
  - the evaluator's drift reference went stale after 53–54 (accepted at 55).
- **ASSIST AUTO COMBO** (§24.10): a generic `:assist-combo` hook; his CPU picks the route on the player's J.
  - HOSHA → K1 → the stance loop; EN J → 2 f cancel → TENSHIN → J1 K2s K3; KIN K3 → crossfire out/in.
  - Assisted traces ×0.8 (`LB-AS-TRACE-MULT`, since a hazard hit has no move).
  - The masher now reads its vpad as a human's (`LB-TICK-BRAIN`).
- **Learning CPU** (§24.9): a new generic kit-situation model (`learn-def-kit`, storage format 3) with three Lille
  situations:
  - which way the human steps off a trace;
  - his answer to the TENSHIN wind-up;
  - his answer to HOSHA.
  - At NORMAL the learner beats the plain CPU by 6–22 points; Lille's own situations are small and noisy.
  - At HARD the HOSHA-guard read costs damage (646 vs 605, still all wins), kept by 51.

**Gate exceptions accepted** (AGENTS.md)
- LR 229.6 s, LI 216.2 s (60 seeds) after the laying shot. The shot is gone since 41: LR 200.0 at 20 seeds, LI 212.1 at 60.
- The mirror's time-outs.
- LR 217.5 s (60 seeds) after the 10 m back dash and the 0.1 slow motion.
- The awaken A/B rows (the never-awaken side 3–18 of 60) and the HARD HOSHA-guard read (51).
- Lille's NORMAL wins after the 7 m TENSHIN (LI 2/20) and the CPU score's drift fail (0.34 vs 0.44) (55).
- Plus: the HARD snap opener (§24.3, later moot) and 「先試玩再決定」 on batch 4's failures.

**Bugs that came from interactions**
- Touch: the onehand rule "an up-flick during a move is a Hoho" vs a stance that is a move. Fixed with a generic
  `:step-branch` flag; Ichigo's TSUKIMACHI had the same bug (24).
- K → L: a latched L in a K string became a chained follow-up, and the engine's string chase ran during TENSHIN's
  dash startup. Fix: `lb-switch-tick` zeroes walk/chase every frame (43).
- TENSHIN's link chase made the dash distance meaningless (52 → 53).
- ASSIST after 53: a stale dash end read during the 2 f cancel's wind-up, and a dash shorter than 6 f ended before the
  form change. Fixes: `lb-link-frame-at`, the form changed before `lb-link-tick`, `lb-link-form` (§23.36).
- The K fan's three traces hit at once (72 for one K): one hit group (lead merge, §22.6).
- The lift shortened the legs (34). The empty-swing 2 f cancel exploit (35).
- Slow motion vs the gate: the gate timed real time, and the slow motion shifted step quantisation, so win counts moved
  (§23.25). The longer Kikon cinematic added match seconds, which led to DL§134: gate times exclude cinematics.
- aieval's K.O. rule ("< 299.5 s") counted Lille's long matches with cinematics as time-ups; Lille's scoring reads
  Konpaku instead (§24.2; a latent bug for the others).
- The generic ORANGE burst broke the HOSHA loop. Cells patched it locally ("composure"); an ORANGE kit key was
  recommended for shared code.
- b3a2's knobs were defined after the functions that read them (11 ECL style warnings); they were moved up (§24.8).

---

## 7. Numbers

- **Decisions**: 56 numbered (1–56; 11 is the colours, in §17) in 3 days.
  - 10-06: 40 (1–40). 10-07: 15 (41–55). 10-08: 1 (56, with 3 amendments and a fix).
  - Plus about 8 unnumbered user rulings: 「先試玩再決定」, the snap opener, 3 exception acceptances, the refund 4 / 2
    (DL§101), the ASSIST fix, gate times without cinematics.
- **Design-intake**: decisions 1–15 before any code (10 AskUserQuestions in the discussion, 4 on the design review).
  Then 41 decisions (16–56) after playtests.
- **DEVLOG**: 50 sections (§84–§133) plus §134 (the gate rule it prompted). 4 of them are deploys (§115, §120, §130,
  §132), 2 are exception acceptances only (§108, §109).
- **Accepted gate exceptions**: 5 entries in AGENTS.md (LR/LI after 39; the mirror's time-outs; LR 217.5; the A/B + HOSHA
  read; NORMAL wins + drift).
- **Gate runs (approx.)**:
  - ~28 twenty-seed runs of his six pairings;
  - ~12 sixty-seed edge reruns;
  - 4 awaken A/B sweeps (15 cells each);
  - 2 revival-gamble tests;
  - ~10 aieval runs;
  - the dream-rsi round of 12 cells plus 2 baselines × 3 re-freezes;
  - 3 assistgate runs; 1 learning-gate matrix.
- **Tests (host duel-rules checks)**: 4431 before him (DL§84) → 5016 (AI perception) → 5714 (batch 1) → 5722 → 5914
  (rework) → 5938 → 5942 → 6367 (the owl on Jilliel's system) → 6370 → 6388 (b3a2) → 6394 / 6405 / 6411 (integration)
  → 6435 (Jilliel strikes) → 6479 (decision 56). **+2048 checks.**
  - learn 100 → 131; duel-control 86 → 89; cine 18 unchanged.
- **Code**: `lille.lisp` 748 → 3434 lines; `lille-art.lisp` 527 → 3261. The design doc is 3566 lines.
  - Git log: 137 commits mention Lille / Jilliel / TENSHIN.
  - Debug range 79000–79999 (79000–79018 setups, 79100–79199 cinematic stills, 79195–79198 probes and looks,
    79200–79599 the Kikon cinematic by frame).
- **Forms**: 10 kit forms (base; Jilliel EN / KIN × stance; owl EN / KIN × stance), 4 bodies, 5 cinematics
  (Jilliel Kikon 162 → 305 f).
- **Win-rate path** (NORMAL, wins of 20 vs Y/K/R/I/S):
  - batch 1: 1/1/0/3/0 (of 10);
  - batch 4: 7/3/3/5/5;
  - rework: 6/2/2/3/4;
  - round 2: 8/9/5/8/8;
  - the owl system: 14/6/6/5/6;
  - decision 41: 10/10/7/6/12;
  - decision 54: 9/7/8/2/6; after the §23.36 fix 10/5/9/4/7 (final, decision 56 unchanged).
  - **No balance knob was turned after batch 4.** Every later shift came from the user's design decisions; the target
    10 ± 3 was never enforced.

**Contrast with earlier characters**
- Senjumaru: 09-28 to 10-01, about 8 playtest sections.
- Ichigo: one v1 → v2 redesign of 12 + 6 items; his A/B was left failing after the user cut his damage.
- Neither had a pre-build reference-image model sheet, an adversarial review of the design, worktree fan-out by batch,
  or a dream-rsi CPU with ASSIST / learning integration.
- Lille inherited their lessons:
  - Senjumaru's "reach matches the art" became the FK test from batch 1;
  - Ichigo's stance gave Lille's base L;
  - Ichigo's parry, which the user found too hard to land, is a likely reason the eye got a forgiving window (no cost on
    a miss) and why the design asked "can a human read it?" for every timing window (my inference; the docs don't say so).
