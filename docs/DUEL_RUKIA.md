# SOUL DUEL: Kuchiki Rukia (TYBW), Sode no Shirayuki and 絶対零度 ZETTAI REIDO

Status: **built 2026-09-28** (the design of 2026-09-28 with the user's decisions of the same day, §"User decisions"
below, which override the body where they differ). It sits on the user's decisions of 2026-09-27 / 28: the research report
`reports/血戰篇四角色格鬥設計研究.md` (its Rukia section, the six sidegrade rules, questions 1–5 and 7–11 at their defaults,
question 6 overruled: an awakened Kikon still takes 3), the Soul Break rule (count + 1, cap 5, the attacker's current Kikon
cinematic), unskippable battle cinematics, and the brief (awakening = the true-Shikai ability, 白霞罸 = the awakened Kikon
cinematic, awakening never heals, awakened vs base differ in playstyle and not in power; **relaxed by the user on
2026-09-28**: the awakening may be the stronger choice as long as not awakening can still win, see "The awaken A/B across
seed streams" at the end). The body below is the design as
approved (numbers were proposals); the as-built values are in "Built: deviations", `duel/lisp/tuning.lisp` and
`duel/lisp/rukia.lisp`; the measurements close the file. **The awakening was rebuilt the same day as a cold gauge of two
stacked bars** (playtest 1 and the decisions after it): §4 and §8 describe the rework as built; its deviations, knobs and
measurements are in "The cold-gauge rework: built" near the end.

## Summary

- **Look**: in TYBW Rukia is the 13th Division's **lieutenant** (Captain only ten years after the war): a black shihakushō,
  the lieutenant's armband on her left upper arm, **no haori**. About 1.44 m, the one black silhouette on the plaza: white
  only in the blade, the snowflake guard and the pommel's ribbon. Ice is mono (white and cold grey): no fourth spot hue.
- **Shikai 舞え、袖白雪, a dancer who places ice**: a fast, short J; K hits leave **frost** (the one new status: walk and run
  ×0.7; Step and Hoho untouched). The awakened forms frost on every hit (30 f as built).
- L 初の舞・月白 TSUKISHIRO: a visible circle under the opponent (≤ 8 m); 24 f later a pillar of ice freezes whoever is in it.
  Guardable, one Step clears it, it vanishes if she is hit first, one at a time.
- SP1 次の舞・白漣 HAKUREN: held, one to four stabs into the plaza, then a wide wave of cold that a side Step clears. SP2 参の舞・
  白刀 SHIRAFUNE: a 5 m ice-blade thrust. I = 縛道の四・這縄 HAINAWA (the Breaker). O = ENBU, a flash-step rush into a spin.
- **The awakening 絶対零度 (no heal)**, rebuilt 2026-09-28 (the temperature rework, §4): **one cold gauge, two stacked
  bars (cold C 0–200)**. Guarding cools her (90 / s: a bar in 1.1 s), not guarding warms her, blocked blades cool her, real hits warm her.
  Bar 1 full → −50 °C; both full → −273.15 °C; bar 1 empty again → −18, bar 2 empty → −50. Actions spend cold (at −18
  only L, refused below its cost). Colder is slower (walk 3.4 / 2.8 / rooted) but hits harder and farther with other
  motions, the L family grows (霜柱 r 2.5 → 氷震 r 3.5 → 零度凍結 r 5.5), and her cold field 寒域 slows the opponent's
  retreat (r 3 / 4 / 5.5).
- **−273.15 °C** (both bars full): rooted; the strongest version of every button; a 360° guard with no blockstun (West's
  ward) that never refills; **the first melee hit it blocks freezes the attacker 18 f**; **projectiles, hazards and
  :ranged hits pass through it (canon's optical loophole)**. Holding U **braces** (the warming stops, the guard gauge
  drains 8 / s). No chosen exit: she leaves by spending the top bar, by warming (slowly: 20 s unbraced, the user's decision), or by the forced
  **CRACK** (the ward crushed or broken: the gauge empties, 60 self-damage, a 30 f crumple, 2 s of THAW lock).
- **The awakened J / K**: the Shikai grid, frost on every hit (30 / 60 / 90 f), reach ×1.0 / 1.1 / 1.35 by band, plus
  bare-hand / ice links (K1 凍手 TŌSHU and K3 氷華 HYŌKA; at zero a palm backhand J2 and a 4.3 m ice thrust K1).
- **The trade**: against Kenpachi's close pressure the awakening pays (zero freezes his strings); against Yamamoto the
  fire passes through zero and the Shikai's footwork is better. The CPU awakens only when ≥ 60 % of what it took came from
  blades.
- **Kikon cinematics**: Shikai 初の舞・月白 (2 Konpaku, 186 f); awakened 卍解 白霞罸 (3 Konpaku, 198 f); the awakening 132 f; all
  unskippable.

---

## 0. Frame of reference

- Conventions: DUEL_DESIGN §0 (60 Hz, S/A/R, move frame 0 = first frame). Every J/K form obeys the DUEL_STRINGS §2.1 budget
  (host-tested per form). Names are TYBW-register romaji in the callouts, kanji in the brush columns.
- Canon marks: **[V]** verified in the research notes (chapter / episode cited there), **[A]** anime-only, **[G]** our game
  interpretation or an invented name. Sources: `research_notes/血戰篇四角色格鬥設計研究/rukia_tybw.md` §1–§5.
- The canon costs this design encodes, each as the opponent's counterplay verb (sidegrade_design Q3):
  | Canon | Mechanic | The opponent's verb |
  |---|---|---|
  | ~4 s at −273.15 °C [V ch. 567 / ep. 385] | the zero window is 240 f | wait it out at range |
  | thaw slowly or crack [V ch. 568 p1, ch. 570] | the cold gauge warms back gradually; forced → 手裂 CRACK (the gauge emptied, self-damage) | wait out the warming; force the crack (Breaker, crush) |
  | whatever touches her freezes [V ch. 567, ch. 570] | the first warded melee hit at zero freezes the attacker | don't strike her at zero |
  | optical attacks still work [V ch. 568 p13] | hazards and `:ranged` windows ignore the zero ward | shoot her |
  | mobility limited by the cold [V wiki "Mobility"] | walk / run fall with each step; rooted at zero | out-walk her, zone her |
  | −18 °C blood won't flow; −50 °C ice quake [V ep. 385] | −18: no chip on her, frost on her hits; −50: 氷震 | respect the quake's 3 m |

---

## 1. Summary

At the top of this file (the player-facing zh-TW text is in docs/TUTORIAL.zh-TW.md, the build notes in docs/DEVLOG.zh-TW.md).

---

## 2. Identity and silhouette

**Rank check.** In TYBW Rukia is the **lieutenant of the 13th Division**. She is made Captain only ten years after the war
(ch. 685–686, per the research notes). So there is **no captain's haori**: a black shihakushō, the lieutenant's armband on her
left upper arm (white band, the division's snowdrop badge and 十三 in ink [verify the badge art against the TYBW anime model]),
white under-collar, white tabi. She has the post-Fullbring **short black bob** with the strand of hair down between her eyes.
In the Soul King Palace arc her clothes were remade by the Royal Guard; the Bankai destroys them [V ch. 570 p7]. In
gameplay she wears the plain black shihakushō look, which is what the anime shows through the Äs Nödt fight
[verify the collar cut on the ep. 385 model sheet].

**Weapon.** Sealed: a plain katana (the intro only, `:ru-katana`). Released 「舞え、袖白雪」 [V]: she turns the blade
counter-clockwise, and blade, hilt and guard turn **pure white**. The guard becomes a **hollow snowflake ring** and a
**long white ribbon** trails from the pommel (`:sode-no-shirayuki`). The ribbon is an fx ribbon along the pommel's
position history (the sword-trail machinery), not geometry. It hangs when she is still and streams through spins. The
Bankai's transparent-ice blade (`:ru-ice`) is used only in the 白霞罸 cinematic.

**Proportions.** Canon 144 cm. `:scale 0.80 :width 0.92 :hunch 0`. The hurt cylinder is **r 0.34, h 1.50**, not her true
~0.30 / 1.44: a fairness floor, so arcs built against 0.36 / 1.65 bodies don't pass over her (§11 M5).

**Palette** (v4 notan, STYLE_STORM §A.1, §2.5; no spot hue of her own):
| Key | Lit | Note |
|---|---|---|
| `:black` | #16161E | the robe: one solid black mass (V0), cold-grey keyline #4A5062 |
| `:hair` | #0C0C12 | solid black with **three white highlight strokes** #D8DCE4 (Kubo's white-on-black), the strand between the eyes |
| `:skin` | #DCC0AE | muted (S ≤ 0.3), the only warm non-spot colour |
| `:white` | #ECECE8 | under-collar, tabi, armband; shadow cold grey-blue |
| `:badge` | #101018 | ink on the armband (十三, the snowdrop) |
| `:pupil` | #4A4460 | a desaturated violet-grey (her anime violet eyes, kept under S 0.3) |
| `:brow` | #0C0C12 (the hair's) | the brows' own key, so the white variants can tint them apart from the white hair: #CFE3F2 (a pale ice white, blue-tinted) |
| keyline | `*body-ink*` | the white variants (`:rukia-zero`, `:rukia-bankai`) override it per body: #7F97B4 ice blue on every shape (`body-variant :ink`; STYLE_STORM_DESIGN palette, ICE keyline) |
| blade / guard / ribbon | #F4F6F8, shade #9AA8BE | the SOUL-glass tones: white with a cold shade |

**Ice is mono.** Every ice effect uses white cores and the **SOUL glass** palette (#FFFFFF / #E6ECF4 / #9AA8BE, edge in its
shade), never STEEL. STEEL stays the guard / Burst tint, so a zero ward's shimmer is not mistaken for a guard spark (§11 M8).
No fourth spot hue is added, and the 15 % spot budget is untouched. Her only colour is BLOOD, which is universal: the Kikon and
the crack on her hand.

**How she reads against the other two.** Yamamoto: hunched old man, white haori, FIRE. Kenpachi: 2 m, white sleeveless
haori, yellow REIATSU. Rukia: small, **all black**, one white line (blade and ribbon) and cold mist. She is the value
inversion of both men, which is Kubo's notan again. At range the white ribbon is her silhouette cue, as the haori is theirs.

**Temperature look** (her state is read on the model, not only the HUD; report risk 4):
| Step | Look |
|---|---|
| base | none; the ribbon moves freely |
| −18 °C | a white **breath puff** every 40 f; the ribbon stiffens (hangs straight); frost motes at her feet |
| −50 °C | + **ice rims** on the sleeve hems, collar and hair tips (tag `:ice-trim`, SOUL glass); aura `:frost` (low white mist, rising motes); the plaza whitens in a 1 m disc under her; the **rimed blade** `:ru-rime` (an ice edge, crystals along its back; the rework) |
| −273.15 °C | body variant `:rukia-zero`: **hair and irises white** (canon Bankai colouring, the user's "white hair / ice crystals"), skin cold-shifted #D6CCCA, a **half-crown of ice** behind the head (tag `:ice-crown`), shoulder crystals; **brows a pale ice white #CFE3F2 and an ice-blue keyline #7F97B4 on every shape** (the user's decision 2026-09-28: the white Rukia is outlined in ice, not ink); the ice blade `:ru-ice` in play (the rework); no breath; aura `:zero` (a thin white ring at her feet and still motes) |
| every band | the **field ring**: a white ring on the plaza at the band's field radius (3 / 4 / 5.5 m), drawn by the band's aura |
| CRACK | an event (the rework: no longer a form): a BLOOD hairline across the cold gauge, the hand-crack sound, "CRACK", her crumple |
| 白霞罸 (cinematic only) | body variant `:rukia-bankai`: ankle-length white kimono (`:black` → #EEEEEA), ice collar and shoulder pieces, ribbon loops at her back, an ice flower on the chest, the half-crown, white hair [V ch. 570 pp6–7]; the same **ice brows and ice-blue keyline** as zero |

---

## 3. Base kit: Shikai 舞え、袖白雪 (form `:base`)

Identity: RoS's 「小回り」 made 3D. A nimble mid-range **placer**: she wins by where the ice is, and her J beats most K's.
Walk **3.8 m/s**, run **9.0 m/s** (between Yamamoto 3.2 / 8 and Kenpachi 4.4 / 10; tuning knobs `*walk-rukia*`, `*run-rukia*`).
Kikon **2**, Soul Break 3.

### 3.1 The one new status: 霜 FROST
- A victim's timer (frames). While it is > 0 his **walk and run speed are ×0.7** (`*frost-slow*`). Step, Hoho, lunges,
  Breaker / Kikon dashes and every frame number are **unaffected**, so the universal escapes and the frame budget stay intact.
- Set on a **real hit** (`:hit` / `:counter`) by a hitwin's `:frost n` (or the awakened passive `:frost-touch`): the timer
  becomes max(current, n), capped at 150. It never stacks.
- Look: an ice crust on his feet and shins (SOUL-glass shards) and a white breath puff. HUD: nothing (read on the model).
- Why: in 3D a zoner has to control walking. Frost makes walking out of Tsukishiro fail and Step succeed. It is the
  3D "force the Step" rule, not a damage bonus.

### 3.2 J / K grid (DUEL_STRINGS §2.1; K2 / K3 at 80 % as for every form)
| Link | Name | Clip | S/A/R (enter → S_eff) | Dmg | React | Blk | Whiff | Volume | Guard | Extra | Pose (one line) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| J1 | 初霜 HATSUSHIMO `:ru-j1` | **new** `:ru-q1` | 7/3/12 | 34 | flinch | −2 | 20 | **1.44 m** 100° (2.4 before the J cut, §3.2 note) | 8 | — | from a low forward stance, a one-handed flat cut, the ribbon trailing the arc |
| J2 | 風花 KAZAHANA `:ru-j2` / `:ru-j2s` | **new** `:ru-q2` | 7/3/13 | 34 | flinch | −2 | 21 | **1.32 m** 100° (was 2.2) | 8 | — | the wrist turns over, a backhand along the same line; the ribbon flips over the blade |
| J3 | 舞袖 MAI-SODE `:ru-j3` (ender) | **new** `:ru-spin` | 9/3/18 | 42 | stagger | −4 | 26 | **1.56 m** 200° (was 2.6) | 8 | — | a full pirouette on the ball of the foot, the blade at arm's length and the ribbon whipping round: "the dance" |
| K1 | 霜突 SHIMO-TSUKI `:ru-k1` | **new** `:ru-thrust` | 17/4/20 | 66 | stagger | −3 | 32 | line 0.2 → **2.8** (was 3.2) | 14 | frost 60 | a fencer's lunge, back arm out for balance, the white point driven straight |
| K2 | 氷輪 HYŌRIN `:ru-k2` / `:ru-k2s` | **new** `:ru-ring` | 21/4/24 (7 → 14) | 58 | stagger | −3 | 36 | **2.5 m** 140° (was 2.8) | 14 | frost 60 | a rising turn; the snowflake guard traces a white ring for 3 drawings |
| K3 | 雪崩 NADARE `:ru-k3` (ender) | **new** `:ru-drop` | 21/5/34 (7 → 14) | 84 | crumple | −20 | 46 | line 0.3 → **2.7** (was 3.0), h 1.2 | 18 | frost 90 | both hands, the blade high and held 3 f, dropped; snow bursts from the plaza at the point |

- Budget check: J1 7, J2 7, J3 9 (7–10 / 7–9 / 8–10); K1 17 (16–20; K1 − J1 = 10 ≥ 7); K2 / K3 S_eff 14; R and block advantage
  exactly the budget's. K2 / K3 combo after a J (A 3 + 14 = 17 ≤ 17) and after a K (≤ 21).
- Routes on hit: JJJ 110, JJK 152, JKK 176, **KKK 208**, KKJ 166, KJJ 142; + the O ender 63. Kenpachi's base KKK is 210: she is
  equal in the strings and pays her zoning for it with the lightest J1 (34).
- Blocked: JJJ 24, KKK 46 (the universal numbers).

### 3.3 The rest of the buttons
| Input | Move | S / A / R | Dmg | Block | Notes | Pose |
|---|---|---|---|---|---|---|
| L | **初の舞・月白 SOME NO MAI: TSUKISHIRO** `:ru-tsukishiro` [V ch. 201] | 10/0/26 (36 f; hazard only) | 60 | guard 14, fixed 14 f blockstun | at f10 the point under the opponent is sampled (`cast-point`, ≤ **8 m**) and a **white ring r 1.8 m** is drawn on the plaza: the tell. **24 f later** (f34) the pillar erupts: a disc hazard (the `:bind` kind) r 1.8, h 3.0, active 8 f. A hit **freezes** (the `:bind` reaction, 36 f; an opener books 2 combo hits, so he may Burst) + frost 90. It is **guardable** from her side (the hazard's source is her position, §10 gap 4), **fragile** (it vanishes if she is hit before it erupts), cooldown **150 f** (so one ring at most). Escape: Step out (r 1.8 + hurt 0.45 = 2.25 < 2.5), Hoho, or guard. Walking out from the centre in 24 f: Yamamoto 1.3 m, Kenpachi 1.8 m, both short of the 2.2 m needed (less when frosted). **After a K link** (K1 / K2 / K3, playtest 2): the combo copy `:ru-tsukishiro-k`, 8/0/26, the ring at f8 and the pillar 10 f later (f18), the same cooldown; in a combo its freeze is a flinch (a `:bind` only opens a combo) | the blade tip drawn round in one sweep, the body turning with it, the ribbon trailing the circle |
| Shift+K | SP1 **次の舞・白漣 TSUGI NO MAI: HAKUREN** `:ru-hakuren` [V ch. 235] | hold 16–64 f, then 6/1/24 | 70 → 130 | guard 12 → 18 | the canon four stabs as a charge: **one stab per 16 f** (1–4, a white ice spike appears in a semicircle before her at each). Release: a **wave** hazard (the `:wave` kind, ice look) 12 m/s, 11 m (55 f), **width 2.4 + 0.4 × (stabs − 1) → 3.6 m**, damage 70 + 20 × (stabs − 1), a hit **freezes 24 f** + frost 120; no chip. Lane rule: half-width ≤ 1.8, so a side Step (2.5) always clears it. 1 bar. A full charge from > 7 m (the AI's charge rule) | stab the plaza, stab, stab, stab in a half circle, the ribbon settling; then the blade swept up, the avalanche of cold rolling off the tip |
| Shift+L | SP2 **参の舞・白刀 SAN NO MAI: SHIRAFUNE** `:ru-shirafune` [V ch. 268] | 16/4/28 | 110 | −14 | lunge 1.0 m; the ice blade extends the reach: **line 0.3 → 5.0 m**, knockback 2 m, frost 150 (the wound keeps freezing, canon). It is her own blade (melee: pays KŌSEI, can be parried). 1 bar. Her mid-range whiff punish and the Tsukishiro converter (§3.4) | a deep one-handed thrust, rear leg straight; ice grows off the point in three stepped drawings |
| I | Breaker **縛道の四・這縄 BAKUDŌ NO YON: HAINAWA** `:ru-breaker` [V ch. 266] | §4 (universal) | 150 | Guard Break | the universal Breaker (aura 12, dash, strike 8/4/18, reach 2.6). The strike: the left hand flicks and a **white rope of light** lashes his arms (the guard broken: canon Hainawa binds the arms). Rope in SOUL glass, not yellow (REIATSU is Kenpachi's) | dash low, blade trailing; at the strike the left palm snaps forward, two fingers pointed |
| O | Kikon module **円舞 ENBU** `:ru-kikon` → Kikon **初の舞・月白** | aura 6, **shunpo 24 m/s ≤ 16 f** (locked), strike 8/3/24 | 70 | −14 | reach 1.6 + 6.4 = **8.0 m**, ≤ 30 f from the press; the strike is MAI-SODE's pirouette (clip reused), **2.4 m 360°**; knockback; cooldown 90; the flash-step look (TENCHI's afterimages, `:hoho-out`). As the O ender (off a J3 / K3 hit) the aura is skipped: from J3's 2.6 m, 1 m of dash (3 f) + S 8 = 11 f < stagger 26 | a vanish, then the spin |
| U | guard | | | | the universal guard (200°, gauge, GUARD HOLD) | |
| P | awaken (§4) | | | | EVOLUTION, from idle / walk / guard | |

Canon notes: **Juhaku** (樹白, the ground trail) is **anime-only** (ep. 272) [A] and is **not used**. The kidō in the kit is
Hainawa only, which is manga canon (ch. 266). Sōkatsui and Byakurai (manga) are left for a later variant. Shakkahō and Sōren
Sōkatsui (anime filler) are not used. Every name without a [V] tag is invented [G]: HATSUSHIMO, KAZAHANA, MAI-SODE,
SHIMO-TSUKI, HYŌRIN, NADARE, ENBU.

### 3.4 What the base kit plays like
- **At 5–8 m**: Tsukishiro under him (Step or eat 60 + freeze), Hakuren lanes (Step sideways), and a full-charge Hakuren on
  his wake-up (the `:oki :sp1-full` rule, the one Shiranui uses).
- **The conversions**: a Tsukishiro freeze (36 f, from f34; she is free at f36) → from ≤ 6 m, Shirafune (S 16, reach 5 m)
  lands, 60 + 110; from ≤ 2.5 m, a J string. A Hakuren freeze at range converts into nothing but frost and the reset of
  neutral.
- **Up close**: J1 at S 7 beats every K1 in the game (Yamamoto 18, Kenpachi 16); her KKK is ordinary. She wants to leave:
  run 9 m/s, the 8 m ENBU rush as her approach and punish.
- **The fairness rules** (report §"風險與對策", sidegrade B.2): every placed thing has a tell (ring 24 f, stabs 16 f each) and a
  bounded life (ring 0.6 s, wave 0.9 s). At most **one ring and two waves** exist at a time (the cooldown and the SP1 cost
  bound them). The ring collapses when she is hit. Step beats both (the ring by radius, the wave by width). Hazards pay no
  KŌSEI, and each blocked hazard drains 12–18 of the guard gauge: pressure, never a crush from full screen.

---

## 4. The awakened kit: 絶対零度 ZETTAI REIDO (the true Shikai [V ch. 567–568, ep. 385])

The awakening is the true power: her own body temperature drops. It is **permanent**, like every awakening. **Since the
temperature rework (built 2026-09-28, the user's decisions in "Playtest 1" and after it) its only resource is one cold
gauge**, two stacked bars; the band the gauge sits in is the kit form (like Nozarashi's cups), so walk, run, commands,
damage, reach, aura, stance and blade stay data. **No heal** (`:heal 0`). Kikon **3** in every band (the universal
awakened count), Soul Break 4. The step ladder, its timers, THAW and the L cooldown are gone.

### 4.1 The cold gauge (the kit meter `:temp`, cold C 0–200)

```
          bar 1 full (C 100)                 both full (C 200)
 −18 °C ──────────────────────► −50 °C ──────────────────────► −273.15 °C
 :m18   ◄────────────────────── :m50   ◄────────────────────── :zero
          bar 1 empty (C 0)                  bar 2 empty (C 100)
 CRACK (the zero ward crushed or broken): C 0, −18 at once, 60 burnt, a 30 f crumple, 120 f of THAW lock
 A Kikon / Soul Break reset: −18, C 0
```

| Rule | Value (knob) |
|---|---|
| Gauge | cold C **0–200**, two bars of 100 drawn overlaid in one strip (`*cold-max*`, `*cold-bar*`); the awakening enters at C 0 (−18) |
| Bands | −18 → −50 when C reaches 100; −50 → −18 when C falls to 0; −50 → zero when C reaches 200; zero → −50 when C falls to 100 (rules `temp-band`). Each band keeps a whole bar of room above its exit (hysteresis by bars) |
| Band switch | only while she is **free** (idle, walk, guard, run: the NOME rule). A string or a special started in a band finishes in that band's version; the drop comes after the move. **The combo band lock** (playtest 2, 2026-09-28): a combo (the string from its first link and everything chained to it: J / K links, K → L, the O ender, SP cancels) plays the band it began in, and when it ends the band re-resolves from what is left, several bands at once (C 0 → −18 even from zero; zero with C ≤ 100 → −50): rules `temp-band-at` |
| Cooling | **90 per second** while she guards (the GUARD HOLD test, `:guard` / `:guard-hit`: cooling = giving up the guard gauge's refill; `*ru-cool-rate*`): −18 → −50 in 1.1 s, → zero in 2.2 s (the user's decision 2026-09-28 "cool faster"; the design's pacing was 3.3 s) |
| Blocked melee | a blocked blade hit adds **1.5 × its guard value** (`*ru-block-cool*`): Kenpachi's pressure pushes her colder (ch. 567, her body adjusting to the thorns). Hazards and ranged hits add nothing |
| Real hit taken | warms her **0.2 × its damage** (`*ru-hit-warm*`, any source): a 100 hit costs 20 cold; shooting her is one way to thaw her |
| Warming | while she isn't guarding: **10 / 12 / 5 per second** at −18 / −50 / zero (the kit's `:warm`; `*ru-warm-m18*` / `-m50*` / `-zero*`): a −18 bar lasts 10 s, a −50 bar 8.3 s, and **zero warms slowest**, its top bar 20 s unbraced (the user's decision 2026-09-28, "slow the warming at −273 so it is easier to hold"; the design had zero warm fastest, 2.9 s) |
| Bracing (zero) | the ward is always up, so U held at zero **braces**: the warming stops, and the guard gauge (already not refilling) drains **8 per second** (`*zero-brace-drain*`). Run dry, it is a GUARD CRUSH, which is the CRACK. Zero can be held, but only on credit |
| CRACK | forced only (the zero ward crushed by blocks or bracing, or a Guard Break): `rukia-crack` (the zero kit's `:crush-hook`) sets C 0 (−18 at once), burns **60** (`*crack-self*`, never below 1), crumples her **30 f** if she is free (`*crack-stun*`), and for **120 f** her guard doesn't cool (the THAW lock, `*ru-thaw-lock*`; the gauge greys, its label reads THAW) |
| No chosen exit | the user's decision D7: she leaves zero only by spending, by warming, or by the CRACK |
| Reset | a Kikon / Soul Break reset sets −18, C 0 (`:reset-form :m18`) |

### 4.2 Spending (the kit's `:cold`, paid on the command's frame 0, hit or whiff, never below 0)

| Action | −18 | −50 | −273 |
|---|---|---|---|
| J link (each) | — | 6 | 20 |
| K link (each) | — | 12 | 40 |
| L | **25**, refused below it | 36, refused below it | **100** (the whole top bar: back to −50) |
| SP1 / SP2 | — | 40 | 100 |
| O (白霞罸, the O ender too) | — | 20 | 60 |
| I (Breaker) | — | 20 | none at zero |
| Step / Hoho | — | 12 / 20 | refused (rooted) |

At −18 **only L spends cold** (the user's decision): there is no band to fall to, and the warming already taxes every
non-guarding moment. **Only L is ever refused** for cold (`kit-command-ok-p`; the `:refused` cue flashes the gauge's cost
mark), and only **outside a combo**: an L chained after a K link (K → L) is an **overdraft**, allowed on credit while
C > 0 (rules `cold-ok-p`; the user's decision 2026-09-28: zero's KKK leaves C 80, short of L's 100, and KKK + L is the
combo he wanted); the spend clamps at 0, and the combo's end then drops her by the band lock's resolve (zero KKK + L:
120 + 100 → C 0 → −18). Everything else spends down to 0. Zero's budget is its top bar (100): a JJJ (60) or a KK (80), a string with the O
ender (a cash-out), or one L / SP1 / SP2 (100) and she is back at −50 once free.

### 4.3 Per band

| | −18 `:m18` 氷点下十八度 | −50 `:m50` 氷点下五十度 | −273.15 `:zero` 絶対零度 |
|---|---|---|---|
| Walk / run | **3.4 / 8.0** (Shikai 3.8 / 9.0) | **2.8 / 6.4** | **0 / 0**, rooted: no Step / Hoho, no move slide, no string chase |
| Damage dealt / taken × | 1.15 / 0.95 | 1.5 / 0.85 | 1.65 / 0.8 (a ranged hit through the ward ×1.0: optic) |
| Frost on every hit | 30 f | 60 f | 90 f |
| Reach × (the derived grid) | 1.0 | 1.1 | 1.35 |
| Blade | Sode no Shirayuki | **`:ru-rime`** (rimed: an ice edge, crystals along the back) | **`:ru-ice`** (the ice blade) |
| U | guard, cools | guard, cools | the ward; held = **bracing** |
| Field 寒域 (the kit's `:field`) | r 3.0, away ×0.85, back Step ×1.0 | r 4.0, ×0.70, ×0.90 | r 5.5, ×0.55, ×0.75 |
| Chip on her | none (`:chipless`) | none | none |
| HUD label / U tag | `-18C` / `U: COOL` | `-50C` / `U: COOL` | `-273C` / `U: BRACE` |

**The field (寒域 KAN'IKI).** While the opponent is within its radius of her and she is upright (not in a reaction, the
air, down or a cinematic), only the part of his walk / run velocity pointing **away** from her is scaled (rules
`field-velocity`; approaching, strafing and circling untouched), and a Step away from her is shortened by
`1 − (1 − s)·max(0, −cos θ)` (`field-step`; a side Step is never shortened, so every lane rule holds). With frost the two
multiply but never below ×0.45 (`*field-floor*`). Hoho, Burst, Kikon / Breaker dashes and knockback are untouched. The
look: a dim white ring on the plaza at the radius (the band's aura).

**J / K** (frames identical in every band: the DUEL_STRINGS §2.1 budget holds per band, host-tested):

| Link | −18 | −50 | −273 |
|---|---|---|---|
| J1 HATSUSHIMO | **1.44 m** (was 2.4) | **1.58 m** (2.64) | **1.94 m** (3.24) (the pinned-feet cut `:ru-q1-z`) |
| J2 KAZAHANA | **1.32 m** (was 2.2) | **1.45 m** (2.42) | **1.78 m** (2.97), **a palm backhand** (`:ru-palm` re-timed to S 7) |
| J3 MAI-SODE | **1.56 m** (was 2.6) | **1.72 m** (2.86), **two-handed and low** (`:ru-spin-50`) | **2.11 m** (3.51), the ice blade |
| K1 | 凍手 TŌSHU, **2.0 m** (was 2.2) | TŌSHU with the blade driven in beside the palm (`:ru-palm-50`), **2.2 m** (2.42) | **SHIMO-TSUKI's thrust with the ice blade, 3.78 m** (4.3), planted (`:ru-thrust-z`) |
| K2 HYŌRIN | **2.5 m** (was 2.8) | **2.75 m** (3.08) | **3.38 m** (3.78) |
| K3 氷華 HYŌKA | **2.4 m** (was 2.7), crumple | **2.64 m** (2.97), **both palms** (`:ru-flower-50`), the flower 1.2× | **3.24 m** (3.65), frost 150, the flower 1.8× |

**The rest by band:**

| | −18 | −50 | −273 |
|---|---|---|---|
| L | **霜柱 SHIMOBASHIRA** [G] 12/0/22: a disc r **2.5** at her, 60, stagger, frost 90, guard 12; a ring of frost pillars | **氷震 HYŌSHIN** 14/0/22: r **3.5**, 85, **crumple**, frost 120, guard 16; two hands on the hilt (`:ru-stab-2h`) | **零度凍結 REIDO TŌKETSU** 10/0/26: r **5.5** (= the field), 120, **freeze 45**, frost 150, guard 20; always cashes the top bar |
| SP1 白漣 HAKUREN | as the Shikai (hold 16–64, one stab per 16 f, 11 m, 70 → 130) | a stab per 12 f (hold 12–48), 14 m/s, 12 m, 80 → 149, freeze 30 | **no hold: the four stabs at once**, S 10, 16 m/s, 14 m, width 3.6, **160**, freeze 36 |
| SP2 白刀 SHIRAFUNE | line 5.0 m, 110, knockback | line 6.0 m, 125 | line 7.5 m, planted, 140, **crumple** |
| O 白霞罸 HAKKA | lane **6.5 m** | lane 7.5 m | lane **9.0 m** |
| I 這縄 HAINAWA | the Breaker | the Breaker | **none** (rooted) |

Every L is a disc round her, 360°, guardable facing her (`:src`), one hit. After a K link (playtest 2) the band's own L
chains as it is (S 12 / 14 / 10 fit a K link's stagger), under the same cold cost. The L family grows strictly (radius and damage;
host-tested), so deeper cold can't be the weaker choice (the playtest fix). SŌSEN, the old −18 L, is deleted (its clip
was J1's).

### 4.4 Absolute zero, in full
1. **The strongest version of every button** (above), ×1.65, and **the largest field**, which matches REIDO's radius:
   anyone the field holds, REIDO reaches.
2. **The ward** (West's: 360°, no blockstun, drains ×`*ward-mult*` 1.1, never refills, off in her moves and reactions)
   with **freeze-touch**: the first melee hit it blocks in a zero visit freezes the attacker **18 f** (`*freeze-touch*`;
   re-armed on each entry: `rukia-zero-enter`). Her punish is a J at 3.2 m.
3. **Optic**: hazards and `:ranged` hits pass the ward and land at ×1.0 (not ×0.8). South's bind binds her. Shooting her is
   the counterplay verb; so is waiting ~3 s outside 5.5 m (she can't chase), breaking the ward (a Breaker, which REIDO
   counter-hits from 5.5 m), or striking a bracing Rukia until the gauge crushes.

### 4.5 Removed base tools (sidegrade rule 2, named)
**初の舞・月白 TSUKISHIRO** (the L; gone in every band), **円舞 ENBU** (the dash rush becomes the dashless 白霞罸), and
**mobility** (walk / run −11 / −26 / −100 %; Step and Hoho at zero). Gained: the growing L family, frost on every hit, no
chip, the field, the zero ward with freeze-touch, and the 3-Konpaku 白霞罸.

### 4.6 Why it is a sidegrade
| Matchup | Base is better | Awakened is better |
|---|---|---|
| **vs Yamamoto** | her 3.8 / 9.0 m/s and Step-clearing lanes; zero is pierced by his fire (optic), and his hits warm her | the field slows his retreat at 3–5.5 m; −50 / zero out-reach his Shikai J / K |
| **vs Kenpachi** | her J beats his K, and the Shikai out-walks his pressure | his blocked strings cool her (×1.0 of their guard value); zero freezes on touch and REIDO answers his Breaker |
| **mirror** | the base zoner out-moves a cold one | a cold one's field and reach punish a base one's approach |

The measured A/B is under "Measurements (the cold gauge rework)".

---

## 5. The Kikon cinematics (60 Hz frames, the review-3 pacing: few long shots, long holds, sharp impacts; unskippable)

Rukia wears black, so she goes on the **white card** (Yamamoto goes on the black card because of his white haori). The
Bankai 白霞罸 is white, so it goes on the **black card**.

### 5.1 Base: `ru-kikon-cine` **初の舞・月白** (186 f; Kikon 2, Soul Break 3)
| Shot | Frames | What |
|---|---|---|
| beat 0 | 0–12 (12) | the ENBU spin held, a negative 2 f |
| caption card | 12–70 (58) | **white card**, Rukia a black silhouette, the blade and ribbon the only white lines drawn in ink; brush column **初の舞 月白** (reading SOME NO MAI, sub TSUKISHIRO / KIKON), the red 鬼 hanko; silence |
| the circle | 70–100 (30) | high and wide: she draws the circle round the victim with the tip, a white ring spreading on the plaza, the ribbon tracing it |
| the pillar | 100–128 (28) | low, wide-angle, from outside the ring: a pillar of white light and ice rises from the circle through the air above it ("everything inside the circle, air included, freezes" [V ch. 201]); `:ice-rise` |
| held push-in | 128–150 (22) | the victim white inside the pillar; poses held, effects frozen, silence |
| the shatter | 150–170 (20) | a negative, then a 12 f manga page (white, and the BLOOD of the soul flame the only colour); the pillar and the figure shatter into ice shards; the Konpaku shatter; `:ice-shatter` + `:konpaku-shatter` |
| aftermath | 170–186 (16) | wide: ice dust falling round her, the ribbon settling |

### 5.2 Awakened: `ru-hakka-cine` **卍解 白霞罸** (198 f; Kikon 3, Soul Break 4)
The canon beats [V: Oricon's official description; ch. 569–570]: lake-surface frost underfoot and in the sky, the pillar of
cold with Rukia as its source, the cold running past the blade tip, the target frozen and weathering into ice dust, and
afterwards the crack on the back of her hand. Her face stays closed-mouthed and composed in every shot (the user's decision
2026-09-28: 「露琪亞開卍解的動畫不要張嘴吧」; `face-beat :neutral` at beat 0).

| Shot | Frames | What |
|---|---|---|
| beat 0 | 0–12 (12) | the HAKKA strike held; a negative 2 f |
| the release | 12–30 (18) | close and low on her; the blade raised straight up; silence; on f24 the body swaps to `:rukia-bankai` (white kimono, ice crown, white hair) in a single white flash frame |
| caption card | 30–88 (58) | **black card**, white back-rim, her white silhouette; brush **卍解 白霞罸** (reading BANKAI, sub HAKKA NO TOGAME; the 罸 glyph, **not** 罰), the red hanko |
| the pillar | 88–118 (30) | low and wide, the camera between two flat **lake-like frost discs**: one on the plaza, one mirrored in the sky; a white pillar pierces both with her at its root; `:ice-rise` + a long low drone |
| the tip | 118–136 (18) | along the blade: the cold runs out past the point in a white sheet to the victim (the Hakuren-like wave [V ep. 385]) |
| frozen | 136–156 (20) | a held push-in on the victim, frozen solid (a white silhouette with ice crust), in silence |
| the crumble | 156–174 (18) | a manga page; the victim **weathers into ice dust**, drifting up and off (TENCHI's ash crumble re-coloured: SOUL glass, not ASH); the Konpaku shatter |
| the hand | 174–198 (24) | a close-up of her right hand on the hilt: **a crack across its back**, a hairline of BLOOD; she lowers the blade; the body swaps back to her current form's look at the cut. Flavour only: no gameplay cost (the reset puts her at −18 anyway) |

Both are `defcine` scripts with existing primitives (`card`, `back-rim`, `caption`, `impact-frame`, `lens`, `silence`,
`hold-both`, `shot-on`, `shot-pair`). The new looks are the frost disc pair and the ice pillar (§10). In portrait the
close-ups follow §15.3 of the mobile design (a close-up keeps the lens; the body may be cropped).

---

## 6. The awakening: condition and entry cinematic

**Condition**: the universal Fighting Spirit gauge (EVOLUTION), P from idle / walk / guard, once per match. **No heal**. The
guard gauge, Reiatsu and flash-step are kept. She enters **−18 °C** with C 0. The CPU's timing is a rule, not a reflex (§7).

**`ru-awaken-cine` 絶対零度 (132 f)**
| Shot | Frames | What |
|---|---|---|
| beat 0 | 0–12 (12) | a negative 2 f; `:ru-awaken` (the blade lowered, point down) |
| the breath | 12–38 (26) | close on her face: one last white breath puff; then **none**; the eyes close; silence (canon "I am not alive right now" [V]) |
| the chill | 38–62 (24) | low from behind: frost spreads from her feet over the plaza in a disc; the ribbon stiffens and frosts; `:frost-tick` ×3 |
| the card | 62–116 (54) | a negative, then a **white card**, Rukia a black silhouette, the blade a white line; brush **絶対零度** (reading ZETTAI REIDO, sub SODE NO SHIRAYUKI) with its ink splash |
| wide | 116–132 (16) | back in the plaza at −18: her breath frosting again, the motes rising |

---

## 7. AI profiles (`:ai` per form; generic code in ai.lisp)

### 7.1 When to awaken (a real choice)
The CPU today awakens on EVOLUTION (Yamamoto only above 40 % Reishi). Rukia's kit uses a new generic key instead:
`:awaken (:melee-share 0.6 :min-taken 150)`. On EVOLUTION it awakens only once she has taken ≥ 150 damage **and ≥ 60 % of it
came from melee** (the opponent's own blade windows: the same `ranged-hit-p` test `apply-hit` already makes; two counters in
`gauges`, not hashed for other characters). The share keeps updating, so a Yamamoto who goes Bankai East and starts cutting
can tip it mid-match. That is rule 5 (the choice is made mid-match, with information). Debug **39000 + 10a + b** sets the mode
per side (0 the rule, 1 always on EVOLUTION, 2 never), like 31000 for Kenpachi's Bankai.

### 7.2 Tables
| Form | Intents (A / P / Z / D) | Ranges | Bands (lo hi weights) | Other keys |
|---|---|---|---|---|
| **base** | 1 / 2 / 3 / 1 | A 3.0–5.5, P 1.4–2.6, **Z 5.0–8.0**, D 4.0–7.0 | 0–2.6 `:q 5 :f 2 :breaker 1 :sp2 1 :step 1`; 2.6–5 `:f 1 :sp2 2 :sig 2 :step 2 nil 1`; 5–8 `:sig 4 :sp1 2 :step 1 nil 1`; 8–99 `:sp1 3 :kikon 1 nil 1` | guard 0.4, hoho 0.35, dash 0.3, dash-back 0.5, kikon-range 8.0, sp-cancel-bars 1 (Shirafune off link 3), `:oki :sp1-full :oki-above 0.4` (a full Hakuren on a downed opponent), **`:stun-follow (:sp2 2.4 5.0)`** (new: a frozen or staggered victim in that band gets Shirafune if the stun outlasts S + the perception delay), `:awaken` §7.1 |
| **−18** | 2 / 3 / 1 / 2 | P 1.3–2.4, A 2.5–4.5, Z 4.5–7.0 | 0–2.8 `:q 5 :f 2 :breaker 1 :sig 1`; 2.8–5 `:sp2 2 :step 1 nil 2`; 5–99 `:sp1 2 nil 2` | guard 0.5, hoho 0.3, dash 0.2, dash-back 0.2, o-ender 0.25, kikon-range 6.5, **`:cool (:p 0.3 :near 3.5)`** (a neutral decision within 3.5 m holds U for the frames the next band still needs: `temp-cool-frames`), `:stun-follow (:sp2 2.4 5.0)` |
| **−50** | 1 / 3 / 0 / 2 | P 1.2–2.4, D 2.0–3.5 | 0–3.5 `:q 4 :f 2 :sig 3` (HYŌSHIN up close); 3.5–99 `:sp2 1 :sp1 1 nil 2` | guard 0.45, `:cool (:p 0.35 :near 4.0 :no-projectile t :min-gg 50)` (never goes for zero with under half a guard gauge: the CRACK comes from crushes), `:stun-follow (:sp2 2.4 6.0)` |
| **zero** | 0 / 3 / 0 / 2 | every range 0–99 (it can't move) | 0–3.5 `:q 4 :f 3`; 3.5–5.5 `:sig 3 :f 1 nil 1` (REIDO, K1 4.3 m); 5.5–7.5 `:sp2 1 :sp1 2 nil 2`; 7.5–14 `:sp1 2 nil 2` (the instant wave); 14–99 wait | guard 0, **`:brace (:p 0.2 :near 5.5 :min-gg 30)`** (a neutral decision holds U 20 f while he is within 5.5 m and the guard gauge is ≥ 30: `ai-brace-p`; replaces `:zero-exit`), `:opp-intent (:zone 2 :defend 2)` |

(THAW / CRACK and `:zero-exit` are gone with the rework. `kit-command-ok-p` checks L's cold, so the CPU never presses a
refused L.)

- The freeze punish needs no new key. The existing reflex "a stunned opponent still stunned when Q1 lands → Q1" fires on the
  frozen attacker (at zero J1 reaches 3.24 m).
- The Breaker answer at zero needs no new key either: REIDO's 5.5 m disc is in her 3.5–5.5 m band, and the anti-Breaker
  reflex's `:q` counter-hits the dash. One generic fix: in a `:rooted` form the reflexes never pick Hoho or a side Step (they would be
  refused), so `hoho-ok` is NIL and a side Step becomes `:q`.
- Tsukishiro's tell for the CPU victim: the South reflex (`:bind` flag, hard-coded tell frames 21–30) reads the tell frames from
  the move's `:params :tell` instead (South `(21 30)`, Tsukishiro `(19 28)`). A frosted victim can only Step out.
- An opponent CPU keeps its Breaker reflex against a held guard. The zero ward already counts as a held guard (`snap-take!`
  treats a `:ward` fighter as guarding), so a CPU Breaks a zero Rukia after 24 f at p 0.4. That is the designed counter
  (§11 B1 checks how often it cracks her).

---

## 8. HUD and the one-hand controls

**Landscape** (the kit-meter row, where NOME / UDE live; the name reads "RUKIA  -50C"; the awakening row names the form):
- base: no meter (the slot is empty, like Kenpachi's base).
- awakened, every band: **one cold gauge** (`%hud-temp`, white on ink: ice is mono), the only thing on its row. Her
  awakened L has no cooldown (the gauge is its limiter), so the `(plusp (mv-cooldown l))` test draws no COOLDOWN row and
  no L cell for her: the playtest overlaps (the TEMP text on COOLDOWN, the bar over the L cell) can't happen. Yamamoto's
  and Kenpachi's awakened panels keep `hud-cooldowns` (one L bar; the thin Shift+L line is deleted with South's cooldown).
  - **Two stacked bars overlaid in one strip**: bar 1 (C 0–100) steel-ice, bar 2 (C 100–200) bright white drawn over
    it (the fighting-game stacked super meter). The fill is continuous; the strip's inner end carries three ice pips,
    as many lit as the band is cold (−18 one, −50 two, zero three).
  - **L's cost** on the top bar: the part of the fill L would spend is dimmed (a white notch at the cost when C is short
    of it, −18's refusal); a refused L flashes it (`*refused-t*`).
  - **Zero**: bar 2 pulses; in its last tenth (C < 110) it flickers. **THAW lock** (120 f after a CRACK): the fill is
    grey. **CRACK**: a BLOOD hairline flashes across the strip (`*crack-t*`, the `:cold-crack` event) and "CRACK" shows.
  - The label is the brush 凍 + the band, `-18C` / `-50C` / `-273C`, or `THAW` during the lock (`temp-label`): a band,
    not a live °C (a jittering number would be noise; the fill is the continuous part). EVOLUTION takes precedence as
    usual. The U tag on the row above: `U: COOL`, zero's `U: BRACE`.

**Portrait** (`hud-side-portrait`): the fourth small gauge of the last row is the same `%hud-temp` at small size (pips and
the cost mark kept, 4 s thick); the row's right-end label (`portrait-label`) is `temp-label`. No COOLDOWN label for her.

**One hand** (DUEL_MOBILE_DESIGN §15.1, unchanged gestures): lower-zone tap = J, upper-zone tap = K, up-flick = the forward
dash, **rest = guard = cool**, rest then up-flick = Hoho, the chips for L / I / SP1 / SP2 / O / AWK.
- **The frost arc under the thumb = C / 200**, clockwise from the top (the two bars round the ring), a white tick at the
  bottom (the half: bar 1 full, −50). At zero a white ring joins it and the arc pulses; while the thumb rests (bracing)
  it stops shrinking and the guard gauge (the block's own bar) is the clock. In the THAW lock the arc is grey.
- A refused flick or rest-flick at zero is eaten (rooted: no Step / Hoho); every tap or chip spends its cold.
- Accidental cooling: a resting thumb is a guard, so drag-rest-drag footwork accumulates cold. Every change shows on the
  ring, zero needs 2.2 s of guarding from −18, and unbraced zero still warms away by itself (20 s).

---

## 9. Balance plan

(The first build's plan, kept as the record. The cold-gauge rework's gates and results are at the end of this file,
"The cold-gauge rework: built".)

**Gate today** (debug 2113, 20 seeds, NORMAL, cinematics included; window: medians 125–210 s, all K.O.): **YY 131.8 / YK 138.4 /
KK 131.5 s**, YK Yamamoto 8 / Kenpachi 12.

**Expected effect**
- **YY / YK / KK: byte-identical.** Every change is behind a Rukia passive or kit key, the new hazard slots default to NIL, no
  new random draw is made for Yamamoto or Kenpachi, and the new gauge counters stay out of their hash lines. The G2
  reference (`duel-cvc-yk.json`, seed 7) must still end `ticks 7123 secs 118.7`.
- The gate grows to six pairings, 120 matches. Predictions:
  | Pairing | Median guess | Why | Risk |
  |---|---|---|---|
  | **RR** | 150–175 s | two zoners at 5–8 m; heat pulls them in; awakened mirrors freeze each other | the high edge if both stay base |
  | **RY** | 150–185 s | Yamamoto zones at 7–9.5 m, she at 5–8 m: waves, rings and Shiranui trade; her J1 beats his K up close | **> 210 s** if the two zoners stare: heat (+3/s beyond 6 m) is the backstop; knob below |
  | **RK** | 130–150 s | Kenpachi closes fast; base Rukia loses ground; the awakened one freezes and punishes | < 125 s if freeze punishes snowball |
- Win targets: RY and RK each within 10 ± 3 of 20.

**The awaken A/B** (seeds 1–60, NORMAL; Rukia P1 with mode 1 "always on EVOLUTION" vs mode 2 "never"; RR: P1 with the mode
against a P2 on the rule):
- (**Superseded 2026-09-28** by the user's decision 「覺醒偏強沒關係，只要不是強到無法贏就好」: the pass is now "never awaken"
  wins **≥ 20 of 60** against each opponent on each of ≥ 3 seed streams, with no target on the margin; see "The awaken
  A/B across seed streams" at the end. The original criterion, kept as the record:)
- **Pass**: in each pairing the win-count difference always − never is within the noise (**|Δ| ≤ 9 of 60**, the Kenpachi
  gamble's criterion, from ±2 of 20), **and at least one pairing has never > always** (expected RY). The rule mode (0) should be
  at least as good as the better of the two in both RY and RK (the adaptive choice pays); that is logged, not gated.
- If always wins everywhere (awakening is an upgrade): `*zero-frames*` 240 → 180, `:taken` at −50 0.9 → 1.0, `*freeze-touch*`
  24 → 18, SŌSEN cooldown 120 → 180, awakened `:frost-touch` 60 → 30.
- If never wins everywhere (a trap): `*cool-frames*` 40 → 30, `*thaw-frames*` 120 → 90, `*freeze-touch*` 24 → 30, −50 walk
  2.5 → 2.8, `*crack-self*` 60 → 40.

**Pacing log** (added to the gate report): awakenings per match and their tick; the melee share at EVOLUTION by opponent form;
time per step (−18 / −50 / zero / thaw / crack); zero windows by exit (chosen by attack, by REIDO, timeout, crush, Guard
Break); freeze-touch triggers and their conversions (damage, Kikons); ranged hits taken at zero; Tsukishiro casts / hits /
blocks / Step-outs; Hakuren by stabs; frost uptime on the opponent.

**Knobs, in order**
- Median under 125 s: Tsukishiro freeze 36 → 28, `:stun-follow` off, frost on K links 60 → 30, `*frost-slow*` 0.7 → 0.8.
- Median over 210 s (RY / RR): the base kit's zone weight 3 → 2, `:dash` 0.3 → 0.5, ring cooldown 150 → 120.
- Rukia wins too much: J1 34 → 32, Hakuren max 130 → 110, `*frost-slow*` → 0.8. Too little: walk 3.8 → 4.0, Shirafune −14 → −12,
  Tsukishiro r 1.8 → 2.0 (2.0 + Kenpachi's 0.45 = 2.45, still under the 2.5 m Step).

---

## 10. Build list

**New files** (MANIFEST: `lisp/rukia-art.lisp` after `lisp/ken-art.lisp`; `lisp/rukia.lisp` after `lisp/ken.lisp`):
- `rukia.lisp` (~450 lines, like yama.lisp): the moves (6 grid + 2 copies, L, SP1, SP2, Breaker, ENBU, SŌSEN, HYŌSHIN, REIDO,
  HAKKA), six kits (`:base :m18 :m50 :zero :thaw :crack`), hooks (`rukia-tsukishiro`, `rukia-hakuren-charge` /
  `-release`, `rukia-hyoshin`, `rukia-reido`, `rukia-hakka-pillar`, `rukia-crack`, `rukia-awaken-enter`), three cinematics.
- `rukia-art.lisp` (~600 lines): body `:rukia` and two `body-variant`s (`:rukia-zero`, `:rukia-bankai`), weapons
  `:ru-katana`, `:sode-no-shirayuki`, `:ru-ice`, and the clips.

**Character select**: automatic. A `:base` kit adds her to `*roster*` and the select screen cycles it. Also add
`*brush-names*` `(:rukia "朽木ルキア" "KUCHIKI RUKIA")`, `:intro :ru-intro :intro-callout "MAE, SODE NO SHIRAYUKI" :intro-weapon
(:ru-katana 70)` (the release turn at f70), and `:win :ru-win`. The P2 mirror tint follows the existing rule (her white parts
cold-tinted, the keyline #5A6A8A).

**Clips: 21 new**
- base (17): `:ru-stance`, `:ru-q1`, `:ru-q2`, `:ru-spin`, `:ru-thrust`, `:ru-ring`, `:ru-drop`, `:ru-tsukishiro`, `:ru-stab`
  (the hold loop), `:ru-hakuren` (release), `:ru-shirafune`, `:ru-breaker` (dash loop), `:ru-hainawa`, `:ru-kikon`
  (cinematic), `:ru-intro`, `:ru-win`, `:ru-awaken`.
- awakened (4): `:ru-cold-stance` (the −18 / −50 / THAW stance: lower, the blade reversed along the forearm, stiller),
  `:ru-zero` (still, point down, eyes closed), `:ru-reido`, `:ru-hakka`.
- **reused**: ENBU's strike = `:ru-spin`; SŌSEN = `:ru-q1` (clip-s 7); HYŌSHIN = `:ru-stab`; the crack = `:sh-crumple`; THAW =
  `:ru-cold-stance`; every reaction, walk, strafe, step, guard and the run set = the shared `:sh-*`; ENBU's dash = `:sh-run`
  (as TENCHI); the awakened grid = the base grid's clips (derived: no new clip).

**Glyphs to bake** (`tools/glyph-bake.py`; skip the ones already baked): 朽 木 ル キ ア 袖 白 雪 舞 初 月 次 漣 参 刀 絶 対 零 度
霞 罸 凍 結 霜 閃 氷 震 縛 道 四 這 縄 円 (≈ 30).

**Sounds: 5 new** (`sounds.lisp`, synthesized): `:frost-tick` (a crystalline tick: a step reached), `:freeze` (a crackle that
locks: freeze-touch, Tsukishiro, REIDO), `:ice-rise` (a rising shimmer + low bell: the pillars), `:ice-shatter` (a glassy
break), `:hand-crack` (a small brittle crack). Reused: `:whoosh-light`, `:cut`, `:clang`, `:hoho-out`, `:kikon-slash`,
`:konpaku-shatter`, `:awaken-rise`, `:awaken-boom`, `:ground-crack` (HYŌSHIN).

**VFX** (vfx.lisp; all in SOUL glass + white, no new palette slot unless §11 M8 demands it): the Tsukishiro ring (a `%tring` in
white with ink ticks) and ice pillar (the pillar geometry with an ice look); the Hakuren wave (the `:wave` draw switches on
`(hazard-look hz)` `:ice`: a white sheet, shards, no light) and the stab spikes; Shirafune's ice line (`:line` look `:ice`);
the frost crust and the frozen crust on a victim; the breath puff; auras `:frost` and `:zero`; the freeze-touch burst; the
HYŌSHIN cracks (`stage-crack-add`, whitened); the REIDO burst (`vfx-shockwave :pal` SOUL); the HAKKA pillar; the cinematic's
frost-disc pair; the ice-dust crumble (`vfx-ash-burst` with a palette argument); the hand crack; the ribbon (an fx ribbon on
the pommel's trail samples).

**Existing systems reused**
| System | Where it comes from | Rukia's use |
|---|---|---|
| **the ward** (`:ward`: 360°, no blockstun, ×1.1, never refills, off in reactions, `ward-drop`) | Bankai West | the zero body |
| **`:drop-to` / `:keep`, `kit-drop`** | Bankai West → East | chosen exit: an attack at zero drops to THAW on frame 0 |
| **the `:bind` hazard and reaction** (a disc that hits once after its delay; `:sh-bound`; `combo-step`'s opener rule books 2 hits; Burst allowed) | South | every freeze: Tsukishiro, HYŌSHIN's disc (with a stagger hitwin), REIDO, freeze-touch |
| **`cast-point`** | South | Tsukishiro's placement ≤ 8 m |
| **the ENJO module** (no dash, a locked lane capsule, `:look :lane`) | Yamamoto's Kikon | 白霞罸 |
| **the flash-step look** (afterimages, `:hoho-out`) | KITA: TENCHI | ENBU's dash, SŌSEN's lunge |
| **the `:wave` hazard** | the Signature's flame wave | Hakuren |
| **the charge hold** (`:hold`, tick, the AI's full-charge rule, `:oki :sp1-full`) | Shiranui | Hakuren's stabs |
| **GUARD HOLD's guarding test** | guard v3 | what cools her |
| **form timers** (`:duration`, `timer-fill`) | Hellfire | zero's 240 f, THAW, CRACK, the countdown bar |
| **kit forms per state** (a meter in `gauges-meter`, one form per rung) | Nozarashi's cups | the temperature steps |
| **"closes when its owner is hit"** (`close-rifts`) | KUKAN-GIRI's rift | the Tsukishiro ring (fragile) |
| **`:opp-intent`** | Kenpachi's Bankai | CPUs wait out zero |
| **derived moves** (`:reach-mult`) | KATATE | the awakened grid at ×0.9 |
| **`defmove-copy`, `:grid`** | the strings | J2s / K2s |
| **the parry** (GOKUI GAESHI) | Bankai West | **not reused**: a 12 f read window is the wrong model for canon's 4 s state; freeze-touch gives zero the parry's payoff through the ward |

**Engine gaps** (all small, generic, and no-ops for Yamamoto and Kenpachi):
1. **Frost** (§3.1): a fighter slot `frost`; the hitwin / `defmove` key `:frost`; the passive `:frost-touch`; set in `apply-hit`
   on `:hit` / `:counter`; decremented in `fighter-step`; ×`*frost-slow*` in `neutral-step` and `run-step`; in the hash line only
   while > 0 ever happened in the match (so Y/K hashes stay). ~15 lines.
2. **Kit keys**: `:expire-to` (a timed form's exit, default `:inherit`: gauge-system, 1 line), `:crush-to` (`ward-drop`'s form,
   default `:drop-to`: 1 line), `:rooted` (`try-command` refuses `:step` / `:hoho`; `run-step` never starts), `:reset-form`
   (`reset-round`, 1 line), `:temp (:cool 40 :to form :warm 300 :warm-to form)` read by a new `temp-step` in `gauge-system`
   (next to `arm-step`) over a pure rule `temp-next (c idle guarding cool-at warm-at)` → c idle step (~25 lines). `register-kit`
   destructures the five keys.
3. **Passives**: `:chipless` (the `:blocked` branch's chip is 0 for her); `:optic` (in `apply-hit`, a ranged hit on a `:ward`
   defender with `:optic` resolves with `def-state :neutral`); `:freeze-touch` (after a `:blocked` melee result on a `:ward`
   defender with it, once per window: spawn the freeze `:bind` hazard on the attacker; a per-window flag in `gauges`, cleared
   on entering zero).
4. **Hazard slots**: `src` (`:owner`: `collect-hazard-hits` passes the owner's position as the hit's source, so a guard facing
   her blocks a disc under the victim) and `fragile` (`close-rifts` also closes the owner's fragile hazards that are still
   delayed). ~6 lines.
5. **AI**: `:awaken` rule (+ `gauges` counters `taken-melee` / `taken-ranged`), `:cool`, `:zero-exit`, `:stun-follow`, the
   `:tell` params for the bind reflex, and rooted-aware reflexes; the debug A/B mode 39000 + 10a + b.
6. **HUD**: the TEMP / countdown bar and labels (landscape + portrait), the one-hand ring's frost arc.
7. **Zero entry from a held guard**: set `fighter-guard-t` to `*guard-raise*` on entering `:zero` from `:guard` / `:guard-hit`,
   so there is no 2 f hole in the ward (West has one on its switch; here it would be an exploit).

**Host tests** (`tests/duel-rules-test.lisp`): the §2.1 budget over `:base :m18 :m50 :thaw :crack` (the six routes, the copies);
`temp-next` (39 → no step, 40 → step, frozen while not guarding, 300 idle → warm, no cooling in THAW); every form's Breaker
strike reach > 2.2 and Kikon strike reach > 1.9; Kikon counts 2 / 3, Soul Break 3 / 4; Tsukishiro r + Kenpachi hurt r < Step;
Hakuren's full half-width + hurt < Step; `:expire-to` / `:crush-to` / `:reset-form` resolved; `:optic` ranged → `:hit` on a ward,
melee → `:blocked`; `:chipless` → chip 0; frost ×0.7 on walk only, max not sum.

**Probes** (debug, a new block such as 2410 + k): cool to zero with U held (80 f); a J at zero drops to THAW and J1 starts
on frame 0; a Kenpachi J1 into zero is frozen 24 f and her J1 connects; Shiranui hits her at zero; a Breaker at zero → CRACK
(burn 60, ≥ 1 left); REIDO counter-hits a Breaker dash; the 240 f timeout → CRACK; a reset from zero → −18; Tsukishiro closes
when she is hit at f20; the determinism double run; stills of the three cinematics (the 35000+f pattern).

**Implementation order**: (1) rules + host tests; (2) kits with placeholder clips (the shared and Yamamoto clips on the
`:rukia` body), the temperature machine, frost, the passives, the hazard slots, a minimal HUD; the gate (YY / YK / KK
byte-identical, then RR / RY / RK); (3) AI keys, the gate again and the awaken A/B; (4) art: the body and variants, weapons,
21 clips, the ribbon, VFX, the three cinematics, sounds, glyphs; user review with stills; (5) docs: DUEL_DESIGN §1 (the roster),
§6.4 (new: Rukia), §6.3 (ENBU, HAKKA rows), §7, §10 (HUD, the cinematic table: 月白 186, 白霞罸 198, awakening 132), §12 rows;
DUEL_MOBILE_DESIGN §15 (the frost arc); STYLE_STORM §A.2 (ice is mono: SOUL glass).

---

## 11. Adversarial self-critique

| # | Sev | Finding | Resolution (folded into the text above) |
|---|---|---|---|
| B1 | BLOCKER | Between CPUs the opponent's Breaker reflex (a held guard ≥ 24 f within 3 m, p 0.4) sees the zero ward as a held guard: most zero windows could end in a CRACK, and the A/B would measure a broken awakening | REIDO counter-hits a Breaker dash (§4.3), and the zero AI's anti-Breaker reflex resolves to a dropped J1 (a counter-hit). The pacing log counts exits by cause. Gate criterion: ≤ 40 % of zero windows end in CRACK between NORMAL CPUs, else `:zero-exit :far` 4.5 → 3.5 (she leaves before the aura) |
| B2 | BLOCKER | The ward's 2 f raise (`fighter-guard-t`) would leave a hole on entering zero from a guard: a hit in it is neither blocked nor frozen | engine gap 7: zero entered from a guard starts with the ward up |
| B3 | BLOCKER | `nome-step`-style ladders pick the form from the meter every free frame: reusing `:ladder` would drag THAW / CRACK back into a rung (they are not rungs) | a dedicated `temp-step` / `temp-next` (§10 gap 2); the forms outside the `:temp` graph are never touched by it |
| B4 | BLOCKER | A forced exit and a chosen exit both leave through `set-form`; the exit hook can't tell them apart | two targets: chosen → `:drop-to :thaw` (and REIDO's hook), forced → `:crush-to` / `:expire-to :crack`; CRACK's cost is its own `:enter-hook` |
| B5 | BLOCKER | Hash drift for Y/K from new slots (frost, counters) would break G2 and every gate comparison | new values enter a hash line only for a Rukia form, or once frost has been applied in the match (Kenpachi's pips precedent: `u<clock>` only for a form with pips) |
| M1 | MAJOR | Awakening may be strictly worse (slow, fewer tools) and "never" wins everywhere | the A/B's second knob list (§9); the 3-Konpaku Kikon already pulls the other way |
| M2 | MAJOR | Freeze → J J J → O ender: every freeze-touch on a red victim is a Kikon worth 3 | once per zero window; he may Burst at once (the bind books 2 hits); he chose to strike a visible zero Rukia; knob `*freeze-touch*` 24 → 18 (J1 still lands at S 7, the string less often completes) |
| M3 | MAJOR | Tsukishiro + frost: the ring can't be walked out of, so every L forces a Step or a guard | intended (3D zoning must force movement); a Step always clears it (tested for Kenpachi's hurt r 0.45), the tell is 24 f, cooldown 150, fragile; the CPU victim reads it (the generic `:tell`) |
| M4 | MAJOR | Two zoners (RY, RR) may stare past 210 s | heat already doubles beyond 6 m; knobs: the zone weight, `:dash`, the ring cooldown (§9) |
| M5 | MAJOR | A 1.44 m body with a true-size hurt cylinder would make some arcs and lines whiff over or past her (a hidden defensive buff) | hurt r 0.34 / h 1.50, close to Yamamoto's 0.36 / 1.65; the host test's reach checks use her cylinder |
| M6 | MAJOR | On the phone a resting thumb is a guard, so footwork cools her without intent | C is frozen, not reset, and the ring shows it; the 300 f warm undoes it; zero needs 80 f of guarding and any tap leaves it. Question 4 offers "reset C when U is released" |
| M7 | MAJOR | `:optic` makes zero useless against every hazard user; with South (a hazard) Yamamoto binds her through the ward | the canon loophole, and the base-vs-Yamamoto half of the sidegrade; zero is a read, not a stance to live in |
| M8 | MAJOR | Ice in cold tints could read as STEEL (guard, Burst) and the Konpaku's SOUL glass | ice uses white cores + SOUL glass, never STEEL; the Konpaku flames keep their BLOOD core; the stills review decides whether a 13th palette slot "ICE" (#FFFFFF / #E4F0F8 / #8FA6C0) is needed |
| M9 | MAJOR | Shirafune at 2 bars in the awakened forms (the universal SP2 rule) makes her main mid-range punish rarer exactly when she is slow | intended: the cold body gives up reach; SŌSEN (free, cooldown) is the −18 replacement. Knob: a move `:cost 1` on the awakened copy |
| M10 | MAJOR | 21 clips and 3 cinematics: the largest art batch since the restyle | 7 moves reuse clips (§10); placeholders let the gate and the A/B run before any art |
| m1 | MINOR | Invented names (HATSUSHIMO … ENBU, SŌSEN, REIDO TŌKETSU) could be mistaken for canon | tagged [G] here; DUEL_DESIGN §6.4 keeps the tags |
| m2 | MINOR | "−273.15" in ASCII | the HUD shows `-273C`; the brush column 絶対零度 carries the rest |
| m3 | MINOR | The Bankai costume appears only in the cinematic, so players never fight "Bankai Rukia" | the user's decision: 白霞罸 is a Kikon, not a form |
| m4 | MINOR | The hand-crack close-up could read as a gameplay cost after a Kikon | the reset always returns her to −18; no cost, flavour only |
| m5 | MINOR | The frozen look reuses `:sh-bound` (feet held), made for South's hands | the ice crust (a look keyed on the hazard's `:ice` look) covers the legs; a dedicated clip is later if stills ask |
| m6 | MINOR | P2 mirror: a black figure's cold tint barely shows | the keyline #5A6A8A and the tinted ribbon; the RR stills check it |
| m7 | MINOR | Juhaku, Sai, Sōkatsui, Byakurai unused | Juhaku is anime-only; the others stay available for a later Signature variant |

Revision: all findings are resolved in the text. Two ideas were dropped on purpose. One is **Shirafune's lingering ice
floor**, a slowing patch that would need a new status zone: frost on hit carries the same canon beat. The other is **"a ranged
hit at zero forces the crack"**, which would double-punish the loophole: the hit and the running timer are enough.

---

## 12. Questions for the user: decided

| # | Question | Decided (2026-09-28) |
|---|---|---|
| 1 | The awakened J / K: derived, or a new bare-hand / ice set? | **Both**: the Shikai grid derived (reach ×0.9, frost on every hit) plus two new links, K1 凍手 TŌSHU (`:ru-palm`) and K3 氷華 HYŌKA (`:ru-flower`) |
| 2 | 月白 Tsukishiro guardable, or unguardable but steppable? | **Guardable** (the default) |
| 3 | 霜 Frost: keep it or drop slows? | **Kept** (the default) |
| 4 | Cooling: progress stays when U is released, or resets? | **Stays** (the default) |
| 5 | Her look: the TYBW lieutenant, white hair only at −273.15, the Bankai kimono only in 白霞罸? | **Yes to all three** (the default) |
| 6 | THAW rooted, or only slowed? | **Rooted** (the default) |

---

## User decisions (2026-09-28)

1. **Awakened J / K**: the derived base grid (reach ×0.9, frost on every hit) **plus a small number of new moves**, not
   0 new clips and not a full new set. Pick 2–3 links of the grid (e.g. K1 and one ender) to replace with new bare-hand /
   ice clips that sell the −273.15 body (canon: she caught thorns bare-handed); the rest stay derived.
2. 月白 Tsukishiro is **guardable** (default).
3. 霜 Frost is **kept** (default).
4. Cooling progress **stays** when U is released (default).
5. Look: TYBW lieutenant, no haori; white hair / ice only at −273.15; the Bankai kimono only in the 白霞罸 cinematic (default).
6. THAW is **rooted** (default).

Cross-batch change decided the same day (built by a separate batch, see DUEL_STRINGS): once a J / K link makes contact
(hit or block), the next links of the string **track the defender** (the attacker closes in during the follow-up anims) so
every pressed link comes out (the contact gate becomes "an earlier link of this string made contact"); tracking is motion
only, the links can still be guarded (or dodged by Step iframes) at their own frames.

---

## Built: deviations from the design, and why

Every number below was moved by the seed gate or the §9 A/B; the reason is the measurement, not taste.

| Item | Design | Built | Why |
|---|---|---|---|
| J3 MAI-SODE startup | 9 | **8** (clip re-timed) | the budget test: K2 → J3 left a blocked gap wider than J1's 7 |
| J1 HATSUSHIMO | 2.2 m | **2.4 m + a 0.6 m slide** | base Rukia could not start a string on Kenpachi's walk-in; the derived −18 J1 is 2.16 m |
| Tsukishiro / HYŌSHIN / REIDO / the freeze-touch hazard | the `:bind` kind | a new **`:freeze`** kind (a `:bind` disc that no projectile cut removes) | Nozarashi's and Bankai East's projectile cut deleted her rings |
| Whole-kit damage | ×1.0 | Shikai `:mult` 1.5 / `:taken` 0.8; awakened `:mult` 1.32 / `:taken` 0.9; −50 `:taken` 0.81 (×0.9 of it, the design's "hardened") | the Shikai lost most seeds to both awakened opponents, and the lightest J in the game left matches outside the 125–210 s band |
| Zero window | 4 s | **3 s** (180 f) | "always awaken" beat "never" by more than the sidegrade margin in the first A/B |
| Freeze-touch | 24 f | **18 f** | same A/B |
| `:frost-touch` (awakened hits) | 60 f | **30 f** | same A/B |
| SŌSEN cooldown | 120 | **180** | same A/B |
| AI cooling | cool whenever blocked | −18: `:cool (:p 0.2 :near 2.5)`; −50: no neutral cooling | the CPU sat at zero too often and cracked in many of its windows |
| AI awakening | `:melee-share 0.6` | the same + `:min-taken 150` (not before she has taken 150) | the rule fired on the first J it blocked |
| The two new awakened links | K1 / an ender | K1 **凍手 TŌSHU** (`:ru-palm`) and K3 **氷華 HYŌKA** (`:ru-flower`, an ice flower hazard at his feet) | the user's decision 1 |
| Frost look | a tinted ribbon trail | a static ice crust on the legs (`vfx-frost`) + the frosted keyline | a static crust reads at every frost timer and needs no per-frame trail |
| Rooted forms | "can't Step / Hoho" | the kit slot `:rooted` refuses :step / :hoho in fighter.lisp; the CPU maps them to guard | one generic flag instead of per-move checks |

Engine pieces added (generic, data-driven): the `frost` hit-window key and fighter timer, the kit slots `:expire-to`,
`:crush-to`, `:rooted`, `:reset-form`, `:u-tag`, the `:temp` kit meter (`temp-next` in rules.lisp), the passives `:optic`
(`optic-p`), `:freeze-touch`, `:chipless`, `:frost-touch`, hazards' `:src` (guarded from her side) and `:fragile`, a
function as a hazard `:look` or a form aura, and the TEMP HUD bar / thumb-ring arc.

## Knobs (debug commands; `duel/lisp/tuning.lisp` and the kits in `duel/lisp/rukia.lisp`)

| Knob | Value | Debug |
|---|---|---|
| `*frost-slow*` / `*frost-cap*` / `*frost-touch*` | 0.7 / 150 / 30 | 43000+k (slow ×0.01) |
| `*cool-frames*` / `*warm-frames*` | 40 / 300 | 46000+k / 55000+k |
| `*zero-seconds*` / `*thaw-seconds*` / `*crack-seconds*` | 3.0 / 2.0 / 2.5 | 44000+f / 51000+f / 52000+f |
| `*crack-self*` / `*crack-stun*` / `*freeze-touch*` | 60 / 30 / 18 | 47000+k / — / 45000+k |
| `*rukia-mult*` / `*rukia-taken*` | 1.5 / 0.8 | 58000+k / 60000+k (×0.01) |
| `*rukia-awake-mult*` / `*rukia-awake-taken*` / `*rukia-m50-taken*` | 1.32 / 0.9 / 0.81 | 48000+k / 61000+k |
| walks: Shikai / −18 / −50 / THAW | 3.8 / 3.2 / 2.5 / 1.9 (runs 9.0 / 7.6 / 5.8) | 57000+k / 56000+k (−18 / −50) |
| AI: awaken melee share, cool p / near, zone weight | 0.6, 0.2 / 2.5, 2 | 49000+k, 50000+k / 53000+k, 54000+k |
| A/B mode for P1 (0 the rule, 1 always, 2 never) | 0 | 39000 + 10a + b |

Other commands: 6000+s / 7000+s / 8000+s run RY / RK / RR at seed s; 2118 / 2119 the gate with her pairings; 2124 her gate
with the combat log (pacing); 2410–2417 human P1 Rukia in each form vs an idle opponent (review stills); 40000+f / 41000+f /
42000+f a still of 月白 / 白霞罸 / the awakening at frame f.

## Measurements (the merged build, fixed-dt turbo, seeds 1–20 per pairing, debug 2113)

| Pairing | K.O. | Median (s) | Wins |
|---|---|---|---|
| YY / YK / KK (refs, unchanged) | 20 / 20 / 20 | 134.7 / 137.1 / 125.8 | — |
| RY (P1 Rukia) | 20 / 20 | **144.0** | Rukia 9, Yamamoto 11 |
| RK | 20 / 20 | **152.1** | Rukia 12, Kenpachi 8 |
| RR | 20 / 20 | **186.0** | P1 10, P2 10 |

120 / 120 K.O.; every median in 125–210 s. The style gates' cvc refs (YY 154.1, YK 122.8, KK 137.1) are identical.

**§9 A/B** (seeds 1–60, P1 Rukia in the given mode vs the rule-driven CPU; P1 wins):

| Pairing | always | never | rule | always − never |
|---|---|---|---|---|
| RY | 25 | 28 | 23 | −3 |
| RK | 34 | 37 | 34 | −3 |
| RR | 28 | 27 | 28 | +1 |

Neither dominates (|Δ| ≤ 3 ≤ 9) and "never" beats "always" in two pairings: the awakening is a sidegrade. The CPU's rule
awakened in all 80 of her gate sides.

**Pacing** (debug 2124, 20 matches each, both Rukia sides in RR):

| Pairing | zero windows | CRACK (all from ward breaks) | freeze-touches | REIDO exits |
|---|---|---|---|---|
| RY | 77 | 13 (17 %) | 24 | 37 |
| RK | 113 | 21 (19 %) | 60 | 39 |
| RR | 234 | 43 (18 %) | 31 | 101 |

Known: the CPU charges HAKUREN rarely (4–14 per 20 matches) and uses TSUKISHIRO against Kenpachi rarely (2): he walks in
too fast for the ring's 24 f tell, which is the design's intent ("one Step clears it").


## Playtest 1 and the rework direction (the user, 2026-09-28)

Problems found in the first hand playtest:
- Her head is too small; enlarge it toward anime proportions.
- Awakened HUD: the temperature text overlaps the COOLDOWN text until −273 C, and the temperature bar overlaps the L
  meter, so the L charge can't be read.
- Yamamoto's and Rukia's L meters look like two cells while only one is usable.
- HYŌSHIN at −50 C reaches farther than REIDO TŌKETSU at −273 C, and −273 C is an immobile state, so −50 C is the
  more useful step. Deeper cold must never be the weaker choice.

**Fixed the same day** (art and HUD only; the sim, the hurt / hit volumes and the G2 hashes are unchanged):
- **Head ×1.3**: `(:head 1.3 1.3 1.3)` in her body's `:girth` (rukia-art.lisp) scales every head shape (skull, face and its
  three expressions, the bob, the zero / Bankai half-crown) about the head joint at the neck's top, so the chin still sits
  on the neck in every clip and cinematic. About 7 heads tall (was ~8.7; Yamamoto ~7.8, Kenpachi ~8), 1.50 m to the crown.
- **The L meter's two cells**: the awakened cooldown slot drew two half bars under one COOLDOWN label, L (steel) and
  Shift+L (ember). Her Shift+L (SHIRAFUNE) has no cooldown, so its half was always full; Yamamoto's was South's 600 f. Both
  read as two L charges, yet L has one use per cooldown. The code was right (one cooldown per command slot, never two
  charges); the display was wrong. Now the slot is **one L bar**, and a Shift+L that has a cooldown (only Yamamoto's South)
  shows as a thin ember line under it while it cools (`hud-cooldowns`, landscape and portrait). Kenpachi never showed the
  row (no awakened L of his has a cooldown). The TEMP bar still covers the L bar in landscape: the temperature rework
  replaces that HUD.

The user's rework direction for the awakened form (it replaces the step ladder of §4.1–4.3 once designed and built):
1. No L meter: the **temperature gauge is the only resource**.
2. When she isn't guarding, the temperature **warms back gradually** (replaces "the timer runs out → reset to −18").
3. The colder she is, the **slower she moves**, and the **worse the opponent can move away from her** (retreat, Step
   out, run away).
4. J / K / L / SP1 / SP2 and the other actions **spend cold** (each warms her by a set amount); spending past a
   threshold drops her back a temperature band.
5. The colder she is, the **stronger** J / K / L / SP1 / SP2 are, each with a **visibly different motion** per band.

Decided the same day: **−273 C stays an immobile state** (no walk, run, Step or Hoho), as built. Deeper cold must
out-pay −50 C through power, reach and the retreat penalty, not through mobility.
**No chosen exit** from −273 C (the THAW input goes): she leaves it only by spending cold with actions or by the passive
warming when she isn't guarding (plus any forced exit the rework keeps, e.g. a crack on a guard break).

**Rework decisions (the user, 2026-09-28)**, on top of the temperature-rework design (all six questions take the
recommended defaults: L-meter removal is awakened-only; −273 keeps the ward + freeze-touch payoff; blocked melee cools and
hits warm; the −18 L becomes the frost pillar so L is one growing family; CRACK stays the only forced exit; holding U at −273
"braces" to stop the warming at a guard-gauge drain):
- **The cold gauge is two stacked bars** (cold C 0–200, 100 per bar), shown **overlaid** in one strip (the
  fighting-game "stacked super meter" read). **Filling a bar moves her one band colder; she only warms back a band when
  that bar is empty again** (the user's words: 第 1 條滿 → −50°，第 1 條回到空 → −18°；第 2 條滿 → −273°，第 2 條回到空 →
  −50°):
  - −18 → −50 when C reaches 100; −50 → −18 when C falls to 0.
  - −50 → −273 when C reaches 200 (both bars full); −273 → −50 when C falls to 100.
  - At −273 the gauge is full: guarding / bracing only holds it there (stops the warming).
  Each band so keeps a whole bar of room above its exit (hysteresis by bars), which replaces the design's separate
  enter / exit thresholds.
- **Spending at −18** (the user asked for my recommendation; adopted as the default): at −18 **only L spends cold** (it
  is L's only limiter now that the L meter is gone, and it is refused without enough cold). J / K / SP1 / SP2 / O / I /
  Step / Hoho are free at −18: there is no band to fall to, so a tax would only punish mixing offence into the climb, and
  the passive warming already makes every non-guarding moment cost progress. At −50 and −273 every action spends.

**Look decision (the user, 2026-09-28):** in her Bankai look (the 白霞罸 cinematic; also the −273 white-hair look, which
shares it) her **eyebrows are a pale, light-blue-tinted white** and her **whole outline (keyline) is ice blue** instead of
the standard ink. The Shikai look is unchanged.

**−273 warms slowest (the user, 2026-09-28):** 「請將 -273° 的回溫速度放緩，使維持在 -273° 的難度減少」. The passive
warming at −273 is the slowest of the three bands (the design had it fastest), so absolute zero is easier to hold; its
limits are the action costs and the crack, not the warming.

## The cold-gauge rework: built (2026-09-28)

Built from the temperature-rework design with the decisions above (§4 and §8 now describe it). Every number below the
design's was moved by the seed gate, the §9 A/B or the "colder never weaker" per-band damage gate.

| Item | Design | Built | Why |
|---|---|---|---|
| Gauge | one bar 0–100, enter / exit thresholds | **two stacked bars, C 0–200**, hysteresis by bars | the user's decision |
| Rates and costs | on 0–100 | rescaled: cooling 30 → **90 / s** (built at 60 / s, the design's 3.3 s to zero; then the user's decision "cool faster": 2.2 s), blocked melee ×0.5 → **×1.5** of its guard value (×1.0 before the faster cooling), hits ×0.1 → **×0.2** of the damage; −50 costs ×2 (J 6, K 12, L 36, SP 40, O 20, I 20, Step 12, Hoho 20), zero's J / K / O **20 / 40 / 60** (×5 = 15 / 30 / 50 first; raised with the faster cooling: the A/B), L / SP1 / SP2 **100**, the whole top bar | a −50 visit now always has a whole bar of room, zero's budget is its top bar |
| Spending at −18 | every action | **only L (25)** | the user's decision |
| Warming | 4 / 6 / 7 per s (zero fastest, ~2.9 s) | **10 / 12 / 5** per s (zero slowest: its top bar lasts 20 s unbraced) | the user's decision "−273 warms slowest" (zero first built at 35 / s = 2.9 s; the gate and the A/B were re-run at 5 / s) |
| Damage dealt / taken | 1.20 / 0.95, 1.35 / 0.85, 1.55 / 0.80 | **1.15 / 0.95, 1.5 / 0.85, 1.65 / 0.8** (a ranged hit through the zero ward ×1.0) | first built at 1.32 / 1.45 / 1.6 (the old awakened ×1.32): the A/B had "always" ahead by 11 (RY) and 9 (RK) of 60; at the design's values −50 dealt less per second than −18 against Kenpachi (19.6 vs 17.5), which the gate forbids; −18 down, −50 and zero up fixed both |
| Zero K3 | freeze 30 (`:bind`) | crumple, frost 150 | the strings budget (every K link 3 crumples, host-tested) |
| Zero J3 | 360°, crumple | the derived J3 (3.51 m, 200°, stagger) | the budget (J link 3 staggers) |
| Cold costs | a move key `:cold` | a kit key `:cold` by command (a latched link pays its button's) | one table per band; the grid moves are shared by the bands |
| AI | −50 `:cool :p 0.35 … :min-gg 50`; zero `:brace (:near 5.5 :min-gg 30)` | as designed, plus −50 guard 0.55 → **0.45** and HYŌSHIN weight 2 → **3**; zero bands add **7.5–14 m: HAKUREN** (its instant wave), `:brace :p` **0.2** (0.5 → 0.35 → 0.2) | −50's damage per second (it spent its time guarding toward zero), zero's against a zoner (the mirror); with zero warming at 5 / s bracing buys little |
| Field look | ring + frost motes at his heels | the ring only (the band's aura, a thin white ring at the radius) | the ring reads "I'm in it"; the heel motes skipped |
| Zero J3 / K2 ice rings, −50 SHIRAFUNE's 4 drawings, the ×1.5 / ×2 flowers | fx | HYŌKA's flower scales with the link's reach (×1.2 / ×1.8); the rest skipped | polish left for a look pass |
| HUD | entry ticks, a dim exit notch | two overlaid bars (the exit is "that bar empty"), three band pips, L's cost dimmed on the top bar, zero's pulse, the THAW grey, the CRACK hairline | the stacked bars show the exits themselves |
| −50 HAKUREN | 80 → 150 | 80 → 149 (23 per stab) | integer damage per stab |

Engine pieces (generic, no character names): the kit slots `:field`, `:warm`, `:cold`, `:crush-hook`, `:frost-touch`
(`:expire-to` and `:crush-to` are deleted with THAW / CRACK, `:rooted` now also stops move slides and the string chase);
rules `temp-next`, `temp-band`, `temp-cool-frames`, `field-velocity`, `field-step`, `field-k`; `cold-add!`,
`cold-spend!`, `opp-field` / `field-slow!`; the `:cold-crack` event; `%hud-temp` / `hud-temp` / `temp-label`; per-body
keylines (`body-variant … :ink`) and the `:brow` palette key (the ice look).

### Knobs (the rework; `duel/lisp/tuning.lisp`, the bands in `duel/lisp/rukia.lisp`)

| Knob | Value | Debug |
|---|---|---|
| `*cold-max*` / `*cold-bar*` | 200 / 100 | — |
| `*ru-cool-rate*` (cold / s guarding or bracing) | 90 (the user's decision: cool faster; was 60) | 46000+k |
| `*ru-block-cool*` (× guard value of a blocked melee hit) | 1.5 (was 1.0) | 62000+k (×0.01) |
| `*ru-hit-warm*` (× damage of a real hit taken) | 0.2 | 63000+k (×0.01) |
| `*ru-warm-m18*` / `*ru-warm-m50*` / `*ru-warm-zero*` (the kit's `:warm`) | 10 / 12 / 5 per s | 55000+k sets zero's (k / 10) |
| `*ru-cold-m18*` / `-m50*` / `-zero*` (the kit's `:cold`) | §4.2 | — |
| `*ru-field-m18*` / `-m50*` / `-zero*` (`:r :away :step`) | 3.0 / 0.85 / 1.0; 4.0 / 0.7 / 0.9; 5.5 / 0.55 / 0.75 | 65000+k (zero's `:away` ×0.01) |
| `*field-floor*` | 0.45 | 66000+k |
| `*zero-brace-drain*` (guard gauge / s while bracing) | 8 | 44000+k (k / 10) |
| `*ru-thaw-lock*` (frames of no cooling after a CRACK) | 120 | 51000+k |
| `*crack-self*` / `*crack-stun*` / `*freeze-touch*` | 60 / 30 / 18 | 47000+k / — / 45000+k |
| `*rukia-awake-mult*` / `*rukia-m50-mult*` / `*rukia-zero-mult*` | 1.15 / 1.5 / 1.65 | 48000+k (zero's) |
| `*rukia-awake-taken*` / `*rukia-m50-taken*` / `*rukia-zero-taken*` | 0.95 / 0.85 / 0.8 | 61000+k |
| `*frost-touch*` / `*frost-touch-m50*` / `*frost-touch-zero*` | 30 / 60 / 90 | — |
| walks / runs | −18 3.4 / 8.0, −50 2.8 / 6.4, zero rooted | 57000+k / 56000+k |
| `*ai-ru-l-after-k*` / `*ai-ru-l-after-k-awake*` (the CPU's L after a K link, per hit; playtest 2) | 0.05 / 0.1 | 72000+k / 73000+k (k / 100) |
| `:ru-tsukishiro-k` (the Shikai's K → L copy) | 8/0/26, `:delay` 10, reach 8.0 | — |

Retired: `*cool-frames*`, `*warm-frames*`, `*zero-seconds*`, `*thaw-seconds*`, `*crack-seconds*`, `*walk-thaw*` (and
debug 52000+k). New debug: 2125+k one gate pairing alone (0 YY … 5 RR: the gate in parallel), 67000+k P1's cold = k and
its band, 68000 the white Rukia with the old ink keyline (before / after stills), 69000+f / 70000+f a close-up of her face
at zero / in the 白霞罸 costume, 2418 zero 3 m from an idle Kenpachi (hold U to brace). After every gate row a `duel band`
line per awakened Rukia side: frames, damage dealt / taken per band, zero visits, exits by CRACK / by spending or warming,
bracing frames, freeze-touches (`band-acc-step`, debug only).

### Measurements (the cold gauge rework, the final build; seeds 1–20, debug 2113)

| Pairing | K.O. | Median (s) | Wins |
|---|---|---|---|
| YY | 20 / 20 | 134.7 | P1 9 / P2 11 |
| YK | 20 / 20 | 136.2 | Yamamoto 12 / Kenpachi 8 |
| KK | 20 / 20 | 131.2 (was 125.8: one pip per string) | P1 13 / P2 7 |
| RY | 20 / 20 | **135.6** | Rukia 11 / Yamamoto 9 |
| RK | 20 / 20 | **148.1** | Rukia 13 / Kenpachi 7 |
| RR | 20 / 20 | **183.1** | 8 / 12 |

120 / 120 K.O., every median in 125–210 s. The parallel runs (2125+k) give the same rows as the sequential 2113. (The
same gate with the cooling at 60 / s and zero's J / K / O at 15 / 30 / 50, before the "cool faster" decision: RY 143.3,
RK 163.8, RR 184.3 s, Rukia 8 / 8.)

**The §9 A/B** (seeds 1–60, P1 Rukia always / never awakening vs the rule-driven CPU): RY **30 / 28** (+2), RK **35 / 32**
(+3), RR **26 / 27** (−1): |Δ| ≤ 3 ≤ 9 and "never" wins RR, so the awakening is a sidegrade. (With the first-built
multipliers it was +11 / +9 / 0; right after the faster cooling, before zero's costs went up, 0 / +1 / +3: no pairing
favoured "never".)

**Colder never weaker** (her damage dealt per second in band, −18 / −50 / zero; the gate, 20 seeds): vs Kenpachi
**19.1 / 27.0 / 55.5**, vs Rukia (RR) **14.7 / 25.1 / 34.2**, vs Yamamoto 24.9 / 34.6 / 51.1: rising in every pairing. On
the 60 "always" seeds: 20.1 / 27.5 / 66.1, 15.8 / 24.9 / 32.2, 26.0 / 34.8 / 53.8.

**Zero, RK (the gate):** 35 visits in 20 matches (19 of the 20 have at least one), 16 of them ended by a CRACK (46 %; on
the 60 "always" seeds 28 of 96, 29 %: the 15–40 % target holds on the larger sample only), 6 % of her awakened time
(≤ 25 %), 27 freeze-touches. Time in band, all three pairings: −18 61–63 %, −50 31–36 %, zero 3–6 %. With zero warming at
5 / s bracing buys little (it saves 5 cold / s at 8 guard / s): the CPU braces rarely (`:brace :p` 0.2). The band log
doesn't split the CRACKs into crushes (blocks, bracing) and Breakers.

**Faster cooling (the user, 2026-09-28):** 「加快露琪亞降溫的速度」. Guarding (and the blocked-melee bonus) cools her
noticeably faster than the rework design's pacing (target ~1.5×: about 2 s of guarding per bar).

**Playtest 2 decisions (the user, 2026-09-28):**
- White Rukia's **eyelashes** take the same pale ice colour as her brows.
- **K → L combo, both forms:** her L can be chained after a K link of a string (Shikai and awakened) and connects as a
  combo on hit (still guardable when the K was blocked).

**Combo band-lock with overdraft (the user, 2026-09-28):** 「只要還在 combo 狀態溫度就不換帶……透過透支溫度的方式打出原本
無法用的 combo」. While a combo runs (a string's first link through every chained follow-up: links, K→L, the O ender, SP
cancels) the band stays the one it started in; moves spend their normal cold and are never refused for lack of cold while
C > 0 (overdraft, C clamps at 0). When the combo ends the band re-resolves from what is left, possibly more than one band
at once (C = 0 → −18 even from −273). The −273 costs stay J/K/O 20/40/60, L/SP 100 (the user's 20/30/40 idea is held
back until a playtest shows zero is too short).

**Calm Bankai face (the user, 2026-09-28):** 「露琪亞開卍解的動畫不要張嘴吧」: no open mouth anywhere in the 白霞罸
cinematic; a closed, composed expression throughout.

## Playtest 2: built (2026-09-28)

**Lashes.** The white looks (`:rukia-zero`, `:rukia-bankai`, rukia-art.lisp) map `:lid` (the lash lines, their flicks,
the shout's and the hurt face's eye lines) to the brows' `#CFE3F2`. The hurt face's teeth line, which also used `:lid`,
has its own key `:clench` (the Shikai's dark `#141016`, kept in every look), so the normal look is unchanged. Debug 68001
puts the dark lashes back (the before still).

**K → L.** The generic kit key `:l-after-k` (DUEL_STRINGS.md §12; `kit-l-link`, the latch in `move-commands`):

| Form | L after K1 / K2 / K2s / K3 | Hit frame of L | Measured stun left at L's hit (K1 → L / K3 → L) |
|---|---|---|---|
| Shikai | `:ru-tsukishiro-k`: TSUKISHIRO's copy, 8/0/26, ring at f8, pillar `:delay 10` (f18), `:reach 8.0` (no chase), clip at 10 / 8, tell (8 17), cooldown 150 shared | 18 | 5 / 18 f |
| −18 | SHIMOBASHIRA as it is (`:l-after-k t`), cold 25 | 12 | 11 / 24 f |
| −50 | HYŌSHIN, cold 36 | 14 | 9 / 22 f |
| −273 | REIDO TŌKETSU, cold 100 (the overdraft) | 10 | 13 / 26 f |

The frame math (host-tested for every K link of every form): from the K link's hit, `A(K) + hit(L) < hitstun(K)`: after
K1 / K2 (A 4, stagger 26) the Shikai's copy is 4 + 18 = 22 < 26 (+4; the probe measures 5 stun frames left), the plain
TSUKISHIRO would be 4 + 34 = 38 (no combo, hence the copy). A `:bind` in a combo is a flinch (rules `combo-step`), so the
ring / REIDO end the combo instead of looping. Blocked: the L comes out at block timing and is guarded (`duel probe kl`
5 / 6: GUARD-HIT, no crush). −18 with 10 cold: refused (probe 4).

**The combo band lock with overdraft** (the user's decision 2026-09-28, §4.1–4.2): rules `temp-band-at` (the band holds in
any state but idle / guard / run) and `cold-ok-p` (a chained L on credit while C > 0), `kit-command-ok-p`'s new COMBO
argument (set by the K → L latch and chain, and the CPU's roll). Probe: −273 K K K (C 200 → 73 after the warming) + REIDO
(stun 26 left) → C 0 → −18 on her first free frame. The −273 costs are unchanged (20 / 40 / 60, L / SP 100).

**Calm Bankai face.** `ru-hakka-cine` holds her face at `:neutral` for the whole cinematic (`face-beat`); the zero kit
gets `:calm t` (a generic kit key: `face-of` returns `:neutral` where the form would shout), so the white-haired battle
face never opens its mouth either (it used the shout on every non-J move before). The −18 / −50 battle faces and the
awakening cinematic keep the shout. The debug close-up 70000+f is calm too.

**AI.** `string-reflex` rolls L on a K link's first hit step: `:ai :l-after-k` = `*ai-ru-l-after-k*` **0.05** (Shikai) /
`*ai-ru-l-after-k-awake*` **0.1** (the bands); knobs debug 72000+k / 73000+k. No roll when the chance is 0.

**Measured** (debug 2113-style gate, 20 seeds per pairing, NORMAL; final build):

| Pairing | K.O. | Median (s) | Wins |
|---|---|---|---|
| YY / YK / KK | 60 / 60 | 134.7 / 136.2 / 131.2 (identical rows: no Rukia) | 9-11 / Yama 12 / 13-7 |
| RY | 20 / 20 | **134.1** (was 135.6) | Rukia 13 / Yamamoto 7 |
| RK | 20 / 20 | **144.9** (was 148.1) | Rukia 13 / Kenpachi 7 |
| RR | 20 / 20 | **185.6** (was 183.1) | 12 / 8 |

**The awaken A/B, and why its 60 seeds can't judge this change.** Any roll the CPU makes changes the seeded random
stream, and the A/B moves with the stream, not with the feature: over seeds 1–180, with the CPU's chance at 0.01 (the
roll made, the chain almost never taken) RY / RK / RR = **+32 / +31 / +2** (always − never); at 0.2 / 0.2 +36 / +32 / −2;
at the final 0.05 / 0.1 **+42 / +31 / +12**; with no roll at all (the old stream, identical to the build before) +13 /
+13 / +7, and seeds 1–60 of that stream give the documented +2 / +3 / −1. So the chain itself is inside the noise, and the
old stream's small Δ was its own luck (the knobs had been tuned on it): on a fresh stream the awakening is worth ~+10
wins per 60 against Yamamoto and Kenpachi, an upgrade that predates this batch. Left for a balance pass (the levers of
§9: `*rukia-awake-mult*`, zero's costs, the CPU's awakening rule).

## The awaken A/B across seed streams (2026-09-28)

**The user's decision (2026-09-28):** 「覺醒偏強沒關係，只要不是強到無法贏就好」: the awakening may be the stronger
choice; what matters is that not awakening can still win. **The A/B's acceptance is now**: on each of **≥ 3 independent
seed streams** (60 seeds each), the "never awaken" policy wins **≥ 20 of 60** against each opponent (RY, RK, and RR
against a P2 on the rule). "Always" may be ahead; there is **no target on the margin** (the old |Δ| ≤ 9 of §9 is
retired, and so is "at least one pairing has never > always").

**Method.** One 60-seed run is one draw of the RNG stream: any extra CPU roll anywhere (playtest 2's K → L chance)
reshuffles every later decision, and on the stream the knobs were tuned on (seeds 1–60 of the build before playtest 2) the
margin read +2 / +3 / −1 while seeds 1–180 of a fresh stream read +42 / +31 / +12. So a result is only trusted when it
holds on several disjoint seed windows of the same build: debug `39010` / `39020` (P1 Rukia always / never on EVOLUTION,
P2 on the rule), `30000+k` (the gate plays seeds k+1 .. k+20), `2128` / `2129` / `2130` (RY / RK / RR alone), three runs per
60-seed stream. A 60-match win count carries about ±4 of noise (one standard deviation near 50 %), so a stream is one
sample, and a margin tuned on one stream says little about the next.

**Measured** (the build as merged at c39dd9c, unchanged: no knob moved; P1 wins, always / never, always − never):

| Pairing | seeds 201–260 | seeds 401–460 | seeds 601–660 | all 180 | never ≥ 20 on every stream |
|---|---|---|---|---|---|
| RY | 35 / **23** (+12) | 33 / **24** (+9) | 37 / **31** (+6) | 105 / 78 (+27) | yes (lowest 23) |
| RK | 35 / **30** (+5) | 39 / **28** (+11) | 31 / **26** (+5) | 105 / 84 (+21) | yes (lowest 26) |
| RR | 39 / **34** (+5) | 34 / **28** (+6) | 28 / **31** (−3) | 101 / 93 (+8) | yes (lowest 28) |

The criterion holds, so **nothing was retuned** (the user's instruction: retune only a stream / pairing that fails, with
the smallest change). The awakening is the stronger choice by ~+9 / +7 / +3 wins per 60 against Yamamoto / Kenpachi /
herself, which the decision allows; the design's matchup table (§4.6) wanted the Shikai ahead against Yamamoto, and it
isn't: the tightest cell is "never" vs Yamamoto on seeds 201–260 (23 of 60), about one standard deviation above the line.
If a later change pushes a stream under 20, the levers found here (a trial before the decision, one stream set each):
`*rukia-awake-mult*` 1.15 → 1.05 moved RY by about −9 per 180 and RK not measurably; the rest (the field's `:away`, the
bands' `:taken`) were not finished. **Colder never weaker** holds on these 180 "always" seeds (her damage dealt per second
in band, −18 / −50 / zero): vs Yamamoto 26.1 / 36.3 / 47.0, vs Kenpachi 20.5 / 28.6 / 56.1, vs Rukia 15.8 / 24.9 / 35.0.
Time in band −18 59–64 %, −50 30–38 %, zero 3–8 %.

**The seed gate** (debug 2125+k in parallel, seeds 1–20; identical to "Playtest 2: built"): YY 134.7 / YK 136.2 / KK 131.2
/ RY 134.1 / RK 144.9 / RR 185.6 s, 120 / 120 K.O.; wins P1 9 / 12 / 13 / 13 / 13 / 12.

**Knobs**: unchanged (the table under "The cold-gauge rework: built").

### No cooldown on TSUKISHIRO (the user, 2026-09-29)

「請取消一護跟露琪亞 L 技的冷卻時間，如果要避免惡意連放的話，設計適當的前後搖破綻就好了」: SOME NO MAI: TSUKISHIRO loses its
150 f cooldown. Instead S 10 → **12** and R 26 → **36** (48 f a cast; the move now outlasts its pillar, S 12 + delay 24 =
f36, so there is still one ring at a time), the CPU victim's tell shifted to (21 30); the K→L combo copy keeps S 8 / delay
10 and inherits R 36. Native gate: RY 139.8 s (Rukia 12 / 20), RK 154.5 (13), RR 176.9, IR 190.8, all K.O.

### −273 guards ranged hits too (the user, 2026-09-30)

「［修改設定］露琪亞的 -273° 將飛行道具也納入防禦冰之防禦的範圍」: the zero ward now blocks projectiles, hazards and
`:ranged` windows as well as melee. The `:optic` passive is removed from `:zero` (the canon optical loophole above is no
longer modelled; `optic-p` stays in rules.lisp, unused). The garb-block look now keys on `:freeze-touch` so her blocks keep
the ice look, not West's fire. Native gate: RY 139.8 s (Rukia 12 / 20), RK 154.5 (14), RR 176.9, IR 193.4, SR 189.9, all
K.O.; her A/B ("never" wins of 60, streams 100 / 300 / 500): RY 33 / 27 / 35, RK 42 / 33 / 35, RR 33 / 39 / 32.
