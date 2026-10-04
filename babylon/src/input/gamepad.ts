// gamepad.ts: pad 0 -> P1's vpad buttons and the menu keys (duel/lisp/control.lisp *p1-default-bindings*, :pad), on the
// W3C "standard" mapping: 0 A, 1 B, 2 X, 3 Y, 4 LB, 5 RB, 6 LT, 7 RT, 8 Back, 9 Start, 10 LS, 11 RS, 12-15 D-pad.
import type { Action } from '../sim/vpad';

const PAD: Record<Action, number> = { quick: 2, flash: 3, sig: 1, guard: 4, breaker: 5, kikon: 7, step: 0, mod: 6, awaken: 8 };
// ponytail: the LS+RS Awaken chord is left out (Back covers it); add it with CONTROLS rebinding (M6)
const DEAD = 0.25;

const pad0 = (): Gamepad | null => navigator.getGamepads?.()[0] ?? null;
const on = (p: Gamepad, i: number) => !!p.buttons[i]?.pressed;

export type PadRead = Record<Action, boolean> & { sx: number; sy: number };
/** Pad 0 as P1's buttons and stick (X right, Y up), or null without a pad. */
export function padP1(): PadRead | null {
  const p = pad0();
  if (!p) return null;
  const r = {} as PadRead;
  for (const a of Object.keys(PAD) as Action[]) r[a] = on(p, PAD[a]);
  const ax = p.axes[0] ?? 0, ay = p.axes[1] ?? 0;
  r.sx = (Math.abs(ax) > DEAD ? ax : 0) + (on(p, 15) ? 1 : 0) - (on(p, 14) ? 1 : 0);
  r.sy = (Math.abs(ay) > DEAD ? -ay : 0) + (on(p, 12) ? 1 : 0) - (on(p, 13) ? 1 : 0);
  return r;
}

const MENU: [number, string][] = [[0, 'Enter'], [9, 'Escape'], [1, 'Escape'], [12, 'ArrowUp'], [13, 'ArrowDown'], [14, 'ArrowLeft'], [15, 'ArrowRight']];
let prev: boolean[] = [];
/** Pad buttons that went down since the last call, as key codes (A = Enter, Start / B = Escape, D-pad = arrows). */
export function padMenuPresses(): string[] {
  const p = pad0();
  if (!p) return [];
  const out: string[] = [], now = p.buttons.map((b) => b.pressed);
  for (const [i, code] of MENU) if (now[i] && !prev[i]) out.push(code);
  prev = now;
  return out;
}
