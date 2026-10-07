# b1a0 (round 1): the sniper's hit-and-run, a HARD-only layer

Cell b1a0, round 1, new direction from the baseline (no parent). The only file changed is `duel/lisp/lille.lisp`, and only
his CPU's code: the AI section (new `*LB-AI-...*` knobs and `LB-AI-*` functions, changes to `LB-AI-REFLEX`, `LB-AI-EYE`,
`LB-AI-EN`, `LB-AI-KIN`, `LB-AI-LINK`, and the `LBAI` struct) plus the `(brain e)` branches of `LB-EN-TICK` (the cancel)
and `LB-KAMAE-TICK` (inside `LB-AI-KAMAE`). No `:ai` table key changed, and no rule, frame, damage, cost, opponent key or
shared file changed. The test section between the LILLE-CPU-TESTS markers gains two checks (6369 → 6371 ALL PASS).

## Result (frozen evaluator, 40 seeds)

| | score | strength | masher | signature | drift (NORMAL share) | pacing |
|---|---|---|---|---|---|---|
| baseline | 0.4769 | 0.140 | 1.000 | 0.552 | 0.4275 | LY 175.0 / LK 176.0 / LR 223.5 / LI 217.1 / LS 205.3 |
| **b1a0** | **0.9027** | **0.932** | 1.000 | **0.824** | **0.4275** (identical) | identical: 175.0 / 176.0 / 223.5 / 217.1 / 205.3, all K.O. |

`sig_by`, baseline → b1a0: trace-combo 0.194 → **0.387**, plain J / K 0.370 → **0.152**, traces 0.138 → 0.142, HOSHA
bullets 0.025 → **0.092**, HOSHA links 0.018 → **0.064**, Jilliel Kikon 0.060 → 0.067, NIJUSHI-KO 0.020 → 0.025, Breaker
0.036 → 0.007, quick shot 0.010 → 0.017, the owl's Kikon 0.040 → 0.009 (he rarely reaches the owl now).

The drift and the pacing medians are bit-identical to the baseline's. Every new behaviour has the level 0 at EASY and
NORMAL, and it is checked before any roll, so NORMAL draws exactly the same random numbers as the shipped CPU.

## Why the baseline loses at HARD (the history, and what I measured)

There is no earlier cell to learn from: round 1, with b0a0 running in parallel. The baseline's HARD strength is 0.14
while its NORMAL share is 0.43. The other five CPUs got HARD-only layers in the AI v2 search (Kenpachi's and Rukia's HARD
chances of 0.8–0.95, for example), and Lille has none. I ran 20 seeds of HARD, both seats, with the combat log and the
`duel lille` counters (`/tmp/claude-0/drsi-r1-b1a0/diag.py`, scratch, not delivered):

- **KIN's neutral is where he bleeds.** He takes 22–32 damage a second in KIN against 8–21 in EN. A KIN K1, SANREN or
  Breaker thrown in neutral is perfect-Hoho'd by a HARD Ichigo or Kenpachi, and their counter plus string costs 300 or
  more.
- **The starved switch-in** (`SWITCH-STARVED`: EN without a J line above the reserve switches in for free) puts him in
  KIN beside the opponent with no traces and less than 29 flash step. That is under the out rule's minimum, so he is
  stuck in KIN's neutral.
- **EN almost never opens anything by itself.** The switch rule needs 3 or more live traces with the opponent on one.
  HARD opponents step off seen traces 83 % of the time (`:opp-trace` 0.5 × 1.667), so he lays line after line and gets
  hit while he walks.
- **The base form loses its exchanges.** The ratio of damage dealt to damage taken was 0.3–1.2, and against Kenpachi
  0.29.

## The action policy (HARD; EASY and NORMAL are the shipped CPU)

The idea is a sniper who never fights in melee. Every visit to melee is a combo he has already confirmed, and he leaves
as soon as it ends.

**Base 万物貫通.** The eye still answers threats first (`LB-AI-EYE`; at HARD its chance is at least 1.0 through
`*LB-AI-EYE-P*`, so the three openings bring EVOLUTION as soon as they can). Then comes **the base snap**
(`LB-AI-HOSHA`): when he perceives the opponent at 3–7 m (`*LB-AI-HOSHA-RANGE*`) standing, walking, running, in a move
or reeling (not guarding, stepping, in a Hoho or down), he takes the shooting stance, and its branch at f6 is HOSHA
(`LB-AI-KAMAE`: the leap's 5 m plus the bullets' 3 m reach him). This also applies to the stance entered after a K
link's hit when the opponent reels at 2–8 m and isn't guarding. A bullet's hit links J1 or K1 on the shipped 50 / 50 roll.
I tried J1 always and K1 always, and both were worse (below). Far range keeps the shipped plan: the charged shot from
8 m, the dash back at 6–8 m.

**Jilliel / owl 遠 EN: the snap shot** (`LB-AI-SNAP-P`, `LB-AI-SNAP-CANCEL-P`). When he perceives the opponent at
2–9 m (`*LB-AI-SNAP-RANGE*`) standing, walking, running, in a move or reeling, and a J line is affordable above the
reserve, he presses J1. Its line is laid straight at the opponent, and the laying shot (decision 39, a 10 f flinch)
fires along it on J1's first active frame. The EN tick then cancels J1 from its active end into TENSHIN's 2 f wind-up,
whatever the live traces are, and the line materialises on the flinched opponent: 30 damage and a 26 f stagger. The dash
follows and the KIN J1 link fires (`LB-AI-LINK-PLAN`'s trace-hit rule, unchanged), giving trace → TENSHIN → J / K → O.
The line is younger than the opponent's perception delay when it materialises (9 f against HARD's 8 f, and it has to be
seen first), so `LB-OPP-TRACE` never gets to roll on it. Measured: 10–24 snaps a match, of which 0.7–2.0 miss.
- **The adaptive part** (`*LB-AI-SNAP-WARY*` 2): `LB-AI-LINK` records each snap's result, whether the trace hit or
  missed. After 2 misses in a row he snaps only at a committed opponent (running, in a move or reeling) until one lands
  again. This is one decision per event, about what the opponent did, with no roll needed.
- The rest of EN is unchanged: the switch rule, the via-J switch, the stance reflex. The **starved switch-in** now fires
  at HARD only onto an opponent who is busy for the 16 f wind-up, because KIN is never entered into neutral.

**Jilliel / owl 近 KIN: the hit-and-run** (`LB-AI-KIN-RUN-P`, `*LB-AI-RUN*`). KIN is only the vehicle for the combo.
Whenever he is free in KIN, TENSHIN out can start (its 10 flash-step price, not the old 29), and there is nothing to
cash in (`LB-AI-PUNISH-P`: the opponent reeling or recovering within J1's reach for its startup, or a red opponent
reeling within the Kikon range, which the generic reflexes take), he switches out at once. The string itself, its O
ender and the trace combo's links are the shipped generic ones.

**MUJITTAI, Trompete, the awakening and the revival** are unchanged. The awakening is still `AI-AWAKEN-P` (the eye's
third opening only fills the gauge, as before), and the revival is the generic `:bankai` reflex. I didn't touch them, so
I didn't run the awaken A/B: it runs at NORMAL, where nothing changed.

## How each piece did (HARD, 20 seeds × 5 opponents × 2 seats = 200 matches; my scratch diagnostic, the same sims)

| Step | Lille wins / 200 | Signature | Kept |
|---|---|---|---|
| baseline | 30 | 0.548 | |
| + KIN hit-and-run, no starved switch-in at HARD | 39 | 0.731 | yes |
| + EN snap shot (2–9 m) | 175 | 0.872 | yes (full eval: 0.8978 = 0.868 / 1.0 / 0.877) |
| + base snap (HOSHA at 3–7 m; HOSHA after a K link's hit) | 187 | 0.825 | yes (full eval: 0.9027) |
| HOSHA's link always K1 (the K1 → L → HOSHA loop) | 169 | 0.851 | no (score down) |
| HOSHA's link always J1 | 178 | 0.805 | no |
| snap range 1.5–10 m / 2.5–9 m | 181 / 183 | 0.825 / 0.820 | no (noise: kept 2–9) |
| the eye's chance 1.0 at HARD | 187 | 0.823 | yes (neutral; the eye is rarely ready) |
| the wary rule (adaptive) | 186 | 0.822 | yes (neutral against fixed CPUs; it matters against a human who learns to step) |

Per opponent at the end (of 40 each): Yamamoto 36, Kenpachi 38, Rukia 40, Ichigo 32, Senjumaru 40. Time per match: base
37–45 s, EN 24–41 s, KIN 32–61 s, the owl 3–15 s (the revival is now rare: he wins first).

## Why it is not a repeat

There is no history to repeat. Against the baseline, the change is structural rather than a retuned knob. EN now opens
with one line laid on the opponent and materialised at once, instead of a trace web, which the HARD opponents' trace
reflex was built to dodge. KIN is never neutral. The base form gets a committed HOSHA opener.

## Risks

- **This is a kit-level discovery, not only a CPU one.** J1 in EN, then L on J1's active end, is a near-unreactable
  opener for a human too: the laying shot flinches on f4 and the line materialises at f9. Decision 39 (the 10 f flinch)
  plus decision 30's 2 f cancel make it so. At HARD the CPU now plays it as its neutral. If the user finds it degenerate,
  the fix is a rule (the laying shot not flinching, or the 2 f cancel not materialising a line younger than N f), not this
  CPU. I'm recording it for the coordinator and the user.
- **Pacing**: unchanged, because NORMAL is unchanged. LR 223.5 s and LI 217.1 s stay within 15 s of their caps (240):
  inherited from the baseline, not introduced here. LS 205.3 is within 15 s of 220 (the same).
- **The learning CPU**: at HARD in EN the snap shot answers whenever its conditions hold (it is a deterministic rule on
  what he sees, like the shipped switch rule). The learner's own read (`LEARN-READ-DUE`) runs before the kit's reflex, so
  it isn't starved. The bandit in `AI-ATTACK` sees fewer EN neutral picks at HARD.
- **The ASSIST**: no kit hook the ASSIST calls was added or changed. Every new branch runs through `(brain e)` in the
  sim's ticks or through the reflex's own brain argument, so it never acts for a human.
- **Search noise**: 20-seed diagnostics move ±6 wins of 200. The two big steps (39 → 175 → 187) are far outside that,
  and the rejected variants were within or below it.
- **Against "new" opponents**: the snap shot works because no CPU reads a line younger than its delay. An opponent CPU
  that guarded or stepped EN's J1 on sight (a shared change) would cut it back. The wary rule then narrows it to committed
  opponents.

## Recommendations for shared code (not done here)

1. The non-red O ender (`:o-ender`, the generic string reflex) feeds Ichigo's KESSA parry: the follow-up is parried and
   GAESHI punishes it for about 190 damage a match in KIN. A generic rule, "no non-red O ender against an opponent whose
   kit has a parry", or a per-difficulty `:o-ender`, would help every character's CPU.
2. The kits' `:ai` keys read by the generic code (`:o-ender`, `:l-after-k`, `:moves`) have no difficulty dimension. A
   per-difficulty plist form (`(:easy .. :normal .. :hard ..)` accepted wherever a number is) would let a HARD layer
   change them without moving NORMAL.
3. The laying-shot opener above is a balance question for the user.
