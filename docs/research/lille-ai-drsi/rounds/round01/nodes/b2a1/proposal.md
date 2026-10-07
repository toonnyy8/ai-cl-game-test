# b2a1 (round 1, refines b2a0, freeze 1a7f135): the executioner who reads — the sight, the burst read, and the round's located fixes

A refine of **b2a0** (rescored 0.9945 at this freeze). It keeps b2a0's engines and knobs: the hunt and the HOSHA → K1 →
stance loop, the composure, the oki HOSHA and oki mark, the EN mark and spring, KIN's J1 → K2s → K3 route, K3's exits, the
pendulum, the vanish, the siege. It adds:

- **two new mechanisms** found in b2a0's own logs:
  - **the sight** spends his idle Reiatsu on the X-Axis;
  - **the burst read** closes a leak no cell had located.
- **the located fixes of the round's other lineages**, credited, that b2a0 lacked.

Only `duel/lisp/lille.lisp` changed, and only his CPU:
- **new knobs:** `*LB-AI-SIGHT-BARS*` (2) and `*LB-AI-BURST-WAIT*` (30).
- **new functions:** `LB-AI-BURST-WAIT-P`, `LB-AI-ATTACKING-P`, `LB-AI-TURTLE`, `LB-AI-EXIT-HARD`, `LB-AI-SANREN-CASH`,
  `LB-AI-SIGHT-P` and `LB-AI-SIGHT`. They sit in a new block at the end of the AI section.
- **edits to existing functions:**
  - `LB-AI-HUNT`;
  - `LB-AI-REFLEX`, which now dispatches the turtle;
  - `LB-AI-KIN`, which gains the SANREN cash and the turtle;
  - `LB-AI-SP-ENDER`: NIJŪSHI-KŌ only off K3's crumple, else SANREN, else b2a0's L out;
  - `LB-AI-EXIT-CMD`, which runs the HARD exits first;
  - `LB-AI-KAMAE`, the stance's CPU plan: the charged shot, never the quick one, at HARD;
  - `LILLE-OK`'s `(brain e)` clause: his HARD CPU refuses the Breaker.

Nothing else changed:
- no frame data, damage, cost, rule, human branch, opponent-facing key (`:opp-trace :opp-reflex :opp-reflect :opp-aim`),
  `LB-OPP-TRACE` or other file;
- the awakening (`AI-AWAKEN-P`, `:awaken`) and the revival (the generic `:bankai`);
- the `:ai` plists are byte-identical to b2a0's.

Every new branch sits behind the forms' existing `:sniper` level (`:by (:easy 0 :normal 0 :hard 1)`). So EASY and NORMAL
are the shipped CPU bit for bit: the drift and the pacing JSON are identical to the baseline's. There is no new roll
anywhere: every new rule is deterministic on what the CPU perceives, decided once per event.

**Score 0.9994** = strength **1.000** (400 / 400), masher 1.000, signature **0.999**. For comparison:
- parent b2a0: 0.9945 = 1.000 / 1.000 / 0.986;
- best of the round so far, b0a2: 0.9991 = 1.000 / 1.000 / 0.998;
- baseline: 0.4449.

## 1. The history read

| cell (rescored at 1a7f135) | score | mechanism | what it meant here |
|---|---|---|---|
| baseline | 0.4449 | the shipped CPU | NORMAL drift 0.44; no HARD layer |
| archive v1 b0a0 / b1a0 | (old rules) | the snipe / snap opener (on the gone laying shot), the HOSHA hunt, SP2 cash-outs | the openers were re-derived on the 2 f cancel by every round-1 cell |
| b0a0 | 0.9548 | EN mark + spring, KIN vanish, the hunt, the HOSHA → K1 → L loop | the engines (b2a0 has them) |
| b1a0 | 0.9586 | EN web, hit-and-run, the same loop, the SP2 cash-out | NIJŪSHI-KŌ off J3 gets guarded (b3a0's measurement) |
| **b2a0 (parent)** | **0.9945** | + composure, oki HOSHA / mark, the KIN route, K3's exits, the pendulum, the siege, the vanish | what I refine |
| b3a0 | 0.9883 | spacing, crossfire, enders by frames (J3 → SANREN), refusals (no Breaker) | SANREN fits J3's stagger; the Breaker loses to HARD CPUs |
| b0a1 | 0.9957 | b0a0 + composure, **the rush read**, **hands-off oki**, the turtle, no Breaker, KIN MUJITTAI exits, charged only | located fixes: taken over (credited) |
| b1a1 | 0.9937 | b1a0 + composure, rush-wary hunt, the wake-up charged shot, patient web, KIN SP1 exits | the wake-up timing idea (the sight times a different shot the same way) |
| b0a2 | 0.9991 | b0a1 + the KIN SP ender, **SANREN cash**, **EN MUJITTAI line exit**, **guard wait**, the execution shot (kills only) | located fixes: taken over (credited); it found the idle Reiatsu, but spent it only in KIN and on the kill |
| b1a2 | 0.9984 | b1a1 + clean hand, turtle, held aim, KIN cash-in and hold | the same turtle / clean hand; its veil / KIN-wait negatives respected |

I trusted the rescored numbers. Then I read **the parent's own logs**. My diagnostic is the evaluator's HARD strength
sims (both seats) with the combat log and the `duel lille` counters; it is adapted from b0a2's and kept in my scratchpad.
On b2a0, seeds 1–40 it gave:
- 400 / 400 wins, signature 0.9862, taken **505** a match, Konpaku lost **0.81** a match;
- held-out seeds 41–80: **397 / 400**, signature 0.9865, taken **588**, Konpaku lost **0.95**.

What was left (seeds 1–20, per match):
1. **The generic step-in J string into his wake-up**: `LB-J1:STEP-J`, **39** of the ~57 non-signature damage. b2a0's
   oki returned NIL until its frame. This is b0a1's located fix.
2. **The hunt leapt into his attack startups and rushes**: Konpaku lost right after a hunt, 0.53 a match. This is b0a1's
   and b1a1's located fix.
3. **His Breakers** (the generic guard-break, anti-parry and neutral picks): ~10 plain damage, and 55 damage a match
   taken after `LB-W-BREAKER:GUARD-BREAK`. b0a1, b1a2 and b3a0 all located this.
4. KIN's plain heads (vanish / stance-exit / neutral) and the quick shot, a few damage each. b0a2 and b1a2 closed these.
5. **New: the burst read.** After a fix-only build, I measured what hit him in the 90 frames after the opponent's
   **BLUE burst**: **70 damage a match** (19 % of all he took), 168 a match against Rukia alone (`RU-SHIRAFUNE` 110 a
   hit).
   - The BLUE burst repels Lille to idle, and the burster is free and invulnerable for 20 f.
   - b2a0's hunt then took the stance at once: 898 of 1141 first moves after a BLUE.
   - Rukia's CPU reads the stance (no defence, `:active 0`) as a recovery and cashes it with SHIRAFUNE.
   - No cell had found this.
6. **New: the idle Reiatsu.** His bars sit at 300 in 535 of b2a0's 750 HARD state samples (seeds 1–20, his side).
   b0a2 found the same in its lineage, but spent the bars only in KIN and on the kill shot.
7. **Style**: HOSHA is 73 % of b2a0's damage; the charged shot 0.2 %, HIRENKYAKU 0.1 %.

## 2. The action policy (HARD; EASY and NORMAL are the shipped CPU)

b2a0's policy stays. The sniper is an executioner: HOSHA's loop is his close finisher, and the trace → TENSHIN → KIN route
is Jilliel's. The changes:

**Base 万物貫通**
- **The sight 照準 (new).** With **2 bars or more**, a downed opponent (the loop's blow-away) is met on his first hittable
  frame by **SP2 HIRENKYAKU**, not by the oki HOSHA:
  - its 6 m vanish back, then the X-Axis shot from range (40 + the distance bonus, ~60–75 here);
  - the press comes 16–18 frames before that frame (`LB-AI-SIGHT-P`); this is b0a2's measured timing for the execution
    shot;
  - hands off (`:NONE`) until then;
  - he is left staggered at ~9–10 m. He has to come back in through the sniper's range, where the hunt takes him.
  - Below 2 bars the oki HOSHA's fresh loop stays. The bars come back by dealing damage (0.08 a point) and by the 3 / s
    regen, so the sight comes about every 20 s: 4.9 a match.
  - This differs from b1a1's wake-up shot and b0a2's execution: a different shot (the bar's SP2 from 6 m farther, no
    stance), a different trigger (idle bars, not every blow-away or only the kill), and it stays one oki among two.
- **The burst read (new, located).** While the opponent's BLUE burst is younger than 30 f (his 20 f of invulnerability,
  + the 8 f perception, + 2), the hunt and the siege take no stance (`:NONE`). The eye runs first and still answers any
  threat. He stands, the left eye on watch, instead of offering a recovery to punish.
- **The rush read** (b0a1 / b1a1, credited): no hunt into a perceived attack before its active end, a rush, or a
  projectile.
- **Hands-off oki** (b0a1, credited): `:NONE` until the oki HOSHA's frame.
- **The turtle and the clean hand** (b0a1 / b1a2 / b3a0, credited): his long guard up close (the generic guard-break
  event, consumed once per guard) gets the stance → TAISHA. A parry gets nothing, and his HARD CPU never presses the
  Breaker.
- **The guard wait** (b0a2, credited): a guard inside the hunt's 7.5 m but beyond the siege's 3.2 m is waited out. A guard
  within 3.2 m is b2a0's siege (TAISHA).
- **Charged only** (b0a1, credited): where the shipped plan says the quick shot, HARD charges.

**Jilliel / owl 遠 EN**: b2a0's mark, spring and oki mark. The turtle's hop back. MUJITTAI's exit is a J line at him (the
spring decides), else EN's SANREN with a bar. It never TENSHINs into KIN with nothing (b0a2, credited).

**Jilliel 近 KIN**: b2a0's route, vanish and pendulum, plus:
- **SANREN cash** (b0a2 / b1a2, credited): a perceived reeling or recovering man within 8 m, a bar → SP1, not the generic
  wing-blade punish.
- **The ender**: NIJŪSHI-KŌ only off K3's crumple (40 f fits its S40), else SANREN with a bar (its f12 line fits J3's 26 f
  stagger), else b2a0's L out. The frames are b3a0's and b0a2's.
- **MUJITTAI's exit**: TENSHIN out, else SANREN on his whiff (b0a1 / b0a2).
- **The turtle**: TENSHIN out, else a hop.

**Unchanged**: the eye, the owl beyond these, Trompete, the awakening, the revival, every debug mode (79000–79999), the
learning CPU's clock, and the `duel lille` counters (new keys `ai-sight`, `ai-turtle`, `ai-sanren-cash`,
`ai-ender-sanren`).

**Adaptation (once per event):**
- the sight reads his perceived wake-up and his own bars;
- the burst read reads the opponent's burst (its flash and the HUD gauge);
- the rush read reads his move's phase;
- the turtle reads his guard's length;
- the cash reads his perceived recovery.

## 3. Measurement

**EVAL_COMMAND** (40 seeds; `score.json` is the line it printed for the delivered file; v3 gave the same JSON before a
docstring-only edit):

| | baseline | b2a0 (parent) | **b2a1** |
|---|---|---|---|
| score | 0.4449 | 0.9945 | **0.9994** |
| strength | 0.095 | 1.000 | **1.000** (400 / 400) |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.517 | 0.986 | **0.999** |
| drift (NORMAL share) | 0.44 | 0.44 | **0.44** (Y 44, K 28, R 31, I 35, S 38 of 80: identical) |
| pacing Y / K / R / I / S (s) | 174.2 / 169.2 / 198.1 / 209.0 / 194.7 | identical | identical, all 40 / 40 K.O. |

`sig_by`, b2a0 → b2a1:

| category | b2a0 | b2a1 |
|---|---|---|
| HOSHA bullets | 0.401 | 0.420 |
| HOSHA links | 0.329 | 0.344 |
| trace combos | 0.137 | 0.088 |
| **HIRENKYAKU** | 0.001 | **0.064** |
| traces | 0.038 | 0.024 |
| NIJŪSHI-KŌ | 0.037 | 0.021 |
| Jilliel Kikon | 0.032 | 0.021 |
| SANREN | 0.000 | 0.007 |
| charged shot | 0.002 | 0.006 |
| TAISHA | 0.007 | 0.003 |
| **plain J / K** | **0.012** | **0.001** |
| Breaker | 0.001 | 0 |
| quick shot | 0.000 | (none) |

**The X-Axis share** (his X-Axis lines: HIRENKYAKU, traces, NIJŪSHI-KŌ, SANREN, the charged shot, TAISHA) rises from
**8.5 %** (b2a0) to **12.5 %**. That is b0a2's 10.3 %, and below b1a2's 15.8 %, which leans on the charged wake-up shot.

The HOSHA loop is **76.4 %** (b2a0 73.0 %). The base form now wins sooner, so less of the match is Jilliel's: trace combos
13.7 → 8.8 %. Without the sight, the loop is 82 % (the fix-only build). So the sight moves ~6 points from the loop to the
X-Axis. Stated plainly: the gain over the parent is a cleaner, safer executioner plus the sniper's shot at every fifth
blow-away. It is not a move away from the loop.

**Robustness** (the diagnostic; HARD, both seats, 400 matches a block, the same sims as the evaluator's strength part):

| build | seeds 1–40 | 41–80 | 81–120 | signature (per block) | taken a match | Konpaku lost a match |
|---|---|---|---|---|---|---|
| b2a0 (parent) | 400 | **397** | – | 0.9862 / 0.9865 | **505 / 588** | **0.81 / 0.95** |
| fixes only, no sight, no burst read | 400 | 400 | 400 | 0.9978 / 0.9985 / 0.9985 | 364 / 388 / 355 | 0.06 / 0.08 / 0.07 |
| + the sight at 3 bars (v1) | 399 (eval) | 400 | 400 | 0.998 / 0.9989 / 0.9986 | – / 407 / 410 | – / 0.15 / 0.10 |
| + the burst read (v2: sight 3 bars) | 400 | 400 | – | 0.9986 / 0.9989 | 282 / 310 | 0.07 / 0.11 |
| **final (v3: the sight at 2 bars)** | **400** | **400** | **400** | **0.9986 / 0.9982 / 0.9984** | **330 / 348 / 330** | **0.09 / 0.15 / 0.14** |

How to read it:
- The located fixes take the parent's signature from 0.986 to 0.998 and its damage taken down by a third.
- **The burst read** cuts the damage he takes within 90 f of the opponent's BLUE from **69.9 to 25.7** a match
  (SHIRAFUNE there from 32.5 to 1.4), and his damage taken a match by 25 % (v1 → v2 on the same seeds 41–80: 407 → 310).
- **The sight** costs some robustness for the style, which I state here:
  - at 3 bars it adds ~20 taken a match (388 → 407 on seeds 41–80), and it was in the trajectory of v1's one loss: seed 3,
    L vs Kenpachi as P1. After a sight the HIRENKYAKU hit filled the awakening gauge, and Jilliel EN's generic step-in
    later met Kenpachi's first strike;
  - at 2 bars it fires 4.9 times a match (3 bars: 3.4) and takes HIRENKYAKU from 4.2 to 6.4 % of his damage, for +38 taken
    a match against the 3-bar build, with the same signature;
  - **the final build wins 1200 / 1200 over seeds 1–120.**
- I kept 2 bars: it is the coordinator's preferred direction, and its cost is inside the margin the burst read bought.

Per match (final, seeds 1–40):
- **the base form:** hunts 11.6, oki HOSHAs 7.3, sights 4.9, HOSHA 49.2 (the loop's stances 43.7), sieges 0.6, the
  turtle 0.5, the charged-shot plans 0.4;
- **Jilliel:** marks 3.6 → springs 3.2, vanishes 7.7, the KIN route 3.3, SANREN enders 0.31, SANREN cashes 0.05;
- **the opponents:** blow-aways by him 13.0, their BLUE bursts 2.8.

Host tests:
- duel-rules **6374 ALL PASS**. The LILLE-CPU-TESTS section is b2a0's plus one new check, and none is removed. It is
  spliced with `splice-tests.py` into the frozen file: identical. Its diff only adds lines. The check pins:
  - `*LB-AI-SIGHT-BARS*` 2, `*LB-AI-BURST-WAIT*` 30 > `*BURST-INVULN*`, and HIRENKYAKU's shot frame 20;
  - `LB-AI-SIGHT-P` case by case (wait, fire at 18 / 16, too late at 15, nothing below 2 bars, nothing without a down);
  - SANREN's first line inside J3's stagger, and NIJŪSHI-KŌ's S40 inside K3's crumple.
- duel-control 89 and learn 100: ALL PASS.
- `tools/pkgcheck.sh duel`: 0 / 0 / 0.
- **The awaken A/B was not run.** The awakening and the revival are untouched, and the A/B runs at NORMAL, where this CPU
  is the shipped one bit for bit (the drift's 400 NORMAL matches are identical).

## 4. Why it is not a repeat

- **New and located:**
  - **the burst read** (no cell found it: 70 damage a match after the opponent's BLUE, his largest remaining single
    source after the fixes; −25 % damage taken);
  - **the sight**: the idle bars spent on the X-Axis in the base form, as the oki, every time two bars are there. b0a2
    spent the bars only in KIN and on the kill shot; b1a1's wake-up shot used the stance's charged shot on every downed
    opponent and gave up the oki HOSHA.
- **Credited and recombined** (all measured positive in their own lineages; each closes a leak I located in b2a0's logs):
  - b0a1's rush read, hands-off oki, turtle and charged-only plan;
  - b0a2's guard wait, SANREN cash and EN MUJITTAI line exit;
  - b3a0's / b0a2's ender frames;
  - b1a2's / b0a1's clean hand.
  - b2a0's lineage had none of them. The round's two other top lineages (b0a2, b1a2) never had b2a0's KIN route,
    pendulum or siege.
- **Not repeated:** b1a2's measured negatives (the KIN veil, the KIN wait) and b1a1's TAISHA meaty on wake-up (HARD CPUs
  perfect-Hoho it).

## 5. Expected benefit

At HARD he wins every one of 1200 HARD CPU matches (seeds 1–120). 99.9 % of his damage is his signature. He takes ~340
damage a match (b2a0: 505–588) and loses 0.1 Konpaku a match (b2a0: 0.8–0.95). He never feeds a burst's advantage. One
blow-away in five ends with the sniper's HIRENKYAKU shot from range. EASY and NORMAL are unchanged.

## 6. Risks

- **Pacing:** the NORMAL medians are the baseline's (LI 209.0 and LR 198.1 against cap 240, LS 194.7 against cap 220).
  None is within 15 s of its cap.
- **Style:** the HOSHA loop is still ~76 % of his damage. The sight is the only lever here that moves damage to the
  X-Axis, and its 2-bar threshold already pays ~38 taken a match. A larger shift (every oki a shot) would trade the oki
  HOSHA's loop for one hit.
- **The burst read reads the opponent's burst gauge** (HUD-visible, at once, not through the 8 f snap). Its window ends
  at the invulnerability + the 8 f delay, so the CPU gains nothing a human watching the flash wouldn't. Its answer is to
  stand still (`:NONE`, with the eye first).
- **The `:NONE` waits** pause the generic reflexes and AI-DECIDE's neutral for those steps: the sight's (≤ ~45 f on a
  downed man), the hands-off oki's, the guard wait's, and the burst read's (≤ 30 f). The eye (base) and the learner's
  read run before them. Nothing of a downed opponent can hit him; a hazard left on the floor would not be dodged in that
  window.
- **The ASSIST:**
  - `:sp-ender` on the KIN forms (b2a0's) now ends an assisted human's J3 with SANREN (one bar) and keeps NIJŪSHI-KŌ for
    K3's crumple. Re-run `tools/assistgate.py` at integration.
  - Every other new branch reads `(brain e)` or the reflex's own brain. `LILLE-OK`'s refusal is NIL for a human, so an
    assisted human can still Breaker.
- **HARD may be too strong for a human** (inherited: the 9 f materialise, the HOSHA loop, the frame-exact oki). The sight's
  HIRENKYAKU is visible (the 6 m slide, the 10 f lock rule doesn't apply: it is SP2's quick shot at f20). A waking human
  can Step on it, or guard it (chip 15 %, drain 30).
- **Overfitting:** measured only against the frozen CPUs. The held-out seeds 41–120 agree.

## 7. Shared-code recommendations (not done)

1. **A burst-advantage read in AI-REFLEX** (or the SNAP carrying the opponent's burst invulnerability). Every kit
   reflex that commits on a free step can walk into a BLUE's advantage; Lille's kit had to read the gauge itself.
2. **The opponents' punish readers** (Rukia's ice-cash, the generic punish) take a `:sig` stance with `:active 0` for a
   recovery from f6. That is true for Lille's stance (no defence), so it is not a bug, but it is why any free stance near
   a CPU gets cashed.
3. An ORANGE kit key (so the composure's held J can go), the AI-ATTACK reach filter for EN's ranged J / K at NORMAL, and
   a wake-up field in the SNAP (every earlier cell's recommendations, still open).
