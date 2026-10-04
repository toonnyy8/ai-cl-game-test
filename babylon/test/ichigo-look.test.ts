// ichigo-look.test.ts: every move of both of Ichigo's forms (and his clones' answers) has its own clip, keyed in phase u
// from 0 to 3 in order over real bones; each form has its stance; the KESSA body swaps the feet, the lapels and the knife.
import { expect, it } from 'vitest';
import '../src/chars';
import { KITS, findMove } from '../src/sim/kit';
import { BONES } from '../src/render/pose';
import { clip, stance } from '../src/render/clips/ichigo';
import { ichigo } from '../src/render/bodies/ichigo';
import { litOf, rig } from '../src/render/body';

it('every Ichigo move has a bespoke clip from u 0 to 3 over real bones', () => {
  const names = [...KITS.get('ichigo')!.entries()].flatMap(([form, kit]) =>   // each form's buttons and string links
    [...Object.values(kit.commands), ...kit.strings.map((row) => row[2])].filter((n): n is string => !!n).map((n) => [n, form]))
    .concat(['ic-c-heavy', 'ic-c-heavy3', 'ic-c-light', 'ic-c-light3'].map((n) => [n, 'kessa']));
  expect(names.length).toBeGreaterThan(30);
  for (const [n, form] of names) {
    const c = clip(findMove(n), form);
    expect(c, n).not.toBeNull();
    expect(c![0].at, n).toBe(0);
    expect(c![c!.length - 1].at, n).toBe(3);
    for (let i = 1; i < c!.length; i++) expect(c![i].at, `${n} key ${i}`).toBeGreaterThanOrEqual(c![i - 1].at);
    for (const key of c!) for (const b of Object.keys(key.pose)) expect(b === 'pos' || (BONES as readonly string[]).includes(b), `${n} ${b}`).toBe(true);
  }
});

it('each form has its own stance, guard and run cycle', () => {
  const a = stance('base'), b = stance('kessa');
  expect(a.idle).not.toBe(b.idle);
  expect(a.run[0].at).toBe(0); expect(a.run[a.run.length - 1].at).toBe(2);
  expect(stance('kessa').run).toBe(b.run);           // cached: the clip cache keys on it
});

it('KESSA: bare feet, no knife; the base: the knife on weaponL', () => {
  const r = rig(ichigo.spec), base = ichigo.parts(ichigo.spec, r), kes = ichigo.variant('kessa')!.parts!(ichigo.spec, r);
  expect(base.some((p) => p.bones.includes('weaponL'))).toBe(true);
  expect(kes.some((p) => p.bones.includes('weaponL'))).toBe(false);
  const bare = (ps: typeof base) => ps.some((p) => p.bones.includes('footR') && p.color.equals(litOf(ichigo.spec.skin)));
  expect(bare(base)).toBe(false); expect(bare(kes)).toBe(true);
});
