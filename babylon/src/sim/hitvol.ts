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
 *  (tsph r). */
export function makeVol(spec: VolSpec): Vol {
  switch (spec[0]) {
    case 'arc': return [0, spec[1], deg(spec[2] / 2), spec[3], spec[4]];
    case 'cap': return [1, spec[1], spec[2], spec[3], spec[4]];
    case 'sph': return [2, spec[1], spec[2], spec[3], 0];
    case 'tsph': return [3, spec[1], 0, 0, 0];
  }
}

/** Does volume V of an attacker at (AX AY AZ) facing (FX 0 FZ) touch the hurt cylinder at (TX TY TZ), radius TR, height
 *  TH? EXTRA widens ARC radii. For TSPH, (AX AY AZ) is the target point. */
export function volHitP(v: Vol, ax: number, ay: number, az: number, fx: number, fz: number,
                        tx: number, ty: number, tz: number, tr: number, th: number, extra: number): boolean {
  const type = v[0];
  if (type < 0.5) {                                             // ARC
    const r = v[1] + extra, half = v[2], y0 = ay + v[3], y1 = ay + v[4];
    const dx = tx - ax, dz = tz - az, d = Math.sqrt(dx * dx + dz * dz);
    if (!(d <= r + tr && y0 <= ty + th && y1 >= ty)) return false;
    if (half >= 3.1 || d < tr + 0.05) return true;
    // the cylinder's edge is inside the slice: angle to its centre <= half + its angular radius
    const c = (dx * fx + dz * fz) / d, s = tr / d;
    return Math.acos(c > 1 ? 1 : c < -1 ? -1 : c) <= half + Math.asin(s > 1 ? 1 : s);
  } else if (type < 1.5) {                                      // CAP: closest point on the segment
    const a = v[1], b = v[2], h = ay + v[3], r = v[4];
    const dx = tx - ax, dz = tz - az, along = dx * fx + dz * fz;
    const s = along < a ? a : along > b ? b : along;
    const ex = tx - (ax + fx * s), ez = tz - (az + fz * s);
    return ex * ex + ez * ez <= (r + tr) * (r + tr) && h >= ty - r && h <= ty + th + r;
  } else {                                                      // SPH / TSPH: sphere vs cylinder
    const sph = type < 2.5;
    const f = sph ? v[1] : 0, u = sph ? v[2] : 1.1, r = sph ? v[3] : v[1];
    const cx = ax + fx * f, cy = ay + u, cz = az + fz * f;
    const dx = tx - cx, dz = tz - cz, lo = ty + tr, hi = ty + th - tr;
    const dy = cy < lo ? lo - cy : cy > hi ? cy - hi : 0;
    return dx * dx + dz * dz + dy * dy <= (r + tr) * (r + tr);
  }
}

/** Does the capsule from A to B with radius R touch the hurt cylinder at (TX TY TZ) (radius TR, height TH)? The cylinder
 *  is taken as the capsule of radius TR around its axis from TY+TR to TY+TH-TR (rounded rims, exact enough for hits). */
export function capsuleCylHitP(ax: number, ay: number, az: number, bx: number, by: number, bz: number, r: number,
                               tx: number, ty: number, tz: number, tr: number, th: number): boolean {
  const lo = ty + Math.min(tr, 0.5 * th), hi = Math.max(lo, ty + th - tr);
  const d1x = bx - ax, d1y = by - ay, d1z = bz - az, d2y = hi - lo;
  const rx = ax - tx, ry = ay - lo, rz = az - tz;
  const a = d1x * d1x + d1y * d1y + d1z * d1z, e = d2y * d2y;
  const f = d2y * ry, c = d1x * rx + d1y * ry + d1z * rz, b = d1y * d2y;
  let s = 0, u = 0;
  const unit = (x: number) => Math.max(0, Math.min(1, x));
  if (a <= 1e-8 && e <= 1e-8) { /* both points */ }
  else if (a <= 1e-8) u = unit(f / e);
  else if (e <= 1e-8) s = unit(-c / a);
  else {
    const den = a * e - b * b;
    s = den > 1e-8 ? unit((b * f - c * e) / den) : 0;
    u = (b * s + f) / e;
    if (u < 0) { u = 0; s = unit(-c / a); }
    else if (u > 1) { u = 1; s = unit((b - c) / a); }
  }
  const dx = rx + d1x * s, dy = ry + d1y * s - d2y * u, dz = rz + d1z * s, rr = r + tr;
  return dx * dx + dy * dy + dz * dz <= rr * rr;
}

/** Does the box centred at (CX CY CZ), turned by YAW, half-width HW (its right), half-height HH, half-length HL (its
 *  facing) touch the hurt cylinder at (TX TY TZ) (radius TR, height TH)? */
export function oboxCylHitP(cx: number, cy: number, cz: number, yaw: number, hw: number, hh: number, hl: number,
                            tx: number, ty: number, tz: number, tr: number, th: number): boolean {
  const fx = fwdX(yaw), fz = fwdZ(yaw);
  const dx = tx - cx, dz = tz - cz;
  const lx = dx * -fz + dz * fx;                     // along the box's right
  const lz = dx * fx + dz * fz;                      // along its facing
  const ex = lx - Math.max(-hw, Math.min(hw, lx)), ez = lz - Math.max(-hl, Math.min(hl, lz));
  return ex * ex + ez * ez <= tr * tr && cy - hh <= ty + th && cy + hh >= ty;
}

/** Do two vertical cylinders (feet, radius, height) overlap? */
export function cylCylHitP(ax: number, ay: number, az: number, ar: number, ah: number,
                           bx: number, by: number, bz: number, br: number, bh: number): boolean {
  const dx = bx - ax, dz = bz - az, rr = ar + br;
  return dx * dx + dz * dz <= rr * rr && ay <= by + bh && by <= ay + ah;
}
