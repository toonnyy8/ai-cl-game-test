# Cell b1a0 (round 1, new direction): Rukia, "vanish through it, cash the stun in ice"

Final file, measured with `python3 tools/aieval.py --char 2 -j 4` (aieval at 9df6ecc, 20 seeds):

| | baseline (re-measured) | b0a0 (rescored) | **b1a0** |
|---|---|---|---|
| score | 0.7495 | 0.8703 | **0.9108** |
| strength (HARD, 160) | 0.831 | 0.963 | 0.956 (153) |
| masher (80) | 0.887 | 0.875 | **1.000** (80 / 80, mirror included) |
| signature | 0.441 | 0.589 | **0.685** |
| pacing (NORMAL medians Y / K / I / S) | ok | 147 / 146 / 177 / 168 | ok: 140 / 149 / 196 / 192 s, every match a K.O. |

`tests/duel-rules-test.lisp`: 4433 checks, ALL PASS. Only `duel/lisp/rukia.lisp` changed: the `:reflex` key of the base,
-18 and -50 `:ai` plists, plus new CPU functions and their per-difficulty parameters in that file. No frame data,
damage, costs or rules changed.

## History and why this is not a repeat
b0a0 (the only earlier cell) *meets* commitments. Its timed J1 / SHIRAFUNE / K1 beat the Breaker's strike. It also
confirms enders (K3 -> L, J3 -> SP2, O), uses HAINAWA on a long guard, and punishes a whiff at range with SP2. Its
strength came almost all from the anti-Breaker (Breakers had dealt 55 k).

This cell uses a mechanism b0a0 never touches: the **perfect Hoho** (combat.lisp PERFECT-NOW-P). A Hoho started while
his hit window is active, or due within *PERFECT-LEAD* (12 f) and overlapping her hurt cylinder (+1 m), is perfect. It
gives the automatic COUNTER (60, not Hoho-able, not Burstable), a 36 f stun, his inputs locked 40 f, and 15 of the 30
flash-step back. She then reappears behind him. In the baseline this happened only by luck: the generic Hoho is untimed,
and only 40 of 71 of her Hohos as P1 were perfect in the first version. The cell turns it into her whole defence:
- she vanishes through his attacks instead of beating them;
- she cashes the stun it leaves with her own ice (SHIRAFUNE / the band's disc L) instead of a J string.
No ender hook (`:sp-ender`), anti-Breaker J1, guard-break or whiff-SP2 code from b0a0 is used.

## The action policy
**Shikai, -18, -50 (`RUKIA-AI-REFLEX`, first in her free steps):**
1. **The timed Hoho (`RUKIA-AI-PERFECT-HOHO`).** From the perceived snap only (SNAP-START is the exact start tick of his
   current phase, SNAP-SF + the delay his frame now), she predicts when his hit window opens. Until then she returns
   `:wait`, which presses nothing: no guard for a Breaker to break and no early J1 for it to beat. She Hohos a few frames
   into the window:
   - *Breaker*: in the aura, the window opens when the aura ends plus the dash to *BREAKER-TRIGGER* + 0.5 m (at
     BREAKER-SPEED). In the dash, it opens at the perceived distance minus delay x speed. She presses 2 f inside.
     Strike seen: at once.
   - *Kikon rush* seen dashing / striking within 3.5 m: at once (the module's speed is its own).
   - *His K / L / SP* (a move with hit frames and reach, her within reach + 0.7 m): lead = S - (SF + delay). She presses
     at lead <= 12 - 3. Only while flash-step >= 60 (`*ai-ru-ph-move-fs*`: one Hoho is kept for a Breaker).
   - *A J masher* (AI-MASH-P): his recovering J is followed at once by the next one. She Hohos into that next J's window
     (frames left - delay + his J's S <= 12 - 1), within his reach + 1.0, spending the gauge to the last Hoho.
   - Only when the Hoho is allowed and the gauge can spare it (`AI-HOHO-SPARE-P`: a Burst's 70 kept while low).
2. **The ice cash (`RUKIA-AI-CASH`).** He is stunned (the perfect counter, a freeze, a crumple) or recovering (not
   while he mashes J), and what is left of it, as seen, outlasts the startup (+ the L's pillar delay) of her ice. Then:
   - SHIRAFUNE within its line (bars and `:sp-cancel-bars` permitting);
   - else the band's disc L within its radius - 0.4: SHIMOBASHIRA at -18, HYOSHIN at -50. (TSUKISHIRO's delay of 24
     rules it out up close.)
   This is where the signature comes from: the cash is now her largest opener (~75 k of ~240 k dealt in a 10-seed run),
   all of it non-link.
3. -50 keeps the shipped Hoho-in to absolute zero (`RUKIA-AI-HOHO-IN`).

**Absolute zero** (rooted, no Hoho): shipped. **Awakening, cooling, bracing, neutral tables**: shipped.

**Difficulty layering** (`RUKIA-AI-P`, one roll per opponent event via `brain-react-roll`):

| parameter | EASY | NORMAL | HARD |
|---|---|---|---|
| `*ai-ru-ph-breaker*` (Breaker / Kikon rush) | 0 | 0.2 | 0.95 |
| `*ai-ru-ph-move*` (his K / L / SP) | 0 | 0.1 | 0.8 |
| `*ai-ru-ph-mash*` (a masher's next J) | 0 | 0.1 | 0.8 |
| `*ai-ru-ph-cash*` (SP2 / disc L on a stun or recovery) | 0 | 0.2 | 0.9 |

When a roll fails, the generic reflexes run as shipped. Randomness comes only from SIM-RND01. She sees only the
perceived snap, the clock and her own gauges.

## What each step measured (scratch runs, 10 seeds unless noted; str of 80, mash of 50)
| step | str | mash | sig | notes |
|---|---|---|---|---|
| baseline | 66 | 42 | 0.436 | mirror masher 4 / 10 |
| v1 timed Hoho + SP2 cash on stun (left >= S + 2) | 77 | 49 | 0.546 | |
| v2 cash at left >= S + 1, + disc L | 77 | 50 | 0.602 | |
| v3 cash also on his recovery | 78 | 47 | 0.663 | mirror masher 7 / 10 |
| v4 = v3, no recovery cash vs a masher (**official 20 seeds**) | 153 / 160 | 77 / 80 | 0.659 | score 0.898 |
| v5 Hoho a few frames *into* the window (close Breaker at el >= 15, K at lead <= 9), K needs active frames, reach + 0.7 | 79 | 49 | 0.680 | perfect share 40/71 -> 76/82 (P1 side) |
| v6 TSUKISHIRO's delay counted in the cash (**official**) | 152 / 160 | 77 / 80 | 0.687 | score 0.8998 |
| v7 masher Hoho only within his reach + 0.3 (20 seeds) | 151 / 160 | 87 / 100 | 0.684 | worse: dropped |
| v8 masher Hoho within reach + 1.0, no flash-step reserve (20 seeds; **final**) | 153 / 160 | 100 / 100 | 0.685 | official: **0.9108** |

Final file: COUNTER (the perfect Hoho's strike) is ~16 % of her damage and SHIRAFUNE ~13 %. Her J / K links fell to
~32 % of what she deals. Hohos are now 85-99 % perfect.

## Where she still loses
- Senjumaru: 35 / 40, mostly as P1 in long matches (195-215 s). SJ's FREEZE hazards (10 k) and J strings.
- Ichigo's Kikon rush still deals 16.6 k (20 seeds). Its dash is handled crudely (Hoho at once within 3.5 m).
- NORMAL pacing medians rose to 196 / 192 s for I / S (gate 220). That is a margin to watch if a later cell makes NORMAL
  stronger.

## Risks
- **Flash-step economy.** All of this runs on 30 flash-step a Hoho (15 back when perfect, 3 / s regen). Any shared change
  to `*fs-hoho*`, `*fs-refund*`, `*perfect-lead*` or `*perfect-inflate*` moves this cell's strength more than b0a0's.
- **Predictability.** A human can bait the timed Hoho with a long-startup move he cancels. The roll per event (0.8-0.95)
  leaves some room. The learner never runs against CPUs.
- **The `:wait` command.** The reflex returns `:wait`, which AI-COMMAND ignores (no case for it): she holds still while
  his window approaches. This relies on AI-COMMAND's `case` having no `otherwise`. A shared `:wait` command in ai.lisp
  would make it explicit (recommendation 2).
- **Noise.** About +-3 wins of 160 per 20-seed run. The v4 / v6 / v8 strength values (152-153) match each other.

## Combination worth trying (untried)
This cell and b0a0 hardly overlap:
- **b0a0** meets the Breaker with J1 and confirms enders (K3 -> L, J3 -> SP2).
- **b1a0** Hohos through everything and cashes stuns.
A cell could use b0a0's ender confirms (its `:sp-ender`) on top of this reflex. The remaining J / K damage here is
mostly the generic FOLLOW-UP string (~30 k of 240 k) after a stun too short for SP2 in the Shikai. b0a0's K3 -> L would
turn its end into signature. Its anti-Breaker J1 would mostly conflict with the timed Hoho (one or the other per Breaker).

## Shared-code recommendations
1. The generic Hoho in AI-REFLEX ("a committed move coming") is untimed (lead >= 6). Timing it as here (lead <= 9, his
   hit frames, reach + 0.7) would make every CPU's Hoho perfect far more often.
2. Add an explicit `:wait` (do nothing this step) to AI-COMMAND for kit reflexes that need to hold still.
3. As b0a0 noted, let `:l-after-k` / `:o-ender` / `:string-k` take per-difficulty plists.
