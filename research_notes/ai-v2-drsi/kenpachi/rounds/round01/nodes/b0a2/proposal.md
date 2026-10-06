# Kenpachi AI v2, cell b0a2 (round 1, refines branch 0): punish with the charge, not a J1 string

## Result (official `python3 tools/aieval.py --char 1 -j 4` on the delivered ken.lisp, aieval at 9df6ecc)

| | score | strength | masher | signature | pacing (NORMAL medians) |
|---|---|---|---|---|---|
| baseline (re-measured) | 0.3006 | 0.175 | 0.400 | 0.528 | ok |
| b0a1 (parent; reproduced here exactly) | 0.8506 | 0.956 | 1.000 | 0.384 | ok, 135-157 s |
| **b0a2** | **0.8660** | **0.975** | **1.000** | **0.405** | ok: 20/20 K.O. each, 138.6-158.2 s |

## The added mechanism

b0a1 stays as it was: anti-Breaker, anti-mash stance, Hoho a commit, no slow reset, far punish, first strike, lunge J1,
walk-in, the enders and the Bankai gate. One new reflex is added, `ken-sig-punish`, which runs before `ken-far-punish`.

**The trigger.** He recovers (past his active frames) or reels within J1's lunge reach, including closer than the generic
reach. If SP2 (the charge) can be used (enough bars) and lands before he is free, by `KEN-ARRIVE`'s charge model, we use
the charge instead of a J1 string.

**The roll.** It uses the same per-move react roll as the lunge J1 punish. If the roll is below `*ken-ai-sig-punish*`
(EASY 0, NORMAL 0.1, HARD 0.5), we charge. Otherwise the roll goes on to J1 as before.

**Why the charge.** On contact the charge goes into the flurry: 25, then 4 x 25, then a 60 launcher, about 185 in all.
None of it is J / K-link damage. A J1 punish string does J1 35 + J2 / K2S + J3 / K3 (about 110-190), all link damage, and
only its ender (O / SP2) counts as signature. The bars are the limit: the charge is used only while they allow it.

**Per form.**
- Base / KATATE / KATAUDE: the charge is used as described above.
- The Bankai: the same command (SP2 is still `:ke-charge`). There the flurry is replaced by the B-PUNCH string (also
  signature damage).
- RYOTE / NOMIHOSE have no SP2 command, so the reflex never fires and their behaviour is unchanged.

Difficulty: EASY 0, NORMAL 0.1 (pacing unchanged from the HARD 0.9 variant, which shares the NORMAL value), HARD 0.5.

## Evidence (bd.py: aieval's matches with a per-move damage breakdown. At 20 seeds it reproduces aieval's parts exactly.)

| variant | 20 seeds (= official) | 40 seeds |
|---|---|---|
| b0a1 parent | 0.8506 (str .956, sig .384) | 0.8425 (str .944, mash .994, sig .387) |
| + O-punish (O first, all ranges, HARD 0.5) | 0.8377 (str .931, sig .395) | - |
| SP2 ender 0.6 -> 1.0 | 0.8125 (str .894, sig .381) | - |
| **+ sig punish HARD 0.5 (delivered)** | **0.8660** (str .975, sig .405) | **0.8536** (str .956, sig .405) |
| + sig punish HARD 0.9 | 0.8532 (str .950, sig .416) | 0.8506 (str .947, sig .419) |
| HARD 0.9 + O fallback in both punishes | - | 0.8459 (str .938, sig .423) |
| HARD 0.9 + L (stance cut) as a 3rd ender | - | 0.8258 (str .909, sig .413) |

KE-FLURRY damage went from 14.6k to 23.5k (HARD 0.5) and 27.3k (HARD 0.9) per 20 seeds. The total damage dealt stayed
the same (514k to 519k).

**Lessons.**
- **Noise.** Any change to the code shifts the SIM-RND01 stream. A one-number change (SP2 ender 1.0) moved strength by 10
  matches of 160. Strength differences under about 0.03 at 20 seeds are noise. Signature is a damage share and is far
  more stable (it moves 0.003-0.01 between seed sets).
- **The charge punish holds.** At 40 seeds it adds signature (+0.018 at 0.5, +0.032 at 0.9) and does not lose strength
  (0.956 / 0.947 vs 0.944).
- **0.5 vs 0.9.** The two tie at 40 seeds (0.8536 vs 0.8506). 0.5 is delivered because it is ahead on both seed sets.
  0.9 trades about 3 matches in 320 for +0.014 signature.
- **O (the Kikon rush) as a punish fails** at close range and as a fallback. Its aura and rush make it late and
  cooldown-limited, so it adds little signature and costs strength.
- **L (the stance cut) off a pushing ender loses** (strength -0.035 at 40 seeds). The stance's 6 f entry plus the cut's
  startup lets the pushed victim act first, and the stance damage did not even rise.

## Why it is not a repeat

- b0a1, b0a0 and b1a0 only gave signature moves the far punish, beyond J1's reach, or the enders.
- b1a0's "sig-first" punish (v6) forced SP2 / SP1 first together with ender 1.0. It lost strength, but it was on b1a0's
  planner, which lacked b0a0's defensive reflexes.
- Here the charge takes over J1's own punish range, including closer than the generic reach. That is where most punish
  damage is, and b0a1's defence stays.

## Risks

- Bars spent on punishes are not there for the SP2 ender or the far punish. Measured, that is net positive.
- **HARD is very strong** (0.95-0.975 vs the four CPUs).
- The 20-seed strength of 0.975 is partly a lucky draw. The 40-seed figure, 0.956, is the honest one.
- **Signature is 0.405** (baseline 0.528). The J strings from the lunge / first-strike openers still dominate. Any
  string's middle links can only be changed by the static `:ai` tables (`:string-k`, `:l-after-j/k`), which are not
  difficulty-scaled.

## Shared-code recommendations (not done)

1. **A difficulty-scaled string-link hook in STRING-REFLEX.** It would be an `:ai :link-hook` called before the nq / nf
   choice. Kit CPUs could then pick signature cancels mid-string by difficulty. Today only static tables reach there,
   so signature work is limited to openers and enders.
2. **Use more seeds for gating.** aieval's 20-seed strength swings about ±0.03 from RNG stream shifts alone. A 40-60 seed
   strength run, or several seed offsets, would stop the search chasing noise.
