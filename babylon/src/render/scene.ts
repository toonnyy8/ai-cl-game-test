// scene.ts: the M5 look (docs/BABYLON_PORT.md "M5 look": anime cel objects, ink-brush effects, screen-space outlines,
// decal faces, skinned bodies). The plaza keeps duel/lisp/stage.lisp's dimensions (stone disc r 15.1 with joint rings at
// 11.3 / 13.2, the curb to 15.6, broken whitewashed walls at r 19) in a muted daylight palette so the fighters read;
// fighters are body.ts skeletons posed by anim.ts; hazards, auras, blade arcs, afterimages are vfx/; hit sparks are ink.ts brush
// sprites. Right-handed like the sim (Y up, yaw 0 faces -Z), so sim positions and yaws go in unchanged.
import {
  Color3, Color4, FreeCamera, Mesh, MeshBuilder, Scene, TransformNode, Vector3, VertexBuffer,
  type AbstractEngine,
} from '@babylonjs/core';
import type { Ent, SimEvent, World } from '../sim/types';
import { CelMaterial } from './cel';
import { createOutline, type Outline } from './outline';
import { buildBody, type BuiltBody } from './body';
import { Animator } from './anim';
import { InkSparks, inkMaterials, type InkMats } from './ink';
import { Vfx } from './vfx';

const hex = (h: number) => new Color3(((h >> 16) & 255) / 255, ((h >> 8) & 255) / 255, (h & 255) / 255);
/** Paint every vertex of M one colour (the stage meshes merge into vertex-coloured batches). */
function paint(m: Mesh, c: number): Mesh {
  const col = hex(c), n = m.getTotalVertices(), a: number[] = [];
  for (let i = 0; i < n; i++) a.push(col.r, col.g, col.b, 1);
  m.setVerticesData(VertexBuffer.ColorKind, a);
  return m;
}

export interface Stage { scene: Scene; cam: FreeCamera; outline: Outline; ink: InkMats }

export function createScene(engine: AbstractEngine): Stage {
  const scene = new Scene(engine);
  scene.useRightHandedSystem = true;
  scene.clearColor = new Color4(0.8, 0.82, 0.85, 0);             // pale sky; alpha 0 = no fighter ink
  const cam = new FreeCamera('cam', new Vector3(0, 3, 12), scene);
  cam.fov = Math.PI / 3; cam.minZ = 0.1; cam.maxZ = 400;
  const outline = createOutline(scene, cam);
  const stone = new CelMaterial('stone', scene, { lit: hex(0xb9b2a6), shadow: hex(0x8a8a98), rim: 0 });
  const vc = new CelMaterial('stage', scene, { shadow: new Color3(0.7, 0.7, 0.8), rim: 0 });

  const floor = MeshBuilder.CreateCylinder('floor', { diameter: 30.2, height: 0.04, tessellation: 72 }, scene);
  floor.position.y = -0.02; floor.material = stone;
  const outside = MeshBuilder.CreateGround('out', { width: 320, height: 320 }, scene);
  outside.position.y = -0.03; outside.material = new CelMaterial('out', scene, { lit: hex(0x8f8a80), shadow: hex(0x70707c), rim: 0 });
  // joint rings, the curb and the wall ring merge into one vertex-coloured mesh
  const parts: Mesh[] = [];
  // (lathed rings: a torus tessellates its tube as finely as its ring, 18k triangles each)
  const ring = (r: number, w: number, h: number, c: number) => {
    const m = MeshBuilder.CreateLathe('ring', { shape: [new Vector3(r - w, 0, 0), new Vector3(r - w, h, 0), new Vector3(r + w, h, 0),
      new Vector3(r + w, 0, 0)], tessellation: 96, closed: true }, scene);
    parts.push(paint(m, c));
  };
  ring(11.3, 0.03, 0.006, 0x8e877c); ring(13.2, 0.03, 0.006, 0x8e877c);
  ring(15.35, 0.25, 0.24, 0x9a9387);                                            // the curb
  for (let i = 0; i < 30; i++) {                                                // the broken wall ring at r 19
    const roll = (Math.sin(i * 12.9898) * 43758.5453) % 1;
    if (Math.abs(roll) < 0.15) continue;                                        // missing panel
    const hgt = Math.abs(roll) < 0.45 ? 1.2 : 2.4, a = (2 * Math.PI * i) / 30;
    for (const [w, h, d, y, c] of [[3.9, hgt, 0.4, hgt / 2, 0xe6e1d6], [4.1, 0.22, 0.7, hgt + 0.11, 0x3c3f4c], [3.9, 0.3, 0.42, 0.15, 0x8c8478]] as const) {
      const b = MeshBuilder.CreateBox('wall', { width: w, height: h, depth: d }, scene);
      b.position.set(19 * Math.cos(a), y, 19 * Math.sin(a)); b.rotation.y = -a + Math.PI / 2;
      b.bakeCurrentTransformIntoVertices(); parts.push(paint(b, c));
    }
  }
  const walls = Mesh.MergeMeshes(parts, true, true)!;
  walls.material = vc;
  for (const m of [floor, outside, walls]) { outline.add(m); m.freezeWorldMatrix(); }
  return { scene, cam, outline, ink: inkMaterials(scene) };
}

// ---------------------------------------------------------------- fighters
const NO_TINT = new Color4(0, 0, 0, 0);
export class FighterView {
  root: TransformNode; body: BuiltBody; anim: Animator; mat: CelMaterial; wmat: CelMaterial;
  constructor(scene: Scene, e: Ent, readonly outline: Outline) {
    this.root = new TransformNode('fighter', scene);
    this.mat = new CelMaterial('fighter', scene, { ink: 1, threshold: 0.0 });
    this.wmat = new CelMaterial('weapon', scene, { ink: 0.5, shadow: new Color3(0.55, 0.58, 0.72) });
    this.body = buildBody(scene, e.f.character, this.mat, this.wmat);
    this.body.mesh.parent = this.root;
    this.body.mesh.alwaysSelectAsActiveMesh = true;                             // posed limbs leave the rest bounds
    this.body.weapon.alwaysSelectAsActiveMesh = true;
    outline.add(this.body.mesh); outline.add(this.body.weapon);
    this.anim = new Animator(this.body, e.f.character);
  }

  update(e: Ent, rdt: number, t: number): void {
    this.root.position.set(e.pos[0], e.pos[1], e.pos[2]);
    this.root.rotation.y = e.yaw;
    this.anim.update(e, rdt, t);
    this.body.faceTex.uOffset = this.anim.face / 3;
    this.mat.look(NO_TINT, this.anim.flash); this.wmat.look(NO_TINT, this.anim.flash);
    const show = e.look.alpha > 0.35;                                           // Hoho: gone while faded
    this.body.mesh.isVisible = this.body.weapon.isVisible = this.body.face.isVisible = show;
  }
  dispose(): void {
    this.outline.remove(this.body.mesh); this.outline.remove(this.body.weapon);
    this.body.weapon.dispose(); this.body.face.dispose(); this.body.faceTex.dispose(); this.body.faceMat.dispose();
    this.body.mesh.dispose(); this.body.skeleton.dispose(); this.mat.dispose(); this.wmat.dispose(); this.root.dispose();
  }
}

// ---------------------------------------------------------------- the battle view: fighters, ink VFX (vfx/), sparks
export class BattleView {
  fighters: FighterView[];
  vfx: Vfx;
  sparks: InkSparks;
  t = 0;
  constructor(readonly scene: Scene, w: World, stage: Stage) {
    this.fighters = [new FighterView(scene, w.p1, stage.outline), new FighterView(scene, w.p2, stage.outline)];
    this.sparks = new InkSparks(scene, stage.ink);
    this.vfx = new Vfx(scene, this.fighters);
  }

  events(ev: SimEvent[], w: World): void {
    const S = this.sparks;
    this.vfx.events(ev, w);
    for (const e of ev) {
      const a = e.args as number[], xyz = (i: number): [number, number, number] => [a[i], a[i + 1], a[i + 2]];
      const at = (side: number): [number, number, number] => { const p = (side === 0 ? w.p1 : w.p2).pos; return [p[0], p[1] + 1.1, p[2]]; };
      switch (e.kind) {
        case 'hit': S.add('hit', ...xyz(2), a[6] ? 1.6 : 1.1); break;
        case 'blocked': S.add('block', ...xyz(2), 0.9, 0.25); break;
        case 'guard-crush': case 'guard-break': case 'stance-break': S.add('hit', ...xyz(2), 2.0, 0.45); break;
        case 'parried': case 'absorbed': case 'armored': S.add('block', ...xyz(1), 1.2); break;
        case 'clash': S.add('block', ...xyz(0), 1.5); break;
        case 'hazard-cut': S.add('block', ...xyz(0), 1.0); break;
        case 'kikon': case 'soul-break': S.add('kikon', ...at(a[1]), 3.2, 0.7); break;
        case 'hoho-out': case 'hoho-in': S.add('block', a[1], 1.0, a[2], 1.0, 0.25); break;
        case 'burst': S.add('kikon', ...at(a[0]), 2.6, 0.45); break;
      }
    }
  }

  update(w: World, rdt: number): void {
    this.t += rdt;
    this.fighters[0].update(w.p1, rdt, this.t); this.fighters[1].update(w.p2, rdt, this.t);
    this.vfx.update(w, rdt);
    this.sparks.step(rdt);
  }

  dispose(): void {
    for (const f of this.fighters) f.dispose();
    this.vfx.dispose();
    this.sparks.dispose();
  }
}
