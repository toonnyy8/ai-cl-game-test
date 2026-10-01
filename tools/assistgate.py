#!/usr/bin/env python3
"""assistgate.py — ASSIST's gate (docs/DUEL_ASSIST.md): the button-masher (debug habit :dumb, P1) against a CPU (P2) on the
native sim (tools/simgate.py's build), every roster pairing, per assist setting; P1's wins per setting.

  python3 tools/assistgate.py                        settings 0 (none) 1 2 3 6 10 11, NORMAL, seeds 1-20
  python3 tools/assistgate.py --ks 0,10 --diff 2     none vs HOLD U + COMBO + BREAK against HARD

k = AUTO GUARD (0 off, 1 HOLD U, 2 ALWAYS) + 3 x AUTO COMBO + 6 x AUTO BREAK (debug 81000+k); --diff 0 EASY 1 NORMAL 2 HARD
(81020+i); --mult the assisted damage in % (81100+k). Run tools/simgate.py once first when a source changed (it rebuilds).
"""
import argparse, concurrent.futures as cf, os, subprocess, sys
sys.dont_write_bytecode = True   # (no tools/__pycache__ from the import below)
from simgate import ROOT, ECL, FAS, MUSLM

NAMES = ['YA', 'KE', 'RU', 'IC', 'SE']


def job(a):
    k, c1, c2, seeds, diff, mult = a
    r = subprocess.run([ECL, '--norc', '--load', 'tools/simgate/run.lisp', '--', FAS, '30000', str(31100 + seeds),
                        str(81000 + k), str(81020 + diff), str(81100 + mult), str(206000 + 100 * c1 + 10 * c2)],
                       cwd=ROOT, capture_output=True, text=True, env=dict(os.environ, LD_PRELOAD=MUSLM), timeout=3000)
    rows = [l for l in r.stdout.splitlines() if 'duel learn row' in l]
    return k, c1, c2, sum(' winner P1 ' in l for l in rows), len(rows), r.returncode


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ks', default='0,1,2,3,6,10,11')
    ap.add_argument('--seeds', type=int, default=20)
    ap.add_argument('--diff', type=int, default=1)
    ap.add_argument('--mult', type=int, default=80)
    ap.add_argument('--rows', action='store_true', help='a line per pairing too')
    a = ap.parse_args()
    jobs = [(int(k), c1, c2, a.seeds, a.diff, a.mult) for k in a.ks.split(',') for c1 in range(5) for c2 in range(5)]
    tot = {}
    with cf.ProcessPoolExecutor(min(16, os.cpu_count() or 1)) as ex:
        for k, c1, c2, w, n, rc in ex.map(job, jobs):
            if a.rows or rc or n != a.seeds:
                print(f'k{k} {NAMES[c1]} vs {NAMES[c2]}: P1 wins {w}/{n}' + (f' rc {rc}' if rc else ''))
            t = tot.setdefault(k, [0, 0]); t[0] += w; t[1] += n
    for k, (w, n) in tot.items():
        print(f'assist gate k{k} (guard {k % 3} combo {k // 3 % 2} break {k // 6}) diff {a.diff}: P1 wins {w}/{n} = {100 * w / max(1, n):.0f}%')


if __name__ == '__main__':
    main()
