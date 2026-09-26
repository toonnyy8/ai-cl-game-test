;;;; debug.lisp — developer tools (design-v1 §15). Module._debug_cmd(N) from the page / test scripts
;;;; (arguments are encoded in the integer); the first call turns the combat log and stats lines on.
;;;;   2000+s   seeded CPU vs CPU now, NORMAL, both characters drawn from seed s (s < 100)
;;;;   3000+s / 4000+s / 5000+s   the same with a fixed pairing: YY / YK (P1 Yama) / KK   (s < 1000)
;;;;   2100 skip every cinematic (toggle)     2101 next match starts with 2 Konpaku each (smoke run)
;;;;   2102 turbo: up to 120 steps per frame, no scene drawn (seed gates; toggle)
;;;;   2103 hitbox overlay   2104 CPU intent overlay   2105 CPUs off (toggle)   2106 perf log
;;;;   2107 dump both fighters (state, gauges) to the log    2108 fill both fighters' Reiatsu
;;;;   2109 toggle the CAMERA option (BEHIND / SIDE; the behind camera is VS CPU's)
;;;;   2120+k   perf: toggle drawing part k off (0 HUD, 1 fighters, 2 stage, 3 hazards + cine looks)
;;;;   2110+p   the seed gate: seeds 1..20 of pairing p (0 YY, 1 YK, 2 KK, 3 all three) back to back
;;;;            (turbo; cinematics play: they are part of the match time), then "duel gate ..." lines
;;;;   2200+k   force cinematic k now and hold it (0 Bankai, 1 Nozarashi, 2 Jokaku Enjo, 3 Tenchi Kaijin,
;;;;            4 Ken Kikon, 5 sky split, 6 Soul Break, 7 intro, 8 K.O.)   2209 a K.O. of P2 (YK), then RESULTS
;;;;   10000+1000k+f   stills: cinematic k (as 2200+k) held at frame f, the effects frozen there; when k already
;;;;            runs, it continues to frame f
;;;;   2300+k   force a special now (0 Hellfire + Ennetsu, 1 full Shiranui, 2 fire wave, 3 Kaka
;;;;            skeletons, 4 Kyokujitsujin, 5 Split the Meteor, 6 guard break, 7 perfect Hoho,
;;;;            8 Ken stance, 9 Buttagiru, 10 Ken SP2 flurry, 11 EVOLUTION both, 12 Bankai form (+ 2 crack patches),
;;;;            13 Nozarashi form, 14 P2 red)
;;;;   2315+k   frame probe, YY at 2 m: P1's move k (0 Q1, 1 Q3, 2 F2, 3 Taimatsu) into P2's held guard
;;;;            -> "duel probe ... advantage"; 2319 trade probe: both Q1 on the same tick -> hash line
;;;;   2320     Burst test: human P1 Yamamoto (3 bars) at 2 m from Kenpachi, whose idle CPU mashes Quick for
;;;;            60 steps (Q1 Q2 Q3): press Shift+J after the 2nd hit
;;;;   2321     force a Burst Reverse now: P1 (in Kenpachi's Q2 hitstun) bursts out (screenshots)
;;;;   2327     guard gauge test: human P1 Yamamoto 2 m from Kenpachi pressing Quick for 20 s (hold U): the
;;;;            gauge drains, GUARD CRUSH, hits land while U is held, the guard back only when full
;;;;   2328     consing of the new HUD gauge bars (100 draws each) -> "hud consing" line; the Bankai stances' looks
;;;;            (10 draws each) -> "vfx consing" line
;;;;   2329     consing of the brush captions (each layout, 100 draws) and the impact splash -> "brush consing" line
;;;;   2330+k   O module test: human P1 with module k mod 4 (0 ENJO, 1 TENCHI, 2 CHARGE, 3 LEAP) 1 m inside
;;;;            its reach from a Yamamoto CPU who (k div 4) 0 stands, 1 guards, 2 stands red, 3 guards red,
;;;;            4 plays (HARD), 5 stands, 0.1x slow motion 14 s (shots), 6 guards once hit (the dash-in is
;;;;            BLOCKED), 7 red and guards once hit (the Kikon anyway); the script holds O
;;;;   2326     force a clash now (Breaker vs Breaker: YK 3 m apart, the CLASH event; screenshots)
;;;;   2370+k   Bankai stance tests (human P1; the script presses the keys; STANCE-TEST): 0 L switch + cooldown (East,
;;;;            idle Kenpachi 3 m), 1 East into a guard kept full (recoil -> BURNOUT, then the guard drops),
;;;;            2 West under Kenpachi's Quick mash (armour -> BURNOUT), 3 / 4 East Shift+K into a guard at 2 / 6 m,
;;;;            5 West parry (Kenpachi's F1 comes when the parry starts), 6 South cast on an idle Kenpachi 3 m,
;;;;            7 / 8 human Kenpachi under a CPU's South at 5 m (7 normal speed, 8 0.25x slow motion 6 s)
;;;;   2600+k   *RED-THRESHOLD* = k % (pacing the seed gate without a rebuild)
;;;;   2400 god (both fighters' Reishi is topped back up to 400 every frame; Kikon still lands)   2500+k human P1 vs an
;;;;            idle CPU (k: 0 Yama vs Ken, 1 Ken vs Yama, 2 Yama vs Yama, 3 Ken vs Ken)
;;;; Log lines: "duel -> STATE" (flow.lisp), "duel hash t=N ..." every 600 battle ticks (h = CPU heat),
;;;; "duel -> RESULTS winner ..." (flow.lisp), CLOG combat lines "[tick] ...".
(in-package :duel)

(defvar *turbo* nil "Debug 2102: fast-forward (many steps per frame, scene not drawn).")
(defvar *hitboxes* nil)
(defvar *intents* nil)
(defvar *god* nil)
(defvar *no-draw* (make-array 4 :initial-element nil) "Debug 2120+k: skip drawing part k (perf bisection).")

(defun state-hash-line ()
  "The determinism hash: positions quantized to cm, facing to 0.01 rad, every gauge (f flash-step,
g guard gauge, ! = guardless)."
  (with-output-to-string (s)
    (format s "duel hash t=~d" *match-tick*)
    (dolist (e (list *p1* *p2*))
      (let ((p (pos-of e)) (g (gauges e)) (f (fighter e)))
        (format s " | ~d ~d ~d ~d ~a ~a r~d k~d a~d f~d g~d~:[~;!~] w~d m~d~@[ h~d~]" (round (* 100 (aref p 0))) (round (* 100 (aref p 1)))
                (round (* 100 (aref p 2))) (round (* 100 (yaw-of e))) (fighter-state f) (fighter-form f)
                (gauges-reishi g) (gauges-konpaku g) (round (gauges-reiatsu g)) (round (gauges-fs g)) (round (gauges-gg g))
                (gauges-guardless g) (round (gauges-awaken g))
                (round (gauges-meter g)) (and (brain e) (floor (brain-heat (brain e)))))))
    (format s " | cd ~{~d~^.~} ~{~d~^.~} | haz ~d" (coerce (fighter-cd (fighter *p1*)) 'list) (coerce (fighter-cd (fighter *p2*)) 'list)
            (let ((n 0)) (do-entities (h hazard) (incf n)) n))))

(defun hash-log ()
  (when (and (eq *flow* :battle) (plusp *match-tick*) (zerop (mod *match-tick* 600)))
    (log-msg "~a" (state-hash-line))))

(defvar *probe* nil "A running frame probe: (kind name t0 attacker-free defender-free blocked).")

(defun probe-block (name)
  "Frame probe: P1 (YY, 2 m) starts move NAME into P2's held guard; PROBE-UPDATE logs the advantage."
  (ensure-battle :yamamoto :yamamoto)
  (place *p1* *p2* 2.0)
  (setf (fighter-state (fighter *p2*)) :guard (fighter-guard-t (fighter *p2*)) 30
        (brain-press (brain *p2*)) :guard (brain-press-left (brain *p2*)) 999)   ; off: held
  (start-move *p1* (kit-move (kit-of *p1*) name))
  (setf *probe* (list :block name *match-tick* nil nil nil)))

(defun probe-trade ()
  "Trade probe: YY at 2 m, both start Q1 on the same step; 40 steps later the hash line."
  (ensure-battle :yamamoto :yamamoto)
  (place *p1* *p2* 2.0)
  (dolist (e (list *p1* *p2*)) (start-move e (kit-move (kit-of e) :ya-q1)))
  (setf *probe* (list :trade :ya-q1 *match-tick* nil nil nil)))

(defun probe-mash ()
  "Burst test (2320): human P1 at 2 m from P2, whose (switched off) CPU mashes Quick (PROBE-UPDATE)."
  (ensure-battle :yamamoto :kenpachi)
  (place *p1* *p2* 2.0)
  (setf (gauges-reiatsu (gauges *p1*)) *reiatsu-max*)
  (setf *probe* (list :mash :quick *match-tick* nil nil nil)))

(defun force-burst ()
  "P1 Yamamoto, 2 hits into Kenpachi's string, bursts out now."
  (ensure-battle :yamamoto :kenpachi)
  (place *p1* *p2* 2.0)
  (setf (gauges-reiatsu (gauges *p1*)) *reiatsu-max*)
  (start-move *p2* (kit-move (kit-of *p2*) :ke-q2))
  (setf (fighter-sf (fighter *p2*)) 9)
  (set-reaction *p1* :flinch 18 (aref (pos-of *p2*) 0) (aref (pos-of *p2*) 2) 0.0)
  (setf (fighter-combo-hits (fighter *p1*)) 2)
  (burst! *p1*))

(defparameter *module-tests* '((:yamamoto :base) (:yamamoto :bankai-east) (:kenpachi :base) (:kenpachi :nozarashi))
  "The O (Kikon rush) modules by form: ENJO, TENCHI, CHARGE, LEAP CLEAVE.")

(defun module-test (k)
  "O module test (2330+k): human P1 with module (mod K 4) (0 ENJO, 1 TENCHI, 2 CHARGE, 3 LEAP) 1 m inside
its reach from a Yamamoto CPU who, by (floor K 4): 0 stands (a held O hits: the knockback, the dash-in,
the Kikon), 1 holds guard (blocked), 2 stands red (the same, the Kikon), 3 holds guard red (the first strike
blocked: no Kikon), 4 is
switched on at HARD (it guards the follow-up by its roll), 5 as 0 in 0.1x slow motion for 8 s (shots),
6 stands and holds guard from the moment the strike hits him (the dash-in's strike is BLOCKED), 7 the same
red (it can't be guarded: the Kikon).
The script holds O (or taps it)."
  (destructuring-bind (c form) (nth (mod k 4) *module-tests*)
    (ensure-battle c :yamamoto)
    (force-form *p1* form)
    (let* ((mv (kit-command-move (kit-of *p1*) :kikon))
           (reach (max (mv-reach mv) (kikon-rush-reach (rush-param mv :speed) (rush-param mv :dash-max)))))
      (place *p1* *p2* (- reach 1.0)))
    (fill (fighter-cd (fighter *p1*)) 0)
    (when (<= 20 k 23) (slowmo 0.1 14.0))
    (when (>= k 24) (setf *probe* (list :guard-after nil *match-tick* nil nil nil)))
    (let ((v (floor k 4)) (g (gauges *p2*)) (b (brain *p2*)))
      (setf (gauges-reishi g) (if (member v '(2 3 7)) 200 (gauges-reishi-max g))
            (gauges-gg g) *gg-max* (gauges-guardless g) nil
            (brain-off b) (/= v 4) (brain-difficulty b) :hard (brain-delay b) (getf *ai-delay* :hard)
            (brain-press b) :guard (brain-press-mod b) nil (brain-press-left b) (if (member v '(1 3)) 999 0)))))

(defun probe-pressure ()
  "Guard gauge test (2327): human P1 Yamamoto 2 m from Kenpachi, whose switched-off CPU presses Quick
every other step for 20 s (Q strings into the guard), both put back 2 m apart whenever Kenpachi is free
beyond 2.6 m (PROBE-UPDATE). Hold Guard (U) throughout: the gauge drains 28 per blocked Q string, the
4th string GUARD CRUSHes, the next hits land although U is held, and the guard comes back only when the
gauge is full again (60 f + 7.1 s)."
  (ensure-battle :yamamoto :kenpachi)
  (place *p1* *p2* 2.0)
  (setf (gauges-gg (gauges *p1*)) *gg-max* (gauges-guardless (gauges *p1*)) nil)
  (setf *probe* (list :pressure :quick *match-tick* nil nil nil)))

(defparameter *stance-tests*
  ;; k: P1 P1-form P2 P2-form distance
  '((:yamamoto :bankai-east :kenpachi :base 3.0) (:yamamoto :bankai-east :kenpachi :base 2.0)
    (:yamamoto :bankai-west :kenpachi :base 2.0) (:yamamoto :bankai-east :kenpachi :base 2.0)
    (:yamamoto :bankai-east :kenpachi :base 6.0) (:yamamoto :bankai-west :kenpachi :base 2.5)
    (:yamamoto :bankai-east :kenpachi :base 3.0) (:kenpachi :base :yamamoto :bankai-east 5.0)
    (:kenpachi :base :yamamoto :bankai-east 5.0)))

(defun stance-test (k)
  "Bankai stance test 2370+K (*STANCE-TESTS*: the pair, forms, distance): human P1, P2's CPU off. 1 and 2 run
a probe (:wall, :armour: PROBE-UPDATE); 3 and 4 hold P2's guard; 5 baits the parry (:parry-bait); 7 / 8 make
P2 cast South at once."
  (destructuring-bind (c1 f1 c2 f2 d) (nth k *stance-tests*)
    (ensure-battle c1 c2)
    (force-form *p1* f1) (force-form *p2* f2)
    (place *p1* *p2* d)
    (dolist (e (list *p1* *p2*))
      (let ((g (gauges e)))
        (fill (fighter-cd (fighter e)) 0)
        (setf (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) *fs-max* (gauges-gg g) *gg-max* (gauges-guardless g) nil
              (gauges-reishi g) (gauges-reishi-max g))))
    (let ((b (brain *p2*)))
      (setf (brain-press b) :guard (brain-press-mod b) nil (brain-press-left b) (if (member k '(1 3 4)) 999 0)))
    (case k
      (1 (setf *probe* (list :wall nil *match-tick* nil nil nil)))
      (2 (setf *probe* (list :armour :quick *match-tick* nil nil nil)))
      (5 (setf *probe* (list :parry-bait nil *match-tick* nil nil nil)))
      ((7 8) (when (= k 8) (slowmo 0.25 6.0)) (force-cmd *p2* :sp2)))))

(defun probe-update ()
  "Per step: finish a running probe (the first tick each side is free again = both idle; the
difference is the frame advantage, measured the way the fighters really step); the mash test's
presses (J down every other step: the switched-off brain still writes its held button)."
  (when *probe*
    (destructuring-bind (kind name t0 af df blocked) *probe*
      (let ((dt (- *match-tick* t0)))
        (case kind
          (:mash (let ((b (brain *p2*)))
                   (setf (brain-press b) :quick (brain-press-mod b) nil (brain-press-left b) (if (evenp dt) 1 0))
                   (when (> dt 60) (setf (brain-press-left b) 0 *probe* nil))))
          (:trade
            (when (>= dt 40) (log-msg "duel probe trade ~a: ~a" name (state-hash-line)) (setf *probe* nil)))
          (:wall (let ((b (brain *p2*)) (g1 (gauges *p1*)) (g2 (gauges *p2*)))   ; P2's guard kept full: P1's recoil
                   (if af                                              ; burned out: guard 120 f more, then drop it
                       (setf (brain-press-left b) (if (< (- *match-tick* af) 120) 999 0))
                       (setf (gauges-gg g2) *gg-max* (gauges-guardless g2) nil))
                   (when (and (not af) (burnout-p *p1*)) (setf (fourth *probe*) *match-tick*))
                   (when (and (member (state-of *p2*) '(:idle :guard)) (> (fighter-dist (fighter *p2*)) 2.6)
                              (member (state-of *p1*) '(:idle :guard)))
                     (place *p1* *p2* 2.0)
                     (setf (brain-press b) :guard (fighter-guard-t (fighter *p2*)) 30)
                     (log-msg "duel probe wall t=~d P1 gg ~d~:[~; BURNOUT~] P2 r~d" dt (round (gauges-gg g1)) (burnout-p *p1*)
                              (gauges-reishi g2)))
                   (when (> dt 1500) (setf (brain-press-left b) 0 *probe* nil))))
          (:armour (let ((b (brain *p2*)) (g1 (gauges *p1*)))   ; Kenpachi mashes Quick into West's armour
                     (setf (brain-press b) :quick (brain-press-mod b) nil (brain-press-left b) (if (evenp dt) 1 0))
                     (when (and (eq (state-of *p2*) :idle) (> (fighter-dist (fighter *p2*)) 2.6) (member (state-of *p1*) '(:idle :guard)))
                       (place *p1* *p2* 2.0)
                       (log-msg "duel probe armour t=~d P1 gg ~d~:[~; BURNOUT~] r~d" dt (round (gauges-gg g1)) (burnout-p *p1*)
                                (gauges-reishi g1)))
                     (when (> dt 600) (setf (brain-press-left b) 0 *probe* nil))))
          (:parry-bait (let ((f1 (fighter *p1*)))       ; P1's parry starts: Kenpachi's F1 is already on its way
                         (when (and (eq (fighter-state f1) :move) (member :parry (mv-flags (fighter-move f1))) (<= (fighter-sf f1) 1)
                                    (not (eq (state-of *p2*) :move)))
                           (start-move *p2* (kit-command-move (kit-of *p2*) :f))
                           (setf (fighter-sf (fighter *p2*)) 10))
                         (when (> dt 1200) (setf *probe* nil))))
          (:guard-after (when (eq (state-of *p2*) :stun)          ; hit: hold guard from now on
                          (let ((b (brain *p2*))) (setf (brain-press b) :guard (brain-press-left b) 999 *probe* nil))))
          (:pressure (let ((b (brain *p2*)))
                       (setf (brain-press b) :quick (brain-press-mod b) nil (brain-press-left b) (if (evenp dt) 1 0))
                       (when (and (eq (state-of *p2*) :idle) (> (fighter-dist (fighter *p2*)) 2.6)
                                  (member (state-of *p1*) '(:idle :guard)))
                         (let ((g1 (gauges *p1*)))
                           (place *p1* *p2* 2.0)
                           (log-msg "duel probe pressure t=~d gg ~d~:[~; guardless~]" dt (round (gauges-gg g1)) (gauges-guardless g1))))
                       (when (> dt 1200) (setf (brain-press-left b) 0 *probe* nil))))
          (t
            (progn
              (when (eq (state-of *p2*) :guard-hit) (setf blocked t))
              (when (and (not af) (member (state-of *p1*) '(:idle :guard))) (setf af dt))
              (when (and blocked (not df) (member (state-of *p2*) '(:idle :guard))) (setf df dt))
              (setf *probe* (list kind name t0 af df blocked))
              (cond ((and af df)
                     (log-msg "duel probe ~a blocked: attacker free at +~d, defender at +~d, advantage ~@d (table ~@d)"
                              name af df (- df af) (mv-adv-block (kit-move (kit-of *p1*) name)))
                     (setf *probe* nil))
                    ((> dt 300) (log-msg "duel probe ~a: no block" name) (setf *probe* nil))))))))))

(defun brush-cons-check ()
  "2329: bytes consed by 100 draws of each brush caption layout (drawn past their stamp: the steady state), of the
screen punctuation with an impact splash and of a brush Latin line (callouts, big words)."
  (let* ((w (window-width)) (h (window-height))
         (cine (make-bcap "天地灰尽" :kanji2 "残火の太刀" :mark "北" :reading "TENCHI KAIJIN" :sub "KITA" :hanko t))
         (card (make-bcap "卍解" :reading "BANKAI" :ink t))
         (call (make-bcap "火火十万億死大葬陣" :mark "南" :reading "MINAMI" :layout :callout :side 1 :secs 100.0))
         (res (make-bcap "勝" :layout :results)))
    (dolist (c (list cine card call res)) (setf (aref (bcap-f c) 0) (f32 (- (fx-clock) 1.0))))
    (dotimes (i 2) (dolist (c (list cine card call res)) (draw-bcap c w h)))   ; the splash arguments boxed once
    (impact-splash 0.0 0.0 0.0 60)
    (macrolet ((per (name form)
                 `(let ((c0 (cons-bytes))) (dotimes (i 100) ,form) (format nil "~a ~d" ,name (- (cons-bytes) c0)))))
      (log-msg "brush consing (100 draws, B): ~{~a~^, ~}"
               (list (per "cine" (draw-bcap cine w h)) (per "card" (draw-bcap card w h)) (per "callout" (draw-bcap call w h))
                     (per "results" (draw-bcap res w h)) (per "splash" (draw-screen-fx w h))
                     (progn (set-line 300 300 40 '(1 1 1 1)) (setf (aref *bl* 7) (line-width "GUARD BREAK"))
                            (per "line" (brush-line "GUARD BREAK")))
                     (per "roll" (%roll-up (camera-up *camera*) *cam-eye* *cam-at* 8f0)))))
    (v3-set! (camera-up *camera*) 0f0 1f0 0f0)
    (setf (aref *screen-fx* 7) 0f0)))

(defun hud-cons-check ()
  "2328: bytes consed by 100 draws of each HUD gauge bar added with the gauges (guard, flash-step, cooldowns) and
by 10 draws of each Bankai stance look (0 B each; the crossfade only while it runs)."
  (let ((c0 (cons-bytes)))
    (dotimes (i 100) (%hud-guard 10f0 10f0 300f0 6f0 0.4f0 0.6f0 nil nil 1f0) (%hud-guard 10f0 10f0 300f0 6f0 0.4f0 0.6f0 t t 1f0))
    (let ((c1 (cons-bytes)))
      (dotimes (i 100) (%hud-flash 10f0 30f0 300f0 6f0 0.8f0 nil t 1f0) (%hud-flash 10f0 30f0 300f0 6f0 0.8f0 t nil 1f0))
      (let ((c2 (cons-bytes)))
        (dotimes (i 100) (%hud-cd 10f0 50f0 150f0 6f0 0.4f0 0f0 nil 1f0 0.5f0 0.2f0) (%hud-cd 10f0 50f0 150f0 6f0 1f0 0.7f0 t 1f0 0.5f0 0.2f0))
        (log-msg "hud consing: 100 x 2 guard bars ~d B, 100 x 2 flash-step bars ~d B, 100 x 2 cooldown bars ~d B"
                 (- c1 c0) (- c2 c1) (- (cons-bytes) c2)))))
  ;; the Bankai stances' per-frame looks (10 draws each; particles emitted too): burned-out aura and blade,
  ;; West's flame garb, the bound ash, the heat sheet, South's crack, the aura crossfade (DRAW-AURA); and
  ;; the Phase-3 :heat aura for comparison
  (macrolet ((per (name form)
               `(let ((c0 (cons-bytes))) (dotimes (i 10) ,form) (format nil "~a ~d" ,name (- (cons-bytes) c0)))))
    (log-msg "vfx consing (10 draws, B): ~{~a~^, ~}"
             (list (per "ash" (vfx-aura 0f0 0f0 0f0 1.8f0 :ash 1f0 0.016f0))
                   (per "garb" (vfx-aura 0f0 0f0 0f0 1.8f0 :garb 1f0 0.016f0))
                   (per "bound" (vfx-aura 0f0 0f0 0f0 1.8f0 :bound 1f0 0.016f0))
                   (per "heat(old)" (vfx-aura 0f0 0f0 0f0 1.8f0 :heat 1f0 0.016f0))
                   (per "blade-ash" (vfx-blade-embers 0f0 1f0 0f0 0f0 1.8f0 -0.5f0 0.016f0 :ash t))
                   (per "blade(old)" (vfx-blade-embers 0f0 1f0 0f0 0f0 1.8f0 -0.5f0 0.016f0))
                   (per "kyoku" (vfx-line-cut 0f0 0f0 0f0 -9f0 0.2f0 0.67f0 :kyoku :dt 0.016f0))
                   (per "south" (vfx-line-cut 0f0 0f0 0f0 -1.2f0 0.1f0 0.93f0 :south :dt 0.016f0))
                   (per "enjo(old)" (vfx-line-cut 0f0 0f0 0f0 -9f0 0.2f0 0.67f0 :enjo :dt 0.016f0))
                   (let ((f (fighter *p1*)))
                     (format nil "~a, ~a" (per "aura crossfading" (draw-aura f (if (evenp i) :garb :heat) 0f0 0f0 0f0 1.8f0 1f0 0.016f0 1.0))
                             (progn (setf (aref *aura-t* (fighter-side f)) (f32 (- (fx-clock) 5.0)))   ; settled
                                    (per "aura settled" (draw-aura f :heat 0f0 0f0 0f0 1.8f0 1f0 0.016f0 1.0)))))))))

(defun god-update ()
  (when *god*
    (dolist (e (list *p1* *p2*))
      (when (entity-alive-p e) (setf (gauges-reishi (gauges e)) (max (gauges-reishi (gauges e)) 400))))))

;;; ---------------------------------------------------------------- scenario helpers
(defun ensure-battle (c1 c2 &key cpu)
  "A battle with P1 = C1, P2 = C2 (CPUs when CPU), cinematics skipped into the fight."
  (unless (and (eq *flow* :battle) (eq (fighter-character (fighter *p1*)) c1) (eq (fighter-character (fighter *p2*)) c2))
    (setf *picks* (list c1 c2) *mode* (if cpu :cpu-cpu :vs-cpu))
    (let ((*skip-cines* t)) (start-match))
    (setf (brain-off (brain *p2*)) (not cpu))
    (when (brain *p1*) (setf (brain-off (brain *p1*)) (not cpu)))))

(defun place (a b dist)
  "A and B DIST metres apart on the x axis around the centre, facing, idle; no hazards, no particles."
  (clear-hazards) (fx-clear) (time-reset) (setf *punch-t* 0.0)
  (dolist (e (list a b)) (setf (model-flash (model e)) 0f0 (model-super (model e)) 0f0))
  (v3-set! (pos-of a) (f32 (* -0.5 dist)) 0f0 0f0) (v3-set! (pos-of b) (f32 (* 0.5 dist)) 0f0 0f0)
  (face-each-other a b)
  (dolist (e (list a b)) (to-idle e 0) (setf (fighter-lock (fighter e)) 0)))

(defun force-cmd (e cmd)
  "Start kit command CMD on E now, whatever the gauges say."
  (setf (gauges-reiatsu (gauges e)) *reiatsu-max*)
  (let ((f (fighter e))) (to-idle e 0) (try-command e f cmd (getf '(:sp1 :flash :sp2 :sig :sig :sig :breaker :breaker) cmd))))

(defun force-form (e form)
  (set-form e form)
  (when (kit-awakening (kit-of e)) (setf (gauges-awakened (gauges e)) t)))

(defun force-cine (k)
  (setf *cine-hold* nil)
  (case k
    (0 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 5.0) (force-form *p1* :bankai-east)
       (start-cine 'yama-bankai-cine *p1* *p2*))
    (1 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 5.0) (force-form *p1* :nozarashi)
       (start-cine 'ken-nozarashi-cine *p1* *p2*))
    (2 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 3.0) (start-cine 'yama-kikon-cine *p1* *p2*))
    (3 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 3.0) (force-form *p1* :bankai-east)
       (start-cine 'yama-tenchi-cine *p1* *p2*))
    (4 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 3.0) (start-cine 'ken-kikon-cine *p1* *p2*))
    (5 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 3.0) (force-form *p1* :nozarashi)
       (start-cine 'ken-sky-split-cine *p1* *p2*))
    (6 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 3.0) (start-cine 'soul-break-cine *p1* *p2*))
    (7 (start-match))
    (8 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 3.0) (start-cine 'ko-cine *p1* *p2*)))
  (setf *cine-hold* t)
  (when *cine* (setf (cine-hold *cine*) (cine-hold-frame (cine-name *cine*)))))

(defparameter *cine-names* '(yama-bankai-cine ken-nozarashi-cine yama-kikon-cine yama-tenchi-cine ken-kikon-cine
                               ken-sky-split-cine soul-break-cine intro-cine ko-cine)
  "FORCE-CINE's numbering.")

(defun cine-at (k f)
  "Debug 10000 + 1000 K + F (stills): cinematic K held at frame F (MAIN.LISP CINE-HELD-P freezes the effects there);
when K already runs, it continues to F."
  (unless (and *cine* (eq (cine-name *cine*) (nth k *cine-names*)))
    (abort-cine)                                         ; another one held: its looks (card, grade) end first
    (force-cine k))
  (when *cine* (setf *cine-hold* t (cine-hold *cine*) f)))

(defun force-special (k)
  (setf *cine-hold* nil)
  (case k
    (0 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 5.0)
       (setf (gauges-meter (gauges *p1*)) *inferno-max*))               ; the gauge step turns it into Hellfire
    (1 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 10.0) (force-cmd *p1* :sp1))
    (2 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 9.0) (force-cmd *p1* :sig))
    (3 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 5.0) (force-form *p1* :bankai-east) (force-cmd *p1* :sp2))
    (4 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 6.0) (force-form *p1* :bankai-east) (force-cmd *p1* :sp1))
    (5 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 7.0) (force-form *p1* :nozarashi) (force-cmd *p1* :sp1))
    (6 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 3.5)
       (setf (fighter-state (fighter *p2*)) :guard (fighter-guard-t (fighter *p2*)) 30)
       (setf (brain-press (brain *p2*)) :guard (brain-press-left (brain *p2*)) 120)   ; off: held
       (force-cmd *p1* :breaker))
    (7 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 2.4) (force-cmd *p2* :f)
       (let ((f (fighter *p1*))) (setf (fighter-sf (fighter *p2*)) 9) (start-hoho *p1* f)))
    (8 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 4.0) (force-cmd *p1* :sig))
    (9 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 5.0) (force-cmd *p1* :sp1))
    (10 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 5.0) (force-cmd *p1* :sp2))
    (11 (dolist (e (list *p1* *p2*)) (setf (gauges-awaken (gauges e)) *awaken-max*)))
    (12 (ensure-battle :yamamoto :kenpachi) (force-form *p1* :bankai-east)            ; + the reveal's cracks (yama-bankai-cine)
        (let ((p (pos-of *p1*)))
          (stage-crack-add (aref p 0) (aref p 2) 3.0) (stage-crack-add (+ (aref p 0) 3.5) (- (aref p 2) 2.0) 2.2)))
    (13 (ensure-battle :kenpachi :yamamoto) (force-form *p1* :nozarashi))
    (14 (setf (gauges-reishi (gauges *p2*)) 200))))

(defun start-cvc (seed pair)
  "Seeded CPU vs CPU (NORMAL): PAIR = (c1 c2), or NIL to draw both from SEED."
  (setf *match-seed* seed *mode* :cpu-cpu *difficulty* :normal)
  (sim-rnd-seed seed)
  (setf *picks* (or pair (list (nth (floor (* (length *roster*) (sim-rnd01))) *roster*)
                               (nth (floor (* (length *roster*) (sim-rnd01))) *roster*))))
  (start-match))

(defvar *gate* nil "Seed gate: (seed pair) matches still to run.")
(defvar *gate-results* nil "(pair secs ko-p) of the finished gate matches.")
(defparameter *pairs* '((:yamamoto :yamamoto) (:yamamoto :kenpachi) (:kenpachi :kenpachi)))

(defun start-gate (p)
  (setf *turbo* t *skip-cines* nil *combat-log* nil *gate-results* nil
        *gate* (loop for pair in (if (= p 3) *pairs* (list (nth p *pairs*)))
                     append (loop for seed from 1 to 20 collect (list seed pair))))
  (gate-update))

(defvar *gate-busy* nil "A gate match is running.")

(defun gate-update ()
  "Per frame: record a finished gate match, start the next, summarise at the end."
  (when (and *gate-busy* (eq *flow* :results))
    (push (list *picks* (/ *match-tick* 60.0)
                (or (zerop (gauges-konpaku (gauges *p1*))) (zerop (gauges-konpaku (gauges *p2*)))))
          *gate-results*)
    (setf *gate-busy* nil))
  (unless *gate-busy*
    (cond (*gate* (destructuring-bind (seed pair) (pop *gate*) (start-cvc seed pair)) (setf *gate-busy* t))
          (*gate-results*
           (dolist (pair *pairs*)
             (let* ((rs (remove pair *gate-results* :key #'first :test-not #'equal))
                    (secs (sort (mapcar #'second rs) #'<)))
               (when secs
                 (log-msg "duel gate ~a ~a: ~d matches, KOs ~d, median ~,1f s, min ~,1f, max ~,1f | ~{~,0f~^ ~}"
                          (first pair) (second pair) (length secs) (count-if #'third rs)
                          (nth (floor (length secs) 2) secs) (first secs) (car (last secs)) secs))))
           (setf *gate-results* nil *turbo* nil)))))

(defun debug-command (c)
  "Module._debug_cmd(C): see the file header."
  (setf *combat-log* t *stats-log* t)
  (log-msg "debug cmd ~d" c)
  (unless (or (<= 2200 c 2299) (<= 10000 c 19999)) (setf *cine-hold* nil))
  (cond ((<= 2000 c 2099) (start-cvc (- c 2000) nil))
        ((<= 3000 c 3999) (start-cvc (- c 3000) '(:yamamoto :yamamoto)))
        ((<= 4000 c 4999) (start-cvc (- c 4000) '(:yamamoto :kenpachi)))
        ((<= 5000 c 5999) (start-cvc (- c 5000) '(:kenpachi :kenpachi)))
        ((= c 2100) (setf *skip-cines* (not *skip-cines*)) (when *skip-cines* (skip-cine)))
        ((= c 2101) (setf *konpaku-start* 2))
        ((= c 2102) (setf *turbo* (not *turbo*)))
        ((= c 2103) (setf *hitboxes* (not *hitboxes*)))
        ((= c 2104) (setf *intents* (not *intents*)))
        ((= c 2105) (do-entities (e (b brain)) (setf (brain-off b) (not (brain-off b)))))
        ((= c 2106) (setf *perf-log* (not *perf-log*)))
        ((= c 2107) (when (entity-alive-p *p1*) (log-msg "~a" (state-hash-line))))
        ((= c 2108) (dolist (e (list *p1* *p2*)) (setf (gauges-reiatsu (gauges e)) *reiatsu-max*)))
        ((= c 2109) (toggle-cam))
        ((<= 2110 c 2113) (start-gate (- c 2110)))
        ((<= 2120 c 2123) (setf (svref *no-draw* (- c 2120)) (not (svref *no-draw* (- c 2120)))))
        ((= c 2209) (setf *cine-hold* nil) (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 3.0) (match-over *p1*))
        ((<= 2200 c 2299) (force-cine (- c 2200)))
        ((<= 10000 c 19999) (cine-at (floor (- c 10000) 1000) (mod c 1000)))
        ((<= 2315 c 2318) (probe-block (nth (- c 2315) '(:ya-q1 :ya-q3 :ya-f2 :ya-taimatsu))))
        ((= c 2319) (probe-trade))
        ((= c 2320) (probe-mash))
        ((= c 2321) (force-burst))
        ((= c 2327) (probe-pressure))
        ((= c 2328) (hud-cons-check))
        ((= c 2329) (brush-cons-check))
        ((<= 2330 c 2361) (module-test (- c 2330)))
        ((<= 2370 c 2378) (stance-test (- c 2370)))
        ((= c 2326) (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 3.0) (clash! *p1* *p2*))
        ((<= 2300 c 2399) (force-special (- c 2300)))
        ((= c 2400) (setf *god* (not *god*)))
        ((<= 2600 c 2699) (setf *red-threshold* (/ (- c 2600) 100.0)))
        ((<= 2500 c 2503)
         (setf *picks* (nth (- c 2500) '((:yamamoto :kenpachi) (:kenpachi :yamamoto) (:yamamoto :yamamoto) (:kenpachi :kenpachi)))
               *mode* :vs-cpu *match-seed* 1)
         (let ((*skip-cines* t)) (start-match))
         (setf (brain-off (brain *p2*)) t))))

;;; ---------------------------------------------------------------- overlays
(defun draw-hitboxes ()
  "Hurt cylinders (green), open melee windows (red: the move's volumes, DRAW-VOL, and a reach line),
hazards (orange)."
  (flet ((ring (x y z r cr cg cb) (draw-circle x y z r cr cg cb :segments 12 :width 0.015 :alpha 0.9)))
    (dolist (e (list *p1* *p2*))
      (let* ((p (pos-of e)) (b (model-body (model e))) (f (fighter e)) (mv (fighter-move f)))
        (ring (aref p 0) (+ 0.05 (aref p 1)) (aref p 2) (body-hurt-r b) 0.2 1.0 0.3)
        (ring (aref p 0) (+ (aref p 1) (body-hurt-h b)) (aref p 2) (body-hurt-r b) 0.2 1.0 0.3)
        (when (and mv (eq (fighter-state f) :move) (eq (fighter-phase f) :main))
          (loop for w across (mv-hits mv)
                when (and (<= (hw-from w) (fighter-sf f)) (< (fighter-sf f) (hw-to w)))
                  do (let* ((yaw (yaw-of e)) (r (mv-reach mv)))
                       (fx-line (aref p 0) 1.0 (aref p 2) (+ (aref p 0) (* r (fwd-x yaw))) 1.0 (+ (aref p 2) (* r (fwd-z yaw)))
                                0.04 1.0 0.1 0.1 1.0)
                       (dolist (v (hw-vols w)) (draw-vol v (aref p 0) (aref p 1) (aref p 2) yaw)))))))
    (do-entities (h (hz hazard))
      (when (hazard-hw hz) (ring (hazard-x hz) 1.0 (hazard-z hz) (max 0.3 (hazard-size hz)) 1.0 0.6 0.1)))))

(defun debug-hud (w h s)
  (declare (ignore h))
  (when (and *intents* (member *flow* '(:battle)))
    (dolist (e (list *p1* *p2*))
      (let ((b (brain e)) (v *hud-v*) (p (pos-of e)))
        (when (and b (world-to-screen v (aref p 0) 2.7 (aref p 2)))
          (ui-text (format nil "~a ~a H~d" (brain-intent b) (or (brain-act b) "") (floor (brain-heat b)))
                   (aref v 0) (aref v 1) :scale s :align :center :color '(0.5 1 0.6 1) :shadow t)))))
  (when *turbo*
    (ui-text (format nil "TURBO  T ~d  ~a" *match-tick* *flow*) (* 0.5 w) (* 40 s) :scale (* 2 s) :align :center :color '(0.5 1 0.6 1))))
