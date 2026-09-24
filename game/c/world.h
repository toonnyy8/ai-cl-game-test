/* world.h — RAVEN EDGE's C scenery helpers (game/c/world.c), called from game/lisp/world.lisp.
   The fx writers append vertices (9 floats: pos, uv, rgba) to an engine fx batch D at float offset F
   (capacity CAP) and return the new offset; P is the per-frame parameter block (see W-FX). */
#ifndef WORLD_H
#define WORLD_H

#include <math.h>

float w_rnd(void);   /* uniform [0,1), LCG */
int w_rain(float *d, int f, int cap, const float *P, int n);
int w_splash(float *d, int f, int cap, const float *P, float *S, int ns, const float *PD, int np);
int w_reflect(float *d, int f, int cap, const float *P, const float *E, int ne, const float *PD, int np);
int w_mirror(float *d, int f, int cap, const float *P, const float *Q, int nq);
int w_sprites(float *d, int f, int cap, const float *P, const float *HZ, int nh);
int w_sky(float *d, int f, int cap, const float *P, const float *BL, int nb, const float *LN, int nl,
          const float *DR, int nd);
int w_resolve(float *p, float r, const float *c, int n, float half);   /* push a circle out of colliders */
float w_raycast(const float *c, int n, const float *s);              /* hit fraction 0..1 (1 = clear) */

#endif
