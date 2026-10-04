// bindings.ts <- duel/lisp/control.lisp's device bindings + CONTROLS rebinding (REBIND, RESET-BINDINGS, BIND-LABEL) and
// fighter.lisp's P1-READER / P2-READER. P1: the left keyboard + pad 0 + the touch controls (onehand.ts); P2: arrows +
// numpad + pad 1. Keys are KeyboardEvent.code names, pad buttons standard-mapping indices. Saved in localStorage
// "soulduel.babylon.bind" (JSON of the non-default cells; the Lisp build's codes are SDL names, so not shared).
import { VPAD_ACTIONS, type Action, type Vpad } from '../sim/vpad';
import { keyDown } from './keyboard';
import { PAD_NAMES, padDown, padStick } from './gamepad';
import { stored, store } from '../ui/settings';
import { touchRead } from './onehand';

export type BindAction = 'up' | 'down' | 'left' | 'right' | Action;
/** The CONTROLS rows, in order. */
export const BIND_ACTIONS: BindAction[] = ['up', 'down', 'left', 'right', 'quick', 'flash', 'sig', 'guard', 'breaker', 'kikon', 'step', 'mod', 'awaken'];
export const BIND_ROW_NAMES = ['MOVE UP', 'MOVE DOWN', 'MOVE LEFT', 'MOVE RIGHT', 'QUICK  J', 'FLASH  K', 'SIGNATURE  L', 'GUARD  U',
  'BREAKER  I', 'KIKON RUSH  O', 'STEP  SPACE', 'REIATSU  SHIFT', 'AWAKEN  P'];
export type Device = 'key' | 'pad';
export interface Bindings { key: Record<BindAction, string>; pad: Record<BindAction, number> }

const PAD_DEFAULT: Record<BindAction, number> = { up: 12, down: 13, left: 14, right: 15, quick: 2, flash: 3, sig: 1, guard: 4,
  breaker: 5, kikon: 7, step: 0, mod: 6, awaken: 8 };
export const DEFAULTS: [Bindings, Bindings] = [
  { key: { up: 'KeyW', down: 'KeyS', left: 'KeyA', right: 'KeyD', quick: 'KeyJ', flash: 'KeyK', sig: 'KeyL', guard: 'KeyU',
           breaker: 'KeyI', kikon: 'KeyO', step: 'Space', mod: 'ShiftLeft', awaken: 'KeyP' }, pad: { ...PAD_DEFAULT } },
  { key: { up: 'ArrowUp', down: 'ArrowDown', left: 'ArrowLeft', right: 'ArrowRight', quick: 'Numpad1', flash: 'Numpad2',
           sig: 'Numpad3', guard: 'Numpad4', breaker: 'Numpad5', kikon: 'Numpad6', step: 'Numpad0', mod: 'NumpadEnter',
           awaken: 'NumpadAdd' }, pad: { ...PAD_DEFAULT } },
];
const copy = (b: Bindings): Bindings => ({ key: { ...b.key }, pad: { ...b.pad } });
/** Both players' live bindings (CONTROLS changes them in place). */
export const PAIR: [Bindings, Bindings] = [copy(DEFAULTS[0]), copy(DEFAULTS[1])];
/** Pad buttons that can't be bound (Start: the pause and the cancel); Escape likewise on the keyboard. */
export const bindableKey = (code: string): boolean => code !== 'Escape';
export const bindablePad = (b: number): boolean => b !== 9 && b < PAD_NAMES.length;

/** SIDE's ACTION on DEVICE becomes NAME. An action already on NAME takes ACTION's old one (a swap, never two actions on one
 *  key): on the keyboard over both players' (one keyboard), on a pad over this player's (his own pad). True if changed. */
export function rebind(pair: [Bindings, Bindings], side: number, action: BindAction, device: Device, name: string | number): boolean {
  const map = pair[side][device] as Record<BindAction, string | number>, old = map[action];
  if (old === name) return false;
  for (const s of device === 'key' ? [0, 1] : [side]) {
    const m = pair[s][device] as Record<BindAction, string | number>;
    for (const a of BIND_ACTIONS) if (m[a] === name && !(s === side && a === action)) m[a] = old;
  }
  map[action] = name;
  return true;
}
export function resetBindings(pair: [Bindings, Bindings]): void { pair[0] = copy(DEFAULTS[0]); pair[1] = copy(DEFAULTS[1]); }

const KEY_LABELS: Record<string, string> = { ShiftLeft: 'SHIFT', ShiftRight: 'RSHIFT', ControlLeft: 'CTRL', ControlRight: 'RCTRL',
  AltLeft: 'ALT', AltRight: 'RALT', Enter: 'ENTER', NumpadEnter: 'KP ENTER', NumpadAdd: 'KP +', NumpadSubtract: 'KP -',
  NumpadMultiply: 'KP *', NumpadDivide: 'KP /', NumpadDecimal: 'KP .', BracketLeft: '[', BracketRight: ']', Semicolon: ';',
  Quote: "'", Backquote: '`', Comma: ',', Period: '.', Slash: '/', Backslash: '\\', Minus: '-', Equal: '=' };
/** How a bound key / pad button reads on screen: SHIFT, KP1, D-UP, J ..., "-" for none. */
export function bindLabel(device: Device, name: string | number | undefined): string {
  if (name === undefined || name === '') return '-';
  if (device === 'pad') return PAD_NAMES[name as number] ?? `B${name}`;
  const c = name as string;
  return KEY_LABELS[c] ?? c.replace(/^Key|^Digit/, '').replace(/^Numpad/, 'KP').replace(/^Arrow/, '').toUpperCase();
}

const STORE = 'soulduel.babylon.bind';
export function saveBindings(): void {
  const diff: Record<string, string | number> = {};
  PAIR.forEach((b, s) => (['key', 'pad'] as Device[]).forEach((d) => BIND_ACTIONS.forEach((a) => {
    if (b[d][a] !== DEFAULTS[s][d][a]) diff[`${s}.${d}.${a}`] = b[d][a];
  })));
  store(STORE, JSON.stringify(diff));
}
/** The saved cells, applied as rebinds (a malformed save: the defaults). */
export function loadBindings(): void {
  try {
    const diff = JSON.parse(stored(STORE) ?? '{}') as Record<string, string | number>;
    for (const [k, v] of Object.entries(diff)) {
      const [s, d, a] = k.split('.') as [string, Device, BindAction];
      if ((s === '0' || s === '1') && (d === 'key' || d === 'pad') && BIND_ACTIONS.includes(a) && typeof v === (d === 'key' ? 'string' : 'number'))
        rebind(PAIR, +s, a, d, v);
    }
  } catch { /* the defaults */ }
}
loadBindings();

/** SIDE's binding of ACTION is down (keyboard or his pad; the pad's LS+RS chord is Awaken too). */
export function bindDown(side: number, a: BindAction): boolean {
  const b = PAIR[side];
  return keyDown(b.key[a]) || padDown(side, b.pad[a]) || (a === 'awaken' && padDown(side, 10) && padDown(side, 11));
}
function read(vp: Vpad, side: number, touch: boolean): void {
  if (touch) touchRead.begin();
  for (const a of VPAD_ACTIONS) vp.set(a, bindDown(side, a) || (touch && touchRead.button(a)));
  const [px, py] = padStick(side), k = (a: BindAction) => (bindDown(side, a) ? 1 : 0);
  vp.stick(k('right') - k('left') + px + (touch ? touchRead.sx() : 0), k('up') - k('down') + py + (touch ? touchRead.sy() : 0));
}
/** P1's device reader: his keys, pad 0 and the touch controls. */
export const readP1 = (vp: Vpad): void => read(vp, 0, true);
/** P2's device reader (VS PLAYER): his keys and pad 1. */
export const readP2 = (vp: Vpad): void => read(vp, 1, false);

/** The HUD's prompt for SIDE ("HOLD O  KIKON") from his key binding. */
export const kikonPrompt = (side: number): string => `HOLD ${bindLabel('key', PAIR[side].key.kikon)}  KIKON`;
