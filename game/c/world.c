/* world.c — RAVEN EDGE rooftop: per-frame scenery fx written straight into the engine's fx vertex
   batches (rain, splashes, neon reflections, sky traffic) and arena collision / raycast.
   Lisp side: game/lisp/world.lisp. */
#include "game/c/world.h"
static unsigned w_seed = 0x2545F491u;
static float w_splash_acc;
float w_rnd(void) { w_seed = w_seed * 1664525u + 1013904223u; return (float)(w_seed >> 8) * (1.0f / 16777216.0f); }
static float w_hash(unsigned n) { n ^= n >> 16; n *= 0x7feb352du; n ^= n >> 15; n *= 0x846ca68bu; n ^= n >> 16; return (float)(n >> 8) * (1.0f / 16777216.0f); }
static float w_frac(float x) { return x - floorf(x); }
/* fx vertex: pos xyz, uv (radial softness), rgba. Needs locals d (buffer) and f (fill, floats). */
#define W_V(X,Y,Z,U,V,R,G,B,A) do { float *q_ = d + f; q_[0]=(X); q_[1]=(Y); q_[2]=(Z); q_[3]=(U); q_[4]=(V); \
  q_[5]=(R); q_[6]=(G); q_[7]=(B); q_[8]=(A); f += 9; } while (0)

/* P (param block, see W-FX): 0-2 eye, 3-5 cam right, 6-8 cam up, 9 time, 10 dt, 12-15 rain rgba,
   16/17 wind x/z, 18 fall speed, 19 streak length, 20/21 cam target x/z, 22 splash rate,
   23 splash radius, 24 cyan flicker (0..1), 25 beacon on (0/1) */
static int w_bb(float *d, int f, const float *P, float x, float y, float z, float s, float r, float g, float b, float a) {
  float rx = P[3]*s, ry = P[4]*s, rz = P[5]*s, ux = P[6]*s, uy = P[7]*s, uz = P[8]*s;
  W_V(x-rx-ux, y-ry-uy, z-rz-uz, -1.0f, -1.0f, r, g, b, a);
  W_V(x+rx-ux, y+ry-uy, z+rz-uz,  1.0f, -1.0f, r, g, b, a);
  W_V(x+rx+ux, y+ry+uy, z+rz+uz,  1.0f,  1.0f, r, g, b, a);
  W_V(x-rx-ux, y-ry-uy, z-rz-uz, -1.0f, -1.0f, r, g, b, a);
  W_V(x+rx+ux, y+ry+uy, z+rz+uz,  1.0f,  1.0f, r, g, b, a);
  W_V(x-rx+ux, y-ry+uy, z-rz+uz, -1.0f,  1.0f, r, g, b, a);
  return f;
}
static int w_line(float *d, int f, const float *P, float x0, float y0, float z0, float x1, float y1, float z1,
                  float w0, float w1, float r, float g, float b, float a0, float a1) {
  float dx = x1-x0, dy = y1-y0, dz = z1-z0, ex = P[0]-x0, ey = P[1]-y0, ez = P[2]-z0;
  float sx = dy*ez-dz*ey, sy = dz*ex-dx*ez, sz = dx*ey-dy*ex, sl = sqrtf(sx*sx+sy*sy+sz*sz);
  if (sl < 1e-9f) return f;
  sx /= sl; sy /= sl; sz /= sl;
  W_V(x0-sx*w0, y0-sy*w0, z0-sz*w0, 0.0f, -1.0f, r, g, b, a0);
  W_V(x0+sx*w0, y0+sy*w0, z0+sz*w0, 0.0f,  1.0f, r, g, b, a0);
  W_V(x1+sx*w1, y1+sy*w1, z1+sz*w1, 0.0f,  1.0f, r, g, b, a1);
  W_V(x0-sx*w0, y0-sy*w0, z0-sz*w0, 0.0f, -1.0f, r, g, b, a0);
  W_V(x1+sx*w1, y1+sy*w1, z1+sz*w1, 0.0f,  1.0f, r, g, b, a1);
  W_V(x1-sx*w1, y1-sy*w1, z1-sz*w1, 0.0f, -1.0f, r, g, b, a1);
  return f;
}
/* flat soft ellipse on the floor, long axis (ax,az) unit, half sizes L (along) and W (across) */
static int w_streak(float *d, int f, float cx, float y, float cz, float ax, float az, float L, float W,
                    float r, float g, float b, float a) {
  float lx = ax*L, lz = az*L, wx = -az*W, wz = ax*W;
  W_V(cx-lx-wx, y, cz-lz-wz, -1.0f, -1.0f, r, g, b, a);
  W_V(cx-lx+wx, y, cz-lz+wz,  1.0f, -1.0f, r, g, b, a);
  W_V(cx+lx+wx, y, cz+lz+wz,  1.0f,  1.0f, r, g, b, a);
  W_V(cx-lx-wx, y, cz-lz-wz, -1.0f, -1.0f, r, g, b, a);
  W_V(cx+lx+wx, y, cz+lz+wz,  1.0f,  1.0f, r, g, b, a);
  W_V(cx+lx-wx, y, cz+lz-wz, -1.0f,  1.0f, r, g, b, a);
  return f;
}

/* Rain: N stateless streaks in a 30x20x30 m box that follows the eye (positions = hash + wind*t,
   wrapped). One tapered triangle per streak: bright head, fading tail. */
int w_rain(float *d, int f, int cap, const float *P, int n) {
  const float B = 30.0f, H = 20.0f, hb = 15.0f;
  float ex = P[0], ey = P[1], ez = P[2], rx = P[3], ry = P[4], rz = P[5];
  float t = fmodf(P[9], 900.0f), cr = P[12], cg = P[13], cb = P[14], ca = P[15];
  float vx = P[16], vz = P[17], vy = -P[18];
  float il = P[19] / sqrtf(vx*vx + vy*vy + vz*vz), tx = -vx*il, ty = -vy*il, tz = -vz*il;
  for (int i = 0; i < n; i++) {
    if (f + 27 > cap) break;
    unsigned h = (unsigned)i * 4u;
    float k = 0.85f + 0.3f * w_hash(h + 3u);
    float x = w_hash(h) * B + vx*t*k, y = w_hash(h + 1u) * H + vy*t*k, z = w_hash(h + 2u) * B + vz*t*k;
    x -= B * floorf((x - ex) / B + 0.5f);
    z -= B * floorf((z - ez) / B + 0.5f);
    y -= H * floorf((y - ey) / H + 0.4f);
    float dx = x - ex, dy = y - ey, dz = z - ez, d2 = dx*dx + dy*dy + dz*dz;
    float edge = hb - fmaxf(fabsf(dx), fabsf(dz));
    float a = ca * fminf(1.0f, d2 * 0.3f) * fminf(1.0f, edge * 0.3f);
    if (a < 0.01f) continue;
    float w = fmaxf(0.007f, sqrtf(d2) * 0.0009f), kx = rx*w, ky = ry*w, kz = rz*w;
    W_V(x - kx, y - ky, z - kz, 0.0f, -1.0f, cr, cg, cb, a);
    W_V(x + kx, y + ky, z + kz, 0.0f,  1.0f, cr, cg, cb, a);
    W_V(x + tx*k, y + ty*k, z + tz*k, 1.0f, 0.0f, cr, cg, cb, a);
  }
  return f;
}

/* Splash ripples: S = ns slots (x z age pad); PD = np puddles (8 floats: x z r ...). */
int w_splash(float *d, int f, int cap, const float *P, float *S, int ns, const float *PD, int np) {
  const float life = 0.25f;
  float dt = P[10], cr = P[12], cg = P[13], cb = P[14], ca = P[15] * 0.9f;
  for (int i = 0; i < ns; i++) S[i*4 + 2] += dt;
  w_splash_acc += P[22] * dt;
  while (w_splash_acc >= 1.0f) {
    w_splash_acc -= 1.0f;
    int slot = -1;
    for (int i = 0; i < ns; i++) if (S[i*4 + 2] >= life) { slot = i; break; }
    if (slot < 0) break;
    float x, z, a = w_rnd() * 6.2831853f;
    if (np > 0 && w_rnd() < 0.4f) {
      int k = (int)(w_rnd() * np) % np; float rr = sqrtf(w_rnd()) * PD[k*8 + 2] * 0.85f;
      x = PD[k*8] + cosf(a) * rr; z = PD[k*8 + 1] + sinf(a) * rr;
    } else {
      float rr = sqrtf(w_rnd()) * P[23];
      x = P[20] + cosf(a) * rr; z = P[21] + sinf(a) * rr;
    }
    if (fabsf(x) > 17.7f || fabsf(z) > 17.7f) continue;
    S[slot*4] = x; S[slot*4 + 1] = z; S[slot*4 + 2] = 0.0f;
  }
  for (int i = 0; i < ns; i++) {
    float age = S[i*4 + 2];
    if (age >= life) continue;
    if (f + 10*54 > cap) break;
    float u = age / life, r = 0.03f + 0.25f*u, hw = 0.01f + 0.012f*u, a = ca * (1.0f - u);
    float cx = S[i*4], cz = S[i*4 + 1], y = 0.025f, ri = r - hw, ro = r + hw;
    for (int j = 0; j < 10; j++) {
      float a0 = j * 0.6283185f, a1 = a0 + 0.6283185f;
      float c0 = cosf(a0), s0 = sinf(a0), c1 = cosf(a1), s1 = sinf(a1);
      W_V(cx + c0*ri, y, cz + s0*ri, 0.0f, -1.0f, cr, cg, cb, a);
      W_V(cx + c0*ro, y, cz + s0*ro, 0.0f,  1.0f, cr, cg, cb, a);
      W_V(cx + c1*ro, y, cz + s1*ro, 0.0f,  1.0f, cr, cg, cb, a);
      W_V(cx + c0*ri, y, cz + s0*ri, 0.0f, -1.0f, cr, cg, cb, a);
      W_V(cx + c1*ro, y, cz + s1*ro, 0.0f,  1.0f, cr, cg, cb, a);
      W_V(cx + c1*ri, y, cz + s1*ri, 0.0f, -1.0f, cr, cg, cb, a);
    }
  }
  return f;
}

/* Neon reflections on the wet roof: for each emitter (E rows of 10: x y z r g b intensity width flag pad),
   the mirror point seen from the eye lands where eye->mirrored-light crosses y=0. Brighter on puddles. */
int w_reflect(float *d, int f, int cap, const float *P, const float *E, int ne, const float *PD, int np) {
  float ex = P[0], ey = P[1], ez = P[2];
  if (ey < 0.05f) return f;
  for (int i = 0; i < ne; i++) {
    const float *e = E + i*10;
    float k = e[6];
    if (e[8] == 1.0f) k *= P[24];
    if (e[8] == 2.0f) k *= P[25];
    if (k <= 0.001f || f + 54 > cap) continue;
    float t = ey / (ey + e[1]);
    float rx = ex + (e[0] - ex) * t, rz = ez + (e[2] - ez) * t;
    float m = 17.6f - fmaxf(fabsf(rx), fabsf(rz));
    if (m <= 0.0f) continue;
    float hx = rx - ex, hz = rz - ez, hl = sqrtf(hx*hx + hz*hz);
    if (hl < 0.01f) continue;
    hx /= hl; hz /= hl;
    float wet = 0.3f;
    for (int j = 0; j < np; j++) {
      float qx = rx - PD[j*8], qz = rz - PD[j*8 + 1], q = 1.0f - sqrtf(qx*qx + qz*qz) / (PD[j*8 + 2] + 0.4f);
      if (q > wet) wet = q;
    }
    float graze = 1.0f - ey / sqrtf(ey*ey + hl*hl);
    float a = k * wet * fminf(1.0f, m) * (0.35f + 0.65f*graze);
    float L = fminf(1.5f + 0.45f*hl, 10.0f) * (0.5f + wet);
    f = w_streak(d, f, rx, 0.03f, rz, hx, hz, L, e[7], e[3], e[4], e[5], a);
  }
  return f;
}

/* Mirror image of a vertical neon rect (rows of 12: x0 y0 z0 (bottom-left) x1 y1 z1 (top-right) r g b a flag pad)
   on the wet floor: each corner's mirror (y -> -y) seen from the eye lands where that ray crosses y = 0. */
int w_mirror(float *d, int f, int cap, const float *P, const float *Q, int nq) {
  float ex = P[0], ey = P[1], ez = P[2];
  if (ey < 0.05f) return f;
  for (int i = 0; i < nq; i++) {
    const float *q = Q + i*12;
    float k = q[9] * (q[10] == 1.0f ? P[24] : 1.0f);
    float hx = 0.5f * (q[0] + q[3]) - ex, hz = 0.5f * (q[2] + q[5]) - ez;
    k *= 0.2f + 0.8f * (1.0f - ey / sqrtf(ey*ey + hx*hx + hz*hz));   /* stronger at grazing angles */
    if (f + 54 > cap) return f;
    float cx[4] = {q[0], q[3], q[3], q[0]}, cy[4] = {q[1], q[1], q[4], q[4]}, cz[4] = {q[2], q[5], q[5], q[2]};
    float rx[4], rz[4];
    for (int j = 0; j < 4; j++) {
      float t = ey / (ey + cy[j]);
      rx[j] = fminf(fmaxf(ex + (cx[j] - ex) * t, -17.7f), 17.7f);
      rz[j] = fminf(fmaxf(ez + (cz[j] - ez) * t, -17.7f), 17.7f);
    }
    W_V(rx[0], 0.03f, rz[0], -1.0f, -1.0f, q[6], q[7], q[8], k);
    W_V(rx[1], 0.03f, rz[1],  1.0f, -1.0f, q[6], q[7], q[8], k);
    W_V(rx[2], 0.03f, rz[2],  1.0f,  1.0f, q[6], q[7], q[8], k);
    W_V(rx[0], 0.03f, rz[0], -1.0f, -1.0f, q[6], q[7], q[8], k);
    W_V(rx[2], 0.03f, rz[2],  1.0f,  1.0f, q[6], q[7], q[8], k);
    W_V(rx[3], 0.03f, rz[3], -1.0f,  1.0f, q[6], q[7], q[8], k);
  }
  return f;
}
/* plain billboards, rows of 8: x y z size r g b a (horizon haze = city light pollution) */
int w_sprites(float *d, int f, int cap, const float *P, const float *HZ, int nh) {
  for (int i = 0; i < nh; i++) {
    const float *h = HZ + i*8;
    if (f + 54 > cap) return f;
    f = w_bb(d, f, P, h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]);
  }
  return f;
}
/* Sky life, additive: BL blinkers (8: x y z size r g b phase), LN traffic lanes
   (16: x0 y0 z0 x1 y1 z1 n speed size r g b blink pad pad pad), DR drones (8: cx cy cz radius w phase beam pad). */
int w_sky(float *d, int f, int cap, const float *P, const float *BL, int nb, const float *LN, int nl,
          const float *DR, int nd) {
  float t = P[9];
  for (int i = 0; i < nb; i++) {
    const float *b = BL + i*8;
    if (f + 108 > cap) return f;
    float on = w_frac(t * 0.5f + b[7]) < 0.18f ? 1.0f : 0.0f;
    if (b[7] < 0.0f) on = P[25];               /* the roof mast beacon follows the 1 Hz blink */
    if (on <= 0.0f) continue;
    f = w_bb(d, f, P, b[0], b[1], b[2], b[3], b[4], b[5], b[6], 0.9f);
    f = w_bb(d, f, P, b[0], b[1], b[2], b[3] * 0.3f, 1.0f, 0.8f, 0.8f, 1.0f);
  }
  for (int i = 0; i < nl; i++) {
    const float *l = LN + i*16;
    float dx = l[3]-l[0], dy = l[4]-l[1], dz = l[5]-l[2], len = sqrtf(dx*dx + dy*dy + dz*dz);
    int n = (int)l[6];
    for (int j = 0; j < n; j++) {
      if (f + 54 > cap) return f;
      float u = w_frac((j + 0.6f * w_hash((unsigned)(i*64 + j))) / n + t * l[7] / len);
      float a = 0.85f;
      if (l[12] > 0.0f) a = w_frac(t * l[12] + j * 0.37f) < 0.12f ? 1.0f : 0.25f;
      f = w_bb(d, f, P, l[0] + dx*u, l[1] + dy*u, l[2] + dz*u, l[8], l[9], l[10], l[11], a);
    }
  }
  for (int i = 0; i < nd; i++) {
    const float *q = DR + i*8;
    if (f + 54*3 > cap) return f;
    float ang = t * q[4] + q[5];
    float x = q[0] + cosf(ang) * q[3], y = q[1] + 0.6f * sinf(t * 1.3f + q[5]), z = q[2] + sinf(ang) * q[3];
    int red = w_frac(t * 2.0f + q[5]) < 0.5f;
    f = w_bb(d, f, P, x, y, z, 0.9f, red ? 1.0f : 0.2f, 0.15f, red ? 0.15f : 1.0f, 0.9f);
    float sw = sinf(t * 0.7f + q[5]) * 0.35f, cw = cosf(t * 0.5f + q[5]) * 0.35f;
    f = w_line(d, f, P, x, y - 0.3f, z, x + sw * q[6], y - q[6], z + cw * q[6], 0.25f, 5.0f,
               0.75f, 0.85f, 1.0f, 0.10f, 0.0f);
  }
  return f;
}

/* Colliders: rows of 8 = kind (0 box, 1 cylinder), cx, cz, hx|r, hz, y0, y1, pad. */
int w_resolve(float *p, float r, const float *c, int n, float half) {
  float x = p[0], z = p[2], x0 = x, z0 = z, lim = half - r;
  for (int pass = 0; pass < 3; pass++) {
    x = fminf(fmaxf(x, -lim), lim); z = fminf(fmaxf(z, -lim), lim);
    for (int i = 0; i < n; i++) {
      const float *q = c + i*8;
      float dx = x - q[1], dz = z - q[2];
      if (q[0] == 0.0f) {
        float hx = q[3], hz = q[4];
        float px = fminf(fmaxf(dx, -hx), hx), pz = fminf(fmaxf(dz, -hz), hz);
        float ex = dx - px, ez = dz - pz, d2 = ex*ex + ez*ez;
        if (d2 >= r*r) continue;
        if (d2 > 1e-10f) { float dd = sqrtf(d2), k = (r - dd + 1e-4f) / dd; x += ex*k; z += ez*k; }
        else if (hx - fabsf(dx) < hz - fabsf(dz)) x = q[1] + (dx < 0.0f ? -1.0f : 1.0f) * (hx + r + 1e-4f);
        else z = q[2] + (dz < 0.0f ? -1.0f : 1.0f) * (hz + r + 1e-4f);
      } else {
        float rr = q[3] + r, d2 = dx*dx + dz*dz;
        if (d2 >= rr*rr) continue;
        if (d2 > 1e-10f) { float k = (rr + 1e-4f) / sqrtf(d2); x = q[1] + dx*k; z = q[2] + dz*k; }
        else z = q[2] + rr + 1e-4f;
      }
    }
  }
  x = fminf(fmaxf(x, -lim), lim); z = fminf(fmaxf(z, -lim), lim);
  p[0] = x; p[2] = z;
  return x != x0 || z != z0;
}
/* First hit of segment a->b against prop volumes and the floor (y=0); returns fraction 0..1 (1 = clear). */
float w_raycast(const float *c, int n, const float *s) {
  float x0 = s[0], y0 = s[1], z0 = s[2], dx = s[3]-x0, dy = s[4]-y0, dz = s[5]-z0, best = 1.0f;
  if (s[4] < 0.0f && y0 >= 0.0f) best = y0 / (y0 - s[4]);
  for (int i = 0; i < n; i++) {
    const float *q = c + i*8;
    float t0 = 0.0f, t1 = best;
    if (q[0] == 0.0f) {
      float lo[3] = {q[1]-q[3], q[5], q[2]-q[4]}, hi[3] = {q[1]+q[3], q[6], q[2]+q[4]};
      float o[3] = {x0, y0, z0}, v[3] = {dx, dy, dz};
      int miss = 0;
      for (int k = 0; k < 3 && !miss; k++) {
        if (fabsf(v[k]) < 1e-9f) { if (o[k] < lo[k] || o[k] > hi[k]) miss = 1; continue; }
        float ta = (lo[k] - o[k]) / v[k], tb = (hi[k] - o[k]) / v[k];
        if (ta > tb) { float tmp = ta; ta = tb; tb = tmp; }
        if (ta > t0) t0 = ta;
        if (tb < t1) t1 = tb;
        if (t0 > t1) miss = 1;
      }
      if (!miss && t0 > 0.0f && t0 < best) best = t0;
    } else {
      float ox = x0 - q[1], oz = z0 - q[2], a = dx*dx + dz*dz, b = ox*dx + oz*dz, cc = ox*ox + oz*oz - q[3]*q[3];
      if (cc <= 0.0f) continue;                     /* starts inside: ignore */
      if (a < 1e-12f) continue;
      float disc = b*b - a*cc;
      if (disc < 0.0f) continue;
      float t = (-b - sqrtf(disc)) / a, y = y0 + dy*t;
      if (t > 0.0f && t < best && y >= q[5] && y <= q[6]) best = t;
    }
  }
  return best;
}
