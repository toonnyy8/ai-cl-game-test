// learn.test.ts <- tests/learn-test.lisp: the learning CPU's pure part (learn.ts): n-gram counting and backoff, decay,
// prediction and its counter, the situations and action classes, the EXP3 update, p_exploit's clamp, the form, the own
// random stream and the storage round trip. One check per Lisp CHECK, in the same order.
import { describe, expect, it } from 'vitest';
import {
  LEARN_ACTIONS, LEARN_ARMS, LEARN_ROWS, LP, LTab, learnAct, learnBand, learnBin, learnBurstP, learnBurstRewardBang,
  learnConfidentP, learnCounter, learnCtx, learnDecode, learnDist, learnEncode, learnEpisode, learnFormAfter, learnMult,
  learnObserve, learnOnset, learnPExploit, learnPredict, learnReward, learnRewardBang, learnRnd, learnRow, learnSit, learnAction,
} from '../src/sim/learn';

let checks = 0;
const check = (c: boolean, what: string) => { checks++; expect(c, what).toBe(true); };
const near = (a: number, b: number, eps = 1e-3) => Math.abs(a - b) < eps;
const s = learnSit, a = learnAct;
const eqArr = (x: ArrayLike<number>, y: ArrayLike<number>, eps: number) => Array.from(x).every((v, i) => (eps === 0 ? v === y[i] : near(v, y[i], eps)));
const fresh = (t: LTab) => {
  const f = new LTab();
  return eqArr(t.c0, f.c0, 0) && eqArr(t.c1, f.c1, 0) && eqArr(t.prev, f.prev, 0) && eqArr(t.arms, f.arms, 0) && eqArr(t.bursts, f.bursts, 0) && t.form === 0;
};

describe('learning CPU (learn-test.lisp)', () => {
  it('counting, decay, backoff, prediction', () => {
    const tab = new LTab();
    check(learnPredict(tab, s('wake'))[0] === null, 'nothing seen: no prediction');
    learnObserve(tab, s('wake'), a('j'));
    check(near(tab.c0[10 * s('wake') + a('j')], 1.0), 'one count');
    check(tab.prev[s('wake')] === a('j'), 'last class');
    learnObserve(tab, s('wake'), a('j'));
    check(near(tab.c0[10 * s('wake') + a('j')], 1.97), 'decay then count');
    check(near(tab.c1[100 * s('wake') + 10 * a('j') + a('j')], 1.0), 'order 1: J after J');
    const [act, p, n] = learnPredict(tab, s('wake'));
    check(act === a('j') && near(p, 1.0) && near(n, 1.97), 'predicts J');
    check(learnConfidentP(p, n), 'confident');
    check(learnPredict(tab, s('far'))[0] === null, 'other situations untouched');
    for (let i = 0; i < 30; i++) learnObserve(tab, s('wake'), a('i'));
    check(near(tab.c0[10 * s('wake') + a('j')], 1.97 * 0.97 ** 30, 1e-3), 'decayed count');
    check(learnPredict(tab, s('wake'))[0] === a('i'), 'now I');

    const t1 = new LTab(), sit = s('close');
    for (let i = 0; i < 6; i++) { learnObserve(t1, sit, a('guard')); learnObserve(t1, sit, a('i')); }
    const [act1, p1] = learnPredict(t1, sit);
    check(act1 === a('guard'), 'after I comes guard');
    check(p1 > 0.6, 'order 1 dominates');
    learnObserve(t1, sit, a('guard'));
    check(learnPredict(t1, sit)[0] === a('i'), 'after guard comes I');
    const t2 = new LTab();
    for (let i = 0; i < 4; i++) learnObserve(t2, sit, a('k'));
    learnObserve(t2, sit, a('hoho'));
    const [pv, n2] = learnDist(t2, sit);
    check(near(Array.from(pv!).reduce((x, y) => x + y, 0), 1.0), 'a distribution');
    check(pv![a('k')] > pv![a('hoho')], 'shrunk toward order 0');
    check(n2 > 4.0, 'evidence');
    check(!learnConfidentP(0.9, 1.0), 'too little evidence');
    check(!learnConfidentP(0.3, 10.0), 'too flat');
  });

  it('counters, situations, classes', () => {
    check(learnCounter(a('guard')) === 'breaker', 'I beats guard');
    check(learnCounter(a('j')) === 'guard', 'guard beats J');
    check(learnCounter(a('i')) === 'q', 'J beats I');
    check(learnCounter(a('hoho')) === 'hoho-punish', 'hoho punish');
    check(learnCounter(a('back')) === null, 'backing off: no read');
    check(LEARN_ACTIONS.every((k) => k === 'back' || learnCounter(a(k)) !== null), 'every class but back answered');
    check(learnCounter(a('burst')) === 'dash-in', 'a neutral burst is rushed');
    check(learnCounter(a('burst'), s('c-hit')) === 'bait', 'baited while our string hits');
    check(learnCounter(a('guard'), s('c-hit')) === null, 'he took it');
    check(learnCounter(a('guard'), s('close')) === 'breaker', 'no override elsewhere');
    check(learnBand(1.0) === s('close') && learnBand(3.0) === s('mid') && learnBand(9.0) === s('far'), 'bands');
    check(learnBin(0.5) === 0 && learnBin(2.0) === 1 && learnBin(20.0) === 4, 'bins');
    check(learnOnset('down', 'wakeup', null, 'idle', 'idle', -1, 3.0) === s('wake'), 'wake');
    check(learnOnset('idle', 'idle', null, 'down', 'wakeup', 5, 3.0) === s('knock'), 'knock overrides neutral');
    check(learnOnset('guard-hit', 'guard', null, 'move', 'move', -1, 2.0) === s('h-blocked'), 'h-blocked');
    check(learnOnset('move', 'move', 'hit', 'guard-hit', 'idle', -1, 2.0) === s('c-blocked'), 'c-blocked');
    check(learnOnset('move', 'idle', null, 'idle', 'idle', 6, 2.0) === s('whiff'), 'whiff');
    check(learnOnset('move', 'idle', 'block', 'idle', 'idle', 6, 2.0) === null, 'a blocked move is no whiff');
    check(learnOnset('idle', 'idle', null, 'idle', 'idle', -1, 4.0) === s('mid'), 'neutral opens');
    check(learnOnset('idle', 'idle', null, 'idle', 'idle', 6, 4.0) === null, 'one open already');
    check(learnOnset('idle', 'move', null, 'idle', 'idle', -1, 4.0) === null, 'not while he is busy');
    check(learnOnset('stun', 'stun', null, 'move', 'move', -1, 2.0, true) === s('c-hit'), 'our hit opened his burst');
    check(learnOnset('stun', 'air', null, 'move', 'move', 7, 2.0, true) === s('c-hit'), 'c-hit overrides neutral');
    check(learnOnset('stun', 'stun', null, 'move', 'move', 5, 2.0, true) === null, 'open already');
    check(learnOnset('idle', 'stun', null, 'move', 'move', -1, 2.0, false) === null, 'no burst possible yet');
    check(learnAction('idle', 'move', 'quick', false, 0.0) === a('j'), 'J');
    check(learnAction('move', 'move', 'breaker', true, 0.0) === a('i'), 'a new move');
    check(learnAction('move', 'move', 'breaker', false, 0.0) === null, 'the same one');
    check(learnAction('guard-hit', 'guard', null, false, 0.0) === a('guard'), 'guard');
    check(learnAction('idle', 'hoho', null, false, 0.0) === a('hoho'), 'hoho');
    check(learnAction('idle', 'step', null, false, 0.0) === a('hoho'), 'step');
    check(learnAction('idle', 'run', null, false, 1.5) === a('back'), 'back');
    check(learnAction('idle', 'idle', null, false, 0.5) === null, 'nothing');
    check(learnAction('stun', 'stun', null, false, 0.0, true) === a('burst'), 'a burst begun');
    check(learnAction('idle', 'move', 'quick', false, 0.0, true) === a('burst'), 'burst wins over the move');
    check(learnCtx(0, 0.0) === 0 && learnCtx(1, 0.9) === 5 && learnCtx(20, 1.0) === 23 && learnCtx(2, 0.34) === 7, 'contexts');
    check(learnRow(3, 4) === 19, 'row');
    check(learnEpisode(s('wake')) === 75 && learnEpisode(s('far')) === 60, 'episodes');
  });

  it('EXP3 and the burst bandits', () => {
    const tab = new LTab(), arm = LEARN_ARMS.indexOf('breaker');
    check(near(learnMult(tab, 0, arm), 1.0), 'fresh x1');
    learnRewardBang(tab, 0, arm, 0.5, 1.0);
    check(near(tab.arms[arm], 0.3), '+eta r / p');
    check(learnMult(tab, 0, arm) > 1.3, 'raised');
    check(near(learnMult(tab, 1, arm), 1.0), 'other bins untouched');
    learnRewardBang(tab, 0, 0, 0.5, 0.0);
    check(near(tab.arms[arm], 0.3 * 0.98), 'decay x gamma');
    for (let i = 0; i < 50; i++) learnRewardBang(tab, 0, arm, 0.01, -1.0);
    check(near(learnMult(tab, 0, arm), 0.25, 1e-3), 'floor and clamp');
    for (let i = 0; i < 50; i++) learnRewardBang(tab, 0, arm, 0.01, 1.0);
    check(near(learnMult(tab, 0, arm), 4.0, 1e-2), 'clamp x4');
    check(learnReward(300, 0) === 1.0 && learnReward(0, 300) === -1.0 && near(learnReward(75, 0), 0.5), 'rewards');
    const tb = new LTab();
    check(near(learnBurstP(tb, 1, 0.6), 0.6), 'fresh = base chance');
    learnBurstRewardBang(tb, 1, true, 0.6, 1.0);
    check(learnBurstP(tb, 1, 0.6) > 0.6, 'a paying use raises it');
    check(near(learnBurstP(tb, 0, 0.3), 0.3), 'other colours untouched');
    for (let i = 0; i < 40; i++) learnBurstRewardBang(tb, 2, false, 0.8, 1.0);
    check(learnBurstP(tb, 2, 0.25) < 0.08, 'a paying "don\'t" lowers it (x4 at most)');
    check(near(learnBurstP(tb, 1, 0.0), 0.0), 'zero stays zero');
    check(near(learnReward(0, 0, 75), 0.5), 'a heal counts');
  });

  it('p_exploit, form, the own stream', () => {
    check(near(learnPExploit(0.0), 0.35), 'mid');
    check(near(learnPExploit(-1.0), 0.15), 'floor');
    check(near(learnPExploit(1.0), 0.6), 'cap');
    check(learnPExploit(-0.5) < learnPExploit(0.0) && learnPExploit(0.0) < learnPExploit(0.5), 'monotone');
    check(near(learnFormAfter(0.0, 1.0, 0.2), 0.2), 'ema');
    check(near(learnFormAfter(0.9, 1.0, 1.0), 1.0), 'k 1');
    let f = 0.0;
    for (let i = 0; i < 50; i++) f = learnFormAfter(f, -1.0, 0.2);
    check(near(f, -1.0, 1e-3), 'converges');
    const [r1, s1] = learnRnd(12345), [r2, s2] = learnRnd(12345);
    check(r1 === r2 && s1 === s2 && r1 >= 0 && r1 < 1, 'deterministic');
    let sum = 0, st = s1;
    for (let i = 0; i < 2000; i++) { const [r, n] = learnRnd(st); sum += r; st = n; }
    check(sum / 2000 > 0.45 && sum / 2000 < 0.55, 'uniform-ish');
  });

  it('storage round trip', () => {
    const tab = new LTab();
    for (let i = 0; i < 20; i++) { learnObserve(tab, s('wake'), a('j')); learnObserve(tab, s('close'), i % 3); }
    learnObserve(tab, s('far'), a('back'));
    learnRewardBang(tab, 2, 3, 0.25, 0.8); learnRewardBang(tab, 117, 9, 0.5, -0.6); learnBurstRewardBang(tab, 1, true, 0.5, 0.7);
    tab.form = Math.fround(-0.437);
    const codes = learnEncode(tab), back = learnDecode(codes);
    check(codes.every(Number.isInteger), 'integers');
    check(codes.every((c) => c > -1 && c < 2 ** 31), "the page's 32-bit integers");
    check(codes.length < 999, 'short');
    check(eqArr(tab.c0, back.c0, 0.051), 'order 0');
    check(eqArr(tab.c1, back.c1, 0.051), 'order 1');
    check(eqArr(tab.arms, back.arms, 6e-4), 'bandit');
    check(eqArr(tab.bursts, back.bursts, 6e-4), 'bursts');
    check(eqArr(tab.prev, back.prev, 0), 'last classes');
    check(near(back.form, -0.437), 'form');
    check(learnPredict(tab, s('close'))[0] === learnPredict(back, s('close'))[0], 'same prediction (EQUAL sees the primary value)');
    check(JSON.stringify(codes) === JSON.stringify(learnEncode(back)), 'stable');
    check(fresh(learnDecode(null)), 'nothing saved: a fresh table');
    check(fresh(learnDecode([0, -5, 3000 * 65536 + 7])), 'garbage: no negative count, unknown entries skipped');
    const big = new LTab(), decay = LP.decay;
    LP.decay = 1.0;
    for (let sit = 0; sit < 9; sit++) for (let p = 0; p < 10; p++) for (let x = 0; x < 10; x++) { learnObserve(big, sit, p); learnObserve(big, sit, x); }
    LP.decay = decay;
    const cap = LP.cap, armCap = LP.armCap;
    LP.cap = 50;
    check(learnEncode(big).filter((c) => { const i = Math.floor(c / 65536); return i >= 100 && i <= 999; }).length <= 50, 'order-1 cap');
    LP.cap = cap;
    for (let r = 0; r < LEARN_ROWS; r++) learnRewardBang(big, r, r % 10, 0.5, 0.5);
    LP.armCap = 40;
    check(learnEncode(big).filter((c) => { const i = Math.floor(c / 65536); return i >= 1000 && i <= 2199; }).length <= 40, 'bandit cap');
    LP.armCap = armCap;
    check(learnEncode(big).length < 999, 'capped size');
    const code = (i: number, v: number) => i * 65536 + Math.round(v) + 32768;
    const v1 = learnDecode([code(999, 1), code(5 * 9 + 1, 20), code(100 + 81 * 7 + 9 * 2 + 3, 15), code(905, 3), code(950, -250), code(820, 400)]);
    check(near(v1.c0[10 * s('close') + a('j')], 2.0), 'v1 close (5) is v2 6');
    check(near(v1.c1[100 * s('far') + 10 * a('k') + a('i')], 1.5), 'v1 order 1');
    check(v1.prev[s('close')] === a('k'), 'v1 last class');
    check(near(v1.form, -0.25), 'v1 form');
    check(v1.arms.every((x) => x === 0), 'v1 bandit dropped');
  });

  it('as many checks as the Lisp file', () => expect(checks).toBe(100));
});
