# b2a2 (round 1, refines b2a1, freeze 1a7f135): the executioner without leaks — the composure's stray J, a perceived burst read, KIN's O refused, the crossfire, every bar on the sight

A refine of **b2a1** (rescored 0.9994 at this freeze; my diagnostic of its file reproduced its own numbers exactly). It
keeps all of b2a1: the hunt and the HOSHA → K1 → stance loop with the composure, the hands-off oki HOSHA, the sight
(HIRENKYAKU on a wake-up), the rush read, the turtle, the guard wait, the EN mark and spring, KIN's route, vanish and
SANREN cash.

Only `duel/lisp/lille.lisp` changed, and only his CPU:
- **new functions:** `LB-BREAK-OUT-P` (pure), `LB-AI-BREAK-OUT-AGE`, `LB-AI-O-REFUSE-P`, `LB-AI-CROSSFIRE-P`;
- **rewritten:** `LB-AI-BURST-WAIT-P` (the coordinator's review item: no gauge read any more);
- **edits:** `LB-LINK-TICK`'s CPU branch (one line), `LILLE-OK`'s CPU clause (one line), `LB-AI-SP-ENDER` (one clause
  first);
- **one knob value:** `*LB-AI-SIGHT-BARS*` 2 → 1.

No frame data, damage, cost, rule, human branch, opponent-facing key (`:opp-trace :opp-reflex :opp-reflect :opp-aim`),
`LB-OPP-TRACE` or other file changed; the `:ai` plists are byte-identical to b2a1's; the awakening (`AI-AWAKEN-P`,
`:awaken`) and the revival (`:bankai`) are untouched; no new hook the ASSIST calls. Every new branch sits behind the forms'
`:sniper` level (HARD 1, EASY / NORMAL 0), so drift and pacing are byte-identical to the baseline. No new roll anywhere.

**Score 0.9996** = strength 1.000 (400 / 400), masher 1.000, signature 0.999 (b2a1 0.9994 = 1.000 / 1.000 / 0.999). The
score is at its ceiling; the gain is in what it can't see: **damage taken −25 to −36 % on every seed block, held-out
included, Konpaku lost about halved, the trace route +4.9 points of his damage**.

## 1. The history read

All ten round-1 proposals, the baseline and archive v1 were read with their rescored JSONs (trusted over claims):

| cell (rescored) | score | mechanism | what it meant here |
|---|---|---|---|
| baseline | 0.4449 | the shipped CPU | NORMAL drift 0.44; no HARD layer |
| v1 b0a0 / b1a0 (old rules) | – | snipe / snap opener on the gone flinch | re-derived on the 2 f cancel by every cell |
| b0a0 / b1a0 | 0.9548 / 0.9586 | mark + spring / web, vanish / hit-and-run, the HOSHA → K1 → L loop | the engines |
| b2a0 | 0.9945 | composure, oki HOSHA / mark, KIN route, K3 exits, **pendulum**, siege, vanish | the pendulum existed but NIJŪSHI-KŌ came first: 0.09 pendulums a match in b2a1 |
| b3a0 | 0.9883 | spacing (TAISHA ends the loop), **crossfire**, enders, **refusals (no non-red O over a combo)** | the O refusal and the crossfire order, credited |
| b0a1 / b1a1 / b1a2 / b0a2 | 0.9957 / 0.9937 / 0.9984 / 0.9991 | rush read, hands-off oki, turtle, wake-up charged shot, KIN SP enders, SANREN cash, guard wait | all already in b2a1 except the wake-up charged shot (re-tested below: negative) |
| b3a1 | 0.9995 | b3a0 + the located fixes, the route + crossfire pendulum, KIN snipe, wake-up charged / HIRENKYAKU | the varied mix (loop 39 %), at ~420 taken a match |
| **b2a1 (parent)** | **0.9994** | b2a0 + located fixes, the sight, the burst read (reads his gauge) | what I refine |

My diagnostic is the evaluator's HARD strength sims, both seats, with the combat log (adapted from b2a1's; scratch
analysers for after-burst windows, hunt outcomes and blow-away sources; not delivered). On b2a1's file, seeds 1–40: 400 /
400, signature 0.9986, **taken 330 a match**, Konpaku lost 0.09 (b2a1's own held-out blocks: 41–80 348, 81–120 330).
Located in its logs:

1. **The composure's J was a real press (new bug).** `LB-AI-COMPOSURE` holds J 18 f from HOSHA's start; the press goes
   into the vpad's 10-step buffer. When the opponent's BLUE repels Lille out of HOSHA inside that window, the buffered J
   starts a **plain J1** on his first free step, into the burster's free invulnerable frames: 68 of 1099 BLUEs,
   **9225 damage taken (136 each, 23 a match)** — Kenpachi's METEOR (390), Rukia's SHIRAFUNE. This, not the hunt's stance,
   was most of the 30 damage a match b2a1 still took within 90 f of a BLUE.
2. **The burst read read the burster's gauge** (the coordinator's review item).
3. **KIN's generic O ender after the route's K3**: 644 O enders in 400 matches, 373 of them on a man not red; the follow-up is
   perfect-Hoho'd / guarded and punished (`LB-W-KIKON:O-ENDER` 22.7 taken a match within 90 f).
4. **K3's crumple went to NIJŪSHI-KŌ** (0.57 a match), so b2a0's pendulum almost never ran (0.09 a match), and the two
   bars NIJŪSHI-KŌ ate were the sight's.

## 2. The action policy (HARD; EASY and NORMAL are the shipped CPU)

b2a1's executioner stays: the base form's HOSHA loop is the close finisher, the blow-away gives the oki, the trace →
TENSHIN → KIN route is Jilliel's. The changes:

**Base 万物貫通**
- **The composure's J consumed** (`LB-LINK-TICK`, his CPU's branch, HARD): HOSHA uses up the buffered J at once, so the
  held J still silences the generic reflexes but can never start a J1 after a repel. Taken within 90 f of a BLUE: 29.7 →
  6.0 a match (with the perceived burst read).
- **The burst read, perceived** (`LB-AI-BURST-WAIT-P`): the hunt takes no stance while (a) **Lille's own body is still
  being pushed** (idle with the repel's slide left: felt at once, *BURST-PUSH-FRAMES* 20 ≥ HARD's 8 f delay), or (b) **his
  perceived SNAPs show the break-out** (`LB-AI-BREAK-OUT-AGE` over the brain's ring: a reel cut short — stun with > 1 frame
  left, or airborne — then free on the next perceived step; `LB-BREAK-OUT-P` is the pure, host-tested test) less than
  `*LB-AI-BURST-WAIT*` (30) frames ago counting the delay it was seen with. No gauge, no burst field is read. The eye runs
  first, as before.
- **Every bar on the sight** (`*LB-AI-SIGHT-BARS*` 2 → 1): with NIJŪSHI-KŌ gone from KIN's ender, the bars go to
  HIRENKYAKU on the wake-up: 5.05 → 6.27 sights a match, HIRENKYAKU 6.4 → 8.0 % of his damage. His bars are now below one
  in 58 % of the base form's state samples (16 % before): every bar he earns becomes the sniper's shot.

**Jilliel / owl 近 KIN**
- **KIN's O refused on a man not red** (`LB-AI-O-REFUSE-P` via `LILLE-OK`'s CPU clause; b3a0's refusal, credited): the
  generic O ender's non-red Kikon after K3 no longer goes; a red one always does (his Konpaku). His own CPU only: a human,
  assisted or not, keeps the O.
- **The crossfire first** (`LB-AI-CROSSFIRE-P` at the head of `LB-AI-SP-ENDER`; b2a0's pendulum, b3a0 / b3a1's order,
  credited): K3's crumple with the flash step for the swing (`:fs` 13) → L chained → TENSHIN out (10 m) → its link lays
  EN's J1 on the crumpled man (b2a0's pendulum rule) → the spring materialises it → TENSHIN in → J1 K2s K3 again, until
  he is blown away. NIJŪSHI-KŌ only when the flash step can't pay the swing. The ASSIST's brain skips it (b2a1's order for
  an assisted human). 2.48 crossfires, 2.39 pendulums, 5.13 routes a match (b2a1: 0.09 pendulums).

**Unchanged**: everything else of b2a1 — the eye, the hunt, the oki HOSHA, the sight's timing, the turtle, the guard
wait, EN's mark / spring / oki mark, the vanish, SANREN cash, MUJITTAI, Trompete, the awakening, the revival, every debug
mode, the learner's clock. New `duel lille` counter keys: `ai-burst-push`, `ai-burst-seen`, `ai-crossfire`.

**Adaptation (once per event, no roll)**: the burst read reads his own push and his perceived break-out; the O refusal
reads the HUD's red state (as the generic rush does); the crossfire reads K3's crumple and his own flash step; the
pendulum reads the perceived reel.

## 3. Measurement

**EVAL_COMMAND** (40 seeds; `score.json` is the line it printed for the delivered file):

| | baseline | b2a1 (parent) | **b2a2** |
|---|---|---|---|
| score | 0.4449 | 0.9994 | **0.9996** |
| strength | 0.095 | 1.000 | **1.000** (400 / 400) |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.517 | 0.999 | **0.999** |
| drift | 0.44 | 0.44 | **0.44** (Y 44, K 28, R 31, I 35, S 38 of 80: identical) |
| pacing Y / K / R / I / S (s) | 174.2 / 169.2 / 198.1 / 209.0 / 194.7 | identical | identical, all 40 / 40 K.O. |

**Robustness** (the diagnostic = the evaluator's HARD strength sims, both seats, 400 matches a block; seeds 41–120 are
not used by the evaluator):

| | seeds 1–40 | 41–80 (held out) | 81–120 (held out) |
|---|---|---|---|
| wins, b2a1 → **b2a2** | 400 → **400** | 400 → **400** | 400 → **400** |
| signature | 0.9986 → **0.9990** | 0.9982 → **0.9987** | 0.9984 → **0.9986** |
| damage taken a match | 330 → **210** (−36 %) | 348 → **254** (−27 %) | 330 → **247** (−25 %) |
| Konpaku lost a match | 0.09 → **0.08** | 0.15 → **0.08** | 0.14 → **0.05** |

**Style** (the evaluator's `sig_by`, 40 seeds), b2a1 → b2a2:

| | b2a1 | b2a2 |
|---|---|---|
| HOSHA loop (bullets + links) | 76.4 % | **73.4 %** |
| trace combos + traces (the trace → TENSHIN → KIN route) | 11.2 % | **16.1 %** (12.5 + 3.6) |
| HIRENKYAKU (the sight) | 6.4 % | **8.0 %** |
| X-Axis lines (HIRENKYAKU, traces, NIJŪSHI-KŌ, SANREN, charged, TAISHA) | 12.5 % | **12.9 %** |
| NIJŪSHI-KŌ / SANREN | 2.1 / 0.7 % | 0.1 / 0.2 % |
| Jilliel Kikon | 2.1 % | 1.1 % |
| plain J / K | 0.1 % | 0.1 % |

Read honestly: the trace route gains ~5 points and the sniper's HIRENKYAKU ~1.6, the loop falls 3 points; the X-Axis
share as a whole barely moves, because the crossfire takes K3's crumple from NIJŪSHI-KŌ (an X-Axis line) and gives it to
traces and the route. This is still a loop-led executioner, not b3a1's mix (loop 39 %).

**The path** (seeds 1–40, 400 matches each):

| step | taken | signature | note |
|---|---|---|---|
| b2a1 | 330 | 0.9986 | |
| v1: + the composure's J consumed, the burst read perceived | 298 | 0.9987 | within 90 f of a BLUE 29.7 → 6.0 a match |
| v2: + KIN's O refused, the crossfire | 214 | 0.9987 | |
| v3: + **the kite** (stance → dash back → charged shot on the wake-up, HOSHA's link not chasing a man seen blown away) | 252 | 0.9979 | **dropped**, below |
| v4 = v2 + the sight at 1 bar | **210** | **0.9990** | HIRENKYAKU 8.0 % |
| v5: + no hunt / mark into a perceived cinematic | 210 | 0.9990 | inert, dropped |
| v6: v4 + **a parting TAISHA** (the loop's stance plans TAISHA once his combo counter is ≥ 9) | **321** | 0.9986 | **dropped**: TAISHA 3.5 %, loop 64 %, but +111 taken a match |
| **final** (v4, docstrings, `:cine` in the break-out test: inert) | **210** | **0.9990** | eval 0.9996 |

**Ablations of the final file on held-out seeds 41–80** (final: 400 / 400, taken 254, signature 0.9987):

| piece off | wins | taken a match | signature | read |
|---|---|---|---|---|
| the composure's J consume | 400 | **267** | 0.9988 | +13; within 90 f of a BLUE 11.6 → 35.3 a match |
| the burst read (perceived) | 400 | **342** | 0.9977 | +88: still the second-largest piece |
| KIN's O refusal | 400 | **380** | 0.9981 | +126, Konpaku lost 0.08 → 0.19: the largest piece |
| the crossfire | 400 | 252 | 0.9986 | robustness-neutral; trace route 17.9 → 13.4 %, NIJŪSHI-KŌ / SANREN back to 3.3 % |
| the sight at 2 bars | 400 | 245 | 0.9987 | within noise; HIRENKYAKU 7.9 → 6.2 % |

**Negative results, with their located causes:**
- **The kite (the stance's charged shot on a wake-up)**: 26 % of those shots (128 of ~490) were perfect-Hoho'd and
  countered. The stance's L has `:lock 0`, so a HARD CPU's threat reader sees it live at once; on his first free step the
  perceived shot has a lead of 8 + (≥ 0) frames ≥ the 6 its Hoho roll needs. HIRENKYAKU's `:lock 14` hides it until after
  it fires (the sight: 1960 hits, 23 perfect Hohos in 2019). The oki HOSHA is hidden by the stance (no hit window). The
  same exposure explains the neutral charged shot's cost (31–38 taken within 120 f per neutral shot). b1a1 / b3a1's
  wake-up shot pays this too.
- **The no-chase link by perception is near-inert**: a blow-away is a stagger with a long slide, not `:air`, and 2079 of
  2803 bullet blow-aways come from the third bullet at f14, two frames before the link; a perceived read can't see them.
- **A TAISHA ending** costs ~+50 % damage taken: every loop it ends is a neutral at ~5 m with both sides free at once,
  where the blow-away gives an 85 f oki.

Host tests: duel-rules **6375 ALL PASS** (b2a1's section + one check, the sight's pin updated to 1 with a one-bar case
added, nothing removed; `splice-tests.py` of the delivered file into the frozen one gives the delivered file byte for
byte; the section's diff only adds lines). The new check pins `LB-BREAK-OUT-P` case by case (a reel cut short / airborne
→ free: yes; a stun run out, a fall, a block, a cinematic: no), `*BURST-PUSH-FRAMES*` ≥ HARD's delay, and the crossfire's
frame budget (K3's active 5 + TENSHIN out's link 14 + the pendulum's 9 ≤ the crumple's 40). duel-control 89, learn 100:
ALL PASS. `tools/pkgcheck.sh duel`: 0 / 0 / 0. **The awaken A/B was not run**: the awakening and the revival are
untouched and the A/B runs at NORMAL, where this CPU is the shipped one bit for bit (the drift's 400 NORMAL matches are
identical).

## 4. Why it is not a repeat

- **New and located**: the composure's buffered J (a bug in b2a0 / b2a1's own composure, also present in every lineage
  that took the composure: b0a1, b0a2, b1a1, b1a2, b3a1); the perceived burst read (own push + the break-out in the SNAP
  ring); the two negative results above with their causes (the stance shot's lock 0 vs HIRENKYAKU's lock 14; the third
  bullet's blow-away).
- **Credited recombination into this lineage**: b3a0's non-red O refusal (which b2a0 / b2a1 never had; the largest single
  robustness piece here) and the crossfire order (b3a0 / b3a1) applied to b2a0's own pendulum, which b2a1 carried but
  starved.
- **A knob that follows a located change**: the sight at 1 bar only after the crossfire freed NIJŪSHI-KŌ's bars.

## 5. Expected benefit

At HARD he wins every one of 1200 HARD CPU matches (seeds 1–120) with 99.9 % of his damage his signature, takes 210–254
damage a match (b2a1 330–348), and loses 0.05–0.08 Konpaku a match. He never feeds a BLUE a stray J1, never throws the
Kikon a HARD CPU perfect-Hohos, swings the trace combo through EN again on every K3 he can pay for, and spends every bar
on HIRENKYAKU's shot from range at the wake-up. EASY and NORMAL are unchanged.

## 6. Risks

- **Pacing**: NORMAL is the shipped CPU: LI 209.0 / LR 198.1 (cap 240), LS 194.7 (cap 220); none within 15 s of its cap.
- **Style**: still loop-led (73 %). A more robust HARD Lille also awakens less: `AI-AWAKEN-P`'s `:min-taken 150` is
  reached in 208–239 of 400 matches instead of 242, which caps the Jilliel share. Every style lever tried that cuts the
  loop (the kite, a TAISHA ending) cost far more robustness than it moved style.
- **The burst read's ring scan**: ages up to 32 − delay − 3 (21 at HARD), so the read ends at ≤ 29 real frames, as
  b2a1's 30. Lille's own slide outside a BLUE (rare: an idle slide) also pauses the hunt for its frames (37 frames a match
  counted in all, BLUE included).
- **The O refusal** stops the non-red Kikon in KIN for his own HARD CPU (`(brain e)`); the generic O ender then skips
  without drawing its roll, so HARD's random stream shifts (HARD only).
- **The ASSIST**: no new hook; the crossfire is skipped for the ASSIST's brain; the composure consume and the refusal read
  `(brain e)`. b2a1's `:sp-ender` (SANREN / NIJŪSHI-KŌ / L for an assisted human) is unchanged: re-run `assistgate.py` at
  integration.
- **HARD may be too strong for a human** (inherited: the 9 f materialise, the HOSHA loop, the frame-exact oki).
- **Overfitting**: measured against the frozen CPUs only; the held-out seeds 41–120 agree.

## 7. Shared-code recommendations (not done)

1. **`AI-PRESS` without a buffered edge** (or the brain consuming its own inert holds): any CPU that holds a button as a
   reflex silencer leaves a 10-step buffered press that fires after a repel (this cell's composure bug is that class).
2. **A burst field in the SNAP** (the break-out perceived with the delay), so no kit scans the ring.
3. **`:awaken :min-taken` by difficulty**: a safer HARD CPU awakens less; HARD could show Jilliel more without touching
   NORMAL.
4. An ORANGE kit key, a per-difficulty `:o-ender`, and a wake-up field in the SNAP (every earlier cell's, still open).
