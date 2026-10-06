#!/usr/bin/env python3
"""style-3-shots.py — the phase-3 still set of the Storm x Kubo restyle (docs/style/STYLE_STORM_DESIGN.md §9 row 3, user
review 2): every signature effect at 3 moments in gameplay framing (dist/duel, the current *CAM-CLOSE*, the VS CPU
behind camera and the side camera), the awakened forms idle and attacking, a before / after sheet against the
pre-restyle stills (the Phase-0 tree's tests/shots/duel-*.png) and a gallery sheet.

  python3 tests/style-3-shots.py [DUEL_DIST]        run the game and shoot (under run.mjs --fixed-dt), then the sheets
  python3 tests/style-3-shots.py --sheet            only rebuild the two sheets from the stills on disk

writes tests/shots/style-3-<name>.png (look at every one), style-3-gallery.png and style-3-pairs.png.
"""
import json, os, subprocess, sys
from PIL import Image, ImageDraw

TMP = "build/style"
os.makedirs(TMP, exist_ok=True)
OUT = "tests/shots/style-3-%s.png"


def cmd(t, c): return {"at": round(t, 3), "eval": f"Module._debug_cmd({c})"}
def shot(t, name): return {"at": round(t, 3), "shot": OUT % name}
def key(t, k, down=True): return {"at": round(t, 3), "key": k, "down": down}
def tap(t, k): return [key(t, k), key(t + 0.08, k, False)]


# (name, setup commands, side camera?, [(key or None, [shot delays after the key / the setup])])
# 2500 human Yamamoto vs an idle Kenpachi, 2501 human Kenpachi vs an idle Yamamoto; 2312 / 2313 Bankai / Nozarashi form,
# 2302 the fire wave, 2305 Split the Meteor, 2309 Buttagiru. K = the flash attack (the big swing: the comet smear).
SCENES = [
    ("blade-fire", [2500], False, [(None, [0.9]), ("KeyK", [0.28, 0.34, 0.45])]),
    ("blade-fire-side", [2500], True, [(None, [0.9]), ("KeyK", [0.28, 0.34, 0.45])]),
    ("fire-wave", [2500, 2302], False, [(None, [0.7, 0.8, 0.9])]),
    ("fire-wave-side", [2500, 2302], True, [(None, [0.7, 0.8, 0.9])]),
    ("ken-aura", [2501], False, [(None, [0.9]), ("KeyK", [0.24, 0.3, 0.4])]),
    ("ken-aura-side", [2501], True, [(None, [0.9]), ("KeyK", [0.24, 0.3, 0.4])]),
    ("buttagiru", [2501, 2309], True, [(None, [0.42, 0.55, 0.9])]),
    ("nozarashi", [2501, 2313], False, [(None, [0.9]), ("KeyK", [0.28, 0.34, 0.45])]),
    ("nozarashi-side", [2501, 2313], True, [(None, [0.9]), ("KeyK", [0.28, 0.34, 0.45])]),
    ("meteor", [2501, 2305], True, [(None, [0.48, 0.6, 0.95])]),
    ("bankai", [2500, 2312], False, [(None, [0.9]), ("KeyK", [0.28, 0.34, 0.45])]),
    ("bankai-side", [2500, 2312], True, [(None, [0.9]), ("KeyK", [0.28, 0.34, 0.45])]),
]


def steps():
    s, t, shots, side = [cmd(3.0, 2100)], 3.2, [], False       # cinematics skipped (the forms are forced)
    for name, setup, want_side, beats in SCENES:
        for c in setup:
            s.append(cmd(t, c)); t += 0.05
        if want_side != side:
            s.append(cmd(t, 2109)); side = want_side; t += 0.05
        n = 0
        for k, delays in beats:
            t += 0.6 if k else 0.0
            if k: s += tap(t, k)
            for d in delays:
                n += 1
                s.append(shot(t + d, f"{name}-{n}")); shots.append(OUT % f"{name}-{n}")
            t += max(delays) + 0.2
        t += 0.3
    return s, t + 0.5, shots


# before (the Phase-0 tree: tests/shots/duel-*.png) -> after (this phase)
PAIRS = [("duel-vfx-blade-fire-0", "blade-fire-side-3"), ("duel-extras-side", "blade-fire-side-1"),
         ("duel-fire-wave", "fire-wave-2"), ("duel-vfx-fire-wave-1", "fire-wave-side-2"),
         ("duel-vfx-auras-0", "ken-aura-side-1"), ("duel-nozarashi", "nozarashi-1"),
         ("duel-meteor", "meteor-2"), ("duel-vfx-line-cuts-1", "buttagiru-2"),
         ("duel-bankai", "bankai-1"), ("duel-vfx-bankai-embers-0", "bankai-side-3")]


def label(g, d, x, y, text):
    d.rectangle((x, y, x + 8 * len(text) + 6, y + 14), fill=(20, 20, 26)); d.text((x + 3, y + 1), text, fill=(235, 235, 235))


def sheets():
    names = [f"{n}-{i + 1}" for n, _, _, beats in SCENES for i in range(sum(len(d) for _, d in beats))]
    ims = [(n, Image.open(OUT % n).convert("RGB").resize((384, 216))) for n in names if os.path.exists(OUT % n)]
    cols = 4
    g = Image.new("RGB", (cols * 384, ((len(ims) + cols - 1) // cols) * 216), (20, 20, 26)); d = ImageDraw.Draw(g)
    for i, (n, im) in enumerate(ims):
        x, y = (i % cols) * 384, (i // cols) * 216
        g.paste(im, (x, y)); label(g, d, x, y, n)
    g.save(OUT % "gallery")
    rows = [(b, a) for b, a in PAIRS if os.path.exists(f"tests/shots/{b}.png") and os.path.exists(OUT % a)]
    p = Image.new("RGB", (2 * 512, len(rows) * 288), (20, 20, 26)); d = ImageDraw.Draw(p)
    for r, (b, a) in enumerate(rows):
        p.paste(Image.open(f"tests/shots/{b}.png").convert("RGB").resize((512, 288)), (0, r * 288))
        p.paste(Image.open(OUT % a).convert("RGB").resize((512, 288)), (512, r * 288))
        label(p, d, 0, r * 288, f"BEFORE {b}"); label(p, d, 512, r * 288, f"AFTER style-3-{a}")
    p.save(OUT % "pairs")


if __name__ == "__main__":
    if "--sheet" in sys.argv: sheets(); sys.exit(0)
    dist = (sys.argv[1:] or ["dist/duel"])[0]
    st, secs, shots = steps()
    json.dump(st, open(f"{TMP}/s3.json", "w"))
    rc = subprocess.run(["node", "tools/run.mjs", dist, "--secs", str(round(secs, 1)), "--script", f"{TMP}/s3.json",
                         "--fixed-dt", "16.666667"], stdout=open(f"{TMP}/s3.log", "w"), stderr=subprocess.STDOUT).returncode
    sheets()
    print("run.mjs exit code", rc, "|", sum(os.path.exists(p) for p in shots), "of", len(shots), "stills")
    sys.exit(rc)
