// combat.ts <- duel/lisp/combat.lisp: what happens when fighters touch. hitSystem (clash check, then COLLECT every
// fighter's and hazard's hits, then APPLY them all: a trade is a trade, no side goes first; then settle the souls they
// broke), applyHit (the triangle, damage, reactions, chip, gauges, hitstop, KOSEI; the Kikon rush's strike becomes the
// Kikon here), Kikon / Soul Break / awakening / form changes (settled here, at connect time; cinematics only present
// them), the perfect-Hoho test and gaugeSystem. Decisions are rules.ts's; effects are emitted for the renderer.
import { T } from './tuning';
import { fwdX, fwdZ, roundHalfEven } from './math';
import {
  awakeningGain, breakerClashP, burn, burnAmount, burstAllowedP, burstDrain, burstDueP, burstFsGain, burstGainMult, burstHeal,
  burstMode, blockstun, cancelOpenP, chipDamage, comboStep, contactOf, cutValue, drinkAdv, drinkSplit, fsRegen, frostNext,
  gaugeAdd, ggDrain, ggIdleNext, ggRegen, hitDamage, hitGains, hitstun, inFrontP, kikonFollowStun, kikonFollowUnguardableP,
  kikonOutcome, kikonRefund, kikonResult, koseiGain, ladderRung, meterDrain, nomeGain, opticP, perfectHohoP, pierceRate,
  pipSpend, pipStep, rangedHitP, reiatsuGain, resetPlacement, resolveContact, secondsToFrames, soulBreakP, stanceStore,
  stringPipDueP, stunAdd, stunDecay, stunOverP, tempBandAt, tempNext, bankaiAllowedP, redP,
  type BurstMode, type Contact, type DefState, type Rung,
} from './rules';
import {
  callHook, findKit, hasKit, kitAtkMods, kitCommandMove, kitDefMods, kitHook, kitKikonCine, kitNext, makeHitwin,
  moveFollowsP, mvTotal, stunToleranceOf, type HitWin, type Move,
} from './kit';
import {
  W, clog, emit, fighters, kitOf, oppOf, passiveP, sideName, stateOf, type Ent, type Fighter, type Gauges, type Hazard,
  type Pending,
} from './types';
import {
  PERFECT_HW, awakenStateP, breakerPhase, callout, defenderState, enderPush, refreshLook, setBlockstun, setReaction,
  setSlide, startMove, toIdle, viewStep,
} from './fighter';
import { clearHazards, closeRifts, collectHazardHits, hazardConnected, hazardThreatP, spawnHazard } from './hazards';
import { faceEachOther, matchOver, startCine } from './match';
import { volHitP, type Vol } from './hitvol';

const hitstop = (frames: number): void => W.time.requestHitstop(frames);

// ---------------------------------------------------------------- damage and gauges
/** The fighter taking E's gains now, or null: the opponent's kit's siphon hook (o e) is true while something of his
 *  drains E. Siphoned, E gains nothing from a hit; his Reiatsu and flash-step gains go to that fighter. */
export function siphonOf(e: Ent): Ent | null {
  const o = oppOf(e), h = o.alive ? kitHook(kitOf(o), 'siphon') : null;
  return h && h(o, e) ? o : null;
}
/** E gains R Reiatsu and FS flash-step (each kept at its max; no flash-step during a burst). */
export function payGauges(e: Ent, r: number, fs: number): void {
  const g = e.g;
  g.reiatsu = gaugeAdd(g.reiatsu, r, T.reiatsuMax);
  g.fs = gaugeAdd(g.fs, burstFsGain(fs, g.burst), T.fsMax);
}
/** Reiatsu, flash-step and Fighting Spirit for dealing DEALT / taking TAKEN damage. */
export function gainGauges(e: Ent, dealt: number, taken: number): void {
  const g = e.g, to = siphonOf(e);
  const [r, fs, aw, sr, sfs] = hitGains(dealt, taken, !!to, burstGainMult(g.burst));
  payGauges(e, r, fs);
  if (to) payGauges(to, sr, sfs);
  if (!g.awakened) g.awaken = gaugeAdd(g.awaken, aw, T.awakenMax);
}
/** DEF loses DMG Reishi (ATT dealt it; a CPU attacker's anti-stall heat resets). Reishi at 0 is an automatic Soul Break,
 *  settled at the end of the step: returns true then. */
export function dealDamage(att: Ent, def: Ent, dmg: number): boolean {
  const ga = att.g, gd = def.g;
  gd.reishi = Math.max(0, gd.reishi - dmg);
  ga.dealt += dmg;
  if (att.brain) att.brain.heat = 0;
  def.f.comboDmg += dmg;
  gainGauges(att, dmg, 0);
  gainGauges(def, 0, dmg);
  nomeGainBang(att, dmg, 0, 0);
  nomeGainBang(def, 0, dmg, 0);
  if (soulBreakP(gd.reishi)) {
    if (!W.soulBreaks.some((s) => s[1] === def)) W.soulBreaks.push([att, def]);
    return true;
  }
  return false;
}
/** NOME (a form with meterGain: Nozarashi's cups) for DEALT / TAKEN / DRUNK points; a gain restarts RYOTE's delay. */
export function nomeGainBang(e: Ent, dealt: number, taken: number, drunk: number): void {
  const mg = kitOf(e).meterGain;
  if (mg && !siphonOf(e)) {
    const n = nomeGain(dealt, taken, drunk, mg), g = e.g;
    if (n > 0) { g.meter = gaugeAdd(g.meter, n, kitOf(e).meter?.max ?? 100); g.meterIdle = 0; }
  }
}
/** The opponent outplayed E: E's respectCallout (a callout only). */
export function respect(e: Ent): void { const c = kitOf(e).respectCallout; if (c) callout(e, c); }
/** The kit meter (Inferno) of E's form, if it has one and isn't running as a timer. */
export function addMeter(e: Ent, amount: number): void {
  const g = e.g, m = kitOf(e).meter;
  if (m && amount > 0 && g.formLeft === 0 && !siphonOf(e)) g.meter = gaugeAdd(g.meter, amount, m.max);
}
/** KOSEI: a contact of ATT's own melee hit window worth guard value G pays him Reiatsu and flash-step, x koseiMult of his
 *  guard gauge. Siphoned, it pays the siphoning side. */
export function kosei(att: Ent, g: number, x: number, y: number, z: number): void {
  const to = siphonOf(att) ?? att;
  const [r, fs, m] = koseiGain(g, att.g.gg);
  payGauges(to, r * burstGainMult(att.g.burst), fs);                 // ORANGE: x1.5 Reiatsu
  emit('kosei', to, m, x, y, z);
}

// ---------------------------------------------------------------- one hit
/** E's guard gauge loses V (its regen waits T.ggDelay again). At 0 he is guardless until it is full. True when emptied. */
export function drainGuard(e: Ent, v: number, why = 'block'): boolean {
  const g = e.g;
  const [n, crushed] = ggDrain(g.gg, v);
  g.gg = n; g.ggIdle = 0;
  if (crushed && !g.guardless) { g.guardless = true; clog(() => `${sideName(e)} GUARDLESS ${why}`); }
  return crushed;
}
/** E's ward is broken: Bankai West drops to his kit's dropTo form; a kit with a crushHook calls it instead. */
export function wardDrop(e: Ent): void {
  if (passiveP(e, 'ward')) {
    const h = kitOf(e).crushHook;
    if (h) callHook(h, e);
    else { setForm(e, kitOf(e).dropTo!); emit('ward-crush', e); }
    clog(() => `${sideName(e)} WARD BROKEN`);
  }
}
/** E's cold gauge (a temp kit meter) changes by N, clamped to 0 .. T.coldMax. */
export function coldAdd(e: Ent, n: number): void {
  if (kitOf(e).meter?.temp && (n <= 0 || !siphonOf(e))) e.g.meter = Math.max(0, Math.min(T.coldMax, e.g.meter + n));
}
/** DEF's scorch (Bankai West): a melee hit his parry caught burns ATT N (never kills). */
export function scorch(att: Ent, def: Ent, n = T.scorch): void {
  if (passiveP(def, 'scorch') && n > 0) {
    att.g.reishi = burn(att.g.reishi, n);
    emit('scorch', att);
    clog(() => `${sideName(att)} scorched ${n}`);
  }
}
/** E's absolute zero: the melee hit her ward just blocked freezes ATT (a bind hazard at his feet a frame later). */
export function freezeTouch(e: Ent, att: Ent): void {
  const q = att.pos;
  e.g.froze = true;
  spawnHazard('freeze', e, { x: q[0], z: q[2], size: 0.7, y: 2.2, delay: 1, life: 2,
    hw: makeHitwin({ dmg: 0, react: 'bind', stun: T.freezeTouch, hs: T.hitstopHeavy, frost: T.freezeTouch, flags: ['unguardable', 'ice'] }) });
  emit('sfx', 'freeze', e);
  clog(() => `${sideName(e)} FREEZE-TOUCH ${sideName(att)}`);
}

export interface ApplyOpts {
  mv?: Move | null; hazard?: Hazard | null; defState: DefState; bonus?: number; crush?: boolean; x?: number; z?: number; red?: boolean;
}
/** Apply hit HW of ATT to DEF, coming from (SX SZ) (the attacker or the HAZARD: guard facing and push direction). MV,
 *  BONUS and CRUSH: ATT's move and its state when the hit was collected; DEF-STATE and RED: DEF's when collected. A Kikon
 *  rush strike that hits with ATT still holding its button knocks DEF back and ATT dashes in to the follow-up strike,
 *  whose hit is the Kikon (queued for settleSouls). Returns resolveContact's result (null = no effect). */
export function applyHit(att: Ent, def: Ent, hw: HitWin, sx: number, sz: number, o: ApplyOpts): Contact | null {
  const mv = o.mv ?? null, hazard = o.hazard ?? null, bonus = o.bonus ?? 0, red = !!o.red;
  const fa = att.f, fd = def.f, flags = hw.flags, p = def.pos;
  const d2 = (p[0] - sx) ** 2 + (p[2] - sz) ** 2;                    // DEF's distance (squared) from the attacker
  const ranged = rangedHitP(hazard, flags, mv?.params.meleeRange, d2);
  const optic = opticP(passiveP(def, 'ward'), passiveP(def, 'optic'), ranged);   // Rukia's absolute zero: ranged hits pass
  const defState: DefState = optic && o.defState === 'guard' ? 'neutral' : o.defState;
  const ward = (passiveP(def, 'ward') || (defState === 'parry' && passiveP(def, 'parry-block'))) && !optic;
  const k = passiveP(att, 'pierce') ? pierceRate(att.g.gg, mv?.params.pierceMult ?? 1.0) : 0;   // Bankai East's pierce
  const rush = !!mv && mv.kind === 'kikon';
  const own = !!mv && fa.move === mv;                                // the attacker is still in that move
  const fstrike = rush && own && fa.follow;                          // the dash-in's strike: the Kikon if it hits
  const crushR = mv?.params.crushRange as number | undefined;
  let res = resolveContact(defState, {
    breaker: flags.includes('breaker'),
    guardCrush: flags.includes('guard-crush') || !!o.crush || (crushR != null && d2 < crushR * crushR),
    inFront: inFrontP(def.yaw, p[0], p[2], sx, sz, T.guardArc),
    unguardable: flags.includes('unguardable') || (fstrike && kikonFollowUnguardableP(red)),
    hazard: ranged, ward, rend: flags.includes('rend'),
  });
  const atk = kitAtkMods(kitOf(att), T.konpakuMax - att.g.konpaku,
                         (res === 'blocked' ? 1.0 : 1.0 + k) * (own && fa.assisted ? T.assistMult : 1.0));   // ASSIST
  const dmods = optic ? { mult: 1.0 } : kitDefMods(kitOf(def));
  const x = o.x ?? p[0], z = o.z ?? p[2], y = p[1] + 1.1;
  const base = hw.dmg + bonus;
  const outcome = rush ? kikonOutcome(att.pilot.vpad.down('kikon'), res, fstrike) : null;
  const follow = outcome === 'follow';
  if (outcome === 'kikon') {
    res = 'kikon';
    if (!W.kikons.some((kk) => kk[1] === def)) W.kikons.push([att, def, mv!]);
  }
  if (!res) return null;
  const first = own && fa.contact !== 'hit' && contactOf(res) === 'hit';   // its first real hit
  if (own) {                                                         // only a real hit counts as one
    fa.contact = contactOf(res) === 'hit' ? 'hit' : (fa.contact ?? 'block');
    if (fa.landSf < 0) fa.landSf = fa.sf;
  }
  clog(() => `${sideName(att)} ${mv ? mv.name : hazard ? hazard.kind : 'counter'} -> ${sideName(def)} ${res} ${base}`);
  if (contactOf(res) === 'hit') closeRifts(def);                    // a rift closes if its owner is hit before it cuts
  if (own && !ranged && res !== 'parried' && res !== 'kikon') kosei(att, hw.guard ?? 0, x, y, z);   // his own blade
  if (res === 'counter') { respect(def); att.g.counters++; }
  switch (res) {
    case 'kikon': break;                                             // settled at the end of the step
    case 'hit': case 'counter': {
      const [react0, hits, launches, air] = comboStep(follow ? 'stagger' : hw.react, fd.state === 'air', fd.comboHits,
                                                     fd.comboLaunches, fd.comboAir);
      fd.comboHits = hits; fd.comboLaunches = launches; fd.comboAir = air;
      // the hidden stun (every connected hit); past his tolerance this hit blows him away: a knockdown sliding ~5 m, the
      // gauge back to 0. A Kikon rush's strike never does, nor ORANGE's attacker (it lifts his tolerance)
      const gd = def.g;
      const st = stunAdd(gd.stun, follow ? 'stagger' : hw.react, !!mv && (mv.kind === 'sp' || mv.kind === 'kikon'));
      const blow = !rush && att.g.burst !== 'orange' && stunOverP(st, stunToleranceOf(kitOf(def)));
      const react = blow ? 'knockdown' : react0;
      let dmg = hitDamage(base, atk, dmods, hits, res === 'counter');
      if (flags.includes('spare')) dmg = Math.min(dmg, Math.max(0, def.g.reishi - 1));   // never takes the last point
      const stun = follow ? kikonFollowStun(red, mv!.s)
        : hw.stun != null && react === hw.react ? hw.stun             // (a bind in a combo: a flinch)
        : hitstun(react, res === 'counter');
      const frost = Math.max(hw.frost, kitOf(att).frostTouch);
      gd.stun = blow ? 0 : st; gd.stunIdle = 0;
      if (frost > 0) fd.frost = frostNext(fd.frost, frost);          // Rukia's ice
      if (ranged) def.g.takenRanged += dmg; else def.g.takenMelee += dmg;
      coldAdd(def, -(T.ruHitWarm * dmg));                            // Rukia: a real hit warms her
      att.g.bestCombo = Math.max(hits, att.g.bestCombo);
      addMeter(att, hw.meter);
      hitstop(hw.hs);
      emit('hit', att, def, x, y, z, hw.hs, res === 'counter', dmg,
           flags.includes('ice') ? 'ice' : react === 'bind' ? 'bind' : flags.includes('blade') ? 'flash'
           : flags.includes('thread') ? 'quick' : hazard ? 'fire' : mv ? mv.kind : 'counter');
      if (!dealDamage(att, def, dmg)) {                              // (a broken soul crumples in its cinematic)
        if (blow) {
          setReaction(def, react, stun, sx, sz, T.stunBlowKb);       // the blow-away
          W.blowAways++;
          clog(() => `${sideName(def)} BLOWN AWAY by ${sideName(att)} (combo hit ${hits})`);
        } else {
          setReaction(def, react, stun, sx, sz, follow ? T.kikonFollowKb : hw.kb);
          if (own && !hazard && mv!.flags.includes('ender') && (mv!.kind === 'quick' || mv!.kind === 'flash'))
            enderPush(att, def, mv!);                                // J3 / K3: out of J1 / K1's reach at once
          if (own && !hazard && !fa.chained && (mv!.kind === 'quick' || mv!.kind === 'flash')
              && mv === kitCommandMove(kitOf(att), mv!.kind === 'quick' ? 'q' : 'f')) {   // a string's opener hit: the
            const pull = Math.sqrt(d2) - T.stringPullTo;                 // attacker dashes in point-blank, so the
            if (pull > 0.01) setSlide(att, pull, T.stringPullFrames, p[0] - sx, p[2] - sz);   // links reach him
          }
        }
      }
      if (follow && own) {                                           // the rush dashes in, then strikes again
        fa.phase = 'follow'; fa.hold = 0; fa.follow = true;
        emit('kikon-follow', att, def);
        emit('rush-dash', att);
        clog(() => `${sideName(att)} KIKON FOLLOW-UP on ${sideName(def)}${red ? ' (red)' : ''}`);
      }
      break;
    }
    case 'armored':                                                  // a move's armour (one hit spent)
      if (defState === 'armor') fd.armorLeft--;
      hitstop(T.hitstopBlock);
      emit('armored', def, x, y, z);
      dealDamage(att, def, hitDamage(base, atk, dmods, 1, false));
      break;
    case 'parried': {                                                // the attacker staggers, the parry counters
      hitstop(T.hitstopBreaker);
      respect(att);
      setReaction(att, 'stagger', T.parryStun, p[0], p[2], T.parrySlide);
      fa.armorLeft = 0;
      scorch(att, def);
      if (passiveP(def, 'ward') && !siphonOf(def)) { def.g.gg = T.ggMax; def.g.ggIdle = 0; }   // the catch refills his gauge
      const h = kitHook(kitOf(def), 'parried');
      if (h && !siphonOf(def)) h(def, att);
      emit('parried', att, def, x, y, z);
      const c = fd.move ? kitNext(kitOf(def), fd.move.name, 'land') : null;
      if (c) startMove(def, c);
      break;
    }
    case 'absorbed': {
      const dmg = hitDamage(base, atk, dmods, 1, false);
      fd.stored = stanceStore(fd.stored, dmg);
      hitstop(T.hitstopBlock);
      emit('absorbed', def, x, y, z);
      dealDamage(att, def, dmg);
      nomeGainBang(def, 0, 0, dmg);                                  // the stance drinks what it absorbs (NOME)
      break;
    }
    case 'blocked': {                                                // blockstun, chip, the guard gauge (at 0: GUARD CRUSH)
      const drink = passiveP(def, 'drink');
      const catchHook = ranged && fd.move ? (fd.move.params.catch as string | undefined) : undefined;   // a shield's catch
      const a0 = mv && Number.isInteger(mv.advBlock) ? (mv.advBlock as number) : 0;
      const adv = (drink && mv ? drinkAdv(a0) : a0) - (mv && mv.kind === 'quick' ? T.quickBlockAdv : 0);
      const stun = mv ? blockstun(mvTotal(mv), fa.sf, adv) : T.hazardBlockstun;
      const v0 = hw.guard ?? T.ggHazard, v1 = mv && passiveP(att, 'cut') ? cutValue(v0, mv.kind) : v0;
      const v = ward && passiveP(def, 'ward') ? T.wardMult * v1 : v1;
      const pierce = k > 0 ? k : null;
      const chip = catchHook || passiveP(def, 'chipless') ? 0      // Rukia awakened: no chip on her
        : chipDamage(base, drink ? pierce : (hw.chip ?? (mv ? kitOf(att).bladeChip : null) ?? pierce), def.g.reishi);
      if (catchHook) { callHook(catchHook, def, base); hitstop(T.hitstopBlock); emit('blocked', att, def, x, y, z); }
      else if (drainGuard(def, v)) {
        wardDrop(def);
        setReaction(def, 'guard-break', T.guardCrushStun, sx, sz, T.blockPushback);
        hitstop(T.hitstopBreaker);
        emit('guard-crush', att, def, x, y, z);
        clog(() => `${sideName(def)} GUARD CRUSH${drink ? ' (drinking)' : ''}`);
      } else if (ward) {                                             // super armour: no blockstun, what he does goes on
        setSlide(def, T.blockPushback, 6, p[0] - sx, p[2] - sz);
        fd.warded = W.tick;
        if (passiveP(def, 'freeze-touch') && !ranged && !def.g.froze) freezeTouch(def, att);
        hitstop(T.hitstopBlock);
        emit('blocked', att, def, x, y, z);
      } else {
        setBlockstun(def, stun, sx, sz, adv, drink ? kitOf(def).drinkClip : null);
        hitstop(T.hitstopBlock);
        emit(drink ? 'drink' : 'blocked', att, def, x, y, z);
      }
      if (drink) {                                                   // the drink: real damage, NOME
        const [taken, drunk] = drinkSplit(hitDamage(base, atk, dmods, 1, false));
        dealDamage(att, def, taken);
        nomeGainBang(def, 0, 0, drunk);
      }
      if (chip > 0) dealDamage(att, def, chip);
      if (mv && !ranged) coldAdd(def, T.ruBlockCool * (hw.guard ?? 0));   // Rukia: a blocked blade cools her
      if (hazard && hw.meter > 0) addMeter(att, T.meterOnBlock);
      break;
    }
    case 'guard-break':
      drainGuard(def, T.ggBreaker, 'breaker');
      wardDrop(def);                                                 // a Breaker blows West's ward off: East
      setReaction(def, 'guard-break', T.guardBreakStun, sx, sz, T.guardBreakKb);
      hitstop(T.hitstopBreaker);
      emit('guard-break', att, def, x, y, z);
      break;
    case 'stance-break':
      setReaction(def, 'crumple', T.stanceBreakStun, sx, sz, T.stanceBreakKb);
      hitstop(T.hitstopBreaker);
      emit('stance-break', att, def, x, y, z);
      break;
  }
  kitHook(kitOf(att), 'hit')?.(att, def, res, hw, mv, hazard, ranged);   // a character's own hit rules
  kitHook(kitOf(def), 'struck')?.(def, att, res, hw, mv, hazard, ranged);
  if (first && mv!.onLand && !W.cine) callHook(mv!.onLand, att);
  return res;
}

// ---------------------------------------------------------------- the system
/** E's move windows open this frame that touch the opponent (each window hits once), and a perfect Hoho's counter
 *  strike on its frame (it always connects). */
export function collectMelee(e: Ent, f: Fighter): void {
  const mv = f.move, o = f.opp!, p = e.pos;
  if (!o.alive) return;
  if (f.state === 'hoho' && f.perfect && f.sf === T.hohoCounterStrike)
    W.pending.push({ att: e, def: o, hw: PERFECT_HW, i: 0, sx: p[0], sz: p[2], hazard: null, state: defenderState(o),
                     red: false, mv: null, bonus: 0, crush: false });
  if (f.state === 'move' && f.phase === 'main' && mv) {
    const sf = f.sf, q = o.pos, fx = fwdX(e.yaw), fz = fwdZ(e.yaw), go = o.g;
    mv.hits.forEach((w, i) => {
      if (w.from <= sf && sf < w.to && !(f.hits & (1 << i))
          && w.vols.some((v) => volHit(v, p, fx, fz, q, o)))
        W.pending.push({ att: e, def: o, hw: w, i, sx: p[0], sz: p[2], hazard: null, state: defenderState(o), mv,
                         red: redP(go.reishi, go.reishiMax), bonus: f.dmgBonus, crush: f.crush });
    });
  }
}
const volHit = (v: Vol, p: number[], fx: number, fz: number, q: number[], o: Ent): boolean =>
  volHitP(v, p[0], p[1], p[2], fx, fz, q[0], q[1], q[2], o.body.hurtR, o.body.hurtH, 0);

/** Nozarashi (projectile-cut): an open window of E's move destroys the opponent's hazards it touches. */
export function cutHazards(e: Ent, f: Fighter): void {
  const mv = f.move;
  if (!(passiveP(e, 'projectile-cut') && f.state === 'move' && f.phase === 'main' && mv)) return;
  const sf = f.sf, p = e.pos, fx = fwdX(e.yaw), fz = fwdZ(e.yaw);
  for (const w of mv.hits) {
    if (!(w.from <= sf && sf < w.to)) continue;
    for (const hz of [...W.hazards]) {
      if (hz.alive && hz.owner !== e && ['wave', 'fireball', 'bind'].includes(hz.kind) && hz.delay <= 0
          && w.vols.some((v) => volHitP(v, p[0], p[1], p[2], fx, fz, hz.x, 0, hz.z, Math.max(0.5, hz.size), 1.8, 0))) {
        emit('hazard-cut', hz.x, 1 + hz.y, hz.z);
        clog(() => `${sideName(e)} cuts ${hz.kind}`);
        hz.alive = false;
      }
    }
  }
}

/** Breaker vs Breaker: both pushed T.clashPush apart and stunned T.clashStun, no damage. */
export function clash(a: Ent, b: Ent): void {
  const p = a.pos, q = b.pos;
  setReaction(a, 'clash', T.clashStun, q[0], q[2], 0.5 * T.clashPush);
  setReaction(b, 'clash', T.clashStun, p[0], p[2], 0.5 * T.clashPush);
  hitstop(T.hitstopBreaker);
  emit('clash', 0.5 * (p[0] + q[0]), 1.2, 0.5 * (p[2] + q[2]));
  clog(() => 'CLASH');
}

/** Clash first; then collect every melee and hazard hit of this step; then apply them all; then settle the souls. */
export function hitSystem(): void {
  const a = W.p1, b = W.p2;
  const pa = breakerPhase(a), pb = breakerPhase(b);
  if (pa && pb && breakerClashP(pa, pb, a.f.dist)) clash(a, b);
  for (const e of fighters()) cutHazards(e, e.f);
  for (const e of fighters()) collectMelee(e, e.f);
  collectHazardHits();
  const hits: Pending[] = W.pending;
  W.pending = [];
  for (const h of hits) {
    const fa = h.att.f, mv = h.mv;
    const res = applyHit(h.att, h.def, h.hw, h.sx, h.sz,
                         { mv, hazard: h.hazard, defState: h.state, red: h.red, bonus: h.bonus, crush: h.crush });
    if (res) {
      if (h.hazard) hazardConnected(h.hazard);
      else if (mv && mv === fa.move) fa.hits |= 1 << h.i;            // (an on-land hook may have started the next move)
    }
  }
  W.hazards = W.hazards.filter((hz) => hz.alive);
  settleSouls();
}

// ---------------------------------------------------------------- perfect Hoho
/** Would a Hoho started now by E be PERFECT? An opponent hit volume active now or within T.perfectLead frames overlaps
 *  E's hurt cylinder grown by T.perfectInflate, or his Breaker / Kikon rush dash is within 0.5 m of its trigger range. */
export function perfectNowP(e: Ent): boolean {
  const o = oppOf(e), fo = o.f, mv = fo.move, p = e.pos, q = o.pos, b = e.body;
  if (fo.state === 'move' && fo.phase === 'main' && mv
      && mv.hits.some((w) => perfectHohoP(fo.sf, w.from, w.to, w.vols, q[0], q[1], q[2], fwdX(o.yaw), fwdZ(o.yaw),
                                          p[0], p[1], p[2], b.hurtR, b.hurtH))) return true;
  if (fo.state === 'move' && fo.phase === 'dash' && mv
      && fo.dist <= (mv.kind === 'kikon' ? T.kikonTrigger : T.breakerTrigger) + 0.5) return true;
  return hazardThreatP(o, e);
}

// ---------------------------------------------------------------- Burst Reverse
/** The burst mode E's state gives a press now, or null. ORANGE: his move's own hit landed and its cancel window is open;
 *  or his L / O has the opponent in hitstun / blockstun; or, free or in any move, while the opponent reels from one of
 *  his hazards (free, that replaces WHITE). */
export function burstModeOf(e: Ent): BurstMode | null {
  const f = e.f, mv = f.move, st = f.state, o = f.opp, os = o && o.alive ? o.f.state : null;
  if ((st === 'idle' || st === 'guard' || st === 'run') && (os === 'stun' || os === 'air') && f.lock === 0) return 'orange';
  return burstMode(st, f.lock > 0, f.comboHits,
    st === 'move' && !!mv && f.phase === 'main'
      && (mv.kind === 'sig' || mv.kind === 'kikon'
        ? os === 'stun' || os === 'guard-hit' || os === 'air'
        : os === 'stun' || os === 'air' || cancelOpenP(f.sf, f.landSf, mvTotal(mv), f.contact === 'hit')));
}
/** May E burst now: the mode or null. */
export function burstOkP(e: Ent): BurstMode | null {
  const m = burstModeOf(e);
  return burstAllowedP(m, e.g.fs, e.g.burst) ? m : null;
}
/** E breaks free (a Burst, an awakening): neutral at once, invulnerable T.burstInvuln f, his combo over; the opponent's
 *  move / Hoho / step / run ends and he slides T.burstPush away, not stunned. */
export function repel(e: Ent): void {
  const f = e.f, mo = e.mo, o = f.opp!, p = e.pos, q = o.pos;
  p[1] = 0; mo.grounded = true; mo.kbLeft = 0;
  toIdle(e, 0);
  f.invuln = T.burstInvuln;
  if (['move', 'hoho', 'step', 'run'].includes(stateOf(o))) { toIdle(o, 0); o.look.alpha = 1; }
  setSlide(o, T.burstPush, T.burstPushFrames, q[0] - p[0], q[2] - p[2]);
  respect(o);
}
/** A burst of MODE starts (applied once both fighters stepped): the flash-step drains from now. BLUE breaks free;
 *  ORANGE cancels his move's recovery, the next move within T.chainWindow f has its startup cut. A short hitstop. */
export function burst(e: Ent, mode: BurstMode): void {
  const o = oppOf(e), g = e.g, f = e.f;
  g.burst = mode; g.burstT = 0; g.fsIdle = 0;
  if (mode === 'blue') { repel(e); g.reiatsu = gaugeAdd(g.reiatsu, T.reiatsuBar, T.reiatsuMax); }   // + one Reiatsu bar
  else if (mode === 'orange') { toIdle(e, 0); f.chain = T.chainWindow; }
  hitstop(T.burstHitstop);
  emit('burst', e, o, mode);
  clog(() => `${sideName(e)} BURST ${mode} fs ${g.fs.toFixed(1)}`);
}
/** E's burst ends (its flash-step ran out, or a reset): the regen delay restarts. */
export function burstEnd(e: Ent): void {
  const g = e.g;
  if (g.burst) {
    clog(() => `${sideName(e)} BURST END ${g.burst}`);
    g.burst = null; g.burstT = 0; g.fsIdle = 0; e.f.chain = 0;
    emit('burst-end', e);
  }
}
/** WHITE's regen on its frame N (1-based): Reishi, Reiatsu and (not yet awakened) the awakening gauge. */
export function whiteRegen(g: Gauges, n: number): void {
  g.reishi = Math.min(g.reishiMax, g.reishi + burstHeal(n, T.whiteReishi));
  g.reiatsu = gaugeAdd(g.reiatsu, T.whiteReiatsu / 60, T.reiatsuMax);
  if (!g.awakened) g.awaken = gaugeAdd(g.awaken, T.whiteAwaken / 60, T.awakenMax);
}
/** A running burst, one frame: the flash-step drains, WHITE's regen; at 0 it ends. */
export function burstStep(e: Ent, g: Gauges): void {
  const n = ++g.burstT;
  g.fs = burstDrain(g.fs);
  if (g.burst === 'white') whiteRegen(g, n);
  if (g.fs <= 0) burstEnd(e);
}
export const awakeRegenFrames = (): number => roundHalfEven(60 * (T.fsMax / T.burstDrain));
export function startAwakeRegen(g: Gauges): void { g.awakeRegen = awakeRegenFrames(); g.awakeT = 0; }

// ---------------------------------------------------------------- forms, awakening
/** E's character changes to FORM: the old form's exit hook, the new kit, its timer, look and entry hook. */
export function setForm(e: Ent, form: string): void {
  const f = e.f, g = e.g, old = f.kit, nw = findKit(f.character, form);
  if (old.exitHook && old !== nw) callHook(old.exitHook, e);
  f.kit = nw; f.form = form; g.burnStep = 0;
  g.formLeft = nw.duration ? secondsToFrames(nw.duration) : 0;
  g.formTotal = g.formLeft;
  refreshLook(e);
  if (nw.enterHook) callHook(nw.enterHook, e);
  emit('form', e, form);
  clog(() => `${sideName(e)} form ${form}`);
}
/** Awakening (once per match): E breaks free as a Burst does, the kit's awakened form, T.awakenHeal of max Reishi, then
 *  the form's cine (both fighters idle after it). */
export function awaken(e: Ent): void {
  const g = e.g, o = oppOf(e);
  repel(e);
  startAwakeRegen(g);
  g.awakened = true; g.awaken = 0; g.evolution = false;
  setForm(e, kitOf(e).awakenForm!);
  const st = kitOf(e).meter?.start;
  if (st != null) { g.meter = st; g.meterIdle = 0; }
  g.reishi = Math.min(g.reishiMax, g.reishi + roundHalfEven(T.awakenHeal * g.reishiMax));
  emit('awaken', e);
  const cine = kitOf(e).cine;
  if (cine) startCine(cine, e, o, () => { toIdle(e, 0); toIdle(o, 0); });
  else toIdle(e, 0);
}

// ---------------------------------------------------------------- Kenpachi's Bankai: the arm meter
/** The Bankai (P in cup 3): the kit's bankaiForm, its arm meter full, his own Konpaku set to 1, his Reishi refilled. */
export function bankai(e: Ent): void {
  const g = e.g, o = oppOf(e), lost = g.konpaku - 1;
  repel(e);
  startAwakeRegen(g);
  setForm(e, kitOf(e).bankaiForm!);
  g.meter = kitOf(e).pips!.n; g.meterIdle = 0; g.armPending = null; g.armOwed = false;
  g.konpaku = 1; g.reishi = g.reishiMax;
  refreshLook(e);
  if (lost > 0) emit('konpaku', e, lost);
  emit('bankai', e);
  const cine = kitOf(e).cine;
  if (cine) startCine(cine, e, o, () => { toIdle(e, 0); toIdle(o, 0); });
  else toIdle(e, 0);
}
/** A pip command starts MV (or a string's pip is charged as it ends): one pip spent, T.armSelf burnt. The last one: the
 *  burst is pending until MV is over. */
export function armSpend(e: Ent, mv: Move | null): void {
  const g = e.g;
  const [n, ok] = pipSpend(Math.round(g.meter));
  if (ok) {
    g.meter = n; g.meterIdle = 0; g.reishi = burn(g.reishi, T.armSelf);
    if (n === 0) g.armPending = mv ?? 'none';
    refreshLook(e);
    emit('arm-spend', e, n);
  }
}
/** The arm bursts: the kit's pips.to form, T.armBurstSelf burnt and a self-inflicted crumple. */
export function armBurst(e: Ent): void {
  const g = e.g, p = e.pos;
  g.armPending = null; g.armOwed = false;
  setForm(e, kitOf(e).pips!.to);
  g.meter = 0; g.meterIdle = 0; g.reishi = burn(g.reishi, T.armBurstSelf);
  setReaction(e, 'crumple', T.armBurstStun, p[0], p[2], 0);
  callout(e, 'GOMEN NE, KEN-CHAN');
  emit('arm-burst', e);
}
/** The arm meter per step: a finished string's owed pip, the crack clock, the pending burst. */
export function armStep(e: Ent, f: Fighter, g: Gauges): void {
  const mv = f.state === 'move' ? f.move : null, pend = g.armPending;
  if (stringPipDueP(g.armOwed, f.state, mv ? mv.kind : null)) { g.armOwed = false; armSpend(e, mv); }
  if (pend && pend !== 'none' && mv && mv !== pend && moveFollowsP(f.kit, pend, mv)) g.armPending = mv;
  const p2 = g.armPending;
  if (p2) { if (burstDueP(p2, f.move, f.state)) armBurst(e); }
  else {
    const [n, idle, cracked] = pipStep(Math.round(g.meter), g.meterIdle, f.lock > 0);
    g.meter = n; g.meterIdle = idle;
    if (cracked) {
      if (n === 0) g.armPending = (f.state === 'move' ? f.move : null) ?? 'none';
      refreshLook(e);
      emit('arm-crack', e, n);
    }
  }
}

// ---------------------------------------------------------------- Kikon, Soul Break, reset
export function bankaiReadyP(e: Ent): boolean {
  const f = e.f;
  return !!f.kit.bankaiForm && bankaiAllowedP(awakenStateP(e, f), e.g.konpaku);
}
/** Konpaku E's Kikon would take now: a running rush's worth, else the kit's kikonWorth hook, else its kikonKonpaku. */
export function kikonWorth(e: Ent): number {
  const f = e.f, mv = f.move, h = kitHook(kitOf(e), 'kikon-worth');
  if (mv && f.state === 'move' && mv.kind === 'kikon') return f.kikonN;
  if (h) return h(e);
  return kitOf(e).kikonKonpaku;
}
/** Is E's opponent red: would E's Kikon rush, connecting now with the button held, be the Kikon? */
export function kikonReadyP(e: Ent): boolean { const go = oppOf(e).g; return redP(go.reishi, go.reishiMax); }

/** Konpaku at connect time: DEF loses the Kikon's count (ATT's rush's), or on a Soul Break ATT's kikonWorth + 1; his
 *  Reishi refills. True when DEF is out of Konpaku. */
export function settleKonpaku(att: Ent, def: Ent, soulBreak: boolean): boolean {
  const gd = def.g;
  const [left, lost, ko] = kikonResult(gd.konpaku, soulBreak ? kikonWorth(att) : att.f.kikonN, soulBreak);
  gd.konpaku = left; gd.reishi = gd.reishiMax;
  if (!(gd.awakened || siphonOf(def))) gd.awaken = gaugeAdd(gd.awaken, awakeningGain(0, 0, lost), T.awakenMax);
  att.g.kikons++;
  emit('konpaku', def, lost);
  clog(() => `${sideName(att)} ${soulBreak ? 'SOUL BREAK' : 'KIKON'} on ${sideName(def)}: -${lost} konpaku, ${left} left (${att.f.form})`);
  return ko;
}

/** The souls broken during this step's hitSystem, settled together so no side goes first: every confirmed Kikon and every
 *  Reishi that reached 0 (a Kikon's victim has no Soul Break on top). Then one cinematic, then the reset, or the finish
 *  (a draw when both souls ran out). The hazards still out are cleared first. */
export function settleSouls(): void {
  const kk = W.kikons;
  const sb = W.soulBreaks.filter((s) => !kk.some((k) => k[1] === s[1]));
  W.kikons = []; W.soulBreaks = [];
  if (!kk.length && !sb.length) return;
  for (const e of fighters()) burstEnd(e);                           // the reset ends every burst, before the refund
  for (const att of new Set([...kk.map((k) => k[0]), ...sb.map((s) => s[0])])) {   // a flash-step bar and a Reiatsu bar back
    const g = att.g;
    [g.fs, g.reiatsu] = kikonRefund(g.fs, g.reiatsu);
  }
  const kos: Ent[] = [];
  for (const [att, def] of kk) if (settleKonpaku(att, def, false)) kos.push(def);
  for (const [att, def] of sb) if (settleKonpaku(att, def, true)) kos.push(def);
  const a = kk.length ? kk[0][0] : sb[0][0], v = kk.length ? kk[0][1] : sb[0][1];
  for (const [att, def, mv] of kk) { if (mv.callout) callout(att, mv.callout); emit('kikon', att, def); }
  for (const [att, def] of sb) emit('soul-break', att, def);
  clearHazards();
  startCine(kk.length ? (kk[0][2].cine ?? 'soul-break-cine') : kitKikonCine(kitOf(a)), a, v, () => {
    if (!kos.length) resetRound(a, v);
    else if (kos.length > 1) matchOver(null);
    else matchOver(oppOf(kos[0]));
  });
}

/** After a Kikon / Soul Break: both placed T.resetDistance apart facing, T.resetNeutral frames of neutral, P1 on the left
 *  of the view again, hazards cleared, the guard gauges full for everyone, the hidden stun cleared, the forms kept. */
export function resetRound(a: Ent, v: Ent): void {
  const p = a.pos, q = v.pos;
  const [ax, az, bx, bz] = resetPlacement(p[0], p[2], q[0], q[2]);
  p[0] = ax; p[1] = 0; p[2] = az; q[0] = bx; q[1] = 0; q[2] = bz;
  faceEachOther(a, v);
  if (a.f.side === 0) viewStep(a, v, true); else viewStep(v, a, true);
  clearHazards();
  for (const e of [a, v]) {
    const f = e.f, g = e.g, mo = e.mo;
    mo.grounded = true; mo.kbLeft = 0; f.lock = T.resetNeutral; f.comboDmg = 0;
    g.reiatsu = gaugeAdd(g.reiatsu, kitOf(e).resetReiatsu, T.reiatsuMax);
    g.gg = T.ggMax; g.ggIdle = 0; g.guardless = false; g.stun = 0;
    const rf = kitOf(e).resetForm;                                   // Rukia: absolute zero never carries over the reset
    if (rf) { setForm(e, rf); g.meter = 0; g.meterIdle = 0; }
    mo.vel.fill(0);
    e.pilot.vpad.clear();
    if (e.brain) e.brain.pressLeft = 0;                              // a CPU lets go of what it held (a rush's O)
    toIdle(e, 0);
  }
  emit('reset');
}

// ---------------------------------------------------------------- Rukia's cold gauge
export function tempStep(e: Ent, f: Fighter, g: Gauges): void {
  const st = f.state, free = st === 'idle' || st === 'guard' || st === 'run', lock = g.meterIdle;
  const brace = free && passiveP(e, 'ward') && !g.guardless && e.pilot.vpad.down('guard');
  const guarding = lock === 0 && (st === 'guard' || st === 'guard-hit' || brace);
  if (lock > 0) g.meterIdle = lock - 1;
  g.meter = tempNext(g.meter, guarding, f.kit.warm);
  if (brace && drainGuard(e, T.zeroBraceDrain / 60, 'brace')) wardDrop(e);
  else {
    const band = tempBandAt(g.meter, f.form, st);
    if (band !== f.form) { setForm(e, band); emit('sfx', 'frost-tick', e); }
  }
}

// ---------------------------------------------------------------- gauges per step
/** A meter with a ladder (Nozarashi's NOME): while free, the rung NOME asks for is his form; then the rung's drain. */
export function nomeStep(e: Ent, f: Fighter, g: Gauges, ladder: Rung[]): void {
  let i = Math.max(0, ladder.findIndex((r) => r[0] === f.form));
  if (f.state === 'idle' || f.state === 'guard' || f.state === 'run') {
    const j = ladderRung(g.meter, i, ladder);
    if (i !== j) { setForm(e, ladder[j][0]); emit('rung', e, j > i); i = j; }
  }
  const r = ladder[i];
  g.meter = meterDrain(g.meter, r[1], r[2], g.meterIdle);
  g.meterIdle = Math.min(9999, g.meterIdle + 1);
}

/** Regen (Reiatsu; flash-step and the guard gauge after their delays), timed forms (burn, drain, end), the meter's full
 *  form (Hellfire), EVOLUTION. GUARD HOLD: one guarding test gates both the guard gauge's refill and its delay counter. */
export function gaugeSystem(): void {
  for (const e of fighters()) {
    const f = e.f, g = e.g, kit = f.kit;
    const guarding = (f.state === 'guard' || f.state === 'guard-hit' || passiveP(e, 'ward')) && !g.guardless;
    g.reiatsu = gaugeAdd(g.reiatsu, reiatsuGain(0, 0, 1), T.reiatsuMax);
    if (g.burst) burstStep(e, g);                                    // a burst: the gauge drains, no regen
    else { g.fs = fsRegen(g.fs, g.fsIdle); g.fsIdle = Math.min(9999, g.fsIdle + 1); }
    if (g.awakeRegen > 0) { g.awakeRegen--; whiteRegen(g, ++g.awakeT); }   // the awakening's regen (overlaps a burst)
    g.gg = ggRegen(g.gg, g.ggIdle, g.guardless, guarding, g.burst === 'blue', kit.ggRegen);
    g.ggIdle = ggIdleNext(g.ggIdle, guarding);
    g.stun = stunDecay(g.stun, g.stunIdle); g.stunIdle = Math.min(9999, g.stunIdle + 1);   // the hidden stun's decay
    if (g.guardless && g.gg >= T.ggMax) { g.guardless = false; emit('guard-back', e); clog(() => `${sideName(e)} GUARD BACK`); }
    if (f.comboDmg > 0 && !['stun', 'air', 'down', 'wakeup', 'guard-hit'].includes(f.state)) f.comboDmg = 0;
    if (g.formLeft > 0) {
      if (kit.burn > 0) g.reishi = burn(g.reishi, burnAmount(g.reishiMax, kit.burn, g.burnStep));
      g.burnStep++;
      if (--g.formLeft === 0) setForm(e, kit.inherit!);
    }
    if (kit.pips) armStep(e, f, g);
    kitHook(kit, 'tick')?.(e, f, g);                                 // the form's own per-step mechanics
    if (kit.meter?.temp) tempStep(e, f, g);
    const m = kit.meter;
    if (m?.ladder) nomeStep(e, f, g, m.ladder as Rung[]);
    // ponytail: Hellfire is M3: until its kit is registered the full Inferno meter just stays full
    if (m && g.formLeft === 0 && g.meter >= m.max && m.fullForm && hasKit(f.character, m.fullForm)) {
      g.meter = 0;                                                   // the bar now shows the form's timer
      setForm(e, m.fullForm);
      emit('hellfire', e);
    }
    if (!g.awakened && !g.evolution && g.awaken >= T.awakenMax) {
      g.evolution = true;
      if (g.evoT < 0) g.evoT = W.tick;
      emit('evolution', e);
      clog(() => `${sideName(e)} EVOLUTION`);
    }
  }
}
