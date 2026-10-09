# SOUL DUEL: Lille Barro II (利傑巴羅・重製), the rebuilt kit

Status: **design written 2026-10-09; build not started.** The old Lille (`DUEL_LILLE.md`, roster index 5) stays as he
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
  slow motion, Hoho → KIN, the stance's charge bonus and its HIRENKYAKU step, HOSHA, the Trompete reflect / seal,
  SABAKI's erupting ground lines. Kept: the owl's revival (decision V1) and MUJITTAI on U in every awakened form (decision V2).

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
| SP1 / SP2 | as ranged SP1 / SP2 | go to ranged and lay (§5.2) [G]: the awakening's damage comes from traces and the recall |
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

- **Near** = the trace's line passes within **2.5 m** of the opponent's centre (point-to-segment, ground plane) [G].
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
`:shin` (EN casts `:lb-oe-q1..`, SP1 `:lb-oe-sabaki` lays 3 lines, SP2 `:lb-oe-trompete` lays the thick line, no reflect,
no seal), U MUJITTAI in both (decision V2). ×1.1 dealt, ×1.1 taken, +1 f on every move, refunds 5 / 2, Kikon 4 (the old owl's numbers). The recall's
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
