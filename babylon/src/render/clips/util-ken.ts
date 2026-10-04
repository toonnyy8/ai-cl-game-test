// util-ken.ts: posing by the sword (B2-ken; generic, any CharBody can use it). A key is a body pose (torso, legs, pos;
// pose.ts conventions) plus where the weapon is: the fist's point, the blade's direction and its edge, in character
// space (metres, x = his right, y = up, he faces -z) or in the chest's frame. Forward kinematics on the body's rest
// rig gives the shoulders; a two-bone IK solves the right arm and the hand's turn, and with TWO the left fist closes on
// the handle GAP metres behind the right one. The result is a plain PoseSpec (Euler degrees), so anim.ts samples it
// like any other key. Built once per clip at load time; nothing runs per frame.
import { Matrix, Quaternion, Vector3 } from '@babylonjs/core';
import { rig, type BodySpec, type Rig } from '../body';
import { BONES, merge, type BoneName, type Euler, type PoseSpec } from '../pose';

const PARENT: Partial<Record<BoneName, BoneName>> = {
  spine: 'pelvis', chest: 'spine', neck: 'chest', head: 'neck', shoulderR: 'chest', armR: 'shoulderR', foreR: 'armR',
  handR: 'foreR', weaponR: 'handR', shoulderL: 'chest', armL: 'shoulderL', foreL: 'armL', handL: 'foreL', weaponL: 'handL',
  thighR: 'pelvis', shinR: 'thighR', footR: 'shinR', thighL: 'pelvis', shinL: 'thighL', footL: 'shinL',
};
const D2R = Math.PI / 180;
export type V3 = [number, number, number];
const v = (a: V3) => new Vector3(a[0], a[1], a[2]);

/** The weapon's local frame in the weaponR bone: BLADE points from the fist to the tip, EDGE across to the cutting edge
 *  (both unit, perpendicular). katana() / the cleavers in bodies/ken.ts: the blade tipped G degrees forward. */
export function gripFrame(gDeg: number): { blade: Vector3; edge: Vector3 } {
  const g = gDeg * D2R;
  return { blade: new Vector3(0, -Math.cos(g), -Math.sin(g)), edge: new Vector3(0, Math.sin(g), -Math.cos(g)) };
}

export interface Grip {
  at: V3;                 // the right fist (the weaponR bone)
  dir: V3;                // the blade, fist -> tip
  edge?: V3;              // where the edge faces (made perpendicular to DIR); default: down / forward
  space?: 'root' | 'chest';
  two?: number;           // both hands: the left fist this far down the handle (metres)
  pole?: V3;              // the right elbow points this way (default out, down, back)
  poleL?: V3;
}

/** FK: world matrices of every bone for POSE on rig R (pos scaled for a figure of HEIGHT). */
export function fk(R: Rig, pose: PoseSpec, height: number): Record<BoneName, Matrix> {
  const W = {} as Record<BoneName, Matrix>, s = height / 1.8, p = pose.pos ?? [0, 0, 0];
  for (const b of BONES) {
    const e = pose[b] ?? [0, 0, 0], par = PARENT[b];
    const q = Quaternion.RotationYawPitchRoll(e[1] * D2R, e[0] * D2R, e[2] * D2R);
    const off = par ? R.rest[b].subtract(R.rest[par]) : R.rest[b].add(new Vector3(p[0] * s, p[1] * s, p[2] * s));
    const local = Matrix.Compose(Vector3.One(), q, off);
    W[b] = par ? local.multiply(W[par]) : local;
  }
  return W;
}
const origin = (m: Matrix) => Vector3.TransformCoordinates(Vector3.Zero(), m);
const rotOf = (m: Matrix) => { const r = m.getRotationMatrix(); return r; };
/** The rotation (row-vector) taking the orthonormal pair (a1, a2) onto (b1, b2). */
function basisMap(a1: Vector3, a2: Vector3, b1: Vector3, b2: Vector3): Matrix {
  const a3 = Vector3.Cross(a1, a2), b3 = Vector3.Cross(b1, b2);
  const A = Matrix.FromValues(a1.x, a1.y, a1.z, 0, a2.x, a2.y, a2.z, 0, a3.x, a3.y, a3.z, 0, 0, 0, 0, 1);
  const B = Matrix.FromValues(b1.x, b1.y, b1.z, 0, b2.x, b2.y, b2.z, 0, b3.x, b3.y, b3.z, 0, 0, 0, 0, 1);
  return A.transpose().multiply(B);
}
const ortho = (x: Vector3, n: Vector3) => x.subtract(n.scale(Vector3.Dot(x, n))).normalize();
/** A rotation matrix as pose Euler degrees ([x, y, z] = pitch, yaw, roll, as anim.ts reads them). */
export function toEuler(m: Matrix): Euler {
  const e = Quaternion.FromRotationMatrix(m).toEulerAngles();
  const r = (a: number) => Math.round((a / D2R) * 10) / 10;
  return [r(e.x), r(e.y), r(e.z)];
}

/** Two-bone IK for one arm (S = 'R' | 'L'): its fist to FIST with the hand's world rotation HAND; writes the arm, fore
 *  and hand angles into OUT. */
function arm(R: Rig, out: PoseSpec, height: number, S: 'R' | 'L', fist: Vector3, hand: Matrix, pole: Vector3): void {
  const W = fk(R, out, height);
  const sh = origin(W[`arm${S}`]), parentRot = rotOf(W[`shoulder${S}`]);
  const ra = R.rest[`arm${S}`], re = R.rest[`fore${S}`], rw = R.rest[`hand${S}`], rf = R.rest[`weapon${S}`];
  const a = Vector3.Distance(ra, re), b = Vector3.Distance(re, rw);
  const wrist = fist.subtract(Vector3.TransformNormal(rf.subtract(rw), hand));
  let d = Vector3.Distance(sh, wrist);
  const dir = wrist.subtract(sh).normalize();
  d = Math.min(Math.max(d, Math.abs(a - b) + 1e-3), a + b - 1e-3);
  const x = (a * a - b * b + d * d) / (2 * d), h = Math.sqrt(Math.max(0, a * a - x * x));
  const pv = ortho(pole.clone(), dir);
  const elbow = sh.add(dir.scale(x)).add(pv.scale(h)), wr = sh.add(dir.scale(d));
  const up = elbow.subtract(sh).normalize(), fo = wr.subtract(elbow).normalize();
  let hinge = Vector3.Cross(up, fo);
  if (hinge.length() < 1e-4) hinge = Vector3.Cross(up, pv.scale(-1));
  hinge.normalize();
  const restUp = re.subtract(ra).normalize(), restFo = rw.subtract(re).normalize();
  const restHinge = ortho(new Vector3(1, 0, 0), restUp), restHingeF = ortho(new Vector3(1, 0, 0), restFo);
  const upW = basisMap(restUp, restHinge, up, hinge);
  const foW = basisMap(restFo, restHingeF, fo, hinge);
  // local = world * inverse(parent world)  (row vectors: world = local * parent)
  out[`arm${S}`] = toEuler(upW.multiply(Matrix.Invert(parentRot)));
  out[`fore${S}`] = toEuler(foW.multiply(Matrix.Invert(upW)));
  out[`hand${S}`] = toEuler(hand.multiply(Matrix.Invert(foW)));
}

/** POSE with the weapon placed by G (see Grip); GF: the weapon's local frame (gripFrame). */
export function grip(sp: BodySpec, gf: { blade: Vector3; edge: Vector3 }, pose: PoseSpec, g: Grip): PoseSpec {
  const R = rig(sp), out: PoseSpec = merge(pose);
  const W = fk(R, out, sp.height);
  const toRoot = (p: V3, dirn: boolean) => g.space === 'chest'
    ? (dirn ? Vector3.TransformNormal(v(p), W.chest) : Vector3.TransformCoordinates(v(p), W.chest)) : v(p);
  const fist = toRoot(g.at, false), dir = toRoot(g.dir, true).normalize();
  const edge = ortho(g.edge ? toRoot(g.edge, true) : Math.abs(dir.y) > 0.8 ? new Vector3(0, 0, -1) : new Vector3(0, -1, 0), dir);
  const hand = basisMap(gf.blade, gf.edge, dir, edge);
  arm(R, out, sp.height, 'R', fist, hand, v(g.pole ?? [1, -0.6, 0.6]).normalize());
  if (g.two !== undefined) {
    // the left fist further down the handle, its knuckles the other way round the same grip
    const fistL = fist.subtract(dir.scale(g.two));
    arm(R, out, sp.height, 'L', fistL, hand, v(g.poleL ?? [-1, -0.6, 0.6]).normalize());
  }
  return out;
}

/** Where the weapon is in POSE (character space): the fist and the blade direction (tests, debugging). */
export function weaponAt(sp: BodySpec, gf: { blade: Vector3 }, pose: PoseSpec, side: 'R' | 'L' = 'R'): { fist: Vector3; dir: Vector3 } {
  const W = fk(rig(sp), pose, sp.height)[`weapon${side}`];
  return { fist: origin(W), dir: Vector3.TransformNormal(gf.blade, W).normalize() };
}
