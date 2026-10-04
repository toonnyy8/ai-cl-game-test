// vfx/index.ts: the battle's ink effects in one object for scene.ts's BattleView: hazard looks (hazards.ts), auras
// (aura.ts), blade arcs and afterimages (trail.ts). Ichigo's ZANZO afterimages, clones and echoes are ink silhouettes of
// his posed body (not sprites) when his view is there. Real time (rdt) for fades, the sim's ages for hazard timing.
import type { Scene } from '@babylonjs/core';
import type { Hazard, SimEvent, World } from '../../sim/types';
import type { FighterView } from '../scene';
import { HazardLooks } from './hazards';
import { Auras } from './aura';
import { Trails } from './trail';
import { hex3 } from './brush';

const GHOSTS: Record<string, number> = { 'ichigo-zanzo-look': 0x1c1a24, 'ichigo-clone-look': 0x3a0d12, 'ichigo-echo-look': 0x3a0d12 };
type Ghost = NonNullable<ReturnType<Trails['ghost']>>;

export class Vfx {
  hz: HazardLooks; auras: Auras; trails: Trails;
  ghosted = new Map<Hazard, Ghost>();
  t = 0;
  constructor(readonly scene: Scene, readonly views: FighterView[]) {
    this.hz = new HazardLooks(scene); this.auras = new Auras(scene); this.trails = new Trails(scene);
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
      let g = this.ghosted.get(hz);
      if (!g && hz.delay <= 0) {
        const v = this.views[hz.owner === w.p2 ? 1 : 0], zanzo = hz.look === 'ichigo-zanzo-look';   // (a ZANZO's yaw is 0: his)
        g = this.trails.ghost(v, hz.x, hz.z, zanzo ? hz.owner.yaw : hz.yaw, zanzo ? Math.max(1, hz.life) / 60 : Infinity, hex3(tint)) ?? undefined;
        if (!g) { rest.push(hz); continue; }
        this.ghosted.set(hz, g);
      }
      if (g && hz.look !== 'ichigo-zanzo-look') { g.node.position.set(hz.x, 0, hz.z); g.node.rotation.y = hz.yaw; }
    }
    for (const [hz, g] of this.ghosted) if (!hz.alive || !w.hazards.includes(hz)) { this.trails.drop(g); this.ghosted.delete(hz); }
    this.hz.update(rest, this.t, rdt);
    this.auras.update(es);
    this.trails.update(es, this.views, rdt);
  }

  /** Live particles and VFX meshes (the budget check: <= 500 particles). */
  stats(): { particles: number; hazards: number; ghosts: number; arcs: number[] } {
    return { particles: this.auras.live(), hazards: this.hz.views.size, ghosts: this.trails.ghosts.length,
             arcs: this.trails.ribbons.map((r) => (r.m.isVisible ? r.pts.length / 2 : 0)) };
  }
  dispose(): void { this.hz.dispose(); this.auras.dispose(); this.trails.dispose(); this.ghosted.clear(); }
}
