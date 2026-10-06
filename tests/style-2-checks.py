#!/usr/bin/env python3
"""style-2-checks.py — the phase-2 acceptance checks that need pixels (docs/style/STYLE_STORM_DESIGN.md §9 row 2):

  python3 tests/style-2-checks.py ticks [VFX_DIST]   stepping: the Kikon rush aura (dist/duelvfx scene 28, fighters,
                                                     text and ash off) shot on 36 consecutive 60 Hz frames under
                                                     --fixed-dt; the toon layer may change only when the fx clock
                                                     enters a new drawing on twos (every 5th frame), never between
  python3 tests/style-2-checks.py pause [DUEL_DIST]  pause: a clash in dist/duel, paused (Escape) 0.1 s later, shot
                                                     twice 1 s apart: the two frames must be identical
  python3 tests/style-2-checks.py manga [VFX_DIST]   manga page (*GRADE-IMPACT* 3) keeps the FIRE and BLOOD pixels and
                                                     turns the rest two-tone: a fire hit and a counter hit, plain and
                                                     under mode 3, compared pixel by pixel
  python3 tests/style-2-checks.py spot [VFX_DIST]    hits are mono: no spot pixel (HSV S > 0.45, V > 0.25) in the cut /
                                                     heavy (outside its blood droplets) / guard / clash / burst stills
Prints PASS / FAIL lines, exits 1 on a FAIL.
"""
import colorsys, json, os, subprocess, sys
import numpy as np
from PIL import Image

TMP = "build/style"
fails = []


def check(name, ok, text=""):
    print(f"{'PASS' if ok else 'FAIL'} {name}{': ' + text if text else ''}", flush=True)
    if not ok: fails.append(name)


def cmd(t, c): return {"at": round(t, 4), "eval": f"Module._debug_cmd({c})"}


def run(dist, steps, secs, tag):
    p = f"{TMP}/s2c-{tag}.json"; json.dump(steps, open(p, "w"))
    return subprocess.run(["node", "tools/run.mjs", dist, "--secs", str(secs), "--script", p, "--fixed-dt", "16.666667"],
                          stdout=open(f"{TMP}/s2c-{tag}.log", "w"), stderr=subprocess.STDOUT).returncode


def img(p): return np.asarray(Image.open(p).convert("RGB")).astype(int)


def ticks(dist):
    steps = [cmd(3.0, 3003), cmd(3.02, 3004), cmd(3.04, 2028), cmd(3.06, 3002)]
    t0, shots = 4.2, []
    for k in range(36):
        p = f"{TMP}/s2c-tick-{k:02d}.png"; steps.append({"at": round(t0 + k / 60.0 + 0.004, 4), "shot": p}); shots.append(p)
    check("ticks run", run(dist, steps, t0 + 0.8, "ticks") == 0)
    ch = [int((np.abs(img(shots[k]) - img(shots[k + 1])).max(-1) > 0).sum()) for k in range(35)]
    moved = [k for k, c in enumerate(ch) if c > 0]
    gaps = sorted(set(b - a for a, b in zip(moved, moved[1:])))
    print("changed pixels between consecutive frames:", ch)
    # 12 drawings/s at 60 Hz = every 5th frame; the drawing boundaries fall exactly on frame times, so float
    # rounding of the accumulated clock moves some by one frame (gaps 4 / 6): never 2 changes within 3 frames
    check("toon shapes change only on new drawings (twos: ~every 5th frame at 60 Hz)",
          len(moved) >= 6 and min(gaps) >= 4 and abs(35 / 5 - len(moved)) <= 1, f"changes at frames {moved}, gaps {gaps}")


def pause(dist):
    a, b = f"{TMP}/s2c-pause-a.png", f"{TMP}/s2c-pause-b.png"
    steps = [cmd(3.0, 2500), cmd(3.5, 2326), {"at": 3.6, "key": "Escape", "down": True}, {"at": 3.65, "key": "Escape", "down": False},
             {"at": 3.9, "shot": a}, {"at": 4.9, "shot": b}]
    check("pause run", run(dist, steps, 5.1, "pause") == 0)
    d = int((np.abs(img(a) - img(b)).max(-1) > 0).sum())
    check("nothing changes while paused (clash effects, fx clock, HUD, camera)", d == 0, f"{d} px differ over 1 s of pause")


def sat_mask(x):
    x = x / 255.0
    mx, mn = x.max(-1), x.min(-1)
    return ((mx - mn) / np.maximum(mx, 1e-6) > 0.45) & (mx > 0.25)


def manga(dist):
    shots = {}
    steps = [cmd(3.0, 3003), cmd(3.02, 3004)]
    t = 3.2
    for scene, ms, tag in ((20, 90, "fire"), (21, 90, "counter")):           # one frozen frame, shot plain then as a manga page
        steps += [cmd(t, 2000 + scene), cmd(t + 0.02, 4000 + ms)]
        t += ms / 1000 + 0.25
        for mode in (0, 3):
            p = f"{TMP}/s2c-manga-{tag}-{mode}.png"; shots[(tag, mode)] = p
            steps += [cmd(t, 3010 + mode), {"at": round(t + 0.1, 3), "shot": p}]; t += 0.2
    steps.append(cmd(t, 3010))
    check("manga run", run(dist, steps, t + 0.3, "manga") == 0)
    for tag in ("fire", "counter"):
        a, b = img(shots[(tag, 0)]), img(shots[(tag, 3)])
        spot = sat_mask(a)
        kept = (np.abs(a - b).max(-1) <= 2) & spot
        rest = b[~sat_mask(b)]
        two = np.isin(rest.sum(-1) // 3, [8, 9, 255]) | (rest.min(-1) >= 250) | (rest.max(-1) <= 13)
        check(f"manga page keeps the spot pixels ({tag})", spot.sum() > 200 and kept.sum() >= 0.98 * spot.sum(),
              f"{int(kept.sum())} of {int(spot.sum())} spot pixels unchanged")
        check(f"manga page: the rest is two-tone ({tag})", two.mean() > 0.97, f"{100 * two.mean():.1f} % ink or paper")


def spot(dist):
    """Spot pixels (S > 0.45) anywhere in the frame of an effect drawn without the fighters (their skin and
    cords are not the effect's), for the mono effects at their 3 moments; the heavy hit's blood droplets excepted."""
    cases = [(18, "cut", (20, 90, 170)), (19, "heavy", (20, 110, 240)), (22, "guard", (20, 90, 170)),
             (24, "clash", (20, 120, 260)), (26, "burst", (40, 110, 260)), (27, "konpaku", (20, 120, 400)),
             (25, "hoho", (40, 250, 800))]
    steps, t, shots = [cmd(3.0, 3003), cmd(3.02, 3004), cmd(3.04, 3002)], 3.2, []      # fighters off: only effects move
    for scene, name, ages in cases:
        for ms in ages + (2300,):
            p = f"{TMP}/s2c-spot-{name}-{ms}.png"; shots.append((scene, name, ms, p))
            steps += [cmd(t, 2000 + scene), cmd(t + 0.02, 4000 + ms)]
            t += ms / 1000 + 0.25; steps.append({"at": round(t, 3), "shot": p}); t += 0.1
    check("spot run", run(dist, steps, t + 0.3, "spot") == 0)
    for scene, name, ms, p in shots:
        if ms == 2300: continue
        a, b = img(p), img(f"{TMP}/s2c-spot-{name}-2300.png")
        new = sat_mask(a)
        if name == "heavy":                                # its 5-8 ink-blood droplets are the one red allowed
            x = a / 255.0
            mx, mn = x.max(-1), x.min(-1)
            red = (x[..., 0] == mx) & (x[..., 1] - mn < 0.1 * (mx - mn) + 0.02)
            new &= ~red
        n = int(new.sum())
        check(f"mono: no spot pixel added by {name} at {ms} ms", n == 0, f"{n} px")


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a: print(__doc__); sys.exit(2)
    d = a[1] if len(a) > 1 else ("dist/duel" if a[0] == "pause" else "dist/duelvfx")
    {"ticks": ticks, "pause": pause, "manga": manga, "spot": spot}[a[0]](d)
    sys.exit(1 if fails else 0)
