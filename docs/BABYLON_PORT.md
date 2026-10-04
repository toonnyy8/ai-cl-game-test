# SOUL DUEL on Babylon.js + TypeScript (`babylon/`)

The user's request (2026-10-04): build a Babylon.js + TypeScript version of SOUL DUEL from the duel design docs, with
Fable 5.1 as the discussion advisor. Decisions:

- **Scope:** staged, up to full parity (the user, 2026-10-04): a playable core slice first, then the roster, awakenings,
  cinematics, VFX, touch, ASSIST, ENDLESS, one committed milestone at a time.
- **Location:** `babylon/` in this repo, its own Vite + TS package, committed to main; it shares `docs/` with the Lisp
  build (the user, 2026-10-04).
- **Models and animations may be redrawn** (the user, 2026-10-04): the Babylon version does not have to copy the Lisp
  rig, `*-art.lisp` clips or body parts; it designs its own models and motions. What stays fixed is the sim's frame data
  (startup / active / recovery, reach, hit volumes, cinematic lengths): an animation is timed to the move's frames,
  never the other way round.

## Strategy (Fable 5.1's recommendation, adopted)

- **The sim is translated, not redesigned.** `duel/lisp` is the source of truth (the docs lag it). `tuning`, `rules`,
  `control`, `kit`, `components`, `fighter`, `combat`, `hazards`, `ai`, `learn`, `assist`, the match part of `flow`,
  `endless-rules`, the character files' data and hooks, and the engine pieces they lean on (`input.lisp` vpad,
  `hitvol.lisp`, `time.lisp`, `engine/c/rng.c`) become TS modules of the same names and the same function names
  (kebab → camelCase).
- **The presentation is rewritten for Babylon:** `*-art`, `body`, `vfx`, `brush`, `glyphs`, `stage`, `hud`, `camera`,
  `cinema`, `sounds`, `onehand`, `feedback`. Only their contracts are kept: clip names per move, cinematic lengths
  (cinematics are sim time and count toward the match clock), the sim-owned view the human stick steers by.
- **Not bit-exact with the Lisp build** (it already needed musl `sinf`/`expf` and SSE flags to agree with itself,
  DEVLOG §38). Parity means: (1) self-determinism (same seed → same hash lines), (2) the rules tests ported from
  `tests/duel-rules-test.lisp` pass, (3) a statistical seed gate: CPU vs CPU NORMAL, all K.O., per-pairing median within
  about ±15 % of `DUEL_AI_V2.md` "Gates (final)" and inside 125–210 s for the cross pairings.

## Layout

```
babylon/
  src/sim/     tuning rules rng vpad hitvol time kit types fighter combat hazards ai flow match   (no Babylon imports)
  src/chars/   yama ken rukia ichigo senjumaru                                                      (no Babylon imports)
  src/render/  scene bodies anim vfx hud camera cinema audio
  src/input/   keyboard gamepad touch   (device → vpad)
  src/main.ts  frame loop: flow → fixed steps (≤ 6 per frame) → camera → draw → HUD
  tools/       headless.ts (node match runner, prints `duel -> RESULTS ...` and hash lines), gate.ts
```

- No ECS: two fighters and a hazard array owned by a `Match`.
- Floats are doubles; integer frame counters stay integers; CL `round` is half-even (`roundHalfEven`), CL `mod` on
  negatives is `((a % n) + n) % n`.
- Gameplay randomness only from the sim stream (xorshift32 of `rng.c`) inside fixed steps; cosmetics use another.

## Traps to copy verbatim (from the advisor's read of the Lisp)

Collect-then-apply hits (`pending` with the defender's state at collection); deferred cross-fighter writes
(`freeze-next`, `lock-next`, `fighter-burst`, `glock`) applied after both fighters stepped, and `ox/oz/dist` snapshotted
before anyone moves; devices read during hitstop / slow motion / cinematics without advancing the vpad clock, flushed at
a cinematic's end; the vpad's 10-step buffer, same-step modifier, command priority (a refused command never hides lower
ones); the string latch; guard-gauge idle frozen while guarding; the Kikon follow-up (button held on the hit step,
`kikon-n` read at rush start, caps 4 / 5, one cinematic per step); slow motion by step skipping; `start-match` resets
the seed, `slowAcc`, hitstop and pending; the hidden hit-stun; `fighter-step` counter order.

## Milestones

| M | Ports | Accept |
|---|---|---|
| M1 core | tuning, rules (+ tests), rng, vpad, hitvol, time, kit, components, fighter, combat, battle flow; Yamamoto and Kenpachi base kits (no awakening / meter); capsule bodies; Canvas HUD; keyboard | `npm test` green; headless YY / YK / KK deterministic with a stub AI; playable in the browser |
| M2 CPU | `ai.lisp` with both base kits' `:ai` tables | headless gate: YY / YK / KK all K.O., medians within range |
| M3 depth | hazards, Inferno / Hellfire, awakenings (Bankai, Nozarashi cups, NOME, Ken Bankai), hidden stun, burst modes, guard lock / cancel; cinematics as length-only | 3 pairings + awaken A/B |
| M4 roster | Rukia, Ichigo, Senjumaru | 15 pairings pass the gate |
| M5 look | new Babylon models and motions (redrawn, timed to the frame data), VFX, real cinematics, audio | visual review; gate unchanged |
| M6 platform | screens, touch deck, ASSIST, practice, ENDLESS, learning CPU | phone smoke test, ENDLESS run |

## Status

- 2026-10-04: plan adopted, scaffold created.
- 2026-10-04: M1-sim (headless) translated: `src/sim/{tuning (generated from tuning.lisp), math, rng, hitvol, time, vpad,
  rules, kit, types, fighter, combat, hazards, match, stubai}.ts`, `src/chars/{yama,ken}.ts` (base forms only),
  `tools/headless.ts`, `test/rules.test.ts`. A `Match` owns a `World` (the Lisp's sim specials) and makes it current for
  its steps; hooks are looked up by name (a missing one is a no-op); cinematics are length-only (`CINES`: `:len` + the
  frame-0 `face-each-other` gap). Deferred: Hellfire (the full Inferno meter stays full), every awakened form (Awaken /
  Bankai refused until their kit is registered), ai.lisp (M2; `stubai.ts` stands in, set with `setBrainStep`), device
  bindings / CONTROLS / SETTINGS (src/input), the Bodies table holds only hurt cylinders. Known divergence: hazards
  iterate in creation order, the Lisp ECS in slot order (only matters when two hazards hit on one step).
- 2026-10-04: M1-render: `src/main.ts` (WebGPU, WebGL2 fallback; flow title → select → battle → results, Esc pause; fixed
  steps via `runFixedSteps`, ≤ 6 a frame), `src/render/{scene,camera,hud}.ts` (placeholder look: the stage.lisp plaza,
  hurt-cylinder capsules with a head, a face marker and a sword timed to the move's hit frames; camera.lisp's pair and
  behind cameras on the sim's view; hud.lisp's panels in plain type), `src/input/{keyboard,gamepad}.ts` (control.lisp
  P1 bindings). VS CPU sets `W.viewBehind`; length-only cinematics dim the screen with their name. `window.duel.match`
  is the harness handle (`tools/run.mjs babylon/dist --script ...`, eval `duel.match.runToEnd()`).
- 2026-10-04: Fable 5.1's fidelity review of M1-sim: faithful on every listed trap and 14 sampled moves, all 220 tuning
  knobs equal. Fixed from it: hazards keep the Lisp ECS's lowest-free-slot order (dead ones stay as holes, readers skip
  them); `defkit` also walks a parent's shadowed command moves (the Lisp's appended plist, `Kit.cmdMoves`); `hitDamage`,
  `chipDamage`, `cutValue`, `stanceStore` round each product to f32 like the single-float Lisp, so integer damages match
  the design tables (test/damage32.test.ts).
