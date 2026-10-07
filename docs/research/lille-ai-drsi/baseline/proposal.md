# Baseline: Lille Barro's CPU as shipped (the freeze commit)

The CPU the search starts from: `baseline/lille.lisp` (= `duel/lisp/lille.lisp` at the freeze commit). Sources:
DUEL_LILLE §19 (batch 3a), §22.4 (rework R), §23.4 (round 2), §23.11–§23.12 (the flash-step economy), §23.15 (the owl on
Jilliel's system), §23.23–§23.26 (decisions 41–44: the rules this freeze runs on). Its measured parts are `score.json` (the frozen evaluator, 40 seeds); the NORMAL drift reference is
`drift-ref.json`.

## Shape

- One kit `:reflex`, `LB-AI-REFLEX`, on every form, dispatching on the form; CPU branches inside the sim's ticks for the
  shooting stance (`LB-AI-KAMAE`), EN's walk (`LB-AI-EN-STICK`), EN's string (`LB-AI-EN-NEXT`), the HOSHA / TENSHIN link
  (`LB-AI-LINK`) and the flash-step reserve (`LILLE-OK`'s brain clause).
- Every chance is the kit's `:p` × `*LB-AI-DIFF*` (EASY 0.5 / NORMAL 1.0 / HARD 1.5, capped at 1): `LB-AI-CHANCE`.
- Every roll once per event: a threatening window (`LBAI-KEY`: his move's start tick or a hazard's spawn), an opponent
  action (the generic react roll), a stance (its plan at f6), a HOSHA hit (the link).
- The rest is the generic CPU (ai.lisp) driven by the forms' `:ai` tables (intents, ranges, distance bands of moves,
  guard / Hoho / dash chances, `:kikon-range`, `:awaken (:min-taken 150)`, `:bankai (:p 0.9 …)`).

## Per form

**Base 万物貫通 (`:base`)** — zone 8–20 m (intent weight 5), approach / pressure / defend 1 / 1 / 2.
- Bands: 0–2.2 m J 4, K 2, Breaker 1, Step 2, the stance 1; 2.2–6 m SP2 HIRENKYAKU 2, Step 2, SANREN 1, the stance 2, wait
  1; 6 m+ the stance 6, SANREN 1, wait 1.
- The shooting stance's branch, picked once at its f6 (`LB-AI-KAMAE-PLAN`, one roll): after a K link's hit (the opponent
  reeling) the quick shot 0.6 / HOSHA 0.4; ≥ 8 m the charged shot; 6–8 m the quick shot on a whiff, else the dash back then
  the charged shot (one dash a stance, its flash step), else charged; 3–6 m the quick shot on a guard or a whiff, else
  HOSHA; ≤ 3 m TAISHA.
- HOSHA's link (one roll after a bullet hit): J1 0.5, else K1.
- The eye (`LB-AI-EYE`, `:eye (:p 0.5)`) replaces the generic guard reflex: on a threat one roll: the eye (U tapped at a
  perceived lead of 1–4 f, a pip left and U rested), else a Step off a lane / a Breaker / a red Kikon, else a guard (its
  share by the guard gauge), else a Step. The third opening gives EVOLUTION; P follows `AI-AWAKEN-P` (`:min-taken 150`).
- `:l-after-k 0.4` (the stance after a K link), `:o-ender 0.3`, `:guard 0.5`, `:hoho 0.3`, `:kikon-range 7.7`.

**JILLIEL 遠 EN (`:jilliel`)** — keeps 6–12 m (`LB-AI-EN-STICK`: out past 12 in, under 6 back, always strafing across the
opponent's line); J / K lay traces (bands 3–14 m K 4, J 3, SP1 1, SP2 1).
- A J / K only while its lines leave ≥ 10 flash step (`*LB-AI-FS-RESERVE*`, `LB-AI-LAY-OK-P`); its next link latched
  under the same rule (`LB-AI-EN-NEXT`).
- TENSHIN in (`LB-SWITCH-IN-RULE`, deterministic): ≥ 3 live traces and the perceived opponent on one (≤ 0.6 m, not
  running / stepping / Hoho-ing for the 16 f wind-up), or reeling / recovering within 1.5 m of one long enough; through a
  J1's 2 f cancel when its line is paid (via-J), else from neutral (16 f); starved (no J line above the reserve) it
  switches in from neutral (free).
- The gap to a trace is read as the trace would materialise: turned toward him by up to 10° (`LB-AI-TRACE-GAP` with
  `LB-SNAP-YAW`, decision 41). There is no laying shot any more (decision 39's 10 f flinch is gone): a trace hits only
  when TENSHIN materialises it. His crossing onto a live trace slows the match (0.1 for 0.3 s of real time; the sim's
  frames are the same).
- TENSHIN in dashes up to 13 m at him, out 10 m away (decision 43), the dash his only movement (the K → L chase fixed).
- The slow motion fires when he steps onto the live traces after ≥ 10 sim frames off all of them (decision 44, §23.26).
- After TENSHIN in, J1 when a materialised trace hit (the combo; no roll).
- The stance MUJITTAI only as a reaction (`LB-AI-STANCE-IN`, `:stance (:p 0.6 :max 180 :gg 30)`): a move starting
  within reach + 1 m or a hazard within 12 f: one roll: U; else a Step off a lane, a Hoho on the generic roll, or nothing
  (never the generic guard: `:neutral-guard 0.0`).
- The revival (`:bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1)`), the generic reflex with the kit's `:bankai-ok`.

**JILLIEL 近 KIN (`:jilliel-kin`)** — pressure 1.4–2.4 m (intents approach 3, pressure 4, defend 1), strings J / K 4 / 4
within 2.4 m, Breaker 1; `:o-ender 0.5`, `:dash 0.8`.
- TENSHIN out (`LB-AI-KIN`) after any string (blocked or not) or with the guard gauge under 40, only with the price + the
  reserve + a K fan's lines (`LB-AI-OUT-OK-P`, ≥ 29 flash step); else the stance reflex.

**MUJITTAI (all four stances)** — leaves only by attacking (`LB-AI-STANCE-OUT`, deterministic): his whiff / recovery,
180 f, the gauge under 30, or him out of reach + 1 m and idle; the attack: K1 if he stays busy for it in reach, J1 in
reach, else L (TENSHIN).

**The owl 真の姿 (`:shin` EN / `:shin-kin` KIN)** — Jilliel's EN / KIN CPU (decision 36), no revival; KIN adds Trompete's
punish (`LB-AI-TROMPETE`, `:trompete (:p 0.5 :left 30)`: SP2 beyond J's reach on him busy ≥ 30 f, the react roll) and
SP2 from 8 m in its far band.

**Opponents facing him** (not his CPU; frozen): `:opp-trace (:p 0.5)` / `LB-OPP-TRACE` (a Step off a seen trace while his
TENSHIN is ready), `:opp-reflect (:p 0.3)` (the owl KIN's Trompete).

## Known weaknesses (DUEL_LILLE §19–§23 measurements)

- His seed-gate win counts are low against most of the roster (§23.21: LY 13, LK 6, LR 6, LI 8, LS 6 of 20) and his
  NORMAL matches are long (LR / LI past 210 s: accepted exceptions).
- Trompete's punish almost never finds its 30 f opening (0.1–0.2 a match); the owl lives briefly.
- The base form alone loses: the awaken A/B (a never-awaken P1 Lille, 39020) won 0–4 of 60 on every stream (§20.3; the
  user: 「先試玩再決定」, §20.7, still open). His CPU fought 85–90 % of the base form under 6 m (§20.7): a sniper with no
  way back to range.
