// senjumaru.ts <- duel/lisp/senjumaru.lisp: SHUTARA SENJUMARU (docs/DUEL_SENJUMARU.md). Her moves, her seven forms (base:
// the Shikai SHIGARAMI, whose J / K / O contacts sew stitches into him and whose L pulls them out as unguardable spikes;
// tsuji1 .. tsuji6: the Bankai's loom, L held weaves the next hank, released it unravels a zone under him), her per-fighter
// state (the loom, the soldier, the umbrella: a fresh one per fighter, on Fighter.char), her hazards' hook, her kit hooks
// and her CPU. Her HUD meter is drawing code in the Lisp: here senjuMeter(e) gives the renderer what it draws. The pacing
// log, debug tests / knobs and the cinematics' shots aren't ported (the cinematics are length-only: match.ts CINES).
import { angleWrap, fwdX, fwdZ, getf, len32, PI, roundHalfEven, turnToward, weightedPick } from '../sim/math';
import { T, f32Deep } from '../sim/tuning';
import { STEP } from '../sim/time';
import { bandWeights, burn, castPoint, clampToCircle, contactOf, dirYaw, gaugeMove, hohoAllowedP, trackStep, type Band, type Contact } from '../sim/rules';
import {
  KIT_COMMANDS, defkit, defmove, defmoveCopy, findMove, kitCommandCost, kitCommandMove, kitKLinkP, kitLLink, makeHitwin, registerHooks,
  type HitWin, type Kit, type Move,
} from '../sim/kit';
import { makeVol, oboxCylHitP, volHitP, type Vol, type VolSpec } from '../sim/hitvol';
import { W, clog, emit, kitOf, oppOf, sideName, simRnd01, type Brain, type Ent, type Fighter, type Gauges, type Hazard, type Snap } from '../sim/types';
import { awakenStateP, callout, faceYawTo, kitCommandOkP, moveParam, playClip, rushParam, setSlide, startMove } from '../sim/fighter';
import { kikonReadyP, setForm } from '../sim/combat';
import { aiAwakenMode, aiAwakenP, aiBrain, aiDash, aiMashP, aiSbFinishP, aiTable, why } from '../sim/ai';
import { hazardActiveP, hazardTarget, hazardTouchesP, spawnHazard, type HazardOpts } from '../sim/hazards';

const f32 = Math.fround;
/** X^2 + Z^2 in single floats (the Lisp's (+ (expt x 2) (expt z 2)) on singles). */
const sq32 = (x: number, z: number): number => f32(f32(x * x) + f32(z * z));

// ================================================================ knobs (docs/DUEL_SENJUMARU.md §11; senjumaru.lisp's own)
export const SJ = f32Deep({
  walkSenju: 3.6, runSenju: 8.5, walkTsuji: 3.3, runTsuji: 8.0,
  senjuMult: 1.6, senjuTaken: 0.95, tsujiMult: 1.55, tsujiTaken: 1.0,
  hariMax: 6, hariIdle: 180, hariFall: 30, hariSewHit: 2, hariSewBlock: 1,
  hariDmg: 13, hariGap: 2, hariStun: 8, hariLastStun: 18,
  shinpeiSpeed: 3.5, shinpeiTurn: 120.0, shinpeiNear: 2.4, shinpeiRise: 10, shinpeiLife: 300,
  kasaBase: 40, kasaCap: 120,
  weavePass: 20, weaveTap: 10, weaveSeg: 30, unfold: 20, unfoldCombo: 10, tornLock: 90, hankRange: 9.0, hankLifeMult: 1.0,
  mirrorK: 0.3, aiSenjuHari: 0.1, aiSenjuTachi: 0.5, aiSenjuPair: 0.04, tachiSecond: 6,
});
/** The soldier's one string: per hit [wind-up, clip, clip startup, volume, damage, reaction, flinch]. */
const SHINPEI_COMBO: [number, string, number, VolSpec, number, string, number | null][] = f32Deep([
  [18, 'ru-q1', 7, ['cap', 0.3, 2.6, 1.2, 0.35], 20, 'flinch', 22],
  [14, 'ru-ring', 21, ['arc', 2.8, 160, 0.0, 1.8], 20, 'flinch', 24],
  [16, 'ru-thrust', 17, ['cap', 0.3, 3.0, 1.2, 0.35], 34, 'stagger', null],
]);

// the six hanks, their values at 3 passes (§4.2)
interface HankDef { name: string; short: string; kanji: string; r?: number; life?: number; rise?: number; dmg?: number;
  guard?: number; after?: number; away?: number; period?: number; swirl?: number; freeze?: number; frost?: number;
  width?: number; max?: number; hits?: number; chip?: number; reiatsu?: number; fs?: number }
export const HANKS: Record<number, HankDef> = f32Deep({
  1: { name: 'BANRA NO ME', short: 'ME', kanji: '万朶の眼', r: 3.0, life: 240 },
  2: { name: 'HAGANE NO YOROI', short: 'HAGANE', kanji: '刃金のよろい', r: 2.0, rise: 16, dmg: 90, guard: 24, after: 20 },
  3: { name: 'KOKUSA NO HARAWATA', short: 'KOKUSA', kanji: '黒砂の腸', r: 2.0, life: 240, away: 0.4, period: 60, swirl: 12, dmg: 40 },
  4: { name: 'ITETSUKU SHITONE', short: 'SHITONE', kanji: '凍てつく褥', r: 2.0, life: 240, dmg: 70, freeze: 40, frost: 60 },
  5: { name: 'YAKENOHARA', short: 'YAKENOHARA', kanji: '焼野原', width: 2.0, max: 10.0, hits: 2, dmg: 45, life: 150, chip: 0.12 },
  6: { name: 'YAMIYO NO HOSHIYO', short: 'HOSHI', kanji: '闇夜の星よ', r: 3.5, life: 240, reiatsu: 30.0, fs: 15.0 },
});
/** The loom's queue: 黒砂 刃金 | 褥 焼野原 | 眼 星, then back to 黒砂 (three SP1 pairs). */
export const HANK_ORDER = [3, 2, 4, 5, 1, 6];
const TSUJI = ['tsuji1', 'tsuji2', 'tsuji3', 'tsuji4', 'tsuji5', 'tsuji6'];
/** The weave's scaling by passes 1 / 2 / 3, rows radius, life, damage, effect. */
const PASS_SCALE = f32Deep([[0.7, 0.85, 1.0], [0.5, 0.8, 1.2], [0.7, 1.0, 1.4], [0.6, 1.0, 1.5]]);

// ================================================================ rules (pure)
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const hank = (n: number, key: keyof HankDef): any => HANKS[n][key];
export const hankNext = (n: number): number => HANK_ORDER[(HANK_ORDER.indexOf(n) + 1) % HANK_ORDER.length];
export const hankSlot = (n: number): number => HANK_ORDER.indexOf(n);
/** SP1 from the form whose next hank is N releases a designed pair (N on an even slot). */
export const tachiAlignedP = (n: number): boolean => hankSlot(n) % 2 === 0;
/** SP1 from next hank N: the two hanks it releases and the hank the loom is on after them. */
export const tachiHanks = (n: number): [number, number, number] => [n, hankNext(n), hankNext(hankNext(n))];
export const hankHitsP = (n: number): boolean => hank(n, 'dmg') != null;
export const hankForm = (n: number): string => TSUJI[n - 1];
export const formHank = (form: string): number | null => { const i = TSUJI.indexOf(form); return i >= 0 ? i + 1 : null; };
/** The hank's woven frames after one more frame of L held (the press's HOLDth). */
export function weaveAdd(woven: number, hold: number): number {
  if (hold < SJ.weaveTap) return woven;
  if (hold === SJ.weaveTap) return Math.min(3 * SJ.weavePass, woven + SJ.weaveTap);
  return Math.min(3 * SJ.weavePass, woven + 1);
}
export const weaveStored = (woven: number): number => Math.min(3, Math.floor(woven / SJ.weavePass));
export const releasePasses = (woven: number): number => Math.max(1, weaveStored(woven));
export const releaseOkP = (woven: number): boolean => weaveStored(woven) >= 1;
export const quickWeave = (woven: number): number => Math.min(3 * SJ.weavePass, woven + SJ.weavePass);
export const weaveTapP = (hold: number): boolean => hold < SJ.weaveTap;
/** Letting L go after HOLD frames: 'stop' (a weave), 'release' (a tap, a pass stored, no zone live), else 'refused'. */
export function weaveReleaseAct(hold: number, woven: number, live: boolean): 'stop' | 'release' | 'refused' {
  if (!weaveTapP(hold)) return 'stop';
  return releaseOkP(woven) && !live ? 'release' : 'refused';
}
/** May a Bankai form's COMMAND start, WOVEN frames on the hank? Only K -> L (a :combo move) needs a pass stored. */
export const loomOkP = (command: string, combo: Move | null, woven: number): boolean =>
  command !== 'sig' || !(combo && combo.params.combo) || releaseOkP(woven);
/** A hit on her while she weaves hank N: void. [next hank, woven frames]. */
export const weaveVoid = (n: number): [number, number] => [hankNext(n), 0];
/** The weave's scaling by PASSES (1-3): [radius x, life x, damage x, effect x]. */
export function hankScale(passes: number): [number, number, number, number] {
  const i = Math.max(1, Math.min(3, passes)) - 1;
  return PASS_SCALE.map((row) => row[i]) as [number, number, number, number];
}
// (single floats, as the Lisp multiplies: the rounded integers agree with it)
export const hankFx = (n: number, key: keyof HankDef, passes: number): number => f32(f32(hankScale(passes)[3]) * f32(hank(n, key)));
/** The stitch count after one contact of her J / K / O window resolved as RES: a hit sews 2, any other contact 1, a parry 0. */
export function hariSew(n: number, res: Contact | null): number {
  if (res === null || res === 'parried' || res === 'kikon') return n;
  return Math.min(SJ.hariMax, n + (contactOf(res) === 'hit' ? SJ.hariSewHit : SJ.hariSewBlock));
}
/** The stitches one frame later: [n, idle, fell]. */
export function hariStep(n: number, idle: number, locked: boolean): [number, number, boolean] {
  if (n <= 0) return [0, 0, false];
  if (locked) return [n, idle, false];
  const i = Math.min(9999, idle + 1);
  return i >= SJ.hariIdle && (i - SJ.hariIdle) % SJ.hariFall === 0 ? [n - 1, i, true] : [n, i, false];
}
export const hariFallsIn = (idle: number): number =>
  idle < SJ.hariIdle ? SJ.hariIdle - idle : SJ.hariFall - ((idle - SJ.hariIdle) % SJ.hariFall);
export const kasaDamage = (caught: number): number => Math.min(SJ.kasaCap, SJ.kasaBase + Math.floor(caught / 2));
export const hankDamage = (n: number, passes: number): number => roundHalfEven(f32(f32(hankScale(passes)[2]) * hank(n, 'dmg')));
export const hankRadius = (n: number, passes: number): number => f32(f32(hankScale(passes)[0]) * f32(hank(n, 'r')));
export const hankLife = (n: number, passes: number): number =>
  roundHalfEven(f32(f32(f32(hankScale(passes)[1]) * f32(SJ.hankLifeMult)) * hank(n, 'life')));
const hankRadiusOr = (n: number, passes: number): number => (hank(n, 'r') != null ? hankRadius(n, passes) : f32(0.5 * hank(n, 'width')));

// ================================================================ Shikai 刺絡 SHIGARAMI (base)
defmove('sj-j1', { kind: 'quick', clip: 'sj-q1', startup: 7, active: 3, recovery: 12, dmg: 25, advBlock: -2,
  reach: 1.44, arc: 90, onHit: 'flinch', slide: 0.5 });             // HITOHARI
defmove('sj-j2', { kind: 'quick', clip: 'sj-q2', startup: 7, active: 3, recovery: 13, dmg: 25, advBlock: -2,
  reach: 1.44, arc: 110, onHit: 'flinch' });                        // KAESHINUI
defmove('sj-j3', { kind: 'quick', clip: 'sj-spin', startup: 8, active: 3, recovery: 18, dmg: 32, advBlock: -4,
  reach: 1.44, arc: 220, onHit: 'stagger', flags: ['ender'] });     // SENJU
defmove('sj-k1', { kind: 'flash', clip: 'sj-f1', startup: 17, active: 4, recovery: 20, dmg: 48, advBlock: -3,
  vol: ['cap', 0.3, 2.9, 1.1, 0.3], onHit: 'stagger' });            // MACHIBARI
defmove('sj-k2', { kind: 'flash', clip: 'sj-f2', enter: 7, startup: 21, active: 4, recovery: 24, dmg: 40, advBlock: -3,
  reach: 2.5, arc: 140, onHit: 'stagger' });                        // MATSURI
defmove('sj-k3', { kind: 'flash', clip: 'sj-drop', enter: 7, startup: 21, active: 5, recovery: 34, dmg: 59, advBlock: -20,
  reach: 2.5, arc: 160, height: [0.0, 1.4], onHit: 'crumple', flags: ['ender'] });   // KUKE
defmoveCopy('sj-j2s', 'sj-j2');
defmoveCopy('sj-k2s', 'sj-k2');
// L 悪い癖 WARUI KUSE: refused at 0 stitches; frame 0 spends them all (senju-warui-kuse)
defmove('sj-warui-kuse', { kind: 'sig', clip: 'sj-yank', callout: 'WARUI KUSE', startup: 8, active: 0, recovery: 24,
  onFrame: [[0, 'senju-warui-kuse']], params: { first: 10 } });
defmoveCopy('sj-warui-kuse-k', 'sj-warui-kuse', { startup: 6, clipS: 8, reach: 9.0, params: { first: 8 } });
// Shift+K SP1 神兵 SHINPEI: a tapestry (f8), the Divine Soldier (f10)
defmove('sj-shinpei', { kind: 'sp', clip: 'sj-summon', clipS: 16, callout: 'SHINPEI', startup: 10, active: 0, recovery: 10,
  onFrame: [[8, 'senju-tapestry'], [10, 'senju-shinpei']] });
// Shift+L SP2 傘 KASA: f4-27 a guard for melee, a catch for hazards / ranged hits; f28 the tendrils always fire
defmove('sj-kasa', { kind: 'sp', clip: 'sj-kasa', callout: 'KASA', startup: 4, active: 24, recovery: 18, flags: ['shield'],
  onFrame: [[0, 'senju-kasa-open'], [28, 'senju-kasa-fire']],
  params: { catch: 'senju-kasa-catch', speed: 16.0, range: 10.0, width: 1.6, guard: 14 } });
defmove('sj-breaker', { kind: 'breaker', clip: 'sj-breaker', clip2: 'sj-saidan', callout: 'SAIDAN' });
// O, the Kikon module 縫地 NUICHI: aura 6, a flash step 26 m/s for <= 14 f, the whirl of hands (it sews)
defmove('sj-kikon', { kind: 'kikon', clip: 'sh-run', clip2: 'sj-spin', callout: 'SHITATE-NAOSHI', cine: 'sj-kikon-cine',
  startup: 8, active: 3, recovery: 24, dmg: 70, advBlock: -14, reach: 2.4, arc: 200, onHit: 'knockback', kb: 2.5, cooldown: 90,
  onFrame: [[7, 'senju-nuichi-threads']],
  params: { aura: 6, aim: 120.0, speed: 26.0, dashMax: 14, dashTrack: 0.0, look: 'flash-step', sfx: 'hoho-out' } });

// ================================================================ 娑闥迦羅骸刺絡辻 SHIGARAMI NO TSUJI (the six hank forms)
defmove('sj-t-k1', { kind: 'flash', clip: 'sj-tanmono', startup: 17, active: 4, recovery: 20, dmg: 45, advBlock: -3,
  vol: ['cap', 0.3, 3.8, 1.1, 0.3], onHit: 'stagger' });            // TANMONO-UCHI
defmove('sj-t-k3', { kind: 'flash', clip: 'sj-makitori', enter: 7, startup: 21, active: 5, recovery: 34, dmg: 58, advBlock: -20,
  reach: 2.5, arc: 160, height: [0.0, 1.4], onHit: 'crumple', flags: ['ender'], params: { pull: 1.4 } });   // MAKITORI
// L 綛解かば KASE TOKABA: held >= weaveTap f it weaves; let go, the weave stops; a tap releases. -k: after a K link (the
// combo cut): no hold, the stored passes, S 8, unfold 10
function defKase(n: number, tell: [number, number] | null, tellK: [number, number] | null): void {
  defmove(`sj-kase-${n}`, { kind: 'sig', clip: 'sj-weave', clip2: 'sj-unravel', callout: HANKS[n].name, hold: [1, 600],
    startup: 6, active: 0, recovery: 22, tick: 'senju-weave-tick', release: 'senju-weave-release', onFrame: [[6, 'senju-unravel']],
    flags: ['bind'], params: { hank: n, tell } });
  defmoveCopy(`sj-kase-${n}-k`, `sj-kase-${n}`, { hold: undefined, tick: undefined, release: undefined, startup: 8, clip: 'sj-unravel',
    clipS: 6, reach: 9.0, onFrame: [[0, 'senju-combo-cut'], [8, 'senju-unravel']], params: { hank: n, combo: true, tell: tellK } });
}
defKase(1, null, null);                    // 眼: no hit of its own
defKase(2, [34, 44], [10, 22]);            // 刃金
defKase(3, [60, 80], [10, 22]);            // 黒砂
defKase(4, [18, 30], [10, 22]);            // 褥
defKase(5, [18, 30], [10, 22]);            // 焼野原
defKase(6, null, null);                    // 星: no hit
// J -> L 一越 HITOKOSHI: +1 pass on the form's hank at f8, never a release
defmove('sj-hitokoshi', { kind: 'sig', clip: 'sj-weave', startup: 8, active: 0, recovery: 10, onFrame: [[8, 'senju-quick-weave']] });
// the weave let go: 6 f back to the loom stance
defmove('sj-weave-stop', { kind: 'sig', clip: 'sj-loom-stance', startup: 1, active: 0, recovery: 5, whiff: 5 });
// Shift+K SP1 裁ち直し TACHINAOSHI: f0 cuts the live zone(s), f8 and f14 release the next two hanks (one copy per form)
defmove('sj-tachinaoshi', { kind: 'sp', clip: 'sj-snip', clipS: 16, callout: 'TACHINAOSHI', startup: 8, active: 0, recovery: 22,
  reach: 9.0, flags: ['bind'], onFrame: [[0, 'senju-combo-cut'], [8, 'senju-tachi-release'], [14, 'senju-tachi-release']] });
const TACHI_TELL: ([number, number] | null)[] = [null, [10, 22], [10, 22], [10, 22], [10, 22], [16, 28]];
TACHI_TELL.forEach((tell, i) => defmoveCopy(`sj-tachinaoshi-${i + 1}`, 'sj-tachinaoshi', { params: { tell } }));
// O, the Kikon module 浮文機 UKIMON NO HATA: the red carpet along a locked lane 8.5 m (no dash)
defmove('sj-t-kikon', { kind: 'kikon', clip: 'sj-loom-stance', clip2: 'sj-unravel', clipS: 6, callout: 'SHIDE NO ROKUSHIKI UKIMON NO HATA',
  cine: 'sj-hata-cine', startup: 20, active: 3, recovery: 30, whiff: 30, dmg: 70, advBlock: -14, track: 0, vol: ['cap', 0.5, 8.5, 1.2, 1.2],
  onHit: 'knockback', kb: 2.0, cooldown: 90, onFrame: [[4, 'senju-carpet']],
  params: { aura: 8, aim: 120.0, speed: 0.0, dashMax: 0, dashTrack: 0.0, look: 'lane', followSpeed: 14.0 } });

// ================================================================ forms
const SENJU_METER = { name: 'HARI', max: 6, start: 0 };   // (the Lisp's :draw / :label: senjuMeter below)
const SENJU_HOOKS = { tick: 'senju-tick', ok: 'senju-ok', hit: 'senju-hit', struck: 'senju-struck', siphon: 'senju-siphon' };

defkit('senjumaru', 'base', {
  name: 'SENJUMARU', body: 'senjumaru', weapon: 'shigarami', stance: 'sj-stance', calm: true,
  intro: 'sj-intro', win: 'sj-win', introCallout: 'SHIGARAMI',
  walk: SJ.walkSenju, run: SJ.runSenju, reishi: T.reishiMax, swingSfx: 'whoosh-light', mult: SJ.senjuMult, taken: SJ.senjuTaken,
  stunTolerance: 13.0,
  commands: { q: 'sj-j1', f: 'sj-k1', sig: 'sj-warui-kuse', sp1: 'sj-shinpei', sp2: 'sj-kasa', breaker: 'sj-breaker', kikon: 'sj-kikon' },
  grid: ['sj-j1', 'sj-j2', 'sj-j3', 'sj-k1', 'sj-k2', 'sj-k3', 'sj-j2s', 'sj-k2s'],
  lAfterK: 'sj-warui-kuse-k',
  awakenForm: 'tsuji3', resetForm: 'base',
  meter: SENJU_METER, hooks: SENJU_HOOKS,
  ai: { intents: { approach: 2, pressure: 4, zone: 0, defend: 1 },
        ranges: { approach: [2.4, 5.0], pressure: [1.0, 1.9], zone: [5.0, 8.0], defend: [3.0, 5.0] },
        moves: [[0.0, 1.7, 'q', 6, 'f', 2, 'breaker', 1],
                [1.7, 2.6, 'f', 4, 'breaker', 1],
                [2.6, 6.0, 'sp1', 2, 'kikon', 1, 'step', 1, null, 1],
                [6.0, 99.0, 'sp1', 2, 'kikon', 2, null, 1]],
        guard: 0.4, hoho: 0.3, dash: 0.7, dashBack: 0.1, blockString: 0.8, oEnder: 0.3, lAfterK: 0.3, spCancelBars: 9,
        kikonRange: 7.7, react: { projectile: 'sp2' },
        awaken: { minTaken: 150 }, awakenAbove: 1.01,
        hari: { min: 4, hurry: 40 }, reflex: 'senju-ai-reflex', assistGuard: 'senju-loom-anti-breaker', sigHold: 'senju-sig-hold',
        spEnder: 'senju-base-ender' },
});

const TSUJI_AI = {
  intents: { approach: 1, pressure: 1, zone: 4, defend: 2 },
  ranges: { approach: [2.6, 5.0], pressure: [1.0, 2.4], zone: [5.0, 8.0], defend: [4.0, 6.0] },
  moves: [[0.0, 1.7, 'q', 3, 'f', 2, 'breaker', 1, 'step', 2],
          [1.7, 2.8, 'f', 3, 'breaker', 1, 'step', 2],
          [2.8, 4.0, 'f', 2, 'step', 2, null, 1],
          [4.0, 5.0, 'f', 1, 'sig', 2, 'step', 1, null, 1],
          [5.0, 9.0, 'sig', 5, 'kikon', 1, null, 1],
          [9.0, 99.0, 'sig', 2, null, 2]],
  guard: 0.45, hoho: 0.35, dash: 0.2, dashBack: 0.6, oEnder: 0.2, lAfterK: 0.3, lAfterJ: 0.35, spCancelBars: 9,
  kikonRange: 8.5, react: { projectile: 'sp2' }, weave: { far: 6.5, near: 4.0 }, spEnder: 'senju-sp-ender',
  oppRushHold: 0.5, oppReflex: 'senju-opp-reflex', reflex: 'senju-ai-reflex', assistGuard: 'senju-loom-anti-breaker',
  sigHold: 'senju-sig-hold',
};

defkit('senjumaru', 'tsuji1', {
  inherit: 'base', awakening: true, formName: 'TSUJI', walk: SJ.walkTsuji, run: SJ.runTsuji,
  mult: SJ.tsujiMult, taken: SJ.tsujiTaken, resetForm: null, stance: 'sj-loom-stance', aura: 'senju-aura-tsuji', cine: 'sj-tsuji-cine',
  commands: { f: 'sj-t-k1', sig: 'sj-kase-1', sp1: 'sj-tachinaoshi-1', sp2: 'sj-kasa', breaker: 'sj-breaker', kikon: 'sj-t-kikon' },
  grid: ['sj-j1', 'sj-j2', 'sj-j3', 'sj-t-k1', 'sj-k2', 'sj-t-k3', 'sj-j2s', 'sj-k2s'],
  lAfterK: 'sj-kase-1-k', lAfterJ: 'sj-hitokoshi', meter: SENJU_METER, ai: TSUJI_AI,
});
for (let n = 2; n <= 6; n++)
  defkit('senjumaru', `tsuji${n}`, { inherit: 'tsuji1', commands: { sig: `sj-kase-${n}`, sp1: `sj-tachinaoshi-${n}` }, lAfterK: `sj-kase-${n}-k` });

// ================================================================ per-fighter state (on Fighter.char: a new fighter, a fresh one)
export class Sjs {
  caught = 0;                       // the umbrella's largest caught hit
  soldier: Hazard | null = null; live: Hazard | null = null; bolt: Hazard | null = null;
  liveHank = 0; liveLife = 1;       // the live zone's hank and life (the HUD's drain)
  live2: Hazard | null = null;      // TACHINAOSHI's first zone while its second is the live one
  woven = 0;                        // frames woven on the form's hank
  tachi = 0;                        // TACHINAOSHI: the woven frames both its hanks release at
  torn = -9999; tornHank = 0;       // tick of the last torn hank, and which
}
export const sj = (e: Ent): Sjs => (e.f.char ??= new Sjs()) as Sjs;

/** Her hazards' data (HAZARD-DATA). */
export interface Sjh {
  kind: string;                     // spike soldier thrust bolt zone gulp maiden follow look
  hank: number; passes: number; r: number; len: number; x0: number; z0: number;
  clock: number; n: number; phase: string | number | null; vol: Vol | null; link: Hazard | null;
  combo: boolean;                   // a zone of the combo cut: 刃金 closes and 黒砂 gulps at the unfold's end
}
const sjh = (o: Partial<Sjh>): Sjh =>
  ({ kind: 'look', hank: 0, passes: 1, r: 0, len: 0, x0: 0, z0: 0, clock: 0, n: 0, phase: null, vol: null, link: null, combo: false, ...o });
const alive = (h: Hazard | null): h is Hazard => !!h && h.alive;
const destroy = (h: Hazard | null): void => { if (h) h.alive = false; };

function senjuSpawn(kind: string, owner: Ent, data: Sjh, o: HazardOpts): Hazard {
  return spawnHazard(kind, owner, { ...o, hook: 'senju-hz', data });
}
/** A look-only hazard (kind fx) the renderer draws by LOOK; FOLLOW: it stays on its owner. */
function senjuLook(e: Ent, look: string, x: number, z: number,
                   o: { yaw?: number; size?: number; life?: number; delay?: number; follow?: boolean } = {}): Hazard {
  return senjuSpawn('fx', e, sjh({ kind: o.follow ? 'follow' : 'look' }),
    { x, z, yaw: o.yaw ?? 0, size: o.size ?? 1.0, life: o.life ?? 30, delay: o.delay ?? 0, look });
}

// ================================================================ the stitches (the Shikai's meter: the kit meter holds the count)
const hari = (e: Ent): number => roundHalfEven(e.g.meter);
const setHari = (e: Ent, n: number): void => { e.g.meter = n; };
const hariFormP = (e: Ent): boolean => e.f.form === 'base';

function senjuPull(e: Ent, tx: number, tz: number, d: number, frames: number): void {
  const p = e.pos, dx = f32(tx - p[0]), dz = f32(tz - p[2]), l = len32(dx, dz);
  if (l > f32(d + f32(0.05))) setSlide(e, f32(l - d), frames, dx, dz);
}

// ================================================================ the loom
const senjuStored = (e: Ent): number => weaveStored(sj(e).woven);
export const senjuLiveZones = (e: Ent): Hazard[] => { const st = sj(e); return [st.live, st.live2].filter(alive); };
function senjuLiveZone(e: Ent, n: number): Hazard | null {
  return senjuLiveZones(e).find((z) => z.delay <= 0 && (z.data as Sjh).hank === n) ?? null;
}
function senjuCutLive(e: Ent): boolean {
  const st = sj(e), any = senjuLiveZones(e).length > 0;
  destroy(st.live); destroy(st.live2);
  return any;
}
function senjuTorn(e: Ent, hankN: number, advance: boolean): void {
  const f = e.f, st = sj(e);
  st.torn = W.tick; st.tornHank = hankN;
  const fh = formHank(f.form);
  if (advance && fh != null) {
    const [next, woven] = weaveVoid(fh);
    st.woven = woven;
    setForm(e, hankForm(next));
  } else f.cd[KIT_COMMANDS.indexOf('sig')] = SJ.tornLock;             // L locked (its cooldown timer)
  emit('sfx', 'shears', e);
  clog(() => `${sideName(e)} TORN hank ${hankN}`);
}
/** Hank N unravels as her live zone at the cast point under him; the form advances past it. */
function senjuCast(e: Ent, n: number, passes: number, unfold: number): void {
  const st = sj(e), p = e.pos, q = oppOf(e).pos;
  const [cx, cz] = castPoint(p[0], p[2], q[0], q[2], SJ.hankRange);
  const z = senjuZone(e, n, passes, unfold, cx, cz);
  st.live = z; st.liveHank = n; st.liveLife = Math.max(1, z.life);
  setForm(e, hankForm(hankNext(n)));
  st.woven = 0;
  emit('sfx', 'cloth-unfurl', e);
}
/** Hank N's zone at (CX CZ) after PASSES, unfolding UNFOLD frames (fragile). */
function senjuZone(e: Ent, n: number, passes: number, unfold: number, cx: number, cz: number): Hazard {
  const r = hankRadiusOr(n, passes), life = hank(n, 'life') != null ? hankLife(n, passes) : 999;
  const dmg = hank(n, 'dmg') != null ? hankDamage(n, passes) : 0;
  const d = sjh({ kind: 'zone', hank: n, passes, r: f32(r), x0: cx, z0: cz, phase: unfold, combo: unfold < SJ.unfold });
  const p = e.pos;
  switch (n) {
    case 4:
      return senjuSpawn('freeze', e, d, { x: cx, z: cz, size: r, y: 0.6, delay: unfold, life, src: true, fragile: true, look: 'senju-zone-look',
        hw: makeHitwin({ dmg, react: 'bind', stun: roundHalfEven(hankFx(4, 'freeze', passes)), hs: T.hitstopHeavy, guard: 12,
                         frost: roundHalfEven(hankFx(4, 'frost', passes)), flags: ['ice'] }) });
    case 5: {
      const q = oppOf(e).pos, yaw = faceYawTo(e, q[0], q[2]);
      const dist = len32(f32(q[0] - p[0]), f32(q[2] - p[2]));
      const len = Math.min(hank(5, 'max'), f32(0.5 + dist)), mid = f32(1.0 + f32(0.5 * len));   // from 1 m ahead of her, past him
      d.len = len; d.x0 = f32(p[0] + fwdX(yaw)); d.z0 = f32(p[2] + fwdZ(yaw));
      return senjuSpawn('sj-lane', e, d, { x: f32(p[0] + f32(mid * fwdX(yaw))), z: f32(p[2] + f32(mid * fwdZ(yaw))), yaw,
        size: f32(0.5 * hank(5, 'width')),
        delay: unfold, life, hits: hank(5, 'hits'), src: true, fragile: true, look: 'senju-zone-look',
        hw: makeHitwin({ dmg, react: 'stagger', hs: T.hitstopHeavy, guard: 12, chip: hankFx(5, 'chip', passes) }) });
    }
    case 6:
      d.x0 = p[0]; d.z0 = p[2];
      return senjuSpawn('sj-zone', e, d, { x: p[0], z: p[2], size: r, delay: unfold, life, src: true, fragile: true, look: 'senju-zone-look' });
    default:
      return senjuSpawn('sj-zone', e, d, { x: cx, z: cz, size: r, delay: unfold, life, src: true, fragile: true, look: 'senju-zone-look' });
  }
}

// ---------------------------------------------------------------- the hazards' steps
/** Does one of O's open melee windows, or one of his active hazards, touch the soldier's cylinder at (X Z)? */
function senjuFrailHitP(o: Ent, x: number, z: number): boolean {
  const f = o.f, mv = f.move;
  if (f.state === 'move' && f.phase === 'main' && mv) {
    const sf = f.sf, p = o.pos, fx = fwdX(o.yaw), fz = fwdZ(o.yaw);
    if (mv.hits.some((w) => w.from <= sf && sf < w.to && w.vols.some((v) => volHitP(v, p[0], p[1], p[2], fx, fz, x, 0, z, 0.4, 1.8, 0))))
      return true;
  }
  return W.hazards.some((hz) => hz.alive && hz.owner === o && hazardActiveP(hz) && hazardTouchesP(hz, x, 0, z, 0.4, 1.8));
}

/** The soldier winds up its string's hit d.n at him: it turns to him and spawns the hit waiting that long. */
function senjuShinpeiStrike(e: Ent, hz: Hazard, d: Sjh, dx: number, dz: number): void {
  const [wind, , , vol, dmg, react, stun] = SHINPEI_COMBO[d.n];
  const yaw = dirYaw(dx, dz);
  hz.yaw = yaw;
  d.link = senjuSpawn('sj-hit', e, sjh({ kind: 'thrust', vol: makeVol(vol) }), { x: hz.x, z: hz.z, yaw, delay: wind, life: 2, src: true,
    hw: makeHitwin({ dmg, react, stun, hs: T.hitstopHeavy, guard: 14, flags: ['thread'] }) });
}

/** The soldier, each step: frail first, then rise / walk / its string / fade. True: it is gone. */
function senjuSoldierStep(hz: Hazard, d: Sjh): boolean {
  const e = hz.owner, o = hazardTarget(hz);
  if (!e.alive || !o || !o.alive) return false;
  if (d.phase !== 'fade' && senjuFrailHitP(o, hz.x, hz.z)) {
    destroy(d.link);
    if (hariFormP(e)) { setHari(e, Math.min(SJ.hariMax, hari(e) + 1)); e.g.meterIdle = 0; }   // it bursts into thread: a stitch
    senjuLook(e, 'senju-burst-look', hz.x, hz.z, { size: 1.0, life: 30 });
    emit('sfx', 'needle-burst', e);
    clog(() => `${sideName(e)} SHINPEI destroyed`);
    hz.alive = false;
    return true;
  }
  const q = o.pos, dx = f32(q[0] - hz.x), dz = f32(q[2] - hz.z), dist = len32(dx, dz);
  d.clock++;
  switch (d.phase) {
    case 'rise':
      if (d.clock >= SJ.shinpeiRise) { d.phase = 'walk'; d.clock = 0; }
      break;
    case 'walk':
      hz.yaw = angleWrap(turnToward(hz.yaw, dirYaw(dx, dz), trackStep(SJ.shinpeiTurn)));
      if (dist <= SJ.shinpeiNear) { d.phase = 'tell'; d.clock = 0; d.n = 0; senjuShinpeiStrike(e, hz, d, dx, dz); }
      else {
        const s = f32(SJ.shinpeiSpeed * f32(STEP)), yaw = hz.yaw;
        [hz.x, hz.z] = clampToCircle(f32(hz.x + f32(s * fwdX(yaw))), f32(hz.z + f32(s * fwdZ(yaw))), f32(T.arenaRadius - f32(0.4)));
      }
      break;
    case 'tell':
      if (d.clock >= SHINPEI_COMBO[d.n][0]) {                         // this hit lands: wind up the next
        d.n++; d.clock = 0;
        if (d.n < SHINPEI_COMBO.length) senjuShinpeiStrike(e, hz, d, dx, dz); else d.phase = 'fade';
      }
      break;
    case 'fade':
      if (d.clock >= 42) { hz.alive = false; return true; }
      break;
  }
  return false;
}

/** The weave's bolt: in her hands while she weaves (the hold, then the S frames before the unravel); gone otherwise. */
function senjuBoltStep(hz: Hazard): boolean {
  const e = hz.owner, f = e.alive ? e.f : null, mv = f ? f.move : null;
  if (f && f.state === 'move' && mv && mv.params.hank && (f.phase === 'hold' || (f.phase === 'main' && f.sf < mv.s))) {
    hz.x = e.pos[0]; hz.z = e.pos[2]; hz.yaw = e.yaw;
    return false;
  }
  hz.alive = false;
  return true;
}

/** A zone, each step once unfolded: 眼 turns his waves back; 刃金 closes once; 黒砂 drags and gulps; 褥 / 焼野原 end once
 *  spent; 星 drains his Reiatsu and flash-step into hers. */
function senjuZoneStep(hz: Hazard, d: Sjh): boolean {
  const e = hz.owner, o = hazardTarget(hz), n = d.hank, age = hz.age;
  if (hz.delay > 0 || !o || !o.alive) return false;
  const q = o.pos, dx = f32(q[0] - hz.x), dz = f32(q[2] - hz.z), dist = len32(dx, dz), inside = dist <= d.r;
  switch (n) {
    case 1:                                                          // the mirror-eyes: his waves / fireballs turn back
      for (const wz of W.hazards)
        if (wz.alive && wz.owner === o && (wz.kind === 'wave' || wz.kind === 'fireball') && wz.hitsLeft > 0
            && sq32(f32(wz.x - hz.x), f32(wz.z - hz.z)) <= sq32(f32(d.r + wz.size), 0)) {
          wz.owner = e; wz.yaw = angleWrap(wz.yaw + PI); wz.src = false;
          emit('sfx', 'shears', e);
          clog(() => `${sideName(e)} ME reflects a ${wz.kind}`);
        }
      break;
    case 2:                                                          // the maiden closes: once (the combo cut: at once)
      if (age === (d.combo ? 0 : hank(2, 'rise'))) {
        senjuSpawn('freeze', e, sjh({ kind: 'maiden', hank: 2 }), { x: hz.x, z: hz.z, size: d.r, y: 2.2, life: 2, src: true,
          hw: makeHitwin({ dmg: hankDamage(2, d.passes), react: 'crumple', hs: T.hitstopHeavy,
                           guard: roundHalfEven(hankFx(2, 'guard', d.passes)), flags: ['thread'] }) });
        hz.life = age + hank(2, 'after');
        emit('sfx', 'ground-crack', e);
      }
      break;
    case 3: {
      const st = o.f.state;
      if (inside && (st === 'idle' || st === 'run')) {               // the drag: walking / running away
        const v = o.mo.vel, l = Math.max(dist, f32(1e-3)), ux = f32(dx / l), uz = f32(dz / l), along = f32(f32(v[0] * ux) + f32(v[2] * uz));
        if (along > 0) {
          const k = f32(f32(Math.min(1.0, f32(hankScale(d.passes)[3] * f32(1.0 - hank(3, 'away')))) * along) * f32(STEP));
          q[0] = f32(q[0] - f32(k * ux)); q[2] = f32(q[2] - f32(k * uz));
        }
      }
      const period = hank(3, 'period');                              // the gulps: 1 / 2 / 3 by passes, a swirl before each
      if (d.n < d.passes && age === (d.combo ? 0 : period * (d.n + 1) - hank(3, 'swirl'))) {
        d.n++;
        senjuSpawn('freeze', e, sjh({ kind: 'gulp', hank: 3, x0: hz.x, z0: hz.z }), { x: hz.x, z: hz.z, size: d.r, y: 1.8,
          delay: d.combo ? 0 : hank(3, 'swirl'), life: 2, src: true,
          hw: makeHitwin({ dmg: hankDamage(3, d.passes), react: 'stagger', hs: T.hitstopHeavy, guard: 12, flags: ['thread'] }) });
        emit('sfx', 'ground-crack', e);
      }
      break;
    }
    case 4: case 5:
      if (hz.hitsLeft <= 0) { hz.alive = false; return true; }        // spent: the loom is free
      break;
    case 6:
      if (inside) {                                                  // the star drains him into her
        const g = o.g, mine = e.g;
        [g.reiatsu, mine.reiatsu] = gaugeMove(g.reiatsu, f32(hankFx(6, 'reiatsu', d.passes) / 60), mine.reiatsu, T.reiatsuMax).map(f32);
        [g.fs, mine.fs] = gaugeMove(g.fs, f32(hankFx(6, 'fs', d.passes) / 60), mine.fs, T.fsMax).map(f32);
      }
      break;
  }
  return false;
}

// ================================================================ hooks
registerHooks({
  /** Her hazards' hook: step / close / touches by the data's kind. */
  'senju-hz'(hz: Hazard, ev: string, tx: number, ty: number, tz: number, tr: number, th: number): boolean {
    const d = hz.data as Sjh;
    switch (ev) {
      case 'step':
        switch (d.kind) {
          case 'spike': case 'follow': {                             // stuck to him / her
            const tg = d.kind === 'spike' ? hazardTarget(hz) : hz.owner;
            if (tg && tg.alive) { hz.x = tg.pos[0]; hz.z = tg.pos[2]; }
            return false;
          }
          case 'soldier': return senjuSoldierStep(hz, d);
          case 'bolt': return senjuBoltStep(hz);
          case 'zone': return senjuZoneStep(hz, d);
          default: return false;
        }
      case 'close': {                                                // a real hit on her: a weave's bolt or an unfolding zone is torn
        const e = hz.owner;
        if (e.alive) {
          if (d.kind === 'bolt') senjuTorn(e, d.hank, true);
          else if (d.kind === 'zone') senjuTorn(e, d.hank, false);
        }
        return false;
      }
      case 'touches':
        if (hz.kind === 'sj-hit') return volHitP(d.vol!, hz.x, 0, hz.z, fwdX(hz.yaw), fwdZ(hz.yaw), tx, ty, tz, tr, th, 0);
        if (hz.kind === 'sj-lane') return oboxCylHitP(hz.x, 1, hz.z, hz.yaw, hz.size, 1.2, f32(0.5 * d.len), tx, ty, tz, tr, th);
        return false;
    }
    return false;
  },

  /** Per step: the stitches fall out after hariIdle frames without a new one (paused while locked). */
  'senju-tick'(e: Ent, f: Fighter, g: Gauges) {
    if (f.form === 'base') {
      const [n, idle, fell] = hariStep(hari(e), g.meterIdle, f.lock > 0);
      g.meter = n; g.meterIdle = idle;
      if (fell) clog(() => `${sideName(e)} stitch fell, ${n} left`);
    }
  },
  /** Her kit's refusals: the Shikai's L at 0 stitches; the Bankai's K -> L with no pass stored. */
  'senju-ok'(e: Ent, command: string, combo: Move | null): boolean {
    if (command !== 'sig') return true;
    if (hariFormP(e)) return hari(e) >= 1;
    return loomOkP(command, combo, sj(e).woven);
  },
  /** After a hit she dealt: her own J / K / O window's contact sews (the Shikai); MAKITORI hauls him in; a gulp pulls
   *  him to the pit's centre. */
  'senju-hit'(att: Ent, def: Ent, res: Contact, _hw: HitWin, mv: Move | null, hazard: Hazard | null, ranged: boolean) {
    const hit = res === 'hit' || res === 'counter';
    if (mv && !hazard && !ranged && att.f.move === mv && (mv.kind === 'quick' || mv.kind === 'flash' || mv.kind === 'kikon')
        && hariFormP(att)) {
      const n = hariSew(hari(att), res);
      if (n > hari(att)) { setHari(att, n); att.g.meterIdle = 0; emit('sfx', 'thread-zip', att); }
    }
    if (hit && mv && mv.params.pull) senjuPull(def, att.pos[0], att.pos[2], mv.params.pull, 8);   // MAKITORI: hauled in
    if (hazard && hit && hazard.hook === 'senju-hz') {
      const d = hazard.data as Sjh;
      if (d.kind === 'gulp') senjuPull(def, d.x0, d.z0, 0.0, 10);
    }
  },
  /** After a hit she took: 眼's mirror: each of his melee contacts on her inside her live ring burns him mirrorK of it. */
  'senju-struck'(def: Ent, att: Ent, res: Contact, hw: HitWin, mv: Move | null, hazard: Hazard | null, ranged: boolean) {
    const z = senjuLiveZone(def, 1), c = contactOf(res);
    if (mv && !hazard && !ranged && (c === 'hit' || c === 'block') && z && z.delay <= 0) {
      const q = att.pos;
      if (sq32(f32(q[0] - z.x), f32(q[2] - z.z)) <= sq32(z.size, 0)) {
        const n = roundHalfEven(f32(f32(f32(SJ.mirrorK) * f32(hankScale((z.data as Sjh).passes)[3])) * hw.dmg));
        if (n > 0) {
          att.g.reishi = burn(att.g.reishi, n);
          emit('sfx', 'needle-burst', att);
          clog(() => `${sideName(att)} mirror ${n}`);
        }
      }
    }
  },
  /** O stands in her live 星, unfolded: he gains nothing, his Reiatsu / flash-step gains are hers. */
  'senju-siphon'(e: Ent, o: Ent): boolean {
    const z = senjuLiveZone(e, 6);
    return !!z && sq32(f32(o.pos[0] - z.x), f32(o.pos[2] - z.z)) <= sq32((z.data as Sjh).r, 0);
  },

  // ---------------------------------------------------------------- 悪い癖 WARUI KUSE
  /** L f0: every stitch spent; one spike per stitch stuck to him, the first at :first, then one every hariGap. */
  'senju-warui-kuse'(e: Ent) {
    const n = hari(e), q = oppOf(e).pos, first = moveParam(e, 'first');
    setHari(e, 0);
    for (let i = 0; i < n; i++)
      senjuSpawn('freeze', e, sjh({ kind: 'spike' }), { x: q[0], z: q[2], size: 0.3, y: 2.0, delay: first + i * SJ.hariGap, life: 2,
        look: 'senju-spike-look',
        hw: makeHitwin({ dmg: SJ.hariDmg, react: 'flinch', stun: i === n - 1 ? SJ.hariLastStun : SJ.hariStun, hs: 3,
                         flags: ['unguardable', 'ranged', 'spare', 'thread'] }) });
    emit('sfx', 'thread-zip', e);
    clog(() => `${sideName(e)} WARUI KUSE ${n}`);
  },

  // ---------------------------------------------------------------- 神兵 SHINPEI
  'senju-tapestry'(e: Ent) {
    const [x, z, yaw] = shinpeiPoint(e);
    senjuLook(e, 'senju-tapestry-look', x, z, { yaw, size: 1.0, life: 40 });
    emit('sfx', 'cloth-unfurl', e);
  },
  /** SP1 f10: the Divine Soldier (a new one replaces the old). */
  'senju-shinpei'(e: Ent) {
    const st = sj(e);
    destroy(st.soldier);
    const [x, z, yaw] = shinpeiPoint(e);
    st.soldier = senjuSpawn('soldier', e, sjh({ kind: 'soldier', phase: 'rise' }), { x, z, yaw, size: 0.4, life: SJ.shinpeiLife,
      look: 'senju-soldier-look' });
    clog(() => `${sideName(e)} SHINPEI`);
  },

  // ---------------------------------------------------------------- 傘 KASA
  'senju-kasa-open'(e: Ent) {
    sj(e).caught = 0;
    senjuLook(e, 'senju-kasa-look', e.pos[0], e.pos[2], { yaw: e.yaw, size: 1.2, life: 28, follow: true });
    emit('sfx', 'cloth-unfurl', e);
  },
  /** A hazard or a ranged hit blocked in the umbrella's window: the largest one is kept for the tendrils. */
  'senju-kasa-catch'(def: Ent, dmg: number) {
    const st = sj(def);
    st.caught = Math.max(st.caught, dmg);
    emit('sfx', 'thread-zip', def);
    clog(() => `${sideName(def)} KASA caught ${dmg}`);
  },
  /** SP2 f28: the tendrils always fire: a wave at him, kasaBase + half the largest caught hit. */
  'senju-kasa-fire'(e: Ent) {
    const q = oppOf(e).pos, yaw = faceYawTo(e, q[0], q[2]), speed = moveParam(e, 'speed'), dmg = kasaDamage(sj(e).caught), p = e.pos;
    spawnHazard('wave', e, { x: f32(p[0] + fwdX(yaw)), z: f32(p[2] + fwdZ(yaw)), yaw, speed, size: f32(0.5 * moveParam(e, 'width')),
      life: roundHalfEven(f32(60 * f32(moveParam(e, 'range') / speed))), look: 'senju-tendril-look',
      hw: makeHitwin({ dmg, react: 'stagger', hs: T.hitstopHeavy, guard: moveParam(e, 'guard'), flags: ['ranged', 'thread'] }) });
    emit('sfx', 'thread-zip', e);
    clog(() => `${sideName(e)} KASA fires ${dmg}`);
  },

  // ---------------------------------------------------------------- NUICHI / UKIMON NO HATA (looks)
  'senju-nuichi-threads'(e: Ent) {
    const q = oppOf(e).pos;
    senjuLook(e, 'senju-pin-look', q[0], q[2], { size: 1.0, life: 30 });
    emit('sfx', 'thread-zip', e);
  },
  'senju-carpet'(e: Ent) {
    senjuLook(e, 'senju-carpet-look', e.pos[0], e.pos[2], { yaw: e.yaw, size: 8.5, life: 40 });
    emit('sfx', 'cloth-unfurl', e);
  },

  // ---------------------------------------------------------------- the loom
  /** L held: from weaveTap frames on it is a weave: the woven frames grow, the bolt (fragile) is between her hands. */
  'senju-weave-tick'(e: Ent) {
    const f = e.f, h = f.hold, st = sj(e);
    if (f.phase === 'hold' && h >= SJ.weaveTap) {
      if (h === SJ.weaveTap) {
        destroy(st.bolt);
        st.bolt = senjuSpawn('fx', e, sjh({ kind: 'bolt', hank: moveParam(e, 'hank') }), { x: e.pos[0], z: e.pos[2], yaw: e.yaw,
          size: 1.0, life: 10000, delay: 10000, fragile: true, look: 'senju-bolt-look' });
      }
      const w = st.woven, w2 = weaveAdd(w, h);
      st.woven = w2;
      if (weaveStored(w2) > weaveStored(w)) emit('sfx', 'shuttle', e);
    }
  },
  /** L let go: a tap with a pass stored goes on to the release; a weave stops; a refused tap stops with the cue. */
  'senju-weave-release'(e: Ent) {
    const f = e.f, st = sj(e), act = weaveReleaseAct(f.hold, st.woven, senjuLiveZones(e).length > 0);
    if (act !== 'release') {
      if (act === 'refused') {
        emit('refused', e, 'sig');
        clog(() => `${sideName(e)} refused L: ${senjuStored(e)} passes stored`);
      }
      destroy(st.bolt);
      startMove(e, findMove('sj-weave-stop'));
    }
  },
  /** HITOKOSHI f8 (J -> L): one pass onto the form's hank at once. */
  'senju-quick-weave'(e: Ent) {
    const st = sj(e), w2 = quickWeave(st.woven);
    st.woven = w2;
    emit('sfx', 'shuttle', e);
    clog(() => `${sideName(e)} HITOKOSHI ${weaveStored(w2)} passes`);
  },
  /** The combo cut's frame 0 (and TACHINAOSHI's): the live zones end (not torn). */
  'senju-combo-cut'(e: Ent) { senjuCutLive(e); },
  /** TACHINAOSHI's f8 / f14: the form's next hank unravels as the combo cut's does, at the passes stored when the move
   *  began; the second keeps the first alive beside it (live2). */
  'senju-tachi-release'(e: Ent) {
    const f = e.f, st = sj(e), n = formHank(f.form), second = f.sf > f.move!.s;
    if (n != null) {
      if (second) { st.live2 = st.live; st.live = null; } else st.tachi = st.woven;
      senjuCast(e, n, releasePasses(st.tachi), SJ.unfoldCombo);
      clog(() => `${sideName(e)} TACHINAOSHI hank ${n}`);
      callout(e, HANKS[n].name);
      playClip(e, 'sj-unravel', { blend: 0, time: 6 / 60.0 });
    }
  },
  /** L's release + S (or the combo cut's S): the bolt goes, the move's hank unravels, the form advances. */
  'senju-unravel'(e: Ent) {
    const st = sj(e), n = moveParam(e, 'hank'), combo = !!moveParam(e, 'combo');
    const passes = releasePasses(st.woven), unfold = combo ? SJ.unfoldCombo : SJ.unfold;
    destroy(st.bolt);
    senjuCutLive(e);
    senjuCast(e, n, passes, unfold);
    clog(() => `${sideName(e)} UNRAVEL hank ${n} passes ${passes}${combo ? ' (combo)' : ''}`);
  },
});

function shinpeiPoint(e: Ent): [number, number, number] {
  const p = e.pos, q = oppOf(e).pos, dx = f32(q[0] - p[0]), dz = f32(q[2] - p[2]);
  const d = Math.max(f32(0.01), len32(dx, dz)), k = Math.min(1.5, f32(0.5 * d));
  return [f32(p[0] + f32(k * f32(dx / d))), f32(p[2] + f32(k * f32(dz / d))), dirYaw(dx, dz)];
}

// ================================================================ the renderer's view of her HUD meter (hud.lisp's :draw)
/** What her kit-meter row shows: the Shikai's stitches (and the frames until the next falls), or the loom: the next hank,
 *  the passes stored on it, the live zones' life left (1 while unfolding), the last torn hank and its age, SP1's pair. */
export function senjuMeter(e: Ent) {
  const st = sj(e), g = e.g, next = formHank(e.f.form);
  if (next == null) return { mode: 'hari' as const, stitches: hari(e), fallsIn: hari(e) > 0 ? hariFallsIn(g.meterIdle) : null };
  return {
    mode: 'loom' as const, next, short: HANKS[next].short, order: HANK_ORDER, stored: weaveStored(st.woven),
    live: senjuLiveZones(e).map((z) => ({ hank: (z.data as Sjh).hank, left: z.delay > 0 ? 1 : Math.max(0, 1 - z.age / Math.max(1, z.life)) })),
    torn: { hank: st.tornHank, age: W.tick - st.torn, lock: SJ.tornLock },
    sp1: { aligned: tachiAlignedP(next), ready: Math.floor(g.reiatsu / T.reiatsuBar) >= kitCommandCost(kitOf(e), 'sp1') },
  };
}

// ================================================================ AI (the kit's reflex / oppReflex / sigHold / spEnder)
// Her CPU's policy chances by difficulty (senjumaru.lisp *SENJU-DP*: EASY <= NORMAL <= HARD).
const SENJU_DP: Record<string, Record<string, number>> = f32Deep({
  oEnderP: { easy: 0.0, normal: 0.05, hard: 0.85 }, lEnderP: { easy: 0.0, normal: 0.05, hard: 0.7 },
  punishP: { easy: 0.0, normal: 0.1, hard: 0.8 }, hariP: { easy: 0.0, normal: 0.1, hard: 0.85 },
  breakP: { easy: 0.3, normal: 0.4, hard: 0.7 }, antiBreakerP: { easy: 0.0, normal: 0.1, hard: 0.85 },
  neutralP: { easy: 0.0, normal: 0.0, hard: 0.7 }, followP: { easy: 0.0, normal: 0.15, hard: 0.9 },
  escortP: { easy: 0.0, normal: 0.1, hard: 0.8 }, okiP: { easy: 0.0, normal: 0.2, hard: 0.9 },
  tachiP: { easy: 0.3, normal: 0.5, hard: 0.9 }, awakenBelow: { easy: 1.0, normal: 1.0, hard: 0.28 },
  loomAntiBreakerP: { easy: 0.0, normal: 0.1, hard: 0.85 }, redRushP: { easy: 0.0, normal: 0.0, hard: 0.8 },
});
/** The Shikai's neutral bands of the policy (neutralP of the decisions). */
const SENJU_NEUTRAL: Band[] = f32Deep([[0.0, 1.7, 'q', 6, 'breaker', 2], [1.7, 2.6, 'breaker', 2, 'f', 1, null, 2], [2.6, 7.5, 'kikon', 1, 'sp1', 1, null, 3]]);
const senjuDp = (b: Brain, key: string): number => { const p = SENJU_DP[key]; return p[b.difficulty] ?? p.normal ?? 0.0; };
const snapDownP = (s: Snap): boolean => s.state === 'down' || s.state === 'wakeup' || s.state === 'hoho';

/** Frames her O rush MV takes to strike from D m: its aura, the dash to its strike reach, its startup. */
function senjuOArrive(mv: Move, d: number): number {
  return rushParam(mv, 'aura') + mv.s
    + (rushParam(mv, 'speed') > 0 ? Math.ceil(f32(f32(60 * Math.max(0.0, f32(d - mv.reach))) / rushParam(mv, 'speed'))) : 0);
}
/** The loom: his Breaker's dash within 6 m: Hoho through it, else Step aside. */
function senjuLoomAntiBreaker(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const f = e.f, g = e.g;
  if (!hariFormP(e) && s.kind === 'breaker' && s.phase === 'dash' && d < 6.0 && b.reactRoll < senjuDp(b, 'loomAntiBreakerP'))
    return why(b, 'loom-anti-breaker', hohoAllowedP(false, g.fs, f.hohoLock, g.burst) ? 'hoho' : 'side-step');
  return null;
}
const decideAgain = (b: Brain): void => { b.decideT = getf(T.aiThink, b.difficulty, 24) + Math.floor(40 * simRnd01()); };

/** The policy's free-state reflexes (each matched branch ends the policy: the Lisp COND). */
function senjuPolicyReflex(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const f = e.f, kit = f.kit, q = kitCommandMove(kit, 'q')!, k = kitCommandMove(kit, 'f'), o = kitCommandMove(kit, 'kikon');
  const left = s.left - b.delay;
  // his Breaker's aura / dash coming: the Shikai's O meets it from up to 6 m; the loom's lane only from 3 m out
  if (o && s.kind === 'breaker' && (s.phase === 'aura' || s.phase === 'dash') && d < 6.0 && (hariFormP(e) || d > 3.0)
      && kitCommandOkP(e, 'kikon') && b.reactRoll < senjuDp(b, 'antiBreakerP'))
    return why(b, 'anti-breaker-o', 'kikon');
  const lab = senjuLoomAntiBreaker(e, b, s, d);
  if (lab) return lab;
  // a neutral decision due, the Shikai: the policy's own bands at neutralP
  if (hariFormP(e) && (f.state === 'idle' || f.state === 'run') && b.decideT <= 1 && !(b.act === 'dash' && b.pressLeft > 0)
      && !snapDownP(s) && bandWeights(SENJU_NEUTRAL, d) && simRnd01() < senjuDp(b, 'neutralP')) {
    decideAgain(b);
    const c = weightedPick(simRnd01(), bandWeights(SENJU_NEUTRAL, d)!);
    return c && kitCommandOkP(e, c) && (!(c === 'q' || c === 'f') || d <= f32(f32(0.2) + kitCommandMove(kit, c)!.reach))
      && !(c === 'kikon' && aiSbFinishP(e)) ? why(b, 'neutral-v2', c) : null;
  }
  // a neutral decision due, the loom, he is red within the lane's range: the lane's Kikon at redRushP
  if (!hariFormP(e) && o && (f.state === 'idle' || f.state === 'run') && b.decideT <= 1 && kikonReadyP(e) && !aiSbFinishP(e)
      && d < aiTable(e, 'kikonRange', 7.0) && !snapDownP(s) && kitCommandOkP(e, 'kikon') && simRnd01() < senjuDp(b, 'redRushP')) {
    decideAgain(b);
    return why(b, 'red-rush', 'kikon');
  }
  // a recovery out of J1's reach: K1, else the O
  if (s.state === 'move' && s.phase === 'main' && s.sf >= s.activeEnd && s.left < 99 && d >= f32(q.reach + f32(0.4))
      && b.reactRoll < senjuDp(b, 'punishP')) {
    if (k && d < f32(k.reach + f32(0.2)) && left >= k.s + 1 && kitCommandOkP(e, 'f')) return why(b, 'far-punish', 'f');
    if (o && d < aiTable(e, 'kikonRange', 7.0) && left >= senjuOArrive(o, d) + 1 && kitCommandOkP(e, 'kikon') && !aiSbFinishP(e))
      return why(b, 'far-punish', 'kikon');
    return null;
  }
  // the stitches: unguardable, so a guard, a recovery or a reel is where they land
  if (hariFormP(e) && hari(e) >= 2 && kitCommandOkP(e, 'sig')
      && ((hari(e) >= 3 && (s.state === 'guard' || s.state === 'guard-hit'
                            || ((s.state === 'move' || s.state === 'stun') && s.left < 99 && left >= 12)))
          || aiMashP(b))
      && b.hohoRoll < senjuDp(b, 'hariP'))
    return why(b, 'hari-sure', 'sig');
  // a long guard up close: SAIDAN (one roll per guard)
  if (s.state === 'guard' && s.guardT >= T.aiGuardBreakHold && d < T.aiGuardBreakRange && b.breakKey !== s.start
      && kitCommandOkP(e, 'breaker')) {
    b.breakKey = s.start;
    return simRnd01() < senjuDp(b, 'breakP') ? why(b, 'guard-break', 'breaker') : null;
  }
  return null;
}

/** Her soldier stands, walks or strikes (not fading). */
function senjuSoldierLiveP(e: Ent): boolean {
  const h = sj(e).soldier;
  return alive(h) && ['rise', 'walk', 'tell'].includes((h.data as Sjh).phase as string);
}

/** The set-play reflexes: FOLLOW returns a command (or null); OKI the loom's / soldier's threat; ESCORT only moves the intent. */
function senjuSetplayReflex(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const kit = kitOf(e), q = kitCommandMove(kit, 'q')!, k = kitCommandMove(kit, 'f'), o = kitCommandMove(kit, 'kikon');
  const left = s.left - b.delay;
  if (s.state === 'stun' && s.left < 99 && d >= f32(q.reach + f32(0.6)) && !aiMashP(b) && b.reactRoll < senjuDp(b, 'followP')) {
    if (k && d <= f32(k.reach + f32(0.1)) && left >= k.s + 1 && kitCommandOkP(e, 'f')) return why(b, 'set-follow', 'f');
    if (o && d <= aiTable(e, 'kikonRange', 7.0) && left >= senjuOArrive(o, d) + 1 && kitCommandOkP(e, 'kikon') && !aiSbFinishP(e))
      return why(b, 'set-follow', 'kikon');
    if (hariFormP(e) && hari(e) >= 2 && left >= 11 && kitCommandOkP(e, 'sig')) return why(b, 'set-follow', 'sig');
    const n = formHank(kit.form);
    if (n != null && left >= 19 && kitCommandOkP(e, 'sp1') && tachiHanks(n).slice(0, 2).some(hankHitsP)) return why(b, 'set-follow', 'sp1');
    return null;
  }
  if ((s.state === 'down' || s.state === 'wakeup') && d >= 2.5 && d <= SJ.hankRange && b.reactRoll < senjuDp(b, 'okiP'))
    return senjuOki(e, b, s, kit);
  if (d > f32(2.4) && senjuSoldierLiveP(e) && b.hohoRoll < senjuDp(b, 'escortP')) {
    b.intent = 'pressure'; b.intentT = Math.max(b.intentT, 20);
  }
  return null;
}

/** He is down out of her reach: set the next threat where he gets up (the loom's hank, or the Shikai's soldier). */
function senjuOki(e: Ent, b: Brain, s: Snap, kit: Kit): string | null {
  const n = formHank(kit.form), inv = (s.state === 'down' ? 60 - s.sf : 30 - s.sf) - b.delay;
  if (n != null && [2, 3, 4, 5].includes(n) && senjuLiveZones(e).length === 0 && kitCommandOkP(e, 'sig')) {
    if (senjuStored(e) < 1) return why(b, 'oki-weave', 'sig');
    if (n !== 2 || inv <= 43) return why(b, 'oki-tap', 'sig');
    return null;
  }
  if (hariFormP(e) && !senjuSoldierLiveP(e) && kitCommandOkP(e, 'sp1')) return why(b, 'oki-soldier', 'sp1');
  return null;
}

/** The awakening (the generic one is off): EVOLUTION, the Shikai, free, the kit's awaken rule, her share <= awakenBelow. */
function senjuAwaken(e: Ent, b: Brain): string | null {
  const g = e.g;
  return g.evolution && hariFormP(e) && awakenStateP(e, e.f) && aiAwakenP(e)
    && (aiAwakenMode[e.f.side] === 'always' || f32(g.reishi / g.reishiMax) <= senjuDp(b, 'awakenBelow')) ? why(b, 'awaken-late', 'awaken') : null;
}

/** Does the designed pair SP1 releases from next hank N suit now (a cross pair never does)? */
function senjuPairP(e: Ent, b: Brain, d: number, n: number): boolean {
  if (!tachiAlignedP(n)) return false;
  const g = e.g;
  switch (n) {
    case 3: return d < 3.0;
    case 4: return d >= 3.0 && d <= 7.0;
    case 1: return d > 7.0 || b.intent === 'defend' || g.takenRanged > f32(f32(0.3) * f32(g.takenRanged + g.takenMelee));
    default: return false;
  }
}

registerHooks({
  /** Her CPU's own reflexes (free states): the awakening, the policy, the set play, the loom's SP1 pair, the stitches. */
  'senju-ai-reflex'(e: Ent, b: Brain, s: Snap, d: number): string | null {
    const kit = e.f.kit, ai = kit.ai, n = formHank(kit.form);
    const c = senjuAwaken(e, b) ?? senjuPolicyReflex(e, b, s, d) ?? senjuSetplayReflex(e, b, s, d);
    if (c) return c;
    if (n != null && senjuLiveZones(e).length === 0 && kitCommandOkP(e, 'sp1') && senjuPairP(e, b, d, n) && simRnd01() < SJ.aiSenjuPair)
      return why(b, 'pair', 'sp1');
    const h = getf<{ min?: number; hurry?: number } | null>(ai, 'hari', null);
    if (h && hariFormP(e) && kitCommandOkP(e, 'sig')) {
      const m = hari(e);
      if ((m >= 2 && hariFallsIn(e.g.meterIdle) <= (h.hurry ?? 40)) || (m >= (h.min ?? 4) && simRnd01() < SJ.aiSenjuHari))
        return why(b, 'hari', 'sig');
    }
    return null;
  },
  'senju-loom-anti-breaker': senjuLoomAntiBreaker,
  /** The Shikai's spEnder: the O ender (oEnderP); else after K3 the stitches' L with >= 3 (lEnderP). */
  'senju-base-ender'(e: Ent, kit: Kit): string | null {
    const b = aiBrain(e)!, mv = e.f.move!;
    if (mv.flags.includes('ender') && !aiSbFinishP(e) && kitCommandOkP(e, 'kikon', kit, true) && simRnd01() < senjuDp(b, 'oEnderP'))
      return 'kikon';
    const l = kitKLinkP(kit, mv.name) && hari(e) >= 3 ? kitLLink(kit, mv.name) : null;
    if (l && kitCommandOkP(e, 'sig', kit, false, l) && simRnd01() < senjuDp(b, 'lEnderP')) return 'sig';
    return null;
  },
  /** The loom's spEnder: SP1 when one of its two hanks hits (tachiP, half on a cross pair); else the O ender. */
  'senju-sp-ender'(e: Ent, kit: Kit): string | null {
    const n = formHank(kit.form), mv = e.f.move!, b = aiBrain(e);
    if (n != null && kitCommandOkP(e, 'sp1') && tachiHanks(n).slice(0, 2).some(hankHitsP)
        && simRnd01() < (b ? senjuDp(b, 'tachiP') : SJ.aiSenjuTachi) * (tachiAlignedP(n) ? 1.0 : 0.5)) return 'sp1';
    if (b && mv.flags.includes('ender') && !aiSbFinishP(e) && kitCommandOkP(e, 'kikon', kit, true) && simRnd01() < senjuDp(b, 'oEnderP'))
      return 'kikon';
    return null;
  },
  /** A CPU facing her: while she holds a weave within 9 m, one roll per hold: rush with O within range, else dash in. */
  'senju-opp-reflex'(e: Ent, b: Brain, s: Snap, d: number): string | null {
    const p = getf<number | null>(kitOf(oppOf(e)).ai, 'oppRushHold', null);
    if (p != null && s.state === 'move' && s.phase === 'hold' && s.kind === 'sig' && d < 9.0 && b.reactRoll < p) {
      if (d < aiTable(e, 'kikonRange', 7.0) && kitCommandOkP(e, 'kikon')) return why(b, 'tear', 'kikon');
      aiDash(b, 1.0, 1.8);
      return why(b, 'tear', 'pressed');
    }
    return null;
  },
  /** Frames her CPU holds L: the Shikai taps it; the loom weaves toward 3 / 2 / 1 passes by distance, one segment at a
   *  time, then taps. */
  'senju-sig-hold'(kit: Kit, d: number, e?: Ent | null): number {
    const n = formHank(kit.form);
    if (n == null || (e && aiBrain(e) && aiBrain(e)!.why === 'oki-tap')) return 1;
    const w = getf<{ far?: number; near?: number } | null>(kit.ai, 'weave', null), hoshi = kit.form === 'tsuji6';
    const far = hoshi ? 5.0 : (w?.far ?? 6.5), near = hoshi ? 2.5 : (w?.near ?? 4.0);
    const want0 = d > far ? 3 : d > near ? 2 : 0, woven = e ? sj(e).woven : 0;
    const fix = !!e && !tachiAlignedP(n) && Math.floor(e.g.reiatsu / T.reiatsuBar) >= kitCommandCost(kit, 'sp1');
    const want = e && senjuLiveZones(e).length > 0 ? 3 : fix ? 1 : Math.max(1, want0);
    return want <= weaveStored(woven) ? 1 : 1 + Math.max(SJ.weaveTap, Math.min(SJ.weaveSeg, want * SJ.weavePass - woven));
  },
});
