// bright.frag.wgsl — bloom step 1: keep the bright part of the scene (half resolution).
// #include "fullscreen.vert.wgsl"
@group(3) @binding(0) var<uniform> P: vec4f;
@group(2) @binding(0) var t0: texture_2d<f32>;
@group(2) @binding(1) var s0: sampler;
@fragment fn fs_bright(i: Post) -> @location(0) vec4f {   // P.x = threshold
  let c = textureSample(t0, s0, i.uv).rgb;
  return vec4f(c * smoothstep(P.x, 1.0, max(c.r, max(c.g, c.b))), 1.0);
}
