/* platform.c — window, input and frame timing on SDL3 (the GPU device lives in render.c).
   Lisp side: engine/lisp/platform.lisp. All input state lives here; queries never cons. */
#include "engine/c/engine.h"
#include <stdio.h>
#include <emscripten/html5.h>

#define PF_NBTN 18   /* SDL gamepad buttons 0..14, 15 unused, 16 = LT, 17 = RT (as buttons) */
static SDL_Window *pf_win; static SDL_Gamepad *pf_pad;
static unsigned char pf_key[SDL_SCANCODE_COUNT], pf_kdown[SDL_SCANCODE_COUNT];
static unsigned char pf_mb[8], pf_mdown[8];
static unsigned char pf_pb[PF_NBTN], pf_pprev[PF_NBTN];
static int pf_w = 1, pf_h = 1, pf_flost = 0;
static Uint64 pf_tprev, pf_t0;
static float pf_dz(float v, float dz) { float a = v < 0 ? -v : v; if (a < dz) return 0; a = (a - dz) / (1 - dz); if (a > 1) a = 1; return v < 0 ? -a : a; }
static void pf_stick(float *out, SDL_GamepadAxis ax, SDL_GamepadAxis ay, float dz) {
  float x = SDL_GetGamepadAxis(pf_pad, ax) / 32767.0f, y = SDL_GetGamepadAxis(pf_pad, ay) / 32767.0f;
  float m = SDL_sqrtf(x*x + y*y);
  if (m < dz) { out[0] = out[1] = 0; return; }
  float s = (m > 1 ? 1 : (m - dz) / (1 - dz)) / m;
  out[0] = x * s; out[1] = -y * s;   /* +Y = stick up */
}
int pf_init(const char *title, int w, int h) {
  if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD)) { printf("SDL_Init: %s\n", SDL_GetError()); return 0; }
  pf_win = SDL_CreateWindow(title, w, h, SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY);
  if (!pf_win) { printf("SDL_CreateWindow: %s\n", SDL_GetError()); return 0; }
  SDL_GetWindowSizeInPixels(pf_win, &pf_w, &pf_h);
  pf_t0 = pf_tprev = SDL_GetTicksNS();
  printf("platform: %dx%d px (density %.2f)\n", pf_w, pf_h, SDL_GetWindowPixelDensity(pf_win));
  return 1;
}
/* f: [0 dx 1 dy 2 wheel 3 lx 4 ly 5 rx 6 ry 7 lt 8 rt 9 dt 10 time 11 raw-dt 12 fps] */
int pf_pump(float *f, float maxdt) {
  SDL_Event e; int run = 1;
  memset(pf_kdown, 0, sizeof pf_kdown); memset(pf_mdown, 0, sizeof pf_mdown);
  f[0] = f[1] = f[2] = 0; pf_flost = 0;
  while (SDL_PollEvent(&e)) switch (e.type) {
    case SDL_EVENT_QUIT: run = 0; break;
    case SDL_EVENT_KEY_DOWN: if (!e.key.repeat && e.key.scancode < SDL_SCANCODE_COUNT) { pf_key[e.key.scancode] = 1; pf_kdown[e.key.scancode] = 1; } break;
    case SDL_EVENT_KEY_UP: if (e.key.scancode < SDL_SCANCODE_COUNT) pf_key[e.key.scancode] = 0; break;
    case SDL_EVENT_MOUSE_MOTION: f[0] += e.motion.xrel; f[1] += e.motion.yrel; break;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
      if (!pf_locked()) {   /* this click (re)acquires the pointer lock: not an attack */
        SDL_SetWindowRelativeMouseMode(pf_win, false); SDL_SetWindowRelativeMouseMode(pf_win, true);
        break;
      }
      if (e.button.button < 8) { pf_mb[e.button.button] = 1; pf_mdown[e.button.button] = 1; }
      break;
    case SDL_EVENT_MOUSE_BUTTON_UP: if (e.button.button < 8) pf_mb[e.button.button] = 0; break;
    case SDL_EVENT_MOUSE_WHEEL: f[2] += e.wheel.y; break;
    case SDL_EVENT_WINDOW_FOCUS_LOST: case SDL_EVENT_WINDOW_HIDDEN: case SDL_EVENT_WINDOW_MINIMIZED:
      memset(pf_key, 0, sizeof pf_key); memset(pf_mb, 0, sizeof pf_mb); pf_flost = 1; break;
    case SDL_EVENT_GAMEPAD_ADDED: if (!pf_pad) { pf_pad = SDL_OpenGamepad(e.gdevice.which); if (pf_pad) printf("gamepad: %s\n", SDL_GetGamepadName(pf_pad)); } break;
    case SDL_EVENT_GAMEPAD_REMOVED: if (pf_pad && SDL_GetGamepadID(pf_pad) == e.gdevice.which) { SDL_CloseGamepad(pf_pad); pf_pad = 0; } break;
  }
  memcpy(pf_pprev, pf_pb, sizeof pf_pb);
  if (pf_pad) {
    pf_stick(f + 3, SDL_GAMEPAD_AXIS_LEFTX, SDL_GAMEPAD_AXIS_LEFTY, 0.2f);
    pf_stick(f + 5, SDL_GAMEPAD_AXIS_RIGHTX, SDL_GAMEPAD_AXIS_RIGHTY, 0.2f);
    f[7] = pf_dz(SDL_GetGamepadAxis(pf_pad, SDL_GAMEPAD_AXIS_LEFT_TRIGGER) / 32767.0f, 0.05f);
    f[8] = pf_dz(SDL_GetGamepadAxis(pf_pad, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER) / 32767.0f, 0.05f);
    for (int i = 0; i < 15; i++) pf_pb[i] = SDL_GetGamepadButton(pf_pad, (SDL_GamepadButton)i);
    pf_pb[16] = f[7] > 0.5f; pf_pb[17] = f[8] > 0.5f;
  } else { memset(pf_pb, 0, sizeof pf_pb); for (int i = 3; i < 9; i++) f[i] = 0; }
  SDL_GetWindowSizeInPixels(pf_win, &pf_w, &pf_h);
  Uint64 now = SDL_GetTicksNS(); float raw = (now - pf_tprev) * 1e-9f; pf_tprev = now;
  f[11] = raw; f[9] = raw > maxdt ? maxdt : raw; f[10] = (now - pf_t0) * 1e-9f;
  if (raw > 0) f[12] = f[12] <= 0 ? 1.0f / raw : f[12] * 0.95f + 0.05f / raw;
  return run;
}
int pf_locked(void) { EmscriptenPointerlockChangeEvent s; return emscripten_get_pointerlock_status(&s) == EMSCRIPTEN_RESULT_SUCCESS && s.isActive; }

/* Accessors for the Lisp queries (KEY-DOWN, MOUSE-PRESSED, PAD-DOWN, WINDOW-WIDTH ...). */
SDL_Window *pf_window(void) { return pf_win; }
int pf_width(void) { return pf_w; }
int pf_height(void) { return pf_h; }
int pf_focus_lost(void) { return pf_flost; }
int pf_key_down(int sc) { return sc >= 0 && sc < SDL_SCANCODE_COUNT && pf_key[sc]; }
int pf_key_pressed(int sc) { return sc >= 0 && sc < SDL_SCANCODE_COUNT && pf_kdown[sc]; }
int pf_mouse_down(int b) { return b >= 0 && b < 8 && pf_mb[b]; }
int pf_mouse_pressed(int b) { return b >= 0 && b < 8 && pf_mdown[b]; }
int pf_pad_connected(void) { return pf_pad != 0; }
int pf_pad_down(int b) { return b >= 0 && b < PF_NBTN && pf_pb[b]; }
int pf_pad_pressed(int b) { return b >= 0 && b < PF_NBTN && pf_pb[b] && !pf_pprev[b]; }
