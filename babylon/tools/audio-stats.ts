// audio-stats.ts: render every sound of the bank (src/audio/sounds.ts) in node and print its length, render time, peak,
// RMS and DC (audio.lisp's AU-STATS line; "<-- BAD" on NaN, a clip, DC or silence). `npx tsx tools/audio-stats.ts`
declare const process: { exitCode: number };
import { RATE } from '../src/audio/synth';
import { SOUNDS, renderSound } from '../src/audio/sounds';

let total = 0, bad = 0;
const t0 = performance.now();
for (const k of Object.keys(SOUNDS)) {
  const t = performance.now(), b = renderSound(k), ms = performance.now() - t;
  let pk = 0, sum = 0, sq = 0, nan = 0;
  for (const x of b) { if (!Number.isFinite(x)) nan++; pk = Math.max(pk, Math.abs(x)); sum += x; sq += x * x; }
  const rms = Math.sqrt(sq / b.length), dc = sum / b.length, len = Math.round((1000 * b.length) / RATE);
  const no = nan > 0 || pk > 0.96 || Math.abs(dc) > 0.01 || rms < 0.005 || len < 20;
  if (no) bad++;
  total += b.length;
  console.log(`audio: ${k.padEnd(16)} ${String(len).padStart(5)} ms  peak ${pk.toFixed(3)}  rms ${rms.toFixed(3)}  dc ${dc.toFixed(5)}  ${ms.toFixed(1).padStart(6)} ms render${no ? '  <-- BAD' : ''}`);
}
console.log(`audio: ${Object.keys(SOUNDS).length} sounds, ${((4 * total) / 1048576).toFixed(1)} MB samples, ${(performance.now() - t0).toFixed(0)} ms, ${bad} bad`);
process.exitCode = bad ? 1 : 0;
