# Engine API

Everything lives in package `ENGINE` (the export list in `engine/lisp/package.lisp` is the public
API, grouped by file); a game is its own package with `(:use :cl :engine)`. Sources: `engine/lisp/*.lisp`
(C: `engine/c/`, shaders: `engine/shaders/`). Rendering is SDL_GPU (WebGPU backend, WGSL); see
ARCHITECTURE.md for the pipeline. The smallest complete game is `examples/hello/hello.lisp`
(walkthrough: TUTORIAL.zh-TW.md step 2); `examples/engine-demo/demo.lisp` uses most of the
rendering, meshgen and UI calls. Names written `engine::x` below are internal (not exported).

## Conventions

* **Space:** Y up, right-handed, meters. The camera looks down its local −Z. Yaw is about +Y:
  yaw 0 faces −Z, positive yaw turns toward −X (counter-clockwise seen from above).
* **Angles:** radians. `(deg 90)` converts degrees.
* **Time:** seconds (single-float).
* **Colors:** sRGB floats 0..1. The renderer linearizes them itself. Where a function takes a
  *color*, it means a list or vector `(r g b [a])`. Hot fx functions take `r g b a` positionally.
* **Vectors/matrices** are `f32vec` = `(simple-array single-float (*))`: vec3 = 3 floats,
  mat4 = 16 floats **column-major** (WGSL `mat4x4f` layout).
* **`!` functions** write into their first argument and return it. They never allocate.
  Their float arguments must be **single-floats** (`1.0`, not `1`), or they signal `type-error`.
* **UI space:** framebuffer pixels, origin top-left, y down.
* **Per-frame consing:** keep it low (see ARCHITECTURE.md "GC rule" and "Gotchas"). Preallocate
  matrices, use `!` functions, write hot numeric code with `defun-fast` + `let*` + declarations.

## Frame skeleton

```lisp
(defun my-frame (dt)                   ; the engine calls PLATFORM-POLL and BEGIN-FRAME before,
  (camera-look-at 0 3 8  0 1 0)        ; position the camera BEFORE fx-* calls (billboards use it)
  ... update, draw-mesh, add-point-light, fx-*, ui-* ...)   ; and END-FRAME after (renders + presents)
(run-game :title "MY GAME" :load (list #'build-my-meshes) :start #'spawn-things :frame #'my-frame)
```

See "App" at the end for `RUN-GAME`. The engine's first startup step is
`(engine-init &key title (msaa 4))` = `platform-init` + `engine::render-init` + `engine::ui-init`.
MSAA is 4 or 1 (WebGPU has no 2/8).

## Platform / input (`platform.lisp`)

| call | returns / notes |
|---|---|
| `(platform-poll)` | pumps events, updates input edges + timing; NIL on quit |
| `(frame-dt)` | seconds since last frame, clamped to `*max-dt*` (default 1/15) |
| `(raw-dt)`, `(elapsed-time)`, `(fps)` | unclamped dt, seconds since init, smoothed FPS |
| `(window-width)`, `(window-height)`, `(window-aspect)` | framebuffer **pixels** (DPI-aware) |
| `(key-down k)` `(key-pressed k)` | K: `:a`..`:z` `:0`..`:9` `:f1`..`:f12` `:space :enter :escape :tab :backspace :left :right :up :down :lshift :rshift :lctrl :lalt :shift :ctrl :alt :minus :equals :comma :period :slash :semicolon :lbracket :rbracket`, or an SDL scancode integer. Keys use physical (US layout) positions. *pressed* is true for exactly one frame |
| `(mouse-down b)` `(mouse-pressed b)` | B: `:left :middle :right` |
| `(mouse-dx)` `(mouse-dy)` | motion this frame (CSS px). Works with and without pointer lock |
| `(mouse-wheel)` | wheel steps this frame (+ = away from the user) |
| `(pointer-locked-p)` | real browser lock state. Any click requests the lock (Esc releases it); a click that (re)acquires it is not reported as a press |
| `(focus-lost-p)` | T in the frame the window lost focus / was hidden |
| `(pad-connected-p)` | first gamepad present |
| `(pad-lx)` `(pad-ly)` `(pad-rx)` `(pad-ry)` | sticks −1..1, radial deadzone 0.2, **+Y = up** |
| `(pad-lt)` `(pad-rt)` | triggers 0..1 |
| `(pad-down b)` `(pad-pressed b)` | B: `:a :b :x :y` (= south/east/west/north) `:lb :rb :lt :rt :back :start :guide :ls :rs :dpad-up :dpad-down :dpad-left :dpad-right` |

## Math (`math.lisp`, pure CL, tested by `tests/test-math.lisp`)

Constructors (allocate; setup code): `(v3 x y z)` `(m4)` = identity,
`(make-f32 n)`, `(fv a b c ...)` (macro), `(xform &key x y z yaw pitch roll s sx sy sz)` → new mat4.
Also `v3-normalize v3-copy` (allocating).

Scalars: `(deg d)`, `(angle-wrap a)` → [−π,π), `(angle-lerp a b u)` (shortest arc),
`(approach x target step)`, `(smoothstep e0 e1 x)`, plus `clamp`, `lerp`, `f32` from package.lisp.

vec3: `v3-set! (o x y z)`, `v3-copy! (o a)`, `v3-add! v3-sub! (o a b)`, `v3-scale! (o a s)`,
`v3-madd! (o a b s)` (a + b·s), `v3-lerp! (o a b u)`, `v3-cross! (o a b)`, `v3-normalize! (o a)`,
`v3-dot (a b)`, `v3-len`, `v3-len2`, `v3-dist (a b)` (these are inline: no boxing in typed code).

mat4: `m4-identity! m4-copy!`, `m4-mul! (o a b)` (o = a·b, aliasing OK), `m4-translation! (o x y z)`,
**`m4-euler! (o px py pz yaw pitch roll &optional sx sy sz)`** (T·Ry·Rx·Rz·S) — the workhorse for rigid parts,
`m4-perspective! (o fovy aspect near far)` (WebGPU clip space: depth 0 = near .. 1 = far), `m4-look-at! (o eye target up)`,
`m4-invert! (o a)` (NIL if singular), `m4-transform-point! (o m v)`, `m4-transform-dir! (o m v)`.
Element access: internal macro `(engine::m@ m row col)`.

`(defun-fast name args ...)` — use for your own hot numeric functions (see Gotchas).

## Renderer (`render.lisp`)

### Meshes
`mesh` struct (`mesh-p`): `mesh-id` (renderer mesh table index), `mesh-count` (vertices). Build them with
meshgen (below). Meshes are immutable and live for the whole run (they share big GPU vertex buffers; there is no free).
Vertex format: position, normal, color (9 floats). Faces must be CCW from the front
(back faces are culled; mirrored model matrices are handled automatically).

**`(draw-mesh mesh model &key tint emissive flash alpha specular rim)`** — queues one draw; the matrix is
copied, so reuse one scratch mat4. `tint` color multiplies vertex colors; `emissive` 0 = lit only,
1–4 = glowing neon (feeds bloom); `flash` 0..1 lerps to white (hit flash); `alpha` < 1 goes to
the transparent pass (drawn after opaque, no depth write, unsorted); `specular` = wet-highlight
strength for this draw (0 = matte and skips the specular math; default/negative = `env-specular`); `rim` =
f32vec of 3 **linear** rgb floats (strength baked in, e.g. from RAVEN's `rim-vec`, game/lisp/bodies.lisp) added as `rim·(1−N·V)³` (character silhouettes).
~0 bytes consed per call.
Counters: `*draw-count*`, `*tri-count*` (last frame).

### Camera
`*camera*` is a `camera` struct (`make-camera`): `camera-pos`, `camera-target`, `camera-up` (vec3s),
`camera-shake` (vec3 offset added to pos and target — write it for screen shake),
`camera-fov` (vertical radians, default 60°), `camera-near` 0.1, `camera-far` 400.
Derived by `(update-camera)`: `camera-eye`, `camera-right`, `camera-upv`, `camera-forward`,
`camera-view`, `camera-proj`, `camera-view-proj`, `camera-inv-view-proj`.
`(camera-look-at px py pz tx ty tz)` sets and updates. If you write the slots directly, call
`(update-camera)` before any `fx-*` call. `end-frame` updates it again.
`(world-to-screen out x y z)` → T and `out` = (px, py, depth 0..1) if in front of the camera
(for HUD markers / enemy bars).

### Lights and look
`(add-point-light x y z r g b radius &optional (intensity 1))` — per frame; up to 8 used,
nearest to the camera target win when more are added. Light fades to 0 at `radius`. Lights with
intensity ≤ 0 and lights whose sphere is outside the view frustum take no slot (each used light
costs a full pass of the shader loop).
`(add-point-light-v v &optional (offset 0))` — same, reading `x y z r g b radius intensity` from
an f32vec: conses nothing (each float argument of `add-point-light` is boxed at the call site).

`*pixel-lights*` (default 8): how many of the used lights (nearest the camera target first) are
shaded per pixel; the rest are shaded per vertex (Gouraud). Per-vertex is much cheaper on weak /
software GPUs (SwiftShader world demo: 8 → 1 cuts the frame ~40 %) but a light pool on a big
low-poly face (2-triangle walls) blurs out, so keep 8 unless fill rate is the problem.

`*env*` (struct `environment`, `make-environment`, accessors `env-...`), all settable at any time:
`sky-top`, `fog-color` (also the horizon color), `fog-density` (/m), `fog-base`, `fog-falloff`,
`fog-max`, `ambient-sky`, `ambient-ground`, `ambient-intensity`, `moon-dir` (unit, *toward* the
moon), `moon-color`, `moon-intensity`, `rim-color`, `rim-intensity`, `rim-power`, `specular`
(wet highlight strength, 0 = matte), `shininess`, `exposure`, `bloom` (T/NIL), `bloom-threshold`,
`bloom-strength`, `vignette`. Colors are vec3s: `(v3-set! (env-fog-color *env*) 0.2 0.1 0.3)`.
`*render-scale*` (offscreen resolution factor, 1.0).

### Frame time, dynamic quality
* `*perf-log*` (NIL): T logs `perf: first frame at N ms after page load` once and
  `perf: startup … | frame … ms avg (fps) max … | render-scale … pixel-lights … | draws … tris …`
  every ~5 s.
* `*auto-render-scale*` (NIL): T enables dynamic quality. Frames are averaged in 1 s windows; a
  window over 1.25 × `*frame-budget-ms*` (18) steps down one level, 3 windows under budget step up.
  Levels: `*render-scale*` 1.0 → `*render-scale-min*` (0.7) in 0.1 steps, then `*pixel-lights*`
  3, then 1. A step down right after a step up locks step-ups for 10 s, doubling to 120 s, so it
  settles instead of flickering. Turning it off restores scale 1.0 / 8 pixel lights. It is off by
  default so headless screenshots stay deterministic; RAVEN turns it on in its `:start` function (`start-game`, game/lisp/main.lisp).

### FX batch (particles, trails, decals)
Drawn after meshes with depth test, no depth write, unlit, faded by fog. `mode` is `:add`
(glow, default) or `:alpha`. Alpha fades with the soft UV falloff (round sprites, soft edges).
Batches hold 16384 vertices each per frame; overflow increments `*fx-dropped*`.

| call | shape |
|---|---|
| `(fx-billboard x y z size r g b a &key mode rot)` | camera-facing round sprite, `size` = radius (m) |
| `(fx-line x0 y0 z0 x1 y1 z1 width r g b a &key mode end-width end-alpha)` | camera-facing soft segment (sparks, slashes, rain), `width` = half-width |
| `(fx-trail samples n r g b a &key mode)` | sword ribbon: `samples` f32vec of n × (base xyz, tip xyz), oldest first; fades out toward the oldest and toward the base |
| `(fx-decal x y z radius r g b a &key (mode :alpha))` | soft disc lying at height y (+2 cm). Blob shadow: `(fx-decal x 0 z 0.6 0 0 0 0.55)` |

Each float argument costs ~16 B of boxing at the call site; a few thousand calls per frame are fine.

## Mesh generation (`meshgen.lisp`, setup time)

```lisp
(build-mesh (mb :jitter 0.1 :color '(0.3 0.3 0.35))   ; → uploaded MESH
  (mb-box mb 1 2 1)
  (with-xform (mb (xform :y 1.2 :yaw 0.3)) (mb-color mb 0.8 0.1 0.1) (mb-sphere mb 0.3)))
```

Every primitive is centered on the current origin; `with-xform` composes a matrix onto the
builder transform (nests; mirroring flips winding automatically). Flat normals. `:jitter` varies
each face's brightness ±jitter (low-poly look).

`(make-mesh-builder)`, `(mb-color mb r g b)`, `(with-xform (mb matrix) ...)`, `(mb-build mb)`,
`(setf (mb-jitter mb) 0.1)`.
Primitives (sizes are full extents, meters):
`(mb-box mb w h d &key colors)` — `colors` = 6 colors for faces +X −X +Y −Y +Z −Z (NIL = current);
`(mb-bevel-box mb w h d bevel &key colors)`;
`(mb-cylinder mb radius height &key segments top-radius caps top-color)` along Y;
`(mb-cone mb radius height &key segments)`; `(mb-prism mb radius height sides)`;
`(mb-sphere mb radius &key segments rings stretch)`; `(mb-capsule mb radius height &key segments rings)`
(height includes the caps); `(mb-wedge mb w h d)` (full height at −Z, sloping to +Z);
`(mb-plane mb w d &key nx nz color2)` (XZ grid facing +Y, checker `color2`);
`(mb-blade mb &key length width thickness curve segments blade-color edge-color guard-color
handle-color wrap-color blade hilt)` — katana, origin at the guard, blade toward +Y with the
edge toward +Z, handle toward −Y (~0.28 m). `:hilt nil` / `:blade nil` build the parts
separately (e.g. to draw the blade emissive);
`(mb-quad mb a b c d &optional color)` (CCW = front),
`(mb-poly-out mb points &key color center)` (convex polygon, auto-oriented away from `center`).
`(mb-tube mb x0 y0 z0 x1 y1 z1 r &key sides caps)` (prism around a segment: pipes, beams, cables),
`(mb-flat-quad mb x0 z0 x1 z1 y &optional color)` (upward-facing rectangle at height y).
Colors from hex: `(hexc #xRRGGBB &optional k)` → `(r g b)`, `(mbc mb #xRRGGBB &optional k)` sets the
builder color; `(mb-cur-color mb)` is the current color (vec3).

## UI / text (`ui.lisp`)

Drawn after everything (no depth, alpha blended), reset each frame by `begin-frame`.
Built-in 5×7 bitmap font (`+font-5x7+`), ASCII 32–126, glyph cell 6×8 px × `scale`.

`(ui-text str x y &key (scale 2) color (align :left) shadow)` → width. `y` = top edge; `align`
`:left/:center/:right` relative to `x`; `#\Newline` starts a new line (10 px × scale);
`shadow` T or a color. `(text-width str &optional scale)`.
`(ui-rect x y w h color)`, `(ui-rect-outline x y w h color &optional thickness)`,
`(ui-gradient x y w h color1 color2 &key (vertical t))`,
`(ui-bar x y w h fraction color &key color2 bg border border-width)`,
`(ui-scale)` → suggested integer scale for the window (1 per 360 px of height, capped at 1 per 480 px of width),
`(fit-scale str want max-w)` → largest scale ≤ WANT at which STR fits MAX-W,
`(ui-block-text str x y px &key color color2 shear align)` → big text drawn as solid font-pixel blocks (crisp,
italic SHEAR, top→bottom gradient), `(%ui-poly4 x0 y0 x1 y1 x2 y2 x3 y3 c0 c1)` → any solid quad (slashes).

## Low-level (render.lisp internals, rarely needed by gameplay)

A `stream-buffer` is a CPU vertex batch (`stream-buffer-data` f32vec, `stream-buffer-fill` in
floats, `stream-buffer-stride`, `(stream-room-p sb nverts)`). `*fx-alpha*` / `*fx-add*` (9 floats per
vertex: pos, uv, rgba) are uploaded and drawn by `end-frame`; hot C code (game/c/world.c) may write
them directly. `(with-fx-verts (data o mode nverts) …)` reserves NVERTS vertices in the batch for
MODE; inside BODY `(vtx x y z u v r g b a)` appends one vertex (when the batch is full, BODY is
skipped and `*fx-dropped*` counts it). Internal:
`engine::make-stream-buffer`, `engine::*ui-batch*` (8 floats: pos xy, uv, rgba),
`(engine::make-pipeline slot vs-wgsl vs-entry fs-wgsl fs-entry layout target depth blend cull)`
(compiles a pipeline into a renderer slot, see `r_make_pipe` in engine/c/render.c).
`(wgsl "file.wgsl")` is the compile-time source string of `engine/shaders/file.wgsl`: `// #include
"other.wgsl"` lines are replaced by that file and comments are stripped. Mesh upload:
`(make-mesh data nfloats)` (meshgen calls it), `+vertex-floats+` = 9.

## Audio (`audio.lisp`, C mixer `engine/c/audio.c`)

Details, the mixer design and the autoplay handling: AUDIO.md.

* `(defsound key (&key (peak 0.9) loop) body…)` — BODY returns a sample buffer (48 kHz mono f32vec);
  it is synthesized during startup (one startup step per sound, in definition order), cleaned and
  normalized to PEAK. `LOOP` T = a seamless loop.
* Playback: `(play-sfx key &key gain pitch pan pitch-jitter)`, `(play-sfx-at key x y z listener-x
  listener-z listener-yaw &key gain pitch pitch-jitter)`, `(start-loop key &key gain)` → id,
  `(stop-loop id &optional fade)`, `(set-loop-gain id g)`; music: `music-play`, `music-stop`,
  `music-playing-p`, `music-intensify`, `(set-music-volume v)`; `(audio-locked-p)` (browser hasn't
  allowed audio yet), `(audio-stats)`. Voice ids are integers, -1 = not played.
* `RUN-GAME`'s startup steps open the device and synthesize every DEFSOUND, one sound per browser
  frame (`audio-init-begin` / `-sound` / `-end`). `*audio-debug*` T logs per-sound stats.
* Synthesis toolkit (all `au-` names in the export list): buffers `au-buf`, `au-render` (per-sample
  DSL, `tt` = local time), `+au-rate+` / `+au-dt+`; oscillators `au-sin au-saw au-sqr au-ph+`; noise
  `au-rnd au-noise au-fnoise`; envelopes `au-ar au-adsr au-env-exp au-sweep`; filters and effects
  `au-svf! au-onepole! au-drive! au-delay! au-reverb!`; utilities `au-mix! au-scale! au-normalize!
  au-peak au-fold au-frac au-expf au-powf au-rrange au-midi`; instruments `au-ping! au-partials!
  au-thump! au-taiko! au-gong! au-shaku! au-saws! au-whoosh`.

## Animation (`anim.lisp`)

A 21-joint humanoid rig (`+nj+`), poses and keyframe clips; GAMEPLAY.md "Rig & animation" has the
conventions.
* `(ji :hand-r)` → joint index at compile time; `(joint-index name)`, `(joint-mask &rest names)`
  (bitmask). A pose is an f32vec of `+pose-n+` (68) floats; `+root+` is the root's offset in it.
* `(defpose name (&key base) specs…)`, `(defclip name (dur &key loop base) keys…)`,
  `(find-pose name)`, `(find-clip name)`; `clip` accessors `clip-name clip-dur clip-loop`;
  `(clip-sample! out clip time)`.
* Playback: `(make-anim)`, `(anim-play an clip &key blend speed time restart)` (BLEND in 60 Hz
  frames), `(anim-advance an dt)`, `(anim-eval an)` → fills `(anim-pose an)`; accessors `anim-clip
  anim-time anim-speed anim-pose`.
* FK: `(pose-fk! jm pose px py pz yaw scale hunch)` writes one world mat4 per joint into JM
  (`+nj+` × 16 floats); `(joint-point! out jm j lx ly lz)` → a point in joint J's frame.

## Time (`time.lisp`)

Fixed steps for a game that wants frame-exact gameplay (RAVEN does; hello doesn't).
* `+step+` = 1/60 s. `*tick*` counts steps (also during hitstop).
* `(time-step)` — call once per fixed step; NIL means "hitstop: skip the simulation this step".
* `(hitstop frames)` — freeze the sim for FRAMES steps; concurrent requests take the max
  (scaled by `*hitstop-mult*`); `*hitstop*` = frames left.
* `(slowmo scale secs &optional others-only)` — time-scale the sim (or only "the others") for SECS
  real seconds; the lowest scale wins. `(slowmo-scale others)` → current scale for the main side
  (NIL) or the others (T); advance your frame counters by it.

## FX (`fx.lisp`)

Real-time or sim-time effects that live in flat float pools (no entities, no consing).
* **Shake:** `(shake amp dur)` (metres, seconds; max wins, × `*shake-mult*`), `(shake-update dt)`
  once per frame writes `camera-shake`.
* **Particles** (2000-slot pool): `(fx-emit type x y z vx vy vz life size grav r g b)`,
  `(fx-burst type n x y z dx dy dz spread smin smax life size r g b)` (all floats except N),
  `(fx-update dt)` and `(fx-draw-particles)` once per frame, `*plive*` = live count. Types:
  `+p-mist+ +p-dust+` (soft alpha puffs), `+p-spark+` (stretched additive streak), `+p-glow+`,
  `+p-feather+`, `+p-orb-a+ +p-orb-b+` (home to `*orb-target*` after 0.4 s and call
  `*on-orb-absorbed*` with `:a` / `:b`); `(fx-clear-orbs)`.
* **Rings:** `(fx-ring x y z r0 r1 dur r g b &key flat width)` (camera-facing, or FLAT on the
  ground), `(fx-rings-update dt)` once per frame advances and draws them.
* **Debris:** `(fx-debris mesh m mo vx vy vz spin)` throws a copy of MESH drawn with the matrix at
  M[MO..MO+15]; `(fx-debris-update dt)` (sim seconds) integrates and draws; `*debris-life*`;
  `(fx-clear-debris)`.
* **Trails:** `(make-trail)` → buffer of `+trail-n+` base/tip samples; `(trail-push tr bx by bz tx ty
  tz)`, `(trail-decay tr)`; draw with `fx-trail`.
* `(edge-vignette r g b a frac)` — UI-space darkening toward the screen edges.

## ECS (`ecs.lisp`)

Plain CL (tested by `tests/ecs-test.lisp`). Background: ARCHITECTURE.md "Game structure".
* `(defcomponent name ["doc"] slot…)` — slots as in DEFSTRUCT: `(slot default :type type)`. Defines
  `make-NAME`, `NAME-SLOT` accessors and the getter `(NAME e)` → the component or NIL.
* `(spawn-entity component…)` → handle; `(destroy-entity e)`; `(clear-entities)`;
  `(entity-alive-p e)` (NIL for NIL, destroyed or reused handles); `(add-component e c)` (replaces
  one of the same kind); `(remove-component e 'name)`. `+max-entities+` = 256.
* `(do-entities (e comp (var comp2) …) body…)` — BODY for every entity having all the listed
  components, in slot order; each component is bound to a variable of its name, or to VAR.
* Events: `(emit kind data…)` queues `(kind . data)`; `(take-events)` → all queued events, oldest
  first, and empties the queue.

## App (`app.lisp`)

* `(run-game &key title load start frame debug stats)` — register the game, once, at load time.
  `:load` = list of functions, one startup step each (after `engine-init`, before audio); `:start`
  = called once when loading and sound synthesis are done; `:frame` = function of the real dt
  (seconds, ≤ 0.1), called every frame between `begin-frame` and `end-frame`; `:debug` = function
  of N for `Module._debug_cmd(N)` from the page; `:stats` = function returning a string appended
  to the stats line. Errors inside any of them stop the main loop and are shown on the page.
* `*stats-log*` T: log `stats: fps … cons/frame … B draws … tris … particles … | ms/frame sim … queue
  … render …` every 2 s. `(perf-mark)` called twice inside `:frame` splits "sim" from "queue".
  `(cons-per-frame)`, `(cons-bytes)` (since the last GC), `(now-ms)`.

## Package helpers (`package.lisp`)

* Types `f32` (= single-float; `(f32 x)` coerces) and `f32vec`; `(f32vec-p x)`; `clamp`, `lerp`;
  `(log-msg fmt args…)` prints a console line.
* `(defun-fast name args …)` — DEFUN for hot numeric code: checks declared argument types on entry,
  runs the body at `(safety 0)` (see ARCHITECTURE.md Gotchas). Declare every float local.
* Float macros compiled to plain C (no boxing): `f-min f-max f-abs f-sqrt f-sin f-cos f-atan2 f-mod
  f-acos f-asin f-clamp f-wrap` (angle into [−π, π)), `i->f`, `f->i` (floor).
* Random numbers (C xorshift, no consing): `(rnd01)` in [0, 1), `(rnd-range a b)`.

## Snippets

**Rigid-part character (one draw per part)**
```lisp
(defvar *root* (m4)) (defvar *local* (m4)) (defvar *world* (m4))
(defun-fast draw-ninja (x z yaw arm flash)
  (declare (single-float x z yaw arm flash))
  (m4-euler! *root* x 1.0 z yaw 0.0 0.0)
  (draw-mesh *m-torso* *root* :flash flash)
  (m4-mul! *world* *root* (m4-euler! *local* 0.28 0.26 0.0 0.0 arm 0.0))   ; shoulder
  (draw-mesh *m-arm* *world* :flash flash)
  (fx-decal x 0.0 z 0.6 0.0 0.0 0.0 0.55))                                  ; blob shadow
```

**Spark burst / neon glow into the fx batch**
```lisp
(fx-billboard px py pz 0.12 1.0 0.5 0.2 0.9)                    ; additive, round
(fx-line px py pz (- px (* 0.03 vx)) (- py (* 0.03 vy)) (- pz (* 0.03 vz))
         0.02 1.0 0.7 0.3 1.0 :end-width 0.0 :end-alpha 0.0)   ; velocity-stretched spark
(add-point-light px py pz 1.0 0.5 0.2 3.0 2.0)                  ; brief light at the hit
```

**HUD**
```lisp
(let ((s (ui-scale)))
  (ui-bar 20 20 (* 160 s) (* 8 s) (/ hp max-hp) '(0.6 0.0 0.1) :color2 '(1 0.2 0.3) :border '(1 1 1 0.5))
  (ui-text (format nil "~d HITS" combo) (- (window-width) 20) 20 :scale (* 3 s) :align :right :shadow t))
```

**Input**
```lisp
(let ((mx (+ (pad-lx) (if (key-down :d) 1.0 0.0) (if (key-down :a) -1.0 0.0)))
      (my (+ (pad-ly) (if (key-down :w) 1.0 0.0) (if (key-down :s) -1.0 0.0))))
  (when (or (key-pressed :j) (mouse-pressed :left) (pad-pressed :x)) (start-light-attack))
  (incf cam-yaw (* -0.005 (mouse-dx))))
```
