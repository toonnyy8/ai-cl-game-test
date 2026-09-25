;;;; vfx.lisp — SOUL DUEL's visual effects: fire (blade, wave, fireball, pillars, dome), auras,
;;;; ground cuts, sky split, hit sparks, Hoho, shatters, awakening bursts, and the UI helpers the
;;;; HUD / cinematics share (hand-authored kanji drawn with the engine's UI-BITMAP).
;;;; Everything is cosmetic: RND01 only (never SIM-RND01), no gameplay state.
;;;; Units: x y z metres (y up), YAW radians with forward = (-sin yaw, -cos yaw) (the duel/RAVEN
;;;; convention), AGE seconds since the effect started, LIFE its total seconds, DT real seconds of
;;;; this frame (particles are emitted at RATE x DT x *FIRE-DENSITY*).
;;;; Kinds of calls:
;;;;   per-frame looks  VFX-BLADE-FIRE … VFX-SOUL-FLAME: call every rendered frame while the thing
;;;;                    exists (after the camera is set, before END-FRAME). Bodies are fx quads
;;;;                    written with WITH-FX-VERTS (0 bytes consed); a few particles top them up.
;;;;   one-shots        VFX-HIT, VFX-HOHO, VFX-FIRE-CONE, VFX-KONPAKU-SHATTER, VFX-AWAKEN-BURST, VFX-SHOCKWAVE,
;;;;                    VFX-ASH-BURST, VFX-SKELETON-DUST: particles / rings once.
;;;;   lights           effects call ADD-POINT-LIGHT with a priority; LIGHTS-FLUSH once per
;;;;                    frame adds the hit flash.
;;;;   UI               UI-BITMAP, UI-KANJI, VFX-TENCHI-SLASH, VFX-SKY-SPLIT (screen space).
;;;; The frame still needs the engine's FX-UPDATE / FX-DRAW-PARTICLES / FX-RINGS-UPDATE.
;;;; Budgets (design §14): ≤ 1200 live particles (emission stops at +LIVE-CAP+), flame half-size
;;;; ≤ 0.35 m, bodies as quads; worst scene (Ennetsu + fire wave + Hellfire + blade + stage) is
;;;; measured by tests/duel-vfx.lisp.
(in-package :duel)

(defvar *fire-density* 1.0 "0..1: scales every VFX emission (tuning.lisp owns the value).")
(defconstant +live-cap+ 1150 "No new VFX particles while the pool holds this many (budget 1200).")

;;; ---------------------------------------------------------------- small hot-path helpers
(defmacro with-floats (vars &body body)
  "Rebind VARS as single-floats (callers may pass fixnums or doubles)."
  `(let* ,(mapcar (lambda (v) `(,v (f32 ,v))) vars)
     (declare (single-float ,@vars))
     ,@body))

(defmacro n-of (rate dt)
  "How many particles to emit this frame for RATE per second: floor(RATE·DT·density + U), so the
average is exact at any frame rate. 0 once the pool is near the budget."
  `(if (< *plive* +live-cap+) (f->i (+ (* ,rate ,dt (the single-float (f32 *fire-density*))) (rnd01))) 0))

(defmacro clock () "Real seconds (phase for flicker)." `(the single-float (f32 (elapsed-time))))

(defmacro hash01 (i seed)
  "Stable pseudo-random 0..1 of (I SEED) — for shapes that must not change every frame."
  `(f-mod (f-abs (* 43758.547f0 (f-sin (+ (* ,i 12.9898f0) (* ,seed 78.233f0))))) 1f0))

(defmacro flame (x y z vx vy vz life size r g b &optional (alpha 0.6f0))
  "One +P-FLAME+ particle (rises: negative gravity). Emit colour = the hot core. ALPHA < 1 keeps
dense flames from summing to white on the bright dusk sky (FX-EMIT's alpha scale)."
  `(fx-emit +p-flame+ ,x ,y ,z ,vx ,vy ,vz ,life ,size -3f0 ,r ,g ,b ,alpha))

(defmacro front-dim (x z ang)
  "0.25..1: how much of an aura layer at angle ANG around (x z) to keep — layers between the camera
and the body fade, so the fighter stays readable inside his aura (the silhouette ones stay full)."
  `(let* ((%e (camera-eye *camera*)) (%dx (- (aref %e 0) ,x)) (%dz (- (aref %e 2) ,z))
          (%l (f-max 0.01f0 (f-sqrt (+ (* %dx %dx) (* %dz %dz)))))
          (%d (/ (+ (* %dx (f-cos ,ang)) (* %dz (f-sin ,ang))) %l)))
     (declare (type f32vec %e) (single-float %dx %dz %l %d))
     (- 1f0 (* 0.75f0 (f-max 0f0 %d)))))

(defmacro with-cam (() &body body)
  "Bind RX RY RZ UX UY UZ (camera right / up) for %SPR."
  `(let* ((%rt (camera-right *camera*)) (%up (camera-upv *camera*)))
     (declare (type f32vec %rt %up) (ignorable %rt %up))
     (let* ((rx (aref %rt 0)) (ry (aref %rt 1)) (rz (aref %rt 2))
            (ux (aref %up 0)) (uy (aref %up 1)) (uz (aref %up 2)))
       (declare (single-float rx ry rz ux uy uz) (ignorable rx ry rz ux uy uz))
       ,@body)))

(defmacro %spr (x y z s r g b a &optional (mode :add))
  "Camera-facing round sprite inside WITH-CAM (a macro: no boxing). Negative A = no white core."
  `(let* ((%s ,s) (px ,x) (py ,y) (pz ,z) (cr ,r) (cg ,g) (cb ,b) (ca ,a)
          (sx (* %s rx)) (sy (* %s ry)) (sz (* %s rz)) (vx (* %s ux)) (vy (* %s uy)) (vz (* %s uz)))
     (declare (single-float %s px py pz cr cg cb ca sx sy sz vx vy vz))
     (with-fx-verts (d o ,mode 6)
       (vtx (- px sx vx) (- py sy vy) (- pz sz vz) -1f0 -1f0 cr cg cb ca)
       (vtx (- (+ px sx) vx) (- (+ py sy) vy) (- (+ pz sz) vz) 1f0 -1f0 cr cg cb ca)
       (vtx (+ px sx vx) (+ py sy vy) (+ pz sz vz) 1f0 1f0 cr cg cb ca)
       (vtx (- px sx vx) (- py sy vy) (- pz sz vz) -1f0 -1f0 cr cg cb ca)
       (vtx (+ px sx vx) (+ py sy vy) (+ pz sz vz) 1f0 1f0 cr cg cb ca)
       (vtx (+ (- px sx) vx) (+ (- py sy) vy) (+ (- pz sz) vz) -1f0 1f0 cr cg cb ca))))

(defmacro %gseg (x0 z0 x1 z1 y w r g b a mode &optional (soft t))
  "Flat ground strip (x0 z0)→(x1 z1) at height Y, half-width W; SOFT fades across its width."
  `(let* ((x0 ,x0) (z0 ,z0) (x1 ,x1) (z1 ,z1) (gy ,y) (w ,w) (cr ,r) (cg ,g) (cb ,b) (ca ,a)
          (dx (- x1 x0)) (dz (- z1 z0)) (l (f-sqrt (+ (* dx dx) (* dz dz)))) (e (if ,soft 1f0 0f0)))
     (declare (single-float x0 z0 x1 z1 gy w cr cg cb ca dx dz l e))
     (when (> l 1f-4)
       (let* ((nx (* w (/ (- dz) l))) (nz (* w (/ dx l))))
         (declare (single-float nx nz))
         (with-fx-verts (d o ,mode 6)
           (vtx (- x0 nx) gy (- z0 nz) 0f0 (- e) cr cg cb ca)
           (vtx (+ x0 nx) gy (+ z0 nz) 0f0 e cr cg cb ca)
           (vtx (+ x1 nx) gy (+ z1 nz) 0f0 e cr cg cb ca)
           (vtx (- x0 nx) gy (- z0 nz) 0f0 (- e) cr cg cb ca)
           (vtx (+ x1 nx) gy (+ z1 nz) 0f0 e cr cg cb ca)
           (vtx (- x1 nx) gy (- z1 nz) 0f0 (- e) cr cg cb ca))))))

(defmacro %gdisc (x y z s r g b a mode)
  "Soft flat disc of radius S at height Y (FX-DECAL without the boxed call)."
  `(let* ((px ,x) (gy ,y) (pz ,z) (%s ,s) (cr ,r) (cg ,g) (cb ,b) (ca ,a))
     (declare (single-float px gy pz %s cr cg cb ca))
     (with-fx-verts (d o ,mode 6)
       (vtx (- px %s) gy (- pz %s) -1f0 -1f0 cr cg cb ca) (vtx (+ px %s) gy (- pz %s) 1f0 -1f0 cr cg cb ca)
       (vtx (+ px %s) gy (+ pz %s) 1f0 1f0 cr cg cb ca) (vtx (- px %s) gy (- pz %s) -1f0 -1f0 cr cg cb ca)
       (vtx (+ px %s) gy (+ pz %s) 1f0 1f0 cr cg cb ca) (vtx (- px %s) gy (+ pz %s) -1f0 1f0 cr cg cb ca))))

(defmacro fire-tongue (x y z ax ay az w k ph sway &key (segs 6) (dark t) (core t) (taper 0.3f0))
  "A flame as 3-4 ribbon layers: dark-red underlay (alpha batch, so it reads on a bright sky),
orange body, yellow middle, white-hot core line (CORE). W = base half-width, TAPER = tip width /
base width, K = brightness 0..1."
  `(let* ((tx ,x) (ty ,y) (tz ,z) (tax ,ax) (tay ,ay) (taz ,az) (tw ,w) (tk ,k) (tph ,ph) (tsw ,sway))
     (declare (single-float tx ty tz tax tay taz tw tk tph tsw))
     (when ,dark
       (fx-ribbon tx ty tz (* 1.1f0 tax) (* 1.1f0 tay) (* 1.1f0 taz) (* 1.2f0 tw) (* (+ ,taper 0.2f0) tw)
               0.28f0 0.04f0 0.02f0 (* 0.5f0 tk) 0.16f0 0.03f0 0.02f0 (* 0.25f0 tk) tph tsw :segs ,segs :mode :alpha))
     (fx-ribbon tx ty tz tax tay taz tw (* ,taper tw) 1f0 0.33f0 0.04f0 (* -0.6f0 tk) 0.6f0 0.06f0 0.02f0 (* -0.3f0 tk)
             tph tsw :segs ,segs)
     (fx-ribbon tx ty tz (* 0.75f0 tax) (* 0.75f0 tay) (* 0.75f0 taz) (* 0.55f0 tw) (* 0.12f0 tw)
             1f0 0.6f0 0.15f0 (* -0.45f0 tk) 1f0 0.3f0 0.04f0 0f0 (+ tph 0.7f0) tsw :segs ,segs)
     (when ,core
       (fx-ribbon tx ty tz (* 0.45f0 tax) (* 0.45f0 tay) (* 0.45f0 taz) (* 0.2f0 tw) (* 0.05f0 tw)
               1f0 0.9f0 0.6f0 (* 0.35f0 tk) 1f0 0.6f0 0.2f0 0f0 (+ tph 1.3f0) (* 0.5f0 tsw) :segs ,segs))))

;;; ---------------------------------------------------------------- lights (engine priorities)
;;; Effects call ADD-POINT-LIGHT with a PRIORITY (its last argument): the engine keeps the 8 highest
;;; (then nearest). The stage's two fire lights use priority 10, so effects share the other 6. Priorities:
;;; 9 detonation / awakening burst, 8 awakening auras, 7 projectile, 6 hit flash, 5 charge /
;;; Breaker, 3-4 hazards.
(declaim (type f32vec *flash-light*))
(defvar *flash-light* (make-f32 8) "hit flash: x y z r g b start-time (real s)")

(defun lights-flush ()
  "Add the 0.15 s hit flash while it lasts. Call once per frame, before END-FRAME."
  (let* ((fl *flash-light*) (age (- (elapsed-time) (aref fl 6))))
    (when (< -0.001 age 0.15)
      (add-point-light (aref fl 0) (aref fl 1) (aref fl 2) (aref fl 3) (aref fl 4) (aref fl 5)
                       6.0 (* 2.0 (- 1.0 (/ age 0.15))) 6))
    nil))

(defun flash-light (x y z r g b)
  "Start the 0.15 s hit-flash light at (x y z)."
  (let ((fl *flash-light*))
    (setf (aref fl 0) (f32 x) (aref fl 1) (f32 y) (aref fl 2) (f32 z)
          (aref fl 3) (f32 r) (aref fl 4) (f32 g) (aref fl 5) (f32 b) (aref fl 6) (f32 (elapsed-time)))))

;;; ---------------------------------------------------------------- Yamamoto: blade fire / embers
(defun-fast vfx-blade-fire (x0 y0 z0 x1 y1 z1 dt &key (power 1.0))
  "Ryujin Jakka: the blade (base x0 y0 z0 → tip x1 y1 z1) sheathed in flame, three tongues
licking upward, flame particles streaming off (they trail the swing). POWER 1.3 in Hellfire."
  (with-floats (x0 y0 z0 x1 y1 z1 dt power)
    (let* ((bx (- x1 x0)) (by (- y1 y0)) (bz (- z1 z0)) (ph (* 1.0f0 (clock))) (p power))
      (declare (single-float bx by bz ph p))
      (fx-ribbon x0 y0 z0 bx by bz (* 0.15f0 p) (* 0.11f0 p) 0.35f0 0.05f0 0.02f0 0.4f0 0.3f0 0.04f0 0.02f0 0.3f0
              ph 0f0 :segs 3 :mode :alpha)
      (fx-ribbon x0 y0 z0 bx by bz (* 0.13f0 p) (* 0.1f0 p) 1f0 0.42f0 0.08f0 -0.75f0 1f0 0.3f0 0.04f0 -0.55f0
              (* 3f0 ph) 0.02f0 :segs 4)
      (fx-ribbon x0 y0 z0 bx by bz 0.04f0 0.03f0 1f0 0.85f0 0.5f0 0.9f0 1f0 0.7f0 0.3f0 0.8f0 ph 0f0 :segs 2)
      (dotimes (k 3)
        (let* ((kf (i->f k)) (u (+ 0.3f0 (* 0.28f0 kf)))
               (h (* p (+ 0.34f0 (* 0.1f0 (f-sin (+ (* 9f0 ph) (* 2.1f0 kf)))))))
               (lean (* 0.08f0 (f-sin (+ (* 5f0 ph) kf)))))
          (declare (single-float kf u h lean))
          (fire-tongue (+ x0 (* u bx)) (+ y0 (* u by)) (+ z0 (* u bz)) lean h 0f0 (* 0.09f0 p) 1f0
                       (+ (* 7f0 ph) (* 1.9f0 kf)) 0.05f0 :segs 4 :dark nil)))
      (dotimes (i (n-of (* 70f0 p) dt))
        (let* ((u (rnd01)))
          (declare (single-float u))
          (flame (+ x0 (* u bx) (rnd-range -0.03f0 0.03f0)) (+ y0 (* u by)) (+ z0 (* u bz) (rnd-range -0.03f0 0.03f0))
                 (rnd-range -0.3f0 0.3f0) (rnd-range 1.0f0 2.0f0) (rnd-range -0.3f0 0.3f0)
                 (rnd-range 0.3f0 0.5f0) (* p (rnd-range 0.07f0 0.13f0)) 1f0 0.85f0 0.45f0)))
      (dotimes (i (n-of 5f0 dt))
        (let* ((u (rnd-range 0.4f0 1f0)))
          (declare (single-float u))
          (fx-emit +p-dust+ (+ x0 (* u bx)) (+ y0 (* u by) 0.3f0) (+ z0 (* u bz)) 0f0 0.8f0 0f0
                   0.8f0 0.08f0 -1.5f0 0.22f0 0.18f0 0.16f0))))))

(defun-fast vfx-blade-embers (x0 y0 z0 x1 y1 z1 dt)
  "Zanka no Tachi: no flame — an ember-red edge line, sparks and floating embers, faint heat
shimmer around the charred blade."
  (with-floats (x0 y0 z0 x1 y1 z1 dt)
    (let* ((bx (- x1 x0)) (by (- y1 y0)) (bz (- z1 z0)) (ph (clock))
           (pulse (+ 0.75f0 (* 0.25f0 (f-sin (* 6f0 ph))))))
      (declare (single-float bx by bz ph pulse))
      (with-cam ()
        (dotimes (k 2)                                  ; heat shimmer: big faint warm sprites
          (let* ((u (+ 0.3f0 (* 0.45f0 (i->f k)))))
            (declare (single-float u))
            (%spr (+ x0 (* u bx)) (+ y0 (* u by) 0.1f0) (+ z0 (* u bz)) 0.45f0 0.5f0 0.22f0 0.08f0 -0.1f0))))
      (fx-ribbon x0 y0 z0 bx by bz 0.05f0 0.035f0 1f0 0.25f0 0.04f0 (* -0.8f0 pulse) 0.9f0 0.15f0 0.03f0 (* -0.6f0 pulse)
              ph 0f0 :segs 2)
      (fx-ribbon x0 y0 z0 bx by bz 0.014f0 0.01f0 1f0 0.55f0 0.2f0 (* 0.9f0 pulse) 1f0 0.45f0 0.15f0 (* 0.7f0 pulse)
              ph 0f0 :segs 2)
      (dotimes (i (n-of 22f0 dt))
        (let* ((u (rnd01)))
          (declare (single-float u))
          (fx-emit +p-spark+ (+ x0 (* u bx)) (+ y0 (* u by)) (+ z0 (* u bz))
                   (rnd-range -0.8f0 0.8f0) (rnd-range 0.3f0 1.8f0) (rnd-range -0.8f0 0.8f0)
                   (rnd-range 0.3f0 0.6f0) 0.012f0 1f0 1f0 0.35f0 0.08f0)))
      (dotimes (i (n-of 10f0 dt))
        (let* ((u (rnd01)))
          (declare (single-float u))
          (fx-emit +p-glow+ (+ x0 (* u bx)) (+ y0 (* u by)) (+ z0 (* u bz))
                   (rnd-range -0.2f0 0.2f0) (rnd-range 0.2f0 0.6f0) (rnd-range -0.2f0 0.2f0)
                   (rnd-range 0.6f0 1.2f0) 0.025f0 -0.3f0 1f0 0.35f0 0.08f0))))))

;;; ---------------------------------------------------------------- fire wave / fireball / charge
(defun-fast vfx-fire-wave (x z yaw age width dt)
  "Signature flame slash wave: a crescent wall of flame WIDTH m wide centred on ground point
(x z), travelling toward YAW (the caller moves it). Tallest in the middle, bowed forward."
  (with-floats (x z yaw age width dt)
    (let* ((fx (- (f-sin yaw))) (fz (- (f-cos yaw))) (sx (- fz)) (sz fx) (ph (clock))
           (grow (f-min 1f0 (/ age 0.12f0))) (hw (* 0.5f0 width)) (tw (/ width 9f0)))
      (declare (single-float fx fz sx sz ph grow hw tw))
      (%gdisc x 0.02f0 z (* 0.7f0 width) 1f0 0.45f0 0.1f0 (* -0.3f0 grow) :add)
      (%gseg x z (- x (* 2.5f0 fx)) (- z (* 2.5f0 fz)) 0.03f0 hw 0.12f0 0.05f0 0.03f0 (* 0.35f0 grow) :alpha)
      (dotimes (k 9)
        (let* ((u (- (* 0.25f0 (i->f k)) 1f0)) (u2 (* u u))
               (back (* 0.7f0 u2)) (px (+ x (* sx u hw) (- (* back fx)))) (pz (+ z (* sz u hw) (- (* back fz))))
               (h (* grow 2.8f0 (- 1f0 (* 0.55f0 u2)) (+ 1f0 (* 0.15f0 (f-sin (+ (* 9f0 ph) (* 3f0 (i->f k)))))))))
          (declare (single-float u u2 back px pz h))
          (fire-tongue px 0f0 pz (* -0.35f0 fx) h (* -0.35f0 fz) (* 0.62f0 tw (- 1.3f0 (* 0.4f0 u2))) 1f0
                       (+ (* 6f0 ph) (* 2.3f0 (i->f k))) 0.12f0 :segs 5)))
      (dotimes (j 4)                                     ; the crescent slash riding the wall
        (let* ((u0 (- (* 0.5f0 (i->f j)) 1f0)) (u1 (+ u0 0.5f0))
               (ax (+ x (* sx u0 hw) (- (* 0.7f0 u0 u0 fx)))) (az (+ z (* sz u0 hw) (- (* 0.7f0 u0 u0 fz))))
               (bx (+ x (* sx u1 hw) (- (* 0.7f0 u1 u1 fx)))) (bz (+ z (* sz u1 hw) (- (* 0.7f0 u1 u1 fz))))
               (w0 (* grow 0.45f0 (- 1f0 (* 0.8f0 (f-abs u0))))) (w1 (* grow 0.45f0 (- 1f0 (* 0.8f0 (f-abs u1))))))
          (declare (single-float u0 u1 ax az bx bz w0 w1))
          (fx-ribbon ax 1.2f0 az (- bx ax) 0f0 (- bz az) (* 1.3f0 w0) (* 1.3f0 w1) 0.3f0 0.04f0 0.02f0 0.45f0
                  0.3f0 0.04f0 0.02f0 0.45f0 0f0 0f0 :segs 1 :mode :alpha)
          (fx-ribbon ax 1.2f0 az (- bx ax) 0f0 (- bz az) w0 w1 1f0 0.45f0 0.08f0 -0.8f0 1f0 0.45f0 0.08f0 -0.8f0 0f0 0f0 :segs 1)
          (fx-ribbon ax 1.2f0 az (- bx ax) 0f0 (- bz az) (* 0.3f0 w0) (* 0.3f0 w1) 1f0 0.85f0 0.5f0 0.7f0
                  1f0 0.85f0 0.5f0 0.7f0 0f0 0f0 :segs 1)))
      (dotimes (i (n-of 150f0 dt))
        (let* ((u (rnd-range -1f0 1f0)) (back (* 0.7f0 u u)))
          (declare (single-float u back))
          (flame (+ x (* sx u hw) (- (* back fx))) (rnd-range 0.1f0 1.4f0) (+ z (* sz u hw) (- (* back fz)))
                 (rnd-range -0.5f0 0.5f0) (rnd-range 1.5f0 3f0) (rnd-range -0.5f0 0.5f0)
                 (rnd-range 0.35f0 0.55f0) (rnd-range 0.18f0 0.33f0) 1f0 0.85f0 0.45f0)))
      (dotimes (i (n-of 20f0 dt))
        (fx-emit +p-spark+ (+ x (* sx hw (rnd-range -1f0 1f0))) (rnd-range 0.5f0 2f0) (+ z (* sz hw (rnd-range -1f0 1f0)))
                 (rnd-range -2f0 2f0) (rnd-range 2f0 5f0) (rnd-range -2f0 2f0) (rnd-range 0.4f0 0.8f0) 0.03f0 6f0
                 1f0 0.6f0 0.2f0))
      (dotimes (i (n-of 10f0 dt))
        (fx-emit +p-dust+ (+ x (* sx hw (rnd-range -0.8f0 0.8f0))) (rnd-range 1.8f0 2.5f0) (+ z (* sz hw (rnd-range -0.8f0 0.8f0)))
                 0f0 1f0 0f0 1.2f0 0.35f0 -1f0 0.22f0 0.17f0 0.15f0))
      (add-point-light x 1.2 z 1.0 0.45 0.12 10.0 2.5 7))))

(defun-fast vfx-fireball (x y z size dt)
  "Shiranui: a ball of fire of radius SIZE m (grows with the charge) with licking tongues and a
flame wake (particles stay behind as it flies)."
  (with-floats (x y z size dt)
    (let* ((s size) (ph (clock)))
      (declare (single-float s ph))
      (with-cam ()
        (%spr x y z (* 1.6f0 s) 0.3f0 0.04f0 0.02f0 0.45f0 :alpha)
        (%spr x y z (* 1.45f0 s) 0.8f0 0.14f0 0.03f0 -0.6f0)
        (%spr x y z (* 1.05f0 s) 1f0 0.45f0 0.08f0 -0.9f0)
        (%spr x y z (* (+ 0.4f0 (* 0.05f0 (f-sin (* 30f0 ph)))) s) 1f0 0.85f0 0.5f0 0.8f0))
      (dotimes (k 5)
        (let* ((a (+ (* 2.5f0 ph) (* 1.2566f0 (i->f k)))) (l (* s (+ 1.1f0 (* 0.3f0 (f-sin (+ (* 11f0 ph) (i->f k))))))))
          (declare (single-float a l))
          (fx-ribbon x y z (* l (f-cos a)) (* 0.6f0 l) (* l (f-sin a)) (* 0.45f0 s) 0f0
                  1f0 0.5f0 0.1f0 -0.8f0 0.8f0 0.12f0 0.02f0 0f0 (+ (* 8f0 ph) (i->f k)) (* 0.2f0 s) :segs 4)))
      (dotimes (i (n-of 90f0 dt))
        (flame (+ x (* 0.6f0 s (rnd-range -1f0 1f0))) (+ y (* 0.6f0 s (rnd-range -1f0 1f0))) (+ z (* 0.6f0 s (rnd-range -1f0 1f0)))
               (rnd-range -0.5f0 0.5f0) (rnd-range 0.3f0 1.2f0) (rnd-range -0.5f0 0.5f0)
               (rnd-range 0.25f0 0.4f0) (f-min 0.33f0 (* s (rnd-range 0.35f0 0.5f0))) 1f0 0.85f0 0.45f0))
      (dotimes (i (n-of 12f0 dt))
        (fx-emit +p-spark+ x y z (rnd-range -3f0 3f0) (rnd-range -1f0 3f0) (rnd-range -3f0 3f0)
                 (rnd-range 0.3f0 0.6f0) 0.03f0 6f0 1f0 0.6f0 0.2f0))
      (add-point-light x y z 1.0 0.5 0.15 8.0 2.0 7))))

(defun-fast vfx-charge (x y z k dt)
  "Charging glow at the blade (x y z), K 0..1: a growing hot sphere, flames sucked inward."
  (with-floats (x y z k dt)
    (let* ((ph (clock)) (fl (+ 1f0 (* 0.12f0 (f-sin (* 25f0 ph))))))
      (declare (single-float ph fl))
      (with-cam ()
        (%spr x y z (* fl (+ 0.4f0 (* 0.6f0 k))) 0.35f0 0.05f0 0.02f0 (+ 0.2f0 (* 0.2f0 k)) :alpha)
        (%spr x y z (* fl (+ 0.3f0 (* 0.5f0 k))) 1f0 0.35f0 0.04f0 (- (+ 0.3f0 (* 0.3f0 k))))
        (%spr x y z (* fl (+ 0.06f0 (* 0.16f0 k))) 1f0 0.85f0 0.5f0 (+ 0.5f0 (* 0.3f0 k))))
      (dotimes (j 4)                                     ; flame tongues spiralling in
        (let* ((a (+ (* -4f0 ph) (* 1.5708f0 (i->f j)))) (l (+ 0.35f0 (* 0.35f0 k))))
          (declare (single-float a l))
          (fx-ribbon (+ x (* l (f-cos a))) (+ y (* 0.3f0 l (f-sin (* 2f0 a)))) (+ z (* l (f-sin a)))
                  (* -0.9f0 l (f-cos a)) 0f0 (* -0.9f0 l (f-sin a)) 0.02f0 (+ 0.05f0 (* 0.06f0 k))
                  0.8f0 0.15f0 0.03f0 -0.2f0 1f0 0.5f0 0.1f0 (- (+ 0.4f0 (* 0.4f0 k))) (* 9f0 ph) 0.04f0 :segs 3)))
      (dotimes (i (n-of (+ 30f0 (* 90f0 k)) dt))
        (let* ((dx (rnd-range -1f0 1f0)) (dy (rnd-range -1f0 1f0)) (dz (rnd-range -1f0 1f0))
               (l (f-max 0.05f0 (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz))))) (r (+ 0.7f0 (* 0.5f0 k)))
               (sp (/ r (* l 0.25f0))))
          (declare (single-float dx dy dz l r sp))
          (fx-emit +p-flame+ (+ x (* r (/ dx l))) (+ y (* r (/ dy l))) (+ z (* r (/ dz l)))
                   (- (* sp dx)) (- (* sp dy)) (- (* sp dz)) 0.25f0 (+ 0.06f0 (* 0.07f0 k)) 0f0 1f0 0.8f0 0.4f0)))
      (add-point-light x y z 1.0 0.5 0.15 (+ 3.0 (* 3.0 k)) (+ 0.5 (* 1.0 k)) 5))))

;;; ---------------------------------------------------------------- Ennetsu Jigoku pillar / Jokaku Enjo dome
(defun-fast vfx-fire-pillar (x z age life dt &key (height 5.0))
  "One Ennetsu Jigoku pillar at ground (x z): rises in 0.18 s, roars, fades over the last
0.25 s of LIFE. Body = ribbon layers; ≤ ~40 live particles; no light (the caller adds one for
the whole ring: 7 pillar lights would wash the floor out)."
  (with-floats (x z age life dt height)
    (let* ((ph (+ (clock) (* 0.37f0 x))) (r0 (f-clamp (/ age 0.18f0) 0f0 1f0))
           (rise (- 1f0 (* (- 1f0 r0) (- 1f0 r0))))
           (fade (f-clamp (/ (- life age) 0.25f0) 0f0 1f0))
           (h (* height rise (+ 0.92f0 (* 0.08f0 (f-sin (* 6f0 ph))))))
           (w (* (+ 0.7f0 (* 0.3f0 rise)) (+ 0.6f0 (* 0.4f0 fade)))))
      (declare (single-float ph r0 rise fade h w))
      (when (> fade 0f0)
        (%gdisc x 0.03f0 z (* 1.8f0 w) 1f0 0.32f0 0.06f0 (* -0.2f0 fade) :add)
        (%gdisc x 0.02f0 z (* 1.4f0 w) 0.08f0 0.03f0 0.02f0 (* 0.5f0 fade) :alpha)
        (fire-tongue x 0f0 z 0f0 h 0f0 (* 0.9f0 w) (* 0.8f0 fade) ph 0.3f0 :segs 8 :taper 0.55f0)
        (with-cam ()
          (fire-tongue (+ x (* 0.45f0 w rx)) 0f0 (+ z (* 0.45f0 w rz)) 0.15f0 (* 0.6f0 h) 0f0 (* 0.5f0 w) (* 0.6f0 fade)
                       (+ ph 2.1f0) 0.3f0 :segs 5 :dark nil)
          (fire-tongue (- x (* 0.45f0 w rx)) 0f0 (- z (* 0.45f0 w rz)) -0.15f0 (* 0.5f0 h) 0f0 (* 0.5f0 w) (* 0.6f0 fade)
                       (+ ph 4.2f0) 0.3f0 :segs 5 :dark nil))
        (dotimes (i (n-of (* 28f0 fade) dt))
          (flame (+ x (rnd-range -0.35f0 0.35f0)) (* h (rnd-range 0.55f0 0.95f0)) (+ z (rnd-range -0.35f0 0.35f0))
                 (rnd-range -0.6f0 0.6f0) (rnd-range 2f0 3.2f0) (rnd-range -0.6f0 0.6f0)
                 (rnd-range 0.4f0 0.6f0) (rnd-range 0.22f0 0.34f0) 1f0 0.8f0 0.4f0))
        (dotimes (i (n-of (* 18f0 fade) dt))
          (let* ((a (rnd-range 0f0 6.2832f0)) (c (f-cos a)) (s (f-sin a)))
            (declare (single-float a c s))
            (flame (+ x (* 0.6f0 c)) 0.2f0 (+ z (* 0.6f0 s)) (* 1.6f0 c) (rnd-range 0.6f0 1.4f0) (* 1.6f0 s)
                   (rnd-range 0.3f0 0.4f0) (rnd-range 0.18f0 0.28f0) 1f0 0.8f0 0.4f0)))
        (dotimes (i (n-of 6f0 dt))
          (fx-emit +p-dust+ (+ x (rnd-range -0.4f0 0.4f0)) h (+ z (rnd-range -0.4f0 0.4f0))
                   (rnd-range -0.3f0 0.3f0) 1.5f0 (rnd-range -0.3f0 0.3f0) 1.4f0 0.5f0 -1.5f0 0.22f0 0.17f0 0.15f0))
        (dotimes (i (n-of 8f0 dt))
          (fx-emit +p-spark+ x (* 0.5f0 h) z (rnd-range -3f0 3f0) (rnd-range 3f0 7f0) (rnd-range -3f0 3f0)
                   (rnd-range 0.6f0 1.1f0) 0.035f0 6f0 1f0 0.6f0 0.2f0))))))

(defconstant +dome-n+ 12 "flame walls around the Jokaku Enjo dome")

(defun-fast vfx-fire-dome (x z r age life dt)
  "Jokaku Enjo around ground point (x z), radius R. 0-35 % of LIFE: 12 flame walls rise; 35-70 %:
they bend inward and close into a dome (a glowing shell grows from the ground up); 70-85 %: the
dome seethes; at 85 % it detonates (one burst + a fading flash)."
  (with-floats (x z r age life dt)
    (let* ((u (/ age (f-max life 0.01f0))) (ph (clock)) (det 0.85f0)
           (big-h (* 1.15f0 r)) (w0 (* 0.62f0 (/ (* 6.2832f0 r) (i->f +dome-n+)))))
      (declare (single-float u ph det big-h w0))
      (if (< u det)
          (let* ((rise (f-clamp (/ u 0.35f0) 0f0 1f0))
                 (c (f-clamp (/ (- u 0.35f0) 0.35f0) 0f0 1f0)) (close (* c c (- 3f0 (* 2f0 c))))
                 (seethe (f-clamp (/ (- u 0.7f0) 0.15f0) 0f0 1f0)) (hw (* 3.2f0 rise)))
            (declare (single-float rise c close seethe hw))
            (%gdisc x 0.025f0 z (* 1.15f0 r) 0.08f0 0.03f0 0.02f0 (* 0.5f0 rise) :alpha)   ; scorched ground: the
            (%gdisc x 0.03f0 z (* 1.3f0 r) 1f0 0.28f0 0.04f0 (* -0.1f0 rise) :add)          ; base reads dark red
            (when (> close 0f0)                          ; the shell: rings of quads up to the closing line
              (let* ((lat (* close 1.5708f0)))
                (declare (single-float lat))
                (dotimes (j 4)
                  (let* ((b0 (* lat (/ (i->f j) 4f0))) (b1 (* lat (/ (i->f (1+ j)) 4f0)))
                         (cr0 (* 0.92f0 r (f-cos b0))) (cr1 (* 0.92f0 r (f-cos b1)))
                         (y0 (* big-h (f-sin b0))) (y1 (* big-h (f-sin b1))) (k (+ 0.08f0 (* 0.08f0 seethe)))
                         (f0 (/ b0 1.5708f0)) (f1 (/ b1 1.5708f0))              ; 0 at the ground, 1 at the top
                         (r0 (+ 0.45f0 (* 0.35f0 f0))) (g0 (+ 0.07f0 (* 0.13f0 f0))) (r1 (+ 0.45f0 (* 0.35f0 f1))) (g1 (+ 0.07f0 (* 0.13f0 f1))))
                    (declare (single-float b0 b1 cr0 cr1 y0 y1 k f0 f1 r0 g0 r1 g1))
                    (dotimes (i 12)
                      (let* ((a0 (* 0.5236f0 (i->f i))) (a1 (+ a0 0.5236f0))
                             (c0 (f-cos a0)) (s0 (f-sin a0)) (c1 (f-cos a1)) (s1 (f-sin a1)))
                        (declare (single-float a0 a1 c0 s0 c1 s1))
                        (with-fx-verts (d o :alpha 6)    ; the wall: opaque-ish, dark red at the ground
                          (vtx (+ x (* cr0 c0)) y0 (+ z (* cr0 s0)) 0f0 0f0 r0 g0 0.03f0 0.65f0)   ; (a low camera sees the
                          (vtx (+ x (* cr0 c1)) y0 (+ z (* cr0 s1)) 0f0 0f0 r0 g0 0.03f0 0.65f0)   ; base through every
                          (vtx (+ x (* cr1 c1)) y1 (+ z (* cr1 s1)) 0f0 0f0 r1 g1 0.04f0 0.6f0)    ; flame), orange up top
                          (vtx (+ x (* cr0 c0)) y0 (+ z (* cr0 s0)) 0f0 0f0 r0 g0 0.03f0 0.65f0)
                          (vtx (+ x (* cr1 c1)) y1 (+ z (* cr1 s1)) 0f0 0f0 r1 g1 0.04f0 0.6f0)
                          (vtx (+ x (* cr1 c0)) y1 (+ z (* cr1 s0)) 0f0 0f0 r1 g1 0.04f0 0.6f0))
                        (with-fx-verts (d o :add 6)
                          (vtx (+ x (* cr0 c0)) y0 (+ z (* cr0 s0)) 0f0 0f0 1f0 0.3f0 0.04f0 (- k))
                          (vtx (+ x (* cr0 c1)) y0 (+ z (* cr0 s1)) 0f0 0f0 1f0 0.3f0 0.04f0 (- k))
                          (vtx (+ x (* cr1 c1)) y1 (+ z (* cr1 s1)) 0f0 0f0 0.9f0 0.15f0 0.03f0 (- k))
                          (vtx (+ x (* cr0 c0)) y0 (+ z (* cr0 s0)) 0f0 0f0 1f0 0.3f0 0.04f0 (- k))
                          (vtx (+ x (* cr1 c1)) y1 (+ z (* cr1 s1)) 0f0 0f0 0.9f0 0.15f0 0.03f0 (- k))
                          (vtx (+ x (* cr1 c0)) y1 (+ z (* cr1 s0)) 0f0 0f0 0.9f0 0.15f0 0.03f0 (- k)))))))))
            (dotimes (i +dome-n+)
              (let* ((a (+ (* 0.5236f0 (i->f i)) (* 0.15f0 ph))) (bx (+ x (* r (f-cos a)))) (bz (+ z (* r (f-sin a))))
                     (ax (* close (- x bx))) (ay (+ (* (- 1f0 close) hw) (* close big-h))) (az (* close (- z bz)))
                     (w (* w0 (+ 0.7f0 (* 0.3f0 rise)))))
                (declare (single-float a bx bz ax ay az w))
                (fire-tongue bx 0f0 bz ax ay az w (* 0.75f0 (- (+ 0.75f0 (* 0.2f0 seethe)) (* 0.6f0 close)))
                             (+ (* 5f0 ph) (* 1.7f0 (i->f i))) (* 0.3f0 (- 1f0 close)) :segs 6 :core (< close 0.3f0))))
            (with-cam ()
              (%spr x 1.2f0 z (* 1.2f0 r (+ 0.8f0 (* 0.2f0 (f-sin (* 17f0 ph))))) 1f0 0.22f0 0.03f0 (* -0.12f0 (+ close seethe))))
            (dotimes (i (n-of (* 130f0 rise (- 1f0 (* 0.6f0 close))) dt))
              (let* ((a (rnd-range 0f0 6.2832f0)) (h (rnd01)) (rr (* r (- 1f0 (* close h)))))
                (declare (single-float a h rr))
                (flame (+ x (* rr (f-cos a))) (* h (+ (* (- 1f0 close) hw) (* close big-h))) (+ z (* rr (f-sin a)))
                       (rnd-range -0.4f0 0.4f0) (rnd-range 1.2f0 2.4f0) (rnd-range -0.4f0 0.4f0)
                       (rnd-range 0.3f0 0.45f0) (rnd-range 0.2f0 0.33f0) 1f0 0.55f0 0.2f0 (- 0.45f0 (* 0.25f0 close)))))
            (add-point-light x 1.5 z 1.0 0.35 0.08 10.0 (+ 1.0 (* 0.8 close)) 8))
          (let* ((v (f-clamp (/ (- u det) (- 1f0 det)) 0f0 1f0)) (tdet (* det life)))
            (declare (single-float v tdet))
            (when (and (<= tdet age) (< (- age dt) tdet))  ; the frame that crosses 85 %: detonate
              (fx-burst +p-flame+ (f->i (* 90f0 (the single-float (f32 *fire-density*)))) x 1.2f0 z 0f0 0.3f0 0f0 1f0
                        6f0 12f0 0.6f0 0.35f0 1f0 0.85f0 0.45f0)
              (fx-burst +p-spark+ 30 x 1.2f0 z 0f0 0.5f0 0f0 1f0 8f0 16f0 0.8f0 0.05f0 1f0 0.7f0 0.3f0)
              (fx-burst +p-dust+ 12 x 1.5f0 z 0f0 0.5f0 0f0 1f0 3f0 6f0 1.4f0 0.7f0 0.24f0 0.18f0 0.15f0)
              (fx-ring x 0.05 z (* 0.8 r) (* 3.0 r) 0.5 1.0 0.6 0.2 :flat t :width 0.35)
              (fx-ring x 1.2 z 0.5 (* 2.5 r) 0.3 1.0 0.85 0.5 :width 0.2))
            (with-cam ()
              (%spr x 1.4f0 z (* r (+ 1f0 (* 1.8f0 v))) 1f0 0.55f0 0.15f0 (* -0.9f0 (- 1f0 v)))
              (%spr x 1.4f0 z (* r (+ 0.4f0 (* 0.8f0 v))) 1f0 0.9f0 0.7f0 (* 0.9f0 (- 1f0 v) (- 1f0 v))))
            (add-point-light x 1.5 z 1.0 0.5 0.2 16.0 (* 3.5 (- 1.0 v)) 9)))))
  nil)

;;; ---------------------------------------------------------------- auras
(defmacro %aura-tongues (x y z height n rad r g b a ph)
  "N flame-shaped ribbons around a body at radius RAD, rising HEIGHT·(0.75..1.15); the ones in
front of the body fade (FRONT-DIM)."
  `(dotimes (k ,n)
     (let* ((kf (i->f k)) (ang (+ (* 0.3f0 ,ph) (/ (* 6.2832f0 kf) (i->f ,n))))
            (hh (* ,height (+ 0.95f0 (* 0.2f0 (f-sin (+ (* 7f0 ,ph) (* 2.7f0 kf)))))))
            (aa (* ,a (front-dim ,x ,z ang))))
       (declare (single-float kf ang hh aa))
       (fx-ribbon (+ ,x (* ,rad (f-cos ang))) (+ ,y 0.05f0) (+ ,z (* ,rad (f-sin ang))) 0f0 hh 0f0
               0.24f0 0f0 ,r ,g ,b aa (* 0.8f0 ,r) (* 0.5f0 ,g) (* 0.5f0 ,b) 0f0 (+ (* 6f0 ,ph) (* 1.9f0 kf)) 0.12f0
               :segs 5))))

(defvar *aura-cap* 1.0
  "0.5..1: alpha cap of every body aura this frame. HUD-DRAW (AURA-CAP-UPDATE) lowers it while the
fighters stand within ~3 m, where two auras (or one over the other fighter) summed to a white blob.")

(defun-fast vfx-aura (x y z height kind age dt &key rgb (k 1.0))
  "Body aura at the feet (x y z) of a fighter HEIGHT m tall. KIND:
:hellfire (fire aura + a ring of flames at the feet + light), :heat (Bankai West: faint heat shimmer
+ embers), :evolution (faint aura in RGB, a list, default white), :reiatsu (Kenpachi's yellow +
light), :breaker (pink; K 0..1 brightens it over the last 8 f). For the other kinds K scales the
alpha (0..1). Every aura also fades by *AURA-CAP* and when the camera is within ~4 m of it (a
close-up must still show the face)."
  (declare (ignorable age))
  (with-floats (x y z height dt k)
    (let* ((ph (+ (clock) (* 0.5f0 x))) (h height) (eye (camera-eye *camera*))
           (ex (- (aref eye 0) x)) (ey (- (aref eye 1) (+ y (* 0.6f0 h)))) (ez (- (aref eye 2) z))
           (near (f-clamp (/ (- (f-sqrt (+ (* ex ex) (* ey ey) (* ez ez))) 1.5f0) 2.5f0) 0.35f0 1f0))
           (cap (* near (the single-float (f32 *aura-cap*))))
           (ka (if (eq kind :breaker) cap (* cap (f-clamp k 0f0 1f0)))))
      (declare (type f32vec eye) (single-float ph h ex ey ez near cap ka))
      (case kind
        (:hellfire
         (%gdisc x (+ y 0.03f0) z 0.9f0 1f0 0.3f0 0.05f0 (* -0.25f0 ka) :add)
         (dotimes (j 5)                                   ; tongues at the silhouette, faint in front
           (let* ((ang (+ (* 0.4f0 ph) (* 1.2566f0 (i->f j)))))
             (declare (single-float ang))
             (fire-tongue (+ x (* 0.34f0 (f-cos ang))) y (+ z (* 0.34f0 (f-sin ang))) 0f0
                          (* h (+ 0.6f0 (* 0.2f0 (f-sin (+ (* 6f0 ph) (* 2f0 (i->f j))))))) 0f0
                          0.2f0 (* 0.8f0 ka (front-dim x z ang)) (+ (* 6f0 ph) (* 1.3f0 (i->f j))) 0.15f0
                          :segs 5 :dark (< j 2) :core nil)))
         (dotimes (j 8)                                   ; a thin ring of flames licking at his feet
           (let* ((ang (+ (* -0.6f0 ph) (* 0.7854f0 (i->f j))))
                  (hh (* 0.32f0 (+ 1f0 (* 0.4f0 (f-sin (+ (* 9f0 ph) (* 2.3f0 (i->f j)))))))))
             (declare (single-float ang hh))
             (fx-ribbon (+ x (* 0.55f0 (f-cos ang))) (+ y 0.02f0) (+ z (* 0.55f0 (f-sin ang))) 0f0 hh 0f0 0.11f0 0f0
                     1f0 0.45f0 0.08f0 (* -0.75f0 ka) 1f0 0.2f0 0.02f0 0f0 (+ (* 8f0 ph) (i->f j)) 0.05f0 :segs 3)))
         (fx-sector x y z 0.42 0.66 0.0 3.1416 1.0 0.4 0.08 (* -0.45 ka) :segs 24)
         (dotimes (i (n-of 40f0 dt))
           (flame (+ x (rnd-range -0.35f0 0.35f0)) (+ y (* h (rnd-range 0.05f0 0.9f0))) (+ z (rnd-range -0.35f0 0.35f0))
                  (rnd-range -0.3f0 0.3f0) (rnd-range 1.5f0 2.5f0) (rnd-range -0.3f0 0.3f0)
                  (rnd-range 0.3f0 0.5f0) (rnd-range 0.12f0 0.22f0) 1f0 0.7f0 0.3f0 (* 0.55f0 ka)))
         (dotimes (i (n-of 4f0 dt))
           (fx-emit +p-dust+ (+ x (rnd-range -0.3f0 0.3f0)) (+ y h) (+ z (rnd-range -0.3f0 0.3f0))
                    0f0 1.2f0 0f0 1.2f0 0.3f0 -1f0 0.22f0 0.17f0 0.15f0))
         (add-point-light x (+ y 0.6) z 1.0 0.4 0.1 4.5 0.8 8))
        (:heat
         (with-cam ()
           (dotimes (j 3)
             (%spr (+ x (* 0.25f0 (f-sin (+ ph (* 2f0 (i->f j)))))) (+ y (* h (+ 0.25f0 (* 0.3f0 (i->f j))))) z
                   (* 0.55f0 h) 1f0 0.55f0 0.25f0 (* -0.06f0 ka))))
         (%aura-tongues x y z (* 0.75f0 h) 4 0.32f0 1f0 0.7f0 0.4f0 (* -0.12f0 ka) ph)
         (dotimes (i (n-of 8f0 dt))
           (fx-emit +p-glow+ (+ x (rnd-range -0.4f0 0.4f0)) (+ y (* h (rnd01))) (+ z (rnd-range -0.4f0 0.4f0))
                    0f0 (rnd-range 0.3f0 0.7f0) 0f0 (rnd-range 0.6f0 1.2f0) 0.025f0 -0.2f0 1f0 0.4f0 0.1f0))
         (add-point-light x (+ y 1.2) z 1.0 0.5 0.2 5.0 0.8 8))
        (:evolution
         (let* ((r (if rgb (f32 (elt rgb 0)) 1f0)) (g (if rgb (f32 (elt rgb 1)) 1f0)) (b (if rgb (f32 (elt rgb 2)) 1f0))
                (pulse (* ka (+ 0.25f0 (* 0.1f0 (f-sin (* 4f0 ph)))))))
           (declare (single-float r g b pulse))
           (%aura-tongues x y z (* 0.85f0 h) 5 0.33f0 r g b (- pulse) ph)
           (dotimes (i (n-of 12f0 dt))
             (fx-emit +p-glow+ (+ x (rnd-range -0.35f0 0.35f0)) (+ y (* h (rnd01))) (+ z (rnd-range -0.35f0 0.35f0))
                      0f0 (rnd-range 0.5f0 1.2f0) 0f0 0.7f0 0.04f0 0f0 r g b))))
        (:reiatsu
         (%gdisc x (+ y 0.03f0) z 1.0f0 1f0 0.75f0 0.15f0 (* -0.15f0 ka) :add)
         (%aura-tongues x y z (* 1.25f0 h) 7 0.45f0 1f0 0.78f0 0.12f0 (* -0.42f0 ka) ph)
         (%aura-tongues x y z (* 0.8f0 h) 4 0.3f0 1f0 0.92f0 0.45f0 (* -0.28f0 ka) (+ ph 1.3f0))
         (dotimes (i (n-of (* 32f0 ka) dt))
           (fx-emit +p-glow+ (+ x (rnd-range -0.5f0 0.5f0)) (+ y (* h (rnd01))) (+ z (rnd-range -0.5f0 0.5f0))
                    (rnd-range -0.2f0 0.2f0) (rnd-range 1.5f0 3f0) (rnd-range -0.2f0 0.2f0)
                    (rnd-range 0.4f0 0.7f0) (rnd-range 0.04f0 0.08f0) 0f0 1f0 0.8f0 0.2f0 0.8f0))
         (add-point-light x (+ y 1.2) z 1.0 0.8 0.25 5.0 0.7 8))
        (:breaker
         (let* ((bk (* ka (+ 0.5f0 (* 0.9f0 (f-clamp k 0f0 1f0))))))
           (declare (single-float bk))
           (%aura-tongues x y z (* 1.05f0 h) 6 0.36f0 1f0 0.3f0 0.65f0 (* -0.4f0 bk) ph)
           (%aura-tongues x y z (* 0.7f0 h) 3 0.2f0 1f0 0.7f0 0.9f0 (* -0.3f0 bk) (+ ph 2f0))
           (dotimes (i (n-of (* 30f0 bk) dt))
             (fx-emit +p-glow+ (+ x (rnd-range -0.4f0 0.4f0)) (+ y (* h (rnd01))) (+ z (rnd-range -0.4f0 0.4f0))
                      0f0 (rnd-range 1f0 2.5f0) 0f0 0.5f0 0.05f0 0f0 1f0 0.35f0 0.7f0))
           (add-point-light x (+ y 1.0) z 1.0 0.35 0.7 5.0 (* 1.2 bk) 5))))
      nil)))

(defun-fast vfx-breaker-ring (x z age)
  "Pink ground ring under a Breaker dash (call every frame with the Breaker's AGE): a steady
ring plus a ripple every 0.4 s."
  (with-floats (x z age)
    (let* ((f (/ (f-mod age 0.4f0) 0.4f0)) (pulse (+ 0.7f0 (* 0.3f0 (f-sin (* 20f0 age))))))
      (declare (single-float f pulse))
      (fx-sector x 0.0 z 0.55 1.05 0.0 3.1416 1.0 0.35 0.7 (* -0.8 pulse) :segs 24)
      (fx-sector x 0.0 z (+ 0.9 (* 1.3 f)) (+ 1.1 (* 1.4 f)) 0.0 3.1416 1.0 0.5 0.8 (* -0.5 (- 1.0 f)) :segs 24)
      (%gdisc x 0.025f0 z 0.9f0 1f0 0.3f0 0.65f0 -0.3f0 :add))))

;;; ---------------------------------------------------------------- ground cuts, sky split, Tenchi Kaijin
(defun-fast %crack (x0 z0 x1 z1 w glow-r glow-g glow-b glow-a dark-a seed)
  "A jagged ground crack (x0 z0)→(x1 z1): dark alpha gash half-width W, glowing core line."
  (declare (single-float x0 z0 x1 z1 w glow-r glow-g glow-b glow-a dark-a seed))
  (let* ((dx (- x1 x0)) (dz (- z1 z0)) (l (f-sqrt (+ (* dx dx) (* dz dz)))) (n (max 2 (f->i (* 1.5f0 l))))
         (px (/ (- dz) (f-max l 1f-4))) (pz (/ dx (f-max l 1f-4))) (ox x0) (oz z0))
    (declare (single-float dx dz l px pz ox oz) (fixnum n))
    (dotimes (i n)
      (let* ((u (/ (i->f (1+ i)) (i->f n))) (jag (if (= i (1- n)) 0f0 (* 0.35f0 (- (hash01 (i->f i) seed) 0.5f0))))
             (nx (+ x0 (* u dx) (* jag px))) (nz (+ z0 (* u dz) (* jag pz)))
             (taper (- 1f0 (f-abs (- (* 2f0 u) 1f0)))) (ww (* w (+ 0.4f0 (* 0.6f0 taper)))))
        (declare (single-float u jag nx nz taper ww))
        (%gseg ox oz nx nz 0.03f0 ww 0.03f0 0.02f0 0.02f0 dark-a :alpha)
        (%gseg ox oz nx nz 0.035f0 (* 0.35f0 ww) glow-r glow-g glow-b glow-a :add)
        (setf ox nx oz nz)))))

(defun-fast vfx-line-cut (x0 z0 x1 z1 age life kind &key (dt 0.0))
  "A cut along the ground (x0 z0)→(x1 z1). KIND :sun (Kyokujitsujin: a thin white-hot line, in
the air at chest height and scorched on the ground, no explosion), :meteor (Nozarashi: the ground
splits, a light sheet flashes and a shockwave runs out on both sides), :crack (Buttagiru: a 3 m
ground crack with dust). DT (optional) feeds the particles; 0 = none."
  (with-floats (x0 z0 x1 z1 age life dt)
    (let* ((dx (- x1 x0)) (dz (- z1 z0)) (l (f-max 1f-3 (f-sqrt (+ (* dx dx) (* dz dz)))))
           (px (/ (- dz) l)) (pz (/ dx l)) (v (f-clamp (/ age (f-max life 0.01f0)) 0f0 1f0))
           (fade (- 1f0 (* v v))) (seed (+ x0 (* 3f0 z0))))
      (declare (single-float dx dz l px pz v fade seed))
      (case kind
        (:sun
         (let* ((grow (f-clamp (/ age 0.06f0) 0f0 1f0)) (ex (+ x0 (* grow dx))) (ez (+ z0 (* grow dz)))
                (hot (f-clamp (- 1f0 (/ age 0.35f0)) 0f0 1f0)))
           (declare (single-float grow ex ez hot))
           (%gseg x0 z0 ex ez 0.03f0 0.12f0 0.05f0 0.03f0 0.02f0 (* 0.7f0 fade) :alpha)
           (%gseg x0 z0 ex ez 0.035f0 0.3f0 1f0 0.5f0 0.12f0 (* -0.6f0 fade) :add)
           (%gseg x0 z0 ex ez 0.04f0 0.05f0 1f0 0.95f0 0.8f0 fade :add)
           (when (> hot 0f0)
             (fx-ribbon x0 1.1f0 z0 (* grow dx) 0f0 (* grow dz) 0.2f0 0.12f0 1f0 0.55f0 0.15f0 (* -0.6f0 hot)
                     1f0 0.45f0 0.1f0 (* -0.4f0 hot) 0f0 0f0 :segs 1)
             (fx-ribbon x0 1.1f0 z0 (* grow dx) 0f0 (* grow dz) 0.035f0 0.025f0 1f0 1f0 0.9f0 hot 1f0 0.9f0 0.7f0 hot
                     0f0 0f0 :segs 1))
           (dotimes (i (n-of (* 40f0 hot) dt))
             (let* ((u (* grow (rnd01))))
               (declare (single-float u))
               (fx-emit +p-spark+ (+ x0 (* u dx)) (rnd-range 0.05f0 1.1f0) (+ z0 (* u dz))
                        (rnd-range -1f0 1f0) (rnd-range 0.5f0 2f0) (rnd-range -1f0 1f0) 0.4f0 0.02f0 3f0 1f0 0.8f0 0.4f0)))))
        (:meteor
         (let* ((open (f-clamp (/ age 0.12f0) 0f0 1f0)) (glow (f-clamp (- 1f0 (/ age (* 0.6f0 life))) 0f0 1f0))
                (in (f-clamp (/ age 0.03f0) 0f0 1f0))     ; nothing at age 0 (a hazard frozen by a cinematic)
                (sheet (* in (f-clamp (- 1f0 (/ age 0.18f0)) 0f0 1f0)))
                (wave (* in (f-clamp (- 1f0 (/ age 0.6f0)) 0f0 1f0))) (off (+ 0.4f0 (* 9f0 (f-sqrt age)))))
           (declare (single-float open glow sheet wave off))
           (%crack x0 z0 (+ x0 (* open dx)) (+ z0 (* open dz)) 0.75f0 1f0 0.85f0 0.35f0 (* 0.9f0 glow) (* 0.9f0 fade) seed)
           (when (> wave 0f0)                            ; shockwave bands running out on both sides
             (%gseg (+ x0 (* off px)) (+ z0 (* off pz)) (+ x1 (* off px)) (+ z1 (* off pz)) 0.05f0 0.5f0
                    1f0 0.85f0 0.5f0 (* -0.6f0 wave) :add)
             (%gseg (- x0 (* off px)) (- z0 (* off pz)) (- x1 (* off px)) (- z1 (* off pz)) 0.05f0 0.5f0
                    1f0 0.85f0 0.5f0 (* -0.6f0 wave) :add))
           (when (> sheet 0f0)                           ; a sheet of light standing on the cut
             (dotimes (k 5)
               (let* ((u (* 0.25f0 (i->f k))))
                 (declare (single-float u))
                 (fx-ribbon (+ x0 (* u dx)) 0f0 (+ z0 (* u dz)) 0f0 (* 8f0 sheet) 0f0 (f-min 1.2f0 (* 0.2f0 l)) 0.15f0
                         1f0 0.9f0 0.55f0 (* -0.55f0 sheet) 1f0 0.75f0 0.3f0 0f0 0f0 0f0 :segs 2))))
           (dotimes (i (n-of (* 120f0 wave) dt))
             (let* ((u (rnd01)) (sd (if (< (rnd01) 0.5f0) -1f0 1f0)) (sp (rnd-range 3f0 7f0)))
               (declare (single-float u sd sp))
               (fx-emit +p-dust+ (+ x0 (* u dx)) 0.2f0 (+ z0 (* u dz)) (* sd sp px) (rnd-range 0.5f0 2f0) (* sd sp pz)
                        (rnd-range 0.6f0 1f0) (rnd-range 0.25f0 0.45f0) -0.3f0 0.5f0 0.42f0 0.34f0)))))
        (t                                               ; :crack
         (let* ((open (f-clamp (/ age 0.08f0) 0f0 1f0)) (glow (f-clamp (- 1f0 (/ age (* 0.5f0 life))) 0f0 1f0))
                (dust (f-clamp (- 1f0 (/ age 0.3f0)) 0f0 1f0)))
           (declare (single-float open glow dust))
           (%crack x0 z0 (+ x0 (* open dx)) (+ z0 (* open dz)) 0.3f0 1f0 0.5f0 0.12f0 (* 0.8f0 glow) (* 0.9f0 fade) seed)
           (dotimes (i (n-of (* 80f0 dust) dt))
             (let* ((u (rnd01)) (sd (if (< (rnd01) 0.5f0) -1f0 1f0)))
               (declare (single-float u sd))
               (fx-emit +p-dust+ (+ x0 (* u dx)) 0.15f0 (+ z0 (* u dz)) (* sd 2.5f0 px) (rnd-range 1f0 3f0) (* sd 2.5f0 pz)
                        (rnd-range 0.5f0 0.9f0) (rnd-range 0.2f0 0.35f0) -0.3f0 0.48f0 0.4f0 0.33f0))))))
      nil)))

(defvar *sky-c0* (make-f32 4)) (defvar *sky-c1* (make-f32 4)) (defvar *sky-scr* (make-f32 3))
(defun %ui-col (v r g b a) (setf (aref v 0) (f32 r) (aref v 1) (f32 g) (aref v 2) (f32 b) (aref v 3) (f32 a)) v)

(defun vfx-sky-split (x z yaw age life)
  "Nozarashi Kikon: a vertical line of light across the whole screen through ground point (x z)
(UI space, so it always spans the sky), the ground split 16 m along YAW (a :meteor line cut), and
for the first 0.2 s the screen halves sheared apart along the centre line (*GRADE-SPLIT*; 0 after,
END-CINE also resets it). Shoot it down the cut (camera on the cut line) so seam and split meet."
  (let* ((age (f32 age)) (v (min 1.0 (/ age (max life 0.01)))) (fade (- 1.0 (* v v v)))
         (fx (- (sin yaw))) (fz (- (cos yaw))) (s *sky-scr*)
         (sx (if (world-to-screen s (f32 x) 1f0 (f32 z)) (aref s 0) (* 0.5 (window-width))))
         (h (window-height)) (ui (ui-scale))
         (wide (* ui (+ 3.0 (* 40.0 (max 0.0 (- 1.0 (/ age 0.12))))))))
    (vfx-line-cut (- x (* 8 fx)) (- z (* 8 fz)) (+ x (* 8 fx)) (+ z (* 8 fz)) age life :meteor)
    (setf *grade-split* (f32 (* 0.035 h (max 0.0 (min 1.0 (/ age 0.03) (/ (- 0.2 age) 0.05))))))
    (when (< age 0.1) (ui-rect 0 0 (window-width) h (list 1 1 0.9 (* 0.45 (- 1 (/ age 0.1))))))
    (let ((gw (* ui 40)))
      (ui-gradient (- sx gw) 0 gw h (%ui-col *sky-c0* 1 0.85 0.3 0) (%ui-col *sky-c1* 1 0.85 0.3 (* 0.45 fade)) :vertical nil)
      (ui-gradient sx 0 gw h *sky-c1* *sky-c0* :vertical nil))
    (ui-rect (- sx (* 0.5 wide)) 0 wide h (list 1 1 0.95 fade))
    nil))

(defvar *ts-c0* (make-f32 4)) (defvar *ts-c1* (make-f32 4))
(defun vfx-tenchi-slash (age life)
  "Tenchi Kaijin: a full-screen white slash (UI space) sweeping lower-left → upper-right in
0.07 s, a white flash, then thinning out over LIFE. Pair with *GRADE-DESAT* 1 and VFX-ASH-BURST."
  (let* ((w (window-width)) (h (window-height)) (v (min 1.0 (/ age (max life 0.01))))
         (sweep (min 1.0 (/ age 0.07))) (th (* h 0.016 (+ 1 (* 2 (max 0.0 (- 1 (/ age 0.17))))) (- 1 (* v v v))))
         (ax (* -0.05 w)) (ay (* 0.8 h)) (bx (+ ax (* sweep 1.1 w))) (by (+ ay (* sweep -0.6 h)))
         (mx (* 0.5 (+ ax bx))) (my (* 0.5 (+ ay by)))
         (len (max 1.0 (sqrt (+ (expt (- bx ax) 2) (expt (- by ay) 2)))))
         (nx (/ (- ay by) len)) (ny (/ (- bx ax) len)))
    (when (< age 0.12) (ui-rect 0 0 w h (list 1 1 1 (* 0.75 (- 1 (/ age 0.12))))))
    (flet ((spindle (k c)
             (%ui-poly4 ax ay mx (- my (* k ny)) bx by bx by c c)
             (%ui-poly4 ax ay (+ mx (* k nx)) (+ my (* k ny)) bx by bx by c c)
             (%ui-poly4 ax ay (- mx (* k nx)) (- my (* k ny)) bx by bx by c c)))
      (spindle (* 5 th) (%ui-col *ts-c0* 1 0.95 0.85 (* 0.25 (- 1 v))))
      (spindle th (%ui-col *ts-c1* 1 1 1 (- 1 (* v v)))))
    nil))

;;; ---------------------------------------------------------------- victim marks
(defun-fast vfx-soul-flame (x y z age)
  "The red soul flame floating over a Kikon-able victim (x y z = the flame's base, e.g. 0.4 m over
the head). Bobbing, flickering; no particles."
  (with-floats (x y z age)
    (let* ((ph (* 1.3f0 age)) (y (+ y (* 0.05f0 (f-sin (* 3f0 age))))) (fl (+ 1f0 (* 0.1f0 (f-sin (* 17f0 age))))))
      (declare (single-float ph y fl))
      (with-cam ()                                      ; blood-red: no blue, no white core (pink)
        (%spr x (+ y 0.2f0) z 0.32f0 0.3f0 0.0f0 0.0f0 0.6f0 :alpha)
        (%spr x (+ y 0.22f0) z 0.5f0 1f0 0.04f0 0.0f0 -0.3f0))
      (fx-ribbon x y z 0f0 (* 0.95f0 fl) 0f0 0.42f0 0f0 0.45f0 0.0f0 0.0f0 0.9f0 0.3f0 0.0f0 0.0f0 0.4f0 ph 0.08f0
              :segs 5 :mode :alpha)
      (fx-ribbon x y z 0f0 (* 0.9f0 fl) 0f0 0.36f0 0f0 1f0 0.02f0 0.0f0 -1f0 0.7f0 0.0f0 0.0f0 -0.3f0 (* 5f0 ph) 0.07f0 :segs 6)
      (fx-ribbon x y z 0f0 (* 0.5f0 fl) 0f0 0.12f0 0f0 1f0 0.22f0 0.05f0 -0.7f0 1f0 0.05f0 0.0f0 0f0 (* 5f0 ph) 0.04f0 :segs 4))))

(defun-fast vfx-ash-burst (x y z)
  "Tenchi Kaijin victim turning to ash (x y z = the feet): grey ash rising off the whole body,
dark flakes, a few burning edges. One-shot (~110 particles)."
  (with-floats (x y z)
    (dotimes (i 50)
      (let* ((h (rnd-range 0.1f0 1.8f0)))
        (declare (single-float h))
        (fx-emit +p-dust+ (+ x (rnd-range -0.3f0 0.3f0)) (+ y h) (+ z (rnd-range -0.3f0 0.3f0))
                 (rnd-range -0.8f0 0.8f0) (rnd-range 0.3f0 1.5f0) (rnd-range -0.8f0 0.8f0)
                 (rnd-range 1.2f0 2.2f0) (rnd-range 0.12f0 0.25f0) -0.5f0 0.55f0 0.54f0 0.52f0)))
    (dotimes (i 40)
      (fx-emit +p-feather+ (+ x (rnd-range -0.3f0 0.3f0)) (+ y (rnd-range 0.1f0 1.8f0)) (+ z (rnd-range -0.3f0 0.3f0))
               (rnd-range -1.2f0 1.2f0) (rnd-range 0.5f0 2f0) (rnd-range -1.2f0 1.2f0)
               (rnd-range 1.5f0 2.5f0) 0.05f0 -0.3f0 0.2f0 0.19f0 0.18f0))
    (dotimes (i 20)
      (fx-emit +p-glow+ (+ x (rnd-range -0.3f0 0.3f0)) (+ y (rnd-range 0.1f0 1.8f0)) (+ z (rnd-range -0.3f0 0.3f0))
               (rnd-range -0.5f0 0.5f0) (rnd-range 0.5f0 1.5f0) (rnd-range -0.5f0 0.5f0) 1f0 0.03f0 -0.2f0 1f0 0.45f0 0.1f0))))

(defun-fast vfx-skeleton-dust (x z)
  "Earth bursting where a charred skeleton claws out: dust, dirt clods, embers. One-shot."
  (with-floats (x z)
    (fx-burst +p-dust+ 26 x 0.2f0 z 0f0 1f0 0f0 0.8f0 2f0 4f0 0.9f0 0.35f0 0.36f0 0.29f0 0.23f0)
    (fx-burst +p-feather+ 10 x 0.3f0 z 0f0 1f0 0f0 0.7f0 3f0 5f0 1.0f0 0.07f0 0.12f0 0.1f0 0.09f0)
    (fx-burst +p-glow+ 10 x 0.3f0 z 0f0 1f0 0f0 0.8f0 1.5f0 3f0 0.8f0 0.04f0 1f0 0.45f0 0.1f0)
    (fx-burst +p-flame+ 8 x 0.3f0 z 0f0 1f0 0f0 0.5f0 1f0 2f0 0.4f0 0.3f0 1f0 0.8f0 0.4f0)))

;;; ---------------------------------------------------------------- one-shots
(defun-fast vfx-hit (x y z kind &key (dx 0.0) (dz -1.0))
  "Hit spark at (x y z); (dx dz) = the hit direction (attacker → victim). KIND :cut :heavy
:fire :guard :clash :counter :breaker (guard break shatter). Also starts the 0.15 s hit light."
  (with-floats (x y z dx dz)
    (let* ((l (f-max 0.01f0 (f-sqrt (+ (* dx dx) (* dz dz))))) (dx (/ dx l)) (dz (/ dz l)))
      (declare (single-float l dx dz))
      (case kind
        (:cut (fx-burst +p-spark+ 14 x y z dx 0.3f0 dz 0.7f0 5f0 10f0 0.25f0 0.035f0 1f0 0.9f0 0.6f0)
         (fx-burst +p-glow+ 1 x y z 0f0 0f0 0f0 0f0 0f0 0f0 0.12f0 0.45f0 1f0 0.9f0 0.7f0)
         (fx-ring x y z 0.1 0.9 0.14 1.0 0.9 0.7 :width 0.05)
         (flash-light x y z 1.0 0.85 0.6))
        (:heavy (fx-burst +p-spark+ 24 x y z dx 0.4f0 dz 0.9f0 6f0 13f0 0.3f0 0.045f0 1f0 0.85f0 0.5f0)
         (fx-burst +p-glow+ 1 x y z 0f0 0f0 0f0 0f0 0f0 0f0 0.16f0 0.8f0 1f0 0.85f0 0.6f0)
         (fx-burst +p-dust+ 8 x y z dx 0.2f0 dz 0.6f0 1.5f0 3f0 0.5f0 0.3f0 0.6f0 0.55f0 0.5f0)
         (fx-ring x y z 0.2 1.6 0.2 1.0 0.85 0.6 :width 0.08)
         (flash-light x y z 1.0 0.8 0.5))
        (:fire (fx-burst +p-flame+ 16 x y z dx 0.5f0 dz 0.8f0 2f0 5f0 0.45f0 0.3f0 1f0 0.85f0 0.45f0)
         (fx-burst +p-spark+ 10 x y z dx 0.4f0 dz 0.9f0 5f0 9f0 0.35f0 0.035f0 1f0 0.6f0 0.2f0)
         (fx-burst +p-glow+ 1 x y z 0f0 0f0 0f0 0f0 0f0 0f0 0.15f0 0.7f0 1f0 0.55f0 0.15f0)
         (flash-light x y z 1.0 0.5 0.15))
        (:guard (fx-burst +p-spark+ 12 x y z (- dx) 0.5f0 (- dz) 0.8f0 4f0 8f0 0.25f0 0.03f0 0.7f0 0.85f0 1f0)
         (fx-ring x y z 0.3 0.9 0.18 0.5 0.75 1.0 :width 0.06)
         (flash-light x y z 0.6 0.8 1.0))
        (:clash (fx-burst +p-spark+ 30 x y z 0f0 0.3f0 0f0 1f0 7f0 14f0 0.4f0 0.05f0 1f0 0.95f0 0.7f0)
         (fx-burst +p-glow+ 1 x y z 0f0 0f0 0f0 0f0 0f0 0f0 0.2f0 1.1f0 1f0 0.9f0 0.7f0)
         (fx-ring x y z 0.2 2.2 0.25 1.0 0.9 0.7 :width 0.1)
         (fx-ring x 0.05 z 0.3 3.0 0.35 1.0 0.8 0.6 :flat t :width 0.15)
         (flash-light x y z 1.0 0.9 0.7))
        (:counter (fx-burst +p-spark+ 20 x y z dx 0.4f0 dz 0.8f0 6f0 12f0 0.3f0 0.045f0 1f0 0.3f0 0.2f0)
         (fx-burst +p-glow+ 1 x y z 0f0 0f0 0f0 0f0 0f0 0f0 0.15f0 0.8f0 1f0 0.35f0 0.25f0)
         (fx-ring x y z 0.2 1.4 0.2 1.0 0.3 0.2 :width 0.08)
         (flash-light x y z 1.0 0.35 0.25))
        (:breaker (fx-burst +p-feather+ 18 x y z dx 0.6f0 dz 1f0 3f0 7f0 0.8f0 0.09f0 0.85f0 0.9f0 1f0)
         (fx-burst +p-spark+ 22 x y z dx 0.4f0 dz 1f0 5f0 11f0 0.35f0 0.04f0 1f0 0.45f0 0.75f0)
         (fx-burst +p-glow+ 1 x y z 0f0 0f0 0f0 0f0 0f0 0f0 0.18f0 1f0 1f0 0.5f0 0.8f0)
         (fx-ring x y z 0.3 2.0 0.25 1.0 0.4 0.75 :width 0.12)
         (flash-light x y z 1.0 0.4 0.75)))
      nil)))

(defun-fast vfx-hoho (x y z appear-p)
  "Flash step, (x y z) = the body's centre (~1 m up; ground effects 1 m below it): vanish
(APPEAR-P NIL) or appear. A pale body-high afterimage column that lingers ~0.5 s, horizontal speed
lines shooting out, a dust ring and a ground ring; appearing adds a pale shock ring."
  (with-floats (x y z)
    (let* ((gy (f-max 0.03f0 (- y 1f0))) (life (if appear-p 0.35f0 0.55f0)))
      (declare (single-float gy life))
      (dotimes (i 14)                                   ; the afterimage: stacked pale glows, head to feet
        (let* ((h (+ gy 0.1f0 (* 0.13f0 (i->f i)))))
          (declare (single-float h))
          (fx-emit +p-glow+ (+ x (rnd-range -0.08f0 0.08f0)) h (+ z (rnd-range -0.08f0 0.08f0))
                   0f0 (if appear-p -0.2f0 0.4f0) 0f0 (* life (rnd-range 0.8f0 1.1f0)) (rnd-range 0.3f0 0.42f0) 0f0
                   0.55f0 0.72f0 1f0 0.8f0)))
      (dotimes (i 18)                                   ; speed lines: fast horizontal streaks
        (let* ((a (rnd-range 0f0 6.2832f0)) (sp (rnd-range 12f0 20f0)))
          (declare (single-float a sp))
          (fx-emit +p-spark+ x (+ gy (rnd-range 0.2f0 1.8f0)) z (* sp (f-cos a)) (rnd-range -0.5f0 0.5f0) (* sp (f-sin a))
                   (rnd-range 0.1f0 0.18f0) 0.03f0 0f0 0.8f0 0.9f0 1f0)))
      (dotimes (i 16)                                   ; dust kicked out along the ground
        (let* ((a (* 0.3927f0 (i->f i))) (c (f-cos a)) (s (f-sin a)))
          (declare (single-float a c s))
          (fx-emit +p-dust+ (+ x (* 0.3f0 c)) (+ gy 0.08f0) (+ z (* 0.3f0 s)) (* 4.5f0 c) 0.4f0 (* 4.5f0 s)
                   0.5f0 0.28f0 -0.3f0 0.6f0 0.58f0 0.55f0)))
      (fx-ring x (+ gy 0.03) z 0.2 (if appear-p 2.2 1.6) 0.3 0.75 0.88 1.0 :flat t :width 0.1)
      (when appear-p (fx-ring x y z 0.3 1.5 0.2 0.75 0.88 1.0 :width 0.08))))
  nil)

(defun-fast vfx-fire-cone (x z yaw &key (reach 4.0) (half 0.785))
  "Taimatsu: a great sweep of fire from ground point (x z) toward YAW, filling the REACH m / ±HALF
rad sector (the move's hit arc) at once: hero-size flames spread over the whole fan, rolling
outward and up for ~0.7 s, sparks, a dark smoke lip at the far edge, an orange flash. One-shot
(~95 particles); call on the move's first active frame."
  (with-floats (x z yaw reach half)
    (dotimes (i (f->i (* 60f0 (the single-float (f32 *fire-density*)))))
      (let* ((a (+ yaw (rnd-range (- half) half))) (fx (- (f-sin a))) (fz (- (f-cos a)))
             (d (* reach (f-max 0.12f0 (f-sqrt (rnd01))))) (sp (rnd-range 1f0 2.5f0)))   ; even over the fan's area
        (declare (single-float a fx fz d sp))
        (flame (+ x (* d fx)) (rnd-range 0.1f0 0.9f0) (+ z (* d fz)) (* sp fx) (rnd-range 1.2f0 2.8f0) (* sp fz)
               (rnd-range 0.5f0 0.85f0) (rnd-range 0.26f0 0.35f0) 1f0 0.8f0 0.4f0 0.8f0)))
    (dotimes (i 18)
      (let* ((a (+ yaw (rnd-range (- half) half))) (sp (rnd-range 6f0 11f0)))
        (declare (single-float a sp))
        (fx-emit +p-spark+ x 1f0 z (* sp (- (f-sin a))) (rnd-range 0.5f0 3f0) (* sp (- (f-cos a)))
                 (rnd-range 0.3f0 0.55f0) 0.035f0 4f0 1f0 0.6f0 0.2f0)))
    (dotimes (i 16)
      (let* ((a (+ yaw (rnd-range (- half) half))) (d (* reach (rnd-range 0.8f0 1.05f0))))
        (declare (single-float a d))
        (fx-emit +p-dust+ (+ x (* d (- (f-sin a)))) (rnd-range 0.3f0 1.2f0) (+ z (* d (- (f-cos a))))
                 0f0 (rnd-range 0.8f0 1.6f0) 0f0 (rnd-range 1f0 1.6f0) (rnd-range 0.35f0 0.55f0) -0.8f0 0.2f0 0.15f0 0.13f0)))
    (flash-light (+ x (* 0.5f0 reach (- (f-sin yaw)))) 1.2 (+ z (* 0.5f0 reach (- (f-cos yaw)))) 1.0 0.5 0.12)
    nil))

(defun-fast vfx-konpaku-shatter (x y z n)
  "N soul-glass shards (a lost Konpaku) bursting from (x y z): pale cyan glass, sparks, a flash."
  (declare (fixnum n))
  (with-floats (x y z)
    (fx-burst +p-feather+ (* 3 n) x y z 0f0 0.6f0 0f0 1f0 3f0 6f0 1.0f0 0.08f0 0.75f0 0.95f0 1f0)
    (fx-burst +p-spark+ (* 4 n) x y z 0f0 0.5f0 0f0 1f0 5f0 10f0 0.35f0 0.035f0 0.6f0 0.9f0 1f0)
    (fx-burst +p-glow+ 1 x y z 0f0 0f0 0f0 0f0 0f0 0f0 0.2f0 0.9f0 0.6f0 0.9f0 1f0)
    (fx-ring x y z 0.2 1.5 0.25 0.6 0.9 1.0 :width 0.06)
    (flash-light x y z 0.6 0.9 1.0)
    nil))

(defun-fast vfx-awaken-burst (x y z kind)
  "Awakening one-shots at the feet (x y z). KIND :bankai (every flame within 6 m sucked into the
blade over ~0.45 s: flames and streaks rushing in, an imploding ground ring), :bankai-burst (the
heat bursting out when the blade is revealed), :nozarashi (a yellow reiatsu pillar + shockwave
rings)."
  (with-floats (x y z)
    (case kind
      (:bankai
       (dotimes (i (f->i (* 140f0 (the single-float (f32 *fire-density*)))))
         (let* ((a (rnd-range 0f0 6.2832f0)) (r (rnd-range 2.5f0 6f0)) (h (rnd-range 0.2f0 3.5f0))
                (px (* r (f-cos a))) (pz (* r (f-sin a))) (ty 1.2f0) (k (rnd-range 2f0 2.4f0)))
           (declare (single-float a r h px pz ty k))
           (fx-emit +p-flame+ (+ x px) (+ y h) (+ z pz) (* (- k) px) (* k (- ty h)) (* (- k) pz)
                    (/ 1f0 k) (rnd-range 0.3f0 0.5f0) 0f0 1f0 0.85f0 0.45f0 0.8f0)))
       (dotimes (i 40)                                  ; suction streaks (sparks stretch along their speed)
         (let* ((a (rnd-range 0f0 6.2832f0)) (r (rnd-range 3f0 6f0)) (h (rnd-range 0.3f0 3f0))
                (px (* r (f-cos a))) (pz (* r (f-sin a))))
           (declare (single-float a r h px pz))
           (fx-emit +p-spark+ (+ x px) (+ y h) (+ z pz) (* -2.4f0 px) (* 2.4f0 (- 1.2f0 h)) (* -2.4f0 pz)
                    0.4f0 0.06f0 0f0 1f0 0.6f0 0.2f0)))
       (fx-ring x (+ y 0.05) z 6.0 0.3 0.45 1.0 0.45 0.1 :flat t :width 0.35)
       (fx-ring x (+ y 1.2) z 3.5 0.2 0.4 1.0 0.6 0.25 :width 0.15))
      (:bankai-burst
       (fx-burst +p-mist+ 20 x (+ y 1f0) z 0f0 0.3f0 0f0 1f0 3f0 6f0 1.2f0 0.9f0 0.3f0 0.2f0 0.15f0)
       (fx-burst +p-spark+ 40 x (+ y 1f0) z 0f0 0.5f0 0f0 1f0 6f0 14f0 0.7f0 0.04f0 1f0 0.5f0 0.15f0)
       (fx-burst +p-glow+ 30 x (+ y 1f0) z 0f0 0.3f0 0f0 1f0 2f0 5f0 1.2f0 0.05f0 1f0 0.4f0 0.1f0)
       (fx-ring x (+ y 0.05) z 0.5 7.0 0.6 1.0 0.5 0.2 :flat t :width 0.3)
       (fx-ring x (+ y 1.0) z 0.3 4.0 0.4 1.0 0.7 0.4 :width 0.15)
       (flash-light x (+ y 1.0) z 1.0 0.5 0.15))
      (:nozarashi                                       ; the pillar: yellow, not white (alpha 0.45)
       (dotimes (i 70)
         (fx-emit +p-glow+ (+ x (rnd-range -0.4f0 0.4f0)) (+ y (rnd-range 0f0 1f0)) (+ z (rnd-range -0.4f0 0.4f0))
                  (rnd-range -0.3f0 0.3f0) (rnd-range 10f0 22f0) (rnd-range -0.3f0 0.3f0)
                  (rnd-range 0.4f0 0.7f0) (rnd-range 0.1f0 0.25f0) 0f0 1f0 0.8f0 0.2f0 0.45f0))
       (fx-burst +p-spark+ 30 x (+ y 1f0) z 0f0 1f0 0f0 0.6f0 8f0 16f0 0.6f0 0.05f0 1f0 0.9f0 0.4f0)
       (fx-burst +p-dust+ 20 x (+ y 0.1f0) z 0f0 0.1f0 0f0 1f0 4f0 8f0 0.8f0 0.4f0 0.5f0 0.45f0 0.35f0)
       (fx-ring x (+ y 0.05) z 0.5 8.0 0.5 1.0 0.85 0.3 :flat t :width 0.3)
       (fx-ring x (+ y 0.05) z 0.3 5.0 0.35 1.0 1.0 0.7 :flat t :width 0.12)
       (fx-ring x (+ y 1.2) z 0.3 3.5 0.3 1.0 0.9 0.4 :width 0.12)
       (flash-light x (+ y 1.0) z 1.0 0.85 0.3)))
    nil))

(defun vfx-shockwave (x z r life &key (rgb '(1.0 0.8 0.5)))
  "Expanding ground ring at (x z) to radius R over LIFE s, with a thinner inner ring and dust."
  (let ((cr (f32 (elt rgb 0))) (cg (f32 (elt rgb 1))) (cb (f32 (elt rgb 2))))
    (fx-ring x 0.05 z 0.3 r life cr cg cb :flat t :width (* 0.04 r))
    (fx-ring x 0.05 z 0.2 (* 0.7 r) (* 0.8 life) cr cg cb :flat t :width (* 0.015 r))
    (fx-burst +p-dust+ 16 (f32 x) 0.15f0 (f32 z) 0f0 0.1f0 0f0 1f0 (f32 (* 0.8 (/ r life))) (f32 (/ r life))
              (f32 (* 0.5 life)) 0.35f0 0.55f0 0.5f0 0.45f0)
    nil))

;;; ---------------------------------------------------------------- UI: kanji (UI-BITMAP glyphs)
(defparameter *kanji*
  ;; 24 x 24 bit rows, rasterised once from Noto Sans CJK JP Bold (SIL OFL) and checked by eye.
  '((:manji   ; 卍
     #x000000 #x000000 #x1FF818 #x1FF838 #x1FF838 #x003838 #x003838 #x003838
     #x003838 #x003838 #x1FFFF8 #x1FFFF8 #x1FFFF8 #x1C3C00 #x1C3800 #x1C3800
     #x1C3800 #x1C3800 #x1C3C00 #x1C3FFC #x1C3FFC #x181FF8 #x000000 #x000000)
    (:kai     ; 解
     #x000000 #x0C0000 #x0E0FFC #x0F8FFC #x1FCFFC #x1DC38C #x39838C #x7FF71C
     #x7FFF7C #x3B7E38 #x1B76E0 #x1FF6E0 #x1FF7FC #x1B7FFC #x1B7FFC #x1FFCE0
     #x1FF4E0 #x387FFE #x387FFE #x3070E0 #x31F0E0 #x71E0E0 #x20C0E0 #x000000)
    (:no      ; 野
     #x000000 #x000000 #x3FF7FC #x3FF7FC #x333038 #x333178 #x3FF3F0 #x3FF1E0
     #x3330F8 #x3FF7FE #x3FFFFE #x3FF7FE #x0300CC #x3FF0CC #x3FF0DC #x3FF0C0
     #x0300C0 #x0300C0 #x07F8C0 #x7FF9C0 #x7FE7C0 #x2007C0 #x000000 #x000000)
    (:zarashi ; 晒
     #x000000 #x003FFC #x3F7FFE #x3F7FFE #x3F06E0 #x3306E0 #x333FFC #x333FFC
     #x333FFC #x3F36CC #x3F36CC #x3B36CC #x3336CC #x333EFC #x333C7C #x3B380C
     #x3F300C #x3F300C #x383FFC #x303FFC #x003FFC #x00300C #x000000 #x000000)
    (:ki      ; 鬼
     #x000000 #x00E000 #x00E000 #x0FFFF0 #x0FFFF0 #x0FFFF0 #x0E1870 #x0FFFF0
     #x0FFFF0 #x0E3C70 #x0E1870 #x0FFFF0 #x0FFFF0 #x0FFFF0 #x00CCC0 #x01CCD0
     #x01CD98 #x03CFF8 #x078FFC #x0F0C0E #x3F0FFE #x3C0FFC #x1003F8 #x000000)
    (:kon     ; 魂
     #x000000 #x000700 #x000700 #x3F9FF8 #x3F9FFC #x001BDC #x00199C #x001FFC
     #x7FDFFC #x7FD99C #x7FD99C #x0C1FFC #x1D9FFC #x198FC0 #x198FD8 #x3BCFDC
     #x7FCDF4 #x7FCDFC #x20DDF4 #x0039C6 #x0079FE #x0070FE #x000000 #x000000))
  "Glyph key → 24 bit rows (MSB = left).")

(defparameter *kanji-words* '((:bankai :manji :kai) (:nozarashi :no :zarashi) (:kikon :ki :kon))
  "Word key → its glyph keys.")

(defun ui-kanji (key x y px &key (color '(1 1 1 1)) color2 (align :left) (shear 0.0))
  "Draw kanji KEY — a word (:bankai 卍解, :nozarashi 野晒, :kikon 鬼魂) or one glyph (:manji :kai
:no :zarashi :ki :kon) — as 24×24 blocks of PX pixels, top at Y. ALIGN :left/:center/:right
relative to X. Returns the width in pixels (glyphs 24 px·PX apart plus a 2-block gap)."
  (let* ((glyphs (or (rest (assoc key *kanji-words*)) (list key)))
         (step (* 26 px)) (w (- (* step (length glyphs)) (* 2 px)))
         (x0 (- x (ecase align (:left 0) (:center (/ w 2)) (:right w)))))
    (loop for g in glyphs for i from 0 do
      (ui-bitmap (rest (or (assoc g *kanji*) (error "no kanji ~s" g))) (+ x0 (* i step)) y px
                 :color color :color2 color2 :shear shear :width 24))
    w))
