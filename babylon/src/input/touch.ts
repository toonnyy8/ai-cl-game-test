// touch.ts <- engine/lisp/touch.lisp: the one-thumb gesture recogniser (docs/DUEL_MOBILE_DESIGN.md §3.2, §15.1). Pure
// (no DOM): onehand.ts feeds it the frame's pointer events (feed), then the vpad reader takes this read's pulses (take).
// A contact that starts in the flow pad is the gesture contact (the latest one wins); one that starts on a chip holds that
// chip until it lifts; anything else only counts as a menu tap. Coordinates are window px; the knobs are CSS px and ms,
// scaled by dpx. Timing uses the events' own timestamps (frame-rate independent).

/** The recogniser's knobs (design §3.8): px are CSS pixels, times ms. */
export interface GestureConfig {
  tapMs: number; slop: number; flickMin: number; flickWindow: number; upCone: number; tapSplit: number;
  stickR: number; runRing: number; runRelease: number; recenter: number; chipSlop: number; menuTapMs: number;
}
export const gestureConfig = (o: Partial<GestureConfig> = {}): GestureConfig => ({
  tapMs: 120, slop: 10, flickMin: 28, flickWindow: 120, upCone: 1.73, tapSplit: 0.5,
  stickR: 48, runRing: 1.6, runRelease: 1.3, recenter: 2, chipSlop: 8, menuTapMs: 350, ...o,
});

export const TP_TAP = 1, TP_FLICK = 2, TP_TAP_HI = 4, TP_HOHO = 8;
const FINGERS = 10, CHIPS = 8;
/** Event types (engine/c/platform.c): 0 down, 1 motion, 2 up, 3 canceled, 4 every finger gone (focus lost). */
export type TouchEvent5 = [type: number, slot: number, x: number, y: number, ms: number];

/** One recogniser. PHASE of the gesture contact: 0 none, 1 pending (still inside the slop since touch-down), 2 drag,
 *  3 rest (guard), 5 spent (a Hoho fired: ignored until it lifts), 6 undecided (left the slop, the flick window open). */
export class Touch {
  cfg: GestureConfig;
  dpx = 1;
  pad = [0, 0, 0, 0];                           // flow pad x0 y0 x1 y1
  chips: number[] = [];                         // cx cy r per chip
  nchips = 0;
  chipHold = new Array(CHIPS).fill(0);          // ms a chip must be held before it is down
  chipSlot = new Array(CHIPS).fill(-1);         // finger holding chip i, -1 none
  chipT = new Array(CHIPS).fill(0);
  chipOn = 0; chipHit = 0;                      // bits: down now / touched this frame
  now = 0;                                      // the clock feed runs to (ms)
  restUpOk = false;                             // the game: may a rested up-flick be a Hoho now (neutral / guard)?
  upHoho = false;                               // the game: is any up-flick a Hoho now, no rest needed?
  gid = -1; phase = 0;
  t0 = 0; x = 0; y = 0; ox = 0; oy = 0; ax = 0; ay = 0;
  tleave = -1; armed = 1; rested = 0;
  px = 0; py = 0; pt = 0;
  flickHold = 0; runHold = 0;
  fx = 0; fy = 0;                               // last flick's stroke (px, y down)
  pend = 0; live = 0;
  fx0 = new Array(FINGERS).fill(0); fy0 = new Array(FINGERS).fill(0); ft0 = new Array(FINGERS).fill(0);
  fmoved = new Array(FINGERS).fill(1);          // 1 = not a tap (moved, cancelled, unknown)
  tapped = 0; tapX = 0; tapY = 0;
  /** Feedback: the last recognised gesture (1 tap 2 flick 3 high tap 4 hoho 5 rest 6 up-flick 7 burst), when, where. */
  glyph = 0; glyphT = -1e4; glyphX = 0; glyphY = 0;

  constructor(cfg: GestureConfig = gestureConfig()) { this.cfg = cfg; }

  private px_(v: number): number { return this.dpx * v; }

  /** Scale DPX, flow PAD (x0 y0 x1 y1) and CHIPS ([cx, cy, r] px; HOLDS ms each must be held first). Releases chips. */
  layout(dpx: number, pad: number[], chips: number[][] = [], holds: number[] = []): this {
    this.dpx = dpx;
    this.pad = pad.slice(0, 4);
    this.nchips = Math.min(CHIPS, chips.length);
    this.chips = chips.slice(0, CHIPS).flat();
    for (let i = 0; i < CHIPS; i++) this.chipHold[i] = holds[i] ?? 0;
    this.chipSlot.fill(-1);
    this.chipOn = 0;
    return this;
  }

  private setGlyph(kind: number, x: number, y: number, ms: number): void {
    this.glyph = kind; this.glyphT = ms; this.glyphX = x; this.glyphY = y;
  }
  private release(): void { this.gid = -1; this.phase = 0; this.flickHold = 0; this.runHold = 0; }

  private gestureDown(slot: number, x: number, y: number, ms: number): void {
    this.gid = slot; this.phase = 1; this.t0 = ms; this.x = x; this.y = y;
    this.ox = x; this.oy = y; this.ax = x; this.ay = y; this.px = x; this.py = y; this.pt = ms;
    this.tleave = -1; this.armed = 1; this.rested = 0; this.flickHold = 0; this.runHold = 0;
  }

  /** A flick crossed FLICK-MIN with stroke (DX DY) (px, y down). */
  private flick(dx: number, dy: number, ms: number): void {
    this.armed = 0; this.fx = dx; this.fy = dy;
    const up = dy < 0 && -dy * this.cfg.upCone >= Math.abs(dx);
    if (up && (this.upHoho || (this.rested === 1 && this.restUpOk))) {   // up from a rest, or any while the game says so
      this.pend |= TP_HOHO; this.phase = 5;
      this.setGlyph(4, this.x, this.y, ms);
    } else {
      this.pend |= TP_FLICK; this.flickHold = 1; this.phase = 2;
      if (up) { this.fx = 0; this.setGlyph(6, this.x, this.y, ms); }   // up: straight ahead (a slanted thumb too)
      else this.setGlyph(2, this.x, this.y, ms);
    }
    this.rested = 0;
  }

  private gestureMove(x: number, y: number, ms: number): void {
    this.x = x; this.y = y;
    if (this.phase === 5) return;
    const slop = this.px_(this.cfg.slop), hs = 0.5 * slop;
    { const dx = x - this.px, dy = y - this.py;
      if (dx * dx + dy * dy > hs * hs) { this.px = x; this.py = y; this.pt = ms; } }   // moved: a new still point
    // flick: from the anchor, FLICK-MIN within FLICK-WINDOW of leaving the slop
    const ax = x - this.ax, ay = y - this.ay, d2 = ax * ax + ay * ay, fm = this.px_(this.cfg.flickMin);
    if (this.tleave < 0 && d2 > slop * slop) this.tleave = ms;
    if (this.armed === 1 && this.tleave >= 0) {
      if (ms - this.tleave > this.cfg.flickWindow) {
        this.armed = 0; this.rested = 0;
        if (this.phase === 6) this.phase = 2;                              // no flick: it was a drag
      } else if (d2 >= fm * fm) this.flick(ax, ay, ms);
    }
    if (this.flickHold === 1 && d2 < fm * fm) this.flickHold = 0;
    // drag: the stick from the origin (which follows past RECENTER radii), Step held beyond the run ring
    const r = this.px_(this.cfg.stickR), sx = x - this.ox, sy = y - this.oy, rc = r * this.cfg.recenter;
    let m2 = sx * sx + sy * sy;
    if ((this.phase === 1 || this.phase === 3) && m2 > slop * slop) this.phase = this.armed === 1 ? 6 : 2;
    if (m2 > rc * rc) {
      const k = rc / Math.sqrt(m2);
      this.ox = x - k * sx; this.oy = y - k * sy; m2 = rc * rc;
    }
    const run = r * this.cfg.runRing, rel = r * this.cfg.runRelease;
    if (m2 >= run * run) this.runHold = 1;
    else if (m2 < rel * rel) this.runHold = 0;
  }

  /** The window y splitting the pad's taps: above it a high tap (TP_TAP_HI), from it down a tap (TP_TAP). */
  splitY(): number { const p = this.pad; return p[1] + this.cfg.tapSplit * (p[3] - p[1]); }

  private gestureLift(ms: number): void {
    if (this.phase === 1 && ms - this.t0 <= this.cfg.tapMs) {           // never left the slop, short: a tap
      const hi = this.oy < this.splitY();                              // where it went down
      this.pend |= hi ? TP_TAP_HI : TP_TAP;
      this.setGlyph(hi ? 3 : 1, this.x, this.y, ms);
    }
    this.release();
  }

  /** Time-based transitions at NOW: an undecided stroke whose window closed is a drag; a thumb still for TAP-MS
   *  re-anchors (re-arming the flick) and, inside the slop of the stick origin, rests (guard); held chips come on. */
  private clock(now: number): void {
    if (this.gid >= 0) {
      if (this.phase === 6 && now - this.tleave > this.cfg.flickWindow) { this.phase = 2; this.armed = 0; this.rested = 0; }
      if (this.phase !== 5 && now - this.pt >= this.cfg.tapMs) {
        const sx = this.x - this.ox, sy = this.y - this.oy, slop = this.px_(this.cfg.slop);
        const inside = sx * sx + sy * sy <= slop * slop;
        this.ax = this.x; this.ay = this.y; this.tleave = -1; this.armed = 1; this.flickHold = 0;
        if (inside) {
          if (this.phase !== 3) this.setGlyph(5, this.x, this.y, now);
          this.phase = 3; this.rested = 1; this.ox = this.x; this.oy = this.y;
        } else { this.rested = 0; this.phase = 2; }
      }
    }
    let on = 0;
    for (let i = 0; i < this.nchips; i++)
      if (this.chipSlot[i] >= 0 && now - this.chipT[i] >= this.chipHold[i]) on |= 1 << i;
    this.chipOn = on;
  }

  /** Index of the chip whose hit circle holds (X Y), or -1. */
  chipAt(x: number, y: number): number {
    const c = this.chips, s = this.px_(this.cfg.chipSlop);
    for (let i = 0; i < this.nchips; i++) {
      const dx = x - c[3 * i], dy = y - c[3 * i + 1], r = s + c[3 * i + 2];
      if (dx * dx + dy * dy <= r * r) return i;
    }
    return -1;
  }

  private event(type: number, slot: number, x: number, y: number, ms: number): void {
    const slop = this.px_(this.cfg.slop), finger = slot > -1 && slot < FINGERS;
    switch (type) {
      case 0: {                                                          // down
        if (finger) { this.fx0[slot] = x; this.fy0[slot] = y; this.ft0[slot] = ms; this.fmoved[slot] = 0; }
        const c = this.chipAt(x, y), p = this.pad;
        if (c >= 0) { this.chipSlot[c] = slot; this.chipT[c] = ms; this.chipHit |= 1 << c; }
        else if (p[0] <= x && x <= p[2] && p[1] <= y && y <= p[3]) this.gestureDown(slot, x, y, ms);   // latest wins
        break;
      }
      case 1:                                                            // motion
        if (finger) {
          const dx = x - this.fx0[slot], dy = y - this.fy0[slot];
          if (dx * dx + dy * dy > slop * slop) this.fmoved[slot] = 1;
        }
        if (slot === this.gid) this.gestureMove(x, y, ms);
        break;
      case 2: case 3:                                                    // up / canceled (a cancel is never a tap)
        if (finger) {
          if (type === 2 && this.fmoved[slot] === 0 && ms - this.ft0[slot] <= this.cfg.menuTapMs) {
            this.tapped = 1; this.tapX = x; this.tapY = y;
          }
          this.fmoved[slot] = 1;
        }
        for (let i = 0; i < this.nchips; i++) if (this.chipSlot[i] === slot) this.chipSlot[i] = -1;
        if (slot === this.gid) { if (type === 2) this.gestureLift(ms); else this.release(); }
        break;
      case 4:                                                            // every finger gone (focus lost)
        this.fmoved.fill(1); this.chipSlot.fill(-1); this.release();
        break;
    }
  }

  /** Process EVENTS, then run the clock to NOW (ms). Clears last frame's menu tap and chip touches first. */
  feed(events: readonly TouchEvent5[], now: number): this {
    this.tapped = 0; this.chipHit = 0;
    this.now = now;
    for (const [t, s, x, y, ms] of events) this.event(t, s, x, y, ms);
    this.clock(now);
    return this;
  }

  /** Call once at the start of each vpad read: the pending pulses become live for exactly this read. */
  take(): this { this.live = this.pend; this.pend = 0; return this; }
  pulseP(bit: number): boolean { return (this.live & bit) !== 0; }
  /** The game took this read's flick for itself (a burst): the contact gives nothing more until it lifts. */
  spend(): this {
    this.phase = 5; this.flickHold = 0; this.runHold = 0; this.live &= ~TP_FLICK;
    return this;
  }
  activeP(): boolean { return this.gid >= 0; }
  restingP(): boolean { return this.phase === 3; }
  stepHeldP(): boolean { return this.phase === 2 && (this.flickHold === 1 || this.runHold === 1); }
  /** The last flick went down (within 45 degrees). */
  flickDownP(): boolean { return this.fy > 0 && this.fy >= Math.abs(this.fx); }
  /** The stick, x right (unclamped: the vpad clamps); a live flick gives its direction. */
  sx(): number {
    if (this.live & TP_FLICK) return this.fx / this.px_(this.cfg.flickMin);
    if (this.phase === 2) return (this.x - this.ox) / this.px_(this.cfg.stickR);
    return 0;
  }
  /** The stick, y up. */
  sy(): number {
    if (this.live & TP_FLICK) return -this.fy / this.px_(this.cfg.flickMin);
    if (this.phase === 2) return (this.oy - this.y) / this.px_(this.cfg.stickR);
    return 0;
  }
  chipDownP(i: number): boolean { return ((this.chipOn >> i) & 1) === 1; }
  chipHitP(i: number): boolean { return ((this.chipHit >> i) & 1) === 1; }
  tappedP(): boolean { return this.tapped === 1; }
}
