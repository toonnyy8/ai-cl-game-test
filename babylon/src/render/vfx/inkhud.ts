// inkhud.ts: the HUD's ink primitives (hud.ts keeps the layout): brush bars (a dry-brush stroke cropped to the fill, an
// ink wash behind), ink dots (Konpaku, cups, pips), claw-slash pips (Kenpachi's arm), a swash behind big words, and the
// calligraphy cards of the cinematics (vfx/card.ts). Each shape is painted once in white on an offscreen canvas, then
// tinted per colour with 'source-in' and cached: a frame only blits.
import { arc, blob, INK, rnd, stroke, WHITE, type G } from './brush';

const BW = 512, BH = 40;
const cache = new Map<string, HTMLCanvasElement>();
function canvas(w: number, h: number): [HTMLCanvasElement, G] {
  const c = document.createElement('canvas'); c.width = w; c.height = h;
  return [c, c.getContext('2d')!];
}
/** Shape KEY painted white by PAINT, tinted COL (cached). */
function shape(key: string, w: number, h: number, col: string, paint: (g: G) => void): HTMLCanvasElement {
  const k = `${key}|${col}`;
  let c = cache.get(k);
  if (c) return c;
  const base = cache.get(`${key}|`) ?? (() => { const [b, g] = canvas(w, h); paint(g); cache.set(`${key}|`, b); return b; })();
  if (!col) return base;
  const [t, g] = canvas(w, h);
  g.drawImage(base, 0, 0); g.globalCompositeOperation = 'source-in'; g.fillStyle = col; g.fillRect(0, 0, w, h);
  cache.set(k, t);
  return t;
}
const barShape = (col: string) => shape('bar', BW, BH, col, (g) => {
  for (let k = 0; k < 3; k++) stroke(g, [[6, BH / 2 + (k - 1) * 2], [BW * 0.5, BH / 2 + (k - 1)], [BW - 4, BH / 2]], BH * (0.95 - 0.15 * k), WHITE, 0.25);
  g.fillStyle = WHITE; g.fillRect(BW * 0.03, BH * 0.22, BW * 0.95, BH * 0.56);       // a solid core: the fraction reads exactly
});
const washShape = () => shape('wash', BW, BH, INK, (g) => {
  for (let k = 0; k < 2; k++) stroke(g, [[2, BH / 2], [BW * 0.5, BH / 2 + k * 2], [BW - 2, BH / 2]], BH * 1.0, WHITE, 0.5);
});
const dotShape = (col: string) => shape('dot', 64, 64, col, (g) => blob(g, 32, 32, 26, WHITE));
const ringShape = (col: string) => shape('ring', 64, 64, col, (g) => stroke(g, arc(32, 32, 22, -1.2, 4.6, 14, 0.04), 9, WHITE, 0.4));
const slashShape = (col: string) => shape('slash', 64, 64, col, (g) => {
  for (let k = 0; k < 3; k++) stroke(g, [[10 + k * 14, 6], [26 + k * 14, 58]], 11, WHITE, 0.35);
});
const swashShape = (col: string) => shape('swash', 512, 192, col, (g) => {
  stroke(g, [[10, 104], [180, 90], [360, 94], [500, 84]], 92, WHITE, 0.55);
  for (let k = 0; k < 10; k++) blob(g, 30 + rnd() * 450, 40 + rnd() * 110, 2 + 4 * rnd(), WHITE);
});

/** A brush bar W x H at (X Y) filled FRAC from its outer edge (RIGHT: from the right) in COL; BACK: the ink wash. */
export function brushBar(g: G, x: number, y: number, w: number, h: number, frac: number, right: boolean, col: string,
                         back = true, alpha = 1): void {
  if (back) {                                                         // the wash's heavy end at the bar's outer edge
    g.save(); g.globalAlpha = 0.72;
    if (right) { g.translate(2 * x + w, 0); g.scale(-1, 1); }
    g.drawImage(washShape(), x - h * 0.35, y - h * 0.3, w + h * 0.7, h * 1.6); g.restore();
  }
  const f = Math.max(0, Math.min(1, frac));
  if (f > 0) {
    g.globalAlpha = alpha;
    const sw = f * BW;
    if (right) g.drawImage(barShape(col), BW - sw, 0, sw, BH, x + w - f * w, y, f * w, h);
    else g.drawImage(barShape(col), 0, 0, sw, BH, x, y, f * w, h);
  }
  g.globalAlpha = 1;
}
/** An ink dot of radius R at (CX CY): COL lit, or null = an empty ink ring. */
export function inkDot(g: G, cx: number, cy: number, r: number, col: string | null, alpha = 1): void {
  g.globalAlpha = alpha;
  if (col) { g.drawImage(dotShape(INK), cx - r * 1.25, cy - r * 1.15, r * 2.5, r * 2.5); g.drawImage(dotShape(col), cx - r, cy - r, 2 * r, 2 * r); }
  else g.drawImage(ringShape('rgba(20,17,15,0.9)'), cx - r, cy - r, 2 * r, 2 * r);
  g.globalAlpha = 1;
}
/** A claw-slash pip S px square at (X Y): blood when LIT, else ink with a white crack. */
export function slashPip(g: G, x: number, y: number, s: number, lit: boolean, alpha = 1): void {
  g.globalAlpha = alpha;
  g.drawImage(slashShape(lit ? '#c8102e' : INK), x, y, s, s);
  if (!lit) { g.strokeStyle = 'rgba(255,255,255,0.8)'; g.lineWidth = Math.max(1, s / 16); g.beginPath(); g.moveTo(x + s * 0.2, y + s * 0.55); g.lineTo(x + s * 0.8, y + s * 0.4); g.stroke(); }
  g.globalAlpha = 1;
}
/** A brush swash W x H centred at (CX CY) in COL (behind a big word). */
export function swash(g: G, cx: number, cy: number, w: number, h: number, col: string, alpha = 1): void {
  g.globalAlpha = alpha; g.drawImage(swashShape(col), cx - w / 2, cy - h * 0.75, w, h * 1.5); g.globalAlpha = 1;
}
/** A hanko seal: a red square of side S at (X Y) with a white mark. */
export function hanko(g: G, x: number, y: number, s: number): void {
  g.fillStyle = '#c8241c'; g.fillRect(x, y, s, s);
  g.strokeStyle = WHITE; g.lineWidth = s * 0.09; g.strokeRect(x + s * 0.16, y + s * 0.16, s * 0.68, s * 0.68);
  g.beginPath(); g.moveTo(x + s * 0.5, y + s * 0.22); g.lineTo(x + s * 0.5, y + s * 0.78); g.moveTo(x + s * 0.24, y + s * 0.5); g.lineTo(x + s * 0.76, y + s * 0.5); g.stroke();
}
export { washShape };
