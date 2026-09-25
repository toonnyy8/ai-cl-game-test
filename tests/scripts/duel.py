# SOUL DUEL headless scripts (duel/lisp/debug.lisp lists the debug commands). Run:
#   python3 tests/scripts/duel.py            (writes tests/scripts/duel-*.json)
#   node tools/run.mjs dist/duel --secs 60  --script tests/scripts/duel-cvc-yk.json   seeded CPU vs CPU -> RESULTS
#   node tools/run.mjs dist/duel --secs 200 --script tests/scripts/duel-gate.json     20 seeds x YY/YK/KK: "duel gate" lines
#     (+ the combat log: 2107 turns it back on after the gate starts; scratchpad pt/attr.py-style analysers read it)
#   node tools/run.mjs dist/duel --secs 20  --script tests/scripts/duel-probe.json    frame probes: "duel probe ... advantage
#     A (table A)" for blocked Q1 / Q3 / F2 / Taimatsu (must be equal), then a mirror Q1 trade (same Reishi both sides)
#   node tools/run.mjs dist/duel --secs 60  --script tests/scripts/duel-keys.json     P1 keyboard: J/K/L/I/U/Space/Shift
#   node tools/run.mjs dist/duel --secs 50  --script tests/scripts/duel-extras.json   dash, Hoho swing, Burst, camera toggle
#   node tools/run.mjs dist/duel --secs 75  --script tests/scripts/duel-perf.json     real-time CPU vs CPU: stats lines
#   node tools/run.mjs dist/duel --secs 140 --script tests/scripts/duel-shots.json    tests/shots/duel-*.png
# Determinism: run a cvc script twice (or once with turbo and once without: drop the 2102 step) and
#   diff <(grep '^duel' run1.log) <(grep '^duel' run2.log)   -> empty.
# Reference (permanent Bankai, slow-motion clock reset per match, 2026-09-25): duel-cvc-yk.json (seed 7) ends
#   duel -> RESULTS winner P2 konpaku 0-1 ticks 7298 secs 121.6    (turbo and real time alike; also after a gate)
#   (before: 0-4 ticks 5857 secs 97.6 with Burst + dash; 0-7 ticks 5302 secs 88.4 before them)
import json
T0 = 9.0          # startup (meshes + sound synthesis) is done by then
SHOTS = "tests/shots/duel-"

def write(name, ev):
    json.dump(ev, open(f"tests/scripts/duel-{name}.json", "w"), indent=0)
    print(f"duel-{name}.json: {len(ev)} steps, last at {max(e['at'] for e in ev):.1f} s")

def cmd(t, c): return {"at": round(t, 2), "eval": f"Module._debug_cmd({c})"}
def shot(t, n): return {"at": round(t, 2), "shot": f"{SHOTS}{n}.png"}
def key(t, k, down=True): return {"at": round(t, 2), "key": k, "down": down}
def tap(t, k, hold=0.08): return [key(t, k), key(t + hold, k, False)]

# seeded CPU vs CPU, turbo (120 steps / frame), cinematics play: reaches RESULTS in a few seconds
for pair, base in (("yy", 3000), ("yk", 4000), ("kk", 5000)):
    write(f"cvc-{pair}", [cmd(T0, 2102), cmd(T0 + 0.1, base + 7)])
write("gate", [cmd(T0, 2113), cmd(T0 + 0.3, 2107)])
write("probe", [cmd(T0 + 2 * i, 2315 + i) for i in range(5)])

# P1 on the keyboard vs an idle CPU (2500: Yamamoto vs Kenpachi). Expected log lines, in order:
# P1 move YA-Q1 YA-Q2 YA-Q3 | YA-F1 YA-F2 | YA-SIG | YA-BREAKER | P1 guard | P1 step | YA-SHIRANUI | P1 hoho | YA-TAIMATSU
ev = [cmd(T0, 2500)]
t = T0 + 1.2
ev += [key(t, "KeyW"), key(t + 1.8, "KeyW", False)]; t += 2.1               # walk in (VS CPU: the behind camera, W = at him)
for k in ("KeyJ", "KeyJ", "KeyJ"): ev += tap(t, k); t += 0.3              # Q Q Q
t += 1.0
ev += tap(t, "KeyK"); ev += tap(t + 0.35, "KeyK"); t += 1.8                 # K K
ev += tap(t, "KeyL"); t += 2.0                                              # Signature (the fire wave)
ev += [key(t, "KeyI"), key(t + 0.6, "KeyI", False)]; t += 1.8               # Breaker (held)
ev += [key(t, "KeyU"), key(t + 0.8, "KeyU", False)]; t += 1.2               # Guard
ev += [key(t, "KeyA"), key(t + 0.5, "KeyA", False)] + tap(t + 0.1, "Space"); t += 1.2   # Step
ev += [cmd(t, 2108), key(t + 0.1, "ShiftLeft"), key(t + 0.15, "KeyK"), key(t + 0.9, "KeyK", False),
       key(t + 1.0, "ShiftLeft", False)]; t += 2.5                         # SP1 Shiranui (charged, 1 bar)
ev += [key(t, "ShiftLeft"), key(t + 0.05, "Space"), key(t + 0.15, "Space", False), key(t + 0.2, "ShiftLeft", False)]; t += 1.5   # Hoho
ev += [key(t, "ShiftLeft"), key(t + 0.05, "KeyL"), key(t + 0.15, "KeyL", False), key(t + 0.2, "ShiftLeft", False)]; t += 2.0   # SP2 Taimatsu
ev += [cmd(t, 2107)]
write("keys", ev)

# Burst, dash and the camera by keyboard (P1 Yamamoto vs an idle Kenpachi, VS CPU = the behind camera).
# Expected log lines, in order: P1 step, P1 dash (the run), P1 step, P1 dash, P1 run -> YA-Q1, carry ...,
# P1 hoho, KE-Q1 / KE-Q2 -> P1 HIT (the mash test 2320), P1 BURST, then "duel camera CAMERA  SIDE" (pause menu).
# Shots: extras-behind (neutral), extras-dash (running), extras-hoho-a / -b (the swing after a Hoho),
# extras-burst-a / -b (2321, the shockwave), extras-pause (the menu with CAMERA), extras-side.
t = T0
ev = [cmd(t, 2500), shot(t + 1.5, "extras-behind")]
t += 2.5
ev += [key(t, "KeyW"), key(t + 0.05, "Space"), shot(t + 1.0, "extras-dash"), key(t + 1.6, "Space", False), key(t + 1.6, "KeyW", False)]
t += 3.0
ev += [cmd(t, 2500)]; t += 1.0                                              # again: J out of the run
ev += [key(t, "KeyW"), key(t + 0.05, "Space")] + tap(t + 0.8, "KeyJ") + [key(t + 1.0, "Space", False), key(t + 1.0, "KeyW", False)]
t += 2.5
ev += [cmd(t, 2500), cmd(t + 0.5, 2108)]; t += 1.0                          # Hoho behind P2: the camera swings round
ev += [key(t, "ShiftLeft"), key(t + 0.05, "Space"), key(t + 0.3, "Space", False), key(t + 0.35, "ShiftLeft", False),
       shot(t + 0.4, "extras-hoho-a"), shot(t + 1.8, "extras-hoho-b")]
t += 3.0
ev += [cmd(t, 2320), key(t + 0.1, "ShiftLeft")]                             # Burst out of Kenpachi's string
for i in range(16): ev += tap(t + 0.3 + 0.12 * i, "KeyJ", 0.05)
ev += [key(t + 2.4, "ShiftLeft", False)]
t += 3.5
ev += [cmd(t, 2321), shot(t + 0.05, "extras-burst-a"), shot(t + 0.5, "extras-burst-b")]
t += 2.0
ev += tap(t, "Escape") + [shot(t + 0.6, "extras-pause")]                    # pause -> CAMERA (5th item) -> SIDE
for i in range(4): ev += tap(t + 1.2 + 0.3 * i, "ArrowDown")
ev += tap(t + 2.6, "Enter") + tap(t + 3.1, "Escape") + [shot(t + 4.0, "extras-side"), cmd(t + 4.5, 2107)]
write("extras", ev)

# the menus by keyboard: TITLE -> MODE (VS PLAYER) -> SELECT (P1 Kenpachi, P2 confirms with KP1) -> INTRO
# -> skip (Esc) -> BATTLE -> pause (Esc) -> RESUME -> pause -> CHARACTER SELECT -> back ... -> TITLE;
# then VS CPU HARD. Expected "duel -> STATE" lines in that order.
t = T0
ev = tap(t, "Enter") + tap(t + 0.6, "ArrowDown") + tap(t + 1.0, "Enter")         # VS PLAYER
ev += tap(t + 1.6, "KeyD") + tap(t + 2.0, "Enter") + tap(t + 2.4, "Numpad1")      # P1 Kenpachi, P2 confirms
ev += tap(t + 4.0, "Escape") + tap(t + 6.0, "Escape") + tap(t + 6.6, "Enter")     # skip intro, pause, resume
ev += tap(t + 8.0, "Escape") + tap(t + 8.4, "ArrowDown") + tap(t + 8.8, "ArrowDown") + tap(t + 9.2, "Enter")  # -> select
ev += tap(t + 10.0, "Escape") + tap(t + 10.5, "Escape")                            # select -> mode -> title
ev += tap(t + 11.5, "Enter") + tap(t + 12.0, "Enter") + tap(t + 12.6, "Enter") + tap(t + 13.0, "Enter")
ev += tap(t + 13.4, "KeyD") + tap(t + 14.2, "Enter")                             # VS CPU, HARD
ev += [shot(t + 21, "flow-vs-cpu-hard")]
write("flow", ev)

# 60 s of real-time CPU vs CPU for the stats lines (cons/frame, ms sim / queue / render, fx-dropped)
write("perf", [cmd(T0, 4003), cmd(T0 + 64, 2107)])

# screenshots
t = T0 - 0.5
ev = [shot(t, "title")]
ev += tap(t + 0.5, "Enter"); ev.append(shot(t + 1.5, "mode"))
ev += tap(t + 2.0, "Enter"); ev.append(shot(t + 3.5, "select"))
t += 4.5
def scene(c, name, wait, extra=()):
    global t
    ev.append(cmd(t, c))
    for w, n in ((wait, name),) + tuple(extra): ev.append(shot(t + w, n))
    t += max([wait] + [w for w, n in extra]) + 1.0
scene(2207, "intro", 4.5)
scene(4003, "neutral", 12.0)
scene(2309, "hit", 0.36, ((0.45, "hit-b"), (0.55, "hit-c")))
scene(2306, "guard-break", 0.62, ((0.8, "guard-break-b"),))
scene(2307, "perfect", 0.3, ((0.5, "perfect-b"),))
scene(2300, "hellfire", 0.35, ((0.6, "hellfire-b"),))
scene(2302, "fire-wave", 0.9)
scene(2301, "shiranui", 1.4)
scene(2303, "kaka", 1.4, ((1.9, "kaka-b"),))
scene(2305, "meteor", 0.6)
scene(2200, "bankai", 1.5)
scene(2203, "tenchi", 1.2)
scene(2201, "nozarashi", 1.6)
scene(2202, "kikon-jokaku", 1.9)
scene(2204, "kikon-ken", 1.9)
scene(2205, "kikon-sky", 1.2)
scene(2206, "soul-break", 1.4)
ev += [cmd(t, 2100), cmd(t + 0.1, 2101), cmd(t + 0.2, 2102), cmd(t + 0.3, 4003), cmd(t + 6.0, 2102), shot(t + 9.0, "results")]
t += 10
ev += [cmd(t, 2101), cmd(t + 0.1, 4005), {"at": t + 5, "size": "800x450"}, shot(t + 7, "hud-800x450")]
write("shots", ev)
