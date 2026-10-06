;;;; fx.lisp — camera shake, particles (mist, sparks, dust, homing orbs, feathers, glow, flame), rings,
;;;; rigid debris, sword-trail buffers, screen-edge vignettes, debug outlines of hit volumes, and
;;;; two fx-batch shapes: camera-facing ribbons (FX-RIBBON) and flat ground sectors (FX-SECTOR).
;;;; All real-time or sim-time driven by the caller; the colors / presets a game uses live in the game.
(in-package :engine)

;;; ---------------------------------------------------------------- camera shake (real time)
(defparameter *shake-mult* 1.0 "Scales every SHAKE request (tuning knob).")
(defparameter *shake-hz* 30f0 "Shake offsets change this many times a second (fewer = a drawn, stepped shake; SOUL DUEL 12).")
(declaim (type f32vec *shake*))
(defvar *shake* (make-f32 8) "amp dur left noise-t ox oy oz")
(defun shake (amp dur)
  "Screen shake of AMP metres decaying linearly over DUR s. Concurrent: the max amplitude wins."
  (let* ((s *shake*) (amp (* (f32 amp) (f32 *shake-mult*)))
         (cur (if (> (aref s 1) 0) (* (aref s 0) (/ (aref s 2) (aref s 1))) 0f0)))
    (when (>= amp cur)
      (setf (aref s 0) amp (aref s 1) (f32 dur) (aref s 2) (f32 dur)))))

(defun-fast shake-update (dt)
  (declare (single-float dt))
  (let* ((s *shake*) (out (camera-shake *camera*)))
    (declare (type f32vec s out))
    (setf (aref s 2) (f-max 0f0 (- (aref s 2) dt))
          (aref s 3) (- (aref s 3) dt))
    (when (<= (aref s 3) 0f0)                          ; 30 Hz noise
      (setf (aref s 3) (/ 1f0 (f-max 1f0 (f32 *shake-hz*)))
            (aref s 4) (rnd-range -1f0 1f0) (aref s 5) (rnd-range -1f0 1f0) (aref s 6) (rnd-range -1f0 1f0)))
    (let* ((a (if (> (aref s 1) 0f0) (* (aref s 0) (/ (aref s 2) (aref s 1))) 0f0)))
      (declare (single-float a))
      (setf (aref out 0) (* a (aref s 4)) (aref out 1) (* a (aref s 5)) (aref out 2) (* a (aref s 6))))))

;;; ---------------------------------------------------------------- toon effects: clock, palettes, envelope
;;; The toon fx batch (WITH-FX-VERTS :toon, fx-toon.frag.wgsl; docs/style/STYLE_STORM_DESIGN.md §3) draws hard,
;;; inked shapes in one of 15 palettes. A toon vertex's colour lanes are HEAT (0..1: ribbons run base 1 to
;;; tip 0.2; fan shapes: 0 centre .. 1 outline), SEED (a shape's noise, 0..999; < 0 = "along" shape, +1000 =
;;; the charcoal style), WOBBLE (0..0.5 silhouette boil) and TOON-A (palette + presence K 0.01..0.98, + 16 for a
;;; fan shape). Presence erodes the shape: 0.98 whole, toward 0 gone (matter perforates, ribbons lose
;;; their tip first). Their noise steps on the FX CLOCK (24 Hz ticks: fire / energy on twos, matter on
;;; threes), which advances only by the effects' dt: it stops while the game pauses.
(defconstant +pal-fire+ 0f0) (defconstant +pal-ember+ 1f0) (defconstant +pal-reiatsu+ 2f0) (defconstant +pal-ink+ 3f0)
(defconstant +pal-steel+ 4f0) (defconstant +pal-hit+ 5f0) (defconstant +pal-smoke+ 6f0) (defconstant +pal-dust+ 7f0)
(defconstant +pal-ash+ 8f0) (defconstant +pal-soul+ 9f0) (defconstant +pal-blood+ 10f0) (defconstant +pal-black-smoke+ 11f0)
(defconstant +pal-blue+ 12f0 "SOUL DUEL's BLUE burst (energy, a coloured edge).")
(defconstant +pal-jade+ 13f0 "SOUL DUEL's muted jade (an ink tone, not a spot hue: energy with a coloured edge).")
(defconstant +pal-gold+ 14f0 "SOUL DUEL's muted gold #B89A5A (energy with a coloured edge).")

(defmacro fx-clock () "The fx clock in seconds (*FX-CLOCK*, render.lisp)." `(aref (the f32vec *fx-clock*) 0))
(defun-fast fx-clock-advance (dt)
  "Advance the fx clock by DT, this frame's effect seconds (0 while paused, held or frozen)."
  (declare (single-float dt))
  (let* ((c *fx-clock*)) (declare (type f32vec c)) (setf (aref c 0) (+ (aref c 0) dt)))
  nil)
(defmacro sage (age rate)
  "AGE (seconds) quantised to the fx clock's drawings of RATE ticks (1 ones, 2 twos, 3 threes at 24 Hz):
AGE - mod(clock, RATE/24), at least 0. Every effect sampled with it changes on the same drawings as the
toon shader's noise. AGE and RATE: single-float forms."
  `(f-max 0f0 (- ,age (f-mod (fx-clock) (/ ,rate 24f0)))))
(defmacro toon-a (p k &optional fan)
  "The toon vertex's alpha lane: palette P (0..14, a +PAL-...+ constant or a float form) + presence K
clamped to 0.01..0.98; FAN T adds 16 (the fan-shape flag of FX-STAR / FX-SHARD)."
  `(+ ,(if (numberp p) (float (+ p (if fan 16 0)) 1f0) (if fan `(+ 16f0 ,p) p)) (f-clamp ,k 0.01f0 0.98f0)))
(defmacro %h01 (i seed)
  "Stable pseudo-random 0..1 of the float forms I and SEED (a sine hash: shapes that must not change per frame)."
  `(let* ((%v (* 43758.547f0 (f-sin (+ (* ,i 12.9898f0) (* ,seed 78.233f0)))))) (declare (single-float %v)) (- %v (i->f (f->i %v)))))

(defmacro fx-envelope ((scale k flash phase) (age flash-f grow hold out &key (anticipate 0)) &body body)
  "Bind SCALE, K (presence), FLASH (1 on the flash frame) and PHASE (0 anticipation, 1 flash, 2 grow,
3 hold, 4 out, 5 done) for AGE seconds into a one-shot drawn effect, then run BODY. The counts are 60 Hz
frames (docs/style/STYLE_STORM_DESIGN.md §3.4): ANTICIPATE (scale 1 -> 0.8; the caller adds converging
shards), FLASH (a white disc), GROW (scale 0.6 -> 1.1, ease-out), HOLD (1.0), OUT (K 0.98 -> 0 erodes
the shape, scale 1.0 -> 1.05). Pass a SAGE'd age so the envelope steps with the drawings. All numbers
single-float forms or literals; zero consing."
  (let ((f (gensym "F")) (a (gensym "A")) (fl (gensym "FL")) (gr (gensym "GR")) (ho (gensym "HO")) (ou (gensym "OU")) (u (gensym "U")))
    `(let* ((,f (* ,age 60f0)) (,a (float ,anticipate 1f0)) (,fl (float ,flash-f 1f0)) (,gr (float ,grow 1f0))
            (,ho (float ,hold 1f0)) (,ou (float ,out 1f0)) (,u 0f0)
            (,scale 1f0) (,k 0.98f0) (,flash 0f0) (,phase 0))
       (declare (single-float ,f ,a ,fl ,gr ,ho ,ou ,u ,scale ,k ,flash) (fixnum ,phase) (ignorable ,scale ,k ,flash ,phase))
       (if (< ,f ,a)
           (setf ,scale (- 1f0 (* 0.2f0 (/ ,f (f-max ,a 1f0)))))
           (progn
             (setf ,f (- ,f ,a))
             (cond ((< ,f ,fl) (setf ,scale 0.6f0 ,flash 1f0 ,phase 1))
                   ((< ,f (+ ,fl ,gr)) (setf ,u (/ (- ,f ,fl) (f-max ,gr 1f0))
                                             ,scale (+ 0.6f0 (* 0.5f0 (- 1f0 (* (- 1f0 ,u) (- 1f0 ,u))))) ,phase 2))
                   ((< ,f (+ ,fl ,gr ,ho)) (setf ,phase 3))
                   ((< ,f (+ ,fl ,gr ,ho ,ou)) (setf ,u (/ (- ,f ,fl ,gr ,ho) (f-max ,ou 1f0))
                                                    ,k (* 0.98f0 (- 1f0 ,u)) ,scale (+ 1f0 (* 0.05f0 ,u)) ,phase 4))
                   (t (setf ,k 0f0 ,phase 5)))))
       ,@body)))

(defmacro %toward-eye ((x y z sc) push &body body)
  "Rebind X Y Z moved PUSH metres toward the camera eye (at most half way) and SC = the size factor that
keeps the screen size (new distance / old). Toon billboards and fans are pushed so they never slice
bodies or the floor with a straight depth line."
  `(let* ((%e (camera-eye *camera*)) (%dx (- (aref %e 0) ,x)) (%dy (- (aref %e 1) ,y)) (%dz (- (aref %e 2) ,z))
          (%d (f-max 1f-3 (f-sqrt (+ (* %dx %dx) (* %dy %dy) (* %dz %dz))))) (%p (f-min ,push (* 0.5f0 %d)))
          (,x (+ ,x (* %p (/ %dx %d)))) (,y (+ ,y (* %p (/ %dy %d)))) (,z (+ ,z (* %p (/ %dz %d)))) (,sc (/ (- %d %p) %d)))
     (declare (type f32vec %e) (single-float %dx %dy %dz %d %p ,x ,y ,z ,sc))
     ,@body))

;;; Toon shape primitives: macros that write their float arguments into *TN-ARGS* and call the body
;;; (%FX-STAR ...), so a call conses nothing (the FX-RIBBON pattern). PAL = palette (0..11), K = presence.
(declaim (type f32vec *tn-args*))
(defvar *tn-args* (make-f32 16) "FX-STAR / FX-SHARD / FX-CRESCENT / FX-WALL arguments (see each).")
(defmacro %tn-call (fn args &rest fixargs)
  (let ((a (gensym "A")))
    `(let* ((,a *tn-args*))
       (declare (type f32vec ,a))
       (setf ,@(loop for x in args for i from 0 append `((aref ,a ,i) ,x)))
       (,fn ,@fixargs))))
(defmacro fx-star (x y z r0 r1 n rot dirx diry wobble seed pal k &key (push 0.3f0))
  "An irregular toon star (hit spark; docs/style/STYLE_STORM_DESIGN.md §3.4) facing the camera at (X Y Z): N spikes
of length R1 x 0.5..1.4 (hashed from SEED), valleys at R0, angles jittered +-12 degrees, ROT turning it;
the spike nearest the screen direction (DIRX DIRY) (camera right / up; 0 0 = none) is 1.7x long, a second
one opposite on odd seeds 1.25x. R0 >= R1 = a regular N-gon (the guard hexagon). One outline (a fan shape:
its field is 0 at the centre, 1 on the straight edges). Pushed PUSH m toward the eye (screen size kept).
Float forms except N (fixnum)."
  `(%tn-call %fx-star (,x ,y ,z ,r0 ,r1 ,rot ,dirx ,diry ,wobble ,seed ,pal ,k ,push) ,n))
(defmacro fx-shard (x y z dx dy dz len w wobble seed pal k &key (push 0.1f0))
  "A toon kite (shard) centred at (X Y Z) pointing along the unit direction (DX DY DZ), LEN long (0.6 ahead,
0.4 behind), half-width W, facing the camera; a fan shape (one outline)."
  `(%tn-call %fx-shard (,x ,y ,z ,dx ,dy ,dz ,len ,w ,wobble ,seed ,pal ,k ,push)))
(defmacro fx-crescent (x0 y0 z0 x1 y1 z1 bx by bz w profile wobble seed pal k &key (push 0.15f0))
  "A toon crescent: a camera-facing strip along the quadratic Bezier (X0..) -> (X1..) with control point
(BX BY BZ), 8 segments. PROFILE :lens = half-width W sin(pi u); :comet = W u^0.4 (1-u)^0.15 with u from the
tail (x0) to the blade (x1): a sword smear or an impact mark. An along shape: the tail erodes first."
  `(%tn-call %fx-crescent (,x0 ,y0 ,z0 ,x1 ,y1 ,z1 ,bx ,by ,bz ,w ,wobble ,seed ,pal ,k ,push)
             ,(if (keywordp profile) (if (eq profile :comet) 1 0) `(if (eq ,profile :comet) 1 0))))
(defmacro fx-disc (x y z r wobble seed pal k &key (push -1f0))
  "A toon disc / puff of radius R facing the camera at (X Y Z) (FX-BILLBOARD :toon without the boxed call),
pushed PUSH m toward the eye (default 0.8 R) at the same screen size. Matter palettes draw a lit puff."
  `(%tn-call %fx-disc (,x ,y ,z ,r ,wobble ,seed ,pal ,k ,push)))
(defmacro fx-wall (xs zs n height scallops wobble seed pal k)
  "A continuous toon wall (a flame wall) standing on the ground polyline of N points XS / ZS (f32vecs),
HEIGHT m at its middle (0.6 x at the quarter points: tallest in the middle), its top cut into SCALLOPS
pointed tongues (5-7, each 0.75..1 x high, hashed from SEED: pass a seed that changes per drawing to
re-draw them) over rounded valleys at 0.45 x, tapering to the ground at both ends. An along shape:
uv.x = the height fraction (the field; the silhouette follows the top), uv.y = 0.8 x the distance along
the wall (only the noise reads it, so the core and shade break up along the wall), heat 1 at the base ..
0.2 at the top, so fire keeps its dark edge on the lower third (the ends and valleys) and fades from the top.
N and SCALLOPS fixnums."
  `(%tn-call %fx-wall (,height ,wobble ,seed ,pal ,k) ,xs ,zs ,n ,scallops))

;;; ---------------------------------------------------------------- particles
;;; Pool of +PMAX+ particles, stride 15:
;;; [0-2] pos [3-5] vel [6] life [7] max [8] size [9] grav [10] r [11] g [12] b [13] type
;;; [14] alpha scale (FX-EMIT's optional ALPHA, 1 = the kind's own alpha; multiplies it when drawn)
(defconstant +pmax+ 2000)
(defconstant +pstride+ 15)
;;; Types (how a particle moves and draws; its color is per particle):
;;;   mist / dust  soft alpha puffs that grow and fade (mist darkens), with drag
;;;   spark        velocity-stretched additive streak, falls
;;;   orb-a/orb-b  additive glow balls that home to *ORB-TARGET* after 0.4 s and call
;;;                *ON-ORB-ABSORBED* with :A / :B when they reach it (pickups)
;;;   feather      narrow alpha quad, slow fall      glow  additive ball that shrinks
;;;   flame        additive ball, mild drag, shrinks; its color runs from the emit color (give a
;;;                white-yellow hot core) through orange to dark red over its life, and only the
;;;                first 10 % of its life gets the additive batch's white center. It rises when the
;;;                caller passes a negative GRAV (FX-BURST uses -2). Its peak alpha is 0.8; FX-EMIT's
;;;                ALPHA scales that (additive: brightness), e.g. 0.3-0.5 so flames do not saturate
;;;                to white over a bright sky.
;;; Every kind's alpha is multiplied by the particle's ALPHA (default 1 = unchanged).
;;; Toon kinds (the toon batch, docs/style/STYLE_STORM_DESIGN.md §3.4): R = wobble, ALPHA = the palette (0..11);
;;; presence K = the life left, seed = the slot. Drawn stepped on the fx clock (at pos - vel x the time
;;; since the drawing began: twos, threes for the matter palettes), so a burst of scraps moves in drawings.
;;;   t-blob       a pushed billboard puff or flame (the palette's style decides): matter grows, the rest shrinks
;;;   t-shard      a kite along its velocity (rock, glass, ink shards)
(defconstant +p-mist+ 0f0) (defconstant +p-spark+ 1f0) (defconstant +p-dust+ 2f0)
(defconstant +p-orb-a+ 3f0) (defconstant +p-orb-b+ 4f0) (defconstant +p-feather+ 5f0)
(defconstant +p-glow+ 6f0) (defconstant +p-flame+ 7f0) (defconstant +p-t-blob+ 8f0) (defconstant +p-t-shard+ 9f0)
(defmacro %matter-pal-p (p) "Palettes 6 7 8 11 (smoke, dust, ash, black smoke) are matter: threes."
  `(or (= ,p 6f0) (= ,p 7f0) (= ,p 8f0) (= ,p 11f0)))
(declaim (type f32vec *parts* *orb-target*) (type fixnum *pcursor* *plive*))
(defvar *parts* (make-f32 (* +pmax+ +pstride+)))
(defvar *pcursor* 0)
(defvar *plive* 0)
(defvar *orb-target* (make-f32 3) "World point orb particles home to (e.g. the player's chest); set it each frame.")
(defvar *on-orb-absorbed* nil "NIL or a function of :A / :B, called when an orb particle reaches *ORB-TARGET*.")

;; FX-EMIT is a function (for #'fx-emit) plus a compiler macro: a direct call expands to %FX-PUT
;; in place, so the 12-13 float arguments are never boxed (a call boxed ~210 B). Only %FX-SLOT (no
;; float arguments) is called.
(defun-fast %fx-slot ()
  "Offset in *PARTS* of the slot the next particle takes (a dead one near the cursor, else the
oldest), advancing the cursor."
  (let* ((p *parts*) (i *pcursor*) (tries 0))
    (declare (type f32vec p) (fixnum i tries))
    (loop while (and (< tries 64) (> (aref p (+ (* i +pstride+) 6)) 0f0)) do
      (incf i) (incf tries) (when (>= i +pmax+) (setf i 0)))
    (let* ((o (* i +pstride+)))
      (declare (fixnum o))
      (incf i) (when (>= i +pmax+) (setf i 0))
      (setf *pcursor* i)
      o)))

(defmacro %fx-put (type x y z vx vy vz life size grav r g b &optional (alpha 1f0))
  "FX-EMIT's body, inline: evaluate the arguments left to right as single-floats, write one slot."
  (let* ((args (list type x y z vx vy vz life size grav r g b alpha))
         (vars (loop repeat (length args) collect (gensym "A"))) (p (gensym "P")) (o (gensym "O")))
    `(let* (,@(mapcar #'list vars args))
       (declare (single-float ,@vars))
       (let* ((,p *parts*) (,o (%fx-slot)))
         (declare (type f32vec ,p) (fixnum ,o))
         (setf ,@(loop for v in (list (nth 1 vars) (nth 2 vars) (nth 3 vars) (nth 4 vars) (nth 5 vars) (nth 6 vars)
                                      (nth 7 vars) (nth 7 vars) (nth 8 vars) (nth 9 vars) (nth 10 vars) (nth 11 vars)
                                      (nth 12 vars) (nth 0 vars) (nth 13 vars))
                       for k from 0 append `((aref ,p (+ ,o ,k)) ,v))))
       nil)))

(defun-fast fx-emit (type x y z vx vy vz life size grav r g b &optional (alpha 1f0))
  "Spawn one particle (overwrites the oldest slot when full). ALPHA scales the kind's alpha (for the
additive kinds: brightness), e.g. 0.3 for flames that must not saturate on a bright sky. A direct
call compiles in place (compiler macro): unboxed float arguments cost no consing."
  (declare (single-float type x y z vx vy vz life size grav r g b))
  (%fx-put type x y z vx vy vz life size grav r g b (f32 alpha)))
(eval-when (:compile-toplevel :load-toplevel :execute)   ; ECL: else not seen by the compiler
  (define-compiler-macro fx-emit (&rest args) `(%fx-put ,@args)))

(defun-fast fx-burst (type n x y z dx dy dz spread smin smax life size r g b)
  "N particles from (x y z): direction (dx dy dz) (zero = omni) jittered by SPREAD, speed
SMIN..SMAX, LIFE s (±25 %), SIZE radius (0.5x..1x)."
  (declare (single-float type x y z dx dy dz spread smin smax life size r g b) (fixnum n))
  (let* ((grav (cond ((= type +p-spark+) 9.8f0) ((= type +p-mist+) -0.4f0) ((= type +p-dust+) -0.3f0)
                     ((= type +p-feather+) 1.2f0) ((= type +p-glow+) 0f0) ((= type +p-flame+) -2f0)
                     (t 2.5f0))))
    (declare (single-float grav))
    (dotimes (k n)
      (let* ((rx (+ dx (* spread (rnd-range -1f0 1f0)))) (ry (+ dy (* spread (rnd-range -1f0 1f0))))
             (rz (+ dz (* spread (rnd-range -1f0 1f0))))
             (l (f-sqrt (+ (* rx rx) (* ry ry) (* rz rz)))) (sp (rnd-range smin smax)))
        (declare (single-float rx ry rz l sp))
        (when (< l 1f-4) (setf rx 0f0 ry 1f0 rz 0f0 l 1f0))
        (setf sp (/ sp l))
        (fx-emit type x y z (* rx sp) (* ry sp) (* rz sp) (* life (rnd-range 0.75f0 1.25f0))
                 (* size (rnd-range 0.5f0 1f0)) grav r g b)))))

(defun-fast fx-update (dt)
  "Advance particles by DT (real seconds). Orbs home to *ORB-TARGET* and call *ON-ORB-ABSORBED*."
  (declare (single-float dt))
  (let* ((p *parts*) (tg *orb-target*) (live 0))
    (declare (type f32vec p tg) (fixnum live))
    (dotimes (i +pmax+)
      (let* ((o (* i +pstride+)) (life (aref p (+ o 6))))
        (declare (fixnum o) (single-float life))
        (when (> life 0f0)
          (incf live)
          (let* ((type (aref p (+ o 13))) (nl (- life dt)))
            (declare (single-float type nl))
            (setf (aref p (+ o 6)) nl)
            (if (or (= type +p-orb-a+) (= type +p-orb-b+))
                (let* ((age (- (aref p (+ o 7)) nl))
                       (dx (- (aref tg 0) (aref p o))) (dy (- (aref tg 1) (aref p (+ o 1))))
                       (dz (- (aref tg 2) (aref p (+ o 2))))
                       (d (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
                  (declare (single-float age dx dy dz d))
                  (cond ((and (> age 0.4f0) (< d 0.6f0))
                         (setf (aref p (+ o 6)) 0f0)
                         (let ((hook *on-orb-absorbed*))
                           (when hook (funcall hook (if (= type +p-orb-a+) :a :b)))))
                        ((and (> age 0.4f0) (< d 8f0))
                         (let* ((k (/ 12f0 (f-max d 0.01f0))))
                           (setf (aref p (+ o 3)) (* dx k) (aref p (+ o 4)) (* dy k) (aref p (+ o 5)) (* dz k))))
                        (t (let* ((dr (f-max 0f0 (- 1f0 (* 3f0 dt)))))
                             (setf (aref p (+ o 3)) (* dr (aref p (+ o 3)))
                                   (aref p (+ o 4)) (- (* dr (aref p (+ o 4))) (* 2f0 dt))
                                   (aref p (+ o 5)) (* dr (aref p (+ o 5))))))))
                (let* ((drag (cond ((or (= type +p-mist+) (= type +p-dust+) (= type +p-feather+))
                                    (f-max 0f0 (- 1f0 (* 3.5f0 dt))))
                                   ((= type +p-flame+) (f-max 0f0 (- 1f0 (* 1.5f0 dt))))
                                   (t 1f0))))
                  (declare (single-float drag))
                  (setf (aref p (+ o 3)) (* drag (aref p (+ o 3)))
                        (aref p (+ o 4)) (- (* drag (aref p (+ o 4))) (* (aref p (+ o 9)) dt))
                        (aref p (+ o 5)) (* drag (aref p (+ o 5))))))
            (setf (aref p o) (+ (aref p o) (* dt (aref p (+ o 3))))
                  (aref p (+ o 1)) (+ (aref p (+ o 1)) (* dt (aref p (+ o 4))))
                  (aref p (+ o 2)) (+ (aref p (+ o 2)) (* dt (aref p (+ o 5)))))
            (when (< (aref p (+ o 1)) 0.03f0)            ; the ground (y = 0)
              (setf (aref p (+ o 1)) 0.03f0 (aref p (+ o 4)) (* -0.3f0 (aref p (+ o 4)))
                    (aref p (+ o 3)) (* 0.6f0 (aref p (+ o 3))) (aref p (+ o 5)) (* 0.6f0 (aref p (+ o 5)))))))))
    (setf *plive* live)))

(defmacro %bb-verts (x y z sx sy sz ux uy uz r g b a)
  "Emit a camera-facing quad inside WITH-FX-VERTS: half axes S (right) and U (up)."
  `(progn
     (vtx (- ,x ,sx ,ux) (- ,y ,sy ,uy) (- ,z ,sz ,uz) -1f0 -1f0 ,r ,g ,b ,a)
     (vtx (- (+ ,x ,sx) ,ux) (- (+ ,y ,sy) ,uy) (- (+ ,z ,sz) ,uz) 1f0 -1f0 ,r ,g ,b ,a)
     (vtx (+ ,x ,sx ,ux) (+ ,y ,sy ,uy) (+ ,z ,sz ,uz) 1f0 1f0 ,r ,g ,b ,a)
     (vtx (- ,x ,sx ,ux) (- ,y ,sy ,uy) (- ,z ,sz ,uz) -1f0 -1f0 ,r ,g ,b ,a)
     (vtx (+ ,x ,sx ,ux) (+ ,y ,sy ,uy) (+ ,z ,sz ,uz) 1f0 1f0 ,r ,g ,b ,a)
     (vtx (+ (- ,x ,sx) ,ux) (+ (- ,y ,sy) ,uy) (+ (- ,z ,sz) ,uz) -1f0 1f0 ,r ,g ,b ,a)))

(defun-fast fx-draw-particles ()
  "Queue all live particles into the fx batches (inline vertex writes, no consing)."
  (let* ((p *parts*) (rt (camera-right *camera*)) (up (camera-upv *camera*)) (eye (camera-eye *camera*))
         (rx (aref rt 0)) (ry (aref rt 1)) (rz (aref rt 2)) (ux (aref up 0)) (uy (aref up 1)) (uz (aref up 2)))
    (declare (type f32vec p rt up eye) (single-float rx ry rz ux uy uz))
    (dotimes (i +pmax+)
      (let* ((o (* i +pstride+)) (life (aref p (+ o 6))))
        (declare (fixnum o) (single-float life))
        (when (> life 0f0)
          (let* ((type (aref p (+ o 13))) (u (/ life (aref p (+ o 7)))) (s (aref p (+ o 8)))
                 (x (aref p o)) (y (aref p (+ o 1))) (z (aref p (+ o 2)))
                 (r (aref p (+ o 10))) (g (aref p (+ o 11))) (b (aref p (+ o 12))) (ka (aref p (+ o 14))))
            (declare (single-float type u s x y z r g b ka))
            (cond
              ((>= type +p-t-blob+)                      ; toon kinds: stepped position, pushed toward the eye
               (let* ((pal ka) (rate (if (%matter-pal-p pal) 3f0 2f0)) (age (- (aref p (+ o 7)) life))
                      (since (f-mod (fx-clock) (/ rate 24f0))) (lag (f-min age since))
                      (u (f-min 1f0 (/ (+ life lag) (aref p (+ o 7)))))   ; life left when the drawing began
                      (vx (aref p (+ o 3))) (vy (aref p (+ o 4))) (vz (aref p (+ o 5)))
                      (x (- x (* lag vx))) (y (- y (* lag vy))) (z (- z (* lag vz)))
                      (seed (* 40f0 (%h01 (i->f i) 0.618f0))) (k (+ 0.12f0 (* 0.86f0 u))) (wob r))
                 (declare (single-float pal rate age since lag u vx vy vz x y z seed k wob))
                 (cond
                   ((< age since) nil)                   ; born during this drawing: it shows from the next one
                   ((= type +p-t-blob+)
                     (let* ((sz (* s (if (%matter-pal-p pal) (+ 1f0 (* 0.8f0 (- 1f0 u))) (+ 0.4f0 (* 0.6f0 u))))))
                       (declare (single-float sz))
                       (%toward-eye (x y z sc) (* 0.8f0 sz)
                         (let* ((sz (* sz sc)) (sx (* sz rx)) (sy (* sz ry)) (sz2 (* sz rz)) (vx (* sz ux)) (vy (* sz uy)) (vz (* sz uz))
                                (a (toon-a pal k)))
                           (declare (single-float sz sx sy sz2 vx vy vz a))
                           (with-fx-verts (d o2 :toon 6)
                             (%bb-verts x y z sx sy sz2 vx vy vz 1f0 seed wob a))))))
                   (t
                     (let* ((l (f-sqrt (+ (* vx vx) (* vy vy) (* vz vz)))))
                       (declare (single-float l))
                       (if (> l 1f-3)
                           (fx-shard x y z (/ vx l) (/ vy l) (/ vz l) s (* 0.3f0 s) wob seed pal k)
                           (fx-shard x y z rx ry rz s (* 0.3f0 s) wob seed pal k)))))))
              ((= type +p-spark+)                        ; velocity-stretched additive line
               (let* ((vx (aref p (+ o 3))) (vy (aref p (+ o 4))) (vz (aref p (+ o 5)))
                      (x1 (- x (* 0.035f0 vx))) (y1 (- y (* 0.035f0 vy))) (z1 (- z (* 0.035f0 vz)))
                      (dx (- x1 x)) (dy (- y1 y)) (dz (- z1 z))
                      (ex (- (aref eye 0) x)) (ey (- (aref eye 1) y)) (ez (- (aref eye 2) z))
                      (cx (- (* dy ez) (* dz ey))) (cy (- (* dz ex) (* dx ez))) (cz (- (* dx ey) (* dy ex)))
                      (cl (f-sqrt (+ (* cx cx) (* cy cy) (* cz cz)))) (w (* s u)))
                 (declare (single-float vx vy vz x1 y1 z1 dx dy dz ex ey ez cx cy cz cl w))
                 (when (> cl 1f-6)
                   (setf cx (* w (/ cx cl)) cy (* w (/ cy cl)) cz (* w (/ cz cl)))
                   (with-fx-verts (d o2 :add 3)
                     (vtx (- x cx) (- y cy) (- z cz) 0f0 -1f0 r g b (* ka u))
                     (vtx (+ x cx) (+ y cy) (+ z cz) 0f0 1f0 r g b (* ka u))
                     (vtx x1 y1 z1 0f0 0f0 r g b 0f0)))))
              ((or (= type +p-mist+) (= type +p-dust+))  ; soft alpha puff that grows and darkens
               (let* ((sz (* s (+ 1f0 (* 1.2f0 (- 1f0 u))))) (a (* ka (* (if (= type +p-mist+) 0.85f0 0.45f0) u)))
                      (k (if (= type +p-mist+) (+ 0.5f0 (* 0.5f0 u)) 1f0))
                      (sx (* sz rx)) (sy (* sz ry)) (sz2 (* sz rz)) (vx (* sz ux)) (vy (* sz uy)) (vz (* sz uz)))
                 (declare (single-float sz a k sx sy sz2 vx vy vz))
                 (with-fx-verts (d o2 :alpha 6)
                   (%bb-verts x y z sx sy sz2 vx vy vz (* k r) (* k g) (* k b) a))))
              ((= type +p-feather+)
               (let* ((a (* ka (* 0.9f0 u))) (sx (* s rx 0.45f0)) (sy (* s ry 0.45f0)) (sz2 (* s rz 0.45f0))
                      (vx (* s ux)) (vy (* s uy)) (vz (* s uz)))
                 (declare (single-float a sx sy sz2 vx vy vz))
                 (with-fx-verts (d o2 :alpha 6)
                   (%bb-verts x y z sx sy sz2 vx vy vz r g b a))))
              ((= type +p-flame+)                        ; additive, shrinking, hot core -> orange -> dark red
               (let* ((age (- 1f0 u))
                      (k1 (f-min 1f0 (* 5f0 age)))                            ; age 0..0.2: emit color -> orange
                      (k2 (f-clamp (* 2.857f0 (- age 0.2f0)) 0f0 1f0))        ; age 0.2..0.55: orange -> dark red
                      (cr (+ r (* (- 1f0 r) k1))) (cg (+ g (* (- 0.42f0 g) k1))) (cb (+ b (* (- 0.06f0 b) k1)))
                      (a (* ka (if (< age 0.1f0) (* 0.8f0 u) (* -0.8f0 u))))   ; faint layers; < 0: no white core (fx.frag)
                      (sz (* s (+ 0.3f0 (* 0.7f0 u)))) (sx (* sz rx)) (sy (* sz ry)) (sz2 (* sz rz))
                      (vx (* sz ux)) (vy (* sz uy)) (vz (* sz uz)))
                 (declare (single-float age k1 k2 cr cg cb a sz sx sy sz2 vx vy vz))
                 (setf cr (+ cr (* (- 0.45f0 cr) k2)) cg (+ cg (* (- 0.05f0 cg) k2)) cb (+ cb (* (- 0.02f0 cb) k2)))
                 (with-fx-verts (d o2 :add 6)
                   (%bb-verts x y z sx sy sz2 vx vy vz cr cg cb a))))
              (t                                          ; orbs + glow: additive
               (let* ((fl (if (> type 4.5f0) u 1f0)) (a (* ka (if (< life 0.5f0) (* 2f0 life) 1f0)))
                      (sz (* s fl)) (sx (* sz rx)) (sy (* sz ry)) (sz2 (* sz rz))
                      (vx (* sz ux)) (vy (* sz uy)) (vz (* sz uz)))
                 (declare (single-float fl a sz sx sy sz2 vx vy vz))
                 (with-fx-verts (d o2 :add 6)
                   (%bb-verts x y z sx sy sz2 vx vy vz r g b a)))))))))))

;;; ---------------------------------------------------------------- rings (parry / shockwave)
(defconstant +ring-n+ 16)
(declaim (type f32vec *rings*))
(defconstant +ring-stride+ 13)
(defvar *rings* (make-f32 (* +ring-stride+ +ring-n+)) "x y z r0 r1 age dur r g b flat width palette (-1 = soft)")
(defun fx-ring (x y z r0 r1 dur r g b &key flat (width 0.05) palette)
  "Expanding ring: camera-facing (parry) or FLAT on the ground (shockwave). PALETTE (0..11, see
TOON-A): drawn as a toon shape instead (the band's two edges inked, eroding as it fades; R G B unused)."
  (let* ((s *rings*) (best 0) (ba -1f0))
    (dotimes (i +ring-n+)
      (let ((rem (- (aref s (+ (* i +ring-stride+) 6)) (aref s (+ (* i +ring-stride+) 5)))))
        (when (or (< ba 0) (< rem ba)) (setf ba rem best i))))
    (let ((o (* best +ring-stride+)))
      (setf (aref s (+ o 12)) (if palette (f32 palette) -1f0))
      (setf (aref s o) (f32 x) (aref s (+ o 1)) (f32 y) (aref s (+ o 2)) (f32 z) (aref s (+ o 3)) (f32 r0)
            (aref s (+ o 4)) (f32 r1) (aref s (+ o 5)) 0f0 (aref s (+ o 6)) (f32 dur)
            (aref s (+ o 7)) (f32 r) (aref s (+ o 8)) (f32 g) (aref s (+ o 9)) (f32 b)
            (aref s (+ o 10)) (if flat 1f0 0f0) (aref s (+ o 11)) (f32 width)))))

(defun-fast fx-rings-update (dt)
  (declare (single-float dt))
  (let* ((s *rings*) (rt (camera-right *camera*)) (up (camera-upv *camera*)))
    (declare (type f32vec s rt up))
    (dotimes (i +ring-n+)
      (let* ((o (* i +ring-stride+)) (age (aref s (+ o 5))) (dur (aref s (+ o 6))))
        (declare (fixnum o) (single-float age dur))
        (when (< age dur)
          (setf (aref s (+ o 5)) (+ age dt))
          (let* ((u (/ age dur)) (rad (+ (aref s (+ o 3)) (* u (- (aref s (+ o 4)) (aref s (+ o 3))))))
                 (a (- 1f0 u)) (w (aref s (+ o 11))) (flat (> (aref s (+ o 10)) 0.5f0))
                 (x (aref s o)) (y (aref s (+ o 1))) (z (aref s (+ o 2)))
                 (r (aref s (+ o 7))) (g (aref s (+ o 8))) (b (aref s (+ o 9))) (pal (aref s (+ o 12))))
            (declare (single-float u rad a w x y z r g b pal))
            (when (>= pal 0f0)                 ; toon ring: uv (0, -1..1) across the band, seed = the slot
              (setf r 1f0 g (+ 1f0 (i->f i)) b 0.12f0 a (toon-a pal (* 0.98f0 (- 1f0 (* u u)))) y (+ y 0.02f0)))
            (with-fx-verts (d o2 (if (>= pal 0f0) :toon :add) (* 6 24))
              (dotimes (k 24)
                (let* ((a0 (* (i->f k) 0.2618f0)) (a1 (+ a0 0.2618f0))
                       (c0 (f-cos a0)) (s0 (f-sin a0)) (c1 (f-cos a1)) (s1 (f-sin a1))
                       (ri (- rad w)) (ro (+ rad w)))
                  (declare (single-float a0 a1 c0 s0 c1 s1 ri ro))
                  (macrolet ((pt (c sn rr)      ; point on the ring plane
                               `(if flat
                                    (values (+ x (* ,rr ,c)) (+ y 0.03f0) (+ z (* ,rr ,sn)))
                                    (values (+ x (* ,rr (+ (* ,c (aref rt 0)) (* ,sn (aref up 0)))))
                                            (+ y (* ,rr (+ (* ,c (aref rt 1)) (* ,sn (aref up 1)))))
                                            (+ z (* ,rr (+ (* ,c (aref rt 2)) (* ,sn (aref up 2)))))))))
                    (multiple-value-bind (x0 y0 z0) (pt c0 s0 ri)
                      (multiple-value-bind (x1 y1 z1) (pt c0 s0 ro)
                        (multiple-value-bind (x2 y2 z2) (pt c1 s1 ro)
                          (multiple-value-bind (x3 y3 z3) (pt c1 s1 ri)
                            (declare (single-float x0 y0 z0 x1 y1 z1 x2 y2 z2 x3 y3 z3))
                            (if (>= pal 0f0)
                                (progn (vtx x0 y0 z0 0f0 -1f0 r g b a) (vtx x1 y1 z1 0f0 1f0 r g b a) (vtx x2 y2 z2 0f0 1f0 r g b a)
                                       (vtx x0 y0 z0 0f0 -1f0 r g b a) (vtx x2 y2 z2 0f0 1f0 r g b a) (vtx x3 y3 z3 0f0 -1f0 r g b a))
                                (progn (vtx x0 y0 z0 0f0 1f0 r g b a) (vtx x1 y1 z1 0f0 0f0 r g b a) (vtx x2 y2 z2 0f0 0f0 r g b a)
                                       (vtx x0 y0 z0 0f0 1f0 r g b a) (vtx x2 y2 z2 0f0 0f0 r g b a) (vtx x3 y3 z3 0f0 1f0 r g b a)))))))))))))))))

;;; ---------------------------------------------------------------- rigid debris (limbs, death parts)
;;; Slot stride 32: [0-15] rotation*scale (no translation) [16-18] pos [19-21] vel [22-24] euler
;;; [25-27] angular velocity [28] age [29] bounced
(defconstant +deb-n+ 128)
(declaim (type f32vec *deb* *deb-m* *deb-t*) (type simple-vector *deb-mesh*) (type fixnum *deb-cursor*))
(defvar *deb* (make-f32 (* 32 +deb-n+)))
(defvar *deb-mesh* (make-array +deb-n+ :initial-element nil))
(defvar *deb-cursor* 0)
(defvar *deb-m* (make-f32 16))
(defvar *deb-t* (make-f32 16))
(defparameter *debris-life* 2.4 "s before a debris part is gone (shrinks over the last 0.4 s)")

(defun-fast fx-debris (mesh m mo vx vy vz spin)
  "Detach MESH drawn with the world matrix at M[MO..MO+15] as a physics piece with velocity
(vx vy vz) and random angular velocity up to SPIN rad/s."
  (declare (type f32vec m) (fixnum mo) (single-float vx vy vz spin))
  (let* ((d *deb*) (i *deb-cursor*) (o (* i 32)))
    (declare (type f32vec d) (fixnum i o))
    (setf (svref *deb-mesh* i) mesh)
    (replace d m :start1 o :start2 mo :end2 (+ mo 12))
    (setf (aref d (+ o 12)) 0f0 (aref d (+ o 13)) 0f0 (aref d (+ o 14)) 0f0 (aref d (+ o 15)) 1f0
          (aref d (+ o 16)) (aref m (+ mo 12)) (aref d (+ o 17)) (aref m (+ mo 13)) (aref d (+ o 18)) (aref m (+ mo 14))
          (aref d (+ o 19)) vx (aref d (+ o 20)) vy (aref d (+ o 21)) vz
          (aref d (+ o 22)) 0f0 (aref d (+ o 23)) 0f0 (aref d (+ o 24)) 0f0
          (aref d (+ o 25)) (rnd-range (- spin) spin) (aref d (+ o 26)) (rnd-range (- spin) spin)
          (aref d (+ o 27)) (rnd-range (- spin) spin) (aref d (+ o 28)) 0f0 (aref d (+ o 29)) 0f0)
    (incf i) (when (>= i +deb-n+) (setf i 0))
    (setf *deb-cursor* i)
    nil))

(defun-fast fx-debris-update (dt)
  "Integrate and draw debris (DT = sim seconds: debris freezes with hitstop)."
  (declare (single-float dt))
  (let* ((d *deb*) (m *deb-m*) (tm *deb-t*) (life (the single-float *debris-life*)))
    (declare (type f32vec d m tm) (single-float life))
    (dotimes (i +deb-n+)
      (let* ((mesh (svref *deb-mesh* i)) (o (* i 32)))
        (declare (fixnum o))
        (when mesh
          (let* ((age (+ (aref d (+ o 28)) dt)))
            (declare (single-float age))
            (setf (aref d (+ o 28)) age)
            (if (> age life)
                (setf (svref *deb-mesh* i) nil)
                (progn
                  (setf (aref d (+ o 20)) (- (aref d (+ o 20)) (* 18f0 dt)))
                  (dotimes (k 3)
                    (setf (aref d (+ o 16 k)) (+ (aref d (+ o 16 k)) (* dt (aref d (+ o 19 k))))
                          (aref d (+ o 22 k)) (+ (aref d (+ o 22 k)) (* dt (aref d (+ o 25 k))))))
                  (when (< (aref d (+ o 17)) 0.08f0)
                    (setf (aref d (+ o 17)) 0.08f0)
                    (if (< (aref d (+ o 29)) 0.5f0)
                        (setf (aref d (+ o 20)) (* -0.3f0 (aref d (+ o 20))) (aref d (+ o 29)) 1f0)
                        (setf (aref d (+ o 20)) 0f0))
                    (setf (aref d (+ o 19)) (* 0.8f0 (aref d (+ o 19))) (aref d (+ o 21)) (* 0.8f0 (aref d (+ o 21)))
                          (aref d (+ o 25)) (* 0.9f0 (aref d (+ o 25))) (aref d (+ o 26)) (* 0.9f0 (aref d (+ o 26)))
                          (aref d (+ o 27)) (* 0.9f0 (aref d (+ o 27)))))
                  (let* ((s (if (> age (- life 0.4f0)) (f-max 0.001f0 (/ (- life age) 0.4f0)) 1f0)))
                    (declare (single-float s))
                    (%euler! tm 0 (aref d (+ o 16)) (aref d (+ o 17)) (aref d (+ o 18))
                             (aref d (+ o 23)) (aref d (+ o 22)) (aref d (+ o 24)) s)
                    (%affine-mul! m 0 tm 0 d o)
                    (draw-mesh mesh m))))))))))

(defun fx-clear-debris () (fill *deb-mesh* nil))

(defun fx-clear ()
  "Remove every particle, ring and debris piece and stop the shake (a new round / scene)."
  (let ((p *parts*) (s *rings*))
    (declare (type f32vec p s))
    (dotimes (i +pmax+) (setf (aref p (+ (* i +pstride+) 6)) 0f0))
    (dotimes (i +ring-n+) (setf (aref s (+ (* i +ring-stride+) 6)) 0f0))    ; dur 0: age >= dur = finished
    (setf *plive* 0))
  (fill *shake* 0f0)
  (fill (camera-shake *camera*) 0f0)
  (fx-clear-debris))

(defun fx-clear-orbs ()
  "Kill in-flight orb particles (e.g. a retry must not collect pickups after a checkpoint restore)."
  (let ((p *parts*))
    (declare (type f32vec p))
    (dotimes (i +pmax+)
      (let* ((o (* i +pstride+)) (ty (aref p (+ o 13))))
        (when (or (= ty +p-orb-a+) (= ty +p-orb-b+)) (setf (aref p (+ o 6)) 0f0))))))

;;; ---------------------------------------------------------------- sword trails
;;; A trail is an f32vec: +TRAIL-N+ samples x (base xyz, tip xyz), oldest first, count at [60].
;;; Push a blade's base/tip each sim step while it swings, decay otherwise, draw it with FX-TRAIL.
(defconstant +trail-n+ 10)
(defun make-trail () (make-f32 (+ (* 6 +trail-n+) 1)))
(defmacro trail-count (tr)
  "Samples in trail TR (a float; SETF-able, e.g. to 0 to drop the trail at once)."
  `(aref ,tr (* 6 +trail-n+)))

(defun-fast trail-push (tr bx by bz tx ty tz)
  (declare (type f32vec tr) (single-float bx by bz tx ty tz))
  (let* ((n (f->i (aref tr 60))))
    (declare (fixnum n))
    (when (>= n +trail-n+)
      (replace tr tr :start1 0 :start2 6 :end2 (* 6 +trail-n+))
      (setf n (1- +trail-n+)))
    (let* ((o (* n 6)))
      (declare (fixnum o))
      (setf (aref tr o) bx (aref tr (+ o 1)) by (aref tr (+ o 2)) bz
            (aref tr (+ o 3)) tx (aref tr (+ o 4)) ty (aref tr (+ o 5)) tz
            (aref tr 60) (i->f (1+ n))))))

(defun-fast trail-decay (tr)
  "Drop the oldest sample (called each sim step when not emitting)."
  (declare (type f32vec tr))
  (let* ((n (f->i (aref tr 60))))
    (declare (fixnum n))
    (when (> n 0)
      (replace tr tr :start1 0 :start2 6 :end2 (* 6 n))
      (setf (aref tr 60) (i->f (1- n))))))

;;; ---------------------------------------------------------------- screen effects (UI layer)
(defun edge-vignette (r g b a frac)
  "Darken toward the screen edges with color (r g b) at alpha A; FRAC = band size."
  (let* ((w (window-width)) (h (window-height)) (bw (* w frac)) (bh (* h frac))
         (c1 (list r g b a)) (c0 (list r g b 0)))
    (ui-gradient 0 0 w bh c1 c0)
    (ui-gradient 0 (- h bh) w bh c0 c1)
    (ui-gradient 0 0 bw h c1 c0 :vertical nil)
    (ui-gradient (- w bw) 0 bw h c0 c1 :vertical nil)))

;;; ---------------------------------------------------------------- debug drawing: hit volumes
;;; Overlays for tuning hits (a debug key / command): hurt cylinders as two circles, attack
;;; volumes (hitvol.lisp) as FX-LINE outlines. Not for shipping frames (they cons: generic math).
(defun draw-circle (x y z r cr cg cb &key (segments 16) (width 0.012) (alpha 0.8))
  "Debug: horizontal circle of radius R centred on (X Y Z), in colour (CR CG CB)."
  (dotimes (i segments)
    (let ((a0 (* i (/ (* 2 pi) segments))) (a1 (* (1+ i) (/ (* 2 pi) segments))))
      (fx-line (+ x (* r (sin a0))) y (+ z (* r (cos a0))) (+ x (* r (sin a1))) y (+ z (* r (cos a1)))
               width cr cg cb alpha))))

(defun draw-vol (v ax ay az yaw &optional tx ty tz)
  "Debug: outline attack volume V (MAKE-VOL) of an attacker whose feet are at (AX AY AZ), facing
YAW, in red. A TSPH is drawn around the target point (TX TY+1.1 TZ) when it is given."
  (let ((fx (fwd-x (f32 yaw))) (fz (fwd-z (f32 yaw))))
    (case (round (aref v 0))
      (0 (let ((r (aref v 1)) (half (aref v 2)))                      ; ARC: both rims + the edges
           (dolist (hy (list (aref v 3) (aref v 4)))
             (let* ((n 12) (y (+ ay hy)))
               (dotimes (i n)
                 (let* ((t0 (+ yaw (- half) (* (/ (* 2 half) n) i))) (t1 (+ t0 (/ (* 2 half) n))))
                   (fx-line (- ax (* r (sin t0))) y (- az (* r (cos t0))) (- ax (* r (sin t1))) y (- az (* r (cos t1)))
                            0.015 1 0.2 0.2 0.9)))
               (when (< half 3.1)
                 (fx-line ax y az (- ax (* r (sin (+ yaw half)))) y (- az (* r (cos (+ yaw half)))) 0.015 1 0.2 0.2 0.9)
                 (fx-line ax y az (- ax (* r (sin (- yaw half)))) y (- az (* r (cos (- yaw half)))) 0.015 1 0.2 0.2 0.9))))))
      (1 (let ((y (+ ay (aref v 3))))                                   ; CAP: a thick line
           (fx-line (+ ax (* fx (aref v 1))) y (+ az (* fz (aref v 1))) (+ ax (* fx (aref v 2))) y (+ az (* fz (aref v 2)))
                    (aref v 4) 1 0.2 0.2 0.25)))
      (2 (draw-circle (+ ax (* fx (aref v 1))) (+ ay (aref v 2)) (+ az (* fz (aref v 1))) (aref v 3) 1 0.2 0.2))
      (3 (when tx (draw-circle tx (+ ty 1.1) tz (aref v 1) 1 0.2 0.2))))))

;;; ---------------------------------------------------------------- ribbons (camera-facing tapered strips)
;;; A tapering strip from a base point along an axis, turned to face the camera around that axis,
;;; soft across its width, colour/alpha lerped base → tip, width and sideways sway flickering with
;;; PH. Flames, pillars, dome walls, auras and blade sheaths are layers of it.
;;; FX-RIBBON (a macro) writes its arguments into *RIBBON-ARGS*, so the call conses nothing.
(declaim (type f32vec *ribbon-args*))
(defvar *ribbon-args* (make-f32 18) "x y z ax ay az w0 w1 r0 g0 b0 a0 r1 g1 b1 a1 phase sway")

(defun-fast %fx-ribbon (segs mode)
  "FX-RIBBON's body: SEGS segments into the MODE (:add / :alpha) fx batch."
  (declare (fixnum segs))
  (let* ((rb *ribbon-args*) (eye (camera-eye *camera*)) (rt (camera-right *camera*))
         (x (aref rb 0)) (y (aref rb 1)) (z (aref rb 2)) (ax (aref rb 3)) (ay (aref rb 4)) (az (aref rb 5))
         (l (f-sqrt (+ (* ax ax) (* ay ay) (* az az)))))
    (declare (type f32vec rb eye rt) (single-float x y z ax ay az l))
    (when (> l 1f-4)
      (let* ((nx (/ ax l)) (ny (/ ay l)) (nz (/ az l))
             (ex (- (aref eye 0) x)) (ey (- (aref eye 1) y)) (ez (- (aref eye 2) z))
             (sx (- (* ny ez) (* nz ey))) (sy (- (* nz ex) (* nx ez))) (sz (- (* nx ey) (* ny ex)))
             (sl (f-sqrt (+ (* sx sx) (* sy sy) (* sz sz))))
             (w0 (aref rb 6)) (w1 (aref rb 7)) (ph (aref rb 16)) (sw (aref rb 17))
             (inv (/ 1f0 (i->f segs)))
             (lx 0f0) (ly 0f0) (lz 0f0) (qx 0f0) (qy 0f0) (qz 0f0) (pr 0f0) (pg 0f0) (pb 0f0) (pa 0f0))
        (declare (single-float nx ny nz ex ey ez sx sy sz sl w0 w1 ph sw inv lx ly lz qx qy qz pr pg pb pa))
        (if (< sl 1f-5)
            (setf sx (aref rt 0) sy (aref rt 1) sz (aref rt 2))
            (setf sx (/ sx sl) sy (/ sy sl) sz (/ sz sl)))
        (with-fx-verts (d o mode (* 6 segs))
          (dotimes (i (1+ segs))
            (let* ((u (* (i->f i) inv))
                   (off (* sw u (+ (f-sin (+ ph (* 5f0 u))) (* 0.5f0 (f-sin (+ (* 1.7f0 ph) (* 11f0 u)))))))
                   (w (* (+ w0 (* (- w1 w0) u)) (+ 1f0 (* 0.14f0 (f-sin (+ (* 2.3f0 ph) (* 9f0 u)))))))
                   (cx (+ x (* ax u) (* sx off))) (cy (+ y (* ay u) (* sy off))) (cz (+ z (* az u) (* sz off)))
                   (r (+ (aref rb 8) (* u (- (aref rb 12) (aref rb 8)))))
                   (g (+ (aref rb 9) (* u (- (aref rb 13) (aref rb 9)))))
                   (b (+ (aref rb 10) (* u (- (aref rb 14) (aref rb 10)))))
                   (a (+ (aref rb 11) (* u (- (aref rb 15) (aref rb 11)))))
                   (mx (- cx (* sx w))) (my (- cy (* sy w))) (mz (- cz (* sz w)))
                   (kx (+ cx (* sx w))) (ky (+ cy (* sy w))) (kz (+ cz (* sz w))))
              (declare (single-float u off w cx cy cz r g b a mx my mz kx ky kz))
              (when (> i 0)
                (vtx lx ly lz -1f0 0f0 pr pg pb pa) (vtx qx qy qz 1f0 0f0 pr pg pb pa) (vtx kx ky kz 1f0 0f0 r g b a)
                (vtx lx ly lz -1f0 0f0 pr pg pb pa) (vtx kx ky kz 1f0 0f0 r g b a) (vtx mx my mz -1f0 0f0 r g b a))
              (setf lx mx ly my lz mz qx kx qy ky qz kz pr r pg g pb b pa a))))))))

(defmacro fx-ribbon (x y z ax ay az w0 w1 r0 g0 b0 a0 r1 g1 b1 a1 ph sway &key (segs 6) (mode :add))
  "Draw a ribbon from (X Y Z) along the axis (AX AY AZ): half-width W0 at the base, W1 at the tip,
colour (R0 G0 B0 A0) at the base, (R1 G1 B1 A1) at the tip, PH the flicker phase, SWAY the sideways
sway amplitude (m), SEGS segments. All numeric arguments must be single-float expressions (no
boxing). A0/A1 < 0 = additive without the white hot core; > 0 whitens the centre line (hot core)."
  (let ((rb (gensym "RB")))                       ; a gensym: the arguments may name any variable
    `(let* ((,rb *ribbon-args*))
       (declare (type f32vec ,rb))
       (setf (aref ,rb 0) ,x (aref ,rb 1) ,y (aref ,rb 2) ,z (aref ,rb 3) ,ax (aref ,rb 4) ,ay (aref ,rb 5) ,az
             (aref ,rb 6) ,w0 (aref ,rb 7) ,w1 (aref ,rb 8) ,r0 (aref ,rb 9) ,g0 (aref ,rb 10) ,b0 (aref ,rb 11) ,a0
             (aref ,rb 12) ,r1 (aref ,rb 13) ,g1 (aref ,rb 14) ,b1 (aref ,rb 15) ,a1 (aref ,rb 16) ,ph (aref ,rb 17) ,sway)
       (%fx-ribbon ,segs ,mode))))

;;; ---------------------------------------------------------------- ground sectors
(defun-fast fx-sector (x y z r0 r1 yaw half r g b a &key (mode :add) (segs 16))
  "Flat annular sector between radii R0 and R1 at height Y, centred on direction YAW (forward =
(FWD-X yaw, FWD-Z yaw)), spanning ±HALF radians (HALF ≥ pi = full ring). Soft toward both radii.
A telegraph cone, a fire front, a shock ring."
  (declare (fixnum segs))
  (let* ((x (f32 x)) (y (f32 y)) (z (f32 z)) (r0 (f32 r0)) (r1 (f32 r1)) (yaw (f32 yaw)) (half (f32 half))
         (r (f32 r)) (g (f32 g)) (b (f32 b)) (a (f32 a)))
    (declare (single-float x y z r0 r1 yaw half r g b a))
    (let* ((y (+ y 0.03f0)) (a0 (- yaw half)) (da (/ (* 2f0 half) (i->f segs))))
      (declare (single-float y a0 da))
      (with-fx-verts (d o mode (* 6 segs))
        (dotimes (k segs)
          (let* ((t0 (+ a0 (* da (i->f k)))) (t1 (+ t0 da))
                 (c0 (- (f-sin t0))) (s0 (- (f-cos t0))) (c1 (- (f-sin t1))) (s1 (- (f-cos t1))))
            (declare (single-float t0 t1 c0 s0 c1 s1))
            (vtx (+ x (* r0 c0)) y (+ z (* r0 s0)) 0f0 -1f0 r g b a)
            (vtx (+ x (* r1 c0)) y (+ z (* r1 s0)) 0f0 1f0 r g b a)
            (vtx (+ x (* r1 c1)) y (+ z (* r1 s1)) 0f0 1f0 r g b a)
            (vtx (+ x (* r0 c0)) y (+ z (* r0 s0)) 0f0 -1f0 r g b a)
            (vtx (+ x (* r1 c1)) y (+ z (* r1 s1)) 0f0 1f0 r g b a)
            (vtx (+ x (* r0 c1)) y (+ z (* r0 s1)) 0f0 -1f0 r g b a)))))))

;;; ---------------------------------------------------------------- toon shape primitives (bodies)
(defun-fast %fx-star (n)
  (declare (fixnum n))
  (let* ((a *tn-args*) (x (aref a 0)) (y (aref a 1)) (z (aref a 2)) (r0 (aref a 3)) (r1 (aref a 4)) (rot (aref a 5))
         (dx (aref a 6)) (dy (aref a 7)) (wob (aref a 8)) (seed (aref a 9)) (pk (toon-a (aref a 10) (aref a 11) t))
         (push (aref a 12)) (rt (camera-right *camera*)) (up (camera-upv *camera*))
         (n (max 3 n)) (m (* 2 n)) (dl (f-sqrt (+ (* dx dx) (* dy dy)))) (poly (>= r0 r1))
         (step (/ 6.2831855f0 (i->f m))) (near (f-cos (/ 3.1415927f0 (i->f n)))))
    (declare (type f32vec a rt up) (fixnum n m)
             (single-float x y z r0 r1 rot dx dy wob seed pk push dl step near))
    (%toward-eye (x y z sc) push
      (let* ((r0 (* r0 sc)) (r1 (* r1 sc)) (px 0f0) (py 0f0) (pz 0f0) (pu 0f0) (pv 0f0))
        (declare (single-float r0 r1 px py pz pu pv))
        (with-fx-verts (d o :toon (* 3 m))
          (dotimes (j (1+ m))
            (let* ((jj (if (= j m) 0 j)) (jf (i->f jj)) (tip (evenp jj))
                   (ang (+ rot (* step jf) (if poly 0f0 (* 0.42f0 (- (%h01 jf seed) 0.5f0)))))
                   (ca (f-cos ang)) (sa (f-sin ang))
                   (dir (if (> dl 1f-4) (/ (+ (* ca dx) (* sa dy)) dl) 0f0))
                   (len (cond (poly (if tip r1 (* r1 near)))
                              (tip (* r1 (+ 0.5f0 (* 0.9f0 (%h01 (+ jf 7.1f0) seed)))
                                      (cond ((> dir near) 1.7f0)
                                            ((and (< dir (- near)) (> (%h01 3.3f0 seed) 0.5f0)) 1.25f0)
                                            (t 1f0))))
                              (t (* r0 (+ 0.75f0 (* 0.5f0 (%h01 (+ jf 3.3f0) seed)))))))
                   (ox (* len (+ (* ca (aref rt 0)) (* sa (aref up 0)))))
                   (oy (* len (+ (* ca (aref rt 1)) (* sa (aref up 1)))))
                   (oz (* len (+ (* ca (aref rt 2)) (* sa (aref up 2)))))
                   (wx (+ x ox)) (wy (+ y oy)) (wz (+ z oz)))
              (declare (fixnum jj) (single-float jf ang ca sa dir len ox oy oz wx wy wz))
              (when (> j 0)
                (vtx x y z 0f0 0f0 0f0 seed wob pk)
                (vtx px py pz pu pv 1f0 seed wob pk)
                (vtx wx wy wz ca sa 1f0 seed wob pk))
              (setf px wx py wy pz wz pu ca pv sa)))))))
  nil)

(defun-fast %fx-shard ()
  (let* ((a *tn-args*) (x (aref a 0)) (y (aref a 1)) (z (aref a 2)) (dx (aref a 3)) (dy (aref a 4)) (dz (aref a 5))
         (len (aref a 6)) (w (aref a 7)) (wob (aref a 8)) (seed (aref a 9)) (pk (toon-a (aref a 10) (aref a 11) t))
         (push (aref a 12)))
    (declare (type f32vec a) (single-float x y z dx dy dz len w wob seed pk push))
    (%toward-eye (x y z sc) push
      (let* ((e (camera-eye *camera*)) (ex (- (aref e 0) x)) (ey (- (aref e 1) y)) (ez (- (aref e 2) z))
             (sx (- (* dy ez) (* dz ey))) (sy (- (* dz ex) (* dx ez))) (sz (- (* dx ey) (* dy ex)))
             (sl (f-max 1f-5 (f-sqrt (+ (* sx sx) (* sy sy) (* sz sz)))))
             (len (* len sc)) (w (/ (* w sc) sl)) (f (* 0.6f0 len)) (b (* 0.4f0 len))
             (tx (+ x (* f dx))) (ty (+ y (* f dy))) (tz (+ z (* f dz)))
             (bx (- x (* b dx))) (by (- y (* b dy))) (bz (- z (* b dz)))
             (lx (+ x (* w sx))) (ly (+ y (* w sy))) (lz (+ z (* w sz)))
             (rx (- x (* w sx))) (ry (- y (* w sy))) (rz (- z (* w sz))))
        (declare (type f32vec e) (single-float ex ey ez sx sy sz sl len w f b tx ty tz bx by bz lx ly lz rx ry rz))
        (with-fx-verts (d o :toon 12)
          (vtx x y z 0f0 0f0 0f0 seed wob pk) (vtx tx ty tz 0f0 1f0 1f0 seed wob pk) (vtx lx ly lz -1f0 0f0 1f0 seed wob pk)
          (vtx x y z 0f0 0f0 0f0 seed wob pk) (vtx lx ly lz -1f0 0f0 1f0 seed wob pk) (vtx bx by bz 0f0 -1f0 1f0 seed wob pk)
          (vtx x y z 0f0 0f0 0f0 seed wob pk) (vtx bx by bz 0f0 -1f0 1f0 seed wob pk) (vtx rx ry rz 1f0 0f0 1f0 seed wob pk)
          (vtx x y z 0f0 0f0 0f0 seed wob pk) (vtx rx ry rz 1f0 0f0 1f0 seed wob pk) (vtx tx ty tz 0f0 1f0 1f0 seed wob pk)))))
  nil)

(defun-fast %fx-crescent (comet)
  (declare (fixnum comet))
  (let* ((a *tn-args*) (x0 (aref a 0)) (y0 (aref a 1)) (z0 (aref a 2)) (x1 (aref a 3)) (y1 (aref a 4)) (z1 (aref a 5))
         (bx (aref a 6)) (by (aref a 7)) (bz (aref a 8)) (w (aref a 9)) (wob (aref a 10))
         (seed (- -1f0 (f-abs (aref a 11)))) (pal (aref a 12)) (kk (aref a 13)) (push (aref a 14))
         (pk (toon-a pal kk)) (e (camera-eye *camera*))
         (lx 0f0) (ly 0f0) (lz 0f0) (rx 0f0) (ry 0f0) (rz 0f0) (lh 0f0))
    (declare (type f32vec a e) (single-float x0 y0 z0 x1 y1 z1 bx by bz w wob seed pal kk push pk lx ly lz rx ry rz lh))
    (with-fx-verts (d o :toon 48)
      (dotimes (i 9)
        (let* ((u (* 0.125f0 (i->f i))) (v (- 1f0 u))
               (px (+ (* v v x0) (* 2f0 u v bx) (* u u x1))) (py (+ (* v v y0) (* 2f0 u v by) (* u u y1)))
               (pz (+ (* v v z0) (* 2f0 u v bz) (* u u z1)))
               (tx (+ (* 2f0 v (- bx x0)) (* 2f0 u (- x1 bx)))) (ty (+ (* 2f0 v (- by y0)) (* 2f0 u (- y1 by))))
               (tz (+ (* 2f0 v (- bz z0)) (* 2f0 u (- z1 bz))))
               (ex (- (aref e 0) px)) (ey (- (aref e 1) py)) (ez (- (aref e 2) pz))
               (el (f-max 1f-3 (f-sqrt (+ (* ex ex) (* ey ey) (* ez ez))))) (pp (f-min push (* 0.5f0 el)))
               (px (+ px (* pp (/ ex el)))) (py (+ py (* pp (/ ey el)))) (pz (+ pz (* pp (/ ez el))))
               (sx (- (* ty ez) (* tz ey))) (sy (- (* tz ex) (* tx ez))) (sz (- (* tx ey) (* ty ex)))
               (sl (f-max 1f-6 (f-sqrt (+ (* sx sx) (* sy sy) (* sz sz)))))
               (hw (if (= comet 1)
                       (* w (ffi:c-inline (u) (:float) :float "powf(#0,0.4f)" :one-liner t)
                          (ffi:c-inline (v) (:float) :float "powf(fmaxf(#0,0.0f),0.15f)" :one-liner t))
                       (* w (f-sin (* 3.1415927f0 u)))))
               (hw (/ (* hw (/ (- el pp) el)) sl))
               (heat (+ 0.2f0 (* 0.8f0 u)))
               (mx (- px (* hw sx))) (my (- py (* hw sy))) (mz (- pz (* hw sz)))
               (nx (+ px (* hw sx))) (ny (+ py (* hw sy))) (nz (+ pz (* hw sz))))
          (declare (single-float u v px py pz tx ty tz ex ey ez el pp sx sy sz sl hw heat mx my mz nx ny nz))
          (when (> i 0)
            (vtx lx ly lz -1f0 0f0 lh seed wob pk) (vtx rx ry rz 1f0 0f0 lh seed wob pk) (vtx nx ny nz 1f0 0f0 heat seed wob pk)
            (vtx lx ly lz -1f0 0f0 lh seed wob pk) (vtx nx ny nz 1f0 0f0 heat seed wob pk) (vtx mx my mz -1f0 0f0 heat seed wob pk))
          (setf lx mx ly my lz mz rx nx ry ny rz nz lh heat)))))
  nil)

(defun-fast %fx-wall (xs zs n scallops)
  (declare (type f32vec xs zs) (fixnum n scallops))
  (let* ((a *tn-args*) (height (aref a 0)) (wob (aref a 1)) (seed (aref a 2)) (pk (toon-a (aref a 3) (aref a 4)))
         (sd (- -1f0 (f-abs seed)))                     ; negative: an along shape
         (cols (* 6 (max 1 scallops))) (inv (/ 1f0 (i->f cols)))   ; 6 columns a tongue: tips and valleys on columns
         (lx 0f0) (lz 0f0) (lh 0f0) (lv 0f0) (v 0f0))
    (declare (type f32vec a) (single-float height wob seed sd pk inv lx lz lh lv v) (fixnum cols))
    (when (>= n 2)
      (with-fx-verts (d o :toon (* 6 cols))
        (dotimes (c (1+ cols))
          (let* ((p (* (i->f (1- n)) inv (i->f c))) (seg (min (- n 2) (f->i p))) (f (- p (i->f seg)))
                 (x (+ (aref xs seg) (* f (- (aref xs (1+ seg)) (aref xs seg)))))
                 (z (+ (aref zs seg) (* f (- (aref zs (1+ seg)) (aref zs seg)))))
                 (u (* inv (i->f c))) (m (- (* 2f0 u) 1f0))
                 (q (* (i->f scallops) u)) (j (min (1- scallops) (f->i q)))  ; the tongue this column is in
                 (tri (- 1f0 (f-abs (- (* 2f0 (- q (i->f j))) 1f0))))       ; 0 valley .. 1 tip
                 (tip (* tri (f-sqrt tri)))                                  ; ^1.5: pointed tips, round valleys
                 (h (* height (- 1f0 (* 0.4f0 m m)) (f-min 1f0 (* 5f0 (f-min u (- 1f0 u))))
                       (+ 0.45f0 (* 0.55f0 tip (+ 0.75f0 (* 0.25f0 (%h01 (i->f j) seed))))))))
            (declare (fixnum seg j) (single-float p f x z u m q tri tip h))
            (when (> c 0)                              ; uv.y = 0.8 x the distance along the wall (the noise's second axis)
              (setf v (+ lv (* 0.8f0 (f-sqrt (+ (* (- x lx) (- x lx)) (* (- z lz) (- z lz)))))))
              (vtx lx 0.02f0 lz 0f0 lv 1f0 sd wob pk) (vtx x 0.02f0 z 0f0 v 1f0 sd wob pk) (vtx x h z 1f0 v 0.2f0 sd wob pk)
              (vtx lx 0.02f0 lz 0f0 lv 1f0 sd wob pk) (vtx x h z 1f0 v 0.2f0 sd wob pk) (vtx lx lh lz 1f0 lv 0.2f0 sd wob pk))
            (setf lx x lz z lh h lv v))))))
  nil)

;;; ---------------------------------------------------------------- screen punctuation (UI layer, 0 B per call)
;;; Manga screen effects drawn into the UI batch; DRAWING is the drawing number (a new one reshuffles the
;;; lines: pass the fx clock's drawings, e.g. (floor (* 12 (fx-clock))), so they change on twos).
(defun-fast ui-focus-lines (cx cy n rmin rmax col drawing)
  "Focus lines: N thin wedges from RMAX (off screen) pointing at (CX CY), their tips at RMIN (hashed
+-25 %), hashed angles and widths per DRAWING. COL = (r g b a)."
  (declare (single-float cx cy rmin rmax) (fixnum n drawing))
  (let* ((seed (* 0.37f0 (i->f drawing))) (tau 6.2831855f0) (nf (i->f (max 1 n))))
    (declare (single-float seed tau nf))
    (%col-floats (r g b al) col
      (with-ui-verts (d o (* 3 n))
        (dotimes (i n)
          (let* ((f (i->f i)) (ang (* tau (/ (+ f (* 0.8f0 (- (%h01 f seed) 0.5f0))) nf)))
                 (r0 (* rmin (+ 0.75f0 (* 0.5f0 (%h01 (+ f 1.7f0) seed)))))
                 (w (* rmax (+ 0.003f0 (* 0.011f0 (%h01 (+ f 4.1f0) seed)))))
                 (c (f-cos ang)) (s (f-sin ang)))
            (declare (single-float f ang r0 w c s))
            (uvtx (+ cx (* r0 c)) (+ cy (* r0 s)) r g b al)
            (uvtx (- (+ cx (* rmax c)) (* w s)) (+ cy (* rmax s) (* w c)) r g b al)
            (uvtx (+ cx (* rmax c) (* w s)) (- (+ cy (* rmax s)) (* w c)) r g b al))))))
  nil)

(defun-fast ui-speed-lines (dir n col drawing)
  "Speed lines: N long thin wedges across the screen parallel to the screen angle DIR (radians, 0 =
pointing right, heads toward +DIR), hashed positions and lengths per DRAWING. COL = (r g b a)."
  (declare (single-float dir) (fixnum n drawing))
  (let* ((w (i->f (window-width))) (h (i->f (window-height))) (c (f-cos dir)) (s (f-sin dir))
         (diag (f-sqrt (+ (* w w) (* h h)))) (px (/ h 720f0)) (seed (* 0.53f0 (i->f drawing))))
    (declare (single-float w h c s diag px seed))
    (%col-floats (r g b al) col
      (with-ui-verts (d o (* 3 n))
        (dotimes (i n)
          (let* ((f (i->f i)) (off (* diag (- (%h01 f seed) 0.5f0))) (along (* 0.6f0 diag (- (%h01 (+ f 2.3f0) seed) 0.5f0)))
                 (hl (* 0.5f0 diag (+ 0.15f0 (* 0.3f0 (%h01 (+ f 5.9f0) seed)))))
                 (wd (* px (+ 1.5f0 (* 4f0 (%h01 (+ f 8.3f0) seed)))))
                 (mx (- (+ (* 0.5f0 w) (* along c)) (* off s))) (my (+ (* 0.5f0 h) (* along s) (* off c))))
            (declare (single-float f off along hl wd mx my))
            (uvtx (- mx (* hl c)) (- my (* hl s)) r g b al)
            (uvtx (- (+ mx (* hl c)) (* wd s)) (+ my (* hl s) (* wd c)) r g b al)
            (uvtx (+ mx (* hl c) (* wd s)) (- (+ my (* hl s)) (* wd c)) r g b al))))))
  nil)

(defun-fast ui-ink-splash (cx cy rad seed col drawing)
  "An ink splash (Kubo's title-page splash) centred at (CX CY), radius RAD px: a main blob (a 14-gon of
hashed radius), 5-9 thin spikes and 6-12 satellite droplets along them, all hashed from SEED. It grows
over DRAWING 0 (x0.6) and holds from drawing 1. COL = (r g b a): black on white cards, white on black."
  (declare (single-float cx cy rad seed) (fixnum drawing))
  (let* ((rad (* rad (if (< drawing 1) 0.6f0 1f0))) (tau 6.2831855f0)
         (ns (+ 5 (f->i (* 4.99f0 (%h01 1.3f0 seed))))) (nd (+ 6 (f->i (* 6.99f0 (%h01 2.9f0 seed)))))
         (lx 0f0) (ly 0f0))
    (declare (single-float rad tau lx ly) (fixnum ns nd))
    (%col-floats (r g b al) col
      (with-ui-verts (d o (+ 42 (* 3 ns) (* 18 nd)))
        (dotimes (j 15)                                   ; the blob
          (let* ((jj (mod j 14)) (f (i->f jj)) (ang (* tau (/ f 14f0)))
                 (rr (* rad (+ 0.7f0 (* 0.45f0 (%h01 f seed)))))
                 (x (+ cx (* rr (f-cos ang)))) (y (+ cy (* rr (f-sin ang)))))
            (declare (fixnum jj) (single-float f ang rr x y))
            (when (> j 0) (uvtx cx cy r g b al) (uvtx lx ly r g b al) (uvtx x y r g b al))
            (setf lx x ly y)))
        (dotimes (j ns)                                   ; spikes
          (let* ((f (i->f j)) (ang (* tau (+ (/ f (i->f ns)) (* 0.1f0 (%h01 (+ f 11f0) seed)))))
                 (c (f-cos ang)) (s (f-sin ang)) (w (* rad (+ 0.05f0 (* 0.06f0 (%h01 (+ f 13f0) seed)))))
                 (l (* rad (+ 1.3f0 (* 0.9f0 (%h01 (+ f 17f0) seed))))) (bb (* 0.6f0 rad)))
            (declare (single-float f ang c s w l bb))
            (uvtx (- (+ cx (* bb c)) (* w s)) (+ cy (* bb s) (* w c)) r g b al)
            (uvtx (+ cx (* bb c) (* w s)) (- (+ cy (* bb s)) (* w c)) r g b al)
            (uvtx (+ cx (* l c)) (+ cy (* l s)) r g b al)))
        (dotimes (j nd)                                   ; droplets: hexagons out along the spikes
          (let* ((f (i->f j)) (sp (f->i (* (i->f ns) (%h01 (+ f 23f0) seed))))
                 (ang (* tau (+ (/ (i->f sp) (i->f ns)) (* 0.1f0 (%h01 (+ (i->f sp) 11f0) seed)) (* 0.04f0 (- (%h01 (+ f 29f0) seed) 0.5f0)))))
                 (dist (* rad (+ 1.4f0 (* 1.1f0 (%h01 (+ f 31f0) seed)))))
                 (dr (* rad (+ 0.03f0 (* 0.07f0 (%h01 (+ f 37f0) seed)))))
                 (ox (+ cx (* dist (f-cos ang)))) (oy (+ cy (* dist (f-sin ang)))) (qx 0f0) (qy 0f0))
            (declare (fixnum sp) (single-float f ang dist dr ox oy qx qy))
            (dotimes (q 7)
              (let* ((qa (* tau (/ (i->f (mod q 6)) 6f0))) (x (+ ox (* dr (f-cos qa)))) (y (+ oy (* dr (f-sin qa)))))
                (declare (single-float qa x y))
                (when (> q 0) (uvtx ox oy r g b al) (uvtx qx qy r g b al) (uvtx x y r g b al))
                (setf qx x qy y))))))))
  nil)

(defun-fast %fx-disc ()
  (let* ((a *tn-args*) (x (aref a 0)) (y (aref a 1)) (z (aref a 2)) (r (aref a 3)) (wob (aref a 4)) (seed (aref a 5))
         (pk (toon-a (aref a 6) (aref a 7))) (push (if (< (aref a 8) 0f0) (* 0.8f0 r) (aref a 8)))
         (rt (camera-right *camera*)) (up (camera-upv *camera*)))
    (declare (type f32vec a rt up) (single-float x y z r wob seed pk push))
    (%toward-eye (x y z sc) push
      (let* ((r (* r sc)) (sx (* r (aref rt 0))) (sy (* r (aref rt 1))) (sz (* r (aref rt 2)))
             (vx (* r (aref up 0))) (vy (* r (aref up 1))) (vz (* r (aref up 2))))
        (declare (single-float r sx sy sz vx vy vz))
        (with-fx-verts (d o :toon 6)
          (%bb-verts x y z sx sy sz vx vy vz 1f0 seed wob pk)))))
  nil)
