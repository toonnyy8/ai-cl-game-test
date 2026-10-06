// habits.ts <- duel/lisp/debug.lisp's scripted players (Brain.habit): the learning gate's "humans" and ASSIST's
// button-masher. A CPU with a habit still plays as the CPU, except where its habit fires first:
//   wake-j       J on every wake-up                  block-guard  guard 40 f after every block
//   grab         the Breaker at every close neutral decision
//   hoho         Hoho at neutral decisions and into every committed move it sees coming
//   burst        BLUE at every chance (ai.ts aiBurstRoll's chance 1)
//   dumb         the button-masher (dumbStep): nothing of the CPU's play; with ASSIST on P1 (assist.ts assistDebug)
import { T } from './tuning';
import { kitCommandMove, type Kit } from './kit';
import { W, kitOf, simRnd01, type Brain, type Ent, type Snap } from './types';
import { kitCommandOkP } from './fighter';
import { aiCommand, aiPress } from './ai';

/** The scripted players by the learning gate's index h (debug 200000 + 1000 h + ...). */
export const HABITS: readonly (string | null)[] = [null, 'wake-j', 'block-guard', 'grab', 'hoho', 'burst', 'dumb'];
/** The button-masher sees as late as an EASY CPU (frames) ... */
export const DUMB_DELAY = 24;
/** ... and guards this share of the moves he sees coming. */
const DUMB_GUARD_P = 0.5;
const COMMITTED = ['quick', 'flash', 'sig', 'sp', 'breaker'];

/** A scripted player's habit before its reflexes (brainStep): true when it pressed. */
export function habitFire(e: Ent, b: Brain, s: Snap, d: number): boolean {
  const f = e.f, g = e.g, was = b.was, hohoOk = f.hohoLock === 0 && g.fs >= T.fsHoho;
  if (!((f.state === 'idle' || f.state === 'guard' || f.state === 'run') && f.lock === 0)) return false;
  if (b.habit === 'wake-j' && was === 'wakeup') { aiPress(b, 'quick', 1); b.why = 'habit'; return true; }
  if (b.habit === 'block-guard' && was === 'guard-hit') { aiPress(b, 'guard', 40, false, 'hold'); b.why = 'habit'; return true; }
  if (b.habit === 'hoho' && hohoOk && s.state === 'move' && COMMITTED.includes(s.kind!) && s.sf < s.activeEnd
      && d < s.reach + T.aiThreatMargin) {
    aiPress(b, 'step', 1, true, 'hoho'); b.why = 'habit'; return true;
  }
  return false;
}

/** The button-masher (ASSIST's gate, docs/duel/DUEL_ASSIST.md): hold U while a move of his comes (seen late, DUMB_DELAY, and
 *  only DUMB_GUARD_P of his moves), mash J (a press every 8 f) within J1's reach, else walk at him. Never a Step, Hoho, L,
 *  SP, Breaker, O, Burst or awakening of its own: those come from the assist. */
export function dumbStep(e: Ent, b: Brain, s: Snap, d: number): true {
  const vp = e.pilot.vpad, reach = kitCommandMove(kitOf(e), 'q')!.reach;
  b.pressLeft = 0;                                                     // every step decides afresh
  if (s.start !== b.rollKey) { b.rollKey = s.start; b.guardRoll = simRnd01(); }   // one guard roll per move of his
  if (s.state === 'move' && b.guardRoll < DUMB_GUARD_P && [...COMMITTED, 'kikon'].includes(s.kind!) && s.sf < s.activeEnd
      && d < s.reach + T.aiThreatMargin) aiPress(b, 'guard', 1, false, 'guard');
  else if (d < reach + 0.3) { if (W.tick % 8 === 0) aiPress(b, 'quick', 1); }
  else vp.stick(0, 1);
  b.why = 'dumb';
  return true;
}

/** A scripted player's habit at a neutral decision (aiDecide): true when it pressed. */
export function habitNeutral(e: Ent, b: Brain, kit: Kit, d: number): boolean {
  const f = e.f, g = e.g;
  if (b.habit === 'grab' && d < 2.6 && kitCommandOkP(e, 'breaker')) { aiCommand(b, kit, 'breaker', d, e); b.why = 'habit'; return true; }
  if (b.habit === 'hoho' && d < 7.0 && f.hohoLock === 0 && g.fs >= T.fsHoho && simRnd01() < 0.5) {
    aiCommand(b, kit, 'hoho', d, e); b.why = 'habit'; return true;
  }
  return false;
}
