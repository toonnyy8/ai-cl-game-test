# SOUL DUEL — J / K strings, the O ender, and KŌSEI, the aggression reward (2026-09-27)

Status: **built** (2026-09-27). §0–§8 are the design (r3) as the user decided it (§0.1); §11 (2026-09-28) revises the gate: after any contact every later link comes out and chases the defender. §9 records what the build does
differently, §10 the measurements (the seed gate). §13 (2026-09-29) cuts every J to 0.4–0.6× and every K a little (J light, short and fast; K heavy, long and slow), §14 puts the grab under J (防 > J > I > 防). The as-built rules also live in DUEL_DESIGN.md §2, §3, §4, §6, §7.

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
| `chain-open-p`: on a whiff (NIL contact) the string goes on | **Whiff never chains**: `(and contact …)`, one line. The gate applies at **every** link (revised 2026-09-28: only link 1 is gated by its own contact; after any contact every later link comes out and chases him, §2.2, §11) |
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

### 2.2 The string gate and the follow-up chase (revised 2026-09-28, §11)
Link 1 is gated by its own contact; **once any link of the string has made contact (hit or block), every later pressed
link comes out**, and it **chases** the defender during its startup so its hit window reaches him. The chase is motion
only: the link can still be guarded, and Step / Hoho / down iframes still dodge it. (Until 2026-09-28 every link was
gated by its own contact: a link that whiffed ended the string.)

| This link's result | Next pressed link? | Note |
|---|---|---|
| hit, counter-hit | yes, at hit timing (from `s + a`) | combo timing |
| blocked guard, **West's ward**, **DRINK**, Kenpachi's stance absorb, CHARGE's rush armour | yes, at block timing (the last `*chain-lead*` 3 f) | the 3 f lead, the gaps of §2.1 |
| whiff (out of range, Step / Hoho / down iframes), **link 1** | **no** | the string stops there, with R + 8 (J) / R + 12 (K) |
| whiff, **link 2 or 3** (an earlier link touched him) | **yes**, at block timing | the string carries on (`fighter-chained`); unpressed, it recovers with its whiff recovery |
| only a hazard touched him (KUKAN-GIRI's rift) | as a whiff | hazards never set the move's contact |
| parried / trade | moot | he is in the parry stagger / in hitstun |

**The chase** (`string-chase-speed`, rules.lisp; `main-phase-step`, fighter.lisp): during the startup of a follow-up link
(one the latch started, `fighter-chained`), each frame he moves toward the defender at
`min(*chase-max*, 60 × (d − goal) / frames-to-hit)` m/s, where `goal = max(*lunge-stop*, reach − *chase-margin*)`, and
turns toward him at least `*chase-track*` deg/s. So he arrives `*chase-margin*` inside the link's reach exactly as its
hit window opens; a frame never covers more than the gap left (no passing through or overshooting him; the fighters'
push-apart holds too), and a move's own lunge (`:slide`) still applies when it is faster. Knobs (tuning.lisp):
`*chase-max*` **18 m/s** (the Kikon dash's speed), `*chase-margin*` **0.4 m**, `*chase-track*` **360 deg/s** (a K
link's own is 60). Link 1 never chases (it is not a follow-up).

### 2.3 Buffer and latch
- A J / K pressed any time from a link's frame 0 until its chain closes is **latched**, and the last press wins. It
  fires at chain open (on hit from `s + a`, on block or a carried whiff at `total − 3`) and is discarded when link 1
  whiffed (§2.2).
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
| J1 | 火閃 HISEN | `:ya-q1` | 9/3/12 | 38 | flinch | −2 | 20 | **0.96 m** 100° (was 2.4) | from the draw, a flat right-to-left cut, the haori trailing, the flame tongue hangs 2 drawings |
| J2 | 返し火 KAESHIBI | `:ya-q2` | 8/3/13 | 38 | flinch | −2 | 21 | **0.96 m** 100° (was 2.4) | the wrist turns over, a backhand along the same line; the flame reverses into a ring |
| J3 | 袖火 SODEBI | **new** `:ya-sleeve` | 9/3/18 | 45 | stagger | −4 | 26 | **0.88 m** 140° (was 2.2) | he whips the **empty left sleeve**, which catches fire, across the face: a one-armed silhouette, the sleeve a FIRE ribbon |
| K1 | 焔薙 HOMURA-NAGI | `:ya-f1` | 18/4/20 | 75 | stagger | −3 | 32 | **2.6 m** 150° (was 3.0) | a long anticipation, the blade drawn back past his hip, then a waist-high sweep that fans fire; +20 Inferno |
| K2 | 昇焔 SHŌEN | `:ya-f2` | 22/4/24 (8 → 14) | 80 | stagger | −3 | 36 | **2.3 m** 90° (was 2.6) | he sinks and rises with the cut, a flame column blooms; 4 f hold at the top; +20 Inferno |
| K3 | 焔爆 ENBAKU | `:ya-q3` | 22/5/34 (8 → 14) | 110 | crumple | −20 | 46 | **2.4 m** 120° (was 2.8) | the blade stabbed down at his feet, the flame bursts out in a dome, beard and sleeve blown back; 4 f hold; +20 Inferno |

### 3.2 Yamamoto: Bankai East (`:bankai-east`; West's J / K drop to these). New clips: **1**
Identity: thin ember lines, the sun's path. ×1.0 + pierce, taken ×1.5 (rework).

| Link | Name | Clip | S/A/R | Dmg | React | Blk | Whiff | Volume | Pose |
|---|---|---|---|---|---|---|---|---|---|
| J1 | 日差 HIZASHI | `:ya-q1` | 8/3/12 | 34 | flinch | −2 | 20 | line **1.24** (was 3.1) | a flat edge line, no fire; a white-hot scratch hangs 1 drawing |
| J2 | 残照 ZANSHŌ | `:ya-q2` | 7/3/13 | 38 | flinch | −2 | 21 | line **1.24** (was 3.1) | the return stroke; the two afterglows cross into an X (his scar) for 6 f |
| J3 | 穿光 SENKŌ | `:ya-e-thrust` | 8/3/18 | 42 | stagger | −4 | 26 | line **1.44** (was 3.6) | a short straight thrust, no lunge (KYOKKŌ is the lunge) |
| K1 | 陽炎 KAGERŌ | `:ya-f1` | 16/4/20 | 70 | stagger | −3 | 32 | line **3.4** (was 3.8) | a wide sweep; the air behind it shimmers (a heat-haze band on twos) |
| K2 | 日昇 NISSHŌ | `:ya-f2` | 19/4/24 (5 → 14) | 75 | stagger | −3 | 36 | line **3.4** h 1.3 (was 3.8) | a rising cut; the edge traces a half-disc, a rising sun, for 3 drawings |
| K3 | 落日 RAKUJITSU | **new** `:ya-e-drop` | 21/5/34 (7 → 14) | 105 | crumple | −20 | 46 | vertical line 0.3 → **3.2** (was 3.6) | the blade straight up, one-armed, held 3 f, falling in a vertical arc (the setting sun); ember sparks on the plaza |

### 3.3 Kenpachi: base (`:base`). New clips: **1**
Identity: no school, a street fighter with a sword who kicks.

| Link | Name | Clip | S/A/R | Dmg | React | Blk | Whiff | Volume | Pose |
|---|---|---|---|---|---|---|---|---|---|
| J1 | 荒斬 ARAGIRI | `:ke-q1` | 7/3/12 | 35 | flinch | −2 | 20 | **1.04 m** 100° (was 2.6), lunge 0.8 | a lazy one-handed slash thrown from the shoulder, grinning |
| J2 | 返斬 KAESHIGIRI | `:ke-q2` | 7/3/13 | 35 | flinch | −2 | 21 | **1.04 m** 100° (was 2.6) | the backhand back across, the haori flaring |
| J3 | 喧嘩蹴り KENKA-GERI | **new** `:ke-kick` | 8/3/18 | 42 | stagger | −4 | 26 | **0.88 m** 60° (was 2.2) | a flat front kick to the gut, the sword held out wide the other way |
| K1 | 大振り ŌBURI | `:ke-f1` | 16/4/20 | 70 | stagger | −3 | 32 | **2.8 m** 120° (was 3.0) | a huge two-handed wind-up over the right shoulder, the whole torso turning |
| K2 | 斬り上げ KIRIAGE | `:ke-f2` | 20/4/24 (6 → 14) | 75 | stagger | −3 | 36 | **2.5 m** 90° (was 2.6) | both hands, from the floor up; hold at the top, arms wide |
| K3 | ぶん回し BUNMAWASHI | `:ke-q3` | 20/5/34 (6 → 14) | 100 | crumple | −20 | 46 | **2.7 m** 360° (was 2.8) | the swing carries him into a full spin, the blade at arm's length; smear on the whole turn |

### 3.4 Kenpachi: Nozarashi cups
- **Cup 1 KATATE**: derived from base (+2 f, reach ×1.3), the same clips with the cleaver. New clips: **0**. `:enter`
  shifts with the startup, so S_eff stays 14: J1 9, J2 9, J3 10, K1 18, K2 22 (8), K3 22 (8).
- **Cup 2 RYOTE** (×1.15), two-handed kendo. New clips: **2**.

| Link | Name | Clip | S/A/R | Dmg | React | Blk | Whiff | Volume | Pose |
|---|---|---|---|---|---|---|---|---|---|
| J1 | 面 MEN | `:ke-r-q1` | 10/3/12 | 40 | flinch | −2 | 20 | line 0.3 → **1.56** (was 3.9) | jōdan, a straight overhead, the kiai |
| J2 | 小手 KOTE | **new** `:ke-r-kote` | 9/3/13 | 38 | flinch | −2 | 21 | **1.44 m** 60° (was 3.6) | a small wrist snap: the only small motion in the set |
| J3 | 袈裟 KESA | `:ke-r-q3` | 10/3/18 | 48 | stagger | −4 | 26 | **1.52 m** 140° (was 3.8) | a diagonal through the shoulder line, the follow-through low |
| K1 | 胴 DO | `:ke-r-f1` | 19/4/20 | 85 | stagger | −3 | 32 | **3.9 m** 160° (was 4.2) | the wide body cut |
| K2 | 諸手突き MOROTE-ZUKI | **new** `:ke-r-tsuki` | 21/4/24 (7 → 14) | 85 | stagger | −3 | 36 | line 0.3 → **4.0** (was 4.4) | both hands drive the cleaver straight out, the back foot sliding; hold 4 f fully extended |
| K3 | 兜割り KABUTO-WARI | `:ke-r-f2` | 21/5/34 (7 → 14) | 115 | crumple | −20 | 46 | line 0.3 → **3.9** (was 4.2) | the cleaver high, held, dropped; the victim crumples to his knees |

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
`duel -> RESULTS winner P2 konpaku 0-3 ticks 7123 secs 118.7` (after §11's chase: `winner P2 konpaku 0-1 ticks 7365 secs 122.8`).

## 15. Close in on the opener's hit, push out at the end (the user, 2026-10-02)

The user, in four messages:

> 請幫我做系統的修正， JK 普攻連段中：讓 J3 跟 K3 分別會將對手推出 J1 與 K1 的攻擊範圍，攻擊角色本身不會位移。
>
> *攻擊角色取消 J/K 的位移
>
> 只要在 J1 K1 擊中時會把距離拉近貼身位置，打完後就推開，沒擊中的話就不會靠近
>
> 如果卡到場邊會無法在推動受攻擊方，則會把攻擊者推開。 / 讓攻擊方衝過去

Asked which displacement, the user picked removing the chase. Asked when to push, the user picked "when the string
ends", over "on the hit".

**The rules:**

- **No chase for J / K links.** `MAIN-PHASE-STEP` gives a follow-up link of kind `:quick` / `:flash` no chase speed. §11's
  chase stays for the L link after a K. A move's own `:slide` lunge stays too, e.g. Rukia's and Kenpachi's J1. The gate
  is unchanged: after a contact every later link still comes out, it just no longer closes in.
- **The opener's hit closes in.** A string's opener is the kit's `:q` / `:f` command move, not a follow-up. When it
  HITS (`APPLY-HIT`, not a block or a whiff), the attacker slides to `*string-pull-to*` (0.7 m) from his victim over
  `*string-pull-frames*` (6). A blocked opener's later links may now fall short after the block pushback, which leaves
  a blocked string gaps and fewer guard crushes.
- **The ender's end pushes out** (`ENDER-PUSH`). The J / K ender (`:ender`: J3, K3) hit, and its move ends or is guard
  cancelled with no follow-up started. While its victim still reels, it pushes him to the attacker's J1 reach (after J3)
  or K1 reach (after K3), + `*ender-push*` (0.3 m), over 8 f. The O ender, L, SP2 and ORANGE off the ender start before
  that, so they still connect. Measured in CPU matches: J3 pushes about 0.8 m, K3 about 2.3 m.
- **The edge** (`PUSH-APART`, `RAY-ROOM` in rules.lisp). Whatever the arena's circle leaves no room for pushes the
  attacker back instead. In 40 masher matches, 60 of 773 pushes moved the attacker.

**Measured:**

- In four CPU matches, J2 hit 59 of 60 times, J3 44 of 47, K3 26 of 29.
- All 15 pairings K.O., medians 135.3–209.3 s.
- The never-awaken A/B is >= 22 on every row.
- The masher's wins: HARD 21 %, NORMAL 59 %; with AUTO GUARD ALWAYS 53 % / 90 %.
- G2: yy P1 3-0 162.4 s, yk P2 0-1 134.7 s, kk P2 0-7 112.8 s.

## 11. The string follow-up chase (the user's decision 2026-09-28)

**Superseded for J / K links on 2026-10-02 (§15).** Only the L link's chase remains.


> 只要普通攻擊擦到，攻擊方在接續的攻擊動畫中就會靠近對手以保證後續的攻擊動作都能被打出來（這邊只講動作，不代表打出來就會造成傷害，還是能被防禦住）

**Decision**: once any link of a J / K string has touched the defender (hit or block), every later link the attacker
presses comes out, and during its startup he closes in so its hit window reaches the defender. It is motion only: the
link can still be guarded, and Step / Hoho / down iframes still dodge it. A string whose first link never touches still
stops with the whiff recovery (§2.2 has the rule and the knobs).

**As built**: `chain-open-p` takes T for a follow-up link (`fighter-chained`: set when the latch starts a link, cleared by
every other `start-move`), so a link that whiffed after an earlier contact still opens at block timing; `string-chase-speed`
(rules.lisp) and `main-phase-step` (fighter.lisp) do the chase. Neither touches a move that isn't a follow-up link, so
link 1, specials, cancels and the O ender are unchanged. No frame data, reach or hit volume changed. Host tests
(`tests/duel-rules-test.lisp`): the carried gate at block timing, and the chase (arrives at the hit frame, clamped, never
past the goal, stops at `*lunge-stop*`, a simulated 14 f chase from 6 m ends inside the reach).

**The CPU** (ai.lisp checked): it presses the next link off its link's own contact (`string-reflex` on a hit, the block
pressure on a block), so it never presses after a whiffed follow-up link: a CPU choice, not the gate. `j-beats-k-p`
reads the attacker's K-link startup, which the chase doesn't change (it only moves him); nothing else read the old
per-link gate. No AI change was needed.

**Measured** (the seed gate, debug 2113, `--secs 1100`, 20 seeds × pairing, NORMAL; with the Bankai entry change of the
same day, DUEL_KEN_BANKAI.md): the chase alone (first run) YY 134.7 / YK 128.6 / KK 136.1 s; final YY **134.7 s**
(98.2–205.5), YK **137.1 s** (76.9–176.9, Yamamoto 10 / Kenpachi 10), KK **125.8 s** (99.6–183.9); 60 / 60 K.O. in each
run. Before: YY 131.8 / YK 138.4 / KK 131.5 s. Inside the window (125–210 s), so no retune; KK sits near the floor
(its Bankai now comes more often, DUEL_KEN_BANKAI.md), and `*chase-max*` / `*chase-margin*` are the first knobs if a later
change pushes it under. G2 (`tests/style-cvc-ref.txt`): every pairing changed: YY `winner P1 konpaku 2-0 ticks 9248
secs 154.1` (was `P2 0-4 ticks 6948 secs 115.8`), YK `winner P2 konpaku 0-1 ticks 7365 secs 122.8` (was `P2 0-3 ticks 7123
secs 118.7`), KK `winner P2 konpaku 0-4 ticks 8225 secs 137.1` (was `P2 0-5 ticks 5930 secs 98.8`).

## 12. L after a K link (the user's decision 2026-09-28)

> 請讓露琪亞的 L 能串連在 K 結束後搭成 combo（無論覺醒前後都是）

**Rule (generic, the kit key `:l-after-k`).** In a form with `:l-after-k`, an L pressed during a **K link** (K1, K2, K2s
or K3: `kit-k-link-p`, the `:f` command's move or an `:f` follow-up) is **latched** like a J / K link (§2.3: the last
press wins, so a later J / K replaces it and an L replaces a latched J / K; the press is consumed). It starts when **that K
link's own contact** opens the chain (`chain-open-p` with the link's contact: on hit from `s + a`, on block in the last
`*chain-lead*` frames); a whiffed K link drops it (the carried gate of §2.2 doesn't apply to L). It goes through L's own
checks and costs as a command (`try-command` with the link's move: cooldown, Reiatsu, a `:temp` form's cold, which a
chained L may **overdraw** while any is left, rules `cold-ok-p`, the combo band lock of DUEL_RUKIA.md §4.1–4.2; refused =
the latch is dropped, the K link recovers as usual) and runs as a follow-up (`fighter-chained`: the chase of §2.2). The
value is T (the form's own L) or a move name (a combo copy of it, e.g. a shorter startup): `kit-l-link`. A J link never
takes it; a form without the key keeps the old behaviour exactly (a `:cancel` L still cancels a landed link, off hit only).

**The J twin `:l-after-j`** (2026-09-29, Senjumaru's "J weaves, K releases"): the same latch after a **J link** (J1, J2,
J2s or J3: `kit-j-link-p`), the value a move of that form (her 一越 HITOKOSHI, a one-pass weave). The CPU reads `:ai
:l-after-j` for a J link as it reads `:l-after-k` for a K link. A refused L link (either key) now gets the `:refused` cue
and its press is eaten, as a refused neutral command always did; the kit's `:ok` hook gets the link's move as `combo`.

**On hit it combos**: from the K link's hit, `A(K) + hit frame(L) < hitstun(K)` (stagger 26 after K1 / K2, crumple 40
after K3), host-tested for every K link of every form that has the key. **On block** the L comes out at block timing and
can be guarded as usual (it is not a guard crush; its own guard value drains). It is not an ender: no O after it.

**AI**: `string-reflex` (the CPU's own link hit it) presses L with the kit's `:ai :l-after-k` chance, one roll on the
hit's first step, when L may start (`kit-command-ok-p`).

Rukia is the only form with the key (DUEL_RUKIA.md, "Playtest 2"). Yamamoto and Kenpachi are unchanged (the seed gate's
YY / YK / KK rows are identical).

**Measured** (2026-09-28): the probe `duel probe kl` (debug 2420+k, `tests/scripts/duel-rukia-kl.json`) shows each L
landing inside the K link's stun (stun frames left at the L's hit: after K1 5 / 11 / 9 / 13 in Rukia's Shikai / −18 /
−50 / −273, after K3 18 / 24 / 22 / 26) and the blocked cases guarded. The seed gate's YY / YK / KK rows are identical;
Rukia's rows and the awaken A/B are in DUEL_RUKIA.md ("Playtest 2: built").

## 13. Playtest: shorter J/K, J light-short-fast, K heavy-long-slow (the user, 2026-09-29)

> 請將所有角色的 J K 攻擊距離都縮短（千手丸的針長度也做對應的縮短），j 是輕短快的攻擊、k 是重長慢的攻擊。
>
> J 縮短 60%，K 依據 J 距離與角色特性而定。
>
> 如果太短也可以提高一點 J 的距離，依角色的動作與特色抓 4~6 成的距離，不用真的卡死長度。只是距離要記得跟動畫模組匹配。

**The rule.** J is the light, short, fast attack: every J link's reach is 0.4–0.6 × what it was, chosen per character, and
the art must match it (the visible strike within about 0.15 m of the volume's far edge). K is the heavy, long, slow one:
its reach follows J and the character, and stays clearly longer than J (every K is at least 0.5 m longer than any J at
the same link, host-tested). Startups are unchanged: J 7–10 f, K1 16–19 f, K2 / K3 S_eff 14 (the frame audit below).

"Reach" is the volume's far edge from the attacker's centre (an arc's r, a capsule's b + r); a hit lands when the
defender's centre is within reach + his hurt radius (0.34 Rukia … 0.45 Kenpachi), so a J of 0.96 m connects at about
1.3–1.4 m centre to centre: true close range.

**The factor per character (J) and the K beside it** (every form's derived reach follows: KATATE ×1.3, RYOTE ×1.4 of the
base moves it doesn't write, 片腕 ×0.7, East ×1.15, −50 °C ×1.1, zero ×1.35):

| Character | J factor | Why | K | Why |
|---|---|---|---|---|
| Yamamoto | **0.4** | an old man's economy: short cuts close to the body, the sleeve whip in his face | −10…−15 % | the fire carries the reach (the sweep, the column, the dome) |
| Kenpachi | **0.4** | a brawler's hacks and the kick, thrown up close | −4…−7 % (RYOTE −7…−9 %) | his long heavy swings stay long: the body of his game |
| Rukia | **0.6** | the dance's cuts at arm's length (at 0.4 her Shikai lost to everyone: the A/B below) | −10 % | the fencer's lunge, the ring and the ice keep their length |
| Ichigo | **0.5** (J1 / J2), **0.6** (J3, KESSA) | the Shikai's J1 / J2 are the short blade, one step in; the turn (J3) swings the cleaver held up, KESSA's slab has the length of a blade | −10 % | the cleaver / the slab at full length |
| Senjumaru | **0.6** | a tailor's reach: the needle two thirds of its length (1.8 → 1.2 m), the jabs at arm's length | −10 % | the pins, the thread and the cloth still fly out |

At 0.4 for everyone the gate (below) broke the window only where these two meet: II 283, SI 244, IR 237, SS 227 s (their CPUs press J up close and their J damage is the lightest in the game); at 0.6 II / SS / SI fell by 70 / 30 / 30 s (a J-reach-only trial). Rukia went to 0.6 too: at 0.4 her pairings were inside the window but her Shikai lost (RY 6, RK 5, SR 2 of 20) and the awaken A/B's "never" won only 11 / 17 / 16 of 60 against Yamamoto (the user's floor is 20). Yamamoto and Kenpachi stay at 0.4: their pairings sat inside the window.

**The reach, old → new** (m; J1 / J2 / J3, K1 / K2 / K3; a capsule's b):

| Form | J old | J new | K old | K new |
|---|---|---|---|---|
| Yamamoto Shikai (Hellfire the same) | 2.4 / 2.4 / 2.2 | **0.96 / 0.96 / 0.88** | 3.0 / 2.6 / 2.8 | **2.6 / 2.3 / 2.4** |
| Yamamoto East (West drops to it) | 3.1 / 3.1 / 3.6 | **1.24 / 1.24 / 1.44** | 3.8 / 3.8 / 3.6 | **3.4 / 3.4 / 3.2** |
| Kenpachi base | 2.6 / 2.6 / 2.2 | **1.04 / 1.04 / 0.88** | 3.0 / 2.6 / 2.8 | **2.8 / 2.5 / 2.7** |
| Kenpachi KATATE (×1.3) | 3.38 / 3.38 / 2.86 | **1.35 / 1.35 / 1.14** | 3.9 / 3.38 / 3.64 | **3.64 / 3.25 / 3.51** |
| Kenpachi RYOTE | 3.9 / 3.6 / 3.8 | **1.56 / 1.44 / 1.52** | 4.2 / 4.4 / 4.2 | **3.9 / 4.0 / 3.9** |
| Kenpachi NOMIHOSE (RYOTE's; K1 KUKAN-GIRI) | as RYOTE | as RYOTE | 4.2 / 4.4 / 4.2 | **3.9 / 4.0 / 3.9** |
| Kenpachi Bankai | 3.2 / 3.2 / 2.0 | **1.28 / 1.28 / 0.8** | 3.6 / 3.2 / 4.0 | **3.4 / 3.0 / 3.7** |
| Kenpachi 片腕 (×0.7; the kick as written) | 1.82 / 1.82 / 2.2 | **0.73 / 0.73 / 0.88** | 2.1 / 1.82 / 1.96 | **1.96 / 1.75 / 1.89** |
| Rukia Shikai | 2.4 / 2.2 / 2.6 | **1.44 / 1.32 / 1.56** | 3.2 / 2.8 / 3.0 | **2.8 / 2.5 / 2.7** |
| Rukia −18 °C (K1 TŌSHU, K3 HYŌKA) | as the Shikai | as the Shikai | 2.2 / 2.8 / 2.7 | **2.0 / 2.5 / 2.4** |
| Rukia −50 °C | 2.64 / 2.42 / 2.86 | **1.58 / 1.45 / 1.72** | 2.42 / 3.08 / 2.97 | **2.2 / 2.75 / 2.64** |
| Rukia −273 °C | 3.24 / 2.97 / 3.51 | **1.94 / 1.78 / 2.11** | 4.3 / 3.78 / 3.65 | **3.78 / 3.38 / 3.24** |
| Ichigo Shikai | 2.2 / 2.2 / 2.4 | **1.1 / 1.1 / 1.44** | 3.0 / 3.0 / 3.4 | **2.7 / 2.7 / 3.0** |
| Ichigo KESSA | 2.6 / 2.6 / 2.8 | **1.56 / 1.56 / 1.68** | 3.2 / 3.2 / 3.6 | **2.9 / 2.9 / 3.2** |
| Senjumaru Shikai | 2.4 / 2.4 / 2.4 | **1.44 / 1.44 / 1.44** | 3.2 / 2.8 / 2.8 | **2.9 / 2.5 / 2.5** |
| Senjumaru 辻 (K1 TANMONO, K3 MAKITORI) | as the Shikai | as the Shikai | 4.2 / 2.8 / 2.8 | **3.8 / 2.5 / 2.5** |

Out of scope and unchanged: L / SP / O / Kikon / Breaker moves (the Breaker changed for its own reason, §14), the chase
markers (`:sj-warui-kuse-k`, `:ru-tsukishiro-k`, the `-k` L copies: reach 9 / 8 m is where the chase stops, not a strike),
the melee / ranged splits of SPs (`:melee-range` 2.4 / 2.6 / 3.4 / 3.9 m: an SP's own blade, they were the J1 reaches of
their forms until now) and KESSA's clones' answers (`:ic-c-*`, the clones keep the long clips).

**The art** (`duel-rules-test` measures it: the rig's FK over the art files' own poses at the hit frames; see "The check"):
- **Senjumaru**: the needle 刺絡 1.8 → **1.2 m** (1.06 m at her scale; `:loop`'s thread starts at the new tip); the
  three J hit poses pulled in (the lunge 0.32 → 0.06 m, the needle arm's elbow bent 20–80°): the tips at 1.47 / 1.43 /
  1.46 m for 1.44. The K props shortened with their volumes (`*sj-strike-reach*`: pins 3.5 → 3.2, the loop 2.8 → 2.5,
  the stakes 2.8 → 2.5, the bolt 4.5 → 4.1, the wrap 2.8 → 2.5 m).
- **Yamamoto**: KAESHIBI's backhand ends with the elbow bent and the blade lowered (1.61 → 0.99 m); SODEBI's lunge
  0.28 → 0.06 m (the sleeve 1.10 → 0.91); HISEN was already at 0.87. East's SENKŌ shares KYOKKŌ's thrust clip: its lunge
  0.5 → 0.22 m (the tip 2.12 → 1.84 ahead for 1.74; KYOKKŌ's line still runs 4.6 m).
- **Kenpachi**: ARAGIRI and KAESHIGIRI thrown from where he stands (the 0.36–0.45 m lunges → 0.04) with the blade
  angled down: the katana's tip at 1.06 / 0.97 for 1.04, the cleaver's (KATATE) at 1.39 / 1.47 for 1.35. KENKA-GERI a
  chambered push kick (the foot 1.54 → 0.96). RYOTE's three J links end with the cleaver's point at the plaza in front
  of him (MEN's point 3.04 → 2.15 ahead for 2.06, KOTE's 2.81 → 1.45, KESA's 2.55 → 1.53): a 1.7 m cleaver can only be
  that close pointing down. The Bankai's GENKOTSU has its own close clip, `:ke-b-hook` (the fist 1.41 → 0.87 for 0.8);
  SP2's NAGURI-TOBASHI keeps `:ke-b-fist`.
- **Rukia**: HATSUSHIMO's lunge kept (0.32 m) with the elbow bent 10°, KAZAHANA's elbow 20° and its lunge 0.2 → 0.02 m,
  MAI-SODE's lunge 0.3 → 0.22 with the elbow bent 75°: 1.39 / 1.30 / 1.51 m for 1.44 / 1.32 / 1.56 (−50's rime blade 1.46 /
  1.38 for 1.58 / 1.45, its two-handed pirouette 1.62 for 1.72).
- **Ichigo**: the Shikai's J1 / J2 are the short blade held reversed along the forearm, so the fist is the strike: one
  step further in (the root 0.26 → 0.5 m; J2's arm brought forward) for 1.10 / 1.00 m at 1.1. SŌSEN-GIRI holds the cleaver
  up in the turn (the tip 2.53 → 1.48 for 1.44). KAESHI-KIBA (J2s) has its own clip, `:ic-cross-j`: the X closed in at his
  chest (2.56 → 1.10); K2s, SŌGA and the O keep `:ic-cross`. KESSA's J links: the elbow bent and the lunge gone (ITA-NAGI
  `:ic-k-jab` 2.25 → 1.62, KAESHI-ITA 2.50 → 1.62, ITA-SEN `:ic-k-wrap-j` 2.56 → 1.74, for 1.56 / 1.56 / 1.68); the clones
  keep the long `:ic-k-cut` / `:ic-k-wrap`.
- **The shared clips** (a J clip another move also plays): HISEN's `:ya-q1` (TENCHI's strike), MAI-SODE's `:ru-spin`
  (ENBU's strike) and SENJU's `:sj-spin` (her O's strike) are closer now; those strikes' volumes are the O's, so they
  under-reach on screen (the flash step and the O's effects carry them). SENKŌ's pull shortens KYOKKŌ's pose by 0.28 m.
- **K**: every K link is at or under its edge (none over by more than 0.15 m); most under-reach on the rig alone (the
  fire, the ice, the cloth and the smears carry them), as before the cut.

**The check** (`tests/duel-rules-test.lisp`, the generalization of DUEL_SENJUMARU.md's): every character's art file is
read (its poses, clips, body scale / hunch / proportions, weapons), and every J / K link reachable in every form (and the
Breaker's strike, §14) is posed at its hit frames: the weapon's tip, or the fist / foot / sleeve of a strike that isn't
the blade (`*strikers*`), or Senjumaru's K prop. J links and her props: within 0.15 m either way. K links, the Breaker and
the forms that play another form's clip at another reach or blade (East, KATATE, the Bankai, −273 °C: `*reach-one-sided*`):
never more than 0.15 m past the edge (they may fall short). **片腕 KATAUDE is the exception**: the base clips at ×0.7 with
the broken cleaver pass the edge by up to 0.36 m (J) and 0.58 m (K3's spin), as K3 did before the cut (0.51); a close
clip set for it is the fix if it shows. A deliberate over-reach (Senjumaru's J1 elbow back at 2°) fails it.

**Close range works** (`*lunge-stop*` 1.3 → **0.95 m**, tuning.lisp): a lunge (`:slide`) and the follow-up chase stop at
it, just outside the widest pair of hurt radii (0.9 m) and inside every J's reach + the thinnest hurt radius (the host
test checks both for every J link of every form: with 1.3 Yamamoto's J3 (0.88 + 0.34 = 1.22) and every 片腕 J would stop out
of reach). On hit a J link doesn't push him (flinch has no knockback), so J2 / J3 connect without a chase; on block the
0.6 m pushback is closed by the chase (not at −273 °C, which is rooted: its J2 still reaches after the push from where a
Shikai J1 lands, 1.78 + 0.45 ≥ 1.44 + 0.6, host-tested).

**What changed with it.**
- **J beats K** (the CPU's reflex, §4) now needs him inside J1's reach: from a K link's own range (2.3–4.0 m) a J can't
  reach, so K is the mid-range poke and J the close one, as asked. Blocked K strings keep their gaps (≥ 11 f), so a
  defender who is close still interrupts with J.
- **A blocked O strike (−14)**: it lands 1.6 m out and pushes 0.6 m, and a J1 can no longer reach from there (it could
  at 2.4 m): the punish now walks in or uses K1's reach (host test: K1 reaches 2.2 m).
- **The CPU tables** (every kit's `:ai`): the pressure range comes in to 1.0–2.4 / 2.6 m (RYOTE and the cups 1.2–3.2,
  片腕 0.9–1.8, Ichigo's Shikai 1.0–1.8, KESSA 1.0–2.0, Senjumaru 1.0–1.9), and the close band splits at J's reach +
  ~0.3–0.5 m: J links inside it, the K weight takes the J weight beyond (a J picked out of reach was a lost decision,
  `ai-attack`). KESSA's CPU attacks a little more (`:attack` 0.15, the gate below).
- **The frame audit** (J ≤ 8 f, K ≥ 14 f): K holds everywhere (K1 16–19, K2 / K3 enter at S_eff 14). J over 8 f, as
  designed and not retimed: Yamamoto's J1 / J3 9 (Hellfire too), KATATE's 9 / 9 / 10 (+2 derivation), RYOTE's
  10 / 9 / 10 (NOMIHOSE too), the Bankai's J3 9, KESSA's J3 9.

**The gate** (seeds 1–20, one run per pairing, debug 2125+k, `--fixed-dt 16.666667`; §13 and §14 together, the final
build; 300 / 300 K.O., every median in 125–210 s; YK, 121.1 s before and accepted by the user under the floor, is back
inside at 139.2 s):

| Pairing | Median (before) | Range | Wins P1 / P2 (before) |
|---|---|---|---|
| YY | **152.4** (134.7) | 116.2–188.8 | 9 / 11 (9 / 11) |
| YK | **139.2** (121.1) | 105.9–208.7 | Yamamoto 14 / 6 (13 / 7) |
| KK | **137.4** (127.7) | 97.1–167.2 | 7 / 13 (9 / 11) |
| RY | **144.8** (133.7) | 101.8–160.6 | Rukia 8 / 12 (12 / 8) |
| RK | **141.6** (130.8) | 95.9–219.0 | Rukia 14 / 6 (13 / 7) |
| RR | **182.2** (170.1) | 154.3–233.9 | 10 / 10 (12 / 8) |
| IY | **147.4** (148.0) | 106.3–182.7 | Ichigo 10 / 10 (7 / 13) |
| IK | **152.5** (147.1) | 105.7–208.5 | Ichigo 16 / 4 (9 / 11) |
| IR | **190.0** (179.3) | 147.6–242.6 | Ichigo 6 / 14 (6 / 14) |
| II | **201.2** (194.1) | 131.9–257.1 | 9 / 11 (12 / 8) |
| SY | **151.0** (136.8) | 128.3–186.7 | Senjumaru 4 / 16 (12 / 8) |
| SK | **155.8** (132.9) | 111.1–177.8 | Senjumaru 12 / 8 (6 / 14) |
| SR | **199.7** (176.0) | 119.4–229.9 | Senjumaru 12 / 8 (12 / 8) |
| SS | **192.3** (190.5) | 107.1–237.3 | 8 / 12 (8 / 12) |
| SI | **197.4** (180.5) | 110.0–263.4 | Senjumaru 13 / 7 (15 / 5) |

Almost every pairing is longer: close-range J connects less often than the 2.4 m J did. The runs that led here: the
data alone (the old CPU tables, YY / YK / KK) 148.7 / 155.4 / 150.7 s; the CPU tables of §13 brought those three to
152.4 / 139.2 / 137.4 but left II 283, SI 244, IR 237, SS 227 s; Ichigo's and Senjumaru's J at 0.6 (a reach-only trial)
cut II / SS / SI to 209 / 199 / 211 s; their pressure ranges pulled in (the Shikai 1.0–1.8, KESSA 1.0–2.0, Senjumaru
1.0–1.9) and KESSA's CPU `:attack` +0.15 (its neutral attack chance) brought II / SI / IR to 197 / 193 / 192 s (the final
build then set the Shikai's J1 / J2 at 0.5, J3 0.6). At J 0.4 Rukia's pairings were inside the window (RY 159.3, RK
169.4, RR 193.7, IR 200.9, SR 182.2 s) but she lost (RY 6, RK 5, SR 2 of 20) and failed the awaken A/B, so her J went to
0.6 (the table above: RY / RK / RR / IR / SR re-run on it; the other ten don't involve her). Knobs if a later change needs
them: the J factors inside 0.4–0.6, the `:pressure` ranges, KESSA's `:attack`, `*lunge-stop*`.

**The awaken A/B** (DUEL_RUKIA.md "The awaken A/B across seed streams": P1 "never awaken", debug 39020, against the
opponent on its own rule; three 60-seed streams, seeds 1–60 / 61–120 / 121–180 through 30000+k; P1's wins of 60; the
user's floor is 20 on every stream):

| Pairing | 1–60 | 61–120 | 121–180 |
|---|---|---|---|
| RY | 35 | 35 | 34 |
| RK | 37 | 37 | 41 |
| RR | 31 | 32 | 38 |
| IY | 30 | 34 | 34 |
| IK | 25 | 23 | 27 |
| IR | 25 | 27 | 26 |
| II | 30 | 32 | 27 |
| SY | 29 | 27 | 34 |
| SK | 30 | 27 | 27 |
| SR | 30 | 40 | 30 |
| SS | 31 | 32 | 32 |
| SI | 32 | — | — |

Every run clears the floor (the lowest: IK 23). SI's second and third streams were not run: SI's matches are the longest
in the game and the shared machine was loaded (seeds 1–60 took ~40 min); its last A/B (DUEL_SENJUMARU.md) read 32 / 30 /
33. At Rukia's J 0.4 the first A/B failed: RY 11 / 17 / 16, RK 22 / 21 / 11 (hence her 0.6). Yamamoto and Kenpachi have
no A/B procedure of their own.

## 14. The grab needs to be closer: 防 > J > I > 防 (the user, 2026-09-29)

> 抓技 I 的範圍也太大了，需要更接近才觸發判定
>
> 抓技範圍必須比輕攻擊更短，這樣才能達到 防 > J > I > 防 這樣的循環克制

**The rule.** A loop: guard beats J (it blocks it), J beats I (the grab), I beats guard (the Guard Break). J beats I
because the grab reaches less far than every J1 and has no armour: its aura, dash and strike startup are `:breaker`
(`defender-state`), so any hit counters it (×1.25, +10 f).

**The numbers** (tuning.lisp, shared, no per-character change): `*breaker-trigger*` 2.2 → **0.95 m** (the dash turns into
the strike this close, centre to centre), `*breaker-reach*` 2.6 → **0.7 m**.
- 0.7 m is under every form's J1 (the shortest: 片腕's 0.73, then Yamamoto's 0.96; the derived Breakers
  scale with their forms: KATATE 0.91 < 1.35, RYOTE / NOMIHOSE / the Bankai 0.98 < 1.28–1.56, East 0.81 < 1.24, −50 °C 0.77 < 1.58).
- 0.95 m is just outside the widest pair of hurt radii (two Kenpachis, 0.45 + 0.45 = 0.9: the push-apart), so every pair
  can reach it; the dash (9–10 m/s, 0.15–0.17 m a frame) gets there before it is pushed apart.
- 0.7 m + the thinnest hurt radius (0.34, Rukia) = 1.04 > 0.95 m, so a triggered strike connects (it hits at
  centre distance ≤ reach + his hurt radius, `collect-melee`).

**The frame math of J beats I** (host-tested per form, `duel-rules-test`): the dash at its fastest, v = 10 m/s = 0.167 m
a frame. J1 (startup S, active A, reach R) pressed while the dash is d away connects when its last active frame meets
the dash inside R + 0.34: d ≤ R + 0.34 + v (S + A − 1) — and when its first active frame comes before the Breaker's
strike does (the dash stops at 0.95, then the strike's 8 f startup): d ≥ 0.95 + v max(0, S − 8). Yamamoto's J1 (S 9,
0.96 m): from **1.1 to 3.1 m**; Kenpachi's (S 7, 1.04 m): from 0.95 m (and even in the strike's first frame) to 2.9 m;
RYOTE's MEN (S 10, 1.56 m): 1.3–3.9 m. Every form's window is open.

**The art.** The strike (the Breaker's clip 2) at the new distance (the same FK check, one-sided): IKKOTSU's punch
(Yamamoto) thrown from where he stands (the lunge 0.4 → 0 m: the fist 1.13 → 0.77 for 0.7), SAIDAN's shears (Senjumaru)
0.3 → 0.14 m (0.86 → 0.72); Kenpachi's shoulder (0.65), HAINAWA's fingers (0.82) and MINEUCHI's flat (0.66) were
already there.

**The CPU.** Its Breaker bands stay up to ~3 m (the dash closes the gap: a 12 f tap still runs ~1.9 m). Against an
incoming Breaker (`ai-reflex`, the anti-breaker branch) it now waits for the dash to come within J1's reach +
`*ai-anti-breaker-j*` (1.4 m) and presses J1 (J beats I); the Hoho through the dash stays (its roll first); against a
Kikon rush nothing changed. `*ai-guard-break-range*` (3 m) is unchanged: the dash closes that too.
