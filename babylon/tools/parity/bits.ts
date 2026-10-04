// bits.ts: the TS side of parity.py --bits: per battle step in LO..HI the line bits.lisp prints (the sim stream's state,
// both fighters' state, sf and floats as integer-decode-float pairs of their f32 value).
// usage: npx tsx tools/parity/bits.ts <p1> <p2> <seed> <lo> <hi>
import '../../src/chars';
import { Match } from '../../src/sim/match';
import type { Ent } from '../../src/sim/types';

declare const process: { argv: string[] };
const CHARS: Record<string, string> = { y: 'yamamoto', k: 'kenpachi', r: 'rukia', i: 'ichigo', s: 'senjumaru' };
const [a, b, s, lo, hi] = process.argv.slice(2);
const fw = new Float32Array(1), u = new Uint32Array(fw.buffer);
function fb(x: number): string {                     // CL INTEGER-DECODE-FLOAT of the f32 nearest X: "mantissa.exponent"
  fw[0] = x; const w = u[0], ex = (w >>> 23) & 255, fr = w & 0x7fffff;
  if (ex === 0 && fr === 0) return '0';
  return `${(w >>> 31 ? -1 : 1) * (ex === 0 ? fr : fr | 0x800000)}.${ex === 0 ? -149 : ex - 150}`;
}
const side = (e: Ent): string => {
  const f = e.f, g = e.g, v = e.mo.vel, k = e.mo.kb, vp = e.pilot.vpad;
  return `${f.state.toUpperCase()} ${f.sf} ` + [e.pos[0], e.pos[1], e.pos[2], e.yaw, v[0], v[1], v[2], k[0], k[2], f.dist, g.gg, g.fs,
    g.reiatsu, g.awaken, g.meter, g.stun, vp.sx, vp.sy].map(fb).join(' ');
};
const m = new Match({ p1: CHARS[a] ?? a, p2: CHARS[b] ?? b, seed: Number(s), cpu1: true, cpu2: true }).start();
m.runToEnd(60 * 600, () => {
  m.takeEvents(); m.takeLog();
  const w = m.w;
  if (w.flow === 'battle' && w.tick >= +lo && w.tick <= +hi) console.log(`B ${w.tick} ${w.rng.state} | ${side(w.p1)} | ${side(w.p2)}`);
});
