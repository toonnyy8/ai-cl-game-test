# Lille Barro (リジェ・バロ, 利傑巴羅): modelling reference sheet

The request (the user, 2026-10-06): 「請順便整理利傑巴羅各型態的參考圖作為建模依據」 (collect reference images of each of his forms
as the basis for modelling), asked again after the network policy changed: 「請再次嘗試整理利傑巴羅各型態的參考圖作為建模依據」.

Companion files: the canon fact file `lille_barro.md` (same folder; §1 appearance, §3 Jilliel, §4 the owl form) and the
design doc `docs/duel/DUEL_LILLE.md` (base form, awakening = Jilliel, second awakening = the owl form). This sheet speaks
in the terms the art code uses: `defbody` (`:scale`, `:width`, `:girth`, `:props`, `:palette`, shapes per rig joint),
`defweapon`, art-only chains (Senjumaru's echo arms, engine gap N12), the v4 notan palette and the three spot hues
(`docs/style/STYLE_STORM_DESIGN.md` §A.1–A.2, §2.5).

## 0. How this was made, and how far to trust it

- **Second pass (2026-10-06), with images.** 49 images were downloaded and **looked at one by one** into the git-ignored
  `.refs/Lille-Barro/` (§8): 47 stills (anime screenshots, the wiki's colour-edition manga panels, the official anime
  character visual and head turnaround, one Brave Souls key art) and two 2×2 frame sheets cut from the wiki's GIFs. Hex
  values marked *sampled* were measured with Pillow/numpy on those files (5×5 means or percentile picks inside a hue mask).
- **Hosts.** Worked: the Bleach Wiki through its MediaWiki API (`bleach.fandom.com/api.php`, browser User-Agent;
  `prop=images` per page, then `prop=imageinfo` for the file URLs), the files on `static.wikia.nocookie.net` (fetched as the
  original PNGs with `&format=original`; without it the CDN serves lossy WebP), the official anime site `bleach-anime.com`
  (character page, Lille = entry 84), the Brave Souls wiki API. The wiki article pages themselves (`/wiki/...`) answer 403 to
  a plain client, so every page link below was resolved through the API, not opened as HTML. The first pass's
  third-party explainer pages (Sportskeeda, animecorner, Game Rant, daddyjim, …) were **not needed and not opened**; they
  are dropped from §7.
- **What the pictures are.** The wiki's manga panels are the **digital colour edition** (Shueisha's coloured release),
  not the black-and-white tankōbon; no B&W scan was collected. The colours in them are the colourist's, not Kubo's.
  The anime stills of TYBW 35 are lit purple (the Shikai games) or gold (the Bankai), and TYBW 37 purple, so colours are
  sampled from the official visual and TYBW 24 where possible.
- **Episode numbers.** TYBW episode N = the wiki's overall episode 366 + N (TYBW 24 = ep 390, 35 = 401, 37 = 403, 40 = 406).

**Marks** (as DUEL_SENJUMARU.md / DUEL_LILLE.md): **[V]** manga, **[A]** anime-only, **[G]** our game interpretation or a
proposal, **[I]** an inference. New in this pass: **[seen: `file`]** = confirmed by eye on that file in `.refs/Lille-Barro/`
(folder implied by the prefix: `base_*` in `base/`, `diagramm_*` in `diagramm/`, and so on). Claims left from the first pass
without a [seen] mark are still text-only.

**Numbers.** Canon gives no measurements beyond his height. Ratios marked *measured* were read off the stills (pixels,
corrected by eye for perspective); everything else in metres is **[G]**.

**Corrections this pass forced (summary).** He fights **without the cloak** (it is a debut-only hooded robe); his **trousers
are white** with a green front panel, not dark green; the **right arm is sleeved** in white, only the left is bare; the
"pauldron" is a **long fur stole** with buttons; his **eyes are green**, not black; **Diagramm is a cross-shaped weapon**
(thin barrel, fur sleeve, a tall black upright plank), about **2.4 m** long, with no visible telescopic scope; Jilliel's
body is a **slender holed column ending in two prongs**, not a teardrop, and its **wings are green** in the anime (gold only
in the owl form); the owl form's **body is white, not gold**, stands on **four stilt legs**, and has **long thin arms**; the
trumpet has **no valves**.

## 1. Body and rig baseline (all forms)

| Item | Value | Mark |
|---|---|---|
| Height | **182 cm**: confirmed by the official anime site's profile (身長 182cm, birthday 4月11日, 聖文字 "X", CV 日野聡) | [A] official |
| Height conflict | the "five feet nine" summary is wrong; ignore | resolved |
| Build | **muscular**, long-limbed; in the official visual about **8.5 heads** tall without the hat (a slim anime head), shoulders ≈ 0.26 H | [seen: `base_fullbody_front_official-anime.png`] measured |
| Rig scale | Ichigo is `:scale 1.0` at 181 cm, so Lille **`:scale 1.0`, `:width 1.04`** | [G] |
| Head | the anime-head rule: `(:head 1.2 1.2 1.2)` in `:girth`, as Ichigo | [G] |
| Hurt cylinder | **r 0.38 / h 1.80** (Ichigo's), in every form; hats, wings, halos, necks add **no** hurt volume (fairness floor, as Senjumaru's crescent) | [G] |
| Rig limits | 21 fixed joints; `:props` stretches `:shoulders`, `:arms`, `:legs` and `:spine`. Anything else (wings, a serpentine neck, stilts) is an **art-only chain** from an anchor joint, as Senjumaru's echo arms | engine fact |

Silhouette across the roster (DUEL_SENJUMARU §2): Yamamoto = hunched white haori + FIRE; Kenpachi = 2 m, white
sleeveless haori + yellow; Rukia = small, all black; Ichigo = tall black, orange head, two blades; Senjumaru = small white
figure, gold halo, gold fan of arms. **Lille's base form reads as "a dark-skinned man all in white, a green fur cap with a
white stripe, one green fur stole on the right, and a black rifle that makes a cross"** [seen]. Collisions to watch:
Kenpachi is also white with a bare arm (separate them by the green hat and stole and the rifle's cross); Senjumaru owns a
gold halo and a gold fan (Jilliel's halo and wings are **green** in the anime, which helps; the owl form's gold wings are
holed blades, its halo a small spiked ring, not a crescent).

**The X / + motif rhymes through every form** [seen]: the eye mark, the scope reticle (`diagramm_dial-muzzle-reticle_frames_anime_ep35.png`),
the muzzle brake, the rifle's side silhouette (barrel × upright plank), the glove's winged X, the trumpet bell's ring with
four struts (`trompete_bell-end-on_manga-colour_ch653.png`). Keep one shared "ring + four ticks" glyph for all of them.

## 2. Base form (万物貫通 THE X-AXIS, Diagramm, the left eye shut)

### 2.1 Silhouette: three readable elements
1. **The rifle cross**: a long, thin, dead-straight black barrel through a green fur sleeve, crossed at the rear by a tall
   black plank; a **+ muzzle brake** at the tip.
2. **The green fur cap with the white stripe**: a tall fur cap whose white crown shows as a vertical stripe from the front.
3. **The asymmetric top**: a long green fur stole over the **right** shoulder and chest, the right arm in a white sleeve,
   the **left arm bare** and muscular; everything else white.

The fourth, close-range element: **the left eye shut under the reticle mark** (a ring of four arcs with four short ticks
pointing in, an X with the centre left open for the eye).

### 2.2 Parts list, front / side / back

| Part | Description | Mark |
|---|---|---|
| Skin | **dark brown** | [seen: `base_fullbody_front_official-anime.png`] |
| Hair | **pale cream**, cut to an **undercut / crew cut**; only the temples, sideburns and nape show under the cap | [seen: `base_head_3view_official-anime.png`] (colour sampled #CBC1A6, not pure white) |
| Eyes | **green** irises (anime: dark green; colour manga: bright green); the left eye kept shut. The wiki's "black eyes" is wrong for both colour sources | [seen: `base_head_3view_official-anime.png`, `base_face_eye-open_manga-colour_ch646.png`] |
| Eye mark | over the **left** eye: a **ring broken into four arcs, with four short ticks pointing inward** (an X whose centre is left open); about 1.5× the eye's width, centred on the shut eye; black | [seen: `base_face_eye-mark_manga-colour_ch599.png`, `base_head_3view_official-anime.png`] |
| Eye-open variant | anime: the opened left eye and the whole mark **glow green** and the mark's X flares into four long light strokes; manga: an ordinary open green eye inside the mark | [seen: `base_face_eye-open_anime_ep35.png`, `base_face_eye-open_manga-colour_ch646.png`] |
| Cap | **resolved.** A tall dark-green **fur cap**: a thick fur rim forms **two ridges running front to back**, left and right of a long **white crown** (the white shows as a vertical stripe from the brow up over the top when seen from the front, and as a long white oval from above). The two ridges are the bicorne's "points", so the points sit **left and right** (worn crosswise). From the side it reads as a round fur dome, a bit longer than wide. A small **metal emblem disc** (a wheel/cross) on each side. It sits low on the brow and covers the head to above the ears | [seen: `base_head_3view_official-anime.png`, `base_face_eye-shut_hat-front_anime_ep24.png`, `base_hat-top_back_anime_ep35.png`] |
| Cloak | **resolved: debut only.** A hooded, floor-length white cloak over everything (cap included), three buttons down the right chest, a big **red Schutzstaffel mark** (an asterisk-like X with a bar) on the front. He throws it off at once (ch. 600 / TYBW 24) and **never fights in it** | [seen: `base_hooded-cloak_anime_ep24.png`, `base_face_eye-mark_manga-colour_ch599.png`] |
| Shirt | **resolved: white** (the same white as the trousers), V-neck, **sleeveless on the left only**; the **right arm wears a long white sleeve** to the glove cuff. A wide **waist band** (≈ 0.09 H tall) closes the shirt, with three buttons on his right | [seen: `base_fullbody_front_official-anime.png`, `diagramm_three-quarter_fur-sleeve_anime_ep24.png`] |
| Fur stole (was "pauldron") | a long **dark-green fur stole** from the right side of the neck (it also rings the back of the collar) over the **right** shoulder and down the right chest to the waist band, fastened by **three grey buttons** along its inner edge | [seen: `base_fullbody_front_official-anime.png`, `diagramm_fur-sleeve-ports_anime_ep35.png`] |
| Gloves | white, with **flared cuffs**; the **winged X** (two crossed rods, a feathered wing on each side, a disc at the centre) is embroidered on the cuff, drawn in dark line | [seen: `base_glove_winged-x_design.png`, `diagramm_aim-window_anime_ep34.png`] |
| Trousers | **corrected: white**, straight, slightly flared at the hem. A **dark-green front panel** hangs from the waist band to the crotch (≈ 0.2 H long, ≈ 0.09 H wide) with **three grey buttons on each edge** and a **notched point** at the bottom; buttoned green strips also show on the back/outer thigh. This fits the wiki text if the white is the "leggings" and the green is the trousers showing through the openings | [seen: `base_fullbody_front_official-anime.png`, `base_hat-top_back_anime_ep35.png`] |
| Leggings cut-outs at the calves | **not visible in any still collected**; the official front shows plain white legs | open, low priority |
| Shoes | **white**, low, slightly pointed | [seen: `base_fullbody_front_official-anime.png`] |
| Weapon at rest | in the fights he **carries Diagramm in his hands** (upright, or levelled); the "slung under the cloak" carry exists only at the debut | [seen: `diagramm_vertical_carry_manga-colour_ch600.png`, `diagramm_full-length-vertical_anime_ep24.png`] |

Front: dark face, cream sideburns, the cap's white stripe, the shut left eye in its ring, the green stole down the right
side, the white sleeve on the right arm and the bare left arm, the white waist band, the green buttoned front panel, white
legs and shoes. Side: the cap as a dome with its emblem disc; the stole's fur mass on the right shoulder. Back: the cap's
long white crown inside the fur rim; the white shirt back; buttoned green strips on the legs (`base_hat-top_back_anime_ep35.png`).
No true back view of the whole body was found.

### 2.3 Proportions (ratios to his 182 cm height H; *measured* on `base_fullbody_front_official-anime.png`)

| Measure | Ratio | Metres | Note |
|---|---|---|---|
| Crown (under the cap) | 1.00 H | 1.82 | `:scale 1.0` |
| Cap top | ≈ 1.05 H | ≈ 1.92 | measured; the cap sits low (brim at the brow), ≈ 0.20 m from brow to top, ≈ 0.24 m wide, ≈ 0.30 m long |
| Brow / cap brim | ≈ 0.96 H | ≈ 1.75 | measured |
| Shoulder width | ≈ 0.26 H | ≈ 0.48 | the stole adds ≈ 0.06 on the right |
| Waist band | ≈ 0.67–0.76 H | 1.22–1.38 | measured; a wide white band |
| Green panel bottom (crotch) | ≈ 0.46 H | ≈ 0.84 | measured |
| Head (anime ×1.2) | ≈ 0.12 H in the visual | ≈ 0.22 | keep the game's ×1.2 rule |
| Cloak hem | — | — | no cloak in play (see 2.2) |

### 2.4 Colours (*sampled* on the official visual, flat cel colours; the style values follow STYLE_STORM §A.1)

| Palette key | Sampled (anime) | Game value [G] | What |
|---|---|---|---|
| `:skin` | lit **#885F4A** (H20 S0.46 V0.53), shade #5B392F | **#7A6155** / shade #54433B (S 0.30) | §A.1 caps skin at S ≤ 0.3; the first pass's #6E4A3A (S 0.47) broke the cap |
| `:hair` | **#CBC1A6** (pale cream, H44 S0.18) | #D8D2C0 | cream, not white; mostly hidden by the cap |
| `:white` | **#ECF1F3** (cool white, H197 S0.03) | #ECECE8 (the roster white) | shirt, sleeve, waist band, gloves, trousers, shoes, the cap's crown: **one white for all** (the first pass's separate `:shirt` #D8D6CC is dropped) |
| `:green` | fur **#434D3B** (H93 S0.23 V0.30), lighter fur #505E47, darkest #2A3124 | #434D3B lit / #2A3124 shade | cap, stole, front panel, rifle sleeve: muted, **not a spot hue**; the first pass's #2F3B2E was one value too dark |
| `:button` | **#AAB3B7** | #BCC1CC (V3 steel) | buttons, the cap's emblem discs |
| `:black` | — | #16161E | Diagramm, the eye mark; keyline #4A5062 on black parts |
| `:emblem` | grey metal on the cap; the glove's winged X is dark line on white | V3 steel / ink | resolved: no gold anywhere on the base form |
| eye | dark green iris | ink dot | at play distance the open right eye is an ink dot |
| eye-open accent | anime glow **green** (H ≈ 135–150, e.g. #3FC563 → #78F5BF) | white + cold steel, or the green of §4.4 (user decision) | the anime makes green his power colour (eye, re-formed rifle, Jilliel); see §9 |

The anime line colour on skin is a dark brown (#2A1D19), not black; the style's ink keyline replaces it.

### 2.5 Signature poses

| Pose | Description | Mark |
|---|---|---|
| Idle | upright and still; rifle held **upright beside him, barrel up** (the debut stance) or levelled across the body | [seen: `diagramm_vertical_carry_manga-colour_ch600.png`, `diagramm_full-length-vertical_anime_ep24.png`] |
| Aim | the fur sleeve on the **right** side of the face, **cheek on the sleeve**, the **left (bare) hand under the sleeve's front**, the right arm round its rear; the black plank stands up behind the sleeve. Kneeling aim in the manga (one knee up) | [seen: `diagramm_aim-window_anime_ep34.png`, `diagramm_side_aim-pose_manga-colour_ch644.png`, `diagramm_muzzle-cross_end-on_bravesouls-art.png`] |
| Aim, adjusting | fingers turning a small **dial knob on the black plank**; then the POV **reticle** (ring + four ticks) | [seen: `diagramm_dial-muzzle-reticle_frames_anime_ep35.png`] (low-res frames) |
| Fire | a single snap along the line; the anime draws the X-Axis as a **green** beam in TYBW 35 | [A] (green beam: triage view of the wiki's DarumaSanGaKoronda still, not saved) |
| Dodge | the **Kageoni leap**: a high side-on jump, legs trailing, rifle held | [seen: `base_fullbody_leap-side_manga-colour_ch645.png`] |
| Hit (eye open) | the left eye snaps open, the mark flares green (anime), the blade passes through him | [seen: `base_face_eye-open_anime_ep35.png`] |
| Hit (normal) | a stiff, upright flinch; he never brawls | [I] |

### 2.6 Simplify for the ink style / never lose

- **Simplify:** the fur becomes **one bevelled mass with 3–5 jagged ink strokes** on its edge (cap rim, stole, rifle
  sleeve, the same treatment); the cap's crown is a white plate between two fur ridges; the emblems become small steel
  discs; buttons become steel dots (3 on the stole, 3 on the band, 3 + 3 on the panel); the glove's winged X vanishes at
  play distance.
- **Never lose:** the rifle's **length, straightness and cross**; the **green cap with the white stripe**; the stole on the
  **right** and the **bare left arm**; the **green front panel** on white legs; the **shut left eye in its ring**, and an
  unmistakable eye-open frame (it is a game state); dark skin against white cloth.

### 2.7 Still to check by eye
A full back view of the body; the calf cut-outs; which glove carries the embroidery (both cuffs in the stills seen).

## 3. Diagramm (ディアグラム), the spirit weapon

### 3.1 Parts

| Part | Description | Mark |
|---|---|---|
| Overall | **not a conventional sniper rifle.** In side view it is a **cross**: a long thin horizontal barrel, a green fur sleeve over its rear part, and a **tall flat black upright plank** set crosswise at the rear | [seen: `diagramm_side_aim-pose_manga-colour_ch644.png`, `diagramm_three-quarter_fur-sleeve_anime_ep24.png`] |
| Barrel | **thin and dead straight**, black (≈ 0.05 m thick), runs out of the front of the fur sleeve | [seen] |
| Muzzle brake | a **+ of four rectangular fins**, each arm ≈ 3–4× the barrel's thickness; end-on it is a heavy black cross with the bore at the centre | [seen: `diagramm_muzzle-cross_end-on_bravesouls-art.png`, `diagramm_dial-muzzle-reticle_frames_anime_ep35.png`] |
| Fur sleeve | **confirmed**: a big cylinder (≈ 0.6 m long, ⌀ ≈ 0.2 m) wrapped in the same green fur as the cap, with **round ports** on its side (seen when cut) | [seen: `diagramm_fur-sleeve-ports_anime_ep35.png`, `diagramm_aim-window_anime_ep34.png`] |
| Upright plank (the "wing-shaped supports") | a flat black plank ≈ 1.0–1.3 m tall and ≈ 0.1 m wide crossing the sleeve's rear; it reaches above his head and below his waist; in the manga a lower part splits into two plates. The "wing-shaped supports" of the first pass are these plates (no feathers) | [seen: `diagramm_vertical_carry_manga-colour_ch600.png`, `diagramm_muzzle-cross_end-on_bravesouls-art.png`] |
| Scope | **no telescopic scope is drawn on the weapon in any still**; the anime shows the "scope" only as a POV reticle (ring + four ticks, the eye-mark glyph) | [seen: `diagramm_dial-muzzle-reticle_frames_anime_ep35.png`] |
| Dial | a **small round knob on the black plank**, turned between finger and thumb | [seen: same file] (low-res) |
| Stock | none in the usual sense: the plank braces against his shoulder/body | [seen] |
| Severed state | ch. 646: the barrel cut short, the plank with holes; anime: the rifle re-forms from **green Reishi** | [seen: `diagramm_severed_manga-colour_ch646.png`, `diagramm_reforming-green-reishi_anime_ep35.png`] |

### 3.2 Proportions (*measured* where marked, else [G])

| Measure | Ratio to H | Metres | Note |
|---|---|---|---|
| Overall length | **≈ 1.3 H** | **≈ 2.4** | measured on `diagramm_full-length-vertical_anime_ep24.png` (barrel ≈ 6 head lengths past the sleeve; a low camera, so ±0.3 m) |
| Barrel past the sleeve | ≈ 0.8 H | ≈ 1.5 | measured, same file |
| Barrel thickness | ≈ 0.03 H | ≈ 0.05 | it must read as a line |
| Fur sleeve | ≈ 0.33 H long, ⌀ ≈ 0.11 H | ≈ 0.6 × ⌀ 0.2 | measured on `diagramm_side_aim-pose_manga-colour_ch644.png` |
| Upright plank | ≈ 0.6–0.7 H tall, ≈ 0.05 H wide | ≈ 1.1–1.3 × 0.1 × 0.05 | measured, same files |
| Muzzle brake | ≈ 0.12 H across | ≈ 0.2 × 0.2, ≈ 0.08 long | [G] from the Brave Souls art |
| Severed barrel | ≈ 0.15 H past the sleeve | ≈ 0.27 | [G] |

`defweapon :diagramm (:length 2.4)` on `:weapon-r`, the grip at the sleeve's rear (≈ 0.35 of the length from the plank
end), the left hand under the sleeve's front. The plank is a separate flat box crossing at the rear (its top above the
head when aimed, so keep it thin and dark against the sky). **There is no bayonet in canon** [G]; the J / K "butt and
bayonet" strings can use the **plank as the butt**. The drawn tip must match the hit volume (±0.15 m FK test).

### 3.3 Simplify / never lose
- **Simplify:** the sleeve to a fur cylinder with jagged ink edges and two dark port dots; the plank to one flat black box
  (two plates below the barrel line); the dial to a tiny disc on the plank; the muzzle to a + of four boxes.
- **Never lose:** the length, the **thin straight barrel**, the **cross** of barrel and plank, the **+ muzzle**, the green
  fur sleeve, black metal.

## 4. Vollständig 神の裁き JILLIEL (ch. 646; TYBW 35)

### 4.1 Silhouette: three readable elements
1. **The eight-wing fan**: four long flat wings each side, **each pierced by three oval holes** (24 muzzles), radiating from
   one point behind the head.
2. **The holed white column**: an armless, slender upright column (no visible legs), **perforated by round holes**,
   ending at the bottom in **two pointed prongs**; he floats.
3. **The thin flat halo** floating just above the top of the column.

### 4.2 Parts

| Part | Description | Mark |
|---|---|---|
| Wings | **8, three oval holes each** (in a row along the wing) | [seen: `jilliel_fullbody_front_anime_ep35.png`, `jilliel_fullbody_front_manga-colour_ch646.png`] |
| Wing shape | **resolved: flat leaf/blade shapes** with torn, serrated trailing edges and pointed tips; **no separate feathers**. They radiate from **one root just behind the top of the column**: upper pair ≈ 35–40° above horizontal, second ≈ 10° up, third ≈ 15° down, fourth ≈ 40° down (anime front) | [seen: same files] |
| Wing colour | **resolved for the anime: green.** TYBW 35 wings are a glowing **green** (sampled mid #356E32, light #83C17C, glow #ADFBA1; H ≈ 112–120) with a sparkle texture; the partial wings in TYBW 26 are green too. The colour manga paints them **pale gold-white** (#FCFCDD). Gold in the anime arrives only with the owl form (§5) | [seen: `jilliel_fullbody_front_anime_ep35.png`, `jilliel_partial-wings_base-body_anime_ep26.png`, `jilliel_fullbody_front_manga-colour_ch646.png`] |
| Body | **corrected: a slender upright column**, widest at the top (≈ 0.19 of its height), slightly narrower at the waist, **ending in two pointed prongs** at the bottom (not a teardrop point); cream-white; **round holes** pierce it (about four near the top, six near the bottom) | [seen: `jilliel_fullbody_front_anime_ep35.png`, `jilliel_face-window_robe-holes_anime_ep35.png`] |
| Top of the column | two small **horn-like points** at the top corners; the **face shows through a round window** just below the top; the mouth is covered | [seen: `jilliel_face-window_manga-colour_ch647.png`, `jilliel_face-window_robe-holes_anime_ep35.png`] |
| Hair | **not visible** (hidden by the column's top) | [seen] |
| Face tattoo | too small to read in any still; the anime profile shows a light vertical band across the brow and eye (the cap's white stripe again?) | low; still open |
| Arms | **none** in the closed column | [seen] |
| Altered form (the "giraffe legs") | **resolved**: later in the fight (ch. 648; TYBW 35) the column's lower half **splits into long curved limbs**, about four reaching outward like arms and four to six reaching the ground like legs, with ribbon strips | [seen: `jilliel_altered_legs_manga-colour_ch648.png`, `jilliel_altered_legs-halo_anime_ep35.png`, `jilliel_silhouette_underwater_anime_ep35.png`] |
| Halo | **resolved: a thin flat ring, horizontal, just above the top of the column** (not behind the head); anime **green** like the wings, colour manga pale yellow. In the altered form it is drawn wider and tilted | [seen: `jilliel_fullbody_front_anime_ep35.png`, `jilliel_altered_legs-halo_anime_ep35.png`] |
| Eyes | open (both) | [seen: `jilliel_face-window_robe-holes_anime_ep35.png`] |
| Posture | upright, floating a little off the ground, serene | [seen] |

### 4.3 Proportions (*measured* on `jilliel_fullbody_front_anime_ep35.png`, as ratios to the column's height C; then [G] metres)

| Measure | Measured | Game [G] | Note |
|---|---|---|---|
| Column height C | 1.0 C | ≈ 2.0 m, floating 0.3 m (cosmetic root lift; the hurt cylinder stays grounded) | |
| Column width | ≈ 0.19 C at the top, ≈ 0.13 C at the waist, ≈ 0.19 C at the prongs | 0.38 / 0.26 / 0.38 m | |
| Each wing | **≈ 1.5 C long**, ≈ 0.35 C wide | **scale down to ≈ 1.0 C (2.0 m)** | full size gives a span over 3 C (> 6 m): too wide for the camera |
| Wing holes | ≈ 0.15 × 0.10 C ovals, three per wing, along the outer two-thirds | ≈ 0.2 × 0.13 m | 24 muzzle anchors |
| Halo | outer ⌀ ≈ 0.42–0.47 C, floating ≈ 0.08 C above the column top | ⌀ ≈ 0.9 m, 0.15 m above | thin band ≈ 0.01 C |

Rig mapping [G]: the `:jilliel` body skins no shapes on the arm or leg joints; the column is a tapered `:cyl` from the
pelvis up past the head, with two prong wedges at the bottom; the wings are **eight art-only flat plates** from one anchor
at the top of the column (the echo-arm precedent, N12), each with a small idle flap from a shared fx clock; the halo is a
thin ring on the column's top (not the head bone). The holes are cut-outs or dark ovals with a light core. The altered
form, if wanted, is a second skin: the column's lower half replaced by 8 curved tendril chains.

### 4.4 Colours

| Key | Sampled | Game value [G] | Note |
|---|---|---|---|
| `:robe` | #F9FDE8 lit (gold-lit frames #EBE0B8), colour manga #FCFCDD | #EDE6CC | cream-white, warmer than the base white |
| `:wing` | anime green #356E32 / #83C17C / glow #ADFBA1 (S 0.36–0.55) | **user decision** (§9): muted jade #6E9A80 (S ≤ 0.3), or adopt the anime green as Lille's spot hue | the anime green is the dominant colour of the form, not a detail |
| `:halo` | green (anime) / pale yellow (manga) | follows `:wing` | the first pass's "huge golden halo" in the anime was wrong for TYBW 35 |
| face | skin in the window | `:skin` | only the face shows |
| shots | green beam (anime) | white core + the `:wing` hue, 1–2 px lines | |

### 4.5 Wing shots (the look of the WING VOLLEY)
- [V] high: shots fire **from the holes of the wings**, "instantaneous"; all 24 holes gathered give one city-severing blast.
- [G]: each firing hole flashes (a white disc), a **thin straight line** runs to the target, and a **round hole** opens
  where it lands. The charged 24-hole blast is every hole lighting in sequence, then 24 converging lines.

### 4.6 Signature poses
- **Idle:** floating, upright, the wings slowly breathing open and shut, the halo still. [seen]
- **Fire:** no arms, so the "gesture" is the **wings snapping forward** to aim their holes. [G]
- **Hit:** passes through (the intangible stance); a real hit = the column jolts, wings flare. [G]
- **Bankai beats (cinematic material):** wounds on the column (Act 1), black spots (Act 2), drowning in the dark ocean
  (Act 3), the **golden glowing cut across the throat** (Act 4). [V] high; Acts 1–3 [seen] at triage on the wiki's
  episode stills (not saved).

### 4.7 Simplify / never lose
- **Simplify:** wings to flat plates with 3–4 ink notches on the trailing edge; the column to one smooth mass with the hole
  dots; the face window to a dark disc with two eye glints.
- **Never lose:** **8 wings × 3 holes**, **no arms**, the **holed column with two prongs**, the **face in a window**, the
  **thin flat halo above**, the float.

## 5. The second form, the owl ("true form" of Jilliel; ch. 650–654; TYBW 37)

### 5.1 Silhouette: three readable elements
1. **The S-neck with a tiny owl head**: a long, curving, segmented neck rising from a fur ruff, ending in a **small round
   owl face** with a **small spiked halo** above it.
2. **The four-stilt "centaur" body with long arms**: a narrow human torso on a horizontal lower body carried by **four long
   tapering stilt legs**; **long thin arms** hanging past the hips.
3. **Eight gold holed wings** (the Jilliel wings, now gold); the body itself stays white.

### 5.2 Parts

| Part | Description | Mark |
|---|---|---|
| Body colour | **corrected: white/pale** (TYBW 37's purple light makes it lavender: sampled lit #DCCBDD, shade #9489AE; colour manga pale grey). **Gold = the wings, the halo and the glow only**, plus golden energy where the body is cut | [seen: `owl_fullbody_three-quarter-back_anime_ep37.png`, `owl_fullbody_three-quarter_manga-colour_ch650.png`, `owl_neck-head-halo_anime_ep37.png`] |
| Head | **small** (≈ 0.4 of a human head): a **round pale facial disc**, two **big round eyes** (anime: pink-violet iris, dark pupil; manga: dark dots), a **small hooked beak**; the hair is **swept back and merges into the neck fur** | [seen: `owl_head-close_fur-ruff_anime_ep37.png`, `owl_front_wings-spread_anime_ep37.png`, `owl_head-halo-arm_manga-colour_ch652.png`] |
| Neck | long, an **S / hook curve**, with **segmented plates on the front** (like a snake's belly) and a **fur crest along the back**; it rises from a shaggy **fur ruff** at the shoulders | [seen: `owl_neck-head-halo_anime_ep37.png`, `owl_fullbody_three-quarter-back_anime_ep37.png`] |
| Halo | **a small ring with about six short spikes** (crown-like), horizontal above the head; gold | [seen: `owl_neck-head-halo_anime_ep37.png`, `owl_head-halo-arm_manga-colour_ch652.png`] |
| Torso | narrow, human, upright; no clothes | [seen] |
| Arms | **corrected: long and thin** (not bulky), hanging to below the hips, long fingers; "much larger" in the text means longer. One arm raised high with a pointing finger in ch. 652 | [seen: `owl_front_wings-spread_anime_ep37.png`, `owl_fullbody_front_arms_manga-colour_ch650.png`, `owl_head-halo-arm_manga-colour_ch652.png`] |
| Lower body / legs | **resolved: the "centaur"** is a horizontal lower body (a table-like hip mass) on **four long, thin, tapering stilt legs**, plus ribbon-like tendrils trailing from the hips | [seen: `owl_fullbody_three-quarter-back_anime_ep37.png`, `owl_fullbody_three-quarter_manga-colour_ch650.png`, `owl_front_arms-stilts_anime_ep37.png`] |
| Wings | **eight kept, gold, three holes each**; amber with sparkle (sampled mid #755424, light #C8B267, glow #F9EB95, H ≈ 35–52) | [seen: `owl_front_wings-spread_anime_ep37.png`] |
| Clothes | **none**; no robe remains | [seen] |
| Damage | the reflected Trompete erases a strip of the body and neck, showing **gold energy** inside | [seen: `owl_neck-head-halo_anime_ep37.png`] |

### 5.3 Proportions (*measured* on the TYBW 37 stills as ratios to the torso T, shoulder ruff to hips; then [G])

| Measure | Measured | Canon-size estimate | Game [G] | Rig mapping |
|---|---|---|---|---|
| Torso T | 1.0 T | ≈ 0.55 m (human) | 0.55 m | `:spine` |
| Stilt legs (hip to floor) | **≈ 3.5 T** | ≈ 1.9 m | **≈ 1.3 m** (`:props :legs 1.5`, extra stilts as art) | 2 rig legs + 2 art-only stilts behind |
| Neck (rise above the ruff) | ≈ 2.5–2.7 T | ≈ 1.4 m | ≈ 0.9 m | art-only chain of 6 tapering segments from `:chest`; the rig `:head` draws nothing |
| Owl head | ≈ 0.2 T | ≈ 0.11 m | 0.18 m (enlarged for reading) | at the chain's end |
| Arms | ≈ 1.6 T | ≈ 0.9 m | ≈ 0.9 m | `:props :arms 1.4`, thin `:girth` |
| Halo | ≈ 0.35 T across | ≈ 0.2 m | 0.25 m, 6 spikes | on the neck chain's last segment |
| Wings | as Jilliel | | ≈ 1.6 m each | the same eight plates, re-coloured |
| Overall height to the neck top | **≈ 7 T** | **≈ 3.7–4 m** | ≈ 2.8 m | the first pass's 3.1 m was close; scaled down for the camera |

Hurt cylinder stays **r 0.38 / h 1.80** (fairness floor); the neck, head and stilts above/below it take no hits.

### 5.4 Colours

| Key | Sampled | Game value [G] | Note |
|---|---|---|---|
| `:body` | lit #DCCBDD (purple-lit), shade #9489AE | #ECECE8 / cold shade #BCC1CC | **white, not gold** (corrected) |
| `:fur` | lavender-white in the same light | #D8DCE4 with ink strokes | ruff and neck crest |
| `:face` | pale | #E8E4DC | the owl disc |
| eyes / beak | violet iris, dark pupil / pale beak | #16161E dots, beak a small dark wedge | |
| `:gold` (wings, halo) | amber #755424 / #C8B267 / glow #F9EB95 (S 0.40–0.69, H 35–52) | **user decision** (§9): muted gold #B89A5A (Senjumaru's key; note it measures S 0.51, so it already counts as a spot pixel by §A.2's S > 0.45 budget) | the anime's highlight hue (46–52°) sits on Kenpachi's REIATSU yellow (48–52°) |
| `:glow` | #FFF3A5 core | #FFE8A8 / #FFFFFF | eyes and body light |

### 5.5 Signature poses
- **Idle:** the torso upright on the stilts, arms hanging, the neck in an S with the head cocked forward, wings half open.
  [seen: `owl_front_wings-spread_anime_ep37.png`]
- **Sabaki no Kōmyō (裁きの光明):** the manga draws thin gold light waves with explosions along the city; the anime a wide
  gold beam. [seen: `sabaki-no-komyo_manga-colour_ch650.png`, `sabaki-no-komyo_anime_ep37.png`] [G]: the right arm raised
  high, then a straight downward chop; the wave a thin vertical gold sheet edge-on.
- **Trompete pose:** the **right fist held at the beak**, the head bent to it. [seen: `trompete_fist-at-beak_frames_anime_ep37.png`]
- **Pointing up:** one long arm raised, index finger up, a sun-like light overhead. [seen: `owl_head-halo-arm_manga-colour_ch652.png`]
- **Hit / defeat:** the reflected Trompete erases a strip of his body (gold energy inside), takes the left arm and a set of
  wings and breaks the halo; he scatters into gold, flamingo-like birds with owl heads. [seen: `trompete_reflected_anime_ep37.png`,
  `remnants_flamingo_anime_ep40.png`, `remnants_bird-clones_manga-colour_ch654.png`]

### 5.6 Simplify / never lose
- **Simplify:** the neck to a tapered segment chain with ink plate lines on the front and a fur crest on the back; the owl
  head to a round disc with two dark eyes and a wedge beak; the stilts to thin tapered rods; the wings as Jilliel's plates.
- **Never lose:** the **S-neck**, the **tiny owl face**, the **small spiked halo** (it must contrast with Jilliel's wide flat
  one: a broken halo is his defeat beat), the **four stilts**, the **long hanging arms**, **white body + gold wings**.

## 6. Props and effects of the second form

### 6.1 Trompete (神の喇叭, "Trumpet of God"; ch. 653; TYBW 37)

| Item | Description | Mark |
|---|---|---|
| Gesture | **a closed fist held in front of his beak**; he blows into the fist | [seen: `trompete_fist-at-beak_frames_anime_ep37.png`] (low-res frames) |
| The trumpet | anime: a **long plain horn, no valves**, a straight cone flaring to a wide bell, with a **plume of four or five curved, flame-like feathers** rising from its top near the mouthpiece; hot gold-orange edges (#8C4118) and pale gold cores (#F1CE7D → #FFF3A5). Manga: the bell seen **end-on as a glowing disc inside an outer ring joined by four struts** (the reticle again) | [seen: `trompete_horn-wing_anime_ep37.png`, `trompete_bell-end-on_manga-colour_ch653.png`] |
| Charge | a sun-like gold sphere with rays above him first | [seen: `trompete_gathering-reishi_anime_ep37.png`] |
| The blast | a city-erasing blast along its line | [seen: `trompete_blast_manga-colour_ch653.png`] |
| The reflection | Nanao's Hakkyōken throws it back into him | [seen: `trompete_reflected_anime_ep37.png`] |

Proportions: the horn is ≈ 3× the owl form's height in the anime still and the bell ring ≈ 2.5× his height in the manga
(both perspective-affected) [measured, rough]. Game [G]: horn ≈ 5 m, bell ⌀ ≈ 1.8 m, hovering above him, its bell pointing
along his line of fire. **Simplify:** a cone + a flared bell + a ring with four struts at the bell, the feather plume as 4–5
curved blades. **Never lose:** the bell, the plume, the fist-at-beak pose.

### 6.2 Sabaki no Kōmyō (裁きの光明)
Manga: thin gold waves and a row of explosions across the city; anime: a broad gold beam [seen]. Look [G]: a thin vertical
sheet of gold with a white core, edge-on when possible, leaving a row of explosions (ink SMOKE / DUST fx) along its path.

### 6.3 The remnants (optional)
Long-legged, flamingo-like birds with **round owl faces** (manga: white, the face like the owl form's; anime: glowing
gold) [seen: `remnants_bird-clones_manga-colour_ch654.png`, `remnants_flamingo_anime_ep40.png`]. Useful only for a K.O.
cinematic.

## 7. Verified sources

Every file below was downloaded and opened. "page" is the file's description page (resolved through the wiki API), "file"
the image file itself (append `?format=original` on the wiki CDN to get the original PNG rather than WebP). Article pages
the files were found on: [Lille Barro](https://bleach.fandom.com/wiki/Lille_Barro), [Lille Barro/Image Gallery](https://bleach.fandom.com/wiki/Lille_Barro/Image_Gallery),
[DON'T CHASE A SHADOW](https://bleach.fandom.com/wiki/DON%E2%80%99T_CHASE_A_SHADOW_(episode)), [SHADOWS GONE](https://bleach.fandom.com/wiki/SHADOWS_GONE),
[Shunsui Kyōraku vs. Lille Barro](https://bleach.fandom.com/wiki/Shunsui_Ky%C5%8Draku_vs._Lille_Barro), [Nanao Ise vs. Lille Barro](https://bleach.fandom.com/wiki/Nanao_Ise_vs._Lille_Barro),
[Trompete](https://bleach.fandom.com/wiki/Trompete), [Sabaki no Kōmyō](https://bleach.fandom.com/wiki/Sabaki_no_K%C5%8Dmy%C5%8D),
[Quincy: Vollständig](https://bleach.fandom.com/wiki/Quincy:_Vollst%C3%A4ndig) ("Diagramm", "Jilliel" and "The X-Axis"
redirect to the main article; the chapter pages 645–654 redirect to volume pages that carry only chapter covers), the
official [character page](https://bleach-anime.com/character/) (entry リジェ・バロ), and the Brave Souls
[Lille Barro](https://bleach-bravesouls.fandom.com/wiki/Lille_Barro) page.

| Local file | Episode / chapter | Page | File |
|---|---|---|---|
| **base/** | | | |
| `base_fullbody_front_official-anime.png` | character page | [page](https://bleach-anime.com/character/) | [file](https://bleach-anime.com/assets/img/character/chara_84.png) |
| `base_head_3view_official-anime.png` | character page | [page](https://bleach-anime.com/character/) | [file](https://bleach-anime.com/assets/img/character/face_84.png) |
| `base_face_eye-shut_hat-front_anime_ep24.png` | TYBW 24 (wiki ep 390) | [page](https://bleach.fandom.com/wiki/File:Ep390LilleProfile.png) | [file](https://static.wikia.nocookie.net/bleach/images/5/58/Ep390LilleProfile.png/revision/latest) |
| `base_face_eye-mark_manga-colour_ch599.png` | ch. 599 | [page](https://bleach.fandom.com/wiki/File:599Lille_profile.png) | [file](https://static.wikia.nocookie.net/bleach/images/5/55/599Lille_profile.png/revision/latest) |
| `base_hooded-cloak_anime_ep24.png` | TYBW 24 (wiki ep 390) | [page](https://bleach.fandom.com/wiki/File:Ep390SchutzstaffelAppears.png) | [file](https://static.wikia.nocookie.net/bleach/images/2/23/Ep390SchutzstaffelAppears.png/revision/latest) |
| `base_face_eye-open_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Ep401LilleEyeOpen.png) | [file](https://static.wikia.nocookie.net/bleach/images/0/08/Ep401LilleEyeOpen.png/revision/latest) |
| `base_face_eye-open_manga-colour_ch646.png` | ch. 646 | [page](https://bleach.fandom.com/wiki/File:646Lille_opens.png) | [file](https://static.wikia.nocookie.net/bleach/images/c/cc/646Lille_opens.png/revision/latest) |
| `base_hat-top_back_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Ep401LilleDodgesStab.png) | [file](https://static.wikia.nocookie.net/bleach/images/a/a1/Ep401LilleDodgesStab.png/revision/latest) |
| `base_fullbody_leap-side_manga-colour_ch645.png` | ch. 645 | [page](https://bleach.fandom.com/wiki/File:645Lille_dodges.png) | [file](https://static.wikia.nocookie.net/bleach/images/b/be/645Lille_dodges.png/revision/latest) |
| `base_glove_winged-x_design.png` | n/a | [page](https://bleach.fandom.com/wiki/File:Lille%27s_Glove_Design.png) | [file](https://static.wikia.nocookie.net/bleach/images/a/a7/Lille%27s_Glove_Design.png/revision/latest) |
| **diagramm/** | | | |
| `diagramm_muzzle-cross_end-on_bravesouls-art.png` | n/a | [page](https://bleach-bravesouls.fandom.com/wiki/File:Gacha-5s-Lille-TYBW-Power.png) | [file](https://static.wikia.nocookie.net/bleach-bravesouls/images/e/e4/Gacha-5s-Lille-TYBW-Power.png/revision/latest) |
| `diagramm_side_aim-pose_manga-colour_ch644.png` | ch. 644 | [page](https://bleach.fandom.com/wiki/File:644Lille%27s_Spirit_Weapon%2C_Diagramm.png) | [file](https://static.wikia.nocookie.net/bleach/images/f/fb/644Lille%27s_Spirit_Weapon%2C_Diagramm.png/revision/latest) |
| `diagramm_three-quarter_fur-sleeve_anime_ep24.png` | TYBW 24 (wiki ep 390) | [page](https://bleach.fandom.com/wiki/File:Ep390LilleSpiritWeaponDiagramm.png) | [file](https://static.wikia.nocookie.net/bleach/images/c/ca/Ep390LilleSpiritWeaponDiagramm.png/revision/latest) |
| `diagramm_vertical_carry_manga-colour_ch600.png` | ch. 600 | [page](https://bleach.fandom.com/wiki/File:600Lille%27s_Spirit_Weapon%2C_Diagramm.png) | [file](https://static.wikia.nocookie.net/bleach/images/5/5a/600Lille%27s_Spirit_Weapon%2C_Diagramm.png/revision/latest) |
| `diagramm_full-length-vertical_anime_ep24.png` | TYBW 24 (wiki ep 390) | [page](https://bleach.fandom.com/wiki/File:Ep390LilleDestroysCities.png) | [file](https://static.wikia.nocookie.net/bleach/images/d/d9/Ep390LilleDestroysCities.png/revision/latest) |
| `diagramm_aim-window_anime_ep34.png` | TYBW 34 (wiki ep 400) | [page](https://bleach.fandom.com/wiki/File:Ep400LilleWatchesFight.png) | [file](https://static.wikia.nocookie.net/bleach/images/d/d5/Ep400LilleWatchesFight.png/revision/latest) |
| `diagramm_fur-sleeve-ports_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Ep401LilleAlmostCut.png) | [file](https://static.wikia.nocookie.net/bleach/images/e/ee/Ep401LilleAlmostCut.png/revision/latest) |
| `diagramm_reforming-green-reishi_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Ep401LilleReformsDiagramm.png) | [file](https://static.wikia.nocookie.net/bleach/images/8/80/Ep401LilleReformsDiagramm.png/revision/latest) |
| `diagramm_dial-muzzle-reticle_frames_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Diagramm.gif) | [file](https://static.wikia.nocookie.net/bleach/images/2/22/Diagramm.gif/revision/latest) |
| `diagramm_severed_manga-colour_ch646.png` | ch. 646 | [page](https://bleach.fandom.com/wiki/File:646Lille_reforms.png) | [file](https://static.wikia.nocookie.net/bleach/images/1/1e/646Lille_reforms.png/revision/latest) |
| **jilliel/** | | | |
| `jilliel_fullbody_front_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Ep401LilleVollstandigJilliel.png) | [file](https://static.wikia.nocookie.net/bleach/images/d/d0/Ep401LilleVollstandigJilliel.png/revision/latest) |
| `jilliel_fullbody_front_manga-colour_ch646.png` | ch. 646 | [page](https://bleach.fandom.com/wiki/File:646Lille%27s_Vollstandig%2C_Jilliel.png) | [file](https://static.wikia.nocookie.net/bleach/images/9/9f/646Lille%27s_Vollstandig%2C_Jilliel.png/revision/latest) |
| `jilliel_altered_legs-halo_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Ep401ShunsuiConfrontsLille.png) | [file](https://static.wikia.nocookie.net/bleach/images/2/2f/Ep401ShunsuiConfrontsLille.png/revision/latest) |
| `jilliel_altered_legs_manga-colour_ch648.png` | ch. 648 | [page](https://bleach.fandom.com/wiki/File:648Altered_Jilliel.png) | [file](https://static.wikia.nocookie.net/bleach/images/5/55/648Altered_Jilliel.png/revision/latest) |
| `jilliel_face-window_manga-colour_ch647.png` | ch. 647 | [page](https://bleach.fandom.com/wiki/File:647Lille_teleports.png) | [file](https://static.wikia.nocookie.net/bleach/images/c/cc/647Lille_teleports.png/revision/latest) |
| `jilliel_face-window_robe-holes_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Ep401IchidanmeTameraikizuNoWakachiai.png) | [file](https://static.wikia.nocookie.net/bleach/images/d/d6/Ep401IchidanmeTameraikizuNoWakachiai.png/revision/latest) |
| `jilliel_partial-wings_base-body_anime_ep26.png` | TYBW 26 (wiki ep 392) | [page](https://bleach.fandom.com/wiki/File:Ep392PartialJilliel.png) | [file](https://static.wikia.nocookie.net/bleach/images/1/15/Ep392PartialJilliel.png/revision/latest) |
| `jilliel_silhouette_underwater_anime_ep35.png` | TYBW 35 (wiki ep 401) | [page](https://bleach.fandom.com/wiki/File:Ep401SandanmeDangyoNoFuchi.png) | [file](https://static.wikia.nocookie.net/bleach/images/c/c8/Ep401SandanmeDangyoNoFuchi.png/revision/latest) |
| `jilliel_wings-side_manga-colour_ch649.png` | ch. 649 | [page](https://bleach.fandom.com/wiki/File:649Shime_no_Dan_-_Itokiribasami_Chizome_no_Nodobue.png) | [file](https://static.wikia.nocookie.net/bleach/images/2/2e/649Shime_no_Dan_-_Itokiribasami_Chizome_no_Nodobue.png/revision/latest) |
| **owl/** | | | |
| `owl_fullbody_three-quarter-back_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403LilleVollstandigJillielSecondFormFull.png) | [file](https://static.wikia.nocookie.net/bleach/images/0/06/Ep403LilleVollstandigJillielSecondFormFull.png/revision/latest) |
| `owl_fullbody_three-quarter_manga-colour_ch650.png` | ch. 650 | [page](https://bleach.fandom.com/wiki/File:650Jilliel%27s_second_form.png) | [file](https://static.wikia.nocookie.net/bleach/images/f/f6/650Jilliel%27s_second_form.png/revision/latest) |
| `owl_fullbody_front_arms_manga-colour_ch650.png` | ch. 650 | [page](https://bleach.fandom.com/wiki/File:650Lille_appears.png) | [file](https://static.wikia.nocookie.net/bleach/images/0/0e/650Lille_appears.png/revision/latest) |
| `owl_front_arms-stilts_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403LilleAppearsNanao.png) | [file](https://static.wikia.nocookie.net/bleach/images/0/0c/Ep403LilleAppearsNanao.png/revision/latest) |
| `owl_front_wings-spread_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403JillielSecondForm.png) | [file](https://static.wikia.nocookie.net/bleach/images/e/eb/Ep403JillielSecondForm.png/revision/latest) |
| `owl_neck-head-halo_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403LilleErased.png) | [file](https://static.wikia.nocookie.net/bleach/images/5/58/Ep403LilleErased.png/revision/latest) |
| `owl_head-close_fur-ruff_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403LilleTransforms.png) | [file](https://static.wikia.nocookie.net/bleach/images/5/5a/Ep403LilleTransforms.png/revision/latest) |
| `owl_head-halo-arm_manga-colour_ch652.png` | ch. 652 | [page](https://bleach.fandom.com/wiki/File:652Lille_generates.png) | [file](https://static.wikia.nocookie.net/bleach/images/8/8d/652Lille_generates.png/revision/latest) |
| `owl_head-close_manga-colour_ch650cover.png` | ch. 650 | [page](https://bleach.fandom.com/wiki/File:650Cover.png) | [file](https://static.wikia.nocookie.net/bleach/images/d/dc/650Cover.png/revision/latest) |
| `owl_head-body_manga-colour_ch652.png` | ch. 652 | [page](https://bleach.fandom.com/wiki/File:652Nanao_severs.png) | [file](https://static.wikia.nocookie.net/bleach/images/b/b4/652Nanao_severs.png/revision/latest) |
| **trompete/** | | | |
| `trompete_horn-wing_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403Trompete.png) | [file](https://static.wikia.nocookie.net/bleach/images/e/e3/Ep403Trompete.png/revision/latest) |
| `trompete_bell-end-on_manga-colour_ch653.png` | ch. 653 | [page](https://bleach.fandom.com/wiki/File:653Trompete.png) | [file](https://static.wikia.nocookie.net/bleach/images/d/d4/653Trompete.png/revision/latest) |
| `trompete_blast_manga-colour_ch653.png` | ch. 653 | [page](https://bleach.fandom.com/wiki/File:653Trompete_fires.png) | [file](https://static.wikia.nocookie.net/bleach/images/3/35/653Trompete_fires.png/revision/latest) |
| `trompete_fist-at-beak_frames_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Trompete.gif) | [file](https://static.wikia.nocookie.net/bleach/images/c/c9/Trompete.gif/revision/latest) |
| `trompete_gathering-reishi_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403LilleGathersReishi.png) | [file](https://static.wikia.nocookie.net/bleach/images/a/a7/Ep403LilleGathersReishi.png/revision/latest) |
| `trompete_reflected_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403NanaoDestroysLille.png) | [file](https://static.wikia.nocookie.net/bleach/images/d/d7/Ep403NanaoDestroysLille.png/revision/latest) |
| `sabaki-no-komyo_anime_ep37.png` | TYBW 37 (wiki ep 403) | [page](https://bleach.fandom.com/wiki/File:Ep403SabakiNoKomyo.png) | [file](https://static.wikia.nocookie.net/bleach/images/1/19/Ep403SabakiNoKomyo.png/revision/latest) |
| `sabaki-no-komyo_manga-colour_ch650.png` | ch. 650 | [page](https://bleach.fandom.com/wiki/File:650Sabaki_no_Komyo.png) | [file](https://static.wikia.nocookie.net/bleach/images/9/95/650Sabaki_no_Komyo.png/revision/latest) |
| `remnants_bird-clones_manga-colour_ch654.png` | ch. 654 | [page](https://bleach.fandom.com/wiki/File:654Lille%27s_clones.png) | [file](https://static.wikia.nocookie.net/bleach/images/f/fa/654Lille%27s_clones.png/revision/latest) |
| `remnants_flamingo_anime_ep40.png` | TYBW 40 (wiki ep 406) | [page](https://bleach.fandom.com/wiki/File:Ep406LilleFlamingoForms.png) | [file](https://static.wikia.nocookie.net/bleach/images/c/c7/Ep406LilleFlamingoForms.png/revision/latest) |

The wiki holds more Lille stills than these 49 (113 files on the gallery page, all fetched and triaged); the ones not
kept are crowd shots, other characters' moments, or low-resolution GIFs (190×108).

## 8. Local folder (`.refs/Lille-Barro/`, git-ignored, never committed)

Third-party art lives only in `.refs/` (`.gitignore`: `/.refs/`). Contents as collected on 2026-10-06 (≈ 52 MB):

```
.refs/Lille-Barro/
  INDEX.md                 every file: what it shows, kind, episode/chapter, size, page and file URLs
  contact_base.png  contact_diagramm.png  contact_jilliel.png  contact_owl.png  contact_trompete.png
                           one captioned grid per folder for a quick review
  base/      10  official full body + head turnaround, face eye-shut / eye-mark / eye-open (anime + manga),
                 hooded debut cloak, cap from above, Kageoni leap, glove embroidery
  diagramm/  10  muzzle end-on (Brave Souls), side aim (ch. 644), 3/4 sleeve + plank, upright carry (ch. 600),
                 full length (TYBW 24), window aim (TYBW 34), cut sleeve ports, green re-forming, dial/muzzle/reticle
                 frames, severed rifle (ch. 646)
  jilliel/    9  full front anime + manga, altered form anime + manga, face window x2, partial wings (TYBW 26),
                 underwater silhouette, wings in ch. 649
  owl/       10  full body 3/4 anime + manga, front with arms x3, neck/head/halo, head close x2, ch. 650 cover
                 head, ch. 652 head + body
  trompete/  10  horn + plume (anime), bell end-on (ch. 653), blast, fist-at-beak frames, Reishi gathering,
                 reflection, Sabaki no Kōmyō anime + manga, remnant birds manga + anime
```

## 9. Resolved and still open

Resolved by the images (first-pass §9 items): **1** cap shape and orientation, cloak (debut only, hooded, floor length),
shirt colour (white; right sleeve, bare left arm), the green panel / white legs; **2** Diagramm's length (≈ 2.4 m), the dial
(a knob on the plank), the fur sleeve (real) and the "winged stock" (the black plank, no feathers), no telescopic scope;
**3** Jilliel's wing shape (flat blades, three holes, one root behind the head), colour (anime green, manga pale gold),
halo (thin, flat, just above), hair (hidden); **4** the owl form's legs (four stilts), neck (segmented S, fur crest, ≈ 2.5 T),
no clothes, white body; **5** the Brave Souls "Resurrection" card icon shows the **base form**, not the owl.

Still open:
1. Jilliel's face tattoo (too small in every still found) and a whole-body back view of the base form; the calf cut-outs.
2. **Palette decisions for the user** (not research questions), updated with what the stills show:
   - **Jilliel's green.** The anime makes green Lille's power colour throughout: the eye-open glow, the re-formed rifle, the
     partial wings (TYBW 26) and every Jilliel wing and halo (TYBW 35), saturated (S 0.36–0.55, H 112–150). STYLE_STORM §A.2
     allows exactly three spot hues (FIRE, REIATSU yellow, BLOOD). Options: (a) a muted jade #6E9A80 (S ≤ 0.3, no new spot;
     proposed), (b) green as a fourth spot hue owned by Lille, inside the ≤ 15 % budget except during his big moves, (c) the
     colour manga's pale gold-white wings (#FCFCDD), which keeps the frame monochrome.
   - **The owl form's gold.** Only the wings, halo and glow are gold (the body is white), amber H 35–52 with highlights at
     46–52°, on top of Kenpachi's REIATSU yellow (48–52°). Proposed: Senjumaru's muted gold #B89A5A / #C2A866 for wings and
     halo; note that #B89A5A measures S 0.51, so it already counts as a spot pixel under §A.2's budget.

**The user's decision (2026-10-06), see DUEL_LILLE.md decision 11:** Jilliel's green = a muted jade (an ink tone, no fourth spot hue); the owl form's gold = Senjumaru's #B89A5A on the wings, halo and glow only.
