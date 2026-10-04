// rules.ts <- duel/lisp/rules.lisp: SOUL DUEL's rules as pure functions (the "functional core"): inputs are arguments,
// results are return values (CL multiple values -> tuples), randomness comes in as a number in [0,1). They read the knobs
// in tuning.ts and nothing else. The systems (fighter, combat, hazards, ai) gather the inputs and apply the result.
// Frames are 60 Hz steps; a move frame SF counts the frames since the move began (0 = its first frame), so a move with
// startup S is active on SF = S .. S+A-1. Reishi is an integer; gauges are floats. No character names in here.
import { T } from './tuning';
import { deg, fwdX, fwdZ, getf, len32, roundHalfEven, floorDiv } from './math';
import { cosf } from './sinf';
import { volHitP, type Vol } from './hitvol';

// ================================================================ angles and positions
/** The yaw that faces direction (DX DZ) (CL's double ATAN, as the seeded replays were recorded with). */
export const dirYaw = (dx: number, dz: number): number => Math.fround(Math.atan2(-dx, -dz));   // (CL ATAN on singles)
/** A :track value (degrees per second) as radians per frame. */
export const trackStep = (degPerSecond: number): number => deg(Math.fround(degPerSecond / 60));

/** (X Z) moved inside the circle of radius R around the origin (the arena's invisible wall). */
export function clampToCircle(x: number, z: number, r: number): [number, number] {
  const d = len32(x, z), k = f32(r / d);                             // (singles, as the Lisp)
  return d <= r ? [x, z] : [f32(x * k), f32(z * k)];
}

/** Opponent-relative movement: stick (SX right, SY up) read through a camera with yaw CAM-YAW, for a fighter at (PX PZ)
 *  whose opponent stands at (OX OZ). Values: TOWARD (+ = at the opponent) and STRAFE (+ = to his right). */
export function stickTowardStrafe(sx: number, sy: number, camYaw: number, px: number, pz: number, ox: number, oz: number): [number, number] {
  const fx = fwdX(camYaw), fz = fwdZ(camYaw);
  const wx = sy * fx + sx * -fz;                     // camera right = (-fz, fx)
  const wz = sy * fz + sx * fx;
  const ax = ox - px, az = oz - pz, d = Math.sqrt(ax * ax + az * az);
  if (d < 1e-4) return [sy, sx];
  const ux = ax / d, uz = az / d;
  return [wx * ux + wz * uz, wx * -uz + wz * ux];
}

/** The inverse projection: world direction (dx dz) of moving TOWARD / STRAFE relative to the opponent at (OX OZ). */
export function towardStrafeDir(toward: number, strafe: number, px: number, pz: number, ox: number, oz: number): [number, number] {
  // (single floats op by op, as the Lisp: it is the walk / run direction)
  const ax = f32(ox - px), az = f32(oz - pz), d = Math.max(f32(1e-4), len32(ax, az));
  const ux = f32(ax / d), uz = f32(az / d);
  return [f32(f32(toward * ux) + f32(strafe * -uz)), f32(f32(toward * uz) + f32(strafe * ux))];
}

/** Is the point (AX AZ) within the ARC-DEG wide cone in front of a fighter at (PX PZ) facing YAW? */
export function inFrontP(yaw: number, px: number, pz: number, ax: number, az: number, arcDeg: number): boolean {
  const dx = f32(ax - px), dz = f32(az - pz), d = len32(dx, dz);    // (singles, as the Lisp: the guard arc's edge)
  return d < 1e-4 || f32(f32(f32(dx * fwdX(yaw)) + f32(dz * fwdZ(yaw))) / d) >= cosf(deg(f32(arcDeg / 2)));
}

/** Where a Hoho reappears: T.hohoDistance behind the opponent at (OX OZ) facing OYAW, facing his back, in the arena. */
export function hohoDestination(ox: number, oz: number, oyaw: number): [number, number, number] {
  const [x, z] = clampToCircle(f32(ox - f32(T.hohoDistance * fwdX(oyaw))), f32(oz - f32(T.hohoDistance * fwdZ(oyaw))), T.arenaRadius);
  return [x, z, oyaw];
}

/** Post-Kikon reset: A and B placed T.resetDistance apart around the arena centre, on the line they stood on. */
export function resetPlacement(ax: number, az: number, bx: number, bz: number): [number, number, number, number] {
  let dx = f32(bx - ax), dz = f32(bz - az);                           // (singles, as the Lisp)
  const d = len32(dx, dz), h = f32(T.resetDistance / 2);
  if (d < 1e-3) { dx = 0; dz = 1; } else { dx = f32(dx / d); dz = f32(dz / d); }
  return [f32(dx * -h), f32(dz * -h), f32(dx * h), f32(dz * h)];
}

/** Step direction (toward strafe, unit length): the stick's, or straight back when neutral. NEUTRAL 1: at him (the run). */
export function stepDirection(toward: number, strafe: number, neutral = -1.0): [number, number] {
  const m = len32(toward, strafe);                                   // (singles, as the Lisp)
  return m < 0.3 ? [neutral, 0] : [f32(toward / m), f32(strafe / m)];
}

// ---------------------------------------------------------------- the run (Step held)
/** Does a run at SPEED m/s, CLOSING (-1..1), stop this frame at DIST? It stops before it would come within T.runStop. */
export const runStopP = (dist: number, closing: number, speed: number): boolean =>
  closing > 0 && f32(dist - f32(f32(speed * closing) * f32(1 / 60))) < T.runStop;   // (singles)
/** Momentum of a move started out of a run: T.runCarry metres, never past T.runStop from the opponent at DIST. */
export const runCarry = (dist: number): number => Math.max(0, Math.min(T.runCarry, f32(dist - T.runStop)));
/** Speed on brake FRAME (1-based) of T.runBrake after a run at SPEED: linear down to 0. */
export const brakeSpeed = (speed: number, frame: number): number => f32(speed * Math.max(0, f32(1 - f32(frame / T.runBrake))));

// ================================================================ the triangle (§3)
// Defender states: neutral guard breaker stance-in stance armor invuln parry (see DUEL_DESIGN §3).
export type DefState = 'neutral' | 'guard' | 'breaker' | 'stance-in' | 'stance' | 'armor' | 'invuln' | 'parry';
export type Contact = 'hit' | 'counter' | 'blocked' | 'guard-break' | 'stance-break' | 'absorbed' | 'armored' | 'parried' | 'kikon';
export interface ContactOpts {
  breaker?: boolean; guardCrush?: boolean; inFront?: boolean; unguardable?: boolean; hazard?: boolean; ward?: boolean; rend?: boolean;
}
/** What one hit that touched the defender does (null = no effect: invulnerable). Breaker vs Breaker is a CLASH, decided
 *  before any contact (breakerClashP). REND: armour and a stance don't stop it; a guard, the ward and a parry still do. */
export function resolveContact(defState: DefState, o: ContactOpts = {}): Contact | null {
  const inFront = o.inFront ?? true;
  const crush = o.breaker || o.guardCrush;
  const state: DefState =
    defState === 'guard' && !inFront && !o.ward ? 'neutral'
    : o.unguardable && ['guard', 'stance-in', 'stance', 'parry'].includes(defState) ? 'neutral'
    : o.hazard && defState === 'parry' ? (o.ward ? 'guard' : 'neutral')
    : defState;
  switch (state) {
    case 'invuln': return null;
    case 'parry': return o.breaker ? 'stance-break' : 'parried';
    case 'guard': return crush ? 'guard-break' : 'blocked';
    case 'breaker': return 'counter';
    case 'stance-in': return o.breaker || o.rend ? 'stance-break' : 'counter';
    case 'stance': return o.breaker || o.rend ? 'stance-break' : 'absorbed';
    case 'armor': return o.breaker || o.unguardable || o.rend ? 'hit' : 'armored';
    case 'neutral': return 'hit';
  }
}

/** What a hit's result counts as for the attacker: 'hit' only when it really landed; armour, an absorb, a parry and a
 *  block are 'block'. Only 'hit' opens the string's hit timing, the cancels and a move's on-land hook. */
export function contactOf(res: Contact | null): 'hit' | 'block' | null {
  if (res === null) return null;
  return ['hit', 'counter', 'guard-break', 'stance-break', 'kikon'].includes(res) ? 'hit' : 'block';
}

export type BreakerPhase = 'aura' | 'dash' | 'strike' | 'recover' | null;
/** Both fighters' Breakers in dash or strike within T.clashRange: CLASH. */
export const breakerClashP = (a: BreakerPhase, b: BreakerPhase, dist: number): boolean =>
  (a === 'dash' || a === 'strike') && (b === 'dash' || b === 'strike') && dist <= T.clashRange;

/** The Breaker's pre-strike state machine: the aura lasts T.breakerAura; the dash lasts while held (at least
 *  T.breakerDashMin, at most T.breakerDashMax) and strikes as soon as the opponent is within T.breakerTrigger. */
export function breakerNextPhase(phase: 'aura' | 'dash', frames: number, held: boolean, dist: number): 'aura' | 'dash' | 'strike' {
  if (phase === 'aura') return frames >= T.breakerAura ? 'dash' : 'aura';
  return dist <= T.breakerTrigger || frames >= T.breakerDashMax || (!held && frames >= T.breakerDashMin) ? 'strike' : 'dash';
}

/** The Kikon rush's pre-strike state machine (the button only matters at the strike: kikonOutcome). */
export function kikonRushNextPhase(phase: 'aura' | 'dash', frames: number, dist: number, aura: number, dashMax: number): 'aura' | 'dash' | 'strike' {
  if (phase === 'aura') {
    if (frames < aura) return 'aura';
    return dashMax === 0 || dist <= T.kikonTrigger ? 'strike' : 'dash';
  }
  return dist <= T.kikonTrigger || frames >= dashMax ? 'strike' : 'dash';
}

/** Is move frame SF of a parry move inside its WINDOW (lo hi), inclusive, else T.parryWindow? */
export const parryFrameP = (sf: number, window?: number[] | null): boolean => invulnerableFrameP(sf, window ?? T.parryWindow);
/** How far a rush module reaches: its dash (SPEED m/s for DASH-MAX frames) + T.kikonTrigger. */
export const kikonRushReach = (speed: number, dashMax: number): number => f32(T.kikonTrigger + f32(speed * f32(dashMax / 60)));
/** Dash speed after FRAMES of dashing: T.breakerSpeedMin rising to T.breakerSpeedMax. */
export const breakerSpeed = (frames: number): number =>
  f32(T.breakerSpeedMin + f32(f32(T.breakerSpeedMax - T.breakerSpeedMin) * Math.min(1, f32(frames / T.breakerDashMax))));   // (singles)

// ================================================================ frame advantage (§3)
/** Blockstun that gives the move its block advantage ADV: the attacker's frames left after the hit (TOTAL = S+A+R, hit on
 *  move frame HIT-FRAME) + ADV, at least 1. Both sides count the same way (moveEndFrame): ADV frames exactly. */
export const blockstun = (total: number, hitFrame: number, adv: number): number => Math.max(1, total - hitFrame + adv);
/** Move frame on which a move ends: R after a hit or block (CONTACT) or for a HITLESS move, else the whiff recovery. */
export const moveEndFrame = (s: number, a: number, r: number, whiff: number | null, contact: unknown, hitless: boolean): number =>
  s + a + (hitless ? r : recoveryFrames(r, contact, whiff));
/** Stun frames of reaction REACT, + T.counterStun on a counter-hit. */
export const hitstun = (react: string, counter = false): number =>
  getf(T.reactionFrames, react, 0) + (counter ? T.counterStun : 0);
/** Recovery actually played: R after contact, else WHIFF or R + T.whiffExtra. */
export const recoveryFrames = (r: number, contact: unknown, whiff?: number | null): number =>
  contact ? r : (whiff ?? r + T.whiffExtra);

/** May the next link of a string start at move frame SF? Only after CONTACT ('hit' / 'block', or true for a follow-up
 *  link). On 'hit' from the end of the active frames; otherwise only in the last T.chainLead frames of recovery. */
export function chainOpenP(sf: number, s: number, a: number, r: number, contact: 'hit' | 'block' | boolean | null): boolean {
  const total = s + a + r;
  return !!contact && sf < total && (contact === 'hit' ? sf >= s + a : sf >= total - T.chainLead);
}

/** The follow-up link's chase speed (m/s) at distance D with LEFT frames to its hit, arriving T.chaseMargin inside its
 *  REACH (never nearer than T.lungeStop) as the hit window opens; no faster than CAP; never overshoots. */
export function stringChaseSpeed(d: number, reach: number, left: number, cap = T.chaseMax): number {
  const goal = Math.max(f32(T.lungeStop), f32(reach - f32(T.chaseMargin)));   // (singles, as the Lisp)
  return d > goal && left > 0 ? Math.min(cap, f32(60 * f32(f32(d - goal) / left))) : 0;
}

/** How far a point (X Z) inside the circle of radius R may move along (UX UZ) before it reaches the circle. */
export function rayRoom(x: number, z: number, ux: number, uz: number, r: number): number {
  const b = f32(f32(x * ux) + f32(z * uz)), c = f32(f32(f32(x * x) + f32(z * z)) - f32(r * r)), disc = f32(f32(b * b) - c);
  return c >= 0 || disc < 0 ? 0 : Math.max(0, f32(-b + f32(Math.sqrt(disc))));   // (singles, as the Lisp)
}

/** On-hit cancel window: the move LANDED, from its first hit frame HIT-FRAME until its recovery ends (TOTAL). */
export const cancelOpenP = (sf: number, hitFrame: number, total: number, landed: boolean): boolean =>
  landed && sf >= hitFrame && sf < total;

/** The guard cancel: a move whose own hit landed (a block too for a QUICK move) may end in a guard over the last
 *  floor(R x T.guardCancel) frames of its recovery. */
export function guardCancelOpenP(sf: number, s: number, a: number, r: number, contact: unknown, quick = false): boolean {
  const total = s + a + r;
  return (contact === 'hit' || (quick && contact === 'block')) && sf >= total - Math.floor(r * T.guardCancel) && sf < total;
}

/** The guard lock: does a defender in blockstun stay there, because his attacker may still chain? (See DUEL_DESIGN.) */
export function guardLockedP(defState: string, was: boolean, chainLeft: number, state: string, phase: string | null,
                             sf: number, s: number, a: number, r: number, touched: unknown, more: unknown): boolean {
  return defState === 'guard-hit' &&
    ((chainLeft > 0 && (state === 'idle' || state === 'guard')) ||
     (state === 'move' && ((was && (phase !== 'main' || sf < s + a)) || (!!touched && !!more && sf + 1 < s + a + r))));
}

/** Is move frame SF inside the inclusive iframe WINDOW (from to)? */
export const invulnerableFrameP = (sf: number, window: number[] | null | undefined): boolean =>
  !!window && window[0] <= sf && sf <= window[1];

// ================================================================ damage (§4)
/** Damage fraction of the Nth hit of a combo (1-based). */
export const comboScale = (n: number): number =>
  n <= T.comboFullHits ? 1.0 : Math.max(T.comboFloor, 1.0 - T.comboDecay * (n - T.comboFullHits));
/** Cornered passive: 1 + PER per Konpaku LOST, the bonus capped at CAP. */
export const corneredMult = (per: number, lost: number, cap: number): number => 1.0 + Math.min(cap, per * lost);

export interface AtkMods { mult?: number; cornered?: number; corneredMax?: number; lost?: number }
export interface DefMods { mult?: number }
/** Damage (integer, >= 1 for a damaging hit) of a hit with BASE damage: the attacker's multipliers, Cornered, the
 *  defender's :taken, the combo scaling and the counter-hit multiplier, stacked. */
export function hitDamage(base: number, atk: AtkMods | null, def: DefMods | null, comboIndex: number, counterHit: boolean): number {
  if (base <= 0) return 0;
  // the Lisp multiplies in single-float, left to right: round each product to f32 so the integer damage agrees with it
  let x = f32(base * f32(atk?.mult ?? 1.0));
  x = f32(x * corneredMult32(atk?.cornered ?? 0, atk?.lost ?? 0, atk?.corneredMax ?? 0));
  x = f32(x * f32(def?.mult ?? 1.0));
  x = f32(x * comboScale32(comboIndex));
  x = f32(x * (counterHit ? f32(T.counterMult) : 1.0));
  return Math.max(1, roundHalfEven(x));
}
const f32 = Math.fround;
const comboScale32 = (n: number): number =>
  n <= T.comboFullHits ? 1.0 : Math.max(f32(T.comboFloor), f32(1.0 - f32(f32(T.comboDecay) * (n - T.comboFullHits))));
const corneredMult32 = (per: number, lost: number, cap: number): number => f32(1.0 + Math.min(f32(cap), f32(f32(per) * lost)));

/** Bankai East's pierce k at guard gauge GG, x a move's :pierce-mult. */
export const pierceRate = (gg: number, mult = 1.0): number =>
  f32(f32(mult) * f32(T.pierceMin + f32(f32(T.pierceMax - T.pierceMin) * f32(gg / T.ggMax))));   // (singles)

/** Where a cast aimed from (PX PZ) at (TX TZ) lands: on the target, or RANGE along the line. */
export function castPoint(px: number, pz: number, tx: number, tz: number, range: number): [number, number] {
  const dx = f32(tx - px), dz = f32(tz - pz), d = len32(dx, dz), k = f32(range / d);   // (singles)
  return d <= range ? [tx, tz] : [f32(px + f32(dx * k)), f32(pz + f32(dz * k))];
}

/** Chip of a blocked hit worth DMG at RATE (null = none) on a defender with REISHI: chip never kills. */
export const chipDamage = (dmg: number, rate: number | null | undefined, reishi: number): number =>
  !rate || rate <= 0 ? 0 : Math.max(0, Math.min(roundHalfEven(f32(dmg * f32(rate))), reishi - 1));

/** Reishi a form's burn takes on its STEPth frame (0-based): whole points, a whole second burns exactly the rate. */
export function burnAmount(maxReishi: number, fractionPerSecond: number, step: number): number {
  const perSecond = roundHalfEven(maxReishi * fractionPerSecond);
  return floorDiv(perSecond * (step + 1), 60) - floorDiv(perSecond * step, 60);
}
/** REISHI after a self-burn of AMOUNT: never below 1. */
export const burn = (reishi: number, amount: number): number => (reishi <= 1 ? reishi : Math.max(1, reishi - amount));

// ---------------------------------------------------------------- KOSEI, the aggression reward
export const koseiMult = (gg: number): number => f32(1.0 + f32(T.koseiBonus * f32(1.0 - f32(gg / T.ggMax))));   // (singles)
/** What one paying contact of guard value G earns at guard gauge GG: [Reiatsu, flash-step, the multiplier]. */
export function koseiGain(g: number, gg: number): [number, number, number] {
  const m = koseiMult(gg);
  return [f32(f32(T.koseiReiatsu * g) * m), f32(f32(T.koseiFs * g) * m), m];
}

// ================================================================ Kikon, Konpaku, time-up (§1)
export const redP = (reishi: number, maxReishi: number): boolean => reishi < maxReishi * T.redThreshold;

/** What a Kikon rush strike that connected with CONTACT leads to: 'follow' (hit, button HELD), 'kikon' (the follow-up hit),
 *  null (guarded, whiffed or released: a plain hit). */
export function kikonOutcome(held: boolean, contact: Contact | null, follow: boolean): 'follow' | 'kikon' | null {
  if (contact === 'hit' || contact === 'counter') {
    if (follow) return 'kikon';
    if (held) return 'follow';
  }
  return null;
}
export const kikonFollowUnguardableP = (red: boolean): boolean => red;
/** Frames the rush dashes in after its strike hit before the follow-up strike (startup S) starts. */
export const kikonFollowWait = (s: number): number => Math.max(0, T.kikonFollowStun + 1 + T.kikonFollowGap - s);
/** The follow-up's victim reels this long: T.kikonFollowStun, or, RED, until the strike has landed. */
export const kikonFollowStun = (red: boolean, s: number): number => (red ? kikonFollowWait(s) + s + 2 : T.kikonFollowStun);
/** The dash-in's speed: arrive at T.kikonTrigger from DIST exactly when FRAMES-LEFT run out, at most CAP. */
export const kikonFollowSpeed = (dist: number, framesLeft: number, cap: number): number =>
  dist <= T.kikonTrigger ? 0 : Math.min(cap, f32(60 * f32(f32(dist - f32(T.kikonTrigger)) / Math.max(1, framesLeft))));   // (singles)
export const soulBreakP = (reishi: number): boolean => reishi <= 0;

/** Konpaku settled at connect time: [konpaku-left, lost, ko-p]. A Kikon never more than T.kikonMaxEvent, a Soul Break
 *  (one more) never more than T.soulBreakMaxEvent. */
export function kikonResult(konpaku: number, count: number, soulBreak: boolean): [number, number, boolean] {
  const lost = Math.min(konpaku, soulBreak ? T.soulBreakMaxEvent : T.kikonMaxEvent, count + (soulBreak ? T.soulBreakExtra : 0));
  const left = konpaku - lost;
  return [left, lost, left <= 0];
}

/** Winner at time-up: 0 or 1 (more Konpaku, then the higher Reishi %), or 'draw'. */
export function timeUpWinner(k0: number, r0: number, m0: number, k1: number, r1: number, m1: number): 0 | 1 | 'draw' {
  if (k0 > k1) return 0;
  if (k0 < k1) return 1;
  if (r0 * m1 > r1 * m0) return 0;                 // integer cross-multiply: exact %
  if (r0 * m1 < r1 * m0) return 1;
  return 'draw';
}

// ================================================================ gauges (§3, §5)
// (the gauges are single floats in the Lisp and so is every step of their arithmetic: f32 op by op, so a gauge reaches
// a threshold (EVOLUTION at 100, a Reiatsu bar) on the same step)
export const gaugeAdd = (g: number, n: number, max: number): number => Math.max(0, Math.min(max, f32(g + n)));
export const reiatsuGain = (dealt: number, taken: number, frames = 0): number =>
  f32(f32(f32(dealt * T.reiatsuDealt) + f32(taken * T.reiatsuTaken)) + f32(frames * f32(T.reiatsuRegen / 60)));
export const awakeningGain = (dealt: number, taken: number, lost: number): number =>
  f32(f32(f32(dealt * T.awakenDealt) + f32(taken * T.awakenTaken)) + f32(lost * T.awakenPerKonpaku));
/** What dealing / taking damage pays: [Reiatsu, flash-step, Fighting Spirit, siphoned Reiatsu, siphoned flash-step]. */
export function hitGains(dealt: number, taken: number, siphoned: boolean, mult = 1.0): [number, number, number, number, number] {
  const r = f32(f32(f32(mult * dealt) * T.reiatsuDealt) + reiatsuGain(0, taken)), fs = f32(taken * f32(T.fsTaken));
  return siphoned ? [0, 0, 0, r, fs] : [r, fs, f32(f32(mult * awakeningGain(dealt, 0, 0)) + awakeningGain(0, taken, 0)), 0, 0];
}
/** Take up to AMOUNT out of gauge FROM into gauge TO (kept at most MAX): [from, to] after. */
export function gaugeMove(from: number, amount: number, to: number, max: number): [number, number] {
  const took = Math.max(0, Math.min(from, amount));
  return [f32(from - took), gaugeAdd(to, took, max)];
}
/** Spend BARS of Reiatsu: [reiatsu-after, ok]. */
export function spendBars(reiatsu: number, bars: number): [number, boolean] {
  const cost = bars * T.reiatsuBar;
  return reiatsu >= cost ? [reiatsu - cost, true] : [reiatsu, false];
}
export const secondsToFrames = (s: number): number => roundHalfEven(s * 60);
export const timerFill = (framesLeft: number, totalFrames: number, max: number): number =>
  totalFrames <= 0 ? 0 : max * (framesLeft / totalFrames);
export const bankaiAllowedP = (free: boolean, konpaku: number): boolean => free && konpaku <= T.bankaiKonpaku;

// ---------------------------------------------------------------- the arm meter UDE (Kenpachi's Bankai)
export const pipSpend = (pips: number): [number, boolean] => (pips >= 1 ? [pips - 1, true] : [pips, false]);
export function pipStep(pips: number, idle: number, locked: boolean): [number, number, boolean] {
  if (locked) return [pips, idle, false];
  if (pips > 0 && idle + 1 >= T.armCrack) return [pips - 1, 0, true];
  return [pips, Math.min(9999, idle + 1), false];
}
export const stringPipDueP = (owed: boolean, state: string, kind: string | null): boolean =>
  owed && !(state === 'move' && (kind === 'quick' || kind === 'flash' || kind === 'kikon'));
export function burstDueP(pending: unknown, current: unknown, state: string): boolean {
  return !!pending && !['stun', 'guard-hit', 'air', 'down', 'wakeup', 'hoho', 'cine', 'intro', 'win', 'lose'].includes(state)
    && !(state === 'move' && current === pending);
}

// ---------------------------------------------------------------- Rukia: frost, the temperature
export const frostNext = (cur: number, n: number): number => Math.min(T.frostCap, Math.max(cur, n));
export const frostSpeed = (speed: number, frost: number): number => (frost > 0 ? f32(speed * T.frostSlow) : speed);
export const opticP = (ward: boolean, optic: boolean, ranged: boolean): boolean => ward && optic && ranged;
export const tempNext = (c: number, guarding: boolean, warm: number): number =>
  Math.max(0, Math.min(T.coldMax, guarding ? f32(c + f32(T.ruCoolRate / 60)) : f32(c - f32(warm / 60))));   // (single floats)
export function tempBand(c: number, band: string): string {
  switch (band) {
    case 'm18': return c >= T.coldMax ? 'zero' : c >= T.coldBar ? 'm50' : 'm18';
    case 'm50': return c >= T.coldMax ? 'zero' : c <= 0 ? 'm18' : 'm50';
    case 'zero': return c <= 0 ? 'm18' : c <= T.coldBar ? 'm50' : 'zero';
    default: throw new Error(`temp-band ${band}`);
  }
}
export const tempBandAt = (c: number, band: string, state: string): string =>
  state === 'idle' || state === 'guard' || state === 'run' ? tempBand(c, band) : band;
export const coldOkP = (c: number, cost: number, combo: boolean): boolean => c >= cost || (combo && c > 0);
export const tempCoolFrames = (c: number): number => Math.ceil(((c < T.coldBar ? T.coldBar : T.coldMax) - c) / (T.ruCoolRate / 60));
export const fieldK = (away: number, frosted: boolean): number => (frosted ? Math.max(f32(away), f32(T.fieldFloor / T.frostSlow)) : f32(away));
export function fieldVelocity(vx: number, vz: number, ux: number, uz: number, k: number): [number, number] {
  const a = f32(f32(1 - k) * Math.max(0, f32(f32(vx * ux) + f32(vz * uz))));   // (singles, as the Lisp)
  return [f32(vx - f32(a * ux)), f32(vz - f32(a * uz))];
}
export const fieldStep = (dist: number, toward: number, s: number): number =>
  f32(dist * f32(1 - f32(f32(1 - f32(s)) * Math.max(0, -toward))));   // (singles)

/** Hoho needs T.fsHoho flash-step (during a burst any FS > 0), no block/hitstun, the lockout over. */
export const hohoAllowedP = (stunned: boolean, fs: number, lockoutLeft: number, bursting: unknown = null): boolean =>
  !stunned && (bursting ? fs > 0 : fs >= T.fsHoho) && lockoutLeft <= 0;
export const hohoCost = (fs: number, bursting: unknown): number => (bursting ? Math.min(fs, T.fsHoho) : T.fsHoho);
export const awakenAllowedP = (free: boolean, gauge: number, used: boolean): boolean => free && !used && gauge >= T.awakenMax;

export type BurstMode = 'white' | 'blue' | 'orange';
/** The burst a press would start from fighter STATE, or null (never while LOCKED). */
export function burstMode(state: string, locked: boolean, comboHits: number, chainOpen: unknown): BurstMode | null {
  if (locked) return null;
  switch (state) {
    case 'stun': case 'air': return comboHits >= T.burstMinHits ? 'blue' : null;
    case 'guard-hit': return 'blue';
    case 'move': return chainOpen ? 'orange' : null;
    case 'idle': case 'guard': case 'run': return 'white';
    default: return null;
  }
}
export const burstAllowedP = (mode: BurstMode | null, fs: number, active: unknown): boolean => !!mode && !active && fs >= T.fsBurst;
export const burstDrain = (fs: number): number => Math.max(0, f32(fs - f32(T.burstDrain / 60)));   // (the fs gauge is single-float)
export const burstFsGain = (gain: number, mode: unknown): number => (mode ? 0 : gain);
/** Integer points a per-second RATE pays on frame N (1-based) of a burst. */
export const burstHeal = (n: number, rate: number): number => floorDiv(n * rate, 60) - floorDiv((n - 1) * rate, 60);
export const burstGainMult = (mode: unknown): number => (mode === 'orange' ? T.orangeGain : 1.0);
/** ORANGE's startup cut: T.chainCut of the startup left, leaving at least 1 f. */
export const chainStartupCut = (s: number, enter: number): number => Math.max(0, Math.min(Math.floor(T.chainCut * (s - enter)), s - enter - 1));
export const kikonRefund = (fs: number, reiatsu: number): [number, number] =>
  [gaugeAdd(fs, T.kikonFsRefund, T.fsMax), gaugeAdd(reiatsu, T.kikonReiatsuRefund, T.reiatsuMax)];
export const fsRegen = (fs: number, idle: number): number => (idle >= T.fsDelay ? Math.min(T.fsMax, f32(fs + f32(T.fsRegen / 60))) : fs);

// ---------------------------------------------------------------- the guard gauge
/** The guard gauge a blocked hit drains: OVERRIDE, else by the move KIND (null = a hazard), + T.ggEnder for an ender. */
export function guardValue(kind: string | null, adv: unknown, override?: number | null): number {
  if (override != null) return override;
  if (!kind) return T.ggHazard;
  return getf(T.ggKind, kind, 0) +
    (['quick', 'flash', 'sig'].includes(kind) && Number.isInteger(adv) && (adv as number) <= T.ggEnderAdv ? T.ggEnder : 0);
}
export function ggDrain(gg: number, v: number): [number, boolean] {
  const n = Math.max(0, gg - v);
  return [n, n <= 0];
}
/** The guard gauge one frame later: nothing while GUARDING or before T.ggDelay frames without a drain, then the regen. */
export function ggRegen(gg: number, idle: number, guardless: boolean, guarding: boolean, blue: unknown = null, mult = 1.0): number {
  const rate = f32((guardless ? T.ggRegenGuardless : f32(f32(mult) * T.ggRegen)) / 60);   // (singles)
  if (blue) return Math.min(T.ggMax, f32(gg + f32(rate * (guarding ? T.blueGgGuarding : T.blueGgMult))));
  if (guarding || idle < T.ggDelay) return gg;
  return Math.min(T.ggMax, f32(gg + rate));
}
/** GUARD HOLD: the refill delay counter one frame later: frozen while GUARDING. */
export const ggIdleNext = (idle: number, guarding: boolean): number => (guarding ? idle : Math.min(9999, idle + 1));
export const canGuardP = (gg: number, guardless: boolean): boolean => gg > 0 && !guardless;

// ---------------------------------------------------------------- NOME: Nozarashi's three-cup ladder
export type Rung = [string, number, number, number, number];
// (in single floats like the Lisp: NOME and its gains are f32)
export const nomeGain = (dealt: number, taken: number, drunk: number, gains: object): number =>
  f32(f32(f32(dealt * f32(getf(gains, 'dealt', 0))) + f32(taken * f32(getf(gains, 'taken', 0))))
      + f32(drunk * f32(getf(gains, 'drunk', 0))));
export const meterDrain = (nome: number, rate: number, delay: number, idle: number): number =>
  rate > 0 && idle >= delay ? Math.max(0, f32(nome - f32(rate / 60))) : nome;
export function ladderRung(nome: number, rung: number, ladder: Rung[]): number {
  let i = rung;
  const n = ladder.length;
  while (i + 1 < n && nome >= ladder[i + 1][3]) i++;
  while (i > 0 && nome < ladder[i][4]) i--;
  return i;
}
/** Is a hit ranged? A HAZARD's always; a :ranged window unless its move's MELEE-RANGE covers the defender (D2 squared). */
export const rangedHitP = (hazard: unknown, flags: readonly string[], meleeRange: number | null | undefined, d2: number): boolean =>
  !!hazard || (flags.includes('ranged') && !(meleeRange != null && d2 <= meleeRange * meleeRange));
export const drinkSplit = (dmg: number): [number, number] => [Math.ceil(dmg / 2), Math.floor(dmg / 2)];
export const drinkAdv = (adv: number): number => adv - T.drinkAdv;
export const cutValue = (v: number, kind: string, mult = T.cutMult): number =>
  kind === 'flash' || kind === 'sig' || kind === 'sp' ? roundHalfEven(f32(v * f32(mult))) : v;

// ---------------------------------------------------------------- stance (a Signature kind)
export const stanceStore = (stored: number, taken: number): number =>
  Math.min(T.stanceStoreCap, stored + roundHalfEven(f32(taken * f32(T.stanceStoreRate))));
export const stanceRelease = (stored: number): [number, boolean] => [T.stanceBaseDamage + stored, stored >= T.stanceCrushAt];

// ================================================================ combos (§3)
/** Book one more connected hit of a combo: [react hits launches air-hits] (HITS is this hit's combo index). */
export function comboStep(react: string, airborne: boolean, hits: number, launches: number, airHits: number): [string, number, number, number] {
  const bind = react === 'bind' && hits === 0;
  const nh = bind ? T.burstMinHits : hits + 1;
  const na = airborne ? airHits + 1 : airHits;
  const r = bind ? 'bind'
    : react === 'bind' ? 'flinch'
    : airborne && na >= T.comboAirHits ? 'knockdown'
    : react === 'launch' && launches >= T.comboLaunches ? 'knockback'
    : react;
  return [r, nh, r === 'launch' ? launches + 1 : launches, na];
}

// ================================================================ the hidden hit-stun tolerance
export const stunWeight = (react: string, heavy: boolean): number =>
  Math.max(getf(T.stunWeights, react, 1), heavy ? getf(T.stunWeights, 'heavy', 3) : 0);
export const stunAdd = (stun: number, react: string, heavy: boolean): number => f32(stun + f32(stunWeight(react, heavy)));   // (single floats)
export const stunDecay = (stun: number, idle: number): number => (idle >= T.stunDelay ? Math.max(0, f32(stun - f32(T.stunDecay / 60))) : stun);
export const stunOverP = (stun: number, tolerance: number): boolean => stun > tolerance;

// ================================================================ perfect Hoho (§3)
/** An opponent hit window [FROM, TO) of his move now at frame SF is active, or becomes so within T.perfectLead frames. */
export const threatWindowP = (sf: number, from: number, to: number): boolean => sf < to && from - sf <= T.perfectLead;
/** Is a Hoho started now PERFECT against the opponent's hit window [FROM, TO) with volumes VOLS? */
export function perfectHohoP(sf: number, from: number, to: number, vols: Vol[], ax: number, ay: number, az: number,
                             fx: number, fz: number, tx: number, ty: number, tz: number, tr: number, th: number): boolean {
  const r = tr + T.perfectInflate, h = th + T.perfectInflate;
  return threatWindowP(sf, from, to) && vols.some((v) => volHitP(v, ax, ay, az, fx, fz, tx, ty, tz, r, h, 0));
}

// ================================================================ CPU AI helpers (§8)
export type Band = [number, number, ...(string | number | null)[]];
/** The weights (key weight ...) of the first band (LO HI . weights) with LO <= D < HI, as [key, weight] pairs, or null. */
export function bandWeights(bands: Band[], d: number): [string | null, number][] | null {
  for (const [lo, hi, ...w] of bands) {
    if (d >= lo && d < hi) {
      const out: [string | null, number][] = [];
      for (let i = 0; i < w.length; i += 2) out.push([w[i] as string | null, w[i + 1] as number]);
      return out;
    }
  }
  return null;
}
export function heatRange(lo: number, hi: number, heat: number): [number, number] {
  const cut = f32(heat * T.aiHeatRange);                             // (singles, as the Lisp)
  return [Math.max(T.aiMinRange, f32(lo - cut)), Math.max(T.aiMinRange, f32(hi - cut))];
}
export const heatBreakerMult = (heat: number): number => (heat >= T.aiHeatBreaker ? 2 : 1);
export const aiBurstWantedP = (reishi: number, reishiMax: number, nextHit: number): boolean =>
  reishi < T.aiBurstLow * reishiMax || redP(reishi - nextHit, reishiMax);
export function aiGuardMult(gg: number, guardless: boolean): number {
  if (!canGuardP(gg, guardless)) return 0;
  if (gg >= 0.5 * T.ggMax) return 1;
  if (gg >= 0.25 * T.ggMax) return 0.5;
  return 0.15;
}
export const aiHohoSpareP = (fs: number, reishi: number, reishiMax: number): boolean =>
  fs >= T.fsHoho + (reishi < T.aiBurstLow * reishiMax ? T.fsBurst : 0);
export const heatAfter = (heat: number, far: boolean): number => f32(heat + f32((far ? 2 : 1) * f32(T.aiHeatRate / 60)));
