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
  (`ken.lisp`, `:arc 360`, crumple): a thrust would draw a front-only strike that hits behind him too. Moving the thrust
  needs the user's call (a sim change to K3's volume, or another slot).
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
