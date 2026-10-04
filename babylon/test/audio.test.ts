// audio.test.ts: the sound bank covers what the sim and the Lisp ask for (every DEFSOUND, every event kind
// feedback.lisp sounds, every emitted :sfx key, kit / move sfx, every cinematic's beats), and every sound renders clean.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { Match, CINES } from '../src/sim/match';
import type { SimEvent } from '../src/sim/types';
import { SOUNDS, BANK_ORDER, renderSound } from '../src/audio/sounds';
import { SOUNDING, feedback } from '../src/audio/feedback';
import { CUES } from '../src/audio/cues';

const raw = (g: Record<string, string>) => Object.values(g).join('\n');
const LISP = import.meta.glob<string>('../../duel/lisp/*.lisp', { query: '?raw', import: 'default', eager: true });
const SIM = raw(import.meta.glob<string>(['../src/sim/*.ts', '../src/chars/*.ts'], { query: '?raw', import: 'default', eager: true }));
const lisp = (f: string) => LISP[`../../duel/lisp/${f}`];

describe('the sound bank', () => {
  it('has every DEFSOUND of the Lisp build', () => {
    const keys = Object.values(LISP).flatMap((t) => [...t.matchAll(/^\(defsound :([a-z0-9-]+)/gm)].map((m) => m[1]));
    expect(keys.length).toBeGreaterThan(60);
    for (const k of keys) expect(SOUNDS[k], k).toBeDefined();
    expect(new Set(BANK_ORDER)).toEqual(new Set(Object.keys(SOUNDS)));
  });

  it('has every key the sim and the kits name (emit :sfx, :sfx params, swing / absorb sfx)', () => {
    const text = SIM;
    const keys = [...text.matchAll(/emit\('sfx', ([^)]*?), \w+\)/g)].flatMap((m) => [...m[1].matchAll(/'([a-z-]+)'/g)].map((q) => q[1]))
      .concat([...text.matchAll(/(?:sfx|swingSfx|absorbSfx): '([a-z-]+)'/g)].map((m) => m[1]));
    expect(keys.length).toBeGreaterThan(60);
    for (const k of keys) expect(SOUNDS[k], k).toBeDefined();
  });

  it('gives every event kind feedback.lisp sounds a sound, all from the bank', () => {
    // the Lisp's FEEDBACK-SYSTEM branches that play something (sfx-on / sfx-at / play-sfx / start-loop / pips-shatter)
    const fb = lisp('feedback.lisp').split('(defun feedback-system')[1];
    const lispKinds = fb.split(/\n {8}\(/).slice(1).flatMap((b: string) => {
      const head = b.match(/^\(?((?::[a-z-]+ ?)+)/)?.[1] ?? '';
      return /sfx|start-loop|pips-shatter/.test(b) ? head.trim().split(' ').map((k: string) => k.slice(1)) : [];
    });
    expect(lispKinds.length).toBeGreaterThan(35);
    for (const k of lispKinds) if (k !== 'drink' && k !== 'breaker-end') expect(SOUNDING, k).toContain(k);   // (:drink is never emitted)

    const m = new Match({ p1: 'yamamoto', p2: 'kenpachi', seed: 1 }).start();
    const played: string[] = [];
    const sink = { play: (k: string) => { played.push(k); }, hum: () => { played.push('breaker-hum'); } };
    const args: Record<string, unknown[]> = {
      hit: [0, 1, 0, 1, 0, 8, false, 60, 'quick'], blocked: [0, 1, 0, 1, 0], armored: [1, 0, 1, 0], absorbed: [1, 0, 1, 0],
      parried: [0, 1, 0, 1, 0], 'guard-crush': [0, 1, 0, 1, 0], 'guard-break': [0, 1, 0, 1, 0], 'stance-break': [0, 1, 0, 1, 0],
      clash: [0, 1, 0], 'hazard-cut': [0, 1, 0], 'skeleton-rise': [0, 0], 'rift-cut': [1, 0, 0, 0, 0, 0], sfx: ['getsuga', 0],
      swing: [0, 'flash'], rung: [1, true], burst: [0, 1, 'white'], konpaku: [1, 1], 'arm-spend': [1, 2], 'arm-crack': [1, 1],
    };
    m.w.p2.f.move = { params: { sfx: 'laugh' } } as never;                           // a rush module with a sound
    for (const kind of SOUNDING) {
      const n = played.length;
      const ev: SimEvent = { kind, tick: 0, args: args[kind] ?? (kind === 'rush-dash' ? [1] : [0, 1]) };
      for (let i = 0; i < 3; i++) feedback(ev, m.w, sink);                          // (absorbed's coin: 3 tries)
      expect(played.length, kind).toBeGreaterThan(n);
    }
    for (const k of played) expect(SOUNDS[k], k).toBeDefined();
  });

  it('has the sound beats of every cinematic, all from the bank', () => {
    expect(new Set(Object.keys(CUES))).toEqual(new Set(Object.keys(CINES)));
    for (const [name, cues] of Object.entries(CUES)) for (const [f, k, n] of cues) {
      expect(f, name).toBeLessThan(CINES[name].len);
      if (k) expect(SOUNDS[k], `${name} ${k}`).toBeDefined(); else expect(n, name).toBeGreaterThan(0);
    }
  });

  it('renders every sound clean: no NaN, the Lisp peak, audible, no DC, deterministic', () => {
    for (const k of BANK_ORDER) {
      const b = renderSound(k);
      let pk = 0, sq = 0, sum = 0, bad = 0;
      for (const x of b) { if (!Number.isFinite(x)) bad++; pk = Math.max(pk, Math.abs(x)); sq += x * x; sum += x; }
      expect(bad, k).toBe(0);
      expect(pk, k).toBeCloseTo(SOUNDS[k].peak, 4);
      expect(Math.sqrt(sq / b.length), k).toBeGreaterThan(0.005);
      expect(Math.abs(sum / b.length), k).toBeLessThan(0.01);
    }
    expect(renderSound('clash')).toEqual(renderSound('clash'));
  }, 30000);
});
