// f32.test.ts: the Lisp's literals are single floats, so every data table the sim reads is rounded to f32 at load (the
// bit-for-bit check against the native Lisp is tools/parity/parity.py; this only guards the load-time rounding).
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { findKit, findMove } from '../src/sim/kit';
import { BODIES } from '../src/sim/types';
import { weightedPick } from '../src/sim/math';
import { volHitP, makeVol } from '../src/sim/hitvol';
import { IC } from '../src/chars/ichigo';
import { HANKS, SJ } from '../src/chars/senjumaru';

const f = Math.fround;
describe('single-float data', () => {
  it('rounds the character knobs, bodies, move and kit specs', () => {
    expect(IC.walkIchigo).toBe(f(4.2));
    expect(SJ.mirrorK).toBe(f(0.3));
    expect(HANKS[3].away).toBe(f(0.4));
    expect(BODIES.ichigo.hurtR).toBe(f(0.38));
    expect(findMove('ic-k-gaeshi').params.pull).toBe(f(1.6));
    expect(findKit('ichigo', 'base').ai!.guard).toBe(f(0.4));
  });
  it('weighs in single floats', () => {
    // (the f32 sum and subtractions never run past the last key)
    expect(weightedPick(0.999, [['a', 0.1], ['b', 0.2]])).toBe('b');
    expect(weightedPick(0.0, [['a', 0], ['b', 0]])).toBe(null);
  });
  it('tests volumes in single floats: a target exactly at the f32 reach edge touches', () => {
    const v = makeVol(['arc', 1.1, 360, 0, 2]), r = f(f(1.1) + f(0.38));
    expect(volHitP(v, 0, 0, 0, 0, -1, 0, 0, -r, f(0.38), f(1.8), 0)).toBe(true);
    expect(volHitP(v, 0, 0, 0, 0, -1, 0, 0, -(r + 1e-6), f(0.38), f(1.8), 0)).toBe(false);
  });
});
