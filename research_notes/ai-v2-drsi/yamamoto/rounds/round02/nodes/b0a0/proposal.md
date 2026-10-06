# b0a0 (round 2, new direction from round 1's b0a2): fire as openers and confirms

**Final score** (tools/aieval.py --char 0, 20 seeds): **0.8728**. The parts are strength 0.912, masher 1.000 and
signature 0.627. Pacing passes: NORMAL medians are 139.1-184.8 s, and every match ended in a K.O.

| part | b0a0 r2 (final) | b0a2 r1 (start) | baseline |
|---|---|---|---|
| strength, 20 seeds | 0.912 | 0.969 (lucky seeds) | 0.531 |
| strength, 40 / 80 seeds (my diag, same jobs) | 0.919 / 0.905 | 0.950 / 0.931 | - |
| signature, 40 / 80 seeds | 0.629 / 0.625 | 0.591 / ~0.59 | 0.58 |
| NORMAL win rate (40 seeds, both seats, 320 matches) | **0.441** (median 157.3 s) | 0.500 (156.7 s) | shipped **0.431** (157.3 s) |

**Verdict.**
- The direction does what it set out to do. Signature rose by +0.035 (80 seeds).
- It pays for that with -0.026 strength (80 seeds), about 1.9 SD.
- Net score at 80 seeds is about 0.868, against the parent's 0.877.
- Every fire-for-link swap I measured traded sig : strength at about 1.3-2.2 : 1. Break-even under
  0.6 strength / 0.2 signature needs 3 : 1, so no swap paid on the score.
- NORMAL is back to the shipped level: 0.441 vs 0.431. The parent was +0.07 above it.

## Evidence (scratch opener tally on b0a2, 20 seeds HARD)
I attributed damage to the move that opened each exchange: C's next non-STRING move start.

- Link damage was 217k and fire 310k.
- **58 % of the link damage comes from the anti-Breaker J1 strings.** East / West's E-J1 gave 78k and the Shikai's J1
  gave 48k.
- The next biggest sources were the J1 follow-up on a stun (23k) and the neutral K1 / E-K1. Those K1s lose their
  exchanges: dealt / taken 0.53 and 0.69.
- Neutral openers, dealt / taken:

  | opener | dealt / taken |
  |---|---|
  | KYOKUJITSUJIN | 1.47 |
  | RYUJIN JAKKA | 1.16 |
  | Breaker | 0.70 |
  | KYOKKO | 0.45 |

- West's parry counter (W-COUNTER) was 128 per use with almost nothing taken.

## Policy implemented (on top of b0a2; NORMAL and EASY are 0 for every new chance)
- **YAMA-ANTI-BREAKER-FIRE** (inside YAMA-ANTI-BREAKER, HARD 0.85). It reuses b0a0's delay / aura / dash model of the
  Breaker. The form's L goes when its first cut meets him before his strike; otherwise the J1 path runs as before.
  - **The Shikai / Hellfire: RYUJIN JAKKA.** The first cut is f16-19 at 2.6 m, then the second cut and the wave:
    30 + 30 + 110, with no bar spent. It fires only when SP2 is not affordable. With a bar, J1's string plus its SP
    confirm deals more (about 212 vs 138).
  - **East: KYOKKO** (the lunge and its 4.6 m line). It almost never fires, because the Bankai Breakers come at West's
    ward and West's L is SHONETSU.
- **YAMA-NEUTRAL-FIRE** (HARD 0.6), East only. At a neutral decision, with him *guarding* within 1.0-2.6 m and 2 bars
  held (one kept for the confirm), KYOKUJITSUJIN replaces the band's pick. The blade breaks the guard, then the sheet
  hits. It takes the decision the way b0a2's rush veto does.
- **YAMA-FIRE-PUNISH** (HARD 0.8). A recovering opponent beyond the generic J1 punish reach, but in fire reach, gets
  the form's fire if it lands before he is free: RYUJIN JAKKA / TAIMATSU, NADEGIRI, KYOKKO / KYOKUJITSUJIN. A paid SP
  goes only with a bar to spare.
- **YAMA-STUN-KYOKKO** (HARD 0.8). In East, a stun beyond J1's follow-up reach that the second KYOKUJITSUJIN can't
  reach gets KYOKKO. That mostly means the knockback left by our own confirm.
- **The NORMAL layer.** b0a0's anti-Breaker J1 at NORMAL goes from 0.2 to 0.0, so EASY 0 <= NORMAL 0 <= HARD 0.85.
  That alone brought NORMAL back from 0.500 to the shipped 0.441 vs 0.431. HARD is unaffected.

## Tried and dropped (HARD, my diag; 40 seeds unless noted)
| variant | strength | signature | note |
|---|---|---|---|
| b0a2 (start) | 0.950 / 80 s: 0.931 | 0.591 | |
| + fire punish (v1) | 0.944 | 0.596 | rarely fires |
| + stun KYOKKO (v2) | 0.941 / 80 s: 0.923 | 0.596 / 0.593 | rarely fires |
| + anti-Breaker fire always (v3) | 0.925 / 80 s: 0.912 | 0.619 / 0.617 | RYUJIN JAKKA 138 per use vs J1 string ~104 + SP confirm |
| v3 + West parry on any melee startup (v4) | 0.909 | 0.627 | Rukia 68 -> 60 |
| v4, K / SP startups only (v5) | 0.903 | 0.624 | Rukia still 60: the generic 0.7 :react is right |
| anti-Breaker fire only without a bar (v6) | 0.931 / 80 s: 0.909 | 0.609 / 0.605 | |
| v6 + Shikai neutral RYUJIN JAKKA for K1 (v7) | 0.891 | 0.647 | repeats b0a0's finding |
| v3 + East neutral KYOKUJITSUJIN, 2 bars, any state (v8) | 0.906 | 0.647 | |
| v3 + East neutral KYOKUJITSUJIN on a guard (v9 = final HARD) | 0.919 / 80 s: 0.905 | 0.629 / 0.625 | |

Noise: the strength SD is about 0.014 at 320 matches and 0.010 at 640. Every single step is within 1-2 SD. The
cumulative loss from b0a2 is not noise.

## Why it is not a repeat
Round 1 spent fire only in the confirm off J3 / K3 and on stuns. This cell puts fire into three other places:
- the Breaker answer (J beats I, with the J replaced by a fire cut),
- the punish beyond J reach,
- a guard-crush neutral opener.

It also measures the exchange rate of each. b0a0's middle-band swap is re-measured (v7) and agrees with b0a0's
finding.

## Risks
- YAMA-NEUTRAL-FIRE resets ai-neutral's decide clock (the same coupling as b0a2's veto).
- The anti-Breaker fire uses b0a0's hard-coded dash speed.

## Shared-code recommendations
1. **A string-link hook.** The CPU can't end a J string early into fire. string-reflex always takes the next link,
   and `:sp-ender` runs only after link 3. With a link hook, the 58 % of link damage from J1 counter strings could be
   cut to J1 -> fire.
2. **The signature weight.** At 0.2 vs 0.6, no in-kit fire swap pays for Yamamoto. His fire is slower and costs bars,
   while J beats everything.
