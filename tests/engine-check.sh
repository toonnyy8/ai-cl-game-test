#!/usr/bin/env bash
# Build and run tests/engine-check.lisp headless; prints its log and exits 1 unless every check passed
# and the stats line carries fx-dropped. Screenshots: tests/shots/ec-*.png (look at them).
set -uo pipefail
cd "$(dirname "$0")/.."
./build.sh echeck tests/engine-check.lisp || exit 1
LOG=build/echeck/run.log
node tools/run.mjs dist/echeck --secs 33 --script tests/scripts/engine-check.json > "$LOG" 2>&1
grep -E "check |consed:|pad-count|sim-rnd|rnd01|key-pressed|mouse-pressed|audio: sound slot|grade-desat|engine-check|EXCEPTION|stats:" "$LOG"
grep -q "engine-check: [0-9]* pass, 0 fail" "$LOG" && grep -q "| fx-dropped [0-9]" "$LOG" \
  && grep -q "audio: sound slot 200 out of range" "$LOG" && echo "ENGINE-CHECK OK" || { echo "ENGINE-CHECK FAILED (log: $LOG)"; exit 1; }
