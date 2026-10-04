// scene.ts: the M5 look (docs/BABYLON_PORT.md "M5 look": anime cel objects, ink-brush effects, screen-space outlines,
// decal faces, skinned bodies). The plaza keeps duel/lisp/stage.lisp's dimensions (stone disc r 15.1 with joint rings at
// 11.3 / 13.2, the curb to 15.6, broken whitewashed walls at r 19) in BABYLON_LOOK.md's B2 palette: a sky gradient
// dome with one hard-edged cloud band, a warm two-tone floor, whitewashed walls with cool shadows, the key light fixed in
// the world (cel.ts); the fighters' contact shadows on the floor; fighters are body.ts skeletons posed by anim.ts with a
// rim in their reiatsu colour, a smear of the blade over the active frames and a one-frame white flash when hit;
// hazards, auras, blade arcs, afterimages are vfx/; hit sparks are ink.ts brush sprites. Right-handed like the sim (Y up, yaw 0 faces -Z), so sim positions and yaws go in unchanged.
import {
  Color3, Color4, FreeCamera, Mesh, MeshBuilder, Scene, StandardMaterial, TransformNode, Vector3, VertexBuffer, VertexData,
  type AbstractEngine,
} from '@babylonjs/core';
import type { Ent, SimEvent, World } from '../sim/types';
import { CelMaterial, celLight } from './cel';
import { createOutline, type Outline } from './outline';
import { buildBody, tube, type BuiltBody } from './body';
import { bodyFor } from './bodies';
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
  scene.clearColor = new Color4(0.65, 0.78, 0.93, 0);           // the horizon; alpha 0 = no fighter ink
  const cam = new FreeCamera('cam', new Vector3(0, 3, 12), scene);
  cam.fov = 50 * Math.PI / 180; cam.minZ = 0.35; cam.maxZ = 400;
  const outline = createOutline(scene, cam);
  const stone = new CelMaterial('stone', scene, { lit: hex(0xc8b38c), shadow: hex(0x8c7858), contact: 0.35 });
  const wl = hex(0xf3eee3), ws = hex(0x8a90a8);
  const vc = new CelMaterial('stage', scene, { shadow: new Color3(ws.r / wl.r, ws.g / wl.g, ws.b / wl.b) });
  // the sky: a gradient dome (top #2E4C8C -> horizon #A6C8EC) and one hard-edged cloud band; flat colour, no ink
  const flat = new CelMaterial('sky', scene, { shadow: Color3.White() });
  const sky = MeshBuilder.CreateSphere('sky', { diameter: 600, segments: 24, sideOrientation: Mesh.BACKSIDE }, scene);
  const sp = sky.getVerticesData('position')!, top = hex(0x2e4c8c), hor = hex(0xa6c8ec), sc: number[] = [];
  for (let i = 0; i < sp.length; i += 3) { const t = Math.pow(Math.max(0, Math.min(1, sp[i + 1] / 160)), 0.7);
    const c = Color3.Lerp(hor, top, t); sc.push(c.r, c.g, c.b, 1); }
  sky.setVerticesData(VertexBuffer.ColorKind, sc); sky.material = flat; sky.infiniteDistance = true;
  const cloud = new Mesh('cloud', scene);
  tube([[3, 270, 270], [13, 270, 270]], 240, { a0: 0, a1: Math.PI * 2, double: true,          // just over the walls
    lip: (a, j) => (j ? 7 * Math.abs(Math.sin(a * 17)) * (0.6 + 0.4 * Math.sin(a * 5)) + 3 * Math.sin(a * 3 + 1) : 0) }).applyToMesh(cloud);
  paint(cloud, 0xf4f6fa).material = flat; cloud.infiniteDistance = true;

  const floor = MeshBuilder.CreateCylinder('floor', { diameter: 30.2, height: 0.04, tessellation: 72 }, scene);
  floor.position.y = -0.02; floor.material = stone;
  const outside = MeshBuilder.CreateGround('out', { width: 320, height: 320 }, scene);
  outside.position.y = -0.03; outside.material = new CelMaterial('out', scene, { lit: hex(0x9e8a66), shadow: hex(0x6e5e44) });
  // joint rings, the curb and the wall ring merge into one vertex-coloured mesh
  const parts: Mesh[] = [];
  // (lathed rings: a torus tessellates its tube as finely as its ring, 18k triangles each)
  const ring = (r: number, w: number, h: number, c: number) => {
    const m = MeshBuilder.CreateLathe('ring', { shape: [new Vector3(r - w, 0, 0), new Vector3(r - w, h, 0), new Vector3(r + w, h, 0),
      new Vector3(r + w, 0, 0)], tessellation: 96, closed: true }, scene);
    parts.push(paint(m, c));
  };
  ring(11.3, 0.03, 0.006, 0x7a6a50); ring(13.2, 0.03, 0.006, 0x7a6a50);
  ring(15.35, 0.25, 0.24, 0x7a6a50);                                            // the curb
  for (let i = 0; i < 30; i++) {                                                // the broken wall ring at r 19
    const roll = (Math.sin(i * 12.9898) * 43758.5453) % 1;
    if (Math.abs(roll) < 0.15) continue;                                        // missing panel
    const hgt = Math.abs(roll) < 0.45 ? 1.2 : 2.4, a = (2 * Math.PI * i) / 30;
    for (const [w, h, d, y, c] of [[3.9, hgt, 0.4, hgt / 2, 0xf3eee3], [4.1, 0.22, 0.7, hgt + 0.11, 0x3c3f4c], [3.9, 0.3, 0.42, 0.15, 0x7a6a50]] as const) {
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
/** Each character's reiatsu: the rim colour (BABYLON_LOOK.md: Yamamoto #FF7A2A, Kenpachi #F5D54A). */
export const REIATSU: Record<string, number> = { yamamoto: 0xff7a2a, kenpachi: 0xf5d54a, rukia: 0xbfe2ff, ichigo: 0x8ec8ff, senjumaru: 0xf2c84a };
const SMEAR_N = 4;                                // blade positions kept for the smear (render frames)
export class FighterView {
  root: TransformNode; body!: BuiltBody; anim: Animator; mat: CelMaterial; wmat: CelMaterial;
  bodies = new Map<string, BuiltBody>();         // one body per (character, variant): a form change swaps, never rebuilds
  bodyKey = '';
  /** Render frames of white flash left (BattleView sets 1 on a hit). */
  flashN = 0;
  smear: Mesh; smearPts: Vector3[] = []; private smearPos = new Float32Array(SMEAR_N * 2 * 3);
  constructor(readonly scene: Scene, e: Ent, readonly outline: Outline) {
    this.root = new TransformNode('fighter', scene);
    this.mat = new CelMaterial('fighter', scene, { ink: 1, threshold: 0.18, pairs: true, rim: outline.depth });
    this.wmat = new CelMaterial('weapon', scene, { ink: 0.95, threshold: 0.18, pairs: true, rim: outline.depth });
    this.useBody(e);
    this.anim = new Animator(this.body, e.f.character);
    // the smear: a ribbon between the blade's last few positions (world space), shown over the active frames
    this.smear = new Mesh('smear', scene);
    const idx: number[] = [];
    for (let i = 0; i + 1 < SMEAR_N; i++) idx.push(2 * i, 2 * i + 1, 2 * i + 2, 2 * i + 1, 2 * i + 3, 2 * i + 2);
    const vd = new VertexData();
    Object.assign(vd, { positions: Array.from(this.smearPos), indices: idx, normals: new Array(SMEAR_N * 6).fill(0).map((_, i) => (i % 3 === 1 ? 1 : 0)),
      colors: new Array(SMEAR_N * 2).fill(0).flatMap((_, i) => { const t = Math.floor(i / 2) / (SMEAR_N - 1); return [0.86 + 0.14 * t, 0.9 + 0.1 * t, 1, 0.55 - 0.4 * t]; }) });
    vd.applyToMesh(this.smear, true);
    this.smear.hasVertexAlpha = true;            // alpha 0.55 newest -> 0.15 oldest; not in the G-buffer (ink shows through)
    this.smear.material = this.smearMat(scene); this.smear.alwaysSelectAsActiveMesh = true; this.smear.isVisible = false;
  }
  private smearMat(scene: Scene): StandardMaterial {
    const m = new StandardMaterial('smear', scene);
    m.disableLighting = true; m.diffuseColor = Color3.White(); m.specularColor = Color3.Black();
    m.backFaceCulling = false; m.disableDepthWrite = true;
    return m;
  }

  /** Show the body of E's current form (fighter.form picks the CharBody variant). */
  useBody(e: Ent): void {
    const { key, body: cb } = bodyFor(e.f.character, e.f.form);
    if (key === this.bodyKey) return;
    if (this.body) {
      for (const m of [this.body.mesh, this.body.weapon, ...this.body.extra?.meshes ?? []]) this.outline.remove(m);
      for (const m of [this.body.mesh, this.body.weapon, this.body.face, ...this.body.extra?.meshes ?? []]) m.setEnabled(false);
    }
    let b = this.bodies.get(key);
    if (!b) {
      b = buildBody(this.scene, key, cb, this.mat, this.wmat);
      b.mesh.parent = this.root;
      b.mesh.alwaysSelectAsActiveMesh = true;                                   // posed limbs leave the rest bounds
      b.weapon.alwaysSelectAsActiveMesh = true;
      this.bodies.set(key, b);
    }
    for (const m of [b.mesh, b.weapon, b.face, ...b.extra?.meshes ?? []]) m.setEnabled(true);
    for (const m of [b.mesh, b.weapon, ...b.extra?.meshes ?? []]) this.outline.add(m, cb.ink !== undefined);   // (alt: the body's own ink)
    this.body = b; this.bodyKey = key;
    if (this.anim) this.anim.body = b;
    if (cb.ink !== undefined) this.outline.alt.copyFrom(hex(cb.ink));
  }

  update(e: Ent, rdt: number, t: number): void {
    this.useBody(e);
    this.root.position.set(e.pos[0], e.pos[1], e.pos[2]);
    this.root.rotation.y = e.yaw;
    this.anim.update(e, rdt, t);
    this.body.extra?.update(e, rdt);
    this.body.faceTex.uOffset = this.anim.face / 3;
    const flash = Math.max(this.anim.flash, this.flashN > 0 ? 1 : 0);
    if (rdt > 0 && this.flashN > 0) this.flashN--;
    this.mat.look(NO_TINT, flash); this.wmat.look(NO_TINT, flash);
    // the reiatsu rim: wider while awakened or gathering (an aura / hold phase), widest in a flare
    const f = e.f, aura = (f.form !== 'base' ? 1.3 : 1) * (f.state === 'move' && (f.phase === 'aura' || f.phase === 'hold') ? 1.4 : 1)
      + 0.5 * Math.min(1, e.look.flare);
    const rc = hex(this.body.spec.reiatsu ?? REIATSU[f.character] ?? 0xffffff), px = Math.max(3, this.scene.getEngine().getRenderHeight() / 160);
    this.mat.rimLook(rc, 0.9, Math.round(px * aura)); this.wmat.rimLook(rc, 0.9, Math.round(px));
    const show = e.look.alpha > 0.35;                                           // Hoho: gone while faded
    this.body.mesh.isVisible = this.body.weapon.isVisible = this.body.face.isVisible = show;
    for (const m of this.body.extra?.meshes ?? []) m.isVisible = show;
    this.updateSmear(show && this.anim.active, rdt);
  }
  /** Keep the blade's base / tip of the last SMEAR_N render frames; fill the ribbon while the move is active. */
  updateSmear(on: boolean, rdt: number): void {
    if (!on) { this.smearPts.length = 0; this.smear.isVisible = false; return; }
    if (rdt <= 0 && this.smearPts.length) return;                               // paused / hit-stop render: hold
    const w = this.body.weapon; w.computeWorldMatrix(true);
    const m = w.getWorldMatrix();
    this.smearPts.unshift(Vector3.TransformCoordinates(this.body.base, m), Vector3.TransformCoordinates(this.body.tip, m));
    this.smearPts.length = Math.min(this.smearPts.length, SMEAR_N * 2);
    const n = this.smearPts.length / 2;
    // skipped: a tip jump > 1.5 m since the last frame (a cut / a snap), or a slice within 1 m of the lens
    if (n >= 2 && Vector3.Distance(this.smearPts[1], this.smearPts[3]) > 1.5) this.smearPts.length = 2;   // (restart after it)
    if (this.smearPts.length < 4) { this.smear.isVisible = false; return; }
    const eye = this.scene.activeCamera?.globalPosition;
    for (let i = 0; i < SMEAR_N; i++) {
      const k = Math.min(i, n - 1), b = this.smearPts[2 * k], tp = this.smearPts[2 * k + 1];
      const q = b.add(tp.subtract(b).scale(0.45 + 0.15 * (k / (SMEAR_N - 1))));  // from 45 % up; older slices narrow toward the tip
      const l = Vector3.Distance(q, tp);
      if (l > 1.3) q.subtractInPlace(tp).scaleInPlace(1.3 / l).addInPlace(tp);  // <= 1.3 m (the cleavers)
      if (eye && Math.min(Vector3.Distance(q, eye), Vector3.Distance(tp, eye)) < 1.0) { this.smear.isVisible = false; return; }
      this.smearPos.set([q.x, q.y, q.z, tp.x, tp.y, tp.z], i * 6);
    }
    this.smear.updateVerticesData(VertexBuffer.PositionKind, this.smearPos);
    this.smear.refreshBoundingInfo();
    this.smear.isVisible = true;
  }
  dispose(): void {
    for (const m of [this.body.mesh, this.body.weapon, ...this.body.extra?.meshes ?? []]) this.outline.remove(m);
    for (const b of this.bodies.values()) {
      b.extra?.dispose(); b.weapon.dispose(); b.face.dispose(); b.faceTex.dispose(); b.faceMat.dispose(); b.mesh.dispose(); b.skeleton.dispose();
    }
    this.smear.material?.dispose(); this.smear.dispose();
    this.mat.dispose(); this.wmat.dispose(); this.root.dispose();
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
        case 'hit': S.add('hit', ...xyz(2), a[6] ? 1.6 : 1.1); this.fighters[a[1]].flashN = 1; break;
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
    celLight.shadows.set(w.p1.pos[0], w.p1.pos[2], w.p2.pos[0], w.p2.pos[2]);       // contact shadows on the floor
    this.vfx.update(w, rdt);
    this.sparks.step(rdt);
  }

  dispose(): void {
    for (const f of this.fighters) f.dispose();
    this.vfx.dispose();
    this.sparks.dispose();
  }
}
