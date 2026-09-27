# SOUL DUEL — J / K strings, the O ender, and KŌSEI, the aggression reward (2026-09-27)

Status: **built** (2026-09-27). §0–§8 are the design (r3) as the user decided it (§0.1); §9 records what the build does
differently, §10 the measurements (the seed gate). The as-built rules also live in DUEL_DESIGN.md §2, §3, §4, §6, §7.

The design sat on top of [DUEL_YAMA_REWORK.md](DUEL_YAMA_REWORK.md) (East / West by U, where West's J / K are
East's moves, pierce, the ward) and on the shared guard regen cut to about 40–50 % (`*gg-regen*` 12 → ~5.5/s).
**r2** follows the user's answers (§0.1): strings are up to **three links**, and each link is J or K. **r3**: J and K
switch **at most once** in a string (「K J 不要來回交錯」): 6 routes, §2.1.

## 0. The requests (verbatim)

> 2. 我希望 J/K 攻擊動作能更有人物特色，而且能組成 JJ、JK、KK、KJ 連段，重攻擊（K）雖然傷害高但速度慢，作為起手會被輕攻擊（J）搶先，作為結尾被防禦時又會有巨大破綻。另外只有在起手勢真的接觸到對手（無論是否被防禦）才會把後續的動作打出來，否則就只會揮出第一個動作後出現硬值破綻。
> 3. 還有只要攻擊動作完整打完，就能銜接 O 進行 combo 擊退＆對手，打中後繼續按住 O 可以銜接毀魂技，但只有當對手血量低於一定數值才必定命中，否則可以靠防禦擋下。
> (addition) 另外，我希望能引入新系統來獎勵積極進攻的玩家，並依據防禦量表的多寡改變獎勵的資源量：當處在防禦量表越少的狀態越積極，所獲取的資源會越多，以此鼓勵玩家從被動轉成主動。

"毀魂技" is the Kikon, and "血量低於一定數值" is red (30 %). The hold-O rule as built (DUEL_DESIGN §2) already makes the Kikon
guaranteed on red and guardable otherwise. Request 3 adds the **O ender** and **gates O cancels** to it.

### 0.1 User decisions (2026-09-27)
| # | Question | Decision |
|---|---|---|
| 1 | Keep neutral O (the rush from range)? | **Keep** |
| 2 | O ender only after a string that hit (not one that was blocked)? | **Hit only** |
| 3 | Remove O cancels off single hits, SPs, Breakers? | **Remove** |
| 4 | Strings exactly two hits? | **No, corrected**: 「JJ, JK 不代表真的只打兩下，只是說明時用來簡化表示輕連段與重連段的組合」. Strings are longer, and J / K mix along them (r2: up to 3 links, §2.1) |
| 5 | KATATE: base animations derived, with the cleaver? | **Yes, derived** |
| 6 | Kikon threshold = red 30 %? | **Yes** |
| 7 | KŌSEI pays Reiatsu + flash-step only (not the guard gauge or awakening)? | **Yes** |
| 8 | Blocked hits count as aggression; projectiles / hazards don't? | **Yes / no** |
| 9 | Hellfire uses Shikai's strings at ×1.3? | **Yes** |
| 10 | (r3) 「K J 不要來回交錯」 | J / K switch **at most once**: JKJ and KJK are dropped. Routes JJJ, JJK, JKK, KKK, KKJ, KJJ (or stop early). After a switch only the new button continues (§2.1) |

## 1. What exists today, and what changes

| Today (code) | Change |
|---|---|
| Q1 → Q2 → Q3, F1 → F2, the branch Q2 → F (`:enter` 6–8 f). J and K can't mix at link 2, and K can't go to 3 | **A 3-link grid**: link 1, 2, 3, each J or K, with **one move per (link, button)**: `J1 K1 J2 K2 J3 K3`. Link 3 depends on whether the string already switched, so the two **switched** link-2 moves are data aliases: `J2s` (J2 after K1) and `K2s` (K2 after J1) are the same frame data and clips as J2 / K2 (a `defmove` copy, **0 new clips**), with no switch-back string. `:strings`: `(J1 :q J2) (J1 :f K2s) (K1 :f K2) (K1 :q J2s) (J2 :q J3) (J2 :f K3) (K2 :f K3) (K2 :q J3) (J2s :q J3) (K2s :f K3)`, which gives 6 routes from 6 animated moves + 2 aliases. The Q3 ender and the Q2→F branch survive as J3 and K2 / K3 (their clips are reused, §3). Every K at link 2 / 3 enters through `:enter` |
| `chain-open-p`: on a whiff (NIL contact) the string goes on | **Whiff never chains**: `(and contact …)`, one line. The gate applies at **every** link |
| The next press must fall in the 10 f vpad buffer before the chain opens | **Latch** (`fighter-queued`): a J / K press from the current link's frame 0 until its chain closes is stored, the last press wins, and it's consumed from the vpad at once (no double fire). It fires at chain open if that link made contact, and is dropped otherwise |
| Whiff recovery R + 6 | J links R + **8**, K links R + **12** (`*whiff-extra-j*` / `*whiff-extra-k*`); other kinds keep 6 |
| O cancel from **any landed move**, aura played | **Only from a link-3 move (J3 / K3) that hit** (flag `:ender`), and the aura is skipped. Single-hit, link-2, SP and Breaker → O cancels are deleted (decision 3) |
| Neutral / run O rush; the hold-O Kikon rule | **Unchanged** (decisions 1, 6) |
| L / SP / Hoho cancels off a landed Q / F | Unchanged, off any landed link |
| `contact-of` | Unchanged: it already is the gate the user asked for (§2.2) |

Renamed or deleted data: `:ya-q3 :ya-f2 :ya-f2q :ya-e-q3 :ya-e-f2 :ya-e-f2q :ke-q3 :ke-f2 :ke-f2q :ke-r-q3 :ke-r-f2
:ke-r-f2q` become the link moves of §3 (the same clips, new frame data). West's J / K set is already gone in the rework.

## 2. The string rules

### 2.1 Shape and frame budget
Up to three links, each J or K, **switching button at most once** (r3). Allowed full routes: **JJJ, JJK, JKK, KKK,
KKJ, KJJ**; any of them may stop after link 1 or 2. **Input rule**: after a switch (J→K or K→J) the string goes on only
with the button switched to. A press of the original button is **ignored**: it isn't latched, it's consumed (so it
can't start a stray J1 / K1 after the string), and it doesn't overwrite an allowed press already latched. If nothing
allowed is pressed, the string ends at that link (not completed, no O). The move still depends only on (link, button),
with the switched link-2 aliases carrying the no-switch-back rule in data, so a route reads left to right: **J = fast
and light, K = slow and heavy, the third link is the finish**. The budget every form obeys (host test,
`tests/duel-rules-test.lisp`):

| Link | S / A / R | React | Block | Rule |
|---|---|---|---|---|
| J1 | S 7–10, A 3, R 12 | flinch 18 | −2 | |
| K1 | S 16–20, A 4, R 20–22 | stagger 26 | −3 | **no armour**; S(K1) − S(J1) ≥ 7 in every form (J beats K) |
| J2 | S 7–9, A 3, R 13 | flinch 18 | −2 | |
| K2 | S 19–22, `:enter` → **S_eff 14**, A 4, R 24 | stagger 26 | −3 | |
| J3 (ender) | S 8–10, A 3, R 18 | stagger 26 | **−4** | hit +6 |
| K3 (ender) | S 20–22, `:enter` → **S_eff 14**, A 5, R 34 | crumple 40 | **−20** | hit +1 … +2; J **and** K1 punish it |
| On-hit combo | A(prev) + S_eff(next) ≤ hitstun(prev) − 1 | | | after a J link (A 3, flinch 18) S_eff ≤ 14, the binding case; after a K link (A 4, stagger 26) ≤ 21 |
| On-block gap | gap = S_eff(next) + block adv(prev) (DUEL_DESIGN §4's measured rule) | | | a **K link after anything leaves ≥ 11 f**: every J (≤ 10 f) fits, so J beats K mid-string. A J link leaves 3–7 f: Step / Hoho fit, J doesn't |

Link 2 and 3 K moves share S_eff 14, so one move combos after either button. The enders stagger or crumple instead of
knocking back or launching, so the O ender can connect. The O strike does the knockback.

### 2.2 The contact gate (every link)
A link fires only if the **previous link's own hit window** touched the opponent (`fighter-contact` non-NIL):

| Previous link's result | Next link? | Note |
|---|---|---|
| hit, counter-hit | yes | combo timing |
| blocked guard, **West's ward**, **DRINK** | yes | block timing (the 3 f lead, the gaps above) |
| Kenpachi's stance absorb, CHARGE's rush armour | yes | the next link feeds the stance too. That's his "try to cut me", on purpose |
| parried | moot | the attacker is in the 32 f parry stagger |
| whiff, out of range, Step / Hoho / down iframes | **no** | the string stops there, with R + 8 (J) / R + 12 (K) |
| only a hazard touched him (KUKAN-GIRI's rift) | **no** | hazards never set the move's contact |
| trade | moot | he is in hitstun |

### 2.3 Buffer and latch
- A J / K pressed any time from a link's frame 0 until its chain closes is **latched**, and the last press wins. It
  fires at chain open (on hit from `s + a`, on block at `total − 3`) and is discarded on a whiff.
- Presses during link 3 are plain vpad-buffered (10 f), so mashing J gives JJJ, a pause, then a new J1.
- O is read from J3 / K3's hit frame to the end of its recovery (`cancel-open-p`), buffered 10 f.

### 2.4 The O ender
- **Completed string** = a **link-3 move (J3 or K3) that hit**. Any of the 6 routes qualifies, and J3's lighter finish
  counts exactly like K3. A string that stops at link 2 (not pressed, or a link-2 whiff) isn't completed: no O cancel.
- **When**: J3 / K3 contact `:hit`, and the module not cooling (90 f).
- **What**: the form's Kikon module (ENJO / TENCHI / CHARGE / LEAP CLEAVE) with the **aura skipped**: `:strike` at once
  within 1.6 m, else its dash. Damage 70 (as hit 4 of a combo: ×0.9 = 63), knockback 2.5 m, guard 20, −14 on block. It
  always combos: the worst case is LEAP CLEAVE on a RYOTE K3 at 4.2 m (≈ 9 f leap + S 11 = 20 f < crumple 40), and ENJO
  S 20 < J3's stagger 26.
- **Hold O**: the hold-O rule as built: knockback, dash-in, follow-up. **Red (< 30 %)**: unguardable, the Kikon
  (Konpaku −2 / −3 / −4, cap 4). **Not red**: he can guard during the dash (16 + 12 f); Step / Hoho dodge it; a Burst escapes.
  **Released**: the knockback hit only (it may Soul Break a red opponent at 0).
- A blocked or whiffed link 3 gets no O cancel (decision 2: a cancelled −20 would stop being a punish). Neutral O is
  still there after recovery.
- **Interplay**: West's ward blocks a non-red follow-up, and the red one goes through (the rework's unguardable rule).
  DRINK drinks a non-red follow-up (no Kikon), and a red one can't be drunk. Nozarashi's worth is read at rush start.
  NOMIHOSE's cash-out isn't a string, so it has no O ender. Burst Reverse is legal from hit 2 on, so a string can be
  Burst before O.

## 3. Per-form moves (6 per form) and routes

Columns: S/A/R (enter → S_eff); dmg before form multipliers; Blk = block advantage; Whiff = total whiff recovery.
Pose keys follow STYLE_STORM §2.6: a held wind-up, a `:snap` into the hit pose at S, overshoot, a zanshin hold, a
settle; 3–4 f attacker holds on K hits; the comet smear on heavies. Normals have no callouts, as today.

### 3.1 Yamamoto: Shikai (`:base`; Hellfire inherits at ×1.30). New clips: **1**
Identity: an old man's economy, one arm, fire does the work.

| Link | Name | Clip | S/A/R | Dmg | React | Blk | Whiff | Volume | Pose (one line) |
|---|---|---|---|---|---|---|---|---|---|
| J1 | 火閃 HISEN | `:ya-q1` | 9/3/12 | 38 | flinch | −2 | 20 | 2.4 m 100° | from the draw, a flat right-to-left cut, the haori trailing, the flame tongue hangs 2 drawings |
| J2 | 返し火 KAESHIBI | `:ya-q2` | 8/3/13 | 38 | flinch | −2 | 21 | 2.4 m 100° | the wrist turns over, a backhand along the same line; the flame reverses into a ring |
| J3 | 袖火 SODEBI | **new** `:ya-sleeve` | 9/3/18 | 45 | stagger | −4 | 26 | 2.2 m 140° | he whips the **empty left sleeve**, which catches fire, across the face: a one-armed silhouette, the sleeve a FIRE ribbon |
| K1 | 焔薙 HOMURA-NAGI | `:ya-f1` | 18/4/20 | 75 | stagger | −3 | 32 | 3.0 m 150° | a long anticipation, the blade drawn back past his hip, then a waist-high sweep that fans fire; +20 Inferno |
| K2 | 昇焔 SHŌEN | `:ya-f2` | 22/4/24 (8 → 14) | 80 | stagger | −3 | 36 | 2.6 m 90° | he sinks and rises with the cut, a flame column blooms; 4 f hold at the top; +20 Inferno |
| K3 | 焔爆 ENBAKU | `:ya-q3` | 22/5/34 (8 → 14) | 110 | crumple | −20 | 46 | 2.8 m 120° | the blade stabbed down at his feet, the flame bursts out in a dome, beard and sleeve blown back; 4 f hold; +20 Inferno |

### 3.2 Yamamoto: Bankai East (`:bankai-east`; West's J / K drop to these). New clips: **1**
Identity: thin ember lines, the sun's path. ×1.0 + pierce, taken ×1.5 (rework).

| Link | Name | Clip | S/A/R | Dmg | React | Blk | Whiff | Volume | Pose |
|---|---|---|---|---|---|---|---|---|---|
| J1 | 日差 HIZASHI | `:ya-q1` | 8/3/12 | 34 | flinch | −2 | 20 | line 3.1 | a flat edge line, no fire; a white-hot scratch hangs 1 drawing |
| J2 | 残照 ZANSHŌ | `:ya-q2` | 7/3/13 | 38 | flinch | −2 | 21 | line 3.1 | the return stroke; the two afterglows cross into an X (his scar) for 6 f |
| J3 | 穿光 SENKŌ | `:ya-e-thrust` | 8/3/18 | 42 | stagger | −4 | 26 | line 3.6 | a short straight thrust, no lunge (KYOKKŌ is the lunge) |
| K1 | 陽炎 KAGERŌ | `:ya-f1` | 16/4/20 | 70 | stagger | −3 | 32 | line 3.8 | a wide sweep; the air behind it shimmers (a heat-haze band on twos) |
| K2 | 日昇 NISSHŌ | `:ya-f2` | 19/4/24 (5 → 14) | 75 | stagger | −3 | 36 | line 3.8 h 1.3 | a rising cut; the edge traces a half-disc, a rising sun, for 3 drawings |
| K3 | 落日 RAKUJITSU | **new** `:ya-e-drop` | 21/5/34 (7 → 14) | 105 | crumple | −20 | 46 | vertical line 0.3 → 3.6 | the blade straight up, one-armed, held 3 f, falling in a vertical arc (the setting sun); ember sparks on the plaza |

### 3.3 Kenpachi: base (`:base`). New clips: **1**
Identity: no school, a street fighter with a sword who kicks.

| Link | Name | Clip | S/A/R | Dmg | React | Blk | Whiff | Volume | Pose |
|---|---|---|---|---|---|---|---|---|---|
| J1 | 荒斬 ARAGIRI | `:ke-q1` | 7/3/12 | 35 | flinch | −2 | 20 | 2.6 m 100°, lunge 0.8 | a lazy one-handed slash thrown from the shoulder, grinning |
| J2 | 返斬 KAESHIGIRI | `:ke-q2` | 7/3/13 | 35 | flinch | −2 | 21 | 2.6 m 100° | the backhand back across, the haori flaring |
| J3 | 喧嘩蹴り KENKA-GERI | **new** `:ke-kick` | 8/3/18 | 42 | stagger | −4 | 26 | 2.2 m 60° | a flat front kick to the gut, the sword held out wide the other way |
| K1 | 大振り ŌBURI | `:ke-f1` | 16/4/20 | 70 | stagger | −3 | 32 | 3.0 m 120° | a huge two-handed wind-up over the right shoulder, the whole torso turning |
| K2 | 斬り上げ KIRIAGE | `:ke-f2` | 20/4/24 (6 → 14) | 75 | stagger | −3 | 36 | 2.6 m 90° | both hands, from the floor up; hold at the top, arms wide |
| K3 | ぶん回し BUNMAWASHI | `:ke-q3` | 20/5/34 (6 → 14) | 100 | crumple | −20 | 46 | 2.8 m 360° | the swing carries him into a full spin, the blade at arm's length; smear on the whole turn |

### 3.4 Kenpachi: Nozarashi cups
- **Cup 1 KATATE**: derived from base (+2 f, reach ×1.3), the same clips with the cleaver. New clips: **0**. `:enter`
  shifts with the startup, so S_eff stays 14: J1 9, J2 9, J3 10, K1 18, K2 22 (8), K3 22 (8).
- **Cup 2 RYOTE** (×1.15), two-handed kendo. New clips: **2**.

| Link | Name | Clip | S/A/R | Dmg | React | Blk | Whiff | Volume | Pose |
|---|---|---|---|---|---|---|---|---|---|
| J1 | 面 MEN | `:ke-r-q1` | 10/3/12 | 40 | flinch | −2 | 20 | line 0.3 → 3.9 | jōdan, a straight overhead, the kiai |
| J2 | 小手 KOTE | **new** `:ke-r-kote` | 9/3/13 | 38 | flinch | −2 | 21 | 3.6 m 60° | a small wrist snap: the only small motion in the set |
| J3 | 袈裟 KESA | `:ke-r-q3` | 10/3/18 | 48 | stagger | −4 | 26 | 3.8 m 140° | a diagonal through the shoulder line, the follow-through low |
| K1 | 胴 DO | `:ke-r-f1` | 19/4/20 | 85 | stagger | −3 | 32 | 4.2 m 160° | the wide body cut |
| K2 | 諸手突き MOROTE-ZUKI | **new** `:ke-r-tsuki` | 21/4/24 (7 → 14) | 85 | stagger | −3 | 36 | line 0.3 → 4.4 | both hands drive the cleaver straight out, the back foot sliding; hold 4 f fully extended |
| K3 | 兜割り KABUTO-WARI | `:ke-r-f2` | 21/5/34 (7 → 14) | 115 | crumple | −20 | 46 | line 0.3 → 4.2 | the cleaver high, held, dropped; the victim crumples to his knees |

- **Cup 3 NOMIHOSE** (×1.20): RYOTE's moves, except **K1 = KUKAN-GIRI** (as built, 20/4/22, 90, −4, the rift, which makes
  a blocked K1 +8 net). New clips: **0**. After a blocked KUKAN-GIRI the next link's gap is closed by the rift: that's
  cup 3's reward. The rift isn't contact, so a whiffed KUKAN-GIRI whose rift hits gets no link 2.

**New clips: 5 in all** (Shikai 1, East 1, Kenpachi base 1, KATATE 0, RYOTE 2, NOMIHOSE 0); every other move reuses a
clip at a new speed (`:clip-s`).

### 3.5 Route examples (Kenpachi base, on hit, before multipliers; the combo scaling starts at hit 4)
JJJ 112 · JJK 170 · JKK 210 · KKK 245 · KKJ 187 · KJJ 147. Add the O ender (hit 4, ×0.9) = +63.
Old: Q string 125, F string 160, Q Q F 160. Blocked guard drain: J 8, K 14, K3 18 (the +4 ender bonus), so JJJ 24,
KKK 46.

## 4. Controls and AI

**Keyboard / pad**: unchanged (J / X light, K / Y heavy, O / RT Kikon). DUEL_DESIGN §3's rows become "up to three
links, each J or K".

**Mobile one-hand** (DUEL_MOBILE_DESIGN §2, one row edited): tap = J, flick ↑ = K (already so), so a route is three
taps / flicks with at most one change between tap and flick (an extra change is ignored). Thanks to the latch each gesture can come any time during the previous link. Flick ↑
in `:move` is already F (never Hoho). The O chip's LIGHT Kikon latch holds O through the strike. No new gesture.

**AI** (generic; keys in the kit `:ai`):
- `string-reflex` on hit: the next link is K with `*ai-string-flash-p*` 0.5, else J, among the links `kit-next`
  allows (after a switch only one exists, so the switch-once rule is automatic), up to link 3 (it presses once,
  after the link makes contact; the latch does the rest).
- **O ender** (new, first reflex on a J3 / K3 hit): red → O always (held through strike: aura 0 + dash-max + S + 4);
  not red → the kit's `:o-ender` (default **0.35**; Nozarashi cups 0.25 / 0.35 / 0.6). The old "any landed hit on red →
  O" cancel goes (decision 3).
- **Block pressure**: on a blocked link it goes on with a **J** link with `:block-string` p. A K link on block only
  0.15 of that (the defender's J can interrupt it), and it never goes into link 3 on block when link 3 would be K. After
  two blocked links it resets to J1 (the existing reset).
- **J beats K** (new generic reflex): an opponent's K link in startup with ≥ S(J1) + 2 frames left, within J reach → J1,
  p EASY 0.2 / NORMAL 0.45 / HARD 0.7 (Kenpachi's stance react and West's parry keep their priority).
- **Punish**: a blocked ender (≤ −8) → J1, as now. At −20 (K3) HARD uses K1 when in K reach.
- **Guarding a non-red follow-up**: its own roll `*ai-follow-guard-p*` EASY 0.6 / NORMAL 0.85 / HARD 0.95.
- **KŌSEI**: neutral attack chance +0.2 × (1 − gg/100).

## 5. KŌSEI 攻勢, the aggression reward

**What pays**: every resolved contact of the attacker's **own melee hit window** (the `own` test that sets
`fighter-contact`): hit, counter, blocked by a guard / ward / DRINK, armoured, absorbed. That covers J / K links, the O
ender and the neutral O strike, the Breaker, SP blades and West's counter. **What doesn't**: whiffs, iframes, parried
hits, every hazard and `:ranged` window (fire wave, Shiranui, pillars, SHŌNETSU, the rift, the heat cone, the Meteor
line), Kikons and scorch. Moving forward, running at him or backing off pays nothing, because only contact counts.

**Formula** (`kosei-mult`, rules.lisp; one call in `apply-hit` next to the Reiatsu gain):
```
m     = 1 + *kosei-bonus* × (1 − gg_attacker / *gg-max*)      ; ×1 full … ×3 empty (guardless: its real gg)
g     = the hit's guard value (guard-value / hitwin :guard, before the defender's cut / ward / garb)
Reiatsu    += *kosei-reiatsu* × g × m      ; 0.20
Flash-step += *kosei-fs*      × g × m      ; 0.10
```
Examples: a JJJ that hits or is blocked (g 24): full +4.8 R / +2.4 FS, empty +14 / +7. KKK + O ender (46 + 20): full
+13 / +6.6, empty +40 / +20. That's on top of the existing +0.08 Reiatsu per damage dealt and Reiatsu's +3/s. A
low-gauge attacker who lands a string every ~3 s roughly doubles his SP income.

**Not paid** (decision 7): the guard gauge (the user removed "attacking refills the gauge" from Bankai, and paying it
would cancel the incentive), the awakening gauge, NOME (Kenpachi's own dealt source exists).

**HUD**: when m ≥ 1.5, a small ember `攻 ×2.4` tag at the end of the guard bar; each paying contact sends one ember mote
from the hit spark to the Reiatsu bar (size by m). No new bar.

**Interactions**
- **Halved guard regen**: gauges stay low longer, so the average m rises (a guess: 1.3 → 1.6 between CPUs). First
  knob: `*kosei-bonus*`.
- **GUARD HOLD**: resting in guard freezes the refill and pays nothing, so a low gauge is worth something only if he
  attacks. That's the push from passive to active.
- **Yamamoto East pierce** pays **damage** at a **full** gauge; KŌSEI pays **resources** at a **low** one. Both reward
  only attacking, and the gauge just picks the currency, so both are kept.
- **West's ward**: West never refills, so its gauge falls as it wards. A West strike drops to East, and that contact is
  paid at the low gauge's m (ward, then strike back). A parry catch refills to 100, which resets m to ×1: self-limiting.
- **DRINK / NOME**: cup 3's gauge falls fast, so NOMIHOSE pays near ×3. That's on theme; watch the cash-out frequency. A
  hit drunk by *his* DRINK pays the **attacker**.
- **Kenpachi's stance**: hitting into it pays the attacker a little, but it feeds his stored cut. Not worth farming.

**Anti-degenerate checks**
1. *Dumping guard to farm*: no move lowers your own gauge. It falls only by blocking or warding the opponent's hits,
   which risks a crush; a crushed fighter gets ×3 but paid 40 f of reel and a long guardless refill. Watch it in play.
2. *Poking a turtle with J for meter*: each blocked J pays 1.6–4.8 R and drains his gauge. That's pressure, as intended,
   and each −2 link still leaves a Step / Hoho gap.
3. *Zoning*: projectiles and hazards pay nothing.
4. *Parity*: symmetric, sim-side, deterministic like every gauge.

## 6. Balance and adversarial self-critique

**Match length.** Baseline (guard v3 follow-up): YY 165.3, YK 155.1, KK 169.2 s median; window 125–210 s, all K.O. The
rework's own estimate is YK 150–170 s. The effects here:
- Per landed opening: the CPU's J-heavy pick (JJJ / JJK) ≈ 112–170 vs the old Q string's 125, and the O ender adds 63
  when off cooldown: roughly **+20 to +50 %**. Shorter.
- Whiffs no longer chain, and whiffed links are punished: shorter.
- Halved regen means more crushes, and KŌSEI means more SPs: shorter.
- Non-red Kikons through O-ender follow-ups: shorter, and this is the big one (B1).
- A blocked K link is J-interruptible, and a blocked K3 at −20 is punished by a string: more exchanges end in a punish.
  Shorter.
- Guess: medians **−15 to −30 s** (YK ~125–140), which is at the window's lower edge, so the gate decides. Knobs, in order:
  `*ai-follow-guard-p*`, `:o-ender`, the link-3 damage (J3 / K3), `*kosei-bonus*` / `*kosei-reiatsu*`, the O ender's
  70, `*whiff-extra-k*`. If still short: `*reishi-max*` stays out of it (it's the user's), so K2 / K3 damage goes −10 %
  first.

| # | Sev | Finding | Resolution |
|---|---|---|---|
| B1 | BLOCKER | CPU victims guard the non-red dash-in only 0.55 (NORMAL); with an O ender after every completed string, Kikons land on non-red CPUs far more than on humans, and medians fall under 125 s | `*ai-follow-guard-p*` 0.85 NORMAL; `:o-ender` 0.35 when not red; the gate measures it |
| B2 | BLOCKER | A latched press plus the 10 f vpad buffer would fire twice | The latch consumes the vpad press when it stores it |
| B3 | BLOCKER | One K move per link must combo after J (flinch 18) **and** K (stagger 26) | Every K2 / K3 enters at **S_eff 14** (A3 + 14 = 17 ≤ 17); the host test asserts it for every (prev, next) pair per form, derivations included |
| M1 | MAJOR | Enders with knockback / launch (old Q3, F2) would make the O ender whiff | J3 staggers, K3 crumples; the O strike does the knockback. The air-combo loss is accepted (the flurry still launches) |
| M2 | MAJOR | O off a blocked ender would make −20 safe | Hit only (decision 2) |
| M3 | MAJOR | KATATE's +2 derivation could break links | `:enter` shifts with `startup-add`, so S_eff is unchanged; covered by B3's test |
| M4 | MAJOR | The stance absorb and West's ward count as contact, so later links are spent into them | Intended: the user's "hit or block"; both are blocks to the attacker |
| M5 | MAJOR | KKK blocked drains 46 guard: with halved regen, two blocked KKKs nearly crush | KKK on block eats two J interrupts and a −20 punish first, so the risk pays for the drain; `:block-string` never goes K3 on block in the AI |
| M6 | MAJOR | KŌSEI's guardless ×3 rewards being crushed | The crush costs more; the fallback is guardless = ×2 |
| M7 | MAJOR | East pierce vs KŌSEI look contradictory | Two currencies, both only for attacking (§5) |
| M8 | MAJOR | 6 routes with 6 moves means the same J2 after J1 and K1, which is less "route flavour" | The position grid is the readability win (a route reads by button), and the clip count stays at 5 new. Per-route variants can come later only if play asks for them |
| M9 | MAJOR | (r3) Link 3 now depends on the route, not only on the previous move, which `kit-strings` (keyed on the current move) can't express | The switched link-2 moves are aliases (`J2s`, `K2s`) whose strings allow only the new button: pure data, no new clips, no engine change. The alias must copy the move, including `:enter`, and the host test asserts the alias equals its original apart from its name |
| m4 | MINOR | (r3) A player who presses the original button after a switch expects something | It's ignored and the string ends there; the ender isn't there, so there's no O. That's the clearest rule, and there's nothing to learn beyond "switch once" |
| m1 | MINOR | ENJO's lane starts at 1.0 m | Capsule r 1.4 covers point blank |
| m2 | MINOR | A K1 whiff = 54 f total for Yamamoto | `*whiff-extra-k*` knob; K is a close tool |
| m3 | MINOR | A string that stops at link 2 has no O | By definition (§2.4); J3 is 8–10 f, so finishing is cheap |

## 7. Questions for the user

None new. The 9 answers and the Q4 correction are in §0.1.

## 8. Implementation sketch (as planned; §9 says where the build went)
- rules.lisp: `chain-open-p` needs contact; `kosei-mult`. tuning.lisp: `*whiff-extra-j* 8`, `*whiff-extra-k* 12`,
  `*kosei-bonus* 2.0`, `*kosei-reiatsu* 0.20`, `*kosei-fs* 0.10`, `*ai-follow-guard-p*`.
- kit.lisp `defmove`: whiff default by kind; the `:ender` flag (J3 / K3).
- fighter.lisp `move-commands`: the latch (`fighter-queued`); the `:kikon` branch requires `:ender` + `:hit`; the rush
  starts with its aura spent (`fighter-phase` → `:strike` / `:dash`).
- combat.lisp `apply-hit`: the KŌSEI gain for `own` contacts that aren't `:parried` or `:ranged`.
- yama.lisp / ken.lisp: the 6 moves + 2 aliases (`J2s`, `K2s`) per form and the 10 `:strings` entries (§1, §3); the latch ignores and consumes a press with no `kit-next`. ai.lisp: §4. hud.lisp: the `攻 ×m`
  tag and the mote.
- tests: the §2.1 budget per form (every (prev, next) combo pair, block gaps, J vs K, K3 −20, J3 −4); a probe that a
  whiffed link doesn't chain; that a blocked J → K leaves ≥ 11 f; and that O cancels only off a J3 / K3 hit.
- Docs: DUEL_DESIGN §2 (the O cancel), §3, §4 (strings), §6 tables, §6.3, §7, §12 rows; DUEL_MOBILE_DESIGN §2's tap row.

## 9. As built: what differs from §0–§8

Code: `rules.lisp` (`chain-open-p` needs contact, `kosei-mult`, `kosei-gain`), `kit.lisp` (`:grid` → the ten strings,
`string-grid`, `defmove-copy`, `string-link-p`, `string-latch`, the whiff default by kind, the `:ender` flag),
`fighter.lisp` (`move-commands`: the latch, the O ender, `skip-aura`), `combat.lisp` (`kosei!`), `ai.lisp`,
`hud.lisp` (`hud-kosei`, `%kosei-mote`), `yama.lisp` / `ken.lisp` (the moves), the five clips in `yama-art.lisp` /
`ken-art.lisp`, two draw-side looks in `main.lisp`. Host tests in `tests/duel-rules-test.lisp` (the §2.1 budget over
every reachable link of every form, the six routes, the latch, the contact gate, the whiff recovery, J beats K, K3 −20,
the O ender's combo, KŌSEI).

| # | Design | Built | Why |
|---|---|---|---|
| 1 | Damage as §3 | **K2 / K3 (and K2s) deal 80 %** of §3's numbers: Shikai 64 / 88, East 60 / 84, Kenpachi 60 / 80, RYOTE 68 / 92 (KATATE and NOMIHOSE inherit). Routes (Kenpachi base, §3.5): JJJ 112, JJK 150, JKK 175, **KKK 210**, KKJ 172, KJJ 147 | The seed gate (§10): at 100 % the medians were YY 106.8 / YK 119.0 / KK 121.7 s, under the 125 s floor. §6's first lever |
| 2 | AI: next link K at `*ai-string-flash-p*` 0.5 | **0.3** | The gate: K links carry the damage (and Yamamoto's Inferno, +20 each) |
| 3 | AI: `:o-ender` default 0.35 | `*ai-o-ender*` **0.15** (Nozarashi's cups keep 0.25 / 0.35 / 0.6) | The gate. On a red opponent the O ender is still always taken |
| 4 | (not in the design) | **`*ai-sp-cancel-p*` 0.3**: the CPU's SP2 cancel off a string's last hit is one roll on the hit's first step (it used to press every step, so it was certain) | Link 3 staggers / crumples instead of launching or knocking back, so the SP2 cancel (Kenpachi's flurry: 185) always combos off it: KK's flurry damage went 2.5 → 6.5 per second |
| 5 | J beats K: a reflex on the perceived opponent's K link startup | **felt at once** on the CPU's first free step after its blockstun, when the string's next link is a K link still ≥ S(J1) + 2 f from its hit (`j-beats-k-p`, checked before a guard held through the string) | As written it could never fire: NORMAL's 14 f perception delay is longer than any K link's remaining startup, and a CPU holding guard through a string runs no reflex. Between CPUs it is still rare (7 in the 60-match gate) because the block pressure picks a K link only 0.15 of the time |
| 6 | Block gap = S_eff(next) + block adv(prev) (§2.1) | Measured: **gap = S_eff − 1 − `*chain-lead*` − adv**: S_eff − 2 after a −2 link (the rule's case), **S_eff − 1 after a −3 one** (a K link, K1 / K2) | The rule was measured on Q1 → Q2 (−2) only. Consequences: every K link leaves ≥ 12 f (not 11), so J still beats K; after a blocked K link the J link's gap is S_eff − 1: Kenpachi's K2 → J3 and KATATE's K2 → J3 leave exactly their own J1 (7 / 9 f), a trade, not an interrupt. The host test asserts gap ≤ S(J1) |
| 7 | O ender: the rush with the aura skipped | `skip-aura`: `kikon-rush-next-phase` with the aura spent, so the strike starts at once within `*kikon-trigger*` (and always for ENJO, no dash), else the dash | Reuses the rush's state machine |
| 8 | The mobile O chip's LIGHT Kikon latch | Not built (DUEL_MOBILE_DESIGN §12 lists LIGHT as not built): the chip is O while it is touched; a tap is the O ender, a hold is the Kikon | Out of this batch's scope |
| 9 | HUD `攻 ×2.4` | `攻` in brush (the glyph baked into `glyphs.lisp`, `tools/glyph-bake.py`) and `x2.4` in the HUD's block font, at the inner end of the guard bar (on the Konpaku row, clear of the timer) at m ≥ 1.5; the ember mote's screen point is taken at the hit (0 B per frame: the 2328 probe's "kosei mote") | The brush set has no digits |
| 10 | SODEBI: the sleeve a FIRE ribbon; RAKUJITSU: ember sparks on the plaza | Draw-side looks (`main.lisp`): the blade-fire look along the empty left sleeve over the hit; embers and a scorch mark 2.2 m ahead at RAKUJITSU's S | Looks only: the sim is unchanged |
| 11 | East's J2 was the derived Shikai Q2 | East's own J2 ZANSHŌ (a line 3.1 m), as §3.2 | — |
| 12 | Non-string moves' whiff R + 6 | kept (`*whiff-extra*`); J links R + 8, K links R + 12 by kind (`:quick` / `:flash`), so NOMIHOSE's KUKAN-GIRI (its K1) whiffs R + 12 | — |

Tools: `tests/scripts/duel-strings.json` (`duel.py`: every route and the O ender by keyboard, debug 2394+k, stills
`tests/shots/duel-string-*.png`), `duel-view-strings.json` (the five new clips' strips; `duel-view.py`'s clip list now
includes the `defrun` clips, whose absence had shifted every strip name after `KE-R-STANCE`), `duel-touch.json` (J J J
and the O chip), debug knobs 24000–29000 (DUEL_GAMEPLAY.md).

## 10. Measured (the seed gate, 2026-09-27)

Debug 2113, `tests/scripts/duel-gate.json` (`--secs 1100`), 20 seeds per pairing, NORMAL, cinematics included.

| Pairing | Median | Min–max | K.O. | Wins (P1 / P2) |
|---|---|---|---|---|
| YY | **129.4 s** | 97.7–165.1 | 20 / 20 | 9 / 11 |
| YK | **137.3 s** | 77.0–196.1 | 20 / 20 | **Yamamoto 10** / Kenpachi 10 |
| KK | **130.4 s** | 97.4–172.0 | 20 / 20 | 7 / 13 |

Before (the Bankai rework): YY 128.6, YK 129.9 (Yamamoto 10), KK 169.2 s. As §6 guessed, the strings as designed cut
the medians: YY 106.8, YK 119.0, KK 121.7 s (KK most, −48 s: KKK and the flurry off link 3). The sweeps (runtime knobs,
each a full gate; the medians' seed noise is about ±5 s): K2 / K3 at 100 / 90 / 80 / 70 % averaged 116 / 120 / 124 /
125 s over the three pairings; the string's K at 0.3 +2 s; the O ender at 0.20 / 0.15 +0–2 s; KŌSEI halved or off and
the follow-up guard at 0.9 inside the noise; the one-roll SP cancel −4 to +13 s pairing by pairing. The chosen set
(80 %, K 0.3, SP cancel 0.3, O ender 0.15) is the one with every median ≥ 129 s and YK within 8–12; the string's K at
0.2 gave more room (137.5 / 131.2 / 136.2 s) but Yamamoto 14 / 20.

In the final gate (7883 match seconds): 35 hits and 6 blocks a minute; per string link 1 J 1529 / K 255, link 2 1224,
link 3 1122 (J3 612, K3 510); 331 O enders (red always, else 0.15 or the cup's); dash-in follow-ups on a red victim 263
(224 Kikons), on one who wasn't red 148 (110 guarded, 14 Kikons); 7 J-beats-K interrupts; damage 35.6 per match second (YY
28.6, as before the strings; KK 43.3, 35.8 before: Kenpachi's KKK and his SP2 off link 3). The G2 reference `duel-cvc-yk.json` (seed 7) ends
`duel -> RESULTS winner P2 konpaku 0-3 ticks 7123 secs 118.7`.
