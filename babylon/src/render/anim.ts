// anim.ts: which pose a fighter shows this frame. Moves sample their clip in phase coordinates from the fighter's sf
// (pose.ts phase: u = 1 on frame S, 2 at the end of the active frames; multi-hit moves key each window), so the hit
// pose lands on the hit frames and hit-stop holds it for free (sf does not advance). Locomotion cycles run on real
// time scaled by the speed. One cross-fade (per-bone slerp from the last shown pose) when the clip changes.
import { Quaternion, Vector3 } from '@babylonjs/core';
import type { Move } from '../sim/kit';
import type { Ent } from '../sim/types';
import { BONES, P, merge, mirror, phase, sampleKeys, type BoneName, type Clip, type PoseSpec } from './pose';
import { FACE, type BuiltBody } from './body';
import { CLIPS } from './clips';

const D2R = Math.PI / 180;
const cache = new WeakMap<PoseSpec, Map<string, Quaternion>>();
function quats(p: PoseSpec): Map<string, Quaternion> {
  let m = cache.get(p);
  if (!m) {
    m = new Map();
    for (const [k, v] of Object.entries(p)) if (k !== 'pos') m.set(k, Quaternion.RotationYawPitchRoll(v[1] * D2R, v[0] * D2R, v[2] * D2R));
    cache.set(p, m);
  }
  return m;
}
const ID = Quaternion.Identity();

// ---------------------------------------------------------------- clips (built per stance)
const k = (at: number, pose: PoseSpec, ease?: 'in' | 'out' | 'io' | 'lin') => ({ at, pose, ease });
function clips(idle: PoseSpec) {
  return {
    slash: [k(0, idle), k(0.85, P.slashWind, 'out'), k(1, P.slashHit, 'in'), k(2, P.slashEnd, 'out'), k(3, idle)],
    backhand: [k(0, idle), k(0.85, P.slashEnd, 'out'), k(1, P.slashHit, 'in'), k(2, P.slashWind, 'out'), k(3, idle)],
    sleeve: [k(0, idle), k(0.85, mirror(P.slashWind), 'out'), k(1, mirror(P.slashHit), 'in'), k(2, mirror(P.slashEnd), 'out'), k(3, idle)],
    heavy: [k(0, idle), k(0.8, P.heavyWind, 'out'), k(1, P.heavyHit, 'in'), k(2, P.heavyEnd, 'out'), k(3, idle)],
    leap: [k(0, idle), k(0.6, merge(P.heavyWind, { pos: [0, 0.7, 0] }), 'out'), k(1, P.heavyHit, 'in'), k(2, P.heavyEnd), k(3, idle)],
    rise: [k(0, idle), k(0.85, P.riseWind, 'out'), k(1, P.heavyHit, 'in'), k(2, P.riseHit, 'out'), k(3, idle)],
    thrust: [k(0, idle), k(0.85, P.thrustWind, 'out'), k(1, P.thrustHit, 'out'), k(2, P.thrustHit), k(3, idle)],
    kick: [k(0, idle), k(0.8, P.kickWind, 'out'), k(1, P.kickHit, 'out'), k(2, P.kickHit), k(3, idle)],
    spin: [k(0, idle), k(0.9, P.spinWind, 'out'), k(2, P.spinWind), k(3, idle)],
    palm: [k(0, idle), k(0.8, P.hold, 'out'), k(1, P.palm, 'out'), k(2, P.palm), k(3, idle)],
    shoulder: [k(0, idle), k(0.8, P.dash, 'out'), k(1, P.shoulder, 'out'), k(2, P.shoulder), k(3, idle)],
    // multi-hit, in w (per window): alternate fore- and backhand, each starting where the last ended
    multiA: [k(0, P.slashWind), k(0.8, P.slashWind), k(1, P.slashHit, 'in'), k(2, P.slashEnd, 'out'), k(3, idle)],
    multiB: [k(0, P.slashEnd), k(0.8, P.slashEnd), k(1, P.slashHit, 'in'), k(2, P.slashWind, 'out'), k(3, idle)],
    multi0: [k(0, idle), k(0.8, P.slashWind, 'out'), k(1, P.slashHit, 'in'), k(2, P.slashEnd, 'out'), k(3, idle)],
    react: (p: PoseSpec): Clip => [k(0, idle), k(0.12, p, 'out'), k(0.6, p), k(1, idle)],
    wakeup: [k(0, P.down), k(0.5, P.kneel), k(1, idle)],
  };
}
type Clips = ReturnType<typeof clips>;
export type ClipName = keyof Clips;
const idleOf = (who: string) => CLIPS[who]?.idle ?? P.idleKen;
const CACHE = new Map<string, Clips>();
const clipsFor = (who: string) => { let c = CACHE.get(who); if (!c) { c = clips(idleOf(who)); CACHE.set(who, c); } return c; };

/** The clip for a move's main phase: WHO's table (render/clips/<who>.ts) first, else the generic mapping. */
export function clipNameFor(who: string, mv: Move): ClipName {
  const c = (mv.clip2 && mv.kind !== 'sp' ? mv.clip2 : mv.clip) ?? '';
  return CLIPS[who]?.clipFor(c, mv) ?? moveClipName(mv);
}
/** The generic mapping from a move's clip name (the art contract) and kind; unknown moves slash on their frames. */
export function moveClipName(mv: Move): ClipName {
  const c = (mv.clip2 && mv.kind !== 'sp' ? mv.clip2 : mv.clip) ?? '';
  if (mv.hits.length > 1) return 'multi0';
  if (c.includes('kick')) return 'kick';
  if (c.endsWith('q2')) return 'backhand';
  if (c.includes('sleeve')) return 'sleeve';
  if (c.endsWith('q3')) return 'heavy';
  if (c.endsWith('f2')) return 'rise';
  if (c.endsWith('f1')) return 'slash';
  return mv.kind === 'flash' ? 'heavy' : 'slash';
}

// ---------------------------------------------------------------- the animator
export class Animator {
  out = new Map<BoneName, Quaternion>(BONES.map((b) => [b, Quaternion.Identity()]));
  pos = new Vector3();
  from = new Map<BoneName, Quaternion>(BONES.map((b) => [b, Quaternion.Identity()]));
  fromPos = new Vector3();
  key = ''; fade = 1; fadeLen = 0.1;
  cycle = 0;              // locomotion phase (0..1 a stride pair)
  face: number = FACE.neutral;
  flash = 0;
  private tq = new Quaternion();
  constructor(public body: BuiltBody, readonly who: string) {}   // (body: swapped on a form change)

  update(e: Ent, rdt: number, t: number): void {
    const f = e.f, C = clipsFor(this.who), idle = idleOf(this.who);
    let key: string = f.state, a: PoseSpec = idle, b: PoseSpec = idle, x = 0, spin = 0;
    const kb = (c: Clip, at: number) => { [a, b, x] = sampleKeys(c, at); };
    this.face = FACE.neutral; this.flash = 0;
    switch (f.state) {
      case 'idle': case 'intro': case 'cine': {
        const clip = e.look.clip ?? '', sp = Math.hypot(e.mo.vel[0], e.mo.vel[2]);
        if (f.state === 'idle' && sp > 0.1 && /walk|strafe/.test(clip)) {
          key = 'walk';
          this.cycle = (this.cycle + (rdt * sp) / (1.3 * this.body.spec.height) * (clip.endsWith('-b') ? -1 : 1) + 1) % 1;
          kb(WALK, this.cycle * 4);
        } else { const br = Math.sin(t * 2.2) * 2; a = b = merge(idle, { chest: [(idle.chest?.[0] ?? 0) + br, idle.chest?.[1] ?? 0, idle.chest?.[2] ?? 0] }); }
        break;
      }
      case 'guard': a = b = P.guard; break;
      case 'guard-hit': kb([k(0, P.guard), k(0.25, P.guardHit, 'out'), k(1, P.guard)], f.sf / Math.max(1, f.stun)); break;
      case 'step': a = b = P.step; break;
      case 'run': {
        const sp = Math.hypot(e.mo.vel[0], e.mo.vel[2]);
        if (f.phase === 'brake' || sp < 0.5) { key = 'brake'; a = b = P.step; break; }
        this.cycle = (this.cycle + (rdt * sp) / (2.4 * this.body.spec.height)) % 1;
        kb(RUN, this.cycle * 2);
        break;
      }
      case 'hoho': a = b = P.hoho; break;
      case 'move': {
        const mv = f.move!;
        key = `move:${mv.name}:${f.phase}`;
        if (f.phase === 'hold' || f.phase === 'aura') { a = b = P.hold; this.face = FACE.shout; break; }
        if (f.phase === 'dash' || f.phase === 'follow') { a = b = P.dash; this.face = FACE.shout; break; }
        const name = clipNameFor(this.who, mv), ph = phase(mv, f.sf);
        if (name === 'multi0') kb(ph.i === 0 ? C.multi0 : ph.i % 2 ? C.multiB : C.multiA, ph.w);
        else kb(C[name] as Clip, ph.u);
        if (name === 'spin' && ph.u > 1) spin = 360 * Math.min(1, ph.u - 1);
        if (ph.u > 0.8 && ph.u < 2.2 || mv.kind === 'sp' || mv.kind === 'kikon') this.face = FACE.shout;
        break;
      }
      case 'stun': {
        const react = f.phase ?? 'flinch';
        key = `stun:${react}`;
        const p = react === 'knockback' ? P.knockback : react === 'crumple' ? P.crumple
          : react === 'stagger' || react === 'guard-break' ? P.stagger : P.flinch;
        kb(react === 'crumple' ? [k(0, P.flinch), k(0.25, P.crumple, 'out'), k(0.8, P.crumple), k(1, idle)] : C.react(p), f.sf / Math.max(1, f.stun));
        this.face = FACE.hurt;
        this.flash = f.sf < 4 ? 0.7 * (1 - f.sf / 4) : 0;
        break;
      }
      case 'air': a = b = P.air; this.face = FACE.hurt; this.flash = f.sf < 4 ? 0.7 * (1 - f.sf / 4) : 0; break;
      case 'down': a = b = P.down; this.face = FACE.hurt; break;
      case 'wakeup': kb(C.wakeup, f.sf / 30); break;
      case 'win': a = b = P.win; break;
      case 'lose': a = b = P.kneel; this.face = FACE.hurt; break;
    }
    if (key !== this.key) {                     // the cross-fade starts from whatever was shown
      for (const bn of BONES) this.from.get(bn)!.copyFrom(this.out.get(bn)!);
      this.fromPos.copyFrom(this.pos);
      this.key = key; this.fade = 0;
      this.fadeLen = f.state === 'move' && f.move && f.move.blend > 0 ? f.move.blend / 60 : f.state === 'stun' ? 0.05 : 0.1;
    }
    this.fade = Math.min(1, this.fade + rdt / this.fadeLen);
    const qa = quats(a), qb = quats(b), fk = this.fade;
    for (const bn of BONES) {
      const o = this.out.get(bn)!;
      Quaternion.SlerpToRef(qa.get(bn) ?? quats(idle).get(bn) ?? ID, qb.get(bn) ?? quats(idle).get(bn) ?? ID, x, this.tq);
      if (bn === 'pelvis' && spin) this.tq.multiplyInPlace(Quaternion.RotationYawPitchRoll(spin * D2R, 0, 0));
      Quaternion.SlerpToRef(this.from.get(bn)!, this.tq, fk, o);
    }
    const pa = a.pos ?? idle.pos ?? [0, 0, 0], pb = b.pos ?? idle.pos ?? [0, 0, 0], s = this.body.spec.height / 1.8;
    const px = (pa[0] + (pb[0] - pa[0]) * x) * s, py = (pa[1] + (pb[1] - pa[1]) * x) * s, pz = (pa[2] + (pb[2] - pa[2]) * x) * s;
    this.pos.set(this.fromPos.x + (px - this.fromPos.x) * fk, this.fromPos.y + (py - this.fromPos.y) * fk, this.fromPos.z + (pz - this.fromPos.z) * fk);
    this.apply();
  }

  /** Write the pose into the skeleton (rest offsets + the pelvis offset; rotations replace the rest identity). */
  apply(): void {
    const { bones, rig } = this.body;
    for (const bn of BONES) bones[bn].setRotationQuaternion(this.out.get(bn)!);
    bones.pelvis.position = rig.rest.pelvis.add(this.pos);
  }
}
const WALK: Clip = [k(0, merge(P.walkA)), k(1, P.walkB), k(2, mirror(P.walkA)), k(3, mirror(P.walkB)), k(4, P.walkA)];
const RUN: Clip = [k(0, P.runA), k(1, mirror(P.runA)), k(2, P.runA)];
