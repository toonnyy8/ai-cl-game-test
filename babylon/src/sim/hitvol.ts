// hitvol.ts <- engine/lisp/hitvol.lisp: hit-volume geometry for melee and hazards. Pure functions of numbers.
// Hurt volumes are vertical cylinders (radius TR, height TH) standing on the target's feet (TX TY TZ). Attack volumes:
//   * attacker-relative (melee swings): a 5-number array [type p1 p2 p3 p4] in the attacker's frame (makeVol):
//       0 ARC   r half-angle(rad) y0 y1   a pie slice around him, from height y0 to y1
//       1 CAP   a b h r                   a capsule along his facing from a to b metres, height h
//       2 SPH   fwd up r                  a sphere fwd metres ahead, up metres high
//       3 TSPH  r                         a sphere at the attacker's target point (chest height)
//   * world-space (projectiles, walls, pillars): capsuleCylHitP, oboxCylHitP, cylCylHitP.
import { deg, fwdX, fwdZ } from './math';

export type Vol = number[];
export type VolSpec = ['arc', number, number, number, number] | ['cap', number, number, number, number]
  | ['sph', number, number, number] | ['tsph', number];

/** Volume KIND from ARGS: (arc r deg y0 y1) (the ARC takes its full angle in degrees), (cap a b h r), (sph fwd up r),
 *  (tsph r). Its numbers are single floats, as the Lisp's f32 array. */
export function makeVol(spec: VolSpec): Vol {
  switch (spec[0]) {
    case 'arc': return [0, f(spec[1]), deg(spec[2] / 2), f(spec[3]), f(spec[4])];
    case 'cap': return [1, f(spec[1]), f(spec[2]), f(spec[3]), f(spec[4])];
    case 'sph': return [2, f(spec[1]), f(spec[2]), f(spec[3]), 0];
    case 'tsph': return [3, f(spec[1]), 0, 0, 0];
  }
}

// Every test below is the Lisp's single-float arithmetic op by op (hitvol.lisp declares all of it SINGLE-FLOAT): the
// arguments are rounded to f32 on entry, every + - * / sqrt rounds (a double op on two f32s, then fround, is the f32 op).
// ponytail: acos / asin are the double ones rounded (musl's acosf / asinf may differ in the last bit); port them like
// sinf.ts if a parity check ever trips on an ARC's edge.
const f = Math.fround;
const EPS = f(1e-8);

/** Does volume V of an attacker at (AX AY AZ) facing (FX 0 FZ) touch the hurt cylinder at (TX TY TZ), radius TR, height
 *  TH? EXTRA widens ARC radii. For TSPH, (AX AY AZ) is the target point. */
export function volHitP(v: Vol, ax: number, ay: number, az: number, fx: number, fz: number,
                        tx: number, ty: number, tz: number, tr: number, th: number, extra: number): boolean {
  ax = f(ax); ay = f(ay); az = f(az); fx = f(fx); fz = f(fz); tx = f(tx); ty = f(ty); tz = f(tz); tr = f(tr); th = f(th);
  const type = v[0];
  if (type < 0.5) {                                             // ARC
    const r = f(v[1] + f(extra)), half = v[2], y0 = f(ay + v[3]), y1 = f(ay + v[4]);
    const dx = f(tx - ax), dz = f(tz - az), d = f(Math.sqrt(f(f(dx * dx) + f(dz * dz))));
    if (!(d <= f(r + tr) && y0 <= f(ty + th) && y1 >= ty)) return false;
    if (half >= f(3.1) || d < f(tr + f(0.05))) return true;
    // the cylinder's edge is inside the slice: angle to its centre <= half + its angular radius
    const c = f(f(f(dx * fx) + f(dz * fz)) / d), s = f(tr / d);
    return f(Math.acos(c > 1 ? 1 : c < -1 ? -1 : c)) <= f(half + f(Math.asin(s > 1 ? 1 : s)));
  } else if (type < 1.5) {                                      // CAP: closest point on the segment
    const a = v[1], b = v[2], h = f(ay + v[3]), r = v[4];
    const dx = f(tx - ax), dz = f(tz - az), along = f(f(dx * fx) + f(dz * fz));
    const s = along < a ? a : along > b ? b : along;
    const ex = f(tx - f(ax + f(fx * s))), ez = f(tz - f(az + f(fz * s))), rt = f(r + tr);
    return f(f(ex * ex) + f(ez * ez)) <= f(rt * rt) && h >= f(ty - r) && h <= f(f(ty + th) + r);
  } else {                                                      // SPH / TSPH: sphere vs cylinder
    const sph = type < 2.5;
    const fw = sph ? v[1] : 0, u = sph ? v[2] : f(1.1), r = sph ? v[3] : v[1];
    const cx = f(ax + f(fx * fw)), cy = f(ay + u), cz = f(az + f(fz * fw));
    const dx = f(tx - cx), dz = f(tz - cz), lo = f(ty + tr), hi = f(f(ty + th) - tr);
    const dy = cy < lo ? f(lo - cy) : cy > hi ? f(cy - hi) : 0, rt = f(r + tr);
    return f(f(f(dx * dx) + f(dz * dz)) + f(dy * dy)) <= f(rt * rt);
  }
}

/** Does the capsule from A to B with radius R touch the hurt cylinder at (TX TY TZ) (radius TR, height TH)? The cylinder
 *  is taken as the capsule of radius TR around its axis from TY+TR to TY+TH-TR (rounded rims, exact enough for hits). */
export function capsuleCylHitP(ax: number, ay: number, az: number, bx: number, by: number, bz: number, r: number,
                               tx: number, ty: number, tz: number, tr: number, th: number): boolean {
  ax = f(ax); ay = f(ay); az = f(az); bx = f(bx); by = f(by); bz = f(bz); r = f(r); tx = f(tx); ty = f(ty); tz = f(tz);
  tr = f(tr); th = f(th);
  const lo = f(ty + Math.min(tr, f(0.5 * th))), hi = Math.max(lo, f(f(ty + th) - tr));
  const d1x = f(bx - ax), d1y = f(by - ay), d1z = f(bz - az), d2y = f(hi - lo);
  const rx = f(ax - tx), ry = f(ay - lo), rz = f(az - tz);
  const a = f(f(f(d1x * d1x) + f(d1y * d1y)) + f(d1z * d1z)), e = f(d2y * d2y);
  const fq = f(d2y * ry), c = f(f(f(d1x * rx) + f(d1y * ry)) + f(d1z * rz)), b = f(d1y * d2y);
  let s = 0, u = 0;
  const unit = (x: number) => Math.max(0, Math.min(1, x));
  if (a <= EPS && e <= EPS) { /* both points */ }
  else if (a <= EPS) u = unit(f(fq / e));
  else if (e <= EPS) s = unit(f(-c / a));
  else {
    const den = f(f(a * e) - f(b * b));
    s = den > EPS ? unit(f(f(f(b * fq) - f(c * e)) / den)) : 0;
    u = f(f(f(b * s) + fq) / e);
    if (u < 0) { u = 0; s = unit(f(-c / a)); }
    else if (u > 1) { u = 1; s = unit(f(f(b - c) / a)); }
  }
  const dx = f(rx + f(d1x * s)), dy = f(f(ry + f(d1y * s)) - f(d2y * u)), dz = f(rz + f(d1z * s)), rr = f(r + tr);
  return f(f(f(dx * dx) + f(dy * dy)) + f(dz * dz)) <= f(rr * rr);
}

/** Does the box centred at (CX CY CZ), turned by YAW, half-width HW (its right), half-height HH, half-length HL (its
 *  facing) touch the hurt cylinder at (TX TY TZ) (radius TR, height TH)? */
export function oboxCylHitP(cx: number, cy: number, cz: number, yaw: number, hw: number, hh: number, hl: number,
                            tx: number, ty: number, tz: number, tr: number, th: number): boolean {
  cx = f(cx); cy = f(cy); cz = f(cz); hw = f(hw); hh = f(hh); hl = f(hl); tx = f(tx); ty = f(ty); tz = f(tz); tr = f(tr); th = f(th);
  const fx = fwdX(f(yaw)), fz = fwdZ(f(yaw));
  const dx = f(tx - cx), dz = f(tz - cz);
  const lx = f(f(dx * -fz) + f(dz * fx));            // along the box's right
  const lz = f(f(dx * fx) + f(dz * fz));             // along its facing
  const ex = f(lx - Math.max(-hw, Math.min(hw, lx))), ez = f(lz - Math.max(-hl, Math.min(hl, lz)));
  return f(f(ex * ex) + f(ez * ez)) <= f(tr * tr) && f(cy - hh) <= f(ty + th) && f(cy + hh) >= ty;
}

/** Do two vertical cylinders (feet, radius, height) overlap? */
export function cylCylHitP(ax: number, ay: number, az: number, ar: number, ah: number,
                           bx: number, by: number, bz: number, br: number, bh: number): boolean {
  ax = f(ax); ay = f(ay); az = f(az); ar = f(ar); ah = f(ah); bx = f(bx); by = f(by); bz = f(bz); br = f(br); bh = f(bh);
  const dx = f(bx - ax), dz = f(bz - az), rr = f(ar + br);
  return f(f(dx * dx) + f(dz * dz)) <= f(rr * rr) && ay <= f(by + bh) && by <= f(ay + ah);
}
