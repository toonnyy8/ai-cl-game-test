// sinf.ts <- musl's sinf / cosf (src/math/sinf.c cosf.c __sindf.c __cosdf.c __rem_pio2f.c), the libm the Lisp build
// runs on (emscripten's musl; the native gate preloads the same sources, DEVLOG §38). musl's float sine is not always
// correctly rounded (~0.03 % of arguments differ from Math.fround(Math.sin(x)) in the last bit), and the Lisp's facing
// math (fwd-x / fwd-z) runs on it: so the sim does too.
// ponytail: the huge-argument reduction (__rem_pio2_large, |x| >= 2^28 pi/2) isn't ported; sim angles never get there.

const f32 = Math.fround;
const word = new Float32Array(1), bits = new Uint32Array(word.buffer);
const S1 = -0x15555554cbac77 * 2 ** -55, S2 = 0x111110896efbb2 * 2 ** -59;
const S3 = -0x1a00f9e2cae774 * 2 ** -65, S4 = 0x16cd878c3b46a7 * 2 ** -71;
const C0 = -0x1ffffffd0c5e81 * 2 ** -54, C1 = 0x155553e1053a42 * 2 ** -57;
const C2 = -0x16c087e80f1e27 * 2 ** -62, C3 = 0x199342e0ee5069 * 2 ** -68;
const P1 = Math.PI / 2, P2 = 2 * P1, P3 = 3 * P1, P4 = 4 * P1;
const INVPIO2 = 6.36619772367581382433e-01, PIO2_1 = 1.57079631090164184570e+00, PIO2_1T = 1.58932547735281966916e-08;
const TOINT = 1.5 / 2 ** -52, PIO4 = Math.PI / 4;

function sindf(x: number): number {
  const z = x * x, w = z * z, r = S3 + z * S4, s = z * x;
  return f32((x + s * (S1 + z * S2)) + s * w * r);
}
function cosdf(x: number): number {
  const z = x * x, w = z * z, r = C2 + z * C3;
  return f32(((1.0 + z * C0) + w * C1) + (w * z) * r);
}
/** [n, y]: x = n pi/2 + y, |y| <= pi/4 (the medium-size branch). */
function remPio2f(x: number): [number, number] {
  let fn = x * INVPIO2 + TOINT - TOINT, n = fn | 0, y = x - fn * PIO2_1 - fn * PIO2_1T;
  if (y < -PIO4) { n--; fn--; y = x - fn * PIO2_1 - fn * PIO2_1T; }
  else if (y > PIO4) { n++; fn++; y = x - fn * PIO2_1 - fn * PIO2_1T; }
  return [n, y];
}
const ixOf = (x: number): number => { word[0] = x; return bits[0]; };

export function sinf(x0: number): number {
  const x = f32(x0), u = ixOf(x), sign = u >>> 31, ix = u & 0x7fffffff;
  if (ix <= 0x3f490fda) return ix < 0x39800000 ? x : sindf(x);
  if (ix <= 0x407b53d1) {
    if (ix <= 0x4016cbe3) return sign ? -cosdf(x + P1) : cosdf(x - P1);
    return sindf(sign ? -(x + P2) : -(x - P2));
  }
  if (ix <= 0x40e231d5) {
    if (ix <= 0x40afeddf) return sign ? cosdf(x + P3) : -cosdf(x - P3);
    return sindf(sign ? x + P4 : x - P4);
  }
  if (ix >= 0x7f800000) return NaN;
  const [n, y] = remPio2f(x);
  switch (n & 3) { case 0: return sindf(y); case 1: return cosdf(y); case 2: return sindf(-y); default: return -cosdf(y); }
}

export function cosf(x0: number): number {
  const x = f32(x0), u = ixOf(x), sign = u >>> 31, ix = u & 0x7fffffff;
  if (ix <= 0x3f490fda) return ix < 0x39800000 ? 1 : cosdf(x);
  if (ix <= 0x407b53d1) {
    if (ix > 0x4016cbe3) return -cosdf(sign ? x + P2 : x - P2);
    return sign ? sindf(x + P1) : sindf(P1 - x);
  }
  if (ix <= 0x40e231d5) {
    if (ix > 0x40afeddf) return cosdf(sign ? x + P4 : x - P4);
    return sign ? sindf(-x - P3) : sindf(x - P3);
  }
  if (ix >= 0x7f800000) return NaN;
  const [n, y] = remPio2f(x);
  switch (n & 3) { case 0: return cosdf(y); case 1: return sindf(-y); case 2: return -cosdf(y); default: return sindf(y); }
}
