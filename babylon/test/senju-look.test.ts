// senju-look.test.ts: Senjumaru's bespoke clips (render/clips/senju.ts): every move of hers in every form plays one of
// them, keyed in phase coordinates 0..3 in order.
import { expect, it } from 'vitest';
import '../src/chars';
import { KITS } from '../src/sim/kit';
import { clipOf } from '../src/render/clips/senju';

it('every Senjumaru move maps to a bespoke clip keyed 0..3', () => {
  let n = 0;
  for (const kit of KITS.get('senjumaru')!.values()) for (const mv of kit.moves.values()) {
    const c = (mv.clip2 && mv.kind !== 'sp' ? mv.clip2 : mv.clip) ?? '';
    if (!c.startsWith('sj-')) continue;
    const clip = clipOf(mv);
    expect(Array.isArray(clip), `${kit.form} ${mv.name} ${c}`).toBe(true);
    if (!Array.isArray(clip)) continue;
    expect(clip[0].at).toBe(0); expect(clip[clip.length - 1].at).toBe(3);
    for (let i = 1; i < clip.length; i++) expect(clip[i].at, `${mv.name} key ${i}`).toBeGreaterThan(clip[i - 1].at);
    n++;
  }
  expect(n).toBeGreaterThan(20);
});
