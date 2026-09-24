#!/usr/bin/env bash
# Rebuild vendor/ecl from an ECL tree cross-built for wasm32-unknown-emscripten
# (see ECL's INSTALL, "Cross-compile for the WASM platform").
set -euo pipefail
ECL_SRC=${ECL_SRC:-/media/8tsp/projects/ecl-24.5.10}
EM=${EM:-/media/8tsp/projects/emsdk/upstream/emscripten}
B=$ECL_SRC/build; V=$(cd "$(dirname "$0")/.." && pwd)/vendor/ecl
rm -rf "$V"; mkdir -p "$V/include" "$V/tmp"
cp "$B/libeclmin.a" "$V/libecl.a"   # libecl.a = C core + compiled lisp core + symbols
(cd "$V/tmp" && "$EM/emar" x "$B/liblsp.a" && for i in *.o; do mv "$i" "lsp_$i"; done \
   && "$EM/emar" r ../libecl.a *.o "$B/c/all_symbols2.o")
rm -rf "$V/tmp"; "$EM/emranlib" "$V/libecl.a"
cp "$B/libeclgc.a" "$B/libeclgmp.a" "$V/"
cp -r "$ECL_SRC/ecl-emscripten/ecl" "$V/include/ecl"
