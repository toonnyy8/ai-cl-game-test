# ICHIGO cell b0a1 (round 1): b0a0's reactive layer + b1a0's red-phase play

This cell refines b0a0 (0.7871 rescored). It stacks b1a0's mechanisms on top and keeps only what measured.
Only `duel/lisp/ichigo.lisp` changed. `tests/duel-rules-test.lisp`: ALL PASS (4433).

Final line, `python3 tools/aieval.py --char 3 -j 4` (20 seeds):
`{"char": "ICHIGO", "score": 0.8158, "strength": 0.831, "masher": 1.0, "signature": 0.585, "pacing_ok": true, ...}`

| | baseline | b0a0 | b1a0 | **b0a1** |
|---|---|---|---|---|
| score, 20 seeds | 0.5065 | 0.7871 | 0.6598 | **0.8158** |
| score / strength, 80 seeds | - | 0.7662 / 0.753 | - | **0.7995 / 0.806** |
| NORMAL pacing Y / K / R / S | 189.2 / 170.8 / 207.9 / 197.3 | 165.1 / 167.8 / 205.2 / 190.6 | baseline's | 165.1 / 167.8 / 205.2 / 190.6 |

NORMAL pacing matches b0a0's to the decimal. Every added rule is HARD-only and is checked before it draws a random
number, so NORMAL and EASY play exactly as in b0a0.

## Action policy

- **All of b0a0 is kept**, in both forms:
  - the timed perfect Hoho;
  - KESSA's parry (HARD 1.0, blockstun 0.8);
  - the long punish;
  - the masher parry and K1 poke;
  - the chasing `:sp-ender` (SOGA / O poke in the Shikai, KUSARI-BIKI in KESSA);
  - ZANZO.
- **New in both forms: our own red phase** (`ichigo-ai-red`, from b1a0). It runs right after the timed Hoho.
  - When his Kikon rush is coming (aura, dash or strike startup, within 11 m), guard it. One roll per his action at
    0.95. Our perception delay of 8 f is longer than the strike's 7 f startup, so the timed Hoho cannot catch that strike.
    Guarding it can.
  - Otherwise, SOUL REVERSE (WHITE), 0.25 a step, while he is not swinging at us.
- **New in both forms: converting a red opponent** (`ichigo-ai-convert`, from b1a0).
  - Rush only when he is busy longer than our rush takes (0.9 per his action), or from 7-8.4 m (0.3 a step).
  - KESSA with 2 or more clones chains him from 3.8-7 m.
  - Closer than 7 m, the neutral decision belongs to the cell: J / K strings, whose O ender always fires on a red man.
- **KESSA's clone bank stays as shipped (banking from 45 %).** b1a0's always-bank and its HARD "O with clones off" both
  measured worse on top of b0a0.

## Evidence

Each 40-seed run below starts from b0a0, which scored 0.7766 / 0.769 at 40 seeds.

| variant | 40 seeds: score / strength | 80 seeds: score / strength |
|---|---|---|
| b0a0 | 0.7766 / 0.769 | 0.7662 / 0.753 |
| + everything from b1a0 (always-bank, red, convert) | 0.7768 / 0.766 | |
| + always-bank only | 0.7495 / 0.731 | |
| + always-bank + red | 0.7441 / 0.716 | |
| + always-bank + convert | 0.7683 / 0.756 | |
| + red + convert, b1a0's bank target, bank-at as shipped | 0.7883 / 0.791 | |
| **+ red + convert, shipped bank (final)** | **0.8079 / 0.819** | **0.7995 / 0.806** |
| + convert only | 0.7777 / 0.772 | |
| + red only | | 0.7900 / 0.791 |
| final, WHITE 0.12 | | 0.7977 / 0.806 |
| final + HARD O-with-clones off | | 0.7879 / 0.791 |
| final, red before the timed Hoho | | 0.7708 / 0.759 |

What the runs show:
- **The always-bank hurts b0a0's KESSA by about 0.04 strength.** Its side-Steps take steps that b0a0 spends on the
  parry, the punish and ZANZO.
- **The red phase is the main gain**, about +0.04 strength at 80 seeds. Convert adds about +0.015 on top.
- **The timed Hoho must stay ahead of the red guard.** Putting the red guard first cost 0.05.
- **The masher score rises from 0.988 to 1.0 without b1a0's keep-out spacing,** so the keep-out was left out.

## Why it is not a repeat

This cell is the untried combination that both round-1 cells proposed. The stacking is selective: the bank change is
the piece that conflicts with b0a0's reactive KESSA, so it was dropped.

## Risks

- **The 20-seed line is on the lucky side.** At 80 seeds the gain is about +0.033 score.
- **NORMAL vs Rukia is still 205.2 s at 20 seeds** (197.9 at 80 seeds), the same as b0a0.
- **Convert takes over `brain-decide-t`** inside 7 m of a red opponent. This is b1a0's risk, carried over.

## Shared-code recommendations

These are unchanged from b1a0:
- A red CPU should guard the Kikon rush's first strike.
- The generic red rush should fire only when he is busy, or from beyond the 5 m answer range.
- `:o-ender` should take a value per difficulty.
