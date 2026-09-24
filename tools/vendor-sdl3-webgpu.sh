#!/usr/bin/env bash
# Rebuild vendor/sdl3-webgpu (SDL3 with the experimental SDL_GPU WebGPU backend) and vendor/emdawn.
# SDL: libsdl-org/SDL PR #16020 (draft, not merged) at a pinned commit + our local fixes
# (vendor/sdl3-webgpu.patch, see docs/DEVLOG.zh-TW.md). Dawn's emdawnwebgpu must match the
# webgpu.h that SDL bundles — emscripten 4.0.12's built-in port is too old (enum values differ).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC=${SDL_SRC:-/media/8tsp/projects/SDL-webgpu}
SDL_COMMIT=971edb04308723734da2865ccd3005eab862398d
DAWN=v20260917.220300
source "${EMSDK_DIR:-/media/8tsp/projects/emsdk}/emsdk_env.sh" >/dev/null 2>&1

if [ ! -d "$SRC/.git" ]; then git init -q "$SRC"; fi
git -C "$SRC" fetch -q --depth 1 https://github.com/libsdl-org/SDL pull/16020/head
git -C "$SRC" checkout -q -f "$SDL_COMMIT"
git -C "$SRC" apply "$ROOT/vendor/sdl3-webgpu.patch"
emcmake cmake -S "$SRC" -B "$SRC/build-em" -DCMAKE_BUILD_TYPE=Release -DSDL_SHARED=OFF -DSDL_STATIC=ON \
  -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF -DSDL_WEBGPU=ON -DSDL_OPENGL=OFF -DSDL_OPENGLES=OFF -DSDL_RENDER=OFF -DCMAKE_INSTALL_PREFIX="$ROOT/vendor/sdl3-webgpu" >/dev/null
cmake --build "$SRC/build-em" -j"$(nproc)"
rm -rf "$ROOT/vendor/sdl3-webgpu"; cmake --install "$SRC/build-em" >/dev/null

rm -rf "$ROOT/vendor/emdawn"; mkdir -p "$ROOT/vendor/emdawn"
curl -sL "https://github.com/google/dawn/releases/download/$DAWN/emdawnwebgpu_pkg-$DAWN.zip" -o "$ROOT/vendor/emdawn/pkg.zip"
(cd "$ROOT/vendor/emdawn" && unzip -q pkg.zip && rm pkg.zip)
echo "vendor/sdl3-webgpu and vendor/emdawn ready"
