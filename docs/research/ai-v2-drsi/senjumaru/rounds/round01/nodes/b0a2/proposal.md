# Cell b0a2 (round 1): the late awakening (b0a1 + keep the Shikai until she needs the heal)

This cell refines branch 0 and starts from b0a1's `senjumaru.lisp` (0.717). Every change is in the AI section of
`duel/lisp/senjumaru.lisp`. No move, frame, damage, cost or form rule changed.

## History read

| cell | score | strength | masher | signature | what it did |
|---|---|---|---|---|---|
| baseline | 0.5714 | 0.512 | 0.700 | 0.619 | the shipped CPU |
| b0a0 | 0.6778 | 0.637 | 0.787 | 0.689 | off-string damage first in the Shikai |
| b1a0 | 0.5944 | 0.575 | 0.637 | 0.610 | set-play conversion |
| b0a1 | 0.7170 | 0.688 | 0.850 | 0.672 | b0a0 + b1a0 stacked |

- Every cell agrees that the loom (Bankai) is her weak phase. In b0a0's logs she won the Shikai's damage race about
  1.4 : 1 and lost the loom's about 1 : 1.7.
- Two attempts to play the loom better both measured worse: b0a0 v3 (closer loom bands) and b1a0 v7 (zone uptime).
- b0a0 compared never awakening with the shipped rule and found never awakening slightly worse (46 vs 51 wins of 80).
  The awakening is worth something: it heals 20 % of max Reishi (since 2026-09-30) and Kikons take 3 Konpaku.

## The mechanism: when she awakens, not how the loom plays

No earlier cell changed the timing of the awakening. With the shipped rule (EVOLUTION ready and >= 150 taken), she
awakens the moment the gauge fills, so most of the match is spent in her weak form.

The policy:

- **Shikai.** She stays in the Shikai, keeping b0a1's whole policy, and the awakening waits until her Reishi share is at
  most `:awaken-below` (HARD 0.28).
- **The awakening's role.** It becomes her late heal: +20 % lands when she is about to lose, and the 3-Konpaku Kikon
  comes in the endgame.
- **The loom.** It plays as before, only for a shorter stretch.

## Implementation

- **The generic awakening is off.** The base kit's `:ai` gets `:awaken-above 1.01`, a share no fighter reaches. That
  turns off both generic routes: the free-state route and the combo-break route.
  - `:awaken (:min-taken 150)` stays, because `tests/duel-rules-test.lisp` pins it. A first try that set `:min-taken`
    huge failed that check.
- **`senju-awaken`** is the first clause of `senju-ai-reflex`. It returns `:awaken` when all of these hold:
  - EVOLUTION is ready;
  - she is in the Shikai and `awaken-state-p` allows it;
  - she has taken at least `:awaken`'s `:min-taken` (150);
  - her Reishi share is at most `(senju-dp b :awaken-below)`.
- **Difficulty.** `:awaken-below` is EASY 1.0, NORMAL 1.0, HARD 0.28.
  - At 1.0, EASY and NORMAL keep the shipped free-state rule.
  - What they lose is the awakening as a combo breaker, which only the generic burst roll could do (see the risks).

## Iterations (aieval, seeds 1–20)

The threshold is HARD `:awaken-below`. "parent" is b0a1's rule.

| HARD :awaken-below | score | strength | masher | signature |
|---|---|---|---|---|
| parent (1.0, the shipped rule) | 0.7170 | 0.688 | 0.850 | 0.672 |
| 0.0 (never) | 0.6908 | 0.637 | 0.838 | 0.704 |
| 0.15 | 0.7323 | 0.700 | 0.863 | 0.699 |
| 0.20 | 0.7450 | 0.706 | 0.912 | 0.694 |
| 0.25 | 0.7890 | 0.775 | 0.925 | 0.695 |
| **0.28 (delivered)** | **0.7857** | **0.787** | 0.875 | 0.691 |
| 0.32 | 0.7525 | 0.750 | 0.825 | 0.688 |
| 0.40 | 0.7549 | 0.750 | 0.850 | 0.675 |

- **The plateau.** Every value from 0.25 to 0.40 gives strength 0.75–0.79, above the parent's 0.688. That is
  +10 to +16 wins of 160, about 1.5–2.5 sigma at ±0.04.
- **Either extreme is worse.** Never awakening and awakening only very late (0.15–0.2) both fall back. So the heal,
  delivered late, is the source of the gain; avoiding the loom alone is not.
- **The choice.** 0.28 sits inside the plateau. 0.25 sits next to the drop at 0.20, and the two score within noise of
  each other.

**Per opponent at 0.25** (wins of 40; masher wins of 16):

| vs | b0a1 era | 0.25 | masher at 0.25 |
|---|---|---|---|
| Ichigo | — | 35 | 16 |
| Kenpachi | — | 36 | 16 |
| Rukia | 12 | 23 | 10 |
| Yamamoto | — | 30 | 16 |
| Senjumaru (mirror) | | | 16 |

- **Damage sources:** FREEZE 20 %, SJ-BREAKER 19 %, SJ-KIKON 19 %, J1 7 %.
- **Damage dealt / taken:** 472k / 427k, against 389k / 452k for b1a0.

## Measured vs the parent (final file, score.json)

- **Score** 0.7857 vs 0.717 (+0.069), and +0.214 over the baseline.
- **Strength** 0.787 vs 0.688.
- **Masher** 0.875 vs 0.850. That is within the ±0.06 masher noise.
- **Signature** 0.691 vs 0.672. Longer Shikai time means more of her damage comes from the O, SAIDAN and the spikes.
- **Pacing** OK. The NORMAL medians are 149–186 s and every match was a K.O.
  - Yamamoto's median moved from 142 to 152 s. NORMAL lost only its combo-break awakening.
- **Rules test:** 4433 checks, ALL PASS.

## Why it is not a repeat

- No cell changed when she awakens. b0a0 only compared never awakening with the shipped rule.
- No cell used the awakening as a late heal.
- It is orthogonal to every earlier mechanism, all of which changed what she does, not which form she spends the match in.

## Risks

- **`:awaken-above 1.01` is an off switch for the generic awakening.** A shared change to how `:awaken-above` is read
  (for example a clamp to 1.0) would quietly bring back the shipped timing at every difficulty.
- **NORMAL and EASY no longer awaken out of a combo.** That route can't be reached from the kit's `:reflex`, which runs
  in free states only. Pacing stayed fine.
- **HARD never awakens if she stays above 28 %.** Across a whole match that costs nothing, and the never-awaken case
  only happens when she is winning.
- **The share is a single threshold.** A human who knows the rule could build up to 29 % and then burst her down
  through the heal window. That is a CPU-character trade-off, not an exploit of the evaluator.
- **The loom is still weak.** This cell sidesteps it rather than fixing it.

## Shared-code recommendations (not done)

1. **A kit key for awakening below a Reishi share** (`:awaken-below`, the mirror of `:awaken-above`), or an `:awaken-p`
   hook that `ai-awaken-p` calls. Either would let a character time its awakening, including the combo-break route,
   without the 1.01 switch. Other characters with a weaker awakened form, and Ichigo's or Rukia's heal timing, may gain
   the same way.
2. **The earlier recommendations still stand:** the anti-Breaker J1 timing, and more masher seeds.
3. **Next cell:** with the loom now short and late, a loom policy tuned for the endgame (she is low; finishing pressure
   and Kikons at 3 Konpaku) is the obvious refinement. Re-check the 0.25–0.4 plateau at more seeds.
