// senjumaru.test.ts: Senjumaru's rules (senjumaru.ts): the stitches, the loom's weave / release, the hanks' scaling,
// the per-fighter state, and a seeded SK match replaying identically.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { findKit } from '../src/sim/kit';
import { Match } from '../src/sim/match';
import { W } from '../src/sim/types';
import { setForm } from '../src/sim/combat';
import { tryCommand } from '../src/sim/fighter';
import {
  SJ, hankDamage, hankLife, hankNext, hariFallsIn, hariSew, hariStep, kasaDamage, loomOkP, sj, tachiAlignedP, tachiHanks,
  weaveAdd, weaveReleaseAct, weaveStored,
} from '../src/chars/senjumaru';
import { findMove } from '../src/sim/kit';

describe('Senjumaru: rules', () => {
  it('sews 2 on a hit, 1 on a block, 0 on a parry, at most 6; they fall after 180 f, then every 30', () => {
    expect(hariSew(0, 'hit')).toBe(2); expect(hariSew(0, 'counter')).toBe(2); expect(hariSew(3, 'blocked')).toBe(4);
    expect(hariSew(3, 'parried')).toBe(3); expect(hariSew(5, 'hit')).toBe(6);
    expect(hariStep(3, 178, false)).toEqual([3, 179, false]);
    expect(hariStep(3, 179, false)).toEqual([2, 180, true]);
    expect(hariStep(2, 209, false)).toEqual([1, 210, true]);
    expect(hariStep(2, 100, true)).toEqual([2, 100, false]);
    expect(hariFallsIn(0)).toBe(180); expect(hariFallsIn(185)).toBe(25);
  });
  it('weaves from the 10th frame (a tap below), a pass per 20 f, at most 3', () => {
    let w = 0;
    for (let h = 1; h <= 9; h++) w = weaveAdd(w, h);
    expect(w).toBe(0);
    for (let h = 10; h <= 60; h++) w = weaveAdd(w, h);
    expect(w).toBe(60); expect(weaveStored(w)).toBe(3);
    expect(weaveReleaseAct(5, 20, false)).toBe('release');
    expect(weaveReleaseAct(5, 19, false)).toBe('refused');
    expect(weaveReleaseAct(5, 40, true)).toBe('refused');
    expect(weaveReleaseAct(30, 0, false)).toBe('stop');
    expect(loomOkP('sig', findMove('sj-kase-3-k'), 0)).toBe(false);
    expect(loomOkP('sig', findMove('sj-kase-3-k'), 20)).toBe(true);
    expect(loomOkP('sig', null, 0)).toBe(true);
  });
  it('queues the hanks 3 2 4 5 1 6, SP1 pairs on even slots, scales in single floats', () => {
    expect([3, 2, 4, 5, 1, 6].map(hankNext)).toEqual([2, 4, 5, 1, 6, 3]);
    expect(tachiAlignedP(3) && tachiAlignedP(4) && tachiAlignedP(1) && !tachiAlignedP(2)).toBe(true);
    expect(tachiHanks(6)).toEqual([6, 3, 2]);
    expect(hankDamage(5, 1)).toBe(32);          // 0.7f0 x 45 = 31.5 in single floats: half-even 32 (doubles: 31)
    expect(hankDamage(2, 3)).toBe(126);
    expect(hankLife(5, 1)).toBe(75);
    expect(kasaDamage(0)).toBe(40); expect(kasaDamage(500)).toBe(SJ.kasaCap);
  });
});

describe('Senjumaru: the fighter', () => {
  it('refuses L at 0 stitches, spends them all as spikes; a fresh state per fighter', () => {
    const m = new Match({ p1: 'senjumaru', p2: 'kenpachi', seed: 1 }).start();
    m.step();
    const e = W.p1;
    e.f.state = 'idle';
    expect(tryCommand(e, e.f, 'sig')).toBe(false);
    e.g.meter = 4;
    expect(tryCommand(e, e.f, 'sig')).toBe(true);
    expect(e.g.meter).toBe(0);
    expect(W.hazards.filter((h) => h.alive && (h.data as { kind: string } | null)?.kind === 'spike')).toHaveLength(4);
    sj(e).woven = 40;
    const m2 = new Match({ p1: 'senjumaru', p2: 'kenpachi', seed: 1 }).start();
    expect(sj(W.p1).woven).toBe(0);
    void m2;
  });
  it('awakens into 黒砂 (tsuji3); a tap with a pass stored unravels the hank and moves the form on', () => {
    expect(findKit('senjumaru', 'base').awakenForm).toBe('tsuji3');
    const m = new Match({ p1: 'senjumaru', p2: 'kenpachi', seed: 1 }).start();
    while (m.w.flow !== 'battle') m.step();                  // (past the intro: the fighters step)
    const e = W.p1;
    setForm(e, 'tsuji3');
    e.f.state = 'idle';
    sj(e).woven = 20;
    expect(tryCommand(e, e.f, 'sig', 'sig')).toBe(true);    // L held 1 f (nobody holds it): a tap, released next step
    for (let i = 0; i < 10; i++) m.step();
    expect(e.f.form).toBe('tsuji2');
    expect(sj(e).live?.alive).toBe(true);
  });
});

describe('Senjumaru: determinism', () => {
  it('replays a seeded SK CPU match identically', () => {
    const run = () => {
      const m = new Match({ p1: 'senjumaru', p2: 'kenpachi', seed: 3, cpu1: true, cpu2: true }).start();
      const out: string[] = [];
      m.runToEnd(60 * 60 * 10, () => { m.takeEvents(); out.push(...m.takeLog()); });
      return out;
    };
    const a = run();
    expect(a.some((l) => l.startsWith('duel -> RESULTS'))).toBe(true);
    expect(run()).toEqual(a);
  });
});
