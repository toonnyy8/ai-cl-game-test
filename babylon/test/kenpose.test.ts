// kenpose.test.ts: posing by the sword (render/clips/util-ken.ts) puts the fist and the blade where the key asks, and
import type { Fighter } from '../src/sim/types';
// the left fist on the handle for two-handed keys.
import { expect, it } from 'vitest';
import { Vector3 } from '@babylonjs/core';
import { ken } from '../src/render/bodies/ken';
import { grip, gripFrame, weaponAt } from '../src/render/clips/util-ken';
import { P } from '../src/render/pose';

const gf = gripFrame(20);
it('grip: the right fist and the blade land on the key, the left fist on the handle', () => {
  const cases: [number, number, number, number, number, number][] = [
    [0.1, 1.2, -0.45, 0, 0.3, -1], [0.1, 1.9, -0.2, 0, 0.5, 1], [0.4, 1.0, 0.1, 0.3, -1, 0.2], [0.05, 1.25, -0.45, -0.3, 0.6, -1]];
  for (const [x, y, z, dx, dy, dz] of cases) {
    const p = grip(ken.spec, gf, P.idleKen, { at: [x, y, z], dir: [dx, dy, dz], two: 0.22 });
    const r = weaponAt(ken.spec, gf, p), l = weaponAt(ken.spec, gf, p, 'L'), d = new Vector3(dx, dy, dz).normalize();
    expect(Vector3.Distance(r.fist, new Vector3(x, y, z))).toBeLessThan(0.01);
    expect(Vector3.Dot(r.dir, d)).toBeGreaterThan(0.999);
    expect(Vector3.Distance(l.fist, new Vector3(x, y, z).subtract(d.scale(0.22)))).toBeLessThan(0.01);
  }
});

it('every move of every Kenpachi form has a bespoke clip, keyed in ascending phase, from and back to the stance', async () => {
  await import('../src/chars');
  const { KITS } = await import('../src/sim/kit');
  const clips = await import('../src/render/clips/ken');
  let n = 0;
  for (const [form, kit] of KITS.get('kenpachi')!) for (const mv of kit.moves.values()) {
    const c = clips.move(mv, { phase: 'main', form } as Fighter);
    expect(c, `${form} ${mv.name}`).not.toBeNull();
    for (let i = 1; i < c!.length; i++) expect(c![i].at, `${form} ${mv.name}`).toBeGreaterThan(c![i - 1].at);
    expect(c![0].pose).toBe(clips.stance(form).idle);
    expect(c![c!.length - 1].at).toBe(3);
    n++;
  }
  expect(n).toBeGreaterThan(60);
  for (const f of ['base', 'nozarashi', 'ryote', 'nomihose', 'bankai', 'kataude']) {
    const st = clips.stance(f);
    expect(st.walk!.at(-1)!.at).toBe(4); expect(st.run!.at(-1)!.at).toBe(2);
  }
});
