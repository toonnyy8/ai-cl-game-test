// cinema.ts: the cinematics' player (the director side of engine/lisp/cine.lisp + duel/lisp/cinema.lisp's looks). The sim
// owns each cinematic's clock (w.cine: name, cf; CINES' len and face-each-other beats); every rendered frame this reads
// the script (cine-scripts.ts) at cf and presents it, so a skip or a late frame loses nothing:
//   update()   the actors' poses (a move sampled at a script sf, a library pose, a reaction), body / weapon swaps (the form
//              shown), aura presets, script-posed hazard looks (fire walls, ice rings, clones ...) and one-shot ink sparks,
//              all lent to BattleView.update for one call and given back (the sim state is untouched after it); then the
//              card (the stage hidden, a black / white / tinted sky), silhouettes and back-rims, tints, flashes, hiding
//   camera()   the shot's rail, lens (FOV) and dutch roll, the shake; a portrait screen dollies back on a wide shot
//   the grade  a post process after the paper pass: the impact frames (negative, two-tone, manga page) and the base grades
//              (Yamamoto's spot grey, Senjumaru's desaturation) — BABYLON_LOOK B4's "post flag"
//   overlay    (drawCineOverlay, from hud.ts) letterbox, caption cards (vfx/card.ts), focus lines, ink splash, white flash,
//              Kenpachi's Kusajishi forest, the intro's VS
// In battle: Kenpachi's cup entries (the 'shockwave' / 'nomihose-enter' rings, the NOMIHOSE negative + manga page).
// window.duelCine (debug): play(name, attacker, victim, {aForm, vForm, at}) / at(frame) for stills.
import {
  Color3, Color4, Matrix, PostProcess, ShaderLanguage, ShaderStore, Vector3, type AbstractEngine, type AbstractMesh,
  type FreeCamera,
} from '@babylonjs/core';
import { MOVES, findKit } from '../sim/kit';
import { Hazard, setWorld, type Cine, type Ent, type FState, type SimEvent, type World } from '../sim/types';
import { Match, abortCine, startCine } from '../sim/match';
import { setForm } from '../sim/combat';
import { NAMES, SCRIPTS, type Act, type Ctx, type HzSpec, type Impact, type Script, type Shot, type Who } from './cine-scripts';
import { CLIPS } from './clips';
import { P, type PoseSpec } from './pose';
import { FACE } from './body';
import { BattleView, type FighterView, type Stage } from './scene';
import { CAPS, drawCard, type Cap } from './vfx/card';
import { swash } from './vfx/inkhud';
import { inkText } from './vfx/brush';
import { DuelCamera } from './camera';
import { updateCel } from './cel';
import { drawBattle, hudSize } from './hud';

// ---------------------------------------------------------------- the grade post (impact frames, base grades)
const GLSL = `precision highp float;
varying vec2 vUV;
uniform sampler2D textureSampler;
uniform vec4 fx; uniform vec3 inkC; uniform vec3 paperC; uniform vec2 keepHue;
vec3 hsv(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
  float d = q.x - min(q.w, q.y);
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
float hd(float a, float b) { return abs(mod(a - b + 540.0, 360.0) - 180.0); }
void main(void) {
  vec3 c = texture2D(textureSampler, vUV).rgb;
  float l = dot(c, vec3(0.299, 0.587, 0.114)), m = fx.x;
  vec3 o = mix(c, vec3(l), fx.w);
  if (m > 0.5) {
    vec3 h = hsv(c);
    vec3 two = l > fx.y ? paperC : inkC;
    bool keep = h.y > fx.z && h.z > 0.3;
    if (m < 1.5) o = vec3(1.0) - c;
    else if (m < 2.5) o = two;
    else if (m < 3.5) o = keep ? c : two;
    else o = keep && min(hd(h.x * 360.0, keepHue.x), hd(h.x * 360.0, keepHue.y)) < 22.0 ? c : vec3(l);
  }
  gl_FragColor = vec4(o, 1.0);
}`;
const WGSL = `varying vUV : vec2f;
var textureSamplerSampler : sampler; var textureSampler : texture_2d<f32>;
uniform fx : vec4f; uniform inkC : vec3f; uniform paperC : vec3f; uniform keepHue : vec2f;
fn hsv(c : vec3f) -> vec3f {
  let K = vec4f(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  let p = mix(vec4f(c.bg, K.wz), vec4f(c.gb, K.xy), step(c.b, c.g));
  let q = mix(vec4f(p.xyw, c.r), vec4f(c.r, p.yzx), step(p.x, c.r));
  let d = q.x - min(q.w, q.y);
  return vec3f(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
fn md(a : f32, b : f32) -> f32 { return a - b * floor(a / b); }
fn hd(a : f32, b : f32) -> f32 { return abs(md(a - b + 540.0, 360.0) - 180.0); }
@fragment
fn main(input : FragmentInputs) -> FragmentOutputs {
  let c = textureSample(textureSampler, textureSamplerSampler, fragmentInputs.vUV).rgb;
  let l = dot(c, vec3f(0.299, 0.587, 0.114));
  let m = uniforms.fx.x;
  var o = mix(c, vec3f(l), uniforms.fx.w);
  if (m > 0.5) {
    let h = hsv(c);
    let two = select(uniforms.inkC, uniforms.paperC, l > uniforms.fx.y);
    let keep = h.y > uniforms.fx.z && h.z > 0.3;
    if (m < 1.5) { o = vec3f(1.0) - c; }
    else if (m < 2.5) { o = two; }
    else if (m < 3.5) { o = select(two, c, keep); }
    else { o = select(vec3f(l), c, keep && min(hd(h.x * 360.0, uniforms.keepHue.x), hd(h.x * 360.0, uniforms.keepHue.y)) < 22.0); }
  }
  fragmentOutputs.color = vec4f(o, 1.0);
}`;
ShaderStore.ShadersStore.cineGradePixelShader = GLSL;
ShaderStore.ShadersStoreWGSL.cineGradePixelShader = WGSL;
/** Impact kind -> [mode, threshold, keep saturation] (cinema.lisp *IMPACT-PRESETS*). */
const MODES: Record<Impact, [number, number, number]> = { negative: [1, 0, 0], 'two-tone': [2, 0.4, 0], manga: [3, 0.4, 0.45], spot: [4, 0, 0.45] };

// ---------------------------------------------------------------- script lookups (pure: functions of cf)
/** The shot at CF and u across it. */
export function shotAt(s: Script, cf: number): [Shot, number] {
  let f0 = 0;
  for (const sh of s.shots) { if (cf < f0 + sh[0]) return [sh, (cf - f0) / sh[0]]; f0 += sh[0]; }
  const last = s.shots[s.shots.length - 1];
  return [last, 1];
}
/** The latest entry of LIST at or before CF, and the frame of the next one (or END). */
function pick<T extends [number, ...unknown[]]>(list: T[] | undefined, cf: number, end = 1e9): [T | null, number] {
  let r: T | null = null, next = end;
  for (const e of list ?? []) { if (e[0] <= cf) r = e; else { next = e[0]; break; } }
  return [r, next];
}
/** Cine time with the pose holds taken out. */
const held = (s: Script, cf: number) => cf - (s.hold ?? []).reduce((n, [f, k]) => n + Math.max(0, Math.min(k, cf - f)), 0);
const ctxOf = (w: World, c: Cine): Ctx => {
  const p = w.p1.pos, q = w.p2.pos, dx = q[0] - p[0], dz = q[2] - p[2], l = Math.max(0.01, Math.hypot(dx, dz));
  const vs = Math.sign(w.viewX * (-dz / l) + w.viewZ * (dx / l)) || 1;
  return { a: c.a, v: c.v, side: c.a === w.p1 ? vs : -vs };
};
const POSE_FACE: Record<string, number> = { hold: FACE.shout, heavyWind: FACE.shout, heavyHit: FACE.shout, kneel: FACE.hurt };
const NO_TINT = new Color4(0, 0, 0, 0);
const CEL_THRESHOLD = 0.18;                                    // (scene.ts FighterView's cel threshold, restored after a back-rim)
const hex3 = (h: number) => new Color3(((h >> 16) & 255) / 255, ((h >> 8) & 255) / 255, (h & 255) / 255);

interface Lent { state: FState; move: Ent['f']['move']; phase: string | null; sf: number; stun: number; hold: number; form: string;
  kit: Ent['f']['kit']; burst: Ent['g']['burst']; alpha: number }

export class Cinema {
  readonly pp: PostProcess;
  private stageMeshes: AbstractMesh[];
  private clear: Color4;
  private baseFov: number;
  private lensOn = false; private cardOn = false; private rimmed = false;
  private cur: Cine | null = null; private last = -1;
  private fakes = new Map<HzSpec, Hazard>();
  private battle: Hazard[] = [];                              // in-battle looks (Kenpachi's cup rings), aged on real time
  private punch: [Impact, number][] = [];                     // in-battle impact frames: [kind, seconds left]
  private mode: [number, number, number, number] = [0, 0, 0, 0];
  constructor(readonly st: Stage, engine: AbstractEngine) {
    const { scene, cam } = st;
    this.stageMeshes = scene.meshes.slice();                  // (createScene built only the stage so far)
    this.clear = scene.clearColor.clone();
    this.baseFov = cam.fov;
    this.pp = new PostProcess('cineGrade', 'cineGrade', { uniforms: ['fx', 'inkC', 'paperC', 'keepHue'], camera: cam, engine,
      shaderLanguage: engine.isWebGPU ? ShaderLanguage.WGSL : ShaderLanguage.GLSL });
    const ink = new Color3(0.03, 0.03, 0.047), paper = new Color3(0.95, 0.94, 0.9);
    this.pp.onApply = (e) => {
      e.setFloat4('fx', ...this.mode); e.setColor3('inkC', ink); e.setColor3('paperC', paper); e.setFloat2('keepHue', 10, 48);
    };
  }

  /** A new match (or the debug scene): nothing left over. */
  reset(): void { this.cur = null; this.last = -1; this.fakes.clear(); this.battle = []; this.punch = []; this.card(null); }

  /** The battle's punctuation from sim events: Kenpachi's cup entries (cup 2: a yellow ring; cup 3, NOMIHOSE: the yellow
   *  pillar's rings and burst, a negative frame then a 12 f manga page; feedback.lisp :rung). */
  events(ev: SimEvent[], w: World, view: BattleView | null): void {
    const ring = (x: number, z: number, r: number, life: number, kind = 'ring') => {
      const hz = new Hazard(kind, w.p1);
      Object.assign(hz, { look: kind === 'ring' ? 'senju-zone-look' : null, data: { hank: 0 }, life, age: 0 });
      hz.x = x; hz.z = z; hz.size = r;
      this.battle.push(hz);
    };
    for (const e of ev) {
      if (e.kind === 'shockwave') { const [x, z, r, t] = e.args as number[]; ring(x, z, r, Math.round(60 * t)); }
      else if (e.kind === 'nomihose-enter') {
        const [, x, z] = e.args as [Ent, number, number];
        ring(x, z, 5, 30); ring(x, z, 3, 21, 'gulp');
        view?.sparks.add('kikon', x, 1.2, z, 3.4, 0.6);
      } else if (e.kind === 'rung') {
        const [en, up] = e.args as [Ent, boolean];
        if (up && en.f.form === 'nomihose') this.punch = [['negative', 1 / 60], ['manga', 12 / 60]];
      }
    }
  }

  /** BattleView.update with the running cinematic's look lent to the actors and the hazard list (given back after). */
  update(w: World, view: BattleView, rdt: number): void {
    const c = w.cine, s = c ? SCRIPTS[c.name] : undefined;
    if (c !== this.cur) {                                     // a new cinematic (or none): the one-shots re-arm
      this.cur = c; this.last = -1; this.fakes.clear();
      for (const fv of view.fighters) fv.anim.cine = null;
    }
    const extra: Hazard[] = [];
    this.battle = this.battle.filter((hz) => (hz.age += rdt * 60) < hz.life);
    extra.push(...this.battle);
    const lent: [Ent, Lent][] = [];
    const reshow: FighterView[] = [];
    let shot: Shot | null = null;
    if (c && s) {
      const cf = c.cf, ctx = ctxOf(w, c);
      [shot] = shotAt(s, cf);
      for (const who of ['a', 'v'] as const) {
        const e = c[who], f = e.f, fv = view.fighters[e === w.p1 ? 0 : 1];
        lent.push([e, { state: f.state, move: f.move, phase: f.phase, sf: f.sf, stun: f.stun, hold: f.hold, form: f.form, kit: f.kit,
          burst: e.g.burst, alpha: e.look.alpha }]);
        this.act(s, who, e, fv, cf, c.len);
        const [fo] = pick(s.form?.[who], cf);
        if (fo?.[1]) f.form = fo[1];
        const [au] = pick(s.aura?.[who], cf), only = shot[2]?.card !== undefined && shot[2]?.only;
        if ((s.gone?.[who] !== undefined && cf >= s.gone[who]!) || (only && only !== who)) e.look.alpha = 0;   // hidden (no aura)
        else if ((au && au[1] === null) || (!au?.[1] && only === who)) { e.look.alpha = 0.3; reshow.push(fv); }   // (a card: clean)  // (auraOf: none under 0.35; shown again below)
        else if (au?.[1]) { f.kit = Object.create(f.kit, { aura: { value: au[1] } }); e.g.burst = null; }
      }
      for (const h of s.hz ?? []) {
        if (cf < h.from || cf >= h.to || (shot[2]?.card !== undefined && !h.card)) continue;
        let hz = this.fakes.get(h);
        if (!hz) {
          hz = new Hazard(h.kind, c.a);
          const d = h.data as { mv?: unknown } | undefined;
          Object.assign(hz, { look: h.look ?? null, life: h.to - h.from,
            data: d && typeof d.mv === 'string' ? { ...d, mv: MOVES.get(d.mv) ?? null } : d ?? null });
          hz.size = h.size;
          this.fakes.set(h, hz);
        }
        const [x, z, yaw] = h.at(ctx, cf);
        hz.x = x; hz.z = z; hz.yaw = yaw; hz.age = cf - h.from;
        extra.push(hz);
      }
      for (const [f, kind, who, size, life = 0.3, up = 1.1] of s.sparks ?? []) {
        if (this.last < f && f <= cf) { const p = c[who].pos; view.sparks.add(kind, p[0], p[1] + up, p[2], size, life); }
      }
      this.last = cf;
    }
    const n = w.hazards.length;
    w.hazards.push(...extra);
    try { view.update(w, rdt); }
    finally {
      w.hazards.length = n;
      for (const [e, l] of lent) {
        const f = e.f;
        f.state = l.state; f.move = l.move; f.phase = l.phase; f.sf = l.sf; f.stun = l.stun; f.hold = l.hold; f.form = l.form;
        f.kit = l.kit; e.g.burst = l.burst; e.look.alpha = l.alpha;
      }
    }
    for (const fv of reshow) for (const m of [fv.body.mesh, fv.body.weapon, fv.body.face, ...fv.body.extra?.meshes ?? []]) m.isVisible = true;
    this.looks(w, view, s ?? null, shot);
    this.gradeFor(s ?? null, c, rdt);
  }

  /** WHO's pose at CF: the script's act lent to the fighter (state / move / sf) or the animator's library pose. */
  private act(s: Script, who: Who, e: Ent, fv: FighterView, cf: number, len: number): void {
    const [act, next] = pick<Act>(s.act?.[who], cf, len), f = e.f;
    fv.anim.cine = null;
    if (!act) return;
    const [f0, what, from = 0, to = from] = act;
    if (what.startsWith('P:')) {
      const name = what.slice(2) as keyof typeof P, pose: PoseSpec | undefined = CLIPS[f.character]?.poses?.[name] ?? P[name];
      if (pose) fv.anim.cine = { key: what, pose, face: POSE_FACE[name] ?? FACE.neutral };
    } else if (what.startsWith('stun:')) { f.state = 'stun'; f.phase = what.slice(5); f.stun = 100; f.sf = 30; }
    else if (what === 'win' || what === 'lose' || what === 'guard') f.state = what;
    else if (what !== 'idle') {
      const mv = MOVES.get(what);
      if (!mv) return;
      const t0 = held(s, f0), x = Math.max(0, Math.min(1, (held(s, cf) - t0) / Math.max(1, held(s, next) - t0)));
      f.state = 'move'; f.move = mv; f.phase = 'main'; f.hold = 0; f.sf = Math.round(from + (to - from) * x);
    }
  }

  /** After the view's update: the card, silhouettes / back-rims, tints and flashes. */
  private looks(w: World, view: BattleView, s: Script | null, shot: Shot | null): void {
    const c = w.cine, lk = shot?.[2];
    this.card(c && lk?.card !== undefined ? lk.card : null);
    if (this.rimmed) for (const fv of view.fighters) for (const m of [fv.mat, fv.wmat]) m.setFloat('threshold', CEL_THRESHOLD);
    this.rimmed = false;
    if (!c || !s) return;
    const cf = c.cf, px = Math.max(3, this.st.scene.getEngine().getRenderHeight() / 160);
    for (const who of ['a', 'v'] as const) {
      const e = c[who], fv = view.fighters[e === w.p1 ? 0 : 1];
      let tint = NO_TINT, flash = 0;
      for (const [tw, a, b, t] of s.tint ?? []) if (tw === who && cf >= a && cf < b) tint = new Color4(...t);
      for (const [tw, a, b] of s.flash ?? []) if (tw === who && cf >= a && cf < b) flash = 1;
      const onCard = lk?.card !== undefined && (!lk.only || lk.only === who);
      if (lk?.sil === who) tint = new Color4(0.06, 0.06, 0.075, 1);
      const rim = onCard && lk?.rim !== undefined && lk?.sil !== who;
      if (rim) {                                                        // all in the shadow tone (cinema.lisp BACK-RIM: the
        tint = new Color4(0.06, 0.05, 0.08, 0.55);                      // toon threshold past 1), a hard back-rim
        for (const m of [fv.mat, fv.wmat]) m.rimLook(hex3(lk.rim!), 1, Math.round(px * 2.5));
      }
      if (rim) { for (const m of [fv.mat, fv.wmat]) m.setFloat('threshold', 1.5); this.rimmed = true; }
      if (tint !== NO_TINT || flash) { fv.mat.look(tint, flash); fv.wmat.look(tint, flash); }
    }
  }

  /** The card behind the fighters (KIND black / white / a colour: the stage not drawn) or the stage back (null). */
  private card(kind: 'black' | 'white' | number | null | undefined): void {
    const on = kind !== null && kind !== undefined;
    if (!on && !this.cardOn) return;
    for (const m of this.stageMeshes) if (!m.isDisposed()) m.isVisible = !on;
    const col = kind === 'black' ? new Color3(0.031, 0.031, 0.04) : kind === 'white' ? new Color3(0.955, 0.95, 0.93)
      : typeof kind === 'number' ? hex3(kind) : null;
    this.st.scene.clearColor = col ? new Color4(col.r, col.g, col.b, 0) : this.clear.clone();
    this.cardOn = on;
  }

  /** The grade post's mode this frame: a script's impact frame, else its base grade; in battle, the punch queue. */
  private gradeFor(s: Script | null, c: Cine | null, rdt: number): void {
    let kind: Impact | null = null, desat = 0;
    if (s && c) {
      for (const [f, k, n] of s.imp ?? []) if (c.cf >= f && c.cf < f + n) kind = k;
      if (!kind) {
        const [g] = pick(s.grade, c.cf);
        if (g?.[1] === 'spot') kind = 'spot'; else if (g?.[1] === 'desat') desat = g[2] ?? 0;
      }
    } else if (this.punch.length) {
      kind = this.punch[0][0];
      if ((this.punch[0][1] -= rdt) <= 0) this.punch.shift();
    }
    const m = kind ? MODES[kind] : [0, 0, 0];
    this.mode = [m[0], m[1], m[2], desat];
  }

  /** The cinematic's shot: rail, lens, roll, shake (after the gameplay camera placed CAM; restores it when none runs). */
  camera(w: World | null, cam: FreeCamera, aspect: number): void {
    const c = w?.cine, s = c ? SCRIPTS[c.name] : undefined;
    if (!w || !c || !s) {
      if (this.lensOn) { cam.fov = this.baseFov; cam.rotation.z = 0; this.lensOn = false; }
      return;
    }
    const [[, rail, lk], u] = shotAt(s, c.cf);
    if (rail) {
      const o = rail(ctxOf(w, c), u), eye = new Vector3(...o.eye), at = new Vector3(...o.at);
      if (aspect < 1 && !o.close) eye.subtractInPlace(at).scaleInPlace(Math.min(2, 0.9 / aspect)).addInPlace(at);   // portrait: back off
      for (const [f, amp, n] of s.shake ?? []) {
        if (c.cf < f || c.cf >= f + n) continue;
        const k = amp * (1 - (c.cf - f) / n), t = c.cf * 1.9;
        const d = new Vector3(k * Math.sin(t * 1.7), k * 0.6 * Math.sin(t * 2.3 + 1), k * Math.sin(t * 1.3 + 2));
        eye.addInPlace(d); at.addInPlace(d);
      }
      cam.position.copyFrom(eye); cam.setTarget(at);
    }
    cam.fov = ((lk?.fov ?? (rail ? 60 : this.baseFov * 180 / Math.PI)) * Math.PI) / 180;
    cam.rotation.z = ((lk?.roll ?? 0) * Math.PI) / 180;
    this.lensOn = true;
  }
}

// ---------------------------------------------------------------- the 2D overlay (hud.ts draws it over a cinematic)
type G = CanvasRenderingContext2D;
type Project = (x: number, y: number, z: number) => [number, number] | null;
const hash = (a: number, b: number) => { const x = Math.sin(a * 127.1 + b * 311.7) * 43758.5453; return x - Math.floor(x); };
const INK = 'rgba(8,8,13,0.92)';

function focusLines(g: G, cx: number, cy: number, r0: number, r1: number, seed: number): void {
  g.fillStyle = INK;
  for (let i = 0; i < 56; i++) {
    const a = ((i + 0.8 * hash(seed, i)) * 2 * Math.PI) / 56, wd = 0.004 + 0.012 * hash(seed, i + 99), r = r0 * (1 + 0.7 * hash(seed, i + 7));
    g.beginPath(); g.moveTo(cx + Math.cos(a - wd) * r1, cy + Math.sin(a - wd) * r1); g.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r);
    g.lineTo(cx + Math.cos(a + wd) * r1, cy + Math.sin(a + wd) * r1); g.fill();
  }
}
function splash(g: G, x: number, y: number, r: number, seed: number): void {
  g.fillStyle = 'rgba(8,8,12,0.96)';
  const blob = (bx: number, by: number, br: number, k: number) => {
    g.beginPath();
    for (let i = 0; i <= 20; i++) { const a = (i / 20) * 2 * Math.PI, q = br * (0.8 + 0.35 * hash(seed + k, i % 20)); g.lineTo(bx + Math.cos(a) * q, by + Math.sin(a) * q * 0.8); }
    g.fill();
  };
  blob(x, y, r, 0);
  for (let i = 0; i < 12; i++) {
    const a = hash(seed, i + 40) * 2 * Math.PI, d = r * (1.2 + 1.3 * hash(seed, i + 60));
    blob(x + Math.cos(a) * d, y + Math.sin(a) * d * 0.7, r * (0.08 + 0.18 * hash(seed, i + 80)), i + 1);
  }
}
/** Kenpachi's Bankai card (ken.lisp KEN-FOREST): ink trunks, petals on twos, and Yachiru for two drawings (f24-31). */
const TRUNKS = [[0.03, 0.05], [0.1, 0.022], [0.62, 0.04], [0.71, 0.018], [0.8, 0.06], [0.93, 0.03]];
function forest(g: G, w: number, h: number, cf: number): void {
  const ink = '#08080c', dr = Math.floor(cf / 2);
  const poly = (...p: number[]) => { g.beginPath(); g.moveTo(p[0], p[1]); for (let i = 2; i < p.length; i += 2) g.lineTo(p[i], p[i + 1]); g.fill(); };
  g.fillStyle = ink;
  TRUNKS.forEach(([fx, fw], i) => {
    const x = fx * w, tw = fw * w, lean = (i % 2 ? -0.015 : 0.02) * w;
    poly(x + lean, 0, x + lean + tw, 0, x + 1.2 * tw, h, x - 0.2 * tw, h);
    const by = h * (0.18 + 0.11 * (i % 3)), dir = i % 2 ? -1 : 1, bx = x + 0.5 * tw;
    poly(bx, by, bx + dir * 0.09 * w, by - 0.07 * h, bx + dir * 0.09 * w, by - 0.06 * h, bx, by + 0.02 * h);
  });
  for (let k = 0; k < 18; k++) {                                   // the petals, re-drawn every drawing
    const px = w * ((k * 0.137 + 0.003 * dr + 0.01 * Math.sin(k + dr)) % 1), py = h * ((k * 0.071 + 0.012 * dr) % 1), r = 0.006 * h;
    g.fillStyle = '#f5f5f0'; poly(px, py - r, px + r, py, px, py + r, px - r, py);
    g.strokeStyle = ink; g.lineWidth = 1; g.strokeRect(px - r, py - r, 2 * r, 2 * r);
  }
  if (cf >= 24 && cf <= 31) {                                       // Yachiru: 2 drawings, then gone
    const cx = 0.52 * w, base = 0.8 * h, u = 0.05 * h, j = cf < 28 ? 0 : 0.08 * u;
    g.fillStyle = ink;
    poly(cx - 0.35 * u, base - 1.3 * u, cx + 0.35 * u, base - 1.3 * u, cx + 0.6 * u, base, cx - 0.6 * u, base);
    g.beginPath(); g.arc(cx, base - 1.75 * u - j, 0.42 * u, 0, 2 * Math.PI); g.fill();
    poly(cx + 0.2 * u, base - 2.1 * u - j, cx + 0.55 * u, base - 2.35 * u - j, cx + 0.5 * u, base - 1.95 * u - j, cx + 0.3 * u, base - 1.9 * u - j);
  }
}

/** The running cinematic's screen layer (W x H device px): letterbox, captions, punctuation. False: no script (hud.ts
 *  falls back to its plain card). */
export function drawCineOverlay(g: G, w: number, h: number, wd: World, project: Project): boolean {
  const c = wd.cine!, s = SCRIPTS[c.name], cf = c.cf;
  if (!s) return false;
  const portrait = h > w, bar = (portrait ? 0.05 : 0.09) * h;
  if (s.over === 'forest' && cf >= 12 && cf < 58) forest(g, w, h, cf);
  for (const [f, n] of s.focus ?? []) if (cf >= f && cf < f + n) {
    const p = project(c.a.pos[0], 1.2, c.a.pos[2]);
    focusLines(g, p ? p[0] : w / 2, p ? p[1] : h / 2, 0.16 * h, 1.4 * Math.max(w, h), Math.floor(cf / 2));
  }
  for (const [f, n, who, r] of s.splash ?? []) if (cf >= f && cf < f + n) {
    const e = c[who], p = project(e.pos[0], 0, e.pos[2]);
    if (p) splash(g, p[0], p[1], r * h, Math.floor(e.pos[0] * 13.7) % 50);
  }
  g.fillStyle = '#000'; g.fillRect(0, 0, w, bar); g.fillRect(0, h - bar, w, bar);
  for (const [from, to, side, cap] of s.caps ?? []) {
    if (cf < from || cf > to) continue;
    let k: Cap | undefined = CAPS[c.name];
    if (cap === 'a' || cap === 'v') {
      const e = c[cap], nm = NAMES[e.f.character] ?? [e.f.character.toUpperCase(), e.f.character.toUpperCase()];
      k = { kanji: nm[0], reading: nm[1], sub: e.f.kit.introCallout ?? undefined };
    } else if (cap) k = cap;
    if (k) drawCard(g, k, cf, c.len, w, h, side === 'R' ? 0 : 1, [from, to]);
  }
  if (s.over === 'vs' && cf >= 240) {
    const sc = Math.max(1, Math.min(h / 360, w / 480)), nm = (e: Ent) => findKit(e.f.character, 'base').name ?? e.f.character.toUpperCase();
    swash(g, w / 2, 0.42 * h + 14 * sc, 0.9 * w, 60 * sc, '#14110f', 0.85);
    inkText(g, `${nm(wd.p1)}   VS   ${nm(wd.p2)}`, w / 2, 0.42 * h - 2 * sc, 25 * sc, '#f4efe2', 'center', 1);
  }
  for (const [f, n] of s.ui ?? []) if (cf >= f && cf < f + n) { g.fillStyle = `rgba(255,255,255,${1 - (cf - f) / n})`; g.fillRect(0, 0, w, h); }
  return true;
}

// ---------------------------------------------------------------- debug: window.duelCine (headless stills)
/** duelCine.play(name, attacker, victim, { aForm, vForm, at }): a CPU-vs-CPU match whose sim runs cinematic NAME (P1 the
 *  attacker) up to cine frame AT and holds there; duelCine.at(f) moves on to frame f (the sim only runs forward). */
export function installCineDebug(engine: AbstractEngine, stage: Stage, cinema: Cinema): void {
  const { scene, cam } = stage;
  let view: BattleView | null = null, target = 0;
  const play = (name: string, ac = 'yamamoto', vc = 'kenpachi', o: { aForm?: string; vForm?: string; at?: number } = {}) => {
    engine.stopRenderLoop();
    view?.dispose();
    (document.getElementById('ui') as HTMLElement).hidden = true;
    const m = new Match({ p1: ac, p2: vc, seed: 1, cpu1: true, cpu2: true }).start(), w = m.w;
    if (name !== 'intro-cine') {
      abortCine(); w.flow = 'battle';
      if (o.aForm) setForm(w.p1, o.aForm);
      if (o.vForm) setForm(w.p2, o.vForm);
      w.p1.pos.set([-2, 0, 0.5]); w.p2.pos.set([2, 0, -0.5]);
      startCine(name, w.p1, w.p2, null);
    }
    m.takeEvents();
    view = new BattleView(scene, w, stage); cinema.reset();
    const dc = new DuelCamera();
    target = o.at ?? 0;
    const project = (x: number, y: number, z: number): [number, number] | null => {
      const rw = engine.getRenderWidth(), rh = engine.getRenderHeight();
      const q = Vector3.Project(new Vector3(x, y, z), Matrix.IdentityReadOnly, scene.getTransformMatrix(), cam.viewport.toGlobal(rw, rh));
      const [hw, hh] = hudSize();
      return q.z < 0 || q.z > 1 ? null : [(q.x * hw) / rw, (q.y * hh) / rh];
    };
    engine.runRenderLoop(() => {
      setWorld(w);
      for (let i = 0; i < 600 && w.cine && w.cine.cf < target; i++) m.step();    // the sim is the clock
      const ev = m.takeEvents();
      view!.events(ev, w); cinema.events(ev, w, view);
      dc.aspect = engine.getAspectRatio(cam); dc.update(w, 1 / 60);
      cam.position.copyFrom(dc.eye); cam.setTarget(dc.at);
      cinema.camera(w, cam, engine.getAspectRatio(cam));
      cinema.update(w, view!, 1 / 60);
      updateCel(cam);
      scene.render();
      drawBattle(w, project, { portrait: false, practice: false, hint: false, prompt: () => '' });
    });
  };
  Object.assign(window, { duelCine: { play, at: (f: number) => { target = f; }, get view() { return view; } } });
}
