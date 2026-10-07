# b0a2 (round 1, refining b0a1, freeze 1a7f135): the idle Reiatsu on his X-axis lines, and the execution shot

A refine of **b0a1** (rescored 0.9957 at this freeze; my diagnostic of its file reproduced its numbers). It keeps all of
b0a1's engines and knobs: the EN mark → 2 f spring → trace combo, the KIN vanish, the base hunt, the HOSHA loop, the
composure, the oki HOSHA, the turtle, the rush read. It adds five pieces. Each one answers a leak or a gap I located in
b0a1's own logs.

Only `duel/lisp/lille.lisp` changed, and only his CPU:
- **one kit key:** `:sp-ender lb-ai-sp-ender` on `:jilliel-kin`. Its MUJITTAI form inherits it.
- **new knobs:** `*LB-AI-CASH-FAR*`, `*LB-AI-EXEC-MARGIN*`, `*LB-AI-EXEC-SLIDE*`.
- **new functions:**
  - `LB-AI-SANREN-CASH` and `LB-AI-SP-ENDER`;
  - `LB-AI-EXEC-LEAD`, `-P`, `-PLAN-OF`, `-PLAN`, `-LINK-P` and `-STANCE-P`;
  - `LB-AI-EN-SP1-P`.
- **one `LBAI` field:** `exec`.
- **edits to existing functions:** `LB-AI-KIN`, `LB-AI-MARK`, `LB-AI-EXIT-CMD`, `LB-AI-HUNT` and `LB-AI-OKI`.
- **edits to the sim ticks' CPU branches:** `LB-AI-KAMAE` (the stance's plan) and `LB-AI-LINK` (HOSHA's link). Both are
  `(brain e)` code.

What did not change:
- no frame data, damage, cost, rule, human branch, opponent-facing key (`:opp-trace :opp-reflex :opp-reflect :opp-aim`),
  `LB-OPP-TRACE`, or other file;
- the awakening (`AI-AWAKEN-P`, `:awaken`) and the revival (the generic `:bankai` reflex);
- EASY and NORMAL. Every new branch sits behind the forms' existing HARD level (`:by (:easy 0 :normal 0 :hard 1)`), so
  EASY and NORMAL draw exactly the shipped random numbers. The drift and pacing JSON are byte-identical to the
  baseline's.

There is no new roll. Every new rule is deterministic on what the CPU perceives, decided once per event.

**Score 0.9991** = strength **1.000** (400 / 400), masher 1.000, signature **0.998**. The parent b0a1 scored 0.9957
(0.998 / 1.000 / 0.992); the baseline scored 0.4449.

## 1. The history read

| cell (rescored) | score | mechanism | what it meant here |
|---|---|---|---|
| baseline | 0.4449 | the shipped CPU | NORMAL drift 0.44; no HARD layer |
| archive v1 b0a0 / b1a0 | (old rules) | snipe / snap opener (on the gone laying shot), HOSHA hunt, SP2 cash-outs, KIN back-switch | their openers were re-derived by every round-1 cell on the 2 f cancel |
| b0a0 | 0.9548 | mark + spring, vanish, hunt, the HOSHA → K1 → L loop | b0a1's parent |
| b1a0 | 0.9586 | web, hit-and-run, the loop, SP2 (NIJŪSHI-KŌ) cash-out | its KIN SP2 ender was mostly guarded (b3a0 measured 559 of 690), because NIJŪSHI's 40 f is too slow off J3 |
| b2a0 | 0.9945 | composure, oki HOSHA, KIN route, K3 exits (NIJŪSHI with two bars), pendulum, siege | K3 → NIJŪSHI combos (the crumple is 40 f) |
| b3a0 | 0.9883 | spacing, crossfire, **combo enders by frames** (J3 → SANREN, K3 → NIJŪSHI), refusals | SANREN's f12 line fits J3's 26 f stagger: 3.6 a match, 6.7 % of his damage there |
| **b0a1 (parent)** | **0.9957** | b0a0 + composure, the rush read, the f6 evade, the hands-off oki, the turtle, no Breaker | the base I refine; its own leak list (ORANGE, rushes, step-in oki, Breaker) is closed |
| b1a1 | 0.9937 | b1a0 + composure, rush-wary hunt, **the charged wake-up shot**, patient web, KIN SP1 exits | the wake-up shot's timing (the stance 40 f before his first hittable frame); a charged share of 4.9 % |

I trusted the rescored numbers. My diagnostic is the evaluator's HARD strength sims with the combat log and the
`duel lille` counters (`scratchpad/lille-b0a2/diag.py`, adapted from b0a1's; not delivered). On b0a1's file it gave:
- seeds 1–20: 200 / 200, signature 0.9918, taken 622 a match;
- seeds 41–60: 200 / 200, signature 0.9914, taken 638.

What was left (seeds 1–20, per match):
1. **His Reiatsu sits idle.** At the state-hash samples his three bars are full in every form: the median is 300 in the
   base form, EN and KIN. 70–83 % of the samples hold two or more bars. He fires 0.3 SANREN and 0.4 NIJŪSHI-KŌ a match.
   His X-axis SPs, the sniper's lines, are almost never used.
2. **KIN's plain strings were 26 of the 36 non-signature damage a match.** Each one is a new combo, opened by the
   generic follow-up (5.4), the neutral pick (7.4), the step-in (4.2), MUJITTAI's exit (5.1) or the blocked-string reset
   (1.0). The trigger is the end of a trace combo: J3 or K3 lands, the O ender's roll fails, he is still close, and the
   generic J1 restarts a plain string. The vanish only fires once nothing is left to cash.
3. **EN MUJITTAI's exit was TENSHIN in from neutral.** Its 16 f wind-up lands him in KIN with no trace and nothing to
   cash, so the KIN neutral strings follow. At low flash step it is the only exit. My held-out loss in a middle version
   (seed 47 vs Ichigo, below) began with exactly that: in at 4.5 k ticks with 10 flash step, and Ichigo's string and
   Kikon followed.
4. **The base form's plain strings came after a guarded HOSHA.** The hunt correctly refuses a guarding opponent. The
   generic step-in J1 (4.4) and the blocked-string reset (1.4) then took the turn, and the J string landed as he dropped
   the guard.
5. **The long-range sniper is absent** (the coordinator's note). The charged shot is 0.5 % of his damage, and 81 % of the
   base form's time is within 2 m. He never reaches range against these CPUs: he finishes every Soul Break with the
   loop's K1 or bullets.

## 2. The action policy (HARD; EASY and NORMAL are the shipped CPU)

Everything of b0a1 stays as it was: the eye first; the hunt (HOSHA onto a free opponent, never into his attack or rush,
the f6 evade); the HOSHA loop with the composure; the oki HOSHA with its hands-off wait; the turtle (TAISHA through a
long guard, no Breaker); EN's mark and spring; KIN's vanish; KIN MUJITTAI's TENSHIN-out exit. The new pieces follow.

**Base 万物貫通: the execution shot 止め撃ち (new trigger; b1a1's wake-up timing).** The last blow of a Soul Break is
the sniper's.
- **At HOSHA's link.** When a loop's bullet blows him away and his Reishi (on the HUD) is within an X-axis shot's
  damage where he will lie, the link does not chase him with K1. "Where he will lie" is the distance + 4 m of the ~5 m
  blow-away slide, with the shot's damage × his form's ×1.3 × the margin 0.9 (`LB-AI-EXEC-LINK-P`). The K1 chase's 42 f
  whiff would leave no time for a charge.
- **On his wake-up** (`LB-AI-EXEC-PLAN-OF`, re-checked on the real perceived distance):
  - the shooting stance is pressed 40 f before his first hittable frame: the stance up 6 + the charge 24 + the shot's
    startup 10. Its plan is forced to the charged shot (`LB-AI-EXEC-STANCE-P`), which takes the Soul Break from where he
    lies;
  - else, with a bar, **SP2 HIRENKYAKU**: the 6 m vanish back, then the X-axis shot from there, which does more damage at
    the longer range. It is pressed 16–18 f before his first hittable frame, so its f20 shot lands just after it. My
    first version pressed it 18–20 f before: 0 of 0.47 a match hit, because they fired on or before the frame. Two frames
    later, every one landed;
  - while it waits: hands off (`:NONE`, the oki's wait);
  - too late, or no shot finishes him: b0a1's oki HOSHA as before.
- This is limited to the kill on purpose. Everywhere else the oki HOSHA's fresh loop deals more. b1a1's unconditional
  wake-up shot trades that loop for one hit.
- Per match: 0.28 charged executions and 0.52 HIRENKYAKU executions. **0.76 of his 2.3 Soul Breaks a match are now an
  X-axis shot from range**; in the parent the loop's K1 or bullets ended nearly all of them.

**Base: the guard wait (new, located leak 4).** A perceived guard within the hunt's 7.5 m gets `:NONE` (`LB-AI-HUNT`): no
generic step-in J string and no blocked-string reset into it. The hunt fires the moment he drops the guard. A long guard
is still the turtle's (TAISHA through it), because the turtle runs before the hunt.

**Jilliel 近 KIN: the bars on his X-axis lines (new, located leaks 1 and 2).**
- **The SP ender** (`LB-AI-SP-ENDER`, the generic STRING-REFLEX hook, after the O ender's own roll):
  - K3's crumple (40 f) → NIJŪSHI-KŌ with two bars (its beam at S 40);
  - else SANREN with one bar (its first line at f12 inside J3's 26 f stagger; its three lines go through guard).
  - Then the vanish.
  - The frames are b2a0's and b3a0's measurements, credited. This lineage had no ender, and here the bars are free.
- **The SANREN cash** (`LB-AI-SANREN-CASH`, before the vanish): free in KIN, with him perceived reeling or recovering
  for SANREN's 12 f within 8 m, and a bar → SP1. This is where the generic punish or follow-up would open a plain string.
- **MUJITTAI's exit** when the vanish can't pay its flash step: SANREN on his whiff, not a plain J1 / K1
  (`LB-AI-EXIT-CMD`).

**Jilliel 遠 EN: never into KIN with nothing (new, located leak 3).**
- MUJITTAI's exit at HARD is **J1, a line laid at him** (the spring decides as for the mark), not TENSHIN in from
  neutral. Without the flash step for a J line, the exit is the bar's SP1 SANREN: three lines that cost no flash step.
- **The poor mark:** when everything for a mark holds but the flash step, the same SP1 lays its three lines
  (`LB-AI-MARK`, 0.13 a match).

**Unchanged:** the eye, the owl's CPU (its KIN has no ender), Trompete, the awakening, the revival, every debug mode
(79000–79999), the learning CPU's clock, and the `duel lille` counters. The new counter keys are `ai-ender-sanren`,
`ai-ender-nijushi`, `ai-sanren-cash`, `ai-exec`, `ai-exec-hiren` and `ai-mark-sp1`.

**Adaptation, once per event:**
- the execution reads his Reishi and his perceived wake-up;
- the guard wait reads his guard;
- the cash and the KIN exit read his perceived recovery;
- the ender reads his own last link's reaction and his bars.

## 3. Measurement

**EVAL_COMMAND** (40 seeds, frozen evaluator; `score.json` is the line it printed for the delivered file):

| | baseline | b0a1 (parent) | **b0a2** |
|---|---|---|---|
| score | 0.4449 | 0.9957 | **0.9991** |
| strength | 0.095 | 0.998 (399 / 400) | **1.000** (400 / 400) |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.517 | 0.992 | **0.998** |
| drift (NORMAL share) | 0.44 | 0.44 | **0.44** (Y 44, K 28, R 31, I 35, S 38 of 80: identical) |
| pacing Y / K / R / I / S (s) | 174.2 / 169.2 / 198.1 / 209.0 / 194.7 | identical | identical, all 40 / 40 K.O. |

`sig_by`, b0a1 → b0a2 (40 seeds):

| category | b0a1 | b0a2 |
|---|---|---|
| HOSHA bullets | 0.434 | 0.413 |
| HOSHA links | 0.354 | 0.338 |
| trace combos | 0.120 | 0.120 |
| traces | 0.042 | 0.044 |
| NIJŪSHI-KŌ | 0.009 | 0.023 |
| SANREN | 0.001 | 0.018 |
| charged shot | 0.005 | 0.008 |
| HIRENKYAKU | 0.000 | 0.008 |
| **plain J / K** | **0.008** | **0.002** |
| counters | 0.001 | 0.000 |

His X-axis lines (charged, HIRENKYAKU, SANREN, NIJŪSHI) rise from **1.5 % to 5.7 %** of his damage, and the HOSHA loop
falls from 78.8 % to 75.1 %. The gain comes from the sniper's own lines, not from leaning further on the loop.

The path, from my diagnostic. Seeds 1–20 are 200 matches; wins within ±2 are noise, and the signature and damage-taken
columns are steadier.

| version | wins | signature | taken / match | |
|---|---|---|---|---|
| b0a1 (parent) | 200 | 0.9918 | 622 | eval 0.9957 |
| v1: + KIN SP ender, SANREN cash, EN exit by a line | 199 | 0.9964 | 491 | ORANGE 0.34 → 0.03 a match; Konpaku lost 0.56 → 0.30 |
| v2: + the guard wait | 200 | 0.9981 | 490 | eval **0.9991** (1.000 / 1.000 / 0.998) |
| v3: + execution, charged shot only | 200 | 0.9975 | 504 | 0.28 a match |
| v4: + HIRENKYAKU execution (timing fixed) | 200 | 0.9973 | 501 | 0.52 a match more |
| v5: + KIN MUJITTAI SANREN exit | 200 | 0.9976 | 507 | eval **0.9991** (1.000 / 1.000 / 0.998) |
| **v6 (final): + EN's SP1 when poor** | **200** | **0.9977** | **500** | eval **0.9991**; held-out 41–60: **200 / 200, 0.9974, 493** (v5: 199 / 200; parent 200 / 200, 0.9914, 638) |

Ablations of v5, one piece off at a time (seeds 1–20; v5 = 200 / 200, 0.9976, 507):

| off | wins | signature | taken / match |
|---|---|---|---|
| KIN SP ender | 200 | **0.9952** | **620** |
| SANREN cash | 200 | 0.9971 | 508 |
| EN MUJITTAI exit by a line | 200 | 0.9978 | 510 |
| guard wait | 199 | **0.9968** | 508 |
| execution shot (charged + HIRENKYAKU) | 200 | 0.9984 | 496 |

How to read the ablations:
- The ender is the biggest piece: +0.0024 signature and −18 % damage taken. Its SANREN / NIJŪSHI replace the plain
  restart and the ORANGE burst off KIN's last link.
- The guard wait adds +0.0008 and the SANREN cash +0.0005.
- The EN line exit is neutral at 20 seeds (−0.0002). It stays because it is the in-character answer to located leak 3,
  and the poor-mark SP1 that completes it took the held-out loss path away.
- **The execution shot costs about 0.0008 signature at 20 seeds** (more of the match in Jilliel, where KIN's last plain
  strings live). It costs nothing at 40 seeds: v2 without it and v5 / v6 with it all scored **0.9991, signature 0.998**.
  I kept it as the style gain the coordinator asked for, and I'm stating its measured cost here.

The seed-47 loss in the held-out run of v5 (vs Ichigo's KESSA) started in Jilliel: EN MUJITTAI's exit fell back to
TENSHIN in at 10 flash step, then came Ichigo's string and his Kikon. v6's SP1 exit and poor mark remove that path; v6
wins all 400 diagnostic matches.

**Host tests:**
- duel-rules **6381 ALL PASS**. The LILLE-CPU-TESTS section gains 2 checks and removes none of the parent's lines. It is
  spliced with `splice-tests.py` into the frozen file: identical. The checks pin:
  - `:sp-ender` on Jilliel KIN and its MUJITTAI only;
  - SANREN's f12 inside J3's stagger and NIJŪSHI's S 40 inside K3's crumple;
  - the cash range inside SANREN's line;
  - the execution's leads (40 / 20), its margin, its slide, and its plan function case by case.
- duel-control 89 and learn 100: ALL PASS.
- `tools/pkgcheck.sh duel`: 0 / 0 / 0.
- **The awaken A/B was not run.** The awakening and the revival are untouched, and the A/B runs at NORMAL, where this
  CPU is the shipped one bit for bit: the drift's 400 NORMAL matches are identical.

## 4. Why it is not a repeat

- **New and located:**
  - the idle-Reiatsu finding (three bars full most of the match) and its use on his X-axis lines;
  - the execution shot: an X-axis kill timed on the wake-up, triggered by his Reishi, with HIRENKYAKU as its ranged
    variant and the HOSHA link's no-chase rule that makes its window;
  - the guard wait;
  - EN never entering KIN with nothing, through MUJITTAI's line exit and the bar's SP1 when poor.
- **Credited, recombined:**
  - the ender frames: b3a0's J3 → SANREN, and b2a0's / b3a0's K3 → NIJŪSHI;
  - b1a1's wake-up timing, restricted here to the kill.
- **Not repeated:** b1a0's NIJŪSHI-only SP2 cash-out, which was guarded off J3. b0a1's knobs and engines are untouched.

## 5. Expected benefit

At HARD he keeps b0a1's discipline. He now also:
- spends the bars he used to sit on, on his X-axis lines: KIN's strings end in SANREN / NIJŪSHI-KŌ, and a whiff in KIN
  is cashed with SANREN, so no new plain string starts;
- waits out a guard instead of feeding it a J string;
- never drops into KIN from EN with nothing;
- finishes a third of his Soul Breaks with the X-Axis from range, as a sniper.

He wins 400 / 400 HARD CPU matches (and 200 / 200 held out), and 99.8 % of his damage is his signature. Damage taken
falls about 20 % against the parent. EASY and NORMAL are unchanged.

## 6. Risks

- **Pacing:** the NORMAL medians are the baseline's (LI 209.0 and LR 198.1 against cap 240, LS 194.7 against 220). None
  is within 15 s of its cap.
- **The ASSIST:** the new `:sp-ender` on Jilliel KIN reads `AI-BRAIN`. An assisted human's KIN J3 / K3 will cash out
  with SANREN / NIJŪSHI-KŌ when the bars are there (the integration plan wants his signature routes there). Re-run
  `tools/assistgate.py` at integration. Every other new branch reads `(brain e)` or the reflex's own brain, so it never
  acts for a human.
- **The `:NONE` waits:**
  - the guard wait: while he guards within 7.5 m, the generic reflexes and AI-DECIDE's neutral are paused. The eye still
    answers threats first, and the learner's read runs before the kit reflex;
  - the execution's wait: up to about 40 f more on a downed opponent than b0a1's oki wait.

  A human who turtles at mid range meets a patient Lille, not a Breaker. The turtle's TAISHA still answers a long guard
  up close.
- **The execution vs a human:** the lock is visible ≥ 10 f before the charged shot (decision 12), and HIRENKYAKU's slide
  is visible. A waking human can Step or guard (chip 15 %, drain 30). If it misses, the next hunt follows.
- **HARD may be too strong for a human** (inherited: the 9 f materialise, the HOSHA loop).
- **Overfitting:** measured only against the frozen CPUs. The held-out seeds 41–60 agree.

## 7. Shared-code recommendations (not done)

1. **An ORANGE kit key** (`:orange` by difficulty), so the composure's held J can go (b0a0 / b2a0 / b3a0 / b0a1).
2. **A per-difficulty `:o-ender`.** His KIN string's generic non-red O ender still rolls before the SP ender. A HARD
   layer could then prefer SANREN / NIJŪSHI, which combo, over a Kikon that HARD CPUs guard or Hoho.
3. **The generic blocked-string reset and the step-in** ignore a kit that wants to wait out a guard. A kit hook (e.g. a
   `:guard-answer`) would avoid the `:NONE` pause.
