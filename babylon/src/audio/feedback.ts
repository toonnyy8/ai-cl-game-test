// feedback.ts <- the sound half of duel/lisp/feedback.lisp FEEDBACK-SYSTEM (and hud.lisp's PIPS-SHATTER): which sounds a sim
// event plays, with the Lisp's gains and pitches. SFX-ON = from the fighter (his position + 1 m), SFX-AT = from the event's
// point, PLAY-SFX = not positional (x NaN). Cosmetic only: reads the world, never writes it (its coin is Math.random).
import { type Ent, type SimEvent, type World, passiveP } from '../sim/types';

export interface Sink {
  /** Play KEY from world point (X Y Z) (X NaN: not positional). */
  play(key: string, gain: number, pitch: number, x: number, y: number, z: number): void;
  /** SIDE's Breaker hum loop on / off. */
  hum(side: number, on: boolean): void;
}

const ent = (w: World, side: unknown): Ent => (side === 0 ? w.p1 : w.p2);
const blade = (e: Ent): unknown => e.f.kit.blade?.[0];

/** The sounds of event E (fighters in its args are side numbers, as emit() stores them). */
export function feedback(e: SimEvent, w: World, s: Sink): void {
  const a = e.args, n = (i: number) => a[i] as number;
  const on = (key: string, side: unknown, gain = 1, pitch = 1) => { const p = ent(w, side).pos; s.play(key, gain, pitch, p[0], p[1] + 1, p[2]); };
  const at = (key: string, i: number, gain = 1, pitch = 1) => s.play(key, gain, pitch, n(i), n(i + 1), n(i + 2));
  const flat = (key: string, gain = 1) => s.play(key, gain, 1, NaN, 0, 0);
  switch (e.kind) {
    case 'swing': on(a[1] === 'quick' ? 'whoosh-light' : ent(w, a[0]).f.kit.swingSfx ?? 'whoosh-heavy', a[0], 0.7); break;
    case 'super': on('whoosh-heavy', a[0], 1, 0.7); break;
    case 'breaker': s.hum(n(0), true); break;
    case 'breaker-end': s.hum(n(0), false); break;
    case 'rush': case 'kikon-follow': on('whoosh-heavy', a[0], 1, 0.6); break;
    case 'rush-dash': { const k = ent(w, a[0]).f.move?.params.sfx; if (typeof k === 'string') on(k, a[0]); break; }
    case 'hit': {                                    // show-hit: (att def x y z hitstop counter dmg kind)
      const k = a[8], b = blade(ent(w, a[0]));
      at(k === 'breaker' ? 'punch' : k === 'fire' ? 'explode' : k === 'bind' ? 'bones' : k === 'ice' ? 'freeze'
        : b === 'embers' || b === 'charcoal' ? 'sizzle' : k === 'quick' ? 'cut' : 'cut-heavy', 2, k === 'quick' ? 0.8 : 1);
      break;
    }
    case 'blocked': {                                // West's ward (not the ice one) flares; every block clangs
      const d = ent(w, a[1]);
      if (passiveP(d, 'ward') && !passiveP(d, 'freeze-touch')) at('sizzle', 2);
      at('clang', 2);
      break;
    }
    case 'armored': {
      const d = ent(w, a[0]), b = blade(d);
      if (b === 'embers' || b === 'charcoal' || b === 'fire') at('sizzle', 1);
      else { at('cut', 1, 0.7); if (d.f.kit.absorbSfx) on(d.f.kit.absorbSfx, a[0], 0.8); }
      break;
    }
    case 'absorbed': {
      const d = ent(w, a[0]);
      at('cut', 1, 0.7);
      if (d.f.kit.absorbSfx && Math.random() < 0.5) on(d.f.kit.absorbSfx, a[0], 0.8);
      break;
    }
    case 'parried': at('clang', 2); at('sizzle', 2); break;
    case 'scorch': on('sizzle', a[0], 0.5, 1.3); break;
    case 'ward-crush': on('sizzle', a[0], 1, 0.6); on('heat-flare', a[0], 0.8, 0.6); break;
    case 'cold-crack': on('hand-crack', a[0]); break;
    case 'refused': on('clang', a[0], 0.35, 1.6); break;
    case 'guard-crush': at('guard-break', 2, 1, 1.2); at('clang', 2, 1, 0.8); break;
    case 'guard-back': on('clang', a[0], 0.5, 1.4); break;
    case 'guard-break': case 'stance-break': at('guard-break', 2); break;
    case 'clash': at('clash', 0); break;
    case 'hazard-cut': at('cut-heavy', 0); break;
    case 'step': on('step', a[0], 0.6); break;
    case 'hoho-out': on('hoho-out', a[0]); break;
    case 'hoho-in': on('hoho-in', a[0]); break;
    case 'perfect': flat('perfect'); break;
    case 'burst': on('clash', a[0], 1, a[2] === 'white' ? 0.9 : 0.7); on('hoho-in', a[0]); break;
    case 'burst-end': on('hoho-out', a[0], 0.5, 0.8); break;
    case 'launch': on('launch', a[0], 0.8); break;
    case 'land': on('land', a[0]); break;
    case 'konpaku': flat('konpaku-shatter'); break;
    case 'kikon': flat('bell'); break;
    case 'awaken': on('awaken-boom', a[0]); break;
    case 'evolution': flat('evolution'); break;
    case 'skeleton-rise': s.play('bones', 1, 1, n(0), 0.5, n(1)); break;
    case 'sfx': on(a[0] as string, a[1]); break;
    case 'reset': flat('bell', 0.6); break;
    case 'rung':                                     // a cup up the NOME ladder (NOMIHOSE: the boom too)
      if (a[1]) { if (ent(w, a[0]).f.form === 'nomihose') on('awaken-boom', a[0]); on('tier-up', a[0]); }
      break;
    case 'rift-cut': s.play('rift-cut', 1, 1, n(1), 1.15, n(2)); break;
    case 'arm-spend': on('arm-crack', a[0], 0.9); break;
    case 'arm-crack': on('arm-crack', a[0], 0.6); break;
    case 'arm-burst': on('arm-burst', a[0]); break;
  }
}

/** Every event kind feedback.lisp gives a sound (breaker-end only stops one): the coverage test's list. */
export const SOUNDING = ['swing', 'super', 'breaker', 'rush', 'kikon-follow', 'rush-dash', 'hit', 'blocked', 'armored', 'absorbed',
  'parried', 'scorch', 'ward-crush', 'cold-crack', 'refused', 'guard-crush', 'guard-back', 'guard-break', 'stance-break', 'clash',
  'hazard-cut', 'step', 'hoho-out', 'hoho-in', 'perfect', 'burst', 'burst-end', 'launch', 'land', 'konpaku', 'kikon', 'awaken',
  'evolution', 'skeleton-rise', 'sfx', 'reset', 'rung', 'rift-cut', 'arm-spend', 'arm-crack', 'arm-burst'];
