# Kenpachi AI v2, cell b0a1 (round 1, refines branch 0): b0a0's reflexes + b1a0's closing-speed first strike

## Result (official `python3 tools/aieval.py --char 1 -j 4`, the delivered ken.lisp, aieval at 9df6ecc)

| | score | strength | masher | signature | pacing (NORMAL medians) |
|---|---|---|---|---|---|
| baseline (re-measured) | 0.3006 | 0.175 | 0.400 | 0.528 | ok |
| b0a0 (parent, rescored; reproduced here) | 0.7995 | 0.894 | 0.875 | 0.441 | ok, 146-166 s |
| b1a0 | 0.7823 | 0.844 | 0.988 | 0.393 | ok, 133-161 s |
| **b0a1** | **0.8506** (score.json) | **0.956** | **1.000** | **0.384** | ok, 20/20 K.O. each, 135-157 s |

## What changed against b0a0 (all in duel/lisp/ken.lisp, "the CPU" section)

b0a0's reflex chain stays as it was: anti-Breaker, anti-mash stance, Hoho a commit, no slow reset, lunge J1, walk-in, the
enders and the HARD Bankai gate. Two parts of b1a0 that b0a0 does not have are added, in this order after no-reset:

1. **`ken-first-strike`** (b1a0's neutral first strike). `KEN-CLOSING` reads his perceived closing speed from the SNAP we
   see and the one before it in the brain's ring. Both are at least the perception delay old, so nothing is read early.
   - J1 if, after our delay plus J1's startup, he will be inside J1's reach plus its lunge (at most 0.8 m).
   - Else K1, if he is closing and will land between his J's reach (reach + slide + 0.2) and K1's reach.
   - **New here: the chance is split by `AI-MASH-P`.** Against a J masher: HARD 0.35, NORMAL 0.02 (b1a0's value).
     Against anyone else: HARD 0.15, NORMAL 0.01. b1a0 used 0.35 against everyone, and that cost strength and signature.
2. **`ken-far-punish`** (from b1a0's intercept punish, restricted to what b0a0 lacks). He recovers or reels **beyond**
   J1's lunge reach (b0a0's lunge punish covers inside it), within 9 m. `KEN-ARRIVE` models SP2's 14 m/s charge and
   SP1's leap. The first of SP2 or SP1 that lands before he is free is used (HARD 0.9, NORMAL 0.2, one roll per move).
   K1 was dropped from the list. It made no measurable difference (0.8433 vs 0.8434), and SP only feeds the signature.

Per form, nothing changes in the tables. The moves' data decides:
- RYOTE / NOMIHOSE: MEN has no lunge, so K1's 3.9 m does more of the first strikes.
- The Bankai: B-J1's lunge is capped at 0.8 m.
- Base / KATATE: the charge and the leap are what the far punish uses.

Difficulty layering: every new chance is EASY 0 <= NORMAL small <= HARD full. EASY still plays the shipped CPU.

## Measurement path (every row a full 20-seed aieval run; the sim is deterministic, so -j does not change results)

| variant | change | strength | masher | sig | score |
|---|---|---|---|---|---|
| b0a0 | parent, reproduced | 0.894 | 0.875 | 0.441 | 0.7995 |
| v1 | + first strike 0.35 (all) + far punish (SP2/SP1/K1) | 0.906 | 1.000 | 0.373 | 0.8183 |
| v2 | first strike 0.35 vs masher, 0.10 otherwise | 0.950 | 0.975 | 0.392 | 0.8433 |
| v3 | far punish without K1 | 0.950 | 0.975 | 0.392 | 0.8434 |
| v4 | + Breaker on a guarding opponent at mid range (HARD 0.08) | 0.869 | 0.988 | 0.414 | 0.8015 (reverted) |
| **v5 (delivered)** | v3, first strike vs others 0.15 | **0.956** | **1.000** | **0.384** | **0.8506** |
| v6 | vs others 0.25 | 0.881 | 0.950 | 0.379 | 0.7945 (reverted) |

**Lessons:**
- **The first strike is a strong anti-masher tool.** Against anyone else it helps only in small doses. Strength against
  the non-masher rate: 0.10 gives 0.950, 0.15 gives 0.956, 0.25 gives 0.881, 0.35 gives 0.906. That is non-monotonic, so
  part of the 0.15 peak is likely seed noise. A 60-seed check of 0.10 vs 0.15 would settle it.
- **A Breaker on a guarding CPU loses** (v4: strength -0.08). The CPUs drop guard and hit the Breaker's long startup.
- **Signature keeps falling when J1 opens more.** The first strike's J1 strings are J-link damage: 0.441 -> 0.384.
  The strength gain (+0.062 x 0.6) and the masher gain (+0.125 x 0.2) outweigh it (-0.057 x 0.2).
- **Tooling gotcha:** aieval rebuilds only when a source is newer than build/simgate/duel.fas. Editing ken.lisp while a
  build runs leaves a stale fas that looks up to date. `touch` the file and re-run.

## Why it is not a repeat

- b0a0 had no anti-masher answer that reads movement: its stance at 0.35 got 0.875.
- b1a0's planner replaced b0a0's defensive reflexes (Hoho a commit, no slow reset, anti-mash stance), so it lost strength.
- This cell runs both chains together, which b1a0's own proposal recommended. The new part is gating the first strike's
  rate on `AI-MASH-P`. Measured, it is the difference between v1 (0.818) and v2 / v5 (0.843 / 0.851).

## Risks

- **HARD is very strong** (0.956 vs the four CPUs).
- **NORMAL pacing is a bit faster** than b0a0's: medians 135-157 s vs 146-166 s, still far below 220.
- **The signature is the lowest of the three cells** (0.384).
- **The 0.15 rate may be partly noise** (see Lessons).
- **`AI-MASH-P` also fires against CPUs** that restart J often. Those CPUs then see the 0.35 rate.

## Next cells
- **Raise the signature without J1:**
  - Use the stance as the anti-K answer more often (it nets +35 per start against CPUs in b0a0's logs).
  - Off a landed ender, try SP2 before O, Bankai excepted.
  - The Breaker in neutral is ruled out (v4).
- **A 60-seed sweep** of the first strike's rate against non-mashers.

## Shared-code recommendations (not done)
Same as b0a0 / b1a0:
- Generic reflexes should use a J1's slide (lunge) reach.
- They should use an arrival / closing-speed model for punishes and first strikes.
- The generic Hoho timing should subtract the perception delay.
