;;;; lille.lisp — LILLE BARRO (Schutzstaffel, TYBW), docs/duel/DUEL_LILLE.md: his moves (DEFMOVE) and his four forms
;;;; (DEFKIT): :base 万物貫通 THE X-AXIS (a sniper: L held aims Diagramm along a line that locks, then fires the whole arena
;;;; long through guard; the left eye's three openings on U), the awakening 神の裁き JILLIEL (:jilliel, U switches to the
;;;; intangible stance :jilliel-mujittai, Yamamoto's West with the :intangible flag) and the second awakening, the owl
;;;; 真の姿 (:shin, P after a beheading in Jilliel: Kenpachi's Bankai path with the kit's :bankai-ok). Everything of his is
;;;; here (the user's code layout, 2026-09-28): the knobs, the pure rules (host-tested), the kits, his per-side state (reset
;;;; with every match), the kit hooks (kit.lisp KIT-HOOK: :tick :ok :hit :struck :settled :bankai-ok :draw), his hazards'
;;;; hook, the CPU tables (basic: batch 1), the debug range 79000-79999, the pacing log and placeholder cinematics (batch
;;;; 3). The looks, bodies, clips and props are lille-art.lisp's. Plain CL above the hooks: the host rules test loads it.
(in-package :duel)

;;; ================================================================ knobs (docs/duel/DUEL_LILLE.md §4-§6, §13)
(defparameter *walk-lille* 3.4 "Walk m/s, the base form (design 2026-10-06).")
(defparameter *run-lille* 8.5 "Run m/s, the base form (design 2026-10-06).")
(defparameter *lille-mult* 1.0 "Damage dealt x, the base form (design 2026-10-06; §13: 1.0 -> 1.3 if he wins too little).")
(defparameter *lille-taken* 1.0 "Damage taken x, the base form (design 2026-10-06).")
(defparameter *walk-jilliel* 3.0 "Walk m/s, JILLIEL (design 2026-10-06, §5.1).")
(defparameter *run-jilliel* 8.0 "Run m/s, JILLIEL (design 2026-10-06).")
(defparameter *jilliel-mult* 1.0 "Damage dealt x, JILLIEL (design 2026-10-06).")
(defparameter *jilliel-taken* 1.1 "Damage taken x, JILLIEL: when he is solid, he is fragile (design 2026-10-06, §5.6).")
(defparameter *jilliel-gg-regen* 0.36
  "JILLIEL's guard gauge refill x (outside the stance; the stance never refills): 0.36 x 5.5 / s = 2.0 / s (design
2026-10-06; the user's decision 14, 「正常狀態防禦槽恢復量大減」).")
(defparameter *walk-shin* 4.0 "Walk m/s, the owl (design 2026-10-06, §6.2).")
(defparameter *run-shin* 9.0 "Run m/s, the owl (design 2026-10-06).")
(defparameter *shin-mult* 1.2 "Damage dealt x, the owl (design 2026-10-06; decision 15: no running cost).")
(defparameter *shin-taken* 1.0 "Damage taken x, the owl (design 2026-10-06).")

;; the left eye (§4.1; decisions 7, 13)
(defparameter *lb-eyes* 3 "The eye's pips: full at the start, never refilled in the match (design 2026-10-06; decision 7).")
(defparameter *lb-eye-rest* 10
  "A U press opens the eye only after U was up this many frames (a deliberate tap; design 2026-10-06, decision 13).")
(defparameter *lb-eye-lead* 8
  "... while an opponent hit window is active now or within this many frames and touches him (the perfect-Hoho test with
a shorter look-ahead; design 2026-10-06, decision 13).")
(defparameter *lb-eye-phase* 16 "Frames he is intangible after the eye opens (FIGHTER-INVULN; design 2026-10-06).")

;; the X-axis shot and the lock (§4.3; decisions 10, 12)
(defparameter *lb-aim-track* 60.0 "Degrees / s he turns while he aims, until the lock (design 2026-10-06; the Signature rate).")
(defparameter *lb-lock* 34 "The aim's lock frame (move frame): the line stops turning (design 2026-10-06; decision 12).")
(defparameter *lb-lock-min* 10 "The shot fires at least this many frames after the lock (design 2026-10-06; decision 12).")
(defparameter *lb-x-delay* 4 "... and this many after L is released (design 2026-10-06).")
(defparameter *lb-aim-max* 64 "The shot fires by itself on this move frame (design 2026-10-06).")
(defparameter *lb-aim-cancel* 10 "From this move frame until the lock, Step / Hoho / U cancel the aim (design 2026-10-06).")
(defparameter *lb-x-near* 4.0 "Distance damage: the minimum at or under this many metres (design 2026-10-06; decision 10)...")
(defparameter *lb-x-far* 20.0 "... the maximum at or beyond this many (design 2026-10-06).")
(defparameter *lb-x-min* 40 "The shot's damage at *LB-X-NEAR* (design 2026-10-06).")
(defparameter *lb-x-max* 120 "The shot's damage at *LB-X-FAR* (design 2026-10-06; §13: 120 -> 100 if he wins too much).")
(defparameter *lb-x-chip* 0.15 "Through guard: the fraction of a blocked X-axis hit that goes through as chip (design 2026-10-06; decision 2).")
(defparameter *lb-x-guard* 30 "Through guard: the guard gauge a blocked shot drains (4 crush a full gauge; design 2026-10-06; decision 2).")
(defparameter *lb-far-kb* 12.0 "A shot that hits from this many metres knocks back 2.0 m, not 1.0 (design 2026-10-06).")
(defparameter *lb-volley-lock* 24 "The wing volley's lock frame (design 2026-10-06, §5.4).")
(defparameter *volley-spread* 6.0 "Degrees between the volley's five lines (design 2026-10-06; §13: 6 -> 5 if awakening is a trap).")

;; the owl (§6)
(defparameter *lb-revive-konpaku* 4
  "BEHEADED: a Kikon or Soul Break that leaves him in Jilliel with 1 to this many Konpaku (design 2026-10-06; decision 8).")
(defparameter *lb-sabaki-from* 1.0 "SABAKI NO KOMYO's ground line starts this many metres ahead (design 2026-10-06)...")
(defparameter *lb-sabaki-to* 18.0 "... and runs to this many (design 2026-10-06).")
(defparameter *lb-sabaki-speed* 40.0 "... erupting outward at this many m/s (design 2026-10-06).")
(defparameter *lb-sabaki-life* 24 "Frames each point of the line burns (0.4 s; design 2026-10-06).")
(defparameter *lb-sabaki-width* 0.6 "The line's width, metres (design 2026-10-06).")
(defparameter *lb-misuji-fan* 20.0 "MISUJI's lines: -this, 0, +this degrees (design 2026-10-06).")
(defparameter *lb-reflect-hoho* '(48 59)
  "Trompete's reflect by a perfect Hoho started on these Trompete frames (design 2026-10-06, decision 9; f60 can't dodge
the beam's first frame: Built, deviations).")
(defparameter *lb-reflect-guard* '(2 10)
  "... or by a guard whose FIGHTER-GUARD-T at the end of Trompete's f59 is in this range (a press on f50-f58; design
2026-10-06, decision 9).")
(defparameter *lb-reflect-k* 0.5 "The reflect: he takes this share of Trompete's damage, x his form's damage (design 2026-10-06).")
(defparameter *lb-reflect-stun* 60 "... and staggers this many frames (design 2026-10-06).")

;;; ================================================================ rules (pure: host-tested)
(defun lb-x-damage (d)
  "The X-axis shot's damage at D metres (centre to centre at the fire frame), before the form's multiplier: *LB-X-MIN*
at <= *LB-X-NEAR*, rising linearly to *LB-X-MAX* at >= *LB-X-FAR* (decision 10)."
  (let ((k (max 0.0 (min 1.0 (/ (- d *lb-x-near*) (- *lb-x-far* *lb-x-near*))))))
    (round (+ *lb-x-min* (* k (- *lb-x-max* *lb-x-min*))))))
(defun lb-x-bonus (d) "What the shot's hit window (*LB-X-MIN*) gets added at D metres (FIGHTER-DMG-BONUS)." (- (lb-x-damage d) *lb-x-min*))
(defun lb-auto-fire (lock)
  "The frame an aimed move locking on LOCK fires by itself: *LB-AIM-MAX* for the shot (lock f34: f64), as much earlier as
its lock is (the volley, lock f24: f54)."
  (- *lb-aim-max* (- *lb-lock* lock)))
(defun lb-fire-frame (release &optional (lock *lb-lock*))
  "The move frame the aimed shot fires on when L was released on move frame RELEASE (NIL: held): max(release +
*LB-X-DELAY*, lock + *LB-LOCK-MIN*), at most the auto-fire (LB-AUTO-FIRE)."
  (let ((auto (lb-auto-fire lock)))
    (min auto (max (+ (or release auto) *lb-x-delay*) (+ lock *lb-lock-min*)))))
(defun lb-aim-hold (lock)
  "The :hold (lo hi) of an aimed move locking on LOCK whose main phase fires *LB-X-DELAY* after it starts: the hold ends at
max(release, lo) or hi, so it fires on LB-FIRE-FRAME."
  (list (- (+ lock *lb-lock-min*) *lb-x-delay*) (- (lb-auto-fire lock) *lb-x-delay*)))
(defun lb-tracking-p (hold lock) "Does the aim still turn on hold frame HOLD (until the lock)?" (< hold lock))
(defun lb-aim-cancel-p (hold lock) "May Step / Hoho / U cancel the aim on hold frame HOLD (from *LB-AIM-CANCEL* until the lock)?"
  (and (>= hold *lb-aim-cancel*) (< hold lock)))
(defun lb-eye-window-p (sf from to)
  "An opponent hit window [FROM, TO) of his move at frame SF is active, or becomes active within *LB-EYE-LEAD* frames
(THREAT-WINDOW-P's eye version)."
  (and (< sf to) (<= (- from sf) *lb-eye-lead*)))
(defun lb-eye-state-p (state sf)
  "May a U tap open the eye from STATE (SF its frame): idle, walk, guard, run and a Step's recovery; never a move, a reaction
or blockstun."
  (or (member state '(:idle :guard :run))
      (and (eq state :step) (> sf (second *step-iframes*)))))
(defun lb-eye-tap-p (rest pips state sf)
  "Does a U press after U rested REST frames open the eye (PIPS left, STATE / SF)? (The threat is the shell's test.)"
  (and (>= rest *lb-eye-rest*) (plusp pips) (lb-eye-state-p state sf) t))
(defun lb-eye-open (pips awakened)
  "One opening of PIPS: values the pips left and whether it fills the awakening gauge (the third opening, unless
AWAKENED already; decision 7)."
  (let ((n (max 0 (1- pips)))) (values n (and (zerop n) (plusp pips) (not awakened)))))
(defun lb-beheaded-p (form left)
  "Is he BEHEADED by a Kikon / Soul Break that left him in FORM with LEFT Konpaku (Jilliel, 1-*LB-REVIVE-KONPAKU*)?"
  (and (member form '(:jilliel :jilliel-mujittai)) (<= 1 left *lb-revive-konpaku*) t))
(defun lb-reflect-hoho-p (start)
  "Is a perfect Hoho started on Trompete frame START a reflect (*LB-REFLECT-HOHO*)?"
  (<= (first *lb-reflect-hoho*) start (second *lb-reflect-hoho*)))
(defun lb-reflect-guard-p (guard-t)
  "Is a guard with FIGHTER-GUARD-T = GUARD-T at the end of Trompete's f59 a reflect (*LB-REFLECT-GUARD*: a press f50-f58)?"
  (<= (first *lb-reflect-guard*) guard-t (second *lb-reflect-guard*)))
(defun lb-reflect-damage (dmg mult) "What a reflected Trompete of DMG deals him, MULT his form's damage x." (round (* *lb-reflect-k* dmg mult)))
(defun lb-sabaki-span (age)
  "The burning part of a SABAKI line AGE frames after it erupted: values from to (metres ahead; FROM = TO: none yet)."
  (let* ((front (min *lb-sabaki-to* (+ *lb-sabaki-from* (* *lb-sabaki-speed* (/ age 60.0)))))
         (tail (max *lb-sabaki-from* (+ *lb-sabaki-from* (* *lb-sabaki-speed* (/ (- age *lb-sabaki-life*) 60.0))))))
    (values (min tail front) front)))
(defun lb-sabaki-frames ()
  "A SABAKI line's life: its eruption to *LB-SABAKI-TO* and the last point's burn."
  (+ (ceiling (* 60 (- *lb-sabaki-to* *lb-sabaki-from*)) *lb-sabaki-speed*) *lb-sabaki-life*))

;;; ================================================================ base 万物貫通 THE X-AXIS (§4)
;;; the J / K strings (docs/duel/DUEL_STRINGS.md §2.1 budget; the lightest in the roster): the plank (the butt) swung at
;;; close range for J1 / J2, the muzzle cross for J3 and every K. Every reach is where the art strikes (lille-art.lisp; the
;;; host FK test: the plank at a negative weapon-length point, the muzzle at the weapon tip)
(defmove :lb-j1 :kind :quick :clip :lb-q1 :startup 8 :active 3 :recovery 12 :dmg 22 :adv-block -2
  :reach 1.45 :arc 100 :on-hit :flinch)                              ; 床尾打 SHOBI-UCHI: the plank swung up from the hip
(defmove :lb-j2 :kind :quick :clip :lb-q2 :startup 7 :active 3 :recovery 13 :dmg 22 :adv-block -2
  :reach 1.45 :arc 110 :on-hit :flinch)                              ; 返し KAESHI: the plank's backhand
(defmove :lb-j3 :kind :quick :clip :lb-jab :startup 9 :active 3 :recovery 18 :dmg 28 :adv-block -4
  :reach 1.6 :arc 70 :on-hit :stagger :flags (:ender))               ; 銃口突 JUKO-TSUKI: the muzzle cross jabbed
(defmove :lb-k1 :kind :flash :clip :lb-f1 :startup 17 :active 4 :recovery 21 :dmg 48 :adv-block -3
  :reach 2.05 :arc 150 :on-hit :stagger)                             ; 銃身薙 JUSHIN-NAGI: the barrel swept flat
(defmove :lb-k2 :kind :flash :clip :lb-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 48 :adv-block -3
  :reach 2.05 :arc 100 :on-hit :stagger)                             ; 振り下ろし FURIOROSHI: the barrel brought down
(defmove :lb-k3 :kind :flash :clip :lb-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 70 :adv-block -20
  :reach 2.15 :arc 60 :on-hit :crumple :flags (:ender))             ; 零距離 REI-KYORI: the muzzle pressed in, fired (melee)
(defmove-copy :lb-j2s :lb-j2)
(defmove-copy :lb-k2s :lb-k2)
;; L 万物貫通 X-AXIS SHOT (§4.3): held, it aims (turning *LB-AIM-TRACK* until the lock at f34, LB-AIM-TICK), the line
;; locks (jade), the shot fires at max(release + 4, lock + 10), by itself at f64: the hold (40 60) ends at max(release,
;; 40) or 60, the main phase fires 4 f later (LB-AIM-HOLD). A line 31 m long through guard (chip 15 %, drain 30), through
;; KASA (:uncatchable); 40 + the distance bonus (LB-X-FIRE)
(defmove :lb-x-axis :kind :sig :clip :lb-aim :clip-2 :lb-fire :callout "X-AXIS" :hold (40 60) :startup 4 :active 2
  :recovery 26 :dmg 40 :adv-block -14 :track 0 :vol (:cap 0.6 31.0 1.2 0.25) :on-hit :stagger :kb 1.0
  :chip *lb-x-chip* :guard *lb-x-guard* :flags (:ranged :x-axis :uncatchable)
  :tick lb-aim-tick :on-frame ((4 lb-x-fire)) :params (:lock 34 :bonus t))
;; K -> L (the kit's :l-after-k): the snap shot, no aim: 40 flat, a 12 m line, a string's only cash-out
(defmove :lb-x-quick :kind :sig :clip :lb-snap :callout "X-AXIS" :startup 6 :active 2 :recovery 20 :dmg 40 :adv-block -14
  :track 0 :vol (:cap 0.6 12.0 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *lb-x-chip* :guard *lb-x-guard*
  :flags (:ranged :x-axis :uncatchable) :on-frame ((6 lb-x-snap)))
;; Shift+K SP1 三連 SANREN: three unaimed lines f12 / f22 / f32 (each 20 m, hits once), turning 90 deg/s between them
(defmove :lb-sanren :kind :sp :clip :lb-sanren :callout "SANREN" :startup 12 :active 22 :recovery 24 :dmg 30 :adv-block -14
  :track 90 :vol (:cap 0.6 20.0 1.2 0.25) :on-hit :flinch :kb 0.5 :chip *lb-x-chip* :guard 12
  :flags (:ranged :x-axis :uncatchable) :hits ((12 14) (22 24) (32 34)) :tick lb-sanren-tick
  :on-frame ((12 lb-line-shot) (22 lb-line-shot) (32 lb-line-shot)) :params (:len 20.0))
;; Shift+L SP2 飛廉脚 HIRENKYAKU: a 6 m back-slide over f0-14 (no iframes), then the X-axis shot at f20 from where he lands
(defmove :lb-hiren :kind :sp :clip :lb-hiren :callout "HIRENKYAKU" :startup 20 :active 2 :recovery 22 :dmg 40 :adv-block -14
  :track 0 :vol (:cap 0.6 31.0 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *lb-x-chip* :guard *lb-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick lb-hiren-tick :on-frame ((0 lb-hiren-slide) (20 lb-x-fire))
  :params (:bonus t :slide 6.0 :slide-f 14 :lock 14))
(defmove :lb-breaker :kind :breaker :clip :lb-breaker :clip-2 :lb-butt :callout "SHOBI-UCHI")
;; O 照準 SHOJUN, the Kikon module: the lane (Rukia's / Senjumaru's shape): aura 8, a 12 m lane, guardable (no :x-axis)
(defmove :lb-kikon :kind :kikon :clip :lb-aim :clip-2 :lb-fire :clip-s 4 :callout "BANBUTSU KANTSU" :cine lb-kikon-cine
  :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0 :vol (:cap 0.5 12.0 1.2 1.2)
  :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 lb-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))

;;; ================================================================ 神の裁き JILLIEL (§5)
;; the wing blades (the front pair: the rig's arms; the base budget, a little longer, a little heavier)
(defmove :lb-w-j1 :kind :quick :clip :lb-w-q1 :startup 8 :active 3 :recovery 12 :dmg 24 :adv-block -2
  :reach 1.6 :arc 110 :on-hit :flinch)                               ; 翼刃 YOKUJIN 1
(defmove :lb-w-j2 :kind :quick :clip :lb-w-q2 :startup 7 :active 3 :recovery 13 :dmg 24 :adv-block -2
  :reach 1.6 :arc 110 :on-hit :flinch)                               ; 翼刃 YOKUJIN 2
(defmove :lb-w-j3 :kind :quick :clip :lb-w-q3 :startup 9 :active 3 :recovery 18 :dmg 30 :adv-block -4
  :reach 1.7 :arc 120 :on-hit :stagger :flags (:ender))              ; 翼刃 YOKUJIN 3
(defmove :lb-w-k1 :kind :flash :clip :lb-w-f1 :startup 17 :active 4 :recovery 21 :dmg 50 :adv-block -3
  :reach 2.2 :arc 150 :on-hit :stagger)                              ; 双翼 SOYOKU 1
(defmove :lb-w-k2 :kind :flash :clip :lb-w-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 50 :adv-block -3
  :reach 2.2 :arc 110 :on-hit :stagger)                              ; 双翼 SOYOKU 2
(defmove :lb-w-k3 :kind :flash :clip :lb-w-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 72 :adv-block -20
  :reach 2.3 :arc 90 :on-hit :crumple :flags (:ender))              ; 双翼 SOYOKU 3
(defmove-copy :lb-w-j2s :lb-w-j2)
(defmove-copy :lb-w-k2s :lb-w-k2)
;; L 翼の斉射 WING VOLLEY: aimed and locked as the shot (lock f24, the hold (30 50): fire max(release + 4, 34), by itself
;; at f54); five lines fanned 6 deg apart in ONE window (one line at most hits him), 55 flat, drain 18
(defmove :lb-volley :kind :sig :clip :lb-w-aim :clip-2 :lb-w-fire :callout "WING VOLLEY" :hold (30 50) :startup 4 :active 2
  :recovery 24 :dmg 55 :adv-block -14 :track 0 :on-hit :stagger :kb 1.0 :chip *lb-x-chip* :guard 18
  :vols ((:cap 0.6 31.0 1.2 0.2 -12) (:cap 0.6 31.0 1.2 0.2 -6) (:cap 0.6 31.0 1.2 0.2 0) (:cap 0.6 31.0 1.2 0.2 6)
         (:cap 0.6 31.0 1.2 0.2 12))
  :flags (:ranged :x-axis :uncatchable) :tick lb-aim-tick :on-frame ((4 lb-volley-fire)) :params (:lock 24))
;; Shift+L SP2 二十四孔 NIJUSHI-KO (2 bars): all 24 holes glow 40 f (turning 60 deg/s until f20, then planted), one 1.2 m
;; radius beam to the wall
(defmove :lb-nijushi :kind :sp :clip :lb-w-nijushi :callout "NIJUSHI-KO" :startup 40 :active 6 :recovery 30 :dmg 180
  :adv-block -14 :track 0 :vol (:cap 0.6 31.0 1.2 1.2) :on-hit :knockback :kb 2.0 :chip *lb-x-chip* :guard 45
  :flags (:ranged :x-axis :uncatchable) :tick lb-nijushi-tick :on-frame ((0 lb-nijushi-tell) (40 lb-beam-shot))
  :params (:lock 20 :track 60.0 :width 1.2))
(defmove :lb-w-breaker :kind :breaker :clip :lb-w-breaker :clip-2 :lb-w-ram :callout "JILLIEL")
(defmove :lb-w-kikon :kind :kikon :clip :lb-w-aim :clip-2 :lb-w-fire :clip-s 4 :callout "KAMI NO SABAKI"
  :cine lb-jilliel-kikon-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.2 1.2) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 lb-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))

;;; ================================================================ the owl 真の姿 (§6)
(defmove :lb-o-j1 :kind :quick :clip :lb-o-q1 :startup 8 :active 3 :recovery 12 :dmg 26 :adv-block -2
  :reach 1.7 :arc 110 :on-hit :flinch)                               ; 鉤爪 KAGIZUME 1: the long arms
(defmove :lb-o-j2 :kind :quick :clip :lb-o-q2 :startup 7 :active 3 :recovery 13 :dmg 26 :adv-block -2
  :reach 1.7 :arc 110 :on-hit :flinch)
(defmove :lb-o-j3 :kind :quick :clip :lb-o-q3 :startup 9 :active 3 :recovery 18 :dmg 32 :adv-block -4
  :reach 1.7 :arc 120 :on-hit :stagger :flags (:ender))
(defmove :lb-o-k1 :kind :flash :clip :lb-o-f1 :startup 17 :active 4 :recovery 21 :dmg 54 :adv-block -3
  :reach 2.3 :arc 150 :on-hit :stagger)
(defmove :lb-o-k2 :kind :flash :clip :lb-o-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 54 :adv-block -3
  :reach 2.3 :arc 110 :on-hit :stagger)
(defmove :lb-o-k3 :kind :flash :clip :lb-o-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 78 :adv-block -20
  :reach 2.3 :arc 90 :on-hit :crumple :flags (:ender))
(defmove-copy :lb-o-j2s :lb-o-j2)
(defmove-copy :lb-o-k2s :lb-o-k2)
;; L 裁きの光明 SABAKI NO KOMYO: the chop at f16 runs a ground line of golden blasts from 1 m to 18 m, erupting outward at 40
;; m/s (his own hazard kind :lb-sabaki through the :hook path, not a :rift), hits once, through guard
(defmove :lb-sabaki :kind :sig :clip :lb-o-chop :callout "SABAKI NO KOMYO" :startup 16 :active 0 :recovery 24 :reach 18.0
  :track 120 :on-frame ((16 lb-sabaki)) :params (:dmg 90 :guard 18 :fan (0.0)))
;; Shift+K SP1 三筋 MISUJI: three SABAKI lines at -20 / 0 / +20 deg at once, one hit group (one line at most hits him)
(defmove :lb-misuji :kind :sp :clip :lb-o-chop :clip-s 16 :callout "MISUJI" :startup 18 :active 0 :recovery 26 :reach 18.0
  :track 90 :on-frame ((18 lb-sabaki)) :params (:dmg 70 :guard 18 :fan (-20.0 0.0 20.0)))
;; Shift+L SP2 神の喇叭 TROMPETE (2 bars): 60 f wind-up (the fist at the beak, the trumpet forming; turning 30 deg/s until
;; f40, then locked), a 2.4 m-wide beam 30 f; reflected by a perfect Hoho f48-f59 / guard f50-f58 (LB-REFLECT-CHECK)
(defmove :lb-trompete :kind :sp :clip :lb-o-trompete :callout "TROMPETE" :startup 60 :active 30 :recovery 40 :dmg 240
  :adv-block -14 :track 0 :vol (:cap 0.6 31.0 1.4 1.2) :on-hit :knockback :kb 3.0 :chip *lb-x-chip* :guard 60
  :flags (:ranged :x-axis :uncatchable :reflectable) :tick lb-trompete-tick :on-frame ((0 lb-trompete-tell) (60 lb-beam-shot))
  :params (:lock 40 :blast 60 :track 30.0 :width 1.2))
(defmove :lb-o-breaker :kind :breaker :clip :lb-o-breaker :clip-2 :lb-o-stamp :callout "KAGIZUME")
(defmove :lb-o-kikon :kind :kikon :clip :lb-o-trompete :clip-2 :lb-o-chop :clip-s 4 :callout "TROMPETE"
  :cine lb-trompete-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 80 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.4 1.4) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 lb-lane-shot))
  :params (:aura 10 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))

;;; ================================================================ forms
(defparameter *lille-hooks* '(:tick lille-tick :ok lille-ok :hit lille-hit :struck lille-struck :settled lille-settled
                              :draw lille-draw)
  "His mechanics (kit.lisp KIT-HOOK): the eye, the lock's bookkeeping, the reflect, the stance's own perfect-Hoho drop
(:tick); the sealed Trompete (:ok); the pacing log (:hit :struck); BEHEADED (:settled); the aim line (:draw). (The revive's
condition is the Jilliel kits' :bankai-ok, LILLE-BANKAI-OK.)")

;; the CPU, batch 1 (DUEL_LILLE §11.1): bands, intents, the aim's hold, the generic Bankai key, and the keys a CPU facing
;; him reads off his kits (:opp-aim, :opp-reflect: the AI batch, ai.lisp AI-OPP-AIM / AI-OPP-REFLECT). TODO batch 3: his own
;; reflexes: the eye (:eye, :reflex), the stance (:stance (:p 0.6 :max 180)), :trompete (:when-recovering t :far 8)
(defkit :lille :base
  :name "LILLE" :body :lille :weapon :diagramm :stance :lb-stance :calm t
  :intro :lb-intro :win :lb-win :intro-callout "THE X-AXIS"
  :walk *walk-lille* :run *run-lille* :reishi *reishi-max* :swing-sfx :whoosh-light :mult *lille-mult* :taken *lille-taken*
  :commands (:q :lb-j1 :f :lb-k1 :sig :lb-x-axis :sp1 :lb-sanren :sp2 :lb-hiren :breaker :lb-breaker :kikon :lb-kikon)
  :grid (:lb-j1 :lb-j2 :lb-j3 :lb-k1 :lb-k2 :lb-k3 :lb-j2s :lb-k2s)
  :l-after-k :lb-x-quick :awaken-form :jilliel :kikon-konpaku 2 :hooks *lille-hooks*
  :ai (:intents (:approach 1 :pressure 1 :zone 5 :defend 2)
       :ranges (:approach (2.2 8.0) :pressure (1.3 2.2) :zone (8.0 20.0) :defend (5.0 9.0))
       :moves ((0.0 2.2 :q 4 :f 2 :breaker 1 :step 2)
               (2.2 6.0 :sp2 2 :step 2 :sp1 1 nil 1)
               (6.0 99.0 :sig 6 :sp1 1 nil 1))
       :guard 0.5 :hoho 0.3 :dash 0.3 :dash-back 0.7 :block-string 0.3 :o-ender 0.3 :l-after-k 0.4 :kikon-range 7.7
       :awaken (:min-taken 150) :sig-hold lb-aim-hold-ai :opp-aim (:step 0.6 :hoho 0.25 :rush 12)))

(defkit :lille :jilliel :inherit :base
  :awakening t :form-name "JILLIEL" :walk *walk-jilliel* :run *run-jilliel* :mult *jilliel-mult* :taken *jilliel-taken*
  :kikon-konpaku 3 :guard-to :jilliel-mujittai :gg-regen *jilliel-gg-regen* :bankai-form :shin :bankai-ok lille-bankai-ok
  :l-after-k nil
  :endless-form :jilliel                        ; ENDLESS: the stance and the owl stay as JILLIEL (never the owl)
  :body :lille-jilliel :weapon nil :stance :lb-w-stance :cine lb-jilliel-cine :u-tag "U: MUJITTAI" :swing-sfx :whoosh-heavy
  :commands (:q :lb-w-j1 :f :lb-w-k1 :sig :lb-volley :sp2 :lb-nijushi :breaker :lb-w-breaker :kikon :lb-w-kikon)
  :grid (:lb-w-j1 :lb-w-j2 :lb-w-j3 :lb-w-k1 :lb-w-k2 :lb-w-k3 :lb-w-j2s :lb-w-k2s)
  :ai (:intents (:approach 1 :pressure 1 :zone 4 :defend 2)
       :ranges (:approach (2.4 8.0) :pressure (1.4 2.4) :zone (8.0 14.0) :defend (5.0 9.0))
       :moves ((0.0 2.4 :q 3 :f 3 :breaker 1 :step 1)
               (2.4 8.0 :sig 3 :step 2 nil 1)
               (8.0 16.0 :sig 5 :sp2 1 nil 1)
               (16.0 99.0 :sig 2 :step 1 nil 2))
       :guard 0.4 :hoho 0.3 :dash 0.4 :dash-back 0.5 :kikon-range 8.5 :sig-hold lb-aim-hold-ai
       :bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1) :opp-aim (:step 0.6 :hoho 0.25 :rush 12)))

;; U in Jilliel: 無実体 MUJITTAI, West's ward with the :intangible flag (§5.2): every attack drops it (no :keep)
(defkit :lille :jilliel-mujittai :inherit :jilliel
  :guard-to nil :drop-to :jilliel :passives (:ward :intangible) :stance :lb-w-fold :u-tag "U: MUJITTAI")

;; the owl (P after BEHEADED, Kenpachi's Bankai path: Konpaku -> 1, Reishi full; decisions 8, 15: no burn)
(defkit :lille :shin :inherit :base
  :awakening t :form-name "SHIN" :walk *walk-shin* :run *run-shin* :mult *shin-mult* :taken *shin-taken* :kikon-konpaku 4
  :body :lille-shin :weapon nil :stance :lb-o-stance :cine lb-revive-cine :l-after-k nil :swing-sfx :whoosh-heavy
  :bankai-form nil :bankai-ok nil
  :endless-form :jilliel
  :commands (:q :lb-o-j1 :f :lb-o-k1 :sig :lb-sabaki :sp1 :lb-misuji :sp2 :lb-trompete :breaker :lb-o-breaker :kikon :lb-o-kikon)
  :grid (:lb-o-j1 :lb-o-j2 :lb-o-j3 :lb-o-k1 :lb-o-k2 :lb-o-k3 :lb-o-j2s :lb-o-k2s)
  :ai (:intents (:approach 3 :pressure 4 :zone 2 :defend 1)
       :ranges (:approach (2.6 6.0) :pressure (1.4 2.6) :zone (6.0 16.0) :defend (3.0 6.0))
       :moves ((0.0 2.6 :q 4 :f 4 :breaker 1)
               (2.6 8.0 :sig 3 :sp1 2 :step 1)
               (8.0 99.0 :sp2 3 :sig 2 nil 1))
       :guard 0.4 :hoho 0.3 :dash 0.8 :o-ender 0.6 :kikon-range 9.0 :opp-reflect (:p 0.3)))

;; his names in the brush tables (brush.lisp): the intro's column and the technique columns at his side (not on the host)
(when (boundp '*brush-names*)
  (setf *brush-names* (append (remove :lille *brush-names* :key #'first) '((:lille "リジェ・バロ" "LILLE BARRO")))
        *brush-callouts*
        (append (remove-if (lambda (c) (member (first c) '(:lb-x-axis :lb-sanren :lb-hiren :lb-volley :lb-nijushi :lb-sabaki
                                                            :lb-misuji :lb-trompete)))
                           *brush-callouts*)
                '((:lb-x-axis "万物貫通" "THE X-AXIS" nil) (:lb-sanren "三連" "SANREN" nil) (:lb-hiren "飛廉脚" "HIRENKYAKU" nil)
                  (:lb-volley "翼の斉射" "WING VOLLEY" nil) (:lb-nijushi "二十四孔" "NIJUSHI-KO" nil)
                  (:lb-sabaki "裁きの光明" "SABAKI NO KOMYO" nil) (:lb-misuji "三筋" "MISUJI" nil)
                  (:lb-trompete "神の喇叭" "TROMPETE" nil)))))

;;; ================================================================ per-side state (the sim's; reset with every match)
(defstruct (lbs (:conc-name lbs-))
  (e nil)                                 ; the fighter it belongs to: a new match's fighter gets a fresh state (LB)
  (eyes *lb-eyes* :type fixnum)           ; the eye's pips left (never refilled)
  (u-up 0 :type fixnum)                   ; frames U has been up (the eye's rest rule)
  (eye-t -1 :type fixnum)                 ; *MATCH-TICK* of the last opening (the look)
  (beheaded nil)                          ; BEHEADED: a Kikon / Soul Break left him in Jilliel with 1-4 Konpaku (P revives)
  (sealed nil)                            ; the halo broke: Trompete is sealed for the match
  (stance 0 :type fixnum)                 ; frames of the current stance (MUJITTAI)
  (awake-t -1 :type fixnum) (revive-t -1 :type fixnum)   ; ticks of the awakening and the revival (the pacing log)
  (acc nil))                              ; the pacing log's counters (debug)
(defvar *lb* (vector (make-lbs) (make-lbs)) "Per side: his eye, his beheading, the seal.")
(defvar *lb-reflect-test* nil "Debug 79007 / 79008: P2 reflects P1's Trompete by a guard (:guard) / a perfect Hoho (:hoho).")
(defun lb (e)
  "E's state; a new fighter entity (a new match) gets a fresh one, keeping only the pacing log's counters (Senjumaru's
carry-over bug, DEVLOG §38-§39)."
  (let* ((i (fighter-side (fighter e))) (st (svref *lb* i)))
    (if (eql (lbs-e st) e) st (setf (svref *lb* i) (make-lbs :e e :acc (lbs-acc st))))))
(defmacro lb-count (e key &optional (n 1)) `(incf (getf (lbs-acc (lb ,e)) ,key 0) ,n))
(defun lb-band (d) "The pacing log's distance band of D metres: :near (< 8) :mid (8-14) :far (>= 14)." (cond ((< d 8.0) :near) ((< d 14.0) :mid) (t :far)))
(defun lb-band-key (prefix d) (intern (format nil "~a-~a" prefix (lb-band d)) :keyword))

;;; hazard data: his hazards (the SABAKI lines, the shots' looks) carry one of these and LB-HZ as their hook
(defstruct (lbh (:conc-name lbh-))
  (kind nil)                              ; :sabaki (a hit) :shot :volley :beam :lane (looks)
  (len 0f0 :type single-float) (width 0f0 :type single-float)
  (lock nil))                             ; a look's colour: T jade (a locked shot), NIL ink

;;; ================================================================ hooks (called through the data's symbols)
(defun lille-ok (e command combo)
  "His kit's refusals: Trompete once the halo broke (sealed for the match, decision 9)."
  (declare (ignore combo))
  (not (and (eq command :sp2) (eq (fighter-form (fighter e)) :shin) (lbs-sealed (lb e)))))

(defun lille-bankai-ok (e)
  "His kit's :bankai-ok (combat.lisp BANKAI-OK-P): P revives him into the owl only once BEHEADED, and only free: idle,
guard or the stance (the generic AWAKEN-STATE-P would also allow blockstun and a combo reaction; §6.1)."
  (and (lbs-beheaded (lb e)) (member (fighter-state (fighter e)) '(:idle :guard)) t))

(defun lille-settled (def lost left)
  "His kit's :settled (combat.lisp SETTLE-KONPAKU): a Kikon or Soul Break that leaves him in Jilliel with 1-4 Konpaku
beheads him (BEHEADED, kept for the match: P may wait)."
  (declare (ignore lost))
  (let ((st (lb def)))
    (when (and (not (lbs-beheaded st)) (lb-beheaded-p (fighter-form (fighter def)) left))
      (setf (lbs-beheaded st) t)
      (lb-count def :beheaded-tick *match-tick*)
      (callout def "BEHEADED")
      (clog "~a BEHEADED (~d konpaku)" (side-name def) left))))

(defun lille-tick (e f g)
  "Per step (his kit's :tick): the eye (base), the stance's own perfect-Hoho drop (MUJITTAI), Trompete's reflect check on
its f59, the pacing log's clocks."
  (declare (ignore g))
  (let ((st (lb e)) (form (fighter-form f)))
    (when (and (not (eq form :base)) (minusp (lbs-awake-t st)))
      (setf (lbs-awake-t st) *match-tick*) (lb-count e :awaken-tick *match-tick*))
    (when (and (eq form :shin) (minusp (lbs-revive-t st)))
      (setf (lbs-revive-t st) *match-tick* (lbs-beheaded st) nil) (lb-count e :revive-tick *match-tick*))
    (if (eq form :base) (lb-eye-step e f st) (setf (lbs-u-up st) 0))
    (cond ((eq form :jilliel-mujittai)
           (when (and (eq (fighter-state f) :hoho) (fighter-perfect f))   ; his own counter strike is an attack: solid
             (set-form e :jilliel)
             (clog "~a MUJITTAI dropped: the perfect Hoho's counter" (side-name e)))
           (incf (lbs-stance st))
           (lb-count e :stance-frames)
           (setf (getf (lbs-acc st) :stance-max) (max (getf (lbs-acc st) :stance-max 0) (lbs-stance st))))
          (t (setf (lbs-stance st) 0)))
    (let ((mv (fighter-move f)))
      (when (and (eq (fighter-state f) :move) mv (eq (mv-name mv) :lb-trompete) (eq (fighter-phase f) :main))
        (when *lb-reflect-test* (lille-reflect-test-step e f))   ; (debug 79007 / 79008: a scripted reflector)
        (when (= (fighter-sf f) 59) (lb-reflect-check e f st mv))))))

;;; ---------------------------------------------------------------- the eye (§4.1)
(defun lb-eye-step (e f st)
  "The base form's eye: a U press after U rested *LB-EYE-REST* frames, from a free state, while a threat is <= *LB-EYE-LEAD*
frames away (LB-THREAT-P) opens it: *LB-EYE-PHASE* frames intangible, a pip spent; the third fills the awakening gauge.
A press with no threat spends nothing (it is a plain guard)."
  (let ((vp (pilot-vpad (pilot e))))
    (if (vpad-down vp :guard)
        (progn
          (when (and (lb-eye-tap-p (lbs-u-up st) (lbs-eyes st) (fighter-state f) (fighter-sf f)) (lb-threat-p e))
            (lb-open-eye e f st))
          (setf (lbs-u-up st) 0))
        (setf (lbs-u-up st) (min 9999 (1+ (lbs-u-up st)))))))

(defun lb-threat-p (e)
  "PERFECT-NOW-P's eye version (lead *LB-EYE-LEAD*): an opponent hit volume (move or hazard) active now or within the lead
overlaps his hurt cylinder grown by *PERFECT-INFLATE*, or the opponent's Breaker / Kikon rush dash is about to strike."
  (let* ((o (opp-of e)) (fo (fighter o)) (mv (fighter-move fo)) (p (pos-of e)) (q (pos-of o))
         (b (model-body (model e))) (yaw (yaw-of o))
         (r (f32 (+ (body-hurt-r b) *perfect-inflate*))) (h (f32 (+ (body-hurt-h b) *perfect-inflate*))))
    (or (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :main)
             (loop for w across (mv-hits mv)
                   thereis (and (lb-eye-window-p (fighter-sf fo) (hw-from w) (hw-to w))
                                (loop for v in (hw-vols w)
                                      thereis (vol-hit-p v (aref q 0) (aref q 1) (aref q 2) (f32 (fwd-x yaw)) (f32 (fwd-z yaw))
                                                         (aref p 0) (aref p 1) (aref p 2) r h 0f0)))))
        (and (eq (fighter-state fo) :move) (eq (fighter-phase fo) :dash)
             (<= (fighter-dist fo) (+ (if (eq (mv-kind mv) :kikon) *kikon-trigger* *breaker-trigger*) 0.5)))
        (let ((found nil))
          (do-entities (hh (hz hazard))
            (when (and (not found) (eql (hazard-owner hz) o) (hazard-hw hz) (> (hazard-hits-left hz) 0)
                       (<= (hazard-delay hz) *lb-eye-lead*)
                       (hazard-touches-p hz (aref p 0) (aref p 1) (aref p 2) r h))
              (setf found t)))
          found))))

(defun lb-open-eye (e f st)
  "The left eye opens: intangible *LB-EYE-PHASE* frames (FIGHTER-INVULN: every hit resolves to nothing, a whiff), one pip
spent; the third opening sets the awakening gauge to EVOLUTION unless he is awakened (decision 7)."
  (let ((g (gauges e)))
    (multiple-value-bind (left evo) (lb-eye-open (lbs-eyes st) (gauges-awakened g))
      (setf (lbs-eyes st) left (lbs-eye-t st) *match-tick* (fighter-invuln f) (max (fighter-invuln f) *lb-eye-phase*))
      (lb-count e :eyes)
      (emit :sfx :hoho-out e)
      (when evo
        (setf (gauges-awaken g) (f32 *awaken-max*))
        (lb-count e :eye-evolution *match-tick*)
        (callout e "SANDO MO ME WO..."))           ; 「三度も眼を開かされるとは…」 (the brush line: batch 3)
      (clog "~a EYE opens, ~d left~:[~; (EVOLUTION)~]" (side-name e) left evo))))

;;; ---------------------------------------------------------------- the aim, the lock, the shot (§4.3, §5.4)
(defun lb-aim-tick (e)
  "An aimed move's tick (the X-axis shot, the volley): in the hold he turns toward the opponent at *LB-AIM-TRACK* until the
lock (its :lock), then the line is committed; from *LB-AIM-CANCEL* until the lock, a Step / Hoho / U cancels the aim."
  (let* ((f (fighter e)) (lock (move-param e :lock)) (h (fighter-hold f)))
    (when (eq (fighter-phase f) :hold)
      (when (= h 1) (lb-count e :aimed))
      (when (= h lock) (lb-count e :locked) (emit :sfx :lb-lock e))
      (if (lb-tracking-p h lock)
          (turn-to-opp e f (track-step *lb-aim-track*)))
      (when (and (lb-aim-cancel-p h lock) (zerop (fighter-lock f)))
        (let ((vp (pilot-vpad (pilot e))))
          (cond ((vpad-command-pressed-p vp :step t)
                 (vpad-consume! vp :step) (to-idle e 0) (lb-count e :aim-cancel)
                 (or (try-command e f :hoho) (try-command e f :step)))
                ((vpad-command-pressed-p vp :step nil)
                 (vpad-consume! vp :step) (to-idle e 0) (lb-count e :aim-cancel) (try-command e f :step))
                ((vpad-command-pressed-p vp :guard :any)
                 (vpad-consume! vp :guard) (to-idle e 0) (lb-count e :aim-cancel))))))))

(defun lb-x-fire (e)
  "The X-axis shot's fire frame (the aimed shot, HIRENKYAKU's): its distance bonus on the hit (FIGHTER-DMG-BONUS: the
window's 40 + LB-X-BONUS), the line's look, the pacing log."
  (let* ((f (fighter e)) (d (fighter-dist f)))
    (setf (fighter-dmg-bonus f) (lb-x-bonus d))
    (lb-count e (lb-band-key "FIRED" d))
    (lb-spawn-look e :shot 31.0 0.05 t)
    (emit :sfx :lb-crack e)))

(defun lb-x-snap (e)
  "K -> L's snap shot (no aim): its look."
  (lb-count e :snap-shots)
  (lb-spawn-look e :shot 12.0 0.04 nil)
  (emit :sfx :rift-cut e))

(defun lb-line-shot (e)
  "SANREN's shots (f12, f22, f32): the line's look."
  (lb-count e :sanren-shots)
  (lb-spawn-look e :shot (move-param e :len) 0.04 nil)
  (emit :sfx :rift-cut e))

(defun lb-lane-shot (e)
  "A Kikon module's lane (照準, 神の裁き, 神の喇叭): its look (the hit is the move's lane)."
  (lb-spawn-look e :lane (move-param e :len) 0.5 t)
  (emit :sfx :kikon-slash e))

(defun lb-volley-fire (e)
  "The volley's fire frame: five lines (one hit window, five volumes), the look."
  (lb-count e :volleys)
  (lb-spawn-look e :volley 31.0 0.04 t)
  (emit :sfx :rift-cut e))

(defun lb-beam-shot (e)
  "NIJUSHI-KO's / Trompete's first active frame: the beam's look."
  (lb-count e (if (eq (mv-name (fighter-move (fighter e))) :lb-trompete) :trompete-fired :nijushi-fired))
  (lb-spawn-look e :beam 31.0 (move-param e :width) t)
  (emit :sfx :explode e))

(defun lb-spawn-look (e kind len width lock)
  "A look-only hazard of his (kind :lb-fx, no hit) along his facing: a shot, the volley's fan, a beam or a lane (drawn by
LB-LOOK, lille-art.lisp)."
  (let ((p (pos-of e)))
    (spawn-hazard :lb-fx e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size len :life (if (eq kind :beam) 30 16)
                           :hook 'lb-hz :data (make-lbh :kind kind :len (f32 len) :width (f32 width) :lock lock)
                           :look 'lb-look)))

(defun lb-sanren-tick (e)
  "SANREN: he turns 90 deg/s between the shots (the 2nd and 3rd follow a Step)."
  (let* ((f (fighter e)) (sf (fighter-sf f)))
    (when (and (eq (fighter-phase f) :main) (< 14 sf 32) (not (<= 22 sf 24)))
      (turn-to-opp e f (track-step 90.0)))))

(defun lb-hiren-slide (e)
  "HIRENKYAKU f0: the 6 m back-slide over 14 f (no iframes: decision 1)."
  (let* ((p (pos-of e)) (f (fighter e)))
    (set-slide e (move-param e :slide) (move-param e :slide-f) (- (aref p 0) (fighter-ox f)) (- (aref p 2) (fighter-oz f)))
    (lb-count e :hiren)
    (emit :sfx :hoho-out e)))

(defun lb-hiren-tick (e)
  "HIRENKYAKU: he keeps turning to the opponent while he slides, then the line is fixed (track 0 after f14)."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (move-param e :lock))) (turn-to-opp e f (track-step 90.0)))))

(defun lb-planted-tick (e)
  "A planted wind-up (NIJUSHI-KO, Trompete): turning at the move's :track until its :lock frame, then locked."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (move-param e :lock)))
      (turn-to-opp e f (track-step (move-param e :track))))))
(defun lb-nijushi-tick (e) "NIJUSHI-KO's wind-up (LB-PLANTED-TICK)." (lb-planted-tick e))
(defun lb-trompete-tick (e) "Trompete's wind-up (LB-PLANTED-TICK)." (lb-planted-tick e))

(defun lb-nijushi-tell (e)
  "NIJUSHI-KO f0: all 24 holes glow (the tell)."
  (setf (model-super (model e)) 0.6)
  (emit :sfx :awaken-rise e))

(defun lb-trompete-tell (e)
  "Trompete f0: the fist at the beak, the trumpet forming overhead, the rising pitch (the tell)."
  (setf (model-super (model e)) 1.0)
  (emit :sfx :lb-trumpet e))

;;; ---------------------------------------------------------------- SABAKI NO KOMYO / MISUJI (§6.2)
(defun lb-sabaki (e)
  "The chop's frame: a SABAKI ground line per :fan angle (MISUJI's three share one hit group: one line at most hits him;
gap G12); each erupts outward from 1 m to 18 m (LB-SABAKI-SPAN), through guard (chip 15 %, the :guard drain), once."
  (let* ((p (pos-of e)) (fan (move-param e :fan)) (group (and (rest fan) (make-hit-group 1))))
    (dolist (a fan)
      (spawn-hazard :lb-sabaki e :x (aref p 0) :z (aref p 2) :yaw (+ (yaw-of e) (deg a)) :size *lb-sabaki-to*
                                 :life (lb-sabaki-frames) :group group :hook 'lb-hz :data (make-lbh :kind :sabaki :len (f32 *lb-sabaki-to*)
                                                                                                    :width (f32 *lb-sabaki-width*))
                                 :look 'lb-look
                                 :hw (make-hitwin :dmg (move-param e :dmg) :react :stagger :kb 1.0 :hs *hitstop-heavy*
                                                  :chip *lb-x-chip* :guard (move-param e :guard)
                                                  :flags '(:ranged :x-axis :uncatchable))))
    (lb-count e (if group :misuji :sabaki))
    (emit :sfx :ground-crack e)))

(defun lb-hz (h hz ev &optional a b c dd ee)
  "His hazards' hook (HAZARD-HOOK): a SABAKI line's volume (:touches): the burning span of the line (LB-SABAKI-SPAN), a box
*LB-SABAKI-WIDTH* wide; the looks touch nothing."
  (declare (ignore h))
  (let ((d (hazard-data hz)))
    (case ev
      (:touches (and (eq (lbh-kind d) :sabaki)
                     (multiple-value-bind (from to) (lb-sabaki-span (hazard-age hz))
                       (and (> to from)
                            (let* ((yaw (hazard-yaw hz)) (mid (* 0.5 (+ from to))))
                              (obox-cyl-hit-p (f32 (+ (hazard-x hz) (* mid (fwd-x yaw)))) 1f0 (f32 (+ (hazard-z hz) (* mid (fwd-z yaw))))
                                              yaw (f32 (* 0.5 (lbh-width d))) 1.2f0 (f32 (* 0.5 (- to from)))
                                              a b c dd ee))))))
      (t nil))))

;;; ---------------------------------------------------------------- Trompete's reflect (§6.3, decision 9)
(defun lb-reflect-check (e f st mv)
  "Trompete at the end of its f59 (the beam comes next step): the opponent in a perfect Hoho started f48-f59, or in a guard
pressed f50-f58 (FIGHTER-GUARD-T 2-10, facing him, not a ward: West, KESSA and zero Rukia can't) reflects it."
  (declare (ignore f))
  (let* ((o (opp-of e)) (fo (fighter o)) (go (gauges o)) (p (pos-of e)) (q (pos-of o))
         (src (cond ((and (eq (fighter-state fo) :hoho) (fighter-perfect fo) (lb-reflect-hoho-p (- 59 (fighter-sf fo)))) :hoho)
                    ((and (eq (fighter-state fo) :guard) (not (passive-p o :ward)) (lb-reflect-guard-p (fighter-guard-t fo))
                          (can-guard-p (gauges-gg go) (gauges-guardless go))
                          (in-front-p (yaw-of o) (aref q 0) (aref q 2) (aref p 0) (aref p 2) *guard-arc*))
                     :guard))))
    (when src (lb-reflect! e o st mv src))))

(defun lb-reflect! (e o st mv src)
  "The reflect: the beam turns back along its line before it fires: he takes *LB-REFLECT-K* of it x his form's damage as a
real hit (it may Soul Break him; not a Kikon), staggers *LB-REFLECT-STUN*; his halo breaks: Trompete is sealed for the
match. The reflector takes nothing (a Hoho's counter strike is replaced by the reflect)."
  (let* ((dmg (lb-reflect-damage (hw-dmg (svref (mv-hits mv) 0)) (kit-mult (kit-of e)))) (q (pos-of o)) (p (pos-of e)))
    (setf (lbs-sealed st) t (fighter-perfect (fighter o)) nil)
    (callout o "REFLECT")
    (lb-count e (if (eq src :hoho) :reflect-hoho :reflect-guard))
    (hitstop *hitstop-breaker*)
    (emit :hit o e (aref p 0) (+ (aref p 1) 1.1) (aref p 2) *hitstop-breaker* nil dmg :sp)
    (unless (deal-damage o e dmg)
      (set-reaction e :stagger *lb-reflect-stun* (aref q 0) (aref q 2) 1.0))
    (clog "~a TROMPETE REFLECTED by ~a (~a): ~d, sealed" (side-name e) (side-name o) src dmg)))

;;; ---------------------------------------------------------------- the pacing log's hit hooks
(defun lille-hit (att def res hw mv hazard ranged)
  "After a hit he dealt (his kit's :hit): a shot from >= *LB-FAR-KB* knocks back 2.0 m; the pacing log (shots hit / guarded
by band, damage by band, Trompete)."
  (declare (ignore ranged))
  (let ((x (member :x-axis (hw-flags hw))) (d (fighter-dist (fighter att))))
    (when x
      (case (contact-of res)
        (:hit (lb-count att (lb-band-key "HIT" d))
         (when (and mv (not hazard) (getf (mv-params mv) :bonus))
           (lb-count att (lb-band-key "DMG" d) (+ (hw-dmg hw) (fighter-dmg-bonus (fighter att))))
           (when (>= d *lb-far-kb*)
             (let ((p (pos-of att)) (q (pos-of def))) (set-slide def 2.0 12 (- (aref q 0) (aref p 0)) (- (aref q 2) (aref p 2)))))))
        (:block (lb-count att (lb-band-key "GUARDED" d))))
      (when (and mv (eq (mv-name mv) :lb-trompete))
        (lb-count att (if (eq (contact-of res) :hit) :trompete-hit :trompete-guarded))))))

(defun lille-struck (def att res hw mv hazard ranged)
  "After a hit he took (his kit's :struck): the stance's pacing (passes, Breaker breaks, crushes)."
  (declare (ignore att hw mv hazard ranged))
  (when (eq (fighter-form (fighter def)) :jilliel-mujittai)
    (case res
      (:blocked (lb-count def :passes)))
    (when (gauges-guardless (gauges def)) (lb-count def :stance-crushed)))
  (when (and (eq res :guard-break) (eq (fighter-form (fighter def)) :jilliel)) (lb-count def :stance-broken)))

;;; ================================================================ AI (the kit's :sig-hold; the rest: batch 2)
(defun lb-aim-hold-ai (kit d &optional e)
  "Frames his CPU holds L (an aimed move): to a fire frame lock + 10 .. lock + 30 (the release, LB-FIRE-FRAME), rolled
once at the press (DUEL_LILLE §11.2: 34 + 10..30 for the shot). TODO batch 2: nearer 10 against a still opponent, nearer
30 against a strafer (his lateral speed read at the press)."
  (declare (ignore d e))
  (let* ((mv (kit-command-move kit :sig)) (lock (or (getf (mv-params mv) :lock) *lb-lock*)))
    (+ (- (+ lock *lb-lock-min*) *lb-x-delay*) (floor (* 21 (sim-rnd01))))))

;;; ================================================================ debug: tests, the pacing log (debug.lisp dispatches)
(defun lille-acc-reset () (dolist (st (coerce *lb* 'list)) (setf (lbs-acc st) nil)))

(defun lille-acc-line ()
  "After a gate row: a \"duel lille\" line per side that played him (the pacing log, docs/duel/DUEL_LILLE.md §13)."
  (dolist (e (list *p1* *p2*))
    (when (and (entity-alive-p e) (eq (fighter-character (fighter e)) :lille))
      (let ((st (lb e)))
        (log-msg "duel lille ~a seed ~d awakened ~a form ~a eyes ~d sealed ~a ~{~(~a~) ~a~^ ~}" (side-name e) *match-seed*
                 (gauges-awakened (gauges e)) (fighter-form (fighter e)) (lbs-eyes st) (lbs-sealed st) (lbs-acc st))))))

(defun lille-probe-line (tag)
  (let ((g1 (gauges *p1*)) (g2 (gauges *p2*)) (st (lb *p1*)))
    (log-msg "duel probe lille ~a t ~d p1 ~a ~a r~d k~d eyes ~d beheaded ~a sealed ~a gg ~d | p2 ~a r~d gg ~d"
             tag *match-tick* (fighter-form (fighter *p1*)) (state-of *p1*) (gauges-reishi g1) (gauges-konpaku g1)
             (lbs-eyes st) (lbs-beheaded st) (lbs-sealed st) (round (gauges-gg g1))
             (state-of *p2*) (gauges-reishi g2) (round (gauges-gg g2)))))

(defun lille-test (k)
  "79000+k (human P1 Lille, P2's CPU off unless noted; a \"duel probe lille\" line): 0 the base form 2.2 m from Kenpachi;
1 the base form 14 m from Kenpachi (aim with L); 2 / 3 / 4 forced JILLIEL / MUJITTAI / the owl 5 m from Kenpachi; 5 JILLIEL
BEHEADED with 3 Konpaku (P revives); 6 the base form 12 m from a Kenpachi CPU; 7 / 8 the owl 6 m from Kenpachi, Trompete
started, P2 reflecting it by a guard pressed on f54 / a Hoho on f52 (*LB-REFLECT-TEST*); 9 the base form 10 m from a
Yamamoto CPU (the eye); 10-13 eye pips 0-3 (in the running match); 20 P1 and P2 both Lille CPUs (the mirror) 12 m apart."
  (flet ((setup (c2 form dist &key cpu)
           (ensure-battle :lille c2 :cpu cpu)
           (when (brain *p1*) (setf (brain-off (brain *p1*)) (not cpu)))
           (unless (eq (fighter-form (fighter *p1*)) form) (force-form *p1* form))
           (place *p1* *p2* dist)
           (setf (gauges-reiatsu (gauges *p1*)) *reiatsu-max*)))
    (setf *lb-reflect-test* nil)
    (case k
      (0 (setup :kenpachi :base 2.2))
      (1 (setup :kenpachi :base 14.0))
      (2 (setup :kenpachi :jilliel 5.0))
      (3 (setup :kenpachi :jilliel-mujittai 5.0))
      (4 (setup :kenpachi :shin 5.0))
      (5 (setup :kenpachi :jilliel 5.0) (setf (gauges-konpaku (gauges *p1*)) 3 (lbs-beheaded (lb *p1*)) t))
      (6 (setup :kenpachi :base 12.0) (setf (brain-off (brain *p2*)) nil))
      ((7 8) (setup :kenpachi :shin 6.0) (setf *lb-reflect-test* (if (= k 7) :guard :hoho))
       (force-cmd *p1* :sp2))
      (9 (setup :yamamoto :base 10.0) (setf (brain-off (brain *p2*)) nil))
      ((10 11 12 13) (setf (lbs-eyes (lb *p1*)) (- k 10)))
      (20 (setup :lille :base 12.0 :cpu t)))
    (lille-probe-line (format nil "test ~d" k))))

(defun lille-reflect-test-step (e f)
  "Debug 79007 / 79008 (*LB-REFLECT-TEST*), from E's Trompete (F his fighter): the opponent's (CPU-off) brain presses guard
on Trompete's f54 and holds it, or Hoho on f52 (pressed at the end of the step before: a scripted reflector)."
  (let* ((o (opp-of e)) (b (brain o)) (sf (fighter-sf f)))
    (when b
      (cond ((and (eq *lb-reflect-test* :guard) (= sf 53)) (ai-press b :guard 200 :act :hold))
            ((and (eq *lb-reflect-test* :hoho) (= sf 51)) (ai-press b :step 1 :modded t :act :hoho))))))

(defun lille-debug (c)
  "His debug commands (debug.lisp *CHAR-DEBUG*, the range 79000-79999, docs/duel/DUEL_GAMEPLAY.md): 79000+k LILLE-TEST k."
  (cond ((< c 79100) (lille-test (- c 79000)))
        (t (log-msg "duel lille: no debug command ~d" c))))
(pushnew '(79000 79999 lille-debug) *char-debug* :test #'equal)

;;; ================================================================ batch 3b (2026-10-06): the HUD hooks, the cinematics, stills
;;; (DUEL_LILLE §9, §10, "Built: art, HUD, cinematics"). Cosmetic only: the art, the HUD and the cinematics' looks live in
;;; lille-art.lisp; this section hangs them on his kits (after DEFKIT) and holds the five scripts.

;; his kit meter (hud.lisp: the :draw row, the portrait :label, the BANKAI prompt renamed 「P  REVIVE」 in gold) and the HUD /
;; look hooks (:hud-guard MUJITTAI's jade outline, :deck the one-hand ring's eye ticks, :body-alpha MUJITTAI's see-through
;; column, :charge his muzzle glint instead of the fire charge), on every form. Not on the host (no lille-art there).
(when (fboundp 'lille-hud-meter)
  (let ((meter (list :name "ME" :max 3 :draw 'lille-hud-meter :label 'lille-hud-label
                     :bankai-prompt (list :key "P  REVIVE" :right "KP+  REVIVE" :pad "BACK  REVIVE" :one-hand "AWAKEN  REVIVE"
                                          :rgb (symbol-value '*c-lb-revive*)))))
    (dolist (form '(:base :jilliel :jilliel-mujittai :shin))
      (let ((k (find-kit :lille form)))
        (setf (kit-meter k) meter
              (kit-hooks k) (list* :hud-guard 'lille-hud-guard :deck 'lille-ring :body-alpha 'lille-body-alpha
                                   :charge 'lille-charge (kit-hooks k)))))))

;;; The cinematics (60 Hz, review-3 pacing: fewer, longer shots; unskippable; every shot SHOT-ON its subject). He wears
;;; white: the black card, the back-rim in his form's colour (jade, the owl's gold). Each script's looks are driven from
;;; its frame by LILLE-DRAW (lille-art.lisp: the wings unfolding, the jade turning gold, the trumpet forming), so a
;;; skipped or aborted script leaves nothing behind (CINE-END's REFRESH-LOOK restores his body).
(defcine lb-jilliel-cine (a v :len 186 :hold 90)
  "The awakening 神の裁き JILLIEL (§10.1, ch. 646): close on the face, the left eye shut under the mark, silence; the eye
opens (the third time), the mark flares jade, a 1 f negative; the black card, jade back-rim: 「三度も眼を開かされるとは 異端に
等しい」, then the brush 神の裁き / JILLIEL as he becomes the column; the cocoon: eight wings unfold one pair per 8 f, the
halo draws itself; from below, the winged column hovering, the opponent small."
  (at 0 (setf (model-body (model a)) (find-body :lille) (model-weapon (model a)) :diagramm)   ; the base face first
      (cine-clip a :lb-stance :blend 0) (cine-clip v (kit-stance (kit-of v)) :blend 6)   ; (no held pose: the
      (hold-pose v 12) (freeze 12) (impact-frame :negative 2) (silence 30)                  ; gameplay one is Jilliel's)
      (shot-on a 14 0.95 1.74 :look 1.72) (lens 36))
  (during (0 30) (shot-on a 14 (- 0.95 (* 0.12 u)) 1.74 :look 1.72))
  (at 30 (impact-frame :negative 1) (play-sfx :lb-lock) (play-sfx :hoho-out))
  (during (30 60) (shot-on a 14 (- 0.83 (* 0.13 u)) 1.74 :look 1.73))
  (at 60 (card :black a) (back-rim 60 0.61 0.77 0.67) (shot-on a 20 4.4 0.9 :look 1.3 :off 0.9) (lens 42)
      (caption "三度も眼を開かされるとは" :kanji2 "異端に等しい" :reading "SANDO MO ME WO HIRAKASARERU TO WA" :sub "ITAN NI HITOSHII"
               :side 0)
      (play-sfx :awaken-rise :pitch 0.8))
  (at 92 (setf (model-body (model a)) (find-body :lille-jilliel) (model-weapon (model a)) nil)
      (cine-clip a :lb-w-fold :blend 4) (impact-frame :negative 1) (play-sfx :awaken-boom)
      (caption "神の裁き" :reading "JILLIEL" :sub "VOLLSTANDIG" :side 0))
  (at 120 (card nil) (caption-exit) (shot-on a 32 3.6 1.4 :look 1.9) (lens 55) (cine-clip a :lb-w-stance :blend 12)
      (play-sfx :hoho-out))
  (at 128 (play-sfx :hoho-out)) (at 136 (play-sfx :hoho-out))
  (during (120 160) (shot-on a 32 (+ 3.6 (* 0.8 u)) 1.4 :look 1.9))
  (at 160 (shot-on a 165 6.5 0.25 :look 2.2) (lens 62)))

(defcine lb-kikon-cine (a v :len 168 :hold 90)
  "The base Kikon 万物貫通 (§10.2, ch. 601-602): beat 0, the aim held; over his shoulder down the barrel, the reticle (the
eye mark) closing round him, silence; the shot: the jade line through everything; on him: his silhouette on the white
card, a cross-shaped hole of light through it, held; the Konpaku shatter; the last card 万物貫通 / THE X-AXIS."
  (at 0 (face-each-other a v) (cine-clip a :lb-aim :blend 2) (cine-clip v :sh-bound :blend 4)
      (hold-both a v 10) (impact-frame :negative 2) (play-sfx :lb-lock))
  (at 10 (if (portrait-p)                       ; over his shoulder, the barrel (portrait: from straight behind and above,
             (shot-on a 162 5.4 2.6 :look 1.2 :ahead 2.5)  ; his back low in the tall frame, the line rising to the reticle)
             (shot-on a 152 2.7 1.9 :look 1.4 :ahead 2.2))
      (lens 40) (silence 50))
  (during (10 60) (vfx-lb-reticle-view v (- 1.0 (/ (- cf 10) 50.0))))
  (at 60 (cine-clip a :lb-fire :blend 1) (impact-frame :negative 2) (play-sfx :lb-crack) (shake 0.25 0.3))
  (during (60 76) (vfx-lb-shot-line a (- 1.0 (/ (- cf 60) 16.0))))
  (at 66 (shot-on v 20 3.2 1.25 :look 1.2) (lens 50) (cine-clip v :sh-kikon-victim :blend 3) (card :white v) (silhouette-black v))
  (during (66 120) (vfx-lb-cross-hole v (min 0.95 (/ (- cf 64) 6.0))))
  (at 72 (hold-both a v 44) (silence 44))
  (at 118 (impact-frame :negative 2) (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 2))
      (play-sfx :konpaku-shatter) (shake 0.2 0.3))
  (at 122 (unsilhouette) (card nil) (impact-frame :manga 10))
  (at 130 (card :black a) (back-rim 38 0.61 0.77 0.67) (shot-on a 20 4.2 0.9 :look 1.25 :off 0.9) (lens 42)
      (cine-clip a :lb-stance :blend 8)
      (caption "万物貫通" :reading "THE X-AXIS" :sub "BANBUTSU KANTSU  KIKON" :side 0)))

(defcine lb-revive-cine (a v :len 180 :hold 120)
  "The revival 真の姿 (§10.3, ch. 649-650): the headless column falls still, silence 30 f; it rises into the air, the jade
turning to gold over 30 f, and the owl head grows on the S-neck from light; the caption 「武器では死なず 霊圧で首を落としても
尚死なない」; the wide shot: four stilt legs, the small spiked halo, one long arm raised."
  (at 0 (setf (model-body (model a)) (find-body :lille-jilliel) (model-weapon (model a)) nil
              (model-hide (model a)) (hide-set '(:jl-head)))   ; beheaded
      (cine-clip a :lb-w-fold :blend 3) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (hold-both a v 30) (silence 30) (shot-on a 35 4.2 1.1 :look 1.3) (lens 50))
  (at 30 (cine-clip a :lb-rise :blend 6) (play-sfx :awaken-rise :pitch 0.6) (shot-on a 25 5.4 0.6 :look 2.1) (lens 55))
  (during (52 94) (multiple-value-bind (x y z) (actor-point a 2.95)
                    (vfx-lb-light x y z (* 0.28 (min 1.0 (/ (- cf 52) 12.0))) (if (< cf 82) 0.9 (* 0.9 (/ (- 94 cf) 12.0))))))
  (at 66 (setf (model-body (model a)) (find-body :lille-shin) (model-hide (model a)) nil)
      (cine-clip a :lb-o-stance :blend 10) (impact-frame :negative 1) (play-sfx :awaken-boom))
  (at 96 (card :black a) (back-rim 54 0.72 0.6 0.35) (shot-on a 20 5.4 1.3 :look 2.0 :off 0.9) (lens 42)
      (caption "武器では死なず" :kanji2 "霊圧で首を落としても尚死なない" :reading "BUKI DEWA SHINAZU" :sub "SHIN NO SUGATA" :side 0))
  (at 150 (card nil) (caption-exit) (shot-on a 28 7.5 0.6 :look 1.9) (lens 55) (cine-clip a :lb-o-reveal :blend 8)))

(defcine lb-jilliel-kikon-cine (a v :len 162 :hold 80)
  "The Jilliel Kikon 神の裁き (§10.4): beat 0, the wings aimed; the black card, 神の裁き / KAMI NO SABAKI, the 24 holes lit;
from the side, 24 jade lines out of the wings, the opponent pinned at their crossing; on him, held in silence; the
Konpaku shatter; the winged column."
  (at 0 (face-each-other a v) (cine-clip a :lb-w-aim :blend 2) (cine-clip v :sh-bound :blend 4)
      (hold-both a v 10) (impact-frame :negative 2) (play-sfx :awaken-rise))
  (at 10 (card :black a) (back-rim 50 0.61 0.77 0.67) (shot-on a 20 4.6 1.2 :look 1.8 :off 0.9) (lens 42)
      (caption "神の裁き" :reading "KAMI NO SABAKI" :sub "KIKON" :side 0))
  (at 60 (card nil) (caption-exit) (shot-on a 100 7.0 2.2 :look 1.6 :ahead 3.0) (lens 50) (play-sfx :lb-crack))
  (during (60 128) (vfx-lb-converge a v (min 0.95 (/ (- cf 58) 8.0))))
  (at 64 (cine-clip v :sh-kikon-victim :blend 3))
  (at 96 (shot-on v 25 3.4 1.4 :look 1.2) (lens 52) (hold-both a v 24) (silence 24))
  (at 120 (impact-frame :negative 2) (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3))
      (play-sfx :konpaku-shatter) (shake 0.25 0.35))
  (at 124 (impact-frame :manga 10))
  (at 132 (shot-on a 30 5.6 1.3 :look 1.7) (lens 50) (cine-clip a :lb-w-stance :blend 8)))

(defcine lb-trompete-cine (a v :len 186 :hold 90)
  "The owl Kikon 神の喇叭 (§10.4): beat 0, the fist at the beak, the note; the trumpet forming over him; the sound card,
神の喇叭 / TROMPETE, silence; the beam erases the horizon; the Konpaku shatter; and then there is silence."
  (at 0 (face-each-other a v) (cine-clip a :lb-o-trompete :blend 2) (cine-clip v :sh-bound :blend 4)
      (hold-both a v 10) (impact-frame :negative 2) (play-sfx :lb-trumpet))
  (at 10 (shot-on a 30 3.6 2.6 :look 2.4) (lens 50))
  (at 60 (card :black a) (back-rim 50 0.72 0.6 0.35) (shot-on a 62 6.0 1.6 :look 2.2 :off 0.9) (lens 42)
      (caption "神の喇叭" :reading "TROMPETE" :sub "KAMI NO RAPPA  KIKON" :side 0) (silence 50))
  (at 110 (card nil) (caption-exit) (shot-on a 118 9.0 3.0 :look 2.0 :ahead 8.0) (lens 60) (impact-frame :negative 2)
      (play-sfx :explode) (shake 0.4 0.5) (ui-flash 1.0 0.95 0.8 0.8 2.5))
  (during (110 150) (vfx-lb-horizon a (min 0.98 (- 1.6 (/ (- cf 110) 25.0)))))
  (at 116 (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 4)) (play-sfx :konpaku-shatter)
      (impact-frame :manga 10))
  (at 140 (silence 46) (shot-on a 30 8.5 1.0 :look 1.8) (lens 50) (cine-clip a :lb-o-stance :blend 10))
  (during (140 186) (setf *grade-desat* (min 0.5 (* 0.02 (- cf 140))))))

;;; stills and the consing probe (debug 79100-79199, DUEL_GAMEPLAY "Debug commands")
(defparameter *lb-cines* '(lb-jilliel-cine lb-kikon-cine lb-revive-cine lb-jilliel-kikon-cine lb-trompete-cine))
(defun lille-cine-at (i f)
  "Stills: cinematic I (*LB-CINES*) with P1 Lille 6 m from Kenpachi, in its form, held at frame F; when it already runs it
continues to F."
  (let ((name (nth i *lb-cines*)))
    (unless (and *cine* (eq (cine-name *cine*) name))
      (abort-cine)
      (setf *cine-hold* nil)
      (ensure-battle :lille :kenpachi) (place *p1* *p2* 6.0)
      (force-form *p1* (nth i '(:jilliel :base :shin :jilliel :shin)))
      (start-cine name *p1* *p2*))
    (when *cine* (setf *cine-hold* t (cine-hold *cine*) f))))

(defun lille-cons-probe ()
  "79195: bytes consed by 10 draws of his :draw hook, of each of his live hazards' looks and of his HUD meter, guard outline
and ring, in the running scene (a \"lille consing\" line; the scripts call it in each form and look)."
  (let* ((e *p1*) (kit (kit-of e)) (hz-n 0))
    (macrolet ((per (form) `(let ((c0 (cons-bytes))) (dotimes (i 10) ,form) (- (cons-bytes) c0))))
      (let ((draw (per (lille-draw e 0.016f0)))
            (looks (let ((c0 (cons-bytes)))
                     (dotimes (i 10) (do-entities (h (hz hazard)) (when (eql (hazard-owner hz) e) (incf hz-n) (lb-look hz 0.016f0))))
                     (- (cons-bytes) c0)))
            (meter (per (lille-hud-meter e kit 10.0 10.0 100.0 4.0 nil 1.0 nil nil nil)))
            (guard (per (lille-hud-guard e 10.0 10.0 100.0 4.0 nil 2 1.0)))
            (ring (per (lille-ring e 100.0 100.0 2.0))))
        (log-msg "lille consing (10 draws, B): form ~a draw ~d looks ~d (~d hazards) meter ~d guard ~d ring ~d"
                 (fighter-form (fighter e)) draw looks (floor hz-n 10) meter guard ring)
        (log-msg "lille consing reads (10 calls, B): fighter ~d pos ~d yaw ~d lb ~d alpha ~d eye-t ~d"   ; (an entity
                 (per (%lbt-fighter e)) (per (%lbt-pos e)) (per (%lbt-yaw e)) (per (%lbt-lb e)) (per (%lbt-alpha e)) ; lookup's cost)
                 (per (%lbt-eyet e)))))))

(defun lille-art-debug (c)
  "79100 + 19 i + k (k 0-18): cinematic i (*LB-CINES*) held at frame 10 k; 79195 his looks' consing (LILLE-CONS-PROBE);
79196 P1's eye opens now (its look: a pip spent, nothing dodged)."
  (let ((n (- c 79100)))
    (cond ((< n 95) (lille-cine-at (floor n 19) (* 10 (mod n 19))))
          ((= n 95) (lille-cons-probe))
          ((= n 96) (let ((st (lb *p1*)))                   ; a still of the eye opening (its look; nothing dodged)
                      (setf (lbs-eye-t st) *match-tick* (lbs-eyes st) (max 0 (1- (lbs-eyes st))))))
          (t (log-msg "duel lille: no debug command ~d" c)))))
(pushnew '(79100 79199 lille-art-debug) *char-debug* :test #'equal)
