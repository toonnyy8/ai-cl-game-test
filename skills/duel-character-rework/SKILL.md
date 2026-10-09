---
name: duel-character-rework
description: Use when changing an EXISTING fighter in a deterministic arena fighter like SOUL DUEL after a playtest — a move "doesn't read", a dash feels wrong, a cinematic is too fast, the ASSIST misses a link, a form looks the same as another — especially when the request is short zh-TW feedback and the user wants to discuss options before anything is changed.
---

# Reworking an existing fighter

## Overview
Distilled from LILLE BARRO's 41 post-playtest decisions in `toonnyy8/ai-cl-game-test` (local
`/media/8tsp/projects/ai-cl-game-test`; DUEL_LILLE §22–§23, DEVLOG §92–§135). Core principle: **find the cause and the
intent first, offer composable options, then make the smallest change. If it is presentation only, prove the sim is
byte-identical; if it touches the sim, gate it against a parent baseline.** Evidence: `reference.md`; the zh-TW guide
`docs/guides/CHARACTER_DESIGN.zh-TW.md`. A new character uses `duel-character`.

## The loop
1. **Quote the feedback verbatim**; if the user said 「先跟我討論」, change nothing until it is agreed.
2. **Diagnose before proposing.** Reproduce in the browser (`tools/run.mjs --script`, debug setups, hash lines,
   the combat log), by hand and with the ASSIST. State the cause in one paragraph. ("Why does J1 after the dash also
   dash?" → the hidden link chase → decision 53.)
3. **Restate the request as numbers or a beat table** when it is relative or about feel (「放慢 1 倍」 = 0.1×?). For a
   cinematic, give a shot-by-shot breakdown (frames, angle/distance/height/lens, action) so the user can point at a shot.
4. **Offer 2–4 lettered, composable directions** (AskUserQuestion, recommended first). The user often takes "all" or
   "A + D"; add a follow-up question for the parameters (strength, length) with defaults.
5. **Docs first**: the design § (verbatim quote, the options, the choice) and a DEVLOG §, committed before the build.
   If the user keeps talking ("我繼續講分鏡"), append to the same § and hold the build.
6. **Classify the change**:
   - **Presentation only** (clips, rig, VFX, camera, cinematic shots): `simgate --seeds 10 --summary` and `--cvc` must
     be byte-identical to a baseline saved before the change. A cinematic's length doesn't move the gate numbers
     either, since gate time excludes cinematics. Use `:clip-map` to give one form a different clip for a shared move.
   - **Sim change** (frame data, distances, links, economy): run the character's pairings at 20 seeds against the
     parent; a median outside 125–210 s → 60 seeds; still outside → report and let the user decide. Don't retune
     other knobs.
7. **Fan out independent batches** in worktrees; brief each with the user's decisions and the identity check. At merge,
   check shared scratch-vector slots, generic hooks and decided values (a subagent changed decision 11's gold).
8. **Verify like a player**: host tests, `pkgcheck`, `./build.sh duel` with 0 warnings, the 79195 consing probe
   (160 B per 10 draws is the floor), before/after contact sheets from the behind and side cameras, **both landscape
   (letterbox 9 %) and portrait**. Then update the playtest Artifact.
9. **Reply** in zh-TW: what changed, the numbers, pushed or not, and what needs the user's eyes.

## Regressions to look for after any rule change
- Hidden movement: Breaker-style link chase, string chase during a dash's startup (K → L measured 0.88 m vs 10 m).
- State read too early: the ASSIST decides one step ahead and read a stale dash end (§23.36). Reset per-move state at
  the move's start, not at its `:go` frame.
- Order of effects: a short dash ended before the form change, so the link was decided for the old form.
- Touch: an up-flick inside a stance-move read as a Hoho.
- Framing: a cinematic's shots depend on the actors' distance at entry (CINE-PLACE fixes it) and on the aspect ratio.

## Feel tuning
- Feel numbers churn (TENSHIN's distance changed 8 times). Get the unit right once (fixed speed, Step lengths), then
  let the user tune the number by play. Prefer a live knob to another gate cycle.
- Feel effects that scale time (slow motion) need their trigger rule settled before their numbers.
- Model tweaks by eye: iterate on stills (front + side), and for a position or size show 3–4 candidates side by side
  so the user picks one (reference §7).

## Red flags
- Changing a distance whose effect another hidden rule cancels. Measure the actual travel first.
- "Looks fine" from one camera or one aspect ratio.
- Starting the build while the user is still describing (a storyboard in several messages).
- A rule change while a CPU search runs (it forces a re-freeze).
- Declaring a presentation change done without the byte-identical sim check.
- Putting a new motion on a move without reading its hit volume: a thrust drawn on K3's 360° spin would hit behind
  him (Kenpachi, reference §8). Check `:arc` / `:vol` before promising a slot.
