# ICHIGO cell b1a0 (round 1): the Konpaku economy (a new direction)

Final file: `ichigo.lisp` here. Only `duel/lisp/ichigo.lisp` changed: the Shikai's `:reflex` (new), KESSA's existing
`:reflex` function, and Ichigo's own CPU functions. `tests/duel-rules-test.lisp`: ALL PASS (4433).

Final measurement, `python3 tools/aieval.py --char 3 -j 4` (20 seeds):

| | baseline (re-measured) | b0a0 (rescored) | **b1a0** |
|---|---|---|---|
| score | 0.5065 | 0.7871 | **0.6598** |
| strength (HARD) | 0.450 | 0.787 | **0.588** |
| masher (HARD) | 0.525 | 0.988 | **1.000** |
| signature | 0.507 | 0.585 | **0.537** |
| NORMAL pacing Y / K / R / S | 189.2 / 170.8 / 207.9 / 197.3 | 165.1 / 167.8 / 205.2 / 190.6 | 189.2 / 170.8 / 207.9 / 197.3 |

The same file at 40 seeds (`--seeds 40`): **0.6317** (strength 0.541, masher 1.000, signature 0.536). The baseline at
40 seeds: 0.5145 (0.453 / 0.706 / 0.507).

NORMAL pacing is the baseline's to the decimal. Every new rule is HARD-only (EASY / NORMAL 0) and is checked before
anything draws a random number, so NORMAL plays and draws exactly as shipped.

## What the history and the logs said

- b0a0 was a reactive cell: timed Hoho, parry, long punish, chasing enders. It left Rukia below even, because her lunging
  J1 out-ranges KESSA and stuffs Ichigo's Breakers.
- **A match is won in Konpaku, not damage.** Baseline vs Rukia, 40 matches: Ichigo dealt 158k damage and took 122k, yet
  won 5 of 40. A per-match ledger (`KIKON on` / `SOUL BREAK on` log lines) showed why:
  - Rukia took 347 Konpaku, Ichigo 229. Her awakened Kikons are worth 3. Ichigo's KESSA Kikons were worth 2 in 48 of
    ~80 cases, because 千影's worth is the clones at the O press (2 / 2 / 3 / 4).
  - Each side's neutral red rush landed about 1 in 3. The generic CPU answers a rush it sees within 5 m with J1, a Hoho
    or a Step. Example: seed 1, Ichigo's 4-clone rush hit a red Rukia, and her J1 landed the same tick, so no Kikon.
  - The generic CPU never guards a rush while it is red. But the first strike is guardable red or not
    (`KIKON-OUTCOME`), so red rushes landed freely on it.
- Clones at the KESSA O press, baseline: the O ender went out with 0 / 1 / 2 / 3 clones 491 / 333 / 60 / 53 times. The
  shipped bank (from 45 % of his Reishi) was spent by the 0.6 non-red O ender and by clone answers before the red O
  came.

## Action policy (行動方針), HARD

**KESSA: the clone bank.**
- `ichigo-bank-at` is 1.0 at HARD: KESSA keeps 3 clones banked all the time. `ichigo-bank-target` wants 3 down to 25
  guard gauge.
- The 4 % "O with clones" poke is off at HARD, so it doesn't spend the bank.
- With a full bank the reflex goes on to the clone-reach J / K; the shipped rule stopped there.
- A non-red O ender still bursts the bank for +30 per clone. It is rebuilt at once, so the red O usually finds 2-3
  clones (worth 3-4).

**Both forms: the conversion on a red man** (`ichigo-ai-convert`). It runs when he is red, our Kikon is ready, and it is
not the Soul-Break finish.
- **Rush only where his answer can't come:**
  - he is busy: recovering from a move as perceived, longer than our rush takes (`ichigo-rush-frames`), 0.9 per his
    action;
  - or from 7-8.4 m, where he sees the rush inside 5 m only as it strikes: 0.3 a step;
  - KESSA with a bank of 2+ also chains him (KUSARI-BIKI at 3.8-7 m, 0.15 a step). The bind is a stun, so the generic
    stun rush follows with every clone.
- **Closer than 7 m, the neutral decision is ours.** The generic neutral rush is suppressed by taking over the decision
  timer. Below 5 m it attacks (J / K strings via `AI-ATTACK`, whose ender's O always comes on a red man). In KESSA it
  first back-steps to post a clone while the bank is short.

**Both forms: our own red phase** (`ichigo-ai-red`).
- Guard his Kikon rush (aura, dash or the strike's startup, within 11 m; 0.95 per his action, the gauge able to take
  the 20). Blocked, he is -14.
- Else SOUL REVERSE (WHITE, +70 Reishi a second): 0.25 a step while he isn't swinging at us.
- Guarding alone (v1) only turned his Kikons into Soul Breaks, which are worth one more. Rukia's Kikons fell 66 -> 27,
  her Soul Breaks rose 9 -> 43, and the net was zero. WHITE is what climbs out of red.

**Against a J masher** (`ichigo-ai-keep-out`, when `AI-MASH-P`). This is spacing, not b0a0's parry or Hoho timing.
- K1 as he walks through 2.9-4.1 m (perceived): 0.5 a step. He only swings inside his J reach, so K1 meets him first.
- Inside his J reach + 0.4 m, a back Step (0.3). In KESSA the Step posts a clone that answers the next K.

**Unchanged:** ranges, bands, the stance, enders, parry chances, awakening, every NORMAL / EASY behaviour.

## Evidence

Steps at 40 seeds (strength at 40 seeds is about +/-0.03):

| step | score | strength | masher | signature |
|---|---|---|---|---|
| baseline | 0.5145 | 0.453 | 0.706 | 0.507 |
| v4: red guard + WHITE, conversion, bank from 0.65 | 0.5345 | 0.491 | 0.675 | 0.526 |
| v5: + masher keep-out | 0.5715 | 0.447 | 0.994 | 0.523 |
| **v6: + always bank (final)** | **0.6317** | **0.541** | **1.000** | **0.536** |
| v8: v6 with a stricter masher test (6 J starts) | 0.6014 | 0.491 | 1.000 | 0.535 |
| v7: v5 with the stricter masher test | 0.5532 | 0.441 | 0.925 | 0.519 |

Ablations of v6, strength only at 80 seeds (640 matches, about +/-0.02; scratch `str.py`):

| variant | strength | Y / K / R / S wins of 160 |
|---|---|---|
| **v6 (final)** | **0.536** | 77 / 145 / 38 / 83 |
| no conversion (`ichigo-ai-convert` off) | 0.467 | 58 / 136 / 31 / 74 |
| no red phase (`ichigo-ai-red` off) | 0.472 | 67 / 136 / 22 / 77 |
| + walk out to 4-6 m while red | 0.489 | 63 / 140 / 25 / 85 |
| WHITE 0.5 a step | 0.508 | 70 / 145 / 33 / 77 |
| WHITE only from 4 m | 0.511 | 72 / 140 / 35 / 80 |
| clone-reach J / K 0.16 a step | 0.495 | 72 / 143 / 23 / 79 |

Bank-timing variants (20-seed diagnostics):
- Banking only once he is red (v3) made it worse. The red O ender fires the moment he goes red, and it took 3 clones
  only 12 times.
- Banking from 0.65 (v2) helped a little.
- Banking all the time (v6) was the largest single step: +0.05-0.09 strength.

Vs Rukia (diagnostic runs, both seats): baseline 5 of 40 (20 seeds), v6 17 of 80 (40 seeds). Of her
411 red-rush presses, 150 are now blocked.

The sim is deterministic: the final file re-measured 0.6317 at 40 seeds, identical to v6 (only comments changed).

## Why it is not a repeat of b0a0

b0a0 answers his moves on perceived timing (perfect Hoho, parry, long punish) and chases off the §16 enders. This cell
leaves every reaction to his moves as shipped. It works on the match's currency instead:
- the clone bank, which sets KESSA's Kikon worth;
- where and when our red rush goes, chosen against the generic CPU's rush answer;
- how we live through our own red phase (guard the guardable strike, WHITE out);
- range control against the masher.

None of these mechanisms exist in b0a0. The two should stack: b0a0's timed Hoho / parry are KESSA reflex clauses that
fire on his attacks, mine fire on red states and the bank. That is an untried combination for round 2.

## Risks

- **Rukia is still the weak pairing** (38 of 160 at 80 seeds). Her O-ender Kikons on a red Ichigo are the largest
  source: 151 in 80 matches. A completed string can't be guarded after J1 lands, and WHITE spends the flash-step that a
  BLUE burst would need.
- **Strength noise.** Single 40-seed runs of near-identical files spread 0.49-0.54. The 80-seed ablations are the firmer
  read; the final 20-seed line (0.588) is on the lucky side.
- **Taking over `brain-decide-t`.** Close to a red opponent this skips the generic neutral guard and dash for those
  decisions.
- **The masher test** is the shared `AI-MASH-P`, so keep-out also fires on CPUs' restarted J strings. The stricter test
  measured worse on the masher (0.925) and no better on strength.

## Shared-code recommendations (not done)

1. **The generic CPU never guards a Kikon rush while red** (`ai-reflex`'s anti-breaker clause and the threat clause
   send a red CPU to Hoho / Step / J1). The first strike is guardable red or not, so a red CPU should guard it. This
   cell's `ichigo-ai-red` does it for Ichigo; every character would gain.
2. **The neutral red rush rolls anywhere inside `:kikon-range`**, mostly inside the 5 m where the generic answer comes.
   A generic "rush when busy or from beyond the answer range" would help every CPU.
3. **`:o-ender` per difficulty.** KESSA's 0.6 non-red O ender bursts the clone bank for +30 a clone. A
   `(:easy :normal :hard)` value, or a kit hook to decline the non-red ender, would let a HARD KESSA keep its bank for
   the red O.
