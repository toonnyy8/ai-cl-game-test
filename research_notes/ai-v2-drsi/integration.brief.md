# Integration of the per-character AI v2 (one subagent, its own worktree)

Reply to the coordinator in English. You work in your own git worktree of /media/8tsp/projects/ai-cl-game-test (main).
You MAY commit on your worktree's branch (small commits, messages ending with the two attribution lines below); do NOT
push and do NOT touch main. The coordinator reviews and merges.

    Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
    Claude-Session: https://claude.ai/code/session_01XHp3Wrc2RN4n5Nn5EHCh5P

## Context
The user (2026-10-02) asked for a per-character AI redesign using the current string logic and each character's
colour, integrated with the learning CPU, and merged into the ASSIST auto mode; strength layered by difficulty (EASY keeps
its gaps, NORMAL stays near today's level, HARD is the full version). A dream-rsi search produced candidate CPU files per
character under /media/8tsp/projects/ai-cl-game-test/research_notes/ai-v2-drsi/<char>/rounds/round0N/nodes/<cell>/
(each with proposal.md, score.json, score.rescored.json). Read docs/DUEL_AI_V2.md, docs/DUEL_ASSIST.md,
docs/DUEL_LEARNING.md, duel/lisp/ai.lisp, duel/lisp/assist.lisp, duel/lisp/learn.lisp first, and every chosen cell's
proposal.md.

## Step 1. The chosen files (copy each over duel/lisp/<file>.lisp)
- Yamamoto: rounds/round01/nodes/b0a2/yama.lisp, PLUS the NORMAL fix from rounds/round02/nodes/b0a0/proposal.md (b0a0's
  NORMAL anti-Breaker J1 chance 0.2 -> 0.0; HARD unchanged).
- Kenpachi: compare rounds/round01/nodes/b0a2/ken.lisp and rounds/round02/nodes/b0a0/ken.lisp at 80 seeds
  (python3 tools/aieval.py --char 1 --seeds 80 -j 16); keep the higher score.
- Rukia: rounds/round02/nodes/b0a0/rukia.lisp.
- Ichigo: rounds/round01/nodes/b0a1/ichigo.lisp.
- Senjumaru: rounds/round02/nodes/b0a0/senjumaru.lisp.
Rules test must pass: /media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl --norc --load tests/duel-rules-test.lisp

## Step 2. NORMAL stays near the shipped CPU (the user's difficulty layering)
For each character measure NORMAL strength (its NORMAL CPU vs the other four NORMAL CPUs, both seats, 40 seeds; the
learning-gate runner as tools/aieval.py does it, difficulty 81021) twice: with ALL FIVE shipped files (git show
main:duel/lisp/<file>.lisp) and with ALL FIVE new files. A character whose NORMAL win share rises by more than 0.05 gets
its NORMAL chances lowered (only NORMAL values) until it is within 0.05. Report the before / after table.
Note: once all five new files are in, each character's HARD strength vs the NEW others is lower than in the search (the
others improved too); report each character's HARD strength vs the new set (aieval --char i --seeds 40), no target.

## Step 3. The learning CPU and the new AIs
The learning CPU (learn.lisp, ai.lisp LEARN-*) attaches to the CPU facing a human (VS CPU / ENDLESS) and runs before the
reflexes / at neutral decisions (BRAIN-STEP: learn-fire; AI-DECIDE: learn-neutral, the bandit in AI-ATTACK). Several new
character reflexes take over the neutral decision (they reset brain-decide-t and call ai-attack / press directly: e.g.
Yamamoto's rush veto, Rukia's zone wave, Ichigo's convert) or return :wait. Make sure the learner still gets to act:
its planned counters (learn-fire) and its neutral read (learn-neutral) must not be starved by those takeovers, and its
bandit must still weigh the picks the takeovers make through ai-attack. Prefer a generic fix in ai.lisp (e.g. a learner
step that runs before the kit :reflex when it has a due counter) over per-character edits. Verify with the learning
gate (debug 200000 + 1000 h + 100 c1 + 10 c2 + m; docs/DUEL_LEARNING.md describes it and its "duel learn row" lines):
per character, habits 1-4 vs that character learning ON (m=1) vs OFF (m=0), 10 seeds; the learner must still raise the
counters / reads it did before (report reads and paid per character).

## Step 4. The ASSIST auto mode uses the new AI
assist.lisp borrows a HARD brain per side for the human's assist. Make the assist use each character's new CPU logic
where it fits the assist's contract ("you press, the CPU chooses"; AUTO GUARD under its trigger):
- AUTO GUARD: before its generic perfect-now-p Hoho / parry, offer the character's own defensive reflex answers when U
  is held / ALWAYS (the timed perfect Hoho, the timed anti-Breaker counter, Rukia's zero REIDO ...), but only DEFENSIVE
  answers; never let a neutral-decision takeover or an offensive reflex fire from AUTO GUARD.
- AUTO COMBO: string-reflex already calls the kit's :sp-ender; check the new :sp-ender functions work with the assist's
  borrowed brain (Ichigo's returns NIL without a brain; make them work with the assist brain), and that the assist's
  learner (*assist-learn-tables*) still feeds AUTO COMBO's reads.
Find a small generic mechanism (e.g. a kit :ai key :assist-guard naming the character's defensive function, called by
AUTO GUARD) rather than special cases by name in assist.lisp (shared files stay name-free).
Verify with tools/assistgate.py (the masher with assist ON vs HARD, --ks 0,2,11; and --p2-dumb 1 --ks 0,2): the assist
must help at least as much as before (record before / after), and an assisted move still deals x0.8 and never a perfect
Hoho from the assist (ASSIST-NEXT).

## Step 5. Gates (all must pass; report the numbers)
- tools/simgate.py: all 15 pairings K.O.; cross-pairing 20-seed medians <= 210 s (recheck with --seeds 60 if over);
  mirror matches may exceed 210 s (the user's rule).
- Never-awaken A/B (Rukia / Senjumaru rows must be >= 20/60 on streams 100/300/500):
  for s in 100 300 500: python3 tools/simgate.py --pairs 3,4,5,10,11,12,13,14 --seed0 $s --seeds 60 --cmd 39020 --summary
  (Ichigo's A/B rows were already failing before this work; report them.)
- Host tests: tests/duel-rules-test.lisp, tests/duel-control-test.lisp, tests/learn-test.lisp, tests/input-test.lisp.
- ./build.sh duel must succeed (the wasm build).
- G2: timeout 1800 python3 tests/style-gates.py cvc dist/duel, then rewrite tests/style-cvc-ref.txt (header: a new note
  + "Before: " + the old header text; then "<pair> <line>" for every log line matching 'duel (hash|-> RESULTS winner)'
  from build/style/cvc-{yy,yk,kk}.log; never the bare "duel -> RESULTS" lines), and python3 tools/simgate.py --cvc must
  PASS. Update the YK RESULTS quote in docs/DUEL_GAMEPLAY.md, docs/TUTORIAL.zh-TW.md and tests/scripts/duel.py (not the
  DEVLOG history).

## Step 6. Docs
docs/DUEL_AI_V2.md: per character the action policy (行動方針) actually shipped (from the chosen proposals), the scores
(search, then final vs the new set), the NORMAL table, the learning and assist integration, the gates; and the shared-code
recommendations the cells made (the late generic anti-Breaker J1, ward-reversal window, :awaken-p hook, :wait command,
difficulty-scaled :o-ender / :string-k / :l-after-k, a :decide hook) with which ones you did. Append a §77 entry to
docs/DEVLOG.zh-TW.md in Traditional Chinese (same style as §76: the user's quote, decisions, what changed, measurements).
Code comments and design docs in English.

## Rules
Bounded waits only; never pkill / kill / killall; no self-matching pgrep loops. Do not deploy. Do not edit
tools/aieval.py's scoring. Report: what you chose, the tables, gate results, the branch name and commit ids.
