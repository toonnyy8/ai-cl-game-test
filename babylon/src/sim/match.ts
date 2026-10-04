// match.ts <- the battle part of duel/lisp/flow.lisp (spawn-pair, start-match, begin-battle, match-over, time-up,
// go-results, match-system) + main.lisp's sim-step / sim-systems / pilot-read + the sim side of cinema.lisp and the
// engine's cine.lisp (a cinematic is N sim steps during which only the devices are read; its frame-0 FACE-EACH-OTHER is
// the one beat that moves the actors) + debug.lisp's determinism hash line.
// Per step: devices -> vpads (humans); then either the running cinematic or the sim: brain -> fighter -> hazard -> hit
// -> gauge -> match. Hitstop freezes the sim; slow motion runs it on a fraction of the steps (slowAcc), so a sim frame is
// always a whole frame and the same seed replays the same match at any frame rate.
import { T } from './tuning';
import { deg, f32, len32, roundHalfEven } from './math';
import { dirYaw, timeUpWinner } from './rules';
import { Brain, Ent, W, World, emit, fighters, logMsg, setWorld, type Cine } from './types';
import { fighterSystem, playClip, refreshLook, spawnFighter, toIdle, viewStep } from './fighter';
import { gaugeSystem, hitSystem } from './combat';
import { clearHazards, hazardSystem } from './hazards';
import type { Vpad } from './vpad';
import { brainStep } from './ai';

// ---------------------------------------------------------------- cinematics (length-only)
/** Each script's length (its DEFCINE :len) and its frame-0 sim beat: FACE-EACH-OTHER, with a GAP for a flash step. */
export const CINES: Record<string, { len: number; face?: boolean; gap?: number }> = {
  'intro-cine': { len: 300, face: true }, 'ko-cine': { len: 150, face: true }, 'time-cine': { len: 120 },
  'soul-break-cine': { len: 96, face: true },
  'yama-kikon-cine': { len: 186, gap: 3.2 }, 'yama-tenchi-cine': { len: 168, gap: 2.4 }, 'yama-bankai-cine': { len: 138 },
  'ken-kikon-cine': { len: 192, gap: 2.0 }, 'ken-sky-split-cine': { len: 162, gap: 2.6 }, 'ken-nozarashi-cine': { len: 108 },
  'ken-bankai-cine': { len: 186, face: true }, 'ken-oni-kikon-cine': { len: 162, gap: 2.6 },
  'ru-kikon-cine': { len: 186, gap: 2.4 }, 'ru-hakka-cine': { len: 198, gap: 3.0 }, 'ru-awaken-cine': { len: 132 },
};

/** Turn A and V to face each other; with GAP, first put A GAP metres in front of V (a flash step). */
export function faceEachOther(a: Ent, v: Ent, gap: number | null = null): void {
  const p = a.pos, q = v.pos;
  if (gap != null) {
    // (singles op by op, as the Lisp: the actors' new places carry on into the fight)
    const dx = f32(p[0] - q[0]), dz = f32(p[2] - q[2]), d = Math.max(f32(0.01), len32(dx, dz)), g = f32(gap);
    p[0] = q[0] + f32(g * f32(dx / d)); p[2] = q[2] + f32(g * f32(dz / d)); p[1] = 0;
  }
  a.yaw = dirYaw(f32(q[0] - p[0]), f32(q[2] - p[2]));
  v.yaw = dirYaw(f32(p[0] - q[0]), f32(p[2] - q[2]));
  q[1] = 0;
}

/** Start cinematic NAME with actors A and V; AFTER runs when it ends. Hitstop and slow motion are cancelled, the actors
 *  leave their sim states (standing still), then frame 0 runs. */
export function startCine(name: string, a: Ent, v: Ent, after: (() => void) | null = null): void {
  W.time.timeReset();
  const c: Cine = { name, cf: 0, len: CINES[name]?.len ?? 60, a, v, after, skip: false };
  W.cine = c;
  for (const e of [a, v]) { e.f.state = 'cine'; e.f.sf = 0; e.mo.kbLeft = 0; e.mo.vel.fill(0); }
  emit('cine', name, a, v);
  const s = CINES[name];
  if (s && (s.face || s.gap != null)) faceEachOther(a, v, s.gap ?? null);
}
/** Finish the running cinematic: the actors back (the presses buffered during it forgotten), then its AFTER. */
export function endCine(): void {
  const c = W.cine;
  W.cine = null;
  if (c) for (const e of [c.a, c.v]) { refreshLook(e); e.pilot.vpad.flush(); }
  emit('cine-end', c?.name ?? null);
  if (c?.after) c.after();
}
/** Drop the running cinematic without its AFTER. */
export function abortCine(): void { if (W.cine) { W.cine.after = null; endCine(); } }
/** One fixed step of the running cinematic: its frame, the actors' clips; it ends after its last frame (or when skipped). */
export function cineStep(): void {
  const c = W.cine!;
  if (c.skip) { endCine(); return; }
  c.cf++;
  for (const e of [c.a, c.v]) e.look.clipTime += e.look.clipSpeed / 60;
  if (c.cf >= c.len) endCine();
}

// ---------------------------------------------------------------- the battle flow
function setFlow(st: World['flow']): void { W.flow = st; logMsg(`duel -> ${st}`); }

/** A fresh plaza with the two picked fighters 8 m apart, facing. */
export function spawnPair(c1: string, c2: string, o: { cpu1?: boolean; cpu2?: boolean; difficulty?: string;
                          readers?: [((vp: Vpad) => void) | null, ((vp: Vpad) => void) | null] } = {}): void {
  clearHazards();
  W.events = [];
  W.time.timeReset();
  const h = T.resetDistance / 2;
  W.p1 = spawnFighter(0, c1, -h, 0, deg(-90), { cpu: o.cpu1, difficulty: o.difficulty, reader: o.readers?.[0] });
  W.p2 = spawnFighter(1, c2, h, 0, deg(90), { cpu: o.cpu2, difficulty: o.difficulty, reader: o.readers?.[1] });
  W.p1.f.opp = W.p2; W.p2.f.opp = W.p1;
  faceEachOther(W.p1, W.p2);
}

/** The intro ended: FIGHT (P1 on the left of the view; endCine already forgot the presses made during the intro). */
export function beginBattle(): void {
  for (const e of fighters()) { refreshLook(e); toIdle(e, 0); }
  W.tick = 0;
  viewStep(W.p1, W.p2, true);
  setFlow('battle');
}

/** A Kikon / Soul Break took the last Konpaku: FINISH (K.O.), then RESULTS. WINNER null = a draw. */
export function matchOver(winner: Ent | null): void {
  const w = winner === null ? 'draw' : winner === W.p1 ? 0 : 1;
  const we = w === 1 ? W.p2 : W.p1, le = w === 1 ? W.p1 : W.p2;
  W.winner = w;
  setFlow('finish');
  startCine('ko-cine', we, le, goResults);
}
export function timeUp(): void {
  const g1 = W.p1.g, g2 = W.p2.g;
  const w = timeUpWinner(g1.konpaku, g1.reishi, g1.reishiMax, g2.konpaku, g2.reishi, g2.reishiMax);
  W.winner = w;
  setFlow('finish');
  startCine('time-cine', w === 1 ? W.p2 : W.p1, w === 1 ? W.p1 : W.p2, goResults);
}
export function goResults(): void {
  const g1 = W.p1.g, g2 = W.p2.g;
  setFlow('results');
  logMsg(`duel -> RESULTS winner ${W.winner === 0 ? 'P1' : W.winner === 1 ? 'P2' : 'DRAW'} konpaku ${g1.konpaku}-${g2.konpaku}` +
         ` ticks ${W.tick} secs ${Math.fround(W.tick / 60).toFixed(1)}`);
  for (const e of fighters()) {
    const won = W.winner === e.f.side;
    e.f.state = won ? 'win' : 'lose';
    refreshLook(e);
    playClip(e, won ? (e.f.kit.win ?? e.f.kit.stance) : 'sh-lose', { blend: 8 });
  }
  faceEachOther(W.p1, W.p2);
}
/** The match timer (sim frames) and time-up. */
export function matchSystem(): void {
  if (W.flow === 'battle' && --W.timer <= 0) timeUp();
}

// ---------------------------------------------------------------- the fixed step
/** A step without a sim frame (hitstop, slow motion, cinematic): the humans' devices are read into their vpads without
 *  advancing the vpad clock, so a press made now is still buffered afterwards. */
export function pilotRead(): void {
  for (const e of fighters()) { const r = e.pilot.vpad.reader; if (r && !e.brain) r(e.pilot.vpad); }
}
/** Every human fighter's vpad reads its devices this step (inside the step: determinism). */
export function pilotSystem(): void {
  for (const e of fighters()) if (!e.brain) e.pilot.vpad.beginStep();
}
export type BrainStep = (e: Ent, b: Brain) => void;
let brainStepFn: BrainStep = brainStep;
/** The CPU in use: ai.ts (default) or stubai.ts (M1's stand-in, headless --ai stub). */
export function setBrainStep(fn: BrainStep): void { brainStepFn = fn; }
/** Every CPU fighter decides this step (before fighterSystem reads the vpads). */
export function brainSystem(): void {
  for (const e of fighters()) if (e.brain) brainStepFn(e, e.brain);
}
/** One sim frame: the systems in order (a Kikon / Soul Break may start a cinematic mid-way: the rest then waits). */
export function simSystems(): void {
  brainSystem();
  fighterSystem();
  if (!W.cine) hazardSystem();
  if (!W.cine) hitSystem();
  if (!W.cine) gaugeSystem();
  if (!W.cine) matchSystem();
}
/** One fixed 1/60 s step of a running match. */
export function simStep(): void {
  W.tick++;
  if (W.cine) { pilotRead(); cineStep(); }
  else if (!W.time.timeStep()) pilotRead();                          // hitstop: devices only
  else {
    W.slowAcc = Math.fround(W.slowAcc + W.time.slowmoScale(false));   // (single floats, as the Lisp's *slow-acc*)
    if (W.slowAcc >= 1.0) { W.slowAcc -= 1.0; pilotSystem(); simSystems(); }
    else pilotRead();
  }
  if (W.flow === 'battle' && W.tick > 0 && W.tick % 600 === 0) logMsg(stateHashLine());
}

/** The determinism hash: positions quantized to cm, facing to 0.01 rad, every gauge (f flash-step, g guard gauge,
 *  ! = guardless, m the kit meter), n the Konpaku the last Kikon rush was worth, h a CPU's heat. */
export function stateHashLine(): string {
  let s = `duel hash t=${W.tick}`;
  const r = (x: number) => roundHalfEven(x);
  for (const e of fighters()) {
    const p = e.pos, g = e.g, f = e.f;
    const u = f.kit.pips || f.kit.meter?.temp ? ` u${g.meterIdle}` : '';
    s += ` | ${r(f32(100 * p[0]))} ${r(f32(100 * p[1]))} ${r(f32(100 * p[2]))} ${r(f32(100 * e.yaw))} ${f.state.toUpperCase()} ${f.form.toUpperCase()}` +
         ` r${g.reishi} k${g.konpaku} a${r(g.reiatsu)} f${r(g.fs)} g${r(g.gg)}${g.guardless ? '!' : ''} w${r(g.awaken)}` +
         ` m${r(g.meter)}${u}${g.armPending ? '*' : ''} n${f.kikonN}${f.frost > 0 ? ` fr${f.frost}` : ''}` +
         `${e.brain ? ` h${Math.floor(e.brain.heat)}` : ''}`;
  }
  return s;
}

// ---------------------------------------------------------------- the Match: owns a World, runs its steps
export interface MatchOpts {
  p1: string; p2: string; seed: number; cpu1?: boolean; cpu2?: boolean; difficulty?: string;
  readers?: [((vp: Vpad) => void) | null, ((vp: Vpad) => void) | null];
  konpakuStart?: number;
}
export class Match {
  readonly w = new World();
  constructor(readonly opts: MatchOpts) {}

  /** Spawn the fighters, seed the sim stream, play the intro (START-MATCH: nothing of the last match may leak in). */
  start(): this {
    setWorld(this.w);
    const o = this.opts;
    W.winner = null; W.tick = 0; W.timer = 60 * T.matchSeconds; W.pending = []; W.soulBreaks = []; W.kikons = [];
    W.slowAcc = 0;
    abortCine();
    W.seed = o.seed;
    W.rng.seed(o.seed);
    spawnPair(o.p1, o.p2, { cpu1: o.cpu1, cpu2: o.cpu2, difficulty: o.difficulty, readers: o.readers });
    for (const e of fighters()) { e.g.konpaku = o.konpakuStart ?? T.konpakuMax; e.f.state = 'intro'; }
    logMsg(`duel match seed ${o.seed} ${o.p1} vs ${o.p2} ${o.difficulty ?? 'normal'}`);
    setFlow('intro');
    startCine('intro-cine', W.p1, W.p2, beginBattle);
    return this;
  }
  /** One fixed step (makes this match's World current first). */
  step(): void { setWorld(this.w); simStep(); }
  /** The battle runs (intro, battle, finish); false once the results are up. */
  running(): boolean { return this.w.flow !== 'results'; }
  /** The events since the last call (the renderer's / feedback's queue). */
  takeEvents() { const ev = this.w.events; this.w.events = []; return ev; }
  /** The log lines since the last call. */
  takeLog(): string[] { const l = this.w.log; this.w.log = []; return l; }
  /** Run steps until the results (or MAX steps). */
  runToEnd(max = 60 * 60 * 10, onStep?: (m: Match) => void): void {
    for (let i = 0; i < max && this.running(); i++) { this.step(); onStep?.(this); }
  }
}
