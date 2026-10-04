// brush.ts: the shared brush kit of the ink VFX and the ink HUD (docs/BABYLON_LOOK.md B4). Textures are painted on canvases
// (no image assets) as BLACK INK + a WHITE "colour channel": a material or a particle multiplies the white by its tint,
// the ink stays ink. Sheets hold N cells side by side; animation is stepped (a drawn look): every sheet shows cell
// floor(t * 12) mod N, one global clock. Brush type is the Lisp's: glyphs.ts (Yuji Syuku outlines) filled on a canvas.
import { Color3, DynamicTexture, StandardMaterial, Texture, type Scene } from '@babylonjs/core';
import { rnd, stroke } from '../ink';
import { GLYPHS } from './glyphs';

export { rnd, stroke };
export type Pt = [number, number];
export type G = CanvasRenderingContext2D;
export const INK = '#14110f', WHITE = '#ffffff';
export const FPS = 12;
export const hex3 = (h: number) => new Color3(((h >> 16) & 255) / 255, ((h >> 8) & 255) / 255, (h & 255) / 255);
export const css = (h: number, a = 1) => `rgba(${(h >> 16) & 255},${(h >> 8) & 255},${h & 255},${a})`;

/** A sheet of N cells of CW x CH px side by side, cell I painted by PAINT in its own clipped frame. */
export function paintSheet(scene: Scene, name: string, n: number, cw: number, ch: number,
                           paint: (g: G, i: number, w: number, h: number) => void): DynamicTexture {
  const t = new DynamicTexture(name, { width: n * cw, height: ch }, scene, true);
  const g = t.getContext() as G;
  g.clearRect(0, 0, n * cw, ch);
  for (let i = 0; i < n; i++) {
    g.save(); g.translate(i * cw, 0); g.beginPath(); g.rect(0, 0, cw, ch); g.clip();
    paint(g, i, cw, ch);
    g.restore();
  }
  t.update(); t.hasAlpha = true;
  t.wrapU = t.wrapV = Texture.CLAMP_ADDRESSMODE;
  return t;
}
/** An unlit, alpha-blended, two-sided material on sheet T, its white tinted TINT (unlit: the emissive is the colour). */
export function inkMat(scene: Scene, name: string, t: Texture, tint: Color3): StandardMaterial {
  const m = new StandardMaterial(name, scene);
  m.diffuseTexture = t; m.useAlphaFromDiffuseTexture = true; m.disableLighting = true;
  m.diffuseColor = Color3.Black(); m.emissiveColor = tint; m.specularColor = Color3.Black();
  m.backFaceCulling = false; m.disableDepthWrite = true;
  return m;
}

/** A filled brush blob (a dot / a seal) of radius R at (X Y): a ragged disc. */
export function blob(g: G, x: number, y: number, r: number, col: string): void {
  g.fillStyle = col; g.beginPath();
  for (let i = 0; i <= 18; i++) {
    const a = (i / 18) * 2 * Math.PI, k = r * (0.86 + 0.22 * rnd());
    if (i === 0) g.moveTo(x + k, y); else g.lineTo(x + Math.cos(a) * k, y + Math.sin(a) * k);
  }
  g.fill();
}
/** Points of an arc of radius R round (CX CY) from A0 to A1 (radians), N + 1 of them, wobbling by WOB. */
export function arc(cx: number, cy: number, r: number, a0: number, a1: number, n = 16, wob = 0.03): Pt[] {
  const p: Pt[] = [];
  for (let i = 0; i <= n; i++) {
    const a = a0 + ((a1 - a0) * i) / n, k = r * (1 + wob * (rnd() - 0.5) * 2);
    p.push([cx + Math.cos(a) * k, cy + Math.sin(a) * k]);
  }
  return p;
}

// ---------------------------------------------------------------- brush type (the Lisp's glyph outlines)
export const hasGlyphs = (s: string): boolean => [...s].every((c) => c === ' ' || c in GLYPHS);
/** Advance of S at PX px per em (spaces 0.32 em; a char with no glyph: the canvas font's). */
export function brushWidth(g: G, s: string, px: number): number {
  let w = 0;
  for (const c of s) {
    const gl = GLYPHS[c];
    if (gl) w += (gl[0] / 1000) * px * 0.92;
    else if (c === ' ') w += 0.32 * px;
    else { g.font = `900 ${Math.round(px * 0.92)}px Georgia, "Times New Roman", serif`; w += g.measureText(c).width; }
  }
  return w;
}
/** S in brush type, PX px per em, top-left at (X Y) after ALIGN; VERTICAL: one char under the other (kanji columns).
 *  Glyphs fill FILL; a missing char (digits) falls back to a heavy serif. Returns the advance drawn. */
export function brushText(g: G, s: string, x: number, y: number, px: number, fill: string,
                          align: 'left' | 'center' | 'right' = 'left', vertical = false): number {
  const w = vertical ? px * [...s].length * 0.98 : brushWidth(g, s, px);
  let pen = vertical ? y : align === 'center' ? x - w / 2 : align === 'right' ? x - w : x;
  g.fillStyle = fill;
  for (const c of s) {
    const gl = GLYPHS[c], gx = vertical ? x - px / 2 : pen, gy = vertical ? pen : y;
    if (gl) {
      g.save(); g.translate(gx, gy); g.scale(px / 1000, px / 1000); g.beginPath();
      for (const poly of gl[1]) {
        g.moveTo(poly[0], poly[1]);
        for (let i = 2; i < poly.length; i += 2) g.lineTo(poly[i], poly[i + 1]);
        g.closePath();
      }
      g.fill(); g.restore();
      pen += vertical ? px * 0.98 : (gl[0] / 1000) * px * 0.92;
    } else if (c === ' ') pen += vertical ? px * 0.5 : 0.32 * px;
    else {
      g.font = `900 ${Math.round(px * 0.92)}px Georgia, "Times New Roman", serif`; g.textBaseline = 'top'; g.textAlign = 'left';
      g.fillText(c, gx, gy + px * 0.06);
      pen += vertical ? px : g.measureText(c).width;
    }
  }
  return w;
}
/** Brush type with an ink under-stroke (offset, a little bigger): reads on the sky and on a white card. */
export function inkText(g: G, s: string, x: number, y: number, px: number, fill: string,
                        align: 'left' | 'center' | 'right' = 'left', alpha = 1): number {
  g.globalAlpha = alpha;
  const o = Math.max(1, px / 10);
  brushText(g, s, x + o, y + o, px, 'rgba(10,8,8,0.85)', align);
  const w = brushText(g, s, x, y, px, fill, align);
  g.globalAlpha = 1;
  return w;
}
