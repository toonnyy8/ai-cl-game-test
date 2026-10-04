// pose.test.ts: the phase sampler puts the hit pose on the move's frames (u = 1 at frame S, 2 at S + A, 3 at the end).
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { findMove } from '../src/sim/kit';
import { phase } from '../src/render/pose';

describe('pose phase sampler', () => {
  for (const name of ['ya-j1', 'ya-k3', 'ke-k1', 'ke-buttagiru', 'ya-sig', 'ke-flurry']) {
    it(`${name}: u keys land on S, S+A and the end`, () => {
      const mv = findMove(name), { s, a, r } = mv;
      expect(phase(mv, 0).u).toBe(0);
      expect(phase(mv, s).u).toBe(1);
      expect(phase(mv, s + a).u).toBe(2);
      expect(phase(mv, s + a + r).u).toBe(3);
      expect(phase(mv, s - 1).u).toBeLessThan(1);
      expect(phase(mv, s + 1).u).toBeGreaterThan(1);
    });
  }
  it('multi-hit moves key every hit window', () => {
    const mv = findMove('ke-flurry');
    mv.hits.forEach((h, i) => {
      expect(phase(mv, h.from)).toMatchObject({ i, w: 1 });
      expect(phase(mv, h.to - 1).w).toBeGreaterThanOrEqual(1);
    });
    const sig = findMove('ya-sig');
    expect(phase(sig, 28)).toMatchObject({ i: 1, w: 1 });
    expect(phase(sig, 22).i).toBe(1);
    expect(phase(sig, sig.s + sig.a + sig.r).w).toBe(3);
  });
});
