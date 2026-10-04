// portrait.ts <- duel/lisp/camera.lisp %PORTRAIT-CAMERA (DUEL_MOBILE_DESIGN §14): any battle in a portrait window. Behind
// P1 (9 x 0.6 = 5.4 m back, + 0.2 m per metre of separation past 4 m; 2 m up; 0.5 m over the shoulder; the close-range
// swing 15 deg), the orbit leading the sim's W.behindYaw by at most 20 deg toward P2 (render-side only, smoothed 8/s);
// the aim bisects the pair (azimuth: their centres, within 20 deg of the orbit; pitch: P1's near feet .. 0.3 m over P2's
// head). The lens: the camera BAND (between the HUD blocks, onehand.ts portraitMetrics) spans 30 deg vertically, widened
// when the pair needs it (full-screen FOV 40..100 deg, smoothed), and a lens shift puts the aim on the band's middle.
import { Matrix, Vector3, type AbstractEngine, type FreeCamera } from '@babylonjs/core';
import { angleWrap, fwdX, fwdZ } from '../sim/math';
import { dirYaw } from '../sim/rules';
import type { World } from '../sim/types';

const D2R = Math.PI / 180, BAND_FOV = 30 * D2R, FOV_MIN = 40 * D2R, FOV_MAX = 100 * D2R;

export class PortraitCamera {
  eye = new Vector3(); at = new Vector3();
  lead = 0; fov = 45 * D2R; anchor = [0, 0];
  cut = true;

  /** Place the camera for W; BAND [top, bottom] fractions of the height. Returns the full-screen vertical FOV and the
   *  lens shift (NDC, + = the aim above the screen's middle). */
  update(w: World, rdt: number, band: [number, number]): { fov: number; shift: number } {
    const a = w.p1, b = w.p2, p = a.pos, q = b.pos, c = this.anchor;
    const sep = Math.hypot(q[0] - p[0], q[2] - p[2]);
    if (this.cut) { c[0] = p[0]; c[1] = p[2]; }
    else { const k = 1 - Math.exp(-8 * rdt); c[0] += k * (p[0] - c[0]); c[1] += k * (p[2] - c[1]); }
    const want = Math.max(-20 * D2R, Math.min(20 * D2R, angleWrap(dirYaw(q[0] - c[0], q[2] - c[1]) - w.behindYaw)));
    this.lead = this.cut ? want : this.lead + (1 - Math.exp(-8 * rdt)) * (want - this.lead);
    const yaw = w.behindYaw + this.lead, fx = fwdX(yaw), fz = fwdZ(yaw);
    let back = 5.4 + 0.2 * Math.max(0, sep - 4);
    const off = 15 * D2R * Math.max(0, Math.min(1, (6 - sep) / 4)), side = 0.5 + back * Math.sin(off);
    back *= Math.cos(off);
    let ex = c[0] - back * fx - side * fz, ez = c[1] - back * fz + side * fx;
    const r = Math.hypot(ex, ez), k = Math.min(1, 18 / Math.max(0.01, r));          // inside the 18 m ring
    ex *= k; ez *= k;
    const ey = 2 + 0.4 * (r - k * r);
    // the aim: azimuth the pair's centre (within 20 deg of the orbit), pitch bisecting P1's near feet and P2's head
    const mx = 0.5 * (p[0] + q[0]), mz = 0.5 * (p[2] + q[2]);
    const az = yaw + Math.max(-20 * D2R, Math.min(20 * D2R, angleWrap(dirYaw(mx - ex, mz - ez) - yaw)));
    const d1 = Math.max(0.5, Math.hypot(p[0] - ex, p[2] - ez) - a.body.hurtR), d2 = Math.max(0.5, Math.hypot(q[0] - ex, q[2] - ez));
    const lo = Math.atan2(-ey, d1), hi = Math.atan2(b.body.hurtH + 0.3 - ey, d2), pitch = 0.5 * (lo + hi);
    this.eye.set(ex, ey, ez);
    this.at.set(ex + 10 * Math.cos(pitch) * fwdX(az), ey + 10 * Math.sin(pitch), ez + 10 * Math.cos(pitch) * fwdZ(az));
    // the lens: the band spans max(30 deg, the pair's spread + a margin)
    const bf = Math.max(0.2, band[1] - band[0]), bandFov = Math.max(BAND_FOV, (hi - lo) * 1.15);
    const fov = Math.max(FOV_MIN, Math.min(FOV_MAX, 2 * Math.atan(Math.tan(bandFov / 2) / bf)));
    this.fov = this.cut ? fov : this.fov + (1 - Math.exp(-6 * rdt)) * (fov - this.fov);
    this.cut = false;
    return { fov: this.fov, shift: 1 - (band[0] + band[1]) };
  }
}

/** Put a vertical FOV and a lens SHIFT (NDC y) on CAM (a frozen projection; clearLens gives it back). */
export function applyLens(cam: FreeCamera, engine: AbstractEngine, fov: number, shift: number): void {
  const rh = cam.getScene().useRightHandedSystem, aspect = engine.getAspectRatio(cam);
  const m = (rh ? Matrix.PerspectiveFovRH : Matrix.PerspectiveFovLH)(fov, aspect, cam.minZ, cam.maxZ || 1e4,
    engine.isNDCHalfZRange, 0, engine.useReverseDepthBuffer);
  const v = m.asArray().slice();
  v[9] = rh ? -shift : shift;                       // y_ndc += shift (RH: w = -z)
  if (baseFov === null) baseFov = cam.fov;
  cam.fov = fov;
  cam.freezeProjectionMatrix(Matrix.FromArray(v));
}
let baseFov: number | null = null;
/** Back to the scene's own lens (landscape, menus). */
export function clearLens(cam: FreeCamera): void {
  if (baseFov === null) return;
  cam.unfreezeProjectionMatrix();
  cam.fov = baseFov; baseFov = null;
}
