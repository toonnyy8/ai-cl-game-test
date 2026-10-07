#!/usr/bin/env python3
"""aieval.py — one character's CPU, scored (the per-character AI redesign, the user 2026-10-02; docs/duel/DUEL_AI_V2.md;
Lille Barro's adaptive CPU search, the user 2026-10-06: docs/duel/DUEL_LILLE.md §24.2).

Native sim (tools/simgate.py's build of THIS checkout): character C's CPU, as its <name>.lisp now reads, against every other
character's CPU as it reads in the same checkout.

  python3 tools/aieval.py --char 3                 Ichigo: JSON with the parts and the score
  python3 tools/aieval.py --char 3 --seeds 6       a quicker, noisier pass
  python3 tools/aieval.py --char 5 --seeds 40 -j 2 Lille, as a dream-rsi cell is scored (DUEL_LILLE §24.2)

The parts (seeds 1..N, fixed; the mirror is never played: C vs C is 0.5 by symmetry and tells nothing):
  strength  HARD, C vs each other character in both seats (learning gate runner, plain CPUs): C's win share
  masher    HARD, the button-masher (debug habit :dumb, every character, C's own included) as P1 vs C as P2: C's win share
            (N * 4 // 5 seeds each)
  signature the share of C's dealt damage (written damage of its hits, strength runs) that is the character's own:
            Yamamoto .. Senjumaru: anything but its J / K links (move names -J1 / -K2S ...);
            Lille: a WHITELIST (SIG_LILLE below, DUEL_LILLE §24.2): the materialised traces, HOSHA's bullets, TAISHA, his
            SPs and Kikons by name; the charged X-Axis shot, the J1 / K1 a HOSHA hit linked into and any J / K hit in a
            combo a trace hit started by the sim's log tag ("Px lb-sig <tag>" after the hit, lille.lisp LB-SIG-LOG);
            his laying shot (LB-NICK, 1 damage) counts nowhere, the Breaker and a plain J / K string never
  pacing    NORMAL, C vs each other character (C as P1): every match a K.O. and the median <= its cap (PACE_MAX 220 s;
            Lille's accepted exceptions: vs Rukia and vs Ichigo 240 s, DUEL_LILLE §23.22), else the score is 0. A K.O.:
            for Lille the RESULTS line's Konpaku (his cinematics put K.O.s past 300 s of match ticks); for the others, as
            frozen on 2026-10-02, a match under 299.5 s
  drift     Lille only: NORMAL, C vs each other character in both seats (the pacing runs are its P1 half): C's win share
            more than DRIFT_TOL (0.05) from the frozen baseline's, measured at the same seed count (DRIFT_REF, a JSON
            {"<seeds>": share}) -> the score is 0 (DREAM_RSI §5.5: NORMAL must stay near the shipped CPU); no reference
            for the seed count -> 0 too
score = w_str strength + w_mash masher + w_sig signature: 0.6 / 0.2 / 0.2 (the user's choice 2026-10-02: win rate +
character colour); Lille 0.4 / 0.2 / 0.4 (the user 2026-10-06: 「風格偏重 0.4/0.2/0.4」)

--pace-seeds / --drift-seeds (default --seeds) run the NORMAL parts at another seed count (the cheaper split, §24.2).
--write-drift-ref stores this run's drift share as the reference for its drift seed count (the frozen baseline only).
Roster index C: 0 Yamamoto 1 Kenpachi 2 Rukia 3 Ichigo 4 Senjumaru 5 Lille (simgate.ROSTER). Rebuilds the native sim first
when a source changed.
"""
import argparse, concurrent.futures as cf, json, os, re, statistics, subprocess, sys
sys.dont_write_bytecode = True
from simgate import ROOT, ECL, FAS, MUSLM, ROSTER, build

NAMES = ROSTER                                    # (simgate.ROSTER: the roster in order)
LILLE = NAMES.index('LILLE')
PACE_MAX = 220.0   # a 20-seed median's ceiling here (the gate's 210 s at 60 seeds: 20-seed medians run ~10 s noisy)
PACE_CAP = {LILLE: {'RUKIA': 240.0, 'ICHIGO': 240.0}}   # accepted exceptions (the user 2026-10-06: LR / LI, DUEL_LILLE §23.22; LR again 2026-10-07, §23.25)
WEIGHTS = {LILLE: (0.4, 0.2, 0.4)}                # strength, masher, signature; everyone else DEFAULT_W
DEFAULT_W = (0.6, 0.2, 0.2)
LINK = re.compile(r'-[JK]\d')                    # a J / K string link's move name (YA-J1, KE-R-K2S, RU-A-K3-50 ...)
# Lille's signature whitelist by name (DUEL_LILLE §24.2): the materialised traces (Jilliel's and the owl's: hazard LB-TRACE),
# HOSHA's bullets (LB-K-J), TAISHA (LB-K-K), the SPs: SANREN (base / KIN), SP2 HIRENKYAKU (base: the X-axis shot after its
# back-slide), NIJUSHI-KO (KIN), 審判光明 / 裁きの光明 (the owl KIN's SABAKI ground lines: hazard LB-SABAKI), Trompete (the owl
# KIN's blast); EN's SPs lay traces (their damage is LB-TRACE's); the three Kikons
SIG_LILLE = {'LB-TRACE', 'LB-K-J', 'LB-K-K', 'LB-SANREN', 'LB-HIREN', 'LB-NIJUSHI', 'LB-SABAKI', 'LB-TROMPETE',
             'LB-KIKON', 'LB-W-KIKON', 'LB-O-KIKON'}
SIG_TAGS = {'charged', 'hosha-link', 'trace-combo'}   # the sim's lb-sig tags (lille.lisp LB-SIG-LOG)
NOTHING_LILLE = {'LB-NICK'}                       # the laying shot (1 damage): counted on neither side
BREAKERS = {'LB-BREAKER', 'LB-W-BREAKER', 'LB-O-BREAKER'}
DRIFT_TOL = 0.05
DRIFT_REF = os.path.join(ROOT, 'docs/research/lille-ai-drsi/baseline/drift-ref.json')


def sim(cmds, log=True):
    script = 'tools/simgate/run-log.lisp' if log else 'tools/simgate/run.lisp'
    r = subprocess.run([ECL, '--norc', '--load', script, '--', FAS] + [str(c) for c in cmds], cwd=ROOT,
                       capture_output=True, text=True, env=dict(os.environ, LD_PRELOAD=MUSLM), timeout=3600)
    return r.stdout


def matches(job):
    """One learning-gate process: P1 c1 (habit h), P2 c2, seeds 1..n at difficulty d -> per match (winner, secs, hits) and
    per match a K.O. by the RESULTS line; hits per side: [name, damage, tag] in order (a "Px lb-sig TAG" line tags that
    side's hit just before it)."""
    c1, c2, h, n, d = job
    kos = []
    out = sim([30000, 31100 + n, 81000, 81020 + d, 81030, 81040, 200000 + 1000 * h + 100 * c1 + 10 * c2])
    res, hits, ko = [], {0: [], 1: []}, False
    for line in out.splitlines():
        m = re.match(r'duel -> RESULTS winner \S+ konpaku (\d+)-(\d+)', line)
        if m:
            ko = m.group(1) == '0' or m.group(2) == '0'
            continue
        m = re.search(r'\] P([12]) (\S+) -> P[12] (HIT|COUNTER) (\d+)', line)
        if m:
            hits[int(m.group(1)) - 1].append([m.group(2), int(m.group(4)), None])
            continue
        m = re.search(r'\] P([12]) lb-sig (\S+)', line)
        if m:
            side = hits[int(m.group(1)) - 1]
            if side:
                side[-1][2] = m.group(2)
            continue
        m = re.search(r'duel gate row seed \d+ \S+ \S+ secs ([\d.]+) winner (\S+)', line)
        if m:
            res.append((m.group(2), float(m.group(1)), hits))
            hits = {0: [], 1: []}
            kos.append(ko)
    return job, res, kos


def lille_class(name, tag):
    """One of Lille's hits -> (counted, signature, category of the breakdown)."""
    if name in NOTHING_LILLE:
        return False, False, 'nick'
    if tag in SIG_TAGS:
        return True, True, tag
    if name in SIG_LILLE:
        return True, True, name.lower()
    if name in BREAKERS:
        return True, False, 'breaker'
    if name == 'LB-K-SHOT':
        return True, False, 'quick-shot'
    if LINK.search(name):
        return True, False, 'plain-jk'
    return True, False, 'other:' + name.lower()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--char', type=int, required=True)
    ap.add_argument('--seeds', type=int, default=20)
    ap.add_argument('--pace-seeds', type=int, default=0, help='seeds of the NORMAL pacing runs (default --seeds)')
    ap.add_argument('--drift-seeds', type=int, default=0, help="seeds of Lille's NORMAL drift runs (default --seeds)")
    ap.add_argument('--write-drift-ref', action='store_true', help='store this drift share as the reference (baseline only)')
    ap.add_argument('-j', type=int, default=8)
    a = ap.parse_args()
    build()                                       # (a no-op unless a source is newer than the build)
    c, n, others = a.char, a.seeds, [o for o in range(len(NAMES)) if o != a.char]
    pn, dn = a.pace_seeds or n, a.drift_seeds or n
    lille = c == LILLE
    jobs = ([('str', (c, o, 0, n, 2)) for o in others] + [('str', (o, c, 0, n, 2)) for o in others] +
            [('mash', (m, c, 6, max(4, n * 4 // 5), 2)) for m in range(len(NAMES))] +
            [('pace', (c, o, 0, pn, 1)) for o in others])
    if lille:                                     # (the drift's P1 half is the pacing runs when the seed counts agree)
        jobs += [('drift', (o, c, 0, dn, 1)) for o in others]
        if dn != pn:
            jobs += [('drift', (c, o, 0, dn, 1)) for o in others]
    won = {'str': [0, 0], 'mash': [0, 0]}
    drift = {}                                    # Lille: opponent -> [his wins, matches] (both seats)
    sig = [0, 0]
    cat = {}                                      # Lille: his damage by category (the breakdown)
    pace_ok, pace = True, {}
    with cf.ProcessPoolExecutor(a.j) as ex:
        futs = {ex.submit(matches, job): kind for kind, job in jobs}
        for fu in cf.as_completed(futs):
            kind = futs[fu]
            (c1, c2, h, nn, d), res, ko = fu.result()
            # a K.O.: Lille's by the RESULTS line's Konpaku (his cinematics put K.O.s past 300 s of match ticks); the others'
            # as frozen on 2026-10-02: a match under 299.5 s (a time-up runs the 300 s clock out)
            nm, kos = len(res), sum(1 for (_, s, _), k in zip(res, ko) if (k if lille else s < 299.5))
            side = 1 if kind == 'mash' else (0 if c1 == c else 1)   # C's seat (the masher is always P1, C's mirror too)
            opp = NAMES[c2 if side == 0 else c1]
            if lille and (kind == 'drift' or (kind == 'pace' and pn == dn)):
                w = drift.setdefault(opp, [0, 0])
                w[0] += sum(1 for win, _, _ in res if win == ('P1' if side == 0 else 'P2'))
                w[1] += len(res)
            if kind == 'drift':
                continue
            if kind == 'pace':
                secs = sorted(s for _, s, _ in res)
                med = statistics.median(secs) if secs else 999.0
                cap = PACE_CAP.get(c, {}).get(opp, PACE_MAX)
                pace[opp] = {'kos': kos, 'matches': nm, 'median': round(med, 1)}
                if cap != PACE_MAX:
                    pace[opp]['cap'] = cap
                if nm == 0 or kos < nm or med > cap:
                    pace_ok = False
                continue
            for w, _, hits in res:
                won[kind][1] += 1
                won[kind][0] += (w == ('P1' if side == 0 else 'P2'))
                if kind == 'str':
                    for name, dmg, tag in hits[side]:
                        if lille:
                            counted, mine, k = lille_class(name, tag)
                            cat[k] = cat.get(k, 0) + dmg
                            if counted:
                                sig[1] += dmg
                                sig[0] += dmg if mine else 0
                        else:
                            sig[1] += dmg
                            sig[0] += 0 if LINK.search(name) else dmg
    part = {k: (won[k][0] / won[k][1] if won[k][1] else 0.0) for k in won}
    part['signature'] = sig[0] / sig[1] if sig[1] else 0.0
    ws, wm, wg = WEIGHTS.get(c, DEFAULT_W)
    out = {'char': NAMES[c], 'score': 0.0, 'strength': round(part['str'], 3), 'masher': round(part['mash'], 3),
           'signature': round(part['signature'], 3), 'pacing_ok': pace_ok, 'pacing': pace,
           'matches': {k: won[k][1] for k in won}}
    ok = pace_ok
    if lille:
        dw, dm = sum(v[0] for v in drift.values()), sum(v[1] for v in drift.values())
        share = dw / dm if dm else 0.0
        refs = json.load(open(DRIFT_REF)) if os.path.exists(DRIFT_REF) else {}
        if a.write_drift_ref:
            refs[str(dn)] = round(share, 4)
            os.makedirs(os.path.dirname(DRIFT_REF), exist_ok=True)
            with open(DRIFT_REF, 'w') as f:
                f.write(json.dumps(refs, indent=1, sort_keys=True) + '\n')
        ref = refs.get(str(dn))
        drift_ok = ref is not None and abs(share - ref) <= DRIFT_TOL + 1e-9
        ok = ok and drift_ok
        out['drift'] = {'share': round(share, 4), 'ref': ref, 'tol': DRIFT_TOL, 'ok': drift_ok, 'seeds': dn,
                        'by_opp': {k: f'{v[0]}/{v[1]}' for k, v in sorted(drift.items())}}
        tot = sum(v for k, v in cat.items() if k != 'nick') or 1
        out['sig_by'] = {k: round(v / tot, 3) for k, v in sorted(cat.items(), key=lambda kv: -kv[1]) if k != 'nick'}
        out['weights'] = [ws, wm, wg]
        if pn != n:
            out['pace_seeds'] = pn
    out['score'] = round(ws * part['str'] + wm * part['mash'] + wg * part['signature'], 4) if ok else 0.0
    print(json.dumps(out))


if __name__ == '__main__':
    main()
