// split.test.ts: the per-character clip tables (render/clips/<char>.ts) + the generic fallback give every kit move the
// clip the pre-split single mapping gave it; the body registry (render/bodies) resolves form variants.
import { expect, it } from 'vitest';
import '../src/chars';
import { KITS, ROSTER, type Move } from '../src/sim/kit';
import { BODIES, bodyFor } from '../src/render/bodies';
import { clipFor } from '../src/render/anim';

function before(mv: Move): string {
  const c = (mv.clip2 && mv.kind !== 'sp' ? mv.clip2 : mv.clip) ?? '', ken = c.startsWith('ke');
  if (mv.hits.length > 1) return 'multi0';
  if (c.includes('kick')) return 'kick';
  if (c.endsWith('q2')) return 'backhand';
  if (c.includes('sleeve')) return 'sleeve';
  if (c.endsWith('q3')) return ken ? 'spin' : 'heavy';
  if (c.endsWith('f2')) return 'rise';
  if (c.endsWith('f1')) return ken ? 'heavy' : 'slash';
  if (c.includes('buttagiru')) return 'leap';
  if (c.includes('taimatsu') || c.includes('shiranui') || c.includes('ikkotsu')) return 'palm';
  if (c.includes('shoulder')) return 'shoulder';
  if (c.includes('charge') || c.includes('enjo')) return 'thrust';
  return mv.kind === 'flash' ? 'heavy' : 'slash';
}

it('every kit move without a bespoke clip maps to the same library clip as before the split', () => {
  let n = 0;
  for (const [who, forms] of KITS) for (const kit of forms.values()) for (const mv of kit.moves.values()) {
    const c = clipFor(who, mv);
    if (Array.isArray(c)) { expect(c.length, `${who} ${mv.name}`).toBeGreaterThan(1); continue; }   // bespoke (B2+)
    expect(`${who} ${mv.name} ${c}`).toBe(`${who} ${mv.name} ${before(mv)}`); n++;
  }
  expect(n).toBeGreaterThan(50);
});

it('bodyFor: every roster character has its own body; a form variant folds in under its own cache key', () => {
  for (const who of ROSTER) expect(BODIES[who], who).toBeDefined();
  expect(bodyFor('kenpachi', 'bankai')).toEqual({ key: 'kenpachi:base', body: BODIES.kenpachi });
  const ken = BODIES.kenpachi, v0 = ken.variant;
  ken.variant = (f) => (f === 'bankai' ? { spec: { skin: 0x9e3a32 } } : null);
  try {
    const { key, body } = bodyFor('kenpachi', 'bankai');
    expect(key).toBe('kenpachi:bankai');
    expect(body.spec.skin).toBe(0x9e3a32);
    expect(body.spec.height).toBe(ken.spec.height);
    expect(body.parts).toBe(ken.parts);
  } finally { ken.variant = v0; }
});
