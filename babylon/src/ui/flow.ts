// flow.ts <- duel/lisp/flow.lisp (the screens; its match part is src/sim/match.ts): TITLE -> MODE (VS CPU / ENDLESS /
// PRACTICE / VS PLAYER / CPU VS CPU / SETTINGS / CONTROLS / MANUAL) -> SELECT (P1, P2 or the CPU, the difficulty and,
// VS CPU / PRACTICE with two hands, the camera; both picks stand on the plaza) -> INTRO -> BATTLE (pause: RESUME /
// RESTART / CHARACTER SELECT / TITLE (+ CAMERA); PRACTICE: its options) -> FINISH -> RESULTS (REMATCH / SELECT / TITLE).
// Menus read every device (either player's keys, any pad, taps); fighters only read their vpads. Per frame: flowFrame.
// ponytail: ENDLESS is listed but not ported (its row says so).
import { Match } from '../sim/match';
import { ROSTER, findKit } from '../sim/kit';
import { W, setWorld, type World } from '../sim/types';
import { DUMMIES, P, PRACTICE_HP, konpakuStep, practiceDummy, practiceHooks, practiceReset, practiceSet } from '../sim/practice';
import { T } from '../sim/tuning';
import { takeKeyPresses } from '../input/keyboard';
import { PAD_A, PAD_B, PAD_DOWN, PAD_LEFT, PAD_RIGHT, PAD_START, PAD_UP, takePadPresses } from '../input/gamepad';
import { BIND_ACTIONS, BIND_ROW_NAMES, PAIR, bindLabel, bindableKey, bindablePad, readP1, readP2, rebind, resetBindings,
  saveBindings, type Device } from '../input/bindings';
import { COARSE, oneHandEffectiveP, oneHandOfferedP, portraitP, takeBack, touch, touchPauseP } from '../input/onehand';
import { SETTINGS, onSettings, setSetting, setting } from './settings';
import { nav, refresh, sel as menuSel, show, type Page, type Row } from './menus';

export type Mode = 'vs-cpu' | 'endless' | 'practice' | 'vs-player' | 'cpu-cpu';
type Screen = 'title' | 'mode' | 'settings' | 'controls' | 'select' | 'battle' | 'results';
const DIFFICULTIES = ['easy', 'normal', 'hard'];
const MODE_MENU: [string, Mode | 'settings' | 'controls' | 'manual'][] = [['VS CPU', 'vs-cpu'], ['ENDLESS', 'endless'],
  ['PRACTICE', 'practice'], ['VS PLAYER', 'vs-player'], ['CPU VS CPU', 'cpu-cpu'], ['SETTINGS', 'settings'],
  ['CONTROLS', 'controls'], ['MANUAL', 'manual']];
const GESTURE_CARD: [string, string][] = [['TAP LOW HALF', 'QUICK  (J)'], ['TAP HIGH HALF', 'FLASH  (K)  3 TAPS = STRING'],
  ['HOLD STILL', 'GUARD'], ['DRAG', 'MOVE  (FAR = RUN)'], ['FLICK UP', 'DASH  (KEEP GOING = RUN)'],
  ['FLICK DOWN / SIDE', 'STEP BACK / SIDESTEP'], ['HOLD, THEN FLICK UP', 'HOHO'], ['FLICK DOWN WHEN HIT', 'BURST  (AS YOUR HIT LANDS: CHAIN)'],
  ['O / RV', 'KIKON RUSH (HOLD = KIKON) / REVERSE'], ['L / I', 'SIGNATURE / BREAKER'], ['SP1 / SP2', 'SPECIALS'],
  ['AWK (HOLD)', 'AWAKEN'], ['II / BACK', 'PAUSE']];

export const F = {
  screen: 'title' as Screen,
  ft: 0,                                   // real seconds on the current screen
  mode: 'vs-cpu' as Mode,
  picks: [0, Math.min(1, ROSTER.length - 1)],
  difficulty: 'normal',
  camBehind: true,                         // the CAMERA setting (BEHIND / SIDE)
  oneHand: false,                          // this VS CPU / PRACTICE match is one-handed (the deck)
  match: null as Match | null,             // the battle (or the select screen's preview pair, never stepped)
  paused: false,
  rotate: false,                           // paused because a one-hand match was turned to landscape
  note: '',                                // a transient note on the MODE screen
  bindCol: 0, capture: false,              // CONTROLS: the column (P1 KEY, P1 PAD, P2 KEY, P2 PAD), waiting for a key
  onMatch: (_m: Match | null) => {},       // main.ts: a new world to draw (or none)
};
onSettings(() => { F.camBehind = setting('camera') === 0; if (F.match) setCamBehind(); });

const vsCpuP = () => F.mode === 'vs-cpu' || F.mode === 'endless' || F.mode === 'practice';
const kitName = (i: number) => findKit(ROSTER[i], 'base').name ?? ROSTER[i].toUpperCase();
const wrap = (i: number, n: number) => ((i % n) + n) % n;
/** Humans steer by the behind view only in VS CPU / PRACTICE, always behind one-handed (fighter.lisp *VIEW-BEHIND*). */
function setCamBehind(): void { if (F.match) F.match.w.viewBehind = (F.camBehind || F.oneHand) && vsCpuP(); }
const cameraLabel = () => (F.camBehind ? 'BEHIND' : 'SIDE');
const toggleCam = () => setSetting('camera', F.camBehind ? 1 : 0);

function setScreen(s: Screen, page: (() => Page) | null, row = 0): void {
  F.screen = s; F.ft = 0; F.capture = false;
  show(page, row);
}
function setMatch(m: Match | null): void { F.match = m; F.paused = false; F.rotate = false; F.onMatch(m); }

// ---------------------------------------------------------------- screens
function goTitle(): void {
  setMatch(null);
  setScreen('title', () => ({ title: 'SOUL DUEL', cls: 'title-page', sub: 'A FAN STUDY INSPIRED BY BLEACH: REBIRTH OF SOULS',
    rows: [], foot: COARSE ? 'TAP TO START' : 'PRESS ENTER', tap: () => { if (F.ft > 0.3) goMode(); } }));
}

function goMode(row = 0): void {
  setMatch(null);
  F.note = '';
  setScreen('mode', () => ({
    title: 'MODE', back: goTitle, note: F.note || undefined,
    rows: MODE_MENU.map(([label, k], i): Row => ({ label, act: () => modeChosen(k, i),
      note: k === 'endless' ? 'ENDLESS: NOT IN THIS BUILD YET' : k === 'manual' ? 'THE PLAYER MANUAL (ZH-TW)' : undefined })),
  }), row);
}
function modeChosen(k: Mode | 'settings' | 'controls' | 'manual', i: number): void {
  if (k === 'settings') goSettings();
  else if (k === 'controls') goControls();
  else if (k === 'manual') location.href = 'manual.html';   // the manual's back link returns to ./
  else if (k === 'endless') F.note = 'ENDLESS IS NOT PORTED TO THIS BUILD YET';
  else {
    F.mode = k;
    F.oneHand = i < 3 && oneHandEffectiveP();               // VS CPU / PRACTICE: one-handed where the setting is in effect
    goSelect();
  }
}

function goSettings(): void {
  setScreen('settings', () => ({
    title: 'SETTINGS', back: () => goMode(5),
    rows: [...SETTINGS.map((r): Row => ({
      label: r.label, value: r.opts[setting(r.key)], dir: (d) => setSetting(r.key, setting(r.key) + d),
      note: r.key === 'one-hand' ? `${r.note}. HERE: ${oneHandEffectiveP() ? 'ON' : 'OFF'}` : r.note,
    })), { label: 'BACK', act: () => goMode(5) }],
  }));
}

function goControls(): void {
  if (oneHandOfferedP()) {                                  // a phone: the gestures card
    setScreen('controls', () => ({ title: 'ONE HAND', cls: 'card', back: () => goMode(6), tap: () => goMode(6),
      html: `<dl>${GESTURE_CARD.map(([a, b]) => `<dt>${a}</dt><dd>${b}</dd>`).join('')}</dl>`, rows: [], foot: 'TAP TO GO BACK' }));
    return;
  }
  setScreen('controls', () => ({
    title: 'CONTROLS', cls: 'controls', back: () => goMode(6), col: F.bindCol,
    html: '<div class="heads"><span></span><span>P1 KEY</span><span>P1 PAD</span><span>P2 KEY</span><span>P2 PAD</span></div>',
    note: F.capture ? `PRESS A ${F.bindCol % 2 ? `BUTTON ON PAD ${F.bindCol >> 1}` : 'KEY'} FOR P${(F.bindCol >> 1) + 1} ${BIND_ROW_NAMES[sel()].split('  ')[0]}   (ESC / START: CANCEL)`
      : 'ENTER / CLICK: REBIND   A KEY ALREADY USED SWAPS',
    rows: [...BIND_ACTIONS.map((a, i): Row => ({
      label: BIND_ROW_NAMES[i].split('  ')[0], dir: (d) => { F.bindCol = wrap(F.bindCol + d, 4); },
      cells: [0, 1, 2, 3].map((c) => {
        const dev: Device = c % 2 ? 'pad' : 'key', side = c >> 1;
        return { text: bindLabel(dev, PAIR[side][dev][a]), on: F.capture && F.bindCol === c && sel() === i,
                 act: () => { F.bindCol = c; F.capture = true; } };
      }),
    })), { label: 'RESET DEFAULTS', act: () => { resetBindings(PAIR); saveBindings(); } },
    { label: 'BACK', act: () => goMode(6) }],
  }));
}
const sel = () => menuSel;

/** CONTROLS waiting for a key / button: the first one pressed this frame binds the cell (a swap if taken). */
function captureStep(keys: string[], pads: [number, number][], back: boolean): boolean {
  if (!F.capture) return false;
  const side = F.bindCol >> 1, dev: Device = F.bindCol % 2 ? 'pad' : 'key', a = BIND_ACTIONS[sel()];
  if (back || keys.includes('Escape') || pads.some(([, b]) => b === PAD_START)) F.capture = false;
  else {
    const name = dev === 'key' ? keys.find(bindableKey) : pads.find(([p, b]) => p === side && bindablePad(b))?.[1];
    if (name === undefined) return true;
    rebind(PAIR, side, a, dev, name);
    saveBindings();
    F.capture = false;
  }
  refresh();
  return true;
}

// ---------------------------------------------------------------- select (a preview of both picks on the plaza)
function preview(): void {
  const m = new Match({ p1: ROSTER[F.picks[0]], p2: ROSTER[F.picks[1]], seed: 1, cpu1: true, cpu2: true }).start();
  setMatch(m);
}
function goSelect(): void {
  preview();
  setScreen('select', () => {
    const cpu2 = F.mode !== 'vs-player', cam = vsCpuP() && !F.oneHand;
    const rows: Row[] = [
      { label: F.mode === 'cpu-cpu' ? 'CPU 1' : 'P1', value: kitName(F.picks[0]), dir: (d) => pick(0, d) },
      { label: cpu2 ? 'CPU' : 'P2', value: kitName(F.picks[1]), dir: (d) => pick(1, d) },
    ];
    if (cpu2) rows.push({ label: F.mode === 'practice' ? 'DUMMY CPU' : 'DIFFICULTY', value: F.difficulty.toUpperCase(),
      dir: (d) => { F.difficulty = DIFFICULTIES[wrap(DIFFICULTIES.indexOf(F.difficulty) + d, 3)]; } });
    if (cam) rows.push({ label: 'CAMERA', value: cameraLabel(), dir: toggleCam });
    rows.push({ label: 'FIGHT', cls: 'go', act: startMatch }, { label: 'BACK', act: () => goMode() });
    return { title: MODE_MENU.find(([, k]) => k === F.mode)![0], cls: 'select', back: () => goMode(), rows,
             sub: F.oneHand ? 'ONE-HAND' : undefined };
  }, 0);
}
function pick(side: number, d: number): void { F.picks[side] = wrap(F.picks[side] + d, ROSTER.length); preview(); }

// ---------------------------------------------------------------- battle
function startMatch(): void {
  const human2 = F.mode === 'vs-player', human1 = F.mode !== 'cpu-cpu';
  P.difficulty = F.difficulty;
  const m = new Match({ p1: ROSTER[F.picks[0]], p2: ROSTER[F.picks[1]], seed: Math.floor(Date.now()) % 100000 || 1,
                        cpu1: !human1, cpu2: !human2, difficulty: F.difficulty,
                        readers: [human1 ? readP1 : null, human2 ? readP2 : null],
                        practice: F.mode === 'practice' ? practiceHooks : undefined,
                        learn: (F.mode === 'vs-cpu' || F.mode === 'endless') && setting('learn') === 0 });
  m.start();
  setMatch(m);
  setCamBehind();
  setScreen('battle', null);
}

type PauseKey = 'resume' | 'restart' | 'select' | 'title' | 'camera' | 'reset' | 'dummy' | 'refill' | 'gauges' | 'p1-hp' | 'p1-kon' | 'dm-hp' | 'dm-kon';
function pauseKeys(): PauseKey[] {
  const k: PauseKey[] = F.mode === 'practice' ? ['resume', 'reset', 'dummy', 'refill', 'gauges', 'p1-hp', 'p1-kon', 'dm-hp', 'dm-kon'] : ['resume', 'restart'];
  k.push('select', 'title');
  if (vsCpuP() && !F.oneHand) k.push('camera');
  return k;
}
const ROWS4: PauseKey[] = ['p1-hp', 'p1-kon', 'dm-hp', 'dm-kon'];
function pauseRow(k: PauseKey): Row {
  const w = F.match!.w;
  switch (k) {
    case 'resume': return { label: 'RESUME', act: () => setPaused(false) };
    case 'restart': return { label: 'RESTART', act: startMatch };
    case 'select': return { label: 'CHARACTER SELECT', act: goSelect };
    case 'title': return { label: 'TITLE', act: goTitle };
    case 'camera': return { label: 'CAMERA', value: cameraLabel(), dir: toggleCam };
    case 'reset': return { label: 'RESET POSITION', act: () => { withWorld(w, () => practiceReset(ROSTER[F.picks[0]], ROSTER[F.picks[1]], [readP1, null])); setPaused(false); } };
    case 'dummy': return { label: 'DUMMY', value: DUMMIES.find(([d]) => d === P.dummy)![1],
      dir: (d) => { P.dummy = DUMMIES[wrap(DUMMIES.findIndex(([x]) => x === P.dummy) + d, DUMMIES.length)][0]; withWorld(w, practiceDummy); } };
    case 'refill': return { label: 'HP REFILL', value: P.hpRefill ? 'AUTO' : 'OFF', dir: () => { P.hpRefill = !P.hpRefill; } };
    case 'gauges': return { label: 'GAUGES', value: P.gaugesInf ? 'INFINITE' : 'NORMAL', dir: () => { P.gaugesInf = !P.gaugesInf; } };
    default: {
      const i = ROWS4.indexOf(k), hp = i % 2 === 0;
      return { label: `${i < 2 ? 'P1' : 'DUMMY'} ${hp ? 'HP' : 'KONPAKU'}`, value: `${P.rows[i]}${hp ? '%' : ''}`,
        dir: (d) => {
          P.rows[i] = hp ? PRACTICE_HP[wrap(PRACTICE_HP.indexOf(P.rows[i]) + d, PRACTICE_HP.length)] : konpakuStep(P.rows[i], d, T.konpakuMax);
          withWorld(w, () => practiceSet(i < 2 ? w.p1 : w.p2));   // in force at once
        } };
    }
  }
}
function withWorld(w: World, fn: () => void): void { const old = W; setWorld(w); fn(); setWorld(old); }

function setPaused(on: boolean): void {
  F.paused = on;
  if (!on) F.rotate = false;
  show(on ? () => ({ title: F.rotate ? 'ROTATE TO PORTRAIT' : 'PAUSED', cls: 'pause', back: () => setPaused(false),
                     rows: pauseKeys().map(pauseRow) }) : null);
}

function goResults(): void {
  setScreen('results', () => {
    const w = F.match!.w, win = w.winner === 0 ? w.p1 : w.winner === 1 ? w.p2 : null;
    const val = (side: 0 | 1) => { const g = (side ? w.p2 : w.p1).g; return [g.dealt, g.kikons, g.perfects, g.bestCombo, g.konpaku]; };
    const stats = ['DAMAGE', 'KIKONS', 'PERFECT HOHOS', 'BEST COMBO', 'KONPAKU LEFT'].map((l, i) =>
      `<tr><td>${l}</td><td>${val(0)[i]}</td><td>${val(1)[i]}</td></tr>`).join('');
    const ready = F.ft > 2.5;                               // a masher doesn't skip the results
    return {
      title: win ? 'WINNER' : 'DRAW', cls: 'results',
      sub: win ? `${win.f.kit.name ?? win.f.character.toUpperCase()}  (P${win.f.side + 1})` : undefined,
      html: `<table><tr><th></th><th>P1</th><th>P2</th></tr>${stats}<tr><td>TIME</td><td colspan="2">${Math.round(w.tick / 60)} S</td></tr></table>`,
      rows: ready ? [{ label: 'REMATCH', act: startMatch }, { label: 'CHARACTER SELECT', act: goSelect }, { label: 'TITLE', act: goTitle }] : [],
    };
  });
}

// ---------------------------------------------------------------- per frame
let clicked = false;
addEventListener('click', () => { clicked = true; });
let focusLost = false;
addEventListener('blur', () => { focusLost = true; });
document.addEventListener('visibilitychange', () => { if (document.hidden) focusLost = true; });

const anyPad = (pads: [number, number][], b: number) => pads.some(([, x]) => x === b);
/** Menus, pause and screen timers (once per frame, real time). SIMRUN: may the match's fixed steps run this frame? */
export function flowFrame(rdt: number): void {
  const keys = takeKeyPresses(), pads = takePadPresses(), back = takeBack();
  const tap = touch.tappedP() || clicked;
  clicked = false;
  const lost = focusLost; focusLost = false;
  if (!F.paused) F.ft += rdt;
  if (F.screen === 'controls' && captureStep(keys, pads, back)) return;
  const has = (...c: string[]) => keys.some((k) => c.includes(k));
  const up = has('KeyW', 'ArrowUp') || anyPad(pads, PAD_UP), down = has('KeyS', 'ArrowDown') || anyPad(pads, PAD_DOWN);
  const left = has('KeyA', 'ArrowLeft') || anyPad(pads, PAD_LEFT), right = has('KeyD', 'ArrowRight') || anyPad(pads, PAD_RIGHT);
  const confirm = has('Enter', 'KeyJ', 'Numpad1', 'NumpadEnter') || anyPad(pads, PAD_A);
  const backP = has('Escape', 'KeyK', 'Numpad2') || anyPad(pads, PAD_B) || back;
  const pauseP = has('Escape') || anyPad(pads, PAD_START) || back;
  const m = F.match;
  if (F.screen === 'battle' && m) {
    const w = m.w;
    if (w.flow === 'results') { goResults(); return; }
    if (F.paused) {
      if (F.rotate && portraitP()) { setPaused(false); return; }
      if (pauseP) { setPaused(false); return; }
    } else {
      if ((w.flow === 'intro' || w.flow === 'finish') && w.cine && (pauseP || confirm || tap)) { w.cine.skip = true; return; }
      // battle cinematics (awakening, Kikon, Soul Break) can't be skipped (the user's decision 2026-09-28)
      if (pauseP || lost || touchPauseP() || (F.oneHand && !portraitP())) {
        F.rotate = F.oneHand && !portraitP();
        setPaused(true);
        return;
      }
      return;
    }
  }
  if (F.screen === 'title' && (has('Space') || anyPad(pads, PAD_START)) && F.ft > 0.3) { goMode(); return; }
  if (F.screen === 'results' && (confirm || backP) && F.ft <= 2.5) return;
  if (F.screen === 'results' && F.ft > 2.5 && F.ft - rdt <= 2.5) refresh();   // the rows appear
  for (const [p, a] of [[up, 'up'], [down, 'down'], [left, 'left'], [right, 'right'], [confirm, 'confirm'], [backP, 'back']] as const)
    if (p) nav(a);
}

/** The world on screen and whether its fixed steps run this frame. */
export const simRunning = (): boolean => F.screen === 'battle' && !!F.match && !F.paused && F.match.running();
/** The touch controls this frame: the deck (one-handed), the landscape layer (a touch device, a human P1), or none. */
export function touchMode(): 'none' | 'deck' | 'land' {
  if (F.screen !== 'battle' || !F.match || F.paused || F.match.w.cine) return 'none';
  if (F.oneHand) return 'deck';
  return COARSE && F.mode !== 'cpu-cpu' ? 'land' : 'none';
}
export const practiceP = (): boolean => F.mode === 'practice';

export function startFlow(): void { goTitle(); }
// debug / harness: jump straight to a screen or a match
Object.assign(globalThis, { duelFlow: { F, goMode, goSelect, goSettings, goControls, startMatch, setPaused, touch } });
