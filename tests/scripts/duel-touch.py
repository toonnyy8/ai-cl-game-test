#!/usr/bin/env python3
"""duel-touch.py — writes tests/scripts/duel-touch.json: ONE-HAND by touch alone at 390x844 (run.mjs --mobile):
title tap -> ONE-HAND VS CPU -> three select taps -> the intro skipped by a tap -> taps (Quick string), a rest (guard),
flicks (Step), a drag far (dash / run), rest + flick up (Hoho), flick up + lift (F), the O and L chips, the pause
chip. Hash lines (debug 2107) at the end: run it twice under --fixed-dt and they must match (the determinism gate).
  python3 tests/scripts/duel-touch.py
  node tools/run.mjs dist/duel --mobile --size 390x844 --fixed-dt 16.666667 --secs 40 --script tests/scripts/duel-touch.json
  node tools/run.mjs dist/duel --mobile --size 390x844 --fixed-dt 16.666667 --secs 19 --script tests/scripts/duel-touch-left.json"""
import json

s = []
def tap(t, x, y): s.extend([{"at": t, "touch": "start", "x": x, "y": y}, {"at": round(t + 0.05, 3), "touch": "end", "x": x, "y": y}])
def stroke(t, pts, dt=0.016, lift=True):
    """A finger down at pts[0], moved through pts every DT s, lifted at the end (or held when LIFT is False)."""
    s.append({"at": t, "touch": "start", "x": pts[0][0], "y": pts[0][1]})
    for i, (x, y) in enumerate(pts[1:], 1): s.append({"at": round(t + i * dt, 3), "touch": "move", "x": x, "y": y})
    if lift: s.append({"at": round(t + len(pts) * dt, 3), "touch": "end", "x": pts[-1][0], "y": pts[-1][1]})

PX, PY = 146, 697                                   # the flow pad's middle (right hand, 390 x 844)
s.append({"at": 6.9, "eval": "Module._debug_cmd(2106)"})   # any debug command turns the combat log on
tap(7.0, 195, 500)                                  # title
tap(8.0, 195, 366)                                  # MODE: ONE-HAND VS CPU (row 0)
tap(9.0, 195, 600); tap(10.0, 195, 600); tap(11.0, 195, 600)   # select: P1, P2, difficulty (the middle third)
tap(12.0, 195, 400)                                 # skip the intro
s.append({"at": 13.0, "eval": "Module._debug_cmd(2105)"})   # the CPU idles while the gestures run (on again at 30 s)
s.append({"at": 30.0, "eval": "Module._debug_cmd(2105)"})
for t in (15.0, 15.25, 15.5): tap(t, PX, PY)        # Quick x3
stroke(17.0, [(PX, PY)], lift=False); s.append({"at": 17.8, "touch": "end", "x": PX, "y": PY})   # rest: guard
stroke(19.0, [(PX, PY), (PX, PY + 12), (PX, PY + 24), (PX, PY + 40)])        # flick down: Step back
stroke(20.0, [(PX, PY), (PX - 12, PY), (PX - 24, PY), (PX - 40, PY)])        # flick left: sidestep
stroke(21.0, [(PX - 60 + 6 * i, PY) for i in range(4)] + [(PX - 60 + 30 + 6 * i, PY) for i in range(0, 24, 2)], dt=0.05, lift=False)
s.append({"at": 23.0, "touch": "end", "x": PX + 60, "y": PY})                   # drag far right: dash / run
stroke(24.0, [(PX, PY)], lift=False)                                           # rest, then flick up: Hoho
for i, dy in enumerate((12, 24, 40)): s.append({"at": round(24.4 + 0.016 * i, 3), "touch": "move", "x": PX, "y": PY - dy})
s.append({"at": 24.6, "touch": "end", "x": PX, "y": PY - 40})
stroke(26.0, [(PX, PY), (PX, PY - 12), (PX, PY - 24), (PX, PY - 40)])        # flick up + lift: F
s.append({"at": 27.5, "touch": "start", "x": 220, "y": 548}); s.append({"at": 28.2, "touch": "end", "x": 220, "y": 548})  # O held
tap(29.5, 318, 564)                                 # L
s.append({"at": 31.0, "shot": "tests/shots/mobile-battle.png"})
tap(32.0, 358, 200)                                  # the pause chip
s.append({"at": 33.0, "shot": "tests/shots/mobile-pause.png"})
tap(34.0, 195, 0.45 * 844 + 12)                     # RESUME
for t in (36.0, 39.5): s.append({"at": t, "eval": "Module._debug_cmd(2107)"})
json.dump(s, open("tests/scripts/duel-touch.json", "w"), indent=0)
print(f"tests/scripts/duel-touch.json: {len(s)} steps")

# duel-touch-left.json: HAND LEFT (the mirrored deck, saved by the page), a match, a drag held, then the phone turned
# to landscape mid-match (paused: ROTATE TO PORTRAIT) and back.
s = []
tap(7.0, 195, 500); tap(8.0, 195, 402)             # title; MODE row 1: HAND -> LEFT
tap(9.0, 195, 366)                                  # ONE-HAND VS CPU
tap(10.0, 195, 600); tap(11.0, 195, 600); tap(12.0, 195, 600); tap(13.0, 195, 400)
s.append({"at": 13.5, "eval": "Module._debug_cmd(2105)"})
PX = 390 - 146
stroke(15.0, [(PX, 697), (PX, 690), (PX, 682), (PX, 676), (PX, 670), (PX, 662)], dt=0.06, lift=False)   # a slow drag up: walk
s.append({"at": 16.2, "shot": "tests/shots/mobile-left.png"})
s.append({"at": 16.4, "touch": "end", "x": PX, "y": 662})
s.append({"at": 17.0, "size": "844x390"}); s.append({"at": 18.0, "shot": "tests/shots/mobile-rotate.png"})
s.append({"at": 18.5, "size": "390x844"})
json.dump(s, open("tests/scripts/duel-touch-left.json", "w"), indent=0)
print(f"tests/scripts/duel-touch-left.json: {len(s)} steps")
