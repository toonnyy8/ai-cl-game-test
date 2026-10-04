// cine-scripts.ts: the shot scripts of every cinematic in the sim's CINES table (src/sim/match.ts owns their lengths and
// the frame-0 / AT face-each-other beats), translated from the Lisp DEFCINEs (duel/lisp/cinema.lisp, yama.lisp, ken.lisp,
// rukia.lisp, ichigo-art.lisp, senjumaru.lisp; engine/lisp/cine.lisp for the director). A script is data on the cine
// frame CF (render/cinema.ts plays it from w.cine each rendered frame, so the sim is the clock and a skip loses nothing):
//   shots   consecutive [frames, camera, look] whose frames sum to the cine's len (test/cinema.test.ts); a camera is a
//           rail relative to the actors (ON: SHOT-ON's angle round the actor's facing / distance / height / look / ahead /
//           off; PAIR: SHOT-PAIR; a number pair [from, to] is lerped across the shot), null = the gameplay shot frozen
//   caps    the brush caption cards (vfx/card.ts) shown [from, to) on the screen side 'L' / 'R'
//   imp     impact frames (negative, two-tone, manga, spot: cinema.ts's grade post) [frame, kind, frames]
//   grade   the base grade from a frame on ('spot': Yamamoto's grey world; 'desat' with an amount)
//   hold    pose holds [frame, frames] (both actors' clip time stops)
//   act     the actors' poses from a frame: a move name sampled from sf FROM to TO across the act, 'P:<pose>' a library
//           pose, 'stun:<reaction>', 'win' / 'lose' / 'idle'
//   form    body / weapon swaps: the form shown from a frame (null: the sim's own)
//   aura    the aura preset from a frame (null: none, '': the form's own)
//   gone / tint / flash   an actor hidden from a frame, tinted or flashed white over [from, to)
//   ui / focus / splash / shake / sparks / hz   the screen and world punctuation; hz = hazard looks (vfx/hazards.ts)
//           posed by the script (fire walls, ice rings, Ichigo's clones ...), age = frames since FROM; not on a card
//           (an empty page) unless CARD
//   over    a 2D overlay ('forest': Kenpachi's Kusajishi card; 'vs': the intro's last beat)
// No Babylon imports: the scripts are tested headless.
import type { Cap } from './vfx/card';

export type Who = 'a' | 'v';
export interface Actor { pos: ArrayLike<number>; yaw: number }
/** The actors and the side (+1 / -1) of the A -> V line the gameplay camera is on (Lisp CAMERA-SIDE). */
export interface Ctx { a: Actor; v: Actor; side: number }
export type V3 = [number, number, number];
export interface View3 { eye: V3; at: V3; close?: boolean }
export type Cam = (c: Ctx, u: number) => View3;
export interface Look { fov?: number; roll?: number; card?: 'black' | 'white' | number; only?: Who; rim?: number; sil?: Who }
export type Shot = [n: number, cam: Cam | null, look?: Look];
export type Act = [frame: number, what: string, from?: number, to?: number];
export type Impact = 'negative' | 'two-tone' | 'manga' | 'spot';
export interface HzSpec { from: number; to: number; kind: string; look?: string; size: number; data?: unknown; card?: boolean;
  at: (c: Ctx, cf: number) => [x: number, z: number, yaw: number] }
export interface Script {
  shots: Shot[];
  caps?: [from: number, to: number, side: 'L' | 'R', cap?: Cap | Who][];
  imp?: [number, Impact, number][];
  grade?: [number, 'spot' | 'desat' | null, number?][];
  hold?: [number, number][];
  act?: { a?: Act[]; v?: Act[] };
  form?: { a?: [number, string | null][]; v?: [number, string | null][] };
  aura?: { a?: [number, string | null][]; v?: [number, string | null][] };
  gone?: { a?: number; v?: number };
  tint?: [Who, number, number, [number, number, number, number]][];
  flash?: [Who, number, number][];
  ui?: [number, number][];
  focus?: [number, number][];
  splash?: [number, number, Who, number][];
  shake?: [number, number, number][];
  sparks?: Spark[];
  hz?: HzSpec[];
  over?: 'forest' | 'vs';
}

type N = number | [number, number];
const L = (x: N, u: number) => (typeof x === 'number' ? x : x[0] + (x[1] - x[0]) * u);
const D2R = Math.PI / 180;
const fx = (yaw: number) => -Math.sin(yaw), fz = (yaw: number) => -Math.cos(yaw);   // the sim's forward (yaw 0 faces -z)

/** SHOT-ON: the camera ANG degrees round W's facing (0 = in front of him), DIST away, H high, looking at his body LOOK up,
 *  AHEAD metres in front of him; OFF > 0 puts him in the right part of the frame (< 0: the left), the other third for a
 *  caption. */
export function on(w: Who, ang: N, dist: N, h: N, o: { look?: N; ahead?: number; off?: number } = {}): Cam {
  return (c, u) => {
    const e = c[w], p = e.pos, yaw = e.yaw + L(ang, u) * D2R, d = L(dist, u), ah = o.ahead ?? 0, off = o.off ?? 0;
    const tx = p[0] + ah * fx(e.yaw) - off * fz(yaw), tz = p[2] + ah * fz(e.yaw) + off * fx(yaw);
    return { eye: [tx + d * fx(yaw), L(h, u), tz + d * fz(yaw)], at: [tx, L(o.look ?? 1.1, u), tz], close: d <= 5 };
  };
}
/** SHOT-PAIR: both actors from SIDE of the A -> V line ('cam': the gameplay camera's, '-cam' the other), DIST from their
 *  midpoint, H high. */
export function pair(side: number | 'cam' | '-cam', dist: N, h: N): Cam {
  return (c, u) => {
    const p = c.a.pos, q = c.v.pos, s = side === 'cam' ? c.side : side === '-cam' ? -c.side : side;
    const mx = 0.5 * (p[0] + q[0]), mz = 0.5 * (p[2] + q[2]), dx = q[0] - p[0], dz = q[2] - p[2];
    const l = Math.max(0.01, Math.hypot(dx, dz)), d = L(dist, u);
    return { eye: [mx + (s * d * -dz) / l, L(h, u), mz + (s * d * dx) / l], at: [mx, 1.1, mz] };
  };
}
/** Ichigo's Getsuga cameras: A's feet, the unit vector to V and the distance (IC-LINE-FROM). */
function line(c: Ctx): [number, number, number, number, number] {
  const p = c.a.pos, q = c.v.pos, dx = q[0] - p[0], dz = q[2] - p[2], d = Math.max(0.5, Math.hypot(dx, dz));
  return [p[0], p[2], dx / d, dz / d, d];
}
const at = (w: Who, ahead = 0, side = 0) => (c: Ctx): [number, number, number] => {
  const e = c[w];
  return [e.pos[0] + ahead * fx(e.yaw) - side * fz(e.yaw), e.pos[2] + ahead * fz(e.yaw) + side * fx(e.yaw), e.yaw];
};
const toward = (k: number, f0: number, n: number) => (c: Ctx, cf: number): [number, number, number] => {   // a -> v, by K at F0+N
  const u = Math.min(1, Math.max(0, (cf - f0) / n)) * k;
  return [c.a.pos[0] + (c.v.pos[0] - c.a.pos[0]) * u, c.a.pos[2] + (c.v.pos[2] - c.a.pos[2]) * u, c.a.yaw];
};

/** The intro's name columns (brush.lisp *BRUSH-NAMES*; kits' intro callouts are added at run time). */
export const NAMES: Record<string, [string, string]> = {
  yamamoto: ['山本元柳斎重國', 'YAMAMOTO GENRYUSAI SHIGEKUNI'], kenpachi: ['更木剣八', 'ZARAKI KENPACHI'],
  rukia: ['朽木ルキア', 'KUCHIKI RUKIA'], ichigo: ['黒崎一護', 'KUROSAKI ICHIGO'], senjumaru: ['修多羅千手丸', 'SHUTARA SENJUMARU'],
};

const WHITE = 0xe8edf4, YELLOW = 0xffd93b, BLOOD = 0xd10f1c;
type Spark = [number, 'hit' | 'block' | 'kikon', Who, number, number?, number?];
/** The Konpaku shatter on the victim at frame F. */
const shatter = (f: number): Spark[] => [[f, 'kikon', 'v', 3.4, 0.8, 1.1], [f, 'hit', 'v', 2.2, 0.4, 1.2]];

// Ichigo's 千影: four waves of three clones charging through him, then six at once (the Lisp's twelve, halved: each is a
// skinned body; ponytail: raise when the ghost pool is cheaper).
function clones(): HzSpec[] {
  const out: HzSpec[] = [], mvs = ['ic-k-j1', 'ic-k-j3', 'ic-k-k1'];
  const charge = (ang: number, start: number, speed: number, k: number) => {
    const n = Math.ceil((10 / speed) * 60);                                   // from 9 m out to 1 m past him
    out.push({ from: start, to: start + n, kind: 'clone', look: 'ichigo-clone-look', size: 1, card: true, data: { mv: mvs[k % 3], sf: 12 },
      at: (c, cf) => { const r = 9 - speed * ((cf - start) / 60), q = c.v.pos;
        return [q[0] + r * Math.cos(ang), q[2] + r * Math.sin(ang), Math.atan2(Math.cos(ang), Math.sin(ang))]; } });
  };
  for (let w = 0; w < 4; w++) for (let i = 0; i < 3; i++) charge(0.5 + Math.PI + 2 * Math.PI * ((8 + 16 * w) / 80) + (i - 1) * 0.6, 30 + 16 * w, 22, w + i);
  for (let i = 0; i < 6; i++) charge(i * (Math.PI / 3), 96, 45, i);
  // (data.mv is a move NAME here: cinema.ts resolves it)
  return out;
}

export const SCRIPTS: Record<string, Script> = {
  // ---------------------------------------------------------------- generic (cinema.lisp)
  'soul-break-cine': {
    shots: [[6, null], [22, on('v', 60, 3.4, 0.8, { look: 0.9, off: -0.7 }), { fov: 50, roll: -6 }],
      [12, on('v', 60, 1.9, 0.45, { look: 0.9 }), { fov: 82 }], [20, on('v', 60, 1.9, 0.45, { look: 0.9 }), { fov: 55 }],
      [36, pair(1, 7.0, 2.2), { fov: 50 }]],
    caps: [[6, 60, 'R']], hold: [[0, 6], [28, 12]],
    imp: [[0, 'negative', 2], [40, 'negative', 2], [42, 'manga', 10]],
    act: { a: [[0, 'idle']], v: [[0, 'stun:crumple']] },
    sparks: shatter(40), shake: [[40, 0.15, 18]],
  },
  'intro-cine': {
    shots: [[120, on('a', [25, 45], [3.6, 3.0], 1.5, { look: 1.2, off: -0.7 }), { fov: 50 }],
      [120, on('v', [-25, -45], [3.6, 3.0], 1.5, { look: 1.2, off: 0.7 }), { fov: 50 }],
      [60, pair('cam', [6, 8], 2.4), { fov: 50 }]],
    caps: [[0, 120, 'R', 'a'], [120, 240, 'L', 'v']], imp: [[120, 'negative', 2]],
    act: { a: [[0, 'P:win'], [80, 'idle']], v: [[0, 'idle'], [120, 'P:win'], [200, 'idle']] }, over: 'vs',
  },
  'ko-cine': {
    shots: [[20, on('a', 30, 3.0, 0.8, { look: 1.3, off: -0.8 }), { fov: 42 }],
      [130, on('v', [40, 90], [5.0, 3.8], [1.0, 1.6], { look: 0.8 }), { fov: 55 }]],
    caps: [[0, 150, 'R']], imp: [[0, 'two-tone', 3]], hold: [[0, 20]],
    act: { a: [[0, 'win']], v: [[0, 'lose']] },
  },
  'time-cine': {
    shots: [[120, pair('cam', [8, 9], 2.6), { fov: 50 }]], caps: [[0, 120, 'L']], imp: [[0, 'negative', 2]],
    act: { a: [[0, 'idle']], v: [[0, 'idle']] },
  },

  // ---------------------------------------------------------------- Yamamoto (yama.lisp): white haori on the black card
  'yama-kikon-cine': {
    shots: [[12, null], [58, on('a', 25, 2.9, 0.7, { look: 1.3, off: -0.8 }), { fov: 45, roll: 10, card: 'black', only: 'a' }],
      [30, pair('cam', 7.5, 3.6), { fov: 50 }], [20, on('v', 150, 3.8, 0.35, { look: 1.4 }), { fov: 88 }],
      [22, on('v', 150, [3.6, 3.0], [0.4, 0.45], { look: 1.4 }), { fov: 70 }],
      [14, on('v', 150, 3.0, 0.45, { look: 1.4 }), { fov: 70 }], [30, pair('-cam', 9.0, 1.6), { fov: 48 }]],
    caps: [[12, 100, 'R']], hold: [[0, 12], [120, 22]],
    imp: [[0, 'negative', 2], [142, 'negative', 2], [144, 'manga', 12]],
    act: { a: [[0, 'ya-kikon', 0, 22], [142, 'ya-kikon', 22, 52]], v: [[0, 'stun:stagger'], [142, 'stun:crumple']] },
    hz: [{ from: 70, to: 150, kind: 'pillars', size: 1.7, at: at('v') }],      // the walls of fire round him (not on the card)
    sparks: shatter(142), splash: [[142, 16, 'v', 0.07]], shake: [[142, 0.3, 24]],
  },
  'yama-tenchi-cine': {
    shots: [[12, null], [56, on('a', 70, 3.2, 0.9, { look: 1.2, off: 0.8 }), { fov: 42, roll: -8, card: 'black', only: 'a', rim: WHITE }],
      [42, pair(1, 5.0, 1.4), { fov: 55 }], [58, on('a', -35, 4.6, 0.5, { look: 1.3 }), { fov: 48 }]],
    caps: [[12, 110, 'L']], hold: [[0, 12]], grade: [[0, 'spot']],
    imp: [[0, 'negative', 2], [68, 'two-tone', 4], [72, 'manga', 12]],
    act: { a: [[0, 'ya-tenchi', 0, 6], [68, 'ya-tenchi', 6, 34]], v: [[0, 'stun:stagger']] },
    hz: [{ from: 68, to: 168, kind: 'line', look: 'kyokko', size: 12, at: at('a', -2) }],   // the hard white slash
    gone: { v: 86 }, sparks: [[86, 'block', 'v', 3.0, 0.7, 1.0], ...shatter(86)], splash: [[86, 14, 'v', 0.07]],
    shake: [[86, 0.2, 18]],
  },
  'yama-bankai-cine': {
    shots: [[12, null], [28, on('a', 25, 1.5, 0.45, { look: 1.45 }), { fov: 88, roll: 6 }],
      [20, on('a', 200, 3.0, 0.8, { look: 1.4 }), { fov: 50 }],
      [58, on('a', 15, 4.4, 0.6, { look: 1.25, off: 0.9 }), { fov: 40, card: 'white', only: 'a', sil: 'a' }],
      [20, on('a', -30, 6.5, 1.6, { look: 1.1 }), { fov: 50 }]],
    caps: [[60, 118, 'L']], hold: [[0, 12]], grade: [[44, 'spot']],
    imp: [[0, 'negative', 2], [60, 'negative', 2]],
    act: { a: [[0, 'P:hold'], [60, 'idle']], v: [[0, 'idle']] },
    form: { a: [[0, 'base'], [60, null]] }, aura: { a: [[0, 'hellfire'], [60, null], [118, '']] },
    focus: [[12, 36]], sparks: [[12, 'kikon', 'a', 2.6, 0.6, 1.0], [118, 'kikon', 'a', 3.6, 0.8, 0.6]],
    hz: [[0, 0], [3.5, -2.0], [-3.0, 2.5]].map(([ox, oz], i): HzSpec => ({ from: 118, to: 138, kind: 'crack', size: 3 - 0.3 * i,
      at: (c) => [c.a.pos[0] + ox, c.a.pos[2] + oz, c.a.yaw + i * 1.9] })),
    shake: [[60, 0.25, 24]],
  },

  // ---------------------------------------------------------------- Kenpachi (ken.lisp): black robe on the white card
  'ken-kikon-cine': {
    shots: [[12, null], [58, on('a', 30, 3.0, 0.6, { look: 1.4, off: -0.8 }), { fov: 44, roll: -12, card: 'white', only: 'a' }],
      [28, on('v', 120, 3.8, 1.2), { fov: 55 }], [24, on('v', -110, 3.6, 1.0), { fov: 55 }],
      [20, on('a', 20, [1.5, 1.9], 0.5, { look: 1.45 }), { fov: 86 }],
      [20, pair('-cam', 5.5, 1.3), { fov: 55 }], [30, on('a', 160, 4.2, 0.8, { look: 1.3 }), { fov: 50 }]],
    caps: [[12, 98, 'R']], hold: [[0, 12], [122, 20]],
    imp: [[0, 'negative', 2], [142, 'negative', 2], [144, 'manga', 12]],
    act: { a: [[0, 'ke-kikon', 0, 8], [64, 'ke-kikon', 8, 14], [86, 'ke-kikon', 2, 14], [110, 'ke-kikon', 2, 8], [140, 'ke-kikon', 8, 36]],
      v: [[0, 'stun:stagger'], [142, 'stun:crumple']] },
    sparks: [[70, 'hit', 'v', 1.6, 0.3, 1.2], [98, 'hit', 'v', 1.6, 0.3, 1.2], ...shatter(142)],
    flash: [['v', 70, 76], ['v', 98, 104]], splash: [[142, 16, 'v', 0.07]], shake: [[142, 0.3, 21]],
  },
  'ken-sky-split-cine': {
    shots: [[12, null], [56, on('a', 60, 4.2, 0.7, { look: 1.6, ahead: 1.3, off: 0.4 }), { fov: 46, roll: 8, card: 'black', only: 'a', rim: YELLOW }],
      [34, on('a', 180, 10.0, 3.6, { look: 1.2, ahead: 5.0 }), { fov: 60 }],
      [30, on('v', 95, 7.5, 1.2, { look: 1.0 }), { fov: 50 }], [30, on('a', -20, 5.0, 0.7, { look: 1.4 }), { fov: 45 }]],
    caps: [[12, 102, 'L']], hold: [[0, 12], [68, 12]],
    imp: [[0, 'negative', 2], [68, 'negative', 2], [70, 'manga', 12]],
    act: { a: [[0, 'ke-kikon-n', 0, 11], [68, 'ke-kikon-n', 11, 38]], v: [[0, 'stun:stagger'], [68, 'stun:crumple']] },
    hz: [{ from: 68, to: 162, kind: 'line', look: 'kyokko', size: 16, at: at('a', -3) },   // the cut down the plaza ...
      { from: 68, to: 102, kind: 'rift', size: 1, at: (c) => [c.v.pos[0] - 2.9 * fx(c.a.yaw), c.v.pos[2] - 2.9 * fz(c.a.yaw), c.a.yaw] }],  // ... and the sky
    focus: [[68, 30]], sparks: [[68, 'hit', 'v', 2.4, 0.4, 1.2], ...shatter(68)], flash: [['v', 68, 74]], shake: [[68, 0.4, 30]],
  },
  'ken-nozarashi-cine': {
    shots: [[28, on('a', 10, 1.9, 1.9, { look: 1.85 }), { fov: 50 }],
      [30, on('a', 0, 4.6, 0.8, { look: 1.6 }), { fov: 52, card: 'black', only: 'a', rim: YELLOW }],
      [20, on('a', 30, 1.6, 0.45, { look: 1.5 }), { fov: 86, roll: -8 }],
      [30, on('a', 20, 4.4, 0.8, { look: 1.3, off: 0.9 }), { fov: 42, card: 'white', only: 'a' }]],
    caps: [[78, 108, 'L']], hold: [[0, 10]],
    imp: [[0, 'negative', 2], [26, 'negative', 2], [78, 'negative', 2], [80, 'manga', 10]],
    act: { a: [[0, 'P:hold'], [26, 'P:heavyWind'], [54, 'P:hold'], [78, 'idle']], v: [[0, 'idle']] },
    form: { a: [[0, 'base'], [78, null]] }, aura: { a: [[0, 'reiatsu'], [26, 'nozarashi'], [28, 'nomihose'], [58, 'reiatsu']] },
    hz: [{ from: 26, to: 62, kind: 'ring', look: 'senju-zone-look', data: { hank: 0 }, size: 7, at: at('a') }],
    sparks: [[26, 'kikon', 'a', 3.0, 0.6, 1.0]], shake: [[26, 0.2, 18]],
  },
  'ken-bankai-cine': {
    shots: [[12, on('a', 35, 3.0, 0.7, { look: 0.9, off: -0.7 }), { fov: 50, roll: -6 }],
      [46, on('a', 20, 3.6, 0.8, { look: 0.9, off: -1.0 }), { fov: 44, card: 'white', only: 'a' }],
      [20, on('a', 25, 5.2, 1.0, { look: 1.6 }), { fov: 55 }], [30, on('a', 14, 1.05, 1.5, { look: 1.58 }), { fov: 80, roll: -8 }],
      [58, on('a', 20, 4.4, 0.8, { look: 1.3, off: 0.9 }), { fov: 42, card: 'black', only: 'a', rim: BLOOD }],
      [20, on('a', 165, 5.6, 1.7, { look: 1.4 }), { fov: 50 }]],
    caps: [[12, 58, 'R', { kanji: '草鹿', reading: 'KUSAJISHI', sub: 'KEN-CHAN' }], [108, 166, 'L']],
    imp: [[0, 'negative', 2], [58, 'negative', 1], [60, 'manga', 12]], hold: [[0, 12]],
    act: { a: [[0, 'P:kneel'], [58, 'P:hold'], [108, 'idle']], v: [[0, 'idle']] },
    form: { a: [[0, 'nozarashi'], [58, null]] }, aura: { a: [[0, null], [58, 'oni']] },
    hz: [{ from: 58, to: 90, kind: 'ring', look: 'senju-zone-look', data: { hank: 5 }, size: 7, at: at('a') },
      { from: 58, to: 84, kind: 'gulp', size: 4, at: at('a') }],
    sparks: [[58, 'kikon', 'a', 3.6, 0.8, 1.0]], splash: [[0, 10, 'a', 0.05]], shake: [[58, 0.25, 21]], over: 'forest',
  },
  'ken-oni-kikon-cine': {
    shots: [[12, null], [56, on('a', 60, 4.2, 0.7, { look: 1.6, ahead: 1.3, off: 0.4 }), { fov: 46, roll: 8, card: 'black', only: 'a', rim: BLOOD }],
      [34, on('v', 0, 5.5, 1.3, { look: 1.1 }), { fov: 55 }],
      [30, on('v', 95, 7.5, 1.2, { look: 1.0 }), { fov: 50 }], [30, on('a', 60, 4.6, 0.7, { look: 1.4 }), { fov: 45 }]],
    caps: [[12, 102, 'L']], hold: [[0, 12], [68, 12]],
    imp: [[0, 'negative', 2], [68, 'negative', 2], [70, 'manga', 12]],
    act: { a: [[0, 'ke-b-kikon', 0, 11], [68, 'ke-b-kikon', 11, 38], [132, 'P:hold']], v: [[0, 'stun:stagger'], [68, 'stun:crumple']] },
    aura: { a: [[0, null]] },                                                   // (the pillar smoulders out: the cut reads)
    hz: [{ from: 68, to: 162, kind: 'line', look: 'kyokko', size: 16, at: at('a', -3) },
      { from: 68, to: 102, kind: 'rift', size: 1, at: (c) => [c.v.pos[0] - 2.9 * fx(c.a.yaw), c.v.pos[2] - 2.9 * fz(c.a.yaw), c.a.yaw] }],
    focus: [[68, 30]], sparks: [[68, 'hit', 'v', 2.4, 0.4, 1.2], ...shatter(68)], flash: [['v', 68, 74]],
    splash: [[68, 16, 'v', 0.08]], shake: [[68, 0.45, 30]],
  },

  // ---------------------------------------------------------------- Rukia (rukia.lisp): white card; the Bankai on black
  'ru-kikon-cine': {
    shots: [[12, null], [58, on('a', 30, 3.0, 0.6, { look: 1.1, off: -0.8 }), { fov: 44, roll: -10, card: 'white', only: 'a' }],
      [30, pair('cam', 8.0, 5.2), { fov: 50 }], [28, on('v', 150, 5.5, 0.3, { look: 1.8 }), { fov: 82 }],
      [22, on('v', 150, [3.8, 3.0], [0.5, 0.6], { look: 1.4 }), { fov: 70 }],
      [20, on('v', 150, 3.0, 0.6, { look: 1.4 }), { fov: 70 }], [16, on('a', 160, 5.0, 1.0, { look: 1.2 }), { fov: 48 }]],
    caps: [[12, 70, 'R']], hold: [[0, 12], [128, 22]],
    imp: [[0, 'negative', 2], [150, 'negative', 2], [152, 'manga', 12]],
    act: { a: [[0, 'ru-kikon', 4, 35], [60, 'idle']], v: [[0, 'stun:stagger']] },
    hz: [{ from: 70, to: 170, kind: 'ring', look: 'rukia-ring-look', size: 1.8, at: at('v') },
      { from: 100, to: 152, kind: 'pillar', look: 'rukia-pillar-look', size: 2.2, at: at('v') }],
    flash: [['v', 104, 110]], gone: { v: 150 },
    sparks: [[150, 'block', 'v', 3.2, 0.8, 1.0], ...shatter(150)], splash: [[150, 14, 'v', 0.07]], shake: [[150, 0.25, 21]],
  },
  'ru-hakka-cine': {
    shots: [[12, null], [18, on('a', 25, 1.8, 0.5, { look: 1.3 }), { fov: 84, roll: 6 }],
      [58, on('a', 20, 4.2, 0.8, { look: 1.1, off: 0.9 }), { fov: 42, card: 'black', only: 'a', rim: WHITE }],
      [30, on('a', 140, 7.0, 0.4, { look: 3.0 }), { fov: 70 }],
      [18, on('a', 165, 2.4, 1.5, { look: 1.1, ahead: 2.6, off: 0.3 }), { fov: 58 }],
      [38, on('v', 30, 3.6, 0.9, { look: 1.1 }), { fov: 64 }],
      [24, on('a', 40, 1.6, 1.2, { look: 1.1 }), { fov: 40 }]],                     // close on her, the hand
    caps: [[30, 88, 'L']], hold: [[0, 12], [136, 20]],
    imp: [[0, 'negative', 2], [156, 'negative', 1], [158, 'manga', 12]],
    act: { a: [[0, 'ru-hakka', 0, 12], [118, 'ru-hakka', 20, 23], [136, 'ru-hakka', 23, 53], [174, 'idle']], v: [[0, 'stun:stagger']] },
    aura: { a: [[0, null], [174, '']] }, tint: [['a', 24, 174, [0.94, 0.97, 1.0, 0.45]]], ui: [[24, 3]],
    hz: [{ from: 88, to: 198, kind: 'freeze', size: 6, at: at('a') },
      { from: 88, to: 118, kind: 'pillar', look: 'rukia-pillar-look', size: 2.6, at: at('a') },
      { from: 118, to: 156, kind: 'line', look: 'rukia-sheet-look', size: 3, at: (c) => { const [px, pz, ux, uz, d] = line(c);
        return [px + ux * (0.5 * d + 1.5), pz + uz * (0.5 * d + 1.5), c.a.yaw]; } },
      { from: 136, to: 156, kind: 'pillar', look: 'rukia-pillar-look', size: 1.0, at: at('v') }],
    flash: [['v', 136, 156]], gone: { v: 156 },
    sparks: [[156, 'block', 'v', 3.2, 0.8, 1.0], ...shatter(156)], shake: [[156, 0.2, 18]],
  },
  'ru-awaken-cine': {
    shots: [[12, null], [26, on('a', 12, 1.3, 1.45, { look: 1.32 }), { fov: 70 }],
      [24, on('a', 170, 3.2, 0.35, { look: 0.8 }), { fov: 76, roll: -6 }],
      [54, on('a', 20, 4.4, 0.8, { look: 1.1, off: 0.9 }), { fov: 42, card: 'white', only: 'a' }],
      [16, on('a', -30, 6.0, 1.4, { look: 1.1 }), { fov: 50 }]],
    caps: [[62, 116, 'L']], hold: [[0, 12]], imp: [[0, 'negative', 2], [62, 'negative', 2]],
    act: { a: [[0, 'P:guard']], v: [[0, 'idle']] },
    hz: [{ from: 38, to: 132, kind: 'freeze', size: 4, at: at('a') }],
    sparks: [[12, 'block', 'a', 0.7, 0.6, 1.25], [116, 'block', 'a', 0.7, 0.6, 1.25]], shake: [[62, 0.15, 18]],
  },

  // ---------------------------------------------------------------- Ichigo (ichigo-art.lisp)
  'ic-kikon-cine': {
    shots: [[12, on('a', 60, 3.6, 1.1, { look: 1.1 }), { fov: 50 }],
      [58, on('a', 30, 3.2, 0.7, { look: 1.1, off: -0.8 }), { fov: 44, roll: -8, card: 'white', only: 'a' }],
      [30, on('a', 40, 4.6, 0.5, { look: 2.3 }), { fov: 46, card: 'black', only: 'a' }],
      [28, on('a', 40, 4.6, 0.5, { look: 2.3 }), { fov: 52, card: 'black', only: 'a' }],
      [10, on('a', 90, 4.2, 1.2, { look: 1.3 }), { fov: 46 }],
      [22, on('a', 200, 5.2, 0.5, { look: 2.6, off: 0.8 }), { fov: 36, card: 0xf0d9db }],    // the pale pink sky
      [12, on('v', 150, 5.0, 1.2, { look: 1.3 }), { fov: 58 }], [14, on('a', 170, 5.2, 1.0, { look: 1.2 }), { fov: 48 }]],
    caps: [[12, 70, 'R']], hold: [[0, 12]],
    imp: [[0, 'negative', 2], [132, 'negative', 2], [160, 'negative', 2], [162, 'manga', 12]],
    act: { a: [[0, 'ic-kikon', 7, 8], [70, 'P:heavyWind'], [128, 'ic-getsuga', 12, 30], [172, 'idle']],
      v: [[0, 'stun:stagger'], [160, 'stun:crumple']] },
    aura: { a: [[0, ''], [100, 'evolution'], [128, '']] },                     // his body swallowed in gold flame
    hz: [{ from: 138, to: 162, kind: 'wave', look: 'ichigo-getsuga-look', size: 3.5, card: true, at: toward(1, 136, 22) },
      { from: 160, to: 172, kind: 'burst', look: 'ichigo-burst-look', size: 1.5, at: at('v') }],
    sparks: [[100, 'kikon', 'a', 2.0, 0.5, 2.0], [160, 'hit', 'v', 2.4, 0.4, 1.3], ...shatter(160)],
    splash: [[160, 14, 'v', 0.08]], shake: [[160, 0.3, 24]],
  },
  'ic-kessa-kikon-cine': {
    shots: [[12, on('a', 60, 3.8, 1.1, { look: 1.1 }), { fov: 50 }],
      [18, on('v', 30, 5.0, 1.2, { look: 1.2 }), { fov: 50, card: 'black', only: 'v' }],
      [80, (c, u) => { const q = c.v.pos, an = 0.5 + 2 * Math.PI * u;                // orbiting him, one turn
        return { eye: [q[0] + 5 * Math.cos(an), 1.6, q[2] + 5 * Math.sin(an)], at: [q[0], 1.1, q[2]] }; }, { fov: 40, card: 'black', only: 'v' }],
      [10, (c) => { const q = c.v.pos, an = 0.5; return { eye: [q[0] + 5 * Math.cos(an), 1.6, q[2] + 5 * Math.sin(an)], at: [q[0], 1.1, q[2]] }; }, { fov: 50 }],
      [56, on('a', 155, 3.2, 0.55, { look: 1.3, off: -0.5 }), { fov: 50, card: 'black', rim: BLOOD }],
      [16, on('a', 150, 7.0, 2.0, { look: 1.4 }), { fov: 50 }]],
    caps: [[120, 176, 'R']], hold: [[0, 12]], ui: [[110, 10]],
    imp: [[0, 'negative', 2], [124, 'negative', 2], [126, 'manga', 12]],
    act: { a: [[0, 'ic-k-kikon', 7, 8], [120, 'idle']], v: [[0, 'stun:stagger'], [100, 'stun:knockback'], [120, 'stun:crumple']] },
    hz: clones(), sparks: [[34, 'hit', 'v', 1.2, 0.25, 1.1], [50, 'hit', 'v', 1.2, 0.25, 1.1], [66, 'hit', 'v', 1.2, 0.25, 1.1],
      [82, 'hit', 'v', 1.2, 0.25, 1.1], [100, 'hit', 'v', 2.4, 0.4, 1.1], ...shatter(124)],
    shake: [[100, 0.2, 18], [124, 0.3, 24]],
  },
  'ic-kessa-getsuga-cine': {
    shots: [[12, on('a', 60, 4.0, 1.1, { look: 1.1 }), { fov: 50 }], [36, on('a', 20, 3.6, 0.6, { look: 2.2 }), { fov: 60 }],
      [52, on('a', 20, 4.2, 0.9, { look: 1.1, off: 0.9 }), { fov: 42, card: 'black', only: 'a', rim: BLOOD }],
      [12, (c, u) => { const [px, pz, ux, uz, d] = line(c), mx = px + 0.5 * d * ux * u, mz = pz + 0.5 * d * uz * u;   // wide, side-on
        return { eye: [mx - 14 * uz, 2.6, mz + 14 * ux], at: [mx, 2.4, mz] }; }, { fov: 40 }],
      [28, (c, u) => { const [px, pz, ux, uz, d] = line(c), k = 0.84 * d - 0.5 * u;                  // inside the C, looking back
        return { eye: [px + k * ux, 2.4, pz + k * uz], at: [px, 2.4, pz] }; }, { fov: 74 }],
      [20, on('v', 160, 5.0, 1.3, { look: 1.3 }), { fov: 58 }],
      [20, (c) => { const [px, pz, ux, uz, d] = line(c); return { eye: [px + 0.8 * d * ux, 2.4, pz + 0.8 * d * uz], at: [px, 2.4, pz] }; }, { fov: 74 }]],
    caps: [[48, 100, 'L']], hold: [[0, 12]],
    imp: [[0, 'negative', 2], [140, 'negative', 2], [142, 'manga', 12]],
    act: { a: [[0, 'ic-k-kikon', 8, 9], [12, 'P:heavyWind'], [100, 'ic-k-kikon', 7, 20], [160, 'idle']],
      v: [[0, 'stun:stagger'], [140, 'stun:crumple']] },
    aura: { a: [[12, 'kikon'], [48, '']] },                                    // the black glow gathering on the slab
    hz: [{ from: 100, to: 180, kind: 'wave', look: 'ichigo-getsuga-look', size: 3.2,      // the C hanging in the air
      at: (c) => { const [px, pz, ux, uz, d] = line(c); return [px + 0.5 * d * ux, pz + 0.5 * d * uz, c.a.yaw + Math.PI / 2]; } }],
    sparks: [[140, 'hit', 'v', 2.4, 0.4, 1.3], ...shatter(140)], splash: [[140, 14, 'v', 0.1]],
    shake: [[100, 0.35, 30], [140, 0.3, 24]],
  },
  'ic-kessa-cine': {
    shots: [[12, on('a', 30, 3.4, 1.0, { look: 1.0 }), { fov: 50 }], [28, on('a', 20, 1.3, 1.62, { look: 1.62 }), { fov: 70 }],
      [30, on('a', 40, 3.0, 0.5, { look: 1.1, off: 0.4 }), { fov: 64, roll: -4 }],
      [26, on('a', 170, 3.6, 0.35, { look: 1.0 }), { fov: 76, roll: -6 }],
      [54, on('a', 20, 4.4, 0.9, { look: 1.1, off: 0.9 }), { fov: 42, card: 'black', only: 'a', rim: BLOOD }],
      [18, on('a', -30, 6.0, 1.4, { look: 1.1 }), { fov: 50 }]],
    caps: [[96, 150, 'L']], hold: [[0, 12]], imp: [[0, 'negative', 2]], ui: [[58, 4]],
    act: { a: [[0, 'P:hold'], [58, 'P:win'], [96, 'idle']], v: [[0, 'idle']] },
    form: { a: [[0, 'base'], [58, null]] }, aura: { a: [[0, null], [70, 'ichigo-aura-kessa'], [96, null], [150, '']] },   // the blood chains burst
    sparks: [[70, 'kikon', 'a', 2.6, 0.6, 1.2]], shake: [[80, 0.15, 18]],
  },

  // ---------------------------------------------------------------- Senjumaru (senjumaru.lisp): white on the black card
  'sj-kikon-cine': {
    shots: [[12, null], [58, on('a', 20, 4.2, 0.9, { look: 1.25, off: 0.9 }), { fov: 42, card: 'black', only: 'a', rim: WHITE }],
      [30, on('v', 35, 3.2, 1.3, { look: 1.15 }), { fov: 55 }], [28, on('a', 25, 1.6, 1.35, { look: 1.45 }), { fov: 70 }],
      [22, on('v', 150, [3.8, 3.0], [0.5, 0.6], { look: 1.4 }), { fov: 70 }],
      [20, on('v', 150, 3.0, 0.6, { look: 1.4 }), { fov: 70 }], [16, on('a', 160, 5.0, 1.0, { look: 1.2 }), { fov: 48 }]],
    caps: [[12, 70, 'L']], hold: [[0, 12], [128, 22]],
    imp: [[0, 'negative', 2], [150, 'negative', 2], [152, 'manga', 12]],
    act: { a: [[0, 'sj-kikon', 8, 9], [70, 'sj-kikon', 9, 35], [100, 'P:palm'], [170, 'win']], v: [[0, 'stun:flinch'], [70, 'stun:stagger']] },
    tint: [['v', 92, 170, [1, 1, 1, 0.55]]],                                     // the robe re-tailored white
    hz: [{ from: 0, to: 12, kind: 'pin', look: 'senju-pin-look', size: 0.6, at: at('v') },
      { from: 70, to: 150, kind: 'thread', look: 'senju-tendril-look', size: 0.8, at: at('v', 0.2) },
      { from: 150, to: 172, kind: 'spike', look: 'senju-spike-look', size: 1.2, at: at('v') }],
    gone: { v: 170 }, sparks: shatter(150), shake: [[150, 0.25, 21]],
  },
  'sj-hata-cine': {
    shots: [[12, null], [28, on('v', 30, 3.6, 1.0, { look: 1.0 }), { fov: 52 }],
      [58, on('a', 20, 4.4, 0.9, { look: 1.4, off: 0.9 }), { fov: 42, card: 'black', only: 'a', rim: WHITE }],
      [28, on('a', 165, 4.5, 0.4, { look: 2.4 }), { fov: 72 }], [24, pair('cam', 5.5, 1.8), { fov: 55 }],
      [22, pair('cam', 5.5, 1.8), { fov: 55 }], [26, on('a', 25, 3.6, 1.1, { look: 1.3 }), { fov: 50 }]],
    caps: [[40, 98, 'L']], hold: [[0, 12]], imp: [[0, 'negative', 2], [150, 'manga', 12]],
    act: { a: [[0, 'sj-t-kikon', 0, 10], [98, 'P:hold'], [150, 'sj-t-kikon', 20, 53], [172, 'idle']], v: [[0, 'stun:flinch']] },
    hz: [{ from: 0, to: 40, kind: 'carpet', look: 'senju-carpet-look', size: 3.5, at: at('a', 1.75) },
      { from: 12, to: 150, kind: 'tapestry', look: 'senju-tapestry-look', size: 0.7, at: at('v') },
      { from: 98, to: 150, kind: 'torii', look: 'senju-soldier-look', size: 1, at: at('a', -1.6) },
      { from: 126, to: 150, kind: 'shears', look: 'senju-bolt-look', size: 1, at: at('v', 1.2) },
      { from: 150, to: 172, kind: 'bolt', look: 'senju-bolt-look', size: 1, at: at('v') }],
    gone: { v: 150 }, sparks: shatter(150), shake: [[150, 0.2, 18]],
  },
  'sj-tsuji-cine': {
    shots: [[12, null], [34, on('a', 12, 1.5, 1.35, { look: 1.35 }), { fov: 70 }],
      [34, on('a', 170, 5.5, 0.5, { look: 2.2 }), { fov: 76, roll: -6 }], [26, on('a', 30, 5.0, 1.2, { look: 1.3 }), { fov: 55 }],
      [56, on('a', 20, 4.4, 0.8, { look: 1.2, off: 0.9 }), { fov: 42, card: 'black', only: 'a', rim: WHITE }],
      [18, on('a', -30, 7.5, 2.0, { look: 1.1 }), { fov: 50 }]],
    caps: [[106, 162, 'L']], hold: [[0, 12]], imp: [[0, 'negative', 2]],
    grade: [[20, 'desat', 0.2], [30, 'desat', 0.4], [40, 'desat', 0.6], [162, null]],   // the three candles go out
    act: { a: [[0, 'P:hold'], [162, 'idle']], v: [[0, 'idle']] }, aura: { a: [[12, null], [162, '']] },
    hz: [{ from: 46, to: 180, kind: 'torii', look: 'senju-soldier-look', size: 1, at: (c) => { const [, , ux, uz] = line(c);
        return [c.v.pos[0] + 4 * ux, c.v.pos[2] + 4 * uz, c.a.yaw]; } },
      { from: 80, to: 180, kind: 'carpet', look: 'senju-carpet-look', size: 8, at: at('a', 4) }],
  },
};
