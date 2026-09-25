// frame.wgsl — shared by the scene shaders: the per-frame uniform block (struct Frame, filled by
// FILL-FRAME-UNIFORMS in render.lisp, 136 floats) and the lighting / fog / tonemap helpers.
// Each including program declares the uniform F itself (vertex and fragment use different groups).
// The shader loader in render.lisp strips every comment before the text reaches SDL.
struct Frame {
  vp: mat4x4f, inv_vp: mat4x4f,
  cam: vec4f,         // eye xyz, exposure
  fog: vec4f,         // linear rgb, density
  fogh: vec4f,        // base height, height falloff, max amount
  amb_sky: vec4f, amb_ground: vec4f,
  moon_dir: vec4f,    // direction TO the moon; w = sky disc size (env-sun-size)
  moon_col: vec4f,    // linear color x intensity; w = sky glow strength (env-sun-glow)
  rim: vec4f,         // linear rgb x strength, power
  sky_top: vec4f,
  spec: vec4f,        // env specular, shininess, lights used, lights shaded per pixel
  lp: array<vec4f, 8>, lc: array<vec4f, 8>,   // pos + radius; linear color x intensity + 1/radius^2
}
// Exponential distance fog, thicker near the ground (height falloff), capped at fogh.z.
fn fog_amount(p: vec3f) -> f32 {
  let d = length(p - F.cam.xyz);
  let hf = 0.35 + 0.65 * exp(-max(p.y - F.fogh.x, 0.0) * F.fogh.y);
  return min(1.0 - exp(-d * F.fog.w * hf), F.fogh.z);
}
fn tonemap(x: vec3f) -> vec3f {   // ACES fit (Narkowicz) + gamma
  let y = clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), vec3f(0.0), vec3f(1.0));
  return pow(y, vec3f(1.0 / 2.2));
}
// +-0.5/255 noise so dark gradients (sky, fog) don't band after 8-bit output.
fn dither(p: vec2f) -> f32 { return (fract(52.9829189 * fract(dot(p, vec2f(0.06711056, 0.00583715)))) - 0.5) / 255.0; }
// ~x^s for Blinn lobes without exp/log: (1 - s/8 (1-x))^8
fn lobe(x: f32, s: f32) -> f32 { var t = max(1.0 - (1.0 - x) * s * 0.125, 0.0); t *= t; t *= t; return t * t; }
struct Lit { dif: vec3f, spc: vec3f }
// Adds point light I (F.lp / F.lc) to ACC: diffuse (wrapped a little) and, when KS > 0, specular.
fn point_light(i: i32, p: vec3f, n: vec3f, v: vec3f, ks: f32, acc: ptr<function, Lit>) {
  let lp = F.lp[i]; let lc = F.lc[i];
  let d = lp.xyz - p;
  let d2 = dot(d, d);
  if (d2 >= lp.w * lp.w) { return; }   // out of range (real GPUs skip coherent pixels)
  let w = 1.0 - d2 * lc.w; let il = inverseSqrt(max(d2, 1e-6));
  let c = lc.rgb * (w * w);
  (*acc).dif += c * (max(dot(n, d) * il, 0.0) * 0.85 + 0.15);
  if (ks > 0.0) { let h = d * il + v; (*acc).spc += c * lobe(max(dot(n, h) * inverseSqrt(max(dot(h, h), 1e-6)), 0.0), F.spec.y); }
}
