# b0a0 (round 1, restart on decisions 41-43): mark, spring, strike, vanish; and the hunt's HOSHA loop

A new direction from the baseline. The only changes are to his CPU in `duel/lisp/lille.lisp`:
- three new `:ai` keys (`:hunt` on the base form, `:mark` on both EN forms, `:vanish` on both KIN forms; the MUJITTAI
  forms inherit them);
- new `LB-AI-*` functions in a new section at the end of the AI section;
- the `(brain e)` branches of `LB-EN-TICK` (the spring), `LB-AI-KAMAE` (the hunt's plan) and `LB-LINK-TICK` / `LB-AI-LINK`
  (the HOSHA loop);
- the dispatch in `LB-AI-REFLEX`, `LB-AI-EN` and `LB-AI-KIN`.

No rule, frame, damage, cost, opponent-facing key (`:opp-trace :opp-reflex :opp-reflect :opp-aim`), `LB-OPP-TRACE` or
shared file changed. The awakening (`AI-AWAKEN-P`, `:awaken`) and the revival (the generic `:bankai` reflex) are untouched.
The test's LILLE-CPU-TESTS section gains 7 checks (6369 → 6376, ALL PASS) that pin the new keys and pure functions; every
earlier pin in the section is kept unchanged.

**Score 0.9612** = strength **0.970**, masher 1.000, signature **0.933**. The baseline is 0.4496 = 0.105 / 1.000 / 0.519.
Drift and pacing are bit-identical to the baseline.

## The history read, and what it implied

- **Rounds**: this is round 1 of the restart. `rounds/` holds no scored cell; b1a0 runs in parallel.
- **The baseline** (`baseline/proposal.md`, `score.json` 0.4496). I reproduced it with a scratch diagnostic: HARD, both
  seats, 10 seeds, 12 / 100 wins, dealt 2417 / taken 3373 a match, signature 0.511, plain J / K 40 % of his damage. The
  per-match counters:
  - EN switches in 10.8 times, 6.8 of them on a trace hit;
  - HOSHA 1.75 uses;
  - the eye: 0.7 plans;
  - the starved switch-in 1.3.
- **archive/v1 b0a0** (0.9124 on decision 39's rules): EN's `:moves` J / K never fired at range, because AI-ATTACK's reach
  filter drops a J / K beyond its 1.6 / 2.2 m reach. It added a "snipe", a KIN "back" switch, the base HOSHA hunt, a K1
  link, and SP enders. The located bug, the reach filter, is still there; it is shared code, so EN's ranged J needs its own
  reflex.
- **archive/v1 b1a0** (0.9027): the snap opener (EN J1 straight at him, the 2 f cancel), KIN hit-and-run, and the base
  HOSHA at 3-7 m. It also measured two dead ends:
  - "HOSHA's link always K1": worse, because without an L after it the K string after K1 is plain and drops;
  - the "wary" two-miss rule: neutral.
- **What changed since v1.** Both v1 openers rode the laying shot's 10 f flinch, which is gone. Decision 41 replaced it
  with a ≤ 10° snap toward him at the materialise. I worked out the frames before reusing the idea:
  - J1 is S4 A3, and the cancel's wind-up is 2 f, so the line materialises **9 f** after the press (pinned in the test).
  - A HARD CPU perceives J1's start 8 f late, and its `LB-OPP-TRACE` waits for the line to be seen (age ≥ its delay). So
    no CPU can leave the line before it materialises.
  - The snap widens the line by 0.87 m at 5 m and 1.7 m at 10 m.

  So the opener does not need the flinch. It needs an EN reflex (the reach filter) and a spring rule that does not need
  ≥ 3 traces. I re-tested it on today's rules instead of assuming the old numbers.

## The action policy (HARD; EASY and NORMAL are the shipped CPU, bit for bit)

Every new layer is a kit key whose `:by` plist gives its level by difficulty: `(:easy 0 :normal 0 :hard 1)`, read by
`LB-AI-BY`. So EASY ≤ NORMAL ≤ HARD. At level 0 the code takes the shipped path and draws exactly the shipped random numbers:
- the drift (Y 39, K 32, R 27, I 28, S 39 of 80) is identical;
- the pacing medians are identical.

Every new rule is deterministic on what the CPU perceives (the delayed SNAP; `LB-AI-SEEN` inside the ticks). None rolls
per step.

**Base 万物貫通: the hunter** (`:hunt (:near 0 :far 7.5)`, `LB-AI-HUNT`, `LB-AI-HUNT-PLAN`, `LB-AI-LOOP-P`)
- After the eye (which still answers threats first), he opens the shooting stance onto a perceived open opponent within
  7.5 m: not stepping, Hoho-ing, guarding, down or launched, with no threat of his near.
- At the stance's f6 the branch is HOSHA (the 5 m leap and its three bullets) onto an open opponent within 8 m, or onto a
  reeling one within 8 m (after a K link: the bullets and the link are his signature, the quick shot is not). Into a
  perceived guard, the shipped plan stays.
- **The HOSHA loop** (new): HOSHA's link is K1 with L latched on it at once (`FIGHTER-QUEUED :sig`, the K → L latch any
  human can press). The K link's hit reopens the stance at its f4, whose branch is HOSHA again: bullets → K1 → L → bullets
  …, with every hit tagged (LB-K-J, hosha-link), until the combo drops or the victim bursts. This is v1-b1a0's failed
  "K1 always", fixed: the L latch stops the plain K string after K1.
- 36 stances, 35 HOSHA and 26 links a match, 22 of the links in combos.

**Jilliel / owl 遠 EN: the mark and the spring** (`:mark (:near 1.5 :far 13.5 :gap 0.6)`, `LB-AI-MARK`, `LB-AI-SPRING`)
- **The mark.** When free, he presses J1 onto a perceived open opponent at 1.5-13.5 m: no threat near, and a J line
  affordable above the shipped 10 flash-step reserve. Its one line is laid straight at him. 13.5 m is inside TENSHIN in's
  13 m + 1.5 m stop, so KIN's J1 still reaches him.
- **The spring.** In `LB-EN-TICK`, from any EN attack's active end: if the perceived opponent is within 0.6 m of a live
  line as it would materialise (`LB-AI-TRACE-GAP` with the snap) and open, TENSHIN's 2 f cancel fires. Into a guard he
  waits: a guarded trace only chips, and the dash would land him beside the guard. The line stays for the next spring.
- The shipped rules come first and are kept: the ≥ 3-trace switch, the via-J switch and the stance reflex. The starved
  switch-in (into KIN with nothing) is NORMAL-only. At HARD he never enters KIN without a hit.
- Then the shipped link (`LB-AI-LINK-PLAN`: J1 after a materialised hit) gives trace → dash → KIN J string, the trace
  combo.
- 14.0 marks and 11.9 springs a match; 14.0 trace hits (1.0 guarded); 12.0 trace combos.

**Jilliel / owl 近 KIN: the vanish** (`:vanish (:fs 13)`, `LB-AI-VANISH`, `LB-AI-CASH-P`)
- He leaves KIN (TENSHIN out: 10 m, iframes f0-8) as soon as he is free with 10 + 3 flash step (the out price + the next
  mark) and nothing to cash.
- "Cash" means him reeling or recovering within J1's reach + 0.6 m for its startup (the generic punish), or reeling in the
  Kikon range while the Kikon is ready (the red rush). Those stay the generic reflexes' job.
- KIN is the stage of the trace combo, never neutral: 16.6 vanishes a match. He spends only ~34 frames a match in KIN
  short of the 13 flash step.

**MUJITTAI, Trompete, the eye, the awakening, the revival**: as shipped. HARD reaches EVOLUTION ~52 s in (by the gauge;
the hunt keeps him busy, so the eye is rarely tapped).

**Adaptation.** Every rule reads the opponent's perceived state, once per event:
- no mark or hunt into a guard, a Step or a Hoho;
- the spring waits while he guards;
- the vanish yields to a punish or a red rush.

I also built a remembered read, measured it, and dropped it: after a spring that missed, the next mark lays K's fan of
three. At 40 seeds it went 381 / 400 against 388, because the fan's 9 flash step costs more than the misses it saves.

## Measurement (EVAL_COMMAND, 40 seeds; `score.json` is the last line it printed)

| | baseline | b0a0 |
|---|---|---|
| score | 0.4496 | **0.9612** |
| strength (HARD, both seats) | 0.105 | **0.970** (388 / 400: Y 73, K 78, R 80, I 77, S 80 of 80) |
| masher | 1.000 | 1.000 |
| signature | 0.519 | **0.933** |
| drift (NORMAL share) | 0.4125 | 0.4125 (identical, every opponent) |
| pacing Y / K / R / I / S (s) | 176.8 / 170.2 / 216.2 / 203.9 / 196.8 | identical, all K.O. |

`sig_by` baseline → b0a0:

| category | baseline | b0a0 |
|---|---|---|
| plain-jk | 0.398 | 0.063 |
| trace-combo | 0.177 | 0.259 |
| lb-trace | 0.103 | 0.097 |
| lb-k-j (HOSHA) | 0.029 | 0.268 |
| hosha-link | 0.020 | 0.229 |
| lb-w-kikon | 0.061 | 0.047 |
| breaker | 0.037 | 0.004 |
| counter | 0.034 | 0.000 |

HARD per match (40 seeds, my diagnostic, the same sims): dealt 2417 → 4590, taken 3373 → 1179.

Path inside the cell. Steps marked 20 seeds are the diagnostic, which reproduces the evaluator's strength exactly at 40
seeds; within ±4 / 200 is noise.

| step | wins | signature | |
|---|---|---|---|
| baseline | 12 / 100 | 0.511 | |
| + mark / spring / vanish / hunt (HOSHA at 2.5-7.5 m) | 97 / 100 | 0.818 | |
| + the HOSHA loop (K1 + L latched) | 96 / 100 | 0.923 | full eval **0.950** (0.948 / 1.0 / 0.927) |
| + hunt from 0 m | 194 / 200 | 0.931 | kept |
| mark far 15 / gap 0.9 | 193 / 194 of 200 | 0.931 | noise, not kept |
| KIN vanish even over a J1 punish | 189 / 200 | 0.932 | worse |
| the patient long shot (stance held at 7.5-20 m for a committed opponent) | 188 / 200 | 0.921 | worse: the stance at range costs; the committed moment came 0.04 times a match |
| the fan read after a missed spring | 381 / 400 | 0.932 | worse (v3 388 / 400, 0.933) |
| vanish :fs 20 / hunt far 6.5 / far 8.0 (40 seeds) | 384 / 376 / 380 of 400 | 0.925 / 0.931 / 0.925 | worse |
| **final (v3)** | **388 / 400** | **0.933** | **0.9612** |

Host tests: duel-rules 6376 ALL PASS, duel-control 89, learn 100; `tools/pkgcheck.sh duel` 0 / 0 / 0. I did not run the
awaken A/B: neither the awakening nor the revival changed, and the A/B runs at NORMAL, where this CPU is the shipped one bit
for bit (the same NORMAL matches as the drift).

## Why it is not a repeat

The v1 cells' openers rode a rule that is gone. This cell:
- re-derives the EN opener on decision 41's snap: the 9 f arithmetic, and a spring rule on the gap as the line will
  materialise, with no trace count;
- combines it with v1's KIN short visit and base HOSHA hunt;
- adds the **HOSHA loop**. It fixes the located failure of v1-b1a0's "K1 always": the plain K string after K1. Latching L
  on the K1 link turns HOSHA's 4.9 % share into 50 % of his damage (bullets 26.8 % + links 22.9 %).

Its knobs were then measured at 40 seeds, not tuned by eye. Three structurally different additions were measured and
dropped, with their numbers above: the patient long shot, the KIN no-punish vanish, and the fan read.

## Expected benefit

His HARD CPU plays the sniper as a hunter:
- the base form's leap-and-fire loop up close;
- the X-Axis mark and the trace → TENSHIN → J combo at any range up to 13.5 m;
- KIN as a strike stage he leaves at once.

He wins 97 % of HARD CPU matches, and 93 % of his damage is his signature. NORMAL and EASY are unchanged.

## Risks

- **Pacing**: the medians are the baseline's, because NORMAL is unchanged. LR 216.2 (cap 240), LI 203.9 (cap 240) and
  LS 196.8 (cap 220) are within ~25 s of their caps. This is the baseline's risk, not a new one.
- **HARD may be too strong for a human.** The mark materialises 9 f after the press, before any reaction. That is EN's rule
  for a human too (decisions 30, 41). A human can stand off his facing line, or guard at range: the mark refuses a guard.
- **The HOSHA loop** gives very long base combos (up to a blow-away or a burst). A burst-happy human breaks it. Its damage
  is combo-scaled as usual.
- **ORANGE**: the generic `AI-ORANGE-P` fires on a HOSHA bullet's hit (a `:sig` hit with the victim within Q1's reach). It
  spends 70 flash step and replaces the loop with a plain J1-J2-K3. The kit can't refuse a burst (it doesn't pass through
  `:ok`), so that is in the recommendations.
- **Determinism / learning / ASSIST**: no new hook the ASSIST calls (no `:sp-ender`, `:sig-hold` or `:assist-guard`). Every
  new branch reads `(brain e)` or the reflex's own brain, so it never acts for a human. The hunt and the mark answer free
  steps only while their conditions hold and return NIL otherwise. They never reset BRAIN-DECIDE-T, so AI-DECIDE and the
  learner's read clock still run. All randomness stays SIM-RND01. At level 0 none is drawn by the new code.
- **Overfitting**: measured against the frozen opponents only. They have no answer to a line younger than their
  perception delay.

## Shared-code recommendations (not done)

1. A per-kit opt-out of ORANGE off a `:sig` hit (or `:orange` difficulty in the kit's `:ai`). His own ORANGE breaks his
   signature loop and spends the flash step EN needs later.
2. AI-ATTACK's reach filter makes a kit's ranged "J / K that isn't a hit" (EN's lines) dead in `:moves`. A per-move flag
   (`:params :lay t`) would let EN's tables mean what they say at NORMAL too, without a reflex.
3. If the user wants the mark answerable by CPUs: an opponent CPU reading EN's J1 start at range as a line threat, which
   would be a deliberate opponent change.
