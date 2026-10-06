# Kenpachi AI v2, cell b0a0 (round 2, new direction): "SP1 is the ender": Buttagiru / Split the Meteor off a landed J3 / K3

## Result (official `python3 tools/aieval.py --char 1 -j 4` on the delivered ken.lisp, aieval at 9df6ecc)

| | score | strength | masher | signature | pacing (NORMAL medians) |
|---|---|---|---|---|---|
| baseline | 0.3006 | 0.175 | 0.400 | 0.528 | ok |
| parent b0a2 (20 seeds, lucky draw) | 0.8660 | 0.975 | 1.000 | 0.405 | ok |
| parent b0a2, 40 seeds | 0.8536 | 0.956 | 0.994 | 0.405 | |
| parent b0a2, 80 seeds | 0.8436 | 0.942 | 0.991 | 0.401 | |
| **this cell, 20 seeds (score.json)** | **0.8582** | **0.938** | **1.000** | **0.479** | ok: 20/20 K.O. each, 138-158 s |
| this cell, 40 seeds | 0.8632 | 0.947 | 0.994 | 0.482 | |
| this cell, 80 seeds | 0.8531 | 0.930 | 0.994 | 0.483 | |

At the same 40 / 80 seeds the cell beats the parent by +0.010. Signature goes up by 0.08 and is stable. Strength goes down
by about 0.01: that is 1 sd at 640 matches, so partly noise, but it is probably a small real cost. The 20-seed figure is
lower than the parent's because the parent's 20-seed strength (0.975) was a lucky draw.

## The mechanism (only `duel/lisp/ken.lisp`, "the CPU" section)

1. **The SP1 ender** (`ken-line-ender-p`, first in `ken-sp-ender`). Off a landed ender, use the form's SP1 when
   startup + 2 fits inside the reel the ender gives (`*reaction-frames*`: J3 stagger 26 f, K3 crumple 40 f). It is
   used before the O ender and the charge, at EASY 0 / NORMAL 0.1 / HARD 0.9 (`*ken-ai-sp1-ender*`).
   - The pushed victim is out of reach, but an SP started off a pushing ender chases (DUEL_STRINGS §15/16), so the
     SP1 connects.
   - Not NOMIHOSE's cash-out (the kit's `:cashout` rule spends it). Not when a Soul Break should finish him.
2. **The line cut punishes first** (`ken-sp-order`, used by `ken-sig-punish` and `ken-far-punish`). Where SP1 is the
   line cut, it is tried before the charge if it lands before he is free. Otherwise the order is the charge, then SP1,
   as before.

**Why SP1.** It costs one bar against the awakened charge's two. It does all its own damage: Buttagiru 180, Meteor 240,
TATE-GOTO 260. The O ender on a non-red victim is 63 plus a guardable follow-up. A red victim still gets the generic
O ender (it runs earlier in ai.lisp), so the Kikon is untouched.

**Per form** (the frame data decides):
- **Base / KATAUDE**: Buttagiru (22 f) off J3 and K3.
- **KATATE / RYOTE**: the Meteor (26 f) off K3 only, plus the Meteor-first punish.
- **NOMIHOSE**: unchanged.
- **Bankai**: TATE-GOTO (24 f) off J3 and K3.

Everything else (b0a0-b0a2's reflex chain) is unchanged.

## Evidence (bd.py: aieval's matches plus a per-move breakdown; 40 seeds unless noted)

| variant | str | sig | score |
|---|---|---|---|
| parent | .956 | .405 | .8536 |
| v1 Meteor off K3 only | .956 | .427 | .8566 |
| v2 + line-cut-first punish | .956 | .431 | .8574 |
| v3 + "line read" (Meteor down his straight run-in, 3.5-10 m) | .941 | .430 | .8479 (reverted: rarely fired) |
| v4 v2 + stance vs his K at HARD 0.95 (ai.lisp :react is 0.7) | .944 | .433 | .8504 (reverted) |
| v5 v2 + keep a bar for the Meteor (charge only at 3 bars) | .959 | .427 | .8585 (reverted: Meteor count unchanged, bars aren't its limit) |
| v6 v2 + the leap off K3 | .947 | .457 | .8582 |
| **v8 (delivered)**: any ender whose reel fits SP1 (J3 too); leap kept in far punish | **.947** | **.482** | **.8632** |
| v9 HARD 0.6 | .919 | .464 | .8416 |
| v10 HARD 1.0 | .931 | .490 | .8543 |

Damage changes (40 seeds, parent to v8):

| move | parent | v8 |
|---|---|---|
| KE-BUTTAGIRU | 8k | 210k |
| KE-METEOR | 5k | 75k |
| KE-KIKON (base O, now partly replaced by the leap) | 163k | 90k |
| total dealt | 1.02M | 1.26M |
| total taken | 533k | 574k |

The leap off a pushing ender chases the victim, so it lands even though `KEN-ARRIVE`'s leap model says a 3 m target is
too close. That was the surprise of this cell.

## Why it is not a repeat

Round 1 changed only which ender comes off a string among O and SP2 (SP2 ender 1.0, L as a third ender: both lost).
No cell used SP1 off an ender, and b0a2's leap was excluded below 4 m by the arrival model. This cell also tried the
other round-1 ideas:
- The stance as an anti-K answer (v4): no gain.
- Bar budgeting (v5): no gain.
- A ranged read (v3): it did not fire.

## Risks

- **Strength** about -0.01 against the parent at 80 seeds (YAM-KEN and RUK-KEN lost the most).
- **Matches deal and take more damage.** NORMAL pacing stays 138-158 s.
- **NORMAL gets the SP1 ender at 0.1**, so shipped-like play changes a little. EASY is unchanged.
- **Base's O-ender Kikon rushes on non-red victims are rarer** (the leap replaces them). On red the O ender is
  untouched.

## Shared-code recommendations (not done)

1. **Chase-aware arrival.** `KEN-ARRIVE` and ai.lisp's punish logic do not know that SPs started off a pushing ender
   chase. A generic "SP off ender" option in STRING-REFLEX (pick by startup vs the ender's reel) would help every
   character with a slow, big SP.
2. **Gate on 80 seeds.** At 40 seeds, strength differences of 0.01-0.02 are still noise (v8 / v9 / v10 vary
   0.919-0.947 for one knob).
