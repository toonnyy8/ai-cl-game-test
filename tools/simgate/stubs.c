/* stubs.c — the engine's C layer for the host-native sim gate (tools/simgate.py, docs/duel/DUEL_GAMEPLAY.md "Pacing gate").
   Included into the natively compiled Lisp unit by tools/simgate/build.lisp. Every function engine/c/engine.h
   declares is here: the random streams are the real ones (engine/c/rng.c), the rest are headless leaves: no window,
   no GPU, no audio device (AUDIO-INIT-BEGIN fails, so no sound is synthesized), no page. Time is virtual: each
   pf_pump advances it by one 1/60 s frame, like tools/run.mjs --fixed-dt 16.666667. */
#include "engine/c/engine.h"
#include "engine/c/rng.c"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

unsigned au_rng = 0x9E3779B9u;

static long long sg_frame = 0;                          /* frames pumped so far */
static double sg_now_ms(void) { return sg_frame * (50.0 / 3.0); }
double emscripten_get_now(void) { return sg_now_ms(); }
Uint64 SDL_GetTicks(void) { return (Uint64)sg_now_ms(); }

/* the debug queue (engine/c/main.c's): SIMGATE-CMD pushes, RUN-FRAME takes at the start of the next frame */
static int sg_cmds[64], sg_n = 0;
void debug_cmd(int c) { if (sg_n < 64) sg_cmds[sg_n++] = c; }
int debug_take_cmd(void) {
  int c = 0, i;
  if (sg_n > 0) { c = sg_cmds[0]; for (i = 1; i < sg_n; i++) sg_cmds[i-1] = sg_cmds[i]; sg_n--; }
  return c;
}
void engine_loading(int pct) { (void)pct; }
void engine_fatal(const char *msg) { fprintf(stderr, "simgate fatal: %s\n", msg); exit(3); }

/* platform.c: a 1280x720 desktop window with no input */
int pf_init(const char *title, int w, int h) { (void)title; (void)w; (void)h; return 1; }
int pf_pump(float *f, float maxdt, int lock) {
  Uint64 prev = (Uint64)(sg_now_ms() * 1e6), now;
  float raw;
  (void)lock;
  sg_frame++;
  now = (Uint64)(sg_now_ms() * 1e6);
  raw = (now - prev) * 1e-9f;
  memset(f, 0, 9 * sizeof(float));
  f[11] = raw; f[9] = raw > maxdt ? maxdt : raw; f[10] = now * 1e-9f;
  f[12] = f[12] <= 0 ? 1.0f / raw : f[12] * 0.95f + 0.05f / raw;
  return 1;
}
SDL_Window *pf_window(void) { return 0; }
int pf_width(void) { return 1280; }
int pf_height(void) { return 720; }
int pf_focus_lost(void) { return 0; }
float pf_density(void) { return 1.0f; }
int pf_touch_copy(float *out, int max) { (void)out; (void)max; return 0; }
int pf_page_get(int k) { (void)k; return 0; }           /* a desktop page with nothing saved */
void pf_page_set(int k, int v) { (void)k; (void)v; }
int pf_locked(void) { return 0; }
int pf_key_down(int s) { (void)s; return 0; }
int pf_key_pressed(int s) { (void)s; return 0; }
int pf_mouse_down(int b) { (void)b; return 0; }
int pf_mouse_pressed(int b) { (void)b; return 0; }
int pf_pad_count(void) { return 0; }
int pf_pad_connected(int p) { (void)p; return 0; }
int pf_pad_down(int p, int b) { (void)p; (void)b; return 0; }
int pf_pad_pressed(int p, int b) { (void)p; (void)b; return 0; }
float pf_pad_axis(int p, int a) { (void)p; (void)a; return 0.0f; }

/* render.c: meshes get ids, frames draw nothing */
static int sg_meshes = 0;
int r_init(int msaa) { (void)msaa; return 1; }
int r_make_pipe(int slot, const char *vs, const char *ve, const char *fs, const char *fe, int layout, int target, int depth,
                int blend, int cull) {
  (void)slot; (void)vs; (void)ve; (void)fs; (void)fe; (void)layout; (void)target; (void)depth; (void)blend; (void)cull;
  return 1;
}
int r_mesh_new(const float *v, int n) { (void)v; (void)n; return sg_meshes++; }
int r_font_new(const unsigned char *px, int w, int h) { (void)px; (void)w; (void)h; return 1; }
int r_frame(const float *fu, const float *rp, const float *dq, int n, const float *fxa, int nfa, const float *fxb, int nfb,
            const float *ui, int nui, const float *fxt, int nft) {
  (void)fu; (void)rp; (void)dq; (void)n; (void)fxa; (void)nfa; (void)fxb; (void)nfb; (void)ui; (void)nui; (void)fxt; (void)nft;
  return 0;
}
int r_sample_count(void) { return 1; }
int r_tri_count(void) { return 0; }
int r_timing(int a, float b, float s, int l, int d, int t, float sc, int p) {
  (void)a; (void)b; (void)s; (void)l; (void)d; (void)t; (void)sc; (void)p;
  return 0;
}

/* audio.c: no device */
int au_open(void) { return 0; }
void au_resume(void) {}
void au_load(int slot, const float *src, int n) { (void)slot; (void)src; (void)n; }
int au_play(int slot, float gain, float pan, float pitch, int loop, int bus) {
  (void)slot; (void)gain; (void)pan; (void)pitch; (void)loop; (void)bus;
  return -1;
}
void au_stop(int id, int fade) { (void)id; (void)fade; }
int au_alive(int id) { (void)id; return 0; }
void au_gain(int id, float g) { (void)id; (void)g; }
void au_set_volume(int bus, float v) { (void)bus; (void)v; }
int au_active(void) { return 0; }
int au_frames_mixed(void) { return 0; }
float au_take_peak(void) { return 0.0f; }
int au_ctx_state(void) { return 0; }
