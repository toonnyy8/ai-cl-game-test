// ai.ts <- duel/lisp/ai.lisp: the CPU player (BRAIN-SYSTEM). Generic code: a character's identity is the ai table of its
// kit form (intents, ranges, weighted moves per distance band, guard / Hoho chances, reactions, hooks named by the data).
// The CPU plays by writing its fighter's vpad exactly like a keyboard, once per fixed step, and draws every random number
// from simRnd01: a seed replays the same match. The Lisp's header (ai.lisp:1-46) explains the parts; in short:
//   perception  the opponent as he was DELAY steps ago (a ring of SNAPs; EASY 24, NORMAL 14, HARD 8); what happens to
//               the CPU itself (its own hit, its own blockstun) it feels at once
//   reflexes    the O ender / next link / SP cancel on hit, block punish, follow-ups, anti-Breaker / anti-Kikon, the
//               kit's reactions, Breaker a long guard, guard or Hoho a committed move (aiReflex)
//   intents     APPROACH / PRESSURE / ZONE / DEFEND re-picked every T.aiRepick f: a range to walk to, then a weighted
//               move for the distance band (aiNeutral, aiDecide, aiAttack)
//   heat        grows without dealing damage: the range shrinks, the Breaker weight doubles (matches end)
//   burst       BLUE out of a combo (aiBurstRoll), ORANGE off a string link that hit (aiOrangeP), WHITE behind on Reishi
// The learning CPU (learn.lisp) is M6: Brain.learn stays null and every learner call site is skipped (no draws either,
// as in the Lisp with BRAIN-LEARN NIL). The debug habits (BRAIN-HABIT, BRAIN-OFF, DUMB-STEP) aren't ported.
import { T } from './tuning';
import { f32, getf, len32, mod, weightedPick } from './math';
import {
  aiBurstWantedP, aiGuardMult, aiHohoSpareP, bandWeights, bankaiAllowedP, guardCancelOpenP, heatAfter, heatBreakerMult,
  heatRange, hohoAllowedP, moveEndFrame, parryFrameP, redP, tempCoolFrames, type Band,
} from './rules';
import {
  KIT_COMMANDS, callHook, hasKit, hookFn, kitCommandMove, kitDrop, kitHook, kitKLinkP, kitLLink, kitNext, kitPipCmdP,
  mvTotal, type Kit, type Move,
} from './kit';
import { VPAD_ACTIONS, type Action } from './vpad';
import { Snap, W, kitOf, oppOf, passiveP, simRnd01, stateOf, type Brain, type Ent, type FState } from './types';
import { awakenStateP, kitCommandOkP, rushParam } from './fighter';
import { burstOkP, kikonReadyP, kikonWorth } from './combat';

const FREE: readonly FState[] = ['idle', 'guard', 'run'];
const diffP = (table: object, b: Brain, dflt: number): number => getf(table, b.difficulty, dflt);

// ---------------------------------------------------------------- perception
/** Fill SNAP S with fighter O as he is now (Bankai West's ward is seen as a held guard). */
export function snapTake(s: Snap, o: Ent): Snap {
  const f = o.f, mv = f.move;
  const st: FState = passiveP(o, 'ward') && (f.state === 'idle' || f.state === 'run') ? 'guard' : f.state;
  s.x = o.pos[0]; s.z = o.pos[2]; s.state = st; s.sf = f.sf; s.guardT = f.guardT; s.projectile = incomingProjectileP(o);
  if (st === 'move' && mv) {
    const total = moveEndFrame(mv.s, mv.a, mv.r, mv.whiff, f.contact, mv.hits.length === 0);
    s.kind = mv.kind; s.phase = f.phase; s.s = mv.s; s.flags = mv.flags; s.contact = f.contact;
    s.tell = mv.params.tell ?? null;
    s.activeEnd = mv.s + mv.a; s.reach = mv.reach;
    s.left = f.phase === 'main' ? Math.max(0, total - f.sf) : 99;
    s.start = W.tick - f.sf - f.hold;
  } else {
    s.kind = null; s.phase = null; s.reach = 0; s.flags = []; s.contact = null;
    s.left = st === 'stun' ? Math.max(0, f.stun - f.sf) : 0;
    s.start = st === 'guard' ? W.tick - f.guardT : -1;
  }
  return s;
}

/** Is one of O's projectiles flying at his opponent within T.aiProjectileRange? */
export function incomingProjectileP(o: Ent): boolean {
  const v = o.f.opp;
  let hit = false;
  if (v && v.alive) {
    const q = v.pos, r2 = T.aiProjectileRange * T.aiProjectileRange;
    for (const hz of W.hazards)
      if (hz.alive && hz.owner === o && (hz.kind === 'wave' || hz.kind === 'fireball') && hz.hitsLeft > 0
          && (hz.x - q[0]) ** 2 + (hz.z - q[2]) ** 2 < r2) hit = true;
  }
  return hit;
}

/** Brain B of E sees opponent O this step: his SNAP goes into the ring; returns the SNAP of B.delay steps ago and the
 *  distance to it. Also counts his J starts for aiMashP. */
export function brainPerceive(e: Ent, b: Brain, o: Ent): [Snap, number] {
  const ring = b.ring, n = ring.length;
  const cur = ring[b.head] ?? (ring[b.head] = new Snap());
  snapTake(cur, o);
  const s = ring[mod(b.head - b.delay, n)] ?? cur, p = e.pos;
  const d = len32(f32(s.x - p[0]), f32(s.z - p[2]));   // (single floats, as the Lisp: d is checked against range edges)
  b.head = mod(b.head + 1, n);
  if (s.state === 'move' && s.kind === 'quick' && s.start !== b.jkey) {   // a J of his begins
    b.jkey = s.start;
    b.jstarts.unshift(W.tick);
  }
  if (b.jstarts.length) b.jstarts = b.jstarts.filter((t0) => !(W.tick - t0 > T.aiMashWindow));   // only the window's
  return [s, d];
}

/** Is he mashing J, as brain B saw him: T.aiMashStarts J starts within T.aiMashWindow frames. */
export const aiMashP = (b: Brain): boolean => b.jstarts.length >= T.aiMashStarts;

// ---------------------------------------------------------------- pressing buttons
/** Hold BUTTON (with mod when MODDED) for FRAMES steps, starting now. */
export function aiPress(b: Brain, button: Action, frames: number, modded = false, act: string = button): void {
  b.press = button; b.pressMod = modded; b.pressLeft = Math.max(1, frames); b.act = act;
}

/** Hold Step (the hop, then the run) with the stick toward (DIR 1) or away from (-1) the opponent until the distance
 *  passes TO (brainStep lets go). */
export function aiDash(b: Brain, dir: number, to: number): void {
  aiPress(b, 'step', T.aiDashFrames, false, 'dash');
  b.dash = dir; b.dashTo = to;
}

/** Press the buttons of kit command CMD at distance D (holding charge / stance / Breaker moves a while: a charge move is
 *  held to its full charge from beyond 7 m). Draws one roll whatever CMD is (an unknown one, e.g. a hook's 'wait',
 *  presses nothing). */
export function aiCommand(b: Brain, kit: Kit, cmd0: string, d: number, e: Ent | null = null): void {
  const r = simRnd01();
  const cmd = kit.rooted && (cmd0 === 'hoho' || cmd0 === 'side-step' || cmd0 === 'step') ? 'q' : cmd0;   // rooted forms
  const holdFor = (mv: Move | null, lo: number, spread: number) => (mv && mv.hold ? lo + Math.floor(r * spread) : 1);
  switch (cmd) {
    case 'q': aiPress(b, 'quick', 1); break;
    case 'f': aiPress(b, 'flash', 1); break;
    case 'sig': {
      const h = getf<string | null>(kit.ai, 'sigHold', null);       // a kit's own hold length (its sigHold hook)
      aiPress(b, 'sig', h && hookFn(h) ? callHook(h, kit, d, e) : holdFor(kitCommandMove(kit, 'sig'), 12, 40));
      break;
    }
    case 'sp1': case 'sp1-full': {                                 // sp1-full: a charge move held to its end
      const mv = kitCommandMove(kit, 'sp1');
      aiPress(b, 'flash', mv && mv.hold && (cmd === 'sp1-full' || d > 7.0) ? 2 + mv.hold[1] : holdFor(mv, 14, 46), true, 'sp1');
      break;
    }
    case 'sp2': aiPress(b, 'sig', r < 0.4 ? 20 : 1, true, 'sp2'); break;
    case 'breaker': aiPress(b, 'breaker', 12 + Math.floor(r * 30)); break;
    case 'step': aiPress(b, 'step', 1); break;
    case 'side-step': aiPress(b, 'step', 1, false, 'side-step'); break;   // brainStep holds the stick sideways
    case 'hoho': aiPress(b, 'step', 1, true, 'hoho'); break;
    case 'guard': aiPress(b, 'guard', 10 + Math.floor(r * 20)); break;
    case 'guard-long': aiPress(b, 'guard', 40, false, 'guard'); break;    // through a stagger and the dash-in after it
    case 'guard-cancel': aiPress(b, 'guard', 4); break;                    // the guard cancel, then neutral decides
    case 'kikon': {                                                        // held through the strike (aura + dash + S)
      const mv = kitCommandMove(kit, 'kikon')!;
      aiPress(b, 'kikon', rushParam(mv, 'aura') + rushParam(mv, 'dashMax') + mv.s + 4);
      break;
    }
    case 'awaken': aiPress(b, 'awaken', 1); break;
    case 'burst': aiPress(b, 'quick', 1, true, 'burst'); break;            // the state picks the mode
  }
}

// ---------------------------------------------------------------- decisions
export const aiTable = <V = any>(e: Ent, key: string, dflt: V = null as V): V => getf<V>(kitOf(e).ai, key, dflt);   // eslint-disable-line @typescript-eslint/no-explicit-any
/** E's deciding brain for the kits' CPU hooks (the ASSIST's borrowed brain is M6: his own, else null). */
export const aiBrain = (e: Ent): Brain | null => e.brain;
/** Note REASON (debug) and return CMD. */
export function why<C>(b: Brain, reason: string, cmd: C): C { b.why = reason; return cmd; }

/** One roll per opponent action (his SNAP S starts a new one): the guard / Hoho / reaction rolls. */
function aiEventRolls(b: Brain, s: Snap): void {
  if (s.start !== b.rollKey) {
    b.rollKey = s.start; b.guardRoll = simRnd01(); b.hohoRoll = simRnd01(); b.reactRoll = simRnd01();
  }
}

/** E's guard gauge as a fraction. */
export const aiGg = (e: Ent): number => e.g.gg / T.ggMax;
/** How much of its guard chance E's CPU uses (aiGuardMult); none in a form whose U is a move (a u hook). */
export const aiGuardK = (e: Ent): number => (kitHook(kitOf(e), 'u') ? 0 : aiGuardMult(e.g.gg, e.g.guardless));
/** Below the kit's ggLow of its guard gauge: back off, zone while it refills. */
export function aiGgLowP(e: Ent): boolean { const k = aiTable<number | null>(e, 'ggLow'); return k != null && aiGg(e) < k; }
/** E holds a guard: guard / guard-hit, or Bankai West's ward. */
export const guardingP = (e: Ent): boolean => stateOf(e) === 'guard' || stateOf(e) === 'guard-hit' || passiveP(e, 'ward');
const redOf = (e: Ent): boolean => redP(e.g.reishi, e.g.reishiMax);
const reishiFrac = (e: Ent): number => e.g.reishi / e.g.reishiMax;

/** Is E's awakening there to be taken (the awakened form registered: M3; until then the awakening code no-ops). */
const awakenFormP = (e: Ent): boolean => hasKit(e.f.character, kitOf(e).awakenForm);

/** Could E's CPU awaken out of this combo (the awakening breaks it as a Burst does)? */
function aiAwakenBreakP(e: Ent): boolean {
  const g = e.g;
  return g.evolution && awakenFormP(e) && awakenStateP(e, e.f) && reishiFrac(e) >= aiTable(e, 'awakenAbove', 0.0) && aiAwakenP(e);
}

/** E's opponent is nearly out of Reishi: finish him with hits (the Soul Break), not the Kikon rush. */
export function aiSbFinishP(e: Ent): boolean { const go = oppOf(e).g; return go.reishi < T.aiSbFinish * go.reishiMax; }

/** Burst Reverse (or the awakening) now? No sooner than the perception delay after the combo's 2nd hit, allowed and worth
 *  it (the next hit estimated as the combo's average so far): one roll per combo. In blockstun: a guard-locked string on a
 *  low guard gauge. */
function aiBurstRoll(e: Ent, b: Brain): boolean {
  const f = e.f, g = e.g;
  if (!b.burstRolled && b.burstT >= b.delay && (burstOkP(e) || aiAwakenBreakP(e))
      && (f.state === 'guard-hit' || aiBurstWantedP(g.reishi, g.reishiMax, Math.floor(f.comboDmg / Math.max(1, f.comboHits))))) {
    b.burstRolled = true;
    return aiBurstRolled(b, diffP(T.aiBurstP, b, 0.4));
  }
  return false;
}

/** Roll a burst at chance P (the learner's bandit re-weighting is M6): true to burst. */
const aiBurstRolled = (_b: Brain, p: number): boolean => simRnd01() < p;

/** End a landed string with the kit's cancel command (L, a cancel Signature) now? */
function aiCancelP(e: Ent, kit: Kit): boolean {
  const c = aiTable<object | null>(e, 'cancel'), p = getf<number | null>(c, 'sig', null), mv = kitCommandMove(kit, 'sig');
  return p != null && !!mv && mv.flags.includes('cancel') && kitCommandOkP(e, 'sig') && simRnd01() < p;
}

/** Our link hit: go on with the string (K T.aiStringFlashP of the time among the links kitNext allows), or end it with L
 *  (the kit's cancel / lAfterK), the kit's SP ender, an SP2 cancel on a grounded victim, or ORANGE. */
function stringReflex(e: Ent, b: Brain, f: Ent['f'], mv: Move): string | null {
  const kit = f.kit, nq = kitNext(kit, mv.name, 'q');
  let nf = kitNext(kit, mv.name, 'f');
  const bars = Math.floor(e.g.reiatsu / T.reiatsuBar), landed = f.sf === f.landSf;
  b.why = 'string';
  if (nf && kitPipCmdP(kit, 'f') && e.g.meter < 1) nf = null;          // no pip: no K link
  if (f.queued) return null;                                           // the next link is latched already
  {
    const p = aiTable(e, kitKLinkP(kit, mv.name) ? 'lAfterK' : 'lAfterJ', 0.0), l = kitLLink(kit, mv.name);
    if (p > 0 && landed && l && kitCommandOkP(e, 'sig', kit, false, l) && simRnd01() < p) return why(b, 'l-after-k', 'sig');
  }
  if (nf && simRnd01() < aiTable(e, 'stringK', T.aiStringFlashP)) return 'f';
  if (nq) return 'q';
  if (nf) return 'f';
  if (f.sf >= f.landSf && aiCancelP(e, kit)) return why(b, 'cancel', 'sig');
  {
    const h = aiTable<string | null>(e, 'spEnder');                     // the kit's own SP ender (its hook picks it, or null)
    if (h && landed && stateOf(oppOf(e)) !== 'air') {
      const c = callHook(h, e, kit);
      if (c) return why(b, 'sp-ender', c);
    }
  }
  if (bars >= aiTable(e, 'spCancelBars', 1) && kitCommandOkP(e, 'sp2') && landed && stateOf(oppOf(e)) !== 'air'
      && simRnd01() < T.aiSpCancelP) return 'sp2';                     // one roll, on the first step we see the hit
  if (!nq && !nf && landed && aiOrangeP(e, b, f)) return why(b, 'orange', 'burst');
  return null;
}

/** CHAIN REVERSE (ORANGE) out of a string link that hit with no link after it: allowed, the victim reeling within Q1's
 *  reach, and healthy (a Burst isn't worth keeping the flash-step for): one roll. */
function aiOrangeP(e: Ent, b: Brain, f: Ent['f']): boolean {
  const g = e.g;
  return burstOkP(e) === 'orange' && stateOf(oppOf(e)) === 'stun'
    && f.dist < kitCommandMove(f.kit, 'q')!.reach + 0.2
    && !aiBurstWantedP(g.reishi, g.reishiMax, 0)
    && aiBurstRolled(b, diffP(T.aiOrangeP, b, 0.25));
}

/** In ORANGE's startup-cut window, free, the victim still reeling within Q1's reach: restart the string. */
function aiChainFollowP(e: Ent): boolean {
  const f = e.f, os = stateOf(oppOf(e));
  return f.chain > 0 && (f.state === 'idle' || f.state === 'guard') && f.lock === 0
    && !e.pilot.vpad.down('quick')                                     // J still held from the burst's press: let go first
    && (os === 'stun' || os === 'air')
    && f.dist < kitCommandMove(f.kit, 'q')!.reach + 2.0;
}

/** SOUL REVERSE (WHITE) at a neutral decision: allowed, far from an opponent not attacking, behind on Reishi. */
function aiWhiteP(e: Ent, b: Brain, s: Snap, d: number): boolean {
  return burstOkP(e) === 'white' && d >= T.aiWhiteRange && s.state !== 'move'
    && reishiFrac(oppOf(e)) - reishiFrac(e) >= T.aiWhiteBehind
    && aiBurstRolled(b, T.aiWhiteP);
}

/** Per side, the CPU's Bankai entry: null = the kit's bankai rule, 'sure' = its chance 1, 'always', 'never' (debug A/B). */
export const aiBankaiMode: (string | null)[] = [null, null];
/** Enter the Bankai now (the kit's bankai plist p / oppBelow / oppKonpaku / ownKonpaku)? One roll per cup-3 stay. */
function aiBankaiP(e: Ent, b: Brain, bk: object): boolean {
  const mode = aiBankaiMode[e.f.side];
  if (mode === 'always') return true;
  if (mode === 'never' || b.bankaiRolled) return false;
  const o = oppOf(e), go = o.g, k = e.g.konpaku;
  const threat = Math.min(T.soulBreakMaxEvent, kikonWorth(o) + T.soulBreakExtra);
  if (k <= threat || (k <= getf(bk, 'ownKonpaku', 9)
                      && (go.reishi <= getf(bk, 'oppBelow', 0.0) * go.reishiMax || go.konpaku <= getf(bk, 'oppKonpaku', 0)))) {
    b.bankaiRolled = true;
    return simRnd01() < (mode === 'sure' ? 1.0 : getf(bk, 'p', 0.0));
  }
  return false;
}

/** Per side, the CPU's awakening on EVOLUTION: null = the kit's awaken rule, 'always', 'never' (debug A/B). */
export const aiAwakenMode: (string | null)[] = [null, null];
/** Awaken now (EVOLUTION)? The kit's awaken plist (minTaken, meleeShare); no key: yes. */
export function aiAwakenP(e: Ent): boolean {
  const mode = aiAwakenMode[e.f.side];
  if (mode === 'always') return true;
  if (mode === 'never') return false;
  const r = aiTable<object | null>(e, 'awaken'), g = e.g;
  if (!r) return true;
  const m = g.takenMelee, all = m + g.takenRanged;
  return all >= getf(r, 'minTaken', 0) && m >= getf(r, 'meleeShare', 0.0) * all;
}

/** The kit's cool (Rukia's cold gauge): hold U to cool to the next band at a neutral decision. */
function aiCoolP(e: Ent, s: Snap, d: number): boolean {
  const c = aiTable<object | null>(e, 'cool');
  return !!c && d < getf(c, 'near', 3.0) && !(getf(c, 'noProjectile', false) && s.projectile)
    && e.g.gg >= getf(c, 'minGg', 0) && simRnd01() < getf(c, 'p', 0.0);
}
/** The kit's brace: at absolute zero, hold U while he is near. */
function aiBraceP(e: Ent, d: number): boolean {
  const c = aiTable<object | null>(e, 'brace');
  return !!c && d < getf(c, 'near', 5.5) && e.g.gg >= getf(c, 'minGg', 0) && simRnd01() < getf(c, 'p', 1.0);
}

/** The reflexes (checked before the intent): a command or null. S = the perceived opponent, D = the perceived distance.
 *  Every branch that matches returns (the Lisp COND): a branch whose answer is null stops the reflexes too. */
export function aiReflex(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const f = e.f, g = e.g, kit = f.kit, st = f.state, mv = f.move;
  const free = FREE.includes(st);
  const red = redP(g.reishi, g.reishiMax);
  const hohoOk = hohoAllowedP(false, g.fs, f.hohoLock, g.burst);      // flash-step for one
  const guardK = aiGuardK(e);                                         // the guard gauge left
  const q = kitCommandMove(kit, 'q');
  const delay = b.delay, dif = b.difficulty;
  const snapAttacking = s.state === 'move' && s.sf < s.activeEnd;
  aiEventRolls(b, s);                                                 // one roll per opponent action
  if (st === 'move' && mv) {
    const landed = f.sf === f.landSf;
    // our completed string (a link-3 hit): the O ender, on a red opponent always, else the kit's oEnder chance
    if (f.contact === 'hit' && mv.flags.includes('ender') && !aiSbFinishP(e) && landed && kitCommandOkP(e, 'kikon', kit, true)
        && (kikonReadyP(e) || simRnd01() < aiTable(e, 'oEnder', T.aiOEnder)))
      return why(b, 'o-ender', 'kikon');
    // our Breaker landed (a hit or a Guard Break): open a string off it, K1 the kit's stringK share of the time
    if (f.contact === 'hit' && mv.kind === 'breaker' && f.sf >= f.landSf) {
      const ok = (c: string) => (!!kitCommandMove(kit, c) || !!kitDrop(kit, c)) && kitCommandOkP(e, c);
      return why(b, 'breaker-string', ok('f') && simRnd01() < aiTable(e, 'stringK', T.aiStringFlashP) ? 'f'
        : ok('q') ? 'q' : ok('f') ? 'f' : null);
    }
    // our hit landed and only the guard cancel's share of its recovery is left (no link latched): guard out of it,
    // unless we see him still reeling past our recovery's end
    if (!f.queued && guardCancelOpenP(f.sf, mv.s, mv.a, mv.r, f.contact, mv.kind === 'quick')
        && !((['stun', 'air', 'down', 'wakeup'] as FState[]).includes(s.state) && s.left - delay > mvTotal(mv) - f.sf))
      return why(b, 'guard-cancel', 'guard-cancel');
    // our own hit: finish the string, else an SP / L cancel
    if (f.contact === 'hit' && (mv.kind === 'quick' || mv.kind === 'flash')) return stringReflex(e, b, f, mv);
    // our L / O hit him: ORANGE on it too
    if (f.contact === 'hit' && (mv.kind === 'sig' || mv.kind === 'kikon') && landed && aiOrangeP(e, b, f))
      return why(b, 'orange', 'burst');
    // guard pressure (the kit's blockString): a blocked link goes on, pressed just before the chain opens: a J link, a
    // K link only T.aiBlockKP of the time, never a punishable ender
    if (f.contact === 'block' && (mv.kind === 'quick' || mv.kind === 'flash') && aiPressureP(e)
        && f.sf === mvTotal(mv) - T.chainLead - 1) {
      const ok = (m: Move | null) => !!m && typeof m.advBlock === 'number' && m.advBlock > T.ggEnderAdv;
      const nq = kitNext(kit, mv.name, 'q'), nf = kitNext(kit, mv.name, 'f');
      return why(b, 'pressure', ok(nf) && simRnd01() < T.aiBlockKP ? 'f' : ok(nq) ? 'q' : null);
    }
    return null;
  }
  // Step -> J: our Step lands him within J1's reach and he isn't mid-attack (a Breaker is: J beats it): J at f10, the
  // latch starts J1 at the Step's T.stepJCancel; one roll per Step
  if (st === 'step' && f.sf === T.stepJCancel - 2 && q && f.dist < q.reach + T.aiStepJMargin
      && !(snapAttacking && s.kind !== 'breaker') && s.state !== 'hoho'
      && simRnd01() < diffP(T.aiStepJP, b, 0.0))
    return why(b, 'step-j', 'q');
  // a Kikon rush's strike hit us, O held, and it dashes in after us: not red, hold guard from inside the stagger
  if (st === 'stun' && s.kind === 'kikon' && s.phase === 'follow' && !red && guardK > 0
      && b.reactRoll < diffP(T.aiFollowGuardP, b, 0.85))
    return why(b, 'anti-kikon', 'guard-long');
  if (!free) return null;
  // (the learning CPU's neutral read: M6)
  // the form's own reflexes (the kit's reflex hook), then the ones its opponent's kit asks of a CPU facing it
  {
    const h = aiTable<string | null>(e, 'reflex');
    const c = h ? callHook(h, e, b, s, d) : null;
    if (c) return c;
    const oh = getf<string | null>(kitOf(oppOf(e)).ai, 'oppReflex', null);
    const oc = oh ? callHook(oh, e, b, s, d) : null;
    if (oc) return oc;
  }
  // Bankai West's reversal: the ward just blocked a hit up close: L now and then
  {
    const p = aiTable<number | null>(e, 'wardReversal');
    if (p != null && passiveP(e, 'ward') && W.tick - f.warded <= 1 && f.dist < 3.0 && kitCommandOkP(e, 'sig') && b.reactRoll < p)
      return why(b, 'ward-reversal', 'sig');
  }
  // the reset: our blocked string just ended (no safe hit left in it) and he still guards: Q1 again
  if (b.was === 'move' && f.contact === 'block' && d < q!.reach + 0.2 && aiPressureP(e)) return why(b, 'pressure', 'q');
  // a red opponent still reeling from our hits (or bound): rush him
  if (kikonReadyP(e) && (s.state === 'stun' || s.state === 'air') && d < aiTable(e, 'kikonRange', 7.0)
      && kitCommandOkP(e, 'kikon') && !aiSbFinishP(e))
    return why(b, 'kikon', 'kikon');
  // the Bankai (cup 3, red, free: the kit's bankai), before the cash-out
  {
    const bk = aiTable<object | null>(e, 'bankai');
    if (bk && kit.bankaiForm && hasKit(f.character, kit.bankaiForm) && (st === 'idle' || st === 'guard')
        && bankaiAllowedP(true, g.konpaku) && aiBankaiP(e, b, bk))
      return why(b, 'bankai', 'awaken');
  }
  // NOMIHOSE's cash-out (the kit's cashout): Shift+K only as a punish or up close while NOME runs low
  {
    const c = aiTable<object | null>(e, 'cashout');
    if (c && kitCommandOkP(e, 'sp1') && d < 12.0) {
      b.why = (s.state === 'move' || s.state === 'stun') && s.left < 99 && s.left - delay >= getf(c, 'punish', 0) ? 'cashout-punish'
        : d < getf(c, 'near', 0) && g.meter < getf(c, 'below', 0) ? 'cashout-near' : null;
      if (b.why) return 'sp1';
    }
  }
  // South's tell under us: step sideways out of it or Hoho it
  if (s.flags.includes('bind') && s.phase === 'main') {
    const [lo, hi] = s.tell ?? [21, 30];
    if (lo <= s.sf + delay && s.sf + delay <= hi) {
      if (hohoOk && b.hohoRoll < aiTable(e, 'hoho', 0.2)) return why(b, 'anti-bind', 'hoho');
      if (b.reactRoll < diffP(T.aiAntiBreakerP, b, 0.5)) return why(b, 'anti-bind', 'side-step');
      return null;
    }
  }
  // a parry up close: don't feed it; a Breaker breaks it (half the time), else wait
  if (s.flags.includes('parry') && s.phase === 'main' && d < 4.0) return b.reactRoll < 0.5 ? why(b, 'anti-parry', 'breaker') : null;
  if (g.evolution && awakenFormP(e) && reishiFrac(e) >= aiTable(e, 'awakenAbove', 0.0) && aiAwakenP(e)) return 'awaken';
  // we just blocked an ender: it's our turn, felt at once; a K3 (-20) HARD punishes with K1 when it reaches
  if (b.was === 'guard-hit' && f.blockAdv <= T.aiPunishAdv && f.dist < q!.reach + 0.4
      && simRnd01() < diffP(T.aiBlockPunishP, b, 0.5))
    return why(b, 'block-punish', dif === 'hard' && f.blockAdv <= -20 && f.dist < kitCommandMove(kit, 'f')!.reach ? 'f' : 'q');
  // a stunned opponent (Guard Break, broken stance, our knockback) still stunned when Q1 lands
  if (s.state === 'stun' && s.left - delay >= q!.s && d < q!.reach + 0.6) return why(b, 'follow-up', 'q');
  // ... farther, the kit's stunFollow [cmd lo hi]
  {
    const sf = aiTable<[string, number, number] | null>(e, 'stunFollow');
    if (sf && s.state === 'stun' && sf[1] <= d && d <= sf[2] && kitCommandOkP(e, sf[0])
        && s.left - delay >= kitCommandMove(kit, sf[0])!.s)
      return why(b, 'stun-follow', sf[0]);
  }
  // the opponent is launched / down: the kit's oki (Yamamoto: a full-charge Shiranui, above okiAbove of his Reishi)
  if ((s.state === 'air' || s.state === 'down') && aiTable(e, 'oki') === 'sp1-full' && kitCommandMove(kit, 'sp1')?.hold
      && kitCommandOkP(e, 'sp1') && d > 3.0 && reishiFrac(e) >= aiTable(e, 'okiAbove', 0.0))
    return why(b, 'oki', aiTable<string>(e, 'oki'));
  // a recovering opponent in reach: punish
  if (s.state === 'move' && s.phase === 'main' && s.sf >= s.activeEnd && s.left - delay >= q!.s && d < q!.reach + 0.4)
    return why(b, 'punish', 'q');
  // an incoming Breaker, a Kikon rush, or a rush's follow-up strike: guard a rush when not red; else Hoho through its
  // dash; a Breaker: J1 as its dash runs into J1's reach (J beats I); a rush: Q1 it while it has the room, else Step aside
  if ((s.kind === 'breaker' || s.kind === 'kikon') && (s.phase === 'aura' || s.phase === 'dash' || s.phase === 'follow')
      && d < (s.phase === 'follow' ? s.reach + T.aiThreatMargin : T.aiAntiBreakerRange)
      && b.reactRoll < diffP(T.aiAntiBreakerP, b, 0.5)
      && (s.kind !== 'breaker'
          || (s.phase === 'dash' && ((hohoOk && b.hohoRoll < aiTable(e, 'hoho', 0.2)) || d < q!.reach + T.aiAntiBreakerJ))))
    return why(b, 'anti-breaker',
      s.kind === 'kikon' && !red && guardK > 0 ? 'guard'
        : s.phase === 'dash' && hohoOk && b.hohoRoll < aiTable(e, 'hoho', 0.2) ? 'hoho'
          : s.kind === 'breaker' ? 'q'
            : d > T.aiAntiBreakerQ ? 'q' : 'side-step');
  // the kit's reactions: stance vs a projectile / a Flash startup it can still beat; a parry vs a Flash startup whose hit
  // falls in its window
  {
    const r = aiTable<Record<string, string> | null>(e, 'react');
    if (r && b.reactRoll < T.aiReactP) {
      const fs = r['flash-startup'];
      const hit = (s.projectile && !!r.projectile)
        || (s.kind === 'flash' && d < 4.0 && !!fs && kitCommandOkP(e, fs) && (() => {
          const lead = s.s - s.sf - delay, m = kitCommandMove(kit, fs)!;
          return m.flags.includes('parry') ? s.phase === 'main' && parryFrameP(lead + T.superFreeze) : lead >= T.stanceIn + 2;
        })());
      if (hit) return why(b, 'react', s.projectile ? r.projectile : fs);
    }
  }
  // a long guard up close: Breaker it (one roll per guard episode)
  if (s.state === 'guard' && s.guardT >= T.aiGuardBreakHold && d < T.aiGuardBreakRange && b.breakKey !== s.start) {
    b.breakKey = s.start;
    return simRnd01() < T.aiGuardBreakP ? why(b, 'guard-break', 'breaker') : null;
  }
  // a committed move coming: Hoho it (flash-step to spare) or guard it; a low guard gauge guards less and steps aside
  // instead; a Kikon rush on us red: Step; a grab: Step
  if (s.state === 'move' && ['quick', 'flash', 'sig', 'sp', 'breaker', 'kikon'].includes(s.kind!)
      && s.sf < s.activeEnd && d < s.reach + T.aiThreatMargin) {
    const chance = aiTable(e, 'guard', 0.3) + (b.intent === 'defend' ? 0.25 : 0.0);
    if (hohoOk && aiHohoSpareP(g.fs, g.reishi, g.reishiMax) && s.s - s.sf >= 6
        && b.hohoRoll < (s.kind === 'quick' && aiMashP(b)                // a masher's J: Hoho it more
          ? Math.max(T.aiAntiMashHoho, 2 * aiTable(e, 'hoho', 0.2)) : aiTable(e, 'hoho', 0.2)))
      return why(b, aiMashP(b) ? 'anti-mash' : 'hoho', 'hoho');
    if (red && s.kind === 'kikon') return why(b, 'anti-kikon', 'side-step');
    if (s.flags.includes('grab')) return why(b, 'anti-grab', 'side-step');
    if (b.guardRoll < chance * guardK) return 'guard';
    if (b.guardRoll < chance) return why(b, 'low-guard', 'side-step');
    return null;
  }
  return null;
}

/** J beats K (DUEL_STRINGS §4): on the first free step after our blockstun, his next link is a K link still far enough
 *  from its hit, or his blocked J still recovers, inside our J1's reach: J1 gets there first. Felt at once; one roll. */
function jBeatsKP(e: Ent, b: Brain): boolean {
  return jBeatsOpenP(e, b) && simRnd01() < (aiMashP(b) ? T.aiAntiMashJP : diffP(T.aiJBeatsKP, b, 0.45));
}
/** jBeatsKP's window without its roll. */
export function jBeatsOpenP(e: Ent, b: Brain): boolean {
  const f = e.f, fo = f.opp!.f, om = fo.move, q = kitCommandMove(f.kit, 'q')!;
  return b.was === 'guard-hit' && (f.state === 'idle' || f.state === 'guard') && f.lock === 0
    && fo.state === 'move' && fo.phase === 'main' && !!om
    && ((om.kind === 'flash' && om.s - fo.sf >= q.s + 2)
        || (om.kind === 'quick' && fo.sf >= om.s + om.a))              // his blocked J still recovering
    && f.dist < q.reach + 0.2;
}

/** No reflex fired: walk to the intent's range, and now and then decide (aiDecide). */
function aiNeutral(e: Ent, b: Brain, s: Snap, d: number): void {
  const kit = kitOf(e), vp = e.pilot.vpad, heat = b.heat;
  if (--b.intentT <= 0) {
    b.intentT = T.aiRepick;
    const w = aiTable<object | null>(e, 'intents'), hot = Math.min(3.0, heat / 4.0), r = simRnd01();
    if (aiGgLowP(e)) b.intent = weightedPick(r, [['zone', 3], ['defend', 2]])!;   // low guard gauge: zone, no pressure
    else {
      const oi = getf<object | null>(kitOf(oppOf(e)).ai, 'oppIntent', null);     // facing a form a CPU waits out
      b.intent = weightedPick(r, [
        ['approach', getf(w, 'approach', 1)],
        ['pressure', Math.fround(Math.fround(getf(w, 'pressure', 1) + hot) + (oppGuardlessP(e) || oppGgLowP(e) ? 3 : 0))],
        ['zone', getf(w, 'zone', 1) + getf(oi, 'zone', 0)],
        ['defend', getf(w, 'defend', 1) + getf(oi, 'defend', 0)]]) ?? 'approach';
    }
  }
  if (--b.strafeT <= 0) {
    b.strafeT = T.aiStrafeTime[0] + Math.floor(T.aiStrafeTime[1] * simRnd01());
    b.strafe = simRnd01() < 0.5 ? -1 : 1;
  }
  const [lo0, hi0] = getf<[number, number]>(aiTable(e, 'ranges'), b.intent, [2.0, 4.0]);
  const [lo, hi] = heatRange(lo0, hi0, heat);
  vp.stick(lo <= d && d <= hi ? b.strafe : 0.3 * b.strafe, d > hi ? 1 : d < lo ? -1 : 0);
  if (--b.decideT <= 0) {
    b.decideT = aiDecideTime(e, b);
    aiDecide(e, b, kit, s, d, lo, hi, heat);
  }
}

/** Frames to the next neutral decision: the difficulty's T.aiThink + up to 40, x the kit's tempo. */
export function aiDecideTime(e: Ent, b: Brain): number {
  const n = diffP(T.aiThink, b, 24) + Math.floor(40 * simRnd01()), k = aiTable<number | null>(e, 'tempo');
  return k != null ? Math.max(1, Math.round(k * n)) : n;
}

/** E's opponent can't guard (his guard gauge ran out): press him. */
const oppGuardlessP = (e: Ent): boolean => oppOf(e).g.guardless;
/** Keep a blocked string going (the kit's blockString chance; always while hunting a low guard gauge)? Only while the
 *  opponent really holds guard, never below ggLow of our own gauge. */
export function aiPressureP(e: Ent): boolean {
  const p = aiTable<number | null>(e, 'blockString');
  return p != null && guardingP(oppOf(e)) && !aiGgLowP(e) && simRnd01() < (oppGgLowP(e) ? 1.0 : p);
}
/** E's opponent's guard gauge is under half: hunt the crush. */
const oppGgLowP = (e: Ent): boolean => oppOf(e).g.gg < 0.5 * T.ggMax;

/** A neutral decision at distance D with the preferred range LO..HI: the Kikon rush on a red opponent, WHITE, dash to /
 *  from the range, Step -> J, guard, attack (a weighted pick from the kit's band), or wait. */
function aiDecide(e: Ent, b: Brain, kit: Kit, s: Snap, d: number, lo: number, hi: number, heat: number): void {
  const q = kitCommandMove(kit, 'q');
  if (kikonReadyP(e) && d < aiTable(e, 'kikonRange', 7.0) && !(['down', 'wakeup', 'hoho'] as FState[]).includes(s.state)
      && kitCommandOkP(e, 'kikon') && !aiSbFinishP(e) && simRnd01() < aiKikonP(e)) {
    aiCommand(b, kit, 'kikon', d, e); b.why = 'kikon';
  } else if (aiWhiteP(e, b, s, d)) { aiCommand(b, kit, 'burst', d, e); b.why = 'white'; }
  else if (aiPipHurryP(e)) aiAttack(e, b, kit, s, d, heat, true);       // the arm's next crack is near: spend the pip
  else if (aiCoolP(e, s, d)) {                                         // Rukia: hold U the frames the next band needs
    aiPress(b, 'guard', 2 + tempCoolFrames(e.g.meter), false, 'cool'); b.why = 'cool';
  } else if (aiBraceP(e, d)) { aiPress(b, 'guard', 20, false, 'brace'); b.why = 'brace'; }
  else if (q && !kit.rooted && d > q.reach + T.aiStepJMargin && d < q.reach + T.stepDistance - 0.2   // Step -> J
           && !(s.state === 'move' && s.sf < s.activeEnd) && s.state !== 'hoho'
           && simRnd01() < diffP(T.aiStepInP, b, 0.0)) {
    aiDash(b, 1.0, q.reach); b.why = 'step-in';
  } else if (d > hi + aiTable(e, 'dashGap', T.aiDashGap) && simRnd01() < aiTable(e, 'dash', 0.0)) {
    aiDash(b, 1.0, 0.5 * (lo + hi)); b.why = 'dash';
  } else if (d < lo - T.aiDashGap && simRnd01() < (aiGgLowP(e) ? 0.6 : aiTable(e, 'dashBack', 0.0))) {
    aiDash(b, -1.0, 0.5 * (lo + hi)); b.why = 'dash-back';
  } else if (d < 3.4 && simRnd01() < Math.min(0.9, aiTable(e, 'neutralGuard', aiTable(e, 'guard', 0.3))
                                                 + (b.intent === 'defend' ? 0.2 : 0.0)) * aiGuardK(e)) {
    aiPress(b, 'guard', T.aiGuardHold[0] + Math.floor(T.aiGuardHold[1] * simRnd01()));
  } else if (simRnd01() < Math.min(0.9, getf(T.aiAggression, b.intent, 0.3) + 0.04 * heat + aiTable(e, 'attack', 0.0)
                                        + T.aiKoseiAggression * (1.0 - aiGg(e))          // KOSEI: a low gauge pays to attack
                                        + (oppGuardlessP(e) ? 0.3 : oppGgLowP(e) ? 0.2 : 0.0))) {
    aiAttack(e, b, kit, s, d, heat, false);
  }
}

/** The kit's pipHurry: a pip of the arm is left and its crack is at most that many frames away. */
export function aiPipHurryP(e: Ent): boolean {
  const h = aiTable<number | null>(e, 'pipHurry'), g = e.g;
  return h != null && !!kitOf(e).pips && g.meter >= 1 && g.armPending === null && g.meterIdle >= T.armCrack - h;
}

/** A weighted pick from the kit's band for D, pressed when it may start (not a J / K out of its reach). HURRY: only the
 *  pip commands of the band. True when something was pressed. */
export function aiAttack(e: Ent, b: Brain, kit: Kit, s: Snap, d: number, heat: number, hurry: boolean): boolean {
  const weights = (bandWeights(aiTable<Band[]>(e, 'moves', []), d) ?? []).map(([k, w]) => [k, w] as [string | null, number]);
  const brk = weights.find(([k]) => k === 'breaker');                   // (a guardless opponent has no guard to break)
  if (brk) brk[1] = oppGuardlessP(e) ? 0 : brk[1] * heatBreakerMult(heat);
  aiStanceWeights(e, s, d, weights);
  if (hurry) for (const kw of weights) if (!(kw[0] && kitPipCmdP(kit, kw[0]))) kw[1] = 0;
  const cmd = weightedPick(simRnd01(), weights);
  if (cmd && (!(KIT_COMMANDS as readonly string[]).includes(cmd) || (kitCommandMove(kit, cmd) && kitCommandOkP(e, cmd)))
      && (!(cmd === 'q' || cmd === 'f') || d <= 0.2 + kitCommandMove(kit, cmd)!.reach)) {   // don't whiff a string at range
    aiCommand(b, kit, cmd, d, e); b.why = hurry ? 'pip-hurry' : 'neutral';
    return true;
  }
  return false;
}

/** The chance a neutral decision rushes a red opponent: the kit's kikonP, at least T.aiKikonP in the last minute. */
function aiKikonP(e: Ent): number {
  const k = aiTable<number | null>(e, 'kikonP');
  return k == null ? T.aiKikonP : W.timer < 3600 ? Math.max(k, T.aiKikonP) : k;
}

/** The stance keys on a neutral pick's WEIGHTS (edited in place): no Q / F into a guard within 3 m below ggLow; none
 *  into a parry; L x the kit's low factor below its Reishi fraction, halved below its sigGg fraction of the guard gauge. */
function aiStanceWeights(e: Ent, s: Snap, d: number, weights: [string | null, number][]): void {
  for (const kw of weights)
    if ((kw[0] === 'q' || kw[0] === 'f')
        && ((aiGgLowP(e) && d < 3.0 && (s.state === 'guard' || s.state === 'guard-hit')) || s.flags.includes('parry'))) kw[1] = 0;
  const low = aiTable<[number, object] | null>(e, 'low'), sg = aiTable<number | null>(e, 'sigGg');
  const sig = weights.find(([k]) => k === 'sig');
  if (low && sig && reishiFrac(e) < low[0]) sig[1] *= getf(low[1], 'sig', 1);
  if (sg != null && sig && aiGg(e) < sg) sig[1] *= 0.5;
}

/** The CPU's first free step out of a hit or a wake-up with him close (against a J masher): hold Guard, else half the
 *  time a Hoho (flash-step to spare) or a back Step out of his reach; else nothing. */
function aiWakeStep(e: Ent, b: Brain, d: number): void {
  const f = e.f, g = e.g, r = simRnd01(), p = diffP(T.aiWakeGuardP, b, 0.6) * aiGuardK(e);
  if (r < p) { aiPress(b, 'guard', T.aiWakeGuardFrames, false, 'hold'); b.why = 'wake-guard'; }
  else if (r < p + 0.5 * (1.0 - p)) {
    aiCommand(b, kitOf(e), !kitOf(e).rooted && hohoAllowedP(false, g.fs, f.hohoLock, g.burst)
      && aiHohoSpareP(g.fs, g.reishi, g.reishiMax) ? 'hoho' : 'step', d, e);   // (a Step with the stick at rest: the back hop)
    b.why = 'wake-out';
  }
}

/** The gap after his blocked J string, too far for our J1, against a J masher: back-Step out of his restart. */
function aiGapStepP(e: Ent, b: Brain): boolean {
  const f = e.f, fo = f.opp!.f, om = fo.move, q = kitCommandMove(f.kit, 'q')!;
  return b.was === 'guard-hit' && (f.state === 'idle' || f.state === 'guard') && f.lock === 0
    && !f.kit.rooted && aiMashP(b)
    && fo.state === 'move' && fo.phase === 'main' && !!om && om.kind === 'quick'
    && fo.sf >= om.s + om.a && f.dist >= q.reach + 0.2
    && simRnd01() < diffP(T.aiGapStepP, b, 0.5);
}

/** One step of the CPU: perceive, then hold / reflex / neutral, written to the vpad (before fighterSystem reads it). */
export function brainStep(e: Ent, b: Brain): void {
  const f = e.f, vp = e.pilot.vpad, o = f.opp!;
  vp.beginStep();
  const [s, d] = brainPerceive(e, b, o);
  b.heat = heatAfter(b.heat, d > T.aiHeatFar);
  vp.stick(0, 0);
  if (!f.kit.bankaiForm) b.bankaiRolled = false;                       // a new cup-3 stay rolls again
  if ((['stun', 'air', 'down', 'wakeup', 'guard-hit'] as FState[]).includes(f.state)) {   // just took it: respect
    b.intent = 'defend'; b.intentT = aiTable(e, 'respect', T.aiRespect);
  }
  if (f.state === 'guard-hit' && f.sf === 0                            // blocked: hold on through the string?
      && simRnd01() < diffP(T.aiHoldGuard, b, 0.85)) aiPress(b, 'guard', f.stun + 20, false, 'hold');
  if ((['stun', 'air', 'down', 'wakeup'] as FState[]).includes(b.was) && FREE.includes(f.state) && f.lock === 0
      && d < T.aiWakeGuardRange && aiMashP(b))                        // out of a hit vs a J masher: guard first
    aiWakeStep(e, b, d);
  if (((f.state === 'stun' || f.state === 'air') && f.comboHits >= T.burstMinHits)
      || (f.state === 'guard-hit' && f.glock && aiGgLowP(e))) b.burstT++;  // the Burst clock
  else { b.burstT = 0; b.burstRolled = false; }
  if (b.act === 'dash' && b.pressLeft > 0 && (b.dash > 0 ? d <= b.dashTo : d >= b.dashTo)) {   // a dash reached its range:
    b.pressLeft = 0; b.decideT = 1;                                    // decide now (out of the run)
  }
  if (!(f.lock > 0 || f.state === 'cine')) {
    if (aiBurstRoll(e, b)) {                                           // a Burst, else the awakening
      if (burstOkP(e)) aiPress(b, 'quick', 1, true, 'burst'); else aiPress(b, 'awaken', 1);
      b.why = 'burst';
    } else if (aiChainFollowP(e)) { aiPress(b, 'quick', 1); b.why = 'chain'; }   // ORANGE's restart
    else if (jBeatsKP(e, b)) { aiPress(b, 'quick', 1); b.why = 'j-beats-k'; }
    else if (aiGapStepP(e, b)) { aiPress(b, 'step', 1, false, 'step'); b.why = 'gap-step'; }
    else if (b.pressLeft > 0                                           // a reflex may drop a guard / a dash, or a Breaker's
             && !(f.state === 'move' && f.move!.kind === 'breaker' && f.contact === 'hit')   // hold once it landed
             && (b.act === 'hold' || !(b.press === 'guard' || b.act === 'dash'))) b.pressLeft--;
    else {
      const cmd = aiReflex(e, b, s, d);
      if (cmd && !(cmd === 'guard' && b.press === 'guard' && b.pressLeft > 0)) aiCommand(b, kitOf(e), cmd, d, e);
      else if (b.pressLeft > 0) b.pressLeft--;
      else if (f.state === 'idle' || f.state === 'run') aiNeutral(e, b, s, d);
    }
  }
  b.was = f.state;
  // the buttons of this step
  for (const a of VPAD_ACTIONS)
    vp.set(a, (b.pressLeft > 0 && a === b.press) || (a === 'mod' && b.pressLeft > 0 && b.pressMod));
  if (b.pressLeft > 0) {
    if (b.act === 'guard') vp.stick(0, 0);
    else if (b.act === 'side-step') vp.stick(b.strafe, 0);
    else if (b.act === 'dash') vp.stick(0, b.dash);
  }
}
