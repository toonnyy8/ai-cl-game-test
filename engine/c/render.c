/* render.c — the SDL_GPU renderer (WebGPU backend): pipelines, meshes, offscreen targets and the
   whole frame (r_frame). Lisp side: engine/lisp/render.lisp (+ ui.lisp for the UI pipeline).
   Never call a blocking SDL_GPU function (WaitAndAcquire..., WaitForGPUFences/Idle): they spin and
   need ASYNCIFY/JSPI, which ECL's setjmp/longjmp rule out. See docs/ARCHITECTURE.md. */
#include "engine/c/engine.h"
#include <stdio.h>
static SDL_GPUDevice *r_dev;
/* Slots are fixed: ui.lisp creates RP_UI = 10; the toon pipelines (SOUL DUEL's restyle) are appended. */
enum { RP_LIT, RP_LIT_CW, RP_LIT_T, RP_LIT_T_CW, RP_SKY, RP_FXA, RP_FXB, RP_BRIGHT, RP_BLUR, RP_COMP, RP_UI,
       RP_TOON, RP_TOON_CW, RP_SKY_TOON, RP_HULL, RP_HULL_CW, RP_FXT, RP_COMP_FX, RP_N };
static SDL_GPUGraphicsPipeline *r_pipe[RP_N];
static SDL_GPUSampler *r_linear, *r_nearest;
static SDL_GPUTexture *r_msaa_tex, *r_depth, *r_scene, *r_half[2], *r_q[2], *r_font;
static SDL_GPUBuffer *r_draws, *r_fx[3], *r_uib;
static SDL_GPUTransferBuffer *r_dyn;
static int r_fw, r_fh, r_samples = 1, r_tris;
#define R_DQ 32            /* draw record floats = WGSL struct Draw (128 bytes), see DRAW-MESH */
#define R_FU 160           /* frame uniform floats = WGSL struct Frame, see FILL-FRAME-UNIFORMS */
#define R_MAX_DRAWS 4096
#define R_FX_VERTS 16384   /* per fx batch, 9 floats each */
#define R_UI_VERTS 32768   /* 8 floats each */
#define R_OFF_FX0 (R_MAX_DRAWS * R_DQ * 4)
#define R_OFF_FX1 (R_OFF_FX0 + R_FX_VERTS * 36)
#define R_OFF_FX2 (R_OFF_FX1 + R_FX_VERTS * 36)   /* the toon fx batch (RP_FXT) */
#define R_OFF_UI (R_OFF_FX2 + R_FX_VERTS * 36)
#define R_DYN_SIZE (R_OFF_UI + R_UI_VERTS * 32)

/* Meshes live in 4 MB vertex buffer chunks (fewer vertex-buffer binds); a mesh = chunk, first vertex, count. */
typedef struct { int buf, first, count; } RMesh;
#define R_CHUNK (4u << 20)
static SDL_GPUBuffer *r_vb[64]; static int r_nvb; static Uint32 r_vb_used, r_vb_cap;
static RMesh *r_mesh; static int r_nmesh, r_mesh_cap;

static int r_count(const char *s, const char *needle) { int n = 0; for (const char *p = s; (p = SDL_strstr(p, needle)); p++) n++; return n; }
static SDL_GPUShader *r_shader(const char *src, const char *entry, SDL_GPUShaderStage stage) {
  SDL_GPUShaderCreateInfo si = {0};
  si.code = (const Uint8 *)src; si.code_size = SDL_strlen(src); si.entrypoint = entry;
  si.format = SDL_GPU_SHADERFORMAT_WGSL; si.stage = stage;
  si.num_samplers = r_count(src, ": sampler;");
  si.num_storage_buffers = r_count(src, "var<storage");
  si.num_uniform_buffers = r_count(src, "var<uniform>");
  return SDL_CreateGPUShader(r_dev, &si);
}
/* LAYOUT: vertex attribute sizes (floats) as hex digits, 0x333 = 3 x float3; 0 = no vertex buffer.
   TARGET 0 scene (MSAA + depth), 1 offscreen RGBA8, 2 swapchain. DEPTH 0 off, 1 test+write, 2 test.
   BLEND 0 off, 1 alpha, 2 additive, 3 off + alpha-to-coverage (with MSAA; the toon fx shader discards
   below its own threshold without it). CULL 0 none, 1 back, 2 back with clockwise front faces,
   3 front (the ink hull), 4 front with clockwise front faces. */
int r_make_pipe(int slot, const char *vsrc, const char *ventry, const char *fsrc, const char *fentry,
                int layout, int target, int depth, int blend, int cull) {
  static const SDL_GPUVertexElementFormat fmt[5] = { SDL_GPU_VERTEXELEMENTFORMAT_INVALID, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT,
    SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4 };
  SDL_GPUShader *vs = r_shader(vsrc, ventry, SDL_GPU_SHADERSTAGE_VERTEX), *fs = r_shader(fsrc, fentry, SDL_GPU_SHADERSTAGE_FRAGMENT);
  SDL_GPUVertexAttribute at[4]; SDL_GPUVertexBufferDescription vb = {0}; int na = 0, off = 0;
  for (int sh = 12; sh >= 0; sh -= 4) {
    int n = (layout >> sh) & 15; if (!n) continue;
    at[na] = (SDL_GPUVertexAttribute){ (Uint32)na, 0, fmt[n], (Uint32)off * 4 }; na++; off += n;
  }
  vb.pitch = off * 4; vb.input_rate = SDL_GPU_VERTEXINPUTRATE_VERTEX;
  SDL_GPUColorTargetDescription ct = {0};
  SDL_GPUColorTargetBlendState *bs = &ct.blend_state;
  ct.format = target == 2 ? SDL_GetGPUSwapchainTextureFormat(r_dev, pf_window()) : SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
  int a2c = blend == 3; if (a2c) blend = 0;   /* alpha-to-coverage: no blending */
  bs->enable_blend = blend != 0; bs->color_blend_op = bs->alpha_blend_op = SDL_GPU_BLENDOP_ADD;
  bs->src_color_blendfactor = blend ? SDL_GPU_BLENDFACTOR_SRC_ALPHA : SDL_GPU_BLENDFACTOR_ONE;
  bs->dst_color_blendfactor = blend == 1 ? SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA : blend ? SDL_GPU_BLENDFACTOR_ONE : SDL_GPU_BLENDFACTOR_ZERO;
  bs->src_alpha_blendfactor = blend == 2 ? SDL_GPU_BLENDFACTOR_SRC_ALPHA : SDL_GPU_BLENDFACTOR_ONE;
  bs->dst_alpha_blendfactor = blend == 1 ? SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA : blend ? SDL_GPU_BLENDFACTOR_ONE : SDL_GPU_BLENDFACTOR_ZERO;
  SDL_GPUGraphicsPipelineCreateInfo pi = {0};
  pi.vertex_shader = vs; pi.fragment_shader = fs;
  pi.vertex_input_state = (SDL_GPUVertexInputState){ &vb, na ? 1u : 0u, at, (Uint32)na };
  pi.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
  pi.rasterizer_state.cull_mode = cull >= 3 ? SDL_GPU_CULLMODE_FRONT : cull ? SDL_GPU_CULLMODE_BACK : SDL_GPU_CULLMODE_NONE;
  pi.rasterizer_state.front_face = cull == 2 || cull == 4 ? SDL_GPU_FRONTFACE_CLOCKWISE : SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE;
  pi.rasterizer_state.enable_depth_clip = true;
  pi.multisample_state.sample_count = target == 0 && r_samples > 1 ? SDL_GPU_SAMPLECOUNT_4 : SDL_GPU_SAMPLECOUNT_1;
  pi.multisample_state.enable_alpha_to_coverage = a2c && target == 0 && r_samples > 1;
  /* the WebGPU backend ignores enable_depth_test: an untested pipeline needs compare ALWAYS */
  pi.depth_stencil_state.enable_depth_test = depth > 0; pi.depth_stencil_state.enable_depth_write = depth == 1;
  pi.depth_stencil_state.compare_op = depth ? SDL_GPU_COMPAREOP_LESS : SDL_GPU_COMPAREOP_ALWAYS;
  pi.target_info.color_target_descriptions = &ct; pi.target_info.num_color_targets = 1;
  if (target == 0) { pi.target_info.depth_stencil_format = SDL_GPU_TEXTUREFORMAT_D32_FLOAT; pi.target_info.has_depth_stencil_target = true; }
  r_pipe[slot] = vs && fs ? SDL_CreateGPUGraphicsPipeline(r_dev, &pi) : NULL;
  if (vs) SDL_ReleaseGPUShader(r_dev, vs);
  if (fs) SDL_ReleaseGPUShader(r_dev, fs);
  if (!r_pipe[slot]) printf("render: pipeline %s/%s failed: %s\n", ventry, fentry, SDL_GetError());
  return r_pipe[slot] != NULL;
}
static SDL_GPUTexture *r_tex(int w, int h, SDL_GPUTextureFormat f, int samples, SDL_GPUTextureUsageFlags usage) {
  SDL_GPUTextureCreateInfo ti = {0};
  ti.type = SDL_GPU_TEXTURETYPE_2D; ti.format = f; ti.usage = usage;
  ti.width = w > 0 ? w : 1; ti.height = h > 0 ? h : 1; ti.layer_count_or_depth = 1; ti.num_levels = 1;
  ti.sample_count = samples > 1 ? SDL_GPU_SAMPLECOUNT_4 : SDL_GPU_SAMPLECOUNT_1;
  return SDL_CreateGPUTexture(r_dev, &ti);
}
static SDL_GPUBuffer *r_buf(SDL_GPUBufferUsageFlags usage, Uint32 size) {
  SDL_GPUBufferCreateInfo bi = {0}; bi.usage = usage; bi.size = size;
  return SDL_CreateGPUBuffer(r_dev, &bi);
}
/* One-off upload (setup time): its own transfer buffer and command buffer. */
static void r_upload(SDL_GPUBuffer *buf, SDL_GPUTexture *tex, Uint32 off, const void *src, Uint32 size, int tw, int th) {
  SDL_GPUTransferBufferCreateInfo ti = {0}; ti.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD; ti.size = size;
  SDL_GPUTransferBuffer *tb = SDL_CreateGPUTransferBuffer(r_dev, &ti);
  SDL_memcpy(SDL_MapGPUTransferBuffer(r_dev, tb, false), src, size);
  SDL_UnmapGPUTransferBuffer(r_dev, tb);
  SDL_GPUCommandBuffer *cb = SDL_AcquireGPUCommandBuffer(r_dev);
  SDL_GPUCopyPass *cp = SDL_BeginGPUCopyPass(cb);
  if (buf) {
    SDL_GPUTransferBufferLocation l = { tb, 0 }; SDL_GPUBufferRegion r = { buf, off, size };
    SDL_UploadToGPUBuffer(cp, &l, &r, false);
  } else {
    SDL_GPUTextureTransferInfo l = {0}; SDL_GPUTextureRegion r = {0};
    l.transfer_buffer = tb; r.texture = tex; r.w = tw; r.h = th; r.d = 1;
    SDL_UploadToGPUTexture(cp, &l, &r, false);
  }
  SDL_EndGPUCopyPass(cp);
  SDL_SubmitGPUCommandBuffer(cb);
  SDL_ReleaseGPUTransferBuffer(r_dev, tb);
}
int r_init(int msaa) {
  r_dev = SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_WGSL, false, NULL);
  if (!r_dev) { printf("render: SDL_CreateGPUDevice: %s\n", SDL_GetError()); return 0; }
  if (!SDL_ClaimWindowForGPUDevice(r_dev, pf_window())) { printf("render: SDL_ClaimWindowForGPUDevice: %s\n", SDL_GetError()); return 0; }
  r_samples = msaa > 1 && SDL_GPUTextureSupportsSampleCount(r_dev, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_SAMPLECOUNT_4) ? 4 : 1;
  SDL_GPUSamplerCreateInfo si = {0};
  si.address_mode_u = si.address_mode_v = si.address_mode_w = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
  si.min_filter = si.mag_filter = SDL_GPU_FILTER_LINEAR; r_linear = SDL_CreateGPUSampler(r_dev, &si);
  si.min_filter = si.mag_filter = SDL_GPU_FILTER_NEAREST; r_nearest = SDL_CreateGPUSampler(r_dev, &si);
  r_draws = r_buf(SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ, R_MAX_DRAWS * R_DQ * 4);
  r_fx[0] = r_buf(SDL_GPU_BUFFERUSAGE_VERTEX, R_FX_VERTS * 36);
  r_fx[1] = r_buf(SDL_GPU_BUFFERUSAGE_VERTEX, R_FX_VERTS * 36);
  r_fx[2] = r_buf(SDL_GPU_BUFFERUSAGE_VERTEX, R_FX_VERTS * 36);
  r_uib = r_buf(SDL_GPU_BUFFERUSAGE_VERTEX, R_UI_VERTS * 32);
  SDL_GPUTransferBufferCreateInfo ti = {0}; ti.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD; ti.size = R_DYN_SIZE;
  r_dyn = SDL_CreateGPUTransferBuffer(r_dev, &ti);
  printf("render: SDL_GPU %s, scene MSAA %dx\n", SDL_GetGPUDeviceDriver(r_dev), r_samples);
  return r_linear && r_nearest && r_draws && r_fx[0] && r_fx[1] && r_fx[2] && r_uib && r_dyn;
}
int r_sample_count(void) { return r_samples; }   /* scene MSAA samples actually used (1 or 4) */
int r_mesh_new(const float *v, int n) {
  Uint32 size = (Uint32)n * 36;
  if (r_nmesh == r_mesh_cap) { r_mesh_cap = r_mesh_cap ? r_mesh_cap * 2 : 256; r_mesh = SDL_realloc(r_mesh, r_mesh_cap * sizeof *r_mesh); }
  RMesh *m = &r_mesh[r_nmesh]; m->buf = m->first = 0; m->count = n;
  if (n > 0) {
    if (!r_nvb || r_vb_used + size > r_vb_cap) {
      if (r_nvb == 64) return -1;
      r_vb_cap = size > R_CHUNK ? size : R_CHUNK;
      r_vb[r_nvb++] = r_buf(SDL_GPU_BUFFERUSAGE_VERTEX, r_vb_cap); r_vb_used = 0;
    }
    m->buf = r_nvb - 1; m->first = r_vb_used / 36;
    r_upload(r_vb[m->buf], NULL, r_vb_used, v, size, 0, 0); r_vb_used += size;
  }
  return r_nmesh++;
}
int r_font_new(const unsigned char *px, int w, int h) {
  r_font = r_tex(w, h, SDL_GPU_TEXTUREFORMAT_R8_UNORM, 1, SDL_GPU_TEXTUREUSAGE_SAMPLER);
  if (r_font) r_upload(NULL, r_font, 0, px, w * h, w, h);
  return r_font != NULL;
}
/* (Re)create the offscreen targets for a W x H scene. */
static int r_targets(int w, int h) {
  if (w == r_fw && h == r_fh) return 1;
  SDL_GPUTexture *old[7] = { r_msaa_tex, r_depth, r_scene, r_half[0], r_half[1], r_q[0], r_q[1] };
  for (int i = 0; i < 7; i++) if (old[i]) SDL_ReleaseGPUTexture(r_dev, old[i]);
  SDL_GPUTextureUsageFlags rt = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER;
  SDL_GPUTextureFormat f = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
  r_scene = r_tex(w, h, f, 1, rt);
  r_msaa_tex = r_samples > 1 ? r_tex(w, h, f, r_samples, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) : NULL;
  r_depth = r_tex(w, h, SDL_GPU_TEXTUREFORMAT_D32_FLOAT, r_samples, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET);
  for (int i = 0; i < 2; i++) { r_half[i] = r_tex(w / 2, h / 2, f, 1, rt); r_q[i] = r_tex(w / 4, h / 4, f, 1, rt); }
  r_fw = w; r_fh = h;
  return r_scene && r_depth && r_half[0] && r_half[1] && r_q[0] && r_q[1] && (r_samples == 1 || r_msaa_tex);
}
/* Opaque (TRANSPARENT 0) or alpha < 1 (1) records of the queue. Per-draw data is read by the vertex
   shader from the storage buffer at instance_index = record index (first_instance). An opaque record
   with a toon mode (q[28] 1 stage / 2 character) uses the toon pipelines, 3 (ink hull) the hull ones; 0 (RAVEN,
   every legacy draw) the lit ones. */
static int r_draw_queue(SDL_GPURenderPass *rp, const float *q, int n, int transparent) {
  int cur_pipe = -1, cur_buf = -1, drawn = 0;
  for (int i = 0; i < n; i++, q += R_DQ) {
    if ((q[19] < 0.999f) != transparent) continue;
    int id = (int)q[23]; if (id < 0 || id >= r_nmesh || r_mesh[id].count == 0) continue;
    RMesh *m = &r_mesh[id];
    float det = q[0]*(q[5]*q[10]-q[9]*q[6]) - q[4]*(q[1]*q[10]-q[9]*q[2]) + q[8]*(q[1]*q[6]-q[5]*q[2]);
    int pipe = (transparent || q[28] < 0.5f ? RP_LIT + 2 * transparent : q[28] > 2.5f ? RP_HULL : RP_TOON) + (det < 0);   /* mirrored transforms flip winding */
    if (pipe != cur_pipe) {
      SDL_BindGPUGraphicsPipeline(rp, r_pipe[pipe]);
      SDL_BindGPUVertexStorageBuffers(rp, 0, &r_draws, 1);   /* pipeline binds reset resource bindings */
      cur_pipe = pipe;
    }
    if (m->buf != cur_buf) { SDL_GPUBufferBinding b = { r_vb[m->buf], 0 }; SDL_BindGPUVertexBuffers(rp, 0, &b, 1); cur_buf = m->buf; }
    SDL_DrawGPUPrimitives(rp, m->count, 1, m->first, i);
    drawn++; r_tris += m->count / 3;
  }
  return drawn;
}
static void r_draw_batch(SDL_GPURenderPass *rp, int pipe, SDL_GPUBuffer *buf, int nverts) {
  if (nverts <= 0) return;
  SDL_GPUBufferBinding b = { buf, 0 };
  SDL_BindGPUGraphicsPipeline(rp, r_pipe[pipe]);
  SDL_BindGPUVertexBuffers(rp, 0, &b, 1);
  SDL_DrawGPUPrimitives(rp, nverts, 1, 0, 0);
}
/* Full-screen pass into DST reading textures SRC[0..NSRC-1] (linear), fragment uniform U (vec4). */
static SDL_GPURenderPass *r_fs_pass(SDL_GPUCommandBuffer *cb, SDL_GPUTexture *dst, int pipe, SDL_GPUTexture **src, int nsrc,
                                    float u0, float u1, float u2, float u3, int keep_open) {
  SDL_GPUColorTargetInfo ct = {0};
  ct.texture = dst; ct.load_op = SDL_GPU_LOADOP_DONT_CARE; ct.store_op = SDL_GPU_STOREOP_STORE;
  SDL_GPURenderPass *rp = SDL_BeginGPURenderPass(cb, &ct, 1, NULL);
  SDL_GPUTextureSamplerBinding b[3]; float u[4] = { u0, u1, u2, u3 };
  for (int i = 0; i < nsrc; i++) { b[i].texture = src[i]; b[i].sampler = r_linear; }
  SDL_BindGPUGraphicsPipeline(rp, r_pipe[pipe]);
  SDL_BindGPUFragmentSamplers(rp, 0, b, nsrc);
  SDL_PushGPUFragmentUniformData(cb, 0, u, sizeof u);
  SDL_DrawGPUPrimitives(rp, 3, 1, 0, 0);
  if (keep_open) return rp;
  SDL_EndGPURenderPass(rp); return NULL;
}
/* The whole frame. FU = frame uniforms; RP = [0 bloom 1 threshold 2 strength 3 vignette
   4 scene w 5 scene h 6 window w 7 window h 8 desaturate 9 split (window px) 10 toon sky
   11 impact mode (0 = RP_COMP; 1..4 = RP_COMP_FX, see composite-fx.frag.wgsl) 12 threshold 13 keep-saturation
   14 keep-hue 15..17 ink rgb 18..20 paper rgb 21 keep-hue-2]; DQ = N draw records; FXA/FXB/FXT/UI = vertex floats.
   Returns the mesh draws issued, or -1 when no swapchain texture was available (frame skipped). */
int r_frame(const float *fu, const float *rp, const float *dq, int n,
            const float *fxa, int nfa, const float *fxb, int nfb, const float *ui, int nui, const float *fxt, int nft) {
  SDL_GPUCommandBuffer *cb = SDL_AcquireGPUCommandBuffer(r_dev);
  SDL_GPUTexture *swt = NULL; Uint32 sw, sh;
  if (!cb) return -1;
  if (!SDL_AcquireGPUSwapchainTexture(cb, pf_window(), &swt, &sw, &sh) || !swt || !r_targets((int)rp[4], (int)rp[5])) {
    SDL_SubmitGPUCommandBuffer(cb); return -1;
  }
  if (n > R_MAX_DRAWS) n = R_MAX_DRAWS;   /* ponytail: fixed capacity, grow the buffer if a scene needs more */
  /* uploads: WebGPU pseudo-maps upload transfer buffers in CPU memory and copies them with
     queue.writeBuffer inside SDL_UploadToGPUBuffer, so reusing r_dyn without cycling is safe
     (cycle=true would memset all 2.6 MB every frame). */
  Uint8 *m = SDL_MapGPUTransferBuffer(r_dev, r_dyn, false);
  Uint32 sz[5] = { (Uint32)n * R_DQ * 4, (Uint32)nfa * 4, (Uint32)nfb * 4, (Uint32)nui * 4, (Uint32)nft * 4 };
  Uint32 offs[5] = { 0, R_OFF_FX0, R_OFF_FX1, R_OFF_UI, R_OFF_FX2 };
  const void *srcs[5] = { dq, fxa, fxb, ui, fxt }; SDL_GPUBuffer *dsts[5] = { r_draws, r_fx[0], r_fx[1], r_uib, r_fx[2] };
  for (int i = 0; i < 5; i++) if (sz[i]) SDL_memcpy(m + offs[i], srcs[i], sz[i]);
  SDL_UnmapGPUTransferBuffer(r_dev, r_dyn);
  SDL_GPUCopyPass *cp = SDL_BeginGPUCopyPass(cb);
  for (int i = 0; i < 5; i++) if (sz[i]) {
    SDL_GPUTransferBufferLocation l = { r_dyn, offs[i] }; SDL_GPUBufferRegion r = { dsts[i], 0, sz[i] };
    SDL_UploadToGPUBuffer(cp, &l, &r, false);
  }
  SDL_EndGPUCopyPass(cp);
  /* scene: sky, opaque (+ ink hulls), transparent, toon fx, fx; MSAA resolves into r_scene */
  SDL_PushGPUVertexUniformData(cb, 0, fu, R_FU * 4);
  SDL_PushGPUFragmentUniformData(cb, 0, fu, R_FU * 4);
  SDL_GPUColorTargetInfo ct = {0};
  ct.texture = r_samples > 1 ? r_msaa_tex : r_scene; ct.resolve_texture = r_samples > 1 ? r_scene : NULL;
  ct.load_op = SDL_GPU_LOADOP_CLEAR; ct.store_op = r_samples > 1 ? SDL_GPU_STOREOP_RESOLVE : SDL_GPU_STOREOP_STORE;
  SDL_GPUDepthStencilTargetInfo dt = {0};
  dt.texture = r_depth; dt.clear_depth = 1; dt.load_op = SDL_GPU_LOADOP_CLEAR; dt.store_op = SDL_GPU_STOREOP_DONT_CARE;
  dt.stencil_load_op = SDL_GPU_LOADOP_DONT_CARE; dt.stencil_store_op = SDL_GPU_STOREOP_DONT_CARE;
  SDL_GPURenderPass *pass = SDL_BeginGPURenderPass(cb, &ct, 1, &dt);
  SDL_BindGPUGraphicsPipeline(pass, r_pipe[rp[10] != 0 ? RP_SKY_TOON : RP_SKY]); SDL_DrawGPUPrimitives(pass, 3, 1, 0, 0);
  r_tris = 0;
  int drawn = r_draw_queue(pass, dq, n, 0) + r_draw_queue(pass, dq, n, 1);
  r_draw_batch(pass, RP_FXT, r_fx[2], nft / 9);
  r_draw_batch(pass, RP_FXA, r_fx[0], nfa / 9);
  r_draw_batch(pass, RP_FXB, r_fx[1], nfb / 9);
  SDL_EndGPURenderPass(pass);
  /* bloom: bright pass at 1/2, separable blur at 1/2 and 1/4 */
  int bloom = rp[0] != 0, hw = r_fw / 2 > 0 ? r_fw / 2 : 1, hh = r_fh / 2 > 0 ? r_fh / 2 : 1, qw = r_fw / 4 > 0 ? r_fw / 4 : 1, qh = r_fh / 4 > 0 ? r_fh / 4 : 1;
  if (bloom) {
    r_fs_pass(cb, r_half[0], RP_BRIGHT, &r_scene, 1, rp[1], 0, 0, 0, 0);
    r_fs_pass(cb, r_half[1], RP_BLUR, &r_half[0], 1, 1.0f / hw, 0, 0, 0, 0);
    r_fs_pass(cb, r_half[0], RP_BLUR, &r_half[1], 1, 0, 1.0f / hh, 0, 0, 0);
    r_fs_pass(cb, r_q[0], RP_BLUR, &r_half[0], 1, 1.0f / qw, 0, 0, 0, 0);
    r_fs_pass(cb, r_q[1], RP_BLUR, &r_q[0], 1, 0, 1.0f / qh, 0, 0, 0);
  }
  /* composite to the swapchain, then the UI on top in the same pass */
  SDL_GPUTexture *src[3] = { r_scene, r_half[0], r_q[1] };
  if (rp[11] != 0) {   /* impact frame / spot-keep grade: RP_COMP_FX with 4 vec4 (the RP_COMP lane, mode + params, ink + keep-hue-2, paper) */
    SDL_GPUColorTargetInfo sct = {0};
    sct.texture = swt; sct.load_op = SDL_GPU_LOADOP_DONT_CARE; sct.store_op = SDL_GPU_STOREOP_STORE;
    pass = SDL_BeginGPURenderPass(cb, &sct, 1, NULL);
    SDL_GPUTextureSamplerBinding b[3]; float u[16] = { bloom ? rp[2] : 0.0f, rp[3], rp[8], rp[7] > 0 ? rp[9] / rp[7] : 0.0f,
      rp[11], rp[12], rp[13], rp[14], rp[15], rp[16], rp[17], rp[21], rp[18], rp[19], rp[20], 0 };
    for (int i = 0; i < 3; i++) { b[i].texture = src[i]; b[i].sampler = r_linear; }
    SDL_BindGPUGraphicsPipeline(pass, r_pipe[RP_COMP_FX]);
    SDL_BindGPUFragmentSamplers(pass, 0, b, 3);
    SDL_PushGPUFragmentUniformData(cb, 0, u, sizeof u);
    SDL_DrawGPUPrimitives(pass, 3, 1, 0, 0);
  } else
    pass = r_fs_pass(cb, swt, RP_COMP, src, 3, bloom ? rp[2] : 0.0f, rp[3], rp[8], rp[7] > 0 ? rp[9] / rp[7] : 0.0f, 1);
  if (nui > 0) {
    float s[4] = { rp[6], rp[7], 0, 0 }; SDL_GPUTextureSamplerBinding fb = { r_font, r_nearest }; SDL_GPUBufferBinding b = { r_uib, 0 };
    SDL_BindGPUGraphicsPipeline(pass, r_pipe[RP_UI]);
    SDL_BindGPUVertexBuffers(pass, 0, &b, 1);
    SDL_BindGPUFragmentSamplers(pass, 0, &fb, 1);
    SDL_PushGPUVertexUniformData(cb, 0, s, sizeof s);
    SDL_DrawGPUPrimitives(pass, nui / 8, 1, 0, 0);
  }
  SDL_EndGPURenderPass(pass);
  SDL_SubmitGPUCommandBuffer(cb);
  return drawn;
}
/* Frame timing, called once per END-FRAME. When LOG is set, logs the startup time (page load to
   first frame) once and a perf line every ~5 s. With AUTO set it adapts a quality level 0..MAXLEVEL (0 = best) and returns it:
   1 s windows; a window averaging > 1.25 x BUDGET ms steps down one level, 3 windows in a row under
   BUDGET step back up. A step down within 4 s of a step up locks step-ups for a backoff that doubles
   (10 s .. 120 s), so it settles instead of oscillating. */
static double r_t_prev, r_t_first, r_t_win, r_t_log, r_t_up, r_t_lock;
static float r_backoff = 10.0f, r_win_sum, r_log_sum, r_log_max;
static int r_win_n, r_log_n, r_ok_wins, r_level;
int r_timing(int autoscale, float budget, float smin, int log, int draws, int tris, float scale, int plights) {
  double t = emscripten_get_now();
  if (r_t_first == 0) { r_t_first = r_t_prev = r_t_win = r_t_log = t;
    if (log) printf("perf: first frame at %.0f ms after page load\n", t); return r_level; }
  float dt = (float)(t - r_t_prev); r_t_prev = t;
  if (dt < 250.0f) { r_win_sum += dt; r_win_n++; }      /* ignore stalls (hidden tab, GC, resize) */
  r_log_sum += dt; r_log_n++; if (dt > r_log_max) r_log_max = dt;
  int maxlevel = (int)((1.0f - smin) * 10.0f + 0.5f) + 2;  /* resolution steps + 2 light steps */
  if (!autoscale) r_level = 0;
  if (t - r_t_win >= 1000.0) {
    if (autoscale && r_win_n > 0) {
      float avg = r_win_sum / r_win_n;
      if (avg > budget * 1.25f && r_level < maxlevel) {
        if (t - r_t_up < 4000.0) { r_t_lock = t + r_backoff * 1000.0; r_backoff = fminf(r_backoff * 2.0f, 120.0f); }
        r_level++; r_ok_wins = 0;
      } else if (avg < budget) {
        if (++r_ok_wins >= 3 && r_level > 0 && t >= r_t_lock) { r_level--; r_t_up = t; r_ok_wins = 0; }
      } else r_ok_wins = 0;
    }
    r_win_sum = 0; r_win_n = 0; r_t_win = t;
  }
  if (t - r_t_log >= 5000.0) {
    if (log) printf("perf: startup %.0f ms | frame %.1f ms avg (%.1f fps) max %.1f | render-scale %.2f pixel-lights %d | draws %d tris %d\n",
                    r_t_first, r_log_sum / r_log_n, 1000.0f * r_log_n / r_log_sum, r_log_max, scale, plights, draws, tris);
    r_log_sum = r_log_max = 0; r_log_n = 0; r_t_log = t;
  }
  return r_level;
}

int r_tri_count(void) { return r_tris; }   /* triangles drawn by the last r_frame */
