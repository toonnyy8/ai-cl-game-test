// sheet.ts: debug hooks for the look review (headless screenshots): window.duelRender.sheet(cols, cam) takes over the
// render loop and shows every roster character in a row of posed states at a fixed camera; .stats() reads draw calls
// (this frame, G-buffer pass included), active meshes and triangles.
import { Matrix, SceneInstrumentation, Vector3, type AbstractEngine } from '@babylonjs/core';
import { Match } from '../sim/match';
import { ROSTER, findMove } from '../sim/kit';
import type { Ent, FState } from '../sim/types';
import { FighterView, type Stage } from './scene';
import { InkSparks } from './ink';
import { updateCel } from './cel';

export function installSheet(engine: AbstractEngine, stage: Stage): void {
  const { scene, cam } = stage;
  new SceneInstrumentation(scene);                   // resets the engine's draw-call counter every frame
  let views: { v: FighterView; e: Ent }[] = [], ink: InkSparks | null = null;
  /** COLS: state names, 'slash[:move[:sf]]', 'stun[:react]'. CAM: [eye x y z, target x y z]. ONLY: one character
   *  ('who:form' shows a form's body). FX: the three ink sparks in front. */
  const sheet = (cols: string[] = ['idle', 'guard', 'slash', 'stun'], c?: number[], only?: string, fx = false) => {
    engine.stopRenderLoop();
    const hud = document.getElementById('hud') as HTMLCanvasElement | null;
    hud?.getContext('2d')!.clearRect(0, 0, hud.width, hud.height);
    for (const s of views) s.v.dispose();
    views = [];
    const [who1, form] = (only ?? '').split(':'), roster = only ? [who1] : ROSTER;
    roster.forEach((who, r) => cols.forEach((col, i) => {
      const e = new Match({ p1: who, p2: who, seed: 1, cpu1: true, cpu2: true }).start().w.p1, f = e.f;
      if (form) f.form = form;
      e.pos.set([(i - (cols.length - 1) / 2) * 1.7, 0, roster.length > 1 ? (r - 0.5) * -2.0 : 0]); e.yaw = Math.PI + 0.5; e.look.alpha = 1;
      const [st, a, b] = col.split(':');
      f.state = (st === 'slash' ? 'move' : st) as FState; f.sf = 0; f.phase = null;
      if (st === 'slash' || st === 'move') {
        f.move = findMove(a ?? f.kit.commands.q!); f.phase = 'main';
        f.sf = b !== undefined ? +b : f.move.s + 1;
      }
      if (st === 'stun') { f.phase = a ?? 'stagger'; f.stun = 26; f.sf = 8; }
      const v = new FighterView(scene, e, stage.outline);
      for (let k = 0; k < 30; k++) v.update(e, 1 / 30, k / 30);
      views.push({ v, e });
    }));
    if (fx) {                                        // the ink sparks, frozen at full size, in front of the row
      ink?.dispose(); ink = new InkSparks(scene, stage.ink);
      ink.add('hit', -1.6, 1.2, 1.2, 1.4, 1); ink.add('block', 0, 1.2, 1.2, 1.2, 1); ink.add('kikon', 1.6, 1.2, 1.2, 1.8, 1);
      ink.step(0.3);
    }
    const p = c ?? [0, 1.3, 7.5, 0, 0.95, 0];
    cam.position.set(p[0], p[1], p[2]); cam.setTarget(new Vector3(p[3], p[4], p[5]));
    engine.runRenderLoop(() => {
      updateCel(cam);
      scene.render();
    });
  };
  const stats = () => {
    const act = scene.getActiveMeshes().data.filter((m) => m.isVisible);
    return { draws: (engine as unknown as { _drawCalls: { current: number } })._drawCalls.current, active: act.length,
      tris: act.reduce((n, m) => n + m.getTotalIndices() / 3, 0), webgpu: engine.isWebGPU };
  };
  const dbg = () => ({ r: cam.getDirection(Vector3.Right()).asArray(), f: cam.getDirection(Vector3.Forward()).asArray() });
  /** The live match's fighters on screen: [top, bottom] as fractions of the frame height, and the height fraction. */
  const frac = () => {
    const w = (window as unknown as { duel: { match: { w: { p1: Ent; p2: Ent } } | null } }).duel.match?.w;
    if (!w) return null;
    const vp = cam.viewport.toGlobal(engine.getRenderWidth(), engine.getRenderHeight()), m = scene.getTransformMatrix();
    return [w.p1, w.p2].map((e) => {
      const lo = Vector3.Project(new Vector3(e.pos[0], 0, e.pos[2]), Matrix.IdentityReadOnly, m, vp);
      const hi = Vector3.Project(new Vector3(e.pos[0], e.body.hurtH, e.pos[2]), Matrix.IdentityReadOnly, m, vp);
      return { top: +(hi.y / vp.height).toFixed(3), bottom: +(lo.y / vp.height).toFixed(3), h: +((lo.y - hi.y) / vp.height).toFixed(3) };
    });
  };
  Object.assign(window, { duelRender: { sheet, stats, dbg, frac } });
}
