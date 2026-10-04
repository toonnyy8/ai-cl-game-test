// time.ts <- engine/lisp/time.lisp: fixed 60 Hz steps (runFixedSteps), hitstop (global sim freeze) and slow motion.
// Pure bookkeeping: the game decides what a "step" simulates. One TimeState per match (the Lisp's specials).
import { roundHalfEven } from './math';

export const STEP = 1 / 60;
// The Lisp keeps the slow-motion slots and scale in single floats (f32vec, 1f0 / 60f0): the step-skipping slow motion
// counts sim frames off them, so they stay f32 here (doubles skip a different step now and then and a CPU match drifts).
const f32 = Math.fround, STEP32 = f32(1 / 60);
const SLOWMO_N = 8;

export class TimeState {
  /** Scales every HITSTOP request (tuning knob). */
  hitstopMult = 1.0;
  /** Frames of global sim freeze left. */
  hitstop = 0;
  /** Fixed steps since start; advances during hitstop too. */
  tick = 0;
  /** scale, real seconds left, who (0 everyone / 1 the others only), per slot */
  slowmoSlots = new Float32Array(3 * SLOWMO_N);
  /** Real seconds not yet simulated (runFixedSteps). Set it to 0 while the sim pauses. */
  stepAcc = 0;

  /** Request a global sim freeze of FRAMES; concurrent requests take the max. */
  requestHitstop(frames: number): void {
    const f = roundHalfEven(frames * this.hitstopMult);
    if (f > this.hitstop) this.hitstop = f;
  }

  /** Time-scale the sim (or only the other side) to SCALE for SECS of real time. Lowest scale wins. */
  slowmo(scale: number, secs: number, othersOnly = false): void {
    const s = this.slowmoSlots;
    let best = 0, bl = Infinity;
    for (let i = 0; i < SLOWMO_N; i++) {
      const left = s[i * 3 + 1];
      if (left < bl) { bl = left; best = i; }
    }
    s[best * 3] = scale; s[best * 3 + 1] = secs; s[best * 3 + 2] = othersOnly ? 1 : 0;
  }

  /** Current sim scale for the main side (OTHERS false) or the other side. Eases to 1 over the last 0.1 s. */
  slowmoScale(others: boolean): number {
    const s = this.slowmoSlots;
    let sc = 1;
    for (let i = 0; i < SLOWMO_N; i++) {
      const o = i * 3, left = s[o + 1];
      if (left > 0 && (others || s[o + 2] < 0.5)) {
        const k = s[o], e = left < f32(0.1) ? f32(k + f32(f32(1 - k) * f32(1 - f32(left * 10)))) : k;
        sc = Math.min(sc, e);
      }
    }
    return sc;
  }

  /** Cancel any hitstop and slow motion (a new round / scene). TICK keeps counting. */
  timeReset(): void {
    this.hitstop = 0;
    this.slowmoSlots.fill(0);
  }

  /** Advance real-time timers by one fixed step. True when the sim should run this step. */
  timeStep(): boolean {
    const s = this.slowmoSlots;
    this.tick++;
    for (let i = 0; i < SLOWMO_N; i++) {
      const o = i * 3 + 1;
      s[o] = Math.max(0, f32(s[o] - STEP32));
    }
    if (this.hitstop > 0) { this.hitstop--; return false; }
    return true;
  }

  /** The frame's fixed steps: add RDT real seconds, call STEP once per whole STEP they cover, at most MAX-STEPS times; a
   *  longer backlog is dropped. WHILE is asked before each step (false stops early). Returns the steps run. */
  runFixedSteps(rdt: number, step: () => void, maxSteps = 6, whileP?: () => boolean): number {
    this.stepAcc += rdt;
    let n = 0;
    while (this.stepAcc >= STEP && n < maxSteps && (!whileP || whileP())) {
      this.stepAcc -= STEP; n++; step();
    }
    if (this.stepAcc >= STEP) this.stepAcc = 0;
    return n;
  }
}
