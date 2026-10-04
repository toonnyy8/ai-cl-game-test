// scene.ts: the M1 placeholder look (the user, 2026-10-04: models and motions may be redrawn; M5 draws the real ones).
// The plaza from duel/lisp/stage.lisp's dimensions (stone disc r 15.1 with joint rings at 11.3 / 13.2, the curb to 15.6,
// broken walls at r 19, darker ground outside), a moon light, fighters as capsules sized by their hurt cylinders with a
// head, a facing marker and a sword box timed to the move's frames, hazards as emissive meshes, sparks from the events.
// Right-handed like the sim (Y up, yaw 0 faces -Z), so sim positions and yaws go in unchanged.
import {
  Color3, Color4, DirectionalLight, FreeCamera, HemisphericLight, Mesh, MeshBuilder, Scene, StandardMaterial,
  TransformNode, Vector3, type AbstractEngine,
} from '@babylonjs/core';
import { fwdX, fwdZ } from '../sim/math';
import type { Ent, Hazard, SimEvent, World } from '../sim/types';

const hex = (h: number) => new Color3(((h >> 16) & 255) / 255, ((h >> 8) & 255) / 255, (h & 255) / 255);
function mat(scene: Scene, color: Color3, emissive = false): StandardMaterial {
  const m = new StandardMaterial('m', scene);
  m.diffuseColor = color; m.specularColor = Color3.Black();
  if (emissive) { m.emissiveColor = color; m.disableLighting = true; }
  return m;
}

export function createScene(engine: AbstractEngine): { scene: Scene; cam: FreeCamera } {
  const scene = new Scene(engine);
  scene.useRightHandedSystem = true;
  const sky = new Color4(0.17, 0.18, 0.23, 1);
  scene.clearColor = sky;
  scene.fogMode = Scene.FOGMODE_LINEAR; scene.fogStart = 30; scene.fogEnd = 110;
  scene.fogColor = new Color3(sky.r, sky.g, sky.b);
  const cam = new FreeCamera('cam', new Vector3(0, 3, 12), scene);
  cam.fov = Math.PI / 3; cam.minZ = 0.1; cam.maxZ = 400;
  const hemi = new HemisphericLight('hemi', new Vector3(0, 1, 0), scene);
  hemi.intensity = 0.65; hemi.groundColor = new Color3(0.25, 0.26, 0.32);
  new DirectionalLight('moon', new Vector3(0.4, -1, 0.6), scene).intensity = 0.75;

  const flat = (m: Mesh) => { m.rotation.x = Math.PI / 2; return m; };          // discs / tori lie in XY / XZ
  const floor = flat(MeshBuilder.CreateDisc('floor', { radius: 15.1, tessellation: 64, sideOrientation: Mesh.DOUBLESIDE }, scene));
  floor.material = mat(scene, hex(0x767d8e));
  const outside = flat(MeshBuilder.CreateDisc('out', { radius: 160, tessellation: 64, sideOrientation: Mesh.DOUBLESIDE }, scene));
  outside.position.y = -0.01; outside.material = mat(scene, hex(0x3c4150));
  for (const r of [11.3, 13.2]) {
    const j = MeshBuilder.CreateTorus('joint', { diameter: 2 * r, thickness: 0.03, tessellation: 96 }, scene);
    j.scaling.y = 0.1; j.material = mat(scene, hex(0x5a6070));
  }
  const curb = MeshBuilder.CreateTorus('curb', { diameter: 2 * 15.35, thickness: 0.5, tessellation: 96 }, scene);
  curb.scaling.y = 0.48; curb.material = mat(scene, hex(0x5c6272));
  const wallMat = mat(scene, hex(0x484d60));
  for (let i = 0; i < 30; i++) {                                                // the broken wall ring at r 19
    const roll = (Math.sin(i * 12.9898) * 43758.5453) % 1;
    if (Math.abs(roll) < 0.15) continue;                                        // missing panel
    const hgt = Math.abs(roll) < 0.45 ? 1.2 : 2.4, a = (2 * Math.PI * i) / 30;
    const w = MeshBuilder.CreateBox('wall', { width: 3.9, height: hgt, depth: 0.4 }, scene);
    w.position.set(19 * Math.cos(a), hgt / 2, 19 * Math.sin(a));
    w.rotation.y = -a + Math.PI / 2; w.material = wallMat;
  }
  return { scene, cam };
}

// ---------------------------------------------------------------- fighters
const SIDE_COLOR = [hex(0xd8743a), hex(0x4d7fd0)];
const SWORD: Record<string, [number, number]> = { yamamoto: [0xff7a2a, 1.0], kenpachi: [0xb8bcc8, 1.3] };

class FighterView {
  root: TransformNode; tilt: TransformNode; arm: TransformNode; sword: Mesh;
  meshes: Mesh[]; bodyMat: StandardMaterial; swordLen: number;
  constructor(scene: Scene, e: Ent) {
    const r = e.body.hurtR, h = e.body.hurtH, [sc, len] = SWORD[e.f.character] ?? [0xdddddd, 1.1];
    this.swordLen = len;
    this.root = new TransformNode('fighter', scene);
    this.tilt = new TransformNode('tilt', scene); this.tilt.parent = this.root;
    this.bodyMat = mat(scene, SIDE_COLOR[e.f.side]);
    const body = MeshBuilder.CreateCapsule('body', { radius: r * 0.8, height: h * 0.84, tessellation: 16 }, scene);
    body.position.y = h * 0.42;
    const head = MeshBuilder.CreateSphere('head', { diameter: h * 0.15, segments: 12 }, scene);
    head.position.y = h * 0.9;
    const marker = MeshBuilder.CreateBox('face', { width: 0.12, height: 0.08, depth: 0.25 }, scene);
    marker.position.set(0, h * 0.9, -h * 0.08);                                // the face: forward is -Z
    marker.material = mat(scene, hex(0xf2efe6), true);
    body.material = head.material = this.bodyMat;
    this.arm = new TransformNode('arm', scene); this.arm.parent = this.tilt;
    this.arm.position.set(r * 0.75, h * 0.58, -r * 0.4);
    this.sword = MeshBuilder.CreateBox('sword', { width: 0.05, height: 0.09, depth: len }, scene);
    this.sword.position.z = -len / 2; this.sword.parent = this.arm;
    this.sword.material = mat(scene, hex(sc), true);
    for (const m of [body, head, marker]) m.parent = this.tilt;
    this.meshes = [body, head, marker, this.sword];
  }

  update(e: Ent, t: number): void {
    const f = e.f;
    this.root.position.set(e.pos[0], e.pos[1], e.pos[2]);
    this.root.rotation.y = e.yaw;
    // the body: lying (down), tipped (air), getting up (wakeup)
    this.tilt.rotation.x = f.state === 'down' ? Math.PI / 2 : f.state === 'air' ? 0.6
      : f.state === 'wakeup' ? Math.max(0, Math.PI / 2 * (1 - f.sf / 20)) : f.state === 'lose' ? 0.25 : 0;
    // the sword: idle low guard; a move winds up over its startup, swings (arc) / thrusts (capsule) through its active
    // frames, eases back over the recovery
    let yawA = 0.35, pitch = -0.35, z = 0;
    const mv = f.state === 'move' ? f.move : null;
    if (mv) {
      const from = mv.hits[0]?.from ?? mv.s, to = mv.hits.at(-1)?.to ?? mv.s + mv.a, end = mv.s + mv.a + mv.r;
      const thrust = mv.spec.vol?.[0] === 'cap', sf = f.phase && f.phase !== 'main' ? 0 : f.sf;
      const u = sf < from ? sf / Math.max(1, from) : sf <= to ? 1 + (sf - from) / Math.max(1, to - from)
        : 2 + (sf - to) / Math.max(1, end - to);
      if (thrust) {
        if (u < 1) { z = 0.35 * u; pitch = -0.35 + 0.35 * u; yawA = 0.35 - 0.35 * u; }
        else if (u <= 2) { z = 0.35 - 1.1 * (u - 1); pitch = 0; yawA = 0; }
        else { const k = Math.min(1, u - 2); z = -0.75 * (1 - k); pitch = -0.35 * k; yawA = 0.35 * k; }
      } else if (u < 1) { yawA = 0.35 - 2.0 * u; pitch = -0.35 + 0.9 * u; }
      else if (u <= 2) { yawA = -1.65 + 3.3 * (u - 1); pitch = 0.55 - 0.7 * (u - 1); }
      else { const k = Math.min(1, u - 2); yawA = 1.65 - 1.3 * k; pitch = -0.15 - 0.2 * k; }
    } else if (f.state === 'guard' || f.state === 'guard-hit') { yawA = 1.2; pitch = 0.9; }
    this.arm.rotation.set(pitch, yawA, 0);
    this.arm.position.z = -e.body.hurtR * 0.4 + z;
    // state tints: guard blue, stun red flash; Hoho fades by the look's alpha
    const em = this.bodyMat.emissiveColor;
    if (f.state === 'guard' || f.state === 'guard-hit') em.set(0.1, 0.25, 0.75);
    else if (f.state === 'stun' || f.state === 'air') { const k = 0.4 + 0.4 * Math.sin(t * 40); em.set(k, 0.05, 0.05); }
    else em.set(0, 0, 0);
    const a = e.look.alpha;
    for (const m of this.meshes) { m.visibility = a; m.isVisible = a > 0.02; }
  }
  dispose(): void { this.root.dispose(false, true); }
}

// ---------------------------------------------------------------- the battle view: fighters, hazards, sparks
interface Spark { m: Mesh; life: number; max: number; grow: number }
const HAZ_COLOR: Record<string, number> = { wave: 0xff6a1a, fireball: 0xffa040, enjo: 0xff5a10, crack: 0x262a36 };

export class BattleView {
  fighters: FighterView[];
  hazards = new Map<Hazard, Mesh>();
  sparks: Spark[] = [];
  t = 0;
  constructor(readonly scene: Scene, w: World) { this.fighters = [new FighterView(scene, w.p1), new FighterView(scene, w.p2)]; }

  spark(x: number, y: number, z: number, color: number, size: number, life = 0.25): void {
    const m = MeshBuilder.CreateSphere('spark', { diameter: 1, segments: 8 }, this.scene);
    m.position.set(x, y, z); m.scaling.setAll(size * 0.4);
    m.material = mat(this.scene, hex(color), true);
    this.sparks.push({ m, life, max: life, grow: size });
  }

  events(ev: SimEvent[], w: World): void {
    for (const e of ev) {
      const a = e.args as number[], xyz = (i: number): [number, number, number] => [a[i], a[i + 1], a[i + 2]];
      const at = (side: number): [number, number, number] => { const p = (side === 0 ? w.p1 : w.p2).pos; return [p[0], p[1] + 1.1, p[2]]; };
      switch (e.kind) {
        case 'hit': this.spark(...xyz(2), a[6] ? 0xfff070 : 0xffb050, a[6] ? 1.1 : 0.8); break;
        case 'blocked': this.spark(...xyz(2), 0x6fa8ff, 0.6); break;
        case 'guard-crush': case 'guard-break': case 'stance-break': this.spark(...xyz(2), 0xffffff, 1.6, 0.4); break;
        case 'parried': case 'absorbed': case 'armored': this.spark(...xyz(1), 0x9ff0ff, 0.9); break;
        case 'clash': this.spark(...xyz(0), 0xffffff, 1.2); break;
        case 'hazard-cut': this.spark(...xyz(0), 0xffd090, 0.7); break;
        case 'kikon': case 'soul-break': this.spark(...at(a[1]), 0xff2030, 2.5, 0.6); break;
        case 'hoho-out': case 'hoho-in': this.spark(a[1], 1.0, a[2], 0x9fc8ff, 0.7, 0.3); break;
        case 'burst': this.spark(...at(a[0]), e.args[2] === 'blue' ? 0x50a0ff : e.args[2] === 'orange' ? 0xff9030 : 0xffffff, 2.2, 0.4); break;
      }
    }
  }

  update(w: World, rdt: number): void {
    this.t += rdt;
    this.fighters[0].update(w.p1, this.t); this.fighters[1].update(w.p2, this.t);
    // hazards: one mesh per live hazard
    for (const [hz, m] of this.hazards) if (!hz.alive || !w.hazards.includes(hz)) { m.dispose(false, true); this.hazards.delete(hz); }
    for (const hz of w.hazards) {
      if (!hz.alive) continue;
      let m = this.hazards.get(hz);
      if (!m) { m = this.hazardMesh(hz); this.hazards.set(hz, m); }
      const len = hz.kind === 'line' ? hz.size : 0;
      m.position.set(hz.x + 0.5 * len * fwdX(hz.yaw), hz.kind === 'fireball' ? hz.y : hz.kind === 'line' ? 0.02 : hz.kind === 'wave' ? 0.8 : 0.3,
                     hz.z + 0.5 * len * fwdZ(hz.yaw));
      m.rotation.y = hz.yaw;
      m.isVisible = hz.delay <= 0;
      m.visibility = hz.life > 0 ? Math.max(0.15, 1 - hz.age / hz.life) : 1;
    }
    // sparks grow and fade on real time
    this.sparks = this.sparks.filter((s) => {
      s.life -= rdt;
      if (s.life <= 0) { s.m.dispose(false, true); return false; }
      const k = 1 - s.life / s.max;
      s.m.scaling.setAll(s.grow * (0.4 + 0.8 * k)); s.m.visibility = 1 - k;
      return true;
    });
  }

  hazardMesh(hz: Hazard): Mesh {
    const s = this.scene;
    const m = hz.kind === 'wave' ? MeshBuilder.CreateBox('wave', { width: 2 * hz.size, height: 1.6, depth: 0.35 }, s)
      : hz.kind === 'fireball' ? MeshBuilder.CreateSphere('fireball', { diameter: 2 * hz.size, segments: 12 }, s)
      : hz.kind === 'line' ? MeshBuilder.CreateBox('line', { width: 0.3, height: 0.02, depth: hz.size }, s)
      : MeshBuilder.CreateSphere(hz.kind, { diameter: 0.6, segments: 8 }, s);
    m.material = mat(s, hex(HAZ_COLOR[hz.look ?? hz.kind] ?? 0xffc080), (hz.look ?? hz.kind) !== 'crack');
    return m;
  }

  dispose(): void {
    for (const f of this.fighters) f.dispose();
    for (const m of this.hazards.values()) m.dispose(false, true);
    for (const s of this.sparks) s.m.dispose(false, true);
  }
}
