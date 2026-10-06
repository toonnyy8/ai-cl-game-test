# SOUL DUEL: Lille Barro (リジェ・バロ, zh-TW 利傑巴羅), 万物貫通 THE X-AXIS and 神の裁き JILLIEL

Status: **full design pass written 2026-10-06 and revised after an adversarial review the same day (22 findings; the
lock, the eye's rest rule, MUJITTAI as a ward); the user's review answered 2026-10-06 (decisions 12–15)** (§2–§16); nothing is built yet; the roster
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

### Decisions 12–15 (2026-10-06): the user's review of the design pass

The user answered the four questions that changed the design (the other two of §16, the volley's and Trompete's
numbers, stand at their defaults):
- **12. The lock** 「照設計」: the line locks after 24 f of tracking, the shot fires ≥ 10 f after the lock (auto at 30),
  the aim can be cancelled before the lock (§4.3).
- **13. The eye** 「U 放開 ≥ 10 f 後的點按」: a deliberate tap after U rested ≥ 10 f, ≤ 8 f before a hit; no cost on a
  miss (§4.1).
- **14. MUJITTAI's clock**: 「向山本一樣無實體不恢復防禦槽，正常狀態防禦槽恢復量大減。使整體設計更容易被破防」 (rejecting a
  3 / s or 6 / s self-drain, or a run that drops the stance). Read as: the stance never refills (as West, no self-drain),
  and **Jilliel's refill outside the stance is cut hard**, 5.5 → **2.0 / s** (`:gg-regen`), so the design breaks
  more easily. The base form keeps the universal refill (the eye and the guard are its defence); if 「正常狀態」 meant
  every form, the base form's `:gg-regen` is one knob.
- **15. The owl's cost** 「不加代價」: no burn, no partial refill. The revival costs what decision 8 says (Konpaku → 1) and
  nothing more; at 1 Konpaku it is free, accepted.

## 2. Summary of the design pass (2026-10-06; every number is a proposal until the gate)

- **Three forms, three temperaments** (research note §6): the base form is a still, patient sniper; Jilliel is an untouchable
  floating judge; the owl form is a shrieking last stand.
- **Base 万物貫通 THE X-AXIS** (`:base`). L is held to **aim**: a thin ink line runs from Diagramm's muzzle to the arena wall,
  and he turns to follow the opponent at the Signature rate (60°/s). After 24 f of aim the line **locks** (it turns jade
  and stops turning). The shot fires on release, **never sooner than 10 f after the lock**, along the locked line,
  the whole arena long. Once the line is locked, one Step clears it. Its damage grows with distance: **40 at ≤ 4 m, 120 at ≥ 20 m**. It **goes through
  guard** (decision 2): a blocked shot lets 15 % through as chip and drains **30** from the guard gauge. It goes through
  projectiles, hazards, summons and Senjumaru's umbrella. Stance, armour and DRINK take it as they take any hit.
- **His J / K strings are the weakest in the roster** (rifle-butt and barrel strikes, J1 22). SP1 is a three-shot burst and
  SP2 a Hirenkyaku back-slide with one quick shot. **U is a guard with the eye**: a deliberate U tap (after U has been up ≥ 10 f) timed
  ≤ 8 f before a hit opens the left eye. The hit passes through him and he is intangible for 16 f, which costs one of **three pips**
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
  plain guard again. No running cost (decision 15).
  - Damage ×1.2 and Kikon 4.
  - L is **裁きの光明 SABAKI NO KŌMYŌ**, the arm chop that runs a line of golden blasts along the ground.
  - SP2 is **神の喇叭 TROMPETE**: a 60 f wind-up, then a 2.4 m-wide beam to the wall. **Reflecting it** with a perfect Hoho
    started f48–f60, or a **perfect guard** (a fresh U press on f50–f58), returns half its damage onto him, staggers him
    60 f and **breaks his halo**: Trompete is sealed for the match (decision 9).
- **The CPU** (§11): it zones at 8–20 m with the aim line and Steps out when a string touches it. It opens the eye on a
  roll per threat, uses the stance only as a reaction (≤ 3 s, anti-stall) and revives when the race can be won.
  **Opponents get two keys read off his kits**:
  - `:opp-aim`: Step off a locked line, Hoho behind a long aim, dash in inside 12 m;
  - `:opp-reflect`: time a guard to Trompete.
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
  barrel's cross (the muzzle). The FK reach test measures the muzzle cross (the weapon tip) and the plank at a
  negative weapon-length point (§12 Art).
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
| Trigger | a **deliberate tap**: a U press after U has been **up for ≥ 10 f** (`*lb-eye-rest*`), so a held or re-pressed reactive guard never opens it, while an opponent hit window (move or hazard) is active now or within **8 f** and overlaps his hurt cylinder grown by 1 m (the perfect Hoho's threat test, `perfect-hoho-p`, with a shorter look-ahead: `*lb-eye-lead*` 8 against Hoho's 12). From idle, walk, run and the recovery of a Step; **not** in a move, hitstun or blockstun (U is already held there). Implementation: a kit `:tick` hook (a form with a `:u` hook loses its guard, fighter.lisp:410) sets the existing `fighter-invuln` (Ichigo's slot, ichigo.lisp:363) |
| Effect | he is **intangible 16 f** (`*lb-eye-phase*`, `fighter-invuln`): every hit in that time resolves to nothing, no damage, no stun, no chip, no guard drain. He keeps his state (the tap is also a guard press), and the attacker's hit is a **whiff** for the string gate (a link-1 whiff stops the string, R + 8 / R + 12: the punish) |
| A miss | a press with no threat in the window is a plain guard press: nothing spent (the risk is the timing, as for the perfect Hoho) |
| Third opening | the awakening gauge is set to **100** (EVOLUTION) unless he has awakened already; the line 「三度も眼を開かされるとは…」 as a brush callout. P still awakens (a choice) |
| Look | the left eye opens (a face-texture swap on the hit frame), the reticle mark flares jade, a ghosted afterimage where the hit lands; the pip turns from shut ― to open ◉ |
| Not in the other forms | Jilliel and the owl keep the left eye open (no pips; §5.6 named removal) |

Why a pip and not a gauge: three discrete openings are canon's own count, and a finite resource can't be farmed. An
escape that costs nothing on a miss is fair because it needs a deliberate tap timed like a perfect Hoho, and it is gone
after three. The rest rule (U up ≥ 10 f) keeps ordinary guarding, a human's or the CPU's generic guard reflex, from
spending the pips by accident.

### 4.2 J / K grid (DUEL_STRINGS §2.1 budget; the lightest strings in the roster) [G]

The rifle is long, but he fights with its butt plank and its muzzle cross at close range: short, light, defensive.
**Damage before `*lille-mult*`** (proposed 1.0; Senjumaru's 25 / 1.6 are the comparison).

| Link | Move | S / A / R | Dmg | Adv (block) | Reach (art) | Notes |
|---|---|---|---|---|---|---|
| J1 | 床尾打 SHŌBI-UCHI `:lb-j1` | 8 / 3 / 12 | 22 | −2 | 1.45 m | the plank swung up from the hip, flinch |
| J2 | 返し KAESHI `:lb-j2` | 7 / 3 / 13 | 22 | −2 | 1.45 m | the plank's backhand |
| J3 | 銃口突 JŪKŌ-TSUKI `:lb-j3` | 9 / 3 / 18 | 28 | −4 | 1.6 m | the muzzle cross jabbed, stagger (+5); `:ender` |
| K1 | 銃身薙 JŪSHIN-NAGI `:lb-k1` | 17 / 4 / 21 | 48 | −3 | 2.05 m | the barrel swept flat (K ≥ J + 0.5), stagger |
| K2 | 振り下ろし FURIOROSHI `:lb-k2` | 20 / 4 / 24, `:enter` 6 (S_eff 14) | 48 | −3 | 2.05 m | the barrel brought down |
| K3 | 零距離 REI-KYORI `:lb-k3` | 21 / 5 / 34, `:enter` 7 (S_eff 14) | 70 | −20 | 2.15 m | the muzzle pressed in and fired point-blank (a melee hit, not `:ranged`: it pays KŌSEI), crumple; `:ender` |
| J2s / K2s | copies (`defmove-copy`) | | | | | |

- `:l-after-k :lb-x-quick`: **K → L** fires a 6 f snap shot (no aim, 40 flat, line 12 m, `:ranged :x-axis :uncatchable`)
  as a string ender: his only cash-out from a close string, scaled as hit 3 or 4.
- No `:l-after-j`.

### 4.3 L 万物貫通 X-AXIS SHOT `:lb-x-axis` (hold) [V ch. 601–602, 644; G frame data]

| Phase | Frames | What |
|---|---|---|
| Raise | f0–10 | Diagramm shouldered, the right eye to the barrel; turning at 60°/s; hittable (no armour) |
| Aim (tracking) | f10–34 (24 f) | **planted** (no walk), turning at **60°/s** toward the opponent (`*lb-aim-track*`); the **aim line** is drawn from the muzzle to the wall in **grey** (drawn by the kit's `:draw` hook from `fighter-hold` and his yaw: cosmetic, no sim entity) |
| **Lock** | f34 | the line turns **jade** and **stops turning** (track 0 from here to the shot, the fire frame included): the direction is committed |
| Release | L released at any time; the hold is `:hold (34 64)` (counted from move frame 0); auto-fire at f64 | the reticle at the line's far end contracts; the shot fires at **max(release + 4, lock + 10)** (`*lb-x-delay*` 4, `*lb-lock-min*` 10): **at least 10 f between the visible lock and the shot** |
| Fire | **active 2 f** | a **line hit**: `(:cap 0.6 31.0 1.2 0.25)` from the muzzle (the arena is 30 m across), `:ranged :x-axis :uncatchable` (§8). Hits every fighter on the line; summons and hazards on the line don't stop it (a hit window never collides with hazards: verified); a KASA catch doesn't stop it |
| Recovery | 26 f (whiff +6) | the recoil, the plank drops |
| Cancel | Step or U from f10 until the lock | he may abort the aim (a Hoho behind him, a rush) at the cost of the time spent |

- **Damage by distance** d (centre to centre at the fire frame): **40 + 80 × clamp((d − 4) / 16, 0, 1)**: 40 at ≤ 4 m, 80 at
  12 m, 120 at ≥ 20 m (× `*lille-mult*`). Combo scaling as usual. On hit: stagger, knockback 1.0 m (2.0 m at ≥ 12 m).
- **Blocked** (a guard, West's ward, a `:shield` window such as KASA, a `:parry-block`): **15 % of the hit through as chip**
  (the hitwin's existing `:chip`, never kills) and a **guard drain of 30** (the hitwin's `:guard`), `:adv-block −14`
  (blockstun 14 f). So a full gauge breaks on the **4th** blocked shot. **Not changed**: Kenpachi's stance absorbs it
  (full damage, as any absorbed hit), armour takes it (full damage), DRINK drinks half; none of them pay the guard gauge
  (DUEL_DESIGN §4). Zero Rukia's optic ward lets it through as a full hit; Rukia at −18 / −50 °C is `:chipless` (no chip).
- **Dodged**: before the lock, by out-turning him (a Step's slide sweeps 716 / d °/s, so it beats 60°/s within 12 m; a
  run within v / 1.05 m: 8–9.5 m), or by Hoho; **after the lock, by any Step or walk off the line** (0.65 m from its
  centre: a Step clears it by its f4, a walk in 11 f). The shot always gives ≥ 10 f to see the lock; a HARD CPU
  (8 f) can Step on it, a human must read it. **A perfect Hoho** works against it (the window is a hit window).
- **Hoho at range**: a Hoho reappears behind him at any distance (rules.lisp:65–71). Against a long aim it is the
  strongest answer (30 flash-step), which is why the aim can be cancelled into U or Step before the lock.
- **KŌSEI**: none (ranged). **No cooldown**: the aim time and the 26 f recovery pace it. Minimum cycle 34 + 10 + 2 + 26
  = **72 f** (1.2 s).
- **Callout**: 万物貫通 as a brush column the first time in a match, then the reticle only.

### 4.4 The rest of the buttons

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| Shift+K (SP1) | 三連 SANREN `:lb-sanren` | 12 / 3×(2) / 24 | 30 × 3 (flat) | 1 bar; three unaimed X-axis lines at f12, f22, f32, turning 90°/s between shots (the 2nd and 3rd follow a Step); each line 20 m, `:ranged :x-axis :uncatchable` (chip 15 %, drain **12** each); three hit windows (each hits once); cancels a landed J / K link (`:cancel`). The anti-sidestep tool, paid with a bar |
| Shift+L (SP2) | 飛廉脚 HIRENKYAKU `:lb-hiren` | 20 / 2 / 22 | the shot (by distance) | 1 bar; a 6 m back-slide over f0–14 (**no** iframes: decision 1 refused a strong escape), then at f20 a quick X-axis shot from where he lands (the §4.3 line and damage, `:ranged :x-axis :uncatchable`, track 0 after f14) |
| I | Breaker (derived, universal frame data) | | 150 | the plank slammed down |
| O | 照準 SHŌJUN, the Kikon module `:lb-kikon` | aura 8, no dash | 70 | the lane module (Rukia's / Senjumaru's `:look :lane`): `(:cap 0.5 12.0 1.2 1.2)`, guardable like every Kikon strike (no `:x-axis`); the follow-up dash is a Hirenkyaku afterimage (`:follow-speed 14`). Kikon **2**; cinematic `lb-kikon-cine` (§10.2) |
| U | guard + the eye (§4.1) | | | |
| Walk / run | 3.4 / 8.5 m/s | | | `*walk-lille*`, `*run-lille*` |

### 4.5 What the base form plays like

Keep 8–20 m and aim; lock where he will be, then pick the moment to fire (10–30 f after the lock) against his Step.
Each blocked shot takes 30 off the gauge, so four end in a GUARD CRUSH, which pulls a turtle out of his shell; the
locked line itself pushes him sideways, away from approaching. When someone reaches him, he Steps back or SP2s out and guards; when
a string comes he times the eye. He loses up close: J1 22 against Kenpachi's 35, and K links that lose to a J1.

---

## 5. The awakened kit: 神の裁き JILLIEL (form `:jilliel`) [V look and names; G mechanics]

### 5.1 The awakening

- Generic: P on EVOLUTION (decision 7's third eye fills it, as does the usual gauge); heals 20 %; the cinematic
  `lb-jilliel-cine` (§10.1). Once.
- Kit: `:awakening t :form-name "JILLIEL" :walk 3.0 :run 8.0 :mult *jilliel-mult* 1.0 :taken *jilliel-taken* 1.1
  :kikon-konpaku 3 :guard-to :jilliel-mujittai`. The left eye is open (no eye pips).

### 5.2 U: 無実体 MUJITTAI, the intangible stance (decisions 3–5)

Two kit forms, as Yamamoto's East / West: `:jilliel` (`:guard-to :jilliel-mujittai`: U enters the stance) and
`:jilliel-mujittai` (`:drop-to :jilliel`, **no `:keep`**: every kit command drops it on its frame 0;
`:passives (:ward :intangible)`, `:u-tag "U: MUJITTAI"`). It **is West's ward** with one flag: everything keyed on
`:ward` works for it unchanged (GUARD HOLD, the 360° guard state, `ward-drop` on a crush or a Breaker, Kenpachi's cut
×1.5, the HUD, the CPU's anti-ward rule), and the `:intangible` flag changes three numbers in the ward branch.

| Rule | Value |
|---|---|
| Enter | U held from idle / walk / run (not in a move, a reaction, blockstun or guardless); up 2 f later (`*guard-raise*`) |
| A hit on him | **passes through**: no damage, no stun, no blockstun, **no chip** (hitwin chip, blade chip and East's pierce all skipped), **no push**. Its **guard value** is drained × `*mujittai-mult*` **1.0** (West's `*ward-mult*` is 1.1); for the attacker it is **contact** (a block for the string gate and KŌSEI), so a string continues and keeps draining. A hazard drains its 12 and passes. An X-axis shot in the mirror drains its 30 |
| The gauge | **never refills** in the stance (GUARD HOLD, as West); no self-drain (decision 14). **Outside the stance, Jilliel's refill is cut hard**: `:gg-regen` **2.0 / s** (`*jilliel-gg-regen*`; the universal 5.5 / s, the user's 「大減」), so a stance that ran the gauge down stays down: 0 → 100 takes 50 s + the delay |
| Empty | the stance drops to `:jilliel` and **GUARD CRUSH** (40 f, guardless: U can't enter the stance until the gauge is full again, as for any guard) |
| What lands anyway | a **Breaker** (Guard Break 50 f, drops the stance, drains 35: West's `ward-drop`) and **unguardables** (South's bind, a red victim's Kikon follow-up, Senjumaru's spikes, Rukia's freeze touch) as normal hits. An opponent's perfect-Hoho counter strike is not unguardable: it **passes** like any hit (West's ward blocks it too) |
| Kept | walk, run, Step, Hoho (decision 5); the stance survives a Step's iframes and a Hoho |
| Dropped | J, K, L, SP1, SP2, I, O (each on its frame 0; a refused command doesn't drop it). **His own perfect-Hoho counter strike also drops it** (it is an attack; one line in his `:tick`, since it is not a kit command). A Burst needs hitstun, which the stance never gives, so it can't start from the stance |
| Look | the wings fold round the column, the jade dims to a ghost tone, the column turns half-transparent; a pass-through ripples the wings |
| HUD | the form tag `U: MUJITTAI` (`hud-guard`), the guard bar as West's |

Why the guard value is the price: the stance is a guard with no blockstun and no chip. The opponent's answers are the
three West already has: pressure (each hit drains; the gauge never refills), the Breaker, and waiting until he must
attack. Kenpachi's NOMIHOSE cut (×1.5 on Flash / Signature / SP) empties it faster, so the Kenpachi matchup leans on that.

### 5.3 J / K (wing blades, the base budget)

Eight wings, the front pair striking. There are no arms, so there is no rifle up close.

| Link | Move | S / A / R | Dmg | Reach |
|---|---|---|---|---|
| J1 / J2 / J3 | 翼刃 YOKUJIN 1–3 `:lb-w-j1…` | as base (§4.2) | 24 / 24 / 30 | 1.6 / 1.6 / 1.7 m (the front wing tips) |
| K1 / K2 / K3 | 双翼 SŌYOKU 1–3 `:lb-w-k1…` | as base (§4.2) | 50 / 50 / 72 | 2.2 / 2.2 / 2.3 m |

Damage before `*jilliel-mult*` 1.0. No K → L.

### 5.4 The rest of the awakened buttons

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| L (hold) | 翼の斉射 WING VOLLEY `:lb-volley` | raise 8, track f8–24, **lock f24**, `:hold (24 54)`, fire max(release + 4, lock + 10), active 2, R 24 | **55** flat | **five lines** fanned at −12°, −6°, 0°, +6°, +12° (`*volley-spread*` 6°), each `(:cap 0.6 31.0 1.2 0.2)` with its own yaw, **one hit window holding five volumes** (so one line at most hits a fighter: `collect-melee` hits once per window; gap G11), `:ranged :x-axis :uncatchable` (chip 15 %, drain **18**). The fan's width: 1.7 m at 4 m (a Step clears it), 4.25 m at 10 m (it doesn't), 8.5 m at 20 m with 2.1 m gaps (a fighter standing in a gap is missed): **mid range is its range**. Track and lock as the base shot |
| Shift+K (SP1) | 三連 SANREN (wings) | as base | 30 × 3 | inherited (the lines start from the wings) |
| Shift+L (SP2) | 二十四孔 NIJŪSHI-KŌ `:lb-nijushi` | 40 / 6 / 30 | **180** | **2 bars** (awakened SP2). All 24 holes glow for 40 f (the tell: planted, `:track` 60°/s until f20, then 0). Then a **1.2 m-radius beam** to the wall (`(:cap 0.6 31.0 1.2 1.2)`), `:ranged :x-axis :uncatchable`: chip 15 %, drain **45**. A Step taken by f40 clears it (1.2 + 0.4 m < 2.5 m) |
| I | Breaker (derived; the column rams) | | 150 | |
| O | 神の裁き Kikon module `:lb-w-kikon` | aura 8, no dash | 70 | lane `(:cap 0.5 12.0 1.2 1.2)`, guardable (no `:x-axis`); Kikon **3**; cinematic `lb-jilliel-kikon-cine` |
| U | 無実体 (§5.2) | | | |

### 5.5 What Jilliel plays like

He floats at 8–14 m. He volleys, and when something comes at him he holds U and lets it pass while the gauge falls, then
shoots once it whiffs. The CPU's stance can't catch a J1 (perception 8–24 f + 2 f raise > S 7–10): it answers K links,
L, SPs and projectiles; a human can stand in it beforehand. Up close the wing blades reach further than the base butt, but every attack is a moment he is
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
| Condition | form `:jilliel` or `:jilliel-mujittai`, **and** the flag **BEHEADED** is set, **and** free: idle, guard or the stance (the kit predicate checks the state itself, since the P command's generic `awaken-state-p` would also allow blockstun and a combo reaction) |
| BEHEADED | set when a **Kikon or a Soul Break settles on him in Jilliel** and leaves him with **1–4 Konpaku** (`*lb-revive-konpaku*` 4), through a new generic `:settled (def lost left)` kit hook called by `settle-konpaku` (gap G7; a Kikon reaches `:struck` before it is settled, and a Soul Break's count exists only there). It stays set for the rest of the match (P may wait) |
| Command | **P** (the phone's AWAKEN chip) |
| On entry | form `:shin`; **Konpaku := 1**, **Reishi := full** (`bankai!`'s generic part, decision 8; it also breaks the attack like a Burst: `repel!`, 20 f invulnerable); guard gauge, Reiatsu, flash-step and cooldowns kept; the stance gone; the cinematic `lb-revive-cine` (§10.3). `bankai!`'s arm-meter line is skipped for a form without `:pips` (gap G7) |
| Once | structural: `:shin` has no `:bankai-form`, and there is no way back to Jilliel |
| Prompt | the awakening row blinks 「P  REVIVE」 in gold while it is allowed (Kenpachi's 「P BANKAI」 path, `bankai-allowed-p` + a kit predicate, gap G7) |

The generic Bankai path (`:bankai-form`, `bankai-allowed-p`: free with ≤ `*bankai-konpaku*` 4 Konpaku) is reused, with
one generic kit predicate added for BEHEADED (gap G7). The Konpaku := 1 and the Reishi refill are Kenpachi's code.

### 6.2 The owl kit

`:awakening t :form-name "SHIN" :walk 4.0 :run 9.0 :mult *shin-mult* 1.2 :taken 1.0 :kikon-konpaku 4`;
U is a plain guard (200°, the universal gauge).

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| J / K | 鉤爪 KAGIZUME (the long arms) | base budget (§4.2) | J 26 / 26 / 32, K 54 / 54 / 78 | reach J 1.7, K 2.3 m (long thin arms) |
| L | 裁きの光明 SABAKI NO KŌMYŌ `:lb-sabaki` | 16 / – / 24 | 90 | the arm chop at f16 sends a **ground line of golden blasts** from 1 m to 18 m, erupting outward at 40 m/s (a delayed line hazard of his own kind through the `:hook` path, **not a `:rift`**, which `close-rifts` cancels when its owner is hit; 0.6 m wide; each point hits once, 0.4 s life; `:x-axis :uncatchable`: chip 15 %, drain 18). A sideways Step from where he aims always clears it; the eruption's travel time (0.45 s to 18 m) leaves time to see it |
| Shift+K (SP1) | 三筋 MISUJI | 18 / – / 26 | 70 | 1 bar; three Sabaki lines at −20°, 0°, +20° at once, **one hit group** (a fighter is hit by one line at most; gap G12) |
| Shift+L (SP2) | **神の喇叭 TROMPETE** `:lb-trompete` | wind-up **60** / active **30** / R 40 | **240** | **2 bars**. The fist at the beak (f0), the golden trumpet with its plume forming overhead (f10–60, the tell: rising pitch, planted, **turning 30°/s until f40, then locked**); then a **beam 2.4 m wide** (radius 1.2) to the wall for 30 f (`(:cap 0.6 31.0 1.4 1.2)`, one window: one hit per fighter), `:ranged :x-axis :uncatchable`. Blocked: chip 15 %, drain **60**. Once he is locked a Step clears it (1.2 + 0.4 m < 2.5 m). The reflect: §6.3. Sealed after a reflect |
| I | Breaker (derived; the four legs stamp) | | 150 | |
| O | 神の喇叭 Kikon module `:lb-o-kikon` | aura 10, no dash | 80 | lane `(:cap 0.5 12.0 1.4 1.4)`, guardable; Kikon **4** (Kenpachi's Bankai value); Soul Break 5; cinematic `lb-trompete-cine` |

### 6.3 The reflect: Hakkyōken's rule (decision 9)

| Rule | Value |
|---|---|
| Who | the opponent, around Trompete's **first active frame** (f60) |
| Perfect Hoho | a Hoho **started f48–f60** that the beam makes perfect: instead of its counter strike, the **reflect**. (The universal test also accepts f61–f89 against a 30 f window; those dodge as a normal perfect Hoho, with its counter strike, but don't reflect) |
| Perfect guard | a guard **started f50–f58** (`fighter-guard-t` at f60 between 2 and 10; with `*guard-raise*` 2 a press on f59 or later isn't up yet), held through f60, facing him (the 200° arc). A guard raised earlier only blocks (chip + drain 60) |
| Who can't | **Bankai West** (its guard time counts from entering West: Hoho only), **KESSA** (no guard: Hoho only), **zero Rukia** (rooted, an optic ward: she can't reflect and must not stand in its line). The A/B logs the reflect source per pairing |
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

Most of it is existing code (the review of 2026-10-06 checked each against the source):

| Rule | How |
|---|---|
| **Through guard**: a **blocked** hit (a guard, West's ward, a `:shield` window, `:parry-block`) lets 15 % through as chip and drains the move's `:guard` | **existing**: the hitwin's `:chip 0.15 :guard 30` (kit.lisp:31–35, combat.lisp:284–291) and `:adv-block −14`; stance absorb, armour and DRINK resolve as for any hit (no change) |
| **Never caught** by KASA | **new**: the `:uncatchable` flag, one test at combat.lisp:279 (gap G2) |
| **The flags per move** | `:ranged :x-axis :uncatchable`: the X-axis shot, the K → L snap shot, SANREN, HIRENKYAKU's shot, the volley, NIJŪSHI-KŌ, Sabaki, MISUJI, Trompete. **None** of them on the Kikon lanes (a Kikon strike stays guardable) or on any J / K (K3's point-blank shot is melee) |
| **Distance damage** | **existing**: an `:on-frame` hook on the fire frame sets `fighter-dmg-bonus` (the hit carries it as `pending-bonus`: damage = the hitwin's 40 + bonus) |
| **The eye** | **existing slot**: his `:tick` hook sets `fighter-invuln` 16 on a qualifying tap (§4.1); every hit then resolves to nothing, a whiff for the attacker |
| **MUJITTAI** | **existing ward** + the `:intangible` passive: one test in the ward branch (drain × `*mujittai-mult*`, no push, no chip); Jilliel's `:gg-regen` 2.0 is an existing kit key (gap G4) |
| **The lock** | his `:tick` sets the move's tracking to 0 from the lock frame; the fire frame from `fighter-hold` (no shared change) |
| **Reflect** | Trompete's own `:hit` hook reads the defender's `fighter-guard-t` (2–10 at f60) and the Hoho start frame (lille.lisp only) |
| **BEHEADED** | a new generic `:settled (def lost left)` kit hook in `settle-konpaku` (gap G7) |

## 9. HUD and the one-hand controls

- **Base: 眼 ME.** Three eye pips (the reticle glyph) in the kit-meter row; a used pip shows the open eye in jade. The
  label is the brush 眼 + `ME n`. The third opening flashes the awakening row (EVOLUTION).
- **The aim line** (both players see it): a thin ink line on the floor from the muzzle to the wall, grey while it tracks,
  jade once it locks (it stops turning; the shot is ≥ 10 f away), and the reticle at its far end. It is not drawn for the CPU's own view (there is none) but it
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
  base form the eye needs a deliberate tap after ≥ 10 f with U up, so a resting thumb never spends a pip. In Jilliel the resting thumb is the
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
| **base** | 1 / 1 / **5** / 2 | **Z 8–20 m**, D 5–9, P 1.3–2.2 | 0–2.2 `:q 4 :f 2 :breaker 1 :step 2`; 2.2–6 `:sp2 2 :step 2 :sp1 1 nil 1`; 6–30 `:sig 6 :sp1 1 nil 1` | guard 0.5, hoho 0.3, dash 0.3, **dash-back 0.7**, block-string 0.3, o-ender 0.3, `:l-after-k 0.4`, kikon-range 7.7, `:awaken (:min-taken 150)`, **`:eye (:p 0.5)`** (§11.2), **`:sig-hold lb-aim-hold`**, `:opp-aim` (§11.3) |
| **jilliel** | 1 / 1 / **4** / 2 | Z 8–14, D 5–9, P 1.4–2.4 | 0–2.4 `:q 3 :f 3 :breaker 1 :step 1`; 2.4–8 `:sig 3 :step 2 nil 1`; 8–16 `:sig 5 :sp2 1 nil 1`; 16–30 `:sig 2 :step 1 nil 2` (dash in) | **`:stance (:p 0.6 :max 180)`** (§11.2), hoho 0.3, dash 0.4, dash-back 0.5, kikon-range 8.5, **`:bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1)`** (the generic Bankai key: its nothing-to-lose rule and the 31000+10a+b A/B already exist, ai.lisp:264–280), `:opp-aim` |
| **shin** | 3 / 4 / 2 / 1 | P 1.4–2.6, Z 6–16 | 0–2.6 `:q 4 :f 4 :breaker 1`; 2.6–8 `:sig 3 :sp1 2 :step 1`; 8–20 `:sp2 3 :sig 2 nil 1` | guard 0.4, hoho 0.3, dash 0.8, o-ender 0.6, kikon-range 9.0, **`:trompete (:when-recovering t :far 8)`**, `:opp-reflect` (§11.3) |

### 11.2 His own reflexes (each rolls once per event, never per step; every lead is the *perceived* one)

- **`lb-aim-hold`** (`:sig-hold`, which returns a hold length at the press): **34 + a rolled 10–30 f** after the lock
  (HARD rolls nearer 10, i.e. fires on the lock against a still opponent, and nearer 30 against a strafer: the
  opponent's lateral speed is read once, at the press). No early release: a `:sig-hold` is fixed at the press
  (ai.lisp:138), and the CPU's reflexes don't run inside a move (ai.lisp:363).
- **The eye** (`:reflex`; it **takes over from the generic guard reflex** in the base form). On a threat it perceives
  (the generic perception delay, 8 / 14 / 24 f by difficulty: the lead is `s − sf − delay`, as Ichigo's perfect-Hoho
  reflex at ichigo.lisp:858, never the true sim state), it rolls once per threatening window:
  - `:eye :p` × difficulty (EASY 0.25, NORMAL 0.5, HARD 0.75): a **tap** of U, only if U has rested ≥ 10 f and a pip is
    left;
  - otherwise a guard held from now, or a Step if the threat is a lane.
  The third pip is used the same way; P then follows the generic awaken rule.
- **The stance** (`:reflex`, Jilliel): when it perceives an opponent move starting within its reach + 1 m, or a hazard /
  ranged threat within 12 f, it rolls `:stance :p` → U. It can't catch a J1 (§5.5). It **leaves the stance by
  attacking**:
  - on the opponent's whiff or recovery;
  - after `:max` 180 f (3 s, anti-stall);
  - when the gauge is below 30.
  It never holds the stance while the opponent is out of reach and idle (no turtling).
- **Revive**: the generic `:bankai` reflex. Once the kit predicate allows it, P with p 0.9 when the opponent has ≤ 4
  Konpaku or his own Konpaku are already 1. Otherwise it waits (BEHEADED stays).
- **Trompete**: SP2 only when the opponent is ≥ 8 m away **or** in a recovery / reaction (a punish), never into an idle
  opponent within 8 m.

### 11.3 Opponents facing him (two keys read off his kits through `:opp-reflex`, ai.lisp:380; every other pairing's hash stays)

- **`:opp-aim (:step 0.6 :hoho 0.25 :rush 12)`** on `:base` and `:jilliel`. A CPU whose opponent is aiming (a `:hold`
  move with `:x-axis`) rolls once per aim:
  - **after it perceives the lock** (jade; the shot is ≥ 10 f away), with p `:step` × difficulty, a sideways Step off the
    line (HARD perceives in 8 f and makes it; NORMAL's 14 f and EASY's 24 f are late, so they **pre-Step** at a rolled
    frame between the lock and lock + 10);
  - **before the lock**, with p `:hoho` × difficulty (if flash-step ≥ 30), a Hoho behind him (the strongest answer to a
    long aim, rules.lisp:65–71);
  - **within `:rush` 12 m**, the dash-in / O rush instead (Senjumaru's `:opp-rush-hold` path, generalised).
- **`:opp-reflect (:p 0.3)`** on the `:shin` kit: × difficulty (EASY 0.1, HARD 0.5), once per Trompete, a guard pressed
  at a perceived f52 (or a Hoho at f50 when the guard is unavailable).
- **The existing reflexes that would misread his 31 m lines** (gap G1): the generic threat test (ai.lisp:486 counts any
  move within reach + 1.5 m from its first frame, so every CPU would guard through each aim and each wind-up and feed
  the crush), `ken-hoho-commit` (ken.lisp:497) and Ichigo's perfect-Hoho / guard reflexes (ichigo.lisp:791, 803, 858,
  897), which would perfect-Hoho, and so reflect, most Trompetes at HARD p 1.0. For moves flagged `:x-axis` only,
  they use the point-to-line distance and the move's real active window (not the hold phase). The old moves keep the old
  test, so the old pairings stay byte-identical.
- **MUJITTAI**: the anti-ward rule (ai.lisp:62, 191) keys on the `:ward` passive, which the stance carries. Nothing new.

---

## 12. Build list and the generic gaps (character code in `lille.lisp` / `lille-art.lisp`; shared files get hook points only)

| Gap | Where | What |
|---|---|---|
| G1 | ai.lisp, ken.lisp, ichigo.lisp | threat perception for `:x-axis` moves only: the point-to-line distance and the real active window (§11.3) |
| G2 | combat.lisp | `:uncatchable` (KASA's catch skips it). Everything else of "through guard" is the existing hitwin `:chip` / `:guard` |
| G3 | — | none: distance damage is `fighter-dmg-bonus` set from an `:on-frame` hook |
| G4 | combat.lisp | the `:intangible` passive inside the ward branch: drain × `*mujittai-mult*`, no push, no chip (hitwin chip, blade chip, East's pierce) |
| G5 | — | none: the reflect reads `fighter-guard-t` and the Hoho's start in Trompete's own hook |
| G6 | hud.lisp | the kit meter `:draw` for eye pips / halo (Senjumaru's pattern); the `:u-tag` for MUJITTAI |
| G7 | combat.lisp, fighter.lisp | a kit predicate `:bankai-ok` beside `bankai-allowed-p` (BEHEADED + idle / guard / stance); `bankai!` skips the arm-meter line when the form has no `:pips`; a generic `:settled (def lost left)` kit hook in `settle-konpaku` |
| G8 | ai.lisp | `:opp-aim`, `:opp-reflect` (read off his kits) |
| G9 | debug.lisp, DUEL_GAMEPLAY | `roster-pairs` already makes LY LK LR LI LS LL (k 15–20; group 2141); claim the character range **79000–79999** |
| G10 | tests | `duel-rules-test`: the load list, `*forms*` (four: `:base :jilliel :jilliel-mujittai :shin`), clips, weapons, `*roster*` (six), the FK reach list. Host tests: distance damage; four blocked shots crush; stance / armour / DRINK unchanged by `:x-axis`; the lock (no turn after f34, fire ≥ lock + 10); the eye's rest rule, whiff and third-eye EVOLUTION; MUJITTAI pass / no chip / Breaker / drop on attack / no refill, Jilliel's 2.0 / s refill outside it; BEHEADED + the revive cost; the reflect edges (Hoho f47 / f48 / f60 / f61; guard f49 / f50 / f58 / f59); one hit per volley and per MISUJI |
| G11 | kit.lisp, engine hitvol | a `:vols` key in `parse-move` (several volumes in one hit window) and a **yaw offset on `:cap`** (today a cap runs along the facing only, engine/lisp/hitvol.lisp:19–27, 46–54): the volley's five lines |
| G12 | hazards.lisp | a hit group shared by several hazards (MISUJI's three lines overlap near him: 0.34 m apart at 1 m) |

**Art** (`lille-art.lisp`; the rig is the fixed 21-joint humanoid, anim.lisp:48):
- Bodies: `:lille` (base), `:lille-jilliel` (the column + the wings, armless to the eye) and `:lille-shin` (the white
  body, the S-neck and the owl head).
- **Jilliel's front wing pair is parented to the arm chains**, so the J / K wing-tip strikes are measured at the hands
  (`*strikers*` entries). The other six wings are static parts.
- **The owl's extra legs** are static parts on the hips; its arms are the rig's arms, lengthened.
- **The base strikes**: the J plank strikes are measured at a negative weapon-length point (the butt), the K and J3 at
  the muzzle cross (the weapon tip). So the FK reach test (±0.15 m) covers every J / K; no `*lb-strike-reach*` bypass.
- Weapons: Diagramm and the trumpet prop. Strikes for three J / K grids.
- Looks:
  - the aim line, from the `:draw` hook (not a hazard);
  - the volley, beam and ground-line looks;
  - five cinematics.
- Glyphs (万 物 貫 通 眼 神 裁 喇 叭 翼 斉 射 光 明 無 実 体 二 十 四 孔 三 連 飛 廉 脚 照 準 鉤 爪 真 姿 異 端 筋 …)
  are baked with `tools/glyph-bake.py`, which needs `fonttools` + `skia-pathops` installed in the container.

**Order** (one character, one branch; a subagent per batch):
1. rules + host tests;
2. the base kit;
3. Jilliel;
4. the owl;
5. the AI;
6. the HUD;
7. art;
8. the cinematics;
9. the gates.

---

## 13. Balance plan

**Every existing pairing must stay byte-identical** (G2 references, the 15 pairings at seeds 1–20). Everything above is
behind his kit, his hit flags or keys read off his kit.

**The gate grows by six pairings** (k 15–20, debug 2141; 21 pairings, 420 matches). Predictions:

| Pairing | Median guess | Why | Risk |
|---|---|---|---|
| **LY** | 140–180 s | two zoners, but Yamamoto's waves are blocked chips and his Bankai West's ward is drained by the shots | > 210 if both stand off |
| **LK** | 125–150 s | Kenpachi closes and wins up close; Lille's eye and back-slide stretch it | **Lille wins too little** |
| **LR** | 140–190 s | Rukia's rings vs lines (−18 / −50 °C are `:chipless`: no chip from his shots); **zero Rukia is rooted**: her optic ward takes every shot as a full hit at full distance damage | **a rooted zero is free prey**: the user's call (a Rukia or a Lille knob), not pre-tuned |
| **LI** | 135–175 s | Ichigo's rushdown vs the eye; KESSA's parry can't catch a ranged hit | — |
| **LS** | 150–200 s | Senjumaru's zones drain the stance; the shots go through KASA | > 210 |
| **LL** | 170–210 s | a mirror (allowed past 210) | the timer |

- **Win targets**: each new pairing 10 ± 3 of 20.
- **Awaken A/B** (the current criterion, the user's 2026-09-28 decision): P1 Lille in "never awaken" wins ≥ 20 / 60 on
  each of three streams (100 / 300 / 500) against each opponent.
- **The revival gamble test** (Kenpachi's Bankai §9 pattern): LY / LK over seeds 1–60 with the existing Bankai A/B
  (31000 + 10a + b: always / never). The win-rate difference must be within ±9 / 60.
- **Pacing log** (`duel lille` lines, the companion regex already accepts any tag):
  - shots aimed / fired / hit / guarded / stepped / run-across, by distance band;
  - damage by distance;
  - eye openings and what they dodged;
  - awakening tick;
  - stance frames, passes, Breaker breaks, crushes;
  - volleys;
  - BEHEADED / revive ticks;
  - Trompete fired / hit / guarded / reflected, and the reflect's source (Hoho / guard) by pairing;
  - stance time per match and the longest stance (the stall watch, decision 14).

**Knobs, in order**:
- **Medians over 210 s**: the base Z intent 5 → 4, `:opp-aim :rush` 12 → 15, the shot's recovery 26 → 30, the stance
  `:max` 180 → 120 (the CPU's own cap; a self-drain was offered and declined, decision 14).
- **Under 125 s**: `*lb-x-guard*` 30 → 22, the far damage 120 → 100.
- **Lille wins too much**: `*lb-lock-min*` 10 → 14, the far damage 120 → 100, the stance's `*mujittai-mult*` 1.0 → 1.2,
  `*jilliel-gg-regen*` 2.0 → 1.5.
- **Too little**: `*lille-mult*` 1.0 → 1.3 (Rukia / Senjumaru precedent), the eye window 8 → 10, J1 22 → 26,
  `*lb-lock-min*` 10 → 8.
- **The A/B, awakening an upgrade**: `*jilliel-taken*` 1.1 → 1.2, the volley 55 → 48, `*mujittai-mult*` → 1.2.
- **The A/B, awakening a trap**: the volley spread 6° → 5°, `*jilliel-taken*` → 1.0, the stance enter 2 f → 1 f.

---

## 14. Adversarial self-critique

1. **"Through guard" against the sidegrade note's advice** (research sidegrade_design Q4 B.4: a zoner's projectiles should
   not crush from full screen). The user chose the drain (decision 2). What keeps it fair: the shot is a lane, and after
   the lock one Step clears it. It needs a 34 f aim with a visible line, then ≥ 10 f between the lock and the shot, and
   he is planted throughout. The drain needs four blocked shots, about 4.8 s at the minimum cycle. A guard is the wrong
   answer to it on purpose, and the gate measures it.
2. **The first draft let the line track after release** (the review of 2026-10-06, its blocker): a Step out-turns 60°/s
   only within 12 m, so from 12–20 m the shot was a blind guess or a guard. Fixed by **the lock**: from the jade frame
   the line doesn't turn, and the shot is ≥ 10 f away. Before the lock, the answers are the out-turn, the Hoho, or
   cancelling his aim by rushing.
3. **The eye has no cost on a miss.** It is timed like the perfect Hoho, but Hoho costs 30 flash-step. Three uses, no
   refill: at most three free escapes a match. Kept. **The rest rule** (a tap after U was up ≥ 10 f) stops a reactive
   guard spending it, which the first draft would have done in the first exchanges (the generic guard reflex presses U
   during active frames).
4. **MUJITTAI and the phone**: a resting thumb is the stance. A phone player in Jilliel turtles by default, and the
   gauge is the only clock on that. Playtest item, noted in §9.
5. **The owl at 1 Konpaku.** Any K.O. event ends him, so is the revival ever worth it? The CPU rule only revives when it
   is free (own Konpaku 1) or the opponent is ≤ 4. The gamble test checks it either way.
6. **Rooted zero Rukia vs the sniper**: zero can't Step. With 120 a shot at 20 m, LR could fall below 125 s. The answer
   would be the user's (a Rukia knob or a Lille knob); noted, not pre-tuned.
7. **Hit-window lines of 31 m**: the AI's threat test, `snap-reach` and two characters' reflexes were written for ≤ 12 m
   (G1). Restricting the fix to `:x-axis` moves keeps the old pairings byte-identical; it is still the riskiest change.
9. **MUJITTAI and the timer** (found by the review): the stance needs no held button and running keeps it, so a leading
   Lille could run out the clock; only a Breaker or an unguardable reaches him. The user declined a self-drain and chose
   West's rule plus a much slower refill outside the stance (decision 14): the stance is still unbounded in time, but
   every hit it takes is gone for ~50 s. **Open risk**, watched by the pacing log; the CPU's own cap is 180 f.
10. **A free revival** (found by the review): at 1 Konpaku the revive costs nothing, heals fully and breaks the attack
    like a Burst. The user kept it without a cost (decision 15); the gamble test (§13) shows whether it is an upgrade.
11. **Through guard vs stance, armour, DRINK**: the first draft would have turned those full / half hits into 15 % chip,
    and drained gauges that DUEL_DESIGN §4 says they never pay. Now only blocks are X-axis'd. (Found by the review.)
8. **Trompete's reflect is a human's read**: a guard started on f50–f58 (a 9 f window) after a 60 f wind-up with a rising
   pitch, or a Hoho started on f48–f60. That is generous on purpose: the owl is already at 1 Konpaku. Three forms can't
   perfect-guard (West, KESSA, zero Rukia; §6.3).

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

## 16. Questions for the user

Answered 2026-10-06: decisions 12–15 (§1). The volley (five lines, 6°, one hit, 55 flat) and Trompete (60 f, 2.4 m wide,
2 bars, 240; the reflect on a Hoho f48–f60 or a guard f50–f58) stand at the proposed defaults.

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
