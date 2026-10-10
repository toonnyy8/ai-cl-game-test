# SOUL DUEL: Lille Barro II, awakening v3: the stance grammar (proposal)

Status: **proposal, revision 3 (2026-10-10, after the user's R1 and R2 below), waiting on 「開始實作」. Nothing is built.** The current kit is `DUEL_LILLE_V2.md` (decisions
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

### R2 (2026-10-10): one stance by L, its three strings; the base too; one owl buff set

The user, on revision 2 (verbatim):

> 架勢用 L 進入（兩個相同的符號代表連擊）
> 1. 架勢 > LL：回收特殊資源
> 2. 架勢 > KK： 高攻擊，可以再銜接 JJ 消耗資源提高傷害
> 3. 架勢 > JJ： 高額閃步/SP 量表恢復，可以再銜接 KK 消耗資源提高恢復量

Then four questions (AskUserQuestion, the recommended first):

| Question | The user's pick |
|---|---|
| Where it applies (only the awakening / the base too) | **「常態也一起改」** |
| The follow-up's price (1 a hit / 4 at once / all) | **「每下花 1 翼」** |
| Back to melee (a forward Step dashes / the string's end / when the stance lapses) | **「連段打完自動回近戰」** |
| Rev. 2's Q3 / Q4 (buffs by colour and the volley the owl's only / one buff set / the volley always) | **「buff 不分顏色」** (the volley stays the owl's only) |

What it settles: rev. 2's Q1 (shared = flash step and Reiatsu, special = the wings / the base's pips: 「高額閃步/SP 量表恢復」),
Q2 (one stance, its strings pick the effect: replaces the three stances), Q3 (one buff set), Q4 (the owl's only), and the
base stance's spend-all K (replaced by its KK → JJ).

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
| `:lb-aim` | loop 0.6 s | the shouldered aim, held | old L aim | Kikon's wind-up | as II (Kikon) |
| `:lb-fire` | 4 / 2 / 26 | the shoulder shot: recoil, the plank drops | old L shot | Kikon's shot | stance L 1 (gather) |
| `:lb-snap` | 6 / 2 / 20 | the snap shot from the hip | unused | stance J snap (also in a Step) | stance J 1; L 2 |
| `:lb-q1` | 8 / 3 / 12 | J1 SHOBI-UCHI: the rifle reversed, the plank swung up | J1 | J1 | J1 |
| `:lb-q2` | 7 / 3 / 13 | J2 KAESHI: the plank's backhand | J2 | J2 | J2 |
| `:lb-jab` | 9 / 3 / 18 | J3 JUKO-TSUKI: the muzzle cross jabbed up | J3 | J3 | J3 |
| `:lb-f1` | 17 / 4 / 21 | K1 JUSHIN-NAGI: the barrel swept flat | K1 | K1 | K1 |
| `:lb-f2` | 20 / 4 / 24 | K2 FURIOROSHI: raised overhead, brought down | K2 | K2 | K2 |
| `:lb-f3` | 21 / 5 / 34 | K3 REI-KYORI: the muzzle pressed in, fired | K3 | K3 | K3 |
| `:lb-sanren` | 12 / 22 / 24 | SP1 SANREN: three shoulder shots, turning | SP1 | SP1, stance SP1 | SP1 (by the pips) |
| `:lb-hiren` | 20 / 2 / 22 | SP2 HIRENKYAKU: the low back-slide, then a shot | SP2 | SP2, stance SP2 | SP2 (by the pips) |
| `:lb-kamae` | loop 0.8 s | the 狙撃構え: low, levelled, aimed | stance | the stance | L into the stance |
| `:lb-k-shot` | 10 / 2 / 26 | stance L: 10 f on the line, the crack, the recoil | stance L | stance L | stance K 1 (heavy) |
| `:lb-k-hosha` | 6 / 10 / 16 | HOSHA: the leap, three bullets in the air | stance J | unused (V9b) | stance J 2 (revived) |
| `:lb-k-taisha` | 16 / 2 / 24 | TAISHA: the 3 m back-slide, the shoulder shot | stance K | stance K (1 / 2 / 3 pips) | stance K 2 |
| `:lb-k-dash` | 12 / 0 / 0 | HIRENKYAKU: the stance Step, crouched | stance Step | stance Step | stance Step |
| `:lb-breaker + :lb-butt` | loop 0.4 s; 8 / 4 / 18 | Breaker: the dash, the plank slammed down | Breaker | Breaker | same |
| `:lb-intro / :lb-win` | 2.0 s | intro (the rifle levelled) / win (the rifle upright) | yes | yes | same |

**Jilliel melee (KIN, the wing blades)** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-w-stance` | loop 3.0 s | idle: afloat, the eight wings fanned | idle | idle | idle (lit wings = the magazine) |
| `:lb-w-q1` | 8 / 3 / 12 | J1 左斬: the right wing cut right to left | KIN J1 | KIN J1 | KIN J1 |
| `:lb-w-q2` | 7 / 3 / 13 | J2 右斬: the mirror | KIN J2 | KIN J2 | KIN J2 |
| `:lb-w-q3` | 9 / 3 / 18 | J3 十字: both wings crossed down | KIN J3 | KIN J3, the empty recall | KIN J3 |
| `:lb-w-f1` | 17 / 4 / 21 | K1 旋: a full turn, the right wing sweeping | KIN K1 | KIN K1 | KIN K1 |
| `:lb-w-f2` | 20 / 4 / 24 | K2 逆旋: the counter-spin | KIN K2 | KIN K2 | KIN K2 |
| `:lb-w-f3` | 21 / 5 / 34 | K3 昇翼: a rising cleave, the landing | KIN K3 | KIN K3 | KIN K3 |
| `:lb-w-fold` | loop 2.0 s | MUJITTAI: the wings curled round the column | MUJITTAI | MUJITTAI, the L turn | spare (MUJITTAI dropped) |

**Jilliel ranged (EN, the casts)** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-e-q1` | 4 / 3 / 6 | EN J1: the right wing thrown down along the line | EN J1 lay | ranged L, 1st | stance J 1 |
| `:lb-e-q2` | 4 / 3 / 6 | EN J2: the mirror | EN J2 | ranged L, 2nd | stance J 2 |
| `:lb-e-q3` | 5 / 3 / 9 | EN J3: both wings crossed onto the line | EN J3 | unused | stance L 2 (revived) |
| `:lb-e-f1` | 9 / 4 / 10 | EN K1: a whirl, the right wing fanned low | EN K1 | ranged L, 3rd | stance K 1 |
| `:lb-e-f2` | 10 / 4 / 12 | EN K2: the counter-whirl | EN K2 | ranged L, 4th | stance K 2 |
| `:lb-e-f3` | 11 / 5 / 17 | EN K3: risen, both wings slammed down | EN K3 | ranged L, 5th | spare |
| `:lb-e-sanren` | 6 / 14 / 12 | EN SP1: three lines | EN SP1 | ranged SP1 (3 points) | SP1 in the stance (by the wings) |

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
| `:lb-w-tenshin` | 14 / 0 / 8 | TENSHIN out: fold, the flash step, open | TENSHIN out | J3 → L backstep | J3 → L backstep into the stance |
| `:lb-w-tenshin-in` | 30 / 0 / 8 (cancel at f14) | TENSHIN in: the wind-up, the dash | TENSHIN in | ranged J dash | spare (no dash) |
| `:br-to-en` | 12 / 0 / 0 | melee to ranged: folded, risen, thrown open | — | L to ranged | L into the stance |
| `:br-recall` | 8 / 0 / 0 | 回収: flung open, the light flies in | — | K3 → L recall | spare (the volley is the owl's) |
| `:br-rc0` | 6 / 2 / 24 | 空收: one line, both wings | — | 0 traces | spare |
| `:br-rc1` | 6 / 12 / 24 | 二連: right f6, left f16 | — | 1–2 | spare |
| `:br-rc2` | 6 / 28 / 24 | 四連: three beats and the launch | — | 3–5 | spare |
| `:br-rc3` | 6 / 32 / 26 | 裁き: four beats, the ring, the beam | — | 6–9 | spare |
| `:br-rc4` | 6 / 44 / 30 | 裁き・極: six beats, the ring, the big beam | — | 10+ | spare |
| `:br-e-swing / :br-oe-swing` | 7 / 3 / 6; 7 / 3 / 5 | V8's ranged L swing | — | withdrawn (V8b) | stance L 1 (revived) |

**The owl (v3: the burst mode)** (`lille-art / barro-art`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-o-stance` | loop 2.4 s | KIN: pitched on the ㄇ legs, wings back | idle | idle | burst owl idle |
| `:lb-o-q1 / q2 / q3` | 8/3/12; 7/3/13; 9/3/18 | 右爪撕 / 左爪撕 / 雙爪剪 | J1–J3 | J1–J3 | burst owl J1–J3 |
| `:lb-o-f1 / f2 / f3` | 17/4/21; 20/4/24; 21/5/34 | 掠爪 / 回爪 / 俯衝 | K1–K3 | K1–K3 | burst owl K1–K3 |
| `:lb-o-chop` | 16 / 0 / 24 | SABAKI NO KOMYO: the chop | SP1 | MISUJI SP1 | burst owl SP1 |
| `:lb-o-trompete` | 60 / 30 / 40 | TROMPETE: the fist at the beak | SP2 | SP2 (reflectable) | burst owl SP2 |
| `:lb-oe-stance` | loop 2.6 s | EN: upright, afloat, wings wide | idle | idle | the burst owl's stance |
| `:lb-oe-q1 / q2` | 4 / 3 / 5 | EN claw casts | EN J1–J2 | ranged L 1–2 | owl stance J 1–2 |
| `:lb-oe-q3` | 5 / 3 / 8 | EN J3: both claws and a peck | EN J3 | unused | owl stance L 2 |
| `:lb-oe-f1 / f2 / f3` | 9/4/9; 10/4/11; 11/5/16 | EN rakes and the slam | EN K1–K3 | ranged L 3–5 | owl stance K 1–2 (f3 spare) |
| `:lb-oe-sabaki` | 6 / 14 / 11 | EN SP1: three chops, a line each | EN SP1 | ranged SP1 | owl stance SP1 |
| `:lb-o-fold / :lb-oe-fold` | loop 2.0 s | MUJITTAI, each mode's silhouette | MUJITTAI | MUJITTAI | spare (MUJITTAI dropped) |
| `:lb-o-tenshin / -in` | 14 / 0 / 8; 30 / 0 / 8 | the owl's TENSHIN out / in | TENSHIN | in: ranged J; out: unused | spare (no dash) |
| `:br-o-to-en / :br-o-backstep` | 12 / 0 / 0; 14 / 0 / 8 | KIN to EN / the backstep (ranged at f0) | — | L turn / J3 → L | as II (in the burst) |
| `:br-o-recall, :br-o-rc0 … rc4` | as Jilliel's | the recall strings on the claws | — | the recall | the burst's full volley (the one spend-all) |
| `:lb-o-breaker + :lb-o-stamp` | loop 0.4 s; 8 / 4 / 18 | Breaker: the stamp | Breaker | Breaker | burst owl Breaker |

**Cinematics** (`lille-art.lisp`)

| Clip | Frames (S / A / R) | Motion | Lille | Lille II | v3 |
|---|---|---|---|---|---|
| `:lb-rise` | 1.0 s | the revival: the headless column rises | cinematic | cinematic | spare (the revival dropped) |
| `:lb-o-reveal` | 2.0 s | the owl revealed | cinematic | cinematic | burst transformation (candidate) |

**Spare clips** (in no move of revision 3): `:lb-e-f3` / `:lb-oe-f3`, `:lb-w-tenshin-in`, `:lb-o-tenshin` /
`-in` (no dash), Jilliel's `:br-recall` and `:br-rc0..rc4` (the volley is the owl's), `:lb-w-judge-*`, the MUJITTAI folds
`:lb-w-fold`, `:lb-o-fold`, `:lb-oe-fold`, the revival's `:lb-rise`. Revived from the spares: `:lb-k-hosha`, `:lb-e-q3` /
`:lb-oe-q3`, `:br-e-swing` / `:br-oe-swing`.

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

## 3. v3, revision 3

### 3.1 Resources

| Resource | Base | Awakened / the burst owl |
|---|---|---|
| Shared (普通) | flash step (100; a burst needs 70) and Reiatsu (3 bars) | the same |
| Special (特殊) | 狙擊 pips, cap 3 | 翼 the wings, cap 8 (a lit blade each; the owl's gold wings); the pips carry in as wings |

### 3.2 One grammar in every form

Attack state = the form's J / K strings (the man with Diagramm, KIN's wing cuts, the owl's claws), plain: no resource in
or out. **L enters the stance** (from neutral, after a string, J3 → L the backstep `:lb-w-tenshin`). In the stance a
button's first press picks a string; **every string ends back in the attack state** (R2). A button always plays the same
clips, so the follow-up looks like the other string's opening.

| In the stance | Hits | Effect [numbers G] |
|---|---|---|
| **L L** 回收 | 2 萬物貫通 shots, 10 each | each hit or block **+1 special** (base pip / wing); the 2nd +2 (a full string: +3) |
| **K K** 高攻 | 2 萬物貫通 shots, **45** each (the owl ×1.1) | damage only |
| → **J J** after K K | 2 shots | each **spends 1 special**: 15 → **45** each (none left: the plain 15) |
| **J J** 回復 | 2 萬物貫通 shots, 15 each | each hit **+10 flash step, +15 Reiatsu** (a block half) |
| → **K K** after J J | 2 shots | each **spends 1 special**: **+20 flash step, +30 Reiatsu** more on its hit (none left: no extra) |

Step keeps the stance; a J in its Step starts J J on the move (V9l's moving snap carried over) [G]. U guards (every form).
Rejected sinks (R1 「避免同質化」): KIN's J no longer fires a wing; TENSHIN in (the forward dash) is gone (R2: the string's
end returns to melee).

| Clips | L | J | K |
|---|---|---|---|
| Base (`:lb-kamae`) | `:lb-fire`, `:lb-snap` | `:lb-snap`, `:lb-k-hosha` (revived) | `:lb-k-shot`, `:lb-k-taisha` |
| Awakened (EN, `:br-to-en`) | `:br-e-swing`, `:lb-e-q3` (revived) | `:lb-e-q1`, `:lb-e-q2` | `:lb-e-f1`, `:lb-e-f2` |
| The owl (EN) | `:br-oe-swing`, `:lb-oe-q3` | `:lb-oe-q1`, `:lb-oe-q2` | `:lb-oe-f1`, `:lb-oe-f2` |

### 3.3 The burst owl and the one full volley

- A burst in an awakened form (any colour, the shared rules) turns him into the owl until it ends, then back. No
  cinematic (`:lb-o-reveal` a candidate flourish). The base's burst stays plain [G].
- **One buff set** (R2: 「buff 不分顏色」) [G]: damage ×1.2, +1 wing a second, the 4-wing armour costs 2; plus V9j's owl
  numbers where they still apply (SP2 Trompete 120, its reflect and seal).
- **The full volley**: K3 → L in the owl, `:br-o-recall` → `:br-o-rc0..rc4`, every wing, tiers 0 / 1–2 / 3–4 / 5–7 / 8 =
  30 / 70 / 160 / 300 / 480 [G], SP2 after it uncharged (V9l). **The only spend-all**; outside the owl K3 → L opens the stance.

### 3.4 SP1 / SP2 by the special count (read, not spent)

| Wings (base pips) | SP1 (1 bar) | SP2 (2 bars; fixed damage: NIJUSHI-KO 90, the owl's Trompete 120, the base's HIRENKYAKU 50) |
|---|---|---|
| 0–3 (0–1) | 3 shots, +18 flash step | the charge as built |
| 4–7 (2) | 3 shots, +35 | half the charge |
| 8 (3) | 5 shots, +70 (a burst's worth) | no charge, a guard break on block |

### 3.5 The 4-wing armour

Awakened and the owl (the base's pips cap at 3): a hit that would stagger him during his own attack spends 4 wings (the
owl 2) and the move goes on; he takes the damage. Fewer: the hit lands as usual. Automatic; Breaker, Kikon and throws
ignore it [G].

### 3.6 What is gone

The owl's revival, MUJITTAI, the ground traces and their rules, TENSHIN in, KIN J's wing shot, the base stance's L / J /
K / SP shots as built (V1–V9l: replaced by the three strings) and its spend-all K. The slow motion moves to the first
stance hit of each stance and the volley's last beam (rev. 1) [G].

## 4. Animation plan

Reused: the inventory's v3 column and §3.2's table. New, all cosmetic: the lit wings (and the base's pips on Diagramm's
sleeve or the HUD only [G]); a wing / pip spent in a follow-up (a flash at the muzzle or the wing tip); the armour's
shatter (4 wings at once); optional: the burst's owl flourish (`:lb-o-reveal`), the judge beats for the 8-wing volley.

## 5. Open points

None blocks the build; every [G] number is a starting value for the playtest. Ask again only if the user changes a rule.

## 6. Build plan (after 「開始實作」)

1. Sim (`barro.lisp` only): the special counts and their sinks, the stance's strings and follow-ups in every form, the
   burst owl and its buff, SP1 / SP2 tiers, the armour; the traces, MUJITTAI, the revival, TENSHIN in and the old stance
   moves removed. The armour needs a kit hook in the shared hit path (inert for everyone else).
2. Art: §4. 3. CPU / ASSIST / learning. 4. Docs, manual, playtest; then his gates (6 pairings, the mirror, the A/B).
