#!/usr/bin/env python3
"""style-4-shots.py — the phase-4 still set of the Storm x Kubo restyle (docs/STYLE_STORM_DESIGN.md §9 row 4, user
review 3): every cinematic at its key beats (debug 10000 + 1000 k + f: cinematic k held at frame f, the effects frozen
there), the brush captions close up, the gameplay brush callouts (SP names, the Bankai compass), the results screen,
and a before / after sheet against the previous build's held cinematics (debug 2200 + k at each script's old :hold).

  python3 tests/style-4-shots.py [DUEL_DIST [BASE_DIST]]   shoot (run.mjs --fixed-dt) and build the sheets
  python3 tests/style-4-shots.py --sheet                     only rebuild the sheets from the stills on disk

writes tests/shots/style-4-<name>.png (look at every one), style-4-gallery.png, style-4-captions.png, style-4-pairs.png.
"""
import json, os, subprocess, sys
from PIL import Image, ImageDraw

TMP = "build/style"
os.makedirs(TMP, exist_ok=True)
OUT = "tests/shots/style-4-%s.png"


def cmd(t, c): return {"at": round(t, 3), "eval": f"Module._debug_cmd({c})"}
def shot(t, name): return {"at": round(t, 3), "shot": OUT % name}
def key(t, k, down=True): return {"at": round(t, 3), "key": k, "down": down}


# (k, name, frames): FORCE-CINE's numbering; the order keeps a forced form from leaking into the next script
CINES = [(2, "jokaku", [6, 20, 50, 85, 110, 130, 143, 150, 170]),
         (0, "bankai", [5, 30, 50, 62, 74, 100, 128]),
         (3, "tenchi", [6, 20, 55, 69, 76, 90, 130]),
         (8, "ko", [2, 12, 60]),
         (4, "ken-kikon", [6, 20, 55, 80, 130, 143, 148, 170]),
         (1, "nozarashi", [5, 26, 40, 66, 84, 96]),
         (5, "sky-split", [6, 20, 55, 70, 74, 110, 145]),
         (6, "soul-break", [3, 14, 34, 41, 46, 70]),
         (7, "intro", [60, 125, 180, 262])]
# gameplay brush callouts: (name, setup commands, keys pressed after the setup, shot delays)
# (keys: (delay, key) pressed after the setup; the shot delays count from the last key). 2109 toggles the side camera.
CALLOUTS = [("minami", [2303], [], [0.15, 0.62, 0.8]), ("kyoku", [2304], [], [0.3]),
            ("nishi", [2370], [(0, "KeyL")], [0.4]), ("higashi-side", [2370, 2109], [(0, "KeyL"), (2.0, "KeyL")], [0.2, 0.3]),
            ("tenchi-rush", [2109, 2331], [(0, "KeyO")], [0.25]), ("ken-charge", [2310], [], [0.3]),
            # brush Latin (user review 3): a Latin-only callout and the big words
            ("meteor", [2305], [], [0.35]), ("guard-break", [2306], [], [0.75, 1.0]), ("clash", [2326], [], [0.3]),
            ("perfect", [2307], [], [0.4])]
# before (the previous build, 2200 + k held at its old :hold) -> after (this build, the same frame)
OLD_HOLD = {0: 44, 1: 52, 2: 70, 3: 26, 4: 72, 5: 34, 6: 44, 7: 200, 8: 70}
AFTER = {"jokaku": 20, "bankai": 74, "tenchi": 20, "ko": 12, "ken-kikon": 20, "nozarashi": 96, "sky-split": 20,
         "soul-break": 14, "intro": 180}                                      # the caption beat of each


def steps():
    s, t, shots = [cmd(3.0, 2106)], 3.2, []
    for k, name, frames in CINES:
        last = 0
        for f in frames:
            s.append(cmd(t, 10000 + 1000 * k + f))
            wait = (f - last) / 60.0 + (1.2 if last == 0 else 0.35)       # the first one sets up the battle
            s.append(shot(t + wait, f"{name}-{f:03d}")); shots.append(OUT % f"{name}-{f:03d}")
            t += wait + 0.1; last = f
        t += 0.3
    s.append(cmd(t, 2209)); t += 150 / 60.0 + 0.6                          # K.O. -> results
    for d in (0.0, 0.12, 1.2):
        s.append(shot(t + d, f"results-{int(d * 100):03d}")); shots.append(OUT % f"results-{int(d * 100):03d}")
    t += 1.6
    for name, setup, keys, delays in CALLOUTS:
        for c in setup: s.append(cmd(t, c)); t += 0.05
        t += 0.4
        for d, kk in keys: t += d; s += [key(t, kk), key(t + 0.1, kk, False)]
        for i, d in enumerate(delays):
            s.append(shot(t + d, f"callout-{name}-{i + 1}")); shots.append(OUT % f"callout-{name}-{i + 1}")
        t += max(delays) + 0.6
    return s, t + 0.5, shots


def base_steps():
    s, t, shots = [cmd(3.0, 2106)], 3.2, []
    for k, name, _ in CINES:
        s.append(cmd(t, 2200 + k)); t += OLD_HOLD[k] / 60.0 + 1.5
        s.append(shot(t, f"before-{name}")); shots.append(OUT % f"before-{name}"); t += 0.3
    return s, t + 0.5, [(k, name) for k, name, _ in CINES]


def label(d, x, y, text):
    d.rectangle((x, y, x + 7 * len(text) + 6, y + 13), fill=(20, 20, 26)); d.text((x + 3, y + 1), text, fill=(235, 235, 235))


def sheets():
    names = [f"{n}-{f:03d}" for _, n, fs in CINES for f in fs] + ["results-000", "results-012", "results-120"] + \
            [f"callout-{n}-{i + 1}" for n, _, _, ds in CALLOUTS for i in range(len(ds))]
    ims = [(n, Image.open(OUT % n).convert("RGB").resize((384, 216))) for n in names if os.path.exists(OUT % n)]
    cols = 5
    g = Image.new("RGB", (cols * 384, ((len(ims) + cols - 1) // cols) * 216), (20, 20, 26)); d = ImageDraw.Draw(g)
    for i, (n, im) in enumerate(ims):
        x, y = (i % cols) * 384, (i // cols) * 216
        g.paste(im, (x, y)); label(d, x, y, n)
    g.save(OUT % "gallery")
    # captions close up: the caption's third of the frame at full resolution
    crops = [("jokaku-020", (640, 0, 1280, 720)), ("bankai-074", (0, 0, 640, 720)), ("tenchi-020", (0, 0, 640, 720)),
             ("ken-kikon-020", (640, 0, 1280, 720)), ("nozarashi-096", (0, 0, 640, 720)), ("sky-split-020", (0, 0, 640, 720)),
             ("results-120", (0, 0, 520, 720)), ("callout-minami-2", (0, 150, 640, 720))]
    parts = [(n, Image.open(OUT % n).convert("RGB").crop(b)) for n, b in crops if os.path.exists(OUT % n)]
    if parts:
        W = sum(p.width for _, p in parts); c = Image.new("RGB", (W, 720), (20, 20, 26)); d = ImageDraw.Draw(c); x = 0
        for n, p in parts:
            c.paste(p, (x, 720 - p.height)); label(d, x, 0, n); x += p.width
        c.save(OUT % "captions")
    rows = [(n, f"{n}-{AFTER[n]:03d}") for _, n, _ in CINES]
    rows = [(b, a) for b, a in rows if os.path.exists(OUT % f"before-{b}") and a and os.path.exists(OUT % a)]
    p = Image.new("RGB", (2 * 512, len(rows) * 288), (20, 20, 26)); d = ImageDraw.Draw(p)
    for r, (b, a) in enumerate(rows):
        p.paste(Image.open(OUT % f"before-{b}").convert("RGB").resize((512, 288)), (0, r * 288))
        p.paste(Image.open(OUT % a).convert("RGB").resize((512, 288)), (512, r * 288))
        label(d, 0, r * 288, f"BEFORE {b} (old :hold frame)"); label(d, 512, r * 288, f"AFTER {a}")
    p.save(OUT % "pairs")


def run(dist, st, secs, tag):
    json.dump(st, open(f"{TMP}/s4-{tag}.json", "w"))
    return subprocess.run(["node", "tools/run.mjs", dist, "--secs", str(round(secs, 1)), "--script", f"{TMP}/s4-{tag}.json",
                           "--fixed-dt", "16.666667"], stdout=open(f"{TMP}/s4-{tag}.log", "w"), stderr=subprocess.STDOUT).returncode


if __name__ == "__main__":
    if "--sheet" in sys.argv: sheets(); sys.exit(0)
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    dist, base = (args + ["dist/duel", "dist/base5-duel"])[:2]
    st, secs, shots = steps()
    rc = run(dist, st, secs, "new")
    if "--no-base" not in sys.argv:
        bs, bsecs, _ = base_steps(); rc |= run(base, bs, bsecs, "base")
    sheets()
    print("run.mjs exit code", rc, "|", sum(os.path.exists(p) for p in shots), "of", len(shots), "stills")
    sys.exit(rc)
