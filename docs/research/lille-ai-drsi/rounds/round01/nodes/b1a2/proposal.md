# b1a2 (round 1, refines b1a1, freeze 1a7f135 / decision 47): the X-Axis, never a plain string — the clean hand, the turtle, the held aim, KIN's cash-in and hold

A refine of **b1a1** (rescored 0.9937 at this freeze; my own run of its file gave the same JSON). Only
`duel/lisp/lille.lisp` changed, and only his CPU:
- a new block at the end of the AI section (after b1a1's): knobs `*LB-AI-CLEAN*`, `*LB-AI-TURTLE*`, `*LB-AI-HELD-AIM*`,
  `*LB-AI-KIN-CASH*`, `*LB-AI-KIN-HOLD*` and functions `LB-AI-CLEAN-P`, `LB-AI-TURTLE`, `LB-AI-TURTLE-STANCE-P`,
  `LB-AI-HELD-AIM`, `LB-AI-KIN-CASH`, `LB-AI-KIN-HOLD`; one `LBAI` field (`turtle`);
- the dispatch in `LB-AI-REFLEX` (the new reflexes per form); `LB-AI-KAMAE` (the stance's CPU plan: the turtle's plan,
  the charged shot instead of the quick one at HARD); `LB-AI-STANCE-OUT` / `LB-AI-EXIT-CMD` / b1a1's `LB-AI-KIN-EXIT` (the
  exit reason passed through, KIN's stance may hold); `LILLE-OK`'s `(brain e)` clause (his own CPU refuses the Breaker).

No frame data, damage, cost, rule, human branch, opponent-facing key (`:opp-trace :opp-reflex :opp-reflect :opp-aim`),
`LB-OPP-TRACE` or other file changed. `AI-AWAKEN-P` / `:awaken` and the `:bankai` revival are untouched; no new kit key the
ASSIST calls. Every new behaviour is a level `(:easy 0 :normal 0 :hard 1)` tested first, so EASY and NORMAL take the
shipped branches and draw the shipped random numbers (drift and pacing byte-identical to the baseline); HARD runs
deterministic rules on what it perceives, once per event (no new roll anywhere).

**Score 0.9984** = strength **1.000** (400 / 400), masher 1.000, signature **0.996** (b1a1 at this freeze: 0.9937 =
0.998 / 1.000 / 0.987; best of the round b0a1 0.9957 = 0.998 / 1.000 / 0.992).

## 1. The history read

| cell (rescored at 1a7f135) | score | mechanism | what it meant here |
|---|---|---|---|
| baseline | 0.4449 | the shipped CPU | HARD 0.095; EN's `:moves` dead at range (AI-ATTACK's reach filter) |
| v1 b0a0 / b1a0 (old rules) | 0.91 / 0.90 | snipe / snap opener (rode the laying shot's flinch) | re-derived by every round-1 cell on the 2 f cancel's timing |
| b0a0 | 0.9548 | EN mark + spring, KIN vanish, base hunt + the HOSHA → K1 → L loop | the engines |
| b1a0 | 0.9586 | EN web, KIN hit-and-run, the loop, SP2 cash-out | the engines (my lineage) |
| b2a0 | 0.9945 | + composure (no generic ORANGE off a bullet), okizeme, KIN J1-K2s-K3 route, siege | composure (already in b1a1) |
| b3a0 | 0.9883 | b1a0 + spacing rule, crossfire, enders, **refusals (no Breaker)** | the Breaker is a measured loser vs HARD CPUs |
| b0a1 | 0.9957 | b0a0 + rush-wary hunt, okizeme hands-off, **the turtle (TAISHA vs a long guard, no Breaker)**, KIN stance left by TENSHIN out | the turtle and the no-Breaker rule, measured +0.005 signature, −93 taken there |
| **b1a1 (parent)** | **0.9937** | b1a0 + composure, rush-wary hunt, wake-up charged shot, patient web, KIN signature exits | what I refine |

Strength is saturated; the room is signature (b1a1 0.987) and robustness. I trusted the rescored numbers, re-ran the
parent's eval (0.9937, the same JSON) and then read **the parent's own logs**: a scratch diagnostic of the evaluator's HARD
strength sims (both seats) with the combat log, every non-signature hit attributed to the form Lille pressed its string's
head in (the stance's MUJITTAI forms apart) and to the head's reason (`brain-why`). The parent, seeds 1–40 (400 matches):
**58.8 non-signature damage a match (1.31 %)**, largest first:

| leak (parent, a match) | where | located cause |
|---|---|---|
| Breaker 10.2 + its BREAKER-STRING 7.5 | all forms | the generic guard-break / anti-parry reflexes and KIN's `:moves` Breaker; the landed Breaker's string is plain |
| base STEP-J 7.0 | base | **new**: b1a1's hunt refuses a guard; after a **guarded HOSHA** the generic step-in J1 met the guard's drop |
| KIN NEUTRAL 7.9, STEP-J 6.7 | KIN (incl. its MUJITTAI) | **new**: in KIN's stance with no exit due the reflex returns NIL and AI-DECIDE steps in; KIN starved of the run's flash step plays the generic neutral |
| KIN FOLLOW-UP 5.6, PUNISH 0.3 | KIN | **new**: a reeling / recovering opponent in KIN is cashed by the generic J1 string (e.g. a trace **guarded into a GUARD CRUSH** vs Yamamoto's West ward: the crush is no hit, so the J string after it is no trace combo) |
| KIN STANCE-EXIT 3.0 | KIN's MUJITTAI | b1a1's exit falls to a wing-blade J1 / K1 when neither SP1 nor TENSHIN out can start |
| quick shot 1.7 | base | the shipped stance plan throws the quick shot on a whiff / at range on a reeling opponent |

Two traces of the history I checked and did **not** chase: after a TENSHIN in whose trace hit, the KIN J1 link is there
2736 of 2774 times (the rest are super-freeze edge cases); a "trace → J1 untagged" I first suspected was my tool's bug.

## 2. The action policy (HARD; EASY and NORMAL are the shipped CPU bit for bit)

The rule this refine adds to b1a1's sniper: **every opening he takes is taken with the X-Axis** — TAISHA's bullet, the
charged shot, SANREN's lines, the traces — never with a plain J / K string he started himself, and never with the Breaker.

**The clean hand (all forms; b0a1's / b3a0's refusal, credited).** `LILLE-OK`'s CPU clause refuses the Breaker for his own
HARD CPU (`LB-AI-CLEAN-P`, `(brain e)`: a human, assisted or not, still has it). AI-ATTACK's neutral picks check `:ok`.

**The turtle (all forms; b0a1's idea, re-implemented in this lineage).** The generic guard-break event (a guard held 24 f
within 3 m, one per guard: `BRAIN-BREAK-KEY`) and the anti-parry case are taken by his kit, so no refused Breaker press is
ever left on the pad: a parry up close gets nothing (`:NONE`); a long guard up close gets the stance → **TAISHA** (base),
**TENSHIN out** (KIN; a hop back when it can't pay), a hop back (EN); MUJITTAI holds.

**The held aim (base, new).** The base form never steps in on a guard within the hunt's band (0–7.5 m): within 3 m the
stance → **TAISHA** (the 3 m back-slide makes room, its 60 X-Axis bullet goes through the guard: chip, drain 30); farther, a
fresh guard is waited out (`:NONE`: his guard drops to act, and the hunt's HOSHA takes him), a long one (a turtle, a ward)
gets the stance → **the charged shot** (drain 30 a shot: four crush a guard, §4.5's plan). And the stance's plan never throws
the quick shot at HARD: where the shipped plan says quick, he holds for the charge (b0a1 measured this neutral; it is kept
for the style).

**KIN's cash-in (new).** KIN free with him perceived reeling or recovering long enough for SP1's startup (and not red in
the Kikon's range: the generic rush takes his Konpaku): **SANREN** (Jilliel KIN; the owl's KIN: MISUJI), three X-Axis lines,
instead of the generic follow-up / punish's wing-blade string. This is also the answer to the West-ward crush: the trace
crushed the guard, the X-Axis lines cash it.

**KIN's hold (new).** In KIN's MUJITTAI with no exit due (`LB-AI-STANCE-OUT`), the generic neutral no longer steps in:
TENSHIN out when it can pay EN's lines after it (the run's price + 9), else the intangible stance holds. Its whiff / idle
exit without SP1 or TENSHIN out holds too (`:NONE`), while the forced exits (180 f, the gauge under 30) still leave as
shipped. Neither the hold nor anything here answers his rush: a Breaker or Kikon on its way (`LB-AI-RUSH-P`, b1a1's test)
goes to the generic anti-rush (J beats I, Hoho, Step) — the located bug class of b1a1's rush fix, which my first hold
re-created (guard breaks on him 0.04 → 0.09 → 0.25 a match with the veil below; back to 0.04 with the yield).

**Unchanged from b1a1**: the hunt and the HOSHA loop with the composure, the wake-up charged shot, the eye, the EN web
(patient on a guard), KIN's hit-and-run and SP2 cash-out, KIN's signature exits, MUJITTAI's entry, Trompete, the owl's CPU,
the awakening, the revival, every debug mode (79000–79999), the `duel lille` counters (new keys: `ai-turtle`,
`ai-held-aim-shot`, `ai-kin-cash`, `ai-kin-hold-out`).

**Adaptation**, once per event, no roll: the turtle reads his guard's length (one per guard episode, the generic key);
the held aim reads his guard (fresh / long) and the distance; KIN's cash-in reads his perceived recovery; KIN's hold reads
his rush and the flash step; the stance's plan reads the stance's reason (the turtle's) at its f6.

## 3. Measurement

**EVAL_COMMAND** (40 seeds, frozen evaluator; `score.json` is the line it printed for the delivered file):

| | baseline | b1a1 (parent) | **b1a2** |
|---|---|---|---|
| score | 0.4449 | 0.9937 | **0.9984** |
| strength (HARD, both seats) | 0.095 | 0.998 | **1.000** (400 / 400) |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.517 | 0.987 | **0.996** |
| drift (NORMAL share) | 0.44 | 0.44 | **0.44** (Y 44, K 28, R 31, I 35, S 38 of 80: identical) |
| pacing Y / K / R / I / S (s) | 174.2 / 169.2 / 198.1 / 209.0 / 194.7 | identical | identical, all 40 / 40 K.O. |

`sig_by` b1a1 → b1a2: plain J / K 0.010 → **0.004**, Breaker 0.002 → **0**, quick shot 0.000 → **0**, counters 0.001 →
0.000; TAISHA 0.015 → **0.019**, SANREN 0.005 → **0.008**, charged shot 0.049 → **0.051**; HOSHA bullets 0.352 → 0.358,
links 0.297 → 0.302, trace combos 0.153 → 0.148, traces 0.052, NIJŪSHI-KŌ 0.030 → 0.027, Jilliel Kikon 0.032 → 0.030.

**Robustness, 1600 HARD matches** (my diagnostic = the evaluator's strength sims, seeds 1–160 in four blocks of 40):

| | wins | signature (per block) | dealt / taken a match | Konpaku lost a match | revivals | guard breaks on him |
|---|---|---|---|---|---|---|
| b1a1 | 1598 | 0.987 / 0.990 / 0.990 / 0.989 | 4458 / **711** | **0.62** | 38 | 0.04 |
| **b1a2** | **1599** | **0.996 / 0.997 / 0.996 / 0.995** | 4484 / **654** | **0.49** | **16** | 0.04 |

Non-signature damage a match (seeds 1–40): **58.8 → 18.3**. What is left: KIN starved of flash step with him free in reach
(the generic neutral's J strings, ~9; see the negatives below), a KIN J1 link whose trace hit landed on his super-freeze
(~1.3), the KIN stance's forced exits (~1.3), his own ORANGE restart (~1.1), Hoho counters (~1.4).

**The path** (each a rebuild; diagnostic seeds 1–40 / 41–80, 400 matches each; signature; damage taken a match):

| step | wins | signature | taken | Konpaku lost | |
|---|---|---|---|---|---|
| b1a1 | 399 / 399 | 0.987 / 0.990 | 691 / 744 | 0.54 / 0.68 | full eval 0.9937 |
| + clean hand, turtle, held aim (wait out any guard, a long one: TAISHA / charged), KIN cash-in, KIN hold | 397 / 400 | 0.995 / 0.995 | 721 / 707 | 0.56 / 0.49 | |
| + **KIN wait**: KIN starved → TENSHIN out at the bare price | 399 / 398 | 0.998 / 0.997 | 755 / 754 | 0.67 / 0.76 | **dropped** (more Konpaku lost) |
| ... KIN wait as a hold (`:NONE` till the run's price) | 397 / 400 | 0.998 / 0.997 | 742 / 726 | 0.60 / 0.65 | **dropped** |
| + KIN's stance holds on a whiff exit with nothing to exit with, charged shot only (KIN wait off) | 399 / 400 | 0.996 / 0.996 | 730 / 710 | 0.61 / 0.51 | |
| + **held aim: TAISHA on any guard within 3 m** (not only a long one) | **400 / 400** | 0.996 / 0.997 | **685 / 635** | **0.52 / 0.50** | 1600 / 1600 over seeds 1–160 |
| + **KIN veil**: KIN starved → MUJITTAI until TENSHIN out | 399 / 399 | 0.998 / 0.998 | 704 / 621 | 0.60 / 0.49 | guard breaks on him 0.25 a match |
| ... the veil and the hold yield to his rush | 398 / 400 (1595 / 1600 over 1–160) | 0.998 / 0.998 | 711 / 627 | 0.62 / 0.45 | **veil dropped**: +0.0017 signature, −5 wins in 1600 (≈ −0.0006 score) |
| **final** = the TAISHA held aim + the rush yield in KIN's hold, no veil | **400 / 400 (1599 / 1600)** | **0.996 / 0.997** | 686 / 635 | 0.52 / 0.50 | full eval **0.9984** |

**Ablations** (one piece off at a time from the step before the TAISHA held aim; seeds 1–40 / 41–80):

| off | wins | signature | taken | read |
|---|---|---|---|---|
| none | 399 / 400 | 0.9958 / 0.9960 | 730 / 710 | |
| clean hand + turtle | 399 / 400 | 0.9930 / 0.9963 | 713 / 694 | +0.0012 signature |
| held aim (the waiting version) | 400 / 400 | 0.9939 / 0.9948 | 674 / 682 | +0.0015 signature but **+40 taken**: led to the TAISHA version, which took it back |
| KIN cash-in | 399 / 400 | 0.9948 / 0.9944 | 723 / 700 | +0.0013 signature |
| KIN hold | 399 / 399 | 0.9935 / 0.9940 | 709 / 728 | +0.0020 signature |
| charged only | 398 / 400 | 0.9956 / 0.9961 | 740 / 716 | neutral (kept for the style, as b0a1 found) |

Host tests: duel-rules **6377 ALL PASS** (the LILLE-CPU-TESTS section: b1a1's checks unchanged + 1 new: the five new levels
0 / 0 / 1, no brain → no refusal, the turtle / held aim's TAISHA plan covering the generic guard-break range and TAISHA's
line reaching from there after its back-slide, KIN's SP1 moves; nothing outside the markers changed: `splice-tests.py` of
the delivered file into the frozen one gives the delivered file), duel-control 89, learn 100 ALL PASS; `tools/pkgcheck.sh
duel` 0 / 0 / 0. The awaken A/B was not run: the awakening and the revival are untouched and the A/B runs at NORMAL, where
this CPU is the shipped one bit for bit (the drift's 400 NORMAL matches are identical).

## 4. Why it is not a repeat

- **Located in the parent's own logs**, each fix aimed at one leak, measured in non-signature damage, damage taken, Konpaku
  lost and guard breaks — not a retune of any b1a1 / b1a0 knob (none changed).
- **New mechanisms no cell had**: the held aim on the guarded HOSHA (the base form's largest plain source; its TAISHA form
  also cut damage taken 720 → 660 and revivals 38 → 16 per 1600); KIN's cash-in with SANREN (incl. the trace-crushed West
  ward); KIN's hold (the MUJITTAI forms handed AI-DECIDE a step-in J) with its rush yield; the charged-only stance plan in
  b1a1's lineage.
- **A new combination**: b0a1's turtle and the b0a1 / b3a0 Breaker refusal (both measured positive in their lineages,
  credited) brought into b1a1's lineage, which still had Breaker + its string as its largest plain source (17.7 a match).
- **Measured negatives, reported**: KIN starved — leaving at TENSHIN's bare price, holding still, or raising MUJITTAI (the
  veil) — each raises the signature (~+0.002) but costs Konpaku / wins (the veil drew 0.25 guard breaks a match before the
  rush yield, and −5 wins in 1600 after it). That moment stays the generic neutral's.

## 5. Expected benefit

At HARD he never hands a guard a plain string or a Breaker: TAISHA's back-slide and X-Axis bullet up close, the charged
shot against a turtle or a ward, SANREN's lines to cash a reeling opponent in KIN, the intangible stance (or TENSHIN out)
instead of KIN's neutral step-in. 1599 / 1600 HARD matches won, 99.6 % of his damage his signature, damage taken −8 %,
Konpaku lost −21 %, revivals (the owl's gamble) −58 % vs b1a1 over the same 1600 matches. EASY and NORMAL unchanged.

## 6. Risks

- **Pacing**: NORMAL is the shipped CPU, so the medians are the baseline's: LI 209.0 (cap 240), LR 198.1 (cap 240), LS 194.7
  (cap 220); none within 15 s of its cap.
- **Style**: still a HOSHA-loop-led CPU (HOSHA bullets + links 66 %); this refine moves the share toward the X-Axis only at
  the margins (TAISHA 1.9 %, SANREN 0.8 %, charged 5.1 %), as the coordinator preferred over leaning further on HOSHA. The
  remaining plain share is KIN's starved neutral, which I could not move without a robustness cost.
- **`:NONE` waits** (KIN's stance hold; the held aim's wait on a fresh guard at 3–7.5 m; the turtle's parry wait): they block
  the generic reflexes after the kit's for those steps, but every one yields to his rush (the generic anti-rush answers),
  the learner's read runs before the kit's reflex, and the kit's own threat answers (the eye, the stance) run before them.
- **The turtle and the held aim vs a human**: TAISHA has a 16 f startup after the 6 f stance; a human can Step / Hoho it
  (the frozen HARD CPUs perfect-Hoho a TAISHA meaty on wake-up, b1a1's finding, but not one fired into their guard: 1.46 hits,
  0.91 guarded a match, Konpaku lost down).
- **The ASSIST**: no new hook it calls; `LILLE-OK`'s refusal reads `(brain e)` (NIL for a human: an assisted human can still
  Breaker); every other new branch reads the reflex's own brain or `(brain e)`.
- **Overfitting**: measured only against the frozen CPUs; seeds 41–160 (held out from the eval's 1–40) agree (1199 / 1200,
  signature 0.995–0.997).

## 7. Shared-code recommendations (not done)

1. The generic guard-break / anti-parry reflexes press a Breaker without asking `KIT-COMMAND-OK-P` (b0a1's recommendation 4):
   a kit refusing it must consume the event itself, as `LB-AI-TURTLE` does.
2. A kit `:reflex` that answers `:NONE` preempts the generic anti-rush clause (b1a1's recommendation 2): a shared `snap-rush-p`
   guard, or the anti-rush clause before the kit's reflex, would protect every kit (this cell hit it again in KIN's hold).
3. An ORANGE kit key (`:orange` by difficulty) so the composure's held J can go (every cell's recommendation); his own ORANGE
   restart is ~1 non-signature damage a match left here.
