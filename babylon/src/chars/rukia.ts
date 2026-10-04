// rukia.ts <- duel/lisp/rukia.lisp: KUCHIKI RUKIA's moves (defmove), her four forms (defkit: base, the awakening
// ZETTAI REIDO's bands m18 / m50 / zero) and their hooks. The cold gauge (tempStep / tempBand), frost, the field, the
// ward / freeze-touch and the rooted form are generic (combat.ts, fighter.ts, rules.ts, ai.ts); here: the data, the ice
// hooks, the Hoho's cold, the CRACK, absolute zero's entry and her CPU hooks. Clip names are the art contract;
// cinematics are length-only (match.ts CINES).
import { T } from '../sim/tuning';
import { castPoint, aiHohoSpareP, breakerSpeed, burn, hohoAllowedP, tempBand } from '../sim/rules';
import { deg, fwdX, fwdZ, getf, roundHalfEven } from '../sim/math';
import { defkit, defmove, defmoveCopy, kitCommandMove, kitJLinkP, kitKLinkP, kitLLink, makeHitwin, registerHooks,
  type HitWin, type Kit, type Move } from '../sim/kit';
import { W, clog, emit, kitOf, oppOf, passiveP, sideName, simRnd01, type Brain, type Ent, type Snap } from '../sim/types';
import { ahead, kitCommandOkP, moveParam, rushParam, setReaction } from '../sim/fighter';
import { setForm } from '../sim/combat';
import { aiBrain, aiMashP, aiSbFinishP, aiTable, why } from '../sim/ai';
import { spawnHazard } from '../sim/hazards';

// ================================================================ Shikai (base)
// the J / K strings (docs/DUEL_STRINGS.md §2.1 budget): J1 7 f beats every K1 in the game; the K links frost. The reach
// since the J cut (§13): J 0.6x, close; K -10 %
defmove('ru-j1', { kind: 'quick', clip: 'ru-q1', startup: 7, active: 3, recovery: 12, dmg: 34, advBlock: -2,
  reach: 1.44, arc: 100, onHit: 'flinch', slide: 0.6 });            // HATSUSHIMO: a one-handed flat cut
defmove('ru-j2', { kind: 'quick', clip: 'ru-q2', startup: 7, active: 3, recovery: 13, dmg: 34, advBlock: -2,
  reach: 1.32, arc: 100, onHit: 'flinch' });                        // KAZAHANA: the backhand along the same line
defmove('ru-j3', { kind: 'quick', clip: 'ru-spin', startup: 8, active: 3, recovery: 18, dmg: 42, advBlock: -4,
  reach: 1.56, arc: 200, onHit: 'stagger', flags: ['ender'] });     // MAI-SODE: the pirouette, the ribbon whipping round
defmove('ru-k1', { kind: 'flash', clip: 'ru-thrust', startup: 17, active: 4, recovery: 20, dmg: 66, advBlock: -3,
  vol: ['cap', 0.2, 2.8, 1.1, 0.3], onHit: 'stagger', frost: 60 }); // SHIMO-TSUKI: the fencer's lunge
defmove('ru-k2', { kind: 'flash', clip: 'ru-ring', enter: 7, startup: 21, active: 4, recovery: 24, dmg: 58, advBlock: -3,
  reach: 2.5, arc: 140, onHit: 'stagger', frost: 60 });             // HYORIN: the rising turn, a white ring
defmove('ru-k3', { kind: 'flash', clip: 'ru-drop', enter: 7, startup: 21, active: 5, recovery: 34, dmg: 84, advBlock: -20,
  vol: ['cap', 0.3, 2.7, 1.2, 0.35], onHit: 'crumple', frost: 90, flags: ['ender'],
  onFrame: [[21, 'rukia-snow-burst']] });                           // NADARE: both hands, held, dropped; snow bursts
defmoveCopy('ru-j2s', 'ru-j2');
defmoveCopy('ru-k2s', 'ru-k2');
// L, SOME NO MAI: TSUKISHIRO: at f12 the point under the opponent (<= range m, castPoint) gets a white ring (the tell);
// delay frames later a pillar of ice erupts in it: a bind disc, guardable from her side (src), fragile (it closes if
// she is hit first): dmg + frozen stun frames + frost. A Step (2.5 m) always clears it. No cooldown: S 12 / R 36.
defmove('ru-tsukishiro', { kind: 'sig', clip: 'ru-tsukishiro', callout: 'SOME NO MAI: TSUKISHIRO', startup: 12, active: 0,
  recovery: 36, flags: ['bind'], onFrame: [[12, 'rukia-tsukishiro']],
  params: { range: 8.0, radius: 1.8, height: 3.0, delay: 24, dmg: 60, stun: 36, guard: 14, frost: 90, life: 8, tell: [21, 30] } });
// TSUKISHIRO after a K link (the kit's lAfterK): the ring at f8, the pillar 10 f later; its reach is the ring's range, so
// the follow-up chase leaves her where she stands
defmoveCopy('ru-tsukishiro-k', 'ru-tsukishiro', { startup: 8, clipS: 10, reach: 8.0, onFrame: [[8, 'rukia-tsukishiro']],
  params: { range: 8.0, radius: 1.8, height: 3.0, delay: 10, dmg: 60, stun: 36, guard: 14, frost: 90, life: 8, tell: [8, 17] } });
// Shift+K, TSUGI NO MAI: HAKUREN: held 16-64 f, one stab per 16 f (1-4, a spike each); released, the wave of cold
// (a wave hazard): wider and harder per stab; a hit freezes stun frames; a side Step always clears it
defmove('ru-hakuren', { kind: 'sp', clip: 'ru-stab', clip2: 'ru-hakuren', callout: 'TSUGI NO MAI: HAKUREN',
  hold: [16, 64], startup: 6, active: 1, recovery: 24, tick: 'rukia-hakuren-charge', onFrame: [[6, 'rukia-hakuren-wave']],
  params: { speed: 12.0, range: 11.0, width: 2.4, widthPer: 0.4, dmg: 70, dmgPer: 20, stun: 24, frost: 120, guard: 12, guardPer: 2 } });
// Shift+L, SAN NO MAI: SHIRAFUNE: the ice blade grows off the point: a 5 m thrust (her own blade: melee), frost 150
defmove('ru-shirafune', { kind: 'sp', clip: 'ru-shirafune', callout: 'SAN NO MAI: SHIRAFUNE', startup: 16, active: 4, recovery: 28,
  dmg: 110, advBlock: -14, slide: 1.0, vol: ['cap', 0.3, 5.0, 1.1, 0.3], onHit: 'knockback', kb: 2.0, frost: 150,
  onFrame: [[13, 'rukia-shirafune-ice']] });
defmove('ru-breaker', { kind: 'breaker', clip: 'ru-breaker', clip2: 'ru-hainawa', callout: 'BAKUDO NO YON: HAINAWA' });
// O, the Kikon rush module ENBU: 6 f of aura, a flash step at 24 m/s for <= 16 f, then the pirouette: 8.0 m, 360 deg.
// Its Kikon is SOME NO MAI: TSUKISHIRO. Cooldown 90.
defmove('ru-kikon', { kind: 'kikon', clip: 'sh-run', clip2: 'ru-spin', callout: 'SOME NO MAI: TSUKISHIRO', cine: 'ru-kikon-cine',
  startup: 8, active: 3, recovery: 24, dmg: 70, advBlock: -14, reach: 2.4, arc: 360, onHit: 'knockback', kb: 2.5, cooldown: 90,
  params: { aura: 6, aim: 120.0, speed: 24.0, dashMax: 16, dashTrack: 0.0, look: 'flash-step', sfx: 'hoho-out' } });

// ================================================================ ZETTAI REIDO (the awakened bands, docs/DUEL_RUKIA.md §4)
// -18: the Shikai grid (reach x1.0) with K1 TOSHU (the palm) and K3 HYOKA (the ice flower). -50 derives it (x1.1), zero
// (x1.35, rooted) swaps J2 / K1 / K3. The frames never change with the band: colder is longer reach and harder hits.
defmove('ru-a-k1', { kind: 'flash', clip: 'ru-palm', startup: 17, active: 4, recovery: 20, dmg: 66, advBlock: -3,
  vol: ['cap', 0.2, 2.0, 1.2, 0.35], slide: 0.8, onHit: 'stagger', frost: 90 });
defmove('ru-a-k3', { kind: 'flash', clip: 'ru-flower', enter: 7, startup: 21, active: 5, recovery: 34, dmg: 84, advBlock: -20,
  reach: 2.4, arc: 160, height: [0.0, 1.4], onHit: 'crumple', frost: 120, flags: ['ender'], onFrame: [[21, 'rukia-ice-flower']] });
defmoveCopy('ru-a-k1-50', 'ru-a-k1', { clip: 'ru-palm-50', vol: ['cap', 0.2, 2.2, 1.2, 0.35] });
defmoveCopy('ru-j3-50', 'ru-j3', { clip: 'ru-spin-50', reach: 1.72 });
defmoveCopy('ru-a-k3-50', 'ru-a-k3', { clip: 'ru-flower-50', reach: 2.64 });
defmoveCopy('ru-z-j2', 'ru-j2', { clip: 'ru-palm', clipS: 17, reach: 1.78 });
defmoveCopy('ru-z-j2s', 'ru-z-j2');
defmoveCopy('ru-z-k1', 'ru-k1', { vol: ['cap', 0.2, 3.78, 1.1, 0.3], frost: 90 });
defmoveCopy('ru-z-k3', 'ru-a-k3', { reach: 3.24, frost: 150 });
// L, one family that grows with the cold: a disc round her, guardable facing her (src). -18 SHIMOBASHIRA (r 2.5); -50
// HYOSHIN (r 3.5, crumple); zero REIDO TOKETSU (r 5.5 = the field, a 45 f freeze; it cashes the top bar)
defmove('ru-shimobashira', { kind: 'sig', clip: 'ru-stab', callout: 'SHIMOBASHIRA', startup: 12, active: 0, recovery: 22,
  onFrame: [[0, 'rukia-hyoshin-tell'], [12, 'rukia-shimobashira']],
  params: { radius: 2.5, height: 0.6, dmg: 60, frost: 90, guard: 12, react: 'stagger' } });
defmove('ru-hyoshin', { kind: 'sig', clip: 'ru-stab-2h', callout: 'HYOSHIN', startup: 14, active: 0, recovery: 22,
  onFrame: [[0, 'rukia-hyoshin-tell'], [14, 'rukia-hyoshin']],
  params: { radius: 3.5, height: 0.6, dmg: 85, frost: 120, guard: 16, react: 'crumple' } });
defmove('ru-reido', { kind: 'sig', clip: 'ru-reido', clipS: 6, callout: 'REIDO TOKETSU', startup: 10, active: 0, recovery: 26,
  onFrame: [[10, 'rukia-reido']], params: { radius: 5.5, height: 2.2, dmg: 120, stun: 45, frost: 150, guard: 20 } });
// SP1 HAKUREN colder: -50 a stab every 12 f (hold 12-48); zero no hold: the four stabs at once and the widest wave
defmoveCopy('ru-hakuren-50', 'ru-hakuren', { hold: [12, 48],
  params: { per: 12, speed: 14.0, range: 12.0, width: 2.4, widthPer: 0.4, dmg: 80, dmgPer: 23, stun: 30, frost: 120, guard: 12, guardPer: 2 } });
defmove('ru-hakuren-0', { kind: 'sp', clip: 'ru-hakuren', clipS: 6, callout: 'TSUGI NO MAI: HAKUREN', startup: 10, active: 1, recovery: 24,
  onFrame: [[0, 'rukia-hakuren-spikes'], [10, 'rukia-hakuren-wave']],
  params: { stabs: 4, speed: 16.0, range: 14.0, width: 3.6, widthPer: 0.0, dmg: 160, dmgPer: 0, stun: 36, frost: 150, guard: 18, guardPer: 0 } });
// SP2 SHIRAFUNE colder: 5.0 m (-18) -> 6.0 m -> 7.5 m planted, crumpling
defmoveCopy('ru-shirafune-50', 'ru-shirafune', { dmg: 125, vol: ['cap', 0.3, 6.0, 1.1, 0.3] });
defmoveCopy('ru-shirafune-0', 'ru-shirafune', { dmg: 140, vol: ['cap', 0.3, 7.5, 1.1, 0.3], onHit: 'crumple', slide: 0.0 });
// O in every band, HAKKA NO TOGAME: ENJO's module shape (no dash): the blade raised (a white pillar, f4), then levelled:
// the cold runs off the tip along a locked lane, 6.5 / 7.5 / 9.0 m by band. Cooldown 90
defmove('ru-hakka', { kind: 'kikon', clip: 'ru-cold-stance', clip2: 'ru-hakka', callout: 'HAKKA NO TOGAME', cine: 'ru-hakka-cine',
  startup: 20, active: 3, recovery: 30, whiff: 30, dmg: 70, advBlock: -14, track: 0, vol: ['cap', 0.5, 7.5, 1.2, 1.2],
  onHit: 'knockback', kb: 2.0, frost: 120, cooldown: 90, onFrame: [[4, 'rukia-hakka-pillar'], [20, 'rukia-hakka-sheet']],
  params: { aura: 8, aim: 120.0, speed: 0.0, dashMax: 0, dashTrack: 0.0, look: 'lane' } });
defmoveCopy('ru-hakka-18', 'ru-hakka', { vol: ['cap', 0.5, 6.5, 1.2, 1.2] });
defmoveCopy('ru-hakka-0', 'ru-hakka', { vol: ['cap', 0.5, 9.0, 1.2, 1.2] });

// ================================================================ forms
defkit('rukia', 'base', {
  name: 'RUKIA', body: 'rukia', weapon: 'sode-no-shirayuki', stance: 'ru-stance', hide: ['ice-trim', 'hand-crack'],
  intro: 'ru-intro', win: 'ru-win', introCallout: 'MAE, SODE NO SHIRAYUKI', introWeapon: ['ru-katana', 70],
  walk: T.walkRukia, run: T.runRukia, reishi: T.reishiMax, swingSfx: 'whoosh-light', mult: T.rukiaMult, taken: T.rukiaTaken,
  stunTolerance: 13.0,                         // the hidden stun: light, blown away sooner
  commands: { q: 'ru-j1', f: 'ru-k1', sig: 'ru-tsukishiro', sp1: 'ru-hakuren', sp2: 'ru-shirafune', breaker: 'ru-breaker', kikon: 'ru-kikon' },
  grid: ['ru-j1', 'ru-j2', 'ru-j3', 'ru-k1', 'ru-k2', 'ru-k3', 'ru-j2s', 'ru-k2s'],
  lAfterK: 'ru-tsukishiro-k',                  // L after K1 / K2 / K3: the combo ring
  awakenForm: 'm18',
  // a mid-range zoner; she awakens only against a melee opponent (>= 60 % of >= 150 taken from blades)
  ai: { intents: { approach: 2, pressure: 3, zone: 2, defend: 1 },
        ranges: { approach: [2.8, 5.0], pressure: [1.0, 2.4], zone: [5.0, 7.5], defend: [3.5, 6.0] },
        moves: [[0.0, 1.8, 'q', 6, 'f', 2, 'breaker', 1, 'sp2', 1],
                [1.8, 2.8, 'f', 4, 'breaker', 1, 'sp2', 1],
                [2.8, 5.0, 'f', 1, 'sp2', 2, 'sig', 2, 'kikon', 1, 'step', 1],
                [5.0, 8.0, 'sig', 4, 'sp1', 2, 'kikon', 2, 'step', 1],
                [8.0, 99.0, 'sp1', 2, 'kikon', 2, null, 1]],
        guard: 0.4, hoho: 0.35, spCancelBars: 1, oki: 'sp1-full', okiAbove: 0.4, dash: 0.5, dashBack: 0.4, kikonRange: 8.0,
        stunFollow: ['sp2', 2.4, 5.0], awaken: { meleeShare: 0.6, minTaken: 150 }, lAfterK: T.aiRuLAfterK,
        spEnder: 'rukia-ai-sp-ender', reflex: 'rukia-ai-reflex', assistGuard: 'rukia-assist-guard' },
});

// -18 C: the Shikai grid (+ TOSHU / HYOKA), frost on every hit, no chip on her; U guards and cools; only L spends cold
defkit('rukia', 'm18', {
  inherit: 'base',
  awakening: true, formName: '-18C', walk: T.walkM18, run: T.runM18, passives: ['chipless'], frostTouch: T.frostTouch,
  mult: T.rukiaAwakeMult, taken: T.rukiaAwakeTaken,
  meter: { name: 'COLD', max: T.coldMax, temp: true }, warm: T.ruWarmM18, cold: T.ruColdM18, field: T.ruFieldM18,
  resetForm: 'm18', uTag: 'U: COOL', hooks: { hoho: 'rukia-hoho-cold' },
  stance: 'ru-cold-stance', aura: 'rukia-aura-cold', cine: 'ru-awaken-cine', swingSfx: 'whoosh-light',
  commands: { f: 'ru-a-k1', sig: 'ru-shimobashira', kikon: 'ru-hakka-18' },
  grid: ['ru-j1', 'ru-j2', 'ru-j3', 'ru-a-k1', 'ru-k2', 'ru-a-k3', 'ru-j2s', 'ru-k2s'],
  lAfterK: true,                               // L after a K link: the band's own L
  ai: { intents: { approach: 2, pressure: 3, zone: 1, defend: 2 },
        ranges: { approach: [2.5, 4.5], pressure: [1.0, 2.2], zone: [4.5, 7.0], defend: [3.0, 5.0] },
        moves: [[0.0, 1.8, 'q', 5, 'f', 2, 'breaker', 1, 'sig', 1],
                [1.8, 2.8, 'f', 3, 'breaker', 1, 'sig', 1],
                [2.8, 5.0, 'sp2', 2, 'step', 1, null, 2],
                [5.0, 99.0, 'sp1', 2, null, 2]],
        guard: 0.5, hoho: 0.3, dash: 0.2, dashBack: 0.2, oEnder: 0.25, lAfterK: T.aiRuLAfterKAwake, kikonRange: 6.5, spCancelBars: 2,
        cool: { p: 0.3, near: 3.5 }, stunFollow: ['sp2', 2.4, 5.0], spEnder: 'rukia-ai-sp-ender', reflex: 'rukia-ai-reflex',
        assistGuard: 'rukia-assist-guard' },
});

// -50 C: slower, hardened, reach x1.1, the rime blade, HYOSHIN for L; every action spends cold now
defkit('rukia', 'm50', {
  inherit: 'm18',
  reachMult: 1.1, formName: '-50C', walk: T.walkM50, run: T.runM50, mult: T.rukiaM50Mult, taken: T.rukiaM50Taken,
  frostTouch: T.frostTouchM50, warm: T.ruWarmM50, cold: T.ruColdM50, field: T.ruFieldM50,
  weapon: 'ru-rime', hide: ['hand-crack'], aura: 'rukia-aura-frost',
  commands: { f: 'ru-a-k1-50', sig: 'ru-hyoshin', sp1: 'ru-hakuren-50', sp2: 'ru-shirafune-50', kikon: 'ru-hakka' },
  grid: ['ru-j1', 'ru-j2', 'ru-j3-50', 'ru-a-k1-50', 'ru-k2', 'ru-a-k3-50', 'ru-j2s', 'ru-k2s'],
  ai: { intents: { approach: 1, pressure: 3, zone: 0, defend: 2 },
        ranges: { approach: [2.0, 3.5], pressure: [1.0, 2.3], zone: [3.0, 5.0], defend: [2.0, 3.5] },
        moves: [[0.0, 1.9, 'q', 4, 'f', 2, 'sig', 3],
                [1.9, 3.5, 'f', 3, 'sig', 3],
                [3.5, 99.0, 'sp2', 1, 'sp1', 1, null, 2]],
        guard: 0.45, hoho: 0.25, dash: 0.1, dashBack: 0.1, oEnder: 0.25, lAfterK: T.aiRuLAfterKAwake, kikonRange: 7.5, spCancelBars: 2,
        cool: { p: 0.35, near: 4.0, noProjectile: true, minGg: 50 }, stunFollow: ['sp2', 2.4, 6.0], reflex: 'rukia-ai-reflex',
        assistGuard: 'rukia-assist-guard', spEnder: 'rukia-ai-sp-ender' },
});

// -273.15 C, absolute zero (both bars full): rooted, every button strongest at reach x1.35, the largest field; the ward
// whose first melee hit freezes its attacker; ranged hits guarded too; U braces. She leaves by spending the top bar,
// by warming, or by the CRACK (rukia-crack)
defkit('rukia', 'zero', {
  inherit: 'm18',
  reachMult: 1.35, formName: '-273C', walk: 0.0, run: 0.0, rooted: true, mult: T.rukiaZeroMult, taken: T.rukiaZeroTaken,
  passives: ['ward', 'freeze-touch', 'chipless'], frostTouch: T.frostTouchZero, warm: T.ruWarmZero, cold: T.ruColdZero,
  field: T.ruFieldZero, crushHook: 'rukia-crack', uTag: 'U: BRACE',
  body: 'rukia-zero', weapon: 'ru-ice', hide: ['ice-trim', 'hand-crack'], stance: 'ru-zero', aura: 'rukia-aura-zero',
  enterHook: 'rukia-zero-enter', calm: true,
  commands: { f: 'ru-z-k1', sig: 'ru-reido', sp1: 'ru-hakuren-0', sp2: 'ru-shirafune-0', kikon: 'ru-hakka-0', breaker: null },
  grid: ['ru-j1', 'ru-z-j2', 'ru-j3', 'ru-z-k1', 'ru-k2', 'ru-z-k3', 'ru-z-j2s', 'ru-k2s'],
  ai: { intents: { approach: 0, pressure: 3, zone: 0, defend: 2 },
        ranges: { approach: [0.0, 99.0], pressure: [0.0, 99.0], zone: [0.0, 99.0], defend: [0.0, 99.0] },
        moves: [[0.0, 2.2, 'q', 4, 'f', 3],
                [2.2, 3.5, 'f', 4, null, 1],
                [3.5, 5.5, 'sig', 3, 'f', 1, null, 1],
                [5.5, 7.5, 'sp2', 1, 'sp1', 2, null, 2],
                [7.5, 14.0, 'sp1', 2, null, 2],
                [14.0, 99.0, null, 1]],
        guard: 0.0, hoho: 0.0, oEnder: 0.25, lAfterK: T.aiRuLAfterKAwake, kikonRange: 9.0, spCancelBars: 2,
        brace: { p: 0.2, near: 5.5, minGg: 30 }, oppIntent: { zone: 2, defend: 2 }, spEnder: 'rukia-ai-sp-ender',
        reflex: 'rukia-ai-reflex', assistGuard: 'rukia-assist-guard' },
});

// ================================================================ hooks (called through the data's names)
/** A look-only hazard (kind 'fx') drawn as KIND: no hit, no sim effect but its hazard slot. */
function rukiaLook(e: Ent, kind: string, x: number, z: number,
                   o: { yaw?: number; size?: number; life?: number; delay?: number; fragile?: boolean } = {}): void {
  spawnHazard('fx', e, { x, z, yaw: o.yaw ?? 0, size: o.size ?? 1.0, life: o.life ?? 30, delay: o.delay ?? 0, look: kind,
                         fragile: o.fragile });
}
/** HAKUREN's stab I (0-3): an ice spike in a half circle before her. */
function rukiaSpike(e: Ent, i: number): void {
  const a = e.yaw + deg(45 - 30 * i), p = e.pos;
  rukiaLook(e, 'rukia-spike-look', p[0] + 1.1 * fwdX(a), p[2] + 1.1 * fwdZ(a), { size: 0.5 + 0.1 * i, life: 70 });
}
/** HAKUREN's stabs (1-4): the move's stabs (zero: 4), else one per `per` f of the charge (set when it was released). */
const rukiaStabs = (e: Ent): number =>
  moveParam(e, 'stabs') ?? Math.max(1, Math.min(4, Math.floor(e.f.charge / (moveParam(e, 'per') ?? 16))));
/** A disc hit round E (radius R, height H) this frame: a freeze hazard from her position (guardable facing her). */
function rukiaDisc(e: Ent, r: number, h: number, hw: HitWin): void {
  spawnHazard('freeze', e, { x: e.pos[0], z: e.pos[2], size: r, y: h, life: 2, src: true, hw });
}
/** HYOSHIN f14 (and SHIMOBASHIRA's disc): the ice quake: a disc round her, the move's react + frost. */
function rukiaHyoshin(e: Ent): void {
  rukiaDisc(e, moveParam(e, 'radius'), moveParam(e, 'height'),
    makeHitwin({ dmg: moveParam(e, 'dmg'), react: moveParam(e, 'react'), kb: 1.0, hs: T.hitstopHeavy,
                 guard: moveParam(e, 'guard'), frost: moveParam(e, 'frost'), flags: ['ice'] }));
  emit('sfx', 'ground-crack', e);
}
/** Cold a Hoho adds when she reappears behind him (-18 / -50). */
const RU_HOHO_COLD = 50.0;

registerHooks({
  /** NADARE f21: snow bursts from the plaza at the point (a look). */
  'rukia-snow-burst'(e: Ent) {
    const [x, z] = ahead(e, 2.4);
    rukiaLook(e, 'rukia-burst-look', x, z, { size: 1.0, life: 24 });
    emit('sfx', 'ice-shatter', e);
  },
  /** TSUKISHIRO: the point under the opponent (castPoint, <= range m); its white ring now (the tell), the pillar delay
   *  frames later: a freeze disc (guardable facing her: src; it closes if she is hit first: fragile). */
  'rukia-tsukishiro'(e: Ent) {
    const p = e.pos, q = oppOf(e).pos, r = moveParam(e, 'radius'), d = 1 + moveParam(e, 'delay');
    const [x, z] = castPoint(p[0], p[2], q[0], q[2], moveParam(e, 'range'));
    spawnHazard('freeze', e, { x, z, size: r, y: moveParam(e, 'height'), delay: d, life: moveParam(e, 'life'), src: true, fragile: true,
      hw: makeHitwin({ dmg: moveParam(e, 'dmg'), react: 'bind', stun: moveParam(e, 'stun'), hs: T.hitstopHeavy,
                       guard: moveParam(e, 'guard'), frost: moveParam(e, 'frost'), flags: ['ice'] }) });
    rukiaLook(e, 'rukia-ring-look', x, z, { size: r, delay: d, life: 36, fragile: true });
    emit('sfx', 'frost-tick', e);
  },
  /** HAKUREN's hold: a stab into the plaza every `per` f (16; -50: 12), 1-4 of them, an ice spike at each. */
  'rukia-hakuren-charge'(e: Ent) {
    const h = e.f.hold, per = moveParam(e, 'per') ?? 16;
    if (h > 0 && h % per === 0 && h <= 4 * per) { rukiaSpike(e, Math.floor(h / per) - 1); emit('sfx', 'frost-tick', e); }
  },
  /** Zero's HAKUREN f0: the four stabs at once. */
  'rukia-hakuren-spikes'(e: Ent) {
    for (let i = 0; i < 4; i++) rukiaSpike(e, i);
    emit('sfx', 'frost-tick', e);
  },
  /** HAKUREN: the wave of cold leaves the blade: speed m/s over range m, width + widthPer per stab wide, dmg + dmgPer
   *  per stab; a hit freezes stun frames, frost. */
  'rukia-hakuren-wave'(e: Ent) {
    const n = rukiaStabs(e) - 1, speed = moveParam(e, 'speed'), w = moveParam(e, 'width') + n * moveParam(e, 'widthPer');
    const [x, z] = ahead(e, 1.0);
    spawnHazard('wave', e, { x, z, yaw: e.yaw, speed, size: 0.5 * w, life: roundHalfEven(60 * (moveParam(e, 'range') / speed)),
      look: 'rukia-wave-look',
      hw: makeHitwin({ dmg: moveParam(e, 'dmg') + n * moveParam(e, 'dmgPer'), react: 'bind', stun: moveParam(e, 'stun'),
                       hs: T.hitstopHeavy, frost: moveParam(e, 'frost'), guard: moveParam(e, 'guard') + n * moveParam(e, 'guardPer'),
                       flags: ['ice'] }) });
    emit('sfx', 'ice-rise', e);
  },
  /** SHIRAFUNE f13: the ice grows off the point along the thrust (a look; the hit is the move's line). */
  'rukia-shirafune-ice'(e: Ent) {
    rukiaLook(e, 'rukia-blade-look', e.pos[0], e.pos[2], { yaw: e.yaw, size: e.f.move!.reach, life: 20 });
    emit('sfx', 'freeze', e);
  },
  /** HYOKA f21: the ice flower bursts at his feet, larger the colder she is (a look; the hit is the move's arc). */
  'rukia-ice-flower'(e: Ent) {
    const k = e.f.move!.reach / 2.7, [x, z] = ahead(e, 1.9 * k);
    rukiaLook(e, 'rukia-flower-look', x, z, { size: 1.1 * k * k, life: 40 });
    emit('sfx', 'ice-shatter', e);
  },
  /** HYOSHIN f0: the blade driven into the plaza, frost cracks radiating (the tell; one look). */
  'rukia-hyoshin-tell'(e: Ent) {
    rukiaLook(e, 'rukia-quake-look', e.pos[0], e.pos[2], { size: moveParam(e, 'radius'), delay: 15, life: 30 });
    emit('sfx', 'frost-tick', e);
  },
  'rukia-hyoshin': rukiaHyoshin,
  /** SHIMOBASHIRA f12: frost pillars stand up in a ring round her (six spikes, a look) and the disc hits (HYOSHIN's). */
  'rukia-shimobashira'(e: Ent) {
    const p = e.pos, r = 0.8 * moveParam(e, 'radius');
    for (let i = 0; i < 6; i++) {
      const a = e.yaw + i * 1.0472;
      rukiaLook(e, 'rukia-spike-look', p[0] + r * fwdX(a), p[2] + r * fwdZ(a), { size: 0.7, life: 40 });
    }
    rukiaHyoshin(e);
  },
  /** REIDO TOKETSU f10: a disc round her (5.5 m) freezes stun frames; the plaza whitens to its edge. */
  'rukia-reido'(e: Ent) {
    rukiaDisc(e, moveParam(e, 'radius'), moveParam(e, 'height'),
      makeHitwin({ dmg: moveParam(e, 'dmg'), react: 'bind', stun: moveParam(e, 'stun'), hs: T.hitstopHeavy,
                   guard: moveParam(e, 'guard'), frost: moveParam(e, 'frost'), flags: ['ice'] }));
    rukiaLook(e, 'rukia-burst-look', e.pos[0], e.pos[2], { size: moveParam(e, 'radius'), life: 30 });
    emit('sfx', 'freeze', e);
  },
  /** HAKKA f4: a white pillar of cold rises at her (a look). */
  'rukia-hakka-pillar'(e: Ent) {
    rukiaLook(e, 'rukia-pillar-look', e.pos[0], e.pos[2], { size: 0.9, life: 40 });
    emit('sfx', 'ice-rise', e);
  },
  /** HAKKA f20: the cold runs off the tip along the lane (a look; the hit is the move's lane). */
  'rukia-hakka-sheet'(e: Ent) {
    rukiaLook(e, 'rukia-sheet-look', e.pos[0], e.pos[2], { yaw: e.yaw, size: e.f.move!.reach, life: 34 });
    emit('sfx', 'kikon-slash', e);
  },
  /** The awakened bands' hoho hook: reappearing behind him adds RU_HOHO_COLD and the band follows at once (a Hoho to
   *  200 lands her at -273, the ward up: rukia-zero-enter). Not in the THAW after a CRACK. */
  'rukia-hoho-cold'(e: Ent) {
    const g = e.g, f = e.f, c = Math.fround(Math.min(T.coldMax, Math.fround(g.meter + RU_HOHO_COLD)));
    const band = tempBand(c, f.form);
    if (g.meterIdle > 0) return;                                      // the THAW: nothing cools her
    g.meter = c;
    if (band !== f.form) { setForm(e, band); emit('sfx', 'frost-tick', e); }
  },
  /** Absolute zero's enterHook: entered from a held guard or a Hoho's arrival, the ward is up at once; a new visit's
   *  freeze-touch; the white burst. */
  'rukia-zero-enter'(e: Ent) {
    const f = e.f;
    if (f.state === 'guard' || f.state === 'guard-hit' || f.state === 'hoho') f.guardT = T.guardRaise;
    e.g.froze = false;
    rukiaLook(e, 'rukia-burst-look', e.pos[0], e.pos[2], { size: 1.4, life: 24 });
    emit('sfx', 'freeze', e);
    clog(() => `${sideName(e)} ZERO`);
  },
  /** The CRACK (zero's crushHook): the gauge empties (-18 at once), T.crackSelf burnt (never below 1), a T.crackStun
   *  crumple in place when she isn't in a reaction already, and the THAW lock (guarding doesn't cool: meterIdle). */
  'rukia-crack'(e: Ent) {
    const f = e.f, g = e.g, p = e.pos;
    setForm(e, 'm18');
    g.meter = 0; g.meterIdle = T.ruThawLock; g.reishi = burn(g.reishi, T.crackSelf);
    if (!(f.state === 'stun' || f.state === 'air' || f.state === 'down' || f.state === 'wakeup'))
      setReaction(e, 'crumple', T.crackStun, p[0], p[2], 0.0);
    emit('cold-crack', e);
    clog(() => `${sideName(e)} CRACK r${g.reishi}`);
  },
});

// ================================================================ her CPU (AI v2, docs/DUEL_AI_V2.md)
// Every chance is per difficulty (EASY <= NORMAL <= HARD).
type Dif = Record<string, number>;
const AI_RU_HOHO_IN = 0.05;                    // -50: chance per free step to Hoho in when that Hoho reaches -273
const AI_RU_K_ENDER_L: Dif = { easy: 0.0, normal: 0.02, hard: 0.9 };
const AI_RU_J_ENDER_SP2: Dif = { easy: 0.1, normal: 0.15, hard: 0.85 };
const AI_RU_ENDER_O: Dif = { easy: 0.0, normal: 0.02, hard: 0.9 };
const AI_RU_PH_BREAKER: Dif = { easy: 0.0, normal: 0.05, hard: 0.95 };
const AI_RU_PH_MOVE: Dif = { easy: 0.0, normal: 0.02, hard: 0.8 };
const AI_RU_PH_MASH: Dif = { easy: 0.0, normal: 0.02, hard: 0.8 };
const AI_RU_PH_MOVE_FS = 60.0;
const AI_RU_PH_CASH: Dif = { easy: 0.0, normal: 0.05, hard: 0.9 };
const AI_RU_CASH_O: Dif = { easy: 0.0, normal: 0.02, hard: 0.9 };
const AI_RU_ZONE_WAVE: Dif = { easy: 0.0, normal: 0.0, hard: 0.5 };
const AI_RU_Z_WARD_REIDO: Dif = { easy: 0.0, normal: 0.02, hard: 0.9 };
const AI_RU_Z_WARD_WINDOW = 24;
const AI_RU_Z_ANTI_BREAKER: Dif = { easy: 0.0, normal: 0.05, hard: 0.9 };
const AI_RU_BAND_DISC: Dif = { easy: 0.0, normal: 0.0, hard: 0.5 };

/** P's chance at E's CPU difficulty (NORMAL's without a brain). */
function rukiaAiP(e: Ent, p: Dif): number {
  const b = aiBrain(e);
  return p[b ? b.difficulty : 'normal'] ?? p.normal ?? 0.0;
}
/** Bars enough for an SP and the kit's reserve (spCancelBars) after it. */
const rukiaAiBarsP = (e: Ent): boolean => Math.floor(e.g.reiatsu / T.reiatsuBar) >= aiTable(e, 'spCancelBars', 1);
/** The next neutral decision as aiNeutral times it (her kit has no tempo). */
const rukiaDecideAgain = (b: Brain): void => { b.decideT = getf(T.aiThink, b.difficulty, 24) + Math.floor(40 * simRnd01()); };

/** -50: beyond 3 m, when a Hoho's cold would reach -273 and the Hoho is allowed, dive in now and then. */
function rukiaAiHohoIn(e: Ent, b: Brain, d: number): string | null {
  const g = e.g, f = e.f;
  return d > 3.0 && g.meterIdle === 0 && Math.fround(g.meter + RU_HOHO_COLD) >= T.coldMax
    && hohoAllowedP(false, g.fs, f.hohoLock, g.burst) && simRnd01() < AI_RU_HOHO_IN ? why(b, 'hoho-in', 'hoho') : null;
}

/** The timed Hoho ('hoho'), 'wait' while his hit window is still to come, or null (rukia.lisp RUKIA-AI-PERFECT-HOHO). */
function rukiaAiPerfectHoho(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const f = e.f, g = e.g, dl = b.delay, el = W.tick - s.start, roll = b.reactRoll, fs = g.fs;
  if (kitOf(e).rooted || !hohoAllowedP(false, fs, f.hohoLock, g.burst) || !aiHohoSpareP(fs, g.reishi, g.reishiMax)) return null;
  const goWhen = (framesToWindow: number, into: number) =>
    framesToWindow <= -into ? why(b, 'perfect-hoho', 'hoho') : why(b, 'ph-wait', 'wait');
  switch (s.kind) {
    case 'breaker':
      if (roll < rukiaAiP(e, AI_RU_PH_BREAKER)) {
        const v = breakerSpeed(20) / 60.0, win = T.breakerTrigger + 0.5;
        if (s.phase === 'aura') { if (d < 7.0) return goWhen(1 + T.breakerAura - el + Math.max(0.0, (d - win) / v), 2); }
        else if (s.phase === 'dash') { if (d < 8.0) return goWhen((d - win - v * dl) / v, 2); }
        else if (s.phase === 'main') { if (s.sf + dl < s.activeEnd) return goWhen(0, 0); }
      }
      return null;
    case 'kikon':
      if (roll < rukiaAiP(e, AI_RU_PH_BREAKER) && (s.phase === 'dash' || s.phase === 'main') && d < 3.5
          && (s.phase === 'dash' || s.sf + dl < s.activeEnd)) return goWhen(0, 0);
      return null;
    case 'flash': case 'sig': case 'sp':
      if (s.phase === 'main' && s.reach > 0 && s.activeEnd > s.s && d < s.reach + 0.7 && fs >= AI_RU_PH_MOVE_FS
          && roll < rukiaAiP(e, AI_RU_PH_MOVE)) {
        const lead = s.s - s.sf - dl;
        if (s.sf + dl + 1 < s.activeEnd && lead <= 40) return goWhen(lead - T.perfectLead, 3);
      }
      return null;
    case 'quick':
      if (aiMashP(b) && s.phase === 'main' && s.sf + dl >= s.activeEnd && s.left < 99 && d < s.reach + 1.0
          && roll < rukiaAiP(e, AI_RU_PH_MASH)) return goWhen(s.left - dl + s.s - T.perfectLead, 1);
      return null;
    default: return null;
  }
}

/** Does O move MV, pressed now at D m, strike within LEFT frames: its aura, its dash into its reach, its startup? */
function rukiaAiOLandsP(mv: Move, d: number, left: number): boolean {
  const sp = (rushParam(mv, 'speed') ?? 0.0) / 60.0, gap = d - mv.reach + 0.3;
  return (sp > 0 || d < mv.reach)
    && left >= (rushParam(mv, 'aura') ?? 0) + mv.s + 1 + (sp > 0 && gap > 0 ? Math.ceil(gap / sp) : 0);
}

/** A stunned opponent (or one recovering) whose stun outlasts the startup of her ice: SHIRAFUNE within its line, else
 *  the band's disc L within its radius, else (a stun only) her O when it strikes in time. */
function rukiaAiCash(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const kit = kitOf(e), sp2 = kitCommandMove(kit, 'sp2'), l = kitCommandMove(kit, 'sig'), left = s.left - b.delay;
  const lands = (mv: Move) => left >= mv.s + ((mv.params.delay as number | undefined) ?? 0) + 1;   // (TSUKISHIRO: its delay)
  if (!((s.state === 'stun'
         || (s.state === 'move' && s.phase === 'main' && s.left < 99 && s.sf + b.delay >= s.activeEnd && !aiMashP(b)))
        && b.reactRoll < rukiaAiP(e, AI_RU_PH_CASH))) return null;
  if (sp2 && d > 0.5 && d < sp2.reach - 0.5 && lands(sp2) && kitCommandOkP(e, 'sp2')
      && Math.floor(e.g.reiatsu / T.reiatsuBar) >= aiTable(e, 'spCancelBars', 1)) return why(b, 'ice-cash', 'sp2');
  const r = l?.params.radius as number | undefined;
  if (l && r != null && d < r - 0.4 && lands(l) && kitCommandOkP(e, 'sig')) return why(b, 'ice-cash', 'sig');
  const o = kitCommandMove(kit, 'kikon');
  if (o && s.state === 'stun' && !aiSbFinishP(e) && kitCommandOkP(e, 'kikon') && rukiaAiOLandsP(o, d, left)
      && b.reactRoll < rukiaAiP(e, AI_RU_CASH_O)) return why(b, 'o-cash', 'kikon');
  return null;
}

/** Her Shikai's neutral decision at range, at HARD half the time: HAKUREN (SP1). */
function rukiaAiZone(e: Ent, b: Brain, d: number): string | null {
  if (b.decideT <= 1 && kitOf(e).form === 'base' && d >= 5.0 && d <= 11.0 && kitCommandOkP(e, 'sp1')) {
    const p = rukiaAiP(e, AI_RU_ZONE_WAVE);
    if (p > 0 && simRnd01() < p) { rukiaDecideAgain(b); return why(b, 'zone-wave', 'sp1'); }
  }
  return null;
}

/** Zero's answers: REIDO on a ward block up close (felt at once), REIDO timed on a Breaker's aura / dash. */
function rukiaAiZero(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const f = e.f, l = kitCommandMove(kitOf(e), 'sig')!, r = ((l.params.radius as number | undefined) ?? 5.5) - 0.5;
  if (!kitCommandOkP(e, 'sig')) return null;
  if (passiveP(e, 'ward') && W.tick - f.warded <= AI_RU_Z_WARD_WINDOW && f.dist < r && b.reactRoll < rukiaAiP(e, AI_RU_Z_WARD_REIDO))
    return why(b, 'ward-reido', 'sig');
  if (s.kind === 'breaker' && b.reactRoll < rukiaAiP(e, AI_RU_Z_ANTI_BREAKER)
      && (s.phase === 'aura' ? d < r : s.phase === 'dash' ? d - (breakerSpeed(20) / 60.0) * (b.delay + l.s) <= r : false))
    return why(b, 'anti-breaker-reido', 'sig');
  return null;
}

/** Her bands' neutral decision up close at HARD half the time: the band's L disc round her. */
function rukiaAiBandDisc(e: Ent, b: Brain, s: Snap, d: number): string | null {
  const l = kitCommandMove(kitOf(e), 'sig'), form = kitOf(e).form;
  if (b.decideT <= 1 && (form === 'm18' || form === 'm50') && d < ((l?.params.radius as number | undefined) ?? 0.0) - 0.6
      && (s.state === 'idle' || s.state === 'run' || (s.state === 'move' && s.phase === 'main' && s.sf >= s.activeEnd))
      && kitCommandOkP(e, 'sig')) {
    const p = rukiaAiP(e, AI_RU_BAND_DISC);
    if (p > 0 && simRnd01() < p) { rukiaDecideAgain(b); return why(b, 'band-disc', 'sig'); }
  }
  return null;
}

registerHooks({
  /** Her spEnder (a landed ender, no link after it): after a K ender the band's L link, after a J ender SHIRAFUNE (not
   *  at zero), else the O ender. A command or null. */
  'rukia-ai-sp-ender'(e: Ent, kit: Kit): string | null {
    const name = e.f.move!.name, l = kitLLink(kit, name);
    if (l && kitKLinkP(kit, name) && kitCommandOkP(e, 'sig', kit, false, l) && simRnd01() < rukiaAiP(e, AI_RU_K_ENDER_L)) return 'sig';
    if (kitJLinkP(kit, name) && !kit.rooted && kitCommandOkP(e, 'sp2') && rukiaAiBarsP(e)
        && simRnd01() < rukiaAiP(e, AI_RU_J_ENDER_SP2)) return 'sp2';
    if (!aiSbFinishP(e) && kitCommandOkP(e, 'kikon', kit, true) && simRnd01() < rukiaAiP(e, AI_RU_ENDER_O)) return 'kikon';
    return null;
  },
  /** Her forms' reflex: zero's REIDO answers; the timed Hoho; the stun cashed with her ice / O; -50's Hoho in; the
   *  Shikai's HAKUREN at range; the bands' disc up close. */
  'rukia-ai-reflex'(e: Ent, b: Brain, s: Snap, d: number): string | null {
    const form = kitOf(e).form;
    return (form === 'zero' ? rukiaAiZero(e, b, s, d) : null)
      ?? rukiaAiPerfectHoho(e, b, s, d)
      ?? rukiaAiCash(e, b, s, d)
      ?? (form === 'm50' ? rukiaAiHohoIn(e, b, d) : null)
      ?? rukiaAiZone(e, b, d)
      ?? rukiaAiBandDisc(e, b, s, d);
  },
  /** Her forms' assistGuard (AUTO GUARD): REIDO at zero and the timed Hoho. */
  'rukia-assist-guard'(e: Ent, b: Brain, s: Snap, d: number): string | null {
    return (kitOf(e).form === 'zero' ? rukiaAiZero(e, b, s, d) : null) ?? rukiaAiPerfectHoho(e, b, s, d);
  },
});
