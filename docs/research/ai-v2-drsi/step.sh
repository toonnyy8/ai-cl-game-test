#!/bin/bash
# ponytail: one cell done -> copy deliverables from the agent's worktree if needed, rescore, record, open the next cell
# usage: step.sh <character> <idx> <file> <cell> <round> [agent-worktree]
set -e
H=/media/8tsp/projects/ai-cl-game-test/docs/research/ai-v2-drsi
D=${DREAM_RSI:-$HOME/.claude/skills/dream-rsi}/scripts   # the dream-rsi skill's directory
N=$H/$1/rounds/round$(printf %02d $5)/nodes/$4
if [ ! -f "$N/$3.lisp" ] && [ -n "$6" ]; then cp $6/docs/research/ai-v2-drsi/$1/rounds/round$(printf %02d $5)/nodes/$4/* $N/; fi
S=$($H/rescore.sh $1 $2 $3 $N | tail -1 | python3 -c "import json,sys; print(json.load(sys.stdin)['score'])")
python3 $D/drsi.py -w $H/$1 record --round $5 --cell $4 --score $S --fail-class ok --note "rescored with the fixed evaluator" > /dev/null
echo "recorded $1 $4 score $S"
W=$(python3 $D/drsi.py -w $H/$1 next-batch --round $5)
ST=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['status'])" "$W")
if [ "$ST" != execute ]; then echo "next: $ST"; exit 0; fi
X=$(python3 -c "import json,sys; print(json.dumps(json.loads(sys.argv[1])['work'][0]))" "$W")
C=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['cell'])" "$X")
python3 $H/brief.py $1 $C $5 "$X" > $H/$1/rounds/round$(printf %02d $5)/nodes/$C.brief.md
echo "next cell $C parent $(python3 -c "import json,sys; print(json.loads(sys.argv[1])['parent_dir'])" "$X")"
