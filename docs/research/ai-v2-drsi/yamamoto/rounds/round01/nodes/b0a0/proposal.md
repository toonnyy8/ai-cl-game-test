# b0a0 (round 1): Yamamoto's CPU, the J that beats the Breaker on his own short reach, and the fire as the confirm

Final score (tools/aieval.py --char 0, 20 seeds): **0.8237** (strength 0.919, masher 0.800, signature 0.562, pacing ok:
medians 142.7-184.8 s, all K.O.). Baseline: 0.5948 (0.531 / 0.800 / 0.580).

## History used
No earlier cells (round 1, first cell). The baseline's score.json was reproduced exactly (deterministic sim). I wrote
diagnostics on the logged HARD runs (per-form time and damage, what each of his moves leads to, what opens him):

- **The Shikai (base) phase loses the exchange 1 : 2** (dealt 138k, taken 269k over ~50 s a match), while Bankai East
  wins it 1.9 : 1 and West 17 : 1. The match is mostly lost or won before the awakening.
- **The single worst habit: the anti-Breaker J1.** In the Shikai his J1 (0.96 m, S 9) won 32 of ~190 answers to a Breaker
  and the grab landed the rest; in East 173 of ~470. The generic rule presses J1 once the dash is *seen* within J1's
  reach + 1.4 m. With the 8 f delay the dash has already run ~1.3 m, and a Guard-Break Breaker (fired at his long guard
  within 3 m) is inside his reach before the CPU ever sees it dash.
- **The O ender ENJO off a J3 is blocked** 97 of 113 times (-14): ENJO has no dash (`:dash-max 0`), S 20, and J3's
  stagger is short. Off a K3 (crumple) it hits. TAIMATSU off either ender hit 71 of 71.
- The masher part is capped at 0.8 by the evaluator. For the mirror masher job (Yamamoto masher vs Yamamoto CPU)
  aieval counts P1's (the masher's) wins as C's: `side = 0 if c1 == c`. The CPU already wins 100 % of the masher
  matches. This is a recommendation for tools/aieval.py, not a change.

## The action policy (per form)
- **Every form, vs the Breaker (J beats I, timed for his own reach): `yama-anti-breaker`.** From the perceived snap,
  he estimates the Breaker's real distance now: the aura left, or the dash it ran unseen at 0.16 m/f, by
  `snap-start` per phase. J1 goes when two things hold: its active frames reach him (J1 reach + 0.3 m body), and his
  strike (trigger 0.95 m, then startup 8) is not out first. This works out of the aura too, so a Guard-Break Breaker
  started up close is met. HARD 0.85, NORMAL 0.2, EASY 0 (the generic answer runs otherwise).
  - Result: in the Shikai, 306 counter-hits vs 23 grabs (was 32 vs ~155). In East and West, ~560 counters vs ~40.
  - His long guards and West's ward are what the other CPUs Breaker, so the bait now pays him.
- **Every form, confirming the pushed victim off J3 / K3: `yama-sp-ender`.** DUEL_STRINGS §16 says L, SP and O chase
  after the push.
  - He picks the form's paid SP when its bars are there: the Shikai's TAIMATSU (120, 4 m cone), Hellfire's NADEGIRI
    (240), or East's KYOKUJITSUJIN (blade 90 + 9 m sheet 130). Chance HARD 0.95, NORMAL 0.3, EASY 0.1.
  - Otherwise he takes the O ender (TENCHI / ENJO) at HARD 0.85, NORMAL 0.15, EASY 0.05, but never ENJO off a J3.
  - East's Kyokko `:cancel 0.5` still goes first.
  - Measured: TAIMATSU 195 of 199 hit, KYOKUJITSUJIN 289 of 299, TENCHI 281 of 299.
- **The Shikai / Hellfire `:o-ender 0.0`.** The generic non-red O roll (0.15) would still throw ENJO off J3. The O
  ender now comes only through the sp-ender, with its difficulty chances. A red opponent still always gets the O
  (the generic rule).
- **Every form, a stunned opponent beyond J1's follow-up reach: `yama-stun-sp`.**
  - Covers a Guard Break, a crumple, or his own knockback. The generic J1 follow-up whiffed 60 of 64 there in the
    Shikai.
  - The Shikai / Hellfire use SP2 within 3.8 m; East uses KYOKUJITSUJIN within 6 m, with 8 f of stun to spare.
  - It fires only if it lands before he is free. HARD 0.7, NORMAL / EASY 0.
  - TAIMATSU hit 39 of 46. KYOKUJITSUJIN hit 15 of 44, so it needs that bigger margin.
- **Unchanged:** ranges, intents, band weights, guard / Hoho chances, the Bankai / awakening rules (awaken at once:
  East / West are where he wins), West's parry `:react` and ward reversal.

## Measured (HARD strength per opponent, 40 matches each; my log tool, same jobs as aieval)
| variant | Ichigo | Kenpachi | Rukia | Senjumaru | strength | signature | aieval score |
|---|---|---|---|---|---|---|---|
| baseline | 24 | 29 | 11 | 21 | 0.531 | 0.580 | 0.5948 |
| + sp-ender (SP / O confirm) | | | | | 0.525 | 0.632 | 0.6015 |
| + delay-aware anti-Breaker J1 (dash only) | 25 | 32 | 7 | 11 | 0.469 | 0.628 | - |
| + anti-Breaker from the aura, phase-timed | 38 | 39 | 30 | 37 | 0.900 | 0.541 | 0.8081 |
| + no ENJO off J3 | 38 | 39 | 36 | 39 | 0.950 | 0.551 | - |
| + :o-ender 0, stun SP (= final, after a snap-start fix) | 38 | 39 | 32 | 38 | 0.919 | 0.562 | **0.8237** |

- Per form in the final: the Shikai's ratio is 0.51 -> 0.87 and East's 1.9 -> 3.2.
- The signature drop at the anti-Breaker step is expected: J1 counter-hits continue as J links.
- **Tried and dropped: a "middle-band swap" at neutral decisions.** At the decision tick (`brain-decide-t` <= 1)
  he took a fire move instead of the K1 sweep.
  - The Shikai's RYUJIN JAKKA and East's KYOKKO there were blocked more than they hit, and perfect-Hoho'd: strength
    0.863, signature 0.615.
  - KYOKUJITSUJIN alone hit 238 vs 60 punished, but strength was again 0.863, likely from bars taken from the
    confirms.
  - Both lowered the score, so neither is in the final.
- Noise: 160 strength matches give an SD of about 0.024 at p ~0.9. The 0.95 -> 0.92 steps are within noise. I judged
  them by the local outcome counts, not by the win totals.

## Why it is not a repeat
This is the first cell. The mechanism is new to the CPU: the generic `ai.lisp` anti-Breaker answers in perceived
distance only. This answer models the real distance (delay, aura, dash speed) and its own J1's frames. It changes the
rock-paper-scissors outcome against the most common close-range grab, and it is not a weight tweak.

## Difficulty layering
Every new chance is a plist by difficulty, with EASY <= NORMAL <= HARD:

| chance | EASY | NORMAL | HARD |
|---|---|---|---|
| anti-Breaker J1 | 0 | 0.2 | 0.85 |
| SP confirm | 0.1 | 0.3 | 0.95 |
| O confirm | 0.05 | 0.15 | 0.85 |
| stun SP | 0 | 0 | 0.7 |

- NORMAL stays near the shipped play: the shipped generic was SP 0.3 / O 0.15. The pacing check passes (NORMAL
  medians 142-185 s).
- `:o-ender 0.0` in the Shikai / Hellfire is a static plist value. At NORMAL the sp-ender's 0.15 O takes its place,
  minus ENJO off J3.
- No reading of inputs. Everything is from the perceived SNAP, his own state, and SIM-RND01 / the per-event reaction
  roll.

## Risks
- The anti-Breaker timing hard-codes the shared Breaker numbers: `*breaker-aura*`, `*breaker-trigger*`,
  `*breaker-startup*` (read live), and the dash speed (`*yama-breaker-step*` 0.16 m/f, from 9-10 m/s). If the Breaker
  is retuned, the window moves with the first three only.
- `yama-anti-breaker` uses `*match-tick* - snap-start` as the frames since the perceived phase began. The rush
  resets `fighter-hold` per phase, so this holds for `:aura` and `:dash`.
- Human play: the J1 counter makes Breakers into him much worse at HARD. That is intended (J beats I), but the
  learning CPU / assist inherit it only through his kit.

## Shared-code recommendations (not done)
1. `ai.lisp`'s generic anti-Breaker J1 has the same late timing for every short-J character. The same real-distance
   model there would likely help Kenpachi / Ichigo.
2. `tools/aieval.py`'s masher mirror job: use `side = 1` for `h == 6`. The mirror masher's wins are counted as the
   CPU's, which caps masher at 0.8.
3. The generic `:o-ender` roll could skip a no-dash O module off a J ender. Today any kit with a stationary O pays -14
   for it.
