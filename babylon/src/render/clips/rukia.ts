// Rukia's clips (DUEL_RUKIA §3-§4): a light, quick, one-handed fencer and a dancer who places ice. Stances per form
// (Shikai ru-stance, the cold stance at -18 / -50, zero's still, rooted stance), her guard and run, and a bespoke clip
// for every move she has, keyed in phase coordinates (pose.ts: u 0 start, 1 frame S, 2 end of active, 3 end; the
// pre-strike phases: HAKUREN's held stabs on f.hold, the Kikon's aura / flash-step dash). Pirouettes key the pelvis yaw
// in < 180 deg steps so the slerp turns the right way.
import type { Stance } from './index';
import type { Move } from '../../sim/kit';
import type { Fighter } from '../../sim/types';
import type { ClipName } from '../anim';
import { P, merge, mirror, phase, type Clip, type Euler, type PoseSpec } from '../pose';

const k = (at: number, pose: PoseSpec, ease?: 'in' | 'out' | 'io' | 'lin') => ({ at, pose, ease });
/** The pose with the pelvis turned to YAW (deg) on top of its own pelvis yaw. */
const turn = (p: PoseSpec, yaw: number): PoseSpec => {
  const pv = p.pelvis ?? [0, 0, 0];
  return merge(p, { pelvis: [pv[0], pv[1] + yaw, pv[2]] as Euler });
};

// ---------------------------------------------------------------- stances
// light on her feet: the right foot forward, knees soft, upright
const feet: PoseSpec = { thighR: [22, -6, 4], shinR: [-22, 0, 0], footR: [2, 0, 0], thighL: [-10, 14, -6], shinL: [-24, 0, 0],
  footL: [22, 0, 0], pos: [0, -0.04, 0] };
/** Shikai: side-on, the white blade held out low toward him in one hand, the left hand loose. */
const shikai = merge(feet, { pelvis: [0, 28, 0], spine: [-2, 0, 0], chest: [0, -12, 0], neck: [4, 0, 0], head: [4, -16, 0],
  armR: [48, -8, 6], foreR: [22, 0, 0], handR: [-24, 0, 0], armL: [12, 0, -16], foreL: [38, 0, 0], handL: [0, 0, 0] });
/** -18 / -50: the cold stance: the blade raised upright before her face, the left palm open beside it. */
export const coldStance = merge(feet, { pelvis: [0, 18, 0], spine: [-2, 0, 0], chest: [0, -10, 0], head: [2, -8, 0],
  armR: [40, 0, 14], foreR: [95, 0, 0], handR: [25, 70, 0], armL: [45, 0, -20], foreL: [80, -20, 0], handL: [-20, 0, 0] });
/** Zero: still, rooted, feet together, the ice blade hanging point-down at her side, the left hand open. */
export const zeroStance = { pelvis: [0, 6, 0], spine: [2, 0, 0], chest: [2, -4, 0], neck: [2, 0, 0], head: [6, -6, 0],
  armR: [4, 0, 10], foreR: [6, 0, 0], handR: [-24, 0, 0], armL: [8, 0, -22], foreL: [18, 0, 0], handL: [10, 0, 0],
  thighR: [2, 0, 3], shinR: [-3, 0, 0], thighL: [2, 0, -3], shinL: [-3, 0, 0], pos: [0, -0.005, 0] } as PoseSpec;

export const idle = shikai;
/** FORM's stance (clips/index.ts CharClips.stance). */
export const stance = (form: string): Stance => ({ idle: idleFor(form) ?? shikai, guard, guardHit, run });
export const idleFor = (form: string): PoseSpec | undefined =>
  form === 'zero' ? zeroStance : form === 'm18' || form === 'm50' ? coldStance : undefined;

/** Guard: the blade across her body, the left hand braced on its back. */
export const guard = merge(feet, { pelvis: [0, 22, 0], spine: [-6, 0, 0], chest: [-4, -14, 0], head: [6, -8, 0],
  armR: [55, 0, 0], foreR: [75, 0, 0], handR: [0, 0, -90], armL: [55, 0, -10], foreL: [85, 0, 0], handL: [0, 0, 0],
  pos: [0, -0.07, 0] });
export const guardHit = merge(guard, { spine: [6, 0, 0], chest: [6, -14, 0], head: [12, -8, 0], pos: [0, -0.05, 0.06] });
/** Run: the shunpo lean, the blade trailing low behind her, the left arm forward. */
const runA = merge(P.runA, { spine: [-24, 0, 0], chest: [-8, -6, 0], head: [26, 6, 0], armR: [-45, 0, 22], foreR: [20, 0, 0],
  handR: [-30, 0, 0], armL: [40, 0, -12], foreL: [70, 0, 0] });
const runB = merge(mirror(P.runA), { spine: [-24, 0, 0], chest: [-8, 6, 0], head: [26, -6, 0], armR: [-45, 0, 22],
  foreR: [20, 0, 0], handR: [-30, 0, 0], armL: [30, 0, -12], foreL: [70, 0, 0] });
export const run: Clip = [k(0, runA), k(1, runB), k(2, runA)];

// ---------------------------------------------------------------- key poses
const lowFeet: PoseSpec = { thighR: [40, -6, 6], shinR: [-50, 0, 0], footR: [10, 0, 0], thighL: [-14, 12, -8], shinL: [-34, 0, 0],
  footL: [30, 0, 0], pos: [0, -0.12, 0] };
const lunge: PoseSpec = { thighR: [62, 0, 4], shinR: [-58, 0, 0], footR: [0, 0, 0], thighL: [-38, 0, -6], shinL: [-6, 0, 0],
  footL: [30, 0, 0], pos: [0, -0.24, -0.2] };
const R = {
  // J1 HATSUSHIMO: a flat one-handed cut from her right across to her left; J2 KAZAHANA comes back along it
  flatR: merge(feet, { pelvis: [0, -10, 0], chest: [0, -30, 0], head: [2, 30, 0], armR: [90, -80, 0], foreR: [25, 0, 0],
    handR: [-20, 0, 0], armL: [20, 0, -25], foreL: [50, 0, 0] }),
  flatF: merge(feet, { pelvis: [0, 20, 0], spine: [-6, 8, 0], chest: [-6, 18, 0], head: [4, -24, 0], armR: [90, 10, 0],
    foreR: [0, 0, 0], handR: [-20, 0, 0], armL: [10, 0, -35], foreL: [40, 0, 0], pos: [0, -0.07, -0.06] }),
  flatL: merge(feet, { pelvis: [0, 40, 0], spine: [-6, 14, 0], chest: [-6, 34, 0], head: [4, -44, 0], armR: [90, 75, 0],
    foreR: [10, 0, 0], handR: [-20, 0, 0], armL: [6, 0, -40], foreL: [30, 0, 0], pos: [0, -0.08, -0.06] }),
  // the pirouette (J3 MAI-SODE, the Kikon's strike): the arm out flat, the blade level
  spin: merge(lowFeet, { spine: [-6, 0, 0], chest: [-4, -10, 0], head: [4, 10, 0], armR: [90, -85, 0], foreR: [0, 0, 0],
    handR: [-20, 0, 0], armL: [90, 85, 0], foreL: [10, 0, 0] }),
  // K1 SHIMO-TSUKI / SHIRAFUNE: en garde (the blade drawn back level by the cheek, the left arm up behind), the lunge
  garde: merge(feet, { pelvis: [0, 40, 0], chest: [0, -20, 0], head: [0, -20, 0], armR: [40, 0, 30], foreR: [110, 0, 0],
    handR: [-70, 0, 0], armL: [-20, 0, -60], foreL: [60, 0, 0], pos: [0, -0.06, 0.04] }),
  lunge: merge(lunge, { pelvis: [0, 40, 0], spine: [-12, 0, 0], chest: [-6, -18, 0], head: [10, -22, 0], armR: [86, 18, 0],
    foreR: [0, 0, 0], handR: [-6, 0, 0], armL: [-40, 0, -40], foreL: [10, 0, 0] }),
  // K2 HYORIN: crouched with the blade low behind her right hip, then rising through a turn, the blade swept up overhead
  ringLow: merge(lowFeet, { pelvis: [0, -30, 0], spine: [-18, 0, 0], chest: [-10, -20, 0], head: [16, 30, 0], armR: [-30, 0, 30],
    foreR: [20, 0, 0], handR: [-40, 0, 40], armL: [30, 0, -30], foreL: [50, 0, 0], pos: [0, -0.2, 0] }),
  ringHigh: merge(feet, { spine: [6, 0, 0], chest: [8, 0, 0], head: [-8, 0, 0], armR: [160, 0, 20], foreR: [10, 0, 0],
    handR: [40, 0, 0], armL: [60, 0, -70], foreL: [20, 0, 0], thighL: [-6, 0, -4], shinL: [-40, 0, 0], footL: [40, 0, 0],
    pos: [0, 0.03, 0] }),
  // K3 NADARE: both hands raised overhead, the blade dropped straight down to the plaza
  dropUp: merge(feet, { pelvis: [0, 0, 0], spine: [10, 0, 0], chest: [8, 0, 0], head: [-8, 0, 0], armR: [170, 0, 10],
    foreR: [50, 0, 0], handR: [40, 0, 0], armL: [170, 0, -10], foreL: [55, 0, 0], handL: [40, 0, 0], pos: [0, 0.02, 0.04] }),
  dropDown: merge(lunge, { pelvis: [0, 0, 0], spine: [-28, 0, 0], chest: [-20, 0, 0], head: [28, 0, 0], armR: [105, 0, 8],
    foreR: [5, 0, 0], handR: [-10, 0, 0], armL: [105, 0, -8], foreL: [10, 0, 0], handL: [-10, 0, 0], pos: [0, -0.3, -0.12] }),
  // TSUKISHIRO: the dance: up on her toes, the blade raised upright, then pointed down at the circle under him
  danceUp: merge(feet, { spine: [6, 0, 0], chest: [6, 0, 0], head: [-6, 0, 0], armR: [150, 0, 30], foreR: [20, 0, 0],
    handR: [30, 0, 0], armL: [80, 0, -80], foreL: [10, 0, 0], thighR: [0, 0, 4], shinR: [-6, 0, 0], footR: [-20, 0, 0],
    thighL: [10, 0, -4], shinL: [-50, 0, 0], footL: [30, 0, 0], pos: [0, 0.04, 0] }),
  point: merge(feet, { pelvis: [0, 30, 0], spine: [-4, 0, 0], chest: [-2, -18, 0], head: [8, -14, 0], armR: [75, 10, 4],
    foreR: [0, 0, 0], handR: [-25, 0, 0], armL: [30, 0, -70], foreL: [20, 0, 0] }),
  // HAKUREN: stabs into the plaza in front (raise / stab), then the blade levelled at him for the wave
  stabUp: merge(lowFeet, { spine: [-10, 0, 0], chest: [-6, -10, 0], head: [12, 0, 0], armR: [80, 0, 12], foreR: [60, 0, 0],
    handR: [-150, 0, 0], armL: [40, 0, -30], foreL: [60, 0, 0] }),
  stab: merge(lowFeet, { spine: [-26, 0, 0], chest: [-14, -6, 0], head: [24, 0, 0], armR: [60, 0, 12], foreR: [8, 0, 0],
    handR: [-60, 0, 0], armL: [30, 0, -30], foreL: [50, 0, 0], pos: [0, -0.2, 0] }),
  aim: merge(lunge, { pelvis: [0, 30, 0], spine: [-6, 0, 0], chest: [-4, -20, 0], head: [6, -14, 0], armR: [88, 10, 0],
    foreR: [0, 0, 0], handR: [-4, 0, 0], armL: [80, -30, -10], foreL: [30, 0, 0], handL: [-20, 0, 0], pos: [0, -0.16, -0.1] }),
  // both hands driving the point into the plaza (HYOSHIN, HYOKA, REIDO)
  stab2Up: merge(feet, { spine: [4, 0, 0], head: [-4, 0, 0], armR: [80, 0, 8], foreR: [40, 0, 0], handR: [-140, 0, 0],
    armL: [80, 0, -8], foreL: [40, 0, 0], handL: [-140, 0, 0], pos: [0, 0.02, 0] }),
  stab2: merge(lowFeet, { spine: [-30, 0, 0], chest: [-16, 0, 0], head: [28, 0, 0], armR: [60, 0, 8], foreR: [10, 0, 0],
    handR: [-55, 0, 0], armL: [60, 0, -8], foreL: [10, 0, 0], handL: [-55, 0, 0], thighR: [70, -6, 6], shinR: [-90, 0, 0],
    thighL: [10, 12, -8], shinL: [-80, 0, 0], footL: [40, 0, 0], pos: [0, -0.34, 0] }),
  // REIDO TOKETSU: upright, the blade driven straight down before her, the left arm swept out wide, palm down
  reido: { pelvis: [0, 0, 0], spine: [-4, 0, 0], chest: [-2, 0, 0], head: [10, 0, 0], armR: [40, 0, 6], foreR: [30, 0, 0],
    handR: [-70, 0, 0], armL: [20, 0, -80], foreL: [4, 0, 0], handL: [-10, 0, 0], thighR: [10, 0, 6], shinR: [-14, 0, 0],
    thighL: [10, 0, -6], shinL: [-14, 0, 0], pos: [0, -0.04, 0] } as PoseSpec,
  // TOSHU / zero's J2: the frozen left palm driven at him, the blade held back
  palmBack: merge(feet, { pelvis: [0, 30, 0], chest: [0, 10, 0], head: [2, -20, 0], armR: [20, 0, 30], foreR: [40, 0, 0],
    armL: [10, 0, -10], foreL: [110, 0, 0], handL: [-50, 0, 0] }),
  palm: merge(lunge, { pelvis: [0, -20, 0], spine: [-8, -10, 0], chest: [-10, -20, 0], head: [6, 20, 0], armR: [-20, 0, 30],
    foreR: [40, 0, 0], armL: [88, 0, 4], foreL: [4, 0, 0], handL: [-75, 0, 0] }),
  // HAKKA NO TOGAME: the blade raised straight up (the pillar), then levelled at him
  hakkaUp: merge(feet, { pelvis: [0, 10, 0], spine: [4, 0, 0], chest: [4, -6, 0], head: [-4, -6, 0], armR: [165, 0, 6],
    foreR: [8, 0, 0], handR: [-13, 0, 0], armL: [60, 0, -40], foreL: [70, 0, 0], handL: [-20, 0, 0] }),
  // HAINAWA (the Breaker): the left hand thrown forward, two fingers out
  kido: merge(P.palm, { handL: [-10, 0, 0], pos: [0, -0.06, -0.06] }),
};

// ---------------------------------------------------------------- clips per stance
function build(I: PoseSpec) {
  const spinKeys = (t0: number, t1: number, base: PoseSpec, from = 0): Clip => {
    const n = 3, out: Clip = [];
    for (let i = 1; i <= n; i++) out.push(k(t0 + ((t1 - t0) * i) / n, turn(base, from + (360 * i) / n), i === 1 ? 'out' : 'lin'));
    return out;
  };
  return {
    q1: [k(0, I), k(0.85, R.flatR, 'out'), k(1, R.flatF, 'in'), k(2, R.flatL, 'out'), k(3, I)],
    q2: [k(0, R.flatL), k(0.85, R.flatL), k(1, R.flatF, 'in'), k(2, R.flatR, 'out'), k(3, I)],
    spin: [k(0, I), k(0.7, turn(R.spin, -40), 'out'), ...spinKeys(0.7, 2.2, R.spin, -40), k(3, I)],
    lunge: [k(0, I), k(0.8, R.garde, 'out'), k(1, R.lunge, 'out'), k(2, R.lunge), k(3, I)],
    ring: [k(0, I), k(0.6, R.ringLow, 'out'), k(1, turn(R.ringHigh, -150), 'out'), k(1.5, turn(R.ringHigh, -270), 'lin'),
      k(2, turn(R.ringHigh, -390), 'lin'), k(3, I)],
    drop: [k(0, I), k(0.85, R.dropUp, 'out'), k(1, R.dropDown, 'in'), k(2, R.dropDown), k(3, I)],
    tsukishiro: [k(0, I), k(0.3, turn(R.danceUp, 120), 'out'), k(0.55, turn(R.danceUp, 240), 'lin'), k(0.8, turn(R.danceUp, 360), 'lin'),
      k(1, R.point, 'out'), k(2, R.point), k(3, I)],
    stabs: [k(0, R.stab), k(0.45, R.stabUp, 'out'), k(0.8, R.stabUp), k(1, R.stab, 'in')],
    hakuren: [k(0, R.stabUp), k(0.8, R.garde, 'out'), k(1, R.aim, 'out'), k(2, R.aim), k(3, I)],
    stab: [k(0, I), k(0.8, R.stabUp, 'out'), k(1, R.stab, 'in'), k(2, R.stab), k(3, I)],
    stab2: [k(0, I), k(0.8, R.stab2Up, 'out'), k(1, R.stab2, 'in'), k(2, R.stab2), k(3, I)],
    flower: [k(0, I), k(0.8, R.stab2Up, 'out'), k(1, R.stab2, 'in'), k(2, R.stab2), k(3, I)],
    reido: [k(0, I), k(0.7, R.stab2Up, 'out'), k(1, R.reido, 'in'), k(2, R.reido), k(3, I)],
    palm: [k(0, I), k(0.8, R.palmBack, 'out'), k(1, R.palm, 'out'), k(2, R.palm), k(3, I)],
    hakka: [k(0, I), k(0.25, R.hakkaUp, 'out'), k(0.85, R.hakkaUp), k(1, R.aim, 'out'), k(2, R.aim), k(3, I)],
    kido: [k(0, I), k(0.8, R.palmBack, 'out'), k(1, R.kido, 'out'), k(2, R.kido), k(3, I)],
    shunpo: [k(0, runA), k(1, runA)],
    crouch: [k(0, P.hoho), k(1, P.hoho)],
  } satisfies Record<string, Clip>;
}
type Clips = ReturnType<typeof build>;
/** The art-contract clip name -> clip (the main phase; sp moves too: their clip2 is the strike). */
const TABLE: Record<string, keyof Clips> = {
  'ru-q1': 'q1', 'ru-q2': 'q2', 'ru-spin': 'spin', 'ru-spin-50': 'spin', 'ru-thrust': 'lunge', 'ru-ring': 'ring', 'ru-drop': 'drop',
  'ru-tsukishiro': 'tsukishiro', 'ru-hakuren': 'hakuren', 'ru-shirafune': 'lunge', 'ru-hainawa': 'kido',
  'ru-palm': 'palm', 'ru-palm-50': 'palm', 'ru-flower': 'flower', 'ru-flower-50': 'flower', 'ru-stab': 'stab',
  'ru-stab-2h': 'stab2', 'ru-reido': 'reido', 'ru-hakka': 'hakka',
};
const CACHE = new Map<PoseSpec, Clips>();

export const move = (mv: Move, f: Fighter): [Clip, number] | null => moveAt(mv, f, idleFor(f.form) ?? shikai);
function moveAt(mv: Move, f: Fighter, idle: PoseSpec): [Clip, number] | null {
  let c = CACHE.get(idle);
  if (!c) { c = build(idle); CACHE.set(idle, c); }
  switch (f.phase) {
    case 'hold': {                                                   // HAKUREN's charge: a stab every `per` frames
      const per = (mv.params.per as number | undefined) ?? 16;
      return [c.stabs, (f.hold % per) / per];
    }
    case 'aura': return mv.kind === 'kikon' ? [c.crouch, 0] : null;  // (the Breaker's aura / dash stay generic)
    case 'dash': case 'follow': return mv.kind === 'kikon' ? [c.shunpo, 0] : null;
  }
  const name = TABLE[mv.clip2 ?? mv.clip ?? ''];
  return name ? [c[name], phase(mv, f.sf).u] : null;
}
export function clipFor(_c: string, _mv: Move): ClipName | null { return null; }
