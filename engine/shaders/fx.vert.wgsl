// fx.vert.wgsl — the fx batches (vertex = position, uv, rgba). Fog fades the vertex alpha.
// #include "frame.wgsl"
@group(1) @binding(0) var<uniform> F: Frame;
// #include "fx-io.wgsl"
@vertex fn vs_fx(@location(0) p: vec3f, @location(1) uv: vec2f, @location(2) c: vec4f) -> FxV {
  var o: FxV;
  o.pos = F.vp * vec4f(p, 1.0); o.uv = uv; o.col = vec4f(c.rgb, c.a * (1.0 - fog_amount(p)));
  return o;
}
