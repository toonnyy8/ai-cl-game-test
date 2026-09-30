# SOUL DUEL headless scripts (duel/lisp/debug.lisp lists the debug commands). Run:
#   python3 tests/scripts/duel.py            (writes tests/scripts/duel-*.json)
#   node tools/run.mjs dist/duel --secs 60  --script tests/scripts/duel-cvc-yk.json   seeded CPU vs CPU -> RESULTS
#   node tools/run.mjs dist/duel --secs 1100 --script tests/scripts/duel-gate.json    20 seeds x YY/YK/KK: "duel gate" lines
#     (2113 now plays all fifteen pairings (YY YK KK RY RK RR IY IK IR II SY SK SR SS SI): better one run per pairing with
#     2125+k, k 0-14, --secs 1500, at most 4 at once on a shared machine)
#     (+ the combat log: 2107 turns it back on after the gate starts; scratchpad pt/attr.py-style analysers read it)
#   node tools/run.mjs dist/duel --secs 20  --script tests/scripts/duel-probe.json    frame probes: "duel probe ... advantage
#     A (table A)" for blocked Q1 / Q3 / F2 / Taimatsu (must be equal), then a mirror Q1 trade (same Reishi both sides)
#   node tools/run.mjs dist/duel --secs 60  --script tests/scripts/duel-keys.json     P1 keyboard: J/K/L/I/U/Space/Shift
#   node tools/run.mjs dist/duel --secs 50  --script tests/scripts/duel-extras.json   dash, Hoho swing, Burst, camera toggle
#   node tools/run.mjs dist/duel --secs 170 --script tests/scripts/duel-kikon.json    the four O modules and the O rule
#   node tools/run.mjs dist/duel --secs 50  --script tests/scripts/duel-gauges.json   guard gauge (crush, guardless) + flash-step
#   node tools/run.mjs dist/duel --secs 70  --script tests/scripts/duel-stances.json  Bankai East / West: U, L, the ward, SP1, South
#   node tools/run.mjs dist/duel --secs 90  --script tests/scripts/duel-nome.json    Nozarashi v2 cups, DRINK, rift, cash-out, West's ward
#   node tools/run.mjs dist/duel --secs 40 --fixed-dt 16.666667 --script tests/scripts/duel-strings.json   the J / K
#     strings, the latch, the O ender (shots tests/shots/duel-string-*.png)
#   node tools/run.mjs dist/duel --secs 75  --script tests/scripts/duel-perf.json     real-time CPU vs CPU: stats lines
#   node tools/run.mjs dist/duel --secs 140 --script tests/scripts/duel-shots.json    tests/shots/duel-*.png
#   node tools/run.mjs dist/duel --secs 62 --fixed-dt 16.666667 --script tests/scripts/duel-practice.json   SETTINGS +
#     PRACTICE by keyboard (--fixed-dt: on a loaded host real-time key timing drops string links)
# Determinism: run a cvc script twice (or once with turbo and once without: drop the 2102 step) and
#   diff <(grep '^duel' run1.log) <(grep '^duel' run2.log)   -> empty.
# Reference (the hidden hit-stun tolerance and the J/K cut, 2026-09-29, docs/DUEL_DESIGN.md "Hidden hit-stun tolerance",
# docs/DUEL_STRINGS.md): duel-cvc-yk.json (seed 7) ends
#   duel -> RESULTS winner P2 konpaku 0-1 ticks 10288 secs 171.5    (turbo and real time alike; also after a gate)
#   (before Kenpachi's more aggressive cup 2 / 3 CPU, 2026-09-29, docs/DUEL_NOZARASHI_V2.md: winner P1 konpaku 2-0 ticks 9636 secs 160.6)
#   (before them, the J / K strings + the Soul Break rule + the Bankai: winner P2 konpaku 0-3 ticks 7123 secs 118.7;
#   before the strings, the Bankai rework + the slower guard refill: winner P1 konpaku 2-0 ticks 7688 secs 128.1;
#   before the rework, guard v3: winner P2 konpaku 0-4 ticks 9305 secs 155.1; before guard v3, the Kenpachi batch: winner P1 konpaku 7-0 ticks 7351 secs 122.5; before the batch: winner P2 konpaku 0-3 ticks 8594 secs 143.2; before user review 3's slower cinematics: the same match with shorter cinematics, ticks 8384 secs 139.7 and ticks 8054 secs 134.2; P1 1-0 ticks 9438 secs 157.3 with the gauges and the O modules; P1 2-0 ticks 9780 secs 163.0 with the Kikon rush; P2 0-1 ticks 7298 secs 121.6 with the instant Kikon; 0-4 ticks 5857 secs 97.6 with a timed Bankai;
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
# P1 move YA-J1 YA-J2 YA-J3 (2393 puts him 2.2 m out: a string needs contact) | YA-K1 | YA-SIG | YA-BREAKER | P1 guard |
# P1 step | YA-SHIRANUI | P1 hoho | YA-TAIMATSU
ev = [cmd(T0, 2500)]
t = T0 + 1.2
ev += [key(t, "KeyW"), key(t + 1.8, "KeyW", False)]; t += 2.1               # walk in (VS CPU: the behind camera, W = at him)
ev.append(cmd(t - 0.2, 2393))                                               # 2.2 m apart: the string makes contact
for k in ("KeyJ", "KeyJ", "KeyJ"): ev += tap(t, k); t += 0.3              # J J J (each latched during the link before)
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

# The Bankai stances by keyboard (debug 2370+k: human P1, P2's CPU off; the side camera; docs/DUEL_YAMA_REWORK.md).
# Expected log lines:
#   0 East vs an idle Kenpachi 3 m: L "P1 move YA-E-KYOKKO", "P1 YA-E-KYOKKO -> P2 HIT 85" (the log shows the base: 162 dealt at a full gauge, x(1 + 0.9));
#     U held: "P1 form BANKAI-WEST"; L: "P1 move YA-W-SHONETSU" (he stays West), the pillars; J: "P1 form BANKAI-EAST",
#     "P1 move YA-E-Q1" (the drop on frame 0)
#   1 East J strings into a guard the probe keeps full: "-> P2 BLOCKED", P2's r falls by the pierce's chip (34 x 0.45 =
#     15 for E-Q1 at a full gauge, 57 a string), the probe's "P1 gg" stays 100 (no recoil any more)
#   2 West's ward under Kenpachi's Quick mash (no U): "P2 KE-Q1 -> P1 BLOCKED", P1 never in blockstun (no GUARD-HIT),
#     the probe's "P1 gg" falls 31 per string (28 x1.1) and never refills, "P1 GUARDLESS", "P1 WARD BROKEN", "P1 form BANKAI-EAST"
#     on the 4th string (GUARD CRUSH), then "P2 KE-Q1 -> P1 HIT"
#   9 West's ward vs ranged hits (the :ranged probe, P2 a cup-3 Kenpachi 4.8 m away): the rifts, the cash-out and the
#     Meteor "-> P1 BLOCKED" (the ward covers them; the cash-out breaks it within 6 m: GUARD-BREAK, "WARD BROKEN")
#   3 East Shift+K into a guard at 2 m: "P1 YA-KYOKU -> P2 GUARD-BREAK 90", then "P1 YA-KYOKU -> P2 HIT 130" (x1.5)
#   4 the same at 6 m: "P1 YA-KYOKU -> P2 BLOCKED 130" only (the cone never breaks guard; its pierce chips 65)
#   5 West Shift+K (Kenpachi's F1 on its way; P1's gauge at 40): "P2 KE-F1 -> P1 PARRIED 70", "P2 scorched 15", the
#     gauge full again ("g100" in the 2107 line), "P1 move YA-W-COUNTER", "P1 YA-W-COUNTER -> P2 HIT 150", still West
#   6 East Shift+L on an idle Kenpachi at 3 m, then J J J: "P1 BIND -> P2 HIT 40", "P1 YA-E-Q1 -> P2 HIT 34", ...
#   7 human Kenpachi under the CPU's South: "P2 BIND -> P1 HIT 40", Shift+J: "P1 BURST"
#   8 the same in 0.25x slow motion, a sideways Step in the tell: no "BIND ->" line (it grabs the air)
# Shots: tests/shots/duel-yama-*.png (kyokko: the ray, west-ward: the ward, shonetsu: the pillar ring, ward-block: the
#   ward under the mash, ward-crush: broken back to East), tests/shots/duel-stance-*.png (east-idle, kyoku-*, parry /
#   counter, south-*)
def yshot(t, n): return {"at": round(t, 2), "shot": f"tests/shots/duel-yama-{n}.png"}
t = T0
ev = [cmd(t - 0.5, 2109)]
ev += [cmd(t, 2370), shot(t + 0.3, "stance-east-idle")] + tap(t + 0.5, "KeyL") + [yshot(t + 0.78, "kyokko")]
ev += [cmd(t + 2.0, 2370), key(t + 2.3, "KeyU"), key(t + 2.6, "KeyU", False), yshot(t + 2.75, "west-ward")]
ev += tap(t + 3.2, "KeyL", 0.15) + [yshot(t + 3.75, "shonetsu")] + tap(t + 4.6, "KeyJ", 0.15) + [cmd(t + 5.5, 2107)]
t += 6.0
ev += [cmd(t, 2371)]
for i in range(40): ev += tap(t + 0.4 + 0.15 * i, "KeyJ", 0.05)
ev += [cmd(t + 8.0, 2107)]
t += 9.0
ev += [cmd(t, 2372), yshot(t + 1.5, "ward-block"), yshot(t + 9.5, "ward-crush"), cmd(t + 16.0, 2107)]
t += 17.0
ev += [cmd(t, 2379), key(t + 1.6, "KeyU"), key(t + 3.3, "KeyU", False)] + tap(t + 5.9, "KeyJ") + [cmd(t + 10.0, 2107)]
t += 10.5
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

# Nozarashi v2 (the NOME ladder) and West's ward by keyboard (debug 2380+k: human P1, P2's CPU off; the side
# camera). Expected log lines:
#   0 the ladder: "duel probe nome t=... m.. FORM" every 30 steps: m 38 -> 50 (form RYOTE from m >= 40), ... 100
#     (NOMIHOSE), then draining 10/s: under 50 RYOTE, 1.5/s after 180 f (guard v3): under 25 NOZARASHI ("P1 form ..." lines too)
#   1 DRINK (cup 3, U held; Bankai East mashes Quick): "P2 YA-E-Q1 -> P1 BLOCKED 34" then "P1 DRINK 17 (+17 drunk)"
#     plus the pierce's chip (x0.5 at a full gauge: 17), the probe's "m" rising and "gg" falling, "P1 GUARD CRUSH (drinking)"
#   2 K into a guard: "P1 KE-N-F1 -> P2 BLOCKED 90", then 20 f later "P1 RIFT -> P2 BLOCKED 50"
#   3 K K on a standing Yamamoto: "KE-N-F1 -> P2 HIT 90", "RIFT -> P2 HIT 50", "KE-R-F2 -> P2 HIT 110" (x1.2 = 300)
#   4 the cash-out: "P1 move KE-METEOR-N", "P1 CASH-OUT", "P1 form NOZARASHI", "KE-METEOR-N -> P2 GUARD-BREAK 390",
#     then O: "P1 move KE-KIKON-N", "KIKON FOLLOW-UP on P2 (red)", "KIKON on P2: -2 konpaku" (cup 1: 2)
#   5 West's ward under RYOTE's K K: "P2 KE-R-F1 -> P1 BLOCKED 85", the probe's "P1 gg" falls 53 per string (the cut x1.1),
#     GUARD CRUSH on the 2nd and "P1 form BANKAI-EAST"
# Shots: tests/shots/duel-nome-*.png (drink, rift, rift-cut, cashout)
t = T0
ev = [cmd(t - 0.5, 2109), cmd(t, 2380), cmd(t + 30.5, 2107)]
t += 31.0
ev += [cmd(t, 2381), key(t + 0.1, "KeyU"), shot(t + 2.0, "nome-drink"), key(t + 14.0, "KeyU", False), cmd(t + 14.5, 2107)]
t += 15.0
ev += [cmd(t, 2382)] + tap(t + 0.5, "KeyK") + [shot(t + 0.9, "nome-rift"), shot(t + 1.18, "nome-rift-cut"), cmd(t + 2.5, 2107)]
t += 3.0
ev += [cmd(t, 2383)] + tap(t + 0.5, "KeyK") + tap(t + 0.85, "KeyK") + [cmd(t + 3.0, 2107)]
t += 3.5
ev += [cmd(t, 2384), key(t + 0.5, "ShiftLeft"), key(t + 0.55, "KeyK"), key(t + 0.65, "KeyK", False), key(t + 0.7, "ShiftLeft", False),
       shot(t + 1.0, "nome-cashout"), key(t + 1.05, "KeyO"), key(t + 4.0, "KeyO", False), cmd(t + 9.0, 2107)]
t += 10.0
ev += [cmd(t, 2385), cmd(t + 15.5, 2107)]
write("nome", ev)

# The J / K strings and the O ender (docs/DUEL_STRINGS.md; debug 2394+k: human P1 2.2 m from an idle Kenpachi, k 0 Shikai,
# 1 Bankai East, 2 Kenpachi, 3 RYOTE). Expected log lines: P1 move YA-J1 YA-J2 YA-J3, then YA-KIKON (O-ENDER) -> P2 HIT
# (no aura: the strike at once); YA-E-K1 YA-E-K2 YA-E-K3; KE-J1 KE-K2S KE-K3 + KE-KIKON; KE-R-J1 KE-R-J2 KE-R-J3;
# KE-R-K1 KE-R-K2 KE-R-J3; and J K J: KE-J1 KE-K2S, the third press eaten (the string ends: no KE-J3).
# Shots: string-o-ender (Shikai's ENJO off J3), string-sodebi (J3, the sleeve lit), string-rakujitsu, string-kick,
# string-tsuki.
t = T0
ev = []
def string(k, keys, shots=()):
    """Form K (2394+k), then KEYS ((key, s after the first) ...) tapped, SHOTS ((s, name) ...)."""
    global t
    ev.append(cmd(t, 2394 + k)); t0 = t + 1.0
    for key_, w in keys: ev.extend(tap(t0 + w, key_, 0.05))
    for w, n in shots: ev.append(shot(t0 + w, n))
    t = t0 + 3.0
string(0, (("KeyJ", 0), ("KeyJ", 0.15), ("KeyJ", 0.4), ("KeyO", 0.75)), ((0.68, "string-sodebi"), (1.08, "string-o-ender")))
string(1, (("KeyK", 0), ("KeyK", 0.2), ("KeyK", 0.6)), ((1.15, "string-rakujitsu"),))
string(2, (("KeyJ", 0), ("KeyK", 0.1), ("KeyK", 0.35), ("KeyO", 1.0)))
string(3, (("KeyJ", 0), ("KeyJ", 0.15), ("KeyJ", 0.4)))
string(3, (("KeyK", 0), ("KeyK", 0.25), ("KeyJ", 0.8)), ((0.76, "string-tsuki"),))
string(2, (("KeyJ", 0), ("KeyJ", 0.12), ("KeyJ", 0.35)), ((0.61, "string-kick"),))
string(2, (("KeyJ", 0), ("KeyK", 0.12), ("KeyJ", 0.4)))
ev.append(cmd(t, 2107))
write("strings", ev)

# the menus by keyboard: TITLE -> MODE (VS PLAYER) -> SELECT (P1 Kenpachi, P2 confirms with KP1) -> INTRO
# -> skip (Esc) -> BATTLE -> pause (Esc) -> RESUME -> pause -> CHARACTER SELECT -> back ... -> TITLE;
# then VS CPU HARD. Expected "duel -> STATE" lines in that order.
t = T0
ev = tap(t, "Enter") + tap(t + 0.4, "ArrowDown") + tap(t + 0.6, "ArrowDown") + tap(t + 0.8, "ArrowDown") + tap(t + 1.0, "Enter")   # VS PLAYER (row 3)
ev += tap(t + 1.6, "KeyD") + tap(t + 2.0, "Enter") + tap(t + 2.4, "Numpad1")      # P1 Kenpachi, P2 confirms
ev += tap(t + 4.0, "Escape") + tap(t + 6.0, "Escape") + tap(t + 6.6, "Enter")     # skip intro, pause, resume
ev += tap(t + 8.0, "Escape") + tap(t + 8.4, "ArrowDown") + tap(t + 8.8, "ArrowDown") + tap(t + 9.2, "Enter")  # -> select
ev += tap(t + 10.0, "Escape") + tap(t + 10.5, "Escape")                            # select -> mode -> title
ev += tap(t + 11.5, "Enter") + tap(t + 12.0, "Enter") + tap(t + 12.6, "Enter") + tap(t + 13.0, "Enter")
ev += tap(t + 13.4, "KeyD") + tap(t + 14.2, "Enter")                             # VS CPU, HARD
ev += [shot(t + 21, "flow-vs-cpu-hard")]
write("flow", ev)

# SETTINGS and PRACTICE by keyboard (the MODE menu since ENDLESS, 2026-09-29: VS CPU / ENDLESS / PRACTICE / VS PLAYER /
# CPU VS CPU / SETTINGS / CONTROLS). Expected, in order: duel -> SETTINGS, duel setting HAND LEFT, ... HAND RIGHT, duel setting CAMERA SIDE,
# duel camera CAMERA  SIDE (the pause menu flips it back: BEHIND), duel -> MODE, duel -> SELECT, the match seed line with
# PRACTICE, duel -> BATTLE; J J J on the standing dummy: YA-J1 / J2 / J3 -> P2 HIT (the dump after it: P2 r1300, the
# HP refilled); duel practice DUMMY  GUARD ALL, then J1 / J2 -> P2 BLOCKED; DUMMY  GUARD AFTER HIT: J1 -> HIT, then a J1
# 0.5 s later -> BLOCKED; GAUGES  INFINITE (the dump: P1 a300 f100 w100); the HP / KONPAKU rows (P1 r650 k4, P2 r325
# k8, again after a hit and after duel practice reset). No RESULTS line.
# Shots: practice-mode, practice-settings, practice-combo (the counter stays up), practice-pause.
t = T0                                   # (a shot stalls the page ~0.5 s: no key within 1 s after one)
ev = tap(t, "Enter") + [shot(t + 0.8, "practice-mode")]                           # TITLE -> MODE
t += 2.0
for i in range(5): ev += tap(t + 0.2 * i, "ArrowDown")                             # SETTINGS (row 5)
ev += tap(t + 1.2, "Enter") + [shot(t + 1.8, "practice-settings")]
t += 3.0
ev += tap(t, "ArrowDown") + tap(t + 0.3, "ArrowRight") + tap(t + 0.6, "ArrowLeft")   # HAND LEFT, back to RIGHT
for i in range(3): ev += tap(t + 0.9 + 0.25 * i, "ArrowDown")                      # CAMERA
ev += tap(t + 1.8, "ArrowRight") + tap(t + 2.2, "Escape")                          # SIDE; back to MODE (cursor on SETTINGS)
for i in range(3): ev += tap(t + 2.6 + 0.25 * i, "ArrowUp")                        # PRACTICE (row 2)
ev += tap(t + 3.6, "Enter") + tap(t + 4.1, "Enter") + tap(t + 4.6, "Enter") + tap(t + 5.1, "Enter")   # P1, P2, CPU
ev += tap(t + 6.6, "Escape")                                                       # skip the intro
t += 8.5
ev += [cmd(t, 2393)] + tap(t + 0.5, "KeyJ", 0.05) + tap(t + 0.62, "KeyJ", 0.05) + tap(t + 0.9, "KeyJ", 0.05)   # J J J on STAND
ev += [shot(t + 1.6, "practice-combo"), cmd(t + 3.0, 2107)]
t += 3.5
ev += tap(t, "Escape") + [shot(t + 0.6, "practice-pause")]
t += 1.6
ev += tap(t, "ArrowDown") + tap(t + 0.25, "ArrowDown") + tap(t + 0.5, "ArrowRight")    # DUMMY -> GUARD ALL
ev += tap(t + 1.0, "Escape") + [cmd(t + 1.5, 2393)] + tap(t + 2.0, "KeyJ", 0.05) + tap(t + 2.12, "KeyJ", 0.05) + tap(t + 2.4, "KeyJ", 0.05)
t += 4.0
ev += tap(t, "Escape") + tap(t + 0.5, "ArrowDown") + tap(t + 0.75, "ArrowDown") + tap(t + 1.0, "ArrowRight")   # AFTER HIT
ev += tap(t + 1.5, "Escape") + [cmd(t + 2.0, 2393)] + tap(t + 2.5, "KeyJ") + tap(t + 3.3, "KeyJ")
t += 5.0
ev += tap(t, "Escape")                                                             # GAUGES -> INFINITE, CAMERA -> BEHIND
for i in range(4): ev += tap(t + 0.4 + 0.25 * i, "ArrowDown")
ev += tap(t + 1.6, "Enter")
for i in range(7): ev += tap(t + 2.0 + 0.2 * i, "ArrowDown")                      # CAMERA (row 11)
ev += tap(t + 3.6, "Enter") + tap(t + 4.1, "Escape") + [cmd(t + 5.0, 2107)]
t += 5.5
# the HP / KONPAKU rows (the user's request 2026-09-28): P1 HP 100 -> 50 %, P1 KONPAKU 9 -> 4, DUMMY HP -> 25 %,
# DUMMY KONPAKU 9 -> 8; the dump: P1 r650 k4 (INFINITE holds his Reishi at his row), P2 r325 k8
ev += tap(t, "Escape")
for i in range(5): ev += tap(t + 0.4 + 0.2 * i, "ArrowDown")                       # P1 HP (row 5)
ev += tap(t + 1.6, "ArrowRight") + tap(t + 1.8, "ArrowRight") + tap(t + 2.1, "ArrowDown")
for i in range(5): ev += tap(t + 2.4 + 0.2 * i, "ArrowLeft")                       # P1 KONPAKU 4
ev += tap(t + 3.6, "ArrowDown")
for i in range(3): ev += tap(t + 3.9 + 0.2 * i, "ArrowRight")                      # DUMMY HP 25 %
ev += tap(t + 4.7, "ArrowDown") + tap(t + 5.0, "ArrowLeft")                         # DUMMY KONPAKU 8
ev += [shot(t + 5.6, "practice-pause-rows")] + tap(t + 6.6, "Escape") + [cmd(t + 7.0, 2107)]
t += 7.5
ev += [cmd(t, 2393)] + tap(t + 0.5, "KeyJ", 0.05) + [cmd(t + 2.5, 2107)]            # a hit, then refilled to 25 %
t += 3.0
ev += tap(t, "Escape") + tap(t + 0.4, "ArrowDown") + tap(t + 0.8, "Enter") + [cmd(t + 2.0, 2107)]   # RESET POSITION: the rows again
write("practice", ev)

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

# Kenpachi's Bankai (docs/DUEL_KEN_BANKAI.md; run with --fixed-dt 16.666667 --secs 60). Expected log lines, in order:
# "P1 BANKAI (konpaku -> 1, -8)" and the dump "... BANKAI r1300 k1 ... m4 u0" (P from cup 3 + red: Konpaku 1, Reishi
# full, 4 pips); "UDE -KE-B-K1 3 left", "-KE-B-K2 2 left", "-KE-B-K3 1 left" (KKK, a pip each); the bite
# "KE-B-BITE -> P2 HIT"; with 1 pip "UDE -KE-B-K1 0 left" then "ARM BURST" only after K1's recovery; 片腕 J "KE-J1".
# Shots: tests/shots/duel-ken-bankai-*.png (the stance, the bite, TATE-GOTO, the burst, 片腕, the cinematics' key frames).
def bshot(t, n): return {"at": round(t, 2), "shot": f"tests/shots/duel-ken-bankai-{n}.png"}
t = T0
ev = [cmd(t, 2386)]; ev += tap(t + 1.0, "KeyP"); ev += [cmd(t + 5.0, 2107)]; t += 5.5   # P: the Bankai (its cinematic plays)
ev += [cmd(t, 2109), cmd(t + 0.1, 2387), bshot(t + 1.2, "stance")]; t += 1.6             # the side camera from here
for k in ("KeyK", "KeyK", "KeyK"): ev += tap(t, k); t += 0.35                            # KKK: three pips
t += 1.5; ev += [cmd(t, 2107)]; t += 0.3
ev += [cmd(t, 2387)]; ev += tap(t + 0.5, "KeyL"); ev += [bshot(t + 0.5 + 0.17, "bite"), bshot(t + 0.5 + 0.35, "bite-b")]; t += 2.0
ev += [cmd(t, 2387), cmd(t + 0.05, 2108)]
ev += [key(t + 0.5, "ShiftLeft"), key(t + 0.55, "KeyK"), key(t + 0.65, "KeyK", False), key(t + 0.7, "ShiftLeft", False)]
ev += [bshot(t + 0.55 + 0.42, "split"), bshot(t + 0.55 + 0.6, "split-b")]; t += 2.5
ev += [cmd(t, 2388)]; ev += tap(t + 0.5, "KeyK")                                          # the last pip: the burst after it
ev += [bshot(t + 0.5 + 0.72, "burst"), bshot(t + 0.5 + 0.85, "burst-b"), bshot(t + 0.5 + 1.2, "burst-c")]; t += 3.0
ev += [cmd(t, 2389), bshot(t + 1.0, "kataude")]; ev += tap(t + 1.2, "KeyJ"); ev += [bshot(t + 1.2 + 0.13, "kataude-j")]; t += 2.5
ev += [cmd(t, 2109)]; t += 0.3
last = 0
for k, frames in ((35000, (6, 26, 64, 92, 130, 176)), (36000, (8, 40, 74, 110, 150))):
    last = 0
    for f in frames:
        ev.append(cmd(t, k + f)); wait = (f - last) / 60.0 + (1.2 if last == 0 else 0.35)
        ev.append(bshot(t + wait, f"{'cine' if k == 35000 else 'kikon'}-{f:03d}")); t += wait + 0.1; last = f
    t += 0.5
ev.append(cmd(t, 2107))
write("bankai", ev)

# Kuchiki Rukia (docs/DUEL_RUKIA.md; run with --fixed-dt 16.666667 --secs 80, landscape, and duel-rukia-portrait.json with
# --size 390x844). The select screen (the roster cycled to her by keyboard; in portrait by a tap on the right third),
# then human P1 Rukia vs an idle Kenpachi (debug 2410+k): the Shikai (stance, TSUKISHIRO's ring and pillar, J1, K1, the
# pirouette J3, K3, HAKUREN's stabs and wave, SHIRAFUNE), -18 C (TOSHU, HYOKA, HAKKA's pillar and lane), -50 C (HYOSHIN's
# tell and quake), absolute zero (the freeze-touch on Kenpachi's J1, REIDO TOKETSU), the CRACK after a Breaker, then key
# frames of her three cinematics (40000+f 月白, 41000+f 白霞罸, 42000+f 絶対零度). Shots tests/shots/duel-rukia[-p]-*.png.
def rukia_script(tag, portrait):
    def rs(t, n): return {"at": round(t, 2), "shot": f"{SHOTS}rukia{tag}-{n}.png"}
    def stap(t, k): return [key(t, "ShiftLeft"), key(t + 0.02, k), key(t + 0.08, k, False), key(t + 0.1, "ShiftLeft", False)]
    def touch(t, x, y): return [{"at": round(t, 2), "touch": "start", "x": x, "y": y}, {"at": round(t + 0.05, 2), "touch": "end", "x": x, "y": y}]
    t = T0 - 0.5
    ev = tap(t + 0.5, "Enter") + tap(t + 1.5, "Enter")                       # title -> MODE -> VS CPU: select
    if portrait: ev += touch(t + 2.5, 350, 400) + touch(t + 3.0, 350, 400)   # the right third: next character, twice
    else: ev += tap(t + 2.5, "ArrowRight") + tap(t + 3.0, "ArrowRight")
    ev.append(rs(t + 3.8, "select")); t += 4.5
    ev += [cmd(t, 2410)] + ([] if portrait else [cmd(t + 0.1, 2109)]); t += 1.2
    ev.append(rs(t, "base-stance")); t += 0.3
    ev += tap(t, "KeyL", 0.06); ev += [rs(t + 0.3, "tsukishiro-ring"), rs(t + 0.64, "tsukishiro-pillar")]; t += 1.6
    ev += [cmd(t, 2393)]; t += 0.4
    ev += tap(t, "KeyJ", 0.06); ev.append(rs(t + 0.12, "j1")); t += 0.9
    ev += [cmd(t, 2393)]; t += 0.3
    ev += tap(t, "KeyK", 0.06); ev.append(rs(t + 0.29, "k1")); t += 1.2
    ev += [cmd(t, 2393)]; t += 0.3
    ev += tap(t, "KeyJ", 0.06) + tap(t + 0.1, "KeyJ", 0.06) + tap(t + 0.3, "KeyJ", 0.06); ev.append(rs(t + 0.5, "j3-spin")); t += 1.4
    ev += [cmd(t, 2393)]; t += 0.3
    ev += tap(t, "KeyK", 0.06) + tap(t + 0.2, "KeyK", 0.06) + tap(t + 0.55, "KeyK", 0.06); ev.append(rs(t + 0.97, "k3-drop")); t += 1.8
    ev += [cmd(t, 2410), cmd(t + 0.05, 2108)]; t += 0.4
    ev += [key(t, "ShiftLeft"), key(t + 0.02, "KeyK"), rs(t + 0.8, "hakuren-stab"), key(t + 1.1, "KeyK", False),
           key(t + 1.12, "ShiftLeft", False), rs(t + 1.45, "hakuren-wave")]; t += 2.4
    ev += [cmd(t, 2410), cmd(t + 0.05, 2108)]; t += 0.4
    ev += stap(t, "KeyL"); ev.append(rs(t + 0.3, "shirafune")); t += 1.3
    ev += [cmd(t, 2411)]; t += 1.0
    ev.append(rs(t, "m18-stance")); t += 0.2
    ev += tap(t, "KeyK", 0.06); ev.append(rs(t + 0.29, "toshu")); t += 1.2
    ev += [cmd(t, 2411)]; t += 0.3
    ev += tap(t, "KeyK", 0.06) + tap(t + 0.2, "KeyK", 0.06) + tap(t + 0.55, "KeyK", 0.06); ev.append(rs(t + 1.0, "hyoka")); t += 1.8
    ev += [cmd(t, 2411)]; t += 0.4
    ev += tap(t, "KeyO", 0.06); ev += [rs(t + 0.2, "hakka-pillar"), rs(t + 0.5, "hakka-lane")]; t += 1.6
    ev += [cmd(t, 2412)]; t += 1.0
    ev.append(rs(t, "m50-stance")); ev += tap(t + 0.1, "KeyL", 0.06); ev += [rs(t + 0.3, "hyoshin-tell"), rs(t + 0.4, "hyoshin")]; t += 1.4
    ev += [cmd(t, 2413)]; t += 0.25
    ev.append(rs(t, "zero-freeze")); t += 1.0
    ev.append(rs(t, "zero-stance")); t += 0.3
    ev += tap(t, "KeyL", 0.06); ev.append(rs(t + 0.12, "reido")); t += 1.2
    ev += [cmd(t, 2415)]; t += 1.3
    ev.append(rs(t, "crack")); t += 0.4
    if not portrait: ev.append(cmd(t, 2109)); t += 0.2
    for k, frames in ((40000, (6, 40, 84, 114, 140, 160, 176)), (41000, (6, 20, 26, 50, 100, 126, 146, 164, 186)),
                      (42000, (6, 24, 50, 80, 124))):
        last = 0
        for f in frames:
            ev.append(cmd(t, k + f)); wait = (f - last) / 60.0 + (1.2 if last == 0 else 0.35)
            ev.append(rs(t + wait, f"cine{k // 1000 - 40}-{f:03d}")); t += wait + 0.1; last = f
        t += 0.5
    ev.append(cmd(t, 2107))
    return ev
# K -> L (docs/DUEL_STRINGS.md §12; run with --fixed-dt 16.666667 --secs 60): human P1 Rukia 2.2 m from an idle Kenpachi
# (debug 2420+k, *KL-TESTS*): per form K L, K K L, K K K L. Expected "duel probe kl" lines: each L hit with P2 still in
# stun (left-before > 0, the combo count up); k 4 (-18, 10 cold): no RU-SHIMOBASHIRA; k 5 / 6 (a held guard): the L
# blocked too. Shots tests/shots/duel-kl-<form>-<n>.png (the K hit, the L's ring / disc).
def kl_script():
    t = T0; ev = []
    ev += tap(t, "Enter") + tap(t + 0.8, "Enter") + tap(t + 1.6, "ArrowRight") + tap(t + 2.0, "ArrowRight"); t += 3.5
    for k, tag in ((0, "base"), (1, "m18"), (2, "m50"), (3, "zero"), (4, "cold"), (5, "block"), (6, "block18")):
        for ks in (1, 2, 3):
            ev.append(cmd(t, 2420 + k)); t0 = t + 0.6
            for i in range(ks): ev += tap(t0 + [0, 0.2, 0.55][i], "KeyK", 0.05)
            lt = t0 + [0.12, 0.35, 1.0][ks - 1]
            ev += tap(lt, "KeyL", 0.05)
            if k < 4: ev += [shot(lt + 0.25 + 0.2 * ks, f"kl-{tag}-{ks}a"), shot(lt + 0.55 + 0.2 * ks, f"kl-{tag}-{ks}b")]
            t = t0 + 3.2
    ev.append(cmd(t, 2107))
    return ev
write("rukia-kl", kl_script())
write("rukia", rukia_script("", False))
write("rukia-portrait", rukia_script("-p", True))

# Kurosaki Ichigo (docs/DUEL_ICHIGO.md; run with --fixed-dt 16.666667 --secs 100, landscape, and duel-ichigo-portrait.json
# with --size 390x844). The select screen (the roster cycled to him), then human P1 Ichigo vs an idle Kenpachi (debug
# 74000+k, ICHIGO-TEST): the Shikai (stance, J1, K1, J3, K3, the cross KOGA, GETSUGA, JUJISHO, SOGA), KESSA (stance, J1's
# chain, K1's sweep, the giant GETSUGA and its residue, KUSARI-BIKI, KUSARI-GAKI, the parry's flare, a Step's clone and its
# slash, the KESSA lane), the catch of Kenpachi's K1 (74002, U timed), a Yamamoto wave blocked by the parry (74003), then
# key frames of his three cinematics (75000+f the Shikai Kikon, 75200+f the KESSA Kikon, 75400+f the awakening).
# Shots tests/shots/duel-ichigo[-p]-*.png (review stills).
def ichigo_script(tag, portrait):
    def rs(t, n): return {"at": round(t, 2), "shot": f"{SHOTS}ichigo{tag}-{n}.png"}
    def stap(t, k): return [key(t, "ShiftLeft"), key(t + 0.02, k), key(t + 0.08, k, False), key(t + 0.1, "ShiftLeft", False)]
    def touch(t, x, y): return [{"at": round(t, 2), "touch": "start", "x": x, "y": y}, {"at": round(t + 0.05, 2), "touch": "end", "x": x, "y": y}]
    t = T0 - 0.5
    ev = tap(t + 0.5, "Enter") + tap(t + 1.5, "Enter")
    for i in range(3):
        ev += touch(t + 2.5 + 0.5 * i, 350, 400) if portrait else tap(t + 2.5 + 0.5 * i, "ArrowRight")
    ev.append(rs(t + 4.3, "select")); t += 5.0
    ev += [cmd(t, 74000)] + ([] if portrait else [cmd(t + 0.1, 2109)]); t += 1.2
    ev.append(rs(t, "base-stance")); t += 0.3
    for keys, n, dt in ((["KeyJ"], "j1", 0.12), (["KeyK"], "k1", 0.27), (["KeyJ", "KeyJ", "KeyJ"], "j3-spin", 0.5),
                        (["KeyK", "KeyK", "KeyK"], "k3-drop", 0.97), (["KeyJ", "KeyK"], "k2s-koga", 0.52)):
        ev += [cmd(t, 2393)]; t += 0.3
        for i, k in enumerate(keys): ev += tap(t + [0, 0.12, 0.3][i], k, 0.06)
        ev.append(rs(t + dt, n)); t += 1.5
    ev += [cmd(t, 74006), cmd(t + 0.05, 2108)]; t += 0.5
    ev += tap(t, "KeyL", 0.06); ev += [rs(t + 0.3, "getsuga"), rs(t + 0.5, "getsuga-b")]; t += 1.8
    ev += [cmd(t, 74006), cmd(t + 0.05, 2108)]; t += 0.5
    ev += stap(t, "KeyK"); ev += [rs(t + 0.24, "juji-first"), rs(t + 0.45, "juji")]; t += 1.8
    ev += [cmd(t, 74000), cmd(t + 0.05, 2108)]; t += 0.5
    ev += stap(t, "KeyL"); ev += [rs(t + 0.18, "soga-dash"), rs(t + 0.33, "soga")]; t += 1.6
    ev += [cmd(t, 74001), cmd(t + 0.05, 2108)]; t += 1.2
    ev.append(rs(t, "kessa-stance")); t += 0.3
    ev += tap(t, "KeyJ", 0.06); ev.append(rs(t + 0.18, "k-j1")); t += 1.0
    ev += [cmd(t, 74001)]; t += 0.3
    ev += tap(t, "KeyK", 0.06); ev.append(rs(t + 0.35, "k-k1")); t += 1.2
    ev += [cmd(t, 74007), cmd(t + 0.05, 2108)]; t += 0.4
    ev += tap(t, "KeyL", 0.06); ev += [rs(t + 0.42, "k-giant"), rs(t + 1.3, "k-residue")]; t += 2.4
    ev += [cmd(t, 74001), cmd(t + 0.05, 2108)]; t += 0.4
    ev += stap(t, "KeyK"); ev += [rs(t + 0.3, "k-hiki"), rs(t + 0.55, "k-hiki-b")]; t += 1.6
    ev += [cmd(t, 74008), cmd(t + 0.05, 2108)]; t += 0.4
    ev += stap(t, "KeyL"); ev += [rs(t + 0.4, "k-wall"), rs(t + 1.0, "k-wall-b")]; t += 1.8
    ev += [cmd(t, 74001)]; t += 0.4
    ev += tap(t, "KeyU", 0.06); ev.append(rs(t + 0.12, "k-parry")); t += 1.0
    ev += [cmd(t, 74001)]; t += 0.4
    ev += tap(t, "Space", 0.06); ev += [rs(t + 0.2, "k-clone"), rs(t + 0.38, "k-clone-slash")]; t += 1.4
    ev += [cmd(t, 74001)]; t += 0.4
    ev += tap(t, "KeyO", 0.06); ev.append(rs(t + 0.4, "k-lane")); t += 1.4
    ev += [cmd(t, 74002)]; t += 0.12
    ev += tap(t, "KeyU", 0.06); ev += [rs(t + 0.3, "k-catch"), rs(t + 0.5, "k-yank")]; t += 1.6
    ev += [cmd(t, 74003)]; t += 0.5
    ev += tap(t + 0.35, "KeyU", 0.06); ev += [rs(t + 0.5, "k-block-wave")]; t += 2.0
    if not portrait: ev.append(cmd(t, 2109)); t += 0.2
    for k, frames in ((75000, (6, 40, 90, 116, 140, 160, 178)), (75200, (6, 30, 70, 110, 135, 160, 182)),
                      (75400, (6, 30, 60, 84, 120, 160))):
        last = 0
        for f in frames:
            ev.append(cmd(t, k + f)); wait = (f - last) / 60.0 + (1.2 if last == 0 else 0.35)
            ev.append(rs(t + wait, f"cine{(k - 75000) // 200}-{f:03d}")); t += wait + 0.1; last = f
        t += 0.5
    ev.append(cmd(t, 2107))
    return ev
write("ichigo", ichigo_script("", False))
write("ichigo-portrait", ichigo_script("-p", True))
# ENDLESS (docs/DUEL_ENDLESS.md; run with --fixed-dt 16.666667 --secs 110): a menu run, so it writes the record.
# Landscape by keyboard: MODE row 1 (ENDLESS) -> P1 Kenpachi -> START NORMAL; stage 1 cleared by debug 80980 (STAGE
# CLEAR not awakened: CONTINUE / QUIT) -> CONTINUE; stage 2: 80987 (his 5th form, KATAUDE) + the clear -> STAGE CLEAR
# awakened -> REVERT; stage 3's line "P1 form base konpaku 9 awaken 100"; 80981 (the Bankai: Konpaku 1) + the clear ->
# CONTINUE (BANKAI -> KATATE); stage 4's line "P1 form nozarashi konpaku 3 awaken 0 meter 10"; pause -> RETIRE ->
# "duel endless over stages 3 ... record T"; NEW RUN -> pause -> RETIRE -> "over stages 0 ... best 3"; then the autopilot
# once (80992: P1 Kenpachi as a HARD CPU, seed 1, CONTINUE every clear): "duel endless over" + "duel endless gate".
# Portrait (--mobile --size 390x844, duel-endless-portrait.json, --secs 60) by taps: P1 Yamamoto, stage 1 cleared,
# stage 2 in BANKAI-WEST (80985) -> REVERT, stage 3 retired from the pause chip.
# Shots tests/shots/duel-endless-*.png; python3 tests/endless-sheet.py builds the contact sheet.
def endless_script(portrait):
    tag = "-p" if portrait else ""
    def es(t, n): return {"at": round(t, 2), "shot": f"{SHOTS}endless{tag}-{n}.png"}
    def touch(t, x, y): return [{"at": round(t, 2), "touch": "start", "x": x, "y": round(y)}, {"at": round(t + 0.05, 2), "touch": "end", "x": x, "y": round(y)}]
    H, ROW = 844, 36.67                                  # portrait CSS px: a menu row is 22 s (s = 5 at DPR 3)
    def row(y0, i): return y0 * H + 12 + i * ROW         # the i-th row of a HUD-MENU starting at Y0 (fraction of h)
    t = T0; ev = [cmd(t - 0.5, 2106)]
    if portrait:
        ev += touch(t, 195, 500) + [es(t + 0.8, "mode")] + touch(t + 1.8, 195, row(0.52, 1))   # title; MODE row 1
        ev += touch(t + 3.0, 195, 600) + [es(t + 3.8, "select")] + touch(t + 4.6, 195, 600)   # P1 Yamamoto; START NORMAL
        ev += touch(t + 6.5, 195, 400)                                                         # skip the intro
    else:
        ev += tap(t, "Enter") + [es(t + 0.8, "mode")] + tap(t + 1.8, "ArrowDown") + tap(t + 2.1, "Enter")
        ev += tap(t + 3.0, "KeyD") + tap(t + 3.3, "Enter") + [es(t + 3.9, "select")] + tap(t + 4.8, "Enter")
        ev += tap(t + 6.5, "Escape")
    t += 8.0
    ev += [es(t, "hud"), cmd(t + 1.0, 80980), es(t + 6.0, "clear")]                           # stage 1 -> STAGE CLEAR
    ev += touch(t + 7.0, 195, row(0.8, 0)) if portrait else tap(t + 7.0, "Enter")              # CONTINUE
    ev += touch(t + 9.0, 195, 400) if portrait else tap(t + 9.0, "Escape")                     # skip the intro
    t += 11.0
    ev += [cmd(t, 80985 if portrait else 80987), es(t + 5.0, "clear-awakened")]              # stage 2, awakened
    ev += touch(t + 6.0, 195, row(0.8, 1)) if portrait else tap(t + 6.0, "ArrowDown") + tap(t + 6.3, "Enter")   # REVERT
    ev += touch(t + 8.0, 195, 400) if portrait else tap(t + 8.0, "Escape")
    t += 10.0
    if not portrait:
        ev += [cmd(t, 80981), cmd(t + 9.0, 80980), es(t + 14.0, "clear-bankai")] + tap(t + 15.0, "Enter")   # stage 3
        ev += tap(t + 17.0, "Escape"); t += 19.0
    ev += [es(t, "hud-4" if not portrait else "hud-3")]
    if portrait: ev += touch(t + 1.0, 358, 200) + [es(t + 1.8, "pause")] + touch(t + 2.6, 195, row(0.45, 1))   # II, RETIRE
    else: ev += tap(t + 1.0, "Escape") + [es(t + 1.8, "pause")] + tap(t + 2.6, "ArrowDown") + tap(t + 2.9, "Enter")
    ev += [es(t + 7.0, "results")]
    t += 8.0
    if not portrait:
        ev += tap(t, "Enter") + tap(t + 8.0, "Escape") + tap(t + 8.4, "ArrowDown") + tap(t + 8.7, "Enter")   # the intro ran out
        ev += [es(t + 13.0, "results-best")]; t += 14.0                                        # NEW RUN, retired: BEST 3
        ev += [cmd(t, 80992)]                                                                  # the autopilot, one run
    return ev
write("endless", endless_script(False))
write("endless-portrait", endless_script(True))
# the ENDLESS pacing check (debug 80990: every character x seeds 1-20, CONTINUE policy; 80991 for REVERT): one
# "duel endless over" line per run, then "duel endless gate P1 c policy stay runs 20 median m ..." per character
write("endless-gate", [cmd(T0, 80990)])
