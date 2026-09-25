# The "Ultimate Ninja Storm" Look: Style Analysis (SOUL DUEL restyle research)

> **風格解析摘要（繁體中文）**
>
> - **問題**：怎樣才會讓人一眼看出是《火影忍者 究極風暴》（CyberConnect2，2008–2023）？SOUL DUEL 的限制是程序產生素材、剛體低面數角色、WebGPU、ECL 的配置預算。在這些限制下，這種風格能重現多少？
> - **證據**：29 個來源。每一條主張標成已驗證 [V]、二手報導 [V2]、推測 [I]。推測的部分必須用參考截圖確認（設計文件的 Phase 0）。
> - **已驗證的關鍵事實**：
>   - CC2 自家部落格（2012）寫明火焰等效果是「一格一格手繪」，因為模擬做出來太寫實 [V]。
>   - CC2 的特效講座：色相最多 3～4 個；特效分主、副、點綴三層；煙轉成雙色；出現與消失要錯開 [V2]。
>   - 殘像模糊：在多邊形上貼一張模糊貼圖來做。另有旋轉背景、「板野馬戲團」式的鏡頭，《究極風暴 4》的奧義還用色差和魚眼 [V2]。
>   - 《鬼滅之刃 火之神血風譚》：角色和背景分開打光、分開調色，角色另有漸層光 [V2]。
>   - 參考實作是 GGXrd 的 GDC 2015 講稿（全文讀過）：以 step 函式決定明暗；閾值可逐頂點偏移；每個角色有自己的光向量；手調法線；「亮色 × 色調」決定陰影色；描邊用反轉外殼；角色採有限動畫 [V]。
> - **十項核心特徵**：
>   1. 角色有墨線；
>   2. 雙色陰影，陰影色經過設計；
>   3. 角色配色飽和，與背景分得開；
>   4. 特效是「畫出來」的硬邊形狀；
>   5. 特效逐格停頓；
>   6. 動畫式模糊與殘像；
>   7. 奧義用誇張的鏡頭語言；
>   8. 閃光與衝擊格；
>   9. 毛筆字標題；
>   10. 背景可讀、會被破壞。
>
>   審查後補上第 0 項：**人物與背景用互補色**。
> - **本質與枝節**：粒子數量、鏡頭光暈、衣服燒起來這類寫實點綴、延遲算圖、多邊形數量都是枝節，不必照做。
> - **限制**：無法看影片，所以畫面上的細節（線寬、邊緣光、衝擊格等）都標為推測 [I]。使用者決定不做參考截圖，改成在設計各階段完成後審查截圖（設計文件 §9）。
>
> **v4 補充：久保帶人／千年血戰篇動畫／Rebirth of Souls（§11）**
> - **久保帶人的畫風**：
>   - 越畫越少用網點灰階，改成純黑對純白 [V2]；
>   - 用留白（余白）讓讀者自己想像 [V2]；
>   - 只用一支毛筆筆和一支 G 筆，刻意留下毛筆的不規則感 [V2]；
>   - 用天空和天氣表現角色的心情 [V2]；
>   - 後期背景極簡，把注意力放在人物剪影和留白上 [V2]。
> - **千年血戰篇動畫**：
>   - 總監督說明第 6 集：山本周圍的火焰是手繪，後方的火焰幾乎都是 3D；殘火太刀用數位做出水墨、炭筆般的質感 [V]；
>   - 山本火焰的段落刻意把聲音拿掉，只留骨頭的聲音 [V]；
>   - 同集的色彩腳本從暖色轉向紫與深藍 [V2]；
>   - 比起舊作，整體改用更暗、更銳利的配色 [V2]。
> - **Rebirth of Souls**（Tamsoft，UE5）：找不到開發者談算圖的資料，只知道玩家認為畫風接近千年血戰篇動畫 [U]。
> - **使用者的美術指示**：冷暗的灰藍底色、突然的全畫面黑白反轉、紅色點綴、墨汁飛濺、漫畫的黑頁回憶風格。這些列為設計輸入，不當作證據。


Research report for SOUL DUEL's restyle. Method: `academic-research-skills:deep-research`, **full
mode, condensed**. The six phases were run as follows: scoping (§0), investigation and source
grading (§1), synthesis (§2 to §6), Devil's Advocate checkpoints (§7), then composition, review and
revision. Review findings are listed in STYLE_STORM_DESIGN.md §13. Date: 2026-09-25.

---

## 0. Phase 1: scoping

**Research question.** Which visual traits make a real-time 3D game read as CyberConnect2's
*Naruto: Ultimate Ninja Storm* series (Storm 1 2008, Storm 2 2010, Generations 2012, Storm 3 2013,
Revolution 2014, Storm 4 2016, Connections 2023)? Which of these traits can a small WebGPU engine
reproduce when it has procedural assets only, rigid low-poly characters and a strict consing
budget?

Sub-questions:
1. How are the characters rendered (shading, lines, colour, faces)?
2. How are the effects built and timed (2D-animated effects in 3D)? This is the core question.
3. How do the stages, lighting, camera and typography support the characters?
4. Which traits are essential and which are incidental?

**Scope.** In scope: published statements by CyberConnect2 (CC2) staff, reports on CC2 talks, and
comparable anime-look 3D productions (Arc System Works, miHoYo, Tango, Byking) where they explain a
technique CC2 only names. Also relevant NPR literature. Out of scope: frame-by-frame analysis of game
footage. This agent cannot watch video, so every claim about how Storm *looks on screen* is marked
INFERRED and must be checked against captures (STYLE_STORM_DESIGN.md, Phase 0).

**Evidence labels** (used inline):
- **[V]** VERIFIED: a primary source was fetched and read in this session (the talk handout, the
  developer's own blog, an interview transcript).
- **[V2]** VERIFIED-SECONDARY: a journalist's or blogger's report of a talk, fetched and read.
  The report is reliable for *what was said*, but details may be lossy.
- **[I]** INFERRED: the author's reasoning, or familiarity with the games from memory. Plausible
  but unconfirmed. **Design decisions that rest on [I] carry a verification step.**
- **[U]** UNVERIFIED: seen only in a search-engine summary. Not used for any design decision.

**Methodology blueprint.** This is qualitative document analysis with a pragmatist paradigm: the
goal is a working design, not a theory. Sources were found by targeted Japanese and English searches
(4Gamer, CC2 blog, gamemakers.jp, GDC Vault, ACM DL, CGWORLD, PlayStation Blog). Each source was
read in full where possible and graded. Themes were coded against sub-questions 1 to 4. Primary
sources were preferred over reports, and reports over forums.

---

## 1. Phase 2: source corpus and grading

| # | Source | Type | Grade | Used for |
|---|---|---|---|---|
| S1 | Matsuyama, H. (2008-06-04). *Q&A: CyberConnect2's Matsuyama on Naruto tech, plans*. Gamasutra/Game Developer. https://www.gamedeveloper.com/game-platforms/q-a-cyberconnect2-s-matsuyama-on-i-naruto-i-tech-plans | interview | [V] | in-house "CCS" engine, the "super toon" shader, "two functions melding together" rather than a typical outline |
| S2 | Siliconera (2008-10-24). *Behind Naruto: Ultimate Ninja Storm's visuals* (N. Taguchi, Namco Bandai). https://www.siliconera.com/behind-naruto-ultimate-ninja-storms-visuals/ | interview | [V] | a "special shading engine" was the key |
| S3 | 4Gamer (2010-02-15). Report of Matsuyama's talk at the 13th Japan Media Arts Festival symposium. https://www.4gamer.net/games/074/G007477/20100215011/ | talk report | [V2] | anime blur (extra triangles at the extremities), unrealistic bending, forced perspective, expression swaps, "know what to move and what to hold" |
| S4 | 4Gamer (2011-03-04). *[GDC 2011] Matsuyama on Storm 2's anime expression*. https://www.4gamer.net/games/114/G011406/20110304091/ | talk report | [V2] | super anime motion blur, a flowing background during combat, Itano Circus, the "gekiga touch" overlay, single-texture smoke and water, water deformed by bones, Skill Editor and Flow Editor |
| S5 | Siliconera (2011-03-04). *Evolution of CyberConnect2's anime style graphics* (I. Takeshita). https://www.siliconera.com/evolution-of-cyberconnect-2s-anime-style-graphics/ | talk report | [V2] | afterimage "blurry texture pasted on the polygons", rotating the background to sell speed, the twisting camera, model LODs (4k/8k/16k tris, then 12k/20k) |
| S6 | Game Watch (2010). *Storm 2 interview* (overseas version). https://game.watch.impress.co.jp/docs/interview/417718.html | interview | [V] | "limited anime-style direction"; brush-written kanji scanned for UI |
| S7 | Yamashiro, R. (2012-03-05). *森羅万象！エフェクト誕生の秘密* (CC2 official Storm Generations blog). https://www.cc2.co.jp/naruto_generation/?p=289 | developer blog | [V] | fire and similar effects hand-drawn frame by frame (1コマ1コマ), because simulation looks too real; wind tapers out instead of fading; ice gets white edge highlights; wood shaded in the anime style |
| S8 | Effect-designer blog (2015). Report of CC2 technical artist K. Ashizuka at CGWORLD CREATIVE MEETING, Storm 4. https://effect.hatenablog.com/entry/cgwcm2015 | talk report | [V2] | forward renderer, DX11/SM5; screen-space decals from depth (≤20 in battles, ≤40 in boss battles, ≤14 per character); 500 particles typical, 2000 to 3000 at peaks; hand-drawn anime blur combined with motion blur; chromatic aberration and fisheye in specials |
| S9 | PlayStation Blog JP (2016-01-29). *Storm 4 special, part 2*. https://blog.ja.playstation.com/2016/01/29/20160129-naruto4/ | publisher feature | [V] | "超アニメ表現" (surpass the anime); realism accents (clothes catch fire, scorched ground, lens flares); background destruction; denser fine particles |
| S10 | GameMakers (2022-08-11). Report of CC2's UNREAL FEST 2022 talk (K. Ōtsuka, effects lead; T. Uokawa, cinema lead, a long-time Storm staffer). https://gamemakers.jp/article/2022_08_11_10558/ | talk report | [V2] | CC2's current practice (Demon Slayer: Hinokami Chronicles): general-purpose slash effects with a shared palette per character; mesh plus trail; separate character and background light parameters; "gradient lighting" on characters only; a tone-control shadow mask; per-character and per-background colour correction |
| S11 | GameMakers (2023-12-19). Report of *CC2流！ビジュアルエフェクトアーティスト入門講座* (CEDEC+KYUSHU 2023). https://gamemakers.jp/article/2023_12_19_57404/ | talk report | [V2] | main, sub and filler layers; **more than 4 hues breaks cohesion, 2 to 3 is typical**; staggered appear and disappear; 2-tone conversion of smoke; UV rotation for spin; ghost blur; always test against the real background |
| S12 | CEDEC+KYUSHU 2025 session list. https://cedec-kyushu.jp/2025/session.html | programme | [V] | CC2 still presents on anime-style effects (Y. Uehara) and on Storm's mobile port (Y. Tsuneoka). Abstracts only |
| S13 | Motomura, J. C. (2015). *GuiltyGearXrd's Art Style: The X Factor Between 2D and 3D*. GDC 2015, speaker notes PDF. https://www.ggxrd.com/Motomura_Junya_GuiltyGearXrd.pdf | talk handout | [V] | the reference implementation: a step function; vertex-colour threshold offset; a light vector per character; hand-edited normals; lit colour × tint texture for the shadow colour; inverted-hull outlines with width painted in vertex colour; UV-aligned inner lines; limited animation (no interpolation, every frame a key, scale animation, deliberate imperfection) |
| S14 | Mitchell, J., Francke, M., & Eng, D. (2007). Illustrative rendering in *Team Fortress 2*. NPAR '07. https://doi.org/10.1145/1274871.1274883 | peer-reviewed | [V] (abstract) | warped-diffuse ramps, rim highlights for readability |
| S15 | Lake, A., Marshall, C., Harris, M., & Blackstein, M. (2000). Stylized rendering techniques for scalable real-time 3D animation. NPAR '00, 13–20. https://doi.org/10.1145/340916.340918 | peer-reviewed | [V] (metadata) | hard shading from a 1D texture; silhouettes |
| S16 | Raskar, R., & Cohen, M. (1999). Image precision silhouette edges. I3D '99. https://doi.org/10.1145/300523.300539 | peer-reviewed | [V] (abstract) | the origin of the enlarged back-face ("inverted hull") silhouette |
| S17 | Saito, T., & Takahashi, T. (1990). Comprehensible rendering of 3-D shapes. SIGGRAPH '90. https://doi.org/10.1145/97879.97901 | peer-reviewed | [V] (abstract) | G-buffer (depth and normal) edge detection, the ancestor of post-process outlines |
| S18 | Schmid, J., Sumner, R., Bowles, H., & Gross, M. (2010). Programmable motion effects. ACM TOG 29(3), 57. https://doi.org/10.1145/1833349.1778794 | peer-reviewed | [V] (abstract) | speed lines, stroboscopic multiple images, stylised blur |
| S19 | Basset, J., Bénard, P., & Barla, P. (2024). SMEAR: Stylized motion exaggeration with art-direction. SIGGRAPH '24. https://doi.org/10.1145/3641519.3657457 | peer-reviewed | [V] (abstract) | elongated in-betweens, multiple in-betweens and motion lines for 3D |
| S20 | Tanaka, K., & Komada, T. (2024). *3D Toon Rendering in Hi-Fi RUSH*. GDC 2024. https://gdcvault.com/play/1034330/ ; summary at 80.lv | talk (summary only) | [V2] | a deferred toon renderer in UE4 for characters and world at 60 fps; comic shader, toon lights, face shadows |
| S21 | He, J. (Unite 2017/2018). *Honkai Impact 3rd high-quality toon rendering in Unity* (Unity CN write-up). https://developer.unity.cn/projects/5b064305880c6462edfeb7ec | talk write-up | [V2] | a 3-step ramp, Fresnel rim with width and softness, vertex-colour masks |
| S22 | Gilland, J. (2009). *Elemental Magic, Vol. I: The Art of Special Effects Animation*. Focal Press. | book | [V] (publisher page) | the canonical hand-drawn effects vocabulary (fire, smoke, liquids, magic) |
| S23 | Nakura, S. (2016). セル調エフェクト tips. *CGWORLD* 219. https://cgworld.jp/feature/201611-cgw219t2-tips.html | trade article | [V] | cel-look effects in 3D: **light:shadow ≈ 7:3**; match the scale of detail to the shading; silhouette over material; simple bent planes beat detailed textures |
| S24 | Izumitsui, Y. (2016). エフェクトを考える. *WEBアニメスタイル*. https://animestyle.jp/2016/03/07/9837/ | trade column | [V] | anime compositing: "T光" glow = isolate the brights, blur, add. Effects divide into environmental and dramatic |
| S25 | Sakugabooru blog glossary, *Impact frames*. https://blog.sakugabooru.com/glossary/impact-frames/ | fan reference | [V] (weak) | impact frames: brief monochrome or chromatically stylised drawings |
| S26 | ja.wikipedia *コマ打ち*; en.wikipedia *Limited animation* | encyclopedia | [V] (weak) | on twos = 12 drawings/s, on threes = 8 drawings/s at 24 fps |
| S27 | torchinsky.me (n.d.). *Stylized VFX in Unity, part 1: step, smoothstep, dissolve*. https://torchinsky.me/stylized-vfx-unity-01/ | tutorial | [V] | the threshold and dissolve math for hard-edged effects |
| S28 | McClellan, M. *2D toon shading for VFX flipbooks*. https://mitchmcclellan.com/2D-toon-shading-for-vfx-flipbooks/ | tutorial | [V] | fake normals from a shape gradient, 2-step toon light on sprites, a stroke channel for outlines |
| S29 | Reviews of *Jujutsu Kaisen: Cursed Clash* (TheXboxHub, Eurogamer via Wikipedia, 2024) | reviews | [V2] | counter-example: flashy effects, but "looked like an early PS3 game", with stiff, blocky animation |

Sources that were rejected or downgraded:
- A Bandai Namco Storm Trilogy dev blog. Its URL now redirects, so its content was never read.
  A search snippet claimed "effect textures ×4 resolution on PS4, a CG + hand-drawn hybrid".
  Graded [U] and not used.
- A claim that "DBFZ characters animate at ~24 fps". It was seen only in a search summary, and the
  fetched Kotaku article contains no such number. Graded [U] and not used.
- GameSpot's 2008 review and hands-on returned HTTP 403. Their search snippets praise the cel
  shading but give no technique. Graded [U] and not used.
- Genshin community shaders on GitHub. They are reverse-engineering of datamined assets, not
  developer statements. Excluded; S21 (miHoYo's own talk) covers the lineage.

---

## 2. Character rendering (sub-question 1)

### 2.1 Shading
- CC2 built an in-house engine (CCS) and a "super toon" shader for Storm 1. Matsuyama says it
  combines "two different functions melding together" instead of a typical toon plus outline
  **[V: S1]**. The functions are not named. The talk also calls a special shading engine "the key"
  to making players feel they are playing the anime **[V: S2]**.
- The clearest public explanation of how such a shader works comes from Arc System Works. Their
  shader is a **step function of N·L against a threshold**, with full artist control over the three
  inputs **[V: S13]**:
  - The threshold is offset per vertex from a vertex-colour channel. An offset of 0 means
    "always in shadow", which acts as painted occlusion.
  - The light vector is **one dedicated light per character**. It is fixed in battle and animated
    in cutscenes. There is no global lighting on characters.
  - The normals are hand-edited on every major feature, and especially on faces.

  Motomura's rule is "Kill everything 3D… every little noise on the surface will become extremely
  distracting" **[V: S13]**.
- Band count. Anime colour design is basically **2 tones** (lit and shadow), sometimes with a
  third highlight or darker tone. Arc System Works uses 2 **[V: S13]**, Honkai uses a 3-step ramp
  **[V2: S21]**, and TF2 uses a continuous warped ramp **[V: S14]**. Storm characters read as
  2-tone with a crisp terminator and occasional soft gradients in later entries **[I]**.
- Shadow colour. The shadow is **not** lit colour × grey. Motomura: "shades on human skin get a
  red tint because of the flesh under it", so a less solid material gets a lighter, tinted shadow.
  The implementation is shadow = base × tint texture, chosen per material by the artist **[V: S13]**.
  CC2's later work adds a mask that places shadows exactly (shadows on the white of the eye but not
  on the pupil) and "Sadd" shadow meshes for eyebrows **[V2: S10]**.
- Separate light for characters. In Hinokami Chronicles, CC2 split the directional light into
  character and background parameters, added "gradient lighting" (additive or negative 3D
  gradients that affect characters only), and applied colour correction separately to characters
  and background **[V2: S10]**. This is CC2's current way of keeping characters readable. Storm's
  earlier implementation details are not public **[I]**.

### 2.2 Lines
- Arc System Works uses an **inverted hull** for outlines: a second, darker shell expanded along
  the normals and front-face culled. Width is painted per vertex and can be erased locally.
  Motomura chose it over post-process outlines because of WYSIWYG preview and per-vertex control
  **[V: S13]**. The method goes back to Raskar & Cohen 1999 **[V: S16]**. Post-process edges
  (depth and normal discontinuities) go back to Saito & Takahashi 1990 **[V: S17]**.
- Inner lines are drawn in the texture along UV-aligned axis "beams", so they stay jaggy-free in
  close-ups **[V: S13]**.
- Storm: dark outlines on characters that are thicker on the silhouette and thinner inside, with
  line colour close to black or a dark local hue **[I]**. For Storm 2, the "gekiga touch" is a
  rough line texture overlaid on faces in intense moments **[V2: S4]**.

### 2.3 Rim and specular
- A rim highlight is a readability tool: it lets players read a shape under any lighting
  **[V: S14]**. Honkai uses a Fresnel rim with width and softness controls and masks it with AO
  **[V2: S21]**. Motomura keeps specular as authored shapes driven by maps (intensity and size),
  not physical lobes **[V: S13]**. Storm shows thin bright rims in dark or dramatic stages and
  hard-edged hair highlights **[I]**.

### 2.4 Colour, faces
- Palettes are limited and saturated per character. Storm keeps the anime's character colours,
  and they stay recognisable under stage tints **[I]**. The effect rule of ≤ 3 to 4 hues **[V2:
  S11]** is a good proxy for the whole frame.
- Faces use **pre-drawn expression variants that are swapped**, not simulated. Swaps are
  concentrated on the eyes and mouth **[V2: S3]**. A facial rig adds exaggerated deformation, such
  as a skull that deforms with emotion **[V2: S4]**. Arc System Works hand-edits face normals
  **[V: S13]**.

### 2.5 Animation of characters
- Storm's philosophy: "serious CG containing 'frivolous' expression". Bones bend unrealistically,
  near objects get impossible proportions to force perspective, and the team decides "what to move
  and where to economise" **[V2: S3]**. Storm 2 also calls this "limited anime-style direction"
  **[V: S6]**.
- Arc System Works goes further with **no interpolation, every frame a key, about 500 bones,
  scale animation, and deliberate per-key imperfection** **[V: S13]**. Storm's in-game character
  motion looks interpolated (smooth). Limited-animation holds show up mostly in cinematics and
  effects **[I]**. This difference matters for SOUL DUEL (STYLE_STORM_DESIGN.md §2.6).

---

## 3. Effects (sub-question 2, the core)

### 3.1 How CC2 builds 2D-animated effects in 3D
- **Hand-drawn, frame by frame.** In Storm Generations, fire and other natural phenomena are drawn
  1コマ1コマ, because "simulation makes it realistic". Textures are tuned so they do not read as CG.
  Wind is designed to taper out rather than fade. Ice gets white rim highlights for sparkle **[V:
  S7]**.
- **Single moving textures, deformed geometry.** For Storm 2, explosion smoke and water pillars
  are made by moving one texture, and water is bone-deformed to look "more impressive than
  reality" **[V2: S4]**.
- **Afterimage smears.** Motion blur is a blurry texture pasted on polygons at the start of a
  movement, which makes limbs look elongated **[V2: S4, S5]**. Storm 1 used pre-inserted triangles
  at the extremities, driven by physics, then hand-corrected until single frames looked good when
  frozen **[V2: S3]**. In Storm 4 this hand-drawn blur is combined with real motion blur **[V2:
  S8]**. Academic equivalents: SMEAR (elongated in-betweens, multiples, motion lines) **[V: S19]**
  and programmable motion effects **[V: S18]**.
- **Volume and budgets.** Storm 4 runs about 500 particles in a typical boss battle and 2000 to
  3000 at peaks. Complex models serve as particle instances, and particle work is spread over 4
  threads **[V2: S8]**. Storm 4 pushed "denser fine particles" plus realism accents: burning
  clothes, scorch marks, soil displacement, lens flares **[V: S9]**.
- **Composition rules** (CC2's in-house effect training) **[V2: S11]**:
  - Layer every effect as main, sub and filler.
  - Keep 2 to 3 hues and never more than 4.
  - Stagger how elements appear and disappear.
  - Convert real smoke to 2 tones.
  - Fake fast spin by rotating the UVs.
  - Use "ghost blur" with controlled shape degradation.
  - Push the flashiness to the limit, but judge it against the real background and with other
    effects playing at the same time.
- Slash effects are generic, tinted per character, and share one palette with the shockwaves and
  sparks of the same character. Trails mark trajectory and meshes give substance **[V2: S10]**.

### 3.2 The drawn-effect vocabulary (anime effects practice)
From S22, S23, S24, S7 and S11. The Storm-specific appearance of each item is [I]:

| Element | Drawn-anime form | Tones | Timing |
|---|---|---|---|
| Fire | Tongues with hard silhouettes and 3 tones (hot core yellow-white, body orange, dark red edge or shadow side), shapes that split and taper, layered | 3 plus a dark edge | on twos or threes; S7 says hand-drawn per frame [V] |
| Smoke puff (the "poof") | Round clustered balls with a lit side and a shadow crescent (7:3 light:shadow [V: S23]), an outline, and a noisy dissolve at the end | 2 plus ink | on twos, with a hold at full size |
| Impact / hit spark | Flat star or spike shapes (4 to 8 points), white core, a coloured ring, 2 to 4 drawings then gone | 2 to 3 | on ones or twos, very short |
| Shockwave | A flat ring or ellipse on the ground, thick then thin, sometimes a hard-edged disc of dust | 2 | fast expand, then hold and break up |
| Speed lines | Parallel streaks (流線) for movement; focus lines (集中線) converging on a subject | 1 (ink or white) | re-drawn every 2 to 3 frames (flicker) |
| Debris | Rock chunks with outlines and 2-tone shading | 2 plus ink | on twos |
| Energy aura | Flame-shaped wisps around the body with a bright rim | 2 to 3 | cycles of 3 to 4 drawings |
| Smear / afterimage | Elongated limb or weapon shapes, multiples, a ghost blur | flat | 1 to 2 frames |
| Impact frame | 1 to 3 frames of monochrome, negative or saturated inversion **[V (weak): S25]** | 1 to 2 | 1 to 3 frames |
| Glow (T光) | Isolate the brights, blur, add **[V: S24]** | n/a | continuous |

Outlines on effects are used selectively. Solid-body effects (smoke puffs, rocks, fire masses) get
dark outlines or a dark rim. Light effects (glows, beams) get no outline but a white core.
Toon-shaded flipbooks get their outline from a stroke channel **[V: S28]**. Storm keeps this split
between solid and light effects **[I]**.

### 3.3 Timing and limited animation
On twos = 12 drawings/s, on threes = 8/s **[V (weak): S26]**. Arc System Works removes
interpolation for characters **[V: S13]**, and CC2 draws effects per frame **[V: S7]**. Held
frames with abrupt changes are what separate "drawn" from "simulated". Continuously integrated
particles read as CG **[I, and consistent with S7's argument]**.

### 3.4 Screen-space effects in Storm
- Chromatic aberration and fisheye distortion in special attacks **[V2: S8]**.
- Lens flares **[V: S9]**, stylised cross flares **[V2: S11]**.
- Background rotation and flow to sell speed **[V2: S4, S5]**.
- Flashes, colour-shifted and monochrome impact frames, and focus-line overlays during ultimate
  jutsu **[I]**.

### 3.5 Camera and cinematics
- Storm 2: rotating and twisting camera moves, the "Itano Circus" of undulating missile paths
  combined with background motion **[V2: S4, S5]**. The Flow Editor gives artists control of
  camera, character movement, screen effects and sound timing on one timeline **[V2: S4]**. The
  cinema section lead (Uokawa) has been on the series throughout **[V: S10 programme page]**.
- Arc System Works: 3D exists largely for the camera freedom in specials and finishes
  **[V: S13]**.
- Storm's ultimate jutsu: a trigger clash, then a staged sequence of close-ups, whip pans,
  low and dutch angles, cuts every 0.3 to 1 s, a held impact still, a wide aftermath, and
  character-specific QTE-style prompts **[I]**.

---

## 4. Environment and lighting (sub-question 3)
- Storm 4 backgrounds take destruction decals (screen-space, from depth) and terrain deformation
  **[V: S8, S9]**. Lens flares and scorch marks are deliberate "realism accents" **[V: S9]**.
- CC2 lights characters and backgrounds with separate parameters and grades them separately
  **[V2: S10]**. Backgrounds are painted in look: soft gradients, low-frequency detail and gentle
  outlines, lower contrast than the characters **[I]**.
- Anime compositing adds glow (T光) and optical effects (flare, halo, diffusion) on top **[V: S24]**.

---

## 5. Comparisons (what transfers)
| Title | What it teaches | Grade |
|---|---|---|
| Guilty Gear Xrd / DBFZ (Arc System Works) | the most documented pipeline: step shading, threshold, per-character light, hull lines, limited animation | [V: S13] |
| Genshin / Honkai (miHoYo) | ramp bands, Fresnel rim, masks in vertex colour; the mobile-friendly lineage | [V2: S21] |
| Hi-Fi Rush (Tango) | toon shading also works for the *world* at 60 fps with toon lights and a comic shader | [V2: S20] |
| Demon Slayer: Hinokami (CC2) | CC2's current effect and lighting practice | [V2: S10] |
| JJK Cursed Clash (Byking) | flashy effects cannot save stiff character animation and a flat, dated look; readability and motion come first | [V2: S29] |

---

## 6. Synthesis: the 10 traits that read as "Storm"

Ranked by how much each contributes to the "this is Storm" read **[I, ranking]**. The evidence
for each trait's existence is given in brackets.

1. **Ink outlines on characters**, heavier on the silhouette, also where parts overlap [I; hull
   method V: S13].
2. **Two-tone cel shading with designed, hue-shifted shadow colours** and a crisp terminator
   [V: S13; CC2 "super toon" V: S1].
3. **Limited, saturated palettes per character**, with clear value separation from the stage
   [I; CC2 separate grading V2: S10].
4. **Effects as drawn shapes**: hard edges, 2 to 4 tones, a dark edge on solid effects, a white
   core on light effects [V: S7; V2: S11].
5. **Held and stepped effect timing** (drawings, not simulation) [V: S7].
6. **Anime motion blur and smears**: afterimage polygons, elongated limbs, speed lines
   [V2: S3, S4, S5].
7. **Camera language in specials**: whip pans, orbiting and rotating backgrounds, fast cuts, low
   and dutch angles, holds on key poses [V2: S4, S5].
8. **Screen punctuation**: flashes, impact frames, chromatic aberration and fisheye, focus lines
   [V2: S8; impact frames I].
9. **Typography as art**: brush-lettered kanji and move names [V: S6].
10. **Readable, painterly stages** that recede behind the characters but show destruction
    [V: S9; V2: S8].

**Incidental** (skip for SOUL DUEL): exact particle counts, lens-flare realism, burning clothes,
LOD tiers, depth of field, deferred versus forward rendering, high poly counts.

---

## 7. Devil's Advocate checkpoints

**Checkpoint 1 (scope).** *Challenge:* "Storm look" is not one look. It spans 15 years and two
hardware generations. *Resolution:* the research targets the **Storm 3/4 era** (PS3 late, PS4)
as the canonical look and treats Storm 1's flatter look as the minimum. PASS.

**Checkpoint 2 (synthesis). Cherry-picking check.** Most technique detail comes from Arc System
Works, not CC2. *Risk:* the design ends up building "Guilty Gear" and calling it Storm. *Response:*
- The ASW techniques used (step shading, per-character light, hull lines) are the generic cel
  toolkit, and CC2 says only that its shader goes "beyond" standard toon (S1).
- The **differences** are kept explicit. Storm characters move smoothly while ASW characters are
  stepped. Storm effects are drawn and stepped [V: S7]. The design follows Storm on both
  (STYLE_STORM_DESIGN.md §2.6, §3.5).
- *Counter-evidence searched:* is there any CC2 statement that its effects are simulated or
  smooth? None found. Storm 4 added "denser fine particles" (S9), so particles do coexist with drawn
  effects. The design keeps a thin layer of particles ("filler", S11).

  Verdict: PASS with a recorded limitation.

**Checkpoint 3 (final vulnerability scan).** The strongest counter-argument: "Low-poly rigid
boxes can't look like Storm; outlines on boxes look like a toy." *Response:* partly true.
- The hull lines and 2-tone shading give an anime read at gameplay distance. Arc System Works
  says the look is 90 % "artist's intention", not polygon count [V: S13].
- Close-ups expose the boxes, so cinematics lean on effects, speed lines and camera, which is
  CC2's own economy of "what to move and where to economise" [V2: S3].
- The design adds smooth normals for round parts and zero face jitter so the terminator reads as
  drawn.

  The residual risk is recorded in STYLE_STORM_DESIGN.md §10. "So what?" test: every trait maps to a concrete
  engine change with a cost estimate (STYLE_STORM_DESIGN.md). PASS.

---

## 8. Limitations
- No video analysis was possible. Every [I] claim about Storm's on-screen look (outline weight,
  rim, impact frames, ultimate camera grammar, painted stages) must be confirmed with 10 to 20
  reference captures before Phase 2 of the plan (STYLE_STORM_DESIGN.md Phase 0).
- CC2 has published little about Storm's shader internals. The key terms ("super toon", "two
  functions") are known only by name.
- Several key sources are secondary reports (4Gamer, GameMakers, a blog) of talks whose slides are
  not public.
- The peer-reviewed sources were checked at abstract and metadata level only.

## 9. Ethics and AI disclosure
AI-assisted research: sources were located, read and summarised by an AI agent (Claude). Quotes
are translated paraphrases unless marked. No copyrighted assets are proposed for use: the design
reproduces a *style* with procedural means only, in line with the project's fan-study statement
(README). Dual-use: none. Attribution: every technique is credited to its source.


---

## 10. Addendum after the design reviews (v3)

The design went through an art-direction critique and a rendering-engineering critique (see
STYLE_STORM_DESIGN.md §13). They changed three points of this analysis:

- **Trait 0: complementary figure/ground** [I, art review]. In an anime frame the saturated
  character and effect colours sit on a background of the complementary temperature. SOUL DUEL's
  current dusk frame keeps everything at hue 15–35°, so the fire effects disappear. This ranks
  above traits 1–10 for our game.
- **The gradient over the cel.** CC2's current practice adds gradient lighting on characters only
  [V2: S10]. Storm 3/4 characters show a soft vertical darkening toward the feet over the 2-tone
  cel [I]. Pure GGXrd flat 2-tone therefore leans toward "Xrd", not "Storm".
- **Matter vs energy edges.** §3.2 already says that solid effects get dark outlines and light
  effects get a white core with no outline. v2 of the design inked everything; v3 follows this
  rule (ink on smoke, dust, ash and rock; coloured edges on reiatsu, soul, burst and hit; fire is
  the hybrid).
- **Canon for these characters.** Storm supplies the *grammar* (drawn, stepped, inked,
  punctuated). The *shapes* of Yamamoto's and Kenpachi's effects must come from **Bleach TYBW**
  and **Rebirth of Souls**. Both are added to the Phase-0 reference board.

---

## 11. Kubo Tite, the TYBW anime and Rebirth of Souls (v4 addendum)

**Why this section exists.** The user redirected the art direction (STYLE_STORM_DESIGN.md §13,
round 4) to Storm's *techniques* rendered in **Kubo Tite's visual language**: stark black/white
contrast between characters and background, and a cold, dark, despairing base tone. The same
deep-research method was used: scoped questions, targeted Japanese and English searches, graded
sources, and a Devil's Advocate check.

### 11.1 Sources

| # | Source | Type | Grade | Used for |
|---|---|---|---|---|
| K1 | CBR, *Tite Kubo's Bleach is the best example of improved animation*. https://www.cbr.com/bleach-art-and-animation-changes-over-time/ | fan journalism | [V2] (weak) | Kubo "reduced his use of gray tones in favor of starker blacks and whites"; later "minimalist" backgrounds where "negative space was used to emphasize a character's attack"; the TYBW anime traded the earlier "hazy scheme for a darker one" |
| K2 | CreativeIdeaNote, summary of *ジャンプ流 vol.4 久保帯人* (Shueisha's drawing-method magazine). https://ideanotes.jp/art8/ | summary of a primary how-to | [V2] | strong 白/黒 contrast for emotional impact; **余白** (negative space) as room for the reader's imagination; only a brush pen and a G-pen, using the brush pen's natural irregularities; **sky and weather as indicators of inner state**; brush lettering refined in detail rather than one stroke |
| K3 | Febri (2023), *『BLEACH 千年血戦篇』監督・田口智久と振り返る制作秘話②*. https://febri.jp/topics/bleach-2023_01_02/ | director interview | [V] | ep. 6: "the flames surrounding Yamamoto are hand-drawn, but the flames behind are almost entirely 3D"; Zanka no Tachi: "even ink-wash or charcoal-like effects can be achieved digitally now" |
| K4 | TV anime *BLEACH 千年血戦篇* official site, director interview no. 9. https://bleach-anime.com/special/interview/09.html | director interview | [V] | the "音を消す" technique: in Yamamoto's flame sequence "骨の音しかしない" (only bone sounds remain); Kubo rewrote the ep. 6 dialogue himself |
| K5 | artist_unknown (2022-11-14), *BLEACH: TYBW #06: The Fire*. https://artistunknown.info/2022/11/14/bleach-thousand-year-blood-war-06-the-fire/ | expert episode analysis | [V2] | the colour script shifts from warm to "a rich assortment of purples and dark blues"; hand-drawn foreground flames over CGI background flames; "a special digital brush" for sketchy patterns; rim highlights to code flashbacks |
| K6 | animatetimes, Taguchi × Murata dialogue (part 3). https://animatetimes.com/news/details.php?id=1730445461 | director interview | [V] | photo and video reference for hard angles, Live2D, 3D sets; original scenes under Kubo's supervision (context only) |
| K7 | Wikipedia / AUTOMATON, *Bleach: Rebirth of Souls* (Tamsoft, 2025, Unreal Engine) | reference | [V2] | the developer and engine only |
| K8 | Steam and community comments that RoS "looks like the TYBW anime" | forum | [U] | not used for decisions; **no developer statement on RoS rendering was found** |
| K9 | Search summary: the TYBW OP's reduced palette with magenta as the arc's symbolic colour | search snippet | [U] | not used |
| — | The user's brief: muted cold greys and blue-blacks, sudden full-screen black/white inversions, red accents, ink splashes, the manga's black-page flashbacks | client brief | design input | treated as a requirement, **not** as evidence about the anime |

### 11.2 Findings: Kubo's manga language
1. **Notan over tone.** Kubo's line moved from grey tone toward pure black and white [V2: K1],
   used for emotional impact [V2: K2]. For us this means a 5-step value system, a world with
   almost no saturation, and no halftone.
2. **Negative space as a device.** 余白 leaves room for the reader [V2: K2], and late-series
   fights empty the background to feature the figure and the attack [V2: K1]. For us: near-empty
   stages, a blank "white page" foreground, and black/white cards in cinematics.
3. **Brush irregularity.** A brush pen and a G-pen, and irregularity is welcome [V2: K2]. This
   supports v3's broken, weighted effect edges and the brush font.
4. **Weather and sky carry emotion** [V2: K2]. This justifies choosing the stage mood on purpose:
   night with ash for despair, and rain only as a cinematic accent.
5. **Clothing as black and white masses** (black shihakusho, white haori) with white lines on
   black. Tagged [I]: this is the familiar look of the manga, not found as a sourced statement.
6. **Attack names and captions in large brush lettering with small readings; English-style
   chapter titles.** Tagged [I]: the manga's convention, not sourced here.

### 11.3 Findings: the TYBW anime (Pierrot, 2022–)
1. **Hand-drawn foreground effects over 3D backgrounds** [V: K3; V2: K5]. This matches Storm's
   hybrid and our drawn shapes over a simple world.
2. **Zanka no Tachi as ink-wash / charcoal** [V: K3]. This is the basis for v4's Bankai: the
   world desaturated, a charcoal texture, and one ember line.
3. **Silence as a direction tool** (only bone sounds) [V: K4]. This becomes v4's silence beats.
4. **A darker, sharper colour script** [V2: K1], shifting from warm to purples and deep blues
   within an episode [V2: K5]. This supports the cold base plus warm spot colour.
5. Full-screen black/white inversions and red accents are the user's description [brief]. The
   design implements them (manga-page and negative modes) without claiming a source.

### 11.4 Rebirth of Souls
The only documentation found gives the developer (Tamsoft) and the engine (Unreal) [V2: K7].
Claims about its look are forum-level [U: K8]. **RoS is therefore not used as a style
reference.** It remains the gameplay reference it always was (DUEL_DESIGN.md).

### 11.5 Integration with Storm (synthesis)
- **Storm supplies the machinery**: toon 2-tone, ink hulls, drawn and stepped effects, impact
  frames, smears, camera grammar.
- **Kubo and TYBW supply the palette and the composition**: notan, negative space, cold dark
  base, spot colour, silence, ink.

The two do not conflict. Storm's research already puts 2–3 hues per effect [V2: S11] and ink on
matter (§3.2), and Kubo's language narrows that to one spot hue plus black and white.

The only real tension is **Storm's saturated anime colour versus Kubo's near-monochrome**. v4
resolves it as follows:
- saturated colour is reserved for 3 spot hues with owners (fire, reiatsu when awakened, blood);
- the characters' skin is the only other warm colour, and it is muted.

### 11.6 Devil's Advocate checkpoint (v4)
**Challenge:** "A monochrome world with thin spot colour will read as a filter over a 3D game,
or as too dark to play."

**Response:**
- The notan interlock puts a pale ground under the fighters for most of the frame, so gameplay
  reads *better* than the current single-hue frame.
- 2-tone shading and ink lines keep the 3D read.
- Spot colour keeps the character identity (fire = Yamamoto, yellow = awakened Kenpachi).

**Residual risk:** it is untested without reference captures, so it is placed at user review 1
(design §9). **Verdict: PASS with a recorded limitation.**
