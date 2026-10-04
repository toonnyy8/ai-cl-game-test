// yama.ts <- duel/lisp/yama.lisp: YAMAMOTO GENRYUSAI SHIGEKUNI's moves (defmove), his four forms (defkit: base = Shikai,
// hellfire = Gokuen, the full Inferno meter for 10 s; the awakening Bankai as two stances, bankai-east (pierce, x1.5
// taken) and bankai-west (the ward)), the hooks they name and the yama-* CPU hooks. Frame data is the §5 table; clip
// names are the art contract. Cinematics are length-only (match.ts CINES).
import { T } from '../sim/tuning';
import { burn, castPoint, secondsToFrames, trackStep } from '../sim/rules';
import { PI, TWO_PI, f32, fwdX, fwdZ, getf, lerp, roundHalfEven } from '../sim/math';
import { defkit, defmove, defmoveCopy, kitCommandMove, makeHitwin, registerHooks, type Kit } from '../sim/kit';
import { W, emit, kitOf, oppOf, simRnd01, type Brain, type Ent, type Snap } from '../sim/types';
import { ahead, kitCommandOkP, moveParam, playClip, rushParam } from '../sim/fighter';
import { addMeter, kikonReadyP } from '../sim/combat';
import { aiAttack, aiBrain, aiSbFinishP, aiTable, why } from '../sim/ai';
import { spawnHand, spawnHazard } from '../sim/hazards';

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

// ================================================================ Hellfire (Gokuen)
defmove('ya-nadegiri', { kind: 'sp', clip: 'ya-nadegiri', callout: 'NADEGIRI', cost: 2,
  startup: 20, active: 4, recovery: 30, dmg: 240, advBlock: -16,
  vol: ['cap', 0.3, 8.0, 1.0, 0.5], onHit: 'knockdown', kb: 3.0, flags: ['ranged'],   // line 8 m: the blade within 2.4 m
  params: { meleeRange: 2.4 } });                                    // (Q1's reach until the J cut), ranged beyond

// ================================================================ Bankai: Zanka no Tachi (docs/DUEL_YAMA_REWORK.md)
// O = North (TENCHI), Shift+L = South (the bind), U = East -> West (guardTo), L = each stance's own technique. In West
// every command but SP1 / L goes back to East first (dropTo / keep).
// ---------------------------------------------------------------- East, Kyokujitsujin: fast thin lines, the pierce
defmove('ya-e-j1', { kind: 'quick', clip: 'ya-q1', clipS: 9, startup: 8, active: 3, recovery: 12, dmg: 34, advBlock: -2,
  vol: ['cap', 0.2, 1.24, 1.1, 0.25], onHit: 'flinch' });          // HIZASHI
defmove('ya-e-j2', { kind: 'quick', clip: 'ya-q2', clipS: 8, startup: 7, active: 3, recovery: 13, dmg: 38, advBlock: -2,
  vol: ['cap', 0.2, 1.24, 1.1, 0.25], onHit: 'flinch' });          // ZANSHO
defmove('ya-e-j3', { kind: 'quick', clip: 'ya-e-thrust', clipS: 11, startup: 8, active: 3, recovery: 18, dmg: 42, advBlock: -4,
  vol: ['cap', 0.2, 1.44, 1.1, 0.3], onHit: 'stagger', flags: ['ender'] });   // SENKO
defmove('ya-e-k1', { kind: 'flash', clip: 'ya-f1', clipS: 18, startup: 16, active: 4, recovery: 20, dmg: 70, advBlock: -3,
  vol: ['cap', 0.2, 3.4, 1.1, 0.3], onHit: 'stagger' });           // KAGERO
defmove('ya-e-k2', { kind: 'flash', clip: 'ya-f2', clipS: 22, enter: 5, startup: 19, active: 4, recovery: 24, dmg: 60, advBlock: -3,
  vol: ['cap', 0.2, 3.4, 1.3, 0.35], onHit: 'stagger' });          // NISSHO
defmove('ya-e-k3', { kind: 'flash', clip: 'ya-e-drop', enter: 7, startup: 21, active: 5, recovery: 34, dmg: 84, advBlock: -20,
  vol: ['cap', 0.3, 3.2, 1.2, 0.3], onHit: 'crumple', flags: ['ender'] });    // RAKUJITSU
defmoveCopy('ya-e-j2s', 'ya-e-j2');
defmoveCopy('ya-e-k2s', 'ya-e-k2');
// L in East: KYOKKO, a lunge whose point runs a 4.6 m line; double pierce; ends a landed string (cancel); cooldown 100
defmove('ya-e-kyokko', { kind: 'sig', clip: 'ya-e-thrust', clipS: 11, callout: 'KYOKKO', startup: 15, active: 3, recovery: 26,
  dmg: 85, advBlock: -12, slide: 1.6, vol: ['cap', 0.2, 4.6, 1.1, 0.3], onHit: 'knockback', kb: 2.0,
  cooldown: 100, flags: ['cancel'], onFrame: [[1, 'yama-kyokko-flare'], [15, 'yama-kyokko']], params: { pierceMult: 2.0 } });
// Shift+K in East: KYOKUJITSUJIN: the blade (f18-19, close) breaks guard; at f20 the heat runs a 25 deg / 9 m cone
defmove('ya-kyoku', { kind: 'sp', clip: 'ya-kyoku', callout: 'KYOKUJITSUJIN', startup: 18, active: 5, recovery: 26,
  dmg: 90, advBlock: -16, vol: ['arc', 9.0, 25, 0.0, 1.6],
  hits: [[18, 20, { vol: ['cap', 0.3, 2.4, 1.0, 0.4], onHit: 'knockback', kb: 0.5, flags: ['guard-crush'] }],   // the blade
         [20, 23, { dmg: 130, onHit: 'knockback', kb: 4.0, flags: ['ranged'] }]],                            // the cone
  onFrame: [[18, 'yama-kyoku-cut'], [20, 'yama-kyoku-sheet']] });
// ---------------------------------------------------------------- West, Zanjitsu Gokui: the ward (passive ward)
// L in West: SHONETSU JIGOKU: a 16 f tell, then a ring of fire pillars where he stands. Cooldown 150
defmove('ya-w-shonetsu', { kind: 'sig', clip: 'ya-shonetsu', clipS: 14, callout: 'SHONETSU JIGOKU', startup: 16, active: 0,
  recovery: 24, cooldown: 150, onFrame: [[0, 'yama-shonetsu-tell'], [16, 'yama-shonetsu']],
  params: { size: 2.0, life: 48, hits: 2, dmg: 45, kb: 2.0, guard: 12 } });
// Shift+K in West: GOKUI GAESHI, a parry (f2-25); a melee hit in it staggers the attacker and starts the counter (land)
defmove('ya-w-parry', { kind: 'sp', clip: 'ya-w-parry', callout: 'GOKUI GAESHI', startup: 2, active: 24, recovery: 20, flags: ['parry'],
  onFrame: [[2, 'yama-parry-up']] });
defmove('ya-w-counter', { kind: 'sig', clip: 'ya-w-counter', startup: 6, active: 3, recovery: 24, dmg: 150, advBlock: -12,
  vol: ['arc', 2.6, 120, 0.0, 2.0], onHit: 'knockback', kb: 3.0 });
// ---------------------------------------------------------------- both: South (Shift+L) and North (O)
// MINAMI, the bind: at f20 the point under the opponent (<= 10 m) is marked; a bind hazard grabs the feet 16 f later
defmove('ya-kaka', { kind: 'sp', clip: 'ya-kaka', callout: 'MINAMI: KAKA JUMANOKUSHI DAISOJIN', cost: 2,
  startup: 20, active: 1, recovery: 34, flags: ['bind'],
  onFrame: [[20, 'yama-south']],
  params: { range: 10.0, radius: 1.2, height: 0.6, delay: 16, dmg: 40, stun: T.bindStun, hands: 4 } });
// O in Bankai, KITA: TENCHI: 10 f of aim, a flash step (36 m/s, <= 14 f), one diagonal cut. Cooldown 90
defmove('ya-tenchi', { kind: 'kikon', clip: 'sh-run', clip2: 'ya-q1', clipS: 9, callout: 'TENCHI KAIJIN', cine: 'yama-tenchi-cine',
  startup: 6, active: 2, recovery: 26, dmg: 70, advBlock: -14, reach: 2.4, arc: 110, onHit: 'knockback', kb: 2.5, cooldown: 90,
  onFrame: [[5, 'yama-tenchi-slash']],
  params: { aura: 10, aim: 120.0, speed: 36.0, dashMax: 14, dashTrack: 0.0, look: 'flash-step', sfx: 'hoho-out' } });

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

defkit('yamamoto', 'hellfire', {
  inherit: 'base',
  callout: 'GOKUEN', mult: T.hellfireMult, duration: T.hellfireSeconds, burn: T.hellfireBurn, blade: ['fire', 1.3],
  enterClips: ['ya-hellfire'], enterHook: 'yama-ennetsu', aura: 'hellfire',
  commands: { sp2: 'ya-nadegiri' },
  ai: { intents: { approach: 1, pressure: 4, zone: 0, defend: 0 },
        ranges: { approach: [3.0, 5.0], pressure: [1.0, 2.6], zone: [6.0, 8.0], defend: [4.0, 7.0] },
        moves: [[0.0, 1.3, 'q', 3, 'f', 2, 'sp2', 2, 'breaker', 1],
                [1.3, 3.0, 'f', 3, 'sp2', 2, 'breaker', 1],
                [3.0, 8.0, 'f', 1, 'sig', 2, 'step', 2],
                [8.0, 99.0, 'sp1', 2, 'step', 2]],
        guard: 0.4, hoho: 0.35, awakenAbove: 0.4, spCancelBars: 1, oEnder: 0.0, dash: 0.5, kikonRange: 9.0,
        spEnder: 'yama-sp-ender', reflex: 'yama-ai-reflex', assistGuard: 'yama-anti-breaker' },
});

defkit('yamamoto', 'bankai-east', {
  inherit: 'base',
  awakening: true, taken: T.bankaiTaken, startupAdd: -1, reachMult: 1.15, guardTo: 'bankai-west', ggRegen: T.eastGgRegen,
  endlessForm: 'bankai-east',                 // ENDLESS: West (inheriting it) stays as East
  blade: ['embers', 1.4], grade: 'spot', passives: ['projectile-cut', 'pierce'], meter: null,
  weapon: 'zanka', aura: 'heat', enterClips: ['ya-bankai'], enterHook: 'yama-bankai-enter', swingSfx: 'whoosh-heavy',
  cine: 'yama-bankai-cine',
  commands: { q: 'ya-e-j1', f: 'ya-e-k1', sig: 'ya-e-kyokko', sp1: 'ya-kyoku', sp2: 'ya-kaka', kikon: 'ya-tenchi' },
  grid: ['ya-e-j1', 'ya-e-j2', 'ya-e-j3', 'ya-e-k1', 'ya-e-k2', 'ya-e-k3', 'ya-e-j2s', 'ya-e-k2s'],
  ai: { intents: { approach: 2, pressure: 4, zone: 1, defend: 0 },
        ranges: { approach: [3.0, 5.0], pressure: [1.0, 3.0], zone: [5.0, 8.0], defend: [4.0, 7.0] },
        moves: [[0.0, 1.6, 'q', 5, 'f', 2, 'breaker', 1, 'sig', 2, 'sp2', 1, null, 1],
                [1.6, 3.0, 'f', 4, 'breaker', 1, 'sig', 2, 'sp2', 1, null, 1],
                [3.0, 6.0, 'f', 1, 'sp1', 2, 'sig', 2, 'step', 1, null, 1],
                [6.0, 99.0, 'sp1', 3, 'step', 1, null, 1]],
        guard: 0.45, hoho: 0.35, awakenAbove: 0.4, spCancelBars: 9, dash: 0.6, dashBack: 0.3, kikonRange: 9.0,
        cancel: { sig: 0.5 }, low: [0.4, { sig: 3 }], ggLow: 0.3, blockString: 0.85, sigGg: 0.6,
        spEnder: 'yama-sp-ender', reflex: 'yama-ai-reflex', assistGuard: 'yama-anti-breaker' },
});

defkit('yamamoto', 'bankai-west', {
  inherit: 'bankai-east',
  taken: 1.0, guardTo: null, dropTo: 'bankai-east', keep: ['sig', 'sp1'], passives: ['ward', 'scorch'],
  blade: ['charcoal'], aura: 'garb',
  enterHook: 'yama-ward-up', exitHook: 'yama-ward-down',
  commands: { sig: 'ya-w-shonetsu', sp1: 'ya-w-parry' },
  strings: [['ya-w-parry', 'land', 'ya-w-counter']],
  ai: { intents: { approach: 2, pressure: 2, zone: 0, defend: 2 },
        ranges: { approach: [2.5, 4.5], pressure: [1.0, 2.5], zone: [3.5, 5.0], defend: [2.5, 4.5] },
        moves: [[0.0, 1.6, 'q', 3, 'f', 2, 'sig', 2, 'breaker', 1, 'sp2', 1, null, 3],
                [1.6, 3.0, 'f', 3, 'sig', 2, 'breaker', 1, 'sp2', 1, null, 3],
                [3.0, 6.0, 'f', 1, 'sp1', 2, 'step', 1, null, 2],
                [6.0, 99.0, 'sp1', 2, 'step', 1, null, 2]],
        guard: 0.3, hoho: 0.3, awakenAbove: 0.4, spCancelBars: 9, dash: 0.4, dashBack: 0.2, kikonRange: 9.0,
        react: { 'flash-startup': 'sp1' }, wardReversal: 0.35,
        spEnder: 'yama-sp-ender', reflex: 'yama-ai-reflex', assistGuard: 'yama-anti-breaker' },
});

// ================================================================ hooks (called through the data's names)
registerHooks({
  /** Signature f40: the flame wave leaves the blade (a hazard 3.5 m wide, 14 m/s, 12 m). */
  'yama-fire-wave'(e: Ent) {
    const [x, z] = ahead(e, 1.0), speed = moveParam(e, 'speed');
    spawnHazard('wave', e, { x, z, yaw: e.yaw, speed, size: f32(0.5 * moveParam(e, 'width')),
      life: roundHalfEven(f32(60 * f32(moveParam(e, 'range') / speed))),
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
    const k = Math.max(0, Math.min(1, f32((f.charge - lo) / (hi - lo))));
    const [x, z] = ahead(e, 0.9), speed = lerp(moveParam(e, 'speedMin'), moveParam(e, 'speedMax'), k);
    spawnHazard('fireball', e, { x, y: 1.2, z, yaw: e.yaw, speed, turn: trackStep(moveParam(e, 'turn')), size: lerp(0.35, 0.6, k),
      life: roundHalfEven(f32(60 * f32(moveParam(e, 'range') / speed))),
      hw: makeHitwin({ dmg: roundHalfEven(lerp(moveParam(e, 'dmgMin'), moveParam(e, 'dmgMax'), k)), react: moveParam(e, 'onHit'),
                       kb: moveParam(e, 'kb'), hs: T.hitstopHeavy, chip: moveParam(e, 'chip'), meter: moveParam(e, 'meter'),
                       guard: roundHalfEven(lerp(moveParam(e, 'guardMin'), moveParam(e, 'guardMax'), k)) }) });
    if (k >= 1) addMeter(e, moveParam(e, 'fullMeter'));
    emit('sfx', 'fire-roar', e);
  },
  /** Hellfire entry: Ennetsu Jigoku, a ring of fire pillars (2 hits max), and it burns Yamamoto too. */
  'yama-ennetsu'(e: Ent) {
    const g = e.g;
    spawnHazard('pillars', e, { x: e.pos[0], z: e.pos[2], size: 3.0, life: secondsToFrames(T.ennetsuSeconds), hits: T.ennetsuHits,
      hw: makeHitwin({ dmg: T.ennetsuDamage, react: 'stagger', kb: 2.0, hs: T.hitstopHeavy, guard: 10 }) });
    g.reishi = burn(g.reishi, T.ennetsuSelfBurn);
    if (e.f.state === 'idle') playClip(e, 'ya-hellfire', { blend: 3 });
    emit('sfx', 'fire-roar', e);
  },
  /** TENCHI: the cut's ring, just before it lands. */
  'yama-tenchi-slash'(e: Ent) { emit('sfx', 'kikon-slash', e); },
  /** Bankai: every fire is drawn into the blade for good (Inferno empties; no more Hellfire). */
  'yama-bankai-enter'(e: Ent) { e.g.meter = 0; },
  /** West's enterHook (U in East): the garb flares on round him. */
  'yama-ward-up'(e: Ent) { emit('nishi', e, e.pos[0], e.pos[2]); emit('sfx', 'heat-flare', e); },
  /** West's exitHook (an attack drops him to East, or a crush / a Guard Break blows the garb off): an ember puff. */
  'yama-ward-down'(e: Ent) { emit('ember', e, e.pos[0], 1.2, e.pos[2], 0.8); emit('sfx', 'sizzle', e); },
  /** KYOKKO f1: the ember edge line flares white-hot (the lunge's tell). */
  'yama-kyokko-flare'(e: Ent) { emit('super', e, 0.2); emit('sfx', 'sizzle', e); },
  /** KYOKKO f15: the ray along the 4.6 m line (a look: the hit is the move's line window). */
  'yama-kyokko'(e: Ent) {
    spawnHazard('line', e, { x: e.pos[0], z: e.pos[2], yaw: e.yaw, size: 4.6, life: 14, look: 'kyokko' });
    emit('sfx', 'kikon-slash', e);
  },
  /** SHONETSU JIGOKU f0: the blade to the ground, the garb flares hard (the tell). */
  'yama-shonetsu-tell'(e: Ent) { emit('flare', e, 0.45); emit('parry-up', e, e.pos[0], e.pos[2]); emit('sfx', 'heat-flare', e); },
  /** SHONETSU JIGOKU f16: the garb erupts: a ring of fire pillars where he stands (blockable), the plaza cracks. */
  'yama-shonetsu'(e: Ent) {
    const [x, z] = [e.pos[0], e.pos[2]];
    spawnHazard('pillars', e, { x, z, size: moveParam(e, 'size'), life: moveParam(e, 'life'), hits: moveParam(e, 'hits'),
      hw: makeHitwin({ dmg: moveParam(e, 'dmg'), react: 'stagger', kb: moveParam(e, 'kb'), hs: T.hitstopHeavy,
                       guard: moveParam(e, 'guard'), chip: T.chipFire }) });
    emit('garb-flare', e, x, z); emit('crack', x, z, 1.5);
    emit('sfx', 'fire-roar', e);
  },
  /** GOKUI GAESHI's window opens: the column of charcoal wisps (a look). */
  'yama-parry-up'(e: Ent) { emit('parry-up', e, e.pos[0], e.pos[2]); },
  /** KYOKUJITSUJIN f18: the charred blade comes straight down (a look). */
  'yama-kyoku-cut'(e: Ent) { emit('kyoku-slit', e, e.pos[0], e.pos[2], fwdX(e.yaw), fwdZ(e.yaw)); emit('sfx', 'kikon-slash', e); },
  /** KYOKUJITSUJIN f20: the sheet of heat runs 9 m ahead (a look: the hit is the move's cone window). */
  'yama-kyoku-sheet'(e: Ent) {
    spawnHazard('line', e, { x: e.pos[0], z: e.pos[2], yaw: e.yaw, size: 9.0, life: 40, look: 'kyoku' });
    emit('sfx', 'heat-flare', e);
  },
  /** MINAMI f20: the point under the opponent (<= range m) is marked; a bind hazard grabs the feet delay frames later
   *  (unguardable, dmg + bound stun frames); hands claw out there. */
  'yama-south'(e: Ent) {
    const p = e.pos, q = oppOf(e).pos, r = moveParam(e, 'radius'), delay = moveParam(e, 'delay');
    const [x, z] = castPoint(p[0], p[2], q[0], q[2], moveParam(e, 'range'));
    // (a hazard's delay counts down in the step it is spawned in: +1 lands the grab exactly delay frames later)
    spawnHazard('bind', e, { x, z, size: r, y: moveParam(e, 'height'), delay: delay + 1, life: 2,
      hw: makeHitwin({ dmg: moveParam(e, 'dmg'), react: 'bind', stun: moveParam(e, 'stun'), hs: T.hitstopHeavy, flags: ['unguardable'] }) });
    spawnHazard('line', e, { x, z, size: r, life: delay + 40, look: 'south' });
    const n = moveParam(e, 'hands');
    for (let i = 0; i < n; i++) {
      const a = i * (TWO_PI / n);
      spawnHand(e, x + 0.7 * r * fwdX(a), z + 0.7 * r * fwdZ(a), a + PI, delay - 8);
    }
    emit('sfx', 'ground-crack', e);
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
