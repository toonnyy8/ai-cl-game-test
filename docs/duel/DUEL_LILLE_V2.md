# SOUL DUEL: Lille Barro II (利傑巴羅・重製), the rebuilt kit

Status: **built 2026-10-09 (batches 1–4: §11–§13); the pendulum and aim-point rework (decisions V6–V7) built 2026-10-10 (batch 5 §15, its CPU batch 6 §16, its art §17); decision V6a (TENSHIN in only as a quick J after a lay) built 2026-10-10 (§18).**
is and stays selectable; this is a second, separate fighter built from a copy of him.

The request (the user, 2026-10-09), verbatim:

> 由於目前利捷巴羅的設計過於強勢，因此我想要對整體系統重新製作，請先以當前的版本為基礎複製一名新版本的「利捷巴羅」，並根據我訂出的規則為基礎對角色玩法進行修改，角色動畫可以將之前的版本進行重新組織，若有缺漏之處再繪製新動作模組。
>
> # 利捷巴羅重製
> - 『萬物貫通』：被防禦時能扣除大量防禦量表、能穿透一部分傷害、射程距離無限
>
> ## 常態：
> - L：狙擊架式，這時候能銜接 L, SP1, SP2 且打出的攻擊會帶有『萬物貫通』特性，擊中對手還能填充『狙擊』量表。
> - J / K：一般攻擊、進入狙擊架式時能消耗『狙擊』量表將行動轉換成具有『萬物貫通』特性的射擊。
>
> ## 覺醒：
> - L：切換成遠程模式，此時的 L, SP1, SP2 會留下射擊軌跡。
> - J / K 會切回近戰並發動攻擊，當 J 攻擊碰到敵人時會讓附近的軌跡實體化，K 攻擊則是就算揮空也會觸發敵人附近的軌跡實體化，實體化後的射擊會帶有「萬物貫通」的特性。
> - 在 J 連段的結尾接入 L 會發動後撤並轉入遠程模式。在 K 連段的結尾接入 L 則會回收掉場上剩餘軌跡，並依據回收數量打出不同的衍生連段（主要輸出手段，具備萬物貫通效果）。
> - 留下軌跡會消耗閃步量表

## 1. User decisions

### Decision V1 (2026-10-09): the four intent questions

Asked with the ⚠ questions of `skills/duel-character` before any build:

| Question | Options offered | The user's choice |
|---|---|---|
| Where does the new version go? | a 7th roster entry, the old one kept (recommended) / the new one replaces the old | **「新增第 7 人，舊版保留」** |
| Which of the old systems survive? | only the two states (recommended) / two states + the owl's revival / two states + MUJITTAI and the eye | **「兩態 + 保留貓頭鷹復活」** |
| The numbers of 萬物貫通 (guard gauge 100; a normal block drains ~30) | drain 40, 30 % through (recommended) / 50, 50 % / 30, 20 % | **「被擋扣 40、穿透 30%」** |
| The 狙擊 gauge | 3 pips, +1 a hit, −1 a conversion (recommended) / 0–100 / blocks fill too | **「3 格，命中 +1，轉換一次 -1」** |

### Decision V2 (2026-10-09): MUJITTAI stays in the awakening

The user, after the design was written: 「覺醒後的 U 還是保持開了就進入無敵的狀態」.

- In every awakened form (melee, ranged, owl melee, owl ranged) U enters **MUJITTAI** exactly as the old Lille's
  (DUEL_LILLE §5.2): a ward with `:intangible` (no damage, no chip, no push), every kit command drops it, the guard gauge
  drains ×1.0 on what it absorbs and does not refill while in it. One `*-mujittai` kit per awakened form.
- The base form's U stays a plain guard (the eye is still dropped).

### Decision V3 (2026-10-09): melee SP1 / SP2 fire directly

The user: 「近戰模式的 SP1／SP2 跟原版一樣會直接放出，只有遠程才會變成軌跡」.

- Melee: SP1 / SP2 are the old KIN moves with their old numbers (not 萬物貫通): Jilliel SP1 SANREN on the wings (3 lines,
  20 m, 30 each, chip 15 %, drain 12), SP2 NIJUSHI-KO (40 f tell, 1.2 m beam, 180); owl SP1 MISUJI (3 SABAKI ground
  lines of 70 to 18 m, their eruption kept), SP2 Trompete (60 f wind-up, 240, reflect by a timed guard / Hoho and the
  seal, as the original).
- Only the ranged modes' L / SP1 / SP2 lay traces.

### Decision V4 (2026-10-09): "near" is the trace's 10° snap

The user: 「「附近」指對手在軌跡線的 10° 補正範圍以內。」

- A trace is near (materialised by a J touch or a K) when the opponent is inside its 10° snap: the ground-plane angle
  between the trace's direction and the line from the trace's origin to him is ≤ 10°, and he is within its length.
  One knob `*br-near-deg*` 10.0 for both the selection and the turn. Replaces the 2.5 m distance of §5.3 ([G], dropped).

### Decision V5 (2026-10-10): the gate results

Asked with the gate numbers of §13.6 (60 seeds, play time without cinematics: BY 115.9 s, BK 112.9 s, both under 125 s;
153.8 / 157.3 s with cinematics; awaken A/B: the never-awaken side BK 8 / 11 / 14 of 60, BI 21 / 17 / 23, pass ≥ 20; only
the base form's damage ×1.3 → ×1.5 moved BK, to 24 / 19 / 16):

- Pacing: 「接受為例外」 — BY 115.9 s and BK 112.9 s are accepted exceptions (AGENTS.md list).
- Awaken A/B: 「先試玩再決定」 — no retune; `*br-mult*` stays ×1.3; the build goes to the playtest (GitHub Pages) and the
  user decides after playing.

### Decision V6 (2026-10-10): the stance step, one trace at a time, no refund, the pendulum back

The user, after the first playtest build: 「常態進入 L 架勢後可以靠 Step 消耗 10 點閃步量表快速位移（就如同原版 lille 一樣）」、
「「附近」的判定條件改成 2.5 公尺內，然後每次只會觸發一條。」; on the old Lille's pendulum: 「我想把鐘擺循環重新帶入 L -> J 與 J -> L
的設計中」; the follow-ups 「把 J 改成就算近攻沒打中也會出發最近實體化，然後後撤瞬間會變回遠程，這樣鐘擺循環的邏輯就跟原本的循環銜接上」、
「只有 J，然後 K 揮空不再觸發實體化」. Choices (AskUserQuestion, the recommended first unless noted):

| Topic | Before | Now (the user's pick) |
|---|---|---|
| The base stance's Step | none | the old HIRENKYAKU: 10 flash step, 3.5 m in the stick direction (neutral: back) over 12 f, iframes f0–7, back in the stance at f6 (a fresh window, aim snapped onto him); **once per stance** |
| "Near" | inside the trace's 10° snap (V4) | the opponent within **2.5 m** of the trace's line (point-to-segment on the ground) |
| How many | every near trace | **one**: the nearest to him (a tie: the newer) |
| Aim | turned ≤ 10° | **fired along its line** as it is at that frame (V7; the pick 「直接對準對手」 of the step before was replaced by V7) |
| J | materialises on a touch | **every J materialises one, hit or whiff** |
| K | materialises at its active frame, hit or whiff | **only on a touch (hit or block)**; a whiff never does (「命中或被防都觸發」) |
| Ranged J | back to melee in place, J1 | **TENSHIN in**: the old dash (30 m/s, ≤ 7 m, stops 1 m short, iframes 9 f, free), 16 f wind-up from neutral, a 2 f cancel out of a ranged L / SP1 / SP2; melee from the dash, J1 at its end (「照原版」) |
| Ranged K | back to melee in place, K1 | unchanged |
| J3 → L backstep | 5 m / 14 f, iframes 7, free, ranged at f13 | 5 m / 14 f, **iframes 9, 10 flash step**, **ranged at f0**; a lay only from the dash's end (「衝刺結束才能接」) |
| J1 / J2 → L | the mode turn | unchanged (only J3 backsteps: 「只有 J3」) |
| Flash-step refund on a materialised hit | 4 / 2 (owl 5 / 2) | **0** (「改成 0」) |

### Decision V7 (2026-10-10): aim points, every trace aims through him

The user: 「另外由於軌跡主動性太低，我想改成設置瞄準點，軌跡會隨時對準自身」. Choices: the point 「設在自己後方 0.5 m 處」; the line
「穿過利捷」; the shot 「沿當下的線射出」; the life 「留到被實體化或回收」; SP1 「隨三發的轉身依序放」; the pick radius 「維持 2.5 m」.

- Ranged L / SP1 / SP2 set an **aim point** 0.5 m behind him (behind his facing at that frame): L one, SP1 one at each of its
  three shot frames (f12 / f22 / f32: he turns at the opponent between them, so the lines part), SP2 one thick (radius 1.2).
  Costs unchanged (3 / 9 / 9 flash step, refused if short); at most 16, the oldest dropped first.
- A trace is the line **from its aim point through Lille's current position, 31 m long**, recomputed every frame: as he
  moves, every line turns about its point. Within 0.3 m of the point the line keeps its last direction [G].
- Materialising (V6: J always, K on a touch; the nearest line within 2.5 m of the opponent, one): the shot runs **along
  that line as it is**, from the point through him and on, with 萬物貫通. The line is ~0.6 m wide: an opponent 2.5 m off it
  is picked and missed (the trace is spent). The opponent sees every line and can step off.
- The recall (K3 → L) takes every aim point, as before.
- The look [G]: a small mark on each point, its line redrawn each frame (0 B a frame).

### Decision V6c (2026-10-10): a wider L → J window; TENSHIN in fires a line at its f0 (the old combo)

The user, on the V6a playtest build: 「L 接 J 的判定再寬鬆一點，另外現在鐘擺戰法沒辦法串成真正的連段」; asked how the old one linked
(the old Lille: TENSHIN in's f0 fired every trace, a 26 f stagger, the ≤ 14 f dash, J1's 8 f: 22 < 26; the out half was
neutral), the user chose 「照原版：前衝第 0 幀觸發」 and the window 「整個放點招式＋收招後 10 幀」.

- The window: a J pressed at any frame of a ranged L / SP1 / SP2 is kept and dashes on the frame the move's last point is
  set (the 2 f cancel); a J within **10 f after the move ends** dashes too (L ≈ 23 f in all). Elsewhere, ranged J = J1 in
  place (V6a).
- TENSHIN in's **f0 fires one line**: the nearest within 2.5 m of the opponent (V6's pick), along the line (V7), stagger
  26 f as every materialised trace; then the dash and J1 (whose own first active frame still fires one more, V6). The
  backstep half stays neutral, as the old.

### Decision V6b (2026-10-10): gates without the old Lille, the playtest first

The user: 「未來測試閘門不要跟第一版 lille 比較，然後先上 playteat 後再跑閘門測試讓自動測試跟人工測試兩邊能同時運作」.

- His gates (pacing, A/B, aieval reads) no longer include BL (Lille II vs the old Lille): six pairings, BY BK BR BI BS BB.
  (The isolation check, the old 21 pairings' rows unchanged, stays: it compares nothing with him.)
- Each change goes to the playtest Artifact once the fast checks pass; the sim gates run after, alongside the playtest.

### Decision V6a (2026-10-10): TENSHIN in only as a quick J after a lay

The user, after the V6–V7 playtest build: 「L > 前衝的設計理解錯誤，我希望是 L 放軌跡後快速連結 J 才會前衝」. Choices: other ranged J
「原地切近戰出 J1」; which lays 「L、SP1、SP2 都可以」.

- TENSHIN in (the dash, its numbers as V6) comes **only** as the 2 f cancel of a J pressed quickly after a ranged L / SP1 /
  SP2: from the frame its point is set to the end of its recovery (the window batch 5 built for the cancel) [G window].
- A ranged J anywhere else (neutral, walking, after the window): back to melee **in place** and J1, as the ranged K. The
  neutral 16 f wind-up dash is gone.

Everything below that the user did not decide is marked **[G]** (our reading, a knob; changed on the next playtest).

## 2. Frame

- Roster **index 6**, kit keyword `:barro`, simgate letter **B** (Y K R I S L B), display name **"LILLE II"**, brush
  name リジェ・バロ. Sim code prefix `br-` (functions, moves `:br-*`, knobs `*br-*`, structs `brs` …); the copy shares
  nothing in the sim with `lille.lisp` (a change to either never moves the other: the old 21 pairings' gate rows must stay
  byte-identical after every batch).
- **Art is shared, not copied** (「角色動畫可以將之前的版本進行重新組織」): his moves point their `:clip` at Lille's clips,
  bodies (`:lille`, `:lille-jilliel`, `:lille-jilliel-kin`, `:lille-shin`) and weapon (`:diagramm`) in `lille-art.lisp`.
  Only the motions Lille never had are new, in `duel/lisp/barro-art.lisp` (§7). `lille-art.lisp` therefore stays loaded
  even if the old Lille is retired one day.
- Files: `duel/lisp/barro-art.lisp`, `duel/lisp/barro.lisp`, after `lille.lisp` in `duel/MANIFEST`.
- Debug range **82000–82999** (claimed here; DUEL_GAMEPLAY "Debug commands"). Gate command for his pairings: 2156–2162
  (k 21–27), character gate 2142.
- Dropped from the old kit: the eye (the base form's U is a plain guard), TENSHIN's dash switch, the crossing
  slow motion, Hoho → KIN, the stance's charge bonus and its HIRENKYAKU step, HOSHA. (Batch 5, decision V6, brought back
  the stance's HIRENKYAKU step and TENSHIN in as ranged J: §15.) Kept: the owl's revival (decision V1) and MUJITTAI on U in every awakened form (decision V2).

## 3. 萬物貫通 THE X-AXIS (one rule, every move that carries it)

A move "with 萬物貫通" is a ranged, hitscan line (`:vol (:cap …)`, `:flags (:ranged :x-axis :uncatchable)`) with:

| Knob | Value | Note |
|---|---|---|
| `*br-x-guard*` | **40** | guard gauge a block drains (gauge 100; a usual block ~30): the 3rd blocked one breaks guard (user) |
| `*br-x-chip*` | **0.30** | the fraction of the damage a block lets through (the chip rule: never kills) (user) |
| `*br-x-len*` | **31.0 m** | "射程距離無限": the arena's diameter (radius 15) + 1, the old shot's length (user, as metres) |

Without 萬物貫通 a ranged move uses the defaults by kind (chip and drain of its kind) and a finite line.

## 4. 常態 (the base form, `:barro :base`)

The old base Lille's body, rifle and strings; L is the shooting stance.

| Input | Move | Data (start) | Notes |
|---|---|---|---|
| J string | `:br-j1..j3` | as `:lb-j1..j3` (26 / 22 / 28) | normal attacks |
| K string | `:br-k1..k3` | as `:lb-k1..k3` (48 / 48 / 70) | normal attacks; L after a K link opens the stance at f4 (as the old) |
| L | `:br-kamae` 狙擊架式 | up at f6, held 30 f (90 while L is held) | clip `:lb-kamae`. From f6 the first of L / SP1 / SP2 / J / K picks the follow-up |
| stance → L | `:br-k-shot` 万物貫通 | S 10 (the lock), dmg **50** flat, PA | clip `:lb-k-shot`. A hit: 狙擊 +1 |
| stance → SP1 | `:br-k-sanren` | 3 lines × 30, PA (each 31 m) | clip `:lb-sanren`. Any hit: 狙擊 +1 (once per move) [G] |
| stance → SP2 | `:br-k-hiren` | 6 m back-slide, then one shot 50, PA | clip `:lb-hiren`. A hit: 狙擊 +1 |
| stance → J, 狙擊 ≥ 1 | `:br-k-snap` 速射 | S 6, dmg **40**, PA, costs 1 | clip `:lb-snap` (Lille's unused hip snap shot) [G] |
| stance → K, 狙擊 ≥ 1 | `:br-k-taisha` 退射 | 3 m back-slide, one shot **70**, PA, costs 1 | clip `:lb-k-taisha` [G] |
| stance → J / K, 狙擊 0 | `:br-j1` / `:br-k1` | — | the stance drops into the normal attack (「一般攻擊」) |
| SP1 (not in the stance) | `:br-sanren` | 3 lines × 30, 20 m, default ranged chip / drain | no 萬物貫通, no 狙擊 [G] |
| SP2 (not in the stance) | `:br-hiren` | slide, one 40 shot, 20 m | no 萬物貫通, no 狙擊 [G] |
| U | guard | — | no eye |
| P (full awaken gauge) | awakening → 覺醒 近戰 | cinematic `lb-jilliel-cine` (copied as `br-jilliel-cine`) | the awaken gauge fills the usual way (no eye) |
| Breaker, O | `:br-breaker`, `:br-kikon` | as the old (Kikon 2) | |

**狙擊 gauge** (`brs-snipe`): 0–3 (user). +1 when the stance's L / SP1 / SP2 hits (not on block, user); −1 for each J / K
conversion. Not filled by the converted shots themselves [G]. Kept through the awakening (unused there) and reset each
match. HUD: three pips labelled "SN" in the kit meter slot.

## 5. 覺醒 (Jilliel, two modes)

(Batch 1's build. Decisions V6–V7 changed ranged J (TENSHIN in), the lays (aim points), materialising (one trace, J
always, K on a touch, along the line), the refunds (0) and the backstep: §15 is the current rule where they differ.)

Two forms of one awakening: **近戰 melee** `:barro :jilliel-kin` (KIN's wing blades and forked legs) and **遠程 ranged**
`:barro :jilliel` (EN, afloat). The awakening enters **melee** [G] (the rule names L as the way into ranged).

### 5.1 Melee (`:jilliel-kin`)

| Input | Move | Notes |
|---|---|---|
| J string | `:br-w-j1..j3` (24 / 24 / 30, clips `:lb-w-q1..q3`) | **a J that touches him (hit or block) materialises the traces near him** (§5.3) |
| K string | `:br-w-k1..k3` (50 / 50 / 72, clips `:lb-w-f1..f3`) | **every K materialises the traces near him at its first active frame, hit or whiff** |
| L | `:br-to-en` | to ranged (a 12 f turn, clip `:lb-w-fold` then EN's stance) [G] |
| J3 → L | `:br-backstep` 後撤 | a 5 m back-dash over 14 f (clip `:lb-w-tenshin`, iframes f0–6), lands in ranged mode |
| K3 → L | `:br-recall` 回收 | takes every live trace off the field, counts n, then plays the derivative string for n (§5.4) |
| SP1 / SP2 | `:br-sanren-w` / `:br-nijushi` | fire directly, the old KIN moves (decision V3) |
| U | MUJITTAI `:jilliel-kin-mujittai` (decision V2) | any command drops it back to melee |
| P (≤ 4 Konpaku, free state) | the owl's revival | §6 |
| Breaker, O | `:br-w-breaker`, `:br-w-kikon` | as the old (Kikon 3) |

### 5.2 Ranged (`:jilliel`)

| Input | Move | Notes |
|---|---|---|
| L | `:br-e-lay` | lays **one** trace line at him (clip `:lb-e-q1`), repeatable; costs **3** flash step |
| SP1 | `:br-e-sanren` | lays 3 lines in a fan (clip `:lb-e-sanren`), 3 each = **9** |
| SP2 | `:br-e-nijushi` | lays one thick line (radius 1.2, clip `:lb-e-nijushi`), **9** [G] |
| J / K | `:br-w-j1` / `:br-w-k1` | back to melee at f0 and the attack (「切回近戰並發動攻擊」) |
| U | MUJITTAI `:jilliel-mujittai` (decision V2) | any command drops it back to ranged |
| walk | EN's float (`*br-walk-en*` = old `*walk-jilliel*`) | |

Laying never deals damage. A lay is refused when the flash step is short of its cost (user: 「留下軌跡會消耗閃步量表」).
At most 16 live traces; the oldest goes first (the old rule). A trace is a 31 m line from where he stood, aimed at him.

### 5.3 Materialising

- **Near** = the opponent is inside the trace's **10° snap** (decision V4): the angle between the trace's direction and
  its origin → him is ≤ 10°, him within the trace's length.
- J: on the J's hit **or block** (「碰到敵人」), every near trace materialises. K: at the K's first active frame, every near
  trace materialises, whether the K connects or not.
- A materialised trace turns up to 10° toward him (the old snap) and becomes a 2-frame hit with **萬物貫通**, then is gone.
  Damage per line: L / SP1 lines **30**, SP2's thick line **90** [G] (old 30 / 180). Stagger 26 f as the old.
- Flash-step refund when a materialised trace connects: 4 on hit / 2 on block (the old numbers).

### 5.4 The recall (K3 → L) and its derivative strings

All live traces are removed and counted (n); the derivative string is picked from n. Every hit is a 萬物貫通 line from him
at the opponent ("主要輸出手段"). Damage is the knob to tune at the gate [G]:

| n | String | Hits | Total (start) | Clip |
|---|---|---|---|---|
| 0 | 空收 | 1 × 30 | 30 | `:br-recall` then `:lb-w-q3` |
| 1–2 | 二連 | 2 × 40 | 80 | `:br-recall` then `:br-rc1` (new) |
| 3–5 | 四連 | 3 × 35 + 1 × 45 (launch) | 150 | `:br-recall` then `:br-rc2` (new) |
| 6+ | 裁き | 4 × 30 + 1 × 90 | 210 | `:br-recall` then `:br-rc3` (new) |

## 6. The owl's revival (kept, decision V1)

P in either awakened mode at ≤ 4 Konpaku, from a free state → the owl, as the old (`br-revive-cine`, Konpaku → 1, Reishi
full, traces cleared). Two modes on the same rules as §5: **owl melee** `:shin-kin` (claws `:lb-o-q1..f3`), **owl ranged**
`:shin` (EN casts `:lb-oe-q1..`, SP1 `:lb-oe-sabaki` lays 3 lines, SP2 `:lb-oe-trompete` lays the thick line); owl
melee SP1 MISUJI and SP2 Trompete fire directly with the reflect and seal (decision V3), U MUJITTAI in both (decision V2). ×1.1 dealt, ×1.1 taken, +1 f on every move, refunds 5 / 2, Kikon 4 (the old owl's numbers). The recall's
derivative strings use the claws' clips (`:lb-o-*`, `:lb-o-chop` for the last hit).

## 7. Animation: what is reused, what is new

Reused (Lille's clips, see §4–§6 tables). New, in `barro-art.lisp`:
- `:br-recall` — the wings / claws flung open, the traces' light pulled back into him (8 f).
- `:br-rc1`, `:br-rc2`, `:br-rc3` — the derivative strings' strikes (two / four / five beats), each beat a line fired
  from the wing tips; the owl versions map onto claw clips via `:clip-map` if a separate drawing is not needed.
- `:br-to-en` (if `:lb-w-fold` reads wrong as a mode switch).
Drawn reach = hit reach (host FK test) does not apply to lines (hitscan), only to the melee strings, which keep Lille's.

## 8. CPU, ASSIST, learning (required for every mechanic)

- Base: zone at range with the stance (L → L shot); at ≥ 1 狙擊 and in close, stance → K (TAISHA's back-slide) or J
  (snap); strings up close, L after a K link.
- Melee: approach, strings; K3 → L when n ≥ 3 (or n ≥ 1 at low HP); J3 → L when n = 0 or the flash step is ≥ 9.
- Ranged: at ≥ 5 m lay lines around him (L, SP1) while the flash step allows; at n ≥ 4 or him inside 4 m: J / K in.
- Opponent reflex (anyone facing him): step off live traces (copied from `lb-opp-trace`).
- ASSIST AUTO COMBO: base J J J → L → L; melee K K K → L.
- Learning: one situation per state (the stance, the recall), as `learn-def-kit :barro`.
- Every chance scales EASY ≤ NORMAL ≤ HARD; roll once per event.

## 9. Gates

- His 7 pairings (BY BK BR BI BS BL, the mirror BB): every match K.O., cross medians 125–210 s (20 seeds; quick pass 10).
- The old 21 pairings' rows: byte-identical to the parent after every batch (proves the copy is isolated).
- Awaken A/B (`--cmd 39060 + b`): the never-awaken side ≥ 20/60.
- ASSIST gate, `aieval.py --char 6`. G2 cvc reference: a 7th roster entry changes `start-cvc`'s draw of pairs, so
  `tests/style-cvc-ref.txt` is regenerated once (header note + "Before:").
- Host tests: rules (his forms, the 萬物貫通 numbers, the 狙擊 gauge, near-trace selection, recall tiers), pkgcheck,
  `./build.sh duel` 0 warnings.

## 10. Build batches

1. **Scaffold + base**: `barro.lisp` from `lille.lisp` (renamed, the dropped systems removed), roster index 6 plumbing,
   §3–§4, HUD pips, host tests; awakened forms present but as plain melee / ranged copies.
2. **Awakening**: §5–§6 (modes, lay, near materialise, backstep, recall tiers, owl).
3. **Art**: §7's new clips.
4. **CPU / ASSIST / learning**, then the gates and tuning (§8–§9).
5. **Player docs**: the manual and tutorial entries.

## 11. Build notes (batch 1, 2026-10-09: batches 1 + 2 of §10 together, branch `barro-b1`)

### What was built

- `duel/lisp/barro.lisp` (sim, kits, hooks, CPU, debug, pacing) and `duel/lisp/barro-art.lisp` (his own looks only), after
  `lille.lisp` in `duel/MANIFEST`. Kit `:barro`, roster index 6, display name "LILLE II", brush name リジェ・バロ. Every
  function, knob, struct (`brs` the per-fighter component, accessor `(br e)`; `brh` the trace data), move (`:br-*`) and
  hazard kind (`:br-trace`, `:br-fx`, `:br-misuji`) is his; no Lille symbol or registry entry is redefined.
- Shared by reference (art, never sim): Lille's clips, bodies, weapon `:diagramm`, his cinematics (`lb-jilliel-cine`,
  `lb-kikon-cine`, `lb-revive-cine`, `lb-jilliel-kikon-cine`, `lb-trompete-cine`), his draw hook `LILLE-DRAW` (called from
  Barro's `BR-DRAW`: it keys on the form names, which Barro shares) and `LB-LOOK` for the look-only hazards (their data is an
  `LBH`, read by nothing in the sim), the sounds `:lb-crack` / `:lb-lock` / `:lb-trumpet`.
- Nine forms: `:base`; JILLIEL melee `:jilliel-kin` (the awakening enters it) and ranged `:jilliel`; the owl melee
  `:shin-kin` and ranged `:shin` (the revival enters the owl's ranged mode, as the old); each awakened mode's MUJITTAI
  (`:jilliel-kin-mujittai`, `:jilliel-mujittai`, `:shin-kin-mujittai`, `:shin-mujittai`).
- §3 萬物貫通 through the per-hit `:guard` / `:chip` + `:flags (:ranged :x-axis :uncatchable)`, 31 m `:cap` lines: the stance's
  L / SP1 / SP2 / snap / TAISHA, the four recall strings, every materialised trace.
- §4 the stance (`:br-kamae`, `:br-kamae-k` after a K link at f4; BR-KAMAE-TICK through non-button `:strings`), the 狙擊 gauge
  (`brs-snipe`; +1 on the first hit of a stance L / SP1 / SP2, a block fills nothing; J / K spend 1, at 0 J1 / K1), HUD: three
  pips (Lille's reticle glyph) + "SN n" in the base form, "TR n" (live traces) awakened; the stance's aim line and reticle
  (`%BR-AIM-LOOK`). Stance SP1 / SP2 cost their usual Reiatsu bar (TRY-COMMAND's WITH) [G].
- §5 modes: melee L `:br-to-en` (12 f, ranged at f11); ranged L / SP1 / SP2 lay (3 / 9 / 9 flash step, refused when short,
  paid line by line; SP1 a three-line fan at f6 / f12 / f18 of −6 / 0 / +6°); ranged (and its MUJITTAI's) J / K start the
  melee J1 / K1, whose frame 0 (`BR-MELEE-IN`) puts him back in melee; a J that touches him (hit or block) and every K's
  first active frame materialise the near traces; refunds 4 / 2 (owl 5 / 2); 16 traces at most. J3 → L `:br-backstep`
  (5 m / 14 f, iframes f0–6, ranged at f13), K3 → L `:br-recall` (f0 takes every trace back and counts n, f7 starts
  `:br-rc0..3` by n). The L links are the kit's `:l-after-j` / `:l-after-k`, refused off anything but J3 / K3
  (BR-L-LINK-OK-P in the `:ok` hook).
- §6 the owl: P at ≤ 4 Konpaku from any JILLIEL form (MUJITTAI included) where the awakening could be taken; Konpaku → 1,
  Reishi full, traces cleared; x1.1 / x1.1, R − 1 on the J / K strings and the lays, Kikon 4.

### Spec changes during the batch (the user, 2026-10-09, relayed by the lead)

1. 「覺醒後的 U 還是保持開了就進入無敵的狀態」: MUJITTAI kept. Each awakened mode has a `*-mujittai` kit (`:guard-to` /
   `:drop-to`, `:passives (:ward :intangible)`, the fold stance `:lb-w-fold` / `:lb-oe-fold` / `:lb-o-fold`, no `:keep`:
   every command drops it), `:gg-regen` `*br-gg-regen*` 0.36 outside it, its perfect-Hoho drop (BARRO-TICK). The base U
   stays a plain guard. Followed.
2. 「近戰模式的 SP1／SP2 跟原版一樣會直接放出，只有遠程才會變成軌跡」: melee SP1 / SP2 fire directly with the old numbers:
   JILLIEL `:br-w-sanren` (3 lines 20 m, 30 each, chip 15 %, guard 12, on `:lb-w-sanren`) and `:br-w-nijushi` (40 f tell,
   1.2 m beam, 180); the owl `:br-misuji` (three 裁きの光明 ground lines of 70 to 18 m, one hit group) and `:br-trompete`
   (60 f wind-up, 240; the reflect by a guard f50–58 / a perfect Hoho f48–59: half back, a 60 f stagger, owl SP2 sealed in
   both owl modes for the match). Only ranged L / SP1 / SP2 lay. Followed (this replaces §5.1's "SP1 / SP2 as ranged").
3. 「「附近」指對手在軌跡線的 10° 補正範圍以內。」: near = the angle between the trace's direction and the direction from its
   origin to the opponent ≤ `*br-near-deg*` 10° (the same knob as the snap) and the opponent within the trace's 31 m; the
   materialised line turns by that angle onto him. Followed (replaces §5.3's 2.5 m rule).

### Deviations from the spec, and why

- Cinematics referenced, not copied (§4 said `br-jilliel-cine`): LILLE-DRAW drives the wings' unfolding, the jade turning
  gold etc. from the running cinematic's *name*; a renamed copy would draw the awakened wings round the base body. Art, so
  shared as the rest of the art; the awakening's caption is still Lille's eye line (the art batch may give him his own).
- The revival enters the owl's ranged mode `:shin` (as the old); §5's [G] "the awakening enters melee" kept for JILLIEL.
- Owl "+1 f on every move": on the J / K strings and the lays (the old owl's numbers); the shared recall, its strings, the
  mode turn and the backstep keep JILLIEL's frames.
- Looks Barro does not have yet (art batch): the owl's trumpet forming and the broken halo after a reflect (LILLE-DRAW keys
  them on Lille's move name / state), the snap shot / recall callouts in brush (no new glyphs baked: plain callouts).
- `*br-mult*` 1.3 (base) is the old Lille's gate value, copied.

### Stand-in clips (`*br-stand-ins*`, barro.lisp: the art batch swaps them)

| Move | JILLIEL plays | The owl plays (`*br-owl-clip-map*`) | New clip to come |
|---|---|---|---|
| `:br-recall` (8 f) | `:lb-w-fold` | `:lb-o-fold` | `:br-recall` |
| `:br-rc0` 空收 | `:lb-w-q3` | `:lb-o-q3` | (`:br-recall` then a strike) |
| `:br-rc1` 二連 | `:lb-w-sanren` | `:lb-o-f2` | `:br-rc1` |
| `:br-rc2` 四連 | `:lb-e-sanren` | `:lb-o-f3` | `:br-rc2` |
| `:br-rc3` 裁き | `:lb-w-nijushi` | `:lb-o-chop` | `:br-rc3` |
| `:br-to-en` | `:lb-w-fold` | `:lb-o-fold` | `:br-to-en` (if needed) |
| `:br-backstep` | `:lb-w-tenshin` | `:lb-o-tenshin` | — |
| `:br-k-snap` | `:lb-snap` (Lille's unused hip shot) | — | — |

### Knobs (barro.lisp; every one with a docstring: old → new, 2026-10-09, the user or [G])

| Knob | Value | | Knob | Value |
|---|---|---|---|---|
| `*br-x-guard*` / `*br-x-chip*` / `*br-x-len*` | 40 / 0.30 / 31.0 (user) | | `*br-snipe-max*` | 3 (user) |
| `*br-shot-dmg*` / `*br-snap-dmg*` / `*br-taisha-dmg*` | 50 / 40 / 70 | | `*br-k-sanren-dmg*` / `*br-k-hiren-dmg*` | 30 / 50 |
| `*br-sanren-dmg*` / `*br-hiren-dmg*` / `*br-plain-len*` | 30 / 40 / 20.0 [G] | | `*br-mult*` / `*br-taken*` | 1.3 / 1.0 |
| `*br-lay-l*` / `*br-lay-sp1*` / `*br-lay-sp2*` | 3 / 9 / 9 | | `*br-trace-max*` | 16 |
| `*br-near-deg*` | 10.0 (user) | | `*br-mat-dmg*` / `*br-mat-thick*` / `*br-mat-stun*` | 30 / 90 / 26 [G] |
| `*br-refund*` / `-block*`, owl | 4 / 2, 5 / 2 | | `*br-backstep*` / `-f*` / `-iframes*` | 5.0 / 14 / 7 [G] |
| `*br-recall-f*` | 8 [G] | | `*br-rc0-dmg*` | 30 [G] |
| `*br-rc1-dmg*` | 40 ×2 [G] | | `*br-rc2-dmg*` / `*br-rc2-last*` | 35 ×3 / 45 (launch) [G] |
| `*br-rc3-dmg*` / `*br-rc3-last*` | 30 ×4 / 90 [G] | | `*br-rc-stun*` / `*br-rc-track*` | 28 / 360 °/s [G] |
| `*br-jilliel-mult*` / `-taken*` | 1.0 / 1.1 | | `*br-owl-mult*` / `-taken*` / `*br-owl-adv*` | 1.1 / 1.1 / 1 |
| `*br-gg-regen*` | 0.36 | | `*br-to-en-f*` | 12 [G] |
| `*br-ai-fire-n*` / `*br-ai-in*` | 4 / 3.5 m [G] | | misuji / reflect knobs | the old values |

### The CPU (batch 1: crude, batch 4 does it properly)

Generic `:ai` plists per form (copied shapes of the old forms), plus: the stance's follow-up planned once at its f6
(BR-AI-KAMAE-PLAN: reeling → the shot; ≥ 1 pip inside 4 m → TAISHA / snap; a quarter of the time with a bar the stance's
SP2 / SP1; else the shot); `:l-after-k` 0.9 / `:l-after-j` 0.6 in melee, the `:ok` hook letting the CPU recall only at ≥ 3
traces (≥ 1 under 35 % Reishi) and backstep only with no trace or ≥ 9 flash step; the reflex (BR-AI-REFLEX): ranged → K at
≥ 4 traces, J inside 3.5 m; MUJITTAI → out by attacking after 120 f or under 30 guard gauge. No ASSIST route (the generic
AUTO COMBO plays his strings), no learning situations, no opponent trace reflex: batch 4.

### Debug commands

82000+k: 0 base 2.2 m from Kenpachi, 1 base 14 m, 2 melee 5 m, 3 ranged 8 m, 4 owl melee 5 m, 5 ranged 8 m with 6 traces
through P2, 6 base 4 m with 3 pips, 7 / 8 the owl's Trompete reflected by a guard / a Hoho, 9 owl ranged 8 m, 10 melee with
3 Konpaku (P revives), 11 / 12 melee / ranged MUJITTAI, 20 the mirror (DUEL_GAMEPLAY "Debug commands").

### Gates (2026-10-09, branch `barro-b1`)

- Host: duel-rules-test 8351 checks ALL PASS (a Lille II block: 萬物貫通 on every PA window, the gauge, near by angle 9° in /
  11° out / behind out / past 31 m out, the recall tiers and their windows, the lay prices and refusal, melee SPs never lay
  and ranged ones always do, the forms and MUJITTAI's guard-to / drop-to for every command, the owl's +1, the CPU's stance
  plan); duel-control 89, learn 131, input 33, touch 64, cine 18: all pass. `tools/pkgcheck.sh duel`: 0 / 0 / 0.
  `./build.sh duel`: 0 warnings. Smoke `run.mjs --secs 8`: exit 0; a script through 82020 / 82006 / 82005 (K materialised
  the six traces: P2 1300 → 1138) / 82004 / 82007 (reflected: P1 1300 → 1168) / 82011: exit 0, no error.
- The old 21 pairings at 10 seeds: every row, companion line and summary line byte-identical to the parent (c3971c6).
- `simgate.py --cvc`: PASS, unchanged (G2 plays fixed pairs YY / YK / KK; only debug 2000+ draws from the roster):
  `tests/style-cvc-ref.txt` needs no regeneration for this batch.
- His seven pairings, 10 seeds (quick pass), every match K.O.:

| Pairing | Median s | Min–max | Wins P1 (him) / P2 |
|---|---|---|---|
| BY | 114.3 | 90.3–130.4 | 1 / 9 |
| BK | 123.3 | 79.3–157.9 | 4 / 6 |
| BR | 129.5 | 104.1–172.8 | 4 / 6 |
| BI | 141.4 | 99.9–152.6 | 5 / 5 |
| BS | 135.6 | 78.8–154.5 | 4 / 6 |
| BL | 186.0 | 114.4–225.1 | 3 / 7 |
| BB | 165.9 | 114.8–185.3 | 6 / 4 (mirror) |

BY and BK are under the 125 s floor: he loses most cross pairings fast (the CPU is batch 1's). Tried: stance shot 50 → 60
and snap 40 → 50: BY 123.8, BK 122.3, BR 127.2, BI 138.6, BS 133.5, BL 168.9, BB 146.7 (noise-level, not kept: the spec's
numbers stay); the melee CPU's L into ranged at 2.4–8 m (kept) moved BY 107 → 114, BK 114 → 123. Left to batch 4 (the CPU)
and the gate batch. `aieval.py --char 6 --seeds 4`: strength 0.06, masher 1.0, signature 0.37, pacing ok.

## 12. Art (batch 3, 2026-10-09, branch `barro-art`)

Presentation only: the sim does not move (every simgate row of all 28 pairings at 10 seeds byte-identical before / after,
the G2 cvc lines unchanged). The old Lille's looks are unchanged (his code paths keep their keys; the edits in
`lille-art.lisp` / `lille.lisp` only add Lille II's move names / character to them).

### New clips (`barro-art.lisp`), timed to `barro.lisp`'s frame data

Every clip lasts its move (S + A + R) with its `:s` mark on S, JILLIEL's on the KIN rig (the front wing pair's tips are the
rig's hands) and the owl's twin (`:br-o-*`, the claws are the hands) through the owl kits' `:clip-map` (`*BR-OWL-CLIP-MAP*`).

| Move (frames) | JILLIEL clip | Owl clip | What it shows |
|---|---|---|---|
| `:br-recall` 回収 (8 f; f0 takes the traces back, f7 starts the string) | `:br-recall` | `:br-o-recall` | the wings / claws flung open wide and high, the column arched back and rising (f3–f6), then drawn in round the gathered light (f8 = the string's first frame). The six table wings fan out (`*lb-spread-clips*`). |
| `:br-rc0` 空收 (6 2 24) | `:br-rc0` | `:br-o-rc0` | one beat, f6: both wings cocked behind (f3), snapped at him, blown up and back |
| `:br-rc1` 二連 (6 12 24) | `:br-rc1` | `:br-o-rc1` | f6 the right wing, f16 the left (each cocked 3 f, snapped at him, kicked back by the shot) |
| `:br-rc2` 四連 (6 28 24) | `:br-rc2` | `:br-o-rc2` | f6 R, f14 L, f22 R, f32 the launch: crouched with both wings swept low (f29), then swept up at him (the tips 1.4 m ahead, 2.3 m up) |
| `:br-rc3` 裁き (6 32 26) | `:br-rc3` | `:br-o-rc3` | f6 R, f12 L, f18 R, f24 L, then risen into NIJUSHI-KO's ring (f26–35, the holes lit, shaking), the beam on f36 blowing him back; the owl raises both claws overhead and throws them at him on f36 |
| `:br-to-en` (12 f, ranged at f11) | `:br-to-en` | `:br-o-to-en` | folded, rising with the wings thrown open, EN's float; the owl's leaps up and steps its root down by the owl's lift (0.35) on f11, the frame its form turns ranged |
| `:br-backstep` (14 + 8 f, ranged at f13) | `:lb-w-tenshin` (Lille's TENSHIN reads right: kept) | `:br-o-backstep` | the owl's: as `:lb-o-tenshin` but its lift step on f13 (Lille's TENSHIN steps on his f6: on Barro it popped the owl 0.35 m up at f13) |

`*BR-STAND-INS*` now lists each move's JILLIEL and owl clip and the batch-1 stand-in it replaced. The recall strings play at
clip speed 1 (their `:clip-s` went). Host test (duel-rules-test, "Lille II's own clips"): each clip's length and S, the
strings' beats equal their moves' line frames (BR-RC-SHOT / BR-BEAM-SHOT), and on each beat the firing tip points at him
(>= 1.2 m ahead, within 0.4 m of his line; the owl's claws within 0.5 m); the finisher's ring the frame before (each wing
>= 1 m aside).

### Looks (cosmetic; `rnd01`-free, driven by the move's frame)

- **The traces fly back** (`%BR-RECALL-LOOK`): BR-TRACE-LOOK notes every live trace it draws (`*BR-SEEN*`), BR-DRAW keeps the
  last frame's set while he is not recalling (`*BR-FLY*`); through the recall's look clock (the recall's frame, then 7 + the
  string's) each trace is a jade line (the owl's gold) whose near end rushes along the floor into his chest by f6 and whose
  far end follows from the wall by f9 (`*BR-FLY-F*`), brightening, a light at its head; then the gathered light flares at his
  chest over f5–f15 (`*BR-GATHER-F*`; a faint puff for an empty recall). No hazard is spawned (the sim's entities are
  untouched).
- **Each string beat** (`*BR-RC-BEATS*`, `%BR-BEAT-LOOK`): for 5 frames a line from each firing wing tip / claw to his chest
  height with a flash at the tip (the finisher's from both, wider), over LB-LOOK's own 31 m line; and Lille's SP drive on the
  wings (`%LB-SP-DRIVE!` calls `BR-RC-DRIVE`): SANREN's kick on the firing wing and its holes flashing, the finisher's
  NIJUSHI-KO ring, lit, shaking, blown back by the beam.
- **Gaps fixed:** Barro's melee SANREN / NIJUSHI-KO / Jilliel Kikon and ranged SANREN / NIJUSHI-KO now drive the same wing
  looks as Lille's (`%LB-SP-DRIVE!`'s cases list `:br-w-sanren :br-e-sanren :br-w-nijushi :br-e-nijushi :br-w-kikon`); the
  owl's trumpet forms over `:br-trompete` / `:br-oe-trompete` (LILLE-DRAW's Trompete cases list them); the broken halo and
  the reflect flash read his own seal (`BR-DRAW-SEALED-P`, `brs-sealed`) when he has no LBS (`%LB-SEAL-LOOK` now takes the
  sealed flag). Lille's paths compute the same values as before.
- **Brush callouts:** 速射 SOKUSHA, 遠 EN, 後退 KOTAI, 回収 KAISHU (the recall and 空收), 二連 NIREN, 四連 YONREN, 裁き SABAKI;
  the glyphs 速 遠 後 回 収 baked into `glyphs-extra.lisp` (tools/glyph-bake.py's GLYPH(), Yuji Syuku, the same subset rules).
- **The awakening's caption:** `lb-jilliel-cine` (shared) shows 「万物貫通 / THE X-AXIS / BANBUTSU KANTSU」 at f60 when its
  subject is Lille II (he has no eye), Lille's eye line otherwise; the f92 神の裁き / JILLIEL caption is shared. (The face
  close-up's eye opening at f30 is the shared cinematic's and still plays.)

### Debug commands (DUEL_GAMEPLAY "Debug commands", 82000 row)

82100+k a scene (P1 Lille II, k + 20 the front view as P2, 4 m from an idle Kenpachi): 0–3 JILLIEL melee with 0 / 2 / 4 / 6
traces laid from behind him and the recall started (空收 / 二連 / 四連 / 裁き), 4–7 the same as the owl, 8 / 9 JILLIEL's
melee → ranged turn / backstep, 10 / 11 the owl's, 12 the owl's Trompete, 13 82007's reflected Trompete, 14 JILLIEL's
melee SANREN; 82200+f freezes the
sim once his look clock reaches f (armed for the next scene), 82299 lets go; 82300+k his awakening held at frame 10 k; 82398
a `barro consing` line. Measured (10 draws): the recall look 0 B, a beat's lines 0 B, BR-RC-DRIVE 0 B, his traces' looks
0 B; BR-DRAW 24 B a draw (LILLE-DRAW's two entity lookups, 16 B, + his fighter's, + his model's in the recall chain). The
first draw of the lit wing holes in a page builds their meshes once (~26 KB, Lille's too).

### Stills (not committed; `tests/shots/barro/`)

Rendered with `node tools/run.mjs dist/duel --fixed-dt 16.666667 --script ...` (the scripts generated by the batch's
scratch generator: per still 82299, 82200+f, 82100+k, a shot). `jl-*` JILLIEL (the game's camera), `owl-*` the owl,
`front-*` the front view, `cine-awaken-*` the caption (`cine-awaken-f070-caption.png`: 万物貫通 / THE X-AXIS);
`barro-art-sheet.png` (JILLIEL) / `barro-art-sheet-2.png` (the owl, the reflect, the caption) the contact sheets. 46 stills:
`jl-rc3-c02-flyback`, `-c05-open`, `-c08-gather`, `-c13-beat1R`, `-c19-beat2L`, `-c31-beat4L`, `-c41-ring`, `-c43-beam`,
`-c52-blown`; `jl-rc2-c21-beat2L`, `-c36-low`, `-c39-launch`; `jl-rc1-c13-beat1R`, `-c23-beat2L`; `jl-rc0-c04-empty`,
`-c13-beat`; `jl-to-en-f05`, `-f09`; `owl-rc3-c03-flyback`, `-c08-gather`, `-c13-beat1R`, `-c19-beat2L`, `-c41-raise`,
`-c43-throw`; `owl-rc2-c39-launch`, `owl-rc0-c13-beat`, `owl-to-en-f06`, `-f12`, `owl-backstep-f06`, `-f16`,
`owl-trompete-f30`, `-f55`, `owl-reflect`, `owl-sealed-halo`; `front-jl-rc3-c05-open`, `-c13-beat1R`, `-c41-ring`,
`-c43-beam`, `front-jl-rc2-c39-launch`, `front-jl-to-en-f09`, `front-owl-rc3-c05-open`, `-c13-beat1R`, `-c43-throw`,
`front-owl-rc2-c39-launch`; `cine-awaken-f070-caption`, `cine-awaken-f100-jilliel` (c = the look clock, f = the move's frame).
A held still's brush callout may already have given way to the pixel one (the hold freezes the sim's callout timer, not the
brush column's 1.3 s).

## 13. CPU, ASSIST, learning and gates (batch 4, 2026-10-09, branch `barro-cpu`)

(§12 is the art batch's.) Everything here is in `duel/lisp/barro.lisp` (the AI, ASSIST and learning sections) and its
kits' `:ai` plists; no other character's code or knob moved (the old 21 pairings' rows are byte-identical, below).

### 13.1 The sim fix: L after a melee J1 / J2 / K1 / K2

Batch 1 refused (and ate) L pressed in a non-ender melee link. Now the melee kits' `:l-after-k` / `:l-after-j` name one
router move, `:br-l-link` (it lives no frame: its f0 starts the real move through the non-button strings
`*br-melee-strings*`). `BARRO-OK` routes it off the link it was pressed in (`BR-L-ROUTE`, kept in `BRS-L-TO`): K3 → the
recall, J3 → the backstep, J1 / J2 / K1 / K2 → `:br-to-en` (the plain L, the mode turn). It starts where the enders'
L links start: latched, at the link's chain open on hit or block. A human's L is never refused now; the CPU's clause
(`BR-AI-L-OK-P`) still gates the recall and the backstep. The owl's melee shares it. Host-tested (the routes, the router's
f0, the strings in both melee kits); the browser smoke ran it.

### 13.2 The CPU (§8)

Every chance is a `:p` in the kit's `:ai`, × `*br-ai-diff*` (EASY 0.5 / NORMAL 1.0 / HARD 1.5, at most 1). Every roll is
made once per event: a base decision window (`*br-ai-every*` 30 f), a threat window (his move's start, a hazard's spawn),
a trace laid (the fire roll), a link's land frame (the enders), the stance's f6 (its plan). `BR-AI-REFLEX` is every
form's `:reflex`.

| Form | Rule | `:ai` key (NORMAL) |
|---|---|---|
| base | the stance at range (its plan: the 萬物貫通 shot) | `:zone (:p 0.5 :near 6.0)` |
| base | the stance in close with a 狙擊 pip (its plan: TAISHA / the snap) | `:pip (:p 0.6 :near 4.0)` |
| base | L after a K link (the stance at f4; its plan the shot on the reeling opponent) | `:l-after-k 0.4 → 0.6` |
| base | strings up close | the bands (unchanged) |
| melee | K3 → L the recall at n ≥ 3, or n ≥ 1 under 35 % Reishi (`BR-AI-SP-ENDER` on K3's hit) | `:recall (:p 0.6 :n 3 :low-n 1 :low 0.35)` |
| melee | J3 → L the backstep with no trace and ≥ 9 flash step (batch 1's clause was "or") | `:backstep (:p 0.5 :fs 9.0)` |
| melee | K links more often (the way to K3) | `:string-k 0.6` (generic 0.3) |
| melee | K at ≥ 4 traces near him (it materialises them at its first active frame, hit or whiff), or ≥ 1 near with him busy past K1's startup | `:fire (:p 0.6 :n 4 :busy-n 1)` |
| ranged | lay at him every 12 f from 4 m while the flash step stays ≥ 15 after the price (SP1's fan on one roll per lay with a bar, else L), fewer than `:fire :n` near | `:lay (:far 4.0 :reserve 15.0 :every 12 :sp1 0.3)` |
| ranged | J / K in: K at ≥ 4 near (or 1 on a busy opponent); inside 4 m J within J1's reach + 0.4, else K | `:fire (:p 0.6 :n 4 :in 4.0 :busy-n 1)` |
| awakened | MUJITTAI (U) on a threat within reach + 1 m or a hazard within 12 f, one roll per window (0 under 30 guard gauge); else a Step off a lane, a Hoho on the generic roll, else the generic answers (whose guard is U, MUJITTAI too) | `:stance (:p 0.4 :max 120 :gg 30)` |
| MUJITTAI | out by attacking: his whiff / recovery, 120 f, the guard gauge under 30, him idle out of reach (K1 / J1 / the near traces' K / L) | `:stance` |
| JILLIEL | the owl's revival when allowed | `:bankai (:p 0.9 …)` (generic, unchanged) |
| facing him | a CPU facing his awakened forms Steps off his live traces (inside a trace's 10° snap, laid ≥ its delay ago), one roll per new trace, × `*ai-opp-diff*` (`BR-OPP-TRACE`, the old `LB-OPP-TRACE` copied; read off his kits, so no other pairing runs it) | `:opp-trace (:p 0.5)` |

Other `:ai` changes: melee `:o-ender` 0.5 → 0.3 (the O ender rolls before the recall), the owl melee's 0.6 → 0.3; the
melee `:l-after-k` 0.9 / `:l-after-j` 0.6 → none (the enders go through `:sp-ender`; the router would turn any K link's
L into the mode turn). Batch 1's `*br-ai-fire-n*` 4 / `*br-ai-in*` 3.5 m are gone (now `:fire :n` / `:in`).

Tried and changed: the MUJITTAI rule first took the whole threat window (`:none` on a failed roll, the old Lille's
shape): BY 13 → 16, BK 12 → 11, BR 3 → 5, BI 6 → 4, BS 13 → 9, BL 15 → 18 of 20 once the failed roll falls to the
generic answers (kept).

### 13.3 ASSIST AUTO COMBO routes (`BR-ASSIST-COMBO`, every form's `:assist-combo`)

- **Base: J → K → L → L.** His J in a link that hit → its K link (J1 → K2s) on the land frame → L latched on the K link
  (the stance at f4, a combo) → the stance's plan (`BR-AI-KAMAE-PLAN`: the shot on the reeling opponent) pressed once it is
  up; his J eaten meanwhile. The spec's J J J → L → L was built first: the stance after J3 comes from neutral after his
  stagger, and the masher's wins as him with COMBO fell 36 % → 24 %; J → K → L is a real combo (60 %).
- **Melee: K K K → L.** His J in a melee link that hit → its K link to K3 → L the recall with ≥ 1 trace; J3 → L the
  backstep with no trace and 9 flash step.
- **Ranged: L.** His J pressed while free in ranged mode → K in at 4 traces near him, else a lay at him (L) from 4 m with
  the flash step ≥ 15 after it; else his J (J1, back to melee).

The gate's masher never awakens, so only the base route comes up there (logged, BA vs KE, 2 seeds: J1 90, the route's K
54 → K2s 53, L 104 → the stance 52 → the shot 52).

### 13.4 Learning (`learn-def-kit :barro`, the old Lille's §24.9 pattern)

Situations `#(:shot :trace :mujittai)`, answers `#(:guard :hoho :step :attack :back :take)`; reads × `*br-learn-diff*`
(0.5 / 1.0 / 1.5), one roll each, only a learner (a CPU facing a human) runs them.

| Situation | Opens | Read → answer |
|---|---|---|
| `:shot` | his stance's 萬物貫通 shot on a free opponent | at the stance's plan: a guard → the stance's SP1 (three lines, 120 of guard); a Step / backing off → the snap (a pip) else SP1; a Hoho / an attack → TAISHA (a pip) else the stance's SP2 |
| `:trace` | awakened, the human inside a live trace's snap (one he could have seen) | at the onset: a guard → K now; a Step → SP1's fan (ranged); a Hoho → the fire held while he is free (`*br-learn-hold*` 60 f); an attack → U (MUJITTAI) inside 4 m |
| `:mujittai` | his MUJITTAI with the human inside 5 m | at the onset: an attack → he stays (only the whiff exit); waiting → he leaves at once |

`*br-learn-episode*` (:shot 24 :trace 40 :mujittai 60) + the delay. No scripted habits for the learning gate yet.
`tests/learn-test.lisp`: 131 ALL PASS.

### 13.5 Knobs changed

No damage knob changed (the spec's numbers stay). New: `*br-ai-diff*`, `*br-ai-every*` 30, `*br-learn-diff*`,
`*br-learn-episode*`, `*br-learn-hold*` 60, the `:ai` keys above. Removed: `*br-ai-fire-n*`, `*br-ai-in*`.

Damage levers measured for the A/B (none kept): `*br-shot-dmg*` 50 → 60 (BK 9, BI 25 of 60 on stream 100); base
`:guard` 0.5 → 0.35, `:hoho` 0.3 → 0.4, `:dash-back` 0.7 → 0.9 (BK 9); `*br-mult*` 1.3 → 1.4 (BK 10), → 1.5 (BK 24 / 19 /
16, BI 27 / 30 / 29 on streams 100 / 300 / 500, one draw).

### 13.6 Gates (native sim, NORMAL)

The match time leaves the cinematics out (DEVLOG §134); the "with the cinematics" median is given beside it.

**His seven pairings, 20 seeds** (the verdict; every match K.O.):

| Pairing | Median s | With cinematics | K.O. | His wins (P1) / P2 |
|---|---|---|---|---|
| BY | **121.1** | 163.0 | 20 / 20 | 16 / 4 |
| BK | **112.4** | 157.3 | 20 / 20 | 11 / 9 |
| BR | 141.5 | 186.3 | 20 / 20 | 5 / 15 |
| BI | 134.8 | 180.5 | 20 / 20 | 4 / 16 |
| BS | 129.4 | 174.6 | 20 / 20 | 9 / 11 |
| BL | 145.2 | 192.8 | 20 / 20 | 18 / 2 |
| BB (mirror) | 132.1 | 185.3 | 20 / 20 | 9 / 11 |

(Batch 1, 10 seeds: his wins 1 / 4 / 4 / 5 / 4 / 3 of 10.) **60-seed reruns:** BY 115.9 s (153.8 with the cinematics),
45 / 15; BK 112.9 s (157.3), 34 / 26. Both stay under 125 s of play time, inside the window with the cinematics; under
the new measure 14 of the old 21 pairings sit under 125 s too (DEVLOG §134: the window is the user's to restate).
**Reported to the user, not tuned further.**

**Awaken A/B** (`--cmd 39020`: 39000 + 10 × P1's mode + P2's, 0 the kit's rule / 1 always / 2 never; he is P1 in all
seven, so §9's "39060 + b" is 39020), the never-awaken side's wins of 60, streams seed0 100 / 300 / 500:

| BY | BK | BR | BI | BS | BL | BB |
|---|---|---|---|---|---|
| 45 / 41 / 39 | **8 / 11 / 14** | 26 / 28 / 27 | 21 / **17** / 23 | 40 / 40 / 40 | 55 / 53 / 54 | 36 / 41 / 28 |

BK fails on every stream, BI on one: his base form needs the awakening against Kenpachi (as the old Lille's never-awaken
rows, DUEL_LILLE §24.12). The levers tried are in §13.5; only `*br-mult*` 1.5 moves BK, and not on every stream.
**Reported to the user.**

**ASSIST gate** (`assistgate.py`'s jobs, his 13 rows, NORMAL, 20 seeds; P1 the masher):

| assist (k) | masher as him | masher vs him |
|---|---|---|
| none (0) | 51 / 140 = 36 % | 2 / 120 = 2 % |
| COMBO (3) | 84 / 140 = 60 % (the J J J → L route: 24 %) | 24 / 120 = 20 % |
| HOLD U + COMBO + BREAK (10) | 115 / 140 = 82 % | 48 / 120 = 40 % |

**CPU score** (`aieval.py --char 6 --seeds 10`): strength (HARD) 0.083, masher 1.0, signature 0.466, score 0.343, pacing ok (NORMAL medians Y 121.2, K 119.8, R 150.2, I 135.6, S 133.8, L 140.7, all K.O.). Batch 1: strength 0.06, signature 0.37. HARD stays weak:
the other characters' HARD layers came from dream-rsi searches (DUEL_AI_V2, DUEL_LILLE §24); a HARD Kenpachi deals him
~16 000 to ~6 000 in 4 matches (logged), as he does to a HARD Ichigo.

**Isolation and the rest:** the old 21 pairings' rows, companion and summary lines at 10 seeds: byte-identical to the merged head (bd5fd75). `simgate.py
--cvc`: PASS 3 / 3. Host: duel-rules-test 8372 checks ALL PASS (the router, the CPU's pure rules, the kits' keys, the learning
spec and answers), duel-control 89, learn 131, input 33, touch 64, cine 18 pass; `tools/pkgcheck.sh duel` 0 / 0 / 0;
`./build.sh duel` 0 warnings; smoke `run.mjs --secs 8` exit 0 and a script through 82020 (the CPU mirror), 82005 (K
materialised the six traces) and 82002 + J + L (the router): exit 0, no error (J1 hit → L → `BR-L-LINK` → `BR-TO-EN`; K1 hit → L → the same).

## 14. Lead's merge gate (2026-10-10)

- Merged `barro-b1`, `barro-cpu`, `barro-art` on `claude/loving-euler-qhsjxo`. Host suites: rules 8440, control 89, learn
  131, input 33, touch 64, cine 18, all pass; pkgcheck 0 / 0 / 0; `./build.sh duel` 0 warnings; smoke exit 0.
- simgate, 10 seeds, all 28 pairings: the merged head's 813 lines byte-identical to `barro-cpu`'s (the art merge moved no
  sim bit); `--cvc` 3/3.
- The looks gate re-pinned for seven fighters (`tests/style-gates.py`): LOOKS_SEEDS ((1 YS) (56 RI) (32 KL) (39 BK)) (before
  ((1 YS) (5 IR) (0 KL) (18 SI)) over six: the draw changed with the roster length), seven select stills, `cine-barro`
  (his awakening, 82300 + k at frames 30 / 90 / 150). Run on the merged build against a copy of itself: 112 stills
  (before 108), noise floor 0, 132 PASS, 0 FAIL; every cvc scene's "duel match" line names the pinned pair.

## 15. Batch 5: the pendulum and aim points (2026-10-10, branch `barro-v7`)

Decisions V6 and V7 (§1) built. Everything is in `duel/lisp/barro.lisp` (sim, CPU, debug) and `duel/lisp/barro-art.lisp`
(the look); no other character's code or knob moved (the old 21 pairings' rows are byte-identical, §15.6).

### 15.1 What was built

- **The base stance's Step 飛廉脚** (V6): `:br-k-dash` (Lille's `:lb-k-dash` clip), the stance's non-button string
  `:kamae-step` from `:br-kamae` / `:br-kamae-k` / `:br-kamae-re`. 10 flash step, 3.5 m in the stick direction (neutral:
  away from him; his CPU's: straight back) over 12 f, iframes f0–7, f11 back in the stance at its f6 (`:br-kamae-re`, a
  copy entered at f6 with no f0 hook: a fresh 30 / 90 f window, the aim snapped onto him). Once per stance
  (`brs-dashed`, cleared by `br-kamae-enter`); refused when used or short: the press is eaten and nothing happens. The
  stance carries `:step-branch` (the one-hand up-flick stays a Step there, as in Lille's / Ichigo's stances). No charge.
- **Aim points** (V7): ranged L / SP1 / SP2 (`br-lay`) set a point `*br-aim-back*` 0.5 m behind him along his facing
  (`br-aim-point`; the hazard's x / z is the point). L one (3 flash step), SP1 one at each of its shot frames (9), SP2 one
  thick (radius 1.2, 9); refused when short; 16 at most, the oldest dropped. Every step (`barro-tick` →
  `br-traces-aim`) each live trace's line is recomputed: the unit vector from its point through his current position
  (`br-line-dir`, single floats), kept within `*br-aim-freeze*` 0.3 m of the point; stored in `brh-ux` / `-uz` (the hit's
  axis) and the hazard's yaw (the look's, the CPUs'). The line is 31 m from the point (`br-trace-vol`: a `:cap` 0 → 31,
  radius 0.6 / 1.2).
- **Materialising** (V6, V7): `br-materialise-one`: the lines turned through him now, then the one live trace whose line
  (point-to-segment on the ground, `br-seg-dist`) passes nearest the opponent within `*br-near-r*` 2.5 m (`br-pick`; a tie:
  the larger id, the newer) becomes a 2-frame 萬物貫通 hit along its line as it is (no snap), 30 a line / 90 the thick one
  × the form's damage, as before. If he is not on that line the shot misses and the trace is spent. Every melee J
  (JILLIEL's and the owl's J1 / J2 / J3 and the J2s copies) calls it at its first active frame (`br-j-mat` on-frame at S),
  hit or whiff; a melee K (`:params (:mat-k t)`) only from `barro-hit` on a touch (hit or block: `br-k-mat-p`), never on a
  whiff; a K's one window touches once, so once a K. Refunds 0 (`*br-refund*` / `-block*`, the owl's: 0.0).
- **Ranged J = TENSHIN in** (V6): `:br-tenshin` (clip `:lb-w-tenshin-in`) and the owl's `:br-o-tenshin`
  (`:lb-o-tenshin-in`), the old `:lb-switch-in` copied: 16 f wind-up, then (`br-tenshin-go`) the dash at him at 30 m/s, at
  most 7 m, stopping 1 m short (`br-tenshin-dist`, `br-tenshin-dash-f`), iframes 9, free; melee 6 f into the dash or at its
  end (`br-tenshin-form`); from the dash's end (`br-tenshin-tick`, the old switch + link ticks) the latch starts the melee
  J1 (J1 by default; a K pressed during the dash makes it K1, the last press wins), else the rest of the startup is
  skipped and R 8 follows. J1's own first active frame then materialises one trace. The 2 f cancel: `:br-tenshin-c` /
  `:br-o-tenshin-c` (entered at f14) out of any ranged L / SP1 / SP2 from its active end (`br-lay-tick`; the old EN
  cancel window). Ranged K: unchanged (melee in place + K1). The ranged MUJITTAI's J drops to ranged, then TENSHIN.
- **J3 → L backstep** (V6): 5 m / 14 f, iframes 9 (`*br-backstep-iframes*` 7 → 9), 10 flash step (`*br-backstep-fs*`,
  paid at f0), ranged at f0 (`br-backstep-go`); from f14 (`br-backstep-tick`, `br-backstep-lay-ok-p`) a human's L / SP1 /
  SP2 press cancels its 8 f recovery into the lay; before, nothing starts. Short of 10: BARRO-OK refuses the L router's
  backstep, so L after J3 does nothing (no mode turn). J1 / J2 → L: the mode turn, unchanged.
- **The look** (functional; the art batch polishes): BR-TRACE-LOOK draws each live trace's point as a small jade reticle
  on the floor (Lille's `%lb-reticle`, turning; SP2's bigger) and its line from the point through him to the wall along
  the hazard's yaw (the owl's gold), every frame. Measured with 82398 (82013's three points; 82005's six): the looks 0 B
  over 10 draws (the first probe of a page reads a one-off heap step in every column, Lille's draw too). Not done: the
  owl's backstep clip (`:br-o-backstep`) still steps its lift on f13, while the owl now turns ranged at f0 (re-timed in §17).

### 15.2 Readings of the spec

- **SP1's frames:** the spec quotes f12 / f22 / f32 "as its moves define"; the ranged SP1 moves (`:br-e-sanren`,
  `:br-oe-sabaki`) lay at **f6 / f12 / f18** (their clips are timed to that), so the points go there; he turns at the
  opponent on each. The fan offsets (−6 / 0 / +6°, `*br-sp1-fan*`) are kept on the points' facing [G], so the three lines
  part by 6° about him even when nobody moves.
- **The stance Step's iframes:** V6's table says f0–7 → `*br-kamae-dash-iframes*` 8 (the old Lille's 9 was f0–8).
- **The backstep short of flash step:** the old Lille's rule for TENSHIN out short of its price (LILLE-OK refuses it):
  refused, L after J3 does nothing.
- **"A lay only after the dash's 14 f":** a lay pressed from f14 cancels the backstep's 8 f recovery (「衝刺結束才能接」);
  before f14 the backstep runs on.
- **The cancel window** ("mid-move"): the old Lille's, from the lay's active end (after its points are set), not earlier.
- **TENSHIN's link:** J1 by default (the J press that started it); a K during the dash: K1 (the old latch).
- **The CPUs' "on a line":** what a CPU reads as standing on a trace is its line within the trace's radius + `*br-ai-on*`
  0.5 m ([G]; the 2.5 m pick would read every line at melee range, as they all run through him): his going in, the
  opponents' Step off it (BR-OPP-TRACE), the learner's `:trace`.

### 15.3 Knobs (old → new, 2026-10-10)

| Knob | Value |
|---|---|
| `*br-near-r*` | 2.5 (the user, V6); `*br-near-deg*` 10 removed |
| `*br-aim-back*` / `*br-aim-freeze*` | 0.5 (the user, V7) / 0.3 [G] |
| `*br-refund*` / `-block*` / `*br-owl-refund*` / `-block*` | 4 / 2 / 5 / 2 → 0.0 (the user, V6) |
| `*br-backstep-iframes*` / `*br-backstep-fs*` | 7 → 9 / new 10.0 (the user, V6) |
| `*br-tenshin-in*` / `-stop*` / `-speed*` / `-f*` | 7.0 / 1.0 / 30.0 / 14 (the old Lille's, copied) |
| `*br-tenshin-windup*` / `-windup-c*` / `-iframes*` / `-form*` | 16 / 2 / 9 / 6 (copied); `*br-tenshin-s*` 30 and `-enter*` 14 derived |
| `*br-kamae-dash*` / `-f*` / `-back*` / `-iframes*` / `-fs*` | 3.5 / 12 / 11 / 8 / 10.0 (copied; 8 from V6's f0–7) |
| `*br-trace-len*` | 31.0, now from the aim point |
| `*br-ai-on*` | 0.5 [G] |
| CPU keys | ranged `:fire (:p 0.8 :n 1 :in 8.0 :close 3.0)`, `:lay (… :reserve 10.0 … :cap 2)`; melee `:backstep (:p 0.6 :fs 13.0 :n 3)`; melee `:fire` removed |

### 15.4 The CPU (only what the new rules need; the full pass is the next batch)

- Ranged: lay a point at him from 4 m (`br-ai-lay`, at most 2 on his line, keeping 10 flash step); go in with J (TENSHIN)
  when he stands on a line within 8 m (one roll per point set, `:fire :p`), inside 3 m, or starved (no lay above the
  reserve) (`br-ai-in-plan`, `br-ai-in-p`); the same rule cancels a lay into TENSHIN in at its active end (`br-ai-cancel-p`,
  the 2 f wind-up; `br-ai-seen`, the old LB-AI-SEEN).
- Melee: the generic J / K strings (every J materialises on its own); J3 → L the backstep with ≥ 13 flash step and < 3
  traces; K3 → L the recall at ≥ 3 (unchanged). The melee K-at-traces rule is gone (a K whiff no longer fires).
- ASSIST ranged: J while free → TENSHIN at a point on his line, else a lay from 4 m.
- Logged per match (10 seeds, his 70 matches as P1): 6.4 TENSHIN (4.5 of them the lay's cancel), 7.7 materialised,
  4.7 trace hits, 8.4 points set, 1.1 backsteps, 0 recalls (the J's spend the points before a K3 sees 3), no stance Step.
- Left for the CPU batch (done in batch 6, §16): the stance Step (HIRENKYAKU) in his base CPU's plan; walking so the lines cross him (he lays and
  dashes; he does not yet steer the lines); the recall (it never comes up now); K's touch-only materialise in his melee
  choices; the learner's `:trace` situation and BR-OPP-TRACE on the new lines (read as "on a line", untuned); his HARD
  layer; ASSIST's melee route (K K K → L assumes traces to recall); `aieval.py --char 6`, the ASSIST gate, the awaken A/B.

### 15.5 Debug commands (DUEL_GAMEPLAY 82000 row)

82013 forced ranged 6 m out with 3 points set around him (−30 / 0 / +30°: the middle line through P2), 82016 the same as
the owl, 82014 the base form 6 m out with the stance started (Step), 82015 forced melee 1.4 m out (J J J → L), 82030 a
`duel probe barro-trace` line per live point (id, point, direction, the line's distance to P2), 82031 the probe line only.

### 15.6 Gates (2026-10-10, branch `barro-v7`)

- Host: duel-rules-test 8099 checks ALL PASS (8440 before: the four ranged forms' J is now TENSHIN, a move with no hit
  window, so the generic hit-based string checks skip them as they skip Lille's EN forms; the Breaker-vs-J1 check skips a
  TENSHIN J; the angle-snap checks went; the batch's came in: the stance Step, the pick (2.4 in, 2.6 out, nearest, tie →
  newer), J / K triggers, refunds 0, the aim point, the line and its freeze, the hit on / 2 m off the line, TENSHIN's
  numbers and cancel, the backstep); duel-control 89, learn 131, input 33, touch 64, cine 18 pass.
  `tools/pkgcheck.sh duel` 0 / 0 / 0. `./build.sh duel` 0 warnings. Smoke `run.mjs --secs 8`: exit 0.
- Browser script (82013 J; 82016 J; 82015 J J J L, then L; 82014 Step, Step): exit 0, no error. 82013: TENSHIN, J1, the
  middle point materialised and hit (P2 1300 → 1246: J1 24 + the line 30); the other two lines then ran 0.04 m from P2
  (they turn through him). The owl: one point spent, P2 −65. The backstep: ranged, flash step 100 → 90, then L set a
  point (87) whose line runs through P2. The Step: 100 → 90, the second Step in the same stance refused (90).
- The old 21 pairings at 10 seeds: all 559 lines (210 rows, companion and summary lines) byte-identical to the merged
  head's (dc3a9d0). `simgate.py --cvc`: PASS 3 / 3.
- His seven pairings, 10 seeds (play time without the cinematics; before = dc3a9d0), every match K.O.:

| Pairing | Median s (before) | With cinematics | K.O. | His wins (P1) / P2 (before) |
|---|---|---|---|---|
| BY | 118.2 (121.3) | 162.6 | 10 / 10 | 9 / 1 (7 / 3) |
| BK | 115.9 (122.2) | 159.0 | 10 / 10 | 8 / 2 (6 / 4) |
| BR | 130.1 (152.3) | 177.8 | 10 / 10 | 6 / 4 (2 / 8) |
| BI | 142.5 (136.4) | 192.9 | 10 / 10 | 6 / 4 (2 / 8) |
| BS | 132.9 (134.7) | 177.3 | 10 / 10 | 9 / 1 (4 / 6) |
| BL | 139.3 (141.2) | 191.5 | 10 / 10 | 10 / 0 (9 / 1) |
| BB | 131.1 (138.5) | 185.1 | 10 / 10 | 3 / 7 (5 / 5) |

BY and BK stay under 125 s (accepted exceptions at 60 seeds since V5); he now wins most cross pairings. No damage knob was
touched (reported, not tuned).

## 16. Batch 6: the CPU on the pendulum and aim points (2026-10-10, branch `barro-cpu2`)

§15.4's list done. Everything is in `duel/lisp/barro.lisp` (his CPU, ASSIST and learning sections, his kits' `:ai`, two debug
flags) and `tests/duel-rules-test.lisp`; no other character's code or knob, and no damage / frame / cost knob of his, moved
(the old 21 pairings' rows are byte-identical, §16.7). Every new chance is a `:p` × `*br-ai-diff*` (EASY 0.5 / NORMAL 1.0 /
HARD 1.5, at most 1), rolled once per event.

### 16.1 Reading the lines (what the CPUs see of decision V7)

- **Within 8 m every line is "on him at the dash's end".** TENSHIN in stops 1 m short, and every line runs from its point
  through Lille, so at the dash's end each line passes at most 1 m from him: inside its radius 0.6 + `*br-ai-on*` 0.5 (and
  inside the real hit, 0.6 + his hurt radius ~0.35, for any line within ~70° of the dash). The dash-end reading
  (`BR-DASH-LINE-GAP`, `BR-END-COUNT`) therefore tells lines apart only beyond 8 m (the long dash). The steering reads the
  line **on him now** (`BR-NEAR-COUNT`): from 6 m a line through Lille passes within 1.1 m of him only when Lille stands
  near the ray from its point through him (within ~9° at 7 m).
- **Steering** (`BR-STEER`, `BR-STEER-TARGET`): Lille puts a point's line on him by standing on the ray from the point
  through him; the strafe that closes his distance to the nearest such ray (points behind him toward the opponent only) is
  written to `BRAIN-STRAFE` and the neutral walk carries it.
- **A crossing**: a line comes onto him now without a point set since the last look (Lille walked it there, or he walked
  into it). The fire roll is made per crossing (and per point set, below).

### 16.2 The CPU by form (`:ai` keys at NORMAL)

| Form | Rule | Keys (old → new) |
|---|---|---|
| base | the stance's Step 飛廉脚 once a stance, at its plan (f6; `BR-AI-KAMAE-STEP`, one roll): his attack coming (perceived, `BR-AI-THREAT-P`) → :threat: aside and back off a lane (`BR-AI-STEP-STICK`: 60° off straight back, `LINE-OFF-STRAFE`'s side) else straight back; him inside 3 m, or running at him inside 5 m, with no pip → :p: back; never on a reeling opponent or short of 10 flash step; the window after the Step plans again (the shot / snap / TAISHA as before) | new `:kamae-step (:p 0.4 :threat 0.5 :close 3.0 :rush 5.0)` |
| ranged | a stay (coming into a ranged mode) rolls its goal once (`BR-AI-GOAL`): from 6 m the bank (6 points, for the K route) under :bank-p, else 2–4 evenly; closer 1 (the point and the 2 f cancel); and once whether it steers (:steer) | `:lay (… :cap 2)` → `(:far 4.0 :reserve 10.0 :every 12 :sp1 0.3 :near 6.0 :goal (2 4) :close-goal 1 :bank-p 0.25 :bank-goal 6 :patience 90)`; new `:steer (:p 0.4)` |
| ranged | lays at him (L, SP1's fan) every 12 f below the goal, the flash step staying over 10; with the goal set and no line on him now, a steering stay walks a line onto him (`BR-AI-STEER`); after 90 f of it without one, a new point | |
| ranged | J (TENSHIN in, `BR-AI-IN-WHY`) within 8 m: him perceived busy for 30 f (the dash and J1) on his action's roll (:busy), inside 3 m, a line on him at the dash's end with the goal set (:p, one roll per event: a point set in a stay that does not steer, or a crossing), starved; from 8 to 13 m only on a crossing (**the long dash**: J1 whiffs short of him, the line it spends does not) | `:fire (:p 0.8 :n 1 :in 8.0 :close 3.0)` → `(… :far-in 13.0 :busy 0.5 :busy-f 30)` |
| ranged → melee | TENSHIN in by his CPU rolls the melee route (`BR-AI-ROUTE-IN`, :p): **K** with ≥ :bank points set (K1 latched at the dash's end, then the K links: K3 → L the recall), else **J** (J1, the J links, J3 → L the backstep); each hit latches the route's next link (`BR-AI-ROUTE-LATCH`, the old Lille's LB-AI-ROUTE); a failed roll leaves the generic strings | new `:route (:p 0.6 :bank 5)` |
| melee | free: the opener in reach on his action's roll: K1 with ≥ :bank points, J1 with a line on him (every J spends the nearest line: `BR-AI-MELEE`) | `:route` |
| melee | K3 → L the recall at n ≥ :n, ≥ :low-n under 35 % Reishi, or ≥ :off-n with no line on him (lines that would miss, taken back); J3 → L the backstep below 3 points and 13 flash step (unchanged) | `:recall (:n 3 …)` → `(:p 0.6 :n 2 :low-n 1 :low 0.35 :off-n 1)` |
| awakened | MUJITTAI on a threat, its exits, the owl's revival, the owl's two modes: unchanged (the owl's kits carry the same keys) | |

Every chance scales by difficulty; the K route needs 5 points (three K touches spend three, decision V6, so 2 are left: the
recall's 二連; the bank's 6 leave 3: 四連).

### 16.3 The HARD layer (`*br-ai-hard*` 0 / 0 / 1, the kits' `:hard`)

`BR-AI-HARD` (before the form's own rules; his action's react roll under the level, so EASY and NORMAL never): a 萬物貫通 line
**on his recovery** (perceived, at least :punish-f frames left: the base form's stance and the shot, or the snap with a pip,
18 f from 2.5 m; ranged TENSHIN in, 30 f; melee J with a line on him) or **into a guard one line breaks** (him guarding at
≤ 40 of his guard gauge: a 萬物貫通 block drains 40). Keys: base `:hard (:near 2.5 :punish-f 18 :crush 40.0)`, melee
`(:near 0.0 :punish-f 12 :crush 40.0)`, ranged `(:near 2.0 :punish-f 30 :crush 40.0)`. Fires ~1.1 times a HARD match.

Tried and dropped (his HARD against the five HARD CPUs, 10 seeds, both seats, 120 matches): ranged TENSHIN only through
the lay's 2 f cancel at HARD (no 16 f wind-up from neutral): 0.175 → 0.108; smaller goals (1–2, no bank): 0.142.

### 16.4 The opponents and the learner (the moving lines)

- **BR-OPP-TRACE** (a CPU facing his awakened forms): one roll per **crossing** (onto one of his lines, its radius +
  `*br-ai-on*`, after being off every line; at most once in `*br-opp-gap*` 30 f) or per line newer than the ones it rolled
  for (was: per new trace only); the Step across the line from its point through him (`LINE-OFF-STRAFE`). New `BRS-OPP-ON`,
  `BRS-OPP-T`.
- **The learner's `:trace`** opens on a crossing too (`BRL-ON-WAS`); its `:step` answer needs him off every line **and** moved
  ≥ `*br-learn-off*` 0.5 m from the onset (a line swinging off him with Lille is not his answer); a guard read now answers
  with **J** (TENSHIN in at the dash's end / a melee J on a line on him: a K spends one only on a touch since V6) instead of K.

### 16.5 ASSIST AUTO COMBO (`BR-ASSIST-COMBO`)

- **Base**: unchanged (J → K → L → the stance's plan).
- **Melee**: his J in a link that hit, on its land frame: the K links while the points left after their touches still
  number 3 (`BR-AS-K-ROUTE-P`: 5 at link 1, 4 at link 2) → K3 → L the recall (n ≥ 1); else the J links (J J J) → J3 → L the
  backstep with 13 flash step (its 10 + a lay's 3). (Was: K links to K3 always, the recall at n ≥ 1, the backstep only with
  no trace.)
- **Ranged**: his J while free: J (TENSHIN in) with a line on him at the dash's end, else an aim point at him (L) from 4 m with
  10 flash step left after it; his J in the backstep from its f14 lays that point at once (`BR-AS-BACKSTEP`: the recovery
  cancelled into it); his next J in the lay cancels it into TENSHIN in (2 f) along that line (L point → J dash → J1 …).

### 16.6 Knobs and code

New: `*br-ai-hard*`, `*br-opp-gap*` 30, `*br-learn-off*` 0.5, the `:ai` keys above; pure and host-tested:
`BR-AI-KAMAE-STEP-PLAN`, `BR-AI-STEP-STICK`, `BR-AI-GOAL`, `BR-DASH-LINE-GAP`, `BR-STEER`, `BR-AI-IN-WHY` (replaces
`BR-AI-IN-PLAN`), `BR-AI-ROUTE`, `BR-AI-HARD-WHY`, `BR-AS-K-ROUTE-P`, `BR-AI-RECALL-P`'s :off-n. Debug (DUEL_GAMEPLAY 82000
row): 82040 / 82041 the ASSIST gate's masher as him plays from JILLIEL melee (off / on); 82050–82052 his CPU at EASY /
NORMAL / HARD whatever the gate's difficulty, 82053 off. Pacing keys: `ai-kamae-step`, `ai-step-back` / `-side`,
`ai-goal-1` … `-4` / `-bank`, `ai-steer`, `ai-cross`, `ai-in-far`, `ai-lay-bored`, `ai-route-j` / `-k` / `-none`,
`ai-hard-punish` / `-crush`, `as-j-link`.

### 16.7 Gates (2026-10-10, branch `barro-cpu2`; native sim; before = the parent 99fba9c, measured the same way)

- **Isolation**: all 28 pairings at 20 seeds: the old 21 pairings' 1161 lines (rows, companion and summary lines)
  byte-identical to 99fba9c's. `simgate.py --cvc`: PASS 3 / 3.
- **His seven pairings, 20 seeds** (play time without the cinematics; every match K.O.):

| Pairing | Median s (before) | With cinematics | K.O. | His wins (P1) / P2 (before) |
|---|---|---|---|---|
| BY | **104.7** (110.8) | 148.0 | 20 / 20 | 17 / 3 (16 / 4) |
| BK | **108.4** (109.3) | 148.6 | 20 / 20 | 15 / 5 (18 / 2) |
| BR | 139.7 (132.1) | 184.8 | 20 / 20 | 14 / 6 (13 / 7) |
| BI | 133.9 (135.6) | 182.9 | 20 / 20 | 12 / 8 (12 / 8) |
| BS | 133.2 (127.0) | 174.0 | 20 / 20 | 16 / 4 (15 / 5) |
| BL | 130.2 (133.6) | 177.9 | 20 / 20 | 18 / 2 (19 / 1) |
| BB (mirror) | **117.7** (118.1) | 169.4 | 20 / 20 | 8 / 12 (8 / 12) |

  **60-seed reruns**: BY 112.3 s (152.4 with the cinematics), 50 / 10; BK 108.7 s (152.1), 42 / 18 (both under 125 s:
  the accepted exceptions of decision V5, which measured 115.9 / 112.9 s); BB 117.7 s (167.9), 27 / 33 (the mirror under
  125 s, as before this batch: 118.1 s at 20 seeds). **Reported, not tuned.**
- **His play, per match as P1** (his 140 matches, before → after): points set 9.2 → 14.6, TENSHIN in 6.2 → 6.6 (the lay's
  2 f cancel 4.4 → 3.1), lines materialised 8.2 → 11.7, trace hits 5.0 → 7.8 (guarded 0.2 → 0.5), backsteps 0.9 → 1.5,
  recalls 0.03 → 0.18, the stance's Step 0 → 0.14, steering stays 0 → 2.4, crossings 0 → 2.2, long dashes 0 → 0.16, routes
  J 5.0 / K 1.2; a CPU facing him rolls 6.8 → 14.0 times to Step off his lines and Steps 3.4 → 6.8 times.
- **Awaken A/B** (`--cmd 39020`: he is P1 and never awakens; the never-awaken side's wins of 60, streams seed0 100 / 300 /
  500; before = 99fba9c for BK / BB, §13.6 (batch 4) for the rest):

| BY | BK | BR | BI | BS | BL | BB |
|---|---|---|---|---|---|---|
| 42 / 47 / 46 | **18 / 17 / 11** | 31 / 27 / 28 | 23 / 22 / 20 | 42 / 48 / 38 | 51 / 57 / 55 | **6 / 12 / 6** |
| (45 / 41 / 39) | (8 / 11 / 14) | (26 / 28 / 27) | (21 / 17 / 23) | (40 / 40 / 40) | (55 / 53 / 54) | (6 / 5 / 8) |

  Every A/B match K.O. but one (BR, stream 100: 59 / 60, a time-up with his base form never awakening). BK still fails, better than before (the stance's Step is the base form's only CPU change at NORMAL);
  BI passes on all three streams now; **BB fails, as it did on the parent** (6 / 5 / 8: batch 5's pendulum made the awakened mirror much
  stronger than the base form; batch 4 measured 36 / 41 / 28). **Reported to the user** (the base form's damage and the
  awakening's rules are the user's; decision V5's 「先試玩再決定」 stands).
- **CPU score** (`aieval.py --char 6 --seeds 10`, before → after): strength (HARD) 0.142 → 0.150, masher 1.0 → 1.0,
  signature 0.401 → 0.443, score 0.365 → 0.379, pacing ok (NORMAL medians Y 109.2, K 107.8, R 137.8, I 132.8, S 143.2, L 118.8,
  all K.O.).
- **His difficulty ladder** (aieval's learning-gate runner with debug 82050–82052: his CPU at each difficulty against the five
  HARD CPUs, both seats, 10 seeds, 120 matches): EASY 0 / 120 = 0.000 ≤ NORMAL 3 / 120 = 0.025 ≤ HARD 18 / 120 = 0.150 (by
  opponent at HARD: Y 7, K 3, R 0, I 1, S 7, L 0 of 20). Both sides at one difficulty (aieval's strength runs at E / N / H):
  0.775 / 0.717 / 0.150 (before 0.825 / 0.767 / 0.142): the five HARD CPUs (dream-rsi layers, DUEL_AI_V2) are the cliff,
  not his HARD.
- **ASSIST gate** (`assistgate.py`'s jobs, his 13 rows, NORMAL, 20 seeds; P1 the masher; before = 99fba9c):

| assist (k) | masher as him | masher vs him |
|---|---|---|
| none (0) | 51 / 140 = 36 % (36 %) | 0 / 120 = 0 % (1 %) |
| COMBO (3) | 81 / 140 = 58 % (61 %) | 12 / 120 = 10 % (14 %) |
| HOLD U + COMBO + BREAK (10) | 111 / 140 = 79 % (80 %) | 36 / 120 = 30 % (28 %) |

  The masher never awakens, so his rows play the base route (unchanged); the "vs him" rows move with his CPU. With 82041 (the
  masher as him forced into JILLIEL melee, 10 seeds, his 7 rows): none 31 / 70 = 44 %, COMBO 24 / 70 = 34 %; the melee
  route fired 7889 J links, 53 K links, 62 backsteps (each followed by TENSHIN in); no recall (the masher's strings start
  with few points) and no ranged route: the masher presses J only inside J1's reach (it walks in out of the backstep), where
  there is no line to dash along and no room to lay. The ranged route and the backstep's lay need a J pressed at range.
- **Host**: duel-rules-test 8109 checks ALL PASS (8099 before: the batch's pure rules, the kits' keys), duel-control 89,
  learn 131, input 33, touch 64, cine 18 pass. `tools/pkgcheck.sh duel` 0 / 0 / 0. `./build.sh duel` 0 warnings. Smoke
  `run.mjs --secs 8`: exit 0; a browser script (39011, then 82020: the CPU mirror, both awakening, 64 s) exit 0, no error,
  both in JILLIEL by t 3719.

### 16.8 For the user

- **BB's and BK's awaken A/B rows fail** (the never-awaken side 6 / 12 / 6 and 18 / 17 / 11 of 60; pass ≥ 20). BB failed
  on the parent too (6 / 5 / 8, batch 5's pendulum); BK improved (8 / 11 / 14). Only his base form's damage or the
  awakening's rules would move them; decision V5 left that to the playtest.
- **The mirror BB runs 117.7 s** (60 seeds; 118.1 s before this batch), under 125 s; BY / BK stay under it as accepted.
- **He wins 92 of 120 cross matches at NORMAL** (93 before): strong at NORMAL, weak against the HARD CPUs (0.15).

## 17. Art: aim points and the pendulum (2026-10-10, branch `barro-art2`)

Presentation only, in `duel/lisp/barro-art.lisp` (no other file's code moved; `lille-art.lisp` untouched): every simgate row
of all 28 pairings at 10 seeds byte-identical before / after (815 lines), `--cvc` 3 / 3. The brief (the lead, relaying the
user's V7 look line, 「軌跡會隨時對準自身」): the point a sigil on the floor, the line readable as pivoting on Lille, a flare
when set, SP2's thick line distinct, the picked line flashing along itself when it fires and a miss visibly missing, the
opponent still able to read every line (the counterplay).

### 17.1 The owl's backstep (decision V6: ranged at f0)

- `:br-o-backstep` stepped its root 0.35 m down on f13 (the frame the form used to turn ranged). Since V6 the form (and the
  owl's kit `:lift`, `*BR-OWL-LIFT*` 0.35) turns at f0, so the old clip popped the owl 0.35 m up on f0 and dropped it back
  on f13. Re-timed: every key is now written in EN's lift (drawn height = root u + 0.35): f0 the fold with u −0.38 (drawn
  −0.03, the floor the J3 leaves), f6 −0.05 (drawn 0.3, the leap up and back), f13 0.05 (drawn 0.4), EN's stance by f17
  (drawn 0.35). No step anywhere; same length (22 f) and marks (the host clip test passes unchanged). `barro.lisp`'s
  `*BR-OWL-CLIP-MAP*` docstring still says "its lift on f13" (a file this batch did not touch; for the lead).
- JILLIEL's backstep keeps Lille's `:lb-w-tenshin`: JILLIEL's two forms float at the same lift (0.5), so the f0 turn only
  swaps the body to EN's fanned wings at the move's own first frame (a snap like any move start); the 5 m glide back reads
  as "out to range" (stills `jl-backstep-*`). No `:br-backstep` clip drawn (it would also need `barro.lisp`'s move `:clip`).
- TENSHIN in (ranged J, `:lb-w-tenshin-in` / the owl's `:lb-o-tenshin-in`, item 3 of the brief): the 16 f wind-up, the dash,
  KIN's body at the dash's end and J1's swing on him read as one dash ending in J1 (stills `tenshin-d*`, `owl-tenshin-d*`);
  the owl's lift step falls inside the dash (f22) as in Lille's. Unchanged.

### 17.2 Aim points (decision V7's look, replacing batch 5's reticle)

All drawn by `BR-TRACE-LOOK` (each live trace, HAZARD-DRAW) and `BR-DRAW` (his draw hook, before the hazards), jade, the
owl's gold (LILLE-DRAW's flag); flat floor meshes for what must stay readable, the toon fx kit for what flashes:

| Part | Look | Numbers |
|---|---|---|
| The point | a sigil on the floor: a ring, eight ticks round it, a chevron past it pointing along the line toward him; Lille's eye mark turning inside (the owl's in gold: `:br-reticle-gold`, Lille's mesh) | r 0.42 (SP2 0.7); meshes `:br-sigil-jade` #B4DCC4 / `:br-sigil-gold` #E2CC8E |
| The line | value steps along it, read from the point: dim (0.8 w) up to 2.5 m before him, the light tone (1.35 w, `:br-line-jade-hi` / `-gold-hi`) from 2.5 m before to 3.5 m past him, then the plain tone (w) to 12 m past him, 0.6 w to 20 m, 0.35 w to its 31 m end (or the wall) | w 0.042 (SP2 0.11) |
| The pivot | a light dash running along each line from the point through him and on, fading past him to the end (one 3.8 s lap, 9 m/s, its own phase per trace); a thin ring on the floor under him while he has live traces (`%BR-HINGE`: where they all turn) | dash 1.6 m; ring r 0.62 |
| SP2's thick line | wider steps, its 1.2 m lane edged on both sides (thin lines at ±1.2 m), a second ring round its sigil at 1.2 m, a wider dash | `*BR-TRACE-R-THICK*` read, not copied |
| Set (its first 14 frames, the hazard's age: held by a hitstop) | the sigil stamped in at 1.5 x settling by f8; an `fx-envelope` (flash 1, grow 3, hold 2, out 8): a white flash at the point, a ring spreading to 3.8 r, a star; the line drawn out from the point to its end in 4 frames, a light head at its tip | 7.5 m a frame |
| Fired (a J / K materialised it; kept in `*BR-SHOT*`, 4 per side, the fx clock) | a light head runs the line at the shot's height (1.2 m) from the point through him to its end in `*BR-FIRE-F*` 5 frames, a star where it passes through him, the spent line flashes on the floor (light tone, thinning over 14 frames), the sigil bursts (a ring to 4 r, a star); over the sim's own LB-LOOK shot / beam / 裁きの光明 | `*BR-FIRE-LIFE*` 0.6 s |
| Missed (its hazard gone with its hit unspent: `hazard-hits-left` > 0) | a grey puff and two ink streaks at the point of the line nearest him (where it passed him by), three ink dashes across the gap to him | fading k² over the 0.6 s |

- His place for the trace looks: BR-DRAW writes his and the opponent's x z into `*BR-AT*` each frame with a DO-ENTITIES pass
  over the transforms (`%BR-PLACE!`; a component getter conses 8 B in this build, the pass does not); fighters draw before
  hazards, so the looks read this frame's place.
- 0 B a frame (82398, 10 draws each, after a page's first probe): the trace looks 0 (3 and 6 traces, JILLIEL and the owl),
  `%BR-PLACE!` 0, the hinge 0, a fired (missed) trace's look 0; BR-DRAW 80 B / 10 (its existing fighter lookup).
- The recall's fly-back look (§12) is unchanged: the live look still notes each trace in `*BR-SEEN*`.

### 17.3 Debug commands (DUEL_GAMEPLAY 82000 row)

82100+k art scenes 15–19 (k + 20 the front view for 15 / 17 / 18): 15 JILLIEL ranged 6 m out with a thick SP2 point (3 m
behind, −35°) and an L point (2.5 m, +30°), then the L lay (the set on its f4: hold with 82200+f); 16 the owl's (82016, then
its lay; P1 only); 17 JILLIEL melee 3 m out, one L point 4 m behind and 50° off (its line ~2.3 m beside him: picked, missed),
J1 started; 18 the same with a thick SP2 point 12° off (J1 whiffs, the line hits); 19 17 as the owl (P1 only). 82398's line
now ends `place / hinge / fired`.

### 17.4 Stills (not committed; `tests/shots/barro2/`)

`node tools/run.mjs dist/duel --fixed-dt 16.666667 --script …` (four scripts: held scenes 82299 / 82200+f / 82100+k;
timed shots after 82117–82119 and 82137; 82013 / 82016 + J; 82015 J J J → L then L, 82014 Space, the idle points); `before-*`
on the batch-5 build (99fba9c), `after-*` on this one. Contact sheet `barro2-sheet.png` (24 tiles: the idle points behind /
front / owl, the set, TENSHIN's hit, the thick hit, the misses, the owl's backstep before / after, JILLIEL's backstep, the
lay after the backstep, the stance Step).

### 17.5 Gates (2026-10-10)

Host suites: duel-rules 8099, duel-control 89, learn 131, input 33, touch 64, cine 18, all pass. `tools/pkgcheck.sh duel`
0 / 0 / 0. `./build.sh duel` 0 warnings. Smoke `run.mjs --secs 8` exit 0; the still scripts exit 0. simgate, 10 seeds, all
28 pairings: 815 lines byte-identical to 99fba9c's; `--cvc` PASS 3 / 3. Needs the user's eyes (checked by numbers and
stills only).

## 18. Decision V6a built (2026-10-10, branch `barro-v6a`)

Decision V6a (§1, 「L 放軌跡後快速連結 J 才會前衝」; other ranged J 「原地切近戰出 J1」; 「L、SP1、SP2 都可以」) built. Everything is in
`duel/lisp/barro.lisp` (sim, CPU, ASSIST, learner, a debug line) and `tests/duel-rules-test.lisp`; no other character's code,
and no damage / frame / cost knob of his, moved (the old 21 pairings' rows are byte-identical, §18.5).

### 18.1 What changed

- **Ranged J = melee J1 in place** (JILLIEL's `:jilliel` and its MUJITTAI: `:br-w-j1`; the owl's `:shin` and its MUJITTAI:
  `:br-o-j1`), exactly as the ranged K: `BR-MELEE-IN` at its f0 turns him melee at once, no dash, and the J1's first active
  frame materialises one line as every melee J does (V6). The ranged MUJITTAI's J drops to ranged, then this J1.
- **TENSHIN in only as the 2 f cancel of a J in a ranged L / SP1 / SP2's window** (JILLIEL's `:br-e-lay` / `-sanren` /
  `-nijushi`, the owl's `:br-oe-lay` / `-sabaki` / `-trompete`): batch 5's window, now a pure rule `BR-DASH-WINDOW-P`: from
  the move's active end (every point of it set) to the end of its recovery (L f7–f12, SP1 f20–f31, SP2 f26–f40; the owl's
  L f7–f11, SP1 f20–f30, SP2 f18–f25). `BR-LAY-TICK` cancels into `:br-tenshin-c` / `:br-o-tenshin-c` (entered at f14: the
  dash on f16); the dash, its numbers and its J1 / K1 link are V6's, unchanged.
- **The neutral 16 f wind-up path is gone**: no command of any form starts `:br-tenshin` (kept only as the cancel copies'
  template; the owl's `:br-o-tenshin` copy deleted). `*br-tenshin-windup*` 16 stays: it is still referenced (the dash's
  frame in the move, `*br-tenshin-enter*` = 16 − 2); its docstring now says so (the §15.3 row "16 f wind-up from neutral"
  is history).
- "After a backstep before a lay": the backstep (J3 → L) takes only a lay from its f14; a J pressed in it is left buffered
  and, once the backstep ends, is the ranged J: J1 in place.

### 18.2 The latch reading

[G] **No latch of its own: the vpad's input buffer, as every cancel in the game and as the old Lille's EN cancel
(`LB-EN-TICK`, the same code).** A J press stays buffered `*input-buffer*` 10 frames; the window reads it on its first frame.
So a J pressed from the frame the move's last point is set always dashes (every lay's last point is within 10 f of its
window: L f4 → f7, SP1 f18 → f20, SP2 f20 → f26, the owl's SP2 f12 → f18; host-tested): **a quick J after the lay dashes**,
and on L (13 f) any J during the move does. A J pressed 10 f or more before the window (only in SP1 between its first
points, ~f6–f10, or in SP2's wind-up up to ~f16) **lapses**: no dash, and no J1 after the lay either (it does not wait). A J after
the move has ended is the ranged J: J1 in place.

### 18.3 The CPU, ASSIST, the learner

- **Going in** (`BR-AI-GO-IN`, pure `BR-AI-IN-CMD`): whenever his ranged CPU went in with J (TENSHIN in from neutral: the
  :busy punish, :close, :line on a crossing or a point set, the long dash 8–13 m on a crossing, :starved), it now presses
  **J1 in place within J1's reach + 0.2 m (1.8 m)**, else **an L pressed for its cancel** (`BRAI-DASH-T`; `BR-AI-CANCEL-P`
  takes it in the L's window: 7 f + the 2 f wind-up instead of 16; the new point is behind him, so its line runs through
  the opponent at the dash's end and J1 spends it), else (short of the L's 3 flash step) nothing: the neutral walk goes in.
  The cancel of a lay laid for the stay's goal is unchanged (`BR-AI-IN-P` at the window). The same chances and rolls: the
  :fire keys and their one roll per event (a point set, a crossing, his action's react roll), × `*br-ai-diff*`.
- **HARD layer** (ranged `:hard`): the punish / guard crush goes in the same way (`BR-AI-GO-IN`).
- **The learner's :trace guard read** (ranged): `BR-AI-GO-IN` with a line on him at the dash's end (was: J, TENSHIN in).
- **ASSIST AUTO COMBO ranged** (`BR-AS-RANGED`): his J pressed while free beyond J1's reach + 0.2 m → an aim point (L) with
  10 flash step left after it; his next J in its window cancels into TENSHIN in (2 f) → J1 (L point → J dash → J1 …); else
  his J is J1 in place. (Was: J straight into TENSHIN in with a line on him, the L only from 4 m.) `as-fire` is gone.
- MUJITTAI's exit J, the melee forms, the opponents' Step off his lines: unchanged (the exit's J is now J1 in place).
- New pacing keys: `ai-in-j1`, `ai-lay-dash`. Debug: the `duel probe barro` line ends `| d` (P1–P2 distance); 82013 / 82016
  now test L then J (the dash) and J alone (J1 in place).

### 18.4 Host tests

duel-rules-test (8109 → 8516 checks, ALL PASS: the four ranged forms' J is a hit move again, so the generic J-string and
Breaker-vs-J1 checks cover them as they did before V6): the ranged :q is melee's J1 / the claws' J1 with `BR-MELEE-IN` at f0,
no TENSHIN tick / go, J1's materialise at S (JILLIEL, the owl, both MUJITTAIs); no command of any form starts TENSHIN; the
cancel copies' numbers (f14 → the dash at f16); every ranged L / SP1 / SP2 (JILLIEL's and the owl's): no dash a frame before
the window, the dash at its first and last frames, none after (the move over: J1 in place), every point set by the window,
the last within the buffer, SP1's first point outside it; `BR-AI-IN-CMD` (J1 in reach, L beyond, nothing short).
duel-control 89, learn 131, input 33, touch 64, cine 18 pass.

### 18.5 Checks (2026-10-10)

- `tools/pkgcheck.sh duel` 0 / 0 / 0. `./build.sh duel` 0 warnings. Smoke `run.mjs --secs 8`: exit 0.
- **Browser script** (`--fixed-dt`, 17 s, exit 0, no error; the probe's `d` and fs): 82013 L + J 0.1 s later: TENSHIN in, d
  6.00 → 0.83, fs 100 → 98, P2 1300 → 1246 (J1 24 + the line 30); 82013 J alone: d 6.00, JILLIEL KIN, one line spent and hit
  (P2 −30); 82013 L, J 0.5 s later (after L's 13 f): d 6.00, fs 97, J1 in place; 82016 (owl) L + J: d 0.83, P2 −65; 82013
  SP1 + J on ~f20: d 0.83 (the dash), 5 live; SP2 + J on ~f24 (buffered into its window at f26): dashed, the thick line hit (P2 −114, knocked back to
  2.70); 82016 J alone: d 6.00, SHIN KIN.
- **Gates: run by the lead after the playtest** (the user, 2026-10-10: the playtest goes up before the gates, automated and
  human testing in parallel; Lille II's gates no longer include the old Lille: no BL pairing for him).

### 18.6 For the user

- In play: **L (or SP1 / SP2) then J quickly** is the dash; J anywhere else is J1 on the spot (from range it whiffs, but its
  first active frame still fires the nearest line within 2.5 m of him: a ranged J now spends a line in 8 f without moving).
- The CPU's way in is now an L and its cancel (about 9 f before the dash instead of 16).

### 18.x Gates (the lead, 2026-10-10, after the playtest went up: decision V6b)

Run on `barro-v6a` 18affe9 (the merged head 4c9051d adds docs only): the old 21 pairings' 1120 lines byte-identical to
ca447c1, `--cvc` 3 / 3; his six pairings (BL dropped, V6b), 20 seeds, every match K.O.:

| Pairing | Median s (before, §16) | His wins / 20 (before) |
|---|---|---|
| BY | 114.6 (104.7) | 16 (17) |
| BK | 111.9 (108.4) | 19 (15) |
| BR | 148.8 (139.7) | 16 (14) |
| BI | 130.1 (133.9) | 10 (12) |
| BS | 130.1 (133.2) | 17 (16) |
| BB | 124.9 (117.7) | mirror |

Awaken A/B (the never-awaken side of 60, streams 100 / 300 / 500, pass >= 20): BK 18 / 17 / 11 (unchanged), BB 7 / 8 / 9
(6 / 12 / 6). aieval `--char 6` (20 seeds): 0.373 (0.377), HARD strength 0.142 (0.150), signature 0.438. TENSHIN in 6.4 a
match (6.6), all from the lay cancel. Playtest Artifact version 41.

