# SOUL DUEL: Kurosaki Ichigo (TYBW), dual Zangetsu and 血鎖の一護 KESSA NO ICHIGO

Status: **v2 built 2026-09-29** (the playtest redesign: "Playtest redesign decisions", "v2 decisions" and "v2: built"
at the end of this file, which override everything above them where they differ). v1 was built 2026-09-28: the design
below with the user's decisions of that day ("User decisions"); its as-built values are in "Built: deviations", "Knobs"
and "Measurements". Code layout (the user's rule, DUEL_DESIGN "Character code layout"): everything of his is in
`duel/lisp/ichigo.lisp` and `duel/lisp/ichigo-art.lisp`; the shared files only gained small generic hook points.

## Summary (v2)

- **The Shikai 二刀の斬月 is a close-range rushdown.** The half-Hollow's single flat white horn; the sleeves end just
  past the elbow. J the short blade (J1 7 f, 2.2 m), K the long cleaver; a switched link 2 is the **cross**. **L is the
  stance 月待 TSUKIMACHI** (RoS's Syzygy): from f6, J 乱月 RANGETSU (a lunge, four slashes), K 月落 TSUKI-OTOSHI (a
  pounce, guard 30), L GETSUGA TENSHŌ (at the old L's f14), Step 月渡 TSUKIWATARI (a flash-step dash back into the
  stance). SP1 月牙十字衝 JŪJISHŌ, SP2 双牙 SŌGA, O the flash-step cross JŪJI; its Kikon is **王虚の閃光を込めた月牙天衝**,
  rebuilt from the reference frames (a gold orb on the raised blade, a hooked flame crescent, the red blade in a pink-violet
  glow, a violet ring round a dark blood-red disc: the palette exception is this cinematic's alone).
- **The awakening 血鎖の一護 KESSA NO ICHIGO** follows the figures (barefoot, the hair split black on his left, the left
  half of the face black, two flat white horns, the robe open on a dark red disc, blood coils; a white pointless,
  guardless slab). **U is a normal guard**; **L the parry 鎖盾**, made easy (from blockstun too, the window f2–25, 10 of
  the guard gauge, a white rim light as its timer, a catch staggers 40 f and the counter 残月返し follows); J / K pure cuts;
  **the clones 分身** (a Step leaves one where it took off, a Hoho in front of the opponent; up to 3 for 5 s): **every clone
  answers every J / K press** with J → a heavy, K → a light, 6 f behind, in his combo at ×0.7; **O 影討 KAGE-UCHI** sends
  them all into the strike (+30 each) and its Kikon **千影** is worth **2 / 2 / 3 / 4 Konpaku by the clones at the press**;
  his Soul Break plays **漆黒の月牙天衝** (a huge C-shaped cut hanging in the air); SP2 **残像 ZANZŌ** echoes every attack
  10 f later at half damage for 6 s; SP1 鎖引 KUSARI-BIKI pulls.
- **Balance**: the awakening may be the stronger choice, but "never awaken" must still win ≥ 20 of 60 on each of three
  seed streams against every opponent (measured under "v2: built").

## Summary (v1, 2026-09-28, superseded where v2 differs)

- **The Shikai 二刀の斬月 is a close-range rushdown.** He starts with the half-Hollow's **single horn** (the user's decision).
  J is the short blade (fast and short: J1 7 f, 2.2 m); K is the long cleaver (slower, longer, heavy on the guard gauge). A
  string that switches buttons once (JK…, KJ…) plays the **cross** link, both blades at once, which grinds the gauge
  harder. L is 月牙天衝 GETSUGA TENSHŌ, chainable after a K link. SP1 月牙十字衝 GETSUGA JŪJISHŌ needs both blades and cuts
  projectiles. SP2 is 双牙 SŌGA, a flash-step X cut. O is the flash-step cross JŪJI; its Kikon is **a Getsuga Tenshō infused
  with a Gran Rey Cero** (2 Konpaku; the user's decision).
- **The awakening 血鎖の一護 KESSA NO ICHIGO is mid-range control.** The Bankai overlays the two blades into one, so
  everything two-bladed goes:
  - lost: the held guard, 月牙十字衝, the cross links, SŌGA, and walking speed;
  - gained: the chain J / K (J1 a 3.8 m line, K1 a 4.5 m sweep), U as the chain parry, a clone on every Step, the giant
    Getsuga and its residue, SP1 鎖引 KUSARI-BIKI (pulls him in from 7 m and binds him), SP2 鎖垣 KUSARI-GAKI (a chain wall
    that eats projectiles); O's Kikon is **the anime's giant, pitch-black Getsuga Tenshō** (3 Konpaku; the user's
    decision), which dwarfs the L's crescent.
- **One resource: the blood-chain gauge 血鎖**, the guard gauge re-skinned (no new bar, no HUD overlap). U costs 20 per
  press; a caught melee hit refunds 40 and the chains yank the attacker to 1.8 m (+3, not a combo). A projectile blocked
  in the parry drains its guard value (at 0: GUARD CRUSH). A clone costs 15 and only happens while 20 stays for U; the
  giant Getsuga costs 30.
- **The clone**: a Step leaves a reiatsu afterimage at its take-off point that slashes 20 f later. One at a time; guarded
  facing him (always blockable); gone if he is hit first.
- **Why it is a sidegrade**: the Shikai holds a guard and grinds gauges; KESSA parries, pulls and zones from 3–4.5 m, and
  its chains stop fire and ice. The user's decision (2026-09-28): **the awakening may be the stronger choice, but never
  so strong that not awakening can't win** (the A/B criterion in "Measurements").
- **Cinematics**: the awakening 168 f, the Shikai Kikon 186 f, the KESSA Kikon 192 f; all unskippable, every shot framed
  on its subject with `shot-on`.

---

Design basis (as written, 2026-09-28). It rests on the user's decisions of 2026-09-27 / 28: the research report
`reports/血戰篇四角色格鬥設計研究.md` (its Ichigo section, the six sidegrade rules; questions 1–5 and 7–11 at their defaults, so Q8
**in-game name KESSA NO ICHIGO; 血鎖斬月 only as a move name, flagged as ours**, and Q9 **Kessa has no hold-guard, U is a chain
parry; if it proves too weak in play, fall back to a normal guard with guard value ×1.3**; question 6 overruled: an
awakened Kikon still takes 3), the Soul Break rule (count + 1, cap 5, the attacker's current Kikon cinematic), unskippable
battle cinematics, and the brief: awakened and base must differ in playstyle and not in power. Numbers are proposals; the
seed gate and the A/B decide them. Structure and depth follow `docs/DUEL_RUKIA.md`.

---

## 0. Frame of reference

- Conventions: DUEL_DESIGN §0 (60 Hz, S/A/R, move frame 0 = first frame). Every J/K form obeys the DUEL_STRINGS §2.1 budget,
  host-tested per form. Callouts use TYBW-register romaji; the brush columns use kanji.
- Canon marks: **[V]** manga canon (verified in `research_notes/血戰篇四角色格鬥設計研究/ichigo_tybw.md`), **[A]**
  anime-only (TYBW ep. 45 「DEFEND YOU」, 2026-08-22, form designed and named by Kubo), **[U]** unverified (search snippet
  only), **[G]** our game interpretation or an invented name. §13 is the full ledger.
- The canon beats this design encodes, each written as the opponent's counterplay verb (sidegrade_design Q3):

| Canon | Mechanic | The opponent's verb |
|---|---|---|
| The true Zangetsu is **two blades**, long and short [V] | base J = short blade (fast, short), K = long blade (slow, long, heavy on the gauge); a switched link is a **cross** that uses both blades | step the K links; J1 beats his K1 (7 f vs 16 f) |
| 月牙十字衝 is two Getsuga fused, and it dispersed a defensive barrier [V] | base SP1: a cross wave that **cuts projectiles** it meets | don't trade projectiles with it; side-Step it (half-width 1.8) |
| Bankai = **the two blades overlaid into one** [V] | Kessa has one blade: no cross links, no Jūjishō, no SŌGA | — (it is the price) |
| 血鎖 chains **block attacks** [A] | U = a 12 f, 360° chain parry; a projectile in it is blocked | bait it: J pressure (7 f can't be reacted to), delays, the Breaker; a whiff costs 20 and 24 f |
| chains **control the field** [A] | the catch yanks the attacker to 1.8 m; SP1 pulls from 7 m and binds; SP2 is a chain wall | side-Step the thin pull line; walk round the wall |
| **reiatsu clones** [A] | a Step leaves an afterimage that slashes 20 f later | don't chase through the afterimage; hit him first (it vanishes) |
| an **enormous Getsuga** [A] that leaves a **crescent afterimage** [A, fan note] | L: a 4 m crescent, then a 1.5 s residue at its end | side-Step it (half-width 2.0); don't retreat through the residue |
| the form **still loses to the Almighty** [A] | it is a new way to fight, not a power-up (sidegrade) | — |

- The six sidegrade rules (report §「跨角色原則」), and where each is met:
  1. **Kikon count.** The awakened count stays 3 (the user's decision); the design offsets it: Kessa's strings deal about −10 %, he has no hold-guard, and the A/B's knobs are in §9.
  2. **Named removals.** Kessa loses hold-guard, 月牙十字衝, the cross links, 双牙 SŌGA and walking speed (§4.8).
  3. **No heal.** The awakening restores nothing.
  4. **Active cheap, forced expensive.** Catch vs whiff: +40 vs −20. Running his own gauge empty (U refused until 20) vs a GUARD CRUSH (guardless until full).
  5. **The choice happens mid-match.** P is manual; the CPU follows a rule (§7.1).
  6. **The Fighting Spirit gauge** is unchanged.

---

## 1. Summary

At the top of this file. The player-facing text is in docs/TUTORIAL.zh-TW.md (§9.2).

---

## 2. Identity and silhouette

**Who.** Kurosaki Ichigo in the Thousand-Year Blood War, after Nimaiya's reforging: a substitute Shinigami in a black
shihakushō, with no haori and no rank badge [V; verify the collar and sash cut against the TYBW ep. 13+ model sheet]. He
has short spiky **orange** hair, the scowl, and brown eyes.

**Weapons (base).** Two blades, **二刀一対** [V]:
- `:zangetsu-long` in the right hand: a large cleaver shaped like the old Shikai, **with a hole between the hilt and the
  blade**, and a short cloth-wrapped hilt. Blade ~1.35 m.
- `:zangetsu-short` in the left hand: **hiltless, shaped like a stone knife (石包丁)** [V], ~0.55 m, held reversed along the
  forearm.
- Which blade is "Quincy" and which "Hollow" is **not** stated by any source. The design never says so, not even in a
  callout.
- Engine gap 1 (§10): a second held weapon in the skeleton's existing `:weapon-l` joint.

**Weapon (Kessa).** `:tensa`, one blade made by overlaying the two [V: "2対の斬月を重ね合わせて"]. Its look follows the
manga's true Tensa Zangetsu: a white blade with a thick black line from mid-blade to the hilt [V]. The anime's Kessa blade
"differs" [U]; stills review decides.

**Blood chains.** In play they are an fx, not geometry: ink links with a BLOOD core, a ribbon along a polyline, reusing the
sword-trail / ribbon machinery. They are drawn from the neck, both wrists and both ankles (the official art [A]), and along
the chain moves' hit volumes during their active frames. That is what lets the Kessa K links reuse the base clips (§10).

**Proportions.** Canon ~181 cm [V wiki height, verify]. `:scale 1.0 :width 0.96 :hunch 0`. Hurt cylinder **r 0.38 /
h 1.80** (Yamamoto 0.36 / 1.65, Kenpachi 0.45 / 2.0, Rukia 0.34 / 1.50). **Anime head** (the user's Rukia decision):
`(:head 1.2 1.2 1.2)` in `:girth`, about 7.4 heads. That is less than Rukia's ×1.3 because Kubo draws the male lead long,
and it is a knob that the stills review decides (Q5).

**Palette** (v4 notan, STYLE_STORM §A.1, §2.5):

| Key | Lit | Note |
|---|---|---|
| `:black` | #16161E | the shihakushō, one solid black mass, cold-grey keyline |
| `:hair` | #B8733E | **muted orange (S ≤ 0.45: not a spot hue**, like Kenpachi's crimson skin), two lighter strokes #D89A66; the only warm head on the plaza |
| `:skin` | #D8B8A0 | muted |
| `:white` | #ECECE8 | under-collar, tabi |
| blades | long: ink #101014 with a steel-white edge #C8CCD4; short: ink with a white edge | mono: the blades read as black silhouettes |
| Getsuga | an **ink crescent with a white rim** | mono. The TYBW anime colours it blue-black [U]; we keep the house notan, so **no new spot hue** |
| Kessa chains / crescent rim / horns' keyline | BLOOD core in ink | BLOOD is universal. §12 M1 covers how it stays apart from the Kikon tell |

**How he reads against the other three.** Yamamoto is a hunched white haori with FIRE. Kenpachi is 2 m, a white
sleeveless haori and yellow. Rukia is small, all black, one white line. **Ichigo is tall, lean and black, with an orange
head and an asymmetric X of two black blades** (a big cleaver right, a small knife left). **Kessa** is one long black and
white blade, two horns, and red chains trailing from the neck, wrists and ankles.

**Form looks:**

| Form | Look |
|---|---|
| base | both blades, the stance `:ic-stance` (long blade low and back, short blade reversed across the chest); no aura |
| Kessa `:ichigo-kessa` (body variant) | **two horns** from the hairline and **no mask** [A]; the left half of the face keeps a faint white Hollow marking [V: manga half-Hollow, left side]; the blood chains (above); aura `ichigo-aura-kessa`: short BLOOD chain wisps at the neck, wrists and ankles, a smoulder, never a pillar (§12 M1); the single `:tensa`; stance `:ic-k-stance` (upright, blade low, chains hanging) |
| Kessa clone | the same body at alpha 0.45, a BLOOD rim light, no chains, fading over 8 f after its slash |

---

## 3. Base kit: 二刀の斬月 (form `:base`)

Identity: **close-to-mid rushdown with a two-blade rhythm**. He wins by getting in and grinding the guard gauge. J is
the short blade, K is the long one, and switching hands in a string brings both blades in.
- Walk **4.2 m/s**, run **10.0 m/s** (`*walk-ichigo*`, `*run-ichigo*`; Kenpachi's are 4.4 / 10).
- Kikon **2**, Soul Break 3. Damage ×1.0 dealt and taken (`*ichigo-mult*`, `*ichigo-taken*`).
- U is the universal guard (200°, the gauge, GUARD HOLD).

### 3.1 The dual-blade identity: the cross links

DUEL_STRINGS makes the switched link 2 a copy (`J2s` after K1, `K2s` after J1). For Ichigo these copies are **the cross**:
the link where both blades strike together. They are pure data (`defmove-copy` with override keys), with no engine change
and one new clip (`:ic-cross`), shared by both copies at different speeds.
- **K2s 交牙 KŌGA** [G], after J1: the long blade and the short blade cross in an X. It has the frames and damage of K2 but
  **guard 24** (K2: 16).
- **J2s 返牙 KAESHI-KIBA** [G], after K1: the short blade snaps under the long one's return. It has J2's frames but
  **guard 12** (J2: 8).

So the routes that switch at link 2 (JK…, KJ…) are the ones that grind the gauge. A blocked **J-KŌGA-K3 drains 8 + 24 +
22 = 54**, the same as KKK, from a string that starts with a 7 f J1.

### 3.2 J / K grid (DUEL_STRINGS §2.1; K2 / K3 at 80 % as for every form)

| Link | Name | Clip | S/A/R (enter → S_eff) | Dmg | React | Blk | Whiff | Volume | Guard | Pose (one line) |
|---|---|---|---|---|---|---|---|---|---|---|
| J1 | 小牙 KOKIBA `:ic-j1` [G] | **new** `:ic-q1` | 7/3/12 | 32 | flinch | −2 | 20 | 2.2 m 100°, slide 0.6 | 8 | the short blade flicked from the reverse grip, stepping in |
| J2 | 返し KAESHI `:ic-j2` [G] | **new** `:ic-q2` | 7/3/13 | 32 | flinch | −2 | 21 | 2.2 m 100° | 8 | the wrist turns, the short blade back across |
| J3 | 双旋 SŌSEN-GIRI `:ic-j3` (ender) [G] | **new** `:ic-spin` | 8/3/18 | 40 | stagger | −4 | 26 | 2.4 m 200° | 8 | a full turn with both blades out, long high and short low |
| K1 | 大牙 ŌKIBA `:ic-k1` [G] | **new** `:ic-f1` | 16/4/20 | 68 | stagger | −3 | 32 | 3.0 m 150° | 16 | the long cleaver drawn back past the hip, a waist-high sweep |
| K2 | 昇牙 SHŌGA `:ic-k2` [G] | **new** `:ic-f2` | 20/4/24 (6 → 14) | 60 | stagger | −3 | 36 | 3.0 m 90° | 16 | from the floor up, the cleaver's hole whistling; 4 f hold at the top |
| K3 | 落牙 RAKUGA `:ic-k3` (ender) [G] | **new** `:ic-drop` | 21/5/34 (7 → 14) | 84 | crumple | −20 | 46 | line 0.3 → 3.4, h 1.2 | 22 | both hands on the long blade, held 3 f, dropped |
| J2s | 返牙 KAESHI-KIBA `:ic-j2s` | `:ic-cross` (clip-s 7) | as J2 | 32 | flinch | −2 | 21 | 2.2 m 100° | **12** | the short blade under the long one's return |
| K2s | 交牙 KŌGA `:ic-k2s` | `:ic-cross` | as K2 | 60 | stagger | −3 | 36 | 2.8 m 110° | **24** | both blades cross in an X from high to low |

**Budget check:**
- Startups: J1 7, J2 7, J3 8 (limits 7–10 / 7–9 / 8–10). K1 16 (limit 16–20; K1 − J1 = 9 ≥ 7). K2 / K3 enter at S_eff 14.
- R and block advantage are exactly the budget's.
- K2 / K3 combo after a J (A 3 + 14 = 17 ≤ 17) and after a K (≤ 21).

**Routes on hit:** JJJ 104, JJK 148, **J-KŌGA-K3 176**, **KKK 212**, KKJ 168, K-KAESHI-J3 140; the O ender adds 63.
Kenpachi's base: 112 / 150 / 175 / 210 / 172 / 147.

**Blocked:** JJJ 24, KKK 16 + 16 + 22 = **54**, J-KŌGA-K3 **54**, K-KAESHI-J3 16 + 12 + 8 = 36. The universal numbers
are 24 / 46; he is the gauge-pressure character.

### 3.3 The rest of the buttons

| Input | Move | S / A / R | Dmg | Block | Notes | Pose |
|---|---|---|---|---|---|---|
| L | **月牙天衝 GETSUGA TENSHŌ** `:ic-getsuga` [V] | 14/0/24 (38 f; hazard only) | 90 | guard 18, fixed 14 f blockstun | **What it does:** at f14 a `:wave` leaves the long blade: an ink crescent, width 2.4 m (half 1.2: a side Step always clears it), 16 m/s over 10 m (38 f), knockback 2.5, no chip. Cooldown 100 f.<br>**After a K link** (the kit's `:l-after-k :ic-getsuga-k`, DUEL_STRINGS §12, Rukia's combo-copy precedent): the copy is **S10**, the same wave and cooldown. From a K1 / K2 hit at ~3 m it lands at A 4 + 10 + ~8 f of travel (2 m at 16 m/s) = 22 < stagger 26; the plain L at S14 would be 26, not a combo. On block it is blockable pressure.<br>**Hazard rules:** pays no KŌSEI | the long blade swung up and out one-handed, the crescent peeling off the edge |
| Shift+K | SP1 **月牙十字衝 GETSUGA JŪJISHŌ** `:ic-juji` [V] | 20/0/26 | 150 | guard 22 | **Frames:** the long blade's crescent forms at f12 and the short blade's at f20; they fuse into **one cross** `:wave`. **The wave:** width 3.6 (half 1.8: a side Step clears it), 14 m/s, 12 m, knockdown. **It cuts** (hazard flag `:cuts`, engine gap 9): every opponent `:wave` / `:fireball` it touches is destroyed (Yamamoto's Signature wave and Shiranui, Rukia's HAKUREN); ground discs (`:bind`, `:freeze`) are not (the Rukia rule: a blade can't cut the ground). 1 bar | both blades drawn back crossed, then swung out one after the other; the two crescents meet into an X |
| Shift+L | SP2 **双牙 SŌGA** `:ic-soga` [G] | 18/4/26 | 130 | −14 | **What it does:** a flash-step lunge (slide 5.0 m over the startup, TENCHI's afterimages, `:hoho-out`), then an X cut with both blades: arc 2.6 m 140°, knockback 2.5, **guard 30**.<br>**Role:** his approach and whiff punish, and the heaviest single drain on a guard; −14 is punishable by J1. 1 bar | vanish, reappear mid-stride, both blades crossing |
| I | Breaker **峰打ち MINEUCHI** `:ic-breaker` [G] | §4 (universal) | 150 | Guard Break | the universal Breaker (aura 12, the dash, strike 8/4/18, reach 2.6); the strike is the flat of the long blade | dash low, both blades trailing; the cleaver's flat slams sideways |
| O | Kikon module **十字 JŪJI** `:ic-kikon` → Kikon **月牙十字衝** | aura 6, **flash step 30 m/s ≤ 14 f** (locked), strike 7/3/24 | 70 | −14 | **Reach:** 1.6 + 7.0 = **8.6 m**, ≤ 27 f from the press; the strike is the `:ic-cross` X, **2.6 m 140°**; knockback 2.5; cooldown 90; the flash-step look.<br>**As the O ender** (off J3 at 2.4 m): 0.8 m of dash (2 f) + S7 = 9 f < stagger 26 | a vanish, then the X |
| U | guard | | | | universal | |
| P | awaken (§6) | | | | EVOLUTION, from idle / walk / guard | |

Canon notes:
- **月牙天衝, 月牙十字衝 and the two blades** are manga canon [V].
- **SŌGA** is ours. RoS's SP1 is a "quick, rushing slash" (Sōgetsu Ranbu, kanji unverified); we don't reuse RoS's name.
- **Half-Hollowfication** [V] is not a base button. It appears only as the first beat of the awakening cinematic (§6).
- **Invented names [G]:** KOKIBA, KAESHI, SŌSEN-GIRI, ŌKIBA, SHŌGA, RAKUGA, KAESHI-KIBA, KŌGA, SŌGA, MINEUCHI, JŪJI (the
  module).

### 3.4 What the base kit plays like

- **2–3 m:** J1 (7 f) and J strings; J → KŌGA → K3 into a guard grinds 54. K links are for hit confirms and for the
  gauge.
- **3–6 m:** GETSUGA as a poke and after K links; SŌGA (5 m lunge) to enter or punish.
- **6–10 m:** JŪJISHŌ answers a zoner's projectile (it cuts them and keeps going); the 8.6 m JŪJI rush.
- **He has no zoning and no trap.** Against a patient zoner he runs in through waves. Against a brawler he holds guard and
  trades J's. The awakening flips exactly that.

---

## 4. The awakened kit: 血鎖の一護 KESSA NO ICHIGO (form `:kessa`) [A]

Half-Hollowfied, then Bankai: the two blades become one, and blood-chain reiatsu bursts from his neck, hands and feet [A,
official description]. It is **permanent**, like every awakening, with **no heal** (`:heal 0`).
- Kikon **3** (the universal awakened count), Soul Break 4.
- Damage ×1.0 dealt and taken (`*kessa-mult*`, `*kessa-taken*`); the A/B tunes them.
- Walk **3.6**, run **9.0** (`*walk-kessa*`, `*run-kessa*`): he holds ground at chain range.
- HUD form name "KESSA"; the awakening row reads KESSA NO ICHIGO; U tag `U: CHAIN`.

Identity: **mid-range control at 3–4.5 m**. Chains reach where every J in the game doesn't. He has no guard to hold: he
parries, steps and leaves clones, and places one big crescent.

### 4.1 The one resource: the blood-chain gauge 血鎖 (the guard gauge, re-skinned)

Kessa has no hold-guard, so the universal guard gauge would be a dead bar. In Kessa **it becomes the blood-chain gauge**
(血鎖の霊圧: the chains and the clones are the same reiatsu [A]). It uses the same slot, number and refill; only the use
differs.

| Rule | Value (knob) |
|---|---|
| Gauge | the fighter's guard gauge (0–100, `gauges-gg`), full at the start and at every Kikon reset, kept at the awakening (universal rules) |
| Refill | universal: 5.5/s once 60 f pass without a drain. His own spends **count as drains** (the delay restarts); GUARD HOLD never applies (he never guards) |
| **U (the chain parry, §4.2)** | **20 on frame 0** (`*chain-u-cost*`); refused below 20 or while guardless |
| **A catch** (a melee hit in the parry window) | **+40** (`*chain-catch*`, cap 100; the delay counter zeroed). Net +20: the active verb pays |
| A projectile / hazard / ranged hit blocked in the window | drains **its guard value** like any block (a hazard 12, JŪJISHŌ 22 …), with chip as for a guard (fire 12 %). At 0 it is a **GUARD CRUSH**: 40 f reel, then **guardless until full** (the universal 1 s + 15.4 s): no U. This is the forced exit |
| **A clone** (every Step, §4.3) | **15** (`*clone-cost*`), made only when the gauge is ≥ 15 + 20 (`*clone-reserve*`: an automatic spend never eats the parry's money); otherwise a plain Step, free |
| **L** (the giant Getsuga, §4.5) | **30** (`*kessa-l-cost*`), refused below 30. No cooldown: the gauge is its only limiter |
| A Breaker on the parry | a stance break (crumple 40 f, `resolve-contact` as for GOKUI GAESHI); no drain |
| Emptied by his own spending | U refused until 20 (≈ 1 s + 3.6 s): cheap. Crushed by a block: guardless until full: expensive (rule 4) |
| KŌSEI | unchanged, and its m reads this gauge: **spending chains raises his KŌSEI** (m ×1 full … ×3 empty). Blocked hits never drain it, so the only ways down are his own choices and a blocked projectile. The universal rule gives the synergy with no new code |
| The opponent's CPU | already reads a low guard gauge as "press him" (`ai-guard-mult`, PRESSURE +3 under half): for Kessa that is correct, since he can't parry |

Why re-skin rather than add a meter:
- **One clear resource per form, no HUD overlap** (the user's playtest rule).
- The guard bar is the only bar Kessa would otherwise leave dead.
- KŌSEI, the AI's gauge reads, the reset refills and guardless all carry over with no new code.

### 4.2 U: 鎖盾 KUSARI-TATE, the chain parry [A: "chains block attacks"; G: the name and frames]

`:ic-k-parry`, kit key `:u-move` (engine gap 2): U pressed (the press edge; holding does nothing more) from a free state
(idle, walk, run) starts it. It is not a cancel of a move's startup or recovery (the rework's rule for West's U).

| | Value |
|---|---|
| Frames | **S2 A12 R24** (38 f). The window is **f2–13**, the move's own S / A (engine gap 4: `parry-frame-p` reads the move, so GOKUI GAESHI's 4–15 is unchanged). **360°**: chains from every limb, and the `:parry` state has no arc |
| Cost | 20 chain on frame 0, hit or whiff |
| **Catch** (a guardable melee hit, including a Kikon rush strike or a non-red dash-in) | **What happens:** no damage; the attacker **staggers `*parry-stun*` 32 f** (his move and rush armour end, `respect` fires); chain +40; then the counter.<br>**The counter** (the `:land` string, GOKUI GAESHI's plumbing) is 引鎖 **HIKI-GUSARI** `:ic-k-yank`: S6 A3 R20, 40 damage, a 360° disc of 4.6 m, **pull to 1.8 m** (engine gap 6), stagger 26.<br>**Frames:** it lands at f6 inside the 32 f stagger, so the victim is free at f32 and Ichigo at f29: **+3**. That is a favourable start, **not a guaranteed combo** (his J1 is 10 f; report risk 2). It pays KŌSEI (his own window); the catch doesn't |
| **Block** (a hazard, a `:ranged` window, beyond a `:melee-range`) | blocked from any side, **no blockstun** (the ward rule: he finishes his recovery), drains its guard value, chip as for a guard. Engine gap 5, the `:parry-block` passive |
| Goes through | unguardables (South's bind, a red victim's dash-in, Kenpachi's bite), a Breaker (stance break) |
| Whiff | 24 f of recovery, no guard, 20 chain gone |
| The opponent's verb | J pressure (7–10 f: nobody reacts to it), a delayed K, the Breaker, projectiles when his chains are low (a crush) |

**The dash-in rule.** A non-red Kikon dash-in "lands 12 f after he can act again". A U pressed on the stagger's last
frames buffers into f0, so the window f2–13 covers the arrival: **a well-timed Kessa catches a follow-up** (the base
form only blocks it, −14). A mistimed one eats a 3-Konpaku Kikon. The HUD's "KIKON / GUARD IT!" still applies (it means
"press U").

### 4.3 Step: 分身 BUNSHIN, the reiatsu clone [A: "multiple copies of himself through his reiatsu"]

`:step-hook ichigo-clone` (engine gap 7), hazard kind `:clone` (engine gap 8).

| | Value |
|---|---|
| When | a Step's frame 0 (a tap or the hop of a dash; **not** a Hoho) while the gauge is ≥ 35 and **no clone of his is alive** |
| Where | his take-off point, facing the opponent's position at that frame (fixed: moving off the line beats it) |
| Tell | the afterimage stands there glowing (alpha 0.45, BLOOD rim) for **20 f** (`*clone-delay*`) |
| Slash | at f20: a `:rift`-style hit whose volume is in the clone's frame, **arc 2.4 m 140°, h 0.2–2.0**, **40** damage (`*clone-dmg*`), **flinch**, guard 8. It plays `:ic-k-lash` (reused) and fades over 8 f |
| Guarding it | `:src` = Ichigo's position: **a guard facing him blocks it wherever it stands** (report risk 1: no front / back unblockable). His own parry doesn't apply to it (it's his) |
| Fragile | it **vanishes if Ichigo is really hit before f20** (`close-rifts` generalised) |
| Rules | a hazard: **no contact** (no string, no cancel), **no KŌSEI**; one at a time; cleared at every reset (`clear-hazards`, as built). A perfect Hoho through it counts (`hazard-threat-p`); Rukia's zero ward lets it through (optic) |
| Frame math | his Step is 24 f, so he is free 4 f after the slash; the victim flinches 18, which is **+14**, and his J1 (10 f) combos. A clone hit converts into a J string. That is the reward for making the opponent chase into the afterimage; it costs 15 and a visible 20 f tell |

It makes the back-Step, his most common spacing move, a trap for the chaser, and a side-Step leaves a post in the lane.

### 4.4 The Kessa J / K: 天鎖 and the chains (DUEL_STRINGS §2.1)

One blade plus the chain extension. They reach farther than any other J / K, deal about 10 % less, and put little on the
guard gauge. The chain look is an fx along each window's volume (§2), so the K links reuse the base long-blade clips.

| Link | Name | Clip | S/A/R (enter → S_eff) | Dmg | React | Blk | Whiff | Volume | Guard | Pose |
|---|---|---|---|---|---|---|---|---|---|---|
| J1 | 鎖突 KUSARI-ZUKI `:ic-k-j1` [G] | **new** `:ic-k-thrust` | **10**/3/12 | 30 | flinch | −2 | 20 | **line 0.3 → 3.8 m** | 6 | a one-handed thrust, the chain paying out past the point |
| J2 | 鎖薙 KUSARI-NAGI `:ic-k-j2` / `-j2s` [G] | **new** `:ic-k-lash` | 9/3/13 | 30 | flinch | −2 | 21 | 3.4 m 120° | 6 | the chain whipped back across from the wrist |
| J3 | 鎖巻 KUSARI-MAKI `:ic-k-j3` (ender) [G] | **new** `:ic-k-wrap` | 10/3/18 | 38 | stagger | −4 | 26 | 3.6 m 200° | 6 | a turn, the chain wrapping round him |
| K1 | 鎖払 KUSARI-BARAI `:ic-k-k1` [G] | `:ic-f1` (clip-s 16) | **20**/4/20 | 60 | stagger | −3 | 32 | **4.5 m 160°** | 10 | the long sweep, the chain trailing the blade |
| K2 | 鎖旋 KUSARI-SEN `:ic-k-k2` / `-k2s` [G] | `:ic-f2` (clip-s 20) | 22/4/24 (8 → 14) | 56 | stagger | −3 | 36 | 4.0 m 120° | 10 | the rising cut, chains spiralling up |
| K3 | 天鎖落 TENSA-OTOSHI `:ic-k-k3` (ender) [G] | `:ic-drop` (clip-s 21) | 22/5/34 (8 → 14) | 76 | crumple | −20 | 46 | line 0.3 → 4.2, h 1.2 | 14 | the single blade dropped, chains lashing down either side |

- **Budget:** J1 10, J2 9, J3 10 (at the top of 7–10 / 7–9 / 8–10: long reach is paid in startup). K1 20 (K1 − J1 = 10
  ≥ 7). K2 / K3 at S 22, entering at f8 (S_eff 14).
- **Block gap:** K2 → J3 gives S_eff − 1 − 3 + 3 = 9 ≤ his J1 10 (the DUEL_STRINGS §9 row 6 test).
- **The switched copies are plain copies:** **no cross links** (one blade, rule 2).
- **Routes on hit:** JJJ 98, JJK 136, JKK 162, KKK 192, KKJ 154, KJJ 128 (base: 104 / 148 / 176 / 212 / 168 / 140);
  + the O ender.
- **Blocked:** JJJ 18, KKK 10 + 10 + 14 = **34** (base 54): chains don't grind guards.
- **Reach, the point of the form:** J1's 3.8 m line at 10 f against Kenpachi's 2.6 + 0.8 lunge, Yamamoto's 2.4 (East
  3.1) and Rukia's 2.4. It loses to every J1 inside 2.5 m.

### 4.5 The rest of the Kessa buttons

| Input | Move | S / A / R | Dmg | Block | Notes | Pose |
|---|---|---|---|---|---|---|
| L | **月牙天衝 GETSUGA TENSHŌ** (the giant one) `:ic-k-getsuga` [A: "enormous Getsuga"] | 18/0/26 (44 f) | 110 | guard 20 | **Cost:** 30 chain, no cooldown.<br>**The wave:** at f18 a `:wave` **4.0 m wide** (half 2.0: + Kenpachi's 0.45 = 2.45 < the 2.5 m Step), 12 m/s over 8 m (40 f), knockdown.<br>**The residue 残月 ZANGETSU** [G name; A: "a giant crescent afterimage"]: at the wave's end a **stationary crescent** (a speed-0 `:wave`, delay 40, **life 90 f = 1.5 s**) stays in the air, 4.0 m wide: 50, stagger, guard 12, one hit. **One residue at a time** (a new one removes the old).<br>**Hazard rules:** neither pays KŌSEI; both are cleared at resets.<br>**After a K link** (`:l-after-k :ic-k-getsuga-k`): a combo copy, S10 and 18 m/s (from K1's hit at 4 m: A 4 + 10 + ~10 f of travel = 24 < 26), the same cost | both hands on the one blade, a huge swing from behind the head; a BLOOD-rimmed ink crescent |
| Shift+K | SP1 **鎖引 KUSARI-BIKI** `:ic-k-hiki` [G; A: "control the battlefield"] | 16/3/24 | 40 | −14 | **The line:** a chain shot along a **thin line 0.5 → 7.0 m** (r 0.3: any side Step clears it), `:ranged` beyond `:melee-range 3.8`: within 3.8 m it is the blade, beyond it the chain (the Meteor rule, so West's parry and Rukia's zero treat the far part as ranged).<br>**On hit:** **pulled to 1.6 m** (`:pull`) and **bound 40 f** (the `:bind` reaction, `:sh-bound`; it books 2 combo hits, so Burst is legal).<br>**Frames:** the victim is free at f56 and Ichigo at f43: **+13**, so his J string combos (J1 at f53) and a K doesn't. 1 bar. The CPU uses it through `:stun-follow` (§7.2) | the chain thrown from the left hand, then a two-handed heave |
| Shift+L | SP2 **鎖垣 KUSARI-GAKI** `:ic-k-wall` [G; A: "block attacks"] | 16/0/24 | 50 | guard 12 | **The wall:** at f16 chains erupt in a line **3.0 m ahead, 5.0 m wide**: a speed-0 `:wave`, **life 120 f**, one hit (50, stagger).<br>**It cuts:** it destroys every opponent `:wave` / `:fireball` that touches it (`:cuts`, engine gap 9). One wall at a time.<br>**What it covers:** the anti-zoner screen; it doesn't block melee, and walking round it takes 2.5 m to either side. 2 bars (awakened SP2) | the blade planted, chains ripping up out of the plaza in a fence |
| I | Breaker (the base one, as written) | §4 | 150 | Guard Break | not derived: a derived strike must out-reach its 2.2 m trigger (Kenpachi's §10 B2 lesson) | |
| O | Kikon module **血鎖 KESSA** `:ic-k-kikon` → Kikon **血鎖斬月 KESSA ZANGETSU** [G, **our coinage**] | aura 6, no dash, strike 16/3/30, locked | 70 | −14 | **The lane:** ENJO's module shape; a chain shoots along a locked lane `:cap 0.5 → 8.0 h 1.2 r 1.0`, knockback 2.0; cooldown 90.<br>**The follow-up:** a straight dash (`:follow-speed 14`).<br>**As the O ender:** S16 < J3's stagger 26 | the chain flung straight out |
| U | 鎖盾 KUSARI-TATE (§4.2) | | | | | chains flare from the neck, wrists and ankles |
| Step | the clone (§4.3) | | | | | |

The awakened SP2 costs 2 bars (the universal rule); SP1 costs 1.

### 4.6 Fairness rules (every placed thing)

- **Tells:**
  - the clone stands 20 f;
  - the residue is visible for its whole life;
  - the wall takes 16 f to rise;
  - the pull is a straight line from his hand.
- **Bounded lives:** 20 f (clone), 90 f (residue), 120 f (wall).
- **Bounded counts:** at most **one clone, one residue and one wall** at a time (the hooks remove the older one); the
  gauge (clone, residue) and bars (wall) limit how often.
- **A Step beats every one of them:** the pull by width, the giant crescent by half-width 2.0, the clone by leaving its
  arc, the wall by going round.
- **Rewards:** hazards pay no KŌSEI; every hazard's guard value is 8–20, so there is no crush from range.
- **Resets:** `clear-hazards` at every reset (built), so there is no setplay from before a reset.

### 4.7 A deeper commitment pays more (the user's Rukia rule)

- **The giant L (30 chain):** 110 + the residue, against the base L's free 90.
- **The catch:** +40 chain and a +3 yank, against the whiff's −20 and 24 f.
- **The pull (1 bar):** a guaranteed J string.
- **The awakening itself** (giving up the guard for good): the 3-Konpaku Kikon.

Nothing the form pays for is weaker than the free version it replaces.

### 4.8 Removed base tools (sidegrade rule 2, named)

- **Hold-guard (U)** → the chain parry.
- **月牙十字衝 GETSUGA JŪJISHŌ** (it needs both blades) and its projectile cut on SP1.
- **The cross links 返牙 / 交牙** (one blade).
- **双牙 SŌGA** (the X lunge).
- **Speed:** walk 4.2 → 3.6, run 10 → 9.

Gained:
- the chain reach (J1 3.8 m, K1 4.5 m);
- the parry, the yank and the pull;
- the clone;
- the giant crescent and its residue;
- the chain wall;
- the 3-Konpaku Kikon.

### 4.9 Why it is a sidegrade

| Matchup | Base is better | Kessa is better |
|---|---|---|
| **vs Kenpachi** (every form) | **hold-guard** against his fast J strings and the flurry; J1 7 f trades with his 7 f; 54-drain strings into a fighter whose own gauge matters | his K links (16–21 f) are parryable, and the yank punishes. But his J's (7 f) and Nozarashi's reach (J1 3.4–3.9 m) erase the chain range, and Kessa has nothing to hold. **Expected: base** |
| **vs Yamamoto** (7–9.5 m zone, fire waves, Shiranui, South) | JŪJISHŌ cuts his waves on the way in | chains block fire in a 12 f window from any side; the pull drags him from 7 m; the residue sits in his 7–9.5 m zone; the wall eats Shiranui. **Expected: Kessa** |
| **vs Rukia** | base Rukia's J1 7 f and rings reward a rushdown that can guard | her placed ice (ring pillar, HAKUREN) is blocked by a timed parry; **her zero's optic ward lets hazards through at ×1.0**: the clone, the crescent, the residue, the wall and the far part of the pull all go through; her blades into a parry are caught (the parry precedes the ward's freeze-touch, since he is the defender). **Expected: Kessa** |
| **mirror** | a base Ichigo's J pressure beats a Kessa who can't guard | a Kessa parries a base Ichigo's K and SŌGA, and blocks his Getsuga |

---

## 5. The Kikon cinematics (60 Hz, review-3 pacing; unskippable; every shot framed with `shot-on` on its subject, so `%keep-subject` keeps him in frame at 0.55 landscape / 0.3 portrait)

Ichigo wears black, so the base goes on the **white card** (Rukia's rule). Kessa's red form goes on the **black card with a
BLOOD back-rim** (Kenpachi's Bankai precedent).

### 5.1 Base: `ic-juji-cine` **月牙十字衝** (186 f; Kikon 2, Soul Break 3) [V move; A: its "blinding explosion" framing, TYBW Part 2]

| Shot | Frames | What |
|---|---|---|
| beat 0 | 0–12 (12) | the JŪJI X held; a negative 2 f; `:whoosh-heavy` |
| caption card | 12–70 (58) | **white card**; Ichigo a black silhouette, both blades crossed low, their white edges the only lines; brush **月牙十字衝** (reading GETSUGA JUJISHO, sub KIKON), the red 鬼 hanko; silence. `shot-on a` |
| the two crescents | 70–100 (30) | medium and low on him (`shot-on a`): the long blade swings, one ink crescent; the short blade, a second; `:getsuga` twice |
| the cross | 100–128 (28) | wide-angle from behind the victim (`shot-on v`): the two crescents fuse into an X and run at him |
| held push-in | 128–150 (22) | on the victim as the X arrives; poses held, effects frozen, silence |
| impact | 150–170 (20) | a negative, then a 12 f manga page (white; the BLOOD soul flame the only colour); the X bursts, "a blinding explosion that engulfs the area"; the Konpaku shatter; `:getsuga` low + `:konpaku-shatter`, shake |
| aftermath | 170–186 (16) | wide from behind Ichigo (`shot-on a`): both blades lowered, ash drifting |

### 5.2 Kessa: `ic-kessa-kikon-cine` **血鎖斬月 KESSA ZANGETSU** (192 f; Kikon 3, Soul Break 4) [A abilities; G the name and the sequence]

| Shot | Frames | What |
|---|---|---|
| beat 0 | 0–12 (12) | the chain lane held; a negative 2 f; `:chain-snap` |
| the chains | 12–40 (28) | on the victim (`shot-on v`): chains lash in from the plaza's edge and wrap his arms and legs (the victim plays `:sh-bound`); `:chain-rattle` ×2 |
| caption card | 40–98 (58) | **black card, BLOOD back-rim**; Ichigo's silhouette, horns, the single blade raised; brush **血鎖斬月** (reading KESSA ZANGETSU, sub KIKON), the red hanko; silence. `shot-on a` |
| the raise | 98–122 (24) | low and close on him (`shot-on a`): Tensa overhead in both hands; a huge crescent builds on the edge (ink, BLOOD rim), the chains at his wrists taut |
| the giant Getsuga | 122–150 (28) | `shot-pair`, wide: the crescent crosses the plaza into the bound victim; `:getsuga` at 0.7 pitch |
| impact | 150–170 (20) | a negative, a 12 f manga page; the crescent passes through him; the Konpaku shatter; the chains snap |
| the residue | 170–192 (22) | on Ichigo (`shot-on a`): the crescent afterimage hangs over the plaza and fades [A-derived]; chains settle back to his wrists |

Both are `defcine` scripts with existing primitives (`card`, `back-rim`, `caption`, `impact-frame`, `lens`, `silence`,
`hold-both`, `shot-on`, `shot-pair`, `cine-clip`). The new looks are the chain wrap and the crescent (§10). In portrait the
close-ups follow DUEL_MOBILE_DESIGN §15.3.

---

## 6. The awakening: condition and entry cinematic

**Condition:** the universal EVOLUTION, P from idle / walk / guard, once per match, **no heal** (Q7). The chain gauge (the
guard gauge), Reiatsu and flash-step are kept as they are. The CPU's timing is a rule (§7.1).

**`ic-kessa-cine` 血鎖の一護 (168 f; unskippable)**

| Shot | Frames | What | Canon |
|---|---|---|---|
| beat 0 | 0–12 (12) | both blades lowered, head down; a negative 2 f; silence | — |
| the Hollow blood | 12–40 (28) | close on the face (`shot-on a`, lens 70): a white Hollow marking crawls up the **left** side and one horn grows on the left; a low drone (`:awaken-rise` at 0.6 pitch) | [V] half-Hollowfication, left side |
| the overlay | 40–70 (30) | medium, low: he brings the short blade into the long blade's hole and the two become one; a white flash frame at f58, when the body swaps to `:ichigo-kessa` and the weapon to `:tensa` | [V] Tensa by overlaying the pair |
| the chains | 70–96 (26) | low and wide from behind (`shot-on a`): blood-chain reiatsu bursts from the neck, wrists and ankles and hangs; **the second horn**, no mask; `:chain-rattle` ×2, `:awaken-boom` | [A] official description |
| caption card | 96–150 (54) | **black card, BLOOD back-rim**, his silhouette with two horns and trailing chains; brush **血鎖の一護** (reading KESSA NO ICHIGO, sub TENSA ZANGETSU); no hanko (not a Kikon) | [A] name by Kubo |
| wide | 150–168 (18) | back in the plaza (`shot-on a`), the chains drifting, the opponent small in the distance | — |

Not used:
- **Yhwach breaking the Bankai** [V]: it is the wrong story for a power moment.
- **The red crescent moon in the sky and a red body** [U, a search summary only]: not used until a source confirms them;
  a sky tint is a one-line add later.

---

## 7. AI profiles (`:ai` per form; generic code in ai.lisp)

### 7.1 When to awaken (a real choice)

Rukia's generic `:awaken` rule reads the damage-source counters (`gauges-taken-melee` / `-ranged`, already built). Ichigo's
is the mirror image: `:awaken (:ranged-share 0.35 :min-taken 150)`. On EVOLUTION he awakens only once he has taken ≥ 150
**and ≥ 35 % of it came from ranged hits** (hazards and `:ranged` windows: fire, waves, rings, Getsuga, the Meteor's far
part). Engine gap 11 adds one key beside `:melee-share`.
- **vs Kenpachi** (almost all melee) he stays base, which is what §4.9 predicts is right.
- **vs Yamamoto / Rukia** he awakens once their zoning has landed.
- **vs a mirror** it follows how much Getsuga he ate.

The share keeps updating (rule 5: the choice is made mid-match, with information). Debug 39000 + 10a + b (0 the rule, 1
always, 2 never) is generic and already built.

### 7.2 Tables

| Form | Intents (A / P / Z / D) | Ranges | Bands (lo hi weights) | Other keys |
|---|---|---|---|---|
| **base** | 2 / 4 / 0 / 1 | A 2.6–5.0, **P 1.4–2.4**, D 3.0–5.0 | 0–2.6 `:q 5 :f 3 :breaker 1 :sp2 1`; 2.6–5 `:sig 2 :sp2 2 :f 1 :step 1`; 5–9 `:sp2 2 :sig 2 :sp1 1 :kikon 1`; 9–99 `:sp1 2 :kikon 1 nil 1` | guard 0.4, hoho 0.3, **dash 0.8**, dash-back 0.1, **block-string 0.8** (the gauge grinder), `:l-after-k 0.3`, sp-cancel-bars 1 (SŌGA off link 3: S18 < 26), kikon-range 8.6, `:awaken` §7.1. JŪJISHŌ against a projectile: `:react (:projectile :sp1)` (the Kenpachi-stance slot, generic) |
| **Kessa** | 1 / 1 / **3** / 2 | **Z 3.2–4.4** (the chain band), P 2.8–3.8, A 3.8–6.0, D 4.0–6.0 | 0–2.4 `:q 2 :f 1 :breaker 1 :step 3 nil 1` (too close: step back, which leaves a clone); 2.4–4.4 `:q 5 :f 3 :sig 1 nil 1`; 4.4–7.5 `:sp1 2 :sig 3 :sp2 1 nil 2`; 7.5–99 `:sig 2 :kikon 1 :sp2 1 nil 2` | **guard 0.0** (no hold-guard), hoho 0.35, dash 0.2, **dash-back 0.6** (keep 3–4 m; each back-dash hop is a clone), o-ender 0.2, kikon-range 8.0, sp-cancel-bars 9 (never), `:l-after-k 0.3`, **`:stun-follow (:sp1 3.8 7.0)`** (a stunned victim beyond J reach gets the pull; Rukia's key), **`:react (:flash-startup :u :projectile :u)`** (parry a K / SP startup or an incoming projectile only when its hit falls in the window: engine gap 11), **`:parry-read (:p 0.12 :near 3.0 :min-gg 40)`** (a neutral decision within 3 m while he is being pressed: a read parry), **`:sig-gg 0.5`** (L halved below half the chain gauge; built key) |

- **The u-move mapping** (engine gap 11, generic): in a form with `:u-move`, `ai-guard-mult` is 0 (no blind presses). Its
  U is pressed only through `:react` (timed to the window), the `:parry-read` roll, and **the follow-up rule**: as the
  victim of a non-red dash-in it presses U on its first free frame (the window covers the 12 f arrival, §4.2), rolled
  with `*ai-follow-guard-p*`.
- **Opponents facing Kessa** need no new key:
  - "a parry up close: don't feed it; Breaker half the time" already reads `:parry` flags;
  - the low-guard-gauge hunt reads his chain gauge;
  - a CPU in a clone's arc sees it as a hazard threat (the perfect-Hoho and anti-projectile paths).
- **No `:opp-intent`.** Kessa is permanent; there is nothing to wait out.

---

## 8. HUD and the one-hand controls

**Landscape:**
- **Base:** the universal panel. The guard bar is steel, the kit-meter slot is empty (like Kenpachi's and Rukia's bases),
  and L's cooldown isn't drawn (the base-form rule).
- **Kessa: one resource, one bar.** The **guard bar's own row and size** becomes the chain gauge (`%hud-guard` with the
  kit key `:gg-skin :chain`, engine gap 12):
  - a BLOOD-cored ink link every 10 points;
  - a **white notch at 20** (U's cost) and a dim notch at 35 (the clone reserve);
  - on an L press, **L's 30 dimmed** on the fill; a refused U or L flashes it (`*refused-t*`);
  - label: brush **鎖** + `CHAIN`;
  - guardless after a crush: the universal grey with a red fill climbing back, "GUARD" when it returns;
  - the KŌSEI `攻 ×m` tag at its inner end, as today.
- **Kessa's other rows:** no kit meter, no COOLDOWN row (L has no cooldown), so nothing can overlap (the Rukia playtest
  rule). The U tag on the awakening row reads `U: CHAIN`, or `U: --` below 20. The name line reads "ICHIGO KESSA".

**Portrait** (`hud-side-portrait`): the chain gauge is the guard row, which already **spans the HP bar's width** (the
user's portrait rule). Ichigo's fourth small-gauge slot stays empty. `portrait-label` is `鎖 CHAIN` in Kessa.

**One hand** (DUEL_MOBILE_DESIGN §15.1; base unchanged: tap J, upper tap K, flicks, **rest = guard**, rest → up-flick
Hoho, chips):
- **In Kessa a resting thumb does nothing.** A rest-as-U would fire a 20-chain parry on every rest (drag-rest-drag
  footwork would burn the gauge). Rest → up-flick is still Hoho.
- **The AWK chip becomes the 鎖 chip** once he has awakened. AWK is spent after the awakening, so the chip slot is free,
  and a tap on it is U, the parry (Q3).
- The thumb ring shows the chain gauge as a BLOOD arc with a white tick at 20; it dims below 20.
- Every Step flick spends 15 when a clone is made; the ring shows it.

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

**Expected effect:**
- **The existing six pairings are byte-identical.** Every change is behind an Ichigo kit key, a passive, or a hazard
  kind / flag only he spawns:
  - `:weapon-2`, `:u-move`, `:gg-cost`, `:step-hook`, `:parry-block`, `:clone`, `:cuts`, `:pull`;
  - the parry window moves from a global to the move's own S / A, which is identical for GOKUI GAESHI and host-tested;
  - the `set-reaction` `kb > 0` → `kb ≠ 0` change is a no-op, since nothing else has a negative kb.

  No new random draw is made for Y / K / R, and the style gates' cvc refs (`tests/style-cvc-ref.txt`) must match.
- **The gate grows to ten pairings** (IY, IK, IR, II), 200 matches. Predictions:

| Pairing | Median guess | Why | Risk |
|---|---|---|---|
| **IY** | 135–165 s | base runs in through waves; Kessa (after the rule fires) blocks fire and pulls | two mid-rangers staring past 210 s; heat is the backstop |
| **IK** | 125–145 s | two rushdowns; base Ichigo's 54 drains meet Kenpachi's cut and Bankai | **< 125 s** (KK already sits near the floor); knobs below |
| **IR** | 140–175 s | base Ichigo vs rings; Kessa vs a zero Rukia (optic lets his hazards in) | the high edge in RR-like stalls |
| **II** | 130–160 s | J pressure vs parries | — |

- **Win targets:** each new pairing within 10 ± 3 of 20.

**The awaken A/B** (seeds 1–60, NORMAL; P1 Ichigo in mode 1 "always on EVOLUTION" vs mode 2 "never" vs mode 0 "the rule";
the opponent on its own rule; II: P2 on the rule):
- **Pass:**
  - |always − never| ≤ **9 of 60** in every pairing (the Kenpachi / Rukia criterion), **and**
  - **at least one pairing has never > always**, expected to be **IK**.
- **Logged, not gated:** mode 0 should be at least as good as the better of the two in IY and IK.
- **The Kikon count is counted in:** "always" gets the universal 3-Konpaku Kikon, which biases it by construction. That is
  why Kessa's strings start ~10 % lighter and he has no hold-guard. If "always" still wins everywhere, the knobs are in the
  order below.
- **If always wins everywhere** (an upgrade):
  1. `*kessa-mult*` 1.0 → 0.9;
  2. `*chain-catch*` 40 → 30;
  3. `*chain-u-cost*` 20 → 25;
  4. the parry window 12 → 10 (A 12 → 10);
  5. `*clone-cost*` 15 → 20;
  6. `*kessa-l-cost*` 30 → 40.
- **If never wins everywhere** (a trap):
  1. `*kessa-taken*` 1.0 → 0.9;
  2. the parry window 12 → 14;
  3. `*walk-kessa*` 3.6 → 3.9;
  4. `*chain-catch*` 40 → 50;
  5. the pull's bind 40 → 44;
  6. if still a trap: **Q9's fallback, a normal guard at guard value ×1.3** (the user's decided fallback).

**Pacing log** (added to the gate report, a `duel ichigo` line per side, debug only):
- when he awakened, and the ranged share at EVOLUTION by opponent form;
- time in each form; the chain gauge's mean and the time spent below 20;
- parries by outcome (catch, whiff, projectile block, Breaker-broken) and yank hits;
- crushes (from blocked projectiles);
- clones made / hit / blocked / closed early, and clone hits converted to a J string;
- residues and their hits; pulls (hit / block / whiff); walls and projectiles cut;
- JŪJISHŌ cuts; the base drains per blocked string.

**Knobs, in order:**
- **Medians under 125 s (IK most likely):**
  1. `:block-string` 0.8 → 0.6;
  2. KŌGA's guard 24 → 20;
  3. the clone's +14 → a stagger-free 12 f flinch (`:stun 12`);
  4. the pull's bind 40 → 32 (no string after it).
- **Medians over 210 s (IY):**
  1. Kessa's zone weight 3 → 2;
  2. `:dash` 0.2 → 0.4;
  3. the residue life 90 → 60.
- **Ichigo wins too much:** base J1 32 → 30, KŌGA 24 → 20, SŌGA 130 → 115.
- **Ichigo wins too little:** base walk 4.2 → 4.4, JŪJISHŌ 150 → 165, the O module's dash 14 → 16 f.

---

## 10. Build list

**New files** (MANIFEST: `lisp/ichigo-art.lisp` after `lisp/rukia-art.lisp`, `lisp/ichigo.lisp` after `lisp/rukia.lisp`):
- `ichigo.lisp` (~480 lines):
  - **Moves:**
    - base: 6 grid + 2 cross copies, GETSUGA + its `-k` combo copy, JŪJISHŌ, SŌGA, MINEUCHI, JŪJI;
    - Kessa: 6 grid + 2 copies, KUSARI-TATE, HIKI-GUSARI, the giant GETSUGA + `-k` copy, KUSARI-BIKI, KUSARI-GAKI,
      KESSA.
  - **Kits** `:base :kessa`.
  - **Hooks:** `ichigo-getsuga`, `ichigo-juji`, `ichigo-giant` (the wave + the delayed residue, one residue),
    `ichigo-wall` (one wall), `ichigo-clone` (the step hook), `ichigo-chains-flare`, `ichigo-kessa-enter`.
  - **Three cinematics.**
- `ichigo-art.lisp` (~650 lines): body `:ichigo` and the variant `:ichigo-kessa` (horns, the left marking, the chain
  anchor tags); weapons `:zangetsu-long` (with its hole), `:zangetsu-short`, `:tensa`; the clips.

**Character select:** automatic (a `:base` kit adds him to `*roster*`). Also:
- `*brush-names*` `(:ichigo "黒崎一護" "KUROSAKI ICHIGO")`;
- `:intro :ic-intro :intro-callout "ZANGETSU"` (both blades drawn from the back);
- `:win :ic-win`;
- the P2 tint follows the existing rule, with the hair cold-shifted.

**Clips: 22 new**
- **Base (15):** `:ic-stance`, `:ic-q1`, `:ic-q2`, `:ic-spin`, `:ic-f1`, `:ic-f2`, `:ic-drop`, `:ic-cross`, `:ic-getsuga`,
  `:ic-juji`, `:ic-breaker` (the dash loop), `:ic-mine` (the strike), `:ic-intro`, `:ic-win`, `:ic-awaken` (the overlay
  pose, cinematic).
- **Kessa (7):** `:ic-k-stance`, `:ic-k-thrust`, `:ic-k-lash`, `:ic-k-wrap`, `:ic-k-parry`, `:ic-k-yank`, `:ic-k-wall`.
- **Reused:**
  - base: J2s / K2s and SŌGA's strike on `:ic-cross`; JŪJI's dash on `:sh-run` and its strike on `:ic-cross`;
  - Kessa: K1 / K2 / K3 on `:ic-f1` / `:ic-f2` / `:ic-drop` (the chain is an fx; §2); the giant GETSUGA on `:ic-getsuga`
    (clip-s 14 at S18, read as a heavier swing); KUSARI-BIKI on `:ic-k-yank`; the KESSA lane on `:ic-k-thrust`; the
    clone's slash on `:ic-k-lash`; the Breaker on the base clips;
  - the Kikon cinematics on `:ic-juji` / `:ic-getsuga`;
  - every reaction, walk, strafe, step, guard and the run set on the shared `:sh-*`.

**Glyphs to bake** (`tools/glyph-bake.py`; 斬 月 天 十 二 刀 盾 の are already baked): **黒 崎 一 護 牙 衝 字 血 鎖 双 引 垣**
(12). The brush columns: 黒崎一護, 月牙天衝, 月牙十字衝, 双牙, 鎖盾 (on a catch), 鎖引, 鎖垣, 血鎖斬月, 血鎖の一護. MINEUCHI stays
brush Latin (the Breaker rule).

**Sounds: 4 new** (`sounds.lisp`, synthesized):
- `:chain-rattle`: link clatter (the parry, the wall, the chains shot);
- `:chain-snap`: a taut snap (a catch, the yank, the pull's hit);
- `:getsuga`: a deep tearing whoosh with a low resonance (every crescent; pitched 0.7 for the giant one);
- `:clone`: a glassy shimmer (a clone appears / slashes).

Reused: `:whoosh-light`, `:whoosh-heavy`, `:cut`, `:clang`, `:hoho-out`, `:kikon-slash`, `:konpaku-shatter`,
`:awaken-rise`, `:awaken-boom`, `:ground-crack` (the wall).

**VFX** (vfx.lisp; mono ink + white, BLOOD only in Kessa's chains and rims):
- the Getsuga crescent (the `:wave` draw with a look function: an ink crescent, white rim) and the cross;
- the giant crescent (a BLOOD rim) and its **residue** (the same crescent, still, pulsing, fading over its last 20 f);
- **the chain ribbon** (small ink ovals with BLOOD cores along a polyline, the ribbon machinery): wrist → a hit volume's
  far end during a window, the parry's radial flare (neck, wrists, ankles), the pull line, the yank, the wall's upright
  strands, the cinematic wrap;
- **the clone** (`draw-body :alpha 0.45`, BLOOD rim, as `:hand` draws South's skeletons);
- the horns and the left marking (body parts);
- the Kessa aura (a smoulder of chain wisps);
- the projectile-cut flash (the existing `:hazard-cut` event).

**Existing systems reused**

| System | Where it comes from | Ichigo's use |
|---|---|---|
| **the parry** (`:parry` flag, `:land` counter, `*parry-stun*`, `:parried`, GOKUI GAESHI's catch refill) | Bankai West | KUSARI-TATE and HIKI-GUSARI; the refill becomes `:gg-catch` |
| **the ward's no-blockstun block** | Bankai West | a projectile blocked in the parry window |
| **the guard gauge, GUARD CRUSH, guardless, KŌSEI's m, the AI's gauge reads** | universal | the chain gauge |
| **the `:wave` hazard** (moving and, at speed 0, stationary) | Yamamoto's Signature | GETSUGA, JŪJISHŌ, the giant one, the residue, the wall |
| **`:src` and `:fragile` hazard slots, `close-rifts`** | Rukia's rings, KUKAN-GIRI's rift | the clone (guarded facing him, gone if he's hit) |
| **the `:rift` hit** (a hitwin volume in its own frame, delayed) | NOMIHOSE | the clone's slash |
| **the `:hand` entity** (a hazard with a model) | South | the clone's body |
| **the `:bind` reaction** (opener, books 2 hits) | South | the pull's bind, the Kikon cinematic's wrap |
| **the ENJO module** (no dash, a locked lane) | Yamamoto's Kikon | the KESSA module |
| **the flash-step look** | KITA: TENCHI | JŪJI, SŌGA |
| **`:melee-range` split** | the Meteor | KUSARI-BIKI (blade to 3.8 m, chain beyond) |
| **`:l-after-k`** | DUEL_STRINGS §12 | GETSUGA after a K link (both forms) |
| **`defmove-copy` with overrides, `:grid`** | the strings, MAPPUTATSU | the cross links, the combo copies |
| **`:awaken` damage-source counters** | Rukia | `:ranged-share` |
| **`:stun-follow`, `:sig-gg`, `:react`** | Rukia, East, Kenpachi / West | the pull, the L gate, the timed parry |
| **`body-variant`** | Kenpachi's oni, Rukia's zero | `:ichigo-kessa` |

**Engine gaps** (all generic and data-driven; no-ops for Y / K / R):

| # | Gap | Size |
|---|---|---|
| 1 | **`:weapon-2`**: a second held weapon drawn in the existing `:weapon-l` joint; its trail; `refresh-look` swaps it (NIL in Kessa) | ~20 lines, body.lisp / main.lisp / kit.lisp |
| 2 | **`:u-move MOVE`**: U's press edge starts MOVE from a free state (like `:guard-to`); refused like a command (cost, guardless); `guard-held-p` is NIL in the form | ~10 lines, fighter.lisp |
| 3 | **`:gg-cost (cmd n …)`**: spend the guard gauge on frame 0 (the delay restarts), refusing `:u` / `:sig` below n; **`:gg-catch n`**: a catch adds n (replacing West's hard-wired full refill with a kit value: West `:gg-catch 100`, identical) | ~12 lines, fighter.lisp / combat.lisp |
| 4 | **The parry window from the move's own S / A** (`parry-frame-p sf mv`); GOKUI GAESHI's S4 A12 = 4–15 as today | ~3 lines + a host test |
| 5 | **`:parry-block`** passive: a hazard / ranged hit in the parry window is `:guard` (not a hit) and takes the ward's no-blockstun branch | ~4 lines, rules.lisp / combat.lisp |
| 6 | **`:pull d`** hitwin key: the reaction's slide goes **toward** the source to d m (rules `pull-kb`: kb = −(dist − d), clamped at 0); `set-reaction`'s grounded `(> kb 0)` becomes `(/= kb 0)` | ~6 lines |
| 7 | **`:step-hook SYMBOL`**: called on a Step's frame 0 (the hop of a dash included, not a Hoho) | ~3 lines |
| 8 | **`:clone` hazard kind**: `:rift`'s touches-p and delay; `close-rifts` includes it; `:hand`'s model and anim (alpha by age); `hazard-draw` draws the body | ~20 lines, hazards.lisp |
| 9 | **`:cuts` hazard flag**: each step a `:cuts` hazard destroys opponent `:wave` / `:fireball` hazards it overlaps (`obox-cyl-hit-p`, the `:hazard-cut` event) | ~12 lines, hazards.lisp |
| 10 | **"One of each"**: the hooks remove the owner's older residue / wall / clone (`do-entities` over his hazards with that look) | in ichigo.lisp |
| 11 | **AI**: `:awaken :ranged-share`; the u-move mapping (`ai-guard-mult` 0; `:react` / follow-up press U timed to `parry-frame-p`); a projectile's time-to-contact for `:react :projectile` with a parry move; `:parry-read` | ~30 lines, ai.lisp |
| 12 | **HUD**: `:gg-skin :chain` (links, notches, the cost flash, the 鎖 label), `U: CHAIN` / `U: --`; portrait label; one-hand: rest inert in a `:u-move` form, the AWK chip → the U chip after awakening, the ring's chain arc | ~40 lines, hud.lisp / onehand.lisp |

**Host tests** (`tests/duel-rules-test.lisp`):
- **Strings:** the §2.1 budget over `:base :kessa`, the six routes, and the J2s / K2s copies (the cross copies may differ
  only in `:guard` and `:clip`).
- **The parry:** `parry-frame-p` for GOKUI GAESHI unchanged (4–15); KUSARI-TATE is 2–13; the yank's on-hit advantage is +3;
  `resolve-contact` with `:parry-block` gives a hazard `:blocked` and a melee hit `:parried`.
- **Pull and bind:** `pull-kb`; KUSARI-BIKI's bind is +13 and J1 combos after it.
- **The clone:** its hit is +14 and J1 combos (Step 24, delay 20, flinch 18).
- **L after K:** the two combo copies (`:ic-getsuga-k`, `:ic-k-getsuga-k`) combo after each K link (A(K) + the L's hit
  frame at the link's reach < 26 / 40).
- **Reaches:** every Breaker strike > 2.2; every Kikon strike > 1.9.
- **Kikon counts:** 2 / 3; Soul Break 3 / 4.
- **Side Steps:** the half-widths + Kenpachi's hurt r < 2.5 (GETSUGA 1.2, JŪJISHŌ 1.8, the giant one 2.0).
- **Costs:** `:gg-cost` refusal (U at 19 refused, 20 allowed); the clone only at ≥ 35.
- **`:cuts`:** a wave destroys a fireball it overlaps and leaves a `:freeze` disc alone.
- **The fallback:** `set-reaction` with a negative kb slides toward the source.

**Probes** (debug, a new block, e.g. 2430 + k, stills at 72000 + f):
- parry a Kenpachi K1 → the yank → +3;
- a whiffed parry costs 20;
- a parried Shiranui is blocked and drains;
- a Breaker breaks the parry (crumple 40);
- a blocked projectile at 5 chain → GUARD CRUSH → U refused until full;
- the clone slashes at f20, doesn't appear under 35, and closes when he is hit at f10; one clone at a time;
- the residue replaces the old one;
- JŪJISHŌ cuts a Signature wave; the wall eats Shiranui;
- a Kessa catch of a non-red dash-in;
- the determinism double run;
- stills of the three cinematics in landscape and portrait (the subject in frame).

**Implementation order:**
1. Rules and host tests.
2. Kits with placeholder clips (Kenpachi's and Rukia's clips on the `:ichigo` body, a single weapon), then the engine gaps
   2–10 and a minimal HUD. The gate: the six old pairings byte-identical, then IY / IK / IR / II.
3. AI keys, the gate again, and the awaken A/B.
4. Art: the body and variant, three weapons (the second-weapon gap 1), 22 clips, the chain ribbon, VFX, three cinematics,
   sounds, glyphs. User review with stills.
5. Docs:
   - DUEL_DESIGN §1 (the roster), §6.5 (new: Ichigo), §6.3 (JŪJI and KESSA rows), §7, §10 (HUD, the cinematic table:
     月牙十字衝 186, 血鎖斬月 192, awakening 168), §12 rows;
   - DUEL_MOBILE_DESIGN §15 (the 鎖 chip, rest inert);
   - STYLE_STORM §A.2 (muted orange hair, not a spot; mono Getsuga);
   - a new docs/DUEL_ICHIGO.md from this file.

---

## 11. Knobs (all in `duel/lisp/tuning.lisp` unless noted; debug numbers assigned at build)

| Knob | Value | Note |
|---|---|---|
| `*walk-ichigo*` / `*run-ichigo*` | 4.2 / 10.0 | base |
| `*walk-kessa*` / `*run-kessa*` | 3.6 / 9.0 | Kessa |
| `*ichigo-mult*` / `*ichigo-taken*` | 1.0 / 1.0 | base damage |
| `*kessa-mult*` / `*kessa-taken*` | 1.0 / 1.0 | the A/B's first knobs |
| `*chain-u-cost*` | 20 | U's price, the HUD notch |
| `*chain-catch*` | 40 | a catch's refund |
| KUSARI-TATE S / A / R | 2 / 12 / 24 | the window is the move's A (ichigo.lisp) |
| HIKI-GUSARI S / A / R, `:pull` | 6 / 3 / 20, 1.8 m | +3 on the catch |
| `*clone-cost*` / `*clone-reserve*` / `*clone-delay*` / `*clone-dmg*` | 15 / 20 / 20 / 40 | the clone |
| `*kessa-l-cost*` | 30 | the giant Getsuga |
| residue life / damage | 90 f / 50 | ichigo.lisp params |
| KUSARI-BIKI `:pull` / bind | 1.6 m / 40 f | +13 |
| wall life / width | 120 f / 5.0 m | ichigo.lisp params |
| KŌGA / KAESHI-KIBA guard | 24 / 12 | the cross |
| base K guard (K1 / K2 / K3) | 16 / 16 / 22 | the gauge grinder |
| JŪJISHŌ damage / width / `:cuts` | 150 / 3.6 / on | |
| AI | `:awaken :ranged-share` 0.35, `:min-taken` 150; `:parry-read :p` 0.12; `:block-string` 0.8 (base); Kessa zone weight 3; `:react` p (the universal `*ai-react-p*`) | |
| art | `(:head 1.2 …)`, hair #B8733E | stills review |

---

## 12. Adversarial self-critique

| # | Sev | Finding | Resolution (folded into the text above) |
|---|---|---|---|
| B1 | BLOCKER | Kessa has **nothing to hold**. Between NORMAL CPUs every J string lands (J1 7 f can't be reacted to), and "never awaken" wins every pairing: the awakening is a trap | chain reach keeps him at 3–4.4 m where J1s don't reach (AI `:dash-back` 0.6; every back-hop is a clone); the parry reads K / SP startups (`:react`) and the follow-up; the A/B's "trap" knob list ends in the user's own fallback (Q9: a normal guard at ×1.3) |
| B2 | BLOCKER | A free U would be mashed on every read: parry fishing with no cost | 20 chain per press, a 24 f unguarded whiff, the Breaker breaks it, and the CPU never feeds a visible parry (built reflex) |
| B3 | BLOCKER | **Clone + body = a front / back mix-up** (report risk 1) | `:src` = Ichigo's position: a guard facing him blocks the clone wherever it stands; flinch only; no contact; one at a time |
| B4 | BLOCKER | **Pull loops** (report risk 2): catch → yank → string → catch … | the yank is +3, not a combo; the pull's bind books 2 hits (Burst legal), costs a bar, and its J string can't reach the ender's O unless it completes; the parry costs 20 every press |
| B5 | BLOCKER | The phone's resting thumb is a guard: in Kessa it would fire a 20-chain parry on every rest | rest is inert in a `:u-move` form; the spent AWK chip becomes the 鎖 chip (Q3) |
| B6 | BLOCKER | Hash drift: new slots (clone entity, `:weapon-2`, costs) would move the Y / K / R references | every change is keyed on an Ichigo kit key or on hazards only he spawns; the global parry window becomes the move's own S / A (identical for GOKUI GAESHI, host-tested); gate step 2 checks the six old pairings byte-identical first |
| M1 | MAJOR | BLOOD chains everywhere blur the **Kikon tell** (the rush's BLOOD trail, the red soul flames) | chains are ink links with a thin BLOOD core; the Kessa aura is a smoulder at five anchor points, never a pillar; the aura drops to a trace during his own Kikon rush (Kenpachi's Bankai rule); checked on stills |
| M2 | MAJOR | Re-skinning the guard gauge could confuse players ("why does my guard bar go down when I step?") | the bar's label, links and colour change at the awakening; the tutorial says it; it is also why the clone keeps a 20 reserve (the automatic spend never takes the parry away) |
| M3 | MAJOR | GUARD CRUSH from **blocked projectiles** leaves him guardless (no U) for ~16 s: harsh against Yamamoto, the matchup he should win | it is the forced exit (rule 4) and the opponent's verb against a low-chain Kessa; the parry's projectile block is a choice; knob: a Kessa `:gg-guardless` refill if the pacing log shows crushes above 1 per IY match |
| M4 | MAJOR | Kessa J1 is the longest J1 (3.8 m at 10 f) and could zone with jabs | 30 damage, guard 6, whiff R + 8; it loses to every J1 inside 2.5 m; K1 − J1 = 10 keeps J beats K |
| M5 | MAJOR | The clone's +14 turns every back-Step into a guaranteed string on a chaser | a 20 f visible tell, costs 15 above a 35 floor, fragile, guardable facing him; knob `:stun 12` (no string) if IK falls under 125 s |
| M6 | MAJOR | The base 54-drain strings plus `:block-string` 0.8 could crush guards every exchange (IK, II too short) | KŌGA / K3 are K links (J beats K interrupts them, ≥ 12 f gaps), and the CPU goes K on block only 0.15 of the time; knobs in §9 |
| M7 | MAJOR | `:cuts` makes JŪJISHŌ and the wall hard counters to Yamamoto's whole Shikai zoning | both are bounded (JŪJISHŌ 1 bar, S20; the wall 2 bars, one at a time, 2 s); South (a ground bind) and ENJO's lane (his Kikon) are never cut; Hellfire's Nadegiri is melee / ranged by window, not a hazard |
| M8 | MAJOR | The residue at 8 m sits in Yamamoto's 7–9.5 m zone: a stall generator if both wait | it is one hit, 1.5 s, one at a time, 30 chain each; heat (×2 beyond 6 m) still pulls both in |
| M9 | MAJOR | The universal awakened Kikon 3 biases "always" by +1 Konpaku per Kikon | Kessa's −10 % strings and no hold-guard are the offset; the §9 knob list starts with `*kessa-mult*` |
| M10 | MAJOR | The dual wield is a new engine piece (a second weapon, a second trail) touching the draw of every fighter | a kit key that defaults to NIL; the render only; the sim never reads weapons |
| M11 | MAJOR | 22 clips + 3 weapons + 3 cinematics is the largest art batch yet | 8 moves reuse clips (§10); the chain is an fx, so Kessa's K links need no new clips; placeholders let the gate and the A/B run first |
| m1 | MINOR | Invented names ([G]) could read as canon, above all **血鎖斬月** | §13's ledger; 血鎖斬月 is tagged "our coinage" wherever it appears (Q8) |
| m2 | MINOR | Parts of the Kessa look are unverified (the blade, a red body, a red moon) | the manga's Tensa description; the red moon and red body are not used [U] |
| m3 | MINOR | The half-Hollow marking on the left appears only in the entry cinematic | canon uses it as a transition beat; the in-play Kessa keeps a faint trace |
| m4 | MINOR | The two base guard-value tiers (cross links) add a rule players must learn | it is data on the existing switch-once rule; the X clip shows it |
| m5 | MINOR | `:ranged-share` might never fire in II if nobody throws Getsuga | the CPU mirror throws them (L in the 2.6–9 m bands); if II never awakens, the log shows it and the A/B still measures modes 1 / 2 |

Revision: every finding above is folded into the text. Three ideas were dropped on purpose:
- **A projectile catch that refunds chains** would make Yamamoto's fire a free battery.
- **Clones on the Hoho** as well: two sources of afterimages would read as a mix-up.
- **Base 半虚化 as an SP**: the half-Hollow is the awakening's first beat, and a second form would blur the one choice.

---

## 13. Canon ledger (what is manga, what is anime-only, what is ours)

| Element | Source | Tag |
|---|---|---|
| the two blades (long cleaver with a hole, hiltless stone-knife short blade) | ch. TYBW reforging; ja.wikipedia | [V] |
| which blade is Quincy / Hollow | no source states it | **not used** |
| 月牙天衝, 月牙十字衝 (two Getsuga fused; dispersed Sankt Zwinger) | manga (Bleach Wiki snippet) | [V] (the "disperses a barrier" detail is snippet-level: used only as the projectile cut, a game reading [G]) |
| 月牙十字衝's "blinding explosion" framing | TYBW anime Part 2 (vs the Bambies) | [A] (cinematic flavour) |
| half-Hollowfication, horn on the left | manga | [V] |
| Tensa Zangetsu by overlaying the pair; white blade, black line | manga (ja.wikipedia) | [V] |
| Yhwach breaks it; Tsukishima / Orihime restore it | manga | [V], **not used** |
| **血鎖の一護 KESSA NO ICHIGO** (half-Hollow + Bankai; two horns, no mask; blood-chain reiatsu from neck, hands, feet) | TYBW ep. 45 「DEFEND YOU」, 2026-08-22; designed and named by Kubo | **[A]** |
| chains that block attacks and control the field; reiatsu clones; an enormous Getsuga | FandomWire's "confirmed" list (ep. 45) | **[A]** |
| a giant crescent afterimage after the Getsuga | a Japanese review (search snippet) | [A] / [U]: used as the residue |
| red crescent moon, red body, super speed | search summary | **[U], not used** |
| it still loses to the Almighty | reviews of ep. 45 | [A] (the design's sidegrade premise) |
| **血鎖斬月** | the user's early name; no official match | **[G], our coinage**: the Kessa Kikon's name only |
| every other move name (KOKIBA … KESSA module, 鎖盾 / 引鎖 / 鎖引 / 鎖垣 / 双牙 / 峰打ち / 交牙 / 返牙 / 残月 residue) | ours | [G] |
| RoS TYBW Ichigo (Syzygy stance, SP1 rushing slash, SP2 Getsuga / Jūjishō branch, awakening = faster follow-ups) | Bandai Namco | a reference; its awakening is the **counter-example** (a pure buff), and its names are not reused |

Everything under Kessa is anime-only. If a later official source (ep. 46–50, a guide book) contradicts it, §4 is the
section to revise.

---

## 14. Questions for the user (each with the recommended default)

1. **血鎖量表就是換了外觀的防禦量表嗎？（U、分身、巨大月牙共用一條，不另加新條）** 建議：是。
   *Is the blood-chain gauge the re-skinned guard gauge (U, clones and the giant Getsuga share it; no new bar)?* **Default: yes.**
2. **血鎖型每次 Step 都自動留分身嗎？（花 15，只在量表 ≥ 35 時才出現）** 建議：是。
   *Does every Kessa Step leave a clone automatically (15, only at ≥ 35)?* **Default: yes.**
3. **手機單手模式：血鎖型拇指靠著不動就什麼都不做，覺醒後 AWK 晶片改成「鎖」招架鍵？** 建議：是。
   *One-hand: in Kessa a resting thumb does nothing, and the spent AWK chip becomes the 鎖 parry chip?* **Default: yes.**
4. **把「血鎖斬月」（自創）當血鎖型毀魂技與過場標題？** 建議：是，文件一律標註自創。
   *Use 血鎖斬月 (our coinage) as the Kessa Kikon and its caption?* **Default: yes, always flagged as ours.**
5. **外觀：頭 ×1.2、兩角無面具、墨色鎖鏈配血紅芯、原作天鎖斬月刀身，不用未證實的紅月與紅身？** 建議：是。
   *Look: head ×1.2, two horns and no mask, ink chains with BLOOD cores, the manga's Tensa blade, no unverified red moon or red body?* **Default: yes.**
6. **CPU 覺醒規則：受傷 ≥ 150 且 ≥ 35 % 來自遠距攻擊才覺醒？** 建議：是。
   *CPU awakening rule: only after ≥ 150 taken with ≥ 35 % from ranged hits?* **Default: yes.**

---

## User decisions (2026-09-28, round 1)

1. **Base form = the one-horned Shikai (單角始解).** Ichigo starts the match in his TYBW dual-blade Shikai with the
   half-hollow **single horn** (one horn, no mask); Kessa keeps the two horns. Update §2 (silhouette) and the look
   question accordingly.
2. **Base Kikon = a Getsuga Tenshō infused with a Gran Rey Cero (王虚の閃光を込めた月牙天衝).** It replaces the
   Getsuga Jūjishō cinematic as the base Kikon (2 Konpaku); the SP1 Jūjishō move itself stays in the base kit.
3. **Kessa Kikon = the anime's giant, pitch-black Getsuga Tenshō (宛如巨大漆黑月牙的月牙天衝).** This replaces the
   "血鎖斬月" Kikon of question 4 (3 Konpaku). The Kessa kit's ordinary giant-Getsuga move stays but must read clearly
   smaller than the Kikon's black crescent (rename or rescale it so the two don't compete).
Questions 1, 2, 3, 5 (look; the base form's single horn as decided above, Kessa's two horns), 6: **the recommended
defaults** (the user, 2026-09-28: 照預設).

**Code layout (the user, 2026-09-28; docs/DUEL_DESIGN.md "Character code layout"):** build this character in its own
files (`<name>.lisp` + `<name>-art.lisp`), including the mechanics listed here as "generic gaps": implement them locally
in the character's files behind the smallest possible generic hook points in the shared files. Do not depend on the other
new character's branch; an extraction pass after both merge moves the real repeats into the shared files.

---

## User decisions (2026-09-28, round 2: balance)

The user, 2026-09-28: 「覺醒偏強沒關係，只要不是強到無法贏就好」. **The awakening may be the stronger choice.** The A/B
criterion becomes: on each of **at least three independent seed streams** (60 seeds each), the "never awaken" policy
must still win **at least 20 of 60** against each opponent. The design's "|always − never| ≤ 9" and "IK favours never"
are kept as nice-to-have readings, not gates.

---

## Built: deviations from the design, and why

| Item | Design | Built | Why |
|---|---|---|---|
| Code layout | engine gaps 1–12 in the shared files | everything in `ichigo.lisp` / `ichigo-art.lisp`; the shared files gained only generic hook points (below) | the user's code-layout rule (DUEL_DESIGN "Character code layout") |
| Second weapon (gap 1) | a `:weapon-2` kit key, a second trail | the short blade is a **body part** on the rig's existing `:weapon-l` joint, tagged `:shikai` and hidden in KESSA; no second trail | no engine change needed; the trail is a look |
| The parry window (gap 4) | the move's own S / A (f2–13) | the shared `*parry-window*` (f4–15, GOKUI GAESHI's): KUSARI-TATE is S4 A12 R24 | no rules change; two frames later is inside the noise of a perception-delayed CPU |
| The catch's refill (gap 3) | `:gg-catch` replacing West's full refill | the `:parried` hook adds `*chain-catch*` 40 (West's refill untouched) | a hook, not a shared rewrite |
| Blocked projectiles in the parry (gap 5) | a `:parry-block` passive | as designed: combat.lisp passes WARD for a `:parry-block` parry; the drain is the plain guard value (West's ×1.1 only for `:ward`) | — |
| Pull (gap 6) | a `:pull` hitwin key, `set-reaction` kb ≠ 0 | the hit's `:on-land` hook slides the victim toward him (ICHIGO-PULL-TO) | no shared change |
| Clone (gaps 7, 8) | a `:clone` hazard kind, `:step-hook` | the `:step` hook spawns a `:freeze` disc (r 1.4, 1 m ahead of the clone, `:src` `:fragile`, delay 20) plus a look-only hazard that draws the translucent body | an existing hazard kind; the arc is a disc (ponytail: the disc approximates the 140° arc) |
| `:cuts` (gap 9) | a hazard flag in hazards.lisp | the `:tick` hook: his JŪJISHŌ wave and the wall's look box destroy opponent waves / fireballs they touch | no shared change |
| The wall | one still `:wave` | a look-only `:fx` (the fence, it cuts projectiles for its 120 f) plus a still `:wave` for its one hit | a spent hit must not remove the fence |
| HUD (gap 12) | `:gg-skin :chain` | the `:hud-guard` hook draws over the guard bar (landscape and portrait): a BLOOD cast, links every 10, the notch at 20, a dim notch at 35, `CHAIN` / `CHAIN --` | — |
| One hand | rest inert, the AWK chip → U | as designed (`u-chip-p`; the deck is laid out again with no hold on the chip), the thumb ring's BLOOD arc via `:deck` | — |
| CPU awakening | `:ranged-share 0.35 :min-taken 150` | `:min-taken 150` | the ranged share almost never reached 35 %: the CPU stayed in the Shikai and lost every pairing |
| CPU parry | `:react (:flash-startup :u :projectile :u)`, `:parry-read` | a `:reflex` function (ICHIGO-AI-PARRY): U when a perceived K / L / SP / Kikon hit or a flying projectile will land 5–14 f later (the window), `*ai-ic-parry-p*` 0.6 of the time, never on J links; `:guard 0.0` (no guard rolls in a `:u` form: `ai-guard-k`) | the generic guard rolls turned into blind 20-chain parries |
| Damage | ×1.0 / ×1.0 both forms | Shikai **×1.6 dealt / ×0.8 taken**, KESSA **×1.15 / ×0.9** | the seed gate (a light string, as Rukia's) and the A/B criterion |
| The Shikai Kikon | 月牙十字衝 cinematic | **月牙天衝 with a Gran Rey Cero** (王虚の閃光; a white card, the Cero gathering red in black on the long blade, a black crescent with a BLOOD core) | the user's decision |
| The KESSA Kikon | 血鎖斬月 KESSA ZANGETSU | **the giant pitch-black 月牙天衝** (a 12 m crescent in the cinematic; caption 月牙天衝 / 漆黒); the L's crescent stays 4 m | the user's decision |
| Base horn | none in the Shikai | the half-Hollow's single horn (left) in the Shikai; KESSA adds the right one and the faint left marking | the user's decision |
| Clips | 22 new | 21 (`:ic-awaken` for the cinematic; the SŌGA / JŪJI strikes and both cross copies share `:ic-cross`) | — |
| Pacing log | a `duel ichigo` line per side | not built | the combat log (CATCH, CLONE, cuts lines) and the gate rows' final forms served the tuning |

Shared-file hook points (all generic, no character names): the kit key `:hooks` + `kit-hook` (kit.lisp); `u-press!`,
`guard-held-p` refusing in a `:u` form, the `:step` call in `start-step`, the `:ok` test in `kit-command-ok-p`
(fighter.lisp); the `:parried` call, the `:tick` call in `gauge-system`, the `:parry-block` ward, the `:blade` hit kind
(combat.lisp); `ai-guard-k` and the `:reflex` call (ai.lisp); two `:hud-guard` calls (hud.lisp); `u-chip-p`, the U chip and
the `:deck` call (onehand.lisp); `*char-debug*`, four `*pairs*` and 2125–2134 (debug.lisp); two MANIFEST lines.

## Knobs (`duel/lisp/ichigo.lisp`; debug commands through `*char-debug*`, 74000–75599)

| Knob | Value | Debug |
|---|---|---|
| `*ichigo-mult*` / `*ichigo-taken*` (Shikai) | 1.6 / 0.8 | 74100+k / 74200+k (0.5 + k / 100) |
| `*kessa-mult*` / `*kessa-taken*` | 1.15 / 0.9 | 74300+k / 74400+k (0.5 + k / 100) |
| `*walk-ichigo*` / `*run-ichigo*`, `*walk-kessa*` / `*run-kessa*` | 4.2 / 10.0, 3.6 / 9.0 | — |
| `*chain-u-cost*` / `*chain-catch*` | 20 / 40 | 74500+k / 74600+k |
| `*clone-cost*` / `*clone-reserve*` / `*clone-delay*` / `*clone-dmg*` | 15 / 20 / 20 / 40 | 74700+k (cost) |
| `*kessa-l-cost*` | 30 | 74800+k |
| `*ai-ic-parry-p*` (KESSA's CPU parry chance) | 0.6 | 74950+k (k / 50) |
| `*ai-ic-l-after-k*` (L after a K link, both forms) | 0.3 | — |
| KUSARI-TATE S / A / R | 4 / 12 / 24 (the shared window 4–15) | — |
| HIKI-GUSARI `:pull`, KUSARI-BIKI `:pull` / bind | 1.8 m, 1.6 m / 40 f | — |
| residue life / damage; wall life / width | 90 f / 50; 120 f / 5.0 m | — |

Other commands: 74000+k his tests (human P1 Ichigo, P2's CPU off; `duel-ichigo.json`, `duel-ichigo-portrait.json`), 74900+k
P1's chain gauge = 2k, 75000+f / 75200+f / 75400+f stills of the Shikai Kikon / the KESSA Kikon / the awakening at frame f;
2131–2134 his gate pairings alone (IY IK IR II).

## Measurements (the final build; fixed-dt turbo, NORMAL, cinematics included; debug 2125+k in parallel)

**The seed gate, seeds 1–20 per pairing** (the CPU's rule: awaken on EVOLUTION after 150 taken):

| Pairing | K.O. | Median (s) | Wins P1 / P2 |
|---|---|---|---|
| YY / YK / KK | 60 / 60 | 134.7 / 136.2 / 131.2 (identical rows) | 9-11 / Yama 12 / 13-7 |
| RY / RK / RR | 60 / 60 | 134.1 / 144.9 / 185.6 (identical rows) | Rukia 13 / Rukia 13 / 12-8 |
| IY | 20 / 20 | **143.6** | Ichigo 9 / Yamamoto 11 |
| IK | 20 / 20 | **143.2** | Ichigo 7 / Kenpachi 13 |
| IR | 20 / 20 | **169.6** | Ichigo 9 / Rukia 11 |
| II | 20 / 20 | **155.2** | 10 / 10 |

200 / 200 K.O.; every median in 125–210 s. The G2 cvc references (YY, YK, KK) are byte-identical.

**The awaken A/B** (P1 Ichigo always / never awakening on EVOLUTION vs the opponent's own rule; II: P2 on the rule;
three seed streams, 60 seeds each: 30000+o with o = 100, 300, 500; P1 wins of 60):

| Stream (seed offset) | IY always / never | IK always / never | IR always / never | II always / never |
|---|---|---|---|---|
| 100 | 32 / **30** (+2) | 30 / **37** (−7) | 28 / **36** (−8) | 26 / **27** (−1) |
| 300 | 26 / **35** (−9) | 29 / **27** (+2) | 37 / **31** (+6) | 28 / **26** (+2) |
| 500 | 29 / **30** (−1) | 42 / **34** (+8) | 33 / **37** (−4) | 30 / **28** (+2) |

**Pass**: "never" wins 26–37 of 60 in every cell (the gate: ≥ 20). The old readings hold too: |always − never| ≤ 9 in
every cell, and "never" beats "always" in five cells (IK on stream 100 among them), so on these streams the awakening is
a sidegrade rather than an upgrade.

The history (the same criterion, earlier builds): ×1.0 everywhere and the ranged-share rule: the Shikai won 1–3 of 20 in
IY / IK / IR and the CPU hardly ever awakened; with the timed parry, Shikai ×1.5 / 0.8 and KESSA ×1.3 / 0.8: "always"
ahead by +15 to +23 on most cells, "never" 11–19 in II and 18 in IY (stream 100); Shikai ×1.6, KESSA ×1.15 / 0.8: "never"
18 in II on stream 300, every other cell ≥ 23; KESSA ×1.15 / 0.9: the table above.

## Playtest redesign decisions (the user, 2026-09-29)

Reference images the user supplied live in `.refs/` (git-ignored, third-party art: not committed): `.refs/Ichigo/`
(sleeves; `Getsuga-Tenshō/` the Cero-infused Getsuga charge-up, frame by frame) and `.refs/Ichigo-of-the-Blood-Chains/`
(the KESSA look and blade).

**Shikai**
1. In both forms the sleeves end **just past the elbow** (`.refs/Ichigo/`).
2. **L enters a stance**, as TYBW Ichigo's special in Bleach: Rebirth of Souls: from the stance, the follow-up J / K / L
   each fire a different kind of attack.
3. **The Cero-infused Getsuga Tenshō (base Kikon):** he raises the cleaver, pours reiatsu in from the half-hollow single
   horn, the blade becomes a red slash shot through with a pink-violet glow, and he fires it forward
   (`.refs/Ichigo/Getsuga-Tenshō/` 1–3 break down the charge-up).

**Bankai (KESSA)**
1. **O commands every clone on the field to a self-destructing charge** at the opponent; the damage scales with the
   clone count. **The Kikon's damage is tied to the number of clones on the field when O is pressed**, and its cinematic
   becomes countless clones charging from every direction (reference: Street Fighter 6, Akuma's Shun Goku Satsu).
2. When the Kikon fires automatically because the opponent's HP reached 0 (the Soul Break), its cinematic is the
   **Getsuga Tenshō** instead.
3. **The KESSA Getsuga Tenshō (cinematic):** he raises the blade, reiatsu gathers on it as a black glow, then a
   top-to-bottom vertical cut. It reads less as a flying slash and more as a **huge C-shaped cut left hanging in the air**;
   at the end Ichigo stands in the C's gap and the camera shoots from inside the C out through the gap:
   ```
     V
   Ichigo
     Ʌ
   ```
4. **J / K redesigned:** the openers no longer carry chains that turn them into area attacks.
5. A **flash step (Hoho) also leaves a clone** in front of the opponent.
6. **Clones stay on the field for a while**, then vanish; **at most three** at once.
7. A clone vanishes when: its time runs out, **or** Ichigo himself is hit, **or** that clone deals damage to the
   opponent or is blocked.
8. **Clones answer J / K** with their own attack: **J → a heavy, K → a light**, the reverse of Ichigo himself.
9. **A clone's combo is judged on its own**, and the clone only vanishes after its own combo finishes. A clone starts
   its attack a little later than Ichigo.
10. **SP2 becomes an afterimage state:** for a while every action of his comes with a clone afterimage, so each becomes
    a two-hit attack.
11. **U is a normal guard again**, and **L becomes the old parry (the stance/parry move)**. The parry was far too hard to
    land: the user never managed one, even in practice mode, so it must get much easier.
12. **The KESSA blade** is close to a long rectangular greatsword with **no point and no guard**
    (`.refs/Ichigo-of-the-Blood-Chains/`).

## v2 decisions (the user, 2026-09-29)

The v2 design (the playtest redesign above, written up as tables with six questions) was answered the same day; these
answers override the design's defaults:

1. **Every clone answers each J / K string**, not only the nearest one. Balanced by per-clone damage and the combo's
   scaling, not by overriding the choice: clone hits join the victim's combo (its scaling, the 10th hit a knockdown) and
   grant no KŌSEI, the clones are capped at 3, and a clone hit deals ×0.7 of its written damage (`*clone-scale*`).
2. **The Kikon's Konpaku by the clones at the O press: 0 / 1 / 2 / 3 → 2 / 2 / 3 / 4.** (The design proposed 2 / 3 / 3 / 4;
   one clone is now worth no more than none.)
3. A Step leaves its clone at the take-off point, a Hoho in front of the opponent: yes.
4. The parry (L) may be pressed from blockstun, its window f2–25: yes.
5. Gold and pink-violet are allowed in the Cero Getsuga cinematic only (in play the Getsuga stays mono): yes.
6. The KESSA look follows the figures (barefoot, black / orange split hair, the left half of the face black, flat sideways
   white horns, the red chest emblem): yes.

## v2: built (2026-09-29)

Everything below is in `duel/lisp/ichigo.lisp` and `ichigo-art.lisp`. It replaces §3.3 (L), §4 (the KESSA kit) and §5
(the cinematics) of the design above; the Shikai's J / K grid, the cross links, JŪJISHŌ, SŌGA, the Breaker, the awakening
rule and the Shikai's ×1.6 / ×0.8 stand.

### Both forms: the look

- **Sleeves**: the shihakushō sleeve ends just past the elbow in a flared black cuff (0.20 m, wider than the upper arm)
  with a white lining; the forearm is bare. KESSA's cuff is torn: three ragged teeth, a gap in the lining.
- **The horn**: the half-Hollow's horn is a **flat white blade** from the left temple, swept sideways and back (both forms);
  KESSA adds the right one.
- **KESSA** (`:tag :kessa`, the Shikai's own parts `:tag :shikai`): the hair split, black on his left (a second cap and the
  left spikes in #1A1418); the left half of the face black from the brow to the jaw, that eye's pupil BLOOD (the white
  half-Hollow marking stays only in the awakening cinematic's first beat, `:tag :mark`, hidden in KESSA); the kosode open to
  the navel, a dark red disc (#6E1418) on the sternum and black lines down the abdomen; a ragged white band at the waist;
  dark maroon coils at the neck, wrists and ankles with BLOOD glints (the neat chain links are gone); barefoot, the
  hakama's hem torn.
- **The KESSA blade** `:tensa`: a long straight white slab (#ECECEA), 1.55 m × 0.17 m × 0.025 m, no point, no guard; a
  cold-grey hairline on the edge side; a jagged black line down the flat's middle (5 segments zig-zagging, both faces);
  the end cut square with a 45° notch at the edge-side corner; a white hilt with a faint grey diamond wrap.

### Shikai L: the stance 月待 TSUKIMACHI (RoS's Syzygy; the names are ours)

| | Value |
|---|---|
| Stance `:ic-tsuki` (`:sig`) | up at **f6**, then held **30 f** (a tap) or up to **60 f** while L is held, R 14 (80 f); no defence (hit as neutral); re-aims at 360°/s |
| Follow-ups | the first J / K / L / Step from f6 (buffered from the press): the stance's non-button `:strings` (`:tsuki-j` …), started by the `:tick` hook (`tsuki-step`) |
| J 乱月 RANGETSU `:ic-tsuki-j` | S8 A12 R18, a 2.4 m lunge, four short-blade slashes at f8 / 11 / 14 / 17, 18 each (72), the 4th a stagger; −6 on block, guard 5 each |
| K 月落 TSUKI-OTOSHI `:ic-tsuki-k` | S18 A4 R30, a 3.0 m pounce, both blades slammed: 100, crumple, **guard 30**, −10 |
| L GETSUGA TENSHŌ `:ic-tsuki-l` | the old wave at S8, so L, L fires at f14 (the old L); its own cooldown 100 f (the stance has none); refused with the cue while it cools |
| Step 月渡 TSUKIWATARI `:ic-tsuki-dash` | 3.5 m in the stick direction (neutral: at him) over 12 f, iframes f0–8, TENCHI's afterimages; back in the stance at f6 (a fresh window); **once per stance**, 10 flash step |
| L after a K link | `:ic-tsuki-k2`, the stance entered at f4 (2 f to its f6): every branch combos off K1 / K2 / K3 (host test) |

The CPU's branch (at the stance's f6, in the `:tick` hook): after a K link's hit J 0.5 / K 0.3 / L 0.2; within 3 m
TSUKI-OTOSHI on a guard (or a gauge under 50) else RANGETSU; 3–5.5 m the dash or the Getsuga; farther the Getsuga or the
dash. Its bands: `:sig 3` at 2.6–5 m, `:sig 2` at 5–9 m; L after a K link 0.3.

### KESSA J / K: cuts only (the slab has no point)

| Link | Name | Clip | S / A / R | Dmg | React | Block | Reach | Guard |
|---|---|---|---|---|---|---|---|---|
| J1 | 板薙 ITA-NAGI | `:ic-k-cut` | 8 / 3 / 12 | 30 | flinch | −2 | 2.6 m 110° | 8 |
| J2 | 返板 KAESHI-ITA | `:ic-k-back` | 8 / 3 / 13 | 30 | flinch | −2 | 2.6 m 110° | 8 |
| J3 | 板旋 ITA-SEN | `:ic-k-wrap` | 9 / 3 / 18 | 40 | stagger | −4 | 2.8 m 200° | 8 |
| K1 | 大板 ŌITA | `:ic-f1` | 18 / 4 / 20 | 66 | stagger | −3 | 3.2 m 150° | 14 |
| K2 | 昇板 SHŌ-ITA | `:ic-f2` | 20 / 4 / 24 (enter 6) | 58 | stagger | −3 | 3.2 m 90° | 14 |
| K3 | 天鎖落 TENSA-OTOSHI | `:ic-drop` | 21 / 5 / 34 (enter 7) | 80 | crumple | −20 | line 0.3 → 3.6 | 20 |

Routes on hit before the multiplier: JJJ 100, KKK 204. U is a **normal guard** again (the chain gauge, its HUD skin, the
`:u` / `:hud-guard` hooks and the one-hand U chip are gone).

### KESSA: the clones 分身 BUNSHIN

- **Made by** a Step (a tap or a dash's hop) at its take-off point, at most once per 40 f (`*clone-step-gap*`), free; and
  by a Hoho, 1.6 m in front of the opponent on the line from Ichigo (behind him) through him. At most 3 live
  (`*clone-max*`): a 4th replaces the oldest. Each lives 300 f (`*clone-life*`). A clone is KESSA's body at alpha 0.45, a
  BLOOD rim and a BLOOD ring at its feet; it can't be hit.
- **They answer J / K, reversed** (the user's choice: **every** live clone within 6 m of the opponent answers every
  press): J → a heavy 影断 KAGE-DACHI (`:ic-f1`, S16, 50, stagger; link 3 `:ic-drop` S18, 60, crumple), K → a light 影薙
  KAGE-NAGI (`:ic-k-cut`, S8, 26, flinch; link 3 `:ic-k-wrap` S9, 32, stagger), **6 f after the press** (`*clone-lag*`),
  closing in up to 3 m per link. A J press's heavy lands at f22, inside Ichigo's J1 flinch; a K press's light at f14,
  before his K1; the opponent's J1 (7 f) still beats it.
- **Their strings are their own**: each press is one link (up to 3, in order); a link opens the next only on its own
  contact (hit or block), after which every queued press comes out. Contact → the clone finishes its string and fades;
  a whiff → it idles where it stands; Ichigo really hit (not a block) → every clone vanishes; its time up → it fades.
- **A clone's hit** is an `:ic-hit` hazard with the answer's own hit window (its volume, its reaction) at **×0.7**
  (`*clone-scale*`) damage and guard value: guarded facing Ichigo wherever the clone stands (`:src`), a hazard blockstun,
  no KŌSEI, in the victim's combo (its scaling; the 10th hit a knockdown; Burst from the 2nd).
- **The worst case** (debug 74008: three clones beside him, 2.2 m from an idle Kenpachi, a J string): J1, J2, three
  heavies, J3, three heavies = 9 hits, **268** (Kenpachi's Reishi 1300 → 1032); a K string with three clones 244. The
  theoretical worst (JKK, the 10-hit cap) ≈ 290. The game's other max strings (3 links × the form's damage): Yamamoto
  227–295, Kenpachi 210–300 (his Bankai 444), Rukia 239–343, Senjumaru 276–294, the Shikai 339. At ×1.0 the J string would
  be 343 (the top of that band), so the knob is ×0.7.

### KESSA L: the parry 鎖盾 KUSARI-TATE, made much easier

| | Value |
|---|---|
| Input | L from idle / walk / run / guard, **and from blockstun** (the blockstun ends; the `:tick` hook starts it) |
| Window | **f2–25** (24 f, twice the old 12), 360°: the move's own `:params :window` (shared hook H4) |
| Cost | **10 guard gauge** on frame 0 (refused below 10 or guardless) |
| Whiff | S2 A24 R18 (44 f), hit as neutral outside the window |
| Catch (a guardable melee hit) | no damage; the attacker staggers **40 f**; **+20 gauge** (net +10); a 12 f hitstop, a white flash, a bright "kiin" (`:parry-ting`), 0.3 s at 0.4× slow motion; then the counter |
| Ranged / hazard in the window | blocked with no blockstun (`:parry-block`), its guard value drained |
| Counter 残月返し ZANGETSU-GAESHI | the `:land` string: a pull to 1.6 m, S6 A3 R22, 80, crumple: **+15**, J1 combos; brush callout 鎖盾 |
| Tells | on press the chains flare and a soft rising shimmer (`:parry-open`); while the window is open **a white rim light fading linearly** (its brightness is the timer) |
| Practice mode | a missed parry says **LATE** (hit within 3 f of pressing L) or **EARLY** (hit in its recovery) over his head |

The CPU: L when a hit it can see (as perceived) lands 4–22 f out, one roll per opponent action at 0.35; from blockstun
after a blocked K link, 0.3, pressed so the string's next hit falls in the window.

### KESSA SP2: 残像 ZANZŌ

`:ic-k-zanzo` (S12 R16, 2 bars, refused while it runs): for **360 f** every attack of his (J / K links, SP1, the O
strike, the counter; not the Breaker) is echoed **10 f later** by an afterimage (his body at alpha 0.35 replaying the move
where he stood then) whose hits deal **×0.5** damage and guard value (a hazard: guarded facing him, gone if he is hit,
no KŌSEI, in the combo). J1's echo hits at f18; RANGETSU's four at f18 / 21 / 24 / 27. The HUD shows a white bar
draining under the clone pips.

### KESSA O: 影討 KAGE-UCHI, and its Kikon 千影 SEN'EI

- The rush `:ic-k-kikon`: aura 6, a flash-step dash at 30 m/s ≤ 14 f (8.6 m), a vertical cut S7 A3 R24, 70, knockback,
  −14, guard 20, cooldown 90.
- **At the O press** (a neutral rush or the ender) every live clone charges (the lead one mid-string included) and bursts
  on the strike's frame: the strike deals **70 + 30 × n** (its bonus, one hit, one scaling step); the clones add no hit
  and no timing of their own, so the O ender and the held-O Kikon are the universal ones.
- **The Kikon's worth**: **2 / 2 / 3 / 4 Konpaku** for 0 / 1 / 2 / 3 clones at the press (`*clone-konpaku*`, the user's
  table); a Soul Break stays the form's 3 + 1 = 4.
- **千影** (192 f; SF6's Shun Goku Satsu): beat 0; the plaza drops to black with the victim alone, Ichigo gone in a
  flash step; the camera orbits him while clones charge through him from a 9 m ring, four waves of three, then twelve at
  once; one white frame; behind Ichigo, low, facing away, the victim collapsed beyond: the brush 千影, the hanko, the
  impact, the Konpaku; wide.
- **His Soul Break** plays **漆黒の月牙天衝** (the kit's `:soul-break-cine`, shared hook H2; 180 f): the slab raised
  overhead, a black glow gathering on it; a black card, 月牙天衝 / 漆黒; wide and side-on, one top-down cut whose trail
  keeps going round into a huge C hanging in the air (a vertical ellipse through the victim, 3.2 m tall about h 2.4, its
  gap ±32° round Ichigo: the V tip over his head, the Ʌ tip at his knees, the part under the plaza a crack); the camera
  inside the C looking back through the gap at him; the impact; the C burning away from both tips.

### The Shikai's Kikon: 王虚の閃光を込めた月牙天衝 (186 f, rebuilt from the reference frames)

Beat 0 and the white caption card as built; **the raise** (f70–100, a black card, low in front, a violet haze at one
side): the cleaver overhead one-handed (`:ic-cero-raise`), a gold orb growing on its tip, a thread of gold light from the
horn's tip to it; **the ignition** (f100–128): the orb bursts into a hooked gold flame crescent with a red inner band
curling back over the tip, his body swallowed in gold-orange flame, then (f116) the blade a red slash in a pink-violet
glow; **the swing** (f128); **the Cero Getsuga** (f138–160, from behind and below him, the sky pale pink): a violet ring
8 m across round a dark blood-red disc, four gold spikes at its diagonals (a diamond), turning as it flies; the impact;
the aftermath with violet ash. The palette exception (gold #FFC23A, violet #C040E8, the disc #5A0A10) lives only in this
cinematic's `defparameter`s.

### HUD and one hand

The guard bar is the universal one in both forms. KESSA's kit-meter row: three clone pips (lit per live clone, each
with a thin arc of its life, pulsing at 3), ZANZŌ's white bar under them, the label `BUNSHIN xN`; on an O press the pips
flash and the label adds the Kikon's worth. One hand: rest is guard again; the thumb ring shows three BLOOD dots for the
clones (`:deck`).

### Code: the shared hook points

The design listed six (H1–H6). Four were not needed: the `:tick` hook (which runs after the hits of every step) reads
the J / K press edges for the clones (H3), starts the parry from blockstun (H5) and the stance's follow-ups (H6), and
sets the Kikon's worth when it sees the O rush start (H1). Two generic points were added, both inert for a character
that doesn't use them:

| # | Where | Key | Change |
|---|---|---|---|
| H2 | kit.lisp `kit-kikon-cine` | kit `:hooks :soul-break-cine` (a cinematic's name) | a Soul Break plays the form's own cinematic, else its Kikon cinematic (as before) |
| H4 | rules.lisp `parry-frame-p`, fighter.lisp `defender-state` | move `:params :window (lo hi)` | a parry move's own window, else the shared `*parry-window*` (GOKUI GAESHI unchanged) |

Existing hooks used: `:tick`, `:step` (the Step clone), `:ok` (the parry's price, ZANZŌ refused while on), `:parried` (the
catch), `:hit` (a clone learns its contact), `:struck` (a real hit clears the clones; the practice judge), `:deck`, the
kit `:meter :draw / :label`, the hazard `hook` / `data` (clones, afterimages and their hits), the AI `:reflex`.

### Knobs (`duel/lisp/ichigo.lisp`; debug 74000–75599)

| Knob | Value | Debug |
|---|---|---|
| `*ichigo-mult*` / `*ichigo-taken*`; `*kessa-mult*` / `*kessa-taken*` | 1.6 / 0.8; **1.25 / 1.0** (v1: 1.15 / 0.9) | 74100+k … 74400+k (0.5 + k / 100) |
| `*tsuki-up*` / `*tsuki-tap*` / `*tsuki-max*`; `*tsuki-dash-fs*`; `*tsuki-getsuga-cd*` | 6 / 30 / 60; 10; 100 | — |
| `*kessa-parry-cost*` / `*kessa-parry-catch*` / `*kessa-parry-stun*`; the window | 10 / 20 / 40; f2–25 | 74600+k (catch); 74500+k (window f2–(k+1)) |
| `*clone-max*` / `*clone-life*` / `*clone-step-gap*` / `*clone-lag*` / `*clone-lunge*` / `*clone-answer-range*` | 3 / 300 / 40 / 6 / 3.0 / 6.0 | 74700+k (life 10k) |
| `*clone-scale*`; `*clone-burst-dmg*`; `*clone-konpaku*` | 0.7; 30; (2 2 3 4) | 74910+k (k / 20); 74800+k |
| `*zanzo-life*` / `*zanzo-lag*` / `*zanzo-mult*` | 360 / 10 / 0.5 | — |
| `*ai-ic-parry-p*` / `*ai-ic-parry-bs-p*` / `*ai-kessa-o-p*`; KESSA's `:o-ender` | 0.35 / 0.3 / 0.04; 0.6 | 74950+k (k / 50) |

Other commands: 74000+k his tests (0 / 1 the forms 3 m from an idle Kenpachi, 2 Kenpachi's K1 into KESSA (the catch), 3
Yamamoto's wave into the parry, 4 the Breaker through it, 5 JUJISHO's cut, 6 the Shikai 8 m out, 7 / 8 KESSA with three
clones 8 m / 2.2 m from an idle Kenpachi (8: the worst-case J string), 9 KESSA 4 m from Rukia, 10 Kenpachi's J1 into
KESSA); 74080+k the 60-seed gate of pairing k (one A/B stream in one run); 74900+k (k 0–3) P1's clones = k, 74905 logs
P2's combo; 74989 / 74990+k pose stills (the camera turned 90°); 75000 + 150 i + k stills of cinematic i (0 the Cero
Kikon, 1 千影, 2 the awakening, 3 漆黒の月牙天衝) at frame 2k.

### Balance: what moved, and the measurements (v2)

Built on main 97f40c1 (Kenpachi's CPU pressing in cups 2 / 3), merged into this branch before tuning. Every number
below is measured (fixed-seed CPU vs CPU, NORMAL, turbo, cinematics included).

| What | First built | Now | Why |
|---|---|---|---|
| `*clone-scale*` | ×1.0 (heavy 50) | **×0.7** | the worst case with every clone answering (above): ×1.0 put a J string with three clones at 343, the top of the game's band |
| The clones' presses | one latched press (like his own latch) | **a queue, one link per press** | 6 f behind him, his second and third presses both fell in the clone's link 1: clones played two links of a three-link string, and O always found them spent |
| KESSA's CPU | intents A2 P3 Z1 D2, bands with waits, dash 0.3 | **A3 P4 Z0 D1**, no waits under 9 m, dash 0.6, back-dash 0.2 | II ran 240–258 s: the mirror stood apart |
| KESSA's `:o-ender` | 0.15 + 0.15 n (the design) → 0.3 | **0.6** | the O ender is the Kikon in CPU play (the clones are rarely banked, so it is mostly worth 2): II 238 → 205 s |
| `*kessa-mult*` / `*kessa-taken*` | 1.15 / 0.9 | **1.25 / 1.0** | II 205 → 190 s with IK still 147 s |

**The seed gate** (seeds 1–20, 2125+k one pairing per run):

| Pairing | K.O. | Median | Wins P1 / P2 |
|---|---|---|---|
| IY | 20 / 20 | **144.3 s** | Ichigo 8 / Yamamoto 12 |
| IK | 20 / 20 | **147.1 s** | Ichigo 8 / Kenpachi 12 |
| IR | 20 / 20 | **175.0 s** | Ichigo 6 / Rukia 14 |
| II | 20 / 20 | **189.6 s** | 9 / 11 |
| SI | 20 / 20 | **176.7 s** | Senjumaru 17 / Ichigo 3 |
| YY / YK / KK / RY / RK / RR | 120 / 120 | 134.7 / 125.4 / 125.1 / 134.1 / 134.4 / 185.6 | main's rows (the shared hooks are inert) |
| SY / SK / SR / SS | 80 / 80 | 143.2 / 133.0 / 173.7 / 195.3 | Senjumaru 10 / 8 / 14, SS 7-13 (main's rows) |

**The awaken A/B** (three seed streams of 60, `30000+o` with o = 100 / 300 / 500 and `74080+k` (60 seeds in one run);
P1 Ichigo "always" / "never" awakening on EVOLUTION vs the opponent on its rule; SI: P2 Ichigo; Ichigo's wins of 60):

| Stream | IY always / never | IK | IR | II | SI |
|---|---|---|---|---|---|
| 100 | 18 / **27** | 26 / **23** | 21 / **32** | 31 / **40** | 14 / **34** |
| 300 | 16 / **24** | 20 / **21** | 22 / **29** | 24 / **42** | 15 / **22** |
| 500 | 17 / **27** | 21 / **25** | 17 / **34** | 26 / **42** | 15 / **33** |

**Pass**: "never" wins 21–42 of 60 in every cell (the gate: ≥ 20). The tightest cell is IK on stream 300 (21), against
main's new Kenpachi CPU. **Reading**: "always" is behind "never" in 14 of the 15 cells: between CPUs the v2 awakening is
the weaker choice (the KESSA CPU rarely banks clones, so its Kikon is mostly worth 2, and its reach is shorter than v1's
chains). The user's rule only forbids the opposite; the levers if it should be stronger are `*kessa-taken*`, the clone
banking in its AI and `*clone-scale*`.
