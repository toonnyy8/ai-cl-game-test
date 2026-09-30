# SOUL DUEL — Yamamoto Bankai rework: East / West by U (2026-09-27)

Status: **built** (2026-09-27). §0–§7 are the design as the user approved it; §8 records the user's decisions, §9 what
the build does differently, §10 the measurements. The as-built rules live in DUEL_DESIGN.md §2, §4, §5, §6.1, §7.
**Later (2026-09-27, [DUEL_STRINGS.md](DUEL_STRINGS.md)):** East's J / K strings (E-Q1 Q2 E-Q3, E-F1 E-F2) became the
three-link J / K grid (HIZASHI, ZANSHŌ, SENKŌ, KAGERŌ, NISSHŌ, RAKUJITSU; West's J / K still switch him to East and start
East's string), and O is no longer a cancel of any landed move (the O ender follows a link-3 hit); the numbers below
that name the old strings are this document's as of its build.

Source: the user's spec 2026-09-27 (quoted in §0). Replaces DUEL_DESIGN §6.1's
"fed flame", "BURNOUT", "the garb", "the garb vs ranged hits", the East / West move tables' L rows and West's J / K set.

## 0. The spec (verbatim) and the reading

> 山本卍解機制重製
> - U 鍵（防禦）會將狀態從『東・旭日刃』切換成『西・殘日獄衣』
> - 『東・旭日刃』：1 倍傷害 + 額外的 0.1~0.5 倍穿透傷害（依據防禦量表殘餘量影響傷害）、1.5 倍受擊，取消攻擊會減少、恢復自身防禦量表的設計
> - 『西・殘日獄衣』：霸體、完全抵擋傷害（效果與防禦相等、可被破防），可以同時執行其他操作，但一旦發動攻擊 SP1 與 L 以外的攻擊就會回到『東・旭日刃』
> - SP1 維持不同狀態有不同效果，另外『西・殘日獄衣』新增『成功觸發反擊時回滿防禦量表』
> - 為『東・旭日刃』與『西・殘日獄衣』設計全新的 L 技來彰顯各自的特色。

The caller's reading is confirmed, with three flags:
1. "依據防禦量表殘餘量" doesn't say which direction. I read it as **full gauge → 0.5** (Q1).
2. "1 倍傷害 + 額外 … 穿透傷害" reads as the pierce being **extra on every hit**, and also the part that
   **goes through a guard** (Q2).
3. "取消攻擊會減少、恢復自身防禦量表的設計" removes East's recoil (attacking *reduces* his gauge) and the fed flame
   (attacking *restores* it). The spec says nothing about the ×1.3 Bankai drain, the garb's scorch, or the ranged ×0.6.
   They all belong to the fed-flame / garb economy, so they go too (Q6, Q8).

## 1. The rules

### 1.1 State machine

Forms stay kit forms: `:bankai-east` (the awakening enters it) and `:bankai-west`. There is no timer: Bankai lasts to
the end of the match, as now.

| From | Event | To | Notes |
|---|---|---|---|
| East | **U pressed** in a free state (idle, walk, run; buffered 10 f like any press) | West | Takes effect after `*guard-raise*` 2 f, like a guard. Refused while guardless (a dud tick and the grey bar flash). **Not** a cancel of an East move's startup or recovery, and not possible in hit/blockstun (Q5) |
| West | U pressed / held | West | Nothing happens: West already guards. Holding U doesn't root him, so he walks by the stick |
| West | any command other than **SP1** or **L**: J, K, Shift+L (South), I (Breaker), O (TENCHI) | East, **on the move's frame 0** | `try-command` sets the form to East, then starts East's move. The startup is taken at East's ×1.5. A command that East would refuse (an O cooldown, bars) refuses **without** switching (South has no cooldown since 2026-09-28) |
| West | SP1 (GOKUI GAESHI), its counter `:ya-w-counter`, L (SHŌNETSU JIGOKU), Step, Hoho (and the perfect Hoho's auto-strike), the run, Burst Reverse | West | Not attacks under the spec, or part of SP1 / L |
| West | the ward's hit empties the gauge: **GUARD CRUSH** | East, guardless | 40 f reel (`*guard-crush-stun*`), then guardless until full (60 f + 14/s: 8.1 s from 0). The garb gutters out (reuses `vfx-burnout`'s West look) |
| West | a **Breaker** / `:guard-crush` hit: **Guard Break** | East | 50 f stun, −35 gauge, as a guard break on anyone. The garb is blown off (Q4) |
| either | Kikon / Soul Break reset | same form | Guard gauge **refilled to full and guardless cleared, like everyone's** (the carry rule is deleted). The form is kept |
| either | awakening | East | The gauge is left as it is (the "lit: full" rule is deleted) |
| either | a cinematic | — | The sim is frozen and nothing changes |

The **BURNOUT** state is deleted. The crush-to-East rule replaces it: the West crush reel, forced East, and
guardless until full. East has nothing that switches off at gauge 0, because at 0 its pierce is just at its floor
(0.1).

### 1.2 East, Kyokujitsujin (旭日刃): the edge

- Damage dealt **×1.0** (`:mult`; was ×1.2). Damage taken **×1.5** (`*bankai-taken*` 1.2 → 1.5, East only).
- **Pierce** (passive `:pierce`): `k = *pierce-min* + (*pierce-max* − *pierce-min*) × gg / 100` = 0.1 … 0.5, read
  from his own guard gauge **on the frame the hit is applied**. A move may scale it with `:pierce-mult` (KYOKKŌ ×2).
  | Defender's result | What the pierce does |
  |---|---|
  | `:hit` / `:counter` | the hit's damage ×(1 + k): one number, one `deal-damage` (the atk `:mult` becomes `mult × (1+k)`) |
  | `:blocked` (a guard, West's ward, DRINK) | `k × hit-damage` goes **through** as the block's chip. It replaces the 25 % blade chip and reuses `chip-damage`, so it **never kills** (it leaves 1), like all chip. Through DRINK it is added on top of the drunk half and is not drunk. Gauge drain, blockstun and advantage are the block's |
  | `:armored` (CHARGE's armour), `:absorbed` (Kenpachi's stance) | already full damage: ×(1 + k) as a hit |
  | `:parried`, `:guard-break`, `:stance-break` | nothing (no damage) |
  Pierce applies to every hit an East Yamamoto deals: his moves' windows, KYOKUJITSUJIN's cone, and South's bind hazard
  cast in East. TENCHI (O) counts too. A Kikon deals no damage, so pierce doesn't touch it.
- **No guard.** U is the switch (§1.1). Step, Hoho, the run and Burst are unchanged. The guard gauge **refills by the
  universal rule** in East: 12/s once 60 f pass without a drain. East is never "guarding", so GUARD HOLD never pauses it.
  Nothing he does changes his own gauge: recoil and feed are gone.
- Kept: `:projectile-cut` (not mentioned by the spec; it matters only in YY). Q2 and the Breaker are still derived
  (−1 f, reach ×1.15), and so are the J / K set, KYOKUJITSUJIN, South and TENCHI.

Examples (E-Q1 Q2 E-Q3, base 34 + 38 + 55):
| gauge | on hit (was 153 at ×1.2) | blocked: through the guard (was ~38 chip) |
|---|---|---|
| 100 (k 0.5) | 51 + 57 + 83 = **191** | 17 + 19 + 28 = **64** |
| 50 (k 0.3) | 44 + 49 + 72 = **165** | 10 + 11 + 17 = **38** |
| 0 (k 0.1) | 37 + 42 + 61 = **140** | 3 + 4 + 6 = **13** |

### 1.3 West, Zanjitsu Gokui (殘日獄衣): the ward

**The ward** (passive `:ward`, replacing `:garb` / `:scorch`-on-block). While West, his `defender-state` is **`:guard`**
in these states: idle, walk, run, the non-invulnerable frames of Step / Hoho, and **his own moves** (SP1, L). The facing
check is skipped (360°, Q3). So `resolve-contact` returns what a guard gets:

| Incoming | Result on West |
|---|---|
| any guardable melee hit, a hazard / projectile, a `:ranged` window, a guardable Kikon strike | **`:blocked`**, but with **super armour**: no blockstun state, his move or movement goes on. He gets the block's 3 f hitstop and the 0.6 m push slide. The gauge drains the hit's guard value × `*ward-mult*` (1.0; Kenpachi's cut ×1.5 applies first). Chip goes through as for any guard: fire 12 %, NOMIHOSE's blade 20 %, a mirror East's pierce. No scorch. The attacker's contact is `:block`, so his strings chain on block timing and he gets no cancels and no Kikon follow-up |
| Breaker, a `:guard-crush` window (KYOKUJITSUJIN's blade in the mirror, the cash-out within 6 m) | **Guard Break**: 50 f, −35, and **East** (Q4) |
| the ward hit that empties the gauge | **GUARD CRUSH**: the hit is still blocked, then a 40 f reel, East, guardless |
| unguardable: South's bind (a grab), a red victim's Kikon follow-up | hits as usual (`:unguardable` already turns `:guard` into `:neutral`). A bound West stays West, and any hit frees him |
| during Step / Hoho iframes, down, wake-up | invulnerable as usual |

**Not warded:** his reaction states (flinch / stagger / knockback / launch / bound / guard-break / crush reels). A combo
that an unguardable or a Guard Break opened plays out normally, so there are no "armoured combos". His parry's
window frames (f2–25 since 2026-10-01, Ichigo's KUSARI-TATE window; was f4–15) are `:parry` (checked before the ward), so a melee hit there is **parried**, not blocked.

**Movement:** walk 3.2 m/s, run 8 m/s, Step, Hoho, Burst, all unchanged. There is no jump in the game.

**GUARD HOLD applies to West:** every frame he is West (and not guardless) counts as guarding. The gauge **does not
refill** and the 60 f delay is **frozen, not restarted** (`gg-idle-next`). His gauge only comes back in East (or
through the parry, §3). This is the brake on the whole form.

Damage dealt ×1.0, taken ×1.0. Taken matters only for unguardables and a mirror's pierce.

### 1.4 What "full block" doesn't cover (written out)
- **Guard break:** yes, as a guard (Breaker; the `:guard-crush` windows).
- **Grabs / binds / unguardables:** go through (the bind is the only grab in the game).
- **Projectiles:** blocked (hazard guard values: a wave 15, Shiranui 10 → 18, a rift 12). Fire chips 12 %. The
  ranged ×0.6 and the ranged armour are gone: the ward covers everything.
- **Kikon rush strike:** warded (it's guardable), so nothing follows. A red West is safe from the rush until the ward
  breaks. That's the point of West, and a Breaker opens it (§5).

## 2. The two new L moves

Both keep the old L's `:cancel` flag (they end a landed Q / F string), use `:kind :sig` (guard value 18, +4 as an
ender), and take the per-move `:cooldown` the engine already has (the HUD's COOLDOWN bar shows L as it does now).

### 2.1 East L — **旭光 KYOKKŌ** ("the first ray of the rising sun"), `:ya-e-kyokko`

The sun's edge driven through: a one-handed lunge thrust whose point burns through any guard.

| Key | Value |
|---|---|
| Frames | **S15 / A3 / R26** (44 f), whiff R +6 (the universal) |
| Travel | `:slide 1.6` (he lunges 1.6 m over the startup; the existing move key) |
| Volume | a line `(:cap 0.2 4.6 1.1 0.3)`: 4.6 m past the lunge, so it hits at **about 6.2 m** from the start |
| Damage | **85**, knockback 2.0 m, block −12 (guard 22) |
| Pierce | `:params (:pierce-mult 2.0)`: k × 2 = **0.2 … 1.0**. Full gauge: **170 on hit, 85 through a guard** (never kills). Empty: 102 / 17 |
| Cooldown | 100 f from the start (`:cooldown 100`) |
| Cancel | from a landed Q / F (`:flags (:cancel)`): E-Q1 Q2 → KYOKKŌ at full gauge = 51 + 57 + 170 |
| Tracking | 60°/s in the startup (the Signature default) |

**Why it's East:** it turns the one East resource (a full gauge = the sharp edge) into damage that a guard can't stop.
Its risk is East's risk: 26 f of recovery at ×1.5 taken, −12 on block, and no U out of it.

**VFX / audio** (the toon-fire style, no new system): on f1 the ember edge line flares white-hot. f15 is `:on-frame`
`yama-kyokko`: a `:line` hazard **look only** (like `:kyoku`'s sheet, new look key `:kyokko`): a thin white core with
an ember rim along the 4.6 m line, and a small ink sun disc with an ember fill at its tip for 10 f. On a block the
existing guard hexagon, plus a white spark that **exits the defender's back** (the pierce, shown). Callout brush
kanji 旭光 / KYOKKŌ (Latin brush fallback as the other Signatures). SFX `:kikon-slash` + `:sizzle`.

**AI (East):** L weights: close band 0–3 m `:sig 1` → **2**, the 3–6 m band gains `:sig 2`. `:cancel (:sig 0.5)` is
kept (L ends a landed string). A new optional key `:sig-gg 0.6`: below 60 % of his gauge the L weight is halved
(KYOKKŌ is worth it with a full edge).

### 2.2 West L — **焦熱地獄 SHŌNETSU JIGOKU** ("the Hell of Scorching Heat"), `:ya-w-shonetsu`

The garb's promise, "anything that touches it burns": he plants the blade and the 15-million-degree garb erupts
into a ring of fire. Shōnetsu Jigoku is the sibling hell of the Shikai's Ennetsu Jigoku (炎熱地獄), and it reuses
its machinery.

| Key | Value |
|---|---|
| Frames | **S16**, then no hit windows (a hazard does the hitting), **R24** (40 f; `move-end-frame`'s hitless rule) |
| The hit | f16 `yama-shonetsu`: `spawn-hazard :pillars` centred **where he stands** (it doesn't follow him), `:size 3.0`, life 48 f (0.8 s), `:hits 2` (`*hazard-rehit*` 16 f apart), hitwin **45**, `:stagger`, kb 2.0, guard 12, chip `*chip-fire*` |
| Total | 45 or 90 on hit, 24 guard blocked (+ ~11 fire chip), 360° |
| Form | **he stays West** (it's L): the ward stays up through the whole move |
| Cooldown | **150 f** (`:cooldown 150`) |
| Cancel | from a landed Q / F? It can't happen: a West Q / F would already have taken him to East. The flag is dropped |

**Why it's West:** the ward has no blockstun, so this is West's only way to strike back **in the middle of a string**
without leaving the ward. It has a readable tell: the garb flares hard for 16 f (the parry's charcoal column, with
the garb's flames ×1.6). It punishes crowding and a Hoho behind him, and it deals no damage to anyone who stays
3 m out.

**VFX / audio:** reuse the Ennetsu pillars drawn as the garb's FIRE brush-flame tongues round a **charcoal core**,
a `stage-crack-add` 1.5 m ring under him, and the world's ember hue pulses once. Callout 焦熱地獄 / SHŌNETSU JIGOKU
(hanko stamp as the cinematics' captions). SFX `:fire-roar`.

**AI (West):** a new reflex `:ward-reversal 0.35`: when its ward just took a hit, L is ready, and the attacker is
within 3 m, press L with p 0.35 (once per blocked string). Neutral table: close band `:sig 2`.

**Nozarashi note:** his `:projectile-cut` destroys hazards his windows touch, so a cup-1 swing can cut the ring. It
reads right (the blade cuts the fire), so it's kept.

## 3. SP1 in each form

| Form | SP1 | Change |
|---|---|---|
| East | **KYOKUJITSUJIN** (as built: the blade f18–19 breaks guard, the cone at f20, 9 m 25°, 130, ranged, blockable) | The blade's guard break no longer turns off in burnout (burnout is gone, and so is the `:heat` flag). The cone and the blade carry pierce. On West the cone is simply blocked (no ranged ×0.6) |
| West | **GOKUI GAESHI** (the parry: 1 bar, window f4–15 (f2–25 since 2026-10-01), 46 f; a melee catch staggers the attacker 32 f, scorches him 15, and counters `:ya-w-counter` 150) | **New: the catch sets his guard gauge to 100** (`gauges-gg` ← `*gg-max*`, idle counter 0; the spec's 成功觸發反擊 = the catch that starts the counter). He **stays West** through the parry and the counter (both are SP1). If the gauge was guardless… it can't be: guardless means East. The whiffed parry's recovery is warded (spec literal; Q7) |

## 4. Deletions, additions, knobs

### 4.1 Deleted
**tuning.lisp:** `*bankai-feed*`, `*bankai-feed-east*`, `*bankai-drain*`, `*garb-mult*`, `*garb-scorch*`, `*garb-ranged*`,
`*recoil*`, `*chip-blade*`, `*switch-cooldown*`. (`*scorch*` stays for the parry.)
**rules.lisp:** `gg-feed`, `garb-value`, `garb-scorch`, `ranged-damage`, `recoil`, and the burnout gates `heat-mult`,
`armor-budget`, `heat-flags`, plus `chip-rate`'s `heat` argument. `resolve-contact` loses `:ranged-armor`.
`ranged-hit-p` **stays**: the parry still needs "a hazard / ranged hit can't be parried".
**components.lisp:** `burnout-p`, `heat-on-p` (`passive-p` becomes unconditional; CHARGE's armour loses its heat gate).
**kit.lisp:** kit keys `:burnout`, `:feed`, and `kit-atk-mods`' heat argument.
**combat.lisp:** the feed in `deal-damage`; `drain-guard`'s ×1.3 and its `:burnout` emit; the garb branches of
`apply-hit` (ranged damage and armour, the garb value, the ward scorch, East's recoil); the awakening's "lit: full"; the
reset's Bankai carry; the `fed` branch of the gauge tick.
**yama.lisp:** `:ya-to-west`, `:ya-to-east`, West's J / K set `:ya-w-q1 :ya-w-q3 :ya-w-f1 :ya-w-f2 :ya-w-f2q` and its
strings. (West derived Q2 / Breaker from them; West's `:startup-add 2` goes, because a West J / K is East's move now.)
Also the kits' `:burnout :feed :blade-chip`, passives `:recoil :garb`, and West's `:scorch`-on-block (the parry keeps
`:scorch`). `yama-switch` is rewritten as the U-switch / drop hook (below).
**ai.lisp:** `ai-no-armor-p`'s burnout, `ai-gg-low-p`'s burnout, the "burned out: DEFEND / dash-back 0.8" branch.
**hud.lisp / feedback.lisp:** `U: GARB`, the fed flash and "HIT TO FEED", the BURNOUT / REIGNITE text and events (the
`:burnout` event becomes `:ward-crush`, with the same vfx). The garb's fire-hexagon block look (feedback.lisp:91)
**stays**, keyed on `:ward`.
**Docs:** DUEL_DESIGN §4's West-garb bullet and the "Bankai never refills by time" / "except Bankai's" clauses; §4's
armour paragraph's "West's garb against a ranged hit"; §5's East ×1.2 / taken 1.2 / garb-ranged sentence; §6.1's Bankai
rule table, fed-flame table, BURNOUT, "garb vs ranged hits", the L / West rows; §7's Stances bullet (gg-low, burned out,
the fed flame); §2's chip row ("Bankai blade hits (25 %)" → "East's pierce"). History rows in §12 stay, and new ones are
added.

### 4.2 Added (about 60 lines of Lisp, no new subsystem)
- `rules.lisp`: `(pierce-rate gg mult)` → `(* mult (+ *pierce-min* (* (- *pierce-max* *pierce-min*) (/ gg *gg-max*))))`.
- `apply-hit`: `k` from the attacker's `:pierce`. On a hit, the atk `:mult` × (1 + k). On a block, the chip rate =
  `(or hw-chip k)`, and with k the chip is also dealt through DRINK. The **ward**: `defender-state` returns `:guard`
  for a `:ward` form in the states of §1.3, `in-front` is forced to T, and the `:blocked` branch skips `set-blockstun`
  for a ward (keeping the hitstop, a `set-slide` of `*block-pushback*` and the emit). A crush / guard break of a ward
  also calls `set-form :bankai-east`.
- The gauge tick: `guarding` also counts a `:ward` form (not guardless).
- `try-command`: a kit's `:drop-to` / `:keep` (West: `:drop-to :bankai-east :keep (:sig :sp1)`). A command outside
  `:keep` switches the form first (if East's `kit-command-ok-p` passes), then starts East's move.
- The U switch: in the guard-start path, a kit with `:guard-to` (East: `:guard-to :bankai-west`) sets the form instead
  of entering `:guard` (free states only, not guardless). The ward goes up after `*guard-raise*`, counted with the
  existing `fighter-guard-t`.
- The parry catch (`:parried` branch): if the defender has `:ward`, gauge ← `*gg-max*`.
- Moves `:ya-e-kyokko`, `:ya-w-shonetsu`. Hooks `yama-kyokko` (look), `yama-shonetsu` (the pillars). Look keys
  `:kyokko`, and `:garb` for the pillars. Two callouts.

### 4.3 Knobs (starting values)
| Knob | Start | Note |
|---|---|---|
| `*pierce-min*` / `*pierce-max*` | 0.1 / 0.5 | the spec's range; `*pierce-max*` is the East balance knob |
| `*bankai-taken*` (East) | **1.5** | the spec's value; not a tuning knob |
| `*ward-mult*` | 1.0 | West's guard-value multiplier: the **main** balance knob (0.8 buffs West, 1.2 nerfs it) |
| KYOKKŌ | S15/A3/R26, 85, slide 1.6, line 4.6, `:pierce-mult` 2.0, cd 100 | |
| SHŌNETSU | S16/R24, pillars r 3.0, 48 f, 45 × 2, cd 150 | cooldown second knob |
| parry refill | to `*gg-max*` | the spec's value |
| AI | East `:guard` 0.35 → **0.45** (now "go West"), `:gg-low` 0.45 → **0.3** (keep away while refilling); West `:ward-reversal 0.35`, `:sig-gg 0.6` (East) | |

## 5. Balance vs Kenpachi

Baseline: YK median 155.1 s, Yamamoto 7 / Kenpachi 13 (20 seeds). Most of that gap comes before either awakens.

**How much West blocks.** It never refills, so each Kenpachi touch costs him for good. Base Q1 Q2 Q3 = 28 → the **4th
string crushes** him. F1 F2 32. Cups 2 / 3 with the cut: K K 48 → the **3rd**, and NOMIHOSE also chips 20 % through.
The 100 gauge is West's total "life". Crushed means 40 f of reel at East ×1.5, then 8.1 s guardless in East. That's
harsher than today's burnout and is the price of a total block.

**Degenerate strategies and what stops them:**
1. *Permanent West, walking forward.* He deals no damage except L (≤ 90 per 150 f, blockable, 3 m, a 16 f tell) and
   parries (1 bar each). Kenpachi's hits are permanent gauge progress, and his **Breaker** flips him to East at once
   (50 f stun, then a free string at ×1.5). The CPU Kenpachi's Breaker reflex ("a guard held ≥ 24 f within 3 m,
   p 0.4") must **see West as a held guard**: one line in its perception (time in West counts as guard time). A human
   stalemate (both standing off) is a player's choice, and the timer settles it (Konpaku, then Reishi %). CPUs can't
   stall: the anti-stall heat forces attacks, and a West CPU's attack is a return to East.
2. *West + L spam.* The cooldown caps it at 150 f; each use is 24 guard to block and 0 damage if he steps 3 m out. The
   40 f move is warded but not safe from a Breaker (the Breaker breaks a ward). Kenpachi's best answer: stay out of
   3 m during the tell, and Breaker the recovery.
3. *Mashing out of pressure from West.* No blockstun, but any J / K / O / I puts him in East **on frame 0**, so the
   startup gets hit by Kenpachi's next string hit (the chain gap is 6 f; E-Q1 is 8 f) at ×1.5. Frame advantage still
   rules: West only removes blockstun from **waiting**, not from **acting**.
4. *East ↔ West ping-pong to refill.* A refill needs 60 non-West frames since the last drain (the counter is frozen in
   West, not restarted), then 12/s: from 30 to 100 takes about 6.8 s in East. And U can't cancel an East move, so every
   blocked East ender (−12) is punishable at ×1.5.
5. *Parry fishing in West.* A whiff costs a bar (the recovery is warded); a catch gives 150 and a full gauge. Reiatsu
   (+3/s, 100 per bar) makes this about 1 per 25–35 s. Watch it; the fallback (Q7) is to take the ward down during
   the parry's recovery.
6. *East at full gauge, glass cannon.* ×1.5 dealt against ×1.5 taken. East still has U as a reactive "guard" in
   neutral, so ×1.5 bites only on commits (startups, recoveries, a crush), which is where it should bite.

**AI changes:** East's `:guard` is now "go West" (the generic neutral guard and the committed-move guard press U, and
`ai-guard-mult` already keeps a low-gauge East out of West). East's `:gg-low 0.3`: DEFEND / dash-back while it
refills. West's table: intents DEFEND 2 / PRESSURE 2 / APPROACH 2; close band `:q 3 :f 2 :sig 2 :breaker 1 :sp2 1
nil 3` (every non-L pick goes back to East); `:react (:flash-startup :sp1)` kept (the parry); `:ward-reversal 0.35`
(new). The burned-out branch goes. Kenpachi: his Breaker reflex treats West as guarding (above). Nothing else: the
"hunt a gauge under half" rule already exists and does the job.

**Expected effect (to measure, not a promise):** Bankai becomes sturdier (West takes about 0 Reishi until broken) and
more swingy (East ×1.5 both ways). Guess: YK Yamamoto **9–11 / 20**, median **150–170 s** (West absorbs time, East
trades speed it up). The risks are a median over 210 s (West stalls) or KO failures, so the gate stays: 20 seeds ×
YY / YK / KK, all K.O., median 125–210 s. Tune in this order: `*ward-mult*`, then `*pierce-max*`, then the
SHŌNETSU cooldown.

## 6. Self-critique (adversarial) and revisions

| # | Sev | Finding | Resolution |
|---|---|---|---|
| 1 | BLOCKER | A West that wards in **every** state would ward the follow-ups of a combo an unguardable (bind) or a Guard Break opened: armoured combos and an unkillable bound West | §1.3: the ward is off in reaction states (hitstun, bound, the guard-break / crush reels); a crush / break also forces East |
| 2 | BLOCKER | West's ward + no blockstun + a 150 f reversal L could leave Kenpachi CPUs without a way in, so matches stall past 300 s (the gate requires all K.O.) | No refill in West (GUARD HOLD), the Breaker flips West to East, Kenpachi's Breaker reflex sees West as a held guard, AI West attacks = East. Measure; `*ward-mult*` is the first knob |
| 3 | MAJOR | "Drop to East when attacking": if the drop happened on the hit frame (like the old L switch), West startups would be warded, so every West attack would win trades | Drop on **frame 0**; a refused command doesn't switch (§1.1) |
| 4 | MAJOR | If U could cancel an East move's recovery, every East ender would be safe (punish → ward) | U only from free states (Q5) |
| 5 | MAJOR | Pierce on hit makes East ×1.5 at full gauge (was ×1.2), on top of a near-immune West: Yamamoto may overshoot | Pierce ×(1+k) is the spec's reading (Q2). `*pierce-max*` knob; expected gauge in East is often < 100 because West spends it |
| 6 | MAJOR | Parry whiffs are free in West apart from the bar | The spec keeps SP1 "as it is" in West; noted as Q7 with the knob ready (ward off in the parry's R) |
| 7 | MAJOR | Phone: a resting thumb is U, so resting in East flips to West, and a one-hand player can't "stay East and wait" | Resting = defend is the phone grammar; one line added to DUEL_MOBILE_DESIGN §3.2 (East → West on rest; it doesn't flip back) |
| 8 | MINOR | Pierce through DRINK stacks with the taken half: cup 3 drinking East is worse | The spec says pierce penetrates; DRINK is still half plus pierce, fine |
| 9 | MINOR | Nozarashi's projectile cut deletes SHŌNETSU's pillars | Thematic; kept (§2.2) |
| 10 | MINOR | The perfect Hoho's auto counter-strike from West: is it an "attack"? | Part of Hoho, not an attack button: stays West |
| 11 | MINOR | `ranged-hit-p` looks dead after the garb | Still gates the parry (hazards / ranged hits can't be parried); kept |
| 12 | MINOR | A crush now costs 40 f + 8.1 s in East at ×1.5 with no guard; harsher than burnout | It's the price of "full block" and a knob family exists (`*guard-crush-stun*` is universal, so don't touch it; use `*ward-mult*`) |
| 13 | MINOR | East keeps `:projectile-cut`, which the spec doesn't mention | Kept (YY only); dropping it is one word |

Revisions applied in the text above: 1 (§1.3 "Not warded"), 3 (§1.1 frame 0), 4 (§1.1 U row), 7 (mobile note in
§6), 2 (§5 AI line for Kenpachi's Breaker perception).

## 7. Questions for the user (each with a recommended default)

1. **Pierce direction:** more pierce with a **fuller** gauge (0.5 at full, 0.1 at empty) or with an emptier one? →
   **Fuller** (East is sharpest when rested; an empty-gauge peak would reward getting crushed in West).
2. **Pierce on clean hits too** (total ×1.1–1.5), or only the part through a guard? → **Both** ("1 倍 + 額外").
3. **West's coverage:** 360° (a garb) or the guard's 200° front (a Hoho behind still hits)? → **360°**.
4. **A Breaker on West:** Guard Break **and back to East**, or Guard Break and stay West? → **Back to East** (the
   anti-turtle key).
5. **Can U cancel an East move's recovery into West?** → **No**, free states only (else East enders are safe).
6. **The ×1.3 Bankai drain** (your 2026-09-26 nerf) belonged to the fed flame: delete it? → **Delete**; `*ward-mult*`
   takes over.
7. **A whiffed West parry:** does its 30 f recovery stay warded (your spec, literally) or open? → **Warded** at first;
   open it only if parry fishing shows in play.
8. **West's scorch on blocked melee** (guard v3) isn't in the new spec: remove it? → **Remove** (the parry keeps its
   scorch).

## 8. The user's decisions (2026-09-27)

The user accepted **every recommended default** of §7:

| # | Question | Decision |
|---|---|---|
| 1 | Pierce direction | **full gauge = sharpest**: k = 0.1 at empty .. 0.5 at full (`*pierce-min*`, `*pierce-max*`) |
| 2 | Pierce on clean hits too | **both**: a hit deals ×(1 + k), a blocked hit lets k × its damage through |
| 3 | West's coverage | **360°** |
| 4 | A Breaker on West | Guard Break **and back to East** |
| 5 | U cancelling an East move's recovery | **no**: U switches only from free states (idle, walk, run) |
| 6 | The ×1.3 Bankai drain | **deleted**; `*ward-mult*` takes over as West's knob |
| 7 | A whiffed West parry | its recovery **stays warded** |
| 8 | West's scorch on blocked melee | **removed** (the parry keeps its scorch) |

The same day the user also asked for **a much slower guard-gauge refill for every character**
(「大幅減少防禦量表的恢復速度」): `*gg-regen*` 12 → **5.5**/s and `*gg-regen-guardless*` 14 → **6.5**/s (46 %; the
60 f delay, GUARD HOLD and the frozen delay are unchanged).

## 9. As built: what differs from §0–§7

- **SHŌNETSU JIGOKU's ring is 2 m, not 3 m.** Ennetsu's `:pillars` hazard is a hollow ring (7 pillars r 0.7 m on the
  circle), so at 3 m it missed an attacker crowding him at 1–1.8 m, which is the whole point of the move; at 2 m it
  covers 0.9–3.1 m from him (nothing beyond 3 m, as designed).
- **SHŌNETSU's look reuses Ennetsu's pillars as they are** (not redrawn as garb tongues round a charcoal core). The tell
  is the garb aura flaring ×1.9 and fading over the startup (`model-flare`) plus the parry's charcoal column; the
  eruption adds the garb's flung ring of flames (`vfx-garb-flare`) and a 1.5 m plaza crack. No world ember pulse.
- **KYOKKŌ's clip is E-Q3's thrust** (`:ya-e-thrust`, played at 11/15 speed so it reaches its hit pose on f15; the 1.6 m
  lunge is the move's `:slide`). Its f1 tell is a 0.2 s rim-light flash and a sizzle; its f15 look is a new `:line`
  hazard look `:kyokko` (a white-cored ember lens at chest height along the line, an ink sun with an ember fill at the
  tip). The pierce's "spark out of his back" shows on every blocked pierce hit (any East move), not only KYOKKŌ's.
- **One L cooldown slot.** Cooldowns are per command slot, so KYOKKŌ's 100 f and SHŌNETSU's 150 f share L's slot:
  using one cools the other for what is left.
- **The ward-reversal reflex** rolls once per opponent move (the CPU's reaction roll), not once per blocked string.
- **The ward's raise** (2 f) is counted by `fighter-guard-t`, which runs while he stands or walks in West; a Step or an
  SP started within those 2 f is not warded yet.
- **Callouts**: brush kanji 旭光 / 焦熱地獄 (光 焦 熱 baked into `glyphs.lisp`), the Latin readings KYOKKO / SHONETSU
  JIGOKU without the macron (the brush Latin set has no Ō).
- **The ward's block look** reuses the garb guard's fire hexagon (and flares the garb); a broken ward reuses the old
  burnout's gutter look (`:ward-crush` event).
- **HUD**: the awakening row tags `U: WEST` (East) / `WARD` (West); the Bankai guard bar stays ember (East's pierce reads
  it), 30 % darker in West (it never refills).
- **West's `:startup-add 2` went** with West's J / K set: West has no derivation, so it takes East's versions of every
  inherited move (the drop starts East's own move anyway).
- Deleted with the old economy beyond §4.1's list: the `:ash` aura, the ash blade look and the `:ash` world grade (the
  burnout looks), HIGASHI's crescent (`vfx-higashi`, the `:sweep` stamp), the "HIT TO FEED" hint and the fed bar's flash.
- Runtime knobs for tuning without a rebuild: debug 20000+k `*ward-mult*`, 21000+k `*pierce-max*` (k / 100), 22000+k /
  23000+k the two refill rates (k / 10).
- **Knobs as tuned**: `*pierce-max*` 0.5 → **0.45** (k 0.1–0.45; KYOKKŌ 0.2–0.9: 162 on hit / 77 through at a full
  gauge) and `*ward-mult*` 1.0 → **1.1** (Kenpachi's base Q string still crushes on the 4th, RYOTE's K K now on the
  2nd). `*bankai-taken*` stays the spec's 1.5.

## 10. Measured (the seed gate, 2026-09-27)

Debug 2113 (`tests/scripts/duel-gate.json`), 20 seeds per pairing, NORMAL CPUs, cinematics included:

| Pairing | Median | Range | K.O. | Wins P1 / P2 |
|---|---|---|---|---|
| YY | 128.6 s | 88.2–160.2 | 20/20 | 14 / 6 |
| YK | 129.9 s | 96.3–153.2 | 20/20 | Yamamoto 10 / Kenpachi 10 |
| KK | 169.2 s | 111.9–196.9 | 20/20 | 15 / 5 |

Before the rework (guard v3 + its follow-up): YY 165.3, YK 155.1 (Yamamoto 7 / 13), KK 169.2 s. Sweeps (runtime knobs,
same seeds; YY / YK medians, YK Yamamoto wins): ward 1.0 pierce 0.5 → 129.4 / 123.6, 9; ward 0.8 → 129.4 / 123.6, 13;
pierce 0.4 → 124.0 / 130.3, 13; ward 1.2 pierce 0.4 → 119.6 / 130.3, 14; ward 1.1 pierce 0.5 → 129.4 / 126.4, 9;
**ward 1.1 pierce 0.45 → 128.6 / 129.9, 10**; guard refill 6.0 / 7.0 (at 1.0 / 0.5) → 129.4 / 123.6, 10. Twenty matches carry about
±2 wins and ±5 s of median noise, so the choice is the pair inside both targets, not a fitted optimum.

Usage in the 20 YK matches: 177 switches to West, 48 broken wards (1 GUARD CRUSH, the rest Kenpachi's Breaker reflex
seeing the ward as a held guard), 80 KYOKKŌ, 20 parries, 5 SHŌNETSU JIGOKU (YY: 306 / 51 / 128 / 25 / 14). The CPU uses
SHŌNETSU rarely (the ward-reversal needs a hit within 3 m with L ready and a 0.35 roll); a human will use it more.

The G2 determinism reference changed for every pairing; YK (seed 7) now ends `duel -> RESULTS winner P1 konpaku 2-0
ticks 7688 secs 128.1` (`tests/style-cvc-ref.txt`).

## Playtest decision: South has no cooldown (the user, 2026-09-28)

「山本的『南』本身就是消耗靈力計量表使出的 SP2，不需要有冷卻。」 MINAMI (South, `:ya-kaka`, his Bankai SP2) loses its
600 f cooldown: like every SP2 its only limiter is the Reishi bar cost (2 bars).

**Built (2026-09-28).** `:ya-kaka` has no `:cooldown` (its comment says so); nothing else in the game had a Shift+L
cooldown, so the HUD's thin ember line under the L bar (`hud-cooldowns`' Shift+L path) and the second `*refused-t*` slot are
deleted: the COOLDOWN row is one L bar (KYOKKŌ's 100 f / SHŌNETSU's 150 f), which is also all a refused press can flash.
`ai.lisp` had no South-cooldown assumption (its weights and the trap reflex never read `fighter-cd`); in the logged YK
gate (debug 2115, 20 seeds) the CPU cast South 8 times, no spam, so no AI gate was added. The G2 reference: YY (seed 7)
keeps its result `winner P1 konpaku 2-0 ticks 9248 secs 154.1`; only its t=6600 hash line changed (South's cooldown slot
reads 0 instead of 220). Seed gate (with the Rukia rework and Kenpachi's one pip per string): DUEL_RUKIA.md, "Measurements
(the cold gauge rework)".

## Bankai East's guard refill (2026-09-30)

The user: 「大幅降低山本『東 旭日刃』時的防禦量表恢復速度」. A new generic kit key `:gg-regen` (x the guard gauge's refill
rate in the form, default 1.0; rules `gg-regen`'s MULT) and Bankai East sets `*east-gg-regen*` **0.5**: 5.5 -> 2.75 / s,
guardless 6.5 -> 3.25 / s, a BLUE burst's boost from that. West (which inherits it) never refills anyway, so East's refill
is his whole one; the pierce (fuller gauge, sharper blade) and West's ward last half as long between refills.
Native gate (seeds 1-20): YY 165.9 s, YK 159.1 (Yamamoto 14 / 20), RY 161.5 (10 / 10), IY 194.2 (10 / 10), SY 158.5
(Senjumaru 11), all K.O. and in the band. G2: yy's hash lines and yk changed (yk now `winner P2 konpaku 0-1 ticks 10983
secs 183.1`), kk unchanged.

**Then x0.25, guardless unchanged (the user, the same day: 「破防後恢復速度不變，但東的恢復速度改成原本的 1/4」):**
`*east-gg-regen*` 0.25 (5.5 -> 1.375 / s) and `gg-regen` applies MULT only when not guardless (6.5 / s after a crush, as
everyone). Native gate (seeds 1-20): YY 165.9 s, YK 166.9 (Yamamoto 13 / 20), RY 160.7 (Rukia 13), IY 181.3 (Yamamoto
13), SY 157.5 (Yamamoto 11), all K.O. and in the band. G2: yy's hash lines and yk changed (yk now `winner P2 konpaku 0-1 ticks 10288 secs 171.5`).
