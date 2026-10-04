// The cinematics' shot scripts (render/cine-scripts.ts) against the sim's clock (CINES in src/sim/match.ts): every cine
// has a script whose shots sum exactly to its len, and every timed beat lies inside it.
import { describe, expect, it } from 'vitest';
import { CINES } from '../src/sim/match';
import { SCRIPTS, on, pair } from '../src/render/cine-scripts';
import { CAPS } from '../src/render/vfx/card';

describe('cinematic shot scripts', () => {
  it('cover every CINES entry and nothing else', () => {
    expect(Object.keys(SCRIPTS).sort()).toEqual(Object.keys(CINES).sort());
  });
  for (const [name, c] of Object.entries(CINES)) {
    it(`${name}: shots sum to len ${c.len}`, () => {
      const s = SCRIPTS[name];
      expect(s.shots.reduce((n, sh) => n + sh[0], 0)).toBe(c.len);
      for (const sh of s.shots) expect(sh[0]).toBeGreaterThan(0);
    });
    it(`${name}: beats inside the cine`, () => {
      const s = SCRIPTS[name], inside = (f: number) => f >= 0 && f < c.len;
      const frames = [...(s.imp ?? []).map((x) => x[0]), ...(s.hold ?? []).map((x) => x[0]), ...(s.sparks ?? []).map((x) => x[0]),
        ...(s.caps ?? []).map((x) => x[0]), ...(s.act?.a ?? []).map((x) => x[0]), ...(s.act?.v ?? []).map((x) => x[0]),
        ...(s.hz ?? []).map((x) => x.from), ...(s.splash ?? []).map((x) => x[0]), ...(s.shake ?? []).map((x) => x[0])];
      for (const f of frames) expect(inside(f), `frame ${f}`).toBe(true);
      for (const [from, to, , cap] of s.caps ?? []) {
        expect(to).toBeGreaterThan(from);
        if (cap === undefined) expect(CAPS[name], 'a caption card').toBeDefined();
      }
      for (const who of ['a', 'v'] as const) {
        const acts = s.act?.[who] ?? [];
        for (let i = 1; i < acts.length; i++) expect(acts[i][0]).toBeGreaterThan(acts[i - 1][0]);
      }
    });
  }
  it('rails follow the actors', () => {
    const c = { a: { pos: [0, 0, 0], yaw: 0 }, v: { pos: [0, 0, -3], yaw: Math.PI }, side: 1 };
    const front = on('a', 0, 4, 1.5)(c, 0);                           // in front of A (yaw 0 faces -z)
    expect(front.eye[2]).toBeCloseTo(-4); expect(front.at).toEqual([0, 1.1, 0]);
    const right = on('a', 0, 4, 1.5, { off: 1 })(c, 0);                // OFF > 0: A in the right part of the frame
    expect(right.at[0]).toBeCloseTo(1);                                // (the aim moves to +x: the left of a camera facing +z)
    const p = pair(1, 6, 2)(c, 0);
    expect(Math.hypot(p.eye[0], p.eye[2] + 1.5)).toBeCloseTo(6);
  });
});
