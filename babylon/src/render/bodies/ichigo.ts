// Kurosaki Ichigo (TYBW, docs/DUEL_ICHIGO.md §2, v2 "the look"; docs/BABYLON_LOOK.md B3): 1.8 m and lean, the black
// shihakusho with no haori, short spiky orange hair with two lighter locks, the scowl; the dual Zangetsu: the long
// cleaver with a hole (right hand, the weapon mesh) and the hiltless stone-knife blade held reversed along the left
// forearm (a body part riding the weaponL bone). KESSA (form 'kessa'): barefoot, the hair and face black on his left,
// two flat white horns at the hairline, the robe open to the navel on a dark red disc with black lines, maroon coils at
// the neck / wrists / ankles (the chains themselves are B4's fx), one white Tensa slab with a jagged black line.
// Colours are lit / shadow pairs (the spec's form); the vertex colour is the lit one until cel.ts takes the pair.
import { Vector3, VertexData, type Material, type Scene } from '@babylonjs/core';
import type { Move } from '../../sim/kit';
import type { Ent } from '../../sim/types';
import {
  box, buildBody, ellipsoid, hex, inkLine, kimono, limb, rigid, T, tube, type Add, type BodySpec, type BuiltBody, type CharBody,
  type Part, type Rig,
} from '../body';
import { Animator } from '../anim';
import type { BoneName } from '../pose';

type Pair = readonly [number, number];
export const IC_PAL = {
  skin: [0xf2cfae, 0xc58e6c], black: [0x2b2d3a, 0x121319], white: [0xf3f1ea, 0xa9b2cf],
  hair: [0xe8792e, 0xa84a1e], hairLit: [0xf8b070, 0xc87a40], hairK: [0x1a1418, 0x0a080a],
  horn: [0xf4f1e8, 0xb8b4c4], disc: [0x6e1418, 0x3a0a0e], coil: [0x5a1418, 0x2e0a0c], blood: [0xd0101c, 0x800a12],
  blade: [0x2a2c36, 0x101116], edge: [0xe8ecf4, 0x9aa6c0], wrap: [0xece8dc, 0xa8a49a], wrapD: [0x2a2a30, 0x141418],
  tensa: [0xf4f4f0, 0xa9b0c4], tensaLine: [0x101014, 0x08080a], tensaEdge: [0xb8bcc4, 0x7a8090],
} as const satisfies Record<string, Pair>;
const L = (k: keyof typeof IC_PAL) => IC_PAL[k][0];
// ponytail: kimono() always adds a haori; he wears none, so it is built in this colour and dropped (no body.ts change)
const NO_HAORI = 0x010203;

const SPEC: BodySpec = { height: 1.8, heads: 8, shoulder: 1.05, chest: [0.72, 0.44], waist: [0.54, 0.38], hip: [0.6, 0.4],
  limb: 0.95, hand: 1.15, skin: L('skin'), black: L('black'), haori: NO_HAORI, obi: L('white'), hair: L('hair'), collar: 0.9,
  haoriHem: 1.6, haoriSleeves: 'long', tattered: false };

/** Half an ellipsoid (his right x >= 0 when RIGHT, else his left): the KESSA split hair cap and the black half-head. */
function halfEllipsoid(c: [number, number, number], r: [number, number, number], right: boolean, seg = 10, rows = 9): VertexData {
  const rings: [number, number, number, number, number][] = [];
  for (let j = 0; j <= rows; j++) {
    const t = Math.PI * (1 - j / rows), s = Math.max(1e-3, Math.sin(t));
    rings.push([c[1] + r[1] * Math.cos(t), r[0] * s, r[2] * s, c[0], c[2]]);
  }
  return tube(rings, seg, right ? { a0: 0, a1: Math.PI, double: true } : { a0: Math.PI, a1: 2 * Math.PI, double: true });
}

/** The spiky head: a cap and short chunky spikes (the bangs over the brow, a crown swept up and back, the sides out and
 *  down, the nape); two lighter locks on the crown. KESSA: everything on his left (x < 0) black. */
function hair(add: Add, hc: [number, number, number], H: number, kessa: boolean): void {
  const col = (x: number) => (kessa && x < -0.02 * H ? L('hairK') : L('hair'));
  const cap: [number, number, number] = [0, hc[1] + 0.12 * H, hc[2] + 0.1 * H], capR: [number, number, number] = [0.4 * H, 0.44 * H, 0.42 * H];
  if (kessa) { add(halfEllipsoid(cap, capR, true), L('hair'), ['head']); add(halfEllipsoid(cap, capR, false), L('hairK'), ['head']); }
  else add(ellipsoid(cap, capR, 16, 10), L('hair'), ['head']);
  const spike = (az: number, el: number, len: number, rad: number, c?: number) => {
    // az: 0 = straight back (+z), +pi/2 = his right; el up from the horizontal
    const d = new Vector3(Math.sin(az) * Math.cos(el), Math.sin(el), Math.cos(az) * Math.cos(el));
    const base = new Vector3(cap[0] + d.x * 0.3 * H, cap[1] + d.y * 0.32 * H, cap[2] + d.z * 0.3 * H);
    add(limb(base, base.add(d.scale(len * H)), rad * H, 0.012, 6), c ?? col(base.x), ['head']);
  };
  // the crown: big locks up and back; the sides out and down; the nape
  for (const [az, el, len, rad] of [[0, 1.0, 0.55, 0.17], [-0.9, 0.8, 0.5, 0.17], [0.9, 0.8, 0.52, 0.17], [-0.35, 0.45, 0.62, 0.18],
    [0.4, 0.5, 0.6, 0.18], [-1.5, 0.35, 0.5, 0.16], [1.5, 0.35, 0.5, 0.16], [-2.3, 0.15, 0.42, 0.15], [2.3, 0.15, 0.42, 0.15],
    [-0.5, -0.3, 0.42, 0.15], [0.5, -0.3, 0.42, 0.15]] as const) spike(az, el, len, rad);
  // the bangs: four locks over the brow from the hairline, the middle one falling between the eyes
  for (const [x, drop, tilt] of [[-0.27, 0.14, -0.12], [-0.1, 0.2, -0.04], [0.06, 0.26, 0.03], [0.24, 0.16, 0.12]] as const) {
    const b = new Vector3(x * H, hc[1] + 0.4 * H, hc[2] - 0.3 * H);
    add(limb(b, new Vector3((x + tilt) * H, hc[1] + (0.38 - drop) * H, hc[2] - 0.47 * H), 0.12 * H, 0.012, 6), col(b.x), ['head']);
  }
  // two lighter strokes over the crown (the base form; KESSA's left half is black)
  if (!kessa) for (const x of [0.08, 0.2]) add(limb(new Vector3(x * H, hc[1] + 0.45 * H, hc[2] - 0.36 * H),
    new Vector3((x + 0.06) * H, hc[1] + 0.56 * H, hc[2] + 0.02 * H), 0.045 * H, 0.012, 5), L('hairLit'), ['head']);
}

/** The short blade, reversed along the left forearm: hiltless, a stone knife's broad slab, ink black with a white edge,
 *  a dark wrap where the fist holds it; rides the weaponL bone (rigid). */
function shortBlade(add: Add, r: Rig): void {
  const o = r.rest.weaponL, x = o.x - 0.045, bones: BoneName[] = ['weaponL'];
  add(tube([[o.y - 0.05, 0.008, 0.035, x, o.z], [o.y + 0.08, 0.008, 0.035, x, o.z]], 4), L('wrapD'), bones);   // the wrap in the fist
  add(tube([[o.y + 0.08, 0.01, 0.04, x, o.z], [o.y + 0.3, 0.011, 0.055, x, o.z + 0.01], [o.y + 0.48, 0.01, 0.05, x, o.z + 0.012],
    [o.y + 0.56, 0.006, 0.02, x, o.z + 0.03]], 4), L('blade'), bones);                       // the slab, widening, the tip angled back
  add(tube([[o.y + 0.09, 0.012, 0.008, x, o.z - 0.042], [o.y + 0.3, 0.013, 0.008, x, o.z - 0.047], [o.y + 0.48, 0.012, 0.008, x, o.z - 0.04],
    [o.y + 0.555, 0.008, 0.006, x, o.z + 0.012]], 4), L('edge'), bones);                       // the white edge on the front
}

type WPart = { vd: VertexData; c: number };
const boxer = (p: WPart[]) => (w: number, h: number, d: number, y: number, z: number, c: number, rx = 0) =>
  p.push({ vd: box(w, h, d, T(0, y, z, rx)), c });
/** Hang a blade-up weapon from the fist as body.ts's katana does (flipped, tipped 20 deg forward along the forearm). */
function hang(scene: Scene, name: string, p: WPart[]) {
  const mt = 20 * Math.PI / 180, g0 = 0.04, m = T(0, -Math.cos(mt) * g0, -Math.sin(mt) * g0, Math.PI + mt);
  for (const q of p) q.vd.transform(m);
  return rigid(scene, name, p);
}

/** Zangetsu, the long blade: a cleaver ~1.45 m, ink black with a white edge, the hole between the hilt and the blade, a
 *  short white-wrapped hilt with a loose cloth end. Built blade-up with the edge at +z (the front once hung: it leads a
 *  rising or forward cut; a chop twists the hand). */
function cleaver(scene: Scene) {
  const p: WPart[] = [], b = boxer(p);
  b(0.03, 1.12, 0.24, 0.94, 0.06, L('blade'));            // the slab, y 0.38-1.5
  b(0.03, 0.12, 0.16, 1.53, 0.02, L('blade'), 0.5);      // the slanted tip
  b(0.03, 0.32, 0.05, 0.22, -0.035, L('blade'));            // beside the hole: the spine
  b(0.03, 0.32, 0.05, 0.22, 0.155, L('blade'));           // ... and the edge side
  b(0.03, 0.04, 0.24, 0.07, 0.06, L('blade'));            // the root under the hole
  b(0.034, 1.44, 0.018, 0.8, 0.183, L('edge'));           // the white edge
  b(0.045, 0.3, 0.045, -0.12, 0, L('wrap'));               // the hilt
  for (let i = 0; i < 4; i++) p.push({ vd: box(0.032, 0.032, 0.052, T(0, -0.02 - i * 0.07, 0, 0, 0, 0.785)), c: L('wrapD') });
  b(0.035, 0.18, 0.012, -0.34, -0.02, L('wrap'), 0.3);     // the loose cloth end
  return hang(scene, 'zangetsu', p);
}

/** KESSA's Tensa Zangetsu: a long straight white slab 1.52 x 0.17 x 0.025, no point and no guard, the end cut square with
 *  a notch on the edge side; a grey hairline on the edge, a jagged black line down the flat (both faces); a white hilt
 *  with a faint grey diamond wrap. */
function tensa(scene: Scene) {
  const p: WPart[] = [], b = boxer(p);
  b(0.025, 1.52, 0.17, 0.78, 0, L('tensa'));
  b(0.025, 0.03, 0.12, 1.555, -0.025, L('tensa'));
  b(0.025, 0.03, 0.03, 1.546, 0.05, L('tensa'), 0.785);
  b(0.027, 1.5, 0.008, 0.78, 0.086, L('tensaEdge'));
  ([[0.24, 0.22, 0.004, 0.12, 0.02], [0.45, 0.2, -0.012, -0.1, 0.032], [0.66, 0.24, 0.01, 0.14, 0.026], [0.88, 0.2, -0.008, -0.12, 0.035],
    [1.07, 0.18, 0.006, 0.1, 0.022]] as const).forEach(([y, l, z, rx, w]) => b(0.029, l, w, y, z, L('tensaLine'), rx));
  b(0.04, 0.22, 0.04, -0.11, 0, L('wrap'));
  for (let i = 0; i < 3; i++) b(0.042, 0.004, 0.052, -0.04 - i * 0.065, 0, 0x8a8c94, 0.785);
  return hang(scene, 'tensa', p);
}

/** KESSA's extras: the black left half of the head, the horns, the open robe's disc and lines, the waist tatters, the
 *  coils, bare feet. */
function kessaParts(add: Add, sp: BodySpec, r: Rig, hc: [number, number, number]): void {
  const { rest: R, H, bs } = r, y = (v: number) => v * bs, cz = sp.chest[1];
  add(halfEllipsoid([0, hc[1] - 0.02 * H, hc[2] + 0.01 * H], [0.365 * H, 0.47 * H, 0.41 * H], false, 8), L('hairK'), ['head']);
  add(halfEllipsoid([0, hc[1] - 0.3 * H, hc[2] - 0.24 * H], [0.245 * H, 0.175 * H, 0.205 * H], false, 8), L('hairK'), ['head']);   // the jaw
  for (const s of [1, -1]) {                               // two flat white horns from the hairline, out, up and back
    const a = new Vector3(s * 0.28 * H, hc[1] + 0.36 * H, hc[2] - 0.26 * H), m = new Vector3(s * 0.62 * H, hc[1] + 0.56 * H, hc[2] - 0.08 * H);
    add(limb(a, m, 0.1 * H, 0.085 * H, 6, 0.3), L('horn'), ['head']);
    add(limb(m, m.add(new Vector3(s * 0.3 * H, 0.1 * H, 0.42 * H)), 0.085 * H, 0.01, 6, 0.3), L('horn'), ['head']);
  }
  add(ellipsoid([0, y(6.05), -cz * H * 1.04], [0.17 * H, 0.17 * H, 0.025 * H], 12, 6), L('disc'), ['chest']);
  for (const x of [-0.07, 0, 0.07]) add(limb(new Vector3(x * H, y(5.85), -cz * H * 1.03), new Vector3(x * 0.6 * H, y(4.95), -sp.waist[1] * H * 1.08),
    0.012 * H, 0.006, 4), L('black'), ['chest', 'spine']);
  for (const [x, l] of [[0.35, 0.5], [0.45, 0.7], [-0.4, 0.55]] as const)
    add(box(0.1 * H, l * 0.35 * H, 0.01, T(x * H, y(4.55) - l * 0.17 * H, -sp.waist[1] * H * 1.1, 0, 0, x * 0.3)), L('white'), ['pelvis', 'spine']);
  const coil = (c: Vector3, rad: number, bones: BoneName[]) => {
    for (const dy of [-0.02, 0.02]) add(tube([[c.y + dy - 0.012, rad, rad, c.x, c.z], [c.y + dy + 0.012, rad, rad, c.x, c.z]], 12,
      { double: true, a0: 0.001, a1: 2 * Math.PI - 0.001 }), L('coil'), bones);
    add(ellipsoid([c.x, c.y, c.z - rad], [0.014, 0.014, 0.01], 5, 4), L('blood'), bones);
  };
  coil(new Vector3(0, R.neck.y + 0.02 * H, R.neck.z), 0.23 * H, ['neck', 'chest']);
  for (const S of ['R', 'L'] as const) {
    const w = R[`hand${S}`], f = R[`foot${S}`];
    coil(new Vector3(w.x, w.y + 0.12 * H, w.z), 0.13 * H, [`fore${S}`]);
    coil(new Vector3(f.x, f.y + 0.1 * bs, f.z + 0.02 * H), 0.19 * H, [`shin${S}`, `foot${S}`]);
    add(ellipsoid([f.x, 0.11 * bs, f.z - 0.32 * H], [0.15 * H, 0.1 * bs, 0.46 * H], 10, 6), L('skin'), [`foot${S}`]);   // bare
  }
}

function parts(sp: BodySpec, r: Rig, kessa: boolean): Part[] {
  let hcAt: [number, number, number] = [0, 0, 0];
  const ps = kimono({ ...sp, collar: kessa ? 1.85 : sp.collar }, r, (add, hc) => { hcAt = hc; hair(add, hc, r.H, kessa); });
  const noHaori = hex(NO_HAORI);
  // kimono's lapels are dropped (its roll turns about the floor, so they land on the shoulders): our own below; KESSA
  // drops the tabi / zori too (bare feet)
  const lapel = (p: Part) => p.bones.length === 2 && p.bones[0] === 'chest' && p.bones[1] === 'neck' && !p.color.equals(hex(sp.skin));
  const out = ps.filter((p) => !p.color.equals(noHaori) && !lapel(p) && !(kessa && p.bones.some((b) => b === 'footR' || b === 'footL')));
  const add: Add = (vd, color, bones) => out.push({ vd, color: typeof color === 'number' ? hex(color) : color, bones });
  const { H, bs } = r, cz = sp.chest[1];                 // the white lapels down the collar's V (KESSA: open to the navel)
  for (const s of [1, -1]) add(limb(new Vector3(s * 0.26 * H, 6.8 * bs, -cz * H * 0.75),
    kessa ? new Vector3(s * 0.04 * H, 4.9 * bs, -sp.waist[1] * H * 1.06) : new Vector3(s * 0.01 * H, 5.9 * bs, -cz * H * 1.04),
    0.05 * H, 0.04 * H, 6, 0.4), L('white'), ['chest', 'neck']);
  if (kessa) kessaParts(add, sp, r, hcAt);
  else shortBlade(add, r);
  return out;
}

// ---------------------------------------------------------------- faces: the scowl (neutral / shout / hurt)
function face(g: CanvasRenderingContext2D, e: number, kessa: boolean): void {
  const line = (w: number, ...p: number[]) => inkLine(g, w, ...p);
  if (kessa) {                                             // his left half (screen right) black from the brow to the jaw
    g.fillStyle = '#141016'; g.beginPath(); g.moveTo(128, 20); g.ellipse(128, 132, 112, 112, 0, -Math.PI / 2, Math.PI / 2); g.closePath(); g.fill();
  }
  for (const [x, s] of [[92, -1], [164, 1]] as const) {    // s = +1 his left (screen right), -1 his right
    const dark = kessa && s > 0, ink = dark ? '#e8e2d6' : '#1a1414';
    g.strokeStyle = ink;
    if (e === 2) { line(6, x - 24 * s, 120, x + 20 * s, 128); line(4, x - 22 * s, 132, x + 18 * s, 128); }
    else {
      const h = e === 1 ? 14 : 9;                          // the narrowed, glaring eye: a lid line over a half-hidden iris
      if (!dark) { g.fillStyle = '#fff'; g.beginPath(); g.moveTo(x - 30 * s, 127); g.quadraticCurveTo(x, 126 - 2 * h, x + 28 * s, 119); g.quadraticCurveTo(x, 126 + h, x - 30 * s, 127); g.fill(); }
      g.fillStyle = dark ? '#d0101c' : '#6a3e22'; g.beginPath(); g.arc(x - 2 * s, 125, e === 1 ? 8 : 11, 0, 7); g.fill();
      if (!dark) { g.fillStyle = '#1a1414'; g.beginPath(); g.arc(x - 2 * s, 125, 5, 0, 7); g.fill(); }
      line(6, x - 32 * s, 128, x, 112 - (e === 1 ? 6 : 0), x + 30 * s, 118);
    }
    // the brows: heavy wedges angled hard down to the nose
    const k = e === 1 ? 8 : 4;
    g.fillStyle = ink; g.beginPath(); g.moveTo(x + 34 * s, 92); g.lineTo(x - 26 * s, 104 + k); g.lineTo(x - 22 * s, 112 + k); g.lineTo(x + 32 * s, 102); g.fill();
  }
  g.strokeStyle = '#1a1414';
  line(3, 124, 98, 126, 112); line(3, 134, 98, 132, 112);   // the furrow between the brows
  const mouthInk = (x0: number) => (kessa && x0 > 128 ? '#e8e2d6' : '#1a1414');
  if (e === 0) { g.strokeStyle = mouthInk(100); line(5, 106, 200, 128, 198); g.strokeStyle = mouthInk(160); line(5, 128, 198, 150, 202); }
  if (e === 1) { g.fillStyle = '#3a1214'; g.beginPath(); g.ellipse(128, 198, 28, 18, 0, 0, 7); g.fill();
    g.fillStyle = '#f4f0e8'; g.fillRect(104, 184, 48, 6); g.fillRect(108, 208, 40, 4); }
  if (e === 2) { g.fillStyle = '#f4f0e8'; g.fillRect(106, 192, 44, 12); g.strokeStyle = '#1a1414'; line(3, 106, 198, 150, 198);
    line(4, 104, 192, 152, 192, 152, 204, 104, 204, 104, 192); }
  g.strokeStyle = '#1a1414';
}

export const ichigo: CharBody = {
  spec: SPEC,
  parts: (sp, r) => parts(sp, r, false),
  drawFace: (g, e) => face(g, e, false),
  weapon: (scene) => cleaver(scene),
  variant: (form) => (form === 'kessa'
    ? { parts: (sp, r) => parts(sp, r, true), drawFace: (g, e) => face(g, e, true), weapon: (scene) => tensa(scene) } : null),
};

// ---------------------------------------------------------------- B4's ghost copy (the clones, ZANZO's afterimages)
/** A copy of his body for drawing a clone / an afterimage: built in FORM with B4's own materials (the tint / mist), posed
 *  by a move at a frame (the clone's Icc.mv / sf; null: the stance). Place it with body.mesh.position / rotation.y. */
export class IchigoGhost {
  body: BuiltBody;
  private anim: Animator;
  private e = { f: { state: 'idle', move: null as Move | null, sf: 0, phase: 'main', stun: 0, form: 'kessa' },
    look: { clip: '' }, mo: { vel: [0, 0, 0] } };
  constructor(scene: Scene, mat: Material, weaponMat: Material, form = 'kessa', key = 'ichigo-ghost') {
    const v = ichigo.variant(form);
    this.body = buildBody(scene, key, v ? { ...ichigo, ...v, spec: ichigo.spec } : ichigo, mat, weaponMat);
    this.e.f.form = form;
    this.anim = new Animator(this.body, 'ichigo');
  }
  /** Pose it: MV at frame SF (sf < 0: its startup's first frame), or the stance; RDT the cross-fade's step. */
  pose(mv: Move | null, sf: number, rdt = 1 / 60): void {
    const f = this.e.f;
    f.state = mv ? 'move' : 'idle'; f.move = mv; f.sf = Math.max(0, sf);
    this.anim.update(this.e as unknown as Ent, rdt, 0);
    this.body.faceTex.uOffset = this.anim.face / 3;
  }
  dispose(): void {
    const b = this.body;
    b.weapon.dispose(); b.face.dispose(); b.faceTex.dispose(); b.faceMat.dispose(); b.mesh.dispose(); b.skeleton.dispose();
  }
}
