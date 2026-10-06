#!/usr/bin/env python3
"""aieval.py — one character's CPU, scored (the per-character AI redesign, the user 2026-10-02; docs/duel/DUEL_AI_V2.md).

Native sim (tools/simgate.py's build of THIS checkout): character C's CPU, as its <name>.lisp now reads, against the other
four characters' CPUs as they read in the same checkout.

  python3 tools/aieval.py --char 3                 Ichigo: JSON with the parts and the score
  python3 tools/aieval.py --char 3 --seeds 6       a quicker, noisier pass

The parts:
  strength  HARD, C vs each other character in both seats (learning gate runner, plain CPUs): C's win share
  masher    HARD, the button-masher (debug habit :dumb, every character) vs C: C's win share
  signature the share of C's dealt damage (written damage of its hits, strength runs) from anything but its J / K links
  pacing    NORMAL, C vs each other character (C as P1): every match a K.O. and the median <= PACE_MAX (220 s at 20 seeds;
            the real gate, 210 s at 60 seeds, runs once at the end), else the score is 0
score = 0.6 strength + 0.2 masher + 0.2 signature   (the user's choice 2026-10-02: win rate + character colour)

Roster index C: 0 Yamamoto 1 Kenpachi 2 Rukia 3 Ichigo 4 Senjumaru. Rebuilds the native sim first when a source changed.
"""
import argparse, concurrent.futures as cf, json, os, re, statistics, subprocess, sys
sys.dont_write_bytecode = True
from simgate import ROOT, ECL, FAS, MUSLM, build

NAMES = ['YAMAMOTO', 'KENPACHI', 'RUKIA', 'ICHIGO', 'SENJUMARU']
PACE_MAX = 220.0   # a 20-seed median's ceiling here (the gate's 210 s at 60 seeds: 20-seed medians run ~10 s noisy)
LINK = re.compile(r'-[JK]\d')                    # a J / K string link's move name (YA-J1, KE-R-K2S, RU-A-K3-50 ...)


def sim(cmds, log=True):
    script = 'tools/simgate/run-log.lisp' if log else 'tools/simgate/run.lisp'
    r = subprocess.run([ECL, '--norc', '--load', script, '--', FAS] + [str(c) for c in cmds], cwd=ROOT,
                       capture_output=True, text=True, env=dict(os.environ, LD_PRELOAD=MUSLM), timeout=3600)
    return r.stdout


def matches(job):
    """One learning-gate process: P1 c1 (habit h), P2 c2, seeds 1..n at difficulty d -> per match (winner, secs, hits)."""
    c1, c2, h, n, d = job
    out = sim([30000, 31100 + n, 81000, 81020 + d, 81030, 81040, 200000 + 1000 * h + 100 * c1 + 10 * c2])
    res, hits = [], {0: [], 1: []}
    for line in out.splitlines():
        m = re.search(r'\] P([12]) (\S+) -> P[12] (HIT|COUNTER) (\d+)', line)
        if m:
            hits[int(m.group(1)) - 1].append((m.group(2), int(m.group(4))))
        m = re.search(r'duel gate row seed \d+ \S+ \S+ secs ([\d.]+) winner (\S+)', line)
        if m:
            res.append((m.group(2), float(m.group(1)), hits))
            hits = {0: [], 1: []}
    return job, res, (len(res), sum(1 for _, s, _ in res if s < 299.5))   # (a time-up runs the 300 s clock out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--char', type=int, required=True)
    ap.add_argument('--seeds', type=int, default=20)
    ap.add_argument('-j', type=int, default=8)
    a = ap.parse_args()
    build()                                       # (a no-op unless a source is newer than the build)
    c, n, others = a.char, a.seeds, [o for o in range(5) if o != a.char]
    jobs = ([('str', (c, o, 0, n, 2)) for o in others] + [('str', (o, c, 0, n, 2)) for o in others] +
            [('mash', (m, c, 6, max(4, n * 4 // 5), 2)) for m in range(5)] +
            [('pace', (c, o, 0, n, 1)) for o in others])
    won = {'str': [0, 0], 'mash': [0, 0]}
    sig = [0, 0]
    pace_ok, pace = True, {}
    with cf.ProcessPoolExecutor(a.j) as ex:
        futs = {ex.submit(matches, job): kind for kind, job in jobs}
        for fu in cf.as_completed(futs):
            kind = futs[fu]
            (c1, c2, h, nn, d), res, (nm, kos) = fu.result()
            side = 1 if kind == 'mash' else (0 if c1 == c else 1)   # C's seat (the masher is always P1, C's mirror too)
            if kind == 'pace':
                secs = sorted(s for _, s, _ in res)
                med = statistics.median(secs) if secs else 999.0
                pace[NAMES[c2]] = {'kos': kos, 'matches': nm, 'median': round(med, 1)}
                if nm == 0 or kos < nm or med > PACE_MAX:
                    pace_ok = False
                continue
            for w, _, hits in res:
                won[kind][1] += 1
                won[kind][0] += (w == ('P1' if side == 0 else 'P2'))
                if kind == 'str':
                    for name, dmg in hits[side]:
                        sig[1] += dmg
                        sig[0] += 0 if LINK.search(name) else dmg
    part = {k: (won[k][0] / won[k][1] if won[k][1] else 0.0) for k in won}
    part['signature'] = sig[0] / sig[1] if sig[1] else 0.0
    score = 0.0 if not pace_ok else 0.6 * part['str'] + 0.2 * part['mash'] + 0.2 * part['signature']
    print(json.dumps({'char': NAMES[c], 'score': round(score, 4), 'strength': round(part['str'], 3),
                      'masher': round(part['mash'], 3), 'signature': round(part['signature'], 3),
                      'pacing_ok': pace_ok, 'pacing': pace, 'matches': {k: won[k][1] for k in won}}))


if __name__ == '__main__':
    main()
