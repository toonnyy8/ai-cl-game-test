// hud.ts <- duel/lisp/hud.lisp at a functional level (plain type, no brush look): per side, P2 mirrored, the name, Reishi
// (red under T.redThreshold, a white damage trail), the guard gauge, 9 Konpaku pips, Reiatsu 3 bars, flash step (ticks at
// the Hoho cost and the burst threshold), Awakening (EVOLUTION), the kit meter; the timer; the combo counter under the
// victim's bar; move callouts over the user's head; big words from the sim events; the HOLD O KIKON prompt; the
// cinematic dim + caption; title, select, results and pause screens. Canvas2D on #hud, device pixels.
import { T } from '../sim/tuning';
import { redP } from '../sim/rules';
import { kitCommandOkP } from '../sim/fighter';
import { findKit } from '../sim/kit';
import type { Ent, SimEvent, World } from '../sim/types';

const cv = document.getElementById('hud') as HTMLCanvasElement;
const g = cv.getContext('2d')!;
let w = 0, h = 0, s = 1;
export function resizeHud(): void {
  const d = devicePixelRatio || 1;
  w = cv.width = Math.round(innerWidth * d); h = cv.height = Math.round(innerHeight * d);
  s = Math.max(1, h / 360);
}
export const hudSize = (): [number, number] => [w, h];

const P_COL = ['#ff9a4d', '#80b3ff'];
function text(str: string, x: number, y: number, px: number, color: string, align: CanvasTextAlign = 'left', alpha = 1): void {
  g.font = `bold ${Math.round(px)}px system-ui, "Segoe UI", sans-serif`;
  g.textAlign = align; g.textBaseline = 'top'; g.globalAlpha = alpha;
  g.fillStyle = 'rgba(0,0,0,0.7)'; g.fillText(str, x + Math.max(1, px / 14), y + Math.max(1, px / 14));
  g.fillStyle = color; g.fillText(str, x, y);
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
function side(e: Ent, human: boolean, inBattle: boolean): void {
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
    text('HOLD O  KIKON', right ? 0.75 * w : 0.25 * w, 0.78 * h, 9 * s, '#ff3340', 'center', 0.5 + 0.5 * pulse(4));
}

export type Project = (x: number, y: number, z: number) => [number, number] | null;

export function drawBattle(wd: World, project: Project): void {
  g.clearRect(0, 0, w, h);
  if (wd.cine) { drawCine(wd); drawWords(); return; }
  for (const e of [wd.p1, wd.p2]) side(e, !e.brain, wd.flow === 'battle');
  for (const e of [wd.p1, wd.p2]) {                                              // callouts over the user's head
    if (e.f.calloutT <= 0 || !e.f.callout) continue;
    const p = project(e.pos[0], e.pos[1] + e.body.hurtH + 0.45, e.pos[2]);
    if (p) text(e.f.callout, p[0], p[1], 9 * s, '#ffd98c', 'center', Math.min(1, e.f.calloutT / 15));
  }
  const secs = Math.min(999, Math.ceil(Math.max(0, wd.timer) / 60));
  text(String(secs), w / 2, 0.035 * h, 22 * s, secs < 30 ? '#ff4d4d' : '#ffffff', 'center');
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
    text(title, w / 2, 0.4 * h, 24 * s, '#ffe0b0', 'center');
    text(kitName(c.a.f.character), w / 2, 0.4 * h + 30 * s, 10 * s, P_COL[c.a.f.side], 'center');
  }
  rect(0.3 * w, 0.88 * h, 0.4 * w * (c.cf / c.len), 2 * s, 'rgba(255,255,255,0.5)');
}

// ---------------------------------------------------------------- screens
export function drawTitle(): void {
  g.clearRect(0, 0, w, h);
  rect(0, 0, w, h, 'rgba(0,0,0,0.35)');
  text('SOUL DUEL', w / 2, 0.3 * h, 48 * s, '#ffebcc', 'center');
  text('A FAN STUDY INSPIRED BY BLEACH: REBIRTH OF SOULS', w / 2, 0.3 * h + 58 * s, 8 * s, '#c8c4d0', 'center');
  text('PRESS ENTER', w / 2, 0.7 * h, 12 * s, '#ffffff', 'center', 0.4 + 0.6 * pulse(1));
}

export interface Sel { row: number; p1: number; p2: number; mode: number }
export const MODES = ['VS CPU', 'CPU VS CPU'];
export function drawSelect(sel: Sel, roster: string[]): void {
  g.clearRect(0, 0, w, h);
  rect(0, 0, w, h, 'rgba(0,0,0,0.45)');
  text('CHARACTER SELECT', w / 2, 0.12 * h, 18 * s, '#ffebcc', 'center');
  const rows: [string, string][] = [['P1', kitName(roster[sel.p1])], ['P2', kitName(roster[sel.p2])], ['MODE', MODES[sel.mode]], ['', 'FIGHT']];
  rows.forEach(([k, v], i) => {
    const y = 0.32 * h + i * 26 * s, on = i === sel.row;
    if (k) text(k, w / 2 - 20 * s, y, 11 * s, on ? '#ffffff' : '#9a98a6', 'right');
    text(i < 3 ? `<  ${v}  >` : v, w / 2 + (k ? 0 : -0), y, 11 * s, on ? '#ffd27a' : '#c8c4d0', k ? 'left' : 'center');
  });
  text('W/S ROW   A/D CHANGE   ENTER FIGHT   ESC BACK', w / 2, 0.85 * h, 7 * s, '#a8a6b4', 'center');
}

export function drawResults(wd: World, menu: boolean): void {
  g.clearRect(0, 0, w, h);
  const px = 0.04 * w, pw = 0.42 * w, cx = px + pw / 2;
  rect(px, 0, pw, h, 'rgba(8,8,12,0.9)');
  const win = wd.winner === 0 ? wd.p1 : wd.winner === 1 ? wd.p2 : null;
  text(win ? 'WINNER' : 'DRAW', cx, 0.12 * h, 26 * s, win ? '#ffffff' : '#c8c4d0', 'center');
  if (win) text(`${win.f.kit.name}  (P${win.f.side + 1})`, cx, 0.12 * h + 32 * s, 12 * s, P_COL[win.f.side], 'center');
  const y0 = 0.36 * h, row = 16 * s, c1 = px + pw * 0.68, c2 = px + pw * 0.88, lx = px + 10 * s;
  text('P1', c1, y0, 9 * s, P_COL[0], 'center'); text('P2', c2, y0, 9 * s, P_COL[1], 'center');
  const val = (e: Ent) => [e.g.dealt, e.g.kikons, e.g.perfects, e.g.bestCombo, e.g.konpaku];
  ['DAMAGE', 'KIKONS', 'PERFECT HOHOS', 'BEST COMBO', 'KONPAKU LEFT'].forEach((label, i) => {
    const y = y0 + (i + 1) * row, a = val(wd.p1)[i], b = val(wd.p2)[i];
    text(label, lx, y, 9 * s, '#b8b4c4'); text(String(a), c1, y, 9 * s, '#fff', 'center'); text(String(b), c2, y, 9 * s, '#fff', 'center');
  });
  text('TIME', lx, y0 + 6 * row, 9 * s, '#b8b4c4');
  text(`${Math.round(wd.tick / 60)} S`, (c1 + c2) / 2, y0 + 6 * row, 9 * s, '#fff', 'center');
  if (menu) text('ENTER  CHARACTER SELECT', cx, 0.8 * h, 9 * s, '#ffd27a', 'center', 0.5 + 0.5 * pulse(1));
}

export function drawPause(): void {
  rect(0, 0, w, h, 'rgba(0,0,0,0.55)');
  text('PAUSED', w / 2, 0.3 * h, 32 * s, '#ffffff', 'center');
  text('ESC  RESUME        ENTER  QUIT TO SELECT', w / 2, 0.5 * h, 9 * s, '#d8d4e0', 'center');
}
