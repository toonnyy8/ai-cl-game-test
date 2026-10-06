#!/bin/bash
# ponytail: re-measure a delivered cell file with the current (fixed) evaluator in a throwaway worktree at main
# usage: rescore.sh <character> <idx> <file-basename> <node_dir>
set -e
ROOT=/media/8tsp/projects/ai-cl-game-test
W=$ROOT/.claude/worktrees/rescore-$1
[ -d "$W" ] || git -C $ROOT worktree add -q --detach "$W" main
git -C "$W" checkout -q --detach main
git -C "$W" checkout -q -- duel/lisp
cp "$4/$3.lisp" "$W/duel/lisp/$3.lisp"
cd "$W" && timeout 3000 python3 tools/aieval.py --char $2 -j 8 | tee "$4/score.rescored.json"
