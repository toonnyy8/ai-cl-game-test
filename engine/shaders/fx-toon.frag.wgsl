// fx-toon.frag.wgsl — fs_fx_toon: drawn effect shapes, one hard layer each (docs/style/STYLE_STORM_DESIGN.md §3.2-§3.5).
// A vertex carries uv (shape-local: |uv| 0 at the centre / spine .. 1 at the edge), heat, seed, wobble
// and pk = palette + presence k (0.01..0.98; the silhouette is the field's level set d = k, so k < 1
// erodes the shape). Flags: seed < 0 = an "along" shape (ribbon: the along coordinate is the heat, the
// tip erodes first; its field is |uv.x|, and uv.y only moves the noise: 0 for ribbons, the distance along
// a wall); |seed| >= 1000 = the charcoal style; pk >= 16 = a fan shape (stars, polygons,
// shards: the field is the heat lane, 0 at the centre .. 1 exactly on the straight outline); pk >= 32: a glass level
// g = floor(pk / 32) (1..3) makes the shape see-through: its alpha is the coverage x g / 4, so alpha-to-coverage keeps g of
// every 4 MSAA samples (without MSAA it stays opaque; g 0, every shape before it, is unchanged).
// Output: the palette colour, alpha = coverage (alpha-to-coverage with MSAA; F.clk.y = the discard
// threshold, 0.5 without MSAA). Noise is PCG-hashed (the same on every GPU) and steps on the fx clock
// (F.clk.x, 24 Hz ticks): energy and fire change on twos, matter (styles 1, 3) on threes; fire scrolls
// up for two drawings and reseeds on the third.
// #include "frame.wgsl"
@group(3) @binding(0) var<uniform> F: Frame;
// #include "fx-toon-io.wgsl"
// #include "fx-toon-pal.wgsl"
fn pcg(v: u32) -> u32 { let s = v * 747796405u + 2891336453u; let w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u; return (w >> 22u) ^ w; }
fn h21(p: vec2f) -> f32 { let q = vec2i(p); return f32(pcg(bitcast<u32>(q.x) ^ pcg(bitcast<u32>(q.y)))) / 4294967295.0; }
fn vnoise(p: vec2f) -> f32 {          // value noise on the integer lattice, smoothstep-interpolated
  let i = floor(p); let f = p - i; let u = f * f * (3.0 - 2.0 * f);
  return mix(mix(h21(i), h21(i + vec2f(1.0, 0.0)), u.x), mix(h21(i + vec2f(0.0, 1.0)), h21(i + vec2f(1.0, 1.0)), u.x), u.y);
}
@fragment fn fs_fx_toon(i: FxT) -> @location(0) vec4f {
  let glass = floor(i.pk / 32.0);
  let pk0 = i.pk - 32.0 * glass;
  let fan = pk0 >= 16.0;
  let pk = select(pk0, pk0 - 16.0, fan);
  let p = min(u32(pk), 12u);
  let k = clamp(fract(pk), 0.01, 0.98);
  let core = PAL[4u * p]; let body = PAL[4u * p + 1u]; let shade = PAL[4u * p + 2u]; let edge = PAL[4u * p + 3u];
  let along = i.col.y < 0.0;
  let charcoal = abs(i.col.y) >= 1000.0;
  let seed = select(abs(i.col.y), abs(i.col.y) - 1000.0, charcoal);
  let style = select(core.w, 3.0, charcoal);
  let matter = style == 1.0 || style == 3.0;
  let fire = style == 2.0;
  let heat = i.col.x;
  let s = select(i.uv, vec2f(i.uv.x, 1.0 - 2.0 * heat), along);        // shape coords: y -1 base .. +1 tip
  let tick = floor(F.clk.x / select(2.0, 3.0, matter));                // this material's drawing number
  let tf = select(tick, floor(tick / 3.0), fire);
  let scroll = select(0.0, (tick - 3.0 * tf) * 0.35, fire);
  let q = vec2f(s.x + select(0.0, i.uv.y, along), s.y - scroll) * 2.6     // along: uv.y = a free along-coordinate (walls)
        + vec2f(fract(seed * 0.618034) * 97.0 + fract(tf * 0.618034) * 37.0, fract(seed * 0.381966) * 61.0 + fract(tf * 0.414214) * 23.0);
  let n1 = vnoise(q) - 0.5; let n2 = vnoise(q * 1.7 + 13.0) - 0.5; let n3 = vnoise(q * 3.1 + 29.0);
  let grain = vnoise(q * 6.0 + 5.0); let holes = vnoise(q * 0.8 + 71.0);
  var d = select(select(length(i.uv), abs(i.uv.x), along), heat, fan) + n1 * i.col.z;   // silhouette field (wobbled)
  if (along) { d = max(d, (1.0 - k - heat) * 4.0 + k); }               // the tip erodes first
  let aa = max(fwidth(d), 1e-4);                                       // (uniform control flow)
  var cover = 1.0 - smoothstep(k - aa, k, d);
  if (matter) { cover *= step(1.0 - k, holes); }                       // matter perforates as it fades
  if (cover <= F.clk.y) { discard; }
  var c = body.rgb;
  if (style == 1.0) {                                                  // puff: sphere-lit, light:shadow ~ 7:3
    let nz = sqrt(max(1.0 - min(dot(s, s), 1.0), 0.0));
    let l = dot(vec3f(s, nz), vec3f(-0.45, 0.60, 0.66));
    c = select(select(shade.rgb, body.rgb, l > -0.05), core.rgb, l > 0.55);
  } else {
    let hc = length(s - vec2f(0.15, -0.35)) + 0.6 * n2;               // a separate core shape inside the body
    c = select(c, core.rgb, hc < select(0.42, 0.2, body.r + body.g + body.b < 0.6) * k);   // dark bodies: a thin core
    c = select(c, shade.rgb, d / k + 0.3 * s.x > 0.82);                // shadow on the side away from the light
    if (style == 3.0) { c = select(c, shade.rgb, grain > 0.55); }      // charcoal grain
  }
  let wdir = clamp(dot(normalize(s + vec2f(1e-4)), vec2f(0.35, -0.94)), 0.0, 1.0);   // heavy under and behind
  var ew = 1.8 * edge.w * F.scr.w * (0.7 + 0.8 * wdir) * step(0.2, n3);   // px (x1.8: read at 720p), broken like a brush lift
  c = select(c, edge.rgb, d > k - ew * aa);
  c = mix(c, pow(F.fog.rgb, vec3f(1.0 / 2.2)), 0.6 * i.fog);           // fog tints the colour, not the coverage
  return vec4f(c, select(cover, cover * 0.25 * glass, glass > 0.0));
}
