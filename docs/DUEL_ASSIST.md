# ASSIST: AUTO GUARD / AUTO COMBO / AUTO BREAK (the user, 2026-10-01)

The user: "I can't beat the CPU — perfect dodges, parries, guard breaks and flashy combos one after another. Plan an AI
assist so I can pull those off easily."

## Decisions (the user, 2026-10-01)

- **Three SETTINGS rows, each always in force when on** (not a held ASSIST button, not a co-pilot):
  - AUTO GUARD: OFF / HOLD U / ALWAYS. The trigger itself is a setting: HOLD U assists only while U is held; ALWAYS
    whenever the fighter is free.
  - AUTO COMBO: OFF / ON.
  - AUTO BREAK: OFF / ON.

  All three default to OFF and are saved like the other rows: `soulduel.autoguard`, `.autocombo`, `.autobreak`.
- **A price**: a move the assist pressed deals x0.8 damage (`*assist-mult*`). Its Hoho dodges but is never PERFECT: no
  counter strike, no refund, no slow motion. Playing it by hand still pays.
- **Offence is "you press, the CPU chooses"**: AUTO COMBO and AUTO BREAK act only on a J the player pressed.
- **Scope**: every human fighter in every mode. VS PLAYER shares one set of SETTINGS for both players. A CPU never has
  the assist, so the CPU-vs-CPU gates (pacing, A/B, G2) are unchanged.

## How it works (`duel/lisp/assist.lisp`)

`ASSIST-SYSTEM` runs between `BRAIN-SYSTEM` and `FIGHTER-SYSTEM`. By then the human's vpad holds the devices, and the
CPUs' vpads hold their brains' presses.

The CPU's own rules pick the move, and its own press code (`AI-COMMAND`, run on a brain the assist borrows per side)
gives the buttons and how long to hold them.

- **Pressing**: `VPAD-STAMP!` (engine `input.lisp`) buffers a press even while the button is already held. The J the
  assist answered is consumed. Later steps of a hold (the Breaker's dash, O through the strike) use `VPAD-HOLD!`.
- **Marking**: `FIGHTER-ASSIST-NEXT` is set when the assist presses.
  - `START-MOVE` turns it into `FIGHTER-ASSISTED`, and `APPLY-HIT` multiplies by `*ASSIST-MULT*` while the attacker is
    still in that move.
  - `START-HOHO` reads it and skips the perfect test.
  - `TO-IDLE` clears it, so a refused press doesn't mark a later move.
- **AUTO GUARD**: the fighter is free (idle / guard / run, no input lock), and U is held for HOLD U. A hit is about to
  land when `PERFECT-NOW-P` holds: one of his hit volumes is active now or within 12 f.
  - Against his melee move, the form's parry: a kit command whose move has `:parry` and that may start (Ichigo's KESSA
    L, Yamamoto's GOKUI GAESHI).
  - Otherwise a Hoho, if allowed and the form isn't rooted.

  The assist reads the opponent's real state, not a delayed one; the price is the x0.8, and the Hoho's flash-step cost
  limits how often it can fire.
- **AUTO COMBO**: on the land frame of a J / K link's hit, the plan is made once per move:
  - On a link-3 (`:ender`) hit with the opponent red: the O ender, which becomes the Kikon.
  - Otherwise `STRING-REFLEX` with the latch emptied: the next link (K at the CPU's rate), L, SP2, or ORANGE.

  The plan is pressed once J was pressed in that move, whether latched or buffered. A plan of J is left alone: his own
  press, unassisted. A cancel, burst or ender drops the latched J link.
- **AUTO BREAK**: J pressed while free, with the opponent holding a guard (or Bankai West's ward) for at least
  `*ai-guard-break-hold*` (24 f) within `*ai-guard-break-range*` (3 m), not guardless, and the Breaker allowed. The J
  becomes the Breaker, held as the CPU holds it.
- **The AUTO tag**: shown at the fighter's feet (move callouts use the space over heads) for `*assist-tag-frames*` (45 f) after each assisted press (`HUD-HINT`). The
  combat log prints "P1 assist <cmd>".

## The gate: the button-masher (`tools/assistgate.py`)

Debug habit `:dumb` (`DUMB-STEP`) models a new player. It sees like an EASY CPU (24 f, `*dumb-delay*`) and holds U for
half of the moves it sees coming (`*dumb-guard-p*`). It mashes J (a press every 8 f) inside J1's reach and otherwise
walks in. It never Steps, Hohos, presses L / SP / I / O, Bursts or awakens on its own: those come only from the assist.

The gate runs it as P1 against a CPU on all 25 roster pairings, 20 seeds each, through the learning gate's runner with
learning off. Its debug knobs:

| Debug | Sets |
|---|---|
| 206000 + 100 c1 + 10 c2 | the masher as P1 |
| 81000 + k | its assist |
| 81020 + i | the CPU's difficulty |
| 81100 + k | `*assist-mult*` |

First run, P1's wins out of 500 (2026-10-01):

| assist (k) | vs NORMAL | vs HARD |
|---|---|---|
| none (0) | 98% | 72% |
| GUARD HOLD U (1) | 99% | 77% |
| GUARD ALWAYS (2) | 100% | 88% |
| COMBO (3) | 84% | 51% |
| BREAK (6) | 99% | 76% |
| HOLD U + COMBO + BREAK (10) | 91% | 65% |
| ALWAYS + COMBO + BREAK (11) | 100% | 80% |

What it says:

- **The planned target was wrong.** The plan was "the masher wins >= 30 % with the assist, almost never without it",
  but mashing J beats the CPU without any assist: 98 % against NORMAL, 72 % against HARD. The CPU has no answer to
  point-blank J mashing plus a late, half-time guard; that is a CPU weakness of its own, outside the assist.
- **AUTO GUARD and AUTO BREAK raise the win rate.**
- **AUTO COMBO lowers it.**
  - Every choice it makes loses tempo against restarting J strings. With one choice removed at a time (x0.8,
    vs HARD, 8 seeds), dropping the O ender gave the most back (62 %); every other single choice stayed at 50–52 %.
  - The x0.8 isn't the cause: COMBO alone at x1.0 scored 48 %.
  - The ender is now red-only (the Kikon, the Konpaku-taking hit). The CPU's coin-flip O ender on a non-red opponent is
    gone.
  - AUTO COMBO still makes the strings the CPU plays (K links, L, SP2, ORANGE, the Kikon): flashier, not stronger.

## Learning his habits (the user, 2026-10-02)

The user: "Can our CPU learn the enemy's habits too?"

**Decision:** no row of its own (the user picked this over a fourth AUTO READ row). While any of the three rows is on, the
assist learns.

**What it does:**

- **The learner.**
  - A brain's perception at HARD's delay (`BRAIN-PERCEIVE`, now shared with `BRAIN-STEP`) feeds `LEARN-STEP`, so the
    learning CPU's player model is turned on the CPU.
  - One table is kept per opponent character in `*ASSIST-LEARN-TABLES*`. They are saved on the page as
    `soulduel.learn.a<i>` (page 10100 + 1000 i) and wiped by RESET LEARNING.
  - At the match's end, its form takes the result (`ASSIST-LEARN-END`).
- **AUTO COMBO's read** (`AUTO-READ`). A J pressed in neutral becomes the counter to his predicted next move, taken from
  the event's planned counter, else his band's when confident and the roll says read:
  - K against his K or I, when he stands beyond J's reach and inside K's.
  - A Hoho against his SP.
  - Anything else leaves J as his.
- **The bait.** When `STRING-REFLEX`'s learner bait applies (he is predicted to burst at our string's 2nd hit), the
  string ends there with a held guard (`:guard-long`), so the guard cancel catches his BLUE.

**The gate:** vs HARD, P1's wins out of 500.

| assist (k) | learner off | first try | Breaker read dropped |
|---|---|---|---|
| COMBO (3) | 51% | 42% | 51% |
| HOLD U + COMBO + BREAK (10) | 65% | 52% | 65% |
| ALWAYS + COMBO + BREAK (11) | 80% | 76% | 80% |

- **The Breaker read made it worse.** The learning CPU answers a predicted guard with the Breaker, and the first try did
  too: 404 of them in 40 matches. A CPU sees the Breaker's aura and dash, and J's or Hohos it. So the read no longer
  uses it; AUTO BREAK (a guard already held long) is that answer.
- **Without it, the learner changes almost nothing** (40 matches, k3):
  - About 12 more assisted K.
  - No bait.
  - Wins 18 → 19.
- **Why so little:** a CPU's choices follow its state, which the model doesn't see.
  - It bursts only when a burst is worth it: under half its Reishi, or the next hit would make it red. HARD then bursts
    85 % of the time (144 BLUE in those 40 matches).
  - The model's :c-hit row doesn't see the Reishi. Taking the string stays the likelier prediction there, so no bait
    was ever planned.
  - The rest of its play reacts to what it sees.

  The learner was built for a human, whose habits repeat. It is kept: neutral against the CPU, and the same tables
  would read a human opponent (VS PLAYER).

## SP in neutral (the user, 2026-10-02)

The user asked whether the assist covers SP1 / SP2. Before this change it did in three places:

- AUTO COMBO's SP2 cancel off a string hit (`STRING-REFLEX`).
- Senjumaru's SP1 ender (her kit's `:sp-ender`).
- Bankai West's parry under AUTO GUARD, since GOKUI GAESHI is West's SP1.

The user then asked for SPs in neutral too.

**What it does now.** A J pressed while free first asks `AUTO-SP`, which applies the CPU's own rules as `AI-REFLEX`
uses them:

- **On a launched or downed opponent**, more than 3 m away: the kit's `:oki`, a full-charge SP1 (Yamamoto's and
  Rukia's Shiranui-type charge).
- **On a stunned opponent inside the kit's `:stun-follow` range**, still stunned when the move lands: that command
  (Rukia's SP2, Ichigo's SP1).

**The gate** (vs HARD, P1's wins out of 500):

| assist (k) | before | with the band roll | oki / stun-follow only |
|---|---|---|---|
| COMBO (3) | 51% | 40% | 51% |
| HOLD U + COMBO + BREAK (10) | 65% | 53% | 65% |
| ALWAYS + COMBO + BREAK (11) | 80% | 72% | 80% |

**Why the band roll was dropped.** The first version also rolled the SP share of the kit's `:moves` band, which is
`AI-ATTACK`'s neutral pick. Applied to every J press, that turned about 1 in 6 presses into an SP2 into a guard: 129 of
435 SP2 were blocked, and each one spent the Reiatsu the string cancels need. The CPU makes that pick only at its
neutral decisions, not on a masher's every press.

**What the two rules add.** In 8 seeds of RU vs RU they fired 2 oki SP1s and the stun follow-ups.
