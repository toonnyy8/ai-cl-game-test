// stubai.ts: the M1 stand-in CPU (the real one is ai.lisp, M2). It writes the same vpad a keyboard does, once per step,
// the way ai.lisp's BRAIN-STEP does (begin the step, decide, set every button, the stick as (strafe, toward)); every roll
// is from the sim stream, so a seed replays. Behaviour: walk in, J strings up close, K at mid range, the form's ranged
// specials far out, a Breaker into a long guard, guards and Steps now and then, the Kikon rush (held) on a red opponent.
// ponytail: no perception delay, no kit :ai tables; M2 replaces this file's brain step with ai.ts's.
import { T } from './tuning';
import { redP } from './rules';
import { kitCommandMove } from './kit';
import { VPAD_ACTIONS, type Action } from './vpad';
import { simRnd01, type Brain, type Ent } from './types';
import { kitCommandOkP } from './fighter';

/** Hold BUTTON (with mod when MODDED) for FRAMES steps, starting now; the stick (strafe, toward) while it is held. */
function press(b: Brain, button: Action, frames: number, modded = false, sx = 0, sy = 0): void {
  b.press = button; b.pressMod = modded; b.pressLeft = Math.max(1, frames); b.sx = sx; b.sy = sy;
}

export function stubBrainStep(e: Ent, b: Brain): void {
  const f = e.f, vp = e.pilot.vpad, o = f.opp!, d = f.dist > 0 ? f.dist : Math.hypot(o.pos[0] - e.pos[0], o.pos[2] - e.pos[2]);
  vp.beginStep();
  b.heat += (d > T.aiHeatFar ? 2 : 1) * (T.aiHeatRate / 60);
  let sx = 0, sy = 0;
  if (f.lock > 0 || f.state === 'cine') b.pressLeft = 0;
  else if (b.pressLeft > 0) { b.pressLeft--; sx = b.sx; sy = b.sy; }
  else if (f.state === 'guard-hit' && f.sf === 0 && simRnd01() < 0.6) press(b, 'guard', f.stun + 12);
  else if ((f.state === 'stun' || f.state === 'air') && f.comboHits >= T.burstMinHits && e.g.fs >= T.fsBurst && simRnd01() < 0.02)
    press(b, 'quick', 1, true);                                        // a Burst, now and then
  else if (f.state === 'move' && f.move && (f.move.kind === 'quick' || f.move.kind === 'flash') && f.contact && !f.queued) {
    const r = simRnd01();                                              // a string: latch the next link
    if (r < 0.5) press(b, 'quick', 1); else if (r < 0.75) press(b, 'flash', 1);
  } else if (f.state === 'idle' || f.state === 'guard' || f.state === 'run') {
    if (--b.decideT <= 0) {
      b.decideT = 8 + Math.floor(simRnd01() * 24);
      decide(e, b, d);
      if (b.pressLeft > 0) { sx = b.sx; sy = b.sy; }
    } else if (d > 1.4) sy = 1;                                        // walk in between decisions
    else sx = b.strafe;
    if (--b.strafeT <= 0) { b.strafeT = 40 + Math.floor(simRnd01() * 40); b.strafe = simRnd01() < 0.5 ? -1 : 1; }
  }
  b.was = f.state;
  for (const a of VPAD_ACTIONS)
    vp.set(a, (b.pressLeft > 0 && a === b.press) || (a === 'mod' && b.pressLeft > 0 && b.pressMod));
  vp.stick(sx, sy);
}

function decide(e: Ent, b: Brain, d: number): void {
  const f = e.f, o = f.opp!, go = o.g, kit = f.kit, r = simRnd01();
  const ok = (cmd: string) => !!kitCommandMove(kit, cmd) && kitCommandOkP(e, cmd);
  const kikon = kitCommandMove(kit, 'kikon');
  if (kikon && ok('kikon') && redP(go.reishi, go.reishiMax) && d < 9 && r < 0.5) { b.why = 'kikon'; press(b, 'kikon', 120); return; }
  if (o.f.state === 'guard' && o.f.guardT > 20 && d < 3 && r < 0.3) { b.why = 'breaker'; press(b, 'breaker', 20); return; }
  if (o.f.state === 'move' && d < 3.5 && r < 0.25) { b.why = 'guard'; press(b, 'guard', 16); return; }
  if (r < 0.06) { b.why = 'step'; press(b, 'step', 1, false, simRnd01() < 0.5 ? -1 : 1, 0); return; }
  if (r < 0.09 && e.g.fs >= T.fsHoho && d < 3) { b.why = 'hoho'; press(b, 'step', 1, true); return; }
  if (d <= 1.3) { b.why = 'j'; press(b, 'quick', 1); return; }
  if (d <= 3.0) {
    if (r < 0.6) { b.why = 'k'; press(b, 'flash', 1); }
    else if (r < 0.75 && ok('sp2')) { b.why = 'sp2'; press(b, 'sig', 1, true); }
    else if (r < 0.85 && ok('sig')) { b.why = 'sig'; press(b, 'sig', 1 + Math.floor(simRnd01() * 30)); }
    else { b.why = 'walk'; press(b, 'guard', 1, false, 0, 1); b.press = null; }
    return;
  }
  if (d > 5 && r < 0.35 && ok('sp1')) { b.why = 'sp1'; press(b, 'flash', 30, true); return; }
  if (d > 4 && r < 0.5 && ok('sig')) { b.why = 'sig'; press(b, 'sig', 1); return; }
  if (r < 0.6) { b.why = 'dash'; press(b, 'step', 40, false, 0, 1); return; }
  b.why = 'walk';
}
