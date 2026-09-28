;;;; hazards.lisp — every hit that isn't a fighter's melee is one HAZARD entity (design-v1 §12):
;;;;   :wave      the Signature flame wave: a moving oriented box (WIDTH wide), hits once
;;;;   :fireball  Shiranui: a homing sphere, swept from last step's position (no tunnelling)
;;;;   :pillars   Ennetsu Jigoku: a ring of *ENNETSU-PILLARS* cylinders around where it erupted
;;;;   :line      a ground line cut / crack: a look only (Kyokujitsujin, Buttagiru, the Meteor, South's crack)
;;;;   :bind      South: a disc at the feet (radius SIZE, height Y) that grabs once its DELAY runs out
;;;;   :freeze    Rukia's ice: the same disc (Tsukishiro's pillar, her quakes, the freeze-touch), out of reach of the
;;;;              projectile cut (a blade can't cut the ground it stands on)
;;;;   :hand      South: a skeleton's arm clawing out of the ground (transform + model), a look only
;;;;   :rift      NOMIHOSE's KUKAN-GIRI: the blade's chord left in the air (its hitwin's volume, in the frame the owner
;;;;              had at the cut, fixed in the world) that cuts once its DELAY runs out; closed if the owner is hit first
;;;; HAZARD-SYSTEM moves them (sim steps, SIM randomness only), COLLECT-HAZARD-HITS hands their hits to
;;;; combat.lisp's HIT-SYSTEM (applied with the fighters' hits), HAZARD-DRAW shows them (vfx.lisp
;;;; looks, real time). Hazards of one kind never hit their owner.
(in-package :duel)

(defun spawn-hazard (kind owner &key (x 0.0) (y 0.0) (z 0.0) (yaw 0.0) (speed 0.0) (turn 0.0) (size 0.5)
                                  (life 60) (delay 0) (hits 1) hw look src fragile hook data)
  "A new hazard of KIND for fighter OWNER. LIFE / DELAY in frames; HW = the HITWIN it deals (NIL = look only). SRC: its
hit comes from the owner's position; FRAGILE: it closes while it waits if the owner is hit (CLOSE-RIFTS). HOOK: a
character's function (h hz event &rest args) called with :step (each step, first: T skips the generic step), :close
(CLOSE-RIFTS closed it) and :touches (the volume test of a kind this file doesn't know); DATA: what it keeps."
  (spawn-entity (make-hazard :kind kind :owner owner :x (f32 x) :y (f32 y) :z (f32 z) :px (f32 x) :pz (f32 z)
                             :yaw (f32 yaw) :speed (f32 speed) :turn (f32 turn) :size (f32 size)
                             :life life :delay delay :hits-left (if hw hits 0) :hw hw :look look :src src :fragile fragile
                             :hook hook :data data)))

(defun clear-hazards ()
  (do-entities (h hazard) (destroy-entity h)))

(defun hazard-target (hz)
  "The fighter a hazard of HZ's owner can hit (his opponent), or NIL."
  (let ((o (hazard-owner hz))) (and (entity-alive-p o) (fighter-opp (fighter o)))))

;;; ---------------------------------------------------------------- South's hands (looks)
(defparameter *hand-life* 92 "Frames a South hand stays out: 8 rising to the grab, the 60 f hold, 24 crumbling.")

(defun spawn-hand (owner x z yaw delay)
  "A charred skeleton's arm (the :skeleton body, its hips under the plaza) that claws out at (X Z) after DELAY
frames, grabs at the ankles, holds and crumbles (:sk-grab): South's look; the :bind hazard is the hit."
  (let ((h (spawn-hazard :hand owner :x x :z z :yaw yaw :size 0.5 :life *hand-life* :delay (max 0 delay))))
    (add-component h (make-transform :yaw (f32 yaw)))
    (add-component h (make-model :body (find-body :skeleton)))
    (v3-set! (pos-of h) (f32 x) -5f0 (f32 z))            ; below the plaza until it appears
    h))

;;; ---------------------------------------------------------------- per step
(defun hazard-step (h hz)
  (let ((k (hazard-hook hz))) (when (and k (funcall k h hz :step)) (return-from hazard-step nil)))
  (when (> (hazard-delay hz) 0)
    (decf (hazard-delay hz))
    (when (and (zerop (hazard-delay hz)) (eq (hazard-kind hz) :hand))
      (v3-set! (pos-of h) (hazard-x hz) 0f0 (hazard-z hz))
      (play-clip h :sk-grab :blend 0)
      (emit :skeleton-rise (hazard-x hz) (hazard-z hz)))
    (when (and (zerop (hazard-delay hz)) (eq (hazard-kind hz) :rift))
      (emit :rift-cut (hazard-owner hz) (rift-mid-x hz) (rift-mid-z hz) (hazard-x hz) (hazard-z hz) (hazard-yaw hz)))   ; (+ its frame: the ink gash)
    (return-from hazard-step nil))
  (incf (hazard-age hz))
  (when (> (hazard-rehit hz) 0) (decf (hazard-rehit hz)))
  (setf (hazard-px hz) (hazard-x hz) (hazard-pz hz) (hazard-z hz))
  (case (hazard-kind hz)
    (:fireball                                          ; home on the target
     (let ((tg (hazard-target hz)))
       (when (entity-alive-p tg)
         (let ((q (pos-of tg)))
           (setf (hazard-yaw hz) (f32 (angle-wrap (turn-toward (hazard-yaw hz)
                                                          (dir-yaw (- (aref q 0) (hazard-x hz)) (- (aref q 2) (hazard-z hz)))
                                                          (hazard-turn hz)))))))))
    (:hand (anim-advance (model-anim (model h)) +step+)))
  (when (member (hazard-kind hz) '(:wave :fireball))
    (let ((d (* (hazard-speed hz) +step+)))
      (setf (hazard-x hz) (f32 (+ (hazard-x hz) (* d (fwd-x (hazard-yaw hz)))))
            (hazard-z hz) (f32 (+ (hazard-z hz) (* d (fwd-z (hazard-yaw hz))))))
      (when (> (+ (expt (hazard-x hz) 2) (expt (hazard-z hz) 2)) (expt (+ *arena-radius* 2.0) 2))
        (setf (hazard-age hz) (hazard-life hz)))))
  (when (>= (hazard-age hz) (hazard-life hz)) (destroy-entity h)))

(defun hazard-system ()
  "Move / age every hazard one fixed step."
  (do-entities (h (hz hazard)) (hazard-step h hz)))

;;; ---------------------------------------------------------------- volumes
(defun hazard-active-p (hz)
  (and (hazard-hw hz) (> (hazard-hits-left hz) 0) (<= (hazard-rehit hz) 0) (<= (hazard-delay hz) 0)
       (case (hazard-kind hz)
         (:pillars (< (first *pillar-window*) (hazard-age hz) (- (hazard-life hz) (second *pillar-window*))))
         (t t))))

(defun hazard-touches-p (hz tx ty tz tr th)
  "Does HZ's world volume touch the hurt cylinder at (TX TY TZ), radius TR, height TH?"
  (let ((x (hazard-x hz)) (y (hazard-y hz)) (z (hazard-z hz)) (s (hazard-size hz)) (tr (f32 tr)) (th (f32 th)))
    (case (hazard-kind hz)
      (:wave (obox-cyl-hit-p x 1f0 z (hazard-yaw hz) s (f32 (first *wave-box*)) (f32 (second *wave-box*)) tx ty tz tr th))
      (:fireball (capsule-cyl-hit-p (hazard-px hz) y (hazard-pz hz) x y z s tx ty tz tr th))
      (:pillars (let ((pr (f32 (first *pillar-size*))) (ph (f32 (second *pillar-size*))))
                  (loop for i below *ennetsu-pillars*
                        for a of-type single-float = (+ (* i (/ +two-pi+ *ennetsu-pillars*)) (hazard-yaw hz))
                        thereis (cyl-cyl-hit-p (+ x (* s (cos a))) 0f0 (+ z (* s (sin a))) pr ph tx ty tz tr th))))
      ((:bind :freeze) (cyl-cyl-hit-p x 0f0 z s y tx ty tz tr th))       ; the feet: a disc SIZE x Y
      (:rift (let ((yaw (hazard-yaw hz)))
               (vol-hit-p (first (hw-vols (hazard-hw hz))) x 0f0 z (f32 (fwd-x yaw)) (f32 (fwd-z yaw)) tx ty tz tr th 0f0)))
      (t (let ((k (hazard-hook hz))) (and k (funcall k nil hz :touches tx ty tz tr th)))))))

(defun rift-mid-x (hz) (f32 (+ (hazard-x hz) (* 2.7 (fwd-x (hazard-yaw hz))))))
(defun rift-mid-z (hz) (f32 (+ (hazard-z hz) (* 2.7 (fwd-z (hazard-yaw hz))))))

(defun close-rifts (e)
  "E was hit: his rifts (and fragile hazards: Tsukishiro's circle) that haven't cut yet close (KUKAN-GIRI's rift: a
parried or traded blade leaves none)."
  (do-entities (h (hz hazard))
    (when (and (or (eq (hazard-kind hz) :rift) (hazard-fragile hz)) (eql (hazard-owner hz) e) (> (hazard-delay hz) 0))
      (emit :rift-close (rift-mid-x hz) (rift-mid-z hz))
      (clog "~a RIFT CLOSED" (side-name e))
      (let ((k (hazard-hook hz))) (when k (funcall k h hz :close)))
      (destroy-entity h))))

(defun collect-hazard-hits ()
  "Hand every active hazard's contact with its target to the HIT-SYSTEM's pending list."
  (do-entities (h (hz hazard))
    (when (hazard-active-p hz)
      (let ((tg (hazard-target hz)))
        (when (entity-alive-p tg)
          (let ((q (pos-of tg)) (b (model-body (model tg))))
            (when (hazard-touches-p hz (aref q 0) (aref q 1) (aref q 2) (body-hurt-r b) (body-hurt-h b))
              (push (make-pending :att (hazard-owner hz) :def tg :hw (hazard-hw hz)
                                  :sx (if (hazard-src hz) (aref (pos-of (hazard-owner hz)) 0) (hazard-x hz))
                                  :sz (if (hazard-src hz) (aref (pos-of (hazard-owner hz)) 2) (hazard-z hz))
                                  :hazard hz :state (defender-state tg))
                    *pending*))))))))

(defun hazard-connected (hz)
  "HZ's hit took effect: one hit fewer (projectiles are spent), pillars wait before hitting again."
  (decf (hazard-hits-left hz))
  (setf (hazard-rehit hz) *hazard-rehit*)
  (when (and (<= (hazard-hits-left hz) 0) (member (hazard-kind hz) '(:wave :fireball)))
    (setf (hazard-life hz) (hazard-age hz))))            ; gone at the next step (its look fades)

(defun hazard-threat-p (owner victim)
  "Perfect Hoho vs hazards: one of OWNER's hazards is active (or becomes so within *PERFECT-LEAD*
frames) and touches VICTIM's hurt cylinder grown by *PERFECT-INFLATE*."
  (let ((q (pos-of victim)) (b (model-body (model victim))) (found nil))
    (do-entities (h (hz hazard))
      (when (and (not found) (eql (hazard-owner hz) owner) (hazard-hw hz) (> (hazard-hits-left hz) 0)
                 (<= (hazard-delay hz) *perfect-lead*)
                 (hazard-touches-p hz (aref q 0) (aref q 1) (aref q 2)
                                   (+ (body-hurt-r b) *perfect-inflate*) (+ (body-hurt-h b) *perfect-inflate*)))
        (setf found t)))
    found))

;;; ---------------------------------------------------------------- draw (real time)
(defun hazard-draw (rdt)
  "Every hazard's look this frame."
  (do-entities (h (hz hazard))
    (when (eq (hazard-kind hz) :rift)                    ; the rift shows while it waits (the tell), then cuts
      (let ((l (hazard-size hz)) (yaw (hazard-yaw hz)))
        (vfx-rift (+ (hazard-x hz) (* 1.0 (fwd-x yaw))) (+ (hazard-z hz) (* 1.0 (fwd-z yaw)))
                  (+ (hazard-x hz) (* l (fwd-x yaw))) (+ (hazard-z hz) (* l (fwd-z yaw))) (<= (hazard-delay hz) 0))))
    (if (and (hazard-look hz) (not (keywordp (hazard-look hz))))   ; a draw function (Rukia's ice): it draws its tell too
        (funcall (hazard-look hz) hz (f32 rdt))
    (when (<= (hazard-delay hz) 0)
      (let ((x (hazard-x hz)) (z (hazard-z hz)) (age (/ (hazard-age hz) 60.0)) (life (/ (hazard-life hz) 60.0)))
        (case (hazard-kind hz)
          (:wave (if (>= (hazard-age hz) (hazard-life hz))   ; spent by a hit (HAZARD-CONNECTED): it erodes where it hit
                     (wave-ghost-start x z (hazard-yaw hz) (* 2 (hazard-size hz)) age)
                     (vfx-fire-wave x z (hazard-yaw hz) age (* 2 (hazard-size hz)) rdt :life life)))   ; (its own light)
          (:fireball (vfx-fireball x (hazard-y hz) z (hazard-size hz) (fwd-x (hazard-yaw hz)) (fwd-z (hazard-yaw hz)) rdt))
          (:pillars (add-point-light x 1.5 z 1.0 0.45 0.12 7.0 (* 1.6 (min 1.0 (* 4.0 (/ (- life age) life)))) 4)   ; one light
                    (dotimes (i *ennetsu-pillars*)          ; for the ring (7 would wash the floor out)
                      (let ((a (+ (* i (/ +two-pi+ *ennetsu-pillars*)) (hazard-yaw hz))))
                        (vfx-fire-pillar (+ x (* (hazard-size hz) (cos a))) (+ z (* (hazard-size hz) (sin a))) age life rdt))))
          (:line (let ((l (hazard-size hz)) (yaw (hazard-yaw hz)))
                   (vfx-line-cut x z (+ x (* l (fwd-x yaw))) (+ z (* l (fwd-z yaw))) age life (hazard-look hz) :dt rdt)))
          (:hand
           (let ((m (model h)) (p (pos-of h)))
             (pose-fk! (model-joints m) (anim-eval (model-anim m)) (aref p 0) (aref p 1) (aref p 2)
                       (transform-yaw (transform h)) (body-scale (model-body m)) (body-hunch (model-body m)))
             (draw-body (model-body m) (model-joints m) (aref p 0) (aref p 1) (aref p 2) 0.0 :shadow nil   ; no disc: it hid the pale bones
                        :alpha (f32 (min 1.0 (max 0.0 (/ (- (hazard-life hz) (hazard-age hz)) 15.0)))))))
          ((:bind :rift :freeze) nil))))))                ; (their looks: the :south crack and the hands; VFX-RIFT)
  (wave-ghosts-draw (f32 rdt)))
