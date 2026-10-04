// vfx.test.ts: every hazard look and aura the kits name has an ink look; the cards' kanji are in the baked glyph subset.
import { describe, expect, it } from 'vitest';
import { lookOf } from '../src/render/vfx/hazards';
import { PRESETS } from '../src/render/vfx/aura';
import { CAPS } from '../src/render/vfx/card';
import { hasGlyphs } from '../src/render/vfx/brush';
import type { Hazard } from '../src/sim/types';

const src = Object.values(import.meta.glob<string>('../src/chars/*.ts', { query: '?raw', import: 'default', eager: true })).join('\n');
const fake = (kind: string, look: string | null, data: unknown = null, hook: string | null = null) =>
  ({ kind, look, data, hook, size: 1, yaw: 0 }) as unknown as Hazard;

describe('ink VFX coverage', () => {
  it('every -look name and hazard kind maps to an archetype', () => {
    const looks = [...new Set(src.match(/'[a-z]+-[a-z-]*-look'/g)!.map((s) => s.slice(1, -1)))];
    expect(looks.length).toBeGreaterThan(25);
    for (const l of looks) expect(lookOf(fake('fx', l)), l).not.toBeNull();
    for (const k of ['wave', 'fireball', 'pillars', 'bind', 'freeze', 'hand', 'rift']) expect(lookOf(fake(k, null)), k).not.toBeNull();
    for (const l of ['kyokko', 'kyoku', 'enjo', 'south', 'crack', 'meteor']) expect(lookOf(fake('line', l)), l).not.toBeNull();
    for (const k of ['maiden', 'gulp', 'spike']) expect(lookOf(fake('freeze', null, { kind: k }, 'senju-hz'))![1], k).not.toBe(0x9fd4ff);
    expect(lookOf(fake('sj-hit', null, { kind: 'thrust' }, 'senju-hz'))).toBeNull();      // a hit with no look of its own
  });
  it('every kit aura has a preset', () => {
    for (const m of src.matchAll(/aura: '([a-z-]+)'/g)) expect(PRESETS[m[1]], m[1]).toBeDefined();
  });
  it('the awakening titles 卍解 / 野晒 and the readings are drawable', () => {
    expect(hasGlyphs('卍解') && hasGlyphs('野晒') && hasGlyphs('KIKON') && hasGlyphs('SOUL BREAK')).toBe(true);
    for (const [n, c] of Object.entries(CAPS)) expect(hasGlyphs(c.reading.replace(/[^A-Z .,!'-:]/g, '')), n).toBe(true);
    expect(hasGlyphs(CAPS['ken-nozarashi-cine'].kanji)).toBe(true);
  });
});
