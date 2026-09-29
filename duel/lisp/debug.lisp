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
;;;;   2110+p   the seed gate: seeds 1..20 of pairing p (0 YY, 1 YK, 2 KK, 3 all six: + RY RK RR) back to back
;;;;            (turbo; cinematics play: they are part of the match time), then "duel gate ..." lines
;;;;   2200+k   force cinematic k now and hold it (0 Bankai, 1 Nozarashi, 2 Jokaku Enjo, 3 Tenchi Kaijin,
;;;;            4 Ken Kikon, 5 sky split, 6 Soul Break, 7 intro, 8 K.O.)   2209 a K.O. of P2 (YK), then RESULTS
;;;;            9 Ken Bankai (P1 in the Bankai), 10 MAPPUTATSU (2210)
;;;;   10000+1000k+f   stills: cinematic k (as 2200+k) held at frame f, the effects frozen there; when k already
;;;;            runs, it continues to frame f
;;;;   2300+k   force a special now (0 Hellfire + Ennetsu, 1 full Shiranui, 2 fire wave, 3 Kaka
;;;;            skeletons, 4 Kyokujitsujin, 5 Split the Meteor, 6 guard break, 7 perfect Hoho,
;;;;            8 Ken stance, 9 Buttagiru, 10 Ken SP2 flurry, 11 EVOLUTION both, 12 Bankai form (+ 2 crack patches),
;;;;            13 Nozarashi form (cup 1), 14 P2 red, 15 cup 2 RYOTE, 16 cup 3 NOMIHOSE)
;;;;   2315+k   frame probe, YY at 2 m: P1's move k (0 J1, 1 K3, 2 J3, 3 Taimatsu) into P2's held guard
;;;;            -> "duel probe ... advantage"; 2319 trade probe: both Q1 on the same tick -> hash line
;;;;   2320     Burst test: human P1 Yamamoto (3 bars) at 2 m from Kenpachi, whose idle CPU mashes Quick for
;;;;            60 steps (J1 J2 J3): press Shift+J after the 2nd hit
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
;;;;   2370+k   Bankai stance tests (human P1; the script presses the keys; STANCE-TEST): 0 East vs an idle Kenpachi
;;;;            3 m (KYOKKO, U to West, SHONETSU JIGOKU, J drops to East), 1 East's J strings into a guard kept full (the
;;;;            pierce's chip), 2 West's ward under Kenpachi's Quick mash (no blockstun, 28 a string, GUARD CRUSH on the
;;;;            4th -> East), 3 / 4 East Shift+K into a guard at 2 / 6 m,
;;;;            5 West parry (Kenpachi's F1 comes when the parry starts; P1's gauge at 40: the catch refills it), 6 South
;;;;            cast on an idle Kenpachi 3 m, 7 / 8 human Kenpachi under a CPU's South at 5 m (7 normal speed, 8 0.25x slow
;;;;            motion 6 s), 9 West's ward vs ranged hits (the :ranged probe: cup-3 Kenpachi at 4.8 m casts the rift twice,
;;;;            the cash-out, then cup 1's Meteor, then the Meteor again at 3 m)
;;;;   2380+k   Nozarashi v2 / West ward tests (human P1, P2's CPU off; NOME-TEST): 0 the ladder (NOME raised +12 every
;;;;            45 steps to 100, then left to drain: cups up, then down), 1 DRINK (cup 3, Bankai East mashes Quick into
;;;;            his held U), 2 / 3 KUKAN-GIRI's rift into a guard / a standing Yamamoto (K, K K), 4 the cash-out (cup 3,
;;;;            Shift+K into a red Yamamoto's guard at 4 m, then O held: the Kikon is worth 2), 5 West's ward under
;;;;            RYOTE's K K (the cut, x*WARD-MULT*: 53 of his guard gauge per string, GUARD CRUSH on the 2nd)
;;;;   2362+k   Phase 5 looks (force-special 62+k): 0 Taimatsu (YK 4.5 m), 1 Nadegiri (Hellfire, 5 m), 2 Yamamoto's
;;;;            Breaker (Ikkotsu, 6 m), 3 Kenpachi drinks cup 3 dry on entry (the NOMIHOSE rung event: the grin beat)
;;;;   2390     consing of the Phase 5 per-frame looks (10 draws each) -> "vfx5 consing" line
;;;;   2366     Phase 6 destruction still: YK 4 m apart, a scorch under Kenpachi, a crack and a burst of chips beside him;
;;;;            Yamamoto shouts and Kenpachi is hurt (face beats: both gameplay face accents)
;;;;   2391     consing of the Phase 6 per-frame looks (10 draws each) -> "vfx6 consing" line
;;;;   2392     the left fist's gap to the cleaver's handle over the grip clips and their transitions, raw and with GRIP-LEFT!
;;;;            (P1 must be Kenpachi, e.g. after 2315 or 2383) -> "grip drift" line
;;;;   2114+p   the seed gate of 2110+p with the combat log and a pace line every 60 ticks (scratchpad pace.py)
;;;;   2600+k   *RED-THRESHOLD* = k % (pacing the seed gate without a rebuild)
;;;;   20000+k / 21000+k / 22000+k / 23000+k   balance knobs without a rebuild (the Bankai rework's gate tuning):
;;;;            *WARD-MULT* / *PIERCE-MAX* = k / 100, *GG-REGEN* / *GG-REGEN-GUARDLESS* = k / 10
;;;;   2393     the string test: the fighters of the running match 2.2 m apart, facing, idle, nothing held (scripts: a
;;;;            string + the O ender, e.g. duel-touch.json)
;;;;   2394+k   the string test (docs/DUEL_STRINGS.md): human P1 in form k (0 Yamamoto Shikai, 1 Bankai East, 2 Kenpachi
;;;;            base, 3 RYOTE) 2.2 m from an idle Kenpachi (CPU off; East with his guard gauge at 30: KOSEI x2.4); the
;;;;            script presses J / K / O (duel-strings.json)
;;;;   24000+k / 25000+k / 26000+k   the strings' gate knobs without a rebuild: *AI-O-ENDER* = k / 100, NORMAL's
;;;;            *AI-FOLLOW-GUARD-P* = k / 100, every K2 / K3 (and copy) deals k % of its written damage;
;;;;            27000+k *KOSEI-REIATSU* = k / 100 (and *KOSEI-FS* half that), 28000+k *AI-STRING-FLASH-P* = k / 100,
;;;;            29000+k *AI-SP-CANCEL-P* = k / 100
;;;;   2700+k   portrait presentation (docs/DUEL_MOBILE_DESIGN.md P2): 0 the framing / text probe on (every 30th battle
;;;;            frame off a cinematic: both fighters' upper halves clear of the two HUD blocks, >= 70 % of each one's width on
;;;;            the screen; the smallest pixel-font
;;;;            glyph drawn) and its "duel frame ..." line now; 1 the fighters 24 m apart; 2 P2 flashed to P1's side
;;;;            (90 deg, 4 m: the camera's catch-up); 3 1 m apart; 4 consing of the portrait camera, dolly and HUD column
;;;;            (100 calls each) -> "portrait consing" line
;;;;   35000+f / 36000+f   stills of the Bankai cinematic / MAPPUTATSU held at frame f (as 10000+1000k+f, k 9 / 10)
;;;;   2386+k   Kenpachi's Bankai tests (docs/DUEL_KEN_BANKAI.md; BANKAI-TEST): 0 cup 3 + red 3 m from an idle Yamamoto (P
;;;;            enters), 1 in the Bankai at once 2.2 m, 2 the Bankai with 1 pip left, 3 片腕
;;;;   30000+k  the seed gate plays seeds k+1 .. k+20;  31000+10a+b the CPUs' Bankai entry, P1 a / P2 b: 0 the kit's rule,
;;;;            1 always (whenever allowed), 2 never, 3 the rule with its chance 1 (the gamble A/B);
;;;;            32000+k *ARM-SELF* = k, 33000+k *ARM-BURST-SELF* = k, 34000+k *ARM-CRACK* = k; 37000+k the cup-3 CPU's
;;;;            Bankai chance :p = k / 100, 38000+k its :own-konpaku = k
;;;;   Rukia (docs/DUEL_RUKIA.md): 6000+s / 7000+s / 8000+s seeded CPU vs CPU RY / RK / RR (P1 Rukia); 2118 the seed gate of
;;;;            her three pairings (RY RK RR; 2113 now plays all six), 2119 RY and RK only, 2125+k pairing k alone (0 YY 1 YK
;;;;            2 KK 3 RY 4 RK 5 RR: the gate in parallel), 2124 2118 with the combat log
;;;;            (the pacing log); 2410+k her tests (RUKIA-TEST: human P1 Rukia, P2's CPU
;;;;            off): 0 Shikai 5 m from Kenpachi, 1 -18 C 2.2 m, 2 -50 C 2.2 m, 3 zero 1.8 m, Kenpachi's J1 into the ward (the
;;;;            freeze-touch), 4 zero, Yamamoto's full Shiranui from 7 m (optic: it hits), 5 zero, Kenpachi's Breaker from 5 m
;;;;            (the CRACK), 6 zero, the same Breaker answered by REIDO TOKETSU within 5.5 m (a counter-hit), 7 zero left to
;;;;            warm out (-50 after ~2.9 s), 8 zero 3 m from him (hold U: braced until the guard gauge runs out, the CRACK);
;;;;            2420+k K -> L (RUKIA-KL-TEST, *KL-TESTS*: 0 Shikai, 1 -18, 2 -50, 3 zero, 4 -18 short of L's cold, 5 / 6 Shikai /
;;;;            -18 into a held guard): "duel probe kl" lines per hit, his stun frames left before it; 72000+k / 73000+k her
;;;;            CPU's :l-after-k = k / 100 in the Shikai / the three bands; 68001 the white Rukia's lashes dark again (the before still); 2430+k the portrait
;;;;            HUD review (HUD-REVIEW, *HUD-REVIEW*: both sides in given forms and gauges, CPUs off);
;;;;            40000+f / 41000+f / 42000+f stills of her Kikon / 白霞罸 / awakening cinematics held at frame f
;;;;            (as 10000+1000k+f, k 11 / 12 / 13; 2211-2213 force them); 39000+10a+b the CPUs' awakening, P1 a / P2 b: 0 the
;;;;            kit's :awaken rule, 1 always on EVOLUTION, 2 never (the A/B); knobs 43000+k *FROST-SLOW* = k / 100, 44000+k
;;;;            *ZERO-BRACE-DRAIN* = k / 10 per s, 45000+k *FREEZE-TOUCH* = k, 46000+k *RU-COOL-RATE* = k per s, 47000+k
;;;;            *CRACK-SELF* = k, 48000+k zero's damage x k / 100, 49000+k the awakening rule's :melee-share = k / 100,
;;;;            50000+k the -18 / -50 CPU's :cool chance = k / 100, 51000+k *RU-THAW-LOCK* = k frames,
;;;;            53000+k the :cool distance k / 10 m, 54000+k the Shikai CPU's ZONE intent weight k, 55000+k zero's warming
;;;;            k / 10 per s, 56000+k / 57000+k the -50 / -18 walk k / 10 m/s, 58000+k the Shikai's damage x k / 100,
;;;;            60000+k the Shikai's damage taken x k / 100, 61000+k the bands' (-18 k / 100, -50 x0.9, zero x0.889 of it),
;;;;            62000+k *RU-BLOCK-COOL* = k / 100, 63000+k *RU-HIT-WARM* = k / 100, 65000+k zero's field :away = k / 100,
;;;;            66000+k *FIELD-FLOOR* = k / 100, 67000+k P1's cold = k (0-200) and its band (review stills); 68000 the
;;;;            white Rukia's bodies rebuilt with the old ink keyline and hair-coloured brows (before / after stills);
;;;;            69000+f / 70000+f a close-up of the white Rukia's face at zero / in the 白霞罸 costume; 71000 Kenpachi's
;;;;            reiatsu opaque <-> see-through (*REIATSU-GLASS*, before / after stills), 71001+k human P1 Kenpachi in cup
;;;;            k+1 (4: the Bankai) 3 m from an idle Yamamoto. Every gate row is followed by a "duel band" line per awakened Rukia side
;;;;            (BAND-ACC: frames, damage dealt / taken per band, zero visits and their exits, bracing frames, freeze-touches)
;;;;   2400 god (both fighters' Reishi is topped back up to 400 every frame; Kikon still lands)   2500+k human P1 vs an
;;;;            idle CPU (k: 0 Yama vs Ken, 1 Ken vs Yama, 2 Yama vs Yama, 3 Ken vs Ken)
;;;; Log lines: "duel -> STATE" (flow.lisp), "duel hash t=N ..." every 600 battle ticks (h = CPU heat),
;;;; "duel -> RESULTS winner ..." (flow.lisp), CLOG combat lines "[tick] ...".
(in-package :duel)

(defvar *turbo* nil "Debug 2102: fast-forward (many steps per frame, scene not drawn).")
(defvar *hitboxes* nil)
(defvar *intents* nil)
(defvar *god* nil)
(defvar *gate-log* nil "Debug 2114+p: the seed gate keeps the combat log and logs a pace line every 60 ticks.")
(defvar *no-draw* (make-array 4 :initial-element nil) "Debug 2120+k: skip drawing part k (perf bisection).")

(defun state-hash-line ()
  "The determinism hash: positions quantized to cm, facing to 0.01 rad, every gauge (f flash-step,
g guard gauge, ! = guardless, m the kit meter: Inferno / NOME), n the Konpaku the last Kikon rush was worth."
  (with-output-to-string (s)
    (format s "duel hash t=~d" *match-tick*)
    (dolist (e (list *p1* *p2*))
      (let ((p (pos-of e)) (g (gauges e)) (f (fighter e)))
        (format s " | ~d ~d ~d ~d ~a ~a r~d k~d a~d f~d g~d~:[~;!~] w~d m~d~@[ u~d~]~:[~;*~] n~d~@[ fr~d~]~@[ h~d~]" (round (* 100 (aref p 0))) (round (* 100 (aref p 1)))
                (round (* 100 (aref p 2))) (round (* 100 (yaw-of e))) (fighter-state f) (fighter-form f)
                (gauges-reishi g) (gauges-konpaku g) (round (gauges-reiatsu g)) (round (gauges-fs g)) (round (gauges-gg g))
                (gauges-guardless g) (round (gauges-awaken g))
                (round (gauges-meter g)) (and (or (kit-pips (fighter-kit f)) (getf (kit-meter (fighter-kit f)) :temp))   ; the arm's
                                              (gauges-meter-idle g))                            ; crack clock / Rukia's warm clock,
                (gauges-arm-pending g)                                                          ; * = its burst pending
                (fighter-kikon-n f) (and (plusp (fighter-frost f)) (fighter-frost f))           ; fr = frost left (Rukia's ice)
                (and (brain e) (floor (brain-heat (brain e)))))))
    (format s " | cd ~{~d~^.~} ~{~d~^.~} | haz ~d" (coerce (fighter-cd (fighter *p1*)) 'list) (coerce (fighter-cd (fighter *p2*)) 'list)
            (let ((n 0)) (do-entities (h hazard) (incf n)) n))))

(defvar *band-acc* (vector (make-array 18 :element-type 'fixnum :initial-element 0)
                           (make-array 18 :element-type 'fixnum :initial-element 0))
  "Per side, the cold bands' pacing (debug only: never read by the sim): frames, damage dealt and taken per band (-18
-50 zero: 0-2, 3-5, 6-8), zero visits (9), exits by CRACK (10) and by spending / warming (11), bracing frames (12),
freeze-touches (13), the last dealt / taken totals (14 15), the last band (16: -1 none) and freeze-touch flag (17).")

(defun band-acc-reset ()
  (dotimes (i 2) (let ((a (svref *band-acc* i))) (fill a 0) (setf (aref a 16) -1))))

(defun band-acc-step ()
  "Per battle step outside cinematics: every awakened Rukia side's band bookkeeping (BAND-ACC-LINE logs it)."
  (when (and (eq *flow* :battle) (not *cine*) (entity-alive-p *p1*) (entity-alive-p *p2*))
    (dolist (e (list *p1* *p2*))
      (let* ((f (fighter e)) (a (svref *band-acc* (fighter-side f))) (g (gauges e)) (go (gauges (opp-of e)))
             (b (position (fighter-form f) '(:m18 :m50 :zero))) (last (aref a 16))
             (d (- (gauges-dealt g) (aref a 14))) (tk (- (gauges-dealt go) (aref a 15))))
        (setf (aref a 14) (gauges-dealt g) (aref a 15) (gauges-dealt go))
        (when b
          (incf (aref a b)) (incf (aref a (+ 3 b)) d) (incf (aref a (+ 6 b)) tk)
          (when (and (= b 2) (/= last 2)) (incf (aref a 9)))
          (when (and (= last 2) (/= b 2)) (incf (aref a (if (and (= b 0) (plusp (gauges-meter-idle g))) 10 11))))
          (when (and (= b 2) (vpad-down (pilot-vpad (pilot e)) :guard)) (incf (aref a 12)))
          (when (and (gauges-froze g) (zerop (aref a 17))) (incf (aref a 13))))
        (setf (aref a 16) (or b -1) (aref a 17) (if (gauges-froze g) 1 0))))))

(defun band-acc-line ()
  "The gate row's companion: a \"duel band\" line per side that was awakened Rukia."
  (dotimes (i 2)
    (let ((a (svref *band-acc* i)))
      (when (plusp (+ (aref a 0) (aref a 1) (aref a 2)))
        (log-msg "duel band seed ~d P~d vs ~a frames ~d ~d ~d dealt ~d ~d ~d taken ~d ~d ~d visits ~d crack ~d exit ~d brace ~d ft ~d"
                 *match-seed* (1+ i) (fighter-character (fighter (if (zerop i) *p2* *p1*)))
                 (aref a 0) (aref a 1) (aref a 2) (aref a 3) (aref a 4) (aref a 5) (aref a 6) (aref a 7) (aref a 8)
                 (aref a 9) (aref a 10) (aref a 11) (aref a 12) (aref a 13))))))

(defvar *cup-acc* (vector (make-array 15 :element-type 'fixnum :initial-element 0)
                          (make-array 15 :element-type 'fixnum :initial-element 0))
  "Per side, Kenpachi's NOME cups (debug only: never read by the sim): frames in KATATE / RYOTE / NOMIHOSE / BANKAI /
KATAUDE (0-4), rung changes 1->2 (5), 2->3 (6), 3->2 (7), 2->1 (8), 3->1 (9: the cash-out), frames at > 4.2 m in cup 2
/ 3 (10 11), frames guarding (or drinking) in cup 2 / 3 (12 13), the last form (14: -1 none).")

(defun cup-acc-reset ()
  (dotimes (i 2) (let ((a (svref *cup-acc* i))) (fill a 0) (setf (aref a 14) -1))))

(defun cup-acc-step ()
  "Per battle step outside cinematics: every Kenpachi side's cup bookkeeping (CUP-ACC-LINE logs it)."
  (when (and (eq *flow* :battle) (not *cine*) (entity-alive-p *p1*) (entity-alive-p *p2*))
    (dolist (e (list *p1* *p2*))
      (let* ((f (fighter e)) (a (svref *cup-acc* (fighter-side f)))
             (c (and (eq (fighter-character f) :kenpachi)
                     (position (fighter-form f) '(:nozarashi :ryote :nomihose :bankai :kataude))))
             (last (aref a 14)))
        (when c
          (incf (aref a c))
          (let ((k (cond ((and (= last 0) (= c 1)) 5) ((and (= last 1) (= c 2)) 6) ((and (= last 2) (= c 1)) 7)
                         ((and (= last 1) (= c 0)) 8) ((and (= last 2) (= c 0)) 9))))
            (when k (incf (aref a k))))
          (when (<= 1 c 2)
            (when (> (fighter-dist f) 4.2) (incf (aref a (+ 9 c))))
            (when (member (fighter-state f) '(:guard :guard-hit)) (incf (aref a (+ 11 c))))))
        (setf (aref a 14) (or c -1))))))

(defun cup-acc-line ()
  "The gate row's companion: a \"duel cups\" line per side that was awakened Kenpachi."
  (dotimes (i 2)
    (let ((a (svref *cup-acc* i)))
      (when (plusp (+ (aref a 0) (aref a 1) (aref a 2) (aref a 3) (aref a 4)))
        (log-msg "duel cups seed ~d P~d vs ~a frames ~{~d~^ ~} up12 ~d up23 ~d dn32 ~d dn21 ~d cash ~d far ~d ~d guard ~d ~d"
                 *match-seed* (1+ i) (fighter-character (fighter (if (zerop i) *p2* *p1*)))
                 (coerce (subseq a 0 5) 'list) (aref a 5) (aref a 6) (aref a 7) (aref a 8) (aref a 9)
                 (aref a 10) (aref a 11) (aref a 12) (aref a 13))))))

(defun hash-log ()
  (band-acc-step)
  (cup-acc-step)
  (when (and (eq *flow* :battle) (plusp *match-tick*) (zerop (mod *match-tick* 600)))
    (log-msg "~a" (state-hash-line)))
  (when (and *gate-log* (eq *flow* :battle) (plusp *match-tick*) (zerop (mod *match-tick* 60)))   ; pace.py reads these
    (log-msg "pace t=~d~{ ~a~}" *match-tick*
             (loop for e in (list *p1* *p2*) for g = (gauges e)
                   collect (format nil "| ~a m~d r~d g~d~:[~;!~] k~d w~d" (fighter-form (fighter e)) (round (gauges-meter g))
                                   (gauges-reishi g) (round (gauges-gg g)) (gauges-guardless g) (gauges-konpaku g)
                                   (round (gauges-awaken g)))))))

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
  (dolist (e (list *p1* *p2*)) (start-move e (kit-move (kit-of e) :ya-j1)))
  (setf *probe* (list :trade :ya-j1 *match-tick* nil nil nil)))

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
  (start-move *p2* (kit-move (kit-of *p2*) :ke-j2))
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
    (:kenpachi :base :yamamoto :bankai-east 5.0) (:yamamoto :bankai-west :kenpachi :nomihose 4.8)))

(defun stance-test (k)
  "Bankai stance test 2370+K (*STANCE-TESTS*: the pair, forms, distance): human P1, P2's CPU off. 1, 2 and 9 run
a probe (:wall, :ward, :ranged: PROBE-UPDATE); 3 and 4 hold P2's guard; 5 baits the parry (:parry-bait, P1's guard
gauge at 40); 7 / 8 make P2 cast South at once; 9: P2 is a cup-3 Kenpachi (NOME 100)."
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
      (2 (setf *probe* (list :ward :quick *match-tick* nil nil nil)))
      (9 (setf (gauges-meter (gauges *p2*)) 100f0 (gauges-meter-idle (gauges *p2*)) 0
               *probe* (list :ranged nil *match-tick* nil nil nil)))
      (5 (setf *probe* (list :parry-bait nil *match-tick* nil nil nil) (gauges-gg (gauges *p1*)) 40f0))
      ((7 8) (when (= k 8) (slowmo 0.25 6.0)) (force-cmd *p2* :sp2)))))

(defparameter *nome-tests*
  ;; k: P1 P1-form P2 P2-form distance P1-NOME
  '((:kenpachi :nozarashi :yamamoto :base 4.0 38.0) (:kenpachi :nomihose :yamamoto :bankai-east 2.0 100.0)
    (:kenpachi :nomihose :yamamoto :base 3.0 100.0) (:kenpachi :nomihose :yamamoto :base 3.0 100.0)
    (:kenpachi :nomihose :yamamoto :base 4.0 100.0) (:yamamoto :bankai-west :kenpachi :ryote 2.5 0.0)))

(defun nome-test (k)
  "Nozarashi v2 test 2380+K (*NOME-TESTS*): human P1, P2's CPU off; the script presses the keys. 0 runs the :nome
probe (the ladder), 1 the :drink probe (P2 mashes Quick), 2 / 4 hold P2's guard, 4 makes P2 red, 5 the :cut probe
(P2, RYOTE, presses K K into West's held U)."
  (destructuring-bind (c1 f1 c2 f2 d m) (nth k *nome-tests*)
    (setf *probe* nil)                                   ; (a probe still running from the test before)
    (ensure-battle c1 c2)
    (force-form *p1* f1) (force-form *p2* f2)
    (place *p1* *p2* d)
    (dolist (e (list *p1* *p2*))
      (let ((g (gauges e)))
        (fill (fighter-cd (fighter e)) 0)
        (setf (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) *fs-max* (gauges-gg g) *gg-max* (gauges-guardless g) nil
              (gauges-reishi g) (gauges-reishi-max g) (gauges-meter-idle g) 0)))
    (setf (gauges-meter (gauges *p1*)) (f32 m) (gauges-meter (gauges *p2*)) (if (= k 5) 70f0 0f0))
    (when (= k 4) (setf (gauges-reishi (gauges *p2*)) 200))
    (let ((b (brain *p2*)))
      (setf (brain-press b) :guard (brain-press-mod b) nil (brain-press-left b) (if (member k '(2 4)) 999 0)))
    (case k
      (0 (setf *probe* (list :nome nil *match-tick* nil nil nil)))
      (1 (setf *probe* (list :drink :quick *match-tick* nil nil nil)))
      (5 (setf *probe* (list :cut :flash *match-tick* nil nil nil))))))

(defun bankai-test (k)
  "Kenpachi's Bankai tests 2386+K (docs/DUEL_KEN_BANKAI.md; human P1 Kenpachi, P2 an idle Yamamoto CPU; the script presses
the keys; his Konpaku at most *BANKAI-KONPAKU*, the entry's condition): 0 cup 3 (NOME 100), red (300), 3 m: P enters
the Bankai (its cinematic); 1 in the Bankai at once (no cinematic), 2.2 m: KKK, a whiffed K, JJJ ...; 2 in the Bankai
with 1 pip, 2.2 m: the 4th strike, then the burst; 3 片腕 at 2.2 m."
  (setf *probe* nil)
  (ensure-battle :kenpachi :yamamoto)
  (force-form *p1* :nomihose)
  (place *p1* *p2* (if (zerop k) 3.0 2.2))
  (let ((g (gauges *p1*)))
    (fill (fighter-cd (fighter *p1*)) 0)
    (setf (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) *fs-max* (gauges-gg g) *gg-max* (gauges-guardless g) nil
          (gauges-meter g) 100f0 (gauges-meter-idle g) 0 (gauges-reishi g) 300 (gauges-arm-pending g) nil
          (gauges-konpaku g) (min (gauges-konpaku g) *bankai-konpaku*)))   ; the entry: <= 4 Konpaku (2026-09-28)
  (setf (gauges-reishi (gauges *p2*)) (gauges-reishi-max (gauges *p2*)))
  (case k
    ((1 2) (let ((*skip-cines* t)) (bankai! *p1*))
     (when (= k 2) (setf (gauges-meter (gauges *p1*)) 1f0) (refresh-look *p1*))
     (place *p1* *p2* 2.2))
    (3 (force-form *p1* :kataude) (setf (gauges-reishi (gauges *p1*)) 900))))

(defparameter *rukia-tests*
  ;; k: P1-form P2 P2-form distance
  '((:base :kenpachi :base 5.0) (:m18 :kenpachi :base 2.2) (:m50 :kenpachi :base 2.2) (:zero :kenpachi :base 1.8)
    (:zero :yamamoto :base 7.0) (:zero :kenpachi :base 5.0) (:zero :kenpachi :base 5.0) (:zero :kenpachi :base 4.0)
    (:zero :kenpachi :base 3.0)))

(defun rukia-test (k)
  "Rukia's tests 2410+K (*RUKIA-TESTS*; human P1 Rukia, P2's CPU off): 3 P2's J1 into the ward (the freeze-touch), 4 P2's
full Shiranui (optic), 5 P2's Breaker (the CRACK), 6 the Breaker answered by REIDO TOKETSU when it is within 5.5 m, 7
zero left to warm out, 8 zero 3 m from him (hold U: braced to the CRACK). A :rukia probe logs \"duel probe rukia ...\" lines (form, state, Reishi, P2's state) every 10 f."
  (destructuring-bind (f1 c2 f2 d) (nth k *rukia-tests*)
    (setf *probe* nil)
    (ensure-battle :rukia c2)
    (force-form *p1* (if (eq f1 :zero) :m50 f1)) (force-form *p2* f2)
    (place *p1* *p2* d)
    (dolist (e (list *p1* *p2*))
      (let ((g (gauges e)))
        (fill (fighter-cd (fighter e)) 0)
        (setf (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) *fs-max* (gauges-gg g) *gg-max* (gauges-guardless g) nil
              (gauges-reishi g) (gauges-reishi-max g) (gauges-meter g) 0f0 (gauges-meter-idle g) 0)))
    (setf (gauges-meter (gauges *p1*)) (case f1 (:m50 150f0) (:zero *cold-max*) (t 0f0)))   ; the band's cold
    (when (eq f1 :zero) (force-form *p1* :zero))
    (setf *probe* (list :rukia k *match-tick* nil nil nil))
    (let ((b (brain *p2*)))                             ; (the switched-off brain still writes its held button)
      (case k
        (3 (force-cmd *p2* :q))
        (4 (force-cmd *p2* :sp1) (setf (brain-press b) :flash (brain-press-mod b) t (brain-press-left b) 70))
        ((5 6) (force-cmd *p2* :breaker) (setf (brain-press b) :breaker (brain-press-mod b) nil (brain-press-left b) 60))))))

(defparameter *kl-tests* '((:base 0 nil) (:m18 60 nil) (:m50 150 nil) (:zero 200 nil) (:m18 10 nil) (:base 0 t) (:m18 60 t))
  "K -> L (2420+k): P1-form, its cold, P2 guarding. 4: -18 with 10 cold, short of L's 25 (refused); 5 / 6 blocked.")

(defun rukia-kl-test (k)
  "2420+k: human P1 Rukia (*KL-TESTS* k) 2.2 m from an idle Kenpachi (holding guard in 5 / 6); a :kl probe logs each hit
P2 takes: its reaction, his stun frames left just before it (> 0: a combo), the combo count, P1's move and cold."
  (destructuring-bind (form cold guard) (nth k *kl-tests*)
    (setf *probe* nil)
    (ensure-battle :rukia :kenpachi)
    (force-form *p1* (if (eq form :zero) :m50 form)) (force-form *p2* :base)
    (place *p1* *p2* 2.2)
    (dolist (e (list *p1* *p2*))
      (let ((g (gauges e)))
        (fill (fighter-cd (fighter e)) 0)
        (setf (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) *fs-max* (gauges-gg g) *gg-max* (gauges-guardless g) nil
              (gauges-reishi g) (gauges-reishi-max g) (gauges-meter g) 0f0 (gauges-meter-idle g) 0)))
    (setf (gauges-meter (gauges *p1*)) (f32 cold))
    (when (eq form :zero) (force-form *p1* :zero))
    (when guard
      (setf (fighter-state (fighter *p2*)) :guard (fighter-guard-t (fighter *p2*)) 30
            (brain-press (brain *p2*)) :guard (brain-press-left (brain *p2*)) 999))
    (setf *probe* (list :kl k *match-tick* 0 0 nil))))

(defparameter *hud-review*
  ;; P1 (character form meter) P2 (character form meter) low-gauge: the portrait HUD's last row in every form (stills)
  '(((:yamamoto :base 60) (:kenpachi :base 0) nil) ((:yamamoto :hellfire 0) (:kenpachi :nozarashi 20) t)
    ((:yamamoto :bankai-east 0) (:kenpachi :ryote 70) nil) ((:yamamoto :bankai-west 0) (:kenpachi :nomihose 100) t)
    ((:kenpachi :bankai 3) (:yamamoto :base 100) nil) ((:kenpachi :kataude 0) (:rukia :base 0) t)
    ((:rukia :base 0) (:rukia :m18 60) nil) ((:rukia :m50 150) (:rukia :zero 200) t) ((:rukia :m18 30) (:kenpachi :base 0) :evo)))

(defun hud-review (k)
  "2430+k: *HUD-REVIEW* k: P1 and P2 in those forms with those kit meters, CPUs off, 3 m apart, the gauges part-full
(LOW: the guard gauges at 30, the KOSEI tag; :EVO P1's EVOLUTION announced)."
  (destructuring-bind ((c1 f1 m1) (c2 f2 m2) low) (nth k *hud-review*)
    (setf *probe* nil)
    (ensure-battle c1 c2)
    (place *p1* *p2* 3.0)
    (loop for e in (list *p1* *p2*) for f in (list f1 f2) for m in (list m1 m2)
          do (let ((g (gauges e)))
               (unless (eq (fighter-form (fighter e)) f) (force-form e f))
               (setf (gauges-meter g) (f32 m) (gauges-meter-idle g) 0 (gauges-reiatsu g) (* 1.6 *reiatsu-bar*)
                     (gauges-fs g) (* 0.6 *fs-max*) (gauges-awaken g) (if (kit-awakening (kit-of e)) 0f0 45f0)
                     (gauges-gg g) (if low 30f0 80f0) (gauges-reishi g) (round (* 0.7 (gauges-reishi-max g))))
               (when (eq low :evo) (setf (gauges-evolution (gauges *p1*)) t (gauges-awaken (gauges *p1*)) 100f0))))))

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
          (:wall (let ((b (brain *p2*)) (g1 (gauges *p1*)) (g2 (gauges *p2*)))   ; P2's guard kept full: East's pierce
                   (setf (gauges-gg g2) *gg-max* (gauges-guardless g2) nil)      ; chips through it
                   (when (and (member (state-of *p2*) '(:idle :guard)) (> (fighter-dist (fighter *p2*)) 2.6)
                              (member (state-of *p1*) '(:idle :guard)))
                     (place *p1* *p2* 2.0)
                     (setf (brain-press b) :guard (fighter-guard-t (fighter *p2*)) 30)
                     (log-msg "duel probe wall t=~d P1 gg ~d P2 r~d" dt (round (gauges-gg g1)) (gauges-reishi g2)))
                   (when (> dt 900) (setf (brain-press-left b) 0 *probe* nil))))
          (:ward (let ((b (brain *p2*)) (g1 (gauges *p1*)))   ; Kenpachi mashes Quick into West's ward
                   (setf (brain-press b) :quick (brain-press-mod b) nil (brain-press-left b) (if (evenp dt) 1 0))
                   (when (and (eq (state-of *p2*) :idle) (> (fighter-dist (fighter *p2*)) 2.6) (member (state-of *p1*) '(:idle :guard)))
                     (place *p1* *p2* 2.0)
                     (log-msg "duel probe ward t=~d P1 gg ~d~:[~; guardless~] ~a r~d P2 r~d" dt (round (gauges-gg g1))
                              (gauges-guardless g1) (fighter-form (fighter *p1*)) (gauges-reishi g1) (gauges-reishi (gauges *p2*))))
                   (when (> dt 900) (setf (brain-press-left b) 0 *probe* nil))))
          (:ranged (let ((g1 (gauges *p1*)))              ; cup-3 Kenpachi's ranged hits on West (KUKAN-GIRI's rift x2,
                     (case dt                              ; the cash-out, then cup 1's Meteor at 4.8 m, then at 3 m:
                       ((20 120) (force-cmd *p2* :f))      ; its cleaver, a melee hit)
                       ((220 340 470) (force-cmd *p2* :sp1))
                       (440 (place *p1* *p2* 3.0)))
                     (when (member dt '(90 190 300 420 560))
                       (log-msg "duel probe ranged t=~d P1 r~d gg ~d ~a P2 ~a" dt (gauges-reishi g1) (round (gauges-gg g1))
                                (state-of *p1*) (fighter-form (fighter *p2*)))
                       (when (= dt 560) (setf *probe* nil)))))
          (:parry-bait (let ((f1 (fighter *p1*)))       ; P1's parry starts: Kenpachi's F1 is already on its way
                         (when (and (eq (fighter-state f1) :move) (member :parry (mv-flags (fighter-move f1))) (<= (fighter-sf f1) 1)
                                    (not (eq (state-of *p2*) :move)))
                           (start-move *p2* (kit-command-move (kit-of *p2*) :f))
                           (setf (fighter-sf (fighter *p2*)) 10))
                         (when (> dt 1200) (setf *probe* nil))))
          (:nome (let ((g (gauges *p1*)))                       ; the ladder: NOME up in steps, then left to drain
                   (when (and (< dt 400) (zerop (mod dt 45)))   ; (a gain: RYOTE's drain waits again)
                     (setf (gauges-meter g) (f32 (min 100.0 (+ (gauges-meter g) 12.0))) (gauges-meter-idle g) 0))
                   (when (zerop (mod dt 30))
                     (log-msg "duel probe nome t=~d m~d ~a" dt (round (gauges-meter g)) (fighter-form (fighter *p1*))))
                   (when (> dt 1800) (setf *probe* nil))))
          ((:drink :cut)                                         ; P2 presses Quick (drink) / Flash (cut) every other step
           (let ((b (brain *p2*)) (g1 (gauges *p1*)))
             (setf (brain-press b) (if (eq kind :drink) :quick :flash) (brain-press-mod b) nil
                   (brain-press-left b) (if (evenp dt) 1 0))
             (when (and (eq (state-of *p2*) :idle) (> (fighter-dist (fighter *p2*)) 2.9) (member (state-of *p1*) '(:idle :guard)))
               (place *p1* *p2* (if (eq kind :drink) 2.0 2.5))
               (log-msg "duel probe ~(~a~) t=~d P1 gg ~d~:[~; guardless~] r~d m~d ~a" kind dt (round (gauges-gg g1))
                        (gauges-guardless g1) (gauges-reishi g1) (round (gauges-meter g1)) (fighter-form (fighter *p1*))))
             (when (> dt 900) (setf (brain-press-left b) 0 *probe* nil))))
          (:rukia (let ((f1 (fighter *p1*)))                  ; Rukia's tests: 6 answers the Breaker with REIDO at 5.5 m
                    (when (and (= name 6) (eq (fighter-form f1) :zero) (member (state-of *p1*) '(:idle))
                               (eq (state-of *p2*) :move) (< (fighter-dist f1) 5.5))
                      (try-command *p1* f1 :sig))

                    (when (zerop (mod dt 10))
                      (log-msg "duel probe rukia ~d t=~d P1 ~a ~a r~d gg ~d m~d fr~d | P2 ~a ~a r~d fr~d" name dt (fighter-form f1)
                               (state-of *p1*) (gauges-reishi (gauges *p1*)) (round (gauges-gg (gauges *p1*)))
                               (round (gauges-meter (gauges *p1*))) (fighter-frost f1)
                               (state-of *p2*) (fighter-form (fighter *p2*)) (gauges-reishi (gauges *p2*)) (fighter-frost (fighter *p2*))))
                    (when (> dt 420) (setf *probe* nil))))
          (:kl (let* ((f2 (fighter *p2*)) (f1 (fighter *p1*)) (n (fighter-combo-hits f2)) (st (state-of *p2*)))
                 (when (or (/= n af) (and (eq st :guard-hit) (not blocked)))   ; a hit (the combo count moved) or a block
                   (log-msg "duel probe kl ~d t=~d P2 ~a ~a left-before ~d combo ~d | P1 ~a sf ~d m~d" name dt st
                            (fighter-phase f2) df n (let ((mv (fighter-move f1))) (and mv (mv-name mv))) (fighter-sf f1)
                            (round (gauges-meter (gauges *p1*)))))
                 (setf *probe* (list :kl name t0 n (if (member st '(:stun :guard-hit)) (- (fighter-stun f2) (fighter-sf f2)) 0)
                                     (eq st :guard-hit)))
                 (when (> dt 240) (setf *probe* nil))))
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
    (dotimes (i 100) (%hud-guard 10f0 10f0 300f0 6f0 0.4f0 0.6f0 nil nil 1 1f0)
                     (%hud-guard 10f0 10f0 300f0 6f0 0.4f0 0.6f0 t nil 3 1f0))
    (let ((c1 (cons-bytes)))
      (dotimes (i 100) (%hud-flash 10f0 30f0 300f0 6f0 0.8f0 nil t 1f0) (%hud-flash 10f0 30f0 300f0 6f0 0.8f0 t nil 1f0))
      (let ((c2 (cons-bytes)))
        (dotimes (i 100) (%hud-cd 10f0 50f0 150f0 6f0 0.4f0 0f0 nil 1f0 0.5f0 0.2f0) (%hud-cd 10f0 50f0 150f0 6f0 1f0 0.7f0 t 1f0 0.5f0 0.2f0))
        (let ((c3 (cons-bytes)))
          (dotimes (i 100) (%hud-nome 10f0 70f0 300f0 6f0 0.55f0 nil 1 0.25f0 1f0) (%hud-nome 10f0 70f0 300f0 6f0 0.3f0 t 2 0.5f0 1f0))
          (let ((c4 (cons-bytes)))
            (dotimes (i 100) (%hud-arm 10f0 90f0 300f0 6f0 3 100 nil 1f0) (%hud-arm 10f0 90f0 300f0 6f0 1 260 t 1f0))
            (log-msg "hud consing: 100 x 2 guard bars ~d B, 100 x 2 flash-step bars ~d B, 100 x 2 cooldown bars ~d B, 100 x 2 NOME bars ~d B, 100 x 2 UDE bars ~d B"
                     (- c1 c0) (- c2 c1) (- c3 c2) (- c4 c3) (- (cons-bytes) c4)))))))
  ;; the Bankai stances' per-frame looks (10 draws each; particles emitted too): West's flame garb, the bound ash,
  ;; the heat sheet, KYOKKO's ray, South's crack, the aura crossfade (DRAW-AURA); and the Phase-3 :heat aura for
  ;; comparison
  (macrolet ((per (name form)
               `(let ((c0 (cons-bytes))) (dotimes (i 10) ,form) (format nil "~a ~d" ,name (- (cons-bytes) c0)))))
    (log-msg "vfx consing (10 draws, B): ~{~a~^, ~}"
             (list (per "garb" (vfx-aura 0f0 0f0 0f0 1.8f0 :garb 1f0 0.016f0))
                   (per "bound" (vfx-aura 0f0 0f0 0f0 1.8f0 :bound 1f0 0.016f0))
                   (per "nomihose" (vfx-aura 0f0 0f0 0f0 2f0 :nomihose 1f0 0.016f0))
                   (per "oni" (vfx-aura 0f0 0f0 0f0 2f0 :oni 1f0 0.016f0))                 ; Kenpachi's Bankai pillar
                   (per "oni smoulder" (vfx-aura 0f0 0f0 0f0 2f0 :oni 1f0 0.016f0 :k 0.15f0))
                   (per "rift" (vfx-rift 1f0 0f0 4.4f0 0f0 nil))
                   (per "heat(old)" (vfx-aura 0f0 0f0 0f0 1.8f0 :heat 1f0 0.016f0))
                   (per "blade(old)" (vfx-blade-embers 0f0 1f0 0f0 0f0 1.8f0 -0.5f0 0.016f0))
                   (per "kyoku" (vfx-line-cut 0f0 0f0 0f0 -9f0 0.2f0 0.67f0 :kyoku :dt 0.016f0))
                   (per "kyokko" (vfx-line-cut 0f0 0f0 0f0 -4.6f0 0.1f0 0.23f0 :kyokko :dt 0.016f0))
                   (per "south" (vfx-line-cut 0f0 0f0 0f0 -1.2f0 0.1f0 0.93f0 :south :dt 0.016f0))
                   (per "enjo(old)" (vfx-line-cut 0f0 0f0 0f0 -9f0 0.2f0 0.67f0 :enjo :dt 0.016f0))
                   (progn (kosei-mote *p1* 2.0 0.0 1.0 0.0)                     ; KOSEI's mote, 0.1 s into its flight
                          (setf (aref *kosei-v* 0) (f32 (- (fx-clock) 0.1)))
                          (per "kosei mote" (%kosei-mote 0 300f0 90f0 2f0)))
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

(defun string-test (k)
  "2394+k: human P1 in form K (Yamamoto Shikai, Bankai East, Kenpachi base, RYOTE) 2.2 m from an idle Kenpachi."
  (destructuring-bind (c form) (nth k '((:yamamoto :base) (:yamamoto :bankai-east) (:kenpachi :base) (:kenpachi :ryote)))
    (ensure-battle c :kenpachi)
    (unless (eq (fighter-form (fighter *p1*)) form) (force-form *p1* form))
    (when (eq form :ryote) (setf (gauges-meter (gauges *p1*)) 60f0))   ; NOME keeps him in cup 2 (NOME-STEP)
    (when (eq form :bankai-east) (setf (gauges-gg (gauges *p1*)) 30f0))   ; a low gauge: KOSEI x2.4 (the HUD tag)
    (place *p1* *p2* 2.2)))

(defun scale-k-links (pct)
  "Debug 26000+k: every K link entered mid-wind-up (a :flash move with :enter: K2, K3 and their copies) of every kit
deals PCT % of its written damage (the seed gate's first lever, DUEL_STRINGS §6, without a rebuild)."
  (maphash (lambda (c forms)
             (declare (ignore c))
             (loop for (nil . kit) in forms
                   do (maphash (lambda (n m)
                                 (declare (ignore n))
                                 (when (and (eq (mv-kind m) :flash) (plusp (mv-enter m)))
                                   (loop for w across (mv-hits m) do (setf (hw-dmg w) (round (* (mv-dmg m) pct) 100)))))
                               (kit-moves kit))))
           *kits*))

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
    (8 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 3.0) (start-cine 'ko-cine *p1* *p2*))
    ((9 10) (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* (if (= k 9) 5.0 3.0)) (force-form *p1* :bankai)
     (setf (gauges-meter (gauges *p1*)) (f32 *arm-pips*)) (refresh-look *p1*)
     (start-cine (if (= k 9) 'ken-bankai-cine 'ken-oni-kikon-cine) *p1* *p2*))
    ((11 12 13) (ensure-battle :rukia :kenpachi) (place *p1* *p2* (if (= k 13) 5.0 3.0))   ; Rukia's (docs/DUEL_RUKIA.md §5, §6)
     (force-form *p1* (if (= k 11) :base :m18))
     (start-cine (nth (- k 11) '(ru-kikon-cine ru-hakka-cine ru-awaken-cine)) *p1* *p2*))
    ((14 15) (ensure-battle :rukia :kenpachi) (place *p1* *p2* 3.0) (force-form *p1* :zero)   ; the white Rukia's face
     (start-cine (if (= k 14) 'ru-face-cine 'ru-face-bankai-cine) *p1* *p2*)))
  (setf *cine-hold* t)
  (when *cine* (setf (cine-hold *cine*) (cine-hold-frame (cine-name *cine*)))))

(defparameter *cine-names* '(yama-bankai-cine ken-nozarashi-cine yama-kikon-cine yama-tenchi-cine ken-kikon-cine
                               ken-sky-split-cine soul-break-cine intro-cine ko-cine ken-bankai-cine ken-oni-kikon-cine
                               ru-kikon-cine ru-hakka-cine ru-awaken-cine ru-face-cine ru-face-bankai-cine)
  "FORCE-CINE's numbering.")

(defcine ru-face-cine (a v :len 60 :hold 30)
  "Debug stills (69000+f): close on the white Rukia's face (absolute zero): the brows and the ice keyline."
  (at 0 (face-each-other a v 3.0) (shot-on a 20 1.3 1.45 :look 1.4) (lens 28)))

(defcine ru-face-bankai-cine (a v :len 60 :hold 30)
  "Debug stills (70000+f): the same close-up in the 白霞罸 costume."
  (at 0 (face-each-other a v 3.0) (setf (model-body (model a)) (find-body :rukia-bankai)) (face-beat a :neutral 2.0)
      (shot-on a 20 1.3 1.45 :look 1.4) (lens 28)))

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
    (14 (setf (gauges-reishi (gauges *p2*)) 200))
    (15 (ensure-battle :kenpachi :yamamoto) (force-form *p1* :ryote) (setf (gauges-meter (gauges *p1*)) 70f0))
    (16 (ensure-battle :kenpachi :yamamoto) (force-form *p1* :nomihose) (setf (gauges-meter (gauges *p1*)) 100f0))
    (62 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 4.5) (force-cmd *p1* :sp2))
    (63 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 5.0) (force-form *p1* :hellfire) (force-cmd *p1* :sp2))
    (64 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 6.0) (force-cmd *p1* :breaker))
    (65 (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 4.0) (force-form *p1* :nomihose)
        (setf (gauges-meter (gauges *p1*)) 100f0) (emit :rung *p1* t))
    (66 (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 4.0)            ; looks only: the marks and chips
        (let ((q (pos-of *p2*)))
          (stage-mark :scorch (aref q 0) (+ (aref q 2) 0.6) 1.0)
          (stage-mark :crack (- (aref q 0) 1.2) (- (aref q 2) 1.4) 1.1) (stage-debris (- (aref q 0) 1.2) (- (aref q 2) 1.4) 5))
        (face-beat *p1* :shout 0.6) (face-beat *p2* :hurt 0.6))))                ; and both face accents

(defun grip-drift-check ()
  "2392: the left fist's gap to the cleaver's handle over every grip clip and every grip-clip -> grip-clip transition
(a 4 f crossfade from 0.1 s before the first one's end), sampled at 60 Hz on P1's body, raw and after GRIP-LEFT! (W 1):
'grip drift: raw max … mm, IK max … mm'."
  (let* ((b (model-body (model *p1*))) (jm (make-f32 (* 16 +nj+))) (an (make-anim)) (raw 0.0) (ik 0.0) (worst nil) (iw nil)
         (one (fv 1)) (per '()))
    (flet ((sample (tag)
             (pose-fk! jm (anim-eval an) 0.0 0.0 0.0 0.0 (body-scale b) (body-hunch b) (body-props b))
             (let ((g (grip-gap jm)))
               (when (> g raw) (setf raw g worst tag))
               (grip-left! jm one)
               (let ((g2 (grip-gap jm)))
                 (when (> g2 ik) (setf ik g2 iw tag))
                 (let ((e (assoc tag per :test #'equal)))
                   (if e (setf (second e) (max (second e) g) (third e) (max (third e) g2)) (push (list tag g g2) per)))))))
      (dolist (a *grip-clips*)
        (anim-play an a :blend 0)
        (let ((fr '()))
          (loop for i from 0 below (floor (* 60 (clip-dur (find-clip a)))) do
            (pose-fk! jm (anim-eval an) 0.0 0.0 0.0 0.0 (body-scale b) (body-hunch b) (body-props b))
            (push (round (* 1000 (grip-gap jm))) fr)
            (grip-left! jm one) (push (round (* 1000 (grip-gap jm))) fr)
            (sample a) (anim-advance an (/ 1f0 60)))
          (log-msg "grip ~a (raw/IK mm): ~{~d/~d~^ ~}" a (reverse fr)))
        (dolist (c *grip-clips*)
          (anim-play an a :blend 0)
          (loop repeat (max 1 (floor (* 60 (- (clip-dur (find-clip a)) 0.1)))) do (anim-advance an (/ 1f0 60)))
          (anim-play an c :blend 4f0)
          (loop repeat 18 do (sample (list a c)) (anim-advance an (/ 1f0 60))))))
    (dolist (e (reverse per)) (when (> (second e) 0.03) (log-msg "grip drift ~a: raw ~,0f mm, IK ~,0f mm" (first e) (* 1000 (second e)) (* 1000 (third e)))))
    (log-msg "grip drift: raw max ~,0f mm (~a), IK max ~,0f mm (~a)" (* 1000 raw) worst (* 1000 ik) iw)))

(defun vfx6-cons-check ()
  "2391: bytes consed by 10 draws of each Phase 6 per-frame look (docs/STYLE_STORM_DESIGN.md §14 Phase 6): the marks and
chips (both pools full), a pillar beside the lens, the fire wave passing it, the skull, the rain, both face accents, the
left-hand grip (its step and the IK), and a caption slicing out."
  (let* ((e *p1*) (m (model e)) (cap (make-bcap "卍解" :kanji2 "残火の太刀" :reading "BANKAI" :layout :cine))
         (eye (camera-eye *camera*)) (px (f32 (+ (aref eye 0) 0.8))) (wx (f32 (+ (aref eye 0) 1.0))) (ez (aref eye 2)))
    (dotimes (i 20) (stage-mark (if (evenp i) :scorch :crack) (- (* 0.5 i) 5.0) 2.0 1.0))
    (stage-debris 0.0 0.0 24)
    (bcap-exit cap) (setf (aref (bcap-f cap) 7) (- (fx-clock) 0.1))
    (face-accent m :shout)                                  ; (a face change stamps the time once: not per frame)
    (macrolet ((per (name form)
                 `(let ((c0 (cons-bytes))) (dotimes (i 10) ,form) (format nil "~a ~d" ,name (- (cons-bytes) c0)))))
      (log-msg "vfx6 consing (10 draws, B): ~{~a~^, ~}"
               (list (per "marks" (st-draw-marks))
                     (per "chips" (st-chips 0.016f0))
                     (per "pillar-near" (vfx-fire-pillar px ez 0.3f0 0.8f0 0.016f0))
                     (per "wave-near" (vfx-fire-wave wx ez 0f0 0.3f0 9f0 0.016f0))
                     (per "skull" (vfx-skull 0f0 3f0 0f0 0.98f0))
                     (per "rain" (vfx-rain 0f0 0f0 0.5f0 0.9f0))
                     (per "shout" (vfx-face-accent (model-joints m) 1 100))
                     (per "hurt" (vfx-face-accent (model-joints m) 2 100))
                     (per "face-accent" (face-accent m :shout))
                     (per "grip" (grip-step m t 0.016f0))
                     (per "caption-exit" (draw-bcap cap 1280 720)))))
    (stage-clear-marks) (setf (aref (model-looks m) 0) 0f0)))

(defun vfx5-cons-check ()
  "2390: bytes consed by 10 draws of each Phase 5 per-frame look (docs/STYLE_STORM_DESIGN.md §14 Phase 5): the fire looks,
the auras redrawn in toon, the rift, a spent wave's erosion, the new stamps (all live at once), and the face / beat /
move-beat choices of DRAW-FIGHTER."
  (let* ((e *p1*) (f (fighter e)) (m (model e)) (mv (fighter-move f)))
    (dolist (k '(:cone :boom :ring :gash :garb-guard :scorch :flare :gutter :nade)) (stamp k 1.0 1.0 0.0 :dx 1.0 :dz 0.0 :scale 2.0 :n 0.7))
    (wave-ghost-start 3.0 0.0 0.0 3.5 0.3)
    (setf (model-beat m) 0.5)
    (macrolet ((per (name form)
                 `(let ((c0 (cons-bytes))) (dotimes (i 10) ,form) (format nil "~a ~d" ,name (- (cons-bytes) c0)))))
      (log-msg "vfx5 consing (10 draws, B): ~{~a~^, ~}"
               (list (per "fireball" (vfx-fireball 0f0 1.2f0 0f0 0.5f0 1f0 0f0 0.016f0))
                     (per "charge" (vfx-charge 0f0 1.2f0 0f0 0.6f0 0.016f0))
                     (per "pillar" (vfx-fire-pillar 0f0 0f0 0.3f0 0.8f0 0.016f0))
                     (per "dome" (vfx-fire-dome 0f0 0f0 1.7f0 1.2f0 1.96f0 0.016f0))
                     (per "hellfire" (vfx-aura 0f0 0f0 0f0 1.8f0 :hellfire 1f0 0.016f0))
                     (per "evolution" (vfx-aura 0f0 0f0 0f0 1.8f0 :evolution 1f0 0.016f0 :k 0.5f0))
                     (per "breaker" (vfx-aura 0f0 0f0 0f0 1.8f0 :breaker-fire 1f0 0.016f0 :k 1.5f0))
                     (per "breaker-ring" (vfx-breaker-ring 0f0 0f0 0.3f0))
                     (per "garb-flare" (vfx-aura 0f0 0f0 0f0 1.8f0 :garb 1f0 0.016f0 :k 1.9f0))
                     (per "rift" (vfx-rift 1f0 0f0 4.4f0 0f0 nil))
                     (per "wave-ghost" (wave-ghosts-draw 0.001f0))
                     (per "stamps" (stamps-draw 0f0))
                     (per "face" (face-of e f m mv))
                     (per "beat-pose" (beat-pose! (anim-pose (model-anim m)) 0.5f0))
                     (per "move-beats" (move-beats e f m mv 0f0 0f0 0f0 0f0)))))
    (setf (model-beat m) 0f0)))

(defun start-cvc (seed pair)
  "Seeded CPU vs CPU (NORMAL): PAIR = (c1 c2), or NIL to draw both from SEED."
  (setf *match-seed* seed *mode* :cpu-cpu *difficulty* :normal)
  (band-acc-reset) (cup-acc-reset)
  (sim-rnd-seed seed)
  (setf *picks* (or pair (list (nth (floor (* (length *roster*) (sim-rnd01))) *roster*)
                               (nth (floor (* (length *roster*) (sim-rnd01))) *roster*))))
  (start-match))

(defvar *gate* nil "Seed gate: (seed pair) matches still to run.")
(defvar *gate-results* nil "(pair secs ko-p) of the finished gate matches.")
(defparameter *pairs* '((:yamamoto :yamamoto) (:yamamoto :kenpachi) (:kenpachi :kenpachi)
                        (:rukia :yamamoto) (:rukia :kenpachi) (:rukia :rukia)))

(defvar *gate-seed0* 0 "Debug 30000+k: the seed gate plays seeds k+1 .. k+20 (the 60-seed A/B in three runs).")
(defun start-gate (p)
  (setf *turbo* t *skip-cines* nil *combat-log* nil *gate-log* nil *gate-results* nil
        *gate* (loop for pair in (case p (3 *pairs*) (4 (subseq *pairs* 3)) (5 (subseq *pairs* 3 5))
                                   (t (list (nth (mod p 10) *pairs*))))   ; (10+k: pairing k alone)
                     append (loop for seed from (1+ *gate-seed0*) to (+ *gate-seed0* 20) collect (list seed pair))))
  (gate-update))

(defvar *gate-busy* nil "A gate match is running.")

(defun gate-update ()
  "Per frame: record a finished gate match, start the next, summarise at the end."
  (when (and *gate-busy* (eq *flow* :results))
    (push (list *picks* (/ *match-tick* 60.0)
                (or (zerop (gauges-konpaku (gauges *p1*))) (zerop (gauges-konpaku (gauges *p2*)))))
          *gate-results*)
    (log-msg "duel gate row seed ~d ~a ~a secs ~,1f winner ~a forms ~a ~a" *match-seed* (first *picks*) (second *picks*)
             (/ *match-tick* 60.0) (case *winner* (0 "P1") (1 "P2") (t "DRAW"))
             (fighter-form (fighter *p1*)) (fighter-form (fighter *p2*)))   ; (the gamble A/B reads the final forms)
    (band-acc-line) (cup-acc-line)
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
  (unless (or (<= 2200 c 2299) (<= 10000 c 19999) (<= 35000 c 36999) (<= 40000 c 42999) (<= 69000 c 70999)) (setf *cine-hold* nil))
  (cond ((<= 2000 c 2099) (start-cvc (- c 2000) nil))
        ((<= 3000 c 3999) (start-cvc (- c 3000) '(:yamamoto :yamamoto)))
        ((<= 4000 c 4999) (start-cvc (- c 4000) '(:yamamoto :kenpachi)))
        ((<= 5000 c 5999) (start-cvc (- c 5000) '(:kenpachi :kenpachi)))
        ((<= 6000 c 6999) (start-cvc (- c 6000) '(:rukia :yamamoto)))
        ((<= 7000 c 7999) (start-cvc (- c 7000) '(:rukia :kenpachi)))
        ((<= 8000 c 8999) (start-cvc (- c 8000) '(:rukia :rukia)))
        ((= c 2118) (start-gate 4))
        ((= c 2119) (start-gate 5))
        ((<= 2125 c 2130) (start-gate (+ 10 (- c 2125))))   ; one pairing alone: 0 YY 1 YK 2 KK 3 RY 4 RK 5 RR
        ((= c 2124) (start-gate 4) (setf *combat-log* t *gate-log* t))   ; her three pairings with the combat log (pacing)
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
        ((<= 2114 c 2117) (start-gate (- c 2114)) (setf *combat-log* t *gate-log* t))
        ((<= 2120 c 2123) (setf (svref *no-draw* (- c 2120)) (not (svref *no-draw* (- c 2120)))))
        ((= c 2209) (setf *cine-hold* nil) (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 3.0) (match-over *p1*))
        ((<= 2200 c 2299) (force-cine (- c 2200)))
        ((<= 10000 c 19999) (cine-at (floor (- c 10000) 1000) (mod c 1000)))
        ((<= 35000 c 36999) (cine-at (+ 9 (floor (- c 35000) 1000)) (mod c 1000)))
        ((<= 40000 c 42999) (cine-at (+ 11 (floor (- c 40000) 1000)) (mod c 1000)))
        ((<= 69000 c 70999) (cine-at (+ 14 (floor (- c 69000) 1000)) (mod c 1000)))   ; the white Rukia's face
        ((<= 2315 c 2318) (probe-block (nth (- c 2315) '(:ya-j1 :ya-k3 :ya-j3 :ya-taimatsu))))
        ((= c 2319) (probe-trade))
        ((= c 2320) (probe-mash))
        ((= c 2321) (force-burst))
        ((= c 2327) (probe-pressure))
        ((= c 2328) (hud-cons-check))
        ((= c 2329) (brush-cons-check))
        ((= c 2390) (vfx5-cons-check))
        ((= c 2391) (vfx6-cons-check))
        ((= c 2392) (grip-drift-check))
        ((<= 2330 c 2361) (module-test (- c 2330)))
        ((<= 2370 c 2379) (stance-test (- c 2370)))
        ((<= 2380 c 2385) (nome-test (- c 2380)))
        ((<= 2386 c 2389) (bankai-test (- c 2386)))
        ((<= 2410 c 2418) (rukia-test (- c 2410)))
        ((<= 2420 c 2426) (rukia-kl-test (- c 2420)))
        ((<= 2430 c 2438) (hud-review (- c 2430)))
        ((= c 2326) (ensure-battle :yamamoto :kenpachi) (place *p1* *p2* 3.0) (clash! *p1* *p2*))
        ((= c 2393) (place *p1* *p2* 2.2)
         (dolist (e (list *p1* *p2*))                   ; a switched-off CPU lets go of what it held (a guard)
           (vpad-clear! (pilot-vpad (pilot e))) (let ((b (brain e))) (when b (setf (brain-press-left b) 0)))))
        ((<= 2394 c 2397) (string-test (- c 2394)))
        ((<= 2700 c 2709) (portrait-test (- c 2700)))
        ((<= 2300 c 2399) (force-special (- c 2300)))
        ((= c 2400) (setf *god* (not *god*)))
        ((<= 2600 c 2699) (setf *red-threshold* (/ (- c 2600) 100.0)))
        ((<= 20000 c 20999) (setf *ward-mult* (/ (- c 20000) 100.0)))
        ((<= 21000 c 21999) (setf *pierce-max* (/ (- c 21000) 100.0)))
        ((<= 22000 c 22999) (setf *gg-regen* (/ (- c 22000) 10.0)))
        ((<= 23000 c 23999) (setf *gg-regen-guardless* (/ (- c 23000) 10.0)))
        ((<= 24000 c 24999) (setf *ai-o-ender* (/ (- c 24000) 100.0)))
        ((<= 25000 c 25999) (setf (getf *ai-follow-guard-p* :normal) (/ (- c 25000) 100.0)))
        ((<= 26000 c 26999) (scale-k-links (- c 26000)))
        ((<= 27000 c 27999) (setf *kosei-reiatsu* (/ (- c 27000) 100.0) *kosei-fs* (/ (- c 27000) 200.0)))
        ((<= 28000 c 28999) (setf *ai-string-flash-p* (/ (- c 28000) 100.0)))
        ((<= 29000 c 29999) (setf *ai-sp-cancel-p* (/ (- c 29000) 100.0)))
        ((<= 30000 c 30999) (setf *gate-seed0* (- c 30000)))
        ((<= 31000 c 31033) (let ((m '(nil :always :never :sure)))
                              (setf (svref *ai-bankai-mode* 0) (nth (floor (- c 31000) 10) m)
                                    (svref *ai-bankai-mode* 1) (nth (mod (- c 31000) 10) m))))
        ((<= 32000 c 32999) (setf *arm-self* (- c 32000)))
        ((<= 33000 c 33999) (setf *arm-burst-self* (- c 33000)))
        ((<= 34000 c 34999) (setf *arm-crack* (- c 34000)))
        ((<= 37000 c 37100) (setf (getf (getf (kit-ai (find-kit :kenpachi :nomihose)) :bankai) :p) (/ (- c 37000) 100.0)))
        ((<= 38000 c 38009) (setf (getf (getf (kit-ai (find-kit :kenpachi :nomihose)) :bankai) :own-konpaku) (- c 38000)))
        ((<= 39000 c 39022) (let ((m '(nil :always :never)))
                              (setf (svref *ai-awaken-mode* 0) (nth (floor (- c 39000) 10) m)
                                    (svref *ai-awaken-mode* 1) (nth (mod (- c 39000) 10) m))))
        ((<= 43000 c 43100) (setf *frost-slow* (/ (- c 43000) 100.0)))
        ((<= 44000 c 44999) (setf *zero-brace-drain* (/ (- c 44000) 10.0)))
        ((<= 45000 c 45999) (setf *freeze-touch* (- c 45000)))
        ((<= 46000 c 46999) (setf *ru-cool-rate* (float (- c 46000))))
        ((<= 47000 c 47999) (setf *crack-self* (- c 47000)))
        ((<= 48000 c 48300) (setf (kit-mult (find-kit :rukia :zero)) (/ (- c 48000) 100.0)))   ; zero's damage x k / 100
        ((<= 49000 c 49099) (setf (getf (getf (kit-ai (find-kit :rukia :base)) :awaken) :melee-share) (/ (- c 49000) 100.0)))
        ((<= 50000 c 50100) (dolist (f '(:m18 :m50)) (setf (getf (getf (kit-ai (find-kit :rukia f)) :cool) :p) (/ (- c 50000) 100.0))))
        ((<= 51000 c 51999) (setf *ru-thaw-lock* (- c 51000)))
        ((<= 53000 c 53099) (dolist (f '(:m18 :m50)) (setf (getf (getf (kit-ai (find-kit :rukia f)) :cool) :near) (/ (- c 53000) 10.0))))
        ((<= 54000 c 54009) (setf (getf (getf (kit-ai (find-kit :rukia :base)) :intents) :zone) (- c 54000)))
        ((<= 55000 c 55999) (setf (kit-warm (find-kit :rukia :zero)) (/ (- c 55000) 10.0)))   ; zero's warming k / 10 per s
        ((<= 56000 c 56099) (setf (kit-walk (find-kit :rukia :m50)) (/ (- c 56000) 10.0)))
        ((<= 57000 c 57099) (setf (kit-walk (find-kit :rukia :m18)) (/ (- c 57000) 10.0)))
        ((<= 58000 c 58300) (setf (kit-mult (find-kit :rukia :base)) (/ (- c 58000) 100.0)))
        ((<= 60000 c 60200) (setf (kit-taken (find-kit :rukia :base)) (/ (- c 60000) 100.0)))
        ((<= 61000 c 61200) (loop for f in '(:m18 :m50 :zero) for r in '(1.0 0.9 0.889)   ; every band's damage taken,
                                  do (setf (kit-taken (find-kit :rukia f)) (* r (/ (- c 61000) 100.0)))))   ; -18's = k / 100
        ((<= 62000 c 62200) (setf *ru-block-cool* (/ (- c 62000) 100.0)))
        ((<= 63000 c 63100) (setf *ru-hit-warm* (/ (- c 63000) 100.0)))
        ((<= 65000 c 65100) (setf (getf (kit-field (find-kit :rukia :zero)) :away) (/ (- c 65000) 100.0)))
        ((<= 66000 c 66100) (setf *field-floor* (/ (- c 66000) 100.0)))
        ((<= 72000 c 72100) (setf (getf (kit-ai (find-kit :rukia :base)) :l-after-k) (/ (- c 72000) 100.0)))   ; her CPU's
        ((<= 73000 c 73100) (dolist (f '(:m18 :m50 :zero))   ; L after a K link, k / 100 per hit: the Shikai / the bands
                              (setf (getf (kit-ai (find-kit :rukia f)) :l-after-k) (/ (- c 73000) 100.0))))
        ((= c 71000) (setf *reiatsu-glass*                      ; review stills: Kenpachi's reiatsu opaque / see-through
                           (if (zerop (getf *reiatsu-glass* :nomihose)) '(:reiatsu 3 :nozarashi 3 :nomihose 2 :oni 2 :oni-ink 3)
                               '(:reiatsu 0 :nozarashi 0 :nomihose 0 :oni 0 :oni-ink 0))))
        ((<= 71001 c 71004) (ensure-battle :kenpachi :yamamoto) (place *p1* *p2* 3.0)   ; his cups 1-3 (4: the Bankai)
                            (force-form *p1* (nth (- c 71001) '(:nozarashi :ryote :nomihose :bankai)))
                            (setf (gauges-meter (gauges *p1*)) (f32 (nth (- c 71001) '(20 70 100 4)))   ; NOME holds the cup
                                  (gauges-meter-idle (gauges *p1*)) 0))
        ((= c 68000) (dolist (n '(:rukia-zero :rukia-bankai))   ; review stills: the white Rukia's look before the ice
                       (let ((b (find-body n)))                ; keyline (the ink, brows the hair's colour)
                         (setf (body-ink b) nil (body-palette b) (cons '(:brow #xE4E8EE) (body-palette b)))
                         (build-body b))))
        ((= c 68001) (dolist (n '(:rukia-zero :rukia-bankai))   ; review stills: the white Rukia's lashes before playtest 2
                       (let ((b (find-body n)))                ; (the ink's dark, not the brows' ice)
                         (setf (body-palette b) (cons '(:lid #x141016) (body-palette b)))
                         (build-body b))))
        ((<= 67000 c 67200) (let ((g (gauges *p1*)) (f (fighter *p1*)))   ; P1's cold = k and the band it asks for (stills)
                              (setf (gauges-meter g) (f32 (- c 67000)))
                              (when (getf (kit-meter (fighter-kit f)) :temp)
                                (let ((b (temp-band (gauges-meter g) (fighter-form f))))
                                  (unless (eq b (fighter-form f)) (force-form *p1* b))))))
        ((<= 2500 c 2503)
         (setf *picks* (nth (- c 2500) '((:yamamoto :kenpachi) (:kenpachi :yamamoto) (:yamamoto :yamamoto) (:kenpachi :kenpachi)))
               *mode* :vs-cpu *match-seed* 1 *probe* nil)
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

;;; ---------------------------------------------------------------- the portrait probes (2700+k)
(defvar *frame-probe* nil "The framing / text probe runs (PORTRAIT-TEST 0).")
(defvar *frame-counts* (make-array 6 :initial-element 0) "Samples, P1 in, P2 in, both in, frames seen, the frame counter.")
(defvar *text-min* (list 1000 nil) "The smallest glyph px seen by the probe and the flow it was drawn in.")
(declaim (type f32vec *probe-v*))
(defvar *probe-v* (make-f32 3))

(defun fighter-screen-box (e)
  "Values x0 y0 x1 y1 (window px) of fighter E's drawn bulk (his hurt cylinder + 0.25 m around, 0.35 m over his head),
or NIL when a corner is behind the camera."
  (let* ((p (pos-of e)) (b (model-body (model e))) (r (+ 0.25 (body-hurt-r b))) (top (+ 0.35 (body-hurt-h b)))
         (x0 1e9) (y0 1e9) (x1 -1e9) (y1 -1e9) (v *probe-v*))
    (dolist (dx (list (- r) r) (values x0 y0 x1 y1))
      (dolist (dz (list (- r) r))
        (dolist (y (list 0.0 top))
          (unless (world-to-screen v (f32 (+ (aref p 0) dx)) (f32 (+ (aref p 1) y)) (f32 (+ (aref p 2) dz))) (return-from fighter-screen-box nil))
          (setf x0 (min x0 (aref v 0)) x1 (max x1 (aref v 0)) y0 (min y0 (aref v 1)) y1 (max y1 (aref v 1))))))))

(defun frame-probe-step ()
  "Once a frame after the HUD (main.lisp GAME-FRAME) while *FRAME-PROBE*: the text floor over every portrait screen, and
every 30th battle frame (no cinematic, not paused) whether each fighter's box sits in the arena band."
  (let ((c *frame-counts*) (w (window-width)) (h (window-height)))
    (when (portrait-p)
      (when (< *ui-text-min* (first *text-min*)) (setf *text-min* (list *ui-text-min* *flow*)))
      (when (and (eq *flow* :battle) (not *cine*) (not *paused*) (zerop (mod (incf (svref c 5)) 30)))
        (flet ((in (e) (multiple-value-bind (x0 y0 x1 y1) (fighter-screen-box e)   ; his upper half clear of both HUD blocks,
                         (and x0 (>= (- (min x1 w) (max x0 0)) (* 0.7 (- x1 x0)))       ; >= 70 % of his width on the screen
                              (>= y0 (* h (aref *band* 2))) (<= (* 0.5 (+ y0 y1)) (* h (aref *band* 3)))))))
          (let ((a (in *p1*)) (b (in *p2*)))
            (incf (svref c 0)) (when a (incf (svref c 1))) (when b (incf (svref c 2))) (when (and a b) (incf (svref c 3))))))))
  (setf *ui-text-min* 1000))

(defun frame-probe-line ()
  (let ((c *frame-counts*) (n (max 1 (svref *frame-counts* 0))))
    (log-msg "duel frame ~dx~d (css ~dx~d) band ~,3f-~,3f: p1 ~d/~d p2 ~d/~d both ~d/~d (~,1f %); text min ~a px in ~a, floor ~d px"
             (window-width) (window-height) (round (window-width) (pixel-density)) (round (window-height) (pixel-density))
             (aref *band* 2) (aref *band* 3) (svref c 1) (svref c 0) (svref c 2) (svref c 0) (svref c 3) (svref c 0)
             (/ (* 100.0 (svref c 3)) n) (first *text-min*) (second *text-min*) (ceiling (* 11 (pixel-density)) 7))))

(defun portrait-test (k)
  (case k
    (0 (if *frame-probe* (frame-probe-line) (setf *frame-probe* t))
       (when (and *p1* (entity-alive-p *p1*))
         (let ((d (pixel-density)))
           (flet ((b (e) (multiple-value-list (fighter-screen-box e))))
             (log-msg "duel frame boxes (css): p1 ~{~,0f~^ ~} p2 ~{~,0f~^ ~} fov ~,1f shift ~,3f eye ~{~,2f~^ ~} at ~{~,2f~^ ~}"
                      (mapcar (lambda (v) (/ v d)) (b *p1*)) (mapcar (lambda (v) (/ v d)) (b *p2*))
                      (/ (camera-fov *camera*) (deg 1)) (camera-shift-y *camera*) (coerce *cam-eye* 'list) (coerce *cam-at* 'list))))))
    (1 (place *p1* *p2* 24.0))
    (2 (let ((p (pos-of *p1*)) (yaw (yaw-of *p1*)))          ; to his left, 4 m, facing him: the view lags behind
         (v3-set! (pos-of *p2*) (f32 (+ (aref p 0) (* 4 (fwd-z yaw)))) 0f0 (f32 (- (aref p 2) (* 4 (fwd-x yaw)))))
         (face-each-other *p2* *p1*)))
    (3 (place *p1* *p2* 1.0))
    (4 (let ((c0 (cons-bytes)) (p (pos-of *p1*)) (q (pos-of *p2*)) (dt 0.016f0) (asp (f32 (window-aspect))))
         (dotimes (i 100) (%portrait-camera p q dt nil))
         (let ((c1 (cons-bytes)))
           (dotimes (i 100) (%portrait-dolly asp))
           (let ((c2 (cons-bytes)))
             (log-msg "portrait consing: 100 x camera ~d B, 100 x dolly ~d B, 1 x the whole portrait HUD column ~d B"
                      (- c1 c0) (- c2 c1)
                      (let ((c3 (cons-bytes))) (hud-side-portrait *p1* (window-width) (window-height) (ui-scale)) (- (cons-bytes) c3)))))))))

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
