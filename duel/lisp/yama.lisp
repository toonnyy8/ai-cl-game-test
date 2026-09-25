;;;; yama.lisp — YAMAMOTO GENRYUSAI SHIGEKUNI (TYBW), design-v1 §5.1: his moves (DEFMOVE) and his
;;;; three forms (DEFKIT): :base (shikai), :hellfire (Gokuen: the Inferno meter full, 10 s) and
;;;; :bankai (Zanka no Tachi, his awakening, kept to the end of the match). Frame data here is the §5 table; clip names are
;;;; the art contract (yama-art.lisp authors them). Below the data: his hook functions (called by
;;;; the generic fighter code through the symbols in the data) and his cinematics (DEFCINE).
(in-package :duel)

;;; ================================================================ shikai (base)
(defmove :ya-q1 :kind :quick :clip :ya-q1 :startup 9 :active 3 :recovery 12 :dmg 38 :adv-block -2
  :reach 2.4 :arc 100 :on-hit :flinch)
(defmove :ya-q2 :kind :quick :clip :ya-q2 :startup 8 :active 3 :recovery 13 :dmg 38 :adv-block -2
  :reach 2.4 :arc 100 :on-hit :flinch)
(defmove :ya-q3 :kind :quick :clip :ya-q3 :startup 12 :active 4 :recovery 22 :dmg 60 :adv-block -12
  :reach 2.6 :arc 120 :on-hit :knockback :kb 3.0)                    ; flame burst
(defmove :ya-f1 :kind :flash :clip :ya-f1 :startup 18 :active 4 :recovery 20 :dmg 75 :adv-block -4
  :reach 3.0 :arc 150 :on-hit :stagger :meter *inferno-flash*)        ; flame sweep
(defmove :ya-f2 :kind :flash :clip :ya-f2 :startup 22 :active 5 :recovery 28 :dmg 95 :adv-block -14
  :reach 2.6 :arc 90 :on-hit :launch :meter *inferno-flash*)          ; rising blaze
;; the Q Q -> F branch: F2 entered 8 f into its wind-up, so it combos off Q2's flinch (same -14)
(defmove :ya-f2q :kind :flash :clip :ya-f2 :enter 8 :startup 22 :active 5 :recovery 28 :dmg 95 :adv-block -14
  :reach 2.6 :arc 90 :on-hit :launch :meter *inferno-flash*)
;; two cuts (f16, f28), then the wave hazard leaves the blade at f40 (-6 on block at range)
(defmove :ya-sig :kind :sig :clip :ya-sig :callout "RYUJIN JAKKA"
  :startup 16 :active 25 :recovery 26 :dmg 30 :adv-block -6 :reach 2.6 :arc 110 :on-hit :flinch
  :meter *inferno-sig*
  :hits ((16 19) (28 31))
  :on-frame ((40 yama-fire-wave))
  :params (:width 3.5 :speed 14.0 :range 12.0 :dmg 110 :on-hit :knockback :kb 3.0
           :chip *chip-fire* :meter *inferno-sig*))
;; hold 12..60 f (charge loop), release -> throw; the fireball leaves at throw frame 2
(defmove :ya-shiranui :kind :sp :clip :ya-shiranui :clip-2 :ya-shiranui-throw :callout "SHIRANUI"
  :hold (12 60) :startup 2 :active 1 :recovery 20
  :tick yama-shiranui-charge :on-frame ((2 yama-shiranui-throw))
  :params (:dmg-min 90 :dmg-max 170 :speed-min 10.0 :speed-max 16.0 :turn 60.0 :range 20.0 :on-hit :knockback
           :kb 3.0 :chip *chip-fire* :meter *inferno-sig* :full-meter *inferno-max*))
(defmove :ya-taimatsu :kind :sp :clip :ya-taimatsu :callout "TAIMATSU"
  :startup 16 :active 8 :recovery 24 :dmg 120 :adv-block -14
  :vol (:arc 4.0 90 0.0 2.2) :on-hit :knockback :kb 3.5             ; fire cone 4 m, 90 deg
  :on-frame ((16 yama-fire-cone)))
(defmove :ya-breaker :kind :breaker :clip :ya-breaker :clip-2 :ya-ikkotsu :callout "IKKOTSU" :planted t)
;; the Kikon rush (O): red aura, dash (tuning.lisp *KIKON-...*), then this strike (Q3's overhead chop,
;; played faster). On a red opponent with O still held when it connects: the Kikon, Jokaku Enjo;
;; else a plain knockback hit (guardable unless he is red). -14 on block.
(defmove :ya-kikon :kind :kikon :clip :sh-run :clip-2 :ya-q3 :clip-s 12 :callout "JOKAKU ENJO" :cine yama-kikon-cine
  :startup 8 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.2 :arc 110 :on-hit :knockback :kb 2.5)

;;; ================================================================ Hellfire (Gokuen)
(defmove :ya-nadegiri :kind :sp :clip :ya-nadegiri :callout "NADEGIRI" :cost 2
  :startup 20 :active 4 :recovery 30 :dmg 240 :adv-block -16
  :vol (:cap 0.3 8.0 1.0 0.5) :on-hit :knockdown :kb 3.0)            ; line 8 m

;;; ================================================================ Bankai: Zanka no Tachi
(defmove :ya-kyoku :kind :sp :clip :ya-kyoku :callout "KYOKUJITSUJIN"
  :startup 18 :active 3 :recovery 26 :dmg 220 :adv-block -16
  :vol (:cap 0.3 9.0 1.1 0.3) :on-hit :knockback :kb 4.0            ; thrust line 9 m x 0.6 m
  :on-frame ((18 yama-sun-line)))
;; COUNT skeletons rise RADIUS m around the opponent, the first DELAY f after the summon (f24), one
;; every STAGGER f, and lunge once risen (hazards; the fighter recovers at f61)
(defmove :ya-kaka :kind :sp :clip :ya-kaka :callout "KAKA JUMANOKUSHI DAISOJIN" :cost 2
  :startup 24 :active 1 :recovery 36
  :on-frame ((24 yama-kaka-summon))
  :params (:count 3 :radius 1.9 :delay 6 :stagger 10 :dmg 50 :on-hit :flinch :last-stun 40))
;; the Bankai Kikon rush: the same numbers, one diagonal cut (Q1's), Tenchi Kaijin
(defmove :ya-tenchi :kind :kikon :clip :sh-run :clip-2 :ya-q1 :clip-s 9 :callout "TENCHI KAIJIN" :cine yama-tenchi-cine
  :startup 8 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.2 :arc 110 :on-hit :knockback :kb 2.5)

;;; ================================================================ forms
(defkit :yamamoto :base
  :name "YAMAMOTO" :body :yamamoto :weapon :ryujin-jakka :stance :ya-stance
  :intro :ya-intro :win :ya-win :intro-callout "BANSHO ISSAI KAIJIN TO NASE" :intro-weapon (:ya-cane 81)
  :walk *walk-yamamoto* :run *run-yamamoto* :reishi *reishi-max* :blade (:fire 1.0) :swing-sfx :fire-whoosh
  :commands (:q :ya-q1 :f :ya-f1 :sig :ya-sig :sp1 :ya-shiranui :sp2 :ya-taimatsu
             :breaker :ya-breaker :kikon :ya-kikon)
  :strings ((:ya-q1 :q :ya-q2) (:ya-q2 :q :ya-q3) (:ya-q2 :f :ya-f2q) (:ya-f1 :f :ya-f2))
  :meter (:name "INFERNO" :max *inferno-max* :full-form :hellfire)
  :awaken-form :bankai
  :ai (:intents (:approach 1 :pressure 1 :zone 3 :defend 1)
       :ranges (:approach (3.0 6.0) :pressure (1.5 3.0) :zone (7.0 9.5) :defend (4.0 7.0))
       :moves ((0.0 3.0 :q 4 :f 2 :breaker 1 :sp2 1 :step 1)
               (3.0 5.0 :f 1 :sig 2 :step 2 nil 2)
               (5.0 7.0 :sig 4 :sp1 1 :step 1 nil 1)
               (7.0 99.0 :sp1 4 :sig 2 nil 1))
       :guard 0.45 :hoho 0.35 :awaken-above 0.4 :sp-cancel-bars 2 :oki :sp1-full :oki-above 0.6
       :dash 0.25 :dash-back 0.5))

(defkit :yamamoto :hellfire :inherit :base
  :callout "GOKUEN" :mult *hellfire-mult* :duration *hellfire-seconds* :burn *hellfire-burn* :blade (:fire 1.3)
  :enter-clips (:ya-hellfire) :enter-hook yama-ennetsu :aura :hellfire
  :commands (:sp2 :ya-nadegiri)
  :ai (:intents (:approach 1 :pressure 4 :zone 0 :defend 0)
       :ranges (:approach (3.0 5.0) :pressure (1.5 3.0) :zone (6.0 8.0) :defend (4.0 7.0))
       :moves ((0.0 3.0 :q 3 :f 3 :sp2 2 :breaker 1)
               (3.0 8.0 :f 1 :sig 2 :step 2)
               (8.0 99.0 :sp1 2 :step 2))
       :guard 0.4 :hoho 0.35 :awaken-above 0.4 :sp-cancel-bars 1 :dash 0.5))

(defkit :yamamoto :bankai :inherit :base
  :awakening t :mult *bankai-mult* :blade (:embers 1.0) :grade :spot
  :passives (:armor-vs-quick) :blade-chip *chip-blade* :meter nil
  :weapon :zanka :aura :heat :enter-clips (:ya-bankai) :enter-hook yama-bankai-enter :swing-sfx :whoosh-heavy
  :cine yama-bankai-cine
  :commands (:sp1 :ya-kyoku :sp2 :ya-kaka :kikon :ya-tenchi))

;;; ================================================================ hooks (called through the data's symbols)
(defun yama-fire-wave (e)
  "Signature f40: the flame wave leaves the blade (a hazard 3.5 m wide, 14 m/s, 12 m)."
  (multiple-value-bind (x z) (ahead e 1.0)
    (let ((speed (move-param e :speed)))
      (spawn-hazard :wave e :x x :z z :yaw (yaw-of e) :speed speed :size (* 0.5 (move-param e :width))
                            :life (round (* 60 (/ (move-param e :range) speed)))
                            :hw (make-hitwin :dmg (move-param e :dmg) :react (move-param e :on-hit) :kb (move-param e :kb)
                                             :hs *hitstop-heavy* :chip (move-param e :chip) :meter (move-param e :meter)))))
  (emit :sfx :fire-wave e))

(defun yama-fire-cone (e)
  "Taimatsu's first active frame: the great sweep of fire over its 4 m / 90 deg cone (a look)."
  (let ((p (pos-of e))) (vfx-fire-cone (aref p 0) (aref p 2) (yaw-of e)))
  (emit :sfx :fire-roar e))

(defun yama-shiranui-charge (e)
  "Shiranui charge tick: the crackle starts with the charge."
  (when (= 1 (fighter-hold (fighter e))) (emit :sfx :fire-whoosh e)))

(defun yama-shiranui-throw (e)
  "Throw f2: a homing fireball; damage and speed grow with the charge; a full charge fills Inferno."
  (let* ((f (fighter e)) (lo (first (mv-hold (fighter-move f)))) (hi (second (mv-hold (fighter-move f))))
         (k (max 0.0 (min 1.0 (/ (- (fighter-charge f) lo) (float (- hi lo)))))))
    (multiple-value-bind (x z) (ahead e 0.9)
      (let ((speed (lerp (move-param e :speed-min) (move-param e :speed-max) k)))
        (spawn-hazard :fireball e :x x :y 1.2 :z z :yaw (yaw-of e) :speed speed
                                  :turn (track-step (move-param e :turn)) :size (lerp 0.35 0.6 k)
                                  :life (round (* 60 (/ (move-param e :range) speed)))
                                  :hw (make-hitwin :dmg (round (lerp (move-param e :dmg-min) (move-param e :dmg-max) k))
                                                   :react (move-param e :on-hit) :kb (move-param e :kb)
                                                   :hs *hitstop-heavy* :chip (move-param e :chip)
                                                   :meter (move-param e :meter)))))
    (when (>= k 1.0) (add-meter e (move-param e :full-meter)))
    (emit :sfx :fire-roar e)))

(defun yama-ennetsu (e)
  "Hellfire entry: Ennetsu Jigoku — a ring of fire pillars (2 hits max), and it burns Yamamoto too."
  (let ((p (pos-of e)) (g (gauges e)))
    (spawn-hazard :pillars e :x (aref p 0) :z (aref p 2) :size 3.0 :life (seconds->frames *ennetsu-seconds*)
                             :hits *ennetsu-hits*
                             :hw (make-hitwin :dmg *ennetsu-damage* :react :stagger :kb 2.0 :hs *hitstop-heavy*))
    (setf (gauges-reishi g) (burn (gauges-reishi g) *ennetsu-self-burn*))
    (when (eq (fighter-state (fighter e)) :idle) (play-clip e :ya-hellfire :blend 3))
    (emit :sfx :fire-roar e)))

(defun yama-bankai-enter (e)
  "Bankai: every fire is drawn into the blade for good (Inferno empties; no more Hellfire)."
  (setf (gauges-meter (gauges e)) 0f0))


(defun yama-sun-line (e)
  "Kyokujitsujin: the thrust leaves a white-hot line on the ground (a look)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 9.0 :life 40 :look :sun)))

(defun yama-kaka-summon (e)
  "Bankai South: :count charred skeletons claw out around the opponent, one every :stagger frames,
and lunge; the last one's hit stuns :last-stun frames."
  (let* ((o (opp-of e)) (q (pos-of o)) (a0 (yaw-of o)) (dmg (move-param e :dmg))
         (n (move-param e :count)) (r (move-param e :radius)))
    (dotimes (i n)
      (let* ((a (+ a0 (* i (/ +two-pi+ n)))) (last (= i (1- n))))
        (spawn-skeleton e (+ (aref q 0) (* r (fwd-x a))) (+ (aref q 2) (* r (fwd-z a))) (+ a +pi+)
                        (+ (move-param e :delay) (* (move-param e :stagger) i))
                        (make-hitwin :dmg dmg :react (if last :stagger (move-param e :on-hit)) :hs *hitstop-light*
                                     :stun (and last (move-param e :last-stun)))
                        last)))
    (emit :sfx :bones e)))

;;; ================================================================ cinematics
(defcine yama-kikon-cine (a v :len 108 :hold 70)
  "Jokaku Enjo: walls of fire rise around the victim, close into a dome and detonate."
  (at 0 (face-each-other a v 3.2)
      (cine-clip a :ya-kikon :blend 2) (cine-clip v :sh-kikon-victim :blend 4)
      (shot-pair a v (camera-side a) 6.5 2.0)
      (caption "JOKAKU ENJO" :sub "KIKON" :color '(1 0.55 0.2 1))
      (play-sfx :fire-roar))
  (at 40 (shot-on v 150 5.5 0.8 :look 1.6))
  (during (0 108) (let ((q (pos-of v))) (vfx-fire-dome (aref q 0) (aref q 2) 1.7 (/ cf 60.0) 1.5 (frame-dt))
                    (add-point-light (aref q 0) 1.5 (aref q 2) 1.0 0.35 0.08 10.0 (+ 0.5 (* 1.5 u)) 5)))
  (at 77 (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3))
      (play-sfx :explode) (play-sfx :konpaku-shatter) (shake 0.3 0.4) (ui-flash 1.0 0.6 0.25 0.7)))

(defcine yama-tenchi-cine (a v :len 96 :hold 26)
  "Tenchi Kaijin: one slash; the world goes ash-grey, a white line crosses the screen, the victim
bursts into ash."
  (at 0 (face-each-other a v 2.4)
      (cine-clip a :ya-tenchi :blend 2) (cine-clip v :sh-kikon-victim :blend 4)
      (shot-on a 70 4.2 1.2 :look 1.1 :ahead 1.2)
      (caption "TENCHI KAIJIN" :sub "KIKON" :color '(0.95 0.95 0.95 1)))
  (during (0 18) (setf *grade-desat* u))
  (during (18 96) (setf *grade-desat* 1.0) (vfx-tenchi-slash (/ (- cf 18) 60.0) 0.6))
  (at 18 (play-sfx :kikon-slash) (ui-flash 1 1 1 0.9 4.0) (shot-pair a v 1 5.0 1.4))
  (at 30 (multiple-value-bind (x y z) (actor-point v 1.0) (vfx-ash-burst x y z) (vfx-konpaku-shatter x y z 3))
      (setf (model-alpha (model v)) 0f0)
      (play-sfx :konpaku-shatter) (play-sfx :sizzle) (shake 0.2 0.3)))

(defcine yama-bankai-cine (a v :len 72 :hold 44)
  "BANKAI: every fire in the arena is drawn into the blade, the blade chars black with an ember edge,
the plaza cracks and dries. 卍解 / ZANKA NO TACHI."
  (at 0 (cine-clip a :ya-bankai :blend 3 :speed (/ 2.2 1.2)) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (setf (model-weapon (model a)) :ryujin-jakka)
      (let ((p (pos-of a))) (vfx-awaken-burst (aref p 0) 0.0 (aref p 2) :bankai))   ; every flame sucked in
      (shot-on a 20 3.4 0.9 :look 1.5)
      (play-sfx :awaken-rise))
  (during (0 40) (let ((p (pos-of a)))
                   (vfx-charge (aref p 0) 2.4 (aref p 2) u (frame-dt))
                   (vfx-aura (aref p 0) 0.0 (aref p 2) 2.2 :hellfire (/ cf 60.0) (frame-dt) :k (- 1.0 u))))
  (at 40 (setf (model-weapon (model a)) :zanka)
      (let ((p (pos-of a)))
        (vfx-awaken-burst (aref p 0) 0.0 (aref p 2) :bankai-burst)
        (stage-crack-add (aref p 0) (aref p 2) 3.0)
        (stage-crack-add (+ (aref p 0) 3.5) (- (aref p 2) 2.0) 2.2)
        (stage-crack-add (- (aref p 0) 3.0) (+ (aref p 2) 2.5) 2.4))
      (caption "ZANKA NO TACHI" :kanji :bankai :color '(1 0.55 0.2 1))
      (play-sfx :awaken-boom) (shake 0.25 0.4) (ui-flash 1 0.5 0.15 0.6)
      (shot-on a 35 5.0 1.6 :look 1.2))
  (during (40 72) (setf *grade-desat* u)))   ; into the form's spot-keep grey (main.lisp FORM-GRADE)
