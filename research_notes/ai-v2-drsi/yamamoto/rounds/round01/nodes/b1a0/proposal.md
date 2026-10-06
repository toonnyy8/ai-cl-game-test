# b1a0 (round 1, new direction): Yamamoto dodges the Breaker with a timed Hoho and keeps his own guard clock short

**Final score** (tools/aieval.py --char 0, 20 seeds): **0.7466**.

| part | b1a0 | baseline (rescored) | b0a0 (rescored) |
|---|---|---|---|
| strength | 0.731 | 0.531 | 0.919 |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.539 | 0.580 | 0.562 |
| score | **0.7466** | 0.6348 | 0.8637 |

- Pacing passes. NORMAL medians are 155-181 s, and every match ended in a K.O.

## History used
b0a0 is the only earlier cell. It found that the other CPUs' Breakers are their main damage against him. It answered
them with a delay-aware J1 counter-hit, added SP / O confirms off J3 / K3, and added a stun SP.

To pick a different mechanism, I measured the baseline per form with HARD logs: 80 matches, both seats, my
scratch tool `diag2.py`.

- **Damage ratio by form:** Shikai 0.58, Hellfire 1.7, Bankai East 1.64, **Bankai West 0.56**.
- **Where the opponents' Breaker decisions came from:**
  - 376 were their GUARD-BREAK reflex against **West's ward**. They see the ward as a guard held forever:
    `fighter-guard-t` never stops in West, and `snap-take!` reports the ward as :guard.
  - 137 were the GUARD-BREAK reflex against the Shikai's neutral guard.
  - About 130 were neutral Breakers.
- So in West the ward draws Breakers and loses the exchange. The Breaker is still the lever, but I answer it with
  evasion and with his own guard time, not with J1.

## The action policy (per form)
- **Every form: YAMA-BREAKER-HOHO, the perfect Hoho through the Breaker.**
  - From the perceived snap he estimates the real frames until the Breaker's strike lands: the aura left, then the
    dash to `*breaker-trigger*` minus what it ran unseen through his perception delay (0.16 m/f), then
    `*breaker-startup*`.
  - When the strike is due within 11 f (HARD; `*perfect-lead*` is 12), he Hohos, provided `hoho-allowed-p` and
    `ai-hoho-spare-p` hold.
  - The Hoho's i-frames (1-14) take the strike. It is a perfect Hoho, so the counter swing comes out and he lands
    behind a whiffing Breaker.
  - It works out of the aura too, which covers a Guard-Break Breaker started up close.
  - Chance: HARD 0.9, NORMAL 0.3 (lead 6 f), EASY 0.
  - In West, the GUARD-BREAK Breakers still come (764 decisions in 160 matches). Now he Hohos most of them: West
    COUNTER hits went from about 60 to 361.
- **The Shikai / Hellfire: YAMA-GUARD-CLOCK.**
  - Conditions: a plain guard held at least 14 f (his own clock, felt at once), the opponent within 3.4 m, and
    nothing of his coming (YAMA-THREAT-P).
  - Then he drops the guard: J1 when it reaches, else the back hop.
  - The opponent therefore never sees 24 f of guard (`*ai-guard-break-hold*`) within 3 m. Shikai GUARD-BREAK
    Breakers fell from 137 to about 21 (per 80 matches).
  - Chance: HARD 0.9 at 14 f, NORMAL 0.3 at 30 f, EASY never.
- **Unchanged:** all :ai plists apart from the added `:reflex yama-ai-reflex`. That covers ranges, bands, guard /
  Hoho chances, awaken / Bankai, West's parry react and ward reversal, and the confirms. No move data was touched.

## Measured (my diag, 160 HARD matches, wins out of 40 per opponent)
| variant | Ichigo | Kenpachi | Rukia | Senjumaru | aieval |
|---|---|---|---|---|---|
| baseline (10-seed diag x2) | 26 | 34 | 12 | 26 | 0.6348 |
| clock in every form; West exits J1 / SHONETSU (v2) | 22 | 34 | 10 | 21 | 0.633 |
| v2 + Hoho, dash seen within 3.5 m (v6) | 28 | 32 | 18 | 34 | 0.7311 |
| v2 + timed Hoho (v7) | 32 | 35 | 17 | 30 | 0.7378 |
| **timed Hoho + Shikai / Hellfire clock only (final)** | 28 | 33 | 24 | 32 | **0.7466** |

- Final per form: East's ratio is 1.64 -> 2.13. The Shikai's is 0.58 -> 0.78 (Breakers are out of its top
  losses; FREEZE, KE-STANCE, counter-Hohos against his slow K1 / L and K3 strings remain). West stays at 0.70.

**Tried and dropped (all measured):**
- **West exit by East K1:** 931 presses, 361 blocked and punished. 35/80 wins.
- **West exit by his own Breaker:** 1658 presses, mostly J1-countered. 34/160 wins.
- **SHONETSU as a reactive trap against a seen Breaker:** a Breaker guard-breaks West even during SHONETSU, and the
  pillars come too late. 77/160 wins.
- **West dash-in, then J1:** 81/160 wins.
- **East guarding less (:guard 0.15, :neutral-guard 0.1), so less West:** 76/160 wins.
- **West clock with SHONETSU only:** signature 0.602, but strength 0.594, score 0.6767. After SHONETSU his ward
  clock is still high, the opponent gets a fresh Guard-Break roll, and the Hoho is then on lockout.
- With the timed Hoho in place, **West's J1 / SHONETSU clock exits cost more than they saved** (0.7378 -> 0.7466
  without them).

Noise: SD is about 0.035 strength at 160 matches. v6, v7 and the final are within noise of each other. The jump from
baseline / v2 to the Hoho versions (+0.17-0.20 strength) is not noise.

## Why it is not a repeat
- b0a0 answers the Breaker with a J1 counter-hit (J beats I), plus SP / O confirms. This cell uses neither of them,
  and leaves :sp-ender and :o-ender untouched.
- It dodges the strike instead: the perfect Hoho, a different tool with its own counter. It also takes away the
  opponent's reason to Breaker the Shikai's guard (the guard clock).
- The two answers are complementary. A later cell could combine them:
  - J1 when it has the frames, Hoho when the flash-step allows.
  - The guard clock on top.
  - b0a0's confirms, which this cell lacks.

## Difficulty layering
| chance | EASY | NORMAL | HARD |
|---|---|---|---|
| Breaker Hoho | 0 | 0.3 (strike <= 6 f) | 0.9 (strike <= 11 f) |
| guard clock | never | 0.3 at 30 f | 0.9 at 14 f |

- Everything comes from the perceived SNAP, his own state (guard time, flash-step, Hoho lockout) and the reaction
  roll, which is SIM-RND01.
- Nothing reads inputs.

## Risks
- The strike-time model hard-codes the dash speed (`*yama-breaker-step*` 0.16 m/f). It reads `*breaker-aura*`,
  `*breaker-trigger*` and `*breaker-startup*` live.
- The Hoho spends flash-step (30, refund 15 on a perfect). `ai-hoho-spare-p` keeps a Burst's reserve when low.
- Signature fell 0.58 -> 0.54. The J1s from the guard clock and the Hoho counter / follow-up strings add J-link and
  COUNTER damage.
- West is still a net loser (0.70) and still gets Guard-Broken when the Hoho isn't available.

## Shared-code recommendations (not done)
1. **The other CPUs' guard-break reflex treats West's ward as a guard held forever** (snap-take! :guard plus a
   never-reset `fighter-guard-t`), so West is Breakered on sight. Two options:
   - Reset the ward's clock when West blocks or acts.
   - Or have AI-REFLEX's guard-break use the time since his last action.
2. A **generic "perfect Hoho the Breaker" answer** in ai.lisp (the strike-time model) would serve every short-J
   character. Today the generic Hoho needs the dash seen and the 0.35 Hoho roll.
