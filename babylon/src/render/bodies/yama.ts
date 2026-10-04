// Yamamoto Genryusai: bald, the long white beard and drooping brows, the old man's slit eyes and the cross scar,
// Ryujin Jakka with a wooden cane hilt.
import { Vector3 } from '@babylonjs/core';
import { inkLine, katana, kimono, limb, tube, type CharBody } from '../body';

export const yama: CharBody = {
  spec: { height: 1.65, heads: 7.5, shoulder: 0.95, chest: [0.66, 0.42], waist: [0.52, 0.38], hip: [0.6, 0.4], limb: 0.9,
    hand: 1.25, skin: 0xe6c3a0, black: 0x24252e, haori: 0xf1efe8, obi: 0xe4e1d8, hair: 0xf2f0ea, collar: 0.7,
    haoriHem: 1.2, haoriSleeves: 'long', tattered: false },
  parts: (sp, r) => kimono(sp, r, (add, hc) => {
    // the long white beard from the jaw to the obi (upper half rides the head, the rest the chest), a moustache
    const H = r.H, y = (v: number) => v * r.bs, cz = sp.chest[1], wz = sp.waist[1], bz = hc[2] - 0.3 * H;
    add(tube([[hc[1] - 0.12 * H, 0.3 * H, 0.12 * H, 0, bz + 0.06 * H], [hc[1] - 0.42 * H, 0.3 * H, 0.18 * H, 0, bz - 0.05 * H],
      [hc[1] - 0.9 * H, 0.27 * H, 0.17 * H, 0, -cz * H - 0.12 * H], [y(5.6), 0.2 * H, 0.14 * H, 0, -cz * H - 0.12 * H],
      [y(5.0), 0.12 * H, 0.1 * H, 0, -wz * H - 0.12 * H], [y(4.75), 0.03 * H, 0.03 * H, 0, -wz * H - 0.1 * H]], 12),
      sp.hair, ['head', 'neck', 'chest']);
    for (const s of [1, -1]) add(limb(new Vector3(s * 0.04 * H, hc[1] - 0.12 * H, hc[2] - 0.42 * H),
      new Vector3(s * 0.36 * H, hc[1] - 0.42 * H, hc[2] - 0.3 * H), 0.06 * H, 0.015, 6), sp.hair, ['head']);
    // the long drooping eyebrows
    for (const s of [1, -1]) add(limb(new Vector3(s * 0.1 * H, hc[1] + 0.12 * H, hc[2] - 0.41 * H),
      new Vector3(s * 0.44 * H, hc[1] - 0.12 * H, hc[2] - 0.3 * H), 0.045 * H, 0.012, 6), sp.hair, ['head']);
  }),
  drawFace: (g, e) => {
    const line = (w: number, ...p: number[]) => inkLine(g, w, ...p);
    for (const [x, s] of [[92, -1], [164, 1]]) {         // s = +1 his left (screen right), -1 his right
      if (e === 0) line(5, x - 22 * s, 122, x, 126, x + 20 * s, 120);                 // the old man's narrow slit
      if (e === 1) { g.fillStyle = '#fff'; g.beginPath(); g.ellipse(x, 124, 20, 9, 0, 0, 7); g.fill(); g.fillStyle = '#1a1414';
        g.beginPath(); g.arc(x - 2 * s, 124, 8, 0, 7); g.fill(); line(5, x - 24 * s, 116, x + 22 * s, 120); }
      if (e === 2) line(6, x - 22 * s, 118, x, 128, x + 20 * s, 122);
    }
    if (e > 0) { line(5, 70, 104, 110, 112); line(5, 186, 104, 146, 112); }    // brows (the long ones are geometry)
    g.strokeStyle = '#8a4a3a';                                                   // the cross scar on the brow
    line(4, 110, 40, 146, 76); line(4, 146, 40, 110, 76); line(3, 120, 30, 136, 30);
    g.strokeStyle = '#1a1414';
    // the mouth sits under the moustache; drawn for shout / hurt
    if (e === 1) { g.fillStyle = '#3a1214'; g.beginPath(); g.ellipse(128, 196, 24, 18, 0, 0, 7); g.fill();
      g.fillStyle = '#f4f0e8'; g.fillRect(100, 180, 56, 7); g.fillRect(104, 207, 48, 5); }
    if (e === 2) line(6, 96, 204, 112, 194, 128, 202, 144, 194, 160, 204);
  },
  weapon: (scene) => katana(scene, { blade: 0.86, grip: 0.24, w: 0.03, bladeC: 0xd0d4de, gripC: 0x6b4a2e }),
  variant: () => null,
};
