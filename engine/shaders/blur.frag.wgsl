// blur.frag.wgsl — bloom step 2: separable Gaussian, 9 taps folded into 5 linear samples.
// Run twice per level: P.xy = one texel along x, then along y.
// #include "fullscreen.vert.wgsl"
@group(3) @binding(0) var<uniform> P: vec4f;
@group(2) @binding(0) var t0: texture_2d<f32>;
@group(2) @binding(1) var s0: sampler;
@fragment fn fs_blur(i: Post) -> @location(0) vec4f {    // P.xy = one-texel step
  var c = textureSample(t0, s0, i.uv).rgb * 0.2270270;
  c += (textureSample(t0, s0, i.uv + P.xy * 1.3846153).rgb + textureSample(t0, s0, i.uv - P.xy * 1.3846153).rgb) * 0.3162162;
  c += (textureSample(t0, s0, i.uv + P.xy * 3.2307692).rgb + textureSample(t0, s0, i.uv - P.xy * 3.2307692).rgb) * 0.0702703;
  return vec4f(c, 1.0);
}
