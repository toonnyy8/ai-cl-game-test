// outline.ts: the screen-space ink outline (the user, 2026-10-04: a depth + normal edge post-process, not inverted hulls;
// fighters darker / thicker than the stage). The GeometryBufferRenderer writes view depth and view normals of the meshes
// in its render list; this pass tests a cross of neighbours at a radius that scales with the resolution: the Laplacian
// of inverse depth (exactly 0 on any plane, so a slanted floor draws no line; silhouettes and creases do) and the normal
// difference across the pixel. The cel shader's output alpha is the ink id (1 = fighter, 0.5 = weapon, 0 = stage): a
// fighter nearby picks the thick dark line, a weapon a thin dark one (a blade is only a few pixels wide), the stage a
// thin muted one. GLSL (WebGL2) and WGSL (WebGPU) with texelFetch / textureLoad, so
// the float G-buffer is never filtered. FXAA after it smooths the hard silhouettes.
import {
  Color3, FxaaPostProcess, PostProcess, ShaderLanguage, ShaderStore, type AbstractMesh, type Camera, type Scene,
} from '@babylonjs/core';

const GLSL = `precision highp float;
varying vec2 vUV;
uniform sampler2D textureSampler; uniform sampler2D depthSampler; uniform sampler2D normalSampler;
uniform vec2 size; uniform vec2 radius; uniform vec3 inkChar; uniform vec3 inkStage; uniform vec3 inkAlt;
ivec2 cl(ivec2 p) { return clamp(p, ivec2(0), ivec2(size) - 1); }
float Q(ivec2 p) { float d = abs(texelFetch(depthSampler, cl(p), 0).r); return d < 1e-4 ? 0.0 : 1.0 / d; }
vec3 N(ivec2 p) { return texelFetch(normalSampler, cl(p), 0).xyz; }
float A(ivec2 p) { return texture2D(textureSampler, (vec2(cl(p)) + 0.5) / size).a; }
void main(void) {
  vec4 c = texture2D(textureSampler, vUV);
  ivec2 p = ivec2(vUV * size);
  int rc = int(radius.x), rs = int(radius.y);
  float ink = max(max(A(p), max(A(p + ivec2(rc, 0)), A(p - ivec2(rc, 0)))), max(A(p + ivec2(0, rc)), A(p - ivec2(0, rc))));
  int r = ink > 0.75 ? rc : rs;
  float q0 = Q(p), ed = 0.0, en = 0.0;
  ivec2 o[4]; o[0] = ivec2(r, 0); o[1] = ivec2(0, r); o[2] = ivec2(r, r); o[3] = ivec2(r, -r);
  for (int i = 0; i < 4; i++) {
    float qa = Q(p + o[i]), qb = Q(p - o[i]);
    ed = max(ed, abs(qa + qb - 2.0 * q0) / max(max(qa, qb), max(q0, 1e-4)));
    if (qa > 0.0 && qb > 0.0) { en = max(en, 1.0 - dot(N(p + o[i]), N(p - o[i]))); }
  }
  float e = max(smoothstep(0.03, 0.1, ed), smoothstep(0.3, 0.7, en));
  vec3 col = ink > 0.25 ? (abs(ink - 0.875) < 0.06 || abs(ink - 0.375) < 0.06 ? inkAlt : inkChar) : inkStage;
  gl_FragColor = vec4(mix(c.rgb, col, e * (ink > 0.25 ? 1.0 : 0.75)), 1.0);
}`;
const WGSL = `varying vUV : vec2f;
var textureSamplerSampler : sampler; var textureSampler : texture_2d<f32>;
var depthSampler : texture_2d<f32>; var normalSampler : texture_2d<f32>;
uniform size : vec2f; uniform radius : vec2f; uniform inkChar : vec3f; uniform inkStage : vec3f; uniform inkAlt : vec3f;
fn cl(p : vec2i) -> vec2i { return clamp(p, vec2i(0), vec2i(uniforms.size) - 1); }
fn Q(p : vec2i) -> f32 { let d = abs(textureLoad(depthSampler, cl(p), 0).r); return select(1.0 / d, 0.0, d < 1e-4); }
fn N(p : vec2i) -> vec3f { return textureLoad(normalSampler, cl(p), 0).xyz; }
fn A(p : vec2i) -> f32 { return textureSampleLevel(textureSampler, textureSamplerSampler, (vec2f(cl(p)) + 0.5) / uniforms.size, 0.0).a; }
@fragment
fn main(input : FragmentInputs) -> FragmentOutputs {
  let c = textureSample(textureSampler, textureSamplerSampler, fragmentInputs.vUV);
  let p = vec2i(fragmentInputs.vUV * uniforms.size);
  let rc = i32(uniforms.radius.x); let rs = i32(uniforms.radius.y);
  let ink = max(max(A(p), max(A(p + vec2i(rc, 0)), A(p - vec2i(rc, 0)))), max(A(p + vec2i(0, rc)), A(p - vec2i(0, rc))));
  let r = select(rs, rc, ink > 0.75);
  let q0 = Q(p);
  var ed = 0.0; var en = 0.0;
  var o = array<vec2i, 4>(vec2i(r, 0), vec2i(0, r), vec2i(r, r), vec2i(r, -r));
  for (var i = 0; i < 4; i++) {
    let qa = Q(p + o[i]); let qb = Q(p - o[i]);
    ed = max(ed, abs(qa + qb - 2.0 * q0) / max(max(qa, qb), max(q0, 1e-4)));
    if (qa > 0.0 && qb > 0.0) { en = max(en, 1.0 - dot(N(p + o[i]), N(p - o[i]))); }
  }
  let e = max(smoothstep(0.03, 0.1, ed), smoothstep(0.3, 0.7, en));
  let alt = abs(ink - 0.875) < 0.06 || abs(ink - 0.375) < 0.06;
  let col = select(uniforms.inkStage, select(uniforms.inkChar, uniforms.inkAlt, alt), ink > 0.25);
  fragmentOutputs.color = vec4f(mix(c.rgb, col, e * select(0.75, 1.0, ink > 0.25)), 1.0);
}`;
ShaderStore.ShadersStore.inkOutlinePixelShader = GLSL;
ShaderStore.ShadersStoreWGSL.inkOutlinePixelShader = WGSL;

/** The alternate ink (B3-rukia): a fighter / weapon whose cel ink id is INK_ALT's draws its outline in Outline.alt
 *  instead of the ink (Rukia's zero: ice blue). ponytail: one alt colour per scene; a per-fighter palette index if two
 *  different alt colours ever meet. */
export const INK_ALT = { body: 0.875, weapon: 0.375 };
export interface Outline { pp: PostProcess; alt: Color3; add(m: AbstractMesh): void; remove(m: AbstractMesh): void }

export function createOutline(scene: Scene, camera: Camera): Outline {
  const engine = scene.getEngine();
  const gbr = scene.enableGeometryBufferRenderer(1)!;
  const list: AbstractMesh[] = [];
  gbr.renderList = list;
  const pp = new PostProcess('inkOutline', 'inkOutline', {
    uniforms: ['size', 'radius', 'inkChar', 'inkStage', 'inkAlt'], samplers: ['depthSampler', 'normalSampler'], camera, engine,
    shaderLanguage: engine.isWebGPU ? ShaderLanguage.WGSL : ShaderLanguage.GLSL,
  });
  const inkChar = new Color3(0.05, 0.04, 0.07), inkStage = new Color3(0.22, 0.2, 0.26), alt = inkChar.clone();
  pp.onApply = (e) => {
    const g = gbr.getGBuffer(), w = g.getRenderWidth(), h = g.getRenderHeight();
    e.setTexture('depthSampler', g.textures[0]); e.setTexture('normalSampler', g.textures[1]);
    e.setFloat2('size', w, h);
    e.setFloat2('radius', Math.max(1, Math.round(h / 380)), Math.max(1, Math.round(h / 1000)));   // thickness with resolution
    e.setColor3('inkChar', inkChar); e.setColor3('inkStage', inkStage); e.setColor3('inkAlt', alt);
  };
  new FxaaPostProcess('fxaa', 1, camera);
  return {
    pp, alt,
    add: (m) => { list.push(m); gbr.renderList = list; },
    remove: (m) => { const i = list.indexOf(m); if (i >= 0) list.splice(i, 1); gbr.renderList = list; },
  };
}
