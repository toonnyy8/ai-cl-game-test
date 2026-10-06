# Cell b1a0 (round 1): Senjumaru's action policy, set-play conversion (a new direction)

There is no parent cell. This cell starts from the shipped file (baseline 0.5714). Every change is in the AI section of
`duel/lisp/senjumaru.lisp`:

- new: `*senju-dp*`, `senju-dp`, `senju-o-arrive`, `senju-soldier-live-p`, `senju-setplay-reflex`, `senju-oki`;
- `senju-ai-reflex` calls the set-play reflex first;
- `senju-sp-ender`'s chance now goes through `senju-dp`;
- `senju-sig-hold` taps when the reason is `:oki-tap`.

No move, frame, damage, cost or form rule changed. Every new chance comes from `*senju-dp*` by difficulty, with EASY <=
NORMAL <= HARD. NORMAL changes little: follow 0.15, oki 0.2, escort 0.1, and the SP1 ender keeps the shipped 0.5.

## History read

- **Baseline** 0.5714 (strength 0.512, masher 0.700, signature 0.619).
- **b0a0** 0.6828 rescored (strength 0.637, masher 0.812, signature 0.689). Its direction is off-string damage *instead
  of* J trades in the Shikai:
  - O / L enders off the pushing J3 / K3;
  - a far punish with K1 / O;
  - spikes on a sure hit;
  - SAIDAN 0.7 on a long guard;
  - an O that meets his Breaker;
  - a HARD neutral-band takeover.

  It measured the loom (Bankai) as the weak phase. Both loom band variants it tried made things worse.

## The direction: set-play conversion (structurally different from b0a0)

b0a0 made her *start* fewer J trades. This cell is about what happens *after* her placed threats hit:

- the spikes;
- the Divine Soldier's string;
- the hank zones (褥 freezes 40 f, 刃金 crumples, 黒砂 staggers and pulls, 焼野原 staggers).

A placed thing hits him where she isn't standing. The generic follow-up only fires within J1 + 0.6 m (about 2 m), so
almost every zone and soldier hit went unconverted. The policy, both forms:

1. **follow** (HARD 0.9). He is seen reeling (`:stun`, through the perception delay) beyond the generic follow-up
   distance. She picks the farthest-reaching hit that lands before he is free:
   - **K1**: the Shikai's 2.9 m, or the loom's TANMONO-UCHI 3.8 m. A string follows.
   - **The O**: the Shikai's flash step (aura 6 + the dash at 26 m/s + S 8), or the loom's lane (aura 8 + S 20, up to
     8.5 m). Its frames come from `senju-o-arrive`.
   - **Else what is already on him:** the spikes with >= 2 stitches (from f10), or the loom's TACHINAOSHI (two hanks
     under him, from f18).
   - **Not against a J masher** (`ai-mash-p`).
2. **oki** (HARD 0.9). He is `:down` / `:wakeup` (invulnerable) at 2.5–9 m:
   - **The loom, hitting hank next (刃金 黒砂 褥 焼野原), nothing live.** With nothing stored she weaves: he can't tear
     it while he is down. With a pass stored she taps the release, timed for 刃金 so it closes after his wake-up
     (43 f after the tap).
   - **The Shikai:** she sends the soldier (SP1).
3. **escort** (HARD 0.8). While her soldier rises, walks or strikes and he is beyond 2.4 m, her intent becomes PRESSURE.
   She walks in behind it, so its string and hers meet.
4. **The loom's enders.** TACHINAOSHI (two zones under him) ends a landed string at `:tachi-p`:
   EASY 0.3, NORMAL 0.5 (shipped), HARD 0.9; half that on a cross pair.

The Shikai's neutral, the loom's bands, the weave lengths and the awakening are unchanged. That is deliberate: this
cell tests conversion only.

## Iterations (seeds 1–20, the evaluator's jobs; diag = per-opponent wins of 40, masher of 16)

| version | change | str wins /160 | masher /80 | notes |
|---|---|---|---|---|
| baseline | | 82 | 56 | Rukia 7/40, masher Rukia 5/16 |
| v1 | follow (K1 / O) + escort | 91 | 43 | aieval 0.5695 (str 0.569, mash 0.537) |
| v1 − escort | | 89 | 46 | escort is noise-level |
| v2 | + no follow vs a J masher | 89 | 49 | |
| v3 | + escort back, + oki | 91 | 53 | |
| v4 | + follow falls back to spikes / TACHINAOSHI | 91 | 53 | the fallbacks rarely fire |
| v5 | + J1 timed against his Breaker dash (J beats I) | 94 | 53 | **Breaker damage taken rose** (IC 3.5 → 5.1 %, KE 2.2 → 3.2 %): reverted |
| **v6 (delivered)** | v4 + TACHINAOSHI ender at HARD 0.9 | 92 | 51 | |
| v7 | + loom "zone uptime" (tap a stored hitting hank, 5 %/step) | 86 | 47 | worse: reverted |

**The masher at 48 seeds** (diag, seeds 1–48) settles the noise question:

| | wins of 240 | Rukia | mirror |
|---|---|---|---|
| baseline | 156 | 10/48 | 21/48 |
| v2 | 153 | 11/48 | 17/48 |

So the 20-seed masher part (16 seeds per masher) swings about ±0.06 on chaos alone. The baseline's 0.700 at seeds 1–16
was a lucky draw; its 48-seed value is 0.65. **This policy neither helps nor hurts the masher.** Against a masher Rukia,
Senjumaru takes 100 % of her damage from RU-J1/J2/J3 (44 400 in 16 matches). Her own J is the same frames and reach
for 25 vs 34 damage, so she loses the J race.

## Measured (final file, aieval -j 4): score.json

| part | v6 | baseline |
|---|---|---|
| **Score** | 0.5944 | 0.5714 |
| **Strength** | 0.575 (92/160) | 0.512 |
| **Masher** | 0.637 | 0.700 (48-seed baseline value: 0.65) |
| **Signature** | 0.610 | 0.619 |
| **Pacing** | OK; medians 151–206 s, all 80 K.O. | |

- **Strength by opponent.** Kenpachi 32/40, Yamamoto 23/40, Ichigo 25/40, Rukia 12/40.
- **Masher.** The drop is the masher-sample noise described above.
- **Signature.** The follow-ups are mostly K1 links, so the share dips slightly. TANMONO-UCHI rose from 1.9 % to 3.9 % of
  her damage.
- **Damage taken** in the strength runs fell from 486k to 452k, and damage dealt rose from 366k to 389k.

**Verdict.** Set-play conversion is a real but small gain: +0.06 strength, about 1.5 sigma. It is clearly weaker than
b0a0's off-string-first policy (0.637 strength). The two touch different moments (b0a0 changes the choice of opener
and ender; this changes what happens after a placed hit or a knockdown), so they should **stack**.

## Why it is not a repeat

b0a0 has none of these mechanisms:

- the follow-up off placed-threat hits at range;
- oki with the loom's zones and the soldier;
- the soldier escort;
- the loom's TACHINAOSHI ender at HARD.

The one overlap is the O's arrival frames (`senju-o-arrive`). b0a0 used them as a punish; here they gate a follow-up.

## Risks

- `brain-react-roll` gates the follow and the oki. It is re-rolled only when he starts a new action, so one bad roll
  skips every stun until his next move. That is harmless at 0.9, but NORMAL's 0.15 / 0.2 means a stretch of nothing.
- Escort sets the intent directly. If AI-NEUTRAL's intent clock changes, it may fight the re-pick.
- The oki tap reuses `brain-why` (`:oki-tap`) to tell `senju-sig-hold` to tap. A future `why` refactor must keep that.
- The loom remains her weak phase. Neither oki nor the "uptime" variant fixed it; uptime made it worse.

## Recommendations for the next round

1. **Combine:** b0a0's v2 file + this cell's follow, oki and TACHINAOSHI-ender clauses. They don't overlap in trigger
   state (b0a0's far punish fires on a *recovering* move, this follow on a *stun*), so this is a cheap stack to try.
2. **Anti-Breaker.** A J1 pressed earlier against the Breaker dash (from where he is now, after the 8 f delay) made it
   worse. The generic window is not simply "too late". Either J1's 3 active frames whiff while he is still outside the
   needle, or a Breaker's strike beats a J that starts too far away. b0a0's O answer is the measured one.
3. **Shared code (not done).** The masher part needs more seeds, or the same seeds for every cell. At 16 seeds per
   masher its noise (±0.06) is as large as most policy effects.
