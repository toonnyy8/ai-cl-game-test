// toon.frag.wgsl — fs_toon: two-tone cel shading of the toon draws (docs/STYLE_STORM_DESIGN.md §2.2).
// The lit tone is the palette colour exactly (no exposure, no ACES); the shadow tone is designed per
// colour (SHADE_OF in toon.vert.wgsl: faces are flat-coloured, so it is computed per vertex).
// Characters (Draw.toon.x 2) use the camera-space key light F.key and a CC2-style vertical gradient
// from the feet (Draw.toon.y); the stage (1) uses the moon, lighter shadows and the first F.spec.w
// point lights per pixel as flat 2-step pools. fs_main (lit.frag.wgsl) is untouched.
// #include "frame.wgsl"
@group(3) @binding(0) var<uniform> F: Frame;
// #include "toon-io.wgsl"
@fragment fn fs_toon(i: ToonV) -> @location(0) vec4f {
  let n = normalize(i.nrm);
  let alb = i.col * i.tint.rgb;
  let chr = i.toon.x > 1.5;
  let L = select(F.moon_dir.xyz, F.key.xyz, chr);
  let th = select(0.5, F.key.w, chr);
  let lit = smoothstep(th - F.toon.x, th + F.toon.x, dot(n, L) * 0.5 + 0.5);
  var sh = i.shade;
  if (chr) { sh += alb * i.warm; }                        // a nearby fire warms the shadow side only
  else { sh = mix(sh, alb, F.shd.w); }                    // stage shadows lighter, so they recede
  var c = mix(sh, alb, lit);                              // lit tone == palette colour
  let v = normalize(F.cam.xyz - i.wpos);
  if (chr) {
    c *= mix(1.0 - F.toon.y, 1.0, clamp((i.wpos.y - i.toon.y) / F.toon.z, 0.0, 1.0));   // darker toward the feet
    c += F.cin.rgb * step(1.0 - F.cin.w, 1.0 - max(dot(n, v), 0.0));                    // cinematic back-rim (0 in play)
  } else {                                                // stage: the per-pixel lights as flat pools
    var acc = Lit(i.dif, vec3f(0.0));
    let np = min(i32(F.spec.w), i32(F.spec.z));
    for (var k = 0; k < np; k++) { point_light(k, i.wpos, n, v, 0.0, &acc); }
    let pi = dot(acc.dif, vec3f(0.2126, 0.7152, 0.0722));
    c += alb * (acc.dif / max(pi, 1e-3)) * floor(min(pi, 1.0) * 2.0 + 0.35) * 0.5 * F.toon.w;
  }
  c += alb * i.fx.x;                                      // emissive
  c = mix(c, F.fog.rgb, fog_amount(i.wpos) * i.toon.z);
  c = pow(clamp(c, vec3f(0.0), vec3f(1.0)), vec3f(1.0 / 2.2));
  return vec4f(mix(c, vec3f(1.0), i.fx.y), 1.0);          // hit flash
}

// fs_ink — the ink hull's colour: the shape's ink x the draw tint, fogged like the character (Draw.toon.z).
@fragment fn fs_ink(i: ToonV) -> @location(0) vec4f {
  let c = mix(i.col * i.tint.rgb, F.fog.rgb, fog_amount(i.wpos) * i.toon.z);
  return vec4f(pow(clamp(c, vec3f(0.0), vec3f(1.0)), vec3f(1.0 / 2.2)), 1.0);
}
