# b1a0 (round 1, restart on decisions 41–43): the sniper's HARD layer — the web, the hit-and-run, the HOSHA loop

A new direction from the baseline (no parent). Only `duel/lisp/lille.lisp` changed, and only his CPU: the AI section (new
`*LB-AI-...*` knobs and `LB-AI-*` functions, `LB-AI-REFLEX` / `LB-AI-EN` / `LB-AI-KIN` / `LB-AI-KAMAE` / `LB-AI-LINK`, two
`LBAI` fields), the `(brain e)` branches of `LB-EN-TICK` (the 2 f cancel) and `LB-LINK-TICK` (the HOSHA link), and one key,
`:sp-ender LB-AI-SP-ENDER`, on the base and Jilliel KIN `:ai` plists. No frame data, damage, rule, hook for a human, opponent
key (`:opp-trace` / `:opp-reflex` / `:opp-reflect` / `:opp-aim`) or shared file changed. The LILLE-CPU-TESTS section gains
three checks that pin the new values (6370 → 6373, ALL PASS).

## Result (frozen evaluator, 40 seeds; `score.json`)

| | score | strength | masher | signature | drift (NORMAL share) | pacing medians Y / K / R / I / S |
|---|---|---|---|---|---|---|
| baseline | 0.4496 | 0.105 | 1.000 | 0.519 | 0.4125 | 176.8 / 170.2 / 216.2 / 203.9 / 196.8 |
| **b1a0** | **0.9600** | **0.975** | 1.000 | **0.925** | **0.4125** (Y 39, K 32, R 27, I 28, S 39 of 80: identical) | identical, all 40 / 40 K.O. |

`sig_by`, baseline → b1a0: HOSHA bullets (`lb-k-j`) 0.029 → **0.250**, trace combos 0.177 → **0.250**, HOSHA links 0.020 →
**0.212**, traces 0.103 → 0.084, plain J / K 0.398 → **0.070**, Jilliel Kikon 0.061 → 0.049, NIJŪSHI-KŌ 0.022 → 0.046, Breaker
0.037 → 0.003, counters 0.034 → 0.001, quick shot 0.011 → 0.000.

HARD per opponent (both seats, 80 each; my diagnostic of the same sims): Yamamoto 75, Kenpachi 78, Rukia 80, Ichigo 79,
Senjumaru 78. Per phase (seconds a match, dealt / taken per second), baseline (10 seeds) → b1a0 (40 seeds):

| phase | baseline | b1a0 |
|---|---|---|
| base | 38 s, 17.4 / 23.8 | 51 s, **49.7 / 8.0** |
| Jilliel EN | 40 s, 4.2 / 16.4 | 22 s, **16.7 / 7.1** (trace damage lands while still EN) |
| Jilliel KIN | 38 s, 25.5 / 28.2 | 38 s, **42.1 / 14.1** |
| the owl EN / KIN | 20 + 18 s | 2 + 3 s (he wins before the revival) |

## What the history says (read first)

- **This round**: no earlier cell (b0a0 runs in parallel). **Baseline** (0.4496): HARD strength 0.105; EN is the hole (it
  deals ~4 / s and takes ~16 / s, my 10-seed diagnostic matches v1's table).
- **archive/v1 b0a0** (0.9124 on decision 39's rules): the located bug — EN's `:moves` band (3–14 m `:f 4 :q 3`) never fires,
  because AI-ATTACK refuses a J / K beyond its reach + 0.2 (EN's J / K reach is 1.6 / 2.2 m: they lay lines, no hit window).
  Its fix, the "snipe": a J laid at him and cancelled into TENSHIN while the line holds him. Plus a base-form HOSHA hunt,
  K1 as HOSHA's link, SP2 enders, KIN going back to EN.
- **archive/v1 b1a0** (0.9027): the same opener ("snap shot") described as riding the laying shot's 10 f flinch, plus KIN as a
  hit-and-run vehicle and no starved switch-in.
- **Re-tested on today's rules** (no flinch): was v1's opener the flinch or the timing? The timing. J1 lays its line on f4,
  the 2 f cancel materialises it at f9, and decision 41's snap turns the line ≤ 10° onto him; a HARD CPU perceives the line
  at age 8 (`LB-OPP-TRACE` needs it seen) so it never gets to step. Measured here without the flinch: 15.7 snaps a match, 15.6
  trace hits, HARD wins 0.12 → 0.75 (20 seeds) from the EN change alone. So the v1 idea was sound; only its explanation leaned
  on the flinch.

## The action policy (HARD; EASY and NORMAL are the shipped CPU, bit for bit)

Every new behaviour is a level by difficulty, `(:easy 0 :normal 0 :hard 1)`, tested before anything else, so EASY and NORMAL
take the same branches and draw the same random numbers as shipped (the drift and pacing JSON are byte-identical to the
baseline's). At HARD every rule is deterministic on what he perceives (no per-step roll; the shipped rolls stay where they
were: the eye, the stance, HOSHA's link roll is still drawn).

**遠 EN — the web (照準網), my direction.** Decision 41's snap turns *every* live trace ≤ 10° toward him when it materialises, so
lines laid at him from where Lille stood converge on him later. EN lays a J line at him every 6 f while he is perceived
2.5–13 m away and not stepping / Hoho-ing / guarding (`LB-AI-WEB-LAY`; the reserve rule of LILLE-OK still applies), and EN's
tick, from the J's active end, counts the **hit groups of all live traces that would hit where he will be** at the
materialise: his perceived position moved on by his perceived velocity over the delay + the 2 f wind-up
(`LB-AI-WEB-AT`, `LB-AI-WEB-COUNT`: each line snapped toward that point, radius + his hurt radius − 0.15 m; a K fan is one
group). It cancels into TENSHIN when the count reaches the volley size (`LB-AI-WEB-CANCEL-P`):
- **the volley** (`LB-AI-VOLLEY-K`): 1 group on a free opponent (the line just laid: the snap), 2 while he is committed
  ≥ 14 more frames (J2's line comes 12 f after J1's active end), 3 while ≥ 28; any group at the string's last line;
- **the wary read** (`LB-AI-WEB-WARY-P`, adaptive, one decision per web switch): after 2 web switches in a row whose traces
  missed (he stepped off, guarded, blew through), the web lays only at a committed opponent (running, in a move, reeling)
  until one hits. Inert against the frozen CPUs (they never see the line in time: 1.2 misses a match), it is the answer to a
  human who learns to step on the J;
- the shipped switch rules (≥ 3 traces and him on one, via-J, the stance reflex) run first, unchanged.

**近 KIN — the hit-and-run.** KIN is the combo's vehicle, not a place to fight: free with nothing to cash in (he is not
reeling / recovering in J1's reach, no red rush), TENSHIN out back to the lines as soon as its price + 9 flash step is there
(`LB-AI-KIN-RUN`: EN arrives able to lay three J lines). EN starved of flash step switches in only onto an opponent busy for
the 16 f wind-up (`*LB-AI-STARVE*`), never into KIN's neutral. A landed KIN string's last link cashes out with NIJŪSHI-KŌ
(`LB-AI-SP-ENDER`, below). The trace combo itself (trace → dash → J1 → the string → the O ender) is the shipped generic one.

**万物貫通 base — the hunt and the HOSHA loop.** At an open opponent (perceived standing, walking, running, in a move or
reeling) 2.5–7.5 m away, the shooting stance, its plan HOSHA (`LB-AI-HUNT`; `LB-AI-KAMAE`'s override; the 5 m leap + 3 m
bullets; HOSHA's S6 lands under a HARD CPU's perception + guard raise). A bullet's hit links **K1** (`LB-AI-LINK`), and L is
latched on that K1 at once (`LB-AI-HOSHA-LOOP`, the same latch a human's L press during a K link sets: `KIT-L-LINK`, the stance
at f4 when K1 touches him); the stance's plan on a reeling opponent at any range under 8 m is HOSHA again: bullets → K1 →
the stance → HOSHA … (every piece of it whitelisted: HOSHA's bullets and its K1 link). The rest of the stance plan (≥ 8 m the
charged shot, the dash back at 6–8 m, a guard's pierce) is shipped. A landed base string's last link cashes out with SP2
HIRENKYAKU (6 m back to range, then the X-Axis shot).

**The cash-out** (`:sp-ender LB-AI-SP-ENDER`, base and Jilliel KIN): ai.lisp STRING-REFLEX's hook, after the O ender's own
roll failed: SP2 when the bars are there. It reads AI-BRAIN, so the ASSIST's borrowed HARD brain uses it for a human too
(the established pattern of Kenpachi's / Rukia's / Ichigo's `:sp-ender`).

**Unchanged**: MUJITTAI (in and out), the eye, Trompete, the owl's CPU, the awakening (AI-AWAKEN-P, `:awaken (:min-taken
150)`), the revival (the generic `:bankai` reflex), the debug modes 79000–79999, the `duel lille` counters (new keys added:
`ai-web-lay`, `ai-switch-web`, `ai-web-miss`, `ai-hunt`, `ai-hosha-loop`, `ai-switch-run`, `ai-sp-ender`), the learning CPU's
clock (every new reflex acts on an event and returns NIL otherwise; the web's lay event is every 6 f, not every step, and
doesn't touch BRAIN-DECIDE-T).

## How each piece did (HARD, both seats; my diagnostic `diag.py`, the same sims as the evaluator's strength part)

| step (cumulative unless noted) | seeds | HARD wins | signature (HARD) |
|---|---|---|---|
| baseline | 10 | 0.120 | 0.511 |
| + the web, volley 1 (the snap) | 20 | 0.750 | 0.782 |
| the web with volley 2 instead | 20 | 0.465 | 0.623 | (falls into the Step his trace reflex takes on seeing J1's line: the f19 materialise lands in its iframes) |
| the web with volley 3 instead (the J string) | 20 | 0.775 | 0.758 | (more trace damage, fewer combos; equal) |
| the web + KIN run (alone) | 20 | 0.740 | 0.788 | (no gain without the starve rule: EN arrived starved) |
| the web + the starve rule (alone) | 20 | 0.785 | 0.784 |
| the web + the hunt, 3–7 m (alone) | 20 | 0.870 | 0.745 |
| hunt + starve (+ the eye at 1.0, later dropped: neutral) | 40 | 0.858 | 0.750 |
| + KIN run (fs + 0 / 3 / 9) | 40 | 0.887 / 0.917 / 0.925 | 0.81 |
| + HOSHA's link K1 | 40 | 0.927 | 0.830 |
| + the cash-out SP2 | 40 | 0.940 | 0.836 |
| + the stance after a K link on a reeling opponent → HOSHA | 40 | 0.955 | 0.851 | (full eval: **0.9225**) |
| + the HOSHA loop (L latched on the K1) | 80 | 0.960 | 0.921 |
| ablations at 80 seeds: KIN run off / starve off / cash-out off / eye 1.0 off | 80 | 0.916 / 0.935 / 0.951 / 0.960 | 0.874 / 0.905 / 0.914 / 0.921 |
| hunt band (2.5 7.5) vs (3 7) / (2 8) / (2.5 6.5) | 80 | 0.969 vs 0.960 / 0.958 / 0.968 | 0.92 |
| + the commitment volley (14 28) | 80 | 0.971 | 0.922 | (±0.007 noise: neutral; kept as the web's rule) |
| final file (+ the wary read) | 40 / 80 | 0.975 / 0.969 | 0.925 / 0.923 | (full eval: **0.9600**) |

The lay cadence (3 / 6 / 12 f) and the commitment volley measured within noise.

## Why it is not a repeat

- The history is the baseline and v1's two cells, measured on a rule that no longer exists. This cell re-tests their
  opener on today's rules and finds it was the 2 f cancel's timing, not the flinch (above), and builds its EN on decision
  41's snap as a **convergence count** over all live lines at a **predicted** position (not v1's "gap ≤ 0.6 to the perceived
  position"), with a commitment-sized volley and an adaptive wary read. The volley experiments are a new negative result: a
  2-line volley is a trap (the reflex Step's iframes), 3 lines only ties.
- New mechanism in the base form: **the HOSHA loop** (L latched on HOSHA's K1 link, the stance's plan HOSHA on a reeling
  opponent at any range). It is what moved the signature from 0.85 to 0.92: the base form's damage was mostly the plain
  K2 / K3 after HOSHA's K1 (270 a match, my "opener" breakdown), now HOSHA again.
- Pieces that worked in v1 (the hunt, K1 link, SP2 cash-out, KIN run, the starve rule) are combined and re-measured one by
  one on the new rules (the ablation rows above); the eye at 1.0 was neutral and is not shipped.

## Risks

- **Pacing**: NORMAL is the shipped CPU, so the medians are the baseline's: LR 216.2 (cap 240), LI 203.9 (cap 240), LS 196.8
  (cap 220). LR is within 24 s of its cap, LS within 24 s; none within 15 s. Inherited, not introduced.
- **NORMAL / EASY never see the layer.** The user's layering is met at its minimum (EASY = NORMAL ≤ HARD). A partial NORMAL
  version would show his style more but would need its own drift measure (the HARD layer turns 0.12 into 0.97).
- **HARD may be too strong for a human.** The snap (f9 materialise) and the HOSHA loop (bullets → K1 → stance → HOSHA, ended
  by the combo's scaling, a Burst or the push) are combos a human can do too; at HARD the CPU now plays them as its neutral.
  The wary read narrows the snap to committed opponents against a player who learns to step on it.
- **The ASSIST**: the new `:sp-ender` runs for an assisted human (AI-BRAIN, HARD): string enders cash out SP2 when the bars
  are there. `tools/assistgate.py` should be re-run at integration.
- **Overfitting**: measured only against the frozen CPUs. The snap works because no CPU reads EN's J1 as a threat beyond its
  1.6 m reach; HOSHA works because its S6 is under a HARD CPU's perception + guard raise.
- The awaken A/B was not run: the awakening and the revival are untouched, and the A/B runs at NORMAL, where this CPU is the
  shipped one bit for bit (the drift's 400 NORMAL matches are identical).

## Shared-code recommendations (not done)

1. The generic non-red O ender (`:o-ender`, ai.lisp's first reflex) is perfect-Hoho'd by HARD CPUs and countered (~57
   damage a match against him, the top single source of counters he takes); a per-difficulty `:o-ender` would let a HARD
   layer drop it without moving NORMAL.
2. AI-ATTACK's no-whiff reach filter makes any kit's "J / K that lays rather than hits" dead in `:moves` (v1's finding,
   still true): a per-move flag would let EN's own table mean what it says at NORMAL.
3. ORANGE's chain restart (`AI-CHAIN-FOLLOW-P`, a plain J1 string) is now his largest non-signature source (~165 a match):
   a kit hook for the restart command would let a character restart into its own route.

## Host tests

duel-rules 6373 ALL PASS (the section: +3 checks: the levels 0 / 0 / 1 and no brain → 0, the knobs' values, the web's band
inside TENSHIN in's reach, `:sp-ender` on base / KIN only, the volley and wary functions, J2's line inside the volley's 14 f);
duel-control 89, learn 100 ALL PASS; `tools/pkgcheck.sh duel` 0 / 0 / 0.
