// sky.frag.wgsl — drawn first in the scene pass: fog color at the horizon to F.sky_top at the zenith,
// plus the moon disc and its glow. The view ray comes from unprojecting the pixel (F.inv_vp).
// #include "frame.wgsl"
@group(3) @binding(0) var<uniform> F: Frame;
// #include "fullscreen.vert.wgsl"
@fragment fn fs_sky(i: Post) -> @location(0) vec4f {
  let q = F.inv_vp * vec4f(i.ndc, 1.0, 1.0);
  let d = normalize(q.xyz / q.w - F.cam.xyz);
  var c = mix(F.fog.rgb, F.sky_top.rgb, pow(clamp(d.y, 0.0, 1.0), 0.5));
  let m = max(dot(d, F.moon_dir.xyz), 0.0);
  c += F.moon_col.rgb * (smoothstep(0.9993, 0.9996, m) * 4.0 + pow(m, 24.0) * 0.25);
  return vec4f(tonemap(c * F.cam.w) + dither(i.pos.xy), 1.0);
}
