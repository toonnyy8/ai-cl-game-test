# b0a1 (round 1, refines b0a0): b0a0 plus East's fire on a close stun; the b1a0 combination measured and dropped

**Final score** (tools/aieval.py --char 0, 20 seeds): **0.8608**.

| part | b0a1 | b0a0 (parent, rescored) | baseline (rescored) |
|---|---|---|---|
| strength | 0.906 | 0.919 | 0.531 |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.585 | 0.562 | 0.580 |
| score | 0.8608 | 0.8637 | 0.6348 |

- Pacing passes. NORMAL medians are 142.7-184.8 s (the same as b0a0's), and every match ended in a K.O.
- At 40 seeds, b0a0 and b0a1 score the same within noise: b0a0 0.8488 (strength 0.894, signature 0.563) and
  b0a1 0.8474 (0.884 / 0.584).
- At 320 strength matches the SD is about 0.017, so the 20-seed gap of -0.003 is noise. **The cell keeps the parent's
  strength and raises signature by +0.022.**

## History used
- **b0a0** (0.8637): a delay-aware anti-Breaker J1, SP / O confirms off J3 / K3, and a stun SP beyond J1's follow-up
  reach.
- **b1a0** (0.7466): a timed perfect Hoho through the Breaker, plus a Shikai / Hellfire guard clock.
- The brief allowed combining them, so I measured each of b1a0's parts on top of b0a0 (20 seeds):
  - **The Hoho as fallback** (J1 first, then the Hoho on its own Hoho roll): 0.8601 (strength 0.912). Neutral, so
    dropped.
  - **The Hoho plus the guard clock**: 0.8362 (strength 0.875). The guard clock costs about 7 wins.
  - **Why the combination doesn't stack:** b0a0's J1 already wins the Breaker exchange, which leaves the Hoho almost
    nothing to answer. The guard clock trades guard time for J1 / back hops that get punished.
- **Diagnostics on b0a0** (40 seeds, scratch tool):
  - **Rukia causes 19 of 34 losses** (seat 2: 29 / 40). Her J strings hurt him in East (RU-J1 openers after his K1 /
    TENCHI) and so does TSUKISHIRO's FREEZE.
  - **Damage ratio by form:** Shikai 1.22, East 2.3.
  - **Signature:** J / K links still make up about 44 % of his damage. East's J1 follow-up string on a stunned
    opponent at close range is a large part of it.

## The action policy (per form)
Everything from b0a0 is unchanged: the anti-Breaker J1, the SP / O confirms, `:o-ender 0` in the Shikai and Hellfire,
ranges, bands, and the awaken / Bankai rules. One change is added.

- **Bankai East: the fire, not the J string, on a close stun (`yama-stun-sp`).**
  - In b0a0, the stun SP fired only beyond J1's follow-up reach. In East it now also fires up close when he holds
    at least 2 bars. That leaves 1 bar for the KYOKUJITSUJIN confirm off J3 / K3, which hit about 97 %.
  - The condition is the same as before: the blade and sheet land before the stun ends, with 8 f to spare.
  - The Shikai and Hellfire keep b0a0's rule (SP2 beyond J1 reach, within 3.8 m).
  - Chance: HARD 0.7, NORMAL 0, EASY 0 (the same plist as b0a0). NORMAL is untouched, which is why the pacing medians
    are identical.
  - Effect: signature 0.562 -> 0.585, with strength unchanged within noise.

## Tried and dropped (all measured)
| variant (on b0a0) | 20 seeds | 40 seeds |
|---|---|---|
| b0a0 itself | 0.8637 (0.919 / 0.562) | 0.8488 (0.894 / 0.563) |
| + b1a0 Breaker Hoho fallback + guard clock | 0.8362 (0.875 / 0.556) | - |
| + Breaker Hoho fallback only | 0.8601 (0.912 / 0.563) | - |
| + close East stun SP, 2 bars (**final**) | 0.8608 (0.906 / 0.585) | 0.8474 (0.884 / 0.584) |
| final + Kikon punish (below) | 0.8612 (0.906 / 0.587) | 0.8443 (0.878 / 0.587) |
| close East stun SP, 3 bars + Kikon punish | - | 0.8458 (0.884 / 0.576) |

**The Kikon punish:** TENCHI (or ENJO) on a red opponent in his own recovery, when the strike lands before he is
free.

- Its motivation: the neutral TENCHI from up to 9 m is J1-countered by Rukia 16 of 58 times.
- In practice it fired only about 5 times per 20 matches. The generic neutral rush (0.5 per decision) takes the red
  opponent first.
- It added nothing measurable, so it was dropped.

## Why it is not a repeat
- It is the first measured combination of b0a0 and b1a0, and that combination's negative result is recorded above.
- The kept change is the first to move J-link damage into fire inside a combo, without spending the J3 / K3 confirm's
  bar. b0a0's middle-band swap did it at neutral and lost strength.

## Difficulty layering
- The only changed chance is the stun SP, at EASY 0 / NORMAL 0 / HARD 0.7 (b0a0's plist).
- Everything comes from the perceived SNAP, his own gauges, and the per-event reaction roll (SIM-RND01).

## Risks
- The close stun SP spends a bar the J follow-up string would not. In long East phases the KYOKUJITSUJIN confirm can
  find only 1 bar. The 3-bar variant measured no better.
- Strength at 20 seeds is 0.013 below b0a0, within noise (40 seeds: -0.010).

## Shared-code recommendations (not done)
1. **A neutral-rush hook.** The generic neutral Kikon (`ai-decide`, `*ai-kikon-p*` 0.5 within `:kikon-range`) fires
   from long range into J1 counters. A kit hook to veto or delay it would let a character start the rush closer, or
   only into recovery. With the reflex hook alone, a character can add rushes but cannot remove these.
2. **A dash command for reflexes.** There is no `:dash` reflex command, so a kit reflex can't close distance before
   a rush.
3. b1a0's recommendations still stand: the West ward's guard clock, and a generic strike-time Breaker model.
