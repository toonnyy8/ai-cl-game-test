---
name: sim-balance-gates
description: Use when changing game rules, frame data, damage, reach, tuning knobs or CPU AI in a deterministic game sim, before calling the change done — or when match pacing, win rates, awaken/transformation balance, seed-gate medians or reference hash lines move, or a CPU behaviour needs measuring.
---

# Gating a deterministic game sim

## Overview
A balance change is done when **measured** gates pass, not when it compiles. The exemplar (SOUL DUEL in
`toonnyy8/ai-cl-game-test`, local `/media/8tsp/projects/ai-cl-game-test`) runs a fixed-step sim with a split RNG, so a
seed replays the same match bit for bit; every gate below relies on that. Details, numbers and evidence:
`reference.md`; the project's current policy text: `docs/duel/DUEL_GAMEPLAY.md` "Gate policy".

## Implement so it can be audited
- One knob in `tuning.lisp` (`defparameter` + docstring: old → new value, date, who decided, doc §). Never bury a
  number in code; never retune other knobs to compensate for a deliberate change of the user's.
- A chance of 0 must not roll; instrumentation counts, never rolls; side systems get their own RNG.
- Encode geometry/frame relations as host-test invariants (e.g. grab reach < every light-attack reach; art reach
  within ±0.15 m of the hit volume).

## The gate stack — run every layer the change touches
(`E` = the 32-bit host ECL, in the exemplar `/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl`.)
| Layer | Exemplar command | Pass |
|---|---|---|
| Host tests | `$E --norc --load tests/<t>.lisp` for rules, control, learn, input | ALL PASS |
| Seed / pacing gate | `python3 tools/simgate.py [--pairs ..] --summary` (native, same sources) | every match K.O.; cross-pairing medians in 125–210 s; mirrors may exceed 210 |
| Quick first pass (optional) | `--seeds 10` | passes at once only if all K.O. and the median is inside 135–200 s; else run 20 |
| Edge rerun | `--pairs k --seeds 60` | a 20-seed median outside the window is rerun at 60 seeds; that is the verdict |
| Awaken A/B | `--pairs k --seed0 {100,300,500} --seeds 60 --cmd 39020` | the "never awaken" side wins ≥ 20/60 on **every** stream |
| CPU vs masher | `tools/assistgate.py` | after AI/assist changes: report the masher's win % per difficulty |
| G2 reference | `tests/style-gates.py cvc dist/duel` | identical lines; on an intended change rewrite `tests/style-cvc-ref.txt` with a header note "after X (the user, date). Before: …" and update every place the reference line is quoted |
| Shipping build | `./build.sh duel` last | `dist/*/index.wasm` newer than every edited source |

Scope: a change inside one character's files → its pairings + its A/B; shared rules (combat, fighter, rules, ai,
tuning, kit) → all pairings. Take a baseline on the parent commit (`git worktree add` → run the same gate) whenever
you need to attribute a shift.

## When a gate fails
1. Measure where the time/wins go (counters, logged runs: one log file per process).
2. Pull the design's named lever; record what was tried and dropped, with numbers.
3. Still failing → **stop and report to the user** with before/after numbers and 2–3 options. Do not quietly retune
   unrelated knobs. If the user accepts, quote their words and date in the gate policy, the design §, the DEVLOG
   and the commit.

## Noise (read numbers with it)
20 seeds ≈ ±2 wins, ±5 after any extra RNG roll reshuffles the stream; 60 seeds ≈ ±4. A/B on one stream overfits →
three disjoint streams. Choose a setting by "every constraint satisfied", not by the single best number.

## CPU AI rules that keep recurring
- A reaction slower than the threat never fires → decide from what the CPU feels at once (its own state), read the
  opponent through the perception delay.
- Roll once per event, never per step (a per-step chance is a certainty).
- Use the real distance for the CPU's own movement, the perceived one for the opponent's intent.
- A held button can suppress the reflex path; add explicit exceptions.
- Every new mechanic gets a CPU rule (EASY ≤ NORMAL ≤ HARD chances) and a measurement (counts of uses and outcomes).

## Report template (design §, DEVLOG, commit)
"Gate (native, 20 seeds): all N K.O.; cross medians a–b (list); mirrors (list); [60-seed rerun]; A/B rows (all ≥ 20);
masher %; host tests rules/control/learn/input pass; G2: yy … yk … kk …". A change claimed inert shows bit-identical rows.
