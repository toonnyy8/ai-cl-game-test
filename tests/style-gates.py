#!/usr/bin/env python3
"""style-gates.py — the Storm x Kubo restyle's harness (docs/style/STYLE_STORM_DESIGN.md §9: Phase 0 and the
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
  python3 tests/style-gates.py looks BASE NEW [--jobs N] [--size WxH] [--only TEXT] [--once]
                                                    the look identity gate (for refactors that must not change a
                                                    pixel): 109 fixed stills of SOUL DUEL under run.mjs --fixed-dt
                                                    (menus, select of all six fighters, four CPU-vs-CPU matches at
                                                    several times, Kikon / awakening / form-change cinematics, HUD
                                                    in every form, VFX, ENDLESS, the portrait touch layout, results)
                                                    from BASE twice (noise floor) and NEW once; per still the max abs
                                                    channel diff and the differing pixels, a diff image in
                                                    build/style/looks/diff/ for any that differ, and the sim's
                                                    `duel hash` lines; PASS only when NEW matches BASE within the
                                                    noise floor (0 on a quiet machine)
  python3 tests/style-gates.py duelstill DIST OUT [--flat]
                                                    the frozen duel still (dist/duelvfx scene 17): OUT.png, OUT-bg.png
                                                    (no fighters = the mask for tools/toon_check.py --bg), OUT-ink.png
                                                    (no shadow discs: toon_check --outline against OUT-bg) and with
                                                    --flat OUT-flat.png + OUT-flat-bg.png (duel-vfx 3005: no gradient,
                                                    character fog or vignette: palette-exact tones)
Every command prints PASS / FAIL lines and exits 1 on a FAIL. Temporary files go to build/style/.
"""
import json, os, re, statistics, subprocess, sys, time
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


def run(dist, sc, secs, log, fixed=True, size="1280x720", extra=()):
    """Start run.mjs (returns the Popen; the console goes to LOG)."""
    args = ["node", "tools/run.mjs", dist, "--secs", str(secs), "--script", sc, "--size", size, *extra]
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


# ---------------------------------------------------------------- looks: the look identity gate (for refactors)
LOOKS_START = 4.0          # virtual s of the first event: the title stands from ~2 s on (raven's G1 uses 4.0 too)
# 2000+seed is a CPU-vs-CPU match whose two fighters are drawn from the seed (xorshift32 over the six-fighter roster
# Y K R I S L): seed 1 = Yamamoto-Senjumaru, 5 Ichigo-Rukia, 0 Kenpachi-Lille, 18 Senjumaru-Ichigo
# (every fighter in a match; the "duel match" log line is checked against this table)
LOOKS_SEEDS = ((1, "YS"), (5, "IR"), (0, "KL"), (18, "SI"))
LOOKS_WINDOWS = ((2, (0.1,)), (8, (0.1, 0.4)), (16, (0.1,)), (30, (0.1,)))   # (turbo frames of 120 steps, the live shots after)
# the cinematics at their key frames: (still name, debug command base, frames); 10000 + 1000 k + f is debug.lisp's, the
# others a character's own range (75300 + k: Ichigo's awakening at frame 2k; 79100 + k: Lille's at frame 10k)
LOOKS_CINES = {
    "cine-yama": [("yama-kikon", 12000, (20, 112)), ("yama-bankai", 10000, (30, 74, 128)), ("ko", 18000, (12, 60))],
    "cine-ken": [("ken-kikon", 14000, (20, 80)), ("ken-nozarashi", 11000, (26, 96)), ("ken-bankai", 35000, (30, 80, 120))],
    "cine-rukia": [("rukia-kikon", 40000, (60, 112)), ("rukia-awaken", 42000, (20, 60, 110)), ("rukia-hakka", 41000, (60, 120))],
    "cine-ichigo": [("ichigo-awaken", 75300, (10, 30, 55))],
    "cine-senju": [("senju-awaken", 78000, (30, 90, 150))],
    "cine-lille": [("lille-awaken", 79100, (3, 9, 15))],
}
LOOKS_FRAMES = {75300: 2, 79100: 10}      # cinematic frames per unit of the command's last digits


def looks_scenarios():
    """name -> (steps, secs, extra run.mjs args); a step's 'shot' is the still's name (looks() maps it to its file)."""
    sc = {}
    def key(s, t, k): s += [{"at": round(t, 3), "key": k, "down": True}, {"at": round(t + 0.08, 3), "key": k, "down": False}]
    def shot(s, t, name): s.append({"at": round(t, 3), "shot": name})
    def ev(s, t, c): s.append(cmd(round(t, 3), c))
    def tap(s, t, x, y): s.extend([{"at": round(t, 3), "touch": "start", "x": x, "y": y}, {"at": round(t + 0.05, 3), "touch": "end", "x": x, "y": y}])
    def done(s): return max(e["at"] for e in s) + 0.3

    # menus: title, MODE, SETTINGS, CONTROLS, then the select screen with each of the six fighters (P1's cycle)
    s, t = [], LOOKS_START
    shot(s, t, "title"); key(s, t + 0.3, "Enter"); shot(s, t + 0.9, "mode")
    t += 1.2
    for i in range(5): key(s, t + 0.15 * i, "ArrowDown")
    key(s, t + 0.9, "Enter"); shot(s, t + 1.5, "settings"); key(s, t + 1.7, "Escape")
    key(s, t + 2.1, "ArrowDown"); key(s, t + 2.4, "Enter"); shot(s, t + 3.0, "controls"); key(s, t + 3.2, "Escape")
    key(s, t + 3.6, "ArrowUp"); key(s, t + 3.8, "ArrowUp"); key(s, t + 4.0, "Enter")          # CPU VS CPU
    t += 4.5
    for i in range(6):
        shot(s, t, f"select-{i}"); key(s, t + 0.1, "ArrowRight"); t += 0.6
    sc["menus"] = (s, done(s), ())

    # CPU vs CPU: the intro, the first frame of the fight (Enter skips the intro), then jumps in turbo (2102: 120 steps a
    # frame, so exactly 120 n ticks in n frames, nothing drawn) each followed by live frames: the effects, hits and
    # cinematics that are on screen at that tick
    for seed, pair in LOOKS_SEEDS:
        s, t = [], LOOKS_START
        ev(s, t, 2000 + seed); shot(s, t + 1.5, "intro"); key(s, t + 1.6, "Enter"); shot(s, t + 2.3, "start")
        t += 2.4
        for w, (n, shots) in enumerate(LOOKS_WINDOWS):
            ev(s, t, 2102); t += n / 60.0 + 0.004; ev(s, t, 2102)
            for j, d in enumerate(shots): shot(s, t + d, f"w{w}-{j}")
            t += max(shots) + 0.05
            if w == 1 and seed == LOOKS_SEEDS[0][0]: key(s, t, "Escape"); shot(s, t + 0.5, "pause"); key(s, t + 0.7, "Escape"); t += 1.0
        sc[f"cvc-{pair.lower()}"] = (s, done(s), ())

    # the cinematics at their key frames (later frames of the same cinematic continue it); one script per fighter's set
    for name, lst in LOOKS_CINES.items():
        s, t = [], LOOKS_START
        for cname, base, frames in lst:
            last = 0
            for f in frames:
                ev(s, t, base + f)
                cf = f * LOOKS_FRAMES.get(base, 1)                       # the cinematic frame
                t += (1.0 if last == 0 else 0.35) + (cf - last) / 60.0
                shot(s, t, f"{cname}-{cf:03d}"); t += 0.1; last = cf
        if name == "cine-yama": ev(s, t, 2209); shot(s, t + 3.5, "results")                 # the K.O., then RESULTS
        sc[name] = (s, done(s), ())

    # looks that are not on screen at a chosen tick: the HUD in every form (2430+k), sword smears, the Bankai's cracks and
    # impact stamps (2312, 2366), Rukia's ice, Senjumaru's bolts of cloth, stitches, umbrella and drapes (2450+k), Lille's
    # wings and claws (79197 / 79198, each 79198 the next of her four forms): (command, seconds to the still, still name)
    for name, lst in (("fx-a", [(2430, 0.6, "hud-0"), (2433, 0.6, "hud-3"), (2434, 0.6, "hud-4"), (2437, 0.6, "hud-7"),
                                (2309, 0.4, "smear-a"), (None, 0.55, "smear-b"), (2312, 0.8, "bankai-crack"), (2366, 0.8, "destruction"),
                                (2302, 0.9, "fire-wave"), (2306, 0.67, "guard-break")]),
                      ("fx-b", [(2412, 1.0, "rukia-m50"), (2413, 0.3, "rukia-freeze-touch"), (2418, 1.0, "rukia-zero"),
                                (2470, 0.8, "senju-hank1"), (2473, 0.8, "senju-hank4"), (2476, 0.8, "senju-stitches"),
                                (2477, 0.7, "senju-umbrella"), (2481, 0.8, "senju-drapes"),
                                (79198, 0.8, "lille-jilliel"), (79198, 0.8, "lille-kin"), (79198, 0.8, "lille-owl"), (79197, 0.8, "lille-kin-p1")])):
        s, t = [], LOOKS_START
        for c, d, still in lst:
            if c is None: shot(s, t0 + d, still); continue                 # a second still of the same command
            ev(s, t, c); shot(s, t + d, still); t0 = t; t += d + 0.3
        sc[name] = (s, done(s), ())

    # ENDLESS: its select, then a debug run (Kenpachi from stage 3), its HUD, and the stage clear
    s, t = [], LOOKS_START
    key(s, t, "Enter"); key(s, t + 0.5, "ArrowDown"); key(s, t + 0.8, "Enter"); shot(s, t + 1.5, "select")
    key(s, t + 1.7, "Enter"); shot(s, t + 2.3, "start")
    ev(s, t + 2.5, 80103); key(s, t + 3.5, "Enter"); shot(s, t + 5.0, "hud")
    ev(s, t + 5.2, 80980); shot(s, t + 9.0, "clear")
    sc["endless"] = (s, done(s), ())

    # the portrait touch layout (390 x 844, one-handed: the taps of tests/scripts/duel-mobile.py)
    s, t = [], LOOKS_START
    tap(s, t, 195, 500); shot(s, t + 0.6, "mode"); tap(s, t + 1.0, 195, 451); shot(s, t + 1.6, "select")
    for i in range(3): tap(s, t + 2.0 + i, 195, 600)
    shot(s, t + 4.9, "intro"); tap(s, t + 5.5, 195, 400); ev(s, t + 6.0, 2105); shot(s, t + 7.0, "neutral")
    ev(s, t + 7.5, 2393); shot(s, t + 8.0, "close")
    tap(s, t + 8.5, 358, 200); shot(s, t + 9.2, "paused"); tap(s, t + 10.0, 195, 392)
    ev(s, t + 11.0, 10110); shot(s, t + 12.0, "cine")
    ev(s, t + 12.4, 2100); ev(s, t + 12.5, 2100)                                        # release the held cinematic
    for i, k in enumerate((0, 3, 4, 7)): ev(s, t + 13.0 + 1.2 * i, 2430 + k); shot(s, t + 13.7 + 1.2 * i, f"hud-{k}")     # the portrait HUD
    ev(s, t + 18.5, 2209); shot(s, t + 25.0, "results")
    sc["mobile"] = (s, done(s), ("--mobile", "--dpr", "1"))
    return sc


def still_diff(a, b):
    """(max abs channel diff, differing pixels, diff image or None) of two stills; (-1, -1, None) when a size differs."""
    x = np.asarray(Image.open(a).convert("RGB")).astype(int); y = np.asarray(Image.open(b).convert("RGB")).astype(int)
    if x.shape != y.shape: return -1, -1, None
    d = np.abs(x - y).max(-1)
    return int(d.max()), int((d > 0).sum()), np.clip(d * 4 + 80 * (d > 0), 0, 255).astype(np.uint8)


def looks(base, new, jobs=3, size="640x360", only=None, once=False):
    """Every scenario of looks_scenarios() rendered from BASE twice and NEW once (run.mjs --fixed-dt, JOBS at a time);
    PASS per still when NEW's diff to the first BASE run is within the BASE-vs-BASE one (the noise floor)."""
    sc = {k: v for k, v in looks_scenarios().items() if not only or only in k}
    root = f"{TMP}/looks"
    os.makedirs(f"{root}/diff", exist_ok=True)
    stills = []                                                       # (scenario, still name)
    todo = []
    for tag, dist in (("base1", base),) if once else (("base1", base), ("base2", base), ("new", new)):
        os.makedirs(f"{root}/{tag}", exist_ok=True)
        for name, (steps, secs, extra) in sc.items():
            st = [dict(e, shot=f"{root}/{tag}/{name}-{e['shot']}.png") if "shot" in e else e for e in steps]
            if tag == "base1": stills += [(name, e["shot"]) for e in steps if "shot" in e]
            todo.append((tag, name, dist, script(f"looks-{tag}-{name}", st), secs, extra))
    todo.sort(key=lambda x: -x[4])                                    # the longest first
    t0 = time.time(); running, codes, wall = [], {}, {}
    while todo or running:
        while todo and len(running) < jobs:
            tag, name, dist, sp, secs, extra = todo.pop(0)
            sz = "390x844" if "--mobile" in extra else size
            running.append((tag, name, time.time(), run(dist, sp, secs, f"{root}/{tag}/{name}.log", size=sz, extra=(*extra, "--timeout", "7200"))))
        for r in list(running):
            if r[3].poll() is not None:
                running.remove(r); codes[r[:2]] = r[3].returncode; wall[r[:2]] = time.time() - r[2]
        time.sleep(0.5)
    total = time.time() - t0
    for (tag, name), c in sorted(codes.items()):
        if c != 0: check(f"looks run {tag} {name}", False, f"exit {c}; see {root}/{tag}/{name}.log")
    noisy = []
    if once: return print(f"looks --once: {len(stills)} stills rendered from BASE only in {total:.0f} s: {root}/base1/")
    for name, still in stills:
        f = [f"{root}/{t}/{name}-{still}.png" for t in ("base1", "base2", "new")]
        if not all(os.path.exists(p) for p in f):
            check(f"looks {name}/{still}", False, "missing still: " + ", ".join(os.path.basename(p) for p in f if not os.path.exists(p))); continue
        nm, nc, _ = still_diff(f[0], f[1])                            # the noise floor: BASE twice
        dm, dc, img = still_diff(f[0], f[2])
        same = open(f[0], "rb").read() == open(f[2], "rb").read()
        if nc: noisy.append(f"{name}/{still}")
        ok = dc >= 0 and nc >= 0 and dm <= nm and dc <= nc
        if dc > 0: Image.fromarray(img).save(f"{root}/diff/{name}-{still}.png")
        check(f"looks {name}/{still}", ok, ("bytes identical" if same else f"max diff {dm}, {dc} px differ") + f" (noise floor: {nm} max, {nc} px)")
    for name in sc:                                                   # the sim: the match's hash / result lines, base vs new
        lines = lambda tag: [l.rstrip() for l in open(f"{root}/{tag}/{name}.log", errors="replace") if re.match(r"duel (hash|match seed|-> RESULTS)", l)]
        if not os.path.exists(f"{root}/new/{name}.log"): continue
        a1, a2, n = lines("base1"), lines("base2"), lines("new")
        if name.startswith("cvc-"):
            m = [l for l in a1 if l.startswith("duel match")]
            pair = name[4:].upper(); want = [dict(Y="YAMAMOTO", K="KENPACHI", R="RUKIA", I="ICHIGO", S="SENJUMARU", L="LILLE")[c] for c in pair]
            check(f"looks {name} fighters", bool(m) and all(w in m[0] for w in want), (m[0] if m else "no match line") + f" (want {' vs '.join(want)})")
        check(f"looks {name} sim lines", a1 == a2 and a1 == n or a1 != a2, f"{len(a1)} lines" + ("" if a1 == n else " DIFFER from base") + ("" if a1 == a2 else " (base runs differ: not compared)"))
    print(f"looks: {len(stills)} stills in {len(sc)} scenarios, {total:.0f} s wall for 3 renders at {jobs} jobs "
          f"(one dist's set ~{sum(w for (t, n), w in wall.items() if t == 'base1'):.0f} s of process time, longest {max((w for (t, n), w in wall.items() if t == 'base1'), default=0):.0f} s); "
          f"noisy between the two BASE runs: {len(noisy)}" + (" (" + ", ".join(noisy) + ")" if noisy else "") + f"; diff images: {root}/diff/")


def duelstill(dist, out, flat):
    steps = [cmd(3.0, 2017), cmd(3.02, 3003), cmd(3.04, 3004), cmd(3.06, 4500), {"at": 4.0, "shot": f"{out}.png"},
             cmd(4.02, 3002), {"at": 4.1, "shot": f"{out}-bg.png"}]
    if flat: steps += [cmd(4.12, 3005), {"at": 4.2, "shot": f"{out}-flat-bg.png"}, cmd(4.22, 3002), {"at": 4.3, "shot": f"{out}-flat.png"},
                       cmd(4.32, 3005), cmd(4.34, 3002)]
    steps += [cmd(4.36, 3002), cmd(4.38, 3006), {"at": 4.46, "shot": f"{out}-ink.png"}]     # no shadow discs: toon_check --outline
    check("duel frozen still", run(dist, script("duelstill", steps), 4.6, f"{TMP}/duelstill.log").wait() == 0, out)


def opt(k, d=None):
    a = sys.argv[1:]
    return a[a.index(k) + 1] if k in a else d


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a: print(__doc__); sys.exit(2)
    {"raven": lambda: raven(a[1], a[2]), "rc": lambda: rc(a[1]), "cvc": lambda: cvc(a[1]),
     "perf": lambda: perf(a[1], a[2], a[3]), "smoke": lambda: smoke(a[1:]),
     "duelstill": lambda: duelstill(a[1], a[2], "--flat" in a),
     "looks": lambda: looks(a[1], a[2], int(opt("--jobs", 3)), opt("--size", "640x360"), opt("--only"), "--once" in a)}[a[0]]()
    sys.exit(1 if fails else 0)
