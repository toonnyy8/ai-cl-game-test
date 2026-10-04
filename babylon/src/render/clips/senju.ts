// Senjumaru's clips (duel/lisp/senjumaru-art.lisp's :sj-* poses, redrawn in phase coordinates: u 0 start, 1 = frame S,
// 2 = end of active, 3 = end). The rig's arms are her upper pair of gold bone arms (the needle in the right); the echo
// arms ripple after them on their own (bodies/senju.ts). She glides on the okobo: short steps, the torso upright. Moves
// with no active frames (L, SP1, the weave) hold their S pose from u 1 to 2 (the phase jumps over it).
import type { Move } from '../../sim/kit';
import type { Fighter } from '../../sim/types';
import type { ClipName } from '../anim';
import type { Stance } from './index';
import { merge, mirror, type Clip, type PoseSpec } from '../pose';

const k = (at: number, pose: PoseSpec, ease?: 'in' | 'out' | 'io' | 'lin') => ({ at, pose, ease });
const legs: PoseSpec = { thighR: [3, 0, -2], shinR: [-5, 0, 0], footR: [2, 0, 0], thighL: [-2, 0, 2], shinL: [-4, 0, 0], footL: [2, 0, 0] };
const bend = (t: number, kn: number): PoseSpec => ({ thighR: [t, 0, -2], shinR: [-kn, 0, 0], thighL: [t * 0.6, 0, 2], shinL: [-kn, 0, 0] });

// ---------------------------------------------------------------- stances
/** The Shikai: upright, the needle raised at shoulder height, the free hand open aside, the clogs together. */
export const shikai = merge(legs, { pelvis: [0, 10, 0], spine: [2, 0, 0], chest: [0, -6, 0], neck: [0, -4, 0], head: [-4, -4, 0],
  armR: [62, 0, 24], foreR: [78, 0, 0], handR: [-30, -20, 0], armL: [30, 0, -46], foreL: [56, 0, 0], handL: [16, 0, 0], pos: [0, -0.01, 0] });
/** The Bankai: the arms spread wider, the upper pair raised as at a loom. */
export const loom = merge(legs, { spine: [2, 0, 0], head: [-2, 0, 0],
  armR: [70, 0, 58], foreR: [64, 0, 0], handR: [-10, -30, 0], armL: [70, 0, -58], foreL: [64, 0, 0], handL: [20, 30, 0], pos: [0, -0.01, 0] });
const weaveA = merge(loom, { chest: [0, 6, 0], head: [-12, 0, 0], armR: [70, 0, 40], foreR: [90, 0, 0], handR: [30, 0, 0],
  armL: [70, 0, -22], foreL: [90, 0, 0], handL: [30, 0, 0] });
const weaveB = merge(weaveA, { chest: [0, -6, 0], armR: [70, 0, 22], armL: [70, 0, -40] });

// ---------------------------------------------------------------- the Shikai's strings
// J1 HITOHARI: the upper right hand jabs the needle straight out
const q1Wind = merge(shikai, { chest: [0, -14, 0], armR: [60, 0, 10], foreR: [110, 0, 0], handR: [-20, 0, 0], pos: [0, -0.03, 0] });
const q1Hit = merge(shikai, bend(20, 14), { pelvis: [0, 18, 0], chest: [0, 16, 0], neck: [0, -12, 0], head: [0, -10, 0],
  armR: [82, 0, 4], foreR: [12, 0, 0], handR: [-20, 0, 0], armL: [20, 0, -60], foreL: [40, 0, 0], pos: [0, -0.05, -0.08] });
const Q1: Clip = [k(0, shikai), k(0.43, q1Wind, 'out'), k(1, q1Hit, 'out'), k(2, merge(q1Hit, { pos: [0, -0.05, -0.1] })),
  k(2.5, merge(shikai, { armR: [70, 0, 18], foreR: [60, 0, 0], handR: [-20, 0, 0], pos: [0, 0, -0.04] })), k(3, shikai)];
// J2 KAESHINUI: the backstitch: the needle drawn back across, from her left to her right
const q2Wind = merge(shikai, { chest: [0, 24, 0], head: [0, -16, 0], armR: [80, 0, -34], foreR: [70, 0, 0], handR: [-20, 30, 0], pos: [0, -0.03, 0] });
const q2Hit = merge(shikai, bend(16, 12), { pelvis: [0, -6, 0], chest: [0, -22, 0], head: [0, 12, 0], armR: [76, 0, 64], foreR: [12, 0, 0],
  handR: [-20, 0, 0], armL: [60, 0, -20], foreL: [50, 0, 0], handL: [-20, 0, 0], pos: [0, -0.05, -0.06] });
const Q2: Clip = [k(0, shikai), k(0.43, q2Wind, 'out'), k(1, q2Hit, 'out'), k(2, merge(q2Hit, { armR: [72, 0, 72] })),
  k(2.6, merge(shikai, { chest: [0, -6, 0], armR: [50, 0, 40], foreR: [50, 0, 0] })), k(3, shikai)];
// J3 SENJU (and NUICHI's strike): every hand fans out and she whirls in a ring of needles, the clogs planted
const fan = { armR: [40, 0, 62], foreR: [62, 0, 0], handR: [-20, 0, 0], armL: [40, 0, -62], foreL: [62, 0, 0], handL: [-20, 0, 0] } as PoseSpec;
const spinWind = merge(shikai, { pelvis: [0, -20, 0], chest: [0, -30, 0], armR: [10, 0, 80], foreR: [10, 0, 0], handR: [-20, 0, 0],
  armL: [10, 0, -80], foreL: [10, 0, 0], handL: [-20, 0, 0], pos: [0, -0.04, 0] });
const spinAt = (yaw: number) => merge(shikai, fan, { pelvis: [0, yaw, 0], chest: [0, 10, 0], pos: [0, -0.03, -0.04] });
const SPIN: Clip = [k(0, shikai), k(0.5, spinWind, 'out'), k(0.75, merge(spinWind, { pelvis: [0, -30, 0], chest: [0, -36, 0] })),
  k(1, spinAt(90), 'in'), k(1.4, spinAt(200), 'lin'), k(1.75, spinAt(300), 'lin'), k(2, spinAt(370), 'out'),
  k(2.4, merge(shikai, { pelvis: [0, 370, 0], armR: [50, 0, 50], foreR: [40, 0, 0], armL: [60, 0, -30], foreL: [50, 0, 0], pos: [0, -0.02, -0.06] })),
  k(3, shikai)];
// K1 MACHIBARI: both upper hands draw long pins back past the hips and drive them straight out
const f1Back = merge(shikai, bend(20, 20), { chest: [0, -4, 0], armR: [-24, 0, 16], foreR: [70, 0, 0], handR: [-20, 0, 0],
  armL: [-26, 0, -18], foreL: [70, 0, 0], handL: [-20, 0, 0], pos: [0, -0.07, 0.07] });
const f1Hit = merge(shikai, { pelvis: [0, 6, 0], spine: [-10, 0, 0], chest: [0, 4, 0], head: [6, 0, 0], armR: [96, 0, 6], foreR: [0, 0, 0],
  handR: [-20, 0, 0], armL: [94, 0, -8], foreL: [0, 0, 0], handL: [-20, 0, 0], thighR: [34, 0, -2], shinR: [-34, 0, 0],
  thighL: [-16, 0, 2], shinL: [-10, 0, 0], pos: [0, -0.1, -0.34] });
const F1: Clip = [k(0, shikai), k(0.41, f1Back, 'out'), k(0.82, merge(f1Back, { armR: [-30, 0, 16], armL: [-32, 0, -18], pos: [0, -0.08, 0.08] })),
  k(1, f1Hit, 'out'), k(2, merge(f1Hit, { pos: [0, -0.1, -0.36] })),
  k(2.55, merge(shikai, { armR: [70, 0, 20], foreR: [50, 0, 0], armL: [50, 0, -30], foreL: [50, 0, 0], pos: [0, -0.05, -0.16] })), k(3, shikai)];
// K2 MATSURI: the hem stitch: crouched and turned away, then a rising loop of thread whipped up and over him
const f2Low = merge(shikai, bend(20, 40), { pelvis: [0, -60, 0], spine: [-22, 0, 0], chest: [0, -12, 0], armR: [-10, 0, 30],
  foreR: [20, 0, 0], armL: [-10, 0, -40], foreL: [30, 0, 0], pos: [0, -0.12, 0] });
const f2Hit = merge(shikai, { pelvis: [0, 0, 0], spine: [8, 0, 0], chest: [0, 10, 0], head: [14, 0, 0], armR: [150, 0, 20], foreR: [10, 0, 0],
  handR: [-20, 0, 0], armL: [120, 0, -40], foreL: [20, 0, 0], handL: [-20, 0, 0], pos: [0, 0.02, -0.14] });
const F2: Clip = [k(0, shikai), k(0.48, f2Low, 'out'), k(0.86, merge(f2Low, { pelvis: [0, -70, 0], spine: [-26, 0, 0], pos: [0, -0.14, 0] })),
  k(1, f2Hit, 'out'), k(1.5, merge(f2Hit, { armR: [156, 0, 20] })), k(2, merge(f2Hit, { armR: [154, 0, 20] })),
  k(2.55, merge(shikai, { spine: [-2, 0, 0], armR: [80, 0, 24], foreR: [60, 0, 0], armL: [50, 0, -40], foreL: [50, 0, 0], pos: [0, -0.02, -0.08] })),
  k(3, shikai)];
// K3 KUKE: the blind stitch: every hand raised high, then slammed down round his feet, held 3 f
const dropUp = merge(shikai, { spine: [12, 0, 0], head: [24, 0, 0], armR: [170, 0, 20], foreR: [20, 0, 0], armL: [170, 0, -20], foreL: [20, 0, 0],
  pos: [0, 0.03, 0] });
const dropHit = merge(shikai, { spine: [-38, 0, 0], chest: [-6, 0, 0], head: [18, 0, 0], armR: [70, 0, 10], foreR: [0, 0, 0], handR: [-20, 0, 0],
  armL: [70, 0, -10], foreL: [0, 0, 0], handL: [-20, 0, 0], thighR: [50, 0, -2], shinR: [-70, 0, 0], thighL: [30, 0, 2], shinL: [-60, 0, 0],
  pos: [0, -0.28, -0.3] });
const DROP: Clip = [k(0, shikai), k(0.38, dropUp, 'out'), k(0.81, merge(dropUp, { spine: [15, 0, 0], armR: [176, 0, 20], armL: [176, 0, -20] })),
  k(1, dropHit, 'in'), k(1.6, dropHit), k(2, merge(dropHit, { spine: [-40, 0, 0], pos: [0, -0.29, -0.3] })),
  k(2.6, merge(dropHit, { spine: [-30, 0, 0], pos: [0, -0.22, -0.26] })),
  k(2.82, merge(shikai, bend(20, 20), { spine: [-10, 0, 0], armR: [60, 0, 20], foreR: [50, 0, 0], armL: [40, 0, -30], foreL: [50, 0, 0],
    pos: [0, -0.08, -0.12] })), k(3, shikai)];

// ---------------------------------------------------------------- the Shikai's specials
// L WARUI KUSE: the upper hands grip the threads and yank them back over her shoulder
const yankHold = merge(shikai, { armR: [90, 0, 10], foreR: [10, 0, 0], handR: [-20, 0, 0], armL: [90, 0, -10], foreL: [10, 0, 0] });
const yank = merge(shikai, { spine: [10, 0, 0], chest: [0, -20, 0], head: [6, 10, 0], armR: [150, 0, 30], foreR: [120, 0, 0], handR: [40, 0, 0],
  armL: [140, 0, -30], foreL: [120, 0, 0], handL: [40, 0, 0], pos: [0, -0.02, 0.1] });
const YANK: Clip = [k(0, yankHold), k(0.62, merge(yankHold, { chest: [0, 6, 0], armR: [96, 0, 10], armL: [96, 0, -10] })),
  k(1, yank, 'out'), k(2, yank), k(2.5, merge(yank, { spine: [8, 0, 0], armR: [146, 0, 30], armL: [136, 0, -30] })), k(3, shikai)];
// SP1 SHINPEI: the hands part an unseen tapestry to the sides; the upper pair beckons the soldier forward
const part = merge(shikai, { chest: [0, 0, 0], head: [0, 0, 0], armR: [30, 0, 70], foreR: [20, 0, 0], handR: [10, 0, 0],
  armL: [30, 0, -70], foreL: [20, 0, 0] });
const beckon = merge(shikai, { head: [4, 0, 0], armR: [100, 0, 10], foreR: [20, 0, 0], handR: [-20, 0, 0], armL: [70, 0, -60], foreL: [10, 0, 0],
  pos: [0, -0.01, -0.05] });
const SUMMON: Clip = [k(0, shikai), k(0.5, part), k(1, beckon, 'out'), k(2, beckon), k(2.6, merge(beckon, { armR: [90, 0, 10], armL: [70, 0, -64] })),
  k(3, shikai)];
// SP2 KASA: the arms open like ribs, the canopy snapping taut over her; then it inverts and the threads lash out
const kasaOpen = merge(shikai, { spine: [4, 0, 0], head: [8, 0, 0], armR: [150, 0, 50], foreR: [10, 0, 0], handR: [30, 0, 0],
  armL: [150, 0, -50], foreL: [10, 0, 0], handL: [30, 0, 0], pos: [0, -0.03, 0] });
const lash = merge(shikai, { spine: [-12, 0, 0], armR: [90, 0, 20], foreR: [0, 0, 0], handR: [-20, 0, 0], armL: [90, 0, -20], foreL: [0, 0, 0],
  handL: [-20, 0, 0], pos: [0, -0.02, -0.12] });
const KASA: Clip = [k(0, shikai), k(1, kasaOpen, 'out'), k(1.5, merge(kasaOpen, { pos: [0, -0.04, 0] })), k(1.95, kasaOpen), k(2, lash, 'out'),
  k(2.67, merge(shikai, { spine: [-4, 0, 0], armR: [70, 0, 24], foreR: [50, 0, 0], armL: [50, 0, -36], foreL: [50, 0, 0] })), k(3, shikai)];
// I SAIDAN: the strike after the dash: two upper hands close like shears on his guard
const shearsOpen = merge(shikai, { armR: [90, 0, 60], foreR: [10, 0, 0], armL: [90, 0, -60], foreL: [10, 0, 0], pos: [0, -0.06, 0] });
const shut = merge(shikai, { spine: [-10, 0, 0], armR: [92, 0, -6], foreR: [0, 0, 0], handR: [-20, 0, 0], armL: [92, 0, 6], foreL: [0, 0, 0],
  handL: [-20, 0, 0], pos: [0, -0.08, -0.14] });
const SAIDAN: Clip = [k(0, shearsOpen), k(0.62, merge(shearsOpen, { armR: [90, 0, 70], armL: [90, 0, -70] })), k(1, shut, 'out'),
  k(2, merge(shut, { pos: [0, -0.08, -0.16] })),
  k(2.67, merge(shikai, { armR: [70, 0, 20], foreR: [50, 0, 0], armL: [40, 0, -40], foreL: [50, 0, 0], pos: [0, -0.02, -0.07] })), k(3, shikai)];

// ---------------------------------------------------------------- the Bankai (the loom)
const WEAVE: Clip = [k(0, weaveA), k(0.5, weaveB), k(1, weaveA), k(2, weaveA), k(3, loom)];       // HITOKOSHI
const STOP: Clip = [k(0, weaveA), k(3, loom)];                                                  // the weave let go
// the release: the upper pair flings the bolt out; it unrolls where it lands
const fling = merge(loom, { spine: [-6, 0, 0], armR: [110, 0, 10], foreR: [0, 0, 0], handR: [-20, 0, 0], armL: [110, 0, -10], foreL: [0, 0, 0],
  handL: [-20, 0, 0], pos: [0, -0.01, -0.1] });
const UNRAVEL: Clip = [k(0, weaveA), k(0.5, merge(loom, { armR: [40, 0, 20], foreR: [100, 0, 0], armL: [40, 0, -20], foreL: [100, 0, 0] })),
  k(1, fling, 'out'), k(2, fling), k(2.45, merge(fling, { armR: [100, 0, 10], armL: [100, 0, -10] })), k(3, loom)];
// K1 TANMONO-UCHI: a bolt of cloth flung straight out from two hands
const tanHit = merge(loom, bend(26, 26), { spine: [-8, 0, 0], armR: [94, 0, 8], foreR: [0, 0, 0], handR: [-20, 0, 0], armL: [94, 0, -8],
  foreL: [0, 0, 0], handL: [-20, 0, 0], pos: [0, -0.08, -0.3] });
const tanBack = merge(loom, { armR: [30, 0, 30], foreR: [110, 0, 0], armL: [30, 0, -30], foreL: [110, 0, 0], pos: [0, -0.05, 0] });
const TANMONO: Clip = [k(0, loom), k(0.47, tanBack, 'out'), k(0.82, merge(tanBack, { armR: [20, 0, 30], armL: [20, 0, -30], pos: [0, -0.05, 0.06] })),
  k(1, tanHit, 'out'), k(2, merge(tanHit, { pos: [0, -0.08, -0.32] })),
  k(2.45, merge(loom, { armR: [60, 0, 30], foreR: [60, 0, 0], armL: [60, 0, -30], foreL: [60, 0, 0], pos: [0, -0.02, -0.12] })), k(3, loom)];
// K3 MAKITORI: the cloth thrown at his feet, then hauled in hand over hand as it wraps him
const reach = merge(loom, { armR: [90, 0, 6], foreR: [0, 0, 0], handR: [-20, 0, 0], armL: [90, 0, -6], foreL: [0, 0, 0], pos: [0, -0.02, -0.12] });
const haul = merge(loom, bend(20, 30), { spine: [6, 0, 0], armR: [60, 0, 10], foreR: [110, 0, 0], handR: [40, 0, 0], armL: [60, 0, -10],
  foreL: [110, 0, 0], handL: [40, 0, 0], thighL: [36, 0, 2], pos: [0, -0.12, 0.1] });
const MAKITORI: Clip = [k(0, loom), k(0.48, reach, 'out'), k(0.86, merge(reach, { armR: [94, 0, 6], armL: [94, 0, -6], pos: [0, -0.02, -0.14] })),
  k(1, haul, 'out'), k(2, merge(haul, { pos: [0, -0.12, 0.12] })),
  k(2.7, merge(loom, { armR: [70, 0, 40], foreR: [70, 0, 0], armL: [70, 0, -40], foreL: [70, 0, 0], pos: [0, -0.04, 0] })), k(3, loom)];
// SP1 TACHINAOSHI: two upper hands close great shears in the air over her head
const snipOpen = merge(loom, { armR: [140, 0, 50], foreR: [10, 0, 0], armL: [140, 0, -50], foreL: [10, 0, 0] });
const snip = merge(snipOpen, { head: [10, 0, 0], armR: [140, 0, 0], armL: [140, 0, 0] });
const SNIP: Clip = [k(0, snipOpen), k(0.67, merge(snipOpen, { armR: [140, 0, 60], armL: [140, 0, -60] })), k(1, snip, 'out'), k(2, snip),
  k(2.4, merge(loom, { armR: [120, 0, 10], foreR: [10, 0, 0], armL: [120, 0, -10], foreL: [10, 0, 0] })), k(3, loom)];

// ---------------------------------------------------------------- the table and the generic states
const TABLE: Record<string, Clip> = {
  'sj-q1': Q1, 'sj-q2': Q2, 'sj-spin': SPIN, 'sj-f1': F1, 'sj-f2': F2, 'sj-drop': DROP, 'sj-yank': YANK, 'sj-summon': SUMMON,
  'sj-kasa': KASA, 'sj-saidan': SAIDAN, 'sj-weave': WEAVE, 'sj-loom-shikai': STOP, 'sj-unravel': UNRAVEL, 'sj-tanmono': TANMONO,
  'sj-makitori': MAKITORI, 'sj-snip': SNIP,
};
/** Her bespoke clip for MV (by its art clip), or null. */
export const clipOf = (mv: Move): Clip | null => TABLE[(mv.clip2 && mv.kind !== 'sp' ? mv.clip2 : mv.clip) ?? ''] ?? null;
export function clipFor(_c: string, _mv: Move): ClipName | null { return null; }
export const idle = shikai;
export const idleFor = (form: string): PoseSpec => (form === 'base' ? shikai : loom);

const guard = merge(legs, bend(10, 12), { spine: [-4, 0, 0], head: [-6, 0, 0], armR: [80, 0, -24], foreR: [80, 0, 0], handR: [20, 0, 0],
  armL: [80, 0, 24], foreL: [80, 0, 0], handL: [20, 0, 0], pos: [0, -0.03, 0] });
// gliding on the okobo: short steps, the robe barely moving, the torso upright; the run leans with the arms trailing
const walkA: PoseSpec = { pelvis: [0, -4, 0], thighR: [14, 0, -2], shinR: [-6, 0, 0], thighL: [-10, 0, 2], shinL: [-14, 0, 0], footL: [10, 0, 0],
  pos: [0, -0.01, 0] };
const walkB: PoseSpec = { pelvis: [0, 0, 0], thighR: [0, 0, -2], shinR: [-6, 0, 0], thighL: [10, 0, 2], shinL: [-24, 0, 0], footL: [6, 0, 0], pos: [0, 0, 0] };
const runA: PoseSpec = { spine: [-10, 0, 0], chest: [0, -4, 0], head: [8, 0, 0], thighR: [26, 0, -2], shinR: [-20, 0, 0], thighL: [-16, 0, 2],
  shinL: [-40, 0, 0], footL: [16, 0, 0], armR: [-35, 0, 30], foreR: [30, 0, 0], handR: [10, 0, 0], armL: [-35, 0, -30], foreL: [30, 0, 0],
  handL: [10, 0, 0], pos: [0, -0.04, 0] };
/** CharClips.poses: her library overrides in every form (the generic walk / run clips are built from walkA / B, runA). */
export const poses = {
  guard, guardHit: merge(guard, { spine: [6, 0, 0], head: [4, 0, 0], pos: [0, -0.03, 0.05] }),
  step: merge(shikai, { spine: [-6, 0, 0], armR: [-10, 0, 30], foreR: [30, 0, 0], armL: [-10, 0, -30], foreL: [30, 0, 0], pos: [0, -0.03, 0] }),
  // the Breaker / NUICHI dash: low on the clogs, the arms folded back
  dash: merge(bend(30, 30), { spine: [-30, 0, 0], head: [24, 0, 0], armR: [-40, 0, 30], foreR: [30, 0, 0], armL: [-40, 0, -30], foreL: [30, 0, 0],
    thighL: [-20, 0, 2], pos: [0, -0.1, 0] }),
  walkA, walkB, runA,
};
// the weave (L held, every aura phase): the hands work in a ripple, a pass per 20 f
const WEAVE_HOLD: Clip = [k(0, weaveA), k(0.5, weaveB), k(1, weaveA)];

// ---------------------------------------------------------------- CharClips
const STANCES = new Map<string, Stance>();
export function stance(form: string): Stance {      // (cached per form: anim.ts's clip cache keys on the idle)
  let s = STANCES.get(form);
  if (!s) { s = { idle: idleFor(form) }; STANCES.set(form, s); }
  return s;
}
/** CharClips.move: the weave (a 20 f loop of the hands) in every hold / aura phase, her clip in the main phase. */
export function move(mv: Move, f: Fighter): Clip | [Clip, number] | null {
  if (f.phase === 'hold' || f.phase === 'aura') return [WEAVE_HOLD, ((f.sf % 20) / 20) * WEAVE_HOLD[WEAVE_HOLD.length - 1].at];
  if (f.phase === 'dash' || f.phase === 'follow') return null;
  return clipOf(mv);
}
