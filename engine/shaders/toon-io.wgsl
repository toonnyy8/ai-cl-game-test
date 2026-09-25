// toon-io.wgsl — shared by toon.vert.wgsl and toon.frag.wgsl (pipelines RP_TOON, RP_TOON_CW).
struct ToonV {
  @builtin(position) pos: vec4f,
  @location(0) wpos: vec3f, @location(1) nrm: vec3f, @location(2) col: vec3f,
  @location(3) dif: vec3f,                                 // stage: point lights past the per-pixel ones
  @location(4) @interpolate(flat) tint: vec4f, @location(5) @interpolate(flat) fx: vec4f,
  @location(6) @interpolate(flat) warm: vec3f,             // character: shadow-side tint of the nearest fx light
  @location(7) @interpolate(flat) toon: vec4f,             // Draw.toon: mode, feet height, fog scale, spare
  @location(8) shade: vec3f,                               // the designed shadow tone of col x tint (linear)
}
