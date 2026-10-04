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

// ---------------------------------------------------------------- bodies (body.lisp / *-art.lisp: the hurt cylinder only)
export interface Body { name: string; hurtR: number; hurtH: number }
export const BODIES: Record<string, Body> = {
  yamamoto: { name: 'yamamoto', hurtR: 0.36, hurtH: 1.65 },
  kenpachi: { name: 'kenpachi', hurtR: 0.45, hurtH: 2.0 },
  'kenpachi-oni': { name: 'kenpachi-oni', hurtR: 0.45, hurtH: 2.0 },   // body-variant of kenpachi: the same hurt cylinder
  skeleton: { name: 'skeleton', hurtR: 0.3, hurtH: 1.7 },
  senjumaru: { name: 'senjumaru', hurtR: 0.36, hurtH: 1.7 },
};
export const findBody = (name: string | null): Body => (name && BODIES[name]) || { name: name ?? 'default', hurtR: 0.35, hurtH: 1.8 };

export type FState = 'idle' | 'guard' | 'guard-hit' | 'step' | 'run' | 'hoho' | 'move' | 'stun' | 'air' | 'down' | 'wakeup'
  | 'cine' | 'intro' | 'win' | 'lose';

/** How a fighter's body moves: walk / dash velocity, a knockback slide, airborne. */
export class Motion {
  vel = [0, 0, 0];          // m/s (x z walking or dashing; y while airborne)
  kb = [0, 0, 0];           // slide, metres per frame (x z): knockback, pushback, Step
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
  ox = 0; oz = 0; dist = 0;     // the opponent at the start of this step, and the distance to him
  runYaw = 0;
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
  reiatsu = 0;
  fs = T.fsMax; fsIdle = 0;
  burst: 'white' | 'blue' | 'orange' | null = null; burstT = 0;
  awakeRegen = 0; awakeT = 0;
  gg = T.ggMax; ggIdle = 0; guardless = false;
  awaken = 0; awakened = false; evolution = false;
  meter = 0; meterIdle = 0;
  formLeft = 0; formTotal = 0; burnStep = 0;
  armPending: Move | 'none' | null = null; armOwed = false;
  takenMelee = 0; takenRanged = 0;
  froze = false;
  stun = 0; stunIdle = 0;       // the hidden hit-stun (no HUD)
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
  heat = 0;
  intent = 'approach'; intentT = 0;
  strafe = 1; strafeT = 0;
  press: string | null = null; pressMod = false; pressLeft = 0;
  decideT = 0;
  rollKey = -1;                 // the opponent move start the reflex rolls were made for
  guardRoll = 1; hohoRoll = 1; reactRoll = 1;   // this event's rolls (1 = never)
  was: FState = 'idle';         // its fighter's state at the previous step (block punish)
  breakKey = -1;                // the guard episode the Breaker roll was made for
  burstT = 0; burstRolled = false;
  dash = 0; dashTo = 0;         // a held dash: +1 toward / -1 away, until this distance
  bankaiRolled = false;
  act: string | null = null; why: string | null = null;
  learn: null = null;           // the learning CPU (learn.lisp, M6): always null, its call sites skipped
  jkey = -1; jstarts: number[] = [];   // his last perceived J's start; the ticks his J's started (aiMashP)
  sx = 0; sy = 0;               // the stick it writes this step (stub)
  constructor(difficulty = 'normal', delay = 14) { this.difficulty = difficulty; this.delay = delay; }
}

/** A fighter entity: transform + motion + fighter + gauges + pilot (+ brain when the CPU plays it) + body + look. */
export class Ent {
  pos = [0, 0, 0];
  yaw = 0;
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
  x = 0; y = 0; z = 0; px = 0; pz = 0; yaw = 0;
  speed = 0; turn = 0; size = 0;
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
