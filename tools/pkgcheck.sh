#!/usr/bin/env bash
# ECL doesn't warn about undefined functions, so a game calling an unexported engine function (or a
# typo, or a deleted helper) compiles silently. This reads (doesn't compile) the engine + a target's
# sources and reports: target symbols shadowing ENGINE internals, target DEF*s redefining ENGINE
# exports, and functions called but defined nowhere (tools/pkgcheck.lisp). Exit status 1 if any.
#   tools/pkgcheck.sh game   |   tools/pkgcheck.sh examples/hello   |   tools/pkgcheck.sh file.lisp...
cd "$(dirname "$0")/.."
ECL_HOST=${ECL_HOST:-/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl}
m() { grep -v '^\s*\(#\|$\)' "$1/MANIFEST" | sed "s|^|$1/|" | grep 'lisp$'; }
if [ -d "$1" ]; then T=$(m "$1"); else T="$*"; fi
"$ECL_HOST" --norc --load tools/pkgcheck.lisp -- $(m engine) $T 2>&1 | grep -v "^;;;"
exit ${PIPESTATUS[0]}
