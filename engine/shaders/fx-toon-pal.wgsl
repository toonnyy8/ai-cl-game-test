// fx-toon-pal.wgsl — the toon effects' 13 palettes (docs/STYLE_STORM_DESIGN.md §3.3), sRGB, as a WGSL
// constant: palette p = PAL[4p .. 4p+3] = core (w = style: 0 energy, 1 matter puff, 2 fire hybrid),
// body, shade, edge (w = edge width in px at 720 lines). No dark ink edge (user review 2, §13 round 6): fire,
// ember, blood and matter have none (w 0), light energy keeps a coloured edge (its own shade tone), and the dark
// shapes (INK, BLACK SMOKE) keep their white value-opposite edge.
// Generated once by hand from the design table; edit here and rebuild (no uniform, no sync point).
var<private> PAL: array<vec4f, 52> = array<vec4f, 52>(
  vec4f(1.0000, 0.8941, 0.5137, 2.0), vec4f(1.0000, 0.3529, 0.1176, 0.0), vec4f(0.7216, 0.1020, 0.0471, 0.0), vec4f(0.1020, 0.0157, 0.0078, 0.0),   // 0 FIRE (core #FFE483: a yellow core, Phase 3; no edge)
  vec4f(1.0000, 0.6902, 0.5412, 2.0), vec4f(0.9098, 0.1882, 0.1020, 0.0), vec4f(0.4157, 0.0392, 0.0235, 0.0), vec4f(0.0392, 0.0157, 0.0157, 0.0),   // 1 EMBER / HELLFIRE (no edge)
  vec4f(1.0000, 1.0000, 1.0000, 0.0), vec4f(1.0000, 0.8471, 0.2275, 0.0), vec4f(0.7843, 0.5412, 0.0392, 0.0), vec4f(0.7843, 0.5412, 0.0392, 1.0),   // 2 REIATSU (edge = the shade gold)
  vec4f(1.0000, 1.0000, 1.0000, 0.0), vec4f(0.0471, 0.0471, 0.0706, 0.0), vec4f(0.1490, 0.1569, 0.2000, 0.0), vec4f(1.0000, 1.0000, 1.0000, 1.2),   // 3 INK
  vec4f(1.0000, 1.0000, 1.0000, 0.0), vec4f(0.7843, 0.8314, 0.8941, 0.0), vec4f(0.4784, 0.5490, 0.6588, 0.0), vec4f(0.4784, 0.5490, 0.6588, 1.0),   // 4 STEEL (edge = the shade steel)
  vec4f(1.0000, 1.0000, 1.0000, 0.0), vec4f(1.0000, 1.0000, 1.0000, 0.0), vec4f(0.7843, 0.8000, 0.8392, 0.0), vec4f(0.7843, 0.8000, 0.8392, 1.2),   // 5 HIT (edge = the pale shade)
  vec4f(0.9490, 0.9490, 0.9333, 1.0), vec4f(0.7686, 0.7843, 0.8157, 0.0), vec4f(0.4784, 0.5020, 0.5647, 0.0), vec4f(0.0627, 0.0627, 0.0941, 0.0),   // 6 SMOKE (no edge)
  vec4f(0.8392, 0.8471, 0.8706, 1.0), vec4f(0.6510, 0.6667, 0.7137, 0.0), vec4f(0.4157, 0.4314, 0.4863, 0.0), vec4f(0.0784, 0.0824, 0.1098, 0.0),   // 7 DUST / ROCK (no edge)
  vec4f(1.0000, 1.0000, 1.0000, 1.0), vec4f(0.8157, 0.8235, 0.8471, 0.0), vec4f(0.5412, 0.5569, 0.6039, 0.0), vec4f(0.1255, 0.1333, 0.1647, 0.0),   // 8 ASH (no edge)
  vec4f(1.0000, 1.0000, 1.0000, 0.0), vec4f(0.9020, 0.9255, 0.9569, 0.0), vec4f(0.6039, 0.6588, 0.7451, 0.0), vec4f(0.6039, 0.6588, 0.7451, 1.2),   // 9 SOUL glass (edge = the shade)
  vec4f(1.0000, 0.9098, 0.9098, 0.0), vec4f(0.8157, 0.0627, 0.1098, 0.0), vec4f(0.4157, 0.0000, 0.0314, 0.0), vec4f(0.0392, 0.0000, 0.0078, 0.0),   // 10 BLOOD (no edge)
  vec4f(0.2275, 0.2431, 0.2980, 1.0), vec4f(0.0627, 0.0627, 0.0941, 0.0), vec4f(0.0314, 0.0314, 0.0471, 0.0), vec4f(0.9098, 0.9098, 0.9255, 1.2),   // 11 BLACK SMOKE / INK SPLASH
  vec4f(1.0000, 1.0000, 1.0000, 0.0), vec4f(0.3804, 0.6392, 1.0000, 0.0), vec4f(0.1216, 0.3137, 0.7216, 0.0), vec4f(0.1216, 0.3137, 0.7216, 1.0)    // 12 BLUE (the duel's BLUE burst; edge = the shade)
);
