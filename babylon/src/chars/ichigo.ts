// ichigo.ts <- duel/lisp/ichigo.lisp: KUROSAKI ICHIGO (TYBW, docs/DUEL_ICHIGO.md v2): his moves (defmove), his two forms
// (defkit: base, the dual-blade Shikai with the stance TSUKIMACHI; kessa, KESSA NO ICHIGO with the parry, the clones, the
// O charge and ZANZO) and their hooks. Most of his mechanics run in his tick hook (after the hits of the step): the
// stance's follow-ups, the parry from blockstun, the clones' answers (a J / K press edge), the Hoho clone, the O charge,
// the afterimages. Clip names are the art contract; cinematics are length-only (match.ts CINES).
// ponytail: the pacing log (ic-acc-*), the HUD's clone row / deck, the parry's rim and the practice EARLY / LATE judge,
// and the debug commands (ICHIGO-DEBUG) are presentation / debug: not ported.
import { T, f32Deep } from '../sim/tuning';
import { angleWrap, fwdX, fwdZ, getf, len32, mod, roundHalfEven, turnToward } from '../sim/math';
import { STEP } from '../sim/time';
import { volHitP } from '../sim/hitvol';
import {
  chainOpenP, clampToCircle, contactOf, dirYaw, hohoAllowedP, redP, stepDirection, towardStrafeDir, trackStep, type Contact,
} from '../sim/rules';
import {
  defkit, defmove, defmoveCopy, findMove, kitCommandMove, kitNext, makeHitwin, mvTotal, registerHooks, type HitWin, type Kit, type Move,
  type StringRow,
} from '../sim/kit';
import { W, clog, emit, kitOf, oppOf, sideName, simRnd01, type Brain, type Ent, type Fighter, type Hazard, type Snap } from '../sim/types';
import {
  ahead, guardLockedNowP, kitCommandOkP, moveParam, setSlide, spendFs, startMove, stickRelative, turnToOpp,
} from '../sim/fighter';
import { burstOkP, kikonReadyP } from '../sim/combat';
import { aiAttack, aiBrain, aiGuardK, aiMashP, aiPress, aiSbFinishP, why } from '../sim/ai';
import { hazardTarget, hazardTouchesP, spawnHazard } from '../sim/hazards';
import type { Action, Vpad } from '../sim/vpad';

// ================================================================ knobs (ichigo.lisp's own defparameters)
export const IC = f32Deep({
  walkIchigo: 4.2, runIchigo: 10.0, walkKessa: 3.6, runKessa: 9.0,
  ichigoMult: 1.0, ichigoTaken: 0.8, kessaMult: 0.95, kessaTaken: 1.0,
  tsukiUp: 6, tsukiTap: 30, tsukiMax: 60, tsukiDashFs: 10.0,           // the Shikai's stance
  kessaParryCost: 10.0, kessaParryCatch: 20.0, kessaParryStun: 40,     // KESSA's parry
  cloneMax: 3, cloneLife: 300, cloneCost: 15.0, cloneLag: 6, cloneScale: 0.7, cloneBurstDmg: 30,
  cloneKonpaku: [2, 2, 3, 4],
  zanzoLife: 360, zanzoLag: 10, zanzoMult: 0.5,                        // SP2 ZANZO
  aiIcLAfterK: 0.3, aiIcParryP: 0.35, aiIcParryBsP: 0.3, aiKessaOP: 0.04, aiKessaBankAt: 0.45, aiKessaCloneJP: 0.08,
});
const f32 = Math.fround;

// ================================================================ 二刀の斬月 (base)
// J is the short blade (fast, short), K the long cleaver; a switched link 2 is the CROSS (the same frames, a heavier guard)
defmove('ic-j1', { kind: 'quick', clip: 'ic-q1', startup: 7, active: 3, recovery: 12, dmg: 32, advBlock: -2, guard: 8,
  reach: 1.1, arc: 100, onHit: 'flinch', slide: 0.6 });               // KOKIBA
defmove('ic-j2', { kind: 'quick', clip: 'ic-q2', startup: 7, active: 3, recovery: 13, dmg: 32, advBlock: -2, guard: 8,
  reach: 1.1, arc: 100, onHit: 'flinch' });                           // KAESHI
defmove('ic-j3', { kind: 'quick', clip: 'ic-spin', startup: 8, active: 3, recovery: 18, dmg: 40, advBlock: -4, guard: 8,
  reach: 1.44, arc: 200, onHit: 'stagger', flags: ['ender'] });        // SOSEN-GIRI
defmove('ic-k1', { kind: 'flash', clip: 'ic-f1', startup: 16, active: 4, recovery: 20, dmg: 68, advBlock: -3, guard: 16,
  reach: 2.7, arc: 150, onHit: 'stagger' });                          // OKIBA
defmove('ic-k2', { kind: 'flash', clip: 'ic-f2', enter: 6, startup: 20, active: 4, recovery: 24, dmg: 60, advBlock: -3, guard: 16,
  reach: 2.7, arc: 90, onHit: 'stagger' });                           // SHOGA
defmove('ic-k3', { kind: 'flash', clip: 'ic-drop', enter: 7, startup: 21, active: 5, recovery: 34, dmg: 84, advBlock: -20, guard: 22,
  vol: ['cap', 0.3, 3.0, 1.2, 0.35], onHit: 'crumple', flags: ['ender'] });   // RAKUGA
defmoveCopy('ic-j2s', 'ic-j2', { clip: 'ic-cross-j', clipS: 7, guard: 12 });   // KAESHI-KIBA
defmoveCopy('ic-k2s', 'ic-k2', { clip: 'ic-cross', clipS: 14, guard: 24 });    // KOGA
// GETSUGA TENSHO (the stance's L branch): at f14 a crescent :wave 2.4 m wide, 16 m/s over 10 m
defmove('ic-getsuga', { kind: 'sig', clip: 'ic-getsuga', callout: 'GETSUGA TENSHO', startup: 14, active: 0, recovery: 34,
  reach: 10.0, onFrame: [[14, 'ichigo-getsuga']],
  params: { width: 2.4, speed: 16.0, range: 10.0, dmg: 90, react: 'knockback', kb: 2.5, guard: 18, look: 'ichigo-getsuga-look' } });
// L, 月待 TSUKIMACHI: up at f6, held 30 f (60 while L is held), R 14; the follow-ups are its non-button strings
defmove('ic-tsuki', { kind: 'sig', clip: 'ic-tsuki', startup: 6, active: 0, recovery: 74, track: 360.0 });
defmoveCopy('ic-tsuki-k2', 'ic-tsuki', { enter: 4 });
defmoveCopy('ic-tsuki-re', 'ic-tsuki', { enter: 6 });
defmove('ic-tsuki-j', { kind: 'sig', clip: 'ic-rangetsu', callout: 'RANGETSU', startup: 8, active: 12, recovery: 18, dmg: 18,
  advBlock: -6, guard: 5, reach: 2.4, arc: 120, slide: 2.4, hs: T.hitstopLight,
  hits: [[8, 9], [11, 12], [14, 15], [17, 20, { onHit: 'stagger' }]] });   // 乱月 RANGETSU
defmove('ic-tsuki-k', { kind: 'sig', clip: 'ic-tsuki-otoshi', callout: 'TSUKI-OTOSHI', startup: 18, active: 4, recovery: 30, dmg: 100,
  advBlock: -10, guard: 30, reach: 2.6, arc: 100, slide: 4.0, onHit: 'crumple' });   // 月落
defmoveCopy('ic-tsuki-l', 'ic-getsuga', { startup: 8, clipS: 14, onFrame: [[8, 'ichigo-getsuga']] });
defmove('ic-tsuki-dash', { kind: 'sig', clip: 'ic-tsuki', startup: 12, active: 0, recovery: 0,
  onFrame: [[0, 'ichigo-tsuki-dash'], [11, 'ichigo-tsuki-return']] });   // 月渡 TSUKIWATARI
// Shift+K, GETSUGA JUJISHO: the cross wave (f20) CUTS every opponent wave / fireball it meets (ichigoCut)
defmove('ic-juji', { kind: 'sp', clip: 'ic-juji', callout: 'GETSUGA JUJISHO', startup: 20, active: 0, recovery: 26, reach: 12.0,
  onFrame: [[12, 'ichigo-juji-first'], [20, 'ichigo-juji']],
  params: { width: 3.6, speed: 14.0, range: 12.0, dmg: 150, react: 'knockdown', kb: 2.0, guard: 22, look: 'ichigo-juji-look' } });
// Shift+L, SOGA: a flash-step lunge (5 m), then the X of both blades
defmove('ic-soga', { kind: 'sp', clip: 'ic-cross', clipS: 7, callout: 'SOGA', startup: 18, active: 4, recovery: 26, dmg: 130, advBlock: -14,
  guard: 30, slide: 5.0, reach: 2.6, arc: 140, onHit: 'knockback', kb: 2.5, onFrame: [[0, 'ichigo-soga-vanish']] });
defmove('ic-breaker', { kind: 'breaker', clip: 'ic-breaker', clip2: 'ic-mine', callout: 'MINEUCHI' });
// O, the Kikon rush module JUJI: 6 f of aura, a flash step at 30 m/s for <= 14 f, the X strike. Cooldown 90
defmove('ic-kikon', { kind: 'kikon', clip: 'sh-run', clip2: 'ic-cross', clipS: 7, callout: 'GETSUGA TENSHO', cine: 'ic-kikon-cine',
  startup: 7, active: 3, recovery: 24, dmg: 70, advBlock: -14, reach: 2.6, arc: 140, onHit: 'knockback', kb: 2.5, cooldown: 90,
  params: { aura: 6, aim: 120.0, speed: 30.0, dashMax: 14, dashTrack: 0.0, look: 'flash-step', sfx: 'hoho-out' } });

// ================================================================ 血鎖の一護 KESSA NO ICHIGO (the awakening)
defmove('ic-k-j1', { kind: 'quick', clip: 'ic-k-jab', startup: 8, active: 3, recovery: 12, dmg: 30, advBlock: -2, guard: 8,
  reach: 1.56, arc: 110, onHit: 'flinch' });                          // 板薙 ITA-NAGI
defmove('ic-k-j2', { kind: 'quick', clip: 'ic-k-back', startup: 8, active: 3, recovery: 13, dmg: 30, advBlock: -2, guard: 8,
  reach: 1.56, arc: 110, onHit: 'flinch' });                          // 返板 KAESHI-ITA
defmove('ic-k-j3', { kind: 'quick', clip: 'ic-k-wrap-j', clipS: 10, startup: 9, active: 3, recovery: 18, dmg: 40, advBlock: -4, guard: 8,
  reach: 1.68, arc: 200, onHit: 'stagger', flags: ['ender'] });        // 板旋 ITA-SEN
defmove('ic-k-k1', { kind: 'flash', clip: 'ic-f1', clipS: 16, startup: 18, active: 4, recovery: 20, dmg: 66, advBlock: -3, guard: 14,
  reach: 2.9, arc: 150, onHit: 'stagger' });                          // 大板 OITA
defmove('ic-k-k2', { kind: 'flash', clip: 'ic-f2', clipS: 20, enter: 6, startup: 20, active: 4, recovery: 24, dmg: 58, advBlock: -3,
  guard: 14, reach: 2.9, arc: 90, onHit: 'stagger' });                // 昇板 SHO-ITA
defmove('ic-k-k3', { kind: 'flash', clip: 'ic-drop', clipS: 21, enter: 7, startup: 21, active: 5, recovery: 34, dmg: 80, advBlock: -20,
  guard: 20, vol: ['cap', 0.3, 3.2, 1.2, 0.35], onHit: 'crumple', flags: ['ender'] });   // 天鎖落 TENSA-OTOSHI
defmoveCopy('ic-k-j2s', 'ic-k-j2');                                   // one blade: no cross links
defmoveCopy('ic-k-k2s', 'ic-k-k2');
// the clones' answers (not a kit's: ichigoCloneStep plays them): J a heavy, K a light (the user's reversal)
defmove('ic-c-heavy', { kind: 'flash', clip: 'ic-f1', clipS: 16, startup: 16, active: 4, recovery: 20, dmg: 50, guard: 12,
  reach: 3.0, arc: 150, onHit: 'stagger' });                          // 影断 KAGE-DACHI
defmove('ic-c-heavy3', { kind: 'flash', clip: 'ic-drop', clipS: 21, startup: 18, active: 5, recovery: 30, dmg: 60, guard: 14,
  vol: ['cap', 0.3, 3.4, 1.2, 0.35], onHit: 'crumple' });
defmove('ic-c-light', { kind: 'quick', clip: 'ic-k-cut', startup: 8, active: 3, recovery: 12, dmg: 26, guard: 6,
  reach: 2.4, arc: 110, onHit: 'flinch' });                           // 影薙 KAGE-NAGI
defmove('ic-c-light3', { kind: 'quick', clip: 'ic-k-wrap', startup: 9, active: 3, recovery: 18, dmg: 32, guard: 6,
  reach: 2.8, arc: 200, onHit: 'stagger' });
// L, 鎖盾 KUSARI-TATE, the parry: its own window f2-25 (params.window), 10 guard gauge on frame 0, from blockstun too
defmove('ic-k-parry', { kind: 'sig', clip: 'ic-k-parry', startup: 2, active: 24, recovery: 18, flags: ['parry'],
  params: { window: [2, 25] }, onFrame: [[0, 'ichigo-parry-open']] });
// 残月返し ZANGETSU-GAESHI: the catch's counter: a pull to 1.6 m, a top-down cut, a crumple
defmove('ic-k-gaeshi', { kind: 'sig', clip: 'ic-drop', clipS: 21, callout: 'KUSARI-TATE', startup: 6, active: 3, recovery: 22, dmg: 80,
  advBlock: -12, guard: 14, reach: 3.0, arc: 100, onHit: 'crumple', onFrame: [[0, 'ichigo-gaeshi-pull']], params: { pull: 1.6 } });
// Shift+K, KUSARI-BIKI: a chain shot to 7 m (the blade within 3.8 m, the chain beyond: ranged), a hit pulls him to 1.6 m
// and binds him 40 f
defmove('ic-k-hiki', { kind: 'sp', clip: 'ic-k-yank', clipS: 6, callout: 'KUSARI-BIKI', startup: 16, active: 3, recovery: 24, dmg: 40,
  advBlock: -14, vol: ['cap', 0.5, 7.0, 1.1, 0.3], flags: ['ranged'], onHit: 'bind', hits: [[16, 19, { stun: 40 }]],
  onLand: 'ichigo-pull', params: { meleeRange: 3.8, pull: 1.6 } });
// Shift+L, 残像 ZANZO: for IC.zanzoLife every attack of his is echoed IC.zanzoLag f later at IC.zanzoMult
defmove('ic-k-zanzo', { kind: 'sp', clip: 'ic-k-zanzo', callout: 'ZANZO', startup: 12, active: 0, recovery: 16,
  onFrame: [[12, 'ichigo-zanzo-on']] });
// O, 影討 KAGE-UCHI: every live clone at the press charges and bursts on the strike's frame (+30 each); its Kikon 千影
// is worth 2 / 2 / 3 / 4 Konpaku by those clones. Cooldown 90
defmove('ic-k-kikon', { kind: 'kikon', clip: 'sh-run', clip2: 'ic-drop', clipS: 21, callout: 'KAGE-UCHI', cine: 'ic-kessa-kikon-cine',
  startup: 7, active: 3, recovery: 24, dmg: 70, advBlock: -14, guard: 20, reach: 2.8, arc: 120, onHit: 'knockback', kb: 2.5,
  cooldown: 90, params: { aura: 6, aim: 120.0, speed: 30.0, dashMax: 14, dashTrack: 0.0, look: 'flash-step', sfx: 'hoho-out' } });

// ================================================================ forms
/** The stance's follow-ups: non-button strings (kitNext) the tick hook starts (tsukiStep). */
const TSUKI_STRINGS: StringRow[] = [
  ...['ic-tsuki', 'ic-tsuki-k2', 'ic-tsuki-re'].flatMap((s): StringRow[] =>
    [[s, 'tsuki-j', 'ic-tsuki-j'], [s, 'tsuki-k', 'ic-tsuki-k'], [s, 'tsuki-l', 'ic-tsuki-l'], [s, 'tsuki-step', 'ic-tsuki-dash']]),
  ['ic-tsuki-dash', 'tsuki-back', 'ic-tsuki-re'],
];
const ICHIGO_HOOKS = { tick: 'ichigo-tick', hit: 'ichigo-hit', struck: 'ichigo-struck' };
const KESSA_HOOKS = { tick: 'ichigo-tick', step: 'ichigo-step-clone', ok: 'ichigo-ok', parried: 'ichigo-catch', hit: 'ichigo-hit',
  struck: 'ichigo-struck', deck: 'ichigo-deck', 'soul-break-cine': 'ic-kessa-getsuga-cine', 'kikon-worth': 'ichigo-kikon-worth' };

defkit('ichigo', 'base', {
  name: 'ICHIGO', body: 'ichigo', weapon: 'zangetsu-long', stance: 'ic-stance', hide: ['kessa', 'mark'],
  intro: 'ic-intro', win: 'ic-win', introCallout: 'ZANGETSU',
  walk: IC.walkIchigo, run: IC.runIchigo, reishi: T.reishiMax, swingSfx: 'whoosh-heavy', mult: IC.ichigoMult, taken: IC.ichigoTaken,
  stunTolerance: 16.0,                          // the hidden stun: the middle (KESSA inherits it)
  commands: { q: 'ic-j1', f: 'ic-k1', sig: 'ic-tsuki', sp1: 'ic-juji', sp2: 'ic-soga', breaker: 'ic-breaker', kikon: 'ic-kikon' },
  grid: ['ic-j1', 'ic-j2', 'ic-j3', 'ic-k1', 'ic-k2', 'ic-k3', 'ic-j2s', 'ic-k2s'],
  strings: TSUKI_STRINGS,
  lAfterK: 'ic-tsuki-k2',                       // L after K1 / K2 / K3: the stance at f4
  awakenForm: 'kessa', aura: 'ichigo-aura-base',
  hooks: ICHIGO_HOOKS,
  // rushdown: J pressure up close, the cleaver's K links into a guard, the stance and SOGA in the middle (the stance's
  // branch: ichigoAiStance), JUJISHO against a projectile; he awakens once he has taken 150
  ai: { intents: { approach: 2, pressure: 4, zone: 0, defend: 1 },
        ranges: { approach: [2.6, 5.0], pressure: [1.0, 1.8], zone: [5.0, 7.0], defend: [3.0, 5.0] },
        moves: [[0.0, 1.6, 'q', 5, 'f', 2, 'breaker', 1, 'sp2', 1, 'sig', 1],
                [1.6, 2.6, 'f', 4, 'sig', 2, 'breaker', 1, 'sp2', 1],
                [2.6, 5.0, 'sig', 4, 'sp2', 2, 'f', 1, 'step', 1],
                [5.0, 9.0, 'sp2', 2, 'sig', 2, 'sp1', 1, 'kikon', 1],
                [9.0, 99.0, 'sp1', 2, 'kikon', 1, null, 1]],
        guard: 0.4, hoho: 0.3, dash: 0.8, dashBack: 0.1, blockString: 0.8, lAfterK: IC.aiIcLAfterK, spCancelBars: 1,
        kikonRange: 8.6, react: { projectile: 'sp1' }, awaken: { minTaken: 150 },
        reflex: 'ichigo-ai-shikai', assistGuard: 'ichigo-assist-guard', spEnder: 'ichigo-ai-ender' },
});

// KESSA NO ICHIGO: permanent, no heal, Kikon 3 (O: 2-4 by the clones). A normal guard; L the parry (and from blockstun);
// a clone on a Step (the step hook) and a Hoho; the clones' answers, the O charge and the afterimages in his tick hook
defkit('ichigo', 'kessa', {
  inherit: 'base',
  awakening: true, formName: 'KESSA', walk: IC.walkKessa, run: IC.runKessa, mult: IC.kessaMult, taken: IC.kessaTaken,
  weapon: 'tensa', hide: ['shikai', 'mark'], stance: 'ic-k-stance', aura: 'ichigo-aura-kessa', cine: 'ic-kessa-cine',
  passives: ['parry-block'],
  hooks: KESSA_HOOKS,
  meter: { name: 'BUNSHIN', max: 3, draw: 'ichigo-hud-meter', label: 'ichigo-hud-label' },   // the clones' row (the gauge unused)
  commands: { q: 'ic-k-j1', f: 'ic-k-k1', sig: 'ic-k-parry', sp1: 'ic-k-hiki', sp2: 'ic-k-zanzo', kikon: 'ic-k-kikon' },
  grid: ['ic-k-j1', 'ic-k-j2', 'ic-k-j3', 'ic-k-k1', 'ic-k-k2', 'ic-k-k3', 'ic-k-j2s', 'ic-k-k2s'],
  strings: [['ic-k-parry', 'land', 'ic-k-gaeshi']],
  lAfterK: null,
  // a mid-close brawler with posts: every back hop and Hoho posts a clone; the parry and O by the clones in its reflex
  // (ichigoAiKessa), from blockstun in the tick hook
  ai: { intents: { approach: 3, pressure: 4, zone: 0, defend: 1 },
        ranges: { approach: [2.6, 6.0], pressure: [1.0, 2.0], zone: [3.0, 4.0], defend: [3.5, 5.5] },
        moves: [[0.0, 1.8, 'q', 5, 'f', 3, 'breaker', 1, 'step', 1],
                [1.8, 2.8, 'f', 5, 'breaker', 1, 'step', 1],
                [2.8, 5.0, 'f', 2, 'step', 1, 'hoho', 1, 'sp2', 1, 'q', 1],
                [5.0, 9.0, 'sp1', 2, 'hoho', 2, 'kikon', 1, 'step', 1],
                [9.0, 99.0, 'kikon', 1, 'hoho', 2, null, 1]],
        guard: 0.4, hoho: 0.4, dash: 0.6, dashBack: 0.2, oEnder: 0.6, attack: 0.15, lAfterK: 0.0, spCancelBars: 9,
        kikonRange: 8.6, stunFollow: ['sp1', 3.8, 7.0], reflex: 'ichigo-ai-kessa', assistGuard: 'ichigo-assist-guard',
        spEnder: 'ichigo-ai-ender' },
});

// ================================================================ pure rules (test/ichigo.test.ts)
/** The Kikon's Konpaku with N clones at the O press. */
export const cloneKonpaku = (n: number): number => IC.cloneKonpaku[Math.max(0, Math.min(3, n))];
/** The clone's move for the answer WEIGHT (q a J press: the heavy; f a K press: the light) at LINK (3: the ender's). */
export const cloneMove = (weight: string, link: number): Move =>
  findMove(weight === 'q' ? (link === 3 ? 'ic-c-heavy3' : 'ic-c-heavy') : link === 3 ? 'ic-c-light3' : 'ic-c-light');
/** Frames from the press to a clone's link-1 hit. */
export const cloneHitFrame = (weight: string): number => IC.cloneLag + cloneMove(weight, 1).s;
/** A clone's string ended: 'fade' when it touched him (hit or block) or its time is up, else 'idle' (a whiff keeps it). */
export const cloneAfterString = (touched: boolean, life: number): 'fade' | 'idle' => (touched || life <= 0 ? 'fade' : 'idle');
/** Does a hit on Ichigo with result RES clear his clones (a real hit, not a block)? */
export const cloneVanishP = (res: Contact | null): boolean => contactOf(res) === 'hit';
/** Making one more clone with live clones born at BORNS: the index of the one to replace (the oldest) at the cap. */
export const cloneEvict = (borns: number[]): number | null =>
  borns.length >= IC.cloneMax ? borns.indexOf(Math.min(...borns)) : null;
/** A copy of hit HW at MULT of its damage and guard value, with a blade's hit look (a clone's or an echo's). The Lisp
 *  multiplies in single floats: a x.5 product rounds half-even after the f32 rounding. */
export function echoHitwin(hw: HitWin, mult: number): HitWin {
  return { ...hw, dmg: Math.max(1, roundHalfEven(f32(f32(mult) * hw.dmg))), guard: hw.guard == null ? null : f32(f32(mult) * hw.guard),
           flags: hw.flags.includes('blade') ? hw.flags : ['blade', ...hw.flags] };
}
/** The frames (from his move's frame 0) an echo of MV hits on. */
export const echoHitFrames = (mv: Move): number[] => mv.hits.map((w) => IC.zanzoLag + w.from);

// ================================================================ per-side state (a new fighter entity = a fresh one)
class Ics {
  hohoDone = false; dashed = false; oLive = false;
  seen: Move | null = null; seenMain = false;    // the move the afterimage watch last saw start
  hist = new Array<number>(48).fill(0); histI = 0;   // his last 16 (x z yaw): the echoes replay them
  parrySf = -1;
  bsKey = -1; bsAt = -1;                         // the CPU's parry from blockstun: which blockstun, pressed on which frame
  oAt = -9999; oN = 0;                           // the last O press and its clones (the HUD's flash)
}
const ICS = new WeakMap<Ent, Ics>();
function ic(e: Ent): Ics {
  let st = ICS.get(e);
  if (!st) { st = new Ics(); ICS.set(e, st); }
  return st;
}

/** Hazard data: a clone (Icc), an afterimage (Ice); their hits are 'ic-hit' hazards whose data is the clone / 'echo'. */
export class Icc {
  state: 'idle' | 'answer' | 'charge' | 'fade' = 'idle';
  born = 0; life = 0; fade = 0; src: string;
  link = 0; mv: Move | null = null; sf = 0; queued: string[] = [];   // (the presses waiting for its next links)
  hit: 'hit' | 'block' | null = null;           // this link's own contact
  touched = false;                               // any link of this string touched him: the carried gate
  constructor(born: number, life: number, src: string) { this.born = born; this.life = life; this.src = src; }
}
class Ice { constructor(public mv: Move, public sf: number, public end: number) {} }

// ================================================================ helpers
/** E spends N of the guard gauge (the regen waits again; never guardless by it). */
function ggSpend(e: Ent, n: number): void { const g = e.g; g.gg = f32(Math.max(0.0, g.gg - n)); g.ggIdle = 0; }

/** A look-only hazard (kind fx): no hit, no sim effect but its slot. */
function ichigoLook(e: Ent, look: string, x: number, z: number, o: { yaw?: number; size?: number; life?: number; delay?: number } = {}): Hazard {
  return spawnHazard('fx', e, { x, z, yaw: o.yaw ?? 0, size: o.size ?? 1.0, life: o.life ?? 30, delay: o.delay ?? 0, look });
}

/** The chain drags ATT's opponent toward him to D metres over FRAMES (after the hit's own reaction: its slide replaced). */
function ichigoPullTo(att: Ent, d: number, frames: number): void {
  const v = oppOf(att), p = att.pos, q = v.pos, dx = f32(p[0] - q[0]), dz = f32(p[2] - q[2]), dist = len32(dx, dz);
  if (dist > d) {
    setSlide(v, f32(dist - d), frames, dx, dz);
    emit('sfx', 'chain-snap', att);
  }
}

/** A crescent wave from the move's params (width speed range dmg react kb guard), AHEAD m in front of E. */
function ichigoWave(e: Ent, look: string, aheadM = 1.0, yaw = e.yaw): void {
  const speed = moveParam(e, 'speed') as number, [x, z] = ahead(e, aheadM);
  spawnHazard('wave', e, { x, z, yaw, speed, size: f32(0.5 * moveParam(e, 'width')), life: roundHalfEven(f32(60 * f32(moveParam(e, 'range') / speed))),
    look, hw: makeHitwin({ dmg: moveParam(e, 'dmg'), react: moveParam(e, 'react'), kb: moveParam(e, 'kb'), hs: T.hitstopHeavy,
                           guard: moveParam(e, 'guard'), flags: ['blade'] }) });
}

/** JUJISHO's cross wave CUTS every opponent wave / fireball it touches. */
function ichigoCut(e: Ent): void {
  for (const hz of W.hazards) {
    if (!(hz.alive && hz.owner === e && hz.look === 'ichigo-juji-look' && hz.delay <= 0 && hz.age < hz.life)) continue;
    for (const oz of W.hazards) {
      if (oz.alive && oz.owner !== e && (oz.kind === 'wave' || oz.kind === 'fireball') && oz.delay <= 0
          && hazardTouchesP(hz, oz.x, 0, oz.z, Math.max(0.5, oz.size), 1.8)) {
        emit('hazard-cut', oz.x, 1.0 + oz.y, oz.z);
        clog(() => `${sideName(e)} cuts ${oz.kind}`);
        oz.alive = false;
      }
    }
  }
}

// ================================================================ the Shikai's stance
/** The stance's follow-up a human pressed (buffered, unmodified), or null. */
function tsukiPressed(vp: Vpad): string | null {
  return vp.commandPressedP('quick', false) ? 'tsuki-j' : vp.commandPressedP('flash', false) ? 'tsuki-k'
    : vp.commandPressedP('sig', false) ? 'tsuki-l' : vp.commandPressedP('step', false) ? 'tsuki-step' : null;
}
const TSUKI_BUTTON: Record<string, Action> = { 'tsuki-j': 'quick', 'tsuki-k': 'flash', 'tsuki-l': 'sig', 'tsuki-step': 'step' };

/** One step of the stance (MV): it re-aims at him; from f6 the first J / K / L / Step fires its branch (a CPU's is picked
 *  once at f6: ichigoAiStance); the Step branch needs its flash step, once per stance; past the hold (30 f, 60 while L is
 *  held) the stance recovers (R 14). */
function tsukiStep(e: Ent, f: Fighter, st: Ics, mv: Move): void {
  const sf = f.sf, vp = e.pilot.vpad, b = e.brain;
  turnToOpp(e, f, trackStep(360.0));
  if (sf >= IC.tsukiUp) {
    const cmd = b ? (sf === IC.tsukiUp ? ichigoAiStance(e, f, st) : null) : tsukiPressed(vp);
    const ok = cmd === 'tsuki-step' ? !st.dashed && e.g.fs >= IC.tsukiDashFs : !!cmd;
    if (ok) {
      if (!b) vp.consume(TSUKI_BUTTON[cmd!]);
      if (cmd === 'tsuki-step') { spendFs(e.g, IC.tsukiDashFs); st.dashed = true; }
      startMove(e, kitNext(f.kit, mv.name, cmd!)!);
      return;
    }
  }
  if (IC.tsukiUp + IC.tsukiTap <= sf && sf < IC.tsukiUp + IC.tsukiMax && !vp.down('sig')) f.sf = IC.tsukiUp + IC.tsukiMax;
}

/** The CPU's branch at the stance's f6 (by reach): after a K link's hit J / K / L; within 4.2 m TSUKI-OTOSHI on a guard
 *  (or a gauge < 50) else mostly RANGETSU; to 6.4 m TSUKI-OTOSHI or the dash in; farther the dash within 7.5 m, else the
 *  Getsuga. */
function ichigoAiStance(e: Ent, f: Fighter, st: Ics): string | null {
  const o = oppOf(e), fo = o.f, d = f.dist, r = simRnd01();
  const getsuga = true, dash = !st.dashed && e.g.fs >= IC.tsukiDashFs;
  if (fo.state === 'stun' || fo.state === 'air') return r < 0.5 ? 'tsuki-j' : r < f32(0.8) ? 'tsuki-k' : 'tsuki-l';
  if (d <= 4.2) {
    return fo.state === 'guard' || fo.state === 'guard-hit' || o.g.gg < 50 ? (r < f32(0.6) ? 'tsuki-k' : 'tsuki-j')
      : r < f32(0.7) ? 'tsuki-j' : 'tsuki-k';
  }
  if (d <= 6.4) return dash && r < 0.5 ? 'tsuki-step' : 'tsuki-k';
  if (dash && d <= 7.5 && r < 0.6) return 'tsuki-step';
  return getsuga ? 'tsuki-l' : dash ? 'tsuki-step' : null;
}

// ================================================================ KESSA: the clones 分身
const icc = (hz: Hazard): Icc | null => (hz.data instanceof Icc ? hz.data : null);
/** E's clone hazards, oldest first. */
function ichigoClones(e: Ent): Hazard[] {
  const out: Hazard[] = [];
  for (const hz of W.hazards) if (hz.alive && hz.owner === e && icc(hz)) out.unshift(hz);   // (the Lisp pushes in slot order)
  return out.sort((a, b) => icc(a)!.born - icc(b)!.born);
}
const cloneLiveP = (c: Icc): boolean => c.state === 'idle' || c.state === 'answer';
/** E's live clones (idle or answering). */
export const cloneCount = (e: Ent): number => ichigoClones(e).filter((h) => cloneLiveP(icc(h)!)).length;
function cloneFade(c: Icc): void { c.state = 'fade'; c.fade = 0; }

/** A clone at (X Z) facing the opponent; at the cap the oldest live one fades out (cloneEvict). */
function ichigoCloneSpawn(e: Ent, x: number, z: number, src: string): void {
  const live = ichigoClones(e).filter((h) => cloneLiveP(icc(h)!));
  const i = cloneEvict(live.map((h) => icc(h)!.born)), q = oppOf(e).pos;
  if (i != null) cloneFade(icc(live[i])!);
  spawnHazard('fx', e, { x, z, yaw: dirYaw(q[0] - x, q[2] - z), size: 0.5, life: 99999, look: 'ichigo-clone-look',
                         hook: 'ichigo-clone-hz', data: new Icc(W.tick, IC.cloneLife, src) });
  emit('sfx', 'clone', e);
  clog(() => `${sideName(e)} CLONE ${src} ${1 + (live.length - (i != null ? 1 : 0))}`);
}

/** Pay IC.cloneCost of E's guard gauge for a clone: true when paid; false (nothing spent) below it or guardless. */
function clonePay(e: Ent): boolean {
  const g = e.g;
  if (!g.guardless && g.gg >= IC.cloneCost) { ggSpend(e, IC.cloneCost); return true; }
  return false;
}

/** A Hoho's reappearance leaves a clone 1.6 m in front of the opponent (the line from Ichigo through him), paid. */
function hohoClone(e: Ent): void {
  if (!clonePay(e)) return;
  const q = oppOf(e).pos, p = e.pos, dx = f32(q[0] - p[0]), dz = f32(q[2] - p[2]), l = Math.max(f32(1e-3), len32(dx, dz));
  const [x, z] = clampToCircle(f32(q[0] + f32(f32(1.6) * f32(dx / l))), f32(q[2] + f32(f32(1.6) * f32(dz / l))),
                               f32(T.arenaRadius - f32(0.4)));
  ichigoCloneSpawn(e, x, z, 'hoho');
}

/** Clone C starts answer LINK with WEIGHT (link 1 after the lag). */
function cloneLink(c: Icc, weight: string, link: number): void {
  c.state = 'answer'; c.mv = cloneMove(weight, link); c.link = link; c.sf = link === 1 ? -IC.cloneLag : 0; c.hit = null;
  if (link === 1) { c.touched = false; c.queued = []; }
}

/** A J / K press edge of E's: EVERY clone answers; an idle one starts its string where it stands, an answering one queues
 *  the press for a later link (each press one link, in order, 3 links at most). */
function ichigoPress(e: Ent, button: string): void {
  const w = button === 'quick' ? 'q' : 'f';
  for (const h of ichigoClones(e)) {
    const c = icc(h)!;
    if (c.state === 'idle') cloneLink(c, w, 1);
    else if (c.state === 'answer' && c.link + c.queued.length < 3) c.queued.push(w);
  }
}

/** A clone's / an echo's hit: an 'ic-hit' hazard with HW at MULT in the frame (X Z YAW), for its active frames; guarded
 *  facing Ichigo (src); a hazard: no KOSEI, it counts in his combo. */
function ichigoStrike(e: Ent, x: number, z: number, yaw: number, hw: HitWin, mult: number, data: unknown): void {
  spawnHazard('ic-hit', e, { x, z, yaw, size: 0.5, life: Math.max(1, hw.to - hw.from), hw: echoHitwin(hw, mult), src: true,
                             hook: 'ichigo-strike-hz', data });
}

/** An answering clone, one frame: the lag; its hit, struck where it stands, facing him; its next link once the chain
 *  opens; at the string's end it fades if it touched him, else it idles where it stands. */
function cloneAnswerStep(e: Ent, hz: Hazard, c: Icc): void {
  const mv = c.mv!, sf = ++c.sf, s = mv.s;
  if (sf < s) return;
  if (sf === s) {
    ichigoStrike(e, hz.x, hz.z, hz.yaw, mv.hits[0], IC.cloneScale, c);
    emit('sfx', 'whoosh-heavy', e);
  }
  if (c.queued.length && c.link < 3 && chainOpenP(sf, s, mv.a, mv.r, c.hit ?? (c.touched ? true : null)))
    cloneLink(c, c.queued.shift()!, c.link + 1);
  else if (sf >= s + mv.a + mv.r) {
    if (cloneAfterString(c.touched, c.life) === 'fade') cloneFade(c);
    else { c.state = 'idle'; c.queued = []; }
  }
}

/** A charging clone bursts on O's strike frame. */
function cloneBurst(e: Ent, hz: Hazard): void {
  ichigoLook(e, 'ichigo-burst-look', hz.x, hz.z, { size: 1.0, life: 16 });
  emit('sfx', 'clone', e);
}

/** A clone, each step: its life, its facing, and its state: idle, answer, charge (runs at him at <= 40 m/s, bursts on
 *  O's strike frame or when the rush is over), fade (8 f). */
function ichigoCloneStep(hz: Hazard, c: Icc): void {
  const e = hz.owner, o = hazardTarget(hz);
  if (!(e.alive && o && o.alive)) { hz.alive = false; return; }
  hz.age++;
  c.life--;
  const q = o.pos, dx = f32(q[0] - hz.x), dz = f32(q[2] - hz.z), d = len32(dx, dz);
  if (c.state !== 'fade') hz.yaw = angleWrap(turnToward(hz.yaw, dirYaw(dx, dz), trackStep(720.0)));
  switch (c.state) {
    case 'idle': if (c.life <= 0) cloneFade(c); break;
    case 'answer': cloneAnswerStep(e, hz, c); break;
    case 'charge': {
      const s = Math.min(f32(40.0 * f32(STEP)), Math.max(0.0, f32(d - 1.0))), f = e.f;
      if (d > 0.01) { hz.x = f32(hz.x + f32(s * f32(dx / d))); hz.z = f32(hz.z + f32(s * f32(dz / d))); }
      const mv = f.move;
      if (!(f.state === 'move' && mv && mv.kind === 'kikon'
            && (f.phase === 'aura' || f.phase === 'dash' || (f.phase === 'main' && f.sf < mv.s)))) {
        cloneBurst(e, hz);
        hz.alive = false;
      }
      break;
    }
    case 'fade': if (++c.fade >= 8) hz.alive = false; break;
  }
}

/** E was really hit: every clone, afterimage and their hits in the air vanish (a puff where each clone stood). */
function ichigoVanish(e: Ent): void {
  const at: [number, number][] = [];
  for (const hz of W.hazards) {
    if (hz.alive && hz.owner === e && (icc(hz) || hz.data instanceof Ice || hz.kind === 'ic-hit')) {
      if (icc(hz)) at.unshift([hz.x, hz.z]);
      hz.alive = false;
    }
  }
  for (const [x, z] of at) ichigoLook(e, 'ichigo-burst-look', x, z, { size: 0.6, life: 12 });
  if (at.length) clog(() => `${sideName(e)} CLONES GONE ${at.length}`);
}

/** O pressed: N = the live clones; they all charge; the strike gains IC.cloneBurstDmg x N; the Kikon is worth
 *  cloneKonpaku(N). */
function ichigoOPress(e: Ent, f: Fighter, st: Ics): void {
  let n = 0;
  for (const h of ichigoClones(e)) { const c = icc(h)!; if (cloneLiveP(c)) { n++; c.state = 'charge'; } }
  f.kikonN = cloneKonpaku(n); f.dmgBonus = n * IC.cloneBurstDmg; st.oAt = W.tick; st.oN = n;
  clog(() => `${sideName(e)} KAGE-UCHI clones ${n} konpaku ${cloneKonpaku(n)}`);
}

// ================================================================ KESSA: 残像 ZANZO, the afterimages
/** Is E's afterimage state on (its timer is a look-only hazard: a reset clears it)? */
const zanzoP = (e: Ent): boolean => W.hazards.some((hz) => hz.alive && hz.owner === e && hz.look === 'ichigo-zanzo-look');

function histPush(st: Ics, e: Ent): void {
  const i = mod(st.histI + 1, 16), v = st.hist;
  st.histI = i; v[3 * i] = e.pos[0]; v[3 * i + 1] = e.pos[2]; v[3 * i + 2] = e.yaw;
}
/** [x z yaw] of Ichigo LAG steps ago (at most 15). */
function histAt(st: Ics, lag: number): [number, number, number] {
  const i = 3 * mod(st.histI - Math.min(15, lag), 16), v = st.hist;
  return [v[i], v[i + 1], v[i + 2]];
}

/** A new attack of E's (a move with hits, not the Breaker; a Kikon rush at its strike) while ZANZO is on: its echo. */
function echoWatch(e: Ent, f: Fighter, st: Ics): void {
  const mv = f.state === 'move' ? f.move : null, main = !!mv && f.phase === 'main';
  if (mv === st.seen && main === st.seenMain) return;
  st.seen = mv; st.seenMain = main;
  if (main && mv!.hits.length > 0 && mv!.kind !== 'breaker' && zanzoP(e))
    spawnHazard('fx', e, { x: e.pos[0], z: e.pos[2], yaw: e.yaw, size: 0.5, life: 99999, look: 'ichigo-echo-look',
                           hook: 'ichigo-echo-hz', data: new Ice(mv!, f.sf - IC.zanzoLag, mvTotal(mv!)) });
}

// ================================================================ KESSA: the parry
/** In blockstun L starts the parry at once, under its price; a CPU presses it after a blocked K link
 *  IC.aiIcParryBsP of the time, on the frame that puts the string's next hit in the window. */
function parryFromBlockstun(e: Ent, f: Fighter, st: Ics, vp: Vpad): void {
  const b = e.brain;
  if (b) {
    const sf = f.sf;
    if (st.bsKey < 0 || sf < st.bsKey) {                               // a new blockstun (a block restarts it at 0)
      st.bsAt = -1;
      const om = oppOf(e).f.move;
      if (om && ((om.kind === 'flash' && simRnd01() < icP(b, f32(f32(0.6) * IC.aiIcParryBsP), IC.aiIcParryBsP, 0.8))
                 || (om.kind === 'quick' && aiMashP(b) && simRnd01() < icP(b, 0.0, 0.0, 0.6))))   // (no habits: M6)
        st.bsAt = Math.max(1, f.stun - 6);
    }
    st.bsKey = sf;
    if (sf === st.bsAt) { st.bsAt = -1; aiPress(b, 'sig', 2); }
  }
  if (vp.commandPressedP('sig', false) && kitCommandOkP(e, 'sig') && !guardLockedNowP(f)) {
    vp.consume('sig');
    startMove(e, kitCommandMove(f.kit, 'sig')!);
    clog(() => `${sideName(e)} parry from blockstun`);
  }
}

/** The parry frame kept for the practice judge (its rim, the window's tell, is the renderer's). */
function parryWatch(e: Ent, f: Fighter, st: Ics): void {
  const mv = f.state === 'move' ? f.move : null;
  st.parrySf = mv && mv.flags.includes('parry') && f.phase === 'main' ? f.sf : -1;
}

// ================================================================ his hooks
registerHooks({
  /** GETSUGA TENSHO's crescent leaves the long blade. */
  'ichigo-getsuga'(e: Ent) { ichigoWave(e, moveParam(e, 'look')); emit('sfx', 'getsuga', e); },
  /** JUJISHO f12: the long blade's crescent forms on the edge (a look; the wave is f20's). */
  'ichigo-juji-first'(e: Ent) {
    const [x, z] = ahead(e, 1.0);
    ichigoLook(e, 'ichigo-form-look', x, z, { yaw: e.yaw, size: 1.8, life: 10 });
    emit('sfx', 'getsuga', e);
  },
  /** JUJISHO f20: the two crescents fused into one cross wave. */
  'ichigo-juji'(e: Ent) { ichigoWave(e, moveParam(e, 'look')); emit('sfx', 'getsuga', e); },
  /** SOGA f0: the flash step's vanish. */
  'ichigo-soga-vanish'(e: Ent) { emit('hoho-out', e, e.pos[0], e.pos[2]); },
  /** TSUKIWATARI f0: 3.5 m in the stick direction (neutral: at him) over its 12 f, iframes f0-8, the flash step's vanish. */
  'ichigo-tsuki-dash'(e: Ent) {
    const f = e.f, p = e.pos;
    const [to0, st0] = e.brain ? [1.0, 0.0] : stickRelative(e, f);
    const [to, st] = stepDirection(to0, st0, 1.0);
    const [dx, dz] = towardStrafeDir(to, st, p[0], p[2], f.ox, f.oz);
    setSlide(e, 3.5, 12, dx, dz);
    f.invuln = 9;
    emit('hoho-out', e, p[0], p[2]);
    emit('sfx', 'whoosh-light', e);
  },
  /** TSUKIWATARI f11: back in the stance, a fresh window. */
  'ichigo-tsuki-return'(e: Ent) { startMove(e, kitNext(kitOf(e), 'ic-tsuki-dash', 'tsuki-back')!); },
  /** KUSARI-BIKI's hit: pulled to its pull m (and bound). */
  'ichigo-pull'(e: Ent) { ichigoPullTo(e, moveParam(e, 'pull'), 10); },
  /** ZANGETSU-GAESHI f0: the staggered attacker dragged to its pull m, so the cut reaches. */
  'ichigo-gaeshi-pull'(e: Ent) { ichigoPullTo(e, moveParam(e, 'pull'), 6); },
  /** ZANZO f12: the state for IC.zanzoLife frames. */
  'ichigo-zanzo-on'(e: Ent) {
    ichigoLook(e, 'ichigo-zanzo-look', e.pos[0], e.pos[2], { life: IC.zanzoLife });
    emit('sfx', 'clone', e);
    clog(() => `${sideName(e)} ZANZO`);
  },
  /** KUSARI-TATE f0: its price, the chains flaring (the tell). */
  'ichigo-parry-open'(e: Ent) {
    ggSpend(e, IC.kessaParryCost);
    ichigoLook(e, 'ichigo-flare-look', e.pos[0], e.pos[2], { yaw: e.yaw, life: 18 });
    emit('sfx', 'chain-rattle', e);
    emit('sfx', 'parry-open', e);
  },
  /** The clones' hazard hook: their own step (true: the generic one skipped); no volume. */
  'ichigo-clone-hz'(hz: Hazard, ev: string) {
    if (ev === 'step') { ichigoCloneStep(hz, hz.data as Icc); return true; }
    return undefined;
  },
  /** The ic-hit hazards' hook: their volume is the hit window's own (in the frame they were struck in). */
  'ichigo-strike-hz'(hz: Hazard, ev: string, tx: number, ty: number, tz: number, tr: number, th: number) {
    if (ev !== 'touches') return undefined;
    return volHitP(hz.hw!.vols[0], hz.x, 0, hz.z, fwdX(hz.yaw), fwdZ(hz.yaw), tx, ty, tz, tr, th, 0);
  },
  /** An afterimage: it replays his move IC.zanzoLag frames behind, where he stood then, and strikes each of its hit
   *  windows at IC.zanzoMult. */
  'ichigo-echo-hz'(hz: Hazard, ev: string) {
    if (ev !== 'step') return undefined;
    const d = hz.data as Ice, e = hz.owner, sf = ++d.sf, mv = d.mv;
    hz.age++;
    if (!e.alive || sf >= d.end) hz.alive = false;
    else {
      const [x, z, yaw] = histAt(ic(e), IC.zanzoLag);
      hz.x = x; hz.z = z; hz.yaw = yaw;
      for (const w of mv.hits) if (sf === w.from) ichigoStrike(e, x, z, yaw, w, IC.zanzoMult, 'echo');
    }
    return true;
  },
  /** KESSA's kikon-worth: what 千影 would take if O were pressed now (the red Konpaku hint, his Soul Break). */
  'ichigo-kikon-worth'(e: Ent) { return cloneKonpaku(cloneCount(e)); },
  /** KESSA's step hook: every Step's take-off point leaves a clone, paid. */
  'ichigo-step-clone'(e: Ent) { if (clonePay(e)) ichigoCloneSpawn(e, e.pos[0], e.pos[2], 'step'); },
  /** KESSA's ok hook: L (the parry) wants its price and a guard; SP2 is refused while ZANZO runs. */
  'ichigo-ok'(e: Ent, cmd: string) {
    const g = e.g;
    return cmd === 'sig' ? !g.guardless && g.gg >= IC.kessaParryCost : cmd === 'sp2' ? !zanzoP(e) : true;
  },
  /** KESSA's parried hook: + the catch's guard gauge, the attacker's stagger lengthened, a 12 f hitstop, 0.3 s of slow
   *  motion; the counter is the land string (ZANGETSU-GAESHI). */
  'ichigo-catch'(e: Ent, att: Ent) {
    const g = e.g, fa = att.f;
    g.gg = f32(Math.min(T.ggMax, g.gg + IC.kessaParryCatch)); g.ggIdle = 0;
    if (fa.state === 'stun') fa.stun = IC.kessaParryStun;
    W.time.requestHitstop(12);
    W.time.slowmo(0.4, 0.3);
    emit('ui-flash', 1, 1, 1, 0.55, 7.0);
    emit('sfx', 'parry-ting', e);
    emit('sfx', 'chain-snap', e);
    clog(() => `${sideName(e)} PARRY CATCH gg ${roundHalfEven(e.g.gg)}`);
  },
  /** Both forms' hit hook: a clone's hit tells its clone what it did (its string's gate and its fate). */
  'ichigo-hit'(att: Ent, _def: Ent, res: Contact, _hw: HitWin, _mv: Move | null, hazard: Hazard | null) {
    const c = hazard ? icc(hazard) : null, k = contactOf(res);
    if (c && k) {
      c.hit = k; c.touched = true;
      clog(() => `${sideName(att)} clone ${res}`);
    }
  },
  /** Both forms' struck hook: a real hit on him clears his clones and afterimages. */
  'ichigo-struck'(def: Ent, _att: Ent, res: Contact) { if (cloneVanishP(res)) ichigoVanish(def); },
  /** Both forms' tick hook (every step, after the hits): JUJISHO's cut; the Shikai's stance; KESSA's clones (the J / K
   *  press edges they answer, the Hoho clone, the O charge), the parry from blockstun, the afterimages. */
  'ichigo-tick'(e: Ent, f: Fighter) {
    const st = ic(e);
    ichigoCut(e);
    if (f.form === 'kessa') {
      const vp = e.pilot.vpad, state = f.state, mv = state === 'move' ? f.move : null;
      histPush(st, e);
      if (!['stun', 'air', 'down', 'wakeup', 'cine'].includes(state))
        for (const bt of ['quick', 'flash'] as const) if (vp.held(bt) === 1 && !vp.moddedP(bt)) ichigoPress(e, bt);
      if (state === 'hoho') {
        if (f.sf >= T.hohoAppear && !st.hohoDone) { st.hohoDone = true; hohoClone(e); }
      } else st.hohoDone = false;
      if (mv && mv.kind === 'kikon') { if (!st.oLive) { st.oLive = true; ichigoOPress(e, f, st); } }
      else st.oLive = false;
      if (state === 'guard-hit') parryFromBlockstun(e, f, st, vp); else st.bsKey = -1;
      parryWatch(e, f, st);
      echoWatch(e, f, st);
    } else {
      const mv = f.state === 'move' ? f.move : null;
      if (mv && (mv.name === 'ic-tsuki' || mv.name === 'ic-tsuki-k2' || mv.name === 'ic-tsuki-re')) tsukiStep(e, f, st, mv);
      else if (!(mv && mv.name === 'ic-tsuki-dash')) st.dashed = false;
    }
  },
});

// ================================================================ the CPU (docs/DUEL_AI_V2.md; every chance by difficulty)
/** A chance by brain B's difficulty: EASY <= NORMAL <= HARD. */
const icP = (b: Brain, easy: number, normal: number, hard: number): number => getf({ easy, normal, hard }, b.difficulty, normal);
const icHitsP = (mv: Move | null): boolean => !!mv && mv.hits.length > 0;

/** One of E's opponent's waves / fireballs reaches E within LO-HI frames. */
function incomingHazardIn(e: Ent, lo: number, hi: number): boolean {
  const o = oppOf(e), q = e.pos;
  return W.hazards.some((hz) => {
    if (!(hz.alive && hz.owner === o && (hz.kind === 'wave' || hz.kind === 'fireball') && hz.hitsLeft > 0 && hz.delay <= 0
          && hz.speed > 0.1)) return false;
    const dx = f32(q[0] - hz.x), dz = f32(q[2] - hz.z), fr = f32(f32(60 * Math.max(0.0, f32(len32(dx, dz) - 1.0))) / hz.speed);
    return lo <= fr && fr <= hi;
  });
}

/** The reach bucket of E's best idle clone to the opponent: 'light' (<= 2.4 m: both answers land), 'heavy' (<= 3.0 m: J's
 *  heavy lands), or null. */
function cloneIdleInReach(e: Ent): 'light' | 'heavy' | null {
  let best: 'light' | 'heavy' | null = null;
  const q = oppOf(e).pos;
  for (const hz of ichigoClones(e)) {
    const dd = len32(f32(q[0] - hz.x), f32(q[2] - hz.z));
    if (icc(hz)!.state === 'idle') {
      if (dd <= 2.4) best = 'light';
      else if (dd <= 3.0 && best === null) best = 'heavy';
    }
  }
  return best;
}

/** KESSA's CPU reflexes (free states): the masher's answers, the timed Hoho, the red phase, the conversion, then the
 *  parry, the long punish, ZANZO, the clone bank before the Kikon, the clones' reach, O with >= 2 clones. A clause whose
 *  test holds ends the chain with its answer (the Lisp COND), null or not. */
function ichigoAiKessa(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const g = e.g, n = cloneCount(e), gg = g.gg, pay = !g.guardless && gg >= IC.cloneCost;
  let c: string | null;
  if ((c = ichigoAiMash(e, b, s, d))) return c;
  if ((c = ichigoAiPerfectHoho(e, b, s, d))) return c;
  if ((c = ichigoAiRed(e, b, s, d))) return c;                         // (the Konpaku economy: HARD only)
  if ((c = ichigoAiConvert(e, b, s, d))) return c;
  if (gg >= IC.kessaParryCost && !g.guardless && b.reactRoll < icP(b, f32(f32(0.6) * IC.aiIcParryP), IC.aiIcParryP, 1.0)) {
    const lead = s.s - s.sf - b.delay;
    if ((s.state === 'move' && s.phase === 'main' && ['quick', 'flash', 'sig', 'sp', 'kikon'].includes(s.kind!)
         && lead >= 4 && lead <= 22 && d < f32(s.reach + f32(0.6))) || incomingHazardIn(e, 4, 22))
      return why(b, 'parry', 'sig');
  }
  if ((c = ichigoAiLongPunish(e, b, s, d))) return c;
  // ZANZO at 2.6-7 m or while he is down / launched, he not attacking; HARD 0.15 a step, EASY / NORMAL never
  if (((d >= f32(2.6) && d <= 7.0) || s.state === 'down' || s.state === 'air') && s.state !== 'move'
      && kitCommandOkP(e, 'sp2') && simRnd01() < icP(b, 0.0, 0.0, 0.15))
    return why(b, 'zanzo', 'sp2');
  {
    const go = oppOf(e).g;
    if (go.reishi < f32(IC.aiKessaBankAt * go.reishiMax) && kitCommandOkP(e, 'kikon')
        && !['stun', 'air', 'down', 'wakeup', 'hoho'].includes(s.state))
      return pay && n < (gg >= IC.cloneCost + 25.0 ? 3 : 2) && d >= 3.0
        && !(s.state === 'move' && s.sf < s.activeEnd && d < f32(s.reach + 1.0)) ? why(b, 'bank', 'side-step') : null;
  }
  if (!s.flags.includes('parry') && !['down', 'wakeup', 'hoho'].includes(s.state) && simRnd01() < IC.aiKessaCloneJP) {
    const r = cloneIdleInReach(e);
    return r === null ? null : r === 'light' && d >= f32(1.6) && d <= 3.0 ? why(b, 'clone-reach', 'f') : why(b, 'clone-reach', 'q');
  }
  if (n >= 2 && d <= f32(8.6) && kitCommandOkP(e, 'kikon') && simRnd01() < (n >= 3 ? 2 : 1) * IC.aiKessaOP)
    return why(b, 'clones', 'kikon');
  return null;
}

/** Out of J's reach, an opponent still recovering (or reeling): the longest tool of the form that lands before he is
 *  free (K1; else the SP that hits), one roll per his action at (EASY 0 / NORMAL 0.15 / HARD 0.8). */
function ichigoAiLongPunish(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const kit = kitOf(e), left = s.left - b.delay;
  if (((s.state === 'move' && s.phase === 'main' && s.sf >= s.activeEnd) || s.state === 'stun')
      && s.left < 99 && d > f32(kitCommandMove(kit, 'q')!.reach + f32(0.4)) && b.reactRoll < icP(b, 0.0, 0.15, 0.8)) {
    for (const c of ['f', 'sp2', 'sp1']) {
      const mv = kitCommandMove(kit, c);
      if (icHitsP(mv) && kitCommandOkP(e, c) && left > mv!.s && d <= f32(f32(mv!.reach + mv!.slide) + f32(0.1))) return why(b, 'long-punish', c);
    }
  }
  return null;
}

/** Against a J masher: KESSA lays the parry where his next J lands; either form K1s him walking in from out of his J.
 *  Per step (EASY 0 / NORMAL 0.03 / HARD 0.25). */
function ichigoAiMash(e: Ent, b: Brain, s: Snap, d: number): string | null {
  if (!(aiMashP(b) && !['guard', 'guard-hit', 'down', 'wakeup', 'hoho', 'stun', 'air'].includes(s.state))) return null;
  const g = e.g, kessa = kitOf(e).form === 'kessa';
  if (kessa && d <= 2.0 && !g.guardless && g.gg >= IC.kessaParryCost + 10.0 && kitCommandOkP(e, 'sig')
      && simRnd01() < icP(b, 0.0, 0.03, 0.25))
    return why(b, 'mash-parry', 'sig');
  if (d >= f32(1.7) && d <= f32(2.8) && s.state !== 'move' && kitCommandOkP(e, 'f') && simRnd01() < icP(b, 0.0, 0.03, 0.25))
    return why(b, 'mash-poke', 'f');
  return null;
}

/** The timed Hoho: his strike lands 0-11 frames from now within its reach + 1.5 m: Hoho now, inside the perfect window.
 *  One roll per his action at (EASY 0 / NORMAL 0 / HARD 1.0); not in a burst. */
function ichigoAiPerfectHoho(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const g = e.g, f = e.f, lead = s.s - s.sf - b.delay;
  return s.state === 'move' && s.phase === 'main' && ['quick', 'flash', 'sig', 'sp', 'breaker', 'kikon'].includes(s.kind!)
    && s.activeEnd > s.s && lead >= 0 && lead <= 11 && d < f32(s.reach + 1.5)
    && !kitOf(e).rooted && hohoAllowedP(false, g.fs, f.hohoLock, g.burst) && !g.burst
    && b.hohoRoll < icP(b, 0.0, 0.0, 1.0) ? why(b, 'perfect-hoho', 'hoho') : null;
}

/** KESSA's clones wanted for the Kikon (2 / 2 / 3 / 4 Konpaku by 0-3 clones): 2, 3 with the guard gauge for them; HARD 3
 *  down to IC.cloneCost + 10 of the gauge. */
const ichigoBankTarget = (e: Ent, b: Brain): number =>
  (e.g.gg >= IC.cloneCost + (b.difficulty === 'hard' ? 10.0 : 25.0) ? 3 : 2);

/** Red (HARD), his rush coming within 11 m: hold guard through its strike, one roll per his action. */
function ichigoAiRedGuard(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const g = e.g;
  return redP(g.reishi, g.reishiMax) && icP(b, 0.0, 0.0, 1.0) > 0 && s.state === 'move' && s.kind === 'kikon'
    && (s.phase === 'aura' || s.phase === 'dash' || (s.phase === 'main' && s.sf < s.activeEnd))
    && d < 11.0 && aiGuardK(e) > 0 && g.gg >= 21.0 && b.reactRoll < 0.95 ? why(b, 'red-guard', 'guard-long') : null;
}

/** We are red (his Kikon ready): hold guard against his rush, else SOUL REVERSE while he isn't swinging at us (HARD). */
function ichigoAiRed(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const g = e.g;
  if (!(redP(g.reishi, g.reishiMax) && icP(b, 0.0, 0.0, 1.0) > 0)) return null;
  const c = ichigoAiRedGuard(e, b, s, d);
  if (c) return c;
  if (burstOkP(e) === 'white' && !(s.state === 'move' && s.sf < s.activeEnd && d < f32(s.reach + 1.5)) && simRnd01() < 0.25)
    return why(b, 'red-white', 'burst');
  return null;
}

/** Frames from an O press at D m to its strike landing (aura 6, 30 m/s to 1.6 m, S 7, + 2). */
const ichigoRushFrames = (d: number): number => 6 + Math.max(0, Math.ceil(f32(d - f32(1.6)) / 0.5)) + 7 + 2;

/** He is red (our Kikon ready; HARD only): turn it into the most Konpaku. KESSA banks its clones first; the rush only
 *  where his answer can't come (he is busy, or 7-8.4 m out); KESSA with its bank chains him; closer, J / K strings. */
function ichigoAiConvert(e: Ent, b: Brain, s: Snap, d: number): string | null {
  if (!(kikonReadyP(e) && !aiSbFinishP(e) && kitCommandOkP(e, 'kikon') && icP(b, 0.0, 0.0, 1.0) > 0
        && !['down', 'wakeup', 'hoho'].includes(s.state))) return null;
  const kessa = kitOf(e).form === 'kessa', g = e.g;
  const short = kessa && cloneCount(e) < ichigoBankTarget(e, b) && !g.guardless && g.gg >= IC.cloneCost;
  const left = s.left - b.delay, attacking = s.state === 'move' && s.sf < s.activeEnd;
  if (!short && d < f32(8.4) && s.state === 'move' && s.phase === 'main' && s.sf >= s.activeEnd && s.left < 99
      && left >= ichigoRushFrames(d) && b.reactRoll < 0.9)
    return why(b, 'rush-busy', 'kikon');
  if (!short && d >= 7.0 && d <= f32(8.4) && !attacking && simRnd01() < 0.3) return why(b, 'rush-far', 'kikon');
  if (kessa && !short && cloneCount(e) >= 2 && d >= f32(3.8) && d <= 7.0 && !attacking && kitCommandOkP(e, 'sp1') && simRnd01() < 0.15)
    return why(b, 'chain', 'sp1');
  if (d < 7.0 && b.decideT <= 1) {
    b.decideT = getf(T.aiThink, b.difficulty, 24) + Math.floor(40 * simRnd01());
    if (short && d < 3.0 && !attacking) return why(b, 'bank', 'step');   // (a back hop: a clone where it took off)
    if (short) return null;                                            // (ichigoAiKessa side-Steps it)
    // (aiAttack presses itself; 'none' keeps that press: no band below 5 m holds kikon)
    if (d < 5.0 && simRnd01() < 0.7 && aiAttack(e, b, kitOf(e), s, d, b.heat, false)) return 'none';
  }
  return null;
}

registerHooks({
  /** The Shikai's reflex: the masher's answers, the timed Hoho, our red phase, the conversion, then the long punish. */
  'ichigo-ai-shikai'(e: Ent, b: Brain, s: Snap, d: number): string | null {
    return ichigoAiMash(e, b, s, d) ?? ichigoAiPerfectHoho(e, b, s, d) ?? ichigoAiRed(e, b, s, d) ?? ichigoAiConvert(e, b, s, d)
      ?? ichigoAiLongPunish(e, b, s, d);
  },
  'ichigo-ai-kessa': ichigoAiKessa,
  /** Both forms' assistGuard: the timed Hoho and the red guard of a rush. */
  'ichigo-assist-guard'(e: Ent, b: Brain, s: Snap, d: number): string | null {
    return ichigoAiPerfectHoho(e, b, s, d) ?? ichigoAiRedGuard(e, b, s, d);
  },
  /** Both forms' spEnder (our J3 / K3 hit, no O ender rolled): the Shikai SOGA with a bar, else the O poke; KESSA
   *  KUSARI-BIKI. HARD only. */
  'ichigo-ai-ender'(e: Ent, kit: Kit): string | null {
    const b = aiBrain(e);
    if (!b) return null;
    const bars = Math.floor(e.g.reiatsu / T.reiatsuBar), r = simRnd01();
    if (kit.form === 'kessa') return bars >= 1 && kitCommandOkP(e, 'sp1') && r < icP(b, 0.0, 0.0, 0.95) ? 'sp1' : null;
    if (bars >= 1 && kitCommandOkP(e, 'sp2') && r < icP(b, 0.0, 0.0, 0.95)) return 'sp2';
    if (kitCommandOkP(e, 'kikon', kit, true) && r < icP(b, 0.0, 0.0, 1.0)) return 'kikon';
    return null;
  },
});
