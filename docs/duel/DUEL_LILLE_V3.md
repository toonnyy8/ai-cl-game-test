# SOUL DUEL: Lille Barro II, awakening v3: the stance grammar (proposal)

Status: **proposal, revision 2 (2026-10-10, after the user's R1 below), waiting on the user. Nothing is built.** The current kit is `DUEL_LILLE_V2.md` (decisions
V1–V9l); this file holds the animation inventory the user asked for and the v3 design drawn from the base form's stance.

The request (the user, 2026-10-10), verbatim:

> 請幫我彙整 lille 所有的動畫模組，並依據覺醒前的架式概念構思全新的版本三設計。

Reading [G]: "版本三" is the third design of Lille II's awakening (the user, earlier the same day: 「我想第三次重新設計覺醒狀態」,
paused with 「主要是軌跡的手感不好，想用新玩法替代」; kept: the owl's revival, U MUJITTAI, the melee / ranged forms, the K → L
five-tier recall; wanted: 指向, materialising one by one and all at once, the J / K feel split with a fast pendulum that
spends flash step and returns Reiatsu and big Reiatsu spends for output or flash step). The base form stays as built. If a
separate fighter (a "Lille III", roster index 7) is meant instead, the design below still applies; only the build plan (§6)
changes.

## 0. User decisions on the proposal

### R1 (2026-10-10): three stances, the burst owl, one spend-all, plain guard, SP by wings, the 4-wing armour

The user, on revision 1 (verbatim):

> - 我想把架式改有不同的效果，包含高攻擊、高額普通資源恢復、高額特殊資源恢復
> - 取消掉再覺醒，改成爆氣時會進入梟頭模式與獲得對應的 buff（因此取得資源並進入爆氣變成主要的輸出循環）
> - 盡量避免不同手段的效果同質化 e.g. 不要有多種將資源耗盡來打出高額傷害的路線
> - U 變成普通防禦
> - 依據特殊資源數量不同，SP1 與 SP2 會有相對應的變化
> - 攻擊時如果被攻擊可以消耗四片翼使自己不會被打斷（不足時不觸發效果）

What it changes in revision 1: the one stance becomes **three** (§3.2); the owl's revival (Konpaku ≤ 4) is gone and the
owl becomes **the awakened burst** (§3.4); only **one** route spends every wing for damage (§3.3); U is a **plain guard**
in every form (MUJITTAI gone); SP1 / SP2 **read the wing count** (§3.5); a hit during his own attack can spend **4 wings**
to keep it going (§3.6). Read as accepted by building on it: the wing magazine replaces the ground traces (rev. 1's Q1).
Superseded: rev. 1's Q2 (the stance's K: no longer a spend-all) and Q3 (the tiers matter only for the one volley).

## 1. The animation inventory

Lille's art lives in two files and is shared by both kits (`DUEL_LILLE_V2` §2: the art is shared, not copied):
`lille-art.lisp` holds **73** clips (`defclip` / `defstrike`) plus their poses, `barro-art.lisp` **17** (Lille II's
recall, its strings, the mode turns, the owl's twins). Walking, running, Step, Hoho, guard and the hit reactions use the
game's generic clips on his bodies, not clips of his own. Frames are startup / active / recovery as the clip is timed
(`defstrike`), or a loop's length. "v3" is the proposed use (§3–§6).

**Base form (the man and Diagramm)** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-stance` | loop 2.6 s | idle: upright, Diagramm levelled at the hip | idle | idle | idle |
| `:lb-aim` | loop 0.6 s | the shouldered aim, held | old L aim | Kikon's wind-up | as II |
| `:lb-fire` | 4 / 2 / 26 | the shoulder shot: recoil, the plank drops | old L shot | Kikon's shot | as II |
| `:lb-snap` | 6 / 2 / 20 | the snap shot from the hip | unused | stance J snap (also in a Step) | as II |
| `:lb-q1` | 8 / 3 / 12 | J1 SHOBI-UCHI: the rifle reversed, the plank swung up | J1 | J1 | J1 |
| `:lb-q2` | 7 / 3 / 13 | J2 KAESHI: the plank's backhand | J2 | J2 | J2 |
| `:lb-jab` | 9 / 3 / 18 | J3 JUKO-TSUKI: the muzzle cross jabbed up | J3 | J3 | J3 |
| `:lb-f1` | 17 / 4 / 21 | K1 JUSHIN-NAGI: the barrel swept flat | K1 | K1 | K1 |
| `:lb-f2` | 20 / 4 / 24 | K2 FURIOROSHI: raised overhead, brought down | K2 | K2 | K2 |
| `:lb-f3` | 21 / 5 / 34 | K3 REI-KYORI: the muzzle pressed in, fired | K3 | K3 | K3 |
| `:lb-sanren` | 12 / 22 / 24 | SP1 SANREN: three shoulder shots, turning | SP1 | SP1, stance SP1 | as II |
| `:lb-hiren` | 20 / 2 / 22 | SP2 HIRENKYAKU: the low back-slide, then a shot | SP2 | SP2, stance SP2 | as II |
| `:lb-kamae` | loop 0.8 s | the 狙撃構え: low, levelled, aimed | stance | the stance | the stance (the grammar's model) |
| `:lb-k-shot` | 10 / 2 / 26 | stance L: 10 f on the line, the crack, the recoil | stance L | stance L | as II |
| `:lb-k-hosha` | 6 / 10 / 16 | HOSHA: the leap, three bullets in the air | stance J | unused (V9b) | spare |
| `:lb-k-taisha` | 16 / 2 / 24 | TAISHA: the 3 m back-slide, the shoulder shot | stance K | stance K (1 / 2 / 3 pips) | as II |
| `:lb-k-dash` | 12 / 0 / 0 | HIRENKYAKU: the stance Step, crouched | stance Step | stance Step | as II |
| `:lb-breaker + :lb-butt` | loop 0.4 s; 8 / 4 / 18 | Breaker: the dash, the plank slammed down | Breaker | Breaker | same |
| `:lb-intro / :lb-win` | 2.0 s | intro (the rifle levelled) / win (the rifle upright) | yes | yes | same |

**Jilliel melee (KIN, the wing blades)** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-w-stance` | loop 3.0 s | idle: afloat, the eight wings fanned | idle | idle | idle (lit wings = the magazine) |
| `:lb-w-q1` | 8 / 3 / 12 | J1 左斬: the right wing cut right to left | KIN J1 | KIN J1 | KIN J1 + fires 1 wing |
| `:lb-w-q2` | 7 / 3 / 13 | J2 右斬: the mirror | KIN J2 | KIN J2 | KIN J2 + fires 1 wing |
| `:lb-w-q3` | 9 / 3 / 18 | J3 十字: both wings crossed down | KIN J3 | KIN J3, the empty recall | KIN J3 + fires 1 wing |
| `:lb-w-f1` | 17 / 4 / 21 | K1 旋: a full turn, the right wing sweeping | KIN K1 | KIN K1 | KIN K1 |
| `:lb-w-f2` | 20 / 4 / 24 | K2 逆旋: the counter-spin | KIN K2 | KIN K2 | KIN K2 |
| `:lb-w-f3` | 21 / 5 / 34 | K3 昇翼: a rising cleave, the landing | KIN K3 | KIN K3 | KIN K3 |
| `:lb-w-fold` | loop 2.0 s | MUJITTAI: the wings curled round the column | MUJITTAI | MUJITTAI, the L turn | spare (MUJITTAI dropped) |

**Jilliel ranged (EN, the casts)** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-e-q1` | 4 / 3 / 6 | EN J1: the right wing thrown down along the line | EN J1 lay | ranged L, 1st | the stances' L, shot 1 |
| `:lb-e-q2` | 4 / 3 / 6 | EN J2: the mirror | EN J2 | ranged L, 2nd | the stances' L, shot 2 |
| `:lb-e-q3` | 5 / 3 / 9 | EN J3: both wings crossed onto the line | EN J3 | unused | stance Step shot (candidate) |
| `:lb-e-f1` | 9 / 4 / 10 | EN K1: a whirl, the right wing fanned low | EN K1 | ranged L, 3rd | the stances' L, shot 3 |
| `:lb-e-f2` | 10 / 4 / 12 | EN K2: the counter-whirl | EN K2 | ranged L, 4th | the stances' L, shot 4 |
| `:lb-e-f3` | 11 / 5 / 17 | EN K3: risen, both wings slammed down | EN K3 | ranged L, 5th | the stances' L, shot 5 |
| `:lb-e-sanren` | 6 / 14 / 12 | EN SP1: three lines | EN SP1 | ranged SP1 (3 points) | stance SP1 (FS back by the wings) |

**Jilliel's specials and Kikon** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-w-sanren` | 12 / 22 / 24 | KIN SP1: three wing shots | KIN SP1 | KIN SP1 | KIN SP1 (FS back by the wings) |
| `:lb-w-nijushi` | 40 / 6 / 30 | NIJUSHI-KO: the ring charged, the beam | SP2 | SP2 (melee beam / ranged thick line) | SP2 (fixed damage; wings cut the charge) |
| `:lb-w-kikon + -fire` | 8 / 0 / 0; 20 / 3 / 30 | Kikon: the wind-up, the fire | Kikon | Kikon | Kikon |
| `:lb-w-judge-open / -shot / -close / -volley` | 24 / 0 / 64; 2 / 0 / 14; 6 / 0 / 40; loop | the old Kikon cinematic's judgement beats | cinematic | unused | spare (for the full volley's look) |
| `:lb-w-breaker + :lb-w-ram` | loop 0.4 s; 8 / 4 / 18 | Breaker: the ram | Breaker | Breaker | same |

**Turns, dashes, the recall (incl. Lille II's own)** (`lille-art / barro-art`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-w-tenshin` | 14 / 0 / 8 | TENSHIN out: fold, the flash step, open | TENSHIN out | J3 → L backstep | J string → L: backstep into the wing stance |
| `:lb-w-tenshin-in` | 30 / 0 / 8 (cancel at f14) | TENSHIN in: the wind-up, the dash | TENSHIN in | ranged J dash | stance J: fire 1 wing + dash |
| `:br-to-en` | 12 / 0 / 0 | melee to ranged: folded, risen, thrown open | — | L to ranged | neutral L into the supply stance |
| `:br-recall` | 8 / 0 / 0 | 回収: flung open, the light flies in | — | K3 → L recall | see Q4 (spare if the volley is the owl's only) |
| `:br-rc0` | 6 / 2 / 24 | 空收: one line, both wings | — | 0 traces | see Q4 |
| `:br-rc1` | 6 / 12 / 24 | 二連: right f6, left f16 | — | 1–2 | see Q4 |
| `:br-rc2` | 6 / 28 / 24 | 四連: three beats and the launch | — | 3–5 | see Q4 |
| `:br-rc3` | 6 / 32 / 26 | 裁き: four beats, the ring, the beam | — | 6–9 | see Q4 |
| `:br-rc4` | 6 / 44 / 30 | 裁き・極: six beats, the ring, the big beam | — | 10+ | see Q4 |
| `:br-e-swing / :br-oe-swing` | 7 / 3 / 6; 7 / 3 / 5 | V8's ranged L swing | — | withdrawn (V8b) | spare |

**The owl (v3: the burst mode)** (`lille-art / barro-art`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-o-stance` | loop 2.4 s | KIN: pitched on the ㄇ legs, wings back | idle | idle | burst owl idle |
| `:lb-o-q1 / q2 / q3` | 8/3/12; 7/3/13; 9/3/18 | 右爪撕 / 左爪撕 / 雙爪剪 | J1–J3 | J1–J3 | burst owl J1–J3, 1 wing each |
| `:lb-o-f1 / f2 / f3` | 17/4/21; 20/4/24; 21/5/34 | 掠爪 / 回爪 / 俯衝 | K1–K3 | K1–K3 | burst owl K1–K3 |
| `:lb-o-chop` | 16 / 0 / 24 | SABAKI NO KOMYO: the chop | SP1 | MISUJI SP1 | burst owl SP1 |
| `:lb-o-trompete` | 60 / 30 / 40 | TROMPETE: the fist at the beak | SP2 | SP2 (reflectable) | burst owl SP2 |
| `:lb-oe-stance` | loop 2.6 s | EN: upright, afloat, wings wide | idle | idle | the burst owl's stance |
| `:lb-oe-q1 / q2` | 4 / 3 / 5 | EN claw casts | EN J1–J2 | ranged L 1–2 | owl stance L 1–2 |
| `:lb-oe-q3` | 5 / 3 / 8 | EN J3: both claws and a peck | EN J3 | unused | Step shot (candidate) |
| `:lb-oe-f1 / f2 / f3` | 9/4/9; 10/4/11; 11/5/16 | EN rakes and the slam | EN K1–K3 | ranged L 3–5 | owl stance L 3–5 |
| `:lb-oe-sabaki` | 6 / 14 / 11 | EN SP1: three chops, a line each | EN SP1 | ranged SP1 | owl stance SP1 |
| `:lb-o-fold / :lb-oe-fold` | loop 2.0 s | MUJITTAI, each mode's silhouette | MUJITTAI | MUJITTAI | spare (MUJITTAI dropped) |
| `:lb-o-tenshin / -in` | 14 / 0 / 8; 30 / 0 / 8 | the owl's TENSHIN out / in | TENSHIN | in: ranged J; out: unused | the owl's dashes |
| `:br-o-to-en / :br-o-backstep` | 12 / 0 / 0; 14 / 0 / 8 | KIN to EN / the backstep (ranged at f0) | — | L turn / J3 → L | as II (in the burst) |
| `:br-o-recall, :br-o-rc0 … rc4` | as Jilliel's | the recall strings on the claws | — | the recall | the burst's full volley (the one spend-all) |
| `:lb-o-breaker + :lb-o-stamp` | loop 0.4 s; 8 / 4 / 18 | Breaker: the stamp | Breaker | Breaker | burst owl Breaker |

**Cinematics** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-rise` | 1.0 s | the revival: the headless column rises | cinematic | cinematic | spare (the revival dropped) |
| `:lb-o-reveal` | 2.0 s | the owl revealed | cinematic | cinematic | burst transformation (candidate) |

**Spare clips** (in no move of v3): `:lb-k-hosha` (dropped by V9b), `:lb-e-q3` / `:lb-oe-q3` (the old EN J3 casts),
`:lb-w-judge-*` (the old Kikon cinematic's beats), `:br-e-swing` / `:br-oe-swing` (V8's swing), and after R1 the
MUJITTAI folds `:lb-w-fold`, `:lb-o-fold`, `:lb-oe-fold` and the revival's `:lb-rise`.

## 2. What the base stance already is

Lille II's base form (`DUEL_LILLE_V2` §4, decisions V1, V6, V9–V9e, V9i, V9l) is a complete little grammar:

| # | Rule | Built as |
|---|---|---|
| B1 | A string ends in L to open the stance | J / K link → L opens `:br-kamae` at f4 (V9c), only with ≥ 1 pip (V9e) |
| B2 | The stance's L / SP1 / SP2 are shots with 萬物貫通 that **load** on a hit | +1 狙擊 pip (within 3 m +2, V8), cap 3 |
| B3 | The stance's J **spends one**: fast, small, links back to J1 | the snap shot 40, 1 pip (V9b, V9c) |
| B4 | The stance's K **spends all**, tiered by the count: slow, big | 退射 70 / 穿甲弾 110 / 破陣弾 150 (V9) |
| B5 | The Step keeps the stance and shoots on the move | HIRENKYAKU; J in any Step = the moving snap (V9i, V9l) |
| B6 | Empty, J / K are the plain J1 / K1; an empty string never reopens the stance | V9d, V9e |

B3 and B4 are the user's two materialisations already: one at a time, and all at once.

## 3. v3, revision 2

### 3.1 Resources

| Resource | What | Reading [G, Q1] |
|---|---|---|
| 普通資源 (the shared ones) | Reiatsu (3 bars, SP1 / SP2) and flash step (100; a burst needs 70 and drains it) | every fighter has them |
| 特殊資源 (his own) | **翼 the wings**, cap 8, a lit wing blade each (the owl: its gold wings) | rev. 1's magazine |
| The base form's 狙擊 pips | 3, as built | carried in as wings at the awakening (rev. 1's Q4 default) |

Every wing sink does one different job (R1: 「避免同質化」):

| Sink | Wings | Job |
|---|---|---|
| A KIN J, the stance's J (TENSHIN in), a J in the stance's Step | 1 | small damage (25 flat) + Reiatsu back (+10): the pendulum |
| Hit during his own attack (§3.6) | 4 | not interrupted: defence |
| **The full volley** (§3.3) | all | **the only big-damage spend** |
| SP1 / SP2 (§3.5) | none: they read the count | SP1 more flash step back, SP2 a shorter charge |

### 3.2 Three stances (awakened; the base keeps its one sniping stance)

The awakened ranged form is the stance (rev. 1); it now comes in three kinds, picked by how he enters it [G, Q2]. All
three share the grammar: L x5 shoots (`:lb-e-q1, q2, f1, f2, f3`, V9k's chain), J = TENSHIN in (fires 1 wing, then KIN
J1), K = back to KIN K1, Step keeps the stance (a J fires 1 wing on the move), SP1 / SP2 by the wings (§3.5).

| Stance | Entered by | The L shot [G] | Its effect |
|---|---|---|---|
| 攻 断罪の構え (high attack) | a KIN K string → L | **35**, 萬物貫通, 6 FS | damage only: no wing, no resource back |
| 補 糧の構え (shared resources) | L from neutral (`:br-to-en`) | 10, 萬物貫通, **free** | a hit **+12 flash step, +15 Reiatsu** (a block half) |
| 翼 装翼の構え (wings) | a KIN J string → L (J3: the backstep, `:lb-w-tenshin`) | 10, 萬物貫通, 6 FS | a hit or block **+2 wings** |

The look tells them apart (cosmetic): the wings' spread and the halo's tint per stance [G].

### 3.3 The burst owl and the one full volley

- **A burst in an awakened form** (any of WHITE / BLUE / ORANGE, the shared rules: 70 flash step, drained 18 / s) turns him
  into **the owl** until it ends, then back to the form he burst from. No cinematic: the body changes on the burst's frame
  (`:lb-o-reveal` is a candidate for a short flourish). The base form's burst stays a plain burst [G].
- **Buffs by the burst's colour** [G, Q3]: WHITE (neutral) → +1 wing every 0.5 s; ORANGE (on his hit) → damage x1.2;
  BLUE (the combo breaker) → the 4-wing armour costs 0 for the burst. Plus the owl's V9j numbers (a fired wing 30, +15
  Reiatsu; SP2 Trompete 120 and its reflect / seal) and his stance shots free of flash step (V9j's burst rule).
- **The full volley** (K3 → L, `:br-o-recall` → `:br-o-rc0..rc4`, every wing, tiers 0 / 1–2 / 3–4 / 5–7 / 8 =
  30 / 70 / 160 / 300 / 480 [G]; SP2 after it uncharged, V9l): **only in the owl** [Q4]. Outside the burst K3 → L
  opens the 攻 stance. So the loop is: gather wings and flash step in the stances → burst → the owl's volley.

### 3.4 What is gone

The owl's revival at ≤ 4 Konpaku (`br-revive-cine`), MUJITTAI on U (every form guards), the ground traces and their
rules (aim points, the 2.5 m pick, the 1.5 m circle, the Hoho points, the crossing slow motion: the slow motion moves to
the first stance-shot hit of each stance and the volley's last beam, rev. 1).

### 3.5 SP1 / SP2 by the wing count (the count is read, not spent)

| Wings | SP1 (1 bar; KIN `:lb-w-sanren`, stance `:lb-e-sanren`) | SP2 (2 bars; NIJUSHI-KO, fixed **90**; the owl's Trompete 120) |
|---|---|---|
| 0–3 | 3 shots, **+18** flash step | the 40 f charge (as built) |
| 4–7 | 3 shots, **+35** (one bar) | a 20 f charge |
| 8 | 5 shots, **+70** (a burst's worth) | no charge, a guard break on block |

SP1 is the flash-step side of the loop (V9j: 「約 2 格 SP 換 1 格閃步」, more with wings); SP2 never deals more with
wings, it only lands more easily (R1: no second 「耗盡打高傷」).

### 3.6 The 4-wing armour

During his own attack (`:move`, startup to recovery), a hit that would stagger him spends **4 wings** instead: he takes
the damage and the move goes on [G: full damage, once a hit]. Fewer than 4: the hit lands as usual (「不足時不觸發」).
Automatic, no input [G]. Breaker, Kikon and throws ignore it [G]. The BLUE burst owl's armour is free.

### 3.7 Inputs by form

| Input | Base | Awakened KIN | The stance (three kinds) | The burst owl |
|---|---|---|---|---|
| J | J string | each J fires 1 wing | TENSHIN in (1 wing) → J1 | claws, 1 wing each J |
| K | K string | K string | back to K1 | claws |
| L | the sniping stance | neutral: 補; J string → L: 翼; K string → L: 攻 | the stance's shot x5 | stances as Jilliel; K3 → L: **the full volley** |
| SP1 / SP2 | as built | by the wings (§3.5) | by the wings | MISUJI / Trompete by the wings |
| U | guard | guard | guard | guard |
| Burst | plain | → the owl | → the owl | — |

## 4. Animation plan

Reused: the inventory's v3 column. New, all cosmetic:
1. The lit wings (a loaded wing brightens, dims as it fires); the owl's gold the same.
2. The fired wing's line from that wing's tip (the recall strings already draw tip lines: `BR-DRAW`).
3. The three stances' looks: the wings' spread and the halo tint on the EN idle (no new clip, or three short idles).
4. The armour's flash (a wing set shattering, 4 dimmed at once).
5. The stance Step shot: the spare `:lb-e-q3` / `:lb-oe-q3`, or a new 6 f clip.
6. Optional: the burst's owl flourish from `:lb-o-reveal`; the judge beats for the 8-wing volley.

## 5. Open questions (for the user)

| # | Question | Options (recommended first) |
|---|---|---|
| Q1 | 普通資源 / 特殊資源 | shared = Reiatsu + flash step, special = the wings / shared = flash step only / shared = Reiatsu only |
| Q2 | How a stance is picked | by the entry (neutral L 補, J string → L 翼, K string → L 攻) / K in the stance cycles them / both |
| Q3 | The owl's buffs | by the burst's colour (WHITE wings, ORANGE damage, BLUE free armour) / one set for every colour |
| Q4 | The full volley | the owl's only (outside, K3 → L opens 攻) / always on K3 → L, the owl only buffs it |

Noted, not asked: the base stance's K (spend every pip for 70 / 110 / 150) is also a spend-all; R1 may want it changed.

## 6. Build plan (after 「開始實作」)

1. Sim (`barro.lisp` only): the wings and their sinks, the three stances, the burst owl and its buffs, SP1 / SP2 tiers,
   the armour; the traces, MUJITTAI and the revival removed. The armour needs a hook in the shared hit path (a kit hook,
   inert for everyone else).
2. Art: §4. 3. CPU / ASSIST / learning. 4. Docs, manual, playtest; then his gates (6 pairings, the mirror, the A/B).
