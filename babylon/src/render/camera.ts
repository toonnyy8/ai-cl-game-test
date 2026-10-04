// camera.ts <- duel/lisp/camera.lisp (landscape): the PAIR camera (3/4 side view of both fighters, on the side of the
// P1 -> P2 axis the sim's view (W.viewX / viewZ) holds, orbit angle / distance / midpoint smoothed separately) and the
// BEHIND camera (VS CPU: over P1's right shoulder along the sim's W.behindYaw, the anchor following P1 on a spring).
// The sim owns the direction the human stick steers by; this only places the render camera. Real time, per frame.
// ponytail: no portrait camera, no cinematic shots (cinematics are length-only: the pair camera frames them).
import { Vector3 } from '@babylonjs/core';
import { angleWrap, fwdX, fwdZ } from '../sim/math';
import type { Ent, World } from '../sim/types';

const ORBIT_RATE = 10, DIST_RATE = 5, MAX_R = 18, CLOSE = 0.6;
const BEHIND_BACK = 5.5, BEHIND_UP = 2, BEHIND_SHOULDER = 0.9, BEHIND_WIDEN = 0.2, BEHIND_LOOK = 0.6, BEHIND_CLOSE = 40,
  BEHIND_RATE = 8;
const D2R = Math.PI / 180;

export class DuelCamera {
  eye = new Vector3(0, 3, 12);
  at = new Vector3(0, 1, 0);
  ang = 0; dist = 7;
  /** Snap on the next frame (a new battle, the end of a cinematic). */
  cut = true;
  /** Real seconds of the perfect-Hoho punch-in left. */
  punchT = 0;
  anchor = [0, 0];

  update(w: World, rdt: number): void {
    this.punchT = Math.max(0, this.punchT - rdt);
    if (w.viewBehind && !w.cine) this.behind(w.p1, w.p2, w.behindYaw, rdt);
    else this.pair(w, rdt);
  }

  behind(a: Ent, b: Ent, yaw: number, rdt: number): void {
    const p = a.pos, q = b.pos, c = this.anchor;
    const sep = Math.hypot(q[0] - p[0], q[2] - p[2]);
    const wide = BEHIND_WIDEN * Math.max(0, sep - 4);
    let back = CLOSE * (BEHIND_BACK + wide) * (this.punchT > 0 ? 0.6 : 1);
    const off = D2R * BEHIND_CLOSE * Math.max(0, Math.min(1, (6 - sep) / 4));
    const side = BEHIND_SHOULDER + back * Math.sin(off);
    const fx = fwdX(yaw), fz = fwdZ(yaw);
    back *= Math.cos(off);
    if (this.cut) { c[0] = p[0]; c[1] = p[2]; this.cut = false; }
    else { const k = 1 - Math.exp(-BEHIND_RATE * rdt); c[0] += k * (p[0] - c[0]); c[1] += k * (p[2] - c[1]); }
    let ex = c[0] - back * fx - side * fz, ez = c[1] - back * fz + side * fx;    // right = (-fz, fx)
    const r = Math.hypot(ex, ez), k = Math.min(1, MAX_R / Math.max(0.01, r));
    const h = BEHIND_UP + 0.33 * wide + 0.4 * (r - k * r);                         // pulled in by the wall: rise instead
    ex *= k; ez *= k;
    for (const e of [a, b]) {                                                       // never inside a fighter
      const o = e.pos, dx = ex - o[0], dz = ez - o[2], d = Math.hypot(dx, dz), min = 0.5 + e.body.hurtR;
      if (d < min && d > 0.001) { ex = o[0] + dx * (min / d); ez = o[2] + dz * (min / d); }
    }
    this.eye.set(ex, h, ez);
    this.at.set(c[0] + BEHIND_LOOK * sep * fx, 1.1, c[1] + BEHIND_LOOK * sep * fz);
  }
  pair(w: World, rdt: number): void {
    const p = w.p1.pos, q = w.p2.pos;
    const mx = 0.5 * (p[0] + q[0]), mz = 0.5 * (p[2] + q[2]);
    const dx = q[0] - p[0], dz = q[2] - p[2], sep = Math.hypot(dx, dz);
    const ux = sep > 0.01 ? dx / sep : 1, uz = sep > 0.01 ? dz / sep : 0;
    const ang = Math.atan2(w.viewZ, w.viewX);
    const dist = CLOSE * Math.max(6, 4.5 + 0.85 * sep) * (this.punchT > 0 ? 0.6 : 1);
    const h = 2.5 + 0.15 * sep, c = this.at;
    if (this.cut) { this.ang = ang; this.dist = dist; this.cut = false; c.x = mx; c.z = mz; }
    else {
      const k = 1 - Math.exp(-ORBIT_RATE * rdt), kd = 1 - Math.exp(-DIST_RATE * rdt);
      this.ang += k * angleWrap(ang - this.ang);
      this.dist += kd * (dist - this.dist);
      c.x += k * (mx - c.x); c.z += k * (mz - c.z);
    }
    const back = 0.05 * this.dist;                                                  // 3/4: a little behind P1
    const ex = c.x + this.dist * Math.cos(this.ang) - back * ux, ez = c.z + this.dist * Math.sin(this.ang) - back * uz;
    const k = Math.min(1, MAX_R / Math.max(0.01, Math.hypot(ex, ez)));
    this.eye.set(k * ex, h, k * ez);
    c.y = 1.05;
  }
}
