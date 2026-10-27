(in-package :duel)

(defvar *br-tip-print* nil)   ; (t: print the awakened stances' drawn tips, *BR-W-TIPS*)
(defvar *br-w-stretch* nil)   ; (barro-art.lisp's whips, read with the art files below)
(defvar *br-squash* nil)      ; (barro-art.lisp's squash and stretch, R8)
(defvar *lb-wall-jl* nil)     ; (lille-art.lisp's wing wall rows: Lille II's awakened guard)
(defvar *lb-wall-owl* nil)
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
                        (:barro :base) (:barro :jilliel-kin) (:barro :jilliel) (:barro :shin-kin) (:barro :shin)
                        (:hisagi :base) (:hisagi :bankai) (:hisagi :bankai-bind)))   ; (Hisagi's Shikai, B2a: DUEL_HISAGI §8;
                                                                ;  his Bankai's two modes, B2b: §17; Lille II
                                                                ;  v3: MUJITTAI gone, DUEL_LILLE_V3 R1)
(defun owl-adv (cf)
  "The frame advantage CF's J / K add to DUEL_STRINGS's budget: the owl's *SHIN-ADV* (decision 36: each recovery 1 f
shorter, its :adv-block 1 higher), else 0."
  (cond ((and (eq (first cf) :barro) (br-owl-form-p (second cf))) *br-owl-adv*)   ; (Lille II's owl: the same +1)
        (t 0)))
(defun trace-form-p (cf)
  "Is CF a form whose J / K strings lay traces instead of hitting (Lille's JILLIEL EN, DUEL_LILLE §22.2): its J1 has no hit
window? The hit-based string checks skip it (its own block below checks its frames)."
  (or (zerop (length (mv-hits (kit-command-move (apply #'kit cf) :q))))
      (and (eq (first cf) :barro) (member (second cf) '(:jilliel :shin)) t)))   ; (Lille II v3: his stance EN's strings,
                                                                                  ;  DUEL_LILLE_V3 R2: own block below)

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
    (when br   ; (Lille II's ranged J is J1 in place again: DUEL_LILLE_V2 decision V6a; V6's TENSHIN in skipped it)
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
             (when (and (integerp (mv-adv-block m)) (plusp (length (mv-hits m))))
               (multiple-value-bind (att def) (free-steps m)
                 (check (or (= (- def att) (mv-adv-block m))        ; the §5 table's number, exactly
                            (format t "~a ~a: block advantage ~d, its :adv-block ~d~%" cf name (- def att) (mv-adv-block m)))))))
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
           (- (+ (mv-s a) (mv-a a) (- (mv-s b) (mv-enter b)))
              (+ h 1 (let ((w (svref (mv-hits a) 0))) (or (hw-stun w) (hitstun (hw-react w))))))))   ; (a window's :stun)
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
(defun on-hit-adv (m &optional (i 0))
  (let ((w (svref (mv-hits m) i))) (- (or (hw-stun w) (hitstun (hw-react w))) (- (mv-total m) (hw-from w)))))
(dolist (cf (remove-if #'trace-form-p *forms*))
  (let* ((k (apply #'kit cf)) (links (link-moves k)) (j1 (kit-command-move k :q)) (k1 (kit-command-move k :f))
         (cup3 (equal cf '(:kenpachi :nomihose))) (fails0 *fails*) (a (owl-adv cf))
         (v8 (eq (first cf) :barro))   ; (Lille II: decision V8 splits his J / K off the budget, DUEL_LILLE_V2 §21: own rows)
         (hs1 (equal cf '(:hisagi :base)))   ; (Hisagi's Shikai since S2, DUEL_HISAGI §23.5: a J after a K leaps in, J2K / J3K)
         (hr (equal cf '(:hisagi :bankai))))   ; (Hisagi's ranged mode, DUEL_HISAGI §17.1: 「前搖大」; B4a, §22.2: J1 S 14;
                                               ;  B4c, §22.4: the route links' S -3 (spread) / +3 (gathered), K1 綁束 S 16;
                                               ;  its own block below pins the rest)
    ;; the shape: exactly the six full routes JJJ JJK JKK KKK KKJ KJJ (J / K switch at most once), every link 3 an ender
    (check (equal (sort (loop for (nil n seq) in links when (= n 3) collect (format nil "~{~a~}" (mapcar (lambda (c) (if (eq c :q) "J" "K")) seq)))
                        #'string<)
                  '("JJJ" "JJK" "JKK" "KJJ" "KKJ" "KKK")))
    (check (every (lambda (l) (eq (and (member :ender (mv-flags (first l))) t) (= 3 (second l)))) links))
    (check (every (lambda (l) (eq (string-link-p k (mv-name (first l))) (< (second l) 3))) links))
    ;; the budget (§2.1): J1 S 7-10 A 3 R 12 flinch -2; K1 S 16-20 A 4 R 20-22 stagger -3, no armour (cup 3's K1 is
    ;; KUKAN-GIRI, -4); J beats K: S(K1) - S(J1) >= 7
    ;; (the owl's +1, decision 36: R 1 f shorter, :adv-block 1 higher on every J / K)
    (if v8   ; (decision V8: J S - 2 / R - 2 / adv + 2, K S + 2 / R + 2 / adv - 4 over the budget's numbers)
        (check (and (if (eq (second cf) :base)   ; (decision R3: the awakened J strings at the standard speed, route :JN)
                        (and (= 6 (mv-s j1)) (= (- 10 a) (mv-r j1)))
                        (and (<= 7 (mv-s j1) 10) (= (- 12 a) (mv-r j1))))
                    (= 3 (mv-a j1)) (= a (mv-adv-block j1))
                    (eq :flinch (hw-react (svref (mv-hits j1) 0)))
                    (= 19 (mv-s k1)) (= 4 (mv-a k1)) (= (- 23 a) (mv-r k1)) (= (+ a -7) (mv-adv-block k1))
                    (zerop (mv-armor-hits k1)) (eq :stagger (hw-react (svref (mv-hits k1) 0)))))
        (progn
    (check (and (if hr (= 14 (mv-s j1)) (<= 7 (mv-s j1) 10)) (= 3 (mv-a j1)) (= (- 12 a) (mv-r j1)) (= (+ -2 a) (mv-adv-block j1))
                (eq :flinch (hw-react (svref (mv-hits j1) 0)))))
    (check (and (<= 16 (mv-s k1) 20) (= 4 (mv-a k1)) (<= (- 20 a) (mv-r k1) 22) (= (+ a (if cup3 -4 -3)) (mv-adv-block k1))
                (zerop (mv-armor-hits k1)) (eq :stagger (hw-react (svref (mv-hits k1) 0)))))))
    (unless hr (check (>= (- (mv-s k1) (mv-s j1)) 7)))   ; (his ranged J1 S 14 / K1 S 16: §17.1's exception, B4c)
    (dolist (l (remove-if (lambda (l) (zerop (length (mv-hits (first l))))) links))
      (destructuring-bind (m n seq) l
        (let ((kk (eq (car (last seq)) :f)) (w (svref (mv-hits m) 0)))
          ;; every K at link 2 / 3 enters at S_eff 14; J links 2 / 3 -2 / -4, K links -3 / -20; enders stagger / crumple
          (when (and kk (> n 1)) (check (= (cond (hr (if (member (mv-name m) *hs-r-gather-links*) 21 15))   ; (B4c: 24 -/+ 3, enter 6)
                                                 ((and v8 (eq (second cf) :base)) 15) (t 14))
                                           (- (mv-s m) (mv-enter m)))))   ; (V8: *BR-K-LINK-SLOW* 1; R12: the awakened :KN 14)
          (when (> n 1)
            (check (= (mv-adv-block m) (+ a (cond ((and hs1 (member (mv-name m) '(:hs-j2k :hs-j3k))) *hs-leap-block*)   ; (S2's leap)
                                                  (v8 (cond ((and (= n 2) kk) -7) ((= n 2) 0) (kk -24) (t -2)))
                                                  (t (cond ((and (= n 2) kk) -3) ((= n 2) -2) (kk -20) (t -4)))))))
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
              (when (and nx (plusp (length (mv-hits nx))))
                (unless (and hr (> (length (mv-hits m)) 1))   ; (his gathered K2's two hits, its launch: his block below)
                  (check (< (hit-gap m nx) 0)))
                (let ((g (blocked-gap m nx)))
                  (cond ((eq c :f) (check (>= g (if v8 (if (eq (second cf) :base) 10 9) 11))))   ; (V8: the owl's J +1 over ±0: J -> K 10 f, base 12; R12: the awakened K links S_eff 14, 9 f)
                        (v8 (check (>= g 0)))   ; (V8: his J links block-safe up to ±0: no gap to Step into, by design)
                        ((or hr (and hs1 (intersection (list (mv-name m) (mv-name nx)) '(:hs-j2k :hs-j3k))))   ; (B4c: the gathered
                         (check (>= g (first *step-iframes*))))   ; J S 16 leave 14-15 f: his block; S2: the leap's 14 f, a Step /
                                                                  ; Hoho / his ranged K fits; after J2K's -6 his J1 punishes)
                        (t (check (and (>= g (first *step-iframes*)) (<= g (mv-s j1)))))))))))))
    ;; the switched link 2 (J2s, K2s) is a copy: the same data as J2 / K2 but its name
    (let ((j2 (kit-next k (mv-name j1) :q)) (j2s (kit-next k (mv-name k1) :q))
          (k2 (kit-next k (mv-name k1) :f)) (k2s (kit-next k (mv-name j1) :f)))
      (unless (or cup3 (eq (first cf) :hisagi))   ; (Hisagi: K2s MAKI is its own move, J2s the one-handed x0.8: DUEL_HISAGI §7.2)
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
                                  (= (+ (if v8 -2 -4) a) (mv-adv-block (first l)))
                                  (and hs1 (eq (mv-name (first l)) :hs-j3k))))   ; (S2's leap J3K: -6, his J1 punishes it, below)
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
              (= 60 (hit-damage 70 nil nil 4 nil)))))
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
(check (and (~= (combo-scale 1) 1.0) (~= (combo-scale 3) 1.0) (~= (combo-scale 4) 0.85) (~= (combo-scale 6) 0.55) (~= (combo-scale 7) 0.4)
            (~= (combo-scale 8) 0.25) (~= (combo-scale 9) 0.2) (~= (combo-scale 12) 0.2)))
;; ORANGE (the user 2026-10-24: 「橙色爆氣會將減免補正重置，且期間減免速度改成 10%、最低 50%」): -10 % a hit, 50 % floor
(check (and (~= (combo-scale 3 t) 1.0) (~= (combo-scale 4 t) 0.9) (~= (combo-scale 7 t) 0.6) (~= (combo-scale 8 t) 0.5)
            (~= (combo-scale 20 t) 0.5) (= 50 (hit-damage 100 nil nil 20 nil t))))
;; every SP ignores the combo scaling (the user 2026-10-24: 「所有角色的 SP 也都設置成不受傷害減免影響」): kind :sp, or the
;; form's SP1 / SP2 command of another kind (Hisagi's ranged KUBIKAKE, Lille's SHIN recall); never a J / K / L
(check (and (sp-move-p (kit :rukia :base) (find-move :ru-shirafune-s)) (sp-move-p (kit :ichigo :kessa) (find-move :ic-k-zanzo))
            (sp-move-p (kit :hisagi :bankai) (kit-command-move (kit :hisagi :bankai) :sp2))
            (sp-move-p (kit :barro :shin) (kit-command-move (kit :barro :shin) :sp2))
            (not (sp-move-p (kit :rukia :base) (find-move :ru-k1))) (not (sp-move-p (kit :hisagi :bankai) (find-move :hs-r-k1)))
            (not (sp-move-p (kit :rukia :base) (find-move :ru-byakurai)))))
;; Hisagi's Bankai ranged mode: a chain-tip hit ignores the combo scaling (the user 2026-10-25: 「修兵卍解遠距的尖端判定也設成
;; 不受連擊衰減的影響」): its :unscaled hook, after :dmg-mult read the tip (HS-TIP-NOW-P); no other kit has the hook
(check (and (eq 'hs-tip-now-p (kit-hook (kit :hisagi :bankai) :unscaled))
            (every (lambda (k) (or (eq (kit-character k) :hisagi) (null (kit-hook k :unscaled))))
                   (loop for al being the hash-values of *kits* append (mapcar #'cdr al)))))
;; Lille's awakened stance K > L wing spends (the user 2026-10-24: 「不受減免補正影響」): :unscaled on KL1-3 of EN and the
;; owl's stance, never on the base stance's
(check (and (every (lambda (n) (every (lambda (w) (member :unscaled (hw-flags w))) (mv-hits (find-move n))))
                   '(:br-e-kl1 :br-e-kl2 :br-e-kl3 :br-oe-kl1 :br-oe-kl2 :br-oe-kl3))
            (notany (lambda (n) (some (lambda (w) (member :unscaled (hw-flags w))) (mv-hits (find-move n))))
                    '(:br-s-kl1 :br-s-kl3 :br-e-k3 :br-e-jl1))))
(check (= (hit-damage 100 nil nil 1 nil) 100))
(check (= (hit-damage 100 '(:mult 1.3) nil 1 nil) 130))                 ; Hellfire
(check (= (hit-damage 100 '(:cornered 0.05 :cornered-max 0.25 :lost 2) nil 1 nil) 110))
(check (= (hit-damage 100 '(:cornered 0.05 :cornered-max 0.25 :lost 6) nil 1 nil) 125))   ; capped
(check (= (hit-damage 100 '(:mult 1.15 :cornered 0.05 :cornered-max 0.25 :lost 3) nil 5 t) 116)) ; x1.15x1.15x1.25x0.7 (hit 5: 0.8 until 2026-10-24's -15 %)
(check (= (hit-damage 100 nil nil 20 nil) 20))                          ; floor 20 % (40 % until 2026-10-24)
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
;; the dash-in (2026-10-24: 「O 到毀魂技的空檔延長」, gap 12 -> 24, the strike 41 f after the O's hit): every victim reels
;; until the strike has landed, locked (KIKON-LOCK-P): not red, U cancels the reel into a guard that blocks it; red,
;; nothing, and the strike can't be guarded (iframes still dodge it)
(check (and (= 24 *kikon-follow-gap*) (= 41 (+ *kikon-follow-stun* 1 *kikon-follow-gap*))
            (= (kikon-follow-wait 6) (- (+ *kikon-follow-stun* 1 *kikon-follow-gap*) 6))
            (= (kikon-follow-wait 99) 0) (~= *kikon-follow-kb* 2.5)))
;; the lock holds while the rusher dashes in (:follow) and until his follow-up strike connected or its active frames
;; are over; never off any other move or state
(check (and (kikon-lock-p :move t :follow nil 0 8 3) (kikon-lock-p :move t :main nil 10 8 3)
            (not (kikon-lock-p :move t :main :hit 10 8 3)) (not (kikon-lock-p :move t :main :block 9 8 3))
            (not (kikon-lock-p :move t :main nil 11 8 3)) (not (kikon-lock-p :move nil :follow nil 0 8 3))
            (not (kikon-lock-p :move nil :main nil 2 8 3)) (not (kikon-lock-p :idle t :follow nil 0 8 3))
            (not (kikon-lock-p :stun t :main nil 2 8 3))))
;; 2026-10-27 (DUEL_RUKIA_TYBW §17.14): a seal's red lock opens to the guard once the bind is over, never while it lasts
;; or while he is red; a guard lock and no lock stay as they are
(check (and (= 1 (kikon-lock-after-seal 2 0 nil)) (= 2 (kikon-lock-after-seal 2 5 nil)) (= 2 (kikon-lock-after-seal 2 0 t))
            (= 1 (kikon-lock-after-seal 1 0 nil)) (= 0 (kikon-lock-after-seal 0 0 nil))))
(check (and (null (kikon-follow-unguardable-p nil)) (kikon-follow-unguardable-p t)))
(check (and (eq (resolve-contact :guard :unguardable (kikon-follow-unguardable-p nil)) :blocked)     ; not red: blocked
            (eq (resolve-contact :guard :unguardable (kikon-follow-unguardable-p t)) :hit)           ; red: the Kikon
            (eq (resolve-contact :stance :unguardable (kikon-follow-unguardable-p t)) :hit)
            (eq (resolve-contact :parry :unguardable (kikon-follow-unguardable-p t)) :hit)
            (null (resolve-contact :invuln :unguardable (kikon-follow-unguardable-p t)))))
(dolist (cf *forms*)
  (let ((s (mv-s (kit-command-move (apply #'kit cf) :kikon))))
    (check (= (kikon-follow-stun nil s) (kikon-follow-stun t s)))                                   ; (2026-10-24: both reel)
    (check (> (kikon-follow-stun t s) (+ (kikon-follow-wait s) s)))))                              ; still reeling as it lands
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
(check (and (~= (reiatsu-gain 100) 15.0) (~= (reiatsu-gain 0 60) 3.0)))   ; SPs only: 3 / s
;; a hit's Reiatsu by its move's kind x the combo bonus, not by its damage (the user 2026-10-26: 「不再按傷害，改成依據每招式各自的
;; 基礎值 * combo 數加成」; the taken side 「受傷值 x combo 加成」; +10 % a hit, at most x2)
(check (and (~= 1.0 (combo-gain-mult 1)) (~= 1.0 (combo-gain-mult 0)) (~= 1.1 (combo-gain-mult 2)) (~= 1.5 (combo-gain-mult 6))
            (~= 2.0 (combo-gain-mult 11)) (~= 2.0 (combo-gain-mult 30))
            (equal '(3.0 5.0 4.0 4.0 7.0 14.0) (mapcar #'hit-reiatsu-base '(:quick :flash :sig :sp :kikon :breaker)))
            (~= *reiatsu-kind-other* (hit-reiatsu-base :stance)) (~= 9.0 (hit-reiatsu-base :quick 9.0))))
(multiple-value-bind (r fs aw) (hit-gains 500 0 nil 1.0 3.0 1)          ; J1, 500 damage or 5: the same 3
  (multiple-value-bind (r2) (hit-gains 5 0 nil 1.0 3.0 1)
    (multiple-value-bind (r6) (hit-gains 5 0 nil 1.0 3.0 6)              ; the combo's 6th hit: x1.5
      (multiple-value-bind (rt ft) (hit-gains 0 100 nil 1.0 0 6)         ; taking 100 at its 6th hit: 15 x 1.5, flash-step 4.5 x 1.5
        (multiple-value-bind (ro) (hit-gains 5 0 nil *orange-gain* 3.0 1)   ; ORANGE x its gain
          (check (and (~= r 3.0) (~= r2 3.0) (~= r6 4.5) (~= rt 22.5) (~= ft 6.75) (zerop fs) (plusp aw) (~= ro (* 3.0 *orange-gain*)))))))))
;; KOSEI by its move's kind (x the combo bonus at the call, x m), not the guard value (2026-10-26: 「攻勢整個改成基礎值×combo×防禦量表越空乘越多」)
(check (and (equal '(9.0 16.0 36.0 27.0 20.0 0.0) (mapcar #'kosei-base '(:quick :flash :sig :sp :kikon :breaker)))
            (~= *kosei-kind-other* (kosei-base :stance)) (~= 5.0 (kosei-base :quick 5.0))
            (multiple-value-bind (r fs m) (kosei-gain (* (kosei-base :flash) (combo-gain-mult 3)) 0.0)   ; K, 3rd hit, empty gauge
              (and (~= r (* 0.2 16 1.2 3)) (~= fs (* 0.1 16 1.2 3)) (~= m 3.0)))))
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
;; the guard cancel (the user, 2026-10-01): after its own hit, over the last half of the recovery; the last three
;; quarters since 2026-10-23 (「將防禦取消提早」; K2 21/4/24: f31-48)
(check (and (= 0.75 *guard-cancel*) (not (guard-cancel-open-p 30 21 4 24 :hit)) (guard-cancel-open-p 31 21 4 24 :hit)
            (guard-cancel-open-p 48 21 4 24 :hit) (not (guard-cancel-open-p 49 21 4 24 :hit))
            (not (guard-cancel-open-p 40 21 4 24 :block)) (not (guard-cancel-open-p 40 21 4 24 nil))))
;; the arena's room for a push (RAY-ROOM): from the centre 5 to an r 5 edge; at 4 m out along +x, 1 left that way and 9 back
(check (and (< (abs (- (ray-room 0.0 0.0 1.0 0.0 5.0) 5.0)) 1e-4) (< (abs (- (ray-room 4.0 0.0 1.0 0.0 5.0) 1.0)) 1e-4)
            (< (abs (- (ray-room 4.0 0.0 -1.0 0.0 5.0) 9.0)) 1e-4) (= 0.0 (ray-room 5.0 0.0 1.0 0.0 5.0))))
;; a J (QUICK) may guard-cancel on block too (the user 2026-10-02): J1 9/3/12 opens f18-23; never on a whiff
;; 2026-10-23 (「拉長打空與被防禦的收招，但收招可以用防禦取消」; 「重度」, then 「調回中間」; 「將防禦取消提早」): a J / K / O blocked
;; recovers R + *BLOCK-ADD*, whiffed its whiff + *WHIFF-ADD*; both may guard-cancel over the last three quarters (J S9 A3
;; R12: blocked 16 from f16, whiffed 20 + 8 from f19)
(check (and (equal *block-add* '(:quick 4 :flash 6 :kikon 6)) (equal *whiff-add* '(:quick 8 :flash 8 :kikon 8))))
(check (and (guard-cancel-open-p 16 9 3 12 :block :quick) (not (guard-cancel-open-p 15 9 3 12 :block :quick))
            (guard-cancel-open-p 27 9 3 12 :block :quick) (not (guard-cancel-open-p 28 9 3 12 :block :quick))
            (guard-cancel-open-p 19 9 3 12 nil :quick 20) (not (guard-cancel-open-p 18 9 3 12 nil :quick 20))
            (guard-cancel-open-p 15 9 3 12 :hit :quick) (not (guard-cancel-open-p 14 9 3 12 :hit :quick))
            (not (guard-cancel-open-p 40 21 4 24 nil :sig 30)) (not (guard-cancel-open-p 40 21 4 24 :block :sp))))
(check (and (= (recovery-frames 12 :block nil :quick) 16) (= (recovery-frames 20 :block nil :flash) 26)
            (= (recovery-frames 24 :block nil :kikon) 30) (= (recovery-frames 12 :hit nil :quick) 12)
            (= (recovery-frames 12 nil 20 :quick) 28) (= (recovery-frames 20 nil 32 :flash) 40) (= (recovery-frames 30 nil 30 :kikon) 38)
            (= (recovery-frames 24 :block nil :sp) 24) (= (recovery-frames 24 nil 30 :sig) 30)))
(check (= (move-end-frame 9 3 12 20 :block nil :quick) 28))
(check (and (= (chain-startup-cut 10 0) 4) (= (chain-startup-cut 20 0) 8) (= (chain-startup-cut 2 0) 0) (= (chain-startup-cut 1 0) 0)
            (= (chain-startup-cut 3 0) 1) (= (chain-startup-cut 12 2) 4) (= *chain-window* 12)))
(check (and (~= (burst-gain-mult :orange) 1.5) (~= (burst-gain-mult :white) 1.0) (~= (burst-gain-mult nil) 1.0)))
(check (and (~= (nth-value 0 (hit-gains 100 0 nil 1.5 8.0)) 12.0) (~= (nth-value 2 (hit-gains 100 0 nil 1.5)) 5.25)   ; x1.5 dealt
            (~= (nth-value 0 (hit-gains 0 100 nil 1.5)) 15.0) (~= (nth-value 0 (hit-gains 100 0 nil 1.0 8.0)) 8.0)))    ; taken untouched
;; the Kikon refund: a flash-step bar (35) and a Reiatsu bar, clamped
(check (and (equal (multiple-value-list (kikon-refund 10.0 50.0)) '(45.0 150.0))
            (equal (multiple-value-list (kikon-refund 90.0 250.0)) '(100.0 300.0))))
;; the flash-step gauge (design v3 G.1): Hoho 30, Burst 70, no Reiatsu; 3 / s after 60 f; +0.03 per damage taken
(check (and (= *fs-hoho* 30) (= *fs-burst* 70) (not (boundp '*fs-refund*)) (~= *fs-taken* 0.045) (= *fs-max* 100)))
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
                      (every (lambda (w) (and (or (<= (mv-s m) (hw-from w)) (hw-seg w))   ; (a :seg-fn hit may land
                                              (< (hw-from w) (hw-to w))                    ;  before S: KOJO's yank, §25.7)
                                              (<= (hw-to w) (+ (mv-s m) (mv-a m))) (or (hw-vols w) (hw-seg w))))
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
            (~= (mv-clip-speed (mv :yamamoto :bankai-east :ya-tenchi)) 1.0)))    ; clips reach their hit pose on frame S
                                                                                 ; (TENCHI's own clip since DUEL_YAMA_TYBW §3.2)
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
  '(:ya-stance :ya-q1 :ya-q2 :ya-f1 :ya-f2 :ya-f3 :ya-sig :ya-shiranui :ya-shiranui-throw :ya-taimatsu
    :ya-nadegiri :ya-breaker :ya-ikkotsu :ya-intro :ya-win :ya-hellfire :ya-bankai :ya-kyoku
    :ya-kaka :sh-run :ya-enjo :ke-n-leap ; the O modules (TENCHI runs in :sh-run, CHARGE in :ke-charge)
    :ya-shonetsu :ya-w-parry :ya-w-counter   ; the Bankai stances
    :ya-e-stance :ya-e-q1 :ya-e-q2 :ya-e-q3 :ya-e-f1 :ya-e-f2 :ya-e-kyokko :ya-e-tenchi   ; East's own (DUEL_YAMA_TYBW §3.2)
    :ya-tsuka :ya-e-drop :ke-kick :ke-r-kote :ke-r-tsuki   ; the strings' new clips (DUEL_STRINGS §3)
    :ke-stance :ke-q1 :ke-q2 :ke-q3 :ke-f1 :ke-f2 :ke-stance-hold :ke-stance-cut :ke-buttagiru :ke-charge
    :ke-flurry :ke-breaker :ke-shoulder :ke-intro :ke-win :ke-release :ke-nome :ke-meteor
    :ke-n-stance
    :sh-skate-b :sh-slide-r :sh-slide-l :ke-run :ke-skate-b :ke-slide-r :ke-slide-l   ; the runs (facing the opponent)
    :ke-r-stance :ke-drink     ; the cups
    :ke-r-q1 :ke-r-q3 :ke-r-f1 :ke-r-f2 :ke-n-f1     ; RYOTE's kendo set and KUKAN-GIRI (their own clips since Phase 5)
    :ke-b-stance :ke-b-fist :ke-b-bite                ; the Bankai (docs/duel/DUEL_KEN_BANKAI.md §12)
    :ke-b-hook :ic-cross-j :ic-k-jab :ic-k-wrap-j     ; the J cut's close J links (DUEL_STRINGS §13)
    :ke-b-leap :ke-b-run :ke-b-skate-b :ke-b-slide-r :ke-b-slide-l   ; its feral pass (2026-09-28; also 片腕)
    :ru-intro :ru-win :ru-q2 :ru-spin :ru-thrust :ru-drop :ru-stab :ru-hakuren
    :ru-breaker :ru-hainawa :ru-palm :ru-flower   ; Rukia (the shared moves' clips a form's table still names unmapped;
    ;; every form plays its own since -273's, DUEL_RUKIA_TYBW §13.4: :ru-q1 / :ru-ring are Senjumaru's Divine Soldier's
    ;; (*SHINPEI-COMBO*), :ru-hakka the 白霞罸 cinematic's, the :ru-shirafune / :ru-cold-stance clips are gone (the moves'
    ;; names stay, every form maps them))
    :ru-s-stance :ru-s-walk-f :ru-s-walk-b :ru-s-strafe-r :ru-s-strafe-l :ru-s-run :ru-s-j1 :ru-s-j2 :ru-s-j3   ; the Shikai's
    :ru-s-k1 :ru-s-k2 :ru-s-k3 :ru-s-shirafune :ru-s-enbu-run :ru-s-enbu :ru-s-breaker :ru-s-hainawa   ; own (§13.3; the old
                                                                        ;  :ru-stance clip retired with zero's own, §13.4)
    :ru-s-shimochiri :ru-s-setsuen :ru-s-sojin :ru-s-hyoreki :ru-s-tsurara :ru-s-hakuren   ; the new Shikai's bursts and kido
    :ru-s-byakurai :ru-s-tsukishiro :ru-s-kido :ru-s-sokatsui :ru-s-rikujo :ru-s-rikujo-cast   ; (DUEL_RUKIA_TYBW §13.3)
    :ru-18-stance :ru-18-walk-f :ru-18-walk-b :ru-18-strafe-r :ru-18-strafe-l :ru-18-run :ru-18-j1 :ru-18-j2 :ru-18-j3   ; -18's own
    :ru-18-k1 :ru-18-k2 :ru-18-k3 :ru-18-shimobashira :ru-18-hakuren-hold :ru-18-hakuren :ru-18-shirafune   ; (§13.4)
    :ru-18-hakka :ru-18-hainawa
    :ru-50-stance :ru-50-walk-f :ru-50-walk-b :ru-50-strafe-r :ru-50-strafe-l :ru-50-run :ru-50-j1 :ru-50-j2 :ru-50-j3   ; -50's own
    :ru-50-k1 :ru-50-k2 :ru-50-k3 :ru-50-hyoshin :ru-50-hakuren-hold :ru-50-hakuren :ru-50-shirafune   ; (§13.4)
    :ru-50-hakka :ru-50-hainawa
    :ru-0-stance :ru-0-j1 :ru-0-j2 :ru-0-j3 :ru-0-k1 :ru-0-k2 :ru-0-k3 :ru-0-reido :ru-0-hakuren :ru-0-shirafune   ; -273's own
    :ru-0-hakka                                                                                                 ; (§13.4)
    :ic-stance :ic-intro :ic-win :ic-q1 :ic-q2 :ic-spin :ic-f1 :ic-f2 :ic-drop :ic-cross :ic-getsuga :ic-juji :ic-breaker
    :ic-mine :ic-k-stance :ic-k-back :ic-k-parry :ic-k-yank :ic-k-zanzo   ; Ichigo (DUEL_ICHIGO §10, v2)
    :ic-tsuki :ic-rangetsu :ic-tsuki-otoshi :ic-soga :ic-juji-x   ; (SOGA's and the JUJI rush's own, DUEL_ICHIGO_TYBW §3.2)
    :ic-k-f1 :ic-k-f2 :ic-k-f3 :ic-k-gaeshi :ic-k-uchi   ; KESSA's own K, counter and O strike (DUEL_ICHIGO_TYBW §3.2)
    :sj-stance :sj-q1 :sj-q2 :sj-spin :sj-f1 :sj-f2 :sj-drop :sj-yank :sj-summon :sj-kasa :sj-breaker :sj-saidan :sj-intro
    :sj-win :sj-loom-stance :sj-weave :sj-unravel :sj-tanmono :sj-makitori :sj-snip   ; Senjumaru (:sj-awaken is the cine's)
    :lb-stance :lb-intro :lb-win :lb-q1 :lb-q2 :lb-aim :lb-fire :lb-sanren :lb-hiren :lb-breaker :lb-butt   ; Lille's shared
    :lb-w-stance :lb-w-q1 :lb-w-q2 :lb-w-q3 :lb-w-f1 :lb-w-f2 :lb-w-f3 :lb-w-sanren :lb-w-kikon :lb-w-kikon-fire   ;  art (the
    :lb-w-nijushi :lb-w-breaker :lb-w-ram :lb-o-stance :lb-o-q1 :lb-o-q2 :lb-o-q3 :lb-o-f1 :lb-o-f2 :lb-o-f3 :lb-o-chop   ;  old
    :lb-o-trompete :lb-o-breaker :lb-o-stamp :lb-kamae :lb-k-dash :lb-oe-stance   ;  Lille's, DUEL_LILLE §12, §22, §23)
    :br-f1 :br-f2 :br-f3                          ; the base form's attack-state K string (the user 2026-10-12: bold)
    :br-sk-l1 :br-sk-l1s :br-sk-lc :br-jab :br-sk-j1 :br-sk-j2 :br-sk-j3 :br-sk-k1 :br-sk-k2 :br-sk-k3   ; the base stance's strings
    :br-sk-jl1 :br-sk-jl2 :br-sk-jl3 :br-sk-kl1 :br-sk-kl2 :br-sk-kl3   ; and its follow-ups (DUEL_LILLE_V3 §8.3, §8.5; :lb-snap unused again)
    :br-en-l1 :br-en-j1 :br-en-j2 :br-en-j3 :br-en-k1 :br-en-k2 :br-en-k3   ; the awakened stance EN's openers,
    :br-en-lc :br-oen-lc                          ; (R10, DUEL_LILLE_V3 §15: the L charge's pose while held)
    :br-oen-l1 :br-oen-j1 :br-oen-j2 :br-oen-j3 :br-oen-k1 :br-oen-k2 :br-oen-k3   ; JILLIEL's and the owl's (§8)
    :br-e-jf1 :br-e-jf2 :br-e-jf3 :br-e-kf1 :br-e-kf2 :br-e-kf3 :br-oe-jf1 :br-oe-jf2 :br-oe-jf3 :br-oe-kf1 :br-oe-kf2 :br-oe-kf3
                                                  ; their L L follow-ups, by route (§8.5; V8's swings :br-e-swing / :br-oe-swing spare again)
    :br-recall :br-rc0 :br-rc1 :br-rc2 :br-rc3 :br-rc4 :br-to-en   ; Lille II's own (the art batch, DUEL_LILLE_V2 §12) ...
    :br-o-recall :br-o-rc0 :br-o-rc1 :br-o-rc2 :br-o-rc3 :br-o-rc4 :br-o-to-en   ; ... and the owl's (the backstep gone, v3 R3)
    :br-w-guard :br-w-guard-hit :br-o-guard :br-o-guard-hit :br-oe-guard :br-oe-guard-hit   ; his wing wall (the awakened guard)
    :ke-k-q1 :ke-k-q2 :ke-k-f1 :ke-k-f2 :ke-k-spin :ke-k-meteor   ; Kenpachi's cup 1 and cup 3 sets (DUEL_KEN_REWORK §6.2)
    :ke-x-stance :ke-x-q1 :ke-x-kote :ke-x-q3 :ke-x-f1 :ke-x-tsuki :ke-x-f2 :ke-x-meteor :ke-x-drink
    :ke-b-q1 :ke-b-q2 :ke-b-f1 :ke-b-f2 :ke-b-f3 :ke-b-split :ke-b-cut   ; the Bankai's own (§8)
    :ke-a-stance :ke-a-q1 :ke-a-q2 :ke-a-f1 :ke-a-f2 :ke-a-spin :ke-a-haymaker :ke-a-stomp :ke-a-flurry   ; KATAUDE's (§8)
    :hs-intro :hs-win                                                  ; Hisagi's B2a intro / win (the Bankai's forms)
    :hs-s-stance :hs-s-intro :hs-s-win :hs-s-walk-f :hs-s-walk-b :hs-s-strafe-r :hs-s-strafe-l   ; the Shikai's own
    :hs-s-run :hs-s-skate-b :hs-s-slide-r :hs-s-slide-l :hs-s-sen :hs-s-kaeshi :hs-s-rin :hs-s-kaeshi-1h :hs-s-rin-1h   ; (§21.4)
    :hs-s-maki :hs-s-modoshi :hs-s-kaza :hs-s-raiden :hs-s-shibari   ; (S1, §23.3: :hs-s-kari no move's since; MAKI dormant;
    :hs-s-nagi :hs-s-noko :hs-s-tsui :hs-s-tobi-kaeshi :hs-s-tobi-rin   ;  A1, §24.1: the K string's and the leap J's own, so
                                                                        ;  :hs-s-nage, :hs-s-hiki, :hs-s-hodoki no move's)
    :hs-s-breaker :hs-s-kubikake :hs-s-kari-aim :hs-s-kari-o
    :hs-k-stance :hs-k-walk-f :hs-k-walk-b :hs-k-strafe-r :hs-k-strafe-l :hs-k-run :hs-k-skate-b :hs-k-slide-r   ; the Bankai's
    :hs-k-slide-l :hs-k-saben :hs-k-kaeshi :hs-k-sensa :hs-k-saharai                                         ;  own (§21.8):
    :hs-k-raiden :hs-k-ame :hs-k-kosa-aim :hs-k-kosa :hs-k-breaker :hs-k-hammer :hs-k-kubikake   ;  the ranged mode,
    :hs-kb-gen :hs-kb-kaeshi :hs-kb-sogen :hs-kb-hikigiri :hs-kb-makigiri :hs-kb-shibori :hs-kb-kaibaku    ;  the bind
    :hs-kb-raiden :hs-kb-kojo :hs-kb-koshu-run :hs-kb-koshu :hs-kb-unwind
    :hs-k-hosoku :hs-k-s-k2 :hs-k-s-k3 :hs-k-g-k2 :hs-k-g-j2 :hs-k-g-k3 :hs-k-g-j3   ; the ranged route links' (A2, §24.2)
    :hs-kb-stance :hs-kb-walk-f :hs-kb-walk-b :hs-kb-strafe-r :hs-kb-strafe-l))     ; the bind's stance and walk (A2)
;; (Jilliel's SPs and Kikon, decision 56, DUEL_LILLE §23.37: :lb-w-sanren is KIN's SANREN through his :clip-map, :lb-e-sanren
;; EN's own, :lb-w-kikon / :lb-w-kikon-fire the Kikon in play; :lb-w-aim and :lb-w-fire are gone)
;; (the Kikon cinematics' own clips, :ya-kikon :ya-tenchi :ke-kikon :ke-kikon-n, are played by their
;; DEFCINEs, which the host stubs; KESSA's clones play :ic-k-cut / :ic-k-wrap, ICHIGO-CLONE-STEP)
(let ((used (remove-duplicates (append (loop for cf in *forms* append (kit-clips (apply #'kit cf)))
                                        ;; (moves started outside every kit's tables: Lille II's base snipe's level 2 / 3
                                        ;;  copies, BR-S-SNIPE-RELEASE; R16, DUEL_LILLE_V3 §20: only they play :br-sk-l1)
                                        ;;  Hisagi's MODOSHI, started by his :command hook while the sickle is out)
                                        (remove nil (loop for m in '(:br-s-l1-2 :br-s-l1-3 :hs-modoshi :hs-k2s :hs-r-kubikake :hs-b-unwind :hs-r-sp2c
                                                                       :hs-b-sp1)   ; (B4c: no kit's since, its strip 83524)
                                                          collect (mv-clip-2 (find-move m))   ; (his Shikai's MODOSHI mapped)
                                                          collect (kit-move-clip (kit :hisagi :base) (mv-clip (find-move m)))))))))
  (let ((extra (set-difference used *clips-5*)) (unused (set-difference *clips-5* used)))
    (when (or extra unused) (format t "  clips not in §5: ~s, §5 clips unused: ~s~%" extra unused))
    (check (and (null extra) (null unused)))))
;; phase 2: art names, roster, form looks, the flurry, hazard hits
(check (equal (mapcar #'kit-weapon (mapcar (lambda (cf) (apply #'kit cf)) *forms*))
              '(:ryujin-jakka :ryujin-jakka :zanka :zanka :ken-katana :nozarashi :nozarashi :nozarashi :ke-broken nil
                :sode-no-shirayuki :sode-no-shirayuki :ru-rime :ru-ice :zangetsu-long :tensa
                :shigarami :shigarami :shigarami :shigarami :shigarami :shigarami :shigarami
                :diagramm nil nil nil nil :kazeshini :kazeshini :kazeshini)))     ; (+ Lille II's five forms, DUEL_LILLE_V3: MUJITTAI gone; Hisagi)
(check (equal *roster* '(:yamamoto :kenpachi :rukia :ichigo :senjumaru :lille :barro :hisagi)))   ; index 5 reserved (the old Lille, removed 2026-10-13), 6 Lille, 7 Hisagi
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

