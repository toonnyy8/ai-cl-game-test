// keyboard.ts: the keyboard (+ pad 0) -> P1's vpad, and the menu presses. P1's keys are control.lisp's
// *p1-default-bindings*: WASD move, J quick, K flash, L signature, U guard, I breaker, O Kikon rush, Space step,
// Left Shift the Reiatsu modifier, P awaken. The vpad READER runs inside the fixed step (determinism, match.ts pilotRead).
import { VPAD_ACTIONS, type Action, type Vpad } from '../sim/vpad';
import { padMenuPresses, padP1 } from './gamepad';

export const P1_KEYS: Record<Action, string> = {
  quick: 'KeyJ', flash: 'KeyK', sig: 'KeyL', guard: 'KeyU', breaker: 'KeyI', kikon: 'KeyO', step: 'Space', mod: 'ShiftLeft',
  awaken: 'KeyP',
};
const MOVE = ['KeyW', 'KeyA', 'KeyS', 'KeyD'];
const STOP = new Set([...Object.values(P1_KEYS), ...MOVE, 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Enter']);

const down = new Set<string>();
let presses: string[] = [];
addEventListener('keydown', (e) => {
  if (!e.repeat) presses.push(e.code);
  down.add(e.code);
  if (STOP.has(e.code)) e.preventDefault();
});
addEventListener('keyup', (e) => down.delete(e.code));
addEventListener('blur', () => down.clear());

/** Keys (KeyboardEvent.code) and pad menu buttons pressed since the last call. */
export function takePresses(): string[] {
  const p = presses.concat(padMenuPresses());
  presses = [];
  return p;
}

/** P1's device reader: every vpad button and the stick from the keyboard and pad 0. */
export function readP1(vp: Vpad): void {
  const pad = padP1();
  for (const a of VPAD_ACTIONS) vp.set(a, down.has(P1_KEYS[a]) || !!pad?.[a]);
  const k = (c: string) => (down.has(c) ? 1 : 0);
  vp.stick(k('KeyD') - k('KeyA') + (pad?.sx ?? 0), k('KeyW') - k('KeyS') + (pad?.sy ?? 0));
}
