# Reworking an existing fighter: evidence from LILLE BARRO's post-playtest rounds

Source repo: `/media/8tsp/projects/ai-cl-game-test`. Evidence: `docs/duel/DUEL_LILLE.md` §22–§23 (decisions 16–56),
`docs/DEVLOG.zh-TW.md` §92–§135, `docs/research/lille-retrospective/digest.md`. "G" = generalizable, "P" = project-specific.

## 1. How the rounds ran (P → G)
- Feedback came as short zh-TW lines after a playtest of the private Artifact, often several in a burst, and often
  「請先跟我討論…後再修改」 (16–20, 44, 53). Each round: a cause, then options, then the docs, the build, the gates and a
  new Artifact version.
- Lettered options the user combined: 41 (A pierce mark / B 0-damage flinch / C snap / D slowing zone → C + a slow
  motion); 44 (A/B/C/D → A, N = 10 f); 50 (four directions, all chosen); 56 (a style plus four extras, all chosen).
- Parameters asked separately with defaults: 56b's slow-motion strength (1/5 → 1/3 → 1/2) and opening length (40 f).
- The user wrote the cinematic storyboard in prose over several messages (「我繼續講分鏡」). The lead held the build
  (SendMessage to the worker: "hold the camera"), appended each message to the doc, and sent the agreed beat sheet.
- A shot-by-shot text breakdown (10 shots with frames, angle, distance, height, lens) let the user name exactly what was
  wrong: 「第三幕太快」「第一幕也拉長」 (56b).

## 2. Presentation-only proofs (G)
- Every art round (§22.5, §23.5, §23.9, §23.19, §23.31, §23.37) saved a baseline (`simgate --seeds 10 --summary`,
  `--cvc`) before the change and compared byte for byte afterwards.
- When a cinematic's length changed match seconds (before the 2026-10-08 rule), the worker rebuilt with the old `:len`
  to prove the outcomes identical; wins and K.O.s were compared instead of medians.
- CINE-PLACE moves the actor for the shot and restores him in CINE-END; Lille's six pairings stayed byte-identical,
  which proves the restore.
- `:clip-map` (kit key, `KIT-MOVE-CLIP`): Jilliel KIN plays `:lb-w-sanren` for the shared move `:lb-sanren`, and the
  move name the AI and tests read is unchanged.

## 3. Sim-change rounds (P)
- TENSHIN chain (decisions 25 → 54): each distance change ran the six pairings at 20 seeds; LR / LI crossing 210 s
  meant 60-seed reruns and reports; 3 exceptions accepted in the user's words; 55 「不用調整，玩起來夠強了」.
- The fixed-speed rule (53): `lb-switch-dash-f` = ⌈60d/30⌉ capped at 14; distances in Step lengths; host tests pin it.

## 4. Regressions found after rule changes (G)
- 43: K → L, a latched L in a K string became a chained follow-up and the string chase pulled him forward (a 7 m back
  dash measured 0.88 m in the browser). Fix: the switch tick zeroes walk/chase every frame.
- 52: a shorter dash changed nothing because the link chased (≤ 40 m/s): measure the actual travel.
- §23.36: after 53 the ASSIST's TENSHIN in → J1 missed: (1) `lbs-dash-end` was stale from the last switch when the 2 f
  cancel entered at f14 and the ASSIST (deciding one step early) read it; (2) a dash shorter than 6 f ended before the
  form change. Fix: the pure `lb-link-frame-at` reads the dash end only after `:go`; the form changes before the link;
  the link plan uses the switch's target form. Reproduced with AUTO COMBO forced by `localStorage soulduel.autocombo`.
- 24: the onehand rule "an up-flick during a move is a Hoho" fired inside the stance (a move): generic `:step-branch`.

## 5. Merge lessons (G)
- Two art batches both used `*LB-WF*` [64]–[66]; the owl's moved to [68]–[70] at merge (§23.37 "Merged").
- A worker "fixed" a decided colour; diff against the decision list.
- After the merge the lead re-ran the host tests, `pkgcheck`, the build, `--cvc`, the seed gate, and the browser
  scripts with the consing probe, then republished the Artifact.

## 6. Cinematic rework checklist (P → G)
- Placement: CINE-PLACE at a fixed gap (6 m for Jilliel's Kikon).
- Aspect ratios: landscape draws a 9 % letterbox (hud.lisp), so keep the subject's head ≤ 0.35 of the half-height below
  centre on landscape. Portrait widens the lens and backs off (%PORTRAIT-DOLLY); keep its framing when the user likes it.
- Time: CINE-SLOW for hits (actors and effects), with the script's frames running on; the effect-time tables must use
  the same clock.
- Scale: CINE-SCALE multiplies the rig; scale every metre-authored size in the draw hook by hand.
- Stills: debug `79200 + f`, contact sheets per beat, both aspects.
- Gate time excludes cinematics since 2026-10-08 (DEVLOG §134); the 125–210 s window predates that.

## 7. Model edits by stills (decision 57, the face) (G)
- The user iterated the head in ten short requests, stills only (「做完後先不要跑對局測試，直接拍影像給我看」): build, debug
  79198 + 79199 (front, side), a cropped sheet; WIP commits on the dev branch; the gates and docs once the look settled.
- For a position or size, shoot a candidate sheet (0 / −2 / −4 / −6 cm side by side, front and side): the user picked
  a value between two (−3 cm) in one reply.
- Restate shape words against the profile: 「頂部往下降」 meant keep the foot, lower the top. A part placed inside another
  shows only what sticks out (a trapezoid nose whose block sat inside the skull read as a triangle): check the side still.
- A squashed (ellipsoid) head needs its features squashed with it: `:squash` scales the placement too.
