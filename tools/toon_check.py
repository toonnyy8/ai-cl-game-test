#!/usr/bin/env python3
"""toon_check.py — measures a SOUL DUEL still against the v4 notan rules (docs/STYLE_STORM_DESIGN.md
§A.1 value system, §A.2 spot colour, §2.5 palettes, §9 row 1a acceptance).

  python3 tools/toon_check.py STILL.png [--bg NOFIGHTERS.png] [--horizon ROW] [--palette HEX,HEX,...]
                              [--haori F0F0EC] [--robe 16161E] [--outline] [--ac] [--exclude x0,y0,x1,y1 ...]

STILL is a frame with the HUD off. --bg is the same frozen frame without the fighters (duel-vfx 3002):
the pixels that differ are the FIGHTER MASK, everything else is WORLD. Without --bg the whole frame is
world. --horizon: the screen row of the horizon (default: estimated, the row that best splits dark sky
rows from light ground rows). --exclude: rectangles (pixels) left out of every measure (e.g. a label).
Reports:
  value steps     share of pixels per step V0..V4 (luma bands between the §A.1 steps)
  world           chroma (max - min channel) / 255, p99 and max over world pixels: the §A.1 "saturation <= 0.12"
                  (HSV saturation would flag the design's own cold greys: V1 #3A3E4C has S 0.24, chroma 0.07)
  spot            share of the frame with HSV S > 0.45 and chroma > 0.25 (spot colour, budget <= 15 %)
  balance         median luma of the world above and below the horizon (user review 1: one balanced
                  cold mid-dark world, not black top / white bottom), the world's luma range (the moon
                  excepted), and the fighters' luma span, which must beat the world's (black robe vs
                  white haori is the strongest contrast on screen)
  fighters        (--bg) interior mask pixels (3x3 uniform): how many match the palette's lit tones or
                  their fs_toon shadow tones (--palette, needs a still with the gradient off), the
                  brightest pixel vs --haori, the lit robe tone vs --robe
  outline         (--bg, --outline; a still without the shadow discs) the ink hull (§2.4, Phase 1b): the share of the
                  fighter mask's edge pixels that have an ink pixel (within 24 of #101018, the keyline #4A5062 or the
                  skin ink #3A1E1A) within 2 px inside the mask, split by what lies outside: sky (above the horizon)
                  or ground; with --ac each must be >= 90 % (a continuous silhouette)
--ac applies the Phase 1a acceptance thresholds (as revised at user review 1) and exits 1 when one fails.
"""
import argparse, colorsys, sys
import numpy as np
from PIL import Image

STEPS = [("V0", 0, 30), ("V1", 30, 95), ("V2", 95, 160), ("V3", 160, 215), ("V4", 215, 256)]   # luma 0..255


def load(p):
    return np.asarray(Image.open(p).convert("RGB")).astype(np.int32)


def luma(a):
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def hsv_sv(a):
    mx = a.max(-1).astype(np.float64); mn = a.min(-1).astype(np.float64)
    return np.where(mx > 0, (mx - mn) / np.maximum(mx, 1), 0.0), mx / 255.0


def hexrgb(h):
    h = int(h, 16); return np.array([(h >> 16) & 255, (h >> 8) & 255, h & 255])


def shade_of(rgb, val=0.72, sat=1.25, hue=8.0):
    """fs_toon's designed shadow (toon.frag.wgsl SHADE_OF, HSV of the sRGB colour) of a palette colour, sRGB 0..255."""
    h, s, v = colorsys.rgb_to_hsv(*(np.asarray(rgb, float) / 255.0))
    warm = h < 0.19 or h > 0.83
    if s < 0.12:
        h, s = 0.61, max(s * sat, 0.10)
    else:
        h, s = (h + (-hue if warm else hue) / 360.0) % 1.0, min(s * sat, 1.0)
    v *= val
    return np.round(np.array(colorsys.hsv_to_rgb(h, s, v)) * 255).astype(int)


def estimate_horizon(lum, keep):
    """Row that maximises the between-class variance of per-row mean luma (dark rows above, light below)."""
    rows = np.array([lum[y][keep[y]].mean() if keep[y].any() else 0 for y in range(lum.shape[0])])
    best, by = -1, lum.shape[0] // 2
    for y in range(8, len(rows) - 8):
        a, b = rows[:y], rows[y:]
        if b.mean() <= a.mean(): continue
        v = len(a) * len(b) * (a.mean() - b.mean()) ** 2
        if v > best: best, by = v, y
    return by


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("still"); ap.add_argument("--bg"); ap.add_argument("--horizon", type=int)
    ap.add_argument("--palette"); ap.add_argument("--haori"); ap.add_argument("--robe")
    ap.add_argument("--exclude", nargs="*", default=[]); ap.add_argument("--ac", action="store_true")
    ap.add_argument("--outline", action="store_true")
    o = ap.parse_args()
    img = load(o.still); H, W, _ = img.shape
    keep = np.ones((H, W), bool)
    for r in o.exclude:
        x0, y0, x1, y1 = map(int, r.split(",")); keep[y0:y1, x0:x1] = False
    fighter = np.zeros((H, W), bool)
    if o.bg:
        fighter = (np.abs(img - load(o.bg)).max(-1) > 2) & keep
    world = keep & ~fighter
    lum = luma(img); s, v = hsv_sv(img)
    fails = []

    def check(name, ok, text):
        print(f"{'PASS' if ok else 'FAIL'} {name}: {text}")
        if not ok: fails.append(name)

    n = keep.sum()
    print(f"{o.still}: {W}x{H}, fighters {fighter.sum() / n * 100:.1f} % of the frame")
    print("value steps  " + "  ".join(f"{k} {((lum >= a) & (lum < b) & keep).sum() / n * 100:5.1f}%" for k, a, b in STEPS))
    chroma = (img.max(-1) - img.min(-1)) / 255.0
    ws = chroma[world] if world.any() else np.zeros(1)
    print(f"world        chroma p99 {np.percentile(ws, 99):.3f} max {ws.max():.3f}")
    spot = (s > 0.45) & (chroma > 0.25) & keep
    print(f"spot         {spot.sum() / n * 100:.2f} % of the frame has S > 0.45")
    hz = o.horizon if o.horizon is not None else estimate_horizon(lum, world)
    sky = world.copy(); sky[hz:] = False
    gnd = world.copy(); gnd[:hz] = False
    wl = lum[world & (lum < 180)]                     # the world without the moon disc (V4 by design)
    wl = wl if len(wl) else np.zeros(1)
    top = np.median(lum[sky & (lum < 180)]) if (sky & (lum < 180)).any() else 0.0
    bot = np.median(lum[gnd]) if gnd.any() else 0.0
    wspan = np.percentile(wl, 98) - np.percentile(wl, 2)
    print(f"horizon      row {hz} ({'given' if o.horizon is not None else 'estimated'}): median luma above {top:.0f}, below {bot:.0f}"
          f" (gap {abs(bot - top):.0f}); world luma p2 {np.percentile(wl, 2):.0f} p98 {np.percentile(wl, 98):.0f} (moon excepted)")
    fspan = 0.0
    if fighter.any():
        fl = lum[fighter]; fspan = np.percentile(fl, 98) - np.percentile(fl, 2)
        print(f"contrast     fighters luma span {fspan:.0f} vs world span {wspan:.0f}")
    if o.ac:
        check("world saturation (chroma) <= 0.12", np.percentile(ws, 99) <= 0.12, f"p99 {np.percentile(ws, 99):.3f}")
        if (sky & (lum < 180)).sum() > 0.02 * n:          # else the horizon is off the frame (or under the HUD)
            check("world balanced (sky / ground median gap <= 75)", abs(bot - top) <= 75, f"{abs(bot - top):.0f}")
        else: print("n/a  world balanced: no sky in the measured frame")
        check("world in the cold mid-dark range (luma p2 >= 20, p98 <= 150)", np.percentile(wl, 2) >= 20 and np.percentile(wl, 98) <= 150,
              f"{np.percentile(wl, 2):.0f} .. {np.percentile(wl, 98):.0f}")
        if fighter.any():
            check("fighters carry the strongest contrast (span >= world span + 60)", fspan >= wspan + 60, f"{fspan:.0f} vs {wspan:.0f}")
        check("spot <= 15 %", spot.sum() / n <= 0.15, f"{spot.sum() / n * 100:.2f} %")
    if o.outline and fighter.any():
        ink = np.zeros((H, W), bool)
        for t in ("101018", "4A5062", "3A1E1A"):
            ink |= np.abs(img - hexrgb(t)).max(-1) <= 24
        ink &= fighter
        near = ink.copy()                               # ink within 2 px (a 5x5 window)
        pad = np.pad(ink, 2)
        for dy in range(5):
            for dx in range(5): near |= pad[dy:dy + H, dx:dx + W]
        out = ~fighter
        edge = fighter & (np.roll(out, 1, 0) | np.roll(out, -1, 0) | np.roll(out, 1, 1) | np.roll(out, -1, 1))
        edge[[0, -1], :] = False; edge[:, [0, -1]] = False
        rows = np.arange(H)[:, None] < hz
        for name, part in (("sky", edge & rows), ("ground", edge & ~rows)):
            if part.sum() < 50: print(f"n/a  outline against the {name}: {part.sum()} edge pixels"); continue
            share = (near & part).sum() / part.sum()
            txt = f"{share * 100:.1f} % of {part.sum()} edge pixels have ink within 2 px"
            check(f"continuous outline against the {name}", share >= 0.9, txt) if o.ac else print(f"outline      {name}: {txt}")
    if fighter.any():
        # interior pixels: the 3x3 neighbourhood has one colour (no edge antialiasing)
        pad = np.pad(img, ((1, 1), (1, 1), (0, 0)), mode="edge")
        same = np.ones((H, W), bool)
        for dy in (0, 1, 2):
            for dx in (0, 1, 2):
                same &= (np.abs(pad[dy:dy + H, dx:dx + W] - img).max(-1) <= 1)
        inner = fighter & same
        px = img[inner]
        print(f"fighters     {inner.sum()} interior pixels of {fighter.sum()}")
        if o.palette:
            lits = [hexrgb(h) for h in o.palette.split(",")]
            tones = lits + [shade_of(c) for c in lits]
            d = np.min([np.abs(px - t).max(-1) for t in tones], axis=0)
            share = (d <= 3).mean() if len(px) else 0
            print("             tones " + " ".join("#%02X%02X%02X" % tuple(t) for t in tones))
            if o.ac: check("2 tones per palette colour", share >= 0.95, f"{share * 100:.1f} % of interior pixels within 3 of a lit or shadow tone")
            else: print(f"             {share * 100:.1f} % of interior pixels within 3 of a lit or shadow tone")
        if o.haori:
            t = hexrgb(o.haori); hit = (np.abs(px - t).max(-1) <= 3).sum()
            top = px[np.argmax(luma(px))] if len(px) else t
            ok = hit > 0.002 * len(px) and luma(top) <= luma(t) + 3
            txt = f"{hit} pixels within 3 of #{o.haori}, brightest #%02X%02X%02X" % tuple(top)
            check("lit haori", ok, txt) if o.ac else print("             " + txt)
        if o.robe:
            t = hexrgb(o.robe); dark = px[luma(px) < 30]
            hit = (np.abs(dark - t).max(-1) <= 3).sum() if len(dark) else 0
            over = (dark.max(-1) > t.max() + 3).sum() if len(dark) else 0
            txt = f"{hit} pixels within 3 of #{o.robe}; {over} V0 pixels brighter than it"
            check("robe", hit > 0 and over == 0, txt) if o.ac else print("             " + txt)
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
