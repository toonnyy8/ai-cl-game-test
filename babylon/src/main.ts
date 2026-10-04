// main.ts <- duel/lisp/main.lisp GAME-FRAME: one frame = the touch page services (onehand.ts) -> the flow (src/ui/flow.ts:
// menus, pause, screens) -> the match's fixed 60 Hz steps (at most 6 a frame, time.ts runFixedSteps; none while paused)
// -> camera (portrait window: render/portrait.ts; else camera.ts) -> draw -> HUD (+ the touch controls).
import './chars';
import { Engine, Matrix, Vector3, WebGPUEngine, type AbstractEngine } from '@babylonjs/core';
import type { Match } from './sim/match';
import { BattleView, createScene } from './render/scene';
import { updateCel } from './render/cel';
import { installSheet } from './render/sheet';
import { installVfxDebug } from './render/vfx/debug';
import { DuelCamera } from './render/camera';
import { Cinema, installCineDebug } from './render/cinema';
import { PortraitCamera, applyLens, clearLens } from './render/portrait';
import { clearHud, drawBattle, hudCtx, hudEvents, hudSize, resetHud, resizeHud } from './render/hud';
import { drawTouch, onehandFrame, perfectHintP, portraitMetrics, portraitP } from './input/onehand';
import { kikonPrompt } from './input/bindings';
import { F, endlessTag, flowFrame, practiceP, simRunning, startFlow, touchMode } from './ui/flow';
import './ui/pwa';
import { audioEvents, audioFrame, setListener } from './audio';

const canvas = document.getElementById('game') as HTMLCanvasElement;

const forceGL = new URLSearchParams(location.search).has('gl');      // ?gl=1: the WebGL2 fallback path
async function makeEngine(): Promise<AbstractEngine> {
  if (!forceGL) try {
    if (await WebGPUEngine.IsSupportedAsync) {
      const e = new WebGPUEngine(canvas, { antialias: true });
      await e.initAsync();
      return e;
    }
  } catch (err) { console.warn('WebGPU unavailable, using WebGL2:', err); }
  return new Engine(canvas, true);
}

const engine = await makeEngine();
const stage = createScene(engine), { scene, cam } = stage;
installSheet(engine, stage);                         // window.duelRender: the still sheet + render stats (debug)
installVfxDebug(engine, stage);                      // window.duelVfx: the ink VFX / HUD still scenes (debug)
const cinema = new Cinema(stage, engine);            // the cinematics' shots, looks and grade (render/cinema.ts)
installCineDebug(engine, stage, cinema);             // window.duelCine: cinematic stills (debug)
const duelCam = new DuelCamera(), ptCam = new PortraitCamera();
setListener(cam);                                    // the camera hears the world (src/audio)
resizeHud();
addEventListener('resize', () => { engine.resize(); resizeHud(); });

let view: BattleView | null = null, menuT = 0;
F.onMatch = (m: Match | null) => {
  view?.dispose();
  view = m ? new BattleView(scene, m.w, stage) : null;
  duelCam.cut = true; duelCam.punchT = 0; ptCam.cut = true;
  cinema.reset();
  resetHud();
};

function project(x: number, y: number, z: number): [number, number] | null {
  const rw = engine.getRenderWidth(), rh = engine.getRenderHeight();
  const p = Vector3.Project(new Vector3(x, y, z), Matrix.IdentityReadOnly, scene.getTransformMatrix(), cam.viewport.toGlobal(rw, rh));
  if (p.z < 0 || p.z > 1) return null;
  const [w, h] = hudSize();
  return [(p.x * w) / rw, (p.y * h) / rh];
}

// the headless harness's handle (tools/run.mjs "eval" steps, e.g. duel.match.runToEnd())
Object.assign(window, { duel: { get match() { return F.match; }, scene } });

startFlow();
engine.runRenderLoop(() => {
  const rdt = Math.min(0.25, engine.getDeltaTime() / 1000);
  const m0 = F.match;
  onehandFrame(F.screen === 'battle' && m0 ? m0.w : null, touchMode(), simRunning());
  flowFrame(rdt);
  const m = F.match, battle = F.screen === 'battle' || F.screen === 'results';
  // the fixed steps (sim time; a paused match keeps no backlog; the select screen's preview pair never steps)
  if (m && battle) {
    const t = m.w.time;
    if (simRunning()) t.runFixedSteps(rdt, () => m.step(), 6);
    else t.stepAcc = 0;
    const ev = m.takeEvents();
    for (const e of ev) if (e.kind === 'perfect') duelCam.punchT = 0.5;
    for (const e of ev) if (e.kind === 'cine-end') { duelCam.cut = true; ptCam.cut = true; }
    duelCam.events(ev);                                    // hit shake, Kikon zoom punch
    view?.events(ev, m.w);
    cinema.events(ev, m.w, view);
    hudEvents(ev);
    audioEvents(ev, m.w);
    for (const l of m.takeLog()) if (l.startsWith('duel -> RESULTS') || l.startsWith('duel match')) console.log(l);
  }
  audioFrame(F.screen, F.match?.w ?? null);             // the screen's music, the cinematic's sound beats
  // camera
  const live = F.paused ? 0 : rdt;
  if (m && battle && portraitP() && !m.w.cine) {
    const { fov, shift } = ptCam.update(m.w, live, portraitMetrics().band);
    cam.position.copyFrom(ptCam.eye); cam.setTarget(ptCam.at);
    applyLens(cam, engine, fov, shift);
  } else {
    clearLens(cam);
    if (m) {
      duelCam.aspect = engine.getAspectRatio(cam);
      duelCam.update(m.w, live);
      cam.position.copyFrom(duelCam.eye); cam.setTarget(duelCam.at);
      if (F.screen === 'select' && portraitP())                // a tall menu frame: back off so both picks show
        cam.position.copyFrom(duelCam.at.add(duelCam.eye.subtract(duelCam.at).scale(2.8)));
      ptCam.cut = true;
    } else {                                         // menus: a slow orbit of the plaza
      menuT += rdt;
      cam.position.set(14 * Math.cos(menuT * 0.1), 4, 14 * Math.sin(menuT * 0.1)); cam.setTarget(new Vector3(0, 1, 0));
    }
  }
  cinema.camera(m && battle ? m.w : null, cam, engine.getAspectRatio(cam));   // a cinematic's shot over the camera
  // draw
  if (m && view) cinema.update(m.w, view, live);
  updateCel(cam);
  scene.render();
  // HUD
  if (m && F.screen === 'battle' && !F.paused) {
    drawBattle(m.w, project, { portrait: portraitP(), practice: practiceP(), hint: perfectHintP(m.w),
                               prompt: (side) => (F.oneHand && side === 0 ? 'HOLD O  KIKON' : kikonPrompt(side)), tag: endlessTag() });
    drawTouch(hudCtx(), m.w);
  } else clearHud();
});
