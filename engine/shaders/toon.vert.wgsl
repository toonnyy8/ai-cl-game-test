// toon.vert.wgsl — vertex stage of the toon draws (RP_TOON*, chosen by r_draw_queue when Draw.toon.x is
// 1 stage or 2 character; docs/STYLE_STORM_DESIGN.md §2). Same transform as vs_main (lit.vert.wgsl).
// Stage draws get the point lights past the per-pixel ones per vertex (diffuse only); character draws
// get none: instead the strongest fx light within 4 m of the part's origin tints their shadow side.
// The designed shadow tone (SHADE_OF) is computed here: faces are flat-coloured, so per vertex = per pixel.
// #include "frame.wgsl"
@group(1) @binding(0) var<uniform> F: Frame;
// #include "lit-io.wgsl"
// #include "toon-io.wgsl"
@group(0) @binding(0) var<storage, read> draws: array<Draw>;
fn hsv(c: vec3f) -> vec3f {           // rgb -> (h s v), h in [0,1)
  let k = vec4f(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  let p = mix(vec4f(c.bg, k.wz), vec4f(c.gb, k.xy), step(c.b, c.g));
  let q = mix(vec4f(p.xyw, c.r), vec4f(c.r, p.yzx), step(p.x, c.r));
  let d = q.x - min(q.w, q.y);
  return vec3f(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
fn rgb(h: vec3f) -> vec3f {           // (h s v) -> rgb
  let p = abs(fract(h.xxx + vec3f(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
  return h.z * mix(vec3f(1.0), clamp(p - 1.0, vec3f(0.0), vec3f(1.0)), h.y);
}
// The designed shadow of linear colour ALB, worked in sRGB HSV (tools/toon_check.py SHADE_OF matches):
// value x F.shd.x, saturation x F.shd.y, hue turned F.shd.z degrees (warm hues toward red, others away);
// neutrals (s < 0.12) become cold blue-grey (hue 0.61).
fn shade_of(alb: vec3f) -> vec3f {
  var h = hsv(pow(alb, vec3f(1.0 / 2.2)));
  let warm = h.x < 0.19 || h.x > 0.83;
  if (h.y < 0.12) { h.x = 0.61; h.y = max(h.y * F.shd.y, 0.10); }
  else { h.x = fract(h.x + select(F.shd.z, -F.shd.z, warm) / 360.0); h.y = min(h.y * F.shd.y, 1.0); }
  h.z = h.z * F.shd.x;
  return pow(rgb(h), vec3f(2.2));
}

@vertex fn vs_toon(@builtin(instance_index) ii: u32, @location(0) p: vec3f, @location(1) n: vec3f, @location(2) c: vec3f) -> ToonV {
  let d = draws[ii];
  let wp = d.model * vec4f(p, 1.0);
  let a = d.model[0].xyz; let b = d.model[1].xyz; let e = d.model[2].xyz;
  let nm = mat3x3f(cross(b, e), cross(e, a), cross(a, b)) * n * select(1.0, -1.0, dot(a, cross(b, e)) < 0.0);
  var o: ToonV;
  o.pos = F.vp * wp;
  o.wpos = wp.xyz; o.nrm = nm; o.col = pow(c, vec3f(2.2));
  o.tint = d.tint; o.fx = d.fx; o.toon = d.toon;
  o.shade = shade_of(o.col * d.tint.rgb);
  let chr = d.toon.x > 1.5;
  let nl = i32(F.spec.z); let np = min(i32(F.spec.w), nl);
  var acc = Lit(vec3f(0.0), vec3f(0.0));
  let nn = normalize(nm); let v = normalize(F.cam.xyz - wp.xyz);
  for (var i = np; i < select(nl, np, chr); i++) { point_light(i, wp.xyz, nn, v, 0.0, &acc); }
  o.dif = acc.dif;
  let org = d.model[3].xyz;
  var best = 0.0; var warm = vec3f(0.0);
  for (var i = 0; i < select(0, nl, chr); i++) {
    let dd = F.lp[i].xyz - org; let d2 = dot(dd, dd);
    let w = max(1.0 - d2 * F.lc[i].w, 0.0);
    let lc = F.lc[i].rgb * (w * w);
    let s = dot(lc, vec3f(0.2126, 0.7152, 0.0722)) * select(0.0, 1.0, d2 < 16.0);
    if (s > best) { best = s; warm = lc; }
  }
  o.warm = warm * 0.35;
  return o;
}

// vs_hull — the ink hull (RP_HULL*, Draw.toon.x 3; docs/STYLE_STORM_DESIGN.md §2.4). The vertex's normal slot
// holds its extrusion E (MB-HULL: width multiplier baked in); the shell is pushed out by E x the ink width
// (Draw.toon.w px at 720 lines, as metres at this depth, thinner where E faces the camera) and then
// Draw.toon.y metres away from the camera along the view ray (the screen position stays): a line shows
// only where the surface behind is farther than that. The pipelines cull front faces, so only the back of
// the shell is drawn: an outline around the part. Colour = the ink colour of the shape (vertex colour).
@vertex fn vs_hull(@builtin(instance_index) ii: u32, @location(0) p: vec3f, @location(1) e: vec3f, @location(2) c: vec3f) -> ToonV {
  let d = draws[ii];
  let wp = (d.model * vec4f(p, 1.0)).xyz;
  let we = (d.model * vec4f(e, 0.0)).xyz / max(length(d.model[0].xyz), 1e-6);   // the joint's scale taken out
  let depth = (F.vp * vec4f(wp, 1.0)).w;
  let mpp = 2.0 * depth / (F.scr.z * F.scr.y);                                   // metres per pixel at this depth
  let vd = normalize(F.cam.xyz - wp);
  let taper = mix(0.45, 1.0, 1.0 - abs(dot(normalize(we + vec3f(1e-6)), vd)));   // full on the silhouette
  let q = wp + we * (clamp(d.toon.w * F.scr.w * mpp, 0.004, 0.03) * taper);
  var o: ToonV;
  o.pos = F.vp * vec4f(q + normalize(q - F.cam.xyz) * d.toon.y, 1.0);
  o.wpos = wp; o.nrm = we; o.col = pow(c, vec3f(2.2));
  o.tint = d.tint; o.fx = d.fx; o.toon = d.toon;
  return o;
}
