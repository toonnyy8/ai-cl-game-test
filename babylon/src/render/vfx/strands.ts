// strands.ts: the cloth and thread fx hung off B3's posed bodies. Rukia's long white ribbon trails from her blade's
// `pommel` node (bodies/rukia.ts): a verlet rope drawn as a camera-facing strip, ink-edged by the outline pass.
// Senjumaru's red threads between her six hands (senjuPoints, bodies/senju.ts): KASA's umbrella (a ring through the hands
// and ribs to an apex over her head) while its window is open, and the loom's warp in every TSUJI form.
import {
  Color3, Mesh, StandardMaterial, Vector3, VertexBuffer, VertexData, type Scene, type TransformNode,
} from '@babylonjs/core';
import type { Ent } from '../../sim/types';
import type { FighterView } from '../scene';
import { senjuPoints } from '../bodies/senju';
import { hex3 } from './brush';

// ---------------------------------------------------------------- Rukia's ribbon
const N = 12, LEN = 0.85, SEG = LEN / (N - 1), W = 0.06, GRAV = -6;
const pommels = new WeakMap<Mesh, TransformNode | null>();
const pommelOf = (w: Mesh) => {
  let n = pommels.get(w);
  if (n === undefined) { n = w.getChildTransformNodes(true).find((c) => c.name === 'pommel') ?? null; pommels.set(w, n); }
  return n;
};

class Ribbon {
  p: Vector3[] = []; q: Vector3[] = []; m: Mesh; buf = new Float32Array(N * 6);
  constructor(scene: Scene, mat: StandardMaterial) {
    this.m = new Mesh('rukia-ribbon', scene);
    const uv: number[] = [], idx: number[] = [];
    for (let j = 0; j < N; j++) {
      uv.push(j / (N - 1), 0, j / (N - 1), 1);
      if (j < N - 1) idx.push(2 * j, 2 * j + 2, 2 * j + 1, 2 * j + 1, 2 * j + 2, 2 * j + 3);
    }
    const vd = new VertexData(); vd.positions = Array<number>(N * 6).fill(0); vd.uvs = uv; vd.indices = idx;
    vd.normals = Array<number>(N * 6).fill(0).map((_, i) => (i % 3 === 1 ? 1 : 0));
    vd.applyToMesh(this.m, true);
    this.m.material = mat; this.m.isPickable = false; this.m.alwaysSelectAsActiveMesh = true;
  }
  update(a: Vector3, rdt: number, eye: Vector3): void {
    const { p, q } = this;
    if (p.length && Vector3.DistanceSquared(p[0], a) > 0.25) p.length = q.length = 0;   // a Hoho / a cut: hang it afresh
    if (!p.length) for (let i = 0; i < N; i++) { p.push(new Vector3(a.x, a.y - i * SEG, a.z)); q.push(p[i].clone()); }
    const dt = Math.min(rdt, 1 / 30), g = GRAV * dt * dt;
    for (let i = 1; i < N; i++) {                       // verlet, damped; a little lift so it streams rather than hangs
      const vx = (p[i].x - q[i].x) * 0.94, vy = (p[i].y - q[i].y) * 0.94, vz = (p[i].z - q[i].z) * 0.94;
      q[i].copyFrom(p[i]); p[i].set(p[i].x + vx, p[i].y + vy + g, p[i].z + vz);
    }
    p[0].copyFrom(a); q[0].copyFrom(a);
    for (let it = 0; it < 4; it++) for (let i = 0; i < N - 1; i++) {
      const A = p[i], B = p[i + 1], d = B.subtract(A), l = Math.max(1e-5, d.length()), k = (l - SEG) / l;
      if (i === 0) B.subtractInPlace(d.scaleInPlace(k)); else { d.scaleInPlace(0.5 * k); A.addInPlace(d); B.subtractInPlace(d); }
    }
    for (const v of p) if (v.y < 0.02) v.y = 0.02;
    const t = new Vector3(), s = new Vector3();
    for (let i = 0; i < N; i++) {                       // camera-facing, tapering to the end
      p[Math.min(N - 1, i + 1)].subtractToRef(p[Math.max(0, i - 1)], t);
      Vector3.CrossToRef(t, eye.subtract(p[i]), s);
      if (!(s.lengthSquared() > 1e-12)) s.set(1, 0, 0);
      s.normalize().scaleInPlace(W * (1 - 0.5 * (i / (N - 1))));
      p[i].add(s).toArray(this.buf, 6 * i); p[i].subtract(s).toArray(this.buf, 6 * i + 3);
    }
    this.m.updateVerticesData(VertexBuffer.PositionKind, this.buf);
    this.m.refreshBoundingInfo();
  }
}

// ---------------------------------------------------------------- Senjumaru's threads
const SEGS = 12, TW = 0.022;
/** SEGS camera-facing quads TW wide (a thread is a few px at battle distance; GL lines are 1 px). */
class Threads {
  m: Mesh; buf = new Float32Array(SEGS * 12);
  constructor(scene: Scene, mat: StandardMaterial) {
    this.m = new Mesh('sj-threads', scene);
    const idx: number[] = [];
    for (let i = 0; i < SEGS; i++) idx.push(4 * i, 4 * i + 1, 4 * i + 2, 4 * i, 4 * i + 2, 4 * i + 3);
    const vd = new VertexData(); vd.positions = Array<number>(SEGS * 12).fill(0); vd.indices = idx;
    vd.normals = Array<number>(SEGS * 12).fill(0).map((_, i) => (i % 3 === 1 ? 1 : 0));
    vd.applyToMesh(this.m, true);
    this.m.material = mat; this.m.isPickable = false; this.m.alwaysSelectAsActiveMesh = true;
  }
  update(lines: Vector3[][], eye: Vector3): void {
    const s = new Vector3();
    this.buf.fill(0);
    lines.forEach(([a, b], i) => {
      Vector3.CrossToRef(b.subtract(a), eye.subtract(a), s);
      if (s.lengthSquared() < 1e-12) return;
      s.normalize().scaleInPlace(TW / 2);
      a.add(s).toArray(this.buf, 12 * i); a.subtract(s).toArray(this.buf, 12 * i + 3);
      b.subtract(s).toArray(this.buf, 12 * i + 6); b.add(s).toArray(this.buf, 12 * i + 9);
    });
    this.m.updateVerticesData(VertexBuffer.PositionKind, this.buf);
    this.m.refreshBoundingInfo();
  }
}
// hands = [rig R, rig L, echo R28, echo L28, echo R52, echo L52]
const RING = [4, 2, 0, 1, 3, 5];
const WARP: [number, number][] = [[0, 1], [2, 3], [4, 5], [0, 2], [2, 4], [1, 3], [3, 5]];
const HURT = new Set(['stun', 'air', 'down', 'wakeup', 'lose']);
function kasaOpen(e: Ent): boolean {
  const f = e.f, mv = f.move;
  return f.state === 'move' && !!mv && mv.clip === 'sj-kasa' && f.phase === 'main' && f.sf >= mv.s && f.sf < mv.s + mv.a;
}

export class Strands {
  ribbons = new Map<FighterView, Ribbon>();
  threads = new Map<FighterView, Threads>();
  mat: StandardMaterial; red: StandardMaterial;
  constructor(readonly scene: Scene, readonly views: FighterView[]) {
    this.mat = new StandardMaterial('ribbon', scene);
    this.mat.disableLighting = true; this.mat.emissiveColor = hex3(0xf6f3ec); this.mat.diffuseColor = Color3.Black();
    this.mat.specularColor = Color3.Black(); this.mat.backFaceCulling = false;
    this.red = this.mat.clone('sj-thread'); this.red.emissiveColor = hex3(0xc8202e);
  }

  update(es: Ent[], rdt: number): void {
    const eye = this.scene.activeCamera?.globalPosition ?? Vector3.Zero();
    es.forEach((e, i) => {
      const v = this.views[i];
      if (e.f.character === 'rukia') {
        let r = this.ribbons.get(v);
        if (!r) { r = new Ribbon(this.scene, this.mat); this.ribbons.set(v, r); v.outline.add(r.m); }
        const pn = pommelOf(v.body.weapon);
        r.m.isVisible = !!pn && v.body.weapon.isVisible;
        if (pn) r.update(pn.getAbsolutePosition(), rdt, eye);
      }
      if (e.f.character === 'senjumaru') {
        const pts = senjuPoints(v.body);
        let th = this.threads.get(v);
        const kasa = kasaOpen(e), loom = e.f.form !== 'base' && !HURT.has(e.f.state);
        const lines: Vector3[][] = [];
        if (pts && (kasa || loom)) {
          const h = pts.hands;
          if (kasa) {
            const c = h.reduce((s, x) => s.addInPlace(x), new Vector3()).scaleInPlace(1 / h.length);
            c.y += 0.45;
            RING.forEach((a, j) => lines.push([h[a], h[RING[(j + 1) % RING.length]]], [h[a], c]));
          } else for (const [a, b] of WARP) lines.push([h[a], h[b]]);
        }
        if (!th) { th = new Threads(this.scene, this.red); this.threads.set(v, th); }
        th.m.isVisible = lines.length > 0 && v.body.mesh.isVisible;
        if (th.m.isVisible) th.update(lines, eye);
      }
    });
  }

  dispose(): void {
    for (const [v, r] of this.ribbons) { v.outline.remove(r.m); r.m.dispose(); }
    for (const t of this.threads.values()) t.m.dispose();
    this.ribbons.clear(); this.threads.clear(); this.mat.dispose(); this.red.dispose();
  }
}
