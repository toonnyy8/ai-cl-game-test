# Cell b0a1 (round 1): b0a0's off-string policy + b1a0's set-play conversion, stacked

This cell refines branch 0. It starts from b0a0's `senjumaru.lisp` and adds b1a0's clauses that don't overlap with it. It
is the combination b1a0 recommended. Every change is in the AI section of `duel/lisp/senjumaru.lisp`. No move, frame,
damage, cost or form rule changed.

## History read

| cell | score | strength | masher | signature | direction |
|---|---|---|---|---|---|
| baseline | 0.5714 | 0.512 | 0.700 | 0.619 | the shipped CPU |
| b0a0 (rescored) | 0.6828 | 0.637 | 0.812 | 0.689 | off-string damage first (see below) |
| b1a0 | 0.5944 | 0.575 | 0.637 | 0.610 | set-play conversion (see below) |

- **b0a0** gets her damage off the strings:
  - O / L enders off the pushing J3 / K3;
  - a far punish with K1 / O;
  - spikes on a sure hit;
  - SAIDAN 0.7 on a long guard;
  - an O against his Breaker;
  - the Shikai's HARD neutral bands.
- **b1a0** converts the hits of what she places:
  - a follow-up on a far stun;
  - oki on a knockdown;
  - the soldier escort;
  - the loom's TACHINAOSHI ender at HARD 0.9.
- **They trigger on different states.** b0a0's far punish fires on a recovering *move*, b1a0's follow on a *stun*.
  b0a0's enders are in the Shikai's `:sp-ender`, b1a0's TACHINAOSHI in the loom's. So they stack.

## The policy (per form)

- **Shikai (`:base`).** b0a0 unchanged:
  - the neutral bands (HARD 70 % of decisions): J1 / SAIDAN / K1 up close, SAIDAN / K1 / O at 1.7–2.6 m, O / soldier
    beyond;
  - the O ender 0.85, else the K3 → WARUI KUSE L ender 0.7;
  - the far punish (K1, else O);
  - the spikes on a guard or reel (>= 3 stitches) or against a J masher (>= 2);
  - SAIDAN on a long guard 0.7;
  - the O against his Breaker.

  Added from b1a0:
  - **follow:** a stun seen beyond J1 + 0.6 m → K1, else the O, else the spikes. HARD 0.9, never against a J masher.
  - **oki:** he is down at 2.5–9 m → the soldier (SP1). HARD 0.9.
  - **escort:** her soldier is live and he is beyond 2.4 m → PRESSURE intent, so she walks in behind it. HARD 0.8.
- **The loom (`:tsuji1`–`:tsuji6`).** The kit's bands, weave and pairs are unchanged. Added from b1a0:
  - **follow:** TANMONO-UCHI K1 (3.8 m), the lane O, or TACHINAOSHI under him.
  - **oki:** weave while nothing is stored, or tap a hitting hank timed to his wake-up.
  - **TACHINAOSHI ender:** EASY 0.3 / NORMAL 0.5 (shipped) / HARD 0.9, half that on a cross pair.

  The O-lane ender fallback from b0a0 is kept.
- **Order inside `senju-ai-reflex`.** b0a0's policy reflex runs first, then b1a0's set-play reflex, then the shipped pair
  and stitch rules. So on a stun with >= 3 stitches, b0a0's unguardable spikes come before b1a0's K1 follow.
- **Awakening.** Unchanged (`:awaken (:min-taken 150)`; b0a0 measured that it still pays).
- **Difficulty.** Every chance is in `*senju-dp*`, EASY <= NORMAL <= HARD. NORMAL adds only b1a0's small rolls:
  follow 0.15, escort 0.1, oki 0.2, tachi 0.5 (shipped).

## Iterations (aieval, seeds 1–20)

| version | change | score | strength | masher | signature |
|---|---|---|---|---|---|
| **v1 (delivered)** | b0a0 + b1a0's follow / oki / escort / TACHINAOSHI ender | **0.7170** | **0.688** | **0.850** | 0.672 |
| v2 | v1 with the follow trying the O before K1 (for signature) | 0.6908 | 0.644 | 0.838 | 0.685 |

v2 raised signature by 0.013 but cost 0.044 strength, so it was reverted. The delivered file was re-measured after the
revert and gave the same JSON (the sim is deterministic).

## Measured vs the earlier cells (final file, score.json)

- **Score** 0.717. That is +0.034 over b0a0 and +0.146 over the baseline.
- **Strength** 0.688 vs b0a0 0.637 (+8 wins of 160). That is about +1.3 sigma at ±0.04, consistent with b1a0's own
  +0.06 gain over the baseline. The two gains add.
- **Masher** 0.850 vs b0a0 0.812. This is within the ±0.06 masher noise b1a0 measured, so it is "no harm", not a
  proven gain.
- **Signature** 0.672 vs b0a0 0.689. The follow-ups are mostly K1 strings, which are J / K links, and b1a0 saw the same
  dip.
- **Pacing** OK: NORMAL medians 142–186 s, all 80 matches K.O.

## Why it is not a repeat

No cell has measured this combination. It is the stack b1a0 proposed. The one variant added here (the O-first follow)
was measured and rejected.

## Risks

- **Old risks carry over.** b0a0's neutral takeover depends on AI-NEUTRAL's clock (`brain-decide-t`). b1a0's escort sets
  `brain-intent` directly, and its oki tap reuses `brain-why` `:oki-tap`.
- **Signature fell a little.** It is still above the baseline (0.619). A later cell could recover it with spikes-first
  follow-ups at >= 2 stitches, but the O-first attempt shows strength is the costlier side to trade.
- **The loom is still the weak phase.** Neither branch fixed it. The loom-band variants (b0a0 v3) and zone uptime
  (b1a0 v7) both measured worse.

## Shared-code recommendations (not done)

- Use more masher seeds, or a fixed common seed set, for the masher part. Its ±0.06 noise matches the policy effects
  (b1a0).
- b0a0's anti-Breaker J1 timing note for `ai-reflex` stands.
