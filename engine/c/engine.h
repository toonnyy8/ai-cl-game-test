/* engine.h — every C function the engine's Lisp code calls, in one header.
   The Lisp side includes it once for the whole compilation unit (engine/lisp/platform.lisp:
   (ffi:clines "#include \"engine/c/engine.h\"")) and calls these through thin FFI:C-INLINE forms.
   Paths are relative to the project root (the build passes -I<root>).

   GC rule (docs/engine/ARCHITECTURE.md): C code never keeps a pointer to a Lisp object. Lisp passes
   arrays in (->vector.self.sf / .b8) for the duration of one call only. */
#ifndef ENGINE_H
#define ENGINE_H

#include <SDL3/SDL.h>
#include <math.h>        /* IWYU pragma: keep — for the Lisp side's c-inline float math (fminf, sqrtf ...) */
#include <emscripten.h>

/* ---------------------------------------------------------------- random numbers
   xorshift32 generators, inline because they run in particle / synthesis loops.
   rng_float: fx / cosmetic randomness (RND01 in Lisp), state in rng.c.
   rng2_float: the simulation stream (SIM-RND01), state in rng.c; seeded by SIM-RND-SEED.
   au_rand: synthesis noise (AU-RND in Lisp), state in audio.c. */
extern unsigned rng_state, rng2_state, au_rng;
static inline float rng_float(void) {   /* uniform [0,1) */
  rng_state ^= rng_state << 13; rng_state ^= rng_state >> 17; rng_state ^= rng_state << 5;
  return (float)(rng_state >> 8) * (1.0f / 16777216.0f);
}
static inline float rng2_float(void) {  /* uniform [0,1), the simulation stream */
  rng2_state ^= rng2_state << 13; rng2_state ^= rng2_state >> 17; rng2_state ^= rng2_state << 5;
  return (float)(rng2_state >> 8) * (1.0f / 16777216.0f);
}
void rng_seed(unsigned *state, int seed);   /* rng.c: &rng_state or &rng2_state */
static inline float au_rand(void) {     /* uniform [-1,1) */
  au_rng ^= au_rng << 13; au_rng ^= au_rng >> 17; au_rng ^= au_rng << 5;
  return (float)(int)au_rng * 4.656612873e-10f;
}

/* ---------------------------------------------------------------- platform.c (window, input, time) */
int pf_init(const char *title, int w, int h);
int pf_pump(float *f, float maxdt, int lock);   /* events + timing into f[13], see PLATFORM-POLL; LOCK = *POINTER-LOCK* */
SDL_Window *pf_window(void);
int pf_width(void);                          /* window size in pixels */
int pf_height(void);
int pf_focus_lost(void);                     /* 1 for the frame in which focus was lost */
float pf_density(void);                      /* window pixels per CSS pixel (device pixel ratio) */
int pf_touch_copy(float *out, int max);      /* this frame's finger events, 5 floats each (touch.lisp) */
int pf_page_get(int k);                      /* page services (globalThis.gamePage), 0 without one */
void pf_page_set(int k, int v);
int pf_locked(void);                         /* pointer lock active */
int pf_key_down(int scancode);
int pf_key_pressed(int scancode);            /* went down this frame */
int pf_mouse_down(int button);
int pf_mouse_pressed(int button);
int pf_pad_count(void);                      /* open pads (up to 4, stable slots 0..3) */
int pf_pad_connected(int pad);
int pf_pad_down(int pad, int button);        /* SDL gamepad button, 16 = LT, 17 = RT */
int pf_pad_pressed(int pad, int button);
float pf_pad_axis(int pad, int axis);        /* 0 lx 1 ly 2 rx 3 ry 4 lt 5 rt */

/* ---------------------------------------------------------------- render.c (SDL_GPU) */
int r_init(int msaa);
int r_make_pipe(int slot, const char *vsrc, const char *ventry, const char *fsrc, const char *fentry,
                int layout, int target, int depth, int blend, int cull);
int r_mesh_new(const float *v, int n);       /* returns the mesh id, -1 when out of buffers */
int r_font_new(const unsigned char *px, int w, int h);
int r_frame(const float *fu, const float *rp, const float *dq, int n,
            const float *fxa, int nfa, const float *fxb, int nfb, const float *ui, int nui, const float *fxt, int nft);
int r_sample_count(void);                    /* scene MSAA samples in use (1 or 4) */
int r_tri_count(void);
int r_timing(int autoscale, float budget, float smin, int log, int draws, int tris, float scale, int plights);

/* ---------------------------------------------------------------- audio.c (mixer) */
int au_open(void);
void au_resume(void);
void au_load(int slot, const float *src, int n);
int au_play(int slot, float gain, float pan, float pitch, int loop, int bus);   /* voice id or -1 */
void au_stop(int id, int fade);
int au_alive(int id);
void au_gain(int id, float g);
void au_set_volume(int bus, float v);        /* 0 master, 1 sfx bus, 2 music bus */
int au_active(void);
int au_frames_mixed(void);
float au_take_peak(void);
int au_ctx_state(void);

/* ---------------------------------------------------------------- main.c (page hooks, debug queue) */
void engine_loading(int pct);                /* Module.engineLoading(pct) on the page */
void engine_fatal(const char *msg);          /* Module.engineFatal(msg): the error overlay */
int debug_take_cmd(void);                    /* next Module._debug_cmd(n) value, 0 = none */

#endif
