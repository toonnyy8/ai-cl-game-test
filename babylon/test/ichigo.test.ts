// ichigo.test.ts: Ichigo's kits and pure rules (ichigo.ts), from tests/duel-rules-test.lisp's Ichigo v2 block.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { findKit, findMove, kitCommandMove, kitKikonCine, kitLLink, kitMove, kitNext, mvTotal, stringLinkP } from '../src/sim/kit';
import { hitstun, parryFrameP, resolveContact } from '../src/sim/rules';
import {
  IC, cloneAfterString, cloneEvict, cloneHitFrame, cloneKonpaku, cloneMove, cloneVanishP, echoHitFrames, echoHitwin,
} from '../src/chars/ichigo';
import { runSeed } from '../tools/headless';

const b = findKit('ichigo', 'base'), ks = findKit('ichigo', 'kessa');
const gv = (k: typeof b, n: string) => kitMove(k, n).hits[0].guard;

describe('Ichigo: kits', () => {
  it('the cross copies, KESSA cuts and routes', () => {
    expect([gv(b, 'ic-j2'), gv(b, 'ic-j2s'), gv(b, 'ic-k2'), gv(b, 'ic-k2s'), gv(b, 'ic-k3')]).toEqual([8, 12, 16, 24, 22]);
    expect(kitMove(b, 'ic-k2s').clip).toBe('ic-cross');
    const kj1 = kitCommandMove(ks, 'q')!, kk1 = kitCommandMove(ks, 'f')!;
    expect(kj1.reach).toBeCloseTo(1.56);
    expect(kk1.reach).toBeCloseTo(2.9);
    expect(kj1.dmg + kitMove(ks, 'ic-k-j2').dmg + kitMove(ks, 'ic-k-j3').dmg).toBe(100);
    expect(kk1.dmg + kitMove(ks, 'ic-k-k2').dmg + kitMove(ks, 'ic-k-k3').dmg).toBe(204);
    expect(gv(ks, 'ic-k-k1')! + gv(ks, 'ic-k-k2')! + gv(ks, 'ic-k-k3')!).toBe(48);
    expect(ks.lAfterK).toBeNull();
    expect(ks.passives).toContain('parry-block');
    expect(ks.walk).toBeLessThan(b.walk);
  });
  it('the stance and its non-button branches', () => {
    const tsuki = kitCommandMove(b, 'sig')!, tk2 = kitLLink(b, 'ic-k1')!;
    expect([tsuki.s, mvTotal(tsuki), tsuki.hits.length, tk2.name, tk2.enter]).toEqual([6, 80, 0, 'ic-tsuki-k2', 4]);
    expect(findMove('ic-tsuki-re').enter).toBe(6);
    expect(kitNext(b, 'ic-tsuki', 'tsuki-j')!.name).toBe('ic-tsuki-j');
    expect(kitNext(b, 'ic-tsuki-dash', 'tsuki-back')!.name).toBe('ic-tsuki-re');
    expect(IC.tsukiUp + kitNext(b, 'ic-tsuki', 'tsuki-l')!.s).toBe(14);
    expect(kitLLink(b, 'ic-j1')).toBeNull();
    expect(stringLinkP(b, 'ic-tsuki')).toBe(false);
    const rj = findMove('ic-tsuki-j');
    expect([rj.hits.length, rj.advBlock, rj.hits[3].react]).toEqual([4, -6, 'stagger']);
  });
  it('the Kikon counts and cinematics', () => {
    expect([b.kikonKonpaku, ks.kikonKonpaku]).toEqual([2, 3]);
    expect(kitKikonCine(ks)).toBe('ic-kessa-getsuga-cine');
    expect(kitKikonCine(b)).toBe('ic-kikon-cine');
    expect(b.ai!.awaken).toEqual({ minTaken: 150 });
  });
});

describe('Ichigo: the clones, the parry, the afterimages', () => {
  it('times and fates the clones', () => {
    expect([cloneHitFrame('q'), cloneHitFrame('f')]).toEqual([22, 14]);
    expect(cloneMove('q', 3).hits[0].react).toBe('crumple');
    expect([0, 1, 2, 3, 5].map(cloneKonpaku)).toEqual([2, 2, 3, 4, 4]);
    expect([cloneAfterString(false, 100), cloneAfterString(true, 100), cloneAfterString(false, 0)]).toEqual(['idle', 'fade', 'fade']);
    expect(cloneEvict([5, 9])).toBeNull();
    expect(cloneEvict([7, 3, 9])).toBe(1);
    expect(['hit', 'counter', 'guard-break'].every((r) => cloneVanishP(r as never))).toBe(true);
    expect(cloneVanishP('blocked') || cloneVanishP('parried') || cloneVanishP(null)).toBe(false);
  });
  it('the parry window, the catch and the counter', () => {
    const parry = kitMove(ks, 'ic-k-parry'), gaeshi = kitMove(ks, 'ic-k-gaeshi'), win = parry.params.window;
    expect([parry.s, parry.a, mvTotal(parry)]).toEqual([2, 24, 44]);
    expect([parryFrameP(2, win), parryFrameP(25, win), parryFrameP(1, win), parryFrameP(26, win)]).toEqual([true, true, false, false]);
    expect(kitNext(ks, 'ic-k-parry', 'land')).toBe(gaeshi);
    expect(gaeshi.s + hitstun('crumple') - mvTotal(gaeshi)).toBe(15);
    expect(resolveContact('parry', { hazard: true, ward: true })).toBe('blocked');
    expect(resolveContact('parry', {})).toBe('parried');
  });
  it('echoes at half (f32 rounding like the Lisp), a blade', () => {
    const kj1 = kitCommandMove(ks, 'q')!, w = echoHitwin(kj1.hits[0], IC.zanzoMult);
    expect(echoHitFrames(kj1)).toEqual([18]);
    expect(echoHitFrames(findMove('ic-tsuki-j'))).toEqual([18, 21, 24, 27]);
    expect([w.dmg, w.guard, w.react]).toEqual([15, 4, 'flinch']);
    expect(w.flags).toContain('blade');
    // 0.7 x 45 is 31.4999995 in doubles but 31.5 in single floats: half-even -> 32
    expect(echoHitwin({ ...kj1.hits[0], dmg: 45 }, IC.cloneScale).dmg).toBe(32);
  });
});

describe('Ichigo: determinism', () => {
  it('IK seed 3 replays identically', () => {
    expect(runSeed('ichigo', 'ken', 3)).toEqual(runSeed('ichigo', 'ken', 3));
  }, 60000);
});
