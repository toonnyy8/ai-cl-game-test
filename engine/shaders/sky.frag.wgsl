// sky.frag.wgsl — drawn first in the scene pass: fog color at the horizon to F.sky_top at the zenith,
// plus the moon (or sun) disc and its glow: F.moon_dir.w = disc size, F.moon_col.w = glow strength. The view ray comes from unprojecting the pixel (F.inv_vp).
// #include "frame.wgsl"
@group(3) @binding(0) var<uniform> F: Frame;
// #include "fullscreen.vert.wgsl"
@fragment fn fs_sky(i: Post) -> @location(0) vec4f {
  let q = F.inv_vp * vec4f(i.ndc, 1.0, 1.0);
  let d = normalize(q.xyz / q.w - F.cam.xyz);
  var c = mix(F.fog.rgb, F.sky_top.rgb, pow(clamp(d.y, 0.0, 1.0), 0.5));
  let m = max(dot(d, F.moon_dir.xyz), 0.0);
  let k = F.moon_dir.w * F.moon_dir.w;   // disc radius^2 (env-sun-size); 1 -> cos edge 0.9993..0.9996
  c += F.moon_col.rgb * (smoothstep(1.0 - 0.0007 * k, 1.0 - 0.0004 * k, m) * 4.0 + pow(m, 24.0) * F.moon_col.w);
  return vec4f(tonemap(c * F.cam.w) + dither(i.pos.xy), 1.0);
}
