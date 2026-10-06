// learn.ts <- duel/lisp/learn.lisp (the learning CPU's pure part, docs/duel/DUEL_LEARNING.md) + ai.lisp's learning-CPU section
// (LRN, LEARN-STEP / -PLAN / -FIRE / -PRESS / -NEUTRAL, the bandit's window, the burst bandits, the tables' storage).
// Character-free: the tables are keyed by situations, action classes, distance bins and command keywords.
//   player model  per SITUATION (9), counts of the human's next ACTION CLASS (10): order 0, and order 1 keyed by his
//                 previous class there; decayed x LP.decay per observation; learnPredict backs order 1 off to order 0,
//                 learnCounter answers the prediction (guard > J > I > guard)
//   bandit        per CONTEXT (form x kit meter third: 24), distance bin (5) and neutral command (10) a discounted EXP3
//                 score; the kit's moves weight x exp(score) (learnMult), rewarded with the next LP.window frames' damage
//   bursts        per burst colour a use / don't two-armed EXP3 re-weighting the base AI's chance (learnBurstP)
//   form          the human's recent results in [-1, 1]; learnPExploit reads him more when he wins
//   storage       learnEncode / learnDecode: a table as a short list of integers, kept by an injectable LearnStore
// Only a CPU facing a human carries a learner (Brain.learn; null = none of this runs, no draws). Its dice are its own
// stream (learnRnd), never simRnd01. The tables are single-float arrays as in the Lisp (Float32Array; f32 arithmetic).
import { T } from './tuning';
import { getf, mod, roundHalfEven } from './math';
import { hohoAllowedP } from './rules';
import { KITS, KIT_COMMANDS, ROSTER, kitCommandMove } from './kit';
import { W, clog, kitOf, oppOf, sideName, stateOf, type Brain, type Ent, type FState, type Snap } from './types';
import { kitCommandOkP } from './fighter';
import { kikonReadyP } from './combat';
import { aiCommand, aiDash, aiGuardK, aiPipHurryP, aiPress } from './ai';

const fr = Math.fround;

export const LEARN_SITUATIONS = ['wake', 'knock', 'h-blocked', 'c-blocked', 'whiff', 'c-hit', 'close', 'mid', 'far'] as const;
/** Situations below this index are events (a counter is planned at their onset). */
export const LEARN_EVENTS = 6;
export const LEARN_ACTIONS = ['guard', 'j', 'k', 'i', 'hoho', 'back', 'l', 'sp', 'o', 'burst'] as const;
/** The neutral commands a kit's moves bands weigh (null = wait): the bandit's arms. */
export const LEARN_ARMS: readonly (string | null)[] = ['q', 'f', 'sig', 'sp1', 'sp2', 'breaker', 'kikon', 'step', 'hoho', null];
const LEARN_BINS = [1.6, 3.0, 5.0, 7.0].map(fr);
const LEARN_BANDS = [2.5, 5.0].map(fr);
/** The answer to each predicted class (I beats guard, guard beats J, J beats K and I, ...). */
const LEARN_COUNTERS: Record<string, string | null> = {
  guard: 'breaker', j: 'guard', k: 'q', i: 'q', hoho: 'hoho-punish', back: null, l: 'guard', sp: 'hoho', o: 'guard', burst: 'dash-in',
};
/** Per situation, answers overriding LEARN_COUNTERS (a predicted burst while our string hits him is baited). */
const LEARN_SIT_COUNTERS: Record<string, Record<string, string | null>> = { 'c-hit': { burst: 'bait', guard: null } };
export const LEARN_BURST_COLORS = ['white', 'blue', 'orange'];

/** The knobs (learn.lisp's defparameters, single floats). Mutable: the tests rebind decay / cap as the Lisp's LET does. */
export const LP = {
  decay: fr(0.97), backoff: fr(2.0), minN: fr(1.5), confident: fr(0.4), eta: fr(0.15), gamma: fr(0.98), sMax: fr(Math.log(4)),
  pFloor: fr(0.05), window: 90, norm: fr(150.0),
  pExploit: { mid: fr(0.35), slope: fr(0.4), lo: fr(0.15), hi: fr(0.6) },
  formK: fr(0.05), formT: 120, formMatch: fr(0.2), episode: { event: 75, neutral: 60 }, back: fr(1.2), cap: 400, armCap: 300,
};
/** Its parts in use (the learning gate's A/B: model only, bandit only). */
export const LEARN_USE = { model: true, bandit: true };
/** Frames after a counter it counts as paid off (damage dealt, none taken). */
const LEARN_READ_T = 60;
/** A learner's base weight for a neutral Hoho its kit's band leaves out (so it can learn one). */
const LEARN_HOHO_W = fr(0.3);

const S = 9, A = 10, ARMS = 10, NBINS = 5, FORMS = 8, METERS = 3;
export const LEARN_ROWS = FORMS * METERS * NBINS;

/** One CPU character's learned tables. */
export class LTab {
  c0 = new Float32Array(S * A);
  c1 = new Float32Array(S * A * A);
  prev = new Int32Array(S).fill(-1);                // his last class per situation
  arms = new Float32Array(LEARN_ROWS * ARMS);
  bursts = new Float32Array(6);                     // colour x (use, don't)
  form = 0;
}

export const learnSit = (k: string): number => (LEARN_SITUATIONS as readonly string[]).indexOf(k);
export const learnAct = (k: string): number => (LEARN_ACTIONS as readonly string[]).indexOf(k);
const posOr = (xs: number[], d: number, dflt: number): number => { const i = xs.findIndex((b) => d < b); return i < 0 ? dflt : i; };
/** Neutral situation index for distance D. */
export const learnBand = (d: number): number => LEARN_EVENTS + posOr(LEARN_BANDS, d, 2);
/** Bandit bin for distance D. */
export const learnBin = (d: number): number => posOr(LEARN_BINS, d, 4);
const clampL = (x: number, lo: number, hi: number): number => Math.max(lo, Math.min(hi, x));
/** Bandit context for form index FORM-I and kit meter fraction METER (0..1). */
export const learnCtx = (formI: number, meter: number): number =>
  Math.min(FORMS - 1, Math.max(0, formI)) * METERS + Math.min(METERS - 1, Math.floor(fr(METERS * clampL(meter, 0, 1))));
export const learnRow = (ctx: number, bin: number): number => ctx * NBINS + bin;

// ---------------------------------------------------------------- the player model
/** The human did class ACT in situation SIT: decay the rows, count it, remember it as his last there. */
export function learnObserve(tab: LTab, sit: number, act: number): LTab {
  const prev = tab.prev[sit], d = LP.decay;
  const bump = (v: Float32Array, base: number) => { for (let a = 0; a < A; a++) v[base + a] = d * v[base + a]; v[base + act] += 1; };
  bump(tab.c0, sit * A);
  if (prev >= 0) bump(tab.c1, (sit * A + prev) * A);
  tab.prev[sit] = act;
  return tab;
}

/** The human's next class in SIT as a probability vector (order 1 given his last class, backed off to order 0) and the
 *  order-0 evidence: [vector or null without evidence, n0]. */
export function learnDist(tab: LTab, sit: number): [Float32Array | null, number] {
  const c0 = tab.c0, c1 = tab.c1, b0 = sit * A, prev = tab.prev[sit], b1 = prev >= 0 ? (b0 + prev) * A : -1;
  let n0 = 0, n1 = 0;
  for (let a = 0; a < A; a++) n0 = fr(n0 + c0[b0 + a]);
  if (b1 >= 0) for (let a = 0; a < A; a++) n1 = fr(n1 + c1[b1 + a]);
  if (n0 <= 0) return [null, 0];
  const p = new Float32Array(A), k = LP.backoff;
  for (let a = 0; a < A; a++) {
    const q0 = fr(c0[b0 + a] / n0);
    p[a] = n1 > 0 ? fr(fr(c1[b1 + a] + fr(k * q0)) / fr(n1 + k)) : q0;
  }
  return [p, n0];
}

/** The human's most likely next class in SIT: [class index (null = no evidence), its probability, the evidence]. */
export function learnPredict(tab: LTab, sit: number): [number | null, number, number] {
  const [p, n] = learnDist(tab, sit);
  if (!p) return [null, 0, n];
  let best = 0;
  for (let a = 1; a < A; a++) if (p[a] > p[best]) best = a;
  return [best, p[best], n];
}

/** Act on a prediction of probability P from evidence N? */
export const learnConfidentP = (p: number, n: number): boolean => n >= LP.minN && p >= LP.confident;

/** The command answering class ACT (in situation SIT: LEARN_SIT_COUNTERS first). */
export function learnCounter(act: number, sit: number | null = null): string | null {
  const k = LEARN_ACTIONS[act], o = sit != null ? LEARN_SIT_COUNTERS[LEARN_SITUATIONS[sit]] : undefined;
  return o && k in o ? o[k] : LEARN_COUNTERS[k] ?? null;
}

const freeSt = (st: string | null): boolean => st === 'idle' || st === 'guard' || st === 'run';
/** Which situation begins this step (index), or null. HPREV / HS: the human's perceived state last step / now (HCONTACT:
 *  what his move last step touched, null = a whiff), OWN-PREV / OWN: ours, OPEN: the open episode (-1 none), D: the
 *  perceived distance, BURST-OPEN: our string's hit just made his burst possible. Events override an open neutral one. */
export function learnOnset(hprev: string, hs: string, hcontact: string | null, ownPrev: string, own: string, open: number, d: number,
                           burstOpen = false): number | null {
  if (hs === 'wakeup' && hprev !== 'wakeup') return 0;
  if (own === 'wakeup' && ownPrev !== 'wakeup') return 1;
  if (hprev === 'guard-hit' && hs !== 'guard-hit') return 2;
  if (ownPrev === 'guard-hit' && own !== 'guard-hit') return 3;
  if (hprev === 'move' && hcontact == null && hs !== 'move') return 4;
  if (burstOpen && open !== 5) return 5;
  if (open < 0 && freeSt(hs) && freeSt(own)) return learnBand(d);
  return null;
}

/** A move kind's action class (null: not one the model counts). */
const KIND_CLASS: Record<string, string> = { quick: 'j', flash: 'k', breaker: 'i', sig: 'l', sp: 'sp', kikon: 'o' };

/** The human's action class index starting this step, or null: a burst begun, a move (from a free state, or a new link:
 *  NEW-START) by its KIND, a guard raised, a Hoho / Step, or AWAY metres backed off within the episode. */
export function learnAction(hprev: string, hs: string, kind: string | null, newStart: boolean, away: number, burst = false): number | null {
  const k = burst ? 'burst'
    : hs === 'move' && (hprev !== 'move' || newStart) ? (kind ? KIND_CLASS[kind] ?? null : null)
      : hs === 'guard' && hprev !== 'guard' ? 'guard'
        : (hs === 'hoho' || hs === 'step') && hprev !== hs ? 'hoho'
          : away > LP.back ? 'back' : null;
  return k ? learnAct(k) : null;
}

/** Frames situation SIT's episode waits. */
export const learnEpisode = (sit: number): number => (sit < LEARN_EVENTS ? LP.episode.event : LP.episode.neutral);

// ---------------------------------------------------------------- the bandit
/** The weight factor of arm ARM in bandit ROW. */
export const learnMult = (tab: LTab, row: number, arm: number): number => fr(Math.exp(tab.arms[row * ARMS + arm]));

/** Discounted EXP3 on the N scores of V from BASE: all x gamma, then ARM (picked with probability PROB) + eta r / prob,
 *  clamped to +-sMax. */
function exp3(v: Float32Array, base: number, n: number, arm: number, prob: number, r: number): void {
  const m = LP.sMax;
  for (let a = 0; a < n; a++) v[base + a] = LP.gamma * v[base + a];
  v[base + arm] = clampL(fr(v[base + arm] + fr(fr(LP.eta * r) / Math.max(prob, LP.pFloor))), -m, m);
}
/** The bandit's update of ROW: arm ARM picked with probability PROB earned R in [-1, 1]. */
export function learnRewardBang(tab: LTab, row: number, arm: number, prob: number, r: number): LTab {
  exp3(tab.arms, row * ARMS, ARMS, arm, prob, r);
  return tab;
}
/** The base AI's chance P of a burst of COLOR re-weighted by that colour's scores: p e^u / (p e^u + (1 - p) e^n). */
export function learnBurstP(tab: LTab, color: number, p: number): number {
  const u = fr(p * fr(Math.exp(tab.bursts[2 * color]))), n = fr(fr(1 - p) * fr(Math.exp(tab.bursts[2 * color + 1])));
  return u + n > 0 ? fr(u / fr(u + n)) : 0;
}
/** COLOR's bandit: USED (or not), that branch taken with probability PROB, earned R. */
export function learnBurstRewardBang(tab: LTab, color: number, used: boolean, prob: number, r: number): LTab {
  exp3(tab.bursts, 2 * color, 2, used ? 0 : 1, prob, r);
  return tab;
}
/** Damage DEALT minus TAKEN (plus Reishi HEALED) in a window, as a reward in [-1, 1]. */
export const learnReward = (dealt: number, taken: number, healed = 0): number => clampL(fr((dealt - taken + healed) / LP.norm), -1, 1);

// ---------------------------------------------------------------- how much it reads
/** The chance a decision takes the model's counter, for the human's FORM (-1 losing .. 1 winning). */
export const learnPExploit = (form: number): number =>
  clampL(fr(LP.pExploit.mid + fr(LP.pExploit.slope * form)), LP.pExploit.lo, LP.pExploit.hi);
/** FORM moved toward R (in [-1, 1]) by K. */
export const learnFormAfter = (form: number, r: number, k: number): number => fr(clampL(fr(fr(fr(1 - k) * form) + fr(k * r)), -1, 1));
/** The learner's own random stream (an LCG mod 2^31): [value in [0, 1), next state]. */
export function learnRnd(state: number): [number, number] {
  const s = ((Math.imul(state, 1103515245) >>> 0) + 12345) & 0x7fffffff;   // (low 31 bits = mod 2^31)
  return [(s >>> 7) / 16777216, s];
}

// ---------------------------------------------------------------- storage
// One integer per entry: index x 65536 + value + 32768. Format 2: 0-89 order 0 (x10), 100-999 order 1 (x10), 1000-2199
// the bandit (x1000), 2300-2308 the last class per situation (+1), 2400-2405 the burst scores (x1000), 2950 the form
// (x1000), 2999 the version (2). Format 1 (999 = 1; 8 situations, 9 classes) is read into format 2, its bandit dropped.
const code = (i: number, v: number): number => i * 65536 + clampL(roundHalfEven(v), -32768, 32767) + 32768;
function largest(v: Float32Array, cap: number, scale: number, min: number): [number, number][] {
  const c: [number, number][] = [];
  for (let i = v.length - 1; i >= 0; i--) if (Math.abs(roundHalfEven(fr(scale * v[i]))) >= min) c.push([i, v[i]]);   // (pushed: last first)
  return c.sort((a, b) => Math.abs(b[1]) - Math.abs(a[1])).slice(0, cap);
}
/** TAB as a list of integers: every counted cell (order 1 only its LP.cap largest), the bandit's LP.armCap largest scores,
 *  the burst scores, the last classes and the form. */
export function learnEncode(tab: LTab): number[] {
  const out: number[] = [code(2950, fr(1000 * tab.form)), code(2999, 2)];
  for (let s = 0; s < S; s++) if (tab.prev[s] >= 0) out.push(code(2300 + s, tab.prev[s] + 1));
  tab.bursts.forEach((v, i) => { if (roundHalfEven(fr(1000 * v)) !== 0) out.push(code(2400 + i, fr(1000 * v))); });
  tab.c0.forEach((v, i) => { if (roundHalfEven(fr(10 * v)) >= 1) out.push(code(i, fr(10 * v))); });
  for (const [i, v] of largest(tab.arms, LP.armCap, 1000, 1)) out.push(code(1000 + i, fr(1000 * v)));
  for (const [i, v] of largest(tab.c1, LP.cap, 10, 1)) out.push(code(100 + i, fr(10 * v)));
  return out;
}
/** A table from learnEncode's integers (format 1 migrated; unknown or out-of-range entries skipped: garbage = fresh). */
export function learnDecode(codes: readonly number[] | null): LTab {
  const tab = new LTab(), v1 = !!codes?.some((c) => Math.floor(c / 65536) === 999);
  const sit1 = (s: number) => (s < 5 ? s : s + 1);                   // format 1's situations: c-hit came in at 5
  for (const c of codes ?? []) {
    const i = Math.floor(c / 65536), v = mod(c, 65536) - 32768;
    if (v1) {
      if (i > -1 && i < 72) tab.c0[sit1(Math.floor(i / 9)) * A + (i % 9)] = Math.max(0, fr(v / 10));
      else if (i >= 100 && i <= 747) {
        const st = Math.floor((i - 100) / 81), r = (i - 100) % 81;
        tab.c1[(sit1(st) * A + Math.floor(r / 9)) * A + (r % 9)] = Math.max(0, fr(v / 10));
      } else if (i >= 900 && i <= 907) tab.prev[sit1(i - 900)] = v >= 1 && v <= 9 ? v - 1 : -1;
      else if (i === 950) tab.form = clampL(fr(v / 1000), -1, 1);
    } else if (i > -1 && i < 90) tab.c0[i] = Math.max(0, fr(v / 10));
    else if (i >= 100 && i <= 999) tab.c1[i - 100] = Math.max(0, fr(v / 10));
    else if (i >= 1000 && i <= 2199) tab.arms[i - 1000] = fr(v / 1000);
    else if (i >= 2300 && i <= 2308) tab.prev[i - 2300] = v >= 1 && v <= A ? v - 1 : -1;
    else if (i >= 2400 && i <= 2405) tab.bursts[i - 2400] = fr(v / 1000);
    else if (i === 2950) tab.form = clampL(fr(v / 1000), -1, 1);
  }
  return tab;
}

/** Where the tables live between matches (the page's soulduel.learn.<i> / .a<i> in the browser: localStorage). LOAD
 *  returns the saved integers or null; SAVE null forgets. Blocked storage may throw: the table then lives in memory. */
export interface LearnStore { load(key: string): number[] | null; save(key: string, codes: number[] | null): void }
export function memoryStore(): LearnStore {
  const m = new Map<string, number[]>();
  return { load: (k) => m.get(k) ?? null, save: (k, c) => { if (c) m.set(k, [...c]); else m.delete(k); } };
}
let store: LearnStore = memoryStore();
export function setLearnStore(s: LearnStore): void { store = s; }
/** Per roster index, the CPUs' learned table of the human (loaded on first use). */
export const learnTables: (LTab | null)[] = new Array(10).fill(null);
/** ASSIST's learner (assist.ts): per roster index, what a human's assist learned of THAT character's CPU. */
export const assistLearnTables: (LTab | null)[] = new Array(10).fill(null);
export const LEARN_KEY = 'soulduel.learn.', ASSIST_LEARN_KEY = 'soulduel.learn.a';

/** Roster index I's table in TABLES (key prefix KEY): in memory, else the store's (nothing saved: a fresh one). */
export function learnTable(i: number, tables = learnTables, key = LEARN_KEY): LTab {
  let t = tables[i];
  if (!t) {
    let codes: number[] | null = null;
    try { codes = store.load(key + i); } catch { codes = null; }
    t = tables[i] = learnDecode(codes ? codes.slice(0, 999) : null);
  }
  return t;
}
/** Roster index I's table of TABLES to the store. */
export function learnSave(i: number, tables = learnTables, key = LEARN_KEY): void {
  const t = tables[i];
  if (t) try { store.save(key + i, learnEncode(t)); } catch { /* blocked storage: memory only */ }
}
/** SETTINGS' RESET LEARNING: every table forgotten, in memory and in the store. */
export function learnResetAll(): void {
  for (let i = 0; i < learnTables.length; i++) {
    learnTables[i] = assistLearnTables[i] = null;
    try { store.save(LEARN_KEY + i, null); store.save(ASSIST_LEARN_KEY + i, null); } catch { /* blocked */ }
  }
}

// ---------------------------------------------------------------- the learner in a match (ai.lisp)
/** A learner's state within one match (Brain.learn); TAB is its character's table, kept across matches. */
export class Lrn {
  sit = -1; epT = 0; away = 0;                      // the open episode, his way away since
  hstate: FState = 'idle'; hstart = -1; hcontact: string | null = null;
  own: FState = 'idle';                             // ... the human (perceived) and we, last step
  cmd: string | null = null; delay = 0; pendT = 0;  // the planned counter, its wait, its life
  arm = -1; bin = 0; prob = 0;                      // the bandit's open window (BIN: its row)
  bw = -1; bwUsed = false; bwProb = 0; bwT = 0;     // a burst bandit's window
  bwDealt = 0; bwTaken = 0; bwReishi = 0; bwKonpaku = 0;
  hburst = false; hcombo = 0;                       // his burst, our combo's hits on him, last step
  winT = 0; wDealt = 0; wTaken = 0;
  formT = 0; fDealt = 0; fTaken = 0;                // the form clock
  stats: [string, number, number][] = [];           // per counter: reads, paid (newest first, as the Lisp's PUSH)
  last: string | null = null;
  reads = 0; paid = 0; readT = 0; rDealt = 0; rTaken = 0;
  readClock = 0;                                    // frames to its next neutral read
  constructor(public tab: LTab, public hx: number, public hz: number, public rng: number) {}
}

/** A fresh learner over TAB, facing opponent O, its stream seeded from the sim stream's state by K (no draw). */
export const newLrn = (tab: LTab, o: Ent, k: number): Lrn => new Lrn(tab, o.pos[0], o.pos[2], 1 + mod(k * W.rng.state, 2147483647));

/** Give CPU E a learner over its character's table. */
export function learnAttach(e: Ent): void {
  e.brain!.learn = newLrn(learnTable(ROSTER.indexOf(e.f.character)), oppOf(e), 7919);
}

/** VS CPU / ENDLESS with LEARNING CPU on (the caller decides: never CPU VS CPU or PRACTICE): P2 learns. */
export function learnMatchStart(on: boolean): void {
  if (on && W.p2.brain) learnAttach(W.p2);
}
/** The match is over: every learner's human's form takes the result, its table is saved. */
export function learnMatchEnd(): void {
  for (const e of [W.p1, W.p2]) {
    const l = e.brain?.learn;
    if (l) {
      const side = e.f.side;
      l.tab.form = learnFormAfter(l.tab.form, W.winner === side ? -1 : W.winner === 'draw' ? 0 : 1, LP.formMatch);
      learnSave(ROSTER.indexOf(e.f.character));
    }
  }
}

/** Take the model's counter now? Its own stream against p_exploit for the human's form. */
export function learnRollP(l: Lrn): boolean {
  const [r, st] = learnRnd(l.rng);
  l.rng = st;
  return r < learnPExploit(l.tab.form);
}

/** Each step: open / close the episodes and count the human's action (the perceived SNAP S, D), plan an event's counter at
 *  its onset, and run the clocks: the counter's wait, the bandit's window, a read's outcome, the form. */
export function learnStep(e: Ent, b: Brain, s: Snap, d: number): void {
  const l = b.learn!, tab = l.tab, own = stateOf(e), hs = s.state, hprev = l.hstate, o = oppOf(e);
  const p = e.pos, dealt = e.g.dealt, taken = o.g.dealt, dx = s.x - l.hx, dz = s.z - l.hz;
  if (d > 0.01 && dx * dx + dz * dz < 0.25)                          // his way away from us (a Hoho's jump is no walk)
    l.away = fr(l.away + fr((dx * (s.x - p[0]) + dz * (s.z - p[2])) / d));
  const n = o.f.comboHits;                                           // our string's hit that opens his burst
  const on = learnOnset(hprev, hs, l.hcontact, l.own, own, l.sit, d, n === T.burstMinHits && l.hcombo !== n && o.g.fs >= T.fsBurst);
  if (on != null) {
    l.sit = on; l.epT = 0; l.away = 0;
    if (on < LEARN_EVENTS) learnPlan(b, l, on);
  }
  const sit = l.sit;
  if (sit >= 0) {
    const burst = !!o.g.burst && !l.hburst;                          // (a burst: its aura, at once)
    const cHit = sit === learnSit('c-hit');                          // (reeling, only a burst is his)
    const act = cHit ? (burst ? learnAct('burst') : null) : learnAction(hprev, hs, s.kind, s.start !== l.hstart, l.away, burst);
    if (act != null) { learnObserve(tab, sit, act); l.sit = -1; }
    else if (++l.epT > learnEpisode(sit) || (cHit && hs !== 'stun' && hs !== 'air')) {
      if (hs === 'guard' || cHit) learnObserve(tab, sit, learnAct('guard'));   // he held guard / took our string
      l.sit = -1;
    }
  }
  if (l.readClock > 0) l.readClock--;
  if (l.cmd) {
    if (l.delay > 0) l.delay--;
    if (--l.pendT <= 0) l.cmd = null;
  }
  if (l.arm >= 0 && --l.winT <= 0) learnSettle(l, dealt, taken);
  if (l.bw >= 0 && --l.bwT <= 0) learnBurstSettle(e, l, dealt, taken);
  if (l.readT > 0 && --l.readT === 0 && taken === l.rTaken && (dealt > l.rDealt || l.last === 'guard')) {   // (a guard pays by taking nothing)
    l.paid++;
    const st = l.stats.find((x) => x[0] === l.last);
    if (st) st[2]++;
  }
  if (++l.formT >= LP.formT) {                                       // his damage balance moves his form
    tab.form = learnFormAfter(tab.form, learnReward(taken - l.fTaken, dealt - l.fDealt), LP.formK);
    l.formT = 0; l.fDealt = dealt; l.fTaken = taken;
  }
  l.hburst = !!o.g.burst; l.hcombo = o.f.comboHits;
  l.hx = s.x; l.hz = s.z; l.hstate = hs; l.hstart = s.start; l.hcontact = s.contact; l.own = own;
}

/** An event's onset: when the model is confident and the roll says read him, plan its counter for the episode (on his
 *  wake-up, a strike timed to meet the end of it). */
function learnPlan(b: Brain, l: Lrn, sit: number): void {
  const [act, p, n] = learnPredict(l.tab, sit);
  if (act != null && learnCounter(act, sit) && LEARN_USE.model && learnConfidentP(p, n) && learnRollP(l)) {
    const c = learnCounter(act, sit)!;
    l.cmd = c; l.pendT = learnEpisode(sit);
    l.delay = sit === 0 && (c === 'q' || c === 'breaker') ? Math.max(0, T.reactionFrames.wakeup - b.delay - 8) : 0;
  }
}

/** The planned counter, once due and we are free: true when it pressed. hoho-punish waits for his Hoho (seen through the
 *  perception delay) and swings where he reappears. */
export function learnFire(e: Ent, b: Brain, s: Snap, d: number): boolean {
  const l = b.learn!, f = e.f;
  if (l.cmd && l.delay <= 0 && freeSt(f.state) && f.lock === 0 && (l.cmd !== 'hoho-punish' || s.state === 'hoho')) {
    const c = l.cmd;
    l.cmd = null;
    return learnPress(e, b, c === 'hoho-punish' ? 'q' : c === 'bait' ? 'guard' : c, d, c === 'hoho-punish');
  }
  return false;
}

/** Press counter CMD at distance D when it can go (a J / K only within its reach, unless ANYWHERE; an SP's Hoho without
 *  flash-step is a guard): true when pressed; the read is counted. */
export function learnPress(e: Ent, b: Brain, cmd0: string, d: number, anywhere = false): boolean {
  const kit = kitOf(e), f = e.f, g = e.g;
  const cmd = cmd0 === 'hoho' && !hohoAllowedP(false, g.fs, f.hohoLock, g.burst) ? 'guard' : cmd0;
  const mv = (KIT_COMMANDS as readonly string[]).includes(cmd) ? kitCommandMove(kit, cmd) : null;
  const ok = cmd === 'q' || cmd === 'f' ? !!mv && kitCommandOkP(e, cmd) && (anywhere || d <= mv.reach + 0.4)
    : cmd === 'guard' ? aiGuardK(e) > 0
      : cmd === 'hoho' || cmd === 'dash-in' ? true
        : !!mv && kitCommandOkP(e, cmd);
  if (!ok) return false;
  if (cmd === 'guard') aiPress(b, 'guard', 30);
  else if (cmd === 'dash-in') aiDash(b, 1.0, 1.5);
  else aiCommand(b, kit, cmd, d, e);
  clog(() => `${sideName(e)} read ${cmd} d ${d.toFixed(1)}`);
  const l = b.learn!;
  l.reads++;
  let st = l.stats.find((x) => x[0] === cmd);
  if (!st) l.stats.unshift(st = [cmd, 0, 0]);
  st[1]++; l.last = cmd;
  b.why = 'read'; l.readT = LEARN_READ_T; l.rDealt = g.dealt; l.rTaken = oppOf(e).g.dealt;
  return true;
}

/** A learning CPU's neutral read is due: its own clock is out, both are free, no Kikon rush on a red opponent nor a pip
 *  hurry comes first; no scripted habit. */
function learnNeutralDueP(e: Ent, b: Brain, s: Snap): boolean {
  const l = b.learn, st = e.f.state;
  return !!l && !b.habit && l.readClock <= 0 && (st === 'idle' || st === 'run') && freeSt(s.state)
    && !kikonReadyP(e) && !aiPipHurryP(e);
}
/** aiReflex: the neutral read when due (the clock's next interval T.aiThink + up to 40 from its own stream): true when it
 *  pressed. */
export function learnReadDue(e: Ent, b: Brain, s: Snap, d: number): boolean {
  if (!learnNeutralDueP(e, b, s)) return false;
  const l = b.learn!, [r, st] = learnRnd(l.rng);
  l.rng = st; l.readClock = getf(T.aiThink, b.difficulty, 24) + Math.floor(40 * r);
  return learnNeutral(e, b, d);
}
/** A neutral read: read him for the band he is in (true when pressed); a predicted Hoho is only primed (the bait). */
function learnNeutral(e: Ent, b: Brain, d: number): boolean {
  const l = b.learn!, [act, p, n] = learnPredict(l.tab, learnBand(d));
  if (act != null && learnCounter(act) && LEARN_USE.model && learnConfidentP(p, n) && learnRollP(l)) {
    const c = learnCounter(act)!;
    if (c !== 'hoho-punish') return learnPress(e, b, c, d);
    l.cmd = c; l.delay = 0; l.pendT = 60;                            // don't feed his Hoho: wait
    aiPress(b, 'guard', 12); b.why = 'read-wait';
    return true;
  }
  return false;
}

/** E's bandit context: its form's index in its character's kits (definition order) x its kit meter's third. */
function learnContext(e: Ent): number {
  const kit = kitOf(e), forms = [...(KITS.get(kit.character)?.keys() ?? [])], m = kit.meter, i = forms.indexOf(kit.form);
  return learnCtx(i < 0 ? forms.length - 1 : i, m ? e.g.meter / getf(m, 'max', 100) : 0);
}

/** The bandit's factors on a neutral pick's WEIGHTS (edited in place) for distance D in E's context; a Hoho the band
 *  leaves out gets LEARN_HOHO_W first when it may go. */
export function learnWeights(e: Ent, l: Lrn, d: number, weights: [string | null, number][]): void {
  if (!LEARN_USE.bandit) return;
  const row = learnRow(learnContext(e), learnBin(d)), f = e.f, g = e.g;
  if (!(weights.some(([k]) => k === 'hoho') || kitOf(e).rooted || !hohoAllowedP(false, g.fs, f.hohoLock, g.burst)))
    weights.unshift(['hoho', LEARN_HOHO_W]);
  for (const kw of weights) {
    const arm = LEARN_ARMS.indexOf(kw[0]);
    if (arm >= 0) kw[1] = fr(kw[1] * learnMult(l.tab, row, arm));
  }
}
/** The bandit's window for arm CMD picked from WEIGHTS (its probability for the importance weight): an open one is settled
 *  first. */
export function learnWindow(e: Ent, l: Lrn, d: number, weights: [string | null, number][], cmd: string | null): void {
  const arm = LEARN_ARMS.indexOf(cmd), dealt = e.g.dealt, taken = oppOf(e).g.dealt;
  let sum = 0;
  for (const [, w] of weights) sum = fr(sum + w);
  if (arm >= 0 && sum > 0 && LEARN_USE.bandit) {
    if (l.arm >= 0) learnSettle(l, dealt, taken);
    l.arm = arm; l.bin = learnRow(learnContext(e), learnBin(d));
    l.prob = fr((weights.find(([k]) => k === cmd)?.[1] ?? 0) / sum);
    l.winT = LP.window; l.wDealt = dealt; l.wTaken = taken;
  }
}
/** Close the bandit's window: its damage balance rewards its arm. */
function learnSettle(l: Lrn, dealt: number, taken: number): void {
  learnRewardBang(l.tab, l.bin, l.arm, l.prob, learnReward(dealt - l.wDealt, taken - l.wTaken));
  l.arm = -1;
}
/** A burst decision of COLOR (USED or not, that branch's probability from PROB) opens its bandit's window, unless one is
 *  open. */
function learnBurstOpen(e: Ent, l: Lrn, color: string | null, used: boolean, prob: number): void {
  const c = color ? LEARN_BURST_COLORS.indexOf(color) : -1, g = e.g;
  if (c >= 0 && l.bw < 0 && LEARN_USE.bandit) {
    l.bw = c; l.bwUsed = used; l.bwProb = fr(used ? prob : 1 - prob); l.bwT = LP.window;
    l.bwDealt = g.dealt; l.bwTaken = oppOf(e).g.dealt; l.bwReishi = g.reishi; l.bwKonpaku = g.konpaku;
  }
}
/** Close the burst window: the damage balance, plus the Reishi healed (WHITE) when no soul was lost in it. */
function learnBurstSettle(e: Ent, l: Lrn, dealt: number, taken: number): void {
  const g = e.g, tk = taken - l.bwTaken;
  const healed = g.konpaku === l.bwKonpaku ? Math.max(0, g.reishi - l.bwReishi + tk) : 0;
  learnBurstRewardBang(l.tab, l.bw, l.bwUsed, l.bwProb, learnReward(dealt - l.bwDealt, tk, healed));
  l.bw = -1;
}
/** The base AI's chance P of a burst of COLOR, re-weighted by a learning CPU's burst bandit. */
export function aiBurstChance(b: Brain, color: string | null, p: number): number {
  const l = b.learn, c = color ? LEARN_BURST_COLORS.indexOf(color) : -1;
  return l && c >= 0 && LEARN_USE.bandit ? learnBurstP(l.tab, c, p) : p;
}
/** ai.lisp AI-BURST-ROLLED's learner half: a decision of COLOR opens the burst bandit's window. */
export function learnBurstRolled(e: Ent, b: Brain, color: string | null, yes: boolean, q: number): void {
  if (b.learn) learnBurstOpen(e, b.learn, color, yes, q);
}
