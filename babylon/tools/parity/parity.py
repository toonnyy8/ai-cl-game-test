#!/usr/bin/env python3
"""parity.py: the Babylon sim against the native Lisp, bit for bit (docs/babylon/BABYLON_PORT.md "Parity check").

Per pairing and seed it plays ONE CPU vs CPU match natively (tools/simgate/run-log.lisp, one match per ECL process: the
debug commands 30000+seed-1 31101 2125+k, a one-seed gate) and the same match in the TS sim (tools/parity/log.ts), then
compares the combat logs, hash lines and RESULTS (symbols lower-cased, cinematic lines and the hash's cooldown tail
dropped, floats as printed). One line per seed: identical, or the first differing line of each side.

  python3 babylon/tools/parity/parity.py --pairs ik,ss --seeds 1-10
  python3 babylon/tools/parity/parity.py --pairs all --seeds 1-20 --summary
  ... --lisp-root ../ai-cl-game-test   (a worktree: reuse the main checkout's build/simgate/duel.fas)
  ... --out DIR -v                     (keep both logs per seed as DIR/{lisp,ts}-<pair>-<seed>.txt; show context)
  ... --pairs ik --seeds 12 --bits 4800-5400   (bits.lisp / bits.ts: the first step in 4800-5400 whose sim stream or
                                                fighter floats differ, and which fields)
"""
import argparse, concurrent.futures as cf, os, re, subprocess, sys

BABYLON = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PAIRS = 'yy yk kk ry rk rr iy ik ir ii sy sk sr ss si'.split()   # = debug.lisp *PAIRS* (2125+k)


def norm(text):
    out = []
    for l in text.splitlines():
        l = l.strip().lower()
        if not (l.startswith('[') or l.startswith('duel hash') or 'results winner' in l) or re.search(r'\] cine(-end)?\b', l):
            continue
        out.append(re.sub(r' \| cd .*', '', l))
    return out


def seeds(s):
    out = []
    for part in s.split(','):
        lo, _, hi = part.partition('-')
        out += range(int(lo), int(hi or lo) + 1)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--pairs', default='all', help='pairing letters, e.g. ik,ss (P1 first, as the gate), or all')
    ap.add_argument('--seeds', default='1-10', help='e.g. 1-10 or 3,7,11-13')
    ap.add_argument('-j', type=int, default=12, help='parallel processes (default 12)')
    ap.add_argument('--lisp-root', default=os.path.dirname(BABYLON), help='checkout with tools/simgate (default this one)')
    ap.add_argument('--out', help='keep the logs here')
    ap.add_argument('-v', action='store_true', help='print 3 lines of context around each first divergence')
    ap.add_argument('--summary', action='store_true', help='only the per-pairing counts')
    ap.add_argument('--bits', help='LO-HI: per-step bit dumps of both sides instead; print the first differing step')
    a = ap.parse_args()
    pairs = PAIRS if a.pairs == 'all' else a.pairs.lower().split(',')
    assert all(p in PAIRS for p in pairs), f'pairings: {PAIRS}'
    sys.path.insert(0, os.path.join(a.lisp_root, 'tools'))
    import simgate                                              # ECL, FAS, MUSLM and its rebuild-when-stale build()
    simgate.ROOT, simgate.FAS = a.lisp_root, os.path.join(a.lisp_root, 'build/simgate/duel.fas')
    simgate.MUSLM = os.path.join(a.lisp_root, 'build/simgate/muslm.so')
    simgate.build()

    def lisp(p, s):
        return subprocess.run([simgate.ECL, '--norc', '--load', 'tools/simgate/run-log.lisp', '--', simgate.FAS,
                               str(30000 + s - 1), '31101', str(2125 + PAIRS.index(p))], cwd=a.lisp_root, timeout=900,
                              capture_output=True, text=True, env=dict(os.environ, LD_PRELOAD=simgate.MUSLM)).stdout

    def ts(p, s):
        return subprocess.run(['node', '--import', 'tsx', 'tools/parity/log.ts', p[0], p[1], str(s)], cwd=BABYLON,
                              timeout=900, capture_output=True, text=True).stdout

    jobs = [(p, s) for p in pairs for s in seeds(a.seeds)]
    if a.bits:
        lo, _, hi = a.bits.partition('-')
        bl = lambda p, s: subprocess.run([simgate.ECL, '--norc', '--load', os.path.join(BABYLON, 'tools/parity/bits.lisp'), '--',
                                          simgate.FAS, lo, hi, str(30000 + s - 1), '31101', str(2125 + PAIRS.index(p)), '2102'],
                                         cwd=a.lisp_root, timeout=900, capture_output=True, text=True,
                                         env=dict(os.environ, LD_PRELOAD=simgate.MUSLM)).stdout
        bt = lambda p, s: subprocess.run(['node', '--import', 'tsx', 'tools/parity/bits.ts', p[0], p[1], str(s), lo, hi],
                                         cwd=BABYLON, timeout=900, capture_output=True, text=True).stdout
        names = 'rng | state sf x y z yaw vx vy vz kbx kbz dist gg fs reiatsu awaken meter stun sx sy'.split()
        with cf.ThreadPoolExecutor(a.j) as ex:
            got = list(ex.map(lambda j: (bl(*j), bt(*j)), jobs))
        for (p, s), (l, t) in zip(jobs, got):
            l, t = ([x for x in o.splitlines() if x.startswith('B ')] for o in (l, t))
            k = next((i for i, (x, y) in enumerate(zip(l, t)) if x != y), None)
            if k is None:
                print(f'{p.upper()} {s:3d} bits identical over {len(l)} / {len(t)} steps')
                continue
            x, y = l[k].split(' | '), t[k].split(' | ')
            fields = [f'{side}:{n}' for side, (u, v) in enumerate(zip(x, y))
                      for n, uu, vv in zip(names[:1] if side == 0 else names[2:], u.split()[2:] if side == 0 else u.split(),
                                           v.split()[2:] if side == 0 else v.split()) if uu != vv]
            print(f'{p.upper()} {s:3d} step {l[k].split()[1]} differs: {" ".join(fields)}\n    L {l[k]}\n    T {t[k]}')
        return
    with cf.ThreadPoolExecutor(a.j) as ex:
        L = dict(zip(jobs, ex.map(lambda j: lisp(*j), jobs)))
        T = dict(zip(jobs, ex.map(lambda j: ts(*j), jobs)))
    same = {p: 0 for p in pairs}
    for p, s in jobs:
        if a.out:
            os.makedirs(a.out, exist_ok=True)
            for side, txt in (('lisp', L[p, s]), ('ts', T[p, s])):
                open(os.path.join(a.out, f'{side}-{p}-{s}.txt'), 'w').write(txt)
        l, t = norm(L[p, s]), norm(T[p, s])
        i = next((k for k, (x, y) in enumerate(zip(l, t)) if x != y), min(len(l), len(t)))
        if l == t and any('results winner' in x for x in l):
            same[p] += 1
            if not a.summary:
                print(f'{p.upper()} {s:3d} identical ({len(l)} lines) {l[-1]}')
            continue
        if a.summary:
            continue
        print(f'{p.upper()} {s:3d} differs at line {i + 1} of {len(l)} / {len(t)}')
        for k in range(max(0, i - 3) if a.v else i, min(i + 4 if a.v else i + 1, max(len(l), len(t)))):
            print(f'    L {l[k] if k < len(l) else "(end)"}\n    T {t[k] if k < len(t) else "(end)"}')
    for p in pairs:
        print(f'parity {p.upper()}: {same[p]} / {len(seeds(a.seeds))} identical')


if __name__ == '__main__':
    main()
