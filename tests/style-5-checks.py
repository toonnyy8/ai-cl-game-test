#!/usr/bin/env python3
"""style-5-checks.py — the phase-5 acceptance of the Storm x Kubo restyle (docs/style/STYLE_STORM_DESIGN.md §9 row 5), on the
stills of tests/style-5-shots.py and, with --run, on a played script:

  faces   each fighter shows 3 expression states: the face close-ups style-5-face-{yama,ken}-{neutral,shout,hurt}.png
          differ pairwise (> 1 % of the face crop's pixels by more than 40 levels)
  dome    Jokaku Enjo's manga-page still (style-5-dome-146): every saturated pixel (S > 0.45) is fire (hue 0-40 deg) or
          the victim's own yellow reiatsu (48 +- 25): the fire is the only colour of the attack
  --run DIST
    hud   no gameplay callout, side word or brush callout column is drawn over a HUD side panel: the HUD logs
          "hud: callout|word ... over the P<n> panel" and brush.lisp "brush: caption ... over the HUD" (once per string),
          and no caption leaves the screen ("brush: caption ... off the"); played at 1280x720 and 800x450 through
          Kenpachi's cup-3 callouts as P2 (KUKAN-GIRI, NOMIHOSE: 2379; behind, then with the side camera, which put them
          over the P2 labels before Phase 5), the NOME ladder's words (2380), the Bankai
          compass callouts (2370 + L, 2303, 2304), the SP2 names (2310), the big words (2306, 2326, 2307)
    cons  0 B for 10 draws of every Phase 5 per-frame look (debug 2390: "vfx5 consing")

  python3 tests/style-5-checks.py [--run DIST]   prints PASS / FAIL lines, exits 1 on a FAIL
"""
import colorsys, json, os, re, subprocess, sys
import numpy as np
from PIL import Image

OUT = "tests/shots/style-5-%s.png"
fails = []


def check(name, ok, text=""):
    print(f"{'PASS' if ok else 'FAIL'} {name}{': ' + text if text else ''}")
    if not ok: fails.append(name)


def face_checks():
    for who in ("yama", "ken"):
        ims = {}
        for f in ("neutral", "shout", "hurt"):
            p = OUT % f"face-{who}-{f}"
            if os.path.exists(p):
                a = np.asarray(Image.open(p).convert("RGB")).astype(int)
                h, w = a.shape[:2]
                ims[f] = a[int(0.25 * h): int(0.75 * h), int(0.35 * w): int(0.65 * w)]   # the face in the close-up
        if len(ims) < 3:
            check(f"faces {who}", False, "missing stills"); continue
        diffs = {f"{a}/{b}": float((np.abs(ims[a] - ims[b]).max(-1) > 40).mean())
                 for a, b in (("neutral", "shout"), ("neutral", "hurt"), ("shout", "hurt"))}
        check(f"faces {who}: 3 expression states", min(diffs.values()) > 0.01,
              ", ".join(f"{k} {100 * v:.1f} % px differ" for k, v in diffs.items()))


def dome_check():
    p = OUT % "dome-146"
    if not os.path.exists(p):
        check("dome manga page", False, "missing still"); return
    a = np.asarray(Image.open(p).convert("RGB")).astype(float) / 255.0
    a = a[int(0.09 * a.shape[0]): int(0.91 * a.shape[0])]
    mx, mn = a.max(-1), a.min(-1); s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    sat = a[(s > 0.45) & (mx > 0.15)][::7]
    hues = [360 * colorsys.rgb_to_hsv(*px)[0] for px in sat]
    fire = sum(1 for h in hues if h <= 40 or h >= 350); yellow = sum(1 for h in hues if 40 < h <= 73)
    other = len(hues) - fire - yellow
    check("dome manga page: the fire is the only colour", other <= 0.02 * max(1, len(hues)),
          f"{len(hues)} sampled saturated px: fire {fire}, the victim's yellow {yellow}, other {other}")


PAT = re.compile(r"(hud: .* over the P\d panel.*|brush: caption .* over the HUD.*|brush: caption .* off the .*)")


def run_checks(dist):
    steps, t = [{"at": 3.0, "eval": "Module._debug_cmd(2100)"}, {"at": 3.1, "eval": "Module._debug_cmd(2106)"}], 3.4
    for c, keys, secs in ((2379, [], 9.5), (2109, [], 0.2), (2379, [], 9.5), (2380, [], 8.0), (2370, [(0.4, "KeyL")], 1.6), (2303, [], 1.6), (2304, [], 1.6),
                          (2310, [], 1.6), (2306, [], 1.8), (2326, [], 1.4), (2307, [], 1.4), (2383, [(0.5, "KeyK")], 1.8),
                          (2390, [], 0.5)):
        steps.append({"at": round(t, 3), "eval": f"Module._debug_cmd({c})"})
        for d, k in keys: steps += [{"at": round(t + d, 3), "key": k, "down": True}, {"at": round(t + d + 0.1, 3), "key": k, "down": False}]
        t += secs
    json.dump(steps, open("build/style/s5-hud.json", "w"))
    for size in ("1280x720", "800x450"):
        log = f"build/style/s5-hud-{size}.log"
        subprocess.run(["node", "tools/run.mjs", dist, "--secs", str(round(t + 0.5, 1)), "--script", "build/style/s5-hud.json",
                        "--fixed-dt", "16.666667", "--size", size], stdout=open(log, "w"), stderr=subprocess.STDOUT)
        text = open(log).read(); bad = PAT.findall(text)
        seen = sorted(set(re.findall(r"P2 move (KE-N-F1|KE-METEOR-N)", text)))
        check(f"hud {size}", not bad and len(seen) == 2, "; ".join(bad[:3]) or f"every callout and word clear of the HUD panels "
                                                                              f"(P2 cast {', '.join(seen)})")
        m = re.search(r"vfx5 consing \(10 draws, B\): (.*)", text)
        if m:
            vals = [int(x.split()[-1]) for x in m.group(1).split(", ")]
            check(f"cons {size}", m and max(vals) == 0, m.group(1))


if __name__ == "__main__":
    face_checks(); dome_check()
    if "--run" in sys.argv: run_checks(sys.argv[sys.argv.index("--run") + 1])
    sys.exit(1 if fails else 0)
