# RAVEN EDGE — Architecture

A Ninja-Gaiden-4-style 3D action demo written in Common Lisp, compiled by ECL to C, then by
Emscripten to WebAssembly. SDL3 provides window, input, timing, audio and rendering: **SDL_GPU on
its WebGPU backend** (WGSL shaders). There is no OpenGL/WebGL code path.

The code is split in two: a reusable **engine** (`engine/`, package `ENGINE`) and the **game**
built on it (`game/`, package `RAVEN`). `examples/` holds two more games on the same engine:
`hello` (the smallest one, the tutorial's starting point) and `engine-demo`. A beginner's tour of
this document's contents is `docs/TUTORIAL.zh-TW.md`.

## Why SDL_GPU + WebGPU works here

Upstream SDL 3.2 has no web backend for SDL_GPU. We build SDL from the draft WebGPU backend
(libsdl-org/SDL PR #16020, pinned commit) plus local fixes (`vendor/sdl3-webgpu.patch`, every hunk
marked `raven-edge patch:`; `tools/vendor-sdl3-webgpu.sh` rebuilds `vendor/sdl3-webgpu` and fetches
Dawn's `emdawnwebgpu` port into `vendor/emdawn`). SDL is built without OpenGL/GLES/SDL_Renderer,
so no GL/WebGL library code is linked. The patches:
* **Pre-initialized device.** Requesting a WebGPU adapter/device is async; doing it from wasm would
  block, which needs ASYNCIFY or JSPI. We can use neither: ECL's `setjmp`/`longjmp` go through JS
  `invoke_*` wrappers, which JSPI cannot suspend across. So `engine/web/shell.html` requests the adapter
  (`powerPreference: 'high-performance'`, then default) and device (all adapter features) in
  `Module.preRun` behind a run dependency, sets `Module.preinitializedWebGPUAdapter/Device`, and
  the patched `SDL_CreateGPUDevice` imports them.
* **Non-blocking swapchain acquire.** `SDL_AcquireGPUSwapchainTexture` now polls finished command
  buffers itself (upstream only did that in the blocking `WaitAndAcquire`, so every frame after
  the first returned NULL). A NULL texture means "skip drawing this frame"; the sim still runs.
* `IndirectFirstInstance` made optional (SwiftShader lacks it; we never draw indirect); the canvas
  selector string length initialized; device-lost reason logged.
* **Bind groups only when changed.** Upstream re-resolved and re-set all four bind groups on every
  draw; the patch sets only the outdated ones. Measured 258 draws: 0.55 ms → 0.03 ms of recording.
* The emscripten video driver skips its GLES hooks when SDL is built with `-DSDL_OPENGLES=OFF`.

**Browser requirement:** a WebGPU-capable browser: Chrome / Edge 113+ (Windows, macOS, ChromeOS;
Linux depends on GPU/driver), Safari 26+, Firefox 141+ on Windows. Without WebGPU the page shows
"WEBGPU UNAVAILABLE"; a lost device shows "GRAPHICS DEVICE LOST" (reload).

## Build pipeline

A build target is a directory with a `MANIFEST`: one source file per line, relative to that
directory, in compile order (`#` lines are comments; `# title: NAME` sets the page title).
`engine/MANIFEST` always comes first.

```
engine/MANIFEST + <target>/MANIFEST (.lisp lines, in order) ──(concatenated)──► build/NAME/game-all.lisp
   │  32-bit host ECL (ecl-emscripten-host) compile-file :system-p t, CC=emcc (tools/build.lisp),
   │  -Ivendor/sdl3-webgpu/include -I<root>; WGSL files are read at compile time (render.lisp WGSL macro)
   ▼
build/NAME/game-all.o + libgame.a (init fn: init_game)
   │  emcc  the .c lines (engine/c/*.c, game/c/world.c) + libgame.a + vendor/ecl/{libecl,libeclgc,libeclgmp}.a
   │        + vendor/sdl3-webgpu/lib/libSDL3.a + --use-port=vendor/emdawn/.../emdawnwebgpu.port.py
   │        -sEXPORTED_RUNTIME_METHODS=addRunDependency,removeRunDependency
   ▼
dist/NAME/{index.html,index.js,index.wasm}   (shell: engine/web/shell.html, title from the MANIFEST)
```

* `./build.sh` builds `dist/game` from `game/MANIFEST`; `./build.sh DIR` builds `DIR/MANIFEST`
  into `dist/<basename DIR>` (e.g. `./build.sh examples/hello`).
* `./build.sh NAME a.lisp b.c …` builds a test target `dist/NAME` from the engine plus the given
  files (use your own NAME so parallel work does not collide).
* `node tools/run.mjs dist/NAME --secs 8 --shot out.png [--script steps.json]`
  runs it in headless Chrome (SwiftShader WebGPU), prints the console, replays
  scripted key/mouse input (and `{"at":t,"size":"800x450"}` resizes), takes screenshots.
  Exit code 1 on JS exceptions. WebGPU validation errors print as `WebGPU: …` console errors.
* `tools/pkgcheck.sh DIR` reads (does not compile) the engine and a target's sources and lists
  target symbols that shadow ENGINE internals, i.e. probable missing exports (see below).
* Host tests, no build: `tests/ecs-test.lisp`, `tests/rules-test.lisp`, `tests/test-math.lisp`
  (commands in their headers).
* `vendor/ecl/` holds the wasm32 ECL 24.5.10 static libs + headers, assembled
  from `/media/8tsp/projects/ecl-24.5.10/build` (see `tools/vendor-ecl.sh`).
  Note: libecl itself was built with `-O0`; our Lisp code is built `-O2`.

All Lisp sources of a target are **one compilation unit** (concatenated). Consequences:
  * order in the MANIFESTs matters: define macros/structs/constants/components before use;
  * compiler errors report positions in `build/NAME/game-all.lisp`
    (each file starts with a `;;;; ---- engine/lisp/file.lisp` banner);
  * C lives in real files (`engine/c/`, `game/c/`), declared in one header per side
    (`engine/c/engine.h`, `game/c/world.h`) that the Lisp includes with `ffi:clines`; the Lisp side
    only has thin `ffi:c-inline` calls. Keep the C prefixes (`pf_`, `r_`, `au_`, `w_`).
  * one package per side: `ENGINE` (engine/lisp/package.lisp exports the public API) and the
    game's (`RAVEN`, `(:use :cl :engine)`; the examples have their own). A game file that uses an
    engine name that is not exported silently gets its own symbol: ECL warns for variables, not
    for functions. Run `tools/pkgcheck.sh DIR` (e.g. `game`).

## Render pipeline (one command buffer per frame, `r_frame` in engine/c/render.c)

```
copy pass     draw records (storage buffer) · fx alpha/add vertices · UI vertices   (one writeBuffer each)
scene pass    MSAA 4x RGBA8 + D32 at window × *render-scale*: sky → opaque → transparent → fx alpha → fx add
              └ resolves into the scene texture
bloom         bright (1/2) → blur H/V (1/2) → blur H/V (1/4)          5 small full-screen passes
swapchain     composite (scene + bloom + vignette) → UI batch (font atlas, nearest)
```
* Per-frame uniforms (WGSL `Frame`: matrices, fog, ambient, moon, rim, 8 lights) are pushed once to
  vertex and fragment slot 0. **Per-draw data** (model, tint, emissive/flash/specular, rim) is not
  pushed per draw: `*dq*` records are laid out exactly as WGSL `struct Draw` (112 B,
  `engine/shaders/lit-io.wgsl`) and uploaded as one storage buffer; each draw is
  `SDL_DrawGPUPrimitives(count, 1, first_vertex, record_index)` and the vertex shader reads
  `draws[instance_index]`. Measured with 258 draws (engine demo, RTX 4090): storage buffer 0.03 ms
  record + 0.07 ms submit vs per-draw `SDL_PushGPUVertexUniformData` 0.10 ms + 0.23 ms (a malloc
  and a `queue.writeBuffer` per push).
* Meshes live in shared 4 MB vertex buffers (mesh = chunk, first vertex, count), so consecutive
  draws rarely rebind a vertex buffer. Mirrored transforms use a clockwise-front pipeline variant.
* Clip-space depth is WebGPU's [0,1]: `m4-perspective!` produces it directly.
  Render-target UVs run top to bottom (`uv.y = 0.5 - ndc.y/2`).
* Shaders are files in `engine/shaders/` (`*.vert.wgsl`, `*.frag.wgsl`; plain `*.wgsl` are shared
  pieces pulled in with a `// #include "file.wgsl"` line). The `WGSL` macro (render.lisp) reads
  them at compile time, resolves includes and strips comments; editing a shader needs a rebuild.

## Runtime model

`engine/c/main.c` (a game registers itself with `RUN-GAME`, engine/lisp/app.lisp):
1. `cl_boot`, then **`GC_disable()`**, then `ecl_init_module(init_game)`, then one collection.
2. runs `ENGINE::%INIT-STEP` once per animation frame until it returns 0 (1 = more steps, 2 = failed),
   with a full GC after each step: `ENGINE-INIT` (window, GPU, UI), the game's `:load` steps
   (RAVEN: world ×2, bodies), opening the audio device, one step per `DEFSOUND`, then the game's
   `:start`. The page's loading bar follows `Module.engineLoading(pct)`. Heap after startup
   (console `startup: heap …`): RAVEN EDGE 87 MB, examples/hello 23 MB; stepwise loading brought
   RAVEN's peak down from 199 MB (wasm memory 237 → 128 MB). Most of RAVEN's remaining heap is ECL
   reading the module's literal data inside `ecl_init_module`, where GC must stay off. (The
   ECS/rules restructure added 1.8 MB there, which crossed a Boehm heap growth step: 71 → 87 MB.)
3. `emscripten_set_main_loop` calls `ENGINE::%FRAME` every animation frame: platform poll,
   `BEGIN-FRAME`, queued `Module._debug_cmd(n)` commands (→ the game's `:debug`), the game's
   `:frame`, `END-FRAME`. Returning `NIL` stops the loop. Any unhandled Lisp condition unwinds to C
   and stops the loop, so `%FRAME` (and `%INIT-STEP`) `handler-case` and call `show-fatal`, which
   puts the condition text on the page (`Module.engineFatal`, engine/web/shell.html).
4. After each frame, if > 24 MB were consed, runs `GC_gcollect()`.

### The GC rule (important)
Without ASYNCIFY, Boehm GC cannot see pointers held in wasm locals. So the
collector is disabled while Lisp runs and only collects **between frames**,
when no Lisp code is on the stack. Therefore:
* **Never** call `(ext:gc)` / `GC_gcollect` from Lisp.
* A C static holding a Lisp object must be registered with
  `ecl_register_root(&var)` (the data segment is *not* scanned on wasm).
  Prefer keeping Lisp objects in Lisp `defvar`s; C code gets Lisp arrays for one call only.
* Keep per-frame consing low (budget: a few hundred KB/frame is fine; a full GC
  on a ~32 MB heap costs a few ms). Heavy allocation (meshgen, sound synthesis) belongs in
  startup steps, which are each followed by a collection.

## Game structure: ECS, rules, events

`engine/lisp/ecs.lisp` is a small Entity-Component-System plus an event queue (plain CL, tested on
the host by `tests/ecs-test.lisp`):
* **Entity** = a fixnum handle, slot + 256 × generation (256 slots). `DESTROY-ENTITY` bumps the
  slot's generation, so a kept handle stops matching: `ENTITY-ALIVE-P` is NIL and every component
  getter returns NIL. Entities can hold each other's handles safely.
* **Component** = a struct defined with `DEFCOMPONENT` (`MAKE-X`, `X-SLOT` accessors) plus the
  getter `(x e)`. One store vector per kind (max 64 kinds), indexed by slot.
* **System** = an ordinary function using `(do-entities (e comp (var comp2) …) body)`, which
  visits every entity that has all the listed components, in slot order. A frame (or fixed step)
  is a list of systems called in a fixed order.
* **Events**: `(emit kind data…)` queues a list, `(take-events)` returns them oldest first.

RAVEN EDGE uses them this way:
* `game/lisp/components.lisp`: every component; the header lists which components make REN, an
  enemy, a training dummy and a projectile. Particles, rain, debris and trail vertices are **not**
  entities: they live in flat float pools (engine/lisp/fx.lisp, game/c/world.c).
* `game/lisp/rules.lisp` — the functional core: pure functions (hit volumes, hit outcomes on an
  enemy / on REN, cancel windows, Raven gauge, tokens, windup skip, weighted pick, ENRA's attack
  choice, waves, score, rank). Arguments in, values or small structs out, randomness passed in as a
  number. Plain CL, so `tests/rules-test.lisp` loads it on the host.
* The imperative shell (systems in combat.lisp, player.lisp, enemy.lisp, projectiles.lisp,
  game.lisp) gathers a rule's inputs from components, calls it, and applies the result **in
  place**. Components are mutated, not copied, because ECL boxes floats in structs and lists
  (see below): copying per step would multiply consing and GC pauses.
* Systems report what happened as events (`emit-hit`, `emit-block`, `:killed`, `:player-hurt` …);
  `FEEDBACK-SYSTEM` (feedback.lisp) turns them into sounds, particles, shake, hitstop and slow-mo
  at the end of each fixed step and once per frame.
* Data files are declarative: `moves.lisp` (DEFMOVE), `bodies.lisp` (DEFBODY), `clips.lisp`
  (DEFPOSE / DEFCLIP), `sounds.lisp` (DEFSOUND); balance knobs are in `tuning.lisp`.
* `main.lisp` is the whole frame: input → game flow → fixed 60 Hz steps (`SIM-STEP`: player,
  enemies, projectiles, separation, tokens, feedback) → camera → draw → HUD.

## Performance conventions (ECL specifics)

* single-floats are **boxed** when stored in generic places (lists, untyped
  struct slots, `defvar`s, generic arrays). They are unboxed in
  `(simple-array single-float (*))` and in declared local variables.
  → Hot data (transforms, particles, vertex buffers) lives in
  `(simple-array single-float (*))`; hot functions declare types.
* File header: `(declaim (optimize (speed 3) (safety 1) (debug 0)))` is set in
  `package.lisp`; use `(safety 0)` locally only in proven inner loops.
* Components are structs (DEFCOMPONENT = DEFSTRUCT): slot access compiles to direct vector access.
  Numeric fields that change every step should be `:type single-float` (ECL still boxes them on
  write, so hot vectors are f32vec slots, e.g. `transform-pos`, `motion-vel`).
* Passing arrays to C: `(ffi:c-inline (v) (t) :void "f(#0->vector.self.sf)")`
  for `(simple-array single-float (*))`; `->vector.self.b8` for
  `(unsigned-byte 8)` arrays. Handles (mesh ids) are `:int`.

## Module map (in MANIFEST order)

`engine/` (package `ENGINE`, knows nothing about the game):

| file              | responsibility                                              |
|-------------------|-------------------------------------------------------------|
| lisp/package.lisp | package `ENGINE` + exports, global declaims, DEFUN-FAST, F-* float macros, RND01 |
| lisp/math.lisp    | vec3 / mat4 on single-float arrays (pure CL)                 |
| lisp/platform.lisp| SDL3 window, time, events → input state (C: c/platform.c)    |
| lisp/render.lisp  | SDL_GPU pipelines, WGSL loader, camera, lights, meshes, draw queue, fx batch (C: c/render.c, shaders/*.wgsl) |
| lisp/meshgen.lisp | procedural mesh builders (box, cylinder, cone, blade, tube…) |
| lisp/ui.lisp      | embedded bitmap font, 2D UI batch (rects, text, bars)        |
| lisp/audio.lisp   | mixer API, synthesis toolkit, DEFSOUND, stepwise loader (C: c/audio.c) |
| lisp/anim.lisp    | humanoid rig, pose / clip DSL, playback, blending, FK        |
| lisp/time.lisp    | fixed step, hitstop, slow-mo                                 |
| lisp/fx.lisp      | shake, particles, rings, debris, trail buffers, edge vignette |
| lisp/ecs.lisp     | entities, components, systems, events                        |
| lisp/app.lisp     | `RUN-GAME`, startup steps, frame driver, debug queue, stats line |
| c/main.c          | boot ECL, GC policy, browser main loop, page hooks            |
| web/shell.html    | page shell: WebGPU pre-init, loading bar, error veil          |

`game/` (package `RAVEN`):

| file                  | responsibility                                              |
|-----------------------|-------------------------------------------------------------|
| lisp/package.lisp     | package `RAVEN`, `CLOG` (the dev combat log)                 |
| lisp/tuning.lisp      | every balance knob (speeds, windows, damage multipliers, tokens) |
| lisp/sounds.lisp      | data: the sound bank (every SFX, rain, music) as DEFSOUNDs   |
| lisp/world.lisp       | arena scenery, skyline, env look, rain, arena collision (C: c/world.c) |
| lisp/clips.lisp       | data: the pose / clip library (DEFPOSE / DEFCLIP), all characters |
| lisp/rules.lisp       | the functional core: plain-CL pure rules (hit volumes, hit outcomes, cancels, tokens, score…), tested by tests/rules-test.lisp |
| lisp/moves.lisp       | data: DEFMOVE and every move / hitdef (REN, enemies)         |
| lisp/effects.lisp     | fx presets (mist, sparks, dust, orbs), trail colors, screen effects |
| lisp/components.lisp  | every DEFCOMPONENT (transform, motion, model, health, fighter, blade-trail, player, brain, dummy, projectile) |
| lisp/bodies.lisp      | data: DEFBODY for every character (parts, palette, stats)    |
| lisp/fighters.lisp    | spawning a fighter entity, geometry helpers, posing, drawing, debris |
| lisp/combat.lisp      | move runner + hit scan, applying hits to enemies, reactions, physics, separation, soft-lock, tokens |
| lisp/camera.lisp      | the third-person orbit camera                               |
| lisp/player.lisp      | REN: input buffer, state machine, specials, defense, `PLAYER-SYSTEM` |
| lisp/enemy.lisp       | enemy spawning, `ENEMY-SYSTEM`, AI brains per kind, boss, enemy drawing |
| lisp/projectiles.lisp | kunai / blast kunai / blade wave entities, `PROJECTILE-SYSTEM` |
| lisp/feedback.lisp    | `FEEDBACK-SYSTEM`: events -> sounds, particles, shake, hitstop, slow-mo, combo / kill counts |
| lisp/training.lisp    | the TRAINING scene's dummies                                |
| lisp/game.lisp        | game flow (title/waves/boss/over/results), spawner, menus, score |
| lisp/hud.lisp         | HUD, combo counter, prompts, title/result screens, F3 overlay |
| lisp/debug.lisp       | `Module._debug_cmd` commands, F3/T keys, autoplay bot, soak mode |
| lisp/main.lisp        | the fixed-step system list, the frame, `RUN-GAME` registration |

`examples/hello/hello.lisp` (one file, package `HELLO`) and `examples/engine-demo/demo.lisp`
(package `ENGINE-DEMO`) use only the engine.

Game design and tuning: see `docs/GAME_DESIGN.md`.

## Gotchas

Each ECL item was checked in ECL-generated C (`compile-file ... :c-file t` with
`c::*delete-files*` nil). To keep the generated C of a build:
`ecl --eval '(require :cmp)' --eval '(setf c::*delete-files* nil)' --load tools/build.lisp -- build/x files…`
and grep the function for `ecl_make_single_float`/`ecl_times`/`ecl_divide`.

### ECL: consing and boxing
* **ECL 24.5 at `(safety 1)` boxes LET initializers.** Even with `(declare (single-float x))`,
  `(let ((x (* a b))) ...)` is computed with generic `ecl_times` on heap floats, then unboxed.
  At `(safety 0)` the same code compiles to plain C float math. Also, at safety 1 an argument
  declared `(simple-array single-float (*))` is checked with the slow runtime `cl_typep`.
  → Hot numeric functions use **`defun-fast`** (package.lisp): it checks the declared argument
  types on entry (cheap tag tests; `f32vec-p` for arrays), then re-binds them and runs the body
  at `(safety 0)`. Wrong argument types still signal a `type-error`.
* **Parallel `let` that shadows names boxes into temporaries.** `(let ((x (f32 x)) (y (f32 y))) ...)`
  evaluates all init forms into boxed temps first. Use **`let*`** for float locals.
* **Declare locals that hold arrays read from struct slots / specials.** Struct accessors are
  not inlined and their result type is unknown, so `(aref (camera-right c) 0)` is a generic
  `ecl_aref` that conses a float. Bind it: `(let ((rt (camera-right c))) (declare (type f32vec rt)) ...)`.
  `free` declarations (`locally (declare (type ...))`) do not change a variable's representation.
* **Every float passed to or returned from a non-inlined function is boxed** (~16 B). Hot paths
  pass/receive f32vecs (the `!` functions) or use `(declaim (inline ...))`.
  Measured after these fixes: `draw-mesh`, `m4-euler!`, `m4-mul!`, `fx-billboard` cons 0 bytes;
  whole engine demo ≈ 70 KB/frame, mostly demo-side float arguments + `format`.
* **Float `min`/`max`/`abs` are generic calls in ECL 24.5**, even with
  declared single-float args. They box, and `min`/`max` add NaN checks. In hot
  loops use `f-min`/`f-max`/`f-abs` (package.lisp: `fminf`/`fmaxf`/`fabsf` through `ffi:c-inline`).
* **`(float x 1.0)` on an already-typed single-float boxes and then unboxes it**,
  and `(float fixnum 1.0)` can push the arithmetic that follows onto generic
  ops. Convert only literals, at macroexpansion time. For fixnum → float use `i->f`
  (c-inline `"(float)(#0)"` with `(:int)`).
* **`(incf (aref v i) x)` boxes** unless `x` is wrapped in `(the single-float …)`.
  Write `(setf (aref v i) (+ (aref v i) x))`. Likewise `(= (1+ j) n)` becomes
  `ecl_make_integer` plus a generic compare. Use `(incf j) (when (>= j n) (setf j 0))`.
* **An inline defun boxes its float arguments** when the parameter is untyped:
  `(declaim (inline f)) (defun f (x) (ffi:c-inline (x) (:float) …))` still conses at every call.
  Write it as a macro (package.lisp: `f-min`, `f-sqrt`, `i->f` …; render.lisp: `srgb->lin`). An inline `defun-fast` called from
  another one re-runs its type checks, and ECL boxes each float just to check it.
* **The math.lisp `!` functions box when they're inlined into another function.** `v3-sub!`,
  `v3-cross!`, `v3-normalize!` and `m4-transform-point!` expand inline, but the `v3-set!` inside
  them is called out of line with 3 boxed floats. Hot loops should spell out the math (see
  `%mb-tri` in meshgen.lisp). A fix belongs in math.lisp (e.g. make `v3-set!` a macro).
* **Fixnums are 30-bit on wasm32.** An LCG like `(* seed 1103515245)` goes to bignums and conses
  on every call. Do it in C with `long long` (the engine's `rnd01` is a C xorshift).

### ECL: compiling and packages
* **ECL doesn't warn about undefined functions.** A typo or an unexported engine function in game
  code compiles silently and fails at run time. `tools/pkgcheck.sh DIR` catches the second kind.
* **defstruct accessors can collide with functions.** A slot named `color` in a struct with
  `(:conc-name mb-)` defines `mb-color`, silently replacing a function of the same name. The same
  holds for components: `(defcomponent gem (angle …))` defines `gem`, `make-gem`, `gem-angle`.
* **`ffi:c-inline` reads one base-36 digit after `#`**: arguments 11+ are `#a`, `#b`, …; `#10` means
  argument 1 followed by a literal `0`.
* **No `@` in `ffi:clines` / `ffi:c-inline` code.** ECL treats `@` specially there (`@(return)`), so
  WGSL (`@group`, `@location`, `@vertex`) in a C string literal gets mangled. WGSL lives in
  `engine/shaders/*.wgsl`; the `WGSL` macro (render.lisp) turns a file into a Lisp string literal at
  compile time, which is passed to C as `:cstring`.
* **Avoid `unwind-protect` / `handler-case` / `catch` in big or hot functions.** Each one is a
  setjmp; many in one function create irreducible control flow and clang's wasm backend
  (register coloring / "Fix Irreducible Control Flow") goes super-linear — one 1.7k-line
  setup function with nested `with-xform`s made an `-O2` build take 2m18s instead of 5s.
  The engine keeps one `handler-case` around each frame (`%FRAME`) and startup step
  (`%INIT-STEP`) in app.lisp; split large setup code into small functions. Profile with
  `emcc -O1 -c -ftime-trace` on the kept C file.
* **`EM_ASM` can't sit in any function inlined into a Lisp function that uses
  `handler-case`/`catch`/`unwind-protect`**. Those compile to setjmp, and clang
  fails with "Cannot use EM_ASM* alongside setjmp/longjmp". Use `EM_JS` (in the C files)
  instead: EM_JS functions are imports and never get inlined.
  Commas at the top level of an `EM_ASM({...})` body also break the macro.

### ECS
* `DO-ENTITIES` scans slots in order; entities spawned during the loop may or may not be visited
  in that pass, and destroying the current entity inside the loop is fine.
* Handles outlive their entities by design: check `(entity-alive-p e)` or the getter's result
  before following a stored handle (a fighter's `target`, a projectile's `owner`, `*boss*`).
* Keep thousands-of-items data (particles, rain) out of the ECS: an entity costs a struct per
  component, a particle costs a few floats in a pool.

### Rendering, platform, SDL_GPU / WebGPU
* **Canvas sizing.** `SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY` + the CSS
  `100vw x 100vh` in `engine/web/shell.html` makes SDL3 size the canvas backing store to
  CSS size × devicePixelRatio and follow window resizes. Always use `window-width/height`
  (= `SDL_GetWindowSizeInPixels`) for layout.
  The WebGPU swapchain follows the canvas size by itself; offscreen targets are rebuilt when
  window size × `*render-scale*` changes.
* **MSAA lives in the offscreen scene target** (4x, the only count WebGPU has besides 1), resolved by
  the scene pass's store op, then bloomed and composited to the swapchain.
* **Coplanar decals z-fight.** `fx-decal` lifts itself 2 cm; pass the actual surface height.
* **Set the camera before `fx-*` calls** in a frame: billboards and rings use its axes.
* **SwiftShader runs both sides of a divergent branch.** A per-pixel `if (d2 >= r*r) continue;`
  saves nothing in headless Chrome; the cost scales with loop iterations × pixels. What helps
  there: fewer iterations (a uniform count), per-vertex work, fewer pixels (`*render-scale*` 0.7
  roughly halves the frame). World demo 1280×720: 8 per-pixel lights ≈ 55 % of the frame; bloom,
  sky and MSAA are each under 5 %. Real GPUs do skip coherent branches, so keep the early-outs.
* **Never call a blocking SDL_GPU function**: `SDL_WaitAndAcquireGPUSwapchainTexture`,
  `SDL_WaitForGPUFences`, `SDL_WaitForGPUIdle`, mapping a DOWNLOAD transfer buffer
  (async map). On the web they spin on `SDL_Delay` and need ASYNCIFY/JSPI, which ECL rules out
  (see above). Use `SDL_AcquireGPUSwapchainTexture` and skip the frame on NULL.
* **The backend derives bind group layouts by scanning each shader's WGSL text** (`@group` …
  `@binding` … `var` … `;`). So: one source per stage that declares only that stage's bindings
  (vertex storage group 0, vertex uniforms group 1, fragment textures/samplers group 2, fragment
  uniforms group 3); comments would be scanned too (the `WGSL` macro strips them); a binding whose declaration contains `sampler` is a
  sampler and one containing `read`/`write` is a (read-only / writable) storage buffer, so keep those
  words out of variable names. Its bind-group cache keys on resource ids only, not stage: never bind
  the same buffer set to both the vertex and the fragment stage.
* **Backend quirks:** it ignores `enable_depth_test` (an untested pipeline needs `compare_op`
  ALWAYS) and `enable_blend` (always give explicit ONE/ZERO factors); a pipeline bind clears
  texture/storage bindings (rebind after every `SDL_BindGPUGraphicsPipeline`); depth clip is off
  unless `enable_depth_clip` is set. Upload transfer buffers are CPU memory copied by
  `queue.writeBuffer` inside `SDL_UploadToGPUBuffer`, so the per-frame transfer buffer is mapped
  with `cycle=false` (cycling would memset all 2.6 MB each frame).

### Headless testing, audio
* **Headless Chrome:** the default `run.mjs` flags give SwiftShader WebGPU (screenshots work, about
  8 fps in a fight; SwiftShader WebGL is equally slow). `CHROME_FLAGS="--enable-unsafe-webgpu
  --enable-features=Vulkan --use-angle=vulkan"` gets the real GPU (60 fps) — but here the default
  `requestAdapter()` returns null (hence the high-performance request in the shell) and page
  screenshots of a hardware WebGPU canvas come out blank, so judge pictures with SwiftShader and
  CPU timings with the hardware flags.
* `run.mjs` passes `--autoplay-policy=no-user-gesture-required`, so audio starts unlocked. To test
  the browser's autoplay lock, change that flag in run.mjs to
  `--autoplay-policy=document-user-activation-required`.
* Never `pkill -f` a pattern that also matches your own shell command line (it kills the shell).
