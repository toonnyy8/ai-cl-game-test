# b0a0 (round 1): the X-Axis hunter

A new direction from the baseline. The history held only the baseline, since this is round 1. Every change is in
`duel/lisp/lille.lisp`'s CPU code: his kits' `:ai` plists, new LB-AI-* functions, and the `(brain e)` branches of LB-EN-TICK
and LB-AI-KAMAE. Nothing shared and nothing a human player uses was touched. The test's LILLE-CPU-TESTS section adds five
checks that pin the new values (6374 checks, ALL PASS).

**Score 0.9124** (strength 0.938, masher 1.000, signature 0.843). The baseline scored 0.4769 (0.140 / 1.000 / 0.552).
NORMAL drift is 0.4275, equal to the reference. Pacing is byte-for-byte the baseline's.

## Evidence that drove it (history + my diagnostics)

- The history is the baseline only. Its known weakness (§20.7) is that his CPU fights 85–90 % of the base form under 6 m.
  The A/B shows the base form alone loses.
- I took a diagnostic of the frozen baseline: HARD, both seats, 20 seeds, 200 matches, with each phase's time and damage
  read from the combat log. Lille won 30 of 200.

  | phase (baseline) | s / match | dealt / s | taken / s | Konpaku by / on him (Kikons) |
  |---|---|---|---|---|
  | base | 39.1 | 16.6 | 23.9 | 0.37 / 1.06 |
  | Jilliel EN | 38.5 | **5.9** | **14.2** | 0.28 / 1.32 |
  | Jilliel KIN | 43.2 | 25.2 | 26.4 | 1.84 / 2.38 |
  | owl EN | 21.6 | 8.3 | 12.0 | 0.39 / 0.24 |
  | owl KIN | 20.3 | 28.6 | 20.9 | 1.82 / 0.32 |

  EN, the sniper's own mode, is the hole: he stands at 6–12 m, takes hits and deals almost nothing.
- **The bug behind it.** EN's `:moves` band at 3–14 m reads `:f 4 :q 3`, and that weight never fires. The generic
  AI-ATTACK refuses a J / K beyond the move's reach plus 0.2 ("don't whiff a string at range"). EN's J / K reach is only
  1.6 / 2.2 m, because they lay lines and have no hit window. So his CPU laid traces only from melee range (STEP-J,
  PUNISH, ANTI-BREAKER, the stance's exit) or through SP1 / SP2 at range. The ≥ 3-trace switch rule rarely had a web to
  spring.
- **HOSHA landed 97 % of its bullets** (4.5 hits of 4.7 shots a match, 0.04 blocked). In the stance its S6 is under a
  HARD CPU's perception plus guard raise. The shipped CPU used it 1.6 times a match.
- At HARD, only 0.78 of the eye's taps happen per match. Breakers into a long guard were countered by J ("J beats I").

## The action policy per form (HARD; EASY and NORMAL are the shipped CPU)

Every new key carries `:by (:easy 0 :normal 0 :hard 1)`, read by `LB-AI-KP`. NORMAL and EASY therefore play exactly as
shipped and draw no extra random numbers, so the drift and pacing are identical to the baseline.

**Base 万物貫通: the hunter.**
- `LB-AI-HUNT` (`:hunt`): when free at 0–7.5 m, a snipe event every 8 f. One roll opens the shooting stance (L). The
  event never fires into a perceived guard, Step or Hoho.
- `LB-AI-HUNT-PLAN-P`: the stance's one-roll plan at f6 becomes HOSHA within 7.5 m unless he is perceived guarding. Into
  a guard the shipped branch stays: TAISHA or the quick shot pierce it.
- `:link-k`: HOSHA's link is K1 at HARD (`LB-AI-HOSHA-LINK`; at 0.5 it is the shipped J1 / K1 roll, roll for roll). K1 is
  the heavier tagged link, and L after a K link reopens the stance, where the hunt picks HOSHA again.
- `LB-AI-SP-ENDER` (`:ender` + `:sp-ender`): a string's ender cashes out with SP2 HIRENKYAKU, which slides 6 m back to
  range and then shoots, instead of a plain reset. It reads AI-BRAIN, so the ASSIST works.
- The eye (`:eye :by`) is tapped at every threat it can make at HARD (1.0; NORMAL 0.5 as shipped). Its effect is small,
  because the hunt keeps him busy.

**Jilliel EN 遠: the snipe.**
- `LB-AI-SNIPE` (`:snipe`): when free at 2.5–13 m, an event every 6 f. One roll presses J, which lays one line at him and
  costs 3 flash step above the reserve.
- `LB-AI-SNIPE-HIT-P`: EN's tick then cancels into TENSHIN (2 f) from the J's active end, while the perceived opponent is
  on a live line (`LB-SNIPE-SWITCH-RULE`, within 0.6 m, no trace count). The materialise lands 9 f after the press, before
  a HARD CPU's 8 f perception plus its Step. The laying shot's 10 f flinch holds him. Then trace → dash (stops 1.5 m short)
  → KIN's J1, which chases the rest in its startup. That is the user's signature combo, on demand.
- **Adaptive, once per event.** No snipe at a guarding, stepping or Hoho-ing opponent, and no switch while he guards: the
  line stays and the next one he steps onto springs it. Otherwise the shipped ≥ 3-trace, via-J and starved rules stay.
- **Measured.** 17.0 snipes a match give 15.6 switches and 15.4 trace hits, against the baseline's 10.5 trace hits from
  21.5 lines. EN now lasts 16.6 s a match, dealing 25.2 / s and taking 5.5 / s.

**Jilliel KIN 近.** `LB-AI-KIN-FAR` (`:back`): TENSHIN out runs under the out rule's flash step, an event every 12 f. It
fires when he is beyond 2.5 m and not reeling, so the CPU snipes again instead of walking in for a plain string. It also
fires against a turtle (a guard held past `*ai-guard-break-hold*` within 3 m), where it replaces the generic Breaker that
HARD CPUs beat with J. The trace-combo string, the O ender and the out-after-string stay as shipped. `:sp-ender`: KIN's
ender cashes out with NIJUSHI-KO.

**MUJITTAI, the awakening, the revival.** These are unchanged. AI-AWAKEN-P (`:awaken :min-taken 150`) and the generic
`:bankai` reflex are untouched.

**The owl.** The owl EN runs the same snipe; it has the same `:snipe` key. The owl KIN has the same `:back` key. It gets
no `:sp-ender`, because its SP2 is Trompete (60 f wind-up, reflectable).

## Measurement (40 seeds, the EVAL_COMMAND; the last JSON = `score.json`)

| part | baseline | b0a0 |
|---|---|---|
| score | 0.4769 | **0.9124** |
| strength (HARD, both seats) | 0.140 | **0.938** |
| masher | 1.000 | 1.000 |
| signature | 0.552 | **0.843** |
| drift (NORMAL share) | 0.4275 | 0.4275 (Y 42, K 29, R 29, I 37, S 34 of 80: identical) |
| pacing medians Y / K / R / I / S | 175.0 / 176.0 / 223.5 / 217.1 / 205.3 | identical (all K.O.) |

`sig_by`, baseline → b0a0:

| category | baseline | b0a0 |
|---|---|---|
| plain-jk | 0.370 | 0.148 |
| trace-combo | 0.194 | 0.333 |
| lb-trace | 0.138 | 0.111 |
| lb-k-j (HOSHA) | 0.025 | 0.123 |
| hosha-link | 0.018 | 0.111 |
| NIJUSHI-KO | 0.020 | 0.055 |
| HIRENKYAKU | 0.016 | 0.024 |
| breaker | 0.036 | 0.007 |
| counter | 0.031 | 0.001 |
| quick-shot | 0.010 | 0.000 |

Path inside the cell (each a 40-seed eval):

| step | score |
|---|---|
| snipe (far 9.5) | 0.8099 |
| + KIN back, far 13 | 0.8631 |
| + the base hunt (HOSHA) | 0.8788 |
| + K1 link | 0.8833 |
| + no snipe / switch into a guard | 0.8830 |
| + turtle back, snipe every 6 | 0.8941 |
| + SP2 sp-ender | 0.9125 |
| + back 2.5 m, hunt every 8 | 0.9151 |
| final: the hunt's guard test reads the perceived snap, not the real state | **0.9124** |

The steps within ±0.003 of each other are noise.

HARD per phase after the change (20 seeds, 188 wins of 200 against the baseline's 30):

| phase | dealt / s | taken / s | before |
|---|---|---|---|
| base | 39.4 | 16.1 | 16.6 / 23.9 |
| Jilliel EN | 25.2 | 5.5 | 5.9 / 14.2 |
| Jilliel KIN | 36.0 | 16.3 | 25.2 / 26.4 |

Kikons landed by Jilliel KIN rose from 1.84 to 4.61 a match.

**The awaken A/B was not run.** Neither the awakening nor the revival changed, and the A/B runs at NORMAL, where this
CPU is the shipped one bit for bit (the same 400 NORMAL matches as the drift above). Its result is the baseline's by
construction.

Host tests:
- duel-rules: 6374 ALL PASS.
- duel-control: 89 ALL PASS.
- learn: 100 ALL PASS.
- `tools/pkgcheck.sh duel`: 0 / 0 / 0.

## Why it is not a repeat

There was no earlier cell. Against the baseline, this cell fixes a located bug: EN's ranged J / K were dead weight in
neutral, because of AI-ATTACK's reach filter. It also adds structurally new behaviour: a one-line snipe with its own
switch rule, a KIN back-switch, a base-form HOSHA opener, and SP cash-outs. It does not retune the shipped knobs.

## Expected benefit

His HARD CPU now plays the sniper the user asked for, in character:
- the trace → TENSHIN → J combo on demand, at any range up to 13 m;
- HOSHA as the base form's opener and its links;
- HIRENKYAKU and NIJUSHI-KO as cash-outs;
- KIN as a short visit, not a brawl.

Strength rises from 0.14 to 0.94 and signature from 0.55 to 0.84.

## Risks

- **Pacing.** NORMAL is unchanged, so the medians are the baseline's: LR 223.5 (cap 240), LI 217.1 (cap 240), LS 205.3
  (cap 220). LS is within 15 s of its cap, and so is LI at 217.1. These are the baseline's risks, not new ones.
- **NORMAL / EASY.** These players never see the hunter: the user's layering is met at its minimum, NORMAL = shipped.
  A partial NORMAL version (e.g. snipe 0.2–0.3) would show the style but would move the drift. The snipe is very strong
  (HARD 0.14 → 0.94), so it needs its own drift measure.
- **HARD may now be too strong for humans.** The snipe's 9 f materialise beats any reaction, which is fair: it is EN's
  rule for a human too. But a HARD Lille CPU now wins 94 % against the other HARD CPUs.
- **The ASSIST.** The new `:sp-ender` is called by the ASSIST's AUTO COMBO with its borrowed HARD brain (AI-BRAIN). A
  Lille player's assisted string enders now cash out into SP2 when the bars allow. `assistgate.py` should be re-run at
  integration.
- **Overfitting.** Measured against the frozen opponents only. The snipe exploits that no CPU reads EN's J as a threat
  beyond its 1.6 m reach (`:opp-trace` steps off seen traces only).

## Shared-code recommendations (not done)

- AI-ATTACK's no-whiff reach filter makes any kit's ranged "J / K that isn't a hit" unusable from `:moves`. A per-move flag
  (e.g. `:params :lay t`) exempting it would let EN's tables mean what they say at NORMAL too.
- The opponents' `:opp-trace` reacts to a trace only after it is seen, which is slower than a 2 f cancel. If the user
  wants the snipe answerable, the defence belongs in the opponents' CPUs, for example reading EN's J start at range as a
  threat. That would be a deliberate opponent change.
