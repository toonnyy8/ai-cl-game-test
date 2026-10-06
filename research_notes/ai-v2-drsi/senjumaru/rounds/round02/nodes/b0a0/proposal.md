# Cell b0a0 (round 2): the loom's endgame, and what the move outcomes say

This cell starts from round 1's best file, b0a2 (0.7857 at 20 seeds). Every change is in the AI section of
`duel/lisp/senjumaru.lisp`. No move, frame, damage, cost or form rule changed, and no other file was edited.

Variants were judged at 40 seeds with a per-opponent breakdown of the same str and mash jobs that aieval runs (the
noise is about ±0.03). The final line comes from `tools/aieval.py --char 4 -j 4` at 20 seeds.

## History read

- **The baseline** scored 0.5714.
- **Round 1:**
  - b0a0, off-string damage: 0.678.
  - b1a0, set-play: 0.594.
  - b0a1, the two stacked: 0.717.
  - b0a2, the late awakening at a Reishi share <= 0.28: 0.7857.
  - b1a1 left no files.
- **What round 1 agreed on:** the loom is her weak phase. Closer loom bands and fewer SP1 pairs both measured worse, and
  b0a2 sidestepped the loom instead of fixing it.
- **b0a2's parent re-measured at 40 seeds:** 0.7685 (str 0.759, mash 0.875, sig 0.690).
  - Rukia: 45/80 str, 20/32 masher.
  - Yamamoto: 57/80.

## Diagnosis (new tools: per-phase and per-choice accounting from the sim logs)

- **The awakening threshold is the red line.** `*red-threshold*` is 0.30, so b0a2's 0.28 makes her awaken just inside
  red. The +20 % heal takes her out of red, where his Kikon's follow-up can't be guarded.
  - She spends about 45 % of the match vs Rukia in the loom.
  - Damage dealt to taken: the Shikai 1.12, the loom 0.84. Vs Yamamoto: the Shikai 1.11, the loom 0.68.
- **Where the Konpaku go vs Rukia (30 seeds).** In the loom she lost 133 Konpaku (112 to Kikons, 21 to Soul Breaks)
  and took 111.
  - Rukia's Kikons are almost never neutral rushes. They come off a string: J1 punish → K2S → A-K3 (push) → the HAKKA O
    ender → Kikon (-3).
  - So guarding a red rush does nothing. The "red guard" variant measured 0.754, and it had nothing to guard.
- **Each of her choices, scored by damage dealt minus taken in the next 90 f** (her as P1, 20 seeds per opponent).
  - **Shikai neutral J1:** +84 to +114 per use vs all four.
  - **Shikai neutral K1:** -8 to -36 vs all four.
  - **Shikai neutral O:** -7 to -19 vs all four.
  - **The loom's generic anti-Breaker J1 vs Rukia:** **-104 per use** (27 uses, 3340 taken). The same problem round 1
    found in the Shikai, but there the O answer covers it and the loom's lane only answers from 3 m out.
  - **The loom's neutral lane Kikon on a red foe:** +69 to +79 per use vs every opponent.
  - **The loom's T-K1 and hank casts in neutral:** negative.
  - **TACHINAOSHI pairs:** mixed (-15 to +31).
  - The generic O ender already fires every time on a red foe, so a loom "red ender" was a no-op. It measured identical to
    the parent and was dropped.

## The policy delivered (per form)

**Shikai (`:base`)**

- Round 1's policy, with the neutral bands (`*senju-neutral*`, HARD 70 % of decisions) re-weighted toward J1.
  - **0–1.7 m:** J1 6, SAIDAN 2. It was J1 4, SAIDAN 3, K1 1.
  - **1.7–2.6 m:** SAIDAN 2, K1 1, wait 2. It was SAIDAN 2, K1 2, O 1.
  - **2.6–7.5 m:** O 1, soldier 1, wait 3. It was O 2, soldier 1, wait 2.
- NORMAL is unchanged, because `:neutral-p` is 0 at NORMAL.

**The loom (`:tsuji1`–`:tsuji6`), the endgame after the late awakening.** Two additions:

- **Anti-Breaker** (`:loom-anti-breaker-p`: EASY 0 / NORMAL 0.1 / HARD 0.85). His Breaker is seen in its dash within
  6 m. She Hohos through it when Hoho is allowed, else she steps aside. This replaces the generic J1 trade her short
  needle loses.
- **Red rush** (`:red-rush-p`: EASY 0 / NORMAL 0 / HARD 0.8). A neutral decision is due, he is red, and he is within the
  lane's 8.5 m. She takes the lane's Kikon (3 Konpaku), unless hits would finish him (the Soul Break rule). The generic
  per-decision roll of 0.5 stays underneath it.

The awakening stays at b0a2's HARD 0.28.

## Measurements (40 seeds, the diag; the score uses aieval's weights)

| version | score | str | mash | sig | Rukia str /80 | Rukia masher /32 | Yamamoto /80 |
|---|---|---|---|---|---|---|---|
| parent b0a2 | 0.7685 | 0.759 | 0.875 | 0.690 | 45 | 20 | 57 |
| A: red hunt (O over K1 on a red recovery) | 0.7607 | 0.744 | 0.881 | 0.691 | 41 | 20 | 57 |
| B: loom close bands, SAIDAN-heavy | 0.7628 | 0.744 | 0.894 | 0.689 | 43 | 20 | 55 |
| C: red guard vs his rush | 0.7541 | 0.734 | 0.875 | 0.692 | 42 | 20 | 52 |
| D: red caution (no SAIDAN, DEFEND when red) | 0.7555 | 0.734 | 0.887 | 0.687 | 40 | 22 | 54 |
| E: Shikai J1-first bands | 0.7856 | 0.806 | 0.831 | 0.678 | 49 | 14 | 59 |
| E + round-1 bands vs a masher | 0.7558 | 0.772 | 0.787 | 0.676 | 48 | 9 | 52 |
| F: E + loom anti-Breaker Hoho | 0.7985 | 0.828 | 0.831 | 0.677 | 51 | 14 | 62 |
| F + loom patient neutral (wait inside 5 m) | 0.7869 | 0.822 | 0.787 | 0.681 | 52 | 14 | 56 |
| F, never awaken | 0.7611 | 0.784 | 0.769 | 0.684 | 50 | 9 | 51 |
| F, no neutral K1 / O | 0.7934 | 0.841 | 0.762 | 0.683 | 50 | 9 | 65 |
| **G: F + loom red rush (delivered)** | **0.8005** | **0.831** | **0.831** | 0.678 | **54** | 13 | 61 |
| G, no mid-range K1 | 0.7891 | 0.828 | 0.781 | 0.680 | 60 | 8 | 66 |

**The final 20-seed aieval line** (score.json):
`{"char": "SENJUMARU", "score": 0.8096, "strength": 0.856, "masher": 0.8, "signature": 0.679, "pacing_ok": true, ...}`.
That is +0.024 over b0a2's 0.7857 at the same 20 seeds.

**Pacing.** Every NORMAL match was a K.O. The medians were 155 / 154.5 / 197.9 (Rukia) / 195.8 (Ichigo) s.

**Rules test.** 4433 checks, ALL PASS.

What each part did, against the 40-seed parent:

- **Strength:** +0.072, about +23 wins of 320. Most of it came from E (the J1-first Shikai bands) and F (the loom's
  anti-Breaker Hoho).
- **Rukia:** +9 / 80.
- **Masher:** -0.044. The Rukia masher went from 20 to 13–14 of 32.
- **Signature:** -0.012, because fewer neutral K1 / O hits mean more of her damage comes from J.

## Why it is not a repeat

- No round-1 cell measured each choice's outcome.
- No round-1 cell touched the loom's anti-Breaker answer.
- No round-1 cell touched the loom's Kikon rate on a red foe.
- No round-1 cell tied the awakening to the red line.
- Round 1 *removed* J1 from her neutral, on the theory that her short needle loses J trades. The per-use outcomes say
  the opposite: the neutral J1 nets about +100 per use, and its K1 and O lose.

## Risks

- **The masher dropped.** The Rukia masher fell in every variant that leaned on J1, 9–14 of 32 vs 20.
  - Returning to round 1's bands when `ai-mash-p` reads him as a masher did not fix it: 9 of 32.
  - With 32 masher matches per character the noise is about ±3, so how big the cause is stays unclear.
- **The tuning is close to noise.** G vs F (+0.002) is within noise. The anti-Breaker Hoho (+0.013) is about 1 sigma.
  The Shikai bands (+0.017 score, +0.047 strength) are the solid part.
- **The 90-frame outcome window is a heuristic.** A choice's score includes what happened after it for any reason. Use
  it to rank choices, not to measure exact values.
- **Pacing.** The Rukia and Ichigo NORMAL medians rose from 186 / 183 to 198 / 196 s, still under 220. The real gate's
  210 s at 60 seeds is closer.
  - What NORMAL changes is limited: the anti-Breaker roll at 0.1, plus whatever HARD Senjumaru does not affect.
  - The rise is probably noise, but check it at the gate.

## Shared-code recommendations (not done)

1. **The generic anti-Breaker** (ai.lisp, AI-REFLEX). It answers a Breaker dash with J1 whenever the dash enters
   J1's reach plus `*ai-anti-breaker-j*`.
   - For short-needle kits through the perception delay, this loses the trade. Measured: Senjumaru vs Rukia -104 per
     use.
   - Suggested fix: a kit key for the answer (`:anti-breaker :hoho`), or prefer Hoho when J1's reach is under about
     1.5 m.
2. **A kit hook for the awakening as a combo breaker** (`:awaken-p`, as b0a2 recommended). A red Senjumaru caught in a
   string that ends in his O ender's Kikon is exactly when the late awakening should break it. Today she can't do that,
   because her `:reflex` runs only in free states.
3. **More masher seeds** for the masher term. Its swing per character (±3 of 32) is larger than most policy effects.

Scratch tools for this cell are in the worktree under `scratchpad/senjumaru-r2b0a0/`:

- `diag.py`: the per-opponent str and mash breakdown.
- `phase.py`: Shikai vs loom damage and Konpaku.
- `outcome.py`: per-choice damage dealt minus taken over the next 90 f.
