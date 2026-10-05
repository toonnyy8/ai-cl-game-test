# A. Engine & toolchain lessons (ai-cl-game-test: CL -> ECL -> C -> emcc -> wasm, SDL3 SDL_GPU on WebGPU)

Repo root = /media/8tsp/projects/ai-cl-game-test. Evidence tags: [ARCH] docs/ARCHITECTURE.md, [API] docs/ENGINE_API.md,
[DL §n] docs/DEVLOG.zh-TW.md section n, [TUT n] docs/TUTORIAL.zh-TW.md step n, [README], [MEM] auto-memory notes,
file paths otherwise. G = generalizable lesson, D = SOUL DUEL / RAVEN-specific detail.

---------------------------------------------------------------------------------------------------------------------
## 1. Architecture

### 1.1 Layers
- G: Three layers: `engine/` (package ENGINE, knows no game), one dir per game (`game/` = RAVEN pkg, `duel/` = DUEL pkg),
  `examples/` (hello 123 lines, engine-demo). Game package = `(:use :cl :engine)`. [ARCH "Module map", README]
- G: Engine is three languages in real files: `engine/lisp/*.lisp` (API), `engine/c/*.c` + ONE header `engine/c/engine.h`
  declaring every C fn Lisp calls, `engine/shaders/*.wgsl`. Lisp side only has thin `ffi:c-inline` one-liners.
  C statics carry module prefixes (`pf_` platform, `r_` render, `au_` audio, `w_` game world) because everything ends up
  in one C unit. [ARCH "Build pipeline", DL §13.1]
- G: Engine module order (engine/MANIFEST): package, math, hitvol, input, touch, platform, render, meshgen, ui, audio,
  anim, body, time, fx, cine, ecs, app; C: main, rng, platform, render, audio. Plain-CL host-loadable files: math,
  hitvol, input, touch, (cine with 2 stubs), ecs. [engine/MANIFEST, ARCH "Gotchas: compiling"]
- G: "Harvest rule": things move into the engine only when a SECOND user exists (vpad, hit volumes, fixed-step
  accumulator, rigid-part bodies, cine director, ribbons/sectors/bitmaps came from game #2). One-user helpers stay in
  the game (pair camera, shot helpers). Each harvest step verified by bit-identical CvC hash lines + RAVEN's generated C
  diffed function-by-function (664 fns identical). [DL §14.1 step 9, §14.2 table]
- G: Game #2 was explicitly used as an engine audit: a read-only agent listed 20 gaps before coding; 15 more found
  during dev (E2). Expect the same for game #3 — budget an "engine gap audit" pass up front. [DL §14.1-14.2]
- G: Engine edits while game agents build in place were done in a separate tree copy (`ai-cl-game-test-engwork`):
  build.sh reads engine Lisp at start and engine C minutes later at link -> concurrent edits produce half-old/half-new
  binaries silently. Use worktrees for engine work. [DL §14.1 step 4]

### 1.2 Adding a new game (checklist)
- G: Create `mygame/MANIFEST`: first line `# title: MY GAME` (page title), then one source per line relative to the dir,
  `#` comments allowed, `.lisp` and `.c` lines. Order matters (macros/structs/components/specials before users).
  [build.sh, duel/MANIFEST, examples/hello/MANIFEST]
- G: Build: `./build.sh mygame` -> `dist/mygame/{index.html,index.js,index.wasm}`. Output name = basename of dir.
  Bare `./build.sh` builds only `game/` (RAVEN) — not your game. [build.sh, MEM raven-edge-project]
- G: Optional `mygame/web/`: `head.html` is spliced into `engine/web/shell.html` at `<!--@HEAD@-->`; every other file
  is copied next to index.html (icons, manifest.webmanifest, sw.js, pwa.js, manual.html). If `sw.js` exists, build.sh
  replaces `@VERSION@` with sha1 of index.{html,js,wasm} + web/* (so a page-only edit also busts cache). [build.sh, DL §43]
- G: Register exactly once at load time:
  `(run-game :title T :load (list #'step1 #'step2) :start #'start :frame #'frame :debug #'debug-cmd :stats #'tail)`.
  [engine/lisp/app.lisp header, API "App"]
- G: Test target without a MANIFEST: `./build.sh NAME a.lisp b.c` = engine + those files -> dist/NAME (use a unique NAME
  per agent so parallel builds don't collide; e.g. duel-view / duel-vfx browsers, tests/engine-check.lisp). [build.sh,
  ARCH, DL §9, tests/engine-check.sh]
- G: Run `tools/pkgcheck.sh mygame` after every edit batch (see §3.3). [tools/pkgcheck.sh]
- G: Start by copying examples/hello/hello.lisp (one file: defsound, build-meshes load step, defcomponents, a pure rule,
  systems via do-entities, emit/take-events feedback, draw, HUD, run-game). [examples/hello/hello.lisp, TUT 2]
- D: SOUL DUEL's file layout pattern: package, tuning, rules (pure), control (pure vpad data), learn (pure), sounds,
  components, body, kit, glyphs, ... per-character `<name>-art.lisp` + `<name>.lisp`, then generic systems
  (fighter, combat, hazards, ai, camera, feedback, flow, hud, debug, main). [duel/MANIFEST]

### 1.3 Web shell / PWA
- G: `engine/web/shell.html` requests the WebGPU adapter (`powerPreference:'high-performance'`, fallback default) and
  device in `Module.preRun` behind addRunDependency, sets `Module.preinitializedWebGPUAdapter/Device` -> patched SDL
  imports them. Shows "WEBGPU UNAVAILABLE" / "GRAPHICS DEVICE LOST" / "THE GAME STOPPED" veils; loading bar via
  `Module.engineLoading(pct)`; fatal text via `Module.engineFatal`. [engine/web/shell.html:55-105, ARCH]
- G: Page <-> game "page services" protocol: integer get/set only. C `pf_page_get(k)` / `pf_page_set(k,v)` are EM_JS
  calls into `globalThis.gamePage.get/set` (0 when no page object, so headless/native work unchanged). The game's
  `web/pwa.js` maps integer key ranges to localStorage, safe-area insets, wake lock, back-gesture count, "open manual".
  Every localStorage access wrapped in try/catch (private mode). Allocate key ranges up front — DUEL collided (bindings
  at 200-399 overlapped learn tables 100-10099; moved to 20000+). [engine/c/platform.c:147, duel/web/pwa.js, DL §67]
- G: Service worker: ONE versioned cache, cache-first for everything (index.html/js/wasm always same build), skipWaiting
  + clients.claim, delete old caches, pwa.js reloads once on controllerchange. Network-first index.html was rejected:
  it can pair new html with old wasm. [duel/web/sw.js, DL §15]
- G: Mobile web gotchas: `pointerdown` is NOT user activation (spec counts pointerup/touchend) -> fullscreen, history
  trap, audio resume must hang on pointerup/touchend; Safari needs AudioContext.resume() inside the gesture handler.
  [DL §15, DL §7]
- G: SW/PWA/fullscreen/history trap only on touch-first devices `(pointer: coarse)`; desktop gets none. [duel/web/pwa.js]
- G: Self-contained manual page (inline CSS/JS, no external fonts) so it works offline in the installed app; add it to
  the SW file list. [DL §43]
- G: Deploy = `tools/deploy-pages.sh` pushes dist/<game> to an orphan gh-pages branch via a worktree in build/gh-pages
  (+ .nojekyll). Only run when the user says they're done. [tools/deploy-pages.sh, MEM feedback-pages-deploy]

### 1.4 Per-frame loop and startup
- G: C owns the loop (`engine/c/main.c`): `cl_boot` -> `GC_disable()` -> `ecl_init_module(init_game)` -> collect ->
  `emscripten_set_main_loop(frame,0,0)`. While starting: one `ENGINE::%INIT-STEP` per browser frame (returns 1 more /
  0 done / 2 failed) with a FULL GC after each step. Then `ENGINE::%FRAME` each frame; collect when
  `GC_get_bytes_since_gc() > 24 MB`. [engine/c/main.c]
- G: Startup step order: engine-init (window, GPU, UI) -> each :load fn -> open audio -> one step per DEFSOUND -> :start.
  Heavy one-off allocation (meshgen, synthesis, hull building) MUST be split into separate :load steps so GC runs between
  them; RAVEN peak heap 199 -> 128 MB wasm memory by going stepwise. Give each character body its own :load step
  (hulls allocate a few MB scratch). [app.lisp run-init-step, ARCH "Runtime model", API "Bodies"]
- G: Frame = `platform-poll` -> `begin-frame` -> drain queued `Module._debug_cmd(n)` -> game :frame(rdt, clamped <=0.1)
  -> `end-frame` (render+present). Whole frame wrapped in ONE handler-case -> `show-fatal` puts the condition text on
  the page and the loop stops. [app.lisp run-frame/%frame]
- G: Fixed step for gameplay: `(run-fixed-steps rdt #'sim-step :while #'sim-running-p)`, +step+ = 1/60, max 6 steps per
  frame, backlog dropped; set `*step-acc*` 0 while paused. Hitstop = global sim freeze (`time-step` returns NIL),
  particles/shake/UI keep running; concurrent hitstops take the max. [API "Time", DL §8]
- G: `perf-mark` twice in :frame splits stats into sim/queue/render; `(setf *stats-log* t)` logs every 2 s:
  `stats: fps .. cons/frame .. B draws .. tris .. particles .. | ms/frame sim .. queue .. render .. | fx-dropped N`.
  Console prints `startup: heap X MB, wasm memory Y MB` once. [app.lisp, main.c m_heap_log]

### 1.5 Zero asset files: everything procedural at startup
- G: Meshes: `meshgen.lisp` builder DSL `(build-mesh (mb :jitter 0.1 :color ..) (mb-box ..) (with-xform (mb (xform ..))
  ..))`; flat normals, per-face brightness jitter = low-poly look; vertex = pos+normal+color (9 floats); meshes packed
  into shared 4 MB vertex buffers. [API "Mesh generation", DL §6.1, ARCH render]
- G: Characters = rigid part per rig joint (no skinning): body spec `((joint shape ...) ...)` -> `build-parts` -> one
  mesh per joint + glows/tagged parts + optional ink hulls; `draw-parts` 0 bytes/call. Dismemberment is trivial (detach
  parts as debris). Cost: many draws (~103 for 4 RAVEN chars; DUEL 45). [API "Bodies", DL §6.1, §14.4]
- G: Animation: 21-joint rig, DEFPOSE / DEFCLIP (`:fps 60` makes times frame numbers, `:marks`), DEFSTRIKE (S/A/R),
  `clip-sample!`, `pose-fk!`; per-character rig proportions via `make-rig-proportions`. Contract between gameplay and art
  agents = clip NAMES; a missing clip falls back to idle + logs `missing clip`, so gameplay never waits for art.
  `tools/pose-solve.py` inverse-solves wrist angles with the same FK to hit spec'd blade directions. [API "Animation",
  DL §8, §14.1 step 4]
- G: Audio: `(defsound :key (:peak .9 :loop t) body)` returns a 48 kHz mono f32vec; synthesized one sound per startup
  step (RAVEN: 26 sounds, 770-810 ms, 9.1 MB samples in C memory). Toolkit `au-*` (osc, noise, env, svf, delay, reverb,
  taiko/gong/shaku instruments). Loops rendered 2.5 s long then folded so tails wrap seamlessly. Max 128 DEFSOUNDs
  (129th errors at load). [API "Audio", DL §7, docs/AUDIO.md]
- G: Mixer is pure C on `SDL_OpenAudioDeviceStream` callback (F32 stereo 48 kHz, 32 voices, peak limiter), never touches
  Lisp objects -> compatible with the GC rule, no starvation during GC/stutter. [DL §7]
- G: Text: embedded bitmap font in ui.lisp (ASCII). Non-ASCII (DUEL's kanji brush titles) = build-time bake:
  `tools/glyph-bake.py FONT.ttf` (fontTools + skia-pathops) -> committed `duel/lisp/glyphs.lisp` integer polygons,
  ear-clipped at load. Game loads no font file; font license file committed. [tools/glyph-bake.py, duel/FONT-LICENSE]
- G: Shaders are compiled into the binary: the `WGSL` macro (render.lisp) reads `engine/shaders/*.wgsl` at COMPILE
  time, resolves `// #include "x.wgsl"`, strips comments -> string literal. Editing a shader needs a rebuild.
  PWA icons from `tools/pwa-icons.py`. [ARCH render, tools/]

---------------------------------------------------------------------------------------------------------------------
## 2. Build / run / debug loop

### 2.1 Commands
- G: `./build.sh DIR` (wasm). Env: `GAME_OPT` (default -O2, C opt of Lisp code), `EMCC_EXTRA`, `EMSDK_DIR`
  (do NOT trust `$EMSDK`, it points at a wrong path on this box), `ECL_HOST`. [build.sh, MEM raven-edge-project]
- G: Serve: `python3 -m http.server -d dist/NAME 8000`; `file://` cannot load wasm. Audio needs a first click/key. [README]
- G: Headless: `node tools/run.mjs dist/NAME --secs 12 --shot out.png [--script steps.json] [--size WxH]
  [--fixed-dt 16.666667] [--timeout 3000] [--mobile --dpr 3]`. No npm deps (Node >= 22 WebSocket + CDP). Script steps:
  `{"at":t,"key":"KeyJ","down":true}`, `{"at":t,"shot":"x.png"}`, `{"at":t,"eval":"Module._debug_cmd(2102)"}`,
  `{"at":t,"size":"800x450"}`, touch `{"at":t,"touch":"start","x":..,"y":..,"id":0}`. Exit 1 on JS exception, on
  `WebGPU:` validation errors or failed pipeline (doubles as a WGSL smoke test). [tools/run.mjs header, ARCH]
- G: `--fixed-dt`: virtual clock (performance.now/Date.now advance exactly dt per rAF; next frame waits for the GPU);
  `at`/`--secs` become virtual seconds -> byte-identical screenshots from same binary+script. Add `--timeout` under load.
  [run.mjs, ARCH "Deterministic stills", MEM]
- G: Host-only pure-CL tests (no build, ~1 s): `$E --norc --load tests/ecs-test.lisp` etc. with
  `E=/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl`. Pure files: ecs, math, hitvol, input (vpad), touch,
  cine, rules, control, learn. [README "測試", TUT 0]
- G: Debug hook: `Module._debug_cmd(n)` (EMSCRIPTEN_KEEPALIVE in main.c, 16-slot queue, drained at next frame start ->
  game's :debug fn). Games use integer RANGES as a namespace: scenario setups, runtime tuning knobs "without a rebuild"
  (e.g. 32000+k sets `*arm-self*` = k), still frames of cinematics, seeded gates (2000+s CvC). Keep a registry table
  in the gameplay doc and let each module register its own range (`*char-debug*`) — hard-coded ranges collided
  (80000+ vs ENDLESS). [main.c debug_cmd, docs/DUEL_GAMEPLAY.md debug table, DL §30]
- G: Dev log channels: `*combat-log*`/CLOG prints state changes/hits/damage to console; tests assert on those lines;
  F3 overlay (dev mode only after a `_debug_cmd`) shows FPS, cons/frame, hitboxes. [DL §9, README controls]
- G: Engine self-test: `tests/engine-check.sh` builds `echeck` from tests/engine-check.lisp, runs it headless, greps
  `engine-check: N pass, 0 fail`. [tests/engine-check.sh]

### 2.2 Timings (this machine, 24 cores)
- G: wasm builds: hello ~7 s, RAVEN ~12 s, SOUL DUEL (28k-line unit) ~43 s from concat to wasm (file mtimes
  build/*/game-all.{lisp,o}, dist/*/index.wasm). One compilation unit -> any one-line change recompiles everything.
  Size: hello 4.8 MB wasm (mostly libecl), RAVEN 5.5 MB, DUEL 7.7 MB. [stat of build/, DL §13.3]
- G: Native sim build `build/simgate/duel.fas` ~2 min (gcc -m32). [DL §38, tools/simgate.py]
- G: Headless Chrome on SwiftShader: ~8 fps in a fight, each Chrome eats ~6 cores -> only 3-4 parallel runs on 24 cores.
  A 20-seed browser gate per pairing took 10+ min; native sim does 300 matches in ~14 s at -j16. [DL §38, ARCH headless]
- G: Mobile probe at DPR 3 headless ~30 min; keep to 2 Chromes. [MEM raven-edge-project]

### 2.3 Native host build of the real game (for gates)
- G: Do NOT write a second simulation. `tools/simgate/build.lisp` concatenates the SAME engine+game MANIFEST Lisp,
  compiles with the 32-bit host ECL + gcc `-m32 -msse2 -mfpmath=sse -ffp-contract=off` (f32 rounding like wasm; x87
  80-bit would differ), and swaps the C layer for `tools/simgate/stubs.c` (real rng.c; window/GPU/audio/page are
  no-op leaves; virtual 1/60 s per pf_pump). No `#+` conditionals in game code. Runs the real `%INIT-STEP`/`%FRAME`.
  [DL §38, tools/simgate/*.lisp, stubs.c]
- G: libm divergence: wasm uses emscripten's musl, host uses glibc -> `sinf`/`expf` differ in last bit -> CvC drifted
  at t~7200 in 3/15 pairings. Fix: compile the same musl math sources from emsdk into `build/simgate/muslm.so` and
  `LD_PRELOAD` it. Then 150/150 matches, 2693/2693 lines identical. [DL §38, tools/simgate.py MUSL_MATH]
- G: Native runs per-process sequentially exposed a cross-match state leak (per-side state "reset each match" in a
  comment, never reset) -> splitting seeds across processes changed results. Native runner = cheap leak detector:
  run seeds both chained and one-per-process and diff. [DL §38-§39]
- G: simgate rebuilds ONLY the native .fas. The user plays dist/ wasm -> always finish with `./build.sh duel` and check
  dist/*/index.wasm is newer than every edited .lisp before handing off (an unexported-symbol bug reached the user's
  phone this way). [MEM feedback-rebuild-dist]
- G: Browser still owns: bit-exact reference CvC (G2), WGSL smoke, frozen stills, touch scripts. [DL §38]

### 2.4 Inspecting generated C
- G: Keep ECL's C: `ecl --eval '(require :cmp)' --eval '(setf c::*delete-files* nil)' --load tools/build.lisp --
  build/x files...` then grep the function for `ecl_make_single_float` / `ecl_times` / `ecl_divide` (boxing). Profile
  slow compiles with `emcc -O1 -c -ftime-trace` on the kept C. [ARCH "Gotchas"]
- G: Lisp compile errors: terminal shows excerpt; full log `build/NAME/lisp.log`; line numbers refer to
  `build/NAME/game-all.lisp`, which has `;;;; ---- path` banners per file. [README, build.sh]

---------------------------------------------------------------------------------------------------------------------
## 3. Gotchas and fixes

### 3.1 GC on wasm (the #1 structural constraint)
- G: Boehm is conservative and cannot see wasm locals (needs ASYNCIFY for `emscripten_scan_registers`); the data
  segment is not scanned on emscripten (DATASTART==DATAEND). Rejected: ASYNCIFY (bigger/slower, fights ECL setjmp),
  binaryen `--spill-pointers`. Chosen: GC disabled while Lisp runs; collect only between frames when the wasm stack
  holds no Lisp objects. Validated with a stress spike (20k garbage lists/frame, 1680 frames, 0 CORRUPTION). [DL §3]
- G: Rules: never `(ext:gc)` / `GC_gcollect` from Lisp; any C static holding a Lisp object needs `ecl_register_root`
  (better: keep Lisp objects in Lisp defvars; C gets arrays for one call only); module constants are safe
  (ECL_DYNAMIC_VV). [ARCH "The GC rule", DL §3.1]
- G: Consequences: per-frame garbage piles until frame end; heap grows (`-sALLOW_MEMORY_GROWTH=1`, INITIAL 128 MB);
  a full collection on ~32 MB costs a few ms (a hitch every 600-1400 frames at 17-41 KB/frame). Model breaks if you
  ever use pthreads or await async events inside Lisp. [DL §3.5, §10]
- G: Load-time garbage happens inside `ecl_init_module` where GC must stay off. Biggest source was ECL's per-definition
  `EXT:ANNOTATE` + `SET-DOCUMENTATION` (~35 KB each). Fix in tools/build.lisp: `(setf ext:*register-with-pde-hook* nil
  si::*keep-documentation* nil)` -> hello load garbage 42.6 -> 15.5 MB, DUEL heap 119 -> 57 MB. [tools/build.lisp, ARCH]
- G: Boehm grows heap in 16 MB steps: a tiny increase in load-time data can jump startup heap a whole step (71 -> 87 MB
  for 1.8 MB of constants). Same binary may report 57 or 71 MB. Don't chase single-step heap jumps. [ARCH, DL §13.2, §15]

### 3.2 ECL float boxing / consing (the #1 performance enemy)
- G: single-floats are boxed (~16 B) in lists, untyped struct slots, defvars, generic arrays, and EVERY float passed
  to / returned from a non-inlined function. Unboxed only in `(simple-array single-float (*))` and declared locals.
  Hot data lives in f32vecs; `!` functions write into their first arg and never allocate. [ARCH "Performance", API]
- G: `(safety 1)` boxes LET initializers even when declared and uses slow `cl_typep` for array arg checks ->
  `defun-fast` macro: cheap type checks on entry, body at `(safety 0)`. Global default `(speed 3) (safety 1) (debug 0)`
  in package.lisp. [ARCH "Gotchas: consing"]
- G: Parallel `let` shadowing names boxes into temps -> use `let*` for float locals. [ARCH]
- G: Declare locals holding arrays read from struct slots/specials (`(declare (type f32vec rt))`), else `aref` is
  generic and conses. `locally (declare ...)` doesn't change representation. [ARCH]
- G: Float `min`/`max`/`abs` are generic in ECL 24.5 -> use `f-min`/`f-max`/`f-abs` (c-inline fminf...). Also f-sqrt,
  f-sin, f-cos, f-atan2, f-mod, f-clamp, f-wrap, `i->f`, `f->i` are MACROS (an inline defun with untyped params still
  boxes). [ARCH, API "Package helpers"]
- G: `(incf (aref v i) x)` boxes unless `(the single-float x)`; write `(setf (aref v i) (+ (aref v i) x))`.
  `(= (1+ j) n)` conses; use `(incf j) (when (>= j n) ...)`. [ARCH]
- G: `(float x 1.0)` on a typed single-float boxes; `(float x 1d0)` boxes even at safety 0 (au-stats consed 7.7 MB
  for 960k samples) -> c-inline `(double)(#0)`. [ARCH]
- G: Zero-cons float-arg API = DEFUN (for #', apply) + `define-compiler-macro` that expands direct calls inline;
  MUST be wrapped in `(eval-when (:compile-toplevel :load-toplevel :execute) ...)` or ECL won't apply it later in the
  same file. fx-emit went 210 B -> 0 B per call. Only calls through a variable holding the function still box. [ARCH]
- G: Inlined math `!` helpers can still call `v3-set!` out of line with 3 boxed floats -> spell out math in hot loops.
  An unused float binding in a defun-fast is kept boxed (8 B/call) -> use `symbol-macrolet` for rarely used fields,
  with uniquely-prefixed hidden names (a `%s` got captured). [ARCH]
- G: Fixnums are 30-bit on wasm32 (`CL_FIXNUM_MAX` 536870911): an LCG `(* seed 1103515245)` goes bignum every call.
  RNG lives in C (`engine/c/rng.c` xorshift). `rnd-state` returns a bignum above 2^29 — not for per-frame use. [ARCH, DL §4]
- G: Components are mutated in place, not copied (functional core returns small values; imperative shell writes back)
  because copying would multiply boxed floats and GC pauses. Measured cost of the ECS/rules refactor: +10 % consing. [ARCH, DL §13.2]
- G: Per-call consing measured and fixed: `ui-text` per char -> 64 B per 26-char line; block text 250 B per font pixel
  -> ~104 B per line; RAVEN title text consed 60 KB/frame before. Measure with `cons-bytes` around a call. [DL §14.2]

### 3.3 ECL compiling, packages, and the one-unit build
- G: Host ECL must be 32-bit (`ABI=32`): wasm32 pointers/fixnums are 32-bit and the host bakes fixnum limits into C.
  [DL §2.1, README toolchain]
- G: `-DECL_C_COMPATIBLE_VARIADIC_DISPATCH` MUST be on every C compile (tools/build.lisp `c::*cc-flags*` and build.sh
  emcc) — the wasm libecl was configured with it; mismatch changes `struct ecl_cfun` layout and traps in
  `call_indirect` with no useful message. Same flag in compile_flags.txt for clangd. [DL §2.3, compile_flags.txt]
- G: Prebuilt `libecl.so` from the cross build is an emscripten SIDE_MODULE (dylink.0) — unusable statically.
  `tools/vendor-ecl.sh` assembles `libecl.a` from libeclmin.a + liblsp.a (members prefixed `lsp_`) + all_symbols2.o;
  copies libeclgc.a / libeclgmp.a / headers. vendor/ is committed; rarely rebuilt. libecl is -O0 (known perf debt). [DL §2.2, §10]
- G: Why one compilation unit: files use `ffi:clines`/`c-inline` that the host can't load, and compiled objects are
  wasm (host can't load either), so the classic compile-then-load-each-file flow is impossible. Concatenate all .lisp
  -> `compile-file :system-p t` with CC=emcc -> `c:build-static-library ... :init-name "init_game"`. [DL §2.4, tools/build.lisp]
- G: ECL does NOT warn on undefined functions. Three silent failure modes, all caught by `tools/pkgcheck.sh DIR` (reads,
  doesn't compile; exit 1): game uses an unexported engine name (becomes a new game-package symbol -> "function X is
  undefined" at runtime, reached the user's phone), a game DEFUN/DEFVAR of an ENGINE-exported name (silently REPLACES
  the engine's definition for that build), and calls to functions defined nowhere. [ARCH, DL §13.1, §14.2, MEM]
- G: defstruct accessors collide silently with functions: `(:conc-name mb-)` + slot `color` defines `mb-color`;
  `(defcomponent gem (angle ..))` defines `gem`, `make-gem`, `gem-angle`. [ARCH]
- G: `do-entities` with a misspelled component used to register a new component silently; now a compile error. C
  implicit function declarations are errors (`-Werror=implicit-function-declaration`). [DL §13.4, tools/build.lisp]
- G: ECL calls compiled functions DIRECTLY: redefining/wrapping a function (`fdefinition`) after loading a .fas does
  not affect calls from other compiled code. Instrument by loading a script after the .fas that prints from the frame
  loop, or rebuild. [docs/BABYLON_PORT.md parity section]
- G: `pi` is a long-float (double) in ECL: `(+ yaw pi)` into a single-float-declared fn crashed (rare branch, found
  only when a new pairing hit it). Use a single-float constant (`+pi+`). Same class: double literals/data, double ops
  between f32s, comparisons against literals read as single — all caused native/TS parity drifts. [DL §30, BABYLON_PORT]
- G: `ffi:c-inline` args: `#` reads ONE base-36 digit -> args 11+ are `#a`, `#b`; `#10` = arg 1 then literal 0.
  No `@` inside clines/c-inline strings (ECL syntax `@(return)`) -> WGSL can't live in C strings. [ARCH, DL §11.2]
- G: Every `handler-case` / `unwind-protect` / `catch` is a setjmp; many in one function -> irreducible control flow,
  clang wasm backend goes super-linear: a 1.7k-line setup fn with nested `with-xform` made -O2 take 2m18s vs 5s.
  Keep one handler-case per frame/init step; split big setup functions. [DL §5, ARCH]
- G: `EM_ASM` cannot be inlined into any function using setjmp ("Cannot use EM_ASM* alongside setjmp/longjmp") and
  top-level commas break it -> use `EM_JS` (an import, never inlined) in the C files. [DL §5, main.c comment]
- G: host-test files must stay plain CL: don't let pure rules call c-inline macros (F-SIN ...); defining is OK, calling
  on host isn't. A pure `dir-yaw` uses CL `atan` (double) while engine `yaw-to` uses `atan2f`: they differ in the last
  bit and produce a different match — pick one per quantity and never swap it once refs are recorded. [ARCH, TUT 9.5]
- G: DEFCINE's AT/DURING/CF are interned in the script's own package to avoid clashing with a game macro named `at`. [ARCH]

### 3.4 SDL3 SDL_GPU on WebGPU (draft backend)
- G: Upstream SDL (3.2 in emsdk 4.0.12, 3.4) has no web SDL_GPU backend (`SDL_GetNumGPUDrivers()` = 0). Uses draft
  PR #16020 pinned + `vendor/sdl3-webgpu.patch` (hunks tagged `raven-edge patch:`), rebuilt by
  `tools/vendor-sdl3-webgpu.sh` without OpenGL/GLES/SDL_Renderer. SDL forbids AI-written upstream contributions:
  patches stay local. Verify "not possible" claims by measuring first. [DL §1, §11, README]
- G: Requires Dawn emdawnwebgpu v20260917 (`--use-port=vendor/emdawn/.../emdawnwebgpu.port.py`): emsdk 4.0.12's port
  has mismatched enums (RGBA8Unorm 0x16 vs 0x12) -> nonsense "surface doesn't support SDR". [DL §11.2]
- G: No ASYNCIFY/JSPI possible (ECL setjmp goes through JS invoke_* wrappers JSPI can't suspend across) ->
  pre-create adapter/device in JS preRun; NEVER call blocking SDL_GPU fns (`WaitAndAcquireGPUSwapchainTexture`,
  `WaitForGPUFences`, `WaitForGPUIdle`, mapping DOWNLOAD buffers). Use `SDL_AcquireGPUSwapchainTexture`; NULL = skip
  drawing this frame (sim still runs). Patch makes the non-blocking acquire also poll fences (else every frame after
  the first returned NULL). [ARCH, DL §11.2]
- G: Backend derives bind group layouts by SCANNING WGSL text: one source per stage declaring only its bindings
  (vertex storage g0, vertex uniforms g1, fragment tex/samplers g2, fragment uniforms g3); words `sampler`, `read`,
  `write` in a binding line change its type -> keep them out of variable names; comments are scanned too (macro strips
  them); bind-group cache keys on resource ids only -> never bind same buffer set to vertex and fragment. [ARCH]
- G: Backend quirks: ignores `enable_depth_test` (use compare_op ALWAYS for untested), ignores `enable_blend` (always
  give explicit ONE/ZERO factors), pipeline bind clears texture/storage bindings (rebind after each bind), depth clip
  off unless `enable_depth_clip`. Map per-frame transfer buffer with cycle=false (cycling memsets 2.6 MB/frame). [ARCH]
- G: Per-draw data via ONE storage buffer of 128 B records indexed by `instance_index`, not per-draw push uniforms:
  258 draws 0.03 ms record + 0.07 submit vs 0.10 + 0.23 ms. Patch "set bind groups only when changed": 0.55 -> 0.03 ms.
  [ARCH render, DL §11.3-11.4]
- G: WebGPU clip depth [0,1] (`m4-perspective!` emits it); RT uv.y = 0.5 - ndc.y/2; MSAA only 4 or 1; MSAA lives in the
  offscreen scene target, resolved by the pass store op; IndirectFirstInstance made optional (SwiftShader lacks it). [ARCH]
- G: Canvas: `SDL_WINDOW_RESIZABLE | HIGH_PIXEL_DENSITY` + CSS 100vw/100vh -> backing store = CSS x DPR; always lay
  out with `window-width/height` (pixels); swapchain follows; offscreen targets rebuilt on size x `*render-scale*` change. [ARCH]
- G: Set the camera before any `fx-*` call in a frame (billboards use its axes); coplanar decals z-fight (`fx-decal`
  lifts 2 cm; pass true surface height); additive sprites have a white hot core (negative alpha = no core). [ARCH, API]
- G: New look without disturbing an old game: add separate pipelines/entry points selected by per-draw lanes defaulting
  to 0 (DUEL's toon path); old shaders stay byte-identical and old game's frames stay bit-identical (gate G1). [ARCH toon]

### 3.5 Headless / SwiftShader testing
- G: Headless Chrome default WebGPU on SwiftShader = instant device lost (no shared image format with GL compositor).
  Working flags (run.mjs default): `--enable-unsafe-webgpu --enable-features=Vulkan --use-vulkan=swiftshader
  --use-webgpu-adapter=swiftshader --use-angle=vulkan --enable-unsafe-swiftshader`. [DL §11.2, run.mjs]
- G: Real GPU headless (`CHROME_FLAGS=... --use-angle=vulkan`): 60 fps but default requestAdapter returns null (hence
  the high-performance request) and canvas screenshots are blank -> judge pictures on SwiftShader, CPU timing on HW. [ARCH]
- G: SwiftShader runs both sides of divergent branches -> per-pixel early-outs save nothing there; what helps: fewer
  loop iterations, per-vertex work, fewer pixels. 8 per-pixel lights = 55 % of frame. SwiftShader numbers are only
  for before/after comparison, never absolute. [DL §6.3, ARCH]
- G: Determinism pitfalls in stills: SDL skips frames whose swapchain isn't ready (canvas shows older state); headless
  windows lose focus and games pause on focus loss (focus emulation on); fixed debugging port can be stolen by a
  leftover Chrome (use port 0 / DevToolsActivePort). [ARCH "Deterministic stills", run.mjs]
- G: Autoplay: run.mjs passes `--autoplay-policy=no-user-gesture-required`; to test the lock use
  `document-user-activation-required`. [ARCH]
- G: Gamepads can't be plugged in headless -> every mode must be drivable by keys; run.mjs injects numpad codes. [ARCH]
- G: Never `pkill -f`/`pgrep -f` a pattern matching your own command line; wait loops need iteration caps or wait by
  PID (orphaned self-matching loops ran 7-16 h). run.mjs handles SIGINT/SIGTERM to never orphan Chrome. [ARCH, MEM]

### 3.6 Input / mobile
- G: Pads: up to 4, each keeps its slot until unplugged (P2 = pad 1 stays true); readers take optional slot; pad 0 axes
  mirrored into `*input*` so zero-arg readers are inline array reads. `*pointer-lock*` NIL for menu/fighter games. [ARCH]
- G: Touch = just another vpad source: C queues finger events with SDL timestamps (`pf_pump`), `engine/lisp/touch.lisp`
  recognizer (plain CL, host-tested, zero cons, timing from event timestamps -> frame-rate independent and
  deterministic under --fixed-dt) emits tap/rest/flick/drag; game writes them into P1's vpad. Rules/AI hashes unchanged. [DL §15, touch.lisp]
- G: Gesture tuning lessons from real phones: flicks travel 60-140 px so drag-stick must not engage until the flick
  window (120 ms) passes ("undecided" state); upward flicks drift diagonally (60 deg cone). Clear pending pulses when
  not in battle (menu taps leaked into first frame). Text floor 11 CSS px. Every portrait-only path gated by
  `(portrait-p)` so desktop stays byte-identical. [DL §15.1, MEM]

---------------------------------------------------------------------------------------------------------------------
## 4. Budgets, allocation discipline, determinism rules

- G: Per-frame consing budget: "a few hundred KB/frame is fine"; actual: engine demo ~70 KB, RAVEN idle 17 KB, fight
  20-41 KB; DUEL CvC 12.6-17.5 KB (cap set at 60 KB). Hot engine calls (`draw-mesh`, `m4-*!`, `fx-billboard`,
  `fx-emit`, `draw-parts`, `ui-rect`) = 0 B. Check with `*stats-log*` cons/frame. [ARCH, DL §4, §14.4]
- G: Startup heap budget: DUEL estimated 80-100 MB, cap 110 MB; now 57 MB both games; hello 23 MB. Draws cap 600
  (DUEL 45). Particles: pool 2000, cap 1200, observed max 547; `fx-dropped` counter in stats (always 0). FX batches
  16384 verts each. [DL §14.4, ARCH]
- G: Write budgets as a table "estimate vs measured" in the design doc before building; a tech-lead reviewer estimated
  them up front. [DL §14.1 step 3, §14.4]
- G: Regression gate for engine changes: RAVEN cons/frame within +10 %, frozen stills byte/pixel identical (noise floor
  measured by running the BASE binary twice), generated C diff function by function. `tests/style-gates.py
  raven|rc|cvc|perf|smoke|duelstill`. [tests/style-gates.py, DL §14.1]
- G: Dynamic quality `*auto-render-scale*` (render-scale 1.0 -> 0.7, then pixel-lights 3 -> 1, hysteresis/backoff),
  OFF by default so headless stills stay deterministic; games enable it in :start. [API "Frame time", DL §6.3]
- G: Not entities: thousands-of-items data (particles, rain, debris, trail verts) live in flat f32 pools / C; RAVEN's
  rain and reflections are written by C straight into the fx batch. ECS = 256 slots, fixnum handle slot+256*gen, max
  64 component kinds; handles outlive entities by design — check `entity-alive-p`. [ARCH ECS, DL §6.2, §13.2]
- G: Two RNG streams: `rnd01` cosmetic (per frame/particle), `sim-rnd01` gameplay/AI ONLY inside fixed steps;
  `(sim-rnd-seed n)` at match start. Never use sim stream for fx or cosmetic stream for gameplay. [ARCH, API]
- G: Determinism checklist (seed = same match at any frame rate): devices read into vpads once per fixed step (CPU and
  scripts write the same vpad); player stick mapped via sim-owned view yaw, not the smoothed camera; slow-mo as
  "skip steps" accumulator (integer frame counts) reset at match start; hitstop decided in rules (sim time), not in
  feedback; cinematics run inside the fixed step (DEFCINE step/draw modes); skip ends on the next step; flush vpad
  presses after cutscenes; reset ALL per-match state (fx-clear, time-reset, clear-entities, per-side game state). [TUT 9.5, DL §14.3, ARCH]
- G: Determinism proof = `duel hash` line every 600 steps + RESULTS line from fixed-seed CvC scripts; refs in
  `tests/style-cvc-ref.txt`; any refactor/harvest must keep them byte-identical. Update refs + docs together when sim
  tuning intentionally changes. [TUT 9.5, MEM]
- G: Every behavior change measured over many seeds; RNG-stream reshuffles dominate A/B noise -> use >=180 seeds (3
  streams of 60) and a p=0.01 control before blaming a feature. [MEM, DL §27]

---------------------------------------------------------------------------------------------------------------------
## 5. Day-one advice for game #3

1. G: Copy examples/hello into `mygame/`, add `# title:` MANIFEST, `./build.sh mygame`, `node tools/run.mjs dist/mygame
   --secs 8 --shot s.png`, `tools/pkgcheck.sh mygame` — all green before writing gameplay.
2. G: Split from the start: pure-CL `rules.lisp` / `control.lisp` (host-tested in 1 s) vs imperative systems; events
   -> one feedback system; data files (moves, bodies, clips, sounds) + one `tuning.lisp` for every knob.
3. G: Use fixed 60 Hz steps, vpads and `sim-rnd01` from day one if you will ever want replays, CPU-vs-CPU gates or a
   native sim gate; add a hash line printer + a seeded CvC script early and record a ref.
4. G: Write hot code with `defun-fast`, `let*`, f32vecs, `!` fns, `f-min/f-max`; turn on `*stats-log*` and keep
   cons/frame in the tens of KB; never call GC from Lisp; split startup into many :load steps.
5. G: Keep `handler-case` out of game code (the engine wraps each frame); keep functions small (setjmp compile blowup).
6. G: Run pkgcheck after every batch; ECL won't tell you about undefined/unexported/redefined functions.
7. G: Claim a debug-command integer range and a page-service key range for the game; document them in a table.
8. G: Need something from the engine? Write it in the game first; harvest into engine only when a second game uses it;
   do engine work in a separate worktree; prove RAVEN/DUEL unchanged (G1 stills + C diff, G2 hashes, cons +10 %).
9. G: Judge visuals on SwiftShader with `--fixed-dt`; never trust SwiftShader timings as absolute; real feel needs
   a human playtest (agents can't feel hit-stop/camera).
10. G: Before any hand-off: `./build.sh <game>` last (not just native/simgate), check wasm mtime > sources, smoke-run.
11. D: SOUL DUEL-only patterns worth copying if relevant: character-as-data kit + `:hooks` (one-character-one-file-set,
    shared files get only hook points; unify hooks when the 2nd user arrives) [DL §26, §30, DUEL_DESIGN "Character code
    layout"]; brush glyph bake for non-ASCII titles; one-hand portrait mode via touch -> vpad; PWA web/ dir; native
    simgate.py for balance gates (15 pairings x 20 seeds in seconds).
12. D: RAVEN-only: `rnd01` used for everything (predates the stream split) — do NOT copy; world collision/camera rays
    live in game/c/world.c (never harvested, single user).
