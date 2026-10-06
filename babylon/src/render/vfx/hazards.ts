// hazards.ts: every hazard's look in ink (docs/babylon/BABYLON_PORT.md "M5 look": effects in ink brush, few colours). A hazard
// maps (by kind / look name, LOOKS below) to an archetype: a painted 4-cell sheet (ink + a white channel tinted per
// character) on a small batch of quads built for that hazard (one mesh, one draw each), stepped at 12 fps. Spent
// hazards linger a few frames (their sim life is often 2 steps: binds, the maiden, rifts). Look-only: never reads back.
import { Mesh, VertexData, type DynamicTexture, type Scene, type StandardMaterial } from '@babylonjs/core';
import { T } from '../../sim/tuning';
import { TWO_PI } from '../../sim/math';
import type { Hazard } from '../../sim/types';
import { arc, blob, FPS, hex3, INK, inkMat, paintSheet, rnd, stroke, WHITE, type G } from './brush';

export type Arch = 'crescent' | 'cross' | 'ball' | 'flame' | 'cut' | 'ring' | 'shard' | 'splash' | 'figure' | 'hand' | 'thread';
const N = 4;

// ---------------------------------------------------------------- the painted sheets
const W2 = 'rgba(255,255,255,0.55)';
const PAINT: Record<Arch, [number, number, (g: G, i: number, w: number, h: number) => void]> = {
  // a flame / energy crescent bowed forward: the white body, an ink rim on its leading edge, a dry tail
  crescent: [256, 128, (g, i, w, h) => {
    const R = h * (1.45 + 0.05 * i), cy = h * 1.62, half = Math.asin(Math.min(0.95, (0.46 * w) / R)), top = 1.5 * Math.PI;
    for (let k = 0; k < 3; k++) stroke(g, arc(w / 2, cy + k * 8, R, top - half, top + half, 20, 0.015), h * (0.36 - 0.09 * k), k ? W2 : WHITE, 0.5);
    stroke(g, arc(w / 2, cy - 4, R, top - half * 0.95, top + half * 0.9, 20, 0.02), h * 0.07, INK, 0.65);
    for (let k = 0; k < 7; k++) blob(g, w * (0.12 + 0.76 * rnd()), h * (0.08 + 0.3 * rnd()), 1.5 + 3 * rnd(), INK);
  }],
  cross: [256, 256, (g, i, w) => {
    const c = w / 2, r = w * (0.4 + 0.02 * i);
    for (const s of [1, -1]) {
      stroke(g, [[c - s * r, c - r], [c - s * r * 0.1, c + r * 0.05 * i], [c + s * r, c + r]], w * 0.16, WHITE, 0.5);
      stroke(g, [[c - s * r * 0.95, c - r * 0.85], [c + s * r * 0.9, c + r * 0.95]], w * 0.035, INK, 0.75);
    }
  }],
  // a fireball: tongues swirling round an ink comma
  ball: [128, 128, (g, i, w) => {
    const c = w / 2, a0 = i * 1.4;
    for (let k = 0; k < 4; k++) {
      const a = a0 + (k * Math.PI) / 2;
      stroke(g, arc(c, c, w * 0.26, a, a + 2.2, 10, 0.08), w * 0.2, WHITE, 0.45);
    }
    stroke(g, arc(c, c, w * 0.12, a0, a0 + 4.2, 10, 0.05), w * 0.08, INK, 0.5);
  }],
  // upright tongues from the ground (pillars, fire walls, the maiden): white bodies, ink rims, dry tips
  flame: [128, 256, (g, i, w, h) => {
    for (let k = 0; k < 3; k++) {                                       // three tongues, the middle one tallest
      const x = w * (0.32 + 0.18 * k + 0.04 * Math.sin(i * 2 + k)), top = h * (k === 1 ? 0.06 : 0.3 + 0.12 * rnd());
      const sw = Math.sin(i * 1.7 + k * 2) * w * 0.1;
      stroke(g, [[x, h * 0.99], [x + sw, h * 0.6], [x - sw * 0.7, top]], w * (k === 1 ? 0.26 : 0.18), k === 1 ? WHITE : W2, 0.55);
      stroke(g, [[x + w * 0.07, h * 0.97], [x + sw + w * 0.06, h * 0.62], [x - sw * 0.5 + w * 0.03, top + h * 0.15]], w * 0.035, INK, 0.75);
    }
  }],
  // a long dry-brush cut: ink edges, a white core (u runs along the cut)
  cut: [512, 64, (g, i, w, h) => {
    const y = h / 2, wob = (k: number) => (Math.sin(k * 3 + i * 1.3) * h) / 14;
    stroke(g, [[4, y + wob(0)], [w * 0.35, y + wob(1)], [w * 0.7, y + wob(2)], [w - 4, y + wob(3)]], h * 0.85, INK, 0.45);
    stroke(g, [[10, y + wob(0)], [w * 0.4, y + wob(1)], [w * 0.75, y + wob(2)], [w - 20, y + wob(3)]], h * 0.42, WHITE, 0.6);
  }],
  // an enso on the ground: a white ring with an inner ink line, the gap wanders
  ring: [256, 256, (g, i, w) => {
    const c = w / 2, a0 = -1.0 + i * 1.57;
    stroke(g, arc(c, c, w * 0.4, a0, a0 + 5.6, 26, 0.02), w * 0.09, WHITE, 0.55);
    stroke(g, arc(c, c, w * 0.33, a0 + 0.5, a0 + 5.2, 26, 0.02), w * 0.025, INK, 0.7);
    for (let k = 0; k < 5; k++) blob(g, c + Math.cos(a0 + k) * w * 0.44, c + Math.sin(a0 + k) * w * 0.44, 2 + 3 * rnd(), INK);
  }],
  // an ice / needle shard: a white crystal with ink edges and a facet
  shard: [128, 256, (g, i, w, h) => {
    const c = w / 2 + (i - 1.5) * 3, top = h * 0.04 + i * 4;
    g.fillStyle = WHITE; g.beginPath(); g.moveTo(c, top); g.lineTo(c + w * 0.26, h * 0.62); g.lineTo(c + w * 0.12, h); g.lineTo(c - w * 0.14, h);
    g.lineTo(c - w * 0.24, h * 0.58); g.closePath(); g.fill();
    stroke(g, [[c, top], [c + w * 0.26, h * 0.62], [c + w * 0.12, h]], w * 0.07, INK, 0.5);
    stroke(g, [[c, top], [c - w * 0.24, h * 0.58], [c - w * 0.14, h]], w * 0.05, INK, 0.6);
    stroke(g, [[c, top + h * 0.1], [c + w * 0.02, h * 0.9]], w * 0.025, INK, 0.8);
  }],
  // a burst: white rays, an ink core, flecks
  splash: [256, 256, (g, i, w) => {
    const c = w / 2, a0 = i * 0.7;
    for (let k = 0; k < 8; k++) {
      const a = a0 + (k / 8) * TWO_PI + (rnd() - 0.5) * 0.4, r0 = w * 0.08, r1 = w * (0.3 + 0.15 * rnd() + 0.03 * i);
      stroke(g, [[c + Math.cos(a) * r0, c + Math.sin(a) * r0], [c + Math.cos(a) * r1, c + Math.sin(a) * r1]], w * 0.07, k % 3 ? WHITE : INK, 0.7);
    }
    blob(g, c, c, w * (0.07 - 0.01 * i), INK);
    for (let k = 0; k < 8; k++) { const a = rnd() * TWO_PI, r = w * (0.35 + 0.1 * rnd()); blob(g, c + Math.cos(a) * r, c + Math.sin(a) * r, 2 + 3 * rnd(), INK); }
  }],
  // a standing figure in ink (a soldier, a clone): an ink body, a white rim down one side
  figure: [128, 256, (g, i, w, h) => {
    const c = w / 2, sway = (i - 1.5) * 2;
    blob(g, c + sway, h * 0.1, w * 0.11, INK);                                       // the head, the shoulders, a robe
    g.fillStyle = INK; g.beginPath(); g.moveTo(c - w * 0.22 + sway, h * 0.19); g.lineTo(c + w * 0.22 + sway, h * 0.19);   // shoulders,
    g.lineTo(c + w * 0.11, h * 0.5); g.lineTo(c + w * 0.34, h * 0.97); g.lineTo(c - w * 0.34, h * 0.97); g.lineTo(c - w * 0.11, h * 0.5);  // waist, hem
    g.closePath(); g.fill();
    stroke(g, [[c - w * 0.2 + sway, h * 0.22], [c - w * 0.3, h * 0.42], [c - w * 0.22, h * 0.56]], w * 0.09, INK, 0.4);   // an arm
    stroke(g, [[c - w * 0.28, h * 0.98], [c, h * 0.9], [c + w * 0.3, h * 0.98]], w * 0.12, INK, 0.6);
    stroke(g, [[c + w * 0.2 + sway, h * 0.22], [c + w * 0.24, h * 0.62], [c + w * 0.26, h * 0.95]], w * 0.06, WHITE, 0.6);   // a lit edge
    stroke(g, [[c - w * 0.2, h * 0.25], [c + w * 0.44, h * 0.02]], w * 0.05, WHITE, 0.3);      // a raised blade / spear
  }],
  // a skeletal hand clawing out of the ground: ink fingers with white bones
  hand: [128, 256, (g, i, w, h) => {
    const c = w / 2, curl = 0.08 * i;
    stroke(g, [[c, h], [c, h * 0.6]], w * 0.3, INK, 0.3);
    for (let k = 0; k < 4; k++) {
      const x = c + (k - 1.5) * w * 0.13, tip = h * (0.12 + 0.05 * Math.abs(k - 1.5));
      stroke(g, [[x, h * 0.62], [x + (k - 1.5) * w * 0.05, h * 0.38], [x + w * curl * (k - 1.5), tip]], w * 0.09, INK, 0.4);
      stroke(g, [[x, h * 0.6], [x + (k - 1.5) * w * 0.04, h * 0.4]], w * 0.025, WHITE, 0.6);
    }
  }],
  // threads: thin wavy white lines with ink knots (Senjumaru's needlework)
  thread: [256, 128, (g, i, w, h) => {
    for (let k = 0; k < 5; k++) {
      const p: [number, number][] = [];
      for (let s = 0; s <= 12; s++) p.push([(s / 12) * w, h * (0.2 + 0.15 * k) + Math.sin(s * 0.9 + k + i * 1.2) * h * 0.08]);
      stroke(g, p, h * 0.06, k % 2 ? WHITE : W2, 0.3);
      blob(g, p[3 + k][0], p[3 + k][1], 3, INK);
    }
  }],
};

// ---------------------------------------------------------------- what each hazard looks like
const FIRE = 0xff7a2a, ICE = 0x9fd4ff, GOLD = 0xf5d54a, RED = 0xd42a1c, ASH = 0x9a9488, PALE = 0xf4f6fa, IC = 0x8fb8ff, MADDER = 0xc0484f;
const HANK = [GOLD, 0x9a82c8, 0xd8b860, 0x3a3a46, 0x8fb4d8, MADDER, 0x5a6aa6];   // Senjumaru's six hanks (dyes, brightened)
const LOOKS: Record<string, [Arch, number]> = {
  wave: ['crescent', FIRE], fireball: ['ball', FIRE], pillars: ['flame', FIRE], bind: ['ring', ASH], hand: ['hand', ASH],
  rift: ['cut', PALE], kyokko: ['cut', 0xfff2b0], kyoku: ['cut', FIRE], enjo: ['flame', FIRE], south: ['ring', ASH],
  crack: ['cut', 0x2a2a30], meteor: ['cut', 0x2a2a30], freeze: ['ring', ICE],
  'rukia-wave-look': ['crescent', ICE], 'rukia-spike-look': ['shard', ICE], 'rukia-burst-look': ['splash', ICE],
  'rukia-ring-look': ['ring', PALE], 'rukia-blade-look': ['cut', ICE], 'rukia-flower-look': ['splash', PALE],
  'rukia-quake-look': ['ring', ICE], 'rukia-pillar-look': ['shard', ICE], 'rukia-sheet-look': ['cut', ICE],
  'ichigo-getsuga-look': ['crescent', IC], 'ichigo-juji-look': ['cross', IC], 'ichigo-burst-look': ['splash', IC],
  'ichigo-form-look': ['splash', RED], 'ichigo-flare-look': ['splash', RED], 'ichigo-zanzo-look': ['figure', 0x30343c],
  'ichigo-clone-look': ['figure', RED], 'ichigo-echo-look': ['figure', RED],
  'senju-zone-look': ['ring', GOLD], 'senju-burst-look': ['splash', GOLD], 'senju-spike-look': ['shard', GOLD],
  'senju-tapestry-look': ['thread', MADDER], 'senju-soldier-look': ['figure', GOLD], 'senju-kasa-look': ['splash', GOLD],
  'senju-tendril-look': ['thread', RED], 'senju-pin-look': ['shard', RED], 'senju-carpet-look': ['cut', MADDER],
  'senju-bolt-look': ['cut', GOLD], maiden: ['flame', 0xc8ccd4], gulp: ['ring', 0x3a3a46], spike: ['shard', GOLD],
};
interface SjData { kind?: string; hank?: number; len?: number }
/** HZ's archetype and tint, or null (a hit with no look of its own: Ichigo's echo hits, Senjumaru's thrusts). */
export function lookOf(hz: Hazard): [Arch, number] | null {
  const d = (hz.data ?? {}) as SjData;
  if (hz.hook === 'senju-hz' && d.kind && LOOKS[d.kind]) return LOOKS[d.kind];
  if (hz.look === 'senju-zone-look') return [hz.kind === 'sj-lane' ? 'cut' : 'ring', HANK[d.hank ?? 0]];
  if (hz.look && LOOKS[hz.look]) return LOOKS[hz.look];
  if (hz.kind === 'wave' && hz.look === null) return LOOKS.wave;
  return LOOKS[hz.kind] ?? null;
}

// ---------------------------------------------------------------- geometry: a few quads per hazard
type V3 = [number, number, number];
/** One mesh of QUADS (4 corners each: bottom-left, bottom-right, top-right, top-left), u over one sheet cell. */
function quads(scene: Scene, qs: V3[][]): Mesh {
  const pos: number[] = [], uv: number[] = [], idx: number[] = [];
  qs.forEach((q, k) => {
    for (const p of q) pos.push(...p);
    uv.push(0, 0, 1 / N, 0, 1 / N, 1, 0, 1);
    idx.push(4 * k, 4 * k + 1, 4 * k + 2, 4 * k, 4 * k + 2, 4 * k + 3);
  });
  const m = new Mesh('hz', scene), vd = new VertexData();
  vd.positions = pos; vd.uvs = uv; vd.indices = idx; vd.applyToMesh(m);
  m.isPickable = false; m.alwaysSelectAsActiveMesh = true;
  return m;
}
const upright = (x0: number, z0: number, x1: number, z1: number, y0: number, y1: number): V3[] =>
  [[x0, y0, z0], [x1, y0, z1], [x1, y1, z1], [x0, y1, z0]];
const flat = (cx: number, cz: number, hw: number, hl: number, y = 0.03): V3[] =>      // along -z (forward), u along it
  [[cx + hw, y, cz + hl], [cx + hw, y, cz - hl], [cx - hw, y, cz - hl], [cx - hw, y, cz + hl]];
const crossed = (x: number, z: number, r: number, y1: number): V3[][] =>
  [upright(x - r, z, x + r, z, 0, y1), upright(x, z - r, x, z + r, 0, y1)];

/** HZ's quads in its local frame (rotation.y = yaw, forward -z) and the mesh's billboard mode. */
function shape(hz: Hazard, a: Arch): [V3[][], number, number] {
  const s = hz.size, d = (hz.data ?? {}) as SjData;
  const along = (len: number, hw: number, y = 0.03): V3[][] => [flat(0, -len / 2, hw, len / 2, y)];
  switch (a) {
    // a wave: the crescent across its path, and again along it (a side view of a wave is not a line)
    case 'crescent': return [[upright(-s * 1.1, 0, s * 1.1, 0, 0, 2.0), upright(0, 1.6, 0, -0.4, 0.1, 1.7)], 0, 0];
    case 'cross': return [[upright(-s * 1.2, 0, s * 1.2, 0, -0.4, 2.8), upright(0, 1.6, 0, -0.6, 0, 2.2)], 0, 0];
    case 'ball': { const r = 1.5 * s; return [[[[-r, -r, 0], [r, -r, 0], [r, r, 0], [-r, r, 0]]], Mesh.BILLBOARDMODE_ALL, 0]; }
    case 'splash': { const r = 0.5 + s; return [[[[-r, -r, 0], [r, -r, 0], [r, r, 0], [-r, r, 0]]], Mesh.BILLBOARDMODE_ALL, 0]; }
    case 'figure': return [[upright(-0.55, 0, 0.55, 0, 0, 2.0)], Mesh.BILLBOARDMODE_Y, 0];
    case 'hand': return [[upright(-0.45, 0, 0.45, 0, 0, 1.5)], Mesh.BILLBOARDMODE_Y, 0];
    case 'shard': return [crossed(0, 0, 0.35 + 0.3 * s, 0.6 + 1.6 * s), 0, 0];
    case 'ring': return [[flat(0, 0, s, s)], 0, 0];
    case 'flame':
      if (hz.kind === 'pillars') {                                     // the ring of pillars, world-aligned (as hazardTouchesP)
        const [pr, ph] = T.pillarSize, q: V3[][] = [];
        for (let i = 0; i < T.ennetsuPillars; i++) {
          const an = (i * TWO_PI) / T.ennetsuPillars + hz.yaw;
          q.push(...crossed(s * Math.cos(an), s * Math.sin(an), pr * 1.5, ph * 1.15));
        }
        return [q, 0, -1];
      }
      if (hz.look === 'enjo') {                                         // walls of fire along the 9 m lane
        const q: V3[][] = [];
        for (let z = 0.5; z < s; z += 1.5) q.push(upright(0, -z, 0, -z - 1.7, 0, 1.9));
        return [q, 0, 0];
      }
      return [crossed(0, 0, s, 2.4), 0, 0];                            // the maiden closing
    case 'thread':
      if (hz.look === 'senju-tendril-look') return [[upright(-s * 1.1, 0, s * 1.1, 0, 0.1, 1.6)], 0, 0];
      return [[upright(-1.2 * s, 0, 1.2 * s, 0, 0, 2.4)], 0, 0];
    case 'cut':
      if (hz.kind === 'rift') return [[upright(0, -0.4, 0, -5.4, 0.1, 2.3)], 0, 0];   // the tear in the air, upright
      if (hz.look === 'senju-zone-look') return [along(d.len ?? 2 * s, s), 0, 0];
      if (hz.look === 'senju-carpet-look') return [along(s, 1.0), 0, 0];
      if (hz.look === 'rukia-blade-look') return [along(s, 0.25, 1.1), 0, 0];
      if (hz.look === 'senju-bolt-look') return [[upright(0, 0, 0, -2.5, 0.8, 1.6)], 0, 0];
      return [along(hz.kind === 'line' ? s : 2 * s, hz.look === 'kyoku' ? 1.4 : hz.look === 'rukia-sheet-look' ? 1.0 : 0.35), 0, 0];
  }
}

// ---------------------------------------------------------------- the views
interface View { m: Mesh; a: Arch; dead: number; local: number }
const TAIL = 0.25;                                                     // seconds a spent hazard lingers

export class HazardLooks {
  sheets = new Map<Arch, DynamicTexture>();
  mats = new Map<string, StandardMaterial>();
  views = new Map<Hazard, View>();
  constructor(readonly scene: Scene) {}

  private mat(a: Arch, tint: number): StandardMaterial {
    const key = `${a}:${tint}`;
    let m = this.mats.get(key);
    if (!m) {
      let t = this.sheets.get(a);
      if (!t) { const [cw, ch, p] = PAINT[a]; t = paintSheet(this.scene, `hz-${a}`, N, cw, ch, p); this.sheets.set(a, t); }
      m = inkMat(this.scene, `hz-${key}`, t, hex3(tint));
      this.mats.set(key, m);
    }
    return m;
  }

  update(hazards: Hazard[], t: number, rdt: number): void {
    const frame = Math.floor(t * FPS) % N;
    for (const tex of this.sheets.values()) tex.uOffset = frame / N;
    for (const hz of hazards) {
      if (!hz.alive || this.views.has(hz)) continue;
      const look = lookOf(hz);
      if (!look) continue;
      const [qs, bb, local] = shape(hz, look[0]);
      const m = quads(this.scene, qs);
      m.material = this.mat(look[0], look[1]); m.billboardMode = bb; m.renderingGroupId = 0;
      this.views.set(hz, { m, a: look[0], dead: 0, local });
    }
    for (const [hz, v] of this.views) {
      const gone = !hz.alive || !hazards.includes(hz);
      if (gone) v.dead += rdt;
      if (v.dead > TAIL) { v.m.dispose(); this.views.delete(hz); continue; }
      this.place(hz, v);
    }
  }

  private place(hz: Hazard, v: View): void {
    const m = v.m, a = v.a, age = Math.floor(hz.age / 5) * 5;          // sim frames, stepped at 12 fps
    m.position.set(hz.x, a === 'ball' ? hz.y : a === 'splash' ? 1.0 : 0, hz.z);
    m.rotation.y = v.local < 0 ? 0 : hz.yaw;
    let vis = 1, sx = 1, sy = 1;
    if (hz.delay > 0) vis = a === 'ring' || a === 'cut' || a === 'shard' ? 0.3 : 0;    // a waiting rift / bind / zone: the tell
    else {
      const grow = Math.min(1, age / 8), k = age / Math.max(1, hz.life);   // pops up over ~2 drawn frames
      if (a === 'flame' || a === 'shard' || a === 'hand' || a === 'figure') sy = 0.25 + 0.75 * grow;
      else if (a === 'ring' || a === 'splash') sx = sy = 0.6 + 0.4 * grow;
      if (hz.life < 9000 && k > 0.75) vis = Math.max(0.2, (1 - k) / 0.25);
    }
    if (v.dead > 0) { const d = Math.floor((v.dead / TAIL) * 3) / 3; vis *= 1 - d; sx *= 1 + 0.25 * d; }
    m.scaling.set(sx, sy, a === 'ring' || a === 'cut' ? sx : 1);
    m.visibility = Math.round(vis * 4) / 4;
    m.isVisible = m.visibility > 0;
  }

  dispose(): void {
    for (const v of this.views.values()) v.m.dispose();
    this.views.clear();
    for (const m of this.mats.values()) m.dispose();
    for (const s of this.sheets.values()) s.dispose();
    this.mats.clear(); this.sheets.clear();
  }
}
