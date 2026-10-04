// Ichigo's clips (docs/DUEL_ICHIGO.md §3-4, v2; the Lisp's ichigo-art.lisp poses as the intent): the Shikai's dual
// stance (the cleaver low and back in the right hand, the short blade reversed along the left forearm), KESSA's upright
// stance with the Tensa low; bespoke clips in phase u (0 start, 1 frame S, 2 end of active, 3 end) for every move of
// both forms: the dual-blade J / K strings, the cross, Getsuga, JUJISHO's two cuts, the stance TSUKIMACHI and its four
// branches, SOGA, MINEUCHI, the Kikons' strikes; KESSA's cuts, the parry, ZANGETSU-GAESHI, KUSARI-BIKI's pull, ZANZO.
// The clones (ic-c-*) swing KESSA's clips.
import type { Move } from '../../sim/kit';
import type { Fighter } from '../../sim/types';
import type { ClipName } from '../anim';
import { P, merge, mirror, type Clip, type Key, type PoseSpec } from '../pose';

const k = (at: number, pose: PoseSpec, ease?: Key['ease']): Key => ({ at, pose, ease });

// ---------------------------------------------------------------- stances
// legs: his left foot leads (the side-on dual stance), weight sunk
const legsL: PoseSpec = { thighL: [30, 8, -6], shinL: [-40, 0, 0], footL: [10, 0, 0], thighR: [-6, -12, 8], shinR: [-28, 0, 0],
  footR: [26, 0, 0], pos: [0, -0.08, 0] };
const legsR: PoseSpec = { thighR: [30, -8, 6], shinR: [-40, 0, 0], footR: [10, 0, 0], thighL: [-6, 12, -8], shinL: [-28, 0, 0],
  footL: [26, 0, 0], pos: [0, -0.08, 0] };
const lunge: PoseSpec = { thighR: [62, -6, 6], shinR: [-66, 0, 0], footR: [6, 0, 0], thighL: [-30, 10, -8], shinL: [-14, 0, 0],
  footL: [20, 0, 0], pos: [0, -0.2, -0.32] };
const lungeL: PoseSpec = mirror(lunge);

export const S = {
  // Shikai: left side leading, the cleaver low and back, the short blade reversed along the raised left forearm
  idle: merge(legsL, { pelvis: [0, -22, 0], spine: [-6, 0, 0], chest: [-4, -8, 0], neck: [4, 12, 0], head: [4, 14, 0],
    armR: [7, 38, 20], foreR: [53, 0, 0], handR: [-125, -6, 8], armL: [13, -1, -37], foreL: [117, 0, 0], handL: [-21, -1, 44] }),
  guard: merge(legsL, { pelvis: [0, -10, 0], spine: [-6, 0, 0], chest: [-6, -4, 0], head: [6, 8, 0],
    armR: [30, 46, 45], foreR: [80, 0, 0], handR: [34, -4, 13], armL: [31, -23, -15], foreL: [76, 0, 0], handL: [-31, -4, 59], pos: [0, -0.1, 0] }),
  run: merge(P.runA, { spine: [-26, 0, 0], armR: [-25, 3, 12], foreR: [29, 0, 0], handR: [-61, 10, -2], armL: [-55, 0, -22], foreL: [40, 0, 0] }),
  // KESSA: upright and still, the Tensa low at his right side angled to the ground ahead, the left hand open
  kIdle: merge(legsR, { thighR: [10, -6, 6], shinR: [-14, 0, 0], thighL: [-4, 8, -8], shinL: [-12, 0, 0], footL: [10, 0, 0],
    pelvis: [0, -10, 0], spine: [-2, 0, 0], chest: [0, -4, 0], head: [4, 8, 0], armR: [13, 6, 10], foreR: [17, 0, 0], handR: [12, -2, -4],
    armL: [6, 0, -14], foreL: [24, 0, 0], pos: [0, -0.03, 0] }),
  kGuard: merge(legsR, { pelvis: [0, -6, 0], spine: [-6, 0, 0], chest: [-4, -4, 0], head: [6, 0, 0],
    armR: [18, 46, 59], foreR: [64, 0, 0], handR: [-11, 91, 81], armL: [62, 8, -11], foreL: [80, 0, 0], handL: [-132, 10, 0], pos: [0, -0.1, 0] }),
  kRun: merge(P.runA, { spine: [-22, 0, 0], armR: [-55, 0, 18], foreR: [20, 0, 0], handR: [-50, 0, 0] }),
};

// ---------------------------------------------------------------- Shikai key poses
export const Q = {
  // the short blade (left): J1 flicked across left-to-right in front, J2 the wrist turned back across
  q1Wind: merge(legsL, { pelvis: [0, -40, 0], chest: [-4, -20, 0], head: [0, 40, 0], armL: [44, -41, -6], foreL: [89, 0, 0], handL: [-109, -47, -7],
    armR: [-25, 0, 25], foreR: [25, 0, 0], handR: [-85, 0, 0] }),
  q1Hit: merge(lungeL, { pelvis: [0, -5, 0], spine: [-8, 0, 0], chest: [-6, 15, 0], head: [6, -10, 0], armL: [41, 23, -38], foreL: [122, 0, 0],
    handL: [-34, 50, -22], armR: [-35, 0, 28], foreR: [20, 0, 0], handR: [-85, 0, 0] }),
  q1End: merge(lungeL, { handL: [-7, 3, 29], pelvis: [0, 5, 0], chest: [-6, 25, 0], head: [6, -20, 0], armL: [35, 38, -29], foreL: [96, 0, 0],
    armR: [-35, 0, 28], foreR: [20, 0, 0], handR: [-85, 0, 0] }),
  q2Hit: merge(lungeL, { pelvis: [0, -30, 0], spine: [-8, 0, 0], chest: [-6, -25, 0], head: [6, 30, 0], armL: [65, -44, 11], foreL: [87, 0, 0],
    handL: [-22, -19, -55], armR: [-30, 0, 30], foreR: [20, 0, 0], handR: [-85, 0, 0] }),
  // J3 SOSEN-GIRI: a full turn, the cleaver high and the short blade low, both out
  spinOut: merge(legsR, { chest: [-6, 0, 0], armR: [9, -17, 84], foreR: [73, 0, 0], handR: [-69, 4, 5], armL: [-10, 0, -70], foreL: [10, 0, 0], pos: [0, -0.16, 0] }),
  // K1 OKIBA: the cleaver's waist-high sweep from his right across, a deep step
  f1Wind: merge(legsR, { pelvis: [0, -40, 0], spine: [-10, 0, 0], chest: [-6, -30, 0], head: [0, 50, 0], armR: [26, -41, 6], foreR: [110, 0, 0],
    handR: [20, -97, 39], armL: [40, 0, -30], foreL: [70, 0, 0], pos: [0, -0.14, 0] }),
  f1Hit: merge(lunge, { pelvis: [0, 15, 0], spine: [-12, 0, 0], chest: [-6, 25, 0], head: [6, -30, 0], armR: [-34, 51, 34], foreR: [139, 0, 0],
    handR: [-100, 38, 42], armL: [-25, 0, -40], foreL: [40, 0, 0] }),
  f1End: merge(lunge, { pelvis: [0, 25, 0], spine: [-12, 0, 0], chest: [-6, 35, 0], head: [6, -40, 0], armR: [-15, 148, 79], foreR: [5, 0, 0],
    handR: [0, 1, 18], armL: [-25, 0, -40], foreL: [40, 0, 0] }),
  // K2 SHOGA: crouched, the blade on the floor, then swept up high
  f2Wind: merge(legsR, { thighR: [60, 0, 6], shinR: [-80, 0, 0], thighL: [10, 0, -6], shinL: [-70, 0, 0], footL: [40, 0, 0],
    pelvis: [0, -20, 0], spine: [-30, 0, 0], chest: [-10, -10, 0], head: [30, 10, 0], armR: [35, 38, 23], foreR: [59, 0, 0], handR: [-9, -9, 12],
    armL: [30, 0, -30], foreL: [50, 0, 0], pos: [0, -0.3, 0] }),
  f2Hit: merge(lunge, { pos: [0, 0, -0.1], thighR: [30, 0, 6], shinR: [-20, 0, 0], pelvis: [0, -10, 0], spine: [10, 0, 0], chest: [8, 5, 0],
    head: [-15, 0, 0], armR: [69, 11, 19], foreR: [103, 0, 0], handR: [-52, -23, 18], armL: [10, 0, -55], foreL: [20, 0, 0] }),
  // K3 RAKUGA: both hands on the cleaver over the head, dropped through him
  dropUp: merge(legsR, { handL: [-110, -15, -1], pelvis: [0, -10, 0], spine: [10, 0, 0], chest: [10, -5, 0], head: [-15, 0, 0], armR: [112, 41, 11], foreR: [56, 0, 0],
    handR: [46, 26, 3], armL: [146, -42, -4], foreL: [5, 0, 0], pos: [0, 0.03, 0] }),
  dropHit: merge(lunge, { handL: [-41, -4, -20], pelvis: [0, 0, 0], spine: [-30, 0, 0], chest: [-15, 0, 0], head: [25, 0, 0], armR: [18, 43, -4], foreR: [141, 0, 0],
    handR: [25, -146, -15], armL: [16, -61, 18], foreL: [145, 0, 0], pos: [0, -0.26, -0.36] }),
  // the CROSS: both blades raised high, then crossed down in an X
  crossUp: merge(legsL, { spine: [8, 0, 0], head: [-15, 0, 0], armR: [129, 3, 38], foreR: [48, 0, 0], handR: [38, 16, 1],
    armL: [159, 26, -19], foreL: [0, 0, 0], handL: [-111, -6, 0] }),
  crossHit: merge(lunge, { spine: [-18, 0, 0], chest: [-8, 0, 0], head: [10, 0, 0], armR: [3, -25, 41], foreR: [113, 0, 0], handR: [33, 62, -7],
    armL: [15, -2, -33], foreL: [99, 0, 0], handL: [-143, -43, -31] }),
  crossJHit: merge(legsL, { pos: [0, -0.12, -0.04], spine: [-12, 0, 0], armR: [37, -10, -9], foreR: [113, 0, 0], handR: [30, 66, -3],
    armL: [66, -4, 9], foreL: [96, 0, 0], handL: [-144, -64, -17] }),
  // Getsuga: the cleaver low behind him, swung up and out one-handed
  gWind: merge(legsR, { pelvis: [0, -40, 0], spine: [-16, 0, 0], chest: [-8, -30, 0], head: [10, 50, 0], armR: [-8, 54, 34], foreR: [10, 0, 0],
    handR: [-64, 29, -17], armL: [40, 0, -20], foreL: [60, 0, 0], pos: [0, -0.18, 0] }),
  gHit: merge(lunge, { pelvis: [0, 10, 0], spine: [-4, 0, 0], chest: [0, 20, 0], head: [0, -20, 0], armR: [139, -39, 25], foreR: [71, 0, 0],
    handR: [-87, -11, -9], armL: [-30, 0, -45], foreL: [30, 0, 0] }),
  // JUJISHO: both blades drawn back and crossed behind him; the cleaver's cut (f12), the short blade's (f20)
  jujiBack: merge(legsL, { handL: [124, -18, 1], pelvis: [0, 0, 0], spine: [-20, 0, 0], chest: [-6, 0, 0], head: [20, 0, 0], armR: [-29, -5, 28], foreR: [0, 0, 0],
    handR: [-80, -25, 0], armL: [-13, 54, -44], foreL: [8, 0, 0], pos: [0, -0.2, 0.05] }),
  // TSUKIMACHI: side-on, the short blade thrust at him (the left arm straight ahead), the cleaver high and back
  tsuki: merge(legsL, { pelvis: [0, -45, 0], spine: [-8, 0, 0], chest: [-4, -20, 0], neck: [0, 30, 0], head: [-4, 30, 0],
    armL: [101, 63, -5], foreL: [3, 0, 0], handL: [-179, -3, -1], armR: [161, 29, 12], foreR: [46, 0, 0], handR: [-10, 23, 63], pos: [0, -0.14, 0] }),
  tsukiDash: merge(P.dash, { handL: [128, 9, 0], armR: [-15, -6, 14], foreR: [2, 0, 0], handR: [-70, 22, 1], armL: [-43, 8, -5], foreL: [21, 0, 0] }),
  // TSUKI-OTOSHI: leapt, both blades overhead, slammed down together
  otoUp: merge(legsL, { handL: [-145, 17, 0], thighR: [70, 0, 6], shinR: [-100, 0, 0], thighL: [40, 0, -6], shinL: [-90, 0, 0], spine: [12, 0, 0], head: [-20, 0, 0],
    armR: [173, 46, -19], foreR: [33, 0, 0], handR: [10, 43, -7], armL: [-158, -1, 5], foreL: [1, 0, 0], pos: [0, 0.55, -0.4] }),
  otoHit: merge(lunge, { spine: [-38, 0, 0], chest: [-10, 0, 0], head: [30, 0, 0], armR: [86, 11, 10], foreR: [1, 0, 0], handR: [1, -18, 0],
    armL: [83, -10, -10], foreL: [5, 0, 0], handL: [-159, 18, 0], pos: [0, -0.32, -0.5] }),
  // MINEUCHI: the cleaver's flat slammed sideways
  mineWind: merge(legsR, { pelvis: [0, -40, 0], chest: [-6, -30, 0], head: [0, 45, 0], armR: [-16, 1, 69], foreR: [88, 0, 0], handR: [8, 136, -74] }),
  mineHit: merge(lunge, { pelvis: [0, 20, 0], chest: [-6, 30, 0], head: [6, -30, 0], armR: [-65, 17, 99], foreR: [149, 0, 0], handR: [134, 139, -50],
    armL: [-25, 0, -45], foreL: [30, 0, 0] }),
};

// ---------------------------------------------------------------- KESSA key poses (the Tensa in the right hand, the left throws the chains)
export const K = {
  cutWind: merge(legsR, { pelvis: [0, -30, 0], chest: [-6, -25, 0], head: [0, 35, 0], armR: [4, -25, 21], foreR: [76, 0, 0], handR: [-71, 31, 24],
    armL: [30, 0, -20], foreL: [50, 0, 0] }),
  cutHit: merge(lunge, { pelvis: [0, 15, 0], spine: [-10, 0, 0], chest: [-6, 25, 0], head: [6, -25, 0], armR: [12, 39, 84], foreR: [151, 0, 0],
    handR: [-106, 21, 11], armL: [-25, 0, -35], foreL: [30, 0, 0] }),
  jabHit: merge(legsR, { pos: [0, -0.1, -0.04], pelvis: [0, 15, 0], chest: [-6, 25, 0], head: [6, -25, 0], armR: [-1, -9, 36], foreR: [128, 0, 0],
    handR: [3, -6, -4], armL: [-20, 0, -35], foreL: [30, 0, 0] }),
  backWind: merge(legsR, { pelvis: [0, 20, 0], chest: [-6, 30, 0], head: [0, -30, 0], armR: [51, 44, 15], foreR: [56, 0, 0], handR: [-42, 32, 18],
    armL: [10, 0, -30], foreL: [30, 0, 0] }),
  backHit: merge(legsR, { pos: [0, -0.1, -0.04], pelvis: [0, -25, 0], chest: [-8, -25, 0], head: [6, 30, 0], armR: [58, 34, -5], foreR: [38, 0, 0],
    handR: [-45, 89, 14], armL: [20, 0, -40], foreL: [30, 0, 0] }),
  wrapOut: merge(legsR, { chest: [-6, 0, 0], armR: [10, -12, 80], foreR: [57, 0, 0], handR: [-59, 6, 6], armL: [10, 0, -75], foreL: [10, 0, 0], pos: [0, -0.12, 0] }),
  wrapIn: merge(legsR, { chest: [-6, 0, 0], armR: [45, -13, -14], foreR: [83, 0, 0], handR: [-26, 2, 10], armL: [10, 0, -75], foreL: [10, 0, 0], pos: [0, -0.1, 0] }),
  // the parry: the slab raised vertical before him, the flat out, the left palm on the flat
  parry: merge(legsR, { pelvis: [0, -6, 0], spine: [-4, 0, 0], chest: [-2, -4, 0], head: [4, 0, 0], armR: [39, 28, 9], foreR: [47, 0, 0],
    handR: [13, -76, -87], armL: [81, -16, -4], foreL: [63, 0, 0], handL: [-137, -1, 0], pos: [0, -0.12, 0] }),
  // KUSARI-BIKI: the left fist thrown at him, then hauled back with the chain, the blade out
  yankThrow: merge(lungeL, { pelvis: [0, 20, 0], chest: [-6, 20, 0], head: [6, -15, 0], armL: [90, 0, -5], foreL: [0, 0, 0], handL: [-10, 0, 0],
    armR: [-50, -54, 24], foreR: [38, 0, 0], handR: [48, -11, 1] }),
  yankHit: merge(legsR, { pos: [0, -0.16, 0.12], pelvis: [0, -30, 0], spine: [-12, 0, 0], chest: [-6, -25, 0], head: [6, 30, 0],
    armL: [-40, 0, -30], foreL: [100, 0, 0], handL: [-20, 0, 0], armR: [96, 48, 6], foreR: [6, 0, 0], handR: [-10, 9, -6] }),
  // ZANZO: the slab swept flat before his face, then down to his side
  zanzoUp: merge(legsR, { chest: [-4, -25, 0], head: [-6, 0, 0], armR: [86, 14, 18], foreR: [66, 0, 0], handR: [62, 113, 48] }),
  zanzoHit: merge(legsR, { pos: [0, -0.14, 0], chest: [-6, 25, 0], armR: [-69, 39, 34], foreR: [86, 0, 0], handR: [-59, 114, -55],
    armL: [10, 0, -30], foreL: [20, 0, 0] }),
  // the overhead (K3 TENSA-OTOSHI, ZANGETSU-GAESHI, the Kikon): both hands on the slab
  dropUp: merge(legsR, { handL: [-110, -15, -1], spine: [10, 0, 0], chest: [10, -5, 0], head: [-15, 0, 0], armR: [112, 41, 11], foreR: [56, 0, 0], handR: [46, 26, 3],
    armL: [146, -42, -4], foreL: [5, 0, 0], pos: [0, 0.03, 0] }),
  dropHit: merge(lunge, { handL: [-41, -4, -20], spine: [-30, 0, 0], chest: [-15, 0, 0], head: [25, 0, 0], armR: [18, 43, -4], foreR: [141, 0, 0], handR: [25, -146, -15],
    armL: [16, -61, 18], foreL: [145, 0, 0], pos: [0, -0.26, -0.36] }),
  f1Wind: merge(legsR, { pelvis: [0, -40, 0], spine: [-10, 0, 0], chest: [-6, -30, 0], head: [0, 50, 0], armR: [26, -41, 6], foreR: [110, 0, 0],
    handR: [20, -97, 39], armL: [30, 0, -30], foreL: [40, 0, 0], pos: [0, -0.14, 0] }),
  f1Hit: merge(lunge, { pelvis: [0, 15, 0], spine: [-12, 0, 0], chest: [-6, 25, 0], head: [6, -30, 0], armR: [-34, 51, 34], foreR: [139, 0, 0],
    handR: [-100, 38, 42], armL: [-25, 0, -40], foreL: [30, 0, 0] }),
};

/** A strike: idle, the windup at 0.85, the hit at 1, held / followed to END at 2, back to idle at 3. */
const strike = (idle: PoseSpec, wind: PoseSpec, hit: PoseSpec, end: PoseSpec = hit): Clip =>
  [k(0, idle), k(0.85, wind, 'out'), k(1, hit, 'in'), k(2, end, 'out'), k(3, idle)];
/** A full turn on the pelvis through the active frames (4 keys of 120 deg: slerp takes the short way). */
const turn = (p: PoseSpec, from: number, to: number): Key[] =>
  [0, 1, 2, 3].map((i) => k(from + ((to - from) * i) / 3, merge(p, { pelvis: [0, -120 * i, 0] }), 'lin'));

const I = S.idle, KI = S.kIdle;
const hi = (p: PoseSpec): PoseSpec => merge(p, { armR: Q.tsuki.armR, foreR: Q.tsuki.foreR, handR: Q.tsuki.handR });
const SHIKAI: Record<string, Clip> = {
  'ic-q1': strike(I, Q.q1Wind, Q.q1Hit, Q.q1End),
  'ic-q2': strike(I, Q.q1End, Q.q2Hit),
  'ic-spin': [k(0, I), k(0.85, merge(Q.spinOut, { pelvis: [0, 40, 0] }), 'out'), ...turn(Q.spinOut, 1, 2), k(3, I)],
  'ic-f1': strike(I, Q.f1Wind, Q.f1Hit, Q.f1End),
  'ic-f2': strike(I, Q.f2Wind, Q.f2Hit),
  'ic-drop': [k(0, I), k(0.5, Q.dropUp, 'out'), k(0.85, Q.dropUp), k(1, Q.dropHit, 'in'), k(2, Q.dropHit), k(3, I)],
  'ic-cross': [k(0, I), k(0.7, Q.crossUp, 'out'), k(1, Q.crossHit, 'in'), k(2, Q.crossHit), k(3, I)],
  'ic-cross-j': [k(0, I), k(0.7, Q.crossUp, 'out'), k(1, Q.crossJHit, 'in'), k(2, Q.crossJHit), k(3, I)],
  'ic-getsuga': strike(I, Q.gWind, Q.gHit),
  'ic-juji': [k(0, I), k(0.3, Q.jujiBack, 'out'), k(0.5, Q.jujiBack), k(0.6, merge(Q.jujiBack, { armR: Q.gHit.armR, foreR: Q.gHit.foreR,
    handR: Q.gHit.handR, chest: [-6, 20, 0] }), 'in'), k(0.9, merge(Q.jujiBack, { armR: Q.gHit.armR, foreR: Q.gHit.foreR, handR: Q.gHit.handR })),
  k(1, Q.crossHit, 'in'), k(2, Q.crossHit), k(3, I)],
  'ic-tsuki': [k(0, I), k(1, Q.tsuki, 'out'), k(2.8, Q.tsuki), k(3, I)],
  // RANGETSU: four short-blade cuts on the lunge, the cleaver kept high and back as in the stance
  'ic-rangetsu': [k(0, Q.tsuki), k(0.7, hi(Q.q1Wind), 'out'), k(1, hi(Q.q1Hit), 'in'), k(1.25, hi(Q.q2Hit), 'in'), k(1.5, hi(Q.q1Hit), 'in'),
    k(1.75, hi(Q.q2Hit), 'in'), k(2, hi(Q.q1End)), k(3, I)],
  'ic-tsuki-otoshi': [k(0, Q.tsuki), k(0.3, merge(lunge, { spine: [-20, 0, 0], armR: [120, 0, 15], armL: [110, 0, -15] }), 'out'),
    k(0.6, Q.otoUp, 'out'), k(0.85, Q.otoUp), k(1, Q.otoHit, 'in'), k(2, Q.otoHit), k(3, I)],
  'ic-mine': strike(I, Q.mineWind, Q.mineHit),
};
const KESSA: Record<string, Clip> = {
  'ic-k-jab': strike(KI, K.cutWind, K.jabHit),
  'ic-k-cut': strike(KI, K.cutWind, K.cutHit),
  'ic-k-back': strike(KI, K.backWind, K.backHit),
  'ic-k-wrap-j': [k(0, KI), k(0.85, merge(K.wrapIn, { pelvis: [0, 40, 0] }), 'out'), ...turn(K.wrapIn, 1, 2), k(3, KI)],
  'ic-k-wrap': [k(0, KI), k(0.85, merge(K.wrapOut, { pelvis: [0, 40, 0] }), 'out'), ...turn(K.wrapOut, 1, 2), k(3, KI)],
  'ic-f1': strike(KI, K.f1Wind, K.f1Hit),
  'ic-f2': strike(KI, merge(Q.f2Wind, { armL: [10, 0, -30], foreL: [30, 0, 0] }), merge(Q.f2Hit, { armL: [10, 0, -55] })),
  'ic-drop': [k(0, KI), k(0.5, K.dropUp, 'out'), k(0.85, K.dropUp), k(1, K.dropHit, 'in'), k(2, K.dropHit), k(3, KI)],
  'ic-k-parry': [k(0, KI), k(1, K.parry, 'out'), k(2, K.parry), k(3, KI)],
  'ic-k-yank': [k(0, KI), k(0.4, K.yankThrow, 'out'), k(0.8, K.yankThrow), k(1, K.yankHit, 'out'), k(2, K.yankHit), k(3, KI)],
  'ic-k-zanzo': [k(0, KI), k(0.5, K.zanzoUp, 'out'), k(1, K.zanzoHit, 'out'), k(2, K.zanzoHit), k(3, KI)],
};
// the Shikai's clips KESSA inherits (the Breaker's strike, the Kikon's cross) swing the one blade
const KESSA_OF: Record<string, string> = { 'ic-mine': 'ic-k-zanzo', 'ic-cross': 'ic-drop' };
// ZANGETSU-GAESHI (the catch's counter): the chain hauled (the pull, f0), the slab up, the top-down cut
const GAESHI: Clip = [k(0, K.yankHit), k(0.5, K.dropUp, 'out'), k(0.85, K.dropUp), k(1, K.dropHit, 'in'), k(2, K.dropHit), k(3, KI)];

/** The bespoke clip for MV in FORM, by its art clip (KESSA's table for KESSA and the clones). */
export function clip(mv: Move, form = 'base'): Clip | null {
  if (mv.name === 'ic-k-gaeshi') return GAESHI;
  if (mv.name === 'ic-tsuki-dash') return [k(0, Q.tsuki), k(0.3, Q.tsukiDash, 'out'), k(2, Q.tsukiDash), k(3, Q.tsuki)];
  const c = (mv.clip2 && mv.kind !== 'sp' ? mv.clip2 : mv.clip) ?? '';
  return (form === 'kessa' ? KESSA[c] ?? KESSA[KESSA_OF[c]] : undefined) ?? SHIKAI[c] ?? null;
}
export function stance(form: string) {
  return form === 'kessa' ? { idle: S.kIdle, guard: S.kGuard, run: run(S.kRun) } : { idle: S.idle, guard: S.guard, run: run(S.run) };
}
const runs = new Map<PoseSpec, Clip>();
function run(p: PoseSpec): Clip {
  let c = runs.get(p);
  if (!c) { c = [k(0, p), k(1, merge(p, mirror(P.runA), pick(p, ARMS))), k(2, p)]; runs.set(p, c); }
  return c;
}
const ARMS = ['armR', 'foreR', 'handR', 'armL', 'foreL', 'handL', 'spine'] as const;
const pick = (p: PoseSpec, ks: readonly string[]): PoseSpec => Object.fromEntries(Object.entries(p).filter(([n]) => ks.includes(n)));
/** CharClips.move: the bespoke clip in the main phase (u); the pre-strike phases keep anim.ts's hold / dash poses. */
export const move = (mv: Move, f: Fighter): Clip | null => (f.phase === 'main' || !f.phase ? clip(mv, f.form) : null);
export const idle = S.idle;
export function clipFor(_c: string, _mv: Move): ClipName | null { return null; }
