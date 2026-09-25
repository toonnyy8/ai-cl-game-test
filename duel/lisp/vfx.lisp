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
;;;;   one-shots        VFX-FIRE-CONE, VFX-AWAKEN-BURST, VFX-ASH-BURST, VFX-SKELETON-DUST: particles / rings once.
;;;;   toon universal   VFX-HIT, VFX-HOHO, VFX-BURST, VFX-KONPAKU-SHATTER, VFX-KIKON-RUSH, VFX-STEP-DUST,
;;;;                    VFX-SHOCKWAVE start STAMPS (drawn one-shots, STAMPS-DRAW every frame) + toon
;;;;                    particles; VFX-SOUL-FLAME and the :KIKON aura are per-frame toon shapes
;;;;                    (docs/STYLE_STORM_DESIGN.md §4.3: mono + the BLOOD spot, stepped on the fx clock).
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

(defmacro clock () "The fx clock's seconds (phase for flicker): it stops while the game pauses." `(the single-float (fx-clock)))

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

(defmacro %t-blob (x y z vx vy vz life size grav wob pal)
  "One toon particle puff / flame / droplet (+P-T-BLOB+)."
  `(fx-emit +p-t-blob+ ,x ,y ,z ,vx ,vy ,vz ,life ,size ,grav ,wob 0f0 0f0 ,pal))
(defmacro %t-shard (x y z vx vy vz life size grav pal)
  "One toon shard particle (+P-T-SHARD+): a kite along its velocity."
  `(fx-emit +p-t-shard+ ,x ,y ,z ,vx ,vy ,vz ,life ,size ,grav 0.05f0 0f0 0f0 ,pal))

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
(defvar *flash-light* (make-f32 8) "hit flash: x y z r g b start-time (fx clock s)")

(defun lights-flush ()
  "Add the 0.15 s hit flash while it lasts. Call once per frame, before END-FRAME."
  (let* ((fl *flash-light*) (age (- (fx-clock) (aref fl 6))))
    (when (< -0.001 age 0.15)
      (add-point-light (aref fl 0) (aref fl 1) (aref fl 2) (aref fl 3) (aref fl 4) (aref fl 5)
                       6.0 (* 2.0 (- 1.0 (/ age 0.15))) 6))
    nil))

(declaim (type f32vec *light-v*))
(defvar *light-v* (make-f32 8) "%LIGHT's record (ADD-POINT-LIGHT-V: no boxed float arguments).")
(defmacro %light (x y z r g b radius intensity priority)
  "ADD-POINT-LIGHT for computed single-float positions without boxing them (0 B)."
  `(let* ((%v *light-v*))
     (declare (type f32vec %v))
     (setf (aref %v 0) ,x (aref %v 1) ,y (aref %v 2) ,z (aref %v 3) ,r (aref %v 4) ,g (aref %v 5) ,b
           (aref %v 6) ,radius (aref %v 7) ,intensity)
     (add-point-light-v %v 0 ,priority)))

(defun flash-light (x y z r g b)
  "Start the 0.15 s hit-flash light at (x y z)."
  (let ((fl *flash-light*))
    (setf (aref fl 0) (f32 x) (aref fl 1) (f32 y) (aref fl 2) (f32 z)
          (aref fl 3) (f32 r) (aref fl 4) (f32 g) (aref fl 5) (f32 b) (aref fl 6) (fx-clock))))

;;; ---------------------------------------------------------------- Yamamoto: blade fire / embers
;;; Signature looks (docs/STYLE_STORM_DESIGN.md §4.1 / §4.2, Phase 3): drawn toon shapes in the layer order of §3.4 —
;;; a darker backing (ember, charcoal), the drawn mass (FIRE / REIATSU / EMBER), a thin additive T光 line, and
;;; scraps (toon particles) flying off. Shapes are re-drawn on the fx clock's drawings (DRAWING: twos, 12 a second),
;;; so they hold still between drawings like the universal effects; positions the game depends on never step.
(defmacro drawing-no (&optional (per-second 12f0))
  "The fx clock's drawing number (0..63): 12 a second = twos (fire, energy), 8 = threes (smoke, charcoal)."
  `(i->f (logand (f->i (* ,per-second (fx-clock))) 63)))

(defmacro %away-from-eye ((x y z) d &body body)
  "Rebind X Y Z moved D metres along the view ray (away from the camera eye; negative D = toward it): a layer
that must sit behind (or in front of) another camera-facing layer without fighting it for depth."
  `(let* ((%e (camera-eye *camera*)) (%dx (- ,x (aref %e 0))) (%dy (- ,y (aref %e 1))) (%dz (- ,z (aref %e 2)))
          (%l (f-max 1f-3 (f-sqrt (+ (* %dx %dx) (* %dy %dy) (* %dz %dz)))))
          (,x (+ ,x (* ,d (/ %dx %l)))) (,y (+ ,y (* ,d (/ %dy %l)))) (,z (+ ,z (* ,d (/ %dz %l)))))
     (declare (type f32vec %e) (single-float %dx %dy %dz %l ,x ,y ,z))
     ,@body))

(defun-fast vfx-blade-fire (x0 y0 z0 x1 y1 z1 dt &key (power 1.0))
  "Ryujin Jakka (§4.1 blade fire): the blade (base x0 y0 z0 → tip x1 y1 z1) sheathed in drawn FIRE (heat 1 at the
base .. 0.3 at the tip), three tongues licking upward from behind the sheath whose heights and lean are re-drawn
every drawing (twos), a thin additive core line (T光) and flame scraps peeling off (the sheath's red shade
lower edge is the backing: black smoke puffs off a blade read as bubbles). POWER 1.3 in Hellfire. The swing is the fighter's comet smear (VFX-SMEAR)."
  (with-floats (x0 y0 z0 x1 y1 z1 dt power)
    (let* ((bx (- x1 x0)) (by (- y1 y0)) (bz (- z1 z0)) (p power) (dr (drawing-no))
           (pk (toon-a +pal-fire+ 0.95f0)) (sd (- -3f0 (i->f (mod (f->i dr) 5)))))
      (declare (single-float bx by bz p dr pk sd))
      (fx-ribbon x0 y0 z0 bx by bz (* 0.075f0 p) (* 0.045f0 p) 1f0 sd 0.2f0 pk 0.3f0 sd 0.2f0 pk dr 0.01f0 :segs 4 :mode :toon)
      (dotimes (k 3)
        (let* ((kf (i->f k)) (u (+ 0.25f0 (* 0.27f0 kf)))
               (h (* p (+ 0.26f0 (* 0.26f0 (hash01 (+ kf dr) 3.1f0)))))
               (lx (* 0.14f0 (- (hash01 (+ kf dr) 5.3f0) 0.5f0))) (lz (* 0.14f0 (- (hash01 (+ kf dr) 7.9f0) 0.5f0)))
               (tx (+ x0 (* u bx))) (ty (+ y0 (* u by))) (tz (+ z0 (* u bz))) (tsd (- sd (* 7f0 (+ kf 1f0)))))
          (declare (single-float kf u h lx lz tx ty tz tsd))
          (%away-from-eye (tx ty tz) 0.04f0
            (fx-ribbon tx ty tz lx h lz (* 0.09f0 p) 0f0 1f0 tsd 0.25f0 pk 0.2f0 tsd 0.25f0 pk (+ dr kf) 0.03f0
                       :segs 5 :mode :toon))))
      (fx-ribbon x0 y0 z0 bx by bz 0.01f0 0.006f0 1f0 0.75f0 0.4f0 0.3f0 1f0 0.65f0 0.3f0 0.2f0 0f0 0f0 :segs 1)   ; T光
      (dotimes (i (n-of (* 10f0 p) dt))                 ; scraps: flame bits peeling off the swing
        (let* ((u (rnd-range 0.2f0 1f0)))
          (declare (single-float u))
          (%t-blob (+ x0 (* u bx)) (+ y0 (* u by) 0.05f0) (+ z0 (* u bz)) (rnd-range -0.4f0 0.4f0) (rnd-range 0.8f0 1.6f0)
                   (rnd-range -0.4f0 0.4f0) (rnd-range 0.3f0 0.5f0) (* p (rnd-range 0.035f0 0.06f0)) -2f0 0.3f0 +pal-fire+))))))

(defun-fast vfx-blade-embers (x0 y0 z0 x1 y1 z1 dt)
  "Zanka no Tachi (§4.1 Bankai): every flame is gone. One thin EMBER line along the charred blade (drawn just in
front of it, a glowing additive core in it), its presence breathing on threes, and a few ember flecks drifting up; the heat is the :HEAT aura's
charcoal wisps. Under the Bankai grade (spot-keep, hue 10) this line is the only colour in the frame."
  (with-floats (x0 y0 z0 x1 y1 z1 dt)
    (let* ((bx (- x1 x0)) (by (- y1 y0)) (bz (- z1 z0)) (d3 (drawing-no 8f0))
           (pk (toon-a +pal-ember+ (+ 0.75f0 (* 0.2f0 (hash01 d3 2.3f0))))) (sd (- -2f0 (i->f (mod (f->i d3) 3)))))
      (declare (single-float bx by bz d3 pk sd))
      (%away-from-eye (x0 y0 z0) -0.03f0
        (fx-ribbon x0 y0 z0 bx by bz 0.026f0 0.016f0 1f0 sd 0.05f0 pk 0.5f0 sd 0.05f0 pk d3 0f0 :segs 3 :mode :toon)
        (fx-ribbon x0 y0 z0 bx by bz 0.012f0 0.008f0 1f0 0.3f0 0.08f0 -0.9f0 1f0 0.3f0 0.08f0 -0.7f0 0f0 0f0 :segs 1))
      (dotimes (i (n-of 5f0 dt))
        (let* ((u (rnd01)))
          (declare (single-float u))
          (%t-blob (+ x0 (* u bx)) (+ y0 (* u by)) (+ z0 (* u bz)) (rnd-range -0.15f0 0.15f0) (rnd-range 0.3f0 0.7f0)
                   (rnd-range -0.15f0 0.15f0) (rnd-range 0.8f0 1.4f0) (rnd-range 0.015f0 0.028f0) -0.3f0 0.1f0 +pal-ember+))))))

(defun-fast vfx-smear (tr sm look)
  "The sword smear (docs/STYLE_STORM_DESIGN.md §2.6, §4.1 blade fire, §4.2 cleaves): a comet crescent through the
blade's 0.7 point over the trail samples of the last drawing (at most 5), fat at the blade, its tail thinning and
eroding. It is captured into SM when a new drawing (twos) starts and held for that drawing. LOOK 0 = FIRE
(Ryujin Jakka), 1 = REIATSU (Kenpachi: a white-cored yellow comet, every form), 2 = charcoal ink wash (Zanka no
Tachi). SM: x0 y0 z0 x1 y1 z1 bx by bz, half-width, drawing, presence."
  (declare (type f32vec tr sm) (fixnum look))
  (let* ((n (f->i (trail-count tr))) (dr (i->f (logand (f->i (* 12f0 (fx-clock))) 63))))
    (declare (fixnum n) (single-float dr))
    (when (/= (aref sm 10) dr)                          ; a new drawing: re-capture from the trail
      (setf (aref sm 10) dr (aref sm 11) 0f0)
      (when (>= n 3)
        (let* ((i0 (max 0 (- n 5))) (im (floor (+ i0 n -1) 2)) (i1 (1- n)) (o0 (* 6 i0)) (om (* 6 im)) (o1 (* 6 i1)))
          (declare (fixnum i0 im i1 o0 om o1))
          (dotimes (c 3)                                ; the 0.7 points: oldest, middle, newest -> control through the middle
            (let* ((p0 (+ (aref tr (+ o0 c)) (* 0.7f0 (- (aref tr (+ o0 c 3)) (aref tr (+ o0 c))))))
                   (pm (+ (aref tr (+ om c)) (* 0.7f0 (- (aref tr (+ om c 3)) (aref tr (+ om c))))))
                   (p1 (+ (aref tr (+ o1 c)) (* 0.7f0 (- (aref tr (+ o1 c 3)) (aref tr (+ o1 c)))))))
              (declare (single-float p0 pm p1))
              (setf (aref sm c) p0 (aref sm (+ c 3)) p1 (aref sm (+ c 6)) (- (* 2f0 pm) (* 0.5f0 (+ p0 p1))))))
          (let* ((lx (- (aref tr (+ o1 3)) (aref tr o1))) (ly (- (aref tr (+ o1 4)) (aref tr (+ o1 1))))
                 (lz (- (aref tr (+ o1 5)) (aref tr (+ o1 2)))))
            (declare (single-float lx ly lz))
            (setf (aref sm 9) (* 0.33f0 (f-sqrt (+ (* lx lx) (* ly ly) (* lz lz))))
                  (aref sm 11) (if (>= n 5) 0.98f0 0.6f0))))))
    (when (> (aref sm 11) 0f0)
      (fx-crescent (aref sm 0) (aref sm 1) (aref sm 2) (aref sm 3) (aref sm 4) (aref sm 5) (aref sm 6) (aref sm 7) (aref sm 8)
                   (aref sm 9) :comet 0.06f0 (if (= look 2) (+ 1000f0 dr) (+ 5f0 dr))
                   (case look (0 +pal-fire+) (1 +pal-reiatsu+) (t +pal-black-smoke+)) (aref sm 11) :push 0.15f0))
    nil))

;;; ---------------------------------------------------------------- fire wave / fireball / charge
(declaim (type f32vec *wave-xs* *wave-zs*))
(defvar *wave-xs* (make-f32 9) "The fire wave's base polyline (x), for FX-WALL.")
(defvar *wave-zs* (make-f32 9) "The fire wave's base polyline (z).")

(defmacro %wave-line (x z sx sz fx fz hw ox oz)
  "Fill *WAVE-XS* / *WAVE-ZS* with the fire wave's base: 9 points along its crescent, the middle ahead (the ends
bowed back 0.7 m), shifted by (OX OZ)."
  `(dotimes (%i 9)
     (let* ((%u (- (* 0.25f0 (i->f %i)) 1f0)) (%b (* 0.7f0 %u %u)))
       (declare (single-float %u %b))
       (setf (aref *wave-xs* %i) (+ ,x ,ox (* ,sx %u ,hw) (- (* %b ,fx)))
             (aref *wave-zs* %i) (+ ,z ,oz (* ,sz %u ,hw) (- (* %b ,fz)))))))

(defun-fast vfx-fire-wave (x z yaw age width dt &key (life 99.0))
  "Signature flame wave (§4.1 fire wave): ONE continuous drawn FIRE wall WIDTH m wide on a crescent centred on
ground point (x z), travelling toward YAW (the caller moves it; the position never steps), tallest in the middle,
its top cut into 6 tongues re-drawn every drawing (seen edge-on, 5 camera-facing tongues along it give it body);
behind it (away from the camera) an EMBER backing wall 20 % taller (the fire's own dark red: a black one read as
an ink outline, user review 2); a FIRE lens slash riding it at 1.2 m;
a narrow EMBER scorch on the ground behind; flame scraps flying ahead (black smoke puffs read as bubbles). Envelope (1 3 hold 18) over LIFE s: a white flash, grows, holds, erodes."
  (with-floats (x z yaw age width dt life)
    (let* ((fx (- (f-sin yaw))) (fz (- (f-cos yaw))) (sx (- fz)) (sz fx) (dr (drawing-no)) (a (sage age 2f0))
           (hold (f-max 0f0 (- (* 60f0 life) 22f0))) (e (camera-eye *camera*))
           (vx (- x (aref e 0))) (vz (- z (aref e 2))) (vl (f-max 0.01f0 (f-sqrt (+ (* vx vx) (* vz vz)))))
           (ox (* 0.35f0 (/ vx vl))) (oz (* 0.35f0 (/ vz vl))) (sd (i->f (mod (f->i dr) 7))))
      (declare (type f32vec e) (single-float fx fz sx sz dr a hold vx vz vl ox oz sd))
      (fx-envelope (es k fl ph) (a 1 3 hold 18)
        (let* ((hw (* 0.5f0 width es)) (hgt (* 2.6f0 es)))
          (declare (single-float hw hgt))
          (when (= ph 1)                              ; the flash drawing: a jagged white burst
            (fx-star x 1.2f0 z 0.48f0 0.69f0 12 (* 6.2831855f0 (hash01 0.3f0 dr)) 0f0 0f0 0.1f0 dr +pal-hit+ 0.98f0 :push 0.45f0))
          (%wave-line x z sx sz fx fz hw ox oz)          ; the backing, then the mass
          (fx-wall *wave-xs* *wave-zs* 9 (* 1.2f0 hgt) 6 0.25f0 (+ 20f0 sd) +pal-ember+ k)
          (%wave-line x z sx sz fx fz hw 0f0 0f0)
          (fx-wall *wave-xs* *wave-zs* 9 hgt 6 0.2f0 (+ 3f0 sd) +pal-fire+ k)
          (let* ((edge (f-abs (/ (+ (* sx vx) (* sz vz)) vl))) (tw (* 0.5f0 es (f-clamp (/ (- edge 0.35f0) 0.5f0) 0f0 1f0))))
            (declare (single-float edge tw))
            (when (> tw 0f0)                            ; seen along the wall (edge-on): camera-facing tongues give it body
              (dotimes (j 5)
                (let* ((i (+ 1 (floor (* 6 j) 4))) (f (i->f j)) (tsd (- -60f0 f sd))
                       (th (* hgt (+ 0.55f0 (* 0.35f0 (hash01 (+ f dr) 4.3f0))))) (tl (* 0.3f0 (- (hash01 (+ f dr) 6.7f0) 0.5f0))))
                  (declare (fixnum i) (single-float f tsd th tl))
                  (fx-ribbon (aref *wave-xs* i) 0.02f0 (aref *wave-zs* i) (* tl fx) th (* tl fz) tw 0f0 1f0 tsd 0.25f0
                             (toon-a +pal-fire+ k) 0.2f0 tsd 0.25f0 (toon-a +pal-fire+ k) (+ dr f) 0.08f0 :segs 6 :mode :toon)))))
          (fx-crescent (aref *wave-xs* 0) 1.2f0 (aref *wave-zs* 0) (aref *wave-xs* 8) 1.2f0 (aref *wave-zs* 8)
                       (+ x (* 0.7f0 fx)) 1.2f0 (+ z (* 0.7f0 fz)) (* 0.16f0 es) :lens 0.05f0 (+ 9f0 dr) +pal-fire+ k :push 0.5f0)
          (toon-ground-seg x z (- x (* 1.4f0 fx)) (- z (* 1.4f0 fz)) 0.03f0 (* 0.3f0 hw) 1f0 0.2f0 (+ 40f0 sd) 0.3f0
                           (toon-a +pal-ember+ (* 0.9f0 k)))
          (fx-ribbon x 0.05f0 z (* sx hw) 0f0 (* sz hw) 0.02f0 0.02f0 1f0 0.7f0 0.3f0 (* -0.4f0 k) 1f0 0.7f0 0.3f0 (* -0.4f0 k)
                     0f0 0f0 :segs 1)                    ; T光 along the base (a thin additive line)
          (fx-ribbon x 0.05f0 z (* (- sx) hw) 0f0 (* (- sz) hw) 0.02f0 0.02f0 1f0 0.7f0 0.3f0 (* -0.4f0 k) 1f0 0.7f0 0.3f0
                     (* -0.4f0 k) 0f0 0f0 :segs 1)
          (when (> k 0.3f0)
            (dotimes (i (n-of 14f0 dt))                  ; scraps: flames flung ahead off the crests
              (let* ((u (rnd-range -0.9f0 0.9f0)) (b (* 0.7f0 u u)) (sp (rnd-range 3f0 6f0)))
                (declare (single-float u b sp))
                (%t-blob (+ x (* sx u hw) (- (* b fx))) (* hgt (rnd-range 0.5f0 0.9f0)) (+ z (* sz u hw) (- (* b fz)))
                         (* sp fx) (rnd-range 0.5f0 1.5f0) (* sp fz) (rnd-range 0.25f0 0.4f0) (rnd-range 0.08f0 0.15f0)
                         -1f0 0.3f0 +pal-fire+))))
          (%light x 1.2f0 z 1f0 0.45f0 0.12f0 6f0 2.5f0 7)
          nil)))))

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
(defmacro %tring (x y z r w pal k seed &optional (segs 32))
  "A flat toon ring on the ground at height Y (+2 cm), radius R, band half-width W, both band edges inked.
The ring is an along shape whose heat varies around it, so it breaks into arcs as K fades."
  `(let* ((cx ,x) (cy (+ ,y 0.02f0)) (cz ,z) (ri (f-max 0f0 (- ,r ,w))) (ro (+ ,r ,w)) (pk (toon-a ,pal ,k))
          (sd (- -1f0 ,seed)) (da (/ 6.2831855f0 ,(float segs 1f0))))
     (declare (single-float cx cy cz ri ro pk sd da))
     (with-fx-verts (d o :toon ,(* 6 segs))
       (dotimes (i ,segs)
         (let* ((a0 (* da (i->f i))) (a1 (+ a0 da)) (c0 (f-cos a0)) (s0 (f-sin a0)) (c1 (f-cos a1)) (s1 (f-sin a1))
                (h0 (+ 0.3f0 (* 0.7f0 (f-abs (f-sin (+ (* 2.5f0 a0) sd)))))) (h1 (+ 0.3f0 (* 0.7f0 (f-abs (f-sin (+ (* 2.5f0 a1) sd)))))))
           (declare (single-float a0 a1 c0 s0 c1 s1 h0 h1))
           (vtx (+ cx (* ri c0)) cy (+ cz (* ri s0)) -1f0 0f0 h0 sd 0.12f0 pk)
           (vtx (+ cx (* ro c0)) cy (+ cz (* ro s0)) 1f0 0f0 h0 sd 0.12f0 pk)
           (vtx (+ cx (* ro c1)) cy (+ cz (* ro s1)) 1f0 0f0 h1 sd 0.12f0 pk)
           (vtx (+ cx (* ri c0)) cy (+ cz (* ri s0)) -1f0 0f0 h0 sd 0.12f0 pk)
           (vtx (+ cx (* ro c1)) cy (+ cz (* ro s1)) 1f0 0f0 h1 sd 0.12f0 pk)
           (vtx (+ cx (* ri c1)) cy (+ cz (* ri s1)) -1f0 0f0 h1 sd 0.12f0 pk))))))


(defmacro %brush-aura (x y z h k pal n rad w white)
  "A brush-flame aura (docs/STYLE_STORM_DESIGN.md §4.2 reiatsu, §4.3 Kikon rush): N tongues of palette PAL around
the body at radius RAD (half-width W at the base), drawn only behind and at the sides (the ones between the camera and the body are left
out, so the fighter stays readable inside), H tall x 0.8..1.25 with a lean, both re-drawn every drawing (twos),
the palette's dark hairline, and when WHITE is 1 a white core line in the back ones. K = presence. A macro (the auras run every frame: 0 B); N and WHITE literal fixnums."
  `(let* ((x ,x) (y ,y) (z ,z) (h ,h) (k ,k) (pal ,pal) (rad ,rad) (w ,w) (e (camera-eye *camera*)) (ex (- (aref e 0) x)) (ez (- (aref e 2) z)) (el (f-max 0.01f0 (f-sqrt (+ (* ex ex) (* ez ez)))))
         (dr (drawing-no)) (pk (toon-a pal (* 0.95f0 k))) (step (/ 6.2831855f0 ,(float n 1f0))))
    (declare (single-float x y z h k pal rad w) (type f32vec e) (single-float ex ez el dr pk step))
    (dotimes (i ,n)
      (let* ((f (i->f i)) (ang (+ (* step f) (* 0.3f0 (hash01 f 1.3f0))))
             (c (f-cos ang)) (sn (f-sin ang)) (front (/ (+ (* ex c) (* ez sn)) el)))
        (declare (single-float f ang c sn front))
        (when (< front 0.35f0)                        ; behind and at the sides only
          (let* ((hh (* h (+ 0.8f0 (* 0.45f0 (hash01 (+ f dr) 3.7f0))))) (lean (* 0.25f0 (- (hash01 (+ f dr) 5.9f0) 0.5f0)))
                 (bx (+ x (* rad c))) (bz (+ z (* rad sn))) (sd (- -1f0 (+ f (* 3f0 (i->f (mod (f->i dr) 5)))))))
            (declare (single-float hh lean bx bz sd))
            (fx-ribbon bx y bz (* lean c) hh (* lean sn) w 0f0 1f0 sd 0.3f0 pk 0.2f0 sd 0.3f0 pk (+ f dr) 0.12f0
                       :segs 6 :mode :toon)
            (when ,(if (eql white 1) '(< front -0.4f0) nil)
              (fx-ribbon bx (+ y 0.1f0) bz (* 0.7f0 lean c) (* 0.6f0 hh) (* 0.7f0 lean sn) 0.035f0 0f0 1f0 sd 0.1f0
                         (toon-a +pal-hit+ (* 0.95f0 k)) 0.2f0 sd 0.1f0 (toon-a +pal-hit+ (* 0.95f0 k)) 0f0 0f0 :segs 3 :mode :toon))))))
     nil))

(defmacro %kikon-aura (x y z h k)
  "The Kikon rush aura (the :KIKON kind of VFX-AURA): 7 BLOOD brush-flame tongues behind the body (radius 0.5 m),
white core lines in the back three, and a flat BLOOD ring at the feet. A macro: 0 B."
  `(let* ((x ,x) (y ,y) (z ,z) (h ,h) (k ,k) (dr (drawing-no)))
    (declare (single-float x y z h k dr))
    (%brush-aura x y z h k +pal-blood+ 7 0.5f0 0.2f0 1)
    (%tring x y z (+ 0.72f0 (* 0.06f0 (hash01 dr 8.3f0))) 0.07f0 +pal-blood+ (* 0.95f0 k) (i->f (mod (f->i dr) 7)))
    nil))

(defmacro %reiatsu-aura (x y z h k awake)
  "Kenpachi's reiatsu, yellow in every form (§4.2, user review 1). Base (AWAKE 0): 7 REIATSU tongues behind him at
0.45 m, 0.8 x his height, white core lines, white flecks rising. Nozarashi (AWAKE 1): 9 wider tongues at 0.5 m, 1.05 x,
3 thin inner white tongues, a flat REIATSU ring at the feet, one faint additive T光 glow and a yellow light. A macro: 0 B."
  `(let* ((x ,x) (y ,y) (z ,z) (h ,h) (k ,k) (dr (drawing-no)))
    (declare (single-float x y z h k dr))
    (if (= ,awake 1)
        (progn
          (with-cam () (%spr x (+ y (* 0.9f0 h)) z (* 0.35f0 h) 1f0 0.85f0 0.3f0 (* -0.06f0 k)))   ; T光 (over the head)
          (%brush-aura x y z (* 1.05f0 h) k +pal-reiatsu+ 9 0.5f0 0.19f0 1)
          (%brush-aura x y z (* 0.7f0 h) k +pal-hit+ 3 0.3f0 0.06f0 0)
          (%tring x y z (+ 0.8f0 (* 0.06f0 (hash01 dr 8.3f0))) 0.06f0 +pal-reiatsu+ (* 0.95f0 k) (i->f (mod (f->i dr) 7)))
          (%light x (+ y 1.2f0) z 1f0 0.8f0 0.25f0 5f0 0.7f0 8))
        (%brush-aura x y z (* 0.8f0 h) k +pal-reiatsu+ 7 0.45f0 0.16f0 1))
    nil))

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
:hellfire (fire aura + a ring of flames at the feet + light), :heat (Bankai: 4 charcoal wisps, drawn),
:evolution (faint aura in RGB, a list, default white), :reiatsu / :nozarashi (Kenpachi's drawn yellow
brush-flame aura, base / awakened: %REIATSU-AURA), :kikon (the drawn BLOOD rush aura), :breaker (pink;
K 0..1 brightens it over the last 8 f). For the other kinds K scales the alpha / presence (0..1). The
soft kinds (hellfire, evolution, breaker) also fade by *AURA-CAP* and when the camera is within ~4 m (a
close-up must still show the face); the drawn ones stand behind the body instead."
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
        (:heat                                           ; Bankai: the heat as 4 slow charcoal ink-wash wisps (threes)
         (let* ((e (camera-eye *camera*)) (ex (- (aref e 0) x)) (ez (- (aref e 2) z)) (el (f-max 0.01f0 (f-sqrt (+ (* ex ex) (* ez ez)))))
                (d3 (drawing-no 8f0)))
           (declare (type f32vec e) (single-float ex ez el d3))
           (dotimes (j 4)
             (let* ((f (i->f j)) (ang (+ (* 1.5708f0 f) 0.785f0 (* 0.4f0 (f-sin (+ (* 0.0375f0 (i->f (f->i (* 8f0 (clock))))) f)))))
                    (c (f-cos ang)) (sn (f-sin ang)))
               (declare (single-float f ang c sn))
               (when (< (/ (+ (* ex c) (* ez sn)) el) 0.3f0)
                 (let* ((hh (* h (+ 0.75f0 (* 0.3f0 (hash01 (+ f d3) 2.9f0))))) (lean (* 0.35f0 (- (hash01 (+ f d3) 6.1f0) 0.5f0)))
                        (sd (- -1001f0 f (* 4f0 (i->f (mod (f->i d3) 3))))))
                   (declare (single-float hh lean sd))
                   (fx-ribbon (+ x (* 0.42f0 c)) (+ y (* 0.25f0 h)) (+ z (* 0.42f0 sn)) (* lean c) hh (* lean sn) 0.15f0 0.01f0
                              1f0 sd 0.35f0 (toon-a +pal-black-smoke+ (* 0.9f0 ka)) 0.2f0 sd 0.35f0
                              (toon-a +pal-black-smoke+ (* 0.9f0 ka)) (+ f d3) 0.3f0 :segs 7 :mode :toon)))))))
        (:evolution
         (let* ((r (if rgb (f32 (elt rgb 0)) 1f0)) (g (if rgb (f32 (elt rgb 1)) 1f0)) (b (if rgb (f32 (elt rgb 2)) 1f0))
                (pulse (* ka (+ 0.25f0 (* 0.1f0 (f-sin (* 4f0 ph)))))))
           (declare (single-float r g b pulse))
           (%aura-tongues x y z (* 0.85f0 h) 5 0.33f0 r g b (- pulse) ph)
           (dotimes (i (n-of 12f0 dt))
             (fx-emit +p-glow+ (+ x (rnd-range -0.35f0 0.35f0)) (+ y (* h (rnd01))) (+ z (rnd-range -0.35f0 0.35f0))
                      0f0 (rnd-range 0.5f0 1.2f0) 0f0 0.7f0 0.04f0 0f0 r g b))))
        ((:reiatsu :nozarashi)
         (%reiatsu-aura x y z h (f-clamp k 0f0 1f0) (if (eq kind :nozarashi) 1 0))
         (dotimes (i (n-of (if (eq kind :nozarashi) 12f0 5f0) dt))   ; white flecks rising
           (%t-blob (+ x (rnd-range -0.45f0 0.45f0)) (+ y (* h (rnd-range 0.1f0 0.8f0))) (+ z (rnd-range -0.45f0 0.45f0))
                    0f0 (rnd-range 1.2f0 2.4f0) 0f0 (rnd-range 0.3f0 0.6f0) (rnd-range 0.015f0 0.03f0) 0f0 0.1f0 +pal-hit+)))
        (:kikon (%kikon-aura x y z (* 0.95f0 h) (f-clamp k 0.3f0 1f0))
         (dotimes (i (n-of 10f0 dt))
           (%t-blob (+ x (rnd-range -0.4f0 0.4f0)) (+ y (* h (rnd-range 0.2f0 0.9f0))) (+ z (rnd-range -0.4f0 0.4f0))
                    0f0 (rnd-range 1f0 2f0) 0f0 (rnd-range 0.4f0 0.7f0) (rnd-range 0.025f0 0.045f0) 0f0 0.2f0 +pal-blood+))
         (add-point-light x (+ y 1.0) z 1.0 0.15 0.2 4.5 1.0 6))
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
(defmacro %crack (x0 z0 x1 z1 w kg kc seed)
  "A jagged ground cut (x0 z0)→(x1 z1) of drawn toon strips (§4.2 Split the Meteor / Buttagiru): a DUST gash of
half-width W (narrow at both ends, a heavy dark edge) with a REIATSU core line; KG / KC their presences (0..1: the
far end erodes first). A macro: 0 B."
  `(let* ((x0 ,x0) (z0 ,z0) (x1 ,x1) (z1 ,z1) (w ,w) (kg ,kg) (kc ,kc) (seed ,seed) (dx (- x1 x0)) (dz (- z1 z0)) (l (f-sqrt (+ (* dx dx) (* dz dz)))) (n (max 2 (f->i (* 1.5f0 l))))
         (px (/ (- dz) (f-max l 1f-4))) (pz (/ dx (f-max l 1f-4))) (ox x0) (oz z0) (oh 1f0)
         (pg (toon-a +pal-dust+ kg)) (pc (toon-a +pal-reiatsu+ kc)))
    (declare (single-float x0 z0 x1 z1 w kg kc seed dx dz l px pz ox oz oh pg pc) (fixnum n))
    (when (> kg 0.02f0)
      (dotimes (i n)
        (let* ((u (/ (i->f (1+ i)) (i->f n))) (jag (if (= i (1- n)) 0f0 (* 0.35f0 (- (hash01 (i->f i) seed) 0.5f0))))
               (nx (+ x0 (* u dx) (* jag px))) (nz (+ z0 (* u dz) (* jag pz))) (nh (- 1f0 (* 0.8f0 u)))
               (ww (* w (+ 0.35f0 (* 0.65f0 (- 1f0 (f-abs (- (* 2f0 u) 1f0))))))))
          (declare (single-float u jag nx nz nh ww))
          (toon-ground-seg ox oz nx nz 0.03f0 ww oh nh seed 0.3f0 pg)
          (when (> kc 0.02f0) (toon-ground-seg ox oz nx nz 0.037f0 (* 0.28f0 ww) oh nh (+ seed 3f0) 0.15f0 pc))
          (setf ox nx oz nz oh nh))))))

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
        (:meteor                                         ; §4.2: gash + core, a light sheet for 3 drawings, rocks, dust
         (let* ((open (f-clamp (/ age 0.12f0) 0f0 1f0)) (glow (f-clamp (- 1f0 (/ age (* 0.6f0 life))) 0f0 1f0))
                (in (f-clamp (/ age 0.03f0) 0f0 1f0))     ; nothing at age 0 (a hazard frozen by a cinematic)
                (sa (sage age 2f0)) (dr (drawing-no)) (wave (* in (f-clamp (- 1f0 (/ age 0.6f0)) 0f0 1f0)))
                (off (+ 0.4f0 (* 9f0 (f-sqrt (sage age 3f0))))))
           (declare (single-float open glow in sa dr wave off))
           (%crack x0 z0 (+ x0 (* open dx)) (+ z0 (* open dz)) 0.42f0 (* in 0.98f0 fade) (* in glow) seed)
           (when (> wave 0.05f0)                         ; the ground heaving out on both sides (DUST, threes)
             (toon-ground-seg (+ x0 (* off px)) (+ z0 (* off pz)) (+ x1 (* off px)) (+ z1 (* off pz)) 0.04f0 0.22f0 1f0 0.2f0
                              (+ seed 7f0) 0.35f0 (toon-a +pal-dust+ wave))
             (toon-ground-seg (- x0 (* off px)) (- z0 (* off pz)) (- x1 (* off px)) (- z1 (* off pz)) 0.04f0 0.22f0 1f0 0.2f0
                              (+ seed 8f0) 0.35f0 (toon-a +pal-dust+ wave)))
           (when (and (> in 0f0) (< sa 0.25f0))          ; the light sheet standing on the cut
             (dotimes (k 5)
               (let* ((u (* 0.25f0 (i->f k))) (sd (- -2f0 (i->f k) (* 5f0 dr))) (pk (toon-a +pal-hit+ (- 0.98f0 (* 3f0 sa)))))
                 (declare (single-float u sd pk))
                 (fx-ribbon (+ x0 (* u dx)) 0f0 (+ z0 (* u dz)) 0f0 5f0 0f0 (f-min 0.35f0 (* 0.05f0 l)) 0.03f0
                            1f0 sd 0.15f0 pk 0.2f0 sd 0.15f0 pk dr 0f0 :segs 2 :mode :toon))))
           (when (< age 0.2f0)                           ; <= 20 particles: 8 inked rocks, 10 dust puffs
             (dotimes (i (n-of 40f0 dt))
               (let* ((u (rnd01)) (sd (if (< (rnd01) 0.5f0) -1f0 1f0)) (sp (rnd-range 3f0 6f0)))
                 (declare (single-float u sd sp))
                 (%t-shard (+ x0 (* u dx)) 0.2f0 (+ z0 (* u dz)) (* sd sp px) (rnd-range 2f0 5f0) (* sd sp pz)
                           (rnd-range 0.6f0 0.9f0) (rnd-range 0.1f0 0.2f0) 9f0 +pal-dust+)))
             (dotimes (i (n-of 50f0 dt))
               (let* ((u (rnd01)) (sd (if (< (rnd01) 0.5f0) -1f0 1f0)) (sp (rnd-range 1.5f0 3f0)))
                 (declare (single-float u sd sp))
                 (%t-blob (+ x0 (* u dx)) 0.2f0 (+ z0 (* u dz)) (* sd sp px) (rnd-range 0.3f0 1f0) (* sd sp pz)
                          (rnd-range 0.6f0 1f0) (rnd-range 0.25f0 0.4f0) -0.2f0 0.25f0 +pal-dust+))))))
        (t                                               ; :crack (Buttagiru): gash + core, dust, a few rocks
         (let* ((open (f-clamp (/ age 0.08f0) 0f0 1f0)) (glow (f-clamp (- 1f0 (/ age (* 0.5f0 life))) 0f0 1f0)))
           (declare (single-float open glow))
           (%crack x0 z0 (+ x0 (* open dx)) (+ z0 (* open dz)) 0.2f0 (* 0.98f0 fade) glow seed)
           (when (< age 0.2f0)
             (dotimes (i (n-of 20f0 dt))
               (let* ((u (rnd01)) (sd (if (< (rnd01) 0.5f0) -1f0 1f0)))
                 (declare (single-float u sd))
                 (%t-shard (+ x0 (* u dx)) 0.15f0 (+ z0 (* u dz)) (* sd 2.5f0 px) (rnd-range 2f0 4f0) (* sd 2.5f0 pz)
                           (rnd-range 0.5f0 0.8f0) (rnd-range 0.08f0 0.14f0) 9f0 +pal-dust+)))
             (dotimes (i (n-of 35f0 dt))
               (let* ((u (rnd01)) (sd (if (< (rnd01) 0.5f0) -1f0 1f0)))
                 (declare (single-float u sd))
                 (%t-blob (+ x0 (* u dx)) 0.15f0 (+ z0 (* u dz)) (* sd 2f0 px) (rnd-range 0.5f0 1.2f0) (* sd 2f0 pz)
                          (rnd-range 0.5f0 0.8f0) (rnd-range 0.18f0 0.3f0) -0.2f0 0.25f0 +pal-dust+)))))))
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

;;; ---------------------------------------------------------------- universal effects (toon, §4.3)
;;; Drawn in the notan world: hits, guard, clash, Hoho, Burst and Konpaku are mono (HIT white, STEEL,
;;; SOUL glass, DUST, INK) with a dark hairline; red (BLOOD) marks only Kikon, counters, guard breaks and
;;; blood droplets. A one-shot is a STAMP: kind, place, direction, age; STAMPS-DRAW redraws every live
;;; stamp each frame through FX-ENVELOPE on SAGE'd ages (so its shape changes on drawings, in step with
;;; the toon shader's noise), and frees it when its envelope ends. Scraps that fly (dust, blood, flame,
;;; glass) are toon particles emitted once. Hit flashes step on ones for their first 2 ticks, then twos.
(defconstant +stamp-n+ 48)
(defconstant +stamp-stride+ 12)
(declaim (type f32vec *stamps*))
(defvar *stamps* (make-f32 (* +stamp-n+ +stamp-stride+))
  "Live drawn one-shots: kind x y z dx dy dz age scale seed n flag (kind 0 = a free slot).")
(defparameter *stamp-kinds*
  '(:cut 1 :heavy 2 :fire 3 :counter 4 :guard 5 :guard-break 6 :clash 7 :hoho-out 8 :hoho-in 9 :burst 10
    :konpaku 11 :rush 12 :land 13)
  "Stamp kind -> its code in *STAMPS*.")
(defvar *stamp-seed* 0.0 "Advances per stamp: every one-shot draws its own irregular shape.")

(defun stamp (kind x y z &key (dx 0.0) (dy 0.0) (dz -1.0) (scale 1.0) (n 0))
  "Start the drawn one-shot KIND (a key of *STAMP-KINDS*) at (x y z), direction (dx dy dz) (unit)."
  (let* ((s *stamps*) (best 0) (oldest -1.0))
    (dotimes (i +stamp-n+)                              ; a free slot, else the oldest
      (let ((o (* i +stamp-stride+)))
        (when (= (aref s o) 0f0) (setf best i) (return))
        (when (> (aref s (+ o 7)) oldest) (setf oldest (aref s (+ o 7)) best i))))
    (let ((o (* best +stamp-stride+)))
      (setf *stamp-seed* (mod (+ *stamp-seed* 7.31) 40.0)
            (aref s o) (f32 (getf *stamp-kinds* kind)) (aref s (+ o 1)) (f32 x) (aref s (+ o 2)) (f32 y) (aref s (+ o 3)) (f32 z)
            (aref s (+ o 4)) (f32 dx) (aref s (+ o 5)) (f32 dy) (aref s (+ o 6)) (f32 dz) (aref s (+ o 7)) 0f0
            (aref s (+ o 8)) (f32 scale) (aref s (+ o 9)) (f32 *stamp-seed*) (aref s (+ o 10)) (f32 n) (aref s (+ o 11)) 0f0))
    nil))

(defun stamps-clear () (fill *stamps* 0f0))

(defmacro with-stamp ((o) &body body)
  "Name the stamp at offset O: X Y Z, DX DY DZ, AGE, SC (scale), SEED, N, and SDX SDY (its direction on
screen: camera right / up) and DRAWING (the fx clock's drawing number on twos, 0..63, for per-drawing
hashes). Symbol macros: a float a stamp kind does not use costs nothing (an unused bound float boxes)."
  `(let* ((%sv *stamps*) (%rt (camera-right *camera*)) (%up (camera-upv *camera*)))
     (declare (type f32vec %sv %rt %up) (ignorable %rt %up))
     (symbol-macrolet ((x (aref %sv (+ ,o 1))) (y (aref %sv (+ ,o 2))) (z (aref %sv (+ ,o 3)))
                       (dx (aref %sv (+ ,o 4))) (dy (aref %sv (+ ,o 5))) (dz (aref %sv (+ ,o 6))) (age (aref %sv (+ ,o 7)))
                       (sc (aref %sv (+ ,o 8))) (seed (aref %sv (+ ,o 9))) (n (aref %sv (+ ,o 10)))
                       (sdx (+ (* dx (aref %rt 0)) (* dy (aref %rt 1)) (* dz (aref %rt 2))))
                       (sdy (+ (* dx (aref %up 0)) (* dy (aref %up 1)) (* dz (aref %up 2))))
                       (drawing (i->f (logand (f->i (* 12f0 (fx-clock))) 63))))
       ,@body)))

(defmacro hit-age (age)
  "A hit flash's stepped age: on ones for its first 2 ticks, then on twos."
  `(if (< ,age 0.0834f0) (sage ,age 1f0) (sage ,age 2f0)))

(defmacro %star (x y z r0 r1 n sdx sdy wob seed pal k &optional (push 0.35f0))
  "An irregular hit star (FX-STAR) whose spikes reshuffle every drawing (the SEED plus the drawing)."
  `(fx-star ,x ,y ,z ,r0 ,r1 ,n (* 6.2831855f0 (hash01 1.7f0 (+ ,seed drawing))) ,sdx ,sdy ,wob (+ ,seed drawing) ,pal ,k
            :push ,push))

(defmacro %flash (x y z r seed)
  "Drawing 1 of a hit: the white flash, a round burst with a jagged rim (12 short hashed spikes)."
  `(fx-star ,x ,y ,z (* 0.8f0 ,r) (* 1.15f0 ,r) 12 (* 6.2831855f0 (hash01 0.3f0 ,seed)) 0f0 0f0 0.1f0 ,seed +pal-hit+ 0.98f0
            :push 0.45f0))

(defmacro %streak (x0 y0 z0 x1 y1 z1 w pal k seed)
  "A straight tapered toon streak (a lens crescent) from (X0..) to (X1..): speed lines, shards of light."
  `(let* ((%x0 ,x0) (%y0 ,y0) (%z0 ,z0) (%x1 ,x1) (%y1 ,y1) (%z1 ,z1))
     (declare (single-float %x0 %y0 %z0 %x1 %y1 %z1))
     (fx-crescent %x0 %y0 %z0 %x1 %y1 %z1 (* 0.5f0 (+ %x0 %x1)) (* 0.5f0 (+ %y0 %y1)) (* 0.5f0 (+ %z0 %z1))
                  ,w :comet 0.05f0 ,seed ,pal ,k :push 0.3f0)))

(defmacro %shards-out (n x y z sdx sdy age speed len w pal k seed &optional (spread 1.2f0) (push 0.3f0))
  "N shards flying out of (X Y Z) around the screen direction (SDX SDY) (+-SPREAD rad), SPEED m/s at AGE."
  `(let* ((%base (f-atan2 ,sdy ,sdx)))
     (declare (single-float %base))
     (dotimes (%i ,n)
       (let* ((%f (i->f %i)) (%a (+ %base (* ,spread 2f0 (- (hash01 %f ,seed) 0.5f0))))
              (%c (f-cos %a)) (%sn (f-sin %a)) (%rt (camera-right *camera*)) (%up (camera-upv *camera*))
              (%wx (+ (* %c (aref %rt 0)) (* %sn (aref %up 0)))) (%wy (+ (* %c (aref %rt 1)) (* %sn (aref %up 1))))
              (%wz (+ (* %c (aref %rt 2)) (* %sn (aref %up 2))))
              (%d (+ 0.15f0 (* ,age ,speed (+ 0.6f0 (* 0.8f0 (hash01 (+ %f 3.1f0) ,seed)))))))
         (declare (single-float %f %a %c %sn %wx %wy %wz %d) (type f32vec %rt %up))
         (fx-shard (+ ,x (* %d %wx)) (+ ,y (* %d %wy)) (+ ,z (* %d %wz)) %wx %wy %wz
                   (* ,len (+ 0.7f0 (* 0.6f0 (hash01 (+ %f 5.3f0) ,seed)))) ,w 0.06f0 (+ ,seed %f) ,pal ,k :push ,push)))))

;;; the stamp kinds' drawings: each a DEFUN-FAST of the slot offset (no float arguments: 0 B), T when done
(defun-fast %st-hit (o)
  "Hits :cut (6-spike HIT star, 4 shards, envelope 1 2 2 6), :heavy (8 spikes r 0.9, an impact crescent
held 3 drawings, 6 shards; envelope 1 2 3 8), :fire (FIRE star), :counter (BLOOD star)."
  (declare (fixnum o))
  (with-stamp (o)
    (let* ((kind (aref %sv o)) (heavy (= kind 2f0)) (pal (cond ((= kind 3f0) +pal-fire+) ((= kind 4f0) +pal-blood+) (t +pal-hit+)))
           (a (hit-age age)))
      (declare (single-float kind pal a))
      (fx-envelope (es k fl ph) (a 1 2 (if heavy 3f0 2f0) (if heavy 8f0 6f0))
        (with-cam ()
          (if (= ph 1)
              (%flash x y z (* sc (if heavy 0.26f0 0.18f0)) seed)
              (when (< ph 5)
                (let* ((r1 (* sc es (if heavy 0.9f0 (if (= kind 4f0) 0.75f0 0.55f0)))))
                  (declare (single-float r1))
                  (%star x y z (* 0.22f0 r1) r1 (if heavy 8 6) sdx sdy 0.06f0 seed pal k)
                  (%shards-out (if heavy 6 4) x y z sdx sdy a 5f0 (* sc 0.3f0) (* sc 0.045f0) pal k seed 0.7f0)
                  (when (< ph 3) (%spr x y z (* 0.2f0 r1) 1f0 1f0 1f0 0.3f0))   ; T光: a thin additive core
                  (when (and heavy (< a 0.25f0))                          ; the impact mark: held 3 drawings
                    (let* ((l (* sc 0.65f0)) (px (- sdy)) (py sdx)
                           (ax (+ x (* l (+ (* px rx) (* py ux))))) (ay (+ y (* l (+ (* px ry) (* py uy))))) (az (+ z (* l (+ (* px rz) (* py uz)))))
                           (bx (- x (* l (+ (* px rx) (* py ux))))) (by (- y (* l (+ (* px ry) (* py uy))))) (bz (- z (* l (+ (* px rz) (* py uz)))))
                           (cx (+ x (* 0.5f0 l (+ (* sdx rx) (* sdy ux))))) (cy (+ y (* 0.5f0 l (+ (* sdx ry) (* sdy uy)))))
                           (cz (+ z (* 0.5f0 l (+ (* sdx rz) (* sdy uz))))))
                      (declare (single-float l px py ax ay az bx by bz cx cy cz))
                      (fx-crescent ax ay az bx by bz cx cy cz (* sc 0.07f0) :lens 0.08f0 seed +pal-hit+ 0.98f0 :push 0.5f0)))))))
        (= ph 5)))))

(defun-fast %st-guard (o)
  "Guard: a hex-faceted STEEL plate (a regular FX-STAR) held 2 drawings + 4 steel shards thrown back."
  (declare (fixnum o))
  (with-stamp (o)
    (let* ((a (hit-age age)))
      (declare (single-float a))
      (fx-envelope (es k fl ph) (a 0 1 4 5)
        (when (< ph 5)
          (fx-star x y z 1f0 (* sc 0.5f0 es) 6 (* 0.5236f0 (hash01 2.1f0 seed)) 0f0 0f0 0.03f0 seed +pal-steel+ k :push 0.4f0)
          (fx-star x y z 1f0 (* sc 0.26f0 es) 6 (* 0.5236f0 (hash01 2.1f0 seed)) 0f0 0f0 0.03f0 (+ seed 1f0) +pal-hit+ k :push 0.42f0)
          (%shards-out 4 x y z (- sdx) (- sdy) a 4f0 (* sc 0.22f0) (* sc 0.04f0) +pal-steel+ k seed 1.1f0))
        (= ph 5)))))

(defun-fast %st-guard-break (o)
  "Guard break: a HIT star and 12 INK shards with BLOOD edges (a red kite behind each black one)."
  (declare (fixnum o))
  (with-stamp (o)
    (let* ((a (hit-age age)))
      (declare (single-float a))
      (fx-envelope (es k fl ph) (a 1 2 3 10)
        (if (= ph 1)
            (%flash x y z (* sc 0.3f0) seed)
            (when (< ph 5)
              (%star x y z (* sc 0.2f0) (* sc es 0.85f0) 8 sdx sdy 0.06f0 seed +pal-hit+ k)
              (%shards-out 12 x y z sdx sdy a 4.5f0 (* sc 0.42f0) (* sc 0.11f0) +pal-blood+ k seed 3.1f0)
              (%shards-out 12 x y z sdx sdy a 4.5f0 (* sc 0.34f0) (* sc 0.075f0) +pal-ink+ k seed 3.1f0 0.36f0)))
        (= ph 5)))))

(defun-fast %st-clash (o)
  "Clash: an 8-spike HIT star (r 1.2) and a flat ground ring running out (envelope 1 2 4 10)."
  (declare (fixnum o))
  (with-stamp (o)
    (let* ((a (hit-age age)))
      (declare (single-float a))
      (fx-envelope (es k fl ph) (a 1 2 4 10)
        (if (= ph 1)
            (%flash x y z (* sc 0.34f0) seed)
            (when (< ph 5)
              (%star x y z (* sc 0.25f0) (* sc es 1.2f0) 8 0f0 1f0 0.06f0 seed +pal-hit+ k)
              (%shards-out 6 x y z 1f0 0f0 a 6f0 (* sc 0.35f0) (* sc 0.05f0) +pal-hit+ k seed 3.1f0)))
        (when (< ph 5) (%tring x 0f0 z (+ 0.4f0 (* 6f0 (sage age 2f0))) 0.07f0 +pal-hit+ (* 0.98f0 k) seed))
        (= ph 5)))))

(defun-fast %st-hoho (o)
  "Hoho vanish (:hoho-out): 6 horizontal speed streaks at body height (drawings 1-2), then DUST puffs on
the ground (drawing 3 on); the ink afterimage is the fighter's (DRAW-FIGHTER). Appear (:hoho-in): 6
streaks converging for 3 drawings, then a small HIT star."
  (declare (fixnum o))
  (with-stamp (o)
    (let* ((kind (aref %sv o)) (a (sage age 2f0)) (hx (- dz)) (hz dx) (gy (f-max 0f0 (- y 1f0))))  ; hx hz: the side
      (declare (single-float kind a hx hz gy))
      (if (= kind 8f0)
          (fx-envelope (es k fl ph) (a 0 0 10 14)
            (when (< a 0.17f0)
              (dotimes (i 6)
                (let* ((f (i->f i)) (h (+ gy 0.3f0 (* 0.26f0 f))) (sd (if (evenp i) 1f0 -1f0))
                       (l0 (+ 0.2f0 (* 0.5f0 (hash01 f seed)))) (l1 (+ l0 1.2f0 (* 9f0 a))))
                  (declare (single-float f h sd l0 l1))
                  (%streak (+ x (* sd l0 hx)) h (+ z (* sd l0 hz)) (+ x (* sd l1 hx)) h (+ z (* sd l1 hz))
                           (* sc 0.035f0) +pal-hit+ (- 0.98f0 (* 4f0 a)) (+ seed f)))))
            (when (>= a 0.16f0)
              (dotimes (i 3)
                (let* ((f (i->f i)) (ang (+ (* 2.1f0 f) seed)) (r (+ 0.3f0 (* 1.2f0 (- a 0.16f0)))))
                  (declare (single-float f ang r))
                  (fx-disc (+ x (* r (f-cos ang))) (+ gy 0.18f0) (+ z (* r (f-sin ang))) (* sc (+ 0.2f0 (* 0.3f0 a))) 0.2f0
                           (+ seed f) +pal-dust+ k))))
            (= ph 5))
          (fx-envelope (es k fl ph) (a 0 0 6 6 :anticipate 6)
            (if (= ph 0)
                (dotimes (i 6)
                  (let* ((f (i->f i)) (ang (+ seed (* 1.047f0 f))) (c (f-cos ang)) (sn (f-sin ang))
                         (r1 (- 2.2f0 (* 16f0 a))) (r0 (- r1 0.9f0)))
                    (declare (single-float f ang c sn r1 r0))
                    (when (> r0 0.05f0)
                      (%streak (+ x (* r1 c hx)) (+ y (* 0.9f0 r1 sn)) (+ z (* r1 c hz)) (+ x (* r0 c hx)) (+ y (* 0.9f0 r0 sn))
                               (+ z (* r0 c hz)) (* sc 0.03f0) +pal-hit+ 0.98f0 (+ seed f)))))
                (when (< ph 5)
                  (%star x y z (* sc 0.08f0) (* sc es 0.4f0) 6 0f0 0f0 0.05f0 seed +pal-hit+ k)))
            (= ph 5))))))

(declaim (type f32vec *burst-flag*))
(defvar *burst-flag* (make-f32 1) "[0] 1 once a Burst stamp's ring fired: main.lisp gives it its beat (a negative frame, the back-rim).")
(defun-fast %st-burst (o)
  "Burst Reverse at the feet: anticipation (4 f, 8 lines converging on the chest), then a flat expanding
double ring (a thick white leading edge, a thin STEEL trailing one, both with a dark hairline) and 8
steel shards. The frame it fires: a 1 f negative frame and a 3 f white back-rim (N = the stamp's flag)."
  (declare (fixnum o))
  (with-stamp (o)
    (let* ((a (sage age 1f0)) (cy (+ y 1.1f0)))
      (declare (single-float a cy))
      (fx-envelope (es k fl ph) (a 0 3 3 16 :anticipate 4)
        (cond ((= ph 0)
               (dotimes (i 8)
                 (let* ((f (i->f i)) (ang (+ seed (* 0.785f0 f))) (c (f-cos ang)) (sn (f-sin ang))
                        (r1 (- 2.4f0 (* 25f0 a))) (r0 (- r1 1.0f0)))
                   (declare (single-float f ang c sn r1 r0))
                   (when (> r0 0.1f0)
                     (%streak (+ x (* r1 c)) (+ cy (* r1 sn)) z (+ x (* r0 c)) (+ cy (* r0 sn)) z (* sc 0.035f0) +pal-steel+ 0.98f0 (+ seed f))))))
              ((< ph 5)
               (when (< (aref %sv (+ o 11)) 0.5f0)
                 (setf (aref %sv (+ o 11)) 1f0 (aref (the f32vec *burst-flag*) 0) 1f0))
               (let* ((r (* sc (+ 0.5f0 (* 7f0 (- a 0.066f0))))))
                 (declare (single-float r))
                 (%tring x y z r 0.16f0 +pal-hit+ k seed)
                 (%tring x y z (f-max 0.1f0 (- r 0.55f0)) 0.05f0 +pal-steel+ k (+ seed 1f0)))
               (%shards-out 8 x cy z 0f0 1f0 a 7f0 (* sc 0.3f0) (* sc 0.05f0) +pal-steel+ k seed 3.1f0)))
        (= ph 5)))))

(defun-fast %st-konpaku (o)
  "A lost Konpaku: a SOUL star and a SOUL ring (the 3N glass shards are toon particles)."
  (declare (fixnum o))
  (with-stamp (o)
    (let* ((a (hit-age age)))
      (declare (single-float a))
      (fx-envelope (es k fl ph) (a 1 2 3 10)
        (if (= ph 1)
            (%flash x y z (* sc 0.22f0) seed)
            (when (< ph 5)
              (%star x y z (* sc 0.15f0) (* sc es 0.7f0) 7 0f0 1f0 0.05f0 seed +pal-soul+ k)
              (%tring x (- y 1.1f0) z (+ 0.3f0 (* 3f0 a)) 0.05f0 +pal-soul+ k seed)))
        (= ph 5)))))

(defun-fast %st-ring (o)
  "Ground rings: :rush (the Kikon rush starts: a BLOOD ring and an inner one running out) and :land (DUST)."
  (declare (fixnum o))
  (with-stamp (o)
    (let* ((rush (= (aref %sv o) 12f0)) (a (sage age 2f0)) (pal (if rush +pal-blood+ +pal-dust+)))
      (declare (single-float a pal))
      (fx-envelope (es k fl ph) (a 0 2 3 14)
        (when (< ph 5)
          (%tring x y z (* sc (+ 0.4f0 (* (if rush 5f0 2.5f0) a))) (* sc (if rush 0.12f0 0.06f0)) pal k seed)
          (when rush (%tring x y z (* sc (+ 0.3f0 (* 2.5f0 a))) 0.04f0 pal k (+ seed 1f0))))
        (= ph 5)))))

(defun-fast stamps-draw (dt)
  "Age every live stamp by DT (effect seconds: 0 while paused) and draw it; free the finished ones."
  (declare (single-float dt))
  (let* ((s *stamps*))
    (declare (type f32vec s))
    (dotimes (i +stamp-n+)
      (let* ((o (* i +stamp-stride+)) (kind (f->i (aref s o))))
        (declare (fixnum o kind))
        (when (> kind 0)
          (setf (aref s (+ o 7)) (+ (aref s (+ o 7)) dt))
          (when (case kind
                  ((1 2 3 4) (%st-hit o)) (5 (%st-guard o)) (6 (%st-guard-break o)) (7 (%st-clash o))
                  ((8 9) (%st-hoho o)) (10 (%st-burst o)) (11 (%st-konpaku o)) ((12 13) (%st-ring o)) (t t))
            (setf (aref s o) 0f0)))))
    nil))

;;; the calls the game makes (events, cinematics)
(defun-fast vfx-hit (x y z kind &key (dx 0.0) (dz -1.0))
  "Hit spark at (x y z); (dx dz) = the hit direction (attacker -> victim). KIND :cut :heavy :fire
:counter :guard :guard-break :clash (:breaker = :guard-break). Heavy hits throw 3 DUST puffs and 5-8
ink-blood droplets, fire hits 4 flame scraps. Also starts the 0.15 s hit light (white: no warm pixels)."
  (with-floats (x y z dx dz)
    (let* ((l (f-max 0.01f0 (f-sqrt (+ (* dx dx) (* dz dz))))) (dx (/ dx l)) (dz (/ dz l))
           (kind (if (eq kind :breaker) :guard-break kind)))
      (declare (single-float l dx dz))
      (stamp kind x y z :dx dx :dy 0.0 :dz dz)
      (case kind
        (:heavy (dotimes (i 3)
                  (%t-blob (+ x (rnd-range -0.2f0 0.2f0)) (- y 0.3f0) (+ z (rnd-range -0.2f0 0.2f0)) (* 1.2f0 dx) 0.6f0 (* 1.2f0 dz)
                           (rnd-range 0.5f0 0.8f0) (rnd-range 0.16f0 0.26f0) -0.2f0 0.2f0 +pal-dust+))
                (dotimes (i (+ 5 (f->i (* 3.99f0 (rnd01)))))
                  (let* ((sp (rnd-range 2.5f0 5f0)))
                    (declare (single-float sp))
                    (%t-blob x y z (* sp (+ dx (rnd-range -0.4f0 0.4f0))) (rnd-range 0.5f0 2.5f0) (* sp (+ dz (rnd-range -0.4f0 0.4f0)))
                             (rnd-range 0.35f0 0.6f0) (rnd-range 0.03f0 0.06f0) 9f0 0.3f0 +pal-blood+))))
        (:fire (dotimes (i 4)
                 (%t-blob x y z (* 2f0 (+ dx (rnd-range -0.6f0 0.6f0))) (rnd-range 1f0 2.5f0) (* 2f0 (+ dz (rnd-range -0.6f0 0.6f0)))
                          (rnd-range 0.3f0 0.5f0) (rnd-range 0.1f0 0.16f0) -2f0 0.3f0 +pal-fire+)))
        (:guard-break (dotimes (i 4)
                        (%t-blob x y z (* 3f0 (+ dx (rnd-range -0.5f0 0.5f0))) (rnd-range 0.5f0 2.5f0) (* 3f0 (+ dz (rnd-range -0.5f0 0.5f0)))
                                 (rnd-range 0.35f0 0.55f0) (rnd-range 0.03f0 0.05f0) 9f0 0.3f0 +pal-blood+))))
      (flash-light x y z 1.0 1.0 1.0)
      nil)))

(defun-fast vfx-hoho (x y z appear-p &key (dx 0.0) (dz -1.0))
  "Flash step, (x y z) = the body's centre (~1 m up): vanish (APPEAR-P NIL: streaks, then DUST puffs;
the ink afterimage is drawn by the fighter) or appear (converging streaks, then a small HIT star).
(DX DZ): the fighter's facing (the streaks run sideways to it)."
  (with-floats (x y z dx dz)
    (stamp (if appear-p :hoho-in :hoho-out) x y z :dx dx :dz dz)
    nil))

(defun-fast vfx-burst (x y z)
  "Burst Reverse at the user's feet (x y z): see %ST-BURST."
  (with-floats (x y z)
    (stamp :burst x y z)
    (flash-light x (+ y 1f0) z 0.85 0.9 1.0)
    nil))

(defun-fast vfx-konpaku-shatter (x y z n)
  "N soul-glass Konpaku lost at (x y z): 3N SOUL shards burst out (toon particles), a SOUL star, a ring."
  (declare (fixnum n))
  (with-floats (x y z)
    (stamp :konpaku x y z)
    (dotimes (i (* 3 n))
      (let* ((a (rnd-range 0f0 6.2832f0)) (sp (rnd-range 2.5f0 5.5f0)))
        (declare (single-float a sp))
        (%t-shard x y z (* sp (f-cos a)) (rnd-range 0.5f0 4f0) (* sp (f-sin a)) (rnd-range 0.6f0 1.0f0) (rnd-range 0.12f0 0.22f0) 7f0
                  +pal-soul+)))
    (flash-light x y z 0.8 0.9 1.0)
    nil))

(defun-fast vfx-kikon-rush (x z)
  "The Kikon rush starts at feet (x z): a BLOOD ground ring running out and DUST puffs kicked up."
  (with-floats (x z)
    (stamp :rush x 0.0 z)
    (dotimes (i 5)
      (let* ((a (rnd-range 0f0 6.2832f0)))
        (declare (single-float a))
        (%t-blob (+ x (* 0.4f0 (f-cos a))) 0.15f0 (+ z (* 0.4f0 (f-sin a))) (* 2.5f0 (f-cos a)) 0.5f0 (* 2.5f0 (f-sin a))
                 (rnd-range 0.5f0 0.8f0) (rnd-range 0.2f0 0.3f0) -0.3f0 0.25f0 +pal-dust+)))
    nil))

(defun-fast vfx-step-dust (x z dx dz)
  "Step / dash start at feet (x z) moving along (dx dz): 3 DUST puffs kicked back."
  (with-floats (x z dx dz)
    (dotimes (i 3)
      (%t-blob (+ x (rnd-range -0.2f0 0.2f0)) 0.12f0 (+ z (rnd-range -0.2f0 0.2f0))
               (- (* 2f0 dx) (rnd-range -0.6f0 0.6f0)) (rnd-range 0.3f0 0.8f0) (- (* 2f0 dz) (rnd-range -0.6f0 0.6f0))
               (rnd-range 0.4f0 0.6f0) (rnd-range 0.14f0 0.22f0) -0.2f0 0.25f0 +pal-dust+))
    nil))

(defun vfx-shockwave (x z r life &key (rgb '(1.0 0.8 0.5)) pal)
  "Expanding ground ring at (x z) to radius R over LIFE s. PAL (a toon palette): a :land-style toon ring
+ DUST puffs (PAL +PAL-DUST+); else the soft coloured ring of RGB with a thinner inner ring and dust."
  (if pal
      (progn (stamp :land x 0.0 z :scale (/ r 2.5))
             (dotimes (i 4)
               (let ((a (rnd-range 0.0 6.2832)))
                 (%t-blob (f32 (+ x (* 0.3 (cos a)))) 0.12f0 (f32 (+ z (* 0.3 (sin a)))) (f32 (* 2.0 (cos a))) 0.4f0 (f32 (* 2.0 (sin a)))
                          0.6f0 0.2f0 -0.2f0 0.25f0 (f32 pal)))))
      (let ((cr (f32 (elt rgb 0))) (cg (f32 (elt rgb 1))) (cb (f32 (elt rgb 2))))
        (fx-ring x 0.05 z 0.3 r life cr cg cb :flat t :width (* 0.04 r))
        (fx-ring x 0.05 z 0.2 (* 0.7 r) (* 0.8 life) cr cg cb :flat t :width (* 0.015 r))
        (fx-burst +p-dust+ 16 (f32 x) 0.15f0 (f32 z) 0f0 0.1f0 0f0 1f0 (f32 (* 0.8 (/ r life))) (f32 (/ r life))
                  (f32 (* 0.5 life)) 0.35f0 0.55f0 0.5f0 0.45f0)))
    nil)

(defun-fast vfx-soul-flame (x y z age)
  "The red soul flame floating over a Kikon-able victim (x y z = the flame's base, e.g. 0.4 m over the
head): one BLOOD ribbon with a dark hairline, boiling through 3 drawings (its seed cycles), a small
white core. AGE (s) bobs it; no particles."
  (with-floats (x y z age)
    (let* ((y (+ y (* 0.05f0 (f-sin (* 3f0 (sage age 2f0))))))
           (dr (i->f (mod (f->i (* 12f0 (fx-clock))) 3))) (seed (+ 11f0 (* 5f0 dr)))
           (h (+ 0.9f0 (* 0.12f0 (hash01 dr 2.7f0)))) (lean (* 0.08f0 (- (hash01 dr 4.1f0) 0.5f0))))
      (declare (single-float y dr seed h lean))
      (fx-ribbon x y z lean h 0f0 0.22f0 0f0 1f0 (- seed) 0.3f0 (toon-a +pal-blood+ 0.95f0) 0.2f0 (- seed) 0.3f0
                 (toon-a +pal-blood+ 0.95f0) (* 2f0 dr) 0.07f0 :segs 6 :mode :toon)
      (fx-ribbon (+ x 0.1f0) (+ y 0.05f0) z (+ 0.1f0 lean) (* 0.55f0 h) 0f0 0.1f0 0f0 1f0 (- -3f0 seed) 0.3f0
                 (toon-a +pal-blood+ 0.95f0) 0.2f0 (- -3f0 seed) 0.3f0 (toon-a +pal-blood+ 0.95f0) (+ 1f0 dr) 0.05f0 :segs 4 :mode :toon)
      (fx-ribbon x (+ y 0.04f0) z (* 0.5f0 lean) (* 0.5f0 h) 0f0 0.035f0 0f0 1f0 (- -5f0 seed) 0.1f0
                 (toon-a +pal-hit+ 0.95f0) 0.2f0 (- -5f0 seed) 0.1f0 (toon-a +pal-hit+ 0.95f0) (* 2f0 dr) 0.03f0 :segs 3 :mode :toon))))

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
