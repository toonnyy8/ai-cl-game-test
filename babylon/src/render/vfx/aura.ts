// aura.ts: the fighters' reiatsu auras as CPU ParticleSystems of brush sprites (GPU particles don't exist on the WebGL2
// path). One system per fighter (capacity AURA_CAP: two fighters stay under the 500-particle budget); the sprite is a
// 4-cell painted sheet (ink rim + a white body tinted by the particle colour) stepped through its cells; a particle is
// born in the character's reiatsu colour at alpha 0.75 and fades in its own colour (the blood / pillar states dry to
// ink). The preset follows the kit's aura (awakened forms only; the base form shows one only while gathering) and the moment: the Kikon rush (blood), a Breaker's wind-up, a running burst, EVOLUTION ready. Cosmetic only.
import { Color4, ParticleSystem, Vector3, type DynamicTexture, type Scene } from '@babylonjs/core';
import type { Ent } from '../../sim/types';
import { arc, blob, INK, paintSheet, stroke, WHITE } from './brush';

export const AURA_CAP = 220;
type Tex = 'tongue' | 'shard' | 'thread';
/** [sprite, colour 1, colour 2, rate /s, size min max, rise speed min max, life min max, radius]. */
type Preset = [Tex, number, number, number, number, number, number, number, number, number, number];
const YAMA = 0xff7a2a, KEN = 0xf5d54a, RUKIA = 0x9fd4ff, ICHIGO = 0x8fb8ff, SENJU = 0xd8b860, BLOOD = 0xc8102e, INKC = 0x14110f;
const CHAR: Record<string, number> = { yamamoto: YAMA, kenpachi: KEN, rukia: RUKIA, ichigo: ICHIGO, senjumaru: SENJU };
export const PRESETS: Record<string, Preset> = {
  // (Polish: life -0.1 s, no x1.3; awakened 40-55 /s, pillars <= 110 /s, r 0.35-0.45; base form off)
  //                    tex       c1      c2      rate size     rise      life       r
  base:                ['tongue', 0,      0,      0,   0.22, 0.4, 0.7, 1.3, 0.3, 0.6, 0.4],
  gather:              ['tongue', 0,      0,      40,  0.25, 0.45, 0.8, 1.5, 0.35, 0.55, 0.4],
  reiatsu:             ['tongue', KEN,    0xfff6c0, 40, 0.3, 0.55, 1.2, 2.2, 0.35, 0.65, 0.4],
  nozarashi:           ['tongue', KEN,    0xfff6c0, 60, 0.35, 0.65, 2.2, 3.4, 0.4, 0.7, 0.42],
  nomihose:            ['tongue', KEN,    0xffffff, 110, 0.45, 0.85, 4.5, 6.5, 0.35, 0.6, 0.45],
  oni:                 ['tongue', BLOOD,  INKC,   110, 0.45, 0.85, 4.0, 6.0, 0.35, 0.6, 0.45],
  hellfire:            ['tongue', YAMA,   0xffd070, 70, 0.35, 0.7, 2.0, 3.2, 0.3, 0.55, 0.42],
  heat:                ['tongue', 0x3a3a40, 0xff5a20, 26, 0.3, 0.55, 0.8, 1.3, 0.6, 0.9, 0.4],
  garb:                ['tongue', 0xe8341c, YAMA,  70,  0.35, 0.7, 1.6, 2.6, 0.25, 0.5, 0.4],
  'rukia-aura-cold':   ['shard',  0xffffff, RUKIA, 20, 0.12, 0.22, 0.5, 1.0, 0.5, 0.9, 0.42],
  'rukia-aura-frost':  ['shard',  0xffffff, RUKIA, 20, 0.12, 0.22, 0.6, 1.2, 0.5, 0.9, 0.45],
  'rukia-aura-zero':   ['shard',  RUKIA, 0x6fa8e0, 60, 0.22, 0.42, 0.8, 1.6, 0.5, 0.9, 0.45],
  'ichigo-aura-base':  ['tongue', ICHIGO, INKC,   30,  0.3, 0.55, 1.0, 1.8, 0.35, 0.6, 0.4],
  'ichigo-aura-kessa': ['tongue', BLOOD,  INKC,   70,  0.35, 0.7, 1.8, 3.0, 0.3, 0.55, 0.42],
  'senju-aura-tsuji':  ['thread', SENJU,  0xc0484f, 45, 0.4, 0.8, 0.5, 1.1, 0.6, 1.0, 0.45],
  kikon:               ['tongue', BLOOD,  INKC,   110, 0.4, 0.75, 2.5, 4.0, 0.25, 0.45, 0.42],
  breaker:             ['tongue', 0,      INKC,   100, 0.35, 0.7, 2.0, 3.2, 0.25, 0.45, 0.42],
  evolution:           ['tongue', 0xffd94d, 0xffffff, 45, 0.3, 0.55, 1.4, 2.4, 0.35, 0.6, 0.42],
  white:               ['tongue', 0xffffff, 0xd8e4ff, 55, 0.3, 0.6, 1.6, 2.6, 0.3, 0.5, 0.42],
  blue:                ['tongue', 0x4f9dff, 0xffffff, 55, 0.3, 0.6, 1.6, 2.6, 0.3, 0.5, 0.42],
  orange:              ['tongue', 0xff9a40, 0xffffff, 55, 0.3, 0.6, 1.6, 2.6, 0.3, 0.5, 0.42],
};
/** The presets that dry to ink as they die; every other one fades out in its own colour. */
const INKDRY = new Set(['kikon', 'oni', 'breaker', 'nomihose']);
const c4 = (h: number, a = 1) => new Color4(((h >> 16) & 255) / 255, ((h >> 8) & 255) / 255, (h & 255) / 255, a);

/** E's aura preset now (or null): the moment over the form. */
export function auraOf(e: Ent): string | null {
  const f = e.f, mv = f.move, g = e.g;
  if (e.look.alpha < 0.35 || !e.alive) return null;
  if (mv && f.state === 'move' && mv.kind === 'kikon' && (f.phase !== 'main' || f.sf < mv.s)) return 'kikon';
  if (mv && f.state === 'move' && mv.kind === 'breaker' && (f.phase !== 'main' || f.sf < mv.s)) return 'breaker';
  if (g.burst) return g.burst;
  const form = f.kit.aura;
  if (form && f.form !== 'base') return form;                       // awakened forms; the base form has none ...
  if (mv && f.state === 'move' && (f.phase === 'hold' || f.phase === 'aura')) return form ?? 'gather';   // ... but gathering
  return g.evolution ? 'evolution' : null;
}

function sheets(scene: Scene): Record<Tex, DynamicTexture> {
  return {
    tongue: paintSheet(scene, 'aura-tongue', 4, 64, 128, (g, i, w, h) => {
      const sw = (i - 1.5) * w * 0.08;
      stroke(g, [[w / 2, h * 0.95], [w / 2 + sw, h * 0.55], [w / 2 - sw, h * 0.08]], w * 0.55, WHITE, 0.55);
      stroke(g, [[w * 0.7, h * 0.9], [w * 0.68 + sw, h * 0.5], [w / 2 - sw * 0.5, h * 0.2]], w * 0.09, INK, 0.7);
    }),
    shard: paintSheet(scene, 'aura-shard', 4, 64, 64, (g, i, w) => {
      g.save(); g.translate(w / 2, w / 2); g.rotate(i * 0.8);
      g.fillStyle = WHITE; g.beginPath(); g.moveTo(0, -w * 0.42); g.lineTo(w * 0.16, 0); g.lineTo(0, w * 0.42); g.lineTo(-w * 0.16, 0); g.fill();
      g.strokeStyle = INK; g.lineWidth = 3; g.stroke(); g.restore();
    }),
    thread: paintSheet(scene, 'aura-thread', 4, 64, 128, (g, i, w, h) => {
      stroke(g, arc(w * (0.2 + 0.1 * i), h / 2, h * 0.42, -1.2, 1.2, 12, 0.04), w * 0.08, WHITE, 0.3);
      blob(g, w * 0.5, h * 0.5, 3, INK);
    }),
  };
}

export class Auras {
  tex: Record<Tex, DynamicTexture>;
  ps: ParticleSystem[] = [];
  now: (string | null)[] = [null, null];
  at = [new Vector3(), new Vector3()];
  constructor(readonly scene: Scene) {
    this.tex = sheets(scene);
    for (let i = 0; i < 2; i++) {
      const p = new ParticleSystem(`aura${i}`, AURA_CAP, scene, null, true);
      p.emitter = this.at[i]; p.blendMode = ParticleSystem.BLENDMODE_STANDARD;
      p.spriteCellWidth = 64; p.spriteCellHeight = 128; p.startSpriteCellID = 0; p.endSpriteCellID = 3;
      p.spriteCellChangeSpeed = 1; p.spriteCellLoop = true; p.spriteRandomStartCell = true;
      p.gravity = new Vector3(0, 0, 0); p.renderingGroupId = 0; p.preWarmCycles = 0;
      p.updateSpeed = 1 / 60;
      p.emitRate = 0; p.start();
      this.ps.push(p);
    }
  }

  private apply(i: number, name: string, character: string): void {
    const p = this.ps[i], [tex, a, b, rate, s0, s1, v0, v1, l0, l1, r] = PRESETS[name] ?? PRESETS.base;
    const own = CHAR[character] ?? 0xffffff;
    p.particleTexture = this.tex[tex];
    p.spriteCellWidth = 64; p.spriteCellHeight = tex === 'shard' ? 64 : 128;
    p.billboardMode = tex === 'tongue' ? ParticleSystem.BILLBOARDMODE_STRETCHED : ParticleSystem.BILLBOARDMODE_ALL;
    const al = tex === 'shard' ? 0.6 : 0.75, dead = c4(b || own, 0);
    p.color1 = c4(a || own, al); p.color2 = c4(b || own, tex === 'shard' ? al : 0.6);
    p.colorDead = INKDRY.has(name) ? new Color4(0.08, 0.07, 0.06, 0) : dead;   // the blood / pillar states dry to ink
    p.minSize = s0; p.maxSize = s1;
    p.minEmitPower = v0; p.maxEmitPower = v1; p.minLifeTime = l0; p.maxLifeTime = l1;
    p.minAngularSpeed = tex === 'tongue' ? 0 : -2; p.maxAngularSpeed = tex === 'tongue' ? 0 : 2;
    const sp = tex === 'tongue' ? 0.12 : 0.45;                          // up, a little spread (a cylinder emitter fires radially)
    p.createDirectedCylinderEmitter(r, 0.2, 1, new Vector3(-sp, 1, -sp), new Vector3(sp, 1, sp));
    p.minScaleX = p.maxScaleX = 1; p.minScaleY = p.maxScaleY = tex === 'shard' ? 1 : 1.6;
    p.emitRate = rate;
  }

  update(es: Ent[]): void {
    es.forEach((e, i) => {
      const want = auraOf(e);
      this.at[i].set(e.pos[0], e.pos[1] + 0.1, e.pos[2]);
      if (want === this.now[i]) return;
      this.now[i] = want;
      if (want) this.apply(i, want, e.f.character); else this.ps[i].emitRate = 0;
    });
  }
  live(): number { return this.ps.reduce((n, p) => n + p.getActiveCount(), 0); }
  dispose(): void { for (const p of this.ps) p.dispose(false); for (const t of Object.values(this.tex)) t.dispose(); }
}
