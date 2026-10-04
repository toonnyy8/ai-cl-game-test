// hazards.ts <- duel/lisp/hazards.lisp: every hit that isn't a fighter's melee is one Hazard (in World.hazards):
//   wave      the Signature flame wave: a moving oriented box, hits once
//   fireball  Shiranui: a homing sphere, swept from last step's position (no tunnelling)
//   pillars   Ennetsu Jigoku: a ring of T.ennetsuPillars cylinders around where it erupted
//   line      a ground line cut / crack: a look only
//   bind / freeze  a disc at the feet (radius SIZE, height Y) that grabs once its DELAY runs out
//   hand      South: a skeleton's arm clawing out of the ground, a look only
//   rift      KUKAN-GIRI: its hitwin's volume fixed in the world, cuts once its DELAY runs out; closed if the owner is hit
// hazardSystem moves them (sim steps, sim randomness only), collectHazardHits hands their hits to combat.ts's hitSystem.
// Hazards never hit their owner. A destroyed hazard is marked dead and swept at the end of the system that killed it.
import { T } from './tuning';
import { angleWrap, f32, fwdX, fwdZ, turnToward, TWO_PI } from './math';
import { cosf, sinf } from './sinf';
import { STEP } from './time';
import { capsuleCylHitP, cylCylHitP, oboxCylHitP, volHitP } from './hitvol';
import { dirYaw } from './rules';
import { callHook, type HitWin } from './kit';
import { Hazard, W, clog, emit, sideName, type Ent } from './types';
import { defenderState } from './fighter';

export interface HazardOpts {
  x?: number; y?: number; z?: number; yaw?: number; speed?: number; turn?: number; size?: number; life?: number;
  delay?: number; hits?: number; hw?: HitWin | null; look?: string | null; src?: boolean; fragile?: boolean;
  hook?: string | null; data?: unknown;
}
/** A new hazard of KIND for fighter OWNER. LIFE / DELAY in frames; HW = the hit it deals (null = look only). SRC: its hit
 *  comes from the owner's position; FRAGILE: it closes while it waits if the owner is hit. HOOK: a character's function
 *  (hz event ...) called with 'step' (true skips the generic step), 'close' and 'touches'. */
export function spawnHazard(kind: string, owner: Ent, o: HazardOpts = {}): Hazard {
  const h = new Hazard(kind, owner);
  h.x = o.x ?? 0; h.y = o.y ?? 0; h.z = o.z ?? 0; h.px = h.x; h.pz = h.z;
  h.yaw = o.yaw ?? 0; h.speed = o.speed ?? 0; h.turn = o.turn ?? 0; h.size = o.size ?? 0.5;
  h.life = o.life ?? 60; h.delay = o.delay ?? 0; h.hw = o.hw ?? null; h.hitsLeft = h.hw ? (o.hits ?? 1) : 0;
  h.look = o.look ?? null; h.src = !!o.src; h.fragile = !!o.fragile; h.hook = o.hook ?? null; h.data = o.data ?? null;
  // the Lisp ECS spawns into the lowest free slot and walks slots in order: reuse the first dead hole
  const hole = W.hazards.findIndex((x) => !x.alive);
  if (hole >= 0) W.hazards[hole] = h; else W.hazards.push(h);
  return h;
}
export function clearHazards(): void { for (const h of W.hazards) h.alive = false; W.hazards = []; }
/** The fighter a hazard of HZ's owner can hit (his opponent), or null. */
export const hazardTarget = (hz: Hazard): Ent | null => (hz.owner.alive ? hz.owner.f.opp : null);

/** Frames a South hand stays out: 8 rising to the grab, the 60 f hold, 24 crumbling. */
export const HAND_LIFE = 92;
/** A charred skeleton's arm (a look; the bind hazard is the hit) that claws out at (X Z) after DELAY frames. */
export const spawnHand = (owner: Ent, x: number, z: number, yaw: number, delay: number): Hazard =>
  spawnHazard('hand', owner, { x, z, yaw, size: 0.5, life: HAND_LIFE, delay: Math.max(0, delay) });

// ---------------------------------------------------------------- per step
export function hazardStep(hz: Hazard): void {
  if (hz.hook && callHook(hz.hook, hz, 'step')) return;
  if (hz.delay > 0) {
    hz.delay--;
    if (hz.delay === 0 && hz.kind === 'hand') emit('skeleton-rise', hz.x, hz.z);
    if (hz.delay === 0 && hz.kind === 'rift') emit('rift-cut', hz.owner, riftMidX(hz), riftMidZ(hz), hz.x, hz.z, hz.yaw);
    return;
  }
  hz.age++;
  if (hz.rehit > 0) hz.rehit--;
  hz.px = hz.x; hz.pz = hz.z;
  if (hz.kind === 'fireball') {                                      // home on the target
    const tg = hazardTarget(hz);
    if (tg && tg.alive) hz.yaw = angleWrap(turnToward(hz.yaw, dirYaw(f32(tg.pos[0] - hz.x), f32(tg.pos[2] - hz.z)), hz.turn));
  }
  if (hz.kind === 'wave' || hz.kind === 'fireball') {
    const d = f32(hz.speed * f32(STEP));                              // (singles, as the Lisp)
    hz.x += f32(d * fwdX(hz.yaw)); hz.z += f32(d * fwdZ(hz.yaw));
    if (hz.x ** 2 + hz.z ** 2 > (T.arenaRadius + 2.0) ** 2) hz.age = hz.life;
  }
  if (hz.age >= hz.life) hz.alive = false;
}
/** Move / age every hazard one fixed step. */
export function hazardSystem(): void {
  for (const hz of [...W.hazards]) if (hz.alive) hazardStep(hz);   // (dead ones stay as holes: slot order)
}

// ---------------------------------------------------------------- volumes
export function hazardActiveP(hz: Hazard): boolean {
  return !!hz.hw && hz.hitsLeft > 0 && hz.rehit <= 0 && hz.delay <= 0
    && (hz.kind !== 'pillars' || (T.pillarWindow[0] < hz.age && hz.age < hz.life - T.pillarWindow[1]));
}
/** Does HZ's world volume touch the hurt cylinder at (TX TY TZ), radius TR, height TH? */
export function hazardTouchesP(hz: Hazard, tx: number, ty: number, tz: number, tr: number, th: number): boolean {
  const x = hz.x, y = hz.y, z = hz.z, s = hz.size;
  switch (hz.kind) {
    case 'wave': return oboxCylHitP(x, 1, z, hz.yaw, s, T.waveBox[0], T.waveBox[1], tx, ty, tz, tr, th);
    case 'fireball': return capsuleCylHitP(hz.px, y, hz.pz, x, y, z, s, tx, ty, tz, tr, th);
    case 'pillars': {
      const [pr, ph] = T.pillarSize;
      for (let i = 0; i < T.ennetsuPillars; i++) {
        const a = f32(f32(i * f32(TWO_PI / T.ennetsuPillars)) + hz.yaw);   // (singles, musl's cosf / sinf: as the Lisp)
        if (cylCylHitP(f32(x + f32(s * cosf(a))), 0, f32(z + f32(s * sinf(a))), pr, ph, tx, ty, tz, tr, th)) return true;
      }
      return false;
    }
    case 'bind': case 'freeze': return cylCylHitP(x, 0, z, s, y, tx, ty, tz, tr, th);   // the feet: a disc SIZE x Y
    case 'rift': return volHitP(hz.hw!.vols[0], x, 0, z, fwdX(hz.yaw), fwdZ(hz.yaw), tx, ty, tz, tr, th, 0);
    default: return !!(hz.hook && callHook(hz.hook, hz, 'touches', tx, ty, tz, tr, th));
  }
}
export const riftMidX = (hz: Hazard): number => hz.x + 2.7 * fwdX(hz.yaw);
export const riftMidZ = (hz: Hazard): number => hz.z + 2.7 * fwdZ(hz.yaw);

/** E was hit: his rifts (and fragile hazards) that haven't cut yet close. */
export function closeRifts(e: Ent): void {
  for (const hz of W.hazards) {
    if (hz.alive && (hz.kind === 'rift' || hz.fragile) && hz.owner === e && hz.delay > 0) {
      emit('rift-close', riftMidX(hz), riftMidZ(hz));
      clog(() => `${sideName(e)} RIFT CLOSED`);
      if (hz.hook) callHook(hz.hook, hz, 'close');
      hz.alive = false;
    }
  }
}

/** Hand every active hazard's contact with its target to the hitSystem's pending list. */
export function collectHazardHits(): void {
  for (const hz of W.hazards) {
    if (!hz.alive || !hazardActiveP(hz)) continue;
    const tg = hazardTarget(hz);
    if (tg && tg.alive && hazardTouchesP(hz, tg.pos[0], tg.pos[1], tg.pos[2], tg.body.hurtR, tg.body.hurtH))
      W.pending.push({ att: hz.owner, def: tg, hw: hz.hw!, i: 0, sx: hz.src ? hz.owner.pos[0] : hz.x,
                       sz: hz.src ? hz.owner.pos[2] : hz.z, hazard: hz, state: defenderState(tg), red: false, mv: null,
                       bonus: 0, crush: false });
  }
}
/** HZ's hit took effect: one hit fewer (projectiles are spent), pillars wait before hitting again. */
export function hazardConnected(hz: Hazard): void {
  hz.hitsLeft--;
  hz.rehit = T.hazardRehit;
  if (hz.hitsLeft <= 0 && (hz.kind === 'wave' || hz.kind === 'fireball')) hz.life = hz.age;   // gone at the next step
}
/** Perfect Hoho vs hazards: one of OWNER's hazards is active (or becomes so within T.perfectLead frames) and touches
 *  VICTIM's hurt cylinder grown by T.perfectInflate. */
export function hazardThreatP(owner: Ent, victim: Ent): boolean {
  const q = victim.pos, b = victim.body;
  return W.hazards.some((hz) => hz.alive && hz.owner === owner && !!hz.hw && hz.hitsLeft > 0 && hz.delay <= T.perfectLead
    && hazardTouchesP(hz, q[0], q[1], q[2], b.hurtR + T.perfectInflate, b.hurtH + T.perfectInflate));
}
