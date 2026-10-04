// Yamamoto's clips (BABYLON_LOOK.md B2, by screen time): every move he has, keyed in its phase (u: 0 start, 1 = frame
// S, 2 = end of the active frames, 3 = end; the Signature's two cuts and its wave chop sit at their frames' u). The
// one arm: Q1-Q3 one-handed iai draws (the coil at the left hip, the flat cut, the backhand along the same line), J3
// SODEBI whips the empty sleeve; F1 / F2 the heavy fire cuts (the waist sweep with a step, the rising column), K3 the
// overhead chop at his feet; TAIMATSU's torch sweep; ENJO points along the lane, raises, sweeps down; Shiranui's charge
// and throw; TENCHI, the Kikon dash-cut (the flash-step lean, one diagonal); Bankai's thrust, drop, KYOKUJITSUJIN's bite,
// SHONETSU's planted tip, the parry and its counter, MINAMI driven into the plaza; NADEGIRI; IKKOTSU's punch.
// The right arm of every key pose was solved for a grip position and blade direction (character space: x his right,
// y up, -z forward) and rounded; the torso and legs are set by hand. Idle: the old man's hunch (spine -12, head +8);
// the empty left sleeve: every library pose keeps the left arm near his side (30 % of its swing), only SODEBI whips it.
import type { Move } from '../../sim/kit';
import type { ClipName } from '../anim';
import { P, merge, type Clip, type Euler, type PoseSpec } from '../pose';

const legs: PoseSpec = { thighR: [28, -8, 6], shinR: [-38, 0, 0], footR: [10, 0, 0], thighL: [-4, 10, -8], shinL: [-26, 0, 0], footL: [26, 0, 0] };
const hang = { armL: [4, 0, -5] as Euler, foreL: [4, 0, 0] as Euler, handL: [0, 0, 0] as Euler };
export const idle = merge(legs, { pelvis: [0, 18, 0], spine: [-12, 0, 0], chest: [-8, -8, 0], neck: [10, 0, 0], head: [8, -10, 0],
  armR: [40, 0, 10], foreR: [35, 0, 0], handR: [-30, 0, 10], ...hang, pos: [0, -0.06, 0] });

// the key poses (bones left out come from the idle)
const K: Record<string, PoseSpec> = {
  q1w: {armR: [52, -5, -31], foreR: [0, 0, 0], handR: [-75, -21, -25], pelvis: [0, 30, 0], chest: [-8, 25, 0], head: [8, -30, 0], pos: [0, -0.1, 0]},
  q1h: {armR: [21, 3, -61], foreR: [102, 0, 0], handR: [-27, 0, 0], pelvis: [0, -5, 0], chest: [-6, -15, 0], head: [8, 10, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.14, -0.12]},
  q1e: {armR: [71, -11, -30], foreR: [97, 0, 0], handR: [2, -29, 42], pelvis: [0, -25, 0], chest: [-4, -35, 0], head: [8, 30, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.12, -0.14]},
  q2w: {armR: [62, -16, -24], foreR: [122, 0, 0], handR: [9, -11, 45], pelvis: [0, -20, 0], chest: [-6, -35, 0], head: [8, 30, 0], pos: [0, -0.1, 0]},
  q2h: {armR: [32, -2, -19], foreR: [118, 0, 0], handR: [-56, 5, 7], pelvis: [0, 15, 0], chest: [-8, 20, 0], head: [8, -15, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.13, -0.1]},
  q2e: {armR: [41, 6, -13], foreR: [80, 0, 0], handR: [-64, -9, -14], pelvis: [0, 30, 0], chest: [-8, 45, 0], head: [8, -40, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.13, -0.12]},
  j3: {armR: [-1, 2, 13], foreR: [0, 0, 0], handR: [-57, 0, 0], pelvis: [0, 0, 0], chest: [-8, 0, 0]},
  f1w: {armR: [74, -4, 0], foreR: [4, 0, 0], handR: [6, -28, 57], pelvis: [0, -35, 0], chest: [-6, -55, 0], head: [8, 50, 0], pos: [0, -0.15, 0.03]},
  f1h: {armR: [-13, 9, -37], foreR: [131, 0, 0], handR: [-29, -6, -4], pelvis: [0, 10, 0], chest: [-8, 25, 0], head: [8, -25, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.2, -0.3]},
  f1e: {armR: [39, -3, -53], foreR: [58, 0, 0], handR: [-23, -4, 14], pelvis: [0, 35, 0], chest: [-8, 60, 0], head: [8, -55, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.2, -0.32]},
  f2w: {armR: [13, 1, 5], foreR: [0, 0, 0], handR: [-52, -3, -2], spine: [-25, 0, 0], chest: [-10, -20, 0], head: [25, 15, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.25, 0]},
  f2h: {armR: [16, -4, -11], foreR: [130, 0, 0], handR: [-26, -3, 9], spine: [-5, 0, 0], chest: [-4, 0, 0], head: [10, 0, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.06, -0.1]},
  f2e: {armR: [103, 1, -15], foreR: [97, 0, 0], handR: [-42, 3, 2], spine: [10, 0, 0], chest: [6, 0, 0], head: [-10, 0, 0], thighR: [10, 0, 6], shinR: [-10, 0, 0], footR: [-20, 0, 0], thighL: [-15, 0, -6], shinL: [-10, 0, 0], footL: [-15, 0, 0], pos: [0, 0.03, -0.1]},
  k3w: {armR: [139, -4, -6], foreR: [61, 0, 0], handR: [0, 5, -9], spine: [8, 0, 0], chest: [4, 0, 0], head: [0, 0, 0], pos: [0, -0.04, 0]},
  k3h: {armR: [14, -4, 0], foreR: [120, 0, 0], handR: [-63, 5, 5], spine: [-35, 0, 0], chest: [-10, 0, 0], head: [35, 0, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.2, -0.15]},
  k3e: {armR: [18, -1, 0], foreR: [91, 0, 0], handR: [-52, -4, 8], spine: [-40, 0, 0], chest: [-12, 0, 0], head: [40, 0, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.24, -0.16]},
  s2h: {armR: [12, 17, -70], foreR: [120, 0, 0], handR: [-17, -3, 1], pelvis: [0, -15, 0], chest: [-8, -30, 0], head: [8, 25, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.18, -0.3]},
  hold: {armR: [2, -46, -59], foreR: [97, 0, 0], handR: [7, -16, 37], pelvis: [0, -30, 0], spine: [-15, 0, 0], chest: [-8, -45, 0], head: [20, 40, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.22, 0]},
  thrH: {armR: [34, -38, 70], foreR: [132, 0, 0], handR: [-66, 2, -3], pelvis: [0, 10, 0], chest: [-6, 25, 0], head: [8, -20, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.14, -0.3]},
  taiW: {armR: [-5, -11, -45], foreR: [110, 0, 0], handR: [-21, -7, 19], pelvis: [0, 30, 0], spine: [-20, 0, 0], chest: [-8, 45, 0], head: [20, -35, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.2, 0]},
  taiH: {armR: [83, -1, -24], foreR: [42, 0, 0], handR: [-6, -3, 8], pelvis: [0, -20, 0], spine: [5, 0, 0], chest: [-2, -35, 0], head: [0, 25, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.04, -0.12]},
  enjoP: {armR: [76, -4, 4], foreR: [81, 0, 0], handR: [-64, 4, 0], pelvis: [0, 5, 0], chest: [-6, 5, 0], head: [8, -5, 0], pos: [0, -0.08, -0.03]},
  enjoR: {armR: [102, 2, 9], foreR: [78, 0, 0], handR: [-62, -4, 9], spine: [5, 0, 0], chest: [0, 0, 0], head: [-5, 0, 0], pos: [0, -0.03, -0.02]},
  enjoH: {armR: [19, 2, 19], foreR: [124, 0, 0], handR: [-78, 4, 1], spine: [-35, 0, 0], chest: [-10, 0, 0], head: [35, 0, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.2, -0.12]},
  dash: {armR: [-7, 2, 9], foreR: [0, 0, 0], handR: [-39, 3, -9], spine: [-30, 0, 0], chest: [-15, -10, 0], head: [35, 5, 0], thighR: [60, 0, 0], shinR: [-70, 0, 0], thighL: [-40, 0, 0], shinL: [-50, 0, 0], pos: [0, -0.15, 0]},
  tenW: {armR: [104, 10, 9], foreR: [79, 0, 0], handR: [3, -20, 52], pelvis: [0, -25, 0], chest: [-6, -35, 0], head: [8, 30, 0], pos: [0, -0.12, 0]},
  tenH: {armR: [-17, 19, -70], foreR: [131, 0, 0], handR: [-17, -6, -2], pelvis: [0, 20, 0], spine: [-20, 0, 0], chest: [-10, 40, 0], head: [25, -35, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.25, -0.35]},
  tenE: {armR: [30, -2, -52], foreR: [36, 0, 0], handR: [-17, -6, 14], pelvis: [0, 25, 0], spine: [-25, 0, 0], chest: [-10, 45, 0], head: [30, -40, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.27, -0.36]},
  etW: {armR: [-25, -3, 57], foreR: [120, 0, 0], handR: [26, 3, -5], pelvis: [0, -25, 0], chest: [-6, -35, 0], head: [8, 30, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.15, 0]},
  etH: {armR: [51, -8, 23], foreR: [114, 0, 0], handR: [-76, 0, 9], pelvis: [0, 10, 0], chest: [-6, 20, 0], head: [8, -15, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.14, -0.25]},
  edUp: {armR: [152, 2, 0], foreR: [10, 0, 0], handR: [-13, 0, 0], spine: [10, 0, 0], chest: [4, 0, 0], head: [-15, 0, 0], pos: [0, 0, 0]},
  edH: {armR: [-13, -3, -9], foreR: [131, 0, 0], handR: [-30, -6, 10], spine: [-35, 0, 0], chest: [-10, 0, 0], head: [35, 0, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.2, -0.3]},
  kyW: {armR: [146, -2, -5], foreR: [41, 0, 0], handR: [-9, 2, -5], spine: [8, 0, 0], chest: [4, 0, 0], head: [-15, 0, 0], pos: [0, 0.02, 0]},
  kyH: {armR: [4, -4, -7], foreR: [131, 0, 0], handR: [-46, -1, 12], spine: [-30, 0, 0], chest: [-10, 0, 0], head: [30, 0, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.18, -0.25]},
  kyB: {armR: [-2, -4, -8], foreR: [126, 0, 0], handR: [-55, 3, 4], spine: [-45, 0, 0], chest: [-12, 0, 0], head: [45, 0, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.3, -0.3]},
  shW: {armR: [107, 6, -1], foreR: [88, 0, 0], handR: [-96, 10, 6], spine: [5, 0, 0], head: [-5, 0, 0], pos: [0, 0.02, 0]},
  shH: {armR: [-3, 10, 73], foreR: [119, 0, 0], handR: [-76, -13, -21], spine: [-30, 0, 0], chest: [-8, 0, 0], head: [30, 0, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.3, 0]},
  par: {armR: [32, -6, 6], foreR: [117, 0, 0], handR: [26, -1, 5], chest: [-4, 10, 0], head: [8, -10, 0], pos: [0, -0.12, 0]},
  coW: {armR: [55, 6, -14], foreR: [86, 0, 0], handR: [86, 8, -9], chest: [-6, -20, 0], head: [8, 15, 0], pos: [0, -0.18, -0.1]},
  coH: {armR: [128, 13, -17], foreR: [86, 0, 0], handR: [-72, 11, 22], spine: [10, 0, 0], chest: [6, 15, 0], head: [-15, 0, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, 0, -0.35]},
  kaW: {armR: [155, -1, -1], foreR: [0, 0, 0], handR: [-65, 2, 9], spine: [6, 0, 0], head: [-15, 0, 0], pos: [0, 0.03, 0]},
  kaH: {armR: [0, 14, 72], foreR: [125, 0, 0], handR: [-80, -10, -16], spine: [-40, 0, 0], chest: [-10, 0, 0], head: [40, 0, 0], thighR: [90, 0, 8], shinR: [-120, 0, 0], footR: [30, 0, 0], thighL: [-10, 0, -8], shinL: [-110, 0, 0], footL: [60, 0, 0], pos: [0, -0.45, 0]},
  naW: {armR: [-13, 14, 52], foreR: [118, 0, 0], handR: [-27, 4, -11], pelvis: [0, 40, 0], spine: [-20, 0, 0], chest: [-8, 60, 0], head: [20, -50, 0], thighR: [70, 0, 8], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [20, 0, -8], shinL: [-80, 0, 0], footL: [50, 0, 0], pos: [0, -0.3, 0]},
  naH: {armR: [16, 19, -42], foreR: [80, 0, 0], handR: [-28, 3, -18], pelvis: [0, -40, 0], spine: [-10, 0, 0], chest: [-6, -70, 0], head: [10, 60, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.18, -0.6]},
  naE: {armR: [79, -1, -16], foreR: [5, 0, 0], handR: [0, -11, 13], pelvis: [0, -45, 0], spine: [-10, 0, 0], chest: [-6, -80, 0], head: [10, 65, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.18, -0.62]},
  ikW: {armR: [-22, -2, 67], foreR: [126, 0, 0], handR: [8, -1, -8], pelvis: [0, -25, 0], chest: [-8, -40, 0], head: [8, 35, 0], pos: [0, -0.12, 0]},
  ikH: {armR: [41, -26, 74], foreR: [102, 0, 0], handR: [-93, -22, -18], pelvis: [0, 20, 0], spine: [-12, 0, 0], chest: [-8, 35, 0], head: [12, -30, 0], thighR: [55, 0, 6], shinR: [-60, 0, 0], footR: [5, 0, 0], thighL: [-25, 0, -8], shinL: [-20, 0, 0], footL: [20, 0, 0], pos: [0, -0.16, -0.15]},
  guard: {armR: [23, 4, 9], foreR: [99, 0, 0], handR: [5, 4, -4], pelvis: [0, 20, 0], spine: [-8, 0, 0], chest: [-6, -10, 0], head: [10, -6, 0], pos: [0, -0.1, 0]},
};
// SODEBI: the empty sleeve whipped across the face, left to right; the blade kept low behind him
const j3w = merge(K.j3, { pelvis: [0, 25, 0], chest: [-6, 40, 0], head: [8, -35, 0], armL: [-10, 0, -70], foreL: [10, 0, 0], pos: [0, -0.1, 0] });
const j3h = merge(K.j3, { pelvis: [0, -15, 0], chest: [-8, -40, 0], head: [8, 30, 0], armL: [95, 0, 30], foreL: [5, 0, 0], pos: [0, -0.1, -0.06] });
const j3e = merge(K.j3, { pelvis: [0, -20, 0], chest: [-8, -50, 0], head: [8, 35, 0], armL: [85, 0, 50], foreL: [5, 0, 0], pos: [0, -0.1, -0.07] });

const k = (at: number, pose: PoseSpec, ease?: 'in' | 'out' | 'io' | 'lin') => ({ at, pose, ease });
/** wind-up, a short hold, the snap into the hit at S, the end of the active frames, a held follow-through, the idle */
const strike = (w: PoseSpec, h: PoseSpec, e: PoseSpec, tw = 0.75, th = 2.45): Clip =>
  [k(0, idle), k(tw, w, 'out'), k(0.9, w), k(1, h, 'in'), k(2, e, 'out'), k(th, e), k(3, idle)];
const C: Record<string, Clip> = {
  q1: strike(K.q1w, K.q1h, K.q1e),
  q2: strike(K.q2w, K.q2h, K.q2e),
  j3: strike(j3w, j3h, j3e),
  f1: [k(0, idle), k(0.5, K.f1w, 'out'), k(0.9, merge(K.f1w, { chest: [-6, -62, 0] })), k(1, K.f1h, 'in'), k(2, K.f1e, 'out'), k(2.4, K.f1e), k(3, idle)],
  f2: strike(K.f2w, K.f2h, K.f2e, 0.5, 2.4),
  k3: strike(K.k3w, K.k3h, K.k3e, 0.5, 2.5),
  // the Signature (S 16, A 25): the sweep f16, the backhand f28, raised f34-37, the wave chop f40
  sig: [k(0, idle), k(0.44, K.f1w, 'out'), k(0.81, K.f1w), k(1, K.f1h, 'in'), k(1.08, K.f1e, 'out'), k(1.36, K.f1e), k(1.48, K.s2h, 'in'),
    k(1.56, K.q1e, 'out'), k(1.72, K.k3w), k(1.84, K.k3w), k(1.96, K.k3h, 'in'), k(2.1, K.k3e, 'out'), k(2.5, K.k3e), k(3, idle)],
  shiranui: [k(0, K.hold), k(0.6, K.hold), k(1, K.thrH, 'in'), k(2, K.thrH), k(2.4, K.thrH), k(3, idle)],
  taimatsu: [k(0, idle), k(0.6, K.taiW, 'out'), k(0.9, K.taiW), k(1, K.taiH, 'in'), k(2, K.taiH), k(2.4, K.taiH), k(3, idle)],
  // ENJO (S 20): the blade along the lane f4-11, raised f15-17, swept down at S
  enjo: [k(0, idle), k(0.2, K.enjoP, 'out'), k(0.55, K.enjoP), k(0.75, K.enjoR), k(0.85, K.enjoR), k(1, K.enjoH, 'in'), k(2, K.enjoH), k(2.5, K.enjoH), k(3, idle)],
  tenchi: [k(0, K.dash), k(0.6, K.tenW, 'out'), k(1, K.tenH, 'in'), k(2, K.tenE, 'out'), k(2.5, K.tenE), k(3, idle)],
  ethrust: [k(0, idle), k(0.7, K.etW, 'out'), k(0.9, K.etW), k(1, K.etH, 'in'), k(2, K.etH), k(2.4, K.etH), k(3, idle)],
  edrop: [k(0, idle), k(0.38, K.edUp, 'out'), k(0.81, K.edUp), k(1, K.edH, 'in'), k(2, K.edH), k(2.6, K.edH), k(3, idle)],
  kyoku: [k(0, idle), k(0.44, K.kyW, 'out'), k(0.83, K.kyW), k(1, K.kyH, 'in'), k(1.4, K.kyB, 'in'), k(2, K.kyB), k(2.6, K.kyB), k(3, idle)],
  shonetsu: [k(0, idle), k(0.5, K.shW, 'out'), k(0.85, K.shW), k(1, K.shH, 'in'), k(2, K.shH), k(2.6, K.shH), k(3, idle)],
  parry: [k(0, idle), k(1, K.par, 'out'), k(2, K.par), k(2.4, K.par), k(3, idle)],
  counter: [k(0, K.par), k(0.5, K.coW, 'out'), k(1, K.coH, 'in'), k(2, K.coH), k(2.4, K.coH), k(3, idle)],
  kaka: [k(0, idle), k(0.45, K.kaW, 'out'), k(0.8, K.kaW), k(1, K.kaH, 'in'), k(2, K.kaH), k(2.7, K.kaH), k(3, idle)],
  nadegiri: [k(0, idle), k(0.5, K.naW, 'out'), k(0.85, K.naW), k(1, K.naH, 'in'), k(2, K.naE, 'out'), k(2.5, K.naE), k(3, idle)],
  ikkotsu: strike(K.ikW, K.ikH, K.ikH, 0.7, 2.4),
};
const BY_NAME: Record<string, string> = { 'ya-tenchi': 'tenchi', 'ya-shiranui': 'shiranui', 'ya-taimatsu': 'taimatsu', 'ya-nadegiri': 'nadegiri',
  'ya-kyoku': 'kyoku', 'ya-kaka': 'kaka', 'ya-w-parry': 'parry', 'ya-w-counter': 'counter', 'ya-w-shonetsu': 'shonetsu' };
const BY_CLIP: Record<string, string> = { 'ya-q1': 'q1', 'ya-q2': 'q2', 'ya-sleeve': 'j3', 'ya-f1': 'f1', 'ya-f2': 'f2', 'ya-q3': 'k3',
  'ya-sig': 'sig', 'ya-enjo': 'enjo', 'ya-e-thrust': 'ethrust', 'ya-e-drop': 'edrop', 'ya-ikkotsu': 'ikkotsu' };

export function clipFor(c: string, mv: Move): ClipName | Clip | null {
  const n = BY_NAME[mv.name] ?? BY_CLIP[c];
  return n ? C[n] : null;
}

const damp = (e?: Euler): Euler | undefined => e && [e[0] * 0.3, e[1] * 0.3, e[2] * 0.3];
export const poses = {
  ...Object.fromEntries(Object.entries(P).map(([n, p]: [string, PoseSpec]) =>
    [n, { ...p, armL: damp(p.armL) ?? hang.armL, foreL: damp(p.foreL) ?? hang.foreL, handL: hang.handL }])),
  guard: merge(idle, K.guard), guardHit: merge(idle, K.guard, { spine: [-2, 0, 0], head: [16, -6, 0], pos: [0, -0.07, 0.06] }),
  hold: merge(idle, K.hold), dash: merge(idle, K.dash),
} as Partial<Record<keyof typeof P, PoseSpec>>;
