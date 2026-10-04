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

export interface BodySpec {
  height: number; heads: number;
  shoulder: number;               // shoulder joint half-width, head units
  chest: [number, number]; waist: [number, number]; hip: [number, number];   // torso half-widths (x, z), head units
  limb: number; hand: number;     // limb thickness, hand size multipliers
  skin: number; black: number; haori: number; obi: number; hair: number;
  collar: number;                 // depth of the collar's V, body units (Kenpachi's open chest is deep)
  haoriHem: number;               // the haori hem height, in body units (8-head figure: knee 2.15, ankle 0.35)
  haoriSleeves: 'long' | 'torn';
  tattered: boolean;
}

/** One character's look. VARIANT(form): overrides for an awakened form's body, or null (the base body). */
export interface CharBody {
  spec: BodySpec;
  parts(sp: BodySpec, r: Rig): Part[];
  /** Draw expression EXPR (FACE.*) into one 256 px cell; G is translated to the cell, ink line style set. */
  drawFace(g: CanvasRenderingContext2D, expr: number): void;
  weapon(scene: Scene, sp: BodySpec, r: Rig): Mesh;
  variant(form: string): BodyVariant | null;
  /** The outline colour (hex) when not the ink (outline.ts INK_ALT; Rukia's zero: ice blue). */
  ink?: number;
}
export type BodyVariant = Partial<Pick<CharBody, 'parts' | 'drawFace' | 'weapon' | 'ink'>> & { spec?: Partial<BodySpec> };

const PARENT: Record<BoneName, BoneName | null> = {
  pelvis: null, spine: 'pelvis', chest: 'spine', neck: 'chest', head: 'neck',
  shoulderR: 'chest', armR: 'shoulderR', foreR: 'armR', handR: 'foreR', weaponR: 'handR',
  shoulderL: 'chest', armL: 'shoulderL', foreL: 'armL', handL: 'foreL', weaponL: 'handL',
  thighR: 'pelvis', shinR: 'thighR', footR: 'shinR', thighL: 'pelvis', shinL: 'thighL', footL: 'shinL',
};
export const hex = (h: number) => new Color3(((h >> 16) & 255) / 255, ((h >> 8) & 255) / 255, (h & 255) / 255);

export interface Part { vd: VertexData; color: Color3; bones: BoneName[] }
export type Add = (vd: VertexData, color: number | Color3, bones: BoneName[]) => void;
export type Ring = [number, number, number, number?, number?];       // y, rx, rz, cx, cz

/** A tube along y through elliptical rings (closed by giving the end rings ~0 radius). The arc a0..a1 (radians, 0 =
 *  front -z, +pi/2 = his right) leaves it open (a haori's front); DOUBLE adds the inside, LIP gives each ring's angle a
 *  y offset (tattered hems). */
export function tube(rings: Ring[], seg = 14, o: { a0?: number; a1?: number; double?: boolean; lip?: (a: number, j: number) => number } = {}): VertexData {
  const a0 = o.a0 ?? 0, a1 = o.a1 ?? Math.PI * 2, closed = o.a0 === undefined;
  const pos: number[] = [], idx: number[] = [], n = seg + 1;
  rings.forEach(([y, rx, rz, cx = 0, cz = 0], j) => {
    for (let k = 0; k <= seg; k++) {
      const a = a0 + ((a1 - a0) * k) / seg;
      pos.push(cx + rx * Math.sin(a), y + (o.lip ? o.lip(a, j) : 0), cz - rz * Math.cos(a));
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
/** Kosode, collar, obi, head, arms with sleeves, the haori, the hakama, tabi and zori. HEAD(add, hc) adds the
 *  character's hair / beard right after the bare head (hc = the skull's centre). */
export function kimono(sp: BodySpec, r: Rig, head?: (add: Add, hc: [number, number, number]) => void): Part[] {
  const { rest: R, H, bs } = r, parts: Part[] = [];
  const add: Add = (vd, color, bones) =>
    parts.push({ vd, color: typeof color === 'number' ? hex(color) : color, bones });
  const y = (v: number) => v * bs, L = sp.limb;
  const torsoB: BoneName[] = ['pelvis', 'spine', 'chest', 'neck', 'shoulderR', 'shoulderL'];
  const [cx, cz] = sp.chest, [wx, wz] = sp.waist, [hx, hz] = sp.hip;
  // torso: the kosode (black), hips to the collar
  add(tube([[y(3.95), 0.02, 0.02], [y(4.0), hx * H * 0.9, hz * H * 0.9], [y(4.4), hx * H, hz * H], [y(5.0), wx * H, wz * H],
    [y(5.6), cx * H * 0.95, cz * H], [y(6.2), cx * H, cz * H * 1.02, 0, 0.02 * H], [y(6.55), cx * H * 0.92, cz * H * 0.9, 0, 0.04 * H],
    [y(6.75), 0.3 * H, 0.3 * H, 0, 0.05 * H], [y(6.8), 0.02, 0.02, 0, 0.05 * H]], 16), sp.black, torsoB);
  // the collar: the white juban lapels in a V, skin inside it
  const deep = sp.collar;
  add(tube([[y(6.75 - deep), 0.02, 0.02, 0, -cz * H * 0.98], [y(6.75 - deep * 0.6), 0.14 * H * deep, 0.04 * H, 0, -cz * H * 1.0],
    [y(6.6), 0.3 * H, 0.05 * H, 0, -cz * H * 0.92], [y(6.8), 0.26 * H, 0.04 * H, 0, -cz * H * 0.7]], 8), sp.skin, ['chest', 'neck']);
  for (const s of [1, -1]) {
    const lap = tube([[y(6.75 - deep), 0.015, 0.015], [y(6.0), 0.05 * H, 0.03 * H], [y(6.8), 0.05 * H, 0.03 * H], [y(6.85), 0.015, 0.015]], 6);
    lap.transform(T(s * 0.14 * H * deep * 0.9, 0, -cz * H * 1.02, 0, 0, s * 0.18 * deep));
    add(lap, 0xf3f1ea, ['chest', 'neck']);
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
    const ar = 0.25 * H * L;
    add(limb(sh.add(new Vector3(0, -0.05 * H, 0)), arm, ar * 1.2, ar * 1.15), sp.black, [`shoulder${S}`, `arm${S}`, 'chest'] as BoneName[]);
    add(limb(arm, el, ar * 1.1, ar * 0.95), sp.black, [`shoulder${S}`, `arm${S}`, `fore${S}`] as BoneName[]);
    add(limb(el, wr, ar * 0.8, ar * 0.62), sp.skin, [`arm${S}`, `fore${S}`, `hand${S}`] as BoneName[]);
    // the kosode's big sleeve: hangs from the upper arm to below the elbow, widest at the bottom (behind the forearm)
    const sl = tube([[0, 0.02, 0.02], [0.05 * H, ar * 1.3, ar * 1.3], [-1.0 * bs, ar * 1.6, ar * 2.2, 0, 0.35 * ar],
      [-1.75 * bs, ar * 1.55, ar * 2.6, 0, 0.6 * ar], [-1.8 * bs, ar * 0.3, ar * 1.0, 0, 0.6 * ar]], 12);
    sl.transform(T(el.x * 0.5 + arm.x * 0.5, arm.y - 0.05 * H, arm.z));
    add(sl, sp.black, [`arm${S}`, `fore${S}`] as BoneName[]);
    // the hand: palm block, a rolled fist of fingers, the thumb
    const hs = sp.hand * H;
    add(ellipsoid([wr.x, wr.y - 0.22 * hs, wr.z], [0.12 * hs, 0.24 * hs, 0.2 * hs], 8, 6), sp.skin, [`hand${S}`, `fore${S}`] as BoneName[]);
    add(ellipsoid([wr.x - s * 0.02 * hs, wr.y - 0.46 * hs, wr.z - 0.02 * hs], [0.15 * hs, 0.14 * hs, 0.22 * hs], 8, 6), sp.skin, [`hand${S}`] as BoneName[]);
    add(limb(new Vector3(wr.x - s * 0.1 * hs, wr.y - 0.12 * hs, wr.z - 0.18 * hs), new Vector3(wr.x - s * 0.14 * hs, wr.y - 0.36 * hs, wr.z - 0.26 * hs),
      0.07 * hs, 0.06 * hs, 6), sp.skin, [`hand${S}`] as BoneName[]);
    // haori sleeve (white) over it all
    if (sp.haoriSleeves === 'long') {
      const hsl = tube([[0.08 * H, ar * 1.5, ar * 1.5], [-0.9 * bs, ar * 1.85, ar * 2.4, 0, 0.3 * ar],
        [-1.6 * bs, ar * 1.8, ar * 2.8, 0, 0.6 * ar], [-1.62 * bs, ar * 0.4, ar * 1.0, 0, 0.6 * ar]], 12);
      hsl.transform(T(el.x * 0.5 + arm.x * 0.5, arm.y, arm.z));
      add(hsl, sp.haori, [`arm${S}`, `fore${S}`] as BoneName[]);
    } else {
      const hsl = tube([[0.08 * H, ar * 1.5, ar * 1.5], [-0.5 * bs, ar * 1.6, ar * 1.7], [-0.75 * bs, ar * 1.5, ar * 1.65]], 12,
        { double: true, a0: 0.001, a1: Math.PI * 2 - 0.001, lip: (a, j) => (j === 2 ? 0.07 * H * Math.sin(a * 5) : 0) });
      hsl.transform(T(arm.x, arm.y, arm.z, 0, 0, s * 0.08));
      add(hsl, sp.haori, [`shoulder${S}`, `arm${S}`] as BoneName[]);
    }
  }
  // the haori body: white coat over the kosode, open at the front, flared down to the hem (skinned to pelvis / thighs)
  const tat = sp.tattered;
  const hem = (a: number, j: number) => (j >= 5 && tat ? 0.16 * H * (Math.sin(a * 7) * 0.6 + Math.sin(a * 13 + 1) * 0.4) : 0);
  const ho = 1.12, fr = 0.42;
  add(tube([[y(6.8), 0.36 * H, 0.32 * H, 0, 0.06 * H], [y(6.6), cx * H * ho * 0.95, cz * H * ho, 0, 0.03 * H],
    [y(6.1), cx * H * ho, cz * H * ho * 1.04, 0, 0.02 * H], [y(5.2), wx * H * ho * 1.1, wz * H * ho * 1.15],
    [y(4.3), hx * H * ho * 1.12, hz * H * ho * 1.2], [y(3.3), hx * H * ho * 1.35, hz * H * ho * 1.45, 0, 0.05 * H],
    [y(sp.haoriHem), hx * H * ho * 1.62, hz * H * ho * 1.8, 0, 0.12 * H]], 18,
  { a0: fr, a1: Math.PI * 2 - fr, double: true, lip: hem }), sp.haori, ['pelvis', 'spine', 'chest', 'thighR', 'thighL', 'shoulderR', 'shoulderL']);
  // the hakama: two wide flared trouser legs over the thighs and shins (each rides its own leg, the waist the pelvis)
  for (const s of [1, -1] as const) {
    const S = s > 0 ? 'R' : 'L', th = R[`thigh${S}`], kn = R[`shin${S}`], an = R[`foot${S}`];
    const lr = 0.42 * H * L;
    add(tube([[y(4.45), lr * 1.15, lr * 1.2, -s * 0.12 * H, 0], [th.y - 0.1 * bs, lr * 1.15, lr * 1.25, s * 0.02 * H, 0],
      [kn.y, lr * 1.35, lr * 1.45, s * 0.06 * H, 0], [an.y + 0.25 * bs, lr * 1.6, lr * 1.7, s * 0.07 * H, 0],
      [an.y + 0.12 * bs, lr * 1.62, lr * 1.72, s * 0.07 * H, 0], [an.y + 0.11 * bs, lr * 0.5, lr * 0.5, s * 0.06 * H, 0]], 14),
    sp.black, ['pelvis', `thigh${S}`, `shin${S}`] as BoneName[]);
    // the white tabi and the straw zori
    add(limb(new Vector3(an.x, an.y + 0.15 * bs, an.z + 0.05 * H), new Vector3(an.x, an.y - 0.15 * bs, an.z - 0.05 * H), 0.16 * H, 0.15 * H, 8),
      0xf3f3ee, [`shin${S}`, `foot${S}`] as BoneName[]);
    add(box(0.3 * H, 0.16 * bs, 0.95 * H, T(an.x, 0.12 * bs, an.z - 0.3 * H)), 0xf3f3ee, [`foot${S}`] as BoneName[]);
    add(box(0.34 * H, 0.06 * bs, 1.02 * H, T(an.x, 0.03 * bs, an.z - 0.3 * H)), 0xc4a273, [`foot${S}`] as BoneName[]);
  }
  return parts;
}

// ---------------------------------------------------------------- assembly
export interface BuiltBody {
  mesh: Mesh; skeleton: Skeleton; bones: Record<BoneName, Bone>; rig: Rig; spec: BodySpec;
  weapon: Mesh; face: Mesh; faceTex: DynamicTexture; faceMat: StandardMaterial;
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
  const pos: number[] = [], nrm: number[] = [], col: number[] = [], idx: number[] = [], mi: number[] = [], mw: number[] = [];
  const tmp = new Vector3();
  for (const part of cb.parts(sp, r)) {
    const P = part.vd.positions as number[], N = part.vd.normals as number[], I = part.vd.indices as number[], base = pos.length / 3;
    for (let i = 0; i < P.length; i += 3) {
      pos.push(P[i], P[i + 1], P[i + 2]); nrm.push(N[i], N[i + 1], N[i + 2]);
      col.push(part.color.r, part.color.g, part.color.b, 1);
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
  mesh.skeleton = skeleton; mesh.numBoneInfluencers = 2; mesh.material = mat;
  // weapon (rigid, attached to the right hand's grip)
  const weapon = cb.weapon(scene, sp, r);
  weapon.material = weaponMat;
  weapon.attachToBone(bones.weaponR, mesh);
  // face decal on the head bone
  const H = r.H, faceTex = new DynamicTexture(`${key}-face`, { width: 768, height: 256 }, scene, true);
  drawFaces(faceTex, cb.drawFace);
  faceTex.hasAlpha = true; faceTex.uScale = 1 / 3; faceTex.wrapU = Texture.CLAMP_ADDRESSMODE;
  const faceMat = new StandardMaterial(`${key}-facemat`, scene);
  faceMat.diffuseTexture = faceTex; faceMat.useAlphaFromDiffuseTexture = true; faceMat.transparencyMode = 1;   // alpha test
  faceMat.disableLighting = true; faceMat.emissiveColor = Color3.White(); faceMat.backFaceCulling = false;
  const face = MeshBuilder.CreatePlane(`${key}-face`, { size: 0.84 * H }, scene);
  face.material = faceMat;
  face.attachToBone(bones.head, mesh);
  face.position.set(0, 0.42 * H, -0.02 * H - 0.425 * H);
  face.scaling.x = -1;                  // the plane's front faces +z in this right-handed scene: mirror it to face -z
  return { mesh, skeleton, bones, rig: r, spec: sp, weapon, face, faceTex, faceMat };
}

/** Merge rigid vertex-coloured pieces into one mesh (weapons). */
export function rigid(scene: Scene, name: string, parts: { vd: VertexData; c: number }[]): Mesh {
  const pos: number[] = [], nrm: number[] = [], col: number[] = [], idx: number[] = [];
  for (const p of parts) {
    const base = pos.length / 3, c = hex(p.c);
    pos.push(...(p.vd.positions as number[])); nrm.push(...(p.vd.normals as number[]));
    for (let i = 0; i < p.vd.positions!.length / 3; i++) col.push(c.r, c.g, c.b, 1);
    for (const k of p.vd.indices as number[]) idx.push(base + k);
  }
  const vd = new VertexData();
  Object.assign(vd, { positions: pos, normals: nrm, colors: col, indices: idx });
  const m = new Mesh(name, scene);
  vd.applyToMesh(m);
  return m;
}

/** A katana in the fist: the grip at the weapon bone, the blade forward (-z). CHIPS notches the edge; GUARD (colour)
 *  adds a small tsuba. */
export function katana(scene: Scene, o: { blade: number; grip: number; w: number; bladeC: number; gripC: number; chips?: boolean; guard?: number }): Mesh {
  const parts: { vd: VertexData; c: number }[] = [];
  const rings: Ring[] = [];
  const n = 28;
  for (let i = 0; i <= n; i++) {
    const t = i / n, chip = o.chips && i % 6 === 4 ? 0.8 : 1;
    const tip = t > 0.9 ? 1 - (t - 0.9) / 0.1 * 0.95 : 1;
    rings.push([t * o.blade, 0.006, o.w * chip * tip, 0, o.w * (1 - chip * tip) * 0.5]);
  }
  const bl = tube(rings, 4);
  // the blade leaves the fist along the forearm's line, tipped 20 deg forward (the grip's angle in a fist)
  const mt = 20 * Math.PI / 180, dy = -Math.cos(mt), dz = -Math.sin(mt), g0 = 0.07;
  bl.transform(T(0, dy * g0, dz * g0, Math.PI + mt));
  parts.push({ vd: bl, c: o.bladeC });
  const gr = tube([[0, 0.016, 0.02], [o.grip, 0.017, 0.021], [o.grip + 0.01, 0.005, 0.005]], 8);
  gr.transform(T(0, dy * g0, dz * g0, mt));
  parts.push({ vd: gr, c: o.gripC });
  if (o.guard !== undefined) parts.push({ vd: box(0.012, 0.075, 0.09, T(0, dy * g0, dz * g0, mt)), c: o.guard });
  return rigid(scene, 'weapon', parts);
}

// ---------------------------------------------------------------- faces: neutral / shout / hurt, one 256 px cell each
export const FACE = { neutral: 0, shout: 1, hurt: 2 } as const;
/** A bold ink polyline (x0 y0 x1 y1 ...) in the current stroke style: a head is ~40 px on screen. */
export function inkLine(g: CanvasRenderingContext2D, w: number, ...p: number[]): void {
  g.lineWidth = w * 2.2;
  g.beginPath(); g.moveTo(p[0], p[1]); for (let i = 2; i < p.length; i += 2) g.lineTo(p[i], p[i + 1]); g.stroke();
}
function drawFaces(t: DynamicTexture, draw: CharBody['drawFace']): void {
  const g = t.getContext() as CanvasRenderingContext2D;
  g.clearRect(0, 0, 768, 256);
  for (let e = 0; e < 3; e++) {
    g.save(); g.translate(e * 256, 0);
    g.lineCap = 'round'; g.lineJoin = 'round'; g.strokeStyle = '#1a1414'; g.fillStyle = '#1a1414';
    draw(g, e);
    g.restore();
  }
  t.update();
}

// ---------------------------------------------------------------- placeholder bodies (until a character gets its own)
const PLAIN: BodySpec = { height: 1.7, heads: 7.5, shoulder: 1.0, chest: [0.7, 0.44], waist: [0.55, 0.4], hip: [0.62, 0.42], limb: 1,
  hand: 1.15, skin: 0xe8c4a0, black: 0x24252e, haori: 0xf1efe8, obi: 0xe4e1d8, hair: 0x1b1c24, collar: 0.8, haoriHem: 1.6,
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
    weapon: (scene) => katana(scene, { blade: 0.9, grip: 0.25, w: 0.03, bladeC: 0xd0d4de, gripC: 0x2b2b38, guard: 0x3a3426 }),
    variant: () => null,
  };
}
