// ui.vert.wgsl — the 2D UI batch (ui.lisp): vertex = pixel position, atlas uv, sRGB color.
// Pixels (origin top-left, y down) -> clip space.
struct UiV { @builtin(position) pos: vec4f, @location(0) uv: vec2f, @location(1) col: vec4f }
@group(1) @binding(0) var<uniform> S: vec4f;   // framebuffer size in pixels
@vertex fn vs_ui(@location(0) p: vec2f, @location(1) uv: vec2f, @location(2) c: vec4f) -> UiV {
  var o: UiV;
  o.pos = vec4f(p.x / S.x * 2.0 - 1.0, 1.0 - p.y / S.y * 2.0, 0.0, 1.0); o.uv = uv; o.col = c;
  return o;
}
