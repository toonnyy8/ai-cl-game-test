// Kenpachi's clips (B2-ken; BABYLON_LOOK "Clips, by screen time"): per-form stances (base slouch, KATATE the cleaver on
// the shoulder, RYOTE / NOMIHOSE two-handed jodan, the Bankai's and KATAUDE's feral crouch), locomotion (walk / run with
// the blade on the shoulder; the oni prowls), and a bespoke clip for every move his kits use. Keys are posed by the
// sword (util-ken.ts grip: the fist, the blade's direction, both hands on the handle) in phase coordinates (u: 1 = frame
// S, 2 = end of the active frames, 3 = the end; the rush phases in frames of f.hold). Frame data is never touched.
import type { Move } from '../../sim/kit';
import type { ClipName } from '../anim';
import { merge, mirror, P, type Clip, type Euler, type PoseSpec } from '../pose';
import { ken, KEN_GRIP } from '../bodies/ken';
import type { Stance } from './index';
import { grip, gripFrame, type Grip, type V3 } from './util-ken';

export const idle = P.idleKen;
/** The generic table, for anything without a bespoke clip below. */
export function clipFor(c: string, mv: Move): ClipName | null {
  if (mv.hits.length > 1) return null;
  if (c.endsWith('q3')) return 'spin';
  if (c.endsWith('f1')) return 'heavy';
  if (c.includes('buttagiru')) return 'leap';
  if (c.includes('shoulder')) return 'shoulder';
  if (c.includes('charge')) return 'thrust';
  return null;
}

// ---------------------------------------------------------------- posing helpers
const GF = gripFrame(KEN_GRIP), SP = ken.spec;
type Ease = 'in' | 'out' | 'io' | 'lin';
const k = (at: number, pose: PoseSpec, ease?: Ease) => ({ at, pose, ease });
/** A key: BODY (torso, legs, pos, a free left arm) with the weapon placed by G (chest space unless G says root). */
const K = (body: PoseSpec, g?: Grip): PoseSpec => (g ? grip(SP, GF, body, { space: 'chest', ...g }) : body);
const g1 = (at: V3, dir: V3, o: Partial<Grip> = {}): Grip => ({ at, dir, ...o });
const g2 = (at: V3, dir: V3, o: Partial<Grip> = {}): Grip => ({ at, dir, two: 0.22, ...o });
const root = (at: V3, dir: V3, o: Partial<Grip> = {}): Grip => ({ at, dir, space: 'root', ...o });
const LEGS = ['pelvis', 'thighR', 'shinR', 'footR', 'thighL', 'shinL', 'footL'] as const;
const legsOf = (p: PoseSpec): PoseSpec => { const o: PoseSpec = {}; for (const b of LEGS) if (p[b]) o[b] = p[b]; if (p.pos) o.pos = p.pos; return o; };
const upperOf = (p: PoseSpec): PoseSpec => { const o: PoseSpec = { ...p }; for (const b of LEGS) delete o[b]; delete o.pos; return o; };
const add = (e: Euler | undefined, d: Euler): Euler => [(e?.[0] ?? 0) + d[0], (e?.[1] ?? 0) + d[1], (e?.[2] ?? 0) + d[2]];

// legs (pose.ts: thighs +x forward, +z out to his right for R / -z for L; knees bend -x)
const wide: PoseSpec = { thighR: [22, -10, 10], shinR: [-30, 0, 0], footR: [8, 0, -6], thighL: [-6, 12, -12], shinL: [-26, 0, 0],
  footL: [26, 0, 8], pos: [0, -0.06, 0] };
const lunge = (d = 1): PoseSpec => ({ thighR: [55 * d, -6, 8], shinR: [-58 * d, 0, 0], footR: [6, 0, 0], thighL: [-30 * d, 8, -10],
  shinL: [-22 * d, 0, 0], footL: [30 * d, 0, 0], pos: [0, -0.16 * d, -0.06 * d] });
const deep: PoseSpec = { thighR: [70, -10, 16], shinR: [-95, 0, 0], footR: [25, 0, 0], thighL: [5, 14, -20], shinL: [-80, 0, 0],
  footL: [55, 0, 0], pos: [0, -0.34, 0] };
const toes: PoseSpec = { thighR: [10, -6, 6], shinR: [-6, 0, 0], footR: [-30, 0, 0], thighL: [-14, 8, -6], shinL: [-8, 0, 0],
  footL: [-20, 0, 0], pos: [0, 0.06, 0.02] };
const air: PoseSpec = { thighR: [70, 0, 8], shinR: [-100, 0, 0], footR: [20, 0, 0], thighL: [30, 0, -8], shinL: [-90, 0, 0],
  footL: [30, 0, 0] };
const kendo: PoseSpec = { thighR: [24, -4, 4], shinR: [-24, 0, 0], footR: [2, 0, 0], thighL: [-18, 6, -5], shinL: [-16, 0, 0],
  footL: [32, 0, 0], pos: [0, -0.05, 0] };
const feralLegs: PoseSpec = { thighR: [62, -12, 16], shinR: [-86, 0, 0], footR: [24, 0, -4], thighL: [-14, 16, -18], shinL: [-72, 0, 0],
  footL: [52, 0, 6], pos: [0, -0.3, 0.02] };

// ---------------------------------------------------------------- the stances
const looseL: PoseSpec = { armL: [8, 0, -14], foreL: [22, 0, 0], handL: [0, 0, 0] };
/** Base: the slouch, the long blade hanging from a loose hand, its point near the ground; the grin, chin down. */
const baseIdle = K(merge(wide, looseL, { pelvis: [0, 14, 0], spine: [-6, 0, 0], chest: [-6, -10, 4], neck: [8, 0, 0], head: [-2, -6, -5] }),
  root([0.42, 0.86, -0.1], [0.32, -0.62, -0.72], { pole: [1, -0.3, 0.8] }));
/** The blade on the right shoulder, its back on the shoulder, the point behind him (walks, runs, KATATE's stance). */
const onShoulder = g1([0.3, 0.02, -0.32], [0.16, 0.55, 1], { edge: [0.2, 1, -0.4], pole: [1, -0.8, -0.2] });
const katateIdle = K(merge(wide, looseL, { pelvis: [0, 16, 0], spine: [-4, 0, 0], chest: [-4, -12, 3], neck: [6, 0, 0], head: [0, -8, -4],
  armL: [10, 0, -18], foreL: [30, 0, 0] }), onShoulder);
/** RYOTE / NOMIHOSE: jodan, both hands over the brow, the cleaver up and back, the tassel hanging in front. */
const jodan = g2([0.14, 0.72, -0.26], [0.06, 0.75, 0.66], { edge: [0, 0.6, -1], pole: [1, -0.2, 0.3], poleL: [-1, -0.5, 0.2] });
const ryoteIdle = K(merge(kendo, { pelvis: [0, 8, 0], spine: [2, 0, 0], chest: [4, -6, 0], neck: [-2, 0, 0], head: [-6, -4, 0] }), jodan);
const nomihoseIdle = K(merge(kendo, { pelvis: [0, 10, 0], spine: [-6, 0, 0], chest: [-2, -6, 0], neck: [6, 0, 0], head: [-2, -4, 0],
  pos: [0, -0.1, 0] }), g2([0.14, 0.66, -0.3], [0.06, 0.7, 0.72], { edge: [0, 0.6, -1], pole: [1, -0.2, 0.3], poleL: [-1, -0.5, 0.2] }));
/** The Bankai and KATAUDE (the feral pass): a deep forward crouch, back rounded, head low and thrust out, the left hand
 *  a loose claw, the broken cleaver dragged behind, tip to the floor. */
const feralBody: PoseSpec = merge(feralLegs, { pelvis: [-6, 18, 0], spine: [-30, 0, 0], chest: [-20, -8, 0], neck: [18, 0, 0],
  head: [34, -6, 0], armL: [45, 0, -24], foreL: [55, 0, 0], handL: [-30, 0, 20] });
const feralIdle = K(feralBody, root([0.5, 0.64, 0.12], [0.3, -0.42, 0.86], { pole: [1, 0, 0.6] }));
const feralGuard = K(merge(feralLegs, { pelvis: [-4, 26, 0], spine: [-34, 0, 0], chest: [-16, -18, 0], neck: [16, 0, 0], head: [30, -8, 0],
  armL: [70, 10, -10], foreL: [110, 0, 0], handL: [-20, 0, 0], pos: [0, -0.36, 0.04] }),
  g1([0.2, -0.05, -0.42], [-1, 0.15, -0.15], { edge: [0, 0, -1], pole: [1, -0.4, 0.3] }));
const feralGuardHit = merge(feralGuard, { spine: [-22, 0, 0], head: [20, -8, 0], pos: [0, -0.32, 0.1] });

/** Walk / run keys at AT: the legs of the shared cycle SRC under an UPPER body (the blade placed), the left arm swung. */
function cycle(src: PoseSpec[], upper: PoseSpec, swingL: number, lean: Euler = [0, 0, 0]): Clip {
  return src.map((s, i) => {
    const p = merge(legsOf(s), upperOf(upper), { spine: add(upper.spine, lean) });
    if (swingL) p.armL = add(upper.armL, [(i % 2 ? 0 : i % 4 ? -1 : 1) * swingL, 0, 0]);
    return k(i, p, 'lin');
  });
}
const WALK_SRC = [P.walkA, P.walkB, mirror(P.walkA), mirror(P.walkB), P.walkA];
const RUN_SRC = [P.runA, mirror(P.runA), P.runA];
const swagger = K(merge(looseL, { spine: [-4, 0, 0], chest: [-4, -6, 0], neck: [6, 0, 0], head: [0, -4, 0] }), onShoulder);
const runUpper = K(merge(looseL, { spine: [-16, 0, 0], chest: [-8, -8, 0], neck: [14, 0, 0], head: [12, 0, 0], armL: [0, 0, -16], foreL: [70, 0, 0] }),
  onShoulder);
const walkShoulder = cycle(WALK_SRC, swagger, 22);
const runShoulder = cycle(RUN_SRC, runUpper, 40);
const walkJodan = cycle(WALK_SRC, upperOf(ryoteIdle), 0);
const sink = (p: PoseSpec): PoseSpec => merge(p, { thighR: add(p.thighR, [34, 0, 6]), shinR: add(p.shinR, [-56, 0, 0]),
  thighL: add(p.thighL, [34, 0, -6]), shinL: add(p.shinL, [-56, 0, 0]), footR: add(p.footR, [20, 0, 0]), footL: add(p.footL, [20, 0, 0]),
  pos: [p.pos?.[0] ?? 0, (p.pos?.[1] ?? 0) - 0.26, 0] });
const prowl: Clip = WALK_SRC.map((s, i) => k(i, merge(upperOf(feralIdle), sink(legsOf(s))), 'lin'));
const oniRun: Clip = RUN_SRC.map((s, i) => k(i, merge(upperOf(feralIdle), sink(legsOf(s)), { spine: [-42, 0, 0], head: [44, -6, 0] }), 'lin'));

const feralSt: Stance = { idle: feralIdle, guard: feralGuard, guardHit: feralGuardHit, walk: prowl, run: oniRun, step: feralGuardHit };
const STANCES: Record<string, Stance> = {
  base: { idle: baseIdle, walk: walkShoulder, run: runShoulder },
  nozarashi: { idle: katateIdle, walk: walkShoulder, run: runShoulder },
  ryote: { idle: ryoteIdle, walk: walkJodan, run: runShoulder },
  nomihose: { idle: nomihoseIdle, walk: walkJodan, run: runShoulder },
  bankai: feralSt, kataude: feralSt,
};
export const stance = (form: string): Stance => STANCES[form] ?? STANCES.base;
const idleIn = (form: string) => stance(form).idle!;
const feral = (form: string) => form === 'bankai' || form === 'kataude';

// ---------------------------------------------------------------- the moves
/** A strike: IDLE -> keys -> IDLE at u 3. */
const strike = (I: PoseSpec, ...keys: [number, PoseSpec, Ease?][]): Clip => [k(0, I), ...keys.map(([a, p, e]) => k(a, p, e)), k(3, I, 'io')];
/** Head low (the street fighter's hacks): the chest folded over, the eyes up under the brows. */
const hunch = (twist: number, lean = -18): PoseSpec => ({ pelvis: [0, twist * 0.5, 0], spine: [lean, twist * 0.25, 0],
  chest: [lean * 0.6, twist * 0.5, 0], neck: [10, -twist * 0.3, 0], head: [-lean * 0.7, -twist * 0.4, 0] });
const shoulderLean = (d: number): PoseSpec => merge(lunge(d), { pelvis: [0, 50 + 20 * (d - 0.8), 0], spine: [-16, 20, 0], chest: [-10, 20, 0],
  neck: [10, -30, 0], head: [10, -40 - 20 * (d - 0.8), 0], armL: [10, 0, -10], foreL: [90, 0, 0] });
const blade_back = g1([0.4, -0.4, 0.3], [0.2, -0.5, 0.85]);
const runLow = (s: PoseSpec) => K(merge(legsOf(s), { spine: [-28, 0, 0], chest: [-12, -10, 0], neck: [16, 0, 0], head: [20, 10, 0], armL: [-40, 0, -20],
  foreL: [70, 0, 0], pos: [0, -0.14, 0] }), g1([0.52, -0.45, 0.15], [0.3, -0.35, 0.9], { pole: [1, 0, 0.6] }));
const overhead2 = g2([0.1, 0.9, 0.0], [0.05, 0.25, 0.97], { pole: [1, 0.3, 0], poleL: [-1, 0.3, 0] });

type Builder = (I: PoseSpec, mv: Move) => Clip;
const B: Record<string, Builder> = {
  // J1 ARAGIRI: a lazy wide hack from high right down across to low left, lunging, head low
  'ke-j1': (I) => strike(I,
    [0.75, K(merge(wide, hunch(-30, -6), { armL: [30, 0, -30], foreL: [40, 0, 0] }), g1([0.42, 0.6, 0.05], [0.4, 0.55, 0.75], { pole: [1, 0.2, 0.3] })), 'out'],
    [1, K(merge(lunge(), hunch(10, -20), { armL: [-10, 0, -40], foreL: [30, 0, 0] }), g1([0.18, 0.1, -0.62], [-0.55, -0.25, -0.8])), 'in'],
    [2, K(merge(lunge(), hunch(34, -26), { armL: [-20, 0, -45], foreL: [30, 0, 0] }), g1([-0.28, -0.25, -0.45], [-0.7, -0.6, 0.2], { pole: [0.6, -1, 0.2] })), 'out']),
  // J2 KAESHIGIRI: the backhand, back across from low left up to high right
  'ke-j2': (I) => strike(I,
    [0.75, K(merge(lunge(0.6), hunch(36, -20), { armL: [-10, 0, -40], foreL: [30, 0, 0] }), g1([-0.25, -0.18, -0.42], [-0.75, -0.45, 0.3], { pole: [0.5, -1, 0] })), 'out'],
    [1, K(merge(lunge(0.8), hunch(0, -16), { armL: [20, 0, -40], foreL: [40, 0, 0] }), g1([0.3, 0.12, -0.62], [0.7, 0.2, -0.65], { edge: [0, 1, 0] })), 'in'],
    [2, K(merge(lunge(0.7), hunch(-30, -10), { armL: [30, 0, -40], foreL: [40, 0, 0] }), g1([0.55, 0.45, -0.2], [0.55, 0.7, 0.45], { edge: [1, 0, 0], pole: [1, -0.6, 0.2] })), 'out']),
  // J3 KENKA-GERI: the street fighter's front kick to the gut, the blade swung out wide behind
  'ke-j3': (I) => {
    const hit = K(merge(P.kickHit, { pelvis: [0, -14, 0], spine: [18, 0, 0], chest: [10, 0, 0], head: [-14, 0, 0], armL: [50, 0, -50], foreL: [50, 0, 0] }),
      g1([0.72, -0.1, 0.18], [0.7, -0.3, 0.65]));
    return strike(I, [0.8, K(merge(P.kickWind, { pelvis: [0, -10, 0], spine: [6, 0, 0], chest: [6, 0, 0], head: [0, 0, 0], armL: [40, 0, -40], foreL: [60, 0, 0] }),
      g1([0.62, -0.15, 0.1], [0.6, -0.4, 0.7])), 'out'], [1, hit, 'out'], [2, hit]);
  },
  // K1 OBURI: the huge two-handed swing: wound high over the right shoulder, hammered across and down
  'ke-k1': (I) => strike(I,
    [0.8, K(merge(toes, { pelvis: [0, -25, 0], spine: [10, -8, 0], chest: [8, -22, 0], neck: [-4, 0, 0], head: [-6, 24, 0] }),
      g2([0.25, 0.75, 0.1], [0.3, 0.45, 0.85], { pole: [1, 0.2, 0.2], poleL: [-1, 0.2, -0.3] })), 'out'],
    [1, K(merge(lunge(), hunch(14, -24)), g2([0.05, 0.05, -0.62], [-0.3, -0.25, -0.92])), 'in'],
    [2, K(merge(lunge(1.1), hunch(36, -32)), g2([-0.25, -0.35, -0.42], [-0.6, -0.75, -0.2], { pole: [0.6, -1, 0.3] })), 'out']),
  // K2 KIRIAGE: from the floor up: the point dragged low behind him, then ripped up through the front
  'ke-k2': (I) => strike(I,
    [0.8, K(merge(deep, { pelvis: [0, -30, 0], spine: [-24, -10, 0], chest: [-12, -20, 0], neck: [8, 0, 0], head: [20, 26, 0], armL: [30, 0, -40], foreL: [40, 0, 0] }),
      g1([0.45, -0.55, 0.15], [0.3, -0.5, 0.82], { pole: [1, -0.2, 0.6] })), 'out'],
    [1, K(merge(lunge(0.6), { pelvis: [0, 0, 0], spine: [-6, 6, 0], chest: [0, 10, 0], neck: [0, 0, 0], head: [6, -8, 0], armL: [20, 0, -50], foreL: [30, 0, 0] }),
      g1([0.25, 0.25, -0.62], [0.15, 0.75, -0.65], { edge: [0, 0, -1] })), 'in'],
    [2, K(merge(toes, { pelvis: [0, 12, 0], spine: [8, 6, 0], chest: [10, 10, 0], head: [-14, -8, 0], armL: [10, 0, -50], foreL: [30, 0, 0] }),
      g1([0.3, 0.95, -0.2], [0.1, 0.9, 0.4], { edge: [0, 0, -1], pole: [1, 0, 0.3] })), 'out']),
  // K3 BUNMAWASHI: the full spin, the blade out flat at arm's length (the chest carries it round), keyed every 90 deg
  'ke-k3': (I) => {
    const arm = g1([0.82, 0.12, -0.25], [0.75, -0.05, -0.65], { edge: [0, 0, -1], pole: [0.3, -1, 0.3] });
    const at = (yaw: number) => K(merge(lunge(0.7), { pelvis: [0, yaw, 0], spine: [-14, 0, 0], chest: [-10, 0, 0], neck: [8, 0, 0], head: [6, 0, 0],
      armL: [40, 0, -70], foreL: [30, 0, 0] }), arm);
    return strike(I,
      [0.9, K(merge(deep, { pelvis: [0, -60, 0], spine: [-14, -16, 0], chest: [-8, -24, 0], neck: [6, 0, 0], head: [10, 40, 0], armL: [60, 0, -60], foreL: [70, 0, 0] }),
        g1([0.6, -0.1, 0.4], [0.4, -0.15, 0.9], { pole: [0.3, -1, 0.5] })), 'out'],
      [1, at(0), 'in'], [1.25, at(90), 'lin'], [1.5, at(180), 'lin'], [1.75, at(270), 'lin'], [2, at(360), 'out'], [2.4, at(360), 'io']);
  },
  // the stance cut (KITTE MIRO YO's release, the Kikon's strike, LEAP CLEAVE's cleave): a huge cross-body cut
  'ke-stance-cut': (I) => strike(I,
    [0.7, K(merge(wide, { pelvis: [0, -35, 0], spine: [0, -10, 0], chest: [4, -30, 0], neck: [0, 0, 0], head: [-4, 40, 0], armL: [40, 0, -60], foreL: [20, 0, 0] }),
      g1([0.62, 0.55, 0.25], [0.55, 0.4, 0.75], { pole: [1, 0, 0.3] })), 'out'],
    [1, K(merge(lunge(), hunch(10, -16), { armL: [-20, 0, -50], foreL: [20, 0, 0] }), g1([0.22, 0.12, -0.7], [-0.85, -0.05, -0.55], { edge: [0, 0, -1] })), 'in'],
    [2, K(merge(lunge(1.1), hunch(55, -24), { armL: [-30, 0, -40], foreL: [20, 0, 0] }), g1([-0.45, 0.0, -0.3], [-0.6, -0.35, 0.7], { pole: [0.5, -1, 0.3] })), 'out']),
  // BUTTAGIRU: crouch, leap with the blade up in both hands, hammer it down where he lands
  'ke-buttagiru': (I) => strike(I,
    [0.25, K(merge(deep, hunch(0, -30)), g2([0.25, -0.1, -0.35], [0.2, -0.6, -0.75])), 'out'],
    [0.7, K(merge(air, { pelvis: [0, 0, 0], spine: [16, 0, 0], chest: [14, 0, 0], neck: [-6, 0, 0], head: [-10, 0, 0], pos: [0, 0.75, 0] }), overhead2), 'out'],
    [1, K(merge(deep, hunch(0, -34)), g2([0.05, -0.05, -0.62], [0, -0.45, -0.9])), 'in'],
    [2, K(merge(deep, hunch(0, -40), { pos: [0, -0.4, 0] }), g2([0.05, -0.35, -0.55], [0, -0.85, -0.5])), 'out']),
  // the charge (ORE NI KIRENEE MON WA NEE): bent low, the blade dragged behind, legs driving through the dash
  'ke-charge': (I) => strike(I, [0.8, runLow(deep), 'out'], [1, runLow(P.runA), 'lin'], [1.25, runLow(mirror(P.runA)), 'lin'],
    [1.5, runLow(P.runA), 'lin'], [1.75, runLow(mirror(P.runA)), 'lin'], [2, runLow(P.runA), 'lin']),
  // the flurry: alternating hacks on its hit windows (fore / back / fore / back), the last a rising launcher
  'ke-flurry': (I, mv) => {
    const u = (f: number) => 1 + (f - mv.s) / mv.a;
    const fore = K(merge(lunge(0.8), hunch(20, -18)), g1([0.0, 0.05, -0.62], [-0.8, -0.3, -0.5]));
    const back = K(merge(lunge(0.8), hunch(-20, -18)), g1([0.35, 0.15, -0.55], [0.8, 0.1, -0.55], { edge: [0, 1, 0] }));
    const hiR = K(merge(lunge(0.6), hunch(-25, -8)), g1([0.5, 0.5, 0.0], [0.4, 0.6, 0.7]));
    const loL = K(merge(lunge(0.6), hunch(30, -20)), g1([-0.3, -0.25, -0.4], [-0.7, -0.6, 0.2], { pole: [0.6, -1, 0.2] }));
    const keys: [number, PoseSpec, Ease?][] = [];
    mv.hits.forEach((h, i) => {
      const prev = i ? mv.hits[i - 1].to : 0, mid = u(prev + (h.from - prev) * 0.55);
      if (i === mv.hits.length - 1) {
        keys.push([mid, K(merge(deep, hunch(-20, -26)), g1([0.4, -0.5, 0.1], [0.3, -0.5, 0.8])), 'out']);
        keys.push([u(h.from), K(merge(toes, { spine: [6, 0, 0], chest: [8, 8, 0], head: [-12, 0, 0] }), g1([0.25, 0.85, -0.3], [0.1, 0.85, -0.5], { edge: [0, 0, -1] })), 'in']);
      } else keys.push([mid, i % 2 ? loL : hiR, 'out'], [u(h.from), i % 2 ? back : fore, 'in']);
    });
    return strike(I, ...keys);
  },
  // SPLIT THE METEOR / NOMIHOSE / TATE-GOTO: the cleaver raised overhead in both hands, the back arched on the toes,
  // then one vertical cleave into the ground
  'ke-meteor': (I) => strike(I,
    [0.5, K(merge(deep, hunch(0, -20)), g2([0.2, -0.15, -0.3], [0.2, -0.5, -0.85])), 'io'],
    [0.85, K(merge(toes, { pelvis: [0, 4, 0], spine: [14, 0, 0], chest: [16, 0, 0], neck: [-8, 0, 0], head: [-14, 0, 0] }), overhead2), 'out'],
    [1, K(merge(lunge(1.2), hunch(0, -36)), g2([0.05, -0.05, -0.65], [0, -0.55, -0.85])), 'in'],
    [2, K(merge(lunge(1.3), hunch(0, -44)), g2([0.05, -0.35, -0.58], [0, -0.9, -0.45])), 'out']),
  // KITTE MIRO YO (the hold, in frames): arms flung wide, chest open, head back, the blade out low to the side
  'ke-stance-hold': (I) => [k(0, I), k(6, K(merge(wide, { pelvis: [0, 0, 0], spine: [8, 0, 0], chest: [10, 0, 0], neck: [-6, 0, 0], head: [-14, 0, 0],
    armL: [10, 0, -80], foreL: [20, 0, 0], handL: [0, 0, 0] }), root([0.95, 0.95, -0.15], [0.55, -0.6, -0.55], { pole: [0, -1, 0.5] })), 'out')],
  // the rush auras / dashes (frames): crouch, then a charge (CHARGE) or the leap (LEAP CLEAVE: the cleaver up, both hands)
  'rush-aura': (I) => [k(0, I), k(5, K(merge(deep, hunch(-10, -26), { armL: [30, 0, -50], foreL: [60, 0, 0] }),
    g1([0.5, -0.45, 0.2], [0.3, -0.4, 0.85])), 'out')],
  'rush-dash': () => Array.from({ length: 9 }, (_, i) => k(i * 5, runLow(i % 2 ? mirror(P.runA) : P.runA), 'lin')),
  'leap-aura': (I) => [k(0, I), k(8, K(merge(deep, hunch(0, -34), { pos: [0, -0.42, 0] }), g2([0.25, -0.2, -0.3], [0.25, -0.55, -0.8])), 'out')],
  'leap-dash': () => [k(0, K(merge(air, { spine: [10, 0, 0], chest: [12, 0, 0], head: [-10, 0, 0] }), overhead2)),
    k(30, K(merge(air, { spine: [16, 0, 0], chest: [16, 0, 0], head: [-14, 0, 0] }), g2([0.1, 0.95, 0.1], [0.05, 0.1, 1], { pole: [1, 0.2, 0], poleL: [-1, 0.2, 0] })), 'lin')],
  // the Breaker: the shoulder first through its aura and dash, then the ram
  'shoulder-dash': (I) => [k(0, I), k(6, K(shoulderLean(0.8), blade_back), 'out'), k(14, K(shoulderLean(1), blade_back), 'lin')],
  'ke-shoulder': (I) => strike(I, [0.8, K(shoulderLean(0.8), blade_back), 'out'], [1, K(shoulderLean(1.2), blade_back), 'out'], [2, K(shoulderLean(1.2), blade_back)]),

  // ---- RYOTE (cup 2): two-handed kendo, straight and long
  // J1 MEN: the straight overhead, stepping in, down the centre line
  'ke-r-j1': (I) => strike(I,
    [0.75, K(merge(kendo, { spine: [6, 0, 0], chest: [8, -4, 0], head: [-8, 0, 0] }), g2([0.12, 0.8, -0.15], [0.04, 0.6, 0.8], { pole: [1, -0.1, 0.2], poleL: [-1, -0.4, 0.2] })), 'out'],
    [1, K(merge(lunge(), { spine: [-10, 0, 0], chest: [-6, 0, 0], neck: [6, 0, 0], head: [6, 0, 0] }), g2([0.08, 0.3, -0.72], [0, 0.05, -1])), 'in'],
    [2, K(merge(lunge(1.1), { spine: [-16, 0, 0], chest: [-8, 0, 0], neck: [8, 0, 0], head: [8, 0, 0] }), g2([0.06, 0.0, -0.68], [0, -0.45, -0.9])), 'out']),
  // J2 KOTE: the small wrist snap
  'ke-r-j2': (I) => strike(I,
    [0.7, K(merge(kendo, { spine: [2, 0, 0] }), g2([0.12, 0.55, -0.35], [0.05, 0.7, -0.3])), 'out'],
    [1, K(merge(lunge(0.7), { spine: [-8, 0, 0], chest: [-4, 0, 0], head: [4, 0, 0] }), g2([0.1, 0.15, -0.65], [0.05, -0.15, -1])), 'in'],
    [2, K(merge(lunge(0.7), { spine: [-10, 0, 0], chest: [-4, 0, 0], head: [4, 0, 0] }), g2([0.1, 0.1, -0.62], [0.05, -0.3, -0.95])), 'out']),
  // J3 KESA: the diagonal, shoulder to hip
  'ke-r-j3': (I) => strike(I,
    [0.75, K(merge(kendo, { pelvis: [0, -20, 0], chest: [6, -16, 0], head: [-6, 18, 0] }), g2([0.3, 0.7, -0.05], [0.35, 0.6, 0.72], { pole: [1, 0, 0.2], poleL: [-1, -0.2, 0] })), 'out'],
    [1, K(merge(lunge(), { pelvis: [0, 10, 0], spine: [-12, 6, 0], chest: [-8, 12, 0], head: [8, -14, 0] }), g2([0.12, 0.2, -0.68], [-0.55, -0.35, -0.75])), 'in'],
    [2, K(merge(lunge(1.1), { pelvis: [0, 30, 0], spine: [-18, 10, 0], chest: [-10, 22, 0], head: [10, -30, 0] }), g2([-0.2, -0.2, -0.5], [-0.65, -0.7, -0.1], { pole: [0.6, -1, 0.2] })), 'out']),
  // K1 DO: the wide body cut from waki-gamae, stepping through
  'ke-r-k1': (I) => strike(I,
    [0.8, K(merge(deep, { pelvis: [0, -45, 0], spine: [-10, -10, 0], chest: [-4, -25, 0], neck: [4, 0, 0], head: [6, 50, 0] }),
      g2([0.45, -0.2, 0.15], [0.55, -0.25, 0.8], { pole: [1, -0.4, 0.4], poleL: [-0.4, -1, 0.4] })), 'out'],
    [1, K(merge(lunge(), { pelvis: [0, 0, 0], spine: [-14, 0, 0], chest: [-8, 0, 0], neck: [6, 0, 0], head: [6, 0, 0] }), g2([0.15, -0.05, -0.7], [-0.6, 0, -0.8], { edge: [0, 0, -1] })), 'in'],
    [2, K(merge(lunge(1.2), { pelvis: [0, 45, 0], spine: [-14, 15, 0], chest: [-8, 30, 0], neck: [6, 0, 0], head: [6, -50, 0] }),
      g2([-0.35, -0.05, -0.45], [-0.85, 0.05, 0.4], { pole: [0.5, -1, 0.3] })), 'out']),
  // K2 MOROTE-ZUKI: both hands drive it straight out
  'ke-r-k2': (I) => {
    const hit = K(merge(lunge(1.3), { pelvis: [0, 0, 0], spine: [-16, 0, 0], chest: [-10, 0, 0], neck: [8, 0, 0], head: [10, 0, 0] }), g2([0.08, 0.05, -0.78], [0, 0.0, -1]));
    return strike(I, [0.8, K(merge(kendo, { pelvis: [0, -10, 0], spine: [4, 0, 0], chest: [2, -6, 0] }),
      g2([0.18, -0.1, -0.15], [0, 0.1, -1], { pole: [1, -0.6, 0.6], poleL: [-1, -0.6, 0.6] })), 'out'], [1, hit, 'out'], [2, hit]);
  },
  // K3 KABUTO-WARI: scoop low, rise huge on the toes, crash
  'ke-r-k3': (I) => strike(I,
    [0.4, K(merge(deep, hunch(-10, -30)), g2([0.3, -0.5, 0.0], [0.3, -0.55, 0.78])), 'io'],
    [0.85, K(merge(toes, { pelvis: [0, 0, 0], spine: [16, 0, 0], chest: [16, 0, 0], neck: [-8, 0, 0], head: [-16, 0, 0], pos: [0, 0.12, 0.02] }), overhead2), 'out'],
    [1, K(merge(lunge(1.2), hunch(0, -34)), g2([0.05, -0.05, -0.66], [0, -0.5, -0.86])), 'in'],
    [2, K(merge(lunge(1.3), hunch(0, -42)), g2([0.05, -0.35, -0.58], [0, -0.9, -0.42])), 'out']),
  // NOMIHOSE's K1 KUKAN-GIRI: a flat cut at chest height, left to right (the rift hangs where it passed)
  'ke-n-f1': (I) => strike(I,
    [0.8, K(merge(wide, { pelvis: [0, 40, 0], spine: [-4, 10, 0], chest: [0, 30, 0], neck: [0, 0, 0], head: [0, -55, 0] }),
      g2([-0.3, 0.3, 0.1], [-0.7, 0.15, 0.7], { pole: [0.2, -1, 0.3], poleL: [-1, -0.4, 0.3] })), 'out'],
    [1, K(merge(lunge(), { pelvis: [0, 0, 0], spine: [-10, 0, 0], chest: [-6, 0, 0], neck: [4, 0, 0], head: [4, 0, 0] }), g2([0.0, 0.15, -0.72], [0.65, 0.0, -0.75], { edge: [0, 0, -1] })), 'in'],
    [2, K(merge(lunge(1.1), { pelvis: [0, -40, 0], spine: [-10, -10, 0], chest: [-6, -28, 0], neck: [4, 0, 0], head: [4, 50, 0] }),
      g2([0.5, 0.15, -0.3], [0.85, 0.0, 0.45], { pole: [1, -0.6, 0.4] })), 'out']),

  // ---- the Bankai (the feral pass): hacks out of the crouch, the fists, the teeth
  // J1 TATAKI-GIRI: hacked down from the shoulder, lunging like a beast
  'ke-b-j1': (I) => strike(I,
    [0.75, K(merge(feralLegs, hunch(-20, -26), { armL: [60, 0, -30], foreL: [60, 0, 0], handL: [-30, 0, 20] }), g1([0.4, 0.6, 0.1], [0.3, 0.55, 0.8], { pole: [1, 0.2, 0.3] })), 'out'],
    [1, K(merge(lunge(1.3), hunch(10, -40), { armL: [30, 0, -40], foreL: [50, 0, 0], handL: [-30, 0, 20] }), g1([0.12, -0.05, -0.62], [-0.2, -0.65, -0.75])), 'in'],
    [2, K(merge(lunge(1.4), hunch(16, -46), { armL: [20, 0, -40], foreL: [50, 0, 0], handL: [-30, 0, 20] }), g1([0.05, -0.4, -0.4], [-0.15, -0.95, 0.1], { pole: [1, -0.4, 0.2] })), 'out']),
  // J2 NAGI-HARAI: the backhand sweep back across
  'ke-b-j2': (I) => strike(I,
    [0.75, K(merge(feralLegs, hunch(36, -34), { armL: [20, 0, -40], foreL: [60, 0, 0] }), g1([-0.28, -0.25, -0.4], [-0.75, -0.5, 0.25], { pole: [0.5, -1, 0] })), 'out'],
    [1, K(merge(lunge(1.2), hunch(0, -34), { armL: [40, 0, -50], foreL: [50, 0, 0] }), g1([0.3, 0.0, -0.62], [0.75, -0.1, -0.6], { edge: [0, 1, 0] })), 'in'],
    [2, K(merge(lunge(1.2), hunch(-34, -28), { armL: [50, 0, -50], foreL: [50, 0, 0] }), g1([0.6, 0.25, -0.1], [0.7, 0.3, 0.6], { edge: [1, 0, 0] })), 'out']),
  // J3 GENKOTSU (and the punch NAGURI-TOBASHI): coiled low, the left fist driven out with the whole body, the cleaver
  // flung out behind
  'ke-b-fist': (I) => {
    const hit = K(merge(lunge(1.3), { pelvis: [0, -30, 0], spine: [-24, -15, 0], chest: [-14, -30, 0], neck: [12, 20, 0], head: [20, 25, 0],
      armL: [85, -5, -5], foreL: [5, 0, 0], handL: [0, 0, 0] }), root([0.7, 0.9, 0.55], [0.35, -0.2, 0.9], { pole: [1, -0.2, 0.3] }));
    return strike(I, [0.75, K(merge(feralLegs, { pelvis: [0, 35, 0], spine: [-34, 10, 0], chest: [-20, 25, 0], neck: [16, -20, 0], head: [30, -20, 0],
      armL: [-30, 0, -20], foreL: [120, 0, 0], handL: [0, 0, 0] }), g1([0.55, -0.2, 0.35], [0.4, -0.3, 0.85])), 'out'], [1, hit, 'out'], [2, hit]);
  },
  // K1 ONATA: the hatchet chop: wound over the right shoulder, the whole torso turning into it
  'ke-b-k1': (I) => strike(I,
    [0.8, K(merge(feralLegs, { pelvis: [0, -30, 0], spine: [-10, -10, 0], chest: [0, -26, 0], neck: [10, 0, 0], head: [10, 30, 0], armL: [70, 0, -20], foreL: [40, 0, 0] }),
      g1([0.35, 0.7, 0.15], [0.2, 0.5, 0.85], { pole: [1, 0.3, 0.2] })), 'out'],
    [1, K(merge(lunge(1.2), hunch(16, -40), { armL: [20, 0, -40], foreL: [50, 0, 0] }), g1([0.1, 0.0, -0.66], [-0.15, -0.55, -0.82])), 'in'],
    [2, K(merge(lunge(1.3), hunch(24, -46), { armL: [10, 0, -40], foreL: [50, 0, 0] }), g1([0.0, -0.4, -0.45], [-0.1, -0.98, 0.1], { pole: [1, -0.4, 0.2] })), 'out']),
  // K2 EGURI-AGE: gouging up from the floor, up on the toes at the top
  'ke-b-k2': (I) => strike(I,
    [0.8, K(merge(deep, hunch(-30, -36), { armL: [40, 0, -30], foreL: [60, 0, 0] }), g1([0.45, -0.6, 0.15], [0.3, -0.5, 0.8], { pole: [1, -0.2, 0.6] })), 'out'],
    [1, K(merge(lunge(0.7), hunch(0, -8), { armL: [10, 0, -60], foreL: [40, 0, 0] }), g1([0.22, 0.3, -0.62], [0.1, 0.8, -0.6], { edge: [0, 0, -1] })), 'in'],
    [2, K(merge(toes, { spine: [10, 6, 0], chest: [12, 10, 0], neck: [-4, 0, 0], head: [-14, -8, 0], armL: [0, 0, -70], foreL: [30, 0, 0] }),
      g1([0.3, 1.0, -0.15], [0.1, 0.9, 0.4], { edge: [0, 0, -1], pole: [1, 0, 0.3] })), 'out']),
  // K3 TATAKI-OTOSHI: the cleaver high in both hands, held, dropped (KABUTO-WARI's shape, out of the crouch)
  'ke-b-k3': (I) => strike(I,
    [0.5, K(merge(feralLegs, hunch(0, -30)), g2([0.2, 0.2, -0.25], [0.2, 0.6, 0.78])), 'io'],
    [0.85, K(merge(toes, { spine: [14, 0, 0], chest: [16, 0, 0], neck: [-8, 0, 0], head: [-14, 0, 0] }), overhead2), 'out'],
    [1, K(merge(lunge(1.3), hunch(0, -40)), g2([0.05, -0.1, -0.64], [0, -0.55, -0.83])), 'in'],
    [2, K(merge(lunge(1.4), hunch(0, -48)), g2([0.05, -0.4, -0.55], [0, -0.92, -0.4])), 'out']),
  // L KAMICHIGIRI: down almost on all fours, the lunge, the claw clamps, the head drives in, the jerk back
  'ke-b-bite': (I) => strike(I,
    [0.6, K(merge(deep, { pelvis: [-10, 10, 0], spine: [-44, 0, 0], chest: [-24, 0, 0], neck: [26, 0, 0], head: [40, 0, 0], armL: [60, 0, -10], foreL: [30, 0, 0],
      handL: [-40, 0, 0], pos: [0, -0.5, 0] }), root([0.55, 0.45, 0.2], [0.3, -0.3, 0.9])), 'out'],
    [1, K(merge(lunge(1.4), { pelvis: [-6, 0, 0], spine: [-34, 0, 0], chest: [-20, 0, 0], neck: [10, 0, 0], head: [6, 0, 0], armL: [95, 0, -6], foreL: [10, 0, 0],
      handL: [-30, 0, 0] }), root([0.6, 0.7, 0.3], [0.35, -0.35, 0.85])), 'out'],
    [2, K(merge(lunge(1.2), { pelvis: [-6, 0, 0], spine: [-14, 0, 0], chest: [-4, 0, 0], neck: [-6, 0, 0], head: [-26, 10, 0], armL: [70, 0, -10], foreL: [50, 0, 0],
      handL: [-30, 0, 0] }), root([0.6, 0.7, 0.3], [0.35, -0.35, 0.85])), 'out']),
  // the Bankai's leap (MAPPUTATSU's rush): dropped almost to all fours, the spring with the broken cleaver swung up
  // one-handed and the claw reaching ahead
  'oni-aura': (I) => [k(0, I), k(8, K(merge(deep, { spine: [-46, 0, 0], chest: [-24, 0, 0], neck: [26, 0, 0], head: [44, 0, 0], armL: [50, 0, -10],
    foreL: [30, 0, 0], handL: [-40, 0, 0], pos: [0, -0.5, 0] }), root([0.55, 0.4, 0.2], [0.3, -0.35, 0.9])), 'out')],
  'oni-dash': () => [k(0, K(merge(air, { spine: [-10, 0, 0], chest: [-6, 0, 0], neck: [10, 0, 0], head: [10, 0, 0], armL: [110, 0, -10], foreL: [10, 0, 0],
    handL: [-30, 0, 0] }), g1([0.3, 0.85, 0.15], [0.1, 0.4, 0.9], { pole: [1, 0.3, 0] }))), k(30, K(merge(air, { spine: [-4, 0, 0], chest: [0, 0, 0], neck: [4, 0, 0],
    head: [-4, 0, 0], armL: [120, 0, -10], foreL: [10, 0, 0], handL: [-30, 0, 0] }), g1([0.25, 0.95, 0.2], [0.05, 0.2, 0.98], { pole: [1, 0.3, 0] })), 'lin')],
};

/** The builder for MV (by name, its copies folded) in FORM and PHASE. */
function builderFor(mv: Move, phase: string, form: string): Builder | null {
  const n = mv.name.replace(/^(ke(?:-[rb])?-[jk]2)s$/, '$1').replace(/^ke-a-j3$/, 'ke-j3');
  if (phase === 'hold') return n === 'ke-stance' ? B['ke-stance-hold'] : null;
  if (phase === 'aura' || phase === 'dash') {
    if (mv.kind === 'breaker') return B['shoulder-dash'];
    return B[feral(form) ? `oni-${phase}` : mv.params?.look === 'leap' ? `leap-${phase}` : `rush-${phase}`];
  }
  if (phase !== 'main') return null;
  if (mv.kind === 'breaker') return B['ke-shoulder'];
  if (mv.kind === 'kikon' || n === 'ke-stance') return B['ke-stance-cut'];
  if (n === 'ke-meteor-n' || n === 'ke-b-split') return B['ke-meteor'];
  if (n === 'ke-b-j3' || n === 'ke-b-punch') return B['ke-b-fist'];
  return B[n] ?? null;
}
const CACHE = new Map<string, Clip | null>();
/** The bespoke clip for MV (clips/index.ts CharClips.move). */
export function move(mv: Move, phase: string, form: string): Clip | null {
  const key = `${mv.name}|${phase}|${form}`;
  if (!CACHE.has(key)) {
    const b = builderFor(mv, phase, form);
    CACHE.set(key, b ? b(idleIn(form), mv) : null);
  }
  return CACHE.get(key)!;
}
