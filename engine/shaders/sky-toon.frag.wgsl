// sky-toon.frag.wgsl — the toon sky (RP_SKY_TOON, drawn instead of fs_sky while ENV-TOON is on): the same
// horizon (fog colour) -> zenith (F.sky_top) gradient, palette-exact (no exposure, no ACES), and a flat
// moon disc (F.moon_col, size F.moon_dir.w) with two flat halo rings of strength F.moon_col.w instead of
// the soft glow, so bloom has nothing to smear.
// #include "frame.wgsl"
@group(3) @binding(0) var<uniform> F: Frame;
// #include "fullscreen.vert.wgsl"
@fragment fn fs_sky_toon(i: Post) -> @location(0) vec4f {
  let q = F.inv_vp * vec4f(i.ndc, 1.0, 1.0);
  let d = normalize(q.xyz / q.w - F.cam.xyz);
  var c = mix(F.fog.rgb, F.sky_top.rgb, pow(clamp(d.y, 0.0, 1.0), 0.5));
  let m = dot(d, F.moon_dir.xyz);
  let e = 0.0005 * F.moon_dir.w * F.moon_dir.w;   // 1 - cos(disc radius); size 1 -> ~1.8 deg
  let aa = fwidth(m);
  c += F.moon_col.rgb * F.moon_col.w * (0.5 * smoothstep(1.0 - 2.6 * e - aa, 1.0 - 2.6 * e, m)
                                        + 0.5 * smoothstep(1.0 - 1.6 * e - aa, 1.0 - 1.6 * e, m));
  c = mix(c, F.moon_col.rgb, smoothstep(1.0 - e - aa, 1.0 - e, m));
  return vec4f(pow(clamp(c, vec3f(0.0), vec3f(1.0)), vec3f(1.0 / 2.2)) + dither(i.pos.xy), 1.0);
}
