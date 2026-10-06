# Kenpachi AI v2, cell b0a0 (round 1, new direction): "Use the reach he has; stop paying for the generic CPU's gaps"

## Result

The official `python3 tools/aieval.py --char 1 -j 4` run of the delivered `ken.lisp` is in `score.json`.

| | score | strength (HARD) | masher (HARD) | signature | pacing (NORMAL medians) |
|---|---|---|---|---|---|
| baseline (main 7176715) | 0.2906 | 0.175 | 0.400 | 0.528 | ok |
| **this cell (variant E)** | **0.7645** | **0.894** | **0.700** | **0.441** | ok: 20/20 K.O. each, 146.3-166.3 s |

All the code is in `duel/lisp/ken.lisp`, in a new section, "the CPU". Each of the six forms' `:ai` plists gets the same
three existing hook keys: `:reflex ken-ai-reflex :sp-ender ken-sp-ender :sig-hold ken-sig-hold`. No move, frame, damage,
cost, form rule, tuning value or other file changed, and no static `:ai` number changed. Every new behaviour is a chance
by difficulty (the `*ken-ai-...*` plists at the top of the section): EASY 0, NORMAL small, HARD full. The Bankai gate is
a rule that is on only at HARD. EASY therefore plays the shipped CPU, apart from a few extra `SIM-RND01` draws (the
stance hold length). The CPU sees the opponent only through the perceived SNAP and the HUD gauges (his Konpaku, for
the Bankai gate), as ai.lisp already does. All dice come from `SIM-RND01`.

## Diagnosis (baseline logs: the evaluator's 20 seeds x 8 seat pairings + the masher)

I re-ran the evaluator's matches with the combat log kept and counted, per Kenpachi move start (move / CPU reason), the
damage dealt and taken in the next 180 frames ("net").

- **Breakers ate him.** He took 354 Breaker hits or guard breaks (150 each) in 140 matches. ai.lisp answers a Breaker
  with J1 once it is inside J1 reach + 1.4 m. For Kenpachi that is 2.4 m, seen 8 f late, and the strike landed 0-5 f
  after his J1 started (`KE-J1/ANTI-BREAKER` net -43). A Breaker in its aura, dash or strike startup is `:breaker` on the
  triangle, so any hit counter-hits it. His K1 reaches 2.8 m (RYOTE / NOMIHOSE 3.9 m) and was used for this only 15
  times.
- **His J1 lunges 0.8 m, but the CPU never used it.** `AI-ATTACK` and the punish / follow-up reflexes allow J only
  within reach + 0.2 to 0.6 m. Base J1 reach is 1.04 m, but its `:slide` carries it 0.8 m further (the ender push
  measures reach + slide + body too). So in neutral he stood at 1.3-3.0 m and threw K1 (16 f, Hoho'd / guarded, net -25)
  or a Breaker (net -43). J1 was the best neutral move he had (`KE-J1/NEUTRAL` +129, `KE-J1/PUNISH` +167).
- **Opponents' perfect Hohos**: 522 against him, 155 by him. ai.lisp's Hoho test reads the perceived startup (>= 6 f
  left) without the perception delay.
- **The masher.** The masher's wins went with his J reach: Yamamoto (0.96 m) lost 16/16, Rukia (1.44 m + 0.6 lunge)
  won 16/16. Kenpachi took about 28 J strings a match. J-BEATS-K needs our J1 in reach, and the gap-step only backs off.
- **The Bankai** sets his Konpaku to 1. Win rate by state at entry: entered with 4 left, 11 W / 16 L; with 3 left and
  the opponent at 5 or more, 7 W / 8 L; with 3 left and the opponent at 4 or fewer, 31 W / 5 L (variant B logs).
- The blocked-string reset with RYOTE's 10 f MEN (`KE-R-J1/PRESSURE`) netted -70. The reset with base J1 (7 f) netted
  +103.

## The action policy

All forms:

- **J1 from the lunge's reach** (`ken-lunge`). Beyond the generic reach + 0.2 and up to reach + slide + 0.1, we use
  J1 to punish his recovery or a reeling opponent when J1 lands before he is free (per event: HARD 0.9, NORMAL 0.3).
  In neutral, when he walks or waits, we open with J1 at a per-step chance (HARD 0.06, NORMAL 0.01).
- **Walk in** (`ken-walk-in`). Neutral, he isn't attacking, and we are between J1's reach (with the lunge, at least
  reach + 0.3) and 3 m: we walk toward J range, strafing a little, instead of standing there to throw K1 (per step:
  HARD 0.8, NORMAL 0.05). It never applies against a J masher (`AI-MASH-P`), who comes to us.
- **Anti-Breaker by a reach / time model** (`ken-anti-breaker`). We see his Breaker in its aura or dash within 6 m.
  The model (dash 0.16 m/f, the 12 f aura, the 0.95 m trigger, 8 f strike) gives where the Breaker will be and when
  its strike lands. If our K1 is active in time and in reach (+0.3), we use K1; else J1; else a Hoho close to the
  strike. Until then we wait, so the generic early J1 is not pressed. One roll per Breaker: HARD 0.9, NORMAL 0.2.
- **Hoho a commit** (`ken-hoho-commit`). His K, L or SP is coming at us, and as we see it (perceived startup minus our
  delay) the hit falls 1-12 f from now, inside the perfect-Hoho lead. We Hoho with flash-step to spare (HARD 0.75,
  NORMAL 0.1). A K that the stance can still beat is left to the kit's `:react` stance.
- **Anti-mash stance** (`ken-anti-mash`, `ken-sig-hold`). He mashes J, is within 2.4 m, and no J of his is about to
  land: KITTE MIRO YO, held 36 f through his string. The stance soaks it (stored 1:1), and the cut returns
  100 + stored. Per step: HARD 0.35, NORMAL 0.05. Only in forms whose L is the stance; the Bankai's L is the bite.
- **No slow reset** (`ken-no-reset`). After our blocked string, if the reset J1 would be 10 f or slower (RYOTE /
  NOMIHOSE MEN), we guard instead (HARD 0.8, NORMAL 0.2).
- **Enders off a landed J3 / K3** (`ken-sp-ender`). When the kit's own O-ender roll fails: the O ender anyway (HARD
  0.85, NORMAL 0.1; the push leaves him just out of reach and the O's dash still connects). Otherwise SP2, the charge
  into the flurry, which chases off the ender (HARD 0.6, NORMAL 0.1). Not on a red opponent (that rushes already), and
  not when a Soul Break should finish him.
- **The Bankai as a finisher** (`ken-bankai-gate`, a rule at HARD only). It enters with 2 or fewer Konpaku left; with
  3 when he has 4 or fewer; with 4 when he has 2 or fewer. Otherwise that cup-3 stay's roll is spent, so ai.lisp's
  `AI-BANKAI-P` skips it.

Per form (the same hooks; the moves' reach decides what fires):

- **Base and KATATE** (J1 1.04 m / 1.35 m + the 0.8 m lunge): a close J fighter that opens from about 2 m.
  - Neutral: walks in; K1 meets Breakers; the stance answers mashers and K startups.
  - Off a landed ender: O, else the charge.
- **RYOTE / NOMIHOSE** (MEN has no lunge, so the lunge J1 never fires; K1 and KUKAN-GIRI reach 3.9 m).
  - Neutral: walks into J range. The long K is mostly the anti-Breaker tool.
  - After a blocked string: guard, not a reset.
  - NOMIHOSE keeps its drink and its cash-out (unchanged tables).
- **The Bankai**: B-J1's 1.0 m lunge opens. At HARD it enters only as a finisher, so it is rarer.
- **KATAUDE**: the same hooks (J1 at reach x0.7 still lunges).

## Measurement path (same seeds; my log analyzer reproduces aieval's strength / masher / signature exactly)

| variant | adds | strength | masher | signature | score |
|---|---|---|---|---|---|
| baseline | | 0.175 | 0.400 | 0.528 | 0.2906 |
| A | anti-Breaker, Hoho a commit 0.5, anti-mash stance, no slow reset, O ender 0.6 | 0.563 | 0.538 | 0.504 | ~0.546 |
| B | + J1 from the lunge's reach | 0.775 | 0.688 | 0.426 | ~0.688 |
| C1 | B + the Bankai gate | 0.813 | 0.700 | 0.432 | ~0.714 |
| C | B + the Bankai gate + walk-in 0.5 | 0.844 | 0.638 | 0.419 | ~0.718 |
| D | C + O ender 0.85, SP2 ender 0.6, no walk-in vs a J masher | 0.869 | 0.700 | 0.443 | 0.7499 (official) |
| **E** | D + walk-in 0.8, Hoho a commit 0.75 | **0.894** | **0.700** | **0.441** | **0.7645 (official)** |

Effects (baseline to A, the same 140 strength matches):

- Breaker hits taken: 354 to 35.
- K1 counter-hits on a Breaker: 15 to 145.
- Konpaku: taken from him 940 to 788; taken by him 683 to 989.

The lunge J1 (`KE-J1/LUNGE`, 1458 starts in D) nets +164 per start; as a punish it nets +216.

E's wins by pairing (Kenpachi P1 / P2): Yamamoto 18 / 18, Rukia 17 / 14, Ichigo 20 / 18, Senjumaru 18 / 20.
Against the masher: Yamamoto 16, Rukia 10, Ichigo 15, Senjumaru 14 of 16. The Kenpachi masher lost 15 of 16 to him,
but aieval counts that row as 1 of 16 (recommendation 1).

**Each part against the baseline:**

- Strength: 0.175 to 0.894. All four opponents in both seats.
- Masher: 0.40 to 0.70. Rukia 0 to 10, Senjumaru 2 to 14, Ichigo 8 to 15.
- Signature: 0.528 to 0.441. The lunge J1 and the J strings it opens are J/K-link damage. The O / SP2 enders, the
  stance and the K1 counters on Breakers win back part of it (B 0.426 to D 0.443).
- Pacing (NORMAL): all K.O., medians 146-166 s, near the shipped 151-171 s.

## Why this is not a repeat

This is the first cell of this run (no history). Against the baseline's line of work (static `:ai` tables: ranges,
weights, `:tempo`, `:attack`, the 2026-09-29 "more aggressive cups" pass), this cell leaves every table number as
shipped. It changes how the CPU answers given situations through the kit's reflex hooks, built on two facts the
tables can't express: J1's lunge reach, and the `:breaker` counter state that his K1 reach can exploit.

## Risks

- **HARD Kenpachi is now much stronger** (0.89 vs the four CPUs). Players who found him easy will notice. NORMAL stays
  close to shipped (small chances, pacing almost unchanged), and EASY plays the shipped CPU.
- **The anti-mash stance also fires against CPUs** (`AI-MASH-P` counts their J restarts). It nets about -8 per start
  there, against +35 for the `:react` stance. A tighter trigger (his last J start within ~30 f) is a cheap follow-up.
- **The signature dropped** (0.53 to 0.44): his damage now leans on J strings, the street fighter who swings first.
  A later cell could raise the stance / SP share without giving up the lunge.
- **The HARD Bankai is rarer** (a finisher only), so fewer Bankai cinematics at HARD.
- **The walk-in sets the stick and returns `:WAIT`** (a no-op command). While it fires, ai.lisp's neutral decision and
  intent timers don't advance.
- **The model constants** (Breaker speed 0.16 m/f, the reach margins) are estimates; the counter-hit counts above
  confirm them.

## Shared-code recommendations (not done: other files)

1. **The masher score counts the masher in the mirror.** In `tools/aieval.py`, `side = 0 if c1 == c else 1`
   treats the mash job `(m, c, 6, ...)` with `m == c` (a Kenpachi masher vs the Kenpachi CPU) as if C sat in P1. The
   masher's wins are then counted as C's: here 1/16 counted instead of 15/16, about -0.035 of score, and the same for
   every character. The fix: for `kind == 'mash'`, C is always P2.
2. **`AI-ATTACK` and the punish / follow-up reflexes ignore a J1's `:slide` lunge** (they use reach + 0.2 to 0.6).
   Rukia (0.6), Ichigo (0.6) and Senjumaru (0.5) also lunge. Using reach + slide would help every CPU.
3. **The generic anti-Breaker answer comes too late.** It presses J1 at J reach + 1.4 m, seen through the perception
   delay. The reach / time model in `ken-anti-breaker` (any hit counters a Breaker before its strike, so use the
   longest move that is active in time) could replace it generically.
4. **The generic Hoho reflex** tests the perceived startup (>= 6 f) without subtracting the perception delay. Timing it
   to the perfect lead as `ken-hoho-commit` does would help every CPU.
