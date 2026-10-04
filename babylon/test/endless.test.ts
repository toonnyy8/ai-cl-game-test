// endless.test.ts <- tests/duel-rules-test.lisp's ENDLESS section (endless-rules.lisp), check for check, plus the run
// itself (endless.ts): a seeded autopilot run replays, and the record is the page's slots.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { T } from '../src/sim/tuning';
import { ROSTER, findKit, type Kit } from '../src/sim/kit';
import { bankaiAllowedP } from '../src/sim/rules';
import * as E from '../src/sim/endless-rules';
import { autoRun, endlessBest, memoryEndlessStore, setEndlessStore, Run } from '../src/sim/endless';

const ck = (c: unknown, label = ''): void => expect(!!c, label).toBe(true);
const kit = (c: string, f: string): Kit => findKit(c, f);
const FORMS: [string, string][] = [['yamamoto', 'base'], ['yamamoto', 'hellfire'], ['yamamoto', 'bankai-east'],
  ['yamamoto', 'bankai-west'], ['kenpachi', 'base'], ['kenpachi', 'nozarashi'], ['kenpachi', 'ryote'],
  ['kenpachi', 'nomihose'], ['kenpachi', 'bankai'], ['kenpachi', 'kataude'], ['rukia', 'base'], ['rukia', 'm18'],
  ['rukia', 'm50'], ['rukia', 'zero'], ['ichigo', 'base'], ['ichigo', 'kessa'], ['senjumaru', 'base'],
  ['senjumaru', 'tsuji1'], ['senjumaru', 'tsuji2'], ['senjumaru', 'tsuji3'], ['senjumaru', 'tsuji4'],
  ['senjumaru', 'tsuji5'], ['senjumaru', 'tsuji6']];
const snap = (c: string, f: string, kv: Partial<E.EndlessSnap> = {}): E.EndlessSnap =>
  ({ character: c, form: f, konpaku: 5, reiatsu: 123.5, fs: 42.25, awaken: 37.0, awakened: kit(c, f).awakening, meter: 55.0, ...kv });
const carry = (c: string, f: string, choice: 'stay' | 'revert', kv: Partial<E.EndlessSnap> = {}) => E.endlessCarry(snap(c, f, kv), choice);

describe('ENDLESS rules (endless-rules.lisp)', () => {
  it('carry: Konpaku + 2 at most 9, Reiatsu and flash step kept', () => {
    expect([1, 7, 8, 9].map((k) => carry('yamamoto', 'base', 'stay', { konpaku: k }).konpaku)).toEqual([3, 9, 9, 9]);
    ck(FORMS.every(([c, f]) => { const r = carry(c, f, 'stay'); return r.reiatsu === 123.5 && r.fs === 42.25; }));
  });
  it('carry: not awakened keeps the gauge and Inferno; Hellfire ends like its timer', () => {
    const r = carry('yamamoto', 'base', 'stay');
    ck(r.form === 'base' && r.awaken === 37 && !r.awakened && r.meter === 55);
    const h = carry('yamamoto', 'hellfire', 'stay');
    ck(h.form === 'base' && h.awaken === 37 && h.meter === 0);
  });
  it('carry: revert from every awakened form', () => {
    ck(FORMS.filter(([c, f]) => kit(c, f).awakening).every(([c, f]) => {
      const r = carry(c, f, 'revert');
      return r.form === 'base' && !r.awakened && r.awaken === T.awakenMax && r.meter === 0;
    }));
  });
  it('carry: stay targets (East, cup 1 at NOME 10, -18 at cold 0)', () => {
    ck(['bankai-east', 'bankai-west'].every((f) => carry('yamamoto', f, 'stay').form === 'bankai-east'));
    ck(['nozarashi', 'ryote', 'nomihose', 'bankai', 'kataude'].every((f) => {
      const r = carry('kenpachi', f, 'stay');
      return r.form === 'nozarashi' && r.meter === T.nomeAwaken && r.awakened && r.awaken === 0;
    }));
    ck(['m18', 'm50', 'zero'].every((f) => { const r = carry('rukia', f, 'stay'); return r.form === 'm18' && r.meter === 0; }));
    ck(carry('kenpachi', 'base', 'stay').form === 'base');
  });
  it('generic guards: stay targets are awakened, never a second form, never timed', () => {
    const targets = FORMS.filter(([c, f]) => kit(c, f).awakening).map(([c, f]) => [c, E.endlessStayForm(kit(c, f))] as const);
    const second: string[] = [];
    for (const [c, f] of FORMS) {
      const k = kit(c, f);
      if (k.bankaiForm) second.push(`${c} ${k.bankaiForm}`);
      if (k.pips) second.push(`${c} ${k.pips.to}`);
    }
    ck(targets.every(([c, f]) => kit(c, f).awakening));
    ck(!targets.some(([c, f]) => second.includes(`${c} ${f}`)));
    ck(FORMS.filter(([c, f]) => kit(c, f).duration).every(([c, f]) => !kit(c, E.endlessStayForm(kit(c, f))).duration));
  });
  it('§5: a Bankai at Konpaku 4 leaves 1, the clear gives 3, cup 3 may Bankai again at 3', () => {
    ck(carry('kenpachi', 'bankai', 'stay', { konpaku: 1 }).konpaku === 3 && bankaiAllowedP(true, 3));
  });
  it('the ramp', () => {
    const fl = ['easy', 'normal', 'hard'];
    ck(fl.every((f) => { let d0 = -1; for (let n = 1; n <= 40; n++) { const d = fl.indexOf(E.endlessDifficulty(f, n)); if (d < d0) return false; d0 = d; } return true; }));
    ck(E.endlessDifficulty('easy', 5) === 'hard' && E.endlessDifficulty('easy', 3) === 'normal' && E.endlessDifficulty('normal', 3) === 'hard'
       && E.endlessDifficulty('easy', 1) === 'easy' && E.endlessDifficulty('hard', 1) === 'hard');
    for (let n = 12; n <= 60; n++) expect(E.endlessRamp(n)).toEqual(E.endlessRamp(12));
    for (let n = 2; n <= 40; n++) {
      const r = E.endlessRamp(n), r0 = E.endlessRamp(n - 1);
      ck(r[2] >= r0[2] && (r[3] || !r0[3]) && r[4] >= r0[4]);
    }
    expect([4, 5, 7, 9].map((n) => E.endlessRamp(n)[2])).toEqual([0, 50, 100, 100]);
    ck(!E.endlessRamp(8)[3] && E.endlessRamp(9)[3] && E.endlessRamp(11)[4] === 110 && E.endlessRamp(12)[4] === 120);
  });
  it('the bag: each bag the roster once, never twice in a row, replays, seeds differ', () => {
    const run = <C>(seed: number, n: number, roster: readonly C[]) => Array.from({ length: n }, (_, s) => E.endlessOpponent(seed, s + 1, roster));
    for (const roster of [ROSTER, ['a', 'b'], ['a', 'b', 'c', 'd', 'e']] as string[][]) {
      const n = roster.length;
      for (let seed = 1; seed <= 200; seed++) {
        const r = run(seed, 6 * n, roster);
        for (let b = 0; b < 6; b++) expect([...r.slice(b * n, (b + 1) * n)].sort()).toEqual([...roster].sort());
        for (let i = 1; i < r.length; i++) expect(r[i]).not.toBe(r[i - 1]);
      }
    }
    expect(run(7, 12, ROSTER)).toEqual(run(7, 12, ROSTER));
    ck(new Set(Array.from({ length: 20 }, (_, s) => run(s + 1, 3, ROSTER).join())).size > 2);
  });
  it('the LCG is the Lisp one (exact mod 2^31)', () => {
    for (const x of [0, 1, 12345, 2147483647, 791900001, 1103515245])
      expect(E.endlessLcg(x)).toBe(Number((BigInt(x) * 1103515245n + 12345n) % 2147483648n));
  });
  it('stage seeds and the record', () => {
    const a = E.endlessStageSeed(1, 2), b = E.endlessStageSeed(1, 3), c = E.endlessStageSeed(2, 2);
    ck(a !== b && b !== c);
    ck(E.endlessBetterP(3, 500, 2, 100) && !E.endlessBetterP(2, 50, 3, 900) && E.endlessBetterP(3, 400, 3, 500)
       && !E.endlessBetterP(3, 500, 3, 500) && !E.endlessBetterP(3, 600, 3, 500) && E.endlessBetterP(1, 999, 0, 0)
       && !E.endlessBetterP(0, 10, 0, 0));
  });
});

describe('ENDLESS run (endless.ts)', () => {
  it('an autopilot run replays and writes the record slots only outside debug', () => {
    const a = autoRun('rukia', 3, 'stay', 3), b = autoRun('rukia', 3, 'stay', 3);
    expect(a.log).toEqual(b.log);
    ck(a.log.some((l) => l.startsWith('duel endless stage 1 ')));
    const mem = memoryEndlessStore();
    setEndlessStore(mem);
    const r = new Run('rukia', 'normal', 5);
    r.cleared = 2; r.ticks = 6000; r.saveRecord();
    expect(endlessBest('rukia')).toEqual([2, 100]);
    expect(mem.get('soulduel.endless.4')).toBe(2);      // rukia = roster index 2: slots 30 + 4 / 31 + 4
    r.cleared = 1; r.saveRecord();
    expect(endlessBest('rukia')).toEqual([2, 100]);
  });
  it('STAGE CLEAR: the rows and the CONTINUE note name the carried form', () => {
    const r = new Run('kenpachi', 'easy', 3);
    r.stage = 4; r.cleared = 4; r.ticks = 7230; r.stageTicks = 1800;
    r.snap = snap('kenpachi', 'bankai', { konpaku: 1 });
    r.clearLines();
    const l = r.clear!;
    expect(l.rows).toEqual(['stay', 'revert', 'quit']);
    expect(l.notes[0]).toBe(`${kit('kenpachi', 'bankai').formName} -> ${kit('kenpachi', 'nozarashi').formName}`);
    expect([l.title, l.times, l.konpaku]).toEqual(['STAGE 4 CLEAR', 'TIME 0:30   RUN 2:00', 'KONPAKU  1 -> 3']);
    expect(l.ramp).toBe('AWAKENING 50');                 // stage 5: half a gauge
    r.snap = snap('kenpachi', 'base');
    r.clearLines();
    expect(r.clear!.rows).toEqual(['stay', 'quit']);
    expect(r.clear!.notes[0]).toBe('ON TO STAGE 5');
  });
});
