// composite.frag.wgsl — final image on the swapchain: scene + bloom (1/2 and 1/4 levels) + vignette.
// #include "fullscreen.vert.wgsl"
@group(3) @binding(0) var<uniform> P: vec4f;
@group(2) @binding(0) var t0: texture_2d<f32>;
@group(2) @binding(1) var s0: sampler;
@group(2) @binding(2) var t1: texture_2d<f32>;
@group(2) @binding(3) var s1: sampler;
@group(2) @binding(4) var t2: texture_2d<f32>;
@group(2) @binding(5) var s2: sampler;
@fragment fn fs_comp(i: Post) -> @location(0) vec4f {    // P.x = bloom strength, P.y = vignette
  var c = textureSample(t0, s0, i.uv).rgb + (textureSample(t1, s1, i.uv).rgb * 0.6 + textureSample(t2, s2, i.uv).rgb) * P.x;
  let q = i.uv - 0.5;
  c *= 1.0 - P.y * dot(q, q) * 2.0;
  return vec4f(c, 1.0);
}
