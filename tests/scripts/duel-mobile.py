#!/usr/bin/env python3
"""duel-mobile.py — the portrait presentation review (docs/DUEL_MOBILE_DESIGN.md P2): ONE-HAND reached by taps, then the
stills of every portrait screen (mode, gesture card, select, intro, neutral, close, far, a string + the O ender, pause,
the Kikon / Bankai / Nozarashi / Soul Break cinematics, results) and the framing / text probe lines (debug 2700).
  python3 tests/scripts/duel-mobile.py [OUTDIR [base|insets]]   writes tests/scripts/duel-mobile.json (OUTDIR default
                            tests/shots, file names mobile-*.png; "base": the pre-P2 taps; "insets": duel-mobile-insets.json,
                            an iPhone's safe area, four stills mobile-insets-*.png)
  node tools/run.mjs dist/duel --mobile --size 390x844 --fixed-dt 16.666667 --secs 48 --script tests/scripts/duel-mobile.json
Then python3 tests/mobile-sheet.py builds the contact sheet."""
import json, sys

out = sys.argv[1] if len(sys.argv) > 1 else "tests/shots"
base = len(sys.argv) > 2 and sys.argv[2] == "base"
insets = len(sys.argv) > 2 and sys.argv[2] == "insets"     # an iPhone's safe area (47 top, 34 bottom): mobile-insets-*.png
H = 844
# tap targets (CSS px at 390 x 844): the MODE rows, the pause chip, the pause menu's first row
if base: mode_y, row_h, pause, resume = 366, 36.67, (358, 200), 392
else: mode_y, row_h, pause, resume = 0.52 * H + 12, 36.67, (358, 200), 392
s = []
def ev(t, c): s.append({"at": t, "eval": f"Module._debug_cmd({c})"})
def tap(t, x, y): s.extend([{"at": t, "touch": "start", "x": x, "y": round(y)}, {"at": round(t + 0.05, 3), "touch": "end", "x": x, "y": round(y)}])
def shot(t, name): s.append({"at": t, "shot": f"{out}/mobile-{'insets-' if insets else ''}{name}.png"})
PX, PY = 146, 697
if insets: s.append({"at": 6.8, "eval": "globalThis.gamePage.testInsets = [47, 34]"})
ev(6.9, 2106)
if not base: ev(6.95, 2700)                               # the framing / text probe on
tap(7.0, 195, 500); shot(7.6, "mode")                        # title -> MODE
tap(8.0, 195, mode_y + 5 * row_h); shot(8.6, "gestures")     # CONTROLS: the gesture card
tap(9.2, 195, 600)                                           # back to MODE
tap(10.0, 195, mode_y)                                       # ONE-HAND VS CPU
shot(10.6, "select")
tap(11.0, 195, 600); tap(12.0, 195, 600); tap(13.0, 195, 600)   # P1, P2, difficulty
shot(13.9, "intro")
tap(14.5, 195, 400)                                          # skip the intro
ev(15.0, 2105)                                               # the CPU idles
shot(16.0, "neutral"); ev(16.05, 2700)
ev(16.5, 2393); shot(17.0, "close"); ev(17.05, 2700)                          # 2.2 m
for t in (17.5, 17.7, 17.95): tap(t, PX, PY)                 # J J J
shot(18.2, "string")
tap(18.35, 220, H - 396)                                     # the O ender
shot(18.75, "ender")
if not base:
    ev(20.0, 2701); shot(20.5, "far"); ev(20.55, 2700)                        # far apart (debug 2701)
    ev(21.0, 2702); shot(21.5, "side"); ev(21.55, 2700)                       # P2 flashed to P1's side (the catch-up)
    shot(21.9, "side-b")
tap(22.5, *pause); shot(23.2, "paused")
tap(24.0, 195, resume)
ev(25.0, 2394 + 1)                                           # Bankai East string test: KOSEI x2.4 on P1's panel
ev(25.1, 2105)
for t in (25.6, 25.8, 26.05): tap(t, PX, PY)
shot(26.3, "kosei")
if not base: ev(27.0, 2700)                                  # the framing / text probe line of this frame
ev(28.0, 12030); shot(29.0, "cine-kikon")                    # Jokaku Enjo: the caption on the black card
ev(29.5, 12080); shot(30.5, "cine-kikon-b")                  # its pair shot
ev(31.0, 10110); shot(32.0, "cine-bankai")                   # Bankai: 卍解 / 残火の太刀 on the white card
ev(32.5, 14030); shot(33.5, "cine-ken")                      # Ken's Kikon: the caption + chapter line
ev(34.0, 11100); shot(35.0, "cine-nozarashi")
ev(35.5, 16010); shot(36.5, "cine-soul")
ev(37.0, 2100); ev(37.1, 2100)                               # release the hold
ev(38.0, 2209); shot(46.0, "results")                        # K.O. of P2, then RESULTS
if not base: ev(46.5, 2704); ev(46.6, 2700)                  # consing; the probe's line
if insets: s = [x for x in s if "shot" not in x or any(k in x["shot"] for k in ("neutral", "kosei", "cine-kikon.png", "results"))]
name = "tests/scripts/duel-mobile" + ("-insets" if insets else "") + ".json"
json.dump(s, open(name, "w"), indent=0)
print(f"{name}: {len(s)} steps -> {out}")
