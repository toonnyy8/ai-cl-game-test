# lille-ai-drsi — the dream-rsi workspace of Lille Barro's CPU search

The plan is DUEL_LILLE §24 (the user's request, 2026-10-06), the evaluator §24.2, the method and last run's lessons
`docs/guides/DREAM_RSI.zh-TW.md` (§7 is the checklist these files follow). The previous run's workspace is
`docs/research/ai-v2-drsi/`.

## The setup (frozen)

Restarted 2026-10-07 on decisions 41–43 (DUEL_LILLE §24.4): a new freeze, baseline 0.4496 at 40 seeds, drift references
40 → 0.4125, 80 → 0.44; the first run is in `archive/v1/`.

- **Task**: SOUL DUEL Lille CPU AI (`duel/lisp/lille.lisp` `:ai` tables and CPU reflexes), scored by
  `tools/aieval.py --char 5 --seeds 40` at the freeze commit.
- **Freeze commit**: the last commit touching `tools/aieval.py`, `tests/duel-rules-test.lisp` or
  `baseline/drift-ref.json` (DUEL_LILLE §24.2 names it); the scripts find it with
  `git log -1 -- tools/aieval.py tests/duel-rules-test.lisp docs/research/lille-ai-drsi/baseline/drift-ref.json`, or take
  `FREEZE=<hash>` from the environment. Every cell's worktree starts there; the opponents are the five other CPUs as
  they read there.
- **Host test**: frozen, except the section of `tests/duel-rules-test.lisp` between `;;; >>> BEGIN LILLE-CPU-TESTS` and
  `;;; <<< END LILLE-CPU-TESTS` (his own CPU's shipped values and pure LB-AI-* functions): a cell may deliver the file
  and `rescore.sh` splices only that section into the frozen test (`splice-tests.py`), writing its diff to
  `NODE_DIR/test-section.diff`. Review it before `record`: the section must still pin the cell's own values and may not
  weaken a test of shared behaviour, a rule, a hook or another character (those live outside the markers, frozen).
- **Score**: 0.4 strength + 0.2 masher + 0.4 signature (whitelist); 0 when NORMAL pacing or the NORMAL drift gate fails.
  Cells compare at 40 seeds (`eval_command` in `config.json`: `-j 2`, two cells run at once on the 4 cores); the final pick
  at 80 (`--seeds 80`; the drift reference holds 40 and 80).
- **dream-rsi**: `drsi.py init` with W = 2, branches 4 × refines 2 (8 cells a round), λ 0.25, the baseline's 40-seed
  score; `plan --beta 0.6` each round; ≥ 3 rounds; between rounds 3–5 written policy revisions compared on the replay
  pool; `set-direction` only structural (DREAM_RSI §5.11).

## Files

| Path | What |
|---|---|
| `config.json`, `policy/`, `rounds/`, `trace_pool/`, `proposal_results/` | `drsi.py`'s (init, plan, record, close-round, compare, promote) |
| `archive/v1/` | the first run (round 1 on decision 39's rules, paused 2026-10-06; DUEL_LILLE §24.4): its config, policy, rounds, baseline |
| `baseline/lille.lisp` | the frozen `duel/lisp/lille.lisp` |
| `baseline/proposal.md` | the shipped CPU, described (DUEL_LILLE §19, §22.4, §23.4, §23.11, §23.15) |
| `baseline/score.json` | the frozen evaluator's JSON for the baseline at 40 seeds (the init's `--baseline-score`) |
| `baseline/score80.json` | the same at 80 seeds (the final pick's reference) |
| `baseline/drift-ref.json` | the baseline's NORMAL win share per drift seed count (`aieval.py` reads it: the drift gate) |
| `brief.py` | one cell's brief: the skill's exploration prompt + this project's rules |
| `step.sh` | the loop: `next` (briefs for the policy's next batch), `done <cell> <round> [worktree]` (copy, rescore, record, next), `fail …` |
| `rescore.sh` | one cell re-measured with the frozen evaluator in a worktree detached at the freeze commit (its test section spliced, host test, then eval) |
| `splice-tests.py` | a cell's LILLE-CPU-TESTS section into the frozen `tests/duel-rules-test.lisp` (+ the section's diff) |

## The loop (the coordinator)

```sh
WS=docs/research/lille-ai-drsi
D=<the dream-rsi skill>/scripts                      # step.sh finds it ($DREAM_RSI, ~/.claude/skills[/synced/*]/dream-rsi)
python3 $D/drsi.py -w $WS plan --beta 0.6            # open round N
$WS/step.sh next                                     # -> rounds/roundNN/nodes/<cell>.brief.md for the batch (W = 2)
#   dispatch each brief to a fresh agent in its own git worktree at the freeze commit; the agent writes its
#   deliverables inside ITS worktree at the brief's relative NODE_DIR (lille.lisp, proposal.md, score.json, and
#   duel-rules-test.lisp if it edited the LILLE-CPU-TESTS section)
$WS/step.sh done <cell> <N> <the agent's worktree>   # copy -> rescore (40 seeds, frozen) -> record the RESCORED score -> next
$WS/step.sh fail <cell> <N> <class> "<error>"        # a cell that delivered nothing scorable
#   round complete -> close-round, replay, write 3-5 policy revisions, compare, promote, plan the next round
```

- `step.sh done` takes a lock (`$RESCORE_WT.lock`): one rescore at a time; a gate failure is recorded as score 0 with
  `--fail-class correctness` and the gate named; a build failure `compile_other`, failing host tests or an unspliceable test section `correctness`, a
  timeout `resource`, anything else `runtime`.
- A cell whose brief already exists is in flight: `next` names it and writes no new brief.
- Variables (top of the scripts, overridable from the environment): `FREEZE`, `RESCORE_WT` (default
  `<repo>/.claude/worktrees/rescore-lille`), `DREAM_RSI`, `ECL_HOST`, `EVAL` (default `config.json`'s `eval_command`),
  `EVAL_TIMEOUT`.
- Never commit `.claude/` or a cell's scratch; commit the workspace's records when a round closes.
