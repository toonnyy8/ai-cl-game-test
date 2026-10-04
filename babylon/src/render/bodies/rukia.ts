// Kuchiki Rukia (DUEL_RUKIA §2, BABYLON_LOOK B3): the 13th Division's lieutenant, 1.5 m (the hurt cylinder; canon 1.44),
// petite, the all-black shihakusho with no haori, the white lieutenant's armband on her left upper arm, the short black
// bob with the strand between her eyes, big violet eyes; Sode no Shirayuki: an all-white katana with a hollow snowflake
// guard (the long ribbon is B4's fx along the weapon's `pommel` node). The cold bands frost her progressively: -18 the
// hems, -50 ice rims on the sleeve / hakama hems, collar and hair tips and the rimed blade; -273.15 (zero) white hair
// and irises, cold skin, an ice half-crown behind the head, shoulder crystals, the ice blade and an ice-blue outline.
// Colours are lit / shadow pairs ([0] lit; each registered with body.ts pair(), so every part gets its shadow half).
import { Matrix, Mesh, TransformNode, Vector3, VertexData, type Scene } from '@babylonjs/core';
import {
  adder, ellipsoid, hex, inkLine, kimono, pair, limb, rigid, T, tube, type Add, type BodySpec, type Col, type CharBody, type Part, type Rig,
  type Ring,
} from '../body';
import type { BoneName } from '../pose';

const C = {
  black: [0x2b2d3a, 0x121319], white: [0xf3f1ea, 0xa9b2cf], skin: [0xf6dccb, 0xcf9e8c], hair: [0x2a2b38, 0x0e0f15],
  hairHi: [0xd8dce4, 0x8e96a8], badge: [0x15151d, 0x0a0a10], blade: [0xf4f6fa, 0x9aa6c0], grip: [0xe9ebf0, 0x8f97ab],
  frost: [0xe6eef6, 0x9aa8be], ice: [0xd2e6f6, 0x86a2c4], iceDeep: [0xa9c8e6, 0x6584ad],
  zSkin: [0xd6ccca, 0x9c94a6], zHair: [0xf4f6fa, 0xa9b4cc],
} as const;
for (const [l, sh] of Object.values(C)) pair(l, sh);
const ICE_INK = 0x7f97b4;        // the zero outline (DUEL_RUKIA §2 keyline)
const isHex = (p: Part, h: number) => { const c = hex(h); return Math.abs(p.color.r - c.r) + Math.abs(p.color.g - c.g) + Math.abs(p.color.b - c.b) < 1e-3; };

type Band = 'base' | 'm18' | 'm50' | 'zero';

// ---------------------------------------------------------------- body parts
function parts(band: Band) {
  return (sp: BodySpec, r: Rig): Part[] => {
    const { H } = r, zero = band === 'zero';
    const ps = kimono(sp, r, (add, hc) => hair(add, hc, H, sp.hair, zero));
    const add: Add = adder(sp, ps);
    armband(add, r, sp);
    if (band === 'm18' || band === 'm50') hems(ps, add, band === 'm50' ? C.ice[0] : C.frost[0], (band === 'm50' ? 0.3 : 0.16) * H);
    if (band === 'm50') iceTrim(add, r, sp);
    if (zero) { crown(add, r); shoulderIce(add, r); }
    return ps;
  };
}

/** The short bob (chin length, open at the face), side-swept bangs, the strand down between the eyes, three highlight
 *  strokes (black hair only). hc = the skull centre. */
function hair(add: Add, hc: [number, number, number], H: number, col: Col, white: boolean): void {
  const [x0, y0, z0] = hc, B: BoneName[] = ['head'];
  add(ellipsoid([0, y0 + 0.07 * H, z0 + 0.04 * H], [0.4 * H, 0.47 * H, 0.45 * H], 16, 10), col, B);       // the crown
  const fr = 0.98;                                          // the face opening, radians either side of the front
  add(tube([[y0 + 0.3 * H, 0.4 * H, 0.45 * H, x0, z0 + 0.04 * H], [y0 + 0.02 * H, 0.445 * H, 0.48 * H, x0, z0 + 0.05 * H],
    [y0 - 0.26 * H, 0.46 * H, 0.47 * H, x0, z0 + 0.07 * H], [y0 - 0.44 * H, 0.47 * H, 0.45 * H, x0, z0 + 0.09 * H],
    [y0 - 0.47 * H, 0.41 * H, 0.4 * H, x0, z0 + 0.09 * H]], 18, { a0: fr, a1: Math.PI * 2 - fr, double: true }), col, B);
  // bangs: locks from the crown's front sweeping down and out over the brow to the cheeks
  for (const s of [1, -1]) for (const [x1, y1, x2, y2, rr] of [[0.05, 0.42, 0.15, 0.22, 0.075], [0.15, 0.4, 0.3, 0.15, 0.08],
    [0.25, 0.33, 0.41, -0.28, 0.07]] as const)
    add(limb(new Vector3(s * x1 * H, y0 + y1 * H, z0 - 0.33 * H), new Vector3(s * x2 * H, y0 + y2 * H, z0 - 0.41 * H + Math.abs(x2) * 0.25 * H),
      rr * H, 0.012 * H, 6), col, B);
  // the strand between the eyes: from the parting down past the brow to the bridge of the nose
  const a = new Vector3(0.01 * H, y0 + 0.44 * H, z0 - 0.32 * H), m = new Vector3(-0.01 * H, y0 + 0.2 * H, z0 - 0.47 * H),
    b = new Vector3(0.02 * H, y0 - 0.06 * H, z0 - 0.5 * H);
  add(limb(a, m, 0.05 * H, 0.04 * H, 6), col, B); add(limb(m, b, 0.04 * H, 0.008 * H, 6), col, B);
  if (white) return;
  // three white highlight strokes on the crown (Kubo's white-on-black)
  for (const [ax, ay, bx, by] of [[0.22, 0.32, 0.1, 0.4], [0.3, 0.2, 0.2, 0.33], [-0.18, 0.36, -0.28, 0.25]] as const) {
    const p = (x: number, y: number) => {
      const yy = (y - 0.07) / 0.47, zz = Math.sqrt(Math.max(0, 1 - (x / 0.4) ** 2 - yy * yy)) * 0.45 * 1.04;
      return new Vector3(x * H, y0 + y * H, z0 + 0.04 * H - zz * H);
    };
    add(limb(p(ax, ay), p(bx, by), 0.018 * H, 0.012 * H, 5, 0.4), C.hairHi[0], B);
  }
}

/** The lieutenant's armband: a white band round her left upper arm over the sleeve, the division badge in ink on its
 *  outside. The ring follows kimono()'s sleeve (its rings at 0.05 H and -1.0 bs). */
function armband(add: Add, r: Rig, sp: BodySpec): void {
  const { rest: R, H, bs } = r, ar = 0.25 * H * sp.limb, arm = R.armL, el = R.foreL;
  const at = (dy: number, k = 1.1): Ring => { const t = (0.05 * H - dy) / (0.05 * H + 1.0 * bs);
    return [dy, ar * (1.3 + 0.3 * t) * k, ar * (1.3 + 0.9 * t) * k, 0, 0.35 * ar * t]; };
  const band = tube([at(-0.2 * bs, 1.0), at(-0.24 * bs), at(-0.46 * bs), at(-0.5 * bs, 1.0)], 14);
  const m = T(el.x * 0.5 + arm.x * 0.5, arm.y - 0.05 * H, arm.z), B: BoneName[] = ['shoulderL', 'armL'];
  band.transform(m); add(band, C.white[0], B);
  const [, rx, , , cz] = at(-0.35 * bs);
  const badge = VertexData.CreateBox({ width: 0.02 * H, height: 0.15 * bs, depth: 0.16 * H });
  badge.transform(Matrix.Translation(-rx - 0.004, -0.35 * bs, cz!).multiply(m)); add(badge, C.badge[0], B);
}

/** The bottom band of a hanging part (sleeve, hakama leg): its lowest 12 % as [y0, y1, rx, rz, cx, cz]. Read off the
 *  built geometry so the rims follow kimono() when B2-look reshapes it. */
function hemOf(p: Part): [number, number, number, number, number, number] {
  const P = p.vd.positions as number[];
  let lo = Infinity, hi = -Infinity;
  for (let i = 1; i < P.length; i += 3) { lo = Math.min(lo, P[i]); hi = Math.max(hi, P[i]); }
  const top = lo + 0.12 * (hi - lo);
  let x0 = Infinity, x1 = -Infinity, z0 = Infinity, z1 = -Infinity;
  for (let i = 0; i < P.length; i += 3) if (P[i + 1] <= top) {
    x0 = Math.min(x0, P[i]); x1 = Math.max(x1, P[i]); z0 = Math.min(z0, P[i + 2]); z1 = Math.max(z1, P[i + 2]);
  }
  return [lo, top, (x1 - x0) / 2, (z1 - z0) / 2, (x0 + x1) / 2, (z0 + z1) / 2];
}
/** Frost / ice rims W tall on the hanging sleeves' and the hakama legs' hems. */
function hems(ps: Part[], add: Add, col: number, w: number): void {
  for (const p of ps.slice()) {
    if (!isHex(p, C.black[0])) continue;
    const leg = p.bones.some((b) => b.startsWith('shin')), sleeve = !leg && p.bones.some((b) => b.startsWith('fore'));
    if (!leg && !sleeve) continue;
    const [y0, , rx, rz, cx, cz] = hemOf(p);
    if (sleeve && rx < 0.05) continue;                      // the upper arm's cloth, not the hanging sleeve
    add(tube([[y0 - 0.005, rx * 1.05, rz * 1.05, cx, cz], [y0 + w, rx * 1.05, rz * 1.05, cx, cz]], 16), col, p.bones);
  }
}
/** -50: icicles along the bob's ends, small crystals at the collar. */
function iceTrim(add: Add, r: Rig, sp: BodySpec): void {
  const { rest: R, H, bs } = r, hc = [0, R.head.y + 0.42 * H, R.head.z - 0.02 * H];
  for (let i = 0; i < 11; i++) {
    const a = 0.98 + ((Math.PI * 2 - 1.96) * (i + 0.5)) / 11, rx = 0.47 * H, rz = 0.45 * H;
    const top = new Vector3(rx * Math.sin(a), hc[1] - 0.42 * H, hc[2] + 0.09 * H - rz * Math.cos(a));
    add(limb(top, top.add(new Vector3(0, -(0.2 + 0.08 * (i % 3)) * H, 0)), 0.05 * H, 0.004, 5), C.ice[0], ['head']);
  }
  const cz = sp.chest[1];
  for (const s of [1, -1]) {
    const base = new Vector3(s * 0.26 * H, 6.72 * bs, -cz * H * 0.72);
    add(limb(base, base.add(new Vector3(s * 0.12 * H, 0.16 * H, 0.02 * H)), 0.04 * H, 0.004, 5), C.ice[0], ['chest', 'neck']);
    add(limb(base, base.add(new Vector3(s * 0.2 * H, 0.04 * H, 0.06 * H)), 0.035 * H, 0.004, 5), C.ice[0], ['chest', 'neck']);
  }
}
/** Zero: the ice half-crown, a fan of shards standing behind the head. */
function crown(add: Add, r: Rig): void {
  const { rest: R, H } = r, c = new Vector3(0, R.head.y + 0.5 * H, R.head.z + 0.44 * H);
  const on = (deg: number) => { const a = (deg * Math.PI) / 180; return c.add(new Vector3(Math.sin(a), Math.cos(a), 0).scale(0.48 * H)); };
  for (let i = 0; i < 7; i++) {
    const deg = -60 + 20 * i, a = (deg * Math.PI) / 180, len = (i === 3 ? 0.85 : i % 2 ? 0.4 : 0.62 - 0.1 * Math.abs(i - 3)) * H;
    const d = new Vector3(Math.sin(a), Math.cos(a), 0.35).normalize();
    add(limb(on(deg), on(deg).add(d.scale(len)), (i % 2 ? 0.055 : 0.075) * H, 0.004, 6, 0.45), i % 2 ? C.iceDeep[0] : C.ice[0], ['head']);
  }
  for (let j = 0; j < 7; j++) add(limb(on(-70 + 20 * j), on(-50 + 20 * j), 0.045 * H, 0.045 * H, 6), C.ice[0], ['head']);
}
/** Zero: ice crystals growing off both shoulders. */
function shoulderIce(add: Add, r: Rig): void {
  const { rest: R, H } = r;
  for (const s of [1, -1] as const) {
    const S = s > 0 ? 'R' : 'L', p = R[`arm${S}`].add(new Vector3(-s * 0.08 * H, 0.2 * H, 0.02 * H));
    for (const [dx, dy, dz, l] of [[0.35, 1, 0.1, 0.42], [0.9, 0.55, -0.15, 0.34], [0.1, 0.8, 0.5, 0.3], [0.7, 0.9, 0.35, 0.26]] as const) {
      const d = new Vector3(s * dx, dy, dz).normalize();
      add(limb(p, p.add(d.scale(1.3 * l * H)), 0.08 * H, 0.006, 6), dz > 0.2 ? C.iceDeep[0] : C.ice[0], [`shoulder${S}`, 'chest'] as BoneName[]);
    }
  }
}

// ---------------------------------------------------------------- the face: big anime eyes, violet (zero: white) irises
function face(zero: boolean) {
  return (g: CanvasRenderingContext2D, e: number) => {
    const ink = zero ? '#4f6688' : '#1a1414', brow = zero ? '#cfe3f2' : '#2a2b38';
    const iris = zero ? '#eef3f8' : '#6a52a8', irisDeep = zero ? '#a8b8cc' : '#3c2a6e';
    g.strokeStyle = ink; g.fillStyle = ink;
    const line = (w: number, ...p: number[]) => inkLine(g, w, ...p);
    for (const [x, s] of [[90, -1], [166, 1]] as const) {       // s = +1 her left (screen right)
      if (e === 2) {                                             // squeezed shut: > <
        line(5, x - 22 * s, 116, x + 14 * s, 128, x - 22 * s, 138);
        g.strokeStyle = brow; line(4, x - 26 * s, 90, x + 18 * s, 100); g.strokeStyle = ink;
        continue;
      }
      const h = e === 1 ? 17 : 24;                               // the shout narrows the eye
      g.fillStyle = '#fff'; g.beginPath(); g.ellipse(x, 130, 25, h, 0, 0, 7); g.fill();
      g.save(); g.beginPath(); g.ellipse(x, 130, 25, h, 0, 0, 7); g.clip();
      g.fillStyle = irisDeep; g.beginPath(); g.ellipse(x + 2 * s, 133, 16, 20, 0, 0, 7); g.fill();
      g.fillStyle = iris; g.beginPath(); g.ellipse(x + 2 * s, 138, 14, 14, 0, 0, 7); g.fill();
      if (!zero) { g.fillStyle = '#16101e'; g.beginPath(); g.arc(x + 2 * s, 133, 7, 0, 7); g.fill(); }
      g.fillStyle = '#fff'; g.beginPath(); g.arc(x - 5 * s, 124, 5, 0, 7); g.fill();
      g.restore();
      g.fillStyle = ink;                                          // the heavy upper lash line, flicked out at the corner
      g.beginPath(); g.moveTo(x - 26 * s, 128 - h * 0.2); g.quadraticCurveTo(x, 130 - h * 1.45, x + 27 * s, 120 - h * 0.35);
      g.lineTo(x + 30 * s, 112); g.quadraticCurveTo(x + 4 * s, 124 - h * 1.7, x - 26 * s, 124 - h * 0.25); g.fill();
      line(2, x - 14 * s, 130 + h * 0.95, x + 14 * s, 130 + h * 0.9);
      g.strokeStyle = brow;                                       // thin brows; the shout pulls them down to the centre
      if (e === 1) line(4, x - 26 * s, 98, x + 18 * s, 92); else line(3.5, x - 24 * s, 92, x + 20 * s, 88);
      g.strokeStyle = ink;
    }
    if (e === 0) line(3, 120, 200, 136, 200);
    if (e === 1) { g.fillStyle = '#5a1e26'; g.beginPath(); g.moveTo(112, 192); g.quadraticCurveTo(128, 186, 144, 192);
      g.quadraticCurveTo(140, 214, 128, 214); g.quadraticCurveTo(116, 214, 112, 192); g.fill();
      g.fillStyle = '#f4f0e8'; g.fillRect(116, 192, 24, 4); }
    if (e === 2) line(4, 112, 204, 120, 198, 128, 204, 136, 198, 144, 204);
  };
}

// ---------------------------------------------------------------- Sode no Shirayuki (white / rime / ice)
type Blade = 'white' | 'rime' | 'ice';
/** The blade in her fist (body.ts katana()'s frame: the grip at the weapon bone, the blade along the forearm tipped
 *  20 deg forward), all white, the hollow snowflake guard; child nodes `pommel` and `tip` for the ribbon / trail fx. */
function sword(kind: Blade) {
  return (scene: Scene): Mesh => {
    const blade = kind === 'ice' ? 0.82 : 0.74, grip = 0.2, w = kind === 'ice' ? 0.038 : 0.034, g0 = 0.06;
    const bc = kind === 'ice' ? C.ice[0] : C.blade[0], gc = kind === 'ice' ? C.frost[0] : C.grip[0];
    const out: { vd: VertexData; c: number }[] = [];
    const rings: Ring[] = [];
    for (let i = 0; i <= 24; i++) {
      const t = i / 24, tip = t > 0.88 ? 1 - ((t - 0.88) / 0.12) * 0.95 : 1;
      rings.push([t * blade, 0.005, w * tip, 0, w * (1 - tip) * 0.5]);
    }
    const mt = (20 * Math.PI) / 180, dy = -Math.cos(mt), dz = -Math.sin(mt);
    const toBlade = T(0, dy * g0, dz * g0, Math.PI + mt), toGrip = T(0, dy * g0, dz * g0, mt);
    const bl = tube(rings, 4); bl.transform(toBlade); out.push({ vd: bl, c: bc });
    if (kind !== 'white') {                     // crystals along the back (rime: small; ice: a jagged ridge), an ice edge
      const n = kind === 'ice' ? 9 : 6;
      for (let i = 0; i < n; i++) {
        const y = (0.12 + (0.72 * i) / n) * blade, h = (kind === 'ice' ? 0.05 : 0.03) * (1 - 0.4 * (i % 2));
        const c = limb(new Vector3(0, y, w * 0.6), new Vector3(0, y + 0.03, w * 0.6 + h), 0.012, 0.002, 4);
        c.transform(toBlade); out.push({ vd: c, c: kind === 'ice' ? C.iceDeep[0] : C.ice[0] });
      }
      const edge = tube(rings.map(([y, rx, rz, cx = 0, cz = 0]) => [y, rx * 1.4, rz * 0.25, cx, cz - rz * 0.85] as Ring), 4);
      edge.transform(toBlade); out.push({ vd: edge, c: kind === 'ice' ? 0xffffff : C.ice[0] });
    }
    const gr = tube([[0, 0.014, 0.017], [grip, 0.015, 0.018], [grip + 0.012, 0.004, 0.004]], 8); gr.transform(toGrip);
    out.push({ vd: gr, c: gc });
    // the guard: a hollow ring with six snowflake points in the plane across the blade
    const ring = VertexData.CreateTorus({ diameter: 0.07, thickness: 0.011, tessellation: 18 }); ring.transform(toGrip);
    out.push({ vd: ring, c: bc });
    for (let i = 0; i < 6; i++) {
      const a = (i * Math.PI) / 3, d = new Vector3(Math.cos(a), 0, Math.sin(a));
      const p = limb(d.scale(0.035), d.scale(0.058), 0.007, 0.002, 4); p.transform(toGrip); out.push({ vd: p, c: bc });
    }
    const m = rigid(scene, 'weapon', out);
    const node = (name: string, v: Vector3, mat: Matrix) => {
      const n = new TransformNode(name, scene); n.parent = m; n.position = Vector3.TransformCoordinates(v, mat);
    };
    node('pommel', new Vector3(0, grip + 0.012, 0), toGrip); node('tip', new Vector3(0, blade, 0), toBlade);
    return m;
  };
}

// ---------------------------------------------------------------- the CharBody
const SPEC: BodySpec = { height: 1.5, heads: 7, shoulder: 0.82, chest: [0.6, 0.4], waist: [0.46, 0.35], hip: [0.56, 0.4],
  limb: 0.84, hand: 1.05, skin: C.skin[0], black: C.black[0], haori: false, obi: C.black[0], hair: C.hair[0],
  collar: 0.6, haoriHem: 1.6, haoriSleeves: 'long', tattered: false };

export const rukia: CharBody = {
  spec: SPEC,
  parts: parts('base'),
  drawFace: face(false),
  weapon: sword('white'),
  variant: (form) => form === 'm18' ? { parts: parts('m18') }
    : form === 'm50' ? { parts: parts('m50'), weapon: sword('rime') }
    : form === 'zero' ? { parts: parts('zero'), drawFace: face(true), weapon: sword('ice'), ink: ICE_INK,
      spec: { skin: C.zSkin[0], hair: C.zHair[0] } }
    : null,
};
