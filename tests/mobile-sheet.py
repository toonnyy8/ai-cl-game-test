#!/usr/bin/env python3
"""mobile-sheet.py — the portrait review contact sheet (docs/duel/DUEL_MOBILE_DESIGN.md P2): each still of
tests/scripts/duel-mobile.py side by side, AFTER (and BEFORE when given) under a label.
  python3 tests/mobile-sheet.py OUT.png AFTER_DIR [BEFORE_DIR] [--names a,b,c] [--w 260]"""
import os, sys
from PIL import Image, ImageDraw

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opt = lambda k, d: sys.argv[sys.argv.index(k) + 1] if k in sys.argv else d
out, after = args[0], args[1]
before = args[2] if len(args) > 2 and not args[2].startswith(("--",)) and os.path.isdir(args[2]) else None
names = opt("--names", "neutral,close,far,side,string,ender,kosei,paused,gestures,mode,select,intro,cine-kikon,cine-kikon-b,"
                       "cine-bankai,cine-ken,cine-nozarashi,cine-soul,results").split(",")
W = int(opt("--w", "260")); cols = int(opt("--cols", "6"))
tiles = []
for n in names:
    a = os.path.join(after, f"mobile-{n}.png")
    if not os.path.exists(a): continue
    b = os.path.join(before, f"mobile-{n}.png") if before else None
    tiles.append((n, [p for p in (b, a) if p and os.path.exists(p)]))
def thumb(p):
    im = Image.open(p).convert("RGB"); return im.resize((W, round(im.height * W / im.width)), Image.LANCZOS)
cells = []
for n, ps in tiles:
    ims = [thumb(p) for p in ps]
    th = max(i.height for i in ims)
    c = Image.new("RGB", (len(ims) * W + (len(ims) - 1) * 6, th + 22), (24, 24, 30))
    d = ImageDraw.Draw(c)
    for i, im in enumerate(ims):
        c.paste(im, (i * (W + 6), 22))
        tag = ("before" if len(ims) == 2 and i == 0 else "after") if before else ""
        d.text((i * (W + 6) + 4, 5), f"{n} {tag}".strip(), fill=(235, 230, 220))
    cells.append(c)
cw = max(c.width for c in cells); ch = max(c.height for c in cells); per = max(1, cols // max(1, len(tiles[0][1])))
rows = (len(cells) + per - 1) // per
sheet = Image.new("RGB", (per * (cw + 12) + 12, rows * (ch + 12) + 12), (12, 12, 16))
for i, c in enumerate(cells): sheet.paste(c, (12 + (i % per) * (cw + 12), 12 + (i // per) * (ch + 12)))
sheet.save(out); print(f"{out}: {len(cells)} stills, {sheet.width}x{sheet.height}")
