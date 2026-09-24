;;;; Cross-compile the Lisp sources (engine + target) -> C -> wasm objects with the 32-bit host ECL,
;;;; then bundle them into <outdir>/libgame.a (init function: init_game, called by engine/c/main.c).
;;;; Usage: ecl-host --norc --load tools/build.lisp -- <outdir> <file.lisp>...   (root-relative paths)
(require :cmp)
(defparameter *root* (truename (merge-pathnames "../" (directory-namestring *load-truename*))))
(defparameter *emsdk* (or (ext:getenv "EMSCRIPTEN") "/media/8tsp/projects/emsdk/upstream/emscripten/"))
(defun root (p) (namestring (merge-pathnames p *root*)))
;; compile-time file reads (the WGSL macro in engine/lisp/render.lisp) use root-relative paths
(setf *default-pathname-defaults* *root*)

(setf c::*cc* (concatenate 'string *emsdk* "/emcc")
      c::*ar* (concatenate 'string *emsdk* "/emar")
      c::*ranlib* (concatenate 'string *emsdk* "/emranlib")
      c::*ecl-include-directory* (root "vendor/ecl/include/")
      c::*cc-optimize* (or (ext:getenv "GAME_OPT") "-O2")
      ;; wasm libecl was built with this; mismatched variadic ABI traps on call_indirect
      ;; -I<root>: (ffi:clines "#include \"engine/c/engine.h\"") and game headers are root-relative
      c::*cc-flags* (format nil "-DECL_C_COMPATIBLE_VARIADIC_DISPATCH -Demscripten -Werror=implicit-function-declaration -Wno-int-conversion -Wno-incompatible-pointer-types -I~a -I~a"
                            (root "vendor/sdl3-webgpu/include") (namestring *root*)))

(let* ((args (cdr (member "--" ext:*command-args* :test #'string=)))
       (out (concatenate 'string (root (first args)) "/"))
       (files (rest args))
       (unit (concatenate 'string out "game-all.lisp"))
       (obj (concatenate 'string out "game-all.o")))
  ;; ponytail: one compilation unit (sources concatenated in order) so macros
  ;; and structs defined earlier are visible later without loading FFI code in
  ;; the host. Split into per-file objects if compile times hurt.
  (ensure-directories-exist obj)
  (with-open-file (out unit :direction :output :if-exists :supersede)
    (dolist (f files)
      (format out "~&;;;; ---- ~a~%" f)
      (with-open-file (in (root f))
        (loop for line = (read-line in nil) while line do (write-line line out)))))
  (unless (compile-file unit :output-file obj :system-p t)
    (ext:quit 1))
  (c:build-static-library (concatenate 'string out "game") :lisp-files (list obj) :init-name "init_game")
  (ext:quit 0))
