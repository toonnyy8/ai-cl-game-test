// kit.ts <- duel/lisp/kit.lisp: characters as data. defmove (one spec per move) and defkit (one spec per character
// form), parsed at load into Move / HitWin / Kit. The generic fighter code reads only these; what a character does beyond
// the data is a hook: a NAME in the data (onFrame [[40, 'yama-fire-wave']], tick, release, onLand, hooks {...}), looked
// up in the hook registry at call time, so a character not ported yet (or a missing hook) is a no-op.
// Numbers that name a tuning knob are read from T when the character file runs (the Lisp's RESOLVE-TUNING).
// Frames: a move's frame SF counts from 0; startup S, active A, recovery R; hit windows [from, to) in move frames.
import { T } from './tuning';
import { makeVol, type Vol, type VolSpec } from './hitvol';
import { guardValue } from './rules';

// ================================================================ hooks (by name)
// ponytail: `any` args: hooks are the characters' own functions, each with its own signature (DUEL_DESIGN "Character
// code layout"); the call sites pass what the Lisp passes.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type HookFn = (...args: any[]) => any;
export const HOOKS: Record<string, HookFn> = {};
const missingHooks = new Set<string>();
export function registerHooks(fns: Record<string, HookFn>): void { Object.assign(HOOKS, fns); }
/** The hook NAME's function, or null (not ported yet: logged once, the call site treats it as a no-op). */
export function hookFn(name: string | null | undefined): HookFn | null {
  if (!name) return null;
  const f = HOOKS[name];
  if (!f && !missingHooks.has(name)) missingHooks.add(name);
  return f ?? null;
}
/** Call hook NAME with ARGS (a no-op returning undefined when it isn't registered). */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function callHook(name: string | null | undefined, ...args: any[]): any {
  const f = hookFn(name);
  return f ? f(...args) : undefined;
}
export const missingHookNames = (): string[] => [...missingHooks];

// ================================================================ moves
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type Params = Record<string, any>;

/** One active window of a move: [from, to) in move frames, its damage and effect on hit. */
export interface HitWin {
  from: number; to: number; dmg: number;
  vols: Vol[];               // volumes in the attacker's frame
  react: string;             // flinch stagger knockback launch knockdown crumple bind ...
  kb: number;                // knockback slide, metres
  hs: number;                // global hitstop frames
  chip: number | null;       // chip fraction on block, null = none
  meter: number;             // the kit meter (Inferno) gained on hit
  stun: number | null;       // hitstun override in frames (null = the reaction's)
  guard: number | null;      // guard gauge a block drains (null = a hazard's T.ggHazard)
  frost: number;             // frames of frost a real hit sets
  flags: string[];           // breaker guard-crush unguardable ranged ice spare rend ...
}
export function makeHitwin(o: Partial<HitWin> = {}): HitWin {
  return { from: 0, to: 0, dmg: 0, vols: [], react: 'flinch', kb: 0, hs: 0, chip: null, meter: 0, stun: null, guard: null,
           frost: 0, flags: [], ...o };
}

export interface HitSpecOpts {
  dmg?: number; onHit?: string; kb?: number; vol?: VolSpec; reach?: number; chip?: number | null; meter?: number;
  flags?: string[]; hs?: number; stun?: number; guard?: number; frost?: number;
}
export type HitSpec = [number, number] | [number, number, HitSpecOpts];

/** One move as one spec (see kit.lisp DEFMOVE's docstring for every key; the keys are its camelCase). */
export interface MoveSpec {
  kind: string; clip?: string; clip2?: string; callout?: string;
  startup?: number; active?: number; recovery?: number; whiff?: number;
  dmg?: number; advBlock?: number | null; track?: number; reach?: number; arc?: number; height?: [number, number];
  vol?: VolSpec; onHit?: string; kb?: number; hs?: number; chip?: number | null; meter?: number;
  cost?: number; hold?: [number, number]; slide?: number; flags?: string[]; hits?: HitSpec[];
  onFrame?: [number, string][]; tick?: string; release?: string; onLand?: string; cine?: string; params?: Params;
  enter?: number; blend?: number; planted?: boolean; clipS?: number; guard?: number; armorHits?: number;
  cooldown?: number; frost?: number;
}

export interface Move {
  name: string; kind: string; clip: string | null; clip2: string | null; callout: string | null;
  s: number; a: number; r: number; whiff: number;
  dmg: number; advBlock: number | 'guard-break' | null; track: number; reach: number;
  hits: HitWin[];
  cost: number | null; hold: [number, number] | null; slide: number; flags: string[];
  armorHits: number; cooldown: number;
  onFrame: [number, string][]; tick: string | null; release: string | null; onLand: string | null; cine: string | null;
  params: Params;
  enter: number;             // the move starts at this frame (its clip too): a faster string branch
  clipSpeed: number;         // clip playback speed so it hits on frame S
  blend: number; planted: boolean;
  spec: MoveSpec;            // the spec, re-parsed for derived forms
}

export const mvTotal = (mv: Move): number => mv.s + mv.a + mv.r;
export const mvFirstHit = (mv: Move): number => (mv.hits.length > 0 ? mv.hits[0].from : mv.s);

/** Move name -> Move, as written in the kit files. */
export const MOVES = new Map<string, Move>();
export function findMove(name: string): Move {
  const m = MOVES.get(name);
  if (!m) throw new Error(`unknown move ${name}`);
  return m;
}

/** Volume spec with its lengths x M (reach). */
export function scaleVolSpec(spec: VolSpec, m: number): VolSpec {
  switch (spec[0]) {
    case 'arc': return ['arc', m * spec[1], spec[2], spec[3], spec[4]];
    case 'cap': return ['cap', m * spec[1], m * spec[2], spec[3], spec[4]];
    case 'sph': return ['sph', m * spec[1], spec[2], m * spec[3]];
    case 'tsph': return spec;
  }
}
export function volSpecReach(spec: VolSpec): number {
  switch (spec[0]) {
    case 'arc': return spec[1];
    case 'cap': return spec[2];
    case 'sph': return spec[1] + spec[3];
    case 'tsph': return 0;
  }
}

const def = <V>(v: V | undefined, d: V): V => (v === undefined ? d : v);

/** SPEC -> Move. STARTUP-ADD / REACH-MULT derive a form's version (Nozarashi): every frame from the startup on shifts,
 *  every reach scales. (CL OR treats 0 as true: `??` here, never `||`, on numbers.) */
export function parseMove(name: string, spec: MoveSpec, startupAdd = 0, reachMult = 1.0): Move {
  const { kind } = spec;
  const breaker = kind === 'breaker';
  const arc = def(spec.arc, 90), height = def(spec.height, [0.2, 2.0] as [number, number]);
  const s = startupAdd + (spec.startup ?? (breaker ? T.breakerStartup : 0));
  const a = spec.active ?? (breaker ? T.breakerActive : 0);
  const r = spec.recovery ?? (breaker ? T.breakerRecovery : 0);
  const dmg0 = def(spec.dmg, 0);
  const dmg = breaker && dmg0 === 0 ? T.breakerDamage : dmg0;
  const rr = spec.reach ?? (spec.vol ? volSpecReach(spec.vol) : null) ?? (breaker ? T.breakerReach : null);
  const reach = rr != null ? reachMult * rr : null;
  const vol: VolSpec | null = spec.vol ? scaleVolSpec(spec.vol, reachMult)
    : reach != null ? ['arc', reach, arc, height[0], height[1]] : null;
  const react = spec.onHit ?? (breaker ? 'stagger' : 'flinch');     // (a Breaker: knockback until 2026-10-02)
  const kb0 = def(spec.kb, 0.0);
  const kb = breaker && kb0 === 0 ? T.breakerKnockback : kb0;
  const hs = spec.hs ?? (kind === 'quick' ? T.hitstopLight : kind === 'breaker' ? T.hitstopBreaker : T.hitstopHeavy);
  const flags0 = def(spec.flags, [] as string[]);
  const flags = breaker && !flags0.includes('breaker') ? ['breaker', ...flags0] : flags0;
  const guard = guardValue(kind, spec.advBlock, spec.guard);
  const chip = def(spec.chip, null), meter = def(spec.meter, 0.0), frost = def(spec.frost, 0);
  const window = (from: number, to: number, o: HitSpecOpts = {}): HitWin => {
    // a window's own reach / vol (scaled like the move's), else the move's volume
    const v: VolSpec | null = o.reach !== undefined ? ['arc', reachMult * o.reach, arc, height[0], height[1]]
      : o.vol !== undefined ? scaleVolSpec(o.vol, reachMult) : vol;
    return makeHitwin({
      from: from + startupAdd, to: to + startupAdd, dmg: def(o.dmg, dmg), react: def(o.onHit, react), kb: def(o.kb, kb),
      hs: def(o.hs, hs), chip: def(o.chip, chip), meter: def(o.meter, meter), flags: def(o.flags, flags),
      stun: def(o.stun, null), guard: def(o.guard, guard), frost: def(o.frost, frost), vols: v ? [makeVol(v)] : [],
    });
  };
  const hits = spec.hits ? spec.hits.map((h) => window(h[0], h[1], h[2]))
    : dmg > 0 && vol ? [window(s - startupAdd, s - startupAdd + a)] : [];
  const whiff = spec.whiff ?? (breaker ? T.breakerWhiff
    : r + (kind === 'quick' ? T.whiffExtraJ : kind === 'flash' ? T.whiffExtraK : T.whiffExtra));
  const enter = def(spec.enter, 0);
  return {
    name, kind, clip: spec.clip ?? null, clip2: spec.clip2 ?? null, callout: spec.callout ?? null,
    s, a, r, whiff, dmg, advBlock: breaker ? (spec.advBlock ?? 'guard-break') : (spec.advBlock ?? null),
    track: spec.track ?? (kind === 'quick' ? T.trackQuick : kind === 'breaker' ? T.trackBreaker : kind === 'kikon' ? T.kikonTrack : T.trackHeavy),
    reach: reach ?? 0, hits, cost: spec.cost ?? null, hold: spec.hold ?? null, slide: def(spec.slide, 0.0), flags,
    armorHits: def(spec.armorHits, 0), cooldown: def(spec.cooldown, 0),
    onFrame: (spec.onFrame ?? []).map(([f, h]) => [f + startupAdd, h] as [number, string]),
    tick: spec.tick ?? null, release: spec.release ?? null, onLand: spec.onLand ?? null, cine: spec.cine ?? null,
    params: spec.params ?? {}, spec,
    enter: enter > 0 ? enter + startupAdd : 0, blend: def(spec.blend, 0.0), planted: !!spec.planted,
    clipSpeed: spec.startup != null && (spec.clipS != null || startupAdd !== 0) ? (spec.clipS ?? spec.startup) / s : 1.0,
  };
}

export function defmove(name: string, spec: MoveSpec): Move {
  const m = parseMove(name, spec);
  MOVES.set(name, m);
  return m;
}
/** Move NAME: a copy of move OF (its spec, :enter and all) under another name: a switched string link (J2s, K2s).
 *  OVERRIDES replace OF's keys. */
export const defmoveCopy = (name: string, of: string, overrides: Partial<MoveSpec> = {}): Move =>
  defmove(name, { ...findMove(of).spec, ...overrides });

export type StringRow = [string, string, string];      // (from-move command to-move)
/** A kit's grid (J1 J2 J3 K1 K2 K3 J2s K2s) as its strings: up to three links, each J (q) or K (f), switching at most
 *  once (JJJ JJK JKK KKK KKJ KJJ). After a switch the alias goes on only with the new button. */
export function stringGrid(grid: string[]): StringRow[] {
  const [j1, j2, j3, k1, k2, k3, j2s, k2s] = grid;
  return [[j1, 'q', j2], [j1, 'f', k2s], [k1, 'f', k2], [k1, 'q', j2s], [j2, 'q', j3], [j2, 'f', k3], [k2, 'f', k3],
          [k2, 'q', j3], [j2s, 'q', j3], [k2s, 'f', k3]];
}

// ================================================================ kits
/** Commands every kit form maps to a move (step hoho burst awaken are universal). */
export const KIT_COMMANDS = ['q', 'f', 'sig', 'sp1', 'sp2', 'breaker', 'kikon'] as const;

/** One character form as one spec (see kit.lisp DEFKIT's docstring; camelCase keys). null = the Lisp's explicit NIL. */
export interface KitSpec {
  inherit?: string; name?: string; awakening?: boolean; awakenForm?: string; duration?: number | null; burn?: number;
  mult?: number; taken?: number; guardTo?: string | null; dropTo?: string | null; keep?: string[]; cornered?: number;
  corneredMax?: number; passives?: string[]; bladeChip?: number | null; walk?: number; run?: number; runClips?: string[];
  reishi?: number; body?: string; weapon?: string; stance?: string; hide?: string[]; aura?: string | null; intro?: string;
  win?: string; introCallout?: string; introWeapon?: [string, number]; callout?: string; swingSfx?: string;
  absorbSfx?: string; enterClips?: string[]; enterHook?: string | null; exitHook?: string | null;
  meter?: Params | null; resetReiatsu?: number; ai?: Params; cine?: string | null; blade?: (string | number)[];
  grade?: string; kikonKonpaku?: number; meterGain?: Params | null; formName?: string; drinkClip?: string;
  respectCallout?: string; bankaiForm?: string | null; pips?: Params | null; crushHook?: string; rooted?: boolean;
  field?: Params; warm?: number; cold?: Params; frostTouch?: number; resetForm?: string | null; uTag?: string;
  lAfterK?: string | true | null; lAfterJ?: string | true | null; calm?: boolean; hooks?: Record<string, string>; endlessForm?: string;
  stunTolerance?: number; ggRegen?: number; startupAdd?: number; reachMult?: number;
  commands?: Record<string, string | null>; strings?: StringRow[]; grid?: string[];
}

export interface Kit {
  character: string; form: string; inherit: string | null; name: string | null;
  awakening: boolean; awakenForm: string | null; duration: number | null; burn: number;
  mult: number; taken: number; guardTo: string | null; dropTo: string | null; keep: string[];
  cornered: number; corneredMax: number; passives: string[]; bladeChip: number | null;
  walk: number; run: number; runClips: string[]; reishi: number; body: string | null; weapon: string | null;
  stance: string | null; hide: string[]; aura: string | null; intro: string | null; win: string | null;
  introCallout: string | null; introWeapon: [string, number] | null; callout: string | null;
  swingSfx: string | null; absorbSfx: string | null; enterClips: string[]; enterHook: string | null; exitHook: string | null;
  meter: Params | null; resetReiatsu: number; ai: Params | null; cine: string | null; blade: (string | number)[] | null;
  grade: string | null; kikonKonpaku: number; meterGain: Params | null; formName: string; drinkClip: string | null;
  respectCallout: string | null; bankaiForm: string | null; pips: Params | null; crushHook: string | null; rooted: boolean;
  field: Params | null; warm: number; cold: Params | null; frostTouch: number; resetForm: string | null; uTag: string | null;
  calm: boolean; stunTolerance: number | null; ggRegen: number; lAfterK: string | true | null; lAfterJ: string | true | null;
  hooks: Record<string, string> | null; endlessForm: string | null;
  commands: Record<string, string | null>;   // command -> move name
  strings: StringRow[];
  moves: Map<string, Move>;                  // move name -> this form's Move
  cmdMoves: string[];                        // every command move down the inherit chain, shadowed ones too (the Lisp plist)
  spec: KitSpec;
}

/** Character -> form -> Kit. */
export const KITS = new Map<string, Map<string, Kit>>();
/** Every character with a base kit, in the order the kit files define them (select screen). */
export const ROSTER: string[] = [];
export function findKit(character: string, form: string): Kit {
  const k = KITS.get(character)?.get(form);
  if (!k) throw new Error(`unknown kit ${character} ${form}`);
  return k;
}
/** Is (CHARACTER FORM) registered? (Forms of M3 / M4 aren't yet: the call sites refuse instead of crashing.) */
export const hasKit = (character: string, form: string | null | undefined): boolean => !!form && !!KITS.get(character)?.has(form);

export function kitMove(kit: Kit, name: string): Move {
  const m = kit.moves.get(name);
  if (!m) throw new Error(`kit ${kit.character} ${kit.form} has no move ${name}`);
  return m;
}
/** The move COMMAND starts from neutral, or null. */
export function kitCommandMove(kit: Kit, command: string): Move | null {
  const name = kit.commands[command];
  return name ? kitMove(kit, name) : null;
}
/** The string follow-up of MOVE-NAME for COMMAND (J1 -q-> J2, J2 -f-> K3 ...), or null. */
export function kitNext(kit: Kit, moveName: string, command: string): Move | null {
  for (const [from, cmd, to] of kit.strings) if (from === moveName && cmd === command) return kitMove(kit, to);
  return null;
}
/** Is move NEXT a continuation of MV in KIT: its string follow-up for any button, or after a link 3 the O ender's rush? */
export function moveFollowsP(kit: Kit, mv: Move, next: Move): boolean {
  return kit.strings.some(([from, , to]) => from === mv.name && kitMove(kit, to) === next)
    || (mv.flags.includes('ender') && next.kind === 'kikon');
}
/** Does MOVE-NAME go on as a J / K string (a q or f follow-up)? While it runs every J / K press is taken by the latch. */
export const stringLinkP = (kit: Kit, moveName: string): boolean => !!(kitNext(kit, moveName, 'q') || kitNext(kit, moveName, 'f'));
export const kitKLinkP = (kit: Kit, moveName: string): boolean =>
  moveName === kit.commands.f || kit.strings.some(([, cmd, to]) => cmd === 'f' && to === moveName);
export const kitJLinkP = (kit: Kit, moveName: string): boolean =>
  moveName === kit.commands.q || kit.strings.some(([, cmd, to]) => cmd === 'q' && to === moveName);
/** The L link after string link MOVE-NAME (after a K link the kit's lAfterK, after a J link lAfterJ), or null. */
export function kitLLink(kit: Kit, moveName: string): Move | null {
  const l = kitKLinkP(kit, moveName) ? kit.lAfterK : kitJLinkP(kit, moveName) ? kit.lAfterJ : null;
  return l ? (l === true ? kitCommandMove(kit, 'sig') : kitMove(kit, l)) : null;
}
/** The latch: a J / K press (COMMAND q / f) during string link MOVE-NAME, with QUEUED latched so far: COMMAND when the
 *  string may go on with it (the last press wins), else QUEUED (the press is eaten). */
export const stringLatch = <Q>(kit: Kit, moveName: string, command: string, queued: Q): string | Q =>
  kitNext(kit, moveName, command) ? command : queued;
/** Reiatsu bars COMMAND's move costs: its cost, else SP1 / SP2 T.costSp (SP2 awakened T.costSpAwakened), else 0. */
export function kitCommandCost(kit: Kit, command: string): number {
  const mv = kitCommandMove(kit, command);
  if (mv && mv.cost != null) return mv.cost;
  if (command === 'sp1') return T.costSp;
  if (command === 'sp2') return kit.awakening ? T.costSpAwakened : T.costSp;
  return 0;
}
/** The character file's function for hook POINT in KIT (its hooks), or null. */
export const kitHook = (kit: Kit, point: string): HookFn | null => hookFn(kit.hooks?.[point]);
export const kitPipCmdP = (kit: Kit, command: string): boolean => !!kit.pips && (kit.pips.cmds as string[]).includes(command);
/** The cinematic a Soul Break by a fighter in KIT plays: the form's soulBreakCine hook name, else its Kikon's cine, else
 *  the generic one. */
export function kitKikonCine(kit: Kit): string {
  const mv = kitCommandMove(kit, 'kikon');
  return kit.hooks?.['soul-break-cine'] ?? mv?.cine ?? 'soul-break-cine';
}
export const stunToleranceOf = (kit: Kit): number => kit.stunTolerance ?? T.stunTolerance;
/** The form a kit command CMD drops KIT's form to first (its dropTo, unless CMD is in its keep), or null. */
export const kitDrop = (kit: Kit, cmd: string): string | null => (kit.dropTo && !kit.keep.includes(cmd) ? kit.dropTo : null);
/** The attacker mods for hitDamage: the form's multiplier (x PIERCE) and Cornered with LOST Konpaku. */
export const kitAtkMods = (kit: Kit, lost: number, pierce = 1.0) =>
  ({ mult: kit.mult * pierce, cornered: kit.cornered, corneredMax: kit.corneredMax, lost });
export const kitDefMods = (kit: Kit) => ({ mult: kit.taken });
/** Every clip name the form uses (moves, stance, intro / win, entry cinematic, the run). */
export function kitClips(kit: Kit): string[] {
  const out = new Set<string>();
  for (const c of [kit.stance, kit.intro, kit.win, ...kit.enterClips, ...kit.runClips, kit.drinkClip]) if (c) out.add(c);
  for (const mv of kit.moves.values()) { if (mv.clip) out.add(mv.clip); if (mv.clip2) out.add(mv.clip2); }
  return [...out];
}

const DEFAULT_RUN_CLIPS = ['sh-run', 'sh-skate-b', 'sh-slide-r', 'sh-slide-l'];

/** One character form. INHERIT takes every key of that (earlier) form; the child's keys win, commands merge per command,
 *  strings add. The derivation rule (design v2 §0): a move is as written when the form lists it in its own commands or
 *  the parent form doesn't have it; an inherited one gets the form's startupAdd / reachMult, and a form with no
 *  derivation takes the parent's version of it. */
export function defkit(character: string, form: string, spec: KitSpec): Kit {
  const parent = spec.inherit ? findKit(character, spec.inherit) : null;
  const pspec: KitSpec = { ...(parent?.spec ?? {}) };
  for (const k of ['inherit', 'startupAdd', 'reachMult', 'grid'] as const) delete pspec[k];
  const commands = { ...(parent?.commands ?? {}), ...(spec.commands ?? {}) };
  const strings: StringRow[] = [...(spec.strings ?? []), ...(spec.grid ? stringGrid(spec.grid) : []), ...(parent?.strings ?? [])];
  const m: KitSpec = { ...pspec, ...spec, commands, strings };   // the child's keys win
  const startupAdd = def(m.startupAdd, 0), reachMult = def(m.reachMult, 1.0);
  const kit: Kit = {
    character, form, inherit: def(m.inherit, null), name: def(m.name, null),
    awakening: !!m.awakening, awakenForm: def(m.awakenForm, null), duration: def(m.duration, null), burn: def(m.burn, 0),
    mult: def(m.mult, 1.0), taken: def(m.taken, 1.0), guardTo: def(m.guardTo, null), dropTo: def(m.dropTo, null),
    keep: def(m.keep, []), cornered: def(m.cornered, 0), corneredMax: def(m.corneredMax, 0), passives: def(m.passives, []),
    bladeChip: def(m.bladeChip, null), walk: def(m.walk, 3.0), run: def(m.run, 8.0), runClips: def(m.runClips, DEFAULT_RUN_CLIPS),
    reishi: def(m.reishi, T.reishiMax), body: def(m.body, null), weapon: def(m.weapon, null), stance: def(m.stance, null),
    hide: def(m.hide, []), aura: def(m.aura, null), intro: def(m.intro, null), win: def(m.win, null),
    introCallout: def(m.introCallout, null), introWeapon: def(m.introWeapon, null), callout: def(m.callout, null),
    swingSfx: def(m.swingSfx, null), absorbSfx: def(m.absorbSfx, null), enterClips: def(m.enterClips, []),
    enterHook: def(m.enterHook, null), exitHook: def(m.exitHook, null), meter: def(m.meter, null),
    resetReiatsu: def(m.resetReiatsu, 0), ai: def(m.ai, null), cine: def(m.cine, null), blade: def(m.blade, null),
    grade: def(m.grade, null),
    kikonKonpaku: m.kikonKonpaku ?? (m.awakening ? T.kikonKonpakuAwakened : T.kikonKonpaku),
    meterGain: def(m.meterGain, null), formName: m.formName ?? form.toUpperCase(), drinkClip: def(m.drinkClip, null),
    respectCallout: def(m.respectCallout, null), bankaiForm: def(m.bankaiForm, null), pips: def(m.pips, null),
    crushHook: def(m.crushHook, null), rooted: !!m.rooted, field: def(m.field, null), warm: def(m.warm, 0),
    cold: def(m.cold, null), frostTouch: def(m.frostTouch, 0), resetForm: def(m.resetForm, null), uTag: def(m.uTag, null),
    calm: !!m.calm, stunTolerance: def(m.stunTolerance, null), ggRegen: def(m.ggRegen, 1.0),
    lAfterK: def(m.lAfterK, null), lAfterJ: def(m.lAfterJ, null), hooks: def(m.hooks, null), endlessForm: def(m.endlessForm, null),
    commands, strings, moves: new Map(), spec: m,
    cmdMoves: [...Object.values(spec.commands ?? {}).filter((v): v is string => !!v), ...(parent?.cmdMoves ?? [])],
  };
  const own = Object.values(spec.commands ?? {});
  const names = new Set<string>();
  for (const v of kit.cmdMoves) names.add(v);     // (a null command: none in this form; a parent's shadowed one still counts)
  for (const [from, , to] of strings) { names.add(from); names.add(to); }
  for (const l of [kit.lAfterK, kit.lAfterJ]) if (l && l !== true) names.add(l);
  for (const n of names) {
    const mv = findMove(n), pmv = parent?.moves.get(n);
    kit.moves.set(n, own.includes(n) || !pmv ? mv
      : startupAdd === 0 && reachMult === 1 ? pmv
      : parseMove(n, mv.spec, startupAdd, reachMult));
  }
  if (form === 'base' && !ROSTER.includes(character)) ROSTER.push(character);
  if (!KITS.has(character)) KITS.set(character, new Map());
  KITS.get(character)!.set(form, kit);
  return kit;
}
