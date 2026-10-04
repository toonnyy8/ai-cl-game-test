// endless.ts <- duel/lisp/endless.lisp (the run; its screens are src/ui/flow.ts, its STAGE tag src/render/hud.ts): one
// human P1 against a gauntlet of CPU stages, the carry-over between them, the record per character. The rules (the ramp,
// the bag, the carry, the record comparison) are endless-rules.ts. The record is the page's (duel/web/pwa.js page get /
// set 30 + 2i = stages, 31 + 2i = seconds of roster index i, localStorage soulduel.endless.<2i | 2i+1>) through an
// injectable store, so both builds on one origin share it. A Run makes each stage's Match; Match.start calls its apply.
// Log: "duel endless start ...", "duel endless stage ...", "duel endless clear ...", "duel endless over ..." (the Lisp's).
// No Babylon, no DOM.
import { T } from './tuning';
import { roundHalfEven } from './math';
import { ROSTER, findKit } from './kit';
import { Brain, W, kitOf } from './types';
import { setForm } from './combat';
import { Match, type MatchOpts } from './match';
import { DIFFICULTIES, endlessBetterP, endlessCarry, endlessDifficulty, endlessOpponent, endlessRamp, endlessStageSeed,
  type EndlessCarry, type EndlessSnap } from './endless-rules';

// ---------------------------------------------------------------- the record (the page's slots)
export interface EndlessStore { get(key: string): number; set(key: string, v: number): void }
export const ENDLESS_KEY = 'soulduel.endless.';
export function memoryEndlessStore(): EndlessStore & { m: Map<string, number> } {
  const m = new Map<string, number>();
  return { m, get: (k) => m.get(k) ?? 0, set: (k, v) => { m.set(k, v); } };
}
let store: EndlessStore = memoryEndlessStore();
export function setEndlessStore(s: EndlessStore): void { store = s; }
/** CHARACTER's stored best: [stages, seconds] (0 0 = none; roster index >= 10 has no slot). */
export function endlessBest(character: string): [number, number] {
  const i = ROSTER.indexOf(character);
  return i >= 0 && i < 10 ? [store.get(ENDLESS_KEY + 2 * i), store.get(ENDLESS_KEY + (2 * i + 1))] : [0, 0];
}

export const mmSs = (secs: number): string => `${Math.floor(secs / 60)}:${String(secs % 60).padStart(2, '0')}`;
const kitName = (c: string): string => findKit(c, 'base').name ?? c.toUpperCase();
/** A fresh run seed from the clock (endless-new-seed). */
export const endlessNewSeed = (nowMs = Date.now()): number => 1 + (Math.floor(nowMs) % 100000);

export type ClearRow = 'stay' | 'revert' | 'quit';
export interface ClearLines { title: string; times: string; konpaku: string; full: string; kept: string; next: string; ramp: string;
  rows: ClearRow[]; labels: string[]; notes: string[] }
export interface OverLines { title: string; stages: string; time: string; best: string; stats: [string, string][]; foes: string }

// ---------------------------------------------------------------- the run
export class Run {
  stage = 0;                        // the stage being played (1-based)
  cleared = 0;
  carry: EndlessCarry | null = null;  // P1's carry into the stage being started (null = a fresh P1)
  snap: EndlessSnap | null = null;    // P1 at the last clear
  ticks = 0;                        // battle ticks of the cleared stages: the run time
  stageTicks = 0;                   // the last cleared stage's
  stats = [0, 0, 0, 0];             // the run's DAMAGE, KIKONS, PERFECT HOHOS, BEST COMBO (P1's)
  foes: string[] = [];              // the opponents faced, oldest first
  record = false;                   // this run wrote a new best record
  lost = false;
  log: string[] = [];
  clear: ClearLines | null = null;
  over: OverLines | null = null;
  /** P1, START DIFFICULTY, run SEED; DEBUG: never writes the record; AUTO: the autopilot's CLEAR policy (P1 a HARD CPU);
   *  OPTS: the stage matches' devices / learner (the flow's). */
  constructor(readonly p1: string, readonly floor: string, readonly seed: number,
              readonly o: { debug?: boolean; auto?: 'stay' | 'revert' | null; opts?: Partial<MatchOpts> } = {}) {}

  /** A run from STAGE (1 from the menu), P1 fresh: its first Match, started. */
  start(stage = 1): Match {
    this.stage = stage - 1;
    this.log.push(`duel endless start seed ${this.seed} P1 ${this.p1} floor ${this.floor}${this.o.debug ? ' debug' : ''}`);
    return this.nextStage();
  }
  /** The next stage: its opponent from the bag, its seed, its Match (started; Match.start calls apply). */
  nextStage(): Match {
    const n = ++this.stage, opp = endlessOpponent(this.seed, n, ROSTER);
    this.foes.push(opp);
    return new Match({ ...this.o.opts, p1: this.p1, p2: opp, seed: endlessStageSeed(this.seed, n), cpu1: false, cpu2: true,
                       difficulty: this.floor, setup: () => this.apply() }).start();
  }
  /** Match.start's hook (W current): P1's carry over his fresh fighter, P2's ramp (difficulty, Reishi, awakening), the
   *  autopilot's brain on P1. */
  apply(): void {
    const n = this.stage, r = endlessRamp(n), d = endlessDifficulty(this.floor, n, DIFFICULTIES);
    const p1 = W.p1, p2 = W.p2, g1 = p1.g, g2 = p2.g, b = p2.brain!, c = this.carry;
    const delay = (dd: string) => (T.aiDelay as Record<string, number>)[dd] ?? 14;
    if (c) {
      if (c.form !== p1.f.form) setForm(p1, c.form);
      g1.konpaku = c.konpaku; g1.reiatsu = c.reiatsu; g1.fs = c.fs; g1.awaken = c.awaken; g1.awakened = c.awakened; g1.meter = c.meter;
    }
    b.difficulty = d; b.delay = delay(d);
    const rm = roundHalfEven((g2.reishiMax * r[4]) / 100);
    g2.reishiMax = rm; g2.reishi = rm; g2.awaken = r[2];
    if (r[3]) {                                                    // spawned awakened: the awaken form, no cinematic
      setForm(p2, kitOf(p2).awakenForm!);
      g2.awakened = true; g2.awaken = 0;
      const st = (kitOf(p2).meter as { start?: number } | null)?.start;
      if (st != null) g2.meter = st;
    }
    if (this.o.auto) {                                             // the autopilot: P1 is a HARD CPU
      p1.brain = new Brain('hard', delay('hard'));
      p1.pilot.vpad.reader = null; p1.pilot.camRelative = false;
    }
    this.log.push(`duel endless stage ${n} vs ${p2.f.character} diff ${d} reishi ${g2.reishiMax} awaken ${r[3] ? 'awakened' : r[2]}` +
      ` seed ${W.seed} P1 form ${p1.f.form} konpaku ${g1.konpaku} awaken ${roundHalfEven(g1.awaken)} meter ${roundHalfEven(g1.meter)}`);
  }

  /** The stage's results are up (go-results' hook, W = the stage's world): its stats into the run; a P1 win is a clear
   *  (the snapshot, the record, STAGE CLEAR's lines: true), anything else ends the run (its RESULTS lines: false). */
  stageEnd(): boolean {
    const g = W.p1.g, s = this.stats;
    s[0] += g.dealt; s[1] += g.kikons; s[2] += g.perfects; s[3] = Math.max(s[3], g.bestCombo);
    if (W.winner !== 0) { this.end(); return false; }
    this.cleared++;
    this.stageTicks = W.tick;
    this.ticks += W.tick;
    this.snap = { character: W.p1.f.character, form: W.p1.f.form, konpaku: g.konpaku, reiatsu: g.reiatsu, fs: g.fs,
                  awaken: g.awaken, awakened: g.awakened, meter: g.meter };
    this.saveRecord();
    this.clearLines();
    return true;
  }
  /** At every clear (not in a debug run): the run so far into the page when it beats the stored best. */
  saveRecord(): void {
    const i = ROSTER.indexOf(this.p1), secs = roundHalfEven(this.ticks / 60);
    if (this.o.debug || i < 0 || i >= 10) return;
    const [bs, bt] = endlessBest(this.p1);
    if (endlessBetterP(this.cleared, secs, bs, bt)) {
      store.set(ENDLESS_KEY + 2 * i, this.cleared); store.set(ENDLESS_KEY + (2 * i + 1), secs);
      this.record = true;
    }
  }
  /** The run is over (a loss, a draw, RETIRE, QUIT; LOST: the last stage ended it): the log line, the RESULTS lines. */
  end(lost = W.winner !== 0): void {
    const secs = roundHalfEven(this.ticks / 60), [bs, bt] = endlessBest(this.p1), s = this.stats;
    this.lost = lost;
    this.log.push(`duel endless over stages ${this.cleared} secs ${secs} best ${bs} secs ${bt} record ${this.record ? 'T' : 'NIL'}`);
    this.over = {
      title: `ENDLESS  ${kitName(this.p1)}`, stages: `STAGES CLEARED  ${this.cleared}`, time: `TIME  ${mmSs(secs)}`,
      best: bs > 0 ? `BEST  ${bs}  ${mmSs(bt)}` : 'BEST  -',
      stats: (['DAMAGE', 'KIKONS', 'PERFECT HOHOS', 'BEST COMBO'] as const).map((l, i) => [l, String(s[i])] as [string, string]),
      foes: this.foes.map((c) => kitName(c)[0]).join(' ') + (lost ? ' X' : ''),
    };
  }

  // ---------------------------------------------------------------- STAGE CLEAR
  /** What STAGE CLEAR's row K does (shown under the rows for the selected one): CONTINUE names the form carried. */
  rowNote(k: ClearRow): string {
    const snap = this.snap!, from = snap.form, to = endlessCarry(snap, 'stay').form;
    const name = (f: string) => findKit(snap.character, f).formName;
    if (k === 'stay') return !snap.awakened ? `ON TO STAGE ${this.stage + 1}` : from === to ? `STAY ${name(to)}` : `${name(from)} -> ${name(to)}`;
    return k === 'revert' ? 'BACK TO BASE  AWAKENING FULL' : 'END THE RUN';
  }
  /** STAGE CLEAR's rows and strings: the stage, its time and the run's, the carry, the next stage. */
  clearLines(): void {
    const snap = this.snap!, n = this.stage, next = n + 1, r = endlessRamp(next), k = snap.konpaku;
    const opp = endlessOpponent(this.seed, next, ROSTER);
    const rows: ClearRow[] = snap.awakened ? ['stay', 'revert', 'quit'] : ['stay', 'quit'];
    this.clear = {
      title: `STAGE ${n} CLEAR`,
      times: `TIME ${mmSs(roundHalfEven(this.stageTicks / 60))}   RUN ${mmSs(roundHalfEven(this.ticks / 60))}`,
      konpaku: `KONPAKU  ${k} -> ${Math.min(T.konpakuMax, k + 2)}`,
      full: 'REISHI FULL   GUARD FULL', kept: 'REIATSU  FLASH STEP  KEPT',
      next: `NEXT  STAGE ${next}  ${kitName(opp)}  ${endlessDifficulty(this.floor, next, DIFFICULTIES).toUpperCase()}`,
      ramp: (r[3] ? 'AWAKENED AT FIGHT' : '') + (!r[3] && r[2] > 0 ? `AWAKENING ${r[2]}` : '') + (r[4] > 100 ? `  REISHI ${r[4]}%` : ''),
      rows, labels: rows.map((x) => (x === 'stay' ? 'CONTINUE' : x === 'revert' ? 'REVERT' : 'QUIT')), notes: rows.map((x) => this.rowNote(x)),
    };
  }
  /** A STAGE CLEAR row: CONTINUE ('stay') / REVERT carry P1 into the next stage (its Match), QUIT ends the run (null). */
  choose(k: ClearRow): Match | null {
    if (k === 'quit') { this.end(false); return null; }
    const snap = this.snap!;
    this.carry = endlessCarry(snap, k);
    this.log.push(`duel endless clear ${this.stage} konpaku ${snap.konpaku}->${this.carry.konpaku} choice ${k} form ${snap.form}->` +
      `${this.carry.form} meter ${roundHalfEven(this.carry.meter)} ticks ${this.ticks}`);
    return this.nextStage();
  }
}

/** The autopilot (debug 80990+ / 80992+): one run of CHARACTER, run SEED, NORMAL floor, P1 a HARD CPU, POLICY at every
 *  clear; MAX stages at most. Returns the run, its log lines (the run's and each stage's) in order. */
export function autoRun(character: string, seed: number, policy: 'stay' | 'revert', max = 99,
                        onMatch?: (m: Match, line: (l: string) => void) => void): { run: Run; log: string[] } {
  const run = new Run(character, 'normal', seed, { debug: true, auto: policy }), log: string[] = [];
  const flush = () => { log.push(...run.log); run.log = []; };
  let m: Match | null = run.start();
  while (m) {
    flush();
    for (const l of m.takeLog()) log.push(l);
    m.runToEnd(60 * 60 * 10, (mm) => { mm.takeEvents(); onMatch?.(mm, (l) => log.push(l)); for (const l of mm.takeLog()) log.push(l); });
    if (m.running()) { log.push('duel -> NO RESULT (step cap)'); break; }
    m = run.stageEnd() ? (run.cleared >= max ? (run.end(false), null) : run.choose(run.clear!.rows.includes(policy) ? policy : 'stay')) : null;
  }
  flush();
  return { run, log };
}
