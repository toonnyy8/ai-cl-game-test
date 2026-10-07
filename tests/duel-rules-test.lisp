;;;; duel-rules-test.lisp — checks SOUL DUEL's pure rules (duel/lisp/rules.lisp) and its kit data
;;;; (kit.lisp + yama.lisp + ken.lisp) on the host, no browser, no build:
;;;;   $ECL_HOST --norc --load tests/duel-rules-test.lisp
;;;; The files are plain Common Lisp over the engine's plain-CL math, hit volumes and vpad, so they
;;;; load here after engine/lisp/{package,math,hitvol,input}.lisp.
(dolist (f '("package" "math" "hitvol" "input"))
  (load (merge-pathnames (format nil "../engine/lisp/~a.lisp" f) *load-truename*)))
(defpackage :duel (:use :cl :engine))
;; the character files also hold their hook functions and cinematics: those need the engine, so the
;; host skips the cinematics (a no-op DEFCINE) and never calls a hook
(defmacro duel::defcine (&rest r) (declare (ignore r)) nil)
(dolist (f '("tuning" "rules" "kit" "yama" "ken" "rukia" "ichigo" "endless-rules" "senjumaru" "lille"))
  (load (merge-pathnames (format nil "../duel/lisp/~a.lisp" f) *load-truename*)))
(in-package :duel)

(defvar *fails* 0)
(defvar *checks* 0)
(defmacro check (form)
  `(progn (incf *checks*) (unless ,form (incf *fails*) (format t "FAIL: ~s~%" ',form))))
(defun ~= (a b &optional (eps 1e-3)) (< (abs (- a b)) eps))
(defun kit (c f) (find-kit c f))
(defun mv (c f name) (kit-move (kit c f) name))
(defparameter *forms* '((:yamamoto :base) (:yamamoto :hellfire) (:yamamoto :bankai-east) (:yamamoto :bankai-west)
                        (:kenpachi :base) (:kenpachi :nozarashi) (:kenpachi :ryote) (:kenpachi :nomihose)
                        (:kenpachi :bankai) (:kenpachi :kataude)
                        (:rukia :base) (:rukia :m18) (:rukia :m50) (:rukia :zero) (:ichigo :base) (:ichigo :kessa)
                        (:senjumaru :base) (:senjumaru :tsuji1) (:senjumaru :tsuji2) (:senjumaru :tsuji3) (:senjumaru :tsuji4)
                        (:senjumaru :tsuji5) (:senjumaru :tsuji6)
                        (:lille :base) (:lille :jilliel) (:lille :jilliel-mujittai) (:lille :jilliel-kin)
                        (:lille :jilliel-kin-mujittai) (:lille :shin) (:lille :shin-mujittai) (:lille :shin-kin)
                        (:lille :shin-kin-mujittai)))
(defun owl-adv (cf)
  "The frame advantage CF's J / K add to DUEL_STRINGS's budget: the owl's *SHIN-ADV* (decision 36: each recovery 1 f
shorter, its :adv-block 1 higher), else 0."
  (if (and (eq (first cf) :lille) (lb-owl-form-p (second cf))) *shin-adv* 0))
(defun trace-form-p (cf)
  "Is CF a form whose J / K strings lay traces instead of hitting (Lille's JILLIEL EN, DUEL_LILLE §22.2): its J1 has no hit
window? The hit-based string checks skip it (its own block below checks its frames)."
  (zerop (length (mv-hits (kit-command-move (apply #'kit cf) :q)))))

;;; ================================================================ the triangle / clash matrix
(check (eq (resolve-contact :neutral) :hit))
(check (eq (resolve-contact :guard) :blocked))                            ; guard > attack
(check (eq (resolve-contact :guard :in-front nil) :hit))                  ; ... only from the front
(check (eq (resolve-contact :guard :breaker t) :guard-break))             ; breaker > guard
(check (eq (resolve-contact :guard :guard-crush t) :guard-break))         ; crushing stance / SP2 hold
(check (eq (resolve-contact :breaker) :counter))                          ; attack > breaker
(check (eq (resolve-contact :neutral :breaker t) :hit))                   ; 150 + knockback
(check (eq (resolve-contact :stance) :absorbed))                          ; super armour, stores
(check (eq (resolve-contact :stance :breaker t) :stance-break))           ; breaker breaks the stance
(check (eq (resolve-contact :stance-in) :counter))
(check (eq (resolve-contact :stance-in :breaker t) :stance-break))
(check (null (resolve-contact :invuln :breaker t)))
;; Bankai West's ward (the rework, the user's decisions 2026-09-27): the defender reports :guard (DEFENDER-STATE); the
;; ward covers 360 deg (a hit from behind is blocked), a Breaker / guard-crush breaks it, an unguardable (the bind, a red
;; victim's Kikon follow-up) goes through, a hazard in the parry's window is blocked (a plain parry lets it hit), a
;; melee hit in the window is parried, iframes still dodge
(check (and (eq (resolve-contact :guard :in-front nil :ward t) :blocked) (eq (resolve-contact :guard :in-front nil) :hit)
            (eq (resolve-contact :guard :hazard t :in-front nil :ward t) :blocked)
            (eq (resolve-contact :guard :breaker t :in-front nil :ward t) :guard-break)
            (eq (resolve-contact :guard :guard-crush t :ward t) :guard-break)
            (eq (resolve-contact :guard :unguardable t :ward t) :hit)
            (eq (resolve-contact :parry :hazard t :ward t) :blocked) (eq (resolve-contact :parry :hazard t) :hit)
            (eq (resolve-contact :parry :ward t) :parried) (eq (resolve-contact :parry :unguardable t :ward t) :hit)
            (null (resolve-contact :invuln :ward t))))
;; the melee / ranged split (the user's decision 2026-09-26): the Meteor's cleaver within 3.4 m, the cash-out's within
;; 3.9 m, Buttagiru's within 2.6 m, Nadegiri's within 2.4 m are melee; beyond, the line. (They were the J1 reaches of their
;; forms until the J cut of 2026-09-29, docs/duel/DUEL_STRINGS.md §13: an SP's own blade, so they stay)
(check (and (ranged-hit-p t nil nil 0.0) (not (ranged-hit-p nil nil nil 100.0)) (ranged-hit-p nil '(:ranged) nil 1.0)
            (not (ranged-hit-p nil '(:ranged) 3.4 (* 3.4 3.4))) (ranged-hit-p nil '(:ranged) 3.4 (* 3.5 3.5))))
(flet ((mr (name) (getf (mv-params (find-move name)) :melee-range)))
  (check (and (~= (mr :ke-meteor) 3.4) (~= (mr :ke-meteor-n) 3.9) (~= (mr :ke-buttagiru) 2.6) (~= (mr :ya-nadegiri) 2.4)
              (null (mr :ya-kyoku)) (null (mr :ya-taimatsu))
              (= 1 (length (mv-hits (find-move :ke-meteor-n)))) (= 1 (length (mv-hits (find-move :ke-meteor)))))))
;; the contact rule: only a real hit is a hit for the attacker (armour, absorb, parry, block are :block)
(check (every (lambda (r) (eq (contact-of r) :hit)) '(:hit :counter :guard-break :stance-break :kikon)))
(check (every (lambda (r) (eq (contact-of r) :block)) '(:blocked :armored :absorbed :parried)))
(check (null (contact-of nil)))
(check (not (chain-open-p 12 9 3 12 (contact-of :armored))))            ; armour never opens hit timing
(check (breaker-clash-p :dash :strike 2.5))
(check (not (breaker-clash-p :dash :aura 1.0)))
(check (not (breaker-clash-p :dash :dash 3.5)))
;; the Breaker's pre-strike phases
(check (and (eq (breaker-next-phase :aura 11 t 9.0) :aura) (eq (breaker-next-phase :aura 12 t 9.0) :dash)))
(check (eq (breaker-next-phase :dash 20 t 9.0) :dash))
(check (eq (breaker-next-phase :dash 1 t 0.9) :strike))                   ; in range
(check (eq (breaker-next-phase :dash 5 nil 9.0) :dash))                   ; a tap still dashes a bit
(check (eq (breaker-next-phase :dash 12 nil 9.0) :strike))
(check (eq (breaker-next-phase :dash 45 t 9.0) :strike))
(check (and (~= (breaker-speed 0) 9.0) (~= (breaker-speed 45) 10.0)))
(let ((b (mv :yamamoto :base :ya-breaker)))
  (check (and (= (mv-s b) 8) (= (mv-a b) 4) (= (mv-r b) 18) (= (mv-whiff b) 30) (= (mv-dmg b) 150)
              (eq (mv-adv-block b) :guard-break) (member :breaker (hw-flags (svref (mv-hits b) 0)))
              (~= (mv-track b) *track-breaker*) (= (hw-hs (svref (mv-hits b) 0)) 10))))
;; a Q1 thrown on seeing the aura beats the fastest Breaker (aura 12 + strike startup 8)
(check (< (mv-s (mv :yamamoto :base :ya-j1)) (+ *breaker-aura* *breaker-startup*)))
;; 防 > J > I > 防 (the user, 2026-09-29; docs/duel/DUEL_STRINGS.md §14): guard blocks J (above), a Breaker breaks the guard
;; (above), and J beats the grab: in every form with a Breaker its strike reaches less far than J1, and J1 has a press
;; window against the dash: the Breaker's aura, dash and strike startup are :breaker (any hit counters it), so J1 connects
;; when its last active frame meets the dash inside J1's reach + the thinnest hurt radius (0.34, Rukia's) and its first
;; active frame comes before the strike's (the dash stops at *BREAKER-TRIGGER*, then *BREAKER-STARTUP* frames). The dash
;; at its fastest (*BREAKER-SPEED-MAX*); the trigger clears the widest pair of hurt radii (0.9: both Kenpachi) and a
;; triggered strike reaches the thinnest
(check (and (> *breaker-trigger* 0.9) (> (+ *breaker-reach* 0.34) *breaker-trigger*)))
(dolist (cf *forms*)
  (let* ((k (apply #'kit cf)) (br (kit-command-move k :breaker)) (j1 (kit-command-move k :q)))
    (when br
      (let* ((v (/ *breaker-speed-max* 60.0)) (s (mv-s j1)) (a (mv-a j1))
             (d-hi (+ (mv-reach j1) 0.34 (* v (+ s a -1))))              ; the farthest press: its last active frame meets him
             (d-lo (+ *breaker-trigger* (* v (max 0 (- s (mv-s br)))))))  ; the nearest: J1 hits before the strike does
        (check (or (and (< (mv-reach br) (mv-reach j1)) (> (+ (mv-reach j1) 0.34) *breaker-trigger*) (< d-lo d-hi))
                   (format t "~a: grab ~,2f m, J1 ~,2f m S ~d, window ~,2f..~,2f m~%" cf (mv-reach br) (mv-reach j1) s d-lo d-hi)))))))

;;; ================================================================ block / whiff advantage
(check (= (blockstun 24 9 -2) 13))
(check (= (hitstun :flinch) 18))
(check (= (hitstun :stagger t) 36))                                     ; counter-hit +10
(check (= (recovery-frames 12 t) 12))
(check (= (recovery-frames 12 nil) 18))                                 ; whiff = R + 6
(check (= (recovery-frames 18 nil 30) 30))                              ; Breaker whiff 30
(check (and (chain-open-p 12 9 3 12 :hit) (not (chain-open-p 11 9 3 12 :hit))))
;; the contact gate (docs/duel/DUEL_STRINGS.md §2.2): a whiff never chains, at any frame
(check (loop for sf from 0 to 30 never (chain-open-p sf 9 3 12 nil)))
(check (and (chain-open-p 21 9 3 12 :block) (not (chain-open-p 20 9 3 12 :block))
            (not (chain-open-p 24 9 3 12 :block))))
;; the string gate (2026-09-28): a follow-up link (T: an earlier link touched him) carries the string even when it
;; whiffed, at block timing; link 1's whiff (NIL) still never chains
(check (and (chain-open-p 21 9 3 12 t) (not (chain-open-p 20 9 3 12 t)) (not (chain-open-p 24 9 3 12 t))))
;; the follow-up's chase: reach its hit window, clamped, never past him
(let ((g (max *lunge-stop* (- 2.6 *chase-margin*))))
  (check (~= (string-chase-speed (+ g 1.4) 2.6 7) (* 60.0 (/ 1.4 7))))            ; arrives exactly at the hit frame
  (check (~= (string-chase-speed 20.0 2.6 7) *chase-max*))                        ; clamped
  (check (zerop (string-chase-speed g 2.6 7)))                                     ; close enough: no motion
  (check (zerop (string-chase-speed 5.0 2.6 0)))                                   ; not after the startup
  (check (<= (/ (string-chase-speed 3.0 2.6 1) 60.0) (- 3.0 g)))                  ; one frame never overshoots the goal
  (check (zerop (string-chase-speed *lunge-stop* 1.2 5)))                          ; a short reach stops at *LUNGE-STOP*
  ;; simulated: a frame at a time from 6 m, he ends inside the reach by the hit and never nearer than the goal
  (let ((d 6.0))
    (loop for left from 14 downto 1 do (decf d (/ (string-chase-speed d 2.6 left) 60.0)))
    (check (and (<= d 2.6) (>= d (- g 1e-4))))))
(check (and (cancel-open-p 9 9 24 t) (cancel-open-p 23 9 24 t) (not (cancel-open-p 24 9 24 t))
            (not (cancel-open-p 10 9 24 nil))))
(check (and (invulnerable-frame-p 3 *step-iframes*) (invulnerable-frame-p 9 *step-iframes*)
            (not (invulnerable-frame-p 10 *step-iframes*)) (invulnerable-frame-p 14 *hoho-iframes*)
            (not (invulnerable-frame-p 0 *hoho-iframes*))))
;; Frame advantage end to end, as far as it is pure: replay how the fighters step (fighter.lisp
;; MAIN-PHASE-STEP / STUN-STEP: a move starts on step 0 at frame ENTER, +1 frame per step, idles on the
;; step its frame reaches MOVE-END-FRAME; blockstun starts on the hit's step at 0 and idles when it
;; reaches the stun; either side acts on the step after it idles). The headless twin: debug 2315+k.
(defun free-steps (mv)
  "MV blocked on its first hit frame: values the attacker's and the defender's first actionable
step, counted from the move's first step."
  (let* ((enter (mv-enter mv)) (h (- (mv-first-hit mv) enter))
         (end (move-end-frame (mv-s mv) (mv-a mv) (mv-r mv) (mv-whiff mv) :block nil))
         (stun (blockstun (mv-total mv) (mv-first-hit mv) (mv-adv-block mv))))
    (values (loop for step from 1 when (>= (+ enter step) end) return (1+ step))
            (loop for step from (1+ h) for sf from 1 when (>= sf stun) return (1+ step)))))
(dolist (cf *forms*)
  (maphash (lambda (name m)
             (declare (ignore name))
             (when (and (integerp (mv-adv-block m)) (plusp (length (mv-hits m))))
               (multiple-value-bind (att def) (free-steps m)
                 (check (= (- def att) (mv-adv-block m))))))        ; the §5 table's number, exactly
           (kit-moves (apply #'kit cf))))
(defun blocked-gap (a b)
         "Steps the defender is free before B's first active frame when A's -2 hit is blocked and the
string goes on at the earliest chain frame (B starts on that step, frame 0)."
         (multiple-value-bind (att def) (free-steps a)
           (declare (ignore att))
           (- (+ (- (mv-total a) (mv-enter a) *chain-lead*) (- (mv-s b) (mv-enter b))) def)))
(defun hit-gap (a b)
         "Frames between the victim leaving hitstun and B's first active frame (< 0 = a combo)."
         (let ((h (mv-first-hit a)))
           (- (+ (mv-s a) (mv-a a) (- (mv-s b) (mv-enter b))) (+ h 1 (hitstun (hw-react (svref (mv-hits a) 0)))))))
;;; ---------------------------------------------------------------- the J / K strings (docs/duel/DUEL_STRINGS.md §2, §3)
(defun link-moves (k)
  "Every string link of kit K reachable from J1 / K1: a list of (move link-number button-sequence)."
  (let ((out nil))
    (labels ((walk (m n seq)
               (push (list m n seq) out)
               (dolist (c '(:q :f))
                 (let ((nx (kit-next k (mv-name m) c)))
                   (when nx (walk nx (1+ n) (append seq (list c))))))))
      (walk (kit-command-move k :q) 1 '(:q))
      (walk (kit-command-move k :f) 1 '(:f)))
    (nreverse out)))
(defun route (k first presses)
  "The links a string plays when every link makes contact: FIRST (:q / :f) from neutral, then per link the J / K
presses made during it (STRING-LATCH: the last allowed press wins, a press after a switch of the old button is eaten)."
  (let* ((m (kit-command-move k first)) (out (list (mv-name m))))
    (dolist (ps presses (nreverse out))
      (let ((q nil))
        (when (string-link-p k (mv-name m))
          (dolist (c ps) (setf q (string-latch k (mv-name m) c q))))
        (unless q (return (nreverse out)))
        (setf m (kit-next k (mv-name m) q))
        (push (mv-name m) out)))))
(defun on-hit-adv (m)
  (let ((w (svref (mv-hits m) 0))) (- (or (hw-stun w) (hitstun (hw-react w))) (- (mv-total m) (hw-from w)))))
(dolist (cf (remove-if #'trace-form-p *forms*))
  (let* ((k (apply #'kit cf)) (links (link-moves k)) (j1 (kit-command-move k :q)) (k1 (kit-command-move k :f))
         (cup3 (equal cf '(:kenpachi :nomihose))) (fails0 *fails*) (a (owl-adv cf)))
    ;; the shape: exactly the six full routes JJJ JJK JKK KKK KKJ KJJ (J / K switch at most once), every link 3 an ender
    (check (equal (sort (loop for (nil n seq) in links when (= n 3) collect (format nil "~{~a~}" (mapcar (lambda (c) (if (eq c :q) "J" "K")) seq)))
                        #'string<)
                  '("JJJ" "JJK" "JKK" "KJJ" "KKJ" "KKK")))
    (check (every (lambda (l) (eq (and (member :ender (mv-flags (first l))) t) (= 3 (second l)))) links))
    (check (every (lambda (l) (eq (string-link-p k (mv-name (first l))) (< (second l) 3))) links))
    ;; the budget (§2.1): J1 S 7-10 A 3 R 12 flinch -2; K1 S 16-20 A 4 R 20-22 stagger -3, no armour (cup 3's K1 is
    ;; KUKAN-GIRI, -4); J beats K: S(K1) - S(J1) >= 7
    ;; (the owl's +1, decision 36: R 1 f shorter, :adv-block 1 higher on every J / K)
    (check (and (<= 7 (mv-s j1) 10) (= 3 (mv-a j1)) (= (- 12 a) (mv-r j1)) (= (+ -2 a) (mv-adv-block j1))
                (eq :flinch (hw-react (svref (mv-hits j1) 0)))))
    (check (and (<= 16 (mv-s k1) 20) (= 4 (mv-a k1)) (<= (- 20 a) (mv-r k1) 22) (= (+ a (if cup3 -4 -3)) (mv-adv-block k1))
                (zerop (mv-armor-hits k1)) (eq :stagger (hw-react (svref (mv-hits k1) 0)))))
    (check (>= (- (mv-s k1) (mv-s j1)) 7))
    (dolist (l links)
      (destructuring-bind (m n seq) l
        (let ((kk (eq (car (last seq)) :f)) (w (svref (mv-hits m) 0)))
          ;; every K at link 2 / 3 enters at S_eff 14; J links 2 / 3 -2 / -4, K links -3 / -20; enders stagger / crumple
          (when (and kk (> n 1)) (check (= 14 (- (mv-s m) (mv-enter m)))))
          (when (> n 1)
            (check (= (mv-adv-block m) (+ a (cond ((and (= n 2) kk) -3) ((= n 2) -2) (kk -20) (t -4)))))
            (check (eq (hw-react w) (cond ((and (= n 3) kk) :crumple) ((or kk (= n 3)) :stagger) (t :flinch)))))
          ;; the whiff: one swing, R + 8 (J) / R + 12 (K)
          (check (= (mv-whiff m) (+ (mv-r m) (if kk *whiff-extra-k* *whiff-extra-j*))))
          (check (= (move-end-frame (mv-s m) (mv-a m) (mv-r m) (mv-whiff m) nil nil)
                    (+ (mv-s m) (mv-a m) (mv-r m) (if kk *whiff-extra-k* *whiff-extra-j*))))
          ;; every follow-up combos on hit (after a J and after a K link alike); on block (the gap is S_eff - 1 -
          ;; *CHAIN-LEAD* - adv: S_eff - 2 after a -2 link, S_eff - 1 after a -3 one) a K link leaves >= 11 f (any J1
          ;; <= 10 f interrupts it; after KUKAN-GIRI the rift closes it) and a J link 3 .. S(J1) f (Step / Hoho fit;
          ;; his own J1 at best trades: Kenpachi's and KATATE's K2 -> J3 leave exactly S(J1))
          (dolist (c '(:q :f))
            (let ((nx (kit-next k (mv-name m) c)))
              (when nx
                (check (< (hit-gap m nx) 0))
                (let ((g (blocked-gap m nx)))
                  (if (eq c :f)
                      (check (>= g 11))
                      (check (and (>= g (first *step-iframes*)) (<= g (mv-s j1))))))))))))
    ;; the switched link 2 (J2s, K2s) is a copy: the same data as J2 / K2 but its name
    (let ((j2 (kit-next k (mv-name j1) :q)) (j2s (kit-next k (mv-name k1) :q))
          (k2 (kit-next k (mv-name k1) :f)) (k2s (kit-next k (mv-name j1) :f)))
      (unless cup3
        ;; (Ichigo's Shikai: the copies are the CROSS, both blades: they may differ only in :guard and the clip)
        (flet ((core (m) (if (equal cf '(:ichigo :base))
                             (loop for (key v) on (mv-spec m) by #'cddr unless (member key '(:guard :clip :clip-s)) append (list key v))
                             (mv-spec m))))
          (check (and (not (eq j2 j2s)) (not (eq k2 k2s))
                      (equal (core j2) (core j2s)) (equal (core k2) (core k2s))
                      (= (mv-enter k2) (mv-enter k2s)) (= (mv-s j2) (mv-s j2s))
                      (or (equal cf '(:ichigo :base)) (eq (mv-clip k2) (mv-clip k2s))))))))
    ;; K3 on block -20: every J1 and every base K1 punishes it; J3 -4 is safe
    (check (every (lambda (l) (or (/= 3 (second l)) (< (max (mv-s (mv :yamamoto :base :ya-j1)) (mv-s (mv :kenpachi :base :ke-j1))
                                                             (mv-s (mv :yamamoto :base :ya-k1)) (mv-s (mv :kenpachi :base :ke-k1)))
                                                        (- (mv-adv-block (first l))))
                                  (= (+ -4 a) (mv-adv-block (first l)))))
                  links))
    ;; the O ender always combos off a link-3 hit: the module's dash from the ender's reach to *KIKON-TRIGGER* + its
    ;; strike's startup inside the ender's stagger / crumple
    (let* ((o (kit-command-move k :kikon)) (pa (mv-params o)))
      (dolist (l links)
        (when (= 3 (second l))
          (let* ((m (first l)) (dash (if (zerop (getf pa :dash-max)) 0
                                        (ceiling (* 60 (/ (max 0.0 (- (mv-reach m) *kikon-trigger*)) (getf pa :speed)))))))
            (check (< (+ (- (mv-total m) (hw-from (svref (mv-hits m) 0)) (mv-r m)) dash (mv-s o))
                      (hitstun (hw-react (svref (mv-hits m) 0)))))))))
    (unless (= fails0 *fails*) (format t "  string budget fails in ~s~%" cf))))
;; route resolution (the latch, §2.1 / §2.3), Yamamoto Shikai and Kenpachi RYOTE
(let ((y (kit :yamamoto :base)) (r (kit :kenpachi :ryote)))
  (check (equal (route y :q '((:q) (:q))) '(:ya-j1 :ya-j2 :ya-j3)))
  (check (equal (route y :q '((:q) (:f))) '(:ya-j1 :ya-j2 :ya-k3)))
  (check (equal (route y :q '((:f) (:f))) '(:ya-j1 :ya-k2s :ya-k3)))
  (check (equal (route y :f '((:f) (:f))) '(:ya-k1 :ya-k2 :ya-k3)))
  (check (equal (route y :f '((:f) (:q))) '(:ya-k1 :ya-k2 :ya-j3)))
  (check (equal (route y :f '((:q) (:q))) '(:ya-k1 :ya-j2s :ya-j3)))
  (check (equal (route y :q '((:f) (:q))) '(:ya-j1 :ya-k2s)))              ; JKJ: switched back, eaten: the string ends
  (check (equal (route y :f '((:q) (:f))) '(:ya-k1 :ya-j2s)))              ; KJK
  (check (equal (route y :q '((:q :f) (:f :q))) '(:ya-j1 :ya-k2s :ya-k3)))   ; the last allowed press wins; the eaten J
  (check (equal (route y :q '((:q) (:q) (:q))) '(:ya-j1 :ya-j2 :ya-j3)))   ; link 3 latches nothing: no link 4
  (check (equal (route y :q '(() (:q))) '(:ya-j1)))                       ; nothing pressed: it stops at link 1
  (check (equal (route r :f '((:q) (:q))) '(:ke-r-k1 :ke-r-j2s :ke-r-j3)))
  (check (equal (route (kit :kenpachi :nomihose) :f '((:f) (:f))) '(:ke-n-f1 :ke-r-k2 :ke-r-k3)))   ; KUKAN-GIRI is cup 3's K1
  (check (and (eq (string-latch y :ya-k2s :q :f) :f) (eq (string-latch y :ya-k2s :q nil) nil)
              (eq (string-latch y :ya-j1 :f :q) :f) (not (string-link-p y :ya-j3)) (not (string-link-p y :ya-sig)))))
;; KATATE (+2) keeps S_eff 14: :enter grows with the startup (J1 9, K1 18, K2 22 from 8); the design's examples
(let ((t1 (kit :kenpachi :nozarashi)))
  (check (and (= 9 (mv-s (kit-move t1 :ke-j1))) (= 18 (mv-s (kit-move t1 :ke-k1))) (= 22 (mv-s (kit-move t1 :ke-k2)))
              (= 8 (mv-enter (kit-move t1 :ke-k2))) (= 8 (mv-enter (kit-move t1 :ke-k3))) (= 10 (mv-s (kit-move t1 :ke-j3))))))
;; the route damage of Kenpachi base on hit (§3.5, before multipliers; the combo scaling starts at hit 4; K2 / K3 at 80 %
;; of the design's, §9): JJJ 112, KKK 210 (the design's 245), KJJ 147; the O ender as hit 4 x0.9 = 63
(flet ((dmg (&rest names) (loop for n in names for i from 1 sum (hit-damage (mv-dmg (mv :kenpachi :base n)) nil nil i nil))))
  (check (and (= 112 (dmg :ke-j1 :ke-j2 :ke-j3)) (= 210 (dmg :ke-k1 :ke-k2 :ke-k3)) (= 147 (dmg :ke-k1 :ke-j2s :ke-j3))
              (= 63 (hit-damage 70 nil nil 4 nil)))))
;; Yama's J1 -> J2 on block: exactly the 6 f gap (free on step 23, J2 hits on step 21 + 8)
(let ((q1 (mv :yamamoto :base :ya-j1)) (q2 (mv :yamamoto :base :ya-j2)))
  (check (= 23 (nth-value 1 (free-steps q1))))
  (check (= 6 (- (+ (- (mv-total q1) *chain-lead*) (mv-s q2)) (nth-value 1 (free-steps q1))))))
(check (~= (mv-clip-speed (mv :kenpachi :nozarashi :ke-j1)) (/ 7.0 9.0)))  ; hit pose on the later hit frame
(check (~= (mv-clip-speed (mv :kenpachi :base :ke-j1)) 1.0))
;; KOSEI (§5): x1 at a full guard gauge, x3 empty, x2 half; a JJJ (g 24) pays 4.8 R / 2.4 FS full, 14.4 / 7.2 empty
(check (and (~= (kosei-mult 100.0) 1.0) (~= (kosei-mult 0.0) 3.0) (~= (kosei-mult 50.0) 2.0) (~= *kosei-bonus* 2.0)))
(multiple-value-bind (r fs m) (kosei-gain 24 100.0) (check (and (~= r 4.8) (~= fs 2.4) (~= m 1.0))))
(multiple-value-bind (r fs m) (kosei-gain 24 0.0) (check (and (~= r 14.4) (~= fs 7.2) (~= m 3.0))))
(check (= 24 (loop for n in '(:ke-j1 :ke-j2 :ke-j3) sum (hw-guard (svref (mv-hits (mv :kenpachi :base n)) 0)))))
(check (= (move-end-frame 9 3 12 18 nil nil) 30))                      ; whiff: R + 6
(check (and (= (move-end-frame 9 3 12 18 :block nil) 24) (= (move-end-frame 2 1 20 26 nil t) 23)))

;;; ================================================================ damage (§4)
(check (and (~= (combo-scale 1) 1.0) (~= (combo-scale 3) 1.0) (~= (combo-scale 4) 0.9)
            (~= (combo-scale 9) 0.4) (~= (combo-scale 12) 0.4)))
(check (= (hit-damage 100 nil nil 1 nil) 100))
(check (= (hit-damage 100 '(:mult 1.3) nil 1 nil) 130))                 ; Hellfire
(check (= (hit-damage 100 '(:cornered 0.05 :cornered-max 0.25 :lost 2) nil 1 nil) 110))
(check (= (hit-damage 100 '(:cornered 0.05 :cornered-max 0.25 :lost 6) nil 1 nil) 125))   ; capped
(check (= (hit-damage 100 '(:mult 1.15 :cornered 0.05 :cornered-max 0.25 :lost 3) nil 5 t) 132)) ; x1.15x1.15x1.25x0.8
(check (= (hit-damage 100 nil nil 20 nil) 40))                          ; floor 40 %
(check (= (hit-damage 1 nil nil 12 nil) 1))                             ; a hit always does 1
(check (= (hit-damage 0 '(:mult 2.0) nil 1 t) 0))
(check (= (hit-damage 100 (kit-atk-mods (kit :yamamoto :bankai-east) 4) nil 1 nil) 100))     ; East x1.0 (the rework)
(check (and (= (hit-damage 100 (kit-atk-mods (kit :kenpachi :nozarashi) 4) nil 1 nil) 120)   ; KATATE x1.0 x Cornered 1.20
            (= (hit-damage 100 (kit-atk-mods (kit :kenpachi :ryote) 4) nil 1 nil) 138)      ; RYOTE 1.15 x 1.20
            (= (hit-damage 100 (kit-atk-mods (kit :kenpachi :nomihose) 5) nil 1 nil) 150))) ; worst case 1.2 x 1.25
(check (= (chip-damage 110 *chip-fire* 500) 13))
(check (and (= (chip-damage 110 0.12 5) 4) (= (chip-damage 110 0.12 1) 0)))   ; chip never kills
(check (= (chip-damage 110 nil 500) 0))                                  ; no chip by default
(check (= 500 (loop for s below 600 sum (burn-amount 1000 *hellfire-burn* s))))  ; 5 %/s x 10 s
(check (= 20 (loop for s below 60 sum (burn-amount 1000 0.02 s))))        ; 2 %/s x 1 s
(check (and (= (burn 30 50) 1) (= (burn 1 5) 1) (= (burn 500 30) 470)))  ; burns floor at 1
(check (= (cornered-mult 0.05 10 0.25) 1.25))

;;; ================================================================ Kikon, Konpaku, Soul Break, time-up
(let ((*red-threshold* 0.30))                  ; the rule at the design value (tuning.lisp may differ)
  (check (and (red-p 299 1000) (not (red-p 300 1000)))))
;; the Kikon rush strike (the user's rule, with the lead's dash-in): the first strike is always guardable; guarded
;; -> nothing; a hit with O held knocks him back and the rusher dashes in to the follow-up, whose hit is the Kikon;
;; released -> a plain hit
(check (eq (kikon-outcome t :hit nil) :follow))
(check (eq (kikon-outcome t :counter nil) :follow))                        ; (a Breaker's startup)
(check (eq (kikon-outcome nil :hit t) :kikon))                             ; the follow-up hit: the Kikon
(check (eq (kikon-outcome t :hit t) :kikon))
(check (null (kikon-outcome nil :hit nil)))                                ; released: a plain hit
(check (notany (lambda (r) (or (kikon-outcome t r nil) (kikon-outcome t r t)))
               '(nil :blocked :absorbed :armored :parried :guard-break)))  ; guarded / dodged: nothing
;; the dash-in: a non-red victim reels *KIKON-FOLLOW-STUN*, then has *KIKON-FOLLOW-GAP* frames (a guard needs
;; *GUARD-RAISE*) before the strike: a guard held during the dash blocks it; a red one reels until it has landed
;; and can't guard it (iframes still dodge it)
(check (and (>= *kikon-follow-gap* (+ *guard-raise* 1)) (= (kikon-follow-wait 6) (- (+ *kikon-follow-stun* 1 *kikon-follow-gap*) 6))
            (= (kikon-follow-wait 99) 0) (~= *kikon-follow-kb* 2.5)))
(check (and (null (kikon-follow-unguardable-p nil)) (kikon-follow-unguardable-p t)))
(check (and (eq (resolve-contact :guard :unguardable (kikon-follow-unguardable-p nil)) :blocked)     ; not red: blocked
            (eq (resolve-contact :guard :unguardable (kikon-follow-unguardable-p t)) :hit)           ; red: the Kikon
            (eq (resolve-contact :stance :unguardable (kikon-follow-unguardable-p t)) :hit)
            (eq (resolve-contact :parry :unguardable (kikon-follow-unguardable-p t)) :hit)
            (null (resolve-contact :invuln :unguardable (kikon-follow-unguardable-p t)))))
(dolist (cf *forms*)
  (let ((s (mv-s (kit-command-move (apply #'kit cf) :kikon))))
    (check (= (+ (kikon-follow-wait s) s) (+ (kikon-follow-stun nil s) 1 *kikon-follow-gap*)))     ; free GAP f first
    (check (> (kikon-follow-stun t s) (+ (kikon-follow-wait s) s)))))                              ; red: still reeling
;; the dash-in's speed: it reaches the trigger range exactly as the wait runs out, never over the module's cap
(check (and (~= (kikon-follow-speed 4.6 10 99.0) 18.0) (~= (kikon-follow-speed 4.6 10 12.0) 12.0)
            (~= (kikon-follow-speed 1.0 10 99.0) 0.0) (~= (kikon-follow-speed 4.6 0 99.0) 99.0)))
;; the strike is guardable: guard and stance stop it (no :unguardable any more); iframes dodge it
(check (eq (resolve-contact :guard) :blocked))
(check (eq (resolve-contact :guard :unguardable t) :hit))
(check (eq (resolve-contact :guard :unguardable nil) :blocked))
(check (eq (resolve-contact :stance :unguardable t) :hit))
(check (eq (resolve-contact :stance-in :unguardable t) :hit))
(check (null (resolve-contact :invuln :unguardable t)))
(check (eq (resolve-contact :breaker :unguardable t) :counter))
;; the rush's phases: the module's aura, then the strike at once when close (or no dash: ENJO), else
;; the dash to the trigger range or its end (the module's dash-max)
(flet ((nx (ph f d &optional (dm 22)) (kikon-rush-next-phase ph f d :aura 5 :dash-max dm)))
  (check (and (eq (nx :aura 4 9.0) :aura) (eq (nx :aura 5 9.0) :dash) (eq (nx :aura 5 *kikon-trigger*) :strike)
              (eq (nx :dash 3 9.0) :dash) (eq (nx :dash 3 (- *kikon-trigger* 0.1)) :strike) (eq (nx :dash 22 9.0) :strike)
              (eq (nx :aura 5 9.0 0) :strike))))                           ; no dash: strike after the aura
(check (and (~= (kikon-rush-reach 36.0 14) 10.0) (~= (kikon-rush-reach 13.0 36) 9.4) (~= (kikon-rush-reach 18.0 30) 10.6)))
;; armour: a move's armour takes hits (:armored) until its budget is spent; a Breaker, an unguardable hit
;; go through (nothing ignores armour: Nozarashi v2 removed :ignore-armor)
(check (and (eq (resolve-contact :armor) :armored) (eq (resolve-contact :armor :in-front nil) :armored)
            (eq (resolve-contact :armor :breaker t) :hit) (eq (resolve-contact :armor :unguardable t) :hit)))
(check (equal (multiple-value-list (kikon-result 6 2 nil)) '(4 2 nil)))
(check (equal (multiple-value-list (kikon-result 6 3 nil)) '(3 3 nil)))           ; awakened
(check (equal (multiple-value-list (kikon-result 6 2 t)) '(3 3 nil)))           ; Soul Break +1
(check (equal (multiple-value-list (kikon-result 6 4 t)) '(1 5 nil)))           ; KESSA's 3 clones: 4 + 1 = the cap 5
(check (equal (multiple-value-list (kikon-result 6 3 t)) '(2 4 nil)))
(check (equal (multiple-value-list (kikon-result 2 2 nil)) '(0 2 t)))
(check (equal (multiple-value-list (kikon-result 1 3 t)) '(0 1 t)))
(check (and (soul-break-p 0) (not (soul-break-p 1))))
(check (eql (time-up-winner 3 100 1000 2 900 1000) 0))                   ; Konpaku first
(check (eql (time-up-winner 2 900 1000 3 100 1000) 1))
(check (eql (time-up-winner 2 600 1000 2 500 1000) 0))                   ; then Reishi %
(check (eql (time-up-winner 2 500 1000 2 525 1050) :draw))               ; 50 % each
(multiple-value-bind (ax az bx bz) (reset-placement 10.0 0.0 12.0 0.0)
  (check (and (~= ax -4.0) (~= az 0.0) (~= bx 4.0) (~= bz 0.0))))

;;; ================================================================ gauges
(check (and (~= (reiatsu-gain 100 0) 8.0) (~= (reiatsu-gain 0 100) 10.0) (~= (reiatsu-gain 0 0 60) 3.0)))   ; SPs only: 3 / s
(check (~= (awakening-gain 100 100 1) 18.9))                                ; x0.7 since 2026-09-30 (was 27)
(check (and (~= *awaken-dealt* 0.035) (~= *awaken-taken* 0.049) (~= *awaken-per-konpaku* 10.5)))
(check (and (~= (gauge-add 290.0 20.0 300.0) 300.0) (~= (gauge-add 5.0 -10.0 300.0) 0.0)))
(check (equal (multiple-value-list (spend-bars 150.0 1)) '(50.0 t)))
(check (equal (multiple-value-list (spend-bars 50.0 1)) '(50.0 nil)))
(check (and (hoho-allowed-p nil 30.0 0) (not (hoho-allowed-p t 100.0 0))          ; flash-step 30
            (not (hoho-allowed-p nil 100.0 10)) (not (hoho-allowed-p nil 29.0 0))))
(check (and (awaken-allowed-p t 100.0 nil) (not (awaken-allowed-p t 100.0 t)) (not (awaken-allowed-p nil 100.0 nil))
            (not (awaken-allowed-p t 99.0 nil))))
;; the burst modes (docs/duel/DUEL_DESIGN.md "Burst modes", the user 2026-09-30): the state picks the mode
(check (and (eq (burst-mode :stun nil 2 nil) :blue) (eq (burst-mode :air nil 3 nil) :blue) (null (burst-mode :stun nil 1 nil))
            (eq (burst-mode :guard-hit nil 0 nil) :blue)                        ; blockstun: from any blocked hit
            (eq (burst-mode :move nil 0 t) :orange) (null (burst-mode :move nil 0 nil))   ; a hit's window / a whiff or block
            (eq (burst-mode :idle nil 0 nil) :white) (eq (burst-mode :guard nil 0 nil) :white) (eq (burst-mode :run nil 0 nil) :white)
            (null (burst-mode :step nil 0 nil)) (null (burst-mode :hoho nil 0 nil)) (null (burst-mode :down nil 5 nil))
            (null (burst-mode :cine nil 0 nil)) (null (burst-mode :idle t 0 nil)) (null (burst-mode :stun t 5 nil))))   ; locked
(check (and (burst-allowed-p :white 70.0 nil) (burst-allowed-p :orange 70.0 nil) (burst-allowed-p :blue 100.0 nil)   ; 70 for every mode
            (not (burst-allowed-p :white 69.9 nil)) (not (burst-allowed-p :blue 69.0 nil)) (not (burst-allowed-p :orange 60.0 nil))
            (not (burst-allowed-p nil 100.0 nil)) (not (burst-allowed-p :white 100.0 :blue))))   ; no mode / one running
;; the drain: 18 / s, to 0 then it ends; from 70 3.9 s, from 100 5.6 s
(check (and (= *burst-drain* 18) (~= (burst-drain 50.0) (- 50.0 0.3)) (~= (burst-drain 0.1) 0.0)))
(flet ((frames (fs) (loop for n from 1 do (setf fs (burst-drain fs)) when (<= fs 0.0) return n)))
  (check (and (<= 232 (frames 70.0) 234) (<= 332 (frames 100.0) 334))))
;; no flash-step gain during a burst; Hoho below one bar spends what is left
(check (and (~= (burst-fs-gain 12.0 nil) 12.0) (~= (burst-fs-gain 12.0 :white) 0.0) (~= (burst-fs-gain 15.0 :orange) 0.0)))
(check (and (hoho-allowed-p nil 12.0 0 :white) (hoho-allowed-p nil 0.1 0 :blue) (not (hoho-allowed-p nil 0.0 0 :blue))
            (not (hoho-allowed-p nil 12.0 0)) (not (hoho-allowed-p nil 12.0 5 :white)) (not (hoho-allowed-p t 50.0 0 :white))))
(check (and (~= (hoho-cost 12.0 :white) 12.0) (~= (hoho-cost 80.0 :white) 30.0) (~= (hoho-cost 80.0 nil) 30.0)))
;; WHITE: Reishi +12 / s in whole points (60 f pay exactly 12), no guard-gauge boost (gg-regen has no WHITE input)
(check (and (= 70 (loop for n from 1 to 60 sum (burst-heal n *white-reishi*))) (= 66 (loop for n from 1 to 333 sum (burst-heal n 12.0)))
            (= 1 (burst-heal 5 12.0)) (= 0 (burst-heal 4 12.0))))
(check (and (~= *white-reishi* 70.0) (~= *white-reiatsu* 15.0) (~= *white-awaken* 1.4)))
;; BLUE: the guard gauge refills with no delay, x2 when free, x0.5 even while guarding (GUARD HOLD otherwise)
(check (and (~= (gg-regen 50.0 999 nil nil nil 0.25) (+ 50.0 (/ (* 0.25 *gg-regen*) 60)))   ; a form's :gg-regen (Bankai East)
            (~= (gg-regen 50.0 999 t nil nil 0.25) (+ 50.0 (/ *gg-regen-guardless* 60)))   ; (guardless: unchanged)
            (= 0.25 (kit-gg-regen (find-kit :yamamoto :bankai-east))) (= 1.0 (kit-gg-regen (find-kit :yamamoto :base)))))
(check (and (~= (gg-regen 50.0 0 nil nil :blue) (+ 50.0 (/ 11.0 60))) (~= (gg-regen 50.0 0 nil t :blue) (+ 50.0 (/ 2.75 60)))
            (~= (gg-regen 50.0 0 t nil :blue) (+ 50.0 (/ 13.0 60))) (~= (gg-regen 99.99 0 nil t :blue) 100.0)
            (~= (gg-regen 50.0 999 nil t) 50.0)))                            ; outside BLUE: GUARD HOLD as ever
;; ORANGE: the cancel window is the hit's cancel window (first hit frame .. end of recovery); the startup cut 40 %, >= 1 f left
(check (and (cancel-open-p 12 10 30 t) (not (cancel-open-p 9 10 30 t)) (not (cancel-open-p 30 10 30 t)) (not (cancel-open-p 12 10 30 nil))))
;; the guard cancel (the user, 2026-10-01): only after its own hit, over the last half of the recovery (K2 21/4/24: f37-44)
(check (and (= 0.5 *guard-cancel*) (not (guard-cancel-open-p 36 21 4 24 :hit)) (guard-cancel-open-p 37 21 4 24 :hit)
            (guard-cancel-open-p 48 21 4 24 :hit) (not (guard-cancel-open-p 49 21 4 24 :hit))
            (not (guard-cancel-open-p 40 21 4 24 :block)) (not (guard-cancel-open-p 40 21 4 24 nil))))
;; the arena's room for a push (RAY-ROOM): from the centre 5 to an r 5 edge; at 4 m out along +x, 1 left that way and 9 back
(check (and (< (abs (- (ray-room 0.0 0.0 1.0 0.0 5.0) 5.0)) 1e-4) (< (abs (- (ray-room 4.0 0.0 1.0 0.0 5.0) 1.0)) 1e-4)
            (< (abs (- (ray-room 4.0 0.0 -1.0 0.0 5.0) 9.0)) 1e-4) (= 0.0 (ray-room 5.0 0.0 1.0 0.0 5.0))))
;; a J (QUICK) may guard-cancel on block too (the user 2026-10-02): J1 9/3/12 opens f18-23; never on a whiff
(check (and (guard-cancel-open-p 18 9 3 12 :block t) (not (guard-cancel-open-p 17 9 3 12 :block t))
            (not (guard-cancel-open-p 24 9 3 12 :block t)) (not (guard-cancel-open-p 20 9 3 12 nil t))
            (guard-cancel-open-p 20 9 3 12 :hit t)))
(check (and (= (chain-startup-cut 10 0) 4) (= (chain-startup-cut 20 0) 8) (= (chain-startup-cut 2 0) 0) (= (chain-startup-cut 1 0) 0)
            (= (chain-startup-cut 3 0) 1) (= (chain-startup-cut 12 2) 4) (= *chain-window* 12)))
(check (and (~= (burst-gain-mult :orange) 1.5) (~= (burst-gain-mult :white) 1.0) (~= (burst-gain-mult nil) 1.0)))
(check (and (~= (nth-value 0 (hit-gains 100 0 nil 1.5)) 12.0) (~= (nth-value 2 (hit-gains 100 0 nil 1.5)) 5.25)   ; x1.5 dealt
            (~= (nth-value 0 (hit-gains 0 100 nil 1.5)) 10.0) (~= (nth-value 0 (hit-gains 100 0 nil)) 8.0)))    ; taken untouched
;; the Kikon refund: a flash-step bar (35) and a Reiatsu bar, clamped
(check (and (equal (multiple-value-list (kikon-refund 10.0 50.0)) '(45.0 150.0))
            (equal (multiple-value-list (kikon-refund 90.0 250.0)) '(100.0 300.0))))
;; the flash-step gauge (design v3 G.1): Hoho 30, Burst 70, no Reiatsu; 3 / s after 60 f; +0.03 per damage taken
(check (and (= *fs-hoho* 30) (= *fs-burst* 70) (= *fs-refund* 15) (~= *fs-taken* 0.03) (= *fs-max* 100)))
(check (and (~= (fs-regen 50.0 59) 50.0) (~= (fs-regen 50.0 60) 50.05) (~= (fs-regen 99.99 600) 100.0)))
(check (~= 3.0 (- (loop with f = 0.0 for i below 60 do (setf f (fs-regen f 60)) finally (return f)) 0.0)))   ; 3 per second
(check (~= 600 (/ *fs-hoho* (/ *fs-regen* 60.0)) 0.5))                     ; ... a Hoho from empty in 11 s (10 + the 1 s delay)
;; the guard gauge (G.2): values by kind, +4 for an ender, overrides; the drain, the crush, the regen, guardless
(check (and (= (guard-value :quick -2) 8) (= (guard-value :quick -12) 12) (= (guard-value :flash -4) 14)
            (= (guard-value :flash -14) 18) (= (guard-value :sig -6) 18) (= (guard-value :sig -14) 22)
            (= (guard-value :sp -16) 22) (= (guard-value :kikon -14) 20) (= (guard-value nil nil) 12)
            (= (guard-value :sig -6 10) 10)))
(check (and (= (hw-guard (svref (mv-hits (mv :kenpachi :base :ke-j3)) 0)) 8)             ; J3 (-4) 8
            (= (hw-guard (svref (mv-hits (mv :kenpachi :base :ke-k3)) 0)) 18)            ; K3 ender (-20) 18
            (= (hw-guard (svref (mv-hits (mv :yamamoto :base :ya-sig)) 0)) 10)           ; the Signature's cuts 10 each
            (= 15 (getf (mv-params (find-move :ya-sig)) :guard))))                       ; ... its wave 15
;; Kenpachi base J J J blocked = 24, K K K = 46 (DUEL_STRINGS §3.5): a full gauge falls on the 5th J string, the 3rd K
(flet ((gv (name) (hw-guard (svref (mv-hits (mv :kenpachi :base name)) 0))))
  (check (= 24 (+ (gv :ke-j1) (gv :ke-j2) (gv :ke-j3))))
  (check (= 46 (+ (gv :ke-k1) (gv :ke-k2) (gv :ke-k3))))
  (check (and (< (* 4 24) *gg-max*) (>= (* 5 24) *gg-max*) (< (* 2 46) *gg-max*) (>= (* 3 46) *gg-max*))))
(check (equal (multiple-value-list (gg-drain 100.0 8)) '(92.0 nil)))
(check (equal (multiple-value-list (gg-drain 5.0 8)) '(0.0 t)))            ; emptied: GUARD CRUSH
;; the refill (the user's request 2026-09-27, 大幅減少防禦量表的恢復速度: 12 -> 5.5 / s, guardless 14 -> 6.5 / s)
(check (and (= *gg-delay* 60) (~= *gg-regen* 5.5) (~= *gg-regen-guardless* 6.5)))
(check (and (~= (gg-regen 50.0 59 nil nil) 50.0) (~= (gg-regen 50.0 60 nil nil) (+ 50.0 (/ 5.5 60)))
            (~= (gg-regen 50.0 60 t nil) (+ 50.0 (/ 6.5 60))) (~= (gg-regen 99.99 99 nil nil) 100.0)))
(check (<= 983 (loop with g = 0.0 for f from 0 until (>= g *gg-max*)         ; 0 -> 100 guardless: 60 f of delay +
                     do (setf g (gg-regen g f t nil)) finally (return f)) 984))   ;  923 f (15.4 s; + float rounding)
;; GUARD HOLD (guard v3): no refill while guarding, the delay frozen (not restarted): 40 f of delay, 30 f of guard,
;; 20 f released -> the refill starts on the 61st frame not guarding; a drain still zeroes the counter (DRAIN-GUARD)
(check (and (~= (gg-regen 50.0 999 nil t) 50.0) (= (gg-idle-next 40 t) 40) (= (gg-idle-next 40 nil) 41) (= (gg-idle-next 9999 nil) 9999)))
(check (= 60 (let ((idle 0)) (dotimes (i 40) (setf idle (gg-idle-next idle nil))) (dotimes (i 30) (setf idle (gg-idle-next idle t)))
               (dotimes (i 20) (setf idle (gg-idle-next idle nil))) idle)))
;; East's pierce (the rework): k = 0.1 .. 0.5 by his guard gauge (full = sharpest, the user's decision 2026-09-27), x a
;; move's :pierce-mult (KYOKKO 2: 0.2 .. 1.0). On hit x(1 + k) (KIT-ATK-MODS' pierce factor): E-Q1 Q2 E-Q3 (34 38 55)
;; at full = 51 + 57 + 82 = 190 (82.5 rounds to even); blocked, k x the damage goes through as chip (never kills): 17 + 19 + 28 = 64 at
;; full, 3 + 4 + 6 = 13 empty; KYOKKO at full: 170 on hit, all 85 through a guard
(check (and (~= *pierce-min* 0.1) (~= *pierce-max* 0.45) (~= *ward-mult* 1.1)))   ; the gate's values (2026-09-27)
(let ((*pierce-max* 0.5))                                                  ; the spec's arithmetic at 0.5
 (check (and (~= (pierce-rate 100.0) 0.5) (~= (pierce-rate 0.0) 0.1)
             (~= (pierce-rate 50.0) 0.3) (~= (pierce-rate 100.0 2.0) 1.0) (~= (pierce-rate 0.0 2.0) 0.2)))
 (let ((east (kit :yamamoto :bankai-east)))
  (flet ((hit (dmg gg &optional (m 1.0)) (hit-damage dmg (kit-atk-mods east 0 (+ 1.0 (pierce-rate gg m))) nil 1 nil))
         (through (dmg gg &optional (m 1.0)) (chip-damage dmg (pierce-rate gg m) 1300)))
    (check (= 190 (+ (hit 34 100.0) (hit 38 100.0) (hit 55 100.0))))
    (check (= 165 (+ (hit 34 50.0) (hit 38 50.0) (hit 55 50.0))))
    (check (= 64 (+ (through 34 100.0) (through 38 100.0) (through 55 100.0))))
    (check (= 13 (+ (through 34 0.0) (through 38 0.0) (through 55 0.0))))
    (check (and (= 170 (hit 85 100.0 2.0)) (= 85 (through 85 100.0 2.0)) (= 102 (hit 85 0.0 2.0)) (= 17 (through 85 0.0 2.0))))
    (check (= 49 (chip-damage 85 1.0 50))))))                                  ; the pierce never kills: it leaves 1
(check (and (~= (pierce-rate 100.0) 0.45) (~= (pierce-rate 100.0 2.0) 0.9)))    ; as tuned: KYOKKO 162 / 77 at full
;; the ward never refills: GUARD HOLD counts it as guarding (combat.lisp GAUGE-SYSTEM), so the gauge stands still and
;; the delay is frozen; West's drain is x*WARD-MULT*; Kenpachi's base Q string (28) crushes it on the 4th string
(check (and (~= (gg-regen 40.0 9999 nil t) 40.0) (= (gg-idle-next 30 t) 30)))
(check (and (can-guard-p 1.0 nil) (not (can-guard-p 0.0 nil)) (not (can-guard-p 99.0 t))))
;; a guard crush: Kenpachi's Q1 blocked into an empty gauge -> the attacker acts 25 frames first
(let ((q1 (mv :kenpachi :base :ke-j1)))
  (check (= 25 (- *guard-crush-stun* (- (mv-total q1) (mv-first-hit q1)))))
  (check (= *gg-breaker* 35)))
;; the CPU's guard: all at >= 50 %, half at 25-50 %, 0.15 below, none guardless; flash-step budgeting
(check (and (~= (ai-guard-mult 50.0 nil) 1.0) (~= (ai-guard-mult 30.0 nil) 0.5) (~= (ai-guard-mult 10.0 nil) 0.15)
            (~= (ai-guard-mult 100.0 t) 0.0) (~= (ai-guard-mult 0.0 nil) 0.0)))
(check (and (ai-hoho-spare-p 30.0 1000 1100) (not (ai-hoho-spare-p 90.0 400 1100)) (ai-hoho-spare-p 100.0 400 1100)))
(check (= *reishi-max* 1300))                                               ; guard v3, the user's decision 2026-09-26
;; the CPU's Burst: below half its Reishi, or the next hit would put it in red (30 % of 1100 = 330)
(check (and (ai-burst-wanted-p 540 1100 10) (not (ai-burst-wanted-p 600 1100 10))
            (ai-burst-wanted-p 600 1100 280) (not (ai-burst-wanted-p 600 1100 260))))
(check (and (= (seconds->frames 10.0) 600) (~= (timer-fill 300 600 100.0) 50.0)))
(check (and (= (stance-store 150 80) 200) (= (stance-store 0 45) 45)))
(check (equal (multiple-value-list (stance-release 150)) '(250 t)))
(check (equal (multiple-value-list (stance-release 100)) '(200 nil)))

;;; ================================================================ combo limits
(check (equal (multiple-value-list (combo-step :launch nil 0 0 0)) '(:launch 1 1 0)))
(check (equal (multiple-value-list (combo-step :launch nil 2 1 0)) '(:knockback 3 1 0)))   ; 1 launch
(check (equal (multiple-value-list (combo-step :flinch t 3 1 1)) '(:flinch 4 1 2)))
(check (equal (multiple-value-list (combo-step :flinch t 4 1 2)) '(:knockdown 5 1 3)))     ; 3 air hits
(check (equal (multiple-value-list (combo-step :flinch nil 9 0 0)) '(:flinch 10 0 0)))  ; no hit cap (the user 2026-09-30)
;; the hidden hit-stun tolerance (docs/duel/DUEL_DESIGN.md, the user 2026-09-29)
(check (= (stun-weight :flinch nil) 1))
(check (= (stun-weight :stagger nil) 2))
(check (every (lambda (r) (= (stun-weight r nil) 3)) '(:crumple :knockback :launch :knockdown)))
(check (= (stun-weight :flinch t) 3))                                     ; an SP / Kikon-rush strike: at least 3
(check (= (stun-weight :clash nil) 1))                                    ; any other reaction: 1
(check (= (stun-add 4.0 :stagger nil) 6.0))
(check (= (stun-decay 10.0 (1- *stun-delay*)) 10.0))                      ; no decay inside the delay
(check (~= (stun-decay 10.0 *stun-delay*) (- 10.0 (/ *stun-decay* 60.0))))   ; then -*STUN-DECAY* per second
(check (= (stun-decay 0.01 999) 0.0))                                     ; never below 0
(check (~= (let ((s 12.0)) (dotimes (i (+ *stun-delay* 60) s) (setf s (stun-decay s i)))) (- 12.0 *stun-decay*) 0.05))   ; 1 s past it
(check (and (not (stun-over-p 16.0 16.0)) (stun-over-p 16.5 16.0)))       ; past it, not at it
(check (= (stun-tolerance-of (kit :ichigo :base)) 16.0))                  ; per kit
(check (= (stun-tolerance-of (kit :kenpachi :base)) 26.0))
(check (= (stun-tolerance-of (kit :rukia :base)) 13.0))
(check (= (stun-tolerance-of (kit :kenpachi :bankai)) 26.0))              ; derived forms inherit it
(check (= (stun-tolerance-of (kit :ichigo :kessa)) 16.0))
(check (= (stun-tolerance-of (kit :senjumaru :tsuji6)) 13.0))
(check (every (lambda (cf) (plusp (stun-tolerance-of (apply #'kit cf)))) *forms*))
(check (= (stun-tolerance-of (make-kit)) *stun-tolerance*))              ; no key: the default
;; a re-pin loop with gaps: a J string (flinch flinch stagger), 20 f of neutral, again ... it still blows him away
(check (let ((s 0.0) (idle 0) (tol 16.0) (strings 0))
         (loop repeat 20 until (stun-over-p s tol)
               do (incf strings)
                  (dolist (r '(:flinch :flinch :stagger))
                    (unless (stun-over-p s tol) (setf s (stun-add s r nil) idle 0)
                            (dotimes (i 20) (setf s (stun-decay s idle)) (incf idle))))
                  (dotimes (i 20) (setf s (stun-decay s idle)) (incf idle)))
         (and (stun-over-p s tol) (<= strings 5))))
;; ... while strings 2 s apart never fill it
(check (let ((s 0.0) (idle 0) (over nil))
         (loop repeat 20
               do (dolist (r '(:flinch :flinch :stagger)) (setf s (stun-add s r nil) idle 0 over (or over (stun-over-p s 16.0))))
                  (dotimes (i 120) (setf s (stun-decay s idle)) (incf idle)))
         (not over)))

;;; ================================================================ perfect Hoho
;; Yama's Q1 (window [9,12), 1.4 m arc: the J floor) from the origin facing -Z; our cylinder r 0.4 h 1.8
(let* ((q1 (mv :yamamoto :base :ya-j1)) (w (svref (mv-hits q1) 0)))
  (flet ((perfect (sf z) (perfect-hoho-p sf (hw-from w) (hw-to w) (hw-vols w)
                                         0f0 0f0 0f0 0f0 -1f0 0f0 0f0 (float z 1f0) 0.4f0 1.8f0)))
    (check (perfect 3 -2.0))                  ; active in 6 f: perfect
    (check (perfect 0 -2.0))                  ; 9 f away: inside the 12 f lead (8 until 2026-10-01)
    (check (not (perfect-hoho-p 0 (+ (hw-from w) 4) (+ (hw-to w) 4) (hw-vols w)   ; 13 f away: too early
                                0f0 0f0 0f0 0f0 -1f0 0f0 0f0 -2f0 0.4f0 1.8f0)))
    (check (perfect 10 -2.0))                 ; active now
    (check (not (perfect 12 -2.0)))           ; over
    (check (perfect 3 -2.2))                  ; out of reach, but inside the 1 m inflation
    (check (perfect 3 -2.6))
    (check (not (perfect 3 -3.0)))))

;;; ================================================================ facing, movement, arena
(check (~= (turn-toward 0.0 (deg 90) (deg 18)) (deg 18)))
(check (~= (turn-toward 0.0 (deg 10) (deg 18)) (deg 10)))
(check (~= (angle-wrap (turn-toward (deg 170) (deg -170) (deg 18))) (deg -172)))   ; short way
(check (~= (track-step 360.0) (deg 6)))
(check (and (in-front-p 0.0 0.0 0.0 (sin (deg 95)) (- (cos (deg 95))) *guard-arc*)
            (not (in-front-p 0.0 0.0 0.0 (sin (deg 105)) (- (cos (deg 105))) *guard-arc*))))
(multiple-value-bind (to st) (stick-toward-strafe 0.0 1.0 0.0 0.0 0.0 0.0 -5.0)
  (check (and (~= to 1.0) (~= st 0.0))))                              ; up = at the opponent
(multiple-value-bind (to st) (stick-toward-strafe 1.0 0.0 0.0 0.0 0.0 0.0 -5.0)
  (check (and (~= to 0.0) (~= st 1.0))))                              ; right = strafe right
(multiple-value-bind (to st) (stick-toward-strafe 0.0 1.0 0.0 0.0 0.0 5.0 0.0)
  (check (and (~= to 0.0) (~= st -1.0))))                             ; opponent to the right: up = strafe left
(multiple-value-bind (dx dz) (toward-strafe-dir 0.6 0.8 1.0 1.0 1.0 -4.0)
  (multiple-value-bind (to st) (stick-toward-strafe dx (- dz) 0.0 1.0 1.0 1.0 -4.0)
    (check (and (~= to 0.6) (~= st 0.8)))))                           ; round trip (camera yaw 0)
(multiple-value-bind (x z) (clamp-to-circle 20.0 0.0 15.0) (check (and (~= x 15.0) (~= z 0.0))))
(multiple-value-bind (x z) (clamp-to-circle 3.0 4.0 15.0) (check (and (~= x 3.0) (~= z 4.0))))
(multiple-value-bind (x z yaw) (hoho-destination 0.0 0.0 0.0)
  (check (and (~= x 0.0) (~= z 1.6) (~= yaw 0.0))))                   ; behind, facing his back
(check (equal (multiple-value-list (step-direction 0.0 0.1)) '(-1.0 0.0)))   ; neutral = back
;; the run (Step held): neutral = at the opponent, stops 1.2 m from him, 6 f brake, 1 m of carry
(check (equal (multiple-value-list (step-direction 0.0 0.1 1.0)) '(1.0 0.0)))
(check (and (not (run-stop-p 1.4 1.0 8.0)) (run-stop-p 1.3 1.0 8.0)      ; 8 m/s = 0.133 m / f
            (not (run-stop-p 1.0 -1.0 8.0)) (not (run-stop-p 1.25 0.0 10.0))))   ; running away / sideways
(check (and (~= (run-carry 5.0) 1.0) (~= (run-carry 1.7) 0.5) (~= (run-carry 1.0) 0.0)))
(check (and (~= (brake-speed 9.0 3) 4.5) (~= (brake-speed 9.0 6) 0.0) (~= (brake-speed 9.0 9) 0.0)))
(check (and (~= (kit-run (kit :yamamoto :base)) 8.0) (~= (kit-run (kit :kenpachi :base)) 10.0)
            (~= (kit-run (kit :kenpachi :nozarashi)) 10.0) (~= (kit-run (kit :yamamoto :bankai-east)) 8.0)))
;; the run faces the opponent: one clip set per character (every Kenpachi form shares his)
(check (and (equal (kit-run-clips (kit :yamamoto :bankai-west)) '(:sh-run :sh-skate-b :sh-slide-r :sh-slide-l))
            (equal (kit-run-clips (kit :kenpachi :nozarashi)) (kit-run-clips (kit :kenpachi :base)))
            (eq (first (kit-run-clips (kit :kenpachi :base))) :ke-run)))
(check (and (> (getf (kit-ai (kit :kenpachi :base)) :dash) (getf (kit-ai (kit :yamamoto :base)) :dash))   ; Ken dashes more
            (getf (kit-ai (kit :yamamoto :base)) :dash-back)))                                          ; Yama backs off to zone

;;; ================================================================ AI helpers
(check (and (eq (weighted-pick 0.0 :a 1 :b 1) :a) (eq (weighted-pick 0.5 :a 1 :b 1) :b)
            (eq (weighted-pick 0.1 :a 0 :b 1) :b) (null (weighted-pick 0.5 :a 0))))
(let ((bands (getf (kit-ai (kit :yamamoto :base)) :moves)))
  (check (eq (apply #'weighted-pick 0.0 (band-weights bands 6.0)) :sig))   ; Signature at 5-8 m
  (check (eq (apply #'weighted-pick 0.0 (band-weights bands 9.0)) :sp1)))  ; Shiranui beyond 8 m
(check (equal (multiple-value-list (heat-range 6.0 8.0 10.0)) '(3.0 5.0)))
(check (equal (multiple-value-list (heat-range 6.0 8.0 30.0)) '(1.0 1.0)))
(check (and (= (heat-breaker-mult 7.9) 1) (= (heat-breaker-mult 8.0) 2)))
(check (and (~= (heat-after 1.0 nil) (+ 1.0 (/ *ai-heat-rate* 60))) (~= (heat-after 1.0 t) (+ 1.0 (/ *ai-heat-rate* 30)))))

;;; ================================================================ hit volumes
(flet ((hits (v x z &key (y 0f0))
         (vol-hit-p v 0f0 0f0 0f0 0f0 -1f0 (float x 1f0) y (float z 1f0) 0.38f0 1.8f0 0f0)))
  (let ((arc (make-vol :arc '(2.4 100 0.2 2.0))))
    (check (~= (aref arc 2) (deg 50)))
    (check (hits arc 0 -2))
    (check (not (hits arc 0 2)))
    (check (not (hits arc 0 -3)))
    (check (not (hits arc 0 -2 :y 3f0))))
  (check (hits (make-vol :cap '(0.3 8.0 1.0 0.5)) 0.5 -7.5))            ; Nadegiri line
  (check (hits (make-vol :sph '(2.0 0.0 1.0)) 0 -2.5)))
;; world space: a Shiranui / thrust capsule, a skeleton lunge, a fire wall, a pillar
(check (capsule-cyl-hit-p 0f0 1f0 0f0 0f0 1f0 -9f0 0.3f0 0.5f0 0f0 -5f0 0.4f0 1.8f0))
(check (not (capsule-cyl-hit-p 0f0 1f0 0f0 0f0 1f0 -9f0 0.3f0 1.0f0 0f0 -5f0 0.4f0 1.8f0)))
(check (not (capsule-cyl-hit-p 0f0 1f0 0f0 0f0 1f0 -9f0 0.3f0 0f0 0f0 -10f0 0.4f0 1.8f0)))  ; past the end
(check (not (capsule-cyl-hit-p 0f0 3f0 0f0 0f0 3f0 -9f0 0.3f0 0f0 0f0 -5f0 0.4f0 1.8f0)))   ; overhead
(check (capsule-cyl-hit-p 0f0 0.5f0 0f0 2f0 1.5f0 0f0 0.3f0 2.5f0 0f0 0f0 0.4f0 1.8f0))     ; sloped lunge
(check (capsule-cyl-hit-p 0f0 1f0 -5f0 0f0 1f0 -5f0 0.5f0 0.6f0 0f0 -5f0 0.4f0 1.8f0))     ; a ball
(check (obox-cyl-hit-p 0f0 1f0 -5f0 0f0 3f0 1f0 0.5f0 2.5f0 0f0 -5f0 0.4f0 1.8f0))          ; inside the width
(check (not (obox-cyl-hit-p 0f0 1f0 -5f0 0f0 3f0 1f0 0.5f0 3.5f0 0f0 -5f0 0.4f0 1.8f0)))
(check (obox-cyl-hit-p 0f0 1f0 -5f0 0f0 3f0 1f0 0.5f0 0f0 0f0 -5.8f0 0.4f0 1.8f0))          ; its face
(check (not (obox-cyl-hit-p 0f0 1f0 -5f0 0f0 3f0 1f0 0.5f0 0f0 0f0 -6.0f0 0.4f0 1.8f0)))
(let ((yaw (deg 90)))                                                  ; turned: width along Z
  (check (obox-cyl-hit-p 0f0 1f0 -5f0 yaw 3f0 1f0 0.5f0 0f0 0f0 -7.5f0 0.4f0 1.8f0))
  (check (not (obox-cyl-hit-p 0f0 1f0 -5f0 yaw 3f0 1f0 0.5f0 0f0 0f0 -8.5f0 0.4f0 1.8f0))))
(check (not (obox-cyl-hit-p 0f0 1f0 -5f0 0f0 3f0 1f0 0.5f0 0f0 3f0 -5f0 0.4f0 1.8f0)))      ; above it
(check (cyl-cyl-hit-p 3f0 0f0 0f0 0.6f0 3f0 3.8f0 0f0 0f0 0.4f0 1.8f0))
(check (not (cyl-cyl-hit-p 3f0 0f0 0f0 0.6f0 3f0 4.1f0 0f0 0f0 0.4f0 1.8f0)))
(check (not (cyl-cyl-hit-p 3f0 0f0 0f0 0.6f0 3f0 3.5f0 3.5f0 0f0 0.4f0 1.8f0)))            ; airborne above

;;; ================================================================ kit sanity
;;; The §5 tables, copied independently of yama.lisp / ken.lisp: move S A R dmg block (? = no value in §5)
(defparameter *table*
  '((:ya-j1 9 3 12 38 -2) (:ya-j2 8 3 13 38 -2) (:ya-j3 9 3 18 45 -4) (:ya-k1 18 4 20 75 -3)
    (:ya-k2 22 4 24 64 -3) (:ya-k3 22 5 34 88 -20) (:ya-sig 16 ? 26 30 -6) (:ya-taimatsu 16 8 24 120 -14)
    (:ya-nadegiri 20 4 30 240 -16) (:ya-breaker 8 4 18 150 :guard-break) (:ya-kyoku 18 5 26 90 -16)
    (:ya-kaka 20 1 34 0 nil)
    ;; Bankai East / West (DUEL_STRINGS §3.2; the rework's L moves)
    (:ya-e-j1 8 3 12 34 -2) (:ya-e-j2 7 3 13 38 -2) (:ya-e-j3 8 3 18 42 -4) (:ya-e-k1 16 4 20 70 -3)
    (:ya-e-k2 19 4 24 60 -3) (:ya-e-k3 21 5 34 84 -20) (:ya-e-kyokko 15 3 26 85 -12) (:ya-w-shonetsu 16 0 24 0 nil)
    (:ya-w-parry 2 24 20 0 nil) (:ya-w-counter 6 3 24 150 -12)
    (:ke-j1 7 3 12 35 -2) (:ke-j2 7 3 13 35 -2) (:ke-j3 8 3 18 42 -4) (:ke-k1 16 4 20 70 -3)
    (:ke-k2 20 4 24 60 -3) (:ke-k3 20 5 34 80 -20) (:ke-stance 8 4 24 100 -14) (:ke-buttagiru 22 4 26 180 -14)
    (:ke-charge 14 ? ? 25 -16) (:ke-breaker 8 4 18 150 :guard-break) (:ke-meteor 26 4 30 240 ?)
    ;; RYOTE's kendo strings (DUEL_STRINGS §3.4), NOMIHOSE's space cut and cash-out (DUEL_NOZARASHI_V2 §2.3)
    (:ke-r-j1 10 3 12 40 -2) (:ke-r-j2 9 3 13 38 -2) (:ke-r-j3 10 3 18 48 -4) (:ke-r-k1 19 4 20 85 -3)
    (:ke-r-k2 21 4 24 68 -3) (:ke-r-k3 21 5 34 92 -20) (:ke-n-f1 20 4 22 90 -4) (:ke-meteor-n 26 4 30 390 -16)))
(dolist (row *table*)
  (destructuring-bind (name s a r dmg adv) row
    (let ((m (find-move name)))
      (flet ((same (want got) (or (eq want '?) (equal want got))))
        (unless (and (same s (mv-s m)) (same a (mv-a m)) (same r (mv-r m)) (same dmg (mv-dmg m))
                     (same adv (mv-adv-block m)))
          (format t "  table mismatch ~s~%" name))
        (check (and (same s (mv-s m)) (same a (mv-a m)) (same r (mv-r m)) (same dmg (mv-dmg m))
                    (same adv (mv-adv-block m))))))))
(check (equal (map 'list (lambda (w) (list (hw-from w) (hw-dmg w))) (mv-hits (find-move :ya-sig)))
              '((16 30) (28 30))))                                        ; hits f16, f28, 30 each
(check (= 110 (getf (mv-params (find-move :ya-sig)) :dmg)))              ; the wave
(check (equal (mv-hold (find-move :ke-stance)) '(6 60)))
(check (equal (mv-hold (find-move :ya-shiranui)) '(12 60)))

;;; every form: all commands mapped, strings resolve, frames consistent, hooks are symbols
(defparameter *kinds* '(:quick :flash :sig :sp :breaker :kikon))
(dolist (cf *forms*)
  (let ((k (apply #'kit cf)))
    (check (every (lambda (c) (or (kit-command-move k c)      ; (or a command the form removes: Rukia's -50 / zero / THAW)
                                  (member c (loop for (cc m) on (kit-commands k) by #'cddr unless m collect cc))))
                  *kit-commands*))
    (check (every (lambda (s) (and (kit-move k (first s)) (kit-next k (first s) (second s)))) (kit-strings k)))
    (maphash
     (lambda (name m)
       (let ((ok (and (member (mv-kind m) *kinds*)
                      (>= (mv-s m) 0) (>= (mv-a m) 0) (>= (mv-r m) 0) (>= (mv-whiff m) (mv-r m))
                      (every (lambda (w) (and (<= (mv-s m) (hw-from w)) (< (hw-from w) (hw-to w))
                                              (<= (hw-to w) (+ (mv-s m) (mv-a m))) (hw-vols w)))
                             (mv-hits m))
                      (or (eq (mv-kind m) :kikon) (zerop (mv-dmg m)) (plusp (length (mv-hits m))))
                      (every (lambda (e) (and (< (first e) (mv-total m)) (symbolp (second e)))) (mv-on-frame m))
                      (every #'symbolp (list (mv-tick m) (mv-release m) (mv-on-land m) (mv-cine m)))
                      (or (not (eq (mv-kind m) :kikon)) (mv-cine m)))))
         (unless ok (format t "  bad move ~s in ~s~%" name cf))
         (check ok)))
     (kit-moves k))))
;; costs
(check (and (= (kit-command-cost (kit :yamamoto :base) :sp2) 1) (= (kit-command-cost (kit :yamamoto :base) :sp1) 1)
            (= (kit-command-cost (kit :yamamoto :hellfire) :sp2) 2) (= (kit-command-cost (kit :yamamoto :bankai-east) :sp2) 2)
            (= (kit-command-cost (kit :kenpachi :nozarashi) :sp2) 2) (= (kit-command-cost (kit :kenpachi :base) :q) 0)))
;; forms: multipliers, inheritance, the Hellfire / Bankai swaps
(check (and (~= (kit-mult (kit :yamamoto :hellfire)) 1.3) (~= (kit-mult (kit :yamamoto :bankai-east)) 1.0)
            (~= (kit-mult (kit :kenpachi :nozarashi)) 1.0) (~= (kit-mult (kit :kenpachi :ryote)) 1.15) (~= (kit-mult (kit :kenpachi :nomihose)) 1.2) (~= (kit-mult (kit :kenpachi :base)) 1.0)))
(check (eq (mv-name (kit-command-move (kit :yamamoto :hellfire) :sp2)) :ya-nadegiri))
(check (eq (mv-name (kit-command-move (kit :yamamoto :hellfire) :sp1)) :ya-shiranui))  ; inherited
(check (eq (mv-name (kit-command-move (kit :yamamoto :bankai-east) :kikon)) :ya-tenchi))
;; the Kikon rush of every form: a strike with a cinematic, clearly punishable on block (-14; K1 of either character
;; reaches it after the block pushback from the trigger range: J1 did until the J cut of 2026-09-29, now it walks in),
;; reach beyond the trigger
(dolist (cf *forms*)
  (let ((m (kit-command-move (apply #'kit cf) :kikon)))
    (check (and (eq (mv-kind m) :kikon) (mv-cine m) (= 1 (length (mv-hits m))) (<= (mv-adv-block m) -12)
                (> (mv-reach m) *kikon-trigger*) (plusp (mv-dmg m))
                (<= (+ *kikon-trigger* *block-pushback*) (min (mv-reach (mv :yamamoto :base :ya-k1))
                                                              (mv-reach (mv :kenpachi :base :ke-k1))))))))
;; the O modules (design v2 §B): cooldown 90, a melee strike with its cinematic, reach and press -> hit,
;; aura >= 5 (>= 8 for a locked dash), armour <= 1 hit; the melee ones strike from *KIKON-TRIGGER* (a
;; blocked strike stays punishable); ENJO has no dash (a lane, locked)
(defparameter *modules* '((:yamamoto :base :ya-kikon 9.0 26) (:yamamoto :bankai-east :ya-tenchi 10.0 30) (:yamamoto :bankai-west :ya-tenchi 10.0 30)
                          (:kenpachi :base :ke-kikon 9.4 50) (:kenpachi :nozarashi :ke-kikon-n 10.6 49)))
(dolist (row *modules*)
  (destructuring-bind (c f name reach press) row
    (let* ((m (mv c f name)) (p (mv-params m)))
      (flet ((pa (k) (getf p k)))
        (check (and (eq (mv-name (kit-command-move (kit c f) :kikon)) name) (= (mv-cooldown m) 90) (mv-cine m)
                    (= 70 (mv-dmg m)) (= -14 (mv-adv-block m)) (>= (pa :aura) 5) (<= (mv-armor-hits m) 1)
                    (or (plusp (pa :dash-track)) (zerop (pa :dash-max)) (>= (pa :aura) 8))))
        (check (~= reach (max (mv-reach m) (kikon-rush-reach (pa :speed) (pa :dash-max))) 0.01))
        (check (= press (+ (pa :aura) (pa :dash-max) (mv-s m))))))))
(check (and (= (mv-armor-hits (find-move :ke-kikon)) 1) (zerop (mv-armor-hits (find-move :ya-tenchi)))))
(check (and (~= 0.0 (mv-track (find-move :ya-kikon))) (~= 0.0 (getf (mv-params (find-move :ya-tenchi)) :dash-track))
            (~= 0.0 (getf (mv-params (find-move :ke-kikon-n)) :dash-track)) (~= 150.0 (getf (mv-params (find-move :ke-kikon)) :dash-track))))
(check (~= 160 (/ (* 2 (aref (first (hw-vols (svref (mv-hits (find-move :ke-kikon-n)) 0))) 2)) (deg 1))))   ; the widest strike
(check (and (~= (mv-clip-speed (mv :kenpachi :nozarashi :ke-kikon-n)) (/ 8.0 11.0)) (~= (mv-clip-speed (mv :kenpachi :base :ke-kikon)) (/ 8.0 9.0))
            (~= (mv-clip-speed (mv :yamamoto :bankai-east :ya-tenchi)) 1.5)))    ; clips reach their hit pose on frame S
;; cooldowns: every command slot of the fighter's CD vector
(check (= 7 (length *kit-commands*)))
(check (and (null (kit-meter (kit :yamamoto :bankai-east))) (kit-meter (kit :yamamoto :hellfire))))  ; no Hellfire in Bankai
(check (and (kit-awakening (kit :yamamoto :bankai-east)) (not (kit-awakening (kit :yamamoto :hellfire)))
            (null (kit-duration (kit :kenpachi :nozarashi))) (null (kit-duration (kit :yamamoto :bankai-east)))))   ; both awakenings last the match
(check (and (member :ward (kit-passives (kit :yamamoto :bankai-west)))
            (not (member :ward (kit-passives (kit :yamamoto :bankai-east))))))
(check (and (~= (kit-walk (kit :yamamoto :base)) 3.2) (~= (kit-walk (kit :kenpachi :nozarashi)) 4.4)))
(check (~= (kit-reset-reiatsu (kit :kenpachi :base)) 10.0))
;; Nozarashi: derived by the kit, not copied (startup +3, reach x1.4), own moves as written
(let ((base (mv :kenpachi :base :ke-j1)) (noz (mv :kenpachi :nozarashi :ke-j1)))
  (check (and (= (mv-s base) 7) (= (mv-s noz) 9) (= (mv-r noz) 12) (= (mv-dmg noz) 35)
              (~= (mv-reach noz) (* 1.4 1.3)) (= (hw-from (svref (mv-hits noz) 0)) 9)
              (~= (aref (first (hw-vols (svref (mv-hits noz) 0))) 1) (* 1.4 1.3)))))
(check (= (mv-s (mv :kenpachi :nozarashi :ke-stance)) 10))
(check (= (mv-s (mv :kenpachi :nozarashi :ke-breaker)) 10))
(check (~= (aref (first (hw-vols (svref (mv-hits (mv :kenpachi :nozarashi :ke-charge)) 0))) 2) (* 1.4 1.3)))
(check (= (mv-s (mv :kenpachi :nozarashi :ke-meteor)) 26))
(check (eq (mv :kenpachi :nozarashi :ke-meteor) (find-move :ke-meteor)))
(check (eq (kit-next (kit :kenpachi :nozarashi) :ke-j1 :q) (mv :kenpachi :nozarashi :ke-j2)))
;; clip names: exactly the §5 contract, and every §5 clip is used
(defparameter *clips-5*
  '(:ya-stance :ya-q1 :ya-q2 :ya-q3 :ya-f1 :ya-f2 :ya-sig :ya-shiranui :ya-shiranui-throw :ya-taimatsu
    :ya-nadegiri :ya-breaker :ya-ikkotsu :ya-intro :ya-win :ya-hellfire :ya-bankai :ya-kyoku
    :ya-kaka :sh-run :ya-enjo :ke-n-leap ; the O modules (TENCHI runs in :sh-run, CHARGE in :ke-charge)
    :ya-e-thrust :ya-shonetsu :ya-w-parry :ya-w-counter   ; the Bankai stances
    :ya-sleeve :ya-e-drop :ke-kick :ke-r-kote :ke-r-tsuki   ; the strings' new clips (DUEL_STRINGS §3)
    :ke-stance :ke-q1 :ke-q2 :ke-q3 :ke-f1 :ke-f2 :ke-stance-hold :ke-stance-cut :ke-buttagiru :ke-charge
    :ke-flurry :ke-breaker :ke-shoulder :ke-intro :ke-win :ke-release :ke-nome :ke-meteor
    :ke-n-stance
    :sh-skate-b :sh-slide-r :sh-slide-l :ke-run :ke-skate-b :ke-slide-r :ke-slide-l   ; the runs (facing the opponent)
    :ke-r-stance :ke-drink     ; the cups
    :ke-r-q1 :ke-r-q3 :ke-r-f1 :ke-r-f2 :ke-n-f1     ; RYOTE's kendo set and KUKAN-GIRI (their own clips since Phase 5)
    :ke-b-stance :ke-b-fist :ke-b-bite                ; the Bankai (docs/duel/DUEL_KEN_BANKAI.md §12)
    :ke-b-hook :ic-cross-j :ic-k-jab :ic-k-wrap-j     ; the J cut's close J links (DUEL_STRINGS §13)
    :ke-b-leap :ke-b-run :ke-b-skate-b :ke-b-slide-r :ke-b-slide-l   ; its feral pass (2026-09-28; also 片腕)
    :ru-stance :ru-intro :ru-win :ru-q1 :ru-q2 :ru-spin :ru-thrust :ru-ring :ru-drop :ru-tsukishiro :ru-stab :ru-hakuren
    :ru-shirafune :ru-breaker :ru-hainawa :ru-cold-stance :ru-palm :ru-flower :ru-zero :ru-reido :ru-hakka   ; Rukia
    :ru-palm-50 :ru-spin-50 :ru-flower-50 :ru-stab-2h   ; her -50 key edits (zero's pinned J1 / K1 are body-variant clips)
    :ic-stance :ic-intro :ic-win :ic-q1 :ic-q2 :ic-spin :ic-f1 :ic-f2 :ic-drop :ic-cross :ic-getsuga :ic-juji :ic-breaker
    :ic-mine :ic-k-stance :ic-k-back :ic-k-parry :ic-k-yank :ic-k-zanzo   ; Ichigo (DUEL_ICHIGO §10, v2)
    :ic-tsuki :ic-rangetsu :ic-tsuki-otoshi
    :sj-stance :sj-q1 :sj-q2 :sj-spin :sj-f1 :sj-f2 :sj-drop :sj-yank :sj-summon :sj-kasa :sj-breaker :sj-saidan :sj-intro
    :sj-win :sj-loom-stance :sj-weave :sj-unravel :sj-tanmono :sj-makitori :sj-snip   ; Senjumaru (:sj-awaken is the cine's)
    :lb-stance :lb-intro :lb-win :lb-q1 :lb-q2 :lb-jab :lb-f1 :lb-f2 :lb-f3 :lb-aim :lb-fire :lb-sanren :lb-hiren
    :lb-breaker :lb-butt :lb-w-stance :lb-w-fold :lb-w-q1 :lb-w-q2 :lb-w-q3 :lb-w-f1 :lb-w-f2 :lb-w-f3 :lb-w-aim :lb-w-fire
    :lb-w-nijushi :lb-w-breaker :lb-w-ram :lb-o-stance :lb-o-q1 :lb-o-q2 :lb-o-q3 :lb-o-f1 :lb-o-f2 :lb-o-f3 :lb-o-chop
    :lb-o-trompete :lb-o-breaker :lb-o-stamp      ; Lille (DUEL_LILLE §12 Art)
    :lb-kamae :lb-k-shot :lb-k-hosha :lb-k-taisha :lb-k-dash :lb-w-tenshin :lb-w-tenshin-in   ; his rework (DUEL_LILLE §22, §23)
    :lb-oe-stance :lb-o-fold :lb-oe-fold :lb-oe-sabaki :lb-o-tenshin :lb-o-tenshin-in))   ; the owl on Jilliel's system (decision 36, §23.14)
;; (the Kikon cinematics' own clips, :ya-kikon :ya-tenchi :ke-kikon :ke-kikon-n, are played by their
;; DEFCINEs, which the host stubs; KESSA's clones play :ic-k-cut / :ic-k-wrap, ICHIGO-CLONE-STEP)
(let ((used (remove-duplicates (loop for cf in *forms* append (kit-clips (apply #'kit cf))))))
  (let ((extra (set-difference used *clips-5*)) (unused (set-difference *clips-5* used)))
    (when (or extra unused) (format t "  clips not in §5: ~s, §5 clips unused: ~s~%" extra unused))
    (check (and (null extra) (null unused)))))
;; phase 2: art names, roster, form looks, the flurry, hazard hits
(check (equal (mapcar #'kit-weapon (mapcar (lambda (cf) (apply #'kit cf)) *forms*))
              '(:ryujin-jakka :ryujin-jakka :zanka :zanka :ken-katana :nozarashi :nozarashi :nozarashi :ke-broken :ke-broken
                :sode-no-shirayuki :sode-no-shirayuki :ru-rime :ru-ice :zangetsu-long :tensa
                :shigarami :shigarami :shigarami :shigarami :shigarami :shigarami :shigarami
                :diagramm nil nil nil nil nil nil nil nil)))
(check (equal *roster* '(:yamamoto :kenpachi :rukia :ichigo :senjumaru :lille)))   ; Lille appended last (DUEL_LILLE §0)
(check (equal (kit-intro-weapon (kit :yamamoto :base)) '(:ya-cane 81)))              ; cane until 1.35 s
(check (and (eq (kit-cine (kit :yamamoto :bankai-east)) 'yama-bankai-cine) (eq (kit-cine (kit :kenpachi :nozarashi)) 'ken-nozarashi-cine)
            (null (kit-cine (kit :yamamoto :hellfire)))))
(check (and (equal (kit-blade (kit :yamamoto :hellfire)) '(:fire 1.3)) (eq (kit-grade (kit :yamamoto :bankai-east)) :spot)
            (null (kit-blade (kit :kenpachi :base)))))
(check (and (mv-planted (find-move :ya-breaker)) (~= (mv-blend (find-move :ke-stance)) 6)))
(let ((fl (find-move :ke-flurry)))                                          ; 4 more cuts + the launcher
  (check (and (= 5 (length (mv-hits fl))) (= 60 (hw-dmg (svref (mv-hits fl) 4))) (eq :launch (hw-react (svref (mv-hits fl) 4)))
              (= (+ 25 (* 4 25) 60) (+ (mv-dmg (find-move :ke-charge)) (loop for w across (mv-hits fl) sum (hw-dmg w)))))))
(check (and (null (hw-stun (make-hitwin))) (= 40 (hw-stun (make-hitwin :stun 40)))))

;;; ================================================================ Bankai stances (docs/duel/DUEL_YAMA_REWORK.md, the user's decisions 2026-09-27)
(let ((east (kit :yamamoto :bankai-east)) (west (kit :yamamoto :bankai-west)))
  ;; the forms: East x1.0 dealt + the pierce, x*BANKAI-TAKEN* 1.5 taken, projectile-cut; U goes West (:guard-to). West
  ;; x1.0 / x1.0, the ward + the parry's scorch; every command but L / SP1 drops to East (:drop-to / :keep); both
  ;; awakened and permanent
  (check (and (~= (kit-mult east) 1.0) (~= (kit-taken east) 1.5) (~= *bankai-taken* 1.5) (null (kit-blade-chip east))
              (equal (kit-passives east) '(:projectile-cut :pierce)) (eq (kit-guard-to east) :bankai-west)
              (null (kit-drop-to east))))
  (check (and (~= (kit-mult west) 1.0) (~= (kit-taken west) 1.0) (null (kit-blade-chip west))
              (equal (kit-passives west) '(:ward :scorch)) (null (kit-guard-to west))
              (eq (kit-drop-to west) :bankai-east) (equal (kit-keep west) '(:sig :sp1))))
  (check (and (kit-awakening west) (null (kit-duration west)) (eq (kit-awaken-form (kit :yamamoto :base)) :bankai-east)
              (null (kit-guard-to (kit :yamamoto :base))) (null (kit-drop-to (kit :kenpachi :nomihose)))))
  (check (and (eq (mv-name (kit-command-move east :sp1)) :ya-kyoku) (eq (mv-name (kit-command-move west :sp1)) :ya-w-parry)
              (eq (mv-name (kit-command-move east :sig)) :ya-e-kyokko) (eq (mv-name (kit-command-move west :sig)) :ya-w-shonetsu)))
  ;; East <-> West (fighter.lisp KIT-DROP): in West J, K, O, I, Shift+L drop to East first (East's own move starts),
  ;; L and Shift+K stay West; East drops nothing
  (check (and (every (lambda (c) (eq (kit-drop west c) :bankai-east)) '(:q :f :sp2 :breaker :kikon))
              (null (kit-drop west :sig)) (null (kit-drop west :sp1))
              (notany (lambda (c) (kit-drop east c)) *kit-commands*)
              (eq (kit-command-move (find-kit :yamamoto (kit-drop west :q)) :q) (kit-command-move east :q))))
  (check (and (= (hit-damage 100 nil (kit-def-mods east) 1 nil) 150) (= (hit-damage 100 nil (kit-def-mods west) 1 nil) 100)))
  ;; the derivation rule: East's inherited moves derived (-1 f; reach x1.15, but a Breaker's stays unscaled); West takes East's versions
  (check (and (= (mv-s (kit-command-move east :breaker)) 7) (~= (mv-reach (kit-command-move east :breaker)) *breaker-reach* 0.01)
              (eq (kit-move west :ya-e-j2) (kit-move east :ya-e-j2)) (eq (kit-command-move west :q) (kit-command-move east :q))))
  (check (and (= (mv-s (kit-move east :ya-e-j1)) 8) (= (mv-s (kit-move east :ya-e-j3)) 8) (= (mv-s (kit-move west :ya-w-counter)) 6)))
  (dolist (name '(:ya-kaka :ya-tenchi))
    (let ((a (kit-move east name)) (b (kit-move west name)))
      (check (and (eq a b) (= (mv-s a) (mv-s (find-move name))) (equal (mv-on-frame a) (mv-on-frame b))))))
  (check (~= (mv-clip-speed (kit-move east :ya-e-j2)) (/ 8.0 7.0)))            ; Shikai's clip at East's -1 f plays faster
  ;; KYOKKO cancels a landed J2 in time; a blocked J1 -> J2 leaves a gap >= Step's first iframe and < 7
  (let* ((k east) (q1 (kit-command-move k :q)) (q2 (kit-next k (mv-name q1) :q)))
    (check (< (- (mv-s (kit-command-move k :sig)) (hitstun (hw-react (svref (mv-hits q2) 0)))) 0))
    (check (and (>= (blocked-gap q1 q2) (first *step-iframes*)) (< (blocked-gap q1 q2) 7))))
  ;; the ender-gap rule: after a string ender that leaves the victim near, his Step fits before the next E-Q1
  (progn
    (check (= 5 (on-hit-adv (find-move :ya-e-j3))))
    (dolist (m (loop for (nil nil to) in (kit-strings east) collect (kit-move east to)))
      (let ((w (svref (mv-hits m) 0)))
        (when (or (member (hw-react w) '(:flinch :stagger)) (and (eq (hw-react w) :knockback) (<= (hw-kb w) 1.5)))
          (check (>= (- (mv-s (kit-command-move east :q)) (on-hit-adv m)) (first *step-iframes*)))))))
  ;; KYOKKO: S15 A3 R26, 85, a 1.6 m lunge, a 4.6 m line, pierce x2, guard 22 (an ender), cooldown 100, cancels a landed
  ;; Q / F; no armour anywhere in either stance
  (let* ((l (kit-command-move east :sig)) (w (svref (mv-hits l) 0)))
    (check (and (eq (mv-kind l) :sig) (member :cancel (mv-flags l)) (= (mv-cooldown l) 100) (~= (mv-slide l) 1.6)
                (~= (getf (mv-params l) :pierce-mult) 2.0) (= (hw-guard w) 22) (eq (hw-react w) :knockback)
                (~= (aref (first (hw-vols w)) 2) 4.6) (> (mv-cooldown l) (+ (mv-total l) *chain-lead*)))))
  ;; SHONETSU JIGOKU: S16 R24 (40 f, no hit window: the pillars do it), on-frames 0 (the tell) and 16, 45 x 2 in a 2 m
  ;; ring, guard 12, cooldown 150, not a cancel (a West Q / F would already have dropped him to East)
  (let* ((l (kit-command-move west :sig)) (pa (mv-params l)))
    (check (and (eq (mv-kind l) :sig) (zerop (length (mv-hits l))) (= (mv-total l) 40) (= (mv-cooldown l) 150)
                (not (member :cancel (mv-flags l))) (equal (mapcar #'first (mv-on-frame l)) '(0 16))
                (= (getf pa :dmg) 45) (= (getf pa :hits) 2) (~= (getf pa :size) 2.0) (= (getf pa :guard) 12)
                (= (move-end-frame (mv-s l) (mv-a l) (mv-r l) (mv-whiff l) nil t) 40))))
  (check (every (lambda (m) (zerop (mv-armor-hits (find-move m)))) '(:ya-e-kyokko :ya-w-shonetsu :ya-w-parry :ya-w-counter)))
  ;; KYOKUJITSUJIN: the blade [18,20) breaks guard (and a ward), the tip's cone [20,23) 25 deg x 9 m, 130, knockback
  ;; 4 m, blockable (never a break), -16; the blade's short knockback keeps the victim in the cone
  (let* ((m (kit-command-move east :sp1)) (bl (svref (mv-hits m) 0)) (co (svref (mv-hits m) 1)))
    (check (and (= 2 (length (mv-hits m))) (= (hw-from bl) 18) (= (hw-to bl) 20 (hw-from co)) (= (hw-to co) 23)
                (= (hw-dmg bl) 90) (= (hw-dmg co) 130) (equal (hw-flags bl) '(:guard-crush)) (equal (hw-flags co) '(:ranged))
                (eq (hw-react bl) :knockback) (~= (hw-kb bl) 0.5) (eq (hw-react co) :knockback) (~= (hw-kb co) 4.0)
                (= (mv-adv-block m) -16) (= (hw-guard co) 22)))
    (check (and (~= (aref (first (hw-vols co)) 1) 9.0) (~= (* 2 (aref (first (hw-vols co)) 2)) (deg 25))))
    (check (and (eq (resolve-contact :guard :guard-crush (member :guard-crush (hw-flags bl))) :guard-break)
                (eq (resolve-contact :guard :guard-crush (member :guard-crush (hw-flags bl)) :ward t) :guard-break)
                (eq (resolve-contact :guard :guard-crush (member :guard-crush (hw-flags co))) :blocked)))
    (flet ((hits (v x z) (vol-hit-p v 0f0 0f0 0f0 0f0 -1f0 (float x 1f0) 0f0 (float z 1f0) 0.36f0 1.65f0 0f0)))
      (check (and (hits (first (hw-vols co)) 0 -8.5) (hits (first (hw-vols co)) 2.0 -8.5) (not (hits (first (hw-vols co)) 3.0 -8.5))
                  (not (hits (first (hw-vols co)) 0 -9.6)) (hits (first (hw-vols bl)) 0 -2.0) (not (hits (first (hw-vols bl)) 0 -3.2))))))
  ;; the ward vs Kenpachi: his base J J J blocked = 24 x*WARD-MULT* 1.1 = 26.4: the 4th string crushes a full
  ;; gauge; RYOTE's K K K (the cut) 69 x 1.1 = 75.9: the 2nd
  (flet ((gv (k name) (hw-guard (svref (mv-hits (kit-move k name)) 0))))
    (let ((qs (* *ward-mult* (+ (gv (kit :kenpachi :base) :ke-j1) (gv (kit :kenpachi :base) :ke-j2) (gv (kit :kenpachi :base) :ke-j3))))
          (kk (* *ward-mult* (+ (cut-value (gv (kit :kenpachi :ryote) :ke-r-k1) :flash) (cut-value (gv (kit :kenpachi :ryote) :ke-r-k2) :flash)
                                (cut-value (gv (kit :kenpachi :ryote) :ke-r-k3) :flash)))))
      (check (and (< (* 3 qs) *gg-max*) (>= (* 4 qs) *gg-max*) (< kk *gg-max*) (>= (* 2 kk) *gg-max*)))))
  ;; GOKUI GAESHI: the parry catches a melee hit on f2-25 (24 f = its active frames; Ichigo's window, 2026-10-01), not a hazard, not an
  ;; unguardable one; a Breaker breaks it; parried = a block for the attacker (no string, no Kikon); the counter
  ;; (150, knockback) lands inside the parried attacker's stagger: guaranteed
  (let ((p (kit-command-move west :sp1)) (c (kit-next west :ya-w-parry :land)))
    (check (and (not (parry-frame-p 1)) (parry-frame-p 2) (parry-frame-p 25) (not (parry-frame-p 26))
                (= (mv-a p) (1+ (- (second *parry-window*) (first *parry-window*)))) (= (mv-s p) (first *parry-window*))
                (member :parry (mv-flags p)) (zerop (length (mv-hits p))) (= (mv-total p) 46) (= (kit-command-cost west :sp1) 1)))
    (check (and (eq (resolve-contact :parry) :parried) (eq (resolve-contact :parry :in-front nil) :parried)
                (eq (resolve-contact :parry :breaker t) :stance-break) (eq (resolve-contact :parry :hazard t) :hit)
                (eq (resolve-contact :parry :unguardable t) :hit) (eq (contact-of :parried) :block)
                (null (kikon-outcome t :parried nil))))
    (check (and (eq (mv-name c) :ya-w-counter) (= (mv-dmg c) 150) (eq (hw-react (svref (mv-hits c) 0)) :knockback)
                (< (1+ (mv-s c)) *parry-stun*) (= *parry-stun* 32) (= *scorch* 15))))
  ;; South, the bind: 20/1/34 (55 f), 2 bars and no cooldown (the user's decision 2026-09-28: the bars are its limiter); the
  ;; grab 16 f after the stab; 40 + bound 60; the follow-up window 41; unguardable (guard, stance, armour, parry
  ;; don't stop it; iframes do); it only opens a combo (else a flinch) and books 2 hits: 70 flash-step Bursts out
  (let* ((m (kit-command-move east :sp2)) (pa (mv-params m)))
    (check (and (= (mv-total m) 55) (= (kit-command-cost east :sp2) 2) (= (mv-cooldown m) 0) (member :bind (mv-flags m))
                (= (getf pa :delay) 16) (= (getf pa :dmg) 40) (= (getf pa :stun) *bind-stun* 60) (~= (getf pa :range) 10.0)
                (= 41 (- (+ (mv-s m) (getf pa :delay) (getf pa :stun)) (mv-total m)))))
    (check (and (eq (resolve-contact :guard :unguardable t) :hit) (eq (resolve-contact :stance :unguardable t) :hit)
                (eq (resolve-contact :armor :unguardable t) :hit) (eq (resolve-contact :parry :unguardable t :hazard t) :hit)
                (null (resolve-contact :invuln :unguardable t))))
    (check (equal (multiple-value-list (combo-step :bind nil 0 0 0)) '(:bind 2 0 0)))       ; the opener: 2 hits
    (check (equal (multiple-value-list (combo-step :bind nil 1 0 0)) '(:flinch 2 0 0)))     ; in a combo: a flinch
    (check (and (burst-allowed-p (burst-mode :stun nil (nth-value 1 (combo-step :bind nil 0 0 0)) nil) *fs-burst* nil)
                (not (burst-allowed-p (burst-mode :stun nil (nth-value 1 (combo-step :bind nil 0 0 0)) nil) (1- *fs-burst*) nil))))
    (check (equal (multiple-value-list (combo-step :flinch nil 2 0 0)) '(:flinch 3 0 0)))   ; the follow-up is hit 3
    ;; the escapes: a Step pressed from the stab's f16 carries him past the grab disc; one pressed f28-33 has
    ;; its iframes over the grab (f36-37); a Hoho pressed f23-35 too; walking doesn't (16 f of walk < the disc)
    (let ((grab (+ (mv-s m) (getf pa :delay))) (r (+ (getf pa :radius) 0.45)))
      (check (and (= grab 36) (> *step-distance* r) (< (* *walk-kenpachi* (/ (getf pa :delay) 60.0)) r)
                  (<= (+ 33 (first *step-iframes*)) grab) (>= (+ 28 (second *step-iframes*)) (1+ grab))
                  (<= (+ 35 (first *hoho-iframes*)) grab) (>= (+ 23 (second *hoho-iframes*)) (1+ grab)))))
    (multiple-value-bind (x z) (cast-point 0.0 0.0 12.0 0.0 10.0) (check (and (~= x 10.0) (~= z 0.0))))
    (multiple-value-bind (x z) (cast-point 0.0 0.0 3.0 4.0 10.0) (check (and (~= x 3.0) (~= z 4.0))))))

;;; ================================================================ Nozarashi v2: NOME, the three-cup ladder (§2.13)
(let* ((t1 (kit :kenpachi :nozarashi)) (t2 (kit :kenpachi :ryote)) (t3 (kit :kenpachi :nomihose))
       (m (kit-meter t1)) (ladder (getf m :ladder)) (gains (kit-meter-gain t1)))
  ;; 1. nome-gain: three sources only
  (check (and (~= (nome-gain 125 0 0 gains) 10.0) (~= (nome-gain 0 200 0 gains) 24.0) (~= (nome-gain 0 0 62 gains) 18.6)
              (~= (nome-gain 0 18 17 gains) (+ 2.16 5.1))))
  ;; 2. meter-drain: cup 1 never, cup 2 3/s after 180 idle frames (the user 2026-09-29: x2 of guard v3's 1.5), cup 3
  ;; 20/s from the first frame (a gain doesn't pause it)
  (flet ((dr (i nome idle) (let ((r (nth i ladder))) (meter-drain nome (second r) (third r) idle))))
    (check (and (~= (dr 0 30.0 999) 30.0) (~= (dr 1 50.0 179) 50.0) (~= (dr 1 50.0 180) 49.95) (~= (dr 2 90.0 0) (- 90.0 (/ 20.0 60)))
                (~= (dr 2 0.05 0) 0.0))))
  ;; 3. ladder-rung: hysteresis, several steps at once
  (check (and (= 0 (ladder-rung 39.9 0 ladder)) (= 1 (ladder-rung 40.0 0 ladder)) (= 1 (ladder-rung 25.0 1 ladder))
              (= 0 (ladder-rung 24.9 1 ladder)) (= 2 (ladder-rung 100.0 1 ladder)) (= 2 (ladder-rung 100.0 0 ladder))
              (= 2 (ladder-rung 50.0 2 ladder)) (= 1 (ladder-rung 49.9 2 ladder)) (= 0 (ladder-rung 0.0 2 ladder))))
  (check (equal (mapcar #'first ladder) '(:nozarashi :ryote :nomihose)))
  (check (and (~= (getf m :start) 10.0) (~= (getf m :max) 100.0)))
  ;; 4. drink-split: the taken half rounded up (real damage: at 1 Reishi a drink of 1 Soul Breaks)
  (check (and (equal (multiple-value-list (drink-split 35)) '(18 17)) (equal (multiple-value-list (drink-split 1)) '(1 0))
              (soul-break-p (- 1 (drink-split 1)))))
  ;; 5. drink as a guard: the guard's triangle (Breaker -> Guard Break, unguardable / behind -> hit), drink-adv
  (check (and (eq (resolve-contact :guard :breaker t) :guard-break) (eq (resolve-contact :guard :unguardable t) :hit)
              (eq (resolve-contact :guard :in-front nil) :hit) (= (drink-adv -2) -6) (= (drink-adv -12) -16)))
  (check (and (member :drink (kit-passives t3)) (not (member :drink (kit-passives t2))) (not (member :drink (kit-passives t1)))))
  ;; 6. the cut: Flash / Signature / SP x1.5 (RYOTE, NOMIHOSE), the J string untouched: blocked RYOTE J J J = 24,
  ;; K K K = 69 (into West's ward too: x*WARD-MULT*)
  (flet ((gv (k name) (hw-guard (svref (mv-hits (kit-move k name)) 0))))
    (check (and (= (cut-value 8 :quick) 8) (= (cut-value 14 :flash) 21) (= (cut-value 22 :sp) 33) (= (cut-value 12 nil) 12)))
    (check (= 24 (+ (cut-value (gv t2 :ke-r-j1) :quick) (cut-value (gv t2 :ke-r-j2) :quick) (cut-value (gv t2 :ke-r-j3) :quick))))
    (check (= 69 (+ (cut-value (gv t2 :ke-r-k1) :flash) (cut-value (gv t2 :ke-r-k2) :flash) (cut-value (gv t2 :ke-r-k3) :flash)))))
  ;; the ranged hits (guard v3): the Meteor, the cash-out, Buttagiru's crack, the heat cone, Taimatsu, Nadegiri are
  ;; :ranged; the blades (the J / K strings, the Kikon strikes, KYOKUJITSUJIN's guard-breaking blade) are not
  (flet ((rw (name i) (member :ranged (hw-flags (svref (mv-hits (find-move name)) i)))))
    (check (and (rw :ke-meteor 0) (rw :ke-meteor-n 0) (rw :ke-buttagiru 0) (rw :ya-kyoku 1) (rw :ya-taimatsu 0) (rw :ya-nadegiri 0)
                (not (rw :ya-kyoku 0)) (not (rw :ke-r-k1 0)) (not (rw :ke-kikon-n 0)) (not (rw :ya-kikon 0)) (not (rw :ke-n-f1 0)))))
  (check (and (member :cut (kit-passives t2)) (member :cut (kit-passives t3)) (not (member :cut (kit-passives t1)))))
  ;; 7. the Kikon count per cup (read at rush start) with the per-event cap
  (check (and (= 2 (kit-kikon-konpaku t1)) (= 3 (kit-kikon-konpaku t2)) (= 4 (kit-kikon-konpaku t3))
              (= 2 (kit-kikon-konpaku (kit :kenpachi :base))) (= 3 (kit-kikon-konpaku (kit :yamamoto :bankai-east)))
              (= 2 (kit-kikon-konpaku (kit :yamamoto :hellfire)))))
  (check (and (= 2 (nth-value 1 (kikon-result 9 2 nil))) (= 3 (nth-value 1 (kikon-result 9 2 t)))
              (= 3 (nth-value 1 (kikon-result 9 3 nil))) (= 4 (nth-value 1 (kikon-result 9 3 t)))
              (= 4 (nth-value 1 (kikon-result 9 4 nil))) (= 5 (nth-value 1 (kikon-result 9 4 t)))))   ; Kikon cap 4, Soul Break 5
  ;; the Soul Break rule (the user's decision 2026-09-27): the attacker's current count + 1, capped at 5 (a Kikon at 4);
  ;; NOMIHOSE's Soul Break = 5; the cinematic is the attacker's current form's Kikon cinematic
  (check (and (= 4 (nth-value 1 (kikon-result 9 5 nil))) (= 5 (nth-value 1 (kikon-result 9 5 t)))
              (= 5 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku t3) t))) (= 3 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku t1) t)))
              (= 4 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku t2) t))) (= 2 (nth-value 1 (kikon-result 2 (kit-kikon-konpaku t3) t)))
              (= 5 *soul-break-max-event*) (= 4 *kikon-max-event*)))
  (check (and (eq 'ken-kikon-cine (kit-kikon-cine (kit :kenpachi :base))) (eq 'ken-sky-split-cine (kit-kikon-cine t1))
              (eq 'ken-sky-split-cine (kit-kikon-cine t2)) (eq 'ken-sky-split-cine (kit-kikon-cine t3))
              (eq 'yama-kikon-cine (kit-kikon-cine (kit :yamamoto :base))) (eq 'yama-kikon-cine (kit-kikon-cine (kit :yamamoto :hellfire)))
              (eq 'yama-tenchi-cine (kit-kikon-cine (kit :yamamoto :bankai-east)))
              (eq 'yama-tenchi-cine (kit-kikon-cine (kit :yamamoto :bankai-west)))))
  ;; 8. register-kit: NOMIHOSE plays RYOTE's moves (not re-derived); RYOTE's meteor / LEAP as written; Hellfire unchanged
  (check (and (eq (kit-move t3 :ke-r-j3) (kit-move t2 :ke-r-j3)) (= 10 (mv-s (kit-move t3 :ke-r-j3)))
              (= 21 (mv-s (kit-move t3 :ke-r-k3))) (eq (kit-move t3 :ke-r-j2) (kit-move t2 :ke-r-j2))
              (~= (mv-reach (kit-move t2 :ke-r-j2)) 1.44) (~= (mv-reach (kit-move t2 :ke-r-j3)) 1.52)))
  (check (and (eq (kit-move t2 :ke-meteor) (find-move :ke-meteor)) (eq (kit-move t2 :ke-kikon-n) (find-move :ke-kikon-n))
              (eq (kit-command-move t3 :kikon) (find-move :ke-kikon-n))
              (eq (kit-move (kit :yamamoto :hellfire) :ya-j1) (find-move :ya-j1))))
  (check (and (= 10 (mv-s (kit-move t1 :ke-stance))) (= 11 (mv-s (kit-move t2 :ke-stance))) (= 11 (mv-s (kit-move t3 :ke-stance)))))
  ;; 9. the links: every J / K pair of every form combos (the string budget above); cup 3's K1 KUKAN-GIRI -> K2 too
  (check (< (hit-gap (kit-move t3 :ke-n-f1) (kit-next t3 :ke-n-f1 :f)) 0))
  ;; 10. the rift: at f20, cuts f40 (a 2 f window), 50 x1.2, guard 12, chip 20 %; on block inside N-F1's blockstun
  ;; (he acts at f43, the rift's 14 f blockstun frees the defender at f55: +8)
  (let* ((n (kit-move t3 :ke-n-f1)) (pa (mv-params n)) (bs (blockstun (mv-total n) (mv-s n) (mv-adv-block n))))
    (check (and (equal (mv-on-frame n) '((20 ken-rift))) (= 40 (+ 20 *rift-delay*)) (= 50 (getf pa :rift-dmg))
                (= 12 (getf pa :rift-guard)) (~= 0.2 (getf pa :rift-chip))
                (< (+ 20 *rift-delay*) (+ (mv-s n) bs))                         ; the rift cuts inside the blockstun
                (= 8 (- (+ 20 *rift-delay* *hazard-blockstun* 1) (1+ (mv-total n)))))))
  ;; 11. the cash-out: NOME 0 and cup 1 on its first frame, 390, the guard break only within 6 m
  (let ((c (kit-command-move t3 :sp1)))
    (check (and (eq (mv-name c) :ke-meteor-n) (= 390 (mv-dmg c)) (equal (first (mv-on-frame c)) '(0 ken-drink-dry))
                (~= 6.0 (getf (mv-params c) :crush-range)) (= -16 (mv-adv-block c)) (= 22 (hw-guard (svref (mv-hits c) 0)))
                (= 390 (hit-damage 390 (kit-atk-mods t1 0) nil 1 nil)))))
  ;; the looks: one hand in cup 1, two hands in cups 2 / 3; the HUD names
  (check (and (eq (kit-stance t1) :ke-n-stance) (eq (kit-stance t2) :ke-r-stance) (eq (kit-stance t3) :ke-r-stance)
              (equal (mapcar #'kit-form-name (list t1 t2 t3)) '("KATATE" "RYOTE" "NOMIHOSE"))
              (eq (kit-aura t3) :nomihose) (eq (kit-drink-clip t3) :ke-drink) (equal (kit-respect-callout t2) "OMOSHIREE!")))
  ;; AI keys: the Kikon chance by cup, the cash-out rule (the near cash-out below 55 since the 2x drain: DUEL_NOZARASHI_V2.md,
  ;; "The CPU after the faster drain")
  (check (and (~= 0.25 (getf (kit-ai t1) :kikon-p)) (~= 0.5 (getf (kit-ai t2) :kikon-p)) (~= 0.9 (getf (kit-ai t3) :kikon-p))
              (equal (getf (kit-ai t3) :cashout) '(:punish 30 :near 6.0 :below 55.0)) (null (getf (kit-ai t2) :cashout)))))

;;; ================================================================ Kenpachi's Bankai and 片腕 (docs/duel/DUEL_KEN_BANKAI.md, the user's decisions 2026-09-28)
(let ((b (kit :kenpachi :bankai)) (a (kit :kenpachi :kataude)) (t3 (kit :kenpachi :nomihose)))
  ;; 1. entry: P, free and red; only cup 3 has it (once a match: nothing after it does)
  ;; the entry (2026-09-28): free with <= 4 of his own Konpaku (no longer red)
  (check (and (= *bankai-konpaku* 4) (bankai-allowed-p t 4) (bankai-allowed-p t 1) (not (bankai-allowed-p nil 4))
              (not (bankai-allowed-p t 5)) (not (bankai-allowed-p t 9))))
  (check (equal (loop for cf in *forms* when (kit-bankai-form (apply #'kit cf)) collect cf)
              '((:kenpachi :nomihose) (:lille :jilliel) (:lille :jilliel-mujittai) (:lille :jilliel-kin)
                (:lille :jilliel-kin-mujittai))))   ; (+ Lille's revive from every Jilliel form, DUEL_LILLE §6.1, decision 16)
  (check (and (eq (kit-bankai-form t3) :bankai) (eq (kit-cine b) 'ken-bankai-cine) (kit-awakening b) (kit-awakening a)))
  ;; 2. the arm: 4 pips; spend 4 -> 3, 0 refused; the crack at 300 f, idle back to 0; locked frames don't count;
  ;; 4 cracks = 1200 f of play
  (check (and (equal (multiple-value-list (pip-spend 4)) '(3 t)) (equal (multiple-value-list (pip-spend 0)) '(0 nil))
              (= 4 *arm-pips*) (= 300 *arm-crack*)))
  (check (and (equal (multiple-value-list (pip-step 4 298 nil)) '(4 299 nil)) (equal (multiple-value-list (pip-step 4 299 nil)) '(3 0 t))
              (equal (multiple-value-list (pip-step 4 299 t)) '(4 299 nil)) (equal (multiple-value-list (pip-step 0 5 nil)) '(0 6 nil))))
  (check (= 1200 (let ((p 4) (i 0) (n 0)) (loop while (plusp p) do (multiple-value-setq (p i) (pip-step p i nil)) (incf n)) n)))
  ;; 3. the pending burst: waits in the move that spent the last pip, in reactions / blockstun / air / down / Hoho, fires
  ;; on anything else (a later move included)
  (let ((m1 (kit-move b :ke-b-k1)) (m2 (kit-move b :ke-b-j1)))
    (check (and (not (burst-due-p m1 m1 :move)) (burst-due-p m1 m2 :move) (burst-due-p m1 nil :idle) (burst-due-p :none nil :guard)
                (not (burst-due-p m1 nil :stun)) (not (burst-due-p m1 nil :hoho)) (not (burst-due-p m1 nil :air))
                (not (burst-due-p m1 nil :guard-hit)) (not (burst-due-p nil nil :idle)) (burst-due-p :none m2 :move))))
  ;; 4. rend: armour -> a hit, a stance -> broken; a guard, the ward and a parry still hold
  (check (and (eq (resolve-contact :armor :rend t) :hit) (eq (resolve-contact :stance :rend t) :stance-break)
              (eq (resolve-contact :stance-in :rend t) :stance-break) (eq (resolve-contact :guard :rend t) :blocked)
              (eq (resolve-contact :guard :rend t :ward t :in-front nil) :blocked) (eq (resolve-contact :parry :rend t) :parried)
              (eq (resolve-contact :armor) :armored)))
  ;; the bite beats every defence but iframes; +9 on hit (his J1, S 8, combos after it)
  (let* ((bite (kit-command-move b :sig)) (w (svref (mv-hits bite) 0)))
    (check (and (eq (mv-name bite) :ke-b-bite) (member :grab (mv-flags bite)) (member :unguardable (hw-flags w))
                (~= 1.5 (mv-reach bite)) (eq :crumple (hw-react w))))
    (check (every (lambda (st) (eq :hit (resolve-contact st :unguardable t :rend t))) '(:guard :stance :stance-in :armor :parry)))
    (check (and (null (resolve-contact :invuln :unguardable t)) (eq :hit (resolve-contact :guard :unguardable t :ward t))))
    (check (= 9 (on-hit-adv bite))) (check (> (on-hit-adv bite) (mv-s (kit-command-move b :q)))))
  ;; the pip commands: K, L, SP1, SP2, I, O (and every latched K link: the latch reads :f); J, Step, Hoho, Burst, U, P don't
  (check (and (equal (getf (kit-pips b) :cmds) '(:f :sig :sp1 :sp2 :breaker :kikon)) (eq :kataude (getf (kit-pips b) :to))
              (kit-pip-cmd-p b :f) (kit-pip-cmd-p b :kikon) (not (kit-pip-cmd-p b :q)) (not (kit-pip-cmd-p b :awaken))
              (null (kit-pips a)) (null (kit-pips t3))))
  ;; 7. the Kikon counts: Bankai 4, 片腕 3 (the universal awakened count); their Soul Breaks 5 / 4 (the cap 5); the
  ;; Soul Break cinematic is the form's Kikon cinematic
  (check (and (= 4 (kit-kikon-konpaku b)) (= 3 (kit-kikon-konpaku a))
              (= 5 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku b) t))) (= 4 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku a) t)))
              (= 4 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku b) nil)))))
  (check (and (eq 'ken-oni-kikon-cine (kit-kikon-cine b)) (eq 'ken-kikon-cine (kit-kikon-cine a))
              (equal "MAPPUTATSU" (mv-callout (kit-command-move b :kikon))) (eq :ke-kikon (mv-name (kit-command-move a :kikon)))))
  ;; 8. B1 / B4: no NOME in the Bankai (no :meter-gain, no :ladder, the pips' meter), no cut; x1.2; U still DRINK
  (check (and (null (kit-meter-gain b)) (null (getf (kit-meter b) :ladder)) (= 4 (getf (kit-meter b) :max)) (= 4 (getf (kit-meter b) :start))
              (not (member :cut (kit-passives b))) (member :drink (kit-passives b)) (~= 1.2 (kit-mult b))
              (null (kit-meter-gain a)) (null (kit-meter a)) (not (member :drink (kit-passives a))) (~= 1.0 (kit-mult a))))
  ;; the K links: guard 28 / 28 / 36 (x2 of a K), rend; TATE-GOTO guard-crushes its whole line; SP2's :land is the punch
  (flet ((g (name) (hw-guard (svref (mv-hits (kit-move b name)) 0))))
    (check (and (= 28 (g :ke-b-k1)) (= 28 (g :ke-b-k2)) (= 28 (g :ke-b-k2s)) (= 36 (g :ke-b-k3))
                (every (lambda (n) (member :rend (hw-flags (svref (mv-hits (kit-move b n)) 0)))) '(:ke-b-k1 :ke-b-k2 :ke-b-k3 :ke-b-punch)))))
  (let ((sp (kit-command-move b :sp1)))
    (check (and (eq (mv-name sp) :ke-b-split) (member :guard-crush (hw-flags (svref (mv-hits sp) 0))) (~= 6.0 (mv-reach sp))
                (eq :ke-b-punch (mv-name (kit-next b :ke-charge :land))) (eq :ke-flurry (mv-name (kit-next a :ke-charge :land)))
                (= 2 (kit-command-cost b :sp2)) (= 1 (kit-command-cost b :sp1)))))
  ;; one pip per J / K string (the playtest decision 2026-09-28): owed from its first K link or its O ender, charged once
  ;; he is out of the string (a whiff, a hit on him, the end, an SP / L cancel); JJJ owes none
  (check (and (not (string-pip-due-p t :move :quick)) (not (string-pip-due-p t :move :flash)) (not (string-pip-due-p t :move :kikon))
              (string-pip-due-p t :idle nil) (string-pip-due-p t :stun nil) (string-pip-due-p t :guard-hit nil)
              (string-pip-due-p t :move :sp) (string-pip-due-p t :move :sig) (not (string-pip-due-p nil :idle nil))))
  ;; the last pip's move comes out in full (the user's report 2026-09-28: the burst cut it): the pending burst follows
  ;; the move's chain (a latched link, SP2's punch started by its hook, the O ender after a link 3: MOVE-FOLLOWS-P) and
  ;; fires only once he is out of it; a new move of his own (J1 after the bite) is cut as before
  (let* ((charge (kit-move b :ke-charge)) (punch (kit-next b :ke-charge :land)) (k1 (kit-move b :ke-b-k1))
         (k2 (kit-next b :ke-b-k1 :f)) (k3 (kit-next b :ke-b-k2 :f)) (o (kit-command-move b :kikon))
         (bite (kit-command-move b :sig)) (j1 (kit-command-move b :q)) (split (kit-command-move b :sp1)))
    (check (and (move-follows-p b charge punch) (move-follows-p b k1 k2) (move-follows-p b k3 o) (move-follows-p b k1 (kit-next b :ke-b-k1 :q))
                (not (move-follows-p b bite j1)) (not (move-follows-p b split j1)) (not (move-follows-p b k1 o))))
    (flet ((burst-frame (pending frames)             ; ARM-STEP's rule over (state move) frames: the frame the burst fires
             (loop for (st m) in frames for i from 0
                   do (when (and (typep pending 'move) m (not (eq m pending)) (move-follows-p b pending m)) (setf pending m))
                   when (burst-due-p pending m st) return i)))
      (check (and (= 3 (burst-frame bite `((:move ,bite) (:move ,bite) (:move ,bite) (:idle nil))))          ; L
                  (= 3 (burst-frame split `((:move ,split) (:move ,split) (:move ,split) (:idle nil))))   ; SP1
                  (= 4 (burst-frame charge `((:move ,charge) (:move ,punch) (:move ,punch) (:move ,punch) (:idle nil))))   ; SP2
                  (= 4 (burst-frame k2 `((:move ,k2) (:move ,k3) (:move ,o) (:stun nil) (:idle nil))))   ; a string + O
                  (= 2 (burst-frame bite `((:move ,bite) (:guard-hit nil) (:move ,j1))))))))   ; a new move is cut
  ;; route damage on hit (x1.2, before Cornered; each hit rounded): KKK 444 (1 pip), JJK 272 (1)
  (flet ((route-dmg (first presses)
           (loop for n in (route b first presses) for i from 1
                 sum (hit-damage (mv-dmg (kit-move b n)) (kit-atk-mods b 0) nil i nil))))
    (check (and (= 444 (route-dmg :f '((:f) (:f)))) (= 272 (route-dmg :q '((:q) (:f)))))))
  ;; 6. 片腕: the sword moves at reach x0.7 (J1 0.73 -> the J floor 1.4, K1 1.96, K3 1.89), the kick, the Breaker and O as written; B2:
  ;; every form's Breaker strike out-reaches its trigger, every Kikon strike *KIKON-TRIGGER* + 0.3
  (check (and (~= *j-reach-min* (mv-reach (kit-move a :ke-j1))) (~= 1.96 (mv-reach (kit-move a :ke-k1))) (~= 1.89 (mv-reach (kit-move a :ke-k3)))
              (~= *j-reach-min* (mv-reach (kit-next a :ke-j2 :q))) (~= *breaker-reach* (mv-reach (kit-command-move a :breaker)))
              (~= 2.4 (mv-reach (kit-command-move a :kikon))) (= 7 (mv-s (kit-move a :ke-j1)))))
  (dolist (cf *forms*)
    (let ((k (apply #'kit cf)))
      (let ((br (kit-command-move k :breaker)))        ; (Rukia's rooted zero has none)
        (check (or (null br) (> (+ (mv-reach br) 0.34) *breaker-trigger*))))   ; (with the thinnest hurt radius)
      (check (> (mv-reach (kit-command-move k :kikon)) (+ *kikon-trigger* 0.3)))))
  ;; the looks: the oni body in both, the aura only in the Bankai, the cracks hidden in 片腕, the wreck hidden in the Bankai
  (check (and (eq :kenpachi-oni (kit-body b)) (eq :kenpachi-oni (kit-body a)) (eq :oni (kit-aura b)) (null (kit-aura a))
              (member :arm-wreck (kit-hide b)) (not (member :arm-wreck (kit-hide a))) (member :crack-4 (kit-hide a))
              (equal (kit-form-name b) "BANKAI") (equal (kit-form-name a) "KATAUDE")))
  ;; AI keys: the entry rule on cup 3, the Bankai's K links / hurry / the opponent's wait
  (check (and (equal (getf (kit-ai t3) :bankai) '(:p 0.9 :opp-below 0.6 :opp-konpaku 4 :own-konpaku 4))
              (~= 0.6 (getf (kit-ai b) :string-k)) (= 90 (getf (kit-ai b) :pip-hurry))
              (equal (getf (kit-ai b) :opp-intent) '(:zone 2 :defend 2)) (null (getf (kit-ai b) :cashout)))))

;;; ================================================================ Kuchiki Rukia (docs/duel/DUEL_RUKIA.md)
(let ((b (kit :rukia :base)) (m18 (kit :rukia :m18)) (m50 (kit :rukia :m50)) (z (kit :rukia :zero)))
  ;; frost: max, not a sum; capped; x0.7 on walk / run only while it lasts
  (check (and (= 90 (frost-next 60 90)) (= 90 (frost-next 90 60)) (= *frost-cap* (frost-next 140 400)) (= 150 *frost-cap*)
              (~= (frost-speed 3.8 1) (* 3.8 *frost-slow*)) (~= (frost-speed 3.8 0) 3.8) (~= *frost-slow* 0.7)))
  ;; the cold gauge (two stacked bars, the user's decision 2026-09-28): guarding cools *RU-COOL-RATE*/s, not guarding warms
  ;; at the band's rate, clamped 0 .. 200
  (check (and (~= 200.0 *cold-max*) (~= 100.0 *cold-bar*) (~= 1.5 (temp-next 0.0 t 10.0)) (~= 200.0 (temp-next 199.5 t 10.0))
              (~= 0.0 (temp-next 0.1 nil 10.0)) (~= (- 150.0 (/ 12.0 60)) (temp-next 150.0 nil 12.0))))
  ;; the bands with hysteresis by bars: -18 -> -50 at 100, back at 0; -50 -> zero at 200, back at 100; several at once
  (check (and (eq :m18 (temp-band 99.9 :m18)) (eq :m50 (temp-band 100.0 :m18)) (eq :m50 (temp-band 0.5 :m50))
              (eq :m18 (temp-band 0.0 :m50)) (eq :m50 (temp-band 199.0 :m50)) (eq :zero (temp-band 200.0 :m50))
              (eq :zero (temp-band 100.5 :zero)) (eq :m50 (temp-band 100.0 :zero)) (eq :m18 (temp-band 0.0 :zero))
              (eq :zero (temp-band 200.0 :m18)) (eq :m50 (temp-band 150.0 :m50))))
  ;; the pacing (§1): guarding from -18 reaches zero in 134 f (2.2 s; the user's decision 2026-09-28: cool faster); a bar
  ;; of -50 warms out in ~8 s, one of
  ;; -18 in 10 s; zero's top bar in 20 s unbraced (the user's decision 2026-09-28: zero warms slowest, easier to hold)
  (flet ((walk (c band guarding warm)
           (loop for n from 1 to 2000 do (setf c (temp-next c guarding warm))
                 when (not (eq band (temp-band c band))) return n)))
    (check (and (= 67 (walk 0.0 :m18 t 0.0)) (= 67 (walk 100.0 :m50 t 0.0)) (= 67 (temp-cool-frames 0.0))
                (<= 1190 (walk 200.0 :zero nil (kit-warm z)) 1210) (<= 480 (walk 100.0 :m50 nil (kit-warm m50)) 520)
                (= 67 (temp-cool-frames 100.0)) (= 40 (temp-cool-frames 140.0)))))
  ;; the kit side: a :temp meter of 200 in every band, warming 10 / 12 / 5 (zero the slowest), reset to -18
  (check (and (eq (kit-awaken-form b) :m18) (every (lambda (k) (and (getf (kit-meter k) :temp) (~= 200.0 (getf (kit-meter k) :max)))) (list m18 m50 z))
              (> (kit-warm m50) (kit-warm m18) (kit-warm z)) (null (kit-meter b))
              (every (lambda (k) (eq (kit-reset-form k) :m18)) (list m18 m50 z)) (null (kit-reset-form b))
              (null (kit-duration z)) (kit-rooted z) (notany #'kit-rooted (list b m18 m50)) (eq 'rukia-crack (kit-crush-hook z))
              (null (kit-crush-hook m50)) (null (kit-drop-to z))))
  ;; spending (§3, rescaled): at -18 only L (refused below its cost); at -50 / zero everything; zero's L and SPs cash the
  ;; whole top bar (100: always back to -50); J / K cost the same whatever the link
  (check (and (equal (kit-cold m18) '(:sig 25)) (= 0 (getf (kit-cold m18) :q 0)) (= 0 (getf (kit-cold m18) :step 0))
              (every (lambda (c) (plusp (getf (kit-cold m50) c 0))) '(:q :f :sig :sp1 :sp2 :kikon :breaker :step))
              (= 0 (getf (kit-cold m50) :hoho 0)) (eq 'rukia-hoho-cold (kit-hook m50 :hoho)) (eq 'rukia-hoho-cold (kit-hook m18 :hoho))   ; a Hoho adds cold
              (eq :zero (temp-band (min *cold-max* (+ 150.0 *ru-hoho-cold*)) :m50)) (eq :m50 (temp-band (+ 60.0 *ru-hoho-cold*) :m18))
              (every (lambda (c) (>= (getf (kit-cold z) c 0) *cold-bar*)) '(:sig :sp1 :sp2))
              (< (getf (kit-cold m18) :sig) (getf (kit-cold m50) :sig) (getf (kit-cold z) :sig))
              (< (* 3 (getf (kit-cold z) :q)) *cold-bar*) (< (* 2 (getf (kit-cold z) :f)) *cold-bar*)))   ; zero's JJJ, KK fit its bar
  ;; the field (§4.1): only the away part of a walk is scaled; a side Step untouched, a back Step x :step; the floor
  (multiple-value-bind (vx vz) (field-velocity 2.0 0.0 1.0 0.0 0.55) (check (and (~= vx 1.1) (~= vz 0.0))))   ; straight away
  (multiple-value-bind (vx vz) (field-velocity -2.0 1.0 1.0 0.0 0.55) (check (and (~= vx -2.0) (~= vz 1.0))))  ; toward / strafe
  (multiple-value-bind (vx vz) (field-velocity 0.0 3.0 1.0 0.0 0.55) (check (and (~= vx 0.0) (~= vz 3.0))))   ; circling
  (check (and (~= 2.5 (field-step 2.5 0.0 0.75)) (~= (* 2.5 0.75) (field-step 2.5 -1.0 0.75)) (~= 2.5 (field-step 2.5 1.0 0.75))
              (< (* 2.5 0.75) (field-step 2.5 -0.5 0.75) 2.5)
              (~= (field-k 0.55 t) (/ *field-floor* *frost-slow*)) (~= (field-k 0.85 t) 0.85) (~= (field-k 0.55 nil) 0.55)
              (>= (* *frost-slow* (field-k 0.55 t)) (- *field-floor* 1e-4))))
  (check (and (< (getf (kit-field m18) :r) (getf (kit-field m50) :r) (getf (kit-field z) :r))
              (> (getf (kit-field m18) :away) (getf (kit-field m50) :away) (getf (kit-field z) :away))
              (null (kit-field b)) (~= (getf (kit-field z) :r) (getf (mv-params (kit-command-move z :sig)) :radius))))
  ;; colder is never weaker (the playtest fix, §4): damage x, frost on every hit, J / K reach, the L family (radius, damage),
  ;; SP1 / SP2 / O reach and damage grow band by band; -50 and zero take less
  (flet ((up (fn) (let ((v (mapcar fn (list m18 m50 z)))) (and (< (first v) (second v)) (< (second v) (third v)))))
         (sig (k key) (getf (mv-params (kit-command-move k :sig)) key)))
    (check (and (up #'kit-mult) (up #'kit-frost-touch) (up (lambda (k) (mv-reach (kit-command-move k :q))))
                (up (lambda (k) (mv-reach (kit-command-move k :f)))) (up (lambda (k) (sig k :radius))) (up (lambda (k) (sig k :dmg)))
                (up (lambda (k) (mv-reach (kit-command-move k :sp2)))) (up (lambda (k) (mv-dmg (kit-command-move k :sp2))))
                (up (lambda (k) (mv-reach (kit-command-move k :kikon))))
                (up (lambda (k) (getf (mv-params (kit-command-move k :sp1)) :dmg)))
                (> (kit-taken m18) (kit-taken m50) (kit-taken z))
                (~= 1.44 (mv-reach (kit-move m18 :ru-j1))) (~= 1.584 (mv-reach (kit-move m50 :ru-j1))) (~= 1.944 (mv-reach (kit-move z :ru-j1)))
                (~= 3.78 (mv-reach (kit-command-move z :f))) (~= 2.106 (mv-reach (kit-move z :ru-j3))) (~= 1.72 (mv-reach (kit-move m50 :ru-j3-50)))
                (~= 5.0 (mv-reach (kit-command-move m18 :sp2))) (~= 7.5 (mv-reach (kit-command-move z :sp2))))))
  ;; rooted zero: at zero no chase, so each follow-up link must still reach after a blocked link's push from where a J1
  ;; lands (the Shikai J1's reach): J2 >= J1 - *BLOCK-PUSHBACK* (the x1.35 reach covers the 0.6 m push)
  (let ((j1 (mv-reach (kit-move m18 :ru-j1))))
    (check (and (>= (+ (mv-reach (kit-move z :ru-z-j2)) 0.45) (+ j1 *block-pushback*))
                (>= (+ (mv-reach (kit-move z :ru-k2)) 0.45) (+ j1 *block-pushback*)))))
  ;; the moves each band has: L SHIMOBASHIRA / HYOSHIN / REIDO (no cooldown: the gauge is the limiter, no COOLDOWN row);
  ;; SP1 HAKUREN in every band (-50 faster stabs, zero no hold); no Breaker at zero; HAKKA in every band
  (check (and (eq :ru-shimobashira (mv-name (kit-command-move m18 :sig))) (eq :ru-hyoshin (mv-name (kit-command-move m50 :sig)))
              (eq :ru-reido (mv-name (kit-command-move z :sig))) (notany (lambda (k) (plusp (mv-cooldown (kit-command-move k :sig)))) (list m18 m50 z))
              (eq :ru-hakuren (mv-name (kit-command-move m18 :sp1))) (equal '(12 48) (mv-hold (kit-command-move m50 :sp1)))
              (null (mv-hold (kit-command-move z :sp1))) (null (kit-command-move z :breaker)) (kit-command-move m50 :breaker)
              (every (lambda (k) (eq 'ru-hakka-cine (mv-cine (kit-command-move k :kikon)))) (list m18 m50 z))
              (every (lambda (k) (null (kit-command-move k :step))) (list m18 m50 z))
              (eq (mv-name (kit-command-move m18 :f)) :ru-a-k1) (eq (mv-name (kit-next m18 :ru-k2 :f)) :ru-a-k3)
              (eq (mv-name (kit-next m50 :ru-j2 :q)) :ru-j3-50) (eq (mv-name (kit-next z :ru-j1 :q)) :ru-z-j2)
              (eq (mv-name (kit-next z :ru-k2 :f)) :ru-z-k3) (= 2 (kit-command-cost m18 :sp2)) (= 1 (kit-command-cost b :sp2))))
  ;; the passives: every band no chip; zero the ward, optic, freeze-touch
  (check (and (equal (kit-passives m18) '(:chipless)) (equal (kit-passives m50) '(:chipless))
              (equal (kit-passives z) '(:ward :freeze-touch :chipless)) (null (kit-passives b)) (= 0 (kit-frost-touch b))
              (~= *rukia-mult* (kit-mult b)) (~= *rukia-taken* (kit-taken b))))
  ;; optic: a ranged hit on the zero ward lands as on an open defender (the defender state :neutral), a melee one is blocked
  (check (and (optic-p t t t) (not (optic-p t t nil)) (not (optic-p nil t t)) (not (optic-p t nil t))
              (eq (resolve-contact (if (optic-p t t t) :neutral :guard) :hazard t) :hit)
              (eq (resolve-contact :guard :in-front nil :ward t) :blocked)))
  ;; walk / run by band (colder is slower; zero rooted)
  (check (and (~= (kit-walk b) 3.8) (~= (kit-run b) 9.0) (~= (kit-walk m18) 3.4) (~= (kit-run m18) 8.0) (~= (kit-walk m50) 2.8)
              (~= (kit-run m50) 6.4) (~= (kit-walk z) 0.0) (~= (kit-run z) 0.0)))
  ;; the Kikon counts: Shikai 2, every band 3; Soul Breaks 3 / 4; the cinematics
  (check (and (= 2 (kit-kikon-konpaku b)) (every (lambda (k) (= 3 (kit-kikon-konpaku k))) (list m18 m50 z))
              (= 3 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku b) t))) (= 4 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku m18) t)))
              (eq 'ru-kikon-cine (kit-kikon-cine b)) (eq 'ru-hakka-cine (kit-kikon-cine m18)) (eq 'ru-hakka-cine (kit-kikon-cine z))
              (eq 'ru-awaken-cine (kit-cine m18))))
  ;; the reaches: ENBU 8.0 m in <= 30 f; HAKKA's lane 6.5 / 7.5 / 9.0, no dash; J1 S7 beats every K1 in the game
  (let ((en (kit-command-move b :kikon)))
    (check (and (~= 8.0 (kikon-rush-reach (getf (mv-params en) :speed) (getf (mv-params en) :dash-max))) (= 30 (+ (getf (mv-params en) :aura) (getf (mv-params en) :dash-max) (mv-s en)))
                (equal '(6.5 7.5 9.0) (mapcar (lambda (k) (mv-reach (kit-command-move k :kikon))) (list m18 m50 z)))
                (zerop (getf (mv-params (kit-command-move z :kikon)) :dash-max)) (= 7 (mv-s (kit-command-move b :q)))
                (< (mv-s (kit-command-move b :q)) (min (mv-s (mv :yamamoto :base :ya-k1)) (mv-s (mv :kenpachi :base :ke-k1)))))))
  ;; fairness: TSUKISHIRO's circle + Kenpachi's hurt radius < a Step; every HAKUREN's widest half-width + his hurt radius
  ;; < a Step (a side Step clears every wave, never shortened by the field); the ring's tell 24 f, one ring at a time (no
  ;; cooldown since 2026-09-29: the move outlasts its pillar)
  (let* ((ts (kit-command-move b :sig)) (pa (mv-params ts)))
    (check (and (< (+ (getf pa :radius) 0.45) *step-distance*) (= 24 (getf pa :delay)) (> (mv-total ts) (+ (mv-s ts) (getf pa :delay)))
                (member :bind (mv-flags ts)) (equal (getf pa :tell) '(21 30))
                (every (lambda (k) (let ((hp (mv-params (kit-command-move k :sp1))))
                                     (< (+ (* 0.5 (+ (getf hp :width) (* 3 (getf hp :width-per)))) 0.45) *step-distance*)))
                       (list b m18 m50 z))
                (equal (mv-hold (kit-command-move b :sp1)) '(16 64))
                (= 130 (let ((hp (mv-params (kit-command-move b :sp1)))) (+ (getf hp :dmg) (* 3 (getf hp :dmg-per))))))))
  ;; frost on the hits: the K links, Shirafune, the new links
  (flet ((fr (k n) (hw-frost (svref (mv-hits (kit-move k n)) 0))))
    (check (and (= 60 (fr b :ru-k1)) (= 60 (fr b :ru-k2)) (= 90 (fr b :ru-k3)) (= 0 (fr b :ru-j1)) (= 150 (fr b :ru-shirafune))
                (= 90 (fr m18 :ru-a-k1)) (= 120 (fr m18 :ru-a-k3)) (= 120 (fr m18 :ru-hakka-18)) (= 150 (fr z :ru-z-k3)))))
  ;; the route damage on hit (before multipliers): KKK 208, JJJ 110, the O ender 63
  (flet ((dmg (&rest names) (loop for n in names for i from 1 sum (hit-damage (mv-dmg (kit-move b n)) nil nil i nil))))
    (check (and (= 110 (dmg :ru-j1 :ru-j2 :ru-j3)) (= 208 (dmg :ru-k1 :ru-k2 :ru-k3)) (= 63 (hit-damage 70 nil nil 4 nil)))))
  ;; the looks and the HUD: the body variants, the blades, the hidden tags, the U tags, the band names
  (check (and (eq :rukia (kit-body b)) (eq :rukia (kit-body m50)) (eq :rukia-zero (kit-body z))
              (equal '(:sode-no-shirayuki :ru-rime :ru-ice) (mapcar #'kit-weapon (list m18 m50 z)))
              (not (member :ice-trim (kit-hide m50))) (member :ice-trim (kit-hide m18)) (member :hand-crack (kit-hide z))
              (equal (mapcar #'kit-u-tag (list m18 m50 z)) '("U: COOL" "U: COOL" "U: BRACE"))
              (equal (mapcar #'kit-form-name (list m18 m50 z)) '("-18C" "-50C" "-273C"))))
  ;; AI keys: the awakening rule, cooling (-50 not below half a guard gauge), bracing at zero, the stun follow-ups, the
  ;; opponent's wait
  (check (and (equal (getf (kit-ai b) :awaken) '(:melee-share 0.6 :min-taken 150)) (equal (getf (kit-ai b) :stun-follow) '(:sp2 2.4 5.0))
              (equal (getf (kit-ai m18) :cool) '(:p 0.3 :near 3.5)) (= 50 (getf (getf (kit-ai m50) :cool) :min-gg))
              (null (getf (kit-ai z) :cool)) (getf (kit-ai z) :brace) (null (getf (kit-ai z) :zero-exit))
              (equal (getf (kit-ai z) :opp-intent) '(:zone 2 :defend 2)) (null (getf (kit-ai b) :opp-intent)))))

;; L after a K link (the kit's :l-after-k, docs/duel/DUEL_STRINGS.md §12, the user's decision 2026-09-28): every K link of
;; every Rukia form (K1 K2 K2s K3) has one, no J link and no other character; the Shikai's is the combo copy of TSUKISHIRO,
;; the bands' their own L. On hit it combos: from the K link's hit its A + the L's hit frame (the last :on-frame hook + a
;; hazard's :delay) < the K link's hitstun; the Shikai's plain TSUKISHIRO wouldn't (its 24 f tell)
(flet ((l-hit (l) (+ (first (car (last (mv-on-frame l)))) (or (getf (mv-params l) :delay) 0))))
  (dolist (form '(:base :m18 :m50 :zero))
    (let* ((k (kit :rukia form)) (ks (remove-if-not (lambda (l) (eq :f (car (last (third l))))) (link-moves k))))
      (check (= 4 (length (remove-duplicates (mapcar #'first ks)))))
      (dolist (l ks)
        (let* ((m (first l)) (lm (kit-l-link k (mv-name m))) (w (svref (mv-hits m) 0)))
          (check (and lm (eq (mv-kind lm) :sig)))
          (check (< (+ (- (mv-s m) (hw-from w)) (mv-a m) (l-hit lm)) (hitstun (hw-react w))))))
      (check (notany (lambda (l) (and (eq :q (car (last (third l)))) (kit-l-link k (mv-name (first l)))))
                     (link-moves k)))))
  (let* ((b (kit :rukia :base)) (lk (kit-l-link b :ru-k1)) (ts (kit-command-move b :sig)))
    (check (and (eq :ru-tsukishiro-k (mv-name lk)) (= 18 (l-hit lk)) (= 36 (l-hit ts)) (zerop (mv-cooldown ts)) (zerop (mv-cooldown lk))   ; (no L cooldown: the user 2026-09-29)
                (>= (+ 4 (l-hit ts)) 26)                                 ; the plain one misses the combo after a K1
                (>= (mv-reach lk) (getf (mv-params lk) :range))           ; no chase: the ring is cast at him
                (equal (mv-callout ts) (mv-callout lk)) (member :bind (mv-flags lk))))
    (check (every (lambda (f) (eq (kit-l-link (kit :rukia f) :ru-k2) (kit-command-move (kit :rukia f) :sig))) '(:m18 :m50 :zero)))
    (check (every (lambda (cf) (null (kit-l-after-k (apply #'kit cf)))) (remove-if (lambda (c) (member c '(:rukia :ichigo :senjumaru :lille))) *forms* :key #'first)))
    (check (every (lambda (f) (numberp (getf (kit-ai (kit :rukia f)) :l-after-k))) '(:base :m18 :m50 :zero)))))

;; the combo band lock with overdraft (the user's decision 2026-09-28): inside a combo the band holds whatever C does; L is
;; refused short of its cold outside a combo, allowed on credit inside one while C > 0; once free the band re-resolves,
;; several at once: -273 K K K (40 each) leaves 80, the chained L (100) overdraws to 0, and she lands at -18
(let* ((z (kit :rukia :zero)) (kc (getf (kit-cold z) :f)) (lc (getf (kit-cold z) :sig))
       (c (- *cold-max* (* 3 kc))))
  (check (and (= 40 kc) (= 100 lc) (= 80 c)
              (not (cold-ok-p c lc nil)) (cold-ok-p c lc t) (not (cold-ok-p 0.0 lc t)) (cold-ok-p 100.0 lc nil)
              (eq :zero (temp-band-at c :zero :move)) (eq :zero (temp-band-at 0.0 :zero :move))   ; locked in the combo
              (eq :zero (temp-band-at 0.0 :zero :stun)) (eq :m50 (temp-band-at 80.0 :zero :idle))
              (eq :m18 (temp-band-at (max 0.0 (- c lc)) :zero :idle))                          ; the overdrawn combo: -18
              (eq :m50 (temp-band-at 150.0 :m50 :guard)) (eq :m18 (temp-band-at 0.0 :m50 :run))
              (eq :m18 (temp-band-at 10.0 :m18 :move)) (eq :zero (temp-band-at 200.0 :m18 :idle)))))

;; Ichigo v2 (docs/duel/DUEL_ICHIGO.md "v2: built"): the cross copies, the stance and its branches (every one combos after a K
;; link), KESSA's cuts, the clones (their timing, the Konpaku table, their fate), the parry's own window (GOKUI GAESHI's
;; unchanged), the counter, the afterimages, the pull, the Kikon counts and cinematics, the removed tools
(let* ((b (kit :ichigo :base)) (ks (kit :ichigo :kessa)) (parry (kit-move ks :ic-k-parry)) (gaeshi (kit-move ks :ic-k-gaeshi))
       (hiki (kit-move ks :ic-k-hiki)) (kj1 (kit-command-move ks :q)) (kk1 (kit-command-move ks :f)) (hk (svref (mv-hits hiki) 0))
       (tsuki (kit-command-move b :sig)) (tk2 (kit-l-link b :ic-k1)) (win (getf (mv-params parry) :window))
       (kr 0.45))                                          ; Kenpachi's hurt r (ken-art.lisp: the host loads no body)
  (flet ((gv (k n) (hw-guard (svref (mv-hits (kit-move k n)) 0))))
    ;; the CROSS: J2s / K2s = J2 / K2 with guard 12 / 24 (J2 / K2 8 / 16); KESSA's copies are plain (one blade)
    (check (and (= 8 (gv b :ic-j2)) (= 12 (gv b :ic-j2s)) (= 16 (gv b :ic-k2)) (= 24 (gv b :ic-k2s)) (= 22 (gv b :ic-k3))
                (eq :ic-cross (mv-clip (kit-move b :ic-k2s))) (equal (mv-spec (kit-move ks :ic-k-k2)) (mv-spec (kit-move ks :ic-k-k2s)))))
    ;; KESSA's cuts: ordinary reach (J 2.6, K 3.2), routes on hit JJJ 100 / KKK 204, blocked KKK drains 48
    (check (and (~= 1.56 (mv-reach kj1)) (~= 2.9 (mv-reach kk1)) (<= (mv-reach (kit-move ks :ic-k-k3)) 3.6)
                (= 100 (+ (mv-dmg kj1) (mv-dmg (kit-move ks :ic-k-j2)) (mv-dmg (kit-move ks :ic-k-j3))))
                (= 204 (+ (mv-dmg kk1) (mv-dmg (kit-move ks :ic-k-k2)) (mv-dmg (kit-move ks :ic-k-k3))))
                (= 48 (+ (gv ks :ic-k-k1) (gv ks :ic-k-k2) (gv ks :ic-k-k3))))))
  ;; the stance: up at f6, 30 f held (60 with L held) then R 14, no hits (hit as neutral); its branches are non-button
  ;; strings; L after a K link opens it at f4; L, L fires the Getsuga at the old L's f14; the dash comes back at f6
  (check (and (= 6 (mv-s tsuki)) (= 80 (mv-total tsuki)) (zerop (length (mv-hits tsuki))) (eq :ic-tsuki-k2 (mv-name tk2))
              (= 4 (mv-enter tk2)) (= 6 (mv-enter (find-move :ic-tsuki-re))) (= 80 (+ *tsuki-up* *tsuki-max* 14))
              (eq (kit-next b :ic-tsuki :tsuki-j) (find-move :ic-tsuki-j)) (eq (kit-next b :ic-tsuki-k2 :tsuki-k) (find-move :ic-tsuki-k))
              (eq (kit-next b :ic-tsuki-re :tsuki-step) (find-move :ic-tsuki-dash))
              (eq (kit-next b :ic-tsuki-dash :tsuki-back) (find-move :ic-tsuki-re))
              (= 14 (+ *tsuki-up* (mv-s (kit-next b :ic-tsuki :tsuki-l)))) (null (kit-l-link b :ic-j1))
              (not (string-link-p b :ic-tsuki))))
  ;; RANGETSU: four hits, -6 on block (J1 7 f doesn't punish it); TSUKI-OTOSHI: guard 30, -10
  (let ((rj (find-move :ic-tsuki-j)) (rk (find-move :ic-tsuki-k)))
    (check (and (= 4 (length (mv-hits rj))) (= 72 (* 4 (mv-dmg rj))) (= -6 (mv-adv-block rj)) (= 30 (hw-guard (svref (mv-hits rk) 0)))
                (= -10 (mv-adv-block rk)) (eq :crumple (hw-react (svref (mv-hits rk) 0))))))
  ;; every branch combos off a K link's hit: its A + 2 (the stance's f4 -> f6) + the branch's first hit (the wave's travel
  ;; from 1 m out to 3 m) < the K link's hitstun
  (dolist (k '(:ic-k1 :ic-k2 :ic-k3))
    (let* ((m (kit-move b k)) (st (hitstun (hw-react (svref (mv-hits m) 0)))))
      (check (and (< (+ (mv-a m) 2 (mv-first-hit (kit-next b :ic-tsuki-k2 :tsuki-j))) st)
                  (< (+ (mv-a m) 2 (mv-first-hit (kit-next b :ic-tsuki-k2 :tsuki-k))) st)
                  (< (+ (mv-a m) 2 (mv-s (kit-next b :ic-tsuki-k2 :tsuki-l)) (ceiling (* 60 (/ 2.0 16.0)))) st)))))
  ;; the clones: a J press's heavy lands inside Ichigo's J1 flinch (between J1 and J2), a K press's light before his K1;
  ;; an opponent's J1 (7 f) beats the light (a real hit on Ichigo clears every clone)
  (check (and (= 22 (clone-hit-frame :q)) (= 14 (clone-hit-frame :f))
              (< (mv-s kj1) (clone-hit-frame :q) (+ (mv-s kj1) (hitstun :flinch))) (< (clone-hit-frame :f) (mv-s kk1))
              (< (mv-s (mv :kenpachi :base :ke-j1)) (clone-hit-frame :f))
              (eq :stagger (hw-react (svref (mv-hits (clone-move :q 1)) 0))) (eq :crumple (hw-react (svref (mv-hits (clone-move :q 3)) 0)))
              (eq :flinch (hw-react (svref (mv-hits (clone-move :f 1)) 0)))))
  ;; the Kikon's Konpaku by the clones at the O press (the user's table 0 / 1 / 2 / 3 -> 2 / 2 / 3 / 4, at most 4)
  (check (and (equal '(2 2 3 4) (mapcar #'clone-konpaku '(0 1 2 3))) (= 4 (clone-konpaku 5)) (<= (clone-konpaku 3) *kikon-max-event*)))
  ;; a clone's life and fate: 300 f, 3 at most (the oldest replaced), 15 guard gauge each (no Step gap); its string touched him
  ;; (hit or block): it fades, a whiff keeps it (idle), its time up: it fades; a real hit on Ichigo (not a block, not a
  ;; parry) clears them all
  (check (and (= 300 *clone-life*) (= 3 *clone-max*) (= 15.0 *clone-cost*)
              (eq :idle (clone-after-string nil 100)) (eq :fade (clone-after-string t 100)) (eq :fade (clone-after-string nil 0))
              (null (clone-evict '(5 9))) (= 1 (clone-evict '(7 3 9)))
              (clone-vanish-p :hit) (clone-vanish-p :counter) (clone-vanish-p :guard-break)
              (not (clone-vanish-p :blocked)) (not (clone-vanish-p :parried)) (not (clone-vanish-p nil))))
  ;; the parry: its own window f2-25 (24 f; the move's :window), 360 deg, 10 of the gauge, R 18; GOKUI GAESHI's shared
  ;; window is the same f2-25 since 2026-10-01; a catch staggers 40 f, and ZANGETSU-GAESHI (the :land string) is +15: his J1 combos
  (check (and (member :parry (mv-flags parry)) (equal '(2 25) win) (= 2 (mv-s parry)) (= 24 (mv-a parry)) (= 44 (mv-total parry))
              (parry-frame-p 2 win) (parry-frame-p 25 win) (not (parry-frame-p 1 win)) (not (parry-frame-p 26 win))
              (parry-frame-p 2) (parry-frame-p 25) (not (parry-frame-p 1)) (not (parry-frame-p 26))
              (eq (kit-next ks :ic-k-parry :land) gaeshi) (= 10 *kessa-parry-cost*) (= 20 *kessa-parry-catch*)
              (= 40 *kessa-parry-stun*) (< (mv-s gaeshi) *kessa-parry-stun*)
              (= 15 (- (+ (mv-s gaeshi) (hitstun :crumple)) (mv-total gaeshi))) (< (mv-s kj1) 15)
              (member :parry-block (kit-passives ks)) (not (member :parry-block (kit-passives b)))))
  ;; a :parry-block parry blocks a hazard and catches a melee hit
  (check (and (eq (resolve-contact :parry :hazard t :ward t) :blocked) (eq (resolve-contact :parry) :parried)
              (eq (resolve-contact :parry :breaker t) :stance-break) (eq (resolve-contact :parry :unguardable t) :hit)))
  ;; the afterimages: each hit repeats *ZANZO-LAG* (10) f later at x0.5 damage and guard, a blade's hit: J1's at f18,
  ;; RANGETSU's four at f18 21 24 27
  (let ((w (echo-hitwin (svref (mv-hits kj1) 0) *zanzo-mult*)))
    (check (and (equal '(18) (echo-hit-frames kj1)) (equal '(18 21 24 27) (echo-hit-frames (find-move :ic-tsuki-j)))
                (= 15 (hw-dmg w)) (~= 4.0 (hw-guard w)) (member :blade (hw-flags w)) (eq :flinch (hw-react w))
                (= 360 *zanzo-life*))))
  ;; KUSARI-BIKI: the far part ranged (beyond 3.8 m), bound 40 f from its f16 hit: +13, so his J1 (8 f) combos
  (check (and (member :ranged (hw-flags hk)) (= 40 (hw-stun hk)) (eq :bind (hw-react hk))
              (~= 3.8 (getf (mv-params hiki) :melee-range)) (= 13 (- (+ (hw-from hk) (hw-stun hk)) (mv-total hiki)))
              (< (mv-s kj1) 13)))
  ;; the Kikon counts 2 / 3 (a Soul Break 3 / 4); KESSA's Soul Break plays the Getsuga (its :soul-break-cine), its O 千影
  (check (and (= 2 (kit-kikon-konpaku b)) (= 3 (kit-kikon-konpaku ks)) (kit-awakening ks)
              (eq 'ic-kessa-getsuga-cine (kit-kikon-cine ks)) (eq 'ic-kikon-cine (kit-kikon-cine b))
              (eq 'ic-kessa-kikon-cine (mv-cine (kit-command-move ks :kikon)))
              (~= 8.6 (kikon-rush-reach 30.0 14)) (> (+ (mv-reach (kit-command-move ks :breaker)) 0.34) *breaker-trigger*)))
  ;; a side Step (2.5 m) clears every crescent: its half-width + Kenpachi's hurt r < 2.5
  (check (every (lambda (w) (< (+ (* 0.5 w) kr) *step-distance*))
                (list (getf (mv-params (kit-next b :ic-tsuki :tsuki-l)) :width) (getf (mv-params (kit-command-move b :sp1)) :width))))
  ;; U is a guard again in both forms (no :u hook, no chain skin); the removed base tools (sidegrade rule 2): no JUJISHO,
  ;; no SOGA, no cross links, no stance; slower
  (check (and (null (kit-hook ks :u)) (null (kit-hook ks :hud-guard)) (null (kit-u-tag ks)) (null (kit-l-after-k ks))
              (not (eq (kit-command-move ks :sp1) (kit-command-move b :sp1))) (not (eq (kit-command-move ks :sp2) (kit-command-move b :sp2)))
              (not (eq (kit-command-move ks :sig) tsuki)) (< (kit-walk ks) (kit-walk b)) (< (kit-run ks) (kit-run b))))
  ;; the CPU: the awakening after 150 taken; KESSA guards (0.4) and parries / sends the clones by its :reflex
  (check (and (equal (getf (kit-ai b) :awaken) '(:min-taken 150)) (eq 'ichigo-ai-kessa (getf (kit-ai ks) :reflex))
              (~= 0.4 (getf (kit-ai ks) :guard)) (equal (kit-form-name ks) "KESSA") (member :kessa (kit-hide b)) (member :shikai (kit-hide ks)))))
;; ================================================================ ENDLESS (docs/duel/DUEL_ENDLESS.md, endless-rules.lisp)
(defun snap (c f &rest kv)
  (append kv (list :character c :form f :konpaku 5 :reiatsu 123.5 :fs 42.25 :awaken 37.0 :awakened (kit-awakening (kit c f))
                   :meter 55.0)))
(defun carry (c f choice &rest kv) (endless-carry (apply #'snap c f kv) choice))
;; Konpaku + 2, at most 9; Reiatsu and flash step bit-identical; the rest comes from the fresh spawn
(check (equal '(3 9 9 9) (mapcar (lambda (k) (getf (carry :yamamoto :base :stay :konpaku k) :konpaku)) '(1 7 8 9))))
(check (every (lambda (cf) (let ((r (carry (first cf) (second cf) :stay)))
                             (and (eql 123.5 (getf r :reiatsu)) (eql 42.25 (getf r :fs)))))
              *forms*))
;; not awakened: the awakening gauge and the kit meter (Inferno) kept; Hellfire ends like its timer: the base, meter 0
(let ((r (carry :yamamoto :base :stay)))
  (check (and (eq :base (getf r :form)) (eql 37.0 (getf r :awaken)) (null (getf r :awakened)) (eql 55.0 (getf r :meter)))))
(let ((r (carry :yamamoto :hellfire :stay)))
  (check (and (eq :base (getf r :form)) (eql 37.0 (getf r :awaken)) (zerop (getf r :meter)))))
;; revert, every awakened form of every character: the base, not awakened, the awakening full, the meter 0
(check (every (lambda (cf) (let ((r (carry (first cf) (second cf) :revert)))
                             (and (eq :base (getf r :form)) (null (getf r :awakened)) (= *awaken-max* (getf r :awaken))
                                  (zerop (getf r :meter)))))
              (remove-if-not (lambda (cf) (kit-awakening (apply #'kit cf))) *forms*)))
;; stay: Yamamoto East / West -> East; every Kenpachi awakened form -> cup 1 at NOME 10 (the user's decision 2026-09-29:
;; no cup kept); Rukia's bands -> -18 at cold 0
(check (every (lambda (f) (eq :bankai-east (getf (carry :yamamoto f :stay) :form))) '(:bankai-east :bankai-west)))
(check (every (lambda (f) (let ((r (carry :kenpachi f :stay)))
                            (and (eq :nozarashi (getf r :form)) (= *nome-awaken* (getf r :meter)) (getf r :awakened)
                                 (zerop (getf r :awaken)))))
              '(:nozarashi :ryote :nomihose :bankai :kataude)))
(check (every (lambda (f) (let ((r (carry :rukia f :stay))) (and (eq :m18 (getf r :form)) (zerop (getf r :meter)))))
              '(:m18 :m50 :zero)))
(check (eq :base (getf (carry :kenpachi :base :stay) :form)))
;; generic guards (a new character's forms must satisfy them): every stay target of an awakened form is awakened, none
;; is any kit's :bankai-form or its arm's :to, and a timed form's stay target is not timed
(let ((targets (loop for cf in *forms* when (kit-awakening (apply #'kit cf))
                     collect (list (first cf) (endless-stay-form (apply #'kit cf)))))
      (second-forms (loop for cf in *forms* for k = (apply #'kit cf)
                          when (kit-bankai-form k) collect (list (first cf) (kit-bankai-form k))
                          when (kit-pips k) collect (list (first cf) (getf (kit-pips k) :to)))))
  (check (every (lambda (ct) (kit-awakening (apply #'kit ct))) targets))
  (check (notany (lambda (ct) (member ct second-forms :test #'equal)) targets))
  (check (every (lambda (cf) (null (kit-duration (kit (first cf) (endless-stay-form (apply #'kit cf))))))
                (remove-if-not (lambda (cf) (kit-duration (apply #'kit cf))) *forms*))))
;; §5: a Bankai at Konpaku 4 leaves 1, the clear gives 3, and cup 3 may take the Bankai again at 3
(check (and (= 3 (getf (carry :kenpachi :bankai :stay :konpaku 1) :konpaku)) (bankai-allowed-p t 3)))
;; the ramp: the difficulty never falls and clamps at HARD, equal from 12 on; the awakening and Reishi never fall
(check (every (lambda (fl)
                (loop for n from 1 to 40
                      for d = (position (endless-difficulty fl n) '(:easy :normal :hard)) and d0 = -1 then d
                      always (and d (>= d d0)) finally (return t)))
              '(:easy :normal :hard)))
(check (and (eq :hard (endless-difficulty :easy 5)) (eq :normal (endless-difficulty :easy 3)) (eq :hard (endless-difficulty :normal 3))
            (eq :easy (endless-difficulty :easy 1)) (eq :hard (endless-difficulty :hard 1))
            (every (lambda (fl) (loop for n from 12 to 60 always (equal (endless-ramp n) (endless-ramp 12)))) '(:easy :normal :hard))))
(check (loop for n from 1 to 40 for r = (endless-ramp n) and r0 = (endless-ramp 1) then r
             always (and (>= (third r) (third r0)) (or (fourth r) (not (fourth r0))) (>= (fifth r) (fifth r0)))))
(check (equal '(0 50 100 100) (mapcar (lambda (n) (third (endless-ramp n))) '(4 5 7 9))))
(check (and (not (fourth (endless-ramp 8))) (fourth (endless-ramp 9)) (= 110 (fifth (endless-ramp 11))) (= 120 (fifth (endless-ramp 12)))))
;; the bag: each bag the roster once; never the same opponent twice in a row (seeds 1-200); a seed replays; seeds differ
(flet ((run (seed n roster) (loop for s from 1 to n collect (endless-opponent seed s roster))))
  (dolist (roster (list *roster* '(:a :b) '(:a :b :c :d :e)))
    (let ((n (length roster)))
      (check (loop for seed from 1 to 200 for r = (run seed (* 6 n) roster)
                   always (and (loop for b below 6 always (null (set-exclusive-or (subseq r (* b n) (* (1+ b) n)) roster)))
                               (loop for (a b) on r while b never (eq a b)))))))
  (check (equal (run 7 12 *roster*) (run 7 12 *roster*)))
  (check (> (length (remove-duplicates (loop for seed from 1 to 20 collect (run seed 3 *roster*)) :test #'equal)) 2)))
(check (/= (endless-stage-seed 1 2) (endless-stage-seed 1 3) (endless-stage-seed 2 2)))
;; the record: more stages wins, equal stages less time, an empty record (0) loses to any stage, 0 stages never writes
(check (and (endless-better-p 3 500 2 100) (not (endless-better-p 2 50 3 900)) (endless-better-p 3 400 3 500)
            (not (endless-better-p 3 500 3 500)) (not (endless-better-p 3 600 3 500)) (endless-better-p 1 999 0 0)
            (not (endless-better-p 0 10 0 0))))

;;; ================================================================ Senjumaru (docs/duel/DUEL_SENJUMARU.md §10's host tests)
(let ((b (kit :senjumaru :base)) (t1 (kit :senjumaru :tsuji1)) (t6 (kit :senjumaru :tsuji6)))
  ;; the stitches: a hit sews 2, any other contact 1, a parry nothing, capped at 6; 179 idle frames keep them, the 180th
  ;; drops one, then one per 30; a lock pauses the clock
  (check (and (= 2 (hari-sew 0 :hit)) (= 2 (hari-sew 0 :counter)) (= 1 (hari-sew 0 :blocked)) (= 1 (hari-sew 0 :absorbed))
              (= 1 (hari-sew 0 :armored)) (= 0 (hari-sew 0 :parried)) (= 0 (hari-sew 0 nil)) (= 6 (hari-sew 5 :hit))
              (= 6 (hari-sew 6 :blocked))))
  (flet ((run (n idle frames &optional locked)
           (let ((fell 0)) (dotimes (i frames) (multiple-value-bind (n2 i2 f) (hari-step n idle locked) (setf n n2 idle i2) (when f (incf fell))))
             (values n fell))))
    (check (and (= 6 (run 6 0 179)) (= 5 (run 6 0 180)) (= 5 (run 6 0 209)) (= 4 (run 6 0 210)) (= 0 (run 6 0 330))
                (= 1 (run 6 0 329)) (= 6 (run 6 0 400 t)) (= 0 (run 0 50 10)))))
  (check (and (= 180 (hari-falls-in 3 0)) (= 1 (hari-falls-in 3 179)) (= 30 (hari-falls-in 3 180)) (= 1 (hari-falls-in 3 209))))
  ;; 悪い癖: spikes from f10, 2 f apart, 10 each, unguardable, :spare; the last holds him to f38, she is free at f32: +6, no
  ;; combo; the -k copy after a K link lands every spike inside the K link's stagger (A 4 + 8 + 2 x 5 = 22 < 26)
  (let ((l (kit-command-move b :sig)) (lk (kit-l-link b :sj-k1)))
    (check (and (eq :sj-warui-kuse (mv-name l)) (= 8 (mv-s l)) (= 32 (mv-total l)) (= 10 (getf (mv-params l) :first))
                (= 6 (- (+ (getf (mv-params l) :first) (* *hari-gap* 5) *hari-last-stun*) (mv-total l)))
                (eq :sj-warui-kuse-k (mv-name lk)) (= 6 (mv-s lk)) (= 8 (getf (mv-params lk) :first))
                (< (+ 4 (getf (mv-params lk) :first) (* *hari-gap* 5)) (hitstun :stagger))
                (>= (mv-reach lk) 9.0) (= 13 *hari-dmg*) (every (lambda (k) (kit-l-link b k)) '(:sj-k1 :sj-k2 :sj-k2s :sj-k3)))))
  ;; the stitches pay: a hit JJJ is 6; blocked, the universal 24 / 46 of guard and 3 stitches either way
  (check (= 6 (reduce #'hari-sew '(:hit :hit :hit) :initial-value 0)))
  (check (= 3 (reduce #'hari-sew '(:blocked :blocked :blocked) :initial-value 0)))
  ;; the Shikai's grid: the lightest (the user, 2026-10-01: J x0.9, K x0.8: J1 25, JJJ 82, KKK 147 on hit; the Bankai's
  ;; K1 45, K3 58)
  (check (and (= 25 (mv-dmg (kit-command-move b :q))) (= 82 (+ 25 (mv-dmg (mv :senjumaru :base :sj-j2)) (mv-dmg (mv :senjumaru :base :sj-j3))))
              (= 147 (+ (mv-dmg (kit-command-move b :f)) (mv-dmg (mv :senjumaru :base :sj-k2)) (mv-dmg (mv :senjumaru :base :sj-k3))))
              (= 45 (mv-dmg (mv :senjumaru :tsuji1 :sj-t-k1))) (= 58 (mv-dmg (mv :senjumaru :tsuji1 :sj-t-k3)))))
  ;; the soldier: one string of three, 300 f, 3.5 m/s (the user's decision), one stitch when it bursts; it moves the frame
  ;; she is free (2026-10-01); each flinch outlasts the next wind-up (+4 for the hitstop: a true combo); the umbrella: a guard over f4-27,
  ;; the tendrils always fire, 40 + half the largest caught hit, at most 120, a side Step clears them (0.8 + 0.45 < 2.5)
  (check (and (= 3 (length *shinpei-combo*)) (= 300 *shinpei-life*) (~= 3.5 *shinpei-speed*)
              (= (mv-total (kit-command-move b :sp1)) (+ 10 *shinpei-rise*))
              (member '(10 senju-shinpei) (mv-on-frame (kit-command-move b :sp1)) :test #'equal)
              (loop for (h nx) on *shinpei-combo* while nx always (>= (seventh h) (+ (first nx) 4)))
              (= 74 (reduce #'+ *shinpei-combo* :key #'fifth))))
  (let ((k (kit-command-move b :sp2)))
    (check (and (member :shield (mv-flags k)) (= 4 (mv-s k)) (= 24 (mv-a k)) (eq 'senju-kasa-catch (getf (mv-params k) :catch))
                (= 40 (kasa-damage 0)) (= 70 (kasa-damage 60)) (= 120 (kasa-damage 999)) (= 1 (kit-command-cost b :sp2))
                (= 2 (kit-command-cost t1 :sp2)) (< (+ (* 0.5 (getf (mv-params k) :width)) 0.45) *step-distance*)
                (member '(28 senju-kasa-fire) (mv-on-frame k) :test #'equal))))
  ;; NUICHI: 7.7 m, <= 28 f; the Bankai's lane 8.5 m; Kikon 2 / 3, Soul Break 3 / 4
  (let ((o (kit-command-move b :kikon)) (u (kit-command-move t1 :kikon)))
    (flet ((pa (m k) (getf (mv-params m) k)))
      (check (and (~= 7.7 (kikon-rush-reach (pa o :speed) (pa o :dash-max)) 0.05) (= 28 (+ (pa o :aura) (pa o :dash-max) (mv-s o)))
                  (~= 8.5 (mv-reach u)) (= 2 (kit-kikon-konpaku b)) (= 3 (kit-kikon-konpaku t1)) (= 3 (kit-kikon-konpaku t6))
                  (eq 'sj-kikon-cine (kit-kikon-cine b)) (eq 'sj-hata-cine (kit-kikon-cine t1))))))
  ;; the loom: six forms, form k's next hank is k; a release advances along the queue (the user, 2026-09-30): 黒砂 刃金 褥
  ;; 焼野原 眼 星, then 黒砂 again; L held 20-60 (a pass per 20 f), the combo copy no hold, S 8, a 9 m reach (no chase)
  (check (and (equal (loop for n from 1 to 6 collect (hank-next n)) '(6 4 2 5 1 3))
              (equal (loop for n from 1 to 6 collect (form-hank (hank-form n))) '(1 2 3 4 5 6)) (null (form-hank :base))
              (equal (mapcar #'weave-passes '(20 39 40 59 60 61)) '(1 1 2 2 3 3))))
  (loop for n from 1 to 6
        for k = (kit :senjumaru (hank-form n))
        for l = (kit-command-move k :sig)
        for lk = (kit-l-link k :sj-t-k1)
        do (check (and (= n (getf (mv-params l) :hank)) (equal (mv-hold l) '(1 600)) (= 6 (mv-s l)) (member :bind (mv-flags l))
                       (eq 'senju-weave-release (mv-release l)) (null (mv-release lk))
                       (= n (getf (mv-params lk) :hank)) (null (mv-hold lk)) (= 8 (mv-s lk)) (getf (mv-params lk) :combo)
                       (>= (mv-reach lk) 9.0) (eq (intern (format nil "SJ-TACHINAOSHI-~d" n) :keyword) (mv-name (kit-command-move k :sp1)))
                       (= 1 (kit-command-cost k :sp1)) (kit-awakening k)
                       (zerop (mv-cooldown l)))))                 ; (no COOLDOWN row: the torn lock is L's timer)
  ;; the combo cut: L after a K link hits before the K link's stagger ends (A 4 + S 8 + unfold 10 = 22 < 26)
  (check (< (+ 4 8 *unfold-combo*) (hitstun :stagger)))
  ;; the weave's scaling: radius, life, damage never smaller with more passes; every disc's full radius + Kenpachi's hurt r
  ;; < a Step; the corridor's half-width too; the rings with no hit (眼 3.0, 星 3.5) are free of the rule
  (loop for n in '(2 3 4) do (check (< (+ (hank-radius n 3) 0.45) *step-distance*)))
  (check (< (+ (* 0.5 (hank 5 :width)) 0.45) *step-distance*))
  (loop for n from 1 to 6
        do (check (loop for p from 1 below 3
                        always (and (or (not (hank n :r)) (<= (hank-radius n p) (hank-radius n (1+ p))))
                                    (or (not (hank n :life)) (<= (hank-life n p) (hank-life n (1+ p))))
                                    (or (not (hank n :dmg)) (<= (hank-damage n p) (hank-damage n (1+ p))))))))
  (check (and (= 126 (hank-damage 2 3)) (= 90 (hank-damage 2 2)) (= 63 (hank-damage 2 1)) (= 288 (hank-life 1 3))
              (= 120 (hank-life 1 1)) (~= 2.1 (hank-radius 1 1)) (null (hank 1 :dmg)) (null (hank 6 :dmg))
              (~= 24.0 (hank-fx 4 :freeze 1)) (~= 60.0 (hank-fx 4 :freeze 3)) (~= 45.0 (hank-fx 6 :reiatsu 3))))
  ;; the awakened grid: J1 J2 J3 K2 as the Shikai's (no reach derivation: the playtest), K1 3.8 m, MAKITORI 2.5 m with its
  ;; pull to 1.4
  (check (and (~= 1.44 (mv-reach (kit-command-move t1 :q))) (~= 2.5 (mv-reach (kit-next t1 :sj-j1 :f)))
              (~= 3.8 (mv-reach (kit-command-move t1 :f))) (~= 2.5 (mv-reach (kit-next t1 :sj-k2 :f)))
              (~= 1.4 (getf (mv-params (kit-next t1 :sj-k2 :f)) :pull)) (~= 3.3 (kit-walk t1)) (~= 3.6 (kit-walk b))))
  ;; the CPU: the rule's keys, the loom's hold by distance (星 closer), the Shikai taps L
  (check (and (equal (getf (kit-ai b) :awaken) '(:min-taken 150))
              (= 31 (senju-sig-hold t1 7.0)) (= 31 (senju-sig-hold t1 5.0)) (= 21 (senju-sig-hold t1 3.0))   ; a segment; one pass
              (= 31 (senju-sig-hold t6 5.5)) (= 31 (senju-sig-hold t6 3.0)) (= 1 (senju-sig-hold b 3.0))
              (~= 0.5 (getf (kit-ai t6) :opp-rush-hold)) (null (kit-reset-form t1)) (eq :base (kit-reset-form b)))))

;; L: hold to weave, tap to release (the user, 2026-09-29): under 10 f is a tap; a weave's frames count from its 10th (those
;; 10 at once), one a frame after, summed over segments on the hank up to 3 passes; a release (the tap, K -> L, SP1) makes
;; the stored passes, at least 1; a hit while weaving voids the hank (the next one, nothing woven)
(flet ((seg (woven frames) (loop for h from 1 to frames do (setf woven (weave-add woven h))) woven))
  (check (and (= 10 *weave-tap*) (weave-tap-p 9) (not (weave-tap-p 10))
              (= 0 (seg 0 9)) (= 10 (seg 0 10)) (= 15 (seg 0 15))            ; a tap weaves nothing; a hold counts from f1
              (= 30 (seg (seg 0 15) 15)) (= 1 (weave-stored (seg (seg 0 15) 15)))   ; two segments of 15: one pass
              (= 45 (seg (seg (seg 0 15) 15) 15)) (= 2 (weave-stored 45))
              (= 60 (seg 45 40)) (= 3 (weave-stored (seg 0 200)))            ; capped at three passes
              (= 30 (seg 30 9))                                             ; a tap keeps what is stored
              (= 1 (release-passes 0)) (= 1 (release-passes 19)) (= 2 (release-passes 45)) (= 3 (release-passes 60))
              (equal '(2 0) (multiple-value-list (weave-void 3))) (equal '(3 0) (multiple-value-list (weave-void 6))))))
(check (and (eq :sig (mv-kind (find-move :sj-weave-stop))) (= 6 (mv-total (find-move :sj-weave-stop)))))

;; J weaves, K releases (the user, 2026-09-29): a release needs a stored pass: a tap with nothing woven is refused (the cue,
;; then it stops), as over a live zone; a weave just stops; K -> L (the -k copies) is refused at 0 passes, J -> L never
;; (it weaves), nor SP1 (it releases at 0 as at 1, RELEASE-PASSES); J -> L is HITOKOSHI in every loom form after every
;; J link (+1 pass at f8, at most 3; 8/0/10: -3 after a J1 / J2 hit, +5 after J3, <= -17 blocked), none in the Shikai
(let ((t1 (kit :senjumaru :tsuji1)) (hk (find-move :sj-hitokoshi)))
  (check (and (not (release-ok-p 0)) (not (release-ok-p 19)) (release-ok-p 20)
              (eq :refused (weave-release-act 5 0 nil)) (eq :refused (weave-release-act 9 19 nil))      ; a tap at 0 passes
              (eq :release (weave-release-act 5 20 nil)) (eq :refused (weave-release-act 5 60 t))
              (eq :stop (weave-release-act 10 0 nil)) (eq :stop (weave-release-act 40 60 t))))
  (check (and (not (loom-ok-p :sig (kit-l-link t1 :sj-t-k1) 0)) (not (loom-ok-p :sig (kit-l-link t1 :sj-k2) 19))   ; K -> L
              (loom-ok-p :sig (kit-l-link t1 :sj-t-k1) 20) (loom-ok-p :sig nil 0) (loom-ok-p :sig hk 0)
              (loom-ok-p :sp1 nil 0) (= 1 (release-passes 0))))                                                ; SP1 at 0
  (check (and (= 20 (quick-weave 0)) (= 1 (weave-stored (quick-weave 0))) (= 35 (quick-weave 15))              ; +1 pass
              (= 2 (weave-stored (quick-weave (quick-weave 0)))) (= 60 (quick-weave 45)) (= 60 (quick-weave 60))  ; cap 3
              (= 3 (weave-stored (quick-weave (quick-weave (quick-weave (quick-weave 0))))))))
  (check (and (eq :sig (mv-kind hk)) (= 8 (mv-s hk)) (= 18 (mv-total hk)) (null (mv-hold hk))
              (equal (mv-on-frame hk) '((8 senju-quick-weave))) (null (getf (mv-params hk) :combo))))
  (let ((j1 (kit-command-move t1 :q)) (j3 (kit-next t1 :sj-j2 :q)))
    (check (= -3 (- (hitstun :flinch) (mv-a j1) (mv-total hk))))                          ; safe-ish on hit
    (check (= 5 (- (hitstun :stagger) (mv-a j3) (mv-total hk))))
    (check (<= (- (+ (mv-adv-block j1) *chain-lead*) (mv-total hk)) -17)))              ; punishable blocked
  (loop for n from 1 to 6
        for k = (kit :senjumaru (hank-form n))
        do (check (and (every (lambda (j) (eq hk (kit-l-link k j))) '(:sj-j1 :sj-j2 :sj-j3 :sj-j2s))
                       (every (lambda (j) (getf (mv-params (kit-l-link k j)) :combo)) '(:sj-t-k1 :sj-k2 :sj-k2s :sj-t-k3))
                       (~= 0.35 (getf (kit-ai k) :l-after-j)))))
  (check (notany (lambda (j) (kit-l-link (kit :senjumaru :base) j)) '(:sj-j1 :sj-j2 :sj-j3 :sj-j2s)))
  (check (every (lambda (cf) (or (eq (first cf) :senjumaru) (null (kit-l-after-j (apply #'kit cf))))) *forms*)))

;; SP1 裁ち直し releases the next two hanks (the user, 2026-09-29): the queue moves +2 (6 wraps to 1); the move cuts the live
;; zone(s) at f0 and releases at f8 and f14 (the combo cut's rules); off a landed link both land inside a stagger (26 f:
;; cancel frame +1, then S + unfold); its :tell is its first hitting hank's; 1 bar
(check (equal (loop for n from 1 to 6 collect (multiple-value-list (tachi-hanks n)))
              '((1 6 3) (2 4 5) (3 2 4) (4 5 1) (5 1 6) (6 3 2))))
(loop for n from 1 to 6
      for k = (kit :senjumaru (hank-form n))
      for sp = (kit-command-move k :sp1)
      do (check (and (eq :sp (mv-kind sp)) (= 8 (mv-s sp)) (= 30 (mv-total sp)) (= 1 (kit-command-cost k :sp1))
                     (equal (mv-on-frame sp) '((0 senju-combo-cut) (8 senju-tachi-release) (14 senju-tachi-release)))
                     (= 6 *tachi-second*)
                     (< (+ 1 8 *unfold-combo*) (hitstun :stagger)) (< (+ 1 8 *tachi-second* *unfold-combo*) (hitstun :stagger))
                     (equal (getf (mv-params sp) :tell)
                            (cond ((hank-hits-p n) '(10 22)) ((hank-hits-p (hank-next n)) '(16 28)))))))
(check (and (null (getf (mv-params (kit-command-move (kit :senjumaru :tsuji1) :sp1)) :tell))   ; 眼 + 星: no hit
            (equal '(16 28) (getf (mv-params (kit-command-move (kit :senjumaru :tsuji6) :sp1)) :tell))   ; 星 + 黒砂
            (eq 'senju-sp-ender (getf (kit-ai (kit :senjumaru :tsuji1)) :sp-ender))
            (null (getf (kit-ai (kit :senjumaru :tsuji1)) :skip))))

;; The queue in three SP1 pairs (the user, 2026-09-30): 黒砂 → 刃金 → 褥 → 焼野原 → 眼 → 星, wrapping to 黒砂; the awakening
;; enters 黒砂's form; SP1 from an even slot releases a designed pair (黒砂+刃金, 褥+焼野原, 眼+星), from an odd one a cross
;; pair (刃金+褥, 焼野原+眼, 星+黒砂); SP1 keeps the parity, a single release (or a voided weave) flips it; each hank keeps its data
(let* ((b (kit :senjumaru :base)) (n0 (form-hank (kit-awaken-form b))))
  (check (and (eq :tsuji3 (kit-awaken-form b)) (= 3 n0) (equal "黒砂の腸" (hank n0 :kanji)) (equal *hank-order* '(3 2 4 5 1 6))))
  (check (equal (loop repeat 7 for n = n0 then (hank-next n) collect (hank n :short))
                '("KOKUSA" "HAGANE" "SHITONE" "YAKENOHARA" "ME" "HOSHI" "KOKUSA")))
  (flet ((pair (n) (multiple-value-bind (a c) (tachi-hanks n) (list a c))))
    (check (equal (mapcar #'pair (remove-if-not #'tachi-aligned-p *hank-order*)) '((3 2) (4 5) (1 6))))
    (check (equal (mapcar #'pair (remove-if #'tachi-aligned-p *hank-order*)) '((2 4) (5 1) (6 3))))
    (dolist (n *hank-order*)
      (check (eq (tachi-aligned-p n) (tachi-aligned-p (nth-value 2 (tachi-hanks n)))))      ; SP1 keeps the parity
      (check (not (eq (tachi-aligned-p n) (tachi-aligned-p (hank-next n)))))                ; a single release flips it
      (check (not (eq (tachi-aligned-p n) (tachi-aligned-p (weave-void n))))))              ; so does a voided weave
    ;; repeated SP1 from the entry: the three pairs, then 黒砂 + 刃金 again; one tap first: the cross pairs
    (check (equal (loop repeat 4 for n = n0 then (nth-value 2 (tachi-hanks n)) collect (pair n)) '((3 2) (4 5) (1 6) (3 2))))
    (check (equal (loop repeat 3 for n = (hank-next n0) then (nth-value 2 (tachi-hanks n)) collect (pair n)) '((2 4) (5 1) (6 3))))))
(check (equal *hanks*
              '((1 :name "BANRA NO ME" :short "ME" :kanji "万朶の眼" :r 3.0 :life 240)
                (2 :name "HAGANE NO YOROI" :short "HAGANE" :kanji "刃金のよろい" :r 2.0 :rise 16 :dmg 90 :guard 24 :after 20)
                (3 :name "KOKUSA NO HARAWATA" :short "KOKUSA" :kanji "黒砂の腸" :r 2.0 :life 240 :away 0.4 :period 60 :swirl 12 :dmg 40)
                (4 :name "ITETSUKU SHITONE" :short "SHITONE" :kanji "凍てつく褥" :r 2.0 :life 240 :dmg 70 :freeze 40 :frost 60)
                (5 :name "YAKENOHARA" :short "YAKENOHARA" :kanji "焼野原" :width 2.0 :max 10.0 :hits 2 :dmg 45 :life 150 :chip 0.12)
                (6 :name "YAMIYO NO HOSHIYO" :short "HOSHI" :kanji "闇夜の星よ" :r 3.5 :life 240 :reiatsu 30.0 :fs 15.0))))

;; 星 siphons (the user, 2026-09-29): inside her live star he gains nothing; his Reiatsu / flash-step gains go to her, his
;; Fighting Spirit (and every kit meter: combat.lisp SIPHON-OF) is lost; the drain gives her what it really took, capped
(multiple-value-bind (r fs aw sr sfs) (hit-gains 100 40 nil)
  (check (and (~= r (reiatsu-gain 100 40)) (~= fs (* 40 *fs-taken*)) (~= aw (awakening-gain 100 40 0)) (zerop sr) (zerop sfs))))
(multiple-value-bind (r fs aw sr sfs) (hit-gains 100 40 t)
  (check (and (zerop r) (zerop fs) (zerop aw) (~= sr (reiatsu-gain 100 40)) (~= sfs (* 40 *fs-taken*)) (plusp sr) (plusp sfs))))
(multiple-value-bind (his hers) (gauge-move 50.0 0.5 20.0 100.0) (check (and (~= his 49.5) (~= hers 20.5))))
(multiple-value-bind (his hers) (gauge-move 0.2 0.5 20.0 100.0) (check (and (~= his 0.0) (~= hers 20.2))))   ; what it took
(multiple-value-bind (his hers) (gauge-move 50.0 0.5 99.8 100.0) (check (and (~= his 49.5) (~= hers 100.0))))  ; capped
(check (every (lambda (f) (eq 'senju-siphon (kit-hook (kit :senjumaru f) :siphon))) '(:base :tsuji1 :tsuji6)))
(check (every (lambda (cf) (or (eq (first cf) :senjumaru) (null (kit-hook (apply #'kit cf) :siphon)))) *forms*))

;; The reach matches the art (the user's playtests, 2026-09-29: first Senjumaru's, DUEL_SENJUMARU.md "Playtest: reach
;; matches the art"; then every character's J / K, docs/duel/DUEL_STRINGS.md §13): at a J / K link's hit frames what it strikes
;; with reaches the volume's far edge, where his hurt cylinder's near side may stand (an arc's r, a capsule's b + r): the
;; held weapon's tip (the rig's FK over the art files' own poses and bodies; radial for an arc, ahead for a capsule), the
;; fist / foot / sleeve of a strike that isn't the blade (*STRIKERS*), or Senjumaru's K prop's far end (*SJ-STRIKE-REACH*).
;; The Breaker's strike too (its clip 2: the grab is close, §14; it may fall short, never over).
;; Within 0.15 m either way for the J links and Senjumaru's K props; the other K links, and every link of the forms that play
;; another form's clip at another reach or blade (*REACH-ONE-SIDED*), may fall short (fire, ice, cloth and the ember line
;; carry them) but never pass the edge by more than 0.15 m. 片腕 KATAUDE is
;; the exception: the base clips at x0.7 with the broken cleaver (the ruined arm; pass the edge by up to 0.6 m, as before
;; the J cut). The host has no C: anim.lisp's float intrinsics as plain CL
(defmacro engine::f-max (a b) `(max ,a ,b))
(defmacro engine::f-mod (a b) `(mod ,a ,b))
(defmacro engine::f-sin (a) `(sin ,a))
(defmacro engine::f-cos (a) `(cos ,a))
(defmacro engine::f-wrap (a) `(let ((x ,a)) (- x (* 6.2831853f0 (floor (+ x 3.14159265f0) 6.2831853f0)))))
(load (merge-pathnames "../engine/lisp/anim.lisp" *load-truename*))
(defparameter *strikers* '((:ya-sleeve . :hand-l) (:ke-kick . :foot-r) (:ke-b-hook . :hand-l) (:ic-q1 . :hand-l)
                           (:ic-q2 . :hand-l) (:ru-palm . :hand-l)
                           (:ya-ikkotsu . :hand-r) (:ke-shoulder . :shoulder-l) (:ru-hainawa . :hand-l) (:sj-saidan . :hand-r))
  "Clip -> the joint that strikes when it isn't the held weapon's tip (Ichigo's Shikai J: the short blade held reversed
along the left forearm, so the fist leads).")
(defparameter *reach-one-sided* '((:yamamoto :bankai-east) (:yamamoto :bankai-west) (:kenpachi :nozarashi)
                                  (:kenpachi :bankai) (:rukia :zero)))
(let ((bodies nil) (weapons nil) (strike nil) (points nil) (butt 0.0))
  (dolist (art '("yama" "ken" "rukia" "ichigo" "senjumaru" "lille"))
    (with-open-file (in (merge-pathnames (format nil "../duel/lisp/~a-art.lisp" art) *load-truename*))
      (let ((*package* (find-package :duel)))
        (loop for form = (read in nil in) until (eq form in)
              when (consp form)
                do (case (first form)
                     ((defpose defclip defstrike) (eval form))
                     (defun (when (eq (second form) 'sj-okobo-props) (eval form)))
                     (defparameter (case (second form)
                                     (*sj-strike-reach* (setf strike (eval (third form))))
                                     (*lb-strike-points* (setf points (eval (third form))))   ; Lille: the plank, the
                                     (*lb-butt* (setf butt (eval (third form))))))           ; wing / arm tips
                     (defbody (push (cons (second form) (third form)) bodies))
                     (defweapon (push (cons (second form) (getf (third form) :length)) weapons)))))))
  (let ((jm (make-f32 (* 16 +nj+))) (pose (make-f32 +pose-n+)) (v (make-f32 3))
        (min-hurt (loop for (nil . b) in bodies minimize (getf b :hurt-r))) (max-hurt (loop for (nil . b) in bodies maximize (getf b :hurt-r))))
    ;; J is close (the J cut): the chase and a lunge stop at *LUNGE-STOP*, outside any two hurt cylinders' push-apart, and
    ;; every J follow-up's chase goal is inside its reach + the thinnest hurt radius (it connects)
    (check (> *lunge-stop* (* 2 max-hurt)))
    (dolist (cf *forms*)
      (let* ((k (apply #'kit cf)) (b (cdr (assoc (kit-body k) bodies)))
             (b (or b (cdr (assoc (first cf) bodies))))                  ; (a body variant: the rig of its character)
             (props (if (eq (first cf) :senjumaru) (sj-okobo-props) (and (getf b :props) (apply #'make-rig-proportions (getf b :props)))))
             (wlen (cdr (assoc (kit-weapon k) weapons))))
        (dolist (lm (append (remove-if (lambda (l) (zerop (length (mv-hits (first l))))) (link-moves k))   ; (EN's traces)
                            (let ((br (kit-command-move k :breaker))) (and br (list (list br :breaker))))))
                                                               ; (the stance's HOSHA / TAISHA: line hits from the muzzle, §23.1)
          (let* ((mv (first lm)) (hw (svref (mv-hits mv) 0)) (vol (first (hw-vols hw))) (cap (> (aref vol 0) 0.5))
                 (edge (if cap (+ (aref vol 2) (aref vol 4)) (aref vol 1)))
                 (clip (if (eq (second lm) :breaker) (mv-clip-2 mv) (mv-clip mv)))   ; (the Breaker's strike: its clip 2)
                 (point (second (assoc clip points)))                ; Lille's: :weapon (the plank) or a joint
                 (striker (or (cdr (assoc clip *strikers*)) (and point (not (eq point :weapon)) point)))
                 (art (or (third (assoc clip strike))
                          (loop for sf from (hw-from hw) below (hw-to hw)
                                maximize (progn
                                           (clip-sample! pose (find-clip clip) (/ (* sf (mv-clip-speed mv)) 60.0))
                                           (pose-fk! jm pose 0f0 0f0 0f0 0f0 (f32 (getf b :scale)) (f32 (deg (getf b :hunch 0))) props)
                                           (if striker                            ; (yaw 0 faces -Z)
                                               (joint-point! v jm (joint-index striker) 0f0 0f0 0f0)
                                               (joint-point! v jm (ji :weapon-r) 0f0 0f0 (f32 (if (eq point :weapon) butt (- wlen)))))
                                           (if cap (- (aref v 2)) (sqrt (+ (expt (aref v 0) 2) (expt (aref v 2) 2))))))))
                 (d (- art edge)))
            (when (eq (mv-kind mv) :quick)
              (check (<= (max *lunge-stop* (- (mv-reach mv) *chase-margin*)) (- (+ (mv-reach mv) min-hurt) 0.02))))
            (check (or (if (equal cf '(:kenpachi :kataude))
                           (<= d 0.6)
                           (and (<= d 0.15)
                                (or (>= d -0.15)
                                    (and (not (assoc clip strike))   ; (her K props: both ways)
                                         (or (member cf *reach-one-sided* :test #'equal) (member (mv-kind mv) '(:flash :breaker)))))))
                       (format t "~a ~a: the volume ends ~,2f m, the art ~,2f m~%" (second cf) (mv-name mv) edge art)))))))))

;; J is short, K long (the user, 2026-09-29, docs/duel/DUEL_STRINGS.md §13): in every form every K link reaches at least 0.5 m further
;; than any J link at the same position of the string; 片腕's short K against the J floor (2026-10-06) excepted
(dolist (cf (remove '(:kenpachi :kataude) *forms* :test #'equal))
  (let ((lm (link-moves (apply #'kit cf))))
    (loop for n from 1 to 3
          do (let ((j (loop for (m k) in lm when (and (= k n) (eq (mv-kind m) :quick)) maximize (mv-reach m)))
                   (kk (loop for (m k) in lm when (and (= k n) (eq (mv-kind m) :flash)) minimize (mv-reach m))))
               (check (or (>= (- kk j) 0.5) (format t "~a link ~d: J ~,2f K ~,2f~%" cf n j kk)))))))

;;; ---------------------------------------------------------------- the guard lock (the user 2026-09-30, DUEL_DESIGN.md "Guard lock")
;; the lock holds a blockstun past its end while the attacker's move may still chain; it ends when that can't happen
(check (guard-locked-p :guard-hit nil 0 :move :main 20 10 3 12 t t))                ; frame 20 of 25: a chain may still start
(check (not (guard-locked-p :guard-hit nil 0 :move :main 24 10 3 12 t t)))          ; frame 24: the last chance was 24
(check (not (guard-locked-p :guard-hit nil 0 :move :main 20 10 3 12 t nil)))        ; nothing left to chain (a link 3)
(check (not (guard-locked-p :guard-hit nil 0 :move :main 20 10 3 12 nil t)))        ; his move never touched him
(check (not (guard-locked-p :guard-hit t 0 :idle nil 0 0 0 0 nil nil)))             ; a new neutral action ends it
(check (not (guard-locked-p :guard-hit t 0 :step nil 0 0 0 0 nil nil)))
;; a follow-up he started carries it through its startup and active frames, then its own window decides
(check (and (guard-locked-p :guard-hit t 0 :move :main 3 10 3 12 t nil) (guard-locked-p :guard-hit t 0 :move :hold 0 10 3 12 t nil)
            (guard-locked-p :guard-hit t 0 :move :main 12 10 3 12 t nil) (not (guard-locked-p :guard-hit t 0 :move :main 13 10 3 12 t nil))))
(check (and (guard-locked-p :guard-hit t 5 :idle nil 0 0 0 0 nil nil)                ; ORANGE's window: the next move is the chain
            (not (guard-locked-p :guard-hit t 5 :step nil 0 0 0 0 nil nil))))
;; the escapes: BLUE (and the awakening) leave blockstun, the lock with it; BLUE is still a blockstun press
(check (and (eq (burst-mode :guard-hit nil 0 nil) :blue) (not (guard-locked-p :idle t 5 :move :main 20 10 3 12 t t))))
(defun locked-free-steps (mv more)
  "FREE-STEPS with the guard lock (fighter.lisp STUN-STEP / FIGHTER-SYSTEM): MV blocked on its first hit, MORE = it may
chain. The lock is judged after each step (from the hit's next one: the hit lands after the fighters stepped) for the
defender's next step. Values: the attacker's and the defender's first actionable step."
  (let* ((enter (mv-enter mv)) (h (- (mv-first-hit mv) enter))
         (end (move-end-frame (mv-s mv) (mv-a mv) (mv-r mv) (mv-whiff mv) :block nil))
         (stun (blockstun (mv-total mv) (mv-first-hit mv) (mv-adv-block mv))) (lock nil))
    (values (loop for step from 1 when (>= (+ enter step) end) return (1+ step))
            (loop for step from (1+ h) for sf from 1
                  when (and (>= sf stun) (not lock)) return (1+ step)
                  do (let ((fr (+ enter step)))
                       (setf lock (guard-locked-p :guard-hit lock 0 (if (>= fr end) :idle :move) :main fr
                                                  (mv-s mv) (mv-a mv) (mv-r mv) t more)))))))
;; every blocked string link that goes on holds the defender to even (the attacker's move ends as he is freed); a link
;; that can't (link 3, no L link ready) keeps its block advantage: an ender is still punishable
(dolist (cf *forms*)
  (let ((k (apply #'kit cf)))
    (dolist (row (link-moves k))
      (let ((m (first row)))
        (when (and (integerp (mv-adv-block m)) (plusp (length (mv-hits m))))
          (multiple-value-bind (att def) (locked-free-steps m (string-link-p k (mv-name m)))
            (check (or (= (- def att) (if (string-link-p k (mv-name m)) (max 0 (mv-adv-block m)) (mv-adv-block m)))
                       (format t "~a ~a: lock ~d, adv ~d~%" cf (mv-name m) (- def att) (mv-adv-block m))))))))))
(let* ((k (kit :yamamoto :base)) (j1 (kit-command-move k :q)) (j3 (kit-next k (mv-name (kit-next k (mv-name j1) :q)) :q)))
  (check (and (string-link-p k (mv-name j1)) (not (string-link-p k (mv-name j3))) (< (mv-adv-block j3) -2)
              (= (mv-adv-block j3) (multiple-value-bind (a d) (locked-free-steps j3 nil) (- d a))))))

;;; ================================================================ :x-axis lines: the CPU's threat perception (DUEL_LILLE §11.3,
;;; gap G1 / G8; ai.lisp SNAP-LIVE-P / SNAP-NEAR-P, AI-OPP-AIM, AI-OPP-REFLECT; the moves here are fakes, no kit has the flag yet)
(check (~= (line-dist 0.0 0.0 0.0 0.6 31.0 0.5 -10.0) 0.5))      ; yaw 0 faces -Z: 0.5 m beside the line
(check (~= (line-dist 0.0 0.0 0.0 0.6 31.0 0.0 2.0) 2.6))        ; behind him: from the muzzle (0.6 m ahead)
(check (~= (line-dist 0.0 0.0 0.0 0.6 31.0 0.0 -40.0) 9.0))      ; past the line's end
(check (~= (line-dist 1.0 1.0 (deg 90.0) 0.0 10.0 -4.0 1.0) 0.0)) ; yaw 90: faces -X
(let* ((shot (parse-move :x-fake '(:kind :sig :hold (34 64) :startup 4 :active 2 :recovery 26 :dmg 40
                                   :vol (:cap 0.6 31.0 1.2 0.25) :flags (:ranged :x-axis) :params (:lock 34))))
       (beam (parse-move :x-fake-beam '(:kind :sp :startup 60 :active 30 :recovery 40 :dmg 240
                                        :vol (:cap 0.6 31.0 1.4 1.2) :flags (:ranged :x-axis :reflectable)
                                        :params (:lock 40 :blast 60))))
       (sanren (parse-move :x-fake-3 '(:kind :sp :startup 12 :active 2 :recovery 24 :dmg 30 :vol (:cap 0.6 20.0 1.2 0.25)
                                       :hits ((12 14) (22 24) (32 34)) :flags (:ranged :x-axis))))
       (on (+ 0.4 *ai-line-margin*)))                            ; a 0.4 m hurt radius + the margin
  (check (= (move-lock shot) 34))
  (check (= (move-lock beam) 40))
  (check (null (move-lock sanren)))
  (check (= (move-active-end shot) 6))
  (check (= (move-active-end sanren) 34))                        ; every line of it, not S + A
  ;; on the line at 20 m (the generic reach test, 31 + 1.5, is true everywhere); 3 m beside it at 20 m: not
  (check (<= (x-line-gap shot 0.0 0.0 0.0 0.0 -20.0) on))
  (check (> (x-line-gap shot 0.0 0.0 0.0 3.0 -20.0) on))
  (check (~= (x-line-gap shot 0.0 0.0 0.0 0.5 -10.0) 0.25))      ; the line's own radius taken off
  (check (> (x-line-gap shot 0.0 0.0 0.0 0.0 1.5) on))           ; right behind him
  (check (<= (x-line-gap beam 0.0 0.0 0.0 1.6 -25.0) on))        ; the 1.2 m beam is wider
  ;; the aim: no threat before the lock (no guard through the aim), a threat from it; the shot until its window ends
  (check (not (x-live-p shot :hold 10 0)))
  (check (not (x-live-p shot :hold 33 0)))
  (check (x-live-p shot :hold 34 0))
  (check (x-live-p shot :hold 64 0))
  (check (x-live-p shot :main 40 5))
  (check (not (x-live-p shot :main 40 6)))
  ;; a wind-up with a :lock: from the lock to the window's end
  (check (not (x-live-p beam :main 0 39)))
  (check (x-live-p beam :main 0 40))
  (check (x-live-p beam :main 0 89))
  (check (not (x-live-p beam :main 0 90)))
  (check (x-live-p sanren :main 0 0))                            ; no lock: from frame 0, through its 3rd line
  (check (x-live-p sanren :main 0 33))
  (check (not (x-live-p sanren :main 0 34)))
  (check (not (x-live-p shot :aura 0 0))))
;; the Step off the line goes away from it, to the side he is on (the CPU's stick: TOWARD-STRAFE-DIR)
(loop for (ax az yaw px pz) in '((0.0 0.0 0.0 0.3 -10.0) (0.0 0.0 0.0 -0.3 -10.0) (2.0 1.0 0.7 -3.0 -4.5) (2.0 1.0 0.7 -2.0 -6.5)
                                 (-5.0 3.0 -2.5 0.5 -1.0) (-5.0 3.0 -2.5 -1.0 0.0))
      do (let* ((st (line-off-strafe ax az yaw px pz ax az))
                (fx (fwd-x (float yaw 1f0))) (fz (fwd-z (float yaw 1f0)))
                (al (+ (* (- px ax) fx) (* (- pz az) fz))) (lx (- px ax (* al fx))) (lz (- pz az (* al fz))))
           (multiple-value-bind (dx dz) (toward-strafe-dir 0.0 st px pz ax az)
             (check (plusp (+ (* dx lx) (* dz lz)))))))
;; chances read off the opponent's kit, by difficulty (EASY <= NORMAL <= HARD; :opp-reflect 0.3 -> 0.1 / 0.3 / 0.5)
(check (~= (opp-chance 0.3 :easy) 0.1))
(check (~= (opp-chance 0.3 :normal) 0.3))
(check (~= (opp-chance 0.3 :hard) 0.5))
(check (= (opp-chance 0.6 :hard) 1.0))
(check (<= (opp-chance 0.25 :easy) (opp-chance 0.25 :normal) (opp-chance 0.25 :hard)))
;; the reflect's timing (a blast at f60): a guard pressed at f52 is 8 f old there (2-10: DUEL_LILLE §6.3), a Hoho at f50
;; (f48-f60); hands off just before; nothing after the blast
(check (null (reflect-action 45 60 t)))
(check (eq (reflect-action 46 60 t) :wait))
(check (eq (reflect-action 51 60 t) :wait))
(check (eq (reflect-action 52 60 t) :guard))
(check (<= 2 (- 60 (- 60 *ai-reflect-guard-lead*)) 10))
(check (eq (reflect-action 60 60 t) :guard))
(check (eq (reflect-action 61 60 t) :late))
(check (null (reflect-action 43 60 nil)))
(check (eq (reflect-action 44 60 nil) :wait))
(check (eq (reflect-action 50 60 nil) :hoho))
(check (<= 48 (- 60 *ai-reflect-hoho-lead*) 60))
(check (<= (- 60 *ai-reflect-hoho-lead*) (+ 60 0) (+ (- 60 *ai-reflect-hoho-lead*) *perfect-lead*)))   ; (it is perfect)
;; inert for the first five characters: no move has :x-axis / :reflectable, no form the keys :opp-aim / :opp-reflect /
;; :bankai-ok (Lille's forms have them: DUEL_LILLE §8, §11.3)
(dolist (cf (remove :lille *forms* :key #'first))
  (let ((k (apply #'kit cf)))
    (check (null (kit-bankai-ok k)))
    (check (not (or (getf (kit-ai k) :opp-aim) (getf (kit-ai k) :opp-reflect))))
    (loop for m being the hash-values of (kit-moves k)
          do (check (not (intersection '(:x-axis :reflectable) (mv-flags m)))))))

;;; ================================================================ Lille Barro (docs/duel/DUEL_LILLE.md §12 G10; batch 1; rework R §22)
(let* ((b (kit :lille :base)) (j (kit :lille :jilliel)) (mu (kit :lille :jilliel-mujittai)) (o (kit :lille :shin))
       (kn (kit :lille :jilliel-kin)) (kmu (kit :lille :jilliel-kin-mujittai)) (ok (kit :lille :shin-kin))
       (x (find-move :lb-k-shot)) (xw (svref (mv-hits x) 0)))
  ;; the distance damage (decision 10): 40 at <= 4 m, 80 at 12, 120 at >= 20; the window deals 40, the bonus the rest
  (check (and (= 40 (lb-x-damage 0.0)) (= 40 (lb-x-damage 4.0)) (= 80 (lb-x-damage 12.0)) (= 120 (lb-x-damage 20.0))
              (= 120 (lb-x-damage 31.0)) (= 40 (hw-dmg xw)) (= 80 (lb-x-bonus 20.0)) (zerop (lb-x-bonus 2.0))
              (< (lb-x-damage 8.0) (lb-x-damage 9.0))))
  ;; through guard (decision 2): a blocked shot chips 15 % (never kills) and drains 30: four blocked shots crush a full gauge
  (check (and (~= (hw-chip xw) 0.15) (= 30 (hw-guard xw)) (= -14 (mv-adv-block x))
              (let ((gg *gg-max*) (n 0)) (loop until (nth-value 1 (gg-drain gg (hw-guard xw))) do (setf gg (gg-drain gg (hw-guard xw))) (incf n))
                (= n 3))                                                       ; three leave 10, the 4th crushes
              (= 18 (chip-damage 120 (hw-chip xw) 1000)) (< (chip-damage 120 (hw-chip xw) 5) 5)))
  ;; stance, armour, DRINK and a parry take it as any hit: the line carries no :unguardable / :rend / :breaker / :guard-crush;
  ;; only :ranged :x-axis :uncatchable, on every line move (TAISHA's bullet too, §23.1), and on no Kikon lane or J / K (nor
  ;; HOSHA's bullets: :ranged, guardable, not the X-axis)
  (let ((lines '(:lb-k-shot :lb-k-k :lb-sanren :lb-hiren :lb-nijushi :lb-trompete)))
    (check (every (lambda (n) (let ((m (find-move n)))
                                (and (subsetp '(:ranged :x-axis :uncatchable) (mv-flags m))
                                     (notany (lambda (fl) (member fl (mv-flags m))) '(:unguardable :rend :breaker :guard-crush))
                                     (loop for w across (mv-hits m) always (and (~= (hw-chip w) 0.15) (subsetp '(:x-axis :uncatchable) (hw-flags w)))))))
                  lines))
    (check (every (lambda (k) (let ((km (kit-command-move k :kikon))) (not (member :x-axis (mv-flags km))))) (list b j kn o)))
    (check (every (lambda (k) (every (lambda (l) (not (member :x-axis (mv-flags (first l))))) (link-moves k))) (list b j kn o)))
    (check (and (member :ranged (mv-flags (find-move :lb-k-j))) (not (member :x-axis (mv-flags (find-move :lb-k-j))))
                (loop for w across (mv-hits (find-move :lb-k-j)) never (or (hw-chip w) (member :x-axis (hw-flags w)))))))
  (check (and (eq (resolve-contact :stance) :absorbed) (eq (resolve-contact :armor) :armored) (eq (resolve-contact :guard) :blocked)
              (eq (resolve-contact :parry :hazard t) :hit) (null (resolve-contact :invuln))))
  ;; L 狙撃構え SOGEKI-GAMAE (decision 17, §22.1): the stance up at f6, held 30 f (90 with L held) then R 14, no hits; its
  ;; branches are non-button strings; L after a K link opens it at f4; the dash comes back at f6 (the charge kept); the
  ;; old hold shot and the K -> L snap shot are gone
  (let ((k0 (kit-command-move b :sig)) (kk (kit-l-link b :lb-k1)))
    (check (and (eq :lb-kamae (mv-name k0)) (= 6 (mv-s k0) *lb-kamae-up*) (= 110 (mv-total k0) (+ *lb-kamae-up* *lb-kamae-max* 14))
                (zerop (length (mv-hits k0))) (eq :lb-kamae-k (mv-name kk)) (= 4 (mv-enter kk))
                (= 6 (mv-enter (find-move :lb-kamae-re))) (null (mv-on-frame (find-move :lb-kamae-re)))
                (equal (mv-on-frame kk) '((4 lb-kamae-enter))) (= 30 *lb-kamae-tap*)
                (eq (kit-next b :lb-kamae :kamae-l) x) (eq (kit-next b :lb-kamae-k :kamae-j) (find-move :lb-k-j))
                (eq (kit-next b :lb-kamae-re :kamae-k) (find-move :lb-k-k))
                (eq (kit-next b :lb-kamae :kamae-step) (find-move :lb-k-dash))
                (eq (kit-next b :lb-k-dash :kamae-back) (find-move :lb-kamae-re))
                (null (kit-l-link b :lb-j1)) (not (string-link-p b :lb-kamae))
                (notany (lambda (n) (gethash n *moves*)) '(:lb-x-axis :lb-x-quick :lb-volley)))))
  ;; the hold: past the tap with L up it recovers (R 14), not with L held, not past the held maximum
  (check (and (not (lb-kamae-hold-over-p 35 nil)) (lb-kamae-hold-over-p 36 nil) (not (lb-kamae-hold-over-p 36 t))
              (lb-kamae-hold-over-p 95 nil) (not (lb-kamae-hold-over-p 96 nil))))
  ;; its L: locked on the press (track 0, a threat from frame 0), fires 10 f later, A2 R26: f6 + 24 + 10 + 2 + 26 = 68 f
  (check (and (= 10 (mv-s x) *lb-lock-min*) (= 2 (mv-a x)) (= 26 (mv-r x)) (zerop (mv-track x)) (= 0 (move-lock x))
              (x-live-p x :main 0 0) (x-live-p x :main 0 11) (not (x-live-p x :main 0 12))
              (= 68 (+ *lb-kamae-up* *lb-charge-f* (mv-s x) (mv-a x) (mv-r x)))))
  ;; quick (charge < 24) 40 flat, charged (>= 24) the distance curve: charge 23 vs 24
  (check (and (not (lb-kamae-charged-p 23)) (lb-kamae-charged-p 24) (= 40 (lb-k-shot-damage 23 20.0))
              (= 120 (lb-k-shot-damage 24 20.0)) (= 40 (lb-k-shot-damage 24 3.0)) (= 80 (lb-k-shot-damage 30 12.0))))
  ;; the charge clock: up at f6 (0), +1 a step, once a step (a second call on the same tick counts nothing), through the
  ;; dash (its frames count): an L pressed at f30 is charged, at f29 not; after a 12 f dash from f6 the re-entry is charged
  ;; 12 steps later
  (let ((st (make-lbs)))
    (loop for sf from 0 to 29 do (lb-kamae-clock st sf sf))
    (check (and (lbs-k-up st) (= 23 (lbs-charge st)) (not (lb-kamae-charged-p (lbs-charge st)))))
    (lb-kamae-clock st 29 29)
    (check (= 23 (lbs-charge st)))
    (lb-kamae-clock st 30 30)
    (check (lb-kamae-charged-p (lbs-charge st))))
  (let ((st (make-lbs)) (now 0))
    (loop for sf from 0 to 6 do (lb-kamae-clock st sf (incf now)))          ; up at f6, the dash pressed there
    (loop repeat 11 do (lb-kamae-clock st nil (incf now)))                  ; the dash's f1-f11
    (lb-kamae-clock st 6 now)                                               ; (the re-entry on the dash's f11: once)
    (check (= 11 (lbs-charge st)))
    (loop for sf from 7 to 19 do (lb-kamae-clock st sf (incf now)))
    (check (= 24 (lbs-charge st))))
  ;; HOSHA (J, §23.1, decision 21): S6, three bullets f6 / f10 / f14 (2-frame windows, each its own hit), 16 each, a short
  ;; line to 3.6 m (third playtest; 6.6 before), flinch held *LB-HOSHA-STUN* (30) then a stagger, guard 6, -8, :ranged (no chip); the leap 5 m (3 before) over
  ;; f0-14; R16 after the last window (total 32); its J / K link from f16. TAISHA (K, decision 22): S16 A2 R24, a 6 m (12 before)
  ;; line, 60 flat (no :bonus), stagger kb 1.0, through guard as the shot (chip 15 %, drain 30), the back-slide 3 m over
  ;; f0-12 then locked. The dash (Step): 12 f hitless, back in the stance at its f11, 10 flash step
  (let* ((rj (find-move :lb-k-j)) (rk (find-move :lb-k-k)) (dash (find-move :lb-k-dash)) (wj (mv-hits rj)) (wk (svref (mv-hits rk) 0)))
    (check (and (= 6 (mv-s rj)) (= 10 (mv-a rj)) (= 16 (mv-r rj)) (= 3 (length wj))
                (equal (map 'list #'hw-from wj) '(6 10 14)) (equal (map 'list #'hw-to wj) '(8 12 16))
                (every (lambda (w) (and (= 16 (hw-dmg w)) (= 6 (hw-guard w)))) wj)
                (equal (map 'list #'hw-react wj) '(:flinch :flinch :stagger))
                (equal (map 'list #'hw-stun wj) (list *lb-hosha-stun* *lb-hosha-stun* nil))
                (= -8 (mv-adv-block rj)) (~= 3.0 (mv-reach rj)) (zerop (mv-slide rj)) (= 16 (getf (mv-params rj) :link))
                (~= 5.0 *lb-hosha-leap*) (= 14 *lb-hosha-leap-f*) (eq (mv-tick rj) 'lb-hosha-tick)
                (equal (mv-on-frame rj) '((0 lb-hosha-leap) (6 lb-bullet) (10 lb-bullet) (14 lb-bullet)))
                (= 16 (mv-s rk)) (= 2 (mv-a rk)) (= 24 (mv-r rk)) (= 60 (hw-dmg wk)) (eq :stagger (hw-react wk)) (~= 1.0 (hw-kb wk))
                (~= 6.0 (mv-reach rk)) (= 30 (hw-guard wk)) (not (getf (mv-params rk) :bonus))
                (~= 3.0 (getf (mv-params rk) :slide)) (= 12 (getf (mv-params rk) :slide-f) (move-lock rk))
                (equal (mv-on-frame rk) '((0 lb-hiren-slide) (16 lb-taisha-fire)))
                (= 12 (mv-total dash)) (zerop (length (mv-hits dash))) (equal (mv-on-frame dash) '((0 lb-kamae-dash) (11 lb-kamae-back)))
                (~= 3.5 *lb-kamae-dash*) (~= 10.0 *lb-kamae-dash-fs*) (= 9 *lb-dash-iframes*))))
  ;; HOSHA's link is a combo, with the real frame numbers: a bullet landing on frame h (the first frame of its window)
  ;; stuns the victim from h on; the link starts on HOSHA's f16 (its :link) and hits on its own first hit frame later, so
  ;; h + the stun must pass f16 + J1's / K1's first hit for every bullet (the victim is free on the step his stun runs out)
  (let* ((rj (find-move :lb-k-j)) (link (getf (mv-params rj) :link)))
    (check (= link (+ (mv-s rj) (mv-a rj))))                             ; (the recovery: the bullets all fire first)
    (dolist (c '(:q :f))
      (let ((opener (mv-first-hit (kit-command-move b c))))
        (loop for w across (mv-hits rj)
              do (check (> (+ (hw-from w) (or (hw-stun w) (hitstun (hw-react w)))) (+ link opener)))))))
  ;; the link plan (his CPU, once a move): after HOSHA's hit J1 under 0.5, else K1; after TENSHIN J1 only when it switched in
  ;; and a trace hit (the combo)
  (check (and (eq :q (lb-ai-link-plan t 0.49 nil nil)) (eq :f (lb-ai-link-plan t 0.5 nil nil))
              (eq :q (lb-ai-link-plan nil 0.0 t t)) (eq :none (lb-ai-link-plan nil 0.0 t nil)) (eq :none (lb-ai-link-plan nil 0.0 nil t))))
  ;; the touch fix (decision 24): the stances whose :tick takes Step (his, Ichigo's TSUKIMACHI) carry :step-branch, and no
  ;; other move does (control.lisp UP-FLICK-HOHO-P keeps their up-flick a Step)
  (check (equal (sort (loop for m being the hash-values of *moves* when (member :step-branch (mv-flags m)) collect (mv-name m))
                      #'string<)
                '(:ic-tsuki :ic-tsuki-k2 :ic-tsuki-re :lb-kamae :lb-kamae-k :lb-kamae-re)))
  ;; every branch combos off a K link's hit: its A + 2 (the stance's f4 -> f6) + the branch's first hit (the shot's S) < the
  ;; K link's hitstun
  (dolist (kl '(:lb-k1 :lb-k2 :lb-k3))
    (let* ((m (kit-move b kl)) (st (hitstun (hw-react (svref (mv-hits m) 0)))) (kk (mv-name (kit-l-link b kl))))
      (check (and (eq kk :lb-kamae-k)
                  (< (+ (mv-a m) 2 (mv-first-hit (kit-next b kk :kamae-j))) st)
                  (< (+ (mv-a m) 2 (mv-first-hit (kit-next b kk :kamae-k))) st)
                  (< (+ (mv-a m) 2 (mv-first-hit (kit-next b kk :kamae-l))) st)))))
  ;; the eye (decisions 7, 13): a tap after U rested >= 10 f, a pip left, from a free state; a threat within 8 f; the third
  ;; opening fills the awakening gauge unless awakened; the phase makes every hit a whiff (:invuln -> NIL)
  (check (and (lb-eye-tap-p 10 3 :idle 0) (not (lb-eye-tap-p 9 3 :idle 0)) (not (lb-eye-tap-p 10 0 :guard 0))
              (lb-eye-tap-p 12 1 :guard 1) (lb-eye-tap-p 12 1 :run 5) (lb-eye-tap-p 12 1 :step 10) (not (lb-eye-tap-p 12 1 :step 5))
              (not (lb-eye-tap-p 30 3 :move 0)) (not (lb-eye-tap-p 30 3 :stun 0)) (not (lb-eye-tap-p 30 3 :guard-hit 0))))
  (check (and (lb-eye-window-p 0 8 11) (not (lb-eye-window-p 0 9 12)) (lb-eye-window-p 10 8 11) (not (lb-eye-window-p 11 8 11))
              (= *lb-eye-lead* 8) (= *lb-eye-phase* 16) (= *lb-eyes* 3)))
  (check (and (equal (multiple-value-list (lb-eye-open 3 nil)) '(2 nil)) (equal (multiple-value-list (lb-eye-open 2 nil)) '(1 nil))
              (equal (multiple-value-list (lb-eye-open 1 nil)) '(0 t)) (equal (multiple-value-list (lb-eye-open 1 t)) '(0 nil))
              (equal (multiple-value-list (lb-eye-open 0 nil)) '(0 nil))))
  ;; MUJITTAI (decisions 3-5, 14) in both modes: U enters it; a ward with :intangible; every attack drops it to its mode (no
  ;; :keep), on its frame 0; a Breaker breaks it; it never refills; Jilliel refills at 2.0 / s outside it
  (check (and (eq (kit-guard-to j) :jilliel-mujittai) (null (kit-guard-to mu)) (eq (kit-drop-to mu) :jilliel) (null (kit-keep mu))
              (equal (kit-passives mu) '(:ward :intangible)) (null (kit-passives j)) (equal (kit-u-tag mu) "U: MUJITTAI")
              (every (lambda (c) (eq :jilliel (kit-drop mu c))) '(:q :f :sig :sp1 :sp2 :breaker :kikon))
              (eq (kit-guard-to kn) :jilliel-kin-mujittai) (null (kit-guard-to kmu)) (eq (kit-drop-to kmu) :jilliel-kin)
              (null (kit-keep kmu)) (equal (kit-passives kmu) '(:ward :intangible)) (null (kit-passives kn))
              (equal (kit-u-tag kmu) "U: MUJITTAI") (equal (kit-u-tag kn) "U: MUJITTAI")
              (every (lambda (c) (eq :jilliel-kin (kit-drop kmu c))) '(:q :f :sig :sp1 :sp2 :breaker :kikon))))
  (check (and (eq (resolve-contact :guard :in-front nil :ward t) :blocked) (eq (resolve-contact :guard :breaker t :ward t) :guard-break)
              (eq (resolve-contact :guard :unguardable t :ward t) :hit) (~= *mujittai-mult* 1.0)))
  (check (and (~= (gg-regen 40.0 999 nil t nil (kit-gg-regen mu)) 40.0)                         ; in the stance: GUARD HOLD
              (~= (* 60 (- (gg-regen 40.0 999 nil nil nil (kit-gg-regen j)) 40.0)) 1.98 0.01)    ; Jilliel: 0.36 x 5.5 / s
              (~= (kit-gg-regen kn) (kit-gg-regen j)) (~= (kit-gg-regen kmu) (kit-gg-regen j))     ; both modes (§22.2)
              (~= (* 60 (- (gg-regen 40.0 999 nil nil nil (kit-gg-regen b)) 40.0)) *gg-regen* 0.01)   ; the base: universal
              (~= (kit-gg-regen o) (kit-gg-regen j)) (~= (kit-taken j) 1.1) (~= (kit-taken kn) 1.1) (= 3 (kit-kikon-konpaku j))
              (= 3 (kit-kikon-konpaku kn)) (= 2 (kit-kikon-konpaku b))
              (~= (kit-walk kn) 3.8) (~= (kit-run kn) 8.5) (~= (kit-walk j) 3.0) (kit-awakening kn)
              (eq (kit-endless-form kn) :jilliel) (eq (kit-endless-form kmu) :jilliel)))
  ;; the revival (decision 16): P from any Jilliel form, free (idle / guard: the stance too), with <= 4 Konpaku (Kenpachi's
  ;; rule); no beheading. The owl: Konpaku 4 a Kikon, x1.1 (decision 36; 1.2 before), no burn, no way back
  (check (and (lb-revive-ok-p :jilliel :idle 4) (lb-revive-ok-p :jilliel-kin :idle 4) (lb-revive-ok-p :jilliel-mujittai :guard 1)
              (lb-revive-ok-p :jilliel-kin-mujittai :guard 4) (not (lb-revive-ok-p :jilliel :idle 5))
              (not (lb-revive-ok-p :jilliel-kin :idle 5)) (not (lb-revive-ok-p :base :idle 3)) (not (lb-revive-ok-p :shin :idle 1))
              (not (lb-revive-ok-p :jilliel :move 3)) (not (lb-revive-ok-p :jilliel-kin :guard-hit 3))
              (not (lb-revive-ok-p :jilliel :stun 2)) (= *bankai-konpaku* 4)))
  (check (and (every (lambda (k) (and (eq (kit-bankai-form k) :shin) (eq (kit-bankai-ok k) 'lille-bankai-ok))) (list j mu kn kmu))
              (null (kit-bankai-form o)) (null (kit-bankai-ok o)) (null (kit-pips o)) (zerop (kit-burn o)) (null (kit-duration o))
              (= 4 (kit-kikon-konpaku o)) (~= (kit-mult o) 1.1) (kit-awakening o) (eq (kit-cine o) 'lb-revive-cine)
              (every (lambda (k) (null (kit-hook k :settled))) (list b j mu kn kmu o))))
  ;; Trompete's reflect (decision 9): a perfect Hoho started f48-f59, a guard pressed f50-f58 (its FIGHTER-GUARD-T at the end
  ;; of f59 is 60 - the press frame); he takes 50 % x1.1 = 132 (x1.2 = 144 before decision 36); 2 bars, 60 f wind-up, the
  ;; blast at f60 (:params :blast): the owl KIN's SP2 (decision 36)
  (flet ((guard-at (press) (lb-reflect-guard-p (- 60 press))))
    (check (and (not (lb-reflect-hoho-p 47)) (lb-reflect-hoho-p 48) (lb-reflect-hoho-p 59) (not (lb-reflect-hoho-p 60))
                (not (guard-at 49)) (guard-at 50) (guard-at 58) (not (guard-at 59))
                (= 132 (lb-reflect-damage 240 (kit-mult ok)))
                (let ((tr (kit-command-move ok :sp2))) (and (= 60 (mv-s tr)) (= 60 (getf (mv-params tr) :blast)) (= 2 (kit-command-cost o :sp2))
                                                           (member :reflectable (mv-flags tr)))))))
  ;; SABAKI: the ground line erupts 1 -> 18 m at 40 m/s, each point burns 24 f; MISUJI three lines, one hit group (G12)
  (check (and (equal (multiple-value-list (lb-sabaki-span 0)) '(1.0 1.0)) (~= (nth-value 1 (lb-sabaki-span 12)) 9.0)
              (~= (lb-sabaki-span 12) 1.0) (~= (lb-sabaki-span 36) 9.0) (multiple-value-bind (f2 t2) (lb-sabaki-span 90) (~= f2 t2))
              (= 50 (lb-sabaki-frames)) (= 3 (length (getf (mv-params (kit-command-move ok :sp1)) :fan)))
              (null (gethash :lb-sabaki *moves*))))                    ; (the owl's L is TENSHIN: decision 36)
  ;; the forms' commands and Kikon modules
  (check (and (null (kit-l-after-k j)) (null (kit-l-after-k o)) (eq (kit-l-after-k kn) t)
              (eq (kit-awaken-form b) :jilliel) (equal (getf (getf (kit-ai j) :bankai) :own-konpaku) 1)
              (equal (getf (getf (kit-ai kn) :bankai) :own-konpaku) 1)
              (every (lambda (k) (eq :kikon (mv-kind (kit-command-move k :kikon)))) (list b j kn o)))))

;;; ---------------------------------------------------------------- JILLIEL EN / KIN and TENSHIN (DUEL_LILLE §22.2, decision 18)
(let* ((j (kit :lille :jilliel)) (kn (kit :lille :jilliel-kin)) (sw (find-move :lb-switch)))
  ;; L is TENSHIN in both modes: 14 f hitless dash (round 2: in up to 8 m stopping 1.5 m short, out 7 m), R 8, no cooldown
  ;; (decision 34; 30 before), frame 0 materialises, the form at f6; J / K cancel it from f14 (its :link); KIN -> EN 10
  ;; flash step (refused at 9.9), EN -> KIN free (allowed at 0; decision 34);
  ;; EN -> KIN, KIN -> EN; KIN's K links chain into it (a K link's L), EN's lines cancel into it from their active end (the
  ;; tick): no L link there
  (check (and (eq sw (kit-command-move kn :sig)) (= 14 (mv-s sw) *lb-switch-f*) (zerop (mv-a sw)) (= 8 (mv-r sw))
              (= 14 (getf (mv-params sw) :link)) (eq (mv-tick sw) 'lb-link-tick)
              (~= 6.5 (lb-switch-dist t 8.0)) (~= 8.0 (lb-switch-dist t 12.0)) (~= 0.0 (lb-switch-dist t 1.2))
              (~= 7.0 (lb-switch-dist nil 3.0)) (~= 7.0 (lb-switch-dist nil 20.0))
              (zerop (length (mv-hits sw))) (zerop (mv-cooldown sw)) (not (boundp '*lb-switch-cd*))
              (equal (mv-on-frame sw) '((0 lb-switch-go) (6 lb-switch-form)))
              (eq (lb-switch-target :jilliel) :jilliel-kin) (eq (lb-switch-target :jilliel-mujittai) :jilliel-kin)
              (eq (lb-switch-target :jilliel-kin) :jilliel) (eq (lb-switch-target :jilliel-kin-mujittai) :jilliel)
              (= 10 *lb-switch-fs*) (~= 10.0 (lb-switch-price :jilliel-kin)) (~= 10.0 (lb-switch-price :jilliel-kin-mujittai))
              (zerop (lb-switch-price :jilliel)) (zerop (lb-switch-price :jilliel-mujittai))
              (not (lb-switch-ok-p :jilliel-kin 9.9)) (not (lb-switch-ok-p :jilliel-kin 9.0)) (lb-switch-ok-p :jilliel-kin 10.0)
              (not (lb-switch-ok-p :jilliel-kin-mujittai 9.0))
              (lb-switch-ok-p :jilliel 0.0) (lb-switch-ok-p :jilliel-mujittai 0.0) (lb-switch-ok-p :jilliel 9.0)
              (eq sw (kit-l-link kn :lb-w-k1)) (eq sw (kit-l-link kn :lb-w-k3)) (null (kit-l-link kn :lb-w-j1))
              (null (kit-l-link j :lb-e-k1))
              (lb-jilliel-form-p :jilliel-kin-mujittai) (not (lb-jilliel-form-p :shin)) (lb-kin-form-p :jilliel-kin)
              (not (lb-kin-form-p :jilliel))))
  ;; TENSHIN in (EN -> KIN, decisions 30, 34): EN's L from neutral (idle / walk / run; MUJITTAI drops to EN and takes it)
  ;; is :lb-switch-in, a 16 f wind-up (8 before decision 34; hittable: no iframes before the dash) then the dash at f16
  ;; (traces materialise, iframes from there), the form 6 f into the dash, its link at the dash's end; as a cancel out of
  ;; an EN attack the same move entered at f14 (:lb-switch-in-c): 2 f. Both paths: a trace hit at the materialise -> the
  ;; dash -> KIN's J1 at the link is a combo (the stun counts from the materialise, so the longer wind-up changes nothing)
  (let ((in (kit-command-move j :sig)) (inc (find-move :lb-switch-in-c)) (kj1 (kit-command-move kn :q)))
    (check (and (eq :lb-switch-in (mv-name in)) (eq in (kit-command-move (kit :lille :jilliel-mujittai) :sig))
                (equal (mv-on-frame in) '((16 lb-switch-go) (22 lb-switch-form))) (equal (mv-on-frame inc) (mv-on-frame in))
                (= 30 (mv-s in) (getf (mv-params in) :link)) (= 16 (getf (mv-params in) :go)) (zerop (mv-cooldown inc))
                (zerop (mv-cooldown in))
                (= 14 (mv-enter inc)) (zerop (mv-enter in)) (eq (mv-tick in) 'lb-link-tick) (zerop (length (mv-hits in)))
                (= *lb-switch-windup* (- 16 (mv-enter in))) (= *lb-switch-windup-c* (- 16 (mv-enter inc)))
                (= 16 *lb-switch-windup*) (= 2 *lb-switch-windup-c*)
                (= (getf (mv-params in) :go) *lb-switch-windup*) (= (mv-s in) (+ *lb-switch-windup* *lb-switch-f*))
                (= (- (getf (mv-params in) :link) 16) *lb-switch-f*)))
    ;; the order (the user, 2026-10-06): wind-up -> the traces materialise (LB-SWITCH-GO's first act, the wind-up's end)
    ;; -> the dash -> J / K: on both paths the materialise is at the end of that path's wind-up (16 f from neutral, 2 f
    ;; from the cancel's f14 entry), the link at the dash's end, and the trace's stun (counted from the materialise)
    ;; outlasts the dash + KIN's J1 first hit
    (loop for m in (list in inc) for windup in (list *lb-switch-windup* *lb-switch-windup-c*)
          do (let ((go (getf (mv-params m) :go)) (link (getf (mv-params m) :link)))
               (check (and (= go (first (first (mv-on-frame m)))) (eq 'lb-switch-go (second (first (mv-on-frame m))))
                           (= windup (- go (mv-enter m))) (= link (+ go *lb-switch-f*))
                           (> *lb-trace-stun* (+ (- link go) (mv-first-hit kj1))))))))
  ;; EN's J / K (round 2, decision 28: the start-ups and recoveries cut, the active frames kept): the strings as KIN's (the
  ;; same links), S / A / R J 4/3/6 4/3/6 5/3/9, K 9/4/10 10/4/12 (enter 3) 11/5/17 (enter 4); no hit window, a trace laid
  ;; on the first active frame, the stick walking him (LB-EN-TICK); the wing clips at :clip-s / S speed (the hit pose on S)
  (check (equal (mapcar #'second (link-moves j)) (mapcar #'second (link-moves kn))))
  (loop for (em nil seq) in (link-moves j)
        for km = (first (find seq (link-moves kn) :key #'third :test #'equal))
        for want = (cdr (assoc (mv-name em) '((:lb-e-j1 4 3 6 0) (:lb-e-j2 4 3 6 0) (:lb-e-j2s 4 3 6 0) (:lb-e-j3 5 3 9 0)
                                              (:lb-e-k1 9 4 10 0) (:lb-e-k2 10 4 12 3) (:lb-e-k2s 10 4 12 3) (:lb-e-k3 11 5 17 4))))
        do (check (and km want (equal (list (mv-s em) (mv-a em) (mv-r em) (mv-enter em)) want)
                       (eq (mv-kind em) (mv-kind km)) (zerop (length (mv-hits em))) (eq (mv-tick em) 'lb-en-tick)
                       (eq (mv-clip em) (mv-clip km)) (~= (mv-clip-speed em) (/ (mv-s km) (float (mv-s em))))
                       (equal (mv-on-frame em) (list (list (mv-s em) 'lb-en-lay)))
                       (< (mv-enter em) (mv-s em))
                       (member (getf (mv-params em) :trace) '(:j :k))
                       (eq (and (member :ender (mv-flags em)) t) (and (member :ender (mv-flags km)) t))
                       (= (move-end-frame (mv-s em) (mv-a em) (mv-r em) (mv-whiff em) nil t) (mv-total em)))))   ; (hitless: R)
  ;; the string goes on without contact: a laid line sets FIGHTER-CHAINED (LB-EN-LAY), which opens the next link in the
  ;; last *CHAIN-LEAD* frames of the recovery (CHAIN-OPEN-P with contact T): every EN link has room for it
  (loop for (em) in (link-moves j)
        do (check (and (chain-open-p (- (mv-total em) 1) (mv-s em) (mv-a em) (mv-r em) t)
                       (not (chain-open-p (- (mv-total em) *chain-lead* 1) (mv-s em) (mv-a em) (mv-r em) t))
                       (> (mv-r em) *chain-lead*))))
  (let ((s1 (kit-command-move j :sp1)) (s2 (kit-command-move j :sp2)))
    (check (and (eq :lb-e-sanren (mv-name s1)) (equal (mapcar #'first (mv-on-frame s1)) '(6 12 18)) (eq :sp1 (getf (mv-params s1) :trace))
                (= 6 (mv-s s1)) (= 14 (mv-a s1)) (= 12 (mv-r s1)) (= 6 (mv-a s2)) (= 15 (mv-r s2)) (= 10 (move-lock s2))
                (equal (mapcar #'first (mv-on-frame s2)) '(0 20)) (~= 2.0 (mv-clip-speed s2))
                (zerop (length (mv-hits s1))) (eq (mv-tick s1) 'lb-en-tick)
                (eq :lb-e-nijushi (mv-name s2)) (= 20 (mv-s s2)) (eq :sp2 (getf (mv-params s2) :trace)) (zerop (length (mv-hits s2)))
                (eq (mv-tick s2) 'lb-nijushi-tick) (= 2 (kit-command-cost j :sp2))
                (eq :lb-sanren (mv-name (kit-command-move kn :sp1))) (eq :lb-nijushi (mv-name (kit-command-move kn :sp2)))
                (plusp (length (mv-hits (kit-command-move kn :sp2)))) (eq :lb-w-j1 (mv-name (kit-command-move kn :q)))
                (~= 3.0 *lb-en-walk*))))
  ;; the traces: J one line, K a fan of three (-6 0 +6), SP1 one a shot; at most 16 live, a 17th drops the oldest (FIFO; decision 29, 8 before)
  (check (and (equal (lb-trace-fans :j) '(0.0)) (equal (lb-trace-fans :sp1) '(0.0)) (= 3 (length (lb-trace-fans :k)))
              (~= 6.0 (third (lb-trace-fans :k))) (~= -6.0 (first (lb-trace-fans :k)))
              (= 16 *lb-trace-max*) (not (lb-trace-drop-p 15)) (lb-trace-drop-p 16) (= 3 (lb-trace-oldest '(5 3 9))) (null (lb-trace-oldest nil))))
  (let ((ids nil) (dropped nil))
    (loop for id from 1 to 19 do (multiple-value-bind (l d) (lb-trace-lay ids id) (setf ids l) (when d (push d dropped))))
    (check (and (equal ids (loop for i from 4 to 19 collect i)) (equal (reverse dropped) '(1 2 3)))))   ; (16 live: decision 29)
  ;; materialising: each trace once, a 2-frame hit (the shell: life = age + 3), :ranged :x-axis :uncatchable; J 30, K 24,
  ;; SP1 30, SP2 180 x his damage; blocked: chip 15 %, drain 18 a line (45 SP2); kept until his switch
  (let ((d (make-lbh :kind :trace :src :k :live t)))
    (let ((hw (lb-trace-materialise! d 1.0)))
      (check (and hw (= 24 (hw-dmg hw)) (not (lbh-live d)) (null (lb-trace-materialise! d 1.0))))))
  (check (and (= 30 (hw-dmg (lb-trace-hitwin :j 1.0))) (= 24 (hw-dmg (lb-trace-hitwin :k 1.0))) (= 30 (hw-dmg (lb-trace-hitwin :sp1 1.0)))
              (= 180 (hw-dmg (lb-trace-hitwin :sp2 1.0))) (= 33 (hw-dmg (lb-trace-hitwin :j 1.1)))
              (every (lambda (k) (let ((w (lb-trace-hitwin k 1.0)))
                                   (and (subsetp '(:ranged :x-axis :uncatchable) (hw-flags w)) (~= 0.15 (hw-chip w))
                                        (= (hw-guard w) (if (eq k :sp2) 45 18))
                                        (notany (lambda (fl) (member fl (hw-flags w))) '(:unguardable :breaker :guard-crush)))))
                     '(:j :k :sp1 :sp2))
              (eq :knockback (hw-react (lb-trace-hitwin :sp2 1.0))) (eq :stagger (hw-react (lb-trace-hitwin :k 1.0)))
              ;; round 2 (decision 25): a trace staggers in place (no knockback) *LB-TRACE-STUN* frames, >= TENSHIN's dash + a
              ;; J1's first hit + 4, in either form after the switch: a trace hit -> TENSHIN in -> J1 is a combo; SP2's knocks back
              (every (lambda (k) (let ((w (lb-trace-hitwin k 1.0))) (and (zerop (hw-kb w)) (= 26 (hw-stun w) *lb-trace-stun*))))
                     '(:j :k :sp1))
              (~= 2.0 (hw-kb (lb-trace-hitwin :sp2 1.0))) (null (hw-stun (lb-trace-hitwin :sp2 1.0)))
              (every (lambda (kit) (>= *lb-trace-stun* (+ (mv-s (find-move :lb-switch)) (mv-first-hit (kit-command-move kit :q)) 4)))
                     (list j kn))
              (~= (gg-drain *gg-max* (hw-guard (lb-trace-hitwin :k 1.0))) (- *gg-max* 18))   ; blocked = a drain
              (> *lb-trace-life* (* 60 60 10)) (~= *lb-trace-r* 0.6) (~= *lb-trace-r-thick* 1.2)))
  ;; the flash-step economy (decision 34): an EN J / K line costs 3 (J 3, a K fan 9), laid only while 3 are left, line by
  ;; line (a short K fan lays its middle line first); SP1 / SP2 free; a materialised trace's hit gives 2 back, a guarded
  ;; one nothing (a K fan is one hit group: asked once)
  (check (and (~= 3.0 *lb-trace-fs*) (~= 3.0 (lb-trace-cost :j)) (~= 3.0 (lb-trace-cost :k))
              (zerop (lb-trace-cost :sp1)) (zerop (lb-trace-cost :sp2))
              (multiple-value-bind (n left) (lb-trace-pay 3.0 :j 1) (and (= n 1) (~= left 0.0)))
              (multiple-value-bind (n left) (lb-trace-pay 2.9 :j 1) (and (= n 0) (~= left 2.9)))
              (multiple-value-bind (n left) (lb-trace-pay 9.0 :k 3) (and (= n 3) (~= left 0.0)))
              (multiple-value-bind (n left) (lb-trace-pay 8.0 :k 3) (and (= n 2) (~= left 2.0)))
              (multiple-value-bind (n left) (lb-trace-pay 5.0 :k 3) (and (= n 1) (~= left 2.0)))
              (multiple-value-bind (n left) (lb-trace-pay 2.0 :k 3) (and (= n 0) (~= left 2.0)))
              (multiple-value-bind (n left) (lb-trace-pay 100.0 :k 3) (and (= n 3) (~= left 91.0)))
              (multiple-value-bind (n left) (lb-trace-pay 0.0 :sp1 1) (and (= n 1) (~= left 0.0)))
              (multiple-value-bind (n left) (lb-trace-pay 0.0 :sp2 1) (and (= n 1) (~= left 0.0)))
              (equal (lb-trace-pick (lb-trace-fans :k) 3) (lb-trace-fans :k))
              (equal (lb-trace-pick (lb-trace-fans :k) 2) (list (- *lb-trace-fan*) 0.0))
              (equal (lb-trace-pick (lb-trace-fans :k) 1) '(0.0)) (null (lb-trace-pick (lb-trace-fans :k) 0))
              (equal (lb-trace-pick (lb-trace-fans :j) 1) '(0.0)) (null (lb-trace-pick (lb-trace-fans :j) 0))
              (lb-en-dry-p 2.9) (not (lb-en-dry-p 3.0)) (not (fboundp 'lb-nick-hitwin)) (~= 4.0 *lb-trace-refund*) (~= 4.0 (lb-trace-refund :hit)) (~= 2.0 (lb-trace-refund :block)) (~= 2.0 *lb-trace-refund-block*)
              (zerop (lb-trace-refund nil))))
  ;; a K fan is one hit group (LB-EN-LAY's MAKE-HIT-GROUP 1 when the fan has more than one line): its refund once
  (check (and (rest (lb-trace-fans :k)) (null (rest (lb-trace-fans :j))) (null (rest (lb-trace-fans :sp1))))))

;; decision 41 (the user 2026-10-07): no laying shot; a trace materialising turns toward him by at most 10 degrees; his
;; crossing onto a live trace slows the match (0.35 for 0.3 s, re-armed after 30 steps)
(check (and (~= 10.0 *lb-snap-max*) (~= 0.35 *lb-cross-scale*) (~= 0.3 *lb-cross-secs*) (= 30 *lb-cross-rearm*)
            ;; facing -z (yaw 0): him 10 m ahead, 1 m to the side (5.7 deg) -> the line turns onto him; 3 m to the side
            ;; (16.7 deg) -> 10 deg only; behind his back -> 10 deg; on the pivot -> unchanged
            (let ((y (lb-snap-yaw 0.0 0.0 0.0 1.0 -10.0))) (~= y (dir-yaw 1.0 -10.0)))
            (let ((y (lb-snap-yaw 0.0 0.0 0.0 3.0 -10.0))) (~= (abs y) (deg 10.0)))
            (let ((y (lb-snap-yaw 0.0 0.0 0.0 0.5 10.0))) (~= (abs y) (deg 10.0)))
            (~= 0.3 (lb-snap-yaw 0.3 2.0 2.0 2.0 2.0))
            ;; snapped, a line 1 m off at 10 m passes through him
            (< (line-dist 0.0 0.0 (lb-snap-yaw 0.0 0.0 0.0 1.0 -10.0) 0.6 *lb-trace-len* 1.0 -10.0) 0.01)
            (lb-cross-p nil t -1 5) (not (lb-cross-p t t -1 5)) (not (lb-cross-p nil nil -1 5))
            (not (lb-cross-p nil t 100 129)) (lb-cross-p nil t 100 130)))

;;; ---------------------------------------------------------------- Lille's own CPU (DUEL_LILLE §11.2, §22; batch 3a, rework R)
;; frozen (the shared hooks and what a CPU facing him reads; DUEL_LILLE §24.2): one :reflex, LB-AI-REFLEX, on every form;
;; the traces' key for a CPU facing EN (:opp-reflex LB-OPP-TRACE, :opp-trace :p 0.5), none on KIN or the base form; no aim
;; keys (:opp-aim)
(let ((forms (mapcar (lambda (f) (kit :lille f)) '(:base :jilliel :jilliel-mujittai :jilliel-kin :jilliel-kin-mujittai
                                                   :shin :shin-mujittai :shin-kin :shin-kin-mujittai))))
  (check (and (every (lambda (k) (eq (getf (kit-ai k) :reflex) 'lb-ai-reflex)) forms)
              (every (lambda (k) (null (getf (kit-ai k) :opp-aim))) forms)
              (eq (getf (kit-ai (kit :lille :jilliel)) :opp-reflex) 'lb-opp-trace)
              (eq (getf (kit-ai (kit :lille :jilliel-mujittai)) :opp-reflex) 'lb-opp-trace)
              (~= 0.5 (getf (getf (kit-ai (kit :lille :jilliel)) :opp-trace) :p))
              (null (getf (kit-ai (kit :lille :jilliel-kin)) :opp-reflex)) (null (getf (kit-ai (kit :lille :base)) :opp-reflex)))))

;;; >>> BEGIN LILLE-CPU-TESTS: the checks of his own CPU's shipped values and pure LB-AI-* functions. A dream-rsi cell
;;; (docs/research/lille-ai-drsi, DUEL_LILLE §24.2) may deliver this file and rescore.sh splices ONLY the lines between
;;; these two markers into the frozen test: they must still pin the cell's own shipped values; everything outside them
;;; (shared behaviour, rules, hooks, the other characters) stays frozen.
(let ((b (kit :lille :base)) (j (kit :lille :jilliel)) (mu (kit :lille :jilliel-mujittai)) (o (kit :lille :shin-kin))
      (kn (kit :lille :jilliel-kin)) (kmu (kit :lille :jilliel-kin-mujittai)))
  ;; every chance x difficulty, EASY <= NORMAL <= HARD, at most 1: the eye 0.25 / 0.5 / 0.75
  (check (and (~= (lb-ai-chance 0.5 :easy) 0.25) (~= (lb-ai-chance 0.5 :normal) 0.5) (~= (lb-ai-chance 0.5 :hard) 0.75)
              (~= (lb-ai-chance 0.8 :hard) 1.0)
              (every (lambda (p) (<= (lb-ai-chance p :easy) (lb-ai-chance p :normal) (lb-ai-chance p :hard))) '(0.0 0.3 0.6 0.9))))
  ;; the kits' keys: the eye (base), the stance (Jilliel's four), the switch (EN in, KIN out), Trompete (the owl); one
  ;; :reflex; the traces' key for a CPU facing EN (:opp-reflex LB-OPP-TRACE, :opp-trace); no aim keys left (the hook and
  ;; the opponents' keys are pinned again, frozen, above the markers)
  (check (and (every (lambda (k) (eq (getf (kit-ai k) :reflex) 'lb-ai-reflex)) (list b j mu kn kmu o))
              (~= (getf (getf (kit-ai b) :eye) :p) 0.5) (equal (getf (kit-ai j) :stance) '(:p 0.6 :max 180 :gg 30))
              (equal (getf (kit-ai mu) :stance) (getf (kit-ai j) :stance)) (equal (getf (kit-ai kmu) :stance) (getf (kit-ai j) :stance))
              (getf (kit-ai o) :trompete) (null (getf (kit-ai b) :stance)) (null (getf (kit-ai j) :eye))
              (equal (getf (kit-ai j) :switch) '(:traces 3 :near 0.6 :whiff 1.5)) (equal (getf (kit-ai kn) :switch) '(:gg 40))
              (eq (getf (kit-ai j) :opp-reflex) 'lb-opp-trace) (eq (getf (kit-ai mu) :opp-reflex) 'lb-opp-trace)
              (~= 0.5 (getf (getf (kit-ai j) :opp-trace) :p)) (null (getf (kit-ai kn) :opp-reflex)) (null (getf (kit-ai b) :opp-reflex))
              (every (lambda (k) (not (or (getf (kit-ai k) :sig-hold) (getf (kit-ai k) :opp-aim)))) (list b j mu kn kmu o))
              (every (lambda (band) (member :sig band)) (getf (kit-ai b) :moves))))   ; (the stance in every band)
  ;; the eye's plan: a pip, the threat not on him yet, U rested *LB-EYE-REST* by the tap (let go until lead 4)
  (check (and (lb-ai-eye-ready-p 4 10 1) (not (lb-ai-eye-ready-p 4 9 1)) (lb-ai-eye-ready-p 14 0 1) (not (lb-ai-eye-ready-p 13 0 1))
              (not (lb-ai-eye-ready-p 20 30 0)) (not (lb-ai-eye-ready-p 0 30 3)) (lb-ai-eye-ready-p 1 30 3)))
  (check (and (lb-ai-eye-tap-p 1) (lb-ai-eye-tap-p 4) (not (lb-ai-eye-tap-p 5)) (not (lb-ai-eye-tap-p 0))
              (<= *lb-ai-eye-tap* *lb-eye-lead*)))
  ;; one roll R per window: the eye under P (ready), else a Step off a lane / from a Breaker, else a guard by the gauge
  (check (and (eq :eye (lb-ai-eye-plan 0.1 0.5 t nil 1.0)) (eq :guard (lb-ai-eye-plan 0.1 0.5 nil nil 1.0))
              (eq :guard (lb-ai-eye-plan 0.7 0.5 t nil 1.0)) (eq :step (lb-ai-eye-plan 0.7 0.5 t t 1.0))
              (eq :eye (lb-ai-eye-plan 0.1 0.5 t t 1.0)) (eq :step (lb-ai-eye-plan 0.9 0.5 t nil 0.5))
              (eq :guard (lb-ai-eye-plan 0.6 0.5 t nil 0.5)) (eq :step (lb-ai-eye-plan 0.3 0.5 nil nil 0.0))
              (eq :guard (lb-ai-eye-plan 0.99 1.0 nil nil 1.0))))
  (check (and (eq :stance (lb-ai-stance-plan 0.5 0.6 nil)) (eq :step (lb-ai-stance-plan 0.7 0.6 t))
              (eq :pass (lb-ai-stance-plan 0.7 0.6 nil))))
  ;; the stance is left by attacking: his whiff first, then :max, the gauge, him idle out of reach; else stay
  (check (and (eq :whiff (lb-stance-exit t 0 180 100.0 30 t)) (eq :max (lb-stance-exit nil 180 180 100.0 30 t))
              (null (lb-stance-exit nil 179 180 30.0 30 nil)) (eq :gauge (lb-stance-exit nil 0 180 29.0 30 nil))
              (eq :idle (lb-stance-exit nil 0 180 100.0 30 t))))
  ;; the shooting stance's branch (one roll at its f6, §22.1, §23.1): after a K link's hit L 0.6 / J (HOSHA) 0.4; from 8 m
  ;; the charged shot; 6-8 m the quick shot on a whiff, else the dash back (then charged), else charged; 3-6 m K (TAISHA) on
  ;; a guard, the quick shot on a whiff, else J (HOSHA); within 3 m K (TAISHA: room)
  (check (and (eq :l (lb-ai-kamae-plan 0.59 2.0 t nil nil nil t)) (eq :j (lb-ai-kamae-plan 0.6 2.0 t nil nil nil t))
              (eq :charge (lb-ai-kamae-plan 0.1 8.0 nil nil nil nil t)) (eq :charge (lb-ai-kamae-plan 0.9 20.0 nil t t t t))
              (eq :l (lb-ai-kamae-plan 0.5 7.0 nil nil nil t t)) (eq :dash (lb-ai-kamae-plan 0.5 7.0 nil nil nil nil t))
              (eq :charge (lb-ai-kamae-plan 0.5 7.0 nil nil nil nil nil))
              (eq :j (lb-ai-kamae-plan 0.5 5.0 nil nil nil nil t)) (eq :j (lb-ai-kamae-plan 0.5 6.0 nil nil t nil t))
              (eq :l (lb-ai-kamae-plan 0.5 4.0 nil t nil nil t)) (eq :l (lb-ai-kamae-plan 0.5 4.0 nil nil nil t t))
              (eq :k (lb-ai-kamae-plan 0.5 2.0 nil nil nil nil t)) (eq :k (lb-ai-kamae-plan 0.5 3.0 nil nil nil t t))))
  ;; EN's switch in (§22.2): >= 3 live traces and him on one (0.6 m), or him reeling / recovering within 1.5 m of one
  (let ((k (getf (kit-ai j) :switch)))
    (check (and (lb-switch-in-rule 3 0.6 nil k) (not (lb-switch-in-rule 2 0.0 nil k)) (not (lb-switch-in-rule 3 0.7 nil k))
                (lb-switch-in-rule 1 1.5 t k) (not (lb-switch-in-rule 1 1.6 t k)) (not (lb-switch-in-rule 0 0.0 t k))
                (lb-switch-in-rule 8 0.0 t k)
                ;; decision 30: from neutral (a 16 f wind-up since decision 34) not onto a running / stepping opponent
                ;; unless he is busy
                (not (lb-switch-in-rule 3 0.6 nil k t)) (lb-switch-in-rule 3 0.6 t k t)
                ;; decision 34: starved of flash step (no J line above the reserve) he switches in (free) with no
                ;; trace, unless the opponent is moving
                (lb-switch-in-rule 0 99.0 nil k nil t) (not (lb-switch-in-rule 0 99.0 nil k t t))
                (not (lb-switch-in-rule 0 99.0 nil k nil nil))))
    ;; the flash-step budget (decision 34): a J / K starts (its next link latched) only while its lines leave the reserve
    ;; (10 = KIN -> EN's price); KIN switches out only with the price + the reserve + a K fan (29: EN never starved)
    (check (and (~= 10.0 *lb-ai-fs-reserve*) (lb-ai-lay-ok-p 13.0 :j) (not (lb-ai-lay-ok-p 12.9 :j))
                (lb-ai-lay-ok-p 19.0 :k) (not (lb-ai-lay-ok-p 18.9 :k)) (lb-ai-lay-ok-p 100.0 :k)
                (lb-ai-out-ok-p 29.0) (not (lb-ai-out-ok-p 28.9))
                (>= (- 29.0 *lb-switch-fs*) (+ *lb-ai-fs-reserve* (* 3 *lb-trace-fs*))))))
  ;; the 16 f wind-up (decision 34) through the AI: a J1 then its 2 f cancel reaches the materialise sooner than the
  ;; neutral wind-up (LB-AI-EN prefers it)
  (let ((j1 (kit-command-move j :q)))
    (check (< (+ (mv-s j1) (mv-a j1) *lb-switch-windup-c*) *lb-switch-windup*))))
;; the owl's own CPU values (Jilliel's EN / KIN tables, Trompete's punish on KIN)
(let ((j (kit :lille :jilliel)) (o (kit :lille :shin)) (ok (kit :lille :shin-kin)))
  (check (and (equal (getf (kit-ai o) :switch) '(:traces 3 :near 0.6 :whiff 1.5)) (equal (getf (kit-ai ok) :switch) '(:gg 40))
              (getf (kit-ai ok) :trompete) (equal (getf (kit-ai o) :stance) (getf (kit-ai j) :stance)))))
;;; <<< END LILLE-CPU-TESTS


;;; ---------------------------------------------------------------- the owl on Jilliel's system (DUEL_LILLE §23.14, decision 36)
(let* ((j (kit :lille :jilliel)) (mu (kit :lille :jilliel-mujittai)) (kn (kit :lille :jilliel-kin)) (kmu (kit :lille :jilliel-kin-mujittai))
       (o (kit :lille :shin)) (omu (kit :lille :shin-mujittai)) (ok (kit :lille :shin-kin)) (okmu (kit :lille :shin-kin-mujittai))
       (owls (list o omu ok okmu)))
  ;; four forms: EN :shin (the revival's), KIN :shin-kin, U MUJITTAI in both (「也是無實體」); the owl's body in all four,
  ;; EN floating (lift *LB-OWL-LIFT* 0.35, its legs tucked: decision 38), KIN on its legs (lift 0); x1.1 dealt (1.2 before),
  ;; x1.1 taken (Jilliel's), Jilliel's guard refill; Kikon 4; no revival from any
  (check (and (~= *lb-owl-lift* 0.35) (~= (kit-lift o) *lb-owl-lift*) (~= (kit-lift omu) *lb-owl-lift*)
              (zerop (kit-lift ok)) (zerop (kit-lift okmu))))
  (check (and (every (lambda (k) (and (eq (kit-body k) :lille-shin) (kit-awakening k)
                                      (~= (kit-mult k) 1.1) (~= (kit-taken k) 1.1) (= 4 (kit-kikon-konpaku k))
                                      (~= (kit-gg-regen k) (kit-gg-regen j)) (null (kit-bankai-form k)) (null (kit-bankai-ok k))
                                      (null (getf (kit-ai k) :bankai)) (eq (kit-endless-form k) :jilliel) (null (kit-weapon k))
                                      (equal (kit-u-tag k) "U: MUJITTAI") (eq (kit-hook k :ok) 'lille-ok)))
                     owls)
              (~= *shin-mult* 1.1) (~= *shin-taken* 1.1) (= 1 *shin-adv*)
              (equal (kit-form-name o) "SHIN") (equal (kit-form-name ok) "SHIN KIN")
              (eq (kit-guard-to o) :shin-mujittai) (eq (kit-guard-to ok) :shin-kin-mujittai)
              (null (kit-guard-to omu)) (null (kit-guard-to okmu)) (eq (kit-drop-to omu) :shin) (eq (kit-drop-to okmu) :shin-kin)
              (every (lambda (c) (and (eq :shin (kit-drop omu c)) (eq :shin-kin (kit-drop okmu c)))) '(:q :f :sig :sp1 :sp2 :breaker :kikon))
              (equal (kit-passives omu) '(:ward :intangible)) (equal (kit-passives okmu) '(:ward :intangible))
              (null (kit-passives o)) (null (kit-passives ok))
              (~= (kit-walk o) (kit-walk j)) (~= (kit-run o) (kit-run j)) (~= (kit-walk ok) (kit-walk kn)) (~= (kit-run ok) (kit-run kn))
              (null (kit-l-after-k o)) (eq (kit-l-after-k ok) t)
              (eq (kit-stance o) :lb-oe-stance) (eq (kit-stance ok) :lb-o-stance) (eq (kit-stance omu) :lb-oe-fold)
              (eq (kit-stance okmu) :lb-o-fold)))
  ;; the revival enters :shin (every Jilliel form's :bankai-form) and is never offered from the owl's four
  (check (and (every (lambda (k) (eq (kit-bankai-form k) :shin)) (list j mu kn kmu))
              (notany (lambda (f) (lb-revive-ok-p f :idle 1)) '(:shin :shin-mujittai :shin-kin :shin-kin-mujittai))
              (lb-revive-ok-p :jilliel :idle 1)))
  ;; the predicates: the owl's EN / KIN pairs run Jilliel's system; the revival's Jilliel test stays Jilliel's four
  (check (and (every #'lb-owl-form-p '(:shin :shin-mujittai :shin-kin :shin-kin-mujittai)) (not (lb-owl-form-p :jilliel))
              (notany #'lb-jilliel-form-p '(:shin :shin-mujittai :shin-kin :shin-kin-mujittai))
              (every #'lb-mode-form-p '(:jilliel :jilliel-kin-mujittai :shin :shin-kin-mujittai)) (not (lb-mode-form-p :base))
              (every #'lb-en-form-p '(:jilliel :jilliel-mujittai :shin :shin-mujittai)) (notany #'lb-en-form-p '(:shin-kin :jilliel-kin :base))
              (every #'lb-kin-form-p '(:shin-kin :shin-kin-mujittai)) (notany #'lb-kin-form-p '(:shin :shin-mujittai))
              (every #'lb-stance-form-p '(:jilliel-mujittai :jilliel-kin-mujittai :shin-mujittai :shin-kin-mujittai))
              (notany #'lb-stance-form-p '(:shin :shin-kin :jilliel))))
  ;; TENSHIN: EN <-> KIN within the owl's pair; EN -> KIN free, KIN -> EN 10 (refused at 9.9); the owl's three moves are
  ;; Jilliel's (frames, frame hooks, link, wind-ups) on the owl's clips; KIN's K links chain into it
  (check (and (eq (lb-switch-target :shin) :shin-kin) (eq (lb-switch-target :shin-mujittai) :shin-kin)
              (eq (lb-switch-target :shin-kin) :shin) (eq (lb-switch-target :shin-kin-mujittai) :shin)
              (zerop (lb-switch-price :shin)) (zerop (lb-switch-price :shin-mujittai)) (~= 10.0 (lb-switch-price :shin-kin))
              (~= 10.0 (lb-switch-price :shin-kin-mujittai)) (lb-switch-ok-p :shin 0.0) (not (lb-switch-ok-p :shin-kin 9.9))
              (lb-switch-ok-p :shin-kin 10.0)
              (eq :lb-o-switch-in (mv-name (kit-command-move o :sig))) (eq :lb-o-switch-in (mv-name (kit-command-move omu :sig)))
              (eq :lb-o-switch (mv-name (kit-command-move ok :sig))) (eq :lb-o-switch (mv-name (kit-command-move okmu :sig)))
              (eq (kit-l-link ok :lb-o-k1) (kit-command-move ok :sig)) (null (kit-l-link ok :lb-o-j1)) (null (kit-l-link o :lb-oe-k1))
              (loop for (om jm clip) in '((:lb-o-switch :lb-switch :lb-o-tenshin) (:lb-o-switch-in :lb-switch-in :lb-o-tenshin-in)
                                          (:lb-o-switch-in-c :lb-switch-in-c :lb-o-tenshin-in))
                    always (let ((a (find-move om)) (b (find-move jm)))
                             (and (eq (mv-clip a) clip) (= (mv-s a) (mv-s b)) (= (mv-a a) (mv-a b)) (= (mv-r a) (mv-r b))
                                  (= (mv-enter a) (mv-enter b)) (equal (mv-on-frame a) (mv-on-frame b))
                                  (equal (mv-params a) (mv-params b)) (eq (mv-tick a) (mv-tick b)) (zerop (mv-cooldown a))
                                  (zerop (length (mv-hits a))))))))
  ;; +1 on every attack (decision 36, 「小」): each owl J / K / SP is Jilliel's with its recovery 1 f shorter (EN's: decision
  ;; 28's frames; KIN's: the owl's claws, the wing strings' frames) and, where it hits, its :adv-block 1 higher
  (flet ((pairs (a b) (loop for (m nil seq) in (link-moves a)
                            collect (list m (first (find seq (link-moves b) :key #'third :test #'equal))))))
    (check (equal (mapcar #'third (link-moves o)) (mapcar #'third (link-moves j))))
    (check (equal (mapcar #'third (link-moves ok)) (mapcar #'third (link-moves kn))))
    ;; (EN's SP2 Trompete is its own since decision 38: below)
    (loop for (om jm) in (append (pairs o j) (list (list (kit-command-move o :sp1) (kit-command-move j :sp1))))
          do (check (and jm (= (mv-s om) (mv-s jm)) (= (mv-a om) (mv-a jm)) (= (mv-r om) (- (mv-r jm) *shin-adv*))
                         (= (mv-enter om) (mv-enter jm)) (eq (mv-kind om) (mv-kind jm)) (zerop (length (mv-hits om)))
                         (equal (getf (mv-params om) :trace) (getf (mv-params jm) :trace))
                         (equal (mapcar #'first (mv-on-frame om)) (mapcar #'first (mv-on-frame jm)))
                         (eq (and (member :ender (mv-flags om)) t) (and (member :ender (mv-flags jm)) t)))))
    (loop for (om jm) in (pairs ok kn)
          do (check (and jm (= (mv-s om) (mv-s jm)) (= (mv-a om) (mv-a jm)) (= (mv-r om) (- (mv-r jm) *shin-adv*))
                         (= (mv-enter om) (mv-enter jm)) (= (mv-adv-block om) (+ (mv-adv-block jm) *shin-adv*))
                         (eq (hw-react (svref (mv-hits om) 0)) (hw-react (svref (mv-hits jm) 0)))))))
  ;; EN's strings run without contact (a laid line chains the next link: every recovery > *CHAIN-LEAD*)
  (loop for (em) in (link-moves o)
        do (check (and (chain-open-p (- (mv-total em) 1) (mv-s em) (mv-a em) (mv-r em) t) (> (mv-r em) *chain-lead*)
                       (eq (mv-tick em) 'lb-en-tick) (equal (mv-on-frame em) (list (list (mv-s em) 'lb-en-lay))))))
  ;; SP1 裁きの光明 (EN lays its three lines as traces; KIN bursts three ground lines, one group, R 25); SP2 神の喇叭 (EN its
  ;; wind-up as a 12 f tell, then a thick trace at f12, A 6, R 8: nothing to reflect (decision 38, 「SP2 神之喇叭在遠程模式的前後搖
  ;; 再縮短」: S 20 -> 12, R 14 -> 8, its lock f10 -> f6 at 100 deg/s, the clip at 5x); KIN Trompete as built, R 39 -13,
  ;; reflectable). Sealed: SP2 refused in both modes, nothing else
  (let ((es1 (kit-command-move o :sp1)) (es2 (kit-command-move o :sp2)) (ks1 (kit-command-move ok :sp1)) (ks2 (kit-command-move ok :sp2)))
    (check (and (eq :lb-oe-sabaki (mv-name es1)) (eq :sp1 (getf (mv-params es1) :trace)) (equal (mapcar #'first (mv-on-frame es1)) '(6 12 18))
                (eq :lb-oe-trompete (mv-name es2)) (eq :sp2 (getf (mv-params es2) :trace)) (eq (mv-clip es2) :lb-o-trompete)
                (not (member :reflectable (mv-flags es2))) (= 12 (mv-s es2)) (= 6 (mv-a es2)) (= 8 (mv-r es2))
                (equal (mv-on-frame es2) '((0 lb-trompete-tell) (12 lb-en-lay))) (= 6 (getf (mv-params es2) :lock))
                (~= 100.0 (getf (mv-params es2) :track)) (~= 5.0 (mv-clip-speed es2)) (zerop (length (mv-hits es2)))
                (eq (mv-kind es2) :sp) (= 2 (kit-command-cost o :sp2))
                (eq :lb-misuji (mv-name ks1)) (= 25 (mv-r ks1)) (= 3 (length (getf (mv-params ks1) :fan)))
                (equal (mv-callout ks1) "SABAKI NO KOMYO") (equal (mv-callout es1) "SABAKI NO KOMYO")
                (eq :lb-trompete (mv-name ks2)) (= 39 (mv-r ks2)) (= -13 (mv-adv-block ks2)) (= 60 (mv-s ks2)) (= 30 (mv-a ks2))
                (= 240 (hw-dmg (svref (mv-hits ks2) 0))) (member :reflectable (mv-flags ks2)) (= 2 (kit-command-cost ok :sp2))
                (lb-sp2-sealed-p :sp2 :shin t) (lb-sp2-sealed-p :sp2 :shin-kin t) (lb-sp2-sealed-p :sp2 :shin-mujittai t)
                (lb-sp2-sealed-p :sp2 :shin-kin-mujittai t) (not (lb-sp2-sealed-p :sp2 :shin nil))
                (not (lb-sp2-sealed-p :sp1 :shin-kin t)) (not (lb-sp2-sealed-p :sp2 :jilliel t)))))
  ;; decision 37 (「覺醒後在遠攻狀態使用閃步就會自動切換成近戰狀態」, 「只有 Hoho 會切換」): a Hoho started in an EN form (either
  ;; pair, the stance too) lands in that pair's KIN (its stance), nothing else does (a Step: LILLE-TICK reads :hoho only)
  (check (and (eq (lb-hoho-target :jilliel) :jilliel-kin) (eq (lb-hoho-target :jilliel-mujittai) :jilliel-kin-mujittai)
              (eq (lb-hoho-target :shin) :shin-kin) (eq (lb-hoho-target :shin-mujittai) :shin-kin-mujittai)
              (notany #'lb-hoho-target '(:base :jilliel-kin :jilliel-kin-mujittai :shin-kin :shin-kin-mujittai))
              (every (lambda (f) (lb-kin-form-p (lb-hoho-target f))) '(:jilliel :jilliel-mujittai :shin :shin-mujittai))
              (every (lambda (f) (eq (lb-stance-form-p f) (lb-stance-form-p (lb-hoho-target f))))
                     '(:jilliel :jilliel-mujittai :shin :shin-mujittai))))
  ;; the traces: EN's J / K lines cost 3 each, refused under 3 (decision 35, EN in both pairs); materialised x1.1; the owl's
  ;; refund 5 on a hit, 2 guarded (Jilliel's 4 / 2)
  (check (and (~= 5.0 *shin-trace-refund*) (~= 2.0 *shin-trace-refund-block*) (~= 5.0 (lb-trace-refund :hit t))
              (~= 2.0 (lb-trace-refund :block t)) (zerop (lb-trace-refund nil t)) (~= 4.0 (lb-trace-refund :hit))
              (~= 2.0 (lb-trace-refund :block nil)) (lb-en-dry-p 2.9) (not (lb-en-dry-p 3.0))
              (= 33 (hw-dmg (lb-trace-hitwin :j (kit-mult o)))) (= 198 (hw-dmg (lb-trace-hitwin :sp2 (kit-mult o))))
              (= 26 (hw-dmg (lb-trace-hitwin :k (kit-mult o))))))
  ;; KIN's strings link on hit (the trace stun covers TENSHIN in + KIN J1 for the owl too) and the keys a CPU facing the owl
  ;; reads, his :reflex hook (the owl's own CPU values: the LILLE-CPU-TESTS section above)
  (check (and (>= *lb-trace-stun* (+ (mv-s (find-move :lb-o-switch)) (mv-first-hit (kit-command-move ok :q)) 4))
              (eq (getf (kit-ai o) :opp-reflex) 'lb-opp-trace)
              (eq (getf (kit-ai omu) :opp-reflex) 'lb-opp-trace) (getf (kit-ai ok) :opp-reflect)
              (every (lambda (k) (eq (getf (kit-ai k) :reflex) 'lb-ai-reflex)) owls))))

;; no character names in the generic files (design-v1 §12)
(dolist (f '("rules" "control" "fighter" "combat" "hazards" "ai" "camera" "flow" "endless-rules" "endless"))
  (with-open-file (in (merge-pathnames (format nil "../duel/lisp/~a.lisp" f) *load-truename*))
    (check (loop for line = (read-line in nil) while line
                 never (some (lambda (w) (search w line)) '(":ya-" ":ke-" ":ru-" ":ic-" ":sj-" "yama" "kenpachi" "rukia" "ichigo"
                                                             "senju" ":lb-" "lille"))))))

(format t "duel-rules-test: ~d checks, ~a~%" *checks*
        (if (zerop *fails*) "ALL PASS" (format nil "~d FAILED" *fails*)))
(ext:quit (if (zerop *fails*) 0 1))
