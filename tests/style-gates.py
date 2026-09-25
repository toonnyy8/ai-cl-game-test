#!/usr/bin/env python3
"""style-gates.py — the Storm x Kubo restyle's harness (docs/STYLE_STORM_DESIGN.md §9: Phase 0 and the
standing gates G1 RAVEN identity, G2 duel determinism, G3 budgets). Run from the repository root; the
dists are built with ./build.sh (a BASE dist is a copy of dist/NAME built before the change).

  python3 tests/style-gates.py raven BASE NEW       G1 frozen stills: RAVEN title + a bot-played wave under
                                                    run.mjs --fixed-dt, BASE twice (noise floor) and NEW once;
                                                    byte / pixel identity and cons/frame (NEW within +10 %)
  python3 tests/style-gates.py rc BASE_ROOT         G1 ECL C: RAVEN's generated C, function by function, of this
                                                    tree vs the tree at BASE_ROOT (needs BASE_ROOT/vendor)
  python3 tests/style-gates.py cvc DIST             G2: result + hash lines of duel-cvc-{yy,yk,kk}.json vs
                                                    tests/style-cvc-ref.txt
  python3 tests/style-gates.py perf A B game|duel   G1/G3: A B A B A B real-time runs, median frame ms; startup
                                                    heap and first frame of each
  python3 tests/style-gates.py smoke DIST...        WGSL smoke: each dist runs 14 s with run.mjs exit 0 (no JS
                                                    exception, no WebGPU validation error, every pipeline built)
  python3 tests/style-gates.py duelstill DIST OUT [--flat]
                                                    the frozen duel still (dist/duelvfx scene 17): OUT.png, OUT-bg.png
                                                    (no fighters = the mask for tools/toon_check.py --bg), OUT-ink.png
                                                    (no shadow discs: toon_check --outline against OUT-bg) and with
                                                    --flat OUT-flat.png + OUT-flat-bg.png (duel-vfx 3005: no gradient,
                                                    character fog or vignette: palette-exact tones)
Every command prints PASS / FAIL lines and exits 1 on a FAIL. Temporary files go to build/style/.
"""
import json, os, re, statistics, subprocess, sys
import numpy as np
from PIL import Image

TMP = "build/style"
ECL = os.environ.get("ECL_HOST", "/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl")
os.makedirs(TMP, exist_ok=True)
fails = []


def check(name, ok, text=""):
    print(f"{'PASS' if ok else 'FAIL'} {name}{': ' + text if text else ''}", flush=True)
    if not ok: fails.append(name)


def cmd(t, c): return {"at": t, "eval": f"Module._debug_cmd({c})"}


def script(name, steps):
    p = f"{TMP}/{name}.json"; json.dump(steps, open(p, "w")); return p


def run(dist, sc, secs, log, fixed=True, size="1280x720"):
    """Start run.mjs (returns the Popen; the console goes to LOG)."""
    args = ["node", "tools/run.mjs", dist, "--secs", str(secs), "--script", sc, "--size", size]
    if fixed: args += ["--fixed-dt", "16.666667"]
    return subprocess.Popen(args, stdout=open(log, "w"), stderr=subprocess.STDOUT)


def px_diff(a, b):
    x = np.asarray(Image.open(a).convert("RGB")).astype(int); y = np.asarray(Image.open(b).convert("RGB")).astype(int)
    return int((np.abs(x - y).max(-1) > 0).sum()) if x.shape == y.shape else -1


def cons(log):
    v = [int(m.group(1)) for m in re.finditer(r"cons/frame (\d+) B", open(log).read())]
    return statistics.mean(v[1:]) if len(v) > 1 else (v[0] if v else 0)


def raven(base, new):
    out = []
    for tag, dist in (("base1", base), ("base2", base), ("new", new)):
        sc = script(f"raven-{tag}", [{"at": 4.0, "shot": f"{TMP}/raven-{tag}-title.png"}, cmd(4.05, 63), cmd(4.1, 13),
                                     cmd(4.15, 16), cmd(4.2, 18), {"at": 9.0, "shot": f"{TMP}/raven-{tag}-wave.png"}])
        out.append((tag, run(dist, sc, 9.2, f"{TMP}/raven-{tag}.log")))
    for tag, p in out: check(f"raven {tag} run", p.wait() == 0)
    for shot in ("title", "wave"):
        noise = px_diff(f"{TMP}/raven-base1-{shot}.png", f"{TMP}/raven-base2-{shot}.png")
        d = px_diff(f"{TMP}/raven-base1-{shot}.png", f"{TMP}/raven-new-{shot}.png")
        same = open(f"{TMP}/raven-base1-{shot}.png", "rb").read() == open(f"{TMP}/raven-new-{shot}.png", "rb").read()
        check(f"G1 raven {shot} still", noise == 0 and d == 0, f"noise floor {noise} px, base vs new {d} px, bytes {'identical' if same else 'differ'}")
    cb, cn = cons(f"{TMP}/raven-base1.log"), cons(f"{TMP}/raven-new.log")
    check("G1 raven cons/frame", cn <= 1.1 * cb + 1, f"base {cb:.0f} B, new {cn:.0f} B")


def c_functions(path):
    """ECL C file -> {lisp function name: normalised body} (L/LC numbers, VV indices, labels and gensym'd
    lambda names folded)."""
    fns, name, body = {}, None, []
    for line in open(path, errors="replace"):
        m = re.match(r"/\*\s+(?:function definition|local function|closure) for (.+?)\s*\*/", line)
        if m:
            if name: fns.setdefault(name, []).append("".join(body))
            name, body = m.group(1), []
        elif line.startswith("#include"):                 # the module init (paths, hashes) follows the last function
            if name: fns.setdefault(name, []).append("".join(body))
            name = None
        elif name: body.append(re.sub(r"\b(LC?|VV|T|V|v)\d+|(lambda|LAMBDA)\d+", lambda m: (m.group(1) or m.group(2)) + "#",
                                      re.sub(r"VV\[\d+\]", "VV[#]", line)))
    if name: fns.setdefault(name, []).append("".join(body))
    return fns


def rc(base_root):
    files = []
    for m in ("engine/MANIFEST", "game/MANIFEST"):
        d = os.path.dirname(m)
        files += [f"{d}/{l.strip()}" for l in open(m) if l.strip() and not l.startswith("#") and l.strip().endswith(".lisp")]
    procs = []
    for tag, root in (("base", base_root), ("new", ".")):
        out = os.path.abspath(f"{TMP}/rc-{tag}")
        procs.append(subprocess.Popen([ECL, "--norc", "--eval", "(require :cmp)", "--eval", "(setf c::*delete-files* nil)",
                                       "--load", f"{root}/tools/build.lisp", "--", os.path.relpath(out, os.path.abspath(root))] + files,
                                      cwd=root, stdout=open(f"{TMP}/rc-{tag}.log", "w"), stderr=subprocess.STDOUT))
    for p in procs: check("ECL C generation", p.wait() == 0)
    a, b = c_functions(f"{TMP}/rc-base/game-all.c"), c_functions(f"{TMP}/rc-new/game-all.c")
    changed = sorted(k for k in a if k in b and a[k] != b[k])
    print(f"RAVEN C: {len(a)} functions before, {len(b)} after; identical {sum(1 for k in a if k in b and a[k] == b[k])}")
    print("  changed: " + (", ".join(changed) or "-"))
    print("  added:   " + (", ".join(sorted(set(b) - set(a))) or "-"))
    print("  removed: " + (", ".join(sorted(set(a) - set(b))) or "-"))


def cvc(dist):
    ref = {}
    for l in open("tests/style-cvc-ref.txt"):
        if not l.startswith("#"): ref.setdefault(l[:2], []).append(l[3:].rstrip("\n"))
    procs = {p: run(dist, f"tests/scripts/duel-cvc-{p}.json", 60, f"{TMP}/cvc-{p}.log", fixed=False) for p in ref}
    for p, pr in procs.items():
        pr.wait()
        got = [l.rstrip("\n") for l in open(f"{TMP}/cvc-{p}.log") if re.match(r"duel (-> RESULTS winner|hash)", l)]
        res = [l for l in got if "RESULTS" in l]
        check(f"G2 cvc {p}", got == ref[p], f"{res[-1] if res else 'no RESULTS line'}; {len(got)} lines vs {len(ref[p])}")


def perf(a, b, target):
    if target == "game":
        steps = [cmd(6.0, 63), cmd(6.1, 62)]          # the title (a bot-played wave varies too much in real time)
    else:
        steps = [cmd(9.0, 4003), cmd(9.1, 2106)]
    sc = script(f"perf-{target}", steps)
    res = {a: [], b: []}; heap = {a: [], b: []}; first = {a: [], b: []}
    for i in range(6):
        d = (a, b)[i % 2]; log = f"{TMP}/perf-{target}-{i}.log"
        run(d, sc, 45, log, fixed=False).wait()
        t = open(log).read()
        ms = [float(x) for x in re.findall(r"perf: .*?frame ([\d.]+) ms avg", t)][2:]   # skip load / first windows
        res[d].append(statistics.mean(ms) if ms else float("nan"))
        heap[d] += [float(x) for x in re.findall(r"startup: heap ([\d.]+) MB", t)]
        first[d] += [float(x) * 1000 for x in re.findall(r"\[run\] startup done ([\d.]+) s", t)]
    for d in (a, b):
        print(f"{d}: frame ms {' '.join(f'{x:.1f}' for x in res[d])} median {statistics.median(res[d]):.1f} | "
              f"startup heap {max(heap[d] or [0]):.1f} MB | startup (page to first frame) {statistics.median(first[d] or [0]):.0f} ms")
    ra, rb = statistics.median(res[a]), statistics.median(res[b])
    print(f"B / A frame time = {rb / ra:.3f}")
    check("G3 startup heap <= 110 MB", max(heap[b] or [999]) <= 110.0)
    check("G3 first frame <= +10 %", statistics.median(first[b] or [1e9]) <= 1.1 * statistics.median(first[a] or [1]))


def smoke(dists):
    procs = [(d, subprocess.Popen(["node", "tools/run.mjs", d, "--secs", "14"], stdout=open(f"{TMP}/smoke-{os.path.basename(d)}.log", "w"),
                                  stderr=subprocess.STDOUT)) for d in dists]
    for d, p in procs:
        rc_ = p.wait()
        bad = [l.strip() for l in open(f"{TMP}/smoke-{os.path.basename(d)}.log") if re.search(r"WebGPU:|pipeline .* failed|EXCEPTION", l)]
        check(f"WGSL smoke {d}", rc_ == 0 and not bad, "; ".join(bad[:3]))


def duelstill(dist, out, flat):
    steps = [cmd(3.0, 2017), cmd(3.02, 3003), cmd(3.04, 3004), cmd(3.06, 4500), {"at": 4.0, "shot": f"{out}.png"},
             cmd(4.02, 3002), {"at": 4.1, "shot": f"{out}-bg.png"}]
    if flat: steps += [cmd(4.12, 3005), {"at": 4.2, "shot": f"{out}-flat-bg.png"}, cmd(4.22, 3002), {"at": 4.3, "shot": f"{out}-flat.png"},
                       cmd(4.32, 3005), cmd(4.34, 3002)]
    steps += [cmd(4.36, 3002), cmd(4.38, 3006), {"at": 4.46, "shot": f"{out}-ink.png"}]     # no shadow discs: toon_check --outline
    check("duel frozen still", run(dist, script("duelstill", steps), 4.6, f"{TMP}/duelstill.log").wait() == 0, out)


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a: print(__doc__); sys.exit(2)
    {"raven": lambda: raven(a[1], a[2]), "rc": lambda: rc(a[1]), "cvc": lambda: cvc(a[1]),
     "perf": lambda: perf(a[1], a[2], a[3]), "smoke": lambda: smoke(a[1:]),
     "duelstill": lambda: duelstill(a[1], a[2], "--flat" in a)}[a[0]]()
    sys.exit(1 if fails else 0)
