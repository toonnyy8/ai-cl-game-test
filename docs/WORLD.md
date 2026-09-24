# RAVEN EDGE — World (arena, skyline, rain, collision)

Source: `game/lisp/world.lisp` (C: `game/c/world.c`). Demo and tests: `tests/world-demo.lisp`. Design: GAME_DESIGN §6.2, §7.6, §9.

```
./build.sh world-demo game/lisp/package.lisp game/lisp/world.lisp game/c/world.c tests/world-demo.lisp
node tools/run.mjs dist/world-demo --secs 8 --shot out.png      # logs "collision self-test: ALL PASS"
```
Demo keys: arrows = orbit, WASD = move the pivot, Q/E or the mouse wheel = zoom, R/F = pivot up/down,
T = next view (1–7 jump to a view), B = bloom, H = haze, N = rain off/on, M = boss rain (×1.5, crimson).
Screenshots: `docs/world-shots/*.png`.

## API

| call | semantics |
|---|---|
| `(world-init)` | (= `world-init-1` + `world-init-2`, separate startup steps in the game.) Builds all meshes and sets `*env*` (§9 look). Call once after `engine-init` (the game registers `world-init-1` and `world-init-2` as `RUN-GAME` `:load` steps); meshgen temporaries are collected by the GC that follows each startup step. |
| `(world-update dt)` | Fans (3 rev/s) and the cyan sign flicker (§6.2: a 5 % chance every 0.1 s to dim to 50 %). DT is **gameplay** time, so slow-mo slows the fans. Any real number is accepted. |
| `(world-draw)` | Queues 11 scenery draws, 8 point lights, and the rain / splash / reflection / sky fx. Call once per frame **after the camera is set**. Rain, blinkers and sky traffic run on **real** time (`elapsed-time` / `frame-dt`), so they keep going during pause and hitstop. |
| `(arena-resolve pos radius)` | Mutates vec3 POS (x, z) and returns T if it moved. It pushes a circle out of the prop colliders (boxes and cylinders below) and clamps it to the walls at ±`*arena-half*`, in 3 passes with the clamp inside each pass, so props against the wall push inward. RADIUS must be a single-float. |
| `(arena-ground-height x z)` | → `0.0` |
| `*arena-half*` | `17.6` (single-float). |
| **added** `(arena-raycast x0 y0 z0 x1 y1 z1)` | Tests the segment against the prop volumes (with their heights) and the floor y = 0. Returns the hit fraction 0..1 (1.0 = clear). A segment that starts inside a cylinder ignores it. Camera use: `dist := min(dist, t*len - 0.3)`. |
| **added** `*rain-count*` | Default 1500 streaks. Boss phase 2: `(setf *rain-count* 2250)`. |
| **added** `*rain-color*` | f32vec r g b a, default #9FB4D0 at 35 %. Boss phase 2: `(setf (aref *rain-color* 0) 0.816 (aref *rain-color* 1) 0.439 (aref *rain-color* 2) 0.502)`. |
| **added** `*world-haze*` | T. The horizon haze sprites are big additive quads; set NIL if fill rate hurts. |

### Colliders (`+w-colliders+`)
| prop | shape |
|---|---|
| AC A (−11, −9), AC B (−7.5, −9) | box half 1.2 × 0.8, h 1.75 |
| AC C (11, 6), AC D (11, 9.5) | box half 0.8 × 1.2, h 1.75 |
| water tank (−12, 12) | cylinder r 1.8, h 5 |
| stair housing (12, −12) | box half 2.0 × 1.75, h 3.3 |
| antenna mast (15, 15) | cylinder r 0.3, h 9.3 |
| **extra:** pipe rack along the west parapet (−17.35, 0) | box half 0.3 × 8.2, h 1.1 |

Everything else is either flat and walkable (paint, puddles, cables, hatch plates, drains) or outside the ±17.6 walls (railings, lamp poles on the parapet caps, guy wires, signs, skyline). The self-test in the demo checks every prop at r 0.35 and 0.75 from 3 start points, plus a face graze, the wall clamp, free space, the 1.1 m gap between AC A and B (the player fits) and 5 raycasts.

## What's in the scene

* **Roof mesh** (1 lit draw, ~6.3k tris). It holds the 2 m concrete slabs (#3A3F4A with slab and low-frequency variation, darker tar cells, seams), the parapets with caps and a wet stain along the base, and railings on the S and W caps. It also has the facade and cornice below the roof, 4 AC units (skids, grilles, copper lines, fan shrouds), the water tank (braced legs, bands, ladder, lamp housing), and the stair housing (door, step, lamp, louvre, conduit, exhaust stacks, dish, mast). The antenna mast has cross-arms, panels, a dish and guy wires. Also: the billboard truss with catwalk, railing and floodlights, the E sign brackets, 3 lamp poles (SE amber, S warm, NW cool), the west pipe rack, floor cables, the helipad ring with a worn H, and 8 puddle blobs (#2A3350).
* **Neon** (1 draw, emissive 3). The billboard N has a magenta frame, 2 pseudo-kanji, the pixel-font brand "KUROSAME", and glyph bars with a cyan accent. Also: lamp bulbs, floodlight lenses and red corner markers.
* **Cyan sign E** (1 draw, emissive 3 × flicker): 5 procedural pseudo-kanji. **Beacon** (1 draw, blinks at 1 Hz). **Fans** (4 draws).
* **City** (1 lit draw + 1 emissive windows draw, ~10.4k tris). The §6.2 ring has 70 boxes (seed 1337, 45–180 m) with setbacks and antennas, 3 facade window styles (grid, bands, LED strips; warm 40 % / cyan 30 % / pink 30 %) and neon crowns. The 2 landmark towers (+110 m) have spires and red blinkers. A far silhouette layer (48 boxes, 220–320 m) sits in the fog, and 8 lower neighbor roofs (−4…−16 m) with AC boxes form the mid-ground.
* **Fx, written directly into the engine fx stream buffers by C** (`w_*` in `game/c/world.c`):
  * Rain: 1 tapered triangle per streak in a 30×20×30 m box that follows the eye, wind (1.5, 0, 0.5), 18 m/s, 0.5 m long. Streaks fade near the eye and at the box edge.
  * Splash ripple rings: 40/s within 15 m of the camera target, 40 % of them on puddles.
  * Wet-floor neon reflections: mirror-projected soft quads of the billboard and sign, plus per-emitter streaks for the lamps and beacon, stronger on puddles and at grazing angles.
  * Blinkers, sky-traffic lanes (headlight and taillight streams), 2 airliners, 2 police drones with searchlight beams, and horizon haze.

### Look (`world-env`, §9)
Sky #070A14. Fog #231F3A: density 0.012 with height falloff, so the city below drowns and tall towers stay visible. Moon (0.4, 1, 0.3) #7F93C9 × 0.45. Ambient #2A3660 / #14121C × 0.55. Rim #9FB4D0 × 0.22 at power 4.5 (silhouettes only, not the floor). Specular 0.6, shininess 60, exposure 1.25, bloom threshold 0.6, bloom strength 0.95, vignette 0.4.

### Lights (8, added every frame in `w-lights`)
| light | position | radius / intensity |
|---|---|---|
| magenta billboard | (0, 5, −20.6), *behind* the board | r 21, i 0.95 |
| cyan sign | (20.3, 5.5, 0), behind the sign | r 15, i 1.1 × flicker |
| amber tank lamp (SW) | (−12, 3, 9.9) | r 9, i 0.9 |
| amber stair door (NE) | (12.6, 2.6, −9.6) | r 7, i 0.8 |
| amber pole (SE) | (16.6, 3.9, 12.5) | r 10, i 0.8 |
| cool work light (NW) | (−16.6, 3.9, −12.5) | r 9, i 0.55 |
| warm pole (S) | (0.5, 3.9, 16.6) | r 9, i 0.5; back rim for the player at spawn |
| red beacon | (15, 9.2, 15) | r 10, i 0 or 0.9 |

The two neon lights sit behind their boards on purpose. The wet specular isn't gated by N·L, so a light in front of a flat dark board painted a glowing disc on it. The engine keeps the 8 candidates nearest the camera target (score = distance − radius), so short-radius hit lights from combat near the target still win slots.

## Performance (measured in the demo, 1280×720, SwiftShader)
* **Draws:** world = 11 (demo total 23 with 6 two-part stand-ins). **Tris:** world ≈ 18.8k (static 6.3k, city 2.6k, windows 7.8k, neon 2.1k).
* **Consing:** `world-update` + `world-draw` measured ≈ 1.2 KB/frame, ~1 KB of it boxed floats in the 8 light calls; that part is gone since the lights moved to `add-point-light-v` (0 B). All fx cons 0 B. The whole demo frame is ~18 KB, mostly the HUD's `format`.
* **Fx vertices:** rain 3 per streak (1500 → 4500 of the 16384 alpha batch; 2250 → 6750). Splashes ≤ 1440 alpha. The add batch gets ~1.5k. `*fx-dropped*` stays 0.
* **FPS in SwiftShader:** ~9. The 8-light per-pixel loop is the cost: with world lights off it runs 18 fps. Haze and rain make no measurable difference. Real GPUs are unaffected.

## Gotchas found here
* `ffi:c-inline` reads one base-36 digit after `#`: arguments 11+ are `#a`, `#b`, …; `#10` is argument 1 followed by `0`.
* World fx write straight into `*fx-alpha*` / `*fx-add*` (`stream-buffer-data`/`fill`), using the fx vertex layout **pos3 uv2 rgba4** (9 floats). If render.lisp changes that layout, update `W_V` in game/c/world.c.
* The flat-quad reflections and decals sit at y 0.03, and puddles and paint at 0.004–0.007 over the floor at 0. That is safe for 24-bit depth out to ~60 m.

## Polish pass
* The roof is two meshes now: `*w-floor*` (slabs, paint, puddles) drawn with `:specular 0.75` and
  `*w-static*` (walls, props) with `:specular 0.2`; city / emissive draws use `:specular 0` (skips the
  math). World lights are one f32vec `*w-lightv*` fed to `add-point-light-v` (0 B consed).

## Engine request (done)
**Allocation-free meshgen path.** `world-init` used to cons ~50 MB once, from `%mb-tri`/`outward-p` allocating per triangle, which raised the peak wasm heap. Both are `defun-fast` now and startup is split into GC-separated steps (engine/lisp/app.lisp).
