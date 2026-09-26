# SOUL DUEL headless scripts (duel/lisp/debug.lisp lists the debug commands). Run:
#   python3 tests/scripts/duel.py            (writes tests/scripts/duel-*.json)
#   node tools/run.mjs dist/duel --secs 60  --script tests/scripts/duel-cvc-yk.json   seeded CPU vs CPU -> RESULTS
#   node tools/run.mjs dist/duel --secs 300 --script tests/scripts/duel-gate.json     20 seeds x YY/YK/KK: "duel gate" lines
#     (+ the combat log: 2107 turns it back on after the gate starts; scratchpad pt/attr.py-style analysers read it)
#   node tools/run.mjs dist/duel --secs 20  --script tests/scripts/duel-probe.json    frame probes: "duel probe ... advantage
#     A (table A)" for blocked Q1 / Q3 / F2 / Taimatsu (must be equal), then a mirror Q1 trade (same Reishi both sides)
#   node tools/run.mjs dist/duel --secs 60  --script tests/scripts/duel-keys.json     P1 keyboard: J/K/L/I/U/Space/Shift
#   node tools/run.mjs dist/duel --secs 50  --script tests/scripts/duel-extras.json   dash, Hoho swing, Burst, camera toggle
#   node tools/run.mjs dist/duel --secs 170 --script tests/scripts/duel-kikon.json    the four O modules and the O rule
#   node tools/run.mjs dist/duel --secs 50  --script tests/scripts/duel-gauges.json   guard gauge (crush, guardless) + flash-step
#   node tools/run.mjs dist/duel --secs 90  --script tests/scripts/duel-stances.json  Bankai East / West: L, burnout, SP1, South
#   node tools/run.mjs dist/duel --secs 75  --script tests/scripts/duel-perf.json     real-time CPU vs CPU: stats lines
#   node tools/run.mjs dist/duel --secs 140 --script tests/scripts/duel-shots.json    tests/shots/duel-*.png
# Determinism: run a cvc script twice (or once with turbo and once without: drop the 2102 step) and
#   diff <(grep '^duel' run1.log) <(grep '^duel' run2.log)   -> empty.
# Reference (the Kikon / awakening cinematics slowed, their caption close-ups held +30 f: user review 3, 2026-09-26):
# duel-cvc-yk.json (seed 7) ends
#   duel -> RESULTS winner P2 konpaku 0-3 ticks 8594 secs 143.2    (turbo and real time alike; also after a gate)
#   (before: the same match with shorter cinematics, ticks 8384 secs 139.7 and ticks 8054 secs 134.2; P1 1-0 ticks 9438 secs 157.3 with the gauges and the O modules; P1 2-0 ticks 9780 secs 163.0 with the Kikon rush; P2 0-1 ticks 7298 secs 121.6 with the instant Kikon; 0-4 ticks 5857 secs 97.6 with a timed Bankai;
#   0-7 ticks 5302 secs 88.4 before Burst and the dash)
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

# The O modules and the O rule by keyboard (debug 2330+k: P1 with module k % 4 -- 0 ENJO, 1 TENCHI, 2 CHARGE,
# 3 LEAP -- 1 m inside its reach from a Yamamoto CPU who, by k // 4: 0 stands, 1 guards, 2 stands red,
# 3 guards red, 4 plays at HARD, 5 stands in 0.1x slow motion, 6 guards once hit, 7 red and guards once hit).
# The rule (the user's, with the lead's dash-in): the strike is guardable; a hit with O held knocks him back
# and the rusher DASHES IN to the follow-up strike, the Kikon: guardable during the dash unless he is red.
# Expected log lines per step:
#   k 20..23 (slow motion, O held): "-> P2 HIT 70", "KIKON FOLLOW-UP on P2" (the dash-in), "-> P2 KIKON 70", the cinematic
#   k 4 / 5  (guarding, not red, O held): "-> P2 BLOCKED 70" and nothing more
#   k 13 / 15 (guarding RED, O held): "-> P2 BLOCKED 70", no Kikon (the first strike is always guardable)
#   k 9 / 11 (red, O held): "-> P2 HIT 70", "FOLLOW-UP", "-> P2 KIKON 70";  k 10 with O tapped: "-> P2 HIT 70" only
#   k 17 (HARD CPU, not red): the CPU guards the strike or the dash-in by its roll, or takes the Kikon
#   k 24 / 26 (not red, guards once hit): "-> P2 HIT 70", "KIKON FOLLOW-UP", then "-> P2 BLOCKED 70": no Kikon
#   k 29 / 30 (RED, guards once hit): "-> P2 HIT 70", "KIKON FOLLOW-UP", then "-> P2 KIKON 70": red can't guard it
# The script turns the CAMERA option to SIDE first (2109): the lanes and dashes read from the side.
# Shots: tests/shots/duel-o-<module>-{a,b,c,d,e}.png (the aim / aura, the dash or lane, the strike, the dash-in,
# its strike).
t = T0
ev = [cmd(t - 0.5, 2109)]
for k, name, hit in ((20, "enjo", 4.7), (21, "tenchi", 4.5), (22, "charge", 8.0), (23, "leap", 7.7)):   # hit: ~s to the strike
    ev += [cmd(t, 2330 + k), key(t + 0.2, "KeyO"), shot(t + 1.2, f"o-{name}-a"), shot(t + 2.6, f"o-{name}-b"),
           shot(t + 4.0, f"o-{name}-c"), shot(t + hit + 1.0, f"o-{name}-d"), shot(t + hit + 2.5, f"o-{name}-e"),
           key(t + 15.0, "KeyO", False)]
    t += 18.0
for k in (4, 5, 13, 15, 9, 11, 17, 24, 26, 29, 30):
    ev += [cmd(t, 2330 + k), key(t + 0.3, "KeyO"), key(t + 3.0, "KeyO", False)]
    t += 7.0
ev += [cmd(t, 2330 + 10)] + tap(t + 0.3, "KeyO", 0.1)                      # CHARGE tapped (released) on a red target: a plain hit
ev += [cmd(t + 4.0, 2107)]
write("kikon", ev)

# The two universal gauges by keyboard. Guard gauge (2327: human P1 Yamamoto holds U while Kenpachi presses
# Quick for 20 s): "P2 KE-Q* -> P1 BLOCKED" (28 per Q string) until "P1 GUARD CRUSH" on the 4th string, then
# "-> P1 HIT" lines although U is held, then "P1 GUARD BACK" 1 s + 7.1 s after the gauge emptied, then BLOCKED
# again. Flash-step (2500: P1 Yamamoto vs an idle Kenpachi): Shift+Space x4 -> three "P1 hoho" (30 each),
# the 4th refused; then 2500 again, one Hoho (70 left), 2320 + Shift+J after Kenpachi's 2nd hit -> "P1 BURST"
# (70), the hash line shows f0. Shots: gauges-drain, gauges-crush, gauges-guardless, gauges-hoho, gauges-burst.
t = T0
ev = [cmd(t, 2327), key(t + 0.2, "KeyU"), shot(t + 3.0, "gauges-drain"), shot(t + 6.0, "gauges-crush"),
      shot(t + 9.0, "gauges-guardless"), key(t + 22.0, "KeyU", False), cmd(t + 22.2, 2107)]
t += 24.0
ev += [cmd(t, 2500)]
for i in range(4):
    ev += [key(t + 1.0 + 1.8 * i, "ShiftLeft"), key(t + 1.05 + 1.8 * i, "Space"), key(t + 1.2 + 1.8 * i, "Space", False),
           key(t + 1.25 + 1.8 * i, "ShiftLeft", False)]
ev += [shot(t + 8.4, "gauges-hoho"), cmd(t + 8.5, 2107)]
t += 10.0
ev += [cmd(t, 2500), key(t + 1.0, "ShiftLeft"), key(t + 1.05, "Space"), key(t + 1.2, "Space", False), key(t + 1.25, "ShiftLeft", False)]
t += 3.0
ev += [cmd(t, 2320), key(t + 0.1, "ShiftLeft")]
for i in range(16): ev += tap(t + 0.3 + 0.12 * i, "KeyJ", 0.05)
ev += [key(t + 2.4, "ShiftLeft", False), shot(t + 2.6, "gauges-burst"), cmd(t + 2.8, 2107)]
write("gauges", ev)

# The Bankai stances by keyboard (debug 2370+k: human P1, P2's CPU off; the side camera). Expected log lines:
#   0 L switch: "P1 move YA-TO-WEST", "P1 form BANKAI-WEST"; L again at once: "P1 refused SIG: cooling N";
#     2.2 s later: "P1 move YA-TO-EAST", "P1 form BANKAI-EAST", "P1 YA-TO-EAST -> P2 HIT 90"
#   1 East J strings into a guard the probe keeps full: "-> P2 BLOCKED" (P2 r falls by the chip), the probe's
#     "P1 gg" falls 17 per string, "P1 BURNOUT RECOIL", then P2 r stays (no chip), then the guard drops: "-> P2 HIT"
#   2 West under Kenpachi's Quick mash: "P2 KE-Q1 -> P1 ARMORED", "P2 scorched 15", the probe's "P1 gg" falls 28
#     per string, "P1 BURNOUT ARMOUR", then "P2 KE-Q1 -> P1 HIT" (no armour, no scorch)
#   3 East Shift+K into a guard at 2 m: "P1 YA-KYOKU -> P2 GUARD-BREAK 90", then "P1 YA-KYOKU -> P2 HIT 130"
#   4 the same at 6 m: "P1 YA-KYOKU -> P2 BLOCKED 130" only (the cone never breaks guard)
#   5 West Shift+K (Kenpachi's F1 on its way): "P2 KE-F1 -> P1 PARRIED 70", "P2 scorched 15", "P1 move YA-W-COUNTER",
#     "P1 YA-W-COUNTER -> P2 HIT 150"
#   6 East Shift+L on an idle Kenpachi at 3 m, then J J J: "P1 BIND -> P2 HIT 40", "P1 YA-E-Q1 -> P2 HIT 34", ...
#   7 human Kenpachi under the CPU's South: "P2 BIND -> P1 HIT 40", Shift+J: "P1 BURST"
#   8 the same in 0.25x slow motion, a sideways Step in the tell: no "BIND ->" line (it grabs the air)
# Shots: tests/shots/duel-stance-*.png (east-idle, nishi / to-west / west-idle: the switch and the flame garb,
#   higashi / to-east, recoil / burnout / burnout-hit (East), armour / armour-burnout (West), kyoku-*, parry /
#   counter, south-*)
t = T0
ev = [cmd(t - 0.5, 2109)]
ev += [cmd(t, 2370), shot(t + 0.3, "stance-east-idle")] + tap(t + 0.5, "KeyL") + [shot(t + 0.8, "stance-nishi")]
ev += tap(t + 1.2, "KeyL") + [shot(t + 1.4, "stance-to-west"), shot(t + 1.9, "stance-west-idle")]   # (L again: refused)
ev += [key(t + 2.0, "KeyD"), key(t + 3.1, "KeyD", False)]                  # walk back in (the side view: D = at him)
ev += tap(t + 3.4, "KeyL") + [shot(t + 3.65, "stance-higashi"), shot(t + 3.85, "stance-to-east"), cmd(t + 5.0, 2107)]
t += 6.0
ev += [cmd(t, 2371)]
for i in range(150): ev += tap(t + 0.4 + 0.15 * i, "KeyJ", 0.05)
ev += [shot(t + 5.0, "stance-recoil"), shot(t + 10.6, "stance-burnout"), shot(t + 12.4, "stance-burnout-hit"), cmd(t + 24.0, 2107)]
t += 25.0
ev += [cmd(t, 2372), shot(t + 2.5, "stance-armour"), shot(t + 6.3, "stance-armour-burnout"), cmd(t + 16.0, 2107)]
t += 17.0
ev += [cmd(t, 2373), key(t + 0.5, "ShiftLeft"), key(t + 0.55, "KeyK"), key(t + 0.65, "KeyK", False), key(t + 0.7, "ShiftLeft", False),
       shot(t + 0.95, "stance-kyoku-break"), shot(t + 1.2, "stance-kyoku-cone")]
t += 3.0
ev += [cmd(t, 2374), key(t + 0.5, "ShiftLeft"), key(t + 0.55, "KeyK"), key(t + 0.65, "KeyK", False), key(t + 0.7, "ShiftLeft", False),
       shot(t + 1.1, "stance-kyoku-far"), cmd(t + 2.5, 2107)]
t += 3.0
ev += [cmd(t, 2375), key(t + 0.5, "ShiftLeft"), key(t + 0.55, "KeyK"), key(t + 0.65, "KeyK", False), key(t + 0.7, "ShiftLeft", False),
       shot(t + 0.95, "stance-parry"), shot(t + 1.25, "stance-counter"), cmd(t + 3.0, 2107)]
t += 4.0
ev += [cmd(t, 2376), key(t + 0.5, "ShiftLeft"), key(t + 0.55, "KeyL"), key(t + 0.65, "KeyL", False), key(t + 0.7, "ShiftLeft", False),
       shot(t + 0.95, "stance-south-tell"), shot(t + 1.4, "stance-south-bound")]
for i in range(3): ev += tap(t + 1.5 + 0.2 * i, "KeyJ", 0.05)
ev += [cmd(t + 3.0, 2107)]
t += 4.0
ev += [cmd(t, 2377), key(t + 1.3, "ShiftLeft"), key(t + 1.35, "KeyJ"), key(t + 1.45, "KeyJ", False), key(t + 1.5, "ShiftLeft", False),
       shot(t + 1.2, "stance-south-victim"), shot(t + 1.6, "stance-south-burst"), cmd(t + 3.0, 2107)]
t += 4.0
ev += [cmd(t, 2378), key(t + 1.9, "KeyD"), key(t + 1.95, "Space"), key(t + 2.05, "Space", False), key(t + 2.4, "KeyD", False),
       shot(t + 2.6, "stance-south-step"), cmd(t + 8.0, 2107)]
write("stances", ev)

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
