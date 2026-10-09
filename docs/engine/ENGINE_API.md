# Engine API

Everything lives in package `ENGINE` (the export list in `engine/lisp/package.lisp` is the public
API, grouped by file); a game is its own package with `(:use :cl :engine)`. Sources: `engine/lisp/*.lisp`
(C: `engine/c/`, shaders: `engine/shaders/`). Rendering is SDL_GPU (WebGPU backend, WGSL); see
ARCHITECTURE.md for the pipeline. The smallest complete game is `examples/hello/hello.lisp`
(walkthrough: TUTORIAL.zh-TW.md step 2); `examples/engine-demo/demo.lisp` uses most of the
rendering, meshgen and UI calls. Names written `engine::x` below are internal (not exported).
Two games use it: RAVEN EDGE (`game/`, package RAVEN) and SOUL DUEL (`duel/`, package DUEL); "used
by" notes below say which game calls an API when only one does. Harvested from the games (the
"harvest", DEVLOG): the vpad, hit volumes, facing helpers, the fixed-step accumulator, the
rigid-part body builder, the cinematic director, ribbons / sectors / bitmaps and a few helpers.

## Conventions

* **Space:** Y up, right-handed, meters. The camera looks down its local −Z. Yaw is about +Y:
  yaw 0 faces −Z, positive yaw turns toward −X (counter-clockwise seen from above).
* **Angles:** radians. `(deg 90)` converts degrees. A character's facing is its yaw; its forward
  direction is `(fwd-x yaw) (fwd-z yaw)` = (−sin yaw, −cos yaw) (math.lisp).
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
| `(key-down k)` `(key-pressed k)` | K: `:a`..`:z` `:0`..`:9` `:f1`..`:f12` `:space :enter :escape :tab :backspace :left :right :up :down :lshift :rshift :lctrl :rctrl :lalt :ralt :shift :ctrl :alt :minus :equals :comma :period :slash :semicolon :lbracket :rbracket :quote :backslash :grave :capslock :insert :delete :home :end :pageup :pagedown`, numpad `:kp-0`..`:kp-9 :kp-enter :kp-plus :kp-minus :kp-multiply :kp-divide :kp-period`, or an SDL scancode integer. Keys use physical (US layout) positions. *pressed* is true for exactly one frame |
| `(mouse-down b)` `(mouse-pressed b)` | B: `:left :middle :right` |
| `(mouse-dx)` `(mouse-dy)` | motion this frame (CSS px). Works with and without pointer lock |
| `(mouse-wheel)` | wheel steps this frame (+ = away from the user) |
| `(pointer-locked-p)` | real browser lock state. With `*pointer-lock*` T (default) any click requests the lock (Esc releases it) and a click that (re)acquires it is not reported as a press |
| `*pointer-lock*` | T (default): mouse-look games, as above. NIL: clicks are ordinary presses and the lock is never requested (menus, a fighter) |
| `(focus-lost-p)` | T in the frame the window lost focus / was hidden |
| `(pad-count)` | open gamepads, 0..4 |
| `(pad-connected-p &optional (pad 0))` | a gamepad is in slot PAD (0..3). A pad takes the first free slot when connected and keeps it until unplugged; the others never move |
| `(pad-lx &optional (pad 0))` `pad-ly` `pad-rx` `pad-ry` | sticks −1..1, radial deadzone 0.2, **+Y = up** |
| `(pad-lt &optional (pad 0))` `pad-rt` | triggers 0..1 |
| `(pad-down b &optional (pad 0))` `(pad-pressed b &optional (pad 0))` | B: `:a :b :x :y` (= south/east/west/north) `:lb :rb :lt :rt :back :start :guide :ls :rs :dpad-up :dpad-down :dpad-left :dpad-right` |

Every pad reader defaults to slot 0; `(pad-lx)` compiles to an inline read of `*input*` (pad 0's
axes), `(pad-lx 1)` to one C call, neither conses. Headless tests cannot plug in a pad.

## Virtual controller (`input.lisp`, plain CL, tested by `tests/input-test.lisp`)

A **vpad** is the only input gameplay code needs to read: devices, a CPU player and test scripts
all write it the same way, once per fixed step, so a CPU press or a replay is indistinguishable
from a key and a seeded match replays exactly. Used by SOUL DUEL (duel/lisp/control.lisp holds its
nine buttons, command table and bindings); no device is touched here.
* `(make-vpad &key actions modifier (buffer 10) reader)` — ACTIONS: the button keywords (list or
  vector). MODIFIER: one of them (or NIL) — a press made while it is held, or in the same step, is
  *modified* (one button, two commands). BUFFER: steps a press stays buffered until consumed.
  READER: NIL or a function of the vpad (the device reader) run by `vpad-begin-step!`.
* Per step: `(vpad-begin-step! vp)` (tick + reader), then `(vpad-set! vp action down)` for each
  button and `(vpad-stick! vp x y)` (x right, y up, clamped to length 1).
* Read: `(vpad-down vp a)`, `(vpad-held vp a)` → steps held (0 = up), `(vpad-pressed vp a
  &optional within)` → buffered and not consumed, `(vpad-modded-p vp a)`, `(vpad-consume! vp a)`,
  `vpad-sx` `vpad-sy`; `(vpad-flush! vp)` forgets presses but keeps holds (end of a cutscene),
  `(vpad-clear! vp)` releases everything.
* Commands: a table `((command button mod) …)`, highest priority first, MOD `t` / `nil` / `:any`
  (needs the modifier / needs it up / ignores it). `(vpad-command vp table &optional allowed)` →
  values command button (then `vpad-consume!` the button); a game whose top command may be refused
  walks its table with `(vpad-command-pressed-p vp button mod)` instead.
* Devices as data: a binding plist maps each action (and `:up :down :left :right` for the stick) to
  inputs `(device name …)` (a chord: all names down), e.g. `(:quick ((:key :j) (:pad :x)))`.
  `(vpad-read! vp bindings down-p &optional ax ay)` sets every button and the stick asking the
  game's `(down-p device name)`; `(inputs-down-p inputs down-p)`. Reader example:
  `(make-vpad :actions *my-actions* :reader (lambda (vp) (vpad-read! vp *p1-bindings* #'my-down-p (pad-lx 0) (pad-ly 0))))`.

## Math (`math.lisp`, pure CL, tested by `tests/test-math.lisp`)

Constructors (allocate; setup code): `(v3 x y z)` `(m4)` = identity,
`(make-f32 n)`, `(fv a b c ...)` (macro), `(xform &key x y z yaw pitch roll s sx sy sz)` → new mat4.
Also `v3-normalize v3-copy` (allocating).

Scalars: `(deg d)`, `(angle-wrap a)` → [−π,π), `(angle-lerp a b u)` (shortest arc),
`(approach x target step)`, `(smoothstep e0 e1 x)`, plus `clamp`, `lerp`, `f32` from package.lisp.
`(hypot a b [c])` (macro) → exactly `(sqrt (+ (* a a) (* b b) [(* c c)]))`: symbols and literals are used as they are,
any other form is bound once in argument order, so the expansion is the hand-written form it replaces and the sim's
float order is kept (SOUL DUEL's native sim and wasm compile the same operations); `f-hypot` (package.lisp) is the
`f-sqrt` twin — never swap one flavour for the other at a site, and leave `(expt x 2)` forms as they are.
`(countdown! place dt)` (macro) → `(setf place (f32 (max 0.0 (- place dt))))`, a timer run down to 0 (PLACE is
evaluated twice: keep it free of side effects).

Facing (both games): `(fwd-x yaw)` `(fwd-z yaw)` → the forward direction of YAW (inline, single-float
YAW), `(yaw-to dx dz)` → the yaw facing direction (dx dz) (float `atan2f`, no consing; SOUL DUEL's
sim keeps its own `dir-yaw`, CL's double-precision ATAN, which its seeded replays were recorded
with), `(turn-toward cur target step)` → CUR turned toward TARGET by at most STEP radians, the short
way. `(weighted-pick r key weight …)` → the key whose share of the total weight contains R in [0,1)
(NIL keys allowed; for AI choices pass `(sim-rnd01)`). The file is plain CL: host tests load
`package.lisp` + `math.lisp` (+ `hitvol.lisp`, `input.lisp`, `cine.lisp`) natively; `yaw-to` is the one
C-inline call and must not run there.

## Hit volumes (`hitvol.lisp`, plain CL, tested by `tests/rules-test.lisp`, `tests/duel-rules-test.lisp`)

Hurt volumes are vertical cylinders (radius TR, height TH) on the target's feet (TX TY TZ). Both games.
* Attacker-relative (melee): `(make-vol kind args)` → a 5-float vector: `(:arc r deg y0 y1)` pie
  slice (full angle in degrees) from height y0 to y1, `(:cap a b h r)` capsule along the facing from
  a to b m at height h, `(:sph fwd up r)` sphere, `(:tsph r)` sphere at the target point.
  `(vol-hit-p v ax ay az fx fz tx ty tz tr th extra)` → does V of an attacker at (ax ay az) facing
  (fx 0 fz) touch the cylinder? EXTRA widens arc radii. Single-float arguments, safety 0, no consing.
* World-space (hazards): `(capsule-cyl-hit-p ax ay az bx by bz r tx ty tz tr th)`,
  `(obox-cyl-hit-p cx cy cz yaw hw hh hl tx ty tz tr th)` (a yaw-turned box: half width / height /
  length), `(cyl-cyl-hit-p ax ay az ar ah bx by bz br bh)`.
* Debug outlines (fx.lisp): `(draw-circle x y z r cr cg cb &key (segments 16) (width 0.012) (alpha
  0.8))`, `(draw-vol v ax ay az yaw &optional tx ty tz)` (red; a TSPH needs the target point).

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

**`(draw-mesh mesh model &key tint emissive flash alpha specular rim env-rim toon)`** — queues one draw; the matrix is
copied, so reuse one scratch mat4. `tint` color multiplies vertex colors; `emissive` 0 = lit only,
1–4 = glowing neon (feeds bloom); `flash` 0..1 lerps to white (hit flash); `alpha` < 1 goes to
the transparent pass (drawn after opaque, no depth write, unsorted); `specular` = wet-highlight
strength for this draw (0 = matte and skips the specular math; default/negative = `env-specular`); `rim` =
f32vec of 3 **linear** rgb floats (strength baked in, e.g. `(rim-vec #xBFD8FF 0.22)`, meshgen.lisp) added as `rim·(1−N·V)³` (character silhouettes);
`env-rim` (1.0) multiplies the environment rim (`env-rim-*`) for this draw: 0 = none (a stage floor or
wall that must not glow at grazing angles), the draw's own `rim` is added either way.
`toon` = NIL (the lit shader, RAVEN) or an f32vec of 4 toon lanes `(mode feet-y fog-scale spare)`: mode 1 =
toon stage (lit by the moon, the per-pixel lights as flat 2-step pools, lighter shadows), 2 = toon
character (the camera-space key light, a darker-toward-the-feet gradient from `feet-y`, the strongest
fx light within 4 m warms only the shadow side); `fog-scale` multiplies the fog (e.g. 0.2 keeps
characters crisp). Toon draws are two-tone and palette-exact (the lit tone is the vertex colour × tint,
no exposure or ACES; the shadow tone is designed per colour in HSV: darker, more saturated, hue turned,
neutrals cold blue-grey), ignore `specular`, `rim` and the env rim, and must be opaque (`alpha` < 1
falls back to the lit shader). Mode 3 = an **ink hull** (a mesh built with `mb-hull`), lanes
`(3 push fog-scale px)`: the shell is pushed out by its extrusion × PX pixels at 720 lines (thinner where
it faces the camera), then PUSH metres away from the camera along the view ray, and drawn front-culled in
its vertex colour × tint (`RP_HULL` / `RP_HULL_CW`): an ink outline that shows only where the surface
behind is farther than PUSH (`draw-parts :hulls` does this for bodies). Keep the lanes in one f32vec and
set its slots: 0 bytes per call.
~0 bytes consed per call.
Counters: `*draw-count*`, `*tri-count*` (last frame).

### Camera
`*camera*` is a `camera` struct (`make-camera`): `camera-pos`, `camera-target`, `camera-up` (vec3s),
`camera-shake` (vec3 offset added to pos and target — write it for screen shake),
`camera-fov` (vertical radians, default 60°), `camera-shift-y` (lens shift: the image moves up this much in NDC,
default 0 = a centred frustum; a portrait screen uses it to put the subject off-centre), `camera-near` 0.1, `camera-far` 400.
Derived by `(update-camera)`: `camera-eye`, `camera-right`, `camera-upv`, `camera-forward`,
`camera-view`, `camera-proj`, `camera-view-proj`, `camera-inv-view-proj`.
`(camera-look-at px py pz tx ty tz)` sets and updates. If you write the slots directly, call
`(update-camera)` before any `fx-*` call. `end-frame` updates it again.
`(world-to-screen out x y z)` → T and `out` = (px, py, depth 0..1) if in front of the camera
(for HUD markers / enemy bars).

### Lights and look
`(add-point-light x y z r g b radius &optional (intensity 1) (priority 0))` — per frame; up to 8
used. When more are added, the highest `priority` (an integer) wins, then the ones nearest the
camera target (priority 0 everywhere = nearest first, the old behaviour). Light fades to 0 at
`radius`. Lights with intensity ≤ 0 take no slot, and lights whose sphere is outside the view
frustum are dropped first whatever their priority (each used light costs a full pass of the shader
loop). Use priority for the lights that must not flicker out: a Bankai aura over a crowd of
embers, the hit light of the current attack.
`(add-point-light-v v &optional (offset 0) (priority 0))` — same, reading `x y z r g b radius
intensity` from an f32vec: conses nothing (each float argument of `add-point-light` is boxed at the call site).

`*pixel-lights*` (default 8): how many of the used lights (highest priority, then nearest the camera target first) are
shaded per pixel; the rest are shaded per vertex (Gouraud). Per-vertex is much cheaper on weak /
software GPUs (SwiftShader world demo: 8 → 1 cuts the frame ~40 %) but a light pool on a big
low-poly face (2-triangle walls) blurs out, so keep 8 unless fill rate is the problem.

`*env*` (struct `environment`, `make-environment`, accessors `env-...`), all settable at any time:
`sky-top`, `fog-color` (also the horizon color), `fog-density` (/m), `fog-base`, `fog-falloff`,
`fog-max`, `ambient-sky`, `ambient-ground`, `ambient-intensity`, `moon-dir` (unit, *toward* the
moon), `moon-color`, `moon-intensity`, `sun-size` (1.0: the sky disc's radius multiplier; the default
is ~1.6°), `sun-glow` (0.25: strength of the halo around it; both only change the sky — use them for
a big dusk sun), `rim-color`, `rim-intensity`, `rim-power`, `specular`
(wet highlight strength, 0 = matte), `shininess`, `exposure`, `bloom` (T/NIL), `bloom-threshold`,
`bloom-strength`, `vignette`. Colors are vec3s: `(v3-set! (env-fog-color *env*) 0.2 0.1 0.3)`.
The toon look (SOUL DUEL): `toon` (NIL) T draws the sky with `fs_sky_toon` (the same gradient,
palette-exact, a flat `moon-color` disc of `sun-size` with two flat halo rings of strength `sun-glow`),
fills the frame's toon lanes and shades 2 point lights per pixel on toon stage draws (so
`*pixel-lights*` and the auto-quality light steps do nothing); its knobs: `key-light` (vec3 in camera
axes right / up / back, default (−0.45 0.62 0.40): lit ≈ 73 % of what the camera sees, and a cut never
flips it), `toon-threshold` (0.5), `toon-band` (0.02, half-width of the soft terminator),
`toon-gradient` (0.14) over `toon-gradient-height` (1.8 m), `toon-light-gain` (0.45, stage pools),
`shade-value` (0.72), `shade-saturation` (1.25), `shade-hue` (8°), `shade-lift` (0.25, stage shadows
toward the lit tone), `cin-rim` (vec3 sRGB, 0 = off: a hard back-rim on toon characters, for
silhouette shots; with `toon-threshold` 1.5 the whole body is in its shadow tone) of width
`cin-width` (0.16). NIL leaves every frame exactly as before (RAVEN).
`*render-scale*` (offscreen resolution factor, 1.0).
`*grade-desat*` (0.0): the composite pass mixes the final scene color toward its luma by this
amount; 0 leaves the image exactly unchanged, 1 is greyscale (KO / flashback grading). The UI is
drawn after it and keeps its colors.
`*grade-split*` (0.0): window pixels. The composite shows the left half of the frame shifted up
and the right half shifted down by this much, split along the vertical centre line; the strips
that uncovers are black (a "the sky is cut in two" beat, e.g. 24). 0 = the plain image. The UI is
not split.

**Screen punctuation** (docs/style/STYLE_STORM_DESIGN.md §3.6): `(grade-impact mode &key (threshold 0.4)
(keep-sat 0.45) (keep-hue 10) (keep-hue-2 keep-hue) (ink '(0.031 0.031 0.047)) (paper '(1 1 1)))` sets `*grade-impact*` and
`*impact-params*`: 1 negative, 2 two-tone (INK below the luma THRESHOLD, PAPER above), 3 manga page
(two-tone, but pixels with HSV saturation > KEEP-SAT and value > 0.25 keep their colour: fire and
blood stay), 4 spot-keep (greyscale except saturated pixels within 25° of KEEP-HUE or KEEP-HUE-2), 0 off. The
composite then runs `RP_COMP_FX` (the plain composite otherwise); the game owns the duration. The UI is
drawn after it and keeps its colours.

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
(glow, default) or `:alpha`, or `:toon` (the toon batch, see "Toon effects" under FX: its colour lanes
mean heat, seed, wobble, `toon-a`). Alpha fades with the soft UV falloff (round sprites, soft edges).
Batches hold 16384 vertices each per frame; a call that does not fit is skipped and increments
`*fx-dropped*` (a running total, also at the end of the stats line). In the additive batch a
sprite's center is whitened (hot core); a **negative vertex alpha** means |alpha| without that
white core (`+p-flame+` uses it after its hot phase).

| call | shape |
|---|---|
| `(fx-billboard x y z size r g b a &key mode rot)` | camera-facing round sprite, `size` = radius (m) |
| `(fx-line x0 y0 z0 x1 y1 z1 width r g b a &key mode end-width end-alpha)` | camera-facing soft segment (sparks, slashes, rain), `width` = half-width |
| `(fx-trail samples n r g b a &key mode)` | sword ribbon: `samples` f32vec of n × (base xyz, tip xyz), oldest first; fades out toward the oldest and toward the base |
| `(fx-decal x y z radius r g b a &key (mode :alpha))` | soft disc lying at height y (+2 cm). Blob shadow: `(fx-decal x 0 z 0.6 0 0 0 0.55)` |
| `(fx-ribbon x y z ax ay az w0 w1 r0 g0 b0 a0 r1 g1 b1 a1 ph sway &key (segs 6) (mode :add))` | macro: a camera-facing strip from (x y z) along the axis (ax ay az), half-width W0 → W1, colour base → tip, flickering width and sideways SWAY with phase PH. Single-float argument forms, 0 bytes consed. SOUL DUEL builds its flames, pillars and auras from layers of it (in the toon batch: `toon-ribbon`, `%tongue`, "Toon kit" under FX) |
| `(fx-sector x y z r0 r1 yaw half r g b a &key (mode :add) (segs 16))` | flat annular sector at height y (+3 cm) between radii R0 and R1, centred on facing YAW, ±HALF radians (≥ π = a full ring), soft toward both radii: telegraph cones, fire-wave fronts (SOUL DUEL). Its 0 B macro form: `%sector-verts` ("Toon kit") |

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
`(setf (mb-jitter mb) 0.1)`. `(mb-at (mb xform-args…) body…)` = `(with-xform (mb (xform xform-args…)) body…)`,
e.g. `(mb-at (mb :y 0.57 :roll 0.4) (mb-cylinder mb 0.05 0.3))` (SOUL DUEL's stage).
Primitives (sizes are full extents, meters):
`(mb-box mb w h d &key colors)` — `colors` = 6 colors for faces +X −X +Y −Y +Z −Z (NIL = current);
`(mb-bevel-box mb w h d bevel &key colors)`;
`(mb-cylinder mb radius height &key segments top-radius caps top-color smooth)` along Y;
`(mb-cone mb radius height &key segments)`; `(mb-prism mb radius height sides)`;
`(mb-sphere mb radius &key segments rings stretch smooth)`; `(mb-capsule mb radius height &key segments rings)`
(height includes the caps); `(mb-wedge mb w h d)` (full height at −Z, sloping to +Z);
`(mb-plane mb w d &key nx nz color2)` (XZ grid facing +Y, checker `color2`);
`(mb-blade mb &key length width thickness curve segments blade-color edge-color guard-color
handle-color wrap-color blade hilt)` — katana, origin at the guard, blade toward +Y with the
edge toward +Z, handle toward −Y (~0.28 m). `:hilt nil` / `:blade nil` build the parts
separately (e.g. to draw the blade emissive); `:smooth t` on a sphere / capsule / cylinder side gives
analytic per-vertex normals (round shading; cylinder caps stay flat), otherwise every face is flat;
`(mb-hull dst src &key start end k c color)` appends to builder DST the ink hull of SRC's triangles in
floats [START, END) (default all; read `mb-fill` around a shape for its range): the same triangles in
COLOR, each vertex's normal slot holding its extrusion E (vertices grouped by position, face normals
recomputed; E = K·ŝ / max(min ŝ·n, C): a box corner gets (±1 ±1 ±1)·K; C 0.55 for boxes and round
shapes, 0.8 caps the spike at cone / blade tips). Draw the built mesh with DRAW-MESH toon mode 3.
`(mb-quad mb a b c d &optional color)` (CCW = front),
`(mb-poly-out mb points &key color center)` (convex polygon, auto-oriented away from `center`).
`(mb-tube mb x0 y0 z0 x1 y1 z1 r &key sides caps)` (prism around a segment: pipes, beams, cables),
`(mb-flat-quad mb x0 z0 x1 z1 y &optional color)` (upward-facing rectangle at height y).
Colors from hex: `(hexc #xRRGGBB &optional k)` → `(r g b)`, `(rim-vec #xRRGGBB k)` → the linear-rgb
f32vec DRAW-MESH `:rim` wants (both games), `(mbc mb #xRRGGBB &optional k)` sets the
builder color; `(mb-cur-color mb)` is the current color (vec3). `(mb-xform mb)` is the builder's
current local→mesh transform (mat4, the product of the enclosing `with-xform`s): read it, e.g.
`(m4-transform-point! out (mb-xform mb) p)` to know where a local point lands in the mesh (attach
points, emitter positions); change it only through `with-xform` (which also tracks mirroring).

## UI / text (`ui.lisp`)

Drawn after everything (no depth, alpha blended), reset each frame by `begin-frame`.
Built-in 5×7 bitmap font (`+font-5x7+`), ASCII 32–126, glyph cell 6×8 px × `scale`.

`(ui-text str x y &key (scale 2) color (align :left) shadow)` → width. `y` = top edge; `align`
`:left/:center/:right` relative to `x`; `#\Newline` starts a new line (10 px × scale);
`shadow` T or a color. Glyphs are written unboxed: a few boxed numbers per line, nothing per
glyph (~64 B for a 26-character line). `(text-width str &optional scale)`.
`(ui-big-text str x y scale color shadow s &key (shear 0.18))` → a title: centred block text
(UI-BLOCK-TEXT, SCALE px blocks, italic SHEAR) with a SHADOW colour offset 2 px × UI scale S, Y its
vertical centre, shrunk to fit the window width (both games' titles, banners, big words).
`(ui-bitmap rows x y px &key color color2 shear width)` → width: any bitmap (ROWS = a list of
integers, one per row, MSB = leftmost column) as solid PX-pixel blocks, top-left at (x y), colour
top → bottom, italic SHEAR. Pass the same (EQ) list every frame: its merged rectangles are cached,
so a call conses only a few boxed numbers. SOUL DUEL draws its hand-made kanji with it.
`(ui-rect x y w h color)`, `(ui-rect-outline x y w h color &optional thickness)`,
`(ui-gradient x y w h color1 color2 &key (vertical t))`,
`(ui-bar x y w h fraction color &key color2 bg border border-width)`,
`(ui-scale)` → suggested integer scale for the window (1 per 360 px of height, capped at 1 per 480 px of width),
`*ui-text-min*`: the smallest glyph pixel size UI-TEXT / UI-BLOCK-TEXT drew since a caller last reset it (a text-floor probe).
`(fit-scale str want max-w)` → largest scale ≤ WANT at which STR fits MAX-W,
`(ui-block-text str x y px &key color color2 shear align)` → big text drawn as solid font-pixel blocks (crisp,
italic SHEAR, top→bottom gradient; ~100 B per call, nothing per font pixel),
`(%ui-poly4 x0 y0 x1 y1 x2 y2 x3 y3 c0 c1)` → any solid quad (slashes). `%ui-poly4` is a function
plus a compiler macro: a direct call compiles in place, so in DEFUN-FAST code with float locals it
conses nothing; `ui-rect` / `ui-gradient` cons nothing themselves (only what the caller boxes).
**`(with-ui-verts (data o nverts) … (uvtx x y r g b a [u v]) …)`** — the UI twin of
`with-fx-verts`: reserves NVERTS vertices (6 per quad, two triangles) in the UI batch and appends
them in place; `u v` default to the font atlas's solid white cell (flat color). BODY is skipped
(NIL) when the batch (32768 vertices) is full. Zero consing in DEFUN-FAST code:
```lisp
(with-ui-verts (d o 6)      ; one quad TL TR BR / TL BR BL, white fading out to the right
  (uvtx x0 y0 1f0 1f0 1f0 1f0) (uvtx x1 y0 1f0 1f0 1f0 0f0) (uvtx x1 y1 1f0 1f0 1f0 0f0)
  (uvtx x0 y0 1f0 1f0 1f0 1f0) (uvtx x1 y1 1f0 1f0 1f0 0f0) (uvtx x0 y1 1f0 1f0 1f0 1f0))
```
**Zero-cons quads** (macros over `with-ui-verts`; every argument a single-float form; SOUL DUEL's HUD):
`(%hq x0 y0 x1 y1 x2 y2 x3 y3 r g b a [r1 g1 b1 a1])` one quad TL TR BR BL, colour (R G B A) on the top edge,
(R1 G1 B1 A1) (default the same) on the bottom; `(%hrect x y w h r g b a [r1 g1 b1 a1])` an axis-aligned rect;
`(%hbar x y w h frac right r g b a [r1 g1 b1 a1])` FRAC (clamped 0..1) of the box, from the left or (RIGHT) the
right; `(%houtline x y w h r g b a)` a 1 px outline; `(%pulse tm hz)` → 0..1, HZ times a second at time TM (HZ a
literal). DEFUN-FASTs on `%hq` (24 segments): `(%ring cx cy r wd cr cg cb ca)`, `(%arc cx cy r wd frac cr cg cb ca)`
(FRAC of the ring, clockwise from the top), `(%disc cx cy r cr cg cb ca)`.

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
  normalized to PEAK. `LOOP` T = a seamless loop. At most `+au-slots+` (128, the C mixer's slots)
  sounds per build: the 129th DEFSOUND signals an error when the module loads.
* Playback: `(play-sfx key &key gain pitch pan pitch-jitter)`, `(play-sfx-at key x y z listener-x
  listener-z listener-yaw &key gain pitch pitch-jitter)`, `(sfx-at key x y z &key gain pitch)` = the
  same with `*camera*` as the listener (both games' in-world sounds), `(start-loop key &key gain)` → id,
  `(stop-loop id &optional fade)`, `(set-loop-gain id g)`; music (one track at a time, on the
  music bus): `(music-play &optional (key :music))` starts the loop KEY unless music is playing
  (switch tracks with `(music-stop fade)` first), `(music-stop &optional fade)`, `music-playing-p`,
  `(music-intensify &optional (key :music))` restarts KEY 12 % faster/higher, `(set-music-volume v)` (the music bus,
  0..2, default 0.55), `(set-sfx-volume v)` (the sfx bus: every sound but the music, 0..2, default 1; SOUL DUEL's
  silence beat mutes it); `(audio-locked-p)` (browser hasn't
  allowed audio yet), `(audio-stats)`. Voice ids are integers, -1 = not played.
* `RUN-GAME`'s startup steps open the device and synthesize every DEFSOUND, one sound per browser
  frame (`audio-init-begin` / `-sound` / `-end`). `*audio-debug*` T logs per-sound stats (peak,
  rms, dc; the pass conses ~10 KB per sound whatever its length).
* `(list-sounds)` → every DEFSOUND key in definition order; `(sound-loop-p key)` → T for a LOOP sound
  (viewers / sound tests: `(if (sound-loop-p k) (music-play k) (play-sfx k))`).
* Synthesis toolkit (all `au-` names in the export list): buffers `au-buf`, `au-render` (per-sample
  DSL, `tt` = local time), `+au-rate+` / `+au-dt+`; oscillators `au-sin au-saw au-sqr au-ph+`; noise
  `au-rnd au-noise au-fnoise`; envelopes `au-ar au-adsr au-env-exp au-sweep`; filters and effects
  `au-svf! au-onepole! au-drive! au-delay! au-reverb!`; utilities `au-mix! au-scale! au-normalize!
  au-peak au-fold au-frac au-expf (= f-exp) au-powf au-rrange au-midi`; instruments `au-ping! au-partials!
  au-thump! au-taiko! au-gong! au-shaku! au-saws! au-whoosh`.

## Animation (`anim.lisp`)

A 21-joint humanoid rig (`+nj+`), poses and keyframe clips; GAMEPLAY.md "Rig & animation" has the
conventions. `*key-ease*` (0): 1 eases between non-`:snap` keys with an ease-out cubic (poses snap into a
key and settle; SOUL DUEL) instead of smoothstep.
* `(ji :hand-r)` → joint index at compile time; `(joint-index name)`, `(joint-mask &rest names)`
  (bitmask). A pose is an f32vec of `+pose-n+` (68) floats; `+root+` is the root's offset in it.
* `(defpose name (&key base) specs…)`, `(defclip name (dur &key loop base fps marks) keys…)`,
  `(find-pose name)`, `(find-clip name &optional (errorp t))` (NIL for an unknown name when ERRORP
  is NIL), `(list-clips)` → every clip name, sorted; `clip` accessors `clip-name clip-dur
  clip-loop`; `(clip-sample! out clip time)`; `(build-clip name dur loop base keys &key fps marks)`
  is DEFCLIP as a function (clips generated from data).
* Frame-timed clips: with `:fps 60`, DUR, key times and MARKS are frame numbers (converted as
  `frame / 60.0`, exactly like a hand-written `(/ 7 60.0)`). `:marks` is a plist of named times;
  a key's time may be a mark name or `:end` (= DUR), and `(clip-mark clip-or-name name)` → the
  mark in seconds (`:end` → the duration, unknown → NIL). An attack whose hit pose lands at frame
  S, holds to S+A and is back in stance at S+A+R:
  ```lisp
  (defclip :my-q1 (22 :fps 60 :base :my-stance :marks (:s 7 :a 10))   ; S A R = 7 3 12
    (4 (:arm-r :flex 120))                  ; wind-up at frame 4
    (:s :snap (:arm-r :flex -30))           ; hit pose at S
    (:a (:arm-r :flex -40))                 ; follow-through held until S+A
    (:end :my-stance))                      ; back at S+A+R
  ```
* `(defstrike name (s a r &key (base :stance)) keys…)` — the attack-clip form of that: DEFCLIP
  `:fps 60` with DUR = S+A+R and marks `:s` = S, `:a` = S+A, so an attack clip is written in its
  move's frame data (`(:s :snap …) (:a …) (:end :my-stance)`; SOUL DUEL's attack art).
* Playback: `(make-anim)`, `(anim-play an clip &key blend speed time restart)` (BLEND in 60 Hz
  frames), `(anim-advance an dt)`, `(anim-eval an)` → fills `(anim-pose an)`; accessors `anim-clip
  anim-time anim-speed anim-blend anim-pose`. `anim-blend` = seconds of crossfade left:
  `(setf (anim-blend an) 0.0)` cuts a running crossfade (a freeze-frame / viewer shows the clip's
  own pose); with `(setf (anim-speed an) 0.0)` the clip is frozen.
* FK: `(pose-fk! jm pose px py pz yaw scale hunch &optional props)` writes one world mat4 per joint
  into JM (`+nj+` × 16 floats); `(joint-point! out jm j lx ly lz)` → a point in joint J's frame.
  `(%euler! m o px py pz yaw pitch roll s)` (macro) writes T(p)·Ry·Rx·Rz·S(s) into M at offset O inline (no
  calls; SOUL DUEL's stage chips use it).
  PROPS: NIL (the standard rig; same code and cost as before) or
  `(make-rig-proportions &key (shoulders 1) (arms 1) (legs 1) (spine 1))` — per-chain multipliers:
  shoulder width, upper arm + forearm length, thigh + shin length (the pelvis rises or sinks with
  the legs so the feet stay on the ground), pelvis-to-neck length. `scale` still applies on top.
  Only joint positions move: body parts are rigid in their joint's frame, so longer bones need
  longer part meshes. Make one proportions vector per body at load time (it allocates):
  ```lisp
  (defvar *ken-props* (make-rig-proportions :shoulders 1.25 :arms 1.05))   ; arms clear the haori
  (pose-fk! joints pose x y z yaw 1.12 0.0 *ken-props*)
  ```

## Bodies (`body.lisp`): rigid-part characters

A character's look is data: shapes per rig joint, built once into one mesh per joint (plus
separate glowing / tagged parts) and drawn with the joint matrices POSE-FK! fills. Both games keep
their own body struct (RAVEN: stats, katana / raven blade, scarf; DUEL: rig proportions, DEFWEAPON
weapons) and build / draw through these:
* The spec: `((joint shape …) …)`, shapes in the joint frame (unscaled rig metres, the bone hangs
  along −up): `(:box w h d)` `(:bevel w h d bevel)` `(:cyl r h)` `(:cone r h)` `(:sphere r)`
  `(:wedge w h d)`; options `:at (right up fwd)` m, `:rot (yaw pitch roll)` deg, `:c` palette key or
  #xRRGGBB, `:seg n`, `:top r` (cylinder top), `:stretch m` (sphere → capsule), `:squash (sx sy sz)` (the
  placed shape scaled in the joint frame, `:at` included: an ellipsoid head, and parts placed on it with the same
  squash stay on it), `:tag key` (its own mesh, hideable); `(:glow e shape [tag])` an emissive part drawn in its own colour.
* `(build-parts spec palette width &key ink)` → values PARTS (simple-vector: a mesh or NIL per joint),
  EXTRAS (list of `#(joint mesh tint emissive tag)`: glows, tint = their colour; tagged solid parts,
  tint NIL) and HULLS (list of `#(joint mesh tag)`, the ink outlines; NIL without INK). WIDTH scales
  the girth (x and z). INK (NIL = no hulls, RAVEN) = `((key . #xRRGGBB) … (t . #xRRGGBB))`, the ink
  colour of a shape by its `:c` key, T for the rest; each solid shape's hull is built from its own
  vertex range (`mb-hull`), K = the shape's `:ink k` option or by size (its middle extent: 0 = no hull
  under 4 cm, e.g. strokes and eye shapes; 0.6 under 10 cm; else 1); glows get none. At load time
  (needs the GPU device; the hulls allocate a few MB of scratch, so give each body its own `:load` step).
* `*part-jitter*` (0.06): per-face random brightness of the built parts; `*part-smooth*` (NIL): T gives
  `:sphere` and `:cyl` shapes smooth normals. Read at build time; a toon game sets 0 and T (SOUL DUEL's
  body.lisp), RAVEN keeps the defaults.
* `(draw-parts parts extras joints &key (hidden 0) hide recolor tint rim (emissive 0) (flash 0) (alpha 1) toon
  hulls ink-tint (ink-px 1.8) (ink-push 0.012))`
  — HIDDEN a joint bitmask (`joint-mask`), HIDE a tag or list of tags, RECOLOR `(tag . rgb)` draws
  that tag's glows in RGB (RAVEN's red visor in Raven Form); TINT / RIM / EMISSIVE / FLASH / ALPHA
  as DRAW-MESH, for the solid parts (glows keep their colour; ALPHA applies); TOON: DRAW-MESH's toon
  lanes for every part. HULLS (BUILD-PARTS' third value) are queued after all solids (2 pipeline
  switches) when TOON is set and ALPHA is 1: INK-PX pixels wide at 720 lines, tinted INK-TINT, pushed
  INK-PUSH m behind (no line on the seams of abutting parts, thin or none where parts nearly touch).
  0 bytes per call.
* `(pal-rgb c palette)` → rgb list of a palette key `((key #xRRGGBB) …)`, a #xRRGGBB or a list.

## Time (`time.lisp`)

Fixed steps for a game that wants frame-exact gameplay (both games do; hello doesn't).
* `+step+` = 1/60 s. `*tick*` counts steps (also during hitstop).
* `(time-step)` — call once per fixed step; NIL means "hitstop: skip the simulation this step".
* `(hitstop frames)` — freeze the sim for FRAMES steps; concurrent requests take the max
  (scaled by `*hitstop-mult*`); `*hitstop*` = frames left.
* `(slowmo scale secs &optional others-only)` — time-scale the sim (or only "the others") for SECS
  real seconds; the lowest scale wins. `(slowmo-scale others)` → current scale for the main side
  (NIL) or the others (T); advance your frame counters by it.
* `(time-reset)` — cancel hitstop and every slow-mo (new round / scene); `*tick*` keeps counting.
* `(run-fixed-steps rdt step &key (max-steps 6) while)` — the frame's fixed steps: adds RDT to
  `*step-acc*` and calls STEP (a function of no arguments) once per whole `+step+`, at most
  MAX-STEPS per frame (a longer backlog is dropped); WHILE (NIL or a function) is asked before each
  step and stops early on NIL. Returns the steps run. Set `*step-acc*` to 0.0 while the sim pauses.
  Both games: `(run-fixed-steps rdt #'sim-step)`, `(run-fixed-steps rdt #'sim-step :while #'sim-running-p)`.

## Cinematics (`cine.lisp`, tested by `tests/cine-test.lisp`)

Scripted cutscenes (a super move, a K.O., an intro) that run inside the fixed step, so a seeded
replay includes them. Used by SOUL DUEL (duel/lisp/cinema.lisp: hooks, shot helpers, scripts).
* `(defcine name (a v &key (len 60) (hold 30)) body…)` defines script NAME for actors A and V.
  The body runs in step mode (once per fixed step, deterministic) and draw mode (once per rendered
  frame, cosmetic); inside it `cf` is the cine frame, `step-p` the mode, `(at frame forms…)` runs in
  step mode on that frame, `(during (from to [u]) forms…)` in draw mode while from ≤ cf < to with U
  0..1 (these names are taken from the script's own package).
* `(start-cine name a v &key after)` (cancels hitstop / slow-mo, runs frame 0), `(cine-step)` — the
  game's fixed step calls it instead of its sim while `*cine*` is set; it ends after LEN frames and
  runs AFTER. `(cine-draw)` per rendered frame. `(skip-cine)` (ends on the next step, AFTER runs),
  `(abort-cine)` (AFTER dropped), `(end-cine)`.
* Shots: `(cine-cam ex ey ez tx ty tz)` sets `*cine-cam*` and `*cine-eye*` / `*cine-target*`; the
  game's camera uses them while `*cine-cam*` (a shot set in an AT is a cut). `*grade-desat*` and
  `*grade-split*` are reset when a script ends.
* Game hooks: `*cine-begin-hook*` (name a v) when one starts (actors leave their sim states),
  `*cine-actor-hook*` (actor) each step (advance its animation), `*cine-end-hook*` (cine or NIL)
  when one ends, before AFTER (restore the look, give the actors back).
* Debug: `*skip-cines*` (every cinematic ends at once), `*cine-hold*` (stop at the script's HOLD
  frame; `(cine-hold-frame name)`, `(setf (cine-hold *cine*) …)`); accessors `cine-name cine-cf cine-a cine-v`.

## FX (`fx.lisp`)

Real-time or sim-time effects that live in flat float pools (no entities, no consing).
* **Shake:** `(shake amp dur)` (metres, seconds; max wins, × `*shake-mult*`), `(shake-update dt)`
  once per frame writes `camera-shake`.
* **Particles** (2000-slot pool): `(fx-emit type x y z vx vy vz life size grav r g b &optional (alpha 1))`
  — ALPHA multiplies the kind's own alpha (for additive kinds: brightness); a direct call compiles
  in place (compiler macro), so unboxed float arguments cost 0 bytes (a call through `#'fx-emit`
  boxes them, ~16 B each);
  `(fx-burst type n x y z dx dy dz spread smin smax life size r g b)` (all floats except N),
  `(fx-update dt)` and `(fx-draw-particles)` once per frame, `*plive*` = live count. Types:
  `+p-mist+ +p-dust+` (soft alpha puffs), `+p-spark+` (stretched additive streak), `+p-glow+`,
  `+p-feather+`, `+p-orb-a+ +p-orb-b+` (home to `*orb-target*` after 0.4 s and call
  `*on-orb-absorbed*` with `:a` / `:b`); `(fx-clear-orbs)`.
  `+p-flame+`: additive, mild drag, shrinks to 30 % over its life; color runs from the emit color
  (give the hot core, e.g. `1 0.9 0.55`) to orange by 20 % of its life and to dark red by 55 %, with
  the white center only in the first 10 %. It rises with a negative GRAV (`fx-burst` passes −2).
  Flame column (tests/engine-check.lisp): per frame `(fx-emit +p-flame+ x 0.15 z vx (rnd-range 1.0 1.8)
  vz (rnd-range 0.6 1.0) (rnd-range 0.16 0.26) -3.0 1.0 0.9 0.55)` at ~55 particles/s, jittered
  ±0.15 m. Additive fire reads best on a dark, warm background; over a bright sky pass ALPHA
  ~0.3–0.5 (the 13th argument) so the columns do not saturate to white.
* `(fx-clear)` — remove every particle, ring and debris piece and stop the shake (new round / scene).
* **Rings:** `(fx-ring x y z r0 r1 dur r g b &key flat width)` (camera-facing, or FLAT on the
  ground), `(fx-rings-update dt)` once per frame advances and draws them.
* **Debris:** `(fx-debris mesh m mo vx vy vz spin)` throws a copy of MESH drawn with the matrix at
  M[MO..MO+15]; `(fx-debris-update dt)` (sim seconds) integrates and draws; `*debris-life*`;
  `(fx-clear-debris)`.
* **Trails:** `(make-trail)` → buffer of `+trail-n+` base/tip samples; `(trail-push tr bx by bz tx ty
  tz)`, `(trail-decay tr)`; `(trail-count tr)` → samples (a float, SETF-able: 0 drops the trail);
  draw with `(fx-trail tr (f->i (trail-count tr)) r g b a)`. The 0 B macro forms (a DEFUN-FAST call boxes
  its six floats): `(%trail-push tr bx by bz tx ty tz)`, `(%trail-drop tr n)` (drop the oldest of N samples);
  samples move with an explicit forward copy (REPLACE of a vector onto itself allocates).
* **Smear** (the drawn sword smear, SOUL DUEL): `(fx-smear-capture! tr sm n dr u (len width) k)` (macro, 0 B)
  — when the drawing number DR differs from SM's [10], re-capture SM (12 floats: x0 y0 z0 x1 y1 z1 bx by bz,
  half-width, drawing, presence) from trail TR's last ≤ 5 of its N samples: a quadratic Bézier through their
  point U (0 base … 1 tip), half-width WIDTH (which may use the variable LEN, bound to the newest sample's
  length), presence K (0 with fewer than 3 samples). The caller draws it, e.g.
  `(when (> (aref sm 11) 0f0) (fx-crescent (aref sm 0) … (aref sm 9) :comet … (aref sm 11)))`.
* **Ribbons, sectors** (`fx-ribbon`, `fx-sector`) and **debug outlines** (`draw-circle`, `draw-vol`):
  see the FX batch table and "Hit volumes".
* `(edge-vignette r g b a frac)` — UI-space darkening toward the screen edges.
* `*shake-hz*` (30.0): how often the shake offsets change; SOUL DUEL 12 (a drawn, stepped shake).

### Toon effects (docs/style/STYLE_STORM_DESIGN.md §3; SOUL DUEL)
Hard, inked shapes in one of 12 palettes (`+pal-fire+ +pal-ember+ +pal-reiatsu+ +pal-ink+ +pal-steel+
+pal-hit+ +pal-smoke+ +pal-dust+ +pal-ash+ +pal-soul+ +pal-blood+ +pal-black-smoke+`; core / body /
shade / edge tones, the edge taking the value opposite to the body) in the `:toon` batch, drawn with
depth write and alpha-to-coverage. A toon vertex's colour lanes: HEAT (ribbons: base 1 → tip 0.2),
SEED (0..999; negative = an "along" shape whose tip erodes first; +1000 = the charcoal style), WOBBLE
(0..0.5 silhouette boil), and `(toon-a pal k &optional fan)` = palette + presence K (0.98 whole … 0.01
gone: matter perforates, energy erodes). Existing calls take `:mode :toon` (`fx-ribbon`, `fx-sector`,
`fx-line`, `fx-billboard` — pushed 0.8 × size toward the eye); `fx-ring` takes `:palette`.
* **Fx clock:** `(fx-clock-advance dt)` once per frame with the effects' dt (0 while paused);
  `(fx-clock)` = its seconds (`*fx-clock*`); the shader steps on it (fire / energy on twos, matter on
  threes). `(sage age rate)` quantises an age to the same drawings (RATE 1 / 2 / 3 ticks).
* **Envelope:** `(fx-envelope (scale k flash phase) (age flash grow hold out :anticipate a) body…)`
  binds a one-shot's drawn scale / presence / flash / phase (0 anticipation … 5 done) for AGE seconds,
  the counts in 60 Hz frames.
* **Shapes** (macros; float forms; 0 B): `(fx-disc x y z r wobble seed pal k &key push)`;
  `(fx-star x y z r0 r1 n rot dirx diry wobble seed pal k &key (push 0.3))` — irregular hashed spikes,
  the one nearest the screen direction (DIRX DIRY) long, R0 ≥ R1 = a regular N-gon;
  `(fx-shard x y z dx dy dz len w wobble seed pal k &key push)` — a kite; `(fx-crescent x0 y0 z0 x1 y1 z1
  bx by bz w profile wobble seed pal k &key push)` — a Bézier strip, PROFILE `:lens` or `:comet`;
  `(fx-wall xs zs n height scallops wobble seed pal k)` — one continuous flame wall on a ground polyline
  (N points in the f32vecs XS / ZS): tallest in the middle, the top cut into SCALLOPS pointed tongues (heights
  hashed from SEED: vary the seed per drawing to re-draw them) over round valleys, tapering to the ground at
  both ends; an along shape (field = height fraction, heat 1 at the base → 0.2 at the top, so fire keeps its dark
  edge only low, on the ends and valleys), its uv.y = the distance along the wall (the noise's second axis).
  An along shape's field is |uv.x|; uv.y only moves the noise (0 for ribbons and crescents).
* **Toon particles:** `+p-t-blob+` (puff / flame / droplet, a pushed billboard) and `+p-t-shard+` (a kite
  along its velocity) — `(fx-emit +p-t-blob+ x y z vx vy vz life size grav wobble 0 0 pal)`; drawn
  stepped (positions per drawing; a newborn particle shows from the next drawing).
* **UI punctuation** (0 B, DRAWING = a drawing number that reshuffles them):
  `(ui-focus-lines cx cy n rmin rmax col drawing)`, `(ui-speed-lines dir n col drawing)`,
  `(ui-ink-splash cx cy r seed col drawing)` (a hashed blob, spikes and droplets, grows over drawing 0).
* **Toon kit** (macros, single-float forms, 0 B; SOUL DUEL's looks are written with them):
  - `(hash01 i seed)` → a stable 0..1 sine hash of (I SEED), `|v| mod 1` — the engine's internal `%h01` is the
    same hash folded as `v − floor v`: they differ for negative v, so never alias one to the other (the shapes
    built on each would change);
  - `(drawing-no [per-second 12])` → the fx clock's drawing number 0..63 (12 = twos, 8 = threes);
  - `(with-cam (rx ry rz ux uy uz) body…)` binds the six names the caller gives (all six, in this order) to
    the camera's right / up axes for camera-facing shapes — they are the caller's own symbols, nothing is
    exported for it; `(%away-from-eye (x y z) d body…)` rebinds X Y Z moved D m along the view ray
    (negative = toward the eye); `(%near-cam x z near far)` → 0 within NEAR m of the eye (ground plane) … 1 at
    FAR (tall columns shrink near the lens);
  - `(%t-blob x y z vx vy vz life size grav wob pal)`, `(%t-shard x y z vx vy vz life size grav pal)` — one
    toon particle (`fx-emit` of `+p-t-blob+` / `+p-t-shard+`);
  - `(%tring x y z r w pal k seed [segs 32])` — a flat toon ring at height y (+2 cm), radius R, band half-width
    W, its heat varying around it (it breaks into arcs as K fades);
  - `(%sector-verts mode segs x y z r0 r1 yaw half l0 l1 l2 l3)` — `fx-sector`'s shape, unboxed: MODE `:toon`
    takes heat seed wobble toon-a as L0..L3 (`fx-sector` itself calls it with r g b a);
  - `(toon-ribbon (x y z) (ax ay az) (w0 w1) &key (heat (1 0.2)) seed (wob 0.3) pal k k1 (ph 0) (sway 0) (segs 6))`
    — `fx-ribbon … :mode :toon` with its lanes named; with PAL the presence lanes are `(toon-a pal k)` /
    `(toon-a pal k1)` (K1 defaults to K), without PAL K / K1 are the lane values; the argument forms land in
    `fx-ribbon`'s positional order (a form repeated there is repeated here, as written by hand);
    `(%tongue x y z ax ay az w pal k seed ph sway &key (segs 6) (wob 0.3))` — a toon flame tongue (w1 = 0,
    SEED made negative: along) through it;
  - `(%light x y z r g b radius intensity priority)` — `add-point-light` without boxing (one shared record).

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
  first, and empties the queue. `(do-events (kind) clause…)` dispatches them, one CASE clause per kind:
  `(key lambda-list body…)` runs BODY with the event's data destructured by LAMBDA-LIST (a symbol gets the
  whole data list); `(t body…)` / `(otherwise body…)` run as written. It expands to
  `(dolist (ev (take-events)) (destructuring-bind (kind &rest data) ev (case kind …)))`:
  ```lisp
  (do-events (kind)
    (:hit (att def dmg) (show-hit def dmg))
    (:died (e) (sfx :death e))
    (t (error "unknown event ~s" kind)))      ; RAVEN keeps its ECASE this way
  ```
* `transform` — the one component every game shares: `pos` (f32vec3, feet / origin, metres, y up) and
  `yaw` (single-float, 0 faces −Z); `(pos-of e)` / `(yaw-of e)` (inline) read them. Both games build on it.

## App (`app.lisp`)

* `(run-game &key title load start frame debug stats)` — register the game, once, at load time.
  `:load` = list of functions, one startup step each (after `engine-init`, before audio); `:start`
  = called once when loading and sound synthesis are done; `:frame` = function of the real dt
  (seconds, ≤ 0.1), called every frame between `begin-frame` and `end-frame`; `:debug` = function
  of N for `Module._debug_cmd(N)` from the page; `:stats` = function returning a string appended
  to the stats line. Errors inside any of them stop the main loop and are shown on the page.
* `*stats-log*` T: log `stats: fps … cons/frame … B draws … tris … particles … | ms/frame sim … queue
  … render …[game :stats tail] | fx-dropped N` every 2 s. `(perf-mark)` called twice inside `:frame` splits "sim" from "queue".
  `(cons-per-frame)`, `(cons-bytes)` (since the last GC), `(now-ms)`.

## Package helpers (`package.lisp`)

* Types `f32` (= single-float; `(f32 x)` coerces) and `f32vec`; `(f32vec-p x)`; `clamp`, `lerp`;
  `(log-msg fmt args…)` prints a console line. `(with-floats (vars…) body…)` rebinds VARS as declared
  single-floats (callers may pass fixnums or doubles).
* `(defun-fast name args …)` — DEFUN for hot numeric code: checks declared argument types on entry,
  runs the body at `(safety 0)` (see ARCHITECTURE.md Gotchas). Declare every float local.
* Float macros compiled to plain C (no boxing): `f-min f-max f-abs f-sqrt f-sin f-cos f-atan2 f-mod
  f-exp f-clamp f-wrap` (angle into [−π, π)), `i->f`, `f->i` (floor); `(f-hypot a b [c])` → exactly
  `(f-sqrt (+ (* a a) (* b b) [(* c c)]))` (forms other than symbols / literals bound once, declared
  single-float), the `f-sqrt` twin of `hypot` (Math).
* Random numbers (C xorshift, no consing), two independent streams:
  - cosmetic: `(rnd01)` in [0, 1), `(rnd-range a b)`; `(rnd-seed n)`, `(rnd-state)`;
  - simulation: `(sim-rnd01)`, `(sim-rnd-range a b)`; `(sim-rnd-seed n)`, `(sim-rnd-state)`.
  Rule: gameplay / AI draws use `sim-rnd01` and only inside fixed steps, so the same seed replays
  the same match at any frame rate; fx, shake and sound use `rnd01` (it runs per frame / per
  particle). A seed is any fixnum (hashed in C, so 1, 2, 3 start far apart). The state is the raw
  generator word, an integer 1..2^32−1 (a bignum above 2^29: read it for save/restore or
  determinism checks, not per frame); `(setf (sim-rnd-state) s)` / `(setf (rnd-state) s)` restore it.

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
