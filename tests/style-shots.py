#!/usr/bin/env python3
"""style-shots.py — the user-review still set of the Storm x Kubo restyle (docs/STYLE_STORM_DESIGN.md §9),
taken under run.mjs --fixed-dt, so a still is the same frame on every run.

  python3 tests/style-shots.py PHASE DUEL DUELVIEW [BEFORE_DUEL BEFORE_DUELVIEW]

writes tests/shots/style-PHASE-NAME.png from the given dists (dist/duel = the game, dist/duelview =
tests/duel-view.lisp) and, with the BEFORE dists (builds of the tree before the restyle), the same
frames as tests/shots/style-PHASE-NAME-before.png. The stills:
  title            the title screen: the stage wide from the menu camera
  neutral-behind   VS CPU, the default behind camera, P1 Yamamoto walking in on an idle Kenpachi
  neutral-side     the same moment on the pair (side) camera
  fight-side       a seeded CPU vs CPU match (YK seed 3) 12 s in, pair camera
  select           the character select screen
  yama-front / -side / -face, ken-front / -side / -face, yama-bankai-*, ken-nozarashi-*   duel-view
                   (-closeup / -closeup34: the face at 0.7 m, from the front and from 35 degrees;
                   yama-34 / ken-34 / -back34: 3/4 views from the front and the back, base forms)
  stage-wide       duel-view scene 4, the stage from outside the fighters
"""
import json, os, subprocess, sys

TMP = "build/style"
os.makedirs(TMP, exist_ok=True)


def cmd(t, c): return {"at": round(t, 3), "eval": f"Module._debug_cmd({c})"}
def key(t, k, down=True): return {"at": round(t, 3), "key": k, "down": down}
def shot(t, name): return {"at": round(t, 3), "shot": name}


def game_steps(out):
    s = [shot(8.9, out("title")), key(9.0, "Enter"), key(9.1, "Enter", False), key(9.6, "Enter"), key(9.7, "Enter", False),
         shot(10.6, out("select")),
         cmd(11.0, 2500),                                           # human P1 Yamamoto vs an idle CPU Kenpachi
         key(11.4, "KeyW"), key(12.4, "KeyW", False), shot(13.0, out("neutral-behind")),
         cmd(13.05, 2109), shot(13.6, out("neutral-side")),
         cmd(13.7, 4003), shot(25.7, out("fight-side"))]            # seeded CPU vs CPU (pair camera)
    return s, 26.0


def view_steps(out):
    s, t = [], 9.0
    def c(x): nonlocal t; s.append(cmd(t, x)); t += 0.1
    def sh(n): nonlocal t; t += 0.4; s.append(shot(t, out(n))); t += 0.1
    for scene, who in ((0, ("yama", "ken")), (1, ("yama-bankai", "ken-nozarashi"))):
        c(2000 + scene)
        for i, w in enumerate(who):
            for deg, view in ((0, "front"), (90, "side")):
                c(3000 + deg); c(6000 + i); sh(f"{w}-{view}")
            if scene == 0:
                c(3000); c(6100 + i); sh(f"{w}-face")
                c(3035); c(6000 + i); sh(f"{w}-34")                        # the ink art pass checks (no haori seams)
                c((3145, 3215)[i]); c(6000 + i); sh(f"{w}-back34")
            c(3000); c(6200 + i); sh(f"{w}-closeup"); c(6210 + i); sh(f"{w}-closeup34")
    c(3000); c(2004); t += 1.5; sh("stage-wide")
    return s, t + 0.2


def start(dist, steps, secs, tag):
    p = f"{TMP}/shots-{tag}.json"; json.dump(steps, open(p, "w"))
    return subprocess.Popen(["node", "tools/run.mjs", dist, "--secs", str(secs), "--script", p, "--fixed-dt", "16.666667"],
                            stdout=open(f"{TMP}/shots-{tag}.log", "w"), stderr=subprocess.STDOUT)


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) not in (3, 5): print(__doc__); sys.exit(2)
    phase, runs = a[0], []
    for suffix, duel, view in (("", a[1], a[2]),) + ((("-before", a[3], a[4]),) if len(a) == 5 else ()):
        out = lambda n, s=suffix: f"tests/shots/style-{phase}-{n}{s}.png"
        runs.append(start(duel, *game_steps(out), f"duel{suffix}"))
        runs.append(start(view, *view_steps(out), f"view{suffix}"))
    codes = [p.wait() for p in runs]
    print("run.mjs exit codes", codes)
    sys.exit(1 if any(codes) else 0)
