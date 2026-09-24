# Generates the scripted headless tests in tests/scripts/*.json (keys at real-time seconds).
# Run: python3 tests/scripts/gen.py ; then node tools/run.mjs dist/game --secs N --script tests/scripts/X.json
import json
def press(ev, key, t, dur=0.06): ev += [{"at": round(t, 2), "key": key, "down": True}, {"at": round(t + dur, 2), "key": key, "down": False}]
def mash(ev, key, t0, t1, every=0.14):
    t = t0
    while t < t1: press(ev, key, t); t += every
def hold(ev, key, t0, t1): ev += [{"at": t0, "key": key, "down": True}, {"at": t1, "key": key, "down": False}]
def save(name, ev):
    for e in ev: e["at"] = round(e["at"] + 0.7, 2)      # the game is ready ~1.7 s after load
    # the game now boots to the title: debug cmd 40 switches to the training scene (idempotent)
    ev += [{"at": t, "eval": "Module._debug_cmd && Module._debug_cmd(40)"} for t in (1.5, 1.8)]
    json.dump(sorted(ev, key=lambda e: e["at"]), open(f"tests/scripts/{name}.json", "w"), indent=0)
side = lambda ev: (press(ev, "F3", 1.2, 0.1), hold(ev, "KeyW", 1.4, 1.72), hold(ev, "ArrowLeft", 1.8, 2.4))

# 1 full light string L1-L5 (mash J), shots at the end
ev = []; side(ev); mash(ev, "KeyJ", 2.6, 5.5); ev.append({"at": 4.1, "shot": "tests/shots/light-string.png"}); save("light-string", ev)
# 2 launcher: L1 -> K held (Rising Crow, auto Chase Jump at f15) -> air string -> Thunderfall
ev = []; side(ev); press(ev, "KeyJ", 2.6); hold(ev, "KeyK", 2.85, 3.6)
mash(ev, "KeyJ", 3.7, 4.3, 0.12); press(ev, "KeyK", 4.4); ev.append({"at": 4.55, "shot": "tests/shots/thunderfall.png"}); save("launcher-air", ev)
# 3 defense: dummies attack (T); guard hold, then dodges, then parry attempts (fresh Q taps)
ev = []; side(ev); press(ev, "KeyT", 2.0); hold(ev, "KeyQ", 2.6, 5.0)
ev.append({"at": 3.4, "shot": "tests/shots/guard.png"})
for i in range(8): press(ev, "ShiftLeft", 5.3 + i * 0.45)
for i in range(10): press(ev, "KeyQ", 9.0 + i * 0.4, 0.3)
ev.append({"at": 7.0, "shot": "tests/shots/dodge.png"}); save("defense", ev)
# 3b just dodge: force a slash (debug cmd 3), roll TOWARD the dummy ~0.3 s later (hit lands in dodge f1-10), J = Mirage Counter
ev = []; press(ev, "F3", 1.3, 0.1); hold(ev, "KeyW", 1.4, 1.62)
for i in range(4):
    t = 2.8 + i * 2.2
    ev.append({"at": t, "eval": "Module._debug_cmd(3)"}); hold(ev, "KeyW", t + 0.3, t + 0.5)
    press(ev, "ShiftLeft", t + 0.36 + 0.035 * i); mash(ev, "KeyJ", t + 0.6, t + 0.95, 0.1)
ev.append({"at": 3.3, "shot": "tests/shots/just-dodge.png"}); save("just-dodge", ev)
# 4 raven: build gauge on the dummies, E (Raven Burst -> form), RL string, Crimson Lance
ev = []; side(ev); mash(ev, "KeyJ", 2.6, 4.5); ev.append({"at": 4.6, "eval": "Module._debug_cmd(1)"}); press(ev, "KeyE", 4.8)
ev.append({"at": 4.95, "shot": "tests/shots/raven-burst.png"}); mash(ev, "KeyJ", 5.6, 7.0); press(ev, "KeyK", 7.3); press(ev, "KeyK", 7.8)
ev.append({"at": 7.6, "shot": "tests/shots/raven-lance.png"}); save("raven", ev)
# 5 cripple + obliterate: H1, H2 on a dummy (HW leaves it <= 30 %) -> K = Obliterate
ev = []; side(ev); press(ev, "KeyK", 2.6); press(ev, "KeyK", 3.05)
ev.append({"at": 3.6, "shot": "tests/shots/crippled.png"}); press(ev, "KeyK", 4.9); ev.append({"at": 5.12, "shot": "tests/shots/obliterate.png"}); save("obliterate", ev)
# 6 parry -> riposte: force a slash, fresh Q tap at varied offsets before the hit (~+0.52 s), then J
ev = []; press(ev, "F3", 1.3, 0.1)
for i, off in enumerate([0.38, 0.44, 0.50, 0.41, 0.47]):
    t = 2.6 + i * 2.6
    hold(ev, "KeyW", t - 0.4, t - 0.25)
    ev.append({"at": t, "eval": "Module._debug_cmd(3)"}); press(ev, "KeyQ", t + off, 0.2); mash(ev, "KeyJ", t + 0.8, t + 1.1, 0.1)
save("parry", ev)
# 7 raven break: gauge full, burst, wait for getups, walk in, force a RED windup, hit it with a Raven light
ev = []; press(ev, "F3", 1.3, 0.1); hold(ev, "KeyW", 1.4, 1.62); ev.append({"at": 2.0, "eval": "Module._debug_cmd(1)"})
press(ev, "KeyE", 2.2); hold(ev, "KeyW", 4.4, 4.75); ev.append({"at": 5.0, "eval": "Module._debug_cmd(4)"})
press(ev, "KeyJ", 5.3); ev.append({"at": 5.36, "shot": "tests/shots/red-telegraph.png"}); mash(ev, "KeyJ", 5.5, 6.2, 0.12); save("raven-break", ev)
# 8 other moves: run -> Gale Thrust, heavy string, jump -> Plunge/Kestrel, air dodge, back off -> jump -> Kestrel
ev = []; press(ev, "F3", 1.3, 0.1); hold(ev, "KeyS", 2.0, 2.5); hold(ev, "KeyW", 2.6, 3.5); press(ev, "KeyJ", 3.4)
mash(ev, "KeyK", 4.5, 6.0, 0.25); press(ev, "Space", 7.0); press(ev, "KeyK", 7.25); ev.append({"at": 7.35, "shot": "tests/shots/plunge.png"})
press(ev, "Space", 9.0); press(ev, "ShiftLeft", 9.2); hold(ev, "KeyS", 10.4, 10.8); press(ev, "Space", 11.4); press(ev, "KeyK", 11.65)
ev.append({"at": 11.8, "shot": "tests/shots/kestrel.png"}); save("moves", ev)
# 9 perf: no overlay, dummies attack (T), mash J for 11 s -> read "stats:" lines (cons/frame, ms)
ev = []; hold(ev, "KeyW", 1.4, 1.7); press(ev, "KeyT", 1.8); mash(ev, "KeyJ", 1.9, 13.0, 0.15); save("perf", ev)
