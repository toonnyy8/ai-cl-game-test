// composite-fx.frag.wgsl — RP_COMP_FX: composite.frag.wgsl's image (scene + bloom + vignette + desaturate +
// split, P[0] = its lane) followed by a screen punctuation mode (docs/STYLE_STORM_DESIGN.md §3.6), chosen by
// r_frame only while *GRADE-IMPACT* is not 0 (RP_COMP stays untouched for every other frame):
//   P[1] = mode, luma threshold, keep-saturation, keep-hue (degrees); P[2].rgb = ink, P[2].w = keep-hue-2;
//   P[3].rgb = paper
//   1 negative        1 - c
//   2 two-tone        ink below the threshold, paper above
//   3 manga page      two-tone, but pixels with HSV saturation > keep-sat (and value > 0.25) keep their colour
//   4 spot-keep       greyscale except saturated pixels within 25 degrees of keep-hue or keep-hue-2
// #include "fullscreen.vert.wgsl"
@group(3) @binding(0) var<uniform> P: array<vec4f, 4>;
@group(2) @binding(0) var t0: texture_2d<f32>;
@group(2) @binding(1) var s0: sampler;
@group(2) @binding(2) var t1: texture_2d<f32>;
@group(2) @binding(3) var s1: sampler;
@group(2) @binding(4) var t2: texture_2d<f32>;
@group(2) @binding(5) var s2: sampler;
fn hsv(c: vec3f) -> vec3f {
  let k = vec4f(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  let p = mix(vec4f(c.bg, k.wz), vec4f(c.gb, k.xy), step(c.b, c.g));
  let q = mix(vec4f(p.xyw, c.r), vec4f(c.r, p.yzx), step(p.x, c.r));
  let d = q.x - min(q.w, q.y);
  return vec3f(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
@fragment fn fs_comp_fx(i: Post) -> @location(0) vec4f {
  let L = P[0];
  let uv = vec2f(i.uv.x, i.uv.y + select(-L.w, L.w, i.uv.x < 0.5));
  let inside = f32(uv.y >= 0.0 && uv.y <= 1.0);
  var c = (textureSample(t0, s0, uv).rgb + (textureSample(t1, s1, uv).rgb * 0.6 + textureSample(t2, s2, uv).rgb) * L.x) * inside;
  let q = i.uv - 0.5;
  c *= 1.0 - L.y * dot(q, q) * 2.0;
  let luma = dot(c, vec3f(0.2126, 0.7152, 0.0722));
  c = clamp(mix(c, vec3f(luma), L.z), vec3f(0.0), vec3f(1.0));
  let m = P[1];
  let h = hsv(c);
  let spot = h.y > m.z && h.z > 0.25;
  let two = select(P[2].rgb, P[3].rgb, luma > m.y);
  var o = vec3f(1.0) - c;
  let near = min(abs(fract(h.x - m.w / 360.0 + 0.5) - 0.5), abs(fract(h.x - P[2].w / 360.0 + 0.5) - 0.5)) * 360.0;
  if (m.x > 3.5) { o = select(vec3f(luma), c, spot && near < 25.0); }
  else if (m.x > 2.5) { o = select(two, c, spot); }
  else if (m.x > 1.5) { o = two; }
  return vec4f(o, 1.0);
}
