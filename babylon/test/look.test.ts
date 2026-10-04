// look.test.ts: B2-look's pure rules: lit / shadow pairs (body.ts), the pair camera's framing bounds and kicks (camera.ts).
import { expect, it } from 'vitest';
import { Vector3 } from '@babylonjs/core';
import { hex, litOf, pair, shadeOf } from '../src/render/body';
import { DuelCamera } from '../src/render/camera';
import type { World } from '../src/sim/types';

it('colour pairs: registered, tuple and derived shadows', () => {
  const lit = pair(0x123456, 0x010203);
  expect(shadeOf(lit).equals(hex(0x010203))).toBe(true);
  expect(shadeOf([0xffffff, 0x808080]).equals(hex(0x808080))).toBe(true);
  expect(litOf([0xffffff, 0x808080]).equals(hex(0xffffff))).toBe(true);
  const warm = shadeOf(0xf0c0a0), cool = shadeOf(0xe0e0e0);
  expect(warm.r - warm.b).toBeGreaterThan(0.2);          // skin keeps a warm shadow
  expect(cool.b).toBeGreaterThan(cool.r);                // cloth turns cool
});

const world = (sep: number, h1 = 1.65, h2 = 2.0) => ({
  p1: { pos: [-sep / 2, 0, 0], body: { hurtH: h1, hurtR: 0.35 } }, p2: { pos: [sep / 2, 0, 0], body: { hurtH: h2, hurtR: 0.4 } },
  viewX: 0, viewZ: 1, viewBehind: false, cine: null, behindYaw: 0,
}) as unknown as World;
const frac = (c: DuelCamera, x: number, h: number) => {
  const d = Vector3.Distance(c.eye, new Vector3(x, h / 2, 0));
  return h / (2 * d * Math.tan(25 * Math.PI / 180));
};

it('pair camera: the shorter >= 35 % and the taller <= 60 % while both fit across', () => {
  for (const sep of [1, 2, 3, 4, 5, 6]) {
    const c = new DuelCamera(); c.update(world(sep), 1 / 60);
    expect(frac(c, -sep / 2, 1.65), `sep ${sep}`).toBeGreaterThan(0.33);
    expect(frac(c, sep / 2, 2.0), `sep ${sep}`).toBeLessThan(0.62);
  }
});

it('kicks: a hit shakes for 8 frames, a Kikon punches in 6 %, both deterministic', () => {
  const run = () => {
    const c = new DuelCamera(), w = world(3), out: number[] = [];
    c.update(w, 1 / 60);
    const base = c.eye.subtract(c.at).length();
    c.events([{ kind: 'kikon', tick: 0, args: [0, 1] }]);
    for (let i = 0; i < 3; i++) c.update(w, 1 / 60);
    out.push(c.eye.subtract(c.at).length() / base);
    c.events([{ kind: 'hit', tick: 0, args: [0, 1, 0, 1, 0, 8, false, 200] }]);
    c.update(w, 1 / 60); out.push(c.shakeT);
    for (let i = 0; i < 10; i++) c.update(w, 1 / 60);
    out.push(c.shakeT);
    return out;
  };
  const a = run();
  expect(a[0]).toBeLessThan(0.97); expect(a[0]).toBeGreaterThan(0.93);
  expect(a[1]).toBeGreaterThan(0); expect(a[2]).toBe(0);
  expect(run()).toEqual(a);
});
