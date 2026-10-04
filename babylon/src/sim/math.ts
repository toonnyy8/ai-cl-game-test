// math.ts <- engine/lisp/math.lisp (the scalar / facing part the sim needs) + engine/lisp/package.lisp's CLAMP / LERP,
// and the CL number semantics the translation leans on. Y up, metres, radians. Yaw 0 faces -Z; the facing direction is
// (fwdX yaw, 0, fwdZ yaw) = (-sin yaw, 0, -cos yaw).

// the Lisp's angles are single floats (engine math.lisp, rules.lisp +pi+ / +two-pi+): the constants and the facing helpers
// round to f32 like it, so a turn decided at +-pi (the short way round) goes the same way
import { cosf, sinf } from './sinf';
export const f32 = Math.fround;
/** The length of (DX DZ) in single floats, op by op, as the Lisp's (sqrt (+ (* dx dx) (* dz dz))) on singles. */
export const len32 = (dx: number, dz: number): number => f32(Math.sqrt(f32(f32(dx * dx) + f32(dz * dz))));
export const PI = f32(Math.PI);
export const TWO_PI = f32(2 * Math.PI);

/** CL ROUND: round half to even (the Lisp's every ROUND; JS Math.round rounds half up). */
export function roundHalfEven(x: number): number {
  const f = Math.floor(x);
  const d = x - f;
  if (d < 0.5) return f;
  if (d > 0.5) return f + 1;
  return f % 2 === 0 ? f : f + 1;
}
/** CL MOD (the result has the divisor's sign). */
export const mod = (a: number, n: number): number => ((a % n) + n) % n;
/** CL (FLOOR a b) as an integer quotient. */
export const floorDiv = (a: number, b: number): number => Math.floor(a / b);
/** CL (CEILING a b) as an integer quotient. */
export const ceilDiv = (a: number, b: number): number => Math.ceil(a / b);

export const deg = (d: number): number => f32(f32(d) * f32(Math.PI / 180));
export const clamp = (x: number, lo: number, hi: number): number => Math.max(lo, Math.min(hi, x));
export const lerp = (a: number, b: number, u: number): number => Math.fround(a + Math.fround(Math.fround(b - a) * u));   // (singles)

/** Wrap angle into [-pi, pi). */
export function angleWrap(a: number): number {
  const x = f32(a);
  return f32(x - f32(TWO_PI * Math.floor(f32(f32(x + PI) / TWO_PI))));
}
export const fwdX = (yaw: number): number => -sinf(yaw);   // (musl sinf, as the Lisp build)
export const fwdZ = (yaw: number): number => -cosf(yaw);
/** Angle CUR turned toward TARGET by at most STEP radians (the short way round). */
export function turnToward(cur: number, target: number, step: number): number {
  return f32(cur + clamp(angleWrap(target - cur), -step, step));
}

/** KV = key weight ...; the key whose share of the total weight contains R (0 <= R < 1); null if all weights are 0. */
export function weightedPick<K>(r: number, kv: [K, number][]): K | null {
  let sum = 0;
  for (const [, w] of kv) sum += w;
  if (sum > 0) {
    let x = sum * r;
    for (const [k, w] of kv) {
      x -= w;
      if (x < 0 && w > 0) return k;
    }
  }
  return null;
}

/** GETF on a tuning plist (an object): KEY's number, else DFLT. */
export function getf<V = number>(plist: object | null | undefined, key: string, dflt: V): V {
  if (!plist) return dflt;
  const v = (plist as Record<string, V | undefined>)[key];
  return v === undefined ? dflt : v;
}
