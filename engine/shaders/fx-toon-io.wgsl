// fx-toon-io.wgsl — shared by fx-toon.vert.wgsl and fx-toon.frag.wgsl (the toon fx batch, RP_FXT).
// col = the vertex's heat, seed, wobble; pk = palette + presence (flat: a toon call passes one value).
struct FxT {
  @builtin(position) pos: vec4f,
  @location(0) uv: vec2f, @location(1) col: vec3f,
  @location(2) @interpolate(flat) pk: f32,
  @location(3) fog: f32,
}
