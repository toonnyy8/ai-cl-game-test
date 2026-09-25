# SOUL DUEL: "Storm × Kubo" Restyle Design (v4)

> **設計摘要（繁體中文）**
>
> **v4 美術方向**：用《究極風暴》的技術（卡通著色、墨線、手繪式特效、衝擊格、奧義鏡頭語言），畫出久保帶人的視覺語言：
> - 大塊的黑對上純白（notan）；
> - 大量留白；
> - 背景極簡；
> - 冷、暗、絕望的底色；
> - 顏色只當作「點色」，少量使用。
>
> 這是依使用者的決定修改的（見 §13 第 4 輪）。
>
> **主要決定**
> 1. **舞台**：瀞靈廷廢墟，無風的深夜，灰燼像雪一樣落下。
>    - 天空是冷黑，後方有一輪巨大的白月。
>    - 廢墟是純黑剪影；廣場是月光照白的石地，只畫幾道墨線裂縫。
>    - 遠方燃燒的建築拿掉，暖色只留給特效。
>    - 選深夜而不選暴風雨，是因為 notan 最乾淨、畫面最不雜，灰燼又和山本燒盡一切的故事呼應。
> 2. **明度系統**：全畫面 5 階明度（V0 黑～V4 白）。
>    - 世界的彩度 ≤ 0.12。
>    - 地面在視線下方占大半畫面，是「白紙」：黑衣在白地上跳出來。
>    - 天空與廢墟是黑：白羽織在黑上跳出來。
> 3. **點色規則**：全遊戲只有三個點色，一般對戰時暖色像素 ≤ 畫面 15%。
>    - 山本的火（橘紅）；
>    - 劍八的靈壓黃，只在覺醒（野晒）與大招時出現，平常的靈壓畫成黑墨火焰加白邊；
>    - 血紅，只給鬼魂（Kikon）、反擊、Breaker、魂之焰。
>
>    其餘特效（命中、防禦、Burst、魂魄、步法）一律黑白，最多帶一點冷鋼藍。
> 4. **卍解・殘火太刀**：整個世界去色成黑白，只剩刀上一道餘燼紅線；刀身與熱氣畫成水墨／炭筆質感。依據是 TYBW 動畫總監督的訪談 [V]。
> 5. **角色**：
>    - 黑死霸裝畫成純黑色塊，用白色筆觸畫出衣褶高光（久保式的「黑上白線」）；
>    - 白羽織是 V4 白，陰影是冷灰藍；
>    - 劍八的頭髮改回純黑，加白色高光筆觸；
>    - 黑色部位的外框線改用冷灰，在白地上當深色邊、在黑天上當分隔線。
> 6. **衝擊格與反轉**：
>    - 全畫面黑白負片；
>    - 新增「漫畫頁」模式：畫面變成黑白兩色，但高彩度的點色（火、血、黃）保留。這就是 TYBW 的黑白加紅色點綴。
> 7. **奧義鏡頭**：
>    - 背景卡改成純黑或純白；
>    - 加墨汁飛濺；
>    - 靜音段落（TYBW 在山本的火焰段落只留骨頭的聲音 [V]）；
>    - 招式名是直排毛筆大字，可以出血到畫面外，旁邊配小字讀音。
> 8. v3 的技術決定全部保留：`fs_toon`／墨線外殼／`fx-toon`／特效時鐘／測試護欄。
>
> **使用者已決定**：美術方向（久保 notan）、範圍（Phase 0–6 全做）、毛筆字型（Yuji Syuku，OFL，離線轉成向量資料並附授權聲明）、跳過參考截圖（各階段完成後由使用者看截圖審查）、鏡頭拉近 20%。
>
> **還需要使用者的**：各審查點的截圖審查（Phase 1a、3、4、6 結束時）。另外兩個預設可以推翻：舞台選深夜（不是暴風雨）、劍八平常的靈壓畫成黑墨（黃色留給覺醒）。

Companion to `STYLE_STORM_RESEARCH.md` (same folder; §11 covers Kubo Tite, the TYBW anime and
Rebirth of Souls). Source tags such as [V: S13] or [V: K3] refer to its tables; [I] = inferred.
Code references are `file:line` in this repository.

**Status.** v4. It follows four review rounds (§13):
- round 1: the internal review of v1;
- rounds 2 and 3: the art and engineering critiques of v2;
- round 4: **the user's decisions on v3**.

Nothing in this document has been implemented yet. v4 changes the **art direction** (§A, §2.5,
§3.3, §4, §5, §6). The engine architecture of v3 (§1–§3.2, §3.4–§3.5) stands unchanged.

---

## A. Art direction v4: Storm's techniques, drawn in Kubo's visual language

**One-sentence brief.** Storm's rendering and animation techniques (toon shading, ink hulls,
drawn stepped effects, impact frames, the cinematic camera) render a world in **Kubo Tite's
notan**:
- heavy spotted blacks against stark whites;
- generous negative space;
- abstracted, near-empty backgrounds;
- a cold, dark, despairing base tone;
- colour used only as rare **spot colour**.

### A.1 The value system (5 steps, used everywhere)

| Step | sRGB | Used for |
|---|---|---|
| V0 black | #08080C – #14151C | ruins, sky, black robes (lit and shadow), ink |
| V1 dark | #262833 – #3A3E4C | robe fold shade, ruin edges, grey keylines |
| V2 mid | #7A8090 | ground shadow, smoke shade |
| V3 light | #BCC1CC | ground lit (moonlit stone) |
| V4 white | #EEEEEA – #FFFFFF | haori lit, moon, effect cores, flashes, paper cards |

Rules:
- World saturation ≤ 0.12, with hue in the cold band 210–240° (grey-blue).
- Skin is the only warm non-spot colour, muted (S ≤ 0.3).
- **Notan interlock.** The gameplay camera looks down. The pale ground fills most of the frame
  below the horizon (at least 55 %), and the dark sky and ruins fill the rest. **Black robes read
  against the white ground; white haori and heads read against the black sky.** Each fighter is
  always half black-on-white and half white-on-black, which is Kubo's figure/ground (research
  §11). It also satisfies the art critic's trait 0 (figure/ground contrast) by *value* instead of
  hue.

### A.2 Spot colour: exactly three hues

| Spot | Hue | Owner | When |
|---|---|---|---|
| **FIRE** | red-orange 15–25° | Yamamoto | always in Shikai/Hellfire (it is his identity). In Bankai, **all fire vanishes** except a thin ember-red line |
| **REIATSU** | yellow 48–52° | Kenpachi | **only** when awakened (Nozarashi) and in his cinematics. His base-form reiatsu is drawn in **black ink with white edges** (manga reiatsu) |
| **BLOOD** | red 355° | universal | Kikon, counter hits, Breaker, the soul flame, the hanko, red accents on inversion frames |

Everything else is monochrome, with at most a desaturated **cold steel** tint (S ≤ 0.3, 210°):
hits, guard, clash, Burst, Hoho, Konpaku, smoke, dust, ash, UI flashes.

**Budget AC:** in gameplay stills, spot-colour pixels (S > 0.45) are ≤ 15 % of the frame, except
during the owner's big moves.

### A.3 What changes from v3, trait by trait

| v3 | v4 |
|---|---|
| blue hour (complementary hue) | notan value contrast; figure/ground carried by value, not hue |
| stage fires and warm light pools | removed; warm is reserved for effects |
| Kenpachi's hair lifted to #2A2A3A | solid black + **white highlight strokes** (Kubo's white-on-black) |
| inner strokes are ink | inner strokes take **the opposite value of their part**: white on black cloth, ink on white cloth and skin |
| hull ink near-black everywhere | near-black on light parts; **cold grey keyline #4A5062** on black parts (dark on the pale ground, a separation line on the black sky) |
| coloured background drop | **pure black or pure white card** (+ ink splash) |
| impact modes: negative, two-tone | + **"manga page"** (two-tone with spot colour kept) |
| REIATSU yellow always | ink reiatsu in base form; yellow when awakened |
| palette of 12 colours | 12 slots remapped to mono + 3 spots (§3.3) |

---

## 0. Decisions at a glance

| # | Decision | Why |
|---|---|---|
| D1 | **Kubo notan world**: Seireitei ruins at night, cold black sky with a huge white moon, black ruin silhouettes, a moonlit pale plaza with a few ink cracks, falling white ash. No burning buildings (§6) | the user's direction (§13 round 4). Night is chosen over a storm: storm rain adds grey noise and blurs notan, while still air with falling ash keeps the frame graphic. The ash ties to Yamamoto's burnt world. Kubo uses weather and sky for emotion [V2: K2] |
| D2 | **Toon characters through `fs_toon`** (separate entry and pipelines; `fs_main` byte-identical): 2 tones, HSV-designed cold shadows, the CC2 vertical gradient, no point lights or rim in gameplay | unchanged from v3 (measured +16 % RAVEN cost otherwise) |
| D3 | **Ink hull**, 1.8 px, facing taper; **cold grey keyline on black parts**; red-brown ink on skin | trait #1; notan separation on black-on-black |
| D4 | **`fx-toon` drawn shapes** with the v3 fixes; the palettes are remapped to **mono + 3 spot colours** (§3.3) | "drawn, not simulated" [V: S7], in Kubo's colour economy |
| D5 | **Impact frames**: negative, two-tone, and the new **manga-page mode** (two-tone that keeps the spot colour) and **spot-keep desaturation** (Bankai), all in `RP_COMP_FX` | the TYBW-style black/white inversions with red accents (the user's brief; [I] as a claim about the anime) |
| D6 | **Cinematics**: beat-0 freeze, **black or white cards** instead of the stage, ink splashes, silhouette shots, silence beats, cuts not orbits, holds | Kubo's negative space; TYBW's sound removal [V: K4] |
| D7 | **Brush typography** (Yuji Syuku, OFL, baked offline to vector glyphs with the licence notice): vertical kanji that may bleed off the frame, small readings, a red hanko only for Kikon | the user's approval; Kubo's attack-name look [I] |
| D8 | Motion stays smooth, with pose-to-pose ease, holds and squash smears; effects are stepped | unchanged |
| D9 | Harness first; standing gates G1–G3 after every phase | unchanged |
| D10 | **Scope: all phases 0–6** (the user); the cut line is kept only as an ordering aid | the user's decision |

---

## 1. Constraints (read from the code; each one shaped a decision)

- **Frame graph** (`engine/c/render.c` `r_frame`): copy, then scene (MSAA 4× RGBA8 + D32: sky,
  opaque, transparent, fx alpha, fx add), then bloom (1/2, 1/4), then composite plus UI to the
  swapchain.
  - The scene target stores tonemapped sRGB, and fx vertex colours are written as sRGB.
  - Depth store is `DONT_CARE`, so depth cannot be sampled.
- **Shared engine = RAVEN EDGE risk.** RAVEN uses the same `lit.frag`, `build-parts`
  (game/lisp/bodies.lisp:55) and `draw-parts` (game/lisp/fighters.lisp:92). **Every new path is a
  separate entry point, pipeline or keyword, defaulting off.**
- **SwiftShader runs both sides of any divergent branch, even a flat per-draw one.**

  Measured by the tech critic: 1280×720, MSAA 4×, 120 boxes, 8 lights, median ms per frame.

  | Config | ms |
  |---|---|
  | today's `fs_main`, 8 per-pixel lights | 33.1 |
  | today's `fs_main`, 0 per-pixel lights | 15.3 |
  | toon branch inside `fs_main`, legacy draw | 38.4 (**+16 %**) |
  | toon draw, 0 per-pixel lights | 21.2 |
  | + hull | +0.7 ms |
  | + always-on CA | +3 ms |

  The speed-up comes from the per-pixel light count, not from toon shading.
- **Pipeline slots**: `ui.lisp:51` hard-codes `RP_UI` = 10. New pipelines are *appended*: 11
  `RP_TOON`, 12 `RP_TOON_CW`, 13 `RP_HULL`, 14 `RP_HULL_CW`, 15 `RP_FXT`, 16 `RP_SKY_TOON`,
  17 `RP_COMP_FX`.
- **FFI**: `r_frame` grows past 10 arguments, and `c-inline` then needs `#a`, `#b` and so on.
- **Per-draw and per-frame data**: `struct Draw` 28→32 floats (`R_DQ`, `+dq-stride+`; RAVEN
  writes 0 in lanes 28–31). `struct Frame` 136→**160** floats (`R_FU`, `+fu-floats+`).
- **Mesh vertex** = 9 floats, flat normals. `%mb-tri` knows only face normals
  (meshgen.lisp:66-95). Weapons are one `:solid` section each, and `mb-blade` emits blade and hilt
  together (yama-art.lisp:82-85, ken-art.lisp:88-94).
- **Poses are cosmetic.** Only draw code reads joints (main.lisp:66-78, hazards.lisp:154), and
  `sim-rnd01` is used only in ai, flow and debug. Visual holds, smears and stepping cannot change
  gameplay. The CvC hash gate proves it after every phase.
- **Cinematics**: `:len` is step-mode and replay-relevant, so it stays unchanged. `:hold` is only
  the debug screenshot frame (cine.lisp:60-63). **Never call `hitstop` inside a cinematic.**
- **Time**: `elapsed-time` is real time and keeps running while paused (platform.lisp:34), but
  `fx-update` gets dt 0 while paused (main.lisp:113). All stepping uses one **fx clock** that
  advances by effect dt.
- **Heap**: SOUL DUEL is at 103 MB against a 110 MB budget (DEVLOG §14.4). Load-time allocation
  goes in its own `:load` steps.
- **ECL**: new hot paths use `defun-fast`, macros, `with-fx-verts`, f32vec arguments and the
  `*ribbon-args*` pattern (0 B per call).

---

## 2. Character rendering

### 2.1 Data layout

`frame.wgsl` (+24 floats, 136 → 160):
```wgsl
  key: vec4f,   // xyz character key light (world, unit, toward the light); w band threshold (0.50; 1.5 = silhouette shot)
  toon: vec4f,  // x band half-softness (0.02)  y vertical-gradient strength (0.14)  z gradient height m (1.8)  w stage light gain (0.45)
  shd: vec4f,   // x shadow value x0.72  y shadow saturation x1.25  z hue shift deg (8)  w stage shadow lift (0.25)
  scr: vec4f,   // xy scene px  z proj[1][1]  w ink scale = scene_h / 720
  cin: vec4f,   // rgb hard back-rim colour (cinematics only; 0 = off)  w rim width (0.16)
  clk: vec4f,   // x fx clock in 24-Hz ticks (floor)  yzw spare
```
`lit-io.wgsl`: `struct Draw { model, tint, fx, rim, toon }` (32 floats). `toon.x` is the mode:
- 0 legacy (RAVEN, unchanged);
- 1 toon stage (world light `moon_dir`);
- 2 toon character (key light);
- 3 ink hull.

The other lanes by mode:
- mode 2: `toon.y` = feet height (for the gradient), `toon.z` = fog scale (0.2), `toon.w` unused;
- mode 1: `toon.z` = fog scale (1);
- mode 3: `toon.w` = ink width in px @720.

`rim.rgb` changes meaning in mode 2: it is the **shadow-side light tint** (see §2.2).

`fill-frame-uniforms` writes the new lanes. `scr` comes from the window size × `*render-scale*`,
not from `*rp*`, which is filled later. Under `env-toon`, u[71] (`spec.w`, per-pixel lights) is set
to **2**, which only stage draws use (see §2.2). The auto-quality ladder's two light steps
(render.lisp:386-390) therefore do nothing in toon mode, as documented.

The key light is set from **camera axes**, so a cut never flips the shading [V: S13: one light per
character, fixed in battle, animated in cutscenes]:
```lisp
;; *key-light* (right up back) = (-0.45 0.62 0.40) -> lit share of the visible hemisphere
;; = (1 + L·V)/2 ≈ 73 %, i.e. about 7:3 [V: S23]. Cinematics may set it per shot.
key = normalize(kr·camera-right + ku·camera-upv − kb·camera-forward)
```

### 2.2 `fs_toon` (new entry in `lit.frag.wgsl`; `fs_main` stays byte-identical)

Pipelines `RP_TOON` and `RP_TOON_CW` use the same `vs_main`. `r_draw_queue` (render.c:174)
dispatches on `q[28]`: 1 or 2 selects `RP_TOON + (det<0)`, and 3 selects `RP_HULL + (det<0)`.
Toon draws must have alpha = 1; bodies are never drawn transparent (§2.6).

```wgsl
fn hsv(c: vec3f) -> vec3f { /* standard rgb→hsv, h in [0,1) */ }
fn rgb(h: vec3f) -> vec3f { /* standard hsv→rgb */ }
fn shade_of(alb: vec3f) -> vec3f {                  // designed shadow colour (art §1.8)
  var h = hsv(alb);
  let warm = h.x < 0.19 || h.x > 0.83;             // reds, oranges, yellows, skin
  if (h.y < 0.12) { h.x = 0.61; h.y = max(h.y * F.shd.y, 0.10); }   // neutrals and whites -> cold blue-grey (v4)
  else { h.x = fract(h.x + select(F.shd.z, -F.shd.z, warm) / 360.0); h.y = min(h.y * F.shd.y, 1.0); }
  h.z = h.z * F.shd.x;
  return rgb(h);
}
@fragment fn fs_toon(i: LitV) -> @location(0) vec4f {
  let n = normalize(i.nrm); let v = normalize(F.cam.xyz - i.wpos);
  let alb = i.col * i.tint.rgb;
  let chr = i.toon.x > 1.5;
  let L = select(F.moon_dir.xyz, F.key.xyz, chr);
  let th = select(0.5, F.key.w, chr);
  let lit = smoothstep(th - F.toon.x, th + F.toon.x, dot(n, L) * 0.5 + 0.5);
  var sh = shade_of(alb);
  if (chr) { sh += alb * i.rim.rgb; }                       // nearest fx light warms the shadow side only
  else { sh = mix(sh, alb, F.shd.w); }                      // stage shadows lighter, so they recede
  var c = mix(sh, alb, lit);                                 // lit tone == palette colour
  if (chr) {
    c *= mix(1.0 - F.toon.y, 1.0, clamp((i.wpos.y - i.toon.y) / F.toon.z, 0.0, 1.0));   // CC2-style vertical gradient
    let fr = 1.0 - max(dot(n, v), 0.0);
    c += F.cin.rgb * step(1.0 - F.cin.w, fr);               // hard back-rim: cinematics only (cin = 0 in play)
  } else {                                                   // stage: 2 per-pixel lights (uniform count) + vertex rest
    var acc = Lit(i.dif, vec3f(0.0));
    for (var k = 0; k < i32(F.spec.w); k++) { point_light(k, i.wpos, n, v, 0.0, &acc); }
    let pi = dot(acc.dif, vec3f(0.2126, 0.7152, 0.0722));
    c += alb * (acc.dif / max(pi, 1e-3)) * floor(min(pi, 1.0) * 2.0 + 0.35) * 0.5 * F.toon.w;  // flat pools
  }
  c += alb * i.fx.x;                                         // emissive
  c = mix(c, F.fog.rgb, fog_amount(i.wpos) * i.toon.z);
  c = pow(clamp(c, vec3f(0.0), vec3f(1.0)), vec3f(1.0 / 2.2)); // no ACES, no exposure: palette-exact
  return vec4f(mix(c, vec3f(1.0), i.fx.y), 1.0);             // hit flash
}
```
- On the `if (chr)` branch: SwiftShader executes both sides. The stage side's loop has a uniform
  count of 2, so the waste is bounded (2 iterations, not 8). Character pixels are a small share
  of the frame.
- **Shadow-side tint.** `draw-fighter` picks the strongest fx light within 4 m from
  `*light-cand*` (a new 0-cons engine helper, `(nearest-light-rgb out x y z r)`). It passes
  rgb × intensity × 0.35 as `:rim`, so a fireball warms Kenpachi's shadow side without breaking
  the palette-exact lit tone.
- Worked shadows:
  - skin #E0A884 gives about #C8705A (redder, more saturated);
  - v4 white #F0F0EC gives cold grey-blue #9CA3B4;
  - REIATSU yellow #FFD83A gives about #C79A2A.

  AC: skin-shadow saturation ≥ lit saturation.
- `fs_sky_toon` (`RP_SKY_TOON`, chosen in `r_frame` by `rp[10]`): the same gradient and sun disc
  as today, without ACES, and with a flat sun disc (no bloom halo). It replaces v2's `fogh.w` flag.

### 2.3 Geometry: jitter off, analytic smooth normals

- `*part-jitter*` (engine body.lisp:67,69) defaults to **0.06**, so RAVEN is unchanged. SOUL DUEL
  sets 0. The duel weapons' fixed 0.04 (duel body.lisp:101) reads the same variable.
- `%mb-tri-n` in meshgen emits per-vertex normals and is used only under `:smooth t`.
  `build-shape` passes `:smooth t` for `:sphere` and `:cyl`. The normals are transformed by the
  builder xform, which is rigid (body.lisp:25-29):
  - sphere: `p − c`;
  - capsule: `p − (0, clamp(y, −hs, hs), 0)`;
  - cylinder side: radial, with a slope term `(x, (r0 − r1)/h · r, z)` for tapered `:top`;
  - caps stay flat.

### 2.4 Ink hull

**Why a hull.** Option B (post-process depth/normal edges [V: S17]) needs a sampleable depth
buffer or an extra MRT target, costs a full-screen pass, and would ink every flagstone. Option C
(texture inner lines [V: S13]) needs UVs we don't have. The hull costs +3 % (measured) and draws
part-overlap lines for free.

**Build** (load time, **its own `:load` step per body** for the heap):
1. `build-parts … &key ink` (default NIL, which builds no hull, so RAVEN is unchanged). While it
   builds the solid mesh, it records `mb-fill` before and after each `build-shape`.
2. For each range it copies the positions into a hull builder and **recomputes face normals from
   the positions** (non-indexed triangles), so it does not depend on smooth or flat solid normals
   or on the jitter RNG. It groups vertices of *that range* by quantised position (1e-4 m):
   - `ŝ` = the normalised sum of the distinct face normals;
   - `e = ŝ / max(min_i ŝ·n_i, c)`;
   - `c` = 0.55 for boxes, bevels, cylinders and spheres (a box corner gives e = (±1, ±1, ±1),
     so each face moves out exactly w);
   - `c` = 0.8 for cones, wedges and blade sections (no ink needles);
   - if `|Σn| < 1e-3`, use the vertex normal.
3. **The width multiplier k is baked into e** (`e ← e·k`), which leaves the vertex colour free for
   the **ink colour per shape**:
   - skin shapes get #3A1610;
   - all other shapes get the body's `:ink`.

   Width multipliers:
   - `:ink k` per shape, default 1;
   - 0.6 for shapes under 10 cm;
   - k = 0, **left out of the hull**, for shapes under 4 cm and every `:c :ink` shape (eye slits,
     inner strokes).
4. Weapons: `defweapon` sections are split with `mb-blade :hilt nil` / `:blade nil`, and each
   section takes `:ink k`:
   - the katana blades get 0;
   - the Nozarashi slab (ken-art.lisp:96-104) gets 1;
   - guards and hilts get 1.
5. `HULLS` is stored as a parallel vector (a third return value). `extras` stays at 5 slots, and
   tagged-part hulls go in a parallel list.

**Draw.** `draw-parts … &key ink-tint (ink-px 1.8)`:
- It queues all solids, then all hulls, so there are 2 pipeline switches per fighter.
- The tint is white, or #9AB0FF for the mirror-match P2, which gives blue-black ink.
- Pipelines use cull codes **3 = FRONT/CCW** and **4 = FRONT/CW** in `r_make_pipe`.

```wgsl
@vertex fn vs_hull(@builtin(instance_index) ii: u32, @location(0) p: vec3f, @location(1) e: vec3f,
                   @location(2) c: vec3f) -> LitV {
  let d = draws[ii];
  let wp = d.model * vec4f(p, 1.0);
  let we = (d.model * vec4f(e, 0.0)).xyz;                        // k already baked in
  let depth = (F.vp * wp).w;
  let mpp = 2.0 * depth / (F.scr.z * F.scr.y);                  // metres per pixel at this depth
  let ve = normalize(we + vec3f(1e-6)); let vd = normalize(F.cam.xyz - wp.xyz);
  let taper = mix(0.45, 1.0, 1.0 - abs(dot(ve, vd)));           // full on the silhouette, thin on overlaps (art §1.10)
  let w = clamp(d.toon.w * F.scr.w * mpp, 0.004, 0.03) * taper;
  var o: LitV;
  o.pos = F.vp * vec4f(wp.xyz + we * w, 1.0);
  o.wpos = wp.xyz; o.nrm = we; o.col = pow(c, vec3f(2.2)); o.dif = vec3f(0.0); o.spc = vec3f(0.0);
  o.tint = d.tint; o.fx = d.fx; o.rim = d.rim; o.toon = d.toon;
  return o;
}
@fragment fn fs_ink(i: LitV) -> @location(0) vec4f {
  let c = mix(i.col * i.tint.rgb, F.fog.rgb, fog_amount(i.wpos) * 0.2);
  return vec4f(pow(clamp(c, vec3f(0.0), vec3f(1.0)), vec3f(1.0 / 2.2)), 1.0);
}
```
**Ink art pass** (+0.5 d). The haori is 15 abutting panels (yama-art.lisp:17-36), and the beard and
brows are 9 boxes (:44-54). Without care, per-shape hulls would outline every panel seam. So:
- `:ink 0` goes on the inner and side panels;
- only the outer silhouette panels and the collar keep ink;
- the result is checked with a 3/4-view still.

### 2.5 Palettes, inner strokes, faces (v4 notan)

The HSV shadow rule (§2.2) is unchanged, except that neutrals now rotate to the **cold** hue 0.61
(blue-grey, 220°) instead of lavender: `h.x = 0.61` in `shade_of`.

| Key | v3 | **v4 lit** | v4 shadow (≈) | Note |
|---|---|---|---|---|
| Yamamoto `:black` | #34324A | **#16161E** | #0A0A10 | a solid black mass (spotted black) |
| Yamamoto `:white` | #EEEAE0 | **#F0F0EC** | #9CA3B4 (cold grey-blue) | haori and sleeves |
| Yamamoto `:beard` | #DAD8D0 | **#ECECEA** | #A2A8B6 | |
| `:skin` (both) | #E0A884 / #D89A70 | **#D8B4A0** / **#CFA48C** | #9A7478 (cold-shifted) | the only warm non-spot colour, muted |
| Yamamoto `:cord` | #6B3A96 | **#4A3A6A** | | desaturated; not a spot |
| Kenpachi `:hair` | #2A2A3A | **#0C0C12** | #08080C | a solid black mass + white highlight strokes |
| Kenpachi `:black` | #2E2C3C | **#16161E** | #0A0A10 | |
| Kenpachi `:white` (haori) | — | **#E8E8E4** | #969DAE | tattered hem |
| Kenpachi eyepatch | #070707 | #070707 | | |
| Ink (hull) | per character near-black | **#101018** on light parts, **#4A5062 keyline on black parts**, **#3A1E1A** on skin | | the keyline is dark against the V3 ground and light against the V0 sky |
| Mirror P2 | blue-black tint | P2 haori and white parts tinted #D8E2F2 (cold), keyline #5A6A8A | | |

- **Inner strokes take the opposite value of their part** (Kubo's white lines on black cloth):
  - on black parts: **white strokes** #D8DCE4 (Yamamoto: 3 robe folds + sleeve-opening edge;
    Kenpachi: 4 hair-spike highlights, 2 robe folds);
  - on white parts: ink strokes (haori collar V, hakama pleats, cuffs, tattered-hem notches);
  - on skin: Kenpachi's scar and the eyepatch strap in ink.

  They are all thin `:c` boxes under 4 cm, so they get no hull.
- **Faces**: unchanged from v3 (ink brows as wedges, eyes, grin), `:tag :face-neutral`.
  Expression swaps (`:face-shout`, `:face-hurt`) are **in scope** (Phase 5).
- The CC2 vertical gradient (§2.2) stays at 0.14. On black robes it is invisible, and on the
  white haori it gives the soft "moonlit from above" fall-off.

### 2.6 Motion: smooth, pose-to-pose, holds, smears, afterimages

- **Key easing** (art §1.14): `clip-sample!` (anim.lisp:173) uses smoothstep between keys, or
  linear for `:snap`. A new `*key-ease*` (0 = today, so RAVEN is unchanged; 1 = ease-out cubic
  `1−(1−u)³` for non-snap keys) makes SOUL DUEL poses snap into keys and settle. This is one
  function edit; per-clip re-authoring is below the cut line.
- **Holds**: a `model-hold` slot, in frames. While it is > 0, `draw-fighter` skips `anim-eval` and
  reuses the cached local pose, but still runs `pose-fk!` with the current root, so the body does
  not detach from a moving actor. It is used by cinematics and for 3–4 f attacker holds on heavy
  hits. It is visual only.
- **Squash/stretch smear**: 1 frame at dash, Hoho and heavy-swing starts. Every joint matrix of
  the fighter is premultiplied by `T(root)·S·T(−root)`, with S = ×1.5 along the motion and ×0.7
  across it. Hulls follow automatically, and the scratch matrices are f32vecs, so it conses 0 B.
- **Sword smear**: `fx-crescent` with the **comet profile** (§3.4) from hilt to tip, spanning the
  last 3 trail samples, held for 2 drawings.
- **Afterimage** (Hoho, SP2 dash). One ghost joint buffer per fighter (16·nj floats, allocated at
  load) holds the vanish pose. The sequence is:
  - d1: that pose drawn **opaque** with `:flash 1.0`, a **pure white silhouette** (v4 notan);
  - d2: **hull only**. A front-culled shell with nothing inside renders a **solid ink
    silhouette**: a black afterimage. White then black: Kubo's notan in two drawings;
  - d3: gone.

  There is no `alpha < 1` body anywhere, since the transparent pass has no depth write and would
  show x-ray insides.

---

## 3. Effects

### 3.1 Choice: vector ink-shapes; the flipbook atlas stays cut

This part of v2 is unchanged:
- Vector shapes need 1 pipeline, 1 batch and 0 textures, and they reuse every shape call.
- A procedural RG8 flipbook atlas (512²×2 B = 512 KB) would be the first scene-pass texture.

v3 adds the art critic's fixes (core field, weighted broken edge, erosion by holes, scrolled fire,
envelopes). With them, vector shapes are judged sufficient, and the atlas is below the cut line
for good.

### 3.2 `RP_FXT` and the toon batch

- `*fx-toon*` = `(make-stream-buffer 9 16384)`. `with-fx-verts` becomes 3-way (render.lisp:397
  is a 2-way `if`). The buffer is reset in `begin-frame` and passed to `r_frame` as arguments
  `#a` and `#b`. The transfer buffer grows by 576 KB.
- **Pipeline**: slot 15, `vs_fx_toon` + `fs_fx_toon`, depth test and write, **alpha-to-coverage
  with blend off** (new `blend 3` in `r_make_pipe`) when MSAA 4× is on. At 1 sample it uses
  `discard` below cover 0.5. A2C removes v2's fringe-writes-depth halo. It validates on
  SwiftShader (tech §0), and the backend passes it through (SDL_gpu_webgpu.c:3542).
- **Draw order**: sky, opaque, hulls, transparent, **fx toon**, fx alpha, fx add. T光 glow
  [V: S24] lands on top of drawn shapes.
- **Palettes are a WGSL constant**: `var<private> PAL: array<vec4f, 48>` in `fx-toon.frag.wgsl`.
  They are authored constants, and changing one needs a rebuild either way, so there is no
  uniform and no sync point. The layout is 12 palettes × (core, body, shade, edge).
  - `core.w` = style: 0 energy, 1 matter puff, 2 fire hybrid.
  - `edge.w` = edge px @720.

Vertex meaning in the toon batch (9 floats):
- `uv`: shape-local; `|uv|` = 0 at the spine or centre, 1 at the edge. This holds for billboards,
  ribbons (±1, 0) and sectors (0, ±1), since `length` is symmetric.
- `r`: **heat** 0..1 (ribbons run it base 1 to tip 0.2).
- `g`: **seed**. A negative seed marks an "along" shape (ribbon or wall), whose along-coordinate
  is taken from heat.
- `b`: **wobble** 0..0.5.
- `a`: **p + k**, the palette index plus presence, with k ∈ [0.01, 0.98]. It is passed as a
  `@interpolate(flat)` varying `pk`. Toon calls pass a0 = a1.

`fx-toon.frag.wgsl` (essentials):
```wgsl
fn pcg(v: u32) -> u32 { let s = v * 747796405u + 2891336453u; let w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u; return (w >> 22u) ^ w; }
fn h21(p: vec2f) -> f32 { return f32(pcg(bitcast<u32>(p.x) ^ pcg(bitcast<u32>(p.y)))) / 4294967295.0; }  // same on every GPU
fn vnoise(p: vec2f) -> f32 { /* 4 x h21 on the integer lattice, smoothstep-interpolated */ }
@fragment fn fs_fx_toon(i: FxT) -> @location(0) vec4f {
  let p = min(u32(i.pk), 11u); let k = fract(i.pk);
  let core = PAL[4u*p]; let body = PAL[4u*p+1u]; let shade = PAL[4u*p+2u]; let edge = PAL[4u*p+3u];
  let along = i.col.g < 0.0; let seed = abs(i.col.g);
  let s = select(i.uv, vec2f(i.uv.x, 1.0 - 2.0 * i.col.r), along);        // shape coords: y = −1 base .. +1 tip
  let tick = floor(F.clk.x / select(2.0, 3.0, core.w == 1.0));          // fire/energy on twos, matter on threes
  let scroll = select(0.0, tick * 0.35, core.w == 2.0);                 // fire travels upward (art §2.4)
  let reseed = select(tick, floor(tick / 3.0), core.w == 2.0) * 0.37;   // fire reseeds every 3rd drawing
  let q = vec2f(s.x, s.y - scroll) * 2.6 + vec2f(seed * 91.0 + reseed, seed * 57.0);
  let n1 = vnoise(q) - 0.5; let n2 = vnoise(q * 1.7 + 13.0) - 0.5; let n3 = vnoise(q * 3.1 + 29.0);
  var d = length(i.uv) + n1 * i.col.b;                                  // silhouette field
  if (along) { d = max(d, (1.0 - k - i.col.r) * 4.0 + k); }             // tip erosion inside the field (tech §4.16)
  let aa = fwidth(d);                                                   // uniform control flow: before any branch
  var cover = 1.0 - smoothstep(k - aa, k, d);
  if (core.w == 1.0) { cover *= step(1.0 - k, vnoise(q * 0.8 + 71.0)); } // matter perforates (art §2.5)
  if (cover <= 0.0) { discard; }
  let hc = length(s - vec2f(0.15, -0.35)) + 0.6 * n2;                   // separate core shape (art §2.1)
  var c = body.rgb;
  if (core.w == 1.0) {                                                  // puff: sphere-lit, light:shadow ≈ 7:3 [V: S23]
    let nz = sqrt(max(1.0 - min(dot(i.uv, i.uv), 1.0), 0.0));
    let l = dot(vec3f(i.uv, nz), vec3f(-0.45, 0.60, 0.66));
    c = select(select(shade.rgb, body.rgb, l > -0.05), core.rgb, l > 0.55);
  } else {
    c = select(c, core.rgb, hc < 0.42 * k);                             // core ⊂ body (the clamp)
    c = select(c, shade.rgb, d / k + 0.3 * s.x > 0.82);                 // shadow on the side away from the light
  }
  let wdir = clamp(dot(normalize(s + vec2f(1e-4)), vec2f(0.35, -0.94)), 0.0, 1.0);   // heavy under and behind (art §2.2)
  var ew = edge.w * F.scr.w * (0.4 + 0.9 * wdir) * step(0.2, n3);       // screen-constant, broken like a brush lift
  if (core.w == 2.0) { ew *= step(s.y, -0.33); }                        // fire: dark edge on the lower third only
  c = select(c, edge.rgb, d > k - ew * aa);                             // edge band in pixels (tech §4.15)
  c = mix(c, F.fog.rgb /* as sRGB */, 0.6 * i.fog);                     // fog tints colour, not coverage (A2C)
  return vec4f(c, cover);
}
```
The derivative `fwidth` is taken in uniform control flow before the `discard`. The branches are
per shape (the style), so they are uniform. Each shape is 1 hard layer, replacing 3 to 4 soft
additive ribbons (`fire-tongue`).

**Billboards in toon mode are pushed toward the camera** by 0.8 × radius, and their size is
rescaled to keep the same screen size. This is done on the CPU in the toon billboard writer. A
puff then no longer slices bodies and the floor with straight depth lines (art §2.9). Ground rings
are lifted 2 cm.

### 3.3 Palettes v4: mono + 3 spot colours; the value-opposite edge

**Edge rule.** v3's matter/energy rule gains one refinement for a monochrome world. The **edge
takes the value opposite to the shape's body**:
- light shapes (white hits, pale smoke, steel, yellow reiatsu) get a dark hairline, so they read
  on the pale ground;
- dark shapes (ink reiatsu, black smoke, ink splashes) get a white edge, so they read on the
  black sky.

Matter edges are heavier (1.4–1.6 px) and energy edges thinner (1.0–1.2 px). Fire keeps its v3
hybrid (dark red, lower third only).

New style 3, **charcoal**: the body is mixed with the shade by a high-frequency grain
(`vnoise(q*6.0) > 0.55`). It is used for Zanka no Tachi's ink-wash/charcoal look [V: K3]. It is
one more branch in `fs_fx_toon`, uniform per shape.

| # | Name | Core | Body | Shade | Edge (px) | Style | Colour class |
|---|---|---|---|---|---|---|---|
| 0 | FIRE | #FFF3DC | #FF5A1E | #B81A0C | #1A0402 (1.6), lower third | 2 hybrid | **spot** |
| 1 | EMBER / HELLFIRE | #FFB08A | #E8301A | #6A0A06 | #0A0404 (1.4) | 2 | **spot** |
| 2 | REIATSU (awakened only) | #FFFFFF | #FFD83A | #C88A0A | #1A1206 (1.0) | 0 | **spot** |
| 3 | INK REIATSU (Kenpachi base form, Breaker aura) | #FFFFFF (core line) | #0C0C12 | #262833 | #FFFFFF (1.2) | 0 | mono |
| 4 | STEEL (Burst, guard) | #FFFFFF | #C8D4E4 | #7A8CA8 | #101018 (1.0) | 0 | cold tint |
| 5 | HIT | #FFFFFF | #FFFFFF | #C8CCD6 | #101018 (1.2) | 0 | mono |
| 6 | SMOKE (pale) | #F2F2EE | #C4C8D0 | #7A8090 | #101018 (1.6) | 1 matter | mono |
| 7 | DUST / ROCK | #D6D8DE | #A6AAB6 | #6A6E7C | #14151C (1.6) | 1 | mono |
| 8 | ASH | #FFFFFF | #D0D2D8 | #8A8E9A | #20222A (1.4) | 1 | mono |
| 9 | SOUL glass | #FFFFFF | #E6ECF4 | #9AA8BE | #101018 (1.2) | 0 | mono |
| 10 | BLOOD (Kikon, counter, Breaker edge, soul flame, ink-blood splatter) | #FFE8E8 | #D0101C | #6A0008 | #0A0002 (1.0) | 0 | **spot** |
| 11 | BLACK SMOKE / INK SPLASH / charcoal | #3A3E4C | #101018 | #08080C | #E8E8EC (1.2) | 1 (3 = charcoal variant via seed flag) | mono |

Each effect still uses ≤ 3 hues [V2: S11], and in practice 1 spot hue plus black and white.

### 3.4 Primitives (engine `fx.lisp`, 0 B per call via the `*ribbon-args*` pattern)

`(toon-a p k)` is a macro for the alpha argument.

Existing primitives in toon mode:
- `fx-ribbon`: tongues use w1 = 0 and a negative seed ("along").
- `fx-billboard`: discs and puffs, pushed toward the camera.
- `fx-line`: streaks.
- `fx-sector`: ground rings and fronts. v2's `fx-ground-ring` is dropped, because `|uv|` is
  symmetric.
- `fx-ring` gets a palette slot, so camera-facing rings are drawn toon with uv across the band.

New primitives:
- `(fx-star x y z r0 r1 n rot dirx diry heat seed a)`: an irregular star (art §2.10):
  - spike length r1 × hash(0.5..1.4);
  - angle jitter ±12°;
  - 1–2 long spikes along the screen-space hit direction;
  - spikes are degenerate quads, so the edge runs along both sides;
  - `r0 = r1` gives a polygon (the guard hexagon).
- `(fx-crescent x0 y0 z0 x1 y1 z1 bx by bz w profile heat seed a)`: a Bézier strip with 8
  segments. Profile `:lens` is `w·sin(πu)`; profile `:comet` is `w·u^0.4·(1−u)^0.15`, with u from
  tail to blade. v2's `fx-trail-crescent` is dropped: its job is this call, with the end points
  at 0.7 of the oldest and newest trail samples.
- `(fx-shard x y z dx dy dz len w heat seed a)`: a kite.
- `(fx-wall xs zs n height scallops heat seed a)`: a continuous flame wall along a base polyline.
  The top vertices form 5–7 scallops; uv.x = height fraction, so the core is at the base and the
  edge follows the top. This fixes the picket fence of separate tongues (art, fire wave).
- Toon particle kinds, merged from 4 to 2 (tech §4.21): `+p-t-blob+` 8 (the palette style decides
  flame or puff) and `+p-t-shard+` 9. The palette is in slot 14, k = the remaining life fraction,
  and the seed is the slot index × 0.618.
- **`fx-envelope`** (a macro, art §2.7) maps the quantised age and 4 frame counts
  `(flash grow hold out)` plus an optional `:anticipate` to (scale, k, flash-p):
  - anticipate: scale 1 → 0.8 plus converging `fx-shard`s;
  - flash (1 f): a white flash disc;
  - grow (2–3 f): 0.6 → 1.1, ease-out;
  - hold (4–8 f): 1.0;
  - out (≥ 2 × grow, 15–40 f): k 1 → 0 (erosion), scale 1.0 → 1.05.

  Every one-shot effect in §4 is written as an envelope call, not as prose.
- **Layering** (art §2.8), for every signature effect, back to front:
  1. a dark **backing** (palette 11 or the shade tone);
  2. the drawn mass;
  3. a thin additive T光;
  4. **scraps**: 2–6 `+p-t-blob+` or `+p-t-shard+` flying off.

### 3.5 Time: one fx clock, material rates

- `*fx-clock*` (seconds) advances by the frame's effect dt, which is 0 while paused, during
  `model-hold` beats and during impact stills (art §3.5). It is written to `F.clk.x` as 24-Hz
  ticks.
- **Material rates** (art §2.6), in ticks per drawing:
  - hit flash: **1** (ones) for its first 2 ticks, then 2;
  - fire, energy and auras: **2** (twos, 12 drawings/s [V (weak): S26]);
  - smoke, dust and ash: **3** (threes, which reads heavier).

  Layers on different rates are what breaks lockstep. v3 does *not* add a per-shape phase offset
  (see §13, "rejected").
- vfx.lisp: `(clock)` (vfx.lisp:38) and the aura age (main.lisp:94) are redefined on the fx clock,
  one line each. `(sage age rate)` quantises an effect's age to the same tick grid:
  `age − mod(fx-clock, rate/24)`, clamped to ≥ 0.
- Toon particles are drawn at `pos − vel·min(mod(fx-clock, rate/24), age)`, which is coherent
  across particles (tech §5.22).
- **Positions that gameplay depends on are never stepped** (fire wave, fireball, Kaka, Breaker
  dash). Only their shapes step.

### 3.6 Screen punctuation (v4: inversions and spot-keeping)

- **`RP_COMP_FX`** (new file `composite-fx.frag.wgsl`, `P: array<vec4f,3>`: the existing lane;
  mode, threshold, keep-saturation and keep-hue; ink rgb; paper rgb; 48 B) is chosen in `r_frame`
  only while `*grade-impact*` ≠ 0. `RP_COMP` and `composite.frag.wgsl` are untouched, so RAVEN
  is unchanged.
- Modes:
  1. **negative**: `1 − c`.
  2. **two-tone**: `select(ink, paper, luma > thr)`.
  3. **manga page** (new): two-tone, but pixels with saturation > `keep-sat` (0.45) keep their
     colour. The world turns to a black-and-white page while fire, blood and yellow stay: the
     TYBW red-accent inversion.
  4. **spot-keep desaturation** (new): grey everywhere except pixels whose saturation is above
     `keep-sat` *and* whose hue lies within ±25° of `keep-hue`. Bankai uses it with hue 10°
     (the ember line) for the whole 20 s. It replaces `*grade-desat*` 0.3.
- Cost: the same 3 taps as `RP_COMP` plus about 20 ALU for the rgb→hsv test, and only while
  active. The Bankai state keeps it active for 20 s, which is negligible [I, measured in Phase 2].
- Presets:
  - white/ink (#FFFFFF/#08080C);
  - ink/white (#08080C/#FFFFFF, used on a white card);
  - red/ink (#D0101C/#08080C);
  - fire/ink (#FF5A1E/#08080C).
- UI layer (0 B per call, `%ui-poly4` fans):
  - `(ui-focus-lines cx cy n r-min r-max col drawing)` (集中線);
  - `(ui-speed-lines dir n col drawing)` (流線);
  - **`(ui-ink-splash cx cy r seed col drawing)`** (new): a main blob (a 14-gon with hashed
    radius), 5–9 thin spikes, and 6–12 satellite droplets along the spikes. It grows over 2
    drawings, then holds. Black on white cards, white on black cards. Kubo's ink-splash title
    pages [I].
- Shake: `*shake-hz*` = 12 in SOUL DUEL (default 30 keeps RAVEN), 3–4 discrete decaying offsets.
- **Silence beats** (TYBW removed all sound except bone sounds in Yamamoto's fire sequence
  [V: K4]): `(silence frames)` in cinema.lisp ramps the music to 0.1 with `set-music-volume` and
  suppresses `play-sfx` from cinematic scripts for the beat. No engine change.
- Still cut: chromatic aberration (+14 % measured), fisheye, zoom blur.

---

## 4. Per-effect redesigns

Timings are at 60 Hz. "d" means a drawing at the material's rate. Envelopes are written
`(flash grow hold out)` in frames. **AC** is the 1-line shape check an agent can close from a
still without the user (tech §9.34). ▲ marks Phases 2–3; the rest are Phase 5. The scope now
covers every row.

**v4 palette mapping** (§3.3), applied to every row below:
- fire → FIRE (0); Hellfire and Bankai embers → EMBER (1);
- Kenpachi's reiatsu → **INK REIATSU (3) in base form**, and REIATSU yellow (2) only when awakened
  (Nozarashi) and in his cinematics;
- Breaker → INK REIATSU with a BLOOD edge;
- Burst and guard → STEEL (4); hits and clash → HIT (5); Konpaku → SOUL glass (9);
- Kikon, counter and soul flame → BLOOD (10);
- smoke backing → BLACK SMOKE (11) on the pale ground, or SMOKE (6) against the dark sky.

### 4.1 Yamamoto
| Effect | Redesign | AC |
|---|---|---|
| ▲ **Blade fire** | toon sheath ribbon (FIRE, heat 1 at the base to 0.3 at the tip) + 3 tongue ribbons (w1 = 0, along) + a thin additive core line + 10 `+p-t-blob+`/s scraps peeling off the swing; the swing is drawn as a FIRE `fx-crescent :comet`, held 2 d | the blade reads as a flame with yellow core, orange body and dark-red lower edge; no white blob |
| ▲ **Fire wave** | **one continuous `fx-wall`** along the crescent (5–7 scallops, FIRE) + a BLACK SMOKE backing wall behind it, 20 % taller and curling off the crests + an `fx-crescent :lens` slash at 1.2 m + 6 flame scraps flying ahead + an EMBER sector scorch; envelope (1 3 ∞ 18) | one wall, not a fence; smoke backing visible where the wall crosses the moonlit ground; the wall is the only warm mass in the still |
| Shiranui | toon disc (FIRE, wobble 0.3) + 5 tongues curling back + a BLACK SMOKE wake (threes) + scraps. Charge: anticipation (converging LIGHT shards + `ui-focus-lines`), disc growing in 3 drawings | ball reads as a drawn fireball with a smoke trail |
| Taimatsu | 9 FIRE blobs fanned over the sector, envelope (1 3 4 30), 5 SMOKE puffs at the lip, a ground FIRE sector for 2 d | fan of drawn flames, then perforating smoke |
| Ennetsu Jigoku pillars | wide FIRE ribbon + an inner EMBER spiral stripe (a second ribbon, twisted) + a **crowned top** (a ring of 6 short tongues flaring out); rise on **ones** (3 drawings), crown on twos; erodes from the tip | 7 crowned pillars, each with a visible dark-red spiral |
| Jokaku Enjo | **no shell**. 3 inward-leaning tiers of tongue rings (12 + 9 + 6 tongues) closing in a spiral over 4 d; the seethe is the tongues boiling on twos; detonation per §5: a fire/ink negative, then a **manga-page** hold where the fire stays orange in a black/white world | never a striped sphere; tiers visible at mid-close; the fire is the only colour |
| Bankai | anticipation: 16 tongues pulled into the blade over 3 d + converging shards + ink focus lines; **silence**; burst: a BLACK SMOKE / charcoal (style 3) double ring + 6 charcoal puffs; silhouette reveal on a white card (§5); for the whole 20 s form: **spot-keep mode 4 (hue 10°)**, a charred blade with an EMBER edge line on threes, 4 slow **charcoal ink-wash wisps** for the heat [V: K3]; cracks = ink gashes with an ember core | the reveal still is grey except the ember line; the wisps show charcoal grain |
| Tenchi Kaijin | a pure white hard slash (`fx-crescent`-like UI polygon, tapered at both ends, 2 px ink border) in a true two-tone impact frame (white/ink), on a **black card**; then a manga-page hold; the victim flakes into ASH shards drifting sideways on threes; a silence beat before the slash | there is no translucent grey wedge; the frame has no colour at all |
| Nadegiri / Kyokujitsujin / Kaka | HIT `fx-crescent :lens` + an ink-edged scorch line; Kaka: DUST puffs + inked rock debris | — |

### 4.2 Kenpachi
| Effect | Redesign | AC |
|---|---|---|
| ▲ **Reiatsu aura** | **base form: INK REIATSU**: 7 black brush-flame tongues **behind** the body (radius 0.5 m, wider than the silhouette; `front-dim` lets only the edges wrap in front) with white edges and a white core line, height flicker per drawing (twos, seed boil) + white flecks rising. **Awakened (Nozarashi)**: the same shapes in REIATSU yellow with a dark hairline + 4 inner white tongues + a flat yellow ring + one faint T光 billboard | base form has no colour pixels; awakened, yellow is the only spot hue on Kenpachi; the body stays readable inside the aura |
| ▲ **Cleaves** | `fx-crescent :comet` from hilt to tip, 2 d. Base form: INK REIATSU (a black comet with a white leading edge). Nozarashi: white leading edge, yellow trailing edge, dark hairline | the smear reads as a comet, not a banana |
| Nozarashi awakening | pillar rises on **ones**, then holds; 2 flat rings; 8 DUST puffs; a negative frame at the eyepatch tear; the yellow pillar on a black card; silhouette plus yellow back-rim shot | the first frame where yellow fills > 30 % |
| Split the Meteor / Buttagiru | ink gash (a DUST-palette ribbon on the ground with a heavy edge) + a REIATSU core line + a light sheet of 5 LIGHT ribbons for 3 d + 12 inked rocks + 14 DUST puffs (threes) | particles per cut ≤ 20 |
| Sky split | beat 0 (a negative frame for 2 f) → **black card**, silence → the white light band with ink borders + focus lines, held 8 f (`model-hold`, no hitstop) → the existing `*grade-split*` → the ground cut in drawings | — |
| SP2 dash | afterimage sequence (§2.6) every 2 drawings + `ui-speed-lines` | — |

### 4.3 Universal (▲ all, Phase 2)
| Effect | Redesign | AC |
|---|---|---|
| Hit :cut | mono (HIT). Drawing 1 (ones): a round white flash disc; d2–d3: an irregular 6-spike HIT star + 4 shards along the hit direction; envelope (1 2 2 6); a thin T光 core; the flash light is kept | irregular spikes; gone by f15 |
| Hit :heavy | an 8-spike star (r 0.9) + an `fx-crescent` **impact mark** held 3 d + 6 shards + 3 DUST puffs + a 3 f attacker `model-hold` + a squash smear + 5–8 **ink-blood droplets** (BLOOD blobs, wobble 0.3) thrown along the hit direction | the impact mark is visible for 3 drawings; red only in the droplets |
| Hit :fire | FIRE star + 4 flame scraps | — |
| Counter | BLOOD star + a manga-page frame for 2 f (the world goes black/white, the red stays) + a "COUNTER" brush stamp | red is the only colour in the frame |
| Guard | a **hex-faceted** STEEL shape (`fx-star` with r0 = r1, n = 6) held 2 d + 4 steel shards | a hexagon, not a ring; no warm pixels |
| Guard break | 12 INK shards with BLOOD edges + a HIT star + a 1 f white flash | — |
| Clash | an 8-spike HIT star (r 1.2) + a negative impact frame for 2 f + focus lines for 20 f + a flat ground ring | — |
| Hoho | vanish: d1 squash/stretch smear + 6 horizontal speed streaks at body height; d2 ink silhouette (§2.6); d3 DUST puffs. Appear: converging streaks → a small HIT star | the ink afterimage is visible in the d2 still |
| Burst Reverse | anticipation (4 f contraction + converging lines) → a flat expanding **double ring** (thick white leading edge, thin STEEL trailing edge, dark hairline) + 8 steel shards + the defender silhouetted with a white back-rim for 3 f + a 1 f negative frame | there is no glowing ball |
| Konpaku shatter | 3 × N SOUL glass shards (white, dark hairline) + a SOUL star + a ring | mono |
| Soul flame | 1 BLOOD ribbon (dark hairline), a 3-drawing boil + a small white core | the only red over the victim |

### 4.4 Typography (brush, Kubo layout)

- **Font** (approved by the user): **Yuji Syuku** (SIL OFL 1.1). The offline tool
  `tools/brush-glyphs.py` (Python + fontTools + ear-clip triangulation) bakes the needed kanji
  and the Latin caption letters into `duel/lisp/glyphs.lisp`: a flat f32 list of triangles per
  glyph, about 200–400 triangles each.
  - The OFL copyright and licence text go in the file header and in
    `duel/FONT-LICENSE-YujiSyuku.txt`.
  - The game still loads no external files at run time. Build-time only; the tool is not part
    of `build.sh`, and its output is committed.
  - The kanji: 卍解, 野晒, 鬼魂, 城郭炎上, 天地灰尽, 残火太刀, 勝, and the "COUNTER" / "CLASH"
    words in Latin.
- **Layout (Kubo attack-name look [I])**:
  - The attack name is **large vertical brush kanji**, 50–70 % of the frame height, on the left
    or right third. It may **bleed off** the top or bottom edge.
  - Its **value is chosen by notan**: black glyphs on a white card, white glyphs on a black card
    or dark scene.
  - The **reading** is small (≤ 28 px), letter-spaced romaji set horizontally beside the kanji,
    for example "ZANKA NO TACHI". An English-style small caption line (Kubo's chapter-title
    habit [I]) sits at the lower left, e.g. "— BANKAI —".
  - A red **hanko** square (BLOOD #D0101C) appears **only** for Kikon names. It is the only
    colour on a caption.
- **Stamp animation** (on twos): scale 1.8 → 1.15 → 1.0, an `ui-ink-splash` behind the glyph on
  drawing 2, a shake of 3 discrete offsets, then hold. Exit: 3 horizontal slices slide apart over
  3 d (in scope, Phase 6).
- The centred 90 px pixel-font captions are removed from cinematics. HUD numbers keep the pixel
  font.
- **Title and results**: the brush title, and a big 勝 stamp (white on a black card, with an ink
  splash) replacing "WINNER". The stats keep the HUD font.

---

## 5. Cinematic language (`duel/lisp/cinema.lisp` helpers; engine `cine.lisp` unchanged)

Helpers (draw-mode, cosmetic):
- `(bg-drop rgb1 rgb2)`: the **background drop** (art §3.1). `stage-draw` is skipped for the beat,
  and the sky shows a flat 2-tone card (sky top = rgb1, horizon = rgb2, fog 0). Only fighters and
  effects remain. `cine-end` restores the stage through `stage-env`.
- `(silhouette-shot rgb)`: sets `F.key.w` = 1.5 (the whole body in its shadow tone) and
  `F.cin` = a hard back-rim: white (#E8ECF4) in the mono world, or the owner's spot colour (fire red-orange, awakened yellow) (art §3.4).
- `(fov-set deg)`: 38° for stand-offs, **85–95° at 1–1.5 m, low** for thrusts and reveals (forced
  perspective [V2: S3]).
- `(shot-dutch deg)`: rolls `camera-up` around the view axis.
- `(hold-pose e frames)` sets `model-hold`. `(impact-frame kind frames)` sets `*grade-impact*`.
  `(focus-lines frames &key center color)`.
- Orbits: **at most one per cinematic, ≤ 90° over ≥ 10 f, eased**. Otherwise, cut on the action
  (art §3.3).

**Grammar** (inside the existing `:len`):
0. **Trigger** (6–8 f): freeze (`model-hold` on both) + a negative impact frame (2 f).
1. **Wind-up** (10–16 f): a mid-shot with a low angle and 10° dutch, a **background drop** in the
   notan colour (§5 v4 additions: black card for Yamamoto, white card for Kenpachi), an ink
   splash, ink focus lines, the vertical kanji stamp.
2. **Establishing wide** (15–25 f): the effect rises in drawings.
3. **Cut on the action** (or the single ≤ 90° orbit).
4. **Hold** (8–12 f): `model-hold` + a FOV change + the fx clock paused.
5. **Impact** (2–3 f): impact frame → a 1–2 f white flash → a drawn shake.
6. **Aftermath wide**: puffs perforate, and the attacker's pose is held.

**Worked example: `yama-kikon-cine`** (len 108, unchanged; the debug `:hold` moves 70 → 78):
| f | Shot | Look |
|---|---|---|
| 0–7 | same as the gameplay shot | freeze + negative impact frame f0–1 |
| 8–20 | mid-shot on Yamamoto, low, dutch 10°, FOV 45, `bg-drop` black card #08080C + white `ui-ink-splash` | 城郭炎上 white vertical stamp, left third, bleeding off the top; silence beat |
| 20–44 | high wide on both, stage back | tier 1, 2, 3 tongue rings rise (ones), closing in 4 d |
| 44 | **cut** to a low wide-angle (FOV 90) on the victim inside the rings | seethe on twos |
| 60–77 | `hold-pose` both, FOV 90 → 60 over 3 cuts (60, 66, 72) | fx clock paused 70–77 (a silence beat) |
| 77–79 | same | `(impact-frame :fire 3)` |
| 80–81 | — | white flash |
| 82–108 | wide, slow push-out | explosion envelope (1 3 6 24), puffs on threes, Konpaku shatter at f82 (the existing `at 77` moves 5 f; cosmetic) |


**v4 additions (Kubo / TYBW language):**
- **Cards are pure black or pure white** (`bg-drop`), chosen for notan:
  - Yamamoto (white haori) goes on **black**;
  - Kenpachi (black robe, black hair) goes on **white**;
  - a clash goes on half-and-half, split along the blade line (two UI rects).

  The stage is not drawn during a card beat. A card beat is Kubo's negative space as an
  anime-style background drop.
- **Ink splash** (`ui-ink-splash`) on every wind-up card and every Kikon impact still.
- **Inversion cuts**: at each Kikon impact and each awakening reveal, a 2–3 f **negative** frame,
  then a 6–12 f **manga-page** hold in which the world is black and white and only the spot
  colour stays.
- **Silence beat** (`silence`) through every hold before an impact [V: K4].
- **Bankai reveal** (`yama-bankai-cine`):
  1. every flame is sucked into the blade (anticipation);
  2. **silence**;
  3. the frame goes spot-keep desaturated;
  4. a black silhouette of Yamamoto on a white card, with one ember-red line on the blade;
  5. vertical 卍解 / 残火太刀 stamp in black with a charcoal ink splash;
  6. the heat is drawn as charcoal wisps (style 3).

  The fire vanishing is the story beat [V: K3, K4], and v4 makes it the look.
- **Nozarashi awakening**: the only time yellow floods the frame.
  1. The eyepatch tears (negative frame).
  2. A yellow pillar against a black card.
  3. The skull silhouette in the pillar for 2 drawings (in scope, Phase 6).

The same grammar is applied to `yama-tenchi-cine`, `yama-bankai-cine` (silhouette reveal),
Kenpachi's awakening (silhouette + yellow rim) and Kikon, `soul-break-cine`, and `ko-cine`
(white/ink impact frame + a 20 f hold on the winner + the 勝 stamp on results).

---

## 6. Stage v4: Seireitei ruins at night (notan)

Numbers apply to `stage-env`, `stage.lisp` and `fs_sky_toon`.

- **Why night, not storm.** A storm's rain streaks and grey sky would add mid-value noise, which
  is the opposite of notan. Still night air with falling ash keeps two clean masses (black sky,
  white ground). The ash doubles as Yamamoto's burnt world, and Kubo uses sky and weather as
  emotion [V2: K2]. Rain stays available as an *emotional* cinematic accent (e.g. the K.O.),
  not as the base.
- **Sky**:
  - `fs_sky_toon` runs from zenith #08090E to horizon #1C2030 (V0 → V1);
  - **a huge white moon**: `sun-size` 6 (about 10°), elevation 14°, #EEF0F2, a flat disc with 2
    flat halo rings (#262A38, #1C2030) and no bloom;
  - the moon's azimuth sits behind the arena centre as seen from the default pair view, so
    fighters often stand against it (Kubo's backlit-moon composition [I]).
- **Ruins** (walls, houses):
  - drawn as **flat black V0** (#101118 lit, #0A0A10 shade);
  - moon-facing caps and ridges are lit #3A3E4C, so a thin edge light reads the silhouette;
  - no stage hulls;
  - the `st-house` walls lose their plaster white (#BEB6A8 → #2A2C36).

  The skyline becomes black paper cut-outs.
- **Burning buildings removed.** The flames, smoke, halos and the 2 stage fire lights go.
  `*st-fires*` becomes empty, which frees about 160 particles and 2 light slots.
- **Plaza** (rebuilt, Phase 1a):
  - one flat disc of moonlit stone, V3 (#BCC1CC lit; V2 #7A8090 shade);
  - 5–8 **ink cracks** (thin black ribbons, hand-placed data);
  - faint stone joints only in the outer ring (#9CA2AE, ≤ 1 px);
  - the curb ring in V2.

  The foreground is a near-blank "white page". This is the art critic's flat-plane rebuild, now
  in scope.
- **Falling ash**: the existing ash particles become toon ASH shards (white, 60 live), drifting
  on threes. Embers are removed (warm is spot-only).
- **Blob shadows** become **hard ink ellipses** under the fighters (INK palette, crisp edge):
  the Kubo cast shadow.
- **Fog**: #1C2030, density 0.012, height falloff unchanged. The far ground fades into the dark,
  which frames the white page like a vignette.
- **Light**: `moon_dir` comes from the moon (behind-left, 14°) for stage shading. Characters keep
  the camera-space key (§2.1). The 2 per-pixel stage lights now come **only from effects**, so a
  fire wave throws a warm pool onto the white ground (spot colour, very readable).
- **Grade**: bloom threshold 0.97 (effect cores only), vignette **0.35**, no global
  desaturation (the palette itself is desaturated). Bankai uses spot-keep mode 4.
- **Destruction** (in scope, Phase 6): ink scorch and crack marks that persist for the round,
  and inked rock debris that rests for 6 s. Black marks on the white page read strongly.
- **Camera**: `*cam-close*` = **0.8** (the user took the recommendation). Pair distance is
  `max(4.8, 3.6 + 0.68·sep)`; the behind eye is at 4.4 m.

---

## 7. Performance, memory, startup budget

Numbers come from the tech critic's synthetic SwiftShader experiment unless marked [I].

| Item | Today | After | Basis |
|---|---|---|---|
| Per-pixel lights | 8 on every lit draw | 0 on characters, 2 on the stage (`fs_toon`); RAVEN 8 (unchanged) | 33.1 → 15.3 ms for 0 lights in the synthetic scene; 2 stage lights put SOUL DUEL between the two |
| Toon branch cost on RAVEN | — | 0 (separate entry points) | +16 % avoided |
| Hull | — | +0.7 ms (+3 %) | measured |
| Composite | 3 taps | 3 taps; `RP_COMP_FX` (+~20 ALU) only during impact, manga-page and Bankai frames | CA (+3 ms) cut |
| Mesh draws (fight) | 45–46 (DEVLOG §14.4) | ~90 | +hull per part; `R_MAX_DRAWS` 4096 |
| Draw record, Frame | 112 B, 544 B | 128 B, 640 B | |
| fx batches | 2 × 576 KB | 3 × 576 KB (transfer 2.6 → 3.2 MB) | |
| Live particles (worst scene) | ≤ 1150 | target ≤ 500 | Storm 4 typical is 500 [V2: S8]; removing the stage fires frees about 160 |
| Point lights | 2 stage fire + effects | effects only | the stage fire lights are removed (v4) |
| Heap after startup | 103 MB | ≤ 110 MB | hulls built in their own `:load` step |
| Startup (`perf: first frame`) | — | ≤ +10 % | 7 new pipelines = 7 SwiftShader JIT compiles |
| Consing per frame, new paths | — | **0 B** | `defun-fast` / macros / `*ribbon-args*` pattern; checked by test |

---

## 8. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | Flat box faces pop between tones as fighters turn | camera-space key light, 7:3 bias, analytic smooth normals on round parts, a 0.04 soft band. Escalation: a per-vertex threshold float (10th vertex float), which also touches RAVEN |
| R2 | RAVEN changes | separate entry points and pipelines; keywords default off; the §9 Phase-0 harness (G1) |
| R3 | Backend quirks (FRONT cull, A2C, bind scanning) | WGSL smoke test: `examples/engine-demo` creates every slot, and `run.mjs` exits 1 on `WebGPU:` errors; the tech critic validated every entry point once |
| R4 | Hull seams on the haori and beard | the ink art pass (+0.5 d) with a 3/4-view still |
| R5 | Stepping hides projectile positions | shapes step, positions never do |
| R6 | Toon fx depth occludes soft fx | intended: T光 is drawn after them; checked in `duel-hellfire` |
| R7 | Box heads in close-ups | background drop, silhouette shots, mid-shots, drawn face shapes; no face close-ups under 1 m |
| R8 | "Guilty Gear, not Storm", or "a manga filter, not a game" | smooth bodies with stepped effects; spot colour and 2-tone depth keep it a 3D anime; user reviews 1–4 replace the skipped board |
| R9 | Notan world too dark or too flat for gameplay reading | pale-ground "white page" under the fighters (≥ 55 % of the frame); keyline and white strokes on black parts; user review 1 |
| R10 | Closer camera hides the opponent in some spacings | `*cam-close*` knob; the existing out-of-both-fighters rule stays |
| R11 | Heap growth step (+16 MB once in the past) | hulls in their own load step; startup heap AC |
| R12 | SwiftShader perf noise (±10 %) | median of 3, A/B in the same session |

---

## 9. Phased plan (scope 0–6, all approved)

Engine edits happen in the engwork tree and are synced once green (DEVLOG §14.1 step 4). **Every
phase ends with the standing gates:**
- **G1 RAVEN identity** (DEVLOG §14.1 steps 4 and 9):
  - the frozen still is byte-identical;
  - the ECL C diff touches only the expected functions;
  - RAVEN consing is within +10 %;
  - the frame time is within noise.
- **G2 duel determinism**: every `duel-cvc-*.json` result line and the 8 `duel hash` lines are
  unchanged.
- **G3 budgets**:
  - 0 B consing for 100 calls of each new per-frame path;
  - perf median of 3 A/B against the previous phase;
  - `startup: heap` ≤ 110 MB;
  - first frame ≤ +10 %.

**User review points** (the reference board was skipped, so the user reviews screenshots
instead): after **1a**, **3**, **4** and **6**, the agent publishes the still set, and the user
approves or redirects. These are the only user-gated steps.

| Phase | Content | Estimate | Acceptance (beyond G1–G3) |
|---|---|---|---|
| **0 Harness** | RAVEN frozen still + noise floor; duel frozen still (`duelvfx` freeze + stage fx off + fighter mask); CvC hash script; perf A/B script; WGSL smoke test; `tools/toon_check.py` (value steps, saturation, spot-pixel share, palette checks) | 0.5 d | the gates run green on the unchanged tree |
| **1a Notan world + toon characters** | §6 (sky, moon, black ruins, flat plaza with ink cracks, remove fires, ash, ink blob shadows, fog, grade, camera 0.8); §2.1–2.3 (`fs_toon`, `fs_sky_toon`, cold HSV shadows, gradient, jitter off, analytic normals); §2.5 v4 palettes | 2 d | duel still: ≥ 55 % of non-HUD pixels below the horizon are V3/V2 ground; the sky is ≤ V1; world saturation ≤ 0.12; a lit haori pixel = #F0F0EC ±3; robe pixels ≤ #16161E (+3); every face shows only its 2 tones (gradient masked); fight frame ≤ 0.75× today. **User review 1** |
| **1b Ink** | hull (§2.4), grey keyline on black parts, red-brown on skin, the ink art pass, **white-on-black inner strokes** and ink strokes, neutral face shapes | 2.5 d | a continuous silhouette on both fighters against ground *and* sky (the keyline is visible on the sky); thinner overlap lines; no haori seam lines; hull cost ≤ +5 % |
| **2 fx-toon + universal + punctuation** | §3 (A2C `RP_FXT`, WGSL palettes v4, charcoal style, value-opposite edges, envelope, fx clock, primitives, 2 particle kinds); §4.3 universal effects; `RP_COMP_FX` modes 1–4; focus lines, speed lines, `ui-ink-splash`; `model-hold`; squash smear; `*key-ease*`; `*shake-hz*`; `silence` | 3.5 d | §4.3 row ACs; hits are mono (no spot pixels); seeds change only on their rate's ticks; nothing changes while paused; manga-page mode keeps FIRE and BLOOD pixels and turns the rest two-tone |
| **3 Signature effects** | ▲ rows (blade fire, fire wave wall, ink-reiatsu and yellow reiatsu auras, cleave comets) + layering | 2 d | row ACs; spot-pixel share ≤ 15 % in the neutral still, and FIRE dominant only while Yamamoto's moves run; live particles ≤ 500. **User review 2** |
| **4 Cinematics + typography** | §5 (beat 0, black/white cards, ink splash, inversion cuts, silence, silhouette shots, FOV, holds); Bankai reveal; 8 cinematics re-staged; §4.4 glyph tool + `glyphs.lisp` + licence file; vertical captions, hanko, 勝 | 3 d | every Kikon: beat 0, ≥ 1 card beat, ≥ 3 cuts, ≥ 1 inversion (negative + manga page), ≥ 1 silence hold ≥ 8 f, a vertical brush caption; `:len` unchanged; the Bankai still shows a grey world with only the ember line red. **User review 3** |
| **5 Remaining effects + faces** | all non-▲ rows of §4.1 and §4.2; expression swaps (`:face-shout`, `:face-hurt`); per-clip pose-to-pose re-authoring of the attack clips | 5 d | row ACs; each fighter shows 3 expression states in the gallery |
| **6 Polish** | destruction marks and resting debris; caption slice exit; skull in the Nozarashi pillar; quantised fog bands (if they help the white page); rain accent for the K.O.; chromatic aberration or fisheye **only if** user review 3 or 4 asks; P10 atlas **only if** the charcoal style is judged too thin | 3 d | **User review 4** (final) |

**Total ≈ 21.5 d** of agent work, plus four user reviews. With parallel agents the limits are
engine syncs, SwiftShader review loops and the review points (tech §9.34). Phases 3 and 5 split by
character between two agents.

---

## 10. Not done (and when to add it)

- Post-process edges: only if the stage ever needs lines.
- The procedural atlas (P10): only if Phase 6 judges the charcoal style too thin.
- The per-vertex threshold float (R1 escalation).
- Halftone screen tone (Hi-Fi Rush, not Storm [V2: S20]; Kubo also reduced grey tones in favour of pure black and white [V2: K1], so v4 agrees).
- Real motion blur.
- Refraction heat haze.
- Chromatic aberration and fisheye (Phase 6 at most).
- Everything listed in §13 as dropped.

---

## 11. Priority order (the scope is 0–6, so the order only sets sequencing)

1. Notan world and camera (S–M).
2. Toon lighting and palettes (S).
3. Ink hull with keylines and white strokes (M).
4. `fx-toon` in mono + spot (M).
5. Hit stars, inversions, focus lines, ink splashes (S).
6. Brush captions (S–M).
7. Cards, silhouettes, silence, holds (S).
8. Inner strokes and faces (S).
9. Remaining effect rebuilds (L).
10. Polish (M).

Items 1–3 fix every gameplay screenshot, items 4–5 every effect, and items 6–7 every cinematic
still. Items 9–10 complete the user's full scope.

---

## 12. Open items for the user

The user has decided:
- the art direction (Kubo notan);
- the scope (0–6);
- the brush font (Yuji Syuku, OFL);
- no reference board;
- the camera at 20 % closer.

Still open:
1. **The four screenshot reviews** (after Phases 1a, 3, 4 and 6). They are the only remaining
   user gates.
2. Two defaults the user may overturn at review 1:
   - **night** was chosen over a storm for the base stage;
   - Kenpachi's **base-form reiatsu is black ink**, and yellow appears only when he is awakened
     or in his cinematics.
3. Carried from v3 as defaults:
   - smooth gameplay animation;
   - near-black ink with a grey keyline on black parts and red-brown ink on skin;
   - brush lettering on the title and results screens.

---

## 13. Debate record

### Round 1: internal Devil's Advocate + editor on v1 (18 findings)

These were all fixed in v2:
- the `|uv|` field on ribbons, trails and stars;
- the palette packing (now a flat varying);
- the invalid composite WGSL;
- the pipeline-slot shift and the `c-inline #a` issue;
- an unfounded perf claim;
- unsorted toon fx;
- hull needles and NaN;
- "palette-exact" vs exposure and bloom;
- paused-time jitter;
- `:hold` semantics and `hitstop` in cinematics;
- missing fisheye, faces, destruction and Kenpachi's hair;
- the over-engineering list (ghost weapons, `*hit-hz*`, zoom blur, per-joint `:shade`, the
  cloud mesh).

### Round 2: art-direction critique of v2

| Point | Verdict | v3 |
|---|---|---|
| 1.1 monochrome frame → blue hour | **accept** (user approval Q1) | D1, §6 |
| 1.2 seams heavier than ink | accept (mid-value seams, no stage hulls); rebuilding the foreground as a flat plane is **deferred** (M cost) | §6 |
| 1.3 far fires fight the fighters | accept | §6 |
| 1.4 fighters too small | accept as the `*cam-close*` knob (user approval Q2) | §6 |
| 1.5 CC2 vertical gradient | accept | §2.2 |
| 1.6 per-vertex pools draw diagonals on boxes | accept: no point lights on characters; the nearest fx light warms the shadow side | §2.2 |
| 1.7 rim flips whole faces | accept: no gameplay rim; cinematic back-rim only | §2.2, §5 |
| 1.8 muddy shadows | accept: HSV rule | §2.2 |
| 1.9 black robe vs ink | accept | §2.5 |
| 1.10 constant-width hull, 2.2 px | accept: facing taper, 1.8 px | §2.4 |
| 1.11 skin ink | accept: per-shape ink colour (k baked into e frees the colour) | §2.4 |
| 1.12 inner lines | accept: authored stroke boxes | §2.5 |
| 1.13 faces | accept neutral shapes; expression swaps below the cut (tag mechanism) | §2.5 |
| 1.14 pose-to-pose, holds, squash smear | accept: `*key-ease*`, `model-hold`, root-scale smear; per-clip re-authoring below the cut | §2.6 |
| 2.1 onion-ring bands | accept: separate core field | §3.2 |
| 2.2 sticker ink | accept, merged with tech 4.15: screen-px width × direction weight × brush breaks | §3.2 |
| 2.3 matter/energy | accept (it was already research §3.2's rule; v2 contradicted it) | §3.3 |
| 2.4 fire must travel | accept: scroll per drawing, reseed every 3rd | §3.2 |
| 2.5 shrink ≠ dissipate | accept: holes for matter, tip erosion for fire, scraps | §3.2, §3.4 |
| 2.6 lockstep; per-material rates | **rates accepted; per-shape phase offset rejected**. The tech critic showed that incoherent per-shape phases make the screen change every frame, so "12 drawings/s" never reads. Different rates per material already break lockstep between layers | §3.5 |
| 2.7 envelopes and anticipation | accept: `fx-envelope` | §3.4 |
| 2.8 four layers | accept | §3.4 |
| 2.9 puffs slice geometry | accept: billboard push, rings lifted | §3.2 |
| 2.10 regular stars | accept: irregular stars + flash disc + impact mark | §3.4, §4.3 |
| Per-effect notes (fire wall, crowned pillars, tiered Jokaku, Tenchi slash, reiatsu behind the body, comet cleave, hex guard, Burst rings, glass Konpaku) | accept all; the skull pillar is below the cut | §4 |
| Hoho: the hull-only pass is a solid ink silhouette | accept the correction and **keep** it as drawing 2 (see the tech 12 conflict below) | §2.6 |
| 3.1 background drop | accept | §5 |
| 3.2 wide-and-close FOV | accept | §5 |
| 3.3 orbits strobe; cut instead | accept | §5 |
| 3.4 silhouette and back-rim shots | accept | §5 |
| 3.5 drawn shake, holds freeze the fx | accept: `*shake-hz*`, fx clock paused | §3.5, §3.6 |
| 3.6 brush captions, vertical kanji | **goal accepted, implementation changed**: vector glyph polygons instead of a 256² R8 texture atlas. The UI batch binds one nearest-sampled R8 font atlas (96×48); a linear-filtered brush texture needs a second UI pipeline and binding, or it blurs the pixel font. Triangles need no engine change and scale to any size | §4.4 |
| 3.7 beat 0 | accept | §5 |
| §4 answers to the open questions | adopted as defaults | §12 |
| §5 80/20 and cut line | adopted, merged with the tech cut list | §9, §11 |
| Phase-0 board + TYBW/RoS | accept | §9 |

### Round 3: rendering-engineering critique of v2 (with measurements)

| Point | Verdict | v3 |
|---|---|---|
| §0 measurements | adopted as the perf basis and in the ACs | §1, §7, §9 |
| 1.1 toon branch slows RAVEN +16 % | accept: separate `fs_toon`, `RP_TOON*`, `fs_sky_toon` (retires `fogh.w`) | §2.2 |
| 1.2 hull building not gated | accept: `build-parts &key ink` default NIL; jitter default 0.06 | §2.3, §2.4 |
| 1.3 CA taxes RAVEN | accept: `RP_COMP_FX`, used only during impact frames; CA cut | §3.6 |
| 1.4 pixel-identity AC untestable | accept: the DEVLOG §14 method + frozen still (G1) | §9 |
| 1.5 shared touch points | accept: listed in §1 and G1 | §1, §9 |
| 2.6 stage loses its pools at 0 lights | accept: 2 uniform per-pixel lights for stage draws in `fs_toon`; ladder no-op documented | §2.1, §2.2 |
| 2.7 capsule and taper normals wrong | accept: `%mb-tri-n` with correct formulas | §2.3 |
| 2.8 weapon jitter | accept | §2.3 |
| 3.9 weapon sections | accept: split blade and hilt; `:ink` per section; Nozarashi lined | §2.4 |
| 3.10 build-twice wasteful | accept: recorded ranges + recomputed normals | §2.4 |
| 3.11 haori and beard seams, eye slits > 4 cm | accept: ink art pass; every `:c :ink` shape has k = 0 | §2.4, §2.5 |
| 3.12 hull-only afterimage = ink blob → cut drawing 2 | **rejected**. The blob *is* the intended drawing: a solid ink silhouette, the black afterimage (art). The tech cost argument applies to a *lines-only* version, which needs a depth pre-pass; the solid silhouette needs none. The ghost joint buffer the critic proposes for drawing 1 serves drawing 2 at no extra cost | §2.6 |
| 3.13 keep hull; draws start at 45–46 | accept | §7 |
| 4.14 fringe depth halos → A2C | accept | §3.2 |
| 4.15 ink band as % of shape | accept: screen-px (merged with art 2.2) | §3.2 |
| 4.16 tip erosion aliasing | accept: folded into the distance | §3.2 |
| 4.17 `fx-ground-ring` redundant | accept (v2's uv claim was wrong) | §3.4 |
| 4.18 `fx-trail-crescent` redundant | accept (comet profile added to `fx-crescent`) | §3.4 |
| 4.19 palettes as a WGSL constant | accept (Frame 344 → 160) | §3.2 |
| 4.20 sin-hash GPU-dependent | accept: pcg | §3.2 |
| 4.21 4 → 2 particle kinds | accept | §3.4 |
| 5.22 per-particle step phase incoherent | accept: one fx clock | §3.5 |
| 5.23 CvC gate every phase | accept (G2) | §9 |
| 6.24 fisheye sign | acknowledged; fisheye cut | §3.6 |
| 6.25 ship impact frames only | accept | §3.6 |
| 7.26 atlas stays deferred | accept | §3.1 |
| 7.27 heap | accept: own load step, AC | §2.4, §9 |
| 7.28 startup | accept: AC | §9 |
| 8.29–31 still targets, perf method, WGSL smoke | accept (Phase 0) | §9 |
| 9.32 harness first, engwork tree | accept | §9 |
| 9.33 split Phase 1 | accept: 1a / 1b | §9 |
| 9.34 per-effect 1-line ACs | accept | §4 |
| 9.35 impact frames and `hold-pose` early | accept: Phase 2 | §9 |
| §10 cut list | adopted, merged with the art cut line | §9, §10 |

### Conflicts between the two critics, and how they were resolved

1. **Stepping phase.** Art wanted a per-shape phase offset; tech wanted one coherent clock. Tech
   wins for the phase and art wins for per-material rates. The two combined give coherent
   drawings in which layers still don't strobe as one.
2. **Afterimage drawing 2.** Tech said cut it; art said keep it as an ink silhouette. Art wins:
   it needs no extra engine work.
3. **Point lights.** Art wanted none on characters; tech wanted 2 per-pixel lights for the stage.
   Both are adopted: characters use 0 per-pixel lights plus the shadow-side tint, and the stage
   gets 2.
4. **Cut lists.** Both cut CA and fisheye. Art's cuts (fog and sky bands, ground marks, stamp
   exit, skull, atlas, expression swaps) and tech's cuts (stage hulls, redundant primitives, the
   palette uniform, the `fogh.w` flag) were merged in §10 and §11.


### Round 4: the user's decisions on v3 (recorded verbatim in substance)

| # | v3 question or proposal | User decision | v4 consequence |
|---|---|---|---|
| 1 | Blue-hour re-key (or keep the dusk) | **Rejected both.** In the user's words, translated from zh-TW: "Use Kubo Tite–style stark black-and-white contrast between the characters and the background to bring out a despairing, deep, cold-and-dark base tone." | §A value system and notan interlock; night ruins with a white moon (§6); 3 spot colours (§A.2); palettes remapped (§2.5, §3.3); manga-page and spot-keep composite modes (§3.6); black/white cards, ink splashes, silence (§5); research §11 on Kubo, TYBW and RoS |
| 2 | Budget below the cut line? | **All phases 0–6** | the cut line becomes an ordering aid; §9 has 7 phases, ≈ 21.5 d |
| 3 | Brush font + offline tool | **Approved**: an OFL brush font (e.g. Yuji Syuku), converted offline by a fontTools tool into vector glyph data committed with the licence notice; no external files at run time | §4.4 |
| 4 | Phase-0 reference board | **Skipped**; the user reviews screenshots afterwards | Phase 0 is harness only; 4 user review points (§9) |
| 5 | Camera 20 % closer | the recommendation was taken | `*cam-close*` 0.8 (§6) |

**v3 positions reversed or changed by round 4, and why:**
- **Blue hour → notan.** Figure/ground contrast is now carried by *value*, not hue. The art
  critic's trait 0 (figure/ground) still holds; only its means changed.
- **Kenpachi's hair lift (#2A2A3A) is reversed** to solid black with white highlight strokes.
  In Kubo's language a black mass is kept black and separated by white lines. The v3 worry (hair
  equal to ink) is solved by the grey keyline and the white strokes, not by greying the black.
- **"Ink only on matter; energy gets a coloured edge"** becomes the **value-opposite edge**.
  Mono energy shapes need a dark hairline to read on the white ground.
- **Stage fires and warm pools are removed**: warm is spot-only.
- **The "cut" items are now in scope** as Phase 6. CA and fisheye stay conditional on a user
  review, because the +14 % measured cost is unchanged.

**New [I] risks introduced by v4, and their checks:**
- Kenpachi against the black sky: the keyline plus white strokes are checked at user review 1.
- A white page with low value contrast against the white haori: the haori shadow is V2 cold
  grey, and the ink hull is near-black. The Phase 1a AC checks the haori-to-ground separation.
- The spot share rising during fire moves: Yamamoto's fire is *meant* to dominate while his moves
  run; the ≤ 15 % AC applies to neutral stills only.
