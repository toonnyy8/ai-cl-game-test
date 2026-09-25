// lit.vert.wgsl — vertex stage of every mesh draw (pipelines RP_LIT*). Vertex = position, normal,
// sRGB color. The draw's record is draws[instance_index] (r_frame passes the record index as the
// first instance). Point lights past the per-pixel count (F.spec.w) are shaded here, per vertex.
// #include "frame.wgsl"
@group(1) @binding(0) var<uniform> F: Frame;
// #include "lit-io.wgsl"
@group(0) @binding(0) var<storage, read> draws: array<Draw>;
@vertex fn vs_main(@builtin(instance_index) ii: u32, @location(0) p: vec3f, @location(1) n: vec3f, @location(2) c: vec3f) -> LitV {
  let d = draws[ii];
  let wp = d.model * vec4f(p, 1.0);
  let a = d.model[0].xyz; let b = d.model[1].xyz; let e = d.model[2].xyz;
  // normal matrix = inverse transpose = cofactors / det (sign only: normalized later)
  let nm = mat3x3f(cross(b, e), cross(e, a), cross(a, b)) * n * select(1.0, -1.0, dot(a, cross(b, e)) < 0.0);
  var o: LitV;
  o.pos = F.vp * wp;
  o.wpos = wp.xyz; o.nrm = nm; o.col = pow(c, vec3f(2.2));
  o.tint = d.tint; o.fx = d.fx; o.rim = d.rim;
  var acc = Lit(vec3f(0.0), vec3f(0.0));
  let nl = i32(F.spec.z); let np = i32(F.spec.w);
  if (np < nl) {                               // per-vertex lights np..nl-1
    let nn = normalize(nm); let v = normalize(F.cam.xyz - wp.xyz);
    let ks = select(d.fx.z, F.spec.x, d.fx.z < 0.0);
    for (var i = np; i < nl; i++) { point_light(i, wp.xyz, nn, v, ks, &acc); }
  }
  o.dif = acc.dif; o.spc = acc.spc;
  return o;
}
