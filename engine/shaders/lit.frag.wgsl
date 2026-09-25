// lit.frag.wgsl — fragment stage of every mesh draw: hemisphere ambient + moon + the first
// F.spec.w point lights per pixel (+ the per-vertex ones), specular, rim (env rim x the draw's
// rim.w, + the draw's own rim), emissive, fog, tonemap.
// #include "frame.wgsl"
@group(3) @binding(0) var<uniform> F: Frame;
// #include "lit-io.wgsl"
@fragment fn fs_main(i: LitV) -> @location(0) vec4f {
  let n = normalize(i.nrm);
  let v = normalize(F.cam.xyz - i.wpos);
  let alb = i.col * i.tint.rgb;
  let ks = select(i.fx.z, F.spec.x, i.fx.z < 0.0);
  let ndm = max(dot(n, F.moon_dir.xyz), 0.0);
  var acc = Lit(mix(F.amb_ground.rgb, F.amb_sky.rgb, n.y * 0.5 + 0.5) + F.moon_col.rgb * ndm + i.dif,
                F.moon_col.rgb * 0.3 * lobe(max(dot(n, normalize(F.moon_dir.xyz + v)), 0.0), F.spec.y * 2.0) * step(0.0001, ndm) + i.spc);
  let np = min(i32(F.spec.w), i32(F.spec.z));
  for (var k = 0; k < np; k++) { point_light(k, i.wpos, n, v, ks, &acc); }
  let fr = 1.0 - max(dot(n, v), 0.0);
  var c = alb * acc.dif + acc.spc * ks + F.rim.rgb * pow(fr, F.rim.w) * i.rim.w + i.rim.rgb * (fr * fr * fr) + alb * i.fx.x;
  c = mix(c, F.fog.rgb, fog_amount(i.wpos));
  c = tonemap(c * F.cam.w);
  c = mix(c, vec3f(1.0), i.fx.y) + dither(i.pos.xy);
  return vec4f(c, i.tint.a);
}
