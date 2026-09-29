;;;; Build the host-native, render-free SOUL DUEL for the sim gate (tools/simgate.py): the same Lisp sources as
;;;; ./build.sh duel (engine/MANIFEST then duel/MANIFEST, one compilation unit, as tools/build.lisp), compiled by the
;;;; 32-bit host ECL with gcc -m32 into one loadable .fas; the engine's C layer is tools/simgate/stubs.c (real random
;;;; streams, headless leaves). SSE float math, no contraction: single-float arithmetic rounds like wasm's f32.
;;;; Usage: ecl-host --norc --load tools/simgate/build.lisp -- <out.fas>
(require :cmp)
(defparameter *root* (truename (merge-pathnames "../../" (directory-namestring *load-truename*))))
(defun root (p) (namestring (merge-pathnames p *root*)))
(setf *default-pathname-defaults* *root*)          ; compile-time file reads (WGSL) are root-relative

(defun manifest (dir)
  (with-open-file (in (root (format nil "~a/MANIFEST" dir)))
    (loop for l = (read-line in nil) while l
          for s = (string-trim " " l)
          when (and (plusp (length s)) (char/= (char s 0) #\#) (search ".lisp" s)) collect (format nil "~a/~a" dir s))))

(setf c::*cc-flags* (format nil "~a -msse2 -mfpmath=sse -ffp-contract=off -I~a -I~a -I~a" c::*cc-flags*
                            (root "tools/simgate/include") (namestring *root*) (root "vendor/sdl3-webgpu/include")))

(let* ((out (root (second (member "--" ext:*command-args* :test #'string=))))
       (unit (concatenate 'string (directory-namestring out) "simgate-all.lisp")))
  (ensure-directories-exist out)
  (with-open-file (o unit :direction :output :if-exists :supersede)
    (dolist (f (append (manifest "engine") (manifest "duel")))
      (format o "~&;;;; ---- ~a~%" f)
      (with-open-file (in (root f))
        (loop for line = (read-line in nil) while line do (write-line line o))))
    (format o "~&;;;; ---- the sim gate's C layer and its debug queue~%(in-package :engine)~%~
               (ffi:clines \"#include \\\"tools/simgate/stubs.c\\\"\")~%~
               (defun simgate-cmd (c) (ffi:c-inline (c) (:int) :void \"debug_cmd(#0)\" :one-liner t))~%"))
  (setf ext:*register-with-pde-hook* nil si::*keep-documentation* nil)
  (ext:quit (if (compile-file unit :output-file out) 0 1)))
