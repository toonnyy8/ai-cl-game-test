# Polish-pass scenarios (phase 3). Run: python3 tests/scripts/p3.py, then e.g.
#   node tools/run.mjs dist/game --secs 20 --script tests/scripts/p3-crowd.json
import json
def cmd(ev, t, c): ev.append({"at": round(t, 2), "eval": f"Module._debug_cmd({c})"})
def shot(ev, t, name): ev.append({"at": round(t, 2), "shot": f"tests/shots/p3-{name}.png"})
def press(ev, key, t, dur=0.25): ev += [{"at": round(t, 2), "key": key, "down": True}, {"at": round(t + dur, 2), "key": key, "down": False}]
def save(name, ev): json.dump(sorted(ev, key=lambda e: e["at"]), open(f"tests/scripts/p3-{name}.json", "w"), indent=0)

# crowd readability: wave 3 (oxhead, grunts, needler) + the boss dropped in, god mode
ev = []; cmd(ev, 2.5, 13); cmd(ev, 3.0, 16); shot(ev, 9.0, "crowd-a"); cmd(ev, 10.0, 60); shot(ev, 14.0, "crowd-b")
save("crowd", ev)

# screens: title, controls, start, pause, boss intro (a shot stalls the script ~1 s: keep inputs clear of shots)
ev = []; shot(ev, 3.5, "title"); press(ev, "ArrowDown", 5.5); press(ev, "ArrowDown", 6.0); press(ev, "Enter", 6.5)
shot(ev, 7.5, "controls"); press(ev, "Escape", 9.0); press(ev, "ArrowUp", 9.5); press(ev, "ArrowUp", 10.0)
press(ev, "Enter", 10.5); shot(ev, 13.8, "wave1-banner"); press(ev, "Escape", 15.5); shot(ev, 16.5, "pause")
press(ev, "Escape", 18.0); cmd(ev, 18.5, 14); shot(ev, 22.8, "boss-intro")
save("screens", ev)

# soak: bot runs back to back with release logging (cmd 61), read the "soak:" heap lines
ev = []; cmd(ev, 4, 61); save("soak", ev)
