# Zaraki Kenpachi — Bankai (TYBW) reference notes

(The images themselves are third-party art, kept out of git in `.refs/kenpachi-bankai/`; this file keeps the sources and the notes. 2026-10-09.)

Collected 2026-10-09 for the SOUL DUEL low-poly model / animation rebuild. Third-party art: never commit (`.refs/` is
git-ignored).

Sources in one line: manga ch. 669 "刃 II / Blade II", ch. 670–671 "The Perfect Crimson (1–2)"; anime overall episode
410 = TYBW episode 44 = *The Calamity* episode 4 "THE PERFECT CRIMSON" (aired 2026-08-15). bleach.fandom.com names its
stills `Ep410…` (anime) and `669…`/`670…` (official digital-colour manga panels). Files came through the MediaWiki API
(`api.php?action=query&prop=imageinfo&iiprop=url`, then the returned URL `…/revision/latest?cb=…&path-prefix=en&format=original`;
without `path-prefix=en` the CDN returns a 520-byte 404 placeholder).

Anime stills are graded violet/magenta by the scene lighting (Wahrwelt night + reiatsu glow), so sampled anime colours
skew purple; the manga digital colour is the cleaner albedo reference.

## Kept images

| File | Source URL | What it shows |
|---|---|---|
| `face-front-grin-anime.png` | https://static.wikia.nocookie.net/bleach/images/e/e2/Ep410KenpachiBankaiFace.png/revision/latest?path-prefix=en | Anime, frontal close-up of the Bankai face: both horns (cut off by the top of frame at their bases), forehead stripes, dark eye mask, blank glowing eyes, cheek "tear" stripes, full-teeth grin, ears. |
| `face-front-grin-manga-color.png` | https://static.wikia.nocookie.net/bleach/images/4/4a/669Kenpachi%27s_Bankai_face.png/revision/latest?path-prefix=en | Manga (ch. 669, digital colour), frontal close-up: large horns, all black markings, stitched scar over his LEFT eye, blank white eyes, grin. Best single face reference. |
| `face-roar-3q-anime.png` | https://fwmedia.fandomwire.com/wp-content/uploads/2026/08/15120858/bleach-thousand-year-blood-war-b8323d84.png | Anime, 3/4 view roaring, mouth fully open (upper/lower teeth, tongue), both horns clearly visible from the side-front, blank eye. The roar after the bisection. |
| `profile-horns-right-arm-burst-anime.png` | https://static.wikia.nocookie.net/bleach/images/a/aa/Ep410KenpachiArmTears.png/revision/latest?path-prefix=en | Anime, left-side profile: two short conical horns, scar line, clenched-teeth grin, hair mane; the RIGHT (far) arm raised overhead gripping the wrapped haft and bursting in blood. |
| `body-front-blade-right-hand-anime.png` | https://static.wikia.nocookie.net/bleach/images/6/67/Ep410KenpachiBankai.png/revision/latest?path-prefix=en | Anime, front 3/4 upper body (fandom's "appearance" image): crimson bare torso, black ragged shoulder mantle, white obi knot, black hakama, blade hanging low in his RIGHT hand, left hand open claw-like. Hair mane spiky on top. |
| `pose-crouch-all-fours-anime.png` | https://static.wikia.nocookie.net/bleach/images/7/75/Ep410KenpachiBankaiActivated.png/revision/latest?path-prefix=en | Anime, the Bankai reveal: crouched on all fours on cracked lava-lit ground, right hand gripping haft (blade forward-left), left palm flat on ground, head down under a huge mane + ragged cloak. Clear blade outline with the back spurs. |
| `pose-crouch-all-fours-manga-color.png` | https://static.wikia.nocookie.net/bleach/images/6/69/669Kenpachi%27s_Bankai.png/revision/latest?path-prefix=en | Manga ch. 669 same moment: crouch on all fours, blood dripping from the bowed face, right hand on the haft, left hand splayed on the floor, black rags + mane. Clear manga blade silhouette. |
| `pose-dive-through-flame-anime.jpg` | https://butwhytho.net/wp-content/uploads/2026/08/BLEACH-Thousand-Year-Blood-War-Episode-44-But-Why-Tho.jpg | Anime, lunging/diving down through a burst of energy, face toward camera: horns very clear (cat-ear silhouette), grin, blade trailing low in his right hand, black mantle billowing. Warm light gives a truer red than the violet scenes. |
| `pose-bite-rip-arm-from-behind-manga-color.png` | https://static.wikia.nocookie.net/bleach/images/1/1e/669Kenpachi_rips.png/revision/latest?path-prefix=en | Manga ch. 669: the bite. Kenpachi (small, seen from behind, lower left) has his teeth in Gerard's giant fist; Gerard's whole right arm is torn off at the shoulder. Blade held low in his right hand. Crop: `crops/bite-from-behind-manga-color.png`. |
| `bite-aftermath-gerard-arm-anime.png` | https://static.wikia.nocookie.net/bleach/images/2/2a/Ep410GerardArmRipped.png/revision/latest?path-prefix=en | Anime: the result of the bite (Gerard's right arm ripped away, blood spray). Kenpachi himself is not readable here; kept for the hit-effect / timing reference only. |
| `pose-leap-cut-shield-manga-color.png` | https://static.wikia.nocookie.net/bleach/images/9/9a/669Kenpachi_slashes.png/revision/latest?path-prefix=en | Manga ch. 669: Kenpachi airborne above Gerard (small silhouette, top), blade extended, after the leaping slash that split Gerard's shield and forehead. |
| `pose-leap-cut-silhouette-anime.png` | https://static.wikia.nocookie.net/bleach/images/d/d7/Ep410KenpachiAttacksGerard.png/revision/latest?path-prefix=en | Anime: the leaping cut, Kenpachi in silhouette mid-air, right arm extended forward along the haft, blade at the end of a long horizontal arc. Crop: `crops/blade-leap-anime.png`. |
| `cut-through-shield-anime.png` | https://static.wikia.nocookie.net/bleach/images/c/c0/Ep410KenpachiSlashesGerard.png/revision/latest?path-prefix=en | Anime: the same leaping slash from Gerard's side; Kenpachi small mid-air at upper left, shield cut. |
| `bisection-gerard-manga-color.png` | https://static.wikia.nocookie.net/bleach/images/4/4c/669Kenpachi_bifurcates.png/revision/latest?path-prefix=en | Manga ch. 669 p.16–17: vertical bisection of Gerard. Kenpachi's grinning face (scar, markings) right, the blade a huge white arc through the frame. |
| `bisection-gerard-anime.png` | https://static.wikia.nocookie.net/bleach/images/6/68/Ep410KenpachiBifurcatesGerard.png/revision/latest?path-prefix=en | Anime: Gerard split into two halves; Kenpachi a dark silhouette between them, blade pointing straight down (follow-through of the top-to-bottom cut). |
| `right-arm-burst-manga-color.png` | https://static.wikia.nocookie.net/bleach/images/e/e6/670Kenpachi_loses_his_arm.png/revision/latest?path-prefix=en | Manga ch. 670 p.12: right arm raised overhead on the haft, upper arm bursting in a spray of blood; small horn, scar, grin visible in profile. |
| `one-armed-grabs-foot-anime.png` | https://static.wikia.nocookie.net/bleach/images/d/d8/Ep410KenpachiTopplesGerard.png/revision/latest?path-prefix=en | Anime, after losing the arm: standing in a wide stance, LEFT hand bare-palmed against Gerard's giant foot to topple him; no blade in hand; barefoot; ragged hakama hem. Crop: `crops/one-armed-barefoot-anime.png`. |
| `compare-shikai-nozarashi-anime.png` | https://static.wikia.nocookie.net/bleach/images/2/2b/Ep386KenpachiShikaiNozarashi.png/revision/latest?path-prefix=en | Comparison only: the SHIKAI Nozarashi (huge axe-cleaver, brass cap, tassel). Not the Bankai. |

Crops (`crops/`, made from the files above with ImageMagick): `blade-bankai-anime-spurs.png`, `blade-bankai-manga-color.png`,
`blade-haft-wrap-anime.png`, `blade-leap-anime.png`, `horns-profile-anime.png`, `horns-markings-manga-color.png`,
`one-armed-barefoot-anime.png`, `bite-from-behind-manga-color.png`.

Looked at and dropped: fandom `BBSBeyond Bankai Kenpachi.png` (Brave Souls card art, normal skin and a Shikai-style
cleaver, not the Bankai), `Ep410KenpachiSmacksHitsugaya.png` / `Ep410KenpachiDeclaresStrategy.png` (pre-Bankai),
`Ep410NozarashiProfile.png` (Yachiru), the chapter covers, and the review sites' other stills (other characters).

## Model-buildable description

Handedness: "his right" = the character's own right. Verified from the front shots (blade on the viewer's left) and the
left-profile shots (scar on the near cheek; the bursting arm is the far arm).

### (a) Head / face

- **Skin**: the whole visible body turns red. Manga digital colour: muted brick crimson, lit ≈ `#B0645A`, shade
  ≈ `#9C4E45`. Anime: saturated crimson-magenta, lit ≈ `#87144A` under violet light, ≈ `#C0452A` under the warm flare
  (`pose-dive…`); shadow ≈ `#3A0D17`. Suggested albedo for our toon shader: **base `#A82A3A`, shadow `#5C1022`**.
- **Horns: two**, symmetric, rooted on the upper forehead at the hairline, one above each eye (roughly above the
  pupil to the outer brow), pointing up and slightly outward, tips curving a little back in.
  - Manga: big and organic. They read as continuations of the bulging brow ridges, thick at the base (≈ 0.12–0.15 ×
    head width), rising ≈ 0.35–0.45 × head height above the brow, same skin colour as the face, no separate horn
    material.
  - Anime: smaller, cleaner cones (cat-ear silhouette in `pose-dive…`, `face-roar…`), height ≈ 0.2–0.25 × head
    height, base ≈ 0.08–0.1 × head width, skin-coloured, slightly darker at the tip.
  - Low-poly: two 4–6-sided cones, slightly curved (2 segments), same material as the skin.
- **Markings** (manga: solid black `#000`; anime: dark crimson-black ≈ `#3A0A14`, drawn as heavy shadow-like
  stripes):
  - Forehead: one vertical slit/diamond on the centre line between the brows, flanked by the two bulging brow ridges.
    On each side a large black comma/teardrop sweeps from the horn base down over the brow to the outer top of the eye.
  - Eyes: a black mask around each eye, densest at the inner and outer corners.
  - "Tear streaks": from under each eye 1–2 black streaks run down over the cheekbone toward the jaw. The manga's are
    short (stop mid-cheek). The anime adds 2–3 parallel diagonal stripes per cheek running toward the jaw and ears,
    plus stripes on the neck and chin, a more tiger-stripe look.
  - Anime only: thin stripes fanning up the forehead toward the horns.
- **Eyes**: blank, no iris or pupil. Manga: pure white `#FFFFFF` with a narrow almond slit. Anime: glowing pale
  lavender-white ≈ `#E8DDF0`, narrow and slanted. In the roar shot (`face-roar…`) the eye is a white almond.
- **Mouth**: a very wide grin showing the full upper and lower rows of square white teeth (`#F4F0EA`), lips pulled
  back to the cheeks. Roar: jaw dropped ≈ 40°, canines slightly pointed, dark mouth interior `#130912`, pink tongue.
- **Scar**: his usual long thin scar on his LEFT side, from the forehead (crossing the left horn base in the manga)
  straight down through the left eye to the jaw. Manga draws it stitched. Anime: a thin dark line.
- **Ears**: normal, slightly pointed in the manga close-up.
- **Hair**: black (`#141018`; it renders violet `#5D2A78` in the anime lighting), very long (mid-back), a wild mane.
  The top/front stands up in stiff spikes (anime front shot: a crown of spikes), and the back flows out in big
  jagged locks that merge visually with the black rags. No bells, no eyepatch (he is not wearing it here).

### (b) Body and costume

- Bare torso: the shihakushō top is torn away from the front. Very lean, ripped muscle, exaggerated in the anime
  (deep abdominal and serratus grooves read almost like ribs: `body-front…`).
- **Black rags over the shoulders**: a sleeveless, ragged black mantle/cape hangs from the shoulders and back down to
  about the hips or thighs. Its edges are torn into jagged points, it is open at the front, and it frames the torso.
  The arms are fully bare from the shoulder. Colour `#16121A` (anime violet-lit `#231218`–`#7C408B` on the rim).
  No white captain's haori is visible in any Bankai shot.
- **Obi**: white sash/bandage wrap at the waist (`#E8E4DC`), tied in a knot at the front centre with short hanging
  ends (anime `body-front…`). Manga: hidden under the rags in the crouch.
- **Hakama**: black (`#18141C`), wide, with a ragged/torn hem (`one-armed-barefoot…`).
- **Feet**: bare in the anime after the arm loss (`one-armed-barefoot…`). No sandals were visible in any Bankai shot.
  Not seen clearly in the manga.
- Blood: in the manga crouch, blood drips from the face; there are cuts on the body from the earlier fight.

### (c) The Bankai Nozarashi (the broken blade)

- Wiki and episode summary: "an altered version of its Shikai state, with a shorter, more jagged blade resembling a
  rough cleaver"; the anime summary calls it "a jagged, broken version of Nozarashi". Gerard mocks "the broken blade".
- **Manga** (`crops/blade-bankai-manga-color.png`, `pose-crouch…manga`): a single-edged wide cleaver, solid black-grey
  flat (`#1A1A1A`–`#747371`) with a pale bevel on the cutting edge. Outline: the edge is a long convex curve; the back
  is roughly straight, with a stepped notch where the blade meets the haft. The far end is cut off square/slanted, as
  if snapped, with no point. Proportions: blade length ≈ 2–2.5 × the forearm, width ≈ 0.4 × its own length.
  The brass cap and tassel of the Shikai are gone.
- **Anime** (`crops/blade-bankai-anime-spurs.png`, `crops/blade-leap-anime.png`): the same cleaver, steel grey-violet
  (`#6A3D5A` in violet light, so a neutral steel ≈ `#8A8A92`, edge highlight `#D8DCE0`). The back near the haft has a
  **hooked spur**: two scalloped bites cut out of the back, leaving a forward-curling hook like a bat-wing, and the
  back edge is jagged. In the leap shot the far section shows more jagged teeth along the back.
- **Haft**: long (≈ 1–1.5 × forearm beyond the hand), straight, no guard. The blade sits straight on the end of the
  haft. Wrap: manga beige/off-white cloth in a diagonal spiral (`#D6CDB0`–`#D6D5D3`). Anime: white wrap with dark
  criss-cross binding lines (`blade-haft-wrap-anime.png`). He grips it near the blade end, one-handed.
- Not seen: the blade's exact thickness and a clean side-on view of its whole outline (every view is foreshortened or
  partly cropped), and whether the break is a straight snap or a ragged tear. The manga reads straight/slanted, the
  anime more jagged.

### (d) Poses (what each reference supports)

- **Crouched stance / reveal**: on all fours, head lowered below the shoulders. The right hand grips the haft with the
  blade lying forward-out to his right, the left palm is flat with the fingers splayed, and the knees are bent. The
  mantle and mane spread over the back like a hump. (`pose-crouch…` ×2.) The standing guard after it
  (`body-front…`): hunched, shoulders forward, arms hanging, the blade low in the right hand, the left hand clawed.
- **Bite**: Gerard punches down; Kenpachi meets the fist head-on, bites into the knuckle/finger, then turns his head
  to tear the whole arm off (wiki: "biting into the flesh of his finger prior to turning his head and ripping Gerard's
  entire right arm off"). The blade stays low in the right hand. Reference only from behind (manga) plus the anime
  aftermath; no frontal bite frame was found.
- **Punch**: leaps off rubble into the underside of Gerard's chin (an uppercut) and knocks him off Wahrwelt. No image
  found, from wiki text only.
- **Leaping cut**: springs out of the dust and slashes at the face, splitting Gerard's left hand, shield and thorn
  crown. The right arm is extended along the haft in a wide horizontal arc (`pose-leap-cut…` ×2,
  `cut-through-shield-anime.png`).
- **Vertical bisection**: Gerard flies at him; one top-to-bottom cut splits him in two. Anime: Kenpachi mid-air
  between the halves with the blade straight down (`bisection-gerard-anime.png`). Manga: the blade as a giant white arc
  with his grinning face behind it (`bisection-gerard-manga-color.png`).
- **Roar**: after landing he leaps back dozens of metres and roars, head thrown forward, jaw wide
  (`face-roar-3q-anime.png`).
- **Dive / lunge**: `pose-dive-through-flame-anime.jpg`, body forward and down, head up, blade trailing.

### (e) The burst right arm, and how he fights after it

- **Which arm**: the RIGHT, the sword arm. Manga ch. 670 p.12: "his right arm suddenly shatters" (fandom, Power
  Overload: "his right arm tore itself to pieces when he attacked Gerard for a fourth time"). Anime episode summary:
  "Kenpachi's right arm breaks off at the elbow in a shower of blood". The images agree. In both
  `right-arm-burst-manga-color.png` and `profile-horns-right-arm-burst-anime.png` it is the arm raised overhead on the
  haft that bursts, from the upper arm to the elbow. The manga shows the hand still gripping the haft as it bursts.
- **After**: Gerard slams Hoffnung into him and drives him into the ground. In the anime summary, "leaving Kenpachi
  with his right arm completely severed". He then fights bare-handed with the LEFT hand. Anime: "Kenpachi clutching
  his left foot with his remaining hand, having used Gerard's momentum against him by holding it in place"
  (`one-armed-grabs-foot-anime.png`: left palm on the giant foot, no blade visible). Manga ch. 671 p.13–14 (wiki):
  "manages to flip Gerard over and mutilate his feet". I could not see those manga pages.
- **Answer**: there is no evidence that he switches the blade to his left hand. The only one-armed action in either
  version is a bare-handed left-hand grab/trip, and none of the post-burst images shows the blade in his hand. Whether
  he held the blade at all in ch. 671 is unconfirmed.

## Manga vs anime differences (summary)

| Feature | Manga (669–671, digital colour) | Anime (ep. 410 / Calamity 4) |
|---|---|---|
| Skin | muted brick crimson `#B0645A` | saturated crimson-magenta (`#87144A` violet-lit, `#C0452A` warm-lit) |
| Horns | large, thick, brow-ridge-like, ≈ 0.4 head height | small clean cones, ≈ 0.2–0.25 head height |
| Markings | few, bold, solid black (forehead slit + commas, eye mask, short tear streaks) | many dark crimson stripes, tiger-like on cheeks, neck and forehead |
| Eyes | pure white slits | glowing pale lavender-white |
| Blade | black flat cleaver, square snapped end, stepped notch at the haft | steel grey, hooked double-scallop spur on the back near the haft, jagged back |
| Haft wrap | beige spiral cloth | white with dark criss-cross binding |
| Arm loss | right arm shatters (upper arm) | right arm breaks off at the elbow |

## Could not see or find

- A clean full-body front or side view standing (every full shot is crouched, foreshortened or silhouetted).
- The punch to the chin, and a frontal frame of the bite.
- Manga ch. 670–671 interior pages beyond the arm-burst panel, so the manga's one-armed action is unconfirmed.
- The back of the costume (whether the mantle is one piece or shredded shihakushō sleeves) and the feet in the manga.
- The blade's thickness and a side-on outline of the whole blade.
