// ken.ts <- duel/lisp/ken.lisp, the BASE form only: ZARAKI KENPACHI's moves (defmove), his base kit (defkit) and the
// hooks it uses. Nozarashi's three cups (NOME), the Bankai and KATAUDE are M3: Awaken is refused until those kits are
// registered. Clip names are the art contract. The kit's ai table is data (M2 ports ai.lisp and the ken-* CPU hooks).
import { T } from '../sim/tuning';
import { stanceRelease } from '../sim/rules';
import { defkit, defmove, defmoveCopy, kitNext, registerHooks } from '../sim/kit';
import { emit, kitOf, type Ent } from '../sim/types';
import { callout, moveParam, startMove } from '../sim/fighter';
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
