/* rng.c — states of the engine's two random streams (rng_float / rng2_float, inline in engine.h)
   and their seeding. rng_state: RND01 (cosmetics: fx, shake).
   rng2_state: SIM-RND01 (gameplay / AI inside fixed steps, so a seed replays the same fight). */
#include "engine/c/engine.h"

unsigned rng_state = 0x9E3779B9u;
unsigned rng2_state = 0x6A09E667u;

/* Seed a stream: the seed goes through murmur3's fmix32 (a bijection with fmix32(0) = 0), so small
   seeds like 1, 2, 3 still start in unrelated places; xorshift needs a non-zero state. */
void rng_seed(unsigned *state, int seed) {
  unsigned x = (unsigned)seed;
  x ^= x >> 16; x *= 0x85EBCA6Bu; x ^= x >> 13; x *= 0xC2B2AE35u; x ^= x >> 16;
  *state = x ? x : 0x9E3779B9u;
}
