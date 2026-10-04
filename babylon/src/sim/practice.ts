// practice.ts <- the PRACTICE part of duel/lisp/flow.lisp (practice-set!, practice-dummy!, practice-step, practice-reset,
// the pause options) + control.lisp's DUMMY-GUARD-LEFT, PRACTICE-REISHI, KONPAKU-STEP. P1 against a dummy: no timer, no
// match end (a K.O. is a reset to both sides' rows). The Lisp switches P2's brain off for the STAND / GUARD dummies; here
// such a dummy has no brain and a device reader that holds its guard (the same vpad writes, one step later than the
// Lisp's match-system write: its guard is read at the next step's start either way).
import { T } from './tuning';
import { W, Brain, type Ent, type FState } from './types';
import { resetRound } from './combat';
import { abortCine, beginBattle, spawnPair, type PracticeHooks } from './match';
import type { Vpad } from './vpad';

export type Dummy = 'stand' | 'guard-all' | 'guard-hit' | 'cpu';
export const DUMMIES: [Dummy, string][] = [['stand', 'STAND'], ['guard-all', 'GUARD ALL'], ['guard-hit', 'GUARD AFTER HIT'], ['cpu', 'CPU']];
export const PRACTICE_HP = [100, 75, 50, 25, 10];
const DUMMY_GUARD_HOLD = 60;
const HIT_STATES: FState[] = ['stun', 'air', 'down', 'wakeup', 'guard-hit'];

/** Frames the dummy goes on holding guard, for its option, its fighter STATE and LEFT (frames still held). */
export function dummyGuardLeft(dummy: Dummy, state: FState, left: number): number {
  if (dummy === 'guard-all') return 999;
  if (dummy === 'guard-hit') return HIT_STATES.includes(state) ? DUMMY_GUARD_HOLD : Math.max(0, left - 1);
  return 0;
}
/** Reishi for PCT % of REISHI-MAX (never 0: 0 would be a Soul Break). */
export const practiceReishi = (reishiMax: number, pct: number): number => Math.max(1, Math.ceil((reishiMax * pct) / 100));
/** The P1 / DUMMY KONPAKU row moved by DIR: 1 .. KMAX, wrapping. */
export const konpakuStep = (k: number, dir: number, kmax: number): number => 1 + ((((k - 1 + dir) % kmax) + kmax) % kmax);

/** PRACTICE's options (the pause menu's rows). ROWS: P1 HP %, P1 KONPAKU, DUMMY HP %, DUMMY KONPAKU. */
export const P = { dummy: 'stand' as Dummy, hpRefill: true, gaugesInf: false, rows: [100, T.konpakuMax, 100, T.konpakuMax],
                   difficulty: 'normal' };

const practiceHp = (e: Ent) => practiceReishi(e.g.reishiMax, P.rows[2 * e.f.side]);
/** E's Reishi and Konpaku to its practice rows. */
export function practiceSet(e: Ent): void { e.g.reishi = practiceHp(e); e.g.konpaku = P.rows[1 + 2 * e.f.side]; }

let guardLeft = 0, guardTick = -1;
/** The STAND / GUARD dummy's device: guard held per dummyGuardLeft (counted once per vpad step, not in hitstop reads). */
function dummyReader(vp: Vpad): void {
  if (vp.tick !== guardTick) { guardTick = vp.tick; guardLeft = dummyGuardLeft(P.dummy, W.p2.f.state, guardLeft); }
  vp.set('guard', guardLeft > 0);
  vp.stick(0, 0);
}
/** P2 for the DUMMY option: the CPU (a brain at P.difficulty), or a dummy holding nothing but its guard. */
export function practiceDummy(): void {
  const e = W.p2;
  guardLeft = 0;
  if (P.dummy === 'cpu') {
    if (!e.brain) e.brain = new Brain(P.difficulty, (T.aiDelay as Record<string, number>)[P.difficulty] ?? 14);
    e.pilot.vpad.reader = null;
  } else { e.brain = null; e.pilot.vpad.reader = dummyReader; }
  e.pilot.vpad.clear();
}

/** Each sim frame of PRACTICE (match-system): the dummy's Konpaku always full, HP REFILL AUTO its Reishi once out of its
 *  hit / block reactions; GAUGES INFINITE: P1's gauges full. */
function practiceStep(): void {
  const e = W.p2, g = e.g;
  g.konpaku = P.rows[3];
  if (P.hpRefill && !HIT_STATES.includes(e.f.state)) g.reishi = practiceHp(e);
  if (P.gaugesInf) {
    const g1 = W.p1.g;
    g1.reishi = practiceHp(W.p1); g1.gg = T.ggMax; g1.guardless = false; g1.reiatsu = T.reiatsuMax;
    if (!g1.burst) g1.fs = T.fsMax;                                   // a burst burns it down first (the user 2026-09-30)
    if (!g1.awakened) g1.awaken = T.awakenMax;
  }
}

export const practiceHooks: PracticeHooks = {
  start(): void { practiceDummy(); practiceSet(W.p1); practiceSet(W.p2); },
  step: practiceStep,
  ko(): void { practiceSet(W.p1); practiceSet(W.p2); resetRound(W.p1, W.p2); },
};

/** RESET POSITION: a fresh pair at the start (full resources, first forms), straight into the fight (no intro). */
export function practiceReset(p1: string, p2: string, readers: [((vp: Vpad) => void) | null, null]): void {
  W.pending = []; W.soulBreaks = [];
  abortCine();
  spawnPair(p1, p2, { cpu2: true, difficulty: P.difficulty, readers });
  practiceHooks.start();
  beginBattle();
}
