// gamepad.ts: the raw pads (W3C "standard" mapping): 0 A, 1 B, 2 X, 3 Y, 4 LB, 5 RB, 6 LT, 7 RT, 8 Back, 9 Start,
// 10 LS, 11 RS, 12-15 D-pad up / down / left / right. Buttons held now, the left stick, and the presses since the last
// frame (pads 0..3). What a button means is bindings.ts'.
export const PAD_NAMES = ['A', 'B', 'X', 'Y', 'LB', 'RB', 'LT', 'RT', 'BACK', 'START', 'LS', 'RS', 'D-UP', 'D-DOWN', 'D-LEFT', 'D-RIGHT'];
export const PAD_A = 0, PAD_B = 1, PAD_START = 9, PAD_UP = 12, PAD_DOWN = 13, PAD_LEFT = 14, PAD_RIGHT = 15;
const DEAD = 0.25;

const pad = (i: number): Gamepad | null => navigator.getGamepads?.()[i] ?? null;
export const padConnected = (i: number): boolean => !!pad(i);
export const padDown = (i: number, b: number): boolean => !!pad(i)?.buttons[b]?.pressed;
/** Pad I's left stick, X right, Y up (0 inside the dead zone). */
export function padStick(i: number): [number, number] {
  const p = pad(i);
  if (!p) return [0, 0];
  const ax = p.axes[0] ?? 0, ay = p.axes[1] ?? 0;
  return [Math.abs(ax) > DEAD ? ax : 0, Math.abs(ay) > DEAD ? -ay : 0];
}

const prev: boolean[][] = [[], [], [], []];
/** Pad buttons that went down since the last call: [pad, button]. */
export function takePadPresses(): [number, number][] {
  const out: [number, number][] = [];
  for (let i = 0; i < 4; i++) {
    const p = pad(i), now = p ? p.buttons.map((b) => b.pressed) : [];
    now.forEach((d, b) => { if (d && !prev[i][b]) out.push([i, b]); });
    prev[i] = now;
  }
  return out;
}
