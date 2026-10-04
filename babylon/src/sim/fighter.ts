// fighter.ts <- duel/lisp/fighter.lisp: FIGHTER-SYSTEM, the generic fighter (design-v1 §3). Each fixed step, per fighter:
// vpad -> command -> state machine -> move tick + the kit's hooks -> physics -> arena clamp. What a character does is data
// (kit.ts) plus hook names; this file never names one. The rules decide windows, costs and advantages; this applies them.
// States: idle (stand / walk / strafe) guard guard-hit step run hoho move (phase hold aura dash follow main) stun (phase =
// the reaction) air down wakeup cine intro win lose. Hits are not here: combat.ts resolves them after every fighter moved.
import { T } from './tuning';
import { angleWrap, deg, f32, fwdX, fwdZ, len32, turnToward } from './math';
import { STEP } from './time';
import { COMMANDS, type Action, type Command, type Vpad } from './vpad';
import {
  breakerNextPhase, breakerSpeed, brakeSpeed, canGuardP, chainOpenP, chainStartupCut, cancelOpenP, coldOkP, dirYaw,
  fieldK, fieldStep, fieldVelocity, frostSpeed, guardCancelOpenP, guardLockedP, hohoAllowedP, hohoCost, hohoDestination,
  invulnerableFrameP, kikonFollowSpeed, kikonFollowWait, kikonRushNextPhase, moveEndFrame, parryFrameP, rayRoom,
  runCarry, runStopP, spendBars, stepDirection, stickTowardStrafe, stringChaseSpeed, towardStrafeDir, trackStep,
  awakenAllowedP, bankaiAllowedP, burstFsGain, type BreakerPhase, type DefState,
} from './rules';
import {
  KIT_COMMANDS, callHook, findKit, hasKit, kitCommandCost, kitCommandMove, kitDrop, kitHook, kitLLink, kitNext,
  kitPipCmdP, makeHitwin, mvTotal, stringLatch, stringLinkP, type Kit, type Move,
} from './kit';
import {
  Brain, Ent, Fighter, Gauges, Pilot, W, clog, emit, findBody, oppOf, passiveP, sideName, stateOf, type FState,
} from './types';
import { newVpad } from './vpad';
import { armSpend, awaken, bankai, burst as burstBang, burstOkP, perfectNowP, respect, setForm } from './combat';

/** The perfect Hoho's automatic counter strike. */
export const PERFECT_HW = makeHitwin({ dmg: T.perfectCounterDamage, react: 'stagger', stun: T.perfectCounterStun, hs: T.hitstopHeavy });

// ---------------------------------------------------------------- creation
/** A fighter entity for SIDE (0 / 1) playing CHARACTER's base kit at (X 0 Z) facing YAW. CPU: a brain of DIFFICULTY
 *  (else the side's device drives the vpad through READER). */
export function spawnFighter(side: number, character: string, x: number, z: number, yaw: number,
                             o: { cpu?: boolean; difficulty?: string; reader?: ((vp: Vpad) => void) | null } = {}): Ent {
  const kit = findKit(character, 'base');
  const e = new Ent(new Fighter(side, character, kit), new Gauges(kit.reishi),
                    new Pilot(newVpad(o.cpu ? null : (o.reader ?? null)), !o.cpu), findBody(kit.body));
  e.yaw = yaw;
  e.pos[0] = x; e.pos[1] = 0; e.pos[2] = z;
  const difficulty = o.difficulty ?? 'normal';
  if (o.cpu) e.brain = new Brain(difficulty, (T.aiDelay as Record<string, number>)[difficulty] ?? 14);
  refreshLook(e);
  playClip(e, kit.stance, { blend: 0 });
  return e;
}

/** Body, weapon and hidden parts of E's current form (a form with the arm meter shows one crack per spent pip). */
export function refreshLook(e: Ent): void {
  const kit = e.f.kit;
  let hide = kit.hide;
  if (kit.pips) {
    const spent = (kit.pips.n as number) - Math.round(e.g.meter);
    hide = hide.filter((tag) => { const k = ['crack-1', 'crack-2', 'crack-3', 'crack-4'].indexOf(tag); return !(k >= 0 && k < spent); });
  }
  e.body = findBody(kit.body);
  e.look.weapon = kit.weapon; e.look.hide = hide; e.look.alpha = 1;
}

// ---------------------------------------------------------------- animation (the look bag: the renderer plays it)
export function playClip(e: Ent, clip: string | null,
                         o: { blend?: number; speed?: number; time?: number; restart?: boolean } = {}): void {
  const l = e.look, c = clip ?? e.f.kit.stance;
  if (o.restart === false && l.clip === c) { l.clipSpeed = o.speed ?? 1; return; }
  l.clip = c; l.blend = o.blend ?? 4; l.clipSpeed = o.speed ?? 1; l.clipTime = o.time ?? 0;
}

// ---------------------------------------------------------------- geometry
/** For hooks: parameter KEY of E's current move (its params). */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const moveParam = (e: Ent, key: string): any => e.f.move!.params[key];
/** [x z] of the point D metres in front of fighter E. */
export const ahead = (e: Ent, d: number): [number, number] =>   // (D a single, as the Lisp's literal)
  [f32(e.pos[0] + f32(f32(d) * fwdX(e.yaw))), f32(e.pos[2] + f32(f32(d) * fwdZ(e.yaw)))];
export const faceYawTo = (e: Ent, x: number, z: number): number => dirYaw(f32(x - e.pos[0]), f32(z - e.pos[2]));
/** Turn E toward his opponent by at most MAX-STEP radians. */
export function turnToOpp(e: Ent, f: Fighter, maxStep: number): void {
  if (f.dist > 0.01) e.yaw = angleWrap(turnToward(e.yaw, faceYawTo(e, f.ox, f.oz), maxStep));
}
/** Slide E DIST metres over FRAMES along (DX DZ) (knockback, pushback, Step, clash). */
export function setSlide(e: Ent, dist: number, frames: number, dx: number, dz: number): void {
  dx = f32(dx); dz = f32(dz);                                         // (single floats op by op, as the Lisp)
  const kb = e.mo.kb, l = Math.max(f32(1e-4), len32(dx, dz)), k = f32(f32(f32(dist) / Math.max(1, frames)) / l);
  kb[0] = dx * k; kb[2] = dz * k; e.mo.kbLeft = frames;
}

// ---------------------------------------------------------------- the view humans steer by
// A human's stick is camera-relative. The sim must not read the render camera, so the sim owns the view's DIRECTION:
// viewStep keeps it on its side of the fighter axis each step; the renderer smooths its camera toward it.
/** Degrees per second the behind view turns toward P1->P2. */
export const BEHIND_TURN = 300.0;
/** Keep the pair view on its side of the A (P1) -> B axis (never a 180 deg swing after a Hoho). RESET: P1 on the left. */
export function viewStep(a: Ent, b: Ent, reset = false): void {
  const p = a.pos, q = b.pos, dx = q[0] - p[0], dz = q[2] - p[2], d = Math.sqrt(dx * dx + dz * dz);
  if (d > 0.01) {
    const nx = -dz / d, nz = dx / d;
    const side = reset || nx * W.viewX + nz * W.viewZ >= 0 ? 1 : -1;
    W.viewSide = side; W.viewX = side * nx; W.viewZ = side * nz;
    W.behindYaw = reset ? dirYaw(dx, dz) : angleWrap(turnToward(W.behindYaw, dirYaw(dx, dz), trackStep(BEHIND_TURN)));
  }
}
/** E's stick as [toward strafe] relative to his opponent: a human's through the view; the CPU writes (strafe, toward). */
export function stickRelative(e: Ent, f: Fighter): [number, number] {
  const vp = e.pilot.vpad;
  if (e.pilot.camRelative)
    return stickTowardStrafe(vp.sx, vp.sy, W.viewBehind ? W.behindYaw : dirYaw(-W.viewX, -W.viewZ), e.pos[0], e.pos[2], f.ox, f.oz);
  return [vp.sy, vp.sx];
}

// ---------------------------------------------------------------- state changes
/** Back to neutral: stance clip, combo over (a victim leaving his reaction ends the combo). */
export function toIdle(e: Ent, blend = 6): void {
  const f = e.f;
  f.state = 'idle'; f.sf = 0; f.phase = null; f.move = null; f.crush = false; f.dmgBonus = 0; f.assistNext = false;
  f.comboHits = 0; f.comboLaunches = 0; f.comboAir = 0;
  e.mo.vel.fill(0);
  playClip(e, f.kit.stance, { blend });
}
export function callout(e: Ent, text: string): void { e.f.callout = text; e.f.calloutT = T.calloutFrames; }

/** Enter move MV (a Move of E's kit). Frame mv.enter is this step; moveStep advances it. */
export function startMove(e: Ent, mv: Move, button: string | null = null): Move {
  const f = e.f, enter = mv.enter, old = f.state === 'move' ? f.move : null;
  const offEnder = f.chain > 0                                       // ORANGE's restart, or a move started off a J / K
    || (!!old && old.flags.includes('ender') && (old.kind === 'quick' || old.kind === 'flash') && f.contact === 'hit')   // ender that hit
    || (!!old && old.kind === 'breaker' && f.contact === 'hit');      // J1 / K1 off a Breaker that landed
  f.endChase = offEnder;
  f.state = 'move'; f.move = mv; f.sf = enter; f.hits = 0;
  f.contact = null; f.queued = null; f.chained = false; f.landSf = -1; f.dmgBonus = 0; f.crush = false;
  f.stored = 0;                                                      // an interrupted stance keeps nothing
  f.button = button; f.hold = 0; f.perfect = false;
  f.assisted = f.assistNext; f.assistNext = false;                   // ASSIST: pressed for him
  f.follow = false; f.armorLeft = mv.armorHits;
  f.phase = mv.kind === 'breaker' || mv.kind === 'kikon' ? 'aura' : mv.hold ? 'hold' : 'main';
  e.mo.vel.fill(0);
  playClip(e, mv.clip, { blend: mv.blend, speed: mv.clipSpeed, time: (enter * mv.clipSpeed) / 60 });
  if (mv.kind === 'kikon') callout(e, 'KIKON');                     // its own name shows if it becomes the Kikon
  else if (mv.callout) callout(e, mv.callout);
  switch (mv.kind) {
    case 'sp': {                                                     // super flash: the opponent alone freezes
      const o = oppOf(e);
      o.f.freezeNext = Math.max(o.f.freezeNext, T.superFreeze);
      emit('super', e);
      break;
    }
    case 'breaker': emit('breaker', e); break;
    case 'kikon': emit('rush', e); break;
  }
  clog(() => `${sideName(e)} move ${mv.name}${e.brain?.why ? ' ' + e.brain.why : ''}`);
  if (f.phase === 'main')                                            // a hook on the move's first frame
    for (const [fr, hook] of mv.onFrame) if (fr === enter) callHook(hook, e);
  if (f.chain > 0) {                                                 // ORANGE: the first move after the cancel starts later
    f.chain = 0;                                                     // in its startup (the skipped frames' hooks run now)
    const cut = f.phase === 'main' ? chainStartupCut(mv.s, enter) : 0;
    if (cut > 0) {
      for (let fr = enter + 1; fr <= enter + cut && f.move === mv; fr++)
        for (const [hf, hook] of mv.onFrame) if (hf === fr) callHook(hook, e);
      if (f.move === mv) {
        f.sf = enter + cut;
        playClip(e, mv.clip, { blend: 0, speed: mv.clipSpeed, time: ((enter + cut) * mv.clipSpeed) / 60 });
        clog(() => `${sideName(e)} chain cut ${cut} f`);
      }
    }
  }
  return mv;
}

/** A hold / Breaker move leaves its pre-strike phase: the move proper starts at frame 0. */
export function enterMain(e: Ent, f: Fighter, mv: Move): void {
  f.phase = 'main'; f.sf = 0;
  e.mo.vel.fill(0);
  if (mv.clip2) playClip(e, mv.clip2, { blend: 0, speed: mv.clipSpeed });
  if (mv.kind === 'breaker') emit('breaker-end', e);
}

/** Step: a 2.5 m hop in the stick direction (neutral = back), iframes f3-f9, 24 f. */
export function startStep(e: Ent, f: Fighter): void {
  const [to0, st0] = stickRelative(e, f);
  const [to, st] = stepDirection(to0, st0);
  const [dx, dz] = towardStrafeDir(to, st, e.pos[0], e.pos[2], f.ox, f.oz);
  const fld = oppField(e, f);                                        // her cold field shortens a Step away from her
  setSlide(e, fld ? fieldStep(T.stepDistance, f32(-f32(f32(dx * fld[1]) + f32(dz * fld[2])) / Math.max(f32(1e-4), len32(dx, dz))), fld[0].step)
                  : T.stepDistance, 12, dx, dz);
  f.state = 'step'; f.sf = 0; f.move = null; f.queued = null;        // (the J latch)
  e.mo.vel.fill(0);
  kitHook(f.kit, 'step')?.(e);                                       // the form's own take-off (a clone)
  playClip(e, Math.abs(st) > Math.abs(to) ? (st > 0 ? 'sh-step-r' : 'sh-step-l') : to > 0 ? 'sh-step-f' : 'sh-step-b', { blend: 2 });
  clog(() => `${sideName(e)} step${e.brain?.why ? ' ' + e.brain.why : ''}`);
  emit('step', e);
}

/** The yaw a runner wants: the stick direction relative to the opponent (neutral = at him). */
export function runYaw(e: Ent, f: Fighter): number {
  const [to0, st0] = stickRelative(e, f);
  const [to, st] = stepDirection(to0, st0, 1.0);
  const [dx, dz] = towardStrafeDir(to, st, e.pos[0], e.pos[2], f.ox, f.oz);
  return dirYaw(dx, dz);
}
/** The run clip for the way he goes relative to where he faces: forward run, back-skate, or a side slide. */
export function runClip(e: Ent, f: Fighter): string {
  const hy = f.runYaw, fy = e.yaw, hx = fwdX(hy), hz = fwdZ(hy), fx = fwdX(fy), fz = fwdZ(fy);
  const aheadK = hx * fx + hz * fz, right = hz * fx - hx * fz, clips = f.kit.runClips;
  return aheadK > 0.5 ? clips[0] : aheadK < -0.5 ? clips[1] : right > 0 ? clips[2] : clips[3];
}
/** Step still held when the hop ends: run toward the stick direction at once, facing the opponent. */
export function startRun(e: Ent, f: Fighter): void {
  f.state = 'run'; f.sf = 0; f.phase = 'run'; f.runYaw = runYaw(e, f);
  playClip(e, runClip(e, f), { blend: 5, speed: f.kit.run / 8.0 });
  clog(() => `${sideName(e)} dash${e.brain?.why ? ' ' + e.brain.why : ''}`);
  emit('step', e);
}

/** Spend AMOUNT of flash-step (the regen waits T.fsDelay again). */
export function spendFs(g: Gauges, amount: number): void { g.fs = Math.max(0, Math.fround(g.fs - amount)); g.fsIdle = 0; }

/** Hoho: spend the flash-step, vanish, reappear behind the opponent (hohoStep). Checks PERFECT now. */
export function startHoho(e: Ent, f: Fighter): void {
  const g = e.g;
  spendFs(g, hohoCost(g.fs, g.burst));
  f.perfect = !f.assistNext && perfectNowP(e);                       // (an assisted one: never)
  f.assistNext = false;
  f.state = 'hoho'; f.sf = 0; f.move = null; f.hohoLock = T.hohoFrames + T.hohoLockout;
  e.mo.vel.fill(0);
  emit('hoho-out', e, e.pos[0], e.pos[2]);
  clog(() => `${sideName(e)} hoho`);
  if (f.perfect) {
    const o = oppOf(e);
    g.perfects++;
    g.fs = Math.fround(Math.min(T.fsMax, g.fs + burstFsGain(T.fsRefund, g.burst)));
    o.f.lockNext = T.perfectLock;
    respect(o);
    W.time.slowmo(T.perfectSlowmoScale, T.perfectSlowmoSeconds);
    emit('perfect', e, o);
    clog(() => `${sideName(e)} PERFECT HOHO`);
  }
}

export const coldCost = (kit: Kit, command: string): number => (kit.cold?.[command] as number | undefined) ?? 0;
/** COMMAND starts in KIT: its cold is spent (Rukia's cold gauge, the kit meter; never below 0). */
export function coldSpend(e: Ent, kit: Kit, command: string): void {
  const c = coldCost(kit, command);
  if (c > 0) e.g.meter = Math.max(0, Math.fround(e.g.meter - c));
}

/** Can E start COMMAND's move (of KIT) now: Reiatsu bars, not cooling down, a pip of the arm meter, L's cold, the kit's
 *  own ok hook (COMBO: a chained follow-up)? */
export function kitCommandOkP(e: Ent, command: string, kit: Kit = e.f.kit, ender = false, combo: unknown = null): boolean {
  const i = (KIT_COMMANDS as readonly string[]).indexOf(command), g = e.g;
  if (!(g.reiatsu >= kitCommandCost(kit, command) * T.reiatsuBar)) return false;
  if (!(i < 0 || e.f.cd[i] === 0)) return false;
  if (kitPipCmdP(kit, command) && !(g.meter >= (g.armOwed && !ender ? 2 : 1))) return false;
  if (command === 'sig' && !coldOkP(g.meter, coldCost(kit, 'sig'), !!combo)) return false;
  const h = kitHook(kit, 'ok');
  return !h || !!h(e, command, combo);                               // the form's own price / refusal
}

/** Start command CMD (pressed with vpad BUTTON) if the rules allow it now. ENDER: the O ender of a string. WITH: the move
 *  to start instead of the command's own (L after a K link), under the command's checks and costs. True when started. */
export function tryCommand(e: Ent, f: Fighter, cmd: string, button: string | null = null, ender = false, withMv: Move | null = null): boolean {
  const g = e.g, kit = f.kit;
  switch (cmd) {
    case 'step':
      if (kit.rooted) return false;                                  // a rooted form (Rukia's zero) refuses
      coldSpend(e, kit, 'step'); startStep(e, f); return true;
    case 'hoho':
      if (!kit.rooted && hohoAllowedP(false, g.fs, f.hohoLock, g.burst)) { startHoho(e, f); return true; }
      return false;
    case 'awaken': {
      const free = awakenStateP(e, f);
      // ponytail: the awakened forms are M3; until their kit is registered Awaken / Bankai are refused (no crash)
      if (awakenAllowedP(free, g.awaken, g.awakened) && hasKit(f.character, kit.awakenForm)) { awaken(e); return true; }
      if (kit.bankaiForm && bankaiAllowedP(free, g.konpaku) && hasKit(f.character, kit.bankaiForm)) { bankai(e); return true; }
      return false;
    }
    case 'burst': {
      const m = burstOkP(e);
      if (m) { f.burst = m; return true; }                           // applied after both stepped
      return false;
    }
    default: {
      const to = kitDrop(kit, cmd);
      const k2 = to ? findKit(f.character, to) : kit;
      const mv = withMv && !to ? withMv : kitCommandMove(k2, cmd);
      if (!(mv && kitCommandOkP(e, cmd, k2, ender, withMv))) return false;
      if (to) setForm(e, to);
      const cost = kitCommandCost(k2, cmd);
      if (cost > 0) g.reiatsu = spendBars(g.reiatsu, cost)[0];
      if (mv.cooldown > 0) f.cd[(KIT_COMMANDS as readonly string[]).indexOf(cmd)] = mv.cooldown;
      if (cmd === 'kikon') f.kikonN = k2.kikonKonpaku;                // its worth, fixed now
      if (kitPipCmdP(k2, cmd)) {                                      // the arm meter (Kenpachi's Bankai):
        if (cmd === 'f' || ender) g.armOwed = true; else armSpend(e, mv);   // a string owes one pip
      }
      coldSpend(e, k2, cmd);
      startMove(e, mv, button);
      return true;
    }
  }
}

/** May E awaken from its state: free (idle / guard / blockstun), or where a Burst could be pressed (a reaction or
 *  airborne, not locked, past the combo's T.burstMinHits-th hit). */
export function awakenStateP(_e: Ent, f: Fighter): boolean {
  const s = f.state;
  return s === 'idle' || s === 'guard' || s === 'guard-hit'
    || ((s === 'stun' || s === 'air') && f.lock === 0 && f.comboHits >= T.burstMinHits);
}

/** Commands from idle / walk / guard (burst: WHITE). kikon starts the Kikon rush at any time. */
export const NEUTRAL_COMMANDS: Command[] = ['kikon', 'awaken', 'hoho', 'burst', 'step', 'breaker', 'sp2', 'sp1', 'sig', 'f', 'q'];
/** Commands a run cancels into at once (neutral's, without Awaken); Step again = a new hop. */
export const RUN_COMMANDS: Command[] = ['kikon', 'hoho', 'burst', 'step', 'breaker', 'sp2', 'sp1', 'sig', 'f', 'q'];

/** The highest-priority buffered command among ALLOWED that can start now; consumes its press. A refused one doesn't hide
 *  the ones below it. Out of a guard cancel no attack starts before the cancelled move's recovery would have ended. */
export function command(e: Ent, f: Fighter, vp: Vpad, allowed: readonly string[]): boolean {
  for (const [cmd, button, mod] of COMMANDS) {
    if (allowed.includes(cmd) && vp.commandPressedP(button, mod)
        && !(f.gcLeft > 0 && (KIT_COMMANDS as readonly string[]).includes(cmd))
        && (tryCommand(e, f, cmd, button) || refusedCue(e, f, cmd, vp, button))) {
      vp.consume(button);
      return true;
    }
  }
  return false;
}

/** A kit command pressed while it cools down, or L without its cold, or one its kit's ok hook refuses: the press is eaten
 *  with the 'refused' cue. Always false: the commands below it may still start. */
export function refusedCue(e: Ent, f: Fighter, cmd: string, vp: Vpad, button: Action, combo: unknown = null): boolean {
  const i = (KIT_COMMANDS as readonly string[]).indexOf(cmd), kit = f.kit;
  if (i >= 0 && f.cd[i] > 0) {
    vp.consume(button); emit('refused', e, cmd);
    clog(() => `${sideName(e)} refused ${cmd}: cooling ${f.cd[i]}`);
  } else if (cmd === 'sig' && kitCommandMove(kit, 'sig') && e.g.meter < coldCost(kit, 'sig')) {
    vp.consume(button); emit('refused', e, cmd);
    clog(() => `${sideName(e)} refused ${cmd}: cold`);
  } else {
    const h = kitHook(kit, 'ok');
    if (h && kitCommandMove(kit, cmd) && !h(e, cmd, combo)) {
      vp.consume(button); emit('refused', e, cmd);
      clog(() => `${sideName(e)} refused ${cmd}: kit`);
    }
  }
  return false;
}

/** The opponent's cold field acting on E now: [field, ux, uz] (the unit vector from her to E), or null. */
export function oppField(e: Ent, f: Fighter): [Record<string, number>, number, number] | null {
  const o = f.opp, fo = o && o.alive ? o.f : null, k = fo?.kit.field as Record<string, number> | null | undefined;
  if (fo && k && f.dist <= k.r && !['stun', 'air', 'down', 'wakeup', 'cine'].includes(fo.state)) {
    const d = Math.max(1e-3, f.dist);
    return [k, f32(f32(e.pos[0] - f.ox) / d), f32(f32(e.pos[2] - f.oz) / d)];
  }
  return null;
}
/** E's walk / run velocity V inside the opponent's cold field: its part away from her x the field's away. */
export function fieldSlow(e: Ent, f: Fighter, v: Float32Array): void {
  const fld = oppField(e, f);
  if (fld) {
    const [vx, vz] = fieldVelocity(v[0], v[2], fld[1], fld[2], fieldK(fld[0].away, f.frost > 0));
    v[0] = vx; v[2] = vz;
  }
}

// ---------------------------------------------------------------- per-state steps
/** Guard is held and E may guard (the guard gauge). A form whose U is a move (a u hook) never guards. */
export function guardHeldP(e: Ent, vp: Vpad): boolean {
  return vp.down('guard') && canGuardP(e.g.gg, e.g.guardless) && !kitHook(e.f.kit, 'u');
}
/** A form with a u hook: a buffered U press calls it; true (the press used) when it started something. */
export function uPress(e: Ent, f: Fighter, vp: Vpad): boolean {
  const h = kitHook(f.kit, 'u');
  if (h && vp.commandPressedP('guard', 'any') && h(e)) { vp.consume('guard'); return true; }
  return false;
}
/** Does U raise a guard now? Not in a form whose U switches (guardTo) or whose ward is always up. */
export const guardP = (e: Ent, vp: Vpad): boolean => guardHeldP(e, vp) && !e.f.kit.guardTo && !passiveP(e, 'ward');

/** Idle / walk / strafe / guard: commands, then guard or walk, auto-facing. A guardTo form (Bankai East) switches to that
 *  form while U is held instead of guarding. */
export function neutralStep(e: Ent, f: Fighter, vp: Vpad): void {
  if (f.lock === 0 && (command(e, f, vp, NEUTRAL_COMMANDS) || uPress(e, f, vp))) return;
  const v = e.mo.vel;
  if (f.lock === 0 && f.kit.guardTo && guardHeldP(e, vp)) { setForm(e, f.kit.guardTo); f.guardT = 0; }
  if (f.lock === 0 && guardP(e, vp)) {
    if (f.state !== 'guard') {
      f.state = 'guard'; f.guardT = 0;
      if (e.pilot.camRelative) clog(() => `${sideName(e)} guard`);
      playClip(e, 'sh-guard', { blend: 3 });
    }
    f.guardT++;
    v.fill(0);
  } else {
    const [to, st] = f.lock === 0 ? stickRelative(e, f) : [0, 0];
    if (f.state === 'guard') toIdle(e, 4);
    f.guardT = passiveP(e, 'ward') ? Math.min(9999, f.guardT + 1) : 0;
    const m = len32(to, st), kit = f.kit;
    if (m < 0.2 || kit.walk <= 0) {                                  // (absolute zero: rooted where she stands)
      v.fill(0);
      playClip(e, kit.stance, { blend: 6, restart: false });
    } else {
      const [dx, dz] = towardStrafeDir(to, st, e.pos[0], e.pos[2], f.ox, f.oz);
      const s = f32(f32(frostSpeed(kit.walk, f.frost) * Math.min(1, m)) * f32(1 / m));
      v[0] = s * dx; v[2] = s * dz;
      fieldSlow(e, f, v);
      playClip(e, Math.abs(st) > Math.abs(to) ? (st > 0 ? 'sh-strafe-r' : 'sh-strafe-l') : to > 0 ? 'sh-walk-f' : 'sh-walk-b',
               { blend: 6, restart: false });
    }
  }
  turnToOpp(e, f, deg(T.faceRate));
}

/** Charge / stance: hold until the button is released (min..max frames), then the move proper. */
export function holdPhaseStep(e: Ent, f: Fighter, vp: Vpad, mv: Move): void {
  f.hold++;
  if (mv.tick) callHook(mv.tick, e);
  const [lo, hi] = mv.hold!;
  if (f.hold >= hi || (f.hold >= lo && !vp.down(f.button as Action))) {
    f.charge = f.hold;
    if (mv.release) callHook(mv.release, e);
    if (f.move === mv) enterMain(e, f, mv);
  }
}

/** Breaker: the aura, then the dash while held (breakerNextPhase), then the strike. */
export function breakerPhaseStep(e: Ent, f: Fighter, vp: Vpad, mv: Move): void {
  f.hold++;
  const next = breakerNextPhase(f.phase as 'aura' | 'dash', f.hold, vp.down(f.button as Action), f.dist);
  const v = e.mo.vel;
  if (next === 'strike') enterMain(e, f, mv);
  else {
    if (next !== f.phase) { f.phase = next; f.hold = 0; }
    v.fill(0);
    if (next === 'dash') {
      turnToOpp(e, f, trackStep(mv.track));
      const sp = breakerSpeed(f.hold);
      v[0] = sp * fwdX(e.yaw); v[2] = sp * fwdZ(e.yaw);
    }
  }
}

/** A Kikon rush module's number KEY (aura aim speed dashMax dashTrack) from its move params. */
export const rushParam = (mv: Move, key: string): number => mv.params[key];

/** Kikon rush: the aura (turning at aim), then the dash toward the opponent at speed (turning at dashTrack; 0 = locked)
 *  until kikonRushNextPhase says strike. After a strike that hit with the button held (phase follow): dash in after the
 *  knocked-back victim for kikonFollowWait frames, then the strike again, the follow-up. */
export function kikonRushStep(e: Ent, f: Fighter, mv: Move): void {
  f.hold++;
  const v = e.mo.vel, phase = f.phase;
  v.fill(0);
  if (phase === 'follow') {
    const left = kikonFollowWait(mv.s) - f.hold;
    turnToOpp(e, f, trackStep(rushParam(mv, 'aim')));
    runVelocity(e, kikonFollowSpeed(f.dist, left, mv.params.followSpeed ?? Math.max(14.0, rushParam(mv, 'speed'))));
    if (left <= 0) {
      f.hits = 0; f.contact = null; f.landSf = -1;
      enterMain(e, f, mv);
    }
  } else {
    let next = kikonRushNextPhase(phase as 'aura' | 'dash', f.hold, f.dist, rushParam(mv, 'aura'), rushDashMax(f, mv));
    if (next === 'strike' && phase === 'dash' && f.endChase && f.hold < rushDashMax(f, mv) && f.opp!.mo.kbLeft > 0)
      next = 'dash';                                                 // off a pushing ender: he still slides away, dash on
    if (next === 'strike') enterMain(e, f, mv);
    else {
      if (next !== phase) { f.phase = next; f.hold = 0; emit('rush-dash', e); }
      if (next === 'dash') {
        turnToOpp(e, f, trackStep(rushParam(mv, 'dashTrack')));
        runVelocity(e, rushDashSpeed(f, mv));
      } else turnToOpp(e, f, trackStep(rushParam(mv, 'aim')));
    }
  }
}

/** The move proper, one frame: tracking and lunge in the startup, frame hooks, chains and cancels, the end. */
export function mainPhaseStep(e: Ent, f: Fighter, vp: Vpad, mv: Move): void {
  const sf = ++f.sf, s = mv.s, v = e.mo.vel;
  v.fill(0);
  if (sf < s) {
    const chained = f.chained, rooted = f.kit.rooted;                // (rooted: her reach is the ice's)
    const chase = !rooted && (f.endChase || (chained && !(mv.kind === 'quick' || mv.kind === 'flash')))   // J / K links: no chase
      ? stringChaseSpeed(f.dist, mv.reach, s - sf, f.endChase ? T.enderChaseMax : T.chaseMax) : 0;
    const slide = mv.slide > 0 && f.dist > T.lungeStop && !rooted ? f32(60 * f32(mv.slide / s)) : 0;
    const sp = Math.max(chase, slide);                               // a lunge stopping at the opponent; a link's chase
    turnToOpp(e, f, trackStep(chained ? Math.max(mv.track, T.chaseTrack) : mv.track));
    if (sp > 0) { v[0] = sp * fwdX(e.yaw); v[2] = sp * fwdZ(e.yaw); }
  }
  for (const [fr, hook] of mv.onFrame) if (fr === sf) callHook(hook, e);
  if (mv.tick) callHook(mv.tick, e);
  for (const w of mv.hits) if (sf === w.from) { emit('swing', e, mv.kind); break; }
  if (f.move === mv) {                                               // a hook may have started another move
    if (f.lock === 0 && moveCommands(e, f, vp, mv, sf)) { /* a chain / cancel started */ }
    else if (f.lock === 0 && guardCancelOpenP(sf, s, mv.a, mv.r, f.contact, mv.kind === 'quick') && guardHeldP(e, vp)) {
      clog(() => `${sideName(e)} guard cancel ${mv.name} f${sf}`);  // the guard cancel: U held after its hit landed
      toIdle(e);
      f.gcLeft = s + mv.a + mv.r - sf;                               // no attack before its recovery would have ended
      if (guardP(e, vp)) { f.state = 'guard'; f.guardT = 0; playClip(e, 'sh-guard', { blend: 3 }); }
    } else if (sf >= moveEndFrame(s, mv.a, mv.r, mv.whiff, f.contact, mv.hits.length === 0)) toIdle(e);
  }
}

/** Push fighter B DIST metres away from A over FRAMES; what the arena's edge leaves no room for pushes A back instead.
 *  [B's share, A's share]. */
export function pushApart(a: Ent, b: Ent, dist: number, frames: number): [number, number] {
  const p = a.pos, q = b.pos, dx = f32(q[0] - p[0]), dz = f32(q[2] - p[2]);   // (singles, as the Lisp)
  const l = Math.max(f32(1e-4), len32(dx, dz)), ux = f32(dx / l), uz = f32(dz / l);
  const room = rayRoom(q[0], q[2], ux, uz, f32(f32(T.arenaRadius) - f32(b.body.hurtR)));
  const mb = Math.min(dist, room), ma = f32(dist - mb);
  if (mb > 0.01) setSlide(b, mb, frames, ux, uz);
  if (ma > 0.01) setSlide(a, ma, frames, -ux, -uz);
  return [mb, ma];
}

/** E's J / K string ender MV (J3 / K3) just hit O: O is pushed out of the reach of E's J1 (after J3) or K1 (after K3). */
export function enderPush(e: Ent, o: Ent, mv: Move): void {
  const f = e.f, opener = kitCommandMove(f.kit, mv.kind === 'quick' ? 'q' : 'f');
  const push = opener ? f32(f32(f32(f32(opener.reach + f32(opener.slide)) + f32(o.body.hurtR)) + f32(T.enderPush)) - f.dist) : null;
  if (push != null && push > 0) {
    const [mb, ma] = pushApart(e, o, push, T.enderPushFrames);
    clog(() => `${sideName(e)} ender push ${mv.name} ${mb.toFixed(1)} m (attacker ${ma.toFixed(1)})`);
  }
}

/** Advance the current move one frame: its pre-strike phase, or the move proper. */
export function moveStep(e: Ent, f: Fighter, vp: Vpad): void {
  const mv = f.move!;
  switch (f.phase) {
    case 'hold': holdPhaseStep(e, f, vp, mv); break;
    case 'aura': case 'dash': case 'follow':
      if (mv.kind === 'kikon') kikonRushStep(e, f, mv); else breakerPhaseStep(e, f, vp, mv);
      break;
    default: mainPhaseStep(e, f, vp, mv);
  }
}

/** The rush MV's dash frames: its module's dashMax, at least T.enderODash off a pushing ender. */
export const rushDashMax = (f: Fighter, mv: Move): number =>
  f.endChase ? Math.max(T.enderODash, rushParam(mv, 'dashMax')) : rushParam(mv, 'dashMax');
export const rushDashSpeed = (f: Fighter, mv: Move): number =>
  f.endChase ? Math.max(T.enderOSpeed, rushParam(mv, 'speed')) : rushParam(mv, 'speed');

/** The O ender: the Kikon rush just started off a link-3 hit skips its aura: its strike at once within T.kikonTrigger
 *  (or a module with no dash), else its dash. */
export function skipAura(e: Ent, f: Fighter): void {
  const mv = f.move!;
  if (!f.endChase && kikonRushNextPhase('aura', 0, f.dist, 0, rushDashMax(f, mv)) === 'strike') enterMain(e, f, mv);
  else { f.phase = 'dash'; f.hold = 0; emit('rush-dash', e); }
}

/** Chains (string follow-ups) and cancels during a move, walked in COMMANDS priority order. A J / K press during a
 *  string link is latched (the last allowed press wins) and consumed at once; the latched link starts when the chain
 *  opens. A Breaker that landed cancels into J1 / K1. O is the ender: only off a link-3 hit. L during a K (J) link of a
 *  form with lAfterK (lAfterJ) is latched too. True when a new move / action started. */
export function moveCommands(e: Ent, f: Fighter, vp: Vpad, mv: Move, sf: number): boolean {
  const kit = f.kit, landed = f.contact, name = mv.name;
  for (const [cmd, button, mod] of COMMANDS) {
    if (!['kikon', 'q', 'f', 'sp1', 'sp2', 'sig', 'hoho', 'burst'].includes(cmd) || !vp.commandPressedP(button, mod)) continue;
    let took = false;
    switch (cmd) {
      case 'kikon':                                                  // the O ender: a completed string
        took = mv.flags.includes('ender') && cancelOpenP(sf, f.landSf, mvTotal(mv), landed === 'hit')
          && tryCommand(e, f, cmd, button, true) && (skipAura(e, f), true);
        break;
      case 'q': case 'f':
        if (stringLinkP(kit, name)) {                                // the latch takes every J / K press
          f.queued = stringLatch(kit, name, cmd, f.queued);
          vp.consume(button);
          took = false;
        } else if (mv.kind === 'breaker')                            // the Breaker opens a string: J1 / K1 off its hit
          took = cancelOpenP(sf, f.landSf, mvTotal(mv), landed === 'hit') && tryCommand(e, f, cmd, button);
        break;
      case 'sig': {                                                  // L after a J / K link: latched like a link
        const l = kitLLink(kit, name);
        if (l) {
          if (kitCommandOkP(e, 'sig', f.kit, false, l)) { f.queued = 'sig'; vp.consume(button); }
          else refusedCue(e, f, 'sig', vp, button, l);               // refused: the cue, eaten
          took = false;
        } else took = cancelInto(e, f, kit, mv, sf, landed, cmd, button);
        break;
      }
      case 'burst': took = tryCommand(e, f, cmd, button); break;     // ORANGE (burstOkP: his hit landed)
      default: took = cancelInto(e, f, kit, mv, sf, landed, cmd, button);
    }
    if (took) { vp.consume(button); return true; }
  }
  const q = f.queued;                                                // the latched link, once the chain opens
  if (q && chainOpenP(sf, mv.s, mv.a, mv.r, q === 'sig' ? landed : (landed ?? f.chained))) {
    if (q === 'sig') {                                               // L after a K link: its own checks and costs
      f.queued = null;
      if (tryCommand(e, f, 'sig', null, false, kitLLink(kit, name))) { f.chained = true; return true; }
      return false;
    }
    const next = kitNext(kit, name, q)!, pip = kitPipCmdP(kit, q);
    if (pip && e.g.meter < 1) { f.queued = null; return false; }    // a K link with no pip left: the string ends here
    if (pip) e.g.armOwed = true;                                     // the string's one pip, charged when it ends
    coldSpend(e, kit, q);                                            // each link's cold (Rukia)
    startMove(e, next, q === 'q' ? 'quick' : 'flash');
    f.chained = true;
    return true;
  }
  return false;
}

/** An on-hit cancel out of J / K link MV: SPs, Hoho, a cancel Signature (L). */
export function cancelInto(e: Ent, f: Fighter, kit: Kit, mv: Move, sf: number, landed: string | null, cmd: string, button: Action): boolean {
  if (!(mv.kind === 'quick' || mv.kind === 'flash')) return false;
  if (cmd === 'sig') { const l = kitCommandMove(kit, 'sig'); if (!(l && l.flags.includes('cancel'))) return false; }
  return cancelOpenP(sf, f.landSf, mvTotal(mv), landed === 'hit') && tryCommand(e, f, cmd, button);
}

/** A reaction / blockstun counts down (Burst may be pressed); then neutral (guard again if held). Blockstun past its end
 *  waits while the guard lock holds him. */
export function stunStep(e: Ent, f: Fighter, vp: Vpad): void {
  if (f.lock === 0) command(e, f, vp, ['burst', 'awaken']);
  if (++f.sf >= f.stun && !(f.state === 'guard-hit' && f.glock)) {
    toIdle(e);
    if (guardP(e, vp)) { f.state = 'guard'; f.guardT = T.guardRaise; playClip(e, 'sh-guard', { blend: 3 }); }
  }
}

/** Can E's move MV still go on into a follow-up (the guard lock's MORE)? */
export function chainMoreP(e: Ent, f: Fighter, mv: Move): boolean {
  const kit = f.kit, name = mv.name;
  if (stringLinkP(kit, name)) return true;
  const l = kitLLink(kit, name);
  if (l && kitCommandOkP(e, 'sig', kit, false, l)) return true;
  if (f.contact === 'hit' && (mv.kind === 'quick' || mv.kind === 'flash')) return true;
  return burstOkP(e) === 'orange';
}

/** Does the guard lock hold F (in blockstun) on his next step (guardLockedP, his attacker's side read here)? */
export function guardLockOf(f: Fighter): boolean {
  const o = f.opp, fo = o && o.alive ? o.f : null, mv = fo && fo.state === 'move' ? fo.move : null;
  if (!fo) return false;
  return guardLockedP(f.state, f.glock, fo.chain, fo.state, fo.phase, fo.sf, mv ? mv.s : 0, mv ? mv.a : 0, mv ? mv.r : 0,
                      mv && (fo.contact || fo.chained), mv && f.state === 'guard-hit' && chainMoreP(o!, fo, mv));
}
export const guardLockedNowP = (f: Fighter): boolean => f.state === 'guard-hit' && f.glock && f.sf >= f.stun;

/** The hop; at its end a Step still held becomes a run. From T.stepJCancel J cancels the rest into J1; a J pressed
 *  earlier in the hop is latched for it. */
export function stepStep(e: Ent, f: Fighter, vp: Vpad): void {
  const j = COMMANDS.find((c) => c[0] === 'q')!;
  if (f.lock === 0 && vp.commandPressedP(j[1], j[2])) { vp.consume(j[1]); f.queued = 'q'; }
  if (f.queued && f.sf >= T.stepJCancel && f.gcLeft === 0 && tryCommand(e, f, 'q', j[1])) return;
  if (++f.sf >= T.stepFrames) {
    f.queued = null;
    if (f.lock === 0 && vp.down('step')) startRun(e, f); else toIdle(e);
  }
}

/** E moves at SPEED along YAW (default his facing). */
export function runVelocity(e: Ent, speed: number, yaw = e.yaw): void {
  const v = e.mo.vel;
  v[0] = speed * fwdX(yaw); v[2] = speed * fwdZ(yaw);
}
/** The fraction (-1..1) of E's run heading that points at his opponent. */
export function runClosing(e: Ent, f: Fighter): number {
  const p = e.pos, yaw = f.runYaw, d = f.dist;
  return d < 0.01 ? 0 : f32(f32(f32(fwdX(yaw) * f32(f.ox - p[0])) + f32(fwdZ(yaw) * f32(f.oz - p[2]))) / d);   // (singles)
}

/** The run: a command cancels it at once (a move keeps runCarry of momentum), Guard stops it, releasing Step brakes
 *  (T.runBrake f, committed); else run at the kit's speed toward the stick direction relative to the opponent. */
export function runStep(e: Ent, f: Fighter, vp: Vpad): void {
  const v = e.mo.vel, vx = v[0], vz = v[2];
  const speed = frostSpeed(f.kit.run, f.frost), sf = ++f.sf, free = f.lock === 0;
  if (f.phase === 'brake') {
    const s = runStopP(f.dist, runClosing(e, f), speed) ? 0 : brakeSpeed(speed, sf);
    turnToOpp(e, f, deg(T.faceRate));
    if (s <= 0 || sf >= T.runBrake) toIdle(e); else runVelocity(e, s, f.runYaw);
  } else if (free && (command(e, f, vp, RUN_COMMANDS) || uPress(e, f, vp))) {
    if (stateOf(e) === 'move') {
      setSlide(e, runCarry(f.dist), T.runCarryFrames, vx, vz);
      clog(() => `${sideName(e)} run -> ${f.move!.name}, carry ${runCarry(f.dist).toFixed(1)} m`);
    }
  } else if (free && guardHeldP(e, vp) && !passiveP(e, 'ward')) { toIdle(e, 3); neutralStep(e, f, vp); }
  else if (!(free && vp.down('step'))) {
    f.phase = 'brake'; f.sf = 0;
    playClip(e, f.kit.stance, { blend: 6 });
  } else {
    f.runYaw = angleWrap(turnToward(f.runYaw, runYaw(e, f), trackStep(T.runTurn)));
    turnToOpp(e, f, deg(T.faceRate));
    if (runStopP(f.dist, runClosing(e, f), speed)) toIdle(e, 4);
    else {
      runVelocity(e, speed, f.runYaw);
      fieldSlow(e, f, e.mo.vel);
      playClip(e, runClip(e, f), { blend: 5, speed: speed / 8.0, restart: false });
    }
  }
}

/** Vanish, reappear behind the opponent on frame T.hohoAppear facing him; a perfect Hoho swings on T.hohoCounterPose
 *  (its strike, on T.hohoCounterStrike, is collected by combat.ts like any hit). */
export function hohoStep(e: Ent, f: Fighter): void {
  const sf = ++f.sf, o = oppOf(e);
  e.look.alpha = sf < T.hohoAppear ? 1 - sf / T.hohoAppear : 1;
  if (sf === T.hohoAppear) {
    const q = o.pos, p = e.pos;
    const [x, z, yaw] = hohoDestination(q[0], q[2], o.yaw);
    p[0] = x; p[2] = z; e.yaw = yaw;
    playClip(e, 'sh-hoho-in', { blend: 0 });
    emit('hoho-in', e, p[0], p[2]);
    kitHook(f.kit, 'hoho')?.(e);                                     // the form's own arrival
  }
  if (sf === T.hohoCounterPose && f.perfect) playClip(e, kitCommandMove(f.kit, 'q')!.clip, { blend: 0, time: 0.1 });
  if (sf >= T.hohoFrames) toIdle(e, 3);
}

/** Airborne until landing (Burst may be pressed), then down 30 f and wakeup 30 f (both invulnerable). */
export function airStep(e: Ent, f: Fighter, vp: Vpad): void {
  if (f.state === 'air' && f.lock === 0) command(e, f, vp, ['burst', 'awaken']);
  const sf = ++f.sf, mo = e.mo;
  switch (f.state) {
    case 'air':
      if (mo.grounded && sf > 2) { f.state = 'down'; f.sf = 0; playClip(e, 'sh-down', { blend: 3 }); emit('land', e); }
      break;
    case 'down':
      if (sf >= T.reactionFrames.down) { f.state = 'wakeup'; f.sf = 0; playClip(e, 'sh-wakeup', { blend: 2 }); }
      break;
    case 'wakeup':
      if (sf >= T.reactionFrames.wakeup) toIdle(e);
      break;
  }
}

// ---------------------------------------------------------------- reactions (called by combat.ts)
/** Put E into reaction REACT (STUN frames for grounded ones), pushed KB metres away from (FROM-X FROM-Z). */
export function setReaction(e: Ent, react: string, stun: number, fromX: number, fromZ: number, kb: number): void {
  const f = e.f, mo = e.mo, p = e.pos, v = mo.vel;
  const dx = p[0] - fromX, dz = p[2] - fromZ, air = f.state === 'air';
  if (f.state === 'down' || f.state === 'wakeup') return;
  f.move = null; f.sf = 0; f.phase = react;
  v.fill(0);
  if (air || react === 'launch' || react === 'knockdown') {
    f.state = 'air'; mo.grounded = false;
    v[1] = (T.airVy as Record<string, number>)[react === 'launch' || react === 'knockdown' ? react : 'air'];
    setSlide(e, kb > 0 ? Math.fround(Math.fround(T.airSlide) * kb) : 1.0, T.airSlideFrames, dx, dz);
    playClip(e, 'sh-launch', { blend: 2 });
    if (react === 'launch') emit('launch', e);
  } else {
    f.state = 'stun'; f.stun = stun;
    if (kb > 0) setSlide(e, kb, Math.min(stun, T.knockbackSlideFrames), dx, dz);
    const clips: Record<string, string> = { stagger: 'sh-stagger', knockback: 'sh-knockback', 'guard-break': 'sh-guard-break',
                                            crumple: 'sh-crumple', clash: 'sh-clash', bind: 'sh-bound' };
    playClip(e, clips[react] ?? 'sh-flinch', { blend: 0 });
  }
}

/** Blockstun of STUN frames, pushed back from (FROM-X FROM-Z); ADV = the blocked move's advantage. */
export function setBlockstun(e: Ent, stun: number, fromX: number, fromZ: number, adv: number, clip: string | null = null): void {
  const f = e.f, p = e.pos;
  f.state = 'guard-hit'; f.sf = 0; f.stun = stun; f.move = null; f.blockAdv = adv;
  e.mo.vel.fill(0);
  setSlide(e, T.blockPushback, 6, p[0] - fromX, p[2] - fromZ);
  playClip(e, clip ?? 'sh-guard-hit', { blend: 0 });
}

/** E's side of the triangle for resolveContact. Bankai West's ward is guard in his free states, the non-invulnerable
 *  frames of Step / Hoho and his own moves (a parry's window is still parry); never in a reaction. */
export function defenderState(e: Ent): DefState {
  const f = e.f, sf = f.sf, mv = f.move;
  const open: DefState = passiveP(e, 'ward') && f.guardT >= T.guardRaise ? 'guard' : 'neutral';
  const st = f.invuln > 0 ? 'invuln' : f.state;
  switch (st) {
    case 'idle': case 'run': return open;
    case 'invuln': return 'invuln';                                  // after a Burst
    case 'guard': return f.guardT >= T.guardRaise && canGuardP(e.g.gg, e.g.guardless) ? 'guard' : 'neutral';
    case 'guard-hit': return 'guard';
    case 'step': return invulnerableFrameP(sf, T.stepIframes) ? 'invuln' : open;
    case 'hoho': return invulnerableFrameP(sf, T.hohoIframes) ? 'invuln' : open;
    case 'down': case 'wakeup': case 'cine': case 'intro': case 'win': case 'lose': return 'invuln';
    case 'air': return f.phase === 'knockdown' ? 'invuln' : 'neutral';   // the combo limits' forced knockdown
    case 'move': {
      const m = mv!;
      if (m.kind === 'breaker' && (f.phase === 'aura' || f.phase === 'dash' || sf < m.s)) return 'breaker';
      if (f.armorLeft > 0 && (m.kind === 'kikon' ? f.phase === 'dash' : f.phase === 'main' && T.armorFrom <= sf && sf < m.s))
        return 'armor';
      if (m.flags.includes('stance') && f.phase === 'hold') return f.hold < T.stanceIn ? 'stance-in' : 'stance';
      if (m.flags.includes('parry') && f.phase === 'main' && parryFrameP(sf, m.params.window)) return 'parry';
      if (m.flags.includes('shield') && f.phase === 'main' && m.s <= sf && sf < m.s + m.a) return 'guard';
      return open;
    }
    default: return 'neutral';
  }
}

/** E's Breaker phase for breakerClashP: aura dash strike (strike startup / active) or null. */
export function breakerPhase(e: Ent): BreakerPhase {
  const f = e.f, mv = f.move;
  if (f.state === 'move' && mv && mv.kind === 'breaker') {
    if (f.phase === 'aura' || f.phase === 'dash') return f.phase;
    return f.sf < mv.s + mv.a ? 'strike' : null;
  }
  return null;
}

// ---------------------------------------------------------------- physics
/** Walk / dash velocity, the slide, gravity and landing, the arena wall. */
export function fighterPhysics(e: Ent): void {
  // (single floats op by op, as the Lisp's declared f32 physics; the stores into the f32vecs round the sums)
  const mo = e.mo, p = e.pos, v = mo.vel, kb = mo.kb, dt = f32(STEP), r = f32(f32(T.arenaRadius) - f32(e.body.hurtR));
  p[0] += f32(dt * v[0]); p[2] += f32(dt * v[2]);
  if (mo.kbLeft > 0) { p[0] += kb[0]; p[2] += kb[2]; mo.kbLeft--; }
  if (!mo.grounded) {
    v[1] -= f32(f32(T.gravity) * dt); p[1] += f32(dt * v[1]);
    if (p[1] <= 0 && v[1] <= 0) { p[1] = 0; v[1] = 0; mo.grounded = true; }
  }
  const x = p[0], z = p[2], d = len32(x, z);
  if (d > r) { const k = f32(r / d); p[0] = x * k; p[2] = z * k; }
}

/** Two grounded, visible fighters never overlap: push both apart equally (symmetric). */
export function separateFighters(a: Ent, b: Ent): void {
  const no: FState[] = ['hoho', 'cine'];
  if (no.includes(stateOf(a)) || no.includes(stateOf(b))) return;
  // (single floats op by op, as the Lisp: the push lands them exactly hurt-r apart, and d < minD must agree next step)
  const p = a.pos, q = b.pos, dx = f32(q[0] - p[0]), dz = f32(q[2] - p[2]), d = len32(dx, dz);
  const minD = f32(f32(a.body.hurtR) + f32(b.body.hurtR));
  if (d < minD && Math.abs(p[1] - q[1]) < 1.2) {
    const push = f32(0.5 * f32(minD - d)), ux = d > 1e-3 ? f32(dx / d) : 1, uz = d > 1e-3 ? f32(dz / d) : 0;
    p[0] -= f32(push * ux); p[2] -= f32(push * uz); q[0] += f32(push * ux); q[2] += f32(push * uz);
  }
}

// ---------------------------------------------------------------- the system
/** One fixed step of fighter E (the counters in the Lisp's order, verbatim). */
export function fighterStep(e: Ent, f: Fighter): void {
  if (f.freeze > 0) { f.freeze--; return; }
  if (f.lock > 0) f.lock--;
  if (f.hohoLock > 0) f.hohoLock--;
  if (f.gcLeft > 0) f.gcLeft--;
  if (f.invuln > 0) f.invuln--;
  if (f.calloutT > 0) f.calloutT--;
  if (f.frost > 0) f.frost--;
  for (let i = 0; i < f.cd.length; i++) if (f.cd[i] > 0) f.cd[i]--;
  const vp = e.pilot.vpad;
  switch (f.state) {
    case 'idle': case 'guard': neutralStep(e, f, vp); break;
    case 'move': moveStep(e, f, vp); break;
    case 'stun': case 'guard-hit': stunStep(e, f, vp); break;
    case 'step': stepStep(e, f, vp); break;
    case 'run': runStep(e, f, vp); break;
    case 'hoho': hohoStep(e, f); break;
    case 'air': case 'down': case 'wakeup': airStep(e, f, vp); break;
    default: break;
  }
  if (f.chain > 0) f.chain--;                                        // ORANGE's window
  fighterPhysics(e);
  e.look.clipTime += STEP * e.look.clipSpeed;
}

/** Every fighter: snapshot the opponents' positions first (nobody sees the other's move of this step: a symmetric sim),
 *  step each, apply the deferred cross-fighter writes, then keep them apart. */
export function fighterSystem(): void {
  const a = W.p1, b = W.p2, both = [a, b];
  for (const e of both) {
    const f = e.f, o = f.opp;
    if (o && o.alive) {
      const p = e.pos, q = o.pos, dx = f32(q[0] - p[0]), dz = f32(q[2] - p[2]);
      f.ox = q[0]; f.oz = q[2]; f.dist = len32(dx, dz);
    }
  }
  viewStep(a, b);
  for (const e of both) if (e.f.state !== 'cine') fighterStep(e, e.f);
  // freezes / locks one fighter put on the other take effect now that both have stepped
  for (const e of both) {
    const f = e.f;
    f.freeze = Math.max(f.freeze, f.freezeNext); f.lock = Math.max(f.lock, f.lockNext);
    f.freezeNext = 0; f.lockNext = 0;
  }
  // a burst pressed this step applies now, unless a cinematic began (an awakening on the same step wins)
  for (const e of both) {
    const m = e.f.burst;
    if (m) { e.f.burst = null; if (!W.cine) burstBang(e, m as 'white' | 'blue' | 'orange'); }
  }
  // the guard lock, judged once both stepped (and any burst applied), read by the blockstun on the next step
  for (const e of both) e.f.glock = guardLockOf(e.f);
  separateFighters(a, b);
}
