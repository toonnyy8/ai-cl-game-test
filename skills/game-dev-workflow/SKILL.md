---
name: game-dev-workflow
description: Use when a user asks for a game feature, rule change, character, bug fix, port or deploy in a long-running hobby game project with design docs and a decision log — especially requests in Traditional Chinese, bursts of small requests, a public repo deployed to GitHub Pages, or work big enough to split across subagents.
---

# The game-dev change loop

## Overview
Distilled from many sessions building `toonnyy8/ai-cl-game-test` (local `/media/8tsp/projects/ai-cl-game-test`).
Core principle: **the user's words are the spec, every decision lands in the repo docs in the same pass, and nothing
is "done" until it is measured, committed and pushed — but never deployed unless asked.** Templates and evidence:
`reference.md`.

## The loop (every request)
1. **Quote the request verbatim** (keep the zh-TW) — it goes into the docs and the commit.
2. **Clarify only what changes the design.** Use AskUserQuestion with 2–4 options, the recommended one first. Fix a
   wrong premise politely, with sources. Small, clear requests: no questions.
3. **Implement in the smallest place**: a character's own files before shared ones; shared files get generic hooks.
4. **Gate it** (REQUIRED SUB-SKILL: sim-balance-gates for rules/AI; procedural-ink-style for looks). Every new mechanic
   also gets a CPU rule, in this batch or the next.
5. **Docs in the same pass**: the feature/design doc § (English: request quote, knobs `*name*` old → new, tests, gate
   numbers), `docs/DEVLOG.zh-TW.md` new § (`## N. 標題（YYYY-MM-DD）`, opens `使用者：「…」`, bullets: 決定／原因／改動／
   試過但拿掉／測試結果／還沒解決), the player manual (zh-TW) if players see it, every place a changed reference number
   is quoted.
6. **Rebuild what the user runs** (`./build.sh <game>`) — the last build before reporting is the shipping build.
7. **Commit + push main at the milestone** without asking; subject = the change, "(the user, YYYY-MM-DD)", key numbers,
   doc § refs; scope caveats in parentheses; the session's attribution trailers. Never commit `.claude/` or scratch;
   research is committed only once moved under `docs/research/<topic>/`.
8. **Deploy (`tools/deploy-pages.sh`) only when the user says so.** Then confirm the Pages build status and URL.
9. **Reply in zh-TW, concise**: what changed, key numbers, what is pushed, what is pending, any decision the user must
   make. Report failing gates and your own mistakes plainly; label anything not checked by eye.

## Design principles the user holds (check new designs against them)
- Faithful to the source characterisation; canon claims tagged [manga]/[anime-only]/[ours].
- A transformation changes playstyle, not power (gate: "never transform" still wins ≥ 20/60 per seed stream).
- Rock-paper-scissors loops enforced by geometry and host tests (guard > light > grab > guard).
- Light = short/fast, heavy = long/slow; drawn reach = hit reach.
- Pacing is a numeric gate the user owns; deliberate nerfs stay nerfs; exceptions only with the user's acceptance.
- No infinite pressure; reward aggression; the CPU answers mashing.
- Accessibility as priced SETTINGS rows (assist, one-hand phone mode, hints), not new modes.

## Multi-agent work
- Fan out only independent batches: one worktree + branch + **fresh agent** per batch, a compact brief (context and
  the user's decisions, numbered steps with exact commands, acceptance numbers, docs to touch, rules, report format).
- Rules block in every brief: bounded waits, wait by PID, no `pgrep -f`/`pkill -f`; no push to main, no deploy; don't
  edit the evaluator; commit trailers.
- The lead verifies every report itself (rerun tests/gates), merges, updates the doc's Status, removes the worktree.
- Before any second implementation (a port): ask whether it replaces or runs beside the original and who keeps
  parity. If it is stopped: a banner on its doc, a Status entry, memory updated.

## Red flags
- "I'll update the docs later" / only in the scratchpad → write them now.
- "The gate is a bit off, I'll nudge another knob" → report and ask.
- "It passed natively" → did you rebuild `dist/`?
- "They'll want it live" → deploy only on their word.
