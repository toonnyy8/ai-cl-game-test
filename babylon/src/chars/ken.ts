// ken.ts <- duel/lisp/ken.lisp, the BASE form only: ZARAKI KENPACHI's moves (defmove), his base kit (defkit) and the
// hooks it uses. Nozarashi's three cups (NOME), the Bankai and KATAUDE are M3: Awaken is refused until those kits are
// registered. Clip names are the art contract. The kit's ai table is data (M2 ports ai.lisp and the ken-* CPU hooks).
import { T } from '../sim/tuning';
import { getf, mod } from '../sim/math';
import { aiHohoSpareP, bankaiAllowedP, hohoAllowedP, stanceRelease } from '../sim/rules';
import { defkit, defmove, defmoveCopy, kitCommandMove, kitNext, registerHooks, type Kit, type Move } from '../sim/kit';
import { emit, kitOf, oppOf, simRnd01, stateOf, type Brain, type Ent, type Snap } from '../sim/types';
import { callout, kitCommandOkP, moveParam, startMove } from '../sim/fighter';
import { kikonReadyP } from '../sim/combat';
import { aiBrain, aiMashP, aiSbFinishP, aiTable, guardingP, why } from '../sim/ai';
import { spawnHazard } from '../sim/hazards';
import type { Action } from '../sim/vpad';

// ================================================================ base
// the J / K strings (docs/DUEL_STRINGS.md §3.3): no school, a street fighter with a sword who kicks. Every K at link 2 / 3
// at S_eff 14, at 80 % of the design's damage.
defmove('ke-j1', { kind: 'quick', clip: 'ke-q1', startup: 7, active: 3, recovery: 12, dmg: 35, advBlock: -2,
  reach: 1.04, arc: 100, onHit: 'flinch', slide: 0.8 });            // ARAGIRI: a lazy slash, lunge 0.8 m
defmove('ke-j2', { kind: 'quick', clip: 'ke-q2', startup: 7, active: 3, recovery: 13, dmg: 35, advBlock: -2,
  reach: 1.04, arc: 100, onHit: 'flinch' });                        // KAESHIGIRI: the backhand
defmove('ke-j3', { kind: 'quick', clip: 'ke-kick', startup: 8, active: 3, recovery: 18, dmg: 42, advBlock: -4,
  reach: 0.88, arc: 60, onHit: 'stagger', flags: ['ender'] });      // KENKA-GERI: a front kick to the gut
defmove('ke-k1', { kind: 'flash', clip: 'ke-f1', startup: 16, active: 4, recovery: 20, dmg: 70, advBlock: -3,
  reach: 2.8, arc: 120, onHit: 'stagger' });                        // OBURI: the huge two-handed swing
defmove('ke-k2', { kind: 'flash', clip: 'ke-f2', enter: 6, startup: 20, active: 4, recovery: 24, dmg: 60, advBlock: -3,
  reach: 2.5, arc: 90, onHit: 'stagger' });                         // KIRIAGE: from the floor up
defmove('ke-k3', { kind: 'flash', clip: 'ke-q3', clipS: 11, enter: 6, startup: 20, active: 5, recovery: 34, dmg: 80, advBlock: -20,
  reach: 2.7, arc: 360, onHit: 'crumple', flags: ['ender'] });      // BUNMAWASHI: the full spin
defmoveCopy('ke-j2s', 'ke-j2');
defmoveCopy('ke-k2s', 'ke-k2');
// "KITTE MIRO YO": hold = 6 f in (hit = counter-hit), then super armour up to 60 f storing damage; release (or 60 f) ->
// the cut, 100 + stored, guard-crushing when stored >= 150 (the hooks decide)
defmove('ke-stance', { kind: 'sig', clip: 'ke-stance-hold', clip2: 'ke-stance-cut', callout: 'KITTE MIRO YO',
  hold: [T.stanceIn, T.stanceHoldMax], flags: ['stance'], blend: 6,
  startup: 8, active: 4, recovery: 24, dmg: T.stanceBaseDamage, advBlock: -14,
  reach: 2.8, arc: 120, onHit: 'knockback', kb: 3.0,
  release: 'ken-stance-release' });
// leap 5 m, overhead, a 3 m ground-crack line
defmove('ke-buttagiru', { kind: 'sp', clip: 'ke-buttagiru', callout: 'BUTTAGIRU',
  startup: 22, active: 4, recovery: 26, dmg: 180, advBlock: -14, slide: 5.0,
  vol: ['cap', 0.0, 3.0, 0.5, 0.6], onHit: 'knockdown', kb: 2.0, flags: ['ranged'], onFrame: [[22, 'ken-ground-crack']],
  params: { meleeRange: 2.6 } });                                    // the blade within 2.6 m, the crack beyond: ranged
// dash 6 m at 14 m/s during the 26 active frames (the tick hook); contact = flurry hit 1 of 5 (25 each), then ke-flurry
// (4 more + a 60 launcher). Still holding at the dash: guard-crushing.
defmove('ke-charge', { kind: 'sp', clip: 'ke-charge', clip2: 'ke-flurry', callout: 'ORE NI KIRENEE MON WA NEE',
  startup: 14, active: 26, recovery: 24, dmg: 25, advBlock: -16,
  vol: ['cap', 0.0, 1.4, 1.1, 0.6], onHit: 'flinch',
  tick: 'ken-charge-tick', onLand: 'ken-flurry',
  params: { dashSpeed: 14.0 } });
// not a command: ken-flurry starts it when the charge connects (the kit's (ke-charge land ke-flurry) string)
defmove('ke-flurry', { kind: 'sp', clip: 'ke-flurry', startup: 10, active: 31, recovery: 24, dmg: 25, advBlock: -16,
  reach: 2.2, arc: 120, onHit: 'flinch',
  hits: [[10, 11], [16, 17], [22, 23], [28, 29], [40, 41, { dmg: 60, onHit: 'launch' }]] });
defmove('ke-breaker', { kind: 'breaker', clip: 'ke-breaker', clip2: 'ke-shoulder', callout: 'SHOULDER CHARGE' });
// O, the Kikon rush module CHARGE: 5 f of aura, then a charge at 13 m/s for at most 36 f that keeps turning at him
// (150 deg/s) and eats one hit on its armour, then the stance's huge cross-body cut: 9.4 m, <= 50 f. Cooldown 90.
defmove('ke-kikon', { kind: 'kikon', clip: 'ke-charge', clip2: 'ke-stance-cut', clipS: 8, cine: 'ken-kikon-cine',
  startup: 9, active: 3, recovery: 24, dmg: 70, advBlock: -14, reach: 2.4, arc: 110, onHit: 'knockback', kb: 2.5,
  armorHits: 1, cooldown: 90,
  params: { aura: 5, aim: 120.0, speed: 13.0, dashMax: 36, dashTrack: 150.0, look: 'charge', sfx: 'laugh' } });

// ================================================================ forms
defkit('kenpachi', 'base', {
  name: 'KENPACHI', body: 'kenpachi', weapon: 'ken-katana', stance: 'ke-stance',
  intro: 'ke-intro', win: 'ke-win',
  walk: T.walkKenpachi, run: T.runKenpachi, runClips: ['ke-run', 'ke-skate-b', 'ke-slide-r', 'ke-slide-l'], reishi: T.reishiMax,
  aura: 'reiatsu', cornered: T.corneredPerKonpaku, corneredMax: T.corneredMax, resetReiatsu: T.resetReiatsuBonus,
  absorbSfx: 'laugh',
  stunTolerance: 26.0,                        // the hidden stun: he takes the most before he flies
  commands: { q: 'ke-j1', f: 'ke-k1', sig: 'ke-stance', sp1: 'ke-buttagiru', sp2: 'ke-charge',
              breaker: 'ke-breaker', kikon: 'ke-kikon' },
  grid: ['ke-j1', 'ke-j2', 'ke-j3', 'ke-k1', 'ke-k2', 'ke-k3', 'ke-j2s', 'ke-k2s'],
  strings: [['ke-charge', 'land', 'ke-flurry']],
  awakenForm: 'nozarashi',
  ai: { intents: { approach: 2, pressure: 4, zone: 0, defend: 1 },
        ranges: { approach: [2.0, 4.0], pressure: [1.0, 2.6], zone: [4.0, 6.0], defend: [3.0, 5.0] },
        moves: [[0.0, 1.3, 'q', 5, 'f', 2, 'breaker', 1, 'sp2', 1, 'sig', 2, null, 3],   // J up close only, K beyond
                [1.3, 3.0, 'f', 4, 'breaker', 1, 'sp2', 1, 'sig', 2, null, 3],
                [3.0, 4.0, 'f', 1, 'sp1', 2, 'step', 1, null, 2],
                [4.0, 6.0, 'sp1', 4, 'sp2', 2, null, 1],
                [6.0, 99.0, 'step', 1, 'kikon', 1, null, 1]],                      // the charge as a poke
        guard: 0.35, hoho: 0.2, awakenAbove: 0.0, spCancelBars: 1, dash: 0.8, kikonRange: 9.0,
        react: { projectile: 'sig', 'flash-startup': 'sig' }, blockString: 0.8,
        reflex: 'ken-ai-reflex', assistGuard: 'ken-assist-guard', spEnder: 'ken-sp-ender', sigHold: 'ken-sig-hold' },
});

// ================================================================ hooks (called through the data's names)
registerHooks({
  /** The stance is released: the cut deals 100 + stored and crushes guard at stored >= 150. */
  'ken-stance-release'(e: Ent) {
    const f = e.f, [dmg, crush] = stanceRelease(f.stored);
    f.dmgBonus = dmg - T.stanceBaseDamage; f.crush = crush; f.stored = 0;
    if (crush) callout(e, 'KITTE MIRO YO!');
    emit('sfx', crush ? 'laugh' : 'whoosh-heavy', e);
  },
  /** Buttagiru lands: a 3 m crack in the ground (a look; the stage marks are the renderer's). */
  'ken-ground-crack'(e: Ent) {
    spawnHazard('line', e, { x: e.pos[0], z: e.pos[2], yaw: e.yaw, size: 3.5, life: 50, look: 'crack' });
    emit('ground-scar', e.pos[0], e.pos[2], e.yaw, [1.2, 2.8], 0.9);
    emit('sfx', 'ground-crack', e);
  },
  /** SP2 dash: 14 m/s during the active frames until it touches; still holding the button when the dash starts =
   *  guard-crushing (the Breaker property). */
  'ken-charge-tick'(e: Ent) {
    const f = e.f, mv = f.move!, sf = f.sf;
    if (f.phase === 'main') {
      if (sf === mv.s && e.pilot.vpad.down(f.button as Action)) f.crush = true;
      if (mv.s <= sf && sf < mv.s + mv.a && f.contact === null && f.dist > 1.2) {
        const v = e.mo.vel, sp = moveParam(e, 'dashSpeed');
        v[0] = sp * -Math.sin(e.yaw); v[2] = sp * -Math.cos(e.yaw);
      }
    }
  },
  /** The SP2 dash connected: on a hit, the flurry (4 more cuts + a launcher). */
  'ken-flurry'(e: Ent) {
    if (e.f.contact === 'hit') {
      startMove(e, kitNext(kitOf(e), 'ke-charge', 'land')!);
      e.f.contact = 'hit'; e.f.landSf = 0;
    }
  },
});

// ================================================================ the CPU (the kit's ai hooks; ai.ts; docs/DUEL_AI_V2.md)
// Chances by difficulty (ken.lisp *KEN-AI-...*).
type Dif = Record<string, number>;
const KEN_AI_ANTI_BREAKER: Dif = { easy: 0.0, normal: 0.2, hard: 0.9 };   // answer a Breaker by the reach model
const KEN_AI_HOHO: Dif = { easy: 0.0, normal: 0.1, hard: 0.75 };          // Hoho a K / L / SP into its perfect lead
const KEN_AI_MASH_STANCE: Dif = { easy: 0.0, normal: 0.005, hard: 0.35 }; // the stance vs a J masher (per free step)
const KEN_AI_NO_RESET: Dif = { easy: 0.0, normal: 0.2, hard: 0.8 };       // guard instead of a slow J1 reset
const KEN_AI_O_ENDER: Dif = { easy: 0.0, normal: 0.1, hard: 0.85 };       // the O ender's extra chance off a landed ender
const KEN_AI_LUNGE_PUNISH: Dif = { easy: 0.0, normal: 0.3, hard: 0.9 };   // J1 from its lunge's reach on a punish
const KEN_AI_LUNGE: Dif = { easy: 0.0, normal: 0.0, hard: 0.06 };         // J1 from its lunge's reach in neutral (per step)
const KEN_AI_WALK_IN: Dif = { easy: 0.0, normal: 0.005, hard: 0.8 };      // walk into J1's range (per step)
const KEN_AI_BANKAI_STRICT: Dif = { easy: 0.0, normal: 0.0, hard: 1.0 };  // the Bankai only as a finisher (HARD: a rule)
const KEN_AI_SP2_ENDER: Dif = { easy: 0.0, normal: 0.1, hard: 0.6 };      // else the SP2 ender (the charge) off it
const KEN_AI_FAR_PUNISH: Dif = { easy: 0.0, normal: 0.2, hard: 0.9 };     // beyond J1's lunge: charge / leap / K1 on a punish
const KEN_AI_FIRST_STRIKE: Dif = { easy: 0.0, normal: 0.002, hard: 0.35 };   // J1 / K1 timed to his closing speed vs a masher
const KEN_AI_FIRST_STRIKE_N: Dif = { easy: 0.0, normal: 0.0, hard: 0.15 };   // the same vs anyone else (per step)
const KEN_AI_SIG_PUNISH: Dif = { easy: 0.0, normal: 0.1, hard: 0.5 };     // the charge as a close punish when it lands in time
const KEN_AI_SP1_ENDER: Dif = { easy: 0.0, normal: 0.1, hard: 0.9 };      // SP1 off a landed ender when it lands in his reel
const KEN_CHARGE_MPF = 0.233;     // the charge's dash, metres per frame (14 m/s)
const KEN_BREAKER_SPEED = 0.16;   // a Breaker dash's metres per frame, for the anti-Breaker timing

const kenP = (b: Brain, table: Dif): number => table[b.difficulty] ?? 0.0;
/** Roll TABLE's chance at B's difficulty (no draw at 0 or 1). */
function kenRoll(b: Brain, table: Dif): boolean { const p = kenP(b, table); return p > 0 && (p >= 1.0 || simRnd01() < p); }
const snapRecovering = (s: Snap): boolean => s.state === 'move' && s.phase === 'main' && s.sf >= s.activeEnd;

/** The Bankai leaves him 1 Konpaku: at HARD only as a finisher or with little to lose; else this stay's roll is spent. */
function kenBankaiGate(e: Ent, b: Brain): void {
  const kit = kitOf(e), k = e.g.konpaku, ko = oppOf(e).g.konpaku;
  if (kit.bankaiForm && !b.bankaiRolled && bankaiAllowedP(true, k)
      && !(k <= 2 || (k <= 3 && ko <= 4) || (k <= 4 && ko <= 2)) && kenRoll(b, KEN_AI_BANKAI_STRICT))
    b.bankaiRolled = true;
}
/** Neutral, he isn't attacking, between J1's lunge reach and 3 m: walk in toward J1's range ('wait': the stick is set). */
function kenWalkIn(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const q = kitCommandMove(kitOf(e), 'q');
  if (q && ['idle', 'run', 'guard'].includes(s.state) && ['idle', 'run'].includes(stateOf(e)) && !aiMashP(b)
      && d > Math.max(kenLungeReach(e) + 0.1, q.reach + 0.3) && d < 3.0 && kenRoll(b, KEN_AI_WALK_IN)) {
    e.pilot.vpad.stick(0.3 * b.strafe, 1);
    return why(b, 'walk-in', 'wait');
  }
  return null;
}
/** How far his J1 reaches with its own lunge (slide). */
function kenLungeReach(e: Ent): number { const q = kitCommandMove(kitOf(e), 'q'); return q ? q.reach + q.slide : 0.0; }
/** J1 from its lunge's reach: punish his recovery / reel when J1 lands before he is free, or open on him in neutral. */
function kenLunge(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const q = kitCommandMove(kitOf(e), 'q'), lr = kenLungeReach(e), left = s.left - b.delay;
  if (q && d > q.reach + 0.2 && d <= lr + 0.1 && kitCommandOkP(e, 'q')) {
    if ((snapRecovering(s) || s.state === 'stun') && s.left < 99 && left >= q.s + 2 && b.reactRoll < kenP(b, KEN_AI_LUNGE_PUNISH))
      return why(b, 'lunge-punish', 'q');
    if ((s.state === 'idle' || s.state === 'run') && kenRoll(b, KEN_AI_LUNGE)) return why(b, 'lunge', 'q');
  }
  return null;
}
/** His Breaker within 6 m: K1 if it is within K1's reach before the strike, else J1, else a Hoho close to the strike;
 *  meanwhile wait. */
function kenAntiBreaker(e: Ent, b: Brain, s: Snap, d: number): string | null {
  if (!(s.kind === 'breaker' && (s.phase === 'aura' || s.phase === 'dash') && d < 6.0 && b.reactRoll < kenP(b, KEN_AI_ANTI_BREAKER)))
    return null;
  const kit = kitOf(e), v = KEN_BREAKER_SPEED, dl = b.delay, trig = T.breakerTrigger;
  const dash = s.phase === 'dash' ? dl : dl - T.breakerAura;           // frames it has dashed by now (< 0: aura left)
  const wait = Math.max(0, -dash);                                     // aura frames still to come
  const de = d - v * Math.max(0, dash);                                // its distance when the dash goes on from now
  const strike = wait + Math.max(0.0, de - trig) / v + T.breakerStartup;   // frames until its strike is active
  const fits = (cmd: string) => {
    const mv = kitCommandMove(kit, cmd);
    return !!mv && kitCommandOkP(e, cmd) && mv.s + 1 < strike
      && Math.max(trig, de - v * Math.max(0, mv.s - wait)) <= mv.reach + 0.3;
  };
  if (fits('f')) return why(b, 'anti-breaker', 'f');
  if (fits('q')) return why(b, 'anti-breaker', 'q');
  if (strike <= 13 && hohoAllowedP(false, e.g.fs, e.f.hohoLock, e.g.burst)) return why(b, 'anti-breaker', 'hoho');
  if (strike > 13) return 'wait';                                      // (not yet: the generic J1 would come early)
  return null;
}
/** His K / L / SP coming whose hit falls 1-12 f from now (the perfect-Hoho lead): Hoho it, with flash-step to spare; a K
 *  the stance can still beat is left to the stance (the kit's react). */
function kenHohoCommit(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const f = e.f, g = e.g, left = s.s - s.sf - b.delay;
  if (s.state === 'move' && (s.kind === 'flash' || s.kind === 'sig' || s.kind === 'sp') && s.phase === 'main'
      && s.sf < s.activeEnd && left >= 1 && left <= T.perfectLead && d < s.reach + 1.0
      && !s.flags.includes('grab')
      && hohoAllowedP(false, g.fs, f.hohoLock, g.burst)
      && aiHohoSpareP(g.fs, g.reishi, g.reishiMax)
      && !(s.kind === 'flash' && aiTable<Record<string, string> | null>(e, 'react')?.['flash-startup'] && d < 4.0
           && left >= T.stanceIn + 2 && b.reactRoll < T.aiReactP)
      && b.hohoRoll < kenP(b, KEN_AI_HOHO))
    return why(b, 'hoho-commit', 'hoho');
  return null;
}
/** His perceived closing speed (m/f) from the SNAP we see and the one before it in the ring. As ken.lisp KEN-CLOSING
 *  computes it: (s - s1).(s - us) / d, i.e. > 0 while he moves AWAY (the docstring says "> 0: coming"; kept as the code). */
function kenClosing(e: Ent, b: Brain, s: Snap, d: number): number {
  const ring = b.ring, s1 = ring[mod(b.head - b.delay - 2, ring.length)], p = e.pos;
  if (!s1 || d < 0.01) return 0.0;
  return -((s1.x - s.x) * (s.x - p[0]) + (s1.z - s.z) * (s.z - p[2])) / d;
}
/** Frames until command CMD's hit touches him at D metres (he stands), or null: out of its reach / can't start. */
function kenArrive(e: Ent, cmd: string, d: number): number | null {
  const mv = kitCommandMove(kitOf(e), cmd);
  if (!(mv && kitCommandOkP(e, cmd))) return null;
  const r = mv.reach, sl = mv.slide, st = mv.s;
  if (mv.name === 'ke-charge') {                                       // the dash runs until it touches
    const run = Math.max(0.0, d - r - 0.4);
    return run <= KEN_CHARGE_MPF * 24 ? st + Math.ceil(run / KEN_CHARGE_MPF) : null;
  }
  if (sl > 2.0) return sl - 1.0 <= d && d <= sl + r - 0.5 ? st : null; // the leap (Buttagiru): it lands sl ahead
  return d <= r + Math.min(sl, 0.8) + 0.05 ? st : null;
}
/** The punish SPs to try, best first: a line-cut SP1 then the charge; else the charge, then SP1 (the leap). */
function kenSpOrder(e: Ent): string[] {
  const sp = kitCommandMove(kitOf(e), 'sp1');
  return sp && sp.slide < 2.0 && sp.name !== 'ke-meteor-n' ? ['sp1', 'sp2'] : ['sp2', 'sp1'];
}
const kenPunishCmd = (e: Ent, d: number, left: number): string | undefined =>
  kenSpOrder(e).find((c) => { const t0 = kenArrive(e, c, d); return t0 != null && t0 < left - 1; });
/** He recovers or reels within J1's lunge and the charge lands before he is free: the charge instead of a J1 string. */
function kenSigPunish(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const left = s.left - b.delay;
  if ((snapRecovering(s) || s.state === 'stun') && s.left < 99 && left > 4 && d <= kenLungeReach(e) + 0.1
      && b.reactRoll < kenP(b, KEN_AI_SIG_PUNISH)) {
    const c = kenPunishCmd(e, d, left);
    return c ? why(b, 'sig-punish', c) : null;
  }
  return null;
}
/** He recovers or reels beyond J1's lunge: the signature command that gets there before he is free. */
function kenFarPunish(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const left = s.left - b.delay;
  if ((snapRecovering(s) || s.state === 'stun') && s.left < 99 && left > 4 && d > kenLungeReach(e) + 0.1 && d < 9.0
      && b.reactRoll < kenP(b, KEN_AI_FAR_PUNISH)) {
    const c = kenPunishCmd(e, d, left);
    return c ? why(b, 'far-punish', c) : null;
  }
  return null;
}
/** Neutral first strike timed to his perceived closing speed: J1 when he will be inside its lunge's reach as it lands,
 *  else K1 when he walks into K1's reach outside his own J's. */
function kenFirstStrike(e: Ent, b: Brain, s: Snap, d: number): string | null {
  if (!(['idle', 'run', 'guard'].includes(s.state) && ['idle', 'run'].includes(stateOf(e)) && d < 4.0
        && kenRoll(b, aiMashP(b) ? KEN_AI_FIRST_STRIKE : KEN_AI_FIRST_STRIKE_N))) return null;
  const kit = kitOf(e), cv = Math.max(0.0, kenClosing(e, b, s, d)), his = kitCommandMove(kitOf(oppOf(e)), 'q');
  const q = kitCommandMove(kit, 'q'), f = kitCommandMove(kit, 'f');
  const at = (c: string, mv: Move | null) => (mv && kitCommandOkP(e, c) ? d - cv * (mv.s + b.delay) : null);
  const dq = at('q', q), df = at('f', f);
  if (dq != null && dq <= q!.reach + Math.min(0.8, q!.slide)) return why(b, 'first-strike', 'q');
  if (df != null && cv > 0.02 && (his ? his.reach + his.slide + 0.2 : 1.6) <= df && df <= f!.reach + 0.1)
    return why(b, 'first-strike', 'f');
  return null;
}
/** Is KIT's L the stance (KITTE MIRO YO)? */
function kenStanceP(kit: Kit): boolean { const mv = kitCommandMove(kit, 'sig'); return !!mv && mv.flags.includes('stance'); }
/** He mashes J within 2.4 m and no J of his is about to land: the stance soaks his string and cuts back. */
function kenAntiMash(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const kit = kitOf(e);
  if (aiMashP(b) && d < 2.4 && kenStanceP(kit) && kitCommandOkP(e, 'sig')
      && (s.state !== 'move' || (s.kind === 'quick' && s.sf >= s.activeEnd))
      && !['stun', 'air', 'down', 'wakeup'].includes(s.state)
      && kenRoll(b, KEN_AI_MASH_STANCE))
    return why(b, 'anti-mash', 'sig');
  return null;
}
/** Our blocked string just ended and he still guards: a J1 of 10 f or more is too slow a reset: guard. */
function kenNoReset(e: Ent, b: Brain, d: number): string | null {
  const f = e.f, q = kitCommandMove(kitOf(e), 'q');
  if (b.was === 'move' && f.contact === 'block' && q && q.s >= 10 && d < q.reach + 0.2 && guardingP(oppOf(e))
      && kenRoll(b, KEN_AI_NO_RESET))
    return why(b, 'no-reset', 'guard');
  return null;
}
/** Off a landed ender, the form's SP1 when its startup + 2 fits in that reel (before the O ender or the charge). */
function kenLineEnderP(e: Ent, kit: Kit, b: Brain): boolean {
  const mv = e.f.move, hw = mv && mv.hits.length > 0 ? mv.hits[0] : null, sp = kitCommandMove(kit, 'sp1');
  return !!hw && !!sp && sp.s + 2 < getf(T.reactionFrames, hw.react, 0) && sp.name !== 'ke-meteor-n'
    && !aiSbFinishP(e) && kitCommandOkP(e, 'sp1', kit) && kenRoll(b, KEN_AI_SP1_ENDER);
}

registerHooks({
  /** Kenpachi's reflex (ai.ts aiReflex, free states, before the generic reflexes): a command or null. */
  'ken-ai-reflex'(e: Ent, b: Brain, s: Snap, d: number): string | null {
    kenBankaiGate(e, b);
    return kenAntiBreaker(e, b, s, d) ?? kenAntiMash(e, b, s, d) ?? kenHohoCommit(e, b, s, d) ?? kenNoReset(e, b, d)
      ?? kenSigPunish(e, b, s, d) ?? kenFarPunish(e, b, s, d) ?? kenFirstStrike(e, b, s, d) ?? kenLunge(e, b, s, d)
      ?? kenWalkIn(e, b, s, d);
  },
  /** His spEnder (a landed string's last link, the O ender's own roll failed): the SP1 line ender, the O ender anyway
   *  (not on a red opponent: that already rushes), else Shift+L (the charge into the flurry). */
  'ken-sp-ender'(e: Ent, kit: Kit): string | null {
    const b = aiBrain(e);
    if (!b) return null;
    if (kenLineEnderP(e, kit, b)) return 'sp1';
    if (!kikonReadyP(e) && !aiSbFinishP(e) && kitCommandOkP(e, 'kikon', kit, true) && kenRoll(b, KEN_AI_O_ENDER)) return 'kikon';
    if (kitCommandOkP(e, 'sp2') && kenRoll(b, KEN_AI_SP2_ENDER)) return 'sp2';
    return null;
  },
  /** Frames his CPU holds L: the stance against a J masher through his string (36 f), else as ai.ts holds a stance. */
  'ken-sig-hold'(kit: Kit, _d: number, e?: Ent | null): number {
    const mv = kitCommandMove(kit, 'sig');
    if (!(mv && mv.hold)) return 1;                                    // (the Bankai's bite: a tap)
    const b = e ? aiBrain(e) : null;
    if (b && kenStanceP(kit) && aiMashP(b)) return 36;
    return 12 + Math.floor(simRnd01() * 40);
  },
});
