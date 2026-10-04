// body.ts: procedural skinned fighters (the user, 2026-10-04: skinned meshes on a Babylon Skeleton, procedural geometry
// and weights; realistic-anime proportions close to TYBW, ~7.5-8 heads, small heads, long legs, big hands; total height =
// the hurt cylinder). Every part is built at rest in character space (metres, x = his right, y = up, he faces -z),
// coloured per vertex and weighted to its 1-2 nearest candidate bone segments (inverse distance^4: rigid mid-limb, a
// smooth blend at the joints), then all parts merge into ONE mesh per fighter (one draw). Weapons are separate rigid
// meshes attached to the hand bone; the face is a flat decal with three expressions (one canvas cell each).
// This file holds the generic machinery (geometry helpers, the rig, the shared shihakusho body, merge / skin weights,
// the face decal, a katana); each character's look is a CharBody in render/bodies/<char>.ts (registry: bodies/index.ts).
import {
  Bone, Color3, DynamicTexture, Matrix, Mesh, MeshBuilder, Quaternion, Scene, Skeleton, StandardMaterial, Texture,
  Vector3, VertexData, type Material,
} from '@babylonjs/core';
import type { BoneName } from './pose';
import type { Ent } from '../sim/types';

export interface BodySpec {
  height: number; heads: number;
  shoulder: number;               // shoulder joint half-width, head units
  chest: [number, number]; waist: [number, number]; hip: [number, number];   // torso half-widths (x, z), head units
  limb: number; hand: number;     // limb thickness, hand size multipliers
  skin: Col; black: Col; haori: Col | false; obi: Col; hair: Col;   // haori false: none (also noHaori)
  collar: number;                 // depth of the collar's V, body units (Kenpachi's open chest is deep)
  haoriHem: number;               // the haori hem height, in body units (8-head figure: knee 2.15, ankle 0.35)
  haoriSleeves: 'long' | 'torn' | 'none';
  tattered: boolean;
  noHaori?: boolean;              // no haori at all (same as haori: false)
  /** The kosode's sleeves: 'full' (default: the wide hanging sleeve), 'none' (bare arms), 'torn' (short, ragged, above
   *  the elbow), 'flared' (a cone flaring past the elbow, lined in LINING). */
  sleeves?: 'full' | 'none' | 'torn' | 'flared';
  lining?: Col;                   // the flared sleeves' lining (default white)
  emptyL?: boolean;               // the left sleeve hangs empty (Yamamoto: the rig keeps the bone, no forearm / hand)
  bareR?: boolean;                // the right shoulder and arm bared, the kosode's sleeve hanging at the hip
  reiatsu?: number;               // the rim colour (default: scene.ts REIATSU by character)
}

/** One character's look. VARIANT(form): overrides for an awakened form's body, or null (the base body). */
export interface CharBody {
  spec: BodySpec;
  parts(sp: BodySpec, r: Rig): Part[];
  /** Draw expression EXPR (FACE.*) into one cell in 256-unit coordinates (rendered at 512 px: G is translated and
   *  scaled to the cell, ink line style set). */
  drawFace(g: CanvasRenderingContext2D, expr: number): void;
  weapon(scene: Scene, sp: BodySpec, r: Rig): Mesh;
  variant(form: string): BodyVariant | null;
  /** The outline colour (hex) when not the ink (outline.ts INK_ALT; Rukia's zero: ice blue). */
  ink?: number;
  /** Optional extra meshes posed every frame after the skeleton (Senjumaru's echo arms); shown / hidden, outlined and
   *  disposed with the body. */
  extra?(scene: Scene, b: BuiltBody): BodyExtra;
}
export type BodyVariant = Partial<Pick<CharBody, 'parts' | 'drawFace' | 'weapon' | 'ink' | 'extra'>> & { spec?: Partial<BodySpec> };
export interface BodyExtra { meshes: Mesh[]; update(e: Ent, rdt: number): void; dispose(): void }

const PARENT: Record<BoneName, BoneName | null> = {
  pelvis: null, spine: 'pelvis', chest: 'spine', neck: 'chest', head: 'neck',
  shoulderR: 'chest', armR: 'shoulderR', foreR: 'armR', handR: 'foreR', weaponR: 'handR',
  shoulderL: 'chest', armL: 'shoulderL', foreL: 'armL', handL: 'foreL', weaponL: 'handL',
  thighR: 'pelvis', shinR: 'thighR', footR: 'shinR', thighL: 'pelvis', shinL: 'thighL', footL: 'shinL',
};
export const hex = (h: number) => new Color3(((h >> 16) & 255) / 255, ((h >> 8) & 255) / 255, (h & 255) / 255);

// ---------------------------------------------------------------- the palette: lit / shadow pairs (BABYLON_LOOK.md B2)
const SHADOWS = new Map<number, number>();
/** A colour: lit hex, or a [lit, shadow] pair. */
export type Col = number | [number, number];
/** Register LIT's cel shadow colour; returns LIT (so a spec can write `skin: pair(0xf2cba3, 0xc98c68)`; a [lit, shadow]
 *  tuple works anywhere a colour is taken, too). */
export const pair = (lit: number, shadow: number): number => { SHADOWS.set(lit, shadow); return lit; };
/** The lit colour of C. */
export const litOf = (c: Col | Color3): Color3 => (c instanceof Color3 ? c : hex(Array.isArray(c) ? c[0] : c));
/** The shadow of colour C: its pair, else derived (warm colours keep a warm shadow, the rest turn cool). */
export function shadeOf(c: Col | Color3): Color3 {
  if (Array.isArray(c)) return hex(c[1]);
  if (typeof c === 'number') { const s = SHADOWS.get(c); if (s !== undefined) return hex(s); c = hex(c); }
  return c.r - c.b > 0.15 ? new Color3(c.r * 0.83, c.g * 0.7, c.b * 0.62) : new Color3(c.r * 0.68, c.g * 0.72, c.b * 0.86);
}
/** The shared colours (cloth saturation <= 0.15; skin and accents full colour). */
export const PAL = {
  haori: pair(0xf6f3ec, 0xa9b2cf), black: pair(0x2b2d3a, 0x121319), obi: pair(0xe9e4d6, 0x9a9db5),
  hair: pair(0x2a2b38, 0x0e0f15), highlight: pair(0xd8dce4, 0x9ea6bc), blade: pair(0xf4f6fa, 0x9aa6c0),
  edge: pair(0xffffff, 0xdfe6f4), tabi: pair(0xf3f3ee, 0xa9b0c4), zori: pair(0xc4a273, 0x8a6a48),
  lapel: pair(0xf3f1ea, 0xa6aec8), pleat: pair(0x4a4d62, 0x24252f), skinYama: pair(0xf2cba3, 0xc98c68), skinKen: pair(0xe4b48c, 0xb2724f),
};

/** A part: geometry, lit colour, its shadow, the bones it may ride; HAIR parts outline as a silhouette only. */
export interface Part { vd: VertexData; color: Color3; shade: Color3; bones: BoneName[]; hair?: boolean }
/** Add a part (the colour's shadow comes from its pair; HAIR: no interior outline). */
export type Add = (vd: VertexData, color: Col | Color3, bones: BoneName[], hair?: boolean) => void;
export type Ring = [number, number, number, number?, number?];       // y, rx, rz, cx, cz

/** A tube along y through elliptical rings (closed by giving the end rings ~0 radius). The arc a0..a1 (radians, 0 =
 *  front -z, +pi/2 = his right) leaves it open (a haori's front); DOUBLE adds the inside, LIP gives each ring's angle a
 *  y offset (tattered hems). */
export function tube(rings: Ring[], seg = 14,
  o: { a0?: number; a1?: number; double?: boolean; lip?: (a: number, j: number) => number; rad?: (a: number, j: number) => number } = {}): VertexData {
  const a0 = o.a0 ?? 0, a1 = o.a1 ?? Math.PI * 2, closed = o.a0 === undefined;
  const pos: number[] = [], idx: number[] = [], n = seg + 1;
  rings.forEach(([y, rx, rz, cx = 0, cz = 0], j) => {
    for (let k = 0; k <= seg; k++) {
      const a = a0 + ((a1 - a0) * k) / seg, m = o.rad ? o.rad(a, j) : 1;      // RAD: a radius factor per angle (pleats)
      pos.push(cx + m * rx * Math.sin(a), y + (o.lip ? o.lip(a, j) : 0), cz - m * rz * Math.cos(a));
    }
  });
  for (let j = 0; j + 1 < rings.length; j++)
    for (let k = 0; k < seg; k++) {
      const a = j * n + k, b = a + 1, c = a + n, d = c + 1;
      idx.push(a, c, b, b, c, d);
    }
  const vd = new VertexData();
  vd.positions = pos; vd.indices = idx;
  if (closed) weldSeam(vd, rings.length, n);
  const nrm: number[] = [];
  VertexData.ComputeNormals(pos, idx, nrm);
  // outward check (the winding Babylon's builders use): flip if the normals point at the axis
  let dot = 0;
  for (let i = 0; i < pos.length; i += 3) {
    const r = rings[Math.floor(i / 3 / n)];
    dot += nrm[i] * (pos[i] - (r[3] ?? 0)) + nrm[i + 2] * (pos[i + 2] - (r[4] ?? 0));
  }
  if (dot < 0) { for (let i = 0; i < idx.length; i += 3) [idx[i + 1], idx[i + 2]] = [idx[i + 2], idx[i + 1]]; VertexData.ComputeNormals(pos, idx, nrm); }
  vd.normals = nrm;
  if (o.double) {
    const m = pos.length / 3;
    vd.positions = pos.concat(pos);
    vd.normals = nrm.concat(nrm.map((v) => -v));
    vd.indices = idx.concat(idx.map((_, i) => m + idx[i - (i % 3) + [0, 2, 1][i % 3]]));
  }
  return vd;
}
/** Smooth normals across a closed tube's seam: the last column reuses the first column's vertices. */
function weldSeam(vd: VertexData, rows: number, n: number): void {
  const idx = vd.indices as number[];
  for (let i = 0; i < idx.length; i++) if (idx[i] % n === n - 1) idx[i] -= n - 1;
  void rows;
}
/** An ellipsoid centred at C with radii R. */
export function ellipsoid(c: [number, number, number], r: [number, number, number], seg = 14, rows = 9): VertexData {
  const rings: Ring[] = [];
  for (let j = 0; j <= rows; j++) {
    const t = Math.PI * (1 - j / rows), s = Math.max(1e-3, Math.sin(t));
    rings.push([c[1] + r[1] * Math.cos(t), r[0] * s, r[2] * s, c[0], c[2]]);
  }
  return tube(rings, seg);
}
/** Split VD's triangles by their centroid: [those where PRED holds, the rest] (two colours on one surface). */
export function splitBy(vd: VertexData, pred: (x: number, y: number, z: number) => boolean): [VertexData, VertexData] {
  const P = vd.positions as number[], N = vd.normals as number[], I = vd.indices as number[];
  const out = [new VertexData(), new VertexData()].map((v) => Object.assign(v, { positions: [...P], normals: [...N], indices: [] as number[] }));
  for (let i = 0; i < I.length; i += 3) {
    let x = 0, y = 0, z = 0;
    for (let k = 0; k < 3; k++) { x += P[3 * I[i + k]]; y += P[3 * I[i + k] + 1]; z += P[3 * I[i + k] + 2]; }
    (out[pred(x / 3, y / 3, z / 3) ? 0 : 1].indices as number[]).push(I[i], I[i + 1], I[i + 2]);
  }
  return out as [VertexData, VertexData];
}
export function box(w: number, h: number, d: number, m: Matrix): VertexData {
  const vd = VertexData.CreateBox({ width: w, height: h, depth: d });
  vd.transform(m);
  return vd;
}
export const T = (x: number, y: number, z: number, rx = 0, ry = 0, rz = 0) =>
  Matrix.Compose(Vector3.One(), Quaternion.RotationYawPitchRoll(ry, rx, rz), new Vector3(x, y, z));

/** A limb segment from A to B (points) as a tapered tube with radii ra -> rb, a little rounded at both ends. */
export function limb(a: Vector3, b: Vector3, ra: number, rb: number, seg = 10, flat = 1): VertexData {
  const len = Vector3.Distance(a, b);
  const vd = tube([[-0.25 * ra, 0.01, 0.01], [0, ra * 0.85, ra * 0.85 * flat], [0.15 * len, ra, ra * flat],
    [0.85 * len, rb, rb * flat], [len, rb * 0.85, rb * 0.85 * flat], [len + 0.25 * rb, 0.01, 0.01]], seg);
  const dir = b.subtract(a).normalize(), up = new Vector3(0, 1, 0);
  const axis = Vector3.Cross(up, dir), ang = Math.acos(Math.max(-1, Math.min(1, Vector3.Dot(up, dir))));
  const q = axis.length() < 1e-6 ? (dir.y < 0 ? Quaternion.RotationAxis(new Vector3(1, 0, 0), Math.PI) : Quaternion.Identity())
    : Quaternion.RotationAxis(axis.normalize(), ang);
  vd.transform(Matrix.Compose(Vector3.One(), q, a));
  return vd;
}

// ---------------------------------------------------------------- the rig
export interface Rig { rest: Record<BoneName, Vector3>; end: Record<BoneName, Vector3>; H: number; bs: number }
export function rig(sp: BodySpec): Rig {
  const H = sp.height / sp.heads, bs = ((sp.heads - 1) * H) / 7;          // head unit; body unit (neck at 7)
  const v = (x: number, y: number, z = 0) => new Vector3(x * H, y * bs, z * H);
  const neckY = 6.78, sx = sp.shoulder;
  const rest = {
    pelvis: v(0, 4.35), spine: v(0, 4.8, 0.05), chest: v(0, 5.75, 0.05), neck: v(0, neckY, 0.05),
    head: new Vector3(0, (sp.heads - 1) * H + 0.08 * H, 0.02 * H),
    shoulderR: v(0.3, 6.45, 0.05), armR: v(sx, 6.4, 0.05), foreR: v(sx + 0.08, 4.95, 0.05), handR: v(sx + 0.12, 3.75, 0),
    weaponR: v(sx + 0.12, 3.75 - 0.36 * sp.hand * H / bs, 0),
    shoulderL: v(-0.3, 6.45, 0.05), armL: v(-sx, 6.4, 0.05), foreL: v(-sx - 0.08, 4.95, 0.05), handL: v(-sx - 0.12, 3.75, 0),
    weaponL: v(-sx - 0.12, 3.75 - 0.36 * sp.hand * H / bs, 0),
    thighR: v(0.42, 4.02), shinR: v(0.44, 2.15), footR: v(0.46, 0.36),
    thighL: v(-0.42, 4.02), shinL: v(-0.44, 2.15), footL: v(-0.46, 0.36),
  } as Record<BoneName, Vector3>;
  const end = {} as Record<BoneName, Vector3>;
  const child: Partial<Record<BoneName, BoneName>> = { pelvis: 'spine', spine: 'chest', chest: 'neck', neck: 'head',
    shoulderR: 'armR', armR: 'foreR', foreR: 'handR', shoulderL: 'armL', armL: 'foreL', foreL: 'handL',
    thighR: 'shinR', shinR: 'footR', thighL: 'shinL', shinL: 'footL' };
  for (const b of Object.keys(rest) as BoneName[]) end[b] = child[b] ? rest[child[b]!] : rest[b].clone();
  end.head = rest.head.add(new Vector3(0, 0.9 * H, 0));
  end.handR = rest.handR.add(new Vector3(0, -0.7 * sp.hand * H, 0)); end.handL = rest.handL.add(new Vector3(0, -0.7 * sp.hand * H, 0));
  end.footR = rest.footR.add(new Vector3(0, -0.3 * bs, -0.85 * H)); end.footL = rest.footL.add(new Vector3(0, -0.3 * bs, -0.85 * H));
  return { rest, end, H, bs };
}

function segDist(p: Vector3, a: Vector3, b: Vector3): number {
  const ab = b.subtract(a), l2 = ab.lengthSquared();
  const t = l2 < 1e-9 ? 0 : Math.max(0, Math.min(1, Vector3.Dot(p.subtract(a), ab) / l2));
  return Vector3.Distance(p, a.add(ab.scale(t)));
}

// ---------------------------------------------------------------- the shared shihakusho + haori body
/** The add function of a parts list: hair-coloured parts (sp.hair) outline as a silhouette only. */
export function adder(sp: BodySpec, parts: Part[]): Add {
  return (vd, color, bones, hair) => parts.push({ vd, color: litOf(color), shade: shadeOf(color),
    bones, hair: hair ?? color === sp.hair });
}
/** Kosode, collar, obi, head, arms with sleeves, the haori, the hakama, tabi and zori. HEAD(add, hc) adds the
 *  character's hair / beard right after the bare head (hc = the skull's centre). Options in the spec: noHaori, emptyL
 *  (the left sleeve hangs flat and empty), bareR (the right shoulder and arm bared). */
export function kimono(sp: BodySpec, r: Rig, head?: (add: Add, hc: [number, number, number]) => void): Part[] {
  const { rest: R, H, bs } = r, parts: Part[] = [], add = adder(sp, parts);
  const y = (v: number) => v * bs, L = sp.limb, hasHaori = sp.haori !== false && !sp.noHaori, haoriC = sp.haori as Col;
  const torsoB: BoneName[] = ['pelvis', 'spine', 'chest', 'neck', 'shoulderR', 'shoulderL'];
  const [cx, cz] = sp.chest, [wx, wz] = sp.waist, [hx, hz] = sp.hip;
  // torso: the kosode (black), hips to the collar; bared: the right shoulder and breast above a line from the left
  // side of the neck down to under the right arm are skin
  const torso = tube([[y(3.95), 0.02, 0.02], [y(4.0), hx * H * 0.9, hz * H * 0.9], [y(4.4), hx * H, hz * H], [y(5.0), wx * H, wz * H],
    [y(5.6), cx * H * 0.95, cz * H], [y(6.2), cx * H, cz * H * 1.02, 0, 0.02 * H], [y(6.55), cx * H * 0.92, cz * H * 0.9, 0, 0.04 * H],
    [y(6.75), 0.3 * H, 0.3 * H, 0, 0.05 * H], [y(6.8), 0.02, 0.02, 0, 0.05 * H]], sp.bareR ? 32 : 16);
  if (sp.bareR) {
    const [bare, cloth] = splitBy(torso, (x, yy) => yy > y(6.85) - (x + 0.12 * H) / ((cx + 0.12) * H) * y(1.35));
    add(bare, sp.skin, torsoB); add(cloth, sp.black, torsoB);
    add(ellipsoid([0.3 * H, y(5.95), -cz * H * 0.72], [0.34 * H, 0.26 * H, 0.2 * H], 10, 7), sp.skin, ['chest']);   // the breast
    // the slipped-off sleeve hangs from the obi at his right hip
    const sl = tube([[y(4.85), 0.12 * H, 0.3 * H], [y(4.2), 0.16 * H, 0.42 * H, 0.03 * H], [y(3.2), 0.12 * H, 0.46 * H, 0.06 * H],
      [y(3.1), 0.03 * H, 0.2 * H, 0.06 * H]], 10);
    sl.transform(T(hx * H * 1.0, 0, 0.08 * H, 0, 0, -0.1));
    add(sl, sp.black, ['pelvis', 'thighR']);
  } else add(torso, sp.black, torsoB);
  // the collar: the white juban lapels in a V, skin inside it
  const deep = sp.collar;
  add(tube([[y(6.75 - deep), 0.02, 0.02, 0, -cz * H * 0.98], [y(6.75 - deep * 0.6), 0.14 * H * deep, 0.04 * H, 0, -cz * H * 1.0],
    [y(6.6), 0.3 * H, 0.05 * H, 0, -cz * H * 0.92], [y(6.8), 0.26 * H, 0.04 * H, 0, -cz * H * 0.7]], 8), sp.skin, ['chest', 'neck']);
  for (const s of sp.bareR ? [-1] : [1, -1]) {                  // a flat band from the side of the neck down into the V
    add(limb(new Vector3(s * 0.24 * H, y(6.8), -cz * H * 0.72), new Vector3(s * 0.02 * H, y(6.75 - deep), -cz * H * 1.03),
      0.06 * H, 0.045 * H, 6, 0.35), PAL.lapel, ['chest', 'neck']);
  }
  // the obi
  add(tube([[y(4.55), wx * H * 1.07, wz * H * 1.08], [y(4.85), wx * H * 1.08, wz * H * 1.1], [y(4.86), wx * H * 0.5, wz * H * 0.5]], 16),
    sp.obi, ['pelvis', 'spine']);
  // neck and head
  add(limb(R.neck.add(new Vector3(0, -0.1 * H, 0)), R.head.add(new Vector3(0, 0.25 * H, 0)), 0.2 * H * L, 0.18 * H * L), sp.skin, ['neck', 'head', 'chest']);
  const hc: [number, number, number] = [0, R.head.y + 0.42 * H, R.head.z - 0.02 * H];
  add(ellipsoid(hc, [0.36 * H, 0.48 * H, 0.42 * H], 16, 10), sp.skin, ['head']);
  add(ellipsoid([0, hc[1] - 0.3 * H, hc[2] - 0.24 * H], [0.24 * H, 0.17 * H, 0.2 * H]), sp.skin, ['head']);    // jaw
  add(ellipsoid([0, hc[1] - 0.02 * H, hc[2] - 0.43 * H], [0.045 * H, 0.09 * H, 0.06 * H], 6, 5), sp.skin, ['head']);   // nose
  for (const s of [1, -1]) add(ellipsoid([s * 0.37 * H, hc[1], hc[2] + 0.02 * H], [0.05 * H, 0.12 * H, 0.08 * H], 6, 5), sp.skin, ['head']);
  head?.(add, hc);
  // arms: kosode sleeve over the upper arm, a wide hanging sleeve, forearm skin, the big hand
  for (const s of [1, -1] as const) {
    const S = s > 0 ? 'R' : 'L', sh = R[`shoulder${S}`], arm = R[`arm${S}`], el = R[`fore${S}`], wr = R[`hand${S}`];
    const ar = 0.25 * H * L, haori = hasHaori;
    if (s < 0 && sp.emptyL) {
      // the empty sleeve: flat cloth from the shoulder to the hip, riding the arm bone (it swings in SODEBI)
      const flat = (w: number, len: number) => tube([[0.05 * H, ar * 1.15, ar * 1.2], [-0.4 * bs, ar * 0.55, ar * 1.7 * w, 0, 0.1 * ar],
        [-len * bs, ar * 0.35, ar * 2.1 * w, 0, 0.3 * ar], [-(len + 0.05) * bs, ar * 0.1, ar * 0.9 * w, 0, 0.3 * ar]], 12);
      add(limb(sh.add(new Vector3(0, -0.05 * H, 0)), arm, ar * 1.2, ar * 1.15), sp.black, ['shoulderL', 'armL', 'chest']);
      const k = flat(1, 2.25); k.transform(T(arm.x - 0.05 * H, arm.y, arm.z, 0, 0, -0.05));
      add(k, sp.black, ['shoulderL', 'armL', 'foreL']);
      if (haori && sp.haoriSleeves === 'long') {
        const w = flat(1.25, 2.0); w.transform(T(arm.x - 0.1 * H, arm.y + 0.05 * H, arm.z, 0, 0, -0.05));
        add(w, haoriC, ['shoulderL', 'armL', 'foreL']);
      }
      continue;
    }
    const bareR = s > 0 && sp.bareR, sv = sp.sleeves ?? 'full', bare = bareR || sv === 'none';
    const armB = [`shoulder${S}`, `arm${S}`, `fore${S}`] as BoneName[];
    if (bareR) {                                                       // the bared arm: shoulder cap, biceps, forearm
      add(limb(sh.add(new Vector3(0, -0.02 * H, 0)), arm, ar * 1.25, ar * 1.4), sp.skin, ['shoulderR', 'armR', 'chest']);
      add(limb(arm, el, ar * 1.35, ar * 0.95), sp.skin, ['shoulderR', 'armR', 'foreR']);
    } else if (sv === 'none' || sv === 'torn') {                       // bare arms; torn: a ragged short sleeve over them
      add(limb(sh.add(new Vector3(0, -0.02 * H, 0)), arm, ar * 1.15, ar * 1.2), sp.skin, [`shoulder${S}`, `arm${S}`, 'chest'] as BoneName[]);
      add(limb(arm, el, ar * 1.15, ar * 0.9), sp.skin, armB);
      if (sv === 'torn') {
        const t = tube([[0.1 * H, ar * 1.45, ar * 1.45], [-0.45 * bs, ar * 1.55, ar * 1.6], [-0.7 * bs, ar * 1.5, ar * 1.55]], 12,
          { double: true, a0: 0.001, a1: Math.PI * 2 - 0.001, lip: (a, j) => (j === 2 ? 0.09 * H * Math.sin(a * 5) + 0.05 * H * Math.sin(a * 11) : 0) });
        t.transform(T(arm.x, arm.y, arm.z, 0, 0, s * 0.06));
        add(t, sp.black, [`shoulder${S}`, `arm${S}`] as BoneName[]);
      }
    } else {
      add(limb(sh.add(new Vector3(0, -0.05 * H, 0)), arm, ar * 1.2, ar * 1.15), sp.black, [`shoulder${S}`, `arm${S}`, 'chest'] as BoneName[]);
      add(limb(arm, el, ar * 1.1, ar * 0.95), sp.black, armB);
    }
    add(limb(el, wr, ar * (bareR ? 1.0 : 0.8), ar * (bareR ? 0.72 : 0.62)), sp.skin, [`arm${S}`, `fore${S}`, `hand${S}`] as BoneName[]);
    if (sv === 'flared' && !bareR) {                                   // a cone from the upper arm flaring past the elbow
      const d = el.subtract(arm), len = d.length() * 1.35;
      const out = tube([[0, ar * 1.2, ar * 1.2], [len * 0.55, ar * 1.6, ar * 1.6], [len, ar * 2.3, ar * 2.3]], 14, { a0: 0.001, a1: Math.PI * 2 - 0.001 });
      const lin = tube([[len * 0.6, ar * 1.5, ar * 1.5], [len * 0.99, ar * 2.2, ar * 2.2]], 14, { a0: 0.001, a1: Math.PI * 2 - 0.001, double: true });
      const q = T(arm.x, arm.y, arm.z, Math.PI);                       // y along the arm (it hangs down at rest)
      out.transform(q); lin.transform(q);
      add(out, sp.black, armB); add(lin, sp.lining ?? PAL.lapel, armB);
    }
    // the kosode's big sleeve: hangs from the upper arm to below the elbow, widest at the bottom (behind the forearm)
    if (!bare && sv === 'full') {
      const sl = tube([[0, 0.02, 0.02], [0.05 * H, ar * 1.3, ar * 1.3], [-1.0 * bs, ar * 1.6, ar * 2.2, 0, 0.35 * ar],
        [-1.75 * bs, ar * 1.55, ar * 2.6, 0, 0.6 * ar], [-1.8 * bs, ar * 0.3, ar * 1.0, 0, 0.6 * ar]], 12);
      sl.transform(T(el.x * 0.5 + arm.x * 0.5, arm.y - 0.05 * H, arm.z));
      add(sl, sp.black, [`arm${S}`, `fore${S}`] as BoneName[]);
    }
    // the hand: palm block, a rolled fist of fingers, the thumb
    const hs = sp.hand * H;
    add(ellipsoid([wr.x, wr.y - 0.22 * hs, wr.z], [0.12 * hs, 0.24 * hs, 0.2 * hs], 8, 6), sp.skin, [`hand${S}`, `fore${S}`] as BoneName[]);
    add(ellipsoid([wr.x - s * 0.02 * hs, wr.y - 0.46 * hs, wr.z - 0.02 * hs], [0.15 * hs, 0.14 * hs, 0.22 * hs], 8, 6), sp.skin, [`hand${S}`] as BoneName[]);
    add(limb(new Vector3(wr.x - s * 0.1 * hs, wr.y - 0.12 * hs, wr.z - 0.18 * hs), new Vector3(wr.x - s * 0.14 * hs, wr.y - 0.36 * hs, wr.z - 0.26 * hs),
      0.07 * hs, 0.06 * hs, 6), sp.skin, [`hand${S}`] as BoneName[]);
    // haori sleeve (white) over it all
    if (!haori || bare) continue;
    if (sp.haoriSleeves === 'long') {
      const hsl = tube([[0.08 * H, ar * 1.5, ar * 1.5], [-0.9 * bs, ar * 1.85, ar * 2.4, 0, 0.3 * ar],
        [-1.6 * bs, ar * 1.8, ar * 2.8, 0, 0.6 * ar], [-1.62 * bs, ar * 0.4, ar * 1.0, 0, 0.6 * ar]], 12);
      hsl.transform(T(el.x * 0.5 + arm.x * 0.5, arm.y, arm.z));
      add(hsl, haoriC, [`arm${S}`, `fore${S}`] as BoneName[]);
    } else if (sp.haoriSleeves === 'torn') {
      const hsl = tube([[0.08 * H, ar * 1.5, ar * 1.5], [-0.5 * bs, ar * 1.6, ar * 1.7], [-0.75 * bs, ar * 1.5, ar * 1.65]], 12,
        { double: true, a0: 0.001, a1: Math.PI * 2 - 0.001, lip: (a, j) => (j === 2 ? 0.07 * H * Math.sin(a * 5) : 0) });
      hsl.transform(T(arm.x, arm.y, arm.z, 0, 0, s * 0.08));
      add(hsl, haoriC, [`shoulder${S}`, `arm${S}`] as BoneName[]);
    }
  }
  // the haori: a white coat over the kosode, open at the front; below the vent top it splits into three panels (two
  // front, one back) at side vents, so the legs show through in a step (the panels ride the pelvis and the thighs)
  if (hasHaori) {
    const tat = sp.tattered, ho = 1.12, fr = 0.42, vent = 0.13, hem = sp.haoriHem, top = Math.max(hem + 0.4, Math.min(3.9, hem + 1.4));
    const lip = (a: number, j: number) => (j === 1 && tat ? 0.16 * H * (Math.sin(a * 7) * 0.6 + Math.sin(a * 13 + 1) * 0.4) : 0);
    const flare = 1.12 + 0.12 * (4.3 - hem);
    add(tube([[y(6.8), 0.36 * H, 0.32 * H, 0, 0.06 * H], [y(6.6), cx * H * ho * 0.95, cz * H * ho, 0, 0.03 * H],
      [y(6.1), cx * H * ho, cz * H * ho * 1.04, 0, 0.02 * H], [y(5.2), wx * H * ho * 1.1, wz * H * ho * 1.15],
      [y(4.3), hx * H * ho * 1.12, hz * H * ho * 1.2], [y(top), hx * H * ho * 1.18, hz * H * ho * 1.28, 0, 0.03 * H]], 18,
    { a0: fr, a1: Math.PI * 2 - fr, double: true }), haoriC, ['pelvis', 'spine', 'chest', 'shoulderR', 'shoulderL']);
    const P2 = Math.PI / 2;
    for (const [a0, a1, b] of [[fr, P2 - vent, 'thighR'], [P2 + vent, 3 * P2 - vent, null], [3 * P2 + vent, 4 * P2 - fr, 'thighL']] as const)
      add(tube([[y(top), hx * H * ho * 1.18, hz * H * ho * 1.28, 0, 0.03 * H], [y(hem), hx * H * ho * flare, hz * H * ho * (flare + 0.1), 0, 0.08 * H]],
        8, { a0, a1, double: true, lip }), haoriC, (b ? ['pelvis', b] : ['pelvis', 'thighR', 'thighL']) as BoneName[]);
  }
  // the hakama: two trouser legs (ankle radius <= 0.45 H, a gap between them), four pleat creases down the front of each
  // (light crease lines on the black), the koshiita board at the back of the waist
  const PLEATS = [-1.0, -0.45, 0.1, 0.65];                                     // angles from the front, his outer side +
  const pleat = (s: number) => (x: number, _y: number, z: number, cx0: number) => {
    const a = Math.atan2((x - cx0) * s, -z);
    return PLEATS.some((p) => Math.abs(a - p) < 0.07);
  };
  for (const s of [1, -1] as const) {
    const S = s > 0 ? 'R' : 'L', th = R[`thigh${S}`], kn = R[`shin${S}`], an = R[`foot${S}`];
    const lx = th.x, ax = an.x;
    const rings: Ring[] = [[y(4.5), 0.38 * H, hz * H * 1.02, s * 0.3 * H, 0], [y(3.9), 0.38 * H, 0.5 * H, s * 0.36 * H, 0],
      [kn.y, 0.38 * H, 0.46 * H, (lx + ax) / 2, 0], [an.y + 0.3 * bs, 0.42 * H, 0.48 * H, ax, 0.02 * H],
      [an.y + 0.14 * bs, 0.44 * H, 0.5 * H, ax, 0.02 * H], [an.y + 0.13 * bs, 0.2 * H, 0.2 * H, ax, 0.02 * H]];
    const leg = tube(rings, 48, { rad: (a) => 1 + 0.035 * Math.abs(Math.sin(s * a * 5.2)) });
    const [lines, cloth] = splitBy(leg, (x, yy, z) => yy < y(4.3) && yy > an.y + 0.15 * bs && pleat(s)(x, yy, z, (lx + ax) / 2));
    const bones = ['pelvis', `thigh${S}`, `shin${S}`] as BoneName[];
    add(cloth, sp.black, bones); add(lines, PAL.pleat, bones);
    // the white tabi and the straw zori
    add(limb(new Vector3(an.x, an.y + 0.15 * bs, an.z + 0.05 * H), new Vector3(an.x, an.y - 0.15 * bs, an.z - 0.05 * H), 0.16 * H, 0.15 * H, 8),
      PAL.tabi, [`shin${S}`, `foot${S}`] as BoneName[]);
    add(box(0.3 * H, 0.16 * bs, 0.95 * H, T(an.x, 0.12 * bs, an.z - 0.3 * H)), PAL.tabi, [`foot${S}`] as BoneName[]);
    add(box(0.34 * H, 0.06 * bs, 1.02 * H, T(an.x, 0.03 * bs, an.z - 0.3 * H)), PAL.zori, [`foot${S}`] as BoneName[]);
  }
  add(box(hx * H * 1.3, 0.55 * bs, 0.06 * H, T(0, y(4.55), hz * H * 1.12, -0.18)), sp.black, ['pelvis']);    // koshiita
  return parts;
}

// ---------------------------------------------------------------- assembly
export interface BuiltBody {
  mesh: Mesh; skeleton: Skeleton; bones: Record<BoneName, Bone>; rig: Rig; spec: BodySpec;
  weapon: Mesh; face: Mesh; faceTex: DynamicTexture; faceMat: StandardMaterial; extra?: BodyExtra;
  /** The blade tip and a point near the grip, in the weapon mesh's local space (smears, trails: weapon.getWorldMatrix()). */
  tip: Vector3; base: Vector3;
}

/** Build CB's skinned mesh, weapon and face decal (KEY names the Babylon objects). */
export function buildBody(scene: Scene, key: string, cb: CharBody, mat: Material, weaponMat: Material): BuiltBody {
  const sp = cb.spec, r = rig(sp);
  const names = Object.keys(PARENT) as BoneName[];
  const skeleton = new Skeleton(`${key}-skel`, `${key}-skel`, scene);
  const bones = {} as Record<BoneName, Bone>;
  for (const b of names) {
    const p = PARENT[b], off = p ? r.rest[b].subtract(r.rest[p]) : r.rest[b];
    bones[b] = new Bone(b, skeleton, p ? bones[p] : null, Matrix.Translation(off.x, off.y, off.z));
  }
  const bi = (b: BoneName) => names.indexOf(b);
  // merge the parts, weighting each vertex
  const pos: number[] = [], nrm: number[] = [], col: number[] = [], sh: number[] = [], idx: number[] = [], mi: number[] = [], mw: number[] = [];
  const tmp = new Vector3();
  for (const part of cb.parts(sp, r)) {
    const P = part.vd.positions as number[], N = part.vd.normals as number[], I = part.vd.indices as number[], base = pos.length / 3;
    for (let i = 0; i < P.length; i += 3) {
      pos.push(P[i], P[i + 1], P[i + 2]); nrm.push(N[i], N[i + 1], N[i + 2]);
      col.push(part.color.r, part.color.g, part.color.b, part.hair ? 0.8 : 1); sh.push(part.shade.r, part.shade.g, part.shade.b);
      tmp.set(P[i], P[i + 1], P[i + 2]);
      const ws = part.bones.map((b) => ({ b, w: 1 / Math.pow(segDist(tmp, r.rest[b], r.end[b]) + 0.01, 4) })).sort((a, c) => c.w - a.w);
      const w0 = ws[0].w, w1 = ws[1] ? ws[1].w : 0, sum = w0 + w1;
      mi.push(bi(ws[0].b), ws[1] ? bi(ws[1].b) : 0, 0, 0);
      mw.push(w0 / sum, w1 / sum, 0, 0);
    }
    for (const k of I) idx.push(base + k);
  }
  const vd = new VertexData();
  Object.assign(vd, { positions: pos, normals: nrm, colors: col, indices: idx, matricesIndices: mi, matricesWeights: mw });
  const mesh = new Mesh(`${key}-body`, scene);
  vd.applyToMesh(mesh);
  mesh.setVerticesData('shade', sh, false, 3);
  mesh.skeleton = skeleton; mesh.numBoneInfluencers = 2; mesh.material = mat;
  // weapon (rigid, attached to the right hand's grip)
  const weapon = cb.weapon(scene, sp, r);
  weapon.material = weaponMat;
  weapon.attachToBone(bones.weaponR, mesh);
  const wp = weapon.getVerticesData('position')!, tip = new Vector3();
  for (let i = 0; i < wp.length; i += 3) if (wp[i] ** 2 + wp[i + 1] ** 2 + wp[i + 2] ** 2 > tip.lengthSquared()) tip.set(wp[i], wp[i + 1], wp[i + 2]);
  // face decal on the head bone (512 px cells)
  const H = r.H, faceTex = new DynamicTexture(`${key}-face`, { width: 1536, height: 512 }, scene, true);
  drawFaces(faceTex, cb.drawFace);
  faceTex.hasAlpha = true; faceTex.uScale = 1 / 3; faceTex.wrapU = Texture.CLAMP_ADDRESSMODE;
  const faceMat = new StandardMaterial(`${key}-facemat`, scene);
  faceMat.diffuseTexture = faceTex; faceMat.useAlphaFromDiffuseTexture = true; faceMat.transparencyMode = 1;   // alpha test
  faceMat.disableLighting = true; faceMat.emissiveColor = Color3.White(); faceMat.backFaceCulling = false;
  const face = MeshBuilder.CreatePlane(`${key}-face`, { size: 0.9 * H }, scene);
  face.material = faceMat;
  face.attachToBone(bones.head, mesh);
  face.position.set(0, 0.42 * H, -0.02 * H - 0.43 * H);
  face.scaling.x = -1;                  // the plane's front faces +z in this right-handed scene: mirror it to face -z
  const b: BuiltBody = { mesh, skeleton, bones, rig: r, spec: sp, weapon, face, faceTex, faceMat, tip, base: tip.scale(0.2) };
  b.extra = cb.extra?.(scene, b);
  return b;
}

/** Merge rigid vertex-coloured pieces into one mesh (weapons). */
export function rigid(scene: Scene, name: string, parts: { vd: VertexData; c: Col }[]): Mesh {
  const pos: number[] = [], nrm: number[] = [], col: number[] = [], sh: number[] = [], idx: number[] = [];
  for (const p of parts) {
    const base = pos.length / 3, c = litOf(p.c), d = shadeOf(p.c);
    pos.push(...(p.vd.positions as number[])); nrm.push(...(p.vd.normals as number[]));
    for (let i = 0; i < p.vd.positions!.length / 3; i++) { col.push(c.r, c.g, c.b, 1); sh.push(d.r, d.g, d.b); }
    for (const k of p.vd.indices as number[]) idx.push(base + k);
  }
  const vd = new VertexData();
  Object.assign(vd, { positions: pos, normals: nrm, colors: col, indices: idx });
  const m = new Mesh(name, scene);
  vd.applyToMesh(m);
  m.setVerticesData('shade', sh, false, 3);
  return m;
}

/** A katana in the fist: the grip at the weapon bone, the blade forward (-z). CHIPS notches the edge; GUARD (colour)
 *  adds a small tsuba; EDGE (colour) a bright stripe along the cutting edge; EXTRA pieces are given in the grip's frame
 *  (y along the grip from the fist toward the pommel). */
export function katana(scene: Scene, o: { blade: number; grip: number; w: number; bladeC: Col; gripC: Col; chips?: boolean;
  guard?: Col; edge?: Col; extra?: { vd: VertexData; c: Col }[] }): Mesh {
  const parts: { vd: VertexData; c: Col }[] = [];
  const rings: Ring[] = [];
  const n = 28;
  for (let i = 0; i <= n; i++) {
    const t = i / n, chip = o.chips && i % 6 === 4 ? 0.8 : 1;
    const tip = t > 0.9 ? 1 - (t - 0.9) / 0.1 * 0.95 : 1;
    rings.push([t * o.blade, 0.009, o.w * chip * tip, 0, o.w * (1 - chip * tip) * 0.5]);
  }
  // the blade leaves the fist along the forearm's line, tipped 20 deg forward (the grip's angle in a fist)
  const mt = 20 * Math.PI / 180, dy = -Math.cos(mt), dz = -Math.sin(mt), g0 = 0.07, at = T(0, dy * g0, dz * g0, Math.PI + mt);
  const bl = tube(rings, 8);
  const [edge, flat] = splitBy(bl, (_x, yy, z) => z < -0.72 * o.w * (yy > 0.9 * o.blade ? 1 - (yy / o.blade - 0.9) / 0.1 * 0.95 : 1));
  for (const [v, c] of [[flat, o.bladeC], [edge, o.edge ?? PAL.edge]] as const) { v.transform(at); parts.push({ vd: v, c }); }
  const gr = tube([[0, 0.016, 0.02], [o.grip, 0.017, 0.021], [o.grip + 0.01, 0.005, 0.005]], 8);
  gr.transform(T(0, dy * g0, dz * g0, mt));
  parts.push({ vd: gr, c: o.gripC });
  if (o.guard !== undefined) parts.push({ vd: box(0.012, 0.075, 0.09, T(0, dy * g0, dz * g0, mt)), c: o.guard });
  for (const x of o.extra ?? []) { x.vd.transform(T(0, dy * g0, dz * g0, mt)); parts.push(x); }
  return rigid(scene, 'weapon', parts);
}

// ---------------------------------------------------------------- faces: neutral / shout / hurt, one 512 px cell each
export const FACE = { neutral: 0, shout: 1, hurt: 2 } as const;
/** A bold ink polyline (x0 y0 x1 y1 ...) in the current stroke style: a head is ~40 px on screen. */
export function inkLine(g: CanvasRenderingContext2D, w: number, ...p: number[]): void {
  g.lineWidth = w * 2.2;
  g.beginPath(); g.moveTo(p[0], p[1]); for (let i = 2; i < p.length; i += 2) g.lineTo(p[i], p[i + 1]); g.stroke();
}
function drawFaces(t: DynamicTexture, draw: CharBody['drawFace']): void {
  const g = t.getContext() as CanvasRenderingContext2D;
  g.clearRect(0, 0, 1536, 512);
  for (let e = 0; e < 3; e++) {
    g.save(); g.translate(e * 512, 0); g.scale(2, 2);                // the drawers keep 256-unit coordinates
    g.lineCap = 'round'; g.lineJoin = 'round'; g.strokeStyle = '#1a1414'; g.fillStyle = '#1a1414';
    draw(g, e);
    g.restore();
  }
  t.update();
}

// ---------------------------------------------------------------- placeholder bodies (until a character gets its own)
const PLAIN: BodySpec = { height: 1.7, heads: 7.5, shoulder: 1.0, chest: [0.7, 0.44], waist: [0.55, 0.4], hip: [0.62, 0.42], limb: 1,
  hand: 1.15, skin: 0xe8c4a0, black: PAL.black, haori: PAL.haori, obi: PAL.obi, hair: PAL.hair, collar: 0.8, haoriHem: 2.35,
  haoriSleeves: 'long', tattered: false };
/** The shared shihakusho body with a hair cap, a plain face and a katana; O overrides the spec (height, colours). */
export function plainBody(o: Partial<BodySpec>): CharBody {
  return {
    spec: { ...PLAIN, ...o },
    parts: (sp, r) => kimono(sp, r, (add, hc) =>
      add(ellipsoid([0, hc[1] + 0.06 * r.H, hc[2] + 0.03 * r.H], [0.39 * r.H, 0.47 * r.H, 0.44 * r.H], 16, 10), sp.hair, ['head'])),
    drawFace: (g, e) => {
      for (const x of [92, 164]) {
        if (e === 2) { inkLine(g, 5, x - 20, 118, x + 20, 128); continue; }
        g.fillStyle = '#fff'; g.beginPath(); g.ellipse(x, 124, 20, 11, 0, 0, 7); g.fill();
        g.fillStyle = '#1a1414'; g.beginPath(); g.arc(x, 124, e === 1 ? 6 : 9, 0, 7); g.fill();
        inkLine(g, 5, x - 22, 104, x + 22, 102);
      }
      if (e === 1) { g.beginPath(); g.ellipse(128, 196, 22, 16, 0, 0, 7); g.fill(); }
      else inkLine(g, 5, 108, 198, 148, 198);
    },
    weapon: (scene) => katana(scene, { blade: 0.9, grip: 0.25, w: 0.03, bladeC: PAL.blade, gripC: 0x2b2b38, guard: 0x3a3426 }),
    variant: () => null,
  };
}
