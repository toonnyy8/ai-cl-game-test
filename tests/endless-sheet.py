#!/usr/bin/env python3
"""endless-sheet.py — the ENDLESS contact sheet (docs/duel/DUEL_ENDLESS.md): the stills of duel-endless.json (landscape, top
row) and duel-endless-portrait.json (portrait, bottom row) under their names.
  python3 tests/endless-sheet.py [OUT.png]      (default tests/shots/duel-endless-sheet.png)"""
import os, sys
from PIL import Image, ImageDraw

out = sys.argv[1] if len(sys.argv) > 1 else "tests/shots/duel-endless-sheet.png"
H = 300                                            # every thumbnail this tall
rows = [[f"tests/shots/duel-endless-{n}.png" for n in
         ("mode", "select", "hud", "clear", "clear-awakened", "clear-bankai", "hud-4", "results", "results-best")],
        [f"tests/shots/duel-endless-p-{n}.png" for n in
         ("mode", "select", "hud", "clear", "clear-awakened", "pause", "results")]]
cells = []
for paths in rows:
    row = []
    for p in paths:
        if not os.path.exists(p): continue
        im = Image.open(p).convert("RGB"); im = im.resize((round(im.width * H / im.height), H), Image.LANCZOS)
        c = Image.new("RGB", (im.width, H + 20), (24, 24, 30)); c.paste(im, (0, 20))
        ImageDraw.Draw(c).text((4, 4), os.path.basename(p)[len("duel-endless-"):-4], fill=(235, 230, 220))
        row.append(c)
    cells.append(row)
W = max(sum(c.width + 8 for c in r) for r in cells) + 8
sheet = Image.new("RGB", (W, len(cells) * (H + 28) + 8), (12, 12, 16))
for j, r in enumerate(cells):
    x = 8
    for c in r: sheet.paste(c, (x, 8 + j * (H + 28))); x += c.width + 8
sheet.save(out); print(f"{out}: {sum(map(len, cells))} stills, {sheet.width}x{sheet.height}")
