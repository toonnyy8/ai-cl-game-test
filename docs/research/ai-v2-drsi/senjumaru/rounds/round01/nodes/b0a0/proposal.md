# Cell b0a0 (round 1): Senjumaru's action policy v2: off-string damage first

This cell opens a new direction (no parent). No earlier cells existed; the only history was the baseline (0.5714:
strength 0.512, masher 0.700, signature 0.619).

All changes are in `duel/lisp/senjumaru.lisp`, in its AI section:

- new `*senju-dp*`, `senju-dp`, `*senju-neutral*`, `senju-o-arrive`, `senju-policy-reflex` and `senju-base-ender`;
- `senju-ai-reflex` calls the policy first;
- `senju-sp-ender` gets an O fallback;
- the base kit's `:ai` gets `:sp-ender senju-base-ender`.

No move, frame, damage, cost or form rule changed. Every new chance goes through `senju-dp`, which reads the brain's
difficulty and keeps EASY <= NORMAL <= HARD. NORMAL adds at most 0.05–0.1 to a few rolls and leaves the neutral override
off. The SAIDAN roll keeps the generic 0.4 at NORMAL.

## What the measurements said first (the baseline, per opponent, HARD, 20 seeds)

| vs | wins (P1 + P2) | | masher of that character | wins |
|---|---|---|---|---|
| Yamamoto | 19/40 | | Yamamoto | 16/16 |
| Kenpachi | 34/40 | | Kenpachi | 16/16 |
| Rukia | **7/40** | | Rukia | **5/16** |
| Ichigo | 22/40 | | Ichigo | 11/16 |
| | | | Senjumaru (mirror) | 8/16 (see the evaluator bug below) |

Damage sources (her side, strength runs): spikes and zones (FREEZE) 20 %, SJ-BREAKER 17 %, J1 11 %. The O was only 5 %:
her O ender fired 0.3 of the time.

In logged SJ vs Rukia matches:

- **The Shikai phase was won on damage** (P1 4314 vs 3012 over 4 matches).
- **The Bankai phase was lost** (4739 vs 7873). Rukia's own awakening, her Breakers and her punishes all landed there.
- **Rukia's Breaker beat Senjumaru's J1 answer every time.** The generic anti-Breaker presses J1 when the dash is about
  q-reach + 1.4 m out. Her J1 is the shortest in the game, so through an 8 f perception delay the press came 6 f before
  the strike landed.

## The policy (行動方針)

Her straight exchange is the weakest in the game: J 25, the shortest needle. So she should rarely trade J's and should
take her damage from her other tools: the O, the unguardable spikes, SAIDAN on the guard every CPU holds, and the hanks.
That damage is also the signature part of the score.

### Shikai (`:base`)

- **Ranges.** The kit's intents and ranges are unchanged.
- **Neutral (new, HARD 70 % of the decisions; `*senju-neutral*`):**
  - 0–1.7 m: J1 4, SAIDAN 3, K1 1.
  - 1.7–2.6 m: SAIDAN 2, K1 2, O 1.
  - 2.6–7.5 m: O 2, SHINPEI 1, wait 2.
  - Beyond 7.5 m: the kit's own bands.
  - This is the AI-NEUTRAL clock taken over in the `:reflex` hook when a decision is due (`brain-decide-t`), with the
    generic interval re-armed.
- **Enders (`senju-base-ender` via the generic `:sp-ender` key).** J3 / K3 hit and push him out.
  - The O ender (it always dashes after the push): HARD 0.85.
  - Else, after K3 with >= 3 stitches, the chasing WARUI KUSE-K: HARD 0.7.
  - Never the O when hits finish him (`ai-sb-finish-p`).
- **Far punish.** He is seen recovering beyond J1 + 0.4 m (HARD 0.8):
  - K1 when its 17 f startup lands in what is left of his recovery after the perception delay;
  - else the O when aura 6 + the 26 m/s dash + S 8 fits (`senju-o-arrive`).
- **Stitches (HARD 0.85).** The spikes are unguardable, so L fires:
  - with >= 3 stitches when he is seen guarding, in blockstun, recovering or reeling with >= 12 f left (the spikes come
    at f10);
  - with >= 2 stitches against a J masher (`ai-mash-p`), who never steps out.
  - The generic `:hari` rule stays below this.
- **SAIDAN on a long guard.** The generic rule (a guard >= 24 f within 3 m, one roll per guard) at 0.7 on HARD (0.4
  generic, kept at NORMAL).
- **Anti-Breaker (HARD 0.85).** His Breaker is seen in its aura or dash within 6 m: her O meets it. Its strike comes
  inside his 0.95 m trigger, so the O hits before it.

### The loom (`:tsuji1`–`:tsuji6`)

- The kit's zoning bands, weave and SP1 pairs are unchanged; the two loom variants tried below both measured worse.
- **Enders.** SP1 TACHINAOSHI first, as before. Its fallback is the O ender (the lane) at the same 0.85.
- **Anti-Breaker.** The lane O (aura 8 + S 20) only against a Breaker seen beyond 3 m.
- **Far punish.** The far punish applies with TANMONO-UCHI (3.8 m) or the lane.

### Awakening and Bankai entry

Unchanged (the kit's `:awaken (:min-taken 150)`). A never-awaken A/B on the v2 code (SJ P1, HARD, 20 seeds) compared to
the awaken rule:

| vs | never awaken | awaken (the rule) |
|---|---|---|
| Yamamoto | 11 | 14 |
| Kenpachi | 18 | 17 |
| Rukia | 4 | 5 |
| Ichigo | 13 | 15 |

Awakening still pays a little, so it stays.

## Iterations inside the cell (seeds 1–20, the evaluator's jobs; the diag runner reproduces aieval's numbers)

| version | change | score | strength | masher | signature |
|---|---|---|---|---|---|
| baseline | | 0.5714 | 0.512 | 0.700 | 0.619 |
| v1 | enders, far punish, stitches on a sure hit, SAIDAN 0.7 | 0.6640 | 0.619 | 0.787 | 0.676 |
| **v2 (delivered)** | + anti-Breaker O, the Shikai's HARD neutral bands | **0.6778** | 0.637 | 0.787 | 0.689 |
| v3 | + loom HARD bands (J / SAIDAN / TANMONO up to 3.8 m) + loom SP1 pairs x0.25 | 0.6024 | 0.556 | 0.713 | 0.631 |
| v4 | v2 + walk-in K1 (perceived ring extrapolated), J1 frame trap after WARUI KUSE, no K1 at 1.7–2.6 | 0.6517 | 0.613 | 0.800 | 0.621 |
| v5 | v4 with the walk-in K1 in the Shikai only | 0.6471 | 0.594 | 0.775 | 0.679 |
| v6 | v2 + loom SP1 pairs x0.25 on HARD (aieval itself) | 0.6656 | 0.644 | 0.713 | 0.684 |

**v2 per opponent:**

| vs | wins (P1 + P2) | baseline |
|---|---|---|
| Yamamoto | 29/40 | 19 |
| Kenpachi | 34/40 | 34 |
| Rukia | 12/40 | 7 |
| Ichigo | 27/40 | 22 |

The masher, per character: Yamamoto 16, Kenpachi 16, Rukia 8 (was 5), Ichigo 16 (was 11), all of 16.

**v2 damage sources:** SJ-BREAKER 20 %, FREEZE 19 %, SJ-KIKON 10 %, SJ-T-KIKON 8.5 %, J1 8.6 %.

**Noise.** One strength share is about ±0.04 (1 sigma) at 160 matches. v2, v4, v5 and v6 are within about 1 sigma of
each other on strength. Only v3 is clearly worse, and v1 / v2 are clearly better than the baseline.

## Measured vs the baseline (final file: score.json, aieval -j 4)

- Score 0.678 vs 0.571.
- **Strength** 0.637 vs 0.512: Yamamoto +10, Ichigo +5 and Rukia +5 wins of 40.
- **Masher** 0.787 vs 0.700: Rukia 8/16 vs 5/16, Ichigo 16/16 vs 11/16.
- **Signature** 0.689 vs 0.619: more O, SAIDAN and spikes; fewer J links.
- **Pacing** OK. The NORMAL medians are 143–186 s, and every match was a K.O.

## Why it is not a repeat

There was no earlier cell. The baseline's CPU is the generic one plus the stitch / pair hooks. This cell adds:

- a difficulty-layered **policy layer** in the character's own `:reflex` hook;
- the first use of the `:sp-ender` key in the Shikai (an O / L confirm off the new pushing enders).

## Risks

- **The neutral takeover** (`brain-decide-t`) relies on AI-NEUTRAL's clock semantics. If the clock moves, the takeover
  silently does nothing.
- **SAIDAN-heavy play is strong against CPUs because they guard a lot.** A human who J's the aura beats it (J beats I).
  The learning CPU / assist bandit may want to weight it.
- **More O enders mean more cooldown-90 O.** The anti-Breaker O can find it cooling; it then falls back to the generic
  answer.
- **The loom (Bankai) is still the weak phase.** Against Kessa Ichigo and awakened Rukia it loses the damage race
  roughly 2:1. Neither loom variant tried here helped.
- **NORMAL.** NORMAL changed slightly (the 0.05–0.1 rolls). The pacing medians stayed under 210 s.

## Shared-code recommendations (not done: other files)

1. **An evaluator bug in `tools/aieval.py`, the masher part.** For the mirror job (masher Senjumaru P1 vs CPU
   Senjumaru P2), `side = 0 if c1 == c else 1` picks seat P1, the masher's.
   - So C's mirror wins count as losses. In v4 "1/16" was really 15/16 wins for the CPU (checked in a logged run).
   - The same holds for every character's mirror masher job.
   - Fix: for `kind == 'mash'` the CPU is always P2 (`side = 1`).
2. **The generic anti-Breaker J1** (`ai-reflex`, `*ai-anti-breaker-j*` 1.4) is pressed too late for a short-reach J1
   through an 8 f delay. Pressing on the perceived aura when `d < reach + slide + speed x (delay + S(J1))` would fix it
   for every character.
3. **The loom's string ender** (`string-reflex` `:sp-ender`) is only consulted when no link follows. A kit hook at
   every link's hit would let a character choose L / SP mid-string by difficulty, without the static `:l-after-k`.
