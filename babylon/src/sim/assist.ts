// assist.ts <- duel/lisp/assist.lisp: ASSIST (the user, 2026-10-01; docs/duel/DUEL_ASSIST.md), the SETTINGS rows AUTO GUARD /
// AUTO COMBO / AUTO BREAK. A layer on a human's vpad, after the devices and the CPUs (brainSystem), before fighterSystem
// reads it: the player gives the intent (U held, J pressed), the CPU's own rules pick the move and press its buttons
// (aiCommand on a borrowed brain). A move it pressed is assisted (Fighter.assistNext, taken by startMove / startHoho):
// x T.assistMult damage, and its Hoho is never PERFECT. The AUTO tag (assistTag) shows at his feet.
//   AUTO GUARD   0 OFF / 1 HOLD U / 2 ALWAYS: free (and U held, for HOLD U): the form's own defensive answers (its kit's
//                assistGuard hook), then a hit about to land (perfectNowP): the form's parry against a melee move, else a
//                Hoho; and J on the first free step out of blocking his J / K link that still recovers (jBeatsOpenP)
//   AUTO COMBO   J pressed during a J / K link that hit: the CPU's choice on the hit's land frame (stringReflex; the O
//                ender off a link-3 hit on a red opponent: the Kikon); J pressed while free: the kit's oki / stun follow-up
//                (autoSp), else the learner's counter to his predicted next move (autoRead)
//   AUTO BREAK   J pressed, free, while he has guarded >= T.aiGuardBreakHold within T.aiGuardBreakRange: the Breaker
//   LEARNING     while any of the three is on, the assist learns HIS habits (learn.ts's model at HARD's delay), one table
//                per opponent character (assistLearnTables, saved apart)
// A CPU never has it, except the gates' button-masher (habit 'dumb' on P1, ASSIST_DEBUG.cfg): CPU-vs-CPU gates unchanged.
import { T } from './tuning';
import { KIT_COMMANDS, ROSTER, callHook, kitCommandMove, type Kit, type Move } from './kit';
import { hohoAllowedP } from './rules';
import { Brain, W, clog, fighters, kitOf, oppOf, sideName, type Ent, type FState, type Snap } from './types';
import type { Action, Vpad } from './vpad';
import { kitCommandOkP } from './fighter';
import { kikonReadyP, perfectNowP } from './combat';
import {
  aiCommand, aiEventRolls, aiSbFinishP, aiTable, brainPerceive, guardingP, jBeatsOpenP, stringReflex, why, withAiBrain,
} from './ai';
import {
  ASSIST_LEARN_KEY, LP, assistLearnTables, learnBand, learnConfidentP, learnCounter, learnFormAfter, learnPredict, learnRollP,
  learnSave, learnStep, learnTable, newLrn,
} from './learn';

/** An assist setting: [AUTO GUARD 0 / 1 HOLD U / 2 ALWAYS, AUTO COMBO, AUTO BREAK]. */
export type AssistCfg = [number, boolean, boolean];
/** The SETTINGS rows every human fighter uses (VS PLAYER: both share them); the UI sets these (soulduel.autoguard ...). */
export const ASSIST = { autoGuard: 0 as 0 | 1 | 2, autoCombo: false, autoBreak: false };
/** ASSIST's gate knobs: the 'dumb' P1's assist (debug 81000+k), the assist's learner on (81030+i). */
export const ASSIST_DEBUG = { cfg: null as AssistCfg | null, learn: true };

// Per side: the brain the assist borrows; AUTO COMBO's plan [move, command]; the match tick of its last step (a smaller
// one: a new match, a fresh brain). assistTag: frames the AUTO tag still shows (the HUD's).
const brains: (Brain | null)[] = [null, null];
const plan: ([Move, string | null] | null)[] = [null, null];
const lastTick = [0, 0];
export const assistTag = [0, 0];
/** The brain SIDE's assist borrows (the gate's learn rows read its learner). */
export const assistBrainOf = (side: number): Brain | null => brains[side];

/** SIDE's assist brain: a fresh one each match (HARD's perception), with a learner over his character's table. */
function assistBrain(e: Ent, side: number): Brain {
  let b = brains[side];
  if (!b || W.tick < lastTick[side]) {
    const o = oppOf(e);
    b = brains[side] = new Brain('hard', T.aiDelay.hard);
    plan[side] = null;
    if (ASSIST_DEBUG.learn)
      b.learn = newLrn(learnTable(ROSTER.indexOf(o.f.character), assistLearnTables, ASSIST_LEARN_KEY), o, 7907);
  }
  lastTick[side] = W.tick;
  return b;
}

/** The match is over (WINNER its side, 'draw' or null): each assist learner's opponent's form takes the result, its table
 *  is saved. */
export function assistLearnEnd(winner: 0 | 1 | 'draw' | null): void {
  for (const e of [W.p1, W.p2]) {
    const side = e.f.side, l = brains[side]?.learn;
    if (l && e.alive && assistConfig(e)) {
      l.tab.form = learnFormAfter(l.tab.form, winner === side ? -1 : winner === 'draw' ? 0 : 1, LP.formMatch);
      learnSave(ROSTER.indexOf(oppOf(e).f.character), assistLearnTables, ASSIST_LEARN_KEY);
    }
  }
}

/** E's assist, or null: a human's SETTINGS, the 'dumb' P1 CPU's ASSIST_DEBUG.cfg, no other CPU. */
export function assistConfig(e: Ent): AssistCfg | null {
  const b = e.brain;
  if (!b) return [ASSIST.autoGuard, ASSIST.autoCombo, ASSIST.autoBreak];
  return b.habit === 'dumb' && e.f.side === 0 ? ASSIST_DEBUG.cfg : null;
}

/** The command of KIT's parry move (a parry flag) E may start now, or null. */
function parryCommand(e: Ent, kit: Kit): string | null {
  return KIT_COMMANDS.find((c) => { const mv = kitCommandMove(kit, c); return !!mv && mv.flags.includes('parry') && kitCommandOkP(e, c, kit); }) ?? null;
}

/** AUTO GUARD's first answer: the form's own defensive reflexes (its kit's assistGuard hook) on brain B as the CPU sees
 *  (S, D). A command or null ('wait': nothing yet, the generic answer may still go). */
function autoGuardKit(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const h = aiTable<string | null>(e, 'assistGuard');
  if (!h) return null;
  aiEventRolls(b, s);                                                  // (its rolls, one per action of his)
  const c = callHook(h, e, b, s, d);
  return c && c !== 'wait' ? c : null;
}

/** AUTO GUARD: a hit about to land (perfectNowP): the parry against his melee move, else a Hoho when allowed; or null. */
function autoGuard(e: Ent): string | null {
  if (!perfectNowP(e)) return null;
  const f = e.f, kit = f.kit, g = e.g, fo = oppOf(e).f;
  return (fo.state === 'move' && fo.phase === 'main' && parryCommand(e, kit))
    || (!kit.rooted && hohoAllowedP(false, g.fs, f.hohoLock, g.burst) ? 'hoho' : null);
}

/** AUTO COMBO: on a J / K link's land frame, the CPU's next step (the O ender off a link-3 hit on a red opponent, else
 *  stringReflex with the latch emptied); pressed once J was pressed in this move (latched or buffered). J stays his own. */
function autoCombo(e: Ent, b: Brain, side: number, vp: Vpad): string | null {
  const f = e.f, mv = f.move!, kit = f.kit;
  if (plan[side]?.[0] !== mv) plan[side] = null;
  if (f.contact === 'hit' && f.sf === f.landSf && (mv.kind === 'quick' || mv.kind === 'flash')) {
    let c: string | null;
    if (mv.flags.includes('ender') && kikonReadyP(e) && !aiSbFinishP(e) && kitCommandOkP(e, 'kikon', kit, true)) c = 'kikon';
    else {
      const q = f.queued;
      f.queued = null;
      c = stringReflex(e, b, f, mv);
      // ponytail: the Lisp's bait branch is (and (eq why :bait) (setf (lrn-cmd l) nil) :guard-long): the SETF returns NIL,
      // so it clears the plan and never yields :guard-long; ported as it behaves
      if (!c && b.why === 'bait') b.learn!.cmd = null;
      f.queued = q;
    }
    plan[side] = [mv, c];
  }
  const cmd = plan[side]?.[1];
  if (cmd && cmd !== 'q' && (f.queued || vp.pressed('quick') || cmd === 'guard-long')) {
    plan[side] = null;
    if (!(cmd === 'f' || cmd === 'sig')) f.queued = null;            // a cancel / burst / ender replaces the latched link
    return cmd;
  }
  return null;
}

/** AUTO COMBO's SP in neutral, by the CPU's own rules: the kit's oki on a launched / downed opponent, its stunFollow on a
 *  stunned one it still reaches. null: none. */
function autoSp(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const kit = kitOf(e), g = e.g, sf = aiTable<[string, number, number] | null>(e, 'stunFollow');
  if ((s.state === 'air' || s.state === 'down') && aiTable(e, 'oki') === 'sp1-full' && kitCommandMove(kit, 'sp1')?.hold
      && kitCommandOkP(e, 'sp1') && d > 3.0 && g.reishi / g.reishiMax >= aiTable(e, 'okiAbove', 0.0)) return 'sp1-full';
  if (sf && s.state === 'stun' && sf[1] <= d && d <= sf[2] && kitCommandOkP(e, sf[0])
      && s.left - b.delay >= kitCommandMove(kit, sf[0])!.s) return sf[0];
  return null;
}

/** AUTO COMBO's read: J pressed while free, the learner's counter to his predicted next move (an event's planned one,
 *  else his distance band's when confident and its roll says read him): K against his K / I, a Hoho against his SP;
 *  null for the rest (J stays his). */
function autoRead(e: Ent, b: Brain, d: number): string | null {
  const l = b.learn;
  if (!l) return null;
  let c: string | null = null;
  if (l.cmd && l.delay <= 0) { c = l.cmd; l.cmd = null; }
  else {
    const [act, p, n] = learnPredict(l.tab, learnBand(d));
    if (act != null && learnConfidentP(p, n) && learnRollP(l)) c = learnCounter(act);
  }
  const f = e.f, g = e.g, kit = f.kit;
  if (c === 'hoho') return !kit.rooted && hohoAllowedP(false, g.fs, f.hohoLock, g.burst) ? 'hoho' : null;
  if (c === 'q') {                                                     // J beats K / I: his J; a K reaching further, ours
    const mv = kitCommandMove(kit, 'f');
    return mv && kitCommandOkP(e, 'f') && kitCommandMove(kit, 'q')!.reach <= d && d <= mv.reach + 0.4 ? 'f' : null;
  }
  return null;
}

/** AUTO BREAK: J pressed while free and he holds a long guard close by: the Breaker, or null. */
function autoBreak(e: Ent, vp: Vpad): string | null {
  const o = oppOf(e);
  return vp.commandPressedP('quick', false) && guardingP(o) && !o.g.guardless && o.f.guardT >= T.aiGuardBreakHold
    && e.f.dist < T.aiGuardBreakRange && kitCommandOkP(e, 'breaker') ? 'breaker' : null;
}

const FREE: readonly FState[] = ['idle', 'guard', 'run'];
/** One step of E's assist CFG: its learner watches him; a press it holds goes on, else AUTO GUARD / COMBO / BREAK may
 *  press one. */
function assistStep(e: Ent, cfg: AssistCfg): void {
  const f = e.f, side = f.side, vp = e.pilot.vpad, b = assistBrain(e, side), st = f.state;
  const free = FREE.includes(st) && f.lock === 0;
  const [s, d] = brainPerceive(e, b, oppOf(e));                        // him as HARD's delay sees him
  withAiBrain(b, () => {                                               // (the kits' CPU code decides on this brain)
    if (b.learn) learnStep(e, b, s, d);
    if (assistTag[side] > 0) assistTag[side]--;
    if (b.pressLeft > 0) {                                             // a held press (the Breaker's dash, O through the
      b.pressLeft--;                                                   // strike, a charge: his J mashing doesn't restart)
      vp.hold(b.press as Action);
      if (b.press === 'guard') { vp.consume('quick'); f.queued = null; }
      return;
    }
    const cmd = (free && cfg[0] > 0 && (cfg[0] === 2 || vp.down('guard'))
                 && (autoGuardKit(e, b, s, d) || autoGuard(e) || (jBeatsOpenP(e, b) ? why(b, 'j-back', 'q') : null)))
      || (cfg[1] && st === 'move' && autoCombo(e, b, side, vp))
      || (cfg[2] && free && autoBreak(e, vp))
      || (cfg[1] && free && vp.commandPressedP('quick', false) && (autoSp(e, b, s, d) || autoRead(e, b, d)));
    if (cmd) {
      vp.consume('quick');                                             // the J it answered (a guard's press: none)
      aiCommand(b, f.kit, cmd, f.dist, e);
      vp.stamp(b.press as Action, b.pressMod);
      b.pressLeft--;
      f.assistNext = true; assistTag[side] = T.assistTagFrames;
      clog(() => `${sideName(e)} assist ${cmd}`);
    }
  });
  b.was = st;                                                          // (jBeatsOpenP: the step after blockstun)
}

/** Every assisted fighter's step (match.ts: between brainSystem and fighterSystem). */
export function assistSystem(): void {
  for (const e of fighters()) {
    const cfg = assistConfig(e), st = e.f.state;
    if (cfg && (cfg[0] > 0 || cfg[1] || cfg[2]) && !(st === 'cine' || st === 'intro' || st === 'win' || st === 'lose'))
      assistStep(e, cfg);
  }
}
