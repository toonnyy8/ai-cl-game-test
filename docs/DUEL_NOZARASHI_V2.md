# SOUL DUEL: Nozarashi redesign — "NOME" (呑め, Drink), the three-cup ladder — v2

> Status: **decided, not yet built**. Working notes (critiques, v1 drafts, research) were kept outside the repo; the debate outcome is recorded below.
> **User override (2026-09-26): Kenpachi wears NO eyepatch in any form.** Every eyepatch mention below is superseded by the last section.

## 給使用者的摘要（繁體中文）

- **核心「呑め（喝吧）」**：野晒是一把會喝血的刀。**NOME 量表**（0–100）只有三個來源：造成傷害、受到傷害、用「喝」或架式吃下的傷害（最多）。量表決定他「認真到第幾杯」。只有在他沒出招的時候才會換杯：
  - **一杯・片手（KATATE）**：開野晒時量表從 10 開始。單手持刀，招式等於現在的野晒但快 1 f，傷害 ×1.0，能斬飛道具，量表不會掉。**這時的 Kikon 只拿 2 個魂魄**，因為他還沒玩夠。
  - **二杯・兩手（RYOTE，≥ 40）**：雙手劍道。J/K 換成自己的一套（面、袈裟、胴、兜割），攻擊直而長。傷害 ×1.15。**K、架式、SP** 被擋或打在霸體上時，扣對手防禦量表 ×1.5。量表每秒掉 3，跌破 25 退回一杯。Kikon 拿 3。
  - **三杯・飲み干せ（NOMIHOSE，= 100）**：黃色靈壓柱沖起，畫面黑白翻轉 12 f、只留黃色。K 是「空間斬」：斬痕留在空中，20 f 後再斬一次（被擋 +8，打中可接連段）。傷害 ×1.2，擋下的攻擊也會削對手 20 % 的血。**他不再防禦**：U 變成「喝」，吃下攻擊只受一半傷害（真的會扣血，也可能被打到 Soul Break），另一半被刀喝進量表。每次「喝」都要付防禦量表，歸零就沒得喝。量表每秒固定掉 10，跌破 50 退回二杯。**Kikon 拿 4**，含 Soul Break 在內每次最多 4。
- **高風險高報酬**：升杯要流自己的血，越強就越接近紅血。三杯通常只撐 5–10 秒，對手可以拉開距離讓刀乾掉，或逼他「喝」到防禦量表見底。
- **Shift+K 劈開隕石**：三杯時會「一口喝乾」：一出招就付掉整杯、立刻退回一杯，所以 O 取消接 Kikon 也只拿 2。這一刀 12 m、390 傷害，**6 m 內破防**，更遠的部分可以擋。
- **享受戰鬥**：越晚收尾，Kikon 越值錢（2 → 3 → 4），而且 Kikon 的價值在衝出去那一刻就定了。
- **U 的兩種例外，規則一致**：山本西（按住 U = 霸體，可以邊移動邊攻擊，吃滿傷害並燙傷對手）和更木三杯（按住 U = 喝，站定，只受一半傷害並累積量表）都是「U 不再擋，改用防禦量表來付」，歸零就要等量表回滿。面板上會標「U: ARMOUR」或「U: DRINK」。
- **配合同批改動**：
  - 野晒不再無視霸體，不然山本西按住 U 的霸體對他完全沒用。改為重招打在霸體上多扣 ×1.5 防禦量表。
  - 跑步時身體一律面向對手，三杯共用同一組跑步動作，杯數靠靈壓大小、單手或雙手握刀和介面辨識（任何形態都沒有眼罩）。
- **替代方案（各一行）**：
  - B「斬る」：每刀留下裂縫，L 一次引爆。偏設置型，不像他。
  - C「勢い」：連續揮刀累積動量，揮空就卡進地面。沒有狀態起伏，影格數據也會一直變。
  - D「もっと！」：放紅血的對手一馬換取變強，容易被濫用；已改成「Kikon 價值隨杯數增加」放進主案。
  - E「單手／雙手兩架式（L 切換）」：跟山本的東／西重複，已併入一杯、二杯。

---

Conventions as DUEL_DESIGN §0 and design-bankai-kikon v3. A string link combos when
`(S_a + A_a + S_b − enter_b) − (hit_a + 1 + stun_a) < 0`. The attacker acts at TOTAL + 1, the victim at
hit + stun + 1. [V] = canon verified in research.md §C; [G] = our interpretation. v2 answers
critique-nozarashi.md point by point (revision log at the end) and fits the same batch's two user
decisions: fighters face the opponent while moving, and West's armour becomes "hold U".

## 0. The bar to clear

Nozarashi today is ×1.15 damage, reach ×1.4, +3 f, projectile cut, ignore-armour, a new SP1 and a new O.
Every button does what it did before, only bigger and slower, so there is no new decision.

Yamamoto's Bankai clears the bar with five things:
1. states you can read at a glance;
2. its own J / K per state;
3. an existing gauge turned into the risk engine;
4. extreme numbers;
5. a role for each button.

Nozarashi must hit all five without copying the East / West switch, and the ideas must come from
Kenpachi himself:

| Canon / personality | Source |
|---|---|
| The release command is 「呑め」 "Drink"; the cleaver drinking **blood** is our reading | [V] / [G] |
| He split Gremmy's meteor **with the eyepatch still on**, then took it off and cut through space | [V] |
| The eyepatch eats his reiatsu so fights last: a self-imposed limiter | [V] |
| One-handed on purpose; two-handed kendō is his "serious" mode | [V] / [G] |
| Takes hits smiling; RoS "stronger the more he is cornered"; 「斬ってみろよ」 | [V] |
| Would rather the fight last than win it | [V] |

Each cup takes one limiter off: **one hand → two hands → the eyepatch.** Blood picks the cup, not a
button, and the cup's value is in *properties* (no guard, drink, the rift, the Kikon value), not in a big
multiplier. Hellfire (a timed ×1.30) and East (×1.20) own the multipliers.

---

## 1. Three concepts

### Concept A — NOME: the three-cup ladder (RECOMMENDED, §2)

- **Loop**: blood (dealt, taken and, most of all, drunk) fills NOME. At 40 he grips two-handed (T2); at
  100 the eyepatch comes off (T3). T2 and T3 drain. Shift+K at T3 cashes the whole cup into one cut.
- **Risk / reward**: he rises by bleeding and so climbs toward red. At T3 he has **no guard**: U = DRINK
  (half the damage, paid from the guard gauge) and a flat 10/s drain. The payoff is the rift, chip, and a
  **4-Konpaku Kikon**. A Kikon at T1 is worth only 2.
- **Gauges**: the guard gauge pays for every drink. His heavy cuts (K / Sig / SP) drain the opponent's
  guard or armour ×1.5 at T2+. The Kikon count depends on the cup and is fixed at rush start. Reiatsu,
  flash-step, Fighting Spirit and Burst are unchanged.
- **Buttons**: J / K are a set per cup. U is Guard at T1 / T2 and DRINK at T3. L is the stance at every
  cup (the deliberate "drink up"). Shift+K is Split the Meteor, and the cash-out at T3. Shift+L, I and O
  are the same at every cup.
- **Look**:
  - T1: one hand, the eyepatch on, the base aura.
  - T2: jōdan two-handed idle, the taller aura.
  - T3: the eyepatch torn off, a 12 f manga-page beat on entry, the pillar aura, white rifts in the air.
- **Canon fit**: very high.
- **Cost**: about Bankai v3's size. Three kit forms, one generic meter ladder, DRINK as a guard passive,
  one hazard, 6 clips, 4 sounds.

### Concept B — KIRU: nothing he can't cut

- **Loop**: every J / K leaves its cut hanging (up to 3 rifts); L detonates all of them (guard value ×2).
  Rifts cut projectiles that cross them.
- **Risk / reward**: each rift costs 20 Reiatsu, and L whiffs with 30 f of recovery when no rift is out.
- **Buttons**: J / K plant rifts, L detonates, Shift+K is a 12 m rift.
- **Canon fit**: his power fits (the meteor, cutting space); his **personality doesn't**: Kenpachi never
  sets traps.
- **Cost**: medium, and the AI needs rift geometry.

### Concept C — ISSHIN: momentum

- **Loop**: each cleave that connects or is blocked within 12 f of the previous recovery adds a stack
  (0–4). Each stack gives −2 f startup, +8 % damage and +0.3 m reach; at 3+ stacks, 1 hit of armour.
  L = the full swing, which spends the stacks.
- **Risk**: a whiff at 3+ stacks sticks him 24 f, and every hit on him is then a counter.
- **Weakness**: frame data that changes at runtime breaks "table = code" and is hard to learn. There
  are no states to read.
- **Cost**: low–medium, but it touches `start-move` and the frame tests.

Folded into A:
- **D "MOTTO!"** (spare a red opponent to power up) survives as "a later Kikon is worth more" (2 / 3 /
  4).
- **E** (one-hand / two-hand stances on L) survives as rungs T1 / T2, not as a toggle.

---

## 2. NOME, in full (v2)

### 2.1 State rules at a glance

| | **T1 KATATE** 片手 | **T2 RYOTE** 両手 | **T3 NOMIHOSE** 飲み干せ |
|---|---|---|---|
| Kit form | `:nozarashi` (inherits `:base`) | `:ryote` (inherits T1) | `:nomihose` (inherits T2, **no derivation**) |
| Enter / leave | awakening (NOME **10**) / NOME < 25 from T2 | NOME ≥ 40 / < 25 | NOME = 100 / < 50 |
| Rung changes | **only when he is free**: idle, walk, guard, run (§2.2); the T3 cash-out is the one forced change (§2.6) | | |
| Drain | 0 | 3/s after 60 f without a gain | **10/s, always** (no delay) |
| Dealt | ×1.00 | ×1.15 | **×1.20** |
| J / K | base moves derived (+2 f, reach ×1.3) | own kendō set | T2's J, own K (the space cut) |
| U | Guard | Guard | **DRINK** (§2.4) |
| Traits | projectile cut | + **the cut**: his Flash / Sig / SP hits that are blocked or armoured drain ×1.5 of their guard value | + DRINK, blade chip 20 %, the rift |
| Shift+K | Split the Meteor | Split the Meteor | **NOMIHOSE**: the cash-out (§2.6) |
| Kikon (O) | **2** | 3 | **4**; the count is read at rush start and each event is capped at 4 (§2.7) |
| Look | one hand, eyepatch on, base aura | jōdan idle, the awakened aura | eyepatch off (sticky), pillar aura; no persistent grade |

- At every cup: L (the stance, derived), Shift+K / O as listed, Shift+L (the charge into the flurry),
  and I (Breaker).
- Walk 4.4 m/s, run 10 m/s. The run uses the new faces-the-opponent clip set (forward run / side slide /
  back-skate), **shared by every cup**: the cleaver is carried on the shoulder while running, and the cup
  reads from the aura and the eyepatch.
- Kept: Cornered (+5 % per Konpaku lost, max +25 %), +10 Reiatsu per reset, the awakening's 150 heal.
- **Removed: `:ignore-armor`.** With West's new hold-U armour (same batch), ignore-armour would make
  West's U worthless against Nozarashi. The cut (×1.5 guard drain on armour too) replaces it: his heavy
  cuts burn West out faster instead of passing through.

### 2.2 The NOME gauge

It is the kit meter (`gauges-meter`, the slot Yamamoto's Inferno uses).

| Rule | Value (knob) |
|---|---|
| Size / start | 100 (`*nome-max*`); **10** on awakening (`*nome-awaken*`); kept through Kikon resets |
| Sources (three only) | **taken** +0.12 per point he loses (`*nome-taken*`, including the half of a drink he takes); **drunk** +0.30 per point (`*nome-drunk*`: the half a T3 DRINK swallows, and all the L stance absorbs at any cup); **dealt** +0.08 per point he deals (`*nome-dealt*`) |
| Not sources | Konpaku lost (Cornered already pays for it), blocked hits, the opponent's good plays. "OMOSHIREE!" stays as a **callout only** (0 meter) on the opponent's counter-hit, perfect Hoho, parry or Burst against him |
| Drain | T1 0; T2 3/s once 60 f pass without a gain (`*nome-delay*`); **T3 10/s every frame** (`*nome-drain-t3*`) |
| Ladder | up at 40 / 100, down below 25 / 50 (`*nome-ladder*`), multi-step (0 at T3 → T1). **Evaluated only when he is free** (`free-p`: idle, walk, guard, run). A rung crossed during a move applies on the first free frame, so `kit-next` never changes kits under a string |
| HUD | a yellow bar in the meter slot; bright marks at 40 and 100, **dim floor ticks at 25 and 50**; the bar **pulses** within 10 above the current floor; three cup pips inside the bar frame; the panel shows `KENPACHI KATATE / RYOTE / NOMIHOSE` and `U: DRINK` at T3 |

**Pace.** From 10, T2 needs +30: about 250 taken, 375 dealt or 100 absorbed by the stance (one or two
real exchanges), so T1 is a real phase. T3 with no gain lasts 50 / 10 = **5 s**.

A drunk point pays 0.21 (half × 0.12 + half × 0.30). A drunk East string (152) therefore adds +32 =
3.2 s and costs 28 guard. After about 3.5 drunk strings he is crushed and guardless for 8.1 s, drinking
nothing, while the drain keeps running: **a T3 lasts ~5–10 s even in a bloody fight** (logged; target
≤ 10 s mean).

### 2.3 Move tables

**T1 KATATE** (`:startup-add 2 :reach-mult 1.3`, ×1.0; lists `:sp1 :ke-meteor :kikon :ke-kikon-n` as its
own, as today):

| Input | Move | S / A / R | Dmg | Block | Reach | Guard | Notes |
|---|---|---|---|---|---|---|---|
| J | Q1 (derived) | 9/3/12 | 35 | −2 | 3.38, 100° | 8 | lunge 0.8 |
| J J | Q2 (derived) | 9/3/13 | 35 | −2 | 3.38 | 8 | Q1→Q2 link −7 |
| J J J | Q3 (derived) | 13/4/22 | 55 | −12 | 3.38, 360° | 12 | knockback 3 m; Q2→Q3 −3 |
| K | F1 (derived) | 18/4/20 | 70 | −4 | 3.90, 120° | 14 | stagger |
| K K / J J K | F2 / F2q (derived) | 22/5/28 (branch enters f8) | 90 | −14 | 3.38 | 18 | launch; **F1→F2 −1** (today's 0-gap fixed), Q2→F2q −2 |
| L | KITTE MIRO YO (derived) | in 6, hold ≤ 60, cut 10/4/24 | 100 + stored | −14 | 3.64 | 22 | absorbed damage → NOME ×0.30 |
| Shift+K | Split the Meteor `:ke-meteor` | 26/4/30 | 240 | −16 | 12 m line | 22 | 1 bar |
| Shift+L | charge → flurry (derived) | 16/26/24; flurry S12 | 25 × 5 + 60 | −16 | | 22 | 2 bars |
| I | Breaker (derived) | strike 10/4/18 | 150 | GB | 2.2 trigger | −35 | |
| O | LEAP CLEAVE `:ke-kikon-n` | as built | 70 | −14 | 10.6 m | 20 | cooldown 90; **Kikon 2** |

**T2 RYOTE** (`:startup-add 3 :reach-mult 1.4` for the base moves it doesn't list, ×1.15). Passives
`(:projectile-cut :cut)`.
- It **lists `:sp1 :ke-meteor` and `:kikon :ke-kikon-n` as its own**. Otherwise it would re-derive
  T1's own moves from their written spec: a 29 f, 16.8 m meteor, and so on. This is the same trap as
  critique 2.1.
- Guard values are shown as written → after the cut.

| Input | Move | S / A / R | Dmg (×1.15) | Block | Volume | Guard | Notes |
|---|---|---|---|---|---|---|---|
| J | **R-Q1 MEN** `:ke-r-q1` | 10/3/12 | 40 (46) | −2 | `:cap 0.3→3.9 h1.2 r0.5` | 8 | straight overhead; narrow and long |
| J J | Q2 (derived) | 10/3/13 | 35 (40) | −2 | 3.64, 100° | 8 | R-Q1→Q2 −6 |
| J J J | **R-Q3 KESA** `:ke-r-q3` | 14/4/22 | 70 (81) | −12 | `:arc 3.8 140°` | 12 | knockback 3 m; Q2→R-Q3 −2 |
| K | **R-F1 DO** `:ke-r-f1` | 19/4/20 | 85 (98) | −4 | `:arc 4.2 160°` | 14 → **21** | stagger |
| K K / J J K | **R-F2 KABUTO-WARI** `:ke-r-f2` / `:ke-r-f2q` | 21/5/28 (branch enters f7) | 110 (127) | −14 | `:cap 0.3→4.2 r0.55` | 18 → **27** | launch; R-F1→R-F2 −2, Q2→R-F2q −2 |
| L | stance (derived) | in 6, cut 11/4/24 | 100 + stored | −14 | 3.92 | 22 → **33** | → NOME |
| Shift+K | Split the Meteor (as written) | 26/4/30 | 240 (276) | −16 | 12 m | 22 → **33** | 1 bar |
| Shift+L | charge / flurry (derived) | 17/26/24 | | −16 | | 22 → **33** | 2 bars |
| I / O | Breaker (derived 11/4/18) / LEAP (as written) | | | | | | **Kikon 3** |

A blocked J string R-Q1 Q2 R-Q3 = **28**, as the base string (the crush comes on the 4th). K K blocked =
**48**: the heavy cuts are what cut guard.

**T3 NOMIHOSE** (inherits T2, `:startup-add 0 :reach-mult 1.0`, so every inherited move is **T2's
version**, via the register-kit fix §2.8). It lists only `:f :ke-n-f1` and `:sp1 :ke-meteor-n`, plus the
string `(:ke-n-f1 :f :ke-r-f2)`. ×1.20; passives `(:projectile-cut :cut :drink)`; `:blade-chip 0.2`.

| Input | Move | S / A / R | Dmg (×1.2) | Block | Volume | Guard | Notes |
|---|---|---|---|---|---|---|---|
| J / J J / J J J | R-Q1 / Q2 / R-Q3 (T2's) | 10/3/12, 10/3/13, 14/4/22 | 48 / 42 / 84 | −2 / −2 / −12 | as T2 | 8 / 8 / 12 | chip 20 % on block |
| K | **N-F1 KUKAN-GIRI** `:ke-n-f1` | 20/4/22 | 90 (108) | −4 | `:arc 4.2 150°` | 14 → 21 | stagger; opens the **rift** at f20 (§2.5): it cuts at **f40**, 50 (60), stagger, knockback 1 m, guard **12** |
| K K / J J K | R-F2 / R-F2q (T2's) | 21/5/28 | 110 (132) | −14 | | 27 | N-F1→R-F2 −2; N-F1 → rift → R-F2 = **300** |
| U | **DRINK** | §2.4 | | | front 200° | pays the guard value | no guard |
| L / Shift+L / I / O | T2's | | | | | | **Kikon 4** |
| Shift+K | **NOMIHOSE: SPLIT THE METEOR** `:ke-meteor-n` | 26/4/30 | **390** (resolves at T1's ×1.0) | −16 | `:cap 0.3→6.0` **breaks guard** + `:cap 6.0→12.0` blockable | Guard Break (−35) / 22 | 1 bar; **the whole cup is paid at f0** (§2.6) |

### 2.4 DRINK (U at T3): a guard passive, not a new state

This implements critique 4.1. DRINK **is a guard**: the same `:guard` defender state, arc, raise time and
gauge check. All of these therefore come for free with no change to `resolve-contact` / `contact-of`:
- a Breaker or a `:guard-crush` hit → Guard Break;
- unguardable (the bind, the red follow-up) goes through;
- from behind = a hit;
- the Kikon rush strike, drunk = guarded (nothing follows);
- to the attacker, a drunk hit is a block (no string on hit timing, no cancel);
- blockstun counts as guard.

The passive `:drink` only changes the **`:blocked` branch** of `apply-hit`:

| On a blocked hit, if the defender has `:drink` | Value |
|---|---|
| Damage | `drink-split`: he takes the half rounded up **through `deal-damage`** (real damage: it can Soul Break him; test), and the cleaver drinks the other half (+0.30 each; the taken half gives +0.12 through the normal taken gain) |
| Chip | none on top (the half is the chip), so T3's own chip rule doesn't double-count |
| Guard gauge | the hit's guard value, as a block. At 0: Guard Crush (40 f) and guardless (no drink until the gauge is full, 60 f + 7.1 s) |
| Blockstun | melee: the block formula with the attacker's advantage **−4** (`drink-adv`): Q1 −2 → −6, enders −12 → −16. Hazards: the usual 14 f |
| Attacker | East's recoil applies (same branch), as does everything else a block does |

A drunk −2 hit leaves a gap to the next string hit of S(next) + 2 (Yamamoto's Q2: 10 f; Kenpachi's: 9 f).
His 10 f R-Q1 at best trades, so a drunk string is not a free interrupt. Every ender is punishable.

**The two U-overrides read as one family** (this batch also turns West's U into hold-U armour):

| | Bankai West: **hold U = ARMOUR** | Nozarashi T3: **hold U = DRINK** |
|---|---|---|
| Blocks? | no | no |
| While held | moves and attacks | **plants his feet** (a guard) |
| A hit taken | full damage, no reaction, **scorches** the attacker | **half** damage, a short blockstun (−4 f), **fills NOME** |
| Paid from | the guard gauge (the hit's guard value) | the guard gauge (the hit's guard value) |
| At 0 | burnout (all West traits off) until full | guardless: no drink until full |
| Breaker | goes through (hold U is no guard) | Guard Break (it *is* a guard) |
| Panel | `U: ARMOUR` | `U: DRINK` |

**The rule a player learns**: "in West and in cup 3, U doesn't guard: it takes the hit, and the guard
gauge pays; empty = nothing until it is full." West keeps walking; Kenpachi stands and drinks. The panel
tag, the U prompt and a distinct absorb look carry the difference: West's ember star plus the
attacker's arm smoking, against yellow flecks sucked into the cleaver.

**YK / KK interplay:**
- **Kenpachi T2+ vs West's hold-U**: the cut drains ×1.5 per heavy hit on West's armour, so West burns
  out faster. His J hits pay the normal value, and the scorch still burns him 15 per armoured hit. No
  ignore-armour.
- **West's armoured attacks into a T3 drink**: West's hit is blocked-and-drunk (Kenpachi +NOME); a
  Kenpachi hit on West's armour scorches Kenpachi. Both sides pay from their own guard gauges: a race.
- **East vs drink**: East's recoil on every drunk hit; KYOKUJITSUJIN's blade breaks the drink.
- **KK, T3 vs T3**: both drink. The 10/s drain with no delay and the guard gauge still end both T3s;
  logged.

### 2.5 The rift (N-F1, T3)

- **f20**: a hazard `:rift` (a white lens slit with a yellow rim) along the chord the blade crossed,
  `:cap 1.0→4.4 h 1.4 r 0.5` in his frame at f20, fixed in the world. `:delay 20` (the bind's field),
  then a 2 f window.
- **It closes** (it is removed) if Kenpachi is **hit** before it cuts: an owner-hit check in
  hazards.lisp (a parried blade: West's 6 f counter hits him first, so the rift is gone). It is also
  removed at every reset.
- **On block**: N-F1's blockstun runs until f42 (he may act at f43). The rift cuts at **f40**, inside
  it, so it is **blocked automatically** (no escape needed or possible): hazard blockstun 14 → he acts at
  f55. Kenpachi acts at f47: **+8**, guard **12**, and chip 20 %. There is no frame trap: his R-Q1 from
  f47 lands at f57, 2 f after the defender is free, so a mashed Q1 loses (7–9 f) and a Step or Hoho
  escapes.
- **On hit**: N-F1 staggers until f47; the rift (hit 2) re-staggers until f67. With K K, R-F2 (chain
  open f24) hits at f45: **108 + 60 + 132 = 300**. A Burst is legal after the rift (hit 2).
- **On whiff** (out of the arc): a static slit that cuts 20 f later. Walking in gets you cut. A Hoho
  started within 8 f of the cut, touching it, is a **perfect Hoho** (the existing `hazard-threat-p`): the
  intended counter, and the reward for reading it.

### 2.6 Split the Meteor and the cash-out

- **T1 / T2**: the built move (T2: ×1.15 and the cut).
- **T3 NOMIHOSE** (`:ke-meteor-n`), the Gremmy moment.
  - **f0**: NOME → 0 **and `set-form :nozarashi` at once** (hook `ken-drink-dry`, like L's stance
    switch in Bankai). This is the only forced rung change; everything else waits until he is free.
  - The cut therefore resolves in T1: **390 at ×1.0**. A cancel on hit (the O rush from its first hit
    frame) is T1's LEAP CLEAVE with a Kikon of **2**. The cup cannot be skipped: paid at f0, the form and
    the Kikon value already dropped (critique 2.2).
  - **Line split**: 0.3–6 m breaks guard (Guard Break 50 f, −35); 6–12 m is blockable (−16, guard 22).
    1 m wide: a sideways Step in the 26 f + 4 f super freeze beats it.
- **The decision**: cash three cups into one big, guard-breaking punish, or keep T3 (drink, rift, the
  4-Konpaku Kikon) for as long as he can keep drinking.

### 2.7 "Enjoy the fight": the Kikon count

- Kit key `:kikon-konpaku`: T1 **2**, T2 3, T3 **4**. Base Kenpachi 2; Yamamoto's awakened forms 3.
- **Read at rush start**: `try-command` stores `(kit-kikon-konpaku kit)` in a new fighter field
  `kikon-n`; `settle-konpaku` uses it. A drain during the dash-in can't turn a 4 into a 3, and a cash-out
  can't keep a 4.
- **Per-event cap 4** (`*kikon-max-event*`): a Soul Break adds +1 up to the cap. T3 Soul Break = 4, not
  5; T1 Soul Break = 3.
- Every character needs **≥ 3 events** to take 9 Konpaku (4 + 4 + 1).
- A red opponent at T1 poses a real question: take 2 now, or climb for 4 and risk the comeback.

### 2.8 Architecture and rules

- **register-kit fix (blocker, one line).**
  - Problem: a form with no derivation (`:startup-add 0`, reach 1) must take the **parent's** move,
    `(gethash m (kit-moves parent))`, not `find-move` (the written spec).
  - Without it T3 re-derives from spec: T3 would get base Q2 / stance / charge at base speed, and with a
    startup-add, R-Q3 17 f and R-F2 24 f, which breaks every link (critique 2.1).
  - Today's kits don't change: Hellfire's parent is the as-written base.
- Three kit forms; `set-form` from `gauge-system` (the ladder, free frames only) and from `ken-drink-dry`.
- New kit keys (generic):
  - `:meter (:name "NOME" :max 100 :ladder ((:nozarashi 0 nil nil nil) (:ryote 3.0 60 40 25) (:nomihose 10.0 0 100 50)))`:
    each rung is (form, drain/s, delay f, up-at, down-below);
  - `:meter-gain (:dealt 0.08 :taken 0.12 :drunk 0.30)`;
  - `:kikon-konpaku n`;
  - passives `:cut` and `:drink`.
- Pure rules (rules.lisp):
  - `(nome-gain dealt taken drunk gains)`;
  - `(meter-drain nome rate delay idle)`;
  - `(ladder-rung nome rung ladder)` (hysteresis, multi-step);
  - `(drink-split dmg)` → taken, drunk;
  - `(drink-adv adv)`;
  - `(cut-value v kind)` → ×1.5 for `:flash :sig :sp` (`*cut-mult*`), else v;
  - `kikon-result` takes the count and caps it with `*kikon-max-event*`.
- Shell:
  - combat.lisp:
    - the `:blocked` branch: `:drink` (split through `deal-damage`, `drink-adv`, NOME) and `:cut` on the
      guard value;
    - the `:armored` branch: `:cut` on the drained value;
    - the NOME gains in `deal-damage` / `gain-gauges` (dealt / taken) and the `:absorbed` branch (drunk);
    - the ladder in `gauge-system`;
    - `settle-konpaku` reads `kikon-n`.
  - fighter.lisp: `try-command` stores `kikon-n`.
  - hazards.lisp: the `:rift` kind (the bind's delay) and the owner-hit removal.
- Hooks (ken.lisp):
  - `ken-rift` (f20);
  - `ken-drink-dry` (f0 of the T3 meteor);
  - `ken-ryote-enter`, `ken-nomihose-enter` (look and callouts only);
  - `ken-sober-exit` ("TSUMANNEE...").
- **The eyepatch is sticky**: a per-fighter `revealed` list unioned into `refresh-look`. The awakening
  cinematic drops its beat 1: the tear moves to the first T3.
- **Remove `:ignore-armor`** from Nozarashi (and the passive, if nothing else uses it: nothing does).
- **Determinism**: the meter, the rung, `kikon-n` and the rifts go in the hash line.

### 2.9 AI

- New generic keys:
  - `:kikon-p` per form: an `ai-table` key read instead of the global `*ai-kikon-p*` (critique 2.13c);
  - `:cashout`.

| Form | Intents | Close band (0–3.4 m) | Keys |
|---|---|---|---|
| T1 | pressure 4, approach 2, defend 1 | `:q 5 :f 2 :sig 3 :breaker 1 :sp2 1` (the stance drinks) | guard 0.35, hoho 0.2, dash 0.8, **`:kikon-p 0.25`** (toys with a red opponent; the global value once the timer is < 60 s), `:react` stance as today, block-string 0.8 |
| T2 | pressure 5, approach 2 | `:q 5 :f 3 :sig 1 :breaker 1` | guard 0.35, dash 0.8, `:kikon-p 0.5`, block-string 0.85 |
| T3 | pressure 6, approach 3, zone 0, defend 0 | `:q 4 :f 4 :breaker 1`, `:sig 0` | **guard (drink) 0.45**, dash 1.0, `:kikon-p 0.9`, **`:cashout (:punish 30 :near 6.0 :below 60)`**: Shift+K only as a **punish** (the opponent has ≥ 30 f of recovery or stun left and stands in the 12 m lane) or **within 6 m in front** (the guard-breaking part) with NOME < 60. Never a raw long-range throw |

- **Dropped from v1**:
  - the rift `:trap` reflex: on block the rift is auto-blocked, on hit it is a combo, and on whiff the
    perfect-Hoho logic already sees hazards;
  - the "DEFEND +2 against `:drink`" rule: it would have had Yamamoto fleeing a faster runner. Heat and
    the ordinary rolls handle it.
- **Pacing log per match**: time per rung (mean T3 stay), rung entries, drinks, crushes during a drink,
  rifts (hit / blocked / whiffed / perfect-Hoho'd), cash-outs (punish / near), Kikons and **Konpaku per
  event** by rung.

### 2.10 Presentation (Kubo notan, yellow reiatsu in every form)

| Item | Design |
|---|---|
| T1 | the cleaver in the right hand, tip low; **eyepatch on**; the base yellow aura; cleave comets as built |
| T1 → T2 | the left hand closes on the cloth handle; idle `:ke-r-stance` (jōdan, the green tassel hanging); the aura flares to today's awakened size over 0.3 s; a yellow ring; callout "RYOTE"; `:tier-up` |
| The cut | a blocked heavy hit: the STEEL hexagon with a **yellow diagonal notch**; an armoured one (West): the same notch across the ember star |
| T2 → T3 | the patch torn off and flung (effect only); **a 1 f negative frame, then 12 f of manga-page** (two-tone with yellow kept: a notan beat Yamamoto never uses; it doesn't collide with his `:spot` / `:ash` grades); the yellow pillar on ones; 2 rings; 8 DUST puffs; "NOMIHOSE!"; `:awaken-boom`. The first T3 of a match gets the full pillar; later ones a half-height flare |
| T3 | **no persistent grade**; the body carries it: patch off, pillar-scale aura (the Phase-6 skull hint allowed), white-cored comets held 3 d, the rifts. The normal spot budget holds; no exception |
| Rift | f20: a white `fx-crescent :lens` slit with a REIATSU edge, trembling on twos; f40: a HIT-white line, an INK gash, 4 shards; `:rift-open` / `:rift-cut`. Closed early: it pinches shut in one drawing |
| DRINK | the hit star **reversed**: 6 yellow flecks into the cleaver, a gulp ring at the chest, `:ke-drink` (head back); `:gulp`; the laugh on every 3rd |
| Drops | T3 → T2: the aura collapses into falling flecks. T2 → T1: the left hand lets go, "TSUMANNEE..." |
| OMOSHIREE! | a callout and a one-drawing aura flare (no meter) |
| Run | the batch's faces-the-opponent clips (forward run / side slide / back-skate), one set for all cups, the cleaver on the shoulder |

- **Clips (6 + 1 variant)**: `:ke-r-stance`, `:ke-r-q1`, `:ke-r-q3`, `:ke-r-f1`, `:ke-r-f2`, `:ke-n-f1`,
  and `:ke-drink` (a variant of `:ke-stance-hold`).
- **Until the art lands, reuse through `:clip-s`**: R-Q1 / R-F1 / N-F1 ← `:ke-f1`, R-Q3 ← `:ke-q3`,
  R-F2 ← `:ke-f2`, drink ← `:ke-stance-hold`, meteor-n ← `:ke-meteor`.
- **Sounds (4 synths)**: `:gulp`, `:rift-open`, `:rift-cut`, `:tier-up`.
- Callouts are ASCII.

### 2.11 Balance

| Risk | Answer / knob |
|---|---|
| T3 permanent in bloody fights | 10/s with no delay; drinks paid by the guard gauge; the crush stops drinking. Knobs: drain 10 → 12; `*nome-drunk*` 0.30 → 0.20 |
| The cash-out as a free Kikon | paid at f0 with the form switched to T1, so the Kikon is 2. The guard break only ≤ 6 m |
| Match ends in two events | cap 4 per event; count read at rush start |
| Snowball when losing (Cornered + taken + Konpaku) | the Konpaku source removed; T3 ×1.2 → worst case ×1.2 × 1.25 = **×1.5** |
| Crush loop at T2 | the cut only on Flash / Sig / SP; the J string stays 28 |
| Rift pressure | +8 on block, guard 12, no frame trap. Knob: delay 20 → 18 |
| vs East (×1.4 taken) | T3 hits East ×1.2 × 1.4 = ×1.68: K K + rift ≈ 420. East's answers: the blade breaks the drink, recoil is paid on drunk hits, or the cone and a wait for the drain |
| vs West (hold-U armour) | no ignore-armour; the cut burns West's gauge faster on heavies; the scorch hits Kenpachi per armoured hit. If West loses too hard: the cut ×1.5 → ×1.25 on armour |
| Mirror | T3 vs T3 drink race, bounded by the drain and the gauges; watch KK |
| AI stuck at T1 | the timer < 60 s override; the gate's all-K.O. requirement |

### 2.12 Pacing (prediction; to be measured)

Today: YK 145.5 s, KK 152.4 s.
- **Shorter**: 4-Konpaku events; the heavy-cut crushes.
- **Longer**: ×1.0 at T1, 2-Konpaku T1 events, the CPU toying at T1, T3 lasting only 5–10 s, drinks
  costing Kenpachi half.
- Expect **YK ~140–150, KK ~135–150**, which agrees with the critique's estimate.
- Gate: 20 seeded matches per pairing, all K.O., median 125–180 s, max 240 s.
- If the median is < 125 s: T3 Kikon 4 → 3, then `*nome-drunk*` 0.30 → 0.20, then the T3 drain 10 → 12.
- If it is > 180 s: T1 Kikon 2 → 3, then T1 `:kikon-p` 0.25 → 0.5, then the T2 entry 40 → 30.
- Log the West hold-U rework separately. It changes YK on its own, so measure with it on and Nozarashi
  v2 off first, then both.

### 2.13 Tests

Rules test (host):
1. `nome-gain`: dealt 125 → 10.0; taken 200 → 24.0; drunk 62 → 18.6; a drink of 35 → 18 taken + 17
   drunk → 2.16 + 5.1.
2. `meter-drain`:
   - T1 never drains;
   - T2 drains 3/s only after 60 idle frames;
   - T3 drains 10/s from the first frame, **even during a drink barrage** (a gain doesn't pause it).
3. `ladder-rung`:
   - 39.9 / 40 → T1 / T2;
   - at T2, 25 / 24.9 → T2 / T1;
   - 100 → T3;
   - at T3, 50 / 49.9 → T3 / T2;
   - 0 at T3 → T1 in one call.
   - **Free-only**: a crossing during a move applies on the first free frame (shell probe: a whiffed
     N-F1 then K still gives R-F2).
4. `drink-split`: 35 → 18 / 17; 1 → 1 / 0. **A drink at 1 Reishi Soul Breaks** (through `deal-damage`,
   not chip).
5. Drink as guard: Breaker → Guard Break; bind → hit; behind → hit; `drink-adv` −2 → −6, −12 → −16;
   East recoil on a drunk hit; a crush at 0.
6. `cut-value`: Quick 8 → 8, Flash 14 → 21, SP 22 → 33; T2 J string blocked = 28, K K = 48; West's
   hold-U armour hit by R-F1 drains 21.
7. `kikon-result` with count and cap:
   - T1 2 / 3 (Soul Break), T2 3 / 4, T3 4 / **4**;
   - **the count is fixed at rush start**: a T3 rush that ends after a drop still takes 4, and a
     cash-out cancelled into O takes 2.
8. **register-kit**:
   - T3 R-Q3 = 14/4/22, 3.8 m and R-F2 = 21/5/28 (not re-derived); T3 Q2 = T2's 10/3/13;
   - T2's meteor 26/4/30, 12 m, and LEAP as written;
   - `:hellfire` unchanged.
9. Tables = code for the three forms. Links:
   - **T1 F1→F2 −1** (and today's 0 recorded as the bug it was), T1 Q1→Q2 −7, Q2→Q3 −3, Q2→F2q −2;
   - T2 R-Q1→Q2 −6, Q2→R-Q3 −2, Q2→R-F2q −2, R-F1→R-F2 −2;
   - T3 N-F1→R-F2 −2.
10. Rift:
    - spawned at f20, cuts at f40; on block inside blockstun, **+8**, guard 12;
    - on hit it combos (300 with K K);
    - **removed when Kenpachi is hit before f40**;
    - a Hoho whose start is within 8 f of the cut and touches it is perfect.
11. Cash-out: NOME 0 and form T1 at f0; damage 390 at ×1.0; the guard break only on the ≤ 6 m window.
12. Awakening: T1, NOME 10, heal 150, patch on. The first T3 reveals the patch, and it stays off after
    a drop.
13. A reset keeps NOME, the rung and the cooldowns, and clears the rifts.

Headless probes:
- drink: an East string barrage into a T3 Kenpachi holding U; NOME, guard gauge, crush and T3 end
  logged (≤ 10 s);
- rift: blocked → +8;
- cash-out → O cancel → Kikon 2;
- the determinism double run (meter, rung, `kikon-n`, rifts hashed);
- the gate.

### 2.14 Implementation order

1. **register-kit parent-move fix + its test** (blocker; it touches every kit's load, so land it
   first).
2. Rules + tests (§2.13 1–9).
3. **The ladder without new moves**: three forms with traits, mults, drain, the free-only rule, the
   Kikon count at rush start + the cap, the HUD bar. Remove `:ignore-armor`. **Gate**, after the West
   hold-U change has had its own gate.
4. DRINK (the `:blocked` branch) and the cut (the `:blocked` / `:armored` branches). Gate.
5. Moves: the T2 kendō set; N-F1 + the rift (with owner-hit removal); the cash-out meteor. Reused clips.
6. AI tables, `:kikon-p`, `:cashout`. Gate YY / YK / KK with the logs.
7. Art: clips, sticky patch, the trimmed awakening cinematic, the T3 manga-page beat, rift / drink /
   cup fx, 4 sounds. User review.
8. Docs: DUEL_DESIGN §2 (Kikon count and cap), §4 (U overrides: West ARMOUR, T3 DRINK in one
   paragraph), §5, §6.2 rewritten, §7, §12; STYLE_STORM §4.2.

Cost: about Bankai v3's. There are three forms, but DRINK is a branch, not a state; one hazard; one
generic ladder.

---

## Revision log

### v1 → v2 (critique-nozarashi.md, and the lead's batch constraints)

| # | Critique | Decision | v2 |
|---|---|---|---|
| 1.1 | T3 ×1.30 = Hellfire again; "burnout" borrowed | **Accept** | T3 ×1.20; the payoff is properties; the word "burnout" dropped from DRINK |
| 1.2 | T1 skipped (awaken 30, T2 at 40) | **Accept** | awaken at 10 (T2 needs ~250 taken / 375 dealt / 100 absorbed) |
| 1.3 | Six meter sources unreadable; OMOSHIREE punishes skill | **Accept** | three sources: taken 0.12, drunk 0.30, dealt 0.08; OMOSHIREE a callout only; steel and Konpaku removed |
| 1.4 | Thresholds invisible | **Accept** | dim floor ticks at 25 / 50, the pulse near the floor, pips inside the frame |
| 2.1 | T3 re-derives T2's string moves; links break | **Accept, extended** | parent-move reuse for non-deriving forms, T3 without derivation. **The critique missed that T2 has the same trap** for T1's own moves (meteor, LEAP): T2 lists them as its own |
| 2.2 | The cash-out skipped via the O cancel before f30 | **Accept, extended** | paid at f0. Paying alone isn't enough: under 2.10's free-only rule the form would still be T3, and a cancelled rush would read Kikon 4. So the cash-out also **switches the form at f0** (the one forced change); 390 at ×1.0; the break ≤ 6 m |
| 2.3 | Rift +12, wrong escapes, perfect-Hoho implication | **Accept** | delay 20 (inside blockstun: +8, auto-blocked); guard 12; escapes rewritten; the perfect Hoho on a whiffed rift stated as intended |
| 2.4 | Rift removal vs "trade with the parry counter" | **Accept** | owner-hit removal kept; the trade claim deleted |
| 2.5 | T3 Soul Break = 5; the count read at connect | **Accept** | cap 4 per event; the count stored at rush start |
| 2.6 | Losing snowballs | **Accept** | Konpaku source removed; worst case ×1.5 |
| 2.7 | T3 never drains in a bloody fight | **Accept** | T3 10/s with no delay; stay ~5–10 s, logged |
| 2.8 | Guard cut ×1.5 on the J string = a crush loop | **Accept** | the cut on Flash / Sig / SP only (J string 28, K K 48); it now also applies to armour (see B2) |
| 2.9 | DRINK must be real damage | **Accept** | the half goes through `deal-damage`; a test that it can Soul Break |
| 2.10 | Form change mid-move breaks strings | **Accept** | the rung applies only when free; the cash-out is the documented exception |
| 2.11 | Today's F1→F2 0-gap | **Accept** | T1 −1, T2 −2; tests added |
| 2.12 | Matchups | **Accept** | numbers updated (×1.68 vs East) |
| 2.13a | Cash-out sidestepped at range | **Accept** | as a punish (≥ 30 f) or within 6 m |
| 2.13b | T3 drink 0.6 invites Breakers | **Accept** | 0.45 |
| 2.13c | `*ai-kikon-p*` is global | **Accept** | `:kikon-p` as an `ai-table` key |
| 2.13d | DEFEND +2 vs drink: fleeing | **Accept, further** | the rule deleted rather than watched |
| 2.14 | Pacing | **Accept** | the prediction adopted; knobs reordered; YK measured with West's rework first |
| 3.1 | Label "drinks blood" [G] | **Accept** | labelled |
| 3.2 | The T3 grade = Yamamoto's burnout grade | **Accept** | no persistent grade; a 1 f negative + 12 f manga page on entry; no spot-budget exception |
| 4.1 | DRINK needn't be a new state | **Accept** | a `:guard` passive in the `:blocked` branch; `resolve-contact` / `contact-of` untouched |
| 4.3 | Missing tests | **Accept** | all added (§2.13 3, 4, 7, 8, 10, 11) |

Rejected outright: **none**. Where I went past the critique:
- 2.1: the T2 derivation trap.
- 2.2: the form switch at f0, since paying the meter alone leaves the Kikon value at 4.
- 2.3 / 2.13d: two AI rules deleted rather than tuned.

### The same batch's user decisions

| # | Decision | Effect on this design |
|---|---|---|
| B1 | Fighters face the opponent while moving (forward run / side slide / back-skate) | No conflict: the rift and the meteor use the facing, which is now always the opponent. One run clip set for all three cups (cleaver on the shoulder); the cup reads from the aura and patch. The ladder's "free" includes the run |
| B2 | West: hold U = armour (no guard; moves and attacks while armoured; each hit drains the guard gauge and scorches; 0 = burnout; per-move and vs-Quick armour removed) | **Conflict found and fixed**: today's Nozarashi `:ignore-armor` would make West's hold-U worthless against him. It is removed; the cut (×1.5 guard drain on Flash / Sig / SP) now applies to armoured hits too. The two U-overrides are specified as one family (§2.4 table: both pay from the guard gauge; West moves and takes full damage + scorch, Kenpachi stands and takes half + NOME; the panel tags `U: ARMOUR` / `U: DRINK`) |

## User decision after v2 (2026-09-26)
- v2 approved for implementation, with one correction from the user: in TYBW Kenpachi has NOT worn the
  eyepatch since the start of the arc, so he wears NO eyepatch in any form (base and all cups).
  Consequences: remove the eyepatch part from his body (all forms); the Nozarashi awakening cinematic loses
  its "patch torn off" beat (make the NOME release the whole beat); cup 3 (NOMIHOSE) needs a different
  visual trigger than "the eyepatch flies off" (e.g. the yellow reiatsu pillar + the 12 f two-tone page beat
  + his grin / hair lifting — decide in implementation); cup identification relies on reiatsu size/shape,
  grip (one hand / two hands) and the HUD, not the patch. Update research/DUEL_DESIGN canon notes.
