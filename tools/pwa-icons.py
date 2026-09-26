#!/usr/bin/env python3
"""pwa-icons.py — draw SOUL DUEL's app icons into duel/web/ (PIL only, already used by the tests):
icon-192.png, icon-512.png, icon-maskable-512.png (the mark inside the 80 % safe circle) and apple-touch-icon.png
(180 px, opaque). The mark: a pale soul ring cut by a red brush slash on the dusk ink.  python3 tools/pwa-icons.py"""
from PIL import Image, ImageDraw

BG, RING, SLASH = (7, 7, 12, 255), (236, 232, 222, 255), (255, 30, 60, 255)


def icon(size, scale=1.0):
    k = 4                                              # supersample, then shrink (smooth edges)
    n = size * k
    im = Image.new("RGBA", (n, n), BG)
    d = ImageDraw.Draw(im)
    c, r = n / 2, n * 0.30 * scale
    d.ellipse([c - r, c - r, c + r, c + r], outline=RING, width=int(n * 0.07 * scale))
    w = n * 0.075 * scale                              # the slash: a long thin quad, lower left to upper right
    a, b = (c - n * 0.36 * scale, c + n * 0.24 * scale), (c + n * 0.36 * scale, c - n * 0.24 * scale)
    d.polygon([(a[0], a[1] + w * 0.2), (a[0] + w * 0.4, a[1] - w * 0.6), (b[0], b[1] - w * 0.2), (b[0] - w * 0.6, b[1] + w)],
              fill=SLASH)
    return im.resize((size, size), Image.LANCZOS)


for name, size, scale in (("icon-192", 192, 1.0), ("icon-512", 512, 1.0), ("icon-maskable-512", 512, 0.78),
                          ("apple-touch-icon", 180, 0.9)):
    icon(size, scale).convert("RGB").save(f"duel/web/{name}.png", optimize=True)
    print(f"duel/web/{name}.png")
