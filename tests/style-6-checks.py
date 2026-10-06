#!/usr/bin/env python3
"""style-6-checks.py — the phase-6 checks of the Storm x Kubo restyle (docs/style/STYLE_STORM_DESIGN.md §14 Phase 6) on a
played script:

  cons   0 B for 10 draws of every Phase 6 per-frame look (debug 2391: "vfx6 consing")
  grip   the left fist held on the cleaver's handle (debug 2392 on cup 3): with the draw's GRIP-LEFT! the worst frame of
         every grip clip and grip-clip crossfade is at most 1/2 of the keys-only worst and at most 170 mm (a few in-betweens
         put the handle out of the left arm's reach), and the median frame is on the handle (<= 10 mm)

  python3 tests/style-6-checks.py --run DIST   prints PASS / FAIL lines, exits 1 on a FAIL
"""
import json, re, statistics, subprocess, sys

fails = []


def check(name, ok, text=""):
    print(f"{'PASS' if ok else 'FAIL'} {name}{': ' + text if text else ''}")
    if not ok: fails.append(name)


def run_checks(dist):
    steps = [{"at": 3.0, "eval": "Module._debug_cmd(2100)"}, {"at": 3.2, "eval": "Module._debug_cmd(2391)"},
             {"at": 3.4, "eval": "Module._debug_cmd(2383)"}, {"at": 3.8, "eval": "Module._debug_cmd(2392)"}]
    json.dump(steps, open("build/style/s6-checks.json", "w"))
    log = "build/style/s6-checks.log"
    subprocess.run(["node", "tools/run.mjs", dist, "--secs", "4.5", "--script", "build/style/s6-checks.json",
                    "--fixed-dt", "16.666667"], stdout=open(log, "w"), stderr=subprocess.STDOUT)
    text = open(log).read()
    m = re.search(r"vfx6 consing \(10 draws, B\): (.*)", text)
    check("cons", bool(m) and max(int(x.split()[-1]) for x in m.group(1).split(", ")) == 0, m.group(1) if m else "no line")
    m = re.search(r"grip drift: raw max (\d+)\. mm \((.*?)\), IK max (\d+)\. mm", text)
    ik = [int(b) for a, b in re.findall(r"(\d+)/(\d+)", " ".join(re.findall(r"grip \S+ \(raw/IK mm\): (.*)", text)))]
    if m and ik:
        raw, mx = int(m.group(1)), int(m.group(3))
        check("grip", mx * 2 <= raw and mx <= 170 and statistics.median(ik) <= 10,
              f"keys only worst {raw} mm ({m.group(2)}), held worst {mx} mm, median {statistics.median(ik)} mm over {len(ik)} frames")
    else:
        check("grip", False, "no grip drift lines")


if __name__ == "__main__":
    if "--run" not in sys.argv: print(__doc__); sys.exit(2)
    run_checks(sys.argv[sys.argv.index("--run") + 1])
    sys.exit(1 if fails else 0)
