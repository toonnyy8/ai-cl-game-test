;;;; package.lisp — the ENGINE package and its public API (the export list below, grouped by file),
;;;; global compiler policy, and the small numeric helpers every other file uses: DEFUN-FAST,
;;;; the F-* float macros (plain C math, no boxing) and the random numbers RND01 / RND-RANGE and
;;;; SIM-RND01 / SIM-RND-RANGE.
;;;; A game is its own package that uses this one: (defpackage :my-game (:use :cl :engine)).
(defpackage :engine
  (:use :cl)
  (:export
   ;; package.lisp: types, compiler helpers, float math in C, random numbers, logging
   #:f32 #:f32vec #:f32vec-p #:clamp #:lerp #:log-msg #:defun-fast
   #:f-min #:f-max #:f-abs #:f-sqrt #:f-sin #:f-cos #:f-atan2 #:f-mod #:f-acos #:f-asin #:f-clamp
   #:i->f #:f->i #:f-wrap #:rnd01 #:rnd-range #:rnd-seed #:rnd-state
   #:sim-rnd01 #:sim-rnd-range #:sim-rnd-seed #:sim-rnd-state
   ;; math.lisp: vec3 / mat4 on f32vecs (! = writes into its first argument)
   #:fv #:make-f32 #:deg #:angle-wrap #:angle-lerp #:approach #:smoothstep
   #:fwd-x #:fwd-z #:yaw-to #:turn-toward #:weighted-pick
   #:v3 #:v3-set! #:v3-copy! #:v3-copy #:v3-add! #:v3-sub! #:v3-scale! #:v3-madd! #:v3-lerp! #:v3-cross!
   #:v3-normalize! #:v3-normalize #:v3-dot #:v3-len #:v3-len2 #:v3-dist
   #:m4 #:m4-identity! #:m4-copy! #:m4-mul! #:m4-translation! #:m4-euler! #:m4-perspective! #:m4-look-at!
   #:m4-invert! #:m4-transform-point! #:m4-transform-dir! #:xform
   ;; hitvol.lisp: hit volumes vs hurt cylinders (plain CL)
   #:make-vol #:vol-hit-p #:capsule-cyl-hit-p #:obox-cyl-hit-p #:cyl-cyl-hit-p
   ;; input.lisp: the virtual controller (vpad), command tables, device bindings (plain CL)
   #:vpad #:vpad-p #:make-vpad #:vpad-actions #:vpad-tick #:vpad-sx #:vpad-sy #:vpad-reader
   #:vpad-downs #:vpad-press #:vpad-modded
   #:vpad-begin-step! #:vpad-set! #:vpad-stick! #:vpad-clear! #:vpad-flush! #:vpad-down #:vpad-held
   #:vpad-pressed #:vpad-modded-p #:vpad-consume! #:vpad-stamp! #:vpad-hold! #:vpad-command-pressed-p #:vpad-command
   #:inputs-down-p #:vpad-read!
   ;; touch.lisp: the one-thumb gesture recogniser (plain CL); platform.lisp feeds it (TOUCH-POLL)
   #:make-touch #:touch #:touch-layout! #:touch-feed! #:touch-take! #:touch-pulse-p #:touch-resting-p
   #:touch-step-held-p #:touch-flick-down-p #:touch-sx #:touch-sy #:touch-chip-down-p #:touch-chip-hit-p
   #:touch-tapped-p #:touch-tap-x #:touch-tap-y #:touch-rest-up-ok #:touch-up-hoho #:touch-spend! #:touch-flick-hold #:touch-rested
   #:touch-active-p #:touch-ox #:touch-oy #:touch-glyph #:touch-glyph-t #:touch-glyph-x #:touch-glyph-y #:touch-cfg #:touch-dpx
   #:+tp-tap+ #:+tp-flick+ #:+tp-tap-hi+ #:+tp-hoho+ #:touch-split-y
   #:gesture-config #:make-gesture-config #:gc-tap-ms #:gc-slop #:gc-flick-min #:gc-flick-window #:gc-up-cone #:gc-tap-split
   #:gc-stick-r #:gc-run-ring #:gc-run-release #:gc-recenter #:gc-chip-slop #:gc-menu-tap-ms
   ;; platform.lisp: window, time, input
   #:platform-init #:platform-poll #:*max-dt* #:window-width #:window-height #:window-aspect
   #:frame-dt #:raw-dt #:elapsed-time #:fps
   #:key-down #:key-pressed #:mouse-down #:mouse-pressed #:mouse-dx #:mouse-dy #:mouse-wheel
   #:pointer-locked-p #:focus-lost-p #:*pointer-lock*
   #:pixel-density #:touch-poll #:page-get #:page-set
   #:pad-count #:pad-connected-p #:pad-down #:pad-pressed #:pad-lx #:pad-ly #:pad-rx #:pad-ry #:pad-lt #:pad-rt
   ;; render.lisp: meshes, camera, look, frame, lights, fx batch
   #:wgsl #:mesh #:mesh-p #:mesh-id #:mesh-count #:make-mesh #:+vertex-floats+
   #:camera #:*camera* #:make-camera #:camera-pos #:camera-target #:camera-up #:camera-shake #:camera-fov #:camera-shift-y
   #:camera-near #:camera-far #:camera-eye #:camera-right #:camera-upv #:camera-forward #:camera-view
   #:camera-proj #:camera-view-proj #:camera-inv-view-proj #:update-camera #:camera-look-at #:world-to-screen
   #:environment #:*env* #:make-environment #:env-sky-top #:env-fog-color #:env-fog-density #:env-fog-base
   #:env-fog-falloff #:env-fog-max #:env-ambient-sky #:env-ambient-ground #:env-ambient-intensity
   #:env-moon-dir #:env-moon-color #:env-moon-intensity #:env-rim-color #:env-rim-intensity #:env-rim-power
   #:env-specular #:env-shininess #:env-exposure #:env-bloom #:env-bloom-threshold #:env-bloom-strength
   #:env-vignette #:env-sun-size #:env-sun-glow #:*grade-desat* #:*grade-split*
   #:env-toon #:env-key-light #:env-toon-threshold #:env-toon-band #:env-toon-gradient #:env-toon-gradient-height
   #:env-toon-light-gain #:env-shade-value #:env-shade-saturation #:env-shade-hue #:env-shade-lift
   #:env-cin-rim #:env-cin-width #:*grade-impact* #:*impact-params* #:grade-impact #:*fx-clock*
   #:*render-scale* #:*scene-scale-cap* #:*auto-render-scale* #:*render-scale-min* #:*frame-budget-ms* #:*pixel-lights* #:*perf-log*
   #:*draw-count* #:*tri-count* #:*fx-alpha* #:*fx-add* #:*fx-toon* #:*fx-dropped*
   #:stream-buffer #:stream-buffer-data #:stream-buffer-fill #:stream-buffer-stride #:stream-room-p
   #:engine-init #:begin-frame #:end-frame #:draw-mesh #:add-point-light #:add-point-light-v
   #:with-fx-verts #:vtx #:fx-billboard #:fx-line #:fx-trail #:fx-decal
   ;; meshgen.lisp: procedural meshes
   #:mesh-builder #:make-mesh-builder #:mb-jitter #:mb-cur-color #:mb-xform #:build-mesh #:mb-build #:with-xform
   #:mb-color #:mbc #:hexc #:mb-quad #:mb-poly-out #:mb-box #:mb-bevel-box #:mb-cylinder #:mb-cone #:mb-prism
   #:mb-sphere #:mb-capsule #:mb-wedge #:mb-plane #:mb-blade #:mb-hull #:mb-tube #:mb-flat-quad #:rim-vec
   ;; ui.lisp: 2D UI batch and bitmap text
   #:+font-5x7+ #:*ui-min-css* #:*ui-text-min* #:ui-scale #:fit-scale #:ui-rect #:ui-gradient #:ui-rect-outline #:ui-bar #:%ui-poly4
   #:with-ui-verts #:uvtx
   #:ui-block-text #:ui-big-text #:ui-bitmap #:text-width #:ui-text
   ;; audio.lisp: synthesis toolkit, DEFSOUND, playback
   #:+au-rate+ #:+au-dt+ #:tt #:au-rnd #:au-frac #:au-expf #:au-powf #:au-sin #:au-saw #:au-sqr #:au-ph+
   #:au-env-exp #:au-ar #:au-adsr #:au-sweep #:au-rrange #:au-midi #:au-buf #:au-render #:au-peak #:au-scale!
   #:au-normalize! #:au-mix! #:au-svf! #:au-onepole! #:au-drive! #:au-delay! #:au-reverb! #:au-fold
   #:au-noise #:au-fnoise #:au-whoosh #:au-ping! #:au-partials! #:au-thump! #:au-taiko! #:au-gong!
   #:au-shaku! #:au-saws! #:defsound #:*audio-debug*
   #:play-sfx #:play-sfx-at #:sfx-at #:start-loop #:stop-loop #:set-loop-gain #:set-music-volume
   #:music-playing-p #:music-play #:music-stop #:music-intensify #:audio-stats #:audio-locked-p
   #:list-sounds #:sound-loop-p
   ;; anim.lisp: humanoid rig, pose / clip DSL, playback, forward kinematics
   #:ji #:joint-index #:joint-mask #:+nj+ #:+pose-n+ #:+root+ #:defpose #:find-pose #:defclip #:defstrike #:find-clip
   #:clip #:clip-name #:clip-dur #:clip-loop #:clip-sample! #:clip-mark #:list-clips #:build-clip #:*key-ease*
   #:anim #:make-anim #:anim-clip #:anim-time #:anim-speed #:anim-blend #:anim-pose #:anim-play #:anim-advance #:anim-eval
   #:pose-fk! #:make-rig-proportions #:joint-point!
   ;; body.lisp: rigid-part characters (shape spec -> meshes per joint, drawing)
   #:pal-rgb #:build-parts #:draw-parts #:*part-jitter* #:*part-smooth*
   ;; time.lisp: fixed step, hitstop, slow motion
   #:+step+ #:*tick* #:*hitstop* #:*hitstop-mult* #:hitstop #:slowmo #:slowmo-scale #:time-step #:time-reset
   #:run-fixed-steps #:*step-acc*
   ;; fx.lisp: shake, particles, rings, debris, trails, screen-edge vignette
   #:*shake-mult* #:*shake-hz* #:shake #:shake-update
   #:+p-mist+ #:+p-spark+ #:+p-dust+ #:+p-orb-a+ #:+p-orb-b+ #:+p-feather+ #:+p-glow+ #:+p-flame+
   #:*plive* #:*orb-target* #:*on-orb-absorbed* #:fx-emit #:fx-burst #:fx-update #:fx-draw-particles
   #:fx-clear-orbs #:fx-clear #:fx-ring #:fx-rings-update #:*debris-life* #:fx-debris #:fx-debris-update #:fx-clear-debris
   #:+trail-n+ #:make-trail #:trail-count #:trail-push #:trail-decay #:edge-vignette
   #:draw-circle #:draw-vol #:fx-ribbon #:fx-sector
   ;; fx.lisp, toon effects (docs/style/STYLE_STORM_DESIGN.md §3): fx clock, palettes, envelope, shapes, toon
   ;; particle kinds, screen punctuation
   #:fx-clock #:fx-clock-advance #:sage #:toon-a #:fx-envelope #:fx-disc #:fx-star #:fx-shard #:fx-crescent #:fx-wall
   #:+pal-fire+ #:+pal-ember+ #:+pal-reiatsu+ #:+pal-ink+ #:+pal-steel+ #:+pal-hit+ #:+pal-smoke+ #:+pal-dust+
   #:+pal-ash+ #:+pal-soul+ #:+pal-blood+ #:+pal-black-smoke+ #:+pal-blue+ #:+p-t-blob+ #:+p-t-shard+
   #:ui-focus-lines #:ui-speed-lines #:ui-ink-splash
   ;; cine.lisp: the cinematic director (scripted cutscenes inside the fixed step)
   #:defcine #:cine #:*cine* #:cine-name #:cine-cf #:cine-a #:cine-v #:cine-hold #:cine-hold-frame
   #:start-cine #:end-cine #:abort-cine #:skip-cine #:cine-step #:cine-draw #:cine-cam
   #:*cine-cam* #:*cine-eye* #:*cine-target* #:*skip-cines* #:*cine-hold*
   #:*cine-begin-hook* #:*cine-actor-hook* #:*cine-end-hook*
   ;; ecs.lisp: entities, components, systems, events
   #:+max-entities+ #:defcomponent #:spawn-entity #:destroy-entity #:entity-alive-p #:add-component
   #:remove-component #:clear-entities #:do-entities #:emit #:take-events
   ;; app.lisp: game registration and the frame driver
   #:run-game #:perf-mark #:*stats-log* #:cons-per-frame #:cons-bytes #:now-ms))
(in-package :engine)

(declaim (optimize (speed 3) (safety 1) (debug 0)))

(deftype f32 () 'single-float)
(deftype f32vec () '(simple-array single-float (*)))

(declaim (inline clamp lerp f32))
(defun f32 (x) (coerce x 'single-float))
(defun clamp (x lo hi) (max lo (min hi x)))
(defun lerp (a b u) (+ a (* (- b a) u)))

(defun log-msg (fmt &rest args)
  "Print a line to the browser console."
  (apply #'format t fmt args)
  (terpri)
  (finish-output))

(declaim (inline f32vec-p))
(defun f32vec-p (x) (and (vectorp x) (eq (array-element-type x) 'single-float)))

(defmacro defun-fast (name args &body body)
  "DEFUN for hot numeric code. ECL 24.5 at (safety 1) evaluates LET initializers with boxed,
consing generic arithmetic even when the variable is declared single-float; at (safety 0) it
emits plain C float math. So the type-declared arguments are checked on entry (cheaply:
single-float/fixnum tag tests, F32VEC-P for f32vec), then re-bound under (safety 0) and BODY
runs there. Declare every float local inside BODY."
  (let* ((doc (when (and (stringp (first body)) (rest body)) (list (pop body))))
         (decls (loop while (and (consp (first body)) (eq (car (first body)) 'declare))
                      append (cdr (pop body))))
         (typed (remove-if-not (lambda (d) (member (car d) '(type single-float fixnum))) decls))
         (other (set-difference decls typed))
         (checks (loop for d in typed
                       for (type . vars) = (if (eq (car d) 'type) (cdr d) (cons (car d) (cdr d)))
                       append (loop for v in vars
                                    collect `(unless ,(if (eq type 'f32vec) `(f32vec-p ,v) `(typep ,v ',type))
                                               (error 'type-error :datum ,v :expected-type ',type)))))
         (vars (remove-duplicates (loop for d in typed append (if (eq (car d) 'type) (cddr d) (cdr d))))))
    `(defun ,name ,args ,@doc
       ,@(when other `((declare ,@other)))
       ,@checks
       (let* ,(mapcar (lambda (v) (list v v)) vars)
         (declare (optimize (speed 3) (safety 0)) ,@typed)
         ,@body))))

;;; ---------------------------------------------------------------- fast float helpers
;;; (ECL: float min/max/abs/sin are generic calls; these compile to plain C.)
(defmacro f-min (a b) `(ffi:c-inline (,a ,b) (:float :float) :float "fminf(#0,#1)" :one-liner t))
(defmacro f-max (a b) `(ffi:c-inline (,a ,b) (:float :float) :float "fmaxf(#0,#1)" :one-liner t))
(defmacro f-abs (a) `(ffi:c-inline (,a) (:float) :float "fabsf(#0)" :one-liner t))
(defmacro f-sqrt (a) `(ffi:c-inline (,a) (:float) :float "sqrtf(fmaxf(#0,0.0f))" :one-liner t))
(defmacro f-sin (a) `(ffi:c-inline (,a) (:float) :float "sinf(#0)" :one-liner t))
(defmacro f-cos (a) `(ffi:c-inline (,a) (:float) :float "cosf(#0)" :one-liner t))
(defmacro f-atan2 (y x) `(ffi:c-inline (,y ,x) (:float :float) :float "atan2f(#0,#1)" :one-liner t))
(defmacro f-mod (x y) `(ffi:c-inline (,x ,y) (:float :float) :float "fmodf(#0,#1)" :one-liner t))
(defmacro f-acos (x) `(ffi:c-inline (,x) (:float) :float "acosf(fmaxf(-1.0f,fminf(1.0f,#0)))" :one-liner t))
(defmacro f-asin (x) `(ffi:c-inline (,x) (:float) :float "asinf(fmaxf(-1.0f,fminf(1.0f,#0)))" :one-liner t))
(defmacro f-clamp (x lo hi) `(f-min (f-max ,x ,lo) ,hi))
(defmacro i->f (i) `(ffi:c-inline (,i) (:int) :float "(float)(#0)" :one-liner t))
(defmacro f->i (x) "floor to int" `(ffi:c-inline (,x) (:float) :int "(int)floorf(#0)" :one-liner t))
(defmacro f-wrap (a) "angle into [-pi,pi)" `(ffi:c-inline (,a) (:float) :float
                                              "((#0)-6.2831853f*floorf(((#0)+3.14159265f)*0.15915494f))" :one-liner t))

;;; ---------------------------------------------------------------- random numbers
;;; xorshift32 in C (engine/c/engine.h, rng.c): 30-bit fixnums make a Lisp LCG cons bignums.
;;; Two independent streams. Rule: gameplay / AI randomness uses SIM-RND01 and only inside fixed
;;; steps, so a seed (SIM-RND-SEED) replays the same match whatever the frame rate or particle count;
;;; cosmetics (fx, shake, sound pitch) use RND01, which runs per frame and per particle.
(defmacro rnd01 () "uniform [0,1), no consing" `(ffi:c-inline () () :float "rng_float()" :one-liner t))
(defmacro rnd-range (a b) "Uniform [A,B). A is evaluated twice: pass plain values." `(+ ,a (* (- ,b ,a) (rnd01))))
(defmacro sim-rnd01 () "uniform [0,1) from the simulation stream, no consing"
  `(ffi:c-inline () () :float "rng2_float()" :one-liner t))
(defmacro sim-rnd-range (a b) "Uniform [A,B) from the sim stream. A is evaluated twice: pass plain values." `(+ ,a (* (- ,b ,a) (sim-rnd01))))

;; Seeding and state. A seed is any fixnum (hashed in C, so 1 2 3 start far apart). The state is the
;; raw 32-bit generator word, 1..2^32-1: above 2^29 it is a bignum, so read it for save / restore /
;; determinism checks, not per frame. (SETF (SIM-RND-STATE) s) restores a state read earlier.
(defun rnd-seed (n) "Restart the RND01 stream from seed N." (ffi:c-inline (n) (:int) :void "rng_seed(&rng_state,#0)" :one-liner t))
(defun sim-rnd-seed (n) "Restart the SIM-RND01 stream from seed N." (ffi:c-inline (n) (:int) :void "rng_seed(&rng2_state,#0)" :one-liner t))
(defun rnd-state () (ffi:c-inline () () :unsigned-int "rng_state" :one-liner t))
(defun sim-rnd-state () (ffi:c-inline () () :unsigned-int "rng2_state" :one-liner t))
(defun (setf rnd-state) (s) (ffi:c-inline (s) (:unsigned-int) :void "rng_state = #0 ? #0 : 1u" :one-liner t) s)
(defun (setf sim-rnd-state) (s) (ffi:c-inline (s) (:unsigned-int) :void "rng2_state = #0 ? #0 : 1u" :one-liner t) s)
