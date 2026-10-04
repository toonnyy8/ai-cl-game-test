// cel.ts: the anime cel material (the user, 2026-10-04: objects in full-colour cel shading close to TYBW / Rebirth of
// Souls, hard two-tone lit / shadow, a rim accent at most). One ShaderMaterial, GLSL on WebGL2 and WGSL on WebGPU (no
// transpiler download), with Babylon's skinning includes: base colour = vertex colour (when present) x the material's
// lit or shadow colour, chosen by N.L against a threshold (a 2 % soft band against crawling); a thin rim on the lit side;
// tint (rgb + amount) and a hit flash to white. The output alpha is the outline pass's ink id (1 = a fighter, 0 = stage).
import '@babylonjs/core/Shaders/ShadersInclude/bonesDeclaration';
import '@babylonjs/core/Shaders/ShadersInclude/bonesVertex';
import '@babylonjs/core/ShadersWGSL/ShadersInclude/bonesDeclaration';
import '@babylonjs/core/ShadersWGSL/ShadersInclude/bonesVertex';
import { Color3, Color4, ShaderLanguage, ShaderMaterial, ShaderStore, Vector3, type Scene, type TargetCamera } from '@babylonjs/core';

const GLSL_V = `precision highp float;
attribute vec3 position; attribute vec3 normal;
#ifdef VERTEXCOLOR
attribute vec4 color;
#endif
#include<bonesDeclaration>
uniform mat4 world; uniform mat4 viewProjection;
varying vec3 vN; varying vec3 vW; varying vec3 vC;
void main(void) {
  mat4 finalWorld = world;
#include<bonesVertex>
  vec4 wp = finalWorld * vec4(position, 1.0);
  vW = wp.xyz;
  vN = normalize((finalWorld * vec4(normal, 0.0)).xyz);
#ifdef VERTEXCOLOR
  vC = color.rgb;
#else
  vC = vec3(1.0);
#endif
  gl_Position = viewProjection * wp;
}`;
const GLSL_F = `precision highp float;
varying vec3 vN; varying vec3 vW; varying vec3 vC;
uniform vec3 lightDir; uniform vec3 eye; uniform vec3 litColor; uniform vec3 shadowColor;
uniform float threshold; uniform float rim; uniform vec4 tint; uniform float flash; uniform float ink;
void main(void) {
  vec3 n = normalize(vN);
  float k = smoothstep(threshold - 0.02, threshold + 0.02, dot(n, -lightDir));
  vec3 c = vC * mix(shadowColor, litColor, k);
  float f = 1.0 - max(dot(n, normalize(eye - vW)), 0.0);
  c += rim * k * smoothstep(0.62, 0.66, f) * 0.35;
  c = mix(c, tint.rgb, tint.a);
  c = mix(c, vec3(1.0), flash);
  gl_FragColor = vec4(c, ink);
}`;
const WGSL_V = `attribute position : vec3f; attribute normal : vec3f;
#ifdef VERTEXCOLOR
attribute color : vec4f;
#endif
#include<bonesDeclaration>
uniform world : mat4x4f; uniform viewProjection : mat4x4f;
varying vN : vec3f; varying vW : vec3f; varying vC : vec3f;
@vertex
fn main(input : VertexInputs) -> FragmentInputs {
  var finalWorld = uniforms.world;
#include<bonesVertex>
  let wp = finalWorld * vec4f(vertexInputs.position, 1.0);
  vertexOutputs.vW = wp.xyz;
  vertexOutputs.vN = normalize((finalWorld * vec4f(vertexInputs.normal, 0.0)).xyz);
#ifdef VERTEXCOLOR
  vertexOutputs.vC = vertexInputs.color.rgb;
#else
  vertexOutputs.vC = vec3f(1.0);
#endif
  vertexOutputs.position = uniforms.viewProjection * wp;
}`;
const WGSL_F = `varying vN : vec3f; varying vW : vec3f; varying vC : vec3f;
uniform lightDir : vec3f; uniform eye : vec3f; uniform litColor : vec3f; uniform shadowColor : vec3f;
uniform threshold : f32; uniform rim : f32; uniform tint : vec4f; uniform flash : f32; uniform ink : f32;
@fragment
fn main(input : FragmentInputs) -> FragmentOutputs {
  let n = normalize(fragmentInputs.vN);
  let k = smoothstep(uniforms.threshold - 0.02, uniforms.threshold + 0.02, dot(n, -uniforms.lightDir));
  var c = fragmentInputs.vC * mix(uniforms.shadowColor, uniforms.litColor, k);
  let f = 1.0 - max(dot(n, normalize(uniforms.eye - fragmentInputs.vW)), 0.0);
  c = c + uniforms.rim * k * smoothstep(0.62, 0.66, f) * 0.35;
  c = mix(c, uniforms.tint.rgb, uniforms.tint.a);
  c = mix(c, vec3f(1.0), uniforms.flash);
  fragmentOutputs.color = vec4f(c, uniforms.ink);
}`;
ShaderStore.ShadersStore.celVertexShader = GLSL_V;
ShaderStore.ShadersStore.celFragmentShader = GLSL_F;
ShaderStore.ShadersStoreWGSL.celVertexShader = WGSL_V;
ShaderStore.ShadersStoreWGSL.celFragmentShader = WGSL_F;

export interface CelOpts { lit?: Color3; shadow?: Color3; threshold?: number; rim?: number; ink?: number }

/** The light and eye every cel material shares, set once a frame (light comes from over the camera's left shoulder, so
 *  faces read lit and the shadow side falls away from the viewer, like anime key lighting). */
export const celLight = { dir: new Vector3(0.4, -0.8, -0.45).normalize(), eye: new Vector3() };
const all = new Set<CelMaterial>();

export class CelMaterial extends ShaderMaterial {
  constructor(name: string, scene: Scene, o: CelOpts = {}) {
    super(name, scene, { vertex: 'cel', fragment: 'cel' }, {
      attributes: ['position', 'normal'],
      uniforms: ['world', 'viewProjection', 'lightDir', 'eye', 'litColor', 'shadowColor', 'threshold', 'rim', 'tint', 'flash', 'ink'],
      shaderLanguage: scene.getEngine().isWebGPU ? ShaderLanguage.WGSL : ShaderLanguage.GLSL,
    });
    this.setColor3('litColor', o.lit ?? Color3.White());
    this.setColor3('shadowColor', o.shadow ?? new Color3(0.66, 0.66, 0.8));
    this.setFloat('threshold', o.threshold ?? 0.05);
    this.setFloat('rim', o.rim ?? 1);
    this.setFloat('ink', o.ink ?? 0);
    this.look(new Color4(0, 0, 0, 0), 0);
    this.setVector3('lightDir', celLight.dir); this.setVector3('eye', celLight.eye);
    all.add(this);
    this.onDisposeObservable.add(() => all.delete(this));
  }
  /** Per-fighter state: TINT (rgb + amount) and the hit FLASH (0..1). */
  look(tint: Color4, flash: number): void { this.setColor4('tint', tint); this.setFloat('flash', flash); }
}
/** Once a frame: the shared light and the camera position. The key light comes from above, over the camera's left
 *  shoulder, so faces turned to the viewer read lit and the shadow side falls away (anime key lighting). */
export function updateCel(cam: TargetCamera): void {
  const eye = cam.globalPosition, fwd = cam.getTarget().subtract(eye).normalize();
  const right = Vector3.Cross(fwd, Vector3.Up()).normalize();          // right-handed: forward x up = screen right
  celLight.eye.copyFrom(eye);
  celLight.dir.set(right.x * 0.5 + fwd.x * 0.45, -0.8, right.z * 0.5 + fwd.z * 0.45).normalizeToRef(celLight.dir);
  for (const m of all) { m.setVector3('lightDir', celLight.dir); m.setVector3('eye', celLight.eye); }
}
