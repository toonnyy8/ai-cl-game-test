// fx-io.wgsl — shared by fx.vert.wgsl and fx.frag.wgsl (particles, lines, trails, decals).
struct FxV { @builtin(position) pos: vec4f, @location(0) uv: vec2f, @location(1) col: vec4f }
