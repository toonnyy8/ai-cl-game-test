# SOUL DUEL (Babylon) — the look spec for M5 B2–B5

The user's M5 decisions are in BABYLON_PORT.md "M5 look". This file is Fable 5.1's review of M5-B1 (2026-10-04) turned
into the spec of the next batches, with the user's answers folded in. Numbers are starting points; screenshots decide.

## The user's decisions on it (2026-10-04)

- **Kenpachi's hair: the TYBW version**: worn down and long (after the Unohana fight), **no bells, no spikes**. No
  eyepatch in any form (as in the Lisp build).
- **Yamamoto's Bankai body: as in TYBW**: the haori comes off; he keeps the black shihakusho, with his one remaining
  (right) arm bared (the sleeve slipped off that shoulder); the left sleeve hangs empty as in every form.

## What B1 got wrong (root causes)

- `cel.ts`: default shadow (0.66, 0.66, 0.80) with a fighter threshold 0.0 puts half of every figure in blue-grey; the
  rim (0.35 × smoothstep, lit side) is invisible; black cloth has no lit band, so the kosode / hakama are flat.
- `scene.ts`: sky, floor, walls all sit between the haori's white and the hakama's grey: no contrast, a grey frame.
- `body.ts`: hakama ankle rings overlap into one skirt and the haori hem drapes over both legs; Kenpachi's 22 thick
  spikes fused into a mop (now replaced by the decision above).
- Faces: 11 px lines on a 256 px cell, the head ~25 px at battle distance: a smudge.
- `ink.ts` sparks: too small (1.1–1.6) and brief (0.3 s).
- Camera: fighters ~21 % of the frame height; anime framing is 45–60 %.

## B2: Yamamoto and Kenpachi base, stage, outline, camera, clips

**Palette.** Fighter threshold 0.18 (60 / 40 lit), hard band 0.01. Lit / shadow pairs: haori `#F6F3EC / #A9B2CF`; black
cloth `#2B2D3A / #121319` plus a lit crease band; obi `#E9E4D6 / #9A9DB5`; Yamamoto skin `#F2CBA3 / #C98C68`; Kenpachi
skin `#E4B48C / #B2724F`; black hair `#2A2B38 / #0E0F15` with 2–3 white highlight strokes `#D8DCE4`; blade
`#F4F6FA / #9AA6C0` with a bright edge stripe. Rim per character's reiatsu, Yamamoto `#FF7A2A`, Kenpachi `#F5D54A`,
width 0.08, scaled by aura state. Saturation: cloth ≤ 0.15, skin and accents 0.35–0.5 (full colour).

**Kenpachi.** Long straight black hair down past the shoulders (TYBW), a few heavy locks over the forehead, highlight
strokes; open collar, chest scar; torn short sleeves; a grin as the neutral face; chipped long katana.

**Yamamoto.** Hunch: spine −12°, head +8° in idle; thick long brows (0.07 H); beard to the obi with three lit strokes;
**empty left sleeve** (one-handed, DUEL_DESIGN §6.1: the rig keeps the bone, the sleeve hangs flat); cane hilt.

**Hakama.** Per-leg ankle radius ≤ 0.45 H, four pleat creases per leg, the koshiita board at the back, a visible gap
between the legs in step / dash poses; haori hem above the knee with side vents so the legs show.

**Faces.** 512 px per cell, lines ×2 (22 px), sclera as a white block, 14 px pupils, brows as filled wedges, a 48 px
shout mouth; plane 0.9 H. Plus a contact shadow under each fighter (`#141420`, alpha 0.5, r 0.45 m).

**Outline.** Fighter radius h/300 (3 px at 1080p), weapons the same; interior crease threshold 0.5–0.8 at 1 px; hair
silhouette only (no interior normal edges); stage 0.5 px at 50 %.

**Camera.** Pair camera distance ×0.7, FOV 50°, never a fighter under 35 % of the frame height; the HUD's top band 18 %.

**Stage and light.** Sky gradient quad, top `#2E4C8C` → horizon `#A6C8EC` (or dusk `#4A2E5C` → `#F2A25A`), one
hard-edged cloud band; floor `#C8B38C / #8C7858`; curb and rings `#7A6A50`; walls `#F3EEE3 / #8A90A8`. Key light from
top-left-front, 35° up, fixed in the world (not camera-relative). 2 % paper grain and a soft vignette in the FXAA pass.

**Clips, by screen time.** Both: walk / run (Kenpachi runs with the blade on his shoulder), guard, flinch / stagger /
knockback / air / down, Hoho. Yamamoto: Q1–Q3 one-handed iai draws, F1 / F2 heavy fire cuts, TAIMATSU, ENJO thrust,
the Kikon dash-cut. Kenpachi: Q1–Q3 wide one-hand hacks with the head low, KUKAN-GIRI's sweep, the two-handed leap,
the charge, KITTE MIRO YO. Readability: the weapon smeared along the arc during active frames, an ink arc ribbon from
the blade-tip history (dry brush; ink normal, red for Kikon / awakened, slate on block), a 1-frame white flash on the
first hit frame, camera shake 0.05–0.2 m by damage over 8 f, a 6 % zoom punch on a Kikon.

## B3: the other bodies and every awakened form

- **Rukia** (DUEL_RUKIA §2): 1.44 m, all-black shihakusho, no haori, white lieutenant armband on the left arm, short
  black bob with a centre strand, violet eyes; white katana with a hollow snowflake guard and a long white ribbon (fx).
  **Zero / white**: white hair and irises, skin `#D6CCCA`, an ice half-crown behind the head, shoulder crystals, an ice
  blade, an ice-blue outline `#7F97B4` (per-fighter ink colour in `outline.ts`).
- **Ichigo** (DUEL_ICHIGO §2): tall, black shihakusho, spiky orange hair `#E8792E` with two lighter strokes, a scowl; the
  long cleaver with a hole (right) and the hiltless stone knife held reversed (left, `weapon_l`). **KESSA**: barefoot,
  the left half of the hair and face black, two flat white horns at the hairline, robe open on a dark-red disc,
  blood-chain fx at neck / wrists / ankles, one white Tensa blade with a thick black line.
- **Senjumaru** (DUEL_SENJUMARU §2): 1.58 m on okobo (+0.10 m), head ×1.3, white haori over an ankle-length white robe,
  long black hair with side locks, a gold crescent-with-rays halo, six gold skeletal arms (the rig's arms are the upper
  pair; four echo arms trail 2 / 4 f late), empty sleeves, a 0.9 m white-gold needle with a thin red thread; two calm
  expressions. **Bankai**: the body stays; the domain is the look (torii → golden loom, red-carpet crossroads, cloth
  walls): stage / VFX work.
- **Yamamoto Bankai**: the user's decision above (no haori, black shihakusho, the right arm bared, empty left sleeve).
  East: a charred blade with an ember-red edge, four charcoal heat wisps. West: wrapped in red brush-flame tongues,
  charcoal blade.
- **Kenpachi Nozarashi** (DUEL_NOZARASHI_V2): the 2 m cleaver replaces the katana (shoulder-carried running); cup 1 one
  hand, cup 2 jodan two-handed idle + a taller aura, cup 3 a pillar aura + white rifts. **Bankai** (DUEL_KEN_BANKAI):
  crimson skin `#9E3A32 / #5E1E1C`, two horns, white irisless eyes, the broken cleaver, a blood pillar aura. **KATAUDE**:
  one arm (the left hidden), no aura.

## File split before B2 / B3 run in parallel

`body.ts` keeps the tube / limb / ellipsoid / rig / merge helpers; `render/bodies/{yama,ken,rukia,ichigo,senju}.ts` each
export `spec`, `parts(sp, rig)`, `drawFace`, `weapon`, awakened forms as a `variant` plus extra parts;
`render/clips/<char>.ts` holds the move → clip table and that character's clips (`anim.ts` looks them up by character).

## B4: VFX and the ink HUD

Hazard looks (wave, fireball, Ennetsu pillars, line, crack, Tsukishiro ring, rifts, Shonetsu); auras (base, awakened,
pillar, oni, zero, KESSA) as CPU `ParticleSystem` brush sprites; sword / ribbon trails; Hoho afterimages; Kikon /
Soul Break brush-calligraphy cards (kanji from stroke paths or a bundled brush font); negative / manga-page frames as a
post flag; paper grain and vignette; the HUD redrawn in ink (brush bars, kanji labels, cup pips, arm pips, Senjumaru's
meter from `senjuMeter`).

## B5: cinematics and audio

Shot scripts per `CINES` entry summing to its `len`; camera rails; letterbox; white / black caption cards; body and
weapon swaps on a frame; the awakening sequences; then WebAudio: per-event sfx, callouts, music (docs/AUDIO.md).
