// fullscreen.vert.wgsl — one triangle that covers the screen (3 vertices, no vertex buffer). Used as
// the vertex stage of the sky and post passes, and included by their fragment programs for Post.
struct Post { @builtin(position) pos: vec4f, @location(0) uv: vec2f, @location(1) ndc: vec2f }
@vertex fn vs_tri(@builtin(vertex_index) vi: u32) -> Post {   // full-screen triangle
  let p = vec2f(f32((vi & 1u) << 2u) - 1.0, f32((vi & 2u) << 1u) - 1.0);
  var o: Post;
  o.pos = vec4f(p, 1.0, 1.0); o.ndc = p;
  o.uv = vec2f(p.x * 0.5 + 0.5, 0.5 - p.y * 0.5);   // texture rows run top to bottom
  return o;
}
