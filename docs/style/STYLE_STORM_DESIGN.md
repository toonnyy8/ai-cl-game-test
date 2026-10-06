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
>    - 天空是冷暗的藍灰，後方有一輪巨大的月亮。
>    - 廢墟是冷灰剪影；廣場是月光下的中灰石地，只畫幾道墨線裂縫。天空、廢墟、地面收在同一段冷暗的中間明度（使用者在審查 1 決定：不要上黑下白）。
>    - 遠方燃燒的建築拿掉，暖色只留給特效。
>    - 選深夜而不選暴風雨，是因為 notan 最乾淨、畫面最不雜，灰燼又和山本燒盡一切的故事呼應。
> 2. **明度系統**：全畫面 5 階明度（V0 黑～V4 白）。
>    - 世界的彩度 ≤ 0.12。
>    - 世界（天空、廢墟、地面）是一整片平衡的冷暗中間調；畫面上最強的對比留給角色：黑衣對白羽織（審查 1）。
> 3. **點色規則**：全遊戲只有三個點色，一般對戰時暖色像素 ≤ 畫面 15%。
>    - 山本的火（橘紅）；
>    - 劍八的靈壓黃，所有形態都是黃色（使用者在審查 1 決定保留）；
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
> **目前狀態**：Phase 0–6 全部完成，使用者已在審查 4（最後一次）核准（2026-09-26：「非常完美」），重繪結束。
>
> **還需要使用者的**：無。審查 1 已決定：維持深夜（不下暴風雨）、劍八靈壓一律黃色、世界明度要平衡（不要上黑下白）、角色改成寫實身材比例（不要 Q 版）。

Companion to `STYLE_STORM_RESEARCH.md` (same folder; §11 covers Kubo Tite, the TYBW anime and
Rebirth of Souls). Source tags such as [V: S13] or [V: K3] refer to its tables; [I] = inferred.
Code references are `file:line` in this repository.

**Status.** v4. It follows four review rounds (§13):
- round 1: the internal review of v1;
- rounds 2 and 3: the art and engineering critiques of v2;
- round 4: **the user's decisions on v3**.

v4 changes the **art direction** (§A, §2.5, §3.3, §4, §5, §6). The engine architecture of v3
(§1–§3.2, §3.4–§3.5) stands unchanged. **All phases, 0 to 6, are implemented** (2026-09-25/26); the user **approved it at
review 4**, the last review point (2026-09-26; `tests/shots/style-final-gallery.png`), so the restyle is closed. §14 logs
what was built, where it differs from this text, and the measured gates.

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
| V0 black | #08080C – #14151C | black robes (lit and shadow), ink, cast shadows |
| V1 dark | #262833 – #4A5062 | sky (#1A1E2A zenith – #363B4C horizon), ruins (#343846 – #484D60), robe fold shade, grey keylines |
| V2 mid | #6A7182 – #7A8090 | ground (moonlit stone #767D8E), smoke shade |
| V3 light | #BCC1CC | effect shades, steel |
| V4 white | #EEEEEA – #FFFFFF | haori lit, effect cores, flashes, paper cards (the moon is a V3 #D6DAE0) |

Rules:
- World saturation ≤ 0.12, with hue in the cold band 210–240° (grey-blue).
- Skin is the only warm non-spot colour, muted (S ≤ 0.3).
- **Figure against one balanced world** (user review 1, §13 round 5; replaces v4's "notan
  interlock" of a black top and a white bottom). The world (sky, ruins, ground) sits in **one cold
  mid-dark value range** (V1–V2, luma about 40–125): the sky and ruins are lifted to V1 and the
  plaza brought down to V2, so the frame no longer splits into a black half and a white half. The
  strongest contrast on screen belongs to the **fighters**: black robes (V0) and white haori (V4)
  both read against the mid-grey ground and the V1 sky. It still satisfies trait 0 (figure/ground)
  by value.

### A.2 Spot colour: exactly three hues

| Spot | Hue | Owner | When |
|---|---|---|---|
| **FIRE** | red-orange 15–25° | Yamamoto | always in Shikai/Hellfire (it is his identity). In Bankai, **all fire vanishes** except a thin ember-red line |
| **REIATSU** | yellow 48–52° | Kenpachi | **in every form** (user review 1: keep his reiatsu yellow): his aura, Breaker, cleaves and cinematics. Nozarashi makes it bigger and brighter, not a different colour |
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
| REIATSU yellow always | ~~ink reiatsu in base form~~ → yellow in every form again (user review 1) |
| palette of 12 colours | 12 slots remapped to mono + 3 spots (§3.3) |

---

## 0. Decisions at a glance

| # | Decision | Why |
|---|---|---|
| D1 | **Kubo world, balanced**: Seireitei ruins at night, a cold dark sky with a huge moon, cold-grey ruin silhouettes, a mid-grey moonlit plaza with a few ink cracks, falling white ash, all in one cold mid-dark value range so the fighters carry the strongest contrast (user review 1). No burning buildings (§6) | the user's direction (§13 round 4). Night is chosen over a storm: storm rain adds grey noise and blurs notan, while still air with falling ash keeps the frame graphic. The ash ties to Yamamoto's burnt world. Kubo uses weather and sky for emotion [V2: K2] |
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
| Kenpachi eyepatch | #070707 | #070707 (removed 2026-09-26: no eyepatch in any form, TYBW) | | |
| Ink (hull) | per character near-black | **#101018** on light parts, **#4A5062 keyline on black parts**, **#3A1E1A** on skin | | the keyline is dark against the V3 ground and light against the V0 sky |
| Mirror P2 | blue-black tint | P2 haori and white parts tinted #D8E2F2 (cold), keyline #5A6A8A | | |
| **ICE keyline** (2026-09-28) | — | the white Rukia (absolute zero and the 白霞罸 costume, the bodies `:rukia-zero` / `:rukia-bankai`): **#7F97B4 on every shape** instead of the ink, and her brows **#CFE3F2** (a palette key `:brow` of their own) | | the user's decision: the white Rukia is outlined in ice, not ink. A per-body override (`body-variant … :ink`, `body-ink`: an alist like `*body-ink*`), no character name in shared code; every other body keeps `*body-ink*` (the `:brow` key maps to the hair's #4A5062 there, so the Shikai is unchanged). A slightly deeper ice than the #8FA6C0 first proposed, so the line still separates the white hair from the pale dusk ground |

- **Inner strokes take the opposite value of their part** (Kubo's white lines on black cloth):
  - on black parts: **white strokes** #D8DCE4 (Yamamoto: 3 robe folds + sleeve-opening edge;
    Kenpachi: 4 hair-spike highlights, 2 robe folds);
  - on white parts: ink strokes (haori collar V, hakama pleats, cuffs, tattered-hem notches);
  - on skin: Kenpachi's scar in ink (the eyepatch strap went with the eyepatch, 2026-09-26).

  They are all thin `:c` boxes under 4 cm, so they get no hull.
- **Faces**: unchanged from v3 (ink brows as wedges, eyes, grin), `:tag :face-neutral`.
  Expression swaps (`:face-shout`, `:face-hurt`) are **built** (Phase 5, §14): `draw-body :face` hides the other two
  tags; the fighter's state picks the face (hurt while stunned / airborne / down / lost, shout through a non-Quick
  move's wind-up and hit, a cinematic's attacker shouts and a Kikon's victim is hurt), and a look can hold one
  (`face-beat`: cup 3's grin).
- The CC2 vertical gradient (§2.2) stays at 0.14. On black robes it is invisible, and on the
  white haori it gives the soft "moonlit from above" fall-off.

### 2.6 Motion: smooth, pose-to-pose, holds, smears, afterimages

- **Key easing** (art §1.14): `clip-sample!` (anim.lisp:173) uses smoothstep between keys, or
  linear for `:snap`. A new `*key-ease*` (0 = today, so RAVEN is unchanged; 1 = ease-out cubic
  `1−(1−u)³` for non-snap keys) makes SOUL DUEL poses snap into keys and settle. This is one
  function edit; per-clip re-authoring is below the cut line. (Phase 5 re-authored every attack clip pose to pose
  within its own S / A / R: a held wind-up, a `:snap` into the unchanged hit pose at S, an overshoot, a zanshin
  hold, a settle; §14.)
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
| 0 | FIRE | #FFE483 (Phase 3; was #FFF3DC) | #FF5A1E | #B81A0C | none (review 2; was #1A0402 1.6, lower third) | 2 hybrid | **spot** |
| 1 | EMBER / HELLFIRE | #FFB08A | #E8301A | #6A0A06 | none (review 2; was #0A0404 1.4) | 2 | **spot** |
| 2 | REIATSU (Kenpachi, every form) | #FFFFFF | #FFD83A | #C88A0A | #C88A0A (1.0) = shade (review 2; was #1A1206) | 0 | **spot** |
| 3 | INK (ink reiatsu of other uses: black splashes on cards, the Breaker's dark backing) | #FFFFFF (core line) | #0C0C12 | #262833 | #FFFFFF (1.2) | 0 | mono |
| 4 | STEEL (Burst, guard) | #FFFFFF | #C8D4E4 | #7A8CA8 | #7A8CA8 (1.0) = shade (review 2; was #101018) | 0 | cold tint |
| 5 | HIT | #FFFFFF | #FFFFFF | #C8CCD6 | #C8CCD6 (1.2) = shade (review 2; was #101018) | 0 | mono |
| 6 | SMOKE (pale) | #F2F2EE | #C4C8D0 | #7A8090 | none (review 2; was #101018 1.6) | 1 matter | mono |
| 7 | DUST / ROCK | #D6D8DE | #A6AAB6 | #6A6E7C | none (review 2; was #14151C 1.6) | 1 | mono |
| 8 | ASH | #FFFFFF | #D0D2D8 | #8A8E9A | none (review 2; was #20222A 1.4) | 1 | mono |
| 9 | SOUL glass | #FFFFFF | #E6ECF4 | #9AA8BE | #9AA8BE (1.2) = shade (review 2; was #101018) | 0 | mono |
| 10 | BLOOD (Kikon, counter, Breaker edge, soul flame, ink-blood splatter) | #FFE8E8 | #D0101C | #6A0008 | none (review 2; was #0A0002 1.0) | 0 | **spot** |
| 11 | BLACK SMOKE / INK SPLASH / charcoal | #3A3E4C | #101018 | #08080C | #E8E8EC (1.2) | 1 (3 = charcoal variant via seed flag) | mono |

Each effect still uses ≤ 3 hues [V2: S11], and in practice 1 spot hue plus black and white.

**User review 2 (§13 round 6): no dark ink edge.** The dark half of the edge rule is withdrawn: no toon effect
draws a black or near-black outline. Each shape reads by its own core / body / shade steps. Fire, ember, blood
and matter (smoke, dust / rock, ash) have no edge at all (edge px 0). Light energy (REIATSU, STEEL, HIT, SOUL)
keeps a coloured edge in its own shade tone, plus its white core. The dark shapes (INK, BLACK SMOKE, charcoal)
keep their *white* edge, because that edge is not an ink line. The change is data only (the edge entries of
`fx-toon-pal.wgsl`); `fs_fx_toon` just loses the fire-only lower-third line. The fire wave's backing wall
changes from BLACK SMOKE to EMBER, because a black wall 20 % taller than the flames read as a black outline.

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
     (the ember line) for the whole 20 s, plus a second kept hue, 48° (`keep-hue-2`: Kenpachi's REIATSU
     yellow, user review 2). It replaces `*grade-desat*` 0.3.
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
- Kenpachi's reiatsu → **REIATSU yellow (2) in every form** (user review 1); Nozarashi makes it
  larger and brighter;
- Breaker → the owner's colour (FIRE / REIATSU) over an INK (3) backing, with a BLOOD edge;
- Burst and guard → STEEL (4); hits and clash → HIT (5); Konpaku → SOUL glass (9);
- Kikon, counter and soul flame → BLOOD (10);
- smoke backing → BLACK SMOKE (11) on the pale ground, or SMOKE (6) against the dark sky.

### 4.1 Yamamoto
| Effect | Redesign | AC |
|---|---|---|
| ▲ **Blade fire** | toon sheath ribbon (FIRE, heat 1 at the base to 0.3 at the tip) + 3 tongue ribbons (w1 = 0, along) + a thin additive core line + 10 `+p-t-blob+`/s scraps peeling off the swing; the swing is drawn as a FIRE `fx-crescent :comet`, held 2 d | the blade reads as a flame with yellow core, orange body and dark-red lower edge; no white blob |
| ▲ **Fire wave** | **one continuous `fx-wall`** along the crescent (5–7 scallops, FIRE) + a BLACK SMOKE backing wall behind it, 20 % taller and curling off the crests + an `fx-crescent :lens` slash at 1.2 m + 6 flame scraps flying ahead + an EMBER sector scorch; envelope (1 3 ∞ 18) | one wall, not a fence; smoke backing visible where the wall crosses the moonlit ground; the wall is the only warm mass in the still |
| Shiranui (built, Phase 5) | toon disc (FIRE, wobble 0.3) + 5 tongues curling back + a BLACK SMOKE wake (threes) + scraps. Charge: anticipation (converging LIGHT shards + `ui-focus-lines`), disc growing in 3 drawings. Built: 6 FIRE / EMBER shards converging on the tip on twos, the disc growing in 6 drawn steps of the charge, focus lines as the charge starts | ball reads as a drawn fireball with a smoke trail |
| Taimatsu (built, Phase 5) | 9 FIRE blobs fanned over the sector, envelope (1 3 4 30), 5 SMOKE puffs at the lip, a ground FIRE sector for 2 d. Built as the `:cone` stamp: each blob is a big FIRE tongue with a small one beside it (discs read as a row of balls) | fan of drawn flames, then perforating smoke |
| Ennetsu Jigoku pillars (built, Phase 5) | wide FIRE ribbon + an inner EMBER spiral stripe (a second ribbon, twisted) + a **crowned top** (a ring of 6 short tongues flaring out); rise on **ones** (3 drawings), crown on twos; erodes from the tip. Built 0.64 m wide (1 m hid the side camera's frame) over an EMBER backing, an EMBER ring at the foot, one light for the ring | 7 crowned pillars, each with a visible dark-red spiral |
| Jokaku Enjo (built, Phase 5) | **no shell**. 3 inward-leaning tiers of tongue rings (12 + 9 + 6 tongues) closing in a spiral over 4 d; the seethe is the tongues boiling on twos; detonation per §5: a fire/ink negative, then a **manga-page** hold where the fire stays orange in a black/white world. Built: the 4 d are 4 drawn steps over the script's closing span; the outer tier over EMBER backings; the detonation is the `:boom` stamp (a FIRE star over an EMBER one, a white core) + a FIRE ground ring + scraps | never a striped sphere; tiers visible at mid-close; the fire is the only colour |
| Bankai | anticipation: 16 tongues pulled into the blade over 3 d + converging shards + ink focus lines; **silence**; burst: a BLACK SMOKE / charcoal (style 3) double ring + 6 charcoal puffs; silhouette reveal on a white card (§5); for the whole 20 s form: **spot-keep mode 4 (hue 10°)**, a charred blade with an EMBER edge line on threes, 4 slow **charcoal ink-wash wisps** for the heat [V: K3]; cracks = ink gashes with an ember core | the reveal still is grey except the ember line; the wisps show charcoal grain |
| Tenchi Kaijin (built; the ash Phase 5) | a pure white hard slash (`fx-crescent`-like UI polygon, tapered at both ends, 2 px ink border) in a true two-tone impact frame (white/ink), on a **black card**; then a manga-page hold; the victim flakes into ASH shards drifting sideways on threes; a silence beat before the slash | there is no translucent grey wedge; the frame has no colour at all |
| Nadegiri / Kyokujitsujin / Kaka (built: Nadegiri Phase 5, the others as their own rows) | HIT `fx-crescent :lens` + an ink-edged scorch line; Kaka: DUST puffs + inked rock debris. Nadegiri: the `:nade` stamp at its S (a draw-side beat): a white lens across his front for 2 d, then an EMBER hairline, and an INK ground strip with an EMBER core racing 8 m out | — |
| Hellfire aura (built, Phase 5; §4 mapping) | 7 FIRE brush tongues behind him (0.8 × his height), 8 short FIRE tongues licking at his feet, an EMBER ring, scraps: a bonfire, apart from West's garb (wrapped all over) | fire the only colour |
| O: ENJO (built, bankai-kikon part 1) | `vfx-line-cut :enjo`: a FIRE ground line along the 1–9 m lane, then 4 `fx-wall`s (2 m each) rising one after another over 16 f, each over an EMBER backing wall (no black), flame scraps, a warm light; erodes over 0.25 s | one lane of walls, fire the only colour |
| O: KITA: TENCHI (built) | take-off: the Hoho vanish streaks; the dash: body and aura not drawn, an ink afterimage (`start-ghost`) every 4 f; the cut: the hit's white star | the flash step reads as afterimages only |
| Bankai East / West (built, bankai-kikon part 2; the user's look) | East: the body as it is (the 4 charcoal heat wisps), the charred blade with its EMBER edge line. West: **wrapped in red flames** (`vfx-aura :garb`: 9 FIRE brush-flame tongues + 5 EMBER inner ones, behind and at the sides so the silhouette stays readable, flame scraps, a warm light), the blade pure charcoal (no ember line, the charcoal smear). A switch crossfades (the new aura flares up 35 % over 0.3 s, the old dies down over 0.35 s) | the two stances read apart at a glance; spot share (S > 0.45, below the HUD) West idle 2.4 %, East idle 1.0 %, NISHI 4.1 %: inside the 15 % budget, no exception needed |
| Burnout (built; the burst Phase 5; **removed with BURNOUT by the Bankai rework 2026-09-27**: only the `:gutter` burst stays, on a broken ward, and the `:ash` aura / grade / blade are deleted) | the burst: the `:gutter` stamp (West's flames sinking for 2 d, then 6 charcoal wisps off the shoulders and an ASH ring) + 5 BLACK SMOKE puffs + 12 ASH shards; the aura crossfades to `:ash`: 3 BLACK SMOKE wisps off the shoulders + ASH flecks (≤ 12/s); East's ember line goes dead ASH; the world's grade loses the ember hue (`:ash` preset: spot-keep with only Kenpachi's yellow); "BURNOUT" in ash grey, the HUD name dimmed; REIGNITE: an EMBER star + the word | traits off must be visible: no warm pixel on a burned-out Yamamoto |
| NISHI / HIGASHI (built; **the moves were removed by the Bankai rework 2026-09-27**: NISHI's ring now marks U raising the ward, HIGASHI's crescent is deleted) | NISHI: a BLACK SMOKE double ring out to 2.6 m + an EMBER inner line + 8 ASH shards, `:heat-flare`; HIGASHI: a white lens crescent 3 m wide across his front (Phase 4: 4.4 m filled the side camera's frame), held 2 d, then an EMBER hairline | — |
| KYOKUJITSUJIN (built) | f18 a white vertical lens slit; f20 an INK gash where the tip bites + a flat 25° sheet (an EMBER sector with a HIT-white core, no dark backing: it read as a black rim) racing 9 m over 3 d, eroding, then ASH lifting along it | no black edge; the only warm mass is the sheet |
| GOKUI GAESHI / the garb / scorch (built; the garb guard since guard v3, the ward since the Bankai rework 2026-09-27 (the same hexagon on a warded hit; no scorch on a block, no ranged flare); Phase 5 redrew the block, the scorch and the flare) | the parry's window: 6 charcoal wisps rising round him; parried: an EMBER star (no charcoal backing star, same reason), a 1 f negative frame, "PARRY"; a hit the garb guard blocks: the guard's hexagon drawn in fire (`:garb-guard`: an EMBER hexagon with a white core, 5 ember sparks flung back, 2 black smoke curls) and a sizzle; a ranged hit it armours: the EMBER star and **the garb flares** (`:flare`: 12 FIRE tongues flung out, an EMBER ring; the aura ×1.9 decaying over 0.45 s); scorch: at the attacker's sword hand a white flash, an EMBER star, 2 BLACK SMOKE curls rising; the garb aura flares ×1.4 while he guards (Phase 5 made it visible: `:garb` scales height and radius by K > 1; before, K was clamped to 1) | the block reads as a block by shape and a burn by value; ember the only colour |
| South (built) | an INK ring crack with an EMBER rim pulsing on twos over the 16 f tell + 5 INK radial cracks; 4 skeleton arms (`:sk-grab`, hips under the plaza; Phase 4: pale bone #D2CEC4 with charred bands #4A4E5C, no shadow disc) claw out, clench, crumble; each throws 1 low DUST puff + 2 rocks; bound: ASH drifting at the feet | — |
| Kikon dash-in (built) | the rush's own travel look (TENCHI afterimages, CHARGE aura ×1.5, LEAP lift) + the BLOOD rush aura, `ui-speed-lines` along the dash, focus lines, "KIKON / GUARD IT!" | — |

### 4.2 Kenpachi
| Effect | Redesign | AC |
|---|---|---|
| ▲ **Reiatsu aura** | **every form: REIATSU yellow** (user review 1): 7 brush-flame tongues **behind** the body (radius 0.5 m, wider than the silhouette; `front-dim` lets only the edges wrap in front) with a dark hairline and a white core line, height flicker per drawing (twos, seed boil) + white flecks rising. **Awakened (Nozarashi)**: taller and denser + 4 inner white tongues + a flat yellow ring + one faint T光 billboard | yellow is the only spot hue on Kenpachi; the body stays readable inside the aura; neutral-still spot share ≤ 15 % with the base aura |
| ▲ **Cleaves** | `fx-crescent :comet` from hilt to tip, 2 d: white leading edge, yellow trailing edge, dark hairline (every form) | the smear reads as a comet, not a banana |
| Nozarashi awakening | pillar rises on **ones**, then holds; 2 flat rings; 8 DUST puffs; a negative frame at the NOME release (no eyepatch in any form since 2026-09-26: the release is the whole first beat); the yellow pillar on a black card; silhouette plus yellow back-rim shot | the first frame where yellow fills > 30 % |
| Nozarashi's cups (v2, built 2026-09-26; Phase 5: the entry beat, the rift drawn, the kendo clips) | cup 1 the base REIATSU aura, one hand; cup 2 the awakened aura, two-handed jōdan, a yellow ring; cup 3 the aura as a pillar (×1.6 tall), on entry the awakening's REIATSU burst + 2 rings, a 1 f negative and a 12 f manga page (yellow kept) **and the grin: his shout face held 0.9 s with the head thrown back** (an overlay pose on whatever clip plays, `face-beat`); DRINK: the REIATSU star reversed; the rift: a REIATSU lens slit with a white HIT line in it at chest height, trembling on twos; when it cuts, a wide white lens over a yellow one and **the ink gash** that stays (`:gash`: an INK lens with a white edge along the rift, a white line in it, 4 ink shards); RYOTE's MEN / KESA / DO / KABUTO-WARI and cup 3's KUKAN-GIRI have their own clips | yellow stays Kenpachi's only spot hue; no persistent grade for cup 3 |
| Reiatsu **see-through** (the user's request 2026-09-28: 「劍八的黃色靈壓有辦法做成半透明嗎？不然三杯的時候真的有點擋視線」) | the toon fx shader gains a **glass level** in its palette lane (pk + 32 × g, g 1..3: `fx-toon.frag.wgsl` writes alpha = coverage × g / 4, so alpha-to-coverage with 4× MSAA keeps g of every 4 samples; g 0, every other shape, is the same math as before). Kenpachi's reiatsu tongues, their white core lines and cup 2's ring take `*reiatsu-glass*` (vfx.lisp): cups 1 / 2 **3 / 4**, cup 3's pillar **2 / 4**; the presence takes the aura's near-camera fade and `*aura-cap*` (`ka`). Without MSAA the aura stays opaque. The tongues already skip the camera side of his body, so the see-through ones are exactly those that stand between the camera and whatever is behind him (the opponent under the behind / portrait camera) | yellow still reads on the dusk ground; RAVEN's G1 stills are byte-identical (g 0) |
| Bankai aura **see-through** (the user, 2026-09-28: 「劍八卍解的紅黑色靈壓也改成半透明的」) | the same glass level on the `:oni` pillar: `*reiatsu-glass*` `:oni` **2 / 4** for the BLOOD tongues and their white cores, `:oni-ink` **3 / 4** for the taller INK tongues behind them (at 2 / 4 the ink dithered into grey: the black-and-red read needs the denser ink). The flecks and light stay; the Kikon rush aura is unchanged | the red-over-black silhouette survives; G1 byte-identical |
| Split the Meteor / Buttagiru | ink gash (a DUST-palette ribbon on the ground with a heavy edge) + a REIATSU core line + a light sheet of 5 LIGHT ribbons for 3 d + 12 inked rocks + 14 DUST puffs (threes) | particles per cut ≤ 20 |
| Sky split | beat 0 (a negative frame for 2 f) → **black card**, silence → the white light band with ink borders + focus lines, held 8 f (`model-hold`, no hitstop) → the existing `*grade-split*` → the ground cut in drawings | — |
| SP2 dash (built, Phase 5) | afterimage sequence (§2.6) every 2 drawings + `ui-speed-lines` (a draw-side beat: a new afterimage every 10 f of the dash's active frames; the speed lines along his facing) | — |
| Breaker (both; built, Phase 5; §4 mapping) | the owner's colour (Kenpachi REIATSU, Yamamoto FIRE, Bankai EMBER) as 7 tongues over 7 taller INK tongues, BLOOD flecks, a steady BLOOD ring and an INK ripple every 0.4 s at the feet; it grows over the strike's startup | — |
| EVOLUTION ready (universal; built, Phase 5) | 5 thin STEEL tongues behind him and white flecks (mono: it was a soft gold glow) | no spot colour |
| O: CHARGE (built) | the REIATSU aura × 1.5 and the BLOOD rush aura; the hit its armour eats: a REIATSU star + the laugh | yellow + the red rush ring only |
| O: LEAP CLEAVE (built) | take-off: a DUST ring + dust; the body drawn up to 1.6 m (`:lift`, a look); landing: a 3 m `:meteor` gash | — |

### 4.3 Universal (▲ all, Phase 2)
| Effect | Redesign | AC |
|---|---|---|
| Hit :cut | mono (HIT). Drawing 1 (ones): a round white flash disc; d2–d3: an irregular 6-spike HIT star + 4 shards along the hit direction; envelope (1 2 2 6); a thin T光 core; the flash light is kept | irregular spikes; gone by f15 |
| Hit :heavy | an 8-spike star (r 0.9) + an `fx-crescent` **impact mark** held 3 d + 6 shards + 3 DUST puffs + a 3 f attacker `model-hold` + a squash smear + 5–8 **ink-blood droplets** (BLOOD blobs, wobble 0.3) thrown along the hit direction | the impact mark is visible for 3 drawings; red only in the droplets |
| Hit :fire | FIRE star + 4 flame scraps | — |
| Counter | BLOOD star + a manga-page frame for 2 f (the world goes black/white, the red stays) + a "COUNTER" brush stamp | red is the only colour in the frame |
| Guard | a **hex-faceted** STEEL shape (`fx-star` with r0 = r1, n = 6) held 2 d + 4 steel shards | a hexagon, not a ring; no warm pixels |
| Guard break | 12 INK shards with BLOOD edges + a HIT star + a 1 f white flash | — |
| Guard crush (built, the guard gauge) | the STEEL hexagon held one drawing, then 12 STEEL shards around a HIT star + a 1 f negative frame, "GUARD CRUSH" | mono |
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
  3 d (built in Phase 6 as one diagonal brush cut and two halves sliding apart over 4 d: §14).
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
  1. NOME: the head thrown back as the reiatsu bursts (negative frame; no eyepatch in any form, 2026-09-26).
  2. A yellow pillar against a black card.
  3. The skull silhouette in the pillar for 2 drawings (built in Phase 6: §14).

The same grammar is applied to `yama-tenchi-cine`, `yama-bankai-cine` (silhouette reveal),
Kenpachi's awakening (silhouette + yellow rim) and Kikon, `soul-break-cine`, and `ko-cine`
(white/ink impact frame + a 20 f hold on the winner + the 勝 stamp on results).

---

## 6. Stage v4: Seireitei ruins at night (notan)

Numbers apply to `stage-env`, `stage.lisp` and `fs_sky_toon`.

- **Why night, not storm** (confirmed by the user at review 1). A storm's rain streaks and grey
  sky would add mid-value noise. Still night air with falling ash keeps the frame calm and
  graphic. The ash doubles as Yamamoto's burnt world, and Kubo uses sky and weather as
  emotion [V2: K2]. Rain stays available as an *emotional* cinematic accent (e.g. the K.O.),
  not as the base.
- **Sky**:
  - `fs_sky_toon` runs from zenith #1A1E2A to horizon #363B4C (V1; review 1 — was #08090E →
    #1C2030);
  - **a huge moon**: `sun-size` 6 (about 10°), elevation 9° (was 14°: cut off by the pair camera),
    #D6DAE0 (was #EEF0F2: the fighters' white must stay the brightest), a flat disc with 2 faint
    flat halo rings and no bloom;
  - the moon's azimuth sits behind the arena centre as seen from the default pair view, so
    fighters often stand against it (Kubo's backlit-moon composition [I]).
- **Ruins** (walls, houses):
  - drawn as **flat cold-grey V1** (review 1; was flat black #101118): ring walls #464B5C,
    footings and rubble #30343F, house walls #484D60 (#3E4354 far ring), roofs #363A48, beams
    #2C303C, far skyline #343846 / #262A34, burnt frames #2E3240;
  - moon-facing caps and ridges are lit #50566A, so a thin edge light reads the silhouette;
  - no stage hulls; 0.6 × fog.

  The skyline reads as grey paper cut-outs against the slightly darker sky.
- **Burning buildings removed.** The flames, smoke, halos and the 2 stage fire lights go.
  `*st-fires*` becomes empty, which frees about 160 particles and 2 light slots.
- **Plaza** (rebuilt, Phase 1a):
  - one flat disc of moonlit stone, **V2 #767D8E** (review 1; was V3 #BCC1CC);
  - 8 **ink cracks** (thin dark ribbons #262A36, hand-placed data);
  - faint stone joints only in the outer ring (#6A7182, ≤ 1 px);
  - the curb ring #5C6272, the ground outside #3C4150.

  The foreground is a near-blank mid-grey page: empty, but no brighter than the figures on it.
- **Falling ash**: the existing ash particles become toon ASH shards (white, 60 live), drifting
  on threes. Embers are removed (warm is spot-only).
- **Blob shadows** become **hard ink ellipses** under the fighters (INK palette, crisp edge):
  the Kubo cast shadow.
- **Fog**: #363B4C (= the horizon), density 0.012, height falloff unchanged. The far ground fades
  into the horizon tone.
- **Light**: `moon_dir` comes from the moon (behind-left, 14°) for stage shading. Characters keep
  the camera-space key (§2.1). The 2 per-pixel stage lights now come **only from effects**, so a
  fire wave throws a warm pool onto the white ground (spot colour, very readable).
- **Grade**: bloom threshold 0.97 (effect cores only), vignette **0.25** (was 0.35), no global
  desaturation (the palette itself is desaturated). Bankai uses spot-keep mode 4.
- **Destruction** (built in Phase 6: §14): ink scorch and crack marks that persist for the round,
  and inked rock debris that rests for 6 s. Dark marks on the mid-grey page.
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
| R9 | Notan world too dark or too flat for gameplay reading | resolved at user review 1: one balanced mid-dark world, the fighters carry the strongest contrast (toon_check: world gap ≤ 75, fighters' span ≥ world span + 60); keyline and white strokes on black parts (1b) |
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
| **1a Notan world + toon characters** | §6 (sky, moon, black ruins, flat plaza with ink cracks, remove fires, ash, ink blob shadows, fog, grade, camera 0.8); §2.1–2.3 (`fs_toon`, `fs_sky_toon`, cold HSV shadows, gradient, jitter off, analytic normals); §2.5 v4 palettes | 2 d | duel still (revised at user review 1): the world is balanced (median luma above / below the horizon differ by ≤ 75), in the cold mid-dark range (world luma p2 ≥ 20, p98 ≤ 150, the moon excepted), and the fighters' luma span beats the world's by ≥ 60; world saturation ≤ 0.12; a lit haori pixel = #F0F0EC ±3; robe pixels ≤ #16161E (+3); every face shows only its 2 tones (gradient masked); fight frame ≤ 0.75× today. **User review 1** |
| **1b Ink** | hull (§2.4), grey keyline on black parts, red-brown on skin, the ink art pass, **white-on-black inner strokes** and ink strokes, neutral face shapes | 2.5 d | a continuous silhouette on both fighters against ground *and* sky (the keyline is visible on the sky); thinner overlap lines; no haori seam lines; hull cost ≤ +5 % |
| **2 fx-toon + universal + punctuation** | §3 (A2C `RP_FXT`, WGSL palettes v4, charcoal style, value-opposite edges, envelope, fx clock, primitives, 2 particle kinds); §4.3 universal effects; `RP_COMP_FX` modes 1–4; focus lines, speed lines, `ui-ink-splash`; `model-hold`; squash smear; `*key-ease*`; `*shake-hz*`; `silence` | 3.5 d | §4.3 row ACs; hits are mono (no spot pixels); seeds change only on their rate's ticks; nothing changes while paused; manga-page mode keeps FIRE and BLOOD pixels and turns the rest two-tone |
| **3 Signature effects** | ▲ rows (blade fire, fire wave wall, yellow reiatsu aura in every form, cleave comets) + layering | 2 d | row ACs; spot-pixel share ≤ 15 % in the neutral still (Yamamoto's blade fire and Kenpachi's base yellow aura included), and FIRE dominant only while Yamamoto's moves run; live particles ≤ 500. **User review 2** |
| **4 Cinematics + typography** | §5 (beat 0, black/white cards, ink splash, inversion cuts, silence, silhouette shots, FOV, holds); Bankai reveal; 8 cinematics re-staged; §4.4 glyph tool + `glyphs.lisp` + licence file; vertical captions, hanko, 勝 | 3 d | every Kikon: beat 0, ≥ 1 card beat, ≥ 3 cuts, ≥ 1 inversion (negative + manga page), ≥ 1 silence hold ≥ 8 f, a vertical brush caption; `:len` unchanged; the Bankai still shows a grey world with only the ember line red. **User review 3** |
| **5 Remaining effects + faces** | all non-▲ rows of §4.1 and §4.2; expression swaps (`:face-shout`, `:face-hurt`); per-clip pose-to-pose re-authoring of the attack clips | 5 d | row ACs; each fighter shows 3 expression states in the gallery |
| **6 Polish** (done, approved at user review 4) | destruction marks and resting debris; caption slice exit; skull in the Nozarashi pillar; quantised fog bands (if they help the white page); rain accent for the K.O.; chromatic aberration or fisheye **only if** user review 3 or 4 asks; P10 atlas **only if** the charcoal style is judged too thin | 3 d | **User review 4** (final) |

**Total ≈ 21.5 d** of agent work, plus four user reviews. With parallel agents the limits are
engine syncs, SwiftShader review loops and the review points (tech §9.34). Phases 3 and 5 split by
character between two agents.

---

## 10. Not done (and when to add it)

- Post-process edges: only if the stage ever needs lines.
- The procedural atlas (P10): judged not needed at Phase 6 (§14): the charcoal grain reads at gameplay distance and in
  the Bankai close-ups; add it only if a review calls the charcoal thin. It needs a texture binding in `fs_fx_toon`
  (an engine change).
- Quantised fog bands: tried at Phase 6 and rejected (§14): on the review-1 mid-grey plaza they draw a false contour arc
  across the page under the fighters. Revisit only if the plaza turns white again.
- Chromatic aberration and fisheye: not built; no review asked for them (+3 ms measured for always-on CA).
- The per-vertex threshold float (R1 escalation).
- Halftone screen tone (Hi-Fi Rush, not Storm [V2: S20]; Kubo also reduced grey tones in favour of pure black and white [V2: K1], so v4 agrees).
- Real motion blur.
- Refraction heat haze.
- A hair rig (the lift of cup 3's grin: the rising aura tongues stand in); a sound for the K.O. rain.
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
1. **The four screenshot reviews** (after Phases 1a, 3, 4 and 6). Reviews 1-3 are answered (§13, §14); **review 4**, the
   final one (Phase 6: `tests/shots/style-final-gallery.png`, `style-6-gallery.png`, `style-6-pairs.png`), is approved
   (§13 round 7). No user gate remains.
2. Decided at review 1 (§13 round 5): night stays; Kenpachi's reiatsu is yellow in every form;
   the world is one balanced value range; the characters get realistic proportions.
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
- Kenpachi against the dark sky: the keyline plus white strokes are checked after 1b.
- A white page with low value contrast against the white haori: the haori shadow is V2 cold
  grey, and the ink hull is near-black. The Phase 1a AC checks the haori-to-ground separation.
- The spot share rising during fire moves: Yamamoto's fire is *meant* to dominate while his moves
  run; the ≤ 15 % AC applies to neutral stills only.

### Round 5: the user's review 1 (Phase 1a stills)

| # | User's words (translated from zh-TW) | Decision | Consequence |
|---|---|---|---|
| 1 | "The ruins are too dark and the arena floor too bright; balance the two so they are consistent." | the world becomes one cold mid-dark value range; the figure (black robe vs white haori) keeps the strongest contrast | §A.1 rules, §6 stage values (sky #1A1E2A → #363B4C, ruins V1 #343846 – #484D60, plaza V2 #767D8E, moon #D6DAE0), the 1a acceptance of §9 and `tools/toon_check.py` (balance / range / figure-contrast replace "≥ 55 % V2/V3 ground" and "sky ≤ V1") |
| 2 | keep the still night | night, no storm | §6 |
| 3 | "Keep Kenpachi's reiatsu yellow." | REIATSU yellow in every form | §A.2, §3.3 palette 2 / 3, §4 mapping and the Kenpachi rows; the neutral spot budget (≤ 15 %) now includes his base aura |
| 4 | "Change the characters' proportions to normal, realistic size instead of the current chibi proportions." | realistic adult proportions (anime-realistic, TYBW): narrow heads, lean / broad but not boxy torsos, long limbs, big hands; heights and hurt cylinders unchanged | `defbody :girth` (per-joint shape scaling, duel/lisp/body.lisp) + `:props`; numbers in §14 |

### Round 6: the user's review 2 (Phase 3 stills)

| # | User's words (translated from zh-TW) | Decision | Consequence |
|---|---|---|---|
| 1 | "I think the effects look better with the black edge lines removed." | no dark ink edge on any toon effect; energy keeps a coloured edge (its shade) + white core, dark shapes keep their white edge | §3.3 (the edge column and the note under the table), `fx-toon-pal.wgsl` edge entries, the fire wave's backing wall → EMBER |
| 2 | (default approved) keep the yellow FIRE core #FFE483 | kept | — |
| 3 | (default approved) keep the Nozarashi aura at 1.05 × | kept | — |
| 4 | (default approved) Kenpachi's base-form yellow aura always on | kept | — |
| 5 | (default approved) keep the fire wave's warm ground light circle | kept | — |
| 6 | (default approved) Bankai's grey grade keeps Kenpachi's yellow | the spot-keep mode keeps a second hue | `grade-impact :keep-hue-2`, the `:spot` preset keeps 10° and 48° (§3.6) |
| 7 | (default approved) the behind camera may hide Kenpachi's swing smear | accepted | — |

**Position reversed:** round 4's "mono energy shapes need a dark hairline to read on the white ground". On the
cold mid-grey ground of round 5 (V2 plaza), white hits and yellow reiatsu read by value without it (see the
review-2 stills).

### Round 7: the user's review 4 (Phase 6, final)

The user approved the whole restyle as shown in `style-final-gallery.png` ("非常完美", 2026-09-26) and asked for no
changes. The review sheet's open questions therefore stay at the built defaults: the destruction marks as built (20 max,
cleared at resets), the shout / hurt face accents kept, the near-camera pillar thinning as built, no rain sound and no
rain on the results screen, and the fog bands rejected. The restyle (Phases 0-6) is closed.

---

## 14. Progress log

### Phase 0: harness (done)

- **`tools/run.mjs --fixed-dt MS`**: a virtual clock. Every animation frame advances
  `performance.now` / `Date.now` by exactly MS (a fixed epoch), the next frame waits until the GPU
  finished the previous one, script times and `--secs` are virtual, and the page is held while a step
  (a screenshot) is applied. The same binary and script give **byte-identical** screenshots: the
  noise floor of every frozen still is 0 px. Three causes of flaky stills were found and fixed on the
  way: SDL skips drawing a frame whose swapchain texture is not ready, so a screenshot showed an older
  frame than the state; a headless window can lose focus and both games pause on focus loss (focus
  emulation on); a fixed random debugging port could hit a leftover Chrome (Chrome now picks it).
  `run.mjs` also exits 1 on `WebGPU:` validation errors and failed pipelines (R3).
- **`tests/style-gates.py`**: `raven` (G1: RAVEN title + bot-played wave frozen stills, base twice =
  noise floor, new once; cons/frame), `rc` (G1: RAVEN's ECL C, function by function, with L / VV /
  gensym numbering folded), `cvc` (G2: the three `duel-cvc-*.json` result + hash lines vs
  `tests/style-cvc-ref.txt`, captured on the unchanged tree), `perf` (G1/G3: A B A B A B real-time
  runs, median frame ms, startup heap, page-to-first-frame), `smoke` (WGSL smoke: run.mjs exit 0),
  `duelstill` (the frozen duel still: `duel-vfx` scene 17 NEUTRAL, stage fx off, frozen scene clock,
  plus the same frame without fighters = the fighter mask, and a "flat" pair without gradient, fog or
  vignette for palette checks).
- **`tools/toon_check.py`**: value steps V0–V4, world chroma, spot share, sky / ground split (horizon
  estimated), fighter palette tones (lit + `shade_of`), lit haori, robe; `--ac` applies the 1a
  thresholds. Two measures were adapted to what the design means (both documented in the tool):
  *world saturation* is **chroma** (max − min channel), because HSV saturation flags the design's own
  cold greys (V1 #3A3E4C has S 0.24); *sky ≤ V1* is "≥ 80 % of the sky pixels are V0/V1", because
  the moon is V4 by design.
- **`tests/style-shots.py`**: the review still set, after and before, under the virtual clock.
- `tests/engine-check.lisp`: the 1a engine checks (below) and a toon scene (`ec-toon.png`) that draws
  every new pipeline, including a mirrored toon draw (`RP_TOON_CW`).
- Gates on the unchanged copy: G1 stills identical (noise 0), C 716/716 identical, G2 3/3, smoke 3/3,
  perf A/A 1.017, heap 103.4 MB.

### Phase 1a: notan world + toon characters (done, awaiting user review 1)

Built as §2.1–§2.3, §2.5 (palettes) and §6, with these differences:

| Design text | Built | Why |
|---|---|---|
| slots 11 RP_TOON, 12 RP_TOON_CW, 16 RP_SKY_TOON | 11, 12, **13** RP_SKY_TOON | no holes; later phases append 14 RP_HULL, 15 RP_HULL_CW, 16 RP_FXT, 17 RP_COMP_FX |
| `fs_toon` in `lit.frag.wgsl` | its own files: `toon.vert.wgsl` (`vs_toon`), `toon.frag.wgsl`, `toon-io.wgsl`, `sky-toon.frag.wgsl` | `lit.vert/frag.wgsl` and `sky.frag.wgsl` stay byte-identical; only the shared `Frame` (160 floats) and `Draw` (+`toon`) structs grew |
| `shade_of` per pixel, HSV of the linear colour | **per vertex** (a face has one colour), HSV of the **sRGB** colour | the worked values of §2.2 (#F0F0EC → #9CA3B4) are sRGB; linear gives #C5C8CF, far too light for notan. Per pixel, the HSV + 2 pows cost the fight 0.83× instead of 0.68× |
| shadow-side tint: `draw-fighter` + a new `nearest-light-rgb` | computed in `vs_toon` from the selected lights (strongest within 4 m of the part's origin, × 0.35) | no CPU cost, no engine helper, and no ordering problem (effects add their lights after the fighters are queued) |
| `draw-mesh` toon keywords | `:toon` takes an f32vec of the 4 lanes | 0 B per call (float keywords box) |
| `*part-jitter*` only | + **`*part-smooth*`** (NIL default) | smooth normals on `:sphere` / `:cyl` would change RAVEN's bodies |
| moon elevation 14°, #EEF0F2, vignette 0.35 | **9°**, #F4F6F8, vignette **0.25** | at 14° the pair camera (pitched ~19° down) cut the moon off at the top; at 9° it rises behind the rooftops, so the ruins stand as black cut-outs against it. Vignette 0.35 greyed the moon to #C4 |
| house walls #2A2C36 | #1C1E28 (#181A22 far ring), ruins drawn with 0.35 × fog | #2A2C36 plus fog read lighter than the sky behind them; the ruins must stay the darkest mass |
| blob shadow: hard ink ellipse | a flat 24-gon ink disc mesh (#14151C) drawn as a toon stage draw, r = 1.2 × hurt radius, shrinking with height | crisp edge without a new fx primitive; 1.5 × read too heavy |
| toon draws must be opaque | an `alpha` < 1 toon draw (the Hoho fade) falls back to the lit shader | Phase 2's afterimage replaces the alpha fades |

Also done: weapons and props desaturated (Ryujin Jakka's guard and wrap, the cane, Nozarashi's brass
and tassel) so only the three spot hues stay saturated; the mirror tint is #D8E2F2; the stage's
per-draw fog scale is 1 on the plaza; `*cam-close*` 0.8 in `duel/lisp/camera.lisp` (pair distance and
behind distance). The ember cracks of Bankai (`stage-crack-add`) are unchanged (Phase 3).

**Measured (final build).**
- G1: RAVEN title and wave stills byte-identical to the base build (noise floor 0 px both); ECL C:
  704 of 716 functions identical, the 12 changed are exactly the touched ones (%MB-TRI, BUILD-PARTS,
  BUILD-SHAPE, DRAW-MESH, DRAW-PARTS, END-FRAME, FILL-FRAME-UNIFORMS, MAKE-ENVIRONMENT,
  MAKE-MESH-BUILDER, MB-CYLINDER, MB-SPHERE, RENDER-INIT) + FILL-TOON-UNIFORMS added; RAVEN
  cons/frame 17 367 B = base; RAVEN title frame time 129.6 → 125.5 ms (0.97×, inside the ±10 % noise).
- G2: yy `winner P1 konpaku 7-0 ticks 6887`, yk `winner P2 konpaku 0-1 ticks 7298 secs 121.6`, kk
  `winner P2 konpaku 0-1 ticks 8034`; every hash line identical.
- G3: 100 toon `draw-mesh` 0 B, 100 `fill-toon-uniforms` 0 B; SOUL DUEL cons/frame 12.5 → 10.9 KB,
  live particles ~330 → ~140, draws 46 → 47; startup heap 103.4 → 103.1 MB; page to first frame
  3370 → 3390 ms (+0.6 %).
- **Fight frame 48.7 → 31.9 ms = 0.65×** (real-time CPU vs CPU, median of 3 A/B, SwiftShader; AC ≤ 0.75×).
- 1a acceptance (`tools/toon_check.py --ac` on the frozen duel still): ground V2/V3 93.9 % of the
  pixels below the horizon (≥ 55 %), sky 93 % V0/V1, world chroma p99 0.063 (≤ 0.12), spot 0.00 %,
  flat still: 99.8 % of the fighters' interior pixels are a lit or designed-shadow palette tone,
  lit haori exactly #F0F0EC, robe #16161E with no V0 pixel brighter; gameplay stills (HUD rows
  excluded): ground 85–95 %, sky 97–98 %, chroma p99 ≤ 0.082.

**Open for 1b and later.** No ink hull, keylines or white-on-black strokes yet, so black hair and
robes merge with the black ruins and the white haori sits on the pale ground without a line (1b).
Faces have no eyes (1b neutral face shapes). Effects are still the soft additive ones (Phase 2–3):
Yamamoto's blade fire reads as a white-hot blob. The HUD (not part of the restyle so far) was made
for a dark frame: the select screen's grey names and hint line nearly vanish on the white page.


### Revision after user review 1 (§13 round 5)

- **Values** (old → new): sky zenith #08090E → #1A1E2A, horizon / fog #1C2030 → #363B4C, moon
  #F4F6F8 → #D6DAE0; ruin walls #101118 → #464B5C, caps #3A3E4C → #50566A, house walls #1C1E28 →
  #484D60, roofs #101118 → #363A48, ruins fog 0.35 → 0.6; plaza #BCC1CC → #767D8E, joints #9CA2AE →
  #6A7182, cracks #101018 → #262A36, curb #7A8090 → #5C6272, outside ground #2A2C36 → #3C4150.
  Frozen duel still: median luma above / below the horizon 20 / 190 → 50 / 112 (gap 151 → 62);
  world luma p2..p98 13..180 → 39..120; fighters' span 217 vs world 81.
- **toon_check `--ac`**: "≥ 55 % V2/V3 ground" and "sky ≤ V1" are replaced by *world balanced*
  (gap ≤ 75, skipped when no sky is measured), *world in the cold mid-dark range* (p2 ≥ 20,
  p98 ≤ 150, the moon excepted) and *fighters carry the strongest contrast* (span ≥ world span +
  60). The flat measuring mode (duel-vfx 3005) also removes the shadow disc's fog.
- **Kenpachi's reiatsu** is yellow in every form (docs only: the auras are Phase 3; the current aura
  is already yellow).
- **Proportions** (`defbody :girth`, per-joint shape scaling in the joint frame, plus `:props`;
  measured by duel-view 4005, standing, no hunch; heights and hurt cylinders unchanged):

  | | Yamamoto old → new | Kenpachi old → new |
  |---|---|---|
  | crown (untilted head shapes) | 1.705 → 1.705 m | 2.09 → 2.04 m (scale 1.13 → 1.07) |
  | head length / heads | 0.209 m, 8.2 → 0.209 m, 8.2 | 0.294 m, 7.1 → 0.250 m, 8.2 |
  | head width | 0.190 → 0.152 m | 0.240 → 0.159 m |
  | shoulder joints | 0.418 → 0.418 m | 0.646 → 0.508 m (shoulders 1.3 → 1.08) |
  | fingertips / height | 0.42 → 0.37 (arms 1.12) | 0.39 → 0.40 (arms 1.06 → 1.1) |
  | hips / height (legs) | 0.52 → 0.52 | 0.50 → 0.53 (legs 1.1) |
  | other | hunch 22° → 14°, chest x 0.86, hands x 1.2–1.3 | chest x 0.8, neck longer, hands x 1.2, limb shapes x 1.1 long |

  The head *length* was already realistic; the chibi read came from wide heads and hair, boxy wide
  torsos, short arms (Yamamoto), short legs (Kenpachi) and small hands. Weapons stay in the hands
  (the grip is the hand joint), two-handed grips still meet (KE-F2), Ikkotsu / Kaka / stances /
  run / lose / win strips checked, no floating feet (make-rig-proportions keeps the feet on the
  ground). The sim reads no joint (G2 unchanged); joints feed only trails and blade fire.
- Gates after the revision: G1 stills identical, G2 3/3, fight frame 43.5 → 30.5 ms (0.70×),
  heap 103.1 MB, cons 10.9 KB/frame.


### Phase 1b: ink (done)

Built as §2.4 and §2.5 (inner strokes, faces), with these differences:

| Design text | Built | Why |
|---|---|---|
| slots 13 RP_HULL, 14 RP_HULL_CW | **14, 15** (1a put RP_SKY_TOON at 13) | appended, no holes |
| `vs_hull` / `fs_ink` in the lit shader files | in `toon.vert.wgsl` / `toon.frag.wgsl`, output `ToonV` | the toon files own every toon entry; the lit files stay byte-identical |
| "thinner lines where parts overlap" by the facing taper alone | the taper **plus a depth push**: after the width offset the hull vertex moves `ink-push` (1.2 cm) away from the camera along its view ray (screen position unchanged) | a line now shows only where the surface behind is more than 1.2 cm farther: full against the ground and sky, thinner or none where parts nearly touch, and **no line on the seams of abutting panels** (coplanar or near-coplanar faces). 3 cm hid the beard against the white haori (white on white needs the line) |
| ink art pass: `:ink 0` on the inner / side haori panels | the haori over the torso rebuilt as **one rounded white shell** per joint (`:bevel`) with the black robe (and Kenpachi's bare chest between two lapels) at its open front; the skirt panels keep their own hulls | 15 abutting boxes read as an open crate at 3/4 view, with or without seams; the push removes what remains (the 3/4 and back stills show no seam lines) |
| `:ink k` per shape, 0.6 under 10 cm, 0 under 4 cm | the size is the shape's **middle extent** (second largest side of its box in the joint frame) | a 20 cm × 5 mm stroke is "under 4 cm" in the sense that matters; strokes, eyes, brows, scars, lids need no `:ink 0` |
| ink colour per shape: skin #3A1610, other = the body's `:ink` | `build-parts :ink` = an alist by colour key: skin / skin-d #3A1E1A, black / hair keyline #4A5062, the rest #101018 (`*body-ink*`, duel body.lisp) | the keyline and skin rules are data; §2.5's table values |
| the hull built in its own `:load` step | built with the solids by `build-parts` (the shape ranges exist only then), **one `:load` step per body** (`body-load-steps`) | the same heap effect (the collector runs between bodies): startup heap 103.1 MB = 1a |
| mirror P2: ink tint #9AB0FF, keyline #5A6A8A | the hulls take the draw's tint (P2 = the cold #D8E2F2) | one rule; the cast shows on the grey keyline |
| katana blades `:ink 0` | as designed (Ryujin Jakka, Zanka, Kenpachi's katana: blade and hilt are separate `defweapon` sections, `(:solid :ink 0 …)`); hilts, the cane and the Nozarashi slab get hulls (c 0.8) | |
| faces "unchanged from v3" | **new heads**: a smooth skull sphere, a flat-fronted face box, flat face shapes (tag `:face-neutral`): Kenpachi's slanted lids, small pupils and angry brows, the scar through the left eye, the grin (dark mouth, teeth, corners up), both eyes under the eyepatch (Nozarashi shows them); Yamamoto's drooping slit eyes with lower lids under the long brows, the X scar, beard strands and the moustache parting in ink | the 1a heads were bevel boxes with no eyes; the user asked for realistic anime figures, not boxes. Head shapes are now plain metres (the `:head` girth factors were baked in) |
| — | **rounder bodies**: hakama legs as flaring smooth 10-sided cylinders, Kenpachi's bare arms as tapered 8-sided limbs with round deltoids, elbows and biceps, bevelled hands and tabi, Kenpachi's top hair spike removed | boxes with outlines still read as boxes; the round parts give the toon terminator real curves. Heights, rig and hurt cylinders unchanged |
| white strokes: Yamamoto 3 robe folds + sleeve edge, Kenpachi 4 hair highlights + 2 robe folds | as designed (`:fold` #D8DCE4 thin boxes), the robe folds on the hakama | |

Also: the face close-up camera in duel-view (`6200+i` front, `6210+i` from 35°) and in the still set
(`-closeup`, `-closeup34`), the 3/4 and back stills of the ink art pass (`yama-34`, `ken-34`, `-back34`),
duel-vfx `3006` (shadow discs off) and `toon_check.py --outline` (below); the duel-vfx flat mode now
restores the stage's vignette (it restored 0.35). HUD (`hud.lisp`): on the select screen the unselected
name and the unselected CPU / camera row are dark ink (`*dim-ink*` #242630) instead of the light grey
that vanished on the V2 plaza, the key hint line and the title's credit line are white with a shadow.

**Measured (final build).**
- G1: RAVEN title and wave stills byte-identical to the 1a build (noise floor 0 px); ECL C: 713 of 717
  functions identical, changed BUILD-PARTS, DRAW-PARTS, RENDER-INIT (2 pipelines) and RAVEN's
  BUILD-BODY (its call of the now-keyworded BUILD-PARTS), added BUILD-SOLID, MB-HULL, SHAPE-INK-K;
  RAVEN cons/frame 17 367 B = base; RAVEN title frame 126.1 → 115.9 ms (0.92×, noise).
- G2: yy `winner P2 konpaku 0-1 ticks 9545`, yk `winner P1 konpaku 2-0 ticks 9780 secs 163.0`, kk
  `winner P2 konpaku 0-4 ticks 8035`; every hash line identical to `tests/style-cvc-ref.txt`.
- G3: 100 `draw-parts` with hulls cons 0 B (engine-check, 64/64); SOUL DUEL cons/frame 11.9 KB = 1a;
  draws 47 → 87, triangles 10.4 k → 14.5 k; startup heap 103.1 MB = 1a; page to first frame 3410 →
  3530 ms (+3.5 %); WGSL smoke green on duel, game, duelview, duelvfx, echeck (ec-toon.png draws a
  hull in both windings).
- **Hull cost: fight frame 29.9 → 30.4 ms = +1.9 %** (real-time A B A B A B, median of 3; AC ≤ +5 %).
- Continuous silhouette (`toon_check.py --outline`: edge pixels of the fighter mask with ink within
  2 px, shadow discs off): frozen duel still 84.4 % against the ground, where every miss is on the two
  unlined katana blades or a sole on the ground (the miss map); duel-view stills with the fighters
  against the ruins and the sky: 92.6–94.5 % above the horizon, the misses being the blades and ash
  flakes that moved between the two shots. The grey keyline shows against the dark sky on Kenpachi's
  hair and the black robes.
- Thinner overlap lines: the facing taper (0.45–1 × width) and the push. The effect is modest: lines
  thin or break only where the part behind is within about 1.2 cm (panel seams, sleeve on hakama, hand
  on hilt); an arm crossing the torso 10 cm in front keeps a full-width line, as in Storm.
- The 1a acceptance still holds on the 1b still (`--ac`: chroma p99 0.094, gap 62, range 39..120,
  fighters' span 217 vs 81, spot 0 %; 99.7 % of the flat still's interior fighter pixels are a palette,
  shadow or ink tone).

**Open.** The katana blades have no line (by design); on a white card (Phase 4) they may need one.
Yamamoto's sleeves and haori skirt are still flat boxes (kimono sleeves are rectangular, so they
read), and his hunch points his face at the floor in level close-ups. Hull lines are 1.8 px at 720
lines as designed; if the user wants a heavier Storm line, `ink-px` is one number.



### Phase 2: fx-toon, universal effects, punctuation (done)

Built as §3 (the toon batch, palettes v4, charcoal, value-opposite edges, envelope, fx clock, primitives,
2 particle kinds), §3.6 (`RP_COMP_FX` modes 1–4, focus / speed lines, ink splash, `*shake-hz*`,
`silence`), §2.6 (`*key-ease*`, `model-hold`, the squash smear, the Hoho afterimage) and every §4.3 row,
plus step / dash dust and the Kikon rush (a dedicated `:kikon` aura and a red ground ring replace the
twice red-tinted Evolution aura, its red light and the red shockwave). Engine: `fx.lisp` (toon section),
`render.lisp` / `render.c` (`*fx-toon*`, slots 16 `RP_FXT` and 17 `RP_COMP_FX`, `grade-impact`),
`fx-toon.vert/frag.wgsl`, `fx-toon-pal.wgsl`, `fx-toon-io.wgsl`, `composite-fx.frag.wgsl`, `anim.lisp`
(`*key-ease*`). Game: `vfx.lisp` (stamps: the drawn one-shots), `feedback.lisp`, `main.lisp` (hold, smear,
afterimage, the Burst beat), `cinema.lisp` (`impact-frame`, `focus-lines`, `silence`, `back-rim`), the HUD's
time on the fx clock, debug 2326 (force a clash). Differences:

| Design text | Built | Why |
|---|---|---|
| slots 15 `RP_FXT`, 17 `RP_COMP_FX` | **16, 17** | appended after 1b's 14–15 |
| `P: array<vec4f,3>` (48 B) | **4 vec4** (64 B): the RP_COMP lane, mode + threshold + keep-sat + keep-hue, ink, paper | ink rgb and paper rgb need a vec4 each |
| charcoal = "seed flag" (≥ 50 in the first draft) | seed **+1000** | toon particle seeds (slot × 0.618) and per-drawing seeds passed 50 and turned puffs into charcoal grain |
| the `\|uv\|` field for every shape | stars, polygons and shards are **fan shapes** (palette + 16): the field is the heat lane, 0 at the centre, exactly 1 on the straight outline | `\|uv\|` interpolated between two rim directions dips below 1 on a straight edge (cos 15°), so the ink band vanished between vertices |
| `fx-star … heat seed a`, `fx-crescent … profile heat seed a` | the heat argument is WOBBLE, plus a PUSH key; crescents run heat 0.2 (tail) → 1 (blade) themselves | fans use heat as their field; a crescent's heat is its along coordinate |
| edge 1.0–1.6 px @720, weight 0.4–1.3 | × 1.8, weight 0.7–1.5 (1.3–4.3 px) | at 1.0–1.6 px the stars' dark hairline did not read on the V2 ground: white clip-art stars |
| core `hc < 0.42 k` | 0.2 k on dark bodies (INK, BLACK SMOKE) | the white "core line" of ink shards covered half the shard |
| `fx-billboard :toon` for discs and puffs | + `fx-disc` (a macro, 0 B) | `fx-billboard` is a function: its float arguments box (40 B a call) |
| — | `fx-wall` (Phase 3's fire wave) is in, minimal: a vertical strip with a scalloped top, no end outlines | §3.4's primitive list; Phase 3 refines it |
| the envelope returns values | `(fx-envelope (scale k flash phase) (age f g h o :anticipate a) body)` binds them | returning floats boxes |
| hit drawing 1 = a round white flash disc (+ T光) | a **jagged** round burst (12 short hashed spikes, ink rim); the additive T光 only as a small core while it grows | a flat disc with a glow read as a glowing ball, not a drawing |
| Hit :heavy "red only in the droplets"; §9 "hits are mono" | heavy hits keep their 5–8 BLOOD droplets; `spot` checks every other mono effect for 0 spot px, the heavy one outside its droplets | the two ACs conflict; the row AC is the specific one |
| toon particles at `pos − vel·min(mod(clock, rate/24), age)` | + presence from the life left when the drawing began; a particle born inside a drawing shows from the next one | else births and fading changed every frame (the `ticks` check caught it) |
| the defender silhouetted with a white back-rim for 3 f | `back-rim`: `env-cin-rim` white + `toon-threshold` 1.5 for 3 f — **both** fighters | `F.cin` / `F.key.w` are per frame; per-draw lanes are not worth it for 3 f |
| `silence`: music to 0.1, suppress the script's `play-sfx` | the music bus × 0.1 and the sfx bus muted for the beat (the mixer's bus gains, `au_set_volume`) | no engine change; a bone sound inside a silence (Phase 4) needs a bus of its own |
| `*fx-clock*` a special float | an f32vec `[0]` + `fx-clock` / `fx-clock-advance` | a special float boxes on every write |
| hold / smear | `model-hold`, `model-smear` (+ dir), `model-ghost` (+ age): the Hoho afterimage (white, then hull-only ink) is drawn from a copy of the vanish pose smeared sideways; a body with alpha < 1 is not drawn | §2.6, no alpha < 1 body |
| — | the HUD's animation (`hud.lisp`, the stage's cracks) on the fx clock, `(hud-dt)` 0 while paused; shake, camera and ash take the effects' dt | "nothing changes while paused" |
| — | `tools/build.lisp` compiles without source annotations and runtime docstrings | this phase's code crossed a Boehm heap growth step at load (103 → 119 MB, budget 110); see ARCHITECTURE "Runtime model". Heap now **57 MB** (SOUL DUEL and RAVEN) |

Bankai's spot-keep grade (mode 4, hue 10°) exists and is in the stills (`impact-spot-keep-*`), but `kit-grade`
still drives `*grade-desat*` 0.3: wiring the form to it goes with its ember line (Phase 3 / 4). The sword trail
is still the soft additive `fx-trail` (the comet smear is Phase 3's cleave row).

**Measured (final build).**
- G1: RAVEN title and wave stills byte-identical (noise 0 px); ECL C 703 of 720 functions identical — changed
  %FX-RIBBON, BEGIN-FRAME, CLIP-SAMPLE!, END-FRAME, FILL-TOON-UNIFORMS, FX-BILLBOARD, FX-CLEAR, FX-DECAL,
  FX-DRAW-PARTICLES, FX-LINE, FX-RING, FX-RINGS-UPDATE, FX-SECTOR, FX-TRAIL, MAKE-ENVIRONMENT, RENDER-INIT,
  SHAKE-UPDATE (the 3-way `with-fx-verts`, the ring palette, toon lanes, `*key-ease*`, `*shake-hz*`), added the
  10 new functions; RAVEN cons/frame 17 367 → 17 369 B; RAVEN title frame 100.5 → 102.2 ms (1.017×, noise).
- G2: yy `winner P2 konpaku 0-1 ticks 9545`, yk `winner P1 konpaku 2-0 ticks 9780 secs 163.0`, kk `winner P2
  konpaku 0-4 ticks 8035`; every hash line identical to `tests/style-cvc-ref.txt`.
- G3: 0 B for 12 rounds of every engine toon primitive, `fx-draw-particles` with toon kinds, focus / speed lines
  + ink splash (engine-check 73/73); 0 B for 100 `stamps-draw` with one stamp of each of the 13 kinds live, 100
  Kikon auras, 100 soul flames (duel-vfx 3020); SOUL DUEL fight frame 28.8 → 28.9 ms (1.003×, CvC A B A B A B);
  startup heap 103.1 → 57.3 MB (both games); page to first frame 2940 → 2870 ms; cons/frame in a fight ~9–10 KB
  (unchanged); WGSL smoke green on duel, game, duelvfx, echeck, duelview.
- ACs (`tests/style-2-checks.py`): `spot` — 0 spot pixels in the cut / heavy (outside its droplets) / guard /
  clash / burst / Konpaku / Hoho stills at their 3 moments (fighters off); `ticks` — the Kikon aura changes on 7
  of 35 frame steps, 4–6 frames apart (twos = every 5th frame; the drawing boundaries fall exactly on frame times,
  so float rounding moves some by a frame), never in between; `pause` — 0 px differ over 1 s of pause right after
  a clash; `manga` — mode 3 keeps 3763 of 3769 FIRE and 4859 of 4859 BLOOD pixels and turns 100 % of the rest to
  ink or paper. The cut spark is gone by f11 (1 2 2 6); the guard is a hexagon; the heavy hit's impact mark holds
  3 drawings; `style-2-game-hoho-2` is the solid ink afterimage; the Burst has no glowing ball (anticipation lines,
  then the double ring).
- Stills: `tests/shots/style-2-gallery.png` (every effect × 3 moments), `style-2-<effect>-{1,2,3}.png`,
  `style-2-impact-{negative,two-tone,manga,spot-keep}-{clash,counter}.png`, in game
  `style-2-game-{hoho,kikon-rush,clash,burst,guard-break}-{1,2,3}.png`, `style-2-neutral-{behind,side}.png`,
  `style-2-side-7m.png`, `style-2-fight-side.png` (with the lead's `*cam-close*` 0.6: both fighters fit the side
  camera at 7 m; the behind camera is over the shoulder).

**Open.** The announce words are still the pixel font (Phase 4's brush typography); the Breaker's pink aura and
ring, Hellfire and the Evolution aura are the soft additive ones (Phase 3 / 5). The Burst's light pool reads as a
faint cold glow on the ground in its first drawing. Every toon shape is a camera-facing card or a flat ground
shape, so ground rings thin out from low angles.


### Phase 3: signature effects (done, awaiting user review 2)

Built as the ▲ rows of §4.1 / §4.2 plus what the lead added to the phase: Yamamoto's blade fire and the swing
smears, the fire wave as one wall, Kenpachi's yellow reiatsu aura in every form, the cleave comets, the Nozarashi /
Buttagiru ground cuts, and Bankai's in-form look (charred blade with an ember line, charcoal heat wisps, ember
cracks, and the form wired to the spot-keep grade). Every signature effect follows the §3.4 layer order (backing,
drawn mass, thin additive T光, toon scraps) and is re-drawn on the fx clock's drawings; no gameplay position steps.
Game: `vfx.lisp` (`vfx-blade-fire`, `vfx-blade-embers`, `vfx-smear`, `vfx-fire-wave`, `%brush-aura` /
`%reiatsu-aura` / `%kikon-aura`, the `:heat` wisps, `%crack` / `vfx-line-cut :meteor :crack`, `%light`), `stage.lisp`
(`toon-ground-seg`, `st-glow-seg`, the cracks), `main.lisp` (`form-grade`, the smear replaces `fx-trail`),
`components.lisp` (`blade-smear`), `kit.lisp` / `yama.lisp` / `ken.lisp` (kit data), `hazards.lisp` (the wave's life),
`debug.lisp` (2312 also lays two crack patches). Engine: `%fx-wall` (fx.lisp), `fx-toon.frag.wgsl`, `fx-toon-pal.wgsl`.
Differences:

| Design text | Built | Why |
|---|---|---|
| FIRE core #FFF3DC | **#FFE483** | the row AC asks for a *yellow* core; the cream core read as a white blob inside every flame |
| `fx-wall`: scallops on a strip, "Phase 3 refines it" | **pointed tongues over round valleys** (tips 0.75–1 × hashed per seed, valleys 0.45 ×), tallest in the middle (1 − 0.4 (2u−1)²), ends tapering to the ground; an **along shape** (heat 1 base → 0.2 top) whose **uv.y is the distance along the wall** | with the height fraction as its only shape coordinate the noise was constant along the wall: core, body and shade became regular zigzag stripes parallel to the top. The shader change is one line (an along shape's field is \|uv.x\|, uv.y only moves the noise; every other along shape writes uv.y = 0, so it is unchanged) |
| fire wave: one wall + smoke backing wall + lens slash + 6 scraps + EMBER sector scorch | as designed, plus **5 camera-facing FIRE tongues that fade in only when the wall is seen edge-on**; the scorch is a narrow EMBER strip (0.3 × the half-width, 1.4 m) behind the wall; no smoke puffs | from the side camera the wall is a sliver; a wide EMBER scorch read as a red carpet; black smoke puffs read as bubbles (the backing wall is the smoke) |
| blade fire: sheath + 3 tongues + T光 + scraps | as designed; the tongues stand 4 cm behind the sheath along the view ray (`%away-from-eye`), no smoke puffs | coplanar camera-facing layers fought for depth |
| sword smear "`fx-crescent :comet` from hilt to tip, the last 3 trail samples, held 2 d" | `vfx-smear`: a comet through the blade's 0.7 point over the samples of the last drawing (≤ 5), captured when a drawing starts and held for it, half-width 0.33 × the blade; FIRE (Ryujin Jakka), REIATSU (Kenpachi, every form), **charcoal BLACK SMOKE** (Zanka no Tachi) | Bankai has no fire: an ink-wash smear keeps the spot-keep grade grey |
| reiatsu aura: 7 tongues behind the body; awakened taller + 4 white tongues + ring + T光 | base: 7 REIATSU tongues at 0.45 m, 0.8 × height; **Nozarashi: 9 tongues at 0.5 m, 1.05 ×** + 3 thin white tongues + a REIATSU ring + a small T光 over the head + a yellow light; white flecks (HIT blobs) rise in both. The Kikon rush aura shares the macro | 1.25 × and 4 wide white tongues filled a fifth of the behind-camera frame and washed Kenpachi's back white |
| Bankai: charred blade, ember edge line on threes, 4 charcoal wisps; cracks = ink gashes with an ember core | as designed; the ember line and the crack cores get an **additive** core line (T光) | a toon line a few pixels wide is all edge band: the ember read as dark red specks |
| Bankai grade: spot-keep mode 4, hue 10°, the whole form | kit `:grade :spot` (was a desaturation of 0.3); `form-grade` sets mode 4 while a fighter's kit has it and no impact frame runs; an impact frame takes over for its frames and the form's grade returns | the Tenchi / Bankai cinematics now ramp `*grade-desat*` to 1 instead of 0.3 (Phase 4 restages them) |
| Split the Meteor: DUST gash + REIATSU core + 5 light ribbons for 3 d + 12 rocks + 14 puffs | DUST gash + REIATSU core line, two DUST heave strips running out (threes), 5 narrow HIT light blades for 3 drawings, **8 inked rocks + 10 puffs**; Buttagiru the same at 0.2 m with 4 rocks + 7 puffs | the row's own AC: ≤ 20 particles per cut |
| — | per-frame helpers are macros or take no float arguments (`%brush-aura`, `%crack`, `%light` → `add-point-light-v`, `st-draw-cracks`) | a `defun-fast` boxes its float arguments at every call |

Not in this phase (not ▲, Phase 5): Shiranui, Taimatsu, the Ennetsu pillars, the Jokaku Enjo dome, the Hellfire /
Evolution / Breaker auras, Kyokujitsujin (`:sun`), and the Bankai / Nozarashi awakening bursts (Phase 4 cinematics).
They are still the soft additive looks. A fire wave that hits is destroyed by the sim on the next step, so its
look ends without its 18-frame erosion.

**Measured (final build).**
- G1: RAVEN title and wave stills byte-identical to the Phase 2 build (noise floor 0 px); RAVEN C 729 of 730
  functions identical, changed exactly %FX-WALL; cons/frame 17 369 B = base.
- G2: yy `winner P2 konpaku 0-1 ticks 9545`, yk `winner P1 konpaku 2-0 ticks 9780 secs 163.0`, kk `winner P2 konpaku
  0-4 ticks 8035`; every hash line identical to `tests/style-cvc-ref.txt`.
- G3: 0 B for 100 calls of each new per-frame path (duel-vfx 3021: blade fire, blade embers, the three smears, the
  fire wave, the three auras, both line cuts, the cracks); engine-check 73/73; SOUL DUEL fight frame 33.6 → 34.7 ms
  (1.033×, CvC A B A B A B, noise); startup heap 57.3 → 55.1 MB; page to first frame 3270 → 3460 ms (+5.8 %);
  cons/frame in a fight ~9.4 KB (unchanged); live particles ≤ 56 in the worst gallery scene, ≤ 26 in the still
  runs (budget 500); WGSL smoke green on duel, game, duelvfx, echeck.
- Spot share (`tests/style-3-checks.py`, HUD rows left out): neutral stills with Yamamoto's blade fire and
  Kenpachi's base aura 0.1–1.2 % (≤ 15 %; the frozen duel still with both looks, duel-vfx 3007: 0.43 %); during the
  fire wave 2.7–4.8 % with FIRE dominant; the Nozarashi idle 3.2 %; in Bankai only the ember hue (0.1–0.4 %). The
  ≤ 15 % rule needed no change for the user's yellow-in-every-form decision.
- Stills: `tests/shots/style-3-<effect>-<n>.png` (behind and side cameras), `style-3-gallery.png`, and
  `style-3-pairs.png` (the Phase-0 look on the left, this phase on the right).


### Revision after user review 2 (§13 round 6)

- **No dark ink edges.** `engine/shaders/fx-toon-pal.wgsl`: the edge entries of FIRE, EMBER, BLOOD, SMOKE, DUST and ASH
  are 0 px; REIATSU, STEEL, HIT and SOUL take their shade tone as the edge colour (same widths); INK and BLACK SMOKE keep
  their white edges. `fx-toon.frag.wgsl` drops the fire lower-third edge line (dead with a 0 px edge). `vfx.lisp`: the
  fire wave's backing wall is EMBER (was BLACK SMOKE).
- **Bankai keeps Kenpachi's yellow.** `grade-impact :keep-hue-2` (default = `keep-hue`, so every other caller is
  unchanged) → `*impact-params*`[9] → `r_frame` rp[21] → `P[2].w` of `composite-fx.frag.wgsl`; mode 4 keeps saturated
  pixels within 25° of either hue. The `:spot` preset (cinema.lisp) keeps 10° (ember) and 48° (REIATSU #FFD83A);
  Kenpachi's skin stays grey (saturation < 0.45).
- **Measured.** G1: RAVEN title and wave stills byte-identical to a copy of dist/game made before the change (noise
  floor 0 px), cons/frame 17 369 B = base. G2: yy / yk / kk results and hash lines identical to
  `tests/style-cvc-ref.txt`. G3: 0 B for every phase-2 (duel-vfx 3020) and phase-3 (3021) per-frame path. duel, game and
  duelvfx build with 0 warnings; pkgcheck clean. Spot share (`tests/style-3-checks.py`): all PASS, neutral 0.2–1.4 %;
  Bankai now shows Kenpachi's yellow (bankai-side-3: 0.51 % yellow).
- Stills: `tests/shots/style-3-*.png`, `style-3-gallery.png`, `style-3-pairs.png` re-shot. The Phase-2 stills
  (`style-2-*`) were not re-shot; their hits and dust now have the same edges.


### Phase 4: cinematics and brush typography (done, awaiting user review 3)

Built as §4.4 and §5. **No engine change** (G1 holds by construction: engine/ and game/ untouched). Game: `duel/lisp/brush.lisp`
(new: triangulation, captions), `duel/lisp/glyphs.lisp` (new, generated), `cinema.lisp` (the shot language, every generic
script), `yama.lisp` / `ken.lisp` (their scripts), `hud.lisp` (captions, the brush callouts, the 勝 results card; the old
pixel-kanji words removed), `main.lisp` (card beats, frozen effects), `camera.lisp` (dutch), `vfx.lisp` (awakening bursts,
Tenchi slash, sky-split band; the 24×24 bitmap kanji deleted), `hazards.lisp` / `yama-art.lisp` (South's hands), `debug.lisp`
(10000 + 1000 k + f, 2209, 2329). Tools: `tools/glyph-bake.py`, `tests/style-4-shots.py`, `tests/style-4-checks.py`; licence
`duel/FONT-LICENSE-YujiSyuku.txt`. Differences:

| Design text | Built | Why |
|---|---|---|
| `tools/brush-glyphs.py` bakes triangles (200–400 per glyph) | **`tools/glyph-bake.py`** (fontTools + skia-pathops in a venv) bakes **outlines**: overlaps removed, curves flattened (1 unit), Douglas–Peucker (2.5 units), each hole bridged into its outer contour (a cut to the nearest vertex it can see that is not an earlier cut's end) → a few simple integer polygons per glyph (1/1000 em, y down), 12 354 points for 109 glyphs, 78 KB of source. `brush-init` (a `:load` step) ear-clips them (exact fixnum tests): 11 976 triangles, **22 ms**, and logs an area check (triangles = polygon area; 0 bad) | the lead's brief (outlines, triangulated at load); a generic-arithmetic clipper took 697 ms (first frame +26 %), the fixnum one 22 ms |
| the kanji list: 卍解 野晒 鬼魂 城郭炎上 天地灰尽 残火太刀 勝 + COUNTER / CLASH in Latin | + 東西南北 旭日刃 残日獄衣 火火十万億死大葬陣 の 呑め、 撫斬 不知火 松明 ぶった斬る 俺に斬れねえもんはねえ 魂 決着 時間切れ 山本元柳斎重國 更木剣八, and A–Z . , ! - : ' (the readings) | captions for every cinematic, the Bankai compass, the SP names, the intro names; Japanese forms (残 尽 万, as printed in BLEACH) rather than 殘 盡 萬 |
| COUNTER / CLASH as brush Latin | every move callout and every big word (ANNOUNCE) is brush Latin (`brush-line`: one centred line + an ink shadow, 0 B; widths cached per string); the pixel font stays for HUD numbers, stat tables, prompts and menus | user review 3 (below) |
| hanko: a red square | BLOOD #D0101C square with 鬼 knocked out in paper white, under the column | the only colour on a caption |
| Bankai direction marks | a white mark glyph in a black box with a thin white frame, at the column's head | mono: the red is the Kikon's; the user kept the black box (review 3) |
| captions may bleed off the frame | the block (mark, column, hanko, reading; the second column) is sized to fit between the letterbox bars (0.1–0.895 h; 0.84 h with a chapter line), the stamp's zoom is capped to stay inside, the column is clamped inside 2–98 % of the width, the reading and the chapter line shrink to fit their half of the screen; `draw-bcap` logs a caption that drew an em box off the screen (`style-4-checks.py bounds`) | the coordinator's review: bleeding read as clipping (野, 卍解, the long intro names, the readings) |
| `ui-ink-splash` behind the glyph | beside the column's head (outer side), from drawing 1; on the results card right of 勝, clear of it and of the name line | a splash in the glyph's own value behind it swallowed the glyph; in the other value it read as a hole |
| the chapter line lower left | at the foot of the caption's third | lower left collided with the figure whenever the caption stood right |
| captions shown until the cinematic ends | until a cut after the wind-up (Kikons), to the end (awakenings, K.O.) | a 60 %-height column over the impact beats crowded them |
| `bg-drop` | `(card kind &optional only)`: the stage skipped, sky / horizon / fog / moon = the card's value (#08080C / #F4F4F0), no vignette or moon glow, the particles cleared, and only the ONLY actor drawn | the other fighter (and Yamamoto's blade fire) crowded every card shot |
| `silhouette-shot` | `back-rim frames &optional rgb` (both fighters in shadow tone + a hard rim: white, or Kenpachi's yellow) and, for the Bankai reveal, `silhouette-black` (a near-black tint on body and ink) | in the shadow tone the white haori is #9CA3B4, not the black silhouette §5 asks for |
| `(fov-set deg)`, `(shot-dutch deg)` | `(lens fov &optional roll)`: `camera-fov` + `*dutch*` (camera.lisp rolls `camera-up` about the view, `%roll-up`, 0 B); `cine-end` restores 60° / 0 | one call per shot |
| hold beat: `model-hold` + the fx clock paused | `(hold-both a v frames)` = `hold-pose` both + `(freeze frames)`: effect time stops (particles, the fx clock, shake, the HUD's fades) while the script runs on | the grammar's beat 0 and holds |
| — | `(cine-grade :spot)`: a cinematic's base grade, back after each impact frame (Tenchi Kaijin, the Bankai reveal) | the old scripts ramped `*grade-desat*`, which the spot-keep grade replaced in Phase 3 |
| — | `(impact-splash x y z frames r)`: a black ink splash at the victim's feet on the Kikon impact stills (boxed once when set: 0 B a frame) | §5 "every Kikon impact still" |
| worked example: the low wide-angle shot "inside the rings" | from 3.8 m outside the dome, then 3.4 / 3.1 m push-in cuts (FOV 88 → 66 → 58) | inside, the Phase-5-pending soft dome shell filled the whole frame; the dome is not drawn during the card beat |
| Bankai reveal (anticipation 16 tongues + shards; burst: charcoal ring + puffs) | `vfx-awaken-burst` redrawn toon: **:bankai** 36 FIRE blobs + 16 EMBER shards rushing into the hands; **:bankai-burst** the NISHI double ring (BLACK SMOKE, EMBER line) ×1.2 + 6 BLACK SMOKE puffs + 10 ASH shards, fired when the card ends (f58); **:nozarashi** 28 REIATSU blobs shooting up + a flat ring (no dust: on the black card the puffs hid him), and the pillar itself is the Nozarashi aura drawn 6.5 m tall for f20–38 | they were the soft additive looks (Phase 3 left them to this phase); a burst on the white card covered the silhouette |
| Tenchi slash: a hard white slash, 2 px ink border | a white spindle over an ink spindle 3 px wider, no translucent wedge, no flash (the two-tone frame is the flash) | §4.1 row AC |
| sky split: a white band with ink borders | as designed; the yellow glow gradients and the pale flash rect removed | the negative / manga page is the flash |
| — | HIGASHI's crescent 3 m wide (was 4.4 m); South's skeleton hands pale bone with charred bands, no shadow disc, 1 low dust puff each (was 2) | the lead's two cheap fixes |

The scripts (all `:len` unchanged; only `FACE-EACH-OTHER` touches the sim, at its old frames):
- **Kikons** (Jokaku Enjo 108, Tenchi Kaijin 96, Kenpachi's 114, sky split 90): beat 0 (f0–7: the gameplay shot frozen, a 2 f
  negative); a card wind-up f8 (Yamamoto on black, Kenpachi's base Kikon on white, the sky split on black with a yellow
  back-rim), low and dutch (8–12°), the stamp with its hanko, silence 10–17 f; cuts on the action (3–7 in all); a held
  close wide-angle push (FOV 72–90, silence 12–17 f) before the last hit (Jokaku, Kenpachi's); the impact: a negative,
  then a 10 f manga page, an ink splash; the aftermath wide. Kenpachi's two Kikons are captioned with his release words
  呑め、野晒 (NOME, NOZARASHI) and the hanko (user review 3).
- **Awakenings**: the Bankai (beat 0; the flames pulled in, FOV 88, focus lines; from behind in silence while the world
  greys; a negative, then the black silhouette on the white card with only the ember line red, 卍解 / 残火の太刀; the
  charcoal burst and the cracks back in the grey world); Nozarashi (beat 0 on the face; the patch tears: a negative; the
  yellow pillar on the black card with a yellow rim; close, low, wide-angle in silence while the blade grows; the stamp
  野晒 / 呑め、 (呑, as in the manga) on the white card, a manga page).
- **Soul Break** (魂 SOUL BREAK, a held close beat in silence, the shatter as negative + manga page), **K.O.** (a white/ink
  two-tone frame, the winner held 20 f under 決着 K.O., the one allowed orbit), **TIME** (時間切れ), **intro** (the names in
  vertical kanji with their readings and intro lines, a negative at the switch).
- **Gameplay callouts**: a move of `*brush-callouts*` shows a brush column at its user's side (stamped, 1.3 s) instead of
  the pixel callout: the SP names with kanji and the Bankai compass marks (東 西 南 北). Every other callout and every
  big word (FIGHT!, COUNTER, CLASH, GUARD BREAK, KIKON / GUARD IT! ...) is one line of brush Latin.

**Measured (final build).**
- G1: no engine or RAVEN file changed.
- G2: with the old cinematic lengths the tree reproduced the old reference exactly (yy `ticks 11248`, yk `ticks 8054 secs
  134.2`, kk `ticks 8396`); after the pacing changes (below) the reference was re-baselined: yy `winner P2 konpaku 0-4 ticks
  11746`, yk `winner P2 konpaku 0-3 ticks 8594 secs 143.2`, kk `winner P2 konpaku 0-4 ticks 8834`; every hash line matches.
- G3: 0 B for 100 draws of each caption layout (cine with mark, second column, hanko, reading and chapter line; card;
  callout; results), the impact splash, the dutch roll and a brush Latin line (debug 2329); fight frame 29.3 → 29.0 ms (0.99×, A B A B A B vs
  the Phase-3/bankai-kikon build; 1.029 / 0.970 after the review-3 passes, noise); startup heap 55.2 → 57.3 MB (≤ 110); page to first
  frame 3460 → 2840–3190 ms (noise; brush-init 22 ms); WGSL smoke green; duel builds with 0 warnings, pkgcheck clean.
- §9 row 4 (`tests/style-4-checks.py --run`, 52 PASS: the row-4 items, every `:len`, the pacing rule, the held caption
  close-ups, the Bankai grade, the bounds at 1280x720 and 800x450): every Kikon has beat 0, a card, ≥ 3 cuts (3–7), a negative + a manga
  page, a silence ≥ 8 f (10–17) and a brush caption; every `:len` unchanged; the Bankai stills (the reveal card, the wide
  after it): 0.0 % of the saturated pixels off the ember / yellow hues.
- Stills: `tests/shots/style-4-<cinematic>-<frame>.png` (each cinematic at 3–8 beats), `style-4-callout-*.png`,
  `style-4-results-*.png`, `style-4-gallery.png`, `style-4-captions.png` (the captions close up), `style-4-pairs.png`
  (before: the previous build held at each script's old `:hold` frame; after: the caption beat).

**Open.** Jokaku Enjo's dome, Shiranui, Taimatsu, Ennetsu and the Hellfire / Breaker auras are still the soft looks (Phase
5); the K.O. rain, the caption slice exit and the Nozarashi skull are Phase 6.

**User review 3 (§13 round 7, answered via the coordinator).**

| # | Question | Decision | Consequence |
|---|---|---|---|
| 1 | 残 尽 万 or 殘 盡 萬 | keep the Japanese forms 残 尽 万 | — |
| 2 | Kikon caption time (up to the second cut after the wind-up) | keep, relative to the cuts: with the slower pacing it stays up ~1 s | — |
| 3 | the black ink splash at the victim's feet on Kikon impacts | keep | — |
| 4 | Latin-only callouts and the big words in pixel font | **all brush**: every move callout and every ANNOUNCE word; pixel only for HUD numbers, stat tables and menus | `brush-line` / `line-width` (brush.lisp), `draw-words` and the callouts (hud.lisp); `DRAW` on the results card |
| 5 | Kenpachi's Kikons captioned 鬼魂 | his release words 「呑め、野晒」 (NOME, NOZARASHI) on both, with the red 鬼 hanko | ken.lisp; the Nozarashi awakening's second column is 呑め、 too (呑, not 飲: the coordinator) |
| 6 | the direction mark style | keep the black box with a white glyph (a thin white frame lets it read on the black card) | brush.lisp |

Coordinator fixes after the first still set: no caption glyph off the screen on any frame (the fit / clamp rules
above; a new `bounds` check plays every cinematic, the callouts and the results at 1280x720 and 800x450); the results
splash moved clear of 勝 and the name line; 呑 baked (飲 dropped).

**Pacing (user request after review 3: 「鬼魂技與覺醒的演出與鏡頭切換速度太快，能放慢節奏嗎？」).** The Kikon and awakening
cinematics are ~1.45× longer, not uniformly stretched: fewer and longer shots (the shortest cuts merged or dropped:
Jokaku's three push-in FOV cuts became one held dolly, Kenpachi's close push the same), **every shot ≥ 20 f** except
beat 0 (12 f, the gameplay freeze) and the 1–3 f negative / impact flashes (nothing under 12 f), longer holds on the
caption card (26–28 f), the Bankai silhouette reveal (28 f), the Nozarashi yellow pillar (30 f) and the pre-final-hit
freeze (20–22 f), and the impact frames themselves as sharp as before (2 f negative, then a 10–12 f manga page). The
actors' clips play slower to keep their hits on the new beats (`:speed` old frame / new frame); the dome, the Tenchi
slash and the sky split run on longer lives. `tests/style-4-checks.py pacing` checks every shot ≥ 12 f and the mean ≥ 20 f.

**User decision (review 3, 2026-09-26): caption close-ups held longer.** The rest approved; the caption close-up (the
card shot with the brush caption and the character close) of the Bankai and of every Kikon holds **+30 f** (0.5 s); no
other shot stretched; the caption stays up through it (the Kikon rule: up to the second cut after the wind-up); the
card's silence and back-rim cover it; the attacker's clip plays slower so his hit still lands on the (later) impact
beat. `tests/style-4-checks.py` checks the card shot's length (`caption close-up held`) with the pacing rule.

| Cinematic | :len original | review 3 (×1.45) | final | Shots (frames), final |
|---|---|---|---|---|
| Jokaku Enjo | 108 | 156 | **186** | 12 · 58 (caption card) · 30 · 20 · 22 (held dolly) · 14 · 30 |
| Tenchi Kaijin | 96 | 138 | **168** | 12 · 56 (caption card) · 42 · 58 |
| Kenpachi's Kikon | 114 | 162 | **192** | 12 · 58 (caption card) · 28 · 24 · 20 (held pull) · 20 · 30 |
| sky split | 90 | 132 | **162** | 12 · 56 (caption card) · 34 · 30 · 30 |
| Bankai | 72 | 108 | **138** | 12 · 28 · 20 · 58 (the reveal caption card) · 20 |
| Nozarashi | 72 | 108 | **108** | 28 · 30 · 20 · 30 |
| Soul Break, intro, K.O., TIME | 96, 300, 150, 120 | unchanged | unchanged | |

**G2 re-baselined.** The sim is frozen during a cinematic (CINE-STEP runs instead of the systems; only `*match-tick*`
counts on), so the lengths shift the match ticks and the times at which the 600-tick hash lines sample the state. Proof
that nothing else changed: the build before the pacing change reproduced the old reference exactly (G2 PASS), and after
it every combat-log event of the three CvC matches (302 / 256 / 264 events) is the old one with its tick shifted by the
frames the cinematics played before it added (yy +288, yk +330, kk +288 ticks in all); same winners, Konpaku and event
order. After the caption close-ups were held +30 f the same proof held again against the review-3 build (the same
302 / 256 / 264 events, shifted yy +210, yk +210, kk +150 ticks; +498 / +540 / +438 against the pre-review reference).
`tests/style-cvc-ref.txt` holds the final lines; the YK reference: `duel -> RESULTS winner P2 konpaku 0-3 ticks 8594 secs
143.2` (review 3's slow-down alone: 8384 / 139.7; before: 8054 / 134.2). The Kikon hold-O rule, the dash-in and every gameplay frame are unchanged (they end
before the cinematic starts). Pacing gate (`duel-gate.json`, 20 seeds × pairing, all K.O.), final: YY median 158.7 s
(95.5–223.2), YK 152.1 (115.2–185.2), KK 159.7 (128.8–197.4); with the slow-down alone 155.2 / 149.6 / 157.2; the build
before the change gave exactly the old 150.4 / 145.5 / 152.4.

### After phase 4: the Kenpachi batch (2026-09-26, DUEL_DESIGN §12)

No engine or RAVEN change (G1 identical). The look side: the eyepatch removed from Kenpachi's body (every form), the
Nozarashi awakening's first shot re-staged as the NOME release (`:ke-release`; its shots stay 28 · 30 · 20 · 30 f, the
pacing rule and the brush captions untouched: `style-4-checks.py --run`, 52 PASS), the run clips facing the opponent
(`defrun`: forward run, side slides, back-skate; Kenpachi's set with the blade on his shoulder), Nozarashi's cup looks
(§4.2's new row) and West's garb flaring while his U armour holds (since guard v3: while he guards). G2 re-baselined (the sim changed: DUEL_GAMEPLAY
"Determinism"); the YK reference is now `duel -> RESULTS winner P1 konpaku 7-0 ticks 7351 secs 122.5`. Stills:
`tests/shots/batch-*.png`, `batch-sheet.png` (`tests/batch-shots.py`).

### After the Kenpachi batch: guard v3 (2026-09-26, DUEL_DESIGN §12)

No engine or RAVEN change (G1: the RAVEN stills byte-identical against a BASE `dist/game` built before the change). The
look side: West's garb guard shows the EMBER star and a sizzle on a blocked hit (and on a ranged hit it armours), the
garb aura's ×1.4 flare is keyed on West guarding (was the held-U armour); the HUD's guard bar is 30 % darker while its
owner guards below full (GUARD HOLD), **ember** in Bankai (the fed flame) with a 0.1 s white flash on a feed and a
one-time "HIT TO FEED" callout; the U tag reads `U: GARB`. The HUD bars stay 0 B (debug 2328). G2 re-baselined (the sim
changed: Reishi 1300 and the new rules); the YK reference is now `duel -> RESULTS winner P2 konpaku 0-4 ticks 9305 secs
155.1`. `style-4-checks.py --run dist/duel`: 52 PASS. Stills: `tests/shots/guard3-*.png` (deleted 2026-09-27 with the garb: the Bankai rework).


### Phase 5: remaining effects, faces, pose-to-pose clips (done)

Built as the non-▲ rows of §4.1 / §4.2 (and every move added since, §4's rows now say "built, Phase 5"), the expression
swaps of §2.5 and the per-clip re-authoring of §2.6, plus the items carried over: the last soft fire looks, the fire
wave's erosion after a hit, the callouts clear of the HUD, the Kenpachi batch's open art (the kendo clips, the rift's
ink gash, cup 3's grin) and West's garb looks. **No engine change** (engine/ and game/ untouched). The work was split
by character as §9 suggests: two helper agents re-authored the clips and faces of `yama-art.lisp` and `ken-art.lisp`
(each file its own owner), the lead did everything else. Files: `vfx.lisp` (the looks, 9 new stamps, the wave's
ghost), `main.lisp` (faces, the head-back overlay, draw-side move beats, the Breaker's colour, the garb flare),
`components.lisp` (5 model slots), `feedback.lisp`, `hazards.lisp` (the draw; the `:rift-cut` event carries the
rift's frame), `hud.lisp` / `brush.lisp` (the panel boxes), `body.lisp` (`draw-body :face`), `debug.lisp` (2362+k,
2390), `ken.lisp` (the kendo moves' `:clip`), the art files; tests `duel-view.lisp` (scene 5, 6300+k), `duel-vfx.lisp`,
`duel-rules-test.lisp` (the clip contract), `style-5-shots.py`, `style-5-checks.py`.

| Item | Built | Why / deviation |
|---|---|---|
| Shiranui | a FIRE disc (wobble 0.3, re-drawn each drawing), 5 tongues licking back along the flight and curling up, a thin T光 core, flame scraps and a BLACK SMOKE wake of toon puffs left behind; `vfx-fireball` takes the flight direction | as §4.1 |
| its charge (`vfx-charge`, also the Bankai reveal's blade) | 6 FIRE / EMBER shards converging on the tip (a new drawing every 1/12 s), flame scraps sucked in, a FIRE disc growing in 6 drawn steps of the charge; focus lines when the charge starts (a draw-side beat) | "3 drawings" became 6 steps of the charge: the charge lasts 12–60 f, 3 steps read as pops |
| Taimatsu | the `:cone` stamp, envelope (1 3 4 30): a white flash, 9 flames fanned over the sector rolling out and up, a FIRE ground sector for 2 drawings, 5 pale SMOKE puffs at the lip | each "blob" is a big FIRE tongue with a small one beside it: 9 discs read as a row of fireballs |
| Ennetsu pillars | a FIRE column over an EMBER backing, a swaying EMBER stripe in front (the spiral), a crown of 6 tongues, an EMBER foot ring; rises on ones in 3 drawings, crown on twos, erodes from the tip; one light for the ring (in `hazard-draw`) | 0.64 m wide, not the soft 1–1.8 m: opaque columns 1 m wide filled the side camera's frame (the camera stands inside the ring) |
| Jokaku Enjo | no shell: 3 tiers of FIRE tongues (12 + 9 + 6; the outer over EMBER backings) rising on ones, leaning in and spiralling closed in 4 drawn steps, boiling on twos; the detonation is the `:boom` stamp (a white flash, a 14-spike FIRE star over a larger EMBER one, a white core) + a FIRE ground ring + 26 flame / 10 smoke / 16 ember scraps | the "4 d" close is 4 drawn steps over the script's closing span (0.35–0.7 of its life), so the cinematic's shots keep their beats. The detonation fires on the first draw past 85 % by a flag, not by crossing with DT: the cinematic freezes effects (DT 0) exactly there, and the old crossing test never fired (the old dome hid it behind sprites drawn every frame) |
| Hellfire aura | a bonfire: 7 FIRE brush tongues behind him, 8 short FIRE tongues at his feet, an EMBER ring, scraps | not in §4's table (only the palette mapping); made to read apart from West's garb, which wraps him all over |
| Evolution aura | 5 thin STEEL tongues + white flecks | universal, so mono (§A.2); it was a soft gold glow |
| Breaker (both) | the owner's colour (REIATSU / FIRE / EMBER by the kit's blade) as 7 tongues over 7 taller INK tongues, BLOOD flecks; the ring: a steady BLOOD ring and an INK ripple every 0.4 s | §4 mapping: "the owner's colour over an INK backing, with a BLOOD edge"; the red edge is the ring (a red outline would break review 2) |
| shockwaves | `vfx-shockwave` always draws a toon `:ring` stamp; an RGB call maps to FIRE / REIATSU / HIT (the Hellfire entry, Buttagiru, the awakening rings) | the soft rings were the last soft ground marks |
| Tenchi Kaijin's ash | 44 ASH shards peeling off and drifting sideways (threes), 16 ASH flakes, 6 BLACK SMOKE puffs | §4.1 Tenchi row (it was soft dust, feathers and a warm glow) |
| Nadegiri | the `:nade` stamp, fired by a draw-side beat at its S: a flash, a white lens across his front for 2 drawings then an EMBER hairline, an INK ground strip with an EMBER core racing 8 m out | the sim's move data is untouched (no new on-frame hook): `move-beats` in `draw-fighter` fires on the draw that first sees S |
| the fire wave after a hit | the sim ends a wave the step after its hit (`hazard-connected`), so its look vanished; `hazard-draw` now hands a spent wave (age ≥ life) to `wave-ghost-start`, and `wave-ghosts-draw` keeps drawing it where it hit with LIFE = its hit age + 22 f: 4 f of hold, then the 18 f erosion | render-only (4 ghost slots); the body is the macro `%fire-wave-look`, shared with the live wave, so the ghost is 0 B |
| KUKAN-GIRI's rift | waiting: a REIATSU lens slit with a white HIT line in it at chest height, trembling on twos; cutting: a wide white lens over a yellow one; and the `:gash` stamp that stays: an INK lens with a white edge along the rift, a white line in it, 4 ink shards (envelope 0 1 4 16) | the `:rift-cut` event now carries the rift's frame (x z yaw) so the gash lies along it; events are presentation, the sim state is unchanged |
| West's garb block | the `:garb-guard` stamp: the guard's hexagon drawn in fire (an EMBER hexagon with a white core) + 5 ember sparks flung back at the attacker + 2 black smoke curls | the lead's "reading clearly in the mono style": a block reads by its shape (the hexagon of every guard), the burn by value (white core, black smoke); the ember is the only colour |
| the scorch | at the attacker's sword hand (its joint): a white flash, an EMBER star for 2 drawings, 2 BLACK SMOKE curls rising (+ 1 puff) | the old 2 puffs at 1.3 m read as nothing |
| the garb flare (a ranged hit armoured) | the `:flare` stamp (12 FIRE tongues flung out low, an EMBER ring running out) and the aura ×1.9 decaying over 0.45 s (`model-flare`) | found on the way: `:garb` clamped K to 1, so the ×1.4 guard flare of guard v3 never showed; K > 1 now scales the garb's height and radius |
| the burnout | the `:gutter` stamp (West: his flames sinking for 2 drawings; both: 6 charcoal wisps off the shoulders, an ASH ring running out), 5 BLACK SMOKE puffs, 12 ASH shards falling | East has no flames to gutter (his heat is charcoal already) |
| SP2 dash (Kenpachi) | an ink afterimage every 10 f of the dash's active frames + speed lines along his facing | §4.2 row; a draw-side beat, like Nadegiri's |
| cup 3's entry (NOMIHOSE) | `face-beat`: his shout face (the laugh) held 0.9 s and the head thrown back over whatever clip plays (head −35°, chest −10°, spine −8° on an envelope; `beat-pose!` copies the pose, the anim's own stays) | the Kenpachi batch dropped the beat because the rung changes only while he is free, where the idle / walk clips replay every step; an overlay pose is independent of the clip. The hair lift is still the rising tongues of his aura (no hair rig) |
| faces | `draw-body :face` (:neutral / :shout / :hurt; `face-hide` hides the other two tag sets, constant lists: 0 B); `face-of` in `draw-fighter`: a held face first, a cinematic's attacker shouts and a Kikon's / Soul Break's / K.O.'s victim is hurt, hurt while stunned / airborne / down / lost, shout through a non-Quick move from 10 f before its hit to 12 f after (and its charge / aura / dash phases). Yamamoto: shout = the glare (wide whites, small pupils, brows up, the mouth open in the beard), hurt = eyes squeezed shut, a grimace. Kenpachi: shout = the roaring laugh (mouth wide, both teeth rows, wide eyes, hooked brows), hurt = a grimacing grin (clenched teeth, one eye squinted); both eyes open in all three, no eyepatch | at gameplay distance (4–8 m) the face is ~12 px tall: the shout reads as a dark open mouth, hurt vs neutral hardly; the close-ups of the cinematics and the viewer show all three |
| the RYOTE kendo clips | own DEFSTRIKEs with the moves' exact S/A/R on the two-handed jōdan: MEN `:ke-r-q1` (10/3/12, the blade down the centre line on a step), KESA `:ke-r-q3` (14/4/22, the diagonal), DO `:ke-r-f1` (19/4/20, the flat sweep stepping through), KABUTO-WARI `:ke-r-f2` (21/5/28, rising on the toes, crashing down; KE-R-F2Q enters it at f7), and cup 3's KUKAN-GIRI `:ke-n-f1` (20/4/22, a flat cut at 1.2 m); `ken.lisp` points the moves at them with `:clip-s` = the authored S (speed 1) | the left hand was solved onto the cleaver's long handle (a host FK tool); `:ke-r-stance` now has both fists on the handle (before, the left fist hung 0.57 m off it) |
| pose-to-pose re-authoring | every attack DEFSTRIKE of both (Yamamoto 19, Kenpachi 10): a held anticipation pose, a `:snap` into the hit pose at S (Yamamoto's from named `:ya-*-hit` poses equal to the old keys; Kenpachi's blade within 3° of the old), an overshoot, a zanshin hold, a settle; the DEFSTRIKE headers (S A R, base), names, durations, marks and weapon swaps are byte-identical to the previous build | the sim never reads joints, and the frame data lives in the headers (G2) |
| callouts vs the HUD | each side panel's box (its bars, labels and combo counter) is recorded as it is drawn (`*panel-box*`, both panels before any callout); a head callout overlapping one moves under it (`callout-y`), a word overlapping one is set under it (`word-layout`), a brush callout column starts under both; anything still over a panel is logged once (`hud: … over the P2 panel`, `brush: caption … over the HUD`) and `style-5-checks.py --run` fails on it at 1280x720 and 800x450 | with the side camera Kenpachi's KUKAN-GIRI / NOMIHOSE (P2) sat on the P2 labels (reproduced on the base build) |
| Kyokujitsujin's old `:sun` line cut | removed (dead: no hazard spawns a `:sun` line) | its soft look was the last `%gseg` user |

Also: the dead soft helpers (`fire-tongue`, `%aura-tongues`, `front-dim`, `%gseg`, `%gdisc`, `flame`) deleted; the duel-vfx
gallery's line-cut scene shows `:kyoku` instead of `:sun`.

**Measured (final build).**
- G1: no engine or RAVEN file changed; the RAVEN title and wave stills byte-identical to a BASE `dist/game` built before
  the phase (noise floor 0 px), cons/frame 17 369 B = base.
- G2 (`style-gates.py cvc dist/duel`): yy `winner P2 konpaku 0-1 ticks 13914 secs 231.9`, yk `winner P2 konpaku 0-4 ticks 9305
  secs 155.1`, kk `winner P1 konpaku 6-0 ticks 7578 secs 126.3`; every hash line identical to `tests/style-cvc-ref.txt`
  (unchanged: a render-only phase).
- G3: 0 B for 10 draws of every new per-frame look (debug 2390: fireball, charge, pillar, dome, the Hellfire /
  Evolution / Breaker auras and ring, the garb flare, the rift, a spent wave's erosion, the 9 new stamps live at once,
  `face-of`, `beat-pose!`, `move-beats`); SOUL DUEL fight frame 29.1 → 28.3 ms (0.97×, CvC A B A B A B against the
  BASE build of the phase: noise); startup heap 56.0 → 55.4 MB (≤ 110); page to first frame 3030 → 3130 ms (+3.3 %).
- duel, game, duelvfx, duelview build with 0 warnings; `tools/pkgcheck.sh duel` clean; WGSL smoke green on duel, game,
  duelvfx, duelview; host tests all pass (duel-rules-test 703 with the 5 kendo clips added to its clip contract,
  duel-control-test 53, ecs, rules, input 31, cine 18).
- `style-4-checks.py --run dist/duel`: 52 PASS (every `:len`, the pacing rule, the held caption close-ups, the Bankai
  grade, the caption bounds at both sizes).
- `style-5-checks.py --run dist/duel`: all PASS — each fighter shows 3 expression states (the face close-ups differ
  pairwise by 10.6–15.3 % of the crop's pixels for Yamamoto, 19.6–28.8 % for Kenpachi); Jokaku Enjo's manga page: of
  2219 sampled saturated pixels 1298 fire, 919 the victim's own yellow reiatsu, 2 other; no callout, word or brush
  column over a HUD panel and no caption off the screen at 1280x720 and 800x450 (the side-camera case reproduced the
  overlap on the BASE build); 0 B for every new look (debug 2390).
- Stills: `tests/shots/style-5-<name>.png` (the gameplay scenes at 2–5 moments, the dome and Tenchi's ash in their
  cinematics, the VFX gallery frames, the kendo and re-authored clip strips, the six face close-ups and the line-up),
  `style-5-before-<name>.png` (the same scripts on the previous build), `style-5-gallery.png`, `style-5-pairs.png`.

**Open (Phase 6).** Destruction marks and resting debris, the caption slice exit, the skull in the Nozarashi pillar,
the K.O. rain, the quantised fog bands, CA / fisheye only if a review asks (as planned). From this phase: the hurt and
neutral faces hardly differ at gameplay distance (a larger mouth shape, or a face held a few frames longer, if the user
wants them read in play); Kenpachi's left fist drifts off the cleaver's handle for a few frames in some kendo
transitions (more solved in-between keys); the half-height pillar of a later cup 3; the hair lift of cup 3's grin (a
hair rig); the additive T光 cores (a few sprites and core lines) are the only soft shapes left.

### Phase 6: polish (done, approved at user review 4)

Built as the Phase 6 row of §9, plus the Phase 5 leftovers and the coordinator's review of the Phase 5 stills. **No engine
change** (engine/ and game/ untouched; the fog-band trial below touched `toon.frag.wgsl` in a one-off build only and was
reverted). Files: `stage.lisp` (the marks and chips, the Bankai cracks' drawn core), `feedback.lisp` (the events that
place marks; `:reset` clears them), `ken.lisp` (the Buttagiru / Meteor scars, the skull beat, the half pillar),
`vfx.lisp` (near-lens columns, the skull, the rain, the face accents, the soft cores redrawn), `body.lisp` (the grip
IK), `main.lisp` (grip and face-accent calls), `components.lisp` (3 model slots), `brush.lisp` / `cinema.lisp` / `hud.lisp`
/ `yama.lisp` (the slice exit), `debug.lisp` (2366, 2391, 2392), the two art files (bolder mouths, the grip clips);
tests `duel-view.lisp` (7000+k grip strips), `style-6-shots.py`, `style-6-checks.py`.

| Item | Built | Why / deviation |
|---|---|---|
| Destruction marks | a pool of 20 marks (x z r kind birth; the oldest replaced), drawn flat in the toon batch as BLACK SMOKE (ink body, the white hairline of Bankai's gashes): a **scorch** = 9 ink spokes splashed from the centre, a **crack** = 5 jagged rays of 3 segments; shapes hashed from the position (stable, 0 B), each burns in over 0.12 s. Placed by the feedback events (a fire hit: scorch 0.8 m; a hit of 150+ or a Breaker: crack 0.9 m; guard break 1.1; clash 1.2; a knockdown landing 0.6; Hellfire's entry: scorch 2 m) and by the Buttagiru / Meteor hooks (cracks along the cut); inside the plaza only. Cleared by `:reset` (a Kikon / Soul Break reset) and a new match | render-only: the sim never reads them; events are read, nothing the sim owns is written (G2 unchanged). The Kikon impacts leave none: the reset follows at once |
| Resting debris | a pool of 24 rubble chips (3 low-poly meshes built at load, each with its ink hull): thrown up by a heavy impact (3-5), gravity, one bounce, at rest, shrinking away 6.6-7 s after the throw; stage toon + ink hull draws (2 per live chip) | the engine's `fx-debris` draws lit, not toon, and lives 2.4 s |
| Caption slice exit | one diagonal brush cut (rising left to right) through the column's middle, the two halves sliding apart along it on twos (4 drawings, 0.3 s) and fading, the cut stroke on the first 2 drawings; the mark box, hanko, reading and chapter line drop out on the cut. `CAPTION-EXIT` replaces the scripts' `(setf *caption* nil)` (at the same cuts), a title still up when a cinematic ends slices out over what follows (`*CAPTION-OUT*`), a timed callout column slices in its last 0.3 s (was a 0.25 s fade). The glyph triangles are clipped to each half in the UI batch (`%GLYPH-TRIS-CLIP`, 0 B) | §4.4 said 3 horizontal slices over 3 d: one diagonal cut reads as the sword stroke. During a freeze beat (effects held) the halves wait with the cut drawn, then slide (Jokaku's held push-in): kept, it reads as "cut, then it falls apart" |
| Skull in the Nozarashi pillar | f40-49 (2 drawings on twos) of the pillar card: an INK cranium and hexagonal jaw cut out of the yellow (white hairline), REIATSU eye sockets with white cores, a REIATSU nose, 6 white fangs; screen-plane shapes 0.25 m behind him (in front of the rear tongues, behind his body) | first placed 0.8 m behind him it sat behind the tongues, black on the black card |
| Quantised fog bands | **rejected**. Trial: `fs_toon` quantising the stage fog to 5 steps (a one-off build); stills `style-6-fog-{title,behind,side}-{before,bands}.png` | the plaza is no longer a white page (review 1 made it V2 mid-grey); the bands draw a false contour arc across the plaza under the fighters and change nothing on the ruins |
| K.O. rain | `vfx-rain` through the K.O.'s orbit (f20-150, fading in over 20 f): 110 thin white streaks slanting through a 14 m box round the loser, falling 14 m/s on threes (re-drawn every 1/8 s), 10 small white splash rings each drawing; no particles | §6: rain as the emotional accent. No rain sound (not asked; §10) |
| Pillars near the lens (review of the Phase 5 stills) | an Ennetsu column is never wider on screen than one 9 m away (width × distance / 9 m, at least × 0.1) and shortens to 0.4 of its height at 2 m (to full at 8 m); its crown and scraps go below half; the EMBER foot ring stays whole (the hazard stays readable). The fire wave sinks to 0.4 of its height where it passes within 1-3.5 m of the eye | render-only (the sim's hit volumes are untouched). In the behind camera the column between the lens and Yamamoto becomes a thin stick; the ring's side columns still frame the shot |
| Faces at gameplay distance | (1) the shout and hurt mouths bolder (Kenpachi's roar 0.08 × 0.054 m, Yamamoto's 0.066 × 0.048, his grimace and clenched teeth wider); (2) a **gameplay accent** when a shout or hurt face is put on (not in cinematics, whose close-ups show the faces): shout = 6 ink strokes (BLACK SMOKE kites) bursting out of the head's upper half, grown over 2 drawings, re-drawn on twos, gone at 350 ms; hurt = 3 white drops flung off the head, falling, gone at 400 ms. 3 states per fighter kept | the face is ~12 px tall at 4-8 m; the burst spans ~125 × 55 px at the side camera (`style-6-face-accents-1`). Inside Kenpachi's cup-3 pillar aura the strokes are partly hidden by the tongues |
| Fist drift (RYOTE kendo) | a render-side **two-bone IK** (`GRIP-LEFT!`, after the FK): the left fist (the `:weapon-l` point) pulled onto the cleaver's handle (0.14-0.62 m behind the right grip, the nearest point to where the keys put it), the elbow bending in the plane the pose gave it, 2 passes; on for the clips of `*GRIP-CLIPS*` (the RYOTE stance, DRINK, MEN, KESA, DO, KABUTO-WARI, KUKAN-GIRI), eased in and out over 0.1 s. Debug 2392 measures every frame of those clips and of every grip-clip → grip-clip crossfade | DEFSTRIKE headers and every key unchanged (the sim never reads joints); the hit pose at S differs only in the left arm, by the key's own few mm. Keys only: 2-43 mm on the keys, spikes of 157-436 mm between them (the snaps and the returns to jōdan); held: median 0 mm, worst 160 mm on one DO wind-up frame where the handle is beyond the left arm's reach (≤ 53 mm on every other clip) |
| Soft shapes | the four soft sprites are gone: Shiranui's and the charge's warm core glows → small white HIT discs (drawn); the Nozarashi aura's faint glow and the hit star's white core sprite cut; the Bankai cracks' ember core → a thin drawn EMBER strip (EMBER has no edge since review 2, so a thin toon strip reads). The unused `%SPR` and `ST-GLOW-SEG` deleted | **kept**: the thin additive T光 core lines (the blade fire's, the embers', the fire wave's base): 1-2 px wide, they read as hard lines, and §3.4 makes the T光 line a layer |
| Half-height pillar of a later cup 3 (optional) | built (cheap, render-only): `MODEL-T3` counts a match's cup-3 entries; the first gets the full pillar, later ones `:nozarashi-half` (the blobs half as fast, the ring × 0.5) | — |
| P10 atlas | **not built**: the charcoal style is not too thin (the Bankai heat, the burnout wisps and the charcoal puffs read at gameplay distance and in the Bankai close-ups: `style-final-gallery` bankai-128) | it would need a texture binding in `fs_fx_toon` (an engine change) for no visible gain |
| CA / fisheye | not built: no review asked | §9 |

**Measured (final build).**
- G1: engine/ and game/ untouched; the RAVEN title and wave stills byte-identical to a BASE `dist/base6-game` built before
  the phase (noise floor 0 px), cons/frame 17 369 B = base.
- G2 (`style-gates.py cvc dist/duel`): yy `winner P2 konpaku 0-1 ticks 13914 secs 231.9`, yk `winner P2 konpaku 0-4 ticks
  9305 secs 155.1`, kk `winner P1 konpaku 6-0 ticks 7578 secs 126.3`; every hash line identical to `tests/style-cvc-ref.txt`
  (unchanged: a render-only phase).
- G3: 0 B for 10 draws of every new per-frame look (debug 2391: the marks and chips with both pools full, a pillar and a
  fire wave beside the lens, the skull, the rain, both face accents, the face-change note, the grip step + IK, a caption
  slicing out); SOUL DUEL fight frame 28.4 → 29.2 ms (1.026×, A B A B A B against `dist/base6-duel`, measured before the last pillar-width tweak: noise); startup heap
  55.4 → 55.4 MB (≤ 110); page to first frame 3320 → 3040 ms.
- duel, game, duelvfx, duelview build with 0 warnings; `tools/pkgcheck.sh duel` clean; WGSL smoke green on all four;
  host tests pass (duel-rules-test 703, duel-control-test 53, input 31, cine 18, ecs, rules, test-math).
- `style-4-checks.py --run dist/duel`: 52 PASS (every `:len`, the pacing, the caption bounds at 1280x720 and 800x450 with
  the slice exits). `style-5-checks.py --run dist/duel`: all PASS (the HUD bounds, the Phase 5 cons). `style-6-checks.py
  --run dist/duel`: cons 0 B each; grip: keys only worst 436 mm, held worst 160 mm, median 0 mm over 346 frames. The
  Phase 6 face close-ups still differ pairwise by 10.9-15.4 % (Yamamoto) and 20.3-28.8 % (Kenpachi) of the crop.
- Stills: `tests/shots/style-6-<name>.png` (the destruction in play, the pillars behind the lens and from the side, the
  face accents, the kendo grip in play and the viewer's grip strips (each pair: keys only | held), the slice exits in
  Jokaku, Kenpachi's Kikon and a callout column, the skull, the rain, the redrawn cores in the VFX gallery, the fog trial),
  `style-6-before-<name>.png` (the same scripts on the BASE build), `style-6-gallery.png`, `style-6-pairs.png`, and the
  **final review sheet** `style-final-gallery.png` (`style-6-final-*`: gameplay in both cameras, Hellfire, the fire wave,
  cup 3, Bankai, Buttagiru, a guard break, every Kikon and awakening at its caption beat and its impact, Soul Break, the
  intro, the K.O. with its rain, the results card, the six face close-ups and the face accents).

**Open.** User review 4 (the final one). The fist's residual on DO's wind-up frame (a longer left arm or an extra key would
reach); the face accents inside Kenpachi's cup-3 aura; a rain sound; the hair lift of cup 3's grin (a hair rig).
