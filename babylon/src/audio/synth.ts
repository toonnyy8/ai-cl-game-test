// synth.ts <- engine/lisp/audio.lisp's synthesis toolkit (docs/engine/AUDIO.md): mono Float32Array buffers at 48 kHz, every sound
// built from noise, sines, saws, a state-variable filter, drive, delay and a Schroeder reverb. Pure (no WebAudio), so the
// bank renders the same in node (tests, tools/audio-stats.ts) and in the page. Names: au-foo! -> foo (in place, returns BUF).
export const RATE = 48000;
const DT = 1 / RATE;
export type Buf = Float32Array<ArrayBuffer>;

// au_rand (engine.h): xorshift32, uniform [-1, 1). Reseeded per sound (sounds.ts) so a sound never depends on render order.
let rng = 0x9e3779b9;
export function seedNoise(s: number): void { rng = s >>> 0 || 1; }
export function rnd(): number { rng ^= rng << 13; rng >>>= 0; rng ^= rng >>> 17; rng ^= rng << 5; rng >>>= 0; return (rng | 0) * 4.656612873e-10; }
export const rrange = (lo: number, hi: number): number => lo + (hi - lo) * (0.5 + 0.5 * rnd());
export const midi = (m: number): number => 440 * 2 ** ((m - 69) / 12);

const TAU = 2 * Math.PI;
export const frac = (x: number): number => x - Math.floor(x);
export const sin = (ph: number): number => Math.sin(TAU * ph);
export const saw = (ph: number): number => 2 * frac(ph) - 1;
export const envExp = (tt: number, d: number): number => Math.exp(-tt / d);
/** Linear attack A, then exponential decay with time constant D. */
export const ar = (tt: number, a: number, d: number): number => (tt < a ? tt / a : Math.exp((a - tt) / d));
/** Linear ADSR; held until LEN seconds, then released over R. */
export function adsr(tt: number, a: number, d: number, s: number, r: number, len: number): number {
  return tt < a ? tt / a : tt < a + d ? 1 - (1 - s) * ((tt - a) / d) : tt < len ? s : s * Math.max(0, 1 - (tt - len) / r);
}
/** Exponential glide F0 -> F1 over TIME seconds, then hold. */
export const sweep = (tt: number, f0: number, f1: number, time: number): number => f0 * (f1 / f0) ** Math.min(1, tt / time);

export const buf = (secs: number): Buf => new Float32Array(Math.max(1, Math.round(secs * RATE)));

/** au-render: ADD FN(tt) (tt = seconds since AT) into B from AT for DUR seconds (default: to the end). */
export function render(b: Buf, fn: (tt: number) => number, at = 0, dur?: number): Buf {
  const s0 = Math.min(b.length, Math.max(0, Math.round(at * RATE)));
  const s1 = dur === undefined ? b.length : Math.min(b.length, s0 + Math.round(dur * RATE));
  for (let i = s0; i < s1; i++) b[i] += fn((i - s0) * DT);
  return b;
}

export function peak(b: Buf): number { let p = 0; for (let i = 0; i < b.length; i++) p = Math.max(p, Math.abs(b[i])); return p; }
export function scale(b: Buf, g: number): Buf { for (let i = 0; i < b.length; i++) b[i] *= g; return b; }
export function normalize(b: Buf, pk = 1): Buf { const p = peak(b); return p > 0 ? scale(b, pk / p) : b; }

/** Add SRC*GAIN into DST at AT seconds (a negative AT drops the head of SRC). */
export function mix(dst: Buf, src: Buf, at = 0, gain = 1): Buf {
  const off = Math.round(at * RATE), end = Math.min(src.length, dst.length - off);
  for (let j = Math.max(0, -off); j < end; j++) dst[j + off] += gain * src[j];
  return dst;
}

export type Mode = 'lp' | 'bp' | 'hp';
/** TPT state-variable filter (Simper), in place. :bp has unity peak. Cutoff sweeps exponentially FROM -> TO over TIME
 *  seconds (0 = the whole buffer). */
export function svf(b: Buf, mode: Mode, from = 1000, to = from, q = 0.707, time = 0): Buf {
  const n = b.length, k = 1 / q, ratio = to / from, sweepN = time > 0 ? Math.max(1, Math.round(time * RATE)) : n;
  let s1 = 0, s2 = 0, g = Math.tan(Math.PI * DT * Math.min(from, 20000));
  for (let i = 0; i < n; i++) {
    if (from !== to) g = Math.tan(Math.PI * DT * Math.min(20000, from * ratio ** Math.min(1, i / sweepN)));
    const a1 = 1 / (1 + g * (g + k)), a2 = g * a1, a3 = g * a2;
    const v0 = b[i], v3 = v0 - s2, v1 = a1 * s1 + a2 * v3, v2 = s2 + a2 * s1 + a3 * v3;
    s1 = 2 * v1 - s1; s2 = 2 * v2 - s2;
    b[i] = mode === 'lp' ? v2 : mode === 'bp' ? k * v1 : v0 - k * v1 - v2;
  }
  return b;
}

/** 6 dB/oct low / high pass, in place. */
export function onepole(b: Buf, mode: 'lp' | 'hp', freq: number): Buf {
  const a = Math.exp(-TAU * freq * DT), c = 1 - a;
  let y = 0;
  for (let i = 0; i < b.length; i++) { const x = b[i]; y = c * x + a * y; b[i] = mode === 'hp' ? x - y : y; }
  return b;
}

/** Normalize, then tanh waveshape: AMOUNT 1 = gentle, 5+ = crushed. */
export function drive(b: Buf, amount: number): Buf {
  normalize(b);
  const k = 1 / Math.tanh(amount);
  for (let i = 0; i < b.length; i++) b[i] = k * Math.tanh(amount * b[i]);
  return b;
}

/** Feedback delay (echo), in place. */
export function delay(b: Buf, secs: number, fb: number, wet: number): Buf {
  const d = Math.max(1, Math.round(secs * RATE)), line = new Float32Array(d);
  for (let i = 0, j = 0; i < b.length; i++) {
    const y = line[j], x = b[i];
    line[j] = x + fb * y; b[i] = x + wet * y;
    if (++j >= d) j = 0;
  }
  return b;
}

/** Schroeder / Freeverb-style: 4 damped combs -> 2 allpasses, added at WET. */
export function reverb(b: Buf, wet: number, size = 1, damp = 0.3, fb = 0.8): Buf {
  const n = b.length, w = new Float32Array(n);
  for (const len of [1214, 1293, 1389, 1475]) {
    const l = Math.max(1, Math.round(len * size)), line = new Float32Array(l);
    let store = 0;
    for (let i = 0, j = 0; i < n; i++) {
      const y = line[j];
      store = y * (1 - damp) + store * damp;
      line[j] = b[i] + store * fb; w[i] += 0.25 * y;
      if (++j >= l) j = 0;
    }
  }
  for (const len of [605, 480]) {
    const l = Math.max(1, Math.round(len * size)), line = new Float32Array(l);
    for (let i = 0, j = 0; i < n; i++) {
      const x = w[i], y = line[j];
      line[j] = x + 0.5 * y; w[i] = y - x;
      if (++j >= l) j = 0;
    }
  }
  return mix(b, w, 0, wet);
}

/** A seamless loop of N samples: what was rendered past N is added onto the head (XFADE: equal-power crossfaded). */
export function fold(b: Buf, n: number, xfade = false): Buf {
  const out = b.slice(0, n), tl = b.length - n;
  for (let i = 0; i < Math.min(tl, n); i++) {
    const x = b[n + i];
    if (xfade) { const u = i / tl; out[i] = Math.sqrt(u) * out[i] + Math.sqrt(1 - u) * x; } else out[i] += x;
  }
  return out;
}

export const reverse = (b: Buf): Buf => b.slice().reverse();

// ---------------------------------------------------------------- elements
export interface Env { attack?: number; hold?: number; decay?: number }
/** White noise under attack / hold / exponential decay. */
export function noise(secs: number, { attack = 0.002, hold = 0, decay = 0.1 }: Env = {}): Buf {
  return render(buf(secs), (tt) => rnd() * (tt < attack ? tt / attack : tt < attack + hold ? 1 : Math.exp((attack + hold - tt) / decay)));
}
/** A filtered noise burst normalized to peak 1. */
export function fnoise(secs: number, mode: Mode, from: number, o: Env & { to?: number; q?: number } = {}): Buf {
  return normalize(svf(noise(secs, o), mode, from, o.to ?? from, o.q ?? 0.707));
}
/** Air movement: band-passed noise sweeping F0 -> F1, swelling until PEAK seconds. */
export function whoosh(secs: number, f0: number, f1: number, q = 1.2, pk = 0.3): Buf {
  const b = render(buf(secs), (tt) => rnd() * (tt < pk ? (tt / pk) ** 2 : Math.max(0, (secs - tt) / (secs - pk)) ** 3));
  return normalize(svf(b, 'bp', f0, f1, q));
}
/** A sine partial with exponential decay; GLIDE = the pitch ratio reached after DECAY. */
export function ping(b: Buf, at: number, freq: number, decay: number, gain: number, attack = 0.001, glide = 1): Buf {
  let ph = 0;
  const lg = Math.log(glide);
  return render(b, (tt) => {
    ph = frac(ph + (glide === 1 ? freq : freq * Math.exp(lg * Math.min(1, tt / decay))) * DT);
    return gain * ar(tt, attack, decay) * sin(ph);
  }, at, attack + 7 * decay);
}
/** PARTIALS = [freq, amp, decay][]: bells, blades, metal. */
export function partials(b: Buf, at: number, ps: [number, number, number][], glide = 1): Buf {
  for (const [f, a, d] of ps) ping(b, at, f, d, a, 0.001, glide);
  return b;
}
/** A pitch-dropping sine: kicks, body impacts, booms. */
export function thump(b: Buf, at: number, f0: number, f1: number, sw: number, decay: number, gain: number): Buf {
  let ph = 0;
  return render(b, (tt) => { ph = frac(ph + sweep(tt, f0, f1, sw) * DT); return gain * ar(tt, 0.002, decay) * sin(ph); }, at, 7 * decay);
}
export function taiko(b: Buf, at: number, gain: number, f = 80): Buf {
  thump(b, at, f * 1.5, f, 0.03, 0.35, gain);
  ping(b, at, f * 2.31, 0.1, 0.3 * gain);
  return mix(b, onepole(noise(0.1, { decay: 0.012 }), 'lp', 1800), at, 0.5 * gain);
}
const GONG: [number, number, number][] = [[1, 1, 2], [1.51, 0.8, 1.5], [2.07, 0.65, 1.1], [2.62, 0.5, 0.8], [3.2, 0.4, 0.6], [4.1, 0.3, 0.45], [5.3, 0.2, 0.3]];
export function gong(b: Buf, at: number, f0: number, gain: number, len = 1): Buf {
  partials(b, at, GONG.map(([r, a, d]) => [f0 * r, a * gain, d * len]), 0.985);
  return mix(b, fnoise(0.1, 'lp', 900, { decay: 0.02 }), at, 0.3 * gain);
}
/** A shakuhachi-ish breathy note: a scoop up into pitch, delayed vibrato, breath chiff. */
export function shaku(b: Buf, at: number, dur: number, f: number, gain: number, vib = 0.012): Buf {
  const len = dur + 0.25, tone = buf(len);
  let ph = 0;
  render(tone, (tt) => {
    const bend = tt < 0.08 ? 0.944 + 0.056 * (tt / 0.08) : 1, vd = vib * Math.min(1, tt / 0.6);
    ph = frac(ph + f * bend * (1 + vd * sin(5.2 * tt)) * DT);
    return adsr(tt, 0.07, 0.15, 0.8, 0.2, dur) * (sin(ph) + 0.22 * sin(2 * ph) + 0.07 * sin(3 * ph));
  });
  const br = render(buf(len), (tt) => rnd() * adsr(tt, 0.03, 0.15, 0.3, 0.2, dur));
  mix(tone, svf(br, 'bp', 2 * f, 2 * f, 1.5), 0, 0.45);
  return mix(b, tone, at, gain);
}
/** A detuned saw pad / drone over FREQS. */
export function saws(b: Buf, at: number, dur: number, freqs: number[], gain: number, a = 0.3, r = 0.6): Buf {
  const g = gain / freqs.length;
  for (const f0 of freqs) for (const det of [0.996, 1.004]) {
    const f = f0 * det;
    let ph = 0.5 + 0.5 * rnd();
    render(b, (tt) => { ph = frac(ph + f * DT); return g * adsr(tt, a, 0.1, 1, r, dur) * saw(ph); }, at, dur + r);
  }
  return b;
}

// ---------------------------------------------------------------- the bank's finishing (audio-init-sound)
/** NaN / Inf to 0; one-shots also lose DC (15 Hz high pass) and fade their last 5 ms; then normalized to PEAK. */
export function finish(b: Buf, pk: number, loop: boolean): Buf {
  for (let i = 0; i < b.length; i++) if (!Number.isFinite(b[i])) b[i] = 0;
  if (!loop) {
    onepole(b, 'hp', 15);
    const n = b.length, f = Math.min(n, 240);
    for (let i = 0; i < f; i++) b[n - 1 - i] *= i / f;
  }
  return normalize(b, pk);
}
