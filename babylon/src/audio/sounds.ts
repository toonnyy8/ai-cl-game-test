// sounds.ts <- duel/lisp/sounds.lisp (+ the character sounds of ichigo-art.lisp and senjumaru-art.lisp): SOUL DUEL's sound
// bank, every SFX and the two music loops described with synth.ts and rendered once (index.ts renders them in the
// background, one per macrotask). No samples, no voices. Keys and recipes as the Lisp's DEFSOUNDs.
import {
  type Buf, RATE, ar, buf, delay, drive, finish, fnoise, fold, frac, gong, midi, mix, noise, normalize,
  partials, ping, render, reverb, reverse, rnd, rrange, saw, saws, seedNoise, shaku, sin, svf, sweep, taiko, thump, whoosh,
} from './synth';

export interface SoundDef { peak: number; loop?: boolean; fn: () => Buf }
const DT = 1 / RATE;

/** Roaring flame body: noise band-limited to LO..HI Hz with a slow random flutter. */
function fireNoise(secs: number, lo: number, hi: number, { decay = 0.3, attack = 0.02, hold = 0 } = {}): Buf {
  const b = noise(secs, { attack, hold, decay });
  svf(b, 'lp', hi); svf(b, 'hp', lo);
  let m = 0.5, target = 0.5;
  for (let i = 0; i < b.length; i++) {
    if (i % 1200 === 0) target = 0.55 + 0.45 * rnd();
    m += 0.002 * (target - m); b[i] *= m;
  }
  return b;
}

export const SOUNDS: Record<string, SoundDef> = {
  // ---------------------------------------------------------------- blades and bodies
  'whoosh-light': { peak: 0.6, fn: () => partials(whoosh(0.26, 1000, 6500, 1.3, 0.07), 0.04, [[3300, 0.12, 0.08], [5100, 0.08, 0.06]]) },
  'whoosh-heavy': { peak: 0.8, fn: () => mix(whoosh(0.45, 350, 4200, 1.0, 0.12), whoosh(0.42, 110, 480, 1.4, 0.12), 0, 0.7) },
  'whoosh-cleaver': { peak: 0.9, fn: () => {
    const b = whoosh(0.75, 70, 900, 0.9, 0.3);
    mix(b, whoosh(0.7, 40, 200, 1.6, 0.3), 0, 0.9);
    thump(b, 0.3, 70, 40, 0.1, 0.15, 0.35);
    return drive(b, 1.6);
  } },
  cut: { peak: 0.85, fn: () => {
    const b = buf(0.35);
    thump(b, 0, 150, 55, 0.05, 0.07, 1.0);
    mix(b, drive(fnoise(0.15, 'hp', 1800, { decay: 0.03 }), 3), 0, 0.7);
    mix(b, fnoise(0.3, 'bp', 900, { to: 350, q: 3, decay: 0.06 }), 0.004, 0.5);
    return partials(b, 0, [[4200, 0.15, 0.05], [6100, 0.1, 0.04]]);
  } },
  'cut-heavy': { peak: 0.95, fn: () => {
    const b = buf(0.7);
    thump(b, 0, 110, 36, 0.08, 0.16, 1.0);
    thump(b, 0.01, 60, 30, 0.1, 0.25, 0.6);
    mix(b, drive(fnoise(0.3, 'lp', 2600, { decay: 0.06 }), 5), 0, 0.8);
    mix(b, fnoise(0.06, 'hp', 3000, { decay: 0.01 }), 0, 0.6);
    mix(b, fnoise(0.45, 'bp', 600, { to: 200, q: 3, decay: 0.1 }), 0.01, 0.5);
    return drive(b, 1.5);
  } },
  punch: { peak: 0.95, fn: () => {
    const b = buf(0.6);
    thump(b, 0, 95, 32, 0.07, 0.2, 1.0);
    mix(b, drive(fnoise(0.12, 'lp', 1500, { decay: 0.03 }), 4), 0, 0.9);
    mix(b, fnoise(0.5, 'lp', 300, { decay: 0.15 }), 0, 0.5);
    return drive(b, 1.8);
  } },
  clang: { peak: 0.8, fn: () => {
    const b = buf(0.9);
    partials(b, 0, [[710, 1.0, 0.28], [722, 0.5, 0.25], [1930, 0.7, 0.2], [3510, 0.5, 0.13], [5800, 0.35, 0.09], [8400, 0.2, 0.05]]);
    mix(b, fnoise(0.03, 'hp', 3000, { decay: 0.004 }), 0, 1.2);
    return drive(b, 1.3);
  } },
  'guard-break': { peak: 0.95, fn: () => {
    const b = buf(1.2);
    thump(b, 0, 120, 40, 0.06, 0.2, 0.9);
    partials(b, 0, [[560, 0.8, 0.3], [1490, 0.6, 0.22], [2870, 0.5, 0.15]]);
    for (let i = 0; i < 30; i++) ping(b, rrange(0, 0.5), rrange(2500, 9000), rrange(0.01, 0.05), 0.3 * (1 - i / 34));   // glassy shards
    mix(b, fnoise(0.4, 'hp', 2000, { decay: 0.08 }), 0, 0.6);
    return reverb(b, 0.25);
  } },
  'breaker-hum': { peak: 0.5, loop: true, fn: () => {        // a 1 s loop (+0.4 s for the crossfade): a beating electric hum
    const b = buf(1.4);
    let p1 = 0, p2 = 0, p3 = 0;
    render(b, (tt) => {
      p1 = frac(p1 + 110 * DT); p2 = frac(p2 + 111.5 * DT); p3 = frac(p3 + 330 * DT);
      return (0.8 + 0.2 * sin(6 * tt)) * (0.4 * saw(p1) + 0.4 * saw(p2) + 0.2 * sin(p3));
    });
    svf(b, 'lp', 1400, 1400, 2.0);
    mix(b, svf(noise(1.4, { hold: 1.4, decay: 1.0 }), 'bp', 3000, 3000, 2), 0, 0.05);
    return fold(b, RATE, true);
  } },
  clash: { peak: 0.95, fn: () => {
    const b = buf(1.4);
    partials(b, 0, [[880, 1.0, 0.5], [893, 0.6, 0.45], [2430, 0.7, 0.35], [4750, 0.4, 0.22], [7860, 0.25, 0.12]]);
    thump(b, 0, 80, 30, 0.1, 0.35, 1.0);
    mix(b, fnoise(0.6, 'lp', 400, { decay: 0.2 }), 0, 0.7);
    for (let i = 0; i < 20; i++) ping(b, rrange(0.02, 0.6), rrange(3000, 9000), rrange(0.02, 0.06), 0.3);
    drive(b, 1.4);
    return reverb(b, 0.3, 1.1);
  } },
  // ---------------------------------------------------------------- movement
  step: { peak: 0.5, fn: () => thump(whoosh(0.22, 500, 2200, 1.3, 0.06), 0.16, 110, 70, 0.02, 0.03, 0.4) },
  'hoho-out': { peak: 0.6, fn: () => ping(whoosh(0.28, 1500, 8000, 2.0, 0.05), 0, 1800, 0.08, 0.4, 0.001, 2.0) },
  'hoho-in': { peak: 0.7, fn: () => {
    const b = reverse(whoosh(0.25, 1500, 7000, 2.0, 0.05));
    thump(b, 0.22, 160, 80, 0.02, 0.05, 0.8);
    return mix(b, fnoise(0.05, 'hp', 4000, { decay: 0.01 }), 0.22, 0.5);
  } },
  perfect: { peak: 0.8, fn: () => {
    const b = buf(1.4);
    partials(b, 0, [[1318, 1.0, 0.5], [2637, 0.5, 0.4], [3951, 0.3, 0.3]]);
    partials(b, 0.08, [[1976, 0.9, 0.6], [3951, 0.4, 0.45], [5927, 0.2, 0.3]]);
    return reverb(b, 0.4, 1.2);
  } },
  launch: { peak: 0.8, fn: () => thump(whoosh(0.4, 300, 2400, 1.2, 0.08), 0, 130, 60, 0.05, 0.08, 1.0) },
  land: { peak: 0.75, fn: () => {
    const b = buf(0.35);
    thump(b, 0, 85, 40, 0.05, 0.08, 1.0);
    mix(b, fnoise(0.25, 'lp', 900, { decay: 0.05 }), 0, 0.7);
    return mix(b, fnoise(0.2, 'hp', 2500, { decay: 0.05 }), 0.005, 0.25);
  } },
  // ---------------------------------------------------------------- fire
  'fire-whoosh': { peak: 0.75, fn: () => mix(whoosh(0.6, 200, 2500, 0.8, 0.2), fireNoise(0.6, 80, 900, { attack: 0.08, decay: 0.2 }), 0, 0.8) },
  'fire-roar': { peak: 0.9, fn: () => {
    const b = fireNoise(1.4, 50, 1400, { attack: 0.15, hold: 0.4, decay: 0.35 });
    mix(b, whoosh(1.3, 150, 700, 0.8, 0.4), 0, 0.8);
    for (let i = 0; i < 40; i++) mix(b, fnoise(0.03, 'hp', 2500, { decay: 0.004 }), rrange(0, 1.2), rrange(0.1, 0.35));
    return drive(b, 1.6);
  } },
  'fire-crackle': { peak: 0.45, loop: true, fn: () => {       // a 2 s loop (+0.5 s for the crossfade): a soft roar bed + pops
    const b = buf(2.5);
    mix(b, normalize(fireNoise(2.5, 60, 700, { hold: 2.5, decay: 1.0 }), 0.35), 0, 1.0);
    for (let i = 0; i < 70; i++)
      mix(b, fnoise(0.03, 'bp', rrange(1500, 6000), { q: 1.5, decay: rrange(0.002, 0.008) }), rrange(0, 2.45), rrange(0.15, 0.6));
    return fold(b, 2 * RATE, true);
  } },
  'fire-wave': { peak: 0.9, fn: () => {
    const b = fireNoise(1.3, 40, 1000, { attack: 0.05, hold: 0.3, decay: 0.35 });
    mix(b, whoosh(1.2, 120, 1800, 0.9, 0.25), 0, 0.9);
    thump(b, 0, 70, 35, 0.2, 0.3, 0.5);
    return drive(b, 1.5);
  } },
  explode: { peak: 0.95, fn: () => {
    const b = buf(1.5);
    thump(b, 0, 70, 22, 0.25, 0.45, 1.0);
    mix(b, drive(fnoise(0.25, 'lp', 3000, { decay: 0.05 }), 5), 0, 0.8);
    mix(b, fireNoise(1.5, 30, 800, { attack: 0.01, decay: 0.4 }), 0, 0.9);
    for (let i = 0; i < 16; i++) mix(b, fnoise(0.05, 'bp', rrange(1500, 5000), { q: 2, decay: 0.01 }), rrange(0.05, 0.9), 0.2);
    drive(b, 1.6);
    return reverb(b, 0.2, 1.2);
  } },
  sizzle: { peak: 0.7, fn: () => {
    const b = fnoise(0.8, 'hp', 3500, { to: 6000, attack: 0.005, hold: 0.1, decay: 0.2 });
    thump(b, 0, 200, 90, 0.03, 0.05, 0.5);
    return mix(b, fnoise(0.6, 'bp', 1200, { q: 4, decay: 0.1 }), 0, 0.3);
  } },
  'heat-flare': { peak: 0.85, fn: () => {
    const b = fnoise(1.2, 'hp', 2200, { to: 5000, attack: 0.02, hold: 0.25, decay: 0.55 });
    thump(b, 0, 90, 35, 0.12, 0.3, 1.0);
    mix(b, fireNoise(0.9, 60, 600, { attack: 0.04, decay: 0.35 }), 0, 0.45);
    return drive(b, 1.3);
  } },
  'ground-crack': { peak: 0.95, fn: () => {
    const b = buf(1.3);
    thump(b, 0, 60, 25, 0.15, 0.4, 1.0);
    for (let i = 0; i < 24; i++)                                   // splitting stone: dry clicks + crunches
      mix(b, fnoise(0.06, 'bp', rrange(400, 2500), { q: 2, decay: rrange(0.005, 0.02) }), (i / 24) * rrange(0.6, 0.9), rrange(0.3, 0.7));
    mix(b, fnoise(1.2, 'lp', 250, { decay: 0.4 }), 0, 0.6);
    return drive(b, 1.5);
  } },
  bones: { peak: 0.75, fn: () => {
    const b = buf(0.8);
    for (let i = 0; i < 22; i++) {                                 // hollow wooden knocks
      const at = rrange(0, 0.6), f = rrange(700, 1600);
      ping(b, at, f, 0.02, 0.6); ping(b, at, f * 2.7, 0.012, 0.3);
    }
    return mix(b, fnoise(0.7, 'bp', 900, { q: 1.2, decay: 0.2 }), 0, 0.2);
  } },
  // ---------------------------------------------------------------- Kikon, Konpaku, awakening
  'kikon-slash': { peak: 0.95, fn: () => {                        // a reverse swell leads in; the cut lands at 0.35 s
    const b = buf(1.5), hit = 0.35;
    const swell = reverse(reverb(fnoise(0.9, 'bp', 1500, { q: 0.8, decay: 0.03 }), 1.0, 1.3, 0.3, 0.85));
    mix(b, normalize(swell, 0.6), hit - swell.length / RATE);
    mix(b, whoosh(0.3, 600, 7000, 1.2, 0.05), hit - 0.05, 0.8);
    partials(b, hit, [[2600, 0.5, 0.3], [4100, 0.4, 0.25], [6300, 0.3, 0.15]]);
    thump(b, hit, 80, 28, 0.2, 0.35, 1.0);
    mix(b, drive(fnoise(0.2, 'lp', 2500, { decay: 0.04 }), 4), hit, 0.6);
    return reverb(b, 0.25, 1.3);
  } },
  'konpaku-shatter': { peak: 0.85, fn: () => {
    const b = buf(1.0);
    partials(b, 0, [[1780, 0.6, 0.25], [2950, 0.5, 0.2], [4600, 0.4, 0.15]]);
    for (let i = 0; i < 36; i++) ping(b, rrange(0, 0.35), rrange(3000, 11000), rrange(0.008, 0.04), 0.35 * (1 - i / 40));
    mix(b, fnoise(0.3, 'hp', 5000, { decay: 0.05 }), 0, 0.7);
    return reverb(b, 0.3);
  } },
  'awaken-boom': { peak: 0.95, fn: () => {
    const b = buf(1.5);
    thump(b, 0, 55, 20, 0.3, 0.6, 1.0);
    taiko(b, 0, 0.8, 60);
    gong(b, 0.02, 98, 0.45, 0.8);
    mix(b, fnoise(1.2, 'lp', 200, { decay: 0.5 }), 0, 0.6);
    return drive(b, 1.4);
  } },
  'awaken-rise': { peak: 0.85, fn: () => {
    const b = buf(1.5), pad = buf(1.5);
    let p1 = 0, p2 = 0;
    render(pad, (tt) => {
      const f = sweep(tt, 55, 220, 1.4);
      p1 = frac(p1 + f * DT); p2 = frac(p2 + 1.502 * f * DT);
      return tt * tt * 0.45 * (saw(p1) + 0.6 * saw(p2));
    });
    svf(pad, 'lp', 300, 5000, 1.5, 1.4);
    mix(b, pad, 0, 0.8);
    return mix(b, whoosh(1.5, 300, 6000, 1.0, 1.4), 0, 0.5);
  } },
  evolution: { peak: 0.7, fn: () => {
    const b = buf(0.9);
    [880, 1318, 1760, 2637].forEach((f, i) => ping(b, i * 0.06, f, 0.2, 0.6, 0.003));
    return reverb(b, 0.35);
  } },
  laugh: { peak: 0.8, fn: () => {                                 // "ha-ha-ha": four formant-filtered saw bursts, falling
    const b = buf(1.3);
    ([[0, 150], [0.22, 142], [0.44, 136], [0.68, 124]] as const).forEach(([at, f]) => {
      const g = buf(0.26);
      let ph = 0;
      render(g, (tt) => { ph = frac(ph + f * (1 + 0.05 * sin(18 * tt)) * DT); return ar(tt, 0.02, 0.07) * (saw(ph) + 0.3 * rnd()); });
      mix(b, svf(g.slice(), 'bp', 750, 750, 5), at, 1.0);
      mix(b, svf(g.slice(), 'bp', 1200, 1200, 6), at, 0.6);
    });
    drive(b, 1.5);
    return reverb(b, 0.15);
  } },
  gulp: { peak: 0.75, fn: () => {
    const b = buf(0.45);
    thump(b, 0, 120, 55, 0.05, 0.14, 1.0);
    mix(b, fnoise(0.18, 'bp', 420, { q: 3, decay: 0.06 }), 0.03, 0.6);
    return mix(b, fnoise(0.12, 'bp', 900, { q: 5, decay: 0.03 }), 0.12, 0.35);
  } },
  'arm-crack': { peak: 0.8, fn: () => {
    const b = buf(0.5);
    for (let i = 0; i < 8; i++)                                    // the creak: low dry clicks
      mix(b, fnoise(0.05, 'bp', rrange(180, 500), { q: 4, decay: rrange(0.01, 0.03) }), i * 0.03, rrange(0.4, 0.7));
    mix(b, fnoise(0.08, 'bp', 2200, { q: 1.5, decay: 0.02 }), 0.26, 1.0);   // the crack
    return thump(b, 0.26, 140, 60, 0.04, 0.1, 0.8);
  } },
  'arm-burst': { peak: 0.95, fn: () => {
    const b = buf(1.0);
    thump(b, 0, 90, 35, 0.1, 0.3, 1.0);
    mix(b, fnoise(0.15, 'bp', 1800, { q: 1.2, decay: 0.04 }), 0, 0.9);
    for (let i = 0; i < 14; i++)                                   // the spray
      mix(b, fnoise(0.04, 'bp', rrange(600, 3000), { q: 2, decay: 0.015 }), rrange(0.02, 0.4), rrange(0.2, 0.5));
    mix(b, fnoise(0.6, 'lp', 700, { decay: 0.25 }), 0.03, 0.5);
    return drive(b, 1.6);
  } },
  'yachiru-call': { peak: 0.7, fn: () => {                        // two voices a few cents apart, each note doubled
    const b = buf(1.2);
    for (const [at, f] of [[0, 1318], [0, 1396], [0.18, 1760], [0.18, 1864], [0.36, 1318], [0.36, 1245]]) ping(b, at, f, 0.18, 0.5, 0.02);
    return reverb(b, 0.45, 1.4);
  } },
  // ---------------------------------------------------------------- Rukia's ice
  'frost-tick': { peak: 0.6, fn: () => {
    const b = buf(0.5);
    ping(b, 0, 3520, 0.08, 0.7, 0.001);
    ping(b, 0.01, 5270, 0.05, 0.4, 0.001);
    mix(b, fnoise(0.06, 'hp', 7000, { decay: 0.02 }), 0, 0.4);
    return reverb(b, 0.3, 1.2);
  } },
  freeze: { peak: 0.85, fn: () => {
    const b = buf(0.8);
    for (let i = 0; i < 26; i++)                                   // the crackle, tightening
      mix(b, fnoise(0.03, 'bp', rrange(2500, 9000), { q: 3, decay: rrange(0.004, 0.012) }), 0.3 * Math.sqrt(i / 26), rrange(0.3, 0.7));
    partials(b, 0.3, [[2093, 0.5, 0.3], [3136, 0.4, 0.25], [4186, 0.3, 0.2]]);   // the lock: a hard glassy chord
    thump(b, 0.3, 180, 90, 0.02, 0.08, 0.5);
    return reverb(b, 0.25);
  } },
  'ice-rise': { peak: 0.85, fn: () => {
    const b = buf(1.4);
    mix(b, whoosh(1.0, 400, 9000, 1.4, 0.9), 0, 0.6);
    [1760, 2637, 3520].forEach((f, i) => ping(b, 0.12 * i, f, 0.5, 0.35, 0.05));
    gong(b, 0, 196, 0.4, 1.2);
    return reverb(b, 0.35, 1.3);
  } },
  'ice-shatter': { peak: 0.9, fn: () => {
    const b = buf(1.0);
    mix(b, fnoise(0.12, 'hp', 3000, { decay: 0.04 }), 0, 0.9);
    for (let i = 0; i < 40; i++) ping(b, rrange(0, 0.5), rrange(2500, 10000), rrange(0.01, 0.05), 0.4 * (1 - i / 45));
    thump(b, 0, 120, 50, 0.05, 0.12, 0.6);
    return reverb(b, 0.3);
  } },
  'hand-crack': { peak: 0.7, fn: () => {
    const b = buf(0.4);
    mix(b, fnoise(0.05, 'bp', 3200, { q: 2, decay: 0.012 }), 0, 1.0);
    mix(b, fnoise(0.04, 'bp', 1800, { q: 3, decay: 0.01 }), 0.05, 0.6);
    return ping(b, 0.02, 4700, 0.03, 0.3);
  } },
  'rift-open': { peak: 0.6, fn: () => {
    const b = buf(0.7);
    mix(b, whoosh(0.5, 1800, 9000, 2.0, 0.35), 0, 0.7);
    partials(b, 0.05, [[3100, 0.3, 0.4], [4700, 0.2, 0.3]]);
    return reverb(b, 0.2);
  } },
  'rift-cut': { peak: 0.9, fn: () => {
    const b = buf(0.8);
    mix(b, whoosh(0.2, 800, 8000, 1.2, 0.03), 0, 0.8);
    partials(b, 0.03, [[2400, 0.5, 0.25], [5200, 0.35, 0.15]]);
    thump(b, 0.03, 90, 30, 0.1, 0.2, 0.8);
    return reverb(b, 0.2);
  } },
  'tier-up': { peak: 0.85, fn: () => {
    const b = buf(1.0);
    taiko(b, 0, 0.8, 70);
    mix(b, whoosh(0.6, 300, 5000, 1.0, 0.5), 0, 0.5);
    return drive(b, 1.3);
  } },
  // ---------------------------------------------------------------- Ichigo (ichigo-art.lisp)
  'chain-rattle': { peak: 0.7, fn: () => {                        // link clatter: the parry, the wall, a chain shot
    const b = buf(0.6);
    for (let i = 0; i < 18; i++) {
      const at = rrange(0, 0.35);
      ping(b, at, rrange(1800, 4200), rrange(0.02, 0.05), rrange(0.2, 0.45), 0.001);
      mix(b, fnoise(0.02, 'bp', rrange(2500, 6000), { q: 3, decay: 0.008 }), at, 0.3);
    }
    return reverb(b, 0.2);
  } },
  'chain-snap': { peak: 0.85, fn: () => {                         // a taut snap: a catch, the yank, the pull's hit
    const b = buf(0.5);
    mix(b, fnoise(0.03, 'bp', 3000, { q: 2, decay: 0.01 }), 0, 1.0);
    ping(b, 0, 2600, 0.06, 0.5, 0.001);
    ping(b, 0.01, 3900, 0.04, 0.35, 0.001);
    thump(b, 0, 140, 60, 0.02, 0.08, 0.5);
    return reverb(b, 0.15);
  } },
  getsuga: { peak: 0.9, fn: () => {                               // a deep tearing whoosh with a low resonance
    const b = buf(1.1);
    mix(b, whoosh(0.6, 200, 5000, 1.1, 0.25), 0, 0.9);
    mix(b, fnoise(0.4, 'bp', 900, { q: 1.5, decay: 0.2 }), 0.1, 0.5);
    thump(b, 0.12, 70, 40, 0.1, 0.35, 0.7);
    partials(b, 0.1, [[110, 0.4, 0.6], [165, 0.25, 0.5]]);
    return reverb(b, 0.3, 1.2);
  } },
  clone: { peak: 0.6, fn: () => {                                 // a glassy shimmer: a clone appears / slashes
    const b = buf(0.7);
    mix(b, whoosh(0.4, 2000, 9000, 2.0, 0.3), 0, 0.5);
    [1568, 2093, 2637].forEach((f, i) => ping(b, 0.05 * i, f, 0.3, 0.3, 0.02));
    return reverb(b, 0.35, 1.3);
  } },
  'parry-ting': { peak: 0.9, fn: () => {                          // the catch: a bright high kiin
    const b = buf(0.8);
    ping(b, 0, 3200, 0.6, 0.9, 0.001);
    ping(b, 0, 6400, 0.35, 0.4, 0.001);
    ping(b, 0.005, 4800, 0.2, 0.25, 0.001);
    mix(b, fnoise(0.02, 'bp', 7000, { q: 2, decay: 0.006 }), 0, 0.5);
    return reverb(b, 0.35, 1.4);
  } },
  'parry-open': { peak: 0.4, fn: () => {                          // the window opens: a soft rising shimmer
    const b = buf(0.4);
    mix(b, whoosh(0.3, 1500, 6000, 2.5, 0.2), 0, 0.5);
    [2093, 2637, 3136].forEach((f, i) => ping(b, 0.06 * i, f, 0.18, 0.2, 0.02));
    return reverb(b, 0.25);
  } },
  // ---------------------------------------------------------------- Senjumaru (senjumaru-art.lisp)
  'thread-zip': { peak: 0.6, fn: () => {                          // a fast thread pull: a rising hiss with a taut tick
    const b = buf(0.35);
    mix(b, whoosh(0.18, 2500, 9000, 3.0, 0.05), 0, 0.8);
    ping(b, 0.16, 3950, 0.03, 0.4, 0.001);
    return mix(b, fnoise(0.03, 'hp', 6000, { decay: 0.01 }), 0.17, 0.5);
  } },
  'needle-burst': { peak: 0.9, fn: () => {                        // a dense metallic spray
    const b = buf(0.9);
    for (let i = 0; i < 30; i++) ping(b, rrange(0, 0.25), rrange(3500, 9000), rrange(0.02, 0.08), 0.35 * (1 - i / 34), 0.001);
    mix(b, fnoise(0.12, 'hp', 4000, { decay: 0.05 }), 0, 0.7);
    thump(b, 0, 160, 70, 0.04, 0.1, 0.5);
    return reverb(b, 0.25);
  } },
  shuttle: { peak: 0.7, fn: () => {                               // a wooden loom clack
    const b = buf(0.4);
    mix(b, fnoise(0.03, 'bp', 900, { q: 4, decay: 0.012 }), 0, 1.0);
    thump(b, 0, 420, 240, 0.02, 0.05, 0.7);
    mix(b, fnoise(0.02, 'bp', 1600, { q: 5, decay: 0.008 }), 0.06, 0.5);
    return reverb(b, 0.12, 0.6);
  } },
  'cloth-unfurl': { peak: 0.8, fn: () => {                        // a heavy cloth whoosh
    const b = buf(0.9);
    mix(b, whoosh(0.6, 180, 2200, 0.9, 0.25), 0, 0.9);
    for (let i = 0; i < 6; i++) mix(b, fnoise(0.05, 'bp', rrange(400, 1200), { q: 2, decay: 0.03 }), 0.1 + 0.07 * i, 0.35);
    thump(b, 0.5, 90, 50, 0.06, 0.15, 0.5);
    return reverb(b, 0.2);
  } },
  shears: { peak: 0.85, fn: () => {                               // a heavy snip
    const b = buf(0.6);
    mix(b, fnoise(0.08, 'bp', 3200, { q: 2, decay: 0.03 }), 0, 0.6);
    partials(b, 0.07, [[1900, 0.4, 0.2], [3100, 0.3, 0.15], [5200, 0.2, 0.1]]);
    thump(b, 0.07, 200, 90, 0.02, 0.08, 0.7);
    return reverb(b, 0.2);
  } },
  'candle-out': { peak: 0.6, fn: () => {                          // a soft puff with a low bell tail
    const b = buf(1.6);
    mix(b, fnoise(0.15, 'lp', 1200, { attack: 0.02, decay: 0.08 }), 0, 0.7);
    gong(b, 0.08, 196, 0.35, 1.3);
    return reverb(b, 0.4, 1.4);
  } },
  // ---------------------------------------------------------------- stingers and menus
  bell: { peak: 0.8, fn: () => {
    const b = buf(1.5);
    partials(b, 0, [[196, 1.0, 1.2], [392, 0.5, 0.9], [466, 0.35, 0.7], [587, 0.4, 0.6], [784, 0.3, 0.45], [1046, 0.2, 0.3]], 0.998);
    return mix(b, fnoise(0.05, 'lp', 1200, { decay: 0.01 }), 0, 0.4);
  } },
  fight: { peak: 0.95, fn: () => {
    const b = buf(1.5);
    taiko(b, 0, 1.0, 72); taiko(b, 0.16, 0.9, 90);
    gong(b, 0.16, 110, 0.5, 0.7);
    return reverb(b, 0.25, 1.1);
  } },
  ko: { peak: 0.95, fn: () => {
    const b = buf(1.5);
    taiko(b, 0, 1.0, 60);
    thump(b, 0, 50, 22, 0.3, 0.5, 0.8);
    gong(b, 0, 73, 0.7, 1.0);
    return reverb(b, 0.35, 1.3);
  } },
  select: { peak: 0.35, fn: () => ping(ping(buf(0.08), 0, 2200, 0.012, 1.0), 0, 3300, 0.008, 0.3) },
  confirm: { peak: 0.5, fn: () => {
    const b = buf(0.35);
    ping(b, 0, 880, 0.05, 1.0, 0.002);
    ping(b, 0.06, 1318, 0.09, 1.0, 0.002);
    return ping(b, 0.06, 2637, 0.05, 0.3);
  } },
  back: { peak: 0.45, fn: () => ping(ping(buf(0.25), 0, 1318, 0.04, 1.0, 0.002), 0.05, 880, 0.07, 1.0, 0.002) },
  // ---------------------------------------------------------------- music
  music: { peak: 0.8, loop: true, fn: () => {
    // 100 BPM, 8 bars of 16ths = 128 steps x 0.15 s = 19.2 s, D phrygian
    const step = 0.15, n = Math.round(128 * step * RATE), len = 21.7;
    const b = buf(len), bass = buf(len), lead = buf(len), kick = buf(0.5);
    const hat = fnoise(0.06, 'hp', 7000, { decay: 0.012 }), rim = fnoise(0.05, 'bp', 2500, { q: 2, decay: 0.008 });
    thump(kick, 0, 150, 45, 0.05, 0.18, 1.0);
    ping(rim, 0, 1600, 0.02, 0.8);
    for (let s = 0; s < 128; s++) {                                // taiko on the downbeats, a driving kick, rims, hats
      const bar = Math.floor(s / 16), p = s % 16, at = s * step;
      if ([0, 3, 8, 11].includes(p)) mix(b, kick, at, p === 0 || p === 8 ? 0.9 : 0.6);
      if (p === 0) taiko(b, at, 1.0, bar % 2 === 0 ? 68 : 76);
      if (p === 10 && bar % 2 === 1) taiko(b, at, 0.6, 90);
      if (bar === 7 && p >= 12) taiko(b, at, 0.5 + 0.1 * (p - 12), 100);
      if (p === 4 || p === 12) mix(b, rim, at, 0.55);
      if (p % 2 === 0) mix(b, hat, at, [2, 6, 10, 14].includes(p) ? 0.3 : 0.15);
    }
    [38, 39, 38, 36].forEach((r, i) => { const f = midi(r); saws(bass, i * 32 * step, 4.6, [f, 1.5 * f, 2 * f], 1.0, 0.3, 0.5); });
    svf(bass, 'lp', 380, 380, 1.2);
    for (let i = 0; i < bass.length; i++) {                        // pump after every beat
      const sb = 0.6 * frac(i * DT / 0.6);
      bass[i] *= 1 - 0.5 * Math.exp(-sb / 0.12);
    }
    mix(b, normalize(bass), 0, 0.6);
    for (const [s, l, m] of [[0, 6, 62], [6, 2, 63], [8, 8, 65], [20, 4, 67], [24, 8, 65], [32, 4, 63], [36, 4, 62], [40, 14, 62],
      [64, 3, 69], [67, 3, 70], [70, 10, 69], [84, 4, 67], [88, 8, 65], [96, 6, 63], [102, 2, 65], [104, 16, 62]])
      shaku(lead, s * step, l * step, midi(m), 0.5);
    delay(lead, 3 * step, 0.3, 0.25);
    reverb(lead, 0.5, 1.3, 0.3, 0.82);
    mix(b, normalize(lead), 0, 0.45);
    return fold(b, n);
  } },
  'music-title': { peak: 0.7, loop: true, fn: () => {
    // 60 BPM, 4 bars = 16 s: gong swells, koto-ish plucks over a soft pad, a slow shakuhachi line
    const n = 16 * RATE, len = 18.5, b = buf(len), pad = buf(len), pluck = buf(len), lead = buf(len);
    gong(b, 0, 73, 0.6, 1.3); gong(b, 8, 82, 0.45, 1.2);
    taiko(b, 0, 0.5, 60); taiko(b, 8, 0.4, 60);
    saws(pad, 0, 8.4, [50, 57, 62, 65].map(midi), 1.0, 1.5, 1.5);
    saws(pad, 8, 8.4, [48, 55, 60, 64].map(midi), 1.0, 1.5, 1.5);
    svf(pad, 'lp', 900, 900, 0.9);
    mix(b, normalize(pad), 0, 0.35);
    for (const [bt, m] of [[0, 62], [0.5, 69], [1, 74], [2, 72], [2.5, 69], [3, 67], [4, 62], [4.5, 65], [5, 69], [6, 67], [7, 65],
      [8, 60], [8.5, 67], [9, 72], [10, 70], [10.5, 67], [11, 65], [12, 62], [12.5, 65], [13, 69], [14, 74], [15, 72]]) {
      const note = buf(1.2), f = midi(m);
      let ph = 0;
      render(note, (tt) => { ph = frac(ph + f * DT); return ar(tt, 0.002, 0.35) * saw(ph); });
      svf(note, 'lp', 4000, 600, 1.5, 0.6);
      mix(pluck, note, bt, 0.35);
    }
    delay(pluck, 0.75, 0.3, 0.3);
    mix(b, pluck, 0, 0.6);
    for (const [bt, l, m] of [[1, 3, 74], [4, 2, 72], [6, 2, 69], [8.5, 3, 67], [12, 1.5, 69], [13.5, 2, 62]]) shaku(lead, bt, l, midi(m), 0.5, 0.018);
    reverb(lead, 0.55, 1.4, 0.3, 0.84);
    mix(b, normalize(lead), 0, 0.4);
    return fold(b, n);
  } },
};

/** Render sound KEY: its recipe (noise reseeded from the key), NaN-free, one-shots DC-blocked and end-faded, normalized. */
export function renderSound(key: string): Buf {
  const d = SOUNDS[key];
  let h = 2166136261;
  for (let i = 0; i < key.length; i++) h = Math.imul(h ^ key.charCodeAt(i), 16777619);
  seedNoise(h);
  return finish(d.fn(), d.peak, !!d.loop);
}


/** The background render order: the menu clicks and the title loop first, the battle loop last. */
const FIRST = ['select', 'confirm', 'back', 'music-title'];
export const BANK_ORDER = [...FIRST, ...Object.keys(SOUNDS).filter((k) => !FIRST.includes(k) && k !== 'music'), 'music'];
