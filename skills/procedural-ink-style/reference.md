# C. Art, presentation and audio style: lessons from ai-cl-game-test

Source repo: `/media/8tsp/projects/ai-cl-game-test` (CL → ECL → wasm, SDL3 GPU / WebGPU; no asset files).
Main evidence: `docs/style/STYLE_STORM_DESIGN.md` (SD), `docs/style/STYLE_STORM_RESEARCH.md` (SR), `docs/engine/AUDIO.md`,
`docs/babylon/BABYLON_LOOK.md` (BL), `docs/duel/DUEL_MOBILE_DESIGN.md` (MD), `docs/DEVLOG.zh-TW.md` (DL), `duel/lisp/*`, `engine/lisp/*`,
`tools/*`, `tests/style-*`. "G" = generalizable lesson, "P" = project-specific fact or number.

## 1. Style pillars and how the style was decided
### 1.1 The look in one sentence (P)
- SOUL DUEL v4 brief (SD §A): use the *techniques* of Naruto Ultimate Ninja Storm (toon shading, ink hulls, drawn and
  stepped effects, impact frames, the cinematic camera) to draw a world in *Kubo Tite's notan*: big black masses against
  stark white, lots of negative space, near-empty backgrounds, a cold, dark, despairing base tone, and colour used only
  as rare spot colour.
- RAVEN EDGE (DL §6.1–6.2) took a different route: flat-shaded low-poly vertex colours with ±6 % per-face brightness
  jitter for a "hand-made" feel, a rainy neon night, fog, 8 point lights and bloom. Same engine, two looks. Every new
  toon path was added as a separate entry point or keyword that defaults off, so RAVEN's output stayed byte-identical.

### 1.2 The pillars as rules you can measure (P → G)
- **A 5-step value system** used for everything (SD §A.1): V0 black #08080C–#14151C … V4 white #EEEEEA–#FFFFFF, with a
  table of what each step is for. World saturation ≤ 0.12, hue kept in the cold band 210–240°. Skin is the only warm
  colour that is not a spot colour (S ≤ 0.3).
- **Figure against one balanced world** (user review 1): sky, ruins and ground all sit in one cold mid-dark range
  (luma about 40–125). The strongest contrast on screen belongs to the fighters (black robe V0 against white haori V4).
  Measured gates: world median luma above vs below the horizon differs by ≤ 75; world p2 ≥ 20 and p98 ≤ 150;
  fighters' luma span ≥ the world's span + 60.
- **Exactly 3 spot hues**, each with an owner (SD §A.2): FIRE red-orange (Yamamoto), REIATSU yellow (Kenpachi, in
  every form), BLOOD red (shared: counter, Kikon, Breaker). Everything else is monochrome plus at most a cold steel tint.
  Budget: in neutral stills, spot pixels (S > 0.45) ≤ 15 % of the frame. The owner's big moves may exceed it.
- **Edge rule for effects**: an edge takes the value opposite to the shape's body. The user then removed every dark
  outline on effects at review 2 ("the effects look better with the black edge lines removed"), so the rule became
  data: the edge column of the palette table changed and no code changed (SD §3.3).
- **Motion**: bodies move smoothly pose to pose (ease-out keys, holds, 1-frame squash smears). Effects are *stepped*
  on a shared 24 Hz fx clock, at rates set per material: hit flash on ones, fire and energy on twos, smoke and dust on
  threes (SD §3.5).
- **Typography as art**: vertical brush kanji captions that are 50–70 % of the frame height, a small romaji reading, and
  a red hanko only on Kikon names (SD §4.4). The pixel font is kept only for HUD numbers, tables and menus (user review 3).

### 1.3 How the decisions were made (G)
- **Research first, in a graded form** (SR): the `deep-research` method run in "condensed full" mode. A scoped research
  question with sub-questions, 29 sources, and every claim tagged [V] verified primary / [V2] secondary report /
  [I] inferred / [U] unverified. **[U] is never used for a decision, and every decision that rests on [I] gets a
  verification step.** Rejected sources are listed with the reason. Devil's Advocate checkpoints cover scope,
  cherry-picking ("are we building Guilty Gear and calling it Storm?") and the strongest counter-argument. There is an
  ethics / AI-disclosure note (a style study by procedural means, no copyrighted assets).
- **Synthesis into ranked traits**: "the 10 traits that read as Storm", plus a list of incidental things to skip
  (particle counts, lens flares, LODs, deferred rendering) (SR §6). A later addendum added "trait 0: figure / ground".
- **The design doc went through recorded critique rounds** (SD §13): an internal Devil's Advocate on v1 (18 findings);
  separate *art-direction* and *rendering-engineering* critiques of v2, each point given a verdict (accept / reject /
  defer) and a pointer to where it landed; then the conflicts between the two critics written up with who won and why.
  Example: per-shape phase offsets (art) against one coherent clock (tech). Tech won on phase and art won on
  per-material rates.
- **The user decides at a few gated review points, by looking at stills, not mood boards.** The Phase 0 reference board
  was skipped by the user's choice, and screenshots after phases 1a, 3, 4 and 6 replaced it. Each review is recorded
  as a table: the user's words (zh-TW, translated), the decision, the consequence (files and sections).
  Rounds 4–7 changed the direction (blue hour → notan), balance (no black top / white bottom), proportions (chibi →
  realistic adult), edges (no dark ink on effects), pacing (cinematics ×1.45 slower, fewer and longer shots) and the
  typography (all callouts in brush).
- **Questions sent to the user always carry a default** ("(default approved) keep the yellow FIRE core"). The user
  only answers what they want changed; everything else ships at the default. "Open items for the user" is a standing
  doc section (SD §12) that ends "None" once it is closed.
- **Every decision is written into the repo docs**, not left in the chat: a zh-TW summary at the top of each design
  doc, an English body, DEVLOG entries, and a "Decisions at a glance" table (SD §0) with a "Why" column.
- **Reversals are logged as reversals**, e.g. "v3 positions reversed by round 4, and why" (SD §13). This stops the
  same argument from being reopened later.
- **BL as a decision record for a port**: a reviewer's (Fable) critique was turned into the next batch's spec. It
  starts with "what B1 got wrong (root causes)", then gives numbers as starting points ("screenshots decide"), then the
  user's answers. Examples of root causes found: a fighter was ~21 % of the frame height where anime framing is
  45–60 %; faces were drawn with 11 px lines on a 256 px cell, so a ~25 px head became a smudge; sky, floor and walls
  all sat between the haori's white and the hakama's grey, so the frame had no contrast.

## 2. Procedural pipelines
### 2.1 Bodies from primitives (P: `engine/lisp/body.lisp`, `duel/lisp/body.lisp`)
- A character is a list of simple shapes per rig joint, one rigid mesh per joint, no skinning:
  `(:box w h d) (:bevel …) (:cyl r h) (:cone) (:sphere r) (:wedge)` with `:at :rot :c palette-key :seg :top :stretch :tag
  :ink k` and `(:glow e shape)`. Meshes are built once at load. Vertices are 9 floats (pos, normal, colour).
- `defbody` takes `:scale :width :hunch :hurt-r :hurt-h :palette :rim :props :girth`. `:props` sets the rig
  proportions (arms 1.12, shoulders 1.08…). `:girth ((joint sx sy sz))` scales that joint's shapes in the joint's own
  frame. This is how "realistic, not chibi" (user review 1) was done as data, without remodelling: head 0.240 →
  0.159 m wide, 7.1 → 8.2 heads tall, with heights and hurt cylinders unchanged (SD §14).
- `body-variant name of :palette :parts :clips :ink`: an awakened form is the same rig and hurt cylinder (so the sim
  can't tell them apart), with a palette override, extra parts, its own replacements for shared clips (the oni's prowl
  and guard), and its own keyline (the white Rukia is outlined in ice #7F97B4, not ink).
- Faces are tagged shape sets `:face-neutral / :face-shout / :face-hurt`. A draw hides the other two. The face is
  picked from fighter state: hurt while stunned or down, shout from 10 f before a heavy hit to 12 f after it. Box
  faces only work at gameplay distance, so the design rules out face close-ups under 1 m (risk R7).
- Small inner strokes are thin `:c` boxes under 4 cm. They take the **opposite value of their part**: white folds on
  black cloth, ink on white cloth (Kubo's "white line on black").
- Toon bodies set `*part-jitter*` 0 and `*part-smooth*` t (round normals on spheres / cylinders), so the shading line
  reads as drawn instead of popping across faceted boxes.
- Weapons (`defweapon`) are built in their own frame (grip at the origin, blade along +Y) and split into blade and hilt
  sections, each with its own ink width.

### 2.2 Rig, poses and clips tied to sim frames (P: `engine/lisp/anim.lisp`, `duel/lisp/*-art.lisp`)
- `defpose name (:base other)` writes a list of `(joint :flex :twist :side)` in degrees, plus root channels
  `(:root :r :u :f m :yaw :pitch deg)`. A later spec overrides an earlier one, so a hit pose can be written as "the
  old keys, then adjustments".
- `defclip name (dur :loop :fps :marks :base)` takes keys `(time [:snap] [pose] specs…)`.
- **`defstrike name (S A R :base stance)`** is the attack form: `defclip` with `:fps 60` and marks `:s` / `:a`, a total
  length of S+A+R, and key times written as frame numbers or `:s`, `:a`, `:end`. **The move's frame data (startup /
  active / recovery) lives in the header, so the hit pose lands exactly on the first active frame.** The authoring
  pattern (yama-art.lisp header): a held wind-up → `:s :snap :ya-q1-hit` (a named hit pose) → a small overshoot held
  through `:a` → half-way recovery → `(:end :stance)`. `*key-ease*` 1 gives ease-out cubic between non-snap keys
  (pose-to-pose timing; RAVEN keeps smoothstep).
- **`:root :f` / `:u` offsets** carry the body forward or down inside the clip, e.g. `(:root :f 0.65)` on a lunge's
  hit pose. They are cosmetic. The sim's real displacement is the move's own `:slide`. When J reach was raised to
  ≥ 1.4 m (commit c1f5ca0), "the short J clips step in on their active frames" so the art kept up with the hit volume.
- **Poses are cosmetic by contract** (SD §1): only draw code reads joints, and the sim never reads a clip. Holds,
  smears and stepping therefore cannot change gameplay, and the CvC hash gate (G2) proves it after each phase.
  Phase 5 re-authored all 29 attack clips pose to pose with the `defstrike` headers byte-identical.
- Shared reactions (`:sh-walk-f`, `:sh-kikon-victim`, …) are played by every character on the same rig. A character
  overrides them through `:clips`, so generic files never name a character.
- Clip speed in cinematics: `(cine-clip a :ya-kikon :speed (/ 77.0 142.0))` re-times an existing clip so its hit lands
  on a new beat, instead of re-authoring it.
- **`tools/pose-solve.py`**: a Python mirror of the FK for the right arm and blade. You give it a body pose and the
  wanted blade azimuth / elevation, and it grid-searches `hand.twist` / `hand.flex`. Blade directions are then reused
  across characters ("diagonal = rb-slash, horizontal = h1 …", yama-art.lisp). G: when authoring by numbers, build a
  tiny solver for the one angle that is hard to eyeball.
- Two-handed grips: a draw-time IK fix (`grip-left!`) pins the left fist to the handle, checked by
  `style-6-checks.py grip` (median 0 mm, worst ≤ 170 mm).

### 2.3 Rendering the look (P: SD §2–3; engine `toon.*.wgsl`, `fx.lisp`, `render.lisp`)
- `fs_toon`: two tones with a crisp line (smoothstep ± 0.02). The **shadow colour is designed in HSV**: value × 0.72,
  saturation × 1.25, hue shifted 8° (in opposite directions for warm and cool colours); neutrals and whites go to a
  cold blue-grey (h 0.61). It is computed per vertex in sRGB, because the linear version came out far too light for
  notan. No ACES and no exposure, so the lit tone equals the palette colour exactly. A CC2-style vertical gradient
  (×0.86 toward the feet) is applied on characters only.
- The key light comes from **camera axes** (lit share about 7:3), so a camera cut never flips the shading. Characters
  get 0 per-pixel lights. The nearest effect light only warms the *shadow* side (×0.35), so a fireball tints Kenpachi
  without breaking the palette-exact lit tone.
- **Ink hull** (inverted hull rather than post-process edges): it needs no depth texture, costs +3 %, and draws the
  lines where parts overlap for free. The expansion vector is built from quantised face normals with a clamp (0.55
  for boxes, 0.8 for cones, so no "ink needles"), and the width multiplier is baked into that vector, which leaves the
  vertex colour free for a per-shape ink colour (red-brown on skin, cold grey keyline #4A5062 on black cloth, near
  black elsewhere). Width is in screen pixels (1.8 px at 720p), with a taper by facing: full on the silhouette, 0.45
  on overlaps. Shapes under 4 cm and stroke boxes get no hull. The 15-panel haori needed an "ink art pass" (`:ink 0`
  on inner panels) so seams did not get outlined.
- Afterimage in two drawings: an opaque white flash silhouette, then the hull only (a front-culled empty shell renders
  as a solid ink silhouette, i.e. a black afterimage), then gone. **There is no alpha < 1 body anywhere**, because
  the transparent pass has no depth write and would show the insides.
- **Effects are vector "ink shapes", not a texture atlas**: one pipeline, no textures, alpha-to-coverage for crisp
  depth. Primitives: `fx-star` (irregular spikes, 1–2 long ones along the hit direction), `fx-crescent` (Bézier strip;
  `:lens` and `:comet` profiles for sword smears), `fx-shard`, `fx-wall` (a scalloped flame wall instead of a picket
  fence of separate tongues). `fx-envelope (flash grow hold out) :anticipate` is the shared timing macro, and **every
  one-shot effect is written as an envelope call, not as prose**. Each signature effect has 4 layers: a dark backing,
  the drawn mass, a thin additive glow (T光), and 2–6 scraps.
- 12 palette slots (core / body / shade / edge / style) live in a WGSL constant. Each effect uses ≤ 3 hues: one spot
  hue plus black and white.
- **Positions the gameplay depends on are never stepped**, only their shapes (fire wave, projectiles).
- Screen punctuation in a separate composite pipeline that runs only while active: negative, two-tone, **manga page**
  (two-tone, but pixels with S > 0.45 keep their colour), and **spot-keep desaturation** (grey except hue 10° ± 25°,
  and since review 2 also 48°, used through all 20 s of the Bankai). Chromatic aberration was cut (+3 ms measured).
  UI helpers (0 B): focus lines, speed lines, `ui-ink-splash` (a hashed 14-gon, spikes, droplets). Shake is drawn at
  12 Hz in 3–4 discrete offsets (RAVEN keeps 30 Hz).
- Stage (P: `stage.lisp`): night ruins as cold-grey paper cut-outs whose moon-facing caps catch a thin edge light; a
  huge flat moon placed behind the arena from the pair view, so fighters stand against it; a mid-grey plaza with 8
  hand-placed ink cracks; falling white ash on threes; hard ink ellipse shadows. Stage fires were removed because
  warm colour is reserved for effects. Fight damage stays on the ground: a pool of 20 marks (scorches, cracks) and
  24 resting chips, placed from feedback events and cleared at reset.

### 2.4 Brush glyphs (P: `tools/glyph-bake.py`, `duel/lisp/glyphs.lisp`, `brush.lisp`)
- An OFL brush font (Yuji Syuku) is baked **offline** with fontTools and skia-pathops: overlaps removed, curves
  flattened (1 unit), Douglas–Peucker (2.5 units), holes bridged into the outer contour. The result is integer
  polygons in 1/1000 em, written to a generated, committed `glyphs.lisp` (109 glyphs, 78 KB) with the licence in the
  header and in `duel/FONT-LICENSE-YujiSyuku.txt`. At load, `brush-init` ear-clips them (exact integer tests).
  **No font file is loaded at run time.** To add a glyph: add it to CHARS, re-run, commit.
- Why triangles and not a texture: the UI batch binds one nearest-sampled pixel-font atlas. A linear brush texture
  would have needed a second UI pipeline, while triangles need no engine change and scale to any size.
- Captions (`bcap`): `:cine` / `:callout` / `:results` layouts; stamped in on twos (scale 1.8 → 1.15 → 1, an ink
  splash, a drawn shake); sliced out with one diagonal brush cut and the halves sliding apart over 4 drawings.
  `draw-bcap` conses nothing and logs any caption whose em box leaves the screen. "Bleed off the frame" was tried and
  dropped: it read as clipping.

### 2.5 VFX and feedback architecture (P: `vfx.lisp`, `feedback.lisp`)
- **The rules decide, events report, presentation shows**: fighters, combat and hazards emit small events
  (`(:hit att def x y z hitstop counter-p dmg kind)` …). `feedback-system` runs once per step, last, and turns events
  into sound, sparks, shake, callouts and stage marks. All cosmetic code uses `rnd01`, never `sim-rnd01`.
- **Hitstop is sim timing** and is decided in combat, not feedback: "determinism must not depend on the presentation
  code" (DUEL_DESIGN). Never call hitstop inside a cinematic.
- `show-hit` scales feedback with the hit: shake 0.03 / 0.09 / 0.22 by damage tier; a heavy hit holds the attacker's
  pose 3 f and smears the victim along the hit; fire scorches the ground, a 150+ hit cracks it; `model-flash` =
  hitstop/60.
- A one-frame squash / stretch smear (×1.5 along the motion, ×0.7 across it) on dash and heavy-swing starts
  premultiplies every joint matrix (0 B).

### 2.6 Cinematics on sim frames (P: `engine/lisp/cine.lisp`, `duel/lisp/cinema.lisp`, `yama.lisp`)
- `(defcine name (a v :len N :hold H) …)`: `(at frame …)` runs once on the fixed step (step mode: deterministic,
  replay-relevant); `(during (from to) …)` runs every rendered frame with `u` going 0..1 (draw mode: looks only).
  `:len` is sim time and must never change for look reasons; `:hold` is only the debug screenshot frame.
- **The rules decide, cinematics present**: by the time a script starts, the outcome (Konpaku, form) is already
  settled, so skipping a cinematic loses nothing. While a cinematic runs, the sim systems are frozen.
- Shot vocabulary as helpers: `card :black/:white` (the stage is not drawn, only the actors on a flat card),
  `shot-on`, `shot-pair`, `lens fov roll` (dutch angle), `hold-both`, `impact-frame :negative/:two-tone/:manga n`,
  `silence n` (music to 0.1, cinematic sfx suppressed), `back-rim`, `caption`, `caption-exit`, `cine-grade :spot`.
- **The grammar** (SD §5): beat 0 (the gameplay shot frozen plus a 2 f negative) → wind-up on a card (low angle, 10°
  dutch, ink splash, vertical caption, silence) → establishing wide → cut on the action (at most one orbit, ≤ 90°,
  over ≥ 10 f) → hold (poses held, fx clock paused, silence) → impact (negative → manga page → white flash → drawn
  shake) → aftermath wide. Card colour is chosen by notan: the white-haori character goes on black, the black-robed
  one on white.
- Pacing lesson (user review 3: "the cuts are too fast, slow it down"): ~1.45× longer, done with **fewer, longer
  shots** rather than a uniform stretch. Every shot is ≥ 20 f except beat 0 and the 1–3 f flashes. Holds: caption card
  26–28 f (+30 f after a later decision), reveal 28 f, pre-hit freeze 20–22 f. Impact frames stayed as sharp (2 f
  negative, 10–12 f manga page). The actors' clips were slowed with `:speed` so hits still land on the new beats.
- A camera fix done once in the shared camera code instead of per shot: `shot-on` records its subject and
  `%keep-subject` pans so the posed body stays in frame (a clip's root motion carried Kenpachi up to 1.4 m off his
  feet) (DL §20).

### 2.7 Synthesized audio and music (P: `engine/lisp/audio.lisp`, `engine/c/audio.c`, `duel/lisp/sounds.lisp`, AUDIO.md)
- `(defsound key (:peak p :loop l) body)` uses an `au-` toolkit: oscillators, a C xorshift noise source (no consing,
  deterministic), AR / ADSR / exp envelopes, a TPT state-variable filter, drive, delay, reverb (4 combs + 2
  allpasses), and instruments (`au-partials!` for inharmonic metal, `au-thump!`, `au-taiko!`, `au-gong!`, `au-shaku!`,
  `au-saws!`). Example `:clang` = 6 inharmonic partials (710/722/1930/3510/5800/8400 Hz) + an HP noise click + drive.
- Init post-processing for every buffer: NaN/Inf zeroed, a 15 Hz DC block, a 5 ms end fade, normalised to `:peak`
  (≤ 0.95). Loops are made seamless by rendering 2.5 s past the end and **folding the tail onto the head** (`au-fold`).
- Rendered at startup, **one sound per browser frame with a GC after each**, then copied into C memory. RAVEN: 26
  sounds in ~800 ms, 9.1 MB. The Babylon port renders 63 sounds (16 MB) in a Web Worker in ~1.3 s.
- Mixer: a pure-C SDL stream callback that never touches Lisp objects; 32 voices; steals the quietest voice
  (gain × amp × remaining); never steals a loop; ids `serial<<5|slot` so a stale id can't stop a newer voice; peak
  limiter. Autoplay: also resume the AudioContext inside keydown / pointerdown / touchend handlers, because Safari
  wants it inside the gesture.
- Music: modal and genre-coded (battle: 100 BPM, D phrygian, taiko + low saws + shakuhachi, 19.2 s; title: 60 BPM, gong
  swells, koto-like plucks). "No samples, no voices": a laugh is a formant bark, a call is a detuned chirp chord.
- **Silence is a sound design tool**: silence beats before every impact, taken from TYBW's fire sequence where only
  bone sounds were kept [V: K4]. `:obliterate` / `:kikon-slash` start with a reverse swell, so the impact lands
  ~300 ms after the call; schedule for that.
- Cinematic sound beats are keyed to *cine frames*, so they follow sim time whatever the shots do (the Babylon
  `cues.ts` is generated from the DEFCINEs).

## 3. Consistency checks (the "style is tested" part)
### 3.1 Deterministic screenshots (G, P: `tools/run.mjs`)
- `run.mjs --fixed-dt MS`: a virtual clock. `performance.now` / `Date.now` advance exactly MS per frame, each frame
  waits for the GPU, script times are virtual, and the page is held while a screenshot is taken. **The same binary and
  script give byte-identical PNGs (noise floor 0 px).** Three causes of flaky stills were found and fixed: SDL skipping
  a frame whose swapchain texture was not ready (so the shot showed an older frame), headless focus loss pausing the
  game, and a fixed debug port hitting a leftover Chrome.
- Scripts are JSON steps: `key`, `eval "Module._debug_cmd(N)"`, `shot`, `size`, touch (`--mobile --dpr 3`). It exits 1
  on JS exceptions **and on WebGPU validation errors or failed pipelines**, which makes it a WGSL smoke test for free.
- **Debug commands encode scenes as integers** (debug.lisp): `10000+1000k+f` = cinematic k held at frame f with the
  effects frozen; `2200+k` = force a cinematic; `2300+k` = force a special; `2700+k` = mobile probes. Any still can be
  reproduced from one number.
- Shot scripts build **contact sheets** for review (`tests/batch-shots.py`, `style-N-shots.py` →
  `tests/shots/*-sheet.png`, `style-final-gallery.png`; 1137 committed PNGs). The user approved the whole restyle from
  `style-final-gallery.png`.

### 3.2 Standing gates after every phase (SD §9; `tests/style-gates.py`)
- **G1 identity of the other game**: RAVEN frozen stills byte-identical (base built twice to get the noise floor),
  ECL-generated C diffed function by function, consing within +10 %, frame time within noise.
- **G2 determinism**: CvC result and hash lines unchanged against `tests/style-cvc-ref.txt`. This is what lets the
  art change freely: poses and effects are cosmetic by contract, and G2 proves it.
- **G3 budgets**: 0 B consing for 100 calls of every new per-frame path; perf median of 3 runs A/B in the same
  session (SwiftShader noise is ±10 %); startup heap ≤ 110 MB; first frame ≤ +10 %.
- `duelstill`: a frozen duel still, the same frame without fighters (the **fighter mask**), a version without shadow
  discs (to check the outline), and a "flat" version (no gradient, fog or vignette) to check exact palette tones.

### 3.3 Pixel checks of the style rules (`tools/toon_check.py`, `tests/style-{2..6}-checks.py`)
- `toon_check.py`: share of pixels per value step V0–V4; world *chroma* (max−min channel, because HSV saturation
  flags the design's own cold greys; measures were adapted to what the design *means* and the reason is documented);
  spot share; balance above / below the horizon; fighters' tones against the palette and the `shade_of` tones;
  outline continuity (≥ 90 % of mask edge pixels have ink within 2 px, split by sky / ground); `--ac` exits 1.
- style-2: effects change **only on fx-clock ticks** (36 consecutive frames, a change only every 5th); pause → two
  frames 1 s apart identical; manga mode keeps FIRE and BLOOD pixels; ordinary hits have no spot pixels.
- style-3: spot budget split by hue (FIRE 0–40°, REIATSU 40–70°, BLOOD 330–360°); neutral stills ≤ 15 %.
- style-4: **cinematic scripts linted as data**: every Kikon has beat 0, ≥ 1 card, ≥ 3 cuts, ≥ 1 inversion, ≥ 1
  silence ≥ 8 f and a caption, and `:len` is unchanged; pacing: every shot ≥ 12 f and the mean ≥ 20 f; the Bankai
  still contains only ember and yellow hues; no caption glyph off screen at 1280×720 and 800×450.
- style-5: three face states differ pairwise; no callout drawn over a HUD panel (the HUD *logs* overlaps and the test
  greps the log).
- Babylon port: per-sound length / peak / RMS / DC stats, and every event kind and every cinematic's beats checked to
  render NaN-free.

### 3.4 Art against hit volume (P: `tests/duel-rules-test.lisp`, search "the volume ends")
- The host test **loads the real `anim.lisp`** (with the C float intrinsics replaced by plain CL macros), reads each
  `*-art.lisp` file form by form (evaluating only `defpose / defclip / defstrike`, collecting `defbody` and `defweapon`
  data), then for every form and every J / K link and the Breaker runs FK over the active frames
  (`clip-sample!` + `pose-fk!` with the body's scale, hunch and proportions). It measures the weapon tip (or the
  striking fist / foot / sleeve from `*strikers*`, or a prop's far end) and compares it with the hit volume's far edge
  (arc radius, or capsule end + radius).
- Tolerance: within ±0.15 m for J links. K links may fall short (fire, ice and cloth carry them), but never pass the
  edge by more than 0.15 m. Documented exceptions: a ruined-arm form (≤ 0.6 m) and forms that borrow another form's
  clips (`*reach-one-sided*`).
- Origin (DL §32): the user said Senjumaru's J / K hitboxes reached much further than her animation. Shrinking the
  hitbox to the needle tip made her lose almost every match (she was out-ranged, not under-damaged), so the fix went
  the other way: the needle was lengthened from 0.9 to 1.8 m and the hit pose pushed 0.1 m forward. **G: fix
  art/hitbox mismatches on the art side when balance depends on the number.** The test was proven by reverting J1 to
  its old value and watching it fail.

### 3.5 Per-frame allocation limits in render code (P → G)
- ECL at safety 1 boxes floats in `let`, so hot code uses `defun-fast` (type checks at entry, the body at safety 0),
  macros, f32vec arguments, `with-fx-verts` / `with-ui-verts`, and the `*ribbon-args*` pattern (a preallocated f32vec
  of arguments instead of keyword floats).
- Keyword floats box, so `draw-mesh :toon` takes an f32vec. HUD strings are cached; colours are quoted literal lists.
- Each phase adds a debug command that draws every new look N times and logs `"vfx5 consing"` / `"brush consing"` /
  `"portrait consing"` lines, which tests check for 0 B. Known leftovers are written down (portrait HUD ~1.5 KB a frame).
- Load-time allocation (hulls, glyph triangulation, sound synthesis) goes in its own `:load` step with a GC, to keep
  the heap's peak ≤ budget.
- SwiftShader runs both sides of a branch, so a toon branch inside the shared shader cost +16 %. Separate entry points
  and pipelines cost 0 for the other game. Per-pixel light count is what dominates cost (8 → 0 lights: 33 → 15 ms).

## 4. Camera, HUD and readability
### 4.1 Telegraphs and hit cues (P)
- Every delayed or area move has a **tell drawn as its own function**, registered in the move's frame table
  (`:on-frame ((0 yama-shonetsu-tell) (16 yama-shonetsu))`): the garb flares for 16 f, a white ring under the target
  pulses faster as it nears (`TSUKISHIRO`), frost cracks radiate before a quake, a parry window is a white rim whose
  brightness is the timer. The CPU reads the same `:tell` frames, so tells are fair for both sides.
- **Counter hit**: `impact-frame :manga 2` (the frame goes two-tone, the red stays) + a red "COUNTER" brush word for
  0.6 s. The BLOOD spot colour is reserved for counters, Kikon and Breaker, so red always means "this was special".
- Hits are monochrome by rule; colour only appears on spot events. A 1-frame white flash on the victim; heavy hits
  hold the attacker 3 f; shake scaled by damage; a Kikon gets a 6 % zoom punch (BL).
- A Kikon-able victim gets a red soul flame over the head; "HOLD O KIKON" appears as a prompt (HUD).
- The fx clock pauses with the game, so HUD pulses and fades hold too (pause checked byte-identical).

### 4.2 Gameplay camera (P)
- Pair camera: a 3/4 side view that smooths the *orbit angle* around the midpoint (a strafing pair stays side-on).
  Which side it stands on is sim state, so it never swings 180° after a Hoho. `*cam-close*` 0.8 came from the art
  critique ("fighters too small"). Behind camera for VS CPU.
- Framing numbers that worked (BL polish): fighters 30 % (floor) to 48 % (ceiling) of the frame height; aim at
  0.55 × the taller fighter's height; a hard minimum distance of 3.2 m from either fighter, so a swung blade never
  fills the lens; FOV 50°. Head tops land at 24–40 % of the frame, under the ~22 % HUD band.
- Render-only camera adjustments never touch sim yaw (`*behind-turn*`), so future netplay stick mapping can't desync.

### 4.3 Mobile portrait (P: MD §4, §14–15, DL §18)
- "Look at the stills first": P0 portrait stills showed the landscape HUD squeezed into two 0.36 w columns (flames
  colliding, the combo counter over the timer, labels under the text floor), prompts cut off, and both fighters under
  the thumb chips.
- The user's decisions replaced the design: **the HUD split by fighter** (the opponent's block across the top, the
  player's across the bottom, both full width, 29 s ≈ 48 CSS px tall), and **fighters larger and low in the frame;
  the thumb may cover their legs**.
- Engine change kept minimal: a `camera-shift-y` lens shift written into the projection only when non-zero, so
  landscape matrices stay the same floats. The portrait camera then *fits*: the band between the HUD blocks spans a
  30° base FOV and widens only when the pair needs it (40–100°, smoothed; typically 41–53°).
- Text floor ≥ 11 CSS px (`s = ceil(11·dpr/7)`), measured by the engine (`*ui-text-min*`). Safe areas come from CSS
  `env(safe-area-inset-*)` passed into the game.
- Cinematics in portrait: FOV ≥ 66° plus a dolly-back so the tall frame's width holds the landscape frame's central
  square (≤ 2.4×). Close-ups (`shot-on` ≤ 5 m) keep the script's lens, so the body may be cropped (user decision).
  Vertical captions clamp to `min(0.6 h / n, 0.36 W)`.
- Verification: a probe (debug 2700) logs every 30th frame whether both fighters' upper halves are clear of the HUD
  blocks with ≥ 70 % of their width on screen. `mobile-probe.py` runs a 45 s CvC plus 5 set positions (1 m, 2.2 m,
  24 m against the wall, after a sidestep) at 4 phone sizes plus iPhone insets. Landscape stills were checked
  byte-identical to the previous commit.

## 5. Generalizable lessons for a new code-only game
1. **Write the style as numbers, not adjectives.** A value-step table, a saturation cap, a fixed set of spot hues each
   with an owner and a pixel budget, an edge rule, and timing rates per material. Numbers can be gated; adjectives
   can't.
2. **Contrast lives on the characters.** Put the world in one narrow value band and give the figures the widest
   span. Reserve saturated colour for meaning (owner identity, counter / critical). Check it with a fighter-mask diff
   (render the same frame with and without the characters).
3. **Do graded research before the design** ([V]/[V2]/[I]/[U]), list the incidental traits to skip, and put a
   verification step on every inferred claim. Then run separate art and engineering critiques, and record verdicts
   and conflicts.
4. **Review stills with the user at a few gates; send questions with defaults.** Record the user's words, the
   decision and its consequence in the repo docs. Log reversals so they stay closed.
5. **Keep presentation strictly cosmetic** (its own RNG, never read by the sim; hitstop and cinematic length are sim
   timing). Then prove it after every art change with a deterministic hash gate, which lets art iterate without
   re-balancing.
6. **Tie animation to frame data**: `defstrike (S A R)` puts the hit pose on the first active frame. Author pose to
   pose (held anticipation → snap to a named hit pose → overshoot → hold → settle). Re-time with `:speed` instead of
   re-keying.
7. **Test art against gameplay geometry**: run the real FK over the art files on the host and require the weapon tip
   to match the hit volume within a tolerance. When they disagree, decide which one balance depends on before
   choosing what to change.
8. **Primitives need extra treatment to read as drawn**: round normals on curved parts, no faceting jitter, designed
   HSV shadows, an inverted hull with a screen-px width and facing taper, opposite-value inner strokes. Avoid
   translucent bodies (use flash-white / ink-silhouette drawings instead).
9. **Effects as drawn, stepped vector shapes** on one shared fx clock with per-material rates, an envelope macro for
   every one-shot, a 4-layer recipe, ≤ 3 hues. Never step positions the gameplay depends on.
10. **Cinematics as a sim-frame script with a small shot vocabulary and a written grammar.** Lint the scripts as data
    (beat 0, cuts, holds, silence, min shot length). Pace with fewer, longer shots and keep impact frames sharp.
11. **Typography is part of the art.** Bake a licensed font offline into committed vector data (no runtime font
    files), and fit-check every caption against the screen bounds in a test.
12. **Synthesize audio with a small toolkit + `defsound` bank**, normalise, DC-block, fold loops, render
    incrementally at load, and mix in native code that never touches managed objects. Use silence as a beat. Key
    cinematic sounds to cine frames.
13. **Deterministic screenshots are the foundation** (virtual clock, frame-complete waits, focus emulation, exit
    non-zero on GPU validation errors). Encode reproducible scenes as debug integers, and build contact sheets for
    human review.
14. **0 B per frame is a test, not a hope**: every new per-frame look gets a consing probe line. Load-time work gets
    its own step with a GC.
15. **Shared engine, two games**: every new render path is a separate entry point, pipeline or keyword that defaults
    off, and the other game's frozen stills stay byte-identical (gate G1).
16. **Readability rules**: a fair tell for every delayed move (shared with the AI), feedback scaled by hit tier, and a
    unique colour plus screen event for counters. Frame fighters at ~30–48 % of the frame height with a hard minimum
    camera distance. On phones, split the HUD per player, keep a text floor in CSS px, measure framing with a probe at
    several sizes, and change the camera only on the render side.
17. **Fix at the shared root**: a camera that keeps the posed subject in frame instead of retuning every shot; edge
    rules changed as palette data instead of code.
