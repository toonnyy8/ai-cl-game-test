# SOUL DUEL: Shutara Senjumaru (修多羅千手丸), Shigarami and 娑闥迦羅骸刺絡辻 SHATATSU KARAGARA SHIGARAMI NO TSUJI

Status: **built 2026-09-28** (the design of 2026-09-28 with the user's decisions of the same day, §"User decisions" below,
which override the body where they differ). The body below is the design as approved (its numbers were proposals); the
as-built values are in "Built: deviations", `duel/lisp/senjumaru.lisp` (knobs at its top) and `duel/lisp/senjumaru-art.lisp`;
the measurements close the file. Everything of hers lives in those two files (the user's code layout, DUEL_DESIGN
"Character code layout"): the shared files got only small generic hook points (listed in "Built").

## Summary

- **The Shikai 刺絡 SHIGARAMI is a close-range tailor: sew first, detonate later.** Every J / K / O contact sews stitches
  into his clothes (+2 on a hit, +1 on a block, 6 at most); red threads stand out of his torso, and 3 s without a new
  stitch they start to fall out one by one. L 悪い癖 WARUI KUSE pulls them all out at once: 13 each (21 after her ×1.6; 10 until 2026-10-01), **unguardable**, never
  a Soul Break (the last Reishi point is spared). Out of a combo it is a frame trap; after a K link it is a combo (scaled).
- **The other buttons**: SP1 神兵 SHINPEI summons a Divine Soldier that stands until she is free, walks the line to him and strikes **one three-hit string** (since 2026-10-01; two lone thrusts before); one
  hit kills it, and it **bursts into thread and sews one stitch into whoever destroyed it** (the user's decision). SP2 傘 KASA
  catches projectiles and hazards (no stun, no gauge) and **always** fires the tendrils back (40 + half the largest caught
  hit, at most 120; the user's decision). O 縫地 NUICHI is a flash step into the six-armed whirl (it sews); its Kikon is
  仕立て直し (the Nianzol kill, 2 Konpaku).
- **The awakening 娑闥迦羅骸刺絡辻 (all anime-original) is a loom whose order is public.** It removes the stitches and
  悪い癖, the soldier, NUICHI, and some walking speed. It adds six hanks cycling in a fixed order (黒砂 → 刃金 → 褥 → 焼野原 → 眼 → 星 since 2026-09-30: three SP1 pairs), one live at a time.
- **L held weaves, L tapped releases** (the user, 2026-09-29): held ≥ 10 f she weaves (a pass per 20 f, up to 3, bigger
  and longer with each), summed over as many short segments as she likes on the same hank; a tap (< 10 f) unfolds it under
  him at the stored passes. A hit on her while she weaves **voids** the hank (its passes are lost, the queue
  moves on); a hit while the zone unfolds **tears** it (L locks 90 f).
- **J weaves, K releases** (the user, 2026-09-29): a hank is released only with **at least one pass woven** (a tap or K → L
  at 0 is refused, the loom row flashes); **J → L** (一越 HITOKOSHI) weaves one pass at once as a string ender. The loop:
  J-ended strings weave, K → L spends the woven hank inside a combo. SP1 is the one release that needs nothing woven. SP1 裁ち直し TACHINAOSHI (since the
  user's decision of 2026-09-29) releases the next two hanks at once, no weave, for a bar: a string ender; O is the red-carpet lane UKIMON NO HATA, whose Kikon is 死出六色浮文機 (3 Konpaku).
- **The six hanks**: 眼 (a ring of mirror-eyes: his waves turn back at him, his melee on her costs him 30 %), 刃金 (the
  iron maiden closes once: guarding it costs double), 黒砂 (a pit that drags his walk away from it and gulps 1–3 times), 褥
  (a mine that freezes him), 焼野原 (a burning corridor from her to him), 星 (a dome round her that drains his Reiatsu and
  flash-step). Every disc is ≤ 2 m in radius: one Step always gets out.
- **One resource per form, in one row**: the Shikai's 針 HARI (six needle pips), the Bankai's 機 HATA (six hank swatches in
  queue order). No COOLDOWN row: nothing overlaps.
- **Why a sidegrade**: keep the Shikai against Kenpachi (his stance and DRINK still get sewn, the unguardable needles go
  through; a rusher tears weaves); awaken against Yamamoto and zero Rukia (眼 turns his fire back; zones are hazards that pass
  zero's optic ward; a rooted Rukia can't walk out).
- **The CPU awakens** once it has taken ≥ 150 with ≥ 30 % from ranged hits, or at once against a rooted form.
- **Cinematics** (unskippable, every shot `shot-on` its subject): the awakening 180 f (three candles going out, a torii,
  the golden loom, the carpet and the drapes), the Shikai's Kikon 186 f, the Bankai's Kikon 198 f.
- **Look**: 158 cm on tall okobo, the head ×1.3, a white haori over a white over-robe, a gold crescent with rays; six gold
  bone arms = the rig's two + four drawn "echo arms" that repeat every motion 2 / 4 frames late (no rig change).

---

## 0. Frame of reference

- **Conventions:** DUEL_DESIGN §0 (60 Hz, S/A/R, move frame 0 = first frame). Every J/K form obeys the DUEL_STRINGS §2.1
  budget, host-tested per form. Callouts use romaji; the brush columns use kanji. Move and clip prefix `:sj-`; character
  keyword `:senjumaru`.
- **Canon marks** (§13 is the full ledger):
  - **[V]** manga canon, verified in `docs/research/tybw-characters/notes/senjumaru.md`;
  - **[A]** anime-only (TYBW ep. 25–27, 2023-09 / 2024-10);
  - **[G]** our game interpretation or an invented name.
- **The canon beats this design encodes,** each written as the opponent's counterplay verb (sidegrade_design Q3):

| Canon | Mechanic | The opponent's verb |
|---|---|---|
| She re-tailors Nianzol's robe unnoticed; the needles left in it impale him from inside; "my bad habit" [V ch. 598–599] | base: her J/K contacts **sew stitches** into his clothes; L 悪い癖 pulls them all, **unguardable** | break contact (the stitches fall out after 3 s); read the yank and Hoho through it |
| She is weak in a straight fight: Gerard shatters her needle with one slash [V ch. 599] | the lightest strings in the game (J1 25) and short reach | out-range her; trade K for J |
| Divine Soldiers fight for her; Pernida crushes the big one [V ch. 597, 599] | SP1 神兵: a proxy that walks at him and **dies to one hit** | swat it (it walks into his arc) |
| The umbrella blocks Licht Regen and fires it back as tendrils [A ep. 25] | SP2 傘: catches projectiles and hazards, then fires back | don't shoot into it; strike her (melee is only guarded) or Break it |
| The Bankai unravels **one hank at a time** [A ep. 26] | one live zone; the queue is public (three SP1 pairs) | read the next hank on the HUD; stand where it can't reach |
| Each hank must be **woven** before it is unravelled [A] | L is held to weave (20–60 f), visible and vulnerable | rush the weaver |
| The Almighty frees Uryū; losing control breaks it [A ep. 27] | a hit on her while she weaves or unfolds **tears** the hank | hit her during the weave: the hank is lost and the loom locks for 90 f |
| She is **cut off from her own Bankai** by Antithesis [A ep. 27] | not used (§12, dropped ideas) | — |
| The Blood Oath: full power only once the other three are dead [A ep. 26] | the awakening cinematic's three candles (Q11); no gameplay cost | — |

- **The six sidegrade rules** (report §「跨角色原則」), and where each is met:
  1. **Kikon count.** The awakened count stays 3 (the user's decision). The offsets are that the awakened form gives up
     the stitches (its strings deal −3 %, and there are no free unguardable 60s), walks slower, and pays for every zone
     with a visible weave. The A/B's knobs are in §9.
  2. **Named removals.** Awakening removes 刺絡の針 (the stitches) and 悪い癖, 神兵, 縫地, and some walking speed (§4.8).
  3. **No heal.** (superseded 2026-09-30: every awakening heals 20 % of max Reishi, DUEL_DESIGN.md "Awakening heal").
  4. **Voluntary cheap, forced expensive.** A voluntary short weave costs nothing but zone size. A torn weave costs the
     hank and a 90 f lock.
  5. **The choice happens mid-match.** P is manual; the CPU follows a rule (§7.1).
  6. **The Fighting Spirit gauge** is unchanged.

---

## 1. Summary

At the top of this file (the player-facing zh-TW text is in docs/guides/TUTORIAL.zh-TW.md §9.2, the build notes in docs/DEVLOG.zh-TW.md §27).

---

## 2. Identity and silhouette

**Who.** Squad Zero's Great Weave Guard (大織守), the fourth officer of the Zero Division, the Divine General of the North,
and the inventor of the shihakushō [V].
- **Build:** 158 cm, the shortest of Squad Zero, on very thick okobo (tall clogs).
- **Manner:** polite, serene and composed, with a dark playfulness [V]. Her face is never a shout: the kit key `:calm t`
  (Rukia's zero precedent). She has two expressions: a half-lidded neutral, and a small closed smile (her "hurt" face is
  a narrowed glare).

**Costume** [V; verify the TYBW anime model sheet for the collar and the over-robe's cut]:
- a black shihakushō under a **white haori and a white over-robe** (ankle-length);
- long straight **black hair** with the side locks;
- a large **golden crescent-moon ornament with rays** behind her head, standing off the skull like a halo;
- the okobo.

**The six arms** [V ch. 517: "six long, golden, skeletal prosthetic arms on her back that she uses instead of her own hands"].
Her own hands stay in her sleeves. The engine rig has 21 fixed joints, and we don't change it:
- **The rig's two arms become the upper pair of golden bone arms.** The `:senjumaru` body skins `:upper-arm-*`,
  `:lower-arm-*` and `:hand-*` as gold bone segments rooted a little behind the shoulders. The sleeves hang empty from
  the real shoulders.
- **The other four are "echo arms" (engine gap N12, art only):**
  - Each is a three-segment gold bone chain drawn from an anchor on the upper back (two at mid-back, two at the waist).
  - Its hand targets the rig hand's position, rotated about the spine axis by ±28° (middle pair) and ±52° (lower pair)
    and taken from the joint history **2 f and 4 f late**. It reuses the ribbon's position-history machinery.
  - So every strike reads as a fan of hands arriving in a ripple.
  - At rest the four settle into a **half-fan behind her**, framing the crescent.
  - No hurt volume: her hurt cylinder is the body's.
- The umbrella, the loom threads and the shears are fx drawn between the six hands.

**Weapon.** The Shikai **刺絡 Shigarami** [A name] is a **sewing needle** [A], ~0.9 m and white-gold, held in the right rig
hand (`:shigarami`).
- An endless **red reishi thread** runs from its eye [A]: an fx ribbon on the pommel-trail machinery, drawn thin.
- The needle is always out; there is no sealed form (canon never showed one).

**Proportions.**
- `:scale 0.88 :width 0.9 :hunch 0`, and the okobo add 0.10 m, so she stands ~1.68 m to the crown and ~1.95 m to the top
  of the crescent.
- **Anime head** `(:head 1.3 1.3 1.3)` in `:girth` (the user's Rukia decision); the crescent scales with the head.
- Hurt cylinder **r 0.36 / h 1.70**. It is a fairness floor like Rukia's: the crescent and the arms add no hurt volume,
  and arcs built for 0.36 / 1.65 bodies must not pass over her.

**Palette** (v4 notan, STYLE_STORM §A.1, §2.5; **no new spot hue**):

| Key | Lit | Note |
|---|---|---|
| `:white` | #ECECE8 | the haori and over-robe: one white mass, cold-grey shadow |
| `:black` | #16161E | the shihakushō showing at the collar and sleeves |
| `:hair` | #0C0C12 | solid black with three white highlight strokes #D8DCE4 |
| `:skin` | #E2CCBC | muted |
| `:gold` | #B89A5A | **muted gold (S ≤ 0.45: not a spot hue**, as Ichigo's orange hair): the crescent, the six bone arms (#C2A866 lit), the loom |
| `:madder` | #7A2E34 | **muted madder (S ≤ 0.45)**: the domain's cloth, the red carpet, the burning cloths. It is **not BLOOD** (§12 M1) |
| thread | BLOOD, 1–2 px lines only | the red reishi thread and the stitches' threads; BLOOD is universal, so it is kept thin |
| hank dyes | S ≤ 0.45 | 眼 purple #6A5A7E, 刃金 gold #A8904E, 黒砂 ink #22222A (grey spiral), 褥 blue #5E7890 (white snowflakes), 焼野原 madder #7E3A34 (ink trees), 星 night blue #2E3656 (a white star) |

**How she reads against the other four:**
- Yamamoto is a hunched white haori with FIRE.
- Kenpachi is 2 m, a white sleeveless haori and yellow.
- Rukia is small, all black, one white line.
- Ichigo is tall and black, with an orange head and two blades.
- **Senjumaru is a small white figure on high clogs with a gold halo and a gold fan of six bone arms.** She is the only
  radially symmetric silhouette on the plaza.

**Form looks:**

| Form | Look |
|---|---|
| base | the needle in the upper right hand, the red thread trailing; the echo arms in a half-fan; stance `:sj-stance` (upright, the needle raised at shoulder height, the clogs together); no aura |
| awakened (every hank) | the same body; stance `:sj-loom-stance` (the arms spread wider, the upper pair raised as if at a loom); **aura `senju-aura-tsuji`**: loose madder cloth strips and red threads drifting round her at **alpha 0.45, half the MSAA samples** (the user's see-through aura rule); the **domain**: while she is awakened the plaza's rim of broken walls hangs with madder cloth drapes (a stage look, no collision, §10 N12); the **loom**: a golden torii-shaped loom stands at the rim behind where she awakened (a stage prop, a look) and red threads run from it to her upper hands **while she weaves** |
| weave (the L hold) | the six hands work in a ripple (the echo lag); a bolt of the current hank's dye grows in the air between them, one fold per pass |

---

## 3. Base kit: 刺絡 SHIGARAMI (the Shikai, form `:base`) [A name; V tailoring]

Identity: **a close-range tailor with a delayed payoff.** Every contact of her strings sews stitches into his clothes, and
L pulls them out as unguardable spikes. Her straight exchange is the weakest in the game; the stitches are her damage.
The soldier and the umbrella let her work from 3–7 m.
- Walk **3.6 m/s**, run **8.5 m/s** (`*walk-senju*`, `*run-senju*`); canon gives her expert Shunpo [A].
- Kikon **2**, Soul Break 3.
- Damage ×1.0 dealt and taken (`*senju-mult*`, `*senju-taken*`).
- U is the universal guard (200°, the gauge, GUARD HOLD).

### 3.1 The one resource: 針 HARI, the stitches [G mechanic; V ch. 598–599]

| Rule | Value (knob) |
|---|---|
| **Where** | her kit meter holds the count, **0–6** (`:meter (:name "HARI" :max 6 :count t :decay (180 30))`, engine gap N1). The count is hers: it counts the needles she has left in **his** clothes |
| **Sewing** (the kit key `:sew (:hit 2 :block 1)`, gap N1) | every contact of her own **J / K link or O strike** window: **+2 on a hit / counter-hit**, **+1 on any other contact** (blocked by a guard, the ward, DRINK, armour, Kenpachi's stance absorb, a Guard Break). It is paid at KŌSEI's call site (`kosei!`), so the definition of "contact" is KŌSEI's. **A parried hit sews nothing** (no contact). Hazards, the soldier and the tendrils sew nothing. Capped at 6 |
| **Decay** | after **180 f** without a new stitch, **one falls out every 30 f** (a full 6 is gone 330 f after the last one: 5.5 s). This is `pip-step`'s crack clock with a shorter period, and it is paused while she is in a lock (hitstop, a cinematic) |
| **Tell** | a red thread from his torso for each stitch, drawn from her kit meter onto **his** model (a look), and fading as each one falls. HUD: her needle pips (§8) |
| **Spent** | by L on its frame 0 (all of them). Set to 0 at every Kikon / Soul Break reset and at the awakening (the awakened kit has no count meter) |
| **Why stitches, and not a damage bonus** | canon's re-tailoring is a *delayed* kill set up by contact. Here blocked contact still sews, so turtling gives her unguardable damage, which is KŌSEI's direction ("from passive to active") |

### 3.2 J / K grid (DUEL_STRINGS §2.1; K2 / K3 at 80 % as for every form; every link sews)

Since 2026-10-01 (the user) every form's J is ×0.9 and K ×0.8 of the values in brackets; the routes below are the
old ones (§"The soldier's string, lighter strings, wider weave steps" has the new).

| Link | Name | Clip | S/A/R (enter → S_eff) | Dmg | React | Blk | Whiff | Volume | Guard | Pose (one line) |
|---|---|---|---|---|---|---|---|---|---|---|
| J1 | 一針 HITOHARI `:sj-j1` [G] | **new** `:sj-q1` | 7/3/12 | 25 (28) | flinch | −2 | 20 | **1.44 m** 90° (was 2.4), slide 0.5 | 8 | the upper right hand jabs the needle; the echo hands ripple behind it |
| J2 | 返し縫い KAESHINUI `:sj-j2` / `-j2s` [G] | **new** `:sj-q2` | 7/3/13 | 25 (28) | flinch | −2 | 21 | **1.44 m** 110° (was 2.4) | 8 | the backstitch: the needle drawn back across, the thread pulled taut |
| J3 | 千手 SENJU `:sj-j3` (ender) [G] | **new** `:sj-spin` | 8/3/18 | 32 (36) | stagger | −4 | 26 | **1.44 m** 220° (2.4 before the J cut, 2.6 before the first playtest) | 8 | all six hands fan out and whirl in a ring of needles; the clogs stay planted |
| K1 | 待ち針 MACHIBARI `:sj-k1` [G] | **new** `:sj-f1` | 17/4/20 | 48 (60) | stagger | −3 | 32 | line 0.3 → **2.9** (was 3.2) | 14 | two hands draw long pins back past the hip and drive them straight out |
| K2 | 纏り MATSURI `:sj-k2` / `-k2s` [G] | **new** `:sj-f2` | 21/4/24 (7 → 14) | 40 (50) | stagger | −3 | 36 | **2.5 m** 140° (was 2.8) | 14 | the hem stitch: a rising loop of thread whipped up and over him |
| K3 | 絎け KUKE `:sj-k3` (ender) [G] | **new** `:sj-drop` | 21/5/34 (7 → 14) | 59 (74) | crumple | −20 | 46 | **2.5 m** 160° (was 2.8), h 0–1.4 | 18 | the blind stitch: all six hands slam pins down round his feet, held 3 f |

Since the playtest every reach is where the art strikes: the J links' is the tip of the needle (now as tall as she is),
and K1 / K2 / K3 each throw a prop out to their volume (below, "Playtest: reach matches the art").

**Budget check:**
- Startups: J1 7, J2 7, J3 8 (limits 7–10 / 7–9 / 8–10). K1 17 (limit 16–20; K1 − J1 = 10 ≥ 7). K2 / K3 enter at S_eff 14.
- R and block advantage are exactly the budget's.
- K2 / K3 combo after a J (A 3 + 14 = 17 ≤ 17) and after a K (≤ 21).

**Routes on hit:** JJJ 92, JJK 130, JKK 152, KKK 184, KKJ 146, KJJ 124; the O ender adds 63.
- Every hit route fills the needles to **6**; a 2-link route leaves 4.
- Kenpachi's base: 112 / 150 / 175 / 210 / 172 / 147.
- Hers are the lightest in the game; the stitches (60 more at full, §3.3) are the difference.

**Blocked:** JJJ 24, KKK 46 (the universal numbers), and **3 stitches** either way (30 unguardable later).

### 3.3 The rest of the buttons

| Input | Move | S / A / R | Dmg | Block | Notes | Pose |
|---|---|---|---|---|---|---|
| L | **悪い癖 WARUI KUSE** `:sj-warui-kuse` [V line ch. 599; G move] | 8/0/24 (32 f) | 13 × n (10 until 2026-10-01) | **unguardable** | **Refused at 0 stitches** (the refused flash on the needle pips; `kit-command-ok-p` reads the count, gap N1). No cooldown: the stitches are its limiter.<br>**Spent on frame 0:** all n stitches (1–6).<br>**The spikes:** from f10, one every 2 f (f10, 12 … 20). Each is a disc hazard **stuck to him** (the `:freeze` kind, r 0.2, h 1.8, `:stick t`, gap N5): **10** each, flags `:unguardable :ranged :spare` (gap N2: **never takes his last Reishi point, so no Soul Break**, the research report's rule). The react is a flinch with **stun 8** (the last one **18**).<br>**Frames:** chained 2 f apart, the spikes hold him through f20 + 18 = f38; she is free at f32, so she is **+6: a frame trap, not a combo** (her J1 lands at f39).<br>**Ranged:** no parry catches it and it pays no KŌSEI.<br>**The counterplay:** Step / Hoho iframes dodge the spikes (each is a hazard hit). Since they sit inside him, **a Hoho pressed during f0–f20 is always a perfect Hoho** (`hazard-threat-p`); the 8 f yank can't be reacted to, so this is a read.<br>**After a K link** (the kit's `:l-after-k :sj-warui-kuse-k`, DUEL_STRINGS §12): the combo copy, S6, spikes from f8. From a K link's hit: A 4 + 8 + 2 × (n − 1) ≤ 22 < stagger 26, so **it combos, with the combo scaling**. Out of a combo it is unscaled: waiting pays more (§3.5) | three upper hands grip the threads and yank them back over her shoulder; the needles burst from inside his clothes |
| Shift+K | SP1 **神兵 SHINPEI** `:sj-shinpei` [V ch. 597 / 599; Brave Souls SA3] | 16/0/22 (**10/0/10 since 2026-10-01**) | 50 × ≤ 2 (**now 20 + 20 + 34, one string**) | guard 14 | **Superseded 2026-10-01** (§"The soldier's string, lighter strings, wider weave steps"); the first build: **The summon:** at f14 a tapestry drops 1.5 m ahead of her on the line to him (a look, [V ch. 598]); at f16 a Divine Soldier steps out of it.<br>**The soldier** (a `:clone`-kind hazard with a body, Ichigo's gap 8, plus a `:think` hook, gap N4, and `:frail`, gap N3): 1.9 m, faceless, cloth-wrapped, with a spear (body `:shinpei`, §10).<br>- It **walks at him along the line at 2.4 m/s** (turning 120°/s), so it arrives in front of him, inside his arc.<br>- Within 2.4 m it stops and winds up (**tell 18 f**, the spear drawn back), then thrusts: a `:rift`-style hit whose volume is in its frame, `:cap 0.3 → 2.6 h 1.2 r 0.35`, **50**, stagger, guard 14.<br>- It rests 50 f, then walks and strikes again; **2 strikes max**, life **300 f**.<br>**Guarding it:** `:src` = Senjumaru, so a guard facing her blocks it (no front / back unblockable; Ichigo's B3 rule).<br>**Frail:** any of his melee hit windows or hazards that touches its cylinder (r 0.4, h 1.8) destroys it (Pernida crushed one [V]), with a cloth-burst look.<br>**Limits:** one at a time (a new one replaces the old); cleared at resets; no contact (no string, no KŌSEI, no stitches). 1 bar | two lower hands part an unseen tapestry to the side; the upper pair gestures him forward |
| Shift+L | SP2 **傘 KASA** `:sj-kasa` [A ep. 25] | 4/24/18 (46 f) | 40 + ½ caught | guard (melee) | **The umbrella:** at f4 the six hands spread an umbrella of red thread between them (the ribs are the arms). The window is **f4–27**, the move's own S / A (Ichigo's gap 4: the parry window read from the move).<br>**Melee in the window:** it is **a guard** (the `:shield` flag, gap N9): front 200°, normal blockstun (which ends the umbrella), the gauge drains its guard value; **a Breaker breaks it** (Guard Break) [research].<br>**A hazard or a `:ranged` hit in the window:** **caught**. It is blocked from the front 200° with **no blockstun and no gauge drain** (Ichigo's gap 5 `:parry-block` branch), and it is **recorded** (the `:catch` hook, gap N9): the caught hit's damage, keeping the largest.<br>**At f28, if anything was caught:** she fires the **tendrils** back, a `:wave` from her toward him: 16 m/s over 10 m, width 1.6 (half 0.8, so a side Step clears it), **40 + ½ of the largest caught hit** (cap 120), stagger, guard 14, `:ranged`. Nothing caught: nothing fires, and the 18 f recovery is a punish window.<br>**Unguardable hits** (South's bind, a red dash-in) go through. 1 bar (**2 bars awakened**, the universal SP2 rule) | the six arms open like ribs, the thread canopy snapping taut; then the canopy inverts and the threads lash out |
| I | Breaker **裁断 SAIDAN** `:sj-breaker` [G] | §4 (universal) | 150 | Guard Break | the universal Breaker (aura 12, the dash, strike 8/4/18, reach 2.6). The strike is two upper hands closing like shears on his guard, with a thread snip (`:shears`). Brush Latin (the Breaker rule) | glides low on the clogs, the arms folded back; the shears snap shut |
| O | Kikon module **縫地 NUICHI** `:sj-kikon` [A: "sews a foe to the ground", ep. 26] → Kikon **仕立て直し** | aura 6, **flash step 26 m/s ≤ 14 f** (locked), strike 8/3/24 | 70 | −14 | **Reach:** 1.6 + 6.1 = **7.7 m**, ≤ 28 f from the press.<br>**The strike:** `:sj-spin` reused, **2.4 m 200°**, knockback 2.5; threads shoot from all six hands into the plaza round his feet (a look). **It sews** (+2 / +1). Cooldown 90; TENCHI's flash-step look.<br>**As the O ender** (off J3 at 2.6 m): 1 m of dash (3 f) + S 8 = 11 f < stagger 26 | a vanish, then the whirl of hands |
| U | guard | | | | universal | |
| P | awaken (§6) | | | | EVOLUTION, from idle / walk / guard | |

**Hoho and Burst look** [V ch. 600 fake body; A ep. 26 rag doll]: her Hoho and Burst Reverse leave a **cloth double**
where she stood, which crumples into an empty robe over 12 f. It is **a look only**: the frames, iframes and costs are the
universal ones.

**Canon notes:**
- 悪い癖 is her own line [V ch. 599]; its use as a detonation is ours [G] (Brave Souls' "Bad Habits" special is the
  precedent).
- Tapestries and Divine Soldiers are manga [V]. The umbrella, the sewing to the ground and the rag doll are anime-only [A].
- **Invented names [G]:** HITOHARI, KAESHINUI, SENJU, MACHIBARI, MATSURI, KUKE (real sewing terms: 返し縫い backstitch,
  待ち針 pin, 纏り hem stitch, 絎け blind stitch), SAIDAN, NUICHI.
- The Shikai release command is **unknown** [research gap], so no chant is invented. The intro callout is only
  "SHIGARAMI".

### 3.4 What the base kit plays like

- **0–2.6 m:** J1 at 7 f beats every K1. Every string sews: a hit JJJ is 6 stitches. Then:
  - **L after a K link** is the safe cash-out (in the combo, scaled);
  - **or walk away** and detonate 60 unscaled later (§3.5).
- **3–7 m:** the soldier walks in first. His answer, swatting it with a J, is the gap she closes with NUICHI (7.7 m) or a
  run.
- **Against projectiles:** the umbrella, and its fire-back.
- **Against a turtle:** blocked strings still sew. A blocked KKK leaves 3 stitches, which is 30 unguardable, and his guard
  gauge takes 46.
- **Her weaknesses:** the shortest reach and the lightest hits in the game. **Nothing at range but the soldier and the
  O.** A patient zoner at 7–9 m never lets her sew, and that is the matchup the awakening answers.

### 3.5 A deeper commitment pays more (the user's Rukia rule)

- **A hit sews 2, a block 1.**
- **Detonating outside a combo is unscaled:**
  - 6 × 10 = **60**;
  - after a K link in the combo it is scaled; after JJK, hits 4–9 give 10 × (0.9 + 0.8 + 0.7 + 0.6 + 0.5 + 0.4) = **39**.
  - Waiting risks the 3 s decay and a hit on her (which doesn't remove the stitches but costs time), and pays +21.
- **The soldier's second strike** comes only if it survives 70+ f in front of him.
- **The umbrella's fire-back** grows with what it caught (40 → 120).

---

## 4. The awakened kit: 娑闥迦羅骸刺絡辻 SHATATSU KARAGARA SHIGARAMI NO TSUJI [A, all of it]

The Bankai [A ep. 26]: a torii becomes a golden loom that pours out red bolts, a red carpet runs out as a crossroads (辻),
and cloth walls enclose the space. The loom weaves a patterned bolt for each enemy and unravels **one hank at a time** into
an environment that wears the target down.
- It is **permanent**, like every awakening, with **no heal** (`:heal 0`) (superseded 2026-09-30: every awakening heals 20 % of max Reishi, DUEL_DESIGN.md "Awakening heal").
- Kikon **3** (the universal awakened count), Soul Break 4.
- Damage ×1.0 dealt and taken (`*tsuji-mult*`, `*tsuji-taken*`).
- Walk **3.3**, run **8.0** (`*walk-tsuji*`, `*run-tsuji*`): the loom holds her to her ground.
- HUD: the name line reads "SENJUMARU  TSUJI"; the awakening row reads SHIGARAMI NO TSUJI (Q11's short name). U is a guard
  (no U tag).

Identity: **terrain control at 4–9 m.** She places one visible, ordered zone at a time under him and fights with long
cloth-carrying strings round it. She no longer sews.

### 4.1 The one resource: 機 HATA, the loom (six hank forms and one lock)

The awakened character is **six kit forms**, one per hank, `:tsuji1` … `:tsuji6`. Each inherits `:tsuji1`, which inherits
`:base`. **The form is the hank the loom unravels next.** This is Nozarashi's cups and Rukia's bands again: the form is
data, and the HUD reads it.

| Rule | Value |
|---|---|
| **Queue** | fixed (Q10; `*hank-order*`, the user, 2026-09-30): **黒砂 → 刃金 → 褥 → 焼野原 → 眼 → 星**, then back to 黒砂: three SP1 pairs (§"The hank queue in three SP1 pairs"). Form `:tsujiN`'s next hank is still hank N (the table below keeps the canon numbers); only `hank-next` follows the queue. The awakening enters `:tsuji3` (黒砂). A Kikon / Soul Break reset keeps the form (no `:reset-form`) and clears the live zone (`clear-hazards`, built) |
| **Weave** (L held, the user's split of 2026-09-29) | `:hold (1 600)` with `:release senju-weave-release`: a press held **≥ 10 f** (`*weave-tap*`) is a weave. Its frames count from then (those first 10 at once), **one pass per 20 f**, summed over every segment on the hank (`sjs-woven`, `weave-add`) up to 3 passes. Let go, the weave just stops: `:sj-weave-stop`, 1/0/5 (6 f), nothing unravels, the passes stay. A `:shuttle` clack marks each pass; the bolt between her hands (fragile) shows only while she weaves |
| **Unravel** (L tapped) | a press let go **under 10 f** is the release: S 6, then the hank's zone is cast (§4.2) at the **stored passes** (`release-passes`), the stored passes reset and **the form advances to the next hank at once**. **With no pass stored the tap is refused** (the `:refused` cue, then the 6 f stop; since "J weaves, K releases"), and tapped while a zone lives it is refused the same way: the loom holds one hank (`weave-release-act`) |
| **Scaling by passes** | (since 2026-10-01, `*pass-scale*`) radius ×0.7 / 0.85 / 1.0, life ×0.5 / 0.8 / 1.2 of the hank's listed life, damage ×0.7 / 1.0 / 1.4, **effect ×0.6 / 1.0 / 1.5** (刃金's guard, 黒砂's drag, 褥's freeze and frost, 焼野原's chip, 星's drain, 眼's mirror); until then radius ×0.8 / 0.9 / 1.0, life ×0.5 / 0.75 / 1.0, damage ×0.8 / 0.9 / 1.0 and no effect scale. **More passes are never weaker** (host-tested per hank: radius, life and damage non-decreasing) |
| **Unfold** (the tell) | every zone first **unfolds for 20 f**: a bolt of its dye unrolls onto its shape (`:cloth-unfurl`). It is **fragile** while it unfolds |
| **One live** (gap N8) | a tap is **refused while one of her zones lives** (it only stops, 6 f), but she may weave meanwhile (since 2026-09-29; L was refused outright before): the loom holds one hank. The HUD's live swatch shows its life draining. A zone whose one-shot effect is spent ends then, and the loom is free again |
| **Void / torn** (the forced exit) | a real hit on her **while she weaves** (a counter-hit, a Guard Break or a Kikon strike included) **voids** the hank (the user, 2026-09-29): its stored passes are lost and **the form advances** to the next hank, no lock (`weave-void`). A hit while she is not weaving keeps the stored passes. A hit **during the unfold** tears the zone: **L is locked 90 f** (the hook sets L's cooldown timer; L's own `:cooldown` stays 0, so no COOLDOWN row is drawn). The weave's bolt and the unfolding zone are fragile hazards whose `:on-close` hook (gap N7) calls `senju-torn`. A BLOOD slash crosses the swatch |
| **Voluntary** (the cheap exit) | weave in short segments (each only 10–30 f of exposure), or one pass at a time with **J → L** (`:l-after-j :sj-hitokoshi`, below), and tap when it fits |
| **J → L 一越 HITOKOSHI** (the quick weave) | L after a J link (J1 / J2 / J2s / J3), latched like K → L: 8/0/10, **+1 pass** on the form's hank at f8 (`quick-weave`, at most 3), **never a release**. No bolt, so no void: a hit before f8 only loses that pass. From a J1 / J2 hit −3, from J3 +5; blocked −17 / −19 (punishable) |
| **SP1: two hanks** | §4.4: 1 bar releases the next two hanks at once (the combo cut's rules), the queue +2 (the skip until 2026-09-29) |
| **The combo cut** (the overdraft rule, the user's Rukia band-lock precedent) | **L after a K link** (`:l-after-k`: the hank's combo copy, no hold, **the stored passes; refused with none stored** (since "J weaves, K releases"; the cue flashes), S 8, **unfold 10**) **ignores the one-live refusal**: inside a combo the live zone is **cut** (it ends) and the next hank unravels under the staggered victim. From a K link's hit: A 4 + 8 + 10 = 22 < stagger 26, so the hanks that hit (刃金, 黒砂, 褥, 焼野原) **combo**. The combo copies strike at the unfold's end: 刃金 closes without its 16 f rise, and 黒砂's first gulp comes without its 12 f swirl. It rides on `kit-command-ok-p`'s built `combo` argument (Rukia's overdraft) |

### 4.2 The six hanks (死出六色浮文機 [A]; each cast by L under him at `cast-point` ≤ **9 m**, except 5 and 6)

Common rules for every zone:
- the 20 f unfold (the tell, fragile);
- **`:src t`**: a guard facing her blocks their hits;
- a hazard's guard value (12) unless stated, and the fixed 14 f hazard blockstun;
- **no KŌSEI**, no contact;
- **cleared at every reset**;
- one live;
- **every disc's full radius is ≤ 2.0 m**, so r + Kenpachi's hurt r 0.45 < the 2.5 m Step, and one Step from the centre
  always gets out.

The values below are the hanks' listed values: the first build's 3 passes, since 2026-10-01 the 2-pass values (3 passes
is ×1.4 damage, ×1.5 effect, ×1.2 life).

| # | Hank [A name and chant] | Shape, where | Life | Effect | Hazard (gap) |
|---|---|---|---|---|---|
| 1 | **一綛解かば 万朶の眼 BANRA NO ME**, the eyes | a ring of eight standing mirror-eyes, **r 3.0**, h 2.5, under him | 240 f | **Reflect:** every opponent `:wave` / `:fireball` that is inside the ring or enters it is **turned back**: its owner becomes Senjumaru and its yaw is reversed (Ichigo's `:cuts` with a `:reflect` mode, gap N6). Canon: "the mirrors reflect the victim's own attacks back onto him."<br>**Mirror:** while **he** stands inside, each of his melee contacts on her (hit or block) deals **30 %** of that hit's damage back to him: unguardable, never kills (`:mirror 0.3`, gap N5), with an eye-flash on the nearest mirror.<br>No hit of its own | `:zone` (N5) + `:cuts :reflect` (Ichigo 9 + N6) |
| 2 | **二綛解かば 刃金のよろい HAGANE NO YOROI**, the iron maiden | a disc **r 2.0** under him; after the unfold, spiked gold sheets cut in her likeness rise round its edge for **16 f** | until it closes, + 20 f | **It closes once** at 16 f after the unfold: **90**, crumple, **guard 24** (twice a hazard's: "nothing to stand dressed in", so guarding inside costs double). Then the life ends | `:freeze`-kind disc (built: no blade cuts it), `:react :crumple`, `:guard 24` |
| 3 | **三綛解かば 黒砂の腸 KOKUSA NO HARAWATA**, the black-sand pit | a pit **r 2.0** under him, a black spiral | 240 f | **Drag:** while his centre is inside, the away part of his walk / run (from the pit's centre) is ×**0.4** (`field-velocity` about the pit's centre, Rukia's built rule; `:step 1.0`: **Steps are never shortened**).<br>**Gulps:** from the unfold's end, every **60 f**, 1 / 2 / 3 times by passes: the sand swirls for 12 f (the tell), then a disc hit r 2.0, **40**, stagger, **pulled to the centre** (Ichigo's `:pull 0.0`, gap 6, toward the hazard's own position) | `:zone` with `:field` (N5) + a `:think` for the gulps (N4) |
| 4 | **四綛解かば 凍てつく褥 ITETSUKU SHITONE**, the freezing bed | a snowflake bed **r 2.0** under him | 240 f, or until it freezes | **A mine:** armed from the unfold's end for its whole life; the first time he touches it: **70**, **frozen 40 f** (the `:bind` reaction: it opens a combo and books 2 hits, so Burst is legal), **frost 60** (Rukia's frost status, built). Then it is spent and the life ends | `:freeze`-kind disc (built) with `:life` |
| 5 | **五綛解かば 焼野原 YAKENOHARA**, the burning field | a **corridor**: a lane from 1 m in front of her toward him, length = the distance to him + 1.5 m (≤ 10 m), **width 2.0** (half 1.0: 1.0 + 0.45 < 2.5, so a side Step clears it); two processions of burning madder cloths with ink trees line it | 150 f | Up to **2 hits, 16 f apart** (the pillars' rehit): **45** each, stagger, **fire chip 12 %**, guard 12. A lane from her feet: anti-approach | a stationary `:wave` (speed 0, as Ichigo's residue), `:hits 2` |
| 6 | **六綛解かば 闇夜の星よ YAMIYO NO HOSHIYO**, the star of the dark night | a dome **r 3.5** centred **on her** (where she stood at the release) | 240 f | **Drain:** while he is inside, his **Reiatsu −30/s and flash-step −15/s** (`:drain`, gap N5), **and it siphons** (the user, 2026-09-29): what the drain
really takes goes to her (each gauge capped at its max), and inside it he gains nothing from any hit, block, parry or
his own blade (Reiatsu, flash-step, Fighting Spirit, a kit meter); his Reiatsu / flash-step gains go to her. Canon: it "drains the target's energy" through a copy of Auswählen.<br>What the drain does: it denies his Hoho and his Burst, so the cycle's last hank sets up her O ender and her Kikon ("to be caught in the end").<br>No hit | `:zone` with `:drain` (N5) |

**Where each hank points** (so the fixed order still reads as a plan):
1. Under him, against his shooting.
2. Under him, a punish.
3. Under him, holds him.
4. Under him, a mine.
5. From her toward him, a wall against his approach.
6. Round her, against a rusher.

The chants [A] are the zones' brush columns. Canon ties each cloth to one Sternritter; that is not used.

### 4.3 The awakened J / K (the base grid as it is, **no sewing**; two new links)

The grid was first derived at reach ×1.15 (`:reach-mult 1.15`, "the arms carry strips of cloth"); no cloth was ever drawn
on the hands, so the playtest (below) dropped the derivation: the awakened J1 / J2 / J3 / K2 are the Shikai's. The kit has
no `:sew` and no count meter. Two links are new (the Rukia decision: "a small number of new moves"):

| Link | Name | Clip | S/A/R (enter → S_eff) | Dmg | React | Blk | Whiff | Volume | Guard | Pose |
|---|---|---|---|---|---|---|---|---|---|---|
| J1 / J2 / J3 / K2 | as §3.2 | base clips | as §3.2 | 25 / 25 / 32 / 40 | as §3.2 | as §3.2 | | **1.44 / 1.44 / 1.44 / 2.5 m** (2.4 / 2.4 / 2.4 / 2.8 before the J cut; 2.76 / 2.76 / 2.99 / 3.22 before the first playtest) | as §3.2 | the needle; K2's loop of thread |
| K1 | 反物打ち TANMONO-UCHI `:sj-t-k1` [G] | **new** `:sj-tanmono` | 17/4/20 | 45 (56) | stagger | −3 | 32 | **line 0.3 → 3.8** (was 4.2) | 14 | a bolt of cloth flung straight out from two hands and snapped back |
| K3 | 巻き取り MAKITORI `:sj-t-k3` (ender) [G] | **new** `:sj-makitori` | 21/5/34 (7 → 14) | 58 (72) | crumple | −20 | 46 | **2.5 m** 160° (was 2.8) | 18 | cloth wraps him from the feet up, then the hands haul it in: **pulled to 1.4 m** (Ichigo's `:pull`, gap 6) |

- **Budget:** unchanged from §3.2 (host-tested on `:tsuji1`; the other five forms inherit it).
- **Routes on hit:** JJJ 92, JJK 128, JKK 150, KKK 178, KKJ 142, KJJ 120 (base 92 / 130 / 152 / 184 / 146 / 124, **plus
  60 of stitches** there). The awakened strings deal about 3 % less and leave nothing behind; K1 reaches farther (the bolt).
- **Blocked:** JJJ 24, KKK 46.

### 4.4 The rest of the awakened buttons

| Input | Move | S / A / R | Dmg | Block | Notes | Pose |
|---|---|---|---|---|---|---|
| L | **綛解かば KASE TOKABA** (the hank of the form) `:sj-kase-1` … `-6` [A: "一綛解かば…"] | held ≥ 10 f: the weave (any length, then 1/0/5 to stop); tapped < 10 f: 6/0/22 (the release at f6), **refused with no pass stored** | §4.2 | §4.2 | §4.1: weave, release, one live, void, torn. `:flags (:bind)` and `:params (:tell (…))` counted from the release, so a CPU victim's tell reflex reads it (Rukia's generic `:tell`). **After a K link:** `:sj-kase-N-k`, no hold, S 8, unfold 10 (the combo cut), refused with no pass stored. **After a J link:** 一越 HITOKOSHI `:sj-hitokoshi`, 8/0/10, +1 pass at f8, no release (§4.1) | held: the six hands weave in a ripple, the bolt growing a fold per pass; released: the upper pair flings it out and it unrolls where it lands |
| Shift+K | SP1 **裁ち直し TACHINAOSHI** `:sj-tachinaoshi-1` … `-6` [G; A: she "cuts the pieces off the loom"] | 8/0/22 (releases at f8 and f14) | the two hanks' | the zones' | **Releases the next two hanks at once** (the user, 2026-09-29; it skipped the next hank before): f0 cuts the live zone(s) as the combo cut does, f8 and f14 each unravel the form's next hank under him with the combo cut's rules (unfold 10, both at the passes stored when SP1 began, **at least 1: the one release that needs nothing woven**; the coordinator's default: §"L: hold to weave"), the second beside the first (both live; neither cuts the other), and the form advances past both (+2 in the queue, wrapping). 1 bar. A string ender through the universal SP cancel: off a landed link (a stagger, 26 f) the first zone strikes at +19 and the second at +25. `:flags (:bind)`, `:tell` = its first hitting hank's (10–22, or 16–28 when only the second hits (星 + 黒砂); none for 眼 + 星) | two upper hands close shears in the air (`:sj-snip`), then the upper pair flings a bolt out twice (`:sj-unravel`); each hank's name is called out |
| Shift+L | SP2 **傘 KASA** (as §3.3) | 4/24/18 | 40 + ½ caught | | 2 bars (the universal awakened SP2 cost) | |
| I | Breaker **裁断 SAIDAN** (as written, not derived) | §4 | 150 | Guard Break | a derived strike must out-reach its 2.2 m trigger (Kenpachi's §10 B2 lesson); it is written, so it isn't derived | |
| O | Kikon module **浮文機 UKIMON NO HATA** `:sj-t-kikon` → Kikon **死出六色浮文機** | aura 8, no dash, strike 20/3/30, locked | 70 | −14 | **The lane:** ENJO's module shape; the **red carpet** rolls out along a locked lane `:cap 0.5 → 8.5 h 1.2 r 1.2` and a bolt of the next hank's dye wraps whatever it reaches; knockback 2; cooldown 90.<br>**The follow-up:** a straight glide along the carpet (`:follow-speed 14`).<br>**As the O ender:** S 20 < J3's stagger 26. Clip: `:sj-unravel` reused | both upper hands sweep down and out; the carpet runs from her clogs |
| U | guard | | | | universal | |

### 4.5 Fairness rules (every placed thing)

- **Tells:** every zone unfolds for 20 f. The weave before it is 26–66 f of visible hold (the bolt, the threads to the
  loom, the `:shuttle` clacks). 刃金's sheets rise for 16 f more; each 黒砂 gulp swirls for 12 f; the soldier's spear
  is drawn back for 18 f.
- **Bounded lives:** zones ≤ 240 f, the soldier 300 f, stitches ≤ 5.5 s after the last one.
- **Bounded counts:** one live zone, one soldier, at most 6 stitches.
- **A Step beats every one of them:**
  - the discs by radius (≤ 2.0);
  - the corridor by half-width (1.0);
  - the tendrils by half-width (0.8);
  - the ring and the dome carry no hit;
  - the needles are dodged by iframes.
- **Reward:** zones, the soldier and the tendrils pay no KŌSEI. Every guard value is 12–24, so there is no crush from
  range. 刃金's 24 is the one doubled hit, and it is a punish for standing inside a visible maiden.
- **Resets:** `clear-hazards` at every reset (built), so there is no setplay from before a reset. The stitches reset to 0.

### 4.6 A deeper commitment pays more

- **Three passes** (60 f of hold, the torn risk the whole time) against one pass (20 f): +25 % radius, double the life
  (and so the gulp count), +25 % damage.
- **The combo cut** turns a K hit into a guaranteed zone hit, but with the combo scaling.
- **The awakening itself** (giving up the stitches for good) earns the 3-Konpaku Kikon.

Nothing the form pays for is weaker than a cheaper version of itself (host-tested).

### 4.7 The combo scaling and the zones (a note)

A zone hit that lands in a combo is scaled like any hit. A zone hit on a free opponent starts a new combo; 褥's freeze
and the gulps book as combo hits, so Burst is legal after the second. After 褥's 40 f freeze she is at cast range
(≤ 9 m), so only her O lane (S 20, 8.5 m) converts it. That is the intended conversion, as Rukia's ring → SHIRAFUNE.

### 4.8 Removed base tools (sidegrade rule 2, named)

- **刺絡の針 the stitches and 悪い癖 WARUI KUSE:** no sewing and no unguardable detonation.
- **神兵 SHINPEI:** SP1 becomes the skip.
- **縫地 NUICHI:** the 7.7 m flash-step rush becomes the dashless lane.
- **Speed:** walk 3.6 → 3.3, run 8.5 → 8.0.

Gained:
- the loom: six hanks in a public order;
- the weave and its scaling;
- the combo cut;
- the skip;
- cloth reach (×1.15, K1 4.2 m, the MAKITORI pull);
- the 3-Konpaku 死出六色浮文機.

Kept: 傘 (at 2 bars), SAIDAN, the guard.

### 4.9 Why it is a sidegrade

| Matchup | Base is better | Awakened is better |
|---|---|---|
| **vs Kenpachi** (every form: rush, stance, DRINK, no projectiles) | **every absorbed or drunk hit sews** (+1), and the needles are unguardable **through the stance and DRINK**; her J1 7 f beats his K; the soldier walks into his swing (it costs him a swing) | 焼野原's corridor and 黒砂's drag slow his approach; 星 drains the flash-step his Hoho needs. **But** a 10 m/s runner tears 20–60 f weaves, and 眼 is dead weight (a skip costs a bar). **Expected: base** |
| **vs Yamamoto** (7–9.5 m, fire waves, Shiranui, South; Bankai West's ward) | the needles pass West's ward (unguardable); the umbrella eats his fire and throws it back | **眼 under him turns his waves and Shiranui back at him**; zones cast 9 m out reach his zone; the corridor walls his Bankai East's rush; she never has to reach him. **Expected: awakened** |
| **vs Rukia** | base Rukia (a mobile zoner at 5–8 m): the umbrella catches HAKUREN and the ring's pillar | **zero Rukia is rooted and her ward is optic: every zone is a hazard and goes through; she can't Step out of 刃金 or 褥**; −50 Rukia's slow walk suffers 黒砂's drag. **Expected: awakened (against her awakened forms)** |
| **vs Ichigo** | base Ichigo holds a guard: blocked strings sew both ways, and her J pressure beats his hold-guard read | **Kessa has no hold-guard**: a zone hit in his parry window drains his chain gauge (the forced crush, his rule 4); his clone and crescent are hazards her umbrella catches. His wall and JŪJISHŌ `:cuts` cut her corridor (a `:wave`), but not the discs or zones. **Expected: base vs base Ichigo, awakened vs Kessa** |
| **mirror** | a base Senjumaru's soldier and 7.7 m rush reach an awakened one mid-weave (torn) | an awakened one's 眼 reflects the tendrils, and its zones out-range a base one's reach |

---

## 5. The Kikon cinematics (60 Hz, review-3 pacing; unskippable)

Every shot is framed with `shot-on` on its subject, so `%keep-subject` keeps the subject in frame at 0.55 of the half-width
in landscape and 0.3 in portrait (`*cine-subject*`). Senjumaru wears white, so she goes on the **black card** (Yamamoto's
rule), with a white back-rim. The domain cinematics stay off BLOOD: madder cloth, gold loom, BLOOD only in the thread
lines and the Konpaku flames.

### 5.1 Base: `sj-kikon-cine` **仕立て直し SHITATE-NAOSHI** (186 f; Kikon 2, Soul Break 3) [V ch. 598–599: the Nianzol kill]

| Shot | Frames | What |
|---|---|---|
| beat 0 | 0–12 (12) | the NUICHI strike held, threads pinning his feet to the plaza; a negative 2 f; `:thread-zip` |
| caption card | 12–70 (58) | **black card**, white back-rim; Senjumaru a white silhouette, the six gold arms fanned into a halo round the crescent; brush **仕立て直し** (reading SHITATE-NAOSHI, sub WARUI KUSE  KIKON), the red 鬼 hanko; silence. `shot-on a` |
| the tailoring | 70–100 (30) | medium on the victim (`shot-on v`): six hands blur round him (the echo arms at a 2 f lag and afterimages), red threads zig-zag over his torso, and his robe turns **white with a black Royal Guard mark on the back** (a torso tint on his body) [V: "the Royal Guard insignia appears on his coat"]; `:thread-zip` ×3 |
| the knot | 100–128 (28) | low and close on her (`shot-on a`, lens 70): she draws the thread to her lips and bites it off; a small courtly bow; the calm face (`:calm`) |
| held push-in | 128–150 (22) | on the victim: the garment tightens; poses held, effects frozen; silence |
| the bad habit | 150–170 (20) | a negative, then a 12 f manga page (white; the BLOOD soul flame the only colour): dozens of needles burst outward from inside the garment in a fan (`vfx-needle-burst`); the Konpaku shatter; `:needle-burst` + `:konpaku-shatter`, a shake |
| aftermath | 170–186 (16) | wide from behind her (`shot-on a`): she threads the needle again; the empty robe settles |

### 5.2 Awakened: `sj-hata-cine` **死出六色浮文機 SHIDE NO ROKUSHIKI UKIMON NO HATA** (198 f; Kikon 3, Soul Break 4) [A ep. 26]

| Shot | Frames | What |
|---|---|---|
| beat 0 | 0–12 (12) | the carpet lane held; a negative 2 f; `:cloth-unfurl` |
| the wrap | 12–40 (28) | on the victim (`shot-on v`): the red carpet lifts off the plaza, and a bolt in **the next hank's dye and pattern** (one texture parameter, six looks) wraps him from the clogs to the neck (the victim plays `:sh-bound`) |
| caption card | 40–98 (58) | **black card**, white back-rim; her silhouette before the golden loom; brush **卍解 / 死出六色浮文機** (reading BANKAI, sub SHIDE NO ROKUSHIKI UKIMON NO HATA  KIKON), the red hanko. `shot-on a` |
| the loom | 98–126 (28) | low and wide from behind her (`shot-on a`): the torii-loom overhead, her six arms raised to it "as if praying" [A]; threads run from the loom to the wrapped victim, taut |
| the cut | 126–150 (24) | `shot-pair`: two upper hands close great shears of gold on the threads; the bolt is **cut off the loom with him inside** [A]; `:shears` |
| sealed | 150–172 (22) | a manga page 12 f: the bolt rolls up and rises to hang among patterned bolts in the dark; the Konpaku flames drift out through the cloth and shatter; `:konpaku-shatter` |
| aftermath | 172–198 (26) | on her (`shot-on a`): the arms lowered; the hanging bolt sways; her calm face |

Both are `defcine` scripts with the built primitives (`card`, `back-rim`, `caption`, `impact-frame`, `lens`, `silence`,
`hold-both`, `shot-on`, `shot-pair`, `cine-clip`, `face-beat`). The new looks are:
- the garment tint;
- the needle burst;
- the wrap bolt;
- the loom prop;
- the shears (§10).

In portrait the close-ups follow DUEL_MOBILE_DESIGN §15.3 (a close-up keeps its lens).

---

## 6. The awakening: condition and entry cinematic

**Condition:** the universal EVOLUTION, P from idle / walk / guard, once per match, **no heal** (superseded 2026-09-30: every awakening heals 20 % of max Reishi, DUEL_DESIGN.md "Awakening heal").
- The stitches go to 0; the guard gauge, Reiatsu and flash-step are kept.
- She enters `:tsuji3` (黒砂 next, the queue's first hank), with no zone live.
- The CPU's timing is a rule (§7.1).

**`sj-tsuji-cine` 娑闥迦羅骸刺絡辻 (180 f; unskippable)**

| Shot | Frames | What | Canon |
|---|---|---|---|
| beat 0 | 0–12 (12) | her arms lowered, the needle down; a negative 2 f; silence | — |
| three candles | 12–46 (34) | close and low on her (`shot-on a`, lens 70): three candle flames float before her and go out one by one (f20, f30, f40); the plaza darkens after each; `:candle-out` ×3 | **the Blood Oath, hinted** (Q11; the three Divine Generals' deaths are not shown) [A] |
| the gate | 46–80 (34) | low and wide from behind (`shot-on a`): a **golden torii rises** from the plaza behind the opponent's line; she raises her six arms toward it as if praying; `:awaken-rise` at 0.7 pitch | [A] |
| the loom | 80–106 (26) | medium (`shot-on a`): the torii shimmers into a **golden loom** and pours out red bolts; a **red carpet rolls from her clogs** across the plaza (the crossroads 辻); madder cloth walls drop over the plaza's broken rim; `:cloth-unfurl`, `:awaken-boom` | [A] |
| caption card | 106–162 (56) | **black card**, white back-rim; her silhouette with the loom behind; brush **卍解 / 娑闥迦羅骸刺絡辻** (reading BANKAI, sub SHATATSU KARAGARA SHIGARAMI NO TSUJI; the eight-kanji name in its own column), no hanko (not a Kikon) | name [A] |
| wide | 162–180 (18) | back in the plaza (`shot-on a`): the dark red domain, the loom at the rim, her aura's drifting strips; the opponent small | — |

**Not used:**
- **The three suicides:** hinted only (Q11).
- **"Its power shakes the Three Worlds":** a shake would read as damage.
- **The Hollow cloths** [A ep. 27]: §12, dropped ideas.

---

## 7. AI profiles (`:ai` per form; generic code in ai.lisp)

### 7.1 When to awaken (a real choice)

The rule reuses the damage-source counters (`gauges-taken-melee` / `-ranged`, built for Rukia) through Ichigo's generic
key:
`:awaken (:ranged-share 0.3 :min-taken 150 :or-opp-rooted t)`. On EVOLUTION she awakens once she has taken ≥ 150 **and
either ≥ 30 % of it came from ranged hits** (hazards and `:ranged` windows), **or the opponent is in a `:rooted` form**
(zero Rukia: one line beside Ichigo's key, gap N10). **Superseded 2026-09-30** (the user: "increase every CPU's chance to
open its Bankai"; this rule left her awakened in 27 % of the gate's CPU matches): she now uses Ichigo's generic
`:awaken (:min-taken 150)`; the `:awaken-rule` key, `senju-awaken-p` and debug 99100+k are gone (99200+k now sets
`:awaken`'s `:min-taken`). The gate after it: awakened in 120 / 120.
- **vs Kenpachi** (nearly all melee) she stays base, which §4.9 predicts is right.
- **vs Yamamoto, vs Kessa, vs base Rukia's rings and waves:** she awakens once the zoning has landed.
- **vs zero Rukia:** at once.

The share keeps updating (rule 5: the choice is made mid-match, with information). The debug A/B mode 39000 + 10a + b (0
the rule, 1 always, 2 never) is generic and already built.

### 7.2 Tables

| Form | Intents (A / P / Z / D) | Ranges | Bands (lo hi weights) | Other keys |
|---|---|---|---|---|
| **base** | 2 / 4 / 0 / 1 | **P 1.3–2.4**, A 2.4–5.0, D 3.0–5.0 | 0–2.6 `:q 6 :f 2 :breaker 1 :sig 1`; 2.6–6 `:sp1 2 :kikon 1 :step 1 nil 1`; 6–99 `:sp1 2 :kikon 2 nil 1` | guard 0.4, hoho 0.3, **dash 0.7**, dash-back 0.1, **block-string 0.8** (blocked strings sew), o-ender 0.3, **`:l-after-k 0.3`** (the scaled cash-out), **`:hari (:min 4 :hurry 40)`** (gap N10: L only with ≥ 4 stitches, **and always** with ≥ 2 when the first would fall within 40 f), `:react (:projectile :sp2)` (the umbrella timed to a projectile's contact, Ichigo's gap 11), sp-cancel-bars 1, kikon-range 7.7, `:awaken` §7.1 |
| **tsuji1–6** | 1 / 1 / **4** / 2 | **Z 5.0–8.0**, D 4.0–6.0, P 1.4–2.6 | 0–2.8 `:q 3 :f 2 :breaker 1 :step 2`; 2.8–5 `:f 2 :sig 2 :step 2 nil 1`; 5–9 `:sig 5 :kikon 1 nil 1`; 9–99 `:sig 2 nil 2` | guard 0.45, hoho 0.35, dash 0.2, **dash-back 0.6** (keep 5–8 m), o-ender 0.2, `:l-after-k 0.3`, **`:weave (:far 6.5 :near 4.0)`** (gap N10: hold L 3 passes beyond 6.5 m, 2 at 4–6.5, 1 inside 4 m when nothing is stored: never a refused tap), **`:l-after-j 0.35`** (J → L, the quick weave), `:react (:projectile :sp2)`, kikon-range 8.5, **`:opp-rush-hold 0.5`** (read by the *opponent's* CPU, below) |
| **tsuji1–6** | | | | **`:sp-ender senju-sp-ender`** (the generic key: a kit's own SP ender for a landed string's last link, ai.lisp `string-reflex`): SP1 at `*ai-senju-tachi*` 0.5 when one of the two hanks it releases hits (the old `:tsuji1` `:skip (:ranged-below 0.2)` is gone with the skip) |
| `:tsuji6` (星) only | | | | `:weave (:far 5.0 :near 2.5)`: the dome is cast round her, so she weaves it as he comes in |

- **The umbrella's `:react`** uses Ichigo's generic projectile time-to-contact (gap 11): she presses SP2 so that the
  projectile arrives inside f4–27.
- **Opponents facing her need one key, read off her kit:** `:opp-rush-hold 0.5` (gap N10). A CPU whose opponent is
  **holding a `:hold` move** (the weave) within 9 m rolls once per hold at 0.5 to **dash in, or rush with O** within its
  kikon-range, so it tears the weave. The key lives in her awakened kits and is read only when facing her, so every other
  pairing's CPU behaviour (and hash) is unchanged. It is the anti-turtle idea of the Bankai rework (`snap-take!`) applied to
  the loom.
- **The zone tells** for a CPU victim: the South-tell reflex reads a `:bind` move's `:params :tell` (Rukia's generic).
  For the hank moves the tell frames are counted **from the release** (the move frame after the hold, `fighter-sf` past
  the hold), one small fix in the reflex (gap N10).
- **The soldier** needs no key on either side. It walks into the opponent's frontal arc, so the opponent's ordinary
  attacks at her hit it, and its 18 f tell is a hazard threat the built reflexes guard or Hoho.

---

## 8. HUD and the one-hand controls

**Landscape** (the kit-meter row, where NOME / UDE / COLD live). There is **one row, one resource**. L has no cooldown in
either form, so `hud-cooldowns` draws no COOLDOWN row for her and nothing can overlap (the Rukia playtest rule).

**Base: 針 HARI.** Six small **needle pips** in the row (gold needles, `%hud-needles`, gap N11; UDE's `%hud-arm` pip
layout re-skinned):
- a set stitch lights its needle's eye with a BLOOD thread;
- the next to fall flickers in its last 30 f (UDE's crack flicker);
- a refused L flashes the row (`*refused-t*`);
- the label is the brush 針 + `HARI`.

**Awakened: 機 HATA.** **Six cloth swatches** in queue order, in three pairs with a wider gap between pairs (`%hud-loom`, gap N11), each in its hank's dye and pattern:
- **SP1's two hanks are framed:** one gold frame round a designed pair, a grey frame round each swatch of a cross pair;
  bright with a bar for SP1, dim without;
- **the next hank is lit and raised**;
- **the passes stored on it fill it in three steps** (every segment, so it reads between them; the same swatch in the
  portrait slot);
- the **live zone's** swatch (the one before) carries a thin line draining over its life, and pulses;
- **torn:** a BLOOD slash across the swatch, then a grey 90 f drain (the lock);
- both of SP1's live zones drain on their swatches (the skip's slide went with the skip);
- **a refused release** (a tap or K → L with nothing woven, a tap over a live zone) washes the next hank's swatch white and
  outlines the row for 0.25 s (`*refused-t*`), in both layouts;
- the label is the brush 機 + the next hank's short name (`ME`, `HAGANE`, `KOKUSA`, `SHITONE`, `YAKENOHARA`, `HOSHI`);
- the name line reads "SENJUMARU  TSUJI"; the awakening row reads SHIGARAMI NO TSUJI.

**Portrait** (`hud-side-portrait`). The last row's small gauges **span the Reishi bar's width** (the user's portrait rule).
The kit slot there holds the six needle pips or the six swatches at small size, keeping the lit / flicker / slash states.
`portrait-label` is `HARI n` or the next hank's short name.

**One hand** (DUEL_MOBILE_DESIGN §15.1; gestures unchanged: tap J, upper tap K, flicks, **rest = guard**, rest → up-flick
Hoho, the chips L / I / SP1 / SP2 / O / AWK):
- **Base:** the L chip is WARUI KUSE; the SP1 chip is the soldier; the SP2 chip is the umbrella. The thumb ring shows **six
  needle ticks** round it, lit by the count.
- **Awakened:** the **L chip held is the weave** (`touch-chip-down-p`: the chip's down state is the hold, as Rukia's SP1
  hold), and releasing it unravels. While it is held the ring shows three pass ticks filling and takes the next hank's dye
  as its tint. The SP1 chip is the skip. A refused L (any character's: cooling, cold, its kit's refusal) flashes the L
  chip white for 0.25 s.
- **A resting thumb is a guard in both forms** (U is a guard), with no side effect: nothing of hers accrues from guarding.

---

## 9. Balance plan

**Gate today** (debug 2113, 20 seeds, NORMAL, cinematics included; the window is medians of 125–210 s, every match by
K.O.). The latest in DUEL_DESIGN §7:

| Pairing | Median | Wins |
|---|---|---|
| YY | 134.7 s | — |
| YK | 136.2 s | Yamamoto 12 / 20 |
| KK | 131.2 s | — |
| RY | 135.6 s | Rukia 11 |
| RK | 148.1 s | Rukia 13 |
| RR | 183.1 s | P1 8 |
| IY / IK / IR / II | — | Ichigo's gate, on his branch |

**Expected effect:**
- **Every existing pairing is byte-identical** (six, or ten once Ichigo is merged). Every change is behind a Senjumaru kit
  key, a hazard kind or flag only she spawns (`:zone`, `:think`, `:frail`, `:stick`, `:on-close`, `:reflect`, `:mirror`,
  `:drain`, `:spare`), or a kit key read off her kit (`:opp-rush-hold`).
  - The generalized `cut-hazards` touches only `:frail` hazards, and no other character has one.
  - The tell-reflex fix changes frames only for a move with a `:hold`, and no `:bind` move with a hold exists today.
  - No new random draw is made for Y / K / R / I, and the style gates' cvc refs (`tests/style-cvc-ref.txt`) must match.
- **The gate grows by five pairings** (SY, SK, SR, SI, SS): 15 pairings, 300 matches. **SI needs Ichigo merged**; if
  Senjumaru is built first, SI waits. Predictions:

| Pairing | Median guess | Why | Risk |
|---|---|---|---|
| **SY** | 140–175 s | base can't reach his 7–9.5 m zone; after the rule fires, 眼 and the 9 m casts contest it | two zoners staring past 210 s: heat (×2 beyond 6 m) and `:opp-rush-hold` pull them in |
| **SK** | 125–150 s | he closes fast; base sews his stance; the fight is short-range | **< 125 s** (KK already sits near the floor); knobs below |
| **SR** | 150–190 s | base Senjumaru vs rings; awakened vs a rooted zero | **> 210 s** if base Senjumaru and base Rukia trade at range |
| **SI** | 130–165 s | stitches vs his hold-guard; zones vs Kessa's parry | — |
| **SS** | 150–190 s | soldier / umbrella / zones in both directions | the high edge |

- **Win targets:** each new pairing within 10 ± 3 of 20.
- **Pacing warning from Rukia:** the lightest J in the game pushed her matches out of the band until her kit multiplier
  moved (Shikai ×1.5 / 0.8 as built). Senjumaru's strings are lighter still, and the stitches are the planned
  compensation. If the medians run long, `*senju-mult*` is the first knob, not the strings' frames.

**The awaken A/B** (seeds 1–60, NORMAL; P1 Senjumaru in mode 1 "always on EVOLUTION" vs mode 2 "never" vs mode 0 "the
rule"; the opponent on its own rule; SS: P2 on the rule):
- **Pass:** |always − never| ≤ **9 of 60** in every pairing (the Kenpachi / Rukia / Ichigo criterion), **and at least one
  pairing has never > always**, expected to be **SK**.
- **Logged, not gated:** mode 0 should be at least as good as the better of the two in SY and SK.
- **The Kikon count is counted in.** "Always" gets the universal 3-Konpaku Kikon, which biases it by construction. The
  offsets are the lost stitches (no free unguardable 60 after each landed string), the weave's torn risk and the slower
  walk.
- **If always wins everywhere (the awakening is an upgrade),** in order:
  1. `*tsuji-mult*` 1.0 → 0.9;
  2. the torn lock 90 → 120 f;
  3. the unfold 20 → 24 f;
  4. zone lives ×0.8;
  5. the skip 1 → 2 bars;
  6. 眼's mirror 0.3 → 0.2.
- **If never wins everywhere (the awakening is a trap),** in order:
  1. `*tsuji-taken*` 1.0 → 0.9;
  2. the skip 1 → 0 bars;
  3. the torn lock 90 → 60 f;
  4. the pass time 20 → 16 f;
  5. walk 3.3 → 3.5;
  6. the cast range 9 → 10 m.

**Pacing log** (a `duel senju` line per side, debug only):
- when she awakened, and the ranged share at EVOLUTION by opponent form;
- stitches sewn (by hit / block), fallen, and detonated in and out of a combo, and the damage of each;
- soldiers: summoned / killed / strikes landed or blocked;
- umbrella catches and fire-back hits;
- weaves by passes, torn weaves (and by what), skips;
- zones by hank: unravelled, hits, blocks, Step-outs; 眼 reflections and mirror damage; 星 drain totals;
- combo cuts.

**Knobs, in order:**
- **Medians under 125 s (SK most likely):**
  1. `:block-string` 0.8 → 0.6;
  2. `:sew :block` 1 → 0 on J links;
  3. the spike damage 10 → 8;
  4. the soldier's strikes 2 → 1.
- **Medians over 210 s (SY / SR / SS):**
  1. the awakened zone weight 4 → 3;
  2. `:dash` (base) 0.7 → 0.9;
  3. `:opp-rush-hold` 0.5 → 0.7;
  4. zone lives ×0.8.
- **Senjumaru wins too much:** the spike damage 10 → 9, 刃金 90 → 80, the stitch decay 180 → 150 f.
- **Senjumaru wins too little:** `*senju-mult*` 1.0 → 1.2, J1 28 → 30, the soldier's life 300 → 360, the umbrella's base 40
  → 60.

---

## 10. Build list

**New files** (MANIFEST: `lisp/senju-art.lisp` after the last `*-art.lisp`; `lisp/senju.lisp` after the last kit file):
- **`senju.lisp`** (~520 lines):
  - **Moves:**
    - base: 6 grid + 2 copies, WARUI KUSE + its `-k` copy, SHINPEI, KASA, SAIDAN, NUICHI;
    - awakened: TANMONO-UCHI, MAKITORI, KASE TOKABA × 6 + 6 `-k` copies (`defmove-copy` with overrides),
      TACHINAOSHI, UKIMON NO HATA.
  - **Kits:** `:base`, `:tsuji1` … `:tsuji6` (2–6 are three-line `:inherit :tsuji1` forms with their own `:sig`, `:sig`
    copy and `:ai` override).
  - **Hooks:**
    - `senju-warui-kuse` (the stuck spikes);
    - `senju-soldier` + `senju-soldier-think` (walk, tell, thrust, rest);
    - `senju-kasa-fire` (the tendrils);
    - `senju-weave-tick` (the passes, the bolt look);
    - `senju-unravel` (the hank's zone and the form advance);
    - `senju-torn` (`:on-close`: advance, 90 f lock);
    - `senju-skip`;
    - `senju-gulp` (黒砂's `:think`);
    - `senju-awaken-enter` (stitches to 0, the domain look).
  - **Three cinematics.**
- **`senju-art.lisp`** (~720 lines):
  - bodies `:senjumaru` (the gold bone arms, the crescent, the okobo, the empty sleeves) and `:shinpei`;
  - the weapon `:shigarami` (the needle, the thread ribbon);
  - the echo arms;
  - the clips;
  - the hank swatch patterns (six small procedural textures in the house palette, also used by the zone looks and the
    wrap);
  - the loom and torii prop, and the domain drapes.

**Character select:** automatic (a `:base` kit adds her to `*roster*`). Also:
- `*brush-names*` `(:senjumaru "修多羅千手丸" "SHUTARA SENJUMARU")`;
- `:intro :sj-intro :intro-callout "SHIGARAMI"` (the needle drawn out of the air, the thread following);
- `:win :sj-win` (she threads the needle);
- the P2 tint follows the existing rule (her white cold-shifted, the gold desaturated).

**Clips: 21 new**
- **Base (15):** `:sj-stance`, `:sj-q1`, `:sj-q2`, `:sj-spin`, `:sj-f1`, `:sj-f2`, `:sj-drop`, `:sj-yank` (L), `:sj-summon`
  (SP1), `:sj-kasa` (SP2), `:sj-breaker` (the dash loop), `:sj-saidan` (the strike), `:sj-intro`, `:sj-win`, `:sj-awaken`
  (the praying pose, cinematic).
- **Awakened (6):** `:sj-loom-stance`, `:sj-weave` (the hold loop), `:sj-unravel` (the release; also the O strike),
  `:sj-tanmono`, `:sj-makitori`, `:sj-snip` (SP1).
- **Reused:**
  - base: J2s / K2s on `:sj-q2` / `:sj-f2`; NUICHI's strike on `:sj-spin` and its dash on `:sh-run`;
  - awakened: J1 / J2 / J3 / K2 derived on the base clips; the O lane's strike on `:sj-unravel`;
  - **the soldier on the shared rig with no new clip:** `:sh-walk-f` (walk), Rukia's `:ru-thrust` re-timed to its 18 f
    tell (the thrust), `:sh-crumple` + an alpha fade (its death);
  - every reaction, walk, strafe, step, guard and the run set on the shared `:sh-*`.

**Glyphs to bake** (`tools/glyph-bake.py`; skip those already baked; 黒 comes with Ichigo's batch). About 44:
修 多 羅 手 丸 仕 立 直 し 出 六 色 浮 文 機 娑 闥 迦 骸 刺 絡 辻 悪 い 癖 神 兵 傘 裁 ち 朶 眼 金 砂 腸 つ く 褥 焼 原 闇 夜 星 針.

The brush columns:
- the name 修多羅千手丸;
- 悪い癖, 神兵, 傘, 裁ち直し (the technique columns);
- the six chants' titles: 万朶の眼, 刃金のよろい, 黒砂の腸, 凍てつく褥, 焼野原, 闇夜の星よ (at the unravel);
- 仕立て直し, 卍解 / 死出六色浮文機, 卍解 / 娑闥迦羅骸刺絡辻;
- the labels 針 and 機.

SAIDAN, NUICHI, TANMONO-UCHI and MAKITORI stay brush Latin (the Breaker rule; normals have no callouts).

**Sounds: 6 new** (`sounds.lisp`, synthesized):
- `:thread-zip`: a fast thread pull (sewing, the tailoring);
- `:needle-burst`: a dense metallic spray (L, the Kikon);
- `:shuttle`: a wooden loom clack (each weave pass);
- `:cloth-unfurl`: a heavy cloth whoosh (every unfold, the carpet);
- `:shears`: a heavy snip (SAIDAN, the skip, the Kikon's cut);
- `:candle-out`: a soft puff with a low bell tail (the awakening).

Reused:
- the general set: `:whoosh-light`, `:cut`, `:clang`, `:hoho-out`, `:kikon-slash`, `:konpaku-shatter`, `:awaken-rise`,
  `:awaken-boom`;
- by hank: the fire crackle / whoosh (焼野原), `:freeze` and `:frost-tick` (褥), `:ground-crack` (刃金 closing, 黒砂's gulp).

**VFX** (vfx.lisp; the house palette, BLOOD only in thin threads):
- the red thread (a ribbon from the needle's eye) and **the stitches' threads on the victim**, one per count, anchored at
  his torso;
- the needle burst (a fan of short white-gold spikes);
- the tapestry drop and the soldier's cloth burst;
- the umbrella canopy (threads between the six hands) and the tendrils (a `:wave` look: red-cored ink strands);
- **the six zone looks**, all hazard `:look` functions (Rukia's built function-as-look):
  - the mirror ring with eye pupils that track him;
  - the maiden's rising gold sheets;
  - the black spiral pit with sand swirl;
  - the snowflake bed (SOUL glass, Rukia's ice rules);
  - the burning cloth procession with ink trees (FIRE flame tongues on madder cloth);
  - the night-blue dome with a white star (alpha 0.35);
- each zone's 20 f unfold (a bolt unrolling onto the shape);
- the weave bolt between her hands;
- the loom threads to the torii-loom;
- the aura strips (semi-transparent);
- the domain drapes;
- the cinematic wrap, the garment tint, the shears.

**The generic pieces this design depends on from Ichigo's branch** (reused by name, not re-designed):

| Ichigo gap | Piece | Senjumaru's use |
|---|---|---|
| 4 | the parry window read from the move's own S / A | the umbrella's f4–27 window |
| 5 | `:parry-block`: a hazard / ranged hit in the window blocked with no blockstun | the umbrella's catch |
| 6 | `:pull d` hitwin key (`pull-kb`, `set-reaction` kb ≠ 0) | MAKITORI (to 1.4 m), 黒砂's gulp (to the centre) |
| 8 | `:clone` hazard kind (a body drawn, `:rift` touches-p and delay, `close-rifts`, `:src`) | the Divine Soldier's body and strike |
| 9 | `:cuts` hazard flag (opponent `:wave` / `:fireball` overlapped each step) | 眼's `:reflect` mode (N6) |
| 10 | "one of each" (the owner's older hazard with that look removed) | one soldier, one live zone. **Proposed: hoist Ichigo's helper from ichigo.lisp into hazards.lisp** as `replace-own-hazard (owner look)` so both kits share it |
| 11 | AI: `:awaken :ranged-share`; `:react :projectile` with a timed defensive move | the awakening rule; the umbrella's timing |

Also reused: Ichigo's `defmove-copy`-with-overrides use for combo copies and the speed-0 `:wave` for a stationary strip
(both built or in his design). If Senjumaru is built before Ichigo is merged, these seven pieces are built first in her
batch, to his spec.

**Existing systems reused** (built):

| System | Where it comes from | Senjumaru's use |
|---|---|---|
| `cast-point` | South | every hank cast ≤ 9 m |
| `:freeze` hazard kind (a disc no blade cuts), `:src`, `:fragile`, function looks | Rukia | 刃金, 褥, the stuck needles, the unfold's fragility |
| frost status | Rukia | 褥's frost 60 |
| `field-velocity` / `field-step` | Rukia's cold field | 黒砂's drag (about the pit's centre) |
| kit forms per state, `set-form`, `:l-after-k`, `kit-command-ok-p`'s `combo` overdraft | Nozarashi's cups, Rukia's bands, DUEL_STRINGS §12 | the six hank forms, the combo cut |
| `pip-step` (a count with a clock), `%hud-arm` pips | Kenpachi's UDE | the stitches' decay and pips |
| `close-rifts` ("closes when its owner is hit") | KUKAN-GIRI | the torn weave |
| the `:wave` hazard, `:pillars` rehit, fire chip 12 % | Yamamoto | the tendrils, 焼野原 |
| the ENJO module (no dash, a locked lane) | Yamamoto's Kikon | UKIMON NO HATA |
| the flash-step look | KITA: TENCHI | NUICHI |
| the `:hand` entity's model / anim draw | South | the soldier's body (via Ichigo's `:clone`) |
| `:awaken` counters, debug 39000 A/B, `:stun-follow`, `:tell` reflex | Rukia | the rule, the A/B, the zone tells |
| `cut-hazards`' overlap test | Nozarashi's `:projectile-cut` | the frail soldier (N3) |
| the ribbon / trail history | Rukia's ribbon | the thread, the echo arms |
| `body-variant`, `:calm`, `(:head …)` girth | Rukia, Kenpachi | her look |

**Engine gaps, new** (all generic and data-driven; no-ops for Y / K / R / I):

| # | Gap | Size |
|---|---|---|
| N1 | **A count meter**: `:meter (:name :max :count t :decay (idle per))`. It reuses `pip-step`'s clock rule; `kit-command-ok-p` refuses `:sig` at 0 in such a form. Plus **`:sew (:hit n :block n)`**: her J / K link or O-strike contacts add to it, paid at `kosei!`'s call site | ~25 lines, combat.lisp / fighter.lisp |
| N2 | **`:spare`** hitwin flag: the hit never takes the last Reishi point (no Soul Break), as chip already does | ~3 lines, combat.lisp |
| N3 | **`:frail`** hazard slot: any opponent melee window or hazard overlapping it destroys it. `cut-hazards`' overlap test, run for every fighter against `:frail` hazards only | ~12 lines, combat.lisp |
| N4 | **`:think SYMBOL`** hazard slot: called each step with the hazard (the soldier's walk and strikes, 黒砂's gulps) | ~4 lines, hazards.lisp |
| N5 | **`:zone` hazard kind**: a stationary disc (radius SIZE) that applies per-step effects to the opponent whose centre is inside: `:field (:away :step)` via `field-velocity` / `field-step` about its centre, `:drain (:reiatsu r :fs f)` per second, `:mirror k` (his melee contacts on the owner cost him k × their damage, unguardable, never kills). Plus **`:stick t`**: a hazard whose x z follow its target each step (the needles) | ~40 lines, hazards.lisp / combat.lisp |
| N6 | **`:cuts :reflect`**: Ichigo's `:cuts` overlap, but the overlapped opponent `:wave` / `:fireball` changes owner and reverses its yaw instead of being destroyed | ~6 lines |
| N7 | **`:on-close SYMBOL`** hazard slot: `close-rifts` calls it when it closes a fragile hazard (not on `clear-hazards`: a reset never tears) | ~2 lines |
| N8 | **`:one-live CMD`** kit key: `kit-command-ok-p` refuses CMD while a hazard of hers flagged `:live` exists, **unless** it is a combo command (`combo` argument, built), which first ends the live one | ~6 lines, fighter.lisp |
| N9 | **The umbrella**: move flag `:shield` (in the move's own S / A window, via gap 4, the defender state is `:guard`, front 200°) + move hook **`:catch SYMBOL`** (called with the hit's damage when a hazard / ranged hit is blocked through gap 5's branch in that window) | ~10 lines, rules.lisp / combat.lisp |
| N10 | **AI**: `:hari (:min :hurry)`, `:weave (:far :near)` (hold length by distance for any `:hold` L: Shiranui's charge rule, generalized), `:skip (:ranged-below)`, `:awaken … :or-opp-rooted`, `:opp-rush-hold p` (read off the opponent's kit), the tell reflex counted from the release for a `:hold` move | ~45 lines, ai.lisp |
| N11 | **HUD**: `%hud-needles` (pips, flicker), `%hud-loom` (six swatches: lit, fill, live drain, torn slash, skip slide), labels, the portrait small-gauge slot, `portrait-label`; one-hand: the ring's needle ticks and pass ticks | ~60 lines, hud.lisp / onehand.lisp |
| N12 | **Art**: the echo arms (4 lagged bone chains); a form key `:stage :cloth` read by stage.lisp (the domain drapes and the loom prop while a fighter in such a form lives); the victim's stitch threads (read from the opponent's count meter) | ~110 lines, senju-art.lisp / stage.lisp / vfx.lisp |

**Host tests** (`tests/duel-rules-test.lisp`):
- **Strings:** the §2.1 budget over `:base :tsuji1` (the six routes, the copies; `:tsuji2`–`6` inherit).
- **Stitches:** hit +2 / block +1 / parried 0, capped at 6. The decay: 179 idle → none fall, 180 → one, then one per 30.
  L refused at 0.
- **The spikes:** `:spare` leaves 1 Reishi. The last spike is +6 and not a combo. The `-k` copy combos after every K link
  (A 4 + 8 + 2 × 5 ≤ 25 < 26).
- **The soldier:** `:src` blocks facing her. Frail: a J1 window overlapping it destroys it. Two strikes max.
- **The umbrella:** melee → `:blocked` (a guard); a hazard → caught and recorded; a Breaker → Guard Break; the fire-back
  = 40 + ½ caught ≤ 120.
- **The loom:**
  - a release advances the form 1 → 2 … 6 → 1;
  - `:one-live` refuses L while live and allows the `-k` copy (the live one ends);
  - a close during the hold / the unfold → `senju-torn` (form + 1, lock 90);
  - `clear-hazards` → no tear;
  - the skip advances by one.
- **Scaling:** for each hank, radius / life / damage are non-decreasing in passes. Every disc's full r + 0.45 < 2.5; the
  corridor's half-width + 0.45 < 2.5; the tendrils' half-width + 0.45 < 2.5.
- **The combo cut:** every hitting hank's `-k` copy lands before stagger 26 ends.
- **Reaches:** every Breaker strike > 2.2; every Kikon strike > 1.9. **Kikon counts:** 2 / 3; Soul Break 3 / 4.
- **Zones:** `:reflect` turns a fireball's owner and yaw; `:mirror` never kills; `:drain` 30 / 15 per s.

**Probes** (debug, a new block, e.g. 2450 + k; stills at 76000 + f / 77000 + f / 78000 + f for the three cinematics in
landscape and portrait):
- a hit JJJ → 6 stitches → L at 5 m → 60, 1 Reishi left on a 50 Reishi victim;
- a Hoho during L's yank is perfect;
- Kenpachi's stance absorbs K1 → +1 stitch → the spikes go through the stance;
- the soldier walks into a Kenpachi J1 and dies; its thrust is blocked facing her;
- the umbrella catches a Shiranui and fires back 40 + ½;
- a 3-pass weave hit at f30 → torn, form + 1, L refused 90 f;
- 眼 reflects a Signature wave; the mirror returns 30 % of a K1;
- 黒砂 drags a walk to ×0.4 and a Step still exits;
- 褥 freezes on entry once;
- 焼野原's two hits and its fire chip;
- 星 drains a full flash-step bar in 6.7 s;
- the combo cut after K1 on a live 褥;
- a zero Rukia inside 刃金 (optic: hit);
- the determinism double run.

**Implementation order:**
1. Rules and host tests.
2. Ichigo's seven pieces, if not merged yet.
3. Kits with placeholder clips (Rukia's and Ichigo's clips on the `:senjumaru` body, no echo arms), then N1–N9 and a
   minimal HUD. The gate: the old pairings byte-identical, then SY / SK / SR / SS (SI with Ichigo).
4. The AI keys (N10); the gate again, and the awaken A/B.
5. Art: the two bodies, the needle, the echo arms, 21 clips, the zone looks, the domain, three cinematics, sounds,
   glyphs. User review with stills (the head ×1.3, the six arms, BLOOD budget).
6. Docs:
   - DUEL_DESIGN §1 (the roster), §6.6 (new: Senjumaru), §6.3 (NUICHI and UKIMON NO HATA rows), §7, §10 (the HUD, the
     cinematic table: 仕立て直し 186, 死出六色浮文機 198, awakening 180), §12 rows;
   - DUEL_MOBILE_DESIGN §15 (the needle / pass ticks);
   - STYLE_STORM §A.2 (muted gold and madder, not spots);
   - a new docs/duel/DUEL_SENJUMARU.md from this file.

---

## 11. Knobs (all in `duel/lisp/tuning.lisp` unless noted; debug numbers assigned at build)

| Knob | Value | Note |
|---|---|---|
| `*walk-senju*` / `*run-senju*` | 3.6 / 8.5 | base |
| `*walk-tsuji*` / `*run-tsuji*` | 3.3 / 8.0 | awakened |
| `*senju-mult*` / `*senju-taken*` | 1.0 / 1.0 | base; the first pacing knob (§9) |
| `*tsuji-mult*` / `*tsuji-taken*` | 1.0 / 1.0 | awakened; the A/B's first knobs |
| `:sew` | hit 2 / block 1 | senju.lisp |
| `*hari-max*` / `*hari-idle*` / `*hari-fall*` | 6 / 180 / 30 | the stitches' cap and decay |
| `*hari-dmg*` / spike gap / last flinch | 13 (10 until 2026-10-01) / 2 f / 18 | WARUI KUSE (+6 on its own) |
| soldier speed / rise / string / life | 3.5 m/s / 10 f / `*shinpei-combo*` 18 f → 20, 14 f → 20, 16 f → 34 / 300 f | since 2026-10-01 (tell / dmg / rest / strikes 18 f / 50 / 50 f / 2 before) |
| umbrella window / fire-back base / cap | f4–27 / 40 / 120 | SP2 |
| NUICHI speed / dash-max | 26 m/s / 14 f | reach 7.7 |
| `*weave-pass*` / passes | 20 f / 1–3 | the hold |
| `*unfold*` / `*unfold-combo*` | 20 / 10 f | the tell |
| `*torn-lock*` | 90 f | the forced exit |
| `*hank-range*` | 9.0 m | `cast-point` |
| 眼 r / life / mirror | 3.0 / 240 / 0.3 | |
| 刃金 r / rise / dmg / guard | 2.0 / 16 f / 90 / 24 | |
| 黒砂 r / away / gulp period / dmg | 2.0 / 0.4 / 60 f / 40 | |
| 褥 r / dmg / freeze / frost | 2.0 / 70 / 40 / 60 | |
| 焼野原 width / max length / hits / dmg / life | 2.0 / 10 / 2 / 45 / 150 | |
| 星 r / drain (R, FS per s) / life | 3.5 / 30, 15 / 240 | the drain and his Reiatsu / flash-step gains go to her (the siphon) |
| skip cost | 1 bar | |
| AI | `:awaken :ranged-share` 0.3, `:min-taken` 150, `:or-opp-rooted` t; `:hari` 4 / 40; `:weave` 6.5 / 4.0; `:skip :ranged-below` 0.2; `:opp-rush-hold` 0.5; base `:block-string` 0.8; zone weight 4 | |
| art | `(:head 1.3 …)`, echo spread ±28° / ±52°, lag 2 / 4 f, aura alpha 0.45 | stills review |

---

## 12. Adversarial self-critique

| # | Sev | Finding | Resolution (folded into the text above) |
|---|---|---|---|
| B1 | BLOCKER | **Unguardable detonations** could be a guard-bypass that also kills a red opponent: a free 60 after every string, from anywhere | `:spare` (never the last point, so no Soul Break: the report's rule); 10 per stitch; the 3 s decay; iframes dodge it and a Hoho in the yank is perfect; the last spike is +6, not a combo; she must first land contact with the lightest strings in the game |
| B2 | BLOCKER | **Stitch loops**: spikes → J string → 6 stitches → spikes … | the spikes leave her +6 (J1 lands 1 f late); after a detonation the count is 0, and 6 needs a whole landed string again; in a combo, L-after-K is scaled and not an ender (no O after it) |
| B3 | BLOCKER | **Zone uptime** could become permanent terrain, and a ranged stall (SR / SS / SY > 210 s) | one live zone; 26–66 f of visible weave per zone, torn by any hit; the 90 f lock; heat; `:opp-rush-hold` makes CPUs rush a weave; discs ≤ 2.0 m, so one Step leaves; knobs in §9 |
| B4 | BLOCKER | **Soldier + her = a front / back unblockable** | `:src` = Senjumaru: a guard facing her blocks the soldier wherever it stands; it walks the line to him, so it arrives in front |
| B5 | BLOCKER | **CPUs never kill the soldier** (they can't aim at it): free chip every summon, pacing drift | it walks into his frontal arc, so his attacks at her hit it; `:frail` to any window or hazard; the pacing log counts kills; knob: strikes 2 → 1, life 300 → 180 |
| B6 | BLOCKER | **Hash drift** from `cut-hazards` generalized, new hazard slots, the tell-reflex fix | every new path is keyed on data only she spawns (`:frail`, `:zone`, `:think`, `:stick`, `:on-close`) or a kit key read off her kit; the tell fix applies only to `:hold` moves with `:tell` (none exist); gate step 3 checks the old pairings byte-identical first |
| B7 | BLOCKER | **A reset during a weave** must not tear (a free queue skip for the opponent) | `:on-close` fires only from `close-rifts`, never from `clear-hazards` (host-tested) |
| M1 | MAJOR | **BLOOD overload** (threads, a red domain, a red carpet) blurs the Kikon tell (the rush trail, the red soul flames) | BLOOD only in 1–2 px threads; the cloth, the carpet and the drapes are muted madder (S ≤ 0.45); the aura is semi-transparent strips; stills review; a 13th palette slot only if the stills demand it |
| M2 | MAJOR | **Six arms without a rig change** may read as two arms plus stiff props | the echo arms follow the real hands with a 2 / 4 f lag and a spread, so every strike ripples through six hands; the stills review decides; fallback: 2 echo arms, not 4 |
| M3 | MAJOR | **眼 is dead weight vs Kenpachi** in a fixed order, and the skip costs a bar | intended matchup texture (the base form is the answer vs Kenpachi); the 30 % mirror gives 眼 a melee use; the "trap" knob list makes the skip free |
| M4 | MAJOR | **Blocked contact sews**, so blocking her becomes a losing option (a "no-guard" character) | guarding still halves what she gets (1 vs 2) and saves the string damage; the detonation can be Hoho'd; knob: `:sew :block` 0 on J links |
| M5 | MAJOR | **黒砂's drag + gulps + pull** could hold him in a stun lock | 3 gulps max, 60 f apart (34 f free between them); a Step is never shortened (r 2.0 + 0.45 < 2.5); gulps book as combo hits (Burst legal after the 2nd); guard facing her blocks each |
| M6 | MAJOR | **星 drains flash-step**, so a drained victim can't Burst her O ender: every O ender → Kikon on red | she must stand inside her own 3.5 m dome to use it (the rusher's range); he can leave (no hit, no drag); it is the queue's last hank, once per cycle; knob: drain 15 → 10. Since the siphon (2026-09-29) it also feeds her and freezes his gains inside: the same answer (he walks out), and the knobs in order are the radius, the life, the drain |
| M7 | MAJOR | **The corridor is a `:wave`**, so Nozarashi's projectile cut and Ichigo's `:cuts` delete it | accepted and canon-flavoured (a blade through cloth); the discs and zones are not cuttable (`:freeze` / `:zone` kinds) |
| M8 | MAJOR | **The awakened SP2 at 2 bars** overlaps 眼 and makes the umbrella rare | accepted: the universal rule; 眼 carries anti-projectile duty in the awakened form |
| M9 | MAJOR | **The universal awakened Kikon 3** biases "always" | offsets: no stitches, the weave risk, the slower walk; the A/B knob list starts with `*tsuji-mult*` |
| M10 | MAJOR | **`:opp-rush-hold` could make every CPU too good** against her, so "never" wins by default | p 0.5, one roll per hold; weaves beyond 6.5 m are out of most rushes' reach; knobs both ways |
| M11 | MAJOR | **Art batch:** 21 clips, 2 bodies, echo arms, six zone looks, a domain and 3 cinematics | 9 moves reuse clips, the soldier has none, the zone looks are hazard look functions; placeholders let the gate and the A/B run first |
| M12 | MAJOR | **Seven dependencies on an unmerged branch** | listed by gap number (§10); built to Ichigo's spec in her batch if needed; SI waits for him |
| m1 | MINOR | Invented names ([G]) could read as canon: the sewing-term strings, SAIDAN, NUICHI, TACHINAOSHI, UKIMON NO HATA as a module, 仕立て直し as a caption | §13's ledger; each is tagged [G] in the tables |
| m2 | MINOR | The Blood Oath is grim | three candles only (Q11, decided) |
| m3 | MINOR | Canon's hanks are tailored per opponent; the fixed order is not | Q10 decided "fixed first"; per-opponent order is v2 (a kit `:order` per opponent character, data only) |
| m4 | MINOR | The eight-kanji Bankai name is long for a caption column | its own column beside 卍解; the HUD uses SHIGARAMI NO TSUJI |
| m5 | MINOR | The soldier reuses Rukia's thrust clip | on a 1.9 m faceless body with a spear it reads differently; stills check; a spear clip later if asked |
| m6 | MINOR | Two awakened Senjumarus both drape the rim | the stage draws the drapes once (the look is per match, not per fighter) |
| m7 | MINOR | The cloth double on Hoho / Burst could read as a decoy mechanic | the look is the universal Hoho's timing; it crumples in 12 f; no hurtbox |

Revision: every finding above is folded into the text. Five ideas were dropped on purpose:
- **Antithesis** (a Burst inside a zone reverses it onto her): a fun canon beat, but it doubles the test surface of every
  zone (report's advice).
- **Hollow cloths** [A ep. 27] as a seventh hank or an SP: the report's advice; one queue of six reads cleanly.
- **Healing with cotton** [A ep. 26]: a heal is a power ramp.
- **Shrinking the arena to a domain:** it would change every opponent's movement rules and the reset geometry; the domain
  is a look.
- **The rag doll as a guard-crush escape** (the research's hook): a defensive power tool with its own meter would break
  "one resource per form". It stays a Hoho / Burst look.

---

## 13. Canon ledger (what is manga, what is anime-only, what is ours)

| Element | Source | Tag |
|---|---|---|
| Shutara Senjumaru, 大織守, Zero Division 4th officer, North's Divine General, 158 cm, inventor of the shihakushō | manga (ch. 516–517; Klub Outside Q&A) | [V] |
| six golden skeletal arms used instead of her hands; the golden crescent ornament; long black hair; white haori / over-robe; okobo | manga (ch. 517) | [V] (the echo-arm technique is ours [G]) |
| polite, serene, darkly playful; 妾 | manga | [V] (her `:calm` face) |
| tapestries that hide soldiers; Divine Soldiers; a Second-Level soldier crushed by Pernida | manga ch. 597–599 | [V] (SHINPEI) |
| re-tailoring Nianzol's robe, spikes from inside; "my bad habit is forgetting to remove my sewing needles" | manga ch. 598–599 | [V] (the stitches' theme, 悪い癖, the base Kikon) |
| Gerard shatters her needle | manga ch. 599 | [V] (the light strings) |
| the fake palace; the fabric body that "died" | manga ch. 600 | [V] (the Hoho / Burst cloth double, a look) |
| **Shikai name 刺絡 Shigarami**; a sewing needle; the endless red reishi thread | TYBW ep. 26 / 27 | **[A]** |
| **the umbrella** that blocks Licht Regen and fires tendrils | TYBW ep. 25 | **[A]** (傘 KASA) |
| **sewing a foe to the ground** | TYBW ep. 26 | **[A]** (the NUICHI look) |
| **the rag doll decoy** | TYBW ep. 26 | **[A]** (the cloth double, a look) |
| healing with cotton and thread; expert Shunpo vs Uryū | TYBW ep. 25–26 | **[A]** (Shunpo: NUICHI's flash step; healing not used) |
| **the Blood Oath Seal**; the three Divine Generals' suicides | TYBW ep. 26 | **[A]** (three candles only, Q11) |
| **the Bankai 娑闥迦羅骸刺絡辻** (name and reading); the torii → golden loom; red bolts; the red carpet; cloth walls | TYBW ep. 26 | **[A]** (the awakening, the domain) |
| **死出六色浮文機**; one hank at a time; cutting the finished pieces off the loom with the victims sealed | TYBW ep. 26 | **[A]** (the loom, the awakened Kikon) |
| **the six hanks** (万朶の眼, 刃金のよろい, 黒砂の腸, 凍てつく褥, 焼野原, 闇夜の星よ) and their chants | TYBW ep. 26 | **[A]** (the zones; their game effects are ours [G]) |
| the Almighty frees Uryū; Antithesis traps her in her own Bankai; her death | TYBW ep. 27 | **[A]** (the torn rule's theme; Antithesis not used) |
| the Hollow cloths | TYBW ep. 27 | **[A], not used** |
| Kubo's involvement in the Bankai | no source | **not claimed** |
| the Shikai release command; a Bankai chant | unknown | **none invented** |
| Brave Souls "Bad Habits" special; the TYBW 2025 Bankai version (a status per button) | KLab | a reference; names not reused beyond 悪い癖 (her own canon line) |
| every other move name: HITOHARI, KAESHINUI, SENJU, MACHIBARI, MATSURI, KUKE, SAIDAN, NUICHI, TANMONO-UCHI, MAKITORI, TACHINAOSHI, KASE TOKABA (from the chant's 綛解かば), UKIMON NO HATA (the module, from the technique's name), 仕立て直し (the caption) | ours | [G] |

The base form draws on manga and anime together; **the whole awakening is anime-only.** If a later official source (a guide
book, a game) contradicts it, §4 is the section to revise.

---

## 14. Questions for the user (each with the recommended default)

1. **針：命中 +2、被擋 +1，最多 6 針，3 秒後開始脫落；L 引爆每針 10、不可防、不能 Soul Break？** 建議：是。
   *Stitches: +2 on hit, +1 on block, max 6, falling after 3 s; L detonates 10 each, unguardable, never a Soul Break?* **Default: yes.**
2. **織機：按住 L 織 20–60 f（1–3 趟），被打中就撕毀、跳過並鎖 90 f，同時只有一綛在場，SP1 花 1 bar 跳過下一綛？** 建議：是。
   *The loom: hold L 20–60 f (1–3 passes), torn if hit (hank lost, 90 f lock), one zone at a time, SP1 skips the next hank for 1 bar?* **Default: yes.**
3. **第 6 綛「星」以她自己為中心（吸取對手靈壓與瞬步），其他五綛放在對手腳下或從她延伸到對手？** 建議：是。
   *Hank 6 (the star) centred on her, draining his Reiatsu and flash-step, while the other five go under him or from her to him?* **Default: yes.**
4. **神兵沿直線走向對手、被打一下就倒、防禦判定從千手丸方向算？** 建議：是。
   *The Divine Soldier walks the line to him, dies to one hit, and is guarded facing Senjumaru?* **Default: yes.**
5. **外觀：頭 ×1.3、兩隻骨架手臂加四隻特效手臂（不改骨架）、金色與布料都用低彩度，紅色只留給細線？** 建議：是。
   *Look: head ×1.3, two rig arms plus four echo arms (no rig change), muted gold and madder, BLOOD only in thin threads?* **Default: yes.**
6. **CPU 覺醒規則：受傷 ≥ 150 且 ≥ 30 % 來自遠距，或對手處於不能移動的形態？** 建議：是。
   *CPU awakening rule: after ≥ 150 taken with ≥ 30 % ranged, or when the opponent is in a rooted form?* **Default: yes.**

---

## User decisions (2026-09-28)

- Questions 1–6: **the recommended defaults**.
- **神兵 SHINPEI (SP1) is buffed so ignoring or swatting it both cost the opponent:** when it is destroyed it bursts into
  red thread and **sews 1 stitch onto whoever destroyed it** (base kit: it feeds 悪い癖's detonation); it walks at
  **~3.5 m/s** (was 2.4). Everything else as §3.3 (1 bar, one at a time, 2 strikes, 300 f, dies to one hit).
- **傘 KASA (SP2) always fires:** at f28 the tendrils fire **whether or not anything was caught** — base 40, 10 m, side
  Step clears it; + ½ of the largest caught hit (cap 120). The "nothing caught → nothing fires, 18 f punish" rule goes.
  Melee in the window stays a plain guard (no counter). Awakened cost 2 bars (universal SP2 rule).

**Code layout (the user, 2026-09-28; docs/duel/DUEL_DESIGN.md "Character code layout"):** build this character in its own
files (`<name>.lisp` + `<name>-art.lisp`), including the mechanics listed here as "generic gaps": implement them locally
in the character's files behind the smallest possible generic hook points in the shared files. Do not depend on the other
new character's branch; an extraction pass after both merge moves the real repeats into the shared files.

### The A/B criterion (the user's decision, 2026-09-28)

「覺醒偏強沒關係，只要不是強到無法贏就好」: the awakening may be the stronger choice. The gate is: **on each of at least
three independent seed streams (60 seeds each), P1 Senjumaru playing "never awaken" still wins at least 20 of 60 against
each opponent** (SY, SK, SR, SS; the opponent on its own rule). The design's "|always − never| ≤ 9" and "SK favours
never" (§9) are no longer gates; they are logged below as nice-to-have. (A single stream was found to overfit: every
extra CPU roll reshuffles a whole match, so one stream's 60 seeds can swing a pairing by ±15.)

## Playtest: reach matches the art (the user, 2026-09-29)

「千手丸的 J／K 判定距離比動畫顯示的長很多，很難判斷距離」: the user played her and could not read her range. **The rule
applied: every J / K link's hit volume ends where the art strikes at its hit frames, within 0.15 m.** The volume's far
edge is where his hurt cylinder's near side may stand (an arc's radius, a capsule's end + its radius; he connects up to
that + his hurt r, 0.36–0.45). What she strikes with is the tip of the needle (radial for an arc, straight ahead for a
capsule; the rig's FK over her own poses) or the K link's prop at its far end. The echo arms never reach past her rig
hands (they follow them, turned about her spine), so they don't count.

- (**Superseded 2026-09-29 by the J cut**, DUEL_STRINGS.md §13: J is light, short and fast for everyone; her J is 1.44 m,
  the needle 1.2 m, the K props shortened with their volumes. The record of the first playtest follows.)
- **The J links (the needle).** The first try trimmed the reach to the old 0.9 m needle's tip (1.6 m, then 2.0 m with a
  1.35 m needle): the seed gate had her win SY 1–4 / 20, SR 2 / 20, SI 2 / 20 (medians still inside the window), and
  `*senju-mult*` 2.0 moved SY only to 5 / 20 while pulling its median to 127.9 s. Her strings were being outranged, not
  out-damaged. So the **needle grew instead: 0.9 → 1.8 m, as tall as she is** (1.58 m at her scale 0.88; Shigarami is a
  giant sewing needle), and each hit pose lunges a little deeper (`:root :f` +0.10–0.12). Its tip now reaches 2.35–2.37 m
  at the hit frames: J1 / J2 keep **2.4 m**, J3 is trimmed 2.6 → **2.4 m**.
- **The K links (thread, pins, cloth)** get a prop that reaches the volume, drawn from her hands during the hit (flung over
  the 4 frames before S, out through the active frames, drawn back over 8: `senjumaru-art.lisp` `*SJ-STRIKE-REACH*`,
  `SJ-STRIKE-PROPS`); no K volume moved.
- **The Bankai's ×1.15 derivation** ("cloth on every hand") had no cloth drawn, so it went: its J1–J3 / K2 are the Shikai's
  (and its Breaker is the universal 2.6 m again, not 2.99).

| Form | Link | Volume far edge, before → now (m) | The art's far end, before → now (m) | Change |
|---|---|---|---|---|
| both | J1 HITOHARI | 2.4 (TSUJI 2.76) → **2.4** | needle tip 1.49 → **2.37** | needle 0.9 → 1.8 m; hit pose `:root :f` 0.2 → 0.32 |
| both | J2 KAESHINUI / J2s | 2.4 (2.76) → **2.4** | 1.52 → **2.36** | the needle; `:root :f` 0.16 → 0.28 |
| both | J3 SENJU | 2.6 (2.99) → **2.4** | 1.52 → **2.35** | trimmed; the needle; `:root :f` 0.1 → 0.2 |
| Shikai | K1 MACHIBARI | 3.5 (capsule 0.3–3.2, r 0.3), kept | needle tip 1.67 → **two long pins to 3.5** | lengthened (a pin out of each hand, straight ahead) |
| both | K2 MATSURI / K2s | 2.8 (TSUJI 3.22) → **2.8** | needle overhead, 0.1 → **a loop of thread to 2.8** | lengthened (two red strands whipped from the needle's tip up and down at him) |
| Shikai | K3 KUKE | 2.8, h 0–1.4, kept | needle tip 1.56 → **pins round his feet at 2.8** | lengthened (five pins slammed into the plaza at 2.1–2.8 m, ±40°, threads to her hands) |
| TSUJI | K1 TANMONO-UCHI | 4.5 (capsule 0.3–4.2, r 0.3), kept | needle tip 1.52 → **a bolt of cloth to 4.5** | lengthened (a flat madder band from both hands) |
| TSUJI | K3 MAKITORI | 2.8, h 0–1.4, kept | hands 0.2 → **cloth to his feet at 2.8** | lengthened (a strip from each hand down to 0.35 m, ±10°) |

The heights agree: the needle at 1.3–1.5 m and the J arcs' 0.2–2.0, the pins and the bolt at the hands' 1.1 m (the
capsules' h 1.1), the loop landing at 0.6 m, KUKE / MAKITORI at the feet (h 0–1.4). **The CPU** (§7.2) keeps its tables:
the J reach it reads (`mv-reach`, 2.4) is unchanged; only the Bankai's J / K2 got shorter, inside its 0–2.8 band's
"don't whiff at range" test. **The string chase** (`string-chase-speed`) reads the reaches as before. **The host test**
(`duel-rules-test`, after the Senjumaru block) loads `anim.lisp` and her poses read from `senjumaru-art.lisp`, runs the FK
over every J / K link's active frames in all seven forms and checks the tip (or `*SJ-STRIKE-REACH*`'s far end) against the
volume's far edge within 0.15 m.

**The seed gate after it** (seeds 1–20, 2125+k, one run per pairing): SY 135.6 s (Senjumaru 11 / Yamamoto 9), SK 142.7
(6 / 14), SR 173.8 (11 / 9), SS 187.2 (10 / 10), SI 166.7 (10 / 10); 100 / 100 K.O., every median in 125–210 s (before:
143.2 / 136.9 / 173.7 / 195.3 / 170.6).

---

## 星 siphons (the user, 2026-09-29)

「在千手丸第 6 綛「星」的範圍內，對手無論受擊還是攻擊都不應該回復量表，然後吸收的量表應該要反還到千手丸自己身上」.
**Inside her live, unfolded 星 he gains no gauge at all**, whether he is hit, blocks, parries or lands his own blade: no
Reiatsu, flash-step or Fighting Spirit, no kit meter (NOME, Inferno, the cold, the chain / ward refills, the Konpaku-loss
Fighting Spirit). **What he would have gained in Reiatsu and flash-step goes to her**, each capped at her max; the rest is
lost (she is awakened: no Fighting Spirit, and her loom has no meter to feed). **The drain goes to her too**: each frame
she gets what it really took (not the nominal 30 / 15 per s), capped. Passive regen is not a gain from a hit and stays.

How: one generic hook, the opponent kit's `:siphon (o e)` (DUEL_DESIGN "Character code layout"), which `siphon-of` in
combat.lisp asks at every gain (so it ends the frame the zone ends or he steps out: no state to clear). The pure part is
rules.lisp `hit-gains` (his gains, or zero and hers) and `gauge-move` (a capped transfer of what was really taken),
host-tested; her hook is `senju-siphon`. The probe 2480 (2450+30): 星 round her, Kenpachi inside, both at 0 Reiatsu;
2479 has him J1 her twice: her Reiatsu 2 → 30 → 75, his flash-step drained 16 → 0 into hers, his Reiatsu unmoved.

**The seed gate after it** (seeds 1–20, 2125+k): SY 135.6 s, SK 142.7, SR 173.8, SS 187.2, SI 166.7, 100 / 100 K.O., every row identical to the reach fix's: between CPUs the loom rarely reaches 星 with him standing inside it, so no gain was ever siphoned in those 100 matches (the probe 2480 is the check that it works).

## SP1 releases the next two hanks (the user, 2026-09-29)

「千手丸卍解的 SP1 效果改成略過準備直接發動接下來的兩綛，這樣就可以跟普攻連段組合，同時也達成多跳一綛的目標」.
**SP1 裁ち直し TACHINAOSHI now skips the preparation and releases the next two hanks** (it only skipped one before):

- **Frames:** S 8, A 0, R 22 (30 in all), 1 bar. f0 cuts her live zone(s) (the combo cut's rule), f8 releases the form's
  next hank, f14 the one after, each as the combo cut does (unfold 10; since the L split both at the passes stored when
  SP1 began, at least 1; the stored passes then reset). The form
  advances past both: **+2 in the queue**, 6 wraps to 1 (`tachi-hanks`, host-tested).
- **Two zones at once:** the first stays alive beside the second (`sjs-live2`); neither cuts the other. L's tap, the combo
  cut and the next SP1 cut both. 眼's mirror and 星's siphon read whichever of the two is theirs; the HUD drains both
  swatches. Pairs with no hit (星 + 眼) just unfold.
- **A string ender:** the universal SP cancel (`cancel-into`: from a landed link's first hit frame to its recovery's end).
  Off a stagger (26 f) the first zone strikes at +19 (1 + 8 + 10) and the second at +25: both combo. The CPU victim's tell
  reflex reads `:tell`, its first hitting hank's (10–22, or 16–28 when only the second hits). One copy per form
  (`:sj-tachinaoshi-1` … `-6`) carries it; the debug knob 97000+k sets every copy's cost.
- **The CPU** ends a landed string's last link with it (`:sp-ender`, a generic key: `senju-sp-ender`) at 0.5 when one of
  its two hanks hits; the old neutral skip of 眼 is gone.
- **A route:** at 2.2 m in 褥's form (debug 2461), TANMONO-UCHI hits (56), SP1 cancels off it 9 frames later; 褥 freezes
  him 26 frames after the K1 hit (56) and 焼野原's corridor burns twice (36 + 36): 184 before scaling, the form ends on 星.

**The seed gate after it** (seeds 1–20, 2125+k): SY 135.6 s (Senjumaru 12), SK 142.7 (6), SR 197.3 (11), SS 191.7 (P1 7 / P2 13), SI 163.6 (12); 100 / 100 K.O., every median in 125–210 s. SR is the one that moved (173.8 → 197.3): the loom awakens in most SR matches, and its zones now come two at a time.

## The hank queue in three SP1 pairs (the user, 2026-09-30)

「善哉，照你說的順序實作」: the queue was the canon chant order 眼 → 刃金 → 黒砂 → 褥 → 焼野原 → 星. It is now
**黒砂 → 刃金 → 褥 → 焼野原 → 眼 → 星**, then back to 黒砂 (`*hank-order*`). SP1 releases the next hank at f8 and the one
after at f14, so the order builds three designed pairs, the control hank first in each:

| Pair | Role | Why |
|---|---|---|
| 黒砂 + 刃金 | offence | 黒砂's drag pulls him back as he flees; 刃金 closes on the same spot |
| 褥 + 焼野原 | sure damage | 褥 freezes him; 焼野原's corridor runs from her through him |
| 眼 + 星 | defence and resources | 眼 reflects his projectiles; 星 drains his Reiatsu / flash-step into hers |

- **Mapping, not renumbering:** form `:tsujiN` is still "hank N next" and every hank keeps its number, data, dye, chant
  title and numeral (一綛 万朶の眼 … 六綛 闇夜の星よ: the canon chant's, not the queue's place). Only `hank-next` reads the
  queue; `tachi-hanks`, `weave-void` and the casts follow it. The awakening enters `:tsuji3` (黒砂).
- **Parity:** `tachi-aligned-p`: SP1 from an even slot (黒砂, 褥, 眼 next) releases a designed pair; SP1 keeps the parity, a
  single release (a tap, K → L, a voided weave) flips it. Off by one, SP1 catches the cross pairs 刃金 + 褥, 焼野原 + 眼 and
  the wrap 星 + 黒砂 (he is drained in her dome while 黒砂 makes it hard to leave). Spending a hank now against keeping the
  alignment for a full pair is the intended trade.
- **`:tell`** per copy: 眼 + 星 none; 星 + 黒砂 16–28 (only the second hits); every other pair 10–22.
- **HUD:** the six swatches in queue order, in three pairs (a wider gap between pairs). The two SP1 would release are
  framed: one gold frame round a designed pair, a grey frame round each swatch of a cross pair; bright with a bar for SP1,
  dim without. The one-hand ring shows no queue: unchanged. Stills (debug 2457 aligned 黒砂, 2456 cross 刃金): landscape
  1280×720 and portrait 390×844 (mobile) checked.
- **CPU** (her `:reflex` / `:sp-ender` / `:sig-hold`, `senju-pair-p`): in a free state with no zone live and SP1 affordable,
  `*ai-senju-pair*` (0.04) per step it opens a designed pair that suits: 黒砂 + 刃金 under 3 m, 褥 + 焼野原 at 3–7 m, 眼 + 星
  when he zones (beyond 7 m, or ≥ 30 % of what she took was ranged) or her intent is :defend. Off a landed string SP1 is
  `*ai-senju-tachi*` (0.5) on a designed pair, half that on a cross pair. On a cross slot with a bar in hand her L wants one
  pass: the quick single release that realigns. Between CPUs SP1 hanks went from 42 to 766 over the 100 Senjumaru matches.
- **Host tests:** the queue and its wrap from the awakening's 黒砂, the pairs per alignment (repeated SP1 from the entry:
  the three pairs then 黒砂 + 刃金 again; after one tap: the three cross pairs), the parity kept by SP1 and flipped by a
  single release or a void, and `*hanks*` equal to its literal table (every hank's data unchanged).

**The seed gate** (native, seeds 1–20): SY 140.5 s (P1 9 / 20), SK 153.6 (12), SR 183.9 (16), SS 181.0 (P1 15 / P2 5),
SI 197.2 (10); 100 / 100 K.O., every median in 125–210 s. The ten pairings without her are row-identical to 6043192's.
**Her awaken A/B** (`--cmd 39020`: P1 never awakens; "never" P1 wins of 60):

| Stream | SY | SK | SR | SS | SI |
|---|---|---|---|---|---|
| 101–160 | 36 | 20 | 34 | 30 | 46 |
| 301–360 | 32 | 36 | 33 | 36 | 36 |
| 501–560 | 29 | 30 | 41 | 36 | 38 |

Every cell ≥ 20 (SK on 101–160 exactly at the floor: the paired loom is stronger against Kenpachi there). No retune.

## L: hold to weave, tap to release (the user, 2026-09-29)

「將千手丸卍解的 L 分成『長按織布』與『短按發動』，讓千手丸可以將織布的行為拆成多段來減少破綻，如果織布期間受到攻擊則該綛作廢跳到下綛。SP1 與 K->L 會依據當前編織程度決定放出的綛的階數。」

- **Hold (≥ 10 f) weaves:** a pass per 20 f of weaving, up to 3, **stored on the hank across segments** (weave 1 pass, walk
  or attack, weave more). The first 10 frames of a hold count once it becomes a weave (the rate is the old one). Letting go
  just stops: `:sj-weave-stop`, 6 f. Exposure per segment: 10 f minimum; the bolt (fragile) is out only while she weaves.
- **Tap (< 10 f) releases:** S 6, the hank unravels at the stored passes (at least 1: a bare tap is a 1-pass zone), unfold
  20 (its tell counted from the release as before), the stored passes reset, the form advances. The input layer already
  had press-and-hold moves (`:hold (lo hi)`, `hold-phase-step`); L is now `:hold (1 600)` and its `:release` hook decides
  tap or stop, so the keyboard, the pad, the one-hand deck and the CPU press it the same way.
- **Hit while weaving: void.** The hank's stored passes are lost and the queue moves to the next hank; no release and no L
  lock (the old "torn weave: lost + 90 f lock" rule). A hit while not weaving keeps the stored passes. (A zone torn while it
  unfolds still locks L 90 f.)
- **K → L and SP1 read the stored level:** the combo copies release at the stored passes (at least 1) instead of 1; SP1's
  two hanks both release at the passes stored when it began (**the coordinator's default**), then the level is 0. The
  frames don't move (bigger zones, the same first contact: +22 after a K link, +19 / +25 after a stagger).
- **HUD:** the next hank's swatch fills in three steps with the stored passes, in both layouts.
- **The CPU** (`senju-sig-hold`, now given the fighter): it wants 3 passes beyond `:far`, 2 beyond `:near`, none inside
  (星: 5 / 2.5 m); short of them it weaves one segment (at most `*weave-seg*` 30 f: each segment is a new decision, so it
  never stands weaving into a rush, and `:opp-rush-hold` still sends the opponent in), else it taps; with a zone live it
  weaves up the next one. K → L (`:l-after-k` 0.3) and SP1 (`:sp-ender`) pick up whatever is stored.
- **Frame data:** weave: press, 10 f to become a weave, then any length; stop 1/0/5. Release (tap): the press (< 10 f), then
  6/0/22, the zone at f6 unfolding 20 f. K → L: 8/0/22, unfold 10. SP1: 8/0/22, releases at f8 and f14, unfold 10.

**The seed gate after it** (seeds 1–20, 2125+k): SY 136.4 s (Senjumaru 12), SK 142.7 (6), SR 189.4 (13), SS 186.8 (P1 8 / P2 12), SI 163.6 (10); 100 / 100 K.O., every median in 125–210 s. **The awaken A/B on this build** (all four changes; P1 Senjumaru "never awaken", debug 39020, vs the opponent on its own rule; seeds 1–60 / 61–120 / 121–180 through 30000+k): SY 27 / 28 / 27, SK 26 / 24 / 32, SR 38 / 38 / 38, SS 34 / 34 / 38, SI 32 / 30 / 33 wins of 60: "never" wins ≥ 24 of 60 on every stream against every opponent (the user's criterion: ≥ 20). No retune was needed.

## J weaves, K releases (the user, 2026-09-29)

「千手丸卍解的綛要至少織出一階才能放出來（唯一例外是 SP1），然後 J 接 L 的話可以直接累積一階織布，整體概念變成通過 J 結尾的連擊快速織布，在將織好的綛混合進 K 連段中。」

- **A release needs a stored pass.** A tap with 0 passes stored, and K → L with 0 stored, are **refused** with the
  `:refused` cue. The tap is refused when it is let go (`weave-release-act`: it becomes the 6 f stop), since a press can
  still become a weave. K → L is refused at the latch by the kit's `:ok` hook (`loom-ok-p`: only a combo copy with `:combo`
  asks for a pass). The latch now gives every refused L link the cue and eats the press, as a refused neutral L always
  did (`refused-cue` takes the link as its `combo`). A tap over a live zone gets the same cue now (it was a silent stop).
  **SP1 is the exception:** it still releases two hanks at 0 passes, at 1 pass each.
- **J → L = 一越 HITOKOSHI** `:sj-hitokoshi`: a new generic key `:l-after-j` (kit.lisp `kit-l-link` / `kit-j-link-p`, the
  twin of `:l-after-k`) latches L after any J link (J1, J2, J2s, J3). The move is the `:sj-weave` clip once: **8/0/10**
  (18 f), and at f8 the shuttle adds **one pass** to the form's hank (`quick-weave`: +20 woven frames, capped at 3
  passes). It never releases.
- **Frame data.** J → L from a J1 / J2 hit: flinch 18 − A 3 − 18 = **−3** (safe against every J, the fastest being 7 f);
  from J3 (stagger 26): **+5**. Blocked (the chain opens 3 f before the link ends): J1 / J2 −2 + 3 − 18 = **−17**, J3
  **−19**: punishable. Tap L (a release): the press (< 10 f), then **6/0/22**, the zone at f6 unfolding 20 f. K → L:
  **8/0/22**, unfold 10, +22 inside a K link's stagger. SP1: 8/0/22, releases at f8 and f14.
- **The void rule does not apply to HITOKOSHI.** It has no bolt: a hit on her before f8 only loses the pass it was
  throwing, and the stored ones stay. The risk is the block punish, not the hank.
- **HUD.** The pass fill already showed the stored level. A refused release now washes the next hank's swatch white and
  outlines the row (landscape and the portrait slot; 0.25 s), and on the one-hand deck the L chip flashes.
- **The CPU.** J links that hit end in L at `:l-after-j` 0.35 per hit (the quick weave). K links that hit end in L at
  `:l-after-k` 0.3 only with a pass stored: the `:ok` hook is asked before the roll. It never taps a release at 0 passes:
  `senju-sig-hold` wants at least one pass, so inside `:near` with nothing stored it weaves one (21 f) instead of tapping.
  SP1 (`:sp-ender`) and the long weave at range are unchanged.
- **A route** (褥's form, 2.2 m, debug 2461 then keys): J1 → L (1 pass), J1 → L (2), J1 → L (3), then K1 → L: 褥 unravels
  at 3 passes under the staggered victim (the probe log: `HITOKOSHI 1 / 2 / 3 passes`, `UNRAVEL hank 4 passes 3 (combo)`);
  a tap or K1 → L before any J → L is refused (`refused L: 0 passes stored`, `refused SIG: kit`); SP1 at 0 passes still
  releases 褥 and 焼野原.

**The seed gate after it** (seeds 1–20, 2125+k): SY 143.9 s (Senjumaru 10), SK 132.9 (6), SR 186.1 (6), SS 197.9 (P1 9 /
P2 11), SI 180.5 (16); 100 / 100 K.O., every median in 125–210 s. The pacing lines: the loom's CPU threw 134 quick weaves
(SR 63, SS 47, SY 16, SI 8), made 36 releases by tap / K → L and 44 SP1 hanks, and **refused 0 releases** (it never taps
at 0). **The awaken A/B** (P1 "never awaken", debug 39020, seeds 1–60 / 61–120 / 121–180 through 30000+k): SY 28 / 28 / 27,
SK 27 / 29 / 25, SR 37 / 38 / 37, SS 40 / 41 / 40, SI 45 / 44 / 43 wins of 60: ≥ 25 everywhere (the criterion: ≥ 20). No
retune. The awakened loom lost ground in SR (Senjumaru 13 → 6 wins in the gate, "never" 38 of 60): with nothing woven it
can no longer throw a free 1-pass zone. If the user wants it back, the levers are `:l-after-j` (more quick weaves) and
the CPU's long weave distances.

## Playtest: the drapes fade near the camera (the user, 2026-09-29)

「千手丸卍解後，如果太接近場邊就會被布幕遮蔽視線。」 The 18 drapes hang on the plaza's rim at r 16.8 m, 4 m tall, but the
camera may stand out to r 18 (`*cam-max-r*`): with a fighter at the arena's edge (r 15) the behind / portrait camera and
the landscape pair camera end up outside the drapes, and a drape filled the frame. Nothing in camera.lisp or stage.lisp
handled occlusion (the stage's wall ring is at 19 m, behind the eye), so the fix is hers, in the look: `sj-domain` measures
every drape's depth along the camera's view (`*cam-eye*` → `*cam-at*`, on the plaza) against the **nearer fighter's**
depth, and `sj-rim-alpha` fades it: opaque from 0.5 m behind him on (the backdrop stays), down to alpha **0.15** at 1.5 m
in front of him (`*sj-drape-fade*` (1.5 2.0 0.15); an alpha below 1 draws in the transparent pass, no depth write). The
torii-loom gets the same fade. It reads the camera each frame, so it holds for the landscape pair camera, the behind /
portrait camera and the cinematics alike, and it only touches drapes between the camera and the fighters (the others are
behind the camera or out of frame). Stills (debug 2481–2484, landscape 1280×720 behind and pair cameras, portrait
390×844; 99600 is the before): the pair at the edge on a tangent (2481) was a wall of cloth, now two ghosted drapes; P1's
back to the rim (2483, portrait) had a drape over her, now she is clear; P2's back to the rim (2484) keeps the drapes
behind him opaque. No sim change.

## The soldier's string, lighter strings, wider weave steps (the user, 2026-10-01)

「始解的 SP1 改成一段神兵的連擊，然後在神兵開始動作前千手丸就結束前搖可以配合神兵一同進攻。始解 L 的傷害從 16 改成 20。所有型態
的 K 傷害變 0.8 倍，J 改為 0.9 倍。提高並增加卍解織物每階段之間的傷害與效果差距。」

**SP1 神兵: one string, and she attacks with it.**
- `:sj-shinpei` is **10/0/10** (was 16/0/22): the tapestry drops at f8, the soldier steps out at f10 and **stands
  `*shinpei-rise*` 10 f**, so it starts to move on f20, the frame she is free. She can walk in behind it, or zone.
- It walks at him as before (3.5 m/s, stops within 2.4 m), then strikes **one string** (`*shinpei-combo*`), then fades:

  | Hit | Wind-up | Clip | Volume | Dmg (×1.6) | React |
  |---|---|---|---|---|---|
  | 1 thrust | 18 f from its stop | `:ru-q1` | line 0.3 → 2.6 | 20 (32) | flinch 22 |
  | 2 sweep | 14 f | `:ru-ring` | arc r 2.8, 160° | 20 (32) | flinch 24 |
  | 3 thrust | 16 f | `:ru-thrust` | line 0.3 → 3.0 | 34 (54) | stagger |

- Each flinch outlasts the next wind-up by ≥ 4 f (host-tested), so **a landed first hit is a true combo** (74 base;
  debug 2452: 3 HITs 118 on Kenpachi); blocked it is a guard string (guard 14 each). Each hit is spawned waiting as its
  wind-up starts (a hazard threat: a Hoho read is perfect), turned at him. It is frail as before: a hit on it also
  cancels the waiting hit.
- `*shinpei-strikes*`, `*shinpei-rest*`, `*shinpei-tell*`, `*shinpei-dmg*` and debug 97200 are gone.

**L 悪い癖: `*hari-dmg*` 10 → 13.** The user asked for 20 after her ×1.6; a hit window's damage is an integer, so 13
(21) it is (12 would be 19).

**Every form's J ×0.9, K ×0.8** (rounded):

| | J1 | J2 | J3 | K1 | K2 | K3 |
|---|---|---|---|---|---|---|
| Shikai | 28 → 25 | 28 → 25 | 36 → 32 | 60 → 48 | 50 → 40 | 74 → 59 |
| Bankai | 25 | 25 | 32 | 56 → 45 (TANMONO-UCHI) | 40 | 72 → 58 (MAKITORI) |

Routes on hit (base): Shikai JJJ 82, JJK 109, JKK 124, KKK 147, KKJ 120, KJJ 105; Bankai JJJ 82, JJK 108, JKK 123,
KKK 143, KKJ 117, KJJ 102.

**The weave's steps: wider, and a stronger top** (`*pass-scale*`; `hank-scale` values four rows, `hank-fx`):

| Passes | 1 | 2 | 3 |
|---|---|---|---|
| radius | ×0.7 (0.8) | ×0.85 (0.9) | ×1.0 (1.0) |
| life | ×0.5 (0.5) | ×0.8 (0.75) | ×1.2 (1.0) |
| damage | ×0.7 (0.8) | ×1.0 (0.9) | ×1.4 (1.0) |
| effect (new) | ×0.6 | ×1.0 | ×1.5 |

- The radius tops at 1.0: every hitting disc's edge stays a Step away (2.0 + 0.45 < 2.5, host-tested).
- What the effect scales: 刃金's guard damage 14 / 24 / 36; 黒砂's drag (the away part of his walk lost) 36 / 60 / 90 %;
  褥's freeze 24 / 40 / 60 f and frost 36 / 60 / 90 f; 焼野原's chip 7 / 12 / 18 %; 星's drain 18 / 30 / 45 Reiatsu/s
  and 9 / 15 / 22.5 flash-step/s; 眼's mirror 18 / 30 / 45 %. 黒砂 still gulps 1 / 2 / 3 times.
- Damage by passes, base (×1.55 in the Bankai): 刃金 63 / 90 / 126; 黒砂 28 / 40 / 56 a gulp; 褥 49 / 70 / 98;
  焼野原 32 / 45 / 63 a hit (×2).
- The 1-pass releases (K → L, SP1 裁ち直し) are now ×0.7: a weave pays more than it did, a quick release less.

**Measurements** (native gate, no knob moved):
- Her five pairings, all K.O.: SY 157.1 s (8–12), SK 151.9 s (17–3) at 20 seeds; SR 185.1 s (23–37), SS 188.3 s,
  SI 206.1 s (30–30) at 60 seeds (SI read 215.3 at 20 seeds).
- Never awaken (`--cmd 39020`, 60 a stream), streams 100 / 300 / 500: SY 24 / 21 / 25, SK 26 / 26 / 23,
  SR 32 / 27 / 22, SS 25 / 30 / 26, SI 39 / 32 / 31: all ≥ 20 (SK and SS were 17–19 before).

## Built: deviations from the design, and why

| Item | Design | Built | Why |
|---|---|---|---|
| Where it lives | senju.lisp / senju-art.lisp, knobs in tuning.lisp, generic gaps N1–N12 in the shared files | `senjumaru.lisp` / `senjumaru-art.lisp` (knobs at the top of `senjumaru.lisp`); every "gap" is her own code behind the generic hook points below | the user's code layout (DUEL_DESIGN "Character code layout"); Ichigo's seven pieces were not depended on |
| Whole-kit damage | ×1.0 dealt / taken both forms | Shikai `*senju-mult*` **1.6** / `*senju-taken*` **0.95**; Bankai `*tsuji-mult*` **1.55** / 1.0 | the first gate: SY 1 / 20, SK 3 / 20, SR 4 / 20 wins and SS 229.6 s (the design's own warning: the lightest strings in the game; `*senju-mult*` was its first knob). Runtime sweeps (80000+ / 82000+) put 1.6 / 1.4 inside the window with even wins; the first 3-stream A/B then had "never" far ahead in SR / SS (Δ −20 … −29), so the Bankai went to 1.55 |
| SP2 as a string cancel | the universal `:sp-cancel-bars` | her CPU never cancels into SP2 (`:sp-cancel-bars 9`) | 傘 is a guard / catch, not an ender: the cancel spent the bar on a whiffing umbrella |
| The Shikai CPU's L | `:sig 1` in the close band + `:hari (:min 4 :hurry 40)` | no L in the bands; her `:reflex` fires L with ≥ 4 stitches at 0.1 per free step (`*ai-senju-hari*`), always with ≥ 2 when the first falls within 40 f; the K → L combo copy 0.3 per K hit | the band pick detonated 1–2 stitches |
| 悪い癖 outside a combo | 60 unscaled | **54**: the six spikes are combo hits 1–6 (the 4th–6th scale ×0.9 / 0.8 / 0.7) | the combo rules are universal; not worth a special case |
| The spikes | spawned from f10 one by one | all spawned on frame 0 as delayed hazards stuck to him (their hook moves them onto him every step) | so they are hazard threats from the start (a Hoho in the yank is perfect, `hazard-threat-p`); they fire even if she is hit after the yank (the needles are already in him) |
| 焼野原 | a speed-0 `:wave` (cuttable) | her own hazard kind `:sj-lane` (a box as long as the lane) | a `:wave` is a 1 m box; the lane needs its length. Consequence: Nozarashi's projectile cut does not cut it (§12 M7 accepted either) |
| 黒砂's drag | `field-velocity` about the pit | the same arithmetic as a position correction in the pit's step (after his walk / run moved him) | no shared-file change; Steps (slides) are untouched as designed |
| Torn during the unfold | the hank lost, L locked | L locked; the form had already advanced at the release, so no second advance | torn during the weave: the hank lost **and** L locked, as designed |
| The combo cut's zones | "刃金 closes without its 16 f rise, 黒砂's first gulp without its swirl" | as designed, and their `:tell` windows moved to the unfold's end | the tell reflex reads them |
| The awakening rule (superseded 2026-09-30: the generic `:awaken (:min-taken 150)`) | Ichigo's `:awaken :ranged-share` + `:or-opp-rooted` | her `:reflex` applies `:awaken-rule (:ranged-share 0.3 :min-taken 150 :or-opp-rooted t)`; the built `:awaken` key is set so it never fires | the debug A/B modes (39000+10a+b: always / never) still decide first |
| The tell reflex "from the release" fix | a change in ai.lisp | none needed | the hank moves' `:tell` counts main-phase frames, which start at the release |
| MAKITORI / the gulps' pull | Ichigo's `:pull` | her `:hit` hook slides him to 1.4 m of her (8 f) / to the pit's centre (10 f) after the reaction | no shared change |
| HUD awakening row | "SHIGARAMI NO TSUJI" | the form name `TSUJI` (the name line reads SENJUMARU  TSUJI) | one form name serves both lines |
| Hoho / Burst cloth double | a look | **not built** | cosmetic; left for the art review |
| Glyphs | `tools/glyph-bake.py` into glyphs.lisp | 49 glyphs baked with the same tool's functions into `glyphs-extra.lisp` (first in `senjumaru-art.lisp`; appended to `*glyph-outlines*` before `brush-init` triangulates them) | keeps the shared generated file out of her branch |
| Stage drapes and the loom | a stage key `:stage :cloth` read by stage.lisp | drawn from her `:draw` hook while she is awakened (18 drapes on the rim, the torii-loom at the rim behind her; the second awakened Senjumaru of a mirror draws none) | no stage change |

**The generic hook points** (the only shared-code changes; inert for every other character, so the old six pairings
replay byte-identically, `style-gates.py cvc`):
- kit.lisp: a kit slot `:hooks` and `kit-hook`: `:tick` (gauge-system, per step; `:step` on her branch), `:ok`
  (kit-command-ok-p and the refused cue; `:cmd-ok` on her branch), `:hit` / `:struck` (the end of apply-hit, for the
  attacker's / defender's kit), `:draw` (draw-fighter), `:deck` (the thumb ring; the meter's `:ring` on her branch).
  The merge with Ichigo (DEVLOG §30) unified these with his hook points: DUEL_DESIGN.md "Character code layout: the
  unified hooks".
- components.lisp / hazards.lisp: the hazard slots `hook` and `data`; `hazard-step` calls the hook first (T skips the
  generic step), `hazard-touches-p` asks it for an unknown kind, `close-rifts` tells it `:close`.
- combat.lisp: the hitwin flags `:spare` (never the last Reishi point) and `:thread` (a hazard hit shown as a blade's); a
  `:shield` move's `:catch` param (a ranged hit blocked in its window: no stun, no gauge, no chip, the catch function
  called).
- fighter.lisp: a `:shield` move's S / A window is a guard (`defender-state`).
- hud.lisp: a kit meter's `:draw` (the landscape row and the portrait slot), `:label` (the portrait label).
- ai.lisp: a kit's `:reflex`, the opponent's kit's `:opp-reflex`, a kit's `:sig-hold` (how long L is held).
- debug.lisp: her gate pairings (SY SK SR SS, and SI since the merge), 2140, the pacing line; her own ranges 2450+k,
  76000–78999 and 90000+ go through `*char-debug*` (SENJU-DEBUG); MANIFEST: her two files.

## Knobs (the top of `duel/lisp/senjumaru.lisp`; runtime: debug 90000+, 80000+ on her branch: ENDLESS has 80000–80999)

| Knob | Value | Debug |
|---|---|---|
| `*senju-mult*` / `*senju-taken*` | 1.6 / 0.95 | 90000+k / 91000+k (×0.01) |
| `*tsuji-mult*` / `*tsuji-taken*` | 1.55 / 1.0 | 92000+k / 93000+k (every hank form) |
| walks: Shikai / Bankai (runs 8.5 / 8.0) | 3.6 / 3.3 | 99300+k (Shikai, ×0.1) / 95500+k (Bankai, ×0.01) |
| `*hari-max*` / `*hari-idle*` / `*hari-fall*` | 6 / 180 / 30 | 98100+k (idle) |
| `*hari-sew-hit*` / `*hari-sew-block*` | 2 / 1 | 99000+k (block) |
| `*hari-dmg*` / `*hari-gap*` / `*hari-stun*` / `*hari-last-stun*` | 10 / 2 / 8 / 18 | 98000+k (damage) |
| soldier: speed / turn / near / tell / dmg / rest / strikes / life | 3.5 / 120 / 2.4 / 18 / 50 / 50 / 2 / 300 | 97200+k (strikes), 97800+k (life ×10) |
| `*kasa-base*` / `*kasa-cap*` | 40 / 120 | 97900+k (base) |
| `*weave-pass*` / `*unfold*` / `*unfold-combo*` / `*torn-lock*` | 20 / 20 / 10 / 90 | 94500+k / 95000+k / — / 94000+k |
| `*hank-range*` / `*hank-life-mult*` / `*mirror-k*` | 9.0 / 1.0 / 0.3 | 96500+k (×0.1) / 96000+k / 97100+k (×0.01) |
| the six hanks (`*hanks*`) | §4.2's values at 3 passes | — |
| SP1's cost (the two-hank release) / its CPU chance | 1 bar / 0.5 | 97000+k (every form's copy) / — |
| AI: `*ai-senju-hari*`, base `:block-string` / `:dash`, the loom's ZONE weight / `:opp-rush-hold`, `:awaken`'s `:min-taken` (2026-09-30), `:sp-cancel-bars` | 0.1, 0.8 / 0.7, 4 / 0.5, 150, 9 | 97700+k, 97500+k / 97600+k, 97300+k / 97400+k, 99200+k (×10), 99400+k |
| the drapes' fade `*sj-drape-fade*` (lead / ramp / floor, senjumaru-art.lisp) | 1.5 m / 2.0 m / 0.15 | 99500+k (the floor ×0.01; 99600 off) |
| A/B mode per side (0 the rule, 1 always, 2 never) | 0 | 39000 + 10a + b |

Other commands: 2125+10 … 2125+14 her gate pairings alone (SY SK SR SS SI; 2125+6 … +9 and 2135 on her branch), 2140 all
five, 2113 all fifteen; 2450+k her tests
(DUEL_GAMEPLAY.md); 76000+f / 77000+f / 78000+f stills of 仕立て直し / 死出六色浮文機 / the awakening.

## Measurements (the final build, fixed-dt turbo, seeds 1–20 per pairing: 2125+k, all ten pairings)

| Pairing | K.O. | Median (s) | Range | Wins |
|---|---|---|---|---|
| YY / YK / KK / RY / RK / RR (refs, unchanged) | 120 / 120 | 134.7 / 136.2 / 131.2 / 134.1 / 144.9 / 185.6 | — | as main |
| **SY** (P1 Senjumaru) | 20 / 20 | **143.2** | 83.9–180.6 | Senjumaru 10, Yamamoto 10 |
| **SK** | 20 / 20 | **144.4** | 97.5–205.3 | Senjumaru 11, Kenpachi 9 |
| **SR** | 20 / 20 | **173.7** | 133.1–239.3 | Senjumaru 14, Rukia 6 |
| **SS** | 20 / 20 | **195.3** | 159.6–220.9 | P1 7, P2 13 |

200 / 200 K.O.; every median in 125–210 s. The six old pairings replay exactly as on main, and the style gates' cvc refs
(YY 154.1, YK 122.8, KK 137.1) are identical. The first gate at the design's ×1.0: SY 142.2 s (Senjumaru 1 / 20), SK 166.4
(3), SR 197.4 (4), SS 229.6 s (outside the window).

**The awaken A/B** (three independent seed streams: seeds 1–60, 61–120, 121–180; P1 Senjumaru in mode 1 "always on
EVOLUTION" / mode 2 "never" vs the opponent on its own rule; P1 wins of 60):

| Pairing | stream 1–60 always / never | 61–120 | 121–180 | never ≥ 20 on every stream |
|---|---|---|---|---|
| SY | 18 / 23 | 22 / 25 | 22 / 27 | yes |
| SK | 22 / 33 | 34 / 22 | 29 / 28 | yes |
| SR | 16 / 38 | 25 / 38 | 17 / 32 | yes |
| SS | 21 / 34 | 14 / 40 | 16 / 39 | yes |

**The gate (the user's relaxed criterion) passes**: "never" wins ≥ 22 of 60 everywhere. Logged, not gated: |Δ| ≤ 9 holds
only for SY (−5 / −3 / −5) and SK stream 3 (+1); SK favours "never" on stream 1 (−11) and "always" on stream 2 (+12), so
the design's "SK favours never" is a coin toss between streams. In SR and SS "never" leads by 13–26: the awakening is the
*weaker* choice there, not the stronger. The Shikai's stitches carry her (in SR the CPU's rule awakens 18 of 20 sides,
against zero Rukia's rooted form; its matches are her slowest). The first stream at `*tsuji-mult*` 1.4 had SR / SS at
Δ −24 / −15 and −20 / −29; 1.55 moved them less than the stream noise. If a later playtest wants the loom closer to even,
the design's "trap" list is the order: `*tsuji-taken*` 1.0 → 0.9, the skip 1 → 0 bars, the torn lock 90 → 60 f.

**Pacing** (the `duel senju` lines of the 20-seed gate, her sides only):

| Pairing | awakened | stitches sewn (hit / block) | fallen | 悪い癖 (free / in a combo) | spike damage | soldiers (killed / hits) | weaves (torn) / skips / combo cuts |
|---|---|---|---|---|---|---|---|
| SY | 3 / 20 | 934 / 196 | 17 | 131 / 46 | 8330 | 19 (9 / 9) | 3 (3) / 1 / 0 |
| SK | 0 / 20 | 1456 / 100 | 12 | 145 / 88 | 12090 | 18 (5 / 20) | 0 |
| SR | 18 / 20 | 955 / 96 | 5 | 99 / 51 | 8120 | 15 (0 / 16) | 28 (12) / 19 / 2 |
| SS (both sides) | 10 / 40 | 2734 / 313 | 25 | 324 / 132 | 23530 | 29 (6 / 25) | 27 (13) / 3 / 1 |

Known: between CPUs the umbrella is almost never opened (0 in the gate): her `:react (:projectile :sp2)` needs his
projectile within 7 m, and the CPUs rarely shoot (Yamamoto's CPU spends his Bankai in East's melee; 29 fire waves in 20
SY matches). 眼's reflections and mirror are likewise rare (0 here; the review probe 2474 shows them). The CPU's rule
awakens against Kenpachi never (as designed) and against Yamamoto rarely (his East is melee).

**Review stills**: `tests/shots/duel-senjumaru-contact.png` (landscape: the Shikai stance, the stitches on him, J3, the
umbrella vs Yamamoto, the soldier's thrust, the loom stance, a weave, the six hanks unfolded, key frames of the three
cinematics; portrait 390×844: the same with the portrait HUD blocks and the close-up cinematic frames).
