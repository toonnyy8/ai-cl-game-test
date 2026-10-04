// Yamamoto Genryusai (BABYLON_LOOK.md B2): bald, the hunch, thick long white brows, the beard to the obi (three lit
// strands, the purple cord), the X scar, the empty left sleeve (DUEL_DESIGN §6.1: one-handed; the rig keeps the bone),
// Ryujin Jakka on a wooden cane hilt. Bankai East / West (the user, 2026-10-04: as in TYBW): no haori, the black
// shihakusho with the right shoulder and arm bared (scarred), the left sleeve empty; East's blade charred with an
// ember edge, West's charcoal (the flame tongues and the heat wisps are B4's VFX). Hellfire has no body look of its own
// (its aura and the blade fire are VFX).
import { Vector3, type Scene } from '@babylonjs/core';
import { PAL, adder, ellipsoid, inkLine, katana, kimono, limb, pair, tube, type Add, type BodySpec, type CharBody, type Rig } from '../body';

const BEARD = pair(0xeceae4, 0xa4acc4), STRAND = pair(0xffffff, 0xd2d8e6), CORD = pair(0x6a4a8e, 0x3e2c5c);
const WOOD = pair(0x7a5434, 0x4a3020), CHAR = pair(0x3a3230, 0x1e1a1a), EMBER = pair(0xff6a2a, 0xe0461a);
const CHARCOAL = pair(0x4a4644, 0x26242a), SCAR = pair(0xb06a52, 0x7a4234), COLLAR = pair(0x8a8070, 0x5a5248);

/** The head: brows, beard, moustache (beard-coloured parts outline as a silhouette only). */
function head(sp: BodySpec, r: Rig, add: Add, hc: [number, number, number]): void {
  const H = r.H, y = (v: number) => v * r.bs, cz = sp.chest[1], wz = sp.waist[1], bz = hc[2] - 0.3 * H;
  // the long beard from the jaw to the obi (the upper half rides the head, the rest the chest)
  const front = (v: number) => (v > 5.6 ? -cz * H - 0.12 * H : -wz * H - 0.13 * H);
  add(tube([[hc[1] - 0.12 * H, 0.3 * H, 0.12 * H, 0, bz + 0.06 * H], [hc[1] - 0.42 * H, 0.31 * H, 0.18 * H, 0, bz - 0.05 * H],
    [hc[1] - 0.9 * H, 0.28 * H, 0.17 * H, 0, front(6)], [y(5.6), 0.22 * H, 0.14 * H, 0, front(5.6)],
    [y(5.05), 0.14 * H, 0.1 * H, 0, front(5)], [y(4.85), 0.04 * H, 0.04 * H, 0, front(4.85)]], 12),
    BEARD, ['head', 'neck', 'chest']);
  // three lit strands down its front, the purple cord near the end
  for (const s of [-1, 0, 1]) add(limb(new Vector3(s * 0.12 * H, hc[1] - 0.45 * H, bz - 0.2 * H),
    new Vector3(s * 0.06 * H, y(5.15), front(5.2) - 0.08 * H), 0.025 * H, 0.012 * H, 5), STRAND, ['head', 'neck', 'chest'], true);
  add(tube([[y(5.22), 0.15 * H, 0.11 * H, 0, front(5.2)], [y(5.3), 0.165 * H, 0.12 * H, 0, front(5.3)],
    [y(5.38), 0.15 * H, 0.11 * H, 0, front(5.4)]], 10), CORD, ['chest']);
  // the moustache
  for (const s of [1, -1]) add(limb(new Vector3(s * 0.04 * H, hc[1] - 0.12 * H, hc[2] - 0.43 * H),
    new Vector3(s * 0.38 * H, hc[1] - 0.46 * H, hc[2] - 0.3 * H), 0.07 * H, 0.02 * H, 6), BEARD, ['head']);
  // the thick long brows (0.07 H), drooping past the eyes
  for (const s of [1, -1]) add(limb(new Vector3(s * 0.08 * H, hc[1] + 0.14 * H, hc[2] - 0.42 * H),
    new Vector3(s * 0.48 * H, hc[1] - 0.16 * H, hc[2] - 0.3 * H), 0.07 * H, 0.02 * H, 7), BEARD, ['head']);
}

/** Bankai's bared side: two scars across the breast. */
function scars(sp: BodySpec, r: Rig, add: Add): void {
  const H = r.H, y = (v: number) => v * r.bs, cz = sp.chest[1];
  for (const [x0, y0, x1, y1] of [[0.12, 6.45, 0.52, 5.7], [0.22, 6.0, 0.58, 6.25]])
    add(limb(new Vector3(x0 * H, y(y0), -cz * H * 0.98 - 0.07 * H), new Vector3(x1 * H, y(y1), -cz * H * 0.9 - 0.07 * H), 0.022 * H, 0.018 * H, 5),
      SCAR, ['chest']);
}

/** Ryujin Jakka on its cane hilt: a plain wooden grip, a metal collar where the blade leaves it, a rounded pommel. */
const cane = (blade: number, edge: number) => (scene: Scene) => katana(scene, {
  blade: 0.86, grip: 0.24, w: 0.03, bladeC: blade, gripC: WOOD, edge,
  extra: [{ vd: tube([[-0.012, 0.019, 0.023], [0.012, 0.019, 0.023]], 8), c: COLLAR },
          { vd: tube([[0.23, 0.018, 0.022], [0.255, 0.024, 0.026], [0.27, 0.005, 0.005]], 8), c: WOOD }],
});

export const yama: CharBody = {
  spec: { height: 1.65, heads: 7.5, shoulder: 0.95, chest: [0.66, 0.42], waist: [0.52, 0.38], hip: [0.6, 0.4], limb: 0.9,
    hand: 1.25, skin: PAL.skinYama, black: PAL.black, haori: PAL.haori, obi: PAL.obi, hair: BEARD, collar: 0.7,
    haoriHem: 2.35, haoriSleeves: 'long', tattered: false, emptyL: true, reiatsu: 0xff7a2a },
  parts: (sp, r) => kimono(sp, r, (add, hc) => head(sp, r, add, hc)),
  drawFace: (g, e) => {
    const line = (w: number, ...p: number[]) => inkLine(g, w, ...p);
    for (const [x, s] of [[92, -1], [164, 1]]) {         // s = +1 his left (screen right), -1 his right
      if (e === 0) {                                     // the old man's narrow eye under the brow: a heavy lid line
        line(6, x - 26 * s, 126, x, 131, x + 22 * s, 124);
        g.beginPath(); g.ellipse(x - 2 * s, 129, 9, 5, 0, 0, 7); g.fill();
      }
      if (e === 1) {                                     // the open eye: a white block, a 14 px pupil, the lid over it
        g.fillStyle = '#fff'; g.beginPath(); g.moveTo(x - 26 * s, 126); g.lineTo(x + 22 * s, 118); g.lineTo(x + 20 * s, 134);
        g.lineTo(x - 22 * s, 136); g.closePath(); g.fill();
        g.fillStyle = '#1a1414'; g.beginPath(); g.arc(x - 1 * s, 127, 7, 0, 7); g.fill();
        line(6, x - 28 * s, 126, x + 24 * s, 116);
      }
      if (e === 2) line(7, x - 26 * s, 120, x, 132, x + 22 * s, 124);      // screwed shut
    }
    // the brow wedges under the hair brows (shout / hurt: knitted down hard)
    if (e > 0) for (const [x0, s] of [[64, 1], [192, -1]]) {
      g.beginPath(); g.moveTo(x0, 100); g.lineTo(x0 + 52 * s, 114); g.lineTo(x0 + 50 * s, 104); g.closePath(); g.fill();
    }
    g.strokeStyle = '#8a4a3a';                                                   // the X scar on the brow
    line(5, 108, 34, 148, 74); line(5, 148, 34, 108, 74);
    g.strokeStyle = '#1a1414';
    // the mouth under the moustache: a 48 px shout, a grimace when hurt
    if (e === 1) { g.fillStyle = '#3a1214'; g.beginPath(); g.ellipse(128, 200, 26, 20, 0, 0, 7); g.fill();
      g.fillStyle = '#f4f0e8'; g.fillRect(106, 183, 44, 7); }
    if (e === 2) line(7, 100, 204, 114, 194, 128, 202, 142, 194, 156, 204);
  },
  weapon: cane(PAL.blade, PAL.edge),
  variant: (form) => {
    if (form !== 'bankai-east' && form !== 'bankai-west') return null;
    return {
      spec: { haori: false, bareR: true },
      parts: (sp, r) => { const ps = kimono(sp, r, (add, hc) => head(sp, r, add, hc)); scars(sp, r, adder(sp, ps)); return ps; },
      weapon: form === 'bankai-east' ? cane(CHAR, EMBER) : cane(CHARCOAL, CHARCOAL),
    };
  },
};
