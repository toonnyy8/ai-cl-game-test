# Cell b0a0 (round 1, new direction): Rukia, "meet the grab, cash the ender"

Measured (final file, `python3 tools/aieval.py --char 2 -j 4`, 20 seeds):

| | baseline | b0a0 |
|---|---|---|
| score | 0.7645 | **0.8603** |
| strength (HARD, 160 matches) | 0.831 (133) | **0.963** (154) |
| masher (as aieval counts it) | 0.887 | 0.825 (see "Evaluator quirk": the real share went **up**, 65 -> 70 of 80) |
| signature | 0.441 | **0.589** |
| pacing (NORMAL medians Y / K / I / S) | ok | ok: 146.7 / 145.7 / 177.3 / 168.4 s, every match a K.O. |

`tests/duel-rules-test.lisp`: 4433 checks, ALL PASS. Only `duel/lisp/rukia.lisp` is changed. All changes are in her forms'
`:ai` plists (new `:sp-ender` / `:reflex` hooks) and new CPU functions plus their per-difficulty parameters, which live in
that file. No frame data, damage, costs or rules are touched.

## History used
This is the first cell; no earlier cells exist. From the baseline's per-move breakdown (my scratch analysis over the
strength runs):
- What she lost to most was the opponents' Breakers: 55 k of the damage she took (Y 12.0 k, K 9.6 k, I 18.9 k,
  S 17.0 k), more than any other single source. The log shows why. The generic anti-Breaker J1 waits until the dash, as
  perceived 8 f late, is within J1 reach + 1.4 m. By then the strike is already coming, so her J1 at f654 lost to a
  strike at f659 (`[654] P1 move RU-J1 ANTI-BREAKER / [659] P2 YA-BREAKER -> P1 HIT 150`).
- Signature was 0.441. Her enders almost never led into her own tools: K3 (crumple) -> L happened at only
  `*ai-ru-l-after-k*` 0.05 per K hit, and J3 -> SP2 only through the generic 0.3 SP cancel.

## The action policy (per form)
**Shikai (base): a placer that meets every commitment.**
- *Range and neutral*: unchanged from the shipped tables (J up close, K / SHIRAFUNE / TSUKISHIRO at mid range, HAKUREN far).
- *Anti-grab (new, `RUKIA-AI-ANTI-BREAKER`)*: timed J beats I. From the perceived snap she works out how many dash frames
  he has run by now (`*match-tick*` - snap-start, minus the 12 f aura), where he is now (about 0.16 m a frame), and when
  his strike starts (`*breaker-trigger*`, then `*breaker-startup*`). She then presses the first of J1, SHIRAFUNE (bars
  permitting) or K1 whose active frames come before the strike and reach his position at that moment. K1 / SHIRAFUNE
  answer Breakers started from 2-5 m, which J1 cannot.
- *Guard break (new)*: when she sees him guard for >= 10 f within 3 m, she uses HAINAWA (the generic CPU waits 24 f at
  p 0.4).
- *Whiff punish (new)*: a recovering opponent beyond J1 reach + 0.4 m but inside SHIRAFUNE's line - 0.4 m, whose recovery
  still outlasts SP2's startup after the perception delay, gets SHIRAFUNE.
- *Ender confirms (new `:sp-ender`, `RUKIA-AI-SP-ENDER`)*: after a K3 hit, she chains the band's L through the K -> L
  latch: TSUKISHIRO-K in the Shikai, SHIMOBASHIRA at -18, HYOSHIN at -50, REIDO at zero. It is a combo off the crumple,
  and in the bands it may overdraw cold. After a J3 hit she uses SHIRAFUNE, which chases the pushed victim (bars and the
  kit's reserve permitting, never at zero). If neither applies, the O ender, which always dashes after the push. All of
  this runs after the generic O-ender roll, so a red opponent still gets the Kikon.

**-18 / -50**: the same reflex and ender policy with each band's own moves (TOSHU K1, HYOSHIN, SHIRAFUNE-50 ...). At -50
the reflex also keeps the shipped Hoho-in to absolute zero (`RUKIA-AI-HOHO-IN`). Cooling, bracing and awakening are
unchanged.

**Zero (rooted)**: K3 -> REIDO through the ender hook (no SP2 off J3: it would cash the top bar for less). Everything else
is shipped.

**Difficulty layering**: every new chance is a `(:easy :normal :hard)` plist read at the CPU's difficulty:

| parameter | EASY | NORMAL | HARD |
|---|---|---|---|
| `*ai-ru-k-ender-l*` | 0.05 | 0.15 | 0.9 |
| `*ai-ru-j-ender-sp2*` | 0.1 | 0.3 | 0.85 |
| `*ai-ru-ender-o*` | 0 | 0.1 | 0.6 |
| `*ai-ru-whiff-sp2*` | 0 | 0.1 | 0.7 |
| `*ai-ru-anti-breaker*` | 0.2 | 0.4 | 0.9 |
| `*ai-ru-guard-break*` | 0.1 | 0.4 | 0.75 |

NORMAL stays close to the shipped CPU. The generic anti-Breaker (0.55 at NORMAL) still covers the rolls hers leaves.
Determinism: every roll is `SIM-RND01` or the per-event `brain-react-roll`.

## What each step measured (strength runs, 20 seeds, Y / K / I / S wins of 40)
| step | Y | K | I | S | strength | sig |
|---|---|---|---|---|---|---|
| baseline | 29 | 36 | 35 | 33 | 0.831 | 0.441 |
| + ender confirms + whiff SP2 | 26 | 38 | 32 | 36 | 0.825 | 0.504 |
| + timed anti-Breaker (J1 first) | 39 | 39 | 40 | 40 | 0.988 | 0.447 |
| + O fallback, guard break, anti-Breaker SP2 first | 38 | 38 | 37 | 38 | 0.944 | 0.605 |
| same, anti-Breaker J1 first (**final**) | 40 | 40 | 37 | 37 | 0.963 | 0.589 |
| + "place TSUKISHIRO at 4-8 m on the neutral decision" (dropped) | 37 | 37 | 36 | 35 | 0.906 | 0.576 |

- In the final file, damage she takes from Breakers fell from 55 k to almost nothing.
- Her own Breaker is now 27 % of what she deals. That is her kidō HAINAWA, so it counts toward signature.
- SHIRAFUNE + FREEZE (TSUKISHIRO / discs) + Kikon + HAKKA rose from about 21 % to about 25 % of her damage.

## Evaluator quirk (recommendation, not touched)
`aieval.py`'s masher job `(m, c, 6, ...)` with m == c (the Rukia masher vs the Rukia CPU) gets `side = 0`, because
`c1 == c`. So it counts the masher's P1 wins as hers. Real results, from my scratch tally of the same runs:
- Baseline: wins 65 / 80, of which 5 / 16 in the mirror. aieval reported 71.
- This cell: wins 70 / 80, of which 10 / 16 in the mirror. aieval reported 66.

The CPU improved against the masher, but the score shows a drop. Fix: key the seat on the habit (the masher is always P1
in the mash jobs), e.g. `side = 1 if kind == 'mash' else ...`. The same bug hits every character's own mirror masher row.

## Risks
- **Breaker share.** Her damage now leans on her own Breaker. The other CPUs' generic anti-Breaker J1 is late, which is the
  same flaw she had. If that shared answer is fixed (below), her strength and signature both drop somewhat.
- **Mind-reading.** The anti-Breaker timing uses only the perceived snap (`snap-start`, `snap-phase`, the perceived
  distance) and the clock. It doesn't read inputs. The dash-speed constant 0.16 m/f is the universal Breaker's.
- **Noise.** Single-variant 20-seed noise is about +-3 wins of 160. The final ordering (J1 first) beat SP2-first by 3
  wins, which is within noise.

## Shared-code recommendations
1. The generic anti-Breaker in `ai-reflex` should use the same timing (dash frames since `snap-start`, the strike's
   start, the first move that gets there). It loses to Breakers at the HARD delay for every character.
2. The aieval mirror-masher seat bug above.
3. Make `:string-k` / `:o-ender` / `:l-after-k` accept a per-difficulty plist. Today only a hook function can scale them,
   which is why this cell routes the ender choices through `:sp-ender`.
