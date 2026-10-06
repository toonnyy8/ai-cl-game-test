# Kenpachi AI v2, cell b1a0 (round 1, new direction): "one intercept planner"

## Result (official `python3 tools/aieval.py --char 1 -j 4`, the delivered ken.lisp; aieval at 9df6ecc)

| | score | strength | masher | signature | pacing (NORMAL medians) |
|---|---|---|---|---|---|
| baseline (re-measured) | 0.3006 | 0.175 | 0.400 | 0.528 | ok |
| b0a0 (rescored) | 0.7995 | 0.894 | 0.875 | 0.441 | ok |
| **b1a0** | **0.7823** | **0.844** | **0.988** | **0.393** | ok, 20/20 K.O. each, 133-161 s |

All code is in `duel/lisp/ken.lisp` ("the CPU" section). Every form's `:ai` gets `:reflex ken-ai-reflex :sp-ender ken-sp-ender`.
No move, frame, cost, form rule, `:ai` table number or other file changed. Every chance is a `*ken-ai-...*` plist by
difficulty (EASY 0, NORMAL small, HARD full). EASY plays the shipped CPU (plus a few extra SIM-RND01 draws). The CPU sees only
the perceived SNAP ring and the HUD gauges (Konpaku), and its dice come from SIM-RND01.

## Mechanism: why it isn't b0a0 again

b0a0 wrote one hand-made reflex per situation (lunge J1, walk-in, anti-Breaker, Hoho a commit, anti-mash stance, no slow
reset). This cell writes one **planner**. `KEN-ARRIVE` gives, for each command, the frame its hit can touch him at distance d:
- J1: its reach plus its lunge (at most 0.8).
- K1: its reach.
- The charge: the 14 m/s dash, S + run / 0.233.
- The leap: it lands `slide` ahead.

It also reads his **perceived velocity** from two consecutive SNAPs of the brain's ring (`KEN-VEL`, `KEN-CLOSING`). No earlier
cell does this, and neither does ai.lisp. The planner then picks one of these targets:

1. **Recovering / reeling** (his perceived frames left, minus our delay): the first command in the order J1, SP2, SP1, K1
   that lands before he is free. The signature moves (SP2, SP1) are tried only on a roll (`*ken-ai-sig-first*` HARD 0.8). The
   range is up to 9 m (the charge's reach), not only J reach.
2. **Breaker aura / dash**: where his dash will be at our active frame, against when his strike lands (any hit counters a
   Breaker). K1, else J1, else wait (the generic J1 comes too early).
3. **Neutral first strike** (per step, HARD 0.35): his predicted distance once our delay and the move's startup have passed,
   from his closing speed.
   - J1 if that distance falls inside J1's reach plus the lunge.
   - Else K1, if he is closing and lands between his J's reach (his kit's J1 reach + slide + 0.2) and K1's reach.
   - It also fires against a masher, who walks straight into K1. No anti-mash special case is needed.
4. **Enders** (`ken-sp-ender`, HARD 0.85): off a landed J3 / K3 (the push), SP2's charge while the bars allow, else the O
   ender. Not when a Soul Break should finish him.
5. **Bankai held for the race's end** (`ken-bankai-hold`, a rule at HARD only, from b0a0's measured win rates): enter only
   with <= 2 Konpaku, or <= 3 with the opponent at <= 4.

Per form, the planner is the same and the moves' data decides what fits:
- **Base / KATATE**: J1 with its lunge, the charge, the leap (Buttagiru, 4-7.5 m).
- **RYOTE / NOMIHOSE**: MEN has no lunge, so K1 (3.9 m) does more of the first strikes.
- **Bankai**: B-J1's 1.0 m lunge, capped at 0.8.

## Measurement path (every row an official run)

| variant | change | strength | masher | sig | score |
|---|---|---|---|---|---|
| v1 | planner (punish ranked by damage: K1 first) + Breaker + K1 approach | 0.306 | 0.475 | 0.523 | 0.3834 |
| v2 | punish J1-first; first strike J1 / K1 by predicted distance (HARD 0.15) | 0.812 | 0.725 | 0.305 | 0.6935 |
| v3 | + the ender hook | 0.819 | 0.787 | 0.409 | 0.7305 |
| v3b | first strike also vs a masher | 0.819 | 0.912 | 0.403 | 0.7543 |
| v4 | first strike HARD 0.35 | 0.819 | 0.975 | 0.393 | 0.7649 |
| **v5 (delivered)** | **+ Bankai held late** | **0.844** | **0.988** | **0.393** | **0.7823** |
| v6 | ender 1.0, sig-first 1.0 | 0.806 | 1.000 | 0.410 | 0.7658 (reverted) |

**Lessons:**
- v1 failed because it ranked the punish by raw damage: K1 (70) beat J1 (35). J1 is faster and starts a string.
- The velocity-timed first strike answers the masher: 0.40 -> 0.99, better than b0a0's stance (0.875).

**Diagnosis** (10 seeds, Ken P1, v4). Wins: Yamamoto 9, Senjumaru 10, Ichigo 8, Rukia 7. What still hurts:
- Ichigo's Kikon rush (IC-K-KIKON, 6.3k damage taken).
- Rukia's J strings.
- Many blocked first-strike J1s and RYOTE MENs.

## Risks
- **Signature is 0.39** (baseline 0.53). The planner's J1-first ranking feeds J strings, and forcing signature moves (v6)
  costs strength.
- **HARD is much stronger.** NORMAL uses small chances. NORMAL pacing (133-161 s) runs a little faster than shipped.
- **The Bankai is rarer at HARD** (a finisher only).
- **The velocity read** uses two ring SNAPs, both at least the perception delay old (no reading ahead).

## Next cells / combinations
- **Combine with b0a0's Hoho-a-commit and no-slow-reset**, which this cell lacks. The parts are orthogonal: b0a0 is stronger
  in defence, this cell answers the masher better.
- **A Kikon-rush answer** (Hoho its dash at HARD): the biggest damage source left against Ichigo.

## Shared-code recommendation (not done)
ai.lisp's punish / follow-up reflexes could use an arrival model like KEN-ARRIVE (reach + slide, the dash). Every CPU's neutral
could use a closing-speed read like KEN-CLOSING.
