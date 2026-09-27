#!/usr/bin/env python3
"""mobile-probe.py — the portrait framing / text probes (docs/DUEL_MOBILE_DESIGN.md §4.1, §7.4; P2) at the four phone
sizes. Each size: a seeded CPU vs CPU (YK) watched in portrait for 45 s with the probe on (debug 2700: every 30th battle
frame, both fighters' upper halves (heads, torsos) clear of the two HUD blocks and >= 70 % of each one's width on the screen, P2's at the top and
P1's at the bottom; the thumb may cover their feet: the user's decision 2026-09-27), then the set shots, each checked on its own: 1 m, 2.2 m, 24 m apart (the eye pulled in by the wall), P2 flashed to P1's side (90 deg,
4 m) 0.1 s and 0.5 s later. 390x844 runs again with iPhone insets (47 top, 34 bottom). PASS needs the CvC >= 95 %, every
set shot but the 0.1 s side one inside the band, and the smallest pixel-font glyph >= the text floor (ceil(11 dpr / 7)).
  python3 tests/mobile-probe.py [DIST]        (default dist/duel; logs in build/p2/)"""
import json, os, re, subprocess, sys

dist = sys.argv[1] if len(sys.argv) > 1 else "dist/duel"
JOBS = 2                                                   # headless SwiftShader at DPR 3 is slow: two at a time
os.makedirs("build/p2", exist_ok=True)
SIZES = [("360x780", None), ("390x844", None), ("430x932", None), ("412x915", None), ("390x844", [47, 34])]
def cmd(t, c): return {"at": t, "eval": f"Module._debug_cmd({c})"}
CVC = 52.0                                                  # the CvC runs 7 .. 52 s (45 s, ~80 samples)
SETS = [("1m", 2703, 0.6), ("2.2m", 2393, 0.6), ("24m", 2701, 0.9), ("side+0.1", 2702, 0.1), ("side+0.5", None, 0.4)]
def script(insets):
    s = [cmd(6.9, 2106), cmd(6.95, 2700), cmd(7.0, 4001)]
    if insets: s.insert(0, {"at": 6.8, "eval": f"globalThis.gamePage.testInsets = {insets}"})
    s.append(cmd(CVC, 2700)); s.append(cmd(CVC + 0.5, 2105))
    t = CVC + 1
    for name, c, wait in SETS:
        if c: s.append(cmd(t, c))
        t = round(t + wait, 2); s.append({"at": t, "eval": f"console.log('set {name}')"}); s.append(cmd(t + 0.01, 2700)); t += 0.5
    return s, t + 1
runs = []
for i, (size, ins) in enumerate(SIZES):
    while len([r for r in runs if r[3].poll() is None]) >= JOBS:
        next(r for r in runs if r[3].poll() is None)[3].wait()
    sc, secs = script(ins)
    p = f"build/p2/probe-{i}.json"; json.dump(sc, open(p, "w"))
    log = f"build/p2/probe-{size}{'-inset' if ins else ''}.log"
    runs.append((size, ins, log, subprocess.Popen(["node", "tools/run.mjs", dist, "--mobile", "--size", size, "--fixed-dt", "16.666667",
                                                    "--secs", str(secs), "--script", p, "--timeout", "3600"],
                                                   stdout=open(log, "w"), stderr=subprocess.STDOUT)))
fails = 0
for size, ins, log, pr in runs:
    pr.wait(); txt = open(log).read()
    agg = re.findall(r"duel frame (\d+)x(\d+) \(css (\d+)x(\d+)\) band ([\d.]+)-([\d.]+): .*both (\d+)/(\d+) \(([\d.]+) %\); text min (\d+) px in (\S+), floor (\d+) px", txt)
    tag = f"{size}{' insets 47/34' if ins else ''}"
    if len(agg) < 2: print(f"FAIL {tag}: no probe lines ({log})"); fails += 1; continue
    W, H, cw, ch, b0, b1, both, n, pct, tmin, tflow, floor = agg[1]   # the CvC's line (agg[0]: the probe switched on)
    ok = float(pct) >= 95.0 and int(n) >= 40
    print(f"{'PASS' if ok else 'FAIL'} {tag} CvC framing: both fighters' upper halves clear {both}/{n} ({pct} %), band {b0}-{b1}"); fails += not ok
    ok = int(tmin) >= int(floor); print(f"{'PASS' if ok else 'FAIL'} {tag} text floor: min {tmin} px (in {tflow}) >= {floor} px"); fails += not ok
    band = (float(b0) * int(ch), float(b1) * int(ch))
    for name, _, _ in SETS:
        m = re.search(r"set " + re.escape(name) + r"[\s\S]*?duel frame boxes \(css\): p1 ([-\d. ]+) p2 ([-\d. ]+) fov ([\d.]+)", txt)
        if not m: print(f"FAIL {tag} {name}: no boxes"); fails += 1; continue
        bx = [list(map(float, g.split())) for g in m.groups()[:2]]
        inside = all(min(b[2], int(cw)) - max(b[0], 0) >= 0.7 * (b[2] - b[0]) and b[1] >= band[0] - 0.5 and (b[1] + b[3]) / 2 <= band[1] + 0.5
                     for b in bx)
        info = name == "side+0.1"
        print(f"{'PASS' if inside else ('INFO' if info else 'FAIL')} {tag} {name}: p1 {bx[0]} p2 {bx[1]} fov {m.group(3)} band {band[0]:.0f}-{band[1]:.0f}")
        fails += (not inside) and not info
print("ALL PASS" if not fails else f"{fails} FAIL"); sys.exit(1 if fails else 0)
