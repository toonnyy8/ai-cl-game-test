#!/bin/bash
# rescore.sh — re-measure one delivered cell with the FROZEN evaluator (DUEL_LILLE §24.2): a dedicated worktree detached
# at the freeze commit, only duel/lisp/lille.lisp replaced and, when the cell delivered tests/duel-rules-test.lisp, only
# its LILLE-CPU-TESTS section spliced into the frozen test (splice-tests.py; the section's diff -> NODE_DIR/test-section.diff
# for review); the host rules test first, then the config's eval command. Writes NODE_DIR/score.rescored.json
# (+ rescore-host.log, rescore-eval.log). Exit 0 ok, 2 build failed (compile_other), 3 host tests failed or the section
# could not be spliced (correctness), 4 timed out (resource), 5 other (runtime).
# usage: rescore.sh <node_dir>          (step.sh calls it under its lock: one rescore at a time)
set -u
WS=$(cd "$(dirname "$0")" && pwd)                                # this workspace (the coordinator's checkout)
REPO=$(cd "$WS/../../.." && pwd)
REL=${WS#$REPO/}
ECL=${ECL_HOST:-/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl}
FREEZE=${FREEZE:-$(git -C "$REPO" log -1 --format=%H -- tools/aieval.py tests/duel-rules-test.lisp "$REL/baseline/drift-ref.json")}
RESCORE_WT=${RESCORE_WT:-$REPO/.claude/worktrees/rescore-lille}
EVAL=${EVAL:-$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['eval_command'])" "$WS/config.json")}
EVAL_TIMEOUT=${EVAL_TIMEOUT:-7200}                               # seconds (one 40-seed eval at -j 2: see README)

N=$(cd "$1" && pwd)
[ -f "$N/lille.lisp" ] || { echo "{\"error\": \"no lille.lisp\"}" > "$N/score.rescored.json"; exit 5; }
if [ ! -d "$RESCORE_WT" ]; then git -C "$REPO" worktree add -q --detach "$RESCORE_WT" "$FREEZE" || exit 5; fi
git -C "$RESCORE_WT" checkout -q --detach "$FREEZE" || exit 5
git -C "$RESCORE_WT" checkout -q "$FREEZE" -- duel tools tests docs || exit 5   # (the frozen tree, again)
cp "$N/lille.lisp" "$RESCORE_WT/duel/lisp/lille.lisp" && touch "$RESCORE_WT/duel/lisp/lille.lisp"
cd "$RESCORE_WT" || exit 5
rm -f "$N/test-section.diff"
if [ -f "$N/duel-rules-test.lisp" ] &&                         # the cell's CPU test section, spliced (nothing else)
   ! python3 "$WS/splice-tests.py" "$N/duel-rules-test.lisp" tests/duel-rules-test.lisp "$N/test-section.diff" 2> "$N/rescore-host.log"; then
  echo '{"error": "the cell test section could not be spliced (LILLE-CPU-TESTS markers)"}' > "$N/score.rescored.json"; exit 3
fi
echo "rescore: $N at $(git rev-parse --short HEAD): $EVAL" >&2
timeout 1800 "$ECL" --norc --load tests/duel-rules-test.lisp > "$N/rescore-host.log" 2>&1
if ! tail -1 "$N/rescore-host.log" | grep -q 'ALL PASS'; then
  echo '{"error": "host tests failed (duel-rules-test.lisp)"}' > "$N/score.rescored.json"; exit 3
fi
timeout "$EVAL_TIMEOUT" $EVAL > "$N/score.rescored.json" 2> "$N/rescore-eval.log"
rc=$?
if [ $rc -eq 124 ]; then echo '{"error": "eval timed out"}' > "$N/score.rescored.json"; exit 4; fi
if [ $rc -ne 0 ]; then
  if grep -q 'BUILD FAILED' "$N/score.rescored.json" "$N/rescore-eval.log"; then
    echo '{"error": "native build failed"}' > "$N/score.rescored.json"; exit 2; fi
  echo "{\"error\": \"eval exited $rc\"}" > "$N/score.rescored.json"; exit 5
fi
cat "$N/score.rescored.json"
