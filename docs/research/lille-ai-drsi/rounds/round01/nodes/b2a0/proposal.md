# b2a0 (round 1, at the re-freeze 6081a39): the executioner — composure, okizeme, the KIN route

A new direction from the baseline. No parent. Only `duel/lisp/lille.lisp` changed, and only his CPU:
- one new `:ai` key, `:sniper`, on the base, EN and KIN forms (the MUJITTAI forms inherit it). Its `:by` gives the level by
  difficulty: `(:easy 0 :normal 0 :hard 1)`.
- `:sp-ender lb-ai-sp-ender` on the two KIN forms (Jilliel's and the owl's);
- four knobs (`*lb-ai-oki-hosha*`, `*lb-ai-oki-mark*`, `*lb-ai-composure*`, `*lb-ai-pendulum*`) and new `LB-AI-*` functions in a
  new block at the end of the AI section;
- hook-ups in `LB-AI-REFLEX` (base), `LB-AI-EN`, `LB-AI-KIN`, `LB-AI-KAMAE`, `LB-AI-LINK`, and the `(brain e)` branches of
  `LB-EN-TICK` (the spring) and `LB-LINK-TICK` (the latches).

No rule, frame, damage, cost, opponent-facing key, `LB-OPP-TRACE` or shared file changed. `AI-AWAKEN-P` / `:awaken` and the
`:bankai` revival are untouched. The LILLE-CPU-TESTS section adds 3 checks (6370 → 6373 ALL PASS) and keeps every earlier pin.

**Score 0.9941** = strength **1.000** (400 / 400), masher 1.000, signature **0.985**. For comparison: baseline 0.4480 (0.098 /
0.995 / 0.525); best history b1a0 0.9563 rescored (0.968 / 1.0 / 0.923). Drift and pacing are byte-identical to the
baseline.

## The history read

| cell | rescored | mechanism | what I took from it |
|---|---|---|---|
| baseline | 0.4480 | the shipped CPU | HARD is 0.098, NORMAL drift is 0.4675: no HARD layer exists |
| b0a0 | 0.9518 | EN mark + 2 f spring; KIN vanish; base hunt → HOSHA, K1 + L latched loop | both engines are sound. Its own recommendation #1 names the leak: the generic ORANGE on a HOSHA bullet's hit |
| b1a0 | 0.9563 | EN web (convergence count); KIN hit-and-run; the same HOSHA loop; SP2 cash-out | same engines. Volley 2 is a trap; the wary read is inert against CPUs |
| v1 b0a0 / b1a0 | (old rules) | the snipe; the snap opener on the laying shot's flinch | the opener's real cause was the 2 f cancel's timing (both round-1 cells re-derived this) |

Both history cells converge on the same two openers and plateau near 0.95. **What is left is not the openers.** I ran a
scratch diagnostic of b0a0's file (HARD, both seats, 10 seeds; `scratchpad/lille-b2a0/diag.py`, not delivered):
- 94 / 100 wins; signature 0.927; dealt 4632 / taken 1199 a match.
- **plain J / K 306 a match, and 245 of it is the base form's plain string** (LB-J1 69, LB-K3 61, J2 40, J3 39, K2S 36). Its
  source: **Lille's own ORANGE, 2.16 a match**. The generic `AI-ORANGE-P` fires on a HOSHA bullet's hit: a `:sig` hit, the
  victim within Q1's reach, and HOSHA's leap always stops 0.95 m short. Then `AI-CHAIN-FOLLOW-P` restarts a plain J string.
  This is the located bug b0a0 reported but could not fix in-kit: both run before the kit's reflex.
- **6.7 blow-aways by him a match** (the HOSHA loop fills the stun tolerance). After each one, the opponent gets ~60 f of
  iframes, then the first move. The history's hunt only acts once he is up and "open".
- The trace combo runs the generic string, J1 J2 J3 (24 24 30) about 70 % of the time. J1 → K2s → K3 (24 50 72) is a
  legal route and also combos.

So this cell keeps the proven openers and adds three structurally new mechanisms, each aimed at one measured leak.

## The action policy (HARD; EASY and NORMAL are the shipped CPU bit for bit)

The idea is an executioner, not a sprayer. Every opening goes to the most damaging route he owns, and that route stays his
signature to the end. A downed opponent is met on the first frame he can be hit again.

**Base 万物貫通**
- The hunt (as in history): the shooting stance onto a perceived open opponent within 7.5 m with no threat near. Its plan at
  f6 is HOSHA. The loop: HOSHA's link is K1 with L latched on it, so the stance reopens at f4 and HOSHA fires again on the
  reeling opponent.
- **The composure (new; `LB-AI-COMPOSURE`).** When the stance's plan is HOSHA, his CPU holds J for 18 f. J does nothing in
  HOSHA, since HOSHA is not a string link and its CPU link is picked by `LB-LINK-TICK`, not the pad. While a press is held,
  `BRAIN-STEP` does not run `AI-REFLEX` on those steps. Its `(not (vpad-down :quick))` also keeps `AI-CHAIN-FOLLOW-P` off.
  So no ORANGE can take the loop over. This is the CPU choosing not to burst out of its own signature combo, through its own
  buttons only.
- **The oki HOSHA (起き攻め; new; `LB-AI-HUNT`'s first branch, `LB-WAKE-LEFT`, `LB-AI-OKI-P`).** On a perceived down or
  waking opponent within 8.4 m:
  - the frames left to his first vulnerable frame are down 30 + wake-up 30, less the snap's frame and the perception delay;
  - the stance is pressed when 9–12 frames are left. The stance is up at f6 and HOSHA's first bullet lands at f6, so the
    bullet lands **12 frames after the press**, on his first hittable frame.
  - He can't see it coming: his perception shows the stance at most, and the stance has no hit window.
- **The siege (new, small).** A perceived guard within 3.2 m → the stance → TAISHA. Its x-axis bullet goes through the guard
  (chip 15 %, drain 30) instead of the generic plain strings into a guard.

**Jilliel / owl 遠 EN**
- The mark and the spring (as in history): J1 laid straight at an open opponent at 1.5–13.5 m, above the shipped reserve.
  `LB-EN-TICK` springs TENSHIN's 2 f cancel from J1's active end while he stands within 0.6 m of a live line as it would
  materialise. The shipped switch rules still run first. The starved switch into KIN is NORMAL-only.
- **The oki mark (new).** On a downed opponent, J1 is pressed 7–9 frames before his first vulnerable frame. Its line lands on
  f4, the cancel on f7, the materialise 9 f after the press. The spring accepts a waking opponent with at most 2 frames left.

**Jilliel / owl 近 KIN**
- **The route (new; `LB-AI-LINK-LATCH`).** The trace combo's KIN J1 (TENSHIN in's link) latches K at once: J1 → K2s → K3.
  K2s has only K3 after it, so the whole route is fixed with one latch. All three are trace-combo hits.
- **K3's exits (new; `LB-AI-SP-ENDER`, the generic STRING-REFLEX hook, after the O ender's own roll).**
  - NIJŪSHI-KŌ with two bars (Jilliel; the owl's SP2 is Trompete, which stays the punish's);
  - else L latched on K3: TENSHIN out chained off the hit (10 m, iframes), with ≥ 13 flash step (the out price + one J line).
- **The pendulum (new, small; `LB-AI-LINK-HARD`).** TENSHIN out's link at its f14 is EN's J1 when he is still perceived
  reeling ≥ 9 more frames. K3's crumple is 40 f; the materialise lands ~28 f after K3's hit. The spring (or the shipped busy
  rule) fires it: trace → TENSHIN in → J1 K2s K3 → out → trace … until the stun tolerance blows him away.
- **The vanish** (as in history, simplified): free in KIN with ≥ 13 flash step and no red rush to take → TENSHIN out. KIN
  never plays neutral, because every KIN J / K that a trace did not open is a plain string.

**MUJITTAI, the eye, Trompete, the awakening (`AI-AWAKEN-P`), the revival (generic `:bankai`)**: as shipped.

**Adaptation.** Every rule reads the perceived snap, once per event:
- no hunt or mark into a guard, a Step, a Hoho, or a down opponent;
- a guard up close is besieged instead;
- a downed opponent is met by the oki timing, read off his perceived wake-up;
- the pendulum only runs while he is perceived reeling long enough.

There is no roll per step (no new roll at all). Every new branch returns NIL when its condition fails. None resets
BRAIN-DECIDE-T, so the learner's clock and AI-DECIDE's neutral run as before.

## Measurement

EVAL_COMMAND, 40 seeds, frozen evaluator. `score.json` is the final file's line. The same file was run twice and gave the
same JSON.

| | baseline | b2a0 v1 (no vanish / siege) | **b2a0 final** |
|---|---|---|---|
| score | 0.4480 | 0.9791 | **0.9941** |
| strength | 0.098 | 0.995 | **1.000** |
| masher | 0.995 | 1.000 | 1.000 |
| signature | 0.525 | 0.953 | **0.985** |
| drift (NORMAL share) | 0.4675 | 0.4675 | 0.4675 (Y 38, K 36, R 34, I 43, S 36 of 80: identical) |
| pacing Y / K / R / I / S (s) | 177.2 / 165.8 / 210.3 / 208.9 / 200.2 | identical | identical, all 40 / 40 K.O. |

`sig_by` final: HOSHA bullets 0.402, HOSHA links 0.330, trace combos 0.135, traces 0.037, NIJŪSHI-KŌ 0.036, Jilliel Kikon
0.032, **plain J / K 0.013** (b0a0 0.063, b1a0 0.072), TAISHA 0.007, Breaker 0.002, charged 0.002.

Ablations: my diagnostic, HARD both seats, 10 seeds (100 matches), the final file with one piece removed. Wins are 100 / 100
in every row, so the parts show in signature and damage.

| variant | signature | dealt / taken a match | Lille ORANGE / match | note |
|---|---|---|---|---|
| final | **0.981** | 4827 / **489** | 0.05 | |
| no composure | 0.945 | 4574 / 690 | **2.21** | plain base strings return (LB-J1 62, LB-K3 54 …) |
| no oki (HOSHA + mark) | 0.980 | 4460 / 809 | 0.06 | oki: −40 % damage taken (blow-aways no longer give the opponent the first move) |
| no route / K3 exits / pendulum | 0.979 | 4790 / 685 | 0.39 | route: +NIJŪSHI-KŌ and the K string inside trace combos, less taken |
| no vanish / siege (= v1) | 0.951 | 4686 / 747 | 0.07 | KIN neutral strings (≈160 plain a match) |
| b0a0's file (same diagnostic) | 0.927 | 4632 / 1199 | 2.16 | 94 / 100 wins |

Counters a match (final, 10-seed diagnostic):
- hunt 13.0, siege 1.45, vanish 8.8, K3 → SP2 0.83, K3 → out 0.32;
- blow-aways by him 12.7, opponent BLUE bursts 2.9;
- from v1's run of the same pieces: oki HOSHA 8.6, oki mark 0.2, pendulum 0.4–0.5, route 4.8–8.
- The pendulum and the oki mark are rare: the base form's loop wins most matches before Jilliel matters much.

Host tests: duel-rules 6373 ALL PASS, duel-control 89, learn 100; `tools/pkgcheck.sh duel` 0 / 0 / 0. The awaken A/B was not
run: the awakening and the revival are untouched, and the A/B runs at NORMAL, where this CPU is the shipped one bit for bit
(the drift's 400 NORMAL matches are identical).

## Why it is not a repeat

The openers (the hunt / HOSHA loop, the EN mark / spring) are the history's, re-implemented and credited. They are kept on
purpose: both cells showed they are the only HOSHA / trace openers a HARD CPU cannot react to.

The new structure is in three mechanisms neither cell had, each aimed at a leak measured on b0a0's own file:
1. **The composure** fixes the located ORANGE leak (b0a0's recommendation #1) inside his own CPU, with no shared change.
   Signature +0.036, ORANGE 2.2 → 0.05.
2. **Okizeme** is timing on the perceived wake-up, a new axis: no history cell read down / wake-up at all. Damage taken −40 %.
3. **The KIN route, K3's exits and the pendulum** are what happens after the opening. The history used the generic string.

The vanish is history's idea, kept for the measured KIN-neutral leak (+0.03 signature). The score moves 0.956 → 0.994. The
gain is in signature (0.923–0.932 → 0.985) and strength (0.948–0.968 → 1.000).

## Expected benefit

His HARD CPU wins all 400 HARD matches, and 98.5 % of his damage is his signature: HOSHA's leap-and-fire loop, the trace →
TENSHIN → J1 K2s K3 combo, and NIJŪSHI-KŌ. Damage taken falls to ~490 a match. EASY and NORMAL are unchanged.

## Risks

- **Pacing**: the NORMAL medians are the baseline's: LR 210.3 (cap 240), LI 208.9 (cap 240), LS 200.2 (cap 220). LS is
  within 20 s of its cap. That risk is inherited, not introduced. No median is within 15 s of its cap.
- **Style**: at HARD he lives in the base form's HOSHA loop, close up. The charged X-Axis shot is 0.2 % of his damage: the
  evaluator rewards HOSHA (whitelisted) and the loop wins, so the "long-range sniper" is barely seen. A human playtest
  should judge whether this reads as Lille. A style constraint (for example, a minimum share of shots at ≥ 8 m) would need
  an evaluator change.
- **The composure is a pad trick.** It holds an inert button so the generic reflexes stay silent for 18 f of HOSHA. Every
  reflex is silenced in that window (guard-cancel, ORANGE, chain-follow), not only ORANGE. His own BLUE burst still runs,
  because it sits before the press branch in BRAIN-STEP. A cleaner fix is shared (recommendation 1).
- **HARD may be too strong for a human.** The oki HOSHA lands on the first hittable frame after a wake-up. A human can
  answer it: a Burst, a wake-up Step (iframes on the vulnerable frame), or holding guard (HOSHA's bullets are guardable). The
  CPUs have no wake-up option.
- **The ASSIST**: the new `:sp-ender` on KIN reads `(ai-brain e)`. The ASSIST's HARD brain will end an assisted human's KIN
  K3 with NIJŪSHI-KŌ (two bars) or TENSHIN out. Re-run `tools/assistgate.py` at integration. Nothing else is reachable for a
  human: every other new branch reads `(brain e)` or the reflex's own brain.
- **Overfitting**: measured only against the frozen CPUs. Their burst and wake-up logic has no answer to frame-exact oki.

## Shared-code recommendations (not done)

1. A kit key for ORANGE (`:orange` by difficulty, or a per-move "no ORANGE off this `:sig`"), so the composure's pad trick
   can go.
2. `AI-ATTACK`'s reach filter keeps EN's ranged J / K silent at NORMAL (v1 b0a0's finding, still true).
3. A generic okizeme hook (perceived frames to wake-up in the snap: `snap-left` for `:down` / `:wakeup`, today 0), so every
   kit can time its wake-up pressure without re-deriving `*reaction-frames*`.
