// main.ts <- duel/lisp/main.lisp GAME-FRAME + the menu part of flow.lisp: one frame = flow (title, select, battle,
// results, pause) -> the match's fixed 60 Hz steps (at most 6 a frame, time.ts runFixedSteps; none while paused) ->
// camera -> draw -> HUD. VS CPU: P1 is the keyboard / pad 0 and the behind camera (the sim's W.viewBehind), P2 the CPU;
// CPU VS CPU: both CPUs, the pair camera.
import './chars';
import { Engine, Matrix, Vector3, WebGPUEngine, type AbstractEngine } from '@babylonjs/core';
import { Match, setBrainStep } from './sim/match';
import { stubBrainStep } from './sim/stubai';
import { ROSTER } from './sim/kit';
import { readP1, takePresses } from './input/keyboard';
import { BattleView, createScene } from './render/scene';
import { DuelCamera } from './render/camera';
import {
  MODES, drawBattle, drawPause, drawResults, drawSelect, drawTitle, hudEvents, hudSize, resetHud, resizeHud,
  type Sel,
} from './render/hud';

const canvas = document.getElementById('game') as HTMLCanvasElement;

async function makeEngine(): Promise<AbstractEngine> {
  try {
    if (await WebGPUEngine.IsSupportedAsync) {
      const e = new WebGPUEngine(canvas, { antialias: true });
      await e.initAsync();
      return e;
    }
  } catch (err) { console.warn('WebGPU unavailable, using WebGL2:', err); }
  return new Engine(canvas, true);
}

const engine = await makeEngine();
const { scene, cam } = createScene(engine);
const duelCam = new DuelCamera();
resizeHud();
addEventListener('resize', () => { engine.resize(); resizeHud(); });

type Screen = 'title' | 'select' | 'battle';
let screen: Screen = 'title';
const sel: Sel = { row: 3, p1: 0, p2: Math.min(1, ROSTER.length - 1), mode: 0 };
let match: Match | null = null, view: BattleView | null = null, paused = false, resultsT = 0, menuT = 0;

function startMatch(): void {
  const vsCpu = sel.mode === 0;
  setBrainStep(stubBrainStep);                       // ponytail: the M1 stub CPU; M2 swaps in ai.ts's brain step
  match = new Match({ p1: ROSTER[sel.p1], p2: ROSTER[sel.p2], seed: 1 + Math.floor(Math.random() * 0x7ffffffe),
                      cpu1: !vsCpu, cpu2: true, readers: [vsCpu ? readP1 : null, null] });
  match.w.viewBehind = vsCpu;                        // humans steer by the behind view (flow.lisp: VS CPU)
  match.start();
  view = new BattleView(scene, match.w);
  duelCam.cut = true; duelCam.punchT = 0;
  paused = false; resultsT = 0;
  resetHud();
  screen = 'battle';
}
function endMatch(): void { view?.dispose(); view = null; match = null; screen = 'select'; }

const wrap = (i: number, n: number) => ((i % n) + n) % n;
function flow(presses: string[], rdt: number): void {
  for (const k of presses) {
    if (screen === 'title') { if (k === 'Enter' || k === 'Space') screen = 'select'; }
    else if (screen === 'select') {
      const dy = k === 'KeyS' || k === 'ArrowDown' ? 1 : k === 'KeyW' || k === 'ArrowUp' ? -1 : 0;
      const dx = k === 'KeyD' || k === 'ArrowRight' ? 1 : k === 'KeyA' || k === 'ArrowLeft' ? -1 : 0;
      if (dy) sel.row = wrap(sel.row + dy, 4);
      if (dx && sel.row === 0) sel.p1 = wrap(sel.p1 + dx, ROSTER.length);
      if (dx && sel.row === 1) sel.p2 = wrap(sel.p2 + dx, ROSTER.length);
      if (dx && sel.row === 2) sel.mode = wrap(sel.mode + dx, MODES.length);
      if (k === 'Enter') { startMatch(); return; }
      if (k === 'Escape') screen = 'title';
    } else if (match) {
      if (!match.running()) { if (k === 'Enter' && resultsT > 1.5) { endMatch(); return; } }
      else if (k === 'Escape') paused = !paused;
      else if (k === 'Enter' && paused) { endMatch(); return; }
    }
  }
  if (match && !match.running()) resultsT += rdt;
}

function project(x: number, y: number, z: number): [number, number] | null {
  const rw = engine.getRenderWidth(), rh = engine.getRenderHeight();
  const p = Vector3.Project(new Vector3(x, y, z), Matrix.IdentityReadOnly, scene.getTransformMatrix(), cam.viewport.toGlobal(rw, rh));
  if (p.z < 0 || p.z > 1) return null;
  const [w, h] = hudSize();
  return [(p.x * w) / rw, (p.y * h) / rh];
}

// the headless harness's handle (tools/run.mjs "eval" steps, e.g. duel.match.runToEnd())
Object.assign(window, { duel: { get match() { return match; } } });

engine.runRenderLoop(() => {
  const rdt = Math.min(0.25, engine.getDeltaTime() / 1000);
  flow(takePresses(), rdt);
  // the fixed steps (sim time; a paused match keeps no backlog)
  if (match) {
    const m = match, t = m.w.time;
    if (!paused && m.running()) t.runFixedSteps(rdt, () => m.step(), 6);
    else t.stepAcc = 0;
    const ev = m.takeEvents();
    for (const e of ev) if (e.kind === 'perfect') duelCam.punchT = 0.5;
    for (const e of ev) if (e.kind === 'cine-end') duelCam.cut = true;
    view!.events(ev, m.w);
    hudEvents(ev);
    for (const l of m.takeLog()) if (l.startsWith('duel -> RESULTS') || l.startsWith('duel match')) console.log(l);
  }
  // camera
  if (match) {
    duelCam.update(match.w, paused ? 0 : rdt);
    cam.position.copyFrom(duelCam.eye); cam.setTarget(duelCam.at);
  } else {                                           // menus: a slow orbit of the plaza
    menuT += rdt;
    cam.position.set(14 * Math.cos(menuT * 0.1), 4, 14 * Math.sin(menuT * 0.1)); cam.setTarget(new Vector3(0, 1, 0));
  }
  // draw
  if (match) view!.update(match.w, paused ? 0 : rdt);
  scene.render();
  // HUD
  if (screen === 'title') drawTitle();
  else if (screen === 'select') drawSelect(sel, ROSTER);
  else if (match && !match.running()) drawResults(match.w, resultsT > 1.5);
  else if (match) { drawBattle(match.w, project); if (paused) drawPause(); }
});
