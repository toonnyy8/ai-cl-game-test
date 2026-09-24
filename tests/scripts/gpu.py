# Renderer regression scenarios (SDL_GPU / WebGPU port). Run: python3 tests/scripts/gpu.py [PREFIX], then
#   node tools/run.mjs dist/game --secs 20 --script tests/scripts/gpu-title.json   (and -wave, -boss)
# Shots go to tests/shots/PREFIX-*.png (default "gpu"). Cmd 63 lifts the frame budget so the auto
# render scale stays at 1.0 and runs are comparable across renderers / builds.
import json, sys
pre = sys.argv[1] if len(sys.argv) > 1 else "gpu"
def cmd(ev, t, c): ev.append({"at": t, "eval": f"Module._debug_cmd({c})"})
def shot(ev, t, name): ev.append({"at": t, "shot": f"tests/shots/{pre}-{name}.png"})
def save(name, ev): json.dump(sorted(ev, key=lambda e: e["at"]), open(f"tests/scripts/{pre}-{name}.json", "w"), indent=0)

ev = []; cmd(ev, 5.0, 63); shot(ev, 7.0, "title"); ev.append({"at": 8.0, "size": "800x450"})
shot(ev, 9.5, "title-800x450"); ev.append({"at": 10.5, "size": "1280x720"}); shot(ev, 12.0, "title-back")
save("title", ev)
ev = []; cmd(ev, 6.0, 63); cmd(ev, 6.5, 13); cmd(ev, 7.0, 16); cmd(ev, 7.2, 18); cmd(ev, 7.4, 62)
for i, t in enumerate([12.0, 14.0, 16.0, 18.0]): shot(ev, t, f"wave-{i}")
save("wave", ev)
ev = []; cmd(ev, 6.0, 63); cmd(ev, 6.5, 14); cmd(ev, 7.0, 16); shot(ev, 11.5, "boss-intro"); cmd(ev, 14.0, 15)
shot(ev, 15.0, "boss-phase2-a"); shot(ev, 17.0, "boss-phase2-b"); shot(ev, 20.0, "boss-phase2-c")
cmd(ev, 22.0, 19); cmd(ev, 22.5, 18); shot(ev, 36.0, "victory"); shot(ev, 46.0, "results"); shot(ev, 50.0, "results-b")
save("boss", ev)
