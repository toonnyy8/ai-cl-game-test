// yama.ts <- duel/lisp/yama.lisp, the BASE form (Shikai) only: YAMAMOTO GENRYUSAI SHIGEKUNI's moves (defmove), his base
// kit (defkit) and the hooks it uses. Hellfire (the full Inferno meter) and the Bankai stances are M3: the meter fills
// and stays full, Awaken is refused until those kits are registered. Frame data is the §5 table; clip names are the art
// contract. The kit's ai table is data (M2 ports ai.lisp and the yama-* CPU hooks it names).
import { T } from '../sim/tuning';
import { trackStep } from '../sim/rules';
import { getf, lerp, roundHalfEven } from '../sim/math';
import { defkit, defmove, defmoveCopy, kitCommandMove, makeHitwin, registerHooks, type Kit } from '../sim/kit';
import { W, emit, kitOf, simRnd01, type Brain, type Ent, type Snap } from '../sim/types';
import { ahead, kitCommandOkP, moveParam, rushParam } from '../sim/fighter';
import { addMeter, kikonReadyP } from '../sim/combat';
import { aiAttack, aiBrain, aiSbFinishP, aiTable, why } from '../sim/ai';
import { spawnHazard } from '../sim/hazards';

// ================================================================ shikai (base)
// the J / K strings (docs/DUEL_STRINGS.md §3.1): up to three links, each J or K, switching at most once. J2s / K2s, the
// switched link 2, are copies. Every K at link 2 / 3 enters at S_eff 14 (enter), so it combos after a J and a K link
// alike; the enders stagger / crumple, and their hit opens the O ender. K2 / K3 deal 80 % of the design's numbers.
defmove('ya-j1', { kind: 'quick', clip: 'ya-q1', startup: 9, active: 3, recovery: 12, dmg: 38, advBlock: -2,
  reach: 0.96, arc: 100, onHit: 'flinch' });                        // HISEN: the flat cut from the draw
defmove('ya-j2', { kind: 'quick', clip: 'ya-q2', startup: 8, active: 3, recovery: 13, dmg: 38, advBlock: -2,
  reach: 0.96, arc: 100, onHit: 'flinch' });                        // KAESHIBI: the backhand along the same line
defmove('ya-j3', { kind: 'quick', clip: 'ya-sleeve', startup: 9, active: 3, recovery: 18, dmg: 45, advBlock: -4,
  reach: 0.88, arc: 140, onHit: 'stagger', flags: ['ender'] });     // SODEBI: the burning empty sleeve
defmove('ya-k1', { kind: 'flash', clip: 'ya-f1', startup: 18, active: 4, recovery: 20, dmg: 75, advBlock: -3,
  reach: 2.6, arc: 150, onHit: 'stagger', meter: T.infernoFlash }); // HOMURA-NAGI: the waist-high sweep
defmove('ya-k2', { kind: 'flash', clip: 'ya-f2', enter: 8, startup: 22, active: 4, recovery: 24, dmg: 64, advBlock: -3,
  reach: 2.3, arc: 90, onHit: 'stagger', meter: T.infernoFlash });  // SHOEN: the rising flame column
defmove('ya-k3', { kind: 'flash', clip: 'ya-q3', clipS: 12, enter: 8, startup: 22, active: 5, recovery: 34, dmg: 88, advBlock: -20,
  reach: 2.4, arc: 120, onHit: 'crumple', meter: T.infernoFlash, flags: ['ender'] });   // ENBAKU: the dome at his feet
defmoveCopy('ya-j2s', 'ya-j2');
defmoveCopy('ya-k2s', 'ya-k2');
// two cuts (f16, f28), then the wave hazard leaves the blade at f40 (-6 on block at range)
defmove('ya-sig', { kind: 'sig', clip: 'ya-sig', callout: 'RYUJIN JAKKA',
  startup: 16, active: 25, recovery: 26, dmg: 30, advBlock: -6, reach: 2.6, arc: 110, onHit: 'flinch',
  meter: T.infernoSig, guard: 10,                                   // guard gauge: 10 per cut, the wave 15
  hits: [[16, 19], [28, 31]],
  onFrame: [[40, 'yama-fire-wave']],
  params: { width: 3.5, speed: 14.0, range: 12.0, dmg: 110, onHit: 'knockback', kb: 3.0,
            chip: T.chipFire, meter: T.infernoSig, guard: 15 } });
// hold 12..60 f (charge loop), release -> throw; the fireball leaves at throw frame 2
defmove('ya-shiranui', { kind: 'sp', clip: 'ya-shiranui', clip2: 'ya-shiranui-throw', callout: 'SHIRANUI',
  hold: [12, 60], startup: 2, active: 1, recovery: 20,
  tick: 'yama-shiranui-charge', onFrame: [[2, 'yama-shiranui-throw']],
  params: { dmgMin: 90, dmgMax: 170, speedMin: 10.0, speedMax: 16.0, turn: 60.0, range: 20.0, onHit: 'knockback',
            kb: 3.0, chip: T.chipFire, meter: T.infernoSig, fullMeter: T.infernoMax, guardMin: 10, guardMax: 18 } });
defmove('ya-taimatsu', { kind: 'sp', clip: 'ya-taimatsu', callout: 'TAIMATSU',
  startup: 16, active: 8, recovery: 24, dmg: 120, advBlock: -14,
  vol: ['arc', 4.0, 90, 0.0, 2.2], onHit: 'knockback', kb: 3.5, flags: ['ranged'],   // fire cone 4 m, 90 deg (ranged)
  onFrame: [[16, 'yama-fire-cone']] });
defmove('ya-breaker', { kind: 'breaker', clip: 'ya-breaker', clip2: 'ya-ikkotsu', callout: 'IKKOTSU', planted: true });
// O, the Kikon rush module ENJO (Shikai): no dash. He aims for 6 f, points the blade along a lane and a line of fire walls
// rises along it (f4) and bursts at f20: a melee lane 1 -> 9 m, locked, fire (chip 12 %). A hit with O held: the Kikon,
// Jokaku Enjo, on a red opponent, else the follow-up. Guardable; -14 on block. Cooldown 90.
defmove('ya-kikon', { kind: 'kikon', clip: 'ya-stance', clip2: 'ya-enjo', callout: 'JOKAKU ENJO', cine: 'yama-kikon-cine',
  startup: 20, active: 2, recovery: 30, whiff: 30, dmg: 70, advBlock: -14, track: 0,
  vol: ['cap', 1.0, 9.0, 1.2, 1.4], onHit: 'knockback', kb: 2.0, chip: T.chipFire, cooldown: 90,
  onFrame: [[4, 'yama-enjo-line']],
  params: { aura: 6, aim: 120.0, speed: 0.0, dashMax: 0, dashTrack: 0.0, look: 'lane' } });

// ================================================================ forms
defkit('yamamoto', 'base', {
  name: 'YAMAMOTO', body: 'yamamoto', weapon: 'ryujin-jakka', stance: 'ya-stance',
  intro: 'ya-intro', win: 'ya-win', introCallout: 'BANSHO ISSAI KAIJIN TO NASE', introWeapon: ['ya-cane', 81],
  walk: T.walkYamamoto, run: T.runYamamoto, reishi: T.reishiMax, blade: ['fire', 1.0], swingSfx: 'fire-whoosh',
  stunTolerance: 18.0,                        // the hidden stun: the old man stands a long beating
  commands: { q: 'ya-j1', f: 'ya-k1', sig: 'ya-sig', sp1: 'ya-shiranui', sp2: 'ya-taimatsu',
              breaker: 'ya-breaker', kikon: 'ya-kikon' },
  grid: ['ya-j1', 'ya-j2', 'ya-j3', 'ya-k1', 'ya-k2', 'ya-k3', 'ya-j2s', 'ya-k2s'],
  meter: { name: 'INFERNO', max: T.infernoMax, fullForm: 'hellfire' },
  awakenForm: 'bankai-east',
  ai: { intents: { approach: 1, pressure: 1, zone: 3, defend: 1 },
        ranges: { approach: [3.0, 6.0], pressure: [1.0, 2.6], zone: [7.0, 9.5], defend: [4.0, 7.0] },
        moves: [[0.0, 1.3, 'q', 4, 'f', 1, 'breaker', 1, 'sp2', 1, 'step', 1],   // J up close only, K beyond
                [1.3, 3.0, 'f', 3, 'breaker', 1, 'sp2', 1, 'step', 1],
                [3.0, 5.0, 'f', 1, 'sig', 2, 'step', 2, null, 2],
                [5.0, 7.0, 'sig', 4, 'sp1', 1, 'step', 1, null, 1],
                [7.0, 99.0, 'sp1', 4, 'sig', 2, 'kikon', 1, null, 1]],      // ENJO as a poke from range
        guard: 0.45, hoho: 0.35, awakenAbove: 0.0, spCancelBars: 2, oEnder: 0.0, oki: 'sp1-full', okiAbove: 0.6,
        dash: 0.25, dashBack: 0.5, kikonRange: 9.0,
        spEnder: 'yama-sp-ender', reflex: 'yama-ai-reflex', assistGuard: 'yama-anti-breaker' },
});

// ================================================================ hooks (called through the data's names)
registerHooks({
  /** Signature f40: the flame wave leaves the blade (a hazard 3.5 m wide, 14 m/s, 12 m). */
  'yama-fire-wave'(e: Ent) {
    const [x, z] = ahead(e, 1.0), speed = moveParam(e, 'speed');
    spawnHazard('wave', e, { x, z, yaw: e.yaw, speed, size: 0.5 * moveParam(e, 'width'),
      life: roundHalfEven(60 * (moveParam(e, 'range') / speed)),
      hw: makeHitwin({ dmg: moveParam(e, 'dmg'), react: moveParam(e, 'onHit'), kb: moveParam(e, 'kb'), hs: T.hitstopHeavy,
                       chip: moveParam(e, 'chip'), meter: moveParam(e, 'meter'), guard: moveParam(e, 'guard') }) });
    emit('sfx', 'fire-wave', e);
  },
  /** Taimatsu's first active frame: the great sweep of fire over its cone (a look). */
  'yama-fire-cone'(e: Ent) { emit('fire-cone', e, e.pos[0], e.pos[2], e.yaw); emit('sfx', 'fire-roar', e); },
  /** Shiranui charge tick: the crackle starts with the charge. */
  'yama-shiranui-charge'(e: Ent) { if (e.f.hold === 1) emit('sfx', 'fire-whoosh', e); },
  /** Throw f2: a homing fireball; damage and speed grow with the charge; a full charge fills Inferno. */
  'yama-shiranui-throw'(e: Ent) {
    const f = e.f, [lo, hi] = f.move!.hold!;
    const k = Math.max(0, Math.min(1, (f.charge - lo) / (hi - lo)));
    const [x, z] = ahead(e, 0.9), speed = lerp(moveParam(e, 'speedMin'), moveParam(e, 'speedMax'), k);
    spawnHazard('fireball', e, { x, y: 1.2, z, yaw: e.yaw, speed, turn: trackStep(moveParam(e, 'turn')), size: lerp(0.35, 0.6, k),
      life: roundHalfEven(60 * (moveParam(e, 'range') / speed)),
      hw: makeHitwin({ dmg: roundHalfEven(lerp(moveParam(e, 'dmgMin'), moveParam(e, 'dmgMax'), k)), react: moveParam(e, 'onHit'),
                       kb: moveParam(e, 'kb'), hs: T.hitstopHeavy, chip: moveParam(e, 'chip'), meter: moveParam(e, 'meter'),
                       guard: roundHalfEven(lerp(moveParam(e, 'guardMin'), moveParam(e, 'guardMax'), k)) }) });
    if (k >= 1) addMeter(e, moveParam(e, 'fullMeter'));
    emit('sfx', 'fire-roar', e);
  },
  /** ENJO f4: the line of fire walls starts rising along the locked lane (a look: the hit is the move's). */
  'yama-enjo-line'(e: Ent) {
    spawnHazard('line', e, { x: e.pos[0], z: e.pos[2], yaw: e.yaw, size: 9.0, life: 34, look: 'enjo' });
    emit('sfx', 'fire-roar', e);
  },
});

// ================================================================ the CPU (the kit's ai hooks; ai.ts; docs/DUEL_AI_V2.md)
/** E's CPU's chance from P, a table by difficulty: its brain's; no brain: NORMAL's. */
function yamaDif(e: Ent, p: Record<string, number>): number {
  const b = aiBrain(e);
  return p[b ? b.difficulty : 'normal'] ?? p.normal;
}
/** A Breaker's dash per frame (9.6 m/s): what the delay hides. */
const YAMA_BREAKER_STEP = 0.16;
/** TENCHI from farther out than this is on a red opponent before he sees it within T.aiAntiBreakerRange. */
const YAMA_RUSH_FAR = 5.0;

/** Frames from the O press to his rush's strike at distance D: the aura, the dash (TENCHI 36 m/s; ENJO none), the startup. */
function yamaRushFrames(e: Ent, d: number): number {
  const mv = kitCommandMove(kitOf(e), 'kikon')!, sp = rushParam(mv, 'speed') / 60.0;
  return rushParam(mv, 'aura') + mv.s
    + (rushParam(mv, 'dashMax') > 0 ? Math.min(rushParam(mv, 'dashMax'), Math.ceil(Math.max(0.0, d - mv.reach) / sp)) : 0);
}
/** Does the rush on a red opponent land: TENCHI from beyond YAMA_RUSH_FAR, ENJO beyond its lane's 1 m start, or either
 *  before he is free (a stun or a move's recovery)? */
function yamaRushOkP(e: Ent, b: Brain, s: Snap, d: number): boolean {
  const dash = rushParam(kitCommandMove(kitOf(e), 'kikon')!, 'dashMax') > 0;
  return d >= (dash ? YAMA_RUSH_FAR : 1.5)
    || ((s.state === 'stun' || (s.state === 'move' && s.phase === 'main' && s.sf >= s.activeEnd))
        && s.left - b.delay >= yamaRushFrames(e, d));
}
/** The rush on a red opponent only where it lands. On his stun: J1's follow-up if it is in reach and time, else wait; at
 *  a neutral decision: that decision's attack pick instead. Chance by difficulty; a command or null. */
function yamaRushVeto(e: Ent, b: Brain, s: Snap, d: number): string | null {
  if (kikonReadyP(e) && d < aiTable(e, 'kikonRange', 7.0) && kitCommandOkP(e, 'kikon') && !aiSbFinishP(e) && !yamaRushOkP(e, b, s, d)) {
    const p = yamaDif(e, { easy: 0.0, normal: 0.0, hard: 0.9 }), q = kitCommandMove(kitOf(e), 'q')!;
    if (s.state === 'stun') {
      if (b.reactRoll < p) return d < q.reach + 0.6 && s.left - b.delay >= q.s ? why(b, 'follow-up', 'q') : 'wait';
    } else if (b.decideT <= 1 && (e.f.state === 'idle' || e.f.state === 'run')
               && !['down', 'wakeup', 'hoho', 'air'].includes(s.state) && p > 0 && simRnd01() < p) {
      b.decideT = getf(T.aiThink, b.difficulty, 24) + Math.floor(40 * simRnd01());
      aiAttack(e, b, kitOf(e), s, d, b.heat, false);
    }
  }
  return null;
}
/** J beats I on his own short J: J1 goes when its active frames meet the Breaker (his real distance now: seen, minus what
 *  the dash ran unseen), its strike not out before J1's. */
function yamaAntiBreaker(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const q = kitCommandMove(kitOf(e), 'q');
  if (q && s.kind === 'breaker' && (s.phase === 'aura' || s.phase === 'dash') && kitCommandOkP(e, 'q')) {
    const el = W.tick - s.start, dash = s.phase === 'dash';            // real frames since the phase we see began
    const aura = dash ? 0 : Math.max(0, T.breakerAura - el);           // its aura left
    const ran = dash ? Math.min(el, b.delay) : Math.max(0, el - T.breakerAura);   // his dash since what we see
    const x = d - ran * YAMA_BREAKER_STEP;                              // his real distance now
    const inn = aura + Math.max(0.0, x - q.reach - 0.3) / YAMA_BREAKER_STEP;   // frames till J1 reaches him
    const strike = aura + Math.max(0.0, x - T.breakerTrigger) / YAMA_BREAKER_STEP + T.breakerStartup;
    if (inn <= q.s + q.a - 2 && q.s + 1 < strike && b.reactRoll < yamaDif(e, { easy: 0.0, normal: 0.0, hard: 0.85 }))
      return why(b, 'anti-breaker', 'q');
  }
  return null;
}
/** A stunned opponent beyond J1's follow-up reach but in the fire's: the form's paid SP if it lands before he is free. */
function yamaStunSp(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const kit = kitOf(e), q = kitCommandMove(kit, 'q');
  const sp = kit.form === 'bankai-east' ? 'sp1' : kit.form === 'base' || kit.form === 'hellfire' ? 'sp2' : null;
  const mv = sp ? kitCommandMove(kit, sp) : null;
  if (sp && mv && q && s.state === 'stun'
      && (d > q.reach + 0.6 || (sp === 'sp1' && Math.floor(e.g.reiatsu / T.reiatsuBar) >= 2)) && d < (sp === 'sp1' ? 6.0 : 3.8)
      && kitCommandOkP(e, sp) && s.left - b.delay >= mv.s + (sp === 'sp1' ? 8 : 2)
      && b.reactRoll < yamaDif(e, { easy: 0.0, normal: 0.0, hard: 0.7 }))
    return why(b, 'stun-sp', sp);
  return null;
}

registerHooks({
  /** Every form's reflex (ai.ts aiReflex, free states, before the generic answers). */
  'yama-ai-reflex'(e: Ent, b: Brain, s: Snap, d: number): string | null {
    return yamaAntiBreaker(e, b, s, d) ?? yamaStunSp(e, b, s, d) ?? yamaRushVeto(e, b, s, d);
  },
  /** Every form's spEnder: confirm the pushed victim with the paid SP when its bars are there, else the O ender (never
   *  ENJO off a J3: no dash, he guards it). Chance by difficulty; a command or null. */
  'yama-sp-ender'(e: Ent, kit: Kit): string | null {
    const sp = kit.form === 'base' || kit.form === 'hellfire' ? 'sp2' : kit.form === 'bankai-east' ? 'sp1' : null;
    const mv = e.f.move!, o = kitCommandMove(kit, 'kikon');
    if (sp && kitCommandOkP(e, sp, kit) && simRnd01() < yamaDif(e, { easy: 0.1, normal: 0.3, hard: 0.95 })) return sp;
    if (o && kitCommandOkP(e, 'kikon', kit, true) && !aiSbFinishP(e)
        && !(mv.kind === 'quick' && rushParam(o, 'dashMax') === 0)          // (ENJO off J3)
        && simRnd01() < yamaDif(e, { easy: 0.05, normal: 0.15, hard: 0.85 })) return 'kikon';
    return null;
  },
});
