// gate.ts: the seed gate (tools/simgate.py's job for the Babylon sim): CPU vs CPU NORMAL per pairing over N seeds, run in
// parallel child processes; per pairing: K.O. count, P1 / P2 wins, median seconds, and the Lisp reference median
// (docs/DUEL_AI_V2.md "Gates (final)").
// usage: npx tsx tools/gate.ts --pairs yy,yk,kk --seeds 20 [--start 1] [--workers 12] [--ai stub]
import { runSeed } from './headless';

// ponytail: no @types/node for one tool: the node globals it touches, untyped
declare const process: { argv: string[]; execPath: string; exit(c: number): never };
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const cp: any = await import('node:child_process' as string);

const CHARS: Record<string, string> = { y: 'yama', k: 'ken', r: 'rukia' };
const LISP_MEDIAN: Record<string, number> = { yy: 139.0, yk: 159.5, kk: 151.6, ry: 163.1, rk: 150.3, rr: 208.2 };
interface Job { pair: string; seed: number; ai: 'ai' | 'stub' }
interface Row extends Job { winner: string; ko: boolean; secs: number }

/** One match: its RESULTS line read back (K.O. = someone at 0 Konpaku). */
function play(j: Job): Row {
  const out = runSeed(CHARS[j.pair[0]], CHARS[j.pair[1]], j.seed, j.ai);
  const m = /winner (\S+) konpaku (\d+)-(\d+) ticks \d+ secs ([\d.]+)/.exec(out[out.length - 1]);
  if (!m) return { ...j, winner: 'NONE', ko: false, secs: NaN };
  return { ...j, winner: m[1], ko: m[2] === '0' || m[3] === '0', secs: Number(m[4]) };
}

const ci = process.argv.indexOf('--child');
if (ci >= 0) {                                                       // a child: its share of the jobs, one JSON row a line
  for (const j of JSON.parse(process.argv[ci + 1]) as Job[]) console.log(JSON.stringify(play(j)));
} else {
  const arg = (k: string, d: string) => { const i = process.argv.indexOf(`--${k}`); return i >= 0 ? process.argv[i + 1] : d; };
  const pairs = arg('pairs', 'yy,yk,kk').split(','), n = Number(arg('seeds', '20')), start = Number(arg('start', '1'));
  const ai = arg('ai', 'ai') === 'stub' ? 'stub' : 'ai';
  const jobs: Job[] = pairs.flatMap((pair) => Array.from({ length: n }, (_, i) => ({ pair, seed: start + i, ai })));
  const nw = Math.min(Number(arg('workers', '12')), jobs.length);
  // ponytail: child processes, not worker_threads (tsx's resolver doesn't reach a worker's extensionless imports)
  const rows: Row[] = (await Promise.all(Array.from({ length: nw }, (_, w) => new Promise<Row[]>((ok, fail) => {
    const share = jobs.filter((_, i) => i % nw === w);
    cp.execFile(process.execPath, ['--import', 'tsx', process.argv[1], '--child', JSON.stringify(share)],
      { maxBuffer: 1 << 26 }, (err: unknown, out: string) => (err ? fail(err) : ok(out.trim().split('\n').map((l) => JSON.parse(l)))));
  })))).flat();
  const median = (xs: number[]) => { const s = [...xs].sort((a, b) => a - b), h = s.length >> 1; return s.length % 2 ? s[h] : (s[h - 1] + s[h]) / 2; };
  console.log(`seeds ${start}-${start + n - 1}, CPU vs CPU ${ai === 'stub' ? 'stub' : 'NORMAL'}`);
  console.log('pair  K.O.   P1  P2  draw  median s  lisp s');
  for (const pair of pairs) {
    const r = rows.filter((x) => x.pair === pair);
    const c = (w: string) => r.filter((x) => x.winner === w).length;
    console.log(`${pair.toUpperCase().padEnd(4)} ${String(r.filter((x) => x.ko).length).padStart(2)}/${r.length}  ${String(c('P1')).padStart(3)}`
      + ` ${String(c('P2')).padStart(3)}  ${String(r.length - c('P1') - c('P2')).padStart(4)}  ${median(r.map((x) => x.secs)).toFixed(1).padStart(8)}`
      + `  ${(LISP_MEDIAN[pair]?.toFixed(1) ?? '-').padStart(6)}`);
  }
}
