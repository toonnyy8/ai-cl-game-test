# Kenpachi rework: his strike motions and his model (in discussion)

Branch `claude/kenpachi-rework`, opened 2026-10-08. Skill: `duel-character-rework` (the loop: quote, diagnose, options,
docs first, presentation-only proof). Research: `docs/research/kenpachi-rework/canon-looks.md` (every visual form, graded
claims, a model checklist per form) and `motion-refs.md` (how he fights per fight, the game references, a motion bar per
form). Nothing in the game has changed yet.

## 1. The request

> 請幫我開一個新的分支，並使用本 repo 建立的 skill 來調整劍八的動作與造型模組，在開始工作前記得先收集與調查各種型態的資料。
> (the user, 2026-10-08)

The standing rule 「請先跟我討論完後再修改」 applies: the directions below wait for the user's choice.

## 2. Where he is now (diagnosis)

Stills of every form and a 4-frame strip (0, S, S+A, end) of each of his 53 clips were shot with the art viewer
(`tests/duel-view.lisp`, `./build.sh duelview …`, `python3 tests/scripts/duel-view.py`).

Forms (`duel/lisp/ken.lisp`): base (katana) → NOZARASHI cup 1 KATATE (one hand) → cup 2 RYOTE (two hands, kendo) →
cup 3 NOMIHOSE → Bankai (red oni, broken cleaver, 4 arm pips) → KATAUDE (the arm gone).

### 2.1 Model
- Base body: 2.04 m, 8.2 heads, bare skin arms, a short white sleeveless haori over the bare chest, black lapels.
- **Hair** is a cap, a back sheet and ~14 cones: from the front it reads as a flat black mop, not his spiky crown with a
  long mane. No bells, no eyepatch (the user's ruling, DUEL_NOZARASHI_V2: no eyepatch in any form).
- **Haori**: 9 hem strips, no sawtooth hem, no holes, no 十一 on the back; no white obi bow (canon has one).
- **Nozarashi** is a straight slab 1.46 × 0.3 m on a 1.62 m weapon. Canon is a crescent cleaver-axe "twice his size":
  a black body, a pale convex edge, a brass box cap at the back with a tassel, a long cloth-wrapped haft.
- **Oni**: skin #9A4A42, two dark horns (#6E302C; canon: skin-red), white pupils. No forehead mark, tear streaks or
  grin plate. The broken cleaver is ink-black with a white edge.
- Sealed katana: 1.08 m, notched; no spiky tsuba.

### 2.2 Motions
- Base strikes are small arm motions with little whole-body travel (J1 a short downward hack, J2 a flat swing hard to
  read from the side, K3 a straight thrust).
- KATATE plays the base clips slowed to S/(S+2) with the cleaver; only SP1 (meteor) and O have their own clips.
- RYOTE has its own kendo clips; NOMIHOSE reuses them (plus KUKAN-GIRI).
- **The oni mostly borrows upright clips**: J1/J2 = the base `:ke-q1`/`:ke-q2`, K1/K2 = `:ke-f1`/`:ke-f2`,
  K3 = RYOTE's `:ke-r-f2`, TATE-GOTO = `:ke-meteor`. Only the bite, the hook, the fist and the leap are his own. The
  feral stance is crouched, so each borrowed strike stands him up.
- KATAUDE plays the base clips at reach ×0.7: the drawn blade overshoots the hit by up to 0.36 m (J) and 0.58 m (K3).
- Known faults: `:ke-flurry` ends at f4 while its first hit is at f10; residual left-fist drift (worst 160 mm) on the
  two-handed clips; cup 3's grin was never built.

### 2.3 What constrains a presentation-only change
- Every strike's frame data (S/A/R), reach and hit volume are sim. A new clip that keeps its S/A/R and its tip at the
  hit edge leaves the sim byte-identical (`simgate --seeds 10 --summary`, `--cvc`).
- The FK reach test (`tests/duel-rules-test.lisp` 1652–1727): J links within ±0.15 m of the hit edge; K, Breaker and
  the NOZARASHI / Bankai forms may not pass it by more than 0.15 m. **A canon-size cleaver (≈ 2.4 m) would overshoot
  KATATE's J reach (1.82 m)** unless the J clips cut close to the body; making the hit match the drawn blade is a sim
  change and goes through the gates.

## 3. Research digest

- **Eyepatch**: canon TYBW keeps a strapless patch on the right eye until he chooses to remove it (on against Gremmy and
  Pernida, off against Unohana and Gerard). The repo's "no eyepatch in any form" is the user's decision
  (DUEL_NOZARASHI_V2), not canon; the comment in `ken-art.lisp` overstates it.
- **Bankai activation aura**: yellow in the anime (crimson is his skin), so the existing yellow pillar is right.
- **Shikai tassel**: green (manga colour edition) or dark red (anime): unresolved.
- **Rebirth of Souls** has no Shikai or Bankai Kenpachi; its sealed kit is the closest game reference (the arms-spread
  "斬ってみろよ" armour stance, the big stepping "ぶった斬る", the charge-flurry, the armoured walking thrust, the eyepatch
  awakening, the two-handed "Bisect").
- Motion bars (motion-refs §3): sealed 12 archetypes, NOZARASHI 15 by cup, Bankai 9, with one rule: **no two strikes
  share an arc plane and a hand set**.

## 4. The user's choices (2026-10-08)

Asked with four questions (recommended first); the answers, verbatim option labels:

1. Scope and order: 「逐型態：模型＋動作一起做」. One form at a time, base → NOZARASHI (KATATE / RYOTE / NOMIHOSE) →
   Bankai / KATAUDE; each form's look first, by stills for the user, then its strike clips. (Rejected: all models then
   all motions; motions only; models only.)
2. Nozarashi's size: 「改成原作形狀，大小貼合現有判定」. The canon crescent cleaver (black body, pale edge, brass cap,
   tassel, long cloth haft) at a length that fits the current hit reach: presentation only, the sim byte-identical.
   (Rejected: canon 2.4 m with the hit lengthened, a sim change; canon 2.4 m drawn only.)
3. Eyepatch: 「維持不戴眼罩」. No eyepatch in any form stays; only the code comment that calls it canon is corrected.
   (Rejected: on in base and off at the awakening; on until the Bankai.)
4. Look items to follow canon (multi-select, all four chosen): 「頭髮：刺狀頭頂＋長鬃髮」「羽織與腰帶」「卍解的臉與角」
   「封印刀的刀鍔與柄」. That is a spiky crown with a long mane (no bells); the haori sleeveless with a sawtooth hem,
   holes and 十一 on the back, a white obi with a front bow; the oni's horns skin-red, a forehead flame mark, tear-streak
   bands, blank white eyes, a grin of flat teeth; the katana's serrated spindle tsuba and a white-wrapped grip.

Every change is presentation only: frame data, reaches and hit volumes stay, and each round is proved with
`simgate --seeds 10 --summary` and `--cvc` byte-identical against the branch base (`cc40146`).

## 5. The base form (2026-10-08 – 09)

### 5.1 The look
Built and shown as stills (front, side, back, three-quarters, face; `tests/duel-view.lisp`); the user: 「可以」.
- Hair (`ken-art.lisp` :head): the skull cap, a back sheet hung 0.15 m behind the head and tilted back 18°, 9 crown spikes
  up, back and out (0.17–0.22 m), 5 ragged mane ends to mid-back (0.24–0.36 m, angled back so they clear the haori), 2
  strands over the shoulders, the side locks and two fringe strands. No bells.
- Haori (:pelvis, :spine): a white diamond behind each hem strip's foot makes the sawtooth hem (14 teeth); 4 round holes
  near the hem (black, the robe through them); 十一 in a diamond in ink strokes on the back, below the mane.
- Obi: white (#DEDED8, was #C8CCD6) with a bow at the front (knot, two loops, two tails).
- Katana (:ken-katana): a grey collar, a dark-iron spindle tsuba 16 × 5 cm pointed along the edge and spine with 12
  teeth round its rim, a white bandage grip with 6 diagonal seams, a grey cap.

### 5.2 The strikes
The plan, as proposed and accepted (「可以」, 2026-10-09), from `motion-refs.md` §3.1; frame data, reaches and hit
volumes unchanged:

| Move | Clip | Before | After |
|---|---|---|---|
| idle | `:ke-stance` (the loop only; the pose the strikes start from is unchanged) | blade held forward | the blade hanging from the loose hand, its tip on the floor behind him |
| J1 ARAGIRI | `:ke-q1` | a short diagonal hack | cocked behind the head, weight back, then down from the right shoulder to the left hip as the right foot lunges; ends low and open |
| J2 KAESHIGIRI | `:ke-q2` | a flat backhand | coiled low on the left, a rising reverse diagonal out to the right as the hips unwind, the free hand flung out; follows through up |
| K1 OBURI | `:ke-f1` | a two-handed kendo cut | the blade onto the right shoulder, up on the toes, held, one vertical one-handed chop into bent knees; the blade bites the floor |
| K2 KIRIAGE | `:ke-f2` | a rising cleave from a crouch | the tip dropped to the floor behind him and dragged as he steps in, the rising cut in front as he stands onto his toes |
| SP1 BUTTAGIRU | `:ke-buttagiru` | a two-handed leap chop | one-handed: knees tucked, the blade cocked behind the head, the left arm out, the vertical drop |
| J3, SP2, Breaker | `:ke-kick`, `:ke-charge` / `:ke-flurry`, `:ke-shoulder` | | unchanged |

- **K3 stays the spin.** The plan put the armoured walking thrust on K3, but K3 BUNMAWASHI's hit is a 360° arc
  (`ken.lisp`, `:arc 360`, crumple): a thrust would draw a front-only strike that hits behind him too. Asked (keep the
  spin / make K3's volume a thrust, a sim change / the thrust on another slot), the user: 「維持旋轉斬」 (2026-10-09).
- **The flurry** (`:ke-flurry`) was checked: it plays at speed 1, so its cuts at f10 / 16 / 22 / 28 and the launcher at
  f40 land on the move's hit windows; the cut at f4 is drawn only (the charge's contact was hit 1). No change.
- Drawn reach (the FK test's measure, the tip's radial distance at the hit frames; edge = the volume's):

| Link | Edge | Before | After |
|---|---|---|---|
| J1 (base / KATATE / Bankai) | 1.40 / 1.82 / 1.40 | 1.30 / 1.62 / 1.32 | 1.49 / 1.84 / 1.51 |
| J2 | 1.40 / 1.82 / 1.40 | 1.42 / 1.88 / 1.44 | 1.33 / 1.70 / 1.35 |
| K1 | 2.80 / 3.64 / 3.40 | 1.21 / 1.56 / 1.24 | 2.34 / 2.91 / 2.38 |
| K2 | 2.50 / 3.25 / 3.00 | 0.81 / 0.93 / 0.82 | 2.05 / 2.50 / 2.09 |

  K1 and K2 were drawn 1.6–1.7 m short of their volumes; they now reach within 0.5 m (K may fall short, never pass the
  edge by more than 0.15 m). KATAUDE plays these clips at ×0.7 reach with the broken cleaver: K1 now passes its edge by
  0.42 m and K2 by 0.34 m, inside its 0.6 m allowance. The KATATE (cup 1) and Bankai forms borrow these clips until their
  own rounds (§4, item 1).
- The art viewer's strips gained 8-frame modes (`1000000+1000i+k`, k 1 side, k 2 33° off the front) so the anticipation
  frames can be reviewed.

### 5.3 Checks
- Presentation only, proved against the branch base `cc40146`: `simgate --seeds 10 --summary` (all 15 pairings, 42
  gate lines) and `--cvc` (every line PASS) byte-identical.
- Host tests ALL PASS (rules 6481, control 89, learn 131, input 33, touch 64, cine 18); `pkgcheck` 0 / 0 / 0;
  `./build.sh duel` 0 warnings.

### 5.4 Playtest and next
- The playtest Artifact (v35, 2026-10-09) carries this round: the user, 「幫我更新 playtest」.
- Next, the user: 「做野晒」: NOZARASHI (KATATE / RYOTE / NOMIHOSE), its look first, then its strikes (§6).

## 6. NOZARASHI (2026-10-09, in progress)

### 6.1 The cleaver
- First pass (canon research, §4 item 2: the canon shape at the old length): a broad near-black head with the point at
  the far end, a brass cap and a green tassel. Shown as stills.
- The user then gave a model sheet to follow:
  > 我發現有人做出野晒的模型，雖然要付費才能下載 3D 模型，但你能看他放出來的照片來參照實作
  > https://www.cgtrader.com/3d-models/military/military-character/nozarashi-from-bleash
  (an attached front / back elevation of the cleaver; the 3D model itself was not bought or downloaded).
- Rebuilt by tracing that elevation (`:nozarashi`, `ken-art.lisp`), at the old length (the axis from the grip to the far
  end stays 1.62 m, so every hit reach and the FK test are unchanged):
  - 2.31 m from butt to end; the grip 0.69 m up the haft (the left fist's 0.14–0.62 m of handle, GRIP-LEFT!);
  - the white-wrapped haft (34 % of the length) with a black butt, running on into the head;
  - the head on the edge side only: its spine just above the haft line, a raked point overhanging back beside the hand
    over a notch, the cutting edge a long convex curve rising to 0.6 m at the square far end;
  - near-black, the edge's pale band ~40 % deep in slanted light / grey stripes with a ragged inner line, 4 chips;
  - a khaki cap (#9C9478) over the whole far end with a stepped foot and a groove; a white tassel from a ring at the
    cap's spine corner (the sheet's colour; the research's green / red conflict is moot).
- The art viewer shows a weapon alone, side on: `4100+k` / `4110+k` (k 0 katana, 1 Nozarashi, 2 the broken cleaver; one
  face / the other).
- The user on that cleaver (2026-10-09): 「流蘇改成原本的造型」「刀紋寬度減少成 2/3」「白色刀柄跟刀身不要直接連結，中間改用黑色斜槓相連」.
  - The gap the user circled (「你的刀身這邊出現缺口了」) between the point and the body: the point's back now lies on the
    body's edge.
  - The pale band: every stripe's depth × 2/3 (0.03–0.25 → 0.02–0.167 m).
  - The white haft now stops 0.08 m short of the head (its top at y 0.08); a black slanted bar (0.07 → 0.40 m up the
    axis, rising 0.07 → 0.115 m toward the edge side) joins it to the head's spine, which now starts at (0.30, 0.07).
  - "The original tassel" read two ways, shown side by side for the user to pick: A, the pre-rework one (dark
    green-grey, hung from the butt); B, the first pass's (dark green strands at the cap's spine corner). The user:
    「選 A」; then (2026-10-09, during §8): 「抱歉，先幫我重新調整始解的流蘇成 B 選項（另外，當時流蘇的頭尾掛反了）」.
    B again, its strands now cones whose points sit in the knot at the cap's spine corner and whose bases fan out away
    from the blade (before, each strand was turned about its middle: they crossed, the spread at the knot and the
    tails gathered, so it read upside down).
  - The head's angle (2026-10-09, during §8; the user: 「請幫我以黑色協槓跟刀身的連接點為基準，將刀身順時針轉 10 度」;
    asked whether Nozarashi or the Bankai's blade or both: 「卍解斷刀和始解野晒都轉（推薦）」): the head (body, point,
    pale band, chips, the cap and the tassel; the Bankai's break) turned 10° about the bar's joint with it, (y z) =
    (0.4 0.08) in the weapon frame, the far end down toward the haft line (seen with the haft on the left, the edge up);
    the black bar and the haft stay (`with-ke-tilt`). The weapon's `:length` and every hit volume unchanged.

### 6.2 The strikes
- The user, on the plan (KATATE gets its own clips through the kit's `:clip-map`, RYOTE's kendo clips refined, NOMIHOSE
  on RYOTE's with KUKAN-GIRI and the drink refined): 「三杯也改用一套自己的獨立動作」: NOMIHOSE gets its own set too;
  its plan (drained, overcommitted, bestial) was then accepted: 「可以」.
- How: the kits' `:clip-map` (a look: FIGHTER.LISP plays KIT-MOVE-CLIP; the move, its frames and volumes unchanged).
  KATATE maps the base clips and the meteor to `:ke-k-*` (authored at the base clips' S/A/R: the derived moves play them
  at S/(S+2)); RYOTE and the Bankai set `:clip-map nil` (they inherit otherwise); NOMIHOSE maps RYOTE's clips,
  KUKAN-GIRI and the meteor to `:ke-x-*`, with its own stance `:ke-x-stance`, drink `:ke-x-drink` (the Bankai keeps
  `:ke-drink`) and body `:kenpachi-nomi` (a body variant: 8 more hair spikes lifted by the reiatsu; same rig and hurt
  cylinder). The FK reach test now reads the clip each form plays (`kit-move-clip`).

| Form | Slot | Clip | What it does |
|---|---|---|---|
| KATATE | idle | `:ke-n-stance` on `:ke-k-rest` | the haft on the right shoulder, the head up behind him |
| | J1 | `:ke-k-q1` | the shoulder-roll drop: heaved off the shoulder, rolled over and down in front, dragged a step |
| | J2 | `:ke-k-q2` | the mowing sweep: low and flat, right to left, the weight dragging him round |
| | J3 | `:ke-kick` | (unchanged) |
| | K1 | `:ke-k-f1` | the flat smack: up over the left shoulder, held, a lunging backhand diagonal |
| | K2 | `:ke-k-f2` | the heave-up: the head dragged on the floor behind him, a one-handed scoop up in front, leaning back |
| | K3 | `:ke-k-spin` | the spin, the arm locked out, the cleaver carrying him round once and a bit |
| | SP1 | `:ke-k-meteor` | the meteor, one hand: cocked over the right shoulder in the leap, the top-down split |
| RYOTE | J1, J2, J3, K1 | `:ke-r-*` | the front foot lifted before the cut and stamped down on it (fumikomi) |
| NOMIHOSE | stance | `:ke-x-stance` | the cleaver dragged low behind in both hands, hunched, wide |
| | J1 | `:ke-x-q1` | the ground-shaker: up over the head, one vertical, buried in the floor |
| | J2 | `:ke-x-kote` | a short brutal hack off the shoulder, elbows bent, a lurch |
| | J3 | `:ke-x-q3` | the shoulder-to-floor diagonal, overcommitted: turned half round, crouched |
| | K1 KUKAN-GIRI | `:ke-x-f1` | one huge rising diagonal, low left to high right (its chord the rift) |
| | K2 | `:ke-x-tsuki` | the battering ram: level at the hip, the capped end first, the body charging behind |
| | K3 | `:ke-x-f2` | the bisector: a leap with the cleaver overhead, one cut to the floor, crouched |
| | SP1 | `:ke-x-meteor` | the meteor at full power: higher, arched back, both hands |
| | U | `:ke-x-drink` | the head thrown back roaring, the arms wide, the cleaver raised high on the right |

- Drawn reach (the tip's radial distance, the MEN / thrust / bisector capsules' distance ahead; edge = the volume's):
  KATATE J1 1.79 / 1.82, J2 1.80 / 1.82, K1 3.35 / 3.64, K2 2.77 / 3.25, K3 3.02 / 3.51; NOMIHOSE J1 2.06 / 2.06, J2
  1.48 / 1.44, J3 1.55 / 1.52, K1 2.84 / 3.90, K2 3.39 / 4.50, K3 2.82 / 4.45. (Before, KATATE played the base clips
  with the cleaver: K1 1.56, K2 0.93.)
- Not built: cup 3's grin (a body variant can add parts but not swap the face); the left fist's residual drift on the
  handle.
- Checks: host tests ALL PASS (rules 6481, control 89, learn 131, cine 18); `pkgcheck` 0 / 0 / 0; `./build.sh duel` 0
  warnings; `simgate --seeds 10 --summary` (42 gate lines) and `--cvc` byte-identical to the branch base `cc40146`.

## 7. The second awakenings free as the first (2026-10-09; a rule change)

> 我發現更木與利傑的二次覺醒只能在站立不動或是防禦時發動，我希望能像一般覺醒一樣只要達成條件就能發動。
> (the user, 2026-10-09)

- Diagnosis: the first awakening is taken where `awaken-state-p` allows (idle, walk, guard, blockstun, or a combo
  reaction / airborne past the Burst's hit with inputs not locked; never during one's own move, run or step). For a
  player, Kenpachi's Bankai already used that rule (`fighter.lisp` `:awaken` passes the same FREE to
  `bankai-allowed-p`). Lille's revival did not: `lb-revive-ok-p` demanded idle / guard (decision 16). The CPU did not
  either, for both: `ai.lisp`'s Bankai reflex demanded idle / guard, and its combo break (`ai-awaken-break-p`) knew only
  the first awakening.
- Asked: the same as the first awakening / wider (also cancelling his own move) / the player only. The user: 「和一般覺醒完全相同」,
  on this branch: 「放在目前的劍八分支」.
- Changes:
  - `lb-revive-ok-p (form free konpaku)`: FREE is `awaken-state-p` (from `lille-bankai-ok`).
  - The CPU's Bankai / revival reflex: `(bankai-allowed-p (awaken-state-p e f) …)` instead of idle / guard.
  - `ai-awaken-break-p (e &optional b)`: also the second awakening when it is ready (`bankai-ready-p`) and the kit's
    `:bankai` rule says so (`ai-bankai-p`, its one roll per stay), so the CPU breaks a combo with it as with the first.
  - Docstrings and DUEL_DESIGN §1, DUEL_KEN_BANKAI §1.1 / m2, DUEL_LILLE decision 16 updated.
- Gates (all 21 pairings, 20 seeds, against the parent `7e7f5b0`): every match K.O.; every median, min, max and win count
  identical; one match of LI changed (132 → 120 s). `--cvc` 3 PASS (the references unchanged). Host tests ALL PASS (the
  revival test now passes FREE: rules 6481); `pkgcheck` 0 / 0 / 0; `./build.sh duel` 0 warnings.

## 8. The Bankai and KATAUDE (2026-10-09, in progress)

- The playtest Artifact carries §6–§7 (v36; the user: 「幫我更新 playtest」), then 「開始設計」 for the Bankai.
- Diagnosis (stills of every `:ke-b-*` clip and the weapon): the oni still wears the white haori; the broken cleaver is
  the old slab's, not the new Nozarashi's; J1 / J2 / K1 / K2 borrow the upright base clips, K3 RYOTE's KABUTO-WARI, SP1
  the meteor (the oni stands up out of his crouch for each); KATAUDE swings with the burst right arm, its drawn reach up
  to 0.58 m past the volume.
- Asked (the face and horns were chosen in §4): the look (multi-select), the motion plan, KATAUDE. The user:
  - look: 「服裝改成原作」「斷刀照新野晒重做」「頭髮更狂亂」 and 「開始前請先找尋卍解的參考圖」 (steam not chosen);
  - the plan: 「可以，照方案做」: stance / prowl low, head forward, jaw open, the left hand a claw, the back dash a roaring
    leap; J1 / J2 beast hacks forehand / backhand off the shoulder; J3 the left hook kept; K1 ONATA a hatchet chop sprung
    from the crouch; K2 EGURI-AGE a gouge up from the floor; K3 a leaping cleave through the guard; L the bite with a
    wrench; SP1 TATE-GOTO the leaping two-handed diagonal; SP2's NAGURI-TOBASHI a left uppercut; O MAPPUTATSU the leaping
    vertical, refined;
  - KATAUDE: 「換左手拿刀＋專屬動作」: the cleaver in the left hand (a generic draw option, presentation only), the right
    arm hanging, a one-handed close set at the ×0.7 reach.
- References (the user: 「開始前請先找尋卍解的參考圖」): 18 stills of the anime (THE PERFECT CRIMSON) and the colour manga
  (ch. 669–671) in `.refs/kenpachi-bankai/` (git-ignored third-party art), their sources and notes in
  `docs/research/kenpachi-rework/bankai-refs.md`. Findings: the whole body crimson; two horns over the eyes (small cones
  in the anime, big brow-ridge horns in the manga); a brow slit, black commas over the eyes, an eye mask, tear streaks,
  and in the anime tiger stripes on the cheeks and neck; blank eyes, a full-teeth grin, the scar; bare torso, a ragged
  black sleeveless mantle over the shoulders, the white obi, black hakama, bare feet; the broken cleaver black with a
  square snapped end (manga) or steel grey with a hooked spur (anime); after the burst he fights **bare-handed** with
  his left (grabs Gerard's foot): no source shows the blade moved to the left hand.
- Asked again on those (2026-10-09): the horns and face 「動畫版：小角＋虎斑紋」; the broken cleaver 「漫畫版：黑色、方形斷口」;
  KATAUDE 「改成空手（照原作）」 (replacing the left-hand blade: the left-hand weapon option built for it was reverted).
  KATAUDE's moves keep their frames and volumes; its fist / grab / kick strikes may fall short of them (the FK test
  allows KATAUDE short, and 0.6 m long).
- The user's figure references (「我給你其他卍解的參考圖，你看一下」, four product photos of Bankai figures, kept in
  `.refs/kenpachi-bankai/user/`): the broken blade is an axe head there, its spine straight along the haft, a hooked
  spur by the haft, the snapped end square, the blade light steel. Asked about the colour: 「維持漫畫：黑色」.

### 8.1 The look (built)

- The oni (`:kenpachi-oni`, the anime's): crimson skin; two small horns over the eyes (cones 0.06 m); the brow slit, the
  black commas, the eye mask, the tear streaks; tiger stripes on the cheeks, the jaw and the neck; the bare chest and
  belly with crease lines; a ragged black sleeveless vest with a white lining down the front edges; the white obi; the
  black hakama with flared ragged cuffs; bare crimson feet. The hair wilder: Nomihose's eight lifted spikes kept.
- The haori: its 42 shapes (hem strips and teeth, holes, every chest / spine / shoulder piece) now carry `:tag :haori`;
  the Bankai and KATAUDE kits hide `:haori` (and the arm wreck / cracks as before).
- The broken cleaver (`:ke-broken`): first built in the manga's black, the figures' axe outline, 1.12 m. On the stills
  the user: 「卍解刀身直接沿用始解刀身，然後將我打 X 的地方移除變成斷刀」 (the X over the cap, the tassel and the far half
  of the head). Now Nozarashi's own head, haft, butt and colours (one function, `ke-mb-noz-head`, draws both: every
  profile clipped at the plane y = END), snapped at 0.9 m up the blade: the khaki cap, the tassel and the far 0.72 m gone,
  the square break chipped. `:length` 1.12 → 0.9 m (only the art: the FK test's tip). Then (the user:
  「卍解刀身造型直接把始解修改成斷刀，然後把刀柄伸長 1.3 倍」「將刀柄向下伸長，使其變成原本的 1.3 倍」) its haft 1.3 times
  Nozarashi's, lengthened downward: 0.76 → 0.99 m, the top kept, the butt 0.23 m lower, 10 bindings for 8
  (`ke-mb-noz-head`'s HAFT argument; Nozarashi passes 1.0 and draws as before).
- Then both blades' heads turned 10° about the black bar's joint (§6.1, the user: 「請幫我以黑色協槓跟刀身的連接點為基準，
  將刀身順時針轉 10 度」, 「卍解斷刀和始解野晒都轉（推薦）」).
- The fringe (every form; the user on the Bankai's face still: 「我圈起來的那兩個刺刺頭髮畫反了，變成尖角朝下」): the two
  fringe cones hung tips down at the brow (pitch 160); first turned up from the hairline (pitch 25), then on the next
  stills the user: 「那兩根瀏海直接刪除」: both removed.
- The lips (the user: 「嘴唇不要用白色，換回紅膚色」): the face has no lip parts; the white bands round the mouth in the
  stills were the three expressions' teeth drawn at once: the viewer (`tests/duel-view.lisp`) passed a kit's `:hide`
  list as is, and a non-NIL `:hide` replaces the face list. The viewer now adds the other two faces' tags as the game's
  `hide-set` does; in the game each expression shows only its own teeth (neutral: one bar; shout: the upper and lower
  rows in the dark open mouth; hurt: the clenched rows) on the crimson skin.

### 8.2 The strikes (built)

Through `:clip-map` (the Bankai: the base J1 / J2 / K1 / K2 slots, RYOTE's K3, the meteor and the stance's cut; KATAUDE
its own map); every move's frames, reach and volume unchanged.

| Slot | Bankai | KATAUDE (bare-handed, the left) |
|---|---|---|
| J1 | `:ke-b-q1` a beast's hack, forehand off the right shoulder | `:ke-a-q1` a lunging left hook |
| J2 | `:ke-b-q2` the backhand hack, low, out to the right | `:ke-a-q2` the backfist across |
| K1 | `:ke-b-f1` ONATA: sprung from the crouch, a hatchet chop | `:ke-a-f1` the overhand haymaker |
| K2 | `:ke-b-f2` EGURI-AGE: laid on the floor, gouged up | `:ke-a-f2` the foot catch (dropped low, the left hand shoots out) |
| K3 | `:ke-b-f3` the leaping cleave from over the left shoulder | `:ke-a-spin` BUNMAWASHI, a spinning low sweep |
| SP1 | `:ke-b-split` TATE-GOTO, the leaping two-handed diagonal | `:ke-a-stomp` the leap down onto the right heel |
| SP2 | `:ke-b-fist` NAGURI-TOBASHI, now the left uppercut | `:ke-a-flurry` left fists, the uppercut last |
| L | `:ke-b-bite` the bite, now with a wrench (chest 45°, head 35°) | (the bite kept) |
| O | `:ke-b-cut` MAPPUTATSU's vertical from the leap | `:ke-a-haymaker` the wide left haymaker |
| stance | (`:ke-b-stance` kept) | `:ke-a-stance` the crouch, the right arm hanging, the left claw up |

Not done from the plan: the prowl walk and the roaring back-dash leap (the existing oni walk and guard kept).

Reach (art vs edge, the FK test; after the 0.9 m blade): Bankai J1 1.32 / 1.40, J2 1.33 / 1.40 (d −0.08, −0.07), K1
2.05 / 3.40, K2 2.28 / 3.00, K3 1.74 / 4.25 (the one-sided forms may fall short); KATAUDE J1 1.34 / 1.40, J2 1.22 / 1.40,
J3 kick 1.40 / 1.40, K1 1.59 / 1.96, K2 1.54 / 1.75, K3 1.34 / 1.89.

### 8.3 Checks

Presentation only, proved on the last commit of the round (the broken cleaver's 1.3× haft, the fringe removed):
`simgate.py --seeds 10 --summary` byte-identical to the base (cc40146) for all 21 pairings; `--cvc` 3 PASS (yy 134.1 s,
yk 103.7 s, kk 140.8 s, as before); `duel-rules-test` 6481 checks ALL PASS (the FK reach above, the KATAUDE weapon NIL,
the clip maps); `pkgcheck.sh duel` 0 / 0 / 0; `./build.sh duel` 0 warnings.

The head turn (§6.1) re-gated the same way: summary byte-identical, cvc 3 PASS, rules test ALL PASS, pkgcheck clean,
build 0 warnings. The playtest Artifact carries §8 and the turn (v37; the user: 「善哉，請幫我上 playtest」).

### 8.4 The prowl, the roaring back leap, the cinematic's torso (2026-10-09)

- The user (after the v37 playtest): 「做卍解的潛行走路和咆哮後跳」 (the two items of the §8 plan not yet built).
- The prowl (`*oni-prowl*` over `*oni-walk*`): the shared walk / strafe legs stay sunk into the crouch (`oni-keys`); above
  the hips each of the four keys now carries its own upper body: the shoulders roll with the steps (the chest twist
  −18° ↔ −2°, a first pass at 30° swung the trailing blade about too much), the left claw paws forward with the
  opposite foot (arm flex 74°, elbow 34°) and drags back (20°, 82°), the head low and swaying (±8°), the blade hand
  scraping; walking back the claw stays up in front; strafing it is held out, the head turned to the opponent.
- The roaring back leap (`:ke-b-step-b`, the oni's art for the shared Step back `:sh-step-b`, the same 0.4 s): sunk
  deep, then at 0.07 s flung up 0.4 m and back, the back arched, the head thrown back, the arms flung wide, the legs
  tucked; down on all fours at 0.28 s, the left claw on the floor; back into the crouch. The roar is the feedback
  layer's (`feedback.lisp` `:step`, looks and sound only): when the played clip is `:ke-b-step-b`, the shout face for
  0.4 s and `:oni-roar` (new: a saw near 80 Hz swelling a fifth and falling, jittered, through two vowel formants,
  driven). KATAUDE shares the oni body and so the prowl and the leap.
- The cinematic's torso (the user, on a still of the Bankai cinematic: 「卍解過場動畫的時候身體軀幹好像會先消失耶？」):
  `ken-bankai-cine` puts the base body back at f0 for the kneel, and the Bankai kit's hide list (with `:haori`) stayed
  on the model: since §8.1 every torso part of the haori is tagged `:haori`, so the base body lost its torso until the
  oni at f58. Now f0 also clears the model's hide list (`refresh-look` at f58 restores the Bankai's).- Checks: `simgate.py --seeds 10 --summary` byte-identical to the base, `--cvc` 3 PASS, `duel-rules-test` 6481 ALL PASS,
  `pkgcheck.sh duel` 0 / 0 / 0, `./build.sh duel` 0 warnings, the headless run clean; the cinematic's stills (35005,
  35040, 35070) show the haori torso until the oni.

