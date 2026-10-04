// endless.ts: the ENDLESS autopilot headless (endless.lisp debug 80992 / 80990's job): a run with P1 a HARD CPU from
// NORMAL, POLICY (stay / revert) at every STAGE CLEAR, until P1 loses. Prints the run's log lines (duel endless ...), each
// stage's "duel match", RESULTS and (unless --quiet) hash lines, like the native Lisp's console.
// usage: npx tsx tools/endless.ts --p1 rukia --seed 1 [--seeds N] [--policy stay|revert] [--max 99] [--quiet] [--clog]
import '../src/chars';
import { autoRun } from '../src/sim/endless';
import { ROSTER } from '../src/sim/kit';

declare const process: { argv: string[] };
const arg = (k: string, d: string) => { const i = process.argv.indexOf(`--${k}`); return i >= 0 ? process.argv[i + 1] : d; };
const p1s = arg('p1', 'all') === 'all' ? ROSTER : arg('p1', '').split(',');
const seed = Number(arg('seed', '1')), n = Number(arg('seeds', '1')), max = Number(arg('max', '99'));
const policy = arg('policy', 'stay') === 'revert' ? 'revert' : 'stay', quiet = process.argv.includes('--quiet');
const clog = process.argv.includes('--clog');
for (const c of p1s) {
  const stages: number[] = [];
  for (let s = seed; s < seed + n; s++) {
    const { run, log } = autoRun(c, s, policy, max, clog ? (m, line) => {
      if (!m.w.combatLog) m.w.combatLog = [];
      for (const l of m.w.combatLog) line(l);
      m.w.combatLog.length = 0;
    } : undefined);
    for (const l of log) if (!quiet || !l.startsWith('duel hash')) console.log(l);
    stages.push(run.cleared);
  }
  if (n > 1) { const st = [...stages].sort((a, b) => a - b); console.log(`duel endless gate P1 ${c} policy ${policy} runs ${n} median ${st[n >> 1]} stages (${st.join(' ')})`); }
}
