// vfx/index.ts: the battle's ink effects in one object for scene.ts's BattleView: hazard looks (hazards.ts), auras
// (aura.ts), blade arcs and afterimages (trail.ts), Rukia's ribbon and Senjumaru's threads (strands.ts). Ichigo's ZANZO
// afterimages, clones and echoes are flat-ink copies of his KESSA body (bodies/ichigo.ts IchigoGhost, pooled), posed by
// the clone's / echo's own move and frame (ZANZO: his pose when it opened). Real time (rdt) for fades, the sim's ages
// for hazard timing.
import { Color3, StandardMaterial, type Scene } from '@babylonjs/core';
import type { Move } from '../../sim/kit';
import type { Hazard, SimEvent, World } from '../../sim/types';
import type { FighterView } from '../scene';
import { IchigoGhost } from '../bodies/ichigo';
import { HazardLooks } from './hazards';
import { Auras } from './aura';
import { Trails } from './trail';
import { Strands } from './strands';
import { FPS, hex3 } from './brush';

const GHOSTS: Record<string, number> = { 'ichigo-zanzo-look': 0x1c1a24, 'ichigo-clone-look': 0x3a0d12, 'ichigo-echo-look': 0x3a0d12 };
interface Ghost { g: IchigoGhost; mat: StandardMaterial }

export class Vfx {
  hz: HazardLooks; auras: Auras; trails: Trails; strands: Strands;
  ghosted = new Map<Hazard, Ghost>();
  free: Ghost[] = [];
  t = 0;
  constructor(readonly scene: Scene, readonly views: FighterView[]) {
    this.hz = new HazardLooks(scene); this.auras = new Auras(scene); this.trails = new Trails(scene);
    this.strands = new Strands(scene, views);
  }

  /** A pooled KESSA ghost tinted TINT (ponytail: built on first need, never shrunk; a match spawns a handful). */
  private take(tint: number): Ghost {
    let gh = this.free.pop();
    if (!gh) {
      const mat = new StandardMaterial('ichigo-ghost', this.scene);
      mat.disableLighting = true; mat.diffuseColor = Color3.Black(); mat.specularColor = Color3.Black(); mat.backFaceCulling = false;
      const g = new IchigoGhost(this.scene, mat, mat, 'kessa', `ichigo-ghost-${this.ghosted.size + this.free.length}`);
      g.body.face.isVisible = false;
      gh = { g, mat };
    }
    gh.mat.emissiveColor = hex3(tint);
    this.show(gh, true);
    return gh;
  }
  private show(gh: Ghost, on: boolean, vis = 0.75): void {
    for (const m of [gh.g.body.mesh, gh.g.body.weapon]) { m.setEnabled(on); m.visibility = vis; }
    gh.g.body.face.setEnabled(false);
  }

  events(ev: SimEvent[], w: World): void {
    for (const e of ev) {
      if (e.kind !== 'hoho-out') continue;
      const [side, x, z] = e.args as number[];
      this.trails.ghost(this.views[side], x, z, (side ? w.p2 : w.p1).yaw, 0.42);
    }
  }

  update(w: World, rdt: number): void {
    this.t += rdt;
    const es = [w.p1, w.p2], rest: Hazard[] = [];
    for (const hz of w.hazards) {
      const tint = hz.alive && hz.look ? GHOSTS[hz.look] : undefined;
      if (tint === undefined) { rest.push(hz); continue; }
      if (hz.delay > 0) continue;
      const zanzo = hz.look === 'ichigo-zanzo-look', o = hz.owner.f;
      let gh = this.ghosted.get(hz);
      if (!gh) {
        gh = this.take(tint); this.ghosted.set(hz, gh);
        if (zanzo) gh.g.pose(o.state === 'move' ? o.move : null, o.sf, 1);   // his pose as it opened (no cross-fade), kept
      }
      const m = gh.g.body.mesh;
      if (zanzo) {                                    // where he stood (a ZANZO's yaw is 0: his), fading in steps
        m.position.set(hz.x, 0, hz.z); m.rotation.y = hz.owner.yaw;
        const k = Math.floor((hz.age / Math.max(1, hz.life)) * FPS) / FPS;
        this.show(gh, true, 0.75 * (1 - k));
      } else {                                        // a clone / an echo: its own move at its own frame
        const d = hz.data as { mv?: Move | null; sf?: number } | null;
        gh.g.pose(d?.mv ?? null, d?.sf ?? 0, rdt);
        m.position.set(hz.x, 0, hz.z); m.rotation.y = hz.yaw;
      }
    }
    for (const [hz, gh] of this.ghosted) if (!hz.alive || !w.hazards.includes(hz)) { this.show(gh, false); this.free.push(gh); this.ghosted.delete(hz); }
    this.hz.update(rest, this.t, rdt);
    this.auras.update(es);
    this.trails.update(es, this.views, rdt);
    this.strands.update(es, rdt);
  }

  /** Live particles and VFX meshes (the budget check: <= 500 particles). */
  stats(): { particles: number; hazards: number; ghosts: number; arcs: number[] } {
    return { particles: this.auras.live(), hazards: this.hz.views.size, ghosts: this.trails.ghosts.length + this.ghosted.size,
             arcs: this.trails.ribbons.map((r) => (r.m.isVisible ? r.pts.length / 2 : 0)) };
  }
  dispose(): void {
    this.hz.dispose(); this.auras.dispose(); this.trails.dispose(); this.strands.dispose();
    for (const gh of [...this.ghosted.values(), ...this.free]) { gh.g.dispose(); gh.mat.dispose(); }
    this.ghosted.clear(); this.free = [];
  }
}
