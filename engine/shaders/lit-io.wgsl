// lit-io.wgsl — shared by lit.vert.wgsl and lit.frag.wgsl.
// Draw = one per-draw record of the storage buffer, laid out exactly like DRAW-MESH writes *DQ*
// (28 floats = 112 bytes). LitV = what the vertex stage hands to the fragment stage.
struct Draw { model: mat4x4f, tint: vec4f, fx: vec4f, rim: vec4f }   // fx: emissive, flash, specular (<0 = env), mesh id
struct LitV {
  @builtin(position) pos: vec4f,
  @location(0) wpos: vec3f, @location(1) nrm: vec3f, @location(2) col: vec3f,
  @location(3) dif: vec3f, @location(4) spc: vec3f,   // per-vertex (Gouraud) lights
  @location(5) @interpolate(flat) tint: vec4f, @location(6) @interpolate(flat) fx: vec4f,
  @location(7) @interpolate(flat) rim: vec3f,
}
