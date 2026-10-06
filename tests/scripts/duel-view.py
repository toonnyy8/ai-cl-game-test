# SOUL DUEL art viewer scripts (tests/duel-view.lisp). Run: python3 tests/scripts/duel-view.py, then
#   node tools/run.mjs dist/duelview --secs 40  --script tests/scripts/duel-view-looks.json
#   node tools/run.mjs dist/duelview --secs 120 --script tests/scripts/duel-view-strips.json
#   node tools/run.mjs dist/duelview --secs 25  --script tests/scripts/duel-view-stage.json
#   node tools/run.mjs dist/duelview --secs 40  --script tests/scripts/duel-view-sounds.json
#   node tools/run.mjs dist/duelview --secs 20  --script tests/scripts/duel-view-strings.json   (the strings' new clips:
#     tests/shots/duel-string-*.png)
# Shots: tests/shots/duel-view-*.png. The clip indices follow the viewer's order (names sorted), which
# this script rebuilds by reading the DEFCLIP / DEFSTRIKE forms of the art files.
import json, re
T0 = 9.0                     # startup (meshes + sound synthesis) is done by then
SRC = ["duel/lisp/body.lisp", "duel/lisp/yama-art.lisp", "duel/lisp/ken-art.lisp"]
clips = set({m.group(2).upper() for f in SRC for m in re.finditer(r"^\((defclip|defstrike) :([a-z0-9-]+)", open(f).read(), re.M)}
               | {n.upper() for f in SRC for m in re.finditer(r"^\(defrun :[a-z0-9-]+ ((?::[a-z0-9-]+ ?)+)\)", open(f).read(), re.M)
                  for n in m.group(1).replace(":", "").split()})    # (DEFRUN base run skate-b slide-r slide-l)
clips |= {n.upper() for f in SRC for n in re.findall(r"^\s+'?\(\(?:([a-z0-9-]+) [\d.]+ \(\(", open(f).read(), re.M)}   # BUILD-CLIP tables
clips |= {n.upper() for f in SRC for m in re.finditer(r"for name in '\(((?::[a-z0-9-]+ ?)+)\)", open(f).read())
          for n in m.group(1).replace(":", "").split()}                  # (the oni's walk / run: ken-art.lisp)
clips = sorted(clips)

def script(name, build):
    ev, t = [], [T0]
    def cmd(c, wait=0.25): ev.append({"at": round(t[0], 2), "eval": f"Module._debug_cmd({c})"}); t[0] += wait
    def shot(n, wait=1.0): t[0] += wait; ev.append({"at": round(t[0], 2), "shot": f"tests/shots/duel-view-{n}.png"}); t[0] += 0.2
    build(cmd, shot, t)
    json.dump(ev, open(f"tests/scripts/duel-view-{name}.json", "w"), indent=0)
    print(f"duel-view-{name}.json: {len(ev)} steps, ends at {t[0]:.0f} s")

def looks(cmd, shot, t):
    for scene, who in ((0, ("yama", "ken")), (1, ("yama-bankai", "ken-nozarashi"))):
        cmd(2000 + scene)
        for i, w in enumerate(who):
            for deg, view in ((0, "front"), (90, "side"), (180, "back"), (35, "34")):
                cmd(3000 + deg); cmd(6000 + i); shot(f"{w}-{view}")
            cmd(3000); cmd(6100 + i); shot(f"{w}-face")
    cmd(2002); shot("cane-skeletons")
    cmd(2003); shot("mirror")
    cmd(2000); cmd(3035); shot("lineup")

def strips(cmd, shot, t):
    for i, n in enumerate(clips):
        cmd(1000000 + 1000 * i); shot(f"strip-{n.lower()}", 0.9)

def stage(cmd, shot, t):
    cmd(2004); shot("stage", 2.5)
    cmd(4002); shot("stage-cracks", 1.5)
    cmd(4003); cmd(2000); cmd(4000); shot("no-stage", 1.0)   # fighters only: cons/frame in the stats line
    t[0] += 4.5; cmd(4004); t[0] += 4.5                     # nothing drawn: the viewer's own baseline

def sounds(cmd, shot, t):
    for i in range(44): cmd(5000 + i, 0.8)

NEW = ("ya-sleeve", "ya-e-drop", "ke-kick", "ke-r-kote", "ke-r-tsuki")   # the strings' new clips (docs/duel/DUEL_STRINGS.md §3)

def strings(cmd, shot, t):
    # their strips (0, S, S+A, end) as tests/shots/duel-string-*.png
    for n in NEW:
        cmd(1000000 + 1000 * clips.index(n.upper()))
        t[0] += 0.9; ev_shot(n)

def script(name, build):
    ev, t = [], [T0]
    def cmd(c, wait=0.25): ev.append({"at": round(t[0], 2), "eval": f"Module._debug_cmd({c})"}); t[0] += wait
    def shot(n, wait=1.0): t[0] += wait; ev.append({"at": round(t[0], 2), "shot": f"tests/shots/duel-view-{n}.png"}); t[0] += 0.2
    global ev_shot
    ev_shot = lambda n: (ev.append({"at": round(t[0], 2), "shot": f"tests/shots/duel-string-{n}.png"}), t.__setitem__(0, t[0] + 0.2))
    build(cmd, shot, t)
    json.dump(ev, open(f"tests/scripts/duel-view-{name}.json", "w"), indent=0)
    print(f"duel-view-{name}.json: {len(ev)} steps, ends at {t[0]:.0f} s")

script("looks", looks); script("strips", strips); script("stage", stage); script("sounds", sounds); script("strings", strings)
print(len(clips), "clips:", " ".join(c.lower() for c in clips))
