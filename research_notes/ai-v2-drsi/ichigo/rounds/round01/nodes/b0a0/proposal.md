# ICHIGO cell b0a0 (round 1): perception-timed defence + chasing enders

Final file: `ichigo.lisp` here (only `duel/lisp/ichigo.lisp` changed: the forms' `:ai` plists and Ichigo's own CPU
functions). Final measurement, `python3 tools/aieval.py --char 3 -j 4` (20 seeds):

| | baseline | b0a0 |
|---|---|---|
| score | 0.4765 | **0.7471** |
| strength (HARD) | 0.450 | **0.787** |
| masher (HARD) | 0.525 | **0.787** |
| signature | 0.507 | **0.585** |
| NORMAL pacing medians Y / K / R / S | 189.2 / 170.8 / 207.9 / 197.3 | 165.1 / 167.8 / 205.2 / 190.6 (all K.O.) |

Per opponent (HARD, both seats, 20 seeds each): Yamamoto 16/40 -> 37/40, Kenpachi 33/40 -> 40/40, Rukia 5/40 -> 17/40,
Senjumaru 18/40 -> 32/40. Mashers: Yamamoto, Kenpachi and Senjumaru 16/16, Rukia 3/16 -> 15/16, Ichigo 16/16.

## History used

Round 1 had no earlier cells, only the baseline (shipped AI, 0.4765) and docs/DUEL_ICHIGO.md "The CPU with the stance and
the clones" (earlier stance and clone-banking work). My own baseline breakdown showed:

- Rukia was the hole: 5/40 in strength, 3/16 as a masher.
- KESSA's parry from neutral never fired against a J: J startup 7-9 is below HARD's 8 f perception delay.
- Half the damage came from J / K links. KESSA's Kikon was the largest non-link source.

## Action policy (行動方針)

**Both forms, reactive layer (HARD).** The core of the cell: act on what the perceived snapshot says will land, with
the perception delay subtracted.

- **The timed Hoho** (`ichigo-ai-perfect-hoho`, the largest gain).
  - Trigger: his strike lands 0-11 frames from now. That is the perceived startup left minus our delay, so the Hoho
    falls inside `*perfect-lead*` 12. He must be within his reach + 1.5 m.
  - Moves: any move with active frames, including slow J's and the Breaker's strike.
  - Result: the automatic counter (60), his inputs locked 40 f, 15 flash-step back. In KESSA the Hoho also posts a
    clone in front of him.
  - Chance: HARD 1.0, EASY / NORMAL 0.
  - Only the Hoho's own price is needed. The generic Burst reserve is not kept, because the perfect refund pays most
    of it back.
  - In KESSA it runs before the parry.
- **The long punish** (`ichigo-ai-long-punish`).
  - Trigger: out of J's reach, he is recovering or reeling, as perceived.
  - Tools, in order: K1, then SOGA (5 m lunge), then KUSARI-BIKI (7 m chain). It picks the first that lands before
    he is free.
  - Chance: one roll per his action, EASY 0 / NORMAL 0.15 / HARD 0.8.
- **Against a masher** (`ichigo-ai-mash`, when `AI-MASH-P` is on).
  - KESSA lays the parry within 2 m. It catches the next J, and the counter crumples him.
  - Either form K1s him as he walks in at 1.7-2.8 m.
  - Chance per step: EASY 0 / NORMAL 0.03 / HARD 0.25.
  - Parry from blockstun on his blocked J: HARD 0.6.

**Ender policy (`:sp-ender ichigo-ai-ender`, both forms).** After a J3 / K3 hit pushes him just out of reach, a move
started off the ender chases.
- The Shikai: SOGA (SP2, 130) with a bar, else the O poke.
- KESSA: KUSARI-BIKI (pull to 1.6 m + 40 f bind, then the J follow-up).
- Chance: HARD 0.95 (the O poke takes all of the rest), NORMAL / EASY none. Those keep the generic 0.3 SP cancel, the
  shipped behaviour.
- It returns NIL without a brain, because the ASSIST's AUTO COMBO calls STRING-REFLEX for a human.

**KESSA.**
- Parry seen coming (the shipped lead 4-22 rule): EASY 0.6x / NORMAL 0.35 / HARD 1.0.
- Parry from blockstun after a blocked K link: EASY 0.6x / NORMAL 0.3 / HARD 0.8.
- **ZANZO** (SP2) at 2.6-7 m, or while he is down / launched, when he is not attacking: HARD 0.15 a step. Every attack
  is echoed at half damage, which counts as signature (`IC-HIT`). Shipped use was 0.74 a match.

**Unchanged.** Ranges, neutral weights, stance branch logic, clone banking and awakening rule are as shipped. NORMAL
differs from shipped only by:
- the long punish at 0.15;
- the masher answers at 0.03;
- draw-order shifts.

**Shared hooks.** Reached only through existing keys: `:reflex` (new `ichigo-ai-shikai` for the Shikai, an extended
`ichigo-ai-kessa`) and `:sp-ender`. The CPU part of `parry-from-blockstun` in the `:tick` hook is the existing CPU code,
re-scaled. No frame data, damage, cost or rule changed. `tests/duel-rules-test.lisp`: ALL PASS (4433).

## Evidence (40-seed runs, the decision basis; 20-seed noise is about +/-0.02 on the score)

Steps that were kept (40-seed scores):

| step | score | strength |
|---|---|---|
| v1: long punish, enders, masher answers, parry x1.6 | 0.601 | 0.559 |
| enders at HARD 0.95 / 1.0 (v2) | 0.6077 | 0.566 |
| ZANZO 0.05 (v3) | 0.6381 | 0.616 |
| ZANZO 0.15, wider (v4) | 0.6455 | 0.619 |
| timed Hoho 0.6 (v5) | 0.6506 | 0.628 |
| timed Hoho 0.9 (v6) | 0.6787 | 0.675 |
| timed Hoho first in KESSA, 1.0 (v7) | 0.6985 | 0.706 |
| wider window / kinds (v8) | 0.7124 | 0.728 |
| no Burst reserve (v9) | 0.7216 | 0.744 |
| parry HARD 1.0 + blockstun 0.8 (v10 = final) | 0.7366 | 0.769 |

Ablations on v1:
- Without the enders: strength 0.519, signature 0.511. The enders are worth about +0.04 strength and +0.03 signature.
- Long punish at NORMAL's 0.15: 0.544 strength. Within noise; kept for the punishes it adds.

The sim is deterministic: re-running v10 reproduced 0.7366 exactly.

## Tried and dropped (all measured, all within noise or worse)

- Releasing an idle neutral guard after 14 f (against Breakers): 0.534 strength.
- Banking clones from 0.6 / to 3. More bank Steps, but no better O-with-clones mix: clones vanish on hits.
- **A pre-emptive close-range parry against any J poker: strength 0.341.** Parry whiffs against CPUs are very
  expensive. Keep parries reactive.
- HARD parry kept at 0.35: 0.537. Skipping KESSA's neutral K1 band decision: 0.547.
- ZANZO "press" (pressure intent, faster decisions while it runs): 0.591.
- A HARD anti-Breaker (J1 led by the delay / Hoho): 0.709. The J1-only version: 0.731.
- Declining the generic guard-break Breaker (0.7, or only from beyond 1.6 m): 0.731 / 0.738. Ichigo's Breakers get
  stuffed by Rukia's J1 about 3.5 times a match, but they are net positive overall and signature damage.
- J-link blockstun parry for every CPU: strength +0.003, masher -0.03.
- The O rush as a far long punish: +0.006, and it moves NORMAL pacing.

## Why it is not a repeat

The baseline AI tuned what to throw and where to stand (stance bands, clone banking). This cell changes how Ichigo
answers: timing from the perceived snapshot minus the perception delay (the perfect Hoho window, the parry window,
punish windows), and a chase policy fitted to the §16 push-out enders. Neither existed in the shipped kit's AI.

## Risks

- **Rukia is still below even** (17/40). Her J1 with its 0.6 m lunge out-ranges KESSA's J, and she stuffs Ichigo's
  generic guard-break Breakers. A spacing or footsies layer is the next direction.
- **NORMAL pacing vs Rukia is 205.2 s**, with 15 s of margin at 20 seeds. It was 196.8 at 40 seeds.
- **The timed Hoho at 1.0 makes HARD Ichigo a hard read for humans.** It only fires on moves with startup above the
  delay (8 f), and NORMAL / EASY never use it.

## Shared-code recommendations (not done)

1. **`tools/aieval.py` masher seat bug.** In the mirror masher job (masher = the scored character), `side = 0 if
   c1 == c` picks the masher's seat. So the CPU's 16/16 wins there score 0, and the masher ceiling is 0.8 for every
   character. The seat should be P2 (`c2`) for `mash` jobs.
2. **Difficulty-scaled `:ai` table values.** `:string-k`, `:l-after-k`, `:o-ender`, `:block-string` and the neutral
   weights are static. Allowing `(:easy x :normal y :hard z)` in `ai-table` would let a cell layer the string routes.
   Two examples: HARD K2/K3 on hit for the K3 push and chase, and KESSA's O-ender poke spending banked clones.
3. **The generic anti-Breaker (`ai-reflex`)** answers on stale distance. Ichigo's J1s lost to Breakers about 1.6 times
   a match against Rukia. A delay-led estimate might help every character. My Ichigo-only test did not show it.
