// log.ts: one CPU vs CPU match of the TS sim with the combat log on, for the parity check (parity.py). Prints, in step
// order, the combat-log events, the `duel hash` lines and the RESULTS line, as the native run-log.lisp does.
// usage: npx tsx tools/parity/log.ts <p1> <p2> <seed>      (yamamoto kenpachi rukia ichigo senjumaru, or y k r i s)
import '../../src/chars';
import { Match } from '../../src/sim/match';

declare const process: { argv: string[] };
const CHARS: Record<string, string> = { y: 'yamamoto', k: 'kenpachi', r: 'rukia', i: 'ichigo', s: 'senjumaru' };
const [a, b, s] = process.argv.slice(2);
const m = new Match({ p1: CHARS[a] ?? a, p2: CHARS[b] ?? b, seed: Number(s), cpu1: true, cpu2: true }).start();
m.w.combatLog = [];
const out: string[] = [];
m.runToEnd(60 * 600, () => { m.takeEvents(); out.push(...m.w.combatLog!.splice(0), ...m.takeLog()); });
console.log(out.join('\n'));
