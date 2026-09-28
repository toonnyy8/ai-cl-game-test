# SOUL DUEL: ENDLESS 無限連戰 (a gauntlet of CPU stages)

Status: **built 2026-09-29.** The design of 2026-09-29 with the user's decisions of the same day ("User decisions" below),
which override the body where they differ. Code: `duel/lisp/endless-rules.lisp` (pure rules, host-tested) and
`duel/lisp/endless.lisp` (the run, its screens, the record, the debug entries); the shared files only carry hook lines
(DUEL_DESIGN.md "Character code layout" applies to modes too). The as-built deviations are in "Built: deviations" at
the end.

## Summary

- **Entry**: MODE row 2, **ENDLESS** (under VS CPU). P1 picks a character, then the **START DIFFICULTY** (EASY / NORMAL
  / HARD: the ramp's floor). One-handed exactly like VS CPU (the ONE-HAND setting decides).
- **Between stages**: after a K.O. (or a time-up win) the **STAGE CLEAR** screen shows the stage's and the run's time,
  Konpaku +2, what carries over and the next stage. Rows: CONTINUE / REVERT (only when awakened) / QUIT.
- **Carry-over** (P1): Reishi full; Konpaku +2 (at most 9); Reiatsu and flash step kept; the guard gauge full; an unused
  awakening gauge kept. REVERT: back to the base form with the awakening gauge full (EVOLUTION at FIGHT), kit meter 0.
- **Staying awakened**: Yamamoto's Bankai always starts in East; Hellfire (a timed form) ends at the clear. **Kenpachi, in
  any awakened form (every cup, Bankai, 片腕), starts the next stage in Nozarashi cup 1 KATATE at NOME 10**, the arm UDE
  gone (the user's decision). Rukia goes back to −18 °C, cold 0 (as at every Kikon reset).
- **Kenpachi's Bankai** is available once per stage (cup 3 comes back through the climb), not once per run. Its cost
  carries: Konpaku 1 → 3 at the clear.
- **Opponents**: a seeded shuffled bag: each character once per bag, never the same opponent twice in a row, mirrors
  allowed. The CPU difficulty rises one level every two stages up to HARD; from stage 5 the opponent starts with half an
  awakening gauge, from 7 a full one, from 9 already awakened; its Reishi +10 % from 9 and +20 % from 12. The ramp
  stops rising at 12.
- **Score**: stages cleared, ties broken by the run time (battle sim time of the cleared stages). One best record per
  character in the page's localStorage (`soulduel.endless.<slot>`, every access in try/catch), written at every clear
  that beats it. Debug runs never write.
- **HUD**: `STAGE n` under the timer (landscape), left under P2's block (portrait; the pause chip is on the right).

## 1. Flow

**MODE**: VS CPU / **ENDLESS** / PRACTICE / VS PLAYER / CPU VS CPU / SETTINGS / CONTROLS. ENDLESS sits next to VS CPU
because both are one human against the CPU. `*mode*` = `:endless`; `vs-cpu-p` includes it, so the behind camera, the
CAMERA option and **one hand** (wherever the ONE-HAND setting is in effect; `*one-hand*` is set for the rows VS CPU /
ENDLESS / PRACTICE) come along without new code.

**SELECT**: phase 0 (P1 picks) goes straight to phase 2 (back from phase 2 returns to phase 0). Entering SELECT draws the
run seed from the clock (`endless-new-seed`, the `go-select` hook), and the plaza's P2 model is the run's stage-1
opponent. Phase 2 is **START < EASY / NORMAL / HARD >** (the select screen's CPU row relabelled) and, with two hands, the
CAMERA row. Confirm → `endless-start`.

**Per stage**: INTRO (5 s, skippable as always) → BATTLE → FINISH (the K.O. or TIME cinematic) → **CLEAR** (a P1 win,
flow state `:clear`) or the run's **RESULTS** (a loss, a draw, RETIRE).

**Pause** in ENDLESS: RESUME / **RETIRE** (/ CAMERA with two hands). No RESTART (it would re-roll a bad stage), no
CHARACTER SELECT or TITLE (the results have them one row away). One hand pauses as before (the II chip, the back gesture).

## 2. STAGE CLEAR (flow state `:clear`)

After the K.O. cinematic `go-results` poses the fighters as usual; its one-line hook (`endless-stage-end`) sends a won
stage to `:clear` instead of the results. The screen is a black card in the results' layout (landscape: the left panel;
portrait: the lower part, the winner above it; `menu-camera` shows `:clear` with the results' shot):

```
STAGE 3 CLEAR
TIME 1:42   RUN 5:10
KONPAKU  5 -> 7
REISHI FULL   GUARD FULL
REIATSU  FLASH STEP  KEPT
NEXT  STAGE 4  KUCHIKI RUKIA  HARD          (ember)
AWAKENED AT FIGHT  REISHI 110%              (the ramp's next step, when there is one)
BANKAI -> KATATE                            (ember: what the selected row does)
> CONTINUE
  REVERT
  QUIT
```

- **Awakened**: three rows. An ember line over the rows says what the selected one does. CONTINUE names the carry:
  `STAY <form>` when the form stays (`STAY BANKAI-EAST`, `STAY KATATE`, `STAY -18C`), else `<form> -> <form>`
  (`BANKAI-WEST -> BANKAI-EAST`, `BANKAI -> KATATE`, `NOMIHOSE -> KATATE`, `-273C -> -18C`); REVERT reads
  `BACK TO BASE  AWAKENING FULL`, QUIT `END THE RUN`.
- **Not awakened**: CONTINUE / QUIT.
- The cursor starts on CONTINUE; the rows take input after 1.0 s (a masher doesn't skip the screen). Taps work on the rows
  (`hud-menu`). Back / Esc does nothing here.
- QUIT goes to the run's RESULTS. The record was already saved at the clear.

## 3. Opponents and the ramp

**Who** (`endless-opponent seed stage roster`, pure): the stages come in **bags** of |roster| (3 today; the roster is read
at run time, so new characters join the bag by registering a `:base` kit). Each bag is a Fisher–Yates shuffle of the
roster driven by the bag's own LCG keyed on (run seed, bag index); when a bag's first entry equals the previous bag's
last, its first two swap. Every character appears once per bag and never twice in a row; P1's own character is in the
bag (mirror matches, P2 tinted). The LCG is not `sim-rnd`, so the order never depends on the fights.

**How hard** (`*endless-ramp*`, data in endless-rules.lisp, read per stage):

| Stages | CPU difficulty | Opponent's awakening at FIGHT | Opponent Reishi |
|---|---|---|---|
| 1–2 | floor | gauge 0 | 100 % |
| 3–4 | floor + 1 | 0 | 100 % |
| 5–6 | floor + 2 | **50** | 100 % |
| 7–8 | floor + 2 | **full** (EVOLUTION at FIGHT; its CPU `:awaken` rule decides when) | 100 % |
| 9–11 | floor + 2 | **awakened** (spawned in its awaken form, no cinematic, the form's meter at its `:start`) | **110 %** |
| 12+ | floor + 2 (**plateau**) | awakened | **120 %** |

- The difficulty clamps at HARD: an EASY floor reaches HARD at stage 5, NORMAL at stage 3; a HARD floor only gets the
  awakening and Reishi steps.
- The CPU knobs are the existing per-difficulty plists; the ramp sets P2's `brain-difficulty` and `brain-delay` after
  spawning (`endless-apply!`). No new AI code.
- The Reishi % sets P2's `gauges-reishi-max` and `gauges-reishi` (red is 30 % of max; the HUD bars are fractions).
- The opponent always has 9 Konpaku and full gauges.
- **Why a plateau**: without one the run ends because the numbers outgrow the player, not because the player fails.
  After 12 the record measures consistency: every stage costs Konpaku on average and the +2 per clear pays back part.

The timer stays 300 s. At time-up the normal rule applies: a P1 win clears the stage; a draw or a loss ends the run.

## 4. Carry-over (P1; `endless-carry snap choice`, pure)

The next stage spawns a **fresh** P1 (`spawn-pair`, as every match does) and applies the carried plist. Anything not
listed starts fresh: cooldowns, frost, combo counters, the stance's stored damage, cup-3 entry counts, the arm's
pending burst.

| Resource | Next stage | Note |
|---|---|---|
| Reishi | **max** | the user's rule |
| Konpaku | **min(9, k + 2)** | the user's rule; Cornered follows from it |
| Reiatsu | **kept** | the user's rule |
| Flash step | **kept** | the user's rule |
| Guard gauge | **full**, guardless cleared | decision 1: as at every Kikon reset |
| Awakening, not awakened | **kept** (EVOLUTION re-announced at FIGHT when full) | decision 2 |
| Awakening, **stay** | awakened, gauge 0 | as in the match: it stops filling once used |
| Awakening, **revert** | form `:base`, not awakened, gauge **100** | the user's rule; P awakens at will (cinematic, heal, NOME 10 as in any awakening) |
| Kit meter, stay / not awakened | **kept**, except: the form has an `:endless-form` or a `:reset-form`, or the carry changed the form → the new form's `:start`, else 0; a `:count` meter → 0 | the Kikon-reset rule, so a clear never gives more than a reset |
| Kit meter, revert | 0 | the base forms' meters start empty |

**The stay form** (`endless-stay-form kit`): `(or (kit-endless-form kit) (kit-reset-form kit) (and (kit-duration kit)
(kit-inherit kit)) (kit-form kit))`:
1. `:endless-form` (a kit key, data in the character files; inherited like every key): Kenpachi's `:nozarashi` (so
   RYOTE, NOMIHOSE and the Bankai inherit it) and `:kataude` → `:nozarashi`; Yamamoto's `:bankai-east` (and West,
   inheriting it) → `:bankai-east`.
2. `:reset-form`: Rukia's bands → `:m18`.
3. A timed form ends the way its timer would: Hellfire → `:base` (Inferno 0).
4. Otherwise the same form.

| | Stay (CONTINUE) | Revert |
|---|---|---|
| **Yamamoto** | Bankai **East** from either stance; the guard gauge full (the pierce at its sharpest) | Shikai, Inferno 0, awakening full |
| Yamamoto, not awakened | Shikai, **Inferno kept**; Hellfire at the clear → Shikai, Inferno 0 | — |
| **Kenpachi**, any awakened form | **Nozarashi cup 1 KATATE, NOME 10** (the awakening's own entry state); the UDE pips gone | base, awakening full |
| **Rukia** | **−18 °C, cold 0** | Shikai, awakening full |
| Characters from later branches | the generic rule; a second-awakening form must set `:endless-form` (the host test's guards) | base, awakening full |

## 5. Kenpachi's Bankai in a run

- **Once per stage, not once per run** (decision 4). The Bankai is once a match by construction (only cup 3 has
  `:bankai-form`); the carry puts him back in cup 1, so each stage can have one Bankai. No new flag.
- **The cost carries.** The Bankai sets Konpaku → 1; a clear gives +2 → **3**; the next stage starts in cup 1, NOME 10,
  Reishi full. At 3 Konpaku he is Bankai-eligible as soon as he reaches cup 3 again. A Bankai every stage keeps him at
  **1 ↔ 3**: any Kikon of an awakened opponent or any Soul Break ends the run. The gamble limits itself.
- **Bankai, then a lethal trade** (both souls out) is a draw: the run ends.

## 6. Game over and results

- **The run is over** when a stage is lost, drawn, retired (pause) or QUIT (STAGE CLEAR).
- **Score**: **stages cleared**, tie-broken by **run time** (the sum of `*match-tick*` over the cleared stages: battle
  sim time only, deterministic, no menus or cinematics).
- **RESULTS** (the results scene; a retired stage poses P1 as the loser): `ENDLESS  <name>`, `STAGES CLEARED n`,
  `TIME m:ss`, `BEST n  m:ss` (or `BEST -`), a blinking `NEW RECORD` when this run wrote the record, the run's totals
  (DAMAGE, KIKONS, PERFECT HOHOS, BEST COMBO; summed from each stage's gauges at its end, BEST COMBO the maximum) and the
  opponents faced by initial (`K R Y K X`: X = the last one ended the run). Menu after 2.5 s: **NEW RUN** (a new seed)
  / CHARACTER SELECT / TITLE.
- **Best record, per character** (decision 6), through the page bridge: page get / set **30 + 2i** = stages and
  **31 + 2i** = seconds of roster index i (i < 10), stored by `duel/web/pwa.js` as **`soulduel.endless.<k − 30>`**
  (`soulduel.endless.0` / `.1` = the first character's stages / seconds, `.2` / `.3` the second's, ...). Every access is in
  try/catch: missing or blocked storage reads 0 (no record). Written at every clear that beats the stored best
  (`endless-better-p`: more stages, else less time), so closing the tab mid-run keeps it. Debug runs never write
  (`*endless-debug*`). The index is stable while the roster stays append-only (kit files add characters at the end).

## 7. HUD

- **Landscape**: `STAGE n` in 2 s dim text centred under the timer (0.13 h), the PRACTICE tag's style.
- **Portrait**: `STAGE n` in 1.2 s dim text, left-aligned under P2's block (x = 4 s, y = the block's bottom + 1 s): the
  pause chip is under the block on the right (358, 200 CSS px).
- STAGE CLEAR and RESULTS have landscape and portrait layouts (the portrait card in the lower part, the rows at 0.8 h,
  under the thumb, like every portrait menu).
- `*stage-strings*` caches the tag's strings (like `*timer-strings*`); the screens' strings are made once per screen.

## 8. Determinism, log, debug, tests

- **Seeds**: the run seed comes from the clock (menu) or is fixed (debug). The stage seed is `endless-stage-seed run
  stage`, a pure mix that feeds `sim-rnd-seed`. The bag and the carry are pure, so stage n replays from (seed, n, the
  carried plist) and P1's inputs.
- **Log lines**:
  - `duel endless start seed S P1 c floor d [debug]`
  - `duel endless stage n vs c diff d reishi r awaken a seed s P1 form f konpaku k awaken w meter m`
  - `duel endless clear n konpaku a->b choice stay|revert form f->g meter m ticks t`
  - `duel endless over stages n secs t best n2 secs t2 record T|NIL`
  - autopilot: `duel endless gate P1 c policy p runs r median m stages (...)`
- **Debug commands** (80000–80999; the character branches avoid this range):

| N | Effect |
|---|---|
| 80000 + 100c + n | a debug ENDLESS run from **stage n** (1–99), P1 = roster c (human), run seed 1, P1 fresh, the intro skipped, no record |
| 80980 | clear the running stage now (P2's last Konpaku: the K.O. path → STAGE CLEAR) |
| 80981 | P1 into his kit's form with a `:bankai-form` (cup 3), Konpaku 4, then that Bankai (`bankai!`): the §5 test |
| 80982 + k | P1 into his kit's k-th form (definition order, 0 = base; meter full, awakened as the form is), then 80980: STAGE CLEAR with that form's carry (Kenpachi: 1 NOZARASHI … 4 BANKAI, 5 KATAUDE; Yamamoto: 1 HELLFIRE, 2 EAST, 3 WEST; Rukia: 1 −18 … 3 ZERO) |
| 80990 + p | **autopilot** gate: P1 a HARD CPU, STAGE CLEAR picks policy p (0 stay, 1 revert), turbo, cinematics skipped, every character × seeds 1–20 at a NORMAL floor; `duel endless over` per run and one `duel endless gate` line per character |
| 80992 + p | the autopilot once: P1's current pick, seed 1 |

- **Host tests** (`tests/duel-rules-test.lisp` loads `endless-rules.lisp`): Konpaku 1→3, 7→9, 8→9, 9→9; Reiatsu and
  flash step bit-identical for every form; not awakened: the awakening and Inferno kept, Hellfire → base, meter 0;
  revert for every awakened form of every character; stay: East / West → East, every Kenpachi awakened form → cup 1 at
  NOME 10, Rukia's bands → −18 at cold 0; the generic guards (every stay target awakened, none a `:bankai-form` or a
  `:pips :to`, no timed stay target); the §5 arithmetic; the ramp (monotone, clamped at HARD, flat from 12); the bag
  (each bag the roster once, no repeat across bags for seeds 1–200 and rosters of 2, 3 and 5, replayable, seeds differ);
  `endless-better-p`. The name-leak check covers both endless files.
- **Scripts** (`tests/scripts/duel.py`; DUEL_GAMEPLAY.md's script table): `duel-endless.json` (landscape, keyboard, the
  menu run: CONTINUE, REVERT, the Bankai's auto-revert, RETIRE, NEW RUN reading the record, then the autopilot once) and
  `duel-endless-portrait.json` (portrait, taps). `duel-endless-gate.json` runs 80990 (the pacing check, a long run).
  `python3 tests/endless-sheet.py` builds the contact sheet from their stills.

Not built (YAGNI): a points formula, previews of later opponents, stage select or continue tokens, VS PLAYER endless,
online boards.

## User decisions (2026-09-29)

- Questions 1, 2, 4, 5 and 6 of the design: **the recommended defaults** (the guard gauge full at every stage; an unused
  awakening gauge kept; the Bankai once per stage; the ramp as proposed; one best record per character).
- **Question 3 changed: Kenpachi does NOT keep his NOME cup.** Whenever he carries an awakened form into the next stage
  (Nozarashi at any cup, the Bankai or 片腕) he starts at **Nozarashi cup 1 KATATE, NOME 10**, UDE cleared: every
  awakened Kenpachi form maps to `:endless-form :nozarashi`.

## Design notes kept from the review

1. **For Yamamoto and Rukia REVERT dominates stay**: the gauge is kept full, so stay only saves a cinematic, and revert
   also allows holding the awakening back. The choice matters most for Kenpachi (revert banks his +150 awakening heal).
   Accepted: the user asked for the choice, not for balance between the two.
2. **Running out the clock**: time-up wins clear stages, and ENDLESS rewards not losing Konpaku; watch the autopilot's
   time-up count.
3. **Reiatsu and flash-step carry mostly doesn't matter**: both regenerate at 3/s, so it only changes the first seconds.
4. **The Reishi steps lengthen stages** (120 % ≈ 30 s more); they affect the ENDLESS opponent only, never the seed gate.
5. **Brittle points**: the record slots depend on an append-only roster; a branch character with a second-awakening form
   must set `:endless-form` (the host test's guards catch the `:bankai-form` / `:pips` pattern, not every future one).

## Built: deviations

- **QUIT keeps P1's win pose** on the RESULTS (he did clear the stage); only RETIRE, a loss or a draw pose him as the loser.
- **NEW RECORD is blinking ember block text**, not a brush stamp (the brush set has no glyphs for it).
- **80982 + k takes the k-th form of P1's kit** instead of a fixed preset list, so the debug file names no character.
- **80992 + p** (the autopilot once) was added for the scripted run; the design had only the 20-seed gate.
- `endless.lisp` compiles after `debug.lisp` (not right after `onehand.lisp`): it reads the debug's `*turbo*`.
- **The carry is named on a note line** over short rows (CONTINUE / REVERT / QUIT) instead of in the CONTINUE row:
  `CONTINUE  BANKAI-WEST -> BANKAI-EAST` did not fit the landscape panel.
- `main.lisp`'s `menu-camera` got one key (`:clear` joins `:results`), and the select screen's CPU row reads START.
