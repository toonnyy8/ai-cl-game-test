// learngate.ts: debug.lisp's learning gate (debug 200000+) and ASSIST's gate (tools/assistgate.py) for the Babylon sim.
// Seeds back to back in one process (the tables carry over, as one native process does): P1 a CPU with a scripted habit
// (habits.ts), P2 the CPU, learning by --learn; P1 = the 'dumb' masher gets ASSIST --assist k (k = AUTO GUARD 0-2 + 3 x
// COMBO + 6 x BREAK, as 81000+k). Prints a "duel learn row" per match (the Lisp's format) and a summary.
// usage: npx tsx tools/learngate.ts --habit grab --p1 ken --p2 ken --learn 1 --seeds 30 [--start 1] [--diff normal]
//        [--assist k] [--assist-learn 1] [--p2-dumb] [--log]   (--log: the combat log lines too)
import '../src/chars';
import { Match } from '../src/sim/match';
import { DUMB_DELAY, HABITS } from '../src/sim/habits';
import { LEARN_ACTIONS, LEARN_SITUATIONS, LEARN_USE, learnAttach, learnPExploit, learnPredict, learnTables } from '../src/sim/learn';
import { ASSIST_DEBUG, assistBrainOf } from '../src/sim/assist';

declare const process: { argv: string[] };
const ALIAS: Record<string, string> = { yama: 'yamamoto', ken: 'kenpachi', y: 'yamamoto', k: 'kenpachi' };
const arg = (k: string, d: string) => { const i = process.argv.indexOf(`--${k}`); return i >= 0 ? process.argv[i + 1] : d; };
const flag = (k: string) => process.argv.includes(`--${k}`);

const h = arg('habit', 'grab'), habit = /^\d$/.test(h) ? HABITS[Number(h)] : h;
const p1 = ALIAS[arg('p1', 'ken')] ?? arg('p1', 'ken'), p2 = ALIAS[arg('p2', 'ken')] ?? arg('p2', 'ken');
const on = Number(arg('learn', '1')), n = Number(arg('seeds', '30')), start = Number(arg('start', '1'));
const diff = arg('diff', 'normal'), k = Number(arg('assist', '0')), log = flag('log');
LEARN_USE.model = on === 1 || on === 2; LEARN_USE.bandit = on === 1 || on === 3;
ASSIST_DEBUG.cfg = [k % 3, Math.floor(k / 3) % 2 === 1, k >= 6];
ASSIST_DEBUG.learn = arg('assist-learn', '1') === '1';
learnTables.fill(null);                                              // P2's table fresh at the start, kept across the seeds

let wins = 0, reads = 0, paid = 0;
const assists: Record<string, number> = {};
for (let seed = start; seed < start + n; seed++) {
  const m = new Match({ p1, p2, seed, cpu1: true, cpu2: true, difficulty: diff }).start();
  const w = m.w, b1 = w.p1.brain!, b2 = w.p2.brain!;
  b1.habit = habit;
  if (habit === 'dumb') b1.delay = DUMB_DELAY;
  if (flag('p2-dumb')) { b2.habit = 'dumb'; b2.delay = DUMB_DELAY; }
  if (on) learnAttach(w.p2);
  w.combatLog = [];                                                  // (read for the assist counts; printed with --log)
  m.runToEnd(60 * 60 * 10, () => {
    m.takeEvents();
    for (const l of m.takeLog()) if (l.startsWith('duel -> RESULTS')) console.log(l);
    for (const l of w.combatLog!) { if (log) console.log(l); const a = / assist (\S+)/.exec(l); if (a) assists[a[1]] = (assists[a[1]] ?? 0) + 1; }
    w.combatLog = [];
  });
  const l = b2.learn, tab = l?.tab, winner = w.winner === 0 ? 'P1' : w.winner === 1 ? 'P2' : 'DRAW';
  if (w.winner === 0) wins++;
  reads += l?.reads ?? 0; paid += l?.paid ?? 0;
  const model = tab ? ' model ' + LEARN_SITUATIONS.map((s, i) => {
    const [act, p, nn] = learnPredict(tab, i);
    return `${s}=${act == null ? '-' : LEARN_ACTIONS[act]}${p.toFixed(2)}/${nn.toFixed(1)}`;
  }).join(' ') : '';
  const by = l?.stats.length ? ' by ' + l.stats.map(([c, r, pd]) => `${c} ${r}/${pd}`).join(' ') : '';
  console.log(`duel learn row seed ${seed} habit ${habit ?? 'plain'} ${p1} ${p2} learn ${on ? 'on' : 'off'} winner ${winner}`
    + ` dealt ${w.p1.g.dealt} ${w.p2.g.dealt} counters ${w.p1.g.counters} ${w.p2.g.counters} reads ${l?.reads ?? 0} paid ${l?.paid ?? 0}`
    + ` pexp ${tab ? learnPExploit(tab.form).toFixed(2) : '0.00'} form ${tab ? tab.form.toFixed(2) : '0.00'}${model}${by}`
    + (habit === 'dumb' && assistBrainOf(0)?.learn ? ` | assist learner form ${assistBrainOf(0)!.learn!.tab.form.toFixed(2)}` : ''));
}
console.log(`learn gate ${habit ?? 'plain'} ${p1} v ${p2} learn ${on} diff ${diff}${habit === 'dumb' ? ` assist k${k}` : ''}:`
  + ` P1 wins ${wins}/${n}, P2 ${(1 - wins / n).toFixed(2)}, reads ${reads} paid ${paid}`
  + (Object.keys(assists).length ? `, assists ${JSON.stringify(assists)}` : ''));
