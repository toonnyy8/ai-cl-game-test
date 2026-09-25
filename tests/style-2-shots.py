#!/usr/bin/env python3
"""style-2-shots.py — the phase-2 still set of the Storm x Kubo restyle (docs/STYLE_STORM_DESIGN.md §9 row 2):
every universal toon effect (§4.3) at 3 moments on the stage (dist/duelvfx scenes 18-31, frozen at chosen ages
under run.mjs --fixed-dt), the impact-frame modes, a gallery sheet, and in-game stills from dist/duel (Hoho
afterimage, Kikon rush aura, clash, burst, guard break, the neutral behind / side cameras).

  python3 tests/style-2-shots.py [VFX_DIST [DUEL_DIST]] [--only gallery|game]
  python3 tests/style-2-shots.py --sheet            (only rebuild the sheet from the stills on disk)

writes tests/shots/style-2-*.png (look at every one) and tests/shots/style-2-gallery.png (the sheet).
"""
import json, os, subprocess, sys
from PIL import Image, ImageDraw

TMP = "build/style"
os.makedirs(TMP, exist_ok=True)
OUT = "tests/shots/style-2-%s.png"

# scene, name, ages in ms (3 moments: early / middle / late)
EFFECTS = [(18, "hit-cut", (20, 90, 170)), (19, "hit-heavy", (20, 110, 240)), (20, "hit-fire", (20, 90, 170)),
           (21, "counter", (20, 90, 170)), (22, "guard", (20, 90, 170)), (23, "guard-break", (20, 110, 240)),
           (24, "clash", (20, 120, 260)), (25, "hoho", (40, 250, 800)), (26, "burst", (40, 110, 260)),
           (27, "konpaku", (20, 120, 400)), (28, "kikon-rush", (100, 300, 700)), (29, "dust", (60, 200, 420)),
           (30, "soul-flame", (100, 180, 260)), (31, "punctuation", (20, 100, 200))]
IMPACT = [(1, "negative"), (2, "two-tone"), (3, "manga"), (4, "spot-keep")]


def cmd(t, c): return {"at": round(t, 3), "eval": f"Module._debug_cmd({c})"}
def shot(t, path): return {"at": round(t, 3), "shot": path}
def key(t, k, down=True): return {"at": round(t, 3), "key": k, "down": down}


def run(dist, steps, secs, tag):
    p = f"{TMP}/s2-{tag}.json"; json.dump(steps, open(p, "w"))
    return subprocess.Popen(["node", "tools/run.mjs", dist, "--secs", str(secs), "--script", p, "--fixed-dt", "16.666667"],
                            stdout=open(f"{TMP}/s2-{tag}.log", "w"), stderr=subprocess.STDOUT)


def gallery_steps():
    s, t = [cmd(3.0, 3003), cmd(3.02, 3004)], 3.2          # label + stats off, ash off
    shots = []
    for scene, name, ages in EFFECTS:
        for i, ms in enumerate(ages):
            s += [cmd(t, 2000 + scene), cmd(t + 0.02, 4000 + ms)]
            t += ms / 1000.0 + 0.25
            path = OUT % f"{name}-{i + 1}"
            s.append(shot(t, path)); shots.append(path); t += 0.1
    for mode, name in IMPACT:                                # the impact modes over a clash and a counter
        for scene, ms, tag in ((24, 120, "clash"), (21, 90, "counter")):
            s += [cmd(t, 2000 + scene), cmd(t + 0.02, 4000 + ms), cmd(t + 0.04, 3010 + mode)]
            t += ms / 1000.0 + 0.25
            s.append(shot(t, OUT % f"impact-{name}-{tag}")); t += 0.1
            s.append(cmd(t, 3010)); t += 0.05
    return s, t + 0.3, shots


def game_steps():
    s = [cmd(3.0, 2500), key(3.1, "KeyW"), key(3.8, "KeyW", False),     # human Yamamoto vs an idle Kenpachi
         shot(4.6, OUT % "neutral-behind"), cmd(4.65, 2109), shot(5.3, OUT % "neutral-side"), cmd(5.35, 2109)]
    t = 5.6
    s += [cmd(t, 2307)]                                         # a perfect Hoho: the afterimage (white, ink), appear
    for i, dt in enumerate((0.05, 0.18, 0.35)):
        s.append(shot(t + dt, OUT % f"game-hoho-{i + 1}"))
    t += 1.5
    s += [cmd(t, 2325), key(t + 0.1, "KeyO"), key(t + 1.5, "KeyO", False)]   # the Kikon rush, 0.1x slow motion
    for i, dt in enumerate((0.4, 0.9, 1.4)):
        s.append(shot(t + dt, OUT % f"game-kikon-rush-{i + 1}"))
    t += 4.5
    s += [cmd(t, 2326)]                                         # a clash (Breaker vs Breaker)
    for i, dt in enumerate((0.03, 0.15, 0.35)):
        s.append(shot(t + dt, OUT % f"game-clash-{i + 1}"))
    t += 1.5
    s += [cmd(t, 2321)]                                         # Burst Reverse out of a combo
    for i, dt in enumerate((0.05, 0.14, 0.3)):
        s.append(shot(t + dt, OUT % f"game-burst-{i + 1}"))
    t += 1.5
    s += [cmd(t, 2306)]                                         # a guard break
    for i, dt in enumerate((0.58, 0.66, 0.8)):
        s.append(shot(t + dt, OUT % f"game-guard-break-{i + 1}"))
    return s, t + 1.2


def sheet(shots):
    def thumb(p):                                          # the effect region (not the punctuation cards)
        im = Image.open(p).convert("RGB")
        return (im if "punctuation" in p else im.crop((240, 60, 1040, 510))).resize((320, 180))
    ims = [thumb(p) for p in shots if os.path.exists(p)]
    cols = 6
    rows = (len(ims) + cols - 1) // cols
    g = Image.new("RGB", (cols * 320, rows * 196), (20, 20, 26))
    d = ImageDraw.Draw(g)
    for i, (im, p) in enumerate(zip(ims, [p for p in shots if os.path.exists(p)])):
        x, y = (i % cols) * 320, (i // cols) * 196
        g.paste(im, (x, y + 16))
        d.text((x + 4, y + 2), os.path.basename(p)[8:-4], fill=(230, 230, 230))
    g.save(OUT % "gallery")


if __name__ == "__main__" and "--sheet" in sys.argv:          # rebuild the sheet from the stills on disk
    sheet([OUT % f"{n}-{i + 1}" for _, n, ages in EFFECTS for i in range(3)]); sys.exit(0)
if __name__ == "__main__":
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    only = sys.argv[sys.argv.index("--only") + 1] if "--only" in sys.argv else None
    a = [x for x in a if x not in ("gallery", "game")]
    vfx, duel = (a + ["dist/duelvfx", "dist/duel"])[:2] if len(a) < 2 else a[:2]
    procs, shots = [], []
    if only in (None, "gallery"):
        st, secs, shots = gallery_steps(); procs.append(run(vfx, st, secs, "gallery"))
    if only in (None, "game"):
        st, secs = game_steps(); procs.append(run(duel, st, secs, "game"))
    codes = [p.wait() for p in procs]
    if shots: sheet(shots)
    print("run.mjs exit codes", codes)
    sys.exit(1 if any(codes) else 0)
