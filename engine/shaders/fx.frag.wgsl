// fx.frag.wgsl — soft sprites: uv is a radial coordinate, |uv| = 0 opaque .. 1 transparent.
// Two entry points: fs_fx_alpha (alpha-blended batch) and fs_fx_add (additive batch, hot white core).
// A negative vertex alpha means |alpha| without the white core (flame particles past their hot phase).
// #include "fx-io.wgsl"
fn soft(i: FxV, core: f32) -> vec4f {   // radial falloff |uv| 0..1; CORE whitens the hot center
  var s = clamp(1.0 - length(i.uv), 0.0, 1.0);
  s = s * s * (3.0 - 2.0 * s);
  let k = select(core, 0.0, i.col.a < 0.0);
  return vec4f(mix(i.col.rgb, vec3f(1.0), k * s * s * s), abs(i.col.a) * s);
}
@fragment fn fs_fx_alpha(i: FxV) -> @location(0) vec4f { return soft(i, 0.0); }
@fragment fn fs_fx_add(i: FxV) -> @location(0) vec4f { return soft(i, 0.6); }
