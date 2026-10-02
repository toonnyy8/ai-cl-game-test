# SOUL DUEL: the learning CPU

The user, 2026-09-29: 「簡單的學習演算法，能快速從與玩家的對戰中學習」, applied to the fighting game. The plan was approved
with 「好，幫我開分支實作！」. This document covers the design as built, its constants, the fairness rules, the storage
format and the measurements.

**Files:** `duel/lisp/learn.lisp` (the pure part: tables, counting, prediction, EXP3, p_exploit, storage; host-tested by
`tests/learn-test.lisp`); the end of `duel/lisp/ai.lisp` (the hooks: `learn-step`, `learn-fire`, `learn-neutral`,
`learn-weights` / `learn-window`); `flow.lisp` (`learn-match-start` / `learn-match-end`, the SETTINGS rows);
`duel/web/pwa.js` (storage); `debug.lisp` (the scripted players and the learning gate). All of it is character-free.

## 1. What it is

A CPU facing a human carries a **learner** (`brain-learn`, a `lrn` struct). It has two parts:

1. **A player model (n-gram).** It predicts the human's next action in the current situation and answers it with a
   counter from the CPU kit's own commands.
2. **A bandit on the kit's `:moves` weights.** It re-weights the neutral pick by how well each command has paid off
   recently.

At every decision, with probability **p_exploit** the CPU takes the model's counter, provided the prediction is
confident. Otherwise it draws from the bandit-adjusted table. p_exploit follows the human's recent results: it reads a
human who is winning more, and one who is losing less.

## 2. Situations (8; 9 since v2, §10: `:c-hit`)

A situation is seen from the CPU about the human. The human's state is the **perceived** one (the delayed `snap`, as
every CPU reflex sees him). The CPU's own state is felt at once, as the existing AI does. `learn-onset` decides which
situation begins on a step:

| # | Key | Onset | Episode |
|---|---|---|---|
| 0 | `:wake` | he enters `:wakeup` | 75 f |
| 1 | `:knock` | we enter `:wakeup` (his oki) | 75 f |
| 2 | `:h-blocked` | his `:guard-hit` ends | 75 f |
| 3 | `:c-blocked` | our `:guard-hit` ends (we blocked his string) | 75 f |
| 4 | `:whiff` | his move ends having touched nothing | 75 f |
| 5–7 | `:close` / `:mid` / `:far` | no episode open, both free (idle / guard / run); by distance < 2.5 / < 5 / beyond | 60 f |

Events (0–4) override an open neutral episode. An episode closes on his first action, or at its timeout. A timeout
while he holds guard counts as `:guard`.

## 3. Action classes (9; 10 since v2, §10: `:burst`)

`learn-action` classifies what he starts:

- `:guard`: he raises a guard (entering `:guard`).
- `:j` / `:k` / `:i` / `:l` / `:sp` / `:o`: a move by its kind (Quick, Flash, Breaker (the grab), Signature, SP,
  Kikon rush), from a free state or as a new link.
- `:hoho`: a Hoho or a Step.
- `:back`: he moved more than 1.2 m away within the episode. Per-step jumps over 0.5 m (a Hoho) are not walking.

## 4. The player model

For each situation `s` it keeps:

- order-0 counts `c0[s][a]`;
- order-1 counts `c1[s][prev][a]`, where `prev` is his last class in that same situation.

On an observation, the order-0 row and the order-1 row are multiplied by **0.97** (`*learn-decay*`, so a habit fades
after ~30 sightings), and then the class gets +1.

**Prediction** (`learn-dist`) is order 1 backed off into order 0:

p(a) = (c1[s][prev][a] + K · c0[s][a] / n0) / (n1 + K), with K = 2 (`*learn-backoff*`).

With no order-1 evidence, p(a) = c0[s][a] / n0. A prediction is acted on only when n0 ≥ 1.5 (two sightings) and the
best class has p ≥ 0.4 (`learn-confident-p`). Order 2 was left out: order 1 with backoff already predicts every
scripted habit within the first match.

**Counters** (`*learn-counters*`, built on 防 > J > I > 防 from DUEL_STRINGS §14):

| Predicted | Counter | Why |
|---|---|---|
| guard | **I** (Breaker) | I beats guard |
| J | **guard** (30 f) | guard beats J |
| K | **J** | J beats K |
| I | **J** | J beats I (the anti-breaker J) |
| Hoho / Step | **wait, then punish** | don't feed his Hoho (guard 12 f), and prime a J that fires when his Hoho is *seen* (through the perception delay) |
| back off | *none* | chasing him paid off 5 % of the time in the gate; the kit's own ranges do better |
| L, O | guard | |
| SP | Hoho (guard without flash-step) | |

A J or K counter is pressed only within its reach + 0.4 m, and every counter only when `kit-command-ok-p` allows it.
Event counters are planned at the onset and pressed once the CPU is free. On his wake-up, a J / Breaker waits so that
it meets the end of the wake-up: 30 f, less the perception delay, less ~8 f of startup. Neutral counters replace the
neutral decision (since AI v2, 2026-10-02: on the learner's own clock in `ai-reflex`, before the kit's `:reflex`, both free,
after the Kikon and pip-hurry checks; `learn-read-due`, docs/DUEL_AI_V2.md).

## 5. The bandit

The arms are the neutral commands `:q :f :sig :sp1 :sp2 :breaker :kikon :step :hoho nil` (nil = wait) in 5 distance
bins (< 1.6, < 3, < 5, < 7 m, beyond). Each (bin, arm) has a score S, and the kit's weight is multiplied by exp(S)
(`learn-weights`), so every kit keeps its own shape.

- **Reward:** after a neutral pick, the damage dealt minus the damage taken over the next **90 f**
  (`*learn-window*`), / 150 (`*learn-norm*`), clamped to [-1, 1]. A new pick settles the open window early.
- **Discounted EXP3:** every score of the bin × **0.98** (γ), then S[arm] += **0.15** · r / max(p, 0.05). Here p is
  the arm's probability in the pick it was drawn from. S is clamped to ±ln 4, so a weight is × ¼ … × 4. The discount
  keeps it following a human who adapts back.

## 6. p_exploit and the human's form

The form f ∈ [-1, 1] is the human's recent results:

- Every 120 f: f ← 0.95 f + 0.05 · r_h, where r_h is his damage balance over those frames, / 150, clamped.
- At match end: f ← 0.8 f + 0.2 · (+1 if he won, −1 if he lost, 0 on a draw).

Then **p_exploit = clamp(0.35 + 0.4 f, 0.15, 0.6)** (`*learn-p-exploit*`). A human who keeps losing is read at
0.15. The CPU never reads inputs, and never reacts faster than its perception delay: it only predicts from what it has
already seen, and even the Hoho punish fires on the delayed snap.

## 7. Fairness and determinism

- **On** only for P2 in **VS CPU** (two hands or one-handed) and **ENDLESS**, with the LEARNING CPU setting ON
  (`learn-match-start`).
- **Off** for CPU VS CPU, PRACTICE, and after any debug command (`*learn-debug-off*`, set by `debug-command`). The only
  exception is the learning gate, which attaches its own learner.
- Off means inert. With `brain-learn` NIL no learner code runs, and the learner never calls `sim-rnd01`: its dice are
  its own LCG (`learn-rnd`), seeded from the sim stream's state without drawing from it. The other shared changes
  (`snap-contact`, `gauges-counters`, the `habit` / `learn` brain slots) are pure bookkeeping.
- **Verified:** the full native gate (15 pairings × seeds 1–20) is **row-identical** before and after (691 / 691 lines).
  `simgate.py --cvc` passes, and so does the browser G2 (`style-gates.py cvc dist/duel`, same references).

## 8. Settings and storage

- **SETTINGS** gains **LEARNING CPU ON / OFF** (a `*settings*` row, default ON, saved as `soulduel.learn`), then
  **RESET LEARNING** (every table forgotten, in memory and in storage; its note says DONE for 2 s), then BACK.
- **Per CPU character** (roster index i), one table: `soulduel.learn.<i>` holds comma-separated integers. A table is
  loaded from the page the first time it is used, kept in memory, and saved at every match end (`learn-match-end`).
  Blocked storage reads as empty: the table then lives in memory only.
- **Page protocol** (`pwa.js`):
  - `get(100 + 1000 i)` is the entry count, and `get(100 + 1000 i + 1 + j)` is entry j.
  - `set(... + 1 + j, v)` stages an entry, and `set(100 + 1000 i, n)` commits the first n (0 = forget).
- **Entry** = index × 65536 + value + 32768:

  | Index | Holds | Scale |
  |---|---|---|
  | 0–71 | order-0 counts | × 10 |
  | 100–747 | order-1 counts | × 10; only the 400 largest (`*learn-cap*`) |
  | 800–849 | the scores | × 1000 |
  | 900–907 | the last class per situation | + 1 |
  | 950 | the form | × 1000 |
  | 999 | the format version | |

  Counts under 0.05 are dropped. A full table is ~150–550 integers (a few KB). Decoding skips unknown entries and
  clamps counts at 0.
- **The cue** (an eye glyph by the CPU's name) was left out: the HUD name rows are dense in portrait.

## 9. Verification

**The learning gate** (debug `200000 + 1000 h + 100 c1 + 10 c2 + m`; seeds from `30000+k` / `31100+n`, as the seed
gate):

- P1 (roster c1) is a CPU with a scripted habit h (`*habits*`): 0 plain, 1 J on every wake-up, 2 guard after every
  block, 3 grab-happy (the Breaker at every close neutral decision), 4 Hoho-happy (Hoho at neutral decisions and into
  every committed move).
- P2 (roster c2) is the CPU: m 0 = no learner, 1 = model + bandit, 2 = model only, 3 = bandit only. Its table starts
  fresh and is kept in memory across the matches.
- Each match logs a `duel learn row` with the winner, damage, counter-hits, reads (and those that paid off: damage
  dealt and nothing taken within 60 f; a guard counter pays by taking nothing), p_exploit, the form, the model's
  prediction per situation, and the reads per counter.

It runs natively: `ecl --load tools/simgate/run.lisp -- build/simgate/duel.fas 30000 31130 203011`.

**P2's win rate**, 30 matches × 6 fresh runs (180 per cell; mode 1 = the learner, 0 = the plain CPU; blocks of 10
matches; ch = P2's counter-hits per match):

| Human (P1) habit | P1 v P2 | learner, matches 1–10 / 11–20 / 21–30 | plain CPU | model only | bandit only |
|---|---|---|---|---|---|
| plain CPU | Yama v Ken | .58 / .62 / .65 (**.62**) | .43 | .54 | .57 |
| J on wake-up | Yama v Ken | .65 / .62 / .72 (**.66**) | .46 | .52 | .63 |
| guard after block | Yama v Ken | .65 / .57 / .60 (**.61**) | .40 | .55 | .60 |
| grab-happy | Yama v Ken | .90 / .75 / .83 (**.83**), ch 3.5–4.0 | .61, ch 2.9–3.0 | .71 | .66 |
| Hoho-happy | Yama v Ken | .57 / .57 / .53 (**.56**) | .48 | .56 | .60 |
| plain CPU | Ken v Rukia | .62 / .68 / .70 (**.67**) | .69 | .72 | .74 |
| guard after block | Ken v Rukia | .77 / .75 / .73 (**.75**) | .69 | .74 | .77 |
| grab-happy | Ken v Rukia | .87 / .88 / .73 (**.83**), ch 2.9–3.1 | .62, ch 1.8–2.2 | .77 | .68 |
| Hoho-happy | Ken v Rukia | .77 / .68 / .70 (**.72**) | .65 | .67 | .73 |

- **It learns quickly:** most of the gain is already there in the first matches. The early curve (24 fresh runs,
  blocks of 2 matches) rises further, e.g.:
  - Hoho-happy YK: .40 → .52 → .65 → .56 → .62, against a plain CPU at .31–.48;
  - guard-after-block KR: .71 → .77 → .83 → .85 → .77, against .65–.73.
- **Grab-happy** is where the model shines. Its J (J beats I) lifts P2's counter-hits from ~3.0 to ~3.7 a match (YK)
  and from ~2.0 to ~3.0 (KR).
- **J on wake-up** barely occurs in Ken v Rukia (Kenpachi is rarely knocked down), so that row is omitted.
- **The only cell below its baseline** is plain Ken v Rukia (.67 vs .69, within noise); its parts alone score .72 and
  .74.
- **Counters that paid off** (all runs): J 87 % (the Hoho punish's J included), guard 75 %, Breaker 43 %, and the Hoho against a predicted SP 6 % (4 of 66).
  Chasing a backing-off human (the dropped `:dash` counter) paid 5 %.

**p_exploit backs off.** Over the learner's 1080 matches:

- after a match the human (scripted P1) lost, p_exploit averaged **0.24**; after one he won, **0.46**;
- against the habits he loses with most (grab-happy, 73–76 % losses), the mean is 0.29–0.30, against 0.34–0.35 where
  he wins 41–43 %;
- it reaches the floor (0.15–0.16) in every configuration.

**Other gates:**

- `./build.sh duel`: 0 warnings.
- Host tests: touch 60, control 71, input 31, rules 4102, cine 18, **learn 74** (n-gram counting and backoff, decay,
  prediction and counters, situations and classes, EXP3 and its clamp, p_exploit's clamp, the form, the own stream,
  and the storage round trip, including the size cap and garbage).
- `style-gates.py smoke dist/duel dist/game`, `tools/pkgcheck.sh duel`, the touch script (exit 0) and the name-leak
  grep (with learn.lisp) all pass.
- In the browser, a learning gate run twice showed the table saved to `soulduel.learn.1` and loaded back by the second
  run (the wake-up evidence went on from 2.9 to 4.7).
- The SETTINGS stills fit in landscape 1280×720 and portrait 390×844.

## 10. v2: the newer mechanics (the user, 2026-09-30)

The user asked whether the learner picks up the mechanics added after it (the three bursts, the guard lock, Rukia's Hoho
into -273 ...), then 「幫我把你推薦的都加進去，並更新基礎 AI」. Built:

- **A burst is an action class** (`:burst`, the 10th): his burst is read from his gauge at once (its aura; the snap
  carries no burst). **A new event situation `:c-hit`** (index 5; the neutral bands move to 6-8): our string's hit that
  makes his burst possible (his combo reaches `*burst-min-hits*` and his flash-step has `*fs-burst*`). There only a
  burst is his action (the knockback is not backing off); the combo ending or the 75 f timeout counts as `:guard` (he
  took it). Per-situation counters (`*learn-sit-counters*`): a predicted burst in `:c-hit` is **baited** (`:bait`: the
  string ends at its 2nd hit, `string-reflex`, then a guard: his BLUE breaks nothing and costs his flash-step); a
  burst predicted in neutral (WHITE, regenerating) is rushed (`:dash-in`).
- **The bandit has contexts**: the form's index in its character's kits (definition order, 8) x the kit meter's third
  (3), so 24 x 5 bins x 10 arms. A neutral Hoho the kit's band leaves out gets `*learn-hoho-w*` 0.3 (when it may go),
  so a Hoho can be learned where it pays (e.g. -50 near a full cold gauge: Rukia's dive into -273).
- **Burst bandits**: per colour (WHITE / BLUE / ORANGE) a use / don't two-armed EXP3 (`learn-burst-p`: p e^u / (p e^u +
  (1-p) e^n)) re-weights the base AI's own roll (`ai-burst-rolled`: `*ai-white-p*`, `*ai-burst-p*`, `*ai-orange-p*`;
  the same one draw of the sim stream). A decision opens a 90 f window (unless one is open); its reward is the damage
  balance plus the Reishi healed (no soul lost in it).
- **Storage format 2** (`learn-encode`): indices 0-89 order 0, 100-999 order 1, 1000-2199 the bandit (its 300 largest),
  2300-2308 the last classes, 2400-2405 the burst scores, 2950 the form, 2999 the version. A saved format 1 table is
  read into it: the model (situations shifted past `:c-hit`) and the form carried over, the old bandit dropped.

**The base AI** (every CPU; the gates change):

- **The Soul Break finish** (`ai-sb-finish-p`): with the opponent under `*ai-sb-finish*` 0.08 of his Reishi, no Kikon
  rush and no O ender: hits finish him, the Soul Break takes the Kikon count + 1.
- **ORANGE off an L / O hit** (the rule since the user's 2026-09-30 decision): `ai-orange-p` also on a landed `:sig` /
  `:kikon` move, as off a string's last link.

**Measured.** Native seed gate (15 x 20): 300 / 300 K.O., medians 153.0-218.8 s (II 213.4, SI 218.8 over 210, as before
at 226.6 / 214.0). The awaken A/B ("never" wins of 60, streams 100 / 300 / 500): RY 35 / 37 / 34, RK 34 / 28 / 26, RR 32 /
27 / 27; SY 31 / 29 / 28, SK 17 / 21 / 17 (failing as before), SR 34 / 24 / 29, SS 30 / 28 / 23, SI (Senjumaru) 39 / 27 /
32; Ichigo 1-8, failing as before. G2: all three changed (yk now `winner P1 konpaku 7-0 ticks 9328 secs 155.5`).

The learning gate (P2's win rate, 30 matches x 4 fresh runs = 120 per cell; habit 5 is new: a burst-happy player,
BLUE at every chance):

| Human (P1) habit | YK: plain / learner | KR: plain / learner |
|---|---|---|
| plain CPU | .48 / **.68** | .72 / **.73** |
| grab-happy | .68 / **.82** | .60 / **.84** |
| Hoho-happy | .40 / **.60** | .67 / **.86** |
| burst-happy | .59 / **.68** | .68 / **.75** |

Against the burst-happy player the model predicts `:c-hit` = burst at 0.73 (a plain CPU player: guard, 0.86), and its
guard reads (the bait's guard among them) pay 92-93 %.
