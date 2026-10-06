#!/usr/bin/env python3
"""style-3-checks.py — the spot-colour budget of docs/style/STYLE_STORM_DESIGN.md §9 row 3 on the phase-3 stills
(tests/style-3-shots.py): the share of the frame (HUD rows 0-165 left out) that is spot colour (HSV S > 0.45,
chroma > 0.25, as tools/toon_check.py), split by hue into FIRE (red-orange, 0-40 deg), REIATSU (yellow, 40-70)
and BLOOD (330-360). Neutral stills (idle, base forms: Yamamoto's blade fire and Kenpachi's base aura) must stay
<= 15 %; FIRE may dominate only in the stills of Yamamoto's moves.

  python3 tests/style-3-checks.py
"""
import colorsys, sys
import numpy as np
from PIL import Image

NEUTRAL = ["blade-fire-1", "blade-fire-side-1", "ken-aura-1", "ken-aura-side-1"]
MOVES = ["blade-fire-2", "blade-fire-side-3", "fire-wave-1", "fire-wave-2", "fire-wave-side-1", "fire-wave-side-2"]
OTHER = ["ken-aura-3", "ken-aura-side-3", "nozarashi-1", "nozarashi-side-1", "meteor-1", "buttagiru-2", "bankai-1", "bankai-side-3"]


def shares(name):
    a = np.asarray(Image.open(f"tests/shots/style-3-{name}.png").convert("RGB")).astype(float)[165:] / 255.0
    mx, mn = a.max(-1), a.min(-1)
    spot = ((mx - mn) / np.maximum(mx, 1e-6) > 0.45) & (mx - mn > 0.25)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    d = np.maximum(mx - mn, 1e-6)
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    n = spot.size
    return {"spot": spot.sum() / n * 100, "fire": (spot & (h < 40)).sum() / n * 100,
            "yellow": (spot & (h >= 40) & (h < 70)).sum() / n * 100, "blood": (spot & (h >= 330)).sum() / n * 100}


fails = 0
for group, names in (("neutral", NEUTRAL), ("Yamamoto's moves", MOVES), ("other", OTHER)):
    for nm in names:
        s = shares(nm)
        ok = group != "neutral" or s["spot"] <= 15.0
        fails += not ok
        dom = max(("fire", "yellow", "blood"), key=lambda k: s[k]) if s["spot"] > 0.05 else "-"
        print(f"{'PASS' if ok else 'FAIL'} {group:17s} {nm:18s} spot {s['spot']:5.2f} %  fire {s['fire']:5.2f}  "
              f"yellow {s['yellow']:5.2f}  blood {s['blood']:4.2f}  dominant {dom}")
sys.exit(1 if fails else 0)
