// rng.ts <- engine/c/rng.c + engine/c/engine.h's rng_float / rng2_float: xorshift32 streams.
// Two of them: the SIM stream (gameplay / AI inside fixed steps, so a seed replays the same fight) and the
// cosmetic stream (fx, shake). Never draw the sim stream outside a fixed step.

export class Rng {
  state: number;
  constructor(state: number) {
    this.state = state >>> 0;
  }
  /** Seed: the seed goes through murmur3's fmix32 (a bijection with fmix32(0) = 0), so small seeds like 1, 2, 3 still
   *  start in unrelated places; xorshift needs a non-zero state. */
  seed(seed: number): void {
    let x = seed >>> 0;
    x ^= x >>> 16;
    x = Math.imul(x, 0x85ebca6b) >>> 0;
    x ^= x >>> 13;
    x = Math.imul(x, 0xc2b2ae35) >>> 0;
    x ^= x >>> 16;
    this.state = x ? x >>> 0 : 0x9e3779b9;
  }
  /** Uniform [0,1): 24 bits of the next state (exact in a double, as the C float is). */
  float(): number {
    let s = this.state;
    s ^= s << 13;
    s >>>= 0;
    s ^= s >>> 17;
    s ^= s << 5;
    this.state = s >>> 0;
    return (this.state >>> 8) * (1 / 16777216);
  }
}

/** The cosmetic stream (RND01): fx, shake. Its state never matters to the sim. */
export const cosmeticRng = new Rng(0x9e3779b9);
/** A fresh sim stream (SIM-RND01) at rng.c's initial state; START-MATCH seeds it. */
export const newSimRng = (): Rng => new Rng(0x6a09e667);
