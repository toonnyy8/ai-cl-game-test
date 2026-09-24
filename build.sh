#!/usr/bin/env bash
# Build a target to wasm. The engine (engine/MANIFEST) always comes first.
#   ./build.sh                      -> dist/game/        the game, from game/MANIFEST
#   ./build.sh DIR                  -> dist/<basename>/  the target described by DIR/MANIFEST
#   ./build.sh NAME a.lisp b.c ...  -> dist/NAME/        engine + the given files, in order (tests)
# A MANIFEST lists sources relative to its own directory, in compile order. .lisp files (engine and
# target together) form one compilation unit for ECL; .c files are compiled by emcc at link time.
# An optional line "# title: ..." sets the page title (engine/web/shell.html).
# Env: GAME_OPT (default -O2) C optimisation for Lisp code; EMCC_EXTRA extra link flags.
# Rendering: SDL_GPU on the WebGPU backend = vendor/sdl3-webgpu (SDL PR #16020 + our patch) and
# Dawn's emdawnwebgpu port (tools/vendor-sdl3-webgpu.sh rebuilds both).
set -euo pipefail
cd "$(dirname "$0")"
EMSDK_DIR=${EMSDK_DIR:-/media/8tsp/projects/emsdk}
ECL_HOST=${ECL_HOST:-/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl}
source "$EMSDK_DIR/emsdk_env.sh" >/dev/null 2>&1

manifest() { grep -v '^\s*\(#\|$\)' "$1/MANIFEST" | sed "s|^|$1/|"; }   # DIR/MANIFEST -> "DIR/file" lines

if [ $# -gt 1 ]; then
  NAME=$1; shift; FILES=("$@"); TITLE=$NAME
else
  DIR=${1:-game}; DIR=${DIR%/}; NAME=$(basename "$DIR")
  [ -f "$DIR/MANIFEST" ] || { echo "no $DIR/MANIFEST"; exit 1; }
  mapfile -t FILES < <(manifest "$DIR")
  TITLE=$(sed -n 's/^# *title: *//p' "$DIR/MANIFEST" | head -1); TITLE=${TITLE:-$NAME}
fi
mapfile -t ENGINE < <(manifest engine)
LISP=() CSRC=()
for f in "${ENGINE[@]}" "${FILES[@]}"; do
  case $f in *.lisp) LISP+=("$f") ;; *.c) CSRC+=("$f") ;; *) echo "unknown source type: $f"; exit 1 ;; esac
done
OUT=build/$NAME DIST=dist/$NAME
rm -rf "$OUT"; mkdir -p "$OUT" "$DIST"

"$ECL_HOST" --norc --load tools/build.lisp -- "$OUT" "${LISP[@]}" > "$OUT/lisp.log" 2>&1 \
  || { grep -B2 -A12 -iE "error|warning" "$OUT/lisp.log" | head -80; echo "LISP BUILD FAILED (full log: $OUT/lisp.log)"; exit 1; }
grep -A6 -E "^;;; (Warning|Style warning)|WARNING" "$OUT/lisp.log" | head -60 || true

sed "s|@TITLE@|$(printf '%s' "$TITLE" | sed 's/[&|\\]/\\&/g')|g" engine/web/shell.html > "$OUT/shell.html"
# addRunDependency/removeRunDependency: the shell requests the WebGPU device before main()
emcc -O2 -DECL_C_COMPATIBLE_VARIADIC_DISPATCH -I. -Ivendor/ecl/include -Ivendor/sdl3-webgpu/include \
  --use-port=vendor/emdawn/emdawnwebgpu_pkg/emdawnwebgpu.port.py \
  "${CSRC[@]}" "$OUT/libgame.a" vendor/ecl/libecl.a vendor/ecl/libeclgc.a vendor/ecl/libeclgmp.a vendor/sdl3-webgpu/lib/libSDL3.a \
  -sSTACK_SIZE=4MB -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=128MB \
  -sEXPORTED_RUNTIME_METHODS=addRunDependency,removeRunDependency \
  --shell-file "$OUT/shell.html" ${EMCC_EXTRA:-} -o "$DIST/index.html"
echo "built $DIST/index.html"
