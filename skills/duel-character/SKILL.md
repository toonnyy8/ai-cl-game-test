---
name: duel-character
description: Use when designing and building a NEW fighter for a 3D arena fighter like SOUL DUEL (a roster character with forms, awakenings, stances, modes, a Kikon cinematic, CPU and assist routes) — from the first concept talk through rig, clips, systems, CPU and cinematics — especially when the user judges by playtest feel and wants the design intent settled before building.
---

# Designing a new fighter

## Overview
Distilled from LILLE BARRO in `toonnyy8/ai-cl-game-test` (local `/media/8tsp/projects/ai-cl-game-test`), the user's
most satisfying character: 56 decisions in 3 days, 41 of them after playtests. Core principle: **settle intent and
units before building; let the user tune feel numbers in play; keep every art round presentation-only and prove it
byte-identical.** The churn concentrated in feel numbers (a dash distance changed 8 times, a slow motion 6 times) and
silhouettes; intent, once asked, rarely moved. Evidence: `reference.md`; the zh-TW guide
`docs/guides/CHARACTER_DESIGN.zh-TW.md`; the full record `docs/duel/DUEL_LILLE.md`, digest
`docs/research/lille-retrospective/digest.md`. For changing an existing character use `duel-character-rework`;
the general loop is `game-dev-workflow`.

## ⚠ Confirm before building (AskUserQuestion, 2–4 options, recommended first, record the rejected ones)
Concept
- **Role against the whole roster**: "what does he do when caught at 2 m?" Probe with a 10-seed time-at-range run
  before tuning. (A "pure sniper, no escape" spent 83–93 % of time under 6 m; two rule rebuilds followed.)
- **Every form reachable in PRACTICE** (a beheading-gated revival could not be playtested).
- **Later awakenings: same system stronger, or a new kit?** (The owl was rebuilt onto Jilliel's system.)
- **Which existing system can this reuse** (Yamamoto's West ward, Ichigo's stance, Kenpachi's Bankai path)? Reuse is
  quick to build, leaves the rest of the roster alone, and is already balanced by precedent.

Mechanics
- **Every movement move**: where it stops relative to the opponent, fixed time or fixed speed, distances in Step
  lengths, and whether the follow-up link travels. **List every hidden movement** (Breaker chase, lunge, string chase).
- **Pacing price and every cancel route** checked adversarially (an empty swing bought a free 2 f cancel).
- **Delayed damage**: when should it reliably land, and what should the opponent do about it?
- **Feel effects** (slow motion, snaps): what are they for, and what triggers them (per line, per region, fresh vs
  old)? Expose the numbers as live knobs; don't predict them.
- **Anything that changes the gate clock** (time scale, cinematic length). Match time excludes cinematics since
  2026-10-08.

Model and look
- **Which part hits, are the arms visible**: show a hit-frame still from the default behind camera. Don't parent a
  visible weapon to the arm chain; keep the rig's strike point invisible and draw the weapon to it.
- **Large translucent or foreground parts must not hide the fight**; check the leg topology with a side still; decide
  whether the modes read apart at a glance.
- **The motion bar**: does every strike get its own silhouette and whole-body motion? Name a reference clip set and use
  that bar for every form.

Presentation
- **A text storyboard first**: a beat table with frames, camera (angle / distance / height / lens) and action.
  **Place the actors** at the start (CINE-PLACE) and check both landscape (letterbox 9 %) and portrait.

Wording
- **Restate relative or colloquial quantities as numbers and get a yes** (「放慢 1 倍」 meant 0.1×; "extra arms" was
  relative; 「閃步」 meant only Hoho).

## Build order
1. Concept talk (no code), canon research with graded claims, a model sheet from reference images. Agents can set up the
   environment in parallel.
2. Full design doc plus an adversarial review (it caught the aim-lock blocker).
3. Batch 1: a playable version (rules, CPU reflexes, functional art at the right reach). Measure range time and wins.
4. Playtest Artifact loop: one private URL, updated each round. Explain causes, offer 3–4 lettered, composable
   directions, and label your proposed numbers as proposals.
5. Art batches, presentation only: `simgate --seeds 10 --summary` and `--cvc` byte-identical, the FK reach test
   ±0.15 m (a cast check for moves with no hit window), 0 B/frame from the debug probe, before/after contact sheets from
   two cameras.
6. CPU (dream-rsi), ASSIST routes, learning situations, **only after the rules freeze**: Lille's search was re-frozen 3
   times because the rules kept changing.
7. Cinematics last, from the agreed storyboard.

## Implementation rules
- Two files per character (`<char>.lisp`, `<char>-art.lisp`). Shared files only get generic hooks that default off
  (`:lift`, `:clip-map`, `:intangible`, `:assist-combo`, CINE-SCALE / -SLOW / -PLACE); prove them off with the other
  pairings byte-identical.
- Each form gets its own clips at its own frames. Never reuse a sibling form's clip sped up with `:clip-s`.
- Every new mechanic gets a CPU rule (EASY ≤ NORMAL ≤ HARD), an opponent reflex key, an ASSIST route, a learning
  situation and use counters.
- Pin combo arithmetic in host tests (stun ≥ dash + link startup on every path).
- When a gate fails, report it; don't retune other knobs. The user's play decides (exceptions quoted in AGENTS.md).

## Red flags
- "I'll pick a distance and gate it" before asking the motion model → ask the units, expose the knob.
- A subagent "improved" a decided value (gold #B89A5A → #CDB47A) → diff the merge against the decision list.
- Two batches claim the same shared slot (`*LB-WF*` [64]–[66]) → check scratch-vector indices at merge.
- Shots framed only at the stills' distance or only on one aspect ratio.
- A dream-rsi search started while rules still move.
