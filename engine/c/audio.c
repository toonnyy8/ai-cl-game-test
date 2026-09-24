/* audio.c — the mixer: up to 32 voices over 64 sample slots, fed to an SDL3 audio stream.
   Lisp side (synthesis toolkit, sound bank, play API): engine/lisp/audio.lisp. See docs/AUDIO.md.
   ponytail: the SDL stream *get callback* mixes in pure C. On the web SDL3 calls it from a
   ScriptProcessorNode `onaudioprocess` event, i.e. between frames, never while Lisp runs, and it
   never touches Lisp objects (GC rule). Frame hitches therefore don't starve audio. */
#include "engine/c/engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define AU_RATE 48000
#define AU_NV 32
#define AU_NS 64
#define AU_CHUNK 256
typedef struct { const float *d; int n, loop, bus, id; double pos, step; float g, gl, gr, amp, rel; } au_voice;
static float *au_snd[AU_NS]; static int au_len[AU_NS];
static au_voice au_v[AU_NV];
static SDL_AudioStream *au_stream;
static float au_vol[3] = {1.0f, 1.0f, 0.55f};   /* master, sfx bus, music bus */
static float au_lim = 1.0f, au_peak = 0.0f;
static unsigned au_serial, au_frames;
unsigned au_rng = 0x9E3779B9u;   /* synthesis noise, see au_rand in engine.h */

static void au_mix(float *out, int frames) {
  int i, k;
  memset(out, 0, sizeof(float) * 2 * frames);
  for (k = 0; k < AU_NV; k++) {
    au_voice *v = &au_v[k];
    const float *d = v->d; double pos = v->pos, step = v->step; int n = v->n;
    float gl, gr;
    if (!d) continue;
    gl = v->gl * au_vol[1 + v->bus]; gr = v->gr * au_vol[1 + v->bus];
    for (i = 0; i < frames; i++) {
      int p; float fr, a, b, s;
      if (pos >= n) { if (!v->loop) { d = 0; break; } pos -= n; if (pos >= n) pos = 0; }
      p = (int)pos; fr = (float)(pos - p);
      a = d[p]; b = p + 1 < n ? d[p + 1] : (v->loop ? d[0] : 0.0f);
      s = a + (b - a) * fr;
      if (v->rel > 0.0f) { v->amp -= v->rel; if (v->amp <= 0.0f) { d = 0; break; } s *= v->amp; }
      out[2*i] += s * gl; out[2*i+1] += s * gr;
      pos += step;
    }
    v->pos = pos; v->d = d;
  }
  /* master gain + peak limiter: instant attack to 0.9, ~100 ms release */
  for (i = 0; i < 2 * frames; i += 2) {
    float l = out[i] * au_vol[0], r = out[i+1] * au_vol[0];
    float pk = fmaxf(fabsf(l), fabsf(r)) * au_lim;
    if (pk > 0.9f) au_lim *= 0.9f / pk; else au_lim += (1.0f - au_lim) * 0.0002f;
    out[i] = l * au_lim; out[i+1] = r * au_lim;
    au_peak = fmaxf(au_peak, fminf(pk, 0.9f));
  }
  au_frames += frames;
}

static void SDLCALL au_cb(void *ud, SDL_AudioStream *s, int add, int total) {
  float buf[AU_CHUNK * 2];
  int frames = (add + 7) / 8;
  (void)ud; (void)total;
  while (frames > 0) {
    int f = frames < AU_CHUNK ? frames : AU_CHUNK;
    au_mix(buf, f); SDL_PutAudioStreamData(s, buf, f * 8); frames -= f;
  }
}

int au_play(int s, float gain, float pan, float pitch, int loop, int bus) {
  int k, best = -1; float bs = 1e30f;
  if (!au_stream || s < 0 || s >= AU_NS || !au_snd[s] || gain <= 0.0f) return -1;
  SDL_LockAudioStream(au_stream);
  for (k = 0; k < AU_NV; k++) {   /* free slot, else steal quietest/most-finished one-shot */
    float sc;
    if (!au_v[k].d) { best = k; break; }
    if (au_v[k].loop) continue;
    sc = au_v[k].g * au_v[k].amp * (float)(1.0 - au_v[k].pos / au_v[k].n);
    if (sc < bs) { bs = sc; best = k; }
  }
  if (best >= 0) {
    au_voice *v = &au_v[best];
    pan = pan < -1.0f ? -1.0f : pan > 1.0f ? 1.0f : pan;
    v->d = au_snd[s]; v->n = au_len[s]; v->pos = 0.0;
    v->step = pitch < 0.05f ? 0.05f : pitch > 8.0f ? 8.0f : pitch;
    v->loop = loop; v->bus = bus; v->g = gain; v->amp = 1.0f; v->rel = 0.0f;
    v->gl = gain * (pan > 0.0f ? 1.0f - pan : 1.0f);
    v->gr = gain * (pan < 0.0f ? 1.0f + pan : 1.0f);
    v->id = (int)((++au_serial & 0xFFFFFu) << 5) | best;
    best = v->id;
  }
  SDL_UnlockAudioStream(au_stream);
  return best;
}

void au_stop(int id, int fade) {   /* fade out over FADE frames */
  if (!au_stream || id < 0) return;
  SDL_LockAudioStream(au_stream);
  if (au_v[id & 31].d && au_v[id & 31].id == id) au_v[id & 31].rel = 1.0f / (fade > 0 ? fade : 1);
  SDL_UnlockAudioStream(au_stream);
}

int au_alive(int id) { return id >= 0 && au_v[id & 31].d && au_v[id & 31].id == id; }
void au_gain(int id, float g) {   /* re-gain a running (centre-panned) voice, e.g. the rain loop */
  if (!au_stream || !au_alive(id)) return;
  SDL_LockAudioStream(au_stream);
  au_v[id & 31].g = au_v[id & 31].gl = au_v[id & 31].gr = g;
  SDL_UnlockAudioStream(au_stream);
}
int au_active(void) { int k, c = 0; for (k = 0; k < AU_NV; k++) c += au_v[k].d != 0; return c; }

void au_load(int s, const float *src, int n) {
  float *d = (float *)malloc(sizeof(float) * n);
  if (!d) return;
  memcpy(d, src, sizeof(float) * n);
  au_snd[s] = d; au_len[s] = n;
}

/* EM_JS, not EM_ASM: EM_ASM inlined into a setjmp-using (handler-case) Lisp
   function is a clang backend error. EM_JS functions are imports, never inlined. */
#ifdef __EMSCRIPTEN__
EM_JS(int, au_js_ctx_state, (void), {   /* 0 none, 1 suspended, 2 running */
  var S = Module['SDL3']; if (!S || !S.audioContext) return 0;
  return S.audioContext.state === 'running' ? 2 : 1;
});
/* Autoplay policy: resume the AudioContext from inside a real user-gesture
   handler (SDL itself only retries from a timer once userActivation is set). */
EM_JS(void, au_install_unlock, (void), {
  ['keydown', 'pointerdown', 'touchend'].forEach(function (ev) {
    window.addEventListener(ev, function () { var S = Module['SDL3']; if (S && S.audioContext && S.audioContext.state !== 'running') S.audioContext.resume(); }, true);
  });
});
#else
static int au_js_ctx_state(void) { return au_stream ? 2 : 0; }
static void au_install_unlock(void) {}
#endif

int au_open(void) {
  SDL_AudioSpec sp;
  if (au_stream) return 1;
  if (!SDL_InitSubSystem(SDL_INIT_AUDIO)) { printf("audio: SDL audio init failed: %s\n", SDL_GetError()); return 0; }
  sp.format = SDL_AUDIO_F32; sp.channels = 2; sp.freq = AU_RATE;
  au_stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &sp, au_cb, NULL);
  if (!au_stream) { printf("audio: no playback device: %s\n", SDL_GetError()); return 0; }
  au_install_unlock();
  return 1;
}

int au_ctx_state(void) { return au_js_ctx_state(); }   /* 0 no context, 1 suspended (autoplay), 2 running */
void au_resume(void) { SDL_ResumeAudioStreamDevice(au_stream); }
void au_set_volume(int bus, float v) { if (bus >= 0 && bus < 3) au_vol[bus] = v; }   /* 0 master, 1 sfx, 2 music */
int au_frames_mixed(void) { return (int)au_frames; }
float au_take_peak(void) { float p = au_peak; au_peak = 0.0f; return p; }   /* peak since the last call */
