# Designing a new fighter: evidence from LILLE BARRO (2026-10-06 → 10-08)

Source repo: `/media/8tsp/projects/ai-cl-game-test`. Evidence: `docs/duel/DUEL_LILLE.md` (§n), `docs/DEVLOG.zh-TW.md`
(DL§n, §84–§135), `docs/research/lille-retrospective/digest.md` (the full 56-decision timeline, rework chains and
numbers). "G" = generalizable, "P" = project-specific. The zh-TW guide for the user: `docs/guides/CHARACTER_DESIGN.zh-TW.md`.

## 1. The numbers (P)
- 56 numbered decisions (40 on day 1), plus about 8 unnumbered rulings. 1–15 were settled before code (10
  AskUserQuestions with 3 options each, 4 on the design review); 16–56 came after playtests.
- The longest chain: TENSHIN's distance, 3.5 → 8 → 10.4 → 13 → 10 → 4.5 → 5.5 → 7 m over about 13 decisions and
  11 twenty-seed gates. Then the crossing slow motion, 6 decisions, 7 gates, 2 CPU-search re-freezes.
- Gates: ~28 twenty-seed runs, ~12 sixty-seed reruns, 5 accepted exceptions. Host checks 4431 → 6479.
- No balance knob was turned after batch 4: every later shift came from the user's design decisions.

## 2. Rework chains and the question that would have saved each (G)
| Chain | Why earlier versions went | Ask, and when |
|---|---|---|
| TENSHIN distance (§23.2–§23.34) | Feel tuning; a hidden link chase (Breaker J1/K1 rule) made the dash length meaningless (52 → 53) | Stop distance, fixed time or speed, Step lengths, does the follow-up travel; list hidden movement. Design pass, and again when a link is added |
| TENSHIN price (30, 34, 35) | An empty swing bought the 2 f cancel | What stops spamming; adversarial pass on each cancel. Design pass |
| Slow motion (41–47) | Trigger semantics never specified; ambiguous 「放慢 1 倍」 | Signal or reaction window; per line or per region; live knobs. Before building any feel effect |
| Trace landing (18, 39, 41) | The 1-damage laying shot was a hidden stun-lock and gave the CPU an unfair opener | When should it hit, what does the opponent do. Design pass |
| Base sniper (1 → 17, 21–23) | A no-escape sniper cannot hold range against rushers | "Caught at 2 m?"; a 10-seed time-at-range probe. Concept stage |
| Jilliel's wings (19, 27, 32, 50, 56) | Arms read as wings; wings hid the fight; too stiff; strikes didn't read | Which part hits, arms visible, behind-camera still, the motion bar. Model sheet / rig stage |
| Owl legs (20, 26) | A misread reference | Side still of the topology. Model sheet |
| Owl system (36) | A separate kit read as another character | Same system stronger or new? Concept stage |
| Revival (8 → 16) | PRACTICE could not reach the owl | How does a playtester reach each form? Design pass |
| Kikon cinematic (56, 56a–c) | Framed at 6 m only; desktop letterbox | Actor placement, both aspect ratios, text storyboard. Storyboarding |

## 3. Process patterns that worked (G)
- Phase 0 a pure discussion; agents set up the toolchain and research meanwhile (DL§84).
- AskUserQuestion with 3 options each; the rejected options recorded (§1).
- A full design doc plus an adversarial review before code (§2–§16, 22 findings; the aim lock came from it).
- Canon research with graded claims, plus a model sheet from 49 reference images (§17).
- Playtest via a private Artifact of the whole game, one URL updated each round (DL§91); deploy only on request.
- Explain the cause first, then 3–4 lettered, composable directions. The user often picks "all" or combines them
  (41: C + slow motion; 50 and 56: all four).
- Proposals labelled as the lead's; the user corrects cheaply (37, 43).
- Text storyboards: the user's prose became beat tables, and a shot-by-shot breakdown prompted amendment 2 (§23.37).
- Worktree fan-out by independent batch with a lead merge; the lead re-runs every gate. Merge pitfalls: the K fan
  hitting three times (fixed at merge, §22.6), a scratch-vector slot collision (§23.37), a subagent overriding decision
  11's gold (§21 dev. 4).

## 4. Design patterns (P → G)
- Reuse system shapes: MUJITTAI = Yamamoto's West + `:intangible`; the stance = Ichigo's TSUKIMACHI; the revival =
  Kenpachi's Bankai path + `:bankai-ok`; the eye = the perfect-Hoho threat test.
- Two modes on one button: EN lays damage-less traces; L materialises them and dashes, giving lay → materialise → dash
  → J. A flash-step economy (3 a line, refund 4 / 2, KIN → EN 10) paces it. The CPU search found the loop itself.
- A transform chain where later forms share the system with small edges (×1.1, refund 5, +1 f).
- The opponents' reflex keys read off his kit (`:opp-trace`, `:opp-reflect`).

## 5. Modelling notes (P → G)
- Four bodies on the 21-joint rig; the same hurt cylinder in every form (r 0.38, h 1.8); the float is drawn only.
- `:lift` kit key, not baked into clips (shared clips play at root 0, so he sank, decision 33); the leg floor subtracts
  BODY-LIFT.
- Strike point = an invisible rig hand; the visible weapon is drawn to it (Rodrigues; a 0.00000 m miss).
- Translucency: an emissive glow × own colour instead of alpha < 1's dark phantom; glass 0.35, rim 0.6.
- Jointed blades (3 segments): lag springs (ω 16, ζ 0.45) + a virtual strike drive; the other wings converge on a ring
  target; tip trails via VFX-SMEAR.
- Clip keys commented as aims (azimuth/elevation in the chest frame); FK-solved claw poses for long arms.
- Pitfalls: stance poses move strike points (hit poses set spine, arm and elbows); spins need two keys 0.0001 f apart
  with yaw 360° apart; the lift steps when the form changes mid-dash (hide it in keys); scaled actors need every
  metre-authored size scaled by hand; big foreground parts loom in the behind camera.

## 6. Systems and the CPU (P → G)
- The X-Axis needed the generic threat test to use point-to-line distance and the real active window, for `:x-axis`
  only, so the old pairings stayed identical (§2 G1).
- Every new mechanic: a CPU rule per difficulty, an opponent key, an ASSIST route (`:assist-combo`), a learning
  situation (`learn-def-kit`), counters.
- The dream-rsi CPU: freeze the evaluator; new behaviour HARD-only so NORMAL stays bit-identical; freeze the rules first
  (3 re-freezes cost every cell a 3-way merge).
- Interaction bugs to expect: touch flicks vs stances (`:step-branch`), string chase during a dash (K → L, 0.88 m vs
  10 m), a stale dash end read by the ASSIST a step early (§23.36). Test by hand and with the ASSIST in the browser.

## 7. Cinematic tools (P)
- CINE-PLACE (actors at a set gap, given back at CINE-END however it ends), CINE-SCALE (an actor drawn ×N),
  CINE-SLOW (clips and effect time scaled; script frames run on), the white card + silhouette, debug `79200 + f` to hold
  a frame. Landscape has a 9 % letterbox; portrait widens the lens (%PORTRAIT-DOLLY).
