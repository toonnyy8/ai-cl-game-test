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
(dolist (f '("tuning" "rules" "kit" "yama" "ken"))
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
                        (:kenpachi :base) (:kenpachi :nozarashi)))

;;; ================================================================ the triangle / clash matrix
(check (eq (resolve-contact :neutral) :hit))
(check (eq (resolve-contact :guard) :blocked))                            ; guard > attack
(check (eq (resolve-contact :guard :in-front nil) :hit))                  ; ... only from the front
(check (eq (resolve-contact :guard :breaker t) :guard-break))             ; breaker > guard
(check (eq (resolve-contact :guard :guard-crush t) :guard-break))         ; crushing stance / SP2 hold
(check (eq (resolve-contact :breaker) :counter))                          ; attack > breaker
(check (eq (resolve-contact :breaker :quick t :armor-vs-quick t) :counter))
(check (eq (resolve-contact :neutral :breaker t) :hit))                   ; 150 + knockback
(check (eq (resolve-contact :stance) :absorbed))                          ; super armour, stores
(check (eq (resolve-contact :stance :breaker t) :stance-break))           ; breaker breaks the stance
(check (eq (resolve-contact :stance-in) :counter))
(check (eq (resolve-contact :stance-in :breaker t) :stance-break))
(check (null (resolve-contact :invuln :breaker t)))
(check (eq (resolve-contact :neutral :quick t :armor-vs-quick t) :armored))            ; Bankai West
(check (eq (resolve-contact :neutral :quick t :armor-vs-quick t :ignore-armor t) :hit)) ; Nozarashi
(check (eq (resolve-contact :neutral :armor-vs-quick t) :hit))            ; West: Quick only
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
(check (eq (breaker-next-phase :dash 1 t 2.0) :strike))                   ; in range
(check (eq (breaker-next-phase :dash 5 nil 9.0) :dash))                   ; a tap still dashes a bit
(check (eq (breaker-next-phase :dash 12 nil 9.0) :strike))
(check (eq (breaker-next-phase :dash 45 t 9.0) :strike))
(check (and (~= (breaker-speed 0) 9.0) (~= (breaker-speed 45) 10.0)))
(let ((b (mv :yamamoto :base :ya-breaker)))
  (check (and (= (mv-s b) 8) (= (mv-a b) 4) (= (mv-r b) 18) (= (mv-whiff b) 30) (= (mv-dmg b) 150)
              (eq (mv-adv-block b) :guard-break) (member :breaker (hw-flags (svref (mv-hits b) 0)))
              (~= (mv-track b) *track-breaker*) (= (hw-hs (svref (mv-hits b) 0)) 10))))
;; a Q1 thrown on seeing the aura beats the fastest Breaker (aura 12 + strike startup 8)
(check (< (mv-s (mv :yamamoto :base :ya-q1)) (+ *breaker-aura* *breaker-startup*)))

;;; ================================================================ block / whiff advantage
(check (= (blockstun 24 9 -2) 13))
(check (= (hitstun :flinch) 18))
(check (= (hitstun :stagger t) 36))                                     ; counter-hit +10
(check (= (recovery-frames 12 t) 12))
(check (= (recovery-frames 12 nil) 18))                                 ; whiff = R + 6
(check (= (recovery-frames 18 nil 30) 30))                              ; Breaker whiff 30
(check (and (chain-open-p 12 9 3 12 :hit) (not (chain-open-p 11 9 3 12 :hit))))
(check (and (chain-open-p 21 9 3 12 :block) (not (chain-open-p 20 9 3 12 :block))
            (not (chain-open-p 24 9 3 12 :block))))
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
           (- (+ (- (mv-total a) *chain-lead*) (mv-s b)) def)))
(defun hit-gap (a b)
         "Frames between the victim leaving hitstun and B's first active frame (< 0 = a combo)."
         (let ((h (mv-first-hit a)))
           (- (+ (mv-s a) (mv-a a) (- (mv-s b) (mv-enter b))) (+ h 1 (hitstun (hw-react (svref (mv-hits a) 0)))))))
(progn
  (dolist (cf '((:yamamoto :base) (:kenpachi :base)))
    (let* ((k (apply #'kit cf)) (q1 (kit-move k (getf (kit-commands k) :q))))
      ;; a blocked Q1 -> Q2 leaves a gap: >= Step's first iframe, < any Q1 startup (§3); the enders
      ;; after Q2 (Q3, F2) leave more: they are the greedy, interruptible part of the string
      (let ((g (blocked-gap q1 (kit-next k (mv-name q1) :q))))
        (check (and (>= g (first *step-iframes*)) (< g 7) (< g (mv-s q1)))))
      ;; enders and SPs at <= -10 are punishable by the Q1 of either character
      (maphash (lambda (name m)
                 (declare (ignore name))
                 (when (and (integerp (mv-adv-block m)) (<= (mv-adv-block m) -10))
                   (check (< (max (mv-s (mv :yamamoto :base :ya-q1)) (mv-s (mv :kenpachi :base :ke-q1)))
                             (- (mv-adv-block m))))))
               (kit-moves k))
      ;; the Q strings, K K and Q Q K combo on hit (Q2 -f-> is the entered F2, :ENTER)
      (dolist (pair '((:q :q) (:f :f)))
        (let* ((a (kit-move k (getf (kit-commands k) (first pair))))
               (b (kit-next k (mv-name a) (second pair))))
          (check (< (hit-gap a b) 0))))
      (let* ((q2 (kit-next k (mv-name q1) :q)) (q3 (kit-next k (mv-name q2) :q)) (f2 (kit-next k (mv-name q2) :f)))
        (check (< (hit-gap q2 q3) 0))
        (check (< (hit-gap q2 f2) 0))                                   ; Q Q F combos ...
        (let ((kk-f2 (kit-next k (mv-name (kit-command-move k :f)) :f)))   ; the K K version
          (check (and (eql (mv-adv-block f2) (mv-adv-block kk-f2)) (= (mv-dmg f2) (mv-dmg kk-f2))   ; not safer
                      (eq (mv-clip f2) (mv-clip kk-f2)) (plusp (mv-enter f2)) (zerop (mv-enter kk-f2)))))))))
;; Nozarashi keeps Q Q F a combo: :enter grows with the startup (+3)
(let* ((k (kit :kenpachi :nozarashi)) (q2 (mv :kenpachi :nozarashi :ke-q2)) (f2 (kit-next k :ke-q2 :f)))
  (check (and (= (mv-enter f2) 9) (= (mv-s f2) 23)
              (< (+ (mv-s q2) (mv-a q2) (- (mv-s f2) (mv-enter f2))) (+ (mv-s q2) 1 (hitstun :flinch))))))
(check (~= (mv-clip-speed (mv :kenpachi :nozarashi :ke-q1)) (/ 7.0 10.0)))  ; hit pose on the later hit frame
(check (~= (mv-clip-speed (mv :kenpachi :base :ke-q1)) 1.0))
;; Yama's Q1 -> Q2 on block: exactly the 6 f gap of §3 (free on step 23, Q2 hits on step 21 + 8)
(let ((q1 (mv :yamamoto :base :ya-q1)) (q2 (mv :yamamoto :base :ya-q2)))
  (check (= 23 (nth-value 1 (free-steps q1))))
  (check (= 6 (- (+ (- (mv-total q1) *chain-lead*) (mv-s q2)) (nth-value 1 (free-steps q1))))))
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
(check (= (hit-damage 100 (kit-atk-mods (kit :yamamoto :bankai-east) 4) nil 1 nil) 120))
(check (= (hit-damage 100 (kit-atk-mods (kit :kenpachi :nozarashi) 4) nil 1 nil) 138)) ; 1.15 x 1.20
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
;; and Nozarashi's ignore-armor go through
(check (and (eq (resolve-contact :armor) :armored) (eq (resolve-contact :armor :quick t) :armored)
            (eq (resolve-contact :armor :breaker t) :hit) (eq (resolve-contact :armor :unguardable t) :hit)
            (eq (resolve-contact :armor :ignore-armor t) :hit)))
(check (equal (multiple-value-list (kikon-result 6 nil nil)) '(4 2 nil)))
(check (equal (multiple-value-list (kikon-result 6 t nil)) '(3 3 nil)))           ; awakened
(check (equal (multiple-value-list (kikon-result 6 nil t)) '(3 3 nil)))           ; Soul Break +1
(check (equal (multiple-value-list (kikon-result 6 t t)) '(2 4 nil)))
(check (equal (multiple-value-list (kikon-result 2 nil nil)) '(0 2 t)))
(check (equal (multiple-value-list (kikon-result 1 t t)) '(0 1 t)))
(check (and (soul-break-p 0) (not (soul-break-p 1))))
(check (eql (time-up-winner 3 100 1000 2 900 1000) 0))                   ; Konpaku first
(check (eql (time-up-winner 2 900 1000 3 100 1000) 1))
(check (eql (time-up-winner 2 600 1000 2 500 1000) 0))                   ; then Reishi %
(check (eql (time-up-winner 2 500 1000 2 525 1050) :draw))               ; 50 % each
(multiple-value-bind (ax az bx bz) (reset-placement 10.0 0.0 12.0 0.0)
  (check (and (~= ax -4.0) (~= az 0.0) (~= bx 4.0) (~= bz 0.0))))

;;; ================================================================ gauges
(check (and (~= (reiatsu-gain 100 0) 8.0) (~= (reiatsu-gain 0 100) 10.0) (~= (reiatsu-gain 0 0 60) 3.0)))   ; SPs only: 3 / s
(check (~= (awakening-gain 100 100 1) 27.0))
(check (and (~= (gauge-add 290.0 20.0 300.0) 300.0) (~= (gauge-add 5.0 -10.0 300.0) 0.0)))
(check (equal (multiple-value-list (spend-bars 150.0 1)) '(50.0 t)))
(check (equal (multiple-value-list (spend-bars 50.0 1)) '(50.0 nil)))
(check (and (hoho-allowed-p nil 30.0 0) (not (hoho-allowed-p t 100.0 0))          ; flash-step 30
            (not (hoho-allowed-p nil 100.0 10)) (not (hoho-allowed-p nil 29.0 0))))
(check (and (awaken-allowed-p t 100.0 nil) (not (awaken-allowed-p t 100.0 t)) (not (awaken-allowed-p nil 100.0 nil))
            (not (awaken-allowed-p t 99.0 nil))))
(check (and (burst-allowed-p t 2 70.0) (not (burst-allowed-p t 1 100.0)) (not (burst-allowed-p t 2 69.0))))  ; flash-step 70
(check (not (burst-allowed-p nil 5 100.0)))                                 ; not in hitstun: no Burst
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
(check (and (= (hw-guard (svref (mv-hits (mv :kenpachi :base :ke-q3)) 0)) 12)            ; Q3 ender 12
            (= (hw-guard (svref (mv-hits (mv :kenpachi :base :ke-f2)) 0)) 18)            ; F2 ender 18
            (= (hw-guard (svref (mv-hits (mv :yamamoto :base :ya-sig)) 0)) 10)           ; the Signature's cuts 10 each
            (= 15 (getf (mv-params (find-move :ya-sig)) :guard))))                       ; ... its wave 15
;; Kenpachi base Q1 Q2 Q3 blocked = 28, F1 F2 = 32: a full gauge falls on the 4th Q string
(flet ((gv (name) (hw-guard (svref (mv-hits (mv :kenpachi :base name)) 0))))
  (check (= 28 (+ (gv :ke-q1) (gv :ke-q2) (gv :ke-q3))))
  (check (= 32 (+ (gv :ke-f1) (gv :ke-f2))))
  (check (and (< (* 3 28) *gg-max*) (>= (* 4 28) *gg-max*))))
(check (equal (multiple-value-list (gg-drain 100.0 8)) '(92.0 nil)))
(check (equal (multiple-value-list (gg-drain 5.0 8)) '(0.0 t)))            ; emptied: GUARD CRUSH
(check (and (= *gg-delay* 60) (~= *gg-regen* 12.0) (~= *gg-regen-guardless* 14.0)))  ; the user's slower refill
(check (and (~= (gg-regen 50.0 59 nil) 50.0) (~= (gg-regen 50.0 60 nil) (+ 50.0 (/ 12.0 60)))
            (~= (gg-regen 50.0 60 t) (+ 50.0 (/ 14.0 60))) (~= (gg-regen 99.9 99 nil) 100.0)))
(check (<= 489 (loop with g = 0.0 for f from 0 until (>= g *gg-max*)         ; 0 -> 100 guardless: 60 f of delay +
                     do (setf g (gg-regen g f t)) finally (return f)) 490))   ;  429 f (7.1 s; + 1 f of float rounding)
(check (and (can-guard-p 1.0 nil) (not (can-guard-p 0.0 nil)) (not (can-guard-p 99.0 t))))
;; a guard crush: Kenpachi's Q1 blocked into an empty gauge -> the attacker acts 25 frames first
(let ((q1 (mv :kenpachi :base :ke-q1)))
  (check (= 25 (- *guard-crush-stun* (- (mv-total q1) (mv-first-hit q1)))))
  (check (= *gg-breaker* 35)))
;; the CPU's guard: all at >= 50 %, half at 25-50 %, 0.15 below, none guardless; flash-step budgeting
(check (and (~= (ai-guard-mult 50.0 nil) 1.0) (~= (ai-guard-mult 30.0 nil) 0.5) (~= (ai-guard-mult 10.0 nil) 0.15)
            (~= (ai-guard-mult 100.0 t) 0.0) (~= (ai-guard-mult 0.0 nil) 0.0)))
(check (and (ai-hoho-spare-p 30.0 1000 1100) (not (ai-hoho-spare-p 90.0 400 1100)) (ai-hoho-spare-p 100.0 400 1100)))
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
(check (equal (multiple-value-list (combo-step :flinch nil 9 0 0)) '(:knockdown 10 0 0)))  ; cap 10

;;; ================================================================ perfect Hoho
;; Yama's Q1 (window [9,12), 2.4 m arc) from the origin facing -Z; our cylinder r 0.4 h 1.8
(let* ((q1 (mv :yamamoto :base :ya-q1)) (w (svref (mv-hits q1) 0)))
  (flet ((perfect (sf z) (perfect-hoho-p sf (hw-from w) (hw-to w) (hw-vols w)
                                         0f0 0f0 0f0 0f0 -1f0 0f0 0f0 (float z 1f0) 0.4f0 1.8f0)))
    (check (perfect 3 -2.0))                  ; active in 6 f: perfect
    (check (not (perfect 0 -2.0)))            ; 9 f away: too early
    (check (perfect 10 -2.0))                 ; active now
    (check (not (perfect 12 -2.0)))           ; over
    (check (perfect 3 -3.5))                  ; out of reach, but inside the 1 m inflation
    (check (not (perfect 3 -4.5)))))

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
  '((:ya-q1 9 3 12 38 -2) (:ya-q2 8 3 13 38 -2) (:ya-q3 12 4 22 60 -12) (:ya-f1 18 4 20 75 -4)
    (:ya-f2 22 5 28 95 -14) (:ya-sig 16 ? 26 30 -6) (:ya-taimatsu 16 8 24 120 -14)
    (:ya-nadegiri 20 4 30 240 -16) (:ya-breaker 8 4 18 150 :guard-break) (:ya-kyoku 18 5 26 90 -16)
    (:ya-kaka 20 1 34 0 nil)
    ;; Bankai East / West (design v3 §A.2, §A.3)
    (:ya-e-q1 8 3 12 34 -2) (:ya-e-q3 11 3 27 55 -12) (:ya-e-f1 16 4 20 70 -4) (:ya-e-f2 19 4 26 90 -14)
    (:ya-e-f2q 19 4 26 90 -14) (:ya-to-west 14 4 20 50 -10) (:ya-w-q1 11 3 12 40 -2) (:ya-w-q3 13 4 22 70 -12)
    (:ya-w-f1 20 4 20 80 -4) (:ya-w-f2 22 5 28 110 -14) (:ya-w-f2q 22 5 28 110 -14) (:ya-to-east 12 3 22 90 -8)
    (:ya-w-parry 4 12 30 0 nil) (:ya-w-counter 6 3 24 150 -12)
    (:ke-q1 7 3 12 35 -2) (:ke-q2 7 3 13 35 -2) (:ke-q3 11 4 22 55 -12) (:ke-f1 16 4 20 70 -4)
    (:ke-f2 20 5 28 90 -14) (:ke-stance 8 4 24 100 -14) (:ke-buttagiru 22 4 26 180 -14)
    (:ke-charge 14 ? ? 25 -16) (:ke-breaker 8 4 18 150 :guard-break) (:ke-meteor 26 4 30 240 ?)))
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
    (check (every (lambda (c) (kit-command-move k c)) *kit-commands*))
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
(check (and (~= (kit-mult (kit :yamamoto :hellfire)) 1.3) (~= (kit-mult (kit :yamamoto :bankai-east)) 1.2)
            (~= (kit-mult (kit :kenpachi :nozarashi)) 1.15) (~= (kit-mult (kit :kenpachi :base)) 1.0)))
(check (eq (mv-name (kit-command-move (kit :yamamoto :hellfire) :sp2)) :ya-nadegiri))
(check (eq (mv-name (kit-command-move (kit :yamamoto :hellfire) :sp1)) :ya-shiranui))  ; inherited
(check (eq (mv-name (kit-command-move (kit :yamamoto :bankai-east) :kikon)) :ya-tenchi))
;; the Kikon rush of every form: a strike with a cinematic, clearly punishable on block (Q1 of either
;; character fits, also after the block pushback from the trigger range), reach beyond the trigger
(dolist (cf *forms*)
  (let ((m (kit-command-move (apply #'kit cf) :kikon)))
    (check (and (eq (mv-kind m) :kikon) (mv-cine m) (= 1 (length (mv-hits m))) (<= (mv-adv-block m) -12)
                (> (mv-reach m) *kikon-trigger*) (plusp (mv-dmg m))
                (<= (+ *kikon-trigger* *block-pushback*) (min (mv-reach (mv :yamamoto :base :ya-q1))
                                                              (mv-reach (mv :kenpachi :base :ke-q1))))))))
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
(check (and (member :armor-vs-quick (kit-passives (kit :yamamoto :bankai-west)))
            (not (member :armor-vs-quick (kit-passives (kit :yamamoto :bankai-east))))))
(check (and (~= (kit-walk (kit :yamamoto :base)) 3.2) (~= (kit-walk (kit :kenpachi :nozarashi)) 4.4)))
(check (~= (kit-reset-reiatsu (kit :kenpachi :base)) 10.0))
;; Nozarashi: derived by the kit, not copied (startup +3, reach x1.4), own moves as written
(let ((base (mv :kenpachi :base :ke-q1)) (noz (mv :kenpachi :nozarashi :ke-q1)))
  (check (and (= (mv-s base) 7) (= (mv-s noz) 10) (= (mv-r noz) 12) (= (mv-dmg noz) 35)
              (~= (mv-reach noz) (* 2.6 1.4)) (= (hw-from (svref (mv-hits noz) 0)) 10)
              (~= (aref (first (hw-vols (svref (mv-hits noz) 0))) 1) (* 2.6 1.4)))))
(check (= (mv-s (mv :kenpachi :nozarashi :ke-stance)) 11))
(check (= (mv-s (mv :kenpachi :nozarashi :ke-breaker)) 11))
(check (~= (aref (first (hw-vols (svref (mv-hits (mv :kenpachi :nozarashi :ke-charge)) 0))) 2) (* 1.4 1.4)))
(check (= (mv-s (mv :kenpachi :nozarashi :ke-meteor)) 26))
(check (eq (mv :kenpachi :nozarashi :ke-meteor) (find-move :ke-meteor)))
(check (eq (kit-next (kit :kenpachi :nozarashi) :ke-q1 :q) (mv :kenpachi :nozarashi :ke-q2)))
;; clip names: exactly the §5 contract, and every §5 clip is used
(defparameter *clips-5*
  '(:ya-stance :ya-q1 :ya-q2 :ya-q3 :ya-f1 :ya-f2 :ya-sig :ya-shiranui :ya-shiranui-throw :ya-taimatsu
    :ya-nadegiri :ya-breaker :ya-ikkotsu :ya-intro :ya-win :ya-hellfire :ya-bankai :ya-kyoku
    :ya-kaka :sh-run :ya-enjo :ke-n-leap ; the O modules (TENCHI runs in :sh-run, CHARGE in :ke-charge)
    :ya-e-thrust :ya-to-west :ya-to-east :ya-w-shove :ya-w-parry :ya-w-counter   ; the Bankai stances
    :ke-stance :ke-q1 :ke-q2 :ke-q3 :ke-f1 :ke-f2 :ke-stance-hold :ke-stance-cut :ke-buttagiru :ke-charge
    :ke-flurry :ke-breaker :ke-shoulder :ke-intro :ke-win :ke-patch :ke-nome :ke-meteor
    :ke-n-stance))
;; (the Kikon cinematics' own clips, :ya-kikon :ya-tenchi :ke-kikon :ke-kikon-n, are played by their
;; DEFCINEs, which the host stubs)
(let ((used (remove-duplicates (loop for cf in *forms* append (kit-clips (apply #'kit cf))))))
  (let ((extra (set-difference used *clips-5*)) (unused (set-difference *clips-5* used)))
    (when (or extra unused) (format t "  clips not in §5: ~s, §5 clips unused: ~s~%" extra unused))
    (check (and (null extra) (null unused)))))
;; phase 2: art names, roster, form looks, the flurry, hazard hits
(check (equal (mapcar #'kit-weapon (mapcar (lambda (cf) (apply #'kit cf)) *forms*))
              '(:ryujin-jakka :ryujin-jakka :zanka :zanka :ken-katana :nozarashi)))         ; the art agent's keys
(check (equal *roster* '(:yamamoto :kenpachi)))
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

;;; ================================================================ Bankai stances + burnout (design v3 §A; part 2)
(let ((east (kit :yamamoto :bankai-east)) (west (kit :yamamoto :bankai-west)))
  ;; the forms: East x1.2 dealt / x1.4 taken, 25 % chip, projectile-cut + recoil; West x1.0 / x1.0, armour vs Quick
  ;; + scorch, no chip; both awakened, permanent, burning out on the guard gauge
  (check (and (~= (kit-mult east) 1.2) (~= (kit-taken east) 1.4) (~= (kit-blade-chip east) 0.25)
              (equal (kit-passives east) '(:projectile-cut :recoil))))
  (check (and (~= (kit-mult west) 1.0) (~= (kit-taken west) 1.0) (null (kit-blade-chip west))
              (equal (kit-passives west) '(:armor-vs-quick :scorch))))
  (check (and (kit-burnout east) (kit-burnout west) (kit-awakening west) (null (kit-duration west))
              (not (kit-burnout (kit :yamamoto :base))) (not (kit-burnout (kit :kenpachi :nozarashi)))
              (eq (kit-awaken-form (kit :yamamoto :base)) :bankai-east)))
  (check (and (eq (mv-name (kit-command-move east :sp1)) :ya-kyoku) (eq (mv-name (kit-command-move west :sp1)) :ya-w-parry)
              (eq (mv-name (kit-command-move east :sig)) :ya-to-west) (eq (mv-name (kit-command-move west :sig)) :ya-to-east)))
  ;; burnout (the five gates): x1.0 dealt, no chip, no armour, the :heat flags filtered; :taken stays
  (check (and (= (hit-damage 100 (kit-atk-mods east 0) nil 1 nil) 120) (= (hit-damage 100 (kit-atk-mods east 0 nil) nil 1 nil) 100)
              (= (hit-damage 100 nil (kit-def-mods east) 1 nil) 140) (= (hit-damage 100 nil (kit-def-mods west) 1 nil) 100)))
  (check (and (~= (chip-rate nil 0.25 t) 0.25) (null (chip-rate nil 0.25 nil)) (~= (chip-rate 0.4 nil t) 0.4) (null (chip-rate 0.4 nil nil))
              (null (chip-rate nil nil t))))
  (check (and (= (armor-budget 2 t) 2) (= (armor-budget 2 nil) 0)))
  (check (and (equal (heat-flags '(:guard-crush :heat) t) '(:guard-crush :heat)) (not (member :guard-crush (heat-flags '(:guard-crush :heat) nil)))
              (equal (heat-flags '(:guard-crush) nil) '(:guard-crush))))           ; only :heat-marked windows lose it
  ;; the derivation rule (the inheritance fix): own moves as written, inherited ones derived; West lists South
  ;; and North in its own :commands, so they are East's frames exactly (not +2)
  (check (and (= (mv-s (kit-move east :ya-q2)) 7) (~= (mv-reach (kit-move east :ya-q2)) 2.76 0.01)
              (= (mv-s (kit-move west :ya-q2)) 10) (~= (mv-reach (kit-move west :ya-q2)) 2.4 0.01)
              (= (mv-s (kit-command-move east :breaker)) 7) (= (mv-s (kit-command-move west :breaker)) 10)))
  (check (and (= (mv-s (kit-move east :ya-e-q1)) 8) (= (mv-s (kit-move east :ya-e-q3)) 11) (= (mv-s (kit-move west :ya-w-f2)) 22)
              (= (mv-s (kit-move west :ya-to-east)) 12) (= (mv-s (kit-move west :ya-w-q3)) 13) (= (mv-s (kit-move west :ya-w-counter)) 6)))
  (dolist (name '(:ya-kaka :ya-tenchi))
    (let ((a (kit-move east name)) (b (kit-move west name)))
      (check (and (eq a b) (= (mv-s a) (mv-s (find-move name))) (equal (mv-on-frame a) (mv-on-frame b))))))
  (check (~= (mv-clip-speed (kit-move east :ya-q2)) (/ 8.0 7.0)))              ; a -1 f derivation plays its clip faster
  ;; the combos, both stances: Q1 -> Q2, Q2 -> Q3', Q2 -> F2q', F1 -> F2' on hit; L cancels from Q2 in time;
  ;; a blocked Q1 -> Q2 leaves a gap >= Step's first iframe (East's also < 7)
  (dolist (k (list east west))
    (let* ((q1 (kit-command-move k :q)) (q2 (kit-next k (mv-name q1) :q)) (q3 (kit-next k (mv-name q2) :q))
           (f2q (kit-next k (mv-name q2) :f)) (f1 (kit-command-move k :f)) (f2 (kit-next k (mv-name f1) :f)))
      (check (and (< (hit-gap q1 q2) 0) (< (hit-gap q2 q3) 0) (< (hit-gap q2 f2q) 0) (< (hit-gap f1 f2) 0)))
      (check (< (- (mv-s (kit-command-move k :sig)) (hitstun (hw-react (svref (mv-hits q2) 0)))) 0))
      (check (>= (blocked-gap q1 q2) (first *step-iframes*)))))
  (check (< (blocked-gap (kit-command-move east :q) (kit-move east :ya-q2)) 7))
  ;; the ender-gap rule: after a string ender (or L) that leaves the victim near (flinch / stagger / knockback
  ;; <= 1.5 m), his Step fits before the next Q1 (of the stance he is in by then): S(Q1) - on-hit adv >= 3.
  ;; E-Q3's R27 makes it +-0 (v1's "+7 frame trap" was a 1 f loop)
  (flet ((on-hit-adv (m) (let ((w (svref (mv-hits m) 0)))
                           (- (or (hw-stun w) (hitstun (hw-react w))) (- (mv-total m) (hw-from w))))))
    (check (= 0 (on-hit-adv (find-move :ya-e-q3))))
    (dolist (k (list east west))
      (dolist (m (cons (kit-command-move k :sig) (loop for (nil nil to) in (kit-strings k) collect (kit-move k to))))
        (let ((w (svref (mv-hits m) 0)))
          (when (or (member (hw-react w) '(:flinch :stagger)) (and (eq (hw-react w) :knockback) (<= (hw-kb w) 1.5)))
            (let ((next (if (getf (mv-params m) :to) (kit (kit-character k) (getf (mv-params m) :to)) k)))
              (check (>= (- (mv-s (kit-command-move next :q)) (on-hit-adv m)) (first *step-iframes*)))))))))
  ;; L: a Signature that cancels a landed Q / F, switches on its first active frame to the other stance, and
  ;; cools *SWITCH-COOLDOWN* (longer than itself + the chain lead); armour budgets from *ARMOR-FROM*
  (dolist (k (list east west))
    (let ((l (kit-command-move k :sig)))
      (check (and (eq (mv-kind l) :sig) (member :cancel (mv-flags l)) (= (mv-cooldown l) *switch-cooldown* 100)
                  (> (mv-cooldown l) (+ (mv-total l) *chain-lead*)) (equal (mapcar #'first (mv-on-frame l)) (list (mv-s l)))
                  (not (eq (getf (mv-params l) :to) (kit-form k))) (find-kit :yamamoto (getf (mv-params l) :to))))))
  (check (and (= 1 (mv-armor-hits (find-move :ya-to-west)) (mv-armor-hits (find-move :ya-w-q3)) (mv-armor-hits (find-move :ya-w-f1)))
              (= 2 (mv-armor-hits (find-move :ya-w-f2))) (zerop (mv-armor-hits (find-move :ya-to-east)))
              (< *armor-from* (min (mv-s (find-move :ya-to-west)) (mv-s (find-move :ya-w-q3))))))
  ;; armour is paid by the guard gauge: Kenpachi's Q1 Q2 Q3 into West's armour vs Quick = 28, his F1 into
  ;; W-F1's armour = 14; East's recoil (0.6 x the guard value): a blocked E-Q1 Q2 E-Q3 = 5 + 5 + 7 = 17, the cone 13
  (check (eq (resolve-contact :neutral :quick t :armor-vs-quick t) :armored))
  (flet ((gv (k name) (hw-guard (svref (mv-hits (kit-move k name)) 0))))
    (check (= 28 (+ (gv (kit :kenpachi :base) :ke-q1) (gv (kit :kenpachi :base) :ke-q2) (gv (kit :kenpachi :base) :ke-q3))))
    (check (= 14 (gv (kit :kenpachi :base) :ke-f1)))
    (check (= 17 (+ (recoil (gv east :ya-e-q1)) (recoil (gv east :ya-q2)) (recoil (gv east :ya-e-q3)))))
    (check (and (= 13 (recoil 22)) (= 12 (recoil 20)) (= (gv east :ya-to-west) 22) (= (gv west :ya-to-east) 18))))
  ;; KYOKUJITSUJIN: the blade [18,20) breaks guard (:heat: not in burnout), the tip's cone [20,23) 25 deg x 9 m,
  ;; 130, knockback 4 m, blockable (never a break), -16; the blade's short knockback keeps the victim in the cone
  (let* ((m (kit-command-move east :sp1)) (bl (svref (mv-hits m) 0)) (co (svref (mv-hits m) 1)))
    (check (and (= 2 (length (mv-hits m))) (= (hw-from bl) 18) (= (hw-to bl) 20 (hw-from co)) (= (hw-to co) 23)
                (= (hw-dmg bl) 90) (= (hw-dmg co) 130) (equal (hw-flags bl) '(:guard-crush :heat)) (null (hw-flags co))
                (eq (hw-react bl) :knockback) (~= (hw-kb bl) 0.5) (eq (hw-react co) :knockback) (~= (hw-kb co) 4.0)
                (= (mv-adv-block m) -16) (= (hw-guard co) 22)))
    (check (and (~= (aref (first (hw-vols co)) 1) 9.0) (~= (* 2 (aref (first (hw-vols co)) 2)) (deg 25))))
    (check (and (eq (resolve-contact :guard :guard-crush (member :guard-crush (heat-flags (hw-flags bl) t))) :guard-break)
                (eq (resolve-contact :guard :guard-crush (member :guard-crush (heat-flags (hw-flags bl) nil))) :blocked)
                (eq (resolve-contact :guard :guard-crush (member :guard-crush (hw-flags co))) :blocked)))
    (flet ((hits (v x z) (vol-hit-p v 0f0 0f0 0f0 0f0 -1f0 (float x 1f0) 0f0 (float z 1f0) 0.36f0 1.65f0 0f0)))
      (check (and (hits (first (hw-vols co)) 0 -8.5) (hits (first (hw-vols co)) 2.0 -8.5) (not (hits (first (hw-vols co)) 3.0 -8.5))
                  (not (hits (first (hw-vols co)) 0 -9.6)) (hits (first (hw-vols bl)) 0 -2.0) (not (hits (first (hw-vols bl)) 0 -3.2))))))
  ;; GOKUI GAESHI: the parry catches a melee hit on f4-15 (12 f = its active frames), not a hazard, not an
  ;; unguardable one; a Breaker breaks it; parried = a block for the attacker (no string, no Kikon); the counter
  ;; (150, knockback) lands inside the parried attacker's stagger: guaranteed
  (let ((p (kit-command-move west :sp1)) (c (kit-next west :ya-w-parry :land)))
    (check (and (not (parry-frame-p 3)) (parry-frame-p 4) (parry-frame-p 15) (not (parry-frame-p 16))
                (= (mv-a p) (1+ (- (second *parry-window*) (first *parry-window*)))) (= (mv-s p) (first *parry-window*))
                (member :parry (mv-flags p)) (zerop (length (mv-hits p))) (= (mv-total p) 46) (= (kit-command-cost west :sp1) 1)))
    (check (and (eq (resolve-contact :parry) :parried) (eq (resolve-contact :parry :quick t) :parried)
                (eq (resolve-contact :parry :breaker t) :stance-break) (eq (resolve-contact :parry :hazard t) :hit)
                (eq (resolve-contact :parry :unguardable t) :hit) (eq (contact-of :parried) :block)
                (null (kikon-outcome t :parried nil))))
    (check (and (eq (mv-name c) :ya-w-counter) (= (mv-dmg c) 150) (eq (hw-react (svref (mv-hits c) 0)) :knockback)
                (< (1+ (mv-s c)) *parry-stun*) (= *parry-stun* 32) (= *scorch* 15))))
  ;; South, the bind: 20/1/34 (55 f), 2 bars, cooldown 600 (longer than the cast + the grab + the hold); the
  ;; grab 16 f after the stab; 40 + bound 60; the follow-up window 41; unguardable (guard, stance, armour, parry
  ;; don't stop it; iframes do); it only opens a combo (else a flinch) and books 2 hits: 70 flash-step Bursts out
  (let* ((m (kit-command-move east :sp2)) (pa (mv-params m)))
    (check (and (= (mv-total m) 55) (= (kit-command-cost east :sp2) 2) (= (mv-cooldown m) 600) (member :bind (mv-flags m))
                (= (getf pa :delay) 16) (= (getf pa :dmg) 40) (= (getf pa :stun) *bind-stun* 60) (~= (getf pa :range) 10.0)
                (> (mv-cooldown m) (+ (mv-s m) (getf pa :delay) (getf pa :stun)))
                (= 41 (- (+ (mv-s m) (getf pa :delay) (getf pa :stun)) (mv-total m)))))
    (check (and (eq (resolve-contact :guard :unguardable t) :hit) (eq (resolve-contact :stance :unguardable t) :hit)
                (eq (resolve-contact :armor :unguardable t) :hit) (eq (resolve-contact :parry :unguardable t :hazard t) :hit)
                (null (resolve-contact :invuln :unguardable t))))
    (check (equal (multiple-value-list (combo-step :bind nil 0 0 0)) '(:bind 2 0 0)))       ; the opener: 2 hits
    (check (equal (multiple-value-list (combo-step :bind nil 1 0 0)) '(:flinch 2 0 0)))     ; in a combo: a flinch
    (check (and (burst-allowed-p t (nth-value 1 (combo-step :bind nil 0 0 0)) *fs-burst*)
                (not (burst-allowed-p t (nth-value 1 (combo-step :bind nil 0 0 0)) (1- *fs-burst*)))))
    (check (equal (multiple-value-list (combo-step :flinch nil 2 0 0)) '(:flinch 3 0 0)))   ; the follow-up is hit 3
    ;; the escapes: a Step pressed from the stab's f16 carries him past the grab disc; one pressed f28-33 has
    ;; its iframes over the grab (f36-37); a Hoho pressed f23-35 too; walking doesn't (16 f of walk < the disc)
    (let ((grab (+ (mv-s m) (getf pa :delay))) (r (+ (getf pa :radius) 0.45)))
      (check (and (= grab 36) (> *step-distance* r) (< (* *walk-kenpachi* (/ (getf pa :delay) 60.0)) r)
                  (<= (+ 33 (first *step-iframes*)) grab) (>= (+ 28 (second *step-iframes*)) (1+ grab))
                  (<= (+ 35 (first *hoho-iframes*)) grab) (>= (+ 23 (second *hoho-iframes*)) (1+ grab)))))
    (multiple-value-bind (x z) (cast-point 0.0 0.0 12.0 0.0 10.0) (check (and (~= x 10.0) (~= z 0.0))))
    (multiple-value-bind (x z) (cast-point 0.0 0.0 3.0 4.0 10.0) (check (and (~= x 3.0) (~= z 4.0))))))

;; no character names in the generic files (design-v1 §12)
(dolist (f '("rules" "control" "fighter" "combat" "hazards" "ai" "camera" "flow"))
  (with-open-file (in (merge-pathnames (format nil "../duel/lisp/~a.lisp" f) *load-truename*))
    (check (loop for line = (read-line in nil) while line
                 never (some (lambda (w) (search w line)) '(":ya-" ":ke-" "yama" "kenpachi"))))))

(format t "duel-rules-test: ~d checks, ~a~%" *checks*
        (if (zerop *fails*) "ALL PASS" (format nil "~d FAILED" *fails*)))
(ext:quit (if (zerop *fails*) 0 1))
