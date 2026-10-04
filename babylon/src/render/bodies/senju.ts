// Shutara Senjumaru (DUEL_SENJUMARU §2, BABYLON_LOOK B3): 158 cm on tall black okobo (the rig is the hurt height 1.7 m;
// the clogs are its bottom 0.1 m, under an ankle-length robe), a white haori over a white over-robe with the black
// shihakusho showing at the collar, empty white sleeves hanging from the shoulders, long straight black hair with side
// locks and a blunt fringe, a gold crescent with rays standing off the back of her head. The rig's two arms are the upper
// pair of her six gold bone arms (rooted a little behind the shoulders); the other four are "echo arms" (EXTRA below:
// gold bone chains from her upper back to the rig hands' positions 2 / 4 frames ago, turned about her spine by +-28 /
// +-52 deg; at rest a half-fan behind her framing the crescent). The needle 刺絡 (0.9 m, white-gold) is the weapon; its
// red thread trails the hand (base form only). The Bankai forms keep this body (the domain is stage / VFX work).
import { Bone, Matrix, Mesh, Quaternion, Skeleton, Vector3, VertexData, type Scene } from '@babylonjs/core';
import { T, box, ellipsoid, hex, inkLine, limb, rigid, tube, type Add, type BodyExtra, type BodySpec, type BuiltBody,
  type CharBody, type Part, type Rig, type Ring } from '../body';
import type { BoneName } from '../pose';

/** Lit / shadow pairs (BABYLON_LOOK palette rule; the vertex colour is the lit one until cel.ts takes per-colour
 *  shadows). Gold and madder stay muted (DUEL_SENJUMARU §2: not spot hues). */
export const SJ_PAL = {
  robe: [0xeeece6, 0xa4adc8], haori: [0xf8f6f0, 0xaab3cf], lining: [0xc9ccd6, 0x8a90a8], black: [0x2b2d3a, 0x121319],
  skin: [0xf2dccc, 0xc4988a], hair: [0x2a2b38, 0x0e0f15], shine: [0xd8dce4, 0x9aa0b4], gold: [0xc9a85c, 0x8a6a34],
  goldL: [0xe2c784, 0xa08048], lacquer: [0x2a1e22, 0x120c0e], madder: [0xa8434a, 0x6a2228], tabi: [0xf3f3ee, 0xb4b8c8],
  needle: [0xf4eedc, 0xb8ae90], thread: [0xd0283c, 0x801420],
} as const;
const L = (k: keyof typeof SJ_PAL) => SJ_PAL[k][0];
const V = (a: number, b: number, c: number) => new Vector3(a, b, c);

/** VD with its faces turned inside out (a lining seen through an opening). */
function flip(vd: VertexData): VertexData {
  const o = new VertexData(), I = vd.indices as number[];
  o.positions = (vd.positions as number[]).slice();
  o.normals = (vd.normals as number[]).map((v) => -v);
  o.indices = I.map((_, i) => I[i - (i % 3) + [0, 2, 1][i % 3]]);
  return o;
}
/** A flat slab between an OUTER and an INNER polyline in the x-y plane, DEPTH thick (the crescent). */
function slab(outer: [number, number][], inner: [number, number][], depth: number): VertexData {
  const pos: number[] = [], idx: number[] = [], n = outer.length, h = depth / 2;
  const strip = (a: [number, number][], za: number, b: [number, number][], zb: number) => {
    const base = pos.length / 3;
    for (let i = 0; i < n; i++) pos.push(a[i][0], a[i][1], za, b[i][0], b[i][1], zb);
    for (let i = 0; i + 1 < n; i++) { const p = base + 2 * i; idx.push(p, p + 1, p + 2, p + 2, p + 1, p + 3); }
  };
  strip(outer, -h, inner, -h); strip(inner, h, outer, h); strip(outer, h, outer, -h); strip(inner, -h, inner, h);
  const vd = new VertexData(), nrm: number[] = [];
  VertexData.ComputeNormals(pos, idx, nrm);
  vd.positions = pos; vd.indices = idx; vd.normals = nrm;
  return vd;
}

/** A flat-faced bone bar from A to B, W wide and D deep (tapered to TAPER at B): the screen-space outline inks a thin
 *  round tube solid (its normals turn too fast), a bar keeps its gold faces. */
function bar(a: Vector3, b: Vector3, w: number, d: number, taper = 0.8): VertexData {
  const len = Vector3.Distance(a, b), pos: number[] = [], idx: number[] = [];
  const c = [[-1, -1], [1, -1], [1, 1], [-1, 1]];
  const ring = (y: number, k: number) => c.map(([x, z]) => [x * w * k / 2, y, z * d * k / 2]);
  const r0 = ring(0, 1), r1 = ring(len, taper);
  for (let i = 0; i < 4; i++) {                          // four sides, own vertices each (flat normals)
    const j = (i + 1) % 4, base = pos.length / 3;
    pos.push(...r0[i], ...r0[j], ...r1[j], ...r1[i]);
    idx.push(base, base + 2, base + 1, base, base + 3, base + 2);
  }
  for (const [r, f] of [[r0, false], [r1, true]] as const) {
    const base = pos.length / 3;
    for (const v of r) pos.push(...v);
    if (f) idx.push(base, base + 1, base + 2, base, base + 2, base + 3); else idx.push(base, base + 2, base + 1, base, base + 3, base + 2);
  }
  const vd = new VertexData(), nrm: number[] = [];
  VertexData.ComputeNormals(pos, idx, nrm);
  // outward check (the winding): flip if the side normals point at the axis
  if (nrm[0] * pos[0] + nrm[2] * pos[2] < 0) { for (let i = 0; i < idx.length; i += 3) [idx[i + 1], idx[i + 2]] = [idx[i + 2], idx[i + 1]]; nrm.length = 0; VertexData.ComputeNormals(pos, idx, nrm); }
  vd.positions = pos; vd.indices = idx; vd.normals = nrm;
  const dir = b.subtract(a).normalize(), ax = Vector3.Cross(new Vector3(0, 1, 0), dir), dd = Math.max(-1, Math.min(1, dir.y));
  const q = ax.lengthSquared() < 1e-10 ? Quaternion.RotationAxis(Vector3.Right(), dd < 0 ? Math.PI : 0) : Quaternion.RotationAxis(ax.normalize(), Math.acos(dd));
  vd.transform(Matrix.Compose(Vector3.One(), q, a));
  return vd;
}

/** The upper pair of gold bone arms (the rig's own arms, at rest): a humerus rooted a little behind the shoulder, two
 *  forearm bones, knuckled joints, a skeletal hand (palm inward, four long finger bones, the thumb forward). They are
 *  drawn by the echo mesh on copies of the rig's bones (with the crescent on the head's), so they share its thin ink line (the fighter's thick line
 *  inks thin gold bones solid black). */
function rigGold(sp: BodySpec, r: Rig): { vd: VertexData; c: number; bn: BoneName }[] {
  const { rest: R, H } = r, out: { vd: VertexData; c: number; bn: BoneName }[] = [], back = V(0, 0.02 * H, 0.22 * H);
  // the crescent with rays: a gold halo standing off the back of the skull, horns up (on the head bone)
  const hc = [0, R.head.y + 0.42 * H, R.head.z - 0.02 * H];
  const cy = hc[1] + 0.55 * H, cz0 = hc[2] + 0.62 * H, Ro = 1.3 * H, A = 1.95, N = 24;
  const outer: [number, number][] = [], inner: [number, number][] = [];
  for (let i = 0; i <= N; i++) {
    const a = -A + (2 * A * i) / N, w = 0.26 * H * Math.pow(Math.cos(((a / A) * Math.PI) / 2), 0.7) + 0.08 * H;
    outer.push([Ro * Math.sin(a), cy - Ro * Math.cos(a)]); inner.push([(Ro - w) * Math.sin(a), cy - (Ro - w) * Math.cos(a)]);
  }
  const moon = slab(outer, inner, 0.05 * H);
  moon.transform(T(0, 0, cz0));
  out.push({ vd: moon, c: L('gold'), bn: 'head' }, { vd: flip(moon), c: L('gold'), bn: 'head' });   // (two-sided)
  for (let i = 0; i < 7; i++) {
    const a = -1.6 + (3.2 * i) / 6, d = V(Math.sin(a), -Math.cos(a), 0), p0 = V(0, cy, cz0).add(d.scale(Ro * 0.98));
    out.push({ vd: bar(p0, p0.add(d.scale((i % 2 ? 0.4 : 0.62) * H)), 0.16 * H, 0.05 * H, 0.15), c: L('goldL'), bn: 'head' });
  }
  for (const s of [1, -1] as const) {
    const S = s > 0 ? 'R' : 'L', sh = R[`arm${S}`].add(back), el = R[`fore${S}`], wr = R[`hand${S}`];
    const ab = `arm${S}` as BoneName, fb = `fore${S}` as BoneName, hb = `hand${S}` as BoneName, hs = sp.hand * H;
    const add = (vd: VertexData, c: number, bn: BoneName) => out.push({ vd, c, bn });
    add(ellipsoid([sh.x, sh.y, sh.z], [0.17 * H, 0.17 * H, 0.17 * H], 8, 6), L('goldL'), ab);
    add(bar(sh, el, 0.26 * H, 0.18 * H), L('gold'), ab);
    add(ellipsoid([el.x, el.y, el.z], [0.15 * H, 0.15 * H, 0.15 * H], 8, 6), L('goldL'), fb);
    for (const k of [1, -1]) add(bar(el.add(V(0, 0, k * 0.07 * H)), wr.add(V(0, 0, k * 0.06 * H)), 0.14 * H, 0.1 * H), L('gold'), fb);
    add(ellipsoid([wr.x, wr.y - 0.2 * hs, wr.z], [0.09 * hs, 0.24 * hs, 0.24 * hs], 8, 6), L('goldL'), hb);
    for (let f = 0; f < 4; f++) {
      const dz = (f - 1.5) * 0.11 * hs, b0 = V(wr.x, wr.y - 0.38 * hs, wr.z + dz), len = [0.5, 0.56, 0.52, 0.42][f] * hs;
      add(bar(b0, b0.add(V(-s * 0.06 * hs, -len, dz * 0.4 - 0.08 * hs)), 0.08 * hs, 0.09 * hs, 0.7), L('gold'), hb);
    }
    add(bar(V(wr.x - s * 0.02 * hs, wr.y - 0.14 * hs, wr.z - 0.18 * hs), V(wr.x - s * 0.12 * hs, wr.y - 0.44 * hs, wr.z - 0.36 * hs),
      0.09 * hs, 0.08 * hs, 0.7), L('gold'), hb);
  }
  return out;
}

function parts(sp: BodySpec, r: Rig): Part[] {
  const { rest: R, H, bs } = r, out: Part[] = [];
  const add: Add = (vd, c, bones) => out.push({ vd, color: typeof c === 'number' ? hex(c) : c, bones });
  const y = (v: number) => v * bs;
  const [cx, cz] = sp.chest, [wx, wz] = sp.waist, [hx, hz] = sp.hip;
  const torso: BoneName[] = ['pelvis', 'spine', 'chest', 'neck', 'shoulderR', 'shoulderL'];
  const hemY = 0.11;                                                   // the robe's hem: just over the clogs
  // the white over-robe: the torso, then a long bell skirt to the ankles (riding the thighs and shins a little)
  add(tube([[y(4.6), 0.02, 0.02], [y(4.65), wx * H, wz * H], [y(5.0), wx * H, wz * H], [y(5.6), cx * H * 0.95, cz * H],
    [y(6.2), cx * H, cz * H * 1.02, 0, 0.02 * H], [y(6.55), cx * H * 0.9, cz * H * 0.9, 0, 0.04 * H],
    [y(6.75), 0.3 * H, 0.3 * H, 0, 0.05 * H], [y(6.8), 0.02, 0.02, 0, 0.05 * H]], 16), L('robe'), torso);
  add(tube([[y(4.9), wx * H * 1.02, wz * H * 1.02], [y(4.3), hx * H, hz * H], [y(3.4), hx * H * 1.08, hz * H * 1.04],
    [y(2.2), hx * H * 1.16, hz * H * 1.1], [y(1.1), hx * H * 1.26, hz * H * 1.16], [hemY, hx * H * 1.46, hz * H * 1.28],
    [hemY + 0.005, hx * H * 0.5, hz * H * 0.5]], 18), L('robe'), ['pelvis', 'thighR', 'thighL', 'shinR', 'shinL']);
  for (const s of [1, -1]) {                                           // two long fold lines down the skirt front
    add(limb(V(s * 0.25 * H, y(4.1), -hz * H * 1.02), V(s * 0.42 * H, hemY + 0.06, -hz * H * 1.22), 0.008, 0.006, 4),
      L('lining'), ['pelvis', s > 0 ? 'thighR' : 'thighL', s > 0 ? 'shinR' : 'shinL']);
  }
  // the collar: skin in the V, the black shihakusho lapels, the white haori's broad collar band down its front edge
  add(tube([[y(6.2), 0.02, 0.02, 0, -cz * H * 0.98], [y(6.4), 0.1 * H, 0.04 * H, 0, -cz * H], [y(6.62), 0.26 * H, 0.05 * H, 0, -cz * H * 0.92],
    [y(6.8), 0.24 * H, 0.04 * H, 0, -cz * H * 0.7]], 8), L('skin'), ['chest', 'neck']);
  for (const s of [1, -1]) {
    add(limb(V(s * 0.02 * H, y(5.5), -0.42 * H), V(s * 0.2 * H, y(6.85), -0.27 * H), 0.05 * H, 0.05 * H, 6, 0.3), L('black'), ['chest', 'neck', 'spine']);
  }
  // the obi: a pale sash with a gold cord over it
  add(tube([[y(4.62), wx * H * 1.08, wz * H * 1.1], [y(4.95), wx * H * 1.09, wz * H * 1.12], [y(4.96), wx * H * 0.5, wz * H * 0.5]], 16),
    L('lining'), ['pelvis', 'spine']);
  add(tube([[y(4.76), wx * H * 1.11, wz * H * 1.14], [y(4.82), wx * H * 1.12, wz * H * 1.15]], 16), L('gold'), ['pelvis', 'spine']);
  // the haori: open at the front, to mid-calf, lined in pale grey (the lining shows through the opening)
  const ho = 1.1, fr = 0.5;
  const haoriRings: Ring[] = [[y(6.82), 0.34 * H, 0.32 * H, 0, 0.06 * H], [y(6.6), cx * H * ho * 0.95, cz * H * ho, 0, 0.03 * H],
    [y(6.1), cx * H * ho, cz * H * ho * 1.04, 0, 0.02 * H], [y(5.2), wx * H * ho * 1.12, wz * H * ho * 1.16],
    [y(4.3), hx * H * ho * 1.1, hz * H * ho * 1.18], [y(3.2), hx * H * ho * 1.24, hz * H * ho * 1.3, 0, 0.03 * H],
    [y(1.9), hx * H * ho * 1.38, hz * H * ho * 1.42, 0, 0.06 * H],
    [y(sp.haoriHem), hx * H * ho * 1.5, hz * H * ho * 1.52, 0, 0.08 * H]];
  const haoriB: BoneName[] = ['pelvis', 'spine', 'chest', 'thighR', 'thighL', 'shoulderR', 'shoulderL'];
  add(tube(haoriRings, 20, { a0: fr, a1: Math.PI * 2 - fr }), L('haori'), haoriB);
  add(flip(tube(haoriRings.map(([a, b, c, d, e]) => [a, b * 0.97, c * 0.97, d, e] as Ring), 20, { a0: fr, a1: Math.PI * 2 - fr })),
    L('lining'), haoriB);
  // neck, head (the generic skull, so the face decal sits where buildBody puts it)
  add(limb(R.neck.add(V(0, -0.1 * H, 0)), R.head.add(V(0, 0.25 * H, 0)), 0.17 * H, 0.15 * H), L('skin'), ['neck', 'head', 'chest']);
  const hc: [number, number, number] = [0, R.head.y + 0.42 * H, R.head.z - 0.02 * H];
  add(ellipsoid(hc, [0.35 * H, 0.47 * H, 0.42 * H], 16, 10), L('skin'), ['head']);
  add(ellipsoid([0, hc[1] - 0.28 * H, hc[2] - 0.22 * H], [0.21 * H, 0.16 * H, 0.19 * H]), L('skin'), ['head']);
  add(ellipsoid([0, hc[1] - 0.06 * H, hc[2] - 0.43 * H], [0.035 * H, 0.06 * H, 0.04 * H], 6, 5), L('skin'), ['head']);
  // hair: the cap, the blunt fringe (hime cut), the straight fall down her back, the side locks to the chest, highlights
  const hb: BoneName[] = ['head'];
  add(ellipsoid([0, hc[1] + 0.06 * H, hc[2] + 0.1 * H], [0.4 * H, 0.5 * H, 0.44 * H], 16, 10), L('hair'), hb);   // (behind the face)
  add(tube([[hc[1] + 0.17 * H, 0.42 * H, 0.47 * H, 0, hc[2] + 0.02 * H], [hc[1] + 0.3 * H, 0.42 * H, 0.47 * H, 0, hc[2] + 0.02 * H],
    [hc[1] + 0.5 * H, 0.36 * H, 0.4 * H, 0, hc[2] + 0.04 * H]], 14, { a0: -1.15, a1: 1.15, double: true }), L('hair'), hb);
  const backZ = cz * H * 1.15 + 0.03 * H;
  add(tube([[hc[1] + 0.3 * H, 0.34 * H, 0.2 * H, 0, hc[2] + 0.28 * H], [hc[1] - 0.2 * H, 0.42 * H, 0.16 * H, 0, hc[2] + 0.36 * H],
    [y(6.6), 0.46 * H, 0.12 * H, 0, backZ + 0.08 * H], [y(5.6), 0.42 * H, 0.08 * H, 0, backZ + 0.06 * H],
    [y(4.7), 0.36 * H, 0.06 * H, 0, backZ + 0.04 * H], [y(4.5), 0.05 * H, 0.03 * H, 0, backZ + 0.04 * H]], 12),
  L('hair'), ['head', 'neck', 'chest', 'spine']);
  for (const s of [1, -1]) {
    add(limb(V(s * 0.37 * H, hc[1] + 0.2 * H, hc[2] - 0.12 * H), V(s * 0.42 * H, hc[1] - 0.55 * H, hc[2] - 0.22 * H), 0.1 * H, 0.08 * H, 8, 0.5),
      L('hair'), ['head']);
    add(limb(V(s * 0.42 * H, hc[1] - 0.5 * H, hc[2] - 0.22 * H), V(s * 0.46 * H, y(5.9), -cz * H * 1.05), 0.08 * H, 0.02 * H, 8, 0.5),
      L('hair'), ['head', 'neck', 'chest']);
  }
  for (const [x0, y0, x1, y1] of [[-0.18, 0.42, -0.3, 0.2], [0.02, 0.48, -0.06, 0.24], [0.2, 0.42, 0.26, 0.24]])
    add(limb(V(x0 * H, hc[1] + y0 * H, hc[2] - 0.32 * H), V(x1 * H, hc[1] + y1 * H, hc[2] - 0.44 * H), 0.025 * H, 0.008 * H, 5),
      L('shine'), hb);
  // (the gold crescent rides the echo mesh too: RIGGOLD)
  // the empty sleeves: wide white haori sleeves hanging from the shoulders (her own arms stay inside), black inside
  for (const s of [1, -1] as const) {
    const S = s > 0 ? 'R' : 'L', sh = R[`arm${S}`], sb = [`shoulder${S}`, 'chest'] as BoneName[];
    const rings: Ring[] = [[0.06 * H, 0.2 * H, 0.22 * H], [-0.4 * H, 0.26 * H, 0.42 * H, 0.03 * H, 0.04 * H],
      [-1.5 * H, 0.26 * H, 0.66 * H, 0.06 * H, 0.1 * H], [-1.95 * H, 0.22 * H, 0.7 * H, 0.06 * H, 0.12 * H]];
    const m = T(sh.x + s * 0.05 * H, sh.y, sh.z + 0.04 * H, 0, 0, s * 0.12);
    const sl = tube(rings.map(([a, b, c, d = 0, e]) => [a, b, c, s * d, e] as Ring), 14); sl.transform(m);
    add(sl, L('haori'), sb);
    const li = flip(tube(rings.slice(1).map(([a, b, c, d = 0, e]) => [a, b * 0.92, c * 0.94, s * d, e] as Ring), 14)); li.transform(m);
    add(li, L('black'), sb);
  }
  // (the upper pair of gold bone arms, the rig's arms, ride the echo mesh: RIGARMS, the weapon's thin ink line)
  // the okobo (black lacquer, a madder thong) with the white tabi standing on them
  for (const s of [1, -1] as const) {
    const S = s > 0 ? 'R' : 'L', an = R[`foot${S}`], fb = [`foot${S}`] as BoneName[];
    add(box(0.075, 0.1, 0.19, T(an.x, 0.05, an.z - 0.05)), L('lacquer'), fb);
    add(limb(V(an.x, 0.125, an.z + 0.04), V(an.x, 0.12, an.z - 0.12), 0.034, 0.03, 8), L('tabi'), fb);
    add(box(0.016, 0.02, 0.06, T(an.x, 0.15, an.z - 0.08)), L('madder'), fb);
  }
  return out;
}

// ---------------------------------------------------------------- the four echo arms and the needle's thread
// per arm: side (+1 her right), spread about the spine (deg), lag (frames), the anchor's height on her back (chest frame)
const ARMS: [number, number, number, number][] = [[1, 28, 2, 0.08], [-1, 28, 2, 0.08], [1, 52, 4, -0.16], [-1, 52, 4, -0.16]];
const PER = 4, THREAD = 5, TH0 = ARMS.length * PER;            // bones: upper (stretched), elbow, lower (stretched), hand
const RIG: BoneName[] = ['armR', 'foreR', 'handR', 'armL', 'foreL', 'handL', 'head'], RIG0 = TH0 + THREAD;   // copies of the rig's arm bones
const UP = V(0, 1, 0);

interface EchoArms extends BodyExtra { pts: Vector3[] }
/** The look points of a built Senjumaru body in world space (for the VFX: the umbrella / loom threads drawn between the
 *  six hands): the needle's eye, the two rig hands, the four echo hands. Null for any other body. */
export function senjuPoints(b: BuiltBody): { eye: Vector3; hands: Vector3[] } | null {
  const x = (b.extra as EchoArms | undefined)?.pts;
  if (!x) return null;
  const w = b.mesh.getWorldMatrix();
  return { eye: Vector3.TransformCoordinates(x[0], w), hands: x.slice(1).map((p) => Vector3.TransformCoordinates(p, w)) };
}

function echoArms(scene: Scene, b: BuiltBody): EchoArms {
  const H = b.rig.H, hs = b.spec.hand * H, skel = new Skeleton('sj-echo', 'sj-echo', scene), bones: Bone[] = [];
  for (let i = 0; i < RIG0 + RIG.length; i++) bones.push(new Bone(`e${i}`, skel, null, Matrix.Identity()));
  // unit pieces along +y, one bone each (the shafts are stretched to length, the joints and hands rigid)
  const pos: number[] = [], nrm: number[] = [], col: number[] = [], idx: number[] = [], mi: number[] = [], mw: number[] = [];
  const put = (vd: VertexData, c: number, bi: number) => {
    const P = vd.positions as number[], N = vd.normals as number[], base = pos.length / 3, k = hex(c);
    for (let i = 0; i < P.length; i += 3) {
      pos.push(P[i], P[i + 1], P[i + 2]); nrm.push(N[i], N[i + 1], N[i + 2]); col.push(k.r, k.g, k.b, 1); mi.push(bi, 0, 0, 0); mw.push(1, 0, 0, 0);
    }
    for (const j of vd.indices as number[]) idx.push(base + j);
  };
  const O = Vector3.Zero(), Y1 = V(0, 1, 0);
  for (let a = 0; a < ARMS.length; a++) {
    put(bar(O, Y1, 0.22 * H, 0.16 * H), L('gold'), PER * a);
    put(ellipsoid([0, 0, 0], [0.14 * H, 0.14 * H, 0.14 * H], 7, 5), L('goldL'), PER * a + 1);
    put(bar(O, Y1, 0.15 * H, 0.11 * H), L('gold'), PER * a + 2);
    put(ellipsoid([0, 0.18 * hs, 0], [0.24 * hs, 0.22 * hs, 0.09 * hs], 7, 5), L('goldL'), PER * a + 3);
    for (let f = 0; f < 4; f++) {
      const dx = (f - 1.5) * 0.11 * hs;
      put(bar(V(dx, 0.34 * hs, 0), V(dx * 1.4, (0.34 + [0.46, 0.52, 0.48, 0.38][f]) * hs, 0.06 * hs), 0.09 * hs, 0.07 * hs, 0.7),
        L('gold'), PER * a + 3);
    }
  }
  for (let t = 0; t < THREAD; t++) put(limb(O, Y1, 0.01, 0.01, 4), L('thread'), TH0 + t);
  for (const p of rigGold(b.spec, b.rig)) put(p.vd, p.c, RIG0 + RIG.indexOf(p.bn));
  const vd = new VertexData();
  Object.assign(vd, { positions: pos, normals: nrm, colors: col, indices: idx, matricesIndices: mi, matricesWeights: mw });
  const mesh = new Mesh('sj-echo', scene);
  vd.applyToMesh(mesh);
  mesh.skeleton = skel; mesh.numBoneInfluencers = 1; mesh.material = b.weapon.material;   // (the weapon's thin ink line)
  mesh.parent = b.mesh; mesh.alwaysSelectAsActiveMesh = true;

  // the rig hands' history (60 Hz samples, newest first) and ACT (0: the rest fan, 1: following the strike)
  const hist: Vector3[][] = Array.from({ length: 8 }, () => [V(0, 0, 0), V(0, 0, 0)]);
  let filled = false, acc = 0, act = 0;
  const pts = Array.from({ length: 7 }, () => V(0, 0, 0)), q = new Quaternion(), sc = V(1, 1, 1);
  const mt0 = new Matrix(), ds = V(1, 1, 1), dq = new Quaternion(), dp = V(0, 0, 0);
  const at = (bn: BoneName, x: number, yy: number, z: number, o = V(0, 0, 0)) => {
    Vector3.TransformCoordinatesFromFloatsToRef(x, yy, z, b.bones[bn].getAbsoluteMatrix(), o);
    return o;
  };
  /** Bone I: its unit piece from A along unit DIR, stretched to LEN along y (or rigid). */
  const seg = (i: number, a: Vector3, dir: Vector3, len: number, stretch: boolean) => {
    const ax = Vector3.Cross(UP, dir), d = Math.max(-1, Math.min(1, Vector3.Dot(UP, dir)));
    if (ax.lengthSquared() < 1e-10) Quaternion.RotationAxisToRef(Vector3.Right(), d < 0 ? Math.PI : 0, q);
    else Quaternion.RotationAxisToRef(ax.normalize(), Math.acos(d), q);
    sc.set(1, stretch ? len : 1, 1);
    const bn = bones[i];
    bn.position = a; bn.rotationQuaternion = q; bn.scaling = sc;
  };
  const between = (i: number, a: Vector3, c: Vector3) => {
    const d = c.subtract(a), l = Math.max(1e-4, d.length());
    seg(i, a, d.scaleInPlace(1 / l), l, true);
  };
  return {
    meshes: [mesh], pts,
    update(e, rdt) {
      const f = e.f;
      RIG.forEach((bn, i) => {                           // the rig arms' copies: rest -> the posed bone (skin = abs x bind^-1)
        const rp = b.rig.rest[bn];
        Matrix.TranslationToRef(-rp.x, -rp.y, -rp.z, mt0).multiplyToRef(b.bones[bn].getAbsoluteMatrix(), mt0);
        mt0.decompose(ds, dq, dp);
        bones[RIG0 + i].position = dp; bones[RIG0 + i].rotationQuaternion = dq; bones[RIG0 + i].scaling = ds;
      });
      at('handR', 0, -0.45 * hs, 0, pts[1]); at('handL', 0, -0.45 * hs, 0, pts[2]);
      if (!filled) { for (const h of hist) { h[0].copyFrom(pts[1]); h[1].copyFrom(pts[2]); } filled = true; }
      for (acc += rdt; acc >= 1 / 60; acc -= 1 / 60) {
        const h = hist.pop()!; h[0].copyFrom(pts[1]); h[1].copyFrom(pts[2]); hist.unshift(h);
      }
      acc = Math.min(acc, 1 / 60);
      const want = f.state === 'move' || f.state === 'hoho' || f.state === 'cine' ? 1 : 0;
      act += (want - act) * Math.min(1, 10 * rdt);
      ARMS.forEach(([s, spread, lag, up], i) => {
        const anc = at('chest', s * 0.08, up, 0.13), rest = at('chest', s * (up < 0 ? 0.5 : 0.46), up < 0 ? 0.1 : 0.34, 0.34);
        const h = hist[lag][s > 0 ? 0 : 1], ang = (s * spread * Math.PI) / 180, c = Math.cos(ang), sn = Math.sin(ang);
        const t = pts[3 + i].set(c * h.x - sn * h.z, h.y + (up < 0 ? -0.12 : 0.02), sn * h.x + c * h.z);
        t.set(rest.x + (t.x - rest.x) * act, rest.y + (t.y - rest.y) * act, rest.z + (t.z - rest.z) * act);
        const mid = anc.add(t).scaleInPlace(0.5), out = V(mid.x, 0, mid.z), ol = Math.max(1e-3, out.length());
        const el = mid.add(out.scaleInPlace(0.16 / ol)); el.y += 0.06;
        between(PER * i, anc, el);
        seg(PER * i + 1, el, UP, 1, false);
        between(PER * i + 2, el, t);
        seg(PER * i + 3, t, t.subtract(el).normalize(), 1, false);
      });
      // the red thread from the needle's eye, trailing where the hand has been (the Shikai only)
      const mt = (20 * Math.PI) / 180;
      at('weaponR', 0, Math.cos(mt) * 0.085, Math.sin(mt) * 0.085, pts[0]);
      let p0 = pts[0];
      for (let k = 0; k < THREAD; k++) {
        const h = hist[k + 1][0], p1 = V(h.x + 0.02 * (k + 1), h.y - 0.08 * (k + 1), h.z);
        if (f.form === 'base') between(TH0 + k, p0, p1); else { sc.set(0, 0, 0); bones[TH0 + k].scaling = sc; }
        p0 = p1;
      }
    },
    dispose() { mesh.dispose(); skel.dispose(); },
  };
}

// ---------------------------------------------------------------- the needle 刺絡 SHIGARAMI: 0.9 m, white-gold
function needle(scene: Scene): Mesh {
  // in the fist like the katana: the shaft leaves along the forearm's line tipped 20 deg forward; the eye end behind
  const mt = (20 * Math.PI) / 180, g = T(0, 0, 0, Math.PI + mt);
  const shaft = tube([[-0.1, 0.004, 0.004], [-0.09, 0.011, 0.011], [0, 0.012, 0.012], [0.55, 0.009, 0.009], [0.78, 0.004, 0.004],
    [0.8, 0.001, 0.001]], 6);
  const collar = tube([[-0.04, 0.016, 0.016], [-0.035, 0.019, 0.019], [-0.005, 0.019, 0.019], [0, 0.016, 0.016]], 8);
  const eye = box(0.026, 0.035, 0.008, T(0, -0.075, 0));
  for (const vd of [shaft, collar, eye]) vd.transform(g);
  return rigid(scene, 'weapon', [{ vd: shaft, c: L('needle') }, { vd: collar, c: L('gold') }, { vd: eye, c: L('goldL') }]);
}

// ---------------------------------------------------------------- faces: half-lidded calm, the closed smile, the glare
// (she never shouts, the kit's :calm: the shout cell is her small closed smile, the hurt cell a narrowed glare)
function drawFace(g: CanvasRenderingContext2D, e: number): void {
  const line = (w: number, ...p: number[]) => inkLine(g, w, ...p);
  for (const [x, s] of [[92, -1], [164, 1]]) {           // s = +1 her left (screen right)
    if (e === 1) {                                         // eyes shut in soft arcs
      line(5, x - 22, 128, x - 6, 120, x + 8, 120, x + 22, 127);
      line(3, x + 20 * s, 126, x + 28 * s, 132);
      continue;
    }
    const h = e === 2 ? 6 : 11, cy = 130, k = e === 2 ? 8 * s : 0;
    g.fillStyle = '#fff'; g.beginPath(); g.ellipse(x, cy, 22, h, 0, 0, 7); g.fill();
    g.save(); g.beginPath(); g.ellipse(x, cy, 22, h, 0, 0, 7); g.clip();
    g.fillStyle = '#3a3048'; g.beginPath(); g.arc(x + 2 * s, cy + 2, 11, 0, 7); g.fill();
    g.fillStyle = '#16121c'; g.beginPath(); g.arc(x + 2 * s, cy + 2, 5, 0, 7); g.fill();
    g.restore();
    g.fillStyle = '#1a1414';                               // the heavy upper lid (half-lidded: over the iris' top)
    g.beginPath(); g.moveTo(x - 26, cy - 2 + k); g.quadraticCurveTo(x, cy - 10 - h * 0.2, x + 26, cy - 2 - k);
    g.lineTo(x + 24, cy + 1 - k); g.quadraticCurveTo(x, cy - 4 - h * 0.2, x - 24, cy + 1 + k); g.fill();
    line(2, x - 16, cy + h + 2, x + 16, cy + h + 2);
    g.strokeStyle = '#a8434a'; line(2, x + 22 * s, cy - 2, x + 30 * s, cy - 6); g.strokeStyle = '#1a1414';   // a red eye-line
  }
  if (e === 0) line(3, 120, 198, 136, 198);
  if (e === 1) line(3, 116, 194, 128, 199, 140, 194);
  if (e === 2) line(4, 116, 200, 140, 198);
}

export const senju: CharBody = {
  // 1.7 m = the hurt height: 1.58 m of her + the 0.10 m okobo (the clogs are the rig's bottom 0.1 m, under the robe)
  spec: { height: 1.7, heads: 7.2, shoulder: 0.82, chest: [0.6, 0.4], waist: [0.46, 0.34], hip: [0.58, 0.42], limb: 0.85,
    hand: 1.15, skin: L('skin'), black: L('black'), haori: L('haori'), obi: L('lining'), hair: L('hair'), collar: 0.6,
    haoriHem: 0.9, haoriSleeves: 'long', tattered: false },
  parts,
  drawFace,
  weapon: (scene) => needle(scene),
  variant: () => null,
  extra: echoArms,
};
