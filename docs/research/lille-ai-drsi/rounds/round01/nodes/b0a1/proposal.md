# b0a1 (round 1, refining b0a0, at the freeze 1a7f135): the hunter who reads — no leap into a rush, hands off a downed man, no Breaker

A refine of b0a0 (rescored 0.9548 at this freeze). It keeps b0a0's engines: the EN mark → 2 f spring → trace combo, the
KIN vanish and the base HOSHA hunt and loop. It fixes four leaks I located in b0a0's own logs, two of them with fixes no
cell had. It borrows one located fix from b2a0, credited. Only `duel/lisp/lille.lisp` changed, and only his CPU:
- the base form's `:hunt` key gains `:oki 8.0`;
- new knobs `*LB-AI-COMPOSURE*` and `*LB-AI-OKI-HOSHA*`;
- new functions `LB-AI-ATTACKING-P`, `LB-AI-HARD-P`, `LB-AI-TURTLE`, `LB-AI-COMPOSURE`, `LB-WAKE-LEFT`, `LB-AI-OKI-PLAN`
  and `LB-AI-OKI`;
- edits to `LB-AI-HUNT-PLAN` (two optional arguments), `LB-AI-HUNT`, `LB-AI-REFLEX`, `LB-AI-KIN` and `LB-AI-EXIT-CMD`;
- in the sim's ticks, `LB-AI-KAMAE` (the stance's CPU plan) and `LILLE-OK`'s `(brain e)` clause.

Nothing else changed: no frame data, damage, cost, rule, human branch, opponent-facing key (`:opp-trace :opp-reflex
:opp-reflect :opp-aim`), `LB-OPP-TRACE` or other file. The awakening (`AI-AWAKEN-P`, `:awaken`) and the revival (the
generic `:bankai` reflex) are untouched. No new hook the ASSIST calls (no `:sp-ender`, `:sig-hold` or `:assist-guard`).

Every new branch sits behind the forms' existing HARD level (`:by (:easy 0 :normal 0 :hard 1)`), so EASY and NORMAL
are the shipped CPU bit for bit: the drift and the pacing JSON are identical to the baseline's. There is no new roll at
all: every new rule is deterministic on what the CPU perceives, read once per event.

**Score 0.9957** = strength **0.998** (399 / 400), masher 1.000, signature **0.992**. For comparison:
- parent b0a0: 0.9548 = 0.958 / 1.000 / 0.930;
- b2a0 (best of the round): 0.9945 = 1.000 / 1.000 / 0.986;
- baseline: 0.4449.

## 1. The history read

| cell | rescored | mechanism | what it meant for this refine |
|---|---|---|---|
| baseline | 0.4449 | the shipped CPU | NORMAL drift 0.44; HARD has no layer |
| archive v1 b0a0 / b1a0 | (old rules) | the snipe / snap opener on the laying shot's flinch; base HOSHA hunt; SP2 cash-out; KIN back-switch | the opener's real cause was the 2 f cancel's timing (round 1 re-derived it); "HOSHA's link always K1" failed only for want of the L latch |
| **b0a0 (parent)** | 0.9548 | EN mark + 2 f spring; KIN vanish; base hunt → HOSHA; K1 + L latched loop | sound engines. Its own recommendation #1 named the ORANGE leak but left it to shared code |
| b1a0 | 0.9586 | EN web (convergence count), KIN hit-and-run, the same loop, SP2 cash-out | the same plateau ~0.95; volley 2 a trap, the wary read inert vs CPUs |
| b2a0 | 0.9945 | + **composure** (J held through HOSHA: no ORANGE), oki HOSHA / oki mark, KIN J1-K2s-K3 route, K3 exits, pendulum, siege | the ORANGE fix inside the kit; oki measured as −40 % damage taken |
| b3a0 | 0.9883 | b1a0's engines + spacing rule (HOSHA outside ORANGE's window), crossfire, combo enders, refusals (no Breaker / O ender via LILLE-OK) | a second ORANGE fix; Breaker and O ender located as losers vs HARD CPUs |

I trusted the rescored numbers and re-measured the parent here: 0.9548, the same JSON. Then I read **the parent's own
logs**. A scratch diagnostic ran the evaluator's HARD strength sims with the combat log and broke down:
- every non-signature hit by its string's origin;
- every hit he took by his last move;
- every HOSHA the hunt fired by its outcome.

At 20 seeds the parent goes 194 / 200, signature 0.928, taken 1232 a match. The leaks, largest first:

1. **ORANGE off a HOSHA bullet** (the history's known leak): plain base strings after his own CHAIN REVERSE.
2. **The hunt leaps into his attack and his Kikon rush** (new; no cell found it). `LB-AI-OPEN-P` takes any perceived
   `:move` as open. A Kikon / Breaker rush's aura and dash are no main phase, so they are no threat to
   `LB-AI-THREAT-P` either. The hunt took the stance (6 f, no defence) and HOSHA (6 f more, no iframes) into his rush.
   In 30 parent matches:
   - 41 of the opponents' 80 Kikon hits on him came right after a hunt's HOSHA;
   - so did **21 of the 32 Konpaku he lost**;
   - a "got hit before the bullet" HOSHA cost ~85 damage each, ~116 a match.
3. **The oki was the generic step-in J string.** After a blow-away (9.5 a match), AI-DECIDE's STEP-IN → J1 STEP-J met
   his wake-up with a plain J1-J2-J3 (+ a non-red O ender). This was the largest plain source once ORANGE was gone:
   61.5 non-signature damage a match had a `LB-J1:STEP-J` origin.
4. **The Breaker** (the generic guard-break and anti-parry reflexes): HARD CPUs beat it with J. It cost ~110 damage a
   match taken after it, and its string is no signature.
5. Smaller: the stance's shipped plan still threw the quick shot (not his signature) on a whiff; KIN's MUJITTAI left by
   a plain J1 / K1.

## 2. The action policy (HARD; EASY / NORMAL = shipped)

**Base 万物貫通: the hunter who reads.**
- **The hunt reads his attack** (new; `LB-AI-ATTACKING-P`). The stance is taken only onto a perceived *free*
  opponent: idle, walking, running, reeling, or in his move's recovery (a whiff to punish). Never onto an attack before
  its active end, a rush (aura / dash / follow-up), or a projectile of his in flight. Otherwise the hunt yields, and the
  eye and the generic anti-rush answers (guard a rush when not red, Hoho, Step) take the event.
- **The read at f6, the evade** (new; `LB-AI-HUNT-PLAN`'s `:evade`). If his attack or rush is seen when the stance
  comes up, the plan is the stance's HIRENKYAKU dash: iframes f0-8, 3.5 m straight back, flash step 10, once a stance.
  HOSHA is not leapt into it. The stance re-enters at f6 and plans again, so HOSHA lands on his whiff, or the charged
  shot follows from range.
- **The charged shot, never the quick one** (new, small). Where the shipped plan would throw the quick shot (not his
  signature), HARD waits for the charge.
- **The composure** (b2a0's fix, borrowed and credited). J is held 18 f from HOSHA's start, an inert press, so no
  generic reflex runs on the bullets' hits: no ORANGE and no plain restart.
- **The okizeme, hands off till the frame** (the timing is b2a0's; the hands-off is new: `LB-AI-OKI-PLAN`'s
  `:wait`). On a perceived down / waking opponent within 8 m:
  - the stance is pressed 12..9 frames before his first hittable frame (down 30 + wake-up 30, less his frame and the
    perception delay), so HOSHA's first bullet lands on it;
  - until that frame the reflex answers `:NONE`. b2a0 returned NIL there, which let the generic step-in J string reach
    his wake-up first.
  - The blow-away's own latched K1 link chases him, so he is always within 8 m when he lands. A charged-shot oki
    beyond 8 m was built and then removed: it never fired against the CPUs in 30 forced matches.
- **The turtle** (new answers; `LB-AI-TURTLE`). His long guard up close (the generic guard-break's own event, taken
  over once per guard through `BRAIN-BREAK-KEY`, as Senjumaru's kit does) gets the stance. Its f6 plan is TAISHA: the
  3 m back-slide, then the X-axis bullet through guard (chip 15 %, drain 30), ending at range for the next hunt. A parry
  up close gets nothing fed to it (`:NONE`).
- **No Breaker at HARD** (`LILLE-OK`'s CPU clause; b3a0 refused it the same way). With the turtle consuming the
  generic events, the refusal only stops the neutral `:moves` picks of the Breaker, and AI-ATTACK checks `:ok` there. So
  no Breaker press is ever left hanging on the pad.
- As b0a0: the loop (HOSHA → K1, L latched → the stance at f4 → HOSHA ...), and the eye first.

**Jilliel / owl 遠 EN** (as b0a0). The mark (J1 laid straight at a free opponent at 1.5–13.5 m, above the reserve) and
the 2 f spring (the materialise 9 f after the press) → TENSHIN in → KIN J (the trace combo). New: the turtle's answer to
a long guard up close is a hop back (the Step at rest); his Breaker is refused.

**Jilliel / owl 近 KIN** (as b0a0). The vanish: TENSHIN out as soon as 13 flash step is there and nothing is to cash.
New:
- the turtle (a long guard up close: TENSHIN out when it can, else a hop back);
- **MUJITTAI in KIN is left by TENSHIN out** (`LB-AI-EXIT-CMD`, HARD) whenever it can pay, not by a plain J1 / K1. KIN
  is the trace combo's stage, never a place to fight.

**MUJITTAI's in-rule, Trompete, the eye, the awakening, the revival**: as shipped.

**Adaptation (once per event, no roll):**
- the hunt yields to what he does (his attack, rush or projectile seen);
- the stance re-reads him at f6 (the evade) and again at the re-entry;
- the oki reads his wake-up's frames;
- the turtle reads his guard's length.

## 3. Measurement

**EVAL_COMMAND** (40 seeds, frozen evaluator). `score.json` is the line for the delivered file:

| | baseline | b0a0 (parent, re-measured here) | **b0a1** |
|---|---|---|---|
| score | 0.4449 | 0.9548 | **0.9957** |
| strength | 0.095 | 0.958 | **0.998** (399 / 400; the loss: seed 38, L vs Ichigo as P1, after the revival) |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.517 | 0.930 | **0.992** |
| drift (NORMAL share) | 0.44 | 0.44 | **0.44** (Y 44, K 28, R 31, I 35, S 38 of 80: identical) |
| pacing Y / K / R / I / S (s) | 174.2 / 169.2 / 198.1 / 209.0 / 194.7 | identical | identical, all 40 / 40 K.O. |

`sig_by`, b0a0 → b0a1:

| category | b0a0 | b0a1 |
|---|---|---|
| HOSHA bullets | 0.267 | 0.434 |
| HOSHA links | 0.228 | 0.354 |
| trace combos | 0.257 | 0.120 |
| traces | 0.095 | 0.042 |
| Jilliel Kikon | 0.049 | 0.025 |
| NIJŪSHI-KŌ | 0.016 | 0.009 |
| **plain J / K** | **0.065** | **0.008** |
| charged shot | 0.002 | 0.005 |
| **Breaker** | **0.005** | **0** |
| quick shot | 0.000 | (none) |
| counters | 0.001 | 0.001 |

**The path and the ablations.** The scratch diagnostic is the evaluator's HARD strength sims (both seats, seeds 1–20 =
200 matches) with the combat log. Wins within ±4 / 200 are noise; the signature and damage-taken columns are not.

| variant | wins / 200 | signature | dealt / taken a match | note |
|---|---|---|---|---|
| b0a0 (parent) | 194 | 0.928 | 4603 / 1232 | |
| + composure (10 seeds) | 97 / 100 | 0.968 | 4535 / 1094 | ORANGE 0.5 a match left (KIN string ends, inside trace combos) |
| + the hunt reads his attack, the f6 evade | 200 | 0.962 | 4481 / 1055 | the evade's re-plan fell to the quick shot |
| + the charged shot, never the quick one | 197 | 0.967 | 4462 / 1108 | |
| + the okizeme (hands off till the frame) | 199 | 0.986 | 4614 / 702 | the plain step-in J string gone |
| + the turtle, no Breaker | 200 | 0.991 | 4615 / 609 | Breaker 0.4 % → 0, ~110 taken a match gone |
| + KIN MUJITTAI left by TENSHIN out (**final**) | **200** | **0.992** | 4618 / 622 | |
| held-out seeds 41–60 (v5 = final less the last row) | 200 | 0.991 | 4617 / 629 | |
| *ablations of v5 (one piece out)* | | | | |
| no composure | 200 | 0.945 | 4658 / 784 | ORANGE's plain strings back |
| no oki | 200 | 0.972 | 4466 / 1029 | |
| oki without the hands-off (b2a0's way: NIL until the frame) | 200 | 0.982 | 4559 / 753 | step-in J origin 33 a match (vs 4.4) |
| no attack read, no evade | 198 | 0.991 | 4637 / 611 | **Konpaku lost 1.02 a match (vs 0.52); his Kikons on Lille 0.41 (vs 0.18); Konpaku lost right after a hunt 0.43 (vs 0.01)** |
| no evade (the read kept) | 200 | 0.991 | 4638 / 642 | |
| the quick shot kept | 200 | 0.990 | 4628 / 619 | |

Per match (final, 40 seeds):
- **the HOSHA loop:** hunts 7.9, oki HOSHAs 11.7, loop stances 32.5;
- **EN and KIN:** marks 6.2 → springs 6.1, vanishes 5.7;
- **the turtle:** sieges 0.5;
- **the opponents:** blow-aways by him 12.3, their BLUE bursts 3.0;
- **his losses:** Konpaku lost 0.57, his own ORANGE 0.36.

Host tests:
- duel-rules **6379 ALL PASS**. Only the LILLE-CPU-TESTS section changed:
  - the `:hunt` pin now has `:oki 8.0`;
  - the hunt-plan pins gain the attacking / evade cases;
  - new pins: the oki plan (`LB-WAKE-LEFT`; `*LB-AI-OKI-HOSHA*` = the stance's 6 + HOSHA's first bullet at f6), the
    composure covering HOSHA's link frame, and the HARD level of every form's key (0 at EASY and NORMAL);
  - every earlier pin is kept, and the section splices byte-identically into the frozen file.
- duel-control 89 and learn 100 ALL PASS.
- `tools/pkgcheck.sh duel`: 0 / 0 / 0.
- The awaken A/B was not run. The awakening and the revival are untouched, and the A/B runs at NORMAL, where this CPU is
  the shipped one bit for bit (the drift's 400 NORMAL matches are identical).

## 4. Why it is not a repeat

- It refines its parent by **locating its bugs in its own logs**, not by retuning its knobs. b0a0's knobs (`:far 7.5`,
  `:mark`, `:vanish :fs 13`) are unchanged.
- **New and found by no cell:**
  - the hunt's open test let it leap into rushes and attack startups (the Konpaku numbers above);
  - the oki's hands-off: the parent's largest plain source after ORANGE, which b2a0's NIL-until-the-frame left half
    open (0.982 vs 0.992);
  - the evade at the stance's f6 with a re-plan;
  - TENSHIN-out exits from KIN's MUJITTAI.
- **The turtle** answers the generic guard-break / anti-parry events in character (TAISHA through guard; KIN out; EN
  back). b2a0's siege and b3a0's refusal touched the same ground. Here the generic events are consumed, so the refusal
  never leaves a dead Breaker press.
- **Borrowed, credited:** b2a0's composure (the located ORANGE fix; ablation −0.046 signature without it) and its oki
  timing. I did not take b2a0's KIN route, pendulum, K3 exits or oki mark, nor b3a0's crossfire, enders or spacing. The
  final still beats b2a0's 0.9945 on its own composition.

## 5. Expected benefit

At HARD he plays a disciplined sniper:
- he never leaps at a man who is swinging, or rushing in for his soul (Konpaku lost halves);
- he waits out a downed opponent and meets his first hittable frame with HOSHA;
- he answers a turtle with the X-axis through guard, never with a Breaker;
- KIN is only the trace combo's stage.

He wins 399 / 400 HARD CPU matches, with 99.2 % of his damage his signature. EASY and NORMAL are unchanged.

## 6. Risks

- **Pacing**: the NORMAL medians are the baseline's (LR 198.1 and LI 209.0 against cap 240, LS 194.7 against 220).
  None is within 15 s of its cap.
- **Style**: at HARD he lives in the base form's HOSHA loop (79 % of his damage is HOSHA's bullets and links). The
  long-range sniper (the charged shot, 0.5 %) is rarely seen, as in b2a0. Only an evaluator change would move this.
- **The `:NONE` waits** (the oki's hands-off, up to ~50 frames per downed opponent; the parry wait) block the generic
  reflexes for those steps. The learner's read runs before the kit's reflex, so it is not starved. While he is down
  there is no move of his to answer, but a hazard he left (a pillar) would not be answered either.
- **The composure is b2a0's pad trick** (an inert J held 18 f). It silences every generic reflex in HOSHA, not only
  ORANGE. A shared `:orange` key would be cleaner (recommendation 1).
- **HARD may be too strong for a human**: the frame-exact oki and the HOSHA loop, inherited. A human can Burst, Step on
  wake-up, or hold guard (HOSHA is guardable).
- **The ASSIST**: no new hook the ASSIST calls. Every new branch reads `(brain e)` or the reflex's own brain. `LILLE-OK`'s
  Breaker refusal reads `(brain e)`, NIL for a human, so an assisted human can still Breaker.
- **Overfitting**: measured only against the frozen CPUs. The held-out seeds 41–60 agree (200 / 200, 0.991).

## 7. Shared-code recommendations (not done)

1. ORANGE as a kit key (`:orange` by difficulty), so the composure's pad trick can go (b0a0's, b2a0's and b3a0's
   recommendation too).
2. `LB-AI-OPEN-P`-style "free target" tests in every kit's opener. The generic `AI-THREAT` view of a rush (a
   non-main-phase Kikon / Breaker) is invisible to any reflex keyed on threat windows. A shared `rush-p` on the SNAP would
   help every character's CPU.
3. A generic okizeme hook (perceived frames to wake-up on the SNAP), so no kit re-derives `*REACTION-FRAMES*` (b2a0's
   recommendation).
4. The generic guard-break / anti-parry reflexes press a Breaker without asking `KIT-COMMAND-OK-P`. A kit that refuses it
   is left with a dead press for 12–42 frames. Checking `:ok` there would let refusals work without consuming the event.
