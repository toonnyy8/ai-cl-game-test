// ai.test.ts: the CPU (ai.ts) replays a seed exactly and plays it out to a K.O.
import { describe, expect, it } from 'vitest';
import '../src/chars';
import { runSeed } from '../tools/headless';

describe('CPU AI', () => {
  it('YK seed 1 with the real AI: the same twice, ends by K.O.', () => {
    const a = runSeed('yama', 'ken', 1, 'ai'), b = runSeed('yama', 'ken', 1, 'ai');
    expect(b).toEqual(a);
    const m = /RESULTS winner (P1|P2) konpaku (\d+)-(\d+)/.exec(a[a.length - 1]);
    expect(m).not.toBeNull();
    expect(m![2] === '0' || m![3] === '0').toBe(true);
    expect(a).not.toEqual(runSeed('yama', 'ken', 1, 'stub'));
  }, 60_000);
});
