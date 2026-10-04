// vfx/debug.ts: window.duelVfx.show(spec), a still scene for the look review of the ink VFX and HUD (headless screenshots):
// a CPU-vs-CPU match that never steps, fighters forced into forms / moves / spots, hazards spawned at given ages, an
// optional cinematic frame (its card) and the battle HUD over it; the BattleView keeps running (auras, trails, stepped
// sheets). .stats() adds the VFX counts to duelRender's draw calls.
import { Matrix, Vector3, type AbstractEngine } from '@babylonjs/core';
import { Match } from '../../sim/match';
import { findMove } from '../../sim/kit';
import { setForm } from '../../sim/combat';
import { spawnHazard, type HazardOpts } from '../../sim/hazards';
import { setWorld, type Ent, type FState } from '../../sim/types';
import { BattleView, type Stage } from '../scene';
import { updateCel } from '../cel';
import { drawBattle, hudSize } from '../hud';

interface Fs { char: string; form?: string; at?: [number, number]; yaw?: number; move?: string; state?: string;
  meter?: number; reishi?: number; konpaku?: number; burst?: 'white' | 'blue' | 'orange'; evolution?: boolean }
interface Spec { p1: Fs; p2: Fs; hz?: (HazardOpts & { kind: string; owner?: 0 | 1; age?: number })[]; cam?: number[];
  hud?: boolean; portrait?: boolean; cine?: [string, number, number] }

export function installVfxDebug(engine: AbstractEngine, stage: Stage): void {
  const { scene, cam } = stage;
  let view: BattleView | null = null;
  const show = (sp: Spec) => {
    engine.stopRenderLoop();
    view?.dispose();
    (document.getElementById('ui') as HTMLElement).hidden = true;
    const m = new Match({ p1: sp.p1.char, p2: sp.p2.char, seed: 1, cpu1: true, cpu2: true }).start(), w = m.w;
    setWorld(w); w.flow = 'battle'; w.cine = null;
    const set = (e: Ent, o: Fs, dflt: [number, number]) => {
      if (o.form && o.form !== 'base') setForm(e, o.form);
      const [x, z] = o.at ?? dflt;
      e.pos.set([x, 0, z]); e.yaw = o.yaw ?? (x < 0 ? -Math.PI / 2 : Math.PI / 2); e.look.alpha = 1;
      e.f.state = (o.state ?? 'idle') as FState; e.f.sf = 0;
      if (o.meter != null) e.g.meter = o.meter;
      if (o.reishi != null) e.g.reishi = o.reishi * e.g.reishiMax;
      if (o.konpaku != null) e.g.konpaku = o.konpaku;
      if (o.burst) e.g.burst = o.burst;
      if (o.evolution) e.g.evolution = true;
      if (o.move) { e.f.state = 'move'; e.f.move = findMove(o.move); e.f.phase = 'main'; e.f.sf = e.f.move.s; }
    };
    set(w.p1, sp.p1, [-1.6, 0]); set(w.p2, sp.p2, [1.6, 0]);
    for (const h of sp.hz ?? []) {
      const hz = spawnHazard(h.kind, h.owner ? w.p2 : w.p1, h);
      hz.age = h.age ?? 10;
    }
    if (sp.cine) w.cine = { name: sp.cine[0], cf: sp.cine[1], len: sp.cine[2], a: w.p1, v: w.p2, after: null, skip: false };
    view = new BattleView(scene, w, stage);
    const p = sp.cam ?? [0, 2.2, 9, 0, 1.0, 0];
    cam.position.set(p[0], p[1], p[2]); cam.setTarget(new Vector3(p[3], p[4], p[5]));
    let frame = 0;
    const project = (x: number, y: number, z: number): [number, number] | null => {
      const rw = engine.getRenderWidth(), rh = engine.getRenderHeight();
      const q = Vector3.Project(new Vector3(x, y, z), Matrix.IdentityReadOnly, scene.getTransformMatrix(), cam.viewport.toGlobal(rw, rh));
      const [hw, hh] = hudSize();
      return [(q.x * hw) / rw, (q.y * hh) / rh];
    };
    engine.runRenderLoop(() => {
      frame++;
      for (const e of [w.p1, w.p2]) {                                   // a move cycles through its strike: the arc draws
        const mv = e.f.move;
        if (e.f.state === 'move' && mv) e.f.sf = mv.s - 4 + (Math.floor(frame / 2) % (mv.a + 9));
      }
      view!.update(w, 1 / 60);
      updateCel(cam);
      scene.render();
      if (sp.hud) drawBattle(w, project, { portrait: !!sp.portrait, practice: false, hint: false, prompt: () => 'HOLD O  KIKON' });
    });
  };
  const stats = () => ({ ...(view?.vfx.stats() ?? {}),
    draws: (engine as unknown as { _drawCalls: { current: number } })._drawCalls.current,
    active: scene.getActiveMeshes().length, particles: scene.particleSystems.reduce((n, p) => n + p.getActiveCount(), 0) });
  Object.assign(window, { duelVfx: { show, stats, get view() { return view; } } });
}
