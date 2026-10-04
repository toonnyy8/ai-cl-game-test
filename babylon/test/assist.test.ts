// assist.test.ts: ASSIST on a human side (assist.ts) and the learning CPU in a VS CPU match (learn.ts), headless.
import { afterEach, describe, expect, it } from 'vitest';
import '../src/chars';
import { Match } from '../src/sim/match';
import { ASSIST } from '../src/sim/assist';
import { learnDecode, learnEncode, learnTable, learnTables, memoryStore, setLearnStore } from '../src/sim/learn';
import type { Vpad } from '../src/sim/vpad';

/** A human P1 who mashes J (a press every 8 steps) and walks in: the button-masher, by hand. */
const masher = (vp: Vpad) => { vp.set('quick', vp.tick % 8 === 0); vp.stick(0, 1); };

function play(seed: number, learn = false): string[] {
  const m = new Match({ p1: 'kenpachi', p2: 'kenpachi', seed, cpu1: false, cpu2: true, readers: [masher, null], learn }).start();
  m.w.combatLog = [];
  m.runToEnd();
  return [...m.w.combatLog, ...m.takeLog().filter((l) => l.startsWith('duel -> RESULTS'))];
}

afterEach(() => { ASSIST.autoGuard = 0; ASSIST.autoCombo = false; ASSIST.autoBreak = false; });

describe('ASSIST on a human', () => {
  it('off: nothing pressed for him', () => {
    expect(play(1).some((l) => l.includes(' assist '))).toBe(false);
  }, 60_000);
  it('AUTO GUARD ALWAYS: Hohos for him, never PERFECT; the same twice', () => {
    ASSIST.autoGuard = 2;
    const a = play(1);
    expect(a.filter((l) => l.includes('P1 assist hoho')).length).toBeGreaterThan(0);
    expect(a.some((l) => l.includes('P1 PERFECT HOHO'))).toBe(false);   // (he never presses Hoho himself)
    expect(play(1)).toEqual(a);
  }, 60_000);
  it('AUTO COMBO + BREAK: his J becomes K links / the Breaker', () => {
    ASSIST.autoCombo = true; ASSIST.autoBreak = true;
    const a = play(2).join('\n');
    expect(/P1 assist (f|sig|sp2|kikon|burst|breaker)/.test(a)).toBe(true);
  }, 60_000);
});

describe('learning CPU vs a human', () => {
  it('P2 learns, reads him, saves its table; the next match loads it', () => {
    const store = memoryStore();
    setLearnStore(store);
    learnTables.fill(null);
    const a = play(3, true);
    expect(a.some((l) => l.includes('P2 read '))).toBe(true);
    const saved = store.load('soulduel.learn.1');
    expect(saved && saved.length).toBeGreaterThan(5);
    learnTables.fill(null);                                            // (a new session: from the store)
    expect(learnEncode(learnTable(1))).toEqual(learnEncode(learnDecode(saved)));
    setLearnStore(memoryStore()); learnTables.fill(null);
    expect(play(3, true)).toEqual(a);                                  // same seed, same fresh table: the same match
  }, 60_000);
  it('without a learner the match is the plain CPU one', () => {
    learnTables.fill(null);
    expect(play(3).some((l) => l.includes(' read '))).toBe(false);
  }, 60_000);
});
