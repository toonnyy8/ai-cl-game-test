# Zaraki Kenpachi: every visual form, for the low-poly procedural rebuild

Research date 2026-10-08. This extends `docs/research/tybw-characters/notes/kenpachi_bankai.md`, which covers
the Bankai's story, its cost and how other games handled it. Nothing from that note is repeated here except
where it is corrected (see §6 and §8).

## 0. Method and sources

**Access problems.**
- WebFetch failed on every host (DNS `ENOTFOUND`, including en.wikipedia.org), so it could not be used at all.
- With `curl`, `bleach.fandom.com/wiki/...` returned HTTP 403.
- The fandom **MediaWiki API** did work: `api.php?action=parse&prop=wikitext` for the text, `prop=imageinfo` for the stills. Every
  "Bleach Wiki" citation below comes from the page's wikitext. The wiki's own footnotes give the manga chapter and page.

**Stills.** I downloaded the wiki's anime screenshots and its manga colour-edition panels and **looked at them myself**, and sampled
colours from them with PIL. They are cited by wiki file name, for example `File:669Kenpachi's Bankai face.png`. Any one can be opened
at `https://bleach.fandom.com/wiki/File:<name>`.

**How much to trust a colour.** The manga colour panels come from the digital colour edition. Hex values sampled from those are
reasonably trustworthy. The TYBW anime grades its fight scenes heavily (purple, red and orange light), so a hex sampled from an anime
frame is a *hue hint*, not a base colour. The recommended model hexes below are my own toon-flat picks [C], anchored on the samples.

**Grades.**
- **[A]**: I verified it in a still myself, or the Bleach Wiki states it with a chapter or page cite.
- **[B]**: a secondary or fan source with no page cite: Moegirl (zh), Anibase, Sportskeeda, a search snippet.
- **[C]**: my inference or estimate.

**Main pages read.**
- Bleach Wiki:
  - [Kenpachi Zaraki](https://bleach.fandom.com/wiki/Kenpachi_Zaraki): Appearance, Equipment, Powers, Zanpakutō, plot
  - [Nozarashi (Zanpakutō spirit)](https://bleach.fandom.com/wiki/Nozarashi_(Zanpakut%C5%8D_spirit))
  - [Ryōdan](https://bleach.fandom.com/wiki/Ry%C5%8Ddan)
  - [I AM THE EDGE (episode)](https://bleach.fandom.com/wiki/I_AM_THE_EDGE_(episode))
  - [The Perfect Crimson (episode)](https://bleach.fandom.com/wiki/The_Perfect_Crimson_(episode))
  - the battle pages [vs Ichigo](https://bleach.fandom.com/wiki/Ichigo_Kurosaki_vs._Kenpachi_Zaraki),
    [vs Nnoitra](https://bleach.fandom.com/wiki/Kenpachi_Zaraki_vs._Nnoitra_Gilga),
    [vs Unohana](https://bleach.fandom.com/wiki/Kenpachi_Zaraki_vs._Retsu_Unohana) and
    [vs Gremmy](https://bleach.fandom.com/wiki/Kenpachi_Zaraki_vs._Gremmy_Thoumeaux)
  - the [Image Gallery](https://bleach.fandom.com/wiki/Kenpachi_Zaraki/Image_Gallery)
  - [Yachiru Kusajishi](https://bleach.fandom.com/wiki/Yachiru_Kusajishi)
- [Moegirl 更木剑八](https://zh.moegirl.org.cn/%E6%9B%B4%E6%9C%A8%E5%89%91%E5%85%AB) (zh)
- [Tamashii S.H.Figuarts Kenpachi (TYBW)](https://tamashiiweb.com/item/14727/)

**Episode numbering.** Wiki file names use the overall episode number: TYBW ep 20 = **Ep386**, TYBW ep 44 = **Ep410**,
Soul Society arc = Ep39, Hueco Mundo = Ep196–202.

---

## 1. Base captain look across eras

### Takeaway
There are three base looks.

| Era | Hair | Eyepatch | Haori | Extras |
|---|---|---|---|---|
| (a) Soul Society | stiff needle spikes, a brass bell on each tip | ornate, gold-trimmed, strap / chain harness | white, ragged | black choker |
| (b) Arrancar | same spikes and bells | plain, with straps | white, ragged; the shihakusho sleeves get torn off in fights | — |
| (c) TYBW | long, loose and wild, spiky crown, **no bells** | **strapless** patch with a grey rim | sleeveless-looking white haori over a black kosode open to the navel | white obi bow |

The haori is destroyed in the Gremmy fight. Against Pernida and Gerard he wears only the black shihakusho.

Constant across every era:
- 202 cm, a long-faced and lanky-muscular build.
- A thin scar from forehead to jaw through his **left** eye.
- The eyepatch on his **right** eye.

### Findings
**Body**
- **Height and weight.** 202 cm and 90 kg, from the Vol. 13 profile [A, [wiki infobox](https://bleach.fandom.com/wiki/Kenpachi_Zaraki)]. Moegirl
  gives 108 kg [B, uncited]. Unresolved, and irrelevant for a mesh.
- **Build and face** [A, wiki Appearance]:
  - "very tall, muscular", "long face with high cheekbones, enlarged canine teeth, pronounced, hairless brow ridges";
  - gray eyes (Moegirl says black-brown, and tags him 三白眼, small irises);
  - "stringy black hair reaching past his shoulders".
- **Scar** [A, wiki; seen in `Ep199KenpachiOpt3`, `Ep386KenpachiProfile`]:
  - "a long, thin scar running down the left side of his face and eye", inflicted by Unohana when he was a child;
  - in the stills it runs from above the left brow, straight down through the (intact) left eye, past the cheek to the jaw line;
  - the eye itself is unharmed.

**Clothing**
- **Shihakushō:** standard black, with "white bandages across his midsection" [A, wiki]. In the anime that midsection reads as a
  **white obi tied in a bow at the front** (`Ep39KenpachiZanpakuto`, `Ep371KenpachiArrives`). The kosode is worn open in a deep V,
  showing pecs and abs (`Ep201KenpachiProfile`, `Ep371KenpachiArrives`) [A].
- **Haori: sleeves or no sleeves?** The sources conflict.
  - The Bleach Wiki: "a **short-sleeved** captain's haori (which he took from the previous captain after defeating him), with ragged
    ends on the sleeves and back flap" [A, cites anime ep 75].
  - Moegirl: 「身穿**无袖**的队长羽织，羽织尾端为碎锯齿状」, a sleeveless haori with a sawtooth hem [B].
  - The stills:
    - `Ep201KenpachiProfile` (Arrancar): a torn, very short white sleeve-cap at the shoulder.
    - `312Kenpachi attempts` (manga colour, after Nnoitra): the haori is clearly **sleeveless**, with ragged armholes and bare arms.
      His kosode sleeves had been torn off as well.
    - `Ep371KenpachiArrives` (TYBW ep 5): the white panels cover only the torso, and the arms show the full black kosode sleeves.
      It reads as **sleeveless**.
  - [C] Model it **sleeveless** (or as a 2–3 cm torn cap), with a ragged sawtooth hem and ragged armholes. That matches every era
    visually and what the repo's art already does.
- **Haori hem:** sawtooth tatters, plus a few **round holes** near the hem (`Ep39KenpachiZanpakuto`) [A]. The 11th Division mark
  (十一 in a diamond) is on the back (`312Kenpachi attempts`) [A].
- **Haori lost** [A, wiki battle pages]:
  - he rips his "tattered haori" off after killing Nnoitra (ch 312);
  - Yamamoto scolds him for losing it in the Fake Karakura arc (ch 423);
  - in TYBW it is "destroyed" by Gremmy's clone explosion (ch 578 pp 9–13).
- **Choker:** "He also wore a black choker necklace. Later, he removed the choker" (early Soul Society arc) [A]. It is visible in
  `65Kenpachi profile` as a dark band.

**Hair and bells (eras a, b)**
- Stiff strands, each tipped with a small bell; he sets them with soap [A, wiki Appearance and Trivia].
- **Bell count: no canon number.**
  - Anibase says **11** [B, search snippet, [anibase](https://anibase.net/en/character/ma0kj/Kenpachi-Zaraki)]; Moegirl says 「十束左右」, about ten [B].
  - `Ep199KenpachiOpt3` shows 8 belled spikes inside the frame, with ~3 more cropped above the frame. So **≈ 11** total is
    consistent [A visual / C count].
- **Spike shape:**
  - Manga colour `65Kenpachi profile`: thin, needle-like, tapering spikes radiating from the crown and back of the head.
  - Anime `Ep199`: thicker cones, ~25–40 cm long at his scale.
- **Bells:** tiny brass spheres, about a fingertip in size. Sampled `#61543F`–`#746F63` in shadow on the manga colour page; the
  anime draws them as tiny red-brown dots [A].
- **Bells gone in TYBW** [A, wiki]: "17 months after Aizen's defeat, Zaraki's hair grew to mid-back and no longer has the bells
  in it." This is from the Fullbring arc on (ch 460, 469; the Vol. 53 sketch).

**Eyepatch** (on the right eye, his right, i.e. the viewer's left when facing him) [A, wiki]:
- **Soul Society arc:** "more elegant, having a **gold-like lining and a chain** as one of the straps" (`65Kenpachi profile`: a
  large black wrap-around plate with a gold rim and a strap harness over the crown).
- **Later in that arc and in the Arrancar arc:** "normal straps". `Ep199` shows one strap running diagonally up across the
  forehead into the hair.
- **TYBW:** "a single piece with **no straps and a grey outline**" (ch 460 p11, ch 469). `Ep386KenpachiProfile` shows a rounded
  hexagonal black plate with a light grey rim, stuck to the face [A].
- **Inside the patch:** "five small mouths and eyes", made by the 12th Division (`113Kenpachi's eyepatch`: small white eyes and
  toothy red mouths on black) [A]. That is a prop detail.

**Sealed sword carry**
- As a wanderer he carried it on a rope across his back; as a Shinigami he wears it "at the left of his waist under his sash"
  [A, wiki].
- In the anime he mostly rests it bare over his shoulder (`Ep386KenpachiProfile`, `Ep399KenpachiAppearsMayuri`) [A].
- The TYBW Figuarts includes a sheath at the waist [B, Tamashii].

**TYBW hair**
- Long, loose, wild black hair to mid-back, with a spiky, upswept crown and fringe-less temples [A, wiki + stills `Ep376`,
  `Ep386`, `Ep410`].
- In motion it streams behind like a mane (`669Kenpachi's Bankai`, `Ep410KenpachiArmTears`).

**Yachiru**
- "often latched onto the back of her captain ... **just over his left shoulder**" [A, [Yachiru page](https://bleach.fandom.com/wiki/Yachiru_Kusajishi)].
  She is 109 cm.
- In the Hueco Mundo arc she "pops out of his haori" [A].
- She vanishes in TYBW (ch 579) and comes back only as Nozarashi's form (ch 668) [A].
- **Relevance:** none for a TYBW-era fighter. At most a cinematic or vision cameo (§6). [C]

### Model checklist (base, TYBW default)
- Height 2.02 m. Head ≈ 0.25 m (≈ 8 heads tall). Long neck. Broad shoulders (≈ 0.55 m) over a narrow waist. Long, ropey arms.
- Skin: base `#D9B49A`, shadow `#A47F68` [C]. Samples: anime `#C4A08F`–`#DCBBA6`, manga colour `#EBD1BA`.
- Face:
  - a long wedge jaw;
  - a heavy brow box;
  - a scar strip (1 cm wide, dark `#5A3A30`) on the **left** side, from brow to jaw, crossing the left eye;
  - small grey irises;
  - a wide, toothy grin option.
- Hair, black `#1A1A22` [C]:
  - a crown of 6–8 upswept spiky cones;
  - a long back mane, several flat wedge panels to mid-back, ragged ends.
  - **No bells** (TYBW).
- Era variant (Soul Society / Arrancar): about 11 radial needle cones, 0.3–0.4 m, each tipped with a 3 cm brass sphere
  (`#B39A55`, shadow `#6A5A3E`) [C], plus a black choker band (Soul Society only).
- Eyepatch (optional; the repo's user ruling is "no eyepatch in any form"):
  - a flat rounded-hex plate on the right eye, black `#111114` with a grey rim `#8A8A90`, strapless (TYBW);
  - Soul Society variant: a gold rim `#B89A50` and a strap over the crown.
- Clothing:
  - a black kosode (`#18181C`) open in a deep V to the navel;
  - a white obi with a front bow knot (`#EDEDED`);
  - black hakama;
  - a white haori (`#ECECEC`, shadow `#BFC3CC`), sleeveless, ragged armholes, sawtooth hem at knee to shin, 2–3 round holes near
    the hem, the 十一 diamond on the back.
- Post-Gremmy variant (vs Pernida / Gerard): no haori; black shihakusho only.

---

## 2. Eyepatch removed: the visual cue

### Takeaway
Taking off the eyepatch reveals an **intact right eye**. His reiatsu spikes into a towering column. When he pushes it, the aura
takes the shape of a **giant fanged skull** above and behind him.
- **Anime:** the aura is **pale yellow / yellow-green**.
- **Manga colour edition:** the skull is **pale violet / lavender**. This is a manga-vs-anime colour split.

His body does not change: no eye glow, no new marks.

### Findings
**The three removals**
- **Vs Ichigo (ch 112 pp 18–19, ch 113):**
  - He "removes his eyepatch, revealing an intact right eye"; his "spiritual power skyrockets".
  - He casually flicks the sword and cuts through the base of a building.
  - Then he "exerts his Reiatsu in a **skull-shaped aura**" while Ichigo answers with a Hollow-mask aura (ch 113 pp 10–12)
    [A, [vs Ichigo](https://bleach.fandom.com/wiki/Ichigo_Kurosaki_vs._Kenpachi_Zaraki)].
- **Vs Nnoitra (ch 308 pp 17–19):**
  - The eyepatch is **knocked off** by Nnoitra's grasping hand ("rips off a grinning Zaraki's eyepatch").
  - His reiatsu surges and he slashes Nnoitra down the length of his body.
  - Later Nnoitra feels "a monstrous and intense Reiatsu enveloping him in the shape of a **demonic skull**" (ch 310 pp 5–10)
    [A, [vs Nnoitra](https://bleach.fandom.com/wiki/Kenpachi_Zaraki_vs._Nnoitra_Gilga)].
- **TYBW:** he removes it at the start of the Unohana fight (ch 524). Against Gerard, Hitsugaya notes "he has already removed his
  eyepatch" (ch 668, ep 410).

  Against **Gremmy** he wins with the Shikai "**without ever taking off his eyepatch**" (ch 573–578) [A, wiki Powers]. The anime
  TYBW ep 20 stills show the patch on (`Ep386KenpachiProfile`, `Ep386KenpachiZarakiProfile`).

**Aura colour**
- Wiki: "When unleashing a strong enough surge of energy, it appears **yellow** in color, sometimes taking the form of a skull" (cites
  ch 113 pp 3–4 and 12) [A].
- Anime stills:
  - `Ep39KenpachiRemovesEyePatch`: a column of pale yellow light filling the corridor, sample `#FBFDB6`.
  - `Ep39KenpachiReiatsuSkull`: a huge skull with hollow black eye and nose sockets and a row of jagged broken teeth, in pale
    yellow-white, sample `#FCFEC4` aura and `#BFBFA3` skull midtone.
  - `Ep202KenpachiKillsNnoitra`: a yellow aura sheet behind the Ryōdan.
- **Conflict:** `113Kenpachi exerts` (manga colour edition, ch 113) colours the skull **lavender / violet** with dark sockets.
  The wiki's "yellow" matches the anime. [A, both visual]

**Ichigo vs Nnoitra framing**
- Ichigo: a voluntary removal to honour an equal, then the skull aura opposed to Ichigo's mask aura.
- Nnoitra: an involuntary removal (patch torn off), then a grin and an immediate cut.
- Nnoitra's own eyepatch hides a Hollow hole, so the two eyepatches are mirrored on purpose [A, battle page].

**Skull scale**
- The skull is several times his height and sits above and behind him, with its jaw at about chest level (`Ep39KenpachiReiatsuSkull`,
  `113Kenpachi exerts`) [A visual]. [C] Read it as about 6–8 m tall.

### Model checklist
- Eyepatch prop: detachable, 20–30 frames for the pull. The removed right eye is normal (grey iris).
- Aura column: an additive cylinder or cone, about 1.5× his height. Anime palette: core `#FFFFE0`, body `#F2F08A`, rim `#C8D24A`.
  [C, anchored on the samples]
- Skull: a billboard or low-poly skull of 6–8 m, with:
  - two hollow eye sockets (wedge-shaped, angled like a frown);
  - an inverted-V nose hole;
  - an upper row of ~8 jagged blocky teeth, broken and uneven.

  Draw it translucent and centred above and behind him.
- Optional manga colourway: lavender `#B9A6D8` with indigo sockets `#2A2240`.
- No change to his eyes, skin or clothes.

---

## 3. Kendō / two-handed grip

### Takeaway
His default is **one-handed** with the off hand free. He is ambidextrous, and the right hand is the dominant sword hand: it is the
arm lost to Pernida and burst by the Bankai.

**Two hands** is a rare "serious" tell:
- **Ryōdan** 両断 against Nnoitra: the left hand joins the right on the hilt, then a straight overhead downward cut that bisects.
- A moment against Ichigo.
- Against Pernida.

Unohana mocks his one-handed style, and the anime shows him two-handed in their clashes.

### Findings
**One hand is the norm**
- "always fight with one hand free, only using both hands when he feels not doing so would lead to his defeat, such as against
  Nnoitra and momentarily Ichigo" (ch 112 p9; ch 636 p10) [A, wiki Powers].

**Ryōdan**
- Wiki: "Grasping their sword with both hands, the practitioner brings it down with enough force to cut an opponent in half down the
  middle" (Character Book UNMASKED p153) [A, [Ryōdan](https://bleach.fandom.com/wiki/Ry%C5%8Ddan)].
- The scene (ch 311 pp 17–19, ch 312):
  - he "grips his Zanpakutō's handle with his **left hand**, and performs Ryōdan, a powerful downward slash";
  - the cut "travels across the desert" as a sand plume;
  - afterwards he "stands with both hands on his Zanpakutō" [A, vs Nnoitra page].
- `Ep202KenpachiKillsNnoitra`: follow-through low, both hands at the hip, kosode sleeves torn off, bare arms, a yellow aura curtain
  behind [A visual].

**Kendō background**
- Yamamoto taught him kendō for **one day** before Central 46 stopped it [A]. Moegirl calls Ryōdan 「剑道·两断」 [B].

**Unohana (ch 524)**
- She calls him weak: "those who only fight with one hand, without using the other for anything else, do not look like they enjoy
  fighting" [A].
- `Ep376KenpachiUnohanaClash` shows him gripping the long hilt with both hands in a blade-to-blade clash [A visual, medium: dark
  frame].
- No text says he switches to kendō there.

### Model checklist
- Grip rig: right-hand-only by default (a free left hand for punches, grabs and bites). The left-hand IK target slides onto the hilt
  below the right hand for the two-hand stance.
- Ryōdan pose: jōdan (sword overhead, both hands) → straight vertical cut to below the waist. The body stays square with a slight
  forward lunge, and the head stays level.
- The torn-sleeve variant (bare arms, as in the Nnoitra fight) fits the "serious" state.

---

## 4. After Unohana (TYBW): any look change?

### Takeaway
Killing Unohana changes **nothing on his body**:
- same long hair, same scar, same strapless patch, same haori;
- the change is internal: limiters gone, Nozarashi's voice heard.

What does change across TYBW is costume damage:
- the **haori is destroyed** vs Gremmy (ch 578);
- from Pernida on he is in black shihakusho only;
- the **right arm** is lost (ch 636), regrown in Mayuri's capsule (ch 667), and burst again by the Bankai (ch 670).

### Findings
**The Unohana fight**
- He removes the eyepatch "from the start" (ch 524 pp 4–8) [A].
- After: "Zaraki pulls back his sword and drops it ... he hears a voice calling out to him ... from his Zanpakutō" (ch 527 pp 1–9) [A].
- No visual change is reported. The Gremmy stills (`Ep386KenpachiProfile`) match the pre-Unohana TYBW look [A visual].

**Costume and arm, step by step**
- **Gremmy:** he "emerges from the cloud of smoke with only moderate burns and his haori destroyed" (ch 578 pp 9–13) [A].
- **Pernida:**
  - his right arm is warped by The Compulsory, so he "immediately rips it off" (ch 636);
  - stills `Ep399KenpachiAppearsMayuri` and `Ep400KenpachiRipsArm` show **no haori**, black shihakusho, **eyepatch still on**, long
    hair, the sealed sword with a spiky guard [A visual].
- **The capsule:** "Zaraki's missing arm is restored and [he] breaks out of the capsule" (ch 667 pp 1–2) [A].
- **Gerard:**
  - `667Kenpachi withstands` (manga colour) and `Ep409KenpachiWithstandsStomp`: black kosode wide open, white obi, no haori,
    **barefoot** in the ep 409 still [A visual];
  - the eyepatch is already off (ch 668).

**Shunpo**
- He "developed it to some degree following his battle with Unohana" [A]. That is a movement cue, not a look.

### Model checklist
- No new mesh.
- Optional "late TYBW" costume: remove the haori; keep the black kosode open to the navel, the white obi and the hakama; optional
  bare feet.
- Optional: a stump or regrown-arm flag is not needed outside the Bankai (§6).

---

## 5. Shikai Nozarashi (「呑め」)

### Takeaway
Nozarashi becomes a **giant crescent cleaver-axe on a long, cloth-wrapped haft**:
- a long, dark blade whose **convex upper edge** (the cutting edge, with a pale bevel band) sweeps into a raked point;
- a squared-off back end capped by a **box-shaped brass ferrule**;
- a **long tassel** hanging from a hole in that cap. The tassel is **dark green** in the manga colour edition and red or dark in the
  anime: a conflict.

The wiki says it is "twice his size": [C] a weapon of about 3.5–4 m, with a blade of about 2.2–2.5 m and about 0.7 m deep.

He carries it **one-handed** and rests it on his shoulder. His body does not change in Shikai, and against Gremmy he even kept the
eyepatch on.

### Findings
**Wiki description** [A, wiki Zanpakutō; ch 577 pp 16–17]
- "an **axe/war cleaver hybrid twice his size** with a long, cloth-wrapped handle. The top of the blade has a **brass cover** with a
  **green tassel** attached to the backside."
- The release is 呑め (ch 577 p11). He leaps at the meteor, releases, and "cuts completely through the center of the meteor, splitting
  it in half", then stands amid the falling chunks (ch 577 pp 7–17).

**Anime ep 20, "I AM THE EDGE" (Ep386)** [A, [episode page](https://bleach.fandom.com/wiki/I_AM_THE_EDGE_(episode))]
- He "stands with Nozarashi, a massive war cleaver with a **bandaged hilt** and a large **red tassel** at the corner of the blade,
  **resting on his shoulder**".
- Anime-added detail: "Zaraki being depicted as **a young boy** while cutting through the meteor" (a flash overlay), and Yachiru's
  flashback.
- Sportskeeda's ep 20 article says "brass cover" and a "**green** tussle [tassel]" [B, search snippet,
  [Sportskeeda](https://sportskeeda.com/anime/is-nozarashi-kenpachi-zaraki-s-shikai-bleach-tybw-explained)].

**Moegirl** [B]: 「巨大刀身的菜刀状，近刀柄处呈现弧状线条，末段洞口坠有长流苏的长柄」. Translation:
- a giant kitchen-cleaver-shaped blade;
- an arced line near the haft;
- **a hole at the end from which a long tassel hangs**;
- a long handle.

**What the stills show** [A visual]
- **Manga colour, `577Kenpachi's Shikai, Nozarashi`:**
  - **Blade:** a solid **black** body. The long upper edge is convex with a white-silver bevel band; the lower edge is nearly
    straight, rising slightly to the tip. Together they make a curved, raked point like a scimitar or crescent cleaver tip.
  - **Back end:** square, sheathed in a **brass box cap**, sample `#BFB178`. The cap covers the top-rear corner, with a small step
    or notch in its outline.
  - **Tassel:** a thick, **dark green** tassel (`#2E3B2D`), knotted at the cap's lower rear corner. Long strands fall to about the
    blade's depth.
  - **Haft:** a long pole wrapped in diagonal tan / off-white cloth binding. He holds it in **one hand** low near the haft's end,
    with the blade arcing over his head.
  - **Costume:** the haori with a ragged hem is visible (the Gremmy fight).
- **Anime, `Ep386KenpachiShikaiNozarashi` (under orange meteor light):**
  - **Blade:** the same silhouette, with a rough, chipped-looking edge highlight and a dark blade body.
  - **Cap:** reads as dark brown, not bright brass.
  - **Tassel:** a large **dark maroon / brown** tassel hanging from the cap's corner, sampled near-black (`#14070A`) in that light.
  - **Haft:** wrapped like rope, red-brown in that light, with a loose cord loop hanging. One hand.
- **Manga colour, `667Kenpachi and Gerard clash`:** the same weapon against Gerard: black blade, brass cap, green tassel, swung
  one-handed from the side.

**Proportions** [C, measured off `577...` with head ≈ 0.25 m as the scale]
- Blade, tip to cap: ≈ 8–10 head-heights, so **2.2–2.5 m**.
- Maximum depth near the cap: ≈ **0.7–0.8 m**.
- Cap: ≈ 0.35 m along the blade, covering the full depth.
- Haft: ≥ 1.2–1.6 m showing.
- Total ≈ 3.5–4 m, which agrees with "twice his size".
- **Where the haft joins the head is not clear** in any still found. Both the manga panel and the anime frame are consistent with the
  haft entering the **straight (lower / spine) edge toward the rear third, under the cap**, like a glaive or guandao. [C, medium-low]

**Changes to him in Shikai**
- None reported: no eye, skin or aura change.
- The anime gives his figure strong red rim-lighting in TYBW (a series-wide grading choice, visible already in the sealed stills)
  [A visual]. The meteor sequence is bathed in yellow-orange light (`Ep386MeteorDestroyed`: the meteor bursts into a yellow-white
  starburst). Neither is a form trait.
- The eyepatch stays **on** against Gremmy [A]; it is off against Gerard [A].

**Swing**
- **Meteor:** a single cut through the centre after a leap. The wiki does not say how many hands. The rest pose is the cleaver on
  the shoulder, one hand on the haft [A].
- **Vs Gerard (ep 410):**
  - he "run[s] directly up the flat side of the blade and leap[s] off of Gerard's fist to slash at the latter's face";
  - he "smacks Nozarashi into Hitsugaya" [A, Perfect Crimson episode page].

  It is used like a club as much as a blade.

### Model checklist (Shikai Nozarashi)
- **Blade:** an extruded 2D profile, ≈ 2.4 m long and 0.75 m deep at the rear, tapering to a raked point, ~6 cm thick at the spine
  and 1 cm at the edge.
  - Upper (cutting) edge: a convex arc, 4–6 segments.
  - Lower edge: near-straight, curving up only in the last 20 % into the tip.
- **Colours** [C]:
  - blade body near-black gunmetal `#22232A`;
  - edge bevel band (~8 cm) pale steel `#D8DCE2` with a few chip notches;
  - brass cap `#BFA868`, shadow `#7A6A3C`;
  - tassel: manga `#2F4A35` (dark green) or anime `#6A1E1E` (dark red). Pick one; see the conflicts in §8.
- **Cap:** a box 0.35 × 0.78 × 0.10 m over the rear end, with a stepped notch on its outer edge.
- **Tassel:** a small cord ring through a hole in the cap's lower rear corner, then a 0.5–0.7 m bundle of 5–8 thin cones or ribbons.
  Give it secondary motion.
- **Haft:** a cylinder of 1.5 m and 4 cm diameter, wrapped in off-white `#D9CBB0` with diagonal dark binding lines. Optional loose cord
  loop. It joins the spine near the rear third.
- **Hold:** one hand (right) near the haft's butt; rest pose on the right shoulder with the blade up and behind. The body is
  unchanged from the base look.
- **Release cue:** the sealed katana "inflates" into the cleaver. Keep the yellow reiatsu for NOMIHOSE (it is already in the build).

---

## 6. Bankai (red oni): visual detail only

Read this together with the existing note §1 (story, cost) and §4 (design hooks).

### Takeaway
- Whole-body **crimson / brick-red skin**.
- **Two short, conical horns** rising straight up from the forehead at the hairline, **the same red as the skin**.
- **Black war-paint markings**: two flame / tear-streak bands from the forehead down through the eyes and onto the cheeks.
- **Blank white, irisless eyes**.
- A huge grin of **flat, square teeth** (not fangs).
- The **scar stays**, the **hair stays black** and becomes a wild mane.
- The upper shihakusho is reduced to black rags around a bare red torso and arms.

The posture opens **on all fours** like a beast, then a hunched, forward-leaning stance. The sword becomes a **shorter, jagged,
broken cleaver** on the same long wrapped haft.

**Anime:** the activation is a massive **yellow** reiatsu pillar, not red. The ground turns to magma (anime-only). His body steams.

### Findings
**Skin**
- Wiki: "skin turns red, and he gains **multiple black markings across his face** as well as **horns on his forehead**, causing him
  to resemble an oni" (ch 669 pp 2–5; ep 410) [A].
- Manga colour samples: lit `#BF7C73`, mid `#A95247`, shadow `#743C33` (`669Kenpachi's Bankai face`, `669Kenpachi's Bankai`).
  The tone is brick or terracotta red, not a saturated spot red.
- Anime samples under purple grading: `#5B1430` (chest), so the anime hue is a deeper crimson-magenta.

**Horns**
- Moegirl: 「额头正上方长出两根角」, two horns growing from directly above the forehead [B].
- In the manga colour face close-up they are:
  - **two**, rising from the upper forehead at the hairline, roughly above each eye's inner half;
  - broad-based, tapering to a point, curving **up and slightly outward**;
  - skin-coloured, with no bone tint.
- In profile (`670Kenpachi loses his arm`, `Ep410KenpachiArmTears`) they are **short**: about the height of the forehead, pointing
  up and slightly back [A visual].
- The repo's current horns use a darker `#6E302C`. Canon is skin-red; a darker shade is acceptable only as an ink contrast choice.

**Face markings**
- Moegirl: 「从额头到眼睛下方有两条黑色的纹路」, two black lines from the forehead to under the eyes [B].
- In the stills [A visual]:
  - forehead: a black flame / trident shape between and above the brows;
  - each eye: a black band surrounding it that drips down like a tear-streak over the cheek;
  - additional dark stripes along the cheekbones and jaw (anime `Ep410KenpachiBankaiFace` shows heavier banding);
  - there are no body markings, only muscle shading.

**Eyes**
- Pure white, irisless almond slits with no pupil (manga colour and anime) [A visual]. This confirms Naledir's "irises vanish"
  (existing note).
- Pupil-less eyes are standard berserker shorthand, so this reads as intentional.

**Mouth**
- A face-wide rictus grin, both rows of large **flat, square teeth**, no visible fangs (`669 face`, `Ep410KenpachiBankaiFace`)
  [A visual]. Moegirl and fan pages say "fangs" or "jagged" [B]; the stills say otherwise.
- He bites through Gerard's knuckle and tears the arm off with his teeth [A].

**Scar**
- Still visible: a vertical stitched line through the **left** eye in `669Kenpachi's Bankai face` [A visual].

**Hair**
- Still black, long and wild. It spikes up off the crown and flows back as a mane (`669Kenpachi's Bankai`, `Ep410KenpachiBankai`)
  [A visual].

**Clothes**
- **Manga** (`669Kenpachi's Bankai`, `670...`): the shihakusho is shredded into **black, flame-like tatters** that blow around his
  shoulders and back like a cape; the arms are bare and red.
- **Anime** (`Ep410KenpachiBankai`, `Ep410KenpachiTopplesGerard`):
  - a **bare red torso**, ribs and abs drawn hard;
  - the white obi still tied;
  - black hakama;
  - black rags flaring behind;
  - he appears **barefoot**. [A visual]

**Posture**
- **Activation:** crouched **on all fours**. One hand flat on the cracked ground, the other gripping the haft of the broken
  cleaver, which lies along the ground. Head down, blood dripping (`669Kenpachi's Bankai`; the anime copies it in
  `Ep410KenpachiBankaiActivated`, with the ground glowing as magma).
- **Then:** a hunched stance, shoulders forward, arms hanging long, the grin (`Ep410KenpachiBankai`).
- **Anime:** "a **steaming** Kenpachi"; he "roars angrily" and leaps "dozens of meters backward" [A, episode page].
- He cannot tell friend from foe; he attacks Hitsugaya and Byakuya (ch 670 p4) [A, wiki Weaknesses].

**Activation aura (anime)**
- "several blocks of the branch are engulfed in a massive **pillar of yellow Reiatsu** visible from the rest of Wahrwelt that produces
  a powerful wind", and the ground beneath him "burned and reduced to magma" (anime-added) [A, Perfect Crimson episode page].
- So the anime keeps Kenpachi's **yellow**. **Crimson** is the *skin*, not the aura.
- The manga is black and white; the colour-edition panel shows a white shockwave and cracked stone.
- **This corrects the existing note's "red reiatsu shockwave"**, which was a design suggestion [G], not canon.

**Broken cleaver**
- Wiki: "an altered version of its Shikai state, with a **shorter, more jagged blade resembling a rough cleaver**" [A].
- Moegirl: 「刀身变成断刀」, the blade becomes a broken sword [B].
- Naledir (existing note): its hilt is "reminiscent of Ichigo's first Zangetsu", i.e. a long bandage-wrapped grip with no guard.
- Stills [A visual]:
  - **Manga** (`669Kenpachi's Bankai`): a broad, flat **black** head with a squared back and a ragged broken top edge; a shorter
    blade than the Shikai, about 1–1.2 m [C].
  - **Anime** (`Ep410KenpachiBankaiActivated`, `Ep410KenpachiSlashesGerard`): a pale steel blade with the convex edge kept and
    **hooked, jagged teeth / broken spurs along the back**, like a snapped cleaver.
  - **Haft:** still long, **white-wrapped** with dark diagonal binding (anime). In the manga it is tan with binding
    (`670Kenpachi loses his arm`).
  - **No brass cap or tassel** in any Bankai still [A visual; absence, medium].

**Arm burst**
- **Manga** (`670Kenpachi loses his arm`, ch 670 p12): the **right** arm, raised overhead and still gripping the haft, **bursts at
  the upper arm / elbow** in a radial spray of dark-red blood. The hand stays on the haft.
- **Anime:** "Kenpachi's right arm **breaks off at the elbow** in a shower of blood" mid-leap. After Gerard slams him he is left "with
  his right arm completely severed". He then grabs Gerard's left foot with his **remaining hand** (left) [A, episode page; still
  `Ep410KenpachiArmTears`: the forearm and hand fly off still holding the haft, red tatters around the stump].
- Anime-only change: in the manga, "Kenpachi's severed arm and sword are visible after Gerard incapacitates him"; the anime hides
  them behind Hoffnung [A].

**The Nozarashi / Yachiru vision (anime)**
- Yachiru in her black shihakusho, crouching in the **Kusajishi forest** (`Ep410NozarashiHelpsKenpachi`).
- She "transfer[s] an energy into Kenpachi's **right hand**"; the manga's wording is "energy begins flowing down Zaraki's arm from
  where she touched him" [A].
- Kubo's Klub Outside Q&A #151, quoted on the wiki: Yachiru is the Bankai-side manifestation; the true spirit resembles an
  **adult woman** [A-, via wiki].

### Model checklist (Bankai)
- **Skin swap** [C, anchored on the manga colour samples; keep S moderate for the ink look]: base `#A94E42`, shadow `#6E2E28`,
  highlight `#C9786A`. The anime-leaning alternative is `#8E2436` / `#5A1424`.
- **Horns:** 2 cones, base radius ≈ 3 cm, length ≈ 9–12 cm, skin-coloured (optionally 15 % darker).
  - Placement: on the upper forehead at the hairline, ≈ 4 cm either side of the midline.
  - Angle: up and slightly outward (±15°), tips a little back.
- **Markings:** black decal or geometry strips:
  - (1) a flame / trident shape on the mid-forehead;
  - (2) a ring around each eye continuing as a tear-streak to mid-cheek;
  - (3) 1–2 thin stripes along each cheekbone.
- **Eyes:** flat white `#F4F2EA` almond slits; no iris or pupil.
- **Mouth:** a wide grin plate with two rows of flat white teeth, no fangs.
- **Scar:** kept on the left side.
- **Hair:** the same black mane, with more lift and flare (secondary-motion ribbons).
- **Costume:** bare red torso and arms; black ragged tatters as 4–6 flame-cut flaps over the shoulders and back; white obi; black
  hakama; bare feet.
- **Broken cleaver:** head ≈ 1.1 m long, 0.6 m deep, convex pale-steel edge `#C9CED6`, dark body, a jagged back made of 3–4 hooked
  spurs and a ragged snapped top. No brass cap, no tassel. Haft 1.5 m, white-wrapped `#E8E4DA` with dark diagonal binding.
- **Poses:** an activation crouch on all fours (head down, haft dragging); then a hunched stance (spine forward 20–25°, arms low);
  a bite grab; an uppercut; one vertical bisecting cleave.
- **VFX:**
  - activation: a **yellow** pillar (reuse NOMIHOSE yellow) plus a ground-crack decal glowing orange-red, plus steam puffs off his
    body;
  - arm burst: the right arm separates at the elbow, a radial dark-red spray (`#7A0A14` core, `#D0101C` droplets), then a stump
    with red tatters.
- **After the burst:** a one-armed variant (right arm gone at or above the elbow); the left hand is free for grabs.

---

## 7. Sealed zanpakutō (unnamed / "Nozarashi" in sealed form)

### Takeaway
- A **nodachi-length**, slightly curved, narrow katana with a heavily **chipped, notched edge**.
- A **long, narrow tsuba** shaped like a serrated elliptical bicone (it reads as a spiky spindle).
- A white hilt and braid, mostly wrapped in **white bandages**, sometimes with a trailing bandage tail.
- It has a brown saya, also bandaged, but he usually carries it bare over his shoulder.

### Findings
**Wiki** [A, ch 120 p9 and ch 529 / 525]
- "much longer than most Zanpakutō, roughly the size of a **nodachi**, with a relatively narrow, but long tsuba shaped like a
  **serrated, eliptical bicone**. The hilt and braid are both white, though they are mostly wrapped in **white bandages**, as is his
  sword's **brown saya**."
- "the blade is chipped and worn-down upon its edge", blamed on his disharmony with the sword.
- He took it from a dead Shinigami's asauchi as a boy.

**Moegirl** [B]: 「护手外形为立体多边形，刀身呈现坑洼的锯齿状，刀柄缠着白色布条」, a 3-D polygonal guard, a pitted / sawtooth
blade, a hilt wrapped in white cloth.

**Stills** [A visual]
- `Ep39KenpachiZanpakuto`:
  - a long, gently curved blade, pale steel (sample `#797B8B` in shadow) with **irregular nicks along the whole edge**;
  - a small dark-iron guard (`#494341`) that reads as an elongated spindle;
  - a grey collar (habaki-like) ring;
  - a white bandaged grip, with a long bandage strip trailing from the pommel.
- `Ep400KenpachiRipsArm` (TYBW): the guard is clearly **spiky / star-like** (a ring of jagged points).
- `Ep399KenpachiAppearsMayuri`: he rests the bare blade on his shoulder, with a long white-wrapped grip about 2 hands long.

**Length** [C]
- A nodachi blade is typically 90–100 cm. On him the shoulder-rest frames show a blade at least as long as his arm.
- Estimate: **blade ~1.0 m, grip ~0.32 m, total ~1.35 m**.
- A retail "Lawless Nozarashi" replica lists a 67 cm blade and 104 cm overall [B, search snippet,
  [Syncee](https://syncee.com/product/437886_74012_4925673537618/kenpachi-zarakis-nozarashi-lawless-katana-sword-from-bleach)]. That is
  a generic katana scale and too short for canon.

**Carry**
- As a wanderer: on a rope across his back, over the right shoulder. As a Shinigami: at the left waist under the sash.
- The TYBW Figuarts has the sword with a sheath at the waist [A for the wiki, B for the Figuarts].

### Model checklist (sealed)
- **Blade:** an extruded strip 1.0 m × 3.2 cm × 0.7 cm, with a slight curve (sori ≈ 2 cm).
  - Colour: steel `#9EA3B0`, darker spine `#5E6270`.
  - **Edge chips:** 8–12 irregular V-notches cut into the edge (or a jagged-edge vertex pass).
- **Guard (tsuba):** an elongated bicone of ~16 × 5 cm, 1.5 cm thick, with 6–10 small serration teeth round its rim (a spiky
  spindle), dark iron `#4A4542`.
- **Collar:** a 2 cm ring of grey `#8A8A90`.
- **Grip:** a 0.32 m cylinder, white `#EDEDED`, with diagonal bandage seams. Optional 0.4 m trailing bandage ribbon from the pommel.
- **Saya (optional):** brown `#6B4A30` with white bandage bands; at the left hip, under the obi.
- **Default hold:** right hand only, or resting on the right shoulder with the blade horizontal behind the neck.

---

## 8. Conflicts and corrections (unresolved unless stated)

| Item | Source A | Source B | Note |
|---|---|---|---|
| Haori sleeves | Wiki: short-sleeved with ragged sleeve ends (ep 75) | Moegirl: sleeveless; TYBW stills read sleeveless | Model sleeveless, or a tiny torn cap |
| Bell count | Anibase: 11 | Moegirl: about 10 | Ep199 frame consistent with ≈ 11 |
| Weight | Vol 13: 90 kg | Moegirl: 108 kg | Irrelevant to a mesh |
| Eye colour | Wiki: gray | Moegirl: black-brown | Anime shows small grey irises |
| Skull aura colour | Anime and wiki text: yellow | Manga colour ed. ch 113: lavender | Medium split; pick per style |
| Shikai tassel | Manga colour ed. (ch 577, 667) and Sportskeeda: **green** | Wiki ep 386 page: **red**; frame reads dark maroon | Unresolved; anime vs manga |
| Shikai cap | Manga colour ed.: bright brass `#BFB178` | Anime frame: dark brown (lighting?) | Treat as brass |
| Bankai activation aura | Existing repo note [G]: red | Wiki ep 410 page: yellow pillar | **Canon (anime) = yellow**; correct the note |
| Bankai teeth | Fan pages: fangs / jagged | Manga and anime stills: flat square teeth | Stills win |
| Bankai horn colour | Repo art: darker `#6E302C` | Stills: skin-red | Darker is an ink choice, not canon |
| "No eyepatch in any form: TYBW canon" (repo `ken-art.lisp` comment) | — | TYBW canon has the strapless patch on until he chooses to remove it (on vs Gremmy and Pernida, off vs Unohana and Gerard) | The no-eyepatch rule is the **user's decision**, not canon; the comment overstates canon |

## 9. Gaps
- **Haft-to-head joint:** no clean side-on still was found of the Shikai head's junction with the haft. Get one frame of TYBW ep 20 or
  ep 44 (Gerard clash) to confirm whether the haft meets the spine at the rear third.
- **Measurements:** nothing official for any weapon. Every metre figure is a proportion estimate off panels.
- **Missing panels:**
  - no manga panel of the Bankai cleaver's full outline was viewed;
  - the anime close-up `Ep410KenpachiSlashesGerard` shows only part of it.
- **Hellverse:** the Echoing Jaws of Hell one-shot (2021) look was not checked.
