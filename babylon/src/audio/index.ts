// audio/index.ts <- engine/c/audio.c (the mixer) + engine/lisp/audio.lisp's play API, on WebAudio: 32 pooled voices
// (gain + stereo pan nodes kept; a buffer source per play, as WebAudio requires), an sfx and a music bus, a master gain
// (SETTINGS SOUND) and a peak limiter at 0.9 (a hard compressor). A full pool steals the one-shot with the lowest
// gain x remaining fraction; loops are never stolen. The bank (sounds.ts) renders in a worker after load; a sound not
// rendered yet is silent. The AudioContext is made and resumed inside the first key / pointer / touch gesture (the autoplay
// rule; Safari wants resume() in the gesture itself) and suspended while the page is hidden. Nothing here touches the sim.
import { type Buf, RATE } from './synth';
import { BANK_ORDER, renderSound } from './sounds';
import { type Sink, feedback } from './feedback';
import { CUES } from './cues';
import type { Cine, SimEvent, World } from '../sim/types';
import { onSettings, settingValue } from '../ui/settings';

const NV = 32, MUSIC_VOL = 0.55;                    // AU_NV; set-music-volume's default
interface Voice { src: AudioBufferSourceNode | null; g: GainNode; pan: StereoPannerNode; bus: GainNode | null;
                  gain: number; t0: number; dur: number; loop: boolean; id: number }
let ctx: AudioContext | null = null, master: GainNode, sfxBus: GainNode, musicBus: GainNode;
const voices: Voice[] = [];
const bank = new Map<string, AudioBuffer>();
let serial = 0, unlocked = false, plays = 0;

function addSound(key: string, data: Buf): void {
  const b = new AudioBuffer({ length: data.length, sampleRate: RATE, numberOfChannels: 1 });
  b.copyToChannel(data, 0);
  bank.set(key, b);
}
function renderBank(): void {
  try {
    const wk = new Worker(new URL('./worker.ts', import.meta.url), { type: 'module' });
    wk.onmessage = (e: MessageEvent<{ key: string; data: Buf }>) => addSound(e.data.key, e.data.data);
    wk.onerror = () => { wk.terminate(); renderHere(bank.size); };
  } catch { renderHere(0); }
}
/** No worker: one sound per macrotask on the main thread. */
function renderHere(i: number): void {
  if (i < BANK_ORDER.length) setTimeout(() => { const k = BANK_ORDER[i]; if (!bank.has(k)) addSound(k, renderSound(k)); renderHere(i + 1); }, 0);
}

function makeContext(): void {
  ctx = new AudioContext({ latencyHint: 'interactive' });
  master = ctx.createGain(); sfxBus = ctx.createGain(); musicBus = ctx.createGain();
  const lim = limiter(ctx);
  sfxBus.connect(master); musicBus.connect(master); master.connect(lim[0]); lim[1].connect(ctx.destination);
  for (let k = 0; k < NV; k++) {
    const g = ctx.createGain(), pan = ctx.createStereoPanner();
    g.connect(pan);
    voices.push({ src: null, g, pan, bus: null, gain: 0, t0: 0, dur: 1, loop: false, id: -1 });
  }
  volumes();
}
/** The peak limiter: a soft clip (linear to 0.8, a tanh knee to at most 0.95). ponytail: the C mixer's limiter rides the
 *  gain (instant attack, 100 ms release); a stateless curve has no lookahead or pumping (DynamicsCompressor ducked the
 *  short transients by half in the offline check) and only bends the peaks of a pile-up. */
function limiter(c: BaseAudioContext): [AudioNode, AudioNode] {
  const pre = c.createGain(), ws = c.createWaveShaper(), n = 4097, curve = new Float32Array(n);
  pre.gain.value = 0.5;                              // the curve's input -1..1 stands for -2..2
  for (let i = 0; i < n; i++) {
    const x = 2 * (2 * i / (n - 1) - 1), a = Math.abs(x);
    curve[i] = Math.sign(x) * (a <= 0.8 ? a : 0.8 + 0.15 * Math.tanh((a - 0.8) / 0.15));
  }
  ws.curve = curve; pre.connect(ws);
  return [pre, ws];
}
function unlock(): void {
  if (!ctx) try { makeContext(); } catch (err) { console.warn('audio: no AudioContext:', err); return; }
  unlocked = true;
  if (ctx!.state !== 'running' && !document.hidden) void ctx!.resume();
}

// ---------------------------------------------------------------- the mixer
const running = (): boolean => !!ctx && ctx.state === 'running';
const alive = (id: number): boolean => id >= 0 && voices[id & 31]?.id === id && !!voices[id & 31].src;

/** au_play: KEY on BUS at GAIN, PAN (-1 left .. 1 right) and PITCH (a rate ratio). A voice id, or -1. */
function play(key: string, gain: number, pan: number, pitch: number, loop: boolean, bus: GainNode): number {
  const buf = bank.get(key);
  if (!running() || !buf || gain <= 0) return -1;
  const now = ctx!.currentTime;
  let best = -1, bs = Infinity;
  for (let k = 0; k < NV; k++) {                    // a free voice, else steal the quietest / most finished one-shot
    const v = voices[k];
    if (!v.src) { best = k; break; }
    if (v.loop) continue;
    const sc = v.gain * Math.max(0, 1 - (now - v.t0) / v.dur);
    if (sc < bs) { bs = sc; best = k; }
  }
  if (best < 0) return -1;
  const v = voices[best];
  if (v.src) { v.src.onended = null; v.src.stop(); v.src.disconnect(); }
  const src = ctx!.createBufferSource(), rate = Math.min(8, Math.max(0.05, pitch));
  src.buffer = buf; src.loop = loop; src.playbackRate.value = rate;
  src.connect(v.g);
  v.g.gain.cancelScheduledValues(now); v.g.gain.setValueAtTime(gain, now);
  v.pan.pan.value = Math.max(-1, Math.min(1, pan));
  if (v.bus !== bus) { v.pan.disconnect(); v.pan.connect(bus); v.bus = bus; }
  src.onended = () => { if (v.src === src) { v.src = null; src.disconnect(); } };
  src.start(now); plays++;
  Object.assign(v, { src, gain, t0: now, dur: buf.duration / rate, loop, id: (++serial & 0xfffff) * 32 + best });
  return v.id;
}
/** au_stop: fade voice ID out over FADE seconds (a stale id does nothing). */
function stop(id: number, fade = 0.15): void {
  if (!alive(id)) return;
  const v = voices[id & 31], now = ctx!.currentTime;
  v.g.gain.cancelScheduledValues(now); v.g.gain.setValueAtTime(v.g.gain.value, now); v.g.gain.linearRampToValueAtTime(0, now + fade);
  v.src!.stop(now + fade + 0.02);
  v.loop = false; v.gain = 0;                        // (stealable now)
}

// ---------------------------------------------------------------- the play API (audio.lisp)
/** PLAY-SFX: KEY once, not positional, its pitch varied by +-5 %. */
export function sfx(key: string, gain = 1, pitch = 1, pan = 0): number {
  return play(key, gain, pan, pitch * (1 + 0.05 * (2 * Math.random() - 1)), false, sfxBus);
}
/** The menus' click (flow.lisp: :select / :confirm / :back). */
export const uiSfx = (key: 'select' | 'confirm' | 'back'): void => { sfx(key); };

type V3 = { x: number; y: number; z: number };
let listener: { position: V3; getTarget(): V3 } | null = null;
/** The camera that hears the world (SFX-AT's listener). */
export function setListener(cam: { position: V3; getTarget(): V3 }): void { listener = cam; }
/** SFX-AT: KEY from world point (X Y Z) as heard from the camera: gain / (1 + d/8), panned by the camera's right. */
export function sfxAt(key: string, x: number, _y: number, z: number, gain = 1, pitch = 1): number {
  if (!listener) return sfx(key, gain, pitch);
  const c = listener.position, t = listener.getTarget();
  const dx = x - c.x, dz = z - c.z, d = Math.hypot(dx, dz), fx = t.x - c.x, fz = t.z - c.z, fl = Math.hypot(fx, fz);
  const pan = d < 0.01 || fl < 1e-6 ? 0 : (0.8 * (dz * fx - dx * fz)) / (d * fl);
  return sfx(key, gain / (1 + d / 8), pitch, pan);
}

// music: one loop on the music bus at a time (flow.lisp PLAY-MUSIC: nothing if KEY is already playing)
let musicKey: string | null = null, musicId = -1;
function music(key: string | null, fade: number): void {
  if (key === musicKey && (key === null || alive(musicId))) return;
  stop(musicId, fade); musicId = -1; musicKey = null;
  if (key) { musicId = play(key, 1, 0, 1, true, musicBus); if (musicId >= 0) musicKey = key; }
}

// volumes: SETTINGS SOUND = the master (OFF mutes), MUSIC = the music bus; a cinematic's SILENCE beat takes the music to a
// tenth and mutes the sfx bus (cinema.lisp SILENCE)
let silent = false;
function volumes(): void {
  if (!ctx) return;
  const t = ctx.currentTime, set = (p: AudioParam, v: number) => p.setTargetAtTime(v, t, 0.015);
  set(master.gain, +settingValue('sound'));
  set(musicBus.gain, MUSIC_VOL * +settingValue('music') * (silent ? 0.1 : 1));
  set(sfxBus.gain, silent ? 0 : 1);
}
onSettings(volumes);

// ---------------------------------------------------------------- the game's hooks (main.ts)
const hums: [number, number] = [-1, -1];
const sink: Sink = {
  play: (key, gain, pitch, x, y, z) => { if (Number.isNaN(x)) sfx(key, gain, pitch); else sfxAt(key, x, y, z, gain, pitch); },
  hum: (side, on) => { stop(hums[side], 0.1); hums[side] = on ? play('breaker-hum', 0.7, 0, 1, true, sfxBus) : -1; },
};
/** FEEDBACK-SYSTEM's sounds for this frame's sim events. */
export function audioEvents(ev: SimEvent[], w: World): void { for (const e of ev) feedback(e, w, sink); }

let world: World | null = null, cine: Cine | null = null, cueCf = -1, silenceEnd = -1;
function silence(on: boolean): void { if (silent !== on) { silent = on; volumes(); } }
/** Once a frame: the music of SCREEN, the running cinematic's beats (CUES by its frame) and the hums' cleanup. */
export function audioFrame(screen: string, w: World | null): void {
  music(screen === 'battle' ? 'music' : screen === 'results' || screen === 'clear' ? null : 'music-title',
        screen === 'results' || screen === 'clear' ? 1.0 : screen === 'battle' ? 0.2 : 0.3);
  if (w !== world || screen !== 'battle') { world = screen === 'battle' ? w : null; sink.hum(0, false); sink.hum(1, false); }
  const c = world?.cine ?? null;
  if (c !== cine) { cine = c; cueCf = -1; silenceEnd = -1; silence(false); }
  if (!c) return;
  for (const [f, key, pitch, gain] of CUES[c.name] ?? []) {
    if (f <= cueCf || f > c.cf) continue;
    if (key) sfx(key, gain ?? 1, pitch ?? 1);
    else { silenceEnd = Math.max(silenceEnd, f + (pitch ?? 0)); silence(true); }   // [f, '', frames]
  }
  cueCf = c.cf;
  if (silenceEnd >= 0 && c.cf >= silenceEnd) { silenceEnd = -1; silence(false); }
}

// ---------------------------------------------------------------- start-up
if (typeof window !== 'undefined') {
  renderBank();
  for (const k of ['pointerdown', 'keydown', 'touchend']) addEventListener(k, unlock, true);
  document.addEventListener('visibilitychange', () => {
    if (!ctx) return;
    if (document.hidden) void ctx.suspend(); else if (unlocked) void ctx.resume();
  });
  // debug / harness: window.duelAudio.check() -> per sound peak / RMS of the bank and of an OfflineAudioContext render
  // through the voice -> bus -> master -> limiter chain
  Object.assign(window, { duelAudio: { bank, sfx, check, get ctx() { return ctx; }, voices: () => voices.filter((v) => v.src).length, plays: () => plays } });
}

async function check(): Promise<string[]> {
  for (let i = 0; i < 600 && bank.size < BANK_ORDER.length; i++) await new Promise((r) => setTimeout(r, 50));
  const out: string[] = [];
  for (const key of BANK_ORDER) {
    const b = bank.get(key);
    if (!b) { out.push(`${key} MISSING`); continue; }
    const oc = new OfflineAudioContext(2, b.length, RATE), src = oc.createBufferSource(), lim = limiter(oc), pan = oc.createStereoPanner();
    src.buffer = b; src.connect(pan); pan.connect(lim[0]); lim[1].connect(oc.destination); src.start();
    const r = await oc.startRendering();
    const st = (d: Float32Array) => { let p = 0, q = 0; for (const x of d) { p = Math.max(p, Math.abs(x)); q += x * x; } return [p, Math.sqrt(q / d.length)]; };
    const [p0, r0] = st(b.getChannelData(0)), [p1, r1] = st(r.getChannelData(0));
    out.push(`${key.padEnd(16)} ${(b.duration * 1000).toFixed(0).padStart(5)} ms  bank peak ${p0.toFixed(3)} rms ${r0.toFixed(3)}  out peak ${p1.toFixed(3)} rms ${r1.toFixed(3)}${p0 < 0.05 || r0 < 0.005 || p1 > 1 ? '  <-- BAD' : ''}`);
  }
  return out;
}
