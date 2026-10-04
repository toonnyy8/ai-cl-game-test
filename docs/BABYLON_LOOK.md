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

Done (B2-look): `cel.ts` threshold 0.18 with a 0.01 band; per-vertex lit / shadow pairs (a `shade` attribute; `pair(lit,
shadow)` or a `[lit, shadow]` tuple anywhere a colour is taken, else a derived warm / cool shadow); a third, lit crease
band on dark colours; the rim is screen-space (the G-buffer depth a few px away from the light on screen is background
or farther), h/160 px in the character's reiatsu colour (`spec.reiatsu`, else scene.ts `REIATSU`), x1.3 awakened, x1.4
gathering; the key light is fixed in the world; contact shadows on the floor material. `outline.ts`: fighters h/300,
weapons 1 px (h/300 on both sides swallowed a blade at battle distance), creases at 1 px (0.5–0.8), hair silhouette
only, the stage 1 px at 30 %; the ink id comes from its own render target (an INKID pass of the outlined meshes), not
the colour alpha, so blended VFX can't change it; paper grain 2 % + vignette after FXAA. `kimono()`: separate hakama legs
(ankle 0.44 H) with four light pleat lines each, the koshiita, haori hem / vents (three panels below the vent top),
lapels as flat bands from the neck into the V, options `haori: false` (or `noHaori`), `sleeves: 'full' | 'none' |
'torn' | 'flared'` (+ `lining`), `haoriSleeves: 'none'`, `emptyL`, `bareR`. Faces: 512 px cells (drawers keep 256-unit
coordinates), plane 0.9 H. Camera: x0.7, lower (1.85 m + 0.1 / m), FOV 50, the shorter >= 35 % (while both fit), the
taller <= 60 %; HUD top band needed: 18 % (heads reach 0.12–0.2 of the frame from the top at close range). The
animator: per-character `poses` overrides and bespoke `Clip`s from `clipFor`; smear ribbon over active frames; a
one-render-frame white flash on the victim's hit; shake by damage, Kikon / Soul Break punch. Yamamoto: every move has
a bespoke clip (render/clips/yama.ts); Bankai East / West bodies as the user decided; Hellfire has no body look.

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

Done (M5 split): `body.ts` exports the helpers (`tube`, `ellipsoid`, `limb`, `box`, `T`, `hex`, `rig`, `rigid`, `katana`,
`inkLine`), the shared shihakusho `kimono(sp, r, head?)`, `plainBody(spec overrides)` for placeholders, `CharBody`
(`spec`, `parts(sp, rig)`, `drawFace(g, expr)`, `weapon(scene, sp, rig)`, `variant(form) → BodyVariant | null`) and
`buildBody(scene, key, charBody, mat, weaponMat)`. `bodies/index.ts`: `BODIES` and `bodyFor(character, form) → {key,
body}`; `FighterView` keeps one built body per key and swaps on `fighter.form` changes. `clips/index.ts`: `CLIPS` of
`{ clipFor(clip, move) → ClipName | null, idle? }`; `anim.ts` `clipNameFor(who, move)` falls back to `moveClipName`.
Rukia / Ichigo / Senjumaru are `plainBody` placeholders (1.5 / 1.8 / 1.7 m, violet / orange / gold) until B3.

## B4: VFX and the ink HUD

Hazard looks (wave, fireball, Ennetsu pillars, line, crack, Tsukishiro ring, rifts, Shonetsu); auras (base, awakened,
pillar, oni, zero, KESSA) as CPU `ParticleSystem` brush sprites; sword / ribbon trails; Hoho afterimages; Kikon /
Soul Break brush-calligraphy cards (kanji from stroke paths or a bundled brush font); negative / manga-page frames as a
post flag; paper grain and vignette; the HUD redrawn in ink (brush bars, kanji labels, cup pips, arm pips, Senjumaru's
meter from `senjuMeter`).

## B5: cinematics and audio

Shot scripts per `CINES` entry summing to its `len`; camera rails; letterbox; white / black caption cards; body and
weapon swaps on a frame; the awakening sequences; then WebAudio: per-event sfx, callouts, music (docs/AUDIO.md).

Done (B5a cinematics): `render/cine-scripts.ts` holds a shot script per `CINES` entry, translated from the DEFCINEs
(test/cinema.test.ts: shots sum to each len, every beat inside it); `render/cinema.ts` plays it from `w.cine` (name, cf)
each rendered frame: camera rails relative to the actors (SHOT-ON / SHOT-PAIR, lerped dollies, Ichigo's orbit and C
cameras), lens + dutch roll, shake; actor poses (a move sampled at a script sf, a library pose, a reaction) and form /
weapon swaps lent to `BattleView.update` for one call; aura presets; script-posed hazard looks (fire walls, ice rings and
pillars, the sky split, Ichigo's clones, Senjumaru's threads / carpet / bolts) and ink sparks; black / white / tinted
cards (the stage hidden), black silhouettes and back-rims (the toon threshold past 1 + a wide rim); the impact frames and
base grades as a post pass after the paper (negative, two-tone, manga page with the spot colours kept, Yamamoto's spot
grey, Senjumaru's desaturation); in `drawCineOverlay` (hud.ts) the letterbox, the caption cards on the script's frames and
side, focus lines, the ink splash, white flashes, Kenpachi's Kusajishi forest and the intro's VS. Kenpachi's cup entries
(RYOTE's ring, NOMIHOSE's rings + a negative frame and a manga page) play in battle. Sound is B5b's (`src/audio/cues.ts`).
Simplified: no rain on K.O., no Cero orb / chain lines / skull / candles (their beats use auras and sparks), Rukia's
Bankai body is her zero body tinted white, the intro has no cane / katana prop. Debug: `duelCine.play(name, attacker,
victim, { aForm, vForm, at })`, `duelCine.at(frame)`.
## Polish (after the M5 merge)

Fable 5.1's review of the merged M5 look (2026-10-05), condensed, with what was done:

- **Camera** (`camera.ts`, `scene.ts`). Root cause: the 60 % ceiling on 2.0 m Kenpachi put the eye ~3.5 m from the
  midpoint at AT y 1.0, so a swung blade sat 1–1.5 m from the lens and his head left the top. Done: frame fractions
  0.30 floor / 0.48 ceiling; AT y = 0.55 × the taller fighter's height (Kenpachi 1.10, Rukia alone 0.8); eye height
  1.85 + 0.1 · sep kept; a hard 3.2 m (horizontal) minimum from either fighter on the pair and behind cameras (was
  0.5 + hurtR); behind camera 0.55 × (3.0 m back); `cam.minZ` 0.35; FOV 50. Head tops land at 24–40 % of the frame
  (the HUD band is ~22 % at 720p).
- **Blade smear** (`scene.ts`): alpha-blended (a StandardMaterial on vertex colours, alpha 0.55 newest → 0.15
  oldest), out of the outline G-buffer; from 45 % up the blade, each slice ≤ 1.3 m from the tip; restarted when the
  tip jumps > 1.5 m in a frame, hidden on a frame where a slice point is within 1 m of the eye. The ink arc ribbon
  (`vfx/trail.ts`) restarts on the same 1.5 m jump (a Hoho dragged it into a screen-wide triangle).
- **Auras** (`vfx/aura.ts`): none in the base form, except while gathering (hold / aura phases: the kit's aura or
  `gather`); bursts, awakened forms, Kikon, Breaker, EVOLUTION keep theirs. No ×1.3 size, stretch 1.6; alpha 0.75 /
  0.6; only Kikon / oni / Breaker / Nomihose dry to ink, the rest fade out in their own colour; life −0.1 s; rates:
  awakened 40–70 /s (reiatsu 40, nozarashi 60, hellfire / garb / KESSA 70, zero 60, TSUJI 45), pillars (Nomihose, oni,
  Kikon) 110, Breaker 100, bursts 55; radius 0.4–0.45; Rukia's cold / frost shards 0.12–0.22, white → ice blue,
  alpha 0.6, 20 /s.
- **HUD** (`hud.ts`, `vfx/brush.ts`, `input/onehand.ts`): name 11s, labels 8s, combo 14s, callouts 12s, HOHO! 13s (timer
  and big words unchanged); Reishi bar 0.034 h, guard 0.35 of it; a 0.45 ink swash behind each side's label column;
  the portrait floor 13 CSS px (s = ceil(13 d / 7)); the brush type's under-stroke offset px / 10.
- **Senjumaru's gold arms** (`bodies/senju.ts`): finger bones 0.045 hs, joints 0.10 H, humerus 0.18 × 0.12 H,
  forearms 0.10 × 0.07 H, echo arms 0.15 / 0.10 H; the echo spread 18 / 34°; at rest a fan of thin lines out of the
  upper back (upper pair +18°, lower pair −34°, 0.55 m), elbows bowed so the forearm bends down 30°, fingers curled
  40 % toward the palm, palms turned toward her; gold `#E8C96A / #A37E2E`, light gold `#F4E2A0 / #C0A050`.
- **Afterimages and shadows**: Hoho ghosts start at 0.45 visibility in `#3A3848`; contact shadows alpha 0.30, radius
  0.35 m; Kenpachi's haori shadow `#C3C9DD` (his own lit key `#F6F3ED`, so Yamamoto's haori keeps `#A9B2CF`).
- Left as is: cel pairs / crease band, outlines, sky / floor palette, grain + vignette, hazard VFX, Kikon cards, hit
  slashes, faces, stage.
