// card.ts: the calligraphy cards of the cinematics (Kikon, Soul Break, the awakenings, K.O. / TIME): the Lisp's captions
// (duel/lisp cinema / yama / ken / rukia / ichigo-art / senjumaru `caption` calls): a vertical kanji column in brush
// type on an ink wash, a smaller second column, a red hanko, the romaji reading and a sub line. Only the kanji the
// baked glyph subset has are drawn (卍解, 野晒, ... see tools/glyphs-gen.mjs); a caption whose kanji are missing shows its
// reading alone, big, on a red swash. Stamped in on twos (scale 1.8 -> 1.15 -> 1), out by fading over its last frames.
import { brushText, brushWidth, hasGlyphs, inkText, type G } from './brush';
import { hanko, swash, washShape } from './inkhud';

export interface Cap { kanji: string; reading: string; sub?: string; kanji2?: string; hanko?: boolean }
const c = (kanji: string, reading: string, sub?: string, kanji2?: string, hk?: boolean): Cap => ({ kanji, reading, sub, kanji2, hanko: hk });
export const CAPS: Record<string, Cap> = {
  'soul-break-cine': c('魂', 'SOUL BREAK'),
  'yama-kikon-cine': c('城郭炎上', 'JOKAKU ENJO', 'KIKON', undefined, true),
  'yama-tenchi-cine': c('天地灰尽', 'TENCHI KAIJIN', 'ZANKA NO TACHI', '北', true),
  'yama-bankai-cine': c('卍解', 'BANKAI', 'ZANKA NO TACHI', '残火の太刀'),
  'ken-kikon-cine': c('呑め、野晒', 'NOME, NOZARASHI', 'MOTTO TANOSHIMASETE KURE YO!', undefined, true),
  'ken-sky-split-cine': c('呑め、野晒', 'NOME, NOZARASHI', 'SKY SPLIT', undefined, true),
  'ken-nozarashi-cine': c('野晒', 'NOME, NOZARASHI', undefined, '呑め、'),
  'ken-bankai-cine': c('卍解', 'BANKAI', undefined, undefined, true),
  'ken-oni-kikon-cine': c('卍解', 'BANKAI', 'MAPPUTATSU', undefined, true),
  'ru-kikon-cine': c('月白', 'SOME NO MAI', 'TSUKISHIRO  KIKON', '初の舞', true),
  'ru-hakka-cine': c('卍解', 'BANKAI', 'HAKKA NO TOGAME', '白霞罸', true),
  'ru-awaken-cine': c('絶対零度', 'ZETTAI REIDO', 'SODE NO SHIRAYUKI'),
  'ic-kikon-cine': c('月牙天衝', 'GETSUGA TENSHO', 'GRAN REY CERO  KIKON', undefined, true),
  'ic-kessa-kikon-cine': c('千影', "SEN'EI", 'KESSA NO ICHIGO  KIKON', undefined, true),
  'ic-kessa-getsuga-cine': c('月牙天衝', 'GETSUGA TENSHO', 'KESSA NO ICHIGO  SOUL BREAK', undefined, true),
  'ic-kessa-cine': c('血鎖の一護', 'KESSA NO ICHIGO', 'TENSA ZANGETSU'),
  'sj-kikon-cine': c('仕立て直し', 'SHITATE-NAOSHI', 'WARUI KUSE  KIKON', undefined, true),
  'sj-hata-cine': c('卍解', 'BANKAI', 'SHIDE NO ROKUSHIKI UKIMON NO HATA  KIKON', undefined, true),
  'sj-tsuji-cine': c('卍解', 'BANKAI', 'SHATATSU KARAGARA SHIGARAMI NO TSUJI'),
  'ko-cine': c('決着', 'K.O.'),
  'time-cine': c('時間切れ', 'TIME'),
};

const PAPER = '#f4efe2', GOLD = '#ffe0a0';
/** A vertical ink wash of thickness T centred on X, from Y0 down to Y1. */
function vwash(g: G, x: number, y0: number, y1: number, t: number, alpha: number): void {
  g.save(); g.globalAlpha = alpha; g.translate(x + t / 2, y0); g.rotate(Math.PI / 2);
  g.drawImage(washShape(), 0, 0, y1 - y0, t); g.restore(); g.globalAlpha = 1;
}

/** CAP drawn on G (W x H) at sim frame CF of a cine of LEN frames; SIDE 0: the column on the right, 1: on the left; WIN:
 *  the frames [in, out] it is up (default 6 % .. 82 % of LEN; render/cinema.ts passes the script's). */
export function drawCard(g: G, cap: Cap, cf: number, len: number, w: number, h: number, side: number, win?: [number, number]): void {
  const [f0, f1] = win ?? [Math.round(0.06 * len), Math.round(0.82 * len)];
  if (cf < f0 || cf > f1) return;
  const step = Math.floor((cf - f0) / 5), scale = step === 0 ? 1.8 : step === 1 ? 1.15 : 1;   // on twos at 12 fps
  const alpha = Math.min(1, (f1 - cf) / 12);
  const kanji = hasGlyphs(cap.kanji) ? cap.kanji : '', portrait = h > w;
  g.save();
  if (kanji) {
    const n = [...kanji].length, cx = (side === 0 ? (portrait ? 0.8 : 0.76) : portrait ? 0.2 : 0.24) * w;
    let px = Math.min((portrait ? 0.075 : 0.13) * h, 0.22 * w);
    px = Math.min(px, (0.58 * h) / n);
    const y0 = (portrait ? 0.22 : 0.12) * h;
    g.translate(cx, y0); g.scale(scale, scale); g.translate(-cx, -y0);
    g.globalAlpha = alpha;
    vwash(g, cx, y0 - px * 0.35, y0 + n * px * 0.98 + px * 0.3, px * 1.7, 0.85 * alpha);
    g.globalAlpha = alpha;
    brushText(g, kanji, cx, y0, px, PAPER, 'left', true);
    let below = y0 + n * px * 0.98;
    if (cap.kanji2 && hasGlyphs(cap.kanji2)) {                          // the second column, inward
      const k2 = px * 0.5, x2 = cx + (side === 0 ? -1 : 1) * px * 1.15;
      vwash(g, x2, y0 + px * 0.2, y0 + px * 0.2 + [...cap.kanji2].length * k2 + k2 * 0.4, k2 * 1.6, 0.8 * alpha);
      g.globalAlpha = alpha;
      brushText(g, cap.kanji2, x2, y0 + px * 0.4, k2, PAPER, 'left', true);
    }
    if (cap.hanko) { hanko(g, cx - px * 0.22, below + px * 0.05, px * 0.44); below += px * 0.5; }
    const line = (str: string, y: number, size: number, col: string) => {          // under the column, kept on screen
      const k = Math.min(1, (0.92 * w) / brushWidth(g, str, size)), tw = brushWidth(g, str, size * k);
      inkText(g, str, Math.max(tw / 2 + 0.04 * w, Math.min(w - tw / 2 - 0.04 * w, cx)), y, size * k, col, 'center', alpha);
    };
    line(cap.reading, below + px * 0.15, px * 0.42, GOLD);
    if (cap.sub) line(cap.sub, below + px * 0.62, px * 0.22, PAPER);
  } else {                                                               // the reading alone, big, on a red swash
    // (fitted to the caption's half of the frame, on its SIDE: a long name never runs off the screen or over the subject)
    const cx = portrait ? w / 2 : (side === 0 ? 0.7 : 0.3) * w, room = (portrait ? 0.9 : 0.5) * w;
    let px = Math.min(0.11 * h, (1.6 * w) / Math.max(6, cap.reading.length));
    px = Math.min(px, (px * room) / Math.max(1, brushWidth(g, cap.reading, px)));
    const y = (portrait ? 0.24 : 0.36) * h;
    g.translate(cx, y); g.scale(scale, scale); g.translate(-cx, -y);
    swash(g, cx, y + px * 0.5, Math.min(room + 2 * px, brushWidth(g, cap.reading, px) + 2 * px), px * 2, '#b0161c', 0.9 * alpha);
    inkText(g, cap.reading, cx, y, px, PAPER, 'center', alpha);
    if (cap.sub) inkText(g, cap.sub, cx, y + px * 1.3, Math.min(px * 0.5, (0.9 * room) / (cap.sub.length * 0.62)), GOLD, 'center', alpha);
  }
  g.restore();
}
