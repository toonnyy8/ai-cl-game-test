;;;; body.lisp — how a character looks: rigid parts per rig joint (DEFBODY over the engine's shape
;;;; spec: BUILD-PARTS / DRAW-PARTS in engine/lisp/body.lisp), swappable weapons (DEFWEAPON), drawing
;;;; a posed character (DRAW-BODY), the generic stance and the shared reaction clips (:sh-*) every
;;;; character plays on the same rig. Attack clips use the engine's DEFSTRIKE (anim.lisp).
;;;;
;;;; API (what the fighter / cinema / select code calls):
;;;;   (find-body key)  (find-weapon key)          registered bodies / weapons (error if unknown)
;;;;   (body-scale b) (body-hunch b) (body-props b)  → the last three args of POSE-FK!
;;;;   (body-hurt-r b) (body-hurt-h b)             hurt cylinder, world metres (already scaled)
;;;;   (bodies-init) (body-load-steps)            :load steps: every weapon mesh, then one step per body
;;;;   (draw-body body joints x y z yaw &key weapon hidden hide tint rim emissive flash alpha shadow)
;;;;       JOINTS = the f32vec POSE-FK! filled; X Y Z = the fighter's feet (blob shadow; YAW unused,
;;;;       kept for the call shape). WEAPON = weapon key or NIL (drawn in the :weapon-r joint).
;;;;       HIDDEN = joint bitmask (JOINT-MASK ...): parts, glows and the weapon of those joints are
;;;;       skipped. HIDE = a tag or list of tags of tagged parts to skip.
;;;;       FACE :neutral / :shout / :hurt = the expression (docs/STYLE_STORM_DESIGN.md §2.5): the face shapes are
;;;;       tagged :face-neutral / :face-shout / :face-hurt and the two not shown are hidden (FACE-HIDE; a
;;;;       non-NIL HIDE replaces that list, so a caller that hides parts names the faces too).
;;;;       TINT (r g b) multiplies the solid parts' colours; RIM (f32vec, RIM-VEC) replaces the body's
;;;;       silhouette rim; EMISSIVE adds glow to solid parts; FLASH 0..1 = hit flash to white;
;;;;       ALPHA < 1 = transparent (Hoho vanish). Mirror match: P2 passes :tint *MIRROR-TINT*
;;;;       :rim *MIRROR-RIM*. Conses a few boxed floats per call (keyword floats), nothing else.
;;;;       Look (docs/STYLE_STORM_DESIGN.md §2): every part is a toon character draw (fs_toon: two
;;;;       tones, cold designed shadows, darker toward the feet), so RIM is ignored; built without
;;;;       per-face jitter and with round normals on spheres / cylinders. The shadow is a hard ink disc.
;;;;       Ink (§2.4): every solid shape and weapon section gets an ink hull (*BODY-INK* colours, a
;;;;       shape's :ink k = width, small shapes and strokes none), drawn when ALPHA is 1.
;;;;   (draw-weapon key m &key alpha flash emissive rim)   a weapon at world matrix M (weapon frame)
;;;;   (draw-planted-weapon key x z yaw &key alpha emissive)  a blade stuck in the ground (Ikkotsu, Kaka)
;;;;   (body-weapon-tip body weapon joints out) / (body-weapon-base ...)   world points of the
;;;;       held weapon's tip / blade base (0.25 m up the blade) into OUT, for trails and fire.
(in-package :duel)

;;; ---------------------------------------------------------------- bodies
(setf *part-jitter* 0.0 *part-smooth* t)      ; toon bodies: flat colour per shape, round spheres / cylinders

(defstruct (body (:constructor %make-body))
  (name nil)
  (scale 1f0 :type single-float)        ; uniform rig scale (1.0 = 1.80 m tall)
  (width 1f0 :type single-float)        ; part girth multiplier (x and z of every shape)
  (hunch 0f0 :type single-float)        ; extra spine flex, radians
  (hurt-r 0.35f0 :type single-float)    ; hurt cylinder (world metres, already scaled)
  (hurt-h 1.8f0 :type single-float)
  (palette nil) (spec nil)
  (rim nil)                             ; f32vec linear rgb x strength: silhouette rim (readability)
  (props nil)                           ; NIL or MAKE-RIG-PROPORTIONS vector: the last arg of POSE-FK!
  (girth nil)                           ; ((joint sx sy sz) ...): that joint's shapes scaled in its frame (GIRTH-SPEC)
  (clips nil)                           ; plist clip -> clip this body plays instead (a variant's own walk / guard)
  (ink nil)                             ; its own keyline colours (as *BODY-INK*), NIL = *BODY-INK*
  (parts (make-array +nj+ :initial-element nil) :type simple-vector)  ; untagged solid mesh per joint
  (extras nil)                          ; list of #(joint mesh tint emissive tag): glows + tagged parts
  (hulls nil))                          ; list of #(joint mesh tag): the ink outlines (BUILD-PARTS)

(defparameter *body-ink* '((:skin . #x3A1E1A) (:skin-d . #x3A1E1A) (:black . #x4A5062) (:hair . #x4A5062) (:brow . #x4A5062)
                           (t . #x101018))
  "Ink of the body hulls by shape colour (docs/STYLE_STORM_DESIGN.md §2.4, §2.5): red-brown on skin, a cold
grey keyline on black cloth and hair (dark on the ground, a separating line on the dark sky), near-black
on everything else.")

(defvar *bodies* (make-hash-table :test 'eq))
(defun find-body (name) (or (gethash name *bodies*) (error "unknown body ~s" name)))

(defvar *mirror-tint* (hexc #xD8E2F2) "Mirror match: P2's body tint (a cold cast: it shows on the white parts).")
(defvar *mirror-rim* (rim-vec #x5A8CFF 0.9) "Mirror match: P2's strong blue silhouette rim.")

(defmacro defbody (name (&rest props &key &allow-other-keys) &body parts)
  "Register a body. PROPS: :scale :width :hunch (degrees) :hurt-r :hurt-h (world m)
:palette ((key #xRRGGBB) ...) :rim (#xRRGGBB strength) :props (MAKE-RIG-PROPORTIONS keys, e.g.
:shoulders 1.3 = a wider chest that keeps the arms out of a broad haori), :girth ((joint sx sy sz) ...)
(every shape of JOINT, size and :at, scaled in the joint frame: a smaller head, a narrower chest, arm
shapes as long as :props :arms makes the bones; see GIRTH-SPEC).
PARTS: (joint shape ...), the engine's shape spec (engine/lisp/body.lisp header: :box :bevel :cyl
:cone :sphere :wedge with :at :rot :c :seg :top :stretch :tag, and (:glow e shape [tag])); a :tag
part is its own mesh, so DRAW-BODY :hide skips it. Meshes are built by BODIES-INIT (after the GPU
device exists)."
  `(setf (gethash ,name *bodies*)
         (%make-body :name ,name :spec ',parts
                     ,@(loop for (k v) on props by #'cddr
                             append (case k
                                      ((:palette :girth) (list k `',v))
                                      (:rim (list k `(rim-vec ,@v)))
                                      (:props (list k `(make-rig-proportions ,@v)))
                                      (:hunch (list k `(deg ,v)))
                                      (t (list k `(f32 ,v))))))))

(defun body-variant (name of &key palette parts clips ink)
  "Register body NAME as a variant of body OF: the same rig, scale and hurt cylinder (the sim can't tell them apart),
PALETTE entries taking precedence over OF's, and PARTS ((joint shape ...) ...) added to those joints (Kenpachi's
Bankai oni: a muted crimson skin, horns, irisless eyes, the forearm cracks). CLIPS: a plist of the shared clips it
plays its own way instead (FIGHTER.LISP PLAY-CLIP; the oni's prowl and guard): art only, the sim never reads a clip.
INK: its own keyline colours (as *BODY-INK*; the white Rukia's ice blue)."
  (let ((b (find-body of)))
    (setf (gethash name *bodies*)
          (%make-body :name name :scale (body-scale b) :width (body-width b) :hunch (body-hunch b)
                      :hurt-r (body-hurt-r b) :hurt-h (body-hurt-h b) :rim (body-rim b) :props (body-props b)
                      :girth (body-girth b) :palette (append palette (body-palette b)) :clips clips :ink ink
                      :spec (append (loop for (j . shapes) in (body-spec b)
                                          collect (list* j (append shapes (rest (assoc j parts)))))
                                    (remove-if (lambda (p) (assoc (first p) (body-spec b))) parts))))))

(defun girth-shape (shape s)
  "SHAPE with its size and :at scaled by S = (sx sy sz) in its joint's frame (radii by (sx + sz) / 2)."
  (if (eq (first shape) :glow)
      (list* :glow (second shape) (girth-shape (third shape) s) (cdddr shape))
      (destructuring-bind (sx sy sz) s
        (let* ((opts (copy-list (member-if #'keywordp (cdr shape)))) (nums (ldiff (cdr shape) opts))
               (r (* 0.5 (+ sx sz))) (at (getf opts :at)))
          (when at (setf (getf opts :at) (mapcar #'* (list (or (first at) 0) (or (second at) 0) (or (third at) 0)) (list sx sy sz))))
          (when (getf opts :top) (setf (getf opts :top) (* r (getf opts :top))))
          (when (getf opts :stretch) (setf (getf opts :stretch) (* sy (getf opts :stretch))))
          (append (list (first shape))
                  (ecase (first shape)
                    ((:box :wedge) (mapcar #'* nums (list sx sy sz)))
                    (:bevel (list (* sx (first nums)) (* sy (second nums)) (* sz (third nums)) (* (min sx sy sz) (fourth nums))))
                    ((:cyl :cone) (list (* r (first nums)) (* sy (second nums))))
                    (:sphere (list (* r (first nums)))))
                  opts)))))

(defun girth-spec (spec girth)
  "SPEC with GIRTH ((joint sx sy sz) ...) applied to the shapes of each listed joint."
  (loop for (j . shapes) in spec
        for s = (rest (assoc j girth))
        collect (cons j (if s (mapcar (lambda (sh) (girth-shape sh s)) shapes) shapes))))

(defun build-body (b)
  "Build B's meshes (the engine's BUILD-PARTS): one per joint for untagged solid shapes, one per
glow / per (joint, tag)."
  (multiple-value-bind (parts extras hulls)
      (build-parts (girth-spec (body-spec b) (body-girth b)) (body-palette b) (body-width b) :ink (or (body-ink b) *body-ink*))
    (setf (body-parts b) parts (body-extras b) extras (body-hulls b) hulls))
  b)

;;; ---------------------------------------------------------------- weapons
;;; A weapon is built in its own frame: origin at the grip (the hand), blade along +Y, edge toward +Z
;;; (MB-BLADE's convention). *WEAPON-M* puts that frame into the :weapon-r joint (blade along -Z of
;;; the joint, i.e. straight out of the fist), so tip = joint point (0 0 -LEN).
(defstruct (weapon (:constructor %make-weapon))
  (name nil)
  (len 1f0 :type single-float)          ; grip → tip (weapon frame, before the body's scale)
  (base 0.25f0 :type single-float)      ; grip → start of the trail / fire (blade base)
  (sections nil)                        ; ((:solid ink fn) (:glow e color fn) ...), fn = (lambda (mb))
  (meshes nil))                         ; built: list of #(mesh tint emissive hull-or-NIL)

(defvar *weapons* (make-hash-table :test 'eq))
(defun find-weapon (name) (or (gethash name *weapons*) (error "unknown weapon ~s" name)))

(defmacro defweapon (name (&key (length 1.0) (base 0.25)) &body sections)
  "Register a weapon. SECTIONS: (:solid [:ink k] meshgen-forms...) drawn toon like the body, with an
ink hull K widths wide (default 1; 0 = none, e.g. a katana blade: build it as its own section with
MB-BLADE :hilt nil), or (:glow emissive #xRRGGBB meshgen-forms...) drawn as a glowing part. The forms use MB (the builder)
in the weapon frame: grip at the origin, blade along +Y, edge toward +Z."
  `(setf (gethash ,name *weapons*)
         (%make-weapon :name ,name :len (f32 ,length) :base (f32 ,base)
                       :sections (list ,@(loop for s in sections collect
                                               (if (eq (first s) :solid)
                                                   (let ((ink (if (eq (second s) :ink) (third s) 1))
                                                         (forms (if (eq (second s) :ink) (cdddr s) (rest s))))
                                                     `(list :solid ,ink (lambda (mb) ,@forms)))
                                                   `(list :glow ,(second s) ,(third s)
                                                          (lambda (mb) ,@(cdddr s)))))))))

(defun build-weapon (wp)
  (setf (weapon-meshes wp)
        (loop for s in (weapon-sections wp) collect
              (if (eq (first s) :solid)
                  (destructuring-bind (ink fn) (rest s)
                    (let ((mb (make-mesh-builder)))
                      (funcall fn mb)
                      (vector (mb-build mb) nil 0f0
                              (when (plusp ink)
                                (mb-build (mb-hull (make-mesh-builder) mb :k ink :c 0.8 :color (hexc (cdr (assoc t *body-ink*)))))))))
                  (destructuring-bind (e hex fn) (rest s)
                    (vector (build-mesh (mb :color '(1 1 1)) (funcall fn mb))
                            (coerce (hexc hex) 'simple-vector) (f32 e) nil)))))
  wp)

(defvar *shadow-mesh* nil "The ink shadow: a flat unit disc (24 sides) at the origin, built by BODIES-INIT.")

(defun bodies-init ()
  "Startup (:load) step: build the meshes of every registered weapon and the shadow disc (the bodies:
BODY-LOAD-STEPS)."
  (setf *shadow-mesh* (build-mesh (mb :color (hexc #x14151C))
                        (mb-poly-out mb (loop for k below 24 collect (let ((a (* 2 pi (/ k 24)))) (v3 (cos a) 0 (sin a))))
                                     :center '(0 -1 0))))
  (maphash (lambda (k w) (declare (ignore k)) (unless (weapon-meshes w) (build-weapon w))) *weapons*))

(defun body-load-steps ()
  "Startup (:load) steps, one per registered body: build its meshes and ink hulls (one step each, so the
collector runs between them: the hull build allocates a few MB of scratch)."
  (loop for b being the hash-values of *bodies*
        collect (let ((b b)) (lambda () (unless (svref (body-parts b) 0) (build-body b))))))

;;; ---------------------------------------------------------------- drawing
(declaim (type f32vec *dm* *dm2* *weapon-m* *toon-body* *toon-ground* *shadow-m*))
(defvar *dm* (m4))
(defvar *dm2* (m4))
(defvar *shadow-m* (m4))
(defvar *toon-body* (fv 2 0 0.2 0) "DRAW-MESH :toon lanes of a character: mode 2, feet height (set per draw), fog x 0.2.")
(defvar *toon-ground* (fv 1 0 1 0) "... and of things lying on the stage (the ink shadow): mode 1, full fog.")
(declaim (type f32vec *toon-ink*))
(defvar *toon-ink* (fv 3 0.012 0.2 1.8) "... and of a weapon's ink hull (DRAW-PARTS' lanes for the body's).")
(defvar *weapon-m* (xform :pitch (deg 90) :roll pi) "weapon frame → :weapon-r joint frame")

(defun draw-weapon (key m &key (alpha 1f0) (flash 0f0) (emissive 0f0) rim)
  "Draw weapon KEY with world matrix M (the weapon frame: grip origin, blade +Y), toon-shaded with the
feet height of the last DRAW-BODY (0 for a planted weapon)."
  (dolist (part (weapon-meshes (find-weapon key)))
    (if (svref part 1)
        (draw-mesh (svref part 0) m :tint (svref part 1) :emissive (+ (svref part 2) emissive) :alpha alpha :toon *toon-body*)
        (draw-mesh (svref part 0) m :flash flash :alpha alpha :emissive emissive :rim rim :toon *toon-body*)))
  (when (>= alpha 1f0)
    (dolist (part (weapon-meshes (find-weapon key)))
      (when (svref part 3) (draw-mesh (svref part 3) m :toon *toon-ink*)))))

(defun draw-planted-weapon (key x z yaw &key (alpha 1f0) (emissive 0f0))
  "WEAPON KEY stuck in the ground at (X Z), leaning slightly toward YAW's facing (Ikkotsu, Kaka)."
  (let* ((len (weapon-len (find-weapon key))) (m *dm2*))
    ;; blade +Y pointing down (pitch pi), grip 0.8 of the blade length above the ground
    (m4-euler! m (f32 x) (f32 (* 0.8 len)) (f32 z) (f32 yaw) (f32 (- pi 0.2)) 0f0)
    (setf (aref *toon-body* 1) 0f0)
    (draw-weapon key m :alpha alpha :emissive emissive)))

(defun draw-shadow (x y z r)
  "The ink shadow disc of radius R under (X Z), smaller the higher the body is (Y)."
  (let ((m *shadow-m*) (k (f32 (* r (max 0.3 (- 1.0 (* 0.3 y)))))))
    (m4-identity! m)
    (setf (aref m 0) k (aref m 10) k (aref m 12) (f32 x) (aref m 13) 0.012f0 (aref m 14) (f32 z))
    (draw-mesh *shadow-mesh* m :toon *toon-ground*)))

(defparameter *face-hides*
  '((:neutral :face-shout :face-hurt) (:shout :face-neutral :face-hurt) (:hurt :face-neutral :face-shout))
  "Expression -> the face tags DRAW-BODY hides for it (constant lists: 0 B a draw).")
(defun face-hide (face) (rest (or (assoc face *face-hides*) (first *face-hides*))))

(defun draw-body (body joints x y z yaw &key weapon (hidden 0) hide (face :neutral) tint rim (emissive 0f0) (flash 0f0)
                                          (alpha 1f0) (shadow t))
  "Queue every visible part of BODY posed by JOINTS (see the file header)."
  (declare (ignore yaw) (type f32vec joints) (fixnum hidden))
  (let* ((dm *dm*) (rim (or rim (body-rim body))) (hide (or hide (face-hide face))))
    (declare (type f32vec dm))
    (setf (aref *toon-body* 1) (f32 y))
    (draw-parts (body-parts body) (body-extras body) joints :hidden hidden :hide hide
                :tint tint :flash flash :emissive emissive :alpha alpha :rim rim :toon *toon-body*
                :hulls (body-hulls body) :ink-tint tint)
    (let ((w (ji :weapon-r)))
      (when (and weapon (not (logbitp w hidden)))
        (replace dm joints :start2 (* w 16) :end2 (+ 16 (* w 16)))
        (m4-mul! *dm2* dm *weapon-m*)
        (draw-weapon weapon *dm2* :alpha alpha :flash flash :rim rim)))
    (when shadow (draw-shadow x y z (* 1.2 alpha (body-hurt-r body))))))

(defun body-weapon-point (weapon joints out along)
  (declare (ignore weapon))
  (joint-point! out joints (ji :weapon-r) 0f0 0f0 (- (f32 along))))

(defun body-weapon-tip (body weapon joints out)
  "World position of the held WEAPON's tip into OUT (the joint matrices carry the body's scale)."
  (declare (ignore body))
  (body-weapon-point weapon joints out (weapon-len (find-weapon weapon))))

(defun body-weapon-base (body weapon joints out)
  "World position of the held WEAPON's blade base (trail / fire start) into OUT."
  (declare (ignore body))
  (body-weapon-point weapon joints out (weapon-base (find-weapon weapon))))

;;; ---------------------------------------------------------------- the two-handed grip (Phase 6)
(defvar *grip-clips* nil
  "Clip names drawn with the left fist on the held weapon's handle (the art files register theirs): GRIP-LEFT! pulls
the left arm there after the FK, so the keys' in-betweens cannot drift off it.")

(defmacro %rot-to! (kx ky kz c x y z)
  "Rotate the float variables X Y Z in place by the rotation taking unit A to unit B, given K = A x B and C = A . B
(Rodrigues: v c + k x v + k (k . v) / (1 + c))."
  `(let* ((%d (/ (+ (* ,kx ,x) (* ,ky ,y) (* ,kz ,z)) (+ 1f0 ,c)))
          (%x (+ (* ,c ,x) (- (* ,ky ,z) (* ,kz ,y)) (* %d ,kx)))
          (%y (+ (* ,c ,y) (- (* ,kz ,x) (* ,kx ,z)) (* %d ,ky)))
          (%z (+ (* ,c ,z) (- (* ,kx ,y) (* ,ky ,x)) (* %d ,kz))))
     (declare (single-float %d %x %y %z))
     (setf ,x %x ,y %y ,z %z)))

(defmacro %rot-cols! (jm j kx ky kz c)
  "Rotate joint J's three axis columns in JM by %ROT-TO!'s rotation (its origin stays)."
  `(dotimes (%c 3)
     (let* ((%o (+ (* ,j 16) (* 4 %c))) (%x (aref ,jm %o)) (%y (aref ,jm (+ %o 1))) (%z (aref ,jm (+ %o 2))))
       (declare (fixnum %o) (single-float %x %y %z))
       (%rot-to! ,kx ,ky ,kz ,c %x %y %z)
       (setf (aref ,jm %o) %x (aref ,jm (+ %o 1)) %y (aref ,jm (+ %o 2)) %z))))

(defun-fast grip-left! (jm wv)
  "Two-bone IK after the FK (a look): move the left fist (the :weapon-l point) W (0..1) of the way onto the right hand's
handle (the :weapon-r frame's +Z axis, 0.14-0.62 m behind the grip: the long handle; the nearest point to where the
pose put the fist, so the keys choose where it holds), bending the elbow in the plane the pose gave it. The upper arm,
forearm, hand and :weapon-l matrices are rotated about the shoulder and elbow; nothing else moves. W = WV[0] (an f32vec:
a float argument would box). 0 B."
  (declare (type f32vec jm wv))
  (dotimes (pass (if (>= (aref wv 0) 1f0) 2 1))          ; a 2nd pass takes up what turning the fist's offset moved
  (let* ((w (aref wv 0)) (ua (* 16 (ji :upper-arm-l))) (la (* 16 (ji :lower-arm-l))) (hd (* 16 (ji :hand-l))) (wl (* 16 (ji :weapon-l)))
         (wr (* 16 (ji :weapon-r)))
         (sx (aref jm (+ ua 12))) (sy (aref jm (+ ua 13))) (sz (aref jm (+ ua 14)))
         (ex (aref jm (+ la 12))) (ey (aref jm (+ la 13))) (ez (aref jm (+ la 14)))
         (hx (aref jm (+ hd 12))) (hy (aref jm (+ hd 13))) (hz (aref jm (+ hd 14)))
         (fx (aref jm (+ wl 12))) (fy (aref jm (+ wl 13))) (fz (aref jm (+ wl 14)))
         (ax (aref jm (+ wr 8))) (ay (aref jm (+ wr 9))) (az (aref jm (+ wr 10)))       ; the handle axis (scaled)
         (ox (aref jm (+ wr 12))) (oy (aref jm (+ wr 13))) (oz (aref jm (+ wr 14)))
         (s (f-clamp (/ (+ (* (- fx ox) ax) (* (- fy oy) ay) (* (- fz oz) az)) (f-max 1f-6 (+ (* ax ax) (* ay ay) (* az az))))
                     0.14f0 0.62f0))
         (tx (+ hx (* w (- (+ ox (* s ax)) fx)))) (ty (+ hy (* w (- (+ oy (* s ay)) fy)))) (tz (+ hz (* w (- (+ oz (* s az)) fz))))
         (a (f-sqrt (+ (* (- ex sx) (- ex sx)) (* (- ey sy) (- ey sy)) (* (- ez sz) (- ez sz)))))
         (b (f-sqrt (+ (* (- hx ex) (- hx ex)) (* (- hy ey) (- hy ey)) (* (- hz ez) (- hz ez)))))
         (dx (- tx sx)) (dy (- ty sy)) (dz (- tz sz))
         (d (f-clamp (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz))) (+ 1f-3 (* 1.01f0 (f-abs (- a b)))) (* 0.999f0 (+ a b))))
         (dl (f-max 1f-5 (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
         (ux (/ dx dl)) (uy (/ dy dl)) (uz (/ dz dl))
         (pe (+ (* (- ex sx) ux) (* (- ey sy) uy) (* (- ez sz) uz)))
         (px (- ex sx (* pe ux))) (py (- ey sy (* pe uy))) (pz (- ez sz (* pe uz)))       ; the elbow's side of S->T
         (pl (f-sqrt (+ (* px px) (* py py) (* pz pz)))))
    (declare (fixnum ua la hd wl wr)
             (single-float w sx sy sz ex ey ez hx hy hz fx fy fz ax ay az ox oy oz s tx ty tz a b dx dy dz d dl ux uy uz pe px py pz pl))
    (when (and (> pl 1f-4) (> a 1f-4) (> b 1f-4))
      (let* ((ca (f-clamp (/ (- (+ (* a a) (* d d)) (* b b)) (* 2f0 a d)) -1f0 1f0)) (sa (f-sqrt (f-max 0f0 (- 1f0 (* ca ca)))))
             (nex (+ sx (* a (+ (* ca ux) (* sa (/ px pl)))))) (ney (+ sy (* a (+ (* ca uy) (* sa (/ py pl))))))
             (nez (+ sz (* a (+ (* ca uz) (* sa (/ pz pl))))))
             (nhx (+ sx (* d ux))) (nhy (+ sy (* d uy))) (nhz (+ sz (* d uz)))
             ;; R1: shoulder->elbow old -> new
             (a0x (/ (- ex sx) a)) (a0y (/ (- ey sy) a)) (a0z (/ (- ez sz) a))
             (a1x (/ (- nex sx) a)) (a1y (/ (- ney sy) a)) (a1z (/ (- nez sz) a))
             (k1x (- (* a0y a1z) (* a0z a1y))) (k1y (- (* a0z a1x) (* a0x a1z))) (k1z (- (* a0x a1y) (* a0y a1x)))
             (c1 (+ (* a0x a1x) (* a0y a1y) (* a0z a1z)))
             ;; the forearm after R1, then R2: it -> elbow->new wrist
             (b0x (/ (- hx ex) b)) (b0y (/ (- hy ey) b)) (b0z (/ (- hz ez) b)))
        (declare (single-float ca sa nex ney nez nhx nhy nhz a0x a0y a0z a1x a1y a1z k1x k1y k1z c1 b0x b0y b0z))
        (when (> c1 -0.999f0)
          (%rot-to! k1x k1y k1z c1 b0x b0y b0z)
          (let* ((bl (f-max 1f-5 (f-sqrt (+ (* (- nhx nex) (- nhx nex)) (* (- nhy ney) (- nhy ney)) (* (- nhz nez) (- nhz nez))))))
                 (b1x (/ (- nhx nex) bl)) (b1y (/ (- nhy ney) bl)) (b1z (/ (- nhz nez) bl))
                 (k2x (- (* b0y b1z) (* b0z b1y))) (k2y (- (* b0z b1x) (* b0x b1z))) (k2z (- (* b0x b1y) (* b0y b1x)))
                 (c2 (+ (* b0x b1x) (* b0y b1y) (* b0z b1z)))
                 (qx (- fx hx)) (qy (- fy hy)) (qz (- fz hz)))                                ; the fist from the wrist
            (declare (single-float bl b1x b1y b1z k2x k2y k2z c2 qx qy qz))
            (when (> c2 -0.999f0)
              (%rot-cols! jm (ji :upper-arm-l) k1x k1y k1z c1)
              (%rot-cols! jm (ji :lower-arm-l) k1x k1y k1z c1) (%rot-cols! jm (ji :lower-arm-l) k2x k2y k2z c2)
              (%rot-cols! jm (ji :hand-l) k1x k1y k1z c1) (%rot-cols! jm (ji :hand-l) k2x k2y k2z c2)
              (%rot-cols! jm (ji :weapon-l) k1x k1y k1z c1) (%rot-cols! jm (ji :weapon-l) k2x k2y k2z c2)
              (%rot-to! k1x k1y k1z c1 qx qy qz) (%rot-to! k2x k2y k2z c2 qx qy qz)
              (setf (aref jm (+ la 12)) nex (aref jm (+ la 13)) ney (aref jm (+ la 14)) nez
                    (aref jm (+ hd 12)) nhx (aref jm (+ hd 13)) nhy (aref jm (+ hd 14)) nhz
                    (aref jm (+ wl 12)) (+ nhx qx) (aref jm (+ wl 13)) (+ nhy qy) (aref jm (+ wl 14)) (+ nhz qz)))))))))
  nil)

(defun grip-gap (jm)
  "Metres from the left fist (:weapon-l) to the handle span of the :weapon-r frame that GRIP-LEFT! uses (tests: debug
2392, the art viewer's grip strips; allocates)."
  (let* ((l (* 16 (ji :weapon-l))) (r (* 16 (ji :weapon-r)))
         (f (list (aref jm (+ l 12)) (aref jm (+ l 13)) (aref jm (+ l 14)))) (o (list (aref jm (+ r 12)) (aref jm (+ r 13)) (aref jm (+ r 14))))
         (ax (list (aref jm (+ r 8)) (aref jm (+ r 9)) (aref jm (+ r 10))))
         (s (max 0.14 (min 0.62 (/ (reduce #'+ (mapcar (lambda (a b c) (* (- a b) c)) f o ax)) (reduce #'+ (mapcar #'* ax ax)))))))
    (sqrt (reduce #'+ (mapcar (lambda (a b c) (expt (- a (+ b (* s c))) 2)) f o ax)))))

;;; ---------------------------------------------------------------- generic stance + shared clips
;;; The shared reactions (:sh-*) are played by every character on the same rig, from and back to
;;; the generic :STANCE (a character's own idle crossfades in afterwards).
(defpose :zero ())
(defpose :stance ()
  (:root :u -0.05) (:pelvis :twist 15)
  (:spine :flex 8) (:chest :twist -10) (:head :twist -5)
  (:arm-r :flex 25 :side 20) (:elbow-r :flex 50) (:hand-r :flex -45)
  (:arm-l :flex 15 :side 15) (:elbow-l :flex 40)
  (:thigh-r :flex -10 :side 8) (:thigh-l :flex 25 :side 5) (:knee-r :flex 25) (:knee-l :flex 30))
(defpose :guard ()
  (:root :u -0.1) (:pelvis :twist 10) (:chest :twist -5)
  (:arm-r :flex 75 :side 10 :twist 20) (:elbow-r :flex 70) (:hand-r :twist 50 :flex -60)
  (:arm-l :flex 70 :side 0) (:elbow-l :flex 90) (:knees :flex 40) (:thigh-r :flex 5) (:thigh-l :flex 35))
(defpose :kneel ()
  (:root :u -0.42) (:pelvis :twist 0) (:spine :flex 45) (:chest :twist 0) (:head :flex 25)
  (:thigh-r :flex 80 :side 5) (:knee-r :flex 125) (:thigh-l :flex 10 :side 5) (:knee-l :flex 120)
  (:arm-l :flex 35 :side 20) (:elbow-l :flex 30))
(defpose :tumble (:base :zero)
  (:root :pitch -50) (:arms :side 60 :flex 30) (:elbows :flex 20) (:thighs :flex 30) (:knees :flex 40)
  (:head :flex 25) (:spine :flex -10))
(defpose :lying (:base :zero)
  (:root :pitch -88 :u -0.82) (:arms :side 50 :flex 20) (:elbows :flex 30) (:thigh-r :flex 20) (:knee-r :flex 30)
  (:head :flex 10))

;; walking / strafing: legs only, arms from the stance (0.9 s cycle ≈ 1.6 m per cycle)
(defclip :sh-walk-f (0.9 :loop t)
  (0 (:thigh-r :flex 25) (:knee-r :flex 10) (:thigh-l :flex -15) (:knee-l :flex 20))
  (0.225 (:root :u -0.03) (:thigh-r :flex 0) (:knee-r :flex 20) (:thigh-l :flex 5) (:knee-l :flex 55))
  (0.45 (:root :u -0.05) (:thigh-l :flex 25) (:knee-l :flex 10) (:thigh-r :flex -15) (:knee-r :flex 20))
  (0.675 (:root :u -0.03) (:thigh-l :flex 0) (:knee-l :flex 20) (:thigh-r :flex 5) (:knee-r :flex 55)))
(defclip :sh-walk-b (0.9 :loop t)
  (0 (:spine :flex 2) (:thigh-r :flex -15) (:knee-r :flex 20) (:thigh-l :flex 25) (:knee-l :flex 10))
  (0.225 (:root :u -0.03) (:thigh-r :flex 5) (:knee-r :flex 55) (:thigh-l :flex 0) (:knee-l :flex 20))
  (0.45 (:root :u -0.05) (:thigh-l :flex -15) (:knee-l :flex 20) (:thigh-r :flex 25) (:knee-r :flex 10))
  (0.675 (:root :u -0.03) (:thigh-l :flex 5) (:knee-l :flex 55) (:thigh-r :flex 0) (:knee-r :flex 20)))
(defclip :sh-strafe-r (0.8 :loop t)
  (0 (:thigh-r :side 22 :flex 5) (:thigh-l :side -2) (:knee-l :flex 25))
  (0.2 (:root :u -0.04) (:thigh-r :side 8) (:knee-r :flex 45) (:thigh-l :side 5))
  (0.4 (:thigh-r :side 4) (:thigh-l :side 18 :flex 10) (:knee-l :flex 20))
  (0.6 (:root :u -0.04) (:thigh-l :side 5) (:knee-l :flex 45) (:thigh-r :side 10)))
(defclip :sh-strafe-l (0.8 :loop t)
  (0 (:thigh-l :side 22 :flex 30) (:thigh-r :side -2) (:knee-r :flex 25))
  (0.2 (:root :u -0.04) (:thigh-l :side 8) (:knee-l :flex 45) (:thigh-r :side 12))
  (0.4 (:thigh-l :side 4) (:thigh-r :side 22 :flex -5) (:knee-r :flex 20))
  (0.6 (:root :u -0.04) (:thigh-r :side 8) (:knee-r :flex 45) (:thigh-l :side 10)))

;; the run (Step held past the hop), facing the opponent whatever way it goes (the user's decision 2026-09-26): a
;; forward run (leaning in, long strides), a side slide (crouched, the lead leg reaching, the trail leg crossing) either
;; way and a back-skate (upright, gliding back on alternate push-offs). The legs are key lists so a character can lay
;; them under his own arms (Kenpachi: the blade on his shoulder, ken-art.lisp); a kit's :run-clips picks the set.
;; 0.5 s cycles played at run speed / 8 m/s (fighter.lisp RUN-CLIP).
(defparameter *run-keys*
  '((0 (:root :u -0.07) (:spine :flex 22) (:head :flex -12) (:thigh-r :flex 45) (:knee-r :flex 15) (:thigh-l :flex -30) (:knee-l :flex 50))
    (0.125 (:root :u 0.02) (:spine :flex 22) (:head :flex -12) (:thigh-r :flex 10) (:knee-r :flex 30) (:thigh-l :flex 10) (:knee-l :flex 95))
    (0.25 (:root :u -0.07) (:spine :flex 22) (:head :flex -12) (:thigh-l :flex 45) (:knee-l :flex 15) (:thigh-r :flex -30) (:knee-r :flex 50))
    (0.375 (:root :u 0.02) (:spine :flex 22) (:head :flex -12) (:thigh-l :flex 10) (:knee-l :flex 30) (:thigh-r :flex 10) (:knee-r :flex 95))))
(defparameter *skate-keys*
  '((0 (:root :u -0.12) (:spine :flex -6) (:head :flex 6) (:thigh-r :flex 25 :side 20) (:knee-r :flex 45) (:thigh-l :flex -12 :side 6) (:knee-l :flex 25))
    (0.125 (:root :u -0.06) (:thigh-r :flex 12 :side 10) (:knee-r :flex 30) (:thigh-l :flex 0 :side 10))
    (0.25 (:root :u -0.12) (:thigh-l :flex 25 :side 20) (:knee-l :flex 45) (:thigh-r :flex -12 :side 6) (:knee-r :flex 25))
    (0.375 (:root :u -0.06) (:thigh-l :flex 12 :side 10) (:knee-l :flex 30) (:thigh-r :flex 0 :side 10))))
(defparameter *slide-r-keys*
  '((0 (:root :u -0.14) (:spine :flex 14 :side -10) (:thigh-r :side 32 :flex 10) (:knee-r :flex 25) (:thigh-l :side -8 :flex 22) (:knee-l :flex 50))
    (0.125 (:root :u -0.07) (:thigh-r :side 14 :flex 20) (:knee-r :flex 45) (:thigh-l :side 6 :flex 10) (:knee-l :flex 30))
    (0.25 (:root :u -0.14) (:thigh-r :side 4 :flex 25) (:knee-r :flex 30) (:thigh-l :side 26 :flex 0) (:knee-l :flex 20))
    (0.375 (:root :u -0.07) (:thigh-r :side 18 :flex 15) (:knee-r :flex 40) (:thigh-l :side 10 :flex 12) (:knee-l :flex 40))))
(defparameter *slide-l-keys*
  '((0 (:root :u -0.14) (:spine :flex 14 :side 10) (:thigh-l :side 32 :flex 10) (:knee-l :flex 25) (:thigh-r :side -8 :flex 22) (:knee-r :flex 50))
    (0.125 (:root :u -0.07) (:thigh-l :side 14 :flex 20) (:knee-l :flex 45) (:thigh-r :side 6 :flex 10) (:knee-r :flex 30))
    (0.25 (:root :u -0.14) (:thigh-l :side 4 :flex 25) (:knee-l :flex 30) (:thigh-r :side 26 :flex 0) (:knee-r :flex 20))
    (0.375 (:root :u -0.07) (:thigh-l :side 18 :flex 15) (:knee-l :flex 40) (:thigh-r :side 10 :flex 12) (:knee-r :flex 40))))
(defun defrun (base fwd back right left)
  "The four run clips (FWD BACK RIGHT LEFT, 0.5 s loops) with the run legs over pose BASE's arms."
  (loop for name in (list fwd back right left) for keys in (list *run-keys* *skate-keys* *slide-r-keys* *slide-l-keys*)
        do (build-clip name 0.5 t base keys)))
(defrun :stance :sh-run :sh-skate-b :sh-slide-r :sh-slide-l)

;; step (24 f): crouch, hop, land
(defclip :sh-step-b (0.4)
  (0 (:root :u -0.12) (:knees :flex 45) (:spine :flex 15))
  (0.1 (:root :u 0.05) (:spine :flex -10) (:thigh-r :flex -20) (:thigh-l :flex 30) (:knees :flex 20) (:arms :side 35))
  (0.28 (:root :u -0.14) (:knees :flex 50) (:thighs :flex 30) (:spine :flex 18))
  (0.4 :stance))
(defclip :sh-step-f (0.4)
  (0 (:root :u -0.12) (:knees :flex 45) (:spine :flex 15))
  (0.1 (:root :u 0.05) (:spine :flex 25) (:thigh-r :flex 40) (:thigh-l :flex -25) (:knees :flex 25))
  (0.28 (:root :u -0.14) (:knees :flex 50) (:thighs :flex 30) (:spine :flex 20))
  (0.4 :stance))
(defclip :sh-step-r (0.4)
  (0 (:root :u -0.12) (:knees :flex 45))
  (0.1 (:root :u 0.05) (:spine :side -15) (:thigh-r :side 35) (:thigh-l :side -5) (:arm-l :side 45))
  (0.28 (:root :u -0.14) (:knees :flex 50) (:thighs :flex 30))
  (0.4 :stance))
(defclip :sh-step-l (0.4)
  (0 (:root :u -0.12) (:knees :flex 45))
  (0.1 (:root :u 0.05) (:spine :side 15) (:thigh-l :side 35) (:thigh-r :side -5) (:arm-r :side 55))
  (0.28 (:root :u -0.14) (:knees :flex 50) (:thighs :flex 30))
  (0.4 :stance))

;; Hoho: reappear behind the opponent (24 f): crouched landing, rising
(defclip :sh-hoho-in (0.4)
  (0 (:root :u -0.3) (:knees :flex 80) (:thighs :flex 55) (:spine :flex 35) (:arm-r :side 50 :flex 10))
  (0.4 :stance))

;; guard
(defclip :sh-guard (0.5 :loop t :base :guard) (0) (0.25 (:root :u -0.11)))
(defclip :sh-guard-hit (0.2 :base :guard)
  (0) (0.05 :snap (:spine :flex -10) (:root :f -0.12) (:head :flex -10)) (0.2 :guard))
(defclip :sh-guard-break (0.83)                     ; 50 f
  (0.05 :snap (:arms :side 70 :flex 40) (:elbows :flex 10) (:spine :flex -22) (:head :flex -20) (:root :f -0.1))
  (0.35 (:spine :flex 30) (:knees :flex 50) (:thighs :flex 30) (:root :u -0.2) (:head :flex 20) (:arms :side 30 :flex 20))
  (0.65 (:spine :flex 34) (:knees :flex 52) (:thighs :flex 32) (:root :u -0.22) (:head :flex 25))
  (0.83 :stance))

;; hit reactions (lengths = the stun frames of §3)
(defclip :sh-flinch (0.3)                           ; 18 f
  (0.03 :snap (:spine :flex -15) (:head :flex -20) (:chest :twist 12))
  (0.3 :stance))
(defclip :sh-stagger (0.43)                         ; 26 f
  (0.05 :snap (:spine :flex -25) (:arms :side 40) (:head :flex -18) (:chest :twist -15))
  (0.22 (:root :f -0.3) (:knees :flex 40) (:spine :flex -10) (:thigh-l :flex -10))
  (0.43 :stance))
(defclip :sh-knockback (0.5)                        ; 30 f
  (0.04 :snap (:spine :flex -35) (:head :flex -30) (:arms :side 55 :flex 30) (:root :u -0.05))
  (0.25 (:root :u -0.25) (:spine :flex 25) (:knees :flex 70) (:thighs :flex 45) (:head :flex 10) (:arms :side 30))
  (0.5 :stance))
(defclip :sh-launch (0.5 :loop t :base :tumble)
  (0) (0.25 (:arms :side 70 :flex 45) (:thighs :flex 40) (:knees :flex 50) (:root :pitch -60)))
(defclip :sh-down (1.0 :loop t :base :lying)
  (0) (0.5 (:head :flex 15) (:arm-r :side 55)))
(defclip :sh-wakeup (0.5 :base :lying)              ; 30 f
  (0)
  (0.2 (:root :pitch 0 :u -0.45) (:spine :flex 40) (:thighs :flex 80) (:knees :flex 120) (:arms :flex 30 :side 20)
       (:head :flex 10))
  (0.5 :stance))
(defclip :sh-crumple (1.0)
  (0.08 :snap (:spine :flex -20) (:head :flex -30) (:arms :side 40))
  (0.6 :kneel)
  (1.0 :kneel (:head :flex 35)))
(defclip :sh-lose (2.0 :loop t :base :kneel)
  (0 (:arm-r :flex 20 :side 10) (:elbow-r :flex 20) (:hand-r :twist 150 :flex 10))
  (1.0 (:spine :flex 50) (:head :flex 32)))
(defclip :sh-bound (1.0 :loop t)                     ; bound by the feet (South): the legs held, the body straining
  (0 (:root :u -0.1) (:spine :flex 30 :twist 15) (:head :flex -20) (:arms :side 40 :flex 30) (:elbows :flex 40) (:knees :flex 25))
  (0.5 (:root :u -0.12) (:spine :flex 22 :twist -15) (:head :flex -10) (:arms :side 50 :flex 10) (:elbows :flex 20) (:knees :flex 30)))
(defclip :sh-kikon-victim (1.0 :loop t)
  (0 (:root :u -0.08) (:spine :flex -18) (:head :flex -25) (:arms :side 35 :flex 15) (:elbows :flex 10) (:knees :flex 30))
  (0.5 (:root :u -0.1) (:spine :flex -22) (:head :flex -30) (:arms :side 40 :flex 18)))
(defclip :sh-clash (0.4)
  (0.04 :snap (:spine :flex -20) (:root :f -0.2) (:arm-r :flex 110 :side 30) (:elbow-r :flex 20) (:head :flex -12))
  (0.2 (:root :u -0.15) (:knees :flex 50) (:spine :flex 15))
  (0.4 :stance))
(defclip :sh-awaken-ready (0.6)
  (0 (:root :u -0.15) (:knees :flex 45) (:spine :flex 25))
  (0.25 (:root :u 0.0) (:spine :flex -15) (:chest :flex -10) (:head :flex -15) (:arms :side 55 :flex 15)
        (:elbows :flex 20))
  (0.6 (:root :u -0.03) (:spine :flex -10) (:head :flex -10) (:arms :side 50 :flex 12)))
