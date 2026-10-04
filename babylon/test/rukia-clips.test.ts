// rukia-clips.test.ts: every move in every Rukia form gets a bespoke clip (render/clips/rukia.ts), and the pirouettes
// turn in steps under 180 deg (a slerp across 180 could take either way round).
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { KITS } from '../src/sim/kit';
import type { Fighter } from '../src/sim/types';

const fighter = () => ({ phase: 'main', sf: 0, hold: 0 }) as unknown as Fighter;
import { idle, idleFor, move } from '../src/render/clips/rukia';

describe('Rukia clips', () => {
  for (const [form, kit] of KITS.get('rukia')!) {
    it(`${form}: every move has its own clip`, () => {
      const f = fighter();
      for (const [n, mv] of kit.moves) {
        f.phase = 'main'; f.sf = mv.s;
        const got = move(mv, f, idleFor(form) ?? idle);
        expect(got, n).not.toBeNull();
        expect(got![1], n).toBe(1);
      }
    });
  }
  it('pelvis yaw steps stay under 180 deg between keys', () => {
    for (const n of ['ru-j3', 'ru-k2', 'ru-tsukishiro', 'ru-kikon']) {
      const mv = KITS.get('rukia')!.get('base')!.moves.get(n)!;
      const f = fighter(); f.phase = 'main'; f.sf = 0;
      const [clip] = move(mv, f, idle)!;
      for (let i = 1; i < clip.length; i++) {
        const a = clip[i - 1].pose.pelvis?.[1] ?? 0, b = clip[i].pose.pelvis?.[1] ?? 0;
        const d = Math.abs((((b - a) % 360) + 540) % 360 - 180);
        expect(d, `${n} key ${i}`).toBeLessThan(170);
      }
    }
  });
});
