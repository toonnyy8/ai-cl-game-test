;;;; player.lisp — REN (GAME_DESIGN §2–3): reading input into the buffer, the state machine and
;;;; move set logic (moves.lisp has the frame data), defense (guard / parry / dodge / just dodge),
;;;; Raven gauge & form, Obliterate, taking hits. PLAYER-SYSTEM runs once per fixed 60 Hz step
;;;; (main.lisp); K = frames this step (player time scale, 1.0 unless slow-mo).
(in-package :raven)

(declaim (type fixnum *ptick*))
(defvar *ptick* 0
  "Input-buffer clock: player time in 1/16 frames. Advances by 16 x the player's slow-mo scale per
sim step (SIM-STEP) and stops during hitstop, so buffered presses survive slow-mo and hit freezes.")

(defun pl () "REN's player component." (player *player*))
(defun raven-form-p () (let ((s (pl))) (and s (player-raven-form s))))

(defun raven-gain (n &optional source)
  "Add N to the Raven gauge (0..100). Nothing is gained in Raven Form except from Obliterate."
  (let ((s (pl)))
    (setf (player-raven s) (f32 (raven-gauge-after (player-raven s) n (player-raven-form s) source)))))

(defun orb-absorbed (kind)
  "An essence orb reached REN: gold fills the gauge, blue heals."
  (let ((e *player*))
    (when (alive-p e)
      (if (eq kind :gold)
          (raven-gain 5)
          (let ((h (health e))) (setf (health-hp h) (f32 (min (health-max-hp h) (+ (health-hp h) 4))))))
      (fx-burst +p-glow+ 3 (aref *orb-target* 0) (aref *orb-target* 1) (aref *orb-target* 2) 0f0 0f0 0f0 1f0 0.5f0 1.5f0
                0.25f0 0.12f0 (if (eq kind :gold) 1f0 0.25f0) (if (eq kind :gold) 0.76f0 0.66f0)
                (if (eq kind :gold) 0.24f0 1f0)))))

;;; ---------------------------------------------------------------- input
(defun trigger-pressed (now prev thr) (and (>= now thr) (< prev thr)))

(defun player-read-input ()
  "Stamp presses into the buffer (per render frame) and compute the camera-relative stick."
  (let* ((s (pl)) (tk *ptick*) (lt (pad-lt)) (rt (pad-rt)))
    (when (or (key-pressed :j) (mouse-pressed :left) (pad-pressed :x)) (setf (player-press-light s) tk))
    (when (or (key-pressed :k) (mouse-pressed :right) (pad-pressed :y)) (setf (player-press-heavy s) tk))
    (when (or (key-pressed :space) (pad-pressed :a)) (setf (player-press-jump s) tk))
    (when (or (key-pressed :lshift) (key-pressed :rshift) (key-pressed :l) (pad-pressed :b)) (setf (player-press-dodge s) tk))
    (when (or (key-pressed :e) (trigger-pressed lt (player-prev-lt s) 0.5)) (setf (player-press-raven s) tk))
    (when (or (key-pressed :q) (trigger-pressed rt (player-prev-rt s) 0.35))
      (setf (player-guard-press s) (if (< (- tk (player-guard-last s)) (* 16 20)) -1000 tk)   ; anti-mash: 20 frames (*PTICK* = 1/16 frame)
            (player-guard-last s) tk))
    (setf (player-prev-lt s) lt (player-prev-rt s) rt)
    (let* ((kx (+ (if (key-down :d) 1.0 0.0) (if (key-down :a) -1.0 0.0)))
           (ky (+ (if (key-down :w) 1.0 0.0) (if (key-down :s) -1.0 0.0)))
           (keys (or (/= kx 0) (/= ky 0)))
           (mx (+ kx (pad-lx))) (my (+ ky (pad-ly)))
           (m (hypot mx my))
           (cy (cam-yaw *cam*)))
      (if (< m 0.05)
          (clear-stick s)
          (let* ((ux (/ mx m)) (uy (/ my m))
                 (dx (+ (* uy (- (sin cy))) (* ux (cos cy))))
                 (dz (+ (* uy (- (cos cy))) (* ux (- (sin cy))))))
            (setf (player-stick-x s) (f32 dx) (player-stick-z s) (f32 dz)
                  (player-stick-mag s) (f32 (if keys 1.0 (min 1.0 m)))
                  (player-stick-on s) (or keys (> m 0.3))))))))

(defun clear-stick (s)
  (setf (player-stick-x s) 0f0 (player-stick-z s) 0f0 (player-stick-mag s) 0f0 (player-stick-on s) nil))

(defun press-tick (button)
  (let ((s (pl)))
    (ecase button
      (:light (player-press-light s)) (:heavy (player-press-heavy s))
      (:jump (player-press-jump s)) (:dodge (player-press-dodge s)))))

(defun buffered-p (button)
  "BUTTON (:light :heavy :jump :dodge) was pressed within the last *INPUT-BUFFER* player frames."
  (<= (- *ptick* (press-tick button)) (* 16 *input-buffer*)))

(defun consume (button)
  (let ((s (pl)))
    (ecase button
      (:light (setf (player-press-light s) -100000)) (:heavy (setf (player-press-heavy s) -100000))
      (:jump (setf (player-press-jump s) -100000)) (:dodge (setf (player-press-dodge s) -100000)))))

(defun raven-pressed-p () (<= (- *ptick* (player-press-raven (pl))) (* 16 *input-buffer*)))
(defun guard-held-p () (or (key-down :q) (> (pad-rt) 0.35)))
(defun heavy-held-p () (or (key-down :k) (mouse-down :right) (pad-down :y)))

(defun take-action (&key (dodge t) (jump t) (heavy t) (light t))
  "Consume the highest-priority buffered action allowed now (ACTION-PRIORITY: dodge > jump > heavy > light)."
  (let ((act (action-priority (and dodge (buffered-p :dodge)) (and jump (buffered-p :jump))
                              (and heavy (buffered-p :heavy)) (and light (buffered-p :light)))))
    (when act (consume act))
    act))

(defun input-dir (e)
  "Values dx dz has-input: stick/keys direction, or facing."
  (let ((s (pl)))
    (if (player-stick-on s)
        (values (player-stick-x s) (player-stick-z s) t)
        (values (fwd-x (yaw-of e)) (fwd-z (yaw-of e)) nil))))

;;; ---------------------------------------------------------------- state helpers
(defun pl-set-state (e st &optional clip (blend 4f0) (speed 1f0))
  (let ((f (fighter e)))
    (unless (eq (fighter-state f) st) (clog "REN ~a -> ~a" (fighter-state f) st))
    (setf (fighter-state f) st (fighter-sf f) 0f0 (fighter-phase f) 0))
  (when clip (play-clip e clip :blend blend :speed speed)))

(defun pl-to-idle (e) (pl-set-state e :idle :idle 6f0) (setf (motion-grav (motion e)) 1f0))
(defun pl-to-air (e)
  (pl-set-state e :air :fall 6f0)
  (let ((mo (motion e))) (unless (> (motion-grav-t mo) 0) (setf (motion-grav mo) 1f0))))

(defun player-invulnerable-p ()
  (let* ((e *player*) (f (fighter e)) (st (fighter-state f)) (sf (fighter-sf f)) (mv (fighter-move f)))
    (or (not (alive-p e)) (> (health-invuln (health e)) 0)
        (and (eq st :dodge) (player-dodge-iframes (pl)) (>= sf 1) (<= sf *dodge-iframes*))
        (and (eq st :air-dodge) (player-dodge-iframes (pl)) (>= sf 1) (<= sf 10))
        (and (eq st :move) mv (<= (mv-inv-from mv) sf) (<= sf (mv-inv-to mv)))
        (and (eq st :knockdown) (or (>= (fighter-phase f) 1) (>= sf 12))))))

(defun just-dodge-window-p ()
  "Player in dodge f1-10 with the just-dodge cooldown ready: enemy volumes test a hurt radius
inflated by *JUST-DODGE-REACH* so rolling away from a swing still counts as a near miss."
  (let* ((f (fighter *player*)) (sf (fighter-sf f)))
    (and (member (fighter-state f) '(:dodge :air-dodge)) (>= sf 1) (<= sf *just-dodge-window*) (<= (player-jd-cd (pl)) 0))))

(defun player-guarding-p ()
  (let ((f (fighter *player*)))
    (and (member (fighter-state f) '(:guard :parry)) (or (eq (fighter-state f) :parry) (>= (fighter-sf f) 2)))))

(defun attacks-paused-p ()
  "Enemies may not START attack windups now (§4.6 pause rule)."
  (let* ((f (fighter *player*)) (mv (and f (fighter-move f))))
    (and f (or (and (eq (fighter-state f) :move) mv
                    (or (member (mv-special mv) '(:obliterate :thunderfall))
                        (and (eq (mv-special mv) :raven-burst) (< (fighter-sf f) (mv-s mv)))))
               (and (eq (fighter-state f) :knockdown) (= (fighter-phase f) 2))))))

(defun player-punishable-p ()
  "Player in >= 14 f of recovery (heavies, enders, whiffed Kestrel)."
  (let* ((f (fighter *player*)) (mv (and f (fighter-move f))))
    (and f mv (eq (fighter-state f) :move) (>= (mv-r mv) 14) (>= (fighter-sf f) (+ (mv-s mv) (mv-a mv)))
         (or (not (eq (mv-name mv) :kestrel)) (not (fighter-landed f))))))

(defun vel-toward (v tx tz rate)
  "Accelerate the horizontal velocity V toward (TX TZ) by at most RATE m/s."
  (let* ((ddx (- tx (aref v 0))) (ddz (- tz (aref v 2))) (dl (hypot ddx ddz)))
    (if (<= dl rate)
        (setf (aref v 0) (f32 tx) (aref v 2) (f32 tz))
        (setf (aref v 0) (f32 (+ (aref v 0) (* rate (/ ddx dl)))) (aref v 2) (f32 (+ (aref v 2) (* rate (/ ddz dl))))))))

;;; ---------------------------------------------------------------- locomotion
(defun pl-locomotion (e k)
  (let* ((s (pl)) (f (fighter e)) (v (motion-vel (motion e))) (dt (* k +step+)) (m (player-stick-mag s))
         (spd (cond ((< m 0.05) 0.0) ((< m 0.5) *walk-speed*) (t *run-speed*)))
         (tx (* (player-stick-x s) spd)) (tz (* (player-stick-z s) spd))
         (cur (sqrt (+ (expt (aref v 0) 2) (expt (aref v 2) 2))))
         (rate (* dt (if (> spd cur) *accel* *decel*))))
    (vel-toward v tx tz rate)
    (when (> m 0.05)
      (setf (transform-yaw (transform e))
            (turn-toward (yaw-of e) (yaw-to (player-stick-x s) (player-stick-z s)) (* *turn-rate* dt))))
    (let ((speed (sqrt (+ (expt (aref v 0) 2) (expt (aref v 2) 2)))))
      (if (> speed 6.0) (incf (player-run-t s) dt) (setf (player-run-t s) 0f0))
      (cond ((> speed 0.8)
             (unless (eq (fighter-state f) :run) (setf (fighter-state f) :run))
             (play-clip e (if (> speed 4.0) :run :walk) :blend 6f0 :restart nil
                        :speed (if (> speed 4.0) (/ speed *run-speed*) (/ speed *walk-speed*)))
             (when (> speed 4.0)
               (decf (player-step-t s) dt)
               (when (<= (player-step-t s) 0)
                 (setf (player-step-t s) 0.25)
                 (play-sfx :footstep :gain 0.7))))
            (t (unless (eq (fighter-state f) :idle) (setf (fighter-state f) :idle))
               (setf (player-step-t s) 0.1)
               (play-clip e :idle :blend 8f0 :restart nil))))))

(defun pl-air-control (e k)
  (let* ((s (pl)) (v (motion-vel (motion e))) (dt (* k +step+)))
    (when (player-stick-on s)
      (vel-toward v (* (player-stick-x s) *run-speed*) (* (player-stick-z s) *run-speed*) (* *air-accel* dt))
      (setf (transform-yaw (transform e))
            (turn-toward (yaw-of e) (yaw-to (player-stick-x s) (player-stick-z s)) (* *air-turn* dt))))))

(defun pl-jump (e vy &optional (clip :jump-up))
  (let ((mo (motion e)) (s (pl)))
    (setf (motion-grounded mo) nil (aref (motion-vel mo) 1) (f32 vy) (motion-grav mo) 1f0 (motion-grav-t mo) 0f0
          (player-air-cuts s) 0 (player-air-dodge s) nil))
  (pl-set-state e :air clip 3f0)
  (play-sfx :jump))

;;; ---------------------------------------------------------------- attacks
(defun obliterate-target (e)
  "Crippled enemy <= 3 m within 100 deg of stick/facing, else the nearest crippled one <= 3 m."
  (when (motion-grounded (motion e))
    (multiple-value-bind (dx dz) (input-dir e)
      (or (pick-target e dx dz t :range 3.0 :half 100.0 :pred #'crippled-p)
          (pick-target e dx dz t :range 3.0 :half 180.0 :pred #'crippled-p)))))

(defun pl-attack (e name &key chain)
  "Start player move NAME with soft-lock (snap + magnetism)."
  (let* ((s (pl)) (f (fighter e)) (mv (find-move name)))
    (unless chain (incf (player-string-id s)))
    (multiple-value-bind (dx dz has) (input-dir e)
      (let ((tg (if (eq (mv-special mv) :mirage) (player-jd-attacker s) (pick-target e dx dz has))))
        (setf (fighter-target f) tg (player-mag-frames s) 0f0)
        (cond (tg (face-toward e tg)) (has (setf (transform-yaw (transform e)) (yaw-to dx dz))))
        (when (and tg (> (mv-magnet mv) 0) (> (mv-s mv) 0))
          (let* ((want (- (distance e tg) (- (mv-reach mv) 0.3))))
            (when (> want 0)
              (setf (player-mag-frames s) (f32 (mv-s mv))
                    (player-mag-step s) (f32 (/ (min want (mv-magnet mv)) (mv-s mv)))))))))
    (let* ((mo (motion e)) (v (motion-vel mo)))
      (if (mv-air mv)
          (setf (aref v 0) (* 0.3 (aref v 0)) (aref v 2) (* 0.3 (aref v 2)))
          (setf (aref v 0) 0f0 (aref v 2) 0f0))
      (when (mv-hang mv)
        (setf (aref v 1) (f32 (max (aref v 1) 0.5)) (motion-grav mo) 0.25 (motion-grav-t mo) 0f0)))
    (start-move e mv)))

(defun pl-heavy (e &key chain (next :h1))
  "Heavy input: Obliterate beats any heavy; Raven Form turns neutral heavies into Crimson Lance."
  (let ((ct (obliterate-target e)))
    (cond (ct (pl-start-obliterate e ct))
          ((and (raven-form-p) (not chain)) (pl-attack e :crimson-lance))
          (next (pl-attack e next :chain chain)))))

(defun pl-air-heavy (e)
  "Air heavy priority: Thunderfall > Kestrel > Plunge."
  (multiple-value-bind (dx dz has) (input-dir e)
    (let ((grab (pick-target e dx dz has :range 2.6 :half 180.0
                             :pred (lambda (o) (and (not (motion-grounded (motion o))) (not (body-grab-immune (body-of o)))
                                                    (not (member (state-of o) '(:grabbed :spawn)))
                                                    (<= (health-invuln (health o)) 0))))))
      (if grab
          (pl-start-thunderfall e grab)
          (let ((kt (pick-target e dx dz has :range 9.0 :half 45.0
                                 :pred (lambda (o) (>= (distance e o) 2.5)))))
            (if kt
                (progn (pl-attack e :kestrel) (setf (fighter-target (fighter e)) kt) (face-toward e kt))
                (pl-attack e :plunge)))))))

(defun pl-try-raven (e)
  "E: Raven Burst with gauge >= 40, or end Raven Form. Returns T if it acted."
  (when (raven-pressed-p)
    (let ((s (pl)))
      (setf (player-press-raven s) -100000)
      (cond ((player-raven-form s) (raven-form-end) t)
            ((>= (player-raven s) *raven-threshold*)          ; Raven Burst enters Raven Form
             (pl-attack e :raven-burst)
             (setf (player-raven-form s) t (player-fov-punch s) 0.4)
             (play-sfx :raven-burst)
             (clog "REN RAVEN FORM gauge ~,1f" (player-raven s))
             t)))))

(defun raven-form-end ()
  (setf (player-raven-form (pl)) nil)
  (play-sfx :raven-burst :pitch 0.7 :gain 0.5)
  (clog "REN raven form END gauge ~,1f" (player-raven (pl))))

(defun pl-try-counter (e)
  "Mirage Counter (just-dodge window) or Riposte (after parry) on J/K. Returns T if started."
  (let* ((s (pl)) (jd (player-jd-attacker s)))
    (when (or (buffered-p :light) (buffered-p :heavy))
      (cond ((and (<= *tick* (player-jd-until s)) (alive-p jd) (<= (distance e jd) 6.0))
             (consume :light) (consume :heavy) (setf (player-jd-until s) -1000)
             (pl-attack e :mirage) t)
            ((<= *tick* (player-riposte-until s))
             (consume :light) (consume :heavy) (setf (player-riposte-until s) -1000)
             (pl-attack e :riposte) t)))))

;;; ---------------------------------------------------------------- dodge
(defun pl-start-dodge (e)
  (let* ((s (pl)) (mo (motion e)) (air (not (motion-grounded mo))))
    (multiple-value-bind (dx dz has) (input-dir e)
      (when (and air (player-air-dodge s)) (return-from pl-start-dodge nil))
      (setf (player-dodge-iframes s) (> (- *tick* (player-dodge-end s)) 9))      ; 0.15 s anti roll-spam
      (let* ((back (not has)) (ddx (if back (- dx) dx)) (ddz (if back (- dz) dz)) (kb (motion-kb mo)))
        (setf (aref kb 0) (f32 ddx) (aref kb 2) (f32 ddz) (motion-kb-left mo) 0f0)
        (unless back (setf (transform-yaw (transform e)) (yaw-to ddx ddz)))
        (cond (air (setf (player-air-dodge s) t (aref (motion-vel mo) 1) 0f0 (motion-grav mo) 0f0)
                   (pl-set-state e :air-dodge :air-dash 2f0))
              (t (pl-set-state e :dodge (if back :dodge-back :dodge-roll) 2f0)))
        (play-sfx :dodge)
        t))))

(defun pl-dodge (e k)
  "Ground roll: 18 m/s for 12 f, then linear decel over 9 f (5 m / 21 f). Cancels from f17."
  (let* ((f (fighter e)) (mo (motion e)) (sf (+ (fighter-sf f) k)) (v (motion-vel mo)) (kb (motion-kb mo))
         (spd (dodge-speed sf)))
    (setf (fighter-sf f) (f32 sf) (aref v 0) (f32 (* spd (aref kb 0))) (aref v 2) (f32 (* spd (aref kb 2))))
    (cond ((pl-try-counter e))
          ((>= sf 17)
           (let ((act (take-action :jump nil)))
             (case act
               (:dodge (pl-end-dodge e) (pl-start-dodge e))
               (:heavy (pl-end-dodge e) (pl-heavy e))
               (:light (pl-end-dodge e) (pl-attack e :l1))
               (t (cond ((guard-held-p) (pl-end-dodge e) (pl-start-guard e))
                        ((>= sf 21) (pl-end-dodge e) (pl-to-idle e))))))))))

(defun pl-end-dodge (e)
  (let ((v (motion-vel (motion e))))
    (setf (player-dodge-end (pl)) *tick* (aref v 0) (* 0.3 (aref v 0)) (aref v 2) (* 0.3 (aref v 2)))))

(defun pl-air-dodge-tick (e k)
  "Air dash: 3.5 m in 15 f, no gravity, i-frames f1-10."
  (let* ((f (fighter e)) (mo (motion e)) (sf (+ (fighter-sf f) k)) (v (motion-vel mo)) (kb (motion-kb mo)))
    (setf (fighter-sf f) (f32 sf) (aref v 0) (f32 (* 14.0 (aref kb 0))) (aref v 2) (f32 (* 14.0 (aref kb 2)))
          (aref v 1) 0f0 (motion-grav mo) 0f0)
    (cond ((pl-try-counter e))
          ((>= sf 15) (pl-end-dodge e) (setf (motion-grav mo) 1f0) (pl-to-air e)))))

;;; ---------------------------------------------------------------- guard / parry
(defun pl-start-guard (e)
  (let ((v (motion-vel (motion e)))) (setf (aref v 0) 0f0 (aref v 2) 0f0))
  (pl-set-state e :guard :guard 3f0))

(defun pl-guard (e k)
  (let* ((s (pl)) (f (fighter e)) (v (motion-vel (motion e)))
         (tg (pick-target e (fwd-x (yaw-of e)) (fwd-z (yaw-of e)) nil :range 12.0 :half 180.0)))
    (setf (fighter-sf f) (+ (fighter-sf f) k))
    (setf (aref v 0) (* (player-stick-x s) (player-stick-mag s) 2.2) (aref v 2) (* (player-stick-z s) (player-stick-mag s) 2.2))
    (if tg
        (face-toward e tg)
        (setf (transform-yaw (transform e)) (turn-toward (yaw-of e) (cam-yaw *cam*) (* *turn-rate* k +step+))))
    (cond ((pl-try-counter e))
          ((pl-try-raven e))
          ((not (guard-held-p)) (setf (aref v 0) 0f0 (aref v 2) 0f0) (pl-to-idle e))
          (t (let ((act (take-action)))
               (case act
                 (:dodge (pl-start-dodge e))
                 (:jump (pl-jump e *jump-vy*))
                 (:heavy (pl-heavy e))
                 (:light (pl-attack e :l1))))))))

(defun pl-parry-state (e k)
  (let ((f (fighter e)))
    (setf (fighter-sf f) (+ (fighter-sf f) k))
    (cond ((pl-try-counter e))
          ((>= (fighter-sf f) 15) (if (guard-held-p) (pl-set-state e :guard :guard 4f0) (pl-to-idle e))))))

;;; ---------------------------------------------------------------- generic move tick (with cancels)
(defun pl-move (e k)
  (let* ((s (pl)) (mv (fighter-move (fighter e))))
    (when (> (player-mag-frames s) 0)                      ; soft-lock magnetism during startup
      (let* ((tg (fighter-target (fighter e))) (step (* (player-mag-step s) (min k (player-mag-frames s)))))
        (decf (player-mag-frames s) k)
        (when (alive-p tg)
          (face-toward e tg)
          (let ((p (pos-of e)) (y (yaw-of e)))
            (setf (aref p 0) (f32 (+ (aref p 0) (* step (fwd-x y)))) (aref p 2) (f32 (+ (aref p 2) (* step (fwd-z y)))))))))
    (case (mv-special mv)
      (:thunderfall (pl-thunderfall e k))
      (:kestrel (pl-kestrel e k))
      (:plunge (pl-plunge e k))
      (:obliterate (pl-obliterate e k))
      (t (pl-generic-move e mv k)))))

(defun pl-generic-move (e mv k)
  (let* ((f (fighter e)) (mo (motion e))
         (f0 (fighter-sf f)) (done (move-tick e k)) (sf (fighter-sf f)) (aend (+ (mv-s mv) (mv-a mv))))
    (case (mv-special mv)
      (:mirage (pl-mirage-tick e f0 sf))
      (:raven-burst (pl-raven-burst-tick e f0 sf)))
    (when (and (mv-air mv) (motion-grounded mo) (> sf 2))  ; air move lands: cancel to landing
      (pl-land e) (return-from pl-generic-move))
    (multiple-value-bind (dodge-ok jump-ok heavy-ok light-ok)
        ;; OBLITERATE-TARGET scans the enemies: only ask when it can matter (heavy pressed, no heavy follow-up)
        (move-cancels mv sf (fighter-landed f)
                      (and (not (mv-heavy mv)) (not (mv-air mv)) (buffered-p :heavy) (obliterate-target e) t))
      (let ((act (take-action :dodge dodge-ok :jump jump-ok :heavy heavy-ok :light light-ok)))
        (cond
          ((eq act :dodge) (pl-start-dodge e))
          ((eq act :jump) (pl-chase-jump e))
          ((and (numberp (mv-jump mv)) (< f0 (mv-jump mv)) (>= sf (mv-jump mv)) (heavy-held-p)) (pl-chase-jump e))
          ((eq act :heavy) (if (mv-air mv) (pl-air-heavy e) (pl-heavy e :chain t :next (mv-heavy mv))))
          ((eq act :light) (pl-attack e (mv-light mv) :chain t))
          ((and (guard-held-p) (>= sf (+ aend 4)) (not (mv-air mv))) (pl-start-guard e))
          ((and (>= sf aend) (pl-try-raven e)))
          (done (setf (motion-grav mo) 1f0)
                (if (motion-grounded mo) (pl-to-idle e) (pl-to-air e))))))))

(defun pl-chase-jump (e)
  "Jump cancel (Rising Crow chase jump vy 11.5 facing the target; L5/H3 on-hit jump)."
  (let* ((f (fighter e)) (crow (eq (mv-name (fighter-move f)) :rising-crow)) (tg (fighter-target f)))
    (when (and crow (alive-p tg)) (face-toward e tg))
    (pl-jump e (if crow 11.5 *jump-vy*) (if crow :chase-jump :jump-up))
    (clog "REN chase jump")))

;;; ---------------------------------------------------------------- specials
(defun pl-raven-burst-tick (e f0 sf)
  (when (and (< f0 6) (>= sf 6))
    (slowmo 0.4 0.25) (shake 0.18 0.30)
    (let ((p (pos-of e)))
      (fx-ring (aref p 0) 0.2 (aref p 2) 0.5 4.5 0.35 1.0 0.12 0.24 :flat t :width 0.18)
      (fx-burst +p-feather+ 30 (aref p 0) 1.2f0 (aref p 2) 0f0 0.5f0 0f0 1f0 3f0 7f0 1.2f0 0.12f0 0.05f0 0.02f0 0.04f0)))
  (let ((mo (motion e)))
    (unless (motion-grounded mo) (setf (aref (motion-vel mo) 1) 0f0 (motion-grav mo) 0f0))))

(defun pl-warp-front (e tg dist sf)
  "Frames 0-6 of Mirage / Obliterate: close in to DIST m in front of TG (on E's side), facing it."
  (let* ((p (pos-of e)) (q (pos-of tg)) (u (min 1.0 (/ sf 6.0)))
         (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2))) (d (max 0.01 (hypot dx dz))))
    (setf (aref p 0) (f32 (lerp (aref p 0) (+ (aref q 0) (* dist (/ dx d))) u))
          (aref p 2) (f32 (lerp (aref p 2) (+ (aref q 2) (* dist (/ dz d))) u)))
    (face-toward e tg)))

(defun pl-mirage-tick (e f0 sf)
  "f0-6: vanish and warp to 1.0 m in front of the attacker; then strike."
  (let ((tg (fighter-target (fighter e))) (p (pos-of e)) (m (model e)))
    (when (and (entity-alive-p tg) (< f0 6))
      (pl-warp-front e tg 1.0 sf)
      (setf (model-hidden m) (if (< sf 6) #x1FFFFF 0))
      (fx-burst +p-glow+ 2 (aref p 0) 1.1f0 (aref p 2) 0f0 0f0 0f0 0.5f0 0f0 0.5f0 0.3f0 0.25f0 0.62f0 0.78f0 1f0))
    (when (>= sf 6) (setf (model-hidden m) 0))))

(defun pl-set-anim-time (e tm)
  (let ((an (model-anim (model e)))) (setf (anim-time an) (f32 tm) (anim-speed an) 0f0)))

(defun pl-start-thunderfall (e tg)
  (let ((ft (fighter tg)))
    (setf (player-grab (pl)) tg (fighter-grabbed ft) t (fighter-state ft) :grabbed))
  (token-release tg)
  (play-clip tg :launched :blend 2f0)
  (pl-attack e :thunderfall)
  (setf (fighter-target (fighter e)) tg)
  (face-toward e tg)
  (play-sfx :jump :pitch 0.8)
  (clog "REN THUNDERFALL grab ~a" (name-of tg)))

(defun pl-hold-grab (e tg fwd up)
  (let* ((p (pos-of e)) (q (pos-of tg)) (y (yaw-of e)) (mo (motion tg)))
    (setf (aref q 0) (f32 (+ (aref p 0) (* fwd (fwd-x y)))) (aref q 2) (f32 (+ (aref p 2) (* fwd (fwd-z y))))
          (aref q 1) (f32 (max 0.0 (+ (aref p 1) up))) (transform-yaw (transform tg)) (f32 (+ y pi))
          (aref (motion-vel mo) 1) 0f0 (motion-kb-left mo) 0f0)))

(defun pl-thunderfall (e k)
  "f0-6 grab, f6-27 rise 1.5 m spinning 720 deg, head-down dive at 18 m/s, impact, 12 f recovery."
  (let* ((f (fighter e)) (mo (motion e)) (tg (player-grab (pl))) (tg (and (entity-alive-p tg) tg))
         (f0 (fighter-sf f)) (sf (+ f0 k)) (v (motion-vel mo)))
    (setf (fighter-sf f) (f32 sf) (aref v 0) 0f0 (aref v 2) 0f0 (motion-grav mo) 0f0)
    (case (fighter-phase f)
      (0 (setf (aref v 1) (if (< sf 6) 0f0 (/ 1.5 (/ 21 60.0))))
         (when (>= sf 6) (setf (transform-yaw (transform e)) (f32 (+ (yaw-of e) (* k (/ (* 4 pi) 21))))))
         (pl-set-anim-time e (* 0.45 (/ (min sf 27) 27.0)))
         (when tg (pl-hold-grab e tg (if (< sf 6) (- 1.8 (* 0.8 (/ sf 6))) 1.0) (if (< sf 6) 0.0 0.3)))
         (when (>= sf 27) (setf (fighter-phase f) 1)))
      (1 (setf (aref v 1) -18f0)
         (pl-set-anim-time e (min 0.64 (+ 0.45 (* 0.01 (- sf 27)))))
         (when tg (pl-hold-grab e tg 0.8 -0.9))
         (when (motion-grounded mo) (pl-thunderfall-impact e tg)))
      (t (pl-set-anim-time e (+ 0.66 (/ (fighter-sf f) 60.0)))
         (when (>= (fighter-sf f) 12) (setf (motion-grav mo) 1f0) (pl-to-idle e))))))

(defun pl-thunderfall-impact (e tg)
  (let ((p (pos-of e)) (f (fighter e)))
    (setf (fighter-phase f) 2 (fighter-sf f) 0f0 (health-invuln (health e)) 24f0 (player-grab (pl)) nil)
    (when (alive-p tg)
      (let ((ft (fighter tg)))
        (setf (fighter-grabbed ft) nil (fighter-state ft) :launched (motion-grounded (motion tg)) t))
      (pl-hold-grab e tg 1.0 0.0)
      (setf (aref (pos-of tg) 1) 0f0)
      (resolve-hit e tg *hd-tf-target*))
    (setf (svref (fighter-hit-log f) 11) (if tg (list tg) nil))   ; the AoE spares the grabbed one
    (hitdef-scan e *hd-tf-aoe* 11)
    (shake 0.2 0.35)
    (fx-dust (aref p 0) (aref p 2) 30)
    (fx-ring (aref p 0) 0.0 (aref p 2) 0.3 3.2 0.35 0.9 0.8 0.7 :flat t :width 0.12)
    (play-sfx :hit-heavy) (play-sfx :land)
    (clog "REN THUNDERFALL impact")))

(defun pl-kestrel (e k)
  "Jump slash: S6 hover, fly at 24 m/s to 1.2 m in front of the target (<= 22 f), R16."
  (let* ((f (fighter e)) (mo (motion e)) (mv (fighter-move f)) (tg (fighter-target f)) (v (motion-vel mo))
         (f0 (fighter-sf f)))
    (move-tick e k)
    (let ((sf (fighter-sf f)))
      (cond ((< sf 6) (setf (aref v 0) 0f0 (aref v 1) 0f0 (aref v 2) 0f0 (motion-grav mo) 0f0))
            ((< f0 28)
             (when (< f0 6) (play-clip e :kestrel-loop :blend 2f0))
             (let* ((p (pos-of e))
                    (arrived
                      (if (alive-p tg)
                          (let* ((q (pos-of tg)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
                                 (dy (- (aref q 1) (aref p 1)))
                                 (d (hypot dx dz)) (rem (- d 1.2)))
                            (face-toward e tg)
                            (if (<= rem (* 0.4 k))
                                t
                                (let ((sc (/ 24.0 (max d 0.01))))
                                  (setf (aref v 0) (f32 (* dx sc)) (aref v 2) (f32 (* dz sc))
                                        (aref v 1) (f32 (clamp (* 4.0 dy) -12.0 12.0)))
                                  nil)))
                          t)))
               (when (or arrived (>= sf 28))
                 (when (and arrived tg) (hitdef-scan e (svref (mv-hits mv) 0) 0))
                 (setf (fighter-sf f) 28f0 (aref v 0) 0f0 (aref v 2) 0f0 (aref v 1) 0f0 (motion-grav mo) 1f0)
                 (play-clip e :kestrel-end :blend 1f0))))
            (t (setf (aref v 0) (* 0.8 (aref v 0)) (aref v 2) (* 0.8 (aref v 2)) (motion-grav mo) 1f0)
               (when (>= sf (+ (mv-s mv) (mv-a mv) (mv-r mv)))
                 (if (motion-grounded mo) (pl-to-idle e) (pl-to-air e))))))))

(defun pl-plunge (e k)
  "S6 hover, fall at 22 m/s hitting below, landing shock r 2.5, R20 (dodge-cancel from +8)."
  (let* ((f (fighter e)) (mo (motion e)) (tr (blade-trail e)) (v (motion-vel mo)) (sf (+ (fighter-sf f) k)))
    (setf (fighter-sf f) (f32 sf) (aref v 0) 0f0 (aref v 2) 0f0)
    (case (fighter-phase f)
      (0 (setf (aref v 1) 0f0 (motion-grav mo) 0f0)
         (when (>= sf 6) (setf (fighter-phase f) 1) (play-clip e :plunge-loop :blend 2f0) (play-sfx :slash-heavy :pitch 0.8)))
      (1 (setf (aref v 1) -22f0 (motion-grav mo) 0f0 (blade-trail-on tr) 1f0)
         (hitdef-scan e *hd-plunge-fall* 10)
         (when (motion-grounded mo)
           (let ((p (pos-of e)))
             (setf (fighter-phase f) 2 (fighter-sf f) 0f0 (motion-grav mo) 1f0 (blade-trail-on tr) 0f0)
             (play-clip e :plunge-land :blend 0f0)
             (hitdef-scan e *hd-plunge-shock* 11)
             (shake 0.2 0.35) (fx-dust (aref p 0) (aref p 2) 30)
             (fx-ring (aref p 0) 0.0 (aref p 2) 0.3 2.7 0.3 0.9 0.8 0.7 :flat t :width 0.1)
             (play-sfx :land) (play-sfx :hit-heavy :gain 0.7))))
      (t (cond ((and (>= sf 8) (buffered-p :dodge)) (consume :dodge) (pl-start-dodge e))
               ((>= sf 20) (pl-to-idle e)))))))

(defun pl-start-obliterate (e tg)
  (setf (fighter-state (fighter tg)) :grabbed)
  (token-release tg)
  (pl-attack e :obliterate :chain t)
  (setf (fighter-target (fighter e)) tg (player-mag-frames (pl)) 0f0)
  (play-sfx :obliterate)
  (clog "REN OBLITERATE ~a" (name-of tg)))

(defun pl-obliterate (e k)
  "f0-6 warp to 1.2 m in front, f15 cut (bisect, 12 f hitstop, enemies 0.25x for 0.4 s), 45 f."
  (let* ((f (fighter e)) (tr (blade-trail e)) (tg (fighter-target f)) (f0 (fighter-sf f)) (sf (+ f0 k)))
    (setf (fighter-sf f) (f32 sf) (blade-trail-on tr) (if (and (>= sf 13) (< sf 20)) 1f0 0f0) (blade-trail-heavy tr) t)
    (when (and (entity-alive-p tg) (< f0 6)) (pl-warp-front e tg 1.2 sf))
    (when (and (< f0 15) (>= sf 15))
      (when (alive-p tg)
        (play-sfx :slash-heavy)
        (resolve-hit e tg *hd-oblit*)
        (slowmo 0.25 0.4 t) (shake 0.15 0.25)
        (raven-gain (if (raven-form-p) 10 25) :obliterate)
        (let ((h (health e))) (setf (health-hp h) (f32 (min (health-max-hp h) (health-hp h)))))))
    (when (>= sf 45)
      (setf (health-invuln (health e)) 12f0 (fighter-target f) nil)
      (pl-to-idle e))))

;;; ---------------------------------------------------------------- landing / air / hurt states
(defun pl-land (e)
  (let* ((mo (motion e)) (v (motion-vel mo)) (long (> (motion-air-t mo) 0.8)) (s (pl)))
    (when (> (motion-air-t mo) 0.3) (play-sfx :land :gain 0.8))
    (setf (player-air-cuts s) 0 (player-air-dodge s) nil (motion-grav mo) 1f0
          (aref v 0) (* 0.3 (aref v 0)) (aref v 2) (* 0.3 (aref v 2)))
    (pl-set-state e :land :land 2f0)
    (setf (fighter-stun (fighter e)) (if long 10f0 4f0))))

(defun pl-air (e k)
  (let* ((f (fighter e)) (s (pl)))
    (setf (fighter-sf f) (+ (fighter-sf f) k))
    (pl-air-control e k)
    (when (and (< (aref (motion-vel (motion e)) 1) 0)
               (member (clip-name (anim-clip (model-anim (model e)))) '(:jump-up :chase-jump)))
      (play-clip e :fall :blend 10f0))
    (cond ((pl-try-counter e))
          ((pl-try-raven e))
          (t (let ((act (take-action :jump nil :dodge (not (player-air-dodge s)) :light (< (player-air-cuts s) 3))))
               (case act
                 (:dodge (pl-start-dodge e))
                 (:heavy (pl-air-heavy e))
                 (:light (incf (player-air-cuts s))
                  (pl-attack e (case (player-air-cuts s) (1 :al1) (2 :al2) (t :al3))
                             :chain (> (player-air-cuts s) 1)))))))))

(defun pl-land-state (e k)
  (let ((f (fighter e)))
    (setf (fighter-sf f) (+ (fighter-sf f) k))
    (when (>= (fighter-sf f) (fighter-stun f)) (pl-to-idle e))))

(defun pl-hurt-tick (e k)
  "flinch 15 f / stagger 30 f / guard break 60 f, then post-hit invulnerability."
  (let ((f (fighter e)))
    (setf (fighter-sf f) (+ (fighter-sf f) k))
    (when (>= (fighter-sf f) (fighter-stun f))
      (case (fighter-state f)
        (:flinch (setf (health-invuln (health e)) 10f0))
        (:stagger (setf (health-invuln (health e)) 15f0))
        (:guard-break (setf (player-guard-meter (pl)) 100f0)))
      (pl-to-idle e))))

(defun pl-knockdown (e k)
  "0.35 s airborne back 3 m -> 0.5 s down (tech roll: dodge within 9 f) -> 0.4 s getup."
  (let ((f (fighter e)) (mo (motion e)))
    (setf (fighter-sf f) (+ (fighter-sf f) k))
    (case (fighter-phase f)
      (0 (when (and (motion-grounded mo) (> (fighter-sf f) 3))
           (setf (fighter-phase f) 1 (fighter-sf f) 0f0 (aref (motion-vel mo) 0) 0f0 (aref (motion-vel mo) 2) 0f0)
           (play-clip e :kd-down :blend 3f0) (fx-dust-at e 8)))
      (1 (cond ((and (< (fighter-sf f) 9) (buffered-p :dodge))
                (consume :dodge) (clog "REN tech roll") (pl-start-dodge e))
               ((>= (fighter-sf f) 30) (setf (fighter-phase f) 2 (fighter-sf f) 0f0) (play-clip e :kd-getup :blend 2f0))))
      (t (when (>= (fighter-sf f) 24) (pl-to-idle e))))))

(defun pl-hurt (e kind att)
  "Enter a hit reaction (§3.5) pushed away from ATT."
  (let* ((s (pl)) (f (fighter e)) (mo (motion e)) (v (motion-vel mo))
         (p (pos-of e)) (q (pos-of att)) (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2)))
         (grab (player-grab s)))
    (setf (fighter-move f) nil (player-mag-frames s) 0f0 (motion-grav mo) 1f0 (model-hidden (model e)) 0)
    (when grab
      (when (entity-alive-p grab) (setf (fighter-grabbed (fighter grab)) nil) (enemy-to-idle grab))
      (setf (player-grab s) nil))
    (setf (aref v 0) 0f0 (aref v 2) 0f0)
    (ecase kind
      (:flinch (pl-set-state e :flinch :hurt-flinch 2f0) (setf (fighter-stun f) 15f0) (set-kb e dx dz 0.5))
      (:stagger (pl-set-state e :stagger :hurt-stagger 2f0) (setf (fighter-stun f) 30f0) (set-kb e dx dz 1.2))
      (:guard-break (pl-set-state e :guard-break :guard-break 2f0) (setf (fighter-stun f) 60f0) (set-kb e dx dz 0.4)
       (shake 0.12 0.25) (play-sfx :clang :gain 2.0))
      (:knockdown
       (pl-set-state e :knockdown :kd-air 2f0)
       (let ((l (max 0.01 (hypot dx dz))))
         (setf (motion-grounded mo) nil (aref v 1) 4.9f0
               (aref v 0) (f32 (* 8.57 (/ dx l))) (aref v 2) (f32 (* 8.57 (/ dz l)))))
       (face-toward e att)))))

;;; ---------------------------------------------------------------- being hit (called by combat)
(defun pl-just-dodge (att)
  "A near miss while rolling: slow-mo for the enemies, gauge +8, Mirage Counter ready for 36 f."
  (let ((s (pl)) (p (pos-of *player*)))
    (setf (player-jd-cd s) 0.8 (player-jd-until s) (+ *tick* 36) (player-jd-attacker s) att)
    (raven-gain 8)
    (emit :just-dodge (aref p 0) (aref p 2))
    (clog "REN JUST DODGE vs ~a" (name-of att))))

(defun pl-parry (att hd)
  "Guard pressed just in time: the attacker staggers (not for projectiles), Riposte ready for 30 f."
  (let* ((e *player*) (s (pl)) (hp (hit-point! e att)))
    (emit :parried (aref hp 0) (aref hp 1) (aref hp 2))
    (raven-gain 8)
    (unless (member :ranged (hd-flags hd))
      (enemy-react att :stagger :stun (if (eq (kind-of att) :enra) 36 60)))
    (setf (player-riposte-until s) (+ *tick* 30))
    (pl-set-state e :parry :parry 1f0)
    (clog "REN PARRY vs ~a" (name-of att))))

(defun player-take-hit (att hd)
  "Enemy hit HD from ATT reaches REN: the rule (PLAYER-HIT-OUTCOME, rules.lisp) decides between
just dodge, i-frames, anti-juggle, Raven Guard, parry, block and damage; this applies and shows it.
Returns :dodged :blocked :parried :hit or NIL."
  (let* ((e *player*) (s (pl)) (h (health e)) (amv (fighter-move (fighter att)))
         (out (player-hit-outcome
               hd :red (or (and amv (mv-red amv)) (and (member :unblockable (hd-flags hd)) t))
                  :just-dodge (just-dodge-window-p) :invulnerable (player-invulnerable-p)
                  :tick *tick* :last-hurt (player-last-hurt s) :prev-hurt (player-prev-hurt s)
                  :guarding (and (player-guarding-p) (facing-p e att 90.0))
                  :raven-form (player-raven-form s) :raven (player-raven s)
                  :guard-age (floor (- *ptick* (player-guard-press s)) 16) :parry-window *parry-window*
                  :guard-meter (player-guard-meter s) :guard-cost-mult *guard-cost-mult*
                  :dmg-mult *enemy-dmg-mult* :hp (health-hp h))))
    (ecase (ph-result out)
      (:just-dodge (pl-just-dodge att) :dodged)
      (:dodged :dodged)
      ((nil) nil)                                          ; anti-juggle: 2 damaging hits / 1.0 s
      (:raven-guard
       (decf (player-raven s) 15f0)
       (emit-block att e)
       (clog "REN RAVEN GUARD")
       :blocked)
      (:parried (pl-parry att hd) :parried)
      (:blocked
       (setf (player-guard-meter s) (f32 (ph-guard-meter out)) (player-guard-idle s) 0f0)
       (emit-block att e)
       (let ((p (pos-of e)) (q (pos-of att)))
         (set-kb e (- (aref p 0) (aref q 0)) (- (aref p 2) (aref q 2)) 0.4))
       (setf (fighter-sf (fighter e)) 2f0)
       (play-clip e :block-hit :blend 1f0)
       (clog "REN blocked ~a meter ~,1f" (name-of att) (player-guard-meter s))
       (when (ph-guard-broken out)
         (pl-hurt e :guard-break att)
         (clog "REN GUARD BREAK"))
       :blocked)
      (:hit
       (let* ((dmg (ph-damage out)) (hp (hit-point! att e)) (ay (yaw-of att)))
         (setf (health-hp h) (f32 (ph-hp out))
               (player-prev-hurt s) (player-last-hurt s) (player-last-hurt s) *tick*
               (player-damage-taken s) (+ (player-damage-taken s) dmg))
         (emit :player-hurt (aref hp 0) (aref hp 1) (aref hp 2) (fwd-x ay) (fwd-z ay) (ph-heavy out) (ph-hitstop out))
         (clog "REN HURT by ~a dmg ~,1f hp ~,1f" (name-of att) dmg (health-hp h))
         (if (eq (ph-reaction out) :dead)
             (player-die e att)
             (pl-hurt e (ph-reaction out) att)))
       :hit))))

(defun player-die (e att)
  (pl-hurt e :knockdown att)
  (setf (fighter-state (fighter e)) :dead (health-alive (health e)) nil
        (player-dead-t (pl)) 0f0 (player-raven-form (pl)) nil)
  (play-clip e :death :blend 4f0)
  (emit :player-died)
  (clog "REN DIED"))

(defun player-landed-hit (hw)
  "Gauge for a player hit that connected (§3.3). The combo counter counts the :HIT events."
  (let* ((mv (fighter-move (fighter *player*))) (nm (and mv (mv-name mv))))
    (raven-gain (landed-hit-gain nm hw))))

;;; ---------------------------------------------------------------- the per-step system
(defun player-system (k)
  "One fixed step of REN (K = time-scaled frames)."
  (do-entities (e player) (player-tick e k)))

(defun player-tick (e k)
  (let* ((s (pl)) (f (fighter e)) (h (health e)) (mo (motion e)) (dt (* k +step+)))
    (when (> (health-invuln h) 0) (countdown! (health-invuln h) k))
    (countdown! (player-jd-cd s) dt)
    ;; guard meter regen after 0.8 s without blocking
    (incf (player-guard-idle s) dt)
    (when (and (> (player-guard-idle s) 0.8) (< (player-guard-meter s) 100) (not (eq (fighter-state f) :guard-break)))
      (setf (player-guard-meter s) (f32 (min 100.0 (+ (player-guard-meter s) (* *guard-regen* dt))))))
    ;; raven gauge
    (cond ((player-raven-form s)
           (countdown! (player-raven s) (* *raven-drain* dt))
           (when (<= (player-raven s) 0) (raven-form-end)))
          ((health-alive h) (raven-gain dt)))
    (case (fighter-state f)
      ((:idle :run) (pl-ground e k))
      (:air (pl-air e k))
      (:land (pl-land-state e k))
      (:move (pl-move e k))
      (:dodge (pl-dodge e k))
      (:air-dodge (pl-air-dodge-tick e k))
      (:guard (pl-guard e k))
      (:parry (pl-parry-state e k))
      ((:flinch :stagger :guard-break) (pl-hurt-tick e k))
      (:knockdown (pl-knockdown e k))
      (:dead (pl-dead-tick e k)))
    (let ((was-air (not (motion-grounded mo))))
      (physics-step e k *gravity*)
      (when (and was-air (motion-grounded mo) (eq (fighter-state f) :air)) (pl-land e)))
    (when (and (member (fighter-state f) '(:idle :run)) (not (motion-grounded mo))) (pl-to-air e))
    (anim-advance (model-anim (model e)) dt)
    (pose-update e)
    (trail-step e)))

(defun pl-ground (e k)
  (cond ((pl-try-counter e))
        ((pl-try-raven e))
        (t (let ((act (take-action)))
             (case act
               (:dodge (pl-start-dodge e))
               (:jump (pl-jump e *jump-vy*))
               (:heavy (pl-heavy e))
               (:light (pl-attack e (if (>= (player-run-t (pl)) 0.35) :gale-thrust :l1)))
               (t (if (guard-held-p) (pl-start-guard e) (pl-locomotion e k))))))))

(defun pl-dead-tick (e k)
  (let ((s (pl)) (mo (motion e)))
    (incf (player-dead-t s) (* k +step+))
    (when (motion-grounded mo) (setf (aref (motion-vel mo) 0) 0f0 (aref (motion-vel mo) 2) 0f0))
    (when (>= (player-dead-t s) 3.0) (player-respawn e))))

(defun player-respawn (e)
  "Training: back on your feet after 3 s (in a run, death leads to GAME OVER instead)."
  (let ((h (health e)))
    (setf (health-alive h) t (health-hp h) (health-max-hp h) (health-invuln h) 120f0 (motion-grounded (motion e)) t)
    (fill (motion-vel (motion e)) 0f0)
    (pl-to-idle e)
    (clog "REN respawn")))

;;; ---------------------------------------------------------------- per-frame (real time)
(defun player-frame-update (dt)
  "Real-time bits: combo timer, HP damage trail, feathers, FOV punch, orb target."
  (let* ((e *player*) (s (pl)) (p (pos-of e)) (hp (health-hp (health e))))
    (when (> (player-combo-t s) 0) (countdown! (player-combo-t s) dt)
      (when (<= (player-combo-t s) 0) (setf (player-combo s) 0)))
    (progn (countdown! (player-combo-punch s) dt)
           (countdown! (player-fov-punch s) dt))
    (if (> (player-hp-trail s) hp)
        (if (> (player-hp-hold s) 0)
            (setf (player-hp-hold s) (f32 (- (player-hp-hold s) dt)))
            (setf (player-hp-trail s) (f32 (max hp (- (player-hp-trail s) (* 60 dt))))))
        (setf (player-hp-trail s) hp (player-hp-hold s) 0.5))
    (v3-set! *orb-target* (aref p 0) (+ (aref p 1) 1.2f0) (aref p 2))
    (when (player-raven-form s)
      (decf (player-feather-t s) dt)
      (when (<= (player-feather-t s) 0)
        (setf (player-feather-t s) 0.125)
        (fx-emit +p-feather+ (+ (aref p 0) (rnd-range -0.6f0 0.6f0)) (+ (aref p 1) (rnd-range 0.6f0 1.9f0))
                 (+ (aref p 2) (rnd-range -0.6f0 0.6f0)) (rnd-range -0.5f0 0.5f0) (rnd-range 0.2f0 0.8f0)
                 (rnd-range -0.5f0 0.5f0) 1.4f0 0.1f0 0.6f0 0.05f0 0.02f0 0.04f0)))))

(defun player-init (x z yaw)
  "Spawn REN at (X, 0, Z) facing YAW with fresh stats; point the camera behind him."
  (let ((e (spawn-fighter :ren :x x :z z :yaw yaw :team :player)))
    (add-component e (make-player :hp-trail (f32 *player-max-hp*)))
    (let ((h (health e))) (setf (health-hp h) (f32 *player-max-hp*) (health-max-hp h) (f32 *player-max-hp*)))
    (setf *player* e)
    (let ((c *cam*)) (setf (cam-yaw c) (f32 yaw) (cam-pivot-x c) (f32 x) (cam-pivot-y c) 1.5 (cam-pivot-z c) (f32 z)))
    e))
