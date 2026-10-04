// platform.test.ts: the platform rules ported with M6b: control.lisp REBIND / RESET-BINDINGS (a swap, never two actions
// on one key; the keyboard swaps across both players, a pad only within its player), ONE-HAND-ON-P (DUEL_MOBILE_DESIGN
// §16's table), DUMMY-GUARD-LEFT, KONPAKU-STEP, PRACTICE-REISHI, the settings' page decoding.
import { beforeAll, describe, expect, it, vi } from 'vitest';
import { oneHandOnP, settingFromPage, SETTINGS } from '../src/ui/settings';
import { dummyGuardLeft, konpakuStep, practiceReishi } from '../src/sim/practice';

let B: typeof import('../src/input/bindings');
beforeAll(async () => {                       // the input modules listen on the window: stub it for node
  vi.stubGlobal('addEventListener', () => {});
  vi.stubGlobal('document', { addEventListener: () => {} });
  B = await import('../src/input/bindings');
});

describe('CONTROLS rebinding', () => {
  it('a taken key swaps, across both players', () => {
    const pair = [structuredClone(B.DEFAULTS[0]), structuredClone(B.DEFAULTS[1])] as typeof B.PAIR;
    expect(B.rebind(pair, 0, 'quick', 'key', 'KeyK')).toBe(true);
    expect([pair[0].key.quick, pair[0].key.flash]).toEqual(['KeyK', 'KeyJ']);
    B.rebind(pair, 0, 'guard', 'key', 'ArrowUp');                    // P2's key: P2's up takes P1's old guard key
    expect([pair[0].key.guard, pair[1].key.up]).toEqual(['ArrowUp', 'KeyU']);
    expect(B.rebind(pair, 0, 'guard', 'key', 'ArrowUp')).toBe(false);
  });
  it('a pad button swaps only within its player', () => {
    const pair = [structuredClone(B.DEFAULTS[0]), structuredClone(B.DEFAULTS[1])] as typeof B.PAIR;
    B.rebind(pair, 1, 'quick', 'pad', 3);
    expect([pair[1].pad.quick, pair[1].pad.flash, pair[0].pad.flash]).toEqual([3, 2, 3]);
    B.resetBindings(pair);
    expect(pair[1].pad.quick).toBe(2);
  });
  it('labels', () => {
    expect(['ShiftLeft', 'KeyJ', 'Numpad1', 'ArrowUp', 'Space', 'NumpadAdd'].map((k) => B.bindLabel('key', k)))
      .toEqual(['SHIFT', 'J', 'KP1', 'UP', 'SPACE', 'KP +']);
    expect(B.bindLabel('pad', 12)).toBe('D-UP');
  });
});

describe('ONE-HAND and SETTINGS', () => {
  it('one-hand-on-p: AUTO coarse + portrait only; ON wherever offered; OFF never', () => {
    const t = (c: number) => [[true, true], [true, false], [false, true], [false, false]].map(([co, p]) => oneHandOnP(c, co, p));
    expect(t(0)).toEqual([true, false, false, false]);
    expect(t(1)).toEqual([true, true, true, false]);
    expect(t(2)).toEqual([false, false, false, false]);
  });
  it('page values: option + 1, 0 / out of range = the default', () => {
    const split = SETTINGS.find((r) => r.key === 'tap-split')!;
    expect([0, 1, 5, 6, -1].map((v) => settingFromPage(split, v))).toEqual([2, 0, 4, 2, 2]);
  });
});

describe('PRACTICE', () => {
  it('dummy guard', () => {
    expect(dummyGuardLeft('guard-all', 'idle', 0)).toBe(999);
    expect(dummyGuardLeft('guard-hit', 'stun', 0)).toBe(60);
    expect(dummyGuardLeft('guard-hit', 'idle', 10)).toBe(9);
    expect(dummyGuardLeft('guard-hit', 'idle', 0)).toBe(0);
    expect(dummyGuardLeft('stand', 'stun', 5)).toBe(0);
    expect(dummyGuardLeft('cpu', 'stun', 5)).toBe(0);
  });
  it('rows', () => {
    expect([konpakuStep(9, 1, 9), konpakuStep(1, -1, 9), konpakuStep(4, 1, 9)]).toEqual([1, 9, 5]);
    expect([practiceReishi(1000, 10), practiceReishi(3, 10), practiceReishi(999, 75)]).toEqual([100, 1, 750]);
  });
});
