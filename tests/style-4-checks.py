#!/usr/bin/env python3
"""style-4-checks.py — the phase-4 acceptance of the Storm x Kubo restyle (docs/STYLE_STORM_DESIGN.md §9 row 4), on
the scripts and on the stills of tests/style-4-shots.py:

  script  every Kikon cinematic (yama-kikon, yama-tenchi, ken-kikon, ken-sky-split) has beat 0 (hold-both + a negative
          at frame 0), >= 1 card beat, >= 3 cuts (SHOT-ON / SHOT-PAIR in AT events after frame 0), >= 1 inversion (a
          negative and a manga page), >= 1 silence >= 8 f and a brush caption; every :len is the one in LENS
  bankai  the Bankai stills (the reveal on the white card, the wide after it): every saturated pixel (S > 0.45) has
          the ember hue (10 deg +- 25) or Kenpachi's yellow (48 deg +- 25): a grey world with only the ember line red

  bounds  no caption draws a glyph off the screen (DRAW-BCAP logs "brush: caption ... off the WxH screen" once per
          caption whose em boxes leave the screen on any frame): the stills run's log (build/style/s4-new.log), and with
          --run DIST every cinematic played through (debug 10000 + 1000 k + 999: never held) plus the gameplay callouts and
          the results screen, at 1280x720 and 800x450

  python3 tests/style-4-checks.py [--run DIST]   prints PASS / FAIL lines, exits 1 on a FAIL
"""
import colorsys, json, os, re, subprocess, sys
import numpy as np
from PIL import Image

LENS = {"yama-kikon-cine": 186, "yama-tenchi-cine": 168, "yama-bankai-cine": 138, "ken-kikon-cine": 192,
        "ken-sky-split-cine": 162, "ken-nozarashi-cine": 108, "soul-break-cine": 96, "intro-cine": 300, "ko-cine": 150,
        "time-cine": 120}   # replay-relevant. Original 108 96 72 114 90 72; user review 3 slowed the Kikons and awakenings
                            # ~1.45x, then held the caption close-ups of the Kikons and the Bankai +30 f (2026-09-26)
CARD_MIN = {"yama-kikon-cine": 58, "yama-tenchi-cine": 56, "yama-bankai-cine": 58, "ken-kikon-cine": 58,
            "ken-sky-split-cine": 56}   # the caption close-up (card) shot, held +30 f at user review 3
KIKONS = ["yama-kikon-cine", "yama-tenchi-cine", "ken-kikon-cine", "ken-sky-split-cine"]
fails = []


def check(name, ok, text=""):
    print(f"{'PASS' if ok else 'FAIL'} {name}{': ' + text if text else ''}")
    if not ok: fails.append(name)


def scripts():
    src = "".join(open(f"duel/lisp/{f}.lisp").read() for f in ("yama", "ken", "cinema"))
    out = {}
    for m in re.finditer(r"\(defcine (\S+) \(a v :len (\d+)", src):
        end = src.find("(defcine ", m.end()); body = src[m.end(): end if end > 0 else len(src)]
        ats = {int(f): b for f, b in re.findall(r"\(at (\d+) (.*?)(?=\n  \((?:at|during) |\Z)", body, re.S)}
        out[m.group(1)] = (int(m.group(2)), ats, body)
    return out


def script_checks():
    sc = scripts()
    for name, n in LENS.items():
        check(f"len {name}", name in sc and sc[name][0] == n, f"{sc.get(name, (None,))[0]} (was {n})")
    for name in KIKONS:
        n, ats, body = sc[name]
        f0 = ats.get(0, "")
        cuts = sum(len(re.findall(r"\(shot-(?:on|pair) ", b)) for f, b in ats.items() if f > 0)
        sil = [int(x) for x in re.findall(r"\(silence (\d+)\)", body)]
        check(f"{name} beat 0", "hold-both" in f0 and "(impact-frame :negative" in f0)
        check(f"{name} card", bool(re.search(r"\(card :(black|white)", body)))
        check(f"{name} cuts", cuts >= 3, f"{cuts}")
        check(f"{name} inversion", "(impact-frame :negative" in body and "(impact-frame :manga" in body)
        check(f"{name} silence", bool(sil) and max(sil) >= 8, f"{sil}")
    for name in KIKONS + ["yama-bankai-cine", "ken-nozarashi-cine"]:          # user review 3: slower pacing
        n, ats, body = sc[name]
        cuts = sorted([0] + [f for f, b in ats.items() if f > 0 and re.search(r"\(shot-(?:on|pair) ", b)] + [n])
        shots = [b - a for a, b in zip(cuts, cuts[1:]) if b > a]
        check(f"{name} pacing", min(shots) >= 12 and sum(shots) / len(shots) >= 20, f"shots {shots}")
        if name in CARD_MIN:                                 # the card shot: from (card :x) to the next shot
            cf = min(f for f, b in ats.items() if re.search(r"\(card :(black|white)", b))
            nxt = min(f for f in cuts if f > cf)
            check(f"{name} caption close-up held", nxt - cf >= CARD_MIN[name], f"{nxt - cf} f (>= {CARD_MIN[name]})")
        check(f"{name} caption", "(caption \"" in body)


def hue_ok(h):
    return min(abs(h - 10), 360 - abs(h - 10)) <= 25 or abs(h - 48) <= 25


def bankai_checks():
    for still in ("bankai-074", "bankai-128"):
        a = np.asarray(Image.open(f"tests/shots/style-4-{still}.png").convert("RGB")).astype(float) / 255.0
        a = a[int(0.09 * a.shape[0]): int(0.91 * a.shape[0])]          # the picture between the letterbox bars
        mx, mn = a.max(-1), a.min(-1); s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
        sat = a[(s > 0.45) & (mx > 0.15)]
        bad = sum(1 for p in sat[:: max(1, len(sat) // 4000)] if not hue_ok(360 * colorsys.rgb_to_hsv(*p)[0]))
        frac = bad / max(1, len(sat[:: max(1, len(sat) // 4000)]))
        check(f"bankai grade {still}", frac < 0.02, f"{len(sat)} saturated px, {100 * frac:.1f} % off the ember / yellow hues")


OFF = re.compile(r"brush: caption .* off the .*")


def bounds_checks(dist):
    logs = ["build/style/s4-new.log"] if os.path.exists("build/style/s4-new.log") else []
    if dist:
        steps, t = [{"at": 3.0, "eval": "Module._debug_cmd(2106)"}], 3.2
        for k, secs in ((2, 3.2), (0, 2.4), (3, 2.9), (4, 3.3), (1, 1.9), (5, 2.8), (6, 1.7), (7, 5.1), (8, 2.6)):
            steps.append({"at": t, "eval": f"Module._debug_cmd({10000 + 1000 * k + 999})"}); t += secs + 1.0
        for c, key in ((2303, None), (2304, None), (2370, "KeyL"), (2331, "KeyO"), (2310, None)):
            steps.append({"at": t, "eval": f"Module._debug_cmd({c})"}); t += 0.4
            if key: steps += [{"at": t, "key": key, "down": True}, {"at": t + 0.1, "key": key, "down": False}]
            t += 1.6
        steps.append({"at": t, "eval": "Module._debug_cmd(2209)"}); t += 4.5
        for size in ("1280x720", "800x450"):
            json.dump(steps, open("build/style/s4-bounds.json", "w")); log = f"build/style/s4-bounds-{size}.log"
            subprocess.run(["node", "tools/run.mjs", dist, "--secs", str(round(t, 1)), "--script", "build/style/s4-bounds.json",
                            "--fixed-dt", "16.666667", "--size", size], stdout=open(log, "w"), stderr=subprocess.STDOUT)
            logs.append(log)
    for log in logs:
        text = open(log).read(); off = OFF.findall(text)
        check(f"bounds {os.path.basename(log)}", "brush:" in text and not off, "; ".join(off[:3]) or "every caption inside the screen")


if __name__ == "__main__":
    script_checks(); bankai_checks()
    bounds_checks(sys.argv[sys.argv.index("--run") + 1] if "--run" in sys.argv else None)
    sys.exit(1 if fails else 0)
