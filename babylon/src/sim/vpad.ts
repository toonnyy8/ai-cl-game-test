// vpad.ts <- engine/lisp/input.lisp (the virtual controller) + duel/lisp/control.lisp (the nine buttons, the command
// table, the PRACTICE / HUD helpers). Devices, a CPU brain and test scripts all write a vpad the same way, once per fixed
// step, so a replay or a CPU press is indistinguishable from a key press (and a seeded match replays).
//   step:   vp.beginStep()           advance the vpad clock, run the device READER (if any)
//   write:  vp.set('quick', true)    button state this step (going down stamps a press);  vp.stick(x, y)
//   read:   vp.down / held / pressed / moddedP / commandPressedP / command;  vp.consume(button)
// A press stays buffered for BUFFER steps until consumed. The MODIFIER button marks presses made while it is held, or
// in the same step, as "modified", so one button can mean two commands.
import { T } from './tuning';
import { kikonResult } from './rules';

export const NO_PRESS = -1000000;

export type Action = 'mod' | 'quick' | 'flash' | 'sig' | 'guard' | 'breaker' | 'kikon' | 'step' | 'awaken';
/** Every vpad button. MOD is the modifier: a button pressed while MOD is down, or in the same step, is modified. */
export const VPAD_ACTIONS: readonly Action[] = ['mod', 'quick', 'flash', 'sig', 'guard', 'breaker', 'kikon', 'step', 'awaken'];

export class Vpad {
  readonly actions: readonly Action[];
  readonly modIndex: number;
  readonly buffer: number;
  tick = 0;
  downs: Int32Array; since: Int32Array; press: Int32Array; modded: Int32Array;
  sx = 0; sy = 0;
  /** null or a function of the vpad, called by beginStep (a device). */
  reader: ((vp: Vpad) => void) | null;

  constructor(actions: readonly Action[], modifier: Action | null, buffer = 10, reader: ((vp: Vpad) => void) | null = null) {
    this.actions = actions;
    this.buffer = buffer;
    this.reader = reader;
    const n = actions.length;
    this.modIndex = modifier ? actions.indexOf(modifier) : -1;
    if (modifier && this.modIndex < 0) throw new Error(`modifier ${modifier} is not an action`);
    this.downs = new Int32Array(n); this.since = new Int32Array(n);
    this.press = new Int32Array(n).fill(NO_PRESS); this.modded = new Int32Array(n);
  }

  index(action: Action): number {
    const i = this.actions.indexOf(action);
    if (i < 0) throw new Error(`unknown vpad action ${action}`);
    return i;
  }
  /** Start a fixed step: advance the tick, then let the device reader (if any) write the state. */
  beginStep(): this {
    this.tick++;
    if (this.reader) this.reader(this);
    return this;
  }
  /** ACTION is DOWN this step. Going down stamps a press and records whether the modifier is down (or goes down in the
   *  same step). */
  set(action: Action, down: boolean): boolean {
    const i = this.index(action), d = this.downs, m = this.modIndex;
    if (down && d[i] === 0) {
      d[i] = 1; this.since[i] = this.tick; this.press[i] = this.tick; this.modded[i] = m >= 0 ? d[m] : 0;
      if (i === m)                                  // the modifier now: presses of this step count too
        for (let j = 0; j < d.length; j++) if (this.press[j] === this.tick) this.modded[j] = 1;
    } else if (!down && d[i] === 1) d[i] = 0;
    return down;
  }
  /** Set the stick (X right, Y up), clamped to unit length. */
  stick(x: number, y: number): this {
    const m2 = x * x + y * y;
    if (m2 > 1) { const m = Math.sqrt(m2); x /= m; y /= m; }
    this.sx = x; this.sy = y;
    return this;
  }
  /** Release everything and forget buffered presses (a reset, a cinematic, a menu). */
  clear(): this {
    this.downs.fill(0); this.press.fill(NO_PRESS); this.modded.fill(0); this.sx = 0; this.sy = 0;
    return this;
  }
  /** Forget buffered presses but keep what is held (the end of a cinematic). */
  flush(): this { this.press.fill(NO_PRESS); return this; }
  down(action: Action): boolean { return this.downs[this.index(action)] === 1; }
  /** Steps ACTION has been held (1 on the step it went down), 0 if up. */
  held(action: Action): number {
    const i = this.index(action);
    return this.downs[i] === 1 ? 1 + this.tick - this.since[i] : 0;
  }
  /** Was ACTION pressed within the last WITHIN steps (default BUFFER; this step included) and not consumed? */
  pressed(action: Action, within?: number): boolean {
    return this.tick - this.press[this.index(action)] < (within ?? this.buffer);
  }
  moddedP(action: Action): boolean { return this.modded[this.index(action)] === 1; }
  /** Press ACTION this step (buffered, MODDED or not), whether or not it is held already (the assist's press). */
  stamp(action: Action, modded = false): this {
    const i = this.index(action);
    this.downs[i] = 1; this.press[i] = this.tick; this.modded[i] = modded ? 1 : 0;
    return this;
  }
  /** Keep ACTION down this step without a new press. */
  hold(action: Action): this { this.downs[this.index(action)] = 1; return this; }
  /** Use up ACTION's buffered press. */
  consume(action: Action): this { this.press[this.index(action)] = NO_PRESS; return this; }

  /** Is the command-table entry (BUTTON MOD) buffered: BUTTON pressed, with the modifier as MOD asks? */
  commandPressedP(button: Action, mod: Mod): boolean {
    return this.pressed(button) && (mod === 'any' || mod === this.moddedP(button));
  }
  /** The highest-priority buffered command of COMMANDS among ALLOWED (null = all): [command, button] or null. */
  command(commands: readonly CommandRow[], allowed: readonly string[] | null = null): [Command, Action] | null {
    for (const [cmd, button, mod] of commands)
      if ((!allowed || allowed.includes(cmd)) && this.commandPressedP(button, mod)) return [cmd, button];
    return null;
  }
}

/** A SOUL DUEL vpad: VPAD_ACTIONS, 'mod' as the modifier, presses buffered T.inputBuffer steps. */
export const newVpad = (reader: ((vp: Vpad) => void) | null = null): Vpad =>
  new Vpad(VPAD_ACTIONS, 'mod', T.inputBuffer, reader);

// ---------------------------------------------------------------- commands
export type Mod = true | false | 'any';
export type Command = 'kikon' | 'awaken' | 'hoho' | 'burst' | 'step' | 'breaker' | 'sp2' | 'sp1' | 'sig' | 'f' | 'q';
export type CommandRow = readonly [Command, Action, Mod];
/** Command table, HIGHEST PRIORITY FIRST: (command button mod), MOD true needs the press modified, false unmodified,
 *  'any' ignores the modifier. The decisive and rare (Kikon, Awaken) first, then escapes (Hoho, Burst, Step), the
 *  Breaker, the modified buttons before the plain ones, heavier before lighter (mashing J+K gives the Flash). Fighter
 *  code walks it with commandPressedP (fighter.ts command), so a refused command doesn't hide the ones below it. */
export const COMMANDS: readonly CommandRow[] = [
  ['kikon', 'kikon', 'any'],
  ['awaken', 'awaken', 'any'],
  ['hoho', 'step', true],
  ['burst', 'quick', true],
  ['step', 'step', false],
  ['breaker', 'breaker', 'any'],
  ['sp2', 'sig', true],
  ['sp1', 'flash', true],
  ['sig', 'sig', false],
  ['f', 'flash', false],
  ['q', 'quick', false],
];

// ---------------------------------------------------------------- PRACTICE and HUD helpers (control.lisp)
// ponytail: device bindings / CONTROLS rebinding / SETTINGS rows are device-side: src/input (M1 playable, M6).
/** PRACTICE, GUARD AFTER HIT: frames the dummy keeps its guard once it is free again. */
export const DUMMY_GUARD_HOLD = 60;
/** Frames the PRACTICE dummy goes on holding guard, for its DUMMY option, its fighter STATE and LEFT. */
export function dummyGuardLeft(dummy: string, state: string, left: number): number {
  switch (dummy) {
    case 'guard-all': return 999;
    case 'guard-hit': return ['stun', 'air', 'down', 'wakeup', 'guard-hit'].includes(state) ? DUMMY_GUARD_HOLD : Math.max(0, left - 1);
    default: return 0;
  }
}
export const PRACTICE_HP = [100, 75, 50, 25, 10];
/** Reishi for PCT % of REISHI-MAX (never 0: 0 would be a Soul Break). */
export const practiceReishi = (reishiMax: number, pct: number): number => Math.max(1, Math.ceil((reishiMax * pct) / 100));
/** The P1 / DUMMY KONPAKU row moved by DIR: 1 .. KMAX, wrapping. */
export const konpakuStep = (k: number, dir: number, kmax: number): number => 1 + ((((k - 1 + dir) % kmax) + kmax) % kmax);
/** How many of KONPAKU flames a Kikon worth COUNT would take if it landed now (the HUD's red flames). */
export const konpakuAtStake = (konpaku: number, count: number): number => kikonResult(konpaku, count, false)[1];
