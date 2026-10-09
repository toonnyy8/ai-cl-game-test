# Refactor: the next round (backlog)

Recorded 2026-10-09 after the 2026-10 refactor merged (`REFACTOR_2026-10.md`, DEVLOG §153–§155). The user: 「把下一輪的修改事項紀錄下來，之後再執行」.
Nothing here is started. Each item says why, where, what to measure first, and how to know it is done. When the user asks
for the next round, pick from here, keep the same bar as 2026-10 (§ "Bar" below), and tick the item off with its DEVLOG §.

## Bar (unchanged from 2026-10)

- Refactors change no sim bit and no pixel: native simgate 15x10 rows byte-identical to the parent commit's, G2 cvc 3/3,
  the 8 host suites, pkgcheck duel + game, both builds 0 warnings, RAVEN G1, and `tests/style-gates.py looks BASE NEW`
  (108 stills byte-identical; BASE = a copy of `dist/duel` built from the parent, `--keep-base` for a series).
- Helpers expand to the text they replace (REFACTOR_2026-10 §8); no anaphoric names across the ENGINE / DUEL packages
  (names a body needs come from the caller, as `with-cam (rx ry rz ux uy uz)`).
- An allocation item is measured before and after with a consing probe; no probe, no change.

## Items

### N1. `defdebug`: the debug command table from one source (the user's item 2)
- Decided: 「第 2 項下一輪再做」(2026-10-09, after the macro discussion; REFACTOR_2026-10 §1).
- Why: `debug.lisp`'s dispatch is ~112 `cond` clauses on number ranges, and `docs/duel/DUEL_GAMEPLAY.md` "Debug commands"
  is written by hand. They drift: batch B2 found more than a dozen ranges the doc lacked.
- What: `(defdebug (from to) "doc line" (k) body)` registers a range, its handler (K = the offset in the range) and its
  table line; the dispatcher walks the ranges in declaration order (first match, as the `cond` does now); a host tool
  prints the table for DUEL_GAMEPLAY (or a check that the doc lists every registered range). Character ranges keep going
  through `*char-debug*`.
- Watch: clause order matters where ranges overlap (`(>= c 6300)` style fall-throughs in the viewer and debug.lisp):
  keep it explicit. Debug commands drive the gates: simgate rows and cvc must be byte-identical.

### N2. Ichigo's and Senjumaru's HUD meters: per-frame consing (was D11 / C12)
- Where: `ichigo-hud-meter`, `ichigo-deck`, `senju-hud-meter`, `senju-hud-label`, `senju-ring` (ichigo.lisp,
  senjumaru.lisp), Ichigo's `ic-rgb` boxing, `ichigo-live-clones`: `list`, `sort`, `remove-if-not`, `format nil`, boxed
  floats every frame.
- First: add a consing probe like Lille's (debug 79195, `lille consing`): one line per side of bytes per 10 draws of the
  meter, the deck, the ring. Claim a debug range in DUEL_GAMEPLAY first.
- Done when: the probe reads 0 B (or the remaining bytes are explained), pixels identical.

### N3. `hud-text`: ~200 B per call, dozens of calls per frame (the advisor's find)
- Where: duel/lisp/hud.lisp `hud-text` (block text on whole pixels). It is the biggest remaining HUD allocator, larger
  than everything removed in 2026-10's HUD batch.
- First: count calls and bytes per frame in a battle with a probe (both orientations, every form's HUD).
- Idea: cache the block quads per (string object, scale) since the strings are mostly constants (as `line-width` caches
  per string object); strings built per frame (numbers) need a fixed buffer instead.

### N4. Senjumaru's draw layer has no `defun-fast`
- Where: duel/lisp/senjumaru-art.lisp (`sj-seg`, `sj-prop`: generic double math, boxing; ~12 calls a frame for the
  echo arms alone).
- First: measure with a probe; do it together with the next Senjumaru rework, not alone. Pixel risk: a single-float port
  moves vertices by ulps, so the looks gate will differ; that makes it a look change for the user to accept, not a refactor.

### N5. `gate.lisp`: the gate machinery out of debug.lisp (with B3.3)
- Why: `debug.lisp` (now ~1150 lines) mixes the gate code (`start-cvc`, `gate-update`, `state-hash-line`, `hash-log`, the
  pacing printers) with scenarios and knobs; scenario churn risks the gate.
- What: move the gate code to `duel/lisp/gate.lisp` (MANIFEST before debug.lisp), and the character-specific scenarios to
  their characters' `*char-debug*` hooks (B3.3, ~500 lines). Pure moves; tools/simgate loads the MANIFEST, check its
  fixed lists anyway. Pairs well with N1.

### N6. `toon-ground-seg` into the engine
- Why it stayed in duel/lisp/stage.lisp: four sites read the macro's own `x0` / `z0` binding in a later argument
  (vfx.lisp ~703, ~726; rukia-art.lisp ~714, ~716), e.g. `(+ x0 (* e ux))` really adds to the macro's x0. In the engine
  that binding becomes `engine::x0` and the sites would read their own x0 (pixels change).
- What: rewrite those four sites with the value spelled out in the same float order (`(+ x0 (* 0.5f0 ux) (* e ux))`
  only if that is the same order as the old nested sum, else bind it explicitly), then move the macro; looks gate.

### N7. Smaller ones (do only with a reason)
- Per-side state created on the draw path: `(lb e)` / `(ic e)` / `(sj e)` can `add-component` when the HUD meter is the
  first reader (a render-path mutation of the ECS, same as before B8 in spirit). Attach the component in the kit's enter
  hook or at spawn instead, if creation order can be proven not to change any read (simgate + cvc).
- Lille's `*lb-ai*` / `*lb-as*` are not components (`*lb-as*` is keyed by the brain; a component would change when it
  resets). Leave unless the ASSIST gate is rerun.
- `*pacing-log*` stays T after a gate / cvc debug command in a browser session (as the counters always ran before 2026-10).
  Clear it in `go-title` if anyone cares; no gate line changes.
- Names: `gauges-red-p` reads like a GAUGES accessor; `reishi-frac` takes the gauges struct while `reiatsu-bars` takes the
  entity. A rename pass (mechanical) if a future reader trips on it.
- C4 `stamp-code` (read `*stamp-kinds*` at macroexpansion for the stamp magic numbers), C8 the art files' 138 long-form
  `with-xform` one-liners -> `mb-at`, C9 the sound shower helpers (needs an audio buffer diff tool first: no audio gate
  exists).

## Not to do (decided in 2026-10, with reasons in REFACTOR_2026-10 §7)
Fold `(expt x 2)` into `hypot`; swap `sqrt` / `f-sqrt` flavours; port the landscape cameras to single-float; merge `%h01`
with `hash01`; merge `ken-roll` with a plain chance; deep-merge `:ai` plists on `:inherit`; ASSIST state as a component;
a data table for the knob clauses; mirrored-joint DSL; `defstrike` sugar.
