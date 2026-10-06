# SOUL DUEL: Zaraki Kenpachi's Bankai (卍解) and 片腕 KATAUDE

Status: **built 2026-09-28** (the user asked for it; the design of 2026-09-28 with the user's decisions of the same day,
§"User decisions" below, which override the body where they differ). It sits on the user's decisions of 2026-09-27 (the
research report `docs/research/tybw-characters/report.zh-TW.md`, questions 1–5 at their defaults) and on the general **Soul Break
rule** built just before it (DUEL_DESIGN §2): a Soul Break auto-plays the attacker's current form's Kikon cinematic and
costs the form's count + 1, with the per-event cap 5 for Soul Breaks only. The body below is the design as approved
(numbers were proposals; the as-built values are in "Built: deviations" and in `duel/lisp/tuning.lisp` /
`duel/lisp/ken.lisp`); the sections at the end record the user's decisions, what was built differently and the
measurements.

## 0. Frame of reference

- Conventions: DUEL_DESIGN §0 (60 Hz, S/A/R, move frame 0 = first frame). The strings budget of DUEL_STRINGS §2.1 holds for
  every new form (host-tested per form, as today).
- Canon ([V] verified in research, [G] our interpretation, [A] anime-only): ch. 669 "Blade II": beaten and bleeding out,
  Yachiru (Nozarashi) names the Bankai; crimson skin, horns; he bites Gerard's arm off, cuts through forearm and shield
  together, punches him off Wahrwelt, cleaves the Vollständig Gerard in two [V]. Ch. 670: the right arm bursts from the
  inside; Yachiru apologises [V]; "on the 4th attack" is a search-snippet claim only [unverified; the count is decided
  at 4 by the user, so this stays a note]. Ch. 671: one-armed, grabs Gerard's feet [V]. Anime ep. 44 (Part 4 ep. 4): the
  Kusajishi forest vision, the distorted doubled call, irisless eyes, the broken cleaver with a hilt like the first
  Zangetsu [A]. No official Bankai name: the UI uses the existing 卍解 bitmap and no name.
- Why "stronger" is allowed here: Kenpachi is exempt from the sidegrade rule (user). The cost is paid in the same
  match: ≤ 20 s of power, red and self-burning the whole time, then 片腕 until the end.

## 1. Entry and the cinematic

### 1.1 Rules
| Rule | Value |
|---|---|
| Command | **P** (Awaken; KP+ / Back / LS+RS; the phone's AWAKEN chip, held 300 ms) |
| Condition | form `:nomihose` (cup 3) **and** ~~red (`red-p`, Reishi < 30 %)~~ **at most 4 of his own Konpaku left** (`*bankai-konpaku*` 4; the user's decision 2026-09-28, 「劍八的卍解條件從紅血改成在剩餘四魂以下」) **and** free (`:idle` or `:guard`, DRINK included; not `:guard-hit`, not a move, not a run). No gauge. Pure rule `bankai-allowed-p (free konpaku)`; the kit key `:bankai-form :bankai` exists only on `:nomihose` |
| Once | structural: `:bankai` and `:kataude` have no `:bankai-form`, and there is no way back to cup 3 |
| On entry | form `:bankai`; the kit meter becomes the arm: **4 pips** (`gauges-meter` 4, `gauges-meter-idle` 0 = the crack clock); ~~no heal~~ **his own Konpaku set to 1 and his Reishi refilled to full** (the user's decisions 2026-09-28, below); guard gauge, Reiatsu, flash-step, cooldowns untouched; NOME is gone (the meter slot now holds pips) |
| Then | the cinematic (sim frozen), both fighters idle after it (as every awakening) |
| Prevention (the opponent) | stay out of range until NOME drops under 50 (cup 3 lasts 5–10 s); or take his Konpaku first (with 4 or fewer left a Kikon or a Soul Break is close to the K.O. anyway) |

### 1.2 Cinematic `ken-bankai-cine` (186 f, unskippable like every battle cinematic (DUEL_DESIGN §3); the review-3 pacing: long holds, few shots)
| Shot | Frames | What | Canon source |
|---|---|---|---|
| beat 0 | 0–12 (12) | Kenpachi down on one knee, head bowed, the grin gone; ink-blood droplets; negative 2 f; silence | ch. 669: beaten, bleeding out [V] |
| the forest | 12–58 (46) | a **white card** of black ink trunks (Kusajishi, mono: no pink, the 3-spot rule of STYLE_STORM §A.2), white petals on twos; a small ink child silhouette in front of him, 2 drawings visible, then gone; the `:yachiru-call` sting (a detuned, doubled chirp chord: the "multiplicity"); a small brush sub-line "KEN-CHAN" | anime ep. 44 [A]: the forest recreation, the distorted voice |
| the burst | 58–78 (20) | he rises; the body swaps to the crimson variant on f58 (`model-body`), the BLOOD pillar (the Nozarashi pillar in the `:oni` palette), two rings, a 1 f negative then a 12 f manga page, `:awaken-boom` + the laugh at 0.7 pitch | ch. 669 [V]: the red flush and the shockwave |
| close, low | 78–108 (30) | wide-angle on the face: horns, **white irisless eyes**, the shout face held; silence 20 | [A]: irisless eyes; [V]: horns |
| caption card | 108–166 (58) | black card, BLOOD back-rim, the silhouette with the broken cleaver; brush column **卍解** (reading "BANKAI"), the red 鬼 hanko | ch. 669 [V]: Yachiru names it Bankai (no name) |
| wide | 166–186 (20) | from behind, the red pillar on ones, the opponent small in the distance | — |

Clips: `:ke-release` (head down, from the Nozarashi awakening) held for beat 0; `:ke-b-stance` from the burst on. Cine
primitives all exist (`card`, `back-rim`, `caption`, `impact-frame`, `lens`, `silence`, `hold-both`); new: a `:forest`
card look (ink trunks, petals) and the child silhouette as a flat ink cut-out (Q3).

### 1.3 Framing fix (2026-09-28): he stays in his own shots

User report: 「劍八覺醒的毀魂技在準備揮刀的動畫看不到自己」, then 「劍八毀魂技無論常態還是始解卍解，在手持模式都有類似的運鏡問題」.
In MAPPUTATSU's wind-up (the black card, f12–68) he was out of frame on a phone (390×844: only an arm and the blade at the
edge) and at the frame's edge in landscape; the same on the phone in the Nozarashi sky split's card (f12–68) and at the
end of the base Kikon's card, where the charge clip carries him forward.

**Root cause**: `shot-on` aims at a scripted point (`:off` / `:ahead`, composed on 16:9), while the clips' root motion
(the leap, the charge, the cleave: up to 1.4 m) carries the body away from his feet; and a portrait close-up keeps the
script's narrow lens (the user's earlier decision: close-ups may crop the body), whose frame is only ~0.8 m wide at 4 m.
**Fix** (render-side, every cinematic, both orientations): `shot-on` records its subject (`*cine-subject*`, cinema.lisp;
`shot-pair` clears it) and `%keep-subject` (camera.lisp, after the portrait dolly) slides the eye and the aim sideways
so his posed pelvis stays within `*cine-keep*` **0.55** (landscape) / `*pt-cine-keep*` **0.3** (portrait) of the frame's
half-width at his depth. Nothing moves while he already is (so the approved compositions stay), close-ups still crop
the body, the sim never reads the camera (G2 unchanged by it). Checked: Kenpachi's four Kikon / Soul Break cinematics
(base, sky split, MAPPUTATSU; 片腕 reuses the base one) and the Bankai and Nozarashi entries, and Yamamoto's six
cinematics in portrait: only Kenpachi's leap / charge shots had left the frame; Yamamoto's were already in shot.

## 2. The arm meter 「腕」 UDE

| Rule | Value (knob) |
|---|---|
| Pips | **4** (`*arm-pips*`), shown in the kit meter slot |
| What spends a pip | **L**, **SP1**, **SP2**, **I** (the Breaker's aura frame) and the **neutral O**: one pip each, on frame 0. A **J / K string** with a K link or the O ender in it (K, KK, KKK, KJJ, JKK, JJK, JJJ + O …) costs **one pip in total**, owed from its first K link (or its O ender) and charged **once, when the string ends**: completed, broken off (a hit on him, a Burst), stopped by a whiff, or cancelled into an SP / L (which pays its own pip on top). The charge burns the Reishi self-cost and flashes the crack like any spend. Hit, block, whiff, clash or parried: charged all the same (the playtest decision 2026-09-28, §"Playtest decision" below) |
| What doesn't | J links, Step, dash, Hoho, Burst Reverse, U (DRINK), P, the SP2 punch (part of SP2: a `:land` follow-up a hook starts) |
| Self-cost | each spend burns **30** Reishi (`*arm-self*`; `burn`: never below 1, no gauges, no NOME, no heat) |
| No pip left | a pip command is refused like a missing Reiatsu bar (`kit-command-ok-p`): a lower command may start instead; a K link (K1 or a latched one) needs a pip available to start, else the string ends at that link (the press is eaten, like the old button after a switch). While a string owes its pip, an SP / L cancel out of it needs a second pip (the owed one is reserved); its O ender does not |
| The crack | a pip cracks (−1, no self-cost) when **300 f** (`*arm-crack*`) pass without a spend; every spend or crack restarts the clock; the clock is paused while he is locked (`fighter-lock` > 0: the 48 f reset neutral) and while the sim is frozen (cinematics). Longest Bankai: 4 × 300 = 1200 f = **20 s** of play |
| Burst trigger | pips reach 0 (a spend or a crack) → **pending**, remembering the move running at that moment (or none). It fires on the first frame he is not in that move, not in a reaction / blockstun / air / down / wake-up, and not in a Hoho. So the 4th strike always comes out in full, and a Kikon rush started earlier finishes |
| Konpaku lost in Bankai | ~~a Kikon or Soul Break on him settles as usual, then the arm bursts quietly at the reset~~ **moot** (the user's decision 2026-09-28): he has 1 Konpaku, so any Kikon or Soul Break on him is the K.O. |
| Strings | **one pip per string**: JJK, KJJ, JKK, KKJ, KKK and any of them + the O ender cost 1; JJJ costs 0 (JJJ + the O ender 1). So the four pips are four strings, or strings and specials mixed (was: one per K link, KKK + O = the whole arm) |
| DRINK | kept (cup 3's U, the `:drink` passive, existing code): a drunk hit costs half its damage for real (he is red: it can Soul Break him) and the guard value; the other half goes nowhere (the kit's `:meter-gain` is NIL). It never touches the pips |

Rejected: "a drunk hit restarts the crack clock" (it would let the opponent's own pressure extend the Bankai past 20 s;
one line to add later if playtests want DRINK to matter more).

## 3. The Bankai move list (form `:bankai`, ×1.20)

Inherits `:nomihose` (so `:drink`, the drink clip, the 20 % blade chip, the respect callout), and lists **every
command as its own** (nothing inherited is derived or reached). Kit keys: `:awakening t :mult *bankai-ken-mult*
:heal 0 :form-name "BANKAI" :kikon-konpaku 4 :passives (:projectile-cut :drink)` (no `:cut`: the pip K's carry their
own doubled guard values) `:meter (:name "UDE" :max 4 :start 4)` (**no `:ladder`**) `:meter-gain nil` (explicit)
`:pips (:n 4 :crack 300 :self 30 :burst-self 60 :burst-stun 40 :to :kataude :cmds (:f :sig :sp1 :sp2 :breaker :kikon))`
`:body :kenpachi-oni :weapon :ke-broken :stance :ke-b-stance :aura :oni :cine ken-bankai-cine
:enter-hook ken-bankai-enter :opp-intent (:zone 2 :defend 2)`.

Identity: the oni. Broken-blade hacks and fists, one gouge, one drop, then the teeth, the shield-and-all cut, the punch,
and the split. **Rend** (a new hitwin flag `:rend`): armour and Kenpachi's stance don't stop it (armour → a hit, the
stance → a stance break, like a Breaker); a guard, DRINK, West's ward and a parry still do.

| Input | Name | Clip | S/A/R (enter) | Dmg (×1.2) | React | Blk | Whiff | Volume | Guard | Pip | Through guard / armour | Pose (one line) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| J1 | 叩き斬り TATAKI-GIRI `:ke-b-j1` | `:ke-q1` | 8/3/12 | 38 (46) | flinch | −2 | 20 | **1.28 m** 100° (was 3.2), lunge 1.0 | 8 | — | chip 20 % | the broken cleaver hacked down from the shoulder, lunging, head low like a beast |
| J2 | 薙ぎ払い NAGI-HARAI `:ke-b-j2` / `-j2s` | `:ke-q2` | 8/3/13 | 38 (46) | flinch | −2 | 21 | **1.28 m** 100° (was 3.2) | 8 | — | chip 20 % | the backhand sweep back across, the torn haori whipping |
| J3 | 拳骨 GENKOTSU `:ke-b-j3` (ender) | **new** `:ke-b-fist` | 9/3/18 | 50 (60) | stagger | −4 | 26 | **0.8 m** 60° (was 2.0; its own close clip `:ke-b-hook`), lunge 0.6 | 8 | — | chip 20 % | a left hook to the face, the cleaver held out wide in the right; the ink impact mark on the jaw |
| K1 | 大鉈 ŌNATA `:ke-b-k1` | `:ke-f1` | 17/4/20 | 120 (144) | stagger | −3 | 32 | **3.4 m** 120° (was 3.6) | **28** | 1 | ×2 guard, chip 20 %, **rend** | the hatchet chop: wound over the right shoulder, the whole torso turning, a crack of red light along the forearm |
| K2 | 抉り上げ EGURI-AGE `:ke-b-k2` / `-k2s` | `:ke-f2` | 20/4/24 (6 → 14) | 100 (120) | stagger | −3 | 36 | **3.0 m** 90° (was 3.2) | **28** | 1 | ×2 guard, chip, rend | from the floor up, gouging; he rises on his toes, 4 f hold at the top |
| K3 | 叩き落とし TATAKI-OTOSHI `:ke-b-k3` (ender) | `:ke-r-f2` (clip-s 21) | 21/5/34 (7 → 14) | 150 (180) | crumple | −20 | 46 | line 0.3 → **3.7** (was 4.0) | **36** | 1 | ×2 guard, chip, rend | the cleaver high in both hands, held 3 f, dropped; the victim crumples |
| L | 噛み千切り KAMICHIGIRI `:ke-b-bite` | **new** `:ke-b-bite` | 10/3/28 | 120 (144) | crumple | — | 34 | 1.5 m 60° | — | 1 | **unguardable** (guard, DRINK, ward, parry, stance, armour all fail; Step / Hoho iframes dodge) | a lunge, the left hand clamps the opponent's arm, the head drives in, a tearing jerk back (a BLOOD spray) |
| Shift+K | 盾ごと TATE-GOTO `:ke-b-split` | `:ke-meteor` | 24/4/30 | 260 (312) | knockdown, kb 3 | Guard Break | 36 | vertical line 0.3 → 6.0, 1 m wide | — | 1 + 1 bar | `:guard-crush` over the whole line (Guard Break 50 f, −35), rend | the two-handed overhead through guard and arm together; the ground splits 6 m (the meteor's look, shorter) |
| Shift+L | 殴り飛ばし NAGURI-TOBASHI | `:ke-charge` (as written) → `:ke-b-punch` | charge 14 / dash 26 / 24; punch 6/3/30 | 25 + 150 (30 + 180) | the punch: knockback **6 m** | −16 | as the charge | charge as built; punch 2.0 m 90° | 22 | 1 + 2 bars | punch: rend; the charge still guard-crushes when held at its dash (as built) | the charge, then a **left** straight into the chest (the `:ke-b-fist` clip at clip-s 9 → 6), the victim sent flying |
| I | SHOULDER CHARGE `:ke-breaker` (as written) | `:ke-breaker` / `:ke-shoulder` | §4 | 150 | Guard Break | | | | 35 | 1 | the Breaker's own rules | as base |
| O | Kikon **真っ二つ MAPPUTATSU** `:ke-b-kikon` | `:ke-n-leap` / `:ke-stance-cut` | LEAP CLEAVE as built: aura 8, 18 m/s ≤ 30 f locked, 11/3/24 | 70 | knockback | −14 | 30 | 3.08 m 160° | 20 | 1 | the §2 Kikon rule | the leap, the widest cleave; its Kikon cinematic is §3.1 |
| U | DRINK | `:ke-drink` | as built | half taken | | drink-adv −4 | | front 200° | pays the gauge | — | a guard | head thrown back |

Notes:
- `:ke-b-kikon` = `(defmove-copy :ke-b-kikon :ke-kikon-n :callout "MAPPUTATSU" :cine ken-oni-kikon-cine)`: `defmove-copy`
  takes override keys (a 1-line change: the overrides go first in the plist, so `&key` takes them).
- SP2 reuses `:ke-charge` as written with the Bankai string `(:ke-charge :land :ke-b-punch)` first in its `:strings`,
  so `ken-flurry` (which starts `(kit-next kit :ke-charge :land)`) starts the punch, not the flurry. No new hook.
- The punch: the charge contact is a flinch (18 f); the punch hits 6 f later. Charge + punch on hit 30 + 180 = 210 and a
  6 m knockback: the "off Wahrwelt" punch. No O after it (not a string).
- The bite's follow-up: the victim crumples 40 f from the hit (f10 → free at f50); Kenpachi is free at f41: **+9**,
  so his J1 (S 8) combos with 1 f to spare. That makes the bite a Breaker-like read: a guaranteed string after it.
  Knob: R 28 → 30 removes the guaranteed follow-up.
- Budget check (§2.1): J1 8, J2 8, J3 9 (7–10 / 7–9 / 8–10), K1 17 (16–20; K1 − J1 = 9 ≥ 7), K2 20 / K3 21 (19–22, S_eff
  14), R and block advantages exactly the budget's. K2 / K3 combo after a J (A 3 + 14 = 17 ≤ 17) and a K (≤ 21).
- Route damage on hit, ×1.2, before Cornered: JJJ 151, **JJK 271 (1 pip)**, KJJ 250 (1), KKJ 324 (1), JKK 346 (1),
  **KKK 444 (1)**; + the O ender 76 (inside the string's pip; the playtest decision 2026-09-28: one pip per string, was
  1 per K link and 1 for the ender). Cup 3 for comparison: KKK ≈ 360 with its rift, JJK ≈ 246.
- Blocked: J 8 each; K 28 / 28 / 36; KKK blocked = 92 (not a crush from full: the report's "raise the drain, never
  crush outright" rule), into West's ward ×1.1 = 101 (§10 M4).

### 3.1 The Bankai's Kikon cinematic `ken-oni-kikon-cine` (162 f; also the Bankai's Soul Break cinematic under the new rule)
| Shot | Frames | What |
|---|---|---|
| beat 0 | 0–12 | the leap clip held, negative 2 f |
| caption card | 12–68 (56) | black card, BLOOD back-rim, the oni silhouette with the broken cleaver raised; brush 卍解 with sub **MAPPUTATSU**, the red 鬼 hanko; silence |
| the cleave | 68–102 (34) | one vertical cut: a negative, then a 12 f manga page; a white line (ink borders) splits the victim and the **screen vertically**, the halves shear apart; the Konpaku shatter; `:kikon-slash` + `:ground-crack` (ch. 669: the Vollständig Gerard cut in two, [V]) |
| side | 102–132 (30) | from the side, the split in the ground, ash |
| end | 132–162 (30) | Kenpachi, head back, the laugh (`:laugh` at 0.8 pitch) |

It is `ken-sky-split-cine` re-cut (the split turned vertical, `:oni` colours): no new primitive except the vertical
variant of `vfx-sky-split`.

## 4. The burst

| | Value |
|---|---|
| When | the pending burst fires (§2) |
| Effect | form `:kataude` (`set-form`); burn **60** (`*arm-burst-self*`, leaves ≥ 1); a self-inflicted **40 f crumple** in place (`*arm-burst-stun*`, `set-reaction :crumple`, clip `:sh-crumple`), no slide. Hits on him during it are ordinary hits (a combo starts; Burst Reverse from hit 2 as usual) |
| Look | a 1 f negative, then a 12 f manga page (`*impact-next*`, as NOMIHOSE's entry); the right forearm splits along its four cracks: BLOOD spray (`impact-splash` from the forearm, 16 droplets), ink shards, the red aura collapsing into falling flecks; the brush callout "GOMEN NE, KEN-CHAN" (small, 1.5 s: Yachiru's apology, ch. 670 [V]); `:arm-burst` sound |
| Why it is punishable | 40 f on a red (often 1-Reishi) Kenpachi: a string lands and its O ender is taken on a red victim (always), so the burst usually costs him the opponent's Kikon count (the Gerard slash). At 8 m after a reset, or far away, nobody can reach him: that is the jackpot case (the last pip spent on a Kikon) |

## 5. 片腕 KATAUDE (form `:kataude`, the rest of the match)

`(defkit :kenpachi :kataude :inherit :base :awakening t :form-name "KATAUDE" :kikon-konpaku 3 :mult 1.0
:reach-mult *kataude-reach* :body :kenpachi-oni :weapon :ke-broken :hide (:crack-1 :crack-2 :crack-3 :crack-4) :aura nil
:commands (:q :ke-j1 :f :ke-k1 :sp1 :ke-buttagiru :sp2 :ke-charge :sig :ke-stance ...) ...)`:

| Input | Move | Rule |
|---|---|---|
| J / K grid | base ARAGIRI, KAESHIGIRI, ŌBURI, KIRIAGE, BUNMAWASHI **derived at reach ×0.7** (`*kataude-reach*`, startup +0): J1 1.82 m, K1 2.10, K3 1.96 | the ruined arm can't extend; the frame budget is untouched (S unchanged) |
| J3 | KENKA-GERI **as written** (0.88 m since the J cut; 2.2 m before) | a leg: the arm doesn't matter (listed as its own move) |
| L | the stance "KITTE MIRO YO" derived (cut 1.96 m) | he still takes hits smiling |
| Shift+K / Shift+L | Buttagiru / charge → flurry, derived | SP2 2 bars (awakened) |
| I | the shoulder charge **as written** | the Breaker strike must out-reach its 2.2 m trigger (§10 B2) |
| O | **CHARGE** `:ke-kikon` **as written** (armour 1 hit), Kikon **3**, the base Kikon cinematic `ken-kikon-cine` reused | the universal awakened count |
| U | a normal guard | no DRINK: the cleaver has stopped drinking |
| Damage | ×1.0; Cornered as always | |
| Gone | NOME, the cups, the cut, the rift, Split the Meteor / the cash-out, projectile cut, the aura | |

New clips: **0**. Later (the user's decision): the bite and the foot-grab throw ("grab the feet and heave", ch. 671).

## 6. Kikon counts and events

| Form | Kikon | Soul Break (count + 1, cap 5) |
|---|---|---|
| NOMIHOSE (for reference) | 4 | 5 |
| **Bankai** | **4** (the active cap is 4) | **5** |
| **片腕** | **3** (the universal awakened value) | **4** |

- Read at rush start (`fighter-kikon-n`) as today: an O started in Bankai stays 4 even if the arm bursts during the rush.
- Soul Breaks read the attacker's form at settle time (as today); the new rule plays that form's `:kikon` move `:cine`:
  MAPPUTATSU in Bankai, the CHARGE cinematic in 片腕.
- **Events to K.O. 9 Konpaku**: minimum **2** (Bankai Soul Break 5 + a 4: another Bankai / NOMIHOSE Kikon or a
  NOMIHOSE Kikon before it). This minimum already exists under the new Soul Break rule for cup 3; the Bankai holds 4 / 5
  for up to 20 s instead of cup 3's 5–10 s. In practice: the Bankai has at most one reset inside it (8 m, 0.8 s lock,
  pips left), so a two-event K.O. needs the opponent to lose 4 before the Bankai and 5 in it. With 片腕 alone: 3 events
  (4 + 4 + 1, or 3 + 3 + 3). Knob if two-event K.O.s show up in the gate: Bankai Kikon 4 → 3.

## 7. HUD and the red look

- **Pips** in the meter slot (where NOME was): four BLOOD claw-slash pips left to right; a spent pip turns INK with a
  white crack line; under the next pip to crack, a thin line drains over the 300 f clock and the pip flickers in its
  last 60 f. Label: the brush glyph **腕** + "UDE" (glyph baked with `tools/glyph-bake.py`).
- Name line: "KENPACHI BANKAI" (form-name "BANKAI"), the awakening row label in BLOOD instead of ember; `U: DRINK` stays.
- **Prompt**: while `bankai-allowed-p` holds for a human, the awakening row blinks "P  BANKAI" in BLOOD (the device's key
  name: P / KP+ / BACK). On the phone the AWAKEN chip lights on the same predicate as EVOLUTION (`onehand.lisp`, the
  deck's `evo` test becomes "awaken or Bankai ready").
- 片腕: "KENPACHI KATAUDE", no meter, the awakening row label in dim ember.
- Callouts: move names ASCII; the SP / technique kanji as brush columns at his side (盾ごと TATE-GOTO, 殴り飛ばし
  NAGURI-TOBASHI, 噛み千切り KAMICHIGIRI; the Kikon 真っ二つ MAPPUTATSU with the hanko). Glyphs to bake: 盾 殴 飛 噛 千 切 真 二 腕 片.
- Portrait HUD (`hud-side-portrait`): the same pips in its meter slot.

## 8. AI

**Entering (the CPU in cup 3).** New `:nomihose` AI key `:bankai (:p 0.6 :opp-below 0.6 :opp-konpaku 4)`: a free-state
reflex **before the cash-out reflex**: when `bankai-allowed-p` holds and the opponent's Reishi ≤ 60 % of max or his
Konpaku ≤ 4, one roll per cup-3 stay (a brain field keyed on the stay's start tick) at 0.6 → P (0.9 since 2026-09-30, the
user: more CPU Bankai; the gate's Kenpachi reached the Bankai in 64 % → 80 % of matches). Otherwise the cash-out
rules run as today. Reason: the Bankai is a finisher; used at full-Reishi opponents it is mostly the downside.

**In Bankai** (the `:bankai` kit `:ai`):
- intents PRESSURE 7 / APPROACH 3 / ZONE 0 / DEFEND 0; pressure range 1.2–3.0 m; dash 1.0.
- bands: 0–1.5 m `:q 3 :f 3 :sig 3 :breaker 1 nil 1` (the bite only here); 1.5–3.4 `:q 4 :f 4 :breaker 1 nil 1`; 3.4–6.0
  `:sp1 3 :sp2 2 :step 1 nil 1`; 6–99 `:kikon 1 :step 1 nil 1` (LEAP from 10.6 m).
- `:string-k 0.6` (new generic key: `string-reflex` reads the kit's value before `*ai-string-flash-p*`), `:o-ender 0.8`,
  `:kikon-p 0.9`, `:kikon-range 10.6`, guard (= DRINK) 0.2, hoho 0.2, block-string 0.85, no `:react`, no `:cashout`.
- **`:pip-hurry 90`** (new generic key): when the crack is ≤ 90 f away and a pip is left, the next neutral decision
  attacks (aggression 1.0) with the pip commands of its band only (J weights zeroed). Use it or lose it.
- Pips are checked for free: `kit-command-ok-p` refuses a pip command at 0, so no pick ever tries one.

**In 片腕**: the base Kenpachi table with the ranges shrunk (pressure 1.0–2.0; close band 0–2.0 `:q 5 :f 2 :sig 2
:breaker 1 :sp2 1 nil 3`, 2.0–4.0 `:f 1 :sp1 2 :step 1 nil 2`, 4–6 `:sp2 2 nil 1`, 6–99 `:step 1 :kikon 1 nil 1`), `:kikon-p
0.5`, `:o-ender 0.25`, guard 0.35, dash 0.9.

**Opponents facing a Bankai** (generic):
- **`:opp-intent (:zone 2 :defend 2)`** on the `:bankai` kit: a CPU facing that form adds these to its intent weights at
  every re-pick (bounded by the ≤ 20 s form; heat still pulls it back in). Yamamoto zones (7–9.5 m, Shiranui); Kenpachi
  keeps 3–6 m. Nozarashi v2 deleted a similar "flee DRINK" rule because DRINK had no end; the arm has one.
- **Grabs**: the bite carries the move flag `:grab`; a committed `:grab` move in reach + margin → Hoho (the kit's roll) or
  a sideways Step, **never a guard** (the South-bind tell's branch, generalised from `:bind` to `(:bind :grab)`).
- Everything else is already there: a red Kenpachi draws the neutral Kikon rush (p 0.5 / the kit's); a blocked K link
  leaves ≥ 12 f and triggers J-beats-K; the burst's crumple is a `:stun`, so "a red opponent still reeling: rush him"
  fires; West's parry and the `:react` rules catch K links.

## 9. Balance

**What he buys** (≤ 20 s, 4 pips):
- per pip on hit, ×1.2: a whole K string (KKK 444, + the O ender), the bite 144 + a guaranteed string, TATE-GOTO 312
  (guard-breaking), NAGURI-TOBASHI 210, a neutral O 76–84 or a Kikon 4; JJJ free (151).
- the dream line: from an opponent at ≤ 60 % (≤ 780), K1 lands → KKK 444 → he is red → the O ender's follow-up is
  unguardable → **Kikon 4**. One pip since the playtest decision (was 4 pips on one read).
- pressure: blocked K links drain 28 / 28 / 36 and chip 20 %; the bite and TATE-GOTO beat guards; rend beats the
  mirror's stance and CHARGE armour.

**What he pays**:
- red the whole time, 30 per pip, 60 at the burst: typically **~1–150 Reishi left by the end**. Any hit may be a Soul
  Break (the opponent's count + 1), and any Kikon rush hit held is a Kikon.
- whiffed or blocked pips are gone; the 5 s crack means waiting also costs.
- the burst: 40 f crumple, usually a string + the opponent's Kikon.
- **the rest of the match as 片腕**: reach ×0.7 on every sword move (J1 1.82 m against Yamamoto's 2.4), ×1.0, no DRINK /
  rift / cash-out / NOME. Against Nozarashi's ladder (awake-time mix KATATE 32 % / RYOTE 52 % / NOMIHOSE 16 %: an
  expected Kikon of 2.84 and damage ×1.12) 片腕 keeps a similar Kikon (3) but loses about 30 % of his reach and 10 % of his
  damage for good.
- the Bankai ends at once if he loses a Konpaku in it.

**Frequency** (the CPU gate): cup 3 is ~16 % of his awake time and he is red maybe a fifth of it, so the window opens
about once or twice a match; with the 60 % / 4-Konpaku filter and p 0.6, expect a Bankai in roughly **half of the
matches with a Kenpachi**, 0–2 per KK match.

**Expected gate effect** (debug 2113, 20 seeds × YY / YK / KK; today 129.4 / 137.3 / 130.4 s, YK 10 / 10):
- YY: unchanged.
- YK: a Bankai match gains ~300 damage for Kenpachi in ≤ 20 s and more Konpaku events both ways, then a weaker
  Kenpachi: median **−2 to −8 s** (≈ 129–135 s). Wins: aimed at 10 ± 3 by construction (a gamble), unproven.
- KK: two possible Bankais: **−4 to −12 s** (≈ 118–126 s). **This is the risk**: KK has 5.4 s of headroom above 125 s.
- Measure only after the general Soul Break rule has had its own gate (it shortens every pairing by itself).

**Acceptance** (added to the gate report):
1. 60/60 K.O., medians 125–210 s, YK Yamamoto 10 ± 3.
2. **The gamble test**: YK and KK over seeds 1–60 with the CPU's `:bankai :p` forced to 1.0 and to 0.0: the win-rate
   difference within noise (≈ ±3 of 20 per 20 seeds, so ±9 of 60). If "always" wins clearly, it is an upgrade, not a
   gamble: nerf the Bankai; if "never" wins clearly, buff it.
3. Pacing log: entries per match, pips by source (K / L / SP1 / SP2 / I / O / crack), pip hit / block / whiff, Bankai
   length (mean, max ≤ 20 s + resets), Konpaku events inside a Bankai (by and on him), bursts by cause (spent / crack /
   Konpaku lost), Kikons on him within 2 s of a burst, 片腕 share of the awake time.

**Knobs, in order** (if the median falls under 125 s): `:bankai :p` 0.6 → 0.35; Bankai Kikon 4 → 3; the K pip damage −15 %
(120 / 100 / 150 → 102 / 85 / 128); `*arm-crack*` 300 → 240. If Kenpachi wins too much: `*kataude-reach*` 0.7 → 0.6, the
burst stun 40 → 50, `*arm-self*` 30 → 40. Too little: `*kataude-reach*` → 0.8, 片腕 keeps projectile cut, the CPU entry
filter 0.6 → 0.8 (more Bankais earlier). Guard ×2 → ×1.75 if West's ward crushes too often (§10 M4).

## 10. Adversarial self-critique

| # | Sev | Finding | Resolution (folded into §1–§9) |
|---|---|---|---|
| B1 | BLOCKER | `:bankai` inherits NOMIHOSE's `:meter-gain` through the merged spec, and `nome-gain!` writes `gauges-meter`: every hit, taken point and drink would **refill the pips** | explicit `:meter-gain nil`; host test: `(kit-meter-gain bankai)` is NIL |
| B2 | BLOCKER | 片腕 derives the Breaker at ×0.7: strike reach 1.82 < `*breaker-trigger*` 2.2, so every triggered Breaker whiffs; the CHARGE strike 1.68 barely clears the 1.6 Kikon trigger | 片腕 lists the Breaker, the O module and the kick as its own (as written); a host test for **every form**: Breaker strike reach > `*breaker-trigger*`, Kikon strike reach > `*kikon-trigger*` + 0.3 |
| B3 | BLOCKER | the reset refills a Kikon'd Bankai Kenpachi to 1300 with pips left: the "red the whole time" premise disappears | a Konpaku loss in Bankai bursts the arm quietly at the reset (§2) |
| B4 | BLOCKER | the merged spec also carries the `:ladder` meter: `nome-step` would move the Bankai back to a cup; the cash-out hook sets `:nozarashi` | `:bankai` sets its own `:meter` without `:ladder`; it lists SP1 as its own (no `ken-drink-dry`); host test: no `:ladder` on `:bankai` / `:kataude` |
| B5 | BLOCKER | the 4th pip spent mid-string, then a latched K link: spend to −1 or start with no pip | the latch start checks `pip-ok-p`; refused → the string ends; the press was already consumed (host + probe) |
| B6 | BLOCKER | "burst when free" can be dodged: a buffered J1 / Step starts in the fighter step before the gauge step sees `:idle`, so a masher is never free | the pending burst waits only for **the move running when the last pip went**, reactions and a Hoho; any later move is interrupted by it (§2) |
| M1 | MAJOR | the red reiatsu is the BLOOD hue, the colour of the Kikon rush / counter tells | the Bankai aura is a vertical pillar of BLOOD tongues over INK tongues (the Breaker-aura structure) and **collapses to a smoulder during his Kikon rush**, so the rush's horizontal BLOOD trail, speed lines and "KIKON" word stay the tell; checked on stills |
| M2 | MAJOR | crimson skin + red aura break the 15 % spot budget, and 片腕 would break it for the rest of the match | the skin is a **muted crimson (S ≤ 0.45: not spot)** in both forms; the Bankai's aura is a big move (the budget's exception, ≤ 20 s); 片腕 has no aura |
| M3 | MAJOR | the bite beats every defence and guarantees a string → O ender → a Kikon on a red opponent | it costs a pip + 30 Reishi, reaches 1.5 m, whiffs 49 f, loses to any startup; the CPU never guards a `:grab`. Knob: R 28 → 30 (no guaranteed follow-up) |
| M4 | MAJOR | a KKK warded by Bankai West drains 101: one blocked KKK crushes the full ward | the ward has no blockstun: West acts between the K links (≥ 12 f) or parries one (the parry refills him, the pip is lost). Knob: ×2 → ×1.75 (KKK 81 / 89 warded) |
| M5 | MAJOR | the CPU's J-heavy strings (K 0.3) would let the pips crack: the gate would test a Bankai no human plays | `:string-k 0.6`, `:pip-hurry 90` |
| M6 | MAJOR | 4 / 5 for 20 s makes two-event K.O.s likelier | logged; knob Bankai Kikon 4 → 3 |
| M7 | MAJOR | KK has 5.4 s of median headroom and gets up to two Bankais | measured after the Soul Break rule's own gate; knob order in §9 |
| M8 | MAJOR | `refresh-look` never swaps the body; the oni variant must keep the hurt cylinder | `refresh-look` sets `model-body` from the kit `:body`; `:kenpachi-oni` is a palette / parts variant of `:kenpachi` with the same scale and hurt numbers |
| M9 | MAJOR | the opponent CPU would keep pressing into a 20 s form it could wait out | `:opp-intent` (zone / defend +2) |
| m1 | MINOR | "4th attack" is a snippet-level source | the count is the user's decision; the note stays |
| m2 | MINOR | P from a DRINK held between an opponent's string links freezes the sim and resets both to idle: an escape | the same as every awakening (from `:guard`); not from `:guard-hit`. Accepted |
| m3 | MINOR | pink (Yachiru, petals) is a 4th hue | the forest is mono; the call is a sound |
| m4 | MINOR | the last pip on a Kikon hides the burst in the reset lock | intended: the jackpot |
| m5 | MINOR | rend matters only in KK (the stance, CHARGE's armour) | ~5 lines + one test; it is the "nothing I can't cut" identity. Kept |
| m6 | MINOR | the crack clock during the 48 f reset lock | paused while locked |
| m7 | MINOR | a 6 m punch knockback lets the crack clock run while he re-closes | canon (off Wahrwelt); LEAP and the dash cover 6 m |
| m8 | MINOR | the P prompt is invisible on the phone unless the AWAKEN chip lights | the chip uses the same predicate |

Revision: all of the above are in the text; nothing was rejected. The one idea dropped on purpose is DRINK restarting
the crack clock (§2).

## 11. Code changes (for the builder)

- **tuning.lisp**: `*bankai-ken-mult*` 1.2, `*arm-pips*` 4, `*arm-crack*` 300, `*arm-self*` 30, `*arm-burst-self*` 60,
  `*arm-burst-stun*` 40, `*kataude-reach*` 0.7.
- **rules.lisp** (pure, host-tested): `bankai-allowed-p (free red)`; `pip-spend (pips)` → pips ok;
  `pip-step (pips idle locked)` → pips idle cracked-p (+1 idle unless locked; a crack at `*arm-crack*`); `burst-due-p
  (pips pending-move current-move state)`; `resolve-contact` gains `:rend` (`:armor` → `:hit`, `:stance` → `:stance-break`).
- **kit.lisp**: kit slots `bankai-form`, `pips` (register-kit destructure); `defmove-copy` with override keys; docs of the
  new keys and the `:grab` / `:rend` flags.
- **fighter.lisp**: `try-command :awaken` → `bankai!` when `bankai-allowed-p` and the kit has `:bankai-form`;
  `kit-command-ok-p` refuses a pip command at 0; the spend in `try-command` and at the latch start (`move-commands`, K
  only); `refresh-look` sets `model-body` and hides the crack tags beyond the spent count.
- **combat.lisp**: `bankai!` (set-form, meter 4, idle 0, the cine; no heal); `arm-step` in `gauge-system` (the clock, the
  crack, the pending burst); `arm-burst!` (form, burn, crumple, the `:arm-burst` event); `settle-konpaku`: a victim in a
  `:pips` form bursts quietly; `apply-hit` passes `(member :rend flags)` to `resolve-contact`.
- **ai.lisp**: the Bankai entry reflex (before the cash-out), `:string-k`, `:pip-hurry`, `:opp-intent`, `:grab` in the
  South-tell branch.
- **ken.lisp**: the 12 Bankai moves (+ 2 copies), `:bankai` / `:kataude` kits, `:bankai-form :bankai` and the `:bankai` AI
  key on `:nomihose`, hooks `ken-bankai-enter`, the two cinematics.
- **ken-art.lisp / body.lisp**: `:kenpachi-oni` as a variant of `:kenpachi` (a small `body-variant` helper: same spec +
  props, new palette, added parts); the pupil boxes get their own palette key `:pupil` (base #0C0C12, oni white:
  irisless); weapon `:ke-broken`; 3 clips.
- **vfx.lisp**: the `:oni` aura (pillar, BLOOD over INK) and its rush-time smoulder; the vertical `vfx-sky-split`; the arm
  crack / burst looks. **cinema.lisp**: the `:forest` card, the child cut-out. **sounds.lisp**: `:arm-crack`,
  `:arm-burst`, `:yachiru-call`. **hud.lisp** / **onehand.lisp**: §7. **glyphs**: §7's list. **debug.lisp**: a key that
  puts P1 in cup 3 and red; probes.
- **Determinism**: the pips are `gauges-meter` (already hashed as `m`); add `meter-idle` and the pending flag to the hash
  line.

**Host tests** (`tests/duel-rules-test.lisp`):
1. `bankai-allowed-p`: free + red → T, not red / not free → NIL; only `:nomihose` has `:bankai-form`.
2. `pip-spend` 4 → 3 T, 0 → 0 NIL; `pip-step`: 299 no crack, 300 crack + idle 0; locked frames don't count; 4 cracks = 1200 f.
3. `burst-due-p`: pending + in the pending move → NIL; a later move → T; in `:stun` / `:hoho` → NIL.
4. `resolve-contact :rend`: armour → `:hit`, stance → `:stance-break`, guard → `:blocked`, parry → `:parried`, a ward → `:blocked`.
5. The §2.1 budget over `:bankai` and `:kataude` (add them to the forms the test walks), the six routes, K2s / J2s aliases.
6. 片腕 reaches: J1 1.82, K1 2.10; J3 2.2, Breaker 2.6, O 2.4 as written; every form's Breaker / Kikon strike beyond its trigger.
7. Kikon counts: `:bankai` 4, `:kataude` 3; Soul Break 5 / 4 under the new cap.
8. `:bankai`: `:meter-gain` NIL, no `:ladder`, no `:cut`; guard values 28 / 28 / 36; the bite's hitwin `:unguardable`, the move
   `:grab`; TATE-GOTO `:guard-crush`; SP2's `:land` string is the punch.

**Probes** (debug): entry refused outside cup 3 / red; KKK spends 3, a whiffed K spends, JJJ spends 0; the latch refuses a
5th; a crack at 300 f; the burst after the 4th strike's recovery (40 f crumple, burn 60, ≥ 1 left) and not before; a
masher can't dodge it; a Kikon on him in Bankai → 片腕 at the reset; a 4th-pip O Kikon → burst inside the lock; the
determinism double run.

**Implementation order**: (1) rules + tests; (2) the two kits with placeholder clips (`:ke-b-fist` ← `:ke-kick`,
`:ke-b-bite` ← `:ke-shoulder`, `:ke-b-stance` ← `:ke-n-stance`), P entry without a cine, pips, crack, burst, the
Konpaku-loss burst, minimal HUD; gate (after the Soul Break rule's own gate); (3) AI keys, gate + the gamble A/B;
(4) art: body variant, weapon, 3 clips, aura, burst, two cinematics, sounds, glyphs; user review; (5) docs:
DUEL_DESIGN §1 (the one-awakening exception), §2 (counts), §4 (DRINK in Bankai), §6.2 (the two forms), §6.3 (the module
row), §7, §10 (HUD, cinematic lengths: Bankai 186, MAPPUTATSU 162), §12 rows; STYLE_STORM §A.2 (the red-reiatsu
exception, the muted crimson skin); DUEL_NOZARASHI_V2 a pointer.

## 12. Art and VFX (the existing toon style)

| Item | Design |
|---|---|
| Body `:kenpachi-oni` | the same mesh; skin **muted crimson** (#9A4A42 / shade #7A3630, S ≤ 0.45: not a spot colour; hull ink unchanged); two short horns from the forehead hairline (cones in the skin colour, ink keyline, tag `:horns`); pupils white (**irisless**) in all three faces; the grin kept; four thin BLOOD-glow crack lines on the right forearm (`:crack-1..4`, shown one per spent pip); a torn right forearm (`:arm-wreck`: jagged skin shell, BLOOD strips, ink splits), shown only in 片腕 |
| Weapon `:ke-broken` | the Nozarashi cleaver cut to ~1.15 m, the end snapped off on a diagonal (jagged wedge), no guard, a long cloth-wrapped tang like the first Zangetsu's hilt [A]; ink-black blade, a white edge highlight; no fire / glow |
| Stance `:ke-b-stance` (new; the feral pass 2026-09-28, below) | a deep forward-leaning crouch on bent, splayed legs, the back rounded, head low and thrust forward, the left hand a loose claw, the broken cleaver dragged behind him with its tip toward the floor; the back heaves (the "beast-like stance") |
| `:ke-b-fist` (new) | J3 and SP2's punch: a left hook / straight from the hip, the whole body behind it, a 3 f hold on contact, the comet smear on the fist |
| `:ke-b-bite` (new) | a low lunge, the left hand clamps, the head drives in, a jerk back with the teeth bared (the shout face), BLOOD spray on the tear |
| Aura `:oni` | BLOOD tongues over taller INK tongues in a vertical pillar (×1.4 tall), BLOOD flecks rising, on twos; a smoulder (a few flecks) during his Kikon rush |
| Pip spend | a BLOOD crack flash along the forearm, `:arm-crack` (a bone creak), the crack tag shown |
| Crack (timeout) | the same, dimmer, with a small ink puff |
| Burst | §4 |
| Cinematics | §1.2, §3.1 |
| 片腕 | no aura; the torn forearm, a BLOOD drip fleck every 20 f from it; horns / skin / eyes kept (Q4) |

Counts: **3 new clips**, 1 weapon, 1 body variant, 3 sounds, ~10 glyphs, 3 VFX kinds, 2 cinematics (1 new, 1 re-cut).
片腕 needs no new clip.

## Questions for the user (each with the recommended default)

1. **A Konpaku lost during the Bankai ends it** (the arm bursts in the cinematic; he resets as 片腕). Otherwise the
   reset refills him to 1300 with pips left and the "red the whole time" gamble disappears. *Default: yes.*
2. **The bite (噛み千切り) as the Bankai's L now** (1 new clip; an unguardable short grab). Your earlier "bite later"
   was about 片腕; the alternative keeps L = the stance in Bankai for v1. *Default: bite now in Bankai; 片腕's bite and
   foot-grab stay for later.*
3. **Yachiru in the forest shot**: a tiny ink silhouette cut-out for 2 drawings (no model, mono: no pink, the 3-spot
   rule), or no figure at all (only the distorted call sting and the "KEN-CHAN" sub). *Default: the silhouette.*
4. **片腕's look**: he stays the oni (horns, muted crimson skin, irisless) with the aura gone and the right forearm torn
   open, still clamping the broken cleaver (the reason for reach ×0.7), or he returns to his normal skin. *Default: stays
   the oni (ch. 671 fights on in Bankai).*
5. **How often the CPU gambles**: only as a finisher (opponent ≤ 60 % Reishi or ≤ 4 Konpaku, 0.6 per cup-3 stay), or
   whenever it can (more Bankais, higher gate risk in KK). *Default: finisher only.*

## User decisions (2026-09-28)
- **Entering the Bankai sets Kenpachi's OWN Konpaku to 1** (verbatim: 「卍解後魂魄直接變成 1」, clarified: 劍八自己剩 1 魂魄). From then on any Kikon or Soul Break on him ends the match; the Bankai (and the 片腕 that follows the burst) is fought on his last soul. If he already has 1, nothing changes. This supersedes question 1: there is no "lose a Konpaku in Bankai -> burst -> reset as 片腕" case, since losing one is the K.O.
- Questions 2–5: the recommended defaults (bite as the Bankai's L now; Yachiru as a tiny mono ink silhouette; 片腕 stays the oni; the CPU enters Bankai only as a finisher).
- Re-check the balance section and the CPU entry rule against this cost (the CPU should weigh its own Konpaku before entering), and the "must-enter vs never-enter" A/B.
- **Entering the Bankai also refills his Reishi (HP) to full** (verbatim: 「然後 HP 回滿」, 2026-09-28). This supersedes the earlier "no heal on entry" default: the trade is all his remaining souls for one full bar fought with the Bankai. The arm-pip self-costs (30 per pip, 60 on the burst) now come out of that full bar; re-tune them and the entry rule (still cup 3 + red + P) with this in mind.

## Built (2026-09-28): deviations from the design

What was built as designed: the entry (P, cup 3, red, free: `bankai-allowed-p`; `:bankai-form :bankai` on NOMIHOSE only);
the arm meter (the kit meter holds the pips, `pip-spend`, `pip-step`: a crack every 300 f without a spend, paused while
locked); the pending burst (`burst-due-p`: it waits for the move that spent the last pip, reactions, blockstun, the air,
down, wake-up, a Hoho); the burst (`arm-burst!`: 片腕, a 40 f self-inflicted crumple in place, "GOMEN NE, KEN-CHAN"); the
twelve Bankai moves and the two copies, 片腕 (the base moves at reach ×0.7; the kick, the Breaker and O as written);
`:rend` in `resolve-contact`; `defmove-copy` with override keys; `body-variant` (`:kenpachi-oni`: muted crimson skin
#9A4A42, horns, the pupils' own palette key `:pupil` white, four forearm cracks, the torn forearm); the weapon
`:ke-broken`; the three clips (`:ke-b-stance`, `:ke-b-fist`, `:ke-b-bite`); the `:oni` aura (BLOOD over INK, a pillar,
a smoulder in his rush); the two cinematics (`ken-bankai-cine` 186 f, `ken-oni-kikon-cine` 162 f); the HUD pips (landscape
and portrait), the P BANKAI prompt, the phone's AWAKEN chip; the sounds `:arm-crack`, `:arm-burst`, `:yachiru-call`;
the glyphs 腕 片 盾 殴 飛 噛 千 切 真 二 草 鹿; the AI keys `:bankai`, `:string-k`, `:pip-hurry`, `:opp-intent`.

| # | Design | Built | Why |
|---|---|---|---|
| 1 | entry: no heal | **his own Konpaku set to 1, his Reishi refilled to full** (`bankai!`) | the user's decisions 2026-09-28 |
| 2 | a Konpaku lost in Bankai bursts the arm quietly at the reset (B3, question 1) | not built | moot: with 1 Konpaku any Kikon or Soul Break on him is the K.O. |
| 3 | `*arm-self*` 30, `*arm-burst-self*` 60 | **60 / 120** (knobs, debug 32000+k / 33000+k) | the entry now refills him: at 30 / 60 the four pips and the burst cost 180 of 1300. The gamble A/B (below) at 30 / 60: Kenpachi +5 of 60 in YK with the entry rule; at 60 / 120 +1 / −2: the one inside the noise both ways |
| 4 | CPU entry: opponent ≤ 60 % Reishi or ≤ 4 Konpaku, p 0.6, a roll keyed on the stay's start tick | `:bankai (:p 0.6 :opp-below 0.6 :opp-konpaku 4 :own-konpaku 4)`: **nothing to lose** (his Konpaku ≤ the opponent's next Soul Break count, the count + 1 capped at 5) **or** the finisher filter with **≤ 4 of his own Konpaku left**; one roll per cup-3 stay (a brain flag cleared outside cup 3), made when the conditions first hold | the user: the CPU must weigh its own Konpaku (entry costs all but one). `:own-konpaku` 5 → 4 at the gate: YK seeds 1–20 Kenpachi 13 → 12 wins |
| 5 | the bite: 1.5 m, no lunge | the bite lunges **0.8 m** (`:slide`, stopping 1.3 m from him) | "a lunge" (the design's pose line); without it the bite never reached from the strings' 2.2 m |
| 6 | a `:grab` joins the South-tell branch (a timed Hoho / side Step) | the committed-move reflex never guards a `:grab` (a side Step) | the bite's 10 f startup is shorter than NORMAL's 14 f perception delay: a tell-timed reflex would never fire |
| 7 | "the vertical variant of `vfx-sky-split`" | the existing sky split (its line is already vertical on screen), shot face-on to the victim so the line splits him; the Bankai's aura is off in MAPPUTATSU (the cut reads) | no new primitive needed |
| 8 | a latched K link with no pip: the press is eaten, the string ends | the latched K is dropped and the string ends at that link; a later J press in the same link may still latch | the smallest change in `move-commands` |
| 9 | 片腕: a BLOOD drip fleck every 20 f from the torn forearm | not built | a look; the torn forearm (`:arm-wreck`) shows it |
| 10 | the forest shot's "KEN-CHAN" brush sub-line | a caption 草鹿 KUSAJISHI with the sub KEN-CHAN; Yachiru a tiny ink cut-out drawn in UI space for two drawings (f24–31), the trunks and petals UI space too | the user's decision (question 3: the silhouette); the card is a UI look |
| 11 | the hash line: `meter-idle` and the pending flag | `u<clock>` and `*` only for a form with pips | the other forms' hash lines stay byte-identical (G2: YK and KK unchanged) |
| 12 | Soul Break cinematic chosen in `settle-souls` | a pure kit function `kit-kikon-cine` (host-tested) | testable without the engine |
| 13 | 片腕's stance | the base `:ke-stance` | "no new clip" |

Knobs as built (tuning.lisp): `*bankai-ken-mult*` 1.2, `*arm-pips*` 4, `*arm-crack*` 300, `*arm-self*` 60,
`*arm-burst-self*` 120, `*arm-burst-stun*` 40, `*kataude-reach*` 0.7; Soul Break `*soul-break-max-event*` 5.
Debug: 2386+k the Bankai tests (0 cup 3 + red, P; 1 in the Bankai 2.2 m; 2 one pip left; 3 片腕), 35000+f / 36000+f
stills of the two cinematics, 30000+k the gate's seed offset, 31000+10a+b the CPUs' entry mode (0 the rule, 1 always,
2 never, 3 the rule with p 1), 32000–34000+k the arm knobs, 37000+k / 38000+k the entry rule's `:p` / `:own-konpaku`.
Script `tests/scripts/duel-bankai.json` (stills `tests/shots/duel-ken-bankai-*.png`).

## Measurements (2026-09-28)

**The seed gate** (debug 2113, 20 seeds × YY / YK / KK, NORMAL, cinematics included; window: median 125–210 s, all K.O.):

| | YY | YK | KK | YK wins (Yamamoto / Kenpachi) |
|---|---|---|---|---|
| before (the strings, 2026-09-27) | 129.4 s | 137.3 s | 130.4 s | 10 / 10 |
| after the Soul Break rule | 131.8 s (99.7–165.1) | 138.0 s (77.0–197.3) | 131.5 s (97.4–174.2) | 9 / 11 |
| after the Bankai (final) | 131.8 s (99.7–165.1) | 138.4 s (98.1–200.9) | 131.5 s (97.4–174.2) | 8 / 12 |

60 / 60 K.O. in every run. Bankai entries in the final gate: 3 in YK (seeds 1–20), 6 in KK; 0 of the 9 were won by the
side that entered (a finisher that usually comes late: the matches were mostly lost already).

**The gamble A/B** (seeds 1–60; YK: Kenpachi's wins; KK: P1 with the mode against a P2 that never enters, compared with
both never; "same seeds": the matches where he entered, won with the Bankai vs the same seed with it forbidden):

| Mode | YK Kenpachi wins / 60 | YK: entered, won vs same seeds never | KK P1 wins / 60 | KK: entered, won vs never |
|---|---|---|---|---|
| never | 27 | — | 28 | — |
| the entry rule with p 1 (the design's test) | **28 (+1)** | 15: 5 vs 4 | **26 (−2)** | 25: 6 vs 8 |
| the entry rule, p 0.6 (as shipped; KK: both sides) | 28 (+1) | 8: 2 vs 2 | 26 of 60 (P2 34) | P1 18: 6 vs 7; P2 8: 2 vs 2 |
| always, whenever allowed (no filter) | **19 (−8)** | 33: 6 vs 14 | **25 (−3)** | 44: 16 vs 19 |
| the rule with p 1 at the design's self-costs 30 / 60 | 32 (+5) | 18: 9 vs 4 | 29 (+1) | 26: 10 vs 9 |

Read: with the entry rule the Bankai is **a gamble**, within the noise both ways (±9 of 60, the design's criterion;
+1 in YK, −2 in KK). Entering blindly, with many Konpaku left, is close to a suicide button against Yamamoto (−8,
6 wins where 14 were there without it): the entry costs every Konpaku but one, which is the user's point. At the
design's self-costs (30 / 60) the Bankai turned into a slight upgrade in YK (+5), so they were doubled with the refill.

## The feral pass (the user's request 2026-09-28)

> 劍八卍解的姿勢與動作更野性 (a beast-like oni)

Art only: every move keeps its S / A / R, reach and hit volumes (the clips are timed by the same `defstrike` frames), and
the sim never reads a clip, so the seed gate and G2 are untouched by it.

| Item | Before | Now (`duel/lisp/ken-art.lisp`) |
|---|---|---|
| Stance / idle `:ke-b-stance` | hunched, knees a little bent, the cleaver held down in front | root −0.30, spine 40 + chest 16, head −58 (the eyes up), wide lead-leg crouch (thigh 62 / knee 84), the trailing leg back; the cleaver dragged behind, tip down; the idle heaves (chest, root, the claw flexing) |
| Guard | the shared `:sh-guard` (upright) | `:ke-b-guard` / `:ke-b-guard-hit`: lower still, behind the raised left forearm, the broken blade flat across the body |
| Walk / strafe | the shared `:sh-walk-*` / `:sh-strafe-*` | `:ke-b-walk-f/b`, `:ke-b-strafe-r/l`: the shared leg cycles sunk into the crouch (`oni-keys`: root −0.28, thighs +38, knees +60, spine +18) |
| Run | the shoulder-rest set (`:ke-run` …) | `:ke-b-run`, `-skate-b`, `-slide-r/l`: the run legs under the crouch, bent double, the blade trailing (kit `:run-clips`) |
| J3 / SP2 punch `:ke-b-fist` | a hook from the hip | coiled lower, springs out of the crouch, the hook with the whole body, the cleaver flung out behind |
| L `:ke-b-bite` | a lunge from a crouch | down almost on all fours, then the lunge, the claw clamping, the head driving in |
| O MAPPUTATSU rush | LEAP CLEAVE's `:ke-n-leap` | `:ke-b-leap`: dropped almost to all fours, then the spring, the broken cleaver swung up one-handed, the claw reaching ahead (`defmove-copy … :clip :ke-b-leap`) |
| MAPPUTATSU cinematic wind-up | the sky split's `:ke-kikon-n` | `:ke-b-kikon` (same beat: the snap at 0.42 s = cine f68): sunk into the crouch, then rearing, back arched, the cleaver high over his head, the claw thrust out; one vertical crash lunging through |
| Entry cinematic | `:ke-b-stance` from the burst | `:ke-b-roar` at the burst (rising out of the crouch, head back, arms flung wide, then the roar comes forward at the opponent for the f78 face close-up); the feral stance on the 卍解 card |

The oni's own walk / guard are a body-level clip map (`body-variant … :clips`, `body-clips`, played by `play-clip`), so
片腕, which keeps the oni body (Q4), prowls and guards the same way; 片腕 also takes the feral stance and run
(`:stance :ke-b-stance :run-clips …`; it had the base `:ke-stance`, Built #13). New clips: 13, and the three Bankai clips redrawn (`tests/duel-rules-test.lisp`'s
clip contract lists the five the kits use). Review stills: `tests/shots/duel-ken-feral-*.png` (before / after) and `tests/shots/duel-ken-cine-framing-*.png` (§1.3).

## The entry at ≤ 4 Konpaku (the user's decision 2026-09-28)

> 劍八的卍解條件從紅血改成在剩餘四魂以下

P in cup 3 now needs **at most 4 of his own Konpaku** (`*bankai-konpaku*`), not red Reishi; everything else about the
entry is unchanged (Konpaku → 1, Reishi → full, once a match). Callers: `bankai-ready-p` (combat.lisp: the HUD's P BANKAI
prompt, the phone's AWAKEN chip), the P command (fighter.lisp), the CPU (`ai-reflex`); debug 2386+k caps his Konpaku at
4. The CPU's rule is the same filter (nothing to lose, or the finisher with `:own-konpaku` 4, which the entry now
implies), with one roll per cup-3 stay; it no longer needs to be red, so the refill can come at a high Reishi.

**Measured** (the seed gate with the string chase of the same day, DUEL_STRINGS §11): YY 134.7 / YK **137.1** / KK **125.8 s**,
60 / 60 K.O.; YK Yamamoto 10 / Kenpachi 10. Bankai entries: **YK 14** of 20 matches (the entrant won 7), **KK 19**
(entrant won 6); with red (the chase alone): YK 0 / KK 3 (0 won); before both: YK 3 / KK 6 (0 of 9 won). The KK median sits at the floor's edge; the entry rule's `:p`
(debug 37000+k) and `:own-konpaku` (38000+k) are the knobs if it goes under.

## Playtest decision: one UDE pip per string (the user, 2026-09-28)

「更木劍八卍解的 K 改成打完一套才扣腕」: a J / K **string** (K, KK, KKK then broken off, KJJ, JKK …, plus its O ender)
costs **one** pip in total, not one per K link; per-K spending made K far too expensive. The pip, its Reishi self-cost and
the crack flash are charged **once, when the string ends** (completed, broken off, or stopped by a whiff). A K link still
needs a pip available to start (the B5 rule: at 0 pips the string can't start / continue a K link). Pure-J strings
(JJJ) still cost nothing. L, SP1, SP2, I and the neutral O keep one pip per use.

**Built (2026-09-28).** The gauges hold `arm-owed` (the string owes its pip). A K1 from neutral, a latched K link and
the O ender set it instead of spending (`try-command`, `move-commands`); `arm-step` charges it (`arm-spend!`: the pip,
`*arm-self*` burnt, the crack clock restarted, the `:arm-spend` crack flash) on the first frame he is not in a `:quick` /
`:flash` link or the `:kikon` ender (rules `string-pip-due-p`, host-tested). A K link still needs one pip; while a pip is
owed, any other pip command needs two (`kit-command-ok-p`), so an SP / L cancel can't run the string for free; the O
ender is called with `ender` and needs one. The burst after the last pip is `:none`-pending, so it fires as soon as he is
free (the string has already ended; a string cancelled into an SP / L charges with that move pending, so it comes out
in full). The §2 table above is updated.

**Fix: the last pip's move is cut by the burst (the user's report 2026-09-28).** 「劍八卍解後『腕』歸零的瞬間就會打斷當前
的出招，導致最後一腕其實放不出來」. Reproduced with debug 2388 (the Bankai with 1 pip) and each pip command: L, SP1, I and
the neutral O came out in full, but **SP2** did not: TATE-GOTO's partner NAGURI-TOBASHI (the charge's `:land`
follow-up, started by the hook `ken-flurry`) is a different move, so `burst-due-p` saw "a later move" and fired on the
punch's first frame. Before the one-pip-per-string change the same rule cut a **K string**: the pip spent on K2 was
pending on K2, and the latched K3 (another move) triggered the burst. Root fix, in the one shared place (`arm-step`):
the pending burst **follows the move's chain**: when the move running is a continuation of the pending one (its string
follow-up for any button, a `:land` follow-up, or the O ender after a link 3: `move-follows-p` in kit.lisp), the pending
move becomes that one, so the burst fires only when the whole chain is over; a new move of his own (J1 after the bite)
is still cut. Host tests: `move-follows-p` on the Bankai's chains and the frame the burst fires for the last pip on L,
SP1, SP2 (charge → punch), a K string + the O ender, and a new move after the bite. In game (debug 2388): SP2's punch
now lands (150) and the burst fires after it. Measurements: the Rukia rework's gate, DUEL_RUKIA.md
"Measurements (the cold gauge rework)".

## Playtest decision: a see-through yellow reiatsu (the user, 2026-09-28)

「劍八的黃色靈壓有辦法做成半透明嗎？不然三杯的時候真的有點擋視線」: Kenpachi's yellow reiatsu aura (cups 1–3, above
all cup 3's pillar) is drawn semi-transparent so it no longer blocks the view (a render-only knob; docs/style/STYLE_STORM_DESIGN.md).
The Bankai's red-and-black `:oni` aura is drawn see-through the same way (the user, 2026-09-28: 「劍八卍解的紅黑色靈壓也改成
半透明的」).

**Built (the `:oni` aura, 2026-09-28).** `vfx-aura :oni` (vfx.lisp) adds the glass level to both tongue sets through
`*reiatsu-glass*`: the BLOOD tongues (and their white core lines, which take the same level) **2 / 4** of the MSAA samples,
the taller INK tongues **3 / 4** (at 2 the black backing dithered into a grey smear against the dusk ground; at 3 it still
reads black-and-red). The BLOOD flecks, the red light and the Bankai entry burst are unchanged; KATAUDE has no body aura.
The same pillar in the Bankai entry cinematic is see-through too (one code path). The Kikon rush aura (`:kikon`) and every
other fighter are untouched; RAVEN's G1 stills are byte-identical (no shader change) and the sim (G2) never reads it.
Debug 71000 toggles every glass level off / on (before / after stills), 71004 puts human P1 Kenpachi in the Bankai.
