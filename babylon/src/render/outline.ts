// outline.ts: the screen-space ink outline (the user, 2026-10-04: a depth + normal edge post-process, not inverted hulls;
// fighters darker / thicker than the stage). The GeometryBufferRenderer writes view depth and view normals of the meshes
// in its render list; this pass tests a cross of neighbours at a radius that scales with the resolution: the Laplacian
// of inverse depth (exactly 0 on any plane, so a slanted floor draws no line; silhouettes and creases do) and the normal
// difference across the pixel. The ink id comes from its own render target (an INKID cel material per ink value draws the
// outlined meshes again: alpha-blended VFX can't change it): the ink id (1 = fighter, 0.95 = weapon, 0.8 = hair,
// 0 = stage): a fighter nearby picks the thick dark line, a weapon a 1 px dark one drawn only on the pixels around it (a
// blade is a few px wide at battle distance: a line over its own pixels would swallow it), the stage a
// thin muted one (B2: fighters h/300 with the interior creases at 1 px, hair (ink id 0.8) silhouette only,
// the stage 1 px at 30 %, about 0.5 px at 50 %). GLSL (WebGL2) and WGSL (WebGPU) with texelFetch / textureLoad, so
// the float G-buffer is never filtered. FXAA after it smooths the hard silhouettes.
import {
  Color3, Color4, FxaaPostProcess, PostProcess, RenderTargetTexture, ShaderLanguage, ShaderStore, type AbstractMesh, type BaseTexture,
  type Camera, type Scene,
} from '@babylonjs/core';
import { CelMaterial } from './cel';

const GLSL = `precision highp float;
varying vec2 vUV;
uniform sampler2D textureSampler; uniform sampler2D depthSampler; uniform sampler2D normalSampler; uniform sampler2D inkSampler;
uniform vec2 size; uniform vec2 radius; uniform vec3 inkChar; uniform vec3 inkStage; uniform vec3 inkAlt;
ivec2 cl(ivec2 p) { return clamp(p, ivec2(0), ivec2(size) - 1); }
float Q(ivec2 p) { float d = abs(texelFetch(depthSampler, cl(p), 0).r); return d < 1e-4 ? 0.0 : 1.0 / d; }
vec3 N(ivec2 p) { return texelFetch(normalSampler, cl(p), 0).xyz; }
float A(ivec2 p) { return texelFetch(inkSampler, cl(p), 0).r; }
float L(ivec2 p) { return texelFetch(inkSampler, cl(p), 0).g; }
void main(void) {
  vec4 c = texture2D(textureSampler, vUV);
  ivec2 p = ivec2(vUV * size);
  int rc = int(radius.x), rs = int(radius.y);
  float a0 = A(p);
  float ink = max(max(a0, max(A(p + ivec2(rc, 0)), A(p - ivec2(rc, 0)))), max(A(p + ivec2(0, rc)), A(p - ivec2(0, rc))));
  int r = ink > 0.97 ? rc : rs;
  float q0 = Q(p), ed = 0.0, en = 0.0;
  ivec2 o[4]; o[0] = ivec2(1, 0); o[1] = ivec2(0, 1); o[2] = ivec2(1, 1); o[3] = ivec2(1, -1);
  for (int i = 0; i < 4; i++) {
    float qa = Q(p + o[i] * r), qb = Q(p - o[i] * r);
    ed = max(ed, abs(qa + qb - 2.0 * q0) / max(max(qa, qb), max(q0, 1e-4)));
    if (Q(p + o[i]) > 0.0 && Q(p - o[i]) > 0.0) { en = max(en, 1.0 - dot(N(p + o[i]), N(p - o[i]))); }
  }
  float hair = a0 > 0.6 && a0 < 0.9 ? 0.0 : 1.0;
  float e = max(smoothstep(0.03, 0.1, ed), hair * smoothstep(0.5, 0.8, en)) * (a0 > 0.92 && a0 < 0.97 ? 0.0 : 1.0);   // a blade keeps its pixels
  float alt = max(max(L(p), max(L(p + ivec2(rc, 0)), L(p - ivec2(rc, 0)))), max(L(p + ivec2(0, rc)), L(p - ivec2(0, rc))));
  vec3 col = ink > 0.25 ? (alt > 0.5 ? inkAlt : inkChar) : inkStage;
  gl_FragColor = vec4(mix(c.rgb, col, e * (ink > 0.25 ? 1.0 : 0.3)), 1.0);
}`;
const WGSL = `varying vUV : vec2f;
var textureSamplerSampler : sampler; var textureSampler : texture_2d<f32>;
var depthSampler : texture_2d<f32>; var normalSampler : texture_2d<f32>; var inkSampler : texture_2d<f32>;
uniform size : vec2f; uniform radius : vec2f; uniform inkChar : vec3f; uniform inkStage : vec3f; uniform inkAlt : vec3f;
fn cl(p : vec2i) -> vec2i { return clamp(p, vec2i(0), vec2i(uniforms.size) - 1); }
fn Q(p : vec2i) -> f32 { let d = abs(textureLoad(depthSampler, cl(p), 0).r); return select(1.0 / d, 0.0, d < 1e-4); }
fn N(p : vec2i) -> vec3f { return textureLoad(normalSampler, cl(p), 0).xyz; }
fn A(p : vec2i) -> f32 { return textureLoad(inkSampler, cl(p), 0).r; }
fn L(p : vec2i) -> f32 { return textureLoad(inkSampler, cl(p), 0).g; }
@fragment
fn main(input : FragmentInputs) -> FragmentOutputs {
  let c = textureSample(textureSampler, textureSamplerSampler, fragmentInputs.vUV);
  let p = vec2i(fragmentInputs.vUV * uniforms.size);
  let rc = i32(uniforms.radius.x); let rs = i32(uniforms.radius.y);
  let a0 = A(p);
  let ink = max(max(a0, max(A(p + vec2i(rc, 0)), A(p - vec2i(rc, 0)))), max(A(p + vec2i(0, rc)), A(p - vec2i(0, rc))));
  let r = select(rs, rc, ink > 0.97);
  let q0 = Q(p);
  var ed = 0.0; var en = 0.0;
  var o = array<vec2i, 4>(vec2i(1, 0), vec2i(0, 1), vec2i(1, 1), vec2i(1, -1));
  for (var i = 0; i < 4; i++) {
    let qa = Q(p + o[i] * r); let qb = Q(p - o[i] * r);
    ed = max(ed, abs(qa + qb - 2.0 * q0) / max(max(qa, qb), max(q0, 1e-4)));
    if (Q(p + o[i]) > 0.0 && Q(p - o[i]) > 0.0) { en = max(en, 1.0 - dot(N(p + o[i]), N(p - o[i]))); }
  }
  let hair = select(1.0, 0.0, a0 > 0.6 && a0 < 0.9);
  let e = max(smoothstep(0.03, 0.1, ed), hair * smoothstep(0.5, 0.8, en)) * select(1.0, 0.0, a0 > 0.92 && a0 < 0.97);
  let alt = max(max(L(p), max(L(p + vec2i(rc, 0)), L(p - vec2i(rc, 0)))), max(L(p + vec2i(0, rc)), L(p - vec2i(0, rc))));
  let col = select(uniforms.inkStage, select(uniforms.inkChar, uniforms.inkAlt, alt > 0.5), ink > 0.25);
  fragmentOutputs.color = vec4f(mix(c.rgb, col, e * select(0.3, 1.0, ink > 0.25)), 1.0);
}`;
ShaderStore.ShadersStore.inkOutlinePixelShader = GLSL;
ShaderStore.ShadersStoreWGSL.inkOutlinePixelShader = WGSL;

// the paper: 2 % grain (fixed to the screen, like the sheet the frame is printed on) and a soft vignette, after FXAA
const PAPER_GLSL = `precision highp float;
varying vec2 vUV;
uniform sampler2D textureSampler; uniform vec2 size;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void main(void) {
  vec3 c = texture2D(textureSampler, vUV).rgb;
  vec2 q = floor(vUV * size / 1.5);
  float g = (h(q) + h(floor(q / 5.0) + 17.0)) * 0.5 - 0.5;
  vec2 d = vUV - 0.5;
  float v = 1.0 - 0.28 * smoothstep(0.3, 0.85, length(d * vec2(1.0, 0.8)));
  gl_FragColor = vec4(c * v * (1.0 + 0.04 * g), 1.0);
}`;
const PAPER_WGSL = `varying vUV : vec2f;
var textureSamplerSampler : sampler; var textureSampler : texture_2d<f32>;
uniform size : vec2f;
fn h(p : vec2f) -> f32 { return fract(sin(dot(p, vec2f(12.9898, 78.233))) * 43758.5453); }
@fragment
fn main(input : FragmentInputs) -> FragmentOutputs {
  let c = textureSample(textureSampler, textureSamplerSampler, fragmentInputs.vUV).rgb;
  let q = floor(fragmentInputs.vUV * uniforms.size / 1.5);
  let g = (h(q) + h(floor(q / 5.0) + 17.0)) * 0.5 - 0.5;
  let d = fragmentInputs.vUV - 0.5;
  let v = 1.0 - 0.28 * smoothstep(0.3, 0.85, length(d * vec2f(1.0, 0.8)));
  fragmentOutputs.color = vec4f(c * v * (1.0 + 0.04 * g), 1.0);
}`;
ShaderStore.ShadersStore.inkPaperPixelShader = PAPER_GLSL;
ShaderStore.ShadersStoreWGSL.inkPaperPixelShader = PAPER_WGSL;

/** ALT: an outlined mesh added with alt = true inks its outline in Outline.alt instead of the ink (B3-rukia: zero's ice
 *  blue; the ink-id target's green channel). ponytail: one alt colour per scene; a palette index if two ever meet. */
export interface Outline { pp: PostProcess; alt: Color3; add(m: AbstractMesh, alt?: boolean): void; remove(m: AbstractMesh): void; depth: BaseTexture }

export function createOutline(scene: Scene, camera: Camera): Outline {
  const engine = scene.getEngine();
  const gbr = scene.enableGeometryBufferRenderer(1)!;
  const list: AbstractMesh[] = [];
  gbr.renderList = list;
  // the ink ids: the same meshes again, each with an INKID cel material of its own material's ink (skinning included)
  const ids = new RenderTargetTexture('inkIds', { width: engine.getRenderWidth(), height: engine.getRenderHeight() }, scene, false);
  ids.clearColor = new Color4(0, 0, 0, 0); ids.renderList = list;
  scene.customRenderTargets.push(ids);
  scene.onBeforeRenderObservable.add(() => {                   // texel for texel with the screen (it never rescales itself)
    const w = engine.getRenderWidth(), h = engine.getRenderHeight(), sz = ids.getSize();
    if (sz.width !== w || sz.height !== h) ids.resize({ width: w, height: h });
  });
  const idMats2 = new Map<string, CelMaterial>();
  const idMat = (ink: number, inkAlt: boolean) => { const k = `${ink}:${inkAlt}`; let m = idMats2.get(k); if (!m) { m = new CelMaterial(`inkid${k}`, scene, { ink, inkId: true, inkAlt }); idMats2.set(k, m); } return m; };
  const pp = new PostProcess('inkOutline', 'inkOutline', {
    uniforms: ['size', 'radius', 'inkChar', 'inkStage', 'inkAlt'], samplers: ['depthSampler', 'normalSampler', 'inkSampler'], camera, engine,
    shaderLanguage: engine.isWebGPU ? ShaderLanguage.WGSL : ShaderLanguage.GLSL,
  });
  const inkChar = new Color3(0.05, 0.04, 0.07), inkStage = new Color3(0.22, 0.2, 0.26), alt = inkChar.clone();
  pp.onApply = (e) => {
    const g = gbr.getGBuffer(), w = g.getRenderWidth(), h = g.getRenderHeight();
    e.setTexture('depthSampler', g.textures[0]); e.setTexture('normalSampler', g.textures[1]); e.setTexture('inkSampler', ids);
    e.setFloat2('size', w, h);
    e.setFloat2('radius', Math.max(1, Math.floor(h / 300)), 1);    // fighters and weapons h/300 (3 px at 1080p); stage 1 px
    e.setColor3('inkChar', inkChar); e.setColor3('inkStage', inkStage); e.setColor3('inkAlt', alt);
  };
  new FxaaPostProcess('fxaa', 1, camera);
  const paper = new PostProcess('inkPaper', 'inkPaper', { uniforms: ['size'], camera, engine,
    shaderLanguage: engine.isWebGPU ? ShaderLanguage.WGSL : ShaderLanguage.GLSL });
  paper.onApply = (e) => e.setFloat2('size', paper.width, paper.height);
  return {
    pp, alt, depth: gbr.getGBuffer().textures[0],
    add: (m, a = false) => { list.push(m); gbr.renderList = list; ids.setMaterialForRendering(m, idMat((m.material as CelMaterial | null)?.inkValue ?? 0, a)); },
    remove: (m) => { const i = list.indexOf(m); if (i >= 0) list.splice(i, 1); gbr.renderList = list; },
  };
}
