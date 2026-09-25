// fx-toon.vert.wgsl — the toon fx batch (docs/STYLE_STORM_DESIGN.md §3.2): vertex = position, uv,
// (heat, seed, wobble, palette + presence). Fog is passed on: it tints the colour, never the coverage
// (alpha-to-coverage would punch holes).
// #include "frame.wgsl"
@group(1) @binding(0) var<uniform> F: Frame;
// #include "fx-toon-io.wgsl"
@vertex fn vs_fx_toon(@location(0) p: vec3f, @location(1) uv: vec2f, @location(2) c: vec4f) -> FxT {
  var o: FxT;
  o.pos = F.vp * vec4f(p, 1.0); o.uv = uv; o.col = c.rgb; o.pk = c.a; o.fog = fog_amount(p);
  return o;
}
