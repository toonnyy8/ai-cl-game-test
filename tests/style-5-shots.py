#!/usr/bin/env python3
"""style-5-shots.py — the phase-5 still set of the Storm x Kubo restyle (docs/style/STYLE_STORM_DESIGN.md §9 row 5): every
effect redone in Phase 5 (the fire looks, the fire wave's erosion, the Hellfire / Evolution / Breaker auras, Tenchi's
ash, the rift and its ink gash, West's garb block / flare / burnout, Nadegiri, the SP2 dash, cup 3's entry beat) in
gameplay framing, the RYOTE kendo clips and the re-authored attack clips (the art viewer), the three expressions of
each fighter, and a before / after sheet against the previous build.

  python3 tests/style-5-shots.py [DUEL VIEW VFX BASE_DUEL BASE_VIEW BASE_VFX]   shoot (run.mjs --fixed-dt), then the sheets
  python3 tests/style-5-shots.py --sheet                                        only rebuild the sheets

Defaults: dist/duel dist/duelview dist/duelvfx and the BASE copies dist/base5-duel dist/base5-duelview dist/base5-duelvfx
(built before the phase). Writes tests/shots/style-5-<name>.png (look at every one; the base ones are
style-5-before-<name>.png), style-5-gallery.png and style-5-pairs.png. Temporary files go to build/style/.
"""
import json, os, re, subprocess, sys
from PIL import Image, ImageDraw

TMP = "build/style"
os.makedirs(TMP, exist_ok=True)
OUT = "tests/shots/style-5-%s.png"


def cmd(t, c): return {"at": round(t, 3), "eval": f"Module._debug_cmd({c})"}
def key(t, k, down=True): return {"at": round(t, 3), "key": k, "down": down}


# gameplay scenes (dist/duel): (name, setup commands, keys [(delay after the setup, key, held s)], shot delays after the
# setup). 2100 skips the cinematics, 2109 toggles the side camera; 2500 = human Yamamoto vs an idle Kenpachi.
GAME = [
    ("shiranui", [2500, 2108], [(0.5, "ShiftLeft", 0.8), (0.55, "KeyK", 0.7)], [1.0, 1.42, 1.55]),   # (not full: no Hellfire)
    ("taimatsu", [2500, 2108], [(0.5, "ShiftLeft", 0.2), (0.55, "KeyL", 0.1)], [0.86, 1.0, 1.25]),
    ("pillars", [2109, 2300], [], [0.25, 0.5, 0.75]),
    ("hellfire", [], [], [2.2]),
    ("nadegiri", [2108], [(0.2, "ShiftLeft", 0.2), (0.25, "KeyL", 0.1)], [0.6, 0.66, 0.9]),
    ("wave", [2109, 2302], [], [0.8, 1.2, 1.32]),
    ("breaker-yama", [2500], [(0.3, "KeyI", 0.1)], [0.6, 1.1]),
    ("breaker-ken", [2306], [], [0.35, 0.7]),
    ("evolution", [2311], [], [0.6]),
    ("sp2-dash", [2310], [], [0.32, 0.4]),
    ("rift", [2383], [(0.5, "KeyK", 0.08)], [0.8, 1.16, 1.3]),
    ("garb-block", [2372], [(0.1, "KeyU", 9.0)], [0.4, 0.5, 7.75, 7.95, 8.3]),
    ("garb-flare", [2379], [], [0.97, 1.05, 1.2]),
    ("cup3", [2109, 2380], [], [4.55, 4.7, 4.95]),
    ("men", [2109, 2383], [(0.5, "KeyJ", 0.08)], [0.62, 0.68, 0.78]),          # cup 3's J is cup 2's MEN
    ("do", [2380], [(2.2, "KeyK", 0.08)], [2.42, 2.54, 2.65]),                # the ladder is in cup 2 by then
]
# cinematic stills (debug 10000 + 1000 k + f): Jokaku Enjo's dome (k 2), Tenchi's ash (k 3)
CINES = [(2, "dome", [70, 110, 130, 146, 160]), (3, "tenchi-ash", [100, 130])]
# the VFX gallery (dist/duelvfx: scene 2000 + k frozen at 4000 + ms): the same frame before and after
VFX = [("vfx-hellfire", 1, 900), ("vfx-charge", 4, 700), ("vfx-fireball", 4, 1500), ("vfx-pillars", 5, 350),
       ("vfx-dome-rise", 6, 500), ("vfx-dome-close", 6, 1300), ("vfx-dome-boom", 6, 1850), ("vfx-evolution", 7, 900),
       ("vfx-breaker", 8, 900), ("vfx-ash", 11, 500), ("vfx-cone", 14, 6850)]
# the art viewer: the kendo clips (new) and the clips they replace (base), the re-authored attack clips, the faces
KENDO = [("ke-r-q1", "ke-f1"), ("ke-r-q3", "ke-q3"), ("ke-r-f1", "ke-f1"), ("ke-r-f2", "ke-f2"), ("ke-n-f1", "ke-f1")]
CLIPS = ["ya-f1", "ya-sig", "ya-kyoku", "ke-f1", "ke-meteor", "ke-buttagiru"]


def clip_names(rev=None):
    """The viewer's clip order (LIST-CLIPS: every DEFCLIP / DEFSTRIKE / DEFRUN clip, names sorted), from the art
    sources of the work tree or of git revision REV."""
    names = set()
    for f in ("duel/lisp/body.lisp", "duel/lisp/yama-art.lisp", "duel/lisp/ken-art.lisp"):
        src = subprocess.run(["git", "show", f"{rev}:{f}"], capture_output=True, text=True).stdout if rev else open(f).read()
        names |= {m.group(2).upper() for m in re.finditer(r"^\((defclip|defstrike) :([a-z0-9-]+)", src, re.M)}
        for m in re.finditer(r"^\(defrun :\S+ ((?::[a-z0-9-]+ ?)+)\)", src, re.M):
            names |= {n.lstrip(":").upper() for n in m.group(1).split()}
    return sorted(names)


def game_steps(tag):
    s, t, names = [cmd(3.0, 2100)], 3.2, []                   # (skip the cinematics in the gameplay scenes)
    for name, setup, keys, delays in GAME:
        for c in setup: s.append(cmd(t, c)); t += 0.05
        t0 = t
        for d, k, held in keys: s += [key(t0 + d, k), key(t0 + d + held, k, False)]
        for i, d in enumerate(delays):
            n = f"{tag}{name}-{i + 1}"; s.append({"at": round(t0 + d, 3), "shot": OUT % n}); names.append(n)
        t = t0 + max(delays + [d + h for d, _, h in keys]) + 0.5
    s.append(cmd(t, 2100)); t += 0.2                           # the cinematics play again
    for k, name, frames in CINES:
        last = 0
        for f in frames:
            s.append(cmd(t, 10000 + 1000 * k + f)); wait = (f - last) / 60.0 + (1.2 if last == 0 else 0.35)
            n = f"{tag}{name}-{f:03d}"; s.append({"at": round(t + wait, 3), "shot": OUT % n}); names.append(n)
            t += wait + 0.1; last = f
        t += 0.3
    return s, t + 0.5, names


def vfx_steps(tag):
    s, t, names = [cmd(3.0, 3000)], 3.2, []                    # the stats line off
    for name, scene, ms in VFX:
        s += [cmd(t, 2000 + scene), cmd(t + 0.05, 4000 + ms)]; t += ms / 1000.0 + 0.6
        n = f"{tag}{name}"; s.append({"at": round(t, 3), "shot": OUT % n}); names.append(n); t += 0.2
        s.append(cmd(t, 4999)); t += 0.1
    return s, t + 0.5, names


def view_steps(tag, clips):
    order = clip_names(rev="HEAD" if tag else None)
    s, t, names = [], 9.0, []
    def snap(n): nonlocal t; t += 1.0; s.append({"at": round(t, 3), "shot": OUT % n}); names.append(n); t += 0.2
    for new, old in KENDO:
        name = (old if tag else new).upper()
        if name in order:
            s.append(cmd(t, 1000000 + 1000 * order.index(name))); t += 0.25; snap(f"{tag}strip-{new}")
    for c in clips:
        if c.upper() in order:
            s.append(cmd(t, 1000000 + 1000 * order.index(c.upper()))); t += 0.25; snap(f"{tag}strip-{c}")
    if tag:                                                    # the base viewer: the neutral faces only
        s.append(cmd(t, 2000)); t += 0.3
        for i, who in enumerate(("yama", "ken")):
            s.append(cmd(t, 6200 + i)); t += 0.25; snap(f"{tag}face-{who}")
    else:
        s.append(cmd(t, 2005)); t += 0.3
        s.append(cmd(t, 3000)); t += 0.1; snap("faces-lineup")
        for i, (who, face) in enumerate([(w, f) for w in ("yama", "ken") for f in ("neutral", "shout", "hurt")]):
            s.append(cmd(t, 6200 + i)); t += 0.25; snap(f"face-{who}-{face}")
    return s, t + 0.5, names


def run(dist, st, secs, tag):
    json.dump(st, open(f"{TMP}/s5-{tag}.json", "w"))
    return subprocess.run(["node", "tools/run.mjs", dist, "--secs", str(round(secs, 1)), "--script", f"{TMP}/s5-{tag}.json",
                           "--fixed-dt", "16.666667"], stdout=open(f"{TMP}/s5-{tag}.log", "w"), stderr=subprocess.STDOUT).returncode


def label(d, x, y, text):
    d.rectangle((x, y, x + 7 * len(text) + 6, y + 13), fill=(20, 20, 26)); d.text((x + 3, y + 1), text, fill=(235, 235, 235))


def all_after():
    names = [f"{n}-{i + 1}" for n, _, _, ds in GAME for i in range(len(ds))]
    names += [f"{n}-{f:03d}" for _, n, fs in CINES for f in fs] + [n for n, _, _ in VFX]
    names += [f"strip-{n}" for n, _ in KENDO] + [f"strip-{c}" for c in CLIPS] + ["faces-lineup"]
    names += [f"face-{w}-{f}" for w in ("yama", "ken") for f in ("neutral", "shout", "hurt")]
    return names


# before -> after rows of the pairs sheet: every redone effect, the kendo clips, re-authored clips, the faces
PAIRS = ([(f"before-{n}", n) for n, _, _ in VFX] +
         [(f"before-{n}-{i}", f"{n}-{i}") for n, i in (("shiranui", 2), ("taimatsu", 2), ("pillars", 2), ("hellfire", 1),
                                                       ("nadegiri", 2), ("wave", 3), ("breaker-yama", 1), ("breaker-ken", 1),
                                                       ("sp2-dash", 2), ("rift", 1), ("rift", 3), ("garb-block", 1),
                                                       ("garb-block", 4), ("garb-flare", 2), ("cup3", 3), ("men", 2), ("do", 2))] +
         [("before-dome-130", "dome-130"), ("before-dome-160", "dome-160"), ("before-tenchi-ash-130", "tenchi-ash-130")] +
         [(f"before-strip-{n}", f"strip-{n}") for n, _ in KENDO] + [(f"before-strip-{c}", f"strip-{c}") for c in CLIPS] +
         [("before-face-yama", "face-yama-shout"), ("before-face-ken", "face-ken-shout")])


def sheets():
    ims = [(n, Image.open(OUT % n).convert("RGB").resize((384, 216))) for n in all_after() if os.path.exists(OUT % n)]
    cols = 5
    g = Image.new("RGB", (cols * 384, ((len(ims) + cols - 1) // cols) * 216), (20, 20, 26)); d = ImageDraw.Draw(g)
    for i, (n, im) in enumerate(ims):
        x, y = (i % cols) * 384, (i // cols) * 216
        g.paste(im, (x, y)); label(d, x, y, n)
    g.save(OUT % "gallery")
    rows = [(b, a) for b, a in PAIRS if os.path.exists(OUT % b) and os.path.exists(OUT % a)]
    p = Image.new("RGB", (2 * 480, len(rows) * 270), (20, 20, 26)); d = ImageDraw.Draw(p)
    for r, (b, a) in enumerate(rows):
        p.paste(Image.open(OUT % b).convert("RGB").resize((480, 270)), (0, r * 270))
        p.paste(Image.open(OUT % a).convert("RGB").resize((480, 270)), (480, r * 270))
        label(d, 0, r * 270, f"BEFORE {b[7:]}"); label(d, 480, r * 270, f"AFTER {a}")
    p.save(OUT % "pairs")


if __name__ == "__main__":
    if "--sheet" in sys.argv: sheets(); sys.exit(0)
    a = [x for x in sys.argv[1:] if not x.startswith("-")]
    duel, view, vfx, bduel, bview, bvfx = (a + ["dist/duel", "dist/duelview", "dist/duelvfx", "dist/base5-duel",
                                                "dist/base5-duelview", "dist/base5-duelvfx"][len(a):])[:6]
    rc, want = 0, []
    for dist, (st, secs, names), tag in ((duel, game_steps(""), "game"), (vfx, vfx_steps(""), "vfx"),
                                         (view, view_steps("", CLIPS), "view"), (bduel, game_steps("before-"), "bgame"),
                                         (bvfx, vfx_steps("before-"), "bvfx"), (bview, view_steps("before-", CLIPS), "bview")):
        rc |= run(dist, st, secs, tag); want += names
    sheets()
    print("run.mjs exit code", rc, "|", sum(os.path.exists(OUT % n) for n in want), "of", len(want), "stills")
    sys.exit(rc)
