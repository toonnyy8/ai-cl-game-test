#!/usr/bin/env python3
# brief.py — one dream-rsi cell's brief for Lille Barro's CPU search (DUEL_LILLE §24): the skill's exploration prompt
# (assets/exploration_prompt.md, Listing 1 of arXiv:2609.14858) + this project's rules. Prints it.
# usage: brief.py <cell> <round> ['<work-order JSON>']     (step.sh calls it with next-batch's work item)
import json, os, sys

WS = os.path.dirname(os.path.abspath(__file__))                  # this workspace, in the coordinator's checkout
REPO = os.path.dirname(os.path.dirname(os.path.dirname(WS)))     # that checkout's root
REL = os.path.relpath(WS, REPO)                                   # docs/research/lille-ai-drsi
ECL = os.environ.get('ECL_HOST', '/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl')
CFG = json.load(open(os.path.join(WS, 'config.json')))
EVAL = CFG.get('eval_command', 'python3 tools/aieval.py --char 5 --seeds 40 -j 2')
FREEZE = os.environ.get('FREEZE', '(the freeze commit: see the README)')

cell, rnd = sys.argv[1], int(sys.argv[2])
work = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
rel_node = f'{REL}/rounds/round{rnd:02d}/nodes/{cell}'
parent = work.get('parent_dir')
parent = os.path.abspath(parent) if parent else '(none: this cell opens a new direction from BASELINE_DIR)'
direction = work.get('direction') or ''

print(f"""You are one discovery cell of a Dream-RSI search (arXiv:2609.14858) redesigning the CPU AI of LILLE BARRO, SOUL DUEL's
sniper (roster index 5). Reply to the coordinator in English; the user is not reading your output directly.

You must read every historical proposal before proposing or implementing a new solution.

# The cell
- Cell {cell}, round {rnd}. Target file (EVAL_PROGRAM): duel/lisp/lille.lisp — its CPU parts only (below).
- PARENT_DIR = {parent}
- HISTORY_DIR = {WS}/rounds   (every earlier cell of every round: proposal.md, score.json, score.rescored.json, lille.lisp)
- BASELINE_DIR = {WS}/baseline  (the frozen lille.lisp, proposal.md: the shipped CPU, score.json: its parts at 40 seeds)
- NODE_DIR (yours) = {rel_node}  — a path RELATIVE TO YOUR OWN WORKTREE ROOT (see Deliverables)
- EVAL_COMMAND (in your worktree root): {EVAL}
- Direction hint: {direction or '(none)'}

You work in your own git worktree of the repo, checked out at the freeze commit {FREEZE} (the evaluator, the opponents'
CPUs and every rule are fixed there). HISTORY_DIR and BASELINE_DIR are in the coordinator's checkout: read them there.
If PARENT_DIR is a directory, first copy PARENT_DIR/lille.lisp over duel/lisp/lille.lisp in your worktree (and
PARENT_DIR/duel-rules-test.lisp over tests/duel-rules-test.lisp when it exists), then refine it; else start from the
worktree's files (= BASELINE_DIR/lille.lisp and the frozen test).

# Step 1. Read the complete history first
Read every proposal.md under HISTORY_DIR (all rounds, all cells except your own) and BASELINE_DIR, in full, with its
score.rescored.json (the coordinator's re-measure with the frozen evaluator: THE number) and score.json. Trust the measured
result over what a proposal claims. For every past attempt note the mechanism and how it did; for a failure work out
whether the idea was flawed or let down by a bug or a parameter (locate the bug in the code before retrying it).
Don't converge on small tweaks of one mechanism with flattening returns: prefer a structurally different mechanism, a new
combination of pieces that worked, or a targeted fix of a located bug. Never a repeat or a rename.

# Step 2. Understand the game as it is NOW (read, don't skim)
- docs/duel/DUEL_LILLE.md: §4-§6 (his kit), §19 (the CPU as built), §22.4, §23.4, §23.11-§23.15 (the modes, TENSHIN, the
  flash-step economy, the owl), §24 (this search: the user's request, the plan, §24.2 the evaluator).
- duel/lisp/lille.lisp: the kits' `:ai` plists (six forms + the four MUJITTAI), the AI section (LB-AI-REFLEX and every
  LB-AI-* function, the *LB-AI-...* knobs), and the CPU branches inside the sim's ticks: LB-KAMAE-TICK (LB-AI-KAMAE: the
  shooting stance's branch), LB-EN-TICK (LB-AI-EN-STICK, the switch rule's 2 f cancel), LB-EN-LAY (LB-AI-EN-NEXT),
  LB-LINK-TICK (LB-AI-LINK), LILLE-OK's `(brain e)` clause (the flash-step reserve).
- duel/lisp/ai.lisp: AI-REFLEX (the order: string / guard-cancel answers, then the learning CPU's read, then the kit's
  :reflex, then :opp-reflex ...), AI-DECIDE / AI-ATTACK (how the :intents / :ranges / :moves tables are used), the
  generic keys (header comment), AI-AWAKEN-P, the :bankai reflex, BRAIN-REACT-ROLL / BRAIN-GUARD-ROLL (one per opponent
  action), AI-BRAIN.
- tools/aieval.py and DUEL_LILLE §24.2: what is measured.

# The score (tools/aieval.py --char 5; frozen)
score = 0.4 strength + 0.2 masher + 0.4 signature, else 0 when a gate fails:
- strength: HARD Lille vs the five other HARD CPUs, both seats (the mirror is not played): his win share.
- masher: HARD Lille (P2) vs the button-masher bot (P1, every character): his win share.
- signature: the share of his dealt damage (strength runs) on the WHITELIST: materialised traces; any J / K hit in a combo a
  trace hit opened (trace -> TENSHIN -> J / K ...); HOSHA's bullets and the J1 / K1 a HOSHA hit links into; the CHARGED
  X-Axis shot; TAISHA; the SPs (SANREN, base SP2 HIRENKYAKU, NIJUSHI-KO, the owl's 裁きの光明 lines, Trompete) and his
  Kikons. Never the Breaker, never a plain J / K string, never the quick shot; the laying shot (1 damage) counts nowhere.
  The JSON's "sig_by" breaks his damage down by category.
- gates (score 0): pacing — NORMAL Lille (P1) vs each other character: every match a K.O., median <= 220 s (vs Rukia and vs
  Ichigo <= 240 s, accepted exceptions); drift — NORMAL Lille vs each other NORMAL CPU, both seats: his win share within
  0.05 of the frozen baseline's (the JSON's "drift"). A NORMAL behaviour change, or a no-roll rule change that also runs at
  NORMAL, moves the drift: keep NORMAL near the shipped CPU (scale new behaviour by difficulty).

# Step 3. Propose and implement his action policy (行動方針), in character
Design the CPU around his kit as a sniper with the X-Axis (the user: 「更具有角色風格的利捷巴羅自適應 AI」): ranges and
spacing per form, when the shooting stance and which branch (charged shot, HOSHA, TAISHA, the dash), how EN lays traces
and when TENSHIN materialises them (the trace -> TENSHIN -> J / K combo), KIN's strings and when it switches out, MUJITTAI,
Trompete, the eye, the awakening and the revival, how it adapts to what the opponent does (one roll per event, as below).
Implement it ONLY in duel/lisp/lille.lisp, ONLY in his own CPU's code:
- allowed: the `:ai` plists of his kits EXCEPT the keys read by CPUs facing him (:opp-trace :opp-reflex :opp-reflect
  :opp-aim); the AI section's LB-AI-* functions and *LB-AI-...* knobs (and new functions / knobs there, wired through the
  existing hook keys); the `(brain e)` / CPU branches of the sim ticks named above (never the human branch).
- forbidden: any move's frame data, damage, volumes, costs, form rules, the sim's rules and hooks for a human, LB-OPP-TRACE
  and anything an opponent's CPU reads (that would weaken the opponents: not his CPU), any other file (ai.lisp, tuning.lisp,
  the other characters ...; of the tests only the LILLE-CPU-TESTS section, Step 4). A shared
  change you believe is needed goes in proposal.md as a recommendation.
- keep working (the gates and shared systems depend on them):
  - AI-AWAKEN-P decides his base -> JILLIEL awakening (the awaken A/B's debug modes 39000+10a+b force it on / off); the
    revival into the owl stays the generic :bankai reflex (the kits' :bankai key; debug 31000+10a+b forces it);
  - every debug mode and test command (79000-79999) and the `duel lille` pacing counters;
  - the learning CPU (learn.lisp) reads on its own clock in AI-REFLEX before the kit's :reflex (LEARN-READ-DUE): a reflex
    that answers every free step (or resets BRAIN-DECIDE-T) starves AI-DECIDE's neutral (DREAM_RSI §5.7) — prefer acting on
    events, return NIL when there is nothing to do;
  - the ASSIST borrows a HARD brain for a human player (assist.lisp, *AI-BRAIN*): any kit hook the ASSIST calls (:sp-ender
    :sig-hold :assist-guard, if you add one) reads its brain through (ai-brain e), never (brain e); the sim ticks' (brain e)
    branches are his own CPU's only and must never act for a human.
- difficulty layering (the user's rule): every new or changed chance scales with (brain-difficulty b) EASY <= NORMAL <=
  HARD (LB-AI-CHANCE, or (getf '(:easy .. :normal .. :hard ..) (brain-difficulty b))); NORMAL close to the shipped CPU,
  HARD the full version. Roll ONCE PER EVENT (an opponent action's react roll, a threatening window, a stance, a string),
  never per step: a chance rolled every step is a certainty within a second — think of any per-step test as "times per
  second" (DREAM_RSI §5.5). A reaction slower than the threat never fires.
- the CPU sees the opponent only through its perceived SNAP (the perception delay) and its own state, as the existing code;
  no input reading, no debug knobs, no seed / tick special cases, nothing keyed to the evaluator.
- determinism: random numbers only via SIM-RND01 (or the brain's event rolls), never RND01 / RANDOM.

# Step 4. Evaluate honestly
In your worktree:
1. {ECL} --norc --load tests/duel-rules-test.lisp  must print ALL PASS. The file's section between the markers
   ";;; >>> BEGIN LILLE-CPU-TESTS" and ";;; <<< END LILLE-CPU-TESTS" checks HIS OWN CPU (the shipped values of his kits'
   :ai keys: :eye, :stance, :switch, :trompete, :sig in the base bands; *LB-AI-FS-RESERVE*; LB-AI-CHANCE,
   LB-AI-KAMAE-PLAN, LB-SWITCH-IN-RULE, LB-AI-LAY-OK-P / LB-AI-OUT-OK-P, the eye / stance plans and exits). You may edit
   THAT SECTION ONLY, to match what your CPU now does, and deliver the whole file (below): the coordinator splices only the
   lines between the markers into the frozen test; everything outside them stays frozen (shared behaviour, the rules, the
   hooks such as :reflex LB-AI-REFLEX, the keys a CPU facing him reads, the other characters). The section's checks must
   still pin your own shipped values and contracts (update a pinned value to yours, don't delete the pin), and may not
   weaken a test of shared behaviour, a rule, a hook or another character; the coordinator reviews the section's diff.
2. touch duel/lisp/lille.lisp (the native build goes by mtime), then run the EVAL_COMMAND (the first run builds the native
   sim, ~3 min). It prints one JSON line. Another cell runs on this machine at the same time: keep -j as given.
3. If you changed the awakening (base -> JILLIEL) or the revival: the awaken A/B, Lille P1 "never awaken" vs each other
   character (pairings 15-19), python3 tools/simgate.py --pairs 15,16,17,18,19 --seed0 S --seeds 60 --cmd 39020 -j 2 for S
   in 100, 300, 500: report the never-awaken side's wins per stream next to the baseline's (DUEL_LILLE §20.3).
You may iterate inside the cell, but the cell's result is the LAST file you deliver and its LAST measured JSON (the
coordinator re-measures it with the frozen evaluator anyway). Never edit tools/aieval.py or anything it reads.

# Deliverables (inside YOUR worktree, at the fixed relative path NODE_DIR; the coordinator copies them)
- NODE_DIR/lille.lisp: your final duel/lisp/lille.lisp
- NODE_DIR/proposal.md: the action policy per form, the mechanisms implemented, the evidence from the history, why it is
  not a repeat, the measurement (each part, sig_by, drift and pacing vs the baseline), the expected benefit, the risks
  (a pacing median within 15 s of its cap is a risk), shared-code recommendations if any.
- NODE_DIR/score.json: the exact JSON line the EVAL_COMMAND printed for that final file.
- NODE_DIR/duel-rules-test.lisp (only if you edited its LILLE-CPU-TESTS section): your whole tests/duel-rules-test.lisp.
Keep scratch files under a directory named after your cell (e.g. scratchpad/lille-{cell}/), never in NODE_DIR. Do not
commit, push, merge or open PRs. Never run pkill / kill / killall; no self-matching pgrep loops; bounded waits only (wait
on a PID or with a timeout).

# Report back
The exact JSON line of the final evaluation (do not round or improve it), the path of your worktree, and on failure the
failure class (compile_other, correctness, runtime, resource) with the error text.
""")
