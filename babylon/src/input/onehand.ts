// onehand.ts <- duel/lisp/onehand.lisp (片手 ONE-HAND, docs/DUEL_MOBILE_DESIGN.md) + the page services of duel/web/pwa.js.
// The recogniser (touch.ts) turns the thumb into gestures; this lays out the flow pad and the chips (DECK-LAYOUT), maps
// gestures to P1's vpad buttons (TOUCH-BUTTON; read by bindings.ts readP1: fighters, rules and the AI never see touch) and
// draws the deck. Plus, new in this build, the two-thumb LANDSCAPE touch controls (a floating stick on the left, the
// buttons on the right) for a touch device held sideways when ONE-HAND is not in effect; the Lisp build has none.
//   per frame: onehandFrame (before the flow)    per vpad read: touchRead.begin (readP1)    drawing: drawTouch
import { TP_FLICK, TP_HOHO, TP_TAP, TP_TAP_HI, Touch, type TouchEvent5 } from './touch';
import { onSettings, oneHandOnP, setting, settingValue } from '../ui/settings';
import { hohoAllowedP } from '../sim/rules';
import { bankaiReadyP, burstOkP, perfectNowP } from '../sim/combat';
import { kitHook } from '../sim/kit';
import { W, kitOf, stateOf, type Ent, type World } from '../sim/types';
import type { Action } from '../sim/vpad';

export const COARSE = !!globalThis.matchMedia?.('(pointer: coarse)').matches;
export const portraitP = (): boolean => innerHeight > innerWidth;
/** ONE-HAND is offered where the window is portrait or the device touch-first (a landscape desktop never). */
export const oneHandOfferedP = (): boolean => COARSE || portraitP();
/** Would VS CPU / PRACTICE be one-handed here and now (the ONE-HAND setting)? */
export const oneHandEffectiveP = (): boolean => oneHandOnP(setting('one-hand'), COARSE, portraitP());

// ---------------------------------------------------------------- the page: safe-area insets, back trap, wake lock
let insets: [number, number] | null = null;
addEventListener('resize', () => { insets = null; });
/** The safe-area inset at the top / bottom, CSS px (env(safe-area-inset-*), measured once per window size). */
function inset(i: 0 | 1): number {
  if (!insets && document.body) {
    const d = document.createElement('div');
    d.style.cssText = 'position:fixed;visibility:hidden;padding-top:env(safe-area-inset-top);padding-bottom:env(safe-area-inset-bottom)';
    document.body.appendChild(d);
    const cs = getComputedStyle(d);
    insets = [parseFloat(cs.paddingTop) || 0, parseFloat(cs.paddingBottom) || 0];
    d.remove();
  }
  return insets ? Math.round(insets[i]) : 0;
}

let backs = 0;
/** Back gestures since the last call (a touch-first device: the browser's back pauses / goes back instead of leaving). */
export function takeBack(): boolean { const b = backs > 0; backs = 0; return b; }
if (COARSE) {
  let trapped = false, firstTap = true;
  addEventListener('popstate', () => { backs++; history.pushState({ trap: 1 }, ''); });
  // pointerup: a touch's pointerdown is not a user activation (HTML spec), its pointerup is
  addEventListener('pointerup', () => {
    if (!trapped) { trapped = true; history.pushState({ trap: 1 }, ''); }
    if (!firstTap) return;
    firstTap = false;
    const ios = /iP(hone|ad|od)/.test(navigator.userAgent) || (navigator.maxTouchPoints > 1 && /Mac/.test(navigator.platform));
    const el = document.documentElement;
    if (!ios && el.requestFullscreen && portraitP() && !matchMedia('(display-mode: fullscreen)').matches)
      el.requestFullscreen({ navigationUI: 'hide' })
        .then(() => (screen.orientation as ScreenOrientation & { lock?: (o: string) => Promise<void> }).lock?.('portrait'))
        .catch(() => {});
  }, true);
}
let wakeOn = false, lock: WakeLockSentinel | null | true = null;
function wake(): void {
  if (!wakeOn || lock || document.visibilityState !== 'visible' || !navigator.wakeLock) return;
  lock = true;
  navigator.wakeLock.request('screen').then((l) => {
    lock = l; l.addEventListener('release', () => { lock = null; });
    if (!wakeOn) l.release();
  }).catch(() => { lock = null; });
}
document.addEventListener('visibilitychange', wake);
/** Battle on / off: the screen wake lock on a touch-first device. */
function setWake(on: boolean): void {
  if (!COARSE || on === wakeOn) return;
  wakeOn = on;
  if (on) wake(); else if (lock && lock !== true) { lock.release(); lock = null; }
}

// ---------------------------------------------------------------- portrait metrics (the HUD blocks, the camera band)
/** Portrait layout in device px: UI scale S (text floor 11 CSS px: ceil(11 dpr / 7)), the blocks' height, P2's block top,
 *  its bottom, P1's block top, and the camera BAND [top, bottom] as fractions of the height (onehand.lisp DECK-UPDATE). */
export function portraitMetrics(): { s: number; blockH: number; top: number; hudBottom: number; p1Top: number; band: [number, number] } {
  const d = devicePixelRatio || 1, h = innerHeight * d;
  const s = Math.ceil((11 * d) / 7), blockH = 29 * s, top = Math.max(4, inset(0)) * d;
  const hudBottom = top + blockH, p1Top = h - Math.max(8, inset(1) + 4) * d - blockH;
  return { s, blockH, top, hudBottom, p1Top, band: [hudBottom / h + 0.03, Math.min(0.82, p1Top / h - 0.03)] };
}

// ---------------------------------------------------------------- the deck (design §3.3, the 2026-09-27 playtest spots)
/** Chip i: 0 O, 1 L, 2 I, 3 SP1, 4 SP2, 5 AWAKEN (held 300 ms), 6 pause, 7 RV. CSS px: x from the thumb-side edge, y from
 *  the bottom (negative: from the top), radius, label. */
const CHIP_SPOTS: [number, number, number, string][] = [[170, 396, 36, 'O'], [72, 380, 26, 'L'], [72, 310, 26, 'I'],
  [72, 240, 26, 'SP1'], [72, 170, 26, 'SP2'], [270, 396, 26, 'AWK'], [32, -200, 22, 'II'], [170, 472, 22, 'RV']];
const CHIP_HOLDS = [0, 0, 0, 0, 0, 300, 0, 0], U_CHIP_HOLDS = [0, 0, 0, 0, 0, 0, 0, 0];
const GLYPH_NAMES = ['', 'Q', 'STEP', 'F', 'HOHO', 'GUARD', 'DASH', 'BURST'];

export const touch = new Touch();
let hand: 'right' | 'left' = 'right';
let mode: 'none' | 'deck' | 'land' = 'none', deckKey = '';
onSettings(() => {
  hand = setting('hand') === 1 ? 'left' : 'right';
  touch.cfg.tapSplit = settingValue('tap-split') as number;
  touch.cfg.flickMin = settingValue('flick') as number;
  deckKey = '';
});

/** Pad (x0 y0 x1 y1) and chips ([cx cy r]), window px, for the window and the hand. */
export function deckLayout(): { pad: number[]; chips: number[][] } {
  const d = devicePixelRatio || 1, w = innerWidth, h = innerHeight, left = hand === 'left';
  const hud = portraitMetrics().hudBottom / d, safeBot = inset(1);
  const x = (fromSide: number) => d * (left ? fromSide : w - fromSide);
  return {
    pad: [d * (left ? 32 : 16), d * (h - 460), d * (left ? w - 16 : w - 32), d * (h - Math.max(50, safeBot + 16))],
    chips: CHIP_SPOTS.map(([cx, cy, r]) => [x(cx), d * (cy < 0 ? Math.max(-cy, hud + 10 + r) : h - cy), d * r]),
  };
}

/** The touch controls in use: the one-hand DECK (portrait VS CPU / PRACTICE), the LANDSCAPE two-thumb layer, or none. */
export type TouchMode = 'none' | 'deck' | 'land';
let p1: Ent | null = null;                                  // P1 of the battle on screen (deck faces, U chip)

/** P1's form has a :u hook (its U is a move, a parry): a resting thumb does nothing and the spent AWAKEN chip is U. */
const uChipP = (): boolean => mode === 'deck' && !!p1 && !!kitHook(kitOf(p1), 'u');

function deckUpdate(): void {
  const key = `${innerWidth}x${innerHeight}@${devicePixelRatio} ${hand} ${mode} ${uChipP()} ${inset(0)} ${inset(1)}`;
  if (key === deckKey) return;
  deckKey = key;
  const d = devicePixelRatio || 1;
  if (mode === 'deck') { const { pad, chips } = deckLayout(); touch.layout(d, pad, chips, uChipP() ? U_CHIP_HOLDS : CHIP_HOLDS); }
  else touch.layout(d, [0, 0, -1, -1]);
  land.layout();
}

/** Would a Hoho by E (in state ST) started now be PERFECT? Then any up-flick is one (the user 2026-10-01). */
function perfectUpP(e: Ent, st: string, battle: boolean): boolean {
  const f = e.f, g = e.g;
  return (st === 'idle' || st === 'guard' || st === 'run') && battle && !f.kit.rooted
    && hohoAllowedP(false, g.fs, f.hohoLock, g.burst) && perfectNowP(e);
}
/** PERFECT HINT (hud): P1 of W would Hoho perfectly now. */
export const perfectHintP = (w: World): boolean => setting('hint') === 1 && w.flow === 'battle' && !w.cine
  && perfectUpP(w.p1, stateOf(w.p1), true);

// ---------------------------------------------------------------- pointer events -> the recogniser's queue
let queue: TouchEvent5[] = [];
const slots = new Map<number, number>();
function slotOf(id: number, make: boolean): number {
  let s = slots.get(id);
  if (s === undefined && make) {
    for (s = 0; [...slots.values()].includes(s); s++);
    slots.set(id, s);
  }
  return s ?? -1;
}
function onPointer(type: number, e: PointerEvent): void {
  if (e.pointerType === 'mouse') return;                    // fingers and pens only (a desktop mouse is the menus')
  const d = devicePixelRatio || 1, s = slotOf(e.pointerId, type === 0);
  if (s < 0) return;
  queue.push([type, s, e.clientX * d, e.clientY * d, e.timeStamp]);
  land.event(type, s, e.clientX * d, e.clientY * d, e.timeStamp);
  if (type >= 2) slots.delete(e.pointerId);
}
addEventListener('pointerdown', (e) => onPointer(0, e));
addEventListener('pointermove', (e) => onPointer(1, e));
addEventListener('pointerup', (e) => onPointer(2, e));
addEventListener('pointercancel', (e) => onPointer(3, e));
addEventListener('blur', () => { queue.push([4, -1, 0, 0, performance.now()]); slots.clear(); land.clear(); });

/** Every frame, before the flow: the mode, the wake lock, the deck, the game's Hoho flags, then this frame's events. */
export function onehandFrame(w: World | null, m: TouchMode, simRunning: boolean): void {
  if (m !== mode) { mode = m; deckKey = ''; }
  p1 = w ? w.p1 : null;
  setWake(!!w && (w.flow === 'intro' || w.flow === 'battle' || w.flow === 'finish'));
  deckUpdate();
  const st = mode === 'deck' && w ? stateOf(w.p1) : null;
  touch.restUpOk = st === 'idle' || st === 'guard';         // a rested up-flick is a Hoho from neutral / guard,
  touch.upHoho = st === 'move' || (!!st && perfectUpP(w!.p1, st, w!.flow === 'battle'));   // any while attacking / perfect
  touch.feed(queue, performance.now());
  queue = [];
  if (!simRunning) { touch.take(); land.take(); }           // menus / pause: no pulse waits for the match
}

/** The pause chip (deck) or button (landscape) was touched this frame. */
export const touchPauseP = (): boolean => (mode === 'deck' && touch.chipHitP(6)) || (mode === 'land' && land.pauseHit());

// ---------------------------------------------------------------- touch -> vpad (G3)
let burst = false;
export const touchRead = {
  /** Start of P1's vpad read: this read's pulses and whether a down-flick is a Burst (P1 in stun / air, or ORANGE). */
  begin(): void {
    touch.take(); land.take();
    const e = W.p1;
    burst = touch.pulseP(TP_FLICK) && touch.flickDownP() && !!e
      && (stateOf(e) === 'stun' || stateOf(e) === 'air' || burstOkP(e) === 'orange');
    if (burst) { touch.spend(); touch.glyph = 7; }            // the contact is spent: no stick, no Step held after it
  },
  /** Is vpad button NAME down from the touch controls (the deck: design §3.2 / §15; or the landscape buttons)? */
  button(name: Action): boolean {
    if (mode === 'land') return land.button(name);
    if (mode !== 'deck') return false;
    const chip = (i: number) => touch.chipDownP(i), pulse = (b: number) => touch.pulseP(b);
    switch (name) {
      case 'guard': return uChipP() ? chip(5) : touch.restingP();
      case 'quick': return pulse(TP_TAP) || burst || chip(7);   // RV: a burst in any mode (the state picks it)
      case 'mod': return burst || pulse(TP_HOHO) || chip(3) || chip(4) || chip(7);
      case 'step': return !burst && (pulse(TP_FLICK) || pulse(TP_HOHO) || touch.stepHeldP());
      case 'flash': return pulse(TP_TAP_HI) || chip(3);
      case 'sig': return chip(1) || chip(4);
      case 'breaker': return chip(2);
      case 'kikon': return chip(0);
      case 'awaken': return !uChipP() && chip(5);
    }
    return false;
  },
  sx: (): number => (mode === 'deck' ? touch.sx() : mode === 'land' ? land.sx : 0),
  sy: (): number => (mode === 'deck' ? touch.sy() : mode === 'land' ? land.sy : 0),
};

// ---------------------------------------------------------------- the landscape two-thumb layer (this build's own)
/** Buttons around the bottom-right corner (CSS px from it: the Q button's centre (72, 72) and three rings, angle 0 = left,
 *  90 = up; scaled down on a short screen so they stay under the HUD), the actions each holds, and a hold time (AWK). */
const LAND_BUTTONS: { label: string; ring: number; ang: number; r: number; acts: Action[]; hold?: number }[] = [
  { label: 'Q', ring: 0, ang: 0, r: 34, acts: ['quick'] },
  { label: 'F', ring: 84, ang: 0, r: 27, acts: ['flash'] }, { label: 'STEP', ring: 84, ang: 45, r: 27, acts: ['step'] },
  { label: 'L', ring: 84, ang: 90, r: 27, acts: ['sig'] },
  { label: 'U', ring: 156, ang: 0, r: 23, acts: ['guard'] }, { label: 'HOHO', ring: 156, ang: 18, r: 21, acts: ['mod', 'step'] },
  { label: 'O', ring: 156, ang: 36, r: 23, acts: ['kikon'] }, { label: 'SP1', ring: 156, ang: 54, r: 21, acts: ['mod', 'flash'] },
  { label: 'SP2', ring: 156, ang: 72, r: 21, acts: ['mod', 'sig'] }, { label: 'I', ring: 156, ang: 90, r: 23, acts: ['breaker'] },
  { label: 'AWK', ring: 222, ang: 25, r: 18, acts: ['awaken'], hold: 300 }, { label: 'RV', ring: 222, ang: 65, r: 18, acts: ['mod', 'quick'] },
];
const STICK_R = 48;
class Land {
  btn: { x: number; y: number; r: number }[] = [];
  pause = { x: 0, y: 0, r: 0 };
  owner = new Map<number, number>();          // finger slot -> button index (-1 the stick, -2 the pause)
  t0 = new Map<number, number>();             // when that finger went down
  latched = 0;                                // buttons touched since the last read (a tap between two reads still counts)
  live = 0;
  stickSlot = -1; ox = 0; oy = 0; x = 0; y = 0; run = false;
  sx = 0; sy = 0;
  pauseHitNow = false;

  layout(): void {
    const d = devicePixelRatio || 1, w = innerWidth * d, h = innerHeight * d, bot = Math.max(8, inset(1)) * d;
    const k = Math.max(0.6, Math.min(1, (innerHeight - 130) / 270)) * d;   // the top ~130 CSS px are the HUD's
    this.btn = LAND_BUTTONS.map((b) => {
      const a = (b.ang * Math.PI) / 180, cx = 72 + b.ring * Math.cos(a), cy = 72 + b.ring * Math.sin(a);
      return { x: w - 8 * d - cx * k, y: h - bot - cy * k, r: b.r * k };
    });
    this.pause = { x: w / 2, y: h - bot - 30 * d, r: 20 * d };          // bottom centre: clear of the timer
    this.clear();
  }
  clear(): void { this.owner.clear(); this.t0.clear(); this.stickSlot = -1; this.run = false; this.sx = this.sy = 0; }
  event(type: number, slot: number, x: number, y: number, ms: number): void {
    if (mode !== 'land') return;
    const d = devicePixelRatio || 1;
    if (type === 0) {
      const hit = (c: { x: number; y: number; r: number }) => Math.hypot(x - c.x, y - c.y) <= c.r + 8 * d;
      const i = this.btn.findIndex(hit);
      if (hit(this.pause)) { this.owner.set(slot, -2); this.pauseHitNow = true; }
      else if (i >= 0) { this.owner.set(slot, i); this.t0.set(slot, ms); if (!LAND_BUTTONS[i].hold) this.latched |= 1 << i; }
      else if (x < innerWidth * d * 0.5) { this.owner.set(slot, -1); this.stickSlot = slot; this.ox = this.x = x; this.oy = this.y = y; }
    } else if (type === 1 && slot === this.stickSlot) { this.x = x; this.y = y; }
    else if (type >= 2) {
      if (slot === this.stickSlot) { this.stickSlot = -1; this.run = false; }
      this.owner.delete(slot); this.t0.delete(slot);
    }
    if (type === 4) this.clear();
  }
  /** This read's buttons and stick (the stick's origin follows the thumb past 2 radii; past 1.6 r Step is held: the run). */
  take(): void {
    const d = devicePixelRatio || 1, r = STICK_R * d, now = performance.now();
    let on = this.latched;
    for (const [slot, i] of this.owner) if (i >= 0 && now - (this.t0.get(slot) ?? now) >= (LAND_BUTTONS[i].hold ?? 0)) on |= 1 << i;
    this.live = on; this.latched = 0;
    if (this.stickSlot < 0) { this.sx = this.sy = 0; return; }
    let dx = this.x - this.ox, dy = this.y - this.oy;
    const m = Math.hypot(dx, dy);
    if (m > 2 * r) { const k = (2 * r) / m; this.ox = this.x - k * dx; this.oy = this.y - k * dy; dx *= k; dy *= k; }
    const mm = Math.min(m, 2 * r);
    this.run = mm >= 1.6 * r || (this.run && mm >= 1.3 * r);
    this.sx = dx / r; this.sy = -dy / r;
  }
  button(a: Action): boolean {
    if (a === 'step' && this.run) return true;
    return LAND_BUTTONS.some((b, i) => (this.live >> i) & 1 && b.acts.includes(a));
  }
  pauseHit(): boolean { const p = this.pauseHitNow; this.pauseHitNow = false; return p; }
  downP(i: number): boolean { for (const [, j] of this.owner) if (j === i) return true; return false; }
}
const land = new Land();

// ---------------------------------------------------------------- drawing (Canvas2D on the HUD canvas, device px)
function ring(g: CanvasRenderingContext2D, x: number, y: number, r: number, wd: number, color: string, fill?: string): void {
  g.beginPath(); g.arc(x, y, r, 0, 2 * Math.PI);
  if (fill) { g.fillStyle = fill; g.fill(); }
  g.lineWidth = wd; g.strokeStyle = color; g.stroke();
}
function label(g: CanvasRenderingContext2D, str: string, x: number, y: number, px: number, color: string, align: CanvasTextAlign = 'center'): void {
  g.font = `600 ${Math.round(px)}px system-ui, "Segoe UI", sans-serif`;
  g.textAlign = align; g.textBaseline = 'middle'; g.fillStyle = color; g.fillText(str, x, y);
}

/** The touch controls of MODE over the battle (not while paused or in a cinematic): the deck (the flow pad, its tap split
 *  F / Q, the chips lit while held, AWAKEN only at EVOLUTION / Bankai ready, RV while a burst is possible, the ink ring
 *  under the thumb, the recognised gesture's glyph for 0.3 s) or the landscape stick and buttons. */
export function drawTouch(g: CanvasRenderingContext2D, w: World): void {
  const d = devicePixelRatio || 1, e = w.p1;
  if (mode === 'deck') {
    const p = touch.pad, left = hand === 'left';
    g.lineWidth = d; g.strokeStyle = 'rgba(255,255,255,0.12)'; g.strokeRect(p[0], p[1], p[2] - p[0], p[3] - p[1]);
    const y = touch.splitY(), x = left ? p[2] - 6 * d : p[0] + 6 * d, al: CanvasTextAlign = left ? 'right' : 'left';
    g.fillStyle = 'rgba(255,255,255,0.18)'; g.fillRect(p[0], y, p[2] - p[0], Math.max(1, d));
    label(g, 'F', x, y - 9 * d, 13 * d, 'rgba(255,255,255,0.4)', al);
    label(g, 'Q', x, y + 10 * d, 13 * d, 'rgba(255,255,255,0.4)', al);
    const u = uChipP(), evo = u || e.g.evolution || bankaiReadyP(e);
    for (let i = 0; i < 8; i++) {
      if (i === 6 || (i === 5 && !evo) || (i === 7 && !burstOkP(e))) continue;   // (6, the pause chip: below)
      const on = touch.chipDownP(i), c = touch.chips, cx = c[3 * i], cy = c[3 * i + 1], r = c[3 * i + 2];
      ring(g, cx, cy, r, 2 * d, on ? 'rgba(255,217,102,1)' : 'rgba(255,140,77,0.7)', `rgba(13,10,18,${on ? 0.85 : 0.45})`);
      label(g, u && i === 5 ? 'U' : CHIP_SPOTS[i][3], cx, cy, (r > 30 * d ? 15 : 12) * d, 'rgba(255,255,255,0.9)');
    }
    if (touch.activeP()) ring(g, touch.ox, touch.oy, 48 * d, 2 * d, `rgba(255,255,255,${touch.restingP() ? 0.35 : 0.6})`);
    const age = performance.now() - touch.glyphT;
    if (age < 300 && touch.glyph > 0) label(g, GLYPH_NAMES[touch.glyph], touch.glyphX, touch.glyphY - 60 * d, 16 * d, 'rgba(255,217,102,1)');
  } else if (mode === 'land') {
    land.btn.forEach((b, i) => {
      if (LAND_BUTTONS[i].label === 'RV' && !burstOkP(e)) return;
      const on = land.downP(i);
      ring(g, b.x, b.y, b.r, 2 * d, on ? 'rgba(255,217,102,1)' : 'rgba(255,140,77,0.6)', `rgba(13,10,18,${on ? 0.8 : 0.4})`);
      label(g, LAND_BUTTONS[i].label, b.x, b.y, (b.r > 28 * d ? 15 : 11) * d, 'rgba(255,255,255,0.9)');
    });
    if (land.stickSlot >= 0) {
      ring(g, land.ox, land.oy, STICK_R * d, 2 * d, 'rgba(255,255,255,0.5)');
      ring(g, land.x, land.y, 14 * d, 2 * d, 'rgba(255,255,255,0.7)', 'rgba(255,255,255,0.2)');
    }
  }
  if (mode !== 'none') {                                     // the pause chip / button
    const c = mode === 'deck' ? { x: touch.chips[18], y: touch.chips[19], r: touch.chips[20] } : land.pause;
    ring(g, c.x, c.y, c.r, 2 * d, 'rgba(255,255,255,0.55)', 'rgba(13,10,18,0.45)');
    label(g, 'II', c.x, c.y, 12 * d, 'rgba(255,255,255,0.9)');
  }
}
