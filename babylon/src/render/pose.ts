// pose.ts: the M5 pose library (the user, 2026-10-04: models and motions are redrawn; a pose library plus per-move key
// poses in phase coordinates, sampled from the fighter's sf, so frame-data changes never touch the art).
// A pose is local Euler angles in degrees per bone ([x, y, z], applied Y then X then Z) on top of the rest pose (arms
// hanging, legs straight), plus `pos`: a pelvis offset in metres for a 1.8 m figure (scaled by height).
// Bone conventions (character space: x = his right, y = up, z = his back; he faces -z):
//   arms / legs hang down: +x swings the limb forward; the right arm lifts out to the side with +z, the left with -z;
//   elbows bend with +x (forearm forward), knees with -x (shin back); torso bones point up: -x bends forward,
//   +y turns to his left, +z leans to his left.
// No Babylon imports: the phase sampler is unit-tested in node (test/pose.test.ts).
import type { Move } from '../sim/kit';

export const BONES = ['pelvis', 'spine', 'chest', 'neck', 'head',
  'shoulderR', 'armR', 'foreR', 'handR', 'weaponR', 'shoulderL', 'armL', 'foreL', 'handL', 'weaponL',
  'thighR', 'shinR', 'footR', 'thighL', 'shinL', 'footL'] as const;
export type BoneName = typeof BONES[number];
export type Euler = [number, number, number];
export type PoseSpec = Partial<Record<BoneName, Euler>> & { pos?: Euler };

/** The pose seen in a mirror: R <-> L, and every yaw / roll flips. */
export function mirror(p: PoseSpec): PoseSpec {
  const o: PoseSpec = {};
  for (const [k, v] of Object.entries(p) as [string, Euler][]) {
    if (k === 'pos') { o.pos = [-v[0], v[1], v[2]]; continue; }
    const m = k.endsWith('R') ? k.slice(0, -1) + 'L' : k.endsWith('L') ? k.slice(0, -1) + 'R' : k;
    (o as Record<string, Euler>)[m] = [v[0], -v[1], -v[2]];
  }
  return o;
}
/** Later specs override earlier ones bone by bone. */
export const merge = (...ps: PoseSpec[]): PoseSpec => Object.assign({}, ...ps);

// ---------------------------------------------------------------- phase coordinates
/** Where move frame SF of MV sits: u (0 = move start, 1 = frame S, 2 = end of active S+A, 3 = end of recovery, linear
 *  in frames inside each span), and for multi-hit moves the hit window i it belongs to with w (0 = the previous window's
 *  end, 1 = window i opens, 2 = it closes; after the last window w runs 2 -> 3 over the recovery). */
export function phase(mv: Move, sf: number): { u: number; i: number; w: number } {
  const s = mv.s, a = mv.a, end = s + a + mv.r;
  const u = sf <= s ? sf / Math.max(1, s) : sf <= s + a ? 1 + (sf - s) / Math.max(1, a) : 2 + Math.min(1, (sf - s - a) / Math.max(1, end - s - a));
  const hs = mv.hits;
  if (hs.length < 2) return { u, i: 0, w: u };
  let prev = 0;
  for (let i = 0; i < hs.length; i++) {
    const h = hs[i];
    if (sf < h.from) return { u, i, w: (sf - prev) / Math.max(1, h.from - prev) };
    if (sf < h.to || i === hs.length - 1 && sf === h.to) return { u, i, w: 1 + (sf - h.from) / Math.max(1, h.to - h.from) };
    prev = h.to;
  }
  return { u, i: hs.length - 1, w: 2 + Math.min(1, (sf - prev) / Math.max(1, end - prev)) };
}

// ---------------------------------------------------------------- clips
/** Key poses at phase values; `ease` per segment: 'in' (slow start), 'out' (fast start: strikes), 'io' (default). */
export interface Key { at: number; pose: PoseSpec; ease?: 'in' | 'out' | 'io' | 'lin' }
export type Clip = Key[];
const EASE = { in: (t: number) => t * t, out: (t: number) => 1 - (1 - t) * (1 - t), io: (t: number) => t * t * (3 - 2 * t), lin: (t: number) => t };
/** The two keys around X and the eased blend between them (the caller slerps bone by bone). */
export function sampleKeys(clip: Clip, x: number): [PoseSpec, PoseSpec, number] {
  if (x <= clip[0].at) return [clip[0].pose, clip[0].pose, 0];
  for (let i = 1; i < clip.length; i++) {
    const k = clip[i];
    if (x <= k.at) {
      const p = clip[i - 1], t = (x - p.at) / Math.max(1e-6, k.at - p.at);
      return [p.pose, k.pose, EASE[k.ease ?? 'io'](t)];
    }
  }
  const l = clip[clip.length - 1].pose;
  return [l, l, 0];
}

// ---------------------------------------------------------------- the pose library
// Stances: a sword in the right hand, blade forward along the hand's -z.
const legsBent: PoseSpec = { thighR: [28, -8, 6], shinR: [-38, 0, 0], footR: [10, 0, 0],
  thighL: [-4, 10, -8], shinL: [-26, 0, 0], footL: [26, 0, 0], pos: [0, -0.07, 0] };
export const P = {
  // Yamamoto: the old man's stoop, blade low and forward, the left hand behind his back
  idleYama: merge(legsBent, { pelvis: [0, 18, 0], spine: [-10, 0, 0], chest: [-8, -8, 0], neck: [10, 0, 0], head: [8, -10, 0],
    armR: [40, 0, 10], foreR: [35, 0, 0], handR: [-30, 0, 10], armL: [-25, 0, -10], foreL: [70, -50, 0], handL: [0, 0, 0],
    pos: [0, -0.06, 0] }),
  // Kenpachi: slouched, the long blade hanging from a loose right hand, point near the ground
  idleKen: merge(legsBent, { pelvis: [0, 15, 0], spine: [-4, 0, 0], chest: [-6, -10, 4], neck: [6, 0, 0], head: [4, -8, -4],
    armR: [18, 0, 18], foreR: [20, 0, 0], handR: [-55, 0, 0], armL: [6, 0, -16], foreL: [20, 0, 0], handL: [0, 0, 0] }),
  guard: merge(legsBent, { pelvis: [0, 20, 0], spine: [-6, 0, 0], chest: [-4, -14, 0], head: [6, -6, 0],
    armR: [55, 25, 15], foreR: [55, 0, 0], handR: [-15, -60, 60], armL: [50, -20, -20], foreL: [80, 0, 0], handL: [0, 0, 0],
    pos: [0, -0.09, 0] }),
  guardHit: merge(legsBent, { pelvis: [0, 20, 0], spine: [8, 0, 0], chest: [6, -14, 0], head: [12, -6, 0],
    armR: [50, 25, 20], foreR: [60, 0, 0], handR: [-15, -60, 60], armL: [45, -20, -25], foreL: [90, 0, 0],
    pos: [0, -0.06, 0.05] }),
  // a slash: windup (blade cocked over the right shoulder), strike (the blade crossing in front), follow-through left
  slashWind: merge(legsBent, { pelvis: [0, -20, 0], spine: [0, -10, 0], chest: [-4, -30, 0], head: [0, 25, 0],
    armR: [40, 0, 75], foreR: [80, 0, 0], handR: [0, 0, 40], armL: [30, 0, -20], foreL: [60, 0, 0] }),
  slashHit: merge(legsBent, { pelvis: [0, 15, 0], spine: [-6, 10, 0], chest: [-10, 20, 0], head: [6, -20, 0],
    armR: [85, 0, 5], foreR: [10, 0, 0], handR: [0, 0, 90], armL: [20, 0, -30], foreL: [50, 0, 0],
    pos: [0, -0.1, -0.05] }),
  slashEnd: merge(legsBent, { pelvis: [0, 35, 0], spine: [-8, 15, 0], chest: [-10, 35, 0], head: [6, -40, 0],
    armR: [70, 0, -40], foreR: [20, 0, 0], handR: [0, 0, 100], armL: [10, 0, -35], foreL: [40, 0, 0],
    pos: [0, -0.11, -0.05] }),
  // the heavy overhead: blade raised high behind the head, then hammered down in front
  heavyWind: merge(legsBent, { pelvis: [0, -10, 0], spine: [12, 0, 0], chest: [10, -10, 0], head: [-10, 8, 0],
    armR: [175, 0, 15], foreR: [60, 0, 0], handR: [40, 0, 0], armL: [165, 0, -25], foreL: [70, 0, 0],
    pos: [0, -0.02, 0.05] }),
  heavyHit: merge(legsBent, { pelvis: [0, 5, 0], spine: [-20, 0, 0], chest: [-20, -5, 0], head: [25, 0, 0],
    armR: [80, 0, 8], foreR: [5, 0, 0], handR: [-10, 0, 0], armL: [75, 0, -10], foreL: [20, 0, 0],
    thighR: [55, 0, 6], shinR: [-60, 0, 0], thighL: [-20, 0, -8], shinL: [-30, 0, 0], pos: [0, -0.2, -0.1] }),
  heavyEnd: merge(legsBent, { pelvis: [0, 5, 0], spine: [-25, 0, 0], chest: [-20, -5, 0], head: [30, 0, 0],
    armR: [45, 0, 8], foreR: [5, 0, 0], handR: [-20, 0, 0], armL: [40, 0, -10], foreL: [25, 0, 0],
    thighR: [55, 0, 6], shinR: [-60, 0, 0], thighL: [-20, 0, -8], shinL: [-30, 0, 0], pos: [0, -0.22, -0.1] }),
  // rising cut: low and back, then up past the head
  riseWind: merge(legsBent, { pelvis: [0, -25, 0], spine: [-20, 0, 0], chest: [-15, -20, 0], head: [25, 20, 0],
    armR: [-30, 0, 30], foreR: [20, 0, 0], handR: [-60, 0, 30], armL: [20, 0, -30], foreL: [50, 0, 0], pos: [0, -0.18, 0] }),
  riseHit: merge(legsBent, { pelvis: [0, 10, 0], spine: [8, 0, 0], chest: [10, 10, 0], head: [-10, -10, 0],
    armR: [150, 0, 15], foreR: [10, 0, 0], handR: [60, 0, 0], armL: [40, 0, -30], foreL: [40, 0, 0], pos: [0, -0.02, 0] }),
  // thrust: drawn back at the hip, then the whole arm and blade straight at him
  thrustWind: merge(legsBent, { pelvis: [0, -25, 0], chest: [-4, -25, 0], head: [0, 30, 0],
    armR: [-30, 0, 20], foreR: [100, 0, 0], handR: [-60, 0, 0], armL: [60, 0, -30], foreL: [40, 0, 0] }),
  thrustHit: merge(legsBent, { pelvis: [0, 5, 0], spine: [-10, 0, 0], chest: [-8, 10, 0], head: [8, -10, 0],
    armR: [88, 0, 2], foreR: [0, 0, 0], handR: [-6, 0, 0], armL: [-30, 0, -25], foreL: [30, 0, 0],
    thighR: [50, 0, 4], shinR: [-40, 0, 0], thighL: [-30, 0, -6], shinL: [-10, 0, 0], pos: [0, -0.16, -0.15] }),
  // kick: the right foot driven straight out, blade held back
  kickWind: merge(legsBent, { chest: [6, -10, 0], armR: [20, 0, 40], foreR: [60, 0, 0], armL: [30, 0, -30], foreL: [60, 0, 0],
    thighR: [70, 0, 0], shinR: [-100, 0, 0], footR: [0, 0, 0], thighL: [0, 0, 0], shinL: [-15, 0, 0], pos: [0, -0.03, 0] }),
  kickHit: merge(legsBent, { spine: [16, 0, 0], chest: [10, -10, 0], head: [-10, 0, 0], armR: [10, 0, 50], foreR: [40, 0, 0],
    armL: [40, 0, -40], foreL: [50, 0, 0], thighR: [90, 0, 0], shinR: [-5, 0, 0], footR: [-30, 0, 0],
    thighL: [-10, 0, 0], shinL: [-10, 0, 0], footL: [10, 0, 0], pos: [0, 0, 0.05] }),
  // the full spin (Bunmawashi): the arm out flat, the body turning through 360 over the active frames
  spinWind: merge(legsBent, { pelvis: [0, -40, 0], chest: [-10, -30, 0], armR: [80, 0, 70], foreR: [10, 0, 0], handR: [0, 0, 90],
    armL: [40, 0, -50], foreL: [40, 0, 0], pos: [0, -0.15, 0] }),
  // hold / charge: blade drawn back low, weight sunk
  hold: merge(legsBent, { pelvis: [0, -30, 0], spine: [-10, 0, 0], chest: [-10, -25, 0], head: [5, 40, 0],
    armR: [-20, 0, 25], foreR: [40, 0, 0], handR: [-50, 0, 40], armL: [40, 0, -15], foreL: [80, -40, 0],
    thighR: [50, -10, 10], shinR: [-70, 0, 0], thighL: [-10, 10, -10], shinL: [-40, 0, 0], pos: [0, -0.22, 0] }),
  // throw (Shiranui) / palm forward (Taimatsu): the left palm pushed at him
  palm: merge(legsBent, { pelvis: [0, 20, 0], chest: [-10, 25, 0], head: [5, -20, 0], armR: [-10, 0, 30], foreR: [40, 0, 0],
    armL: [85, 0, 5], foreL: [5, 0, 0], handL: [-70, 0, 0], pos: [0, -0.1, -0.08] }),
  // dashes: Breaker / Kikon rush lean, the charge
  dash: merge(legsBent, { spine: [-20, 0, 0], chest: [-15, -10, 0], head: [25, 0, 0], armR: [-40, 0, 25], foreR: [40, 0, 0],
    handR: [-40, 0, 0], armL: [-40, 0, -25], foreL: [40, 0, 0], thighR: [60, 0, 0], shinR: [-70, 0, 0], thighL: [-40, 0, 0],
    shinL: [-50, 0, 0], pos: [0, -0.12, 0] }),
  shoulder: merge(legsBent, { pelvis: [0, 60, 0], spine: [-10, 20, 0], chest: [-10, 20, 0], head: [10, -60, 0],
    armR: [20, 0, 10], foreR: [70, 0, 0], armL: [10, 0, -10], foreL: [90, 0, 0], pos: [0, -0.12, -0.15] }),
  // locomotion keys (a cycle: contact R, pass, contact L)
  walkA: { pelvis: [0, -6, 0], thighR: [28, 0, 0], shinR: [-8, 0, 0], thighL: [-22, 0, 0], shinL: [-25, 0, 0], footL: [20, 0, 0],
    armL: [18, 0, -6], pos: [0, -0.02, 0] },
  walkB: { pelvis: [0, 0, 0], thighR: [0, 0, 0], shinR: [-12, 0, 0], thighL: [20, 0, 0], shinL: [-60, 0, 0], footL: [10, 0, 0],
    pos: [0, 0, 0] },
  runA: { spine: [-18, 0, 0], chest: [-8, -12, 0], head: [20, 10, 0], thighR: [60, 0, 0], shinR: [-40, 0, 0], thighL: [-35, 0, 0],
    shinL: [-90, 0, 0], footL: [30, 0, 0], armR: [-50, 0, 20], foreR: [50, 0, 0], handR: [-40, 0, 0], armL: [50, 0, -10],
    foreL: [80, 0, 0], pos: [0, -0.06, 0] },
  // Hoho: a low crouch before the vanish / on arrival
  hoho: merge(legsBent, { spine: [-25, 0, 0], chest: [-15, 0, 0], head: [30, 0, 0], armR: [-30, 0, 20], foreR: [40, 0, 0],
    handR: [-40, 0, 0], armL: [-20, 0, -30], foreL: [30, 0, 0], thighR: [70, 0, 6], shinR: [-110, 0, 0], footR: [40, 0, 0],
    thighL: [40, 0, -6], shinL: [-100, 0, 0], footL: [50, 0, 0], pos: [0, -0.38, 0] }),
  step: merge(legsBent, { spine: [-10, 0, 0], thighR: [40, 0, 10], shinR: [-60, 0, 0], thighL: [10, 0, -10], shinL: [-50, 0, 0],
    pos: [0, -0.12, 0] }),
  // reactions
  flinch: merge(legsBent, { spine: [14, 0, 6], chest: [12, 12, 0], neck: [10, 0, 0], head: [15, 15, 8],
    armR: [10, 0, 35], foreR: [30, 0, 0], armL: [20, 0, -40], foreL: [40, 0, 0], pos: [0, -0.06, 0.04] }),
  stagger: merge(legsBent, { spine: [22, 0, -6], chest: [20, -10, 0], neck: [15, 0, 0], head: [25, -10, -10],
    armR: [-20, 0, 55], foreR: [40, 0, 0], armL: [-10, 0, -60], foreL: [40, 0, 0],
    thighR: [-20, 0, 6], shinR: [-30, 0, 0], thighL: [35, 0, -8], shinL: [-40, 0, 0], pos: [0, -0.08, 0.1] }),
  knockback: merge(legsBent, { spine: [30, 0, 0], chest: [25, 0, 0], neck: [20, 0, 0], head: [30, 0, 0],
    armR: [40, 0, 70], foreR: [40, 0, 0], armL: [40, 0, -70], foreL: [40, 0, 0],
    thighR: [30, 0, 6], shinR: [-60, 0, 0], thighL: [10, 0, -6], shinL: [-40, 0, 0], pos: [0, -0.12, 0.15] }),
  crumple: merge(legsBent, { spine: [-35, 0, 10], chest: [-25, 0, 0], head: [-10, 0, 10], armR: [10, 0, 10], foreR: [50, 0, 0],
    armL: [30, 0, -5], foreL: [90, 0, 0], thighR: [80, 0, 10], shinR: [-130, 0, 0], footR: [40, 0, 0],
    thighL: [60, 0, -10], shinL: [-120, 0, 0], footL: [50, 0, 0], pos: [0, -0.5, 0] }),
  air: { pelvis: [60, 0, 0], spine: [15, 0, 0], chest: [10, 0, 0], head: [20, 0, 0], armR: [120, 0, 40], foreR: [30, 0, 0],
    armL: [110, 0, -40], foreL: [30, 0, 0], thighR: [50, 0, 0], shinR: [-60, 0, 0], thighL: [20, 0, 0], shinL: [-30, 0, 0],
    pos: [0, 0.2, 0] },
  down: { pelvis: [90, 0, 0], spine: [5, 0, 0], head: [-10, 15, 0], armR: [150, 0, 30], foreR: [20, 0, 0],
    armL: [160, 0, -40], foreL: [30, 0, 0], thighR: [10, 0, 8], shinR: [-20, 0, 0], thighL: [25, 0, -8], shinL: [-40, 0, 0],
    pos: [0, -0.8, 0.2] },
  kneel: merge(legsBent, { spine: [-20, 0, 0], chest: [-10, 0, 0], head: [20, 0, 0], armR: [40, 0, 20], foreR: [40, 0, 0],
    armL: [60, 0, -20], foreL: [60, 0, 0], thighR: [90, 0, 6], shinR: [-90, 0, 0], footR: [0, 0, 0],
    thighL: [0, 0, -6], shinL: [-120, 0, 0], footL: [60, 0, 0], pos: [0, -0.45, 0] }),
  win: merge(legsBent, { spine: [6, 0, 0], chest: [6, 0, 0], head: [-5, 0, 0], armR: [10, 0, 25], foreR: [20, 0, 0], handR: [-60, 0, 0],
    armL: [10, 0, -10], foreL: [10, 0, 0], thighR: [0, -10, 4], shinR: [-5, 0, 0], thighL: [0, 10, -4], shinL: [-5, 0, 0], pos: [0, -0.01, 0] }),
} satisfies Record<string, PoseSpec>;
