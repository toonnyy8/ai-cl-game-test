# Cell b0a0 (round 2, from round 1's best b0a2): Rukia, "the cold answers: REIDO at zero, the disc in the bands"

Final file, official `python3 tools/aieval.py --char 2 -j 4` (20 seeds, aieval at 9df6ecc):
`{"score": 0.9533, "strength": 0.981, "masher": 0.988, "signature": 0.835, pacing ok: Y 147.8 / K 148.8 / I 182.2 / S 199.9 s}`.
`tests/duel-rules-test.lisp`: 4433 checks, ALL PASS. I changed only `duel/lisp/rukia.lisp`, and only CPU code: zero's `:ai`
gets `:reflex rukia-ai-reflex`, there are two new functions plus their parameters, and seven NORMAL values are lowered.
No frame data, damage, cost or rule changed.

The aim (coordinator): she already wins about 99 % at HARD. So the goal was more character colour in her awakened forms
without losing wins, and a NORMAL CPU closer to the shipped one.

## Evidence from round 1 (my form-aware breakdown, `scratchpad/rukia-r2b0a0/brk2.py`, b0a2's file, HARD, 20 seeds)
- She awakens in every match (EVOLUTION 160 / 160). Her damage by form: Shikai 227 k (sig 0.774), -18 70 k (0.820),
  -50 144 k (0.871), **zero 23 k (sig 0.326)**. She enters absolute zero 212 times and suffers 67 CRACKs.
- No form had a `:reflex` at zero, and the generic code at zero only presses J / K. Log: the ward's freeze-touch froze
  Kenpachi at f4903. Her first press came 17 f later, a J1 FOLLOW-UP string. She met a Breaker on the ward with J1 or
  not at all, and that is where the CRACKs came from. REIDO (the signature disc, 120, 45 f freeze) was almost never used.
- NORMAL drift: the shipped file wins 89 / 160 at NORMAL vs the NORMAL CPUs (sig 0.416). b0a2's file wins 120 / 160
  (sig 0.463). So round 1 made NORMAL much stronger.

## The action policy (what changed; everything else is b0a2)
**Absolute zero (`RUKIA-AI-ZERO`, first in her reflex at :zero): REIDO is her answer.**
- *Ward reversal.* Her own ward blocked a hit within REIDO's radius - 0.5 in the last 24 ticks. She feels her own
  state at once, with no perception delay. The window covers the block and freeze hitstops; the brain only regains
  control about 20 f later. She then presses REIDO, the disc hits a still-frozen attacker, and the -50 cash
  (HYOSHIN / SHIRAFUNE-50) often follows. One roll per action of his. `*ai-ru-z-ward-reido*` EASY 0 / NORMAL 0.05 /
  HARD 0.9.
- *Anti-Breaker.* A Breaker in its aura inside radius - 0.5, or a dash that will be inside it at REIDO's f10 (the
  perceived distance minus the dash over delay + S), gets REIDO. This is the counter-hit the design names
  (DUEL_RUKIA 4.4), instead of J1. `*ai-ru-z-anti-breaker*` 0 / 0.1 / 0.9.
- Zero also gets the existing stun cash (`RUKIA-AI-CASH`: SHIRAFUNE-0 / REIDO / HAKKA-0). The timed Hoho is skipped
  because she is rooted.
- REIDO spends the top bar, so she drops to -50. A CRACK would have emptied the whole gauge, and CRACKs fell 67 -> 17
  per 160 matches.

**-18 / -50 (`RUKIA-AI-BAND-DISC`): the cold disc as the close opener.** At a neutral decision, if he is inside the band's
L radius - 0.6 (SHIMOBASHIRA 1.9 m, HYOSHIN 2.9 m), idle / running or recovering (not guarding, not attacking), and cold
permits, she uses the disc instead of the table's J / K pick. HYOSHIN's crumple then feeds the existing ice cash.
`*ai-ru-band-disc*` 0 / 0 / 0.5. She re-times the next decision the way RUKIA-AI-ZONE does.

**Shikai**: unchanged from b0a2 (perfect Hoho, ice / O cash, ender confirms, HAKUREN zoning).

**NORMAL brought back toward the shipped CPU** (HARD unchanged):

| parameter | EASY / NORMAL / HARD (was) | now |
|---|---|---|
| `*ai-ru-k-ender-l*` | 0.05 / 0.15 / 0.9 | 0 / **0.05** / 0.9 (= shipped `*ai-ru-l-after-k*`) |
| `*ai-ru-ender-o*` | 0 / 0.1 / 0.9 | 0 / **0.05** / 0.9 |
| `*ai-ru-ph-breaker*` | 0 / 0.2 / 0.95 | 0 / **0.1** / 0.95 |
| `*ai-ru-ph-move*`, `*ai-ru-ph-mash*` | 0 / 0.1 / 0.8 | 0 / **0.05** / 0.8 |
| `*ai-ru-ph-cash*` | 0 / 0.2 / 0.9 | 0 / **0.1** / 0.9 |
| `*ai-ru-cash-o*` | 0 / 0.1 / 0.9 | 0 / **0.05** / 0.9 |

## Measured (HARD runs: 40 seeds = 320 strength / 160 masher matches; breakdowns 20 seeds)
| variant | score | str | mash | sig | zero sig | -50 sig | -18 sig | CRACK / ZERO |
|---|---|---|---|---|---|---|---|---|
| v0 = b0a2 (40 seeds) | 0.9468 | 315 | 159 | 0.787 | 0.326 | 0.871 | 0.820 | 67 / 212 |
| v1 + zero anti-Breaker REIDO + cash | 0.9523 | 315 | 160 | 0.808 | 0.784 | 0.869 | 0.824 | 17 / 199 |
| v2 + ward REIDO (24-tick window) | 0.9524 | 315 | 160 | 0.809 | 0.822 | 0.871 | 0.825 | 17 / 203 |
| **v3 + band disc HARD 0.5 + NORMAL cut (final)** | **0.9540** | **315** | 159 | **0.823** | 0.876 | **0.920** | **0.847** | 10 / 119 |
| v4 = v3, band disc HARD 0.8 | 0.9540 | 317 | 156 | 0.823 | | | | |
| **final file, official 20 seeds** | **0.9533** | 157 / 160 | 79 / 80 | **0.835** | | | | |

NORMAL (Rukia NORMAL vs the NORMAL CPUs, both seats, 20 seeds, 160 matches):

| | wins | sig |
|---|---|---|
| shipped file | 89 | 0.416 |
| b0a2 | 120 | 0.463 |
| v3 with every new NORMAL chance at 0 (control) | 105 | 0.407 |
| **v3 (final)** | **117** | **0.442** |

Readings:
- Strength holds: 315 / 320 in v0 through v3. The official 20-seed run is 157 vs b0a2's 159, within the ~3-win noise.
- The signature gain is all colour. Zero went from links (0.33) to REIDO (0.82-0.88), and -50 rose 0.87 -> 0.92 with
  HYOSHIN opening its close game. Overall: 0.787 -> 0.823 at 40 seeds, and 0.789 -> 0.835 on the official seeds.
- Band disc 0.8 adds nothing over 0.5 (same sig) and cost 3 masher wins, so I kept 0.5.
- The band disc spends cold, so she reaches zero less often (ZERO 203 -> 119). Zero's damage fell 24 k -> 15 k, but what
  is left of it is signature.
- NORMAL: the 105-win control (all new NORMAL chances at 0) differs from the shipped 89 by about two SD of a 160-match
  difference, so most of that gap reads as RNG-stream noise. The chances themselves now add about 12 wins and some
  colour (sig 0.442 vs 0.416). The pacing medians stay well under 220 s.

## Why it is not a repeat
Round 1 worked on the Shikai and the -50 Hoho / cash. No cell gave zero a reflex or used REIDO / the ward, and none
used the band disc as a neutral opener. Round 1 also never checked NORMAL against the shipped file.

## Risks
- **Ward window (24 ticks).** It is generous: a later hit on the ward inside it also triggers REIDO. That is fine, because
  his move is still committed, but a human could bait it with a blocked J and then guard the disc (guard 20).
- **Zero time is shorter.** The band disc spends the cold that the Hoho dive would have turned into zero. If the user
  wants more absolute-zero screen time, set HARD band-disc lower or add a cold floor before using it.
- **Noise.** About +-3 strength wins per 160; the masher moves 1-4 of 160 between variants with no masher-specific change.

## Shared-code recommendations
1. AI-REFLEX's `:ward-reversal` uses `(<= (- tick warded) 1)`, which never fires for Rukia's zero: the block and freeze
   hitstops keep her brain from running in that tick. A wider window (or "since the last free step") would make the
   generic key work for both West and her.
2. Carried over: a kit `:decide` hook (instead of re-timing `brain-decide-t` from `:reflex`), per-difficulty
   `:l-after-k` / `:o-ender`, and an explicit `:wait`.
