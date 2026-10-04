// ken.test.ts: Kenpachi's forms (ken.ts): the NOME cups' thresholds and drain, the cash-out, the Bankai's entry.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { T } from '../src/sim/tuning';
import { callHook, findKit, kitMove } from '../src/sim/kit';
import { ladderRung, meterDrain, type Rung } from '../src/sim/rules';
import { Match } from '../src/sim/match';
import { W } from '../src/sim/types';
import { nomeStep, setForm } from '../src/sim/combat';
import { tryCommand } from '../src/sim/fighter';

const ladder = findKit('kenpachi', 'nozarashi').meter!.ladder as Rung[];
/** A KK match past its intro, P1 free in FORM with NOME at N. */
function ken(form: string, n = 0) {
  const m = new Match({ p1: 'kenpachi', p2: 'kenpachi', seed: 1 }).start();
  m.step();
  const e = W.p1;
  setForm(e, form);
  e.f.state = 'idle'; e.g.meter = n; e.g.meterIdle = 0;
  return e;
}

describe('Kenpachi: kits', () => {
  it('derives KATATE / RYOTE from the base moves, NOMIHOSE plays RYOTE', () => {
    const k1 = kitMove(findKit('kenpachi', 'nozarashi'), 'ke-k1');
    expect(k1.s).toBe(16 + T.nozarashiStartup);
    expect(k1.reach).toBeCloseTo(2.8 * T.nozarashiReach);
    expect(kitMove(findKit('kenpachi', 'ryote'), 'ke-stance').s).toBe(8 + T.ryoteStartup);
    expect(findKit('kenpachi', 'nomihose').commands.q).toBe('ke-r-j1');
    expect(findKit('kenpachi', 'nomihose').passives).toContain('drink');
    expect(kitMove(findKit('kenpachi', 'kataude'), 'ke-k1').reach).toBeCloseTo(2.8 * T.kataudeReach);
    expect(findKit('kenpachi', 'bankai').meterGain).toBeNull();
  });
});

describe('Kenpachi: the NOME cups', () => {
  it('climbs at 40 / 100 and falls below 25 / 50 (hysteresis, several rungs at once)', () => {
    expect(ladderRung(39.9, 0, ladder)).toBe(0);
    expect(ladderRung(40, 0, ladder)).toBe(1);
    expect(ladderRung(100, 0, ladder)).toBe(2);
    expect(ladderRung(25, 1, ladder)).toBe(1);
    expect(ladderRung(24.9, 1, ladder)).toBe(0);
    expect(ladderRung(50, 2, ladder)).toBe(2);
    expect(ladderRung(49.9, 2, ladder)).toBe(1);
    expect(ladderRung(10, 2, ladder)).toBe(0);
  });
  it('the free fighter takes the rung NOME asks for', () => {
    const e = ken('nozarashi', 100);
    nomeStep(e, e.f, e.g, ladder);
    expect(e.f.form).toBe('nomihose');
  });
  it('RYOTE drains 3/s after 180 f without a gain; NOMIHOSE 20/s always; KATATE never', () => {
    expect(meterDrain(60, T.nomeDrainT2, T.nomeDelay, 179)).toBe(60);
    expect(meterDrain(60, T.nomeDrainT2, T.nomeDelay, 180)).toBeCloseTo(60 - 3 / 60, 5);
    expect(meterDrain(60, T.nomeDrainT3, 0, 0)).toBeCloseTo(60 - 20 / 60, 5);
    expect(meterDrain(60, 0, 0, 999)).toBe(60);
    const e = ken('nomihose', 100);
    for (let i = 0; i < 60; i++) nomeStep(e, e.f, e.g, ladder);
    expect(e.g.meter).toBeCloseTo(80, 3);                            // one second of cup 3
  });
  it('the cash-out drinks the cup dry: NOME 0 and cup 1 at once', () => {
    const e = ken('nomihose', 70);
    callHook('ken-drink-dry', e);
    expect(e.g.meter).toBe(0);
    expect(e.f.form).toBe('nozarashi');
  });
});

describe('Kenpachi: the Bankai', () => {
  it('P in cup 3: refused with 5 Konpaku, taken with 4: Konpaku 1, Reishi full, the arm full', () => {
    const e = ken('nomihose', 100);
    e.g.awakened = true; e.g.konpaku = 5;
    expect(tryCommand(e, e.f, 'awaken')).toBe(false);
    expect(e.f.form).toBe('nomihose');
    e.g.konpaku = T.bankaiKonpaku; e.g.reishi = 100;
    expect(tryCommand(e, e.f, 'awaken')).toBe(true);
    expect(e.f.form).toBe('bankai');
    expect(e.g.konpaku).toBe(1);
    expect(e.g.reishi).toBe(e.g.reishiMax);
    expect(e.g.meter).toBe(T.armPips);
  });
  it('not from cup 2, not while busy', () => {
    const e = ken('ryote', 60);
    e.g.awakened = true; e.g.konpaku = 2;
    expect(tryCommand(e, e.f, 'awaken')).toBe(false);
    const n = ken('nomihose', 100);
    n.g.awakened = true; n.g.konpaku = 2; n.f.state = 'stun';
    expect(tryCommand(n, n.f, 'awaken')).toBe(false);
  });
});
