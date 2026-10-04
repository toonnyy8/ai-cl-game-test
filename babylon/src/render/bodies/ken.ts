// Zaraki Kenpachi: spiky hair with a bell on every tip, the open collar, torn haori sleeves and a tattered hem, the
// long scar over his left eye; a long notched katana with a small dark guard.
import { Vector3 } from '@babylonjs/core';
import { ellipsoid, inkLine, katana, kimono, limb, type CharBody } from '../body';

export const ken: CharBody = {
  spec: { height: 2.0, heads: 8, shoulder: 1.18, chest: [0.86, 0.52], waist: [0.62, 0.44], hip: [0.66, 0.46], limb: 1.2,
    hand: 1.2, skin: 0xdcae86, black: 0x22232c, haori: 0xeeece4, obi: 0xe0ddd2, hair: 0x1b1c24, collar: 1.25,
    haoriHem: 1.6, haoriSleeves: 'torn', tattered: true },
  parts: (sp, r) => kimono(sp, r, (add, hc) => {
    const H = r.H;
    // the cap of hair, then spikes radiating out from the crown and the back of the head in rows, a bell on every tip
    add(ellipsoid([0, hc[1] + 0.06 * H, hc[2] + 0.03 * H], [0.39 * H, 0.47 * H, 0.44 * H], 16, 10), sp.hair, ['head']);
    let i = 0;
    for (const [el, nAz, len0] of [[0.75, 7, 0.95], [0.25, 9, 1.15], [-0.15, 6, 1.0]] as const)
      for (let j = 0; j < nAz; j++, i++) {
        const az = (-0.85 + (1.7 * (j + 0.5)) / nAz) * Math.PI * (el > 0.5 ? 0.85 : el > 0 ? 0.8 : 0.6);   // 0 = straight back (+z)
        const d = new Vector3(Math.sin(az) * Math.cos(el), Math.sin(el), Math.cos(az) * Math.cos(el)).normalize();
        const base = new Vector3(hc[0] + d.x * 0.25 * H, hc[1] + 0.12 * H + d.y * 0.25 * H, hc[2] + d.z * 0.25 * H);
        const tip = base.add(d.scale((len0 + 0.25 * Math.sin(i * 2.3)) * H));
        add(limb(base, tip, 0.14 * H, 0.012, 6), sp.hair, ['head']);
        add(ellipsoid([tip.x, tip.y - 0.04 * H, tip.z], [0.08 * H, 0.08 * H, 0.08 * H], 7, 5), 0xe7c24e, ['head']);
      }
    // forelock strands over the brow
    for (const s of [-1, 0, 1]) add(limb(new Vector3(s * 0.15 * H, hc[1] + 0.4 * H, hc[2] - 0.36 * H),
      new Vector3(s * 0.25 * H, hc[1] + 0.12 * H, hc[2] - 0.47 * H), 0.07 * H, 0.01, 5), sp.hair, ['head']);
  }),
  drawFace: (g, e) => {
    const line = (w: number, ...p: number[]) => inkLine(g, w, ...p);
    for (const [x, s] of [[92, -1], [164, 1]]) {         // s = +1 his left (screen right), -1 his right
      if (e === 2) { line(6, x - 24 * s, 116, x + 20 * s, 128); line(6, x - 24 * s, 132, x + 20 * s, 126); continue; }
      g.fillStyle = '#fff'; g.beginPath(); g.moveTo(x - 26 * s, 128); g.quadraticCurveTo(x, 110, x + 24 * s, 120); g.quadraticCurveTo(x, 136, x - 26 * s, 128); g.fill();
      g.fillStyle = '#1a1414'; g.beginPath(); g.arc(x - 3 * s, 124, e === 1 ? 6 : 10, 0, 7); g.fill();
      line(5, x - 28 * s, 128, x, 112, x + 26 * s, 118);
    }
    const k = e === 1 ? 14 : e === 2 ? -6 : 8;                                   // the brows angle down hard
    line(8, 62, 96, 112, 104 + k); line(8, 194, 96, 144, 104 + k);
    g.strokeStyle = '#8a4a3a';                                                   // the long cut over his left eye (screen right)
    line(5, 178, 60, 160, 190); line(3, 150, 70, 136, 200);
    g.strokeStyle = '#1a1414';
    if (e === 0) line(5, 100, 196, 128, 200, 160, 190);
    if (e === 1) { g.fillStyle = '#3a1214'; g.beginPath(); g.ellipse(128, 196, 34, 22, 0, 0, 7); g.fill();
      g.fillStyle = '#f4f0e8'; g.fillRect(100, 180, 56, 7); g.fillRect(104, 207, 48, 5); }
    if (e === 2) line(6, 96, 204, 112, 194, 128, 202, 144, 194, 160, 204);
  },
  weapon: (scene) => katana(scene, { blade: 1.3, grip: 0.3, w: 0.036, bladeC: 0xb8bcc6, gripC: 0x2b2b38, chips: true, guard: 0x3a3426 }),
  variant: () => null,
};
