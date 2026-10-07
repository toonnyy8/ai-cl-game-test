# b1a1 (round 1, refines b1a0, freeze 1a7f135 / decision 47): the sniper's discipline at HARD — no rush into a rush, a charged shot on the wake-up, a web that waits out a guard

A refine of **b1a0** (rescored 0.9586 at this freeze; my own run of its port gave the same JSON). Only
`duel/lisp/lille.lisp` changed, and only his CPU:
- new knobs and `LB-AI-*` functions in a new block at the end of b1a0's HARD layer: `*LB-AI-SIEGE*`, `*LB-AI-KIN-EXIT*` /
  `LB-AI-KIN-EXIT`, `*LB-AI-RUSH-WARY*` / `LB-AI-RUSH-P`, `*LB-AI-COMPOSURE*` / `-F*` / `LB-AI-COMPOSURE`, `*LB-AI-OKI*` /
  `LB-WAKE-LEFT` / `LB-AI-OKI-LEAD` / `LB-AI-OKI-SHOT` / `LB-AI-OKI-STANCE-P`, one `LBAI` field (`oki`);
- b1a0's own functions: `LB-AI-REFLEX` (base: the wake-up shot between the eye and the hunt), `LB-AI-HUNT` (the rush
  test), `LB-AI-WEB-LAY` (the guard test), `LB-AI-KAMAE` (the wake-up plan, the composure), `LB-AI-LINK` (no K1 into the
  air), `LB-AI-EXIT-CMD` (KIN's exits); one knob value, `*LB-AI-HUNT-BAND*` (2.5 7.5) → (0.0 7.5).

No frame data, damage, cost, rule, human branch, opponent-facing key (`:opp-trace :opp-reflex :opp-reflect :opp-aim`),
`LB-OPP-TRACE` or other file changed. `AI-AWAKEN-P` / `:awaken` and the `:bankai` revival are untouched; no new kit key the
ASSIST calls (`:sp-ender` is b1a0's). Every new behaviour is a level `(:easy 0 :normal 0 :hard 1)` tested first: EASY and
NORMAL take the shipped branches and draw the shipped random numbers (drift and pacing byte-identical to the baseline);
HARD runs deterministic rules on what it perceives (no new roll anywhere).

**Score 0.9937** = strength **0.998**, masher 1.000, signature **0.987** (b1a0 at this freeze: 0.9586 = 0.973 / 1.000 /
0.924; baseline 0.4449).

## 1. The history read

| cell (rescored at 1a7f135) | score | mechanism | what I took / what it meant here |
|---|---|---|---|
| baseline | 0.4449 | the shipped CPU | HARD 0.095; EN's `:moves` never fire at range |
| v1 b0a0 / b1a0 (old rules) | (0.91 / 0.90) | the snipe / snap opener (rode the laying shot's flinch, gone) | re-derived by every round-1 cell on the 2 f cancel's timing |
| b0a0 | 0.9548 | EN mark + spring, KIN vanish, base hunt from 0 m, the HOSHA → K1 → L loop | its hunt from 0 m (a knob value) |
| **b1a0 (parent)** | **0.9586** | EN web (convergence count), KIN hit-and-run, the hunt 2.5–7.5 m and the loop, SP2 cash-out | the engines, kept as they are |
| b2a0 | 0.9945 | both openers + **composure** (J held through HOSHA: no generic ORANGE), oki HOSHA, KIN route, pendulum, siege, vanish | composure (credited; not one of b3a0's pieces) |
| b3a0 | 0.9883 | b1a0's engines + spacing rule (TAISHA / dash in ORANGE's window), crossfire, enders, refusals (no Breaker, no non-red O over a combo) | none of it: the coordinator asked for something different |

My diagnostic of b1a0's port (the evaluator's strength runs, seeds 1–40, the logs read move by move: `scratchpad/lille-b1a1/
diag.py`, `summ.py`, not delivered) reproduced the JSON (389 / 400, signature 0.924) and located its leaks:
1. **ORANGE** off a re-HOSHA at 0.8 m (K1's chase leaves him there): 2.0 a match, its plain J restart **183** damage a match
   of the 323 plain. Both b2a0 and b3a0 closed it; b3a0's way (spacing) is barred here, so I take b2a0's composure.
2. **A bug in b1a0's hunt** (new finding): it hunts any perceived `:move`, *including his Kikon / Breaker rush in its aura,
   dash or follow-up*, and the kit's reflex runs **before** the generic answers to a rush (guard it, Step a red one's
   follow-up, J into a Breaker). The stance (TAISHA up close) ate the follow-up: **185 of the 200** Kikons / Soul Breaks he
   took in the base form (40 seeds) came right after a hunt's TAISHA; in my later 80-seed runs every lost match had one.
3. **A gap in b1a0's web** (new finding): it refuses to lay at a guarding opponent, and Yamamoto's Bankai West ward is
   *always* seen as a guard (SNAP-TAKE!). EN then sits idle and the generic Breaker fires into it (J beats I): vs Yamamoto
   1.6 Breakers a match, ~340 damage taken a match in the 2 s after them.
4. **The wake-up** (new axis for this lineage): after the HOSHA loop blows him away, b1a0's HOSHA link still K1s into the
   air (whiff, 42 f), and the generic step-in J1 meets his wake-up (Kenpachi's first strike, 0.84 step-ins a match into a
   waking opponent): the base form's plain string and the trades.
5. **KIN's MUJITTAI exit** (his own code, `LB-AI-EXIT-CMD`): a wing-blade J1 / K1 string, ~30 plain a match.

## 2. The action policy (HARD; EASY and NORMAL are the shipped CPU bit for bit)

**Base 万物貫通 — the hunter who never rushes into a rush, and the sight on the wake-up.**
- b1a0's hunt (the stance → HOSHA → K1 → L → HOSHA … loop), now **from 0 m** (b0a0's band), and **never into his rush**
  (`LB-AI-RUSH-P`: a Kikon / Breaker in aura, dash or follow-up): the generic guard / Step / J answers it as for every CPU.
- **The composure** (b2a0's mechanism): when the stance's plan is HOSHA, J (inert in HOSHA) is held 18 f, through the last
  bullet (f14–16) and the link (f16), so no generic reflex runs on a bullet's hit: no ORANGE turns the loop into a plain
  string (ORANGE 2.0 → 0.2 a match).
- **The wake-up shot 起き照準 (new)**: a downed / waking opponent (`LB-WAKE-LEFT`: down 30 + wake-up 30, less his frame and
  the perception delay) gets **the fully charged X-Axis shot timed to fire on his first hittable frame** — the stance pressed
  40 f before it (`LB-AI-OKI-LEAD` = the stance up 6 + the charge 24 + the shot's startup 10; host-pinned), its plan forced
  to `:charge` (`LB-AI-OKI-STANCE-P`), fired from wherever he stands (the line is 31 m, the damage grows with range, a
  through-guard drain if he guards). While waiting, and when it is too late for a charge, he stands off (`:NONE`: no step-in
  into his wake-up; nothing of his can hit while he is down). To make the window, HOSHA's link skips the K1 into a
  blown-away opponent (`LB-AI-LINK`: `:none` when he is `:air` / `:down`), so HOSHA recovers (R 16) while he flies.
  4.1 wake-up shots a match; 4.9 charged shots fired a match in all, 4.5 shot hits (the charged share of his damage 0.5 %
  → 4.9 %).
- The rest of b1a0's base CPU (the eye first, the stance's other branches, the SP2 cash-out) unchanged.

**Jilliel / owl 遠 EN — the patient web (new).** b1a0's web (a J line every 6 f at 2.5–13 m, TENSHIN's 2 f cancel when its
hit groups would hit where he will be) now also lays at a guarding or warding opponent (`*LB-AI-SIEGE*`); its switch still
refuses a guard, so the lines wait: the moment the guard drops (to attack or step), the converged lines materialise. EN no
longer stands idle in front of a ward and hands the decision to the generic Breaker.

**Jilliel / owl 近 KIN — signature exits (new, his own `LB-AI-EXIT-CMD`).** MUJITTAI is left on his whiff / recovery by
**SP1** (SANREN's three through-guard lines; the owl's 裁きの光明) when he stays busy for its startup, else by **TENSHIN out**
back to EN's lines; the wing-blade string only when neither can start. b1a0's hit-and-run, starve rule and SP2 cash-out
unchanged.

**Unchanged**: MUJITTAI's entry, the eye, Trompete, the owl's CPU beyond the exits, the awakening, the revival, every debug
mode (79000–79999), the `duel lille` counters (new keys: `ai-composure`, `ai-oki-shot`).

**Adaptation**, once per event, no roll: the rush test reads his perceived move's kind and phase; the wake-up shot reads
his perceived down / wake-up frame; the link reads his state at its frame; the web reads his guard; KIN's exit reads his
perceived recovery. b1a0's wary read (after two missed web switches, only a committed opponent) stays.

## 3. Measurement

**EVAL_COMMAND** (40 seeds, frozen evaluator; `score.json` is the last line it printed for the delivered file):

| | baseline | b1a0 (parent) | **b1a1** |
|---|---|---|---|
| score | 0.4449 | 0.9586 | **0.9937** |
| strength (HARD, both seats) | 0.095 | 0.973 | **0.998** (399 / 400) |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.517 | 0.924 | **0.987** |
| drift (NORMAL share) | 0.44 | 0.44 | **0.44** (Y 44, K 28, R 31, I 35, S 38 of 80: identical) |
| pacing Y / K / R / I / S (s) | 174.2 / 169.2 / 198.1 / 209.0 / 194.7 | identical | identical, all 40 / 40 K.O. |

`sig_by` b1a0 → b1a1: HOSHA bullets 0.251 → **0.352**, HOSHA links 0.213 → **0.297**, trace combos 0.249 → 0.153, traces
0.084 → 0.052, **charged shot 0.005 → 0.049**, Jilliel Kikon 0.048 → 0.032, NIJŪSHI-KŌ 0.045 → 0.030, TAISHA 0.007 → 0.015,
SANREN 0.002 → 0.005, **plain J / K 0.070 → 0.010**, Breaker 0.004 → 0.002. (The base form wins sooner, so less of the match
is Jilliel's.)

HARD per match (my diagnostic, the same sims, seeds 1–40): dealt 4600 → 4478, **taken 1164 → 691**; Kikons / Soul Breaks
on him 1.07 → 0.23 a match; ORANGE 2.02 → 0.20.

**The path** (diagnostic wins of 400 at seeds 1–40, signature; held-out seeds 41–80 where run; each a rebuild):

| step (cumulative) | wins | signature | taken / match | |
|---|---|---|---|---|
| b1a0's port | 389 | 0.924 | 1164 | full eval 0.9586 |
| + composure | 388 | 0.957 | 1038 | ORANGE 2.0 → 0.4 |
| + hunt from 0 m | 393 | 0.966 | 970 | |
| + patient web | 392 / 391 | 0.967 / 0.967 | 880 | Yamamoto 78 → 80 |
| + wake-up shot, from free only | 392 | 0.967 | 878 | fired 0.01 a match: the loop's K1 into the air kept him busy through the down time |
| + no K1 into the air, + a TAISHA meaty when the charge is late | 392 | 0.978 | **1043** | **dropped**: HARD CPUs perfect-Hoho the TAISHA meaty (they see its 22 f startup; Ichigo: COUNTER 42 → 174 a match) |
| charged shot only (the TAISHA fallback removed) | 397 / 396 | 0.985 / 0.982 | 746 | full eval 0.9911 |
| + KIN's signature exits | 397 / 396 | 0.988 / 0.985 | 759 | |
| + stand off a late wake-up (no step-in) | 395 / 398 | 0.989 / 0.990 | 673 | full eval 0.9905 |
| **+ the rush-wary hunt (final)** | **399 / 399** | **0.987 / 0.990** | **691** | full eval **0.9937**; base Kikons on him 277 → 33 in 800 |

**Ablations of the final file** (80 seeds: 1–40 / 41–80, one piece off at a time):

| off | wins of 800 | signature | taken / match |
|---|---|---|---|
| none (final) | **798** | 0.987 / 0.990 | 691 / 744 |
| composure | 798 | **0.941 / 0.944** | 878 / 881 |
| patient web | 797 | 0.988 / 0.990 | 787 / 803 |
| wake-up shot (+ its link rule) | 797 | **0.973 / 0.972** | 943 / 944 |
| KIN's exits | 800 | 0.984 / 0.987 | 695 / 723 |
| rush-wary hunt | **793** | 0.989 / 0.990 | 673 / 727 |
| hunt band 2.5–7.5 (b1a0's) | 799 | **0.981 / 0.982** | 715 / 716 |

Read: the composure is the signature's biggest piece (+0.045), the wake-up shot the next (+0.016 and −25 % damage taken),
the rush fix the wins (+5 of 800), the hunt from 0 m +0.006 signature; the patient web and KIN's exits are within ±3 wins
and ±0.003 signature (the web: −10 % damage taken; the exits: more of his own damage). All kept: none costs score
beyond the noise, and each is the in-character answer to a located behaviour.

Host tests: duel-rules **6376** ALL PASS (the LILLE-CPU-TESTS section: b1a0's 3 checks with the hunt band's pin updated to
(0.0 7.5), + 3 new: the four new levels 0 / 0 / 1 and no brain → 0, the composure covering HOSHA's last bullet and link;
`LB-WAKE-LEFT` and the wake-up lead 40 fitting a down seen at HARD's delay, before the stance's tap ends; KIN's SP1 / L
moves; nothing outside the markers changed, checked with `splice-tests.py` into the frozen file: identical), duel-control
89, learn 100 ALL PASS; `tools/pkgcheck.sh duel` 0 / 0 / 0. The awaken A/B was not run: the awakening and the revival are
untouched and the A/B runs at NORMAL, where this CPU is the shipped one bit for bit (the drift's 400 NORMAL matches are
identical).

## 4. Why it is not a repeat

- **The rush-wary hunt** fixes a bug located in b1a0's own hunt (it preempted the generic anti-rush answers), measured by
  where his Kikons come from (185 / 200 in the parent, 244 / 277 after my other changes, 33 / 800 matches after the fix).
  No cell reported it.
- **The wake-up shot** is a new okizeme: the charged X-Axis shot (the sniper's own tool, whitelisted as `charged`) timed on
  the first hittable frame from range, and the link rule that makes its window. b2a0's oki is HOSHA from close; I measured
  the close meaty (TAISHA) as a negative result (perfect-Hoho'd by HARD CPUs) and dropped it.
- **The patient web** fixes a located gap in b1a0's web (silent on a guard / ward → the generic Breaker).
- **KIN's exits** change his own MUJITTAI exit, which no cell touched.
- Credited, not new: the composure (b2a0) — the only in-kit ORANGE fix besides b3a0's spacing, which this cell may not
  reuse; it is what moved the signature 0.924 → 0.957 — and b0a0's hunt band value.
- Different from b3a0 by construction: no spacing rule, no crossfire, no enders, no refusals (the Breaker and the O ender
  still go through the generic code; the patient web removes most of EN's Breakers by giving EN something to do).

## 5. Expected benefit

At HARD he plays the hunter's HOSHA loop up close without bursting out of it, retreats to his sight when the opponent is
down and fires the charged X-Axis shot on the wake-up, lets the generic defence take his rushes, and keeps the web laid
against a turtle until it moves. 99.8 % of HARD CPU matches won, 98.7 % of his damage his signature, damage taken −41 % vs
b1a0. EASY and NORMAL unchanged.

## 6. Risks

- **Pacing**: NORMAL is the shipped CPU, so the medians are the baseline's: LI 209.0 (cap 240), LR 198.1 (cap 240), LS 194.7
  (cap 220); none within 15 s of its cap.
- **The composure is a pad trick** (b2a0's risk, inherited): 18 f of held J silence every generic reflex during HOSHA
  (guard-cancel, ORANGE, the chain restart). His own BLUE still runs (before the press branch in BRAIN-STEP).
- **The wake-up shot vs a human**: the lock is visible ≥ 10 f before the shot (decision 12), so a human can wake up with a
  Step / Hoho or a guard (it then drains 30 and chips 15 %). While he waits (≤ 60 f) he stands still (`:NONE`), so AI-DECIDE's
  neutral (and a learning CPU's neutral window) is paused for that time; the learner's read still runs (it is before the kit
  reflex). A HARD CPU that wakes with a buffered Hoho would perfect-Hoho it (none of the frozen ones does against the
  charged shot: 4.5 hits of 4.9 a match).
- **HARD may be too strong for a human** (inherited: the 9 f materialise, the HOSHA loop).
- **The ASSIST**: no new hook it calls; every new branch reads `(brain e)` or the reflex's own brain (the ASSIST calls only
  `:assist-guard`, which Lille has none of, and b1a0's `:sp-ender`). Re-run `tools/assistgate.py` at integration for b1a0's
  `:sp-ender` as before.
- **Overfitting**: measured only against the frozen CPUs; the held-out seeds 41–80 agree (399 / 400, signature 0.990).

## 7. Shared-code recommendations (not done)

1. An ORANGE kit key (`:orange` by difficulty) so the composure's held J can go (b0a0 / b2a0 / b3a0's recommendation too).
2. AI-REFLEX: a kit's `:reflex` runs before the generic anti-rush answers; a kit that attacks "a perceived move" can preempt
   them. A shared `snap-rush-p` (or running the anti-rush clause before the kit's reflex) would protect every kit.
3. A wake-up field in the SNAP (frames to his first hittable frame), so kits time okizeme without re-deriving
   `*REACTION-FRAMES*` (b2a0's recommendation 3).
