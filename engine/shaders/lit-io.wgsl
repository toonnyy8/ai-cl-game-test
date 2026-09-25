// lit-io.wgsl — shared by lit.vert.wgsl and lit.frag.wgsl.
// Draw = one per-draw record of the storage buffer, laid out exactly like DRAW-MESH writes *DQ*
// (32 floats = 128 bytes). LitV = what the vertex stage hands to the fragment stage.
// fx: emissive, flash, specular (<0 = env), mesh id; rim: rgb, env rim scale;
// toon: mode (0 lit = fs_main, 1 toon stage, 2 toon character), feet height, fog scale, spare (toon.wgsl)
struct Draw { model: mat4x4f, tint: vec4f, fx: vec4f, rim: vec4f, toon: vec4f }
struct LitV {
  @builtin(position) pos: vec4f,
  @location(0) wpos: vec3f, @location(1) nrm: vec3f, @location(2) col: vec3f,
  @location(3) dif: vec3f, @location(4) spc: vec3f,   // per-vertex (Gouraud) lights
  @location(5) @interpolate(flat) tint: vec4f, @location(6) @interpolate(flat) fx: vec4f,
  @location(7) @interpolate(flat) rim: vec4f,
}
