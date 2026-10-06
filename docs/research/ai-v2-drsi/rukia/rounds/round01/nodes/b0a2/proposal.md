# Cell b0a2 (round 1, refines branch 0 from b0a1): Rukia, "no bar? cash it with the O"

Final file, measured with `python3 tools/aieval.py --char 2 -j 4` (aieval at 9df6ecc, 20 seeds):

| | baseline | b0a0 (rescored) | b1a0 | b0a1 (parent) | **b0a2** |
|---|---|---|---|---|---|
| score | 0.7495 | 0.8703 | 0.9108 | 0.9337 | **0.9516** |
| strength (HARD, 160) | 0.831 | 0.963 | 0.956 | 0.981 (157) | **0.994** (159) |
| masher (80) | 0.887 | 0.875 | 1.000 | 1.000 | 0.988 (79) |
| signature | 0.441 | 0.589 | 0.685 | 0.725 | **0.789** |
| pacing (NORMAL medians Y / K / I / S) | ok | 147 / 146 / 177 / 168 | 140 / 149 / 196 / 192 | 153 / 149 / 196 / 188 | ok: 154.5 / 149.2 / 195.9 / 187.2 s, all K.O. |

`tests/duel-rules-test.lisp`: 4433 checks, ALL PASS. Only `duel/lisp/rukia.lisp` changed, and only her CPU code: two new
functions reached through the existing `:reflex` hook (`RUKIA-AI-CASH` got a third branch; `RUKIA-AI-ZONE` is new) and two
new per-difficulty parameters. No frame data, damage, costs, form rules or `:ai` plist values changed.

## What the parent left on the table (measured, not guessed)
I wrote a scratch breakdown (`scratchpad/rukia-b0a2/brk.py`: her damage per move and the CPU reason that started its string,
from the same logs aieval reads). On b0a1, 10 seeds:
- J / K link damage was 27.6 % of what she deals. FOLLOW-UP strings made 29.5 k of it (12.5 %), NEUTRAL J1 / K1 strings
  28.2 k (11.9 %), the rest (anti-Breaker J1, punish, block punish) about 3 %.
- The FOLLOW-UP strings are almost all one situation. With a debug log in the cash I found 141 of ~250 follow-ups in it:
  Shikai, after the perfect Hoho's COUNTER, him stunned with 20-29 perceived frames left at 1.5-2.0 m, **0 bars**. So no
  SHIRAFUNE, and TSUKISHIRO's 24 f pillar delay can't land. Her O (ENBU) was off cooldown in every one of them. Most of
  the rest were the cash's 10 % roll miss.
- In the neutral, the table's TSUKISHIRO at 5-8 m lands about 1 time in 6 against these CPUs (164 casts, 28 pillar hits
  in 20 seeds). HAKUREN's wave lands about 2 in 3 (52 casts, ~35 hits). Neutral K1 at 1.8-2.8 m lands about 1 in 5.

## The action policy (what changed)
**Shikai, after a perfect Hoho, no bar (the O cash, `RUKIA-AI-CASH` third branch + `RUKIA-AI-O-LANDS-P`).** He is stunned.
SHIRAFUNE (bars) and the band's disc L don't fit. Her O does if it strikes before the stun ends: aura + the dash into its
reach + S + 1 frame (ENBU at 1.6 m: 15 f). Then she takes the O instead of letting the generic FOLLOW-UP J1 string
happen. It's 70 + the rush's follow-up strike, all signature, and it costs no bar. It's skipped when the generic code
would finish him with hits (`AI-SB-FINISH-P`). The same rule covers the bands' HAKKA (aura 8 + S 20, a lane without a
dash), which rarely fits. Stuns only: the same cash on his recovery cost 3 wins of 160 (v3 below).
- Per stun, at the cash roll (`brain-react-roll`, one per event): `*ai-ru-cash-o*` EASY 0 / NORMAL 0.1 / HARD 0.9.

**Shikai neutral decision at 5-11 m (`RUKIA-AI-ZONE`).** On the step the neutral decision is due (`brain-decide-t` <= 1),
she sends HAKUREN's wave (SP1, one bar, held by AI-COMMAND) instead of the table's pick, which is mostly the TSUKISHIRO
that a CPU steps out of. She then re-times the next decision the way AI-NEUTRAL does.
- `*ai-ru-zone-wave*` EASY 0 / NORMAL 0 / HARD 0.5. At 0 no random number is drawn, so EASY / NORMAL decisions are
  unchanged.

**Everything else is b0a1:** the timed perfect Hoho, the stun / recovery ice cash, the K3 -> L / J3 -> SHIRAFUNE / O ender
confirms, -50's Hoho-in, absolute zero as shipped, and the shipped neutral tables, awakening, cooling and bracing.

Per form:
- **Shikai**: counter-fighter. Up close, J1 strings that end in SP2 / O / L. Every stun is cashed in ice, and with the O
  when there is no bar. At range she zones with HAKUREN's wave rather than TSUKISHIRO.
- **-18 / -50**: as b0a1 (disc cash; HAKKA rarely fits the O cash).
- **Zero**: as b0a1.

## Steps measured
"A" is seeds 1-20 (= aieval's), "B" is seeds 21-40. str is wins of 160 per set (HARD, both seats, the four others).

| variant | A str | B str | sig (A) | kept? |
|---|---|---|---|---|
| b0a1 (parent) | 157 (aieval) | - | 0.725 | |
| v1 = + O cash on stuns | 158 | 156 | 0.780 | yes (aieval 0.9485) |
| v2a = v1 + "hold fire": no neutral J / K opener within 2.8 m at HARD 0.7 | 75/80 (10 seeds) | - | 0.826 | no: -5 wins |
| v3 = v1 + O cash on his recovery too | 155 | - | 0.790 | no |
| v5 = v1 + hold fire only at 1.8-2.8 m (no K1 poke) | 156 | - | 0.782 | no |
| v6 = v1 + cash rolls 1.0 at HARD | 153 | - | 0.807 | no |
| **v8 = v1 + zone wave HARD 0.5** | **159** | **156** | **0.789** | **final** |
| v9 = v8 at HARD 0.9 | 157 | 155 | 0.792 | no |
| v10 = v8 from 4 m | 156 | 153 | 0.792 | no |
| v11 = v8 + timed Hoho on his K / L / SP 0.95 | 157 | 156 | 0.795 | no |

Readings:
- The O cash is the cell's main gain. Signature 0.725 -> 0.78 and damage dealt unchanged (233.8 k vs 236.8 k in 10
  seeds), because the O (70) plus the rush's own follow-up strike replaces a J string whose own ender was mostly an O
  anyway. The bar it saves goes to a later SHIRAFUNE cash. Over 20 seeds the O cash fires ~420 times.
- Signature is cheap and strength is expensive: one win of 160 is worth 0.019 signature. Every variant that took J / K
  openers away from her neutral (v2a, v5) gained signature and lost more in wins.
- v8 vs v1 over 40 seeds: 315 vs 314 wins, signature +0.008. This step is small, inside the noise for wins, and
  consistently positive for signature.

## Risks
- **The O's cooldown (90).** The O cash spends the cooldown the J3 ender's O fallback also uses. They rarely collide
  (cashes come seconds apart), but a shared change to the O cooldown or the ENBU timing (aura 6, 24 m/s, S 8) moves this
  cell. RUKIA-AI-O-LANDS-P reads them from the move, not from constants.
- **Bars.** The zone wave spends a bar the SHIRAFUNE cash would have used. The O cash covers the gap, and that is why the
  wave is capped at HARD 0.5: at 0.9 or from 4 m (v9, v10) it measured worse.
- **Masher 79 / 80.** It was 80 / 80 in v1's official run. Neither change touches the masher answers (the timed Hoho on his
  next J; the O cash needs a stun), so I read the one loss as chaos from the reshuffled random stream.
- **Pacing.** NORMAL changed only through the O cash's 0.1. The medians are within 1 s of b0a1's; Ichigo is at 195.9 s
  (gate 220).
- **The decision hook.** RUKIA-AI-ZONE intercepts the neutral decision from `:reflex` by reading `brain-decide-t` and
  setting it again. That works because ai-neutral only counts it down when no reflex fired. A shared `:decide` hook
  would make this explicit (recommendation 1).

## Shared-code recommendations
1. A kit `:decide` hook in AI-DECIDE (before the weighted pick). Kit-specific neutral choices could then scale with
   difficulty without re-timing `brain-decide-t` from `:reflex`.
2. Let `:l-after-k` / `:string-k` / `:o-ender` take per-difficulty plists, or call a hook mid-string. Today a kit can only
   act at the string's end (`:sp-ender`). K1 -> TSUKISHIRO-K (60 + a 36 f freeze that the cash turns into SHIRAFUNE / O)
   would be her best signature string, but it can't be raised at HARD only.
3. Carried over: time the generic Hoho into the hit window (b1a0); an explicit `:wait` command in AI-COMMAND.
