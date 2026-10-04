// trail.ts: the blade's ink arc and the ink afterimages (docs/BABYLON_LOOK.md B2 "Readability" / B4). The arc is a
// ribbon over the last TRAIL samples of the blade (a point 35 % up the blade to its tip) while the move's strike is
// live (the Lisp's window: S - 4 to S + A + 3), painted as one dry-brush stroke (thick at the newest sample, bristles
// breaking toward the tail): ink normally, red for a Kikon / an awakened form, slate when it was blocked. The blade is
// read off the body's weapon mesh (its local bounds' long axis, the far end = the tip), no hook into the body.
// Afterimages: the posed body baked into a flat ink mesh (skinning applied on the CPU once), fading in steps.
import {
  Color3, Matrix, Mesh, StandardMaterial, TransformNode, Vector3, VertexBuffer, VertexData, type Scene,
} from '@babylonjs/core';
import type { Ent } from '../../sim/types';
import type { FighterView } from '../scene';
import { FPS, hex3, paintSheet, stroke, WHITE } from './brush';

const TRAIL = 10;
const TINT = { ink: hex3(0x14110f), red: hex3(0xc8102e), slate: hex3(0x3b4a66) };

/** The blade's [base, tip] in the weapon's local space (cached per weapon mesh). */
const bladeCache = new WeakMap<Mesh, [Vector3, Vector3]>();
function bladeLocal(w: Mesh): [Vector3, Vector3] {
  let b = bladeCache.get(w);
  if (!b) {
    const { minimum: lo, maximum: hi } = w.getBoundingInfo();
    const ext = [hi.x - lo.x, hi.y - lo.y, hi.z - lo.z], ax = ext.indexOf(Math.max(...ext));
    const far = Math.abs(hi.asArray()[ax]) > Math.abs(lo.asArray()[ax]) ? hi.asArray()[ax] : lo.asArray()[ax];
    const tip = Vector3.Zero(), base = Vector3.Zero();
    tip.set(ax === 0 ? far : 0, ax === 1 ? far : 0, ax === 2 ? far : 0);
    base.copyFrom(tip).scaleInPlace(0.35);
    b = [base, tip]; bladeCache.set(w, b);
  }
  return b;
}
export function strikeLive(e: Ent): boolean {
  const f = e.f, mv = f.move;
  return !!mv && f.state === 'move' && f.phase === 'main' && f.sf >= mv.s - 4 && f.sf < mv.s + mv.a + 3;
}

class Ribbon {
  m: Mesh; pts: Vector3[] = []; mat: StandardMaterial; buf = new Float32Array(TRAIL * 6);
  constructor(scene: Scene, tex: StandardMaterial['diffuseTexture']) {
    this.m = new Mesh('trail', scene);
    const pos = Array<number>(TRAIL * 6).fill(0), uv: number[] = [], idx: number[] = [];
    for (let j = 0; j < TRAIL; j++) {
      uv.push(j / (TRAIL - 1), 0, j / (TRAIL - 1), 1);
      if (j < TRAIL - 1) idx.push(2 * j, 2 * j + 2, 2 * j + 1, 2 * j + 1, 2 * j + 2, 2 * j + 3);
    }
    const vd = new VertexData(); vd.positions = pos; vd.uvs = uv; vd.indices = idx; vd.applyToMesh(this.m, true);
    this.mat = new StandardMaterial('trail', scene);
    this.mat.diffuseTexture = tex; this.mat.useAlphaFromDiffuseTexture = true; this.mat.disableLighting = true;
    this.mat.backFaceCulling = false; this.mat.disableDepthWrite = true; this.mat.specularColor = Color3.Black();
    this.mat.diffuseColor = Color3.Black(); this.mat.emissiveColor = TINT.ink;
    this.m.material = this.mat; this.m.renderingGroupId = 0; this.m.isPickable = false; this.m.alwaysSelectAsActiveMesh = true;
    this.m.isVisible = false;
  }
  update(e: Ent, v: FighterView): void {
    const w = v.body.weapon;
    if (strikeLive(e) && w.isVisible) {
      const [b, t] = bladeLocal(w), M = w.computeWorldMatrix(true);
      this.pts.unshift(Vector3.TransformCoordinates(b, M), Vector3.TransformCoordinates(t, M));
      if (this.pts.length > 2 * TRAIL) this.pts.length = 2 * TRAIL;
      const f = e.f;
      this.mat.emissiveColor = f.contact === 'block' ? TINT.slate : f.move!.kind === 'kikon' || f.kit.awakening ? TINT.red : TINT.ink;
    } else this.pts.splice(-4, 4);                                     // decays two samples a frame
    const n = this.pts.length / 2;
    this.m.isVisible = n >= 2;
    if (n < 2) return;
    const pos = this.buf;
    for (let j = 0; j < 2 * TRAIL; j++) this.pts[Math.min(j, this.pts.length - 2 + (j & 1))].toArray(pos, 3 * j);
    this.m.updateVerticesData(VertexBuffer.PositionKind, pos);
    this.m.refreshBoundingInfo();
  }
}

interface Ghost { node: TransformNode; meshes: Mesh[]; age: number; life: number }
export class Trails {
  ribbons: Ribbon[];
  ghosts: Ghost[] = [];
  ghostMat: StandardMaterial;
  constructor(readonly scene: Scene) {
    // dry brush along the ribbon (u: 0 = the newest sample), the bristles breaking off toward the tail
    const tex = paintSheet(scene, 'trail-brush', 1, 512, 64, (g, _i, w, h) => {
      stroke(g, [[2, h * 0.5], [w * 0.4, h * 0.52], [w - 2, h * 0.5]], h * 0.95, WHITE, 0.95);
      stroke(g, [[2, h * 0.6], [w * 0.3, h * 0.62], [w * 0.7, h * 0.66]], h * 0.5, WHITE, 0.6);
    });
    this.ribbons = [new Ribbon(scene, tex), new Ribbon(scene, tex)];
    this.ghostMat = new StandardMaterial('ghost', scene);
    this.ghostMat.disableLighting = true; this.ghostMat.emissiveColor = hex3(0x1c1a24); this.ghostMat.diffuseColor = Color3.Black();
    this.ghostMat.specularColor = Color3.Black(); this.ghostMat.backFaceCulling = false;
  }

  /** V's body as posed now, flat ink, at (X Z) facing YAW; LIFE seconds (Infinity: until dropped). */
  ghost(v: FighterView, x: number, z: number, yaw: number, life: number, tint?: Color3): Ghost | null {
    const src = v.body.mesh, pos = src.getPositionData(true, false), idx = src.getIndices();
    if (!pos || !idx) return null;
    const node = new TransformNode('ghost', this.scene);
    const body = new Mesh('ghost-body', this.scene), vd = new VertexData();
    vd.positions = pos; vd.indices = idx; vd.applyToMesh(body);
    body.parent = node; body.position.copyFrom(src.position); body.rotationQuaternion = src.rotationQuaternion?.clone() ?? null;
    body.rotation.copyFrom(src.rotation); body.scaling.copyFrom(src.scaling);
    const meshes = [body], w = v.body.weapon;
    if (w.isVisible || v.body.mesh.isVisible) {                        // the weapon, relative to the fighter's root
      const wc = new Mesh('ghost-weapon', this.scene), wd = new VertexData();
      wd.positions = w.getPositionData(false, false)!; wd.indices = w.getIndices()!; wd.applyToMesh(wc);
      const rel = w.computeWorldMatrix(true).multiply(Matrix.Invert(v.root.computeWorldMatrix(true)));
      wc.parent = node; wc.rotationQuaternion = null;
      const q = wc.rotation.toQuaternion(); rel.decompose(wc.scaling, q, wc.position); wc.rotationQuaternion = q;
      meshes.push(wc);
    }
    const mat = tint ? this.ghostMat.clone('ghost-t') : this.ghostMat;
    if (tint) mat.emissiveColor = tint;
    for (const m of meshes) { m.material = mat; m.isPickable = false; m.alwaysSelectAsActiveMesh = true; m.renderingGroupId = 0; }
    node.position.set(x, 0, z); node.rotation.y = yaw;
    const g = { node, meshes, age: 0, life };
    this.ghosts.push(g);
    return g;
  }
  drop(g: Ghost): void { g.age = g.life = 0; }

  update(es: Ent[], views: FighterView[], rdt: number): void {
    es.forEach((e, i) => this.ribbons[i].update(e, views[i]));
    this.ghosts = this.ghosts.filter((g) => {
      g.age += rdt;
      if (g.age >= g.life) {
        if (g.meshes[0].material !== this.ghostMat) g.meshes[0].material?.dispose();
        g.node.dispose(); return false;
      }
      const k = Number.isFinite(g.life) ? Math.floor((g.age / g.life) * FPS * g.life) / (FPS * g.life) : 0;   // stepped fade
      for (const m of g.meshes) m.visibility = 0.75 * (1 - k);
      g.node.scaling.y = 1 + 0.05 * k;
      return true;
    });
  }
  dispose(): void {
    for (const r of this.ribbons) { r.m.dispose(); r.mat.dispose(); }
    for (const g of this.ghosts) g.node.dispose();
    this.ghosts = [];
    this.ghostMat.dispose();
  }
}
