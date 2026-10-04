// rules.test.ts <- tests/duel-rules-test.lisp (the M1 parts: the rules, Yamamoto's and Kenpachi's base kits; the
// awakened forms and the other characters come with M3 / M4) + tests/duel-control-test.lisp's vpad / command checks
// + determinism (same seed twice -> identical hash lines) and a smoke run of YY / YK / KK.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { T } from '../src/sim/tuning';
import { angleWrap, deg, roundHalfEven, turnToward, weightedPick } from '../src/sim/math';
import * as R from '../src/sim/rules';
import { capsuleCylHitP, cylCylHitP, makeVol, oboxCylHitP, volHitP } from '../src/sim/hitvol';
import {
  findKit, findMove, kitAtkMods, kitCommandCost, kitCommandMove, kitMove, kitNext, makeHitwin, mvFirstHit, mvTotal,
  stringLatch, stringLinkP, stunToleranceOf, type Kit, type Move,
} from '../src/sim/kit';
import { COMMANDS, VPAD_ACTIONS, konpakuAtStake, konpakuStep, newVpad, practiceReishi, dummyGuardLeft, DUMMY_GUARD_HOLD, type Action, type Vpad } from '../src/sim/vpad';
import { Rng } from '../src/sim/rng';
import { runSeed } from '../tools/headless';

const ck = (c: unknown, label = ''): void => expect(!!c, label).toBe(true);
const near = (a: number, b: number, eps = 1e-3): boolean => Math.abs(a - b) < eps;
const kit = (c: string, f: string): Kit => findKit(c, f);
const mv = (c: string, f: string, n: string): Move => kitMove(kit(c, f), n);
const FORMS: [string, string][] = [['yamamoto', 'base'], ['kenpachi', 'base']];
const withT = <K extends keyof typeof T>(k: K, v: (typeof T)[K], fn: () => void): void => {
  const old = T[k]; T[k] = v;
  try { fn(); } finally { T[k] = old; }
};

describe('CL numbers', () => {
  it('round is half-even', () => {
    expect([0.5, 1.5, 2.5, -0.5, -1.5, 82.5, 2.4, 2.6].map((x) => roundHalfEven(x) + 0)).toEqual([0, 2, 2, 0, -2, 82, 2, 3]);
  });
  it('xorshift32 seeding (fmix32) and the [0,1) stream', () => {
    const a = new Rng(0), b = new Rng(0);
    a.seed(7); b.seed(7);
    const xs = Array.from({ length: 5 }, () => a.float());
    ck(xs.every((x) => x >= 0 && x < 1));
    expect(Array.from({ length: 5 }, () => b.float())).toEqual(xs);
    const z = new Rng(1); z.seed(0); expect(z.state).toBe(0x9e3779b9);   // fmix32(0) = 0 -> the fallback
  });
});

describe('the triangle / clash matrix', () => {
  it('resolveContact', () => {
    ck(R.resolveContact('neutral') === 'hit');
    ck(R.resolveContact('guard') === 'blocked');
    ck(R.resolveContact('guard', { inFront: false }) === 'hit');
    ck(R.resolveContact('guard', { breaker: true }) === 'guard-break');
    ck(R.resolveContact('guard', { guardCrush: true }) === 'guard-break');
    ck(R.resolveContact('breaker') === 'counter');
    ck(R.resolveContact('neutral', { breaker: true }) === 'hit');
    ck(R.resolveContact('stance') === 'absorbed');
    ck(R.resolveContact('stance', { breaker: true }) === 'stance-break');
    ck(R.resolveContact('stance-in') === 'counter');
    ck(R.resolveContact('stance-in', { breaker: true }) === 'stance-break');
    ck(R.resolveContact('invuln', { breaker: true }) === null);
    // the ward
    ck(R.resolveContact('guard', { inFront: false, ward: true }) === 'blocked');
    ck(R.resolveContact('guard', { hazard: true, inFront: false, ward: true }) === 'blocked');
    ck(R.resolveContact('guard', { breaker: true, inFront: false, ward: true }) === 'guard-break');
    ck(R.resolveContact('guard', { guardCrush: true, ward: true }) === 'guard-break');
    ck(R.resolveContact('guard', { unguardable: true, ward: true }) === 'hit');
    ck(R.resolveContact('parry', { hazard: true, ward: true }) === 'blocked' && R.resolveContact('parry', { hazard: true }) === 'hit');
    ck(R.resolveContact('parry', { ward: true }) === 'parried' && R.resolveContact('parry', { unguardable: true, ward: true }) === 'hit');
    ck(R.resolveContact('invuln', { ward: true }) === null);
    // armour
    ck(R.resolveContact('armor') === 'armored' && R.resolveContact('armor', { inFront: false }) === 'armored');
    ck(R.resolveContact('armor', { breaker: true }) === 'hit' && R.resolveContact('armor', { unguardable: true }) === 'hit');
  });
  it('the melee / ranged split', () => {
    ck(R.rangedHitP(true, [], null, 0) && !R.rangedHitP(null, [], null, 100) && R.rangedHitP(null, ['ranged'], null, 1));
    ck(!R.rangedHitP(null, ['ranged'], 3.4, 3.4 * 3.4) && R.rangedHitP(null, ['ranged'], 3.4, 3.5 * 3.5));
    ck(near(findMove('ke-buttagiru').params.meleeRange, 2.6) && findMove('ya-taimatsu').params.meleeRange === undefined);
  });
  it('the contact rule', () => {
    ck((['hit', 'counter', 'guard-break', 'stance-break', 'kikon'] as const).every((r) => R.contactOf(r) === 'hit'));
    ck((['blocked', 'armored', 'absorbed', 'parried'] as const).every((r) => R.contactOf(r) === 'block'));
    ck(R.contactOf(null) === null);
    ck(!R.chainOpenP(12, 9, 3, 12, R.contactOf('armored')));
    ck(R.breakerClashP('dash', 'strike', 2.5) && !R.breakerClashP('dash', 'aura', 1.0) && !R.breakerClashP('dash', 'dash', 3.5));
  });
  it("the Breaker's pre-strike phases", () => {
    ck(R.breakerNextPhase('aura', 11, true, 9) === 'aura' && R.breakerNextPhase('aura', 12, true, 9) === 'dash');
    ck(R.breakerNextPhase('dash', 20, true, 9) === 'dash');
    ck(R.breakerNextPhase('dash', 1, true, 0.9) === 'strike');
    ck(R.breakerNextPhase('dash', 5, false, 9) === 'dash');
    ck(R.breakerNextPhase('dash', 12, false, 9) === 'strike');
    ck(R.breakerNextPhase('dash', 45, true, 9) === 'strike');
    ck(near(R.breakerSpeed(0), 9) && near(R.breakerSpeed(45), 10));
    const b = mv('yamamoto', 'base', 'ya-breaker');
    ck(b.s === 8 && b.a === 4 && b.r === 18 && b.whiff === 30 && b.dmg === 150 && b.advBlock === 'guard-break'
       && b.hits[0].flags.includes('breaker') && near(b.track, T.trackBreaker) && b.hits[0].hs === 10);
    ck(mv('yamamoto', 'base', 'ya-j1').s < T.breakerAura + T.breakerStartup);
  });
  it('J beats the grab in every form with a Breaker', () => {
    ck(T.breakerTrigger > 0.9 && T.breakerReach + 0.34 > T.breakerTrigger);
    for (const [c, f] of FORMS) {
      const k = kit(c, f), br = kitCommandMove(k, 'breaker')!, j1 = kitCommandMove(k, 'q')!;
      const v = T.breakerSpeedMax / 60, s = j1.s, a = j1.a;
      const dHi = j1.reach + 0.34 + v * (s + a - 1), dLo = T.breakerTrigger + v * Math.max(0, s - br.s);
      ck(br.reach < j1.reach && j1.reach + 0.34 > T.breakerTrigger && dLo < dHi, `${c} ${f}`);
    }
  });
});

// ---------------------------------------------------------------- the frame-advantage replays (the Lisp test's helpers)
/** MV blocked on its first hit frame: [the attacker's, the defender's] first actionable step from the move's first step. */
function freeSteps(m: Move): [number, number] {
  const enter = m.enter, h = mvFirstHit(m) - enter;
  const end = R.moveEndFrame(m.s, m.a, m.r, m.whiff, 'block', false);
  const stun = R.blockstun(mvTotal(m), mvFirstHit(m), m.advBlock as number);
  let att = 0, def = 0;
  for (let step = 1; ; step++) if (enter + step >= end) { att = step + 1; break; }
  for (let step = h + 1, sf = 1; ; step++, sf++) if (sf >= stun) { def = step + 1; break; }
  return [att, def];
}
function lockedFreeSteps(m: Move, more: boolean): [number, number] {
  const enter = m.enter, h = mvFirstHit(m) - enter;
  const end = R.moveEndFrame(m.s, m.a, m.r, m.whiff, 'block', false);
  const stun = R.blockstun(mvTotal(m), mvFirstHit(m), m.advBlock as number);
  let att = 0, def = 0, lock = false;
  for (let step = 1; ; step++) if (enter + step >= end) { att = step + 1; break; }
  for (let step = h + 1, sf = 1; ; step++, sf++) {
    if (sf >= stun && !lock) { def = step + 1; break; }
    const fr = enter + step;
    lock = R.guardLockedP('guard-hit', lock, 0, fr >= end ? 'idle' : 'move', 'main', fr, m.s, m.a, m.r, true, more);
  }
  return [att, def];
}
const blockedGap = (a: Move, b: Move): number => mvTotal(a) - a.enter - T.chainLead + (b.s - b.enter) - freeSteps(a)[1];
const hitGap = (a: Move, b: Move): number => a.s + a.a + (b.s - b.enter) - (mvFirstHit(a) + 1 + R.hitstun(a.hits[0].react));
function linkMoves(k: Kit): [Move, number, string[]][] {
  const out: [Move, number, string[]][] = [];
  const walk = (m: Move, n: number, seq: string[]) => {
    out.push([m, n, seq]);
    for (const c of ['q', 'f']) { const nx = kitNext(k, m.name, c); if (nx) walk(nx, n + 1, [...seq, c]); }
  };
  walk(kitCommandMove(k, 'q')!, 1, ['q']);
  walk(kitCommandMove(k, 'f')!, 1, ['f']);
  return out;
}
function route(k: Kit, first: string, presses: string[][]): string[] {
  let m = kitCommandMove(k, first)!;
  const out = [m.name];
  for (const ps of presses) {
    let q: string | null = null;
    if (stringLinkP(k, m.name)) for (const c of ps) q = stringLatch(k, m.name, c, q);
    if (!q) return out;
    m = kitNext(k, m.name, q)!;
    out.push(m.name);
  }
  return out;
}

describe('block / whiff advantage', () => {
  it('the basics', () => {
    ck(R.blockstun(24, 9, -2) === 13 && R.hitstun('flinch') === 18 && R.hitstun('stagger', true) === 36);
    ck(R.recoveryFrames(12, true) === 12 && R.recoveryFrames(12, null) === 18 && R.recoveryFrames(18, null, 30) === 30);
    ck(R.chainOpenP(12, 9, 3, 12, 'hit') && !R.chainOpenP(11, 9, 3, 12, 'hit'));
    for (let sf = 0; sf <= 30; sf++) ck(!R.chainOpenP(sf, 9, 3, 12, null));
    ck(R.chainOpenP(21, 9, 3, 12, 'block') && !R.chainOpenP(20, 9, 3, 12, 'block') && !R.chainOpenP(24, 9, 3, 12, 'block'));
    ck(R.chainOpenP(21, 9, 3, 12, true) && !R.chainOpenP(20, 9, 3, 12, true) && !R.chainOpenP(24, 9, 3, 12, true));
    ck(R.cancelOpenP(9, 9, 24, true) && R.cancelOpenP(23, 9, 24, true) && !R.cancelOpenP(24, 9, 24, true) && !R.cancelOpenP(10, 9, 24, false));
    ck(R.invulnerableFrameP(3, T.stepIframes) && R.invulnerableFrameP(9, T.stepIframes) && !R.invulnerableFrameP(10, T.stepIframes)
       && R.invulnerableFrameP(14, T.hohoIframes) && !R.invulnerableFrameP(0, T.hohoIframes));
    ck(R.moveEndFrame(9, 3, 12, 18, null, false) === 30);
    ck(R.moveEndFrame(9, 3, 12, 18, 'block', false) === 24 && R.moveEndFrame(2, 1, 20, 26, null, true) === 23);
  });
  it("the follow-up's chase", () => {
    const g = Math.max(T.lungeStop, 2.6 - T.chaseMargin);
    ck(near(R.stringChaseSpeed(g + 1.4, 2.6, 7), 60 * (1.4 / 7)));
    ck(near(R.stringChaseSpeed(20, 2.6, 7), T.chaseMax));
    ck(R.stringChaseSpeed(g, 2.6, 7) === 0 && R.stringChaseSpeed(5, 2.6, 0) === 0);
    ck(R.stringChaseSpeed(3, 2.6, 1) / 60 <= 3 - g);
    ck(R.stringChaseSpeed(T.lungeStop, 1.2, 5) === 0);
    let d = 6;
    for (let left = 14; left >= 1; left--) d -= R.stringChaseSpeed(d, 2.6, left) / 60;
    ck(d <= 2.6 && d >= g - 1e-4);
  });
  it("every move's block advantage is the §5 table's, exactly", () => {
    for (const [c, f] of FORMS)
      for (const m of kit(c, f).moves.values())
        if (Number.isInteger(m.advBlock) && m.hits.length > 0) { const [att, def] = freeSteps(m); expect(def - att, m.name).toBe(m.advBlock); }
  });
});

describe('the J / K strings', () => {
  for (const [c, f] of FORMS) it(`${c} ${f}: shape, budget, gaps`, () => {
    const k = kit(c, f), links = linkMoves(k), j1 = kitCommandMove(k, 'q')!, k1 = kitCommandMove(k, 'f')!;
    expect(links.filter(([, n]) => n === 3).map(([, , s]) => s.map((x) => (x === 'q' ? 'J' : 'K')).join('')).sort())
      .toEqual(['JJJ', 'JJK', 'JKK', 'KJJ', 'KKJ', 'KKK']);
    ck(links.every(([m, n]) => m.flags.includes('ender') === (n === 3)));
    ck(links.every(([m, n]) => stringLinkP(k, m.name) === (n < 3)));
    ck(j1.s >= 7 && j1.s <= 10 && j1.a === 3 && j1.r === 12 && j1.advBlock === -2 && j1.hits[0].react === 'flinch');
    ck(k1.s >= 16 && k1.s <= 20 && k1.a === 4 && k1.r >= 20 && k1.r <= 22 && k1.advBlock === -3 && k1.armorHits === 0
       && k1.hits[0].react === 'stagger');
    ck(k1.s - j1.s >= 7);
    for (const [m, n, seq] of links) {
      const kk = seq[seq.length - 1] === 'f', w = m.hits[0];
      if (kk && n > 1) expect(m.s - m.enter, m.name).toBe(14);
      if (n > 1) {
        expect(m.advBlock, m.name).toBe(n === 2 && kk ? -3 : n === 2 ? -2 : kk ? -20 : -4);
        expect(w.react, m.name).toBe(n === 3 && kk ? 'crumple' : kk || n === 3 ? 'stagger' : 'flinch');
      }
      expect(m.whiff, m.name).toBe(m.r + (kk ? T.whiffExtraK : T.whiffExtraJ));
      for (const cc of ['q', 'f']) {
        const nx = kitNext(k, m.name, cc);
        if (nx) {
          ck(hitGap(m, nx) < 0, `${m.name}->${nx.name} combos`);
          const g = blockedGap(m, nx);
          if (cc === 'f') ck(g >= 11, `${m.name}->${nx.name} gap ${g}`);
          else ck(g >= T.stepIframes[0] && g <= j1.s, `${m.name}->${nx.name} gap ${g}`);
        }
      }
    }
    // the switched link 2 is a copy
    const j2 = kitNext(k, j1.name, 'q')!, j2s = kitNext(k, k1.name, 'q')!, k2 = kitNext(k, k1.name, 'f')!, k2s = kitNext(k, j1.name, 'f')!;
    ck(j2 !== j2s && k2 !== k2s && k2.enter === k2s.enter && j2.s === j2s.s && k2.clip === k2s.clip);
    expect(j2s.spec).toEqual(j2.spec);
    expect(k2s.spec).toEqual(k2.spec);
    // K3 on block -20: every J1 and every base K1 punishes it; J3 -4 is safe
    const punish = Math.max(mv('yamamoto', 'base', 'ya-j1').s, mv('kenpachi', 'base', 'ke-j1').s, mv('yamamoto', 'base', 'ya-k1').s,
                            mv('kenpachi', 'base', 'ke-k1').s);
    ck(links.every(([m, n]) => n !== 3 || punish < -(m.advBlock as number) || m.advBlock === -4));
    // the O ender always combos off a link-3 hit
    const o = kitCommandMove(k, 'kikon')!, pa = o.params;
    for (const [m, n] of links) if (n === 3) {
      const dash = pa.dashMax === 0 ? 0 : Math.ceil(60 * (Math.max(0, m.reach - T.kikonTrigger) / pa.speed));
      ck(mvTotal(m) - m.hits[0].from - m.r + dash + o.s < R.hitstun(m.hits[0].react), m.name);
    }
    // J links reach at least 0.5 m less than the K links of the same link number
    for (let n = 1; n <= 3; n++) {
      const j = Math.max(...links.filter(([m, l]) => l === n && m.kind === 'quick').map(([m]) => m.reach));
      const kr = Math.min(...links.filter(([m, l]) => l === n && m.kind === 'flash').map(([m]) => m.reach));
      ck(kr - j >= 0.5, `link ${n}`);
    }
  });
  it('routes (the latch)', () => {
    const y = kit('yamamoto', 'base');
    expect(route(y, 'q', [['q'], ['q']])).toEqual(['ya-j1', 'ya-j2', 'ya-j3']);
    expect(route(y, 'q', [['q'], ['f']])).toEqual(['ya-j1', 'ya-j2', 'ya-k3']);
    expect(route(y, 'q', [['f'], ['f']])).toEqual(['ya-j1', 'ya-k2s', 'ya-k3']);
    expect(route(y, 'f', [['f'], ['f']])).toEqual(['ya-k1', 'ya-k2', 'ya-k3']);
    expect(route(y, 'f', [['f'], ['q']])).toEqual(['ya-k1', 'ya-k2', 'ya-j3']);
    expect(route(y, 'f', [['q'], ['q']])).toEqual(['ya-k1', 'ya-j2s', 'ya-j3']);
    expect(route(y, 'q', [['f'], ['q']])).toEqual(['ya-j1', 'ya-k2s']);
    expect(route(y, 'f', [['q'], ['f']])).toEqual(['ya-k1', 'ya-j2s']);
    expect(route(y, 'q', [['q', 'f'], ['f', 'q']])).toEqual(['ya-j1', 'ya-k2s', 'ya-k3']);
    expect(route(y, 'q', [['q'], ['q'], ['q']])).toEqual(['ya-j1', 'ya-j2', 'ya-j3']);
    expect(route(y, 'q', [[], ['q']])).toEqual(['ya-j1']);
    ck(stringLatch(y, 'ya-k2s', 'q', 'f') === 'f' && stringLatch(y, 'ya-k2s', 'q', null) === null && stringLatch(y, 'ya-j1', 'f', 'q') === 'f'
       && !stringLinkP(y, 'ya-j3') && !stringLinkP(y, 'ya-sig'));
  });
  it("route damage, Yama's J1 -> J2 gap, KOSEI", () => {
    const dmg = (...ns: string[]) => ns.reduce((s, n, i) => s + R.hitDamage(mv('kenpachi', 'base', n).dmg, null, null, i + 1, false), 0);
    ck(dmg('ke-j1', 'ke-j2', 'ke-j3') === 112 && dmg('ke-k1', 'ke-k2', 'ke-k3') === 210 && dmg('ke-k1', 'ke-j2s', 'ke-j3') === 147
       && R.hitDamage(70, null, null, 4, false) === 63);
    const q1 = mv('yamamoto', 'base', 'ya-j1'), q2 = mv('yamamoto', 'base', 'ya-j2');
    expect(freeSteps(q1)[1]).toBe(23);
    expect(mvTotal(q1) - T.chainLead + q2.s - freeSteps(q1)[1]).toBe(6);
    ck(near(mv('kenpachi', 'base', 'ke-j1').clipSpeed, 1.0));
    ck(near(R.koseiMult(100), 1) && near(R.koseiMult(0), 3) && near(R.koseiMult(50), 2) && near(T.koseiBonus, 2));
    let [r, fs, m] = R.koseiGain(24, 100); ck(near(r, 4.8) && near(fs, 2.4) && near(m, 1));
    [r, fs, m] = R.koseiGain(24, 0); ck(near(r, 14.4) && near(fs, 7.2) && near(m, 3));
    expect(['ke-j1', 'ke-j2', 'ke-j3'].reduce((s, n) => s + mv('kenpachi', 'base', n).hits[0].guard!, 0)).toBe(24);
  });
});

describe('damage', () => {
  it('scaling, multipliers, chip, burns', () => {
    ck(near(R.comboScale(1), 1) && near(R.comboScale(3), 1) && near(R.comboScale(4), 0.9) && near(R.comboScale(9), 0.4) && near(R.comboScale(12), 0.4));
    expect(R.hitDamage(100, null, null, 1, false)).toBe(100);
    expect(R.hitDamage(100, { mult: 1.3 }, null, 1, false)).toBe(130);
    expect(R.hitDamage(100, { cornered: 0.05, corneredMax: 0.25, lost: 2 }, null, 1, false)).toBe(110);
    expect(R.hitDamage(100, { cornered: 0.05, corneredMax: 0.25, lost: 6 }, null, 1, false)).toBe(125);
    expect(R.hitDamage(100, { mult: 1.15, cornered: 0.05, corneredMax: 0.25, lost: 3 }, null, 5, true)).toBe(132);
    expect(R.hitDamage(100, null, null, 20, false)).toBe(40);
    expect(R.hitDamage(1, null, null, 12, false)).toBe(1);
    expect(R.hitDamage(0, { mult: 2 }, null, 1, true)).toBe(0);
    expect(R.hitDamage(100, kitAtkMods(kit('kenpachi', 'base'), 4), null, 1, false)).toBe(120);   // Cornered 1.20
    expect(R.chipDamage(110, T.chipFire, 500)).toBe(13);
    ck(R.chipDamage(110, 0.12, 5) === 4 && R.chipDamage(110, 0.12, 1) === 0 && R.chipDamage(110, null, 500) === 0);
    expect(Array.from({ length: 600 }, (_, s) => R.burnAmount(1000, T.hellfireBurn, s)).reduce((a, b) => a + b)).toBe(500);
    expect(Array.from({ length: 60 }, (_, s) => R.burnAmount(1000, 0.02, s)).reduce((a, b) => a + b)).toBe(20);
    ck(R.burn(30, 50) === 1 && R.burn(1, 5) === 1 && R.burn(500, 30) === 470);
    ck(R.corneredMult(0.05, 10, 0.25) === 1.25);
  });
  it("East's pierce arithmetic (the rules; the Bankai kits are M3)", () => {
    ck(near(T.pierceMin, 0.1) && near(T.pierceMax, 0.45) && near(T.wardMult, 1.1));
    withT('pierceMax', 0.5, () => {
      ck(near(R.pierceRate(100), 0.5) && near(R.pierceRate(0), 0.1) && near(R.pierceRate(50), 0.3) && near(R.pierceRate(100, 2), 1.0)
         && near(R.pierceRate(0, 2), 0.2));
      const hit = (d: number, gg: number, m = 1.0) => R.hitDamage(d, { mult: 1 + R.pierceRate(gg, m) }, null, 1, false);
      const through = (d: number, gg: number, m = 1.0) => R.chipDamage(d, R.pierceRate(gg, m), 1300);
      expect(hit(34, 100) + hit(38, 100) + hit(55, 100)).toBe(190);       // 82.5 rounds to even
      expect(hit(34, 50) + hit(38, 50) + hit(55, 50)).toBe(165);
      expect(through(34, 100) + through(38, 100) + through(55, 100)).toBe(64);
      expect(through(34, 0) + through(38, 0) + through(55, 0)).toBe(13);
      ck(hit(85, 100, 2) === 170 && through(85, 100, 2) === 85 && hit(85, 0, 2) === 102 && through(85, 0, 2) === 17);
      expect(R.chipDamage(85, 1.0, 50)).toBe(49);
    });
    ck(near(R.pierceRate(100), 0.45) && near(R.pierceRate(100, 2), 0.9));
  });
});

describe('Kikon, Konpaku, Soul Break, time-up', () => {
  it('red, the outcome, the follow-up', () => {
    withT('redThreshold', 0.3, () => ck(R.redP(299, 1000) && !R.redP(300, 1000)));
    ck(R.kikonOutcome(true, 'hit', false) === 'follow' && R.kikonOutcome(true, 'counter', false) === 'follow');
    ck(R.kikonOutcome(false, 'hit', true) === 'kikon' && R.kikonOutcome(true, 'hit', true) === 'kikon');
    ck(R.kikonOutcome(false, 'hit', false) === null);
    ck(([null, 'blocked', 'absorbed', 'armored', 'parried', 'guard-break'] as const).every((r) => !R.kikonOutcome(true, r, false) && !R.kikonOutcome(true, r, true)));
    ck(T.kikonFollowGap >= T.guardRaise + 1 && R.kikonFollowWait(6) === T.kikonFollowStun + 1 + T.kikonFollowGap - 6
       && R.kikonFollowWait(99) === 0 && near(T.kikonFollowKb, 2.5));
    ck(!R.kikonFollowUnguardableP(false) && R.kikonFollowUnguardableP(true));
    ck(R.resolveContact('guard', { unguardable: R.kikonFollowUnguardableP(false) }) === 'blocked'
       && R.resolveContact('guard', { unguardable: R.kikonFollowUnguardableP(true) }) === 'hit'
       && R.resolveContact('stance', { unguardable: true }) === 'hit' && R.resolveContact('parry', { unguardable: true }) === 'hit'
       && R.resolveContact('invuln', { unguardable: true }) === null && R.resolveContact('stance-in', { unguardable: true }) === 'hit'
       && R.resolveContact('breaker', { unguardable: true }) === 'counter');
    for (const [c, f] of FORMS) {
      const s = kitCommandMove(kit(c, f), 'kikon')!.s;
      ck(R.kikonFollowWait(s) + s === R.kikonFollowStun(false, s) + 1 + T.kikonFollowGap);
      ck(R.kikonFollowStun(true, s) > R.kikonFollowWait(s) + s);
    }
    ck(near(R.kikonFollowSpeed(4.6, 10, 99), 18) && near(R.kikonFollowSpeed(4.6, 10, 12), 12) && near(R.kikonFollowSpeed(1, 10, 99), 0)
       && near(R.kikonFollowSpeed(4.6, 0, 99), 99));
  });
  it("the rush's phases and reach", () => {
    const nx = (ph: 'aura' | 'dash', f: number, d: number, dm = 22) => R.kikonRushNextPhase(ph, f, d, 5, dm);
    ck(nx('aura', 4, 9) === 'aura' && nx('aura', 5, 9) === 'dash' && nx('aura', 5, T.kikonTrigger) === 'strike'
       && nx('dash', 3, 9) === 'dash' && nx('dash', 3, T.kikonTrigger - 0.1) === 'strike' && nx('dash', 22, 9) === 'strike'
       && nx('aura', 5, 9, 0) === 'strike');
    ck(near(R.kikonRushReach(36, 14), 10) && near(R.kikonRushReach(13, 36), 9.4) && near(R.kikonRushReach(18, 30), 10.6));
  });
  it('kikonResult, time-up, the reset placement', () => {
    expect(R.kikonResult(6, 2, false)).toEqual([4, 2, false]);
    expect(R.kikonResult(6, 3, false)).toEqual([3, 3, false]);
    expect(R.kikonResult(6, 2, true)).toEqual([3, 3, false]);
    expect(R.kikonResult(6, 4, true)).toEqual([1, 5, false]);
    expect(R.kikonResult(6, 3, true)).toEqual([2, 4, false]);
    expect(R.kikonResult(2, 2, false)).toEqual([0, 2, true]);
    expect(R.kikonResult(1, 3, true)).toEqual([0, 1, true]);
    ck(R.soulBreakP(0) && !R.soulBreakP(1));
    ck(R.timeUpWinner(3, 100, 1000, 2, 900, 1000) === 0 && R.timeUpWinner(2, 900, 1000, 3, 100, 1000) === 1);
    ck(R.timeUpWinner(2, 600, 1000, 2, 500, 1000) === 0 && R.timeUpWinner(2, 500, 1000, 2, 525, 1050) === 'draw');
    const [ax, az, bx, bz] = R.resetPlacement(10, 0, 12, 0);
    ck(near(ax, -4) && near(az, 0) && near(bx, 4) && near(bz, 0));
  });
});

describe('gauges', () => {
  it('Reiatsu, awakening, bars, Hoho', () => {
    ck(near(R.reiatsuGain(100, 0), 8) && near(R.reiatsuGain(0, 100), 10) && near(R.reiatsuGain(0, 0, 60), 3));
    ck(near(R.awakeningGain(100, 100, 1), 18.9));
    ck(near(R.gaugeAdd(290, 20, 300), 300) && near(R.gaugeAdd(5, -10, 300), 0));
    expect(R.spendBars(150, 1)).toEqual([50, true]);
    expect(R.spendBars(50, 1)).toEqual([50, false]);
    ck(R.hohoAllowedP(false, 30, 0) && !R.hohoAllowedP(true, 100, 0) && !R.hohoAllowedP(false, 100, 10) && !R.hohoAllowedP(false, 29, 0));
    ck(R.awakenAllowedP(true, 100, false) && !R.awakenAllowedP(true, 100, true) && !R.awakenAllowedP(false, 100, false) && !R.awakenAllowedP(true, 99, false));
  });
  it('the burst modes', () => {
    ck(R.burstMode('stun', false, 2, null) === 'blue' && R.burstMode('air', false, 3, null) === 'blue' && R.burstMode('stun', false, 1, null) === null
       && R.burstMode('guard-hit', false, 0, null) === 'blue' && R.burstMode('move', false, 0, true) === 'orange' && R.burstMode('move', false, 0, null) === null
       && R.burstMode('idle', false, 0, null) === 'white' && R.burstMode('guard', false, 0, null) === 'white' && R.burstMode('run', false, 0, null) === 'white'
       && R.burstMode('step', false, 0, null) === null && R.burstMode('hoho', false, 0, null) === null && R.burstMode('down', false, 5, null) === null
       && R.burstMode('cine', false, 0, null) === null && R.burstMode('idle', true, 0, null) === null && R.burstMode('stun', true, 5, null) === null);
    ck(R.burstAllowedP('white', 70, null) && R.burstAllowedP('orange', 70, null) && R.burstAllowedP('blue', 100, null)
       && !R.burstAllowedP('white', 69.9, null) && !R.burstAllowedP('blue', 69, null) && !R.burstAllowedP('orange', 60, null)
       && !R.burstAllowedP(null, 100, null) && !R.burstAllowedP('white', 100, 'blue'));
    ck(T.burstDrain === 18 && near(R.burstDrain(50), 50 - 0.3) && near(R.burstDrain(0.1), 0));
    const frames = (fs: number) => { for (let n = 1; ; n++) { fs = R.burstDrain(fs); if (fs <= 0) return n; } };
    ck(frames(70) >= 232 && frames(70) <= 234 && frames(100) >= 332 && frames(100) <= 334);
    ck(near(R.burstFsGain(12, null), 12) && near(R.burstFsGain(12, 'white'), 0) && near(R.burstFsGain(15, 'orange'), 0));
    ck(R.hohoAllowedP(false, 12, 0, 'white') && R.hohoAllowedP(false, 0.1, 0, 'blue') && !R.hohoAllowedP(false, 0, 0, 'blue')
       && !R.hohoAllowedP(false, 12, 0) && !R.hohoAllowedP(false, 12, 5, 'white') && !R.hohoAllowedP(true, 50, 0, 'white'));
    ck(near(R.hohoCost(12, 'white'), 12) && near(R.hohoCost(80, 'white'), 30) && near(R.hohoCost(80, null), 30));
    const heal = (to: number, rate: number) => Array.from({ length: to }, (_, i) => R.burstHeal(i + 1, rate)).reduce((a, b) => a + b);
    ck(heal(60, T.whiteReishi) === 70 && heal(333, 12) === 66 && R.burstHeal(5, 12) === 1 && R.burstHeal(4, 12) === 0);
    ck(near(R.ggRegen(50, 999, false, false, null, 0.25), 50 + (0.25 * T.ggRegen) / 60) && near(R.ggRegen(50, 999, true, false, null, 0.25), 50 + T.ggRegenGuardless / 60));
    ck(near(R.ggRegen(50, 0, false, false, 'blue'), 50 + 11 / 60) && near(R.ggRegen(50, 0, false, true, 'blue'), 50 + 2.75 / 60)
       && near(R.ggRegen(50, 0, true, false, 'blue'), 50 + 13 / 60) && near(R.ggRegen(99.99, 0, false, true, 'blue'), 100) && near(R.ggRegen(50, 999, false, true), 50));
    ck(R.cancelOpenP(12, 10, 30, true) && !R.cancelOpenP(9, 10, 30, true) && !R.cancelOpenP(30, 10, 30, true) && !R.cancelOpenP(12, 10, 30, false));
    ck(T.guardCancel === 0.5 && !R.guardCancelOpenP(36, 21, 4, 24, 'hit') && R.guardCancelOpenP(37, 21, 4, 24, 'hit')
       && R.guardCancelOpenP(48, 21, 4, 24, 'hit') && !R.guardCancelOpenP(49, 21, 4, 24, 'hit')
       && !R.guardCancelOpenP(40, 21, 4, 24, 'block') && !R.guardCancelOpenP(40, 21, 4, 24, null));
    ck(Math.abs(R.rayRoom(0, 0, 1, 0, 5) - 5) < 1e-4 && Math.abs(R.rayRoom(4, 0, 1, 0, 5) - 1) < 1e-4
       && Math.abs(R.rayRoom(4, 0, -1, 0, 5) - 9) < 1e-4 && R.rayRoom(5, 0, 1, 0, 5) === 0);
    ck(R.guardCancelOpenP(18, 9, 3, 12, 'block', true) && !R.guardCancelOpenP(17, 9, 3, 12, 'block', true)
       && !R.guardCancelOpenP(24, 9, 3, 12, 'block', true) && !R.guardCancelOpenP(20, 9, 3, 12, null, true) && R.guardCancelOpenP(20, 9, 3, 12, 'hit', true));
    ck(R.chainStartupCut(10, 0) === 4 && R.chainStartupCut(20, 0) === 8 && R.chainStartupCut(2, 0) === 0 && R.chainStartupCut(1, 0) === 0
       && R.chainStartupCut(3, 0) === 1 && R.chainStartupCut(12, 2) === 4 && T.chainWindow === 12);
    ck(near(R.burstGainMult('orange'), 1.5) && near(R.burstGainMult('white'), 1) && near(R.burstGainMult(null), 1));
    ck(near(R.hitGains(100, 0, false, 1.5)[0], 12) && near(R.hitGains(100, 0, false, 1.5)[2], 5.25)
       && near(R.hitGains(0, 100, false, 1.5)[0], 10) && near(R.hitGains(100, 0, false)[0], 8));
    expect(R.kikonRefund(10, 50)).toEqual([45, 150]);
    expect(R.kikonRefund(90, 250)).toEqual([100, 300]);
  });
  it('flash-step and the guard gauge', () => {
    ck(T.fsHoho === 30 && T.fsBurst === 70 && T.fsRefund === 15 && near(T.fsTaken, 0.03) && T.fsMax === 100);
    ck(near(R.fsRegen(50, 59), 50) && near(R.fsRegen(50, 60), 50.05) && near(R.fsRegen(99.99, 600), 100));
    let f = 0; for (let i = 0; i < 60; i++) f = R.fsRegen(f, 60); ck(near(f, 3));
    ck(R.guardValue('quick', -2) === 8 && R.guardValue('quick', -12) === 12 && R.guardValue('flash', -4) === 14 && R.guardValue('flash', -14) === 18
       && R.guardValue('sig', -6) === 18 && R.guardValue('sig', -14) === 22 && R.guardValue('sp', -16) === 22 && R.guardValue('kikon', -14) === 20
       && R.guardValue(null, null) === 12 && R.guardValue('sig', -6, 10) === 10);
    ck(mv('kenpachi', 'base', 'ke-j3').hits[0].guard === 8 && mv('kenpachi', 'base', 'ke-k3').hits[0].guard === 18
       && mv('yamamoto', 'base', 'ya-sig').hits[0].guard === 10 && findMove('ya-sig').params.guard === 15);
    const gv = (n: string) => mv('kenpachi', 'base', n).hits[0].guard!;
    ck(gv('ke-j1') + gv('ke-j2') + gv('ke-j3') === 24 && gv('ke-k1') + gv('ke-k2') + gv('ke-k3') === 46);
    expect(R.ggDrain(100, 8)).toEqual([92, false]);
    expect(R.ggDrain(5, 8)).toEqual([0, true]);
    ck(T.ggDelay === 60 && near(T.ggRegen, 5.5) && near(T.ggRegenGuardless, 6.5));
    ck(near(R.ggRegen(50, 59, false, false), 50) && near(R.ggRegen(50, 60, false, false), 50 + 5.5 / 60)
       && near(R.ggRegen(50, 60, true, false), 50 + 6.5 / 60) && near(R.ggRegen(99.99, 99, false, false), 100));
    let g = 0, fr = 0; for (; g < T.ggMax; fr++) g = R.ggRegen(g, fr, true, false);
    ck(fr >= 983 && fr <= 984, `guardless refill ${fr}`);
    ck(near(R.ggRegen(50, 999, false, true), 50) && R.ggIdleNext(40, true) === 40 && R.ggIdleNext(40, false) === 41 && R.ggIdleNext(9999, false) === 9999);
    let idle = 0;
    for (let i = 0; i < 40; i++) idle = R.ggIdleNext(idle, false);
    for (let i = 0; i < 30; i++) idle = R.ggIdleNext(idle, true);
    for (let i = 0; i < 20; i++) idle = R.ggIdleNext(idle, false);
    expect(idle).toBe(60);
    ck(R.canGuardP(1, false) && !R.canGuardP(0, false) && !R.canGuardP(99, true));
    const q1 = mv('kenpachi', 'base', 'ke-j1');
    expect(T.guardCrushStun - (mvTotal(q1) - mvFirstHit(q1))).toBe(25);
    ck(T.ggBreaker === 35 && T.reishiMax === 1300);
  });
  it('AI helpers, timers, the stance', () => {
    ck(near(R.aiGuardMult(50, false), 1) && near(R.aiGuardMult(30, false), 0.5) && near(R.aiGuardMult(10, false), 0.15)
       && near(R.aiGuardMult(100, true), 0) && near(R.aiGuardMult(0, false), 0));
    ck(R.aiHohoSpareP(30, 1000, 1100) && !R.aiHohoSpareP(90, 400, 1100) && R.aiHohoSpareP(100, 400, 1100));
    ck(R.aiBurstWantedP(540, 1100, 10) && !R.aiBurstWantedP(600, 1100, 10) && R.aiBurstWantedP(600, 1100, 280) && !R.aiBurstWantedP(600, 1100, 260));
    ck(R.secondsToFrames(10) === 600 && near(R.timerFill(300, 600, 100), 50));
    ck(R.stanceStore(150, 80) === 200 && R.stanceStore(0, 45) === 45);
    expect(R.stanceRelease(150)).toEqual([250, true]);
    expect(R.stanceRelease(100)).toEqual([200, false]);
    ck(weightedPick(0, [['a', 1], ['b', 1]]) === 'a' && weightedPick(0.5, [['a', 1], ['b', 1]]) === 'b'
       && weightedPick(0.1, [['a', 0], ['b', 1]]) === 'b' && weightedPick(0.5, [['a', 0]]) === null);
    const bands = kit('yamamoto', 'base').ai!.moves as R.Band[];
    ck(weightedPick(0, R.bandWeights(bands, 6)!) === 'sig' && weightedPick(0, R.bandWeights(bands, 9)!) === 'sp1');
    expect(R.heatRange(6, 8, 10)).toEqual([3, 5]);
    expect(R.heatRange(6, 8, 30)).toEqual([1, 1]);
    ck(R.heatBreakerMult(7.9) === 1 && R.heatBreakerMult(8) === 2);
    ck(near(R.heatAfter(1, false), 1 + T.aiHeatRate / 60) && near(R.heatAfter(1, true), 1 + T.aiHeatRate / 30));
  });
});

describe('combo limits, the hidden stun', () => {
  it('comboStep', () => {
    expect(R.comboStep('launch', false, 0, 0, 0)).toEqual(['launch', 1, 1, 0]);
    expect(R.comboStep('launch', false, 2, 1, 0)).toEqual(['knockback', 3, 1, 0]);
    expect(R.comboStep('flinch', true, 3, 1, 1)).toEqual(['flinch', 4, 1, 2]);
    expect(R.comboStep('flinch', true, 4, 1, 2)).toEqual(['knockdown', 5, 1, 3]);
    expect(R.comboStep('flinch', false, 9, 0, 0)).toEqual(['flinch', 10, 0, 0]);
  });
  it('stun weights, decay, tolerance', () => {
    ck(R.stunWeight('flinch', false) === 1 && R.stunWeight('stagger', false) === 2);
    ck(['crumple', 'knockback', 'launch', 'knockdown'].every((r) => R.stunWeight(r, false) === 3));
    ck(R.stunWeight('flinch', true) === 3 && R.stunWeight('clash', false) === 1 && R.stunAdd(4, 'stagger', false) === 6);
    ck(R.stunDecay(10, T.stunDelay - 1) === 10 && near(R.stunDecay(10, T.stunDelay), 10 - T.stunDecay / 60) && R.stunDecay(0.01, 999) === 0);
    let s = 12; for (let i = 0; i < T.stunDelay + 60; i++) s = R.stunDecay(s, i); ck(near(s, 12 - T.stunDecay, 0.05));
    ck(!R.stunOverP(16, 16) && R.stunOverP(16.5, 16));
    ck(stunToleranceOf(kit('kenpachi', 'base')) === 26 && stunToleranceOf(kit('yamamoto', 'base')) === 18);
    // a re-pin loop with gaps still blows him away; strings 2 s apart never fill it
    let st = 0, idle = 0, strings = 0;
    for (let n = 0; n < 20 && !R.stunOverP(st, 16); n++) {
      strings++;
      for (const r of ['flinch', 'flinch', 'stagger'])
        if (!R.stunOverP(st, 16)) { st = R.stunAdd(st, r, false); idle = 0; for (let i = 0; i < 20; i++) st = R.stunDecay(st, idle++); }
      for (let i = 0; i < 20; i++) st = R.stunDecay(st, idle++);
    }
    ck(R.stunOverP(st, 16) && strings <= 5);
    st = 0; idle = 0; let over = false;
    for (let n = 0; n < 20; n++) {
      for (const r of ['flinch', 'flinch', 'stagger']) { st = R.stunAdd(st, r, false); idle = 0; over ||= R.stunOverP(st, 16); }
      for (let i = 0; i < 120; i++) st = R.stunDecay(st, idle++);
    }
    ck(!over);
  });
});

describe('perfect Hoho, facing, movement, arena, volumes', () => {
  it('perfectHohoP', () => {
    const w = mv('yamamoto', 'base', 'ya-j1').hits[0];
    const perfect = (sf: number, z: number) => R.perfectHohoP(sf, w.from, w.to, w.vols, 0, 0, 0, 0, -1, 0, 0, z, 0.4, 1.8);
    ck(perfect(3, -2) && perfect(0, -2) && perfect(10, -2) && !perfect(12, -2) && perfect(3, -2.2) && !perfect(3, -2.6));
    ck(!R.perfectHohoP(0, w.from + 4, w.to + 4, w.vols, 0, 0, 0, 0, -1, 0, 0, -2, 0.4, 1.8));
  });
  it('facing and movement', () => {
    ck(near(turnToward(0, deg(90), deg(18)), deg(18)) && near(turnToward(0, deg(10), deg(18)), deg(10)));
    ck(near(angleWrap(turnToward(deg(170), deg(-170), deg(18))), deg(-172)));
    ck(near(R.trackStep(360), deg(6)));
    ck(R.inFrontP(0, 0, 0, Math.sin(deg(95)), -Math.cos(deg(95)), T.guardArc) && !R.inFrontP(0, 0, 0, Math.sin(deg(105)), -Math.cos(deg(105)), T.guardArc));
    let [to, st] = R.stickTowardStrafe(0, 1, 0, 0, 0, 0, -5); ck(near(to, 1) && near(st, 0));
    [to, st] = R.stickTowardStrafe(1, 0, 0, 0, 0, 0, -5); ck(near(to, 0) && near(st, 1));
    [to, st] = R.stickTowardStrafe(0, 1, 0, 0, 0, 5, 0); ck(near(to, 0) && near(st, -1));
    const [dx, dz] = R.towardStrafeDir(0.6, 0.8, 1, 1, 1, -4);
    [to, st] = R.stickTowardStrafe(dx, -dz, 0, 1, 1, 1, -4); ck(near(to, 0.6) && near(st, 0.8));
    let [x, z] = R.clampToCircle(20, 0, 15); ck(near(x, 15) && near(z, 0));
    [x, z] = R.clampToCircle(3, 4, 15); ck(near(x, 3) && near(z, 4));
    const [hx, hz, hy] = R.hohoDestination(0, 0, 0); ck(near(hx, 0) && near(hz, 1.6) && near(hy, 0));
    expect(R.stepDirection(0, 0.1)).toEqual([-1, 0]);
    expect(R.stepDirection(0, 0.1, 1)).toEqual([1, 0]);
    ck(!R.runStopP(1.4, 1, 8) && R.runStopP(1.3, 1, 8) && !R.runStopP(1, -1, 8) && !R.runStopP(1.25, 0, 10));
    ck(near(R.runCarry(5), 1) && near(R.runCarry(1.7), 0.5) && near(R.runCarry(1), 0));
    ck(near(R.brakeSpeed(9, 3), 4.5) && near(R.brakeSpeed(9, 6), 0) && near(R.brakeSpeed(9, 9), 0));
    ck(near(kit('yamamoto', 'base').run, 8) && near(kit('kenpachi', 'base').run, 10));
    ck(kit('kenpachi', 'base').runClips[0] === 'ke-run');
    ck((kit('kenpachi', 'base').ai!.dash as number) > (kit('yamamoto', 'base').ai!.dash as number) && kit('yamamoto', 'base').ai!.dashBack);
  });
  it('hit volumes', () => {
    const hits = (v: number[], x: number, z: number, y = 0) => volHitP(v, 0, 0, 0, 0, -1, x, y, z, 0.38, 1.8, 0);
    const arc = makeVol(['arc', 2.4, 100, 0.2, 2.0]);
    ck(near(arc[2], deg(50)) && hits(arc, 0, -2) && !hits(arc, 0, 2) && !hits(arc, 0, -3) && !hits(arc, 0, -2, 3));
    ck(hits(makeVol(['cap', 0.3, 8.0, 1.0, 0.5]), 0.5, -7.5) && hits(makeVol(['sph', 2.0, 0.0, 1.0]), 0, -2.5));
    ck(capsuleCylHitP(0, 1, 0, 0, 1, -9, 0.3, 0.5, 0, -5, 0.4, 1.8) && !capsuleCylHitP(0, 1, 0, 0, 1, -9, 0.3, 1.0, 0, -5, 0.4, 1.8));
    ck(!capsuleCylHitP(0, 1, 0, 0, 1, -9, 0.3, 0, 0, -10, 0.4, 1.8) && !capsuleCylHitP(0, 3, 0, 0, 3, -9, 0.3, 0, 0, -5, 0.4, 1.8));
    ck(capsuleCylHitP(0, 0.5, 0, 2, 1.5, 0, 0.3, 2.5, 0, 0, 0.4, 1.8) && capsuleCylHitP(0, 1, -5, 0, 1, -5, 0.5, 0.6, 0, -5, 0.4, 1.8));
    ck(oboxCylHitP(0, 1, -5, 0, 3, 1, 0.5, 2.5, 0, -5, 0.4, 1.8) && !oboxCylHitP(0, 1, -5, 0, 3, 1, 0.5, 3.5, 0, -5, 0.4, 1.8));
    ck(oboxCylHitP(0, 1, -5, 0, 3, 1, 0.5, 0, 0, -5.8, 0.4, 1.8) && !oboxCylHitP(0, 1, -5, 0, 3, 1, 0.5, 0, 0, -6.0, 0.4, 1.8));
    ck(oboxCylHitP(0, 1, -5, deg(90), 3, 1, 0.5, 0, 0, -7.5, 0.4, 1.8) && !oboxCylHitP(0, 1, -5, deg(90), 3, 1, 0.5, 0, 0, -8.5, 0.4, 1.8));
    ck(!oboxCylHitP(0, 1, -5, 0, 3, 1, 0.5, 0, 3, -5, 0.4, 1.8));
    ck(cylCylHitP(3, 0, 0, 0.6, 3, 3.8, 0, 0, 0.4, 1.8) && !cylCylHitP(3, 0, 0, 0.6, 3, 4.1, 0, 0, 0.4, 1.8) && !cylCylHitP(3, 0, 0, 0.6, 3, 3.5, 3.5, 0, 0.4, 1.8));
  });
});

describe('kit sanity (the §5 tables, base forms)', () => {
  it('frame data', () => {
    const table: [string, number | null, number | null, number | null, number | null, number | string | null][] = [
      ['ya-j1', 9, 3, 12, 38, -2], ['ya-j2', 8, 3, 13, 38, -2], ['ya-j3', 9, 3, 18, 45, -4], ['ya-k1', 18, 4, 20, 75, -3],
      ['ya-k2', 22, 4, 24, 64, -3], ['ya-k3', 22, 5, 34, 88, -20], ['ya-sig', 16, null, 26, 30, -6], ['ya-taimatsu', 16, 8, 24, 120, -14],
      ['ya-breaker', 8, 4, 18, 150, 'guard-break'],
      ['ke-j1', 7, 3, 12, 35, -2], ['ke-j2', 7, 3, 13, 35, -2], ['ke-j3', 8, 3, 18, 42, -4], ['ke-k1', 16, 4, 20, 70, -3],
      ['ke-k2', 20, 4, 24, 60, -3], ['ke-k3', 20, 5, 34, 80, -20], ['ke-stance', 8, 4, 24, 100, -14], ['ke-buttagiru', 22, 4, 26, 180, -14],
      ['ke-charge', 14, null, null, 25, -16], ['ke-breaker', 8, 4, 18, 150, 'guard-break'],
    ];
    for (const [name, s, a, r, dmg, adv] of table) {
      const m = findMove(name), same = (want: unknown, got: unknown) => want === null || want === got;
      ck(same(s, m.s) && same(a, m.a) && same(r, m.r) && same(dmg, m.dmg) && same(adv, m.advBlock), name);
    }
    expect(findMove('ya-sig').hits.map((w) => [w.from, w.dmg])).toEqual([[16, 30], [28, 30]]);
    ck(findMove('ya-sig').params.dmg === 110);
    expect(findMove('ke-stance').hold).toEqual([6, 60]);
    expect(findMove('ya-shiranui').hold).toEqual([12, 60]);
  });
  it('every form: commands mapped, strings resolve, frames consistent, kikon modules', () => {
    const KINDS = ['quick', 'flash', 'sig', 'sp', 'breaker', 'kikon'];
    for (const [c, f] of FORMS) {
      const k = kit(c, f);
      ck(['q', 'f', 'sig', 'sp1', 'sp2', 'breaker', 'kikon'].every((cmd) => kitCommandMove(k, cmd)));
      ck(k.strings.every(([from, cmd]) => k.moves.has(from) && kitNext(k, from, cmd)));
      for (const m of k.moves.values()) {
        const ok = KINDS.includes(m.kind) && m.s >= 0 && m.a >= 0 && m.r >= 0 && m.whiff >= m.r
          && m.hits.every((w) => m.s <= w.from && w.from < w.to && w.to <= m.s + m.a && w.vols.length > 0)
          && (m.kind === 'kikon' || m.dmg === 0 || m.hits.length > 0)
          && m.onFrame.every(([fr]) => fr < mvTotal(m)) && (m.kind !== 'kikon' || !!m.cine);
        ck(ok, `${c} ${m.name}`);
      }
      const o = kitCommandMove(k, 'kikon')!;
      ck(o.kind === 'kikon' && !!o.cine && o.hits.length === 1 && (o.advBlock as number) <= -12 && o.reach > T.kikonTrigger && o.dmg > 0
         && T.kikonTrigger + T.blockPushback <= Math.min(mv('yamamoto', 'base', 'ya-k1').reach, mv('kenpachi', 'base', 'ke-k1').reach));
    }
    for (const [c, f, name, reach, pressF] of [['yamamoto', 'base', 'ya-kikon', 9.0, 26], ['kenpachi', 'base', 'ke-kikon', 9.4, 50]] as const) {
      const m = mv(c, f, name), p = m.params;
      ck(kitCommandMove(kit(c, f), 'kikon')!.name === name && m.cooldown === 90 && !!m.cine && m.dmg === 70 && m.advBlock === -14
         && p.aura >= 5 && m.armorHits <= 1 && (p.dashTrack > 0 || p.dashMax === 0 || p.aura >= 8), name);
      ck(near(reach, Math.max(m.reach, R.kikonRushReach(p.speed, p.dashMax)), 0.01), name);
      expect(p.aura + p.dashMax + m.s).toBe(pressF);
    }
    ck(findMove('ke-kikon').armorHits === 1 && near(findMove('ya-kikon').track, 0) && near(findMove('ke-kikon').params.dashTrack, 150));
    ck(near(mv('kenpachi', 'base', 'ke-kikon').clipSpeed, 8 / 9));
    ck(kitCommandCost(kit('yamamoto', 'base'), 'sp2') === 1 && kitCommandCost(kit('yamamoto', 'base'), 'sp1') === 1 && kitCommandCost(kit('kenpachi', 'base'), 'q') === 0);
    ck(near(kit('yamamoto', 'base').walk, 3.2) && near(kit('kenpachi', 'base').resetReiatsu, 10));
    expect(kit('yamamoto', 'base').introWeapon).toEqual(['ya-cane', 81]);
    ck(findMove('ya-breaker').planted && near(findMove('ke-stance').blend, 6));
    const fl = findMove('ke-flurry');
    ck(fl.hits.length === 5 && fl.hits[4].dmg === 60 && fl.hits[4].react === 'launch'
       && findMove('ke-charge').dmg + fl.hits.reduce((s, w) => s + w.dmg, 0) === 25 + 4 * 25 + 60);
    ck(makeHitwin().stun === null && makeHitwin({ stun: 40 }).stun === 40);
  });
});

describe('the guard lock', () => {
  it('guardLockedP', () => {
    ck(R.guardLockedP('guard-hit', false, 0, 'move', 'main', 20, 10, 3, 12, true, true));
    ck(!R.guardLockedP('guard-hit', false, 0, 'move', 'main', 24, 10, 3, 12, true, true));
    ck(!R.guardLockedP('guard-hit', false, 0, 'move', 'main', 20, 10, 3, 12, true, false));
    ck(!R.guardLockedP('guard-hit', false, 0, 'move', 'main', 20, 10, 3, 12, false, true));
    ck(!R.guardLockedP('guard-hit', true, 0, 'idle', null, 0, 0, 0, 0, false, false));
    ck(!R.guardLockedP('guard-hit', true, 0, 'step', null, 0, 0, 0, 0, false, false));
    ck(R.guardLockedP('guard-hit', true, 0, 'move', 'main', 3, 10, 3, 12, true, false) && R.guardLockedP('guard-hit', true, 0, 'move', 'hold', 0, 10, 3, 12, true, false)
       && R.guardLockedP('guard-hit', true, 0, 'move', 'main', 12, 10, 3, 12, true, false) && !R.guardLockedP('guard-hit', true, 0, 'move', 'main', 13, 10, 3, 12, true, false));
    ck(R.guardLockedP('guard-hit', true, 5, 'idle', null, 0, 0, 0, 0, false, false) && !R.guardLockedP('guard-hit', true, 5, 'step', null, 0, 0, 0, 0, false, false));
    ck(R.burstMode('guard-hit', false, 0, null) === 'blue' && !R.guardLockedP('idle', true, 5, 'move', 'main', 20, 10, 3, 12, true, true));
  });
  it('a blocked link that goes on holds the defender to even; an ender keeps its advantage', () => {
    for (const [c, f] of FORMS) {
      const k = kit(c, f);
      for (const [m] of linkMoves(k)) if (Number.isInteger(m.advBlock) && m.hits.length > 0) {
        const more = stringLinkP(k, m.name), [att, def] = lockedFreeSteps(m, more);
        expect(def - att, `${c} ${m.name}`).toBe(more ? Math.max(0, m.advBlock as number) : m.advBlock);
      }
    }
  });
});

// ================================================================ the controls (tests/duel-control-test.lisp)
const steps = (vp: Vpad, n: number) => { for (let i = 0; i < n; i++) vp.beginStep(); };
const tap = (vp: Vpad, a: Action) => { vp.beginStep(); vp.set(a, true); vp.beginStep(); vp.set(a, false); };
const pressed = (...as: Action[]) => { const vp = newVpad(); vp.beginStep(); for (const a of as) vp.set(a, true); return vp; };
const cmd = (vp: Vpad, allowed: string[] | null = null) => vp.command(COMMANDS, allowed);

describe('the vpad and the command table', () => {
  it('buffer window, consume, hold', () => {
    expect(VPAD_ACTIONS.length).toBe(9);
    const vp = newVpad();
    vp.beginStep(); vp.set('quick', true);
    ck(vp.pressed('quick') && vp.down('quick') && vp.held('quick') === 1);
    vp.set('quick', false);
    steps(vp, 9); ck(vp.pressed('quick'));                          // 10th step: still buffered
    steps(vp, 1); ck(!vp.pressed('quick'));                         // 11th: gone
    ck(!vp.pressed('flash'));
    tap(vp, 'flash'); ck(vp.pressed('flash') && !vp.pressed('flash', 1));
    vp.consume('flash'); ck(!vp.pressed('flash'));
    vp.beginStep(); vp.set('guard', true); vp.consume('guard');
    steps(vp, 3); vp.set('guard', true);
    ck(vp.down('guard') && !vp.pressed('guard') && vp.held('guard') === 4);
    vp.set('guard', false); ck(!vp.down('guard') && vp.held('guard') === 0);
    vp.set('guard', true); ck(vp.pressed('guard'));
    vp.clear(); ck(!vp.down('guard') && !vp.pressed('guard') && cmd(vp) === null);
  });
  it('priority and modifier combos', () => {
    expect(cmd(pressed('quick'))).toEqual(['q', 'quick']);
    expect(cmd(pressed('quick', 'flash'))).toEqual(['f', 'flash']);
    expect(cmd(pressed('flash', 'sig'))).toEqual(['sig', 'sig']);
    expect(cmd(pressed('quick', 'step'))).toEqual(['step', 'step']);
    expect(cmd(pressed('breaker', 'sig'))).toEqual(['breaker', 'breaker']);
    expect(cmd(pressed('quick', 'kikon', 'step'))).toEqual(['kikon', 'kikon']);
    expect(cmd(pressed('awaken', 'step'))).toEqual(['awaken', 'awaken']);
    expect(cmd(pressed('mod', 'flash'))).toEqual(['sp1', 'flash']);
    expect(cmd(pressed('mod', 'sig'))).toEqual(['sp2', 'sig']);
    expect(cmd(pressed('mod', 'step'))).toEqual(['hoho', 'step']);
    expect(cmd(pressed('mod', 'quick'))).toEqual(['burst', 'quick']);
    expect(cmd(pressed('mod', 'breaker'))).toEqual(['breaker', 'breaker']);
    expect(cmd(pressed('mod', 'quick', 'sig'))).toEqual(['burst', 'quick']);
    expect(cmd(pressed('mod', 'flash', 'sig'))).toEqual(['sp2', 'sig']);
    let vp = newVpad(); vp.beginStep(); vp.set('flash', true); vp.set('mod', true);   // the same step, mod after
    expect(cmd(vp)).toEqual(['sp1', 'flash']);
    vp = pressed('flash'); vp.beginStep(); vp.set('mod', true);     // Flash first, mod later
    expect(cmd(vp)).toEqual(['f', 'flash']);
    vp = pressed('mod', 'flash'); vp.beginStep(); vp.set('mod', false);   // mod released: still SP1
    expect(cmd(vp)).toEqual(['sp1', 'flash']);
    ck(cmd(pressed('quick'), ['sp1', 'sp2', 'hoho']) === null);
    expect(cmd(pressed('quick', 'mod', 'flash'), ['sp1', 'sp2', 'hoho'])).toEqual(['sp1', 'flash']);
    ck(cmd(pressed('mod', 'flash'), ['q', 'f']) === null);
    expect(cmd(pressed('quick', 'flash'), ['q'])).toEqual(['q', 'quick']);
    vp = pressed('quick', 'flash'); vp.consume(cmd(vp)![1]);
    expect(cmd(vp)).toEqual(['q', 'quick']);
    // a refused top command doesn't hide the next one: both entries are pressed, walked in priority order
    vp = newVpad(); vp.beginStep(); vp.set('kikon', true); vp.set('quick', true);
    expect(COMMANDS.filter(([, b, m]) => vp.commandPressedP(b, m)).map(([c]) => c)).toEqual(['kikon', 'q']);
    // flush: presses forgotten, holds kept
    vp = newVpad(); vp.beginStep(); vp.set('guard', true); vp.set('quick', true); vp.flush();
    ck(vp.down('guard') && !vp.pressed('quick') && cmd(vp) === null);
  });
  it('the stick, relative directions', () => {
    const vp = newVpad();
    vp.stick(3, 4); ck(near(vp.sx, 0.6) && near(vp.sy, 0.8));
    vp.stick(0.3, 0); ck(near(vp.sx, 0.3));
    vp.stick(1, 0);
    let [to, st] = R.stickTowardStrafe(vp.sx, vp.sy, 0, 0, 0, 0, -5); ck(near(to, 0) && near(st, 1));
    vp.stick(0, 1);
    [to, st] = R.stickTowardStrafe(vp.sx, vp.sy, deg(90), 0, 0, -5, 0); ck(near(to, 1) && near(st, 0));
  });
  it('a device reader equals direct injection', () => {
    let held: Set<Action> = new Set();
    const vpDev = newVpad((vp) => { for (const a of VPAD_ACTIONS) vp.set(a, held.has(a)); }), vpInj = newVpad();
    const script: Action[][] = [['quick'], [], ['mod', 'flash'], ['mod'], [], ['awaken'], ['step'], []];
    for (const frame of script) {
      held = new Set(frame);
      vpDev.beginStep(); vpInj.beginStep();
      for (const a of [...VPAD_ACTIONS].reverse()) vpInj.set(a, held.has(a));   // any order
      ck(String(vpDev.downs) === String(vpInj.downs) && String(vpDev.press) === String(vpInj.press)
         && String(vpDev.modded) === String(vpInj.modded));
      expect(cmd(vpDev)).toEqual(cmd(vpInj));
    }
    ck(vpDev.pressed('awaken', 3));
  });
  it('PRACTICE and HUD helpers', () => {
    ck(['idle', 'stun', 'guard-hit'].every((st) => dummyGuardLeft('guard-all', st, 0) === 999));
    ck(['stand', 'cpu'].every((d) => ['idle', 'stun', 'guard-hit'].every((st) => dummyGuardLeft(d, st, 50) === 0)));
    ck(dummyGuardLeft('guard-hit', 'idle', 0) === 0);
    ck(['stun', 'air', 'down', 'wakeup', 'guard-hit'].every((st) => dummyGuardLeft('guard-hit', st, 3) === DUMMY_GUARD_HOLD));
    let left = DUMMY_GUARD_HOLD, n = 0; while (left > 0) { left = dummyGuardLeft('guard-hit', 'guard', left); n++; }
    expect(n).toBe(DUMMY_GUARD_HOLD);
    ck(practiceReishi(1300, 100) === 1300 && practiceReishi(1300, 50) === 650 && practiceReishi(1300, 10) === 130 && practiceReishi(1, 10) > 0);
    ck(practiceReishi(1300, 25) < 1300 * T.redThreshold && 1300 * T.redThreshold < practiceReishi(1300, 50));
    ck(konpakuStep(9, 1, 9) === 1 && konpakuStep(1, -1, 9) === 9 && konpakuStep(4, 1, 9) === 5 && konpakuStep(5, -1, 9) === 4);
    expect([2, 3, 4, 5].map((c) => konpakuAtStake(9, c))).toEqual([2, 3, 4, Math.min(5, T.kikonMaxEvent)]);
    ck(konpakuAtStake(3, 4) === 3 && konpakuAtStake(1, 2) === 1 && konpakuAtStake(0, 3) === 0);
  });
});

// ================================================================ the whole sim
describe('determinism and smoke', () => {
  it('the same seed twice gives identical hash lines and results', () => {
    const a = runSeed('yama', 'ken', 7), b = runSeed('yama', 'ken', 7);
    ck(a.length > 3 && a.some((l) => l.startsWith('duel hash')) && a[a.length - 1].startsWith('duel -> RESULTS'));
    expect(b).toEqual(a);
    expect(runSeed('ken', 'ken', 8)).not.toEqual(runSeed('ken', 'ken', 9));
  });
  it('YY / YK / KK x 3 seeds finish without exceptions', () => {
    for (const [p1, p2] of [['yama', 'yama'], ['yama', 'ken'], ['ken', 'ken']])
      for (let s = 1; s <= 3; s++) {
        const out = runSeed(p1, p2, s);
        ck(out[out.length - 1].startsWith('duel -> RESULTS'), `${p1} ${p2} ${s}`);
      }
  }, 60_000);
});
