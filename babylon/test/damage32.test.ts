// The Lisp computes damage in single-float (rules.lisp hit-damage); these cells differ in doubles (Fable's M1 review).
import { describe, expect, it } from 'vitest';
import { hitDamage } from '../src/sim/rules';
import { T } from '../src/sim/tuning';

describe('hitDamage rounds like the f32 Lisp', () => {
  it('45 as combo hit 6 -> 32', () => expect(hitDamage(45, null, null, 6, false)).toBe(32));
  it('30 x Cornered 1.05 -> 31', () => expect(hitDamage(30, { cornered: 0.05, lost: 1, corneredMax: 0.25 }, null, 1, false)).toBe(31));
  it('no scaling stays exact', () => expect(hitDamage(70, null, null, 1, false)).toBe(70));
  it('counter mult applies', () => expect(hitDamage(100, null, null, 1, true)).toBe(Math.round(100 * T.counterMult)));
});
