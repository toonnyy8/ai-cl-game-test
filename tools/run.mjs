// Headless test driver (no deps; Node >= 22 for global WebSocket).
//   node tools/run.mjs dist/NAME [--secs N] [--shot out.png] [--script steps.json] [--size 1280x720]
// Serves the dist dir, runs it in headless Chrome (SwiftShader WebGPU), streams console
// output to stdout, optionally replays scripted input and saves a screenshot at the end.
// steps.json: [{"at":1.0,"key":"KeyJ","down":true}, {"at":1.1,"key":"KeyJ","down":false},
//              {"at":2,"shot":"mid.png"}, {"at":2.5,"eval":"Module._foo()"}, {"at":3,"size":"800x450"} ...]
// --fixed-dt MS: virtual clock (deterministic frames and frozen stills). performance.now / Date.now read a
//   clock that advances exactly MS per animation frame; "at" and --secs are then VIRTUAL seconds: before each
//   step the page is held at that time (no frame runs), the step is applied, then it resumes. The same binary
//   and script give byte-identical screenshots; --timeout SEC (default 900) bounds the wall time.
// Exit code 1 on JS exceptions and on WebGPU validation errors / failed pipelines (the WGSL smoke test).
import http from 'node:http'; import fs from 'node:fs'; import path from 'node:path';
import { spawn } from 'node:child_process';

const a = process.argv.slice(2), dir = path.resolve(a[0] || 'dist/game');
const opt = (k, d) => { const i = a.indexOf(k); return i >= 0 ? a[i + 1] : d; };
const secs = +opt('--secs', 8), shot = opt('--shot'), script = opt('--script');
const fixed = opt('--fixed-dt') ? +opt('--fixed-dt') : 0, wallMax = +opt('--timeout', 900);
const [W, H] = opt('--size', '1280x720').split('x').map(Number);
const steps = script ? JSON.parse(fs.readFileSync(script, 'utf8')).sort((x, y) => x.at - y.at) : [];
const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.data': 'application/octet-stream' };

const srv = http.createServer((q, r) => {
  const f = path.join(dir, decodeURIComponent(q.url.split('?')[0]).replace(/^\/$/, '/index.html'));
  fs.readFile(f, (e, b) => { if (e) { r.writeHead(404); r.end(); } else { r.writeHead(200, { 'content-type': types[path.extname(f)] || 'application/octet-stream' }); r.end(b); } });
}).listen(0);
const port = srv.address().port;
const udd = fs.mkdtempSync('/tmp/claude-1000/chrome-');
const chrome = spawn(process.env.CHROME_BIN || 'google-chrome', ['--headless=new', '--no-sandbox', '--remote-debugging-port=0',   // Chrome picks a free port (DevToolsActivePort): parallel runs never share one
  `--user-data-dir=${udd}`, ...(process.env.CHROME_FLAGS ? process.env.CHROME_FLAGS.split(' ') : '--enable-unsafe-webgpu --enable-features=Vulkan --use-vulkan=swiftshader --use-webgpu-adapter=swiftshader --use-angle=vulkan --enable-unsafe-swiftshader'.split(' ')), '--autoplay-policy=no-user-gesture-required',
  `--window-size=${W},${H}`, ...(process.env.CHROME_LOG ? ['--enable-logging=stderr', '--v=0'] : []), 'about:blank'], { stdio: ['ignore', 'ignore', process.env.CHROME_LOG ? 'inherit' : 'ignore'] });

const sleep = ms => new Promise(r => setTimeout(r, ms));
let ws, id = 0; const pending = new Map();
const send = (method, params = {}) => new Promise(res => { const i = ++id; pending.set(i, res); ws.send(JSON.stringify({ id: i, method, params })); });
const done = code => { chrome.once('exit', () => { spawn('sh', ['-c', `sleep 3; rm -rf '${udd}'`], { detached: true, stdio: 'ignore' }).unref(); process.exit(code); }); chrome.kill('SIGKILL'); srv.close(); };
for (const sig of ['SIGINT', 'SIGTERM']) process.on(sig, () => done(130));   // e.g. `timeout` — never orphan Chrome
let failed = false;

for (let i = 0; ; i++) {
  try { const dport = fs.readFileSync(`${udd}/DevToolsActivePort`, 'utf8').split('\n')[0]; const t = await (await fetch(`http://127.0.0.1:${dport}/json`)).json(); const p = t.find(x => x.type === 'page'); if (p) { ws = new WebSocket(p.webSocketDebuggerUrl); break; } } catch {}
  if (i > 100) { console.error('chrome did not start'); done(2); } await sleep(100);
}
await new Promise(r => ws.onopen = r);
ws.onmessage = m => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result ?? d.error); pending.delete(d.id); return; }
  const gpuErr = t => /WebGPU:|render: pipeline .* failed/.test(t) && (failed = true);
  if (d.method === 'Runtime.consoleAPICalled') { const t = d.params.args.map(x => x.value ?? x.description).join(' '); console.log(t); gpuErr(t);
    if (t.startsWith('startup: heap')) console.log(`[run] startup done ${wall().toFixed(2)} s after navigation`); }
  if (d.method === 'Log.entryAdded' && d.params.entry.level !== 'verbose') { console.log(`[browser ${d.params.entry.level}]`, d.params.entry.text); gpuErr(d.params.entry.text); }
  if (d.method === 'Runtime.exceptionThrown') { failed = true; console.log('EXCEPTION:', d.params.exceptionDetails.exception?.description || d.params.exceptionDetails.text); }
};
await send('Runtime.enable'); await send('Page.enable'); await send('Log.enable');
await send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
await send('Emulation.setFocusEmulationEnabled', { enabled: true });   // parallel headless runs must not lose focus (the games pause)
// virtual clock: rAF callbacks advance it by DT; __hold(t) stops it at t (the frame loop idles, nothing is drawn)
if (fixed) await send('Page.addScriptToEvaluateOnNewDocument', { source: `(() => {
  const DT = ${fixed}, raf = window.requestAnimationFrame.bind(window), d0 = 1.75e12; let vt = 0, hold = 0, last = -1, idle = 0, held = true, busy = false;
  performance.now = () => vt; Date.now = () => d0 + Math.round(vt);
  window.__settle = async () => {   // the GPU finished every submitted frame, then 2 more browser frames
    const d = window.Module && Module.preinitializedWebGPUDevice; if (d) await d.queue.onSubmittedWorkDone();
    for (let i = 0; i < 2; i++) await new Promise(r => raf(r));
  };
  window.__vt = () => vt; window.__hold = t => { if (t * 1000 !== hold) idle = 0; hold = t * 1000; return vt + DT > hold + 1e-6 && idle >= 3; };
  window.requestAnimationFrame = cb => raf(function tick(ts) {   // one step per browser frame, shared by every rAF user
    // a frame waits until the GPU finished the previous one: SDL skips drawing a frame whose swapchain
    // texture is not ready, and the canvas would then show an older frame than the state
    if (ts !== last) { last = ts; held = busy || vt + DT > hold + 1e-6; if (held) idle += !busy; else vt += DT; }
    if (held) { raf(tick); return; }
    cb(vt);
    const d = window.Module && Module.preinitializedWebGPUDevice;
    if (d && !busy) { busy = true; d.queue.onSubmittedWorkDone().then(() => { busy = false; }); }
  });
})();` });
await send('Page.navigate', { url: `http://127.0.0.1:${port}/index.html` });
const t0 = Date.now(), wall = () => (Date.now() - t0) / 1000;
const vnow = async () => (await send('Runtime.evaluate', { expression: 'window.__vt ? __vt() / 1000 : -1', returnByValue: true })).result?.value ?? -1;
const held = async t => (await send('Runtime.evaluate', { expression: `!!window.__hold && __hold(${t})`, returnByValue: true })).result?.value;
const waitUntil = async t => {       // wall mode: sleep; fixed mode: hold the page at virtual time T and wait for it
  if (!fixed) { while (wall() < t) await sleep(10); return; }
  while (!await held(t)) {           // (re)sent every poll: the first ones may hit about:blank
    if (wall() > wallMax) { console.log(`[run] TIMEOUT at virtual ${(await vnow()).toFixed(2)} s`); failed = true; return; }
    await sleep(20);
  }
  await send('Runtime.evaluate', { expression: '__settle()', awaitPromise: true });
};
const save = async f => { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(f, Buffer.from(r.data, 'base64')); console.log(`[run] screenshot ${f} @${(fixed ? await vnow() : wall()).toFixed(fixed ? 3 : 1)}s${fixed ? ' (virtual)' : ''}`); };
// numpad: code Numpad0..9 / NumpadEnter / NumpadAdd ... with the numpad virtual key codes and location 3
const numpad = { ...Object.fromEntries([...'0123456789'].map((d, i) => ['Numpad' + d, 96 + i])), NumpadEnter: 13, NumpadAdd: 107,
  NumpadSubtract: 109, NumpadMultiply: 106, NumpadDivide: 111, NumpadDecimal: 110 };
const keyEv = (key, down) => send('Input.dispatchKeyEvent', { type: down ? 'keyDown' : 'keyUp', code: key, key: key.replace(/^Key/, '').toLowerCase(), windowsVirtualKeyCode: key.startsWith('Key') ? key.charCodeAt(3) : ({ Space: 32, ShiftLeft: 16, Enter: 13, Escape: 27, Tab: 9, ArrowLeft: 37, ArrowUp: 38, ArrowRight: 39, ArrowDown: 40, ...numpad }[key] || 0), ...(key in numpad ? { location: 3 } : {}) });
for (const s of steps) {
  await waitUntil(s.at);
  if (s.key) await keyEv(s.key, s.down !== false);
  if (s.mouse) await send('Input.dispatchMouseEvent', { type: s.mouse, x: s.x ?? W / 2, y: s.y ?? H / 2, button: s.button || 'left', clickCount: 1 });
  if (s.size) { const [w, h] = s.size.split('x').map(Number); await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false }); }
  if (s.eval) { const r = await send('Runtime.evaluate', { expression: s.eval, returnByValue: true }); console.log('[eval]', JSON.stringify(r.result?.value)); }
  if (s.shot) await save(s.shot);
}
await waitUntil(secs);
if (shot) await save(shot);
const fps = await send('Runtime.evaluate', { expression: 'document.getElementById("status")?.textContent', returnByValue: true });
if (fps.result?.value) console.log('[run] status:', fps.result.value);
done(failed ? 1 : 0);
