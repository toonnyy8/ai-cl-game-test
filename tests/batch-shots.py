#!/usr/bin/env python3
"""batch-shots.py — stills of the Kenpachi batch (DUEL_DESIGN §6.2, DUEL_NOZARASHI_V2.md, built 2026-09-26): the
Nozarashi awakening with no eyepatch (debug 10000 + 1000 k + f), the three NOME cups (2380: the ladder probe walks
NOME up), DRINK (2381, U held), KUKAN-GIRI's rift (2382), the cash-out (2384), West's hold-U armour (2379, 2385) and
the run facing the opponent (2503: side slide, back-skate). Same pattern as tests/style-4-shots.py.

  python3 tests/batch-shots.py [DUEL_DIST]     shoot (run.mjs --fixed-dt) and build the contact sheet
  python3 tests/batch-shots.py --sheet         only rebuild the sheet

writes tests/shots/batch-<name>.png and tests/shots/batch-sheet.png.
"""
import json, os, subprocess, sys
from PIL import Image, ImageDraw

TMP = "build/style"
os.makedirs(TMP, exist_ok=True)
OUT = "tests/shots/batch-%s.png"


def cmd(t, c): return {"at": round(t, 3), "eval": f"Module._debug_cmd({c})"}
def shot(t, name): return {"at": round(t, 3), "shot": OUT % name}
def key(t, k, down=True): return {"at": round(t, 3), "key": k, "down": down}


def steps():
    s, t, names = [cmd(3.0, 2106)], 3.2, []
    def snap(at, name): s.append(shot(at, name)); names.append(name)
    last = 0                                              # the awakening: no eyepatch; the release is the whole first beat
    for f in (5, 20, 26, 40, 66, 84, 96):
        s.append(cmd(t, 11000 + f)); wait = (f - last) / 60.0 + (1.2 if last == 0 else 0.35)
        snap(t + wait, f"nozarashi-{f:03d}"); t += wait + 0.1; last = f
    s += [cmd(t + 0.2, 2100), cmd(t + 0.4, 2100)]; t += 0.8    # skip the held cinematic (and turn skipping off again)
    s.append(cmd(t, 2109)); t += 0.2                      # the side camera
    s.append(cmd(t, 2380))                               # the ladder: cup 1, 2 (m >= 40), 3 (m = 100) and the page beat
    snap(t + 0.5, "cup1-katate"); snap(t + 1.6, "cup2-ryote"); snap(t + 4.56, "cup3-entry-page"); snap(t + 5.6, "cup3-nomihose")
    t += 6.5
    s += [cmd(t, 2381), key(t + 0.1, "KeyU")]            # DRINK
    snap(t + 0.35, "drink-a"); snap(t + 0.75, "drink-b"); s.append(key(t + 1.2, "KeyU", False)); t += 1.8
    s += [cmd(t, 2382), key(t + 0.5, "KeyK"), key(t + 0.58, "KeyK", False)]   # the rift into a guard
    snap(t + 0.95, "rift-open"); snap(t + 1.2, "rift-cut"); t += 2.2
    s += [cmd(t, 2384), key(t + 0.5, "ShiftLeft"), key(t + 0.55, "KeyK"), key(t + 0.65, "KeyK", False),
          key(t + 0.7, "ShiftLeft", False)]              # the cash-out
    snap(t + 0.75, "cashout-windup"); snap(t + 1.02, "cashout-cut"); t += 2.5
    s += [cmd(t, 2379), key(t + 0.1, "KeyU")]            # West: U held, attacking through Kenpachi's mash
    for i in range(6): s += [key(t + 0.4 + 0.35 * i, "KeyJ"), key(t + 0.45 + 0.35 * i, "KeyJ", False)]
    snap(t + 0.9, "west-armour-a"); snap(t + 1.5, "west-armour-b"); s.append(key(t + 2.5, "KeyU", False)); t += 3.0
    s += [cmd(t, 2385), key(t + 0.1, "KeyU")]            # West under RYOTE's K K: the cut
    snap(t + 0.5, "west-cut-a"); snap(t + 1.3, "west-cut-b"); s.append(key(t + 2.0, "KeyU", False)); t += 2.5
    s.append(cmd(t, 2503)); t += 1.0                     # KK: the run facing the opponent (P1 human)
    s += [key(t, "KeyA"), key(t + 0.05, "Space")]; snap(t + 0.9, "run-slide"); s += [key(t + 1.1, "Space", False), key(t + 1.1, "KeyA", False)]
    t += 1.8
    s += [key(t, "KeyS"), key(t + 0.05, "Space")]; snap(t + 0.9, "run-skate"); s += [key(t + 1.1, "Space", False), key(t + 1.1, "KeyS", False)]
    t += 1.8
    s += [key(t, "KeyW"), key(t + 0.05, "Space")]; snap(t + 0.6, "run-forward"); s += [key(t + 0.8, "Space", False), key(t + 0.8, "KeyW", False)]
    return s, t + 1.5, names


def label(d, x, y, text):
    d.rectangle((x, y, x + 7 * len(text) + 6, y + 13), fill=(20, 20, 26)); d.text((x + 3, y + 1), text, fill=(235, 235, 235))


def sheet(names=None):
    names = names or sorted(os.path.basename(f)[6:-4] for f in os.listdir("tests/shots")
                            if f.startswith("batch-") and f.endswith(".png") and f != "batch-sheet.png")
    ims = [(n, Image.open(OUT % n).convert("RGB").resize((384, 216))) for n in names if os.path.exists(OUT % n)]
    cols = 5
    g = Image.new("RGB", (cols * 384, ((len(ims) + cols - 1) // cols) * 216), (20, 20, 26)); d = ImageDraw.Draw(g)
    for i, (n, im) in enumerate(ims):
        x, y = (i % cols) * 384, (i // cols) * 216
        g.paste(im, (x, y)); label(d, x, y, n)
    g.save(OUT % "sheet")


if __name__ == "__main__":
    if "--sheet" in sys.argv: sheet(); sys.exit(0)
    dist = ([a for a in sys.argv[1:] if not a.startswith("-")] + ["dist/duel"])[0]
    st, secs, names = steps()
    json.dump(st, open(f"{TMP}/batch.json", "w"))
    rc = subprocess.run(["node", "tools/run.mjs", dist, "--secs", str(round(secs, 1)), "--script", f"{TMP}/batch.json",
                         "--fixed-dt", "16.666667"], stdout=open(f"{TMP}/batch.log", "w"), stderr=subprocess.STDOUT).returncode
    sheet(names)
    print("run.mjs exit code", rc, "|", sum(os.path.exists(OUT % n) for n in names), "of", len(names), "stills")
    sys.exit(rc)
