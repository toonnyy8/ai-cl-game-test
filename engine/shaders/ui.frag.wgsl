// ui.frag.wgsl — color x font-atlas coverage (the atlas has one solid white cell for rects).
struct UiV { @builtin(position) pos: vec4f, @location(0) uv: vec2f, @location(1) col: vec4f }
@group(2) @binding(0) var atlas: texture_2d<f32>;
@group(2) @binding(1) var smp: sampler;
@fragment fn fs_ui(i: UiV) -> @location(0) vec4f { return vec4f(i.col.rgb, i.col.a * textureSample(atlas, smp, i.uv).r); }
