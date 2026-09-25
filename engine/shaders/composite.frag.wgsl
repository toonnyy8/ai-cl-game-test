// composite.frag.wgsl — final image on the swapchain: scene + bloom (1/2 and 1/4 levels) + vignette,
// then desaturation toward luma (P.z = *GRADE-DESAT*; 0 leaves the color exactly as it was).
// P.w = *GRADE-SPLIT* / window height: the left half samples P.w lower (the image moves up), the right
// half P.w higher; what falls outside the frame is black. 0 = the plain image.
// #include "fullscreen.vert.wgsl"
@group(3) @binding(0) var<uniform> P: vec4f;
@group(2) @binding(0) var t0: texture_2d<f32>;
@group(2) @binding(1) var s0: sampler;
@group(2) @binding(2) var t1: texture_2d<f32>;
@group(2) @binding(3) var s1: sampler;
@group(2) @binding(4) var t2: texture_2d<f32>;
@group(2) @binding(5) var s2: sampler;
@fragment fn fs_comp(i: Post) -> @location(0) vec4f {    // P.x = bloom strength, P.y = vignette, P.z = desaturate, P.w = split
  let uv = vec2f(i.uv.x, i.uv.y + select(-P.w, P.w, i.uv.x < 0.5));   // left half shows the image moved up
  let inside = f32(uv.y >= 0.0 && uv.y <= 1.0);
  var c = (textureSample(t0, s0, uv).rgb + (textureSample(t1, s1, uv).rgb * 0.6 + textureSample(t2, s2, uv).rgb) * P.x) * inside;
  let q = i.uv - 0.5;
  c *= 1.0 - P.y * dot(q, q) * 2.0;
  c = mix(c, vec3f(dot(c, vec3f(0.2126, 0.7152, 0.0722))), P.z);
  return vec4f(c, 1.0);
}
