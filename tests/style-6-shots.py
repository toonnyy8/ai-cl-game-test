#!/usr/bin/env python3
"""style-6-shots.py — the phase-6 still set of the Storm x Kubo restyle (docs/style/STYLE_STORM_DESIGN.md §9 row 6, user
review 4): the destruction marks and resting chips, the pillars and the fire wave beside the lens, the face accents, the
left fist held on the cleaver's handle (the art viewer's grip strips), the caption slice exit, the skull in the Nozarashi
pillar, the K.O. rain, the soft shapes redrawn; a before / after sheet against the previous build; and the final review
sheet, a best-of across the whole restyle (tests/shots/style-final-gallery.png).

  python3 tests/style-6-shots.py [DUEL VIEW VFX BASE_DUEL BASE_VFX]   shoot (run.mjs --fixed-dt), then the sheets
  python3 tests/style-6-shots.py --sheet                              only rebuild the sheets

Defaults: dist/duel dist/duelview dist/duelvfx and the BASE copies dist/base6-duel dist/base6-duelvfx (built before the
phase). Writes tests/shots/style-6-<name>.png (the base ones style-6-before-<name>.png), style-6-final-<name>.png,
style-6-gallery.png, style-6-pairs.png and style-final-gallery.png. The fog-band verdict stills (style-6-fog-*) come from a
one-off build (§14 Phase 6), not from this script. Temporary files go to build/style/.
"""
import json, os, subprocess, sys
from PIL import Image, ImageDraw

TMP = "build/style"
os.makedirs(TMP, exist_ok=True)
OUT = "tests/shots/style-6-%s.png"


def cmd(t, c): return {"at": round(t, 3), "eval": f"Module._debug_cmd({c})"}
def key(t, k, down=True): return {"at": round(t, 3), "key": k, "down": down}


# gameplay scenes (dist/duel): (name, setup commands, keys [(delay, key, held s)], shot delays after the setup).
# 2100 skips the cinematics, 2109 toggles the side camera (each scene that turns it on turns it off again).
GAME = [
    ("marks", [2366], [], [0.3, 1.6]),                                    # scorch + crack + chips (looks placed directly)
    ("marks-side", [2109, 2366], [], [1.6]),
    ("face-accents", [2109, 2366], [], [0.15]),                           # 2366's face beats: the shout burst, hurt drops
    ("wave-scorch", [2302], [], [0.55, 1.28, 1.36, 2.6]),                 # the wave: shout, the hit (hurt drops), the scorch
    ("buttagiru", [2309], [], [0.45, 0.9, 1.6, 4.5]),                     # the cracks and chips thrown, at rest 3 s later
    ("meteor", [2305], [], [1.3, 3.2]),
    ("guard-break", [2306], [], [0.4, 1.3]),
    ("pillars", [2300], [], [0.25, 0.5, 0.75, 1.6]),                       # behind the lens + the Hellfire scorch
    ("pillars-side", [2109, 2300], [], [0.5]),
    ("bankai-cracks", [2109, 2312], [], [0.8]),                           # the ember core, now a drawn EMBER strip
    ("shiranui", [2500, 2108], [(0.5, "ShiftLeft", 0.8), (0.55, "KeyK", 0.7)], [1.0, 1.42]),   # the fireball's core
    ("men", [2109, 2383], [(0.5, "KeyJ", 0.08)], [0.62, 0.68, 0.78]),     # (the side camera from 2383 on)
    ("do", [2380], [(2.2, "KeyK", 0.08)], [2.42, 2.54, 2.65]),
    ("minami-exit", [2109, 2303], [], [0.3, 1.12, 1.2]),                   # a callout column slicing out (its last 0.3 s)
]
OFF_SIDE = {"marks-side", "face-accents", "pillars-side", "bankai-cracks", "do", "minami-exit"}   # toggle the side camera off after these
# cinematic stills (debug 10000 + 1000 k + f): the slice exits, the skull, the rain
CINES = [(2, "jokaku-exit", [96, 103, 106, 110]), (4, "ken-kikon-exit", [96, 101, 105]),
         (1, "nozarashi-skull", [38, 42, 46]), (8, "ko-rain", [30, 70, 110, 140])]
# the VFX gallery (dist/duelvfx: scene 2000 + k frozen at 4000 + ms): the soft cores redrawn
VFX = [("vfx-charge", 4, 700), ("vfx-fireball", 4, 1500), ("vfx-hit-cut", 18, 120), ("vfx-hit-heavy", 19, 150),
       ("vfx-pillars", 5, 350), ("vfx-bankai", 2, 900)]
# the art viewer: the grip strips (debug 7000 + k of *GRIP-CLIPS*: the kendo strikes)
GRIPS = [(2, "ke-r-q1"), (3, "ke-r-q3"), (4, "ke-r-f1"), (5, "ke-r-f2"), (6, "ke-n-f1")]

# the final review sheet (user review 4): gameplay in both cameras, every awakening and Kikon, the key effects, results
FINAL_GAME = [("behind", [2500], [], [0.8]), ("side", [2109, 2500], [], [0.8]), ("hellfire", [2109, 2300], [], [1.2]),
              ("wave", [2109, 2302], [], [1.0]), ("cup3", [2109, 2365], [], [1.2]), ("bankai", [2312], [], [0.8]),
              ("buttagiru", [2309], [], [1.4]), ("breaker", [2306], [], [0.7])]
FINAL_OFF = {"side", "hellfire", "wave", "cup3"}
FINAL_CINES = [(2, "jokaku", [20, 150]), (3, "tenchi", [20, 76]), (0, "bankai", [74, 128]), (1, "nozarashi", [42, 96]),
               (4, "ken-kikon", [20, 148]), (5, "sky-split", [20, 74]), (6, "soul-break", [14, 46]), (7, "intro", [180]),
               (8, "ko", [12, 110])]


def game_steps(tag, scenes, cines, off, out=OUT, skip_first=True):
    s, t, names = ([cmd(3.0, 2100)] if skip_first else []), 3.2, []
    for name, setup, keys, delays in scenes:
        for c in setup: s.append(cmd(t, c)); t += 0.05
        t0 = t
        for d, k, held in keys: s += [key(t0 + d, k), key(t0 + d + held, k, False)]
        for i, d in enumerate(delays):
            n = f"{tag}{name}-{i + 1}"; s.append({"at": round(t0 + d, 3), "shot": out % n}); names.append(n)
        t = t0 + max(delays + [d + h for d, _, h in keys]) + 0.5
        if name in off: s.append(cmd(t, 2109)); t += 0.1
    s.append(cmd(t, 2100)); t += 0.2                           # the cinematics play again
    for k, name, frames in cines:
        last = 0
        for f in frames:
            s.append(cmd(t, 10000 + 1000 * k + f)); wait = (f - last) / 60.0 + (1.2 if last == 0 else 0.35)
            n = f"{tag}{name}-{f:03d}"; s.append({"at": round(t + wait, 3), "shot": out % n}); names.append(n)
            t += wait + 0.1; last = f
        t += 0.3
    return s, t + 0.5, names


def final_steps():
    s, t, names = game_steps("final-", FINAL_GAME, FINAL_CINES, FINAL_OFF)
    s.append(cmd(t, 2209)); t += 150 / 60.0 + 1.8                          # K.O. -> the results card
    s.append({"at": round(t, 3), "shot": OUT % "final-results"}); names.append("final-results")
    return s, t + 0.5, names


def vfx_steps(tag):
    s, t, names = [cmd(3.0, 3000)], 3.2, []
    for name, scene, ms in VFX:
        s += [cmd(t, 2000 + scene), cmd(t + 0.05, 4000 + ms)]; t += ms / 1000.0 + 0.6
        n = f"{tag}{name}"; s.append({"at": round(t, 3), "shot": OUT % n}); names.append(n); t += 0.2
        s.append(cmd(t, 4999)); t += 0.1
    return s, t + 0.5, names


def view_steps():
    s, t, names = [], 9.0, []
    def snap(n): nonlocal t; t += 1.0; s.append({"at": round(t, 3), "shot": OUT % n}); names.append(n); t += 0.2
    for k, name in GRIPS:
        s.append(cmd(t, 7000 + k)); t += 0.25; snap(f"grip-{name}")
    s.append(cmd(t, 2005)); t += 0.3                           # the faces, for the final sheet
    s.append(cmd(t, 3000)); t += 0.1; snap("final-faces-lineup")
    for i, (who, face) in enumerate([(w, f) for w in ("yama", "ken") for f in ("neutral", "shout", "hurt")]):
        s.append(cmd(t, 6200 + i)); t += 0.25; snap(f"final-face-{who}-{face}")
    return s, t + 0.5, names


def run(dist, st, secs, tag):
    json.dump(st, open(f"{TMP}/s6-{tag}.json", "w"))
    return subprocess.run(["node", "tools/run.mjs", dist, "--secs", str(round(secs, 1)), "--script", f"{TMP}/s6-{tag}.json",
                           "--fixed-dt", "16.666667"], stdout=open(f"{TMP}/s6-{tag}.log", "w"), stderr=subprocess.STDOUT).returncode


def label(d, x, y, text):
    d.rectangle((x, y, x + 7 * len(text) + 6, y + 13), fill=(20, 20, 26)); d.text((x + 3, y + 1), text, fill=(235, 235, 235))


def after_names():
    names = [f"{n}-{i + 1}" for n, _, _, ds in GAME for i in range(len(ds))]
    names += [f"{n}-{f:03d}" for _, n, fs in CINES for f in fs] + [n for n, _, _ in VFX] + [f"grip-{n}" for _, n in GRIPS]
    return names + [f"fog-{v}-{w}" for v in ("title", "behind", "side") for w in ("before", "bands")]


def final_names():
    names = [f"final-{n}-{i + 1}" for n, _, _, ds in FINAL_GAME for i in range(len(ds))]
    names += [f"final-{n}-{f:03d}" for _, n, fs in FINAL_CINES for f in fs] + ["final-results", "final-faces-lineup"]
    return names + [f"final-face-{w}-{f}" for w in ("yama", "ken") for f in ("neutral", "shout", "hurt")] + ["face-accents-1"]


# before -> after rows of the pairs sheet
PAIRS = ([(f"before-{n}-{i}", f"{n}-{i}") for n, i in (("marks", 2), ("wave-scorch", 3), ("wave-scorch", 4), ("buttagiru", 3),
                                                       ("buttagiru", 4), ("meteor", 2), ("guard-break", 2), ("pillars", 2),
                                                       ("pillars", 3), ("pillars-side", 1), ("bankai-cracks", 1),
                                                       ("shiranui", 2), ("men", 2), ("do", 2), ("minami-exit", 2))] +
         [(f"before-{n}", n) for n, _, _ in VFX] +
         [("before-jokaku-exit-106", "jokaku-exit-106"), ("before-ken-kikon-exit-101", "ken-kikon-exit-101"),
          ("before-nozarashi-skull-042", "nozarashi-skull-042"), ("before-ko-rain-110", "ko-rain-110")] +
         [(f"fog-{v}-before", f"fog-{v}-bands") for v in ("title", "behind", "side")])


def contact(names, out, cols=5, w=384, h=216):
    ims = [(n, Image.open(OUT % n).convert("RGB").resize((w, h))) for n in names if os.path.exists(OUT % n)]
    g = Image.new("RGB", (cols * w, ((len(ims) + cols - 1) // cols) * h), (20, 20, 26)); d = ImageDraw.Draw(g)
    for i, (n, im) in enumerate(ims):
        x, y = (i % cols) * w, (i // cols) * h
        g.paste(im, (x, y)); label(d, x, y, n)
    g.save(out)


def sheets():
    contact(after_names(), OUT % "gallery")
    contact(final_names(), "tests/shots/style-final-gallery.png", cols=6, w=426, h=240)
    rows = [(b, a) for b, a in PAIRS if os.path.exists(OUT % b) and os.path.exists(OUT % a)]
    p = Image.new("RGB", (2 * 480, len(rows) * 270), (20, 20, 26)); d = ImageDraw.Draw(p)
    for r, (b, a) in enumerate(rows):
        p.paste(Image.open(OUT % b).convert("RGB").resize((480, 270)), (0, r * 270))
        p.paste(Image.open(OUT % a).convert("RGB").resize((480, 270)), (480, r * 270))
        label(d, 0, r * 270, "BEFORE " + b.replace("before-", "")); label(d, 480, r * 270, f"AFTER {a}")
    p.save(OUT % "pairs")


if __name__ == "__main__":
    if "--sheet" in sys.argv: sheets(); sys.exit(0)
    a = [x for x in sys.argv[1:] if not x.startswith("-")]
    duel, view, vfx, bduel, bvfx = (a + ["dist/duel", "dist/duelview", "dist/duelvfx", "dist/base6-duel",
                                         "dist/base6-duelvfx"][len(a):])[:5]
    rc, want = 0, []
    for dist, (st, secs, names), tag in ((duel, game_steps("", GAME, CINES, OFF_SIDE), "game"), (vfx, vfx_steps(""), "vfx"),
                                         (view, view_steps(), "view"), (duel, final_steps(), "final"),
                                         (bduel, game_steps("before-", GAME, CINES, OFF_SIDE), "bgame"),
                                         (bvfx, vfx_steps("before-"), "bvfx")):
        rc |= run(dist, st, secs, tag); want += names
    sheets()
    print("run.mjs exit code", rc, "|", sum(os.path.exists(OUT % n) for n in want), "of", len(want), "stills")
    sys.exit(rc)
