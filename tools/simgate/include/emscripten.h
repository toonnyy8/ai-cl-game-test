/* emscripten.h for the host-native sim gate (tools/simgate): engine/c/engine.h includes it; the only
   emscripten call the Lisp side makes is emscripten_get_now (NOW-MS), defined in tools/simgate/stubs.c. */
double emscripten_get_now(void);
