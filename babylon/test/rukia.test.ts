// rukia.test.ts: Rukia's forms (rukia.ts): the bands' derivation, the Hoho's cold, absolute zero's entry, the CRACK,
// the cold gauge's single floats.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { T } from '../src/sim/tuning';
import { callHook, findKit, kitMove } from '../src/sim/kit';
import { tempNext } from '../src/sim/rules';
import { Match } from '../src/sim/match';
import { W } from '../src/sim/types';
import { setForm, tempStep } from '../src/sim/combat';

/** An RR match past its intro, P1 free in FORM with cold C. */
function ru(form: string, c = 0) {
  const m = new Match({ p1: 'rukia', p2: 'rukia', seed: 1 }).start();
  m.step();
  const e = W.p1;
  setForm(e, form);
  e.f.state = 'idle'; e.g.meter = c; e.g.meterIdle = 0;
  return e;
}

describe('Rukia: kits', () => {
  it('derives -50 at x1.1 and zero at x1.35; their own links as written', () => {
    expect(kitMove(findKit('rukia', 'm50'), 'ru-j1').reach).toBeCloseTo(1.44 * 1.1);
    expect(kitMove(findKit('rukia', 'zero'), 'ru-j1').reach).toBeCloseTo(1.44 * 1.35);
    expect(kitMove(findKit('rukia', 'zero'), 'ru-z-j2').reach).toBeCloseTo(1.78);
    const z = findKit('rukia', 'zero');
    expect(z.rooted).toBe(true);
    expect(z.commands.breaker).toBeNull();
    expect(z.passives).toEqual(['ward', 'freeze-touch', 'chipless']);
    expect(findKit('rukia', 'm50').hooks?.hoho).toBe('rukia-hoho-cold');   // inherited from -18
  });
});

describe('Rukia: the cold', () => {
  it('a Hoho adds 50 and the band follows at once: -50 at 150 lands at absolute zero, the ward up', () => {
    const e = ru('m50', 150);
    e.f.state = 'hoho';
    callHook('rukia-hoho-cold', e);
    expect(e.g.meter).toBe(200);
    expect(e.f.form).toBe('zero');
    expect(e.f.guardT).toBe(T.guardRaise);
  });
  it('no cold from a Hoho in the THAW', () => {
    const e = ru('m18', 60);
    e.g.meterIdle = 5;
    callHook('rukia-hoho-cold', e);
    expect(e.g.meter).toBe(60);
  });
  it('the CRACK empties the gauge, drops to -18, burns and crumples, starts the THAW', () => {
    const e = ru('zero', 200);
    const r = e.g.reishi;
    callHook('rukia-crack', e);
    expect(e.f.form).toBe('m18');
    expect(e.g.meter).toBe(0);
    expect(e.g.meterIdle).toBe(T.ruThawLock);
    expect(e.g.reishi).toBe(r - T.crackSelf);
    expect(e.f.state).toBe('stun');
  });
  it('the gauge counts in single floats (as the Lisp slot) and warming re-resolves the band', () => {
    expect(tempNext(0.5, false, T.ruWarmM18)).toBe(Math.fround(0.5 - Math.fround(T.ruWarmM18 / 60)));
    const e = ru('m50', 0.05);
    tempStep(e, e.f, e.g);
    expect(e.g.meter).toBe(0);
    expect(e.f.form).toBe('m18');
  });
});
