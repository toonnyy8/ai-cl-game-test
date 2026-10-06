# Cell b0a1 (round 1, refines branch 0): Rukia, "vanish, cash the stun, cash the ender"

Final file, measured with `python3 tools/aieval.py --char 2 -j 4` (aieval at 9df6ecc, 20 seeds):

| | baseline | b0a0 (rescored) | b1a0 | **b0a1** |
|---|---|---|---|---|
| score | 0.7495 | 0.8703 | 0.9108 | **0.9337** |
| strength (HARD, 160) | 0.831 | 0.963 | 0.956 | **0.981** (157) |
| masher (80) | 0.887 | 0.875 | 1.000 | **1.000** |
| signature | 0.441 | 0.589 | 0.685 | **0.725** |
| pacing (NORMAL medians Y / K / I / S) | ok | 147 / 146 / 177 / 168 | 140 / 149 / 196 / 192 | ok: 153 / 149 / 196 / 188 s, all K.O. |

`tests/duel-rules-test.lisp`: 4433 checks, ALL PASS. Only `duel/lisp/rukia.lisp` changed, and only in CPU code (`:ai`
plist hook keys plus CPU functions and parameters). No frame data, damage, costs or rules changed.

## What it is
This cell combines the two round-1 cells where they don't overlap. b1a0 had already flagged this as untried.
- **Defence and stun cash: b1a0's `:reflex`, unchanged** (`RUKIA-AI-PERFECT-HOHO`, `RUKIA-AI-CASH`). She uses a Hoho
  timed into his hit window from the perceived snap, so it comes out PERFECT (counter, 36 f stun, inputs locked). She then
  cashes the stun or his recovery with SHIRAFUNE, or with the band's disc L (SHIMOBASHIRA / HYOSHIN). At -50 she does the
  shipped Hoho-in to zero.
- **String enders: b0a0's `:sp-ender`** (`RUKIA-AI-SP-ENDER`, in all four forms, zero included). After a K3 hit she chains
  the band's L through the K -> L latch. After a J3 hit she uses SHIRAFUNE, which chases the pushed victim (bars and the
  kit reserve permitting, not at zero). Otherwise she takes the O ender, which dashes after the push. This turns the end of
  the generic FOLLOW-UP strings into signature damage. Those strings come after a stun too short for SP2, and b1a0 named
  them as the remaining J / K damage (~30 k of 240 k).
- **Changed from b0a0**: the O-ender fallback at HARD goes from 0.6 to 0.9 (EASY 0 / NORMAL 0.1 unchanged).
- **Dropped from b0a0**: the timed anti-Breaker J1/SP2/K1, the HAINAWA guard break and the whiff SP2. The whiff SP2 is
  covered by b1a0's recovery cash. The other two measurably cost strength on top of the Hoho (below).

Per form: in Shikai, -18 and -50 she Hohos through commitments, cashes stuns in ice and confirms enders into her L / SP2 / O.
At zero (rooted, no Hoho) she does K3 -> REIDO through the ender hook and otherwise plays as shipped. Neutral tables,
awakening, cooling and bracing are as shipped.

## Difficulty layering
Every chance is a `(:easy :normal :hard)` plist read at the CPU's difficulty. NORMAL stays near the shipped CPU, and
NORMAL pacing is unchanged by the HARD-only tweak.

| parameter | EASY | NORMAL | HARD |
|---|---|---|---|
| `*ai-ru-ph-breaker*` | 0 | 0.2 | 0.95 |
| `*ai-ru-ph-move*` | 0 | 0.1 | 0.8 |
| `*ai-ru-ph-mash*` | 0 | 0.1 | 0.8 |
| `*ai-ru-ph-cash*` | 0 | 0.2 | 0.9 |
| `*ai-ru-k-ender-l*` | 0.05 | 0.15 | 0.9 |
| `*ai-ru-j-ender-sp2*` | 0.1 | 0.3 | 0.85 |
| `*ai-ru-ender-o*` | 0 | 0.1 | **0.9** |

Randomness comes only from SIM-RND01 / brain-react-roll. She sees only the perceived snap, the clock and her own gauges.

## Steps measured (official 20-seed runs, all with pacing ok)
| variant | score | str | mash | sig |
|---|---|---|---|---|
| v1: b1a0 reflex + b0a0 anti-Breaker fallback + guard break + sp-ender | 0.9035 | 0.919 | 0.988 | 0.774 |
| v2: b1a0 reflex + sp-ender only | 0.9219 | 0.975 | 0.975 | 0.709 |
| v3: v2 + guard break | 0.9025 | 0.912 | 0.988 | 0.788 |
| **v4: v2 + O ender HARD 0.9 (final)** | **0.9337** | **0.981** | **1.000** | **0.725** |

Readings:
- The guard break (HAINAWA, her Breaker) lifts signature by about 0.08. It costs about 10 strength wins of 160, which is
  well beyond the ~3-win noise. A Breaker on a guard he can still drop gets punished. Net loss, so it was dropped.
- The sp-ender alone adds +0.02 signature over b1a0 at no strength cost.
- The O-ender bump (v2 -> v4) is mostly within noise for strength. It is +0.016 signature and the masher went 78 -> 80.

## Risks
- Everything rests on the flash-step economy of the perfect Hoho (see b1a0). Shared changes to `*fs-hoho*`,
  `*fs-refund*` or `*perfect-lead*` move this cell most.
- The v2 -> v4 gain is partly noise (about +-3 wins of 160). The signature rise is consistent across runs.
- The ICHIGO NORMAL median is 196 s (gate 220). NORMAL behaviour is identical to b1a0's except for the sp-ender's small
  NORMAL chances.
- The reflex's `:wait` relies on AI-COMMAND ignoring unknown commands (b1a0's note).

## Shared-code recommendations (carried over)
1. Time the generic Hoho into the hit window (b1a0) and the generic anti-Breaker J1 (b0a0).
2. Add an explicit `:wait` command in AI-COMMAND.
3. Let `:l-after-k` / `:o-ender` take per-difficulty plists.
