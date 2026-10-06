# SOUL DUEL: Lille Barro (リジェ・バロ, zh-TW 利傑巴羅), 万物貫通 THE X-AXIS and 神の裁き JILLIEL

Status: **full design pass written 2026-10-06, awaiting the user's review** (§2–§16); nothing is built yet; the roster
plumbing for a sixth character is in (DEVLOG §84). §1 holds the user's decisions; §16 the questions on the design pass. Canon facts: `docs/research/tybw-characters/notes/lille_barro.md`
(web-search summaries only, each claim with a confidence flag; check chapter numbers before quoting them in the manual).

The request (the user, 2026-10-06): 「我想要請你依據之前 duel 的開發經驗幫我製作新角色『利傑巴羅』，先與我討論整體設計構想，並在討論期間指派 agent 建制環境。」

## 0. Frame

- Roster **index 5**, keyword `:lille`, move and clip prefix `:lb-`. Appended **last** (the roster is append-only:
  learn tables, ENDLESS records and every index-keyed tool depend on it; DUEL_ENDLESS.md). Files `duel/lisp/lille.lisp` +
  `duel/lisp/lille-art.lisp`, loaded after `senjumaru.lisp` (DUEL_DESIGN "Character code layout").
- Canon marks as in DUEL_SENJUMARU.md: **[V]** manga, **[A]** anime-only, **[G]** our game interpretation.
- The canon beats this kit encodes (research note §2–§4):

| Canon | Mechanic | The opponent's verb |
|---|---|---|
| The X-Axis pierces everything on the line from the muzzle to the target; no barrier stops it (Nimaiya shot through two Royal Guards' shields) [V ch. 601–602] | the X-Axis shot goes **through guard**, projectiles and summons | **step off the line** |
| A sniper with no melee technique; he wins by never being in reach [V] | the weakest close range in the roster | **close the distance** |
| Jilliel: constantly intangible, "no weapon or spell can wound" him [V ch. 646] | a **phase stance** on U that any attack ends (decision 3) | **make him attack**, then punish |
| The left eye opens in a crisis; three openings unlock the Vollständig [V ch. 645–646] | three **eye** pips of a timed phase; the third fills EVOLUTION (decision 7) | **bait the eye**, then strike |
| Beheaded by Kyōraku's Bankai, he revives owl-headed [V ch. 649–650] | a **second awakening** at ≤ 4 Konpaku, Konpaku → 1 (decisions 6, 8) | **finish him**: one Kikon ends it |
| Nanao reflects his own Trompete; the halo breaks [V ch. 653] | a perfect Hoho / guard **reflects** Trompete and seals it (decision 9) | **time the guard** to the trumpet |

## 1. User decisions

### Decision 1 (2026-10-06): a pure long-range sniper

The user chose 「純遠距狙擊」 from: pure long-range sniper / mid-range hybrid / long range + strong escape.

- The roster's first true zoner: the lightest J / K strings (rifle butt and bayonet, short reach), strong at range.
- The opponent's plan is to close in and sidestep. The CPU and the pacing gate must not let him stall (the 125–210 s
  window applies as for everyone).

### Decision 2 (2026-10-06): the X-Axis pierces guard but only drains the guard gauge

The user chose 「穿防但只削防禦槽」 from: pierce guard but only drain the gauge / fully unguardable / blockable, pierce
projectiles only.

- A guarded X-Axis shot deals little Reishi (chip; chip never kills) and a large guard-gauge drain, so it leads to
  GUARD CRUSH. The main answer is a sidestep off the line, which a visible aim line telegraphs.

### Decision 3 (2026-10-06): Jilliel's intangibility works like Yamamoto's Bankai West

The user's words: 「設計成跟山本卍解相同，按下防禦開啟無實體狀態、攻擊就解除」 (rejecting: intangible when not attacking with
a gauge / the pure canon rule / intangible to ranged only).

- In the awakened form, **U switches him into the intangible stance** (as Yamamoto's U = East → West, kit
  `:guard-to`, DUEL_DESIGN §6.1 / DUEL_YAMA_REWORK.md), and **attacking drops it** (as West's `:drop-to … :keep`).
- The details: decisions 4–5 and §5.2.

### Decision 4 (2026-10-06): the intangible stance's cost and breaker (Q1, Q2)

The user chose 「穿過的攻擊削防禦槽，Breaker 能破」 (rejecting: fully invincible, only a Breaker breaks it / passed hits
drain Reiatsu).

- As West's ward: every hit that passes through him drains its guard value from the guard gauge, which **does not refill**
  while he is in the stance; empty = the stance drops and GUARD CRUSH.
- A **Breaker** (the grab) and the **unguardables** land on him in the stance.

### Decision 5 (2026-10-06): which commands keep the stance (Q3)

The user chose 「移動與 Step／Hoho 保留，所有攻擊解除」 (rejecting: walking only / the wing volley also keeps it).

- Walk, run, Step and Hoho keep the stance; **every attack** (J, K, L, SP1, SP2, I, O) drops it on the move's frame 0
  (West's `kit-drop`, with no `:keep` list).

### Decision 6 (2026-10-06): the second form is a second awakening (Q4)

The user chose 「第二次覺醒（像劍八卍解）」 (rejecting: a last stage inside the awakening / the Kikon cinematic only),
after the research came in (the owl-headed "true form" that revives after Kyōraku beheads him, Trompete, Sabaki no
Kōmyō; research note §4).

- The second exception to "one awakening per match", after Kenpachi's Bankai (DUEL_KEN_BANKAI.md). Entry and cost: decision 8 and §6.1.

### Decision 7 (2026-10-06): the left eye, three openings (Q5)

The user chose 「做：3 格眼，用完第 3 格補滿覺醒槽」 (rejecting: three pips not tied to the awakening / no eye rule).

- Base form: a three-pip **eye** meter, no refill in the match. U pressed at the moment he is hit spends a pip for a
  brief phase (a Hoho without the displacement; canon: he opens the left eye in a crisis, the blade passes through, ch. 645).
- The **third** opening fills the awakening gauge to EVOLUTION (canon: three openings is "heresy" and he releases
  Jilliel, ch. 646). It does not awaken him by itself; P still does.

### Decision 8 (2026-10-06): the second awakening is a revival after a beheading (Q6)

The user chose 「被斬首後復活」 (rejecting: exactly Kenpachi's Bankai rule / a higher threshold at a lighter cost).

- Canon: Kyōraku's Bankai beheads him and he revives owl-headed (ch. 649–650). The entry: in Jilliel, when a Kikon takes
  his Konpaku and he has **≤ 4 of his own Konpaku** left, **P** revives him into the owl form.
- The cost as Kenpachi's Bankai: his Konpaku go to **1**, his Reishi is refilled; the halo shrinks and the intangible
  stance is gone (the owl form trades the defence for the attack). Once a match by construction.

### Decision 9 (2026-10-06): Trompete can be reflected, and a reflection breaks his form (Q7)

The user chose 「反射成功還會打斷他的形態」 (rejecting: a perfect Hoho / guard reflects part of it / no reflection).

- Canon: Nanao's Hakkyōken turns Trompete back into him, takes an arm and a set of wings and breaks his halo (ch. 653).
- A perfect Hoho or a perfect guard against Trompete reflects part of it back onto him **and breaks his halo**: the
  owl form loses Trompete for the rest of the match (the exact loss is set at the design pass; the largest swing in the
  kit, so its timing window is a gate item).

### Decision 10 (2026-10-06): the X-Axis shot reaches the whole arena, more damage the farther (Q8)

The user chose 「全場，越遠傷害越高」 (rejecting: the whole arena at a fixed damage / about 15 m).

- One shot reaches the arena's edge (30 m across); its damage rises with distance, so he wants range and the opponent
  wants to close in. The aim line gives the opponent time to step off it. The CPU's perception and `:moves` bands must
  cover 8–30 m (nothing today is longer than 12 m).

## 2. Summary of the design pass (2026-10-06; every number is a proposal until the gate)

- **Three forms, three temperaments** (research note §6): the base form is a still, patient sniper; Jilliel is an untouchable
  floating judge; the owl form is a shrieking last stand.
- **Base 万物貫通 THE X-AXIS** (`:base`). L is held to **aim**: a thin ink line runs from Diagramm's muzzle to the arena wall,
  and he turns to follow the opponent at the Signature rate (60°/s). On release the shot fires **4 f later along the
  frozen line, the whole arena long**. Its damage grows with distance: **40 at ≤ 4 m, 120 at ≥ 20 m**. It **goes through
  guard** (decision 2): a guarded shot lets 15 % through as chip and drains **30** from the guard gauge. It goes through
  projectiles, hazards, summons and Senjumaru's umbrella. A Step to either side clears the 0.25 m line, and so does running
  across it faster than he can turn.
- **His J / K strings are the weakest in the roster** (rifle-butt and barrel strikes, J1 22). SP1 is a three-shot burst and
  SP2 a Hirenkyaku back-slide with one quick shot. **U is a guard with the eye**: a fresh U press timed to a hit (the perfect-Hoho
  window) opens the left eye. The hit passes through him and he is intangible for 16 f, which costs one of **three pips**
  for the whole match. The third opening fills his awakening gauge to EVOLUTION (decision 7).
- **Awakened 神の裁き JILLIEL** (`:jilliel`). **U switches him into 無実体 MUJITTAI, the intangible stance** (Yamamoto's West,
  decisions 3–5). Hits pass through him and drain their guard value from a gauge that does not refill. A Breaker or an
  unguardable lands; any attack drops the stance; walk, run, Step and Hoho keep it.
  - L is the **WING VOLLEY**: a fan of five thin lines from the wing holes, 6° apart. It covers a sidestep at mid range, but
    the gaps grow with distance.
  - SP2 is **二十四孔 NIJŪSHI-KŌ**, all 24 holes at once: one wide beam after a long tell.
  - What he gives up: the normal guard, the eye, the long precision shot's distance bonus, the back-slide.
- **Second awakening, the owl** (`:shin`, 真の姿 the "true form"; decision 8). In Jilliel, once a Kikon or Soul Break has left him
  with **1–4 Konpaku**, **P** revives him: his Konpaku go to **1** and his Reishi is refilled; the stance is gone and U is a
  plain guard again.
  - Damage ×1.2 and Kikon 4.
  - L is **裁きの光明 SABAKI NO KŌMYŌ**, the arm chop that runs a line of golden blasts along the ground.
  - SP2 is **神の喇叭 TROMPETE**: a 60 f wind-up, then a 2.4 m-wide beam to the wall. **Reflecting it** with a perfect Hoho
    or a **perfect guard** (a fresh U press ≤ 10 f before the blast) returns half its damage onto him, staggers him 60 f
    and **breaks his halo**: Trompete is sealed for the match (decision 9).
- **The CPU** (§11): it zones at 8–20 m with the aim line and Steps out when a string touches it. It opens the eye on a
  roll per threat, uses the stance only as a reaction (≤ 3 s, anti-stall) and revives at once when allowed. **Opponents
  get one key read off his kit**: `:opp-aim`, so they strafe while he aims and dash in inside 12 m.
- **Cinematics** (five; review-3 pacing, every shot `shot-on` its subject; §10): the awakening (the third eye-opening, "tantamount to
  heresy"), the base Kikon 万物貫通, the Jilliel Kikon 神の裁き, the revival, the owl Kikon 神の喇叭.

---

## 3. Identity and silhouette (the model sheet is the reference; this is what the code must keep)

- **Base**: 182 cm, the default rig. White trousers with a buttoned green front panel, a white sleeve on the right arm and a
  bare left arm, a long green fur stole with three buttons, and the green fur bicorne (the points sit left and right).
  Dark skin #7A6155 (the style's saturation cap), cream crew cut, **the left eye shut under the ring-of-four-arcs mark**.
  No cloak in combat.
- **Diagramm**: about 2.4 m long. A thin barrel runs through a fur sleeve, crossed at the rear by a tall black plank; the
  muzzle is a black cross. There is no scope, only a small dial knob on the plank. It is held at the hip pointing forward
  (idle) or shouldered with the open right eye along the barrel (aim). The J / K strikes use the plank (the butt) and the
  barrel's cross (the muzzle). The FK reach test measures the muzzle cross and the plank's far edge (`*lb-strike-reach*`).
- **Jilliel**: a holed, cream-white column with a face window near its top, ending in two prongs, floating 0.6 m up (the
  hurt cylinder stays on the ground, so flight is visual only). Eight flat blade wings, each with three oval holes, are
  fanned round him in **muted jade** (decision 11), with a wide thin halo. **No arms**: the J / K strikes are wing blades.
  The 24 holes are the muzzles.
- **The owl**: a white body on **four stilt legs**, long thin arms, a segmented S-neck and a tiny barn-owl face. A small
  spiked halo and gold (#B89A5A) only on the wings, the halo and the glow.
- **The eye mark is the motif**: the scope reticle on the aim line's far end, the HUD's eye pips and the trumpet bell's
  ring are the same glyph (`:lb-reticle`, baked once).

---

## 4. Base kit: 万物貫通 THE X-AXIS (form `:base`) [V names; G mechanics]

### 4.1 The one resource: 眼 ME, the left eye [V ch. 645–646; G mechanic]

| Rule | Value (knob) |
|---|---|
| Pips | **3** (`*lb-eyes*`), full at the start, **never refilled** in the match (canon scarcity), kept through Kikon resets |
| Trigger | a **fresh U press** (an edge, not the hold) while an opponent hit window (move or hazard) is active now or within **8 f** and overlaps his hurt cylinder grown by 1 m: the same test as the perfect Hoho (`perfect-hoho-p`, a shorter look-ahead: `*lb-eye-lead*` 8 against Hoho's 12). From idle, walk, run, guard, guard-hit (blockstun) and the recovery of a Step; **not** in a move or in hitstun (that is Burst Reverse's job) |
| Effect | the hit (and every hit of that window) **passes through**: no damage, no stun, no chip, no guard drain. He is **intangible 16 f** (`*lb-eye-phase*`), keeps his state (a guard stays a guard after it), and the attacker's hit counts as a **whiff** for the string gate (a link-1 whiff stops the string, R + 8 / R + 12: the punish) |
| A miss | a press with no threat in the window is a plain guard press: nothing spent (the risk is the timing, as for the perfect Hoho) |
| Third opening | the awakening gauge is set to **100** (EVOLUTION) unless he has awakened already; the line 「三度も眼を開かされるとは…」 as a brush callout. P still awakens (a choice) |
| Look | the left eye opens (a face-texture swap on the hit frame), the reticle mark flares jade, a ghosted afterimage where the hit lands; the pip turns from shut ― to open ◉ |
| Not in the other forms | Jilliel and the owl keep the left eye open (no pips; §5.6 named removal) |

Why a pip and not a gauge: three discrete openings are canon's own count, and a finite resource can't be farmed. An
escape that costs nothing on a miss is fair because it needs the perfect-Hoho timing and is gone after three.

### 4.2 J / K grid (DUEL_STRINGS §2.1 budget; the lightest strings in the roster) [G]

The rifle is long, but he fights with its butt plank and its muzzle cross at close range: short, light, defensive.
**Damage before `*lille-mult*`** (proposed 1.0; Senjumaru's 25 / 1.6 are the comparison).

| Link | Move | S / A / R | Dmg | Adv (block) | Reach (art) | Notes |
|---|---|---|---|---|---|---|
| J1 | 床尾打 SHŌBI-UCHI `:lb-j1` | 8 / 3 / 12 | 22 | −2 | 1.45 m | the plank swung up from the hip, flinch |
| J2 | 返し KAESHI `:lb-j2` | 7 / 3 / 13 | 22 | −2 | 1.45 m | the plank's backhand |
| J3 | 銃口突 JŪKŌ-TSUKI `:lb-j3` | 9 / 3 / 16 | 28 | −4 | 1.6 m | the muzzle cross jabbed, stagger (+5); `:ender` |
| K1 | 銃身薙 JŪSHIN-NAGI `:lb-k1` | 17 / 4 / 21 | 48 | −3 | 2.05 m | the barrel swept flat (K ≥ J + 0.5), stagger |
| K2 | 振り下ろし FURIOROSHI `:lb-k2` | 16 / 4 / 21 (`:enter` 14) | 48 | −3 | 2.05 m | the barrel brought down |
| K3 | 零距離 REI-KYORI `:lb-k3` | 18 / 4 / 30 (`:enter` 14) | 70 | −20 | 2.1 m | the muzzle pressed in and fired point-blank (a melee hit, not `:ranged`: it pays KŌSEI), crumple; `:ender` |
| J2s / K2s | copies (`defmove-copy`) | | | | | |

- `:l-after-k :lb-x-quick`: **K → L** fires a 6 f snap shot (§4.3's quick variant, no aim, 40 flat, line 12 m) as a
  string ender: his only cash-out from a close string, scaled as hit 3 or 4.
- No `:l-after-j`.

### 4.3 L 万物貫通 X-AXIS SHOT `:lb-x-axis` (hold) [V ch. 601–602, 644; G frame data]

| Phase | Frames | What |
|---|---|---|
| Raise | f0–10 | Diagramm shouldered, the right eye to the barrel; turning at 60°/s from f0; hittable (no armour) |
| Aim (the hold) | f10 → release, **min 24 f, max 120 f** (`:hold (24 120)`) | **planted** (no walk), turning at **60°/s** toward the opponent (`*lb-aim-track*`); the **aim line** is drawn from the muzzle to the wall (a `:line` look hazard, cosmetic): **grey** until f24, then **jade** ("can fire") |
| Release | L released at or after f24 (or auto at f120) | the line **freezes**; the reticle at its far end contracts for 4 f (`*lb-x-delay*`) |
| Fire | release + 4, **active 2 f** | a **line hit**: `(:cap 0.6 31.0 1.2 0.25)` from the muzzle (the arena is 30 m across), `:ranged`, `:x-axis` (§12 gap G2). Hits every fighter on the line; summons and hazards on the line don't stop it (a hit window never collides with hazards); **a KASA catch doesn't stop it** (`:uncatchable`) |
| Recovery | 26 f (whiff +6) | the recoil, the plank drops |

- **Damage by distance** d (centre to centre at the fire frame): **40 + 80 × clamp((d − 4) / 16, 0, 1)**: 40 at ≤ 4 m, 80 at
  12 m, 120 at ≥ 20 m (× `*lille-mult*`). Combo scaling as usual. On hit: stagger, knockback 1.0 m (2.0 m at ≥ 12 m).
- **Guarded** (a guard, West's ward, DRINK, Kenpachi's stance, armour, the KASA window): **15 % of the hit through as chip**
  (never kills, `*lb-x-chip*`) and a **guard drain of 30** (`*lb-x-guard*`), no blockstun beyond the 14 f hazard rule.
  So a full gauge breaks on the **4th** guarded shot. Kenpachi's stance absorbs it as a block, not a hit. Zero Rukia's
  optic ward lets it through, as any ranged hit.
- **Dodged** by Step / Hoho iframes, by being off the line (a sideways Step 2.5 m always clears the 0.25 m line), and by
  running across it: a sideways run at 8.5 m/s from 8 m away sweeps 61°/s, more than his 60°/s, so he can't follow.
  **A perfect Hoho** works against it (the window is a hit window), as does the eye in the mirror.
- **KŌSEI**: none (ranged). **No cooldown**: the aim time and the 26 f recovery pace it. Minimum cycle 10 + 24 + 4 + 2 +
  26 = **66 f** (1.1 s).
- **Callout**: 万物貫通 as a brush column the first time in a match, then the reticle only.

### 4.4 The rest of the buttons

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| Shift+K (SP1) | 三連 SANREN `:lb-sanren` | 12 / 3×(2) / 24 | 30 × 3 (flat) | 1 bar; three unaimed X-axis lines at f12, f22, f32, each turning 90°/s between shots (so the 2nd and 3rd follow a Step); each line 20 m, through guard (chip 15 %, drain **12** each); cancels a landed J / K link (`:cancel`). The anti-sidestep tool, paid with a bar |
| Shift+L (SP2) | 飛廉脚 HIRENKYAKU `:lb-hiren` | 4 / – / 18 | 60 + shot | 1 bar; a 6 m back-slide over 14 f (**no** iframes: decision 1 refused a strong escape), then a 6 f quick X-axis shot (the §4.3 line, damage by distance, through guard as §4.3) from where he lands |
| I | Breaker (derived, universal frame data) | | 150 | the plank slammed down |
| O | 照準 SHŌJUN, the Kikon module `:lb-kikon` | aura 8, no dash | 70 | the lane module (Rukia's / Senjumaru's `:look :lane`): `(:cap 0.5 12.0 1.2 1.2)`, the follow-up dash is a Hirenkyaku afterimage (`:follow-speed 14`). Kikon **2**; cinematic `lb-kikon-cine` (§10.2) |
| U | guard + the eye (§4.1) | | | |
| Walk / run | 3.4 / 8.5 m/s | | | `*walk-lille*`, `*run-lille*` |

### 4.5 What the base form plays like

Keep 8–20 m, aim, and release when he stops moving sideways. Each guarded shot takes 30 off the gauge, so four end in a
GUARD CRUSH, which pulls a turtle out of his shell. When someone reaches him, he Steps back or SP2s out and guards; when
a string comes he times the eye. He loses up close: J1 22 against Kenpachi's 35, and K links that lose to a J1.

---

## 5. The awakened kit: 神の裁き JILLIEL (form `:jilliel`) [V look and names; G mechanics]

### 5.1 The awakening

- Generic: P on EVOLUTION (decision 7's third eye fills it, as does the usual gauge); heals 20 %; the cinematic
  `lb-jilliel-cine` (§10.1). Once.
- Kit: `:awakening t :form-name "JILLIEL" :walk 3.0 :run 8.0 :mult *jilliel-mult* 1.0 :taken *jilliel-taken* 1.1
  :kikon-konpaku 3 :guard-to :jilliel-mujittai`. The left eye is open (no eye pips).

### 5.2 U: 無実体 MUJITTAI, the intangible stance (decisions 3–5)

Two kit forms, as Yamamoto's East / West: `:jilliel` (U enters the stance) and `:jilliel-mujittai` (`:drop-to :jilliel`,
**no `:keep`**: every attack command drops it on its frame 0).

| Rule | Value |
|---|---|
| Enter | U held from idle / walk / run (not in a move, a reaction, blockstun or guardless); up 2 f later (`*guard-raise*`) |
| A hit on him | **passes through**: no damage, no stun, no blockstun, no chip, no push. Its **guard value** is drained from the guard gauge × `*mujittai-mult*` **1.0**; for the attacker it is **contact** (a block for the string gate and KŌSEI), so a string continues and keeps draining. A hazard drains its 12 and passes |
| The gauge | **never refills** in the stance (GUARD HOLD counts every stance frame, as West); outside it the universal refill |
| Empty | the stance drops to `:jilliel` and **GUARD CRUSH** (40 f, guardless: U can't enter the stance until the gauge is full again, as for any guard) |
| What lands anyway | a **Breaker** (Guard Break 50 f, drops the stance, drains 35), **unguardables** (South's bind, a red victim's Kikon follow-up, Senjumaru's spikes, Rukia's freeze touch) as normal hits, and **perfect-Hoho counter strikes** |
| Kept | walk, run, Step, Hoho (decision 5); the stance survives a Step's iframes and a Hoho |
| Dropped | J, K, L, SP1, SP2, I, O, Burst (each on its frame 0; a refused command doesn't drop it) |
| Look | the wings fold round the column, the jade dims to a ghost tone, the column turns half-transparent; a pass-through ripples the wings |
| HUD | the form tag `U: MUJITTAI` (`hud-guard`), the guard bar as West's |

Why the guard value is the price: the stance is a guard with no blockstun and no chip. The opponent's answers are the
three West already has: pressure (each hit drains; the gauge never refills), the Breaker, and waiting until he must
attack. Kenpachi's NOMIHOSE cut (×1.5 on Flash / Signature / SP) empties it faster, so the Kenpachi matchup leans on that.

### 5.3 J / K (wing blades, the base budget)

Eight wings, the front pair striking. There are no arms, so there is no rifle up close.

| Link | Move | S / A / R | Dmg | Reach |
|---|---|---|---|---|
| J1 / J2 / J3 | 翼刃 YOKUJIN 1–3 `:lb-w-j1…` | as base | 24 / 24 / 30 | 1.6 / 1.6 / 1.7 m (the wing tips) |
| K1 / K2 / K3 | 双翼 SŌYOKU 1–3 `:lb-w-k1…` | as base | 50 / 50 / 72 | 2.2 / 2.2 / 2.3 m |

Damage before `*jilliel-mult*` 1.0. No K → L.

### 5.4 The rest of the awakened buttons

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| L (hold) | 翼の斉射 WING VOLLEY `:lb-volley` | raise 8, hold **16–90 f**, fire release + 4, active 2, R 24 | **55** flat per line | **five lines** fanned at −12°, −6°, 0°, +6°, +12° (`*volley-spread*` 6°), each `(:cap 0.6 31.0 1.2 0.2)`, through guard (chip 15 %, drain **18**); **one line at most hits a fighter per volley**. The fan's width: 1.7 m at 4 m (a Step clears it), 4.2 m at 10 m (it doesn't), 8.4 m at 20 m with 2.1 m gaps (a fighter standing in a gap is missed): **mid range is its range**. Turning 60°/s during the hold, as the base shot |
| Shift+K (SP1) | 三連 SANREN (wings) | as base | 30 × 3 | inherited (the lines start from the wings) |
| Shift+L (SP2) | 二十四孔 NIJŪSHI-KŌ `:lb-nijushi` | 40 / 6 / 30 | **180** | **2 bars** (awakened SP2). All 24 holes glow for 40 f (the tell: planted, no turning after f20). Then a **1.2 m-radius beam** to the wall (`(:cap 0.6 31.0 1.2 1.2)`). Through guard: chip 15 %, drain **45**. A side Step from the centre line clears 1.2 + 0.4 m only if it is taken before f40 |
| I | Breaker (derived; the column rams) | | 150 | |
| O | 神の裁き Kikon module `:lb-w-kikon` | aura 8, no dash | 70 | lane `(:cap 0.5 12.0 1.2 1.2)`; Kikon **3**; cinematic `lb-jilliel-kikon-cine` |
| U | 無実体 (§5.2) | | | |

### 5.5 What Jilliel plays like

He floats at 8–14 m. He volleys, and when something comes at him he holds U and lets it pass while the gauge falls, then
shoots once it whiffs. Up close the wing blades reach further than the base butt, but every attack is a moment he is
solid.

### 5.6 Removed base tools (sidegrade rule 2, named)

The **normal guard** (U is the stance; he can't block a thing while attacking or after the stance breaks), **the eye** (3
pips), **the precision shot** (the 120 at 20 m; the volley is flat 55), **HIRENKYAKU** (SP2 is now the beam), and some walk
(3.4 → 3.0). Taken ×1.1 (`*jilliel-taken*`): when he is solid, he is fragile.

### 5.7 Why it is a sidegrade

- **Better against** pressure and zoning that is not a Breaker: Yamamoto's waves and pillars, Senjumaru's zones, Rukia's
  rings. Each drains the gauge and nothing more.
- **Worse against** Breaker-happy rushers (Kenpachi, Ichigo) and against Kenpachi's ×1.5 cut: the stance falls fast, and
  he has no guard when it does.
- **Base precision vs the volley**: the base form's 120 at 20 m is the biggest ranged hit in the game. The volley is flat
  55 and gives up that range, but it catches Steps at mid range.

---

## 6. The second awakening: the owl, 真の姿 (form `:shin`) [V ch. 650–653; A ep. 37; G mechanics]

### 6.1 Entry (decision 8)

| Rule | Value |
|---|---|
| Condition | form `:jilliel` or `:jilliel-mujittai`, **and** the flag **BEHEADED** is set, **and** free (idle / guard / the stance; not a move, a reaction or blockstun) |
| BEHEADED | set when a **Kikon or a Soul Break settles on him in Jilliel** and leaves him with **1–4 Konpaku** (`*lb-revive-konpaku*` 4). It stays set for the rest of the match (P may wait) |
| Command | **P** (the phone's AWAKEN chip) |
| On entry | form `:shin`; **Konpaku := 1**, **Reishi := full** (Kenpachi's Bankai cost, decision 8); guard gauge full; Reiatsu, flash-step and cooldowns kept; the stance gone; the cinematic `lb-revive-cine` (§10.3) |
| Once | structural: `:shin` has no `:bankai-form`, and there is no way back to Jilliel |
| Prompt | the awakening row blinks 「P  REVIVE」 in gold while it is allowed (Kenpachi's 「P BANKAI」 path, `bankai-allowed-p` + a kit predicate, gap G7) |

The generic Bankai path (`:bankai-form`, `bankai-allowed-p`: free with ≤ `*bankai-konpaku*` 4 Konpaku) is reused, with
one generic kit predicate added for BEHEADED (gap G7). The Konpaku := 1 and the Reishi refill are Kenpachi's code.

### 6.2 The owl kit

`:awakening t :form-name "SHIN" :walk 4.0 :run 9.0 :mult *shinkei-mult* 1.2 :taken 1.0 :kikon-konpaku 4`; U is a plain
guard (200°, the universal gauge).

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| J / K | 鉤爪 KAGIZUME (the long arms) | base budget | J 26 / 26 / 32, K 54 / 54 / 78 | reach J 1.7, K 2.3 m (long thin arms) |
| L | 裁きの光明 SABAKI NO KŌMYŌ `:lb-sabaki` | 16 / – / 24 | 90 | the arm chop at f16 sends a **ground line of golden blasts** from 1 m to 18 m, erupting outward at 40 m/s (a `:rift`-style delayed line hazard, 0.6 m wide; each point hits once, 0.4 s life). Through guard (chip 15 %, drain 18). A sideways Step from where he aims always clears it; the eruption's travel time (0.45 s to 18 m) leaves time to see it |
| Shift+K (SP1) | 三筋 MISUJI | 18 / – / 26 | 70 × 1 | 1 bar; three Sabaki lines at −20°, 0°, +20° at once (one hit per fighter) |
| Shift+L (SP2) | **神の喇叭 TROMPETE** `:lb-trompete` | wind-up **60** / active **30** / R 40 | **240** | **2 bars**. The fist at the beak (f0), the golden trumpet with its plume forming overhead (f10–60, the tell: rising pitch, planted, **turning 30°/s until f40, then locked**); then a **2.4 m-radius beam** to the wall for 30 f (`(:cap 0.6 31.0 1.4 2.4)`, one hit per fighter). Guarded: chip 15 %, drain **60**. The reflect: §6.3. Sealed after a reflect |
| I | Breaker (derived; the four legs stamp) | | 150 | |
| O | 神の喇叭 Kikon module `:lb-o-kikon` | aura 10, no dash | 80 | lane `(:cap 0.5 12.0 1.4 1.4)`; Kikon **4** (Kenpachi's Bankai value); Soul Break 5; cinematic `lb-trompete-cine` |

### 6.3 The reflect: Hakkyōken's rule (decision 9)

| Rule | Value |
|---|---|
| Who | the opponent, on Trompete's **first active frame** (f60) |
| Perfect Hoho | the universal perfect Hoho triggered by the beam (its 12 f window): instead of its counter strike, the **reflect** |
| Perfect guard | a **fresh U press ≤ 10 f before f60** (`*lb-reflect-window*` 10), held through f60, facing him (the 200° arc). A guard raised earlier than that only blocks (chip + drain 60) |
| Reflect | the beam turns back along its line: **he takes 50 % of it** (120 × 1.2 = 144) as a real hit (it can Soul Break him; red or not, it is not a Kikon) and **staggers 60 f**. His **halo breaks**: Trompete is **sealed for the rest of the match** (SP2 refused; the HUD halo cracked) and the owl's O module keeps working. The reflector takes nothing; a "REFLECT" callout and a mirror-flash |
| Why not more | the beheading already took him to 1 Konpaku. A reflect that also ended the form would leave him with no last-stand tools; the seal removes the one move that made the form worth the gamble |

### 6.4 What the owl plays like, and the gamble

With one Konpaku, any Kikon or Soul Break on him is the K.O. So the owl wins only by taking the opponent's Konpaku first.
He has Kikon 4, ×1.2 damage, Trompete's 288, and Sabaki's ground lines. Against a fresh opponent with 9 Konpaku, three
owl Kikons are needed; against one at ≤ 4, one. The CPU rule (§11) revives only when that race can be won.

---

## 7. Kikon counts and events

| Form | Kikon | Soul Break (+1, cap 5) |
|---|---|---|
| base | 2 | 3 |
| Jilliel / MUJITTAI | 3 | 4 |
| owl | **4** | **5** |

The fewest events to K.O. 9 Konpaku stays two (owl Soul Break 5 + a 4), as for Kenpachi's Bankai.

---

## 8. Hit and guard rules this kit adds (one place)

| Rule | Where |
|---|---|
| **X-axis** (`:x-axis` hit flag): a guarded hit (any guard, ward, DRINK, stance, armour, the KASA window) lets `*lb-x-chip*` 0.15 of it through as chip and drains the move's `:guard`; it is never caught (`:uncatchable`) | combat (`apply-hit`): one flag branch, gap G2 |
| **Distance damage** (`:params :dist (d0 d1 dmg0 dmg1)`): the damage read at the fire frame from the centre distance | a `:dmg-fn` hook point, gap G3 |
| **The eye** (base) and **MUJITTAI** (Jilliel): a pre-hit veto: the kit's `:intangible` hook returns `:whiff` (the eye) or `:pass` (the stance: drain, contact) | combat, gap G4 |
| **Reflect** (owl): Trompete's own `:hit` hook reads the defender's guard press time and the perfect-Hoho flag | lille.lisp only, gap G5 |
| **BEHEADED** | lille.lisp, via the generic `:struck` hook and the settle path; the Bankai predicate gap G7 |

---

## 9. HUD and the one-hand controls

- **Base: 眼 ME.** Three eye pips (the reticle glyph) in the kit-meter row; a used pip shows the open eye in jade. The
  label is the brush 眼 + `ME n`. The third opening flashes the awakening row (EVOLUTION).
- **The aim line** (both players see it): a thin ink line on the floor from the muzzle to the wall, grey while too early,
  jade once he can fire, and the reticle at its far end. It is not drawn for the CPU's own view (there is none) but it
  is in the replay.
- **Jilliel**: no kit meter. The guard bar carries the `U: MUJITTAI` tag; in the stance the guard bar is outlined jade
  and drains (never refills) as West's.
- **Owl**: the halo icon in the meter row, whole or cracked (sealed). The name line reads "LILLE  SHIN". While BEHEADED
  holds in Jilliel, the awakening row blinks 「P  REVIVE」.
- **Distance tag** (base only): next to the reticle on the aim line, a small number for the damage the shot would deal
  now (40–120 × mult). It shows only to a human playing Lille.
- **Portrait**: the same pips / halo in the portrait meter slot; `portrait-label` `ME n` / `MUJITTAI` / `HALO`.
- **One hand** (DUEL_MOBILE_DESIGN §15.1): the **L chip held is the aim** (Rukia's SP1 hold path: the chip's down state is
  the hold), and releasing it fires. The thumb ring shows three eye ticks (base). **A resting thumb is a guard**: in the
  base form the eye needs a *fresh press*, so a resting thumb never spends a pip. In Jilliel the resting thumb is the
  stance (as West). In the owl it is a guard. Note: the stance gives a phone player a strong default; the gate does not
  measure phones, so this is a playtest item.

---

## 10. Cinematics (60 Hz, review-3 pacing; unskippable; every shot `shot-on` its subject)

### 10.1 The awakening `lb-jilliel-cine` (186 f) [V ch. 646]

| Shot | Frames | What |
|---|---|---|
| close | 0–30 | the face, the left eye shut under the mark; silence |
| the eye | 30–60 | the left eye **opens** (the third time); the mark flares jade; a 1 f negative |
| caption card | 60–120 | black card, jade back-rim: the line 「三度も眼を開かされるとは 異端に等しい」 as a brush column, the brush **神の裁き** with the reading JILLIEL |
| the cocoon | 120–160 | the body sheathed in the cream column, eight wings unfold one pair per 8 f, the halo draws itself |
| wide | 160–186 | from below, the winged column hovering, the opponent small |

### 10.2 The base Kikon `lb-kikon-cine` 万物貫通 (168 f) [V ch. 601–602]

The reticle view (the eye-mark ring), the shot, then the cross-shaped hole of light through the opponent's silhouette,
held. Last card: 万物貫通 with the reading THE X-AXIS.

### 10.3 The revival `lb-revive-cine` (180 f) [V ch. 649–650]

The headless column falls still; silence 30 f. It rises into the air, the jade turning to gold over 30 f, and the owl head
grows on the S-neck from light. The caption 「武器では死なず 霊圧で首を落としても尚死なない」, then the wide shot with
four stilt legs and a small spiked halo.

### 10.4 The Jilliel Kikon `lb-jilliel-kikon-cine` 神の裁き (162 f) and the owl Kikon `lb-trompete-cine` 神の喇叭 (186 f)

Jilliel's Kikon is 24 lines out of the wings, the opponent pinned at their crossing. The owl's is the trumpet's sound card:
the beam erases the horizon, and then there is silence. The 神の喇叭 card carries the reading TROMPETE.

---

## 11. AI (`:ai` per form; generic code in ai.lisp; difficulty scales every chance)

### 11.1 Tables

| Form | Intents (A / P / Z / D) | Ranges | Bands (lo hi weights) | Other keys |
|---|---|---|---|---|
| **base** | 1 / 1 / **5** / 2 | **Z 8–20 m**, D 5–9, P 1.3–2.2 | 0–2.2 `:q 4 :f 2 :breaker 1 :step 2`; 2.2–6 `:sp2 2 :step 2 :sp1 1 nil 1`; 6–30 `:sig 6 :sp1 1 nil 1` | guard 0.5, hoho 0.3, dash 0.3, **dash-back 0.7**, block-string 0.3, o-ender 0.3, `:l-after-k 0.4`, kikon-range 7.7, `:awaken (:min-taken 150)`, **`:eye (:p 0.5)`** (§11.2), **`:sig-hold lb-aim-hold`** |
| **jilliel** | 1 / 1 / **4** / 2 | Z 8–14, D 5–9, P 1.4–2.4 | 0–2.4 `:q 3 :f 3 :breaker 1 :step 1`; 2.4–8 `:sig 3 :step 2 nil 1`; 8–16 `:sig 5 :sp2 1 nil 1`; 16–30 `:sig 2 :step 1 nil 2` (dash in) | **`:stance (:p 0.6 :max 180)`** (§11.2), hoho 0.3, dash 0.4, dash-back 0.5, kikon-range 8.5, **`:revive (:p 0.9 :opp-konpaku 4 :or-own 1)`** |
| **shinkei** | 3 / 4 / 2 / 1 | P 1.4–2.6, Z 6–16 | 0–2.6 `:q 4 :f 4 :breaker 1`; 2.6–8 `:sig 3 :sp1 2 :step 1`; 8–20 `:sp2 3 :sig 2 nil 1` | guard 0.4, hoho 0.3, dash 0.8, o-ender 0.6, kikon-range 9.0, **`:trompete (:when-recovering t :far 8)`** |

### 11.2 His own reflexes (each rolls once per event, never per step)

- **`lb-aim-hold`** (`:sig-hold`): it rolls a hold length once per aim, in 24–60 f, and releases early when the opponent's
  lateral speed has stayed under 1.5 m/s for 6 f, i.e. he stopped strafing. HARD reads it; EASY holds a random length.
- **The eye** (`:reflex`): when the perfect-Hoho threat test fires against him in a free / guard state and pips remain,
  it rolls `:eye :p` × difficulty (EASY 0.25, NORMAL 0.5, HARD 0.75) once per threatening window, and presses U fresh. The
  third pip is used the same way; P follows the generic awaken rule.
- **The stance** (`:reflex`, Jilliel): when an opponent move starts within its reach + 1 m, or a hazard / ranged threat is
  within 12 f, it rolls `:stance :p` → U. It **leaves the stance by attacking**:
  - on the opponent's whiff or recovery;
  - after `:max` 180 f (3 s, anti-stall);
  - when the gauge is below 30.
  It never holds the stance while the opponent is out of reach and idle (no turtling).
- **Revive** (`:revive`): once BEHEADED is set, P at the first free frame with p 0.9, if the opponent has ≤ 4 Konpaku **or**
  his own Konpaku are already 1 (it costs nothing then). Otherwise it waits.
- **Trompete**: SP2 only when the opponent is ≥ 8 m away **or** in a recovery / reaction (a punish), never into an idle
  opponent within 8 m.

### 11.3 Opponents facing him (one key read off his kit; others unchanged, so every other pairing's hash stays)

- **`:opp-aim (:strafe 0.6 :rush 12)`** on `:base` and `:jilliel`. A CPU whose opponent is **holding an aim** (`:hold` +
  `:x-axis`) rolls once per aim at `:strafe` × difficulty to **strafe or side-run** (a reaction slower than the 4 f shot
  never fires, so it reads the hold, not the release). Within `:rush` 12 m it rolls the dash-in / O rush instead.
  Senjumaru's `:opp-rush-hold` path, generalised.
- **Trompete**: the generic perfect-Hoho / guard reflexes see the beam as a threat. One new roll on the `:shin` kit,
  `:opp-reflect (:p 0.3)` × difficulty (EASY 0.1, HARD 0.5), presses a fresh guard 6 f before f60 once per Trompete.
- **MUJITTAI**: the generic anti-ward rule, the one that sends a CPU's Breaker at Yamamoto's West, reads `:guard-to` forms.
  The build checks that it covers `:jilliel-mujittai` (gap G8).

---

## 12. Build list and the generic gaps (character code in `lille.lisp` / `lille-art.lisp`; shared files get hook points only)

| Gap | Where | What |
|---|---|---|
| G1 | ai.lisp | ranged perception past 12 m: `snap-reach` of a 31 m line makes "threat in range" true everywhere; the threat test must use the line distance (point-to-segment), not the reach |
| G2 | combat.lisp, rules.lisp | the `:x-axis` hit flag (chip `*lb-x-chip*` of a guarded hit + its `:guard` drain, through stance / ward / DRINK / armour / KASA) and `:uncatchable` |
| G3 | combat.lisp | a `:dmg-fn` (or `:params :dist`) read when a hit is collected |
| G4 | combat.lisp, fighter.lisp | a kit `:intangible (e hit)` hook before a hit applies: `:whiff` (the eye) or `:pass` (the stance: drain, contact) |
| G5 | lille.lisp | the Trompete reflect (the defender's last fresh U press tick: `fighter-guard-t` is the hold, so a "last press tick" field may be needed: generic, one slot) |
| G6 | hud.lisp | the kit meter `:draw` for eye pips / halo (Senjumaru's pattern) |
| G7 | rules.lisp / combat.lisp | `bankai-allowed-p` + a kit predicate `:bankai-ok` (BEHEADED); the Bankai entry's Kenpachi-only parts (the arm meter) kept behind his kit |
| G8 | ai.lisp | `:opp-aim`, `:opp-reflect`, the anti-ward rule covering any `:guard-to` form |
| G9 | debug.lisp | the gate's `*pairs*` append (`roster-pairs` already generates LY LK LR LI LS LL, k 15–20; group 2141) and a character debug range **79000–79999** (free; claim it in DUEL_GAMEPLAY) |
| G10 | tests | `duel-rules-test`: load list, `*forms*` (5 forms), clips, weapons, `*roster*` (six), the FK reach list; a host test per rule: distance damage, the X-axis guard drain (4 shots crush), the eye whiff and the third-eye EVOLUTION, MUJITTAI pass / Breaker / drop on attack, BEHEADED + revive cost, the reflect window edges (f49 / f50 / f61), one hit per volley |

**Art** (`lille-art.lisp`): bodies `:lille` (base), `:lille-jilliel` (column + wings, armless), `:lille-shinkei` (four legs,
S-neck, owl head); weapons Diagramm and the trumpet prop; strikes for 3 grids (J/K ×3 forms); the aim / volley / beam / ground-line
looks; five cinematics; glyphs (万 物 貫 通 眼 神 裁 喇 叭 翼 斉 射 光 明 無 実 体 二 十 四 孔 三 連 飛 廉 脚 照 準 鉤 爪 真
姿 異 端 …, baked with `tools/glyph-bake.py`, which needs `fonttools` + `skia-pathops` installed in the container).
**Order** (one character, so one branch; subagents per batch): rules + host tests → base kit → Jilliel → the owl → AI →
HUD → art → cinematics → gates.

---

## 13. Balance plan

**Every existing pairing must stay byte-identical** (G2 references, the 15 pairings at seeds 1–20). Everything above is
behind his kit, his hit flags or keys read off his kit.

**The gate grows by six pairings** (k 15–20, debug 2141; 21 pairings, 420 matches). Predictions:

| Pairing | Median guess | Why | Risk |
|---|---|---|---|
| **LY** | 140–180 s | two zoners, but Yamamoto's waves are blocked chips and his Bankai West's ward is drained by the shots | > 210 if both stand off |
| **LK** | 125–150 s | Kenpachi closes and wins up close; Lille's eye and back-slide stretch it | **Lille wins too little** |
| **LR** | 140–190 s | Rukia's rings vs lines; **zero Rukia is rooted**: every shot lands at full distance damage | **a rooted zero is free prey**: the knob is `:opp-aim` for her and the X-axis drain on her optic ward |
| **LI** | 135–175 s | Ichigo's rushdown vs the eye; KESSA's parry can't catch a ranged hit | — |
| **LS** | 150–200 s | Senjumaru's zones drain the stance; the shots go through KASA | > 210 |
| **LL** | 170–210 s | a mirror (allowed past 210) | the timer |

- **Win targets**: each new pairing 10 ± 3 of 20.
- **Awaken A/B** (the current criterion, the user's 2026-09-28 decision): P1 Lille in "never awaken" wins ≥ 20 / 60 on
  each of three streams (100 / 300 / 500) against each opponent.
- **The revival gamble test** (Kenpachi's Bankai §9 pattern): LY / LK over seeds 1–60 with `:revive :p` forced to 1.0 and
  to 0.0. The win-rate difference must be within ±9 / 60.
- **Pacing log** (`duel lille` lines, the companion regex already accepts any tag):
  - shots aimed / fired / hit / guarded / stepped / run-across, by distance band;
  - damage by distance;
  - eye openings and what they dodged;
  - awakening tick;
  - stance frames, passes, Breaker breaks, crushes;
  - volleys;
  - BEHEADED / revive ticks;
  - Trompete fired / hit / guarded / reflected.

**Knobs, in order**:
- **Medians over 210 s**: the base Z intent 5 → 4, `:opp-aim :rush` 12 → 15, the shot's recovery 26 → 30, the stance
  `:max` 180 → 120.
- **Under 125 s**: `*lb-x-guard*` 30 → 22, the far damage 120 → 100.
- **Lille wins too much**: the aim minimum 24 → 30 f, the far damage 120 → 100, the stance's `*mujittai-mult*` 1.0 → 1.2.
- **Too little**: `*lille-mult*` 1.0 → 1.3 (Rukia / Senjumaru precedent), the eye window 8 → 10, J1 22 → 26.
- **The A/B, awakening an upgrade**: `*jilliel-taken*` 1.1 → 1.2, the volley 55 → 48, `*mujittai-mult*` → 1.2.
- **The A/B, awakening a trap**: the volley spread 6° → 5°, `*jilliel-taken*` → 1.0, the stance enter 2 f → 1 f.

---

## 14. Adversarial self-critique

1. **"Through guard" against the sidegrade note's advice** (research sidegrade_design Q4 B.4: a zoner's projectiles should
   not crush from full screen). The user chose the drain (decision 2). What keeps it fair: the shot is a lane (one Step
   clears it); it has a 24 f minimum aim with a visible line, and he is planted while he aims; the drain needs four
   guarded shots, about 4.5 s at the minimum cycle. A guard is the wrong answer to it on purpose, and the gate measures it.
2. **Full-arena range lets him shoot at the reset distance** (8 m): 60 per shot, about one every 1.1 s. The 48 f reset
   neutral ignores inputs, so nobody aims during it. **Risk**: the CPU stands and trades shots. That is why `:opp-aim`
   makes CPUs strafe.
3. **The eye has no cost on a miss.** It is timed like the perfect Hoho, but Hoho costs 30 flash-step. Three uses, no
   refill: at most three free escapes a match. Kept.
4. **MUJITTAI and the phone**: a resting thumb is the stance. A phone player in Jilliel turtles by default, and the
   gauge is the only clock on that. Playtest item, noted in §9.
5. **The owl at 1 Konpaku.** Any K.O. event ends him, so is the revival ever worth it? The CPU rule only revives when it
   is free (own Konpaku 1) or the opponent is ≤ 4. The gamble test checks it either way.
6. **Rooted zero Rukia vs the sniper**: zero can't Step. With 120 a shot at 20 m, LR could fall below 125 s. The answer
   would be the user's (a Rukia knob or a Lille knob); noted, not pre-tuned.
7. **Hit-window lines of 31 m**: the AI's `snap-reach` and `incoming-projectile-p` were written for ≤ 12 m (G1). This is
   the riskiest generic change; it is a perception fix gated by byte-identical old pairings.
8. **Trompete's reflect is a human's read**: a perfect guard needs a fresh U within 10 f of a sound cue after a 60 f
   wind-up. That is generous on purpose: the owl is already at 1 Konpaku.

## 15. Canon ledger

| Item | Canon |
|---|---|
| X-Axis through barriers, Nimaiya shot through two guards | [V] ch. 601–602 |
| The left eye: three openings, then the Vollständig | [V] ch. 645–646 |
| Jilliel: eight wings × three holes, constant intangibility | [V] ch. 646 |
| Intangibility as a stance broken by a Breaker and by attacking | [G] (decisions 3–5) |
| The 24-hole blast cutting the city | [V] (med) |
| Beheaded by the Bankai, revives owl-headed | [V] ch. 649–650 |
| Sabaki no Kōmyō as the owl's chop | [V] (med; the wiki's version) |
| Trompete, reflected by Hakkyōken, halo broken | [V] ch. 653 |
| The reflect as a perfect Hoho / perfect guard | [G] (decision 9) |
| Every frame number, damage and distance | [G] |
| Move names 床尾打, 銃身薙, 零距離, 三連, 翼刃, 双翼, 鉤爪, 三筋, 照準 | [G] invented |

## 16. Questions for the user (each with the recommended default)

1. **X 軸狙擊：瞄準至少 24 f（線變色後才能開槍）、放開後 4 f 擊發、擋下扣 30 防禦槽（四發破防）、穿防 15 % 削血？** 建議：是。
2. **左眼：時機和完美 Hoho 相同（8 f 內），按錯不扣格；成功時對方的攻擊算揮空？** 建議：是。
3. **Jilliel 的翼斉射：五條線、每條 6°、每次最多中一條、固定 55，中距離最強？** 建議：是。
4. **梟頭的 Trompete：60 f 預備、2 bars、240 傷害；完美防禦是預備結束前 10 f 內重新按下 U？** 建議：是。
5. **梟頭的 Kikon 4、傷害 ×1.2（照劍八卍解）？** 建議：是。
6. **CPU 只在「對手 ≤ 4 魂」或「自己只剩 1 魂」時復活？** 建議：是。

## 17. Modelling references

The user (2026-10-06): 「請順便整理利傑巴羅各型態的參考圖作為建模依據」, and after opening the network policy: 「我以變更網路政策，請再次嘗試整理利傑巴羅各型態的參考圖作為建模依據」.

- The sheet: `docs/research/tybw-characters/notes/lille_barro_model_sheet.md` (per form: silhouette, parts, proportions
  re-measured from the official full-body visual, colours sampled from the stills, poses, what the ink style may simplify,
  the source list with page and file URLs).
- The pictures: 49 images (anime stills, the official digital colour manga, the official site's visual) in the
  git-ignored `.refs/Lille-Barro/` (`base/ diagramm/ jilliel/ owl/ trompete/`, `INDEX.md`, one contact sheet per form);
  third-party art, never committed.
- What the images corrected (the sheet has the full list): he fights without the cloak; Diagramm is about 2.4 m, a thin
  barrel through a fur sleeve crossed at the rear by a tall black plank, no telescopic scope; the eye mark (a ring of four
  arcs with four inward ticks) is also the reticle and the trumpet bell's ring; Jilliel is a holed column with a face
  window and eight flat blade wings with three oval holes each; the owl form is white with gold only on the wings, halo
  and glow, on four stilt legs.
- **Decision 11 (2026-10-06), the colours** (the sheet's §9): Jilliel's green is a **muted jade** (「低彩度玉色」; not a
  fourth spot hue, not the manga's pale gold-white): an ink tone, so the style keeps its three spot hues FIRE, REIATSU,
  BLOOD. The owl form's gold is **Senjumaru's muted gold #B89A5A** (「千手丸的低彩度金」; not REIATSU yellow, which is
  Kenpachi's, and not a near-colourless white-gold), on the wings, halo and glow only; the body stays white.
