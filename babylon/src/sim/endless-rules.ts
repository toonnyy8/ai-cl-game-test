// endless-rules.ts <- duel/lisp/endless-rules.lisp: ENDLESS 無限連戰 as pure rules (docs/duel/DUEL_ENDLESS.md): the ramp, the
// opponent bag, the stage seed, P1's carry-over between stages and the record comparison. Plain data over kit.ts (findKit
// and the kit slots); the mode itself (the run, its screens, the record on the page) is endless.ts / src/ui/flow.ts.
// No character names in here: what a form carries over is kit data (endlessForm, resetForm, duration, meter).
import { T } from './tuning';
import { findKit, type Kit } from './kit';

/** Per row, from its first stage on: [stage, difficulty steps above the floor, opponent awakening gauge, opponent
 *  awakened, opponent Reishi %]. The last row is the plateau (DUEL_ENDLESS §3). */
export type RampRow = [number, number, number, boolean, number];
export const ENDLESS_RAMP: RampRow[] = [[1, 0, 0, false, 100], [3, 1, 0, false, 100], [5, 2, 50, false, 100],
  [7, 2, 100, false, 100], [9, 2, 100, true, 110], [12, 2, 100, true, 120]];
export const DIFFICULTIES = ['easy', 'normal', 'hard'];

/** The ramp row in force at STAGE (1-based). */
export function endlessRamp(stage: number): RampRow {
  let row = ENDLESS_RAMP[0];
  for (const r of ENDLESS_RAMP) if (stage >= r[0]) row = r;
  return row;
}

/** The CPU difficulty at STAGE for a run started at FLOOR: the ramp's steps above it, clamped at the last of LEVELS. */
export function endlessDifficulty(floor: string, stage: number, levels = DIFFICULTIES): string {
  return levels[Math.min(levels.length - 1, Math.max(0, levels.indexOf(floor)) + endlessRamp(stage)[1])];
}

/** One step of the bag's own LCG (not the sim stream: the order never depends on the fights). (x * 1103515245 + 12345)
 *  mod 2^31 only needs the product's low 32 bits: Math.imul. */
export const endlessLcg = (x: number): number => (Math.imul(x, 1103515245) + 12345) & 0x7fffffff;

/** Bag B (0-based) of run SEED: a shuffle of ROSTER (Fisher-Yates on the LCG keyed on SEED and B). */
export function endlessBag<C>(seed: number, b: number, roster: readonly C[]): C[] {
  const v = [...roster];
  let x = endlessLcg(seed * 7919 + b * 104729 + 1);
  for (let i = v.length - 1; i >= 1; i--) {
    x = endlessLcg(x);
    const j = Math.floor(x / 65536) % (i + 1);
    [v[i], v[j]] = [v[j], v[i]];
  }
  return v;
}

/** The opponent of STAGE (1-based) in run SEED: bags of |ROSTER|, each the whole roster once; a bag whose first entry
 *  equals the previous bag's last swaps its first two (never the same opponent twice in a row). */
export function endlessOpponent<C>(seed: number, stage: number, roster: readonly C[]): C {
  const n = roster.length, b = Math.floor((stage - 1) / n);
  let prev: C | undefined, bag: C[] = [];
  for (let k = 0; k <= b; k++) {
    bag = endlessBag(seed, k, roster);
    if (prev !== undefined && bag.length > 1 && bag[0] === prev) [bag[0], bag[1]] = [bag[1], bag[0]];
    prev = bag[bag.length - 1];
  }
  return bag[(stage - 1) % n];
}

/** The sim seed of STAGE in run RUN (a pure mix: stage n replays alone). */
export const endlessStageSeed = (run: number, stage: number): number => (run * 104729 + stage * 7919 + 17) % 1000000;

/** The form KIT's fighter starts the next stage in when he stays awakened / is not awakened: its endlessForm, else its
 *  resetForm, else a timed form ends the way its timer would (its inherit), else the same form. */
export const endlessStayForm = (kit: Kit): string =>
  kit.endlessForm || kit.resetForm || (kit.duration ? kit.inherit : null) || kit.form;

/** P1 at a clear (the carry's input). */
export interface EndlessSnap {
  character: string; form: string; konpaku: number; reiatsu: number; fs: number; awaken: number; awakened: boolean; meter: number;
}
/** What the next stage applies over a fresh fighter (Reishi full and the guard gauge full come from the fresh spawn). */
export interface EndlessCarry { form: string; konpaku: number; reiatsu: number; fs: number; awaken: number; awakened: boolean; meter: number }

/** P1's carry into the next stage; CHOICE 'stay' (CONTINUE) or 'revert'. The rules (DUEL_ENDLESS §4, the user's decisions
 *  2026-09-29): Konpaku + 2 (at most T.konpakuMax); Reiatsu and flash step kept; REVERT: the base form, the awakening unused
 *  and full, the kit meter 0; otherwise the stay form (endlessStayForm) with the awakening as it was and the kit meter
 *  kept, except when the form has an endlessForm / resetForm or the carry changed the form (the new form's start, else 0)
 *  or the meter is a count meter (0). */
export function endlessCarry(snap: EndlessSnap, choice: 'stay' | 'revert'): EndlessCarry {
  const { character, form, konpaku, reiatsu, fs, awaken, awakened, meter } = snap;
  const kit = findKit(character, form);
  const common = { konpaku: Math.min(T.konpakuMax, konpaku + 2), reiatsu, fs };
  if (choice === 'revert' && awakened) return { form: 'base', awaken: T.awakenMax, awakened: false, meter: 0, ...common };
  const to = endlessStayForm(kit), m = findKit(character, to).meter as { start?: number; count?: boolean } | null;
  return {
    form: to, awaken: awakened ? 0 : awaken, awakened,
    meter: kit.endlessForm || kit.resetForm || to !== form ? (m?.start ?? 0) : m?.count ? 0 : meter,
    ...common,
  };
}

/** Does a run of STAGES cleared in SECS beat the stored best (0 0 = no record)? More stages, else less time; 0 stages is
 *  never a record. */
export const endlessBetterP = (stages: number, secs: number, bestStages: number, bestSecs: number): boolean =>
  stages > 0 && (stages > bestStages || (stages === bestStages && secs < bestSecs));
