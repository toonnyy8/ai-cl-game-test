// yama.test.ts: Yamamoto's forms (yama.ts): Hellfire's entry / burn / end, the Bankai's entry, East / West, MINAMI's bind.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { T } from '../src/sim/tuning';
import { callHook, findKit, kitDrop, kitMove } from '../src/sim/kit';
import { Match } from '../src/sim/match';
import { W } from '../src/sim/types';
import { awaken, gaugeSystem, setForm } from '../src/sim/combat';

/** A YY match past its intro, P1 idle in FORM. */
function yama(form = 'base') {
  const m = new Match({ p1: 'yamamoto', p2: 'yamamoto', seed: 1 }).start();
  m.step();
  const e = W.p1;
  if (form !== 'base') setForm(e, form);
  e.f.state = 'idle';
  return e;
}

describe('Yamamoto: kits', () => {
  it('East derives the inherited moves (-1 f, reach x1.15), West drops to East but for L / SP1', () => {
    const east = findKit('yamamoto', 'bankai-east'), west = findKit('yamamoto', 'bankai-west');
    expect(kitMove(east, 'ya-breaker').s).toBe(kitMove(findKit('yamamoto', 'base'), 'ya-breaker').s - 1);
    expect(kitMove(east, 'ya-breaker').reach).toBeCloseTo(T.breakerReach * 1.15, 5);
    expect(kitMove(east, 'ya-e-j1').s).toBe(8);                      // its own commands: as written
    expect(east.meter).toBeNull();
    expect(east.passives).toEqual(['projectile-cut', 'pierce']);
    expect(east.guardTo).toBe('bankai-west');
    expect(west.passives).toEqual(['ward', 'scorch']);
    expect(kitDrop(west, 'q')).toBe('bankai-east');
    expect(kitDrop(west, 'sig')).toBeNull();
    expect(kitDrop(west, 'sp1')).toBeNull();
    expect(west.strings).toContainEqual(['ya-w-parry', 'land', 'ya-w-counter']);
  });
});

describe('Yamamoto: Hellfire', () => {
  it('a full Inferno enters it: Ennetsu pillars, the self-burn, the 10 s timer, then back to the Shikai', () => {
    const e = yama();
    e.g.meter = T.infernoMax;
    gaugeSystem();
    expect(e.f.form).toBe('hellfire');
    expect(e.g.meter).toBe(0);
    expect(e.g.formLeft).toBe(Math.round(60 * T.hellfireSeconds));
    const pillars = W.hazards.filter((h) => h.alive && h.kind === 'pillars');
    expect(pillars.length).toBe(1);
    expect(pillars[0].hitsLeft).toBe(T.ennetsuHits);
    // the self-burn (30), then 5 % of max Reishi per second for 10 s
    const perSecond = Math.round(e.g.reishiMax * T.hellfireBurn);
    for (let i = 0; i < 60 * T.hellfireSeconds; i++) { expect(e.f.form).toBe('hellfire'); gaugeSystem(); }
    expect(e.f.form).toBe('base');
    expect(e.g.reishi).toBe(T.reishiMax - T.ennetsuSelfBurn - perSecond * T.hellfireSeconds);
    expect(e.g.meter).toBe(0);                                         // the Inferno starts over
  });
  it('NADEGIRI replaces SP2 and costs 2 bars; damage x1.3', () => {
    const k = findKit('yamamoto', 'hellfire');
    expect(k.commands.sp2).toBe('ya-nadegiri');
    expect(kitMove(k, 'ya-nadegiri').cost).toBe(2);
    expect(k.mult).toBeCloseTo(1.3, 5);
  });
});

describe('Yamamoto: the Bankai', () => {
  it('awakening enters East: Inferno emptied for good, the heal, its cinematic', () => {
    const e = yama();
    e.g.reishi = 500; e.g.meter = 50; e.g.awaken = T.awakenMax; e.g.evolution = true;
    awaken(e);
    expect(e.f.form).toBe('bankai-east');
    expect(e.g.meter).toBe(0);
    expect(e.g.awakened).toBe(true);
    expect(e.g.reishi).toBe(500 + Math.round(T.awakenHeal * e.g.reishiMax));
    expect(W.cine?.name).toBe('yama-bankai-cine');
    e.g.meter = T.infernoMax;                                          // no meter in the Bankai: never Hellfire again
    W.cine = null;
    gaugeSystem();
    expect(e.f.form).toBe('bankai-east');
  });
  it('West enters with the ward (enter hook) and leaves to East', () => {
    const e = yama('bankai-east');
    setForm(e, 'bankai-west');
    expect(e.f.form).toBe('bankai-west');
    setForm(e, 'bankai-east');
    expect(e.f.form).toBe('bankai-east');
  });
  it('MINAMI f20 marks the point under him: a bind hazard 16 f later, four hands', () => {
    const e = yama('bankai-east');
    e.f.move = kitMove(e.f.kit, 'ya-kaka');
    callHook('yama-south', e);
    const bind = W.hazards.find((h) => h.alive && h.kind === 'bind')!;
    expect(bind.delay).toBe(17);                                       // (counts down in its spawn step)
    expect(bind.hw!.flags).toContain('unguardable');
    expect(bind.hw!.stun).toBe(T.bindStun);
    expect(W.hazards.filter((h) => h.alive && h.kind === 'hand').length).toBe(4);
    const o = W.p2;
    expect(Math.hypot(bind.x - o.pos[0], bind.z - o.pos[2])).toBeLessThan(1e-5);   // 8 m: within its 10 m range
  });
});
