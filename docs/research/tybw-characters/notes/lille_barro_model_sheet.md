# Lille Barro (リジェ・バロ, 利傑巴羅): modelling reference sheet

The request (the user, 2026-10-06): 「請順便整理利傑巴羅各型態的參考圖作為建模依據」 (collect reference images of each of his forms
as the basis for modelling).

Companion files: the canon fact file `lille_barro.md` (same folder; §1 appearance, §3 Jilliel, §4 the owl form) and the
design doc `docs/duel/DUEL_LILLE.md` (base form, awakening = Jilliel, second awakening = the owl form). This sheet speaks
in the terms the art code uses: `defbody` (`:scale`, `:width`, `:girth`, `:props`, `:palette`, shapes per rig joint),
`defweapon`, art-only chains (Senjumaru's echo arms, engine gap N12), the v4 notan palette and the three spot hues
(`docs/style/STYLE_STORM_DESIGN.md` §A.1–A.2, §2.5).

## 0. How this was made, and how far to trust it

- **No image was opened or downloaded.** The network policy blocks every page and image host this needs
  (`bleach.fandom.com`, `static.wikia.nocookie.net`, `upload.wikimedia.org`, `animeoshi.com` and others answered
  CONNECT 403 / EGRESS_BLOCKED on 2026-10-06). Everything here comes from **web-search result summaries** (the search
  engine's quotes and paraphrases of the Bleach Wiki, fan wikis, reviews) plus the fact file, which was built the same way.
- So the **image list (§7) is a list of pages that carry the images**, not direct image files. Every URL in it appeared in
  a search result (this session, or the fact file's session). None could be opened, so none is verified to show what
  its note says; the note says what the search summary said the page covers.
- **Nothing in this sheet replaces looking.** Each form ends with a "check by eye" list; open the pages in §7 in a
  browser, save the frames into `.refs/Lille-Barro/` (§8), and correct this sheet where the pictures disagree.

**Marks** (as DUEL_SENJUMARU.md / DUEL_LILLE.md): **[V]** manga, **[A]** anime-only (TYBW Part 3, 2024), **[G]** our game
interpretation or a proposal, **[I]** an inference from the sources. Confidence: **high** (two or more independent
summaries agree), **med** (one summary), **low** (one weak or contradicted summary), **recall** (from memory of the
material, found in no source this session; treat as a guess to check). The manga is black and white, so **every colour
is [A] or game art** unless stated; where the manga only gives tone (white / screentone / black) the sheet says so.

**Numbers.** Canon gives no measurements beyond his height. Every metre or ratio below that is not his height is **[G]**:
a starting value for the body file, to be corrected against the references.

## 1. Body and rig baseline (all forms)

| Item | Value | Mark |
|---|---|---|
| Height | **182 cm** (wiki infobox; JP profiles via anime.eiga / anibase summaries also give 182 cm) | [V] high |
| Height conflict | one wiki summary gives "five feet nine inches" (175 cm); use 182 cm | low, ignore |
| Build | youthful-looking adult, **muscular**, broad but not Kenpachi-heavy | [V] med–high |
| Rig scale | Ichigo is `:scale 1.0` at 181 cm, so Lille **`:scale 1.0`, `:width 1.04`** (muscular, sleeveless arms show) | [G] |
| Head | the anime-head rule: `(:head 1.2 1.2 1.2)` in `:girth`, as Ichigo | [G] |
| Hurt cylinder | **r 0.38 / h 1.80** (Ichigo's), in every form; hats, wings, halos, necks add **no** hurt volume (fairness floor, as Senjumaru's crescent) | [G] |
| Rig limits | 21 fixed joints; `:props` stretches `:shoulders`, `:arms`, `:legs` (shin + foot; the pelvis rises with them) and `:spine` (spine + chest + neck together). Bones lengthen, meshes do not stretch. Anything else (wings, a serpentine neck) is an **art-only chain** drawn from an anchor joint, as Senjumaru's echo arms | engine fact |

Silhouette across the roster (the existing reads, DUEL_SENJUMARU §2): Yamamoto = hunched white haori + FIRE; Kenpachi =
2 m, white sleeveless haori + yellow; Rukia = small, all black; Ichigo = tall black, orange head, two blades; Senjumaru =
small white figure, gold halo, gold fan of arms. **Lille's base form must read as "the dark-skinned man in a white
cloak with a green fur hat and a rifle longer than a sword"**: the only fighter with a long straight horizontal line.
Watch two collisions: Kenpachi is also white and sleeveless (separate them by the hat, the rifle and the green), and
Senjumaru also owns a gold halo and a gold fan (Jilliel's wing fan and the owl form's gold must differ in shape:
blades with holes, not arms; a thin ring, not a crescent).

## 2. Base form (万物貫通 THE X-AXIS, Diagramm, the left eye shut)

### 2.1 Silhouette: three readable elements
1. **The rifle line**: a long, thin, dead-straight black line ending in a **cross (+) muzzle brake**.
2. **The green fur bicorne**: a wide, two-pointed fur hat on a small crew-cut head.
3. **The asymmetric white cloak**: a long white cloak over dark skin, with **one dark-green fur pauldron on the right
   shoulder** only.

The fourth, close-range element (portraits, cinematics, the eye meter's state): **the left eye shut under an
X-in-a-circle crosshair tattoo**.

### 2.2 Parts list, front / side / back

| Part | Description | Mark |
|---|---|---|
| Skin | **dark skin** | [V][A] high |
| Hair | **white**, cut almost to a **crew cut**, with **short trimmed sideburns** | [V] high (crew cut), med (sideburns) |
| Eyes | black eyes; the **left eye kept shut**; the right eye open | [V] high |
| Crosshair mark | a black tattoo over the **left** eye: **an X inside a circle** ("reads like a tilted crosshair"); JP summaries call it an "X-shaped scar/mark on the left eye" (左目に入ったX型の傷跡) | [V] high (left eye, X), med (the circle) |
| Eye-open variant | the left eye opens in a crisis (three times, ch. 645); the tattoo stays. In the eye-open frames the attack passes through him | [V] high |
| Hat | a **dark-green furred bicorne** with a **small Wandenreich emblem on each side** | [V][A] high (wiki text) |
| Hat orientation | which way the two points face (side to side, Napoleonic, or fore and aft) | **unknown, check by eye** |
| Cloak | a **long white cloak** over everything; in ch. 599 he **casts off the cloak** to bare Diagramm | [V] high (white cloak), med (cast off) |
| Shirt | a **light-coloured sleeveless shirt** (arms bare from the shoulder) | [V] med–high; colour vague |
| Pauldron | a **dark-green furred pauldron on the right shoulder** | [V][A] high |
| Gloves | **white gloves embroidered with a winged X** (on the back of the hand) | [V] high; embroidery colour unknown |
| Trousers | **dark-green trousers** | [A] high (wiki text) |
| Leggings | **white leggings with cut-outs near the calves**, which **attach to the shirt** (straps or a one-piece line running up under the trousers: check) | [V] med |
| Shoes | **light-coloured shoes** | [V] med |
| Weapon at rest | Diagramm **slung across his back under the cloak** | [V] med–high |

Front: dark face with the white crew cut, the closed left eye and its mark, the bicorne's brim, the sleeveless light
shirt, the right fur pauldron, the white gloves, green legs with white calves showing through the cut-outs.
Side: the hat's points and depth; the rifle's line diagonal across the back under the cloak (stock low, barrel up, or
the reverse: check). Back: a plain white cloak mass; the rifle's ends may show past its hem and above the shoulder.

### 2.3 Proportions [G] (ratios to his 182 cm height H)

| Measure | Ratio | Metres | Note |
|---|---|---|---|
| Crown | 1.00 H | 1.82 | `:scale 1.0` |
| Hat top | ≈ 1.08 H | ≈ 1.97 | fur bicorne ≈ 0.15 m tall, ≈ 0.40 m tip to tip [G] |
| Shoulder width | ≈ 0.26 H | ≈ 0.48 | `:width 1.04`; the pauldron adds ≈ 0.06 on the right |
| Cloak hem | ≈ 0.12 H above the floor | ≈ 0.22 | mid-shin; check the length (ankle or calf) |
| Head (anime ×1.2) | ≈ 0.14 H | ≈ 0.25 incl. hair | as Ichigo |

### 2.4 Colours (all [A] or game art; the manga gives white cloak / tone hat and trousers / black rifle and tattoo)

Hex values are **approximations** chosen for the v4 notan palette (STYLE_STORM §A.1: V0 black, V4 white, colours
muted to S ≤ 0.45 unless they are one of the three spot hues). None is sampled from a frame.

| Palette key | Lit hex | What |
|---|---|---|
| `:skin` | **#6E4A3A** (shade #4A3028) | dark brown, muted warm (skin is "the only warm non-spot colour"); the white cloak and hair against it carry the notan contrast |
| `:hair` | #E8E8E4 | white crew cut; ink keyline #101018 |
| `:white` | #ECECE8 | the cloak, gloves, leggings, shoes |
| `:shirt` | #D8D6CC | the light sleeveless shirt (one value below the cloak so the two read apart) |
| `:green` | **#2F3B2E** (fur light #46563F) | hat, pauldron, trousers: a dark muted green, S ≈ 0.25, **not a spot hue** |
| `:black` | #16161E | Diagramm, the tattoo, the muzzle brake; keyline #4A5062 on it (black-part rule) |
| `:emblem` | #B89A5A muted gold or #D8DCE4 white | the hat emblems and the gloves' winged X: colour **unknown**, check |
| eye-open accent | white + the cold steel tint | the phase flash when the left eye opens (no new hue) |

### 2.5 Signature poses

| Pose | Description | Mark |
|---|---|---|
| Idle | upright, still, the deadpan sniper; rifle **slung under the cloak** in canon. For play, rifle **carried at port arms** or **butt grounded, barrel up** beside him, so its line is always on screen | [V] stillness high; carry [G] |
| Aim | rifle **shouldered on the right**, cheek to the stock, **the right eye at the scope** (the left is shut by his rule); left hand forward under the forestock | [I] high for the right eye (the left is shut), med for right-shouldered |
| Aim, adjusting | he **adjusts the dial and looks through the scope** before firing (ch. 644 / TYBW 34) | [V][A] med |
| Fire | a single recoil-less snap: the shot is effectively instant along the line, so the pose barely moves; the effect is the line and a **perfectly round hole** in the target | [V] med (round holes, instant) |
| Dodge | the **Kageoni leap**: he jumps clear on the first try | [V] high |
| Hit (eye open) | the left eye snaps open, the crosshair flares, the blade passes **through** him | [V] high |
| Hit (normal) | a stiff, upright flinch; he never brawls | [I] |

### 2.6 Simplify for the ink style / never lose

- **Simplify:** the fur becomes **one bevelled mass with 3–5 jagged ink strokes** on its edge (no fur cards); the hat's
  emblems become a small pale disc each side; the gloves' winged X becomes a 2-stroke mark or vanishes at play distance;
  the leggings' cut-outs become **one dark window per calf**; the cloak is a rigid `:cyl` / plate mass on `:chest` and
  `:pelvis` (no cloth sim), split at the front so the shirt shows.
- **Never lose:** the rifle's **length and straightness** and its **+ muzzle**; the **green fur hat**; **one** pauldron on
  the **right**; the **shut left eye with the X-in-circle**, and an unmistakable eye-open frame (it is a game state);
  dark skin against white cloth.

### 2.7 Check by eye
Hat orientation and size; cloak length and whether it has a hood/collar; shirt colour; how the leggings attach to the
shirt; the emblem and embroidery colours; whether the eye-open frame shows an iris or a glowing eye in the anime.

## 3. Diagramm (ディアグラム), the spirit weapon

### 3.1 Parts

| Part | Description | Mark |
|---|---|---|
| Overall | a **large sniper rifle of black metal** | [V] high |
| Barrel | **long and slender**, "extraordinarily long and thin" | [V] high |
| Muzzle brake | **black, cross-shaped** (a "+" of four fins seen end-on) at the tip | [V] high |
| Scope | a telescopic scope on top | [V] med (ch. 644) |
| Dial | an adjustment **dial** he turns before shooting (likely on the scope or the receiver: check) | [V] med |
| Fur wrapping | the receiver and forestock (one version says "body and barrel", another "receiver and stock") **wrapped in dark-green fur**, matching the hat | low–med (one AI-written database, three paraphrases; not in the wiki text the fact file quotes) |
| Stock | a **bulky stock** that "sprouts **wing-shaped supports**" bracing it against his shoulder | low–med (same source) |
| Carry | slung **across his back under the cloak** | [V] med–high |
| Severed state | ch. 645 / TYBW 35: Kyōraku **cuts most of the barrel off** (Daruma-san ga Koronda); the rest of the fight uses the stump or the Vollständig | [V][A] high |

### 3.2 Proportions [G]

No canon length. Proposal, to check against the ch. 599 and TYBW 34–35 frames:

| Measure | Ratio to H | Metres |
|---|---|---|
| Overall length | **≈ 1.1 H** | **≈ 2.0** |
| Barrel (receiver to muzzle) | ≈ 0.6 H | ≈ 1.1 |
| Barrel diameter | ≈ 0.02 H | ≈ 0.04 (thin: it must read as a line) |
| Muzzle brake | ≈ 0.08 H across the cross | ≈ 0.14 × 0.14, ≈ 0.10 long |
| Scope | ≈ 0.2 H long | ≈ 0.35, ⌀ 0.05 |
| Stock | ≈ 0.25 H long, ≈ 0.08 H deep | ≈ 0.45 × 0.15 |
| Severed barrel | the barrel cut to ≈ 0.15 H past the receiver | ≈ 0.27 |

`defweapon :diagramm (:length 2.0)` on `:weapon-r`, the **grip at ≈ 0.55 of the length from the muzzle end**, the left
hand on the forestock. The design doc's J / K are "rifle butt and bayonet" strings: **there is no bayonet in canon** [G];
if one is added it must be a short blade under the muzzle, and the drawn tip must match the hit volume (±0.15 m FK test).
A `:diagramm-cut` variant (the severed barrel) is a cosmetic option for damage states.

### 3.3 Simplify / never lose
- **Simplify:** the scope to a cylinder + two rings; the dial to a disc; fur to a jagged ink band round the forestock; the
  wing supports (if confirmed) to two flat wedges.
- **Never lose:** the length (longer than any sword in the roster), the **thin straight barrel**, the **+ muzzle** (it is
  his X: the crosshair, the muzzle and the letter all rhyme), black metal.

### 3.4 Check by eye
Overall length against his body; where the dial is; whether the fur wrapping and the stock's wing supports are real;
whether the anime adds colour (green fur, any gold).

## 4. Vollständig 神の裁き JILLIEL (ch. 646; TYBW 35–36)

### 4.1 Silhouette: three readable elements
1. **The eight-wing fan**: four pairs of long wings spread round him, **each pierced by three round holes** (24 muzzles).
2. **The armless cocoon**: a cream-white carapace robe from **the mouth down**, tapering like a teardrop; no arms; he
   **floats**.
3. **The wide, thin halo** (Heiligenschein), large and gold in the anime.

### 4.2 Parts

| Part | Description | Mark |
|---|---|---|
| Wings | **eight wings, three holes each**; JP: 「4対の羽を持つ天使」 (four pairs) | [V] high |
| Hole count | 3 per wing, 24 total (one blog says "4 per wing" while also saying 24: a slip) | [V] high for 3 |
| Wing shape | long, blade-like feathered wings fanning out from behind the shoulders, four per side, in a near-radial fan (fans call the form "the winged chair") | recall / low; **check** |
| Wing colour | **conflict**: "eight expansive **green** wings" (Filibuster), green Reiatsu glow shifting to gold in the second form (Anime Explained ep 37: "the transformation of his wings' colours from green to a golden palette"); but "eight **golden** wings" (Sportskeeda ep 35, Brave Souls). Best reading: **green in the anime's Jilliel, gold from the revival on**; Brave Souls may use gold throughout | [A] med; **check** |
| Robe | a **large carapace-like robe covering his body below the mouth**; "priestly cream-white"; "white cocoon-like" | [V][A] high |
| Arms | **none visible**: the arms are replaced by (or hidden under) the wings; the owl form "regrows the arms he had lost" | [V] med–high |
| Legs | hidden in the robe; one summary says **long "giraffe-like" legs show when the robe opens** | [A] low; **check** |
| Halo | a **wide and thin** Heiligenschein; anime: "a **huge golden** Heiligenschein **above his head**" | [V] high (wide, thin); [A] med (gold, above) |
| Face | **a more elaborate tattoo** than the base X; the robe hides the mouth; one blog says "the absence of hair and a mouth" (is the crew cut hidden by a hood?) | [V] high (tattoo), low (hair); **check** |
| Eyes | both open by now (the third opening released the form) | [I] high |
| Posture | upright, **floating**, serene; flies over Wahrwelt's rooftops | [V] high |

### 4.3 Proportions [G]

| Measure | Ratio to H | Metres |
|---|---|---|
| Body (head + cocoon) | ≈ 1.0 H tall, hovering **0.3 m** off the floor (cosmetic root lift; the hurt cylinder stays grounded, as the design doc says) | ≈ 1.82 + 0.3 |
| Cocoon width | ≈ 0.3 H at the shoulders, tapering to ≈ 0.1 H at the bottom point | 0.55 → 0.18 |
| Each wing | ≈ 0.9 H long, ≈ 0.12 H wide | ≈ 1.6 × 0.22 |
| Wing span (tip to tip, top pair) | ≈ 2.2 H | ≈ 4.0 (the widest silhouette in the roster: keep it inside the camera's framing) |
| Holes | ⌀ ≈ 0.05 H, evenly spaced along the outer two-thirds of each wing | ⌀ ≈ 0.09 |
| Halo | outer ⌀ ≈ 0.8 H, band ≈ 0.02 H, ≈ 0.15 H above (or behind) the head | ⌀ ≈ 1.45 |

Rig mapping [G]: the `:jilliel` body skins no shapes on the arm joints (armless); the cocoon is a tapered `:cyl` from
`:chest` to below the feet (the legs' joints draw nothing); the wings are **eight art-only rigid plates** anchored on
`:chest` (the echo-arm precedent, N12), each with a small idle flap from a shared fx clock; the halo is a thin ring
on `:head` (or the chest, so it does not bob with nods). The wing **holes** are cut-outs or black discs with a light
core; each hole is a muzzle anchor for the WING VOLLEY lines (24 named points).

### 4.4 Colours

| Key | Lit hex | Note |
|---|---|---|
| `:robe` | #E6E0CC | cream-white, warmer than the base cloak's #ECECE8 |
| `:wing` | **decision needed**: muted jade **#6E9A80** (S ≤ 0.45, not a spot) with white cores, **or** the same muted gold as the halo | the anime's green is a fourth hue; STYLE_STORM §A.2 allows exactly three spot hues (FIRE, REIATSU yellow, BLOOD) |
| `:halo` | #B89A5A muted gold (lit #C2A866) | Senjumaru's gold key: no new spot hue |
| `:skin`, `:hair` | as base | only the face shows |
| tattoo | #16161E | the larger pattern: check its shape |
| shots | white core + cold steel tint, 1–2 px lines | the X-Axis is a line, not a coloured beam |

### 4.5 Wing shots (the look of the WING VOLLEY)
- [V] high: shots fire **from the holes of the wings**, "instantaneous"; gathering energy in **all 24 holes** gives one
  blast that severs part of a city. [V] med: the light that carries the X-Axis is called **裁きの光明 Sabaki no Kōmyō**
  in one summary (the wiki places that name in the second form; see §5).
- [G]: each firing hole flashes (a white disc), a **thin straight line** runs to the target, and a **round hole** opens
  where it lands. The charged 24-hole blast is every hole lighting in sequence, then 24 converging lines.

### 4.6 Signature poses
- **Idle:** floating, upright, the wings slowly breathing open and shut, the halo still. [V] serene high.
- **Fire:** no arms, so the "gesture" is the **wings snapping forward** to aim their holes, the head level. [G]
- **Hit:** passes through (the intangible stance, decisions 3–5); a real hit = the cocoon jolts, wings flare. [G]
- **Bankai beats (cinematic material):** wounds appear on him (Act 1), black spots (Act 2), drowning in the dark ocean
  while flapping uselessly (Act 3), the **golden glowing cut across the throat** that expands upward (Act 4). [V] high.

### 4.7 Simplify / never lose
- **Simplify:** feathers to 3–4 ink notches per wing edge; the robe to one smooth tapered mass with 2–3 white fold
  strokes; the tattoo to a few bold strokes.
- **Never lose:** **8 wings × 3 holes** (count them in the still), **no arms**, the **covered mouth**, the **thin wide halo**,
  the float.

### 4.8 Check by eye
Wing shape (feathered or plate-like) and where they root; wing colour in TYBW 35–36; halo position (above, behind,
tilted) and inner pattern; the tattoo's new shape; hair under a hood or not; the "giraffe legs" moment.

## 5. The second form, the owl ("true form" of Jilliel; ch. 650–654; TYBW 37)

### 5.1 Silhouette: three readable elements
1. **The serpentine neck with an owl's face**: a long, curving, snake-like neck, furred on its back, ending in a
   **barn-owl head** (the heart-shaped facial disc, owl eyes, beak) with slicked-back hair.
2. **Stilt legs and big arms**: a thin, lanky, curved body on **greatly lengthened legs/shoes** (the "centaur" read) with
   **regrown arms, much larger** than before.
3. **Gold everywhere**, the wings kept, and a **small spiked halo** (the Jilliel halo shrunk and given spikes).

### 5.2 Parts

| Part | Description | Mark |
|---|---|---|
| Overall | "an angelic, bird-like being with a very curved but thin, lanky build"; JP: a monster combining a barn owl and a man (メンフクロウと人) | [V] high |
| Head | a **new, fair-skinned head** with **slicked-back hair**, with **the eyes, nose and beak of an owl** | [V] high |
| Hair (anime) | the anime "altered the design … with his **white hair fused to the long neck** rather than wispy" | [A] low–med (one summary) |
| Neck | **elongated, like the body of a snake, with fur on its back** | [V] high |
| Halo | **drastically reduced in size and gains spikes** | [V] high |
| Arms | **regrown, much larger**; "after forming a pair of long arms on either side of his torso, Lille raises the right one and fires" | [V] high (larger), med (right arm raised) |
| Legs | "**his shoes greatly extend**, making him look like a **centaur**"; "elongated limbs"; "giraffe-like legs" | [V] high (centaur read); the exact construction (two stilt legs, or a horse-like lower body) **check** |
| Wings | kept, now **golden**; Trompete's reflection later **severs his left arm and a set of wings** | [V][A] high |
| Colour | the Reiatsu and wings shift **from green to gold** as the headless body rises and the face re-forms "from energy" | [A] high |
| Voice / eyes | the anime processes his voice digitally and adds a first-person shot from inside his eyes (anime-original) | [A] med |
| Clothes | "devoid of the restraints of his clothes" (the cocoon robe is gone) | med; **check** |

### 5.3 Proportions [G]

This form is a different skeleton in all but name. Proposal with the fixed 21-joint rig:

| Measure | Ratio to base H | Metres | Rig mapping |
|---|---|---|---|
| Overall to the head | ≈ 1.7 H | ≈ 3.1 | `:legs 1.6` (pelvis rises), plus the neck chain |
| Legs (hip to floor) | ≈ 0.85 H | ≈ 1.55 | `:props :legs 1.6`; thin shins, long pointed shoes |
| Torso | ≈ 0.3 H, narrow (`:width 0.85`), arched | ≈ 0.55 | `:spine` flexed forward in every pose (the "very curved" build) |
| Neck | ≈ 0.5 H, an S-curve | ≈ 0.9 | **art-only chain** of 5–6 tapering segments from `:chest`, the head drawn at its end (the rig `:head` draws nothing); segments lag the chest by 1–3 f (the echo-arm history) so it sways |
| Owl head | ≈ 0.16 H tall, disc ≈ 0.14 H wide | ≈ 0.29 × 0.25 | heart-shaped facial disc, two round dark eyes, a small hooked beak |
| Arms | ≈ 0.6 H each | ≈ 1.1 | `:props :arms 1.5`, `:girth` upper/lower arm 1.3 |
| Halo | ⌀ ≈ 0.2 H, 6–8 spikes | ⌀ ≈ 0.36 | on the neck chain's last segment, behind the head |
| Wings | as Jilliel but gold, ≈ 1.0 H long | ≈ 1.8 | the same eight plates, re-coloured |

Hurt cylinder stays **r 0.38 / h 1.80** (fairness floor); the head and neck sit above it and take no hits. The camera
framing must allow ≈ 3.1 m plus wings: check against Kenpachi's Bankai framing.

### 5.4 Colours

| Key | Lit hex | Note |
|---|---|---|
| `:gold` | **#B89A5A** muted (lit #C2A866) | body and wings; the S ≤ 0.45 muted gold Senjumaru already uses. A saturated gold would collide with Kenpachi's REIATSU spot yellow (48–52°): **user decision** if a spot exception is wanted during his big moves |
| `:glow` | #FFE8A8 core, #FFFFFF | light from his eyes and body (Hakkyōken "diffuses the light which Lille is emitting") |
| `:face` | #E2CCBC | the "fair-skinned" owl face (pale, not his dark base skin) |
| `:hair` | #E8E8E4 | slicked back, fused into the neck in the anime |
| `:fur` | #8A7A5A | the neck's back fur, a muted darker gold-brown |
| eyes / beak | #16161E | two black discs and the beak |

### 5.5 Signature poses
- **Idle:** hunched forward, the neck in an S, the head cocked like an owl's, the big arms hanging, the wings half
  open. [I] (owl head-cock: [G])
- **Sabaki no Kōmyō (裁きの光明):** a **chopping gesture with his arm** that fires **thin waves of golden light**; lines of
  explosions across the city behind them. [V] med (the wiki technique page; the conflict with §4.5 is recorded in the fact
  file §3). [G]: the right arm raised high, then a straight downward chop; the wave is a thin vertical gold sheet edge-on.
- **Trompete pose:** see §6.
- **Light from the eyes:** a glare; Nanao's mirrors throw it back so bright he cannot see her sword. [V] med
- **Hit / defeat:** the reflected Trompete **erases a thin strip of his body**, severs the **left arm and a set of wings**,
  exposes **golden energy** inside, and **breaks the halo**; he falls, notes he has lost his halo, and **scatters "like
  rain"** into golden, crane- or flamingo-like birds (ch. 654; TYBW 40). [V] high (order), med (chapters)

### 5.6 Simplify / never lose
- **Simplify:** the neck to a tapered segment chain with an ink fur crest along its back; the owl disc to one flat
  heart-shaped plate with two black eyes and a wedge beak; the body to thin rods; feathers as notches.
- **Never lose:** the **S-neck**, the **owl disc face**, the **small spiked halo** (it must contrast with Jilliel's wide thin
  one: a broken halo is his defeat beat), the **too-long legs**, the **big arms**, gold.

### 5.7 Check by eye
How the "centaur" legs are built; the neck's length and curve; the face's colour and the hair in the anime; whether any
robe remains; the halo's spike count; how many wings remain and their colour.

## 6. Props and effects of the second form

### 6.1 Trompete (神の喇叭, "Trumpet of God"; ch. 653; TYBW 37)

| Item | Description | Mark |
|---|---|---|
| Gesture | **a closed fist held in front of his beak** as though grasping a trumpet; he **blows into the fist** | [V] high |
| The trumpet | absorbs Reishi from the surroundings to form an **enormous golden trumpet** ("horn") **with a wing-like appendage** ("crowned with a wing above it"), **in the air above him** | [V] high |
| The blast | a **massive X-Axis blast**, erasing everything on its line of fire **while the trumpet sounds** (音を鳴らしながら); one summary calls it "a wide spherical blast"; it erases a large part of a Wahrwelt city | [V] high (erase), med (spherical) |
| The reflection | Nanao's **Shinken Hakkyōken** (a bladeless ritual sword with mirrors along its length) protects the ground and **reflects the blast into him** | [V] high |

Proportions [G]: the trumpet ≈ 3.0 H long (≈ 5.5 m), the bell ⌀ ≈ 1.0 H (≈ 1.8 m), hovering ≈ 1.0 H above his head, its
bell pointing along his line of fire; one golden wing (≈ 1.5 H) rising from its top. Muted gold body, a white-hot bell
interior when it sounds. Simplify the valves to three discs; **never lose** the bell, the wing and the fist-at-beak pose.

### 6.2 Sabaki no Kōmyō (裁きの光明)
Thin golden light waves from an arm chop (§5.5); in Jilliel, possibly light from the wings (§4.5). [V] med. Look [G]: a
thin vertical sheet of gold with a white core, edge-on to the camera when possible, leaving a row of explosions (ink
SMOKE / DUST fx) along its path.

### 6.3 The remnants (optional)
Golden crane- or flamingo-like birds that fire beams (ch. 654, TYBW 40). Useful only for a K.O. cinematic: the body
breaks into these and they fly off. [V] med.

## 7. Image list (pages that carry the images)

Every URL below appeared in a web-search result (**S** = this session's searches, **F** = the fact file's searches). **None
could be opened** from this environment, so every entry is **unverified**; the note is what the search summary said the
page covers. No direct image-file URL (static.wikia / nocookie) appeared in any search result, so there are none here;
from a wiki page, open the image and use "Open image in new tab" to get the file.

### 7.0 All forms
| URL | Shows (per search) | Src |
|---|---|---|
| https://bleach.fandom.com/wiki/Lille_Barro/Image_Gallery | the wiki's gallery: manga and anime images of every form (incl. Lille with Gerard and Askin in the Soul King Palace) | S, F |
| https://bleach.fandom.com/wiki/Lille_Barro | the main article: infobox portrait, appearance text, form images | S, F |
| https://www.pinterest.com/pin/lille-barroimage-gallery--944489353090629302/ | a pin of the wiki gallery | S |
| https://www.pinterest.com/pin/517351075963619446/ | "Google Image Result for static.wikia.nocookie.net …": **content unknown** | S |
| https://myanimelist.net/character/114967 | MAL character page with anime pictures | S, F |
| https://anime.jepang.org/karakter/114967/Lille_Barro | "Gambar Karakter Anime" (character images) mirror of MAL | S |
| https://anibase.net/en/character/4k2OV/Lille-Barro | character database page (anime images) | S |
| https://renote.net/tags/21261 | JP tag page "リジェ・バロ / Lille Barro" (articles with screenshots) | S |
| https://renote.net/articles/251985 | JP article on Lille (screenshots) | S |
| https://ciatr.jp/topics/338893 | JP explainer of his abilities and forms (screenshots) | S, F |
| https://villains.fandom.com/wiki/Lille_Barro | Villains Wiki: infobox + gallery | S, F |
| https://vsbattles.fandom.com/wiki/Lille_Barro | VS Battles profile: usually one image per form | S |
| https://daddyjim.ai/bleach/character/Lille-Barro | a database page paraphrasing the wiki (images unknown) | S |

### 7.1 Base form (4–10)
| URL | Shows (per search) | Src |
|---|---|---|
| https://daddyjim.ai/bleach/manga-chapter/599-Too-Early-To-Win-Too-Late-To-Know | ch. 599: the Schutzstaffel debut; he casts off the cloak and fires Diagramm | S |
| https://bleach.fandom.com/wiki/The_Royal_Guard_vs._The_Wandenreich | ch. 601–602: shooting Nimaiya through two shields | F |
| https://bleach.fandom.com/wiki/User_blog:Xilinoc/Ch._645_-_Don't_Chase_a_Shadow | ch. 645 review: the eye-opening frames | F |
| https://bleach.fandom.com/wiki/Shunsui_Ky%C5%8Draku_vs._Lille_Barro | the fight page: base form, eye opens, Jilliel | F |
| https://bleach.fandom.com/wiki/BABY,HOLD_YOUR_HAND | TYBW 34 episode page: Lille at his scope | F |
| https://animecorner.me/shunsui-kyoraku-takes-on-lille-barro-in-bleach-thousand-year-blood-war-episode-35-preview/ | official TYBW 35 preview stills (anime colours of the base form) | S |
| https://www.sportskeeda.com/anime/bleach-tybw-episode-35-preview-teases-shunsui-kyoraku-vs-lille-barro | TYBW 35 preview stills | S |
| https://sportskeeda.com/anime/bleach-cosplayer-s-lille-barro-makeover-fans-wowed | a cosplay (by @Haitiansenpai) with a detailed Diagramm replica: a real-world 3D read of the outfit | S |
| https://animeexplained.com/explained/bleach-thousand-year-blood-war-episode-35-review | TYBW 35 review with screenshots | S |

### 7.2 Diagramm (4–10)
| URL | Shows (per search) | Src |
|---|---|---|
| https://daddyjim.ai/bleach/item/Diagramm | the weapon entry (fur wrapping, + muzzle, wing-shaped stock supports) | S |
| https://daddyjim.ai/bleach/manga-chapter/599-Too-Early-To-Win-Too-Late-To-Know | ch. 599: the rifle bared and fired | S |
| https://www.sportskeeda.com/anime/how-daruma-san-ga-koronda-work-shunsui-kyoraku-s-new-technique-bleach-tybw-explored | Daruma-san ga Koronda: the scene where the barrel is cut | S |
| https://bleach.fandom.com/wiki/DON%E2%80%99T_CHASE_A_SHADOW_(episode) | TYBW 35 episode page: aiming, the severed barrel | F |
| https://sportskeeda.com/anime/bleach-thousand-year-blood-war-how-powerful-lille-barro-everything-know-x-axis | X-Axis explainer with screenshots of the rifle shots | S, F |
| https://sportskeeda.com/anime/bleach-cosplayer-s-lille-barro-makeover-fans-wowed | the cosplay replica of the rifle | S |

### 7.3 Jilliel (4–10)
| URL | Shows (per search) | Src |
|---|---|---|
| https://www.tumblr.com/dailyanimeart/130679038350/bleach-646-sees-lille-barro-vs-shunsui-as-their | ch. 646 review: the Vollständig reveal | F |
| https://daddyjim.ai/bleach/manga-chapter/647-THE-THEATRE-SUICIDE | ch. 647: Jilliel vs the Bankai | S |
| https://animecorner.me/mayuris-fight-against-pernida-continues-in-bleach-thousand-year-blood-war-episode-36-preview/ | TYBW 36 preview stills: Lille transforming (Jilliel) | S |
| https://www.sportskeeda.com/anime/bleach-tybw-part-3-episode-9-pierrot-films-justice-shunsui-s-bankai | TYBW 35 review: Jilliel in colour ("eight golden wings … huge golden Heiligenschein") | S |
| https://sportskeeda.com/anime/bleach-tybw-episode-35-shunsui-kyoraku-reveals-bankai-battle-lille-barro-begins | TYBW 35 recap with stills | S, F |
| https://thefilibusterblog.com/understanding-lille-barros-vollstandig-in-bleach-tybw/ | Jilliel explainer ("eight expansive green wings") with images | S |
| https://gamerant.com/bleach-tybw-lille-barro-vollstandig-explained/ | Jilliel explainer with images | F |
| https://bleach-bravesouls.fandom.com/wiki/6%E2%98%85_Lille_Barro_(TYBW_Version) | Brave Souls 6★ card art (Vollständig, wing beam special) | F |
| https://bleach-bravesouls.fandom.com/wiki/5%E2%98%85_Lille_Barro_(TYBW_Version) | Brave Souls 5★ card art | F |

### 7.4 The owl form (4–10)
| URL | Shows (per search) | Src |
|---|---|---|
| https://bleach.fandom.com/wiki/SHADOWS_GONE | TYBW 37 episode page: the owl form, Nanao, Trompete | S, F |
| https://www.sportskeeda.com/anime/why-lille-barro-turn-owl-like-angel-bleach-tybw-his-second-form-s-design-explored | the owl design explained, with stills | S, F |
| https://dailyanimeart.com/2015/11/05/nanaos-zanpakuto-kyokotsu-lilles-evolution-bleach-650/ | ch. 650 review: the revival into the owl form | F |
| https://animecorner.me/nanao-learns-the-truth-in-bleach-thousand-year-blood-war-episode-37-preview/ | official TYBW 37 preview stills | S |
| https://www.animeexplained.com/explained/bleach-thousand-year-blood-war-episode-37-review/ | TYBW 37 review (green → gold) with stills | F |
| https://sportskeeda.com/anime/bleach-tybw-part-3-episode-11-anime-vs-manga-comparison | TYBW 37 anime vs manga panels side by side: the best manga/anime design comparison | S |
| https://www.cbr.com/bleach-thousand-year-blood-war-part-3-episode-11-review/ | TYBW 37 review with stills | F |
| https://gamerant.com/bleach-tybw-lille-barros-final-form-explained/ | the "Cherubim form" explainer with images | F |
| https://bleach-bravesouls.fandom.com/wiki/6%E2%98%85_Lille_Barro_(TYBW_Version)_(Resurrection) | Brave Souls "Resurrection" card (form unconfirmed: check whether it is the owl) | F |
| https://bleach.fandom.com/wiki/Nanao_Ise_vs._Lille_Barro | the fight page: owl form, Hakkyōken, the defeat | S, F |

### 7.5 Trompete and Sabaki no Kōmyō (4–10)
| URL | Shows (per search) | Src |
|---|---|---|
| https://bleach.fandom.com/wiki/Trompete | the technique page: the fist-at-beak pose, the golden trumpet with its wing | F |
| https://daddyjim.ai/bleach/character/Trompete | a paraphrase of the technique page | S |
| https://bleach.fandom.com/wiki/User_blog:Xilinoc/Ch._653_-_The_Theatre_Suicide_SCENE_7 | ch. 653 review: Trompete and its reflection | S |
| https://www.fandompost.com/2015/12/01/bleach-chapter-653-manga-review/ | ch. 653 review | S |
| https://www.fandompost.com/2015/11/24/bleach-chapter-652-manga-review/ | ch. 652 review: Hakkyōken, the arm dispersed | F |
| https://bleach.fandom.com/wiki/Sabaki_no_K%C5%8Dmy%C5%8D | the chopping-gesture light waves | F |
| https://daddyjim.ai/bleach/manga-chapter/654-Deadman-Standing | ch. 654: the broken halo, the scattering, the bird remnants | S |
| https://dailyanimeart.com/2015/12/04/dead-man-kira-vs-lille-gerards-miracle-bleach-654/ | ch. 654 review: Kira vs the remnants | F |
| https://bleach.fandom.com/wiki/MY_LAST_WORDS_(episode) | TYBW 40: the remnants cut down | F |

**Counts:** all forms 13, base 9, Diagramm 6, Jilliel 9, owl 10, Trompete 9 (some pages repeat across forms).

**Fastest route to good references:** the wiki Image Gallery (7.0) for the manga panels; the TYBW 35 / 36 / 37 preview
pages on animecorner (official stills, 7.1 / 7.3 / 7.4) for anime colour; the Sportskeeda "episode 11 anime vs manga"
page (7.4) for the owl form in both media.

## 8. Local folder layout (`.refs/`, git-ignored, never committed)

Third-party art lives only in `.refs/` (`.gitignore`: `/.refs/`), as `.refs/Ichigo/` does. Suggested names: `NN-source-what`.

```
.refs/Lille-Barro/
  base/
    01-wiki-infobox-portrait.png        the main portrait
    02-ch599-cloak-off.png               cloak cast off, rifle bared
    03-ep35-front-full.png               anime full body, front (colours)
    04-ep35-side.png                     side view: hat points, rifle on the back
    05-ep35-back.png                     the cloak from behind
    06-ep35-face-eye-shut.png            close-up: the X-in-circle, left eye shut
    07-ep35-face-eye-open.png            the eye-open variant
    08-ep35-gloves-winged-x.png          the glove embroidery
    09-ep35-legs-cutouts.png             trousers, leggings, shoes
    10-cosplay-full.jpg                  the cosplay, for 3D volumes
  diagramm/
    01-ch599-firing.png
    02-ep34-scope-dial.png               the dial and scope close-up
    03-ep35-aim-pose.png                 stance and the eye at the scope
    04-ep35-muzzle-cross.png             the + muzzle brake
    05-ep35-barrel-severed.png           Daruma-san ga Koronda aftermath
    06-cosplay-rifle.jpg
  jilliel/
    01-ch646-reveal.png
    02-ep35-full-front.png               wings, cocoon, halo (colours)
    03-ep35-wings-holes-close.png        count the holes
    04-ep36-side.png                     wing roots, float height
    05-ep36-face-tattoo.png              the new tattoo, covered mouth
    06-ep36-wing-volley.png              the shots from the holes
    07-bbs-6star-card.png                Brave Souls card
  owl/
    01-ch650-revival.png
    02-ep37-full.png                     neck, legs, arms, wings, halo
    03-ep37-head-close.png               owl disc, beak, slicked hair
    04-ep37-halo-spikes.png
    05-ep37-legs-centaur.png             how the "centaur" legs are built
    06-ep37-sabaki-chop.png              the chopping gesture
    07-anime-vs-manga-compare.png
    08-ch654-broken-halo.png             the defeat state
  trompete/
    01-ch653-fist-at-beak.png
    02-ep37-trumpet-overhead.png         the trumpet and its wing, scale against him
    03-ep37-blast.png
    04-ep37-reflected.png                Hakkyōken throws it back
    05-ch654-remnant-birds.png           optional: the bird remnants
```

## 9. What could not be determined (needs the pictures)

1. The **bicorne's orientation** and size; the **cloak's length** and collar; the shirt's colour; how the leggings attach.
2. **Diagramm's length** relative to him (the 2.0 m in §3.2 is a guess), where the dial sits, and whether the **fur
   wrapping** and the **winged stock** are real (one AI-written source only).
3. **Jilliel's wing shape** and **colour** in the anime (green vs gold: the sources conflict), the halo's position and
   pattern, the new tattoo's shape, whether his hair shows.
4. The owl form's **leg construction** ("centaur" from lengthened shoes), the neck's proportions, the anime's hair, and
   whether any clothing remains.
5. Whether the Brave Souls "Resurrection" card is the owl form.
6. **Palette decisions for the user** (not research questions): Jilliel's green would be a fourth hue (STYLE_STORM §A.2
   allows FIRE, REIATSU, BLOOD only), and a saturated owl-form gold would collide with Kenpachi's REIATSU yellow. The
   sheet proposes muted values (S ≤ 0.45) for both, as Senjumaru's gold and Ichigo's hair were handled.
