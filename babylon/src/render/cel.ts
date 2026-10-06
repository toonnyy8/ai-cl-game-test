// cel.ts: the anime cel material (the user, 2026-10-04: objects in full-colour cel shading close to TYBW / Rebirth of
// Souls, hard two-tone lit / shadow, bold outlines, reiatsu glow; docs/babylon/BABYLON_LOOK.md "B2" palette). One ShaderMaterial,
// GLSL on WebGL2 and WGSL on WebGPU (no transpiler download), with Babylon's skinning includes.
//   Tone: N.L against THRESHOLD (fighters 0.18: about 60 / 40 lit) with a hard 0.01 band. A PAIRS material (fighters,
//   weapons) reads the lit colour from the vertex colour and the shadow colour from the `shade` attribute (body.ts
//   `pair` / `shadeOf`: warm skin shadows, cool cloth shadows); otherwise lit / shadow = vertex colour x the uniforms.
//   Dark colours (luminance < 0.2: black cloth, black hair) get a third, lit crease band on the faces turned to the key.
//   Rim (RIM material option: the G-buffer's depth texture): a band WIDTH px inside the silhouette edges that face away
//   from the key light on screen (the depth RIMPX away is background or farther), in the fighter's reiatsu colour.
//   Contact shadows: SHADOWR > 0 (the floor) darkens the discs under the two fighters (celLight.shadows).
//   Tint (rgb + amount) and the hit flash to white. The ink id (outline.ts) = the material's INK x the vertex colour's
//   alpha (1 = fighter, 0.95 = weapon, 0.8 = hair: silhouette only, 0 = stage); an INKID material (the outline's id
//   pass, its own render target) writes only that, so alpha-blended VFX never touch it. The colour pass's alpha carries
//   it too (kept for compatibility; the outline no longer reads it).
import '@babylonjs/core/Shaders/ShadersInclude/bonesDeclaration';
import '@babylonjs/core/Shaders/ShadersInclude/bonesVertex';
import '@babylonjs/core/ShadersWGSL/ShadersInclude/bonesDeclaration';
import '@babylonjs/core/ShadersWGSL/ShadersInclude/bonesVertex';
import {
  Color3, Color4, ShaderLanguage, ShaderMaterial, ShaderStore, Vector2, Vector3, Vector4, type BaseTexture, type Scene, type TargetCamera,
} from '@babylonjs/core';

const GLSL_V = `precision highp float;
attribute vec3 position; attribute vec3 normal;
#ifdef VERTEXCOLOR
attribute vec4 color;
#endif
#ifdef SHADE
attribute vec3 shade;
#endif
#include<bonesDeclaration>
uniform mat4 world; uniform mat4 viewProjection;
varying vec3 vN; varying vec3 vW; varying vec4 vC; varying vec3 vS;
void main(void) {
  mat4 finalWorld = world;
#include<bonesVertex>
  vec4 wp = finalWorld * vec4(position, 1.0);
  vW = wp.xyz;
  vN = normalize((finalWorld * vec4(normal, 0.0)).xyz);
#ifdef VERTEXCOLOR
  vC = color;
#else
  vC = vec4(1.0);
#endif
#ifdef SHADE
  vS = shade;
#else
  vS = vC.rgb;
#endif
  gl_Position = viewProjection * wp;
}`;
const GLSL_F = `precision highp float;
varying vec3 vN; varying vec3 vW; varying vec4 vC; varying vec3 vS;
uniform vec3 lightDir; uniform vec3 eye; uniform vec3 litColor; uniform vec3 shadowColor;
uniform float threshold; uniform float rim; uniform vec3 rimColor; uniform float rimWidth;
uniform vec4 tint; uniform float flash; uniform float ink; uniform vec4 shadows; uniform float shadowR;
#ifdef RIMSS
uniform highp sampler2D depthSampler; uniform vec2 rimPx;
#endif
void main(void) {
  vec3 n = normalize(vN);
  float ndl = dot(n, -lightDir);
  float k = smoothstep(threshold - 0.005, threshold + 0.005, ndl);
#ifdef SHADE
  vec3 c = mix(vS, vC.rgb, k);
#else
  vec3 c = vC.rgb * mix(shadowColor, litColor, k);
#endif
  float lum = dot(vC.rgb, vec3(0.3, 0.59, 0.11));
  c += vec3(0.075, 0.08, 0.11) * (1.0 - step(0.2, lum)) * smoothstep(0.645, 0.655, ndl);
#ifdef RIMSS
  ivec2 p = ivec2(gl_FragCoord.xy), sz = textureSize(depthSampler, 0) - 1;
  float d0 = abs(texelFetch(depthSampler, clamp(p, ivec2(0), sz), 0).r);
  float d1 = abs(texelFetch(depthSampler, clamp(p + ivec2(rimPx * rimWidth), ivec2(0), sz), 0).r);
  c = mix(c, rimColor, rim * ((d1 < 1e-4 || d1 > d0 * 1.04 + 1e-3) ? 1.0 : 0.0));
#endif
  if (shadowR > 0.0) {
    float d = min(distance(vW.xz, shadows.xy), distance(vW.xz, shadows.zw));
    c = mix(c, vec3(0.078, 0.078, 0.125), 0.3 * (1.0 - smoothstep(shadowR - 0.02, shadowR, d)));
  }
  c = mix(c, tint.rgb, tint.a);
  c = mix(c, vec3(1.0), flash);
#ifdef INKID
#ifdef INKALT
  gl_FragColor = vec4(ink * vC.a, 1.0, 0.0, 1.0);
#else
  gl_FragColor = vec4(ink * vC.a, 0.0, 0.0, 1.0);
#endif
#else
  gl_FragColor = vec4(c, ink * vC.a);
#endif
}`;
const WGSL_V = `attribute position : vec3f; attribute normal : vec3f;
#ifdef VERTEXCOLOR
attribute color : vec4f;
#endif
#ifdef SHADE
attribute shade : vec3f;
#endif
#include<bonesDeclaration>
uniform world : mat4x4f; uniform viewProjection : mat4x4f;
varying vN : vec3f; varying vW : vec3f; varying vC : vec4f; varying vS : vec3f;
@vertex
fn main(input : VertexInputs) -> FragmentInputs {
  var finalWorld = uniforms.world;
#include<bonesVertex>
  let wp = finalWorld * vec4f(vertexInputs.position, 1.0);
  vertexOutputs.vW = wp.xyz;
  vertexOutputs.vN = normalize((finalWorld * vec4f(vertexInputs.normal, 0.0)).xyz);
#ifdef VERTEXCOLOR
  vertexOutputs.vC = vertexInputs.color;
#else
  vertexOutputs.vC = vec4f(1.0);
#endif
#ifdef SHADE
  vertexOutputs.vS = vertexInputs.shade;
#else
  vertexOutputs.vS = vertexOutputs.vC.rgb;
#endif
  vertexOutputs.position = uniforms.viewProjection * wp;
}`;
const WGSL_F = `varying vN : vec3f; varying vW : vec3f; varying vC : vec4f; varying vS : vec3f;
uniform lightDir : vec3f; uniform eye : vec3f; uniform litColor : vec3f; uniform shadowColor : vec3f;
uniform threshold : f32; uniform rim : f32; uniform rimColor : vec3f; uniform rimWidth : f32;
uniform tint : vec4f; uniform flash : f32; uniform ink : f32; uniform shadows : vec4f; uniform shadowR : f32;
#ifdef RIMSS
var depthSampler : texture_2d<f32>; uniform rimPx : vec2f;
#endif
@fragment
fn main(input : FragmentInputs) -> FragmentOutputs {
  let n = normalize(fragmentInputs.vN);
  let ndl = dot(n, -uniforms.lightDir);
  let k = smoothstep(uniforms.threshold - 0.005, uniforms.threshold + 0.005, ndl);
#ifdef SHADE
  var c = mix(fragmentInputs.vS, fragmentInputs.vC.rgb, k);
#else
  var c = fragmentInputs.vC.rgb * mix(uniforms.shadowColor, uniforms.litColor, k);
#endif
  let lum = dot(fragmentInputs.vC.rgb, vec3f(0.3, 0.59, 0.11));
  c = c + vec3f(0.075, 0.08, 0.11) * (1.0 - step(0.2, lum)) * smoothstep(0.645, 0.655, ndl);
#ifdef RIMSS
  let sz = vec2i(textureDimensions(depthSampler)) - 1;
  let p = vec2i(fragmentInputs.position.xy);
  let d0 = abs(textureLoad(depthSampler, clamp(p, vec2i(0), sz), 0).r);
  let d1 = abs(textureLoad(depthSampler, clamp(p + vec2i(uniforms.rimPx * uniforms.rimWidth), vec2i(0), sz), 0).r);
  c = mix(c, uniforms.rimColor, uniforms.rim * select(0.0, 1.0, d1 < 1e-4 || d1 > d0 * 1.04 + 1e-3));
#endif
  if (uniforms.shadowR > 0.0) {
    let d = min(distance(fragmentInputs.vW.xz, uniforms.shadows.xy), distance(fragmentInputs.vW.xz, uniforms.shadows.zw));
    c = mix(c, vec3f(0.078, 0.078, 0.125), 0.3 * (1.0 - smoothstep(uniforms.shadowR - 0.02, uniforms.shadowR, d)));
  }
  c = mix(c, uniforms.tint.rgb, uniforms.tint.a);
  c = mix(c, vec3f(1.0), uniforms.flash);
#ifdef INKID
#ifdef INKALT
  fragmentOutputs.color = vec4f(uniforms.ink * fragmentInputs.vC.a, 1.0, 0.0, 1.0);
#else
  fragmentOutputs.color = vec4f(uniforms.ink * fragmentInputs.vC.a, 0.0, 0.0, 1.0);
#endif
#else
  fragmentOutputs.color = vec4f(c, uniforms.ink * fragmentInputs.vC.a);
#endif
}`;
ShaderStore.ShadersStore.celVertexShader = GLSL_V;
ShaderStore.ShadersStore.celFragmentShader = GLSL_F;
ShaderStore.ShadersStoreWGSL.celVertexShader = WGSL_V;
ShaderStore.ShadersStoreWGSL.celFragmentShader = WGSL_F;

export interface CelOpts {
  lit?: Color3; shadow?: Color3; threshold?: number; ink?: number;
  /** The screen-space rim: the G-buffer's depth texture (outline.ts), strength, colour and width (px). */
  rim?: BaseTexture; rimColor?: Color3; rimWidth?: number;
  /** Lit / shadow pairs per vertex (`shade` attribute; the meshes of body.ts carry it). */
  pairs?: boolean;
  /** Receive the fighters' contact shadows (radius, metres). */
  contact?: number;
  /** The outline's ink-id pass: write only the ink id (r) and INKALT (g: 1 = outline.ts's alternate ink colour). */
  inkId?: boolean; inkAlt?: boolean;
}

/** The light and eye every cel material shares. The key light is fixed in the world (docs/babylon/BABYLON_LOOK.md: top-left-front,
 *  35 deg up, seen from the pair camera's opening view, which looks at the plaza from +z); SHADOWS are the fighters'
 *  ground positions (x1, z1, x2, z2), set by the battle view. */
const KEY_EL = 35 * Math.PI / 180;
export const celLight = {
  dir: new Vector3(Math.cos(KEY_EL) * Math.SQRT1_2, -Math.sin(KEY_EL), -Math.cos(KEY_EL) * Math.SQRT1_2),
  eye: new Vector3(), shadows: new Vector4(1e4, 1e4, 1e4, 1e4),
  rimPx: new Vector2(1, 0),        // the screen direction the light travels (texel space), for the rim probe
};
const all = new Set<CelMaterial>();

export class CelMaterial extends ShaderMaterial {
  constructor(name: string, scene: Scene, o: CelOpts = {}) {
    super(name, scene, { vertex: 'cel', fragment: 'cel' }, {
      attributes: o.pairs ? ['position', 'normal', 'shade'] : ['position', 'normal'],
      uniforms: ['world', 'viewProjection', 'lightDir', 'eye', 'litColor', 'shadowColor', 'threshold', 'rim', 'rimColor',
        'rimWidth', 'tint', 'flash', 'ink', 'shadows', 'shadowR', 'rimPx'],
      samplers: o.rim ? ['depthSampler'] : [],
      defines: [...(o.pairs ? ['SHADE'] : []), ...(o.rim ? ['RIMSS'] : []), ...(o.inkId ? ['INKID'] : []), ...(o.inkAlt ? ['INKALT'] : [])],
      shaderLanguage: scene.getEngine().isWebGPU ? ShaderLanguage.WGSL : ShaderLanguage.GLSL,
    });
    this.setColor3('litColor', o.lit ?? Color3.White());
    this.setColor3('shadowColor', o.shadow ?? new Color3(0.64, 0.66, 0.8));
    this.setFloat('threshold', o.threshold ?? 0.05);
    this.setFloat('rim', 0.9);
    this.setColor3('rimColor', o.rimColor ?? Color3.White());
    this.setFloat('rimWidth', o.rimWidth ?? 3);
    if (o.rim) { this.setTexture('depthSampler', o.rim); this.rims = true; }
    this.setFloat('ink', this.inkValue = o.ink ?? 0);
    this.setFloat('shadowR', o.contact ?? 0);
    this.look(new Color4(0, 0, 0, 0), 0);
    this.setVector3('lightDir', celLight.dir); this.setVector3('eye', celLight.eye);
    this.setVector4('shadows', celLight.shadows);
    all.add(this);
    this.onDisposeObservable.add(() => all.delete(this));
  }
  rims = false;
  /** The ink id this material's meshes carry (outline.ts reads it when a mesh is added). */
  inkValue = 0;
  /** Per-fighter state: TINT (rgb + amount) and the hit FLASH (0..1). */
  look(tint: Color4, flash: number): void { this.setColor4('tint', tint); this.setFloat('flash', flash); }
  /** Per-fighter reiatsu rim: COLOR, strength and width (px). */
  rimLook(color: Color3, strength: number, width: number): void {
    this.setColor3('rimColor', color); this.setFloat('rim', strength); this.setFloat('rimWidth', width);
  }
}
/** Once a frame: the camera position and the contact shadows (the key light is fixed in the world). */
export function updateCel(cam: TargetCamera): void {
  celLight.eye.copyFrom(cam.globalPosition);
  const v = Vector3.TransformNormal(celLight.dir, cam.getViewMatrix()), l = Math.max(0.35, Math.hypot(v.x, v.y));
  // texel space: x right; y up in GL (gl_FragCoord), down in WebGPU; a light along the view probes to the right
  celLight.rimPx.set(Math.hypot(v.x, v.y) < 0.2 ? 1 : v.x / l, (cam.getScene().getEngine().isWebGPU ? -v.y : v.y) / l);
  for (const m of all) {
    m.setVector3('lightDir', celLight.dir); m.setVector3('eye', celLight.eye); m.setVector4('shadows', celLight.shadows);
    if (m.rims) m.setVector2('rimPx', celLight.rimPx);
  }
}
