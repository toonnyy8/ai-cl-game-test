// hud.ts <- duel/lisp/hud.lisp at a functional level (plain type, no brush look): per side, P2 mirrored, the name, Reishi
// (red under T.redThreshold, a white damage trail), the guard gauge, 9 Konpaku pips, Reiatsu 3 bars, flash step (ticks at
// the Hoho cost and the burst threshold), Awakening (EVOLUTION), the kit meter; the timer; the combo counter under the
// victim's bar; move callouts over the user's head; big words from the sim events; the HOLD O KIKON prompt; the
// cinematic dim + caption. In a portrait window (onehand.lisp / hud.lisp HUD-SIDE-PORTRAIT, DUEL_MOBILE_DESIGN §14-§15.2) P2's
// block runs across the top and P1's across the bottom instead. The menus are DOM (src/ui/menus.ts). Canvas2D on #hud,
// device pixels.
import { T } from '../sim/tuning';
import { redP } from '../sim/rules';
import { kitCommandOkP } from '../sim/fighter';
import { findKit } from '../sim/kit';
import type { Ent, SimEvent, World } from '../sim/types';
import { portraitMetrics } from '../input/onehand';

const cv = document.getElementById('hud') as HTMLCanvasElement;
const g = cv.getContext('2d')!;
let w = 0, h = 0, s = 1;
export function resizeHud(): void {
  const d = devicePixelRatio || 1;
  w = cv.width = Math.round(innerWidth * d); h = cv.height = Math.round(innerHeight * d);
  s = Math.max(1, Math.min(h / 360, w / 480));                    // engine ui.lisp UI-SCALE; portrait: the 11 CSS px floor
  if (h > w) s = Math.max(s, Math.ceil((11 * d) / 7));
}
export const hudSize = (): [number, number] => [w, h];
export const hudCtx = (): CanvasRenderingContext2D => g;
export function clearHud(): void { g.clearRect(0, 0, w, h); }

const P_COL = ['#ff9a4d', '#80b3ff'];
function text(str: string, x: number, y: number, px: number, color: string, align: CanvasTextAlign = 'left', alpha = 1): void {
  g.font = `bold ${Math.round(px)}px system-ui, "Segoe UI", sans-serif`;
  g.textAlign = align; g.textBaseline = 'top'; g.globalAlpha = alpha;
  const mw = 0.94 * w;                                              // a long line is squeezed, never cut
  g.fillStyle = 'rgba(0,0,0,0.7)'; g.fillText(str, x + Math.max(1, px / 14), y + Math.max(1, px / 14), mw);
  g.fillStyle = color; g.fillText(str, x, y, mw);
  g.globalAlpha = 1;
}
function rect(x: number, y: number, ww: number, hh: number, color: string): void { g.fillStyle = color; g.fillRect(x, y, ww, hh); }
/** A bar of width BW filled FRAC from its outer edge (RIGHT: P2's side, filled from the right). */
function bar(x: number, y: number, bw: number, bh: number, frac: number, right: boolean, color: string, back = 'rgba(0,0,0,0.55)'): void {
  rect(x, y, bw, bh, back);
  const f = Math.max(0, Math.min(1, frac)) * bw;
  rect(right ? x + bw - f : x, y, f, bh, color);
}
const pulse = (hz: number) => 0.5 + 0.5 * Math.sin(performance.now() / 1000 * 2 * Math.PI * hz);
const kitName = (character: string) => findKit(character, 'base').name ?? character.toUpperCase();

// ---------------------------------------------------------------- words, combos, trails (event-driven, real time)
interface Word { text: string; color: string; t0: number; secs: number; small: boolean }
let words: Word[] = [];
const trail = [1, 1];
const combo = [{ str: '', t0: -10 }, { str: '', t0: -10 }];
const now = () => performance.now() / 1000;
export function announce(text: string, color = '#ffffff', secs = 1.0, small = false): void {
  words = words.filter((x) => x.small !== small);
  words.push({ text, color, t0: now(), secs, small });
}
export function resetHud(): void { words = []; trail[0] = trail[1] = 1; combo.forEach((c) => { c.str = ''; c.t0 = -10; }); }

export function hudEvents(ev: SimEvent[]): void {
  for (const e of ev) {
    switch (e.kind) {
      case 'kikon': announce('KIKON', '#ff3040', 1.4); break;
      case 'soul-break': announce('SOUL BREAK', '#ff3040', 1.4); break;
      case 'guard-crush': announce('GUARD CRUSH', '#ffffff', 1.0, true); break;
      case 'guard-break': announce('GUARD BREAK', '#ffffff', 1.0, true); break;
      case 'stance-break': announce('STANCE BREAK', '#ffffff', 1.0, true); break;
      case 'evolution': announce('EVOLUTION', '#ffd94d', 1.4); break;
      case 'perfect': announce('PERFECT HOHO', '#9ff0ff', 1.0, true); break;
      case 'parried': announce('PARRY', '#9ff0ff', 0.8, true); break;
      case 'clash': announce('CLASH', '#ffffff', 0.8, true); break;
      case 'burst': announce(`${String(e.args[2]).toUpperCase()} BURST`, e.args[2] === 'blue' ? '#60a8ff' : e.args[2] === 'orange' ? '#ff9a40' : '#ffffff', 0.9, true); break;
      case 'hit': if (e.args[6]) announce('COUNTER', '#fff070', 0.7, true); break;
      case 'cine': if (e.args[0] === 'ko-cine') announce('K.O.', '#ff3040', 2.4); else if (e.args[0] === 'time-cine') announce('TIME', '#ffffff', 2.0); break;
      case 'cine-end': if (e.args[0] === 'intro-cine') announce('FIGHT', '#ffe0b0', 1.0); break;
    }
  }
}

function drawWords(): void {
  const t = now();
  words = words.filter((x) => t - x.t0 < x.secs);
  for (const x of words) {
    const k = (t - x.t0) / x.secs, a = k > 0.7 ? (1 - k) / 0.3 : 1;
    text(x.text, w / 2, h * (x.small ? 0.3 : 0.42), (x.small ? 14 : 30) * s, x.color, 'center', a);
  }
}

// ---------------------------------------------------------------- the battle HUD
function side(e: Ent, human: boolean, inBattle: boolean, prompt: string): void {
  const f = e.f, gg = e.g, kit = f.kit, sd = f.side, right = sd === 1;
  const m = 0.03 * w, bw = 0.36 * w, x = right ? w - m - bw : m, edge = right ? x + bw : x;
  const al: CanvasTextAlign = right ? 'right' : 'left', y = 0.05 * h, bh = Math.max(7 * s, 0.028 * h);
  const frac = gg.reishi / gg.reishiMax, red = redP(gg.reishi, gg.reishiMax);
  text(`${kit.name ?? f.character.toUpperCase()}${f.form !== 'base' ? '  ' + kit.formName : ''}`, edge, y - 9 * s, 7 * s, P_COL[sd], al);
  trail[sd] = trail[sd] > frac ? Math.max(frac, trail[sd] - 0.35 / 60) : frac;
  bar(x, y, bw, bh, trail[sd], right, '#f4f4f0');
  const rf = Math.max(0, Math.min(1, frac)) * bw;
  rect(right ? x + bw - rf : x, y, rf, bh, red ? `rgba(230,40,40,${0.75 + 0.25 * pulse(3)})` : '#e8c060');
  // the guard gauge (grey while guardless, darker while he holds guard)
  const gf = gg.gg / T.ggMax, gy = y + bh + 2 * s, gh = Math.max(3 * s, 0.3 * bh);
  bar(x, gy, bw, gh, gf, right, gg.guardless ? '#806060' : f.state === 'guard' || f.state === 'guard-hit' ? '#6d8fb8' : '#a8c4e8');
  // Konpaku pips
  const py = y + bh + 16 * s, pr = Math.max(4.5 * s, 0.013 * h) * 0.7;
  for (let i = 0; i < T.konpakuMax; i++) {
    const cx = right ? edge - pr - i * 3.2 * pr : edge + pr + i * 3.2 * pr;
    g.beginPath(); g.arc(cx, py, pr, 0, 2 * Math.PI);
    g.fillStyle = i < gg.konpaku ? (red ? '#ff5050' : '#ffe2a0') : 'rgba(255,255,255,0.15)'; g.fill();
  }
  // Reiatsu: 3 bars
  const sy = y + bh + 25 * s, sw = 0.075 * w, sh = Math.max(3 * s, 0.011 * h), gap = 3 * s, row = 11 * s;
  for (let i = 0; i < 3; i++) {
    const bx = right ? edge - (i + 1) * (sw + gap) + gap : edge + i * (sw + gap);
    bar(bx, sy, sw, sh, (gg.reiatsu - i * T.reiatsuBar) / T.reiatsuBar, right, '#70c8ff');
  }
  const lab = (str: string, yy: number, color: string, lx = right ? edge - 3 * (sw + gap) - 4 * s : edge + 3 * (sw + gap) + 4 * s) =>
    text(str, lx, yy - 2.5 * s, 6 * s, color, al);
  lab('REIATSU', sy, '#73ccff');
  // flash step, awakening, the kit meter
  const aw = 3 * sw + 6 * s, ah = Math.max(3 * s, 0.009 * h), ax = right ? edge - aw : x, lx = right ? edge - aw - 6 * s : edge + aw + 6 * s;
  const fy = sy + row, ay = fy + row, my = ay + row;
  const burst = gg.burst;
  bar(ax, fy, aw, ah, gg.fs / T.fsMax, right, burst === 'blue' ? '#4f9dff' : burst === 'orange' ? '#ff9a40' : burst ? '#ffffff' : '#9cc4ff');
  for (const tick of [T.fsHoho, T.fsBurst]) { const tx = right ? ax + aw - aw * tick / T.fsMax : ax + aw * tick / T.fsMax; rect(tx, fy - s, Math.max(1, s / 2), ah + 2 * s, '#ffffff'); }
  lab('FLASH STEP', fy, '#9cc7ff', lx);
  bar(ax, ay, aw, ah, gg.awaken / T.awakenMax, right, gg.evolution ? '#ffd94d' : '#e8c070');
  if (gg.evolution) lab('EVOLUTION', ay, `rgba(255,217,77,${0.4 + 0.6 * pulse(3)})`, lx); else lab('AWAKEN', ay, '#f2cc66', lx);
  const meter = kit.meter as { name?: string; max?: number } | null;
  if (meter?.max) {
    const burning = gg.formLeft > 0;
    bar(ax, my, aw, ah, burning ? gg.formLeft / Math.max(1, gg.formTotal) : gg.meter / meter.max, right, burning ? '#ff6a1a' : '#ff8c40');
    lab(meter.name ?? 'METER', my, '#ff8c40', lx);
  }
  // the combo counter under this side's bar (this side is the victim)
  const c = combo[sd];
  if (f.comboHits > 1 && f.comboDmg > 0) { c.str = `${f.comboHits} HITS  ${f.comboDmg}`; c.t0 = now(); }
  if (now() - c.t0 < 1.2) text(c.str, edge, y + bh + 62 * s, 10 * s, '#ffe699', al);
  // the Kikon prompt for a human whose opponent is red
  const o = f.opp!;
  if (human && inBattle && redP(o.g.reishi, o.g.reishiMax) && kitCommandOkP(e, 'kikon'))
    text(prompt, right ? 0.75 * w : 0.25 * w, 0.78 * h, 9 * s, '#ff3340', 'center', 0.5 + 0.5 * pulse(4));
}

// ---------------------------------------------------------------- the portrait blocks (hud.lisp HUD-SIDE-PORTRAIT)
/** E's block: row 1 the name, a label (EVOLUTION / the form) and the nine Konpaku flames (P2: the timer at its right end);
 *  Reishi; the guard gauge; the four small gauges across the width (Reiatsu cells, flash step, Awakening, the kit meter). */
function sidePortrait(e: Ent, wd: World, human: boolean, top: number, ps: number, blockH: number, timerStr: string | null, prompt: string): void {
  const f = e.f, gg = e.g, kit = f.kit, sd = f.side;
  const m = 4 * ps, x = m, bw = w - 2 * m, y = top;
  const grad = g.createLinearGradient(0, y - 2 * ps, 0, y + blockH);
  grad.addColorStop(0, 'rgba(6,6,12,0.0)'); grad.addColorStop(0.25, 'rgba(6,6,12,0.55)'); grad.addColorStop(1, 'rgba(6,6,12,0.55)');
  rect(0, y - 2 * ps, w, blockH + 4 * ps, grad as unknown as string);
  const name = `${kit.name ?? f.character.toUpperCase()}${f.form !== 'base' && kit.formName ? '  ' + kit.formName : ''}`;
  text(name, x, y + ps, 6 * ps, P_COL[sd]);
  g.font = `bold ${Math.round(6 * ps)}px system-ui, "Segoe UI", sans-serif`;
  let fx = x + g.measureText(name).width + 4 * ps;
  if (gg.evolution) {
    text('EVOLUTION', fx, y + 1.8 * ps, 4.5 * ps, `rgba(255,217,77,${0.4 + 0.6 * pulse(3)})`);
    g.font = `bold ${Math.round(4.5 * ps)}px system-ui, "Segoe UI", sans-serif`;
    fx += g.measureText('EVOLUTION').width + 4 * ps;
  }
  const fend = timerStr ? w - m - 14 * ps : w - m, red = redP(gg.reishi, gg.reishiMax);
  const pr = Math.min(2.6 * ps, (fend - fx) / (T.konpakuMax * 2.6)), pitch = Math.min(3.4 * pr, (fend - fx) / T.konpakuMax);
  for (let i = 0; i < T.konpakuMax; i++) {
    g.beginPath(); g.arc(fx + pr + i * pitch, y + 4 * ps, pr, 0, 2 * Math.PI);
    g.fillStyle = i < gg.konpaku ? (red ? '#ff5050' : '#ffe2a0') : 'rgba(255,255,255,0.15)'; g.fill();
  }
  if (timerStr) text(timerStr, w - m, y, 8 * ps, timerStr.length < 3 && +timerStr < 30 ? '#ff4d4d' : '#ffffff', 'right');
  const frac = gg.reishi / gg.reishiMax, ry = y + 9 * ps, rh = 5 * ps;
  trail[sd] = trail[sd] > frac ? Math.max(frac, trail[sd] - 0.35 / 60) : frac;
  bar(x, ry, bw, rh, trail[sd], false, '#f4f4f0');
  rect(x, ry, Math.max(0, Math.min(1, frac)) * bw, rh, red ? `rgba(230,40,40,${0.75 + 0.25 * pulse(3)})` : '#e8c060');
  bar(x, ry + rh + ps, bw, 2 * ps, gg.gg / T.ggMax, false, gg.guardless ? '#806060' : f.state === 'guard' || f.state === 'guard-hit' ? '#6d8fb8' : '#a8c4e8');
  const sy = ry + rh + 5 * ps, sh = 4 * ps, gap = 3 * ps, cw = (bw - 3 * gap) / 4;
  for (let i = 0; i < 3; i++) {                                                  // Reiatsu: 3 cells in the first quarter
    const c = (cw - 2 * ps) / 3;
    bar(x + i * (c + ps), sy, c, sh, (gg.reiatsu - i * T.reiatsuBar) / T.reiatsuBar, false, '#70c8ff');
  }
  const burst = gg.burst;
  bar(x + cw + gap, sy, cw, sh, gg.fs / T.fsMax, false, burst === 'blue' ? '#4f9dff' : burst === 'orange' ? '#ff9a40' : burst ? '#ffffff' : '#9cc4ff');
  bar(x + 2 * (cw + gap), sy, cw, sh, gg.awaken / T.awakenMax, false, gg.evolution ? '#ffd94d' : '#e8c070');
  const meter = kit.meter as { max?: number } | null;
  if (meter?.max) {
    const burning = gg.formLeft > 0;
    bar(x + 3 * (cw + gap), sy, cw, sh, burning ? gg.formLeft / Math.max(1, gg.formTotal) : gg.meter / meter.max, false, burning ? '#ff6a1a' : '#ff8c40');
  }
  const c = combo[sd], cy = sd === 1 ? y + blockH + 4 * ps : y - 12 * ps;       // under P2's block / over P1's
  if (f.comboHits > 1 && f.comboDmg > 0) { c.str = `${f.comboHits} HITS  ${f.comboDmg}`; c.t0 = now(); }
  if (now() - c.t0 < 1.2) text(c.str, w / 2, cy, 7 * ps, '#ffe699', 'center');
  const o = f.opp!;
  if (human && wd.flow === 'battle' && redP(o.g.reishi, o.g.reishiMax) && kitCommandOkP(e, 'kikon'))
    text(prompt, w / 2, portraitMetrics().hudBottom + 14 * ps, 7 * ps, '#ff3340', 'center', 0.5 + 0.5 * pulse(4));
}

export type Project = (x: number, y: number, z: number) => [number, number] | null;

export interface BattleHud { portrait: boolean; practice: boolean; hint: boolean; prompt: (side: number) => string;
  tag?: string | null }                                 // ENDLESS: STAGE n (hud.lisp HUD-ENDLESS-TAG)

export function drawBattle(wd: World, project: Project, o: BattleHud): void {
  g.clearRect(0, 0, w, h);
  if (wd.cine) { drawCine(wd); drawWords(); return; }
  const secs = Math.min(999, Math.ceil(Math.max(0, wd.timer) / 60)), timer = o.practice ? 'PRACTICE' : String(secs);
  if (o.portrait) {
    const pm = portraitMetrics();
    sidePortrait(wd.p2, wd, !wd.p2.brain, pm.top, pm.s, pm.blockH, timer, o.prompt(1));
    sidePortrait(wd.p1, wd, !wd.p1.brain, pm.p1Top, pm.s, pm.blockH, null, o.prompt(0));
  } else for (const e of [wd.p1, wd.p2]) side(e, !e.brain, wd.flow === 'battle', o.prompt(e.f.side));
  if (o.hint) {                                                                   // PERFECT HINT over P1
    const p = project(wd.p1.pos[0], wd.p1.pos[1] + wd.p1.body.hurtH + 0.8, wd.p1.pos[2]);
    if (p) text('HOHO!', p[0], p[1], 11 * s, '#9ff0ff', 'center');
  }
  for (const e of [wd.p1, wd.p2]) {                                              // callouts over the user's head
    if (e.f.calloutT <= 0 || !e.f.callout) continue;
    const p = project(e.pos[0], e.pos[1] + e.body.hurtH + 0.45, e.pos[2]);
    if (p) text(e.f.callout, p[0], p[1], 9 * s, '#ffd98c', 'center', Math.min(1, e.f.calloutT / 15));
  }
  if (!o.portrait) text(timer, w / 2, 0.035 * h, (o.practice ? 10 : 22) * s, !o.practice && secs < 30 ? '#ff4d4d' : '#ffffff', 'center');
  if (o.tag) {                                                                    // landscape under the timer, portrait left under P2's block
    if (o.portrait) { const pm = portraitMetrics(); text(o.tag, 4 * pm.s, pm.hudBottom + pm.s, 6 * pm.s, '#e2deea'); }
    else text(o.tag, w / 2, 0.13 * h, 10 * s, '#c8c4d4', 'center');
  }
  drawWords();
}

function drawCine(wd: World): void {
  const c = wd.cine!;
  rect(0, 0, w, h, 'rgba(0,0,0,0.45)');
  rect(0, 0, w, 0.09 * h, '#000'); rect(0, 0.91 * h, w, 0.09 * h, '#000');
  const title = c.name.replace(/-cine$/, '').replace(/^(yama|ken)-/, '').replace(/-/g, ' ').toUpperCase();
  if (c.name === 'intro-cine') {
    text(`${kitName(wd.p1.f.character)}   VS   ${kitName(wd.p2.f.character)}`, w / 2, 0.42 * h, 22 * s, '#ffffff', 'center');
  } else {
    const ty = (h > w ? 0.2 : 0.4) * h;                                             // portrait: clear of the big words
    text(title, w / 2, ty, 24 * s, '#ffe0b0', 'center');
    text(kitName(c.a.f.character), w / 2, ty + 30 * s, 10 * s, P_COL[c.a.f.side], 'center');
  }
  rect(0.3 * w, 0.88 * h, 0.4 * w * (c.cf / c.len), 2 * s, 'rgba(255,255,255,0.5)');
}
