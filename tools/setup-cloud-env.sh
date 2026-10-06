#!/usr/bin/env bash
# setup-cloud-env.sh - recreate the ai-cl-game-test (SOUL DUEL) toolchain in a fresh Ubuntu 24.04 x86_64 cloud
# container, at exactly the paths the repo's scripts hard-code (no env overrides needed):
#   host ECL 24.5.10, 32-bit i386, no threads  -> /media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl
#   emsdk 4.0.12                                -> /media/8tsp/projects/emsdk
#   google-chrome (Playwright Chromium symlink) -> /usr/local/bin/google-chrome
#   /tmp/claude-1000                            (tools/run.mjs mkdtemps its Chrome profile there)
# vendor/ (wasm ECL, SDL3-webgpu, emdawn) is already in the repo and is not rebuilt.
# Idempotent: each step is skipped when its result exists. Runs as root. ~15 min on 4 cores.
# Downloads go through the agent proxy (CA bundle preconfigured). ecl.common-lisp.dev is blocked (403) by the
# egress policy here, so the ECL source comes from GitLab's tag archive (same 24.5.10 tree, bundled gmp/bdwgc/libffi).
set -euo pipefail
P=/media/8tsp/projects
J=$(nproc)
mkdir -p "$P/dl"

# 1. apt: 32-bit gcc (host ECL is -m32; simgate builds musl libm with gcc -m32 and the .fas with ECL's gcc -m32)
if ! dpkg -s gcc-multilib >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y gcc-multilib g++-multilib
fi
# (simgate's musl is emscripten's own musl source compiled by gcc -m32 into build/simgate/muslm.so: no musl-tools needed)

# 2. emsdk 4.0.12
if [ ! -x "$P/emsdk/upstream/emscripten/emcc" ]; then
  [ -d "$P/emsdk" ] || git clone https://github.com/emscripten-core/emsdk.git "$P/emsdk"
  (cd "$P/emsdk" && ./emsdk install 4.0.12 && ./emsdk activate 4.0.12)
fi

# 3. host ECL 24.5.10, 32-bit (README "從頭建置 ECL 交叉編譯工具鏈" step 1 / ECL INSTALL "Cross-compile for the WASM platform")
if [ ! -x "$P/ecl-24.5.10/ecl-emscripten-host/bin/ecl" ]; then
  [ -f "$P/dl/ecl-24.5.10.tar.gz" ] || curl -fsSL -o "$P/dl/ecl-24.5.10.tar.gz" \
    https://gitlab.com/embeddable-common-lisp/ecl/-/archive/24.5.10/ecl-24.5.10.tar.gz
  [ -d "$P/ecl-24.5.10" ] || tar xzf "$P/dl/ecl-24.5.10.tar.gz" -C "$P"
  (cd "$P/ecl-24.5.10" \
    && ./configure ABI=32 CFLAGS="-m32 -g -O2" LDFLAGS="-m32 -g -O2" \
         --prefix="$P/ecl-24.5.10/ecl-emscripten-host" --disable-threads \
    && make -j"$J" && make install)
  # README then does `rm -rf build/` (that dir is reused by the wasm cross build, which vendor/ecl already holds)
fi

# 4. headless browser for tools/run.mjs (spawns $CHROME_BIN or `google-chrome`; do not `playwright install`).
# A wrapper, not a bare symlink: the container has no Vulkan ICD (/etc/vulkan/icd.d is empty), so with run.mjs's
# default flags (--use-angle=vulkan --use-vulkan=swiftshader ...) ANGLE fails "Extension not supported: VK_KHR_surface",
# the GPU process exits and requestDevice throws "A valid external Instance reference no longer exists" (run.mjs then
# hangs until timeout). VK_ICD_FILENAMES -> Chromium's bundled SwiftShader ICD fixes it with the default flags.
CHDIR=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux 2>/dev/null | sort -V | tail -1)
if [ -n "$CHDIR" ]; then
  rm -f /usr/local/bin/google-chrome
  cat > /usr/local/bin/google-chrome <<EOF
#!/bin/sh
# Playwright Chromium as google-chrome for tools/run.mjs, with the bundled SwiftShader Vulkan ICD (see setup-cloud-env.sh)
export VK_ICD_FILENAMES=\${VK_ICD_FILENAMES:-$CHDIR/vk_swiftshader_icd.json}
exec "$CHDIR/chrome" "\$@"
EOF
  chmod +x /usr/local/bin/google-chrome
fi
mkdir -p /tmp/claude-1000 && chmod 1777 /tmp/claude-1000   # run.mjs hard-codes mkdtemp('/tmp/claude-1000/chrome-')

# 5. Python deps of the image tools (tests/style-*-checks.py, tools/toon_check.py ...); simgate / style-gates cvc need none
python3 -c 'import PIL, numpy' 2>/dev/null || python3 -m pip install -q pillow numpy

"$P/ecl-24.5.10/ecl-emscripten-host/bin/ecl" --norc --eval '(progn (print (lisp-implementation-version)) (print most-positive-fixnum) (terpri) (ext:quit 0))'
"$P/emsdk/upstream/emscripten/emcc" --version | head -1
google-chrome --version
echo "setup done. Try: ./build.sh duel (from the repo root)"
