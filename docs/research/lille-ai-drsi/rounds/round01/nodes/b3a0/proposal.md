# b3a0 (round 1, freeze 6081a39, decision 44): the sniper's discipline — spacing, the crossfire, combo enders, refusals

A new direction from the baseline that **combines** the engines the history proved (b1a0's EN web, KIN hit-and-run and
base HOSHA hunt / loop, taken as its port at this freeze) with **four new mechanisms**, the first of which fixes a bug both
earlier cells located but left to shared code. Only `duel/lisp/lille.lisp` changed, and only his CPU:

- the AI knobs (new `*LB-AI-SPACE*`, `*LB-AI-SPACE-NEAR*`, `*LB-AI-SPACE-RUSH*`, `*LB-AI-XFIRE*`, `*LB-AI-XFIRE-LIFE*`,
  `*LB-AI-CLEAN*`, `*LB-AI-GUARD-READ*`) and pure functions (`LB-AI-SPACE-RISK-P`, `LB-AI-SPACE-PLAN`, `LB-AI-REFUSE-P`,
  `LB-AI-ENDER-SP`), two `LBAI` fields;
- `LB-AI-KAMAE` (the stance plan), `LB-AI-LINK`, `LB-AI-SP-ENDER` (b1a0's `:sp-ender` hook) and new `LB-AI-*` shells
  (`LB-AI-XFIRE-P`, `-OK-P`, `-LIVE-P`, `-CANCEL-P`, `LB-AI-VETO-P`, `LB-AI-HOSHA-READ`, `LB-AI-ENDER-MOVE-SP`);
- the `(brain e)` branches of `LB-EN-TICK` (the crossfire's cancel), `LB-LINK-TICK` (the guard read, own CPU only) and
  `LILLE-OK`'s CPU clause (the refusals).

No frame data, damage, cost, rule, human branch, opponent-facing key (`:opp-trace :opp-reflex :opp-reflect :opp-aim`),
`LB-OPP-TRACE` or other file changed. The awakening (`AI-AWAKEN-P`, `:awaken`) and the revival (the generic `:bankai`
reflex) are untouched. Every new behaviour is a level by difficulty `(:easy 0 :normal 0 :hard 1)`, so EASY and NORMAL are
the shipped CPU bit for bit (drift and pacing identical to the baseline) and HARD runs deterministic rules (no new roll).

**Score 0.9869** = strength **0.993**, masher 1.000, signature **0.975** (the baseline 0.4480 = 0.098 / 0.995 / 0.525;
b1a0 rescored 0.9563 = 0.968 / 1.0 / 0.923; b0a0 rescored 0.9518).

## 1. The history read, and what it implied

- **Baseline** (0.4480): HARD strength 0.098; EN's `:moves` never fire at range (AI-ATTACK's reach filter), KIN neutral
  bleeds, the base form loses its exchanges.
- **b0a0** (0.9518 rescored) and **b1a0** (0.9563 rescored), round 1 at the old freeze, ported: the same two engines found
  independently: EN's J1 laid at him + TENSHIN's 2 f cancel (the line materialises 9 f after the press, inside a HARD CPU's
  8 f perception: unreactable for every frozen CPU), and the base HOSHA → K1 → L → HOSHA loop. Both measured well; neither
  had a bug in its engines. Their residue (my diagnostic of b1a0's port, 20 seeds: 194 / 200, signature 0.921):
  - **the generic ORANGE** (ai.lisp `AI-ORANGE-P`: any `:sig` hit with the victim within J1's reach + 0.2 m, rolled 0.4 at
    HARD) fired **1.98 times a match off a HOSHA** of the loop (the re-HOSHA from ~1.8 m lands its first bullet at
    ~1.45 m). Each one turned the loop into a plain J1-J2-K3 (base plain J / K = 5.6 % of his damage, the largest
    non-signature source) and burnt ~100 flash step (ORANGE drains 18 / s). Both cells flagged ORANGE as a shared-code
    recommendation; neither addressed it inside the kit.
  - their SP2 cash-out: once KIN's K3s go elsewhere, NIJUSHI-KO (40 f startup) follows J3's 26 f stagger and is guarded
    (measured below: 56 hits, 559 guarded of 690 at 40 seeds) and then punished (~100 damage a match taken).
  - the generic Breaker (`GUARD-BREAK` vs a long guard, `ANTI-PARRY`) is countered by HARD CPUs (J beats I): ~150 damage
    a match taken in the punish after it; the non-red O ender is guarded or perfect-Hohoed about as often as it lands
    (W-Kikon O ender: 1.96 hits, 2.38 guarded, 0.18 Hohos a match), ~130 damage a match taken.
- **archive/v1** (b0a0 0.9124, b1a0 0.9027, decision 39's rules): the snipe / snap opener (re-derived by both round-1
  cells on today's snap), the base HOSHA hunt, the SP2 enders, KIN's back-switch. Their measured dead ends: "HOSHA's link
  always K1" without L (the plain K string after K1; fixed by b0a0 / b1a0's L latch), the wary rule (neutral).

So the room left was in the **signature** (0.92 → ~0.98) and in the punishes he still eats. Another copy of the two
engines would add nothing; the located ORANGE leak, and the enders around the loops, would.

## 2. The action policy (HARD; EASY and NORMAL are the shipped CPU)

**Base 万物貫通: the hunter keeps his distance (間合い).** From b1a0: the hunt (the stance at an open opponent at
2.5–7.5 m, its branch HOSHA) and the loop (HOSHA's link K1 with L latched: the stance at f4 on the reeling opponent).
New — **the spacing rule** (`*LB-AI-SPACE*`, `LB-AI-SPACE-RISK-P`, `LB-AI-SPACE-PLAN`): the stance plans HOSHA only where
its first bullet lands **outside the ORANGE window**: from d, the leap (5 m, stopping 0.95 m short, f0–14) has covered
6/14 of it at the first bullet (f6), so d − 6/14 (d − 0.95) > 1.65 m needs d > 2.18 m (`*LB-AI-SPACE-NEAR*` 2.4; pinned
by a host check), + 5 m while he comes in (a run, a Step, a rush's dash: `*LB-AI-SPACE-RUSH*`), and only while ORANGE
could start at all (flash step ≥ 70, no burst running). Inside it:
- a **reeling** opponent (the loop's K1 just hit him at ~1.8 m): **TAISHA** — the 3 m back-slide, the 6 m line through
  guard from ≥ 3 m (no ORANGE: he is out of J1's reach), 60 flat, a stagger; the loop becomes bullets → K1 → the stance →
  TAISHA, ending with him at range ~5 m, where the hunt opens the next one with HOSHA (a fresh combo: no scaling, no
  blow-away count);
- an **open** opponent (close, or rushing in): the **HIRENKYAKU dash back** (3.5 m, iframes f0–8, the stance's one dash,
  10 flash step), then HOSHA from range; TAISHA when the dash isn't there.
- **The guard read** (adaptive, `*LB-AI-GUARD-READ*` 2, `LB-AI-HOSHA-READ` at HOSHA's link frame from his own move's
  contact): two HOSHAs guarded in a row → the hunt's next stance pierces with TAISHA once, then tries HOSHA again. Inert
  against the frozen CPUs (0.03 a match), the answer to a player who guards on seeing the stance.
- The base K3 (crumple) ends in L, the stance (HOSHA / TAISHA by the same rule), not SP2 (`LB-AI-ENDER-SP`; his CPU only:
  the ASSIST keeps HIRENKYAKU).

**Jilliel / owl 遠 EN.** b1a0's web (a J line at him every 6 f at 2.5–13 m, TENSHIN's 2 f cancel when its hit groups would
hit where he will be, the wary read), the starve rule. New — the crossfire's EN half (below).

**Jilliel / owl 近 KIN: the crossfire 十字砲火, and enders that combo.** From b1a0: KIN as the combo's vehicle (the
hit-and-run: TENSHIN out when free with nothing to punish). New:
- **The crossfire** (`*LB-AI-XFIRE*`, `LB-AI-XFIRE-P`, through the `:sp-ender` hook at the string's last link): KIN's K3
  crumple (40 f) latches L (the K link's L link) → TENSHIN out (10 m away) → its link is EN's J1 laid at him
  (`LB-AI-LINK`) → the line materialises at once through the 2 f cancel (`LB-AI-XFIRE-CANCEL-P`) → TENSHIN in (13 m) →
  KIN's J (the shipped trace-hit link) → the string … The trace combo carried through both modes: 5 + 14 + 7 + 2 = 28 f
  from K3's hit to the materialise, inside the crumple (pinned). Only with the flash step for the out price and a J line
  above the reserve. 3.2 a match.
- **Combo enders** (`LB-AI-ENDER-SP`): the SP that still combos off the last link — J3's stagger (26 f) → **SANREN**
  (1 bar, first line at f12, three lines through guard); K3's crumple (when no crossfire) → NIJUSHI-KO (its beam by f40).
  With nothing to spend, his own CPU returns `:NONE` at that frame: no generic SP2 into a guard, no ORANGE (KIN's
  hit-and-run then takes him out). 3.6 SANRENs a match.

**The refusals** (`*LB-AI-CLEAN*`, `LB-AI-REFUSE-P` through `LILLE-OK`'s CPU clause, `(brain e)` only): no Breaker (the
generic guard-break / anti-parry Breaker is countered by HARD CPUs); no non-red O ender where the crossfire or SANREN combos
off the same link (on a red opponent the Kikon always goes: it takes Konpaku). The generic reflexes see the refusal through
`KIT-COMMAND-OK-P` and pick their next option.

**MUJITTAI, Trompete, the eye, the awakening, the revival**: as shipped.

**Adaptation**, once per event, no roll: the spacing rule reads his approach at the stance's f6 (the shipped plan's
pattern: the sim's state at f6); the guard read reads HOSHA's own contact; the web's wary read (b1a0) reads its misses; the
crossfire and the enders read his own link's hit and gauges.

## 3. Measurement

EVAL_COMMAND (40 seeds), `score.json` is the last line it printed for the delivered file:

| | baseline | b1a0 (rescored) | **b3a0** |
|---|---|---|---|
| score | 0.4480 | 0.9563 | **0.9869** |
| strength (HARD, both seats) | 0.098 | 0.968 | **0.993** (397 / 400: Y 78, K 79, R 80, I 80, S 80 of 80) |
| masher | 0.995 | 1.000 | 1.000 |
| signature | 0.525 | 0.923 | **0.975** |
| drift (NORMAL share) | 0.4675 | 0.4675 | **0.4675** (Y 38, K 36, R 34, I 43, S 36 of 80: identical) |
| pacing Y / K / R / I / S (s) | 177.2 / 165.8 / 210.3 / 208.9 / 200.2 | identical | identical, all 40 / 40 K.O. |

Held-out seeds 41–80 (my diagnostic: the same HARD runs as the evaluator's strength part, `--seed0 40`): **398 / 400**,
signature 0.973. So the 80-seed strength is ~0.994.

`sig_by`, b1a0 → b3a0: trace-combo 0.247 → **0.287**, HOSHA bullets 0.252 → 0.180, HOSHA links 0.214 → 0.153, TAISHA
0.007 → **0.138**, traces 0.084 → **0.100**, SANREN 0.002 → **0.067**, Jilliel Kikon 0.049 → 0.027, NIJUSHI-KO 0.045 →
0.003, **plain J / K 0.072 → 0.024**, Breaker 0.004 → 0, counters 0.001.

Per match (HARD, 40 seeds): ORANGE off a HOSHA 1.98 → **0.15**; the spacing rule 14.2 (TAISHA 12.5, the dash-back
HOSHA 2.8); HOSHA 19.3 (47 bullet hits), its K1 links 16.5; crossfires 3.2; SANREN enders 3.6; trace hits 13.6, trace
combos 12.4; dealt 4178 / match. Damage taken in the punish after his own move, top items: b1a0-like variants had the
Breaker ~150, the non-red O ender ~130, NIJUSHI-KO ~100 a match; b3a0's largest is the neutral quick shot (~50).

The path inside the cell (diagnostic wins of 400 at seeds 1–40, signature; `+` cumulative, each a rebuild):

| step | wins | signature | |
|---|---|---|---|
| b1a0's port (20 seeds) | 194 / 200 | 0.921 | ORANGE 1.98 a match off HOSHA |
| + the spacing rule, TAISHA in ORANGE's window (reeling and open) | 389 | 0.961 | full eval **0.9735** |
| + the crossfire | 390 | 0.963 | |
| + no Breaker | 392 | 0.964 | |
| + no non-red O ender where the crossfire combos | 390 | 0.964 | dealt 3861 → 4025 |
| + the combo enders (J3 SANREN, K3 NIJUSHI-KO, else nothing) | **398** | **0.969** | full eval **0.9856**; held-out 392, 0.972 |
| + the base K3 → L; + the guard read | 398 | 0.969 | neutral (rare / inert vs CPUs), kept |
| + no non-red O ender where SANREN combos | 398 | 0.970 | held-out 394, 0.972 |
| open opponent in the window: HOSHA anyway | 394 / 394 held-out | 0.960 / 0.963 | worse |
| ... TAISHA, rush margin 1.2 | 394 / 397 | 0.966 / 0.965 | worse |
| **... the dash back, then HOSHA (final)** | **397 / 398** | **0.975 / 0.973** | full eval **0.9869** |
| ... the dash back in the reeling loop too | 397 / 391 | 0.966 / 0.964 | worse |
| the hunt from 0 m (20 seeds) | 195 / 200 | 0.966 | neutral, dropped |
| no non-red O ender at all | 197 / 200 | 0.959 | Kikon share lost, dropped |

Host tests: duel-rules **6379 ALL PASS** (the LILLE-CPU-TESTS section: b1a0's 3 checks + 6 new ones pinning the new
levels and knobs, the spacing geometry, the space plan, the enders and their frame budgets, the crossfire's frame budget,
the refusals; nothing outside the markers changed), duel-control 89, learn 100 ALL PASS; `tools/pkgcheck.sh duel` 0 / 0 / 0.
The awaken A/B was not run: the awakening and the revival are untouched and the A/B runs at NORMAL, where this CPU is the
shipped one bit for bit (the drift's NORMAL matches are identical).

## 4. Why it is not a repeat

- The two engines are taken over, credited, and not re-tuned (b1a0's knobs and test pins unchanged). What is new is
  structural: **the spacing rule** fixes the located ORANGE leak inside the kit (the cells could only recommend a shared
  opt-out) with an in-character answer — the sniper's back-step shot and his vanish-dash, not a burst lock; **the
  crossfire** is a new combo route through both of Jilliel's modes (TENSHIN out as a combo extender, not a reset);
  **combo enders** pick the SP by the frames the last link leaves (b1a0's SP2 cash-out, once the K3s went elsewhere, was
  guarded 559 times for 56 hits); **the refusals** use LILLE-OK's CPU clause to keep the generic reflexes off two
  measured losing moves.
- It is distinct from b2a0's brief (running in parallel from the same history) by construction: a bug-located fix plus new
  combo routes, rather than a third EN opener.

## 5. Expected benefit

His HARD CPU wins ~99 % of HARD CPU matches with 97.5 % of his damage his signature: the base form hunts with HOSHA and
resets its range with TAISHA or the HIRENKYAKU dash instead of being dragged into a burst and a plain string; Jilliel's
trace combo now runs through both modes (trace → KIN string → K3 → TENSHIN out → a line → TENSHIN in → …) and its strings
end in an SP that combos (SANREN / NIJUSHI-KO), never one into a guard. NORMAL and EASY are unchanged.

## 6. Risks

- **Pacing**: NORMAL is unchanged, so the medians are the baseline's: LS 200.2 (cap 220), LR 210.3 / LI 208.9 (cap 240);
  none within 15 s of its cap.
- **HARD may be too strong for a human** (inherited from the engines: the 9 f materialise, the HOSHA loop). The spacing
  rule makes base combos shorter but more frequent; the crossfire lengthens Jilliel's.
- **Real-state reads** at the stance's f6 (the opponent's distance, reeling, running / stepping / rushing) follow the
  shipped LB-AI-KAMAE pattern (its plan reads the sim's state at f6); the spacing rule adds his approach to that read.
- **The ASSIST** (b1a0's `:sp-ender` is called with the ASSIST's borrowed brain for a human): the crossfire, the `:NONE`
  ender and the base K3 → L are his own CPU's only (`(brain e)`); an assisted human now gets SANREN off KIN's J3 instead of
  b1a0's NIJUSHI-KO (which the stagger doesn't hold). `tools/assistgate.py` should be re-run at integration. The refusals
  are `(brain e)` only (an assisted human can still Breaker).
- **Learning CPU / neutral starvation**: no new reflex answers free steps (the refusals answer through the generic
  reflexes' own checks; the rest runs inside moves); BRAIN-DECIDE-T untouched.
- **Determinism**: no new random number at all (every new rule is deterministic); EASY / NORMAL draw exactly the shipped
  rolls.
- **Overfitting**: measured only against the frozen CPUs; the held-out seeds 41–80 agree (398 / 400).

## 7. Shared-code recommendations (not done)

1. ORANGE as a kit key (`:orange` by difficulty, or a per-kit opt-out off `:sig` hits): the spacing rule works around it,
   but a human's ASSIST still loses the loop to it.
2. AI-ATTACK's reach filter keeps EN's ranged J / K silent in `:moves` at NORMAL (b0a0 / b1a0's finding, still true).
3. The generic guard-break Breaker and the non-red O ender lose to HARD CPUs' J-beats-I and perfect Hoho for every
   character, not only Lille: a per-difficulty `:o-ender` / `:breaker` key would let a HARD layer drop them without a
   refusal hook.
