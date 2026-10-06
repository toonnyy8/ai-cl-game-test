// Zaraki Kenpachi, TYBW (docs/babylon/BABYLON_LOOK.md; the user, 2026-10-04): 2.0 m, ~8 heads, broad; long straight black hair
// worn down past the shoulders with heavy forelocks (no bells, no spikes, no eyepatch in any form); the open collar and
// the chest scar; the haori's sleeves torn off, the kosode's torn short, bare arms; the scar down the left side of his
// face; a grin as the neutral face. Weapons: the chipped long katana (base), NOZARASHI, the 2 m cleaver (the three NOME
// cups), the broken cleaver (Bankai, KATAUDE). Forms (src/chars/ken.ts kits): base; nozarashi / ryote / nomihose (the
// cleaver; the cups' auras are VFX); bankai (DUEL_KEN_BANKAI §12: crimson skin, two horns at the hairline parting the
// forelocks, white irisless eyes, the broken cleaver); kataude (the oni with the left arm gone, the right forearm torn).
import { Vector3, VertexData, type Scene } from '@babylonjs/core';
import { adder, box, ellipsoid, inkLine, katana, kimono, limb, pair, rigid, T, tube, type Add, type BodySpec, type CharBody, type Part, type Rig } from '../body';
import type { BoneName } from '../pose';

/** Lit / shadow pairs (BABYLON_LOOK B2 palette); L registers the pair (body.ts pair) so every part gets its shadow half. */
export const KC = {
  skin: [0xe4b48c, 0xb2724f], oni: [0x9e3a32, 0x5e1e1c], hair: [0x2a2b38, 0x0e0f15], hairHi: [0xd8dce4, 0x8c93a6],
  black: [0x2b2d3a, 0x121319], haori: [0xf6f3ed, 0xc3c9dd], obi: [0xe9e4d6, 0x9a9db5], scar: [0xa65a48, 0x6e3428],
  blade: [0xf4f6fa, 0x9aa6c0], steel: [0x9aa4b4, 0x5c6478], spine: [0x3a3f4c, 0x1e2129], cloth: [0xe6e0cf, 0x9c968a],
  wrap: [0x4a4440, 0x26221f], brass: [0xb8a274, 0x786846], tassel: [0x3f6e52, 0x22402e], broken: [0x1c1c22, 0x0c0c10],
  blood: [0xc8242a, 0x7a1014],
} as const;
const L = (c: readonly [number, number]) => pair(c[0], c[1]);

/** The grip angle of all his weapons (the blade tipped this far forward of the forearm's line, as katana()). */
export const KEN_GRIP = 20;

// ---------------------------------------------------------------- geometry: a hair lock swept along a curve
/** A tapered lock along the quadratic curve A -> (control C) -> B: elliptical sections W wide (along SIDE, kept
 *  perpendicular to the curve) and TH thick, narrowing to a point at B. */
function lock(a: Vector3, c: Vector3, b: Vector3, w: number, th: number, side: Vector3, n = 7, seg = 6): VertexData {
  const pos: number[] = [], idx: number[] = [], P: Vector3[] = [];
  for (let i = 0; i <= n; i++) {
    const t = i / n;
    P.push(a.scale((1 - t) * (1 - t)).add(c.scale(2 * t * (1 - t))).add(b.scale(t * t)));
  }
  for (let i = 0; i <= n; i++) {
    const t = i / n, tg = P[Math.min(n, i + 1)].subtract(P[Math.max(0, i - 1)]).normalize();
    const u = side.subtract(tg.scale(Vector3.Dot(side, tg))).normalize(), v = Vector3.Cross(tg, u);
    const ww = w * (i === 0 ? 0.8 : Math.pow(1 - t, 0.7) + 0.02), tt = th * (1 - 0.6 * t) + 0.002;
    for (let k = 0; k <= seg; k++) {
      const an = (2 * Math.PI * k) / seg, p = P[i].add(u.scale(ww * Math.cos(an))).add(v.scale(tt * Math.sin(an)));
      pos.push(p.x, p.y, p.z);
    }
  }
  const m = seg + 1;
  for (let i = 0; i < n; i++) for (let k = 0; k < seg; k++) {
    const q = i * m + k;
    idx.push(q, q + 1, q + m, q + 1, q + m + 1, q + m);
  }
  const base = pos.length / 3;                       // cap the root
  pos.push(P[0].x, P[0].y, P[0].z);
  for (let k = 0; k < seg; k++) idx.push(base, k + 1, k);
  return finish(pos, idx, P);
}
/** Normals, flipped outward if the winding came out inside-out (tested against the nearest AXIS point). */
function finish(pos: number[], idx: number[], axis: Vector3[]): VertexData {
  const nrm: number[] = [];
  VertexData.ComputeNormals(pos, idx, nrm);
  let dot = 0;
  for (let i = 0; i < pos.length; i += 3) {
    const p = new Vector3(pos[i], pos[i + 1], pos[i + 2]);
    let best = axis[0];
    for (const q of axis) if (Vector3.DistanceSquared(p, q) < Vector3.DistanceSquared(p, best)) best = q;
    dot += nrm[i] * (p.x - best.x) + nrm[i + 1] * (p.y - best.y) + nrm[i + 2] * (p.z - best.z);
  }
  if (dot < 0) { for (let i = 0; i < idx.length; i += 3) [idx[i + 1], idx[i + 2]] = [idx[i + 2], idx[i + 1]]; VertexData.ComputeNormals(pos, idx, nrm); }
  const vd = new VertexData();
  vd.positions = pos; vd.indices = idx; vd.normals = nrm;
  return vd;
}
/** A flat prism: the polygon POLY (star-shaped about its centroid) in the (y, z) plane, X thick, flat-shaded. */
function prism(poly: [number, number][], x: number): VertexData {
  const pos: number[] = [], idx: number[] = [], n = poly.length;
  const cy = poly.reduce((s, p) => s + p[0], 0) / n, cz = poly.reduce((s, p) => s + p[1], 0) / n;
  for (const sx of [-x / 2, x / 2]) { pos.push(sx, cy, cz); for (const [y, z] of poly) pos.push(sx, y, z); }
  const m = n + 1;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    idx.push(0, 1 + i, 1 + j, m, m + 1 + j, m + 1 + i);
    idx.push(1 + i, m + 1 + i, 1 + j, 1 + j, m + 1 + i, m + 1 + j);
  }
  const P: number[] = [], I: number[] = [];          // unwelded: each face keeps its own normal
  for (const k of idx) { P.push(pos[3 * k], pos[3 * k + 1], pos[3 * k + 2]); I.push(I.length); }
  return finish(P, I, [new Vector3(0, cy, cz)]);
}

// ---------------------------------------------------------------- the hair (TYBW: down, long, straight, heavy forelocks)
function hair(add: Add, hc: [number, number, number], H: number, o: { parted: boolean }): void {
  const C = new Vector3(...hc), bones: BoneName[] = ['head', 'neck', 'chest'];
  const at = (x: number, y: number, z: number) => C.add(new Vector3(x * H, y * H, z * H));
  const col = L(KC.hair);
  // the cap over the skull, fuller at the back and the crown
  add(ellipsoid([hc[0], hc[1] + 0.07 * H, hc[2] + 0.05 * H], [0.41 * H, 0.48 * H, 0.46 * H], 16, 10), col, ['head']);
  add(ellipsoid([hc[0], hc[1] - 0.05 * H, hc[2] + 0.2 * H], [0.38 * H, 0.42 * H, 0.32 * H], 12, 8), col, ['head']);
  // the long fall down the back and sides: locks from the crown ring, longest at the back (to the shoulder blades),
  // jagged ends; az 0 = straight back
  const N = 13;
  for (let i = 0; i < N; i++) {
    const az = (-1 + (2 * i) / (N - 1)) * 2.0, sa = Math.sin(az), ca = Math.cos(az);
    const len = (2.1 + 0.35 * Math.sin(i * 2.7) - 0.45 * Math.abs(az) / 2) * (Math.abs(az) > 1.7 ? 0.8 : 1);
    const root = at(sa * 0.3, 0.32, ca * 0.3 + 0.05);
    const ctrl = at(sa * 0.62, -0.2, ca * 0.62 + 0.12);
    const tip = at(sa * (0.62 + 0.12 * Math.abs(sa)), -len, ca * 0.58 + 0.35 + 0.08 * Math.sin(i * 1.9));
    add(lock(root, ctrl, tip, 0.2 * H, 0.07 * H, new Vector3(ca, 0, -sa)), col, bones);
  }
  // a second, shorter layer over it (the volume at the nape), and two locks down each side in front of the ears
  for (let i = 0; i < 7; i++) {
    const az = (-1 + (2 * i) / 6) * 1.5, sa = Math.sin(az), ca = Math.cos(az);
    add(lock(at(sa * 0.28, 0.45, ca * 0.25), at(sa * 0.58, 0.05, ca * 0.6 + 0.1), at(sa * 0.66, -1.1 - 0.2 * Math.cos(i * 2.1), ca * 0.75 + 0.15),
      0.19 * H, 0.07 * H, new Vector3(ca, 0, -sa)), col, bones);
  }
  for (const s of [1, -1]) for (const [dz, len] of [[-0.12, 1.25], [0.08, 1.55]] as const)
    add(lock(at(s * 0.33, 0.2, dz), at(s * 0.5, -0.3, dz - 0.05), at(s * 0.56, -len, dz - 0.12), 0.14 * H, 0.06 * H, new Vector3(0, 0, 1)), col, bones);
  // the forelocks: heavy pointed locks from the hairline hanging over the brow to the eyes (one down between them, the
  // eyes themselves clear); the Bankai's horns part them (PARTED). [root x, tip x, tip y, width] in head units
  const fore: [number, number, number, number][] = o.parted
    ? [[-0.36, -0.44, -0.18, 0.16], [-0.24, -0.34, 0.0, 0.15], [0.24, 0.34, 0.0, 0.15], [0.36, 0.44, -0.2, 0.16], [0.0, -0.02, 0.08, 0.1]]
    : [[-0.36, -0.42, -0.18, 0.16], [-0.24, -0.27, 0.0, 0.15], [-0.1, -0.12, 0.18, 0.13], [0.02, 0.0, 0.02, 0.11], [0.13, 0.15, 0.16, 0.13],
      [0.25, 0.29, -0.02, 0.15], [0.36, 0.42, -0.2, 0.16]];
  for (const [x0, x1, y1, w] of fore)
    add(lock(at(x0, 0.46, -0.3), at(x0 + (x1 - x0) * 0.3, 0.34, -0.5), at(x1, y1, -0.48 + 0.1 * Math.abs(x1)), w * H, 0.05 * H, new Vector3(1, 0, 0)),
      col, ['head']);
  // highlight strokes on the crown (the spec's 2-3 light streaks)
  for (const [a0, a1] of [[-0.55, -0.25], [-0.1, 0.15], [0.35, 0.6]] as const) {
    const p0 = at(Math.sin(a0) * 0.38, 0.38, -Math.cos(a0) * 0.36 + 0.12), p1 = at(Math.sin(a1) * 0.4, 0.2, -Math.cos(a1) * 0.4 + 0.18);
    add(lock(p0, p0.add(p1).scale(0.5).add(new Vector3(0, 0.05 * H, -0.03 * H)), p1, 0.035 * H, 0.012 * H, new Vector3(1, 0, 0), 4, 4),
      L(KC.hairHi), ['head']);
  }
}

// ---------------------------------------------------------------- the body: the shared shihakusho, his arms, the scar
interface KenLook { parted: boolean; horns: boolean; oneArm: boolean; wreck: boolean }
function kenParts(sp: BodySpec, r: Rig, o: KenLook): Part[] {
  const H = r.H;
  let parts = kimono(sp, r, (add, hc) => {
    hair(add, hc, H, o);
    if (o.horns) for (const s of [1, -1]) {           // two short horns from the hairline, in the skin colour
      const b = new Vector3(hc[0] + s * 0.17 * H, hc[1] + 0.34 * H, hc[2] - 0.33 * H);
      add(limb(b, b.add(new Vector3(s * 0.12 * H, 0.45 * H, -0.16 * H)), 0.1 * H, 0.01, 8), sp.skin, ['head']);
    }
  });
  // his arms: kimono()'s torn sleeves (bare arms under a ragged short kosode sleeve), plus the bulk of his arms below
  if (o.oneArm)                                      // KATAUDE: the left arm gone below the sleeve stubs
    parts = parts.filter((p) => !p.bones.some((b) => b === 'foreL' || b === 'handL'));
  const add: Add = adder(sp, parts);
  for (const s of [1, -1] as const) {
    const S = s > 0 ? 'R' : 'L', arm = r.rest[`arm${S}`], el = r.rest[`fore${S}`], ar = 0.25 * H * sp.limb;
    if (o.oneArm && s < 0) continue;
    // the biceps and the forearm's bulk (big arms)
    const mid = arm.add(el.subtract(arm).scale(0.62));
    add(ellipsoid([mid.x + s * 0.01, mid.y, mid.z - 0.025 * H], [ar * 1.05, ar * 1.5, ar * 1.12], 10, 6), sp.skin, [`arm${S}`, `fore${S}`] as BoneName[]);
    const wr = r.rest[`hand${S}`], fm = el.add(wr.subtract(el).scale(0.3));
    add(ellipsoid([fm.x, fm.y, fm.z - 0.01 * H], [ar * 0.95, ar * 1.5, ar * 0.95], 10, 6), sp.skin, [`fore${S}`, `arm${S}`] as BoneName[]);
  }
  // the chest scar: one long diagonal welt across the open collar
  const cz = -sp.chest[1] * H - 0.012, y = (u: number) => u * r.bs;
  add(limb(new Vector3(0.1 * H, y(6.55), cz + 0.004), new Vector3(-0.09 * H, y(5.75), cz - 0.006), 0.016, 0.012, 5, 0.5), L(KC.scar), ['chest']);
  if (o.wreck) {                                      // KATAUDE: the right forearm split along its four cracks
    const el = r.rest.foreR, wr = r.rest.handR;
    for (let i = 0; i < 4; i++) {
      const t0 = 0.12 + 0.2 * i, a = el.add(wr.subtract(el).scale(t0)), b = el.add(wr.subtract(el).scale(t0 + 0.18));
      const ang = -0.6 + 0.4 * i, ox = Math.sin(ang) * 0.075 * H * sp.limb * 1.25, oz = -Math.cos(ang) * 0.075 * H * sp.limb * 1.25;
      add(limb(a.add(new Vector3(ox, 0, oz)), b.add(new Vector3(ox * 0.8, 0, oz * 0.8)), 0.012, 0.006, 4), L(KC.blood), ['foreR', 'handR']);
    }
  }
  return parts;
}

// ---------------------------------------------------------------- the face: grin / roar / gritted teeth
/** ONI: the Bankai's white irisless eyes. */
function face(oni: boolean) {
  return (g: CanvasRenderingContext2D, e: number) => {
    const line = (w: number, ...p: number[]) => inkLine(g, w, ...p);
    const poly = (fill: string, ...p: number[]) => {
      g.fillStyle = fill; g.beginPath(); g.moveTo(p[0], p[1]); for (let i = 2; i < p.length; i += 2) g.lineTo(p[i], p[i + 1]); g.closePath(); g.fill();
    };
    for (const [x, s] of [[90, -1], [166, 1]] as const) {     // s = +1 his left (screen right), -1 his right
      const ox = (dx: number) => x + s * dx;
      if (e === 2) {                                          // hurt: squeezed shut, a hard crease
        line(6, ox(-26), 118, ox(4), 128, ox(24), 120); line(4, ox(-20), 134, ox(14), 132);
      } else {
        // the sclera: a narrow slanted block, the outer corner raised (a fierce eye)
        poly('#fff', ox(-25), 128, ox(-14), 118, ox(22), 112, ox(27), 120, ox(14), 131);
        if (!oni) {
          g.fillStyle = '#1a1414';
          g.beginPath(); g.arc(ox(e === 1 ? 4 : 1), 122, e === 1 ? 5 : 7, 0, 7); g.fill();
        }
        line(5, ox(-28), 129, ox(-14), 116, ox(24), 109, ox(30), 118);     // the upper lid, heavy
        line(3, ox(-22), 132, ox(14), 133);
      }
      // the brows: filled wedges, thick at the nose, angled down hard
      const k = e === 1 ? 10 : e === 2 ? -4 : 4;
      poly('#1a1414', ox(-18), 104 + k, ox(-12), 92 + k, ox(32), 84, ox(34), 92);
    }
    g.strokeStyle = oni ? '#3a0c0c' : '#8a4a3a';                         // the long scar down his left side (screen right)
    line(5, 176, 44, 160, 204); line(3, 168, 112, 182, 116); line(3, 166, 150, 180, 154);
    g.strokeStyle = '#1a1414';
    line(3, 112, 160, 120, 168);                                         // the nostril shadow
    if (e === 0) {                                                       // the grin: wide, lopsided, teeth showing
      poly('#3a1214', 92, 190, 128, 196, 168, 182, 164, 200, 128, 210, 98, 202);
      poly('#f4f0e8', 98, 192, 128, 198, 162, 186, 160, 194, 128, 202, 100, 198);
      line(4, 86, 188, 98, 191, 128, 197, 166, 182, 174, 176);
    }
    if (e === 1) {                                                       // the roar
      g.fillStyle = '#3a1214'; g.beginPath(); g.ellipse(128, 198, 34, 26, 0, 0, 7); g.fill();
      poly('#f4f0e8', 98, 182, 158, 182, 154, 190, 102, 190); poly('#f4f0e8', 106, 216, 150, 216, 146, 222, 110, 222);
      line(4, 94, 196, 98, 182, 128, 174, 158, 182, 162, 196);
    }
    if (e === 2) {                                                       // gritted teeth
      poly('#f4f0e8', 100, 190, 156, 188, 154, 204, 102, 206);
      line(4, 98, 190, 156, 188); line(4, 100, 206, 154, 204); line(3, 114, 190, 114, 205); line(3, 128, 189, 128, 205); line(3, 142, 189, 142, 205);
    }
  };
}

// ---------------------------------------------------------------- weapons (all in the katana's grip frame)
/** Rigid pieces built in a blade frame (x thick, y from the fist to the tip, z across to the edge), turned into the
 *  weapon bone's frame like katana(): the blade leaves the fist tipped KEN_GRIP degrees forward. */
function bladeMesh(scene: Scene, name: string, pieces: { vd: VertexData; c: number }[]) {
  const m = T(0, 0, 0, Math.PI + (KEN_GRIP * Math.PI) / 180);
  for (const p of pieces) p.vd.transform(m);
  return rigid(scene, name, pieces);
}
const bx = (x: number, y0: number, y1: number, z0: number, z1: number, rx = 0) =>
  box(x, y1 - y0, z1 - z0, T(0, (y0 + y1) / 2, (z0 + z1) / 2, rx));
const rod = (y0: number, y1: number, r: number) => tube([[y0, 0.002, 0.002], [y0, r, r], [y1, r, r], [y1, 0.002, 0.002]], 8);
/** The wrapped handle from Y0 down to Y1 (< Y0): cloth with dark diamond wraps. */
function handle(y0: number, y1: number, cloth: number): { vd: VertexData; c: number }[] {
  const out = [{ vd: rod(y1, y0, 0.026), c: cloth }];
  for (let y = y0 - 0.05; y > y1 + 0.03; y -= 0.09) out.push({ vd: box(0.04, 0.04, 0.04, T(0, y, 0, 0, Math.PI / 4, Math.PI / 4)), c: L(KC.wrap) });
  return out;
}

/** NOZARASHI: a 1.5 m slab of a cleaver (0.29 wide, the edge chipped), a brass collar, the long cloth handle, the green
 *  tassel; ~2.2 m in all. The left hand takes the handle 0.22 m behind the right fist (clips/ken.ts). */
export function nozarashi(scene: Scene) {
  const P: { vd: VertexData; c: number }[] = [];
  P.push({ vd: prism([[0.12, -0.09], [1.56, -0.09], [1.68, 0.03], [1.64, 0.2], [0.12, 0.2]], 0.042), c: L(KC.steel) });
  P.push({ vd: bx(0.046, 0.14, 1.58, 0.13, 0.2), c: 0xd2d8e2 });              // the ground bevel
  P.push({ vd: prism([[0.12, 0.2], [1.64, 0.2], [1.62, 0.25], [0.12, 0.25]], 0.02), c: L(KC.blade) });   // the bright edge
  P.push({ vd: bx(0.048, 0.16, 1.5, -0.09, -0.06), c: L(KC.spine) });          // the dark spine
  P.push({ vd: bx(0.046, 0.2, 1.4, -0.04, -0.01), c: L(KC.spine) });          // the fuller
  for (const [y, d] of [[0.42, 0.03], [0.7, 0.02], [0.98, 0.035], [1.3, 0.025]] as const)
    P.push({ vd: box(0.05, d, d * 1.2, T(0, y, 0.245, Math.PI / 4)), c: L(KC.spine) });   // chips bitten out of the edge
  P.push({ vd: bx(0.08, 0.02, 0.12, -0.11, 0.22), c: L(KC.brass) });          // the collar
  P.push(...handle(0.02, -0.62, L(KC.cloth)));
  P.push({ vd: bx(0.07, -0.68, -0.62, -0.035, 0.035), c: L(KC.brass) });       // the pommel cap
  P.push({ vd: bx(0.03, -0.92, -0.68, -0.02, 0.02, 0.15), c: L(KC.tassel) });  // the tassel
  return bladeMesh(scene, 'nozarashi', P);
}
/** The Bankai's broken cleaver (anime ep. 44): the slab snapped on a diagonal at ~1 m, ink-black, a white edge line, no
 *  guard, a long cloth-wrapped tang like the first Zangetsu's hilt, its loose end hanging. */
export function brokenCleaver(scene: Scene) {
  const P: { vd: VertexData; c: number }[] = [];
  P.push({ vd: prism([[0.08, -0.09], [0.74, -0.09], [0.8, -0.02], [0.86, 0.02], [0.92, 0.1], [1.0, 0.14], [0.97, 0.2], [0.08, 0.2]], 0.042),
    c: L(KC.broken) });
  P.push({ vd: prism([[0.08, 0.2], [0.97, 0.2], [0.95, 0.24], [0.08, 0.24]], 0.02), c: L([0xf6f3ec, 0xa9b2cf]) });        // the white edge line
  P.push({ vd: bx(0.046, 0.12, 0.7, -0.05, -0.02), c: 0x3a3a42 });
  P.push(...handle(0.08, -0.56, L(KC.cloth)));
  P.push({ vd: bx(0.012, -0.8, -0.56, -0.03, 0.02, 0.3), c: L(KC.cloth) });  // the cloth's loose end
  return bladeMesh(scene, 'ke-broken', P);
}
/** The base katana: long, battered, chipped, a small dark guard. */
const kenKatana = (scene: Scene) =>
  katana(scene, { blade: 1.25, grip: 0.3, w: 0.036, bladeC: 0xe2e6ee, gripC: 0x2b2b38, chips: true, guard: 0x3a3426 });

// ---------------------------------------------------------------- the CharBody and its forms
const BASE: KenLook = { parted: false, horns: false, oneArm: false, wreck: false };
const ONI: KenLook = { parted: true, horns: true, oneArm: false, wreck: false };
const KATAUDE: KenLook = { parted: true, horns: true, oneArm: true, wreck: true };
const oniSpec: Partial<BodySpec> = { skin: L(KC.oni) };

export const ken: CharBody = {
  spec: { height: 2.0, heads: 8, shoulder: 1.18, chest: [0.88, 0.52], waist: [0.64, 0.44], hip: [0.66, 0.46], limb: 1.2,
    hand: 1.2, skin: L(KC.skin), black: L(KC.black), haori: L(KC.haori), obi: L(KC.obi), hair: L(KC.hair), collar: 1.45,
    haoriHem: 1.6, haoriSleeves: 'torn', sleeves: 'torn', tattered: true },
  parts: (sp, r) => kenParts(sp, r, BASE),
  drawFace: face(false),
  weapon: kenKatana,
  variant(form) {
    switch (form) {
      case 'nozarashi': case 'ryote': case 'nomihose': return { weapon: nozarashi };
      case 'bankai': return { spec: oniSpec, parts: (sp, r) => kenParts(sp, r, ONI), drawFace: face(true), weapon: brokenCleaver };
      case 'kataude': return { spec: oniSpec, parts: (sp, r) => kenParts(sp, r, KATAUDE), drawFace: face(true), weapon: brokenCleaver };
      default: return null;
    }
  },
};
