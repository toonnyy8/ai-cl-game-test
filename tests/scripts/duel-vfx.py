# SOUL DUEL VFX gallery script (tests/duel-vfx.lisp). Run: python3 tests/scripts/duel-vfx.py, then
#   node tools/run.mjs dist/duelvfx --secs 170 --script tests/scripts/duel-vfx.json
# Shots: tests/shots/duel-vfx-<scene>-<n>.png at the listed scene times: the gallery runs the scene
# clock to that time and freezes (debug 4000+ms), so a shot is deterministic up to cosmetic RNG. The stats line of the
# worst-case scene is in the console log ("stats: ... cons/frame") and on screen.
import json
T0 = 8.0                     # startup (meshes) is done by then
SCENES = [  # (index, name, shot times)
    (0, "blade-fire", [1.0, 1.6]), (1, "hellfire", [1.0, 1.7]), (2, "bankai-embers", [1.0, 1.7]),
    (3, "fire-wave", [0.3, 0.6, 0.9]), (4, "shiranui", [0.8, 1.6, 2.0]), (5, "ennetsu", [0.15, 0.45, 0.75]),
    (6, "dome", [0.5, 1.2, 1.55, 1.8, 2.1]), (7, "auras", [1.0, 1.8]), (8, "breaker", [0.5, 0.95]),
    (9, "line-cuts", [0.1, 0.35, 0.9]), (10, "sky-split", [0.05, 0.3, 0.9]), (11, "tenchi", [0.04, 0.3, 1.2]),
    (12, "soul-flame", [0.4, 1.0]), (13, "hits", [0.1, 0.5, 0.9, 1.3, 1.7, 2.1, 2.5]),
    (14, "oneshots", [0.15, 1.15, 2.15, 3.25, 3.7, 5.2, 6.2, 6.75, 6.95]), (15, "ui", [0.5]), (16, "worst", [2.5, 6.0]),
]
ev, t = [], T0
for i, name, times in SCENES:
    ev.append({"at": round(t, 2), "eval": f"Module._debug_cmd({2000 + i})"}); t += 0.1
    prev = 0.0
    for n, s in enumerate(times):
        ev.append({"at": round(t, 2), "eval": f"Module._debug_cmd({4000 + round(s * 1000)})"})
        t += (s - prev) * 1.5 + 0.7; prev = s
        ev.append({"at": round(t, 2), "shot": f"tests/shots/duel-vfx-{name}-{n}.png"}); t += 0.3
json.dump(ev, open("tests/scripts/duel-vfx.json", "w"), indent=0)
print(f"duel-vfx.json: {len(ev)} steps, ends at {t:.0f} s")
