// ink.ts: ink-brush effects (the user, 2026-10-04: effects in ink brush, brush strokes, few colours). The brush
// textures are painted procedurally on canvases (no image assets): each stroke is a bundle of bristles along a path,
// thinning to a dry-brush tail (kasure) where bristles break off. Sparks are camera-facing quads that pop out fast and
// fade on real time: hit = a black splat with a vermilion flick, block = thin slate strokes, Kikon / Soul Break = an
// enso ring with a red seal.
import { Color3, DynamicTexture, Mesh, MeshBuilder, StandardMaterial, type Scene } from '@babylonjs/core';

type Pt = [number, number];
let seed = 7;
const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);

/** One brush stroke through PTS (canvas px) of max width W, colour COL; DRY (0..1) = how early the bristles break. */
function stroke(g: CanvasRenderingContext2D, pts: Pt[], w: number, col: string, dry = 0.5): void {
  const n = Math.max(6, Math.round(w / 1.6)), seg = 40;
  const at = (t: number): [number, number, number, number] => {      // position and tangent along the polyline
    const f = t * (pts.length - 1), i = Math.min(pts.length - 2, Math.floor(f)), u = f - i;
    const [x0, y0] = pts[i], [x1, y1] = pts[i + 1];
    return [x0 + (x1 - x0) * u, y0 + (y1 - y0) * u, x1 - x0, y1 - y0];
  };
  g.strokeStyle = col; g.lineCap = 'round';
  for (let b = 0; b < n; b++) {
    const o = (b / (n - 1)) * 2 - 1, lw = (w / n) * (1.4 + rnd()), breakAt = 1 - dry * (0.2 + 0.8 * rnd()) * Math.abs(o) - 0.15 * dry * rnd();
    g.lineWidth = lw; g.globalAlpha = 0.75 + 0.25 * rnd();
    g.beginPath();
    let pen = false;
    for (let s = 0; s <= seg; s++) {
      const t = s / seg;
      if (t > breakAt || (t > 0.5 && rnd() < dry * 0.12)) { pen = false; continue; }
      const [x, y, tx, ty] = at(t), l = Math.hypot(tx, ty) || 1;
      const width = w * Math.sin(Math.PI * Math.min(1, 0.15 + t * 0.95)) * (1 - 0.6 * t);   // press in, lift off
      const px = x - (ty / l) * o * width * 0.5, py = y + (tx / l) * o * width * 0.5;
      if (pen) g.lineTo(px, py); else { g.moveTo(px, py); pen = true; }
    }
    g.stroke();
  }
  g.globalAlpha = 1;
}
function tex(scene: Scene, name: string, size: number, paint: (g: CanvasRenderingContext2D, s: number) => void): StandardMaterial {
  const t = new DynamicTexture(name, size, scene, true), g = t.getContext() as CanvasRenderingContext2D;
  g.clearRect(0, 0, size, size);
  paint(g, size);
  t.update(); t.hasAlpha = true;
  const m = new StandardMaterial(name, scene);
  m.diffuseTexture = t; m.useAlphaFromDiffuseTexture = true; m.disableLighting = true; m.emissiveColor = Color3.White();
  m.backFaceCulling = false; m.disableDepthWrite = true;
  return m;
}
const INK = '#14110f', RED = '#d42a1c', SLATE = '#3b4a66';

/** The brush sprite set (VARIANTS rotations of each, baked at random angles). */
export function inkMaterials(scene: Scene) {
  const variants = 3;
  const splat = Array.from({ length: variants }, (_, v) => tex(scene, `ink-splat${v}`, 256, (g, s) => {
    const c = s / 2, a0 = rnd() * 6.28;
    for (let i = 0; i < 7; i++) {
      const a = a0 + (i / 7) * 6.28 + (rnd() - 0.5) * 0.5, r0 = s * 0.06, r1 = s * (0.28 + 0.18 * rnd()), bend = (rnd() - 0.5) * 0.5;
      stroke(g, [[c + Math.cos(a) * r0, c + Math.sin(a) * r0], [c + Math.cos(a + bend) * (r0 + r1) * 0.55, c + Math.sin(a + bend) * (r0 + r1) * 0.55],
        [c + Math.cos(a + bend * 1.5) * r1, c + Math.sin(a + bend * 1.5) * r1]], s * (0.05 + 0.04 * rnd()), INK, 0.7);
    }
    const a = a0 + 0.4;   // the vermilion flick across it
    stroke(g, [[c - Math.cos(a) * s * 0.36, c - Math.sin(a) * s * 0.36], [c, c + s * 0.04], [c + Math.cos(a) * s * 0.4, c + Math.sin(a) * s * 0.4]], s * 0.07, RED, 0.6);
    g.fillStyle = INK;
    for (let i = 0; i < 9; i++) { const r = s * (0.3 + 0.15 * rnd()), b = rnd() * 6.28; g.beginPath(); g.arc(c + Math.cos(b) * r, c + Math.sin(b) * r, 1.5 + rnd() * 4, 0, 7); g.fill(); }
  }));
  const block = Array.from({ length: variants }, (_, v) => tex(scene, `ink-block${v}`, 256, (g, s) => {
    const c = s / 2, a0 = rnd() * 6.28;
    for (let i = 0; i < 4; i++) {
      const a = a0 + (rnd() - 0.5) * 0.9, l = s * (0.22 + 0.15 * rnd()), off = (i - 1.5) * s * 0.06;
      const nx = -Math.sin(a) * off, ny = Math.cos(a) * off;
      stroke(g, [[c + nx - Math.cos(a) * l, c + ny - Math.sin(a) * l], [c + nx + Math.cos(a) * l, c + ny + Math.sin(a) * l]], s * 0.03, SLATE, 0.8);
    }
  }));
  const enso = tex(scene, 'ink-enso', 512, (g, s) => {
    const c = s / 2, r = s * 0.36, pts: Pt[] = [];
    for (let i = 0; i <= 24; i++) { const a = -1.2 + (i / 24) * 5.7; pts.push([c + Math.cos(a) * r * (1 + 0.04 * Math.sin(i)), c + Math.sin(a) * r]); }
    stroke(g, pts, s * 0.09, INK, 0.65);
    g.fillStyle = RED; g.fillRect(c + r * 0.5, c + r * 0.55, s * 0.08, s * 0.08);
  });
  return { splat, block, enso };
}
export type InkMats = ReturnType<typeof inkMaterials>;

interface Spark { m: Mesh; life: number; max: number; size: number }
export class InkSparks {
  sparks: Spark[] = [];
  constructor(readonly scene: Scene, readonly mats: InkMats) {}
  add(kind: 'hit' | 'block' | 'kikon', x: number, y: number, z: number, size: number, life = 0.3): void {
    const m = MeshBuilder.CreatePlane('ink', { size: 1 }, this.scene);
    const set = kind === 'hit' ? this.mats.splat : kind === 'block' ? this.mats.block : [this.mats.enso];
    m.material = set[Math.floor(rnd() * set.length)];
    m.billboardMode = Mesh.BILLBOARDMODE_ALL; m.position.set(x, y, z); m.renderingGroupId = 1;
    m.isPickable = false;
    this.sparks.push({ m, life, max: life, size });
    this.step(0);
  }
  step(rdt: number): void {
    this.sparks = this.sparks.filter((s) => {
      s.life -= rdt;
      if (s.life <= 0) { s.m.dispose(); return false; }
      const k = 1 - s.life / s.max, pop = 1 - (1 - Math.min(1, k / 0.3)) ** 3;
      s.m.scaling.setAll(s.size * (0.45 + 0.65 * pop));
      s.m.visibility = k < 0.5 ? 1 : 1 - (k - 0.5) / 0.5;
      return true;
    });
  }
  dispose(): void { for (const s of this.sparks) s.m.dispose(); this.sparks = []; }
}
