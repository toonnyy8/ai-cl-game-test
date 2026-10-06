# The per-character AI, v2 (the user, 2026-10-02)

The user: "請萊醬你用現在的設計邏輯與每個角色的特色規劃出新的 AI 設計與行動方針。並將這套改良版的 AI 與學習型 AI 整合後也整併到
auto 的輔助模式中。可以開啟 subagents 與 /anthropic-skills:dream-rsi 進行每個角色與連段應用的辯思與測試，並將這些經驗一同整合的
AI 的設計中。"

**Decisions (the user, 2026-10-02):**

- **Score.** Win rate + character colour. `tools/aieval.py`: 0.6 strength + 0.2 masher + 0.2 signature, 0 when the
  pacing check fails.
- **Budget.** 2 dream-rsi rounds x 4 variants per character.
- **Strength by difficulty.** EASY keeps its gaps, NORMAL stays near today's level, HARD is the full version.
- **Parallelism.** 5 subagents, one per character, each in its own git worktree.

**Method:**

- **The search.** Each character has a dream-rsi workspace (`docs/research/ai-v2-drsi/<character>/`). A cell is one
  variant of that character's `duel/lisp/<file>.lisp` AI: its forms' `:ai` tables and their reflex functions. The
  evaluator is `tools/aieval.py --char i`, run on the native sim against the other four characters' current CPUs.
- **After the rounds.** The best variant per character is merged. Then the learning CPU and the ASSIST auto mode take
  over its choices, and the full gates run.

**Baseline scores (main 0462476, 20 seeds):**

| character | score | strength (HARD) | masher (HARD) | signature |
|---|---|---|---|---|
| Yamamoto | 0.595 | 0.531 | 0.800 | 0.580 |
| Kenpachi | 0.291 | 0.175 | 0.400 | 0.528 |
| Rukia | 0.765 | 0.831 | 0.887 | 0.441 |
| Ichigo | 0.477 | 0.450 | 0.525 | 0.507 |
| Senjumaru | 0.571 | 0.512 | 0.700 | 0.619 |

## What shipped (2026-10-02)

**The chosen cells** (`docs/research/ai-v2-drsi/<character>/rounds/...`; each copied over `duel/lisp/<file>.lisp`):

| character | cell | search score (20 seeds) | strength / masher / signature |
|---|---|---|---|
| Yamamoto | round 1 b0a2, plus round 2 b0a0's NORMAL fix | 0.8989 | 0.969 / 1.000 / 0.588 |
| Kenpachi | round 2 b0a0 (80 seeds vs round 1 b0a2: 0.749 vs 0.747) | 0.8582 | 0.938 / 1.000 / 0.479 |
| Rukia | round 2 b0a0 | 0.9533 | 0.981 / 0.988 / 0.835 |
| Ichigo | round 1 b0a1 | 0.8158 | 0.831 / 1.000 / 0.585 |
| Senjumaru | round 2 b0a0 | 0.8096 | 0.856 / 0.800 / 0.679 |

Each search score was measured against the other four characters' *shipped* CPUs.

**The action policy (行動方針) per character.** Every new rule is a chance by difficulty (EASY <= NORMAL <= HARD).

- **Yamamoto: fire where it lands, the rush only where it lands.**
  - `YAMA-ANTI-BREAKER`: J1 timed so its active frames meet the Breaker. The dash he can't see yet is counted. HARD
    0.85; NORMAL 0 (round 2's fix, which brought NORMAL back to the shipped level), so NORMAL keeps the generic J1.
  - `YAMA-STUN-SP`: a stun beyond J1's follow-up reach gets the form's paid SP (the Shikai's / Hellfire's cone, East's
    KYOKUJITSUJIN) if it lands before he is free. HARD 0.7.
  - `YAMA-RUSH-VETO`: the rush on a red opponent goes only where it lands: TENCHI from beyond 5 m, ENJO from 1.5 m, or
    either on a stun or recovery it reaches in time. A vetoed neutral rush becomes the band's attack pick. HARD 0.9.
  - `YAMA-SP-ENDER`: a pushing J3 / K3 is confirmed with the paid SP when the bars are there, else the O ender (never
    ENJO off J3).
- **Kenpachi: the reach model, and his signature moves as the punish.**
  - `KEN-ANTI-BREAKER`: K1, else J1, else a Hoho, by where the Breaker will be.
  - `KEN-HOHO-COMMIT`: a Hoho into a K / L / SP's perfect lead.
  - `KEN-ANTI-MASH`: the stance against a J masher.
  - `KEN-NO-RESET`: guard instead of a slow J1 reset.
  - The punishes: the charge (SP2) inside J1's lunge (`KEN-SIG-PUNISH`); beyond it, the charge / the line cut / the leap
    (`KEN-FAR-PUNISH`); the line cut first where SP1 is one.
  - In neutral: the first strike timed to his closing speed, the J1 lunge, the walk-in.
  - The enders: SP1 (Buttagiru / Meteor / TATE-GOTO) when it fits the ender's reel, else the O ender, else the charge.
  - The Bankai only as a finisher at HARD.
- **Rukia: the perfect-Hoho counter-fighter, the cold answers.**
  - The timed Hoho into a Breaker, a committed move, or a masher's next J. Then she cashes the stun or recovery with
    her ice (SHIRAFUNE / HYOSHIN / the O).
  - -50's Hoho dive to -273.
  - The Shikai's HAKUREN wave at range (HARD 0.5).
  - The bands' L disc as the close opener (HARD 0.5).
  - At zero: REIDO on a ward block (24-tick window) and against a Breaker.
  - The enders: L after a K ender, SHIRAFUNE after a J ender, else the O.
- **Ichigo: the reactive layer and the red phase.**
  - The timed perfect Hoho; KESSA's parry; the long punish.
  - Against a masher: the parry, or the K1 poke.
  - The chasing `:sp-ender`: SOGA or the O poke in the Shikai, KUSARI-BIKI in KESSA.
  - The red phase: guard his rush, or WHITE.
  - Converting a red opponent: rush only when he is busy longer than the rush takes. Every new rule is HARD-only.
- **Senjumaru: J1 up close in the Shikai, the late awakening, the loom's endgame.**
  - The Shikai's neutral bands lean on J1 (HARD 0.7 of the decisions).
  - The O ender / the stitches' L off a pushing ender.
  - The far punish (K1, else the O); SAIDAN on a long guard.
  - The O meets his Breaker.
  - The awakening at a Reishi share <= 0.28 (HARD).
  - The loom: a Hoho / Step through his Breaker's dash, and the lane's Kikon on a red foe (HARD 0.8).

**Two fixes made while integrating:**

- **Senjumaru's late awakening (`SENJU-AWAKEN`).** It now goes through `AI-AWAKEN-P`, so the awaken A/B's never / always
  mode holds for her too. The cell's version ignored it, and her "never" rows awakened anyway.
- **`RUKIA-AI-ZONE`'s unused argument is declared.** The build has 0 warnings again.

## NORMAL stays near the shipped CPU

Each character's NORMAL CPU against the other four NORMAL CPUs, both seats, 40 seeds (320 matches). The table gives its
win share.

| character | all shipped files | all new files (as delivered) | final |
|---|---|---|---|
| Yamamoto | 0.431 | 0.356 | 0.431 |
| Kenpachi | 0.397 | **0.806** | 0.422 |
| Rukia | 0.603 | 0.578 (**0.703** once Kenpachi's NORMAL was cut) | 0.637 |
| Ichigo | 0.569 | 0.416 | 0.537 |
| Senjumaru | 0.500 | 0.344 | 0.472 |

- **Kenpachi.** His per-step neutral rolls fire at almost every step at NORMAL. With all his NORMAL chances at 0 he
  scored 0.366; with only the per-step ones at 0, 0.388; with the per-step ones at a tenth, 0.500.
  - The J1 lunge in neutral and the first strike against a non-masher are what made NORMAL strong.
  - Final NORMAL values: lunge 0, first strike (non-masher) 0, walk-in 0.005, stance vs a masher 0.005, first strike vs
    a masher 0.002. The per-event chances are as delivered.
- **Rukia.** Every NORMAL chance halved: L after a K ender 0.02, SHIRAFUNE after a J ender 0.15 (EASY 0.1), the O
  ender 0.02, the timed Hoho on a Breaker / move / masher 0.05 / 0.02 / 0.02, the ice cash 0.05, the cash O 0.02, zero's
  ward REIDO 0.02, zero's anti-Breaker REIDO 0.05.

**HARD strength against the new set** (`aieval --char i --seeds 40`). There is no target here: the other four are the
new CPUs too, so each number is below its search score.

| character | score | strength | masher | signature | NORMAL pacing |
|---|---|---|---|---|---|
| Yamamoto | 0.616 | 0.512 | 0.994 | 0.547 | ok |
| Kenpachi | 0.762 | 0.781 | 0.994 | 0.471 | ok |
| Rukia | 0.763 | 0.669 | 0.994 | 0.816 | ok |
| Ichigo | 0 (pacing) | 0.312 | 1.000 | 0.560 | IR 39 / 40 K.O. (one time-up), median 198.4 s |
| Senjumaru | 0.432 | 0.225 | 0.831 | 0.655 | ok |

## The learning CPU and the new AIs

**The problem.**

- The learner's neutral read (`LEARN-NEUTRAL`) used to run inside `AI-DECIDE`.
- The new kit reflexes take that decision over at its tick: they reset `brain-decide-t` and pick themselves (Yamamoto's
  rush veto, Rukia's zone wave and band disc, Ichigo's conversion, Senjumaru's neutral bands and red rush). Or they
  `:wait` every step: Kenpachi's walk-in. Then `AI-NEUTRAL` doesn't run at all, and its clock stops.
- With the new files and nothing changed, the HARD learner made fewer reads (Kenpachi 606 -> 348, Senjumaru
  452 -> 240) and fewer of them paid off (Kenpachi 172 -> 66, Senjumaru 137 -> 48).

**The generic fix** (ai.lisp; no character file touched):

- The neutral read runs on its own clock in `AI-REFLEX`, before the kit's `:reflex` (`LEARN-READ-DUE`). It needs:
  - both fighters free;
  - no Kikon rush on a red opponent and no pip hurry first (`AI-DECIDE`'s order);
  - no scripted habit.
- Its interval is `*AI-THINK*` + up to 40 frames, drawn from the learner's own stream.
- A read that presses makes the decision: the brain's decide clock is reset (`AI-DECIDE-TIME`, now shared with
  `AI-NEUTRAL`), and the reflex returns `:WAIT`.
- `AI-DECIDE` no longer calls the read.

The rest already held:

- The planned counters (`LEARN-FIRE`) run in `BRAIN-STEP` before any reflex.
- The bandit weighs every pick made through `AI-ATTACK`, including Yamamoto's veto and Ichigo's conversion.

Without a learner nothing changes: the CPU gates are row-identical.

**The learning gate.** P2 is the character with the learner; P1 is the next roster character with habits 1-4; 10 seeds
per habit (40 matches per cell). Each cell gives P2's wins with the learner off (m0) / on (m1), its reads / paid, and
its reads per minute of play.

| P2 | shipped HARD | new, unfixed HARD | final HARD | shipped NORMAL | final NORMAL |
|---|---|---|---|---|---|
| Yamamoto | 20->23, 396 / 163 (4.5) | 20->17, 339 / 134 | 20->18, 404 / 172 (5.7) | 15->18, 360 / 156 (3.8) | 17->11, 338 / 134 (3.8) |
| Kenpachi | 3->5, 606 / 172 (7.4) | 34->23, 348 / 66 | 34->22, 380 / 57 (5.5) | 11->13, 505 / 225 (5.7) | 13->11, 546 / 206 (6.3) |
| Rukia | 28->27, 474 / 190 (4.1) | 38->31, 417 / 115 | 38->29, 425 / 103 (4.1) | 22->25, 457 / 279 (3.9) | 20->23, 489 / 272 (4.1) |
| Ichigo | 17->22, 514 / 199 (4.3) | 10->11, 469 / 175 | 10->13, 470 / 178 (5.0) | 23->25, 447 / 208 (3.8) | 23->21, 548 / 232 (4.9) |
| Senjumaru | 32->27, 452 / 137 (5.2) | 5->5, 240 / 48 | 5->9, 372 / 72 (4.9) | 29->30, 381 / 181 (4.4) | 28->25, 389 / 150 (4.5) |

- **Reads per minute are back to the shipped level or above**, except Kenpachi at HARD (7.4 -> 5.5).
- **Fewer reads pay off at HARD.** The scripted P1 is now a v2 HARD CPU, which answers a read more often.
- **At HARD the learner costs the strongest new CPUs wins against these scripted CPUs:** Kenpachi 34 -> 22, Rukia
  38 -> 29. Its counters (a guard for a predicted J, the Breaker for a predicted guard) take the place of their own
  better-timed answers. This is open for the user's decision (see the DEVLOG).

## The ASSIST auto mode and the new AIs

- **AUTO GUARD.** Under its trigger, AUTO GUARD first asks the form's own defensive answers (`AUTO-GUARD-KIT`). Then
  comes the generic parry / Hoho on `PERFECT-NOW-P`, then J back. A form names its answers with the kit's `:ai`
  key `:assist-guard`, a function (e b s d):

  | character | :assist-guard |
  |---|---|
  | Yamamoto | `YAMA-ANTI-BREAKER` (the timed J1) |
  | Kenpachi | `KEN-ASSIST-GUARD`: the anti-Breaker hit and the Hoho into a commit |
  | Rukia | `RUKIA-ASSIST-GUARD`: REIDO at zero, then the timed Hoho |
  | Ichigo | `ICHIGO-ASSIST-GUARD`: the timed Hoho and the red guard of a rush (`ICHIGO-AI-RED-GUARD`, split out of `ICHIGO-AI-RED`) |
  | Senjumaru | `SENJU-LOOM-ANTI-BREAKER` (split out of her policy reflex; the Shikai has none, since its answer is the O) |

  - Only defensive answers are listed. No neutral-decision takeover and no offensive reflex can fire from AUTO GUARD.
  - A kit `:wait` (the timed Hoho still waiting for its window) leaves the generic answer free to act.
  - The rolls are rolled as `AI-REFLEX` rolls them, one per action of his (`AI-EVENT-ROLLS`, shared).
- **AUTO COMBO.** The kits' CPU code reads `AI-BRAIN`: the assist's borrowed HARD brain while `ASSIST-STEP` runs
  (`*AI-BRAIN*`), else the fighter's own. This covers `:sp-ender`, `:sig-hold` and their difficulty lookups.
  - Ichigo's `:sp-ender` returned NIL without a brain. Senjumaru's would have hit NIL in `SENJU-DP`. Both now give a
    human's AUTO COMBO the HARD choices: Ichigo masher vs Kenpachi, 5 seeds, k11: 69 SOGA and 33 O.
  - The assist's learner (`*ASSIST-LEARN-TABLES*`) still feeds AUTO COMBO's reads through the same brain.
- **The price is unchanged.** Every assisted press still sets `FIGHTER-ASSIST-NEXT`.
  - Rukia masher vs Kenpachi, HARD, k11, 10 seeds: 133 assisted Hohos, none PERFECT. The HARD CPU had 43 perfect Hohos.
  - Its hits still deal x0.8.

**The gate** (`tools/assistgate.py`). The masher's wins out of 500, before (new AIs, old assist) -> after:

| | k0 none | k2 GUARD ALWAYS | k11 ALWAYS + COMBO + BREAK |
|---|---|---|---|
| vs HARD | 4% -> 4% | 42% -> 41% | 61% -> 62% |
| vs the masher (--p2-dumb 1) | 40% -> 40% | 59% -> 59% | |

The kit answers fire (5 seeds per pairing, HARD, k2): Yamamoto's and Kenpachi's anti-Breaker J1, Rukia's timed Hoho,
Ichigo's red guard (7) and timed Hoho. Their effect on the masher's wins is within noise. The masher with no assist
fell from 28% (DEVLOG §76) to 4% against the v2 HARD CPUs.

## Gates (final)

- **Seed gate** (`simgate.py`): all 300 matches K.O.
  - Cross-pairing medians: YK 159.5, RY 163.1, RK 150.3, IY 178.9, IK 170.0, IR 206.2, SY 170.7, SK 160.1, SR 194.9,
    SI 182.4 s, all <= 210.
  - Mirrors: YY 139.0, KK 151.6, RR 208.2, II 213.0, SS 206.4 s.
- **Awaken A/B** ("never" wins of 60, streams 100 / 300 / 500):

  | pairing | wins |
  |---|---|
  | RY | 36 / 35 / 30 |
  | RK | 36 / 38 / 40 |
  | RR | 30 / 30 / 34 |
  | SY | 31 / 27 / 29 |
  | SK | 24 / 25 / 29 |
  | SR | 23 / 28 / 20 |
  | SS | 29 / 38 / 31 |
  | SI | 33 / 29 / 31 |

  - Before Senjumaru's awakening fix SR was 21 / 24 / 18.
  - Ichigo's rows fail as before: IY 7 / 13 / 15, IK 17 / 17 / 16, IR 7 / 5 / 4, II 9 / 9 / 9. On main's files, stream
    100: 10 / 16 / 6 / 6.
- **Host tests:** rules 4433, control 86, learn 100, input 33, all pass.
- **The build:** `./build.sh duel`, 0 warnings.
- **G2:** refreshed and `simgate.py --cvc` passes. yy P2 0-9 124.7 s, yk P1 1-0 136.3 s, kk P1 7-0 158.4 s.

## The cells' shared-code recommendations

| recommendation | from | done? |
|---|---|---|
| A late / geometry-checked generic anti-Breaker J1 (or a kit `:anti-breaker` answer) | Senjumaru, Yamamoto | no: each kit answers in its `:reflex`; AUTO GUARD now offers those answers |
| A wider `:ward-reversal` window (the brain misses the 1-tick window in hitstop) | Rukia | no: her zero reflex has its own 24-tick window |
| An `:awaken-p` kit hook (the awakening as a combo breaker) | Senjumaru | partly: `SENJU-AWAKEN` goes through `AI-AWAKEN-P` (the A/B modes); no combo-break hook |
| An explicit `:wait` command | Yamamoto, Rukia | used as is (`AI-COMMAND` ignores it; the learner's read returns it); AUTO GUARD treats a kit `:wait` as "not yet" |
| Difficulty-scaled `:o-ender` / `:string-k` / `:l-after-k` | Kenpachi, Rukia, Ichigo | no |
| A `:decide` hook instead of re-timing `brain-decide-t` from `:reflex` | Rukia, Yamamoto, Ichigo | no; the learner no longer depends on the decision tick (its own clock), and `AI-DECIDE-TIME` is shared for kits that want it |
| A string-link hook in `STRING-REFLEX` | Yamamoto, Kenpachi | no |
| Gate on 60-80 seeds | Kenpachi, Senjumaru | this integration used 40-80 |

## :x-axis lines and the keys a sniper's kit sets (2026-10-06, the Lille Barro build; DUEL_LILLE §11.3, gaps G1 / G8)

The user asked for Lille Barro (DUEL_LILLE.md), whose shots are 31 m line hit windows. Every key below is inert for a move
or a kit without it: today's five characters keep their pairings byte for byte (`simgate.py --seeds 10` and G2 identical).

- **Threat perception (G1).** A move flagged **`:x-axis`** would be "in reach" everywhere (reach 31 m + 1.5 m), and an aim
  (a `:hold` move) would be a threat from its first frame, so every CPU would guard through each aim and block the shot.
  Every threat reader now asks `snap-live-p` / `snap-near-p` (ai.lisp). A move without the flag takes the old test, the
  same expression (`sf < active-end`, `d < reach + margin`). A line uses:
  - **its real threat window** (`x-live-p`, kit.lisp): a `:hold` aim only from its **lock** (`:params :lock`, else its
    minimum hold), the move proper until its last hit window ends (`move-active-end`: SANREN's three lines), a wind-up
    with a `:params :lock` (Trompete's f40) only from the lock;
  - **the point-to-line distance** (`x-line-gap`): the CPU's feet against every `:cap` volume of the move, from his
    perceived feet along his perceived yaw (a 6th volume element, when there is one, turns that line: the volley's fan).
    On the line = within its radius + the CPU's hurt radius + `*ai-line-margin*` 0.3 m.
  - Readers: the generic guard / Hoho test (ai.lisp), `ken-hoho-commit`, Ichigo's perfect Hoho, KESSA's bank and WHITE
    tests, Rukia's perfect Hoho. KESSA's parry skips a line (`:ranged`: no parry catches it). `incoming-projectile-p` is
    unchanged: it counts the `:wave` / `:fireball` hazards only, and a line is a hit window.
- **`:reflectable`** (a move flag, with `:params (:blast f)`): the kits' timed Hohos and the generic threat Hoho leave it
  alone, so the reflect rate is `:opp-reflect`'s alone (Ichigo's HARD perfect Hoho would otherwise reflect every one).
- **`:opp-aim (:step 0.6 :hoho 0.25 :rush 12)`**, read off the opponent's kit (`ai-opp-aim`, after `:opp-reflex`). While he
  holds a `:hold` move flagged `:x-axis`, one `sim-rnd01` per aim (keyed on its start tick, `brain-aim-key`), each chance
  × `*ai-opp-diff*` (EASY 0.33 / NORMAL 1 / HARD 1.67, capped at 1; `opp-chance`):
  - r < `:hoho`, perceived before the lock, flash-step for one: a Hoho at once;
  - else r < `:hoho` + `:step`:
    - within `:rush` m, the rush at once (O within `:kikon-range`, else the dash in);
    - farther, a sideways Step off the line, away from its side (`line-off-strafe`), while it stands on it.
    - Timing: a delay ≤ `*ai-aim-react*` 8 (HARD) Steps on the lock it perceives. NORMAL / EASY pre-Step at a second
      roll's tick, lock + 0..`*ai-aim-pre-step*` 10, from his perceived start: they would see the lock too late.
  - Rooted forms (zero Rukia) never answer.
- **`:opp-reflect (:p 0.3)`**, read off the opponent's kit (`ai-opp-reflect`): one roll per `:reflectable` move at :p ×
  difficulty (0.1 / 0.3 / 0.5). A yes counts his move frame as perceived (`snap-sf` + the delay, `reflect-action`):
  - nothing pressed in the 6 f before the press (`*ai-reflect-quiet*`; a held guard is let go, so `fighter-guard-t`
    restarts);
  - a guard pressed `*ai-reflect-guard-lead*` 8 f before the blast (`fighter-guard-t` 8 at f60: the 2–10 window);
  - where it can't guard (a ward, a form whose U is a move, guardless): a Hoho `*ai-reflect-hoho-lead*` 10 f before (f50).
- **`:bankai-ok`** (a kit key, a function of the fighter entity): the Bankai entry reflex also asks it (NIL key: yes).
- Host tests (duel-rules-test): `line-dist`, `x-line-gap`, `x-live-p` (no threat before the lock), `line-off-strafe`
  (away from the line), `opp-chance`, `reflect-action`'s frames, and no form of the five has the flags or the keys.
