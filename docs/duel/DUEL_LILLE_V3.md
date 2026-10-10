# SOUL DUEL: Lille Barro II, awakening v3: the stance grammar (proposal)

Status: **proposal, 2026-10-10, waiting on the user. Nothing is built.** The current kit is `DUEL_LILLE_V2.md` (decisions
V1–V9l); this file holds the animation inventory the user asked for and the v3 design drawn from the base form's stance.

The request (the user, 2026-10-10), verbatim:

> 請幫我彙整 lille 所有的動畫模組，並依據覺醒前的架式概念構思全新的版本三設計。

Reading [G]: "版本三" is the third design of Lille II's awakening (the user, earlier the same day: 「我想第三次重新設計覺醒狀態」,
paused with 「主要是軌跡的手感不好，想用新玩法替代」; kept: the owl's revival, U MUJITTAI, the melee / ranged forms, the K → L
five-tier recall; wanted: 指向, materialising one by one and all at once, the J / K feel split with a fast pendulum that
spends flash step and returns Reiatsu and big Reiatsu spends for output or flash step). The base form stays as built. If a
separate fighter (a "Lille III", roster index 7) is meant instead, the design below still applies; only the build plan (§7)
changes.

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
| `:lb-w-fold` | loop 2.0 s | MUJITTAI: the wings curled round the column | MUJITTAI | MUJITTAI, the L turn | MUJITTAI |

**Jilliel ranged (EN, the casts)** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-e-q1` | 4 / 3 / 6 | EN J1: the right wing thrown down along the line | EN J1 lay | ranged L, 1st | stance L, shot 1 |
| `:lb-e-q2` | 4 / 3 / 6 | EN J2: the mirror | EN J2 | ranged L, 2nd | stance L, shot 2 |
| `:lb-e-q3` | 5 / 3 / 9 | EN J3: both wings crossed onto the line | EN J3 | unused | stance Step shot (candidate) |
| `:lb-e-f1` | 9 / 4 / 10 | EN K1: a whirl, the right wing fanned low | EN K1 | ranged L, 3rd | stance L, shot 3 |
| `:lb-e-f2` | 10 / 4 / 12 | EN K2: the counter-whirl | EN K2 | ranged L, 4th | stance L, shot 4 |
| `:lb-e-f3` | 11 / 5 / 17 | EN K3: risen, both wings slammed down | EN K3 | ranged L, 5th | stance L, shot 5 |
| `:lb-e-sanren` | 6 / 14 / 12 | EN SP1: three lines | EN SP1 | ranged SP1 (3 points) | stance SP1 (3 FS-free loads) |

**Jilliel's specials and Kikon** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-w-sanren` | 12 / 22 / 24 | KIN SP1: three wing shots | KIN SP1 | KIN SP1 | KIN SP1 |
| `:lb-w-nijushi` | 40 / 6 / 30 | NIJUSHI-KO: the ring charged, the beam | SP2 | SP2 (melee beam / ranged thick line) | SP2 (damage only) |
| `:lb-w-kikon + -fire` | 8 / 0 / 0; 20 / 3 / 30 | Kikon: the wind-up, the fire | Kikon | Kikon | Kikon |
| `:lb-w-judge-open / -shot / -close / -volley` | 24 / 0 / 64; 2 / 0 / 14; 6 / 0 / 40; loop | the old Kikon cinematic's judgement beats | cinematic | unused | spare (for the full volley's look) |
| `:lb-w-breaker + :lb-w-ram` | loop 0.4 s; 8 / 4 / 18 | Breaker: the ram | Breaker | Breaker | same |

**Turns, dashes, the recall (incl. Lille II's own)** (`lille-art / barro-art`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-w-tenshin` | 14 / 0 / 8 | TENSHIN out: fold, the flash step, open | TENSHIN out | J3 → L backstep | J → L backstep into the stance |
| `:lb-w-tenshin-in` | 30 / 0 / 8 (cancel at f14) | TENSHIN in: the wind-up, the dash | TENSHIN in | ranged J dash | stance J: fire 1 wing + dash |
| `:br-to-en` | 12 / 0 / 0 | melee to ranged: folded, risen, thrown open | — | L to ranged | L into the stance |
| `:br-recall` | 8 / 0 / 0 | 回収: flung open, the light flies in | — | K3 → L recall | the full volley's start |
| `:br-rc0` | 6 / 2 / 24 | 空收: one line, both wings | — | 0 traces | 0 wings |
| `:br-rc1` | 6 / 12 / 24 | 二連: right f6, left f16 | — | 1–2 | 1–2 |
| `:br-rc2` | 6 / 28 / 24 | 四連: three beats and the launch | — | 3–5 | 3–4 |
| `:br-rc3` | 6 / 32 / 26 | 裁き: four beats, the ring, the beam | — | 6–9 | 5–7 |
| `:br-rc4` | 6 / 44 / 30 | 裁き・極: six beats, the ring, the big beam | — | 10+ | 8 (full) |
| `:br-e-swing / :br-oe-swing` | 7 / 3 / 6; 7 / 3 / 5 | V8's ranged L swing | — | withdrawn (V8b) | spare |

**The owl** (`lille-art / barro-art`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-o-stance` | loop 2.4 s | KIN: pitched on the ㄇ legs, wings back | idle | idle | idle |
| `:lb-o-q1 / q2 / q3` | 8/3/12; 7/3/13; 9/3/18 | 右爪撕 / 左爪撕 / 雙爪剪 | J1–J3 | J1–J3 | J1–J3, 1 wing each |
| `:lb-o-f1 / f2 / f3` | 17/4/21; 20/4/24; 21/5/34 | 掠爪 / 回爪 / 俯衝 | K1–K3 | K1–K3 | K1–K3 |
| `:lb-o-chop` | 16 / 0 / 24 | SABAKI NO KOMYO: the chop | SP1 | MISUJI SP1 | same |
| `:lb-o-trompete` | 60 / 30 / 40 | TROMPETE: the fist at the beak | SP2 | SP2 (reflectable) | same |
| `:lb-oe-stance` | loop 2.6 s | EN: upright, afloat, wings wide | idle | idle | the owl's stance |
| `:lb-oe-q1 / q2` | 4 / 3 / 5 | EN claw casts | EN J1–J2 | ranged L 1–2 | stance L 1–2 |
| `:lb-oe-q3` | 5 / 3 / 8 | EN J3: both claws and a peck | EN J3 | unused | Step shot (candidate) |
| `:lb-oe-f1 / f2 / f3` | 9/4/9; 10/4/11; 11/5/16 | EN rakes and the slam | EN K1–K3 | ranged L 3–5 | stance L 3–5 |
| `:lb-oe-sabaki` | 6 / 14 / 11 | EN SP1: three chops, a line each | EN SP1 | ranged SP1 | stance SP1 |
| `:lb-o-fold / :lb-oe-fold` | loop 2.0 s | MUJITTAI, each mode's silhouette | MUJITTAI | MUJITTAI | same |
| `:lb-o-tenshin / -in` | 14 / 0 / 8; 30 / 0 / 8 | the owl's TENSHIN out / in | TENSHIN | in: ranged J; out: unused | as II |
| `:br-o-to-en / :br-o-backstep` | 12 / 0 / 0; 14 / 0 / 8 | KIN to EN / the backstep (ranged at f0) | — | L turn / J3 → L | as II |
| `:br-o-recall, :br-o-rc0 … rc4` | as Jilliel's | the recall strings on the claws | — | the recall | the owl's full volley |
| `:lb-o-breaker + :lb-o-stamp` | loop 0.4 s; 8 / 4 / 18 | Breaker: the stamp | Breaker | Breaker | same |

**Cinematics** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-rise` | 1.0 s | the revival: the headless column rises | cinematic | cinematic | same |
| `:lb-o-reveal` | 2.0 s | the owl revealed | cinematic | cinematic | same |
**Spare clips** (in no move of Lille II): `:lb-k-hosha` (dropped by V9b), `:lb-e-q3` / `:lb-oe-q3` (the old EN J3 casts),
`:lb-w-judge-*` (the old Kikon cinematic's beats), `:lb-o-tenshin` (the owl's TENSHIN out; II uses `:br-o-backstep`),
`:br-e-swing` / `:br-oe-swing` (V8's swing, withdrawn by V8b). The old Lille alone uses `:lb-k-hosha`, `:lb-w-judge-*` and
`:lb-o-tenshin`.

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

## 3. v3: one grammar, three bodies

The awakening and the owl run B1–B6 with their own bodies. The ground traces go (「軌跡的手感不好，想用新玩法替代」); the
rounds live on his wings instead:

- **翼倉 the wing magazine.** Jilliel's eight wing blades are the rounds: a loaded round lights a wing (the owl: its eight
  gold wings). Cap **8** [G]. The HUD shows the count; both players see the lit wings.
- **指向.** A round has no place on the floor: when it fires it leaves the tip of a lit wing as a 萬物貫通 line straight at
  the opponent, wherever he is. Counterplay is the Step's iframes, a block (30 % through, 40 guard drain) or MUJITTAI.
- **One by one = the J route** (B3), **all at once = the K route** (B4, the recall kept as its input).

| | Attack state (strings) | The stance (L) | Rounds |
|---|---|---|---|
| Base | the man: J / K with Diagramm | 狙擊架式 `:lb-kamae` | 狙擊, 3 pips (as built) |
| Awakened | KIN: the wing cuts | EN afloat, the eight wings open | 翼倉, 8 wings |
| The owl | KIN: the claws | EN upright, the gold wings wide | 翼倉, 8 gold wings |

## 4. The awakened rules (Jilliel; the owl the same with its own clips and numbers)

| Input | Move | Rule |
|---|---|---|
| KIN J1 / J2 / J3 | `:lb-w-q1..q3` | **each J fires one round** from a lit wing at him on its first active frame, hit or whiff (V6's "every J"); 25 flat, 萬物貫通, +10 Reiatsu on a hit (+5 on a block). Empty: just the cut |
| KIN K1 / K2 / K3 | `:lb-w-f1..f3` | fire nothing (the K route keeps the magazine, V8) |
| KIN J link → L | J1 / J2 → L: `:br-to-en`; J3 → L: the backstep `:lb-w-tenshin` | into the stance (B1); the backstep fires one round as it leaves (V9h). Empty: the turn in place |
| KIN K3 → L | `:br-recall` → `:br-rc0..rc4` | **全彈 the full volley**: every round, the tier by the count (§5); SP2 after it uncharged (V9l). No Reiatsu from it (V9j: 「回收不算」) |
| Stance L (×5) | `:lb-e-q1`, `-q2`, `-f1`, `-f2`, `-f3` | a 萬物貫通 shot at him [G 15 damage], 6 flash step (owl 4.5; none in a burst, V9j); **a hit or block loads one wing** [G: the base loads on a hit only]; L latched during one chains the next (V9k's string) |
| Stance J | `:lb-w-tenshin-in` | TENSHIN in: fires one round at f0, then the dash into KIN J1 (V9f's order; the round is its price, V8a). Empty: J1 in place |
| Stance K | Q2 | the full volley from range, or back to KIN K1 |
| Stance SP1 | `:lb-e-sanren` | three shots, **no flash step**, each hit or block loads a wing; 1 bar |
| Stance SP2 | `:lb-w-nijushi` | the thick beam, 90 flat (owl Trompete 120), damage only; 2 bars |
| Stance Step | generic Step | keeps the stance; J during it fires one round on the move (V9l's moving snap; the iframes end on the shot) |
| KIN SP1 / SP2 | `:lb-w-sanren`, `:lb-w-nijushi` | as built (V3) |
| U | MUJITTAI | as built (V2) |
| P | the owl's revival (≤ 4 Konpaku) | as built (V1) |

## 5. Numbers and the resource loop

| Knob | v3 [G] | From |
|---|---|---|
| Wings (cap) | 8 (the owl 8) | Jilliel's eight blades |
| A fired round | 25 flat (owl 30), 萬物貫通, +10 Reiatsu (owl +15; block half) | V9j's line |
| Stance L shot | 15, 萬物貫通, 6 FS (owl 4.5), loads 1 | V9j's price, V8's swing damage |
| Full volley tiers | 0 / 1–2 / 3–4 / 5–7 / 8 = 30 / 70 / 160 / 300 / 480 | V8's five tiers, cut to 8 |
| The owl | ×1.1 dealt and taken, +1 f, Trompete reflect and seal | as built |

The loop the user set (V9j: 「2 格閃步換 1 格 SP」 ⇔ 「約 2 格 SP 換 1 格閃步」) carries over unchanged in its arithmetic:
flash step → (stance L) → wings → (the J route) → Reiatsu → (SP1) → wings without flash step.
- 70 FS (two bars) = 11.7 stance shots → up to 11.7 wings → fired by J = ~117 Reiatsu (1.2 bars).
- 2 bars of Reiatsu = two SP1 = 6 wings with no flash step (~36 FS worth).
- The K route turns the same wings into one burst instead (no Reiatsu back): the user's 高攻循環.

Defaults taken without a question [G]: the awakened Hoho leaves nothing (no traces to leave); the slow motion moves from
the traces to **the first stance-shot hit of each stance** (fresh, 0.1 × 0.2 s) and **the full volley's last beam**
(0.2 × 0.5 s); the base's 狙擊 pips stay the base's.

## 6. What changes, what stays

| Item | Lille II now | v3 |
|---|---|---|
| Ground traces, aim points, the 2.5 m pick, the 1.5 m circle, Hoho points | the core | **gone** |
| Ranged L | a damage-less point (6 FS) | a 萬物貫通 shot that loads a wing |
| Ranged form | a mode | **the stance** (B1–B6) |
| J's materialisation | the nearest line within 2.5 m | one round, always at him (指向) |
| K3 → L recall | every trace, five tiers | every wing, five tiers (same clips) |
| TENSHIN in / the backstep | price: a trace | price: a round |
| Kept | the owl's revival, MUJITTAI, both forms, the recall's five tiers, SP2 after it, the V8 J / K feel split, V9j's loop | |

## 7. Animation plan

Nearly everything is reused (the inventory's v3 column). New work, all cosmetic:
1. **The lit wings** (draw hook): a loaded round brightens one blade, it dims as it fires; the owl's gold the same.
2. **The fired round's look**: a line from that wing's tip at him (the recall strings already draw tip lines: `BR-DRAW`).
3. **The stance Step shot**: from the spare `:lb-e-q3` / `:lb-oe-q3` (a quick both-wing cast) or a new 6 f clip.
4. Optional: the spare `:lb-w-judge-*` beats as the 8-wing volley's look.

## 8. Open questions (for the user)

| # | Question | Options (recommended first) |
|---|---|---|
| Q1 | The ground traces | remove them, the wing magazine instead / keep aim points but always aimed at him / both (wings + Hoho points) |
| Q2 | The stance's K | the full volley from range (B4 as the base) / back to melee K1 (as now) |
| Q3 | Magazine and tiers | 8 wings, 0 / 1–2 / 3–4 / 5–7 / 8 / 16 as now, 0 / 1–2 / 3–5 / 6–9 / 10+ |
| Q4 | 狙擊 pips at the awakening | carried in as wings (3 pips → 3 wings) / not carried |

## 9. Build plan (after the user's 「開始實作」)

1. Sim: the magazine, the J route, the stance L / SP1 / J / Step, the full volley on wings; the traces' code removed
   (`barro.lisp`, his own files only; nothing shared).
2. Art: the lit wings, the fired round, the Step shot.
3. CPU / ASSIST / learning on the new rules.
4. Docs, manual, playtest; then his gates (6 pairings without BL, the mirror, the awaken A/B).
