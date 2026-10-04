// types.ts <- duel/lisp/components.lisp: the data a SOUL DUEL entity carries, as plain classes (no ECS: two fighters and
// a hazard array owned by the World), plus the World itself (the Lisp's sim specials: *match-tick*, *pending*, *cine*,
// the view, the sim rng ...). A Match (match.ts) owns one World and makes it current (W) for the steps it runs.
// The cosmetic MODEL / BLADE components are reduced to a `look` bag the renderer reads (clip, move frame, flash timers).
import { T } from './tuning';
import { newVpad, type Vpad } from './vpad';
import { TimeState } from './time';
import { newSimRng, type Rng } from './rng';
import type { HitWin, Kit, Move } from './kit';
import type { DefState } from './rules';
import type { Lrn } from './learn';

// ---------------------------------------------------------------- bodies (body.lisp / *-art.lisp: the hurt cylinder only)
export interface Body { name: string; hurtR: number; hurtH: number }
export const BODIES: Record<string, Body> = {
  yamamoto: { name: 'yamamoto', hurtR: 0.36, hurtH: 1.65 },
  kenpachi: { name: 'kenpachi', hurtR: 0.45, hurtH: 2.0 },
  'kenpachi-oni': { name: 'kenpachi-oni', hurtR: 0.45, hurtH: 2.0 },   // body-variant of kenpachi: the same hurt cylinder
  rukia: { name: 'rukia', hurtR: 0.34, hurtH: 1.5 },
  'rukia-zero': { name: 'rukia-zero', hurtR: 0.34, hurtH: 1.5 },     // body-variants of rukia: the same hurt cylinder
  'rukia-bankai': { name: 'rukia-bankai', hurtR: 0.34, hurtH: 1.5 },
  skeleton: { name: 'skeleton', hurtR: 0.3, hurtH: 1.7 },
  ichigo: { name: 'ichigo', hurtR: 0.38, hurtH: 1.8 },
  senjumaru: { name: 'senjumaru', hurtR: 0.36, hurtH: 1.7 },
};
export const findBody = (name: string | null): Body => (name && BODIES[name]) || { name: name ?? 'default', hurtR: 0.35, hurtH: 1.8 };

export type FState = 'idle' | 'guard' | 'guard-hit' | 'step' | 'run' | 'hoho' | 'move' | 'stun' | 'air' | 'down' | 'wakeup'
  | 'cine' | 'intro' | 'win' | 'lose';

/** How a fighter's body moves: walk / dash velocity, a knockback slide, airborne. */
export class Motion {
  vel = new Float32Array(3); // m/s (x z walking or dashing; y while airborne)   (f32vecs, as the Lisp's)
  kb = new Float32Array(3);         // slide, metres per frame (x z): knockback, pushback, Step
  kbLeft = 0;               // slide frames left
  grounded = true;
}

/** What the renderer reads (the Lisp MODEL component's sim-side writes): the clip a state / move started, its speed,
 *  the clip time, alpha (Hoho vanish), super / flare flashes, the weapon key. Cosmetic: the sim never reads it back. */
export class Look {
  clip: string | null = null;
  clipSpeed = 1;
  clipTime = 0;
  blend = 0;
  alpha = 1;
  super = 0;
  flare = 0;
  weapon: string | null = null;
  hide: string[] = [];
}

/** One side of the duel: its kit (character + form), state machine and combo bookkeeping (components.lisp FIGHTER). */
export class Fighter {
  side: number;
  opp: Ent | null = null;
  character: string;
  form = 'base';
  kit: Kit;
  state: FState = 'idle';
  sf = 0;                       // frames in the state; in 'move' the move frame (0 = first)
  phase: string | null = null;  // move: hold aura dash follow main; stun: the reaction kind
  move: Move | null = null;
  button: string | null = null; // the vpad button that started the move (holds, releases)
  hold = 0;                     // frames in the pre-strike phase
  follow = false;               // this Kikon rush strike is the follow-up (its hit = the Kikon)
  armorLeft = 0;
  kikonN = 2;                   // Konpaku his current Kikon rush is worth (read at rush start)
  cd = [0, 0, 0, 0, 0, 0, 0];   // frames each KIT_COMMANDS slot still cools down (kept through resets)
  hits = 0;                     // bitmask: hit windows of the current move that connected
  contact: 'hit' | 'block' | null = null;
  queued: string | null = null; // the latch: the J / K link (q / f, or sig) pressed during this string link
  chained = false;              // this move is a string follow-up link started by the latch
  landSf = -1;                  // move frame of the first connect (cancel windows open)
  dmgBonus = 0;                 // added to the move's damage (stance: stored)
  crush = false;                // this move now crushes guard (stance >= 150, SP2 held)
  stun = 0;                     // frames the reaction / blockstun lasts
  glock = false;                // blockstun: the guard lock holds him
  blockAdv = 0;
  freeze = 0;                   // frames this fighter alone is frozen (super freeze)
  lock = 0;                     // frames inputs are ignored (reset neutral, perfect Hoho victim)
  freezeNext = 0; lockNext = 0; // set by the opponent during fighterSystem, applied after both stepped
  hohoLock = 0;
  guardT = 0;                   // frames Guard has been held (raised at T.guardRaise)
  warded = -1;
  stored = 0;                   // stance: damage absorbed
  charge = 0;                   // hold frames when a charge move was released (Shiranui)
  perfect = false;              // this Hoho was perfect: its counter strike is pending
  assistNext = false; assisted = false;
  endChase = false;             // this move started off a J / K ender's hit (or ORANGE's restart): it chases
  gcLeft = 0;                   // frames a guard cancel still keeps attacks out
  burst: string | null = null;  // the burst mode pressed this step (applied after both stepped)
  chain = 0;                    // ORANGE: frames the next move started still has its startup cut
  invuln = 0;
  private f32s = new Float32Array(4);   // ox oz dist runYaw: single floats in the Lisp
  get ox(): number { return this.f32s[0]; } set ox(v: number) { this.f32s[0] = v; }
  get oz(): number { return this.f32s[1]; } set oz(v: number) { this.f32s[1] = v; }
  get dist(): number { return this.f32s[2]; } set dist(v: number) { this.f32s[2] = v; }
  get runYaw(): number { return this.f32s[3]; } set runYaw(v: number) { this.f32s[3] = v; }     // the opponent at the start of this step, and the distance to him
  comboHits = 0; comboLaunches = 0; comboAir = 0; comboDmg = 0;   // as a victim: the running combo
  frost = 0;
  callout: string | null = null; calloutT = 0;
  char: unknown = null;          // a character file's own state (fresh with every fighter: Senjumaru's loom)
  constructor(side: number, character: string, kit: Kit) {
    this.side = side; this.character = character; this.kit = kit;
  }
}

/** A fighter's numbers and his match stats (components.lisp GAUGES). */
export class Gauges {
  reishi: number; reishiMax: number;
  konpaku = T.konpakuMax;
  // the single-float gauges of the Lisp (components.lisp): stored as f32 so their threshold crossings fall on the same step
  private f32s = new Float32Array([0, T.fsMax, T.ggMax, 0, 0, 0]);
  get reiatsu(): number { return this.f32s[0]; } set reiatsu(v: number) { this.f32s[0] = v; }
  get fs(): number { return this.f32s[1]; } set fs(v: number) { this.f32s[1] = v; }
  get gg(): number { return this.f32s[2]; } set gg(v: number) { this.f32s[2] = v; }
  get awaken(): number { return this.f32s[3]; } set awaken(v: number) { this.f32s[3] = v; }
  get meter(): number { return this.f32s[4]; } set meter(v: number) { this.f32s[4] = v; }
  get stun(): number { return this.f32s[5]; } set stun(v: number) { this.f32s[5] = v; }
  fsIdle = 0;
  burst: 'white' | 'blue' | 'orange' | null = null; burstT = 0;
  awakeRegen = 0; awakeT = 0;
  ggIdle = 0; guardless = false;
  awakened = false; evolution = false;
  meterIdle = 0;
  formLeft = 0; formTotal = 0; burnStep = 0;
  armPending: Move | 'none' | null = null; armOwed = false;
  takenMelee = 0; takenRanged = 0;
  froze = false;
  stunIdle = 0;                 // (stun: the hidden hit-stun, no HUD)
  dealt = 0; kikons = 0; perfects = 0; bestCombo = 0; counters = 0; evoT = -1;
  constructor(reishi: number) { this.reishi = reishi; this.reishiMax = reishi; }
}

/** Who drives the fighter: a vpad. CAM-RELATIVE: the stick is camera-relative (humans); else it is already
 *  (strafe, toward) relative to the opponent (the CPU). */
export class Pilot {
  vpad: Vpad;
  camRelative: boolean;
  constructor(vpad: Vpad = newVpad(), camRelative = true) { this.vpad = vpad; this.camRelative = camRelative; }
}

/** What the CPU sees of its opponent at one step (ai.lisp SNAP). Ring entries are reused: fields a state doesn't set
 *  keep their last value, as in the Lisp. */
export class Snap {
  x = 0; z = 0;
  state: FState = 'idle'; kind: string | null = null; phase: string | null = null;
  sf = 0; s = 0; activeEnd = 0;
  left = 0;                     // frames left of his move (99 = still charging / dashing) or stun
  start = 0;                    // tick his current move / guard began (one roll per event)
  reach = 0; guardT = 0; projectile = false;
  flags: string[] = [];         // his move's flags (parry bind ...)
  contact: 'hit' | 'block' | null = null;
  tell: [number, number] | null = null;
}

/** The CPU player (ai.lisp BRAIN, components.lisp): delayed perception, the current intent, anti-stall heat, the button
 *  it is holding. Identity comes from the kit's ai tables. stubai.ts drives it with sx / sy only. */
export class Brain {
  difficulty: string;
  delay: number;                // perception delay, frames
  ring: (Snap | null)[] = new Array(32).fill(null);   // SNAPs of the opponent, one per step
  head = 0;
  private f32s = new Float32Array([0, 1, 0, 0]);   // heat strafe dash dashTo: single floats in the Lisp
  get heat(): number { return this.f32s[0]; } set heat(v: number) { this.f32s[0] = v; }
  get strafe(): number { return this.f32s[1]; } set strafe(v: number) { this.f32s[1] = v; }
  get dash(): number { return this.f32s[2]; } set dash(v: number) { this.f32s[2] = v; }
  get dashTo(): number { return this.f32s[3]; } set dashTo(v: number) { this.f32s[3] = v; }
  intent = 'approach'; intentT = 0;
  strafeT = 0;
  press: string | null = null; pressMod = false; pressLeft = 0;
  decideT = 0;
  rollKey = -1;                 // the opponent move start the reflex rolls were made for
  guardRoll = 1; hohoRoll = 1; reactRoll = 1;   // this event's rolls (1 = never)
  was: FState = 'idle';         // its fighter's state at the previous step (block punish)
  breakKey = -1;                // the guard episode the Breaker roll was made for
  burstT = 0; burstRolled = false;
  // (dash dashTo: a held dash, +1 toward / -1 away, until this distance)
  bankaiRolled = false;
  act: string | null = null; why: string | null = null;
  learn: Lrn | null = null;     // the learning CPU (learn.ts; null = off: nothing of it runs)
  habit: string | null = null;  // debug: a scripted player's habit (habits.ts; the learning / ASSIST gates)
  jkey = -1; jstarts: number[] = [];   // his last perceived J's start; the ticks his J's started (aiMashP)
  sx = 0; sy = 0;               // the stick it writes this step (stub)
  constructor(difficulty = 'normal', delay = 14) { this.difficulty = difficulty; this.delay = delay; }
}

/** A fighter entity: transform + motion + fighter + gauges + pilot (+ brain when the CPU plays it) + body + look. */
export class Ent {
  pos = new Float32Array(3);  // (the Lisp's transform is an f32vec and a single-float yaw: stores round to f32)
  private yaw32 = 0;
  get yaw(): number { return this.yaw32; }
  set yaw(v: number) { this.yaw32 = Math.fround(v); }
  mo = new Motion();
  f: Fighter;
  g: Gauges;
  pilot: Pilot;
  brain: Brain | null = null;
  body: Body;
  look = new Look();
  alive = true;
  constructor(f: Fighter, g: Gauges, pilot: Pilot, body: Body) { this.f = f; this.g = g; this.pilot = pilot; this.body = body; }
}

/** A hit that is not a fighter's melee: fire wave, Shiranui, pillars, line cuts (looks only), binds, rifts. */
export class Hazard {
  kind: string;
  owner: Ent;
  // (single floats in the Lisp's hazard component: stored as f32)
  private f32s = new Float32Array(9);
  get x(): number { return this.f32s[0]; } set x(v: number) { this.f32s[0] = v; }
  get y(): number { return this.f32s[1]; } set y(v: number) { this.f32s[1] = v; }
  get z(): number { return this.f32s[2]; } set z(v: number) { this.f32s[2] = v; }
  get px(): number { return this.f32s[3]; } set px(v: number) { this.f32s[3] = v; }
  get pz(): number { return this.f32s[4]; } set pz(v: number) { this.f32s[4] = v; }
  get yaw(): number { return this.f32s[5]; } set yaw(v: number) { this.f32s[5] = v; }
  get speed(): number { return this.f32s[6]; } set speed(v: number) { this.f32s[6] = v; }
  get turn(): number { return this.f32s[7]; } set turn(v: number) { this.f32s[7] = v; }
  get size(): number { return this.f32s[8]; } set size(v: number) { this.f32s[8] = v; }
  age = 0; life = 0; delay = 0;
  hitsLeft = 1; rehit = 0;
  hw: HitWin | null = null;
  src = false; fragile = false;
  hook: string | null = null; data: unknown = null;
  look: string | null = null;
  alive = true;
  constructor(kind: string, owner: Ent) { this.kind = kind; this.owner = owner; }
}

/** One hit collected this step, with what it needs of the attacker as he was then (applied after all are collected). */
export interface Pending {
  att: Ent; def: Ent; hw: HitWin; i: number; sx: number; sz: number; hazard: Hazard | null;
  state: DefState; red: boolean; mv: Move | null; bonus: number; crush: boolean;
}

/** A running cinematic: only its length and its actors matter to the sim (cinema.lisp / engine cine.lisp). */
export interface Cine { name: string; cf: number; len: number; a: Ent; v: Ent; after: (() => void) | null; skip: boolean }

/** An event for the renderer / feedback (fighters as their side numbers). */
export interface SimEvent { kind: string; tick: number; args: unknown[] }

export type Flow = 'intro' | 'battle' | 'finish' | 'results';

export class World {
  tick = 0;                         // *MATCH-TICK*: fixed steps since the battle began
  time = new TimeState();
  rng: Rng = newSimRng();
  slowAcc = 0;                      // slow motion: sim frames owed
  p1!: Ent; p2!: Ent;
  hazards: Hazard[] = [];
  pending: Pending[] = [];
  kikons: [Ent, Ent, Move][] = [];
  soulBreaks: [Ent, Ent][] = [];
  cine: Cine | null = null;
  events: SimEvent[] = [];
  flow: Flow = 'intro';
  timer = 0;
  winner: 0 | 1 | 'draw' | null = null;
  seed = 1;
  blowAways = 0;
  // the view humans steer by (fighter.ts viewStep)
  viewX = 0; viewZ = 1; viewSide = 1; behindYaw = 0; viewBehind = false;
  /** Combat log lines ("[tick] ..."), when on. */
  combatLog: string[] | null = null;
  /** Lines the Lisp logs with LOG-MSG (RESULTS, hash lines). */
  log: string[] = [];
}

/** The current World (the Lisp's specials): a Match makes its World current before running a step. */
export let W: World = new World();
export function setWorld(w: World): void { W = w; }

export const fighters = (): Ent[] => [W.p1, W.p2];
export const simRnd01 = (): number => W.rng.float();

export function emit(kind: string, ...args: unknown[]): void {
  W.events.push({ kind, tick: W.tick, args: args.map((a) => (a instanceof Ent ? a.f.side : a instanceof Hazard ? a.kind : a)) });
}
/** Combat log line "[tick] ..." while the log is on (the message isn't built otherwise). */
export function clog(msg: () => string): void {
  if (W.combatLog) W.combatLog.push(`[${String(W.tick).padStart(6)}] ${msg()}`);
}
export function logMsg(line: string): void { W.log.push(line); }
export const sideName = (e: Ent): string => (e.f.side === 0 ? 'P1' : 'P2');
export const oppOf = (e: Ent): Ent => e.f.opp!;
export const kitOf = (e: Ent): Kit => e.f.kit;
export const stateOf = (e: Ent): FState => e.f.state;
export const cpuP = (e: Ent): boolean => !!e.brain;
/** Does E's current form have passive P (ward pierce projectile-cut scorch cut drink ...)? */
export const passiveP = (e: Ent, p: string): boolean => e.f.kit.passives.includes(p);
