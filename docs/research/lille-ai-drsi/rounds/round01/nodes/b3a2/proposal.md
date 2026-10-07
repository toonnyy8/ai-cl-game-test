# b3a2 (round 1, refines b3a1, freeze 1a7f135 / decision 47): the sniper never raises the stance into the other man's free frames — the burst read, the sniper's step, the blow-away aim, the TAISHA read

A refine of **b3a1** (rescored 0.9995 at this freeze; my diagnostic of its file reproduced its own numbers exactly). It
keeps all of b3a1's engines and knobs: the spacing rule and the HOSHA → K1 → stance → TAISHA loop, the composure, the
pendulum (KIN J1 → K2s → K3 → crossfire), the web, the lines before KIN, KIN's snipe, the wake-up shot and HIRENKYAKU, the
turtle and the held aim. It adds three located fixes and one adaptive read, each aimed at a leak found in b3a1's own logs
on seeds the evaluator does not use (41–120).

Only `duel/lisp/lille.lisp` changed, and only his CPU:
- **a new block at the end of the AI section** (after b3a1's): knobs `*LB-AI-BURST-READ*`, `*LB-AI-BURST-WAIT*` (30),
  `*LB-AI-TAISHA-READ*`, `*LB-AI-TAISHA-PUNISHED*` (1), `*LB-AI-CLOSE*`, `*LB-AI-BLOW*`; functions `LB-AI-BREAK-FREE-P`,
  `LB-AI-BURST-AGE`, `LB-AI-BURST-WAIT`, `LB-AI-TAISHA-PLAN`, `LB-AI-TAISHA-READ`, `LB-AI-TAISHA-SETTLE`,
  `LB-AI-BLOW-FIRE-P`, `LB-AI-BLOW-STEP`; five `LBAI` fields (`burst`, `taisha`, `taisha-hp`, `taisha-kon`, `punished`);
- **edits**: `LB-AI-REFLEX` (the base form: the TAISHA settle first, the burst wait after the eye), `LB-AI-KAMAE` (the
  stance's CPU plan, `(brain e)` code: the close hunt, the whiff exemption from the spacing rule, the blow-away plan, the
  TAISHA read on the turtle / held aim's TAISHA, and the new `:dash-oki` / `:oki` plans).

What did not change: frame data, damage, costs, rules, every human branch; the opponent-facing keys (`:opp-trace :opp-reflex
:opp-reflect :opp-aim`) and `LB-OPP-TRACE`; every other file; no new kit key the ASSIST calls (no `:sp-ender` change);
`AI-AWAKEN-P` / `:awaken` and the `:bankai` revival; every debug mode (79000–79999); the `duel lille` counters (new keys
`ai-burst-wait`, `ai-blow-shot`, `ai-kamae-dash-oki`, `ai-kamae-oki`, `ai-taisha-read`, `ai-taisha-punished`).

Every new behaviour is a level `(:easy 0 :normal 0 :hard 1)`, tested first, so EASY and NORMAL take the shipped branches and
draw the shipped random numbers: the drift and pacing JSON are byte-identical to the baseline's. HARD runs deterministic
rules on what it perceives (the delayed SNAPs) and on its own state, decided once per event. There is no new roll.

**Score 0.9992** = strength **1.000** (400 / 400), masher 1.000, signature **0.998**. b3a1, the parent, rescored 0.9995
(1.000 / 1.000 / 0.999). **The 40-seed score does not see this refine's gain and is 0.0003 lower** (signature 0.9981 vs
0.9987 at seeds 1–40 in my diagnostic: KIN's starved neutral strings, which move ±0.001 from seed block to seed block; on
seeds 41–80 the same comparison is 0.9991 vs 0.9979). The gain is in robustness, measured on 800 held-out matches (§3).

## 1. The history read

| cell (rescored at 1a7f135) | score | mechanism | what I took / what it meant here |
|---|---|---|---|
| baseline | 0.4449 | the shipped CPU | NORMAL drift 0.44; HARD 0.095 |
| v1 b0a0 / b1a0 (old rules) | — | snipe / snap opener on the gone laying shot's flinch; HOSHA hunt; SP2 cash-outs | re-derived on the 2 f cancel by every round-1 cell |
| b0a0 | 0.9548 | mark + spring, vanish, hunt, the HOSHA → K1 → L loop | the engines |
| b1a0 | 0.9586 | web, hit-and-run, the loop, SP2 cash-out | this lineage's engines |
| b2a0 | 0.9945 | composure, okizeme, KIN route, K3 exits, pendulum, siege | the route and the composure (in b3a1) |
| b3a0 | 0.9883 | b1a0 + spacing, crossfire, enders, refusals | the spacing rule's TAISHA (in b3a1) |
| b0a1 | 0.9957 | rush-wary hunt, **attack read**, hands-off oki, turtle, no Breaker | the attack read: re-tested here, a measured negative on this lineage (§3) |
| b1a1 | 0.9937 | rush-wary hunt, wake-up charged shot, patient web, KIN exits | in b3a1 |
| b0a2 | 0.9991 | KIN SP enders, SANREN cash, EN line exit, guard wait, HIRENKYAKU timing 16–18 | in b3a1 |
| b1a2 | 0.9984 | clean hand, turtle, held aim (TAISHA on any guard within 3 m), KIN cash-in, KIN hold | in b3a1; its negatives (KIN veil / wait) respected |
| b2a1 | 0.9994 | the sight (HIRENKYAKU oki at 2 bars), **the burst read** (HUD gauge), the round's fixes | the burst read's idea, credited, re-built on perception (§2) |
| **b3a1 (parent)** | **0.9995** | b3a0 + the round's fixes + pendulum, lines before KIN, KIN's snipe, late wake-up HIRENKYAKU | what I refine |

I trusted the rescored numbers. Then I read **the parent's own logs** on held-out seeds. My diagnostic is the evaluator's
HARD strength sims (both seats, 400 matches a 40-seed block) with the combat log and the `duel lille` counters (b3a1's
`diag.py` / `summ.py` / `kon.py`, plus my own scripts: damage taken by context, by the opponent's whole combo and by the
move of his that opened it; scratch, not delivered). b3a1 on seeds 41–80: 400 / 400, signature 0.9979, **taken 424 a
match**, Konpaku lost 0.17; on 81–120: 400 / 400, 0.9980, **438**, 0.225, one revival. Located (seeds 41–80, a match):

1. **The burst.** 42.7 damage within 90 f of the opponent's BLUE, 27.6 of it right after a hunt's stance (Rukia's
   ICE-CASH SHIRAFUNE, Kenpachi's KE-STANCE). This is b2a1's finding, still open in this lineage.
2. **The hunt's TAISHA at his feet.** The hunt's HOSHA override in `LB-AI-KAMAE` starts at 2 m, so a hunt stance on a free
   opponent within 2 m planned the shipped TAISHA (16 f startup after the stance's 6, at point blank): 1.04 a match, 158
   hits in 400 matches, 69 times hit out of it, 31 times perfect-Hohoed (Ichigo), ~35 damage a match taken after it.
3. **The blow-away.** The loop's K1 latches L, so the stance comes up at K1's f4. When that K1 blew him away (the stun
   tolerance), the spacing rule read him `:air` as reeling and planned TAISHA into the air: 2.1 a match. Its 42 f whiff ate
   the wake-up shot's 40 f lead, so the wake-up went to the late HIRENKYAKU (1.44 a match, a bar) or to a hunt into his
   wake-up (0.6 a match). Of 5.9 base-form blow-aways a match, only 2.4 got the charged shot.
4. **His perfect Hoho on TAISHA.** By whole combos (my combo attribution), the largest single item vs Ichigo is the held
   aim's TAISHA at his close guard: perfect Hoho, the counter strike, his Bankai string and Kikon: 0.08 a match at
   **274 damage each** (22 a match). Ichigo perfect-Hohos 35 of 50 such TAISHAs; the other four almost never.

## 2. The action policy (HARD; EASY and NORMAL are the shipped CPU bit for bit)

One rule joins the three fixes, in character: **the sniper never raises his stance (no guard, 6 f up) into the other man's
free frames.** He shoots a committed target, from range, and at point blank he leaves first.

**Base 万物貫通**
- **The burst read 読み (new mechanism here; b2a1's idea, credited).** After the eye (which still answers any threat
  first), the base form stands (`:NONE`) while the opponent's break-free is younger than 30 f (his 20 f of invulnerability
  + 10), instead of hunting into it. Read without the opponent's gauge:
  - **his own state first**: REPEL! pushes him 5 m over 20 frames, so "free and still being pushed" (`MOTION-KB-LEFT`) is
    the burst seen on his own body. This matters: the burst's hitstop (8 f) freezes the sim, so the CPU's first free step
    comes before the 8 f perception can show the break (my debug trace: at the hunt's step every perceived SNAP still showed
    the pre-burst stun);
  - **then the perceived SNAPs** (`LB-AI-BURST-AGE`): two in a row, the older reeling with ≥ 2 frames of it still to run
    (or airborne), the newer free: a reaction that runs out ends at 0 left, a burst or an awakening ends it at once
    (`LB-AI-BREAK-FREE-P`, host-tested case by case). It looks back (30 − delay) SNAPs, inside the brain's ring of 32 at
    HARD's delay 8 (pinned).
  - It never waits against his rush (`LB-AI-RUSH-P`): the generic anti-rush answers a Kikon / Breaker coming in.
  - 2.0 a match; damage taken within 90 f of his BLUE 42.7 → **22.2** a match (seeds 41–80), 47.9 → **21.7** (81–120).
- **The sniper's step 間合い (new).** The hunt's stance on a free opponent within 2 m now plans HOSHA too
  (`*LB-AI-CLOSE*`), so b3a0's spacing rule takes it: **the HIRENKYAKU dash back** (iframes f0–8, 3.5 m) then HOSHA, or
  TAISHA when the dash can't be paid. Onto a close **whiff** (him in his recovery, the shipped f6 read) HOSHA fires at once
  (its first bullet at f6 vs TAISHA's f16; the composure holds ORANGE off, so the spacing rule is skipped there). The hunt's
  close TAISHA fell from 1.04 to 0.13 a match.
- **The blow-away aim 残心の照準 (new).** When the stance comes up (its f6 plan) on an opponent blown away (`:air` /
  `:down` / `:wakeup`), it no longer plans TAISHA into the air: it **dashes back** (HIRENKYAKU's step, when it can pay) and
  **holds L** (the stance's hold, up to 90 f; `LB-AI-BLOW-STEP`), then fires the **charged X-Axis shot** when his first
  hittable frame, read off the perceived SNAP (`LB-WAKE-LEFT`), is the shot's startup (10 f) away, or at once if he is seen
  up (`LB-AI-BLOW-FIRE-P`, host-tested). 2.5 a match; the charged shot fired 4.2 → **6.9** a match and hit 3.4 → **6.1**;
  the late HIRENKYAKU 1.84 → 0.27 a match (its bar stays for SANREN / NIJŪSHI-KŌ in Jilliel). b3a1's free wake-up shot
  (`LB-AI-OKI-SHOT`) is unchanged and still fires 2.35 a match.
- **The TAISHA read 見切り (new, adaptive; one read per TAISHA).** The turtle / held aim pierce a close guard with TAISHA as
  before. Each such TAISHA is remembered (its tick, his own Reishi and Konpaku). On his next free step it is settled: if he
  lost Reishi or Konpaku since, it was punished. One punished TAISHA turns the next close-guard plan into **the dash back
  then the charged shot through the guard** (`LB-AI-TAISHA-PLAN`); an unpunished one clears the read. It reads only his own
  state. Against the frozen CPUs it is almost inert (0.12 punished a match, 0.03 reads: Ichigo's TAISHAs are ~0.6 a match,
  so the first one costs before the read can answer); it is the answer to a player who learns to Hoho TAISHA.

**Jilliel / owl, MUJITTAI, Trompete, the eye, the awakening, the revival**: b3a1's, unchanged.

**Adaptation, once per event, no roll:** the burst read reads his break-free (own push, then the perceived break); the
sniper's step reads the distance and his whiff at the stance's f6; the blow-away aim reads his down / wake-up frames off
the perceived SNAP; the TAISHA read reads what his TAISHA cost him.

## 3. Measurement

**EVAL_COMMAND** (40 seeds, frozen evaluator; `score.json` is the line it printed for the delivered file):

| | baseline | b3a1 (parent, rescored) | **b3a2** |
|---|---|---|---|
| score | 0.4449 | 0.9995 | **0.9992** |
| strength | 0.095 | 1.000 (400 / 400) | **1.000** (400 / 400) |
| masher | 1.000 | 1.000 | 1.000 |
| signature | 0.517 | 0.999 | **0.998** |
| drift (NORMAL share) | 0.44 | 0.44 | **0.44** (Y 44, K 28, R 31, I 35, S 38 of 80: identical) |
| pacing Y / K / R / I / S (s) | 174.2 / 169.2 / 198.1 / 209.0 / 194.7 | identical | identical, all 40 / 40 K.O. |

`sig_by`, b3a1 → b3a2 (40 seeds): trace combos 0.242 → 0.235, HOSHA bullets 0.210 → 0.215, HOSHA links 0.181 → 0.183,
TAISHA 0.180 → 0.175, **charged shot 0.046 → 0.086**, traces 0.069 → 0.067, **HIRENKYAKU 0.042 → 0.007**, Jilliel Kikon
0.020 → 0.020, SANREN 0.006 → 0.006, NIJŪSHI-KŌ 0.002 → 0.003, plain J / K 0.001 → 0.002, counters 0.000 → 0.000.

**Robustness (the diagnostic; HARD, both seats, the evaluator's strength sims, 400 matches a block):**

| file | seeds | wins | signature | taken a match | Konpaku lost a match | revivals |
|---|---|---|---|---|---|---|
| b3a1 | 1–40 (eval's) | 400 | 0.9987 | 418 | 0.185 | 1 |
| b3a1 | 41–80 | 400 | 0.9979 | 424 | 0.170 | 0 |
| b3a1 | 81–120 | 400 | 0.9980 | 438 | 0.225 | 1 |
| **b3a2** | 1–40 (eval's) | **400** | 0.9981 | **395** | **0.113** | 0 |
| **b3a2** | 41–80 | **400** | **0.9991** | **367** | **0.147** | 0 |
| **b3a2** | 81–120 | **400** | **0.9982** | **380** | **0.115** | 0 |

Held out (seeds 41–120, 800 matches): **damage taken 431 → 374 a match (−13 %)**, **Konpaku lost 0.198 → 0.131 a match
(−34 %)**, revivals 1 → 0, signature 0.9980 → 0.9987, 800 / 800 wins both. On the eval's seeds: −6 % taken, −39 % Konpaku.
(b3a1's seeds 1–40 row is b3a1's own diagnostic of the same file; I reproduced its 41–80 row exactly.)

**The path and the ablations** (seeds 41–80 / 81–120; taken a match, Konpaku lost a match):

| build | taken | Konpaku | signature | note |
|---|---|---|---|---|
| b3a1 | 424 / 438 | 0.170 / 0.225 | 0.9979 / 0.9980 | |
| v1: + the sniper's step, the blow-away aim, the burst read on perception only | 392 / – | 0.130 / – | 0.9983 | the burst read fired 0.05 a match: the hitstop (above) |
| v2: + the burst read on his own push first | 368 / 380 | 0.142 / 0.117 | 0.9990 / 0.9984 | eval **0.9991** (sig 0.998); post-BLUE 44 → 23 |
| v3: v2 + b0a1's attack read in the hunt (no stance into his startup / projectile) | 394 / – (seeds 1–40: 420 vs 392) | 0.175 / – | 0.9981 | **dropped**: a measured negative on this lineage |
| **v4 = final: v2 + the TAISHA read + the burst wait yields to his rush** | **367 / 380** | **0.147 / 0.115** | **0.9991 / 0.9982** | eval **0.9992** |
| final, no burst read | 387 / 409 | 0.125 / 0.098 | 0.9983 / 0.9982 | the burst read: −20 / −29 taken |
| final, no sniper's step | 391 / 422 | 0.193 / 0.185 | 0.9987 / 0.9985 | the step: −24 / −42 taken, −0.05 / −0.07 Konpaku, 3 revivals → 0 |
| final, no blow-away aim | 376 / 371 | 0.150 / 0.105 | 0.9984 / 0.9984 | robustness-neutral (±9): it is the style piece |

Read: the sniper's step and the burst read carry the robustness; the blow-away aim moves the X-Axis share to the charged
shot (HIRENKYAKU → the charged X-Axis shot from range) at no robustness cost; the TAISHA read is inert against the frozen
CPUs. Wins are saturated (400 / 400 everywhere), so damage taken and Konpaku lost are the columns that move.

**Style (the coordinator's question)**, the eval's 40 seeds:
- **The charged X-Axis shot doubles: 4.6 % → 8.6 % of his damage** (6.9 fired, 6.1 hits a match; b3a1 4.2 / 3.4): every
  base-form blow-away now ends in a shot from range on the wake-up, the stance held and dashed back.
- **The X-Axis share** (TAISHA + charged + HIRENKYAKU + traces + SANREN + NIJŪSHI-KŌ) is **34.4 %** (b3a1 34.5 %): the same
  share, with the iconic charged shot replacing HIRENKYAKU. Trace combos (trace → TENSHIN → KIN, both modes) 23.5 %.
- **The HOSHA loop** (bullets + links) is **39.8 %** (b3a1 39.1 %): the close step's dash-back HOSHA replaces a point-blank
  TAISHA, +0.7 points. It does not lean back on the loop (b0a2 75 %, b2a1 76 %).
- The pendulum, the web and KIN's snipe are b3a1's, unchanged (crossfires 3.7, web lays 5.7, routes 7.9 a match).

**Host tests:**
- duel-rules **6388 ALL PASS**. The LILLE-CPU-TESTS section is b3a1's (spliced with `splice-tests.py`, nothing removed or
  changed) plus 4 new checks: the four new levels 0 / 0 / 1 and no brain → 0; the burst read (the wait 30 > the burster's
  invulnerability, the push inside the wait, the look-back inside the ring of 32 at HARD's delay, `LB-AI-BREAK-FREE-P` on
  11 cases); the blow-away aim (`LB-AI-BLOW-FIRE-P` on 8 cases, the shot's startup 10, the 90 f hold covering a down and a
  wake-up, the charge inside the hold); the TAISHA read (`LB-AI-TAISHA-PLAN`). Splicing the delivered file's section into
  the frozen test gives the delivered file byte for byte; the section diff only adds lines.
- duel-control 89 and learn 100: ALL PASS. `tools/pkgcheck.sh duel`: 0 / 0 / 0.
- **The awaken A/B was not run.** The awakening and the revival are untouched, and the A/B runs at NORMAL, where this CPU is
  the shipped one bit for bit (the drift's 400 NORMAL matches are identical).

## 4. Why it is not a repeat

- **Located in the parent's own held-out logs**, each fix aimed at one leak, measured in damage taken, Konpaku lost and by
  the opponent's whole combo; no b3a1 knob was retuned.
- **New:**
  - **the sniper's step**: a located gap in the hunt's override (it began at 2 m, so the shipped point-blank TAISHA
    fired), not reported by any cell; the largest robustness piece here (−24 / −42 taken, −30 % Konpaku);
  - **the blow-away aim**: a located bug of this lineage (the loop's latched stance planned TAISHA into a blown-away
    opponent, eating the wake-up shot's window); fixed with a held, dashed-back charged shot timed on the perceived wake-up;
  - **the burst read on perception**: b2a1 read the opponent's burst gauge; here it is read from his own push and the
    perceived break, as the brief asks, and I found and measured why perception alone is too late (the burst's hitstop);
  - **the TAISHA read**: an adaptive read of his answer to TAISHA, on his own state.
- **Credited:** b2a1's burst-read idea and its 30 f window; b3a0's spacing rule (the dash-back HOSHA) reused for the close
  hunt; b1a1's wake-up timing (`LB-WAKE-LEFT`) reused for the held shot.
- **Measured negative, reported:** b0a1's attack read (no hunt into his startup or projectile) costs this lineage +26 / +28
  taken a match (seeds 41–80 / 1–40): dropped.

## 5. Expected benefit

At HARD he plays b3a1's sniper with better discipline: he stands while a burster is invulnerable, leaves point blank with
his vanish-dash before he raises the stance, and meets every blow-away with the charged X-Axis shot from range on the first
frame the opponent can be hit. 1200 / 1200 HARD CPU matches won over seeds 1–120, 99.8–99.9 % of his damage his signature,
damage taken −13 % and Konpaku lost −34 % on held-out seeds. EASY and NORMAL are unchanged.

## 6. Risks

- **Pacing**: NORMAL is the shipped CPU, so the medians are the baseline's: LI 209.0 and LR 198.1 (cap 240), LS 194.7
  (cap 220). None is within 15 s of its cap.
- **The 40-seed score is 0.0003 below the parent's** (signature 0.998 vs 0.999, KIN's starved neutral strings on those
  seeds); on held-out seeds the signature is higher. Within the noise of a 400-match block.
- **The burst read's own-state cue**: "free and still being pushed" is REPEL!'s push in practice (my trace: every case was a
  BLUE), but any push of a free Lille would also make the base form stand still for its frames (`:NONE`); the eye still
  answers threats first and his rush is never waited on.
- **The held stance on a blown-away opponent**: up to ~60 frames in the stance (no guard) while he is down. Nothing of a
  downed opponent can hit him, but a hazard left on the floor (a pillar) would not be answered in that time (as b3a1's
  wake-up wait).
- **`:NONE` waits**: the burst wait (≤ 30 f, 2 a match) pauses the generic reflexes and AI-DECIDE's neutral; the learner's
  read runs before the kit reflex.
- **HARD may be too strong for a human** (inherited). The new pieces are answerable: the held shot's lock is visible 10 f
  before it fires (a waking human can Step), the dash-back HOSHA is a visible vanish.
- **The ASSIST**: no new hook it calls; every new branch reads `(brain e)` or the reflex's own brain (`LB-AI-KAMAE` is the
  stance's CPU branch). b3a1's `:sp-ender` is unchanged: re-run `tools/assistgate.py` at integration as for b3a1.
- **Overfitting**: measured only against the frozen CPUs; every robustness number above is on seeds the evaluator does not
  use.

## 7. Shared-code recommendations (not done)

1. **The burst's hitstop and the perception delay**: the brains don't step during hitstop, so a CPU's first free step after
   an opponent's burst still perceives the pre-burst reaction (8 f of SNAPs). A burst field in the SNAP (or counting
   hitstop frames into the perception) would let every kit read it without its own-state workaround.
2. An ORANGE kit key (`:orange` by difficulty), so the composure's held J can go (every cell's recommendation).
3. The generic guard-break / anti-parry reflexes press a Breaker without asking `KIT-COMMAND-OK-P` (b0a1 / b1a2 / b3a1).
4. A wake-up field in the SNAP (frames to his first hittable frame), so no kit re-derives `*REACTION-FRAMES*` for okizeme.
