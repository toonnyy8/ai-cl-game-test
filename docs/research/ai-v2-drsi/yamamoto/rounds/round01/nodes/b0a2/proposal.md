# b0a2 (round 1, refines b0a1): the rush on a red opponent only where it lands

**Final score** (tools/aieval.py --char 0, 20 seeds): **0.8989**.

| part | b0a2 | b0a1 (parent) | baseline (rescored) |
|---|---|---|---|
| strength | 0.969 | 0.906 | 0.531 |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.588 | 0.585 | 0.580 |
| score | 0.8989 | 0.8608 | 0.6348 |

- **40 seeds:** b0a2 0.887 (strength 0.950) vs b0a1 0.8474 (0.884). This is a paired comparison on the same seeds:
  strength +0.066, about 5 SD.
- **80 seeds:** b0a2 0.875 (strength 0.931; seeds 41-80 alone 0.912).
- **Pacing:** NORMAL medians are identical to the parent's (142.7-184.8 s), every match a K.O. The change only rolls
  at HARD, and it draws no random number at NORMAL.

## Evidence (my scratch log tool, HARD strength runs, 40 seeds x 8 jobs)
- **Parent:** the generic rush on a red opponent (ai.lisp) is the biggest single leak.
  - Neutral TENCHI: n=982. He was hit before his next move 421 times, landed it 357 times and whiffed 157.
  - "YA-TENCHI KIKON -> opponent J1" opened him 115 times vs Rukia (17.3k damage), 85 vs Ichigo and 115 vs
    Senjumaru.
- **Probe 1 (neutral decision, tagged by perceived distance):**

  | perceived distance | hit | hit by | whiff | note |
  |---|---|---|---|---|
  | 1-2 m | 9 | 20 | 37 | side-Stepped |
  | 2-3 m | 16 | 47 | | |
  | 3-4 m | 33 | 80 | | |
  | 4-5 m | 13 | 21 | | |
  | 6-7 m | 21 | 10 | | the only good band |

  - This matches ai.lisp's answer to a seen rush on a red CPU: within *AI-ANTI-BREAKER-RANGE* 5 m it presses J1
    beyond 1.8 m and side-Steps inside, at HARD 0.7.
  - ENJO inside 1.5 m mostly whiffs, because its lane starts 1 m out.
- **Probe 2 (the rush on his stun):** when the strike lands before he is free (margin >= 0), it almost always hits.
  With a negative margin the result is mixed and depends on the distance.

## The action policy change (on top of b0a1, everything else unchanged)
**`yama-rush-veto`** (a reflex in the `:reflex` chain, after the anti-Breaker J1 and the stun SP) applies to every form.

- **The rule:** the rush on a red opponent goes only where it lands (`yama-rush-ok-p`). That means:
  - TENCHI from beyond 5 m (`*yama-rush-far*`, his answer range), or
  - ENJO from 1.5 m out, or
  - either one on a stun / a move's recovery when it strikes before he is free. The strike time is
    `yama-rush-frames`: the aura, then TENCHI's 36 m/s dash to its reach (at most 14 f), then the startup.
- **What replaces a vetoed rush:**
  - **At a neutral decision** (the tick ai-neutral would decide on): he takes the decision himself. He resets the
    decide clock and makes the band's attack pick (`ai-attack`), so the rush roll never happens.
  - **On his stun:** J1's follow-up if it reaches him in time, else `:wait` (a no-op command), so the generic
    reflex rush below it doesn't fire.
- **Chance:** EASY 0, NORMAL 0, HARD 0.9. At 0 it draws no random number.
- **What stays the same:** the O ender / a string's ender on a red opponent always rushes. That rush hit 534 of 559,
  so it is untouched.
- **Measured (parent -> b0a2, 40 seeds):**
  - Wins: Rukia 59 -> 71 of 80, Senjumaru 74 -> 76, Ichigo 76 -> 79, Kenpachi 74 -> 78.
  - The rush-opened damage vs Rukia: 17.3k -> 4.7k.

## Tried and dropped (40 seeds, on top of the veto)
| variant | score | strength | signature |
|---|---|---|---|
| **veto (final)** | **0.887** | **0.950** | 0.591 |
| + veto the long-guard Breaker (generic GUARD-BREAK, HARD 0.9) | 0.857 | 0.912 | 0.553 |
| + the same, East's KYOKUJITSUJIN blade (:guard-crush) in its place within 2.2 m | 0.868 | 0.928 | 0.561 |
| stun rushes on timing only (no far rule while stunned) + no TENCHI inside 1 m | 0.875 | 0.931 | 0.591 |
| `*yama-rush-far*` 4.0 | 0.877 | 0.931 | 0.591 |
| + East KYOKKO on a stun beyond J1's reach, stun SP from J1's reach (not +0.6) | 0.879 | 0.934 | 0.600 |

- **The long-guard Breaker** is countered a lot (about 310 times hit vs 367 grabs in 1020), but it still pays. The
  grab also takes the guard away.
- **Stun rushes from 5-6 m:** the probe showed 71 hits vs 61 hit-by, and it still pays. One Kikon on a red
  opponent is worth more than the J string he takes for it. Any veto must be lopsided to help, which the 1-5 m
  neutral rush was (about 1 : 2.6).

## Why it is not a repeat
- b0a1 tried a Kikon *punish* that adds rushes. It fired about 5 times in 20 matches, because the generic rush came
  first.
- b0a2 removes the generic rush where it loses. It is the first cell to veto a generic ai.lisp decision from the
  kit's reflex, at the decision tick and through a no-op command.
- The mechanism comes from measured outcome tables per distance, not from weight tweaks.

## Risks
- **The decision-tick takeover** (`brain-decide-t` <= 1 in a free state) repeats ai-neutral's clock reset. If
  ai-neutral's decision cadence changes, this reflex must follow it.
- **`:wait`** is a command keyword that ai-command ignores. If ai-command ever errors on unknown commands, it breaks.
- **`*yama-rush-far*` is ai.lisp's 5 m answer range, written as a constant.** It is not read from
  `*ai-anti-breaker-range*`, so retuning that won't move it. A follow-up could use the variable instead.
- **Noise:** the 20-seed 0.969 strength is on the lucky side (80 seeds: 0.931). The gain vs the parent holds at 40
  seeds, paired.

## Shared-code recommendations (not done)
1. Give ai.lisp's neutral rush (`ai-decide`, and the stun / air reflex rush) a geometry check, or a kit
   `:rush-ok` hook. Every character's rush into a red CPU within 1.8-5 m meets the generic J1 answer. A
   `:kikon-p` by difficulty would also help.
2. Give ai-command an explicit `:wait` (a no-op that blocks the rest of the reflexes), so kits can veto generic
   reflexes cleanly.
3. b0a1's and b0a0's recommendations still stand.
