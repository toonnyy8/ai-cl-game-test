# Enemy / game-flow headless scenarios (phase 2b). Run: python3 tests/scripts/e2.py, then e.g.
#   node tools/run.mjs dist/game --secs 30 --script tests/scripts/e2-grunt.json
# Headless SwiftShader runs the sim at ~0.5x real time, so waits below are generous.
# Debug commands (Module._debug_cmd, see DEBUG-COMMAND in game/lisp/debug.lisp): 11-13 wave N,
# 14 boss, 15 boss phase 2, 16 god, 17 kill all, 18 bot(+god), 19 boss broken, 21-32 forced
# enemy attacks, 41 player dies, 50 near-freeze now, 52/53 near-freeze at / 24 f after the next
# enemy move event (release, impact, takeoff), 51 dump the AI state.
import json
def cmd(ev, t, c): ev.append({"at": round(t, 2), "eval": f"Module._debug_cmd({c})"})
def shot(ev, t, name): ev.append({"at": round(t, 2), "shot": f"tests/shots/e2-{name}.png"})
def press(ev, key, t, dur=0.08): ev += [{"at": round(t, 2), "key": key, "down": True}, {"at": round(t + dur, 2), "key": key, "down": False}]
def hold(ev, key, t0, t1): ev += [{"at": t0, "key": key, "down": True}, {"at": t1, "key": key, "down": False}]
def save(name, ev): json.dump(sorted(ev, key=lambda e: e["at"]), open(f"tests/scripts/e2-{name}.json", "w"), indent=0)
def red(ev, t, c, name):        # force attack c, freeze during its (red) windup, screenshot
    cmd(ev, t, c); cmd(ev, t + 0.5, 50); shot(ev, t + 0.6, name)
def event(ev, t, c, name, late=0):   # force attack c, freeze 1/10/24 f after its release / impact, screenshot
    cmd(ev, t, 52 + late); cmd(ev, t + 0.05, c); shot(ev, t + 3.0, name)

# grunts: wave 1 surround, forced slash, cripple one -> crawl -> red Death Grip
ev = []; cmd(ev, 2.5, 11); cmd(ev, 3.0, 16); shot(ev, 3.5, "wave1-banner"); shot(ev, 11.0, "wave1-surround")
event(ev, 13.0, 21, "grunt-slash")
cmd(ev, 17.0, 56); cmd(ev, 17.1, 32); cmd(ev, 17.2, 56); shot(ev, 20.0, "grunt-crippled"); shot(ev, 24.5, "grunt-crawl")
for i in range(8): shot(ev, 27.0 + 1.3 * i, f"grunt-grip-{i}")
save("grunt", ev)
# off-screen attack: turn the camera away (arrows), force the nearest grunt to slash -> chevron + :warn
ev = []; cmd(ev, 2.5, 11); cmd(ev, 3.0, 16); shot(ev, 9.0, "offscreen-before"); hold(ev, "ArrowLeft", 9.5, 12.5)
cmd(ev, 12.8, 33); cmd(ev, 13.0, 50); shot(ev, 13.1, "offscreen-chevron")
save("offscreen", ev)

# needlers: wave 2, kunai fan in flight, blast kunai red windup + stuck ring
ev = []; cmd(ev, 2.5, 12); cmd(ev, 3.0, 16); shot(ev, 14.0, "wave2")
event(ev, 16.0, 22, "kunai-fan", late=1)
red(ev, 21.0, 23, "kunai-blast-windup"); cmd(ev, 26.0, 56); cmd(ev, 26.2, 55); cmd(ev, 26.3, 23); shot(ev, 31.0, "kunai-blast-ring")
save("needler", ev)

# oxhead: wave 3, red Crushing Slam (ring), Bull Charge lane, swing
ev = []; cmd(ev, 2.5, 13); cmd(ev, 3.0, 16); shot(ev, 7.0, "ox-landed"); shot(ev, 13.0, "wave3")
red(ev, 15.0, 24, "ox-slam-windup"); event(ev, 20.0, 24, "ox-slam-impact")
red(ev, 26.0, 25, "ox-charge-windup"); cmd(ev, 31.0, 51)
event(ev, 32.0, 31, "ox-swing"); save("ox", ev)

# boss: intro, crescent (red ring), blade wave, triple cut, phase 2 (roar, crimson rain), leap, broken -> bot finishes
ev = []; cmd(ev, 2.5, 14); cmd(ev, 3.0, 16); shot(ev, 4.2, "boss-drop"); shot(ev, 7.5, "boss-intro")
red(ev, 12.0, 26, "boss-crescent")
event(ev, 19.0, 28, "boss-blade-wave", late=1)
event(ev, 24.0, 30, "boss-triple")
cmd(ev, 29.0, 15); shot(ev, 29.8, "boss-phase2-a"); shot(ev, 31.0, "boss-phase2-roar"); shot(ev, 33.0, "boss-phase2-b"); shot(ev, 36.0, "boss-phase2")
red(ev, 41.0, 27, "boss-leap-windup"); event(ev, 45.0, 27, "boss-leap-air", late=2)
cmd(ev, 51.0, 19); shot(ev, 52.5, "boss-broken"); cmd(ev, 53.0, 18); shot(ev, 64.0, "victory"); shot(ev, 74.0, "results")
save("boss", ev)

# game over + retry + pause
ev = []; cmd(ev, 2.5, 11); cmd(ev, 7.0, 41); shot(ev, 13.0, "game-over"); press(ev, "Enter", 15.0); shot(ev, 17.0, "retry")
press(ev, "Escape", 19.0); shot(ev, 20.0, "pause"); press(ev, "Escape", 21.5); save("over", ev)

# full run: start from the title with Enter, then the autoplay bot (+god) to victory
ev = []; press(ev, "Enter", 8.0); cmd(ev, 10.0, 18)   # title accepts input only after startup (~5 s headless)
for i, t in enumerate(range(90, 1800, 90)): shot(ev, t, f"full-{i:02d}")
save("full", ev)

# perf: wave 3 + reinforcements with bot+god (read the "stats:" lines)
ev = []; cmd(ev, 2.5, 13); cmd(ev, 3.0, 18); save("perf", ev)
