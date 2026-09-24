/* main.c — program entry. Boots ECL, loads the compiled Lisp, then drives the engine from the
   browser's animation-frame loop: ENGINE::%INIT-STEP once per frame until startup is done, then
   ENGINE::%FRAME every frame (both in engine/lisp/app.lisp). Also: the page hooks (loading %,
   fatal error) and the queue behind the JS debug hook Module._debug_cmd(n). Knows nothing about
   the game: a game registers itself with RUN-GAME. */
#include <ecl/ecl.h>
#include "engine/c/engine.h"

extern void init_game(cl_object);   /* the Lisp library's init function (tools/build.lisp) */

static cl_object frame_sym, init_sym;
static int init_done = 0;

/* ponytail: wasm locals are invisible to Boehm GC (no ASYNCIFY), so GC is
   disabled while Lisp runs and only collected here, between frames, when the
   stack holds no Lisp pointers. Budget = bytes consed before a collection. */
#define GC_BUDGET (24u << 20)

static void collect(void) { GC_enable(); GC_gcollect(); GC_disable(); }

/* EM_JS, not EM_ASM: frame() uses setjmp (ECL_CATCH_ALL), which clang can't mix with EM_ASM. */
EM_JS(void, m_stopped, (void), { if (Module.engineFatal) Module.engineFatal('the main loop stopped unexpectedly'); });
EM_JS(void, m_heap_log, (int heap), {
  console.log('startup: heap ' + (heap / 1048576).toFixed(1) + ' MB, wasm memory ' + (HEAP8.length / 1048576).toFixed(1) + ' MB');
});

/* Loading progress and fatal errors go to the page (engine/web/shell.html hooks; plain console otherwise). */
EM_JS(void, m_loading, (int pct), { if (Module.engineLoading) Module.engineLoading(pct); });
EM_JS(void, m_fatal, (const char *msg), {
  var m = UTF8ToString(msg); console.error(document.title + ' stopped: ' + m);
  if (Module.engineFatal) Module.engineFatal(m); else if (Module.setStatus) Module.setStatus('error: ' + m);
});
void engine_loading(int pct) { m_loading(pct); }
void engine_fatal(const char *msg) { m_fatal(msg); }

/* Test hook: Module._debug_cmd(n) queues n; the engine hands each one to the game's debug handler
   at the start of the next frame (RUN-FRAME, engine/lisp/app.lisp). */
static int dbg_cmds[16], dbg_n = 0;
EMSCRIPTEN_KEEPALIVE void debug_cmd(int c) { if (dbg_n < 16) dbg_cmds[dbg_n++] = c; }
int debug_take_cmd(void) {
  int c = 0, i;
  if (dbg_n > 0) { c = dbg_cmds[0]; for (i = 1; i < dbg_n; i++) dbg_cmds[i-1] = dbg_cmds[i]; dbg_n--; }
  return c;
}

static void frame(void)
{
  cl_env_ptr env = ecl_process_env();
  int ok = 0;
  if (!init_done) {
    /* startup runs one %INIT-STEP per frame (page stays responsive, loading bar
       advances) with a full collection after each, so meshgen / synthesis garbage
       never piles up: peak heap stays near the live set. 1 = more, 0 = done, 2 = failed. */
    int r = 2;
    ECL_CATCH_ALL_BEGIN(env) {
      cl_object v = cl_funcall(1, init_sym);
      r = ECL_FIXNUMP(v) ? ecl_fixnum(v) : 2;
    } ECL_CATCH_ALL_END;
    collect();
    if (r == 2) { emscripten_cancel_main_loop(); return; }
    if (r == 0) {
      init_done = 1;
      m_heap_log((int)GC_get_heap_size());
    }
    return;
  }
  ECL_CATCH_ALL_BEGIN(env) {
    ok = cl_funcall(1, frame_sym) != ECL_NIL;
  } ECL_CATCH_ALL_END;
  if (!ok) { m_stopped(); emscripten_cancel_main_loop(); return; }
  if (GC_get_bytes_since_gc() > GC_BUDGET) collect();
}

int main(int argc, char **argv)
{
  cl_boot(argc, argv);
  GC_disable();
  ecl_init_module(NULL, init_game);
  collect();                           /* module load garbage (~67 MB) before anything else */
  frame_sym = ecl_make_symbol("%FRAME", "ENGINE");
  init_sym = ecl_make_symbol("%INIT-STEP", "ENGINE");
  ecl_register_root(&frame_sym);
  ecl_register_root(&init_sym);
  emscripten_set_main_loop(frame, 0, 0);
  return 0;
}
