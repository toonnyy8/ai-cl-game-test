// headless.ts: CPU vs CPU to the end (K.O. or the 300 s timer), no Babylon. Prints the Lisp's lines per seed:
//   duel hash t=N | ...                                   every 600 battle ticks (determinism)
//   duel -> RESULTS winner P1|P2|DRAW konpaku a-b ticks N secs S
// usage: npx tsx tools/headless.ts --p1 yama --p2 ken --seed 7 [--seeds N] [--quiet] [--ai stub]   (yama / ken or yamamoto /
//        kenpachi; --ai stub: M1's stand-in CPU instead of ai.ts)
import '../src/chars';
import { Match, setBrainStep } from '../src/sim/match';
import { stubBrainStep } from '../src/sim/stubai';
import { brainStep } from '../src/sim/ai';

// ponytail: no @types/node for one global
declare const process: { argv: string[] };

const ALIAS: Record<string, string> = { yama: 'yamamoto', ken: 'kenpachi', y: 'yamamoto', k: 'kenpachi', r: 'rukia', i: 'ichigo', s: 'senjumaru' };

export function runSeed(p1: string, p2: string, seed: number, ai: 'ai' | 'stub' = 'ai'): string[] {
  setBrainStep(ai === 'stub' ? stubBrainStep : brainStep);
  const m = new Match({ p1: ALIAS[p1] ?? p1, p2: ALIAS[p2] ?? p2, seed, cpu1: true, cpu2: true }).start();
  const out: string[] = [];
  const keep = (l: string) => l.startsWith('duel hash') || l.startsWith('duel -> RESULTS');
  m.runToEnd(60 * 60 * 10, () => { m.takeEvents(); for (const l of m.takeLog()) if (keep(l)) out.push(l); });
  if (m.running()) out.push('duel -> NO RESULT (step cap)');
  return out;
}

const isMain = process.argv[1] && /headless\.ts$/.test(process.argv[1]);
if (isMain) {
  const arg = (k: string, d: string) => { const i = process.argv.indexOf(`--${k}`); return i >= 0 ? process.argv[i + 1] : d; };
  const p1 = arg('p1', 'yama'), p2 = arg('p2', 'ken'), seed = Number(arg('seed', '1')), n = Number(arg('seeds', '1'));
  const quiet = process.argv.includes('--quiet'), ai = arg('ai', 'ai') === 'stub' ? 'stub' : 'ai';
  for (let s = seed; s < seed + n; s++) {
    if (n > 1) console.log(`# seed ${s}`);
    for (const l of runSeed(p1, p2, s, ai)) if (!quiet || !l.startsWith('duel hash')) console.log(l);
  }
}
