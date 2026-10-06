#!/bin/bash
# step.sh — the coordinator's loop for Lille's CPU search (DUEL_LILLE §24; DREAM_RSI §7 "每個 cell"):
#   step.sh next [round]                         ask the policy for the next batch; write a brief for every cell not yet
#                                                briefed (a cell whose brief exists is in flight: W = 2 run at once)
#   step.sh done <cell> <round> [cell-worktree]  a cell reported: copy its deliverables from its worktree (the fixed
#                                                relative path; a delivered duel-rules-test.lisp gives only its
#                                                LILLE-CPU-TESTS section), rescore with the frozen evaluator, record the
#                                                RESCORED score with a truthful --fail-class, then `next`
#   step.sh fail <cell> <round> <class> <error>  a cell delivered nothing scorable: record the failure, then `next`
#   (FORCE=1 re-records a cell already recorded: a coordinator's mistake, never to retry a cell for a better score)
# Dispatch each brief (rounds/roundNN/nodes/<cell>.brief.md) to a fresh agent in its own worktree at the freeze commit.
set -u
WS=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$WS/../../.." && pwd)
REL=${WS#$REPO/}
DREAM_RSI=${DREAM_RSI:-$(ls -d "$HOME/.claude/skills/dream-rsi" "$HOME"/.claude/skills/synced/*/dream-rsi 2>/dev/null | head -1)}
DRSI="python3 $DREAM_RSI/scripts/drsi.py -w $WS"
export FREEZE=${FREEZE:-$(git -C "$REPO" log -1 --format=%H -- tools/aieval.py tests/duel-rules-test.lisp "$REL/baseline/drift-ref.json")}
RESCORE_WT=${RESCORE_WT:-$REPO/.claude/worktrees/rescore-lille}
export RESCORE_WT

next() {
  local W ST R
  W=$($DRSI next-batch ${1:+--round $1}) || exit 1
  ST=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['status'])" "$W")
  R=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['round'])" "$W")
  if [ "$ST" != execute ]; then
    echo "round $R: $ST -> close-round, replay / compare 3-5 policy revisions, promote, plan --beta 0.6 the next"; return
  fi
  python3 - "$W" "$WS" "$R" <<'EOF'
import json, os, subprocess, sys
w, ws, r = json.loads(sys.argv[1]), sys.argv[2], int(sys.argv[3])
for x in w['work']:
    b = os.path.join(ws, 'rounds', f'round{r:02d}', 'nodes', x['cell'] + '.brief.md')
    if os.path.exists(b):
        print(f"in flight: {x['cell']} (round {r})"); continue
    txt = subprocess.run([sys.executable, os.path.join(ws, 'brief.py'), x['cell'], str(r), json.dumps(x)],
                         capture_output=True, text=True, check=True).stdout
    open(b, 'w').write(txt)
    print(f"dispatch: {x['cell']} (round {r}) brief {b} parent {x['parent'] or '-'}")
EOF
}

record() {   # cell round score class error note
  $DRSI record --round "$2" --cell "$1" ${3:+--score $3} --fail-class "$4" ${5:+--error "$5"} --note "$6" \
        ${FORCE:+--force} > /dev/null || exit 1
  echo "recorded $1 (round $2): score ${3:-none} fail-class $4 ${5:+($5)}"
}

case "${1:-}" in
  next) next "${2:-}" ;;
  fail) [ $# -ge 5 ] || { echo "usage: step.sh fail <cell> <round> <class> <error>" >&2; exit 2; }
        exec 9>"$RESCORE_WT.lock"; flock 9
        record "$2" "$3" 0 "$4" "$5" "the cell delivered nothing scorable"; next "$3" ;;
  done) [ $# -ge 3 ] || { echo "usage: step.sh done <cell> <round> [cell-worktree]" >&2; exit 2; }
        C=$2; R=$3; RR=$(printf %02d "$R"); N=$WS/rounds/round$RR/nodes/$C
        mkdir -p "$N"
        if [ ! -f "$N/lille.lisp" ] && [ -n "${4:-}" ]; then
          cp "$4/$REL/rounds/round$RR/nodes/$C/"{lille.lisp,proposal.md,score.json,duel-rules-test.lisp} "$N/" 2>/dev/null
        fi
        exec 9>"$RESCORE_WT.lock"; flock 9                       # (one rescore at a time; records in order)
        if [ ! -f "$N/lille.lisp" ]; then record "$C" "$R" 0 runtime "no lille.lisp delivered" "nothing to rescore"; next "$R"; exit 0; fi
        "$WS/rescore.sh" "$N" > /dev/null
        rc=$?
        case $rc in
          0) eval "$(python3 - "$N/score.rescored.json" <<'EOF'
import json, shlex, sys
j = json.loads(open(sys.argv[1]).read().strip().splitlines()[-1])
d = j.get('drift', {})
parts = (f"rescored at the freeze: str {j['strength']} mash {j['masher']} sig {j['signature']} "
         f"drift {d.get('share')} (ref {d.get('ref')}) pacing {'ok' if j['pacing_ok'] else 'FAIL'}")
gates = [g for g, ok in (('pacing', j['pacing_ok']), ('drift', d.get('ok', True))) if not ok]
print(f"S={j['score']} G={shlex.quote(' '.join(gates))} P={shlex.quote(parts)}")
EOF
)"
             if [ -n "$G" ]; then record "$C" "$R" 0 correctness "gate failed: $G" "$P"
             else record "$C" "$R" "$S" ok "" "$P"; fi ;;
          2) record "$C" "$R" 0 compile_other "native build failed (rescore-eval.log)" "rescore" ;;
          3) record "$C" "$R" 0 correctness "host tests failed (rescore-host.log)" "rescore" ;;
          4) record "$C" "$R" 0 resource "eval timed out" "rescore" ;;
          *) record "$C" "$R" 0 runtime "rescore exited $rc (rescore-eval.log)" "rescore" ;;
        esac
        next "$R" ;;
  *) sed -n 2,10p "$0"; exit 2 ;;
esac
