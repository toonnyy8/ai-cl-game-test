# b3a1 (round 1, refines b3a0, freeze 1a7f135 / decision 47): the sniper's pendulum — b3a0's multi-mode engines, the located fixes, the lines before KIN, the X-Axis on the wake-up

A refine of **b3a0** (rescored 0.9883 at this freeze; my run of its file gave the same JSON). It keeps b3a0's engines:
- the spacing rule (TAISHA / the dash back inside ORANGE's window);
- the KIN → EN → KIN crossfire;
- the combo enders and the refusals.

It brings in the fixes the other lineages located, credited (b3a0's file still had every one of those leaks). It develops b3a0's crossfire into a pendulum. It adds three new pieces aimed at leaks located in this lineage's own logs.

Only `duel/lisp/lille.lisp` changed, and only his CPU:
- the AI section: a new block after `LB-AI-HUNT`, with new knobs, functions and two `LBAI` fields;
- edits to the dispatch in `LB-AI-REFLEX`, `LB-AI-EXIT-CMD`, `LB-AI-STANCE-OUT`, `LB-AI-EN`, `LB-AI-KIN`, `LB-AI-WEB-LAY`, `LB-AI-HUNT`, `LB-AI-KAMAE` and `LB-AI-LINK`;
- one value: `*LB-AI-HUNT-BAND*` (2.5 7.5) → (0.0 7.5);
- one `(brain e)` line in `LB-LINK-TICK` (the route latch).

What did not change:
- frame data, damage, costs, rules, the human branches;
- the opponent-facing keys (`:opp-trace :opp-reflex :opp-reflect :opp-aim`) and `LB-OPP-TRACE`;
- any other file, and no new kit key the ASSIST calls;
- `AI-AWAKEN-P` / `:awaken` and the `:bankai` revival.

Every new behaviour is a level `(:easy 0 :normal 0 :hard 1)`, tested first. So EASY and NORMAL take the shipped branches and draw the shipped random numbers: drift and pacing are byte-identical to the baseline. HARD runs deterministic rules on what it perceives, once per event. There is no new roll anywhere.

**Score 0.9995**: strength **1.000** (400 / 400), masher 1.000, signature **0.999**. For comparison, b3a0 rescored 0.9883 (0.995 / 1.000 / 0.976), and the best of the round, b0a2, 0.9991 (1.000 / 1.000 / 0.998).

## 1. The history read

| cell (rescored) | score | mechanism | what I took / what it meant |
|---|---|---|---|
| baseline | 0.4449 | the shipped CPU | NORMAL drift 0.44; HARD 0.095 |
| v1 b0a0 / b1a0 (old rules) | — | snipe / snap opener on the laying shot's flinch | re-derived by every round-1 cell on the 2 f cancel |
| b0a0 | 0.9548 | mark + spring, vanish, hunt, the HOSHA → K1 → L loop | the engines |
| b1a0 | 0.9586 | web, hit-and-run, the loop, SP2 cash-out | my lineage's engines (via b3a0) |
| b2a0 | 0.9945 | composure (held J: no ORANGE), okizeme, **KIN J1 → K2s → K3 route**, K3 exits, pendulum | the route latch and the composure, credited |
| **b3a0 (parent)** | **0.9883** | b1a0 + spacing rule, **crossfire**, enders, refusals | kept whole; the crossfire developed |
| b0a1 | 0.9957 | rush-wary hunt (first seen there), hands-off oki, **turtle**, no Breaker | the turtle (via b1a2) |
| b1a1 | 0.9937 | **rush-wary hunt**, **wake-up charged shot**, **patient web**, **KIN signature exits**, composure | all four ported (same b1a0 lineage as b3a0) |
| b0a2 | 0.9991 | KIN SP enders, SANREN cash, **EN never into KIN with nothing**, guard wait, execution shot (HIRENKYAKU timing 16–18 f) | the EN-exit leak (re-found here) and the HIRENKYAKU timing |
| b1a2 | 0.9984 | clean hand, **turtle**, **held aim**, **KIN cash-in**, **KIN hold** | all four ported; its negative result (KIN starved: leave / hold / veil cost Konpaku) respected |

I trusted the rescored numbers.

My diagnostic is the evaluator's HARD strength sims, both seats, with the combat log (`scratchpad/lille-b3a1/diag.py`, `summ.py`, `plain.py`, `kinorig.py`, adapted from b1a2's; not delivered). On b3a0's file, seeds 1–40 (400 matches) gave:
- 398 / 400 wins, signature 0.9758, taken 707 a match;
- Konpaku lost 1.375 a match, **0.98 of it right after a HUNT stance**. This is b1a1's located bug: b1a0's hunt treats his Kikon / Breaker rush as "a move" and takes the stance into it. b3a0 inherited it, and it is where both of its losses came from.

Plain J / K was 2.3 % of his damage. By the string's head (a match):

| head | damage a match | cause |
|---|---|---|
| base STEP-J | 27.9 | no okizeme; the generic step-in J met the wake-up |
| base PUNISH | 17.4 | a whiff under 2.5 m, below the hunt's band: the generic J string |
| KIN STANCE-EXIT | 14.2 | KIN MUJITTAI's wing-blade exit |
| base CHAIN | 13.9 | ORANGE: a hunt HOSHA whose first bullet missed lands the second at the leap's end, 0.95 m from him. The spacing rule only covers the HOSHA's start distance. It also fired off TAISHA and the charged shot when he ran in |
| KIN NEUTRAL | 10.2 | KIN reached with nothing to cash |
| base FOLLOW-UP | 6.8 | the generic follow-up |

## 2. The action policy (HARD; EASY and NORMAL are the shipped CPU bit for bit)

**Base 万物貫通: the hunter who keeps his distance and finishes with the X-Axis.**
- **b3a0's spacing rule, kept.** The loop is bullets → K1 → the stance → **TAISHA** from 3 m back, then the hunt again from range. An open opponent close in gets the HIRENKYAKU dash back, then HOSHA. TAISHA is 18 % of his damage.
- **The composure** (b2a0's mechanism) is now on every branch the stance fires: HOSHA, TAISHA and the shot. J is held 18 f (inert there), so no generic reflex (ORANGE) runs on their hits. ORANGE fell from 0.17 to 0.00 a match.
- **The hunt starts from 0 m** (b0a0 / b1a1's value). With the composure, a whiff under 2.5 m is punished by the stance, not by a generic J string. b3a0 had measured "the hunt from 0 m" as neutral; that was before ORANGE was closed.
- **The rush-wary hunt** (b1a1): never the stance into his rush. The generic anti-rush answers take it.
- **The wake-up shot** (b1a1): a downed opponent gets the charged X-Axis shot, pressed 40 f before his first hittable frame. HOSHA's link skips the K1 into a blown-away opponent.
- **New: the late wake-up.** When it is too late for a charge, **HIRENKYAKU** (SP2: the 6 m back-slide, the X-Axis shot at its f20) is pressed 16–18 f before that frame (`*LB-AI-OKI-HIREN*`, b0a2's timing). b0a2 used it only for kills; here it fires on every late wake-up that has a bar. It fires 1.9 times a match with ~1.6 hits of ~91, and HIRENKYAKU went from 0 to 4.2 % of his damage.
- **The turtle and the held aim** (b0a1 / b1a2):
  - the generic guard-break / anti-parry events are his kit's;
  - a guard within 3 m gets TAISHA through it;
  - a long guard farther away gets the charged shot;
  - a fresh guard is waited out;
  - the stance never throws the quick shot at HARD.

**Jilliel / owl 遠 EN: the web, and lines before KIN.**
- b1a0's web (via b3a0) is kept, with b1a1's **patient web**: lines are laid at a guard or ward too, and the switch waits for it to drop.
- **New: the lines before KIN** (`*LB-AI-EN-EXIT*`). This is b0a2's located leak, found again in this lineage: 0.27 MUJITTAI exits a match into KIN with nothing, 2.9 plain damage a match after them, and 1.1 more after the starved switch.
  - EN MUJITTAI's exit is J1, a line laid at him; the web's cancel materialises it. With no flash step for that, the exit is SP1's three lines (`LB-AI-EN-EXIT`).
  - A starved EN lays SP1's lines at him from the web's band before the starved switch-in (`LB-AI-POOR-WEB`). This fires 0.34 a match.

**Jilliel / owl 近 KIN: the pendulum 振り子 (b3a0's crossfire developed).**
- **New: the route** (`*LB-AI-ROUTE*`, b2a0's latch, credited). The trace combo's KIN J1 (TENSHIN in's link) latches K at once: J1 → K2s → K3. The string now always ends in K3's crumple, which is exactly where b3a0's crossfire opens: L → TENSHIN out → EN J1 at him → the materialise → TENSHIN in → J1 → K2s → K3 → … The trace combo swings between the two modes until the stun tolerance blows him away. NIJŪSHI-KŌ follows the crumple when the flash step can't pay the swing.
  - Crossfires went from 2.1 to **4.0 a match** (8.3 routes).
  - Trace combos went from 19 % to 24 % of his damage.
  - Damage taken fell from 469 to 419 a match.
- KIN's exits / hold (b1a1 / b1a2): MUJITTAI in KIN ends in SANREN or TENSHIN out, else holds, yielding to his rush. KIN's cash-in (b1a2): SANREN on a reeling or recovering opponent.
- **New: KIN's snipe** (`*LB-AI-KIN-SNIPE*`). KIN free, after the run and the cash, with nothing to cash and no flash step to run on, and him free (no threat, no rush, not stepping or Hohoing): **SANREN**, not the generic neutral wing-blade string.
  - This was the largest plain source left in KIN (KIN NEUTRAL, 3–4 a match).
  - It fires 0.27 a match, and KIN NEUTRAL plain fell to 0.8–2.4 a match.
  - b1a2's measured negative was making a starved KIN leave or hold. This acts instead, with the bar b1a2's lineage left idle.

**Unchanged:**
- b3a0's refusals (no Breaker; no non-red O ender where an answer combos), its enders and its guard read;
- the eye, MUJITTAI's entry, Trompete, the owl's CPU beyond the shared EN / KIN code;
- the awakening and the revival;
- every debug mode (79000–79999).

The `duel lille` counters gain these keys: `ai-composure`, `ai-oki-shot`, `ai-oki-hiren`, `ai-route`, `ai-poor-web`, `ai-kin-snipe`, `ai-kin-cash`, `ai-kin-hold-out`, `ai-turtle`, `ai-held-aim-shot`.

**Adaptation**, once per event, with no roll:
- the hunt reads his rush and his whiff;
- the wake-up reads his down / wake-up frames (charged, or HIRENKYAKU when late);
- the turtle and the held aim read his guard's length and distance;
- the patient web reads his guard;
- the route reads the trace hit, the crossfire reads K3's crumple and his own flash step, and the EN exit reads his flash step and bars;
- KIN's cash / snipe read his perceived recovery and threat.

## 3. Measurement

**EVAL_COMMAND** (40 seeds, frozen evaluator). `score.json` is the line it printed for the delivered file.

| | baseline | b3a0 (parent) | **b3a1** |
|---|---|---|---|
| score | 0.4449 | 0.9883 | **0.9995** |
| strength | 0.095 | 0.995 (398 / 400) | **1.000** (400 / 400) |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.517 | 0.976 | **0.999** |
| drift (NORMAL share) | 0.44 | 0.44 | **0.44** (Y 44, K 28, R 31, I 35, S 38 of 80: identical) |
| pacing Y / K / R / I / S (s) | 174.2 / 169.2 / 198.1 / 209.0 / 194.7 | identical | identical, all 40 / 40 K.O. |

`sig_by`, b3a0 → b3a1:

| category | b3a0 | b3a1 |
|---|---|---|
| trace combos | 0.285 | 0.242 |
| HOSHA bullets | 0.181 | 0.210 |
| HOSHA links | 0.154 | 0.181 |
| TAISHA | 0.139 | 0.180 |
| traces | 0.101 | 0.069 |
| charged shot | 0.013 | **0.046** |
| HIRENKYAKU | 0.002 | **0.042** |
| SANREN | 0.068 | 0.006 |
| Jilliel Kikon | 0.027 | 0.020 |
| NIJŪSHI-KŌ | 0.003 | 0.002 |
| **plain J / K** | **0.023** | **0.001** |
| counters | 0.001 | 0.000 |

**Style (the coordinator's question).**
- **The X-Axis share** is TAISHA + charged shot + HIRENKYAKU + traces + SANREN + NIJŪSHI-KŌ: **34.5 %** of his damage (b3a0 32.6 %). Trace combos (trace → TENSHIN → KIN, both modes) add another 24.2 %.
- **The HOSHA loop** (bullets + links) is **39.1 %** (b3a0 33.5 %; b0a1 / b0a2 75–79 %; b1a1 / b1a2 65–66 %).
- The charged X-Axis shot and HIRENKYAKU together rose from 1.5 % to 8.8 %. Each Soul Break that blows him away is now usually followed by a shot from range on his wake-up.
- SANREN fell (6.8 % → 0.6 %): KIN's strings now end in K3 and swing back through EN as traces, instead of J3 → SANREN.

**The path.** My diagnostic at seeds 1–40 (400 matches each); held-out seeds 41–80 where run. Wins within ±2 are noise; the signature and damage-taken columns are steadier.

| step (cumulative) | wins | signature | taken / match | Konpaku lost / match | |
|---|---|---|---|---|---|
| b3a0 (parent) | 398 | 0.9758 | 707 | 1.375 | full eval 0.9883 |
| v1: + rush-wary hunt, wake-up shot, patient web, KIN exits / hold, turtle, held aim, KIN cash-in (ports) | 398 | 0.9864 | 559 | 0.305 | |
| v2a: + composure (HOSHA) | 399 | 0.9899 | 585 | 0.407 | |
| v2b: + the hunt from 0 m | **400** | 0.9968 | 469 | 0.207 | full eval **0.9987** |
| v3: + the lines before KIN (EN exit, poor web) | 400 / 400 | 0.9975 / 0.9966 | 469 / 512 | 0.225 / 0.255 | |
| v4: + composure on TAISHA / the shot (+ a link hold, inert: 0 fires, dropped) | 399 | 0.9973 | 479 | 0.245 | ORANGE off TAISHA / the shot: CHAIN 1.1 → 0.4 |
| v5: + **the pendulum's route** | 400 / 400 | 0.9978 / 0.9980 | **419 / 432** | **0.145 / 0.160** | crossfires 2.1 → 4.0 |
| v6: + **KIN's snipe** | 400 / 400 | 0.9987 / 0.9981 | 430 / 435 | 0.175 / 0.198 | full eval **0.9995** |
| **v7 = final: + HIRENKYAKU on a late wake-up** | **400 / 400** | **0.9987 / 0.9979** | **418 / 424** | 0.185 / 0.170 | full eval **0.9995** (the same parts; X-Axis share +4 %) |

What is left of the non-signature damage (final, a match): KIN plain 1–3 (a trace hit on a super-freeze / armoured start, after which TENSHIN in's J1 opens a new combo, ~1–2; the generic step-in J ~1.5), base 0.5, counters 0.1. One sub-test, "no link J1 when he isn't seen reeling", was inert (that snap still shows him reeling) and was dropped.

**Host tests:**
- duel-rules **6384 ALL PASS**. The LILLE-CPU-TESTS section is b3a0's checks plus 5 new ones, and the hunt band's pin is updated to (0.0 7.5). The new checks pin:
  - the twelve new levels at 0 / 0 / 1, with no brain → 0;
  - the composure covering HOSHA's bullets and link, TAISHA's hit and the shot's;
  - `LB-WAKE-LEFT`, the wake-up lead 40, and HIRENKYAKU's 16–18 window against its f20 shot;
  - TAISHA's reach against the guard-break range;
  - the SP1s his lines use (KIN SANREN, EN SANREN / the owl's EN 裁きの光明 with no flash-step cost, the owl's KIN MISUJI);
  - the route (KIN J1 → K2s → K3 only, K3 crumples).
- Nothing outside the markers changed: `splice-tests.py` of the delivered file into the frozen one gives the delivered file byte for byte.
- duel-control 89 and learn 100: ALL PASS. `tools/pkgcheck.sh duel`: 0 / 0 / 0.
- **The awaken A/B was not run.** The awakening and the revival are untouched, and the A/B runs at NORMAL, where this CPU is the shipped one bit for bit (the drift's 400 NORMAL matches are identical).

## 4. Why it is not a repeat

- **b3a0's engines are developed, not replaced.** The crossfire's opening (K3's crumple) is made the end of every trace-combo string by the route latch, so the KIN → EN → KIN swing runs 4 times a match instead of 2: the pendulum. That cut damage taken by 11 % and lifted trace combos to 24 %. The spacing rule is kept for its TAISHA (18 % of his damage, the largest X-Axis share in the history), not for ORANGE.
- **New and located in this lineage's logs:**
  - **KIN's snipe**: SANREN in the starved KIN neutral, the leak b1a2 could not close by leaving or holding;
  - **the late wake-up HIRENKYAKU** for every late wake-up, not only the kill;
  - **the composure on TAISHA and the shot**: ORANGE off them, a source no cell had reported;
  - the finding that **the hunt's HOSHA whose first bullet misses** lands inside ORANGE's window despite the spacing rule (the hunt's ORANGE leak b3a0 left).
- **Credited and combined:** b1a1's rush-wary hunt, wake-up shot, patient web and KIN exits; b1a2's turtle, held aim, KIN cash-in and hold; b2a0's composure and route latch; b0a2's EN-exit fix and HIRENKYAKU timing. All of these are ported line for line from the same b1a0 lineage where possible, with their knobs unchanged.

## 5. Expected benefit

At HARD he plays a sniper who never fights a plain exchange:
- HOSHA onto every opening, TAISHA from 3 m back to end the loop at range;
- the X-Axis (charged, or HIRENKYAKU when late) on every wake-up;
- TAISHA or the charged shot through a guard;
- Jilliel's trace combo swinging between EN and KIN until the opponent is blown away;
- SANREN wherever KIN would otherwise throw a plain string.

He wins 800 / 800 HARD CPU matches (seeds 1–80), 99.9 % of his damage is his signature, and he takes ~420 damage a match (b3a0: 707). EASY and NORMAL are unchanged.

## 6. Risks

- **Pacing**: NORMAL is the shipped CPU, so the medians are the baseline's: LI 209.0 and LR 198.1 (cap 240), LS 194.7 (cap 220). None is within 15 s of its cap.
- **The composure is b2a0's pad trick**, now on TAISHA and the shot too. It holds an inert J 18 f, which silences every generic reflex in those moves (guard-cancel, ORANGE, chain-follow). His own BLUE burst still runs. A shared `:orange` kit key would be cleaner (every cell's recommendation).
- **Real-state reads in the sim ticks** follow the shipped `LB-AI-KAMAE` pattern (its plan reads the sim's state at f6). These are b3a0's spacing read and b1a1's "no K1 into a blown-away opponent" (`state-of`) in the HOSHA link.
- **`:NONE` waits** (the wake-up wait, the held aim on a fresh guard, the turtle's parry wait, KIN's hold) block the generic reflexes for those steps. Each yields to his rush or comes after the kit's own threat answers, and the learner's read runs before the kit reflex.
- **Bars**: the late HIRENKYAKU, the poor web, EN's exit SP1 and KIN's snipe spend Reiatsu bars that the enders used before (SANREN fell 6.8 % → 0.6 %, NIJŪSHI-KŌ is rare). Measured neutral to positive at 80 seeds.
- **HARD may be too strong for a human** (inherited: the 9 f materialise, the HOSHA loop). The new pieces are answerable:
  - the wake-up HIRENKYAKU's slide is visible, and a waking human can Step or guard it (it drains 30);
  - the pendulum's lines are visible;
  - KIN's snipe is 12 f of startup.
- **The ASSIST**: no new hook it calls. b3a0's `:sp-ender` is unchanged and still reads `AI-BRAIN`, so re-run `tools/assistgate.py` at integration. Every new branch reads `(brain e)` or the reflex's own brain. The route is in `LB-LINK-TICK`'s `(brain e)` branch, and the composure is in `LB-AI-KAMAE` (his CPU only).
- **Overfitting**: measured only against the frozen CPUs. The held-out seeds 41–80 agree: 400 / 400, signature 0.9979.

## 7. Shared-code recommendations (not done)

1. An ORANGE kit key (`:orange` by difficulty), so the composure's held J can go. This is every cell's recommendation, and here it would also cover TAISHA and the shot.
2. The generic guard-break / anti-parry reflexes press a Breaker without asking `KIT-COMMAND-OK-P` (b0a1 / b1a2). Checking it there would let a refusal work without the kit consuming the event.
3. A wake-up field in the SNAP (frames to his first hittable frame), so no kit re-derives `*REACTION-FRAMES*` for okizeme (b2a0 / b1a1).
4. A super-freeze / armoured-start edge in the trace-combo tag: a trace that hits a move's armoured start opens no combo, so TENSHIN in's J1 counts as plain (~1–2 a match left). This is an evaluator or rules observation, not a CPU fix.
