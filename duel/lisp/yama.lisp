;;;; yama.lisp — YAMAMOTO GENRYUSAI SHIGEKUNI (TYBW), design-v1 §5.1: his moves (DEFMOVE) and his
;;;; four forms (DEFKIT): :base (shikai), :hellfire (Gokuen: the Inferno meter full, 10 s), and his
;;;; awakening Bankai (Zanka no Tachi, kept to the end of the match) as two stances L switches between:
;;;; :bankai-east (Kyokujitsujin, offence) and :bankai-west (Zanjitsu Gokui, defence), both burning out
;;;; when his guard gauge empties (design bankai-kikon v3 §A). Frame data here is the §5 table; clip names are
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
  :meter *inferno-sig* :guard 10                                    ; guard gauge: 10 per cut, the wave 15
  :hits ((16 19) (28 31))
  :on-frame ((40 yama-fire-wave))
  :params (:width 3.5 :speed 14.0 :range 12.0 :dmg 110 :on-hit :knockback :kb 3.0
           :chip *chip-fire* :meter *inferno-sig* :guard 15))
;; hold 12..60 f (charge loop), release -> throw; the fireball leaves at throw frame 2
(defmove :ya-shiranui :kind :sp :clip :ya-shiranui :clip-2 :ya-shiranui-throw :callout "SHIRANUI"
  :hold (12 60) :startup 2 :active 1 :recovery 20
  :tick yama-shiranui-charge :on-frame ((2 yama-shiranui-throw))
  :params (:dmg-min 90 :dmg-max 170 :speed-min 10.0 :speed-max 16.0 :turn 60.0 :range 20.0 :on-hit :knockback
           :kb 3.0 :chip *chip-fire* :meter *inferno-sig* :full-meter *inferno-max* :guard-min 10 :guard-max 18))
(defmove :ya-taimatsu :kind :sp :clip :ya-taimatsu :callout "TAIMATSU"
  :startup 16 :active 8 :recovery 24 :dmg 120 :adv-block -14
  :vol (:arc 4.0 90 0.0 2.2) :on-hit :knockback :kb 3.5 :flags (:ranged)   ; fire cone 4 m, 90 deg (fire: ranged)
  :on-frame ((16 yama-fire-cone)))
(defmove :ya-breaker :kind :breaker :clip :ya-breaker :clip-2 :ya-ikkotsu :callout "IKKOTSU" :planted t)
;; O, the Kikon rush module ENJO (Shikai, Hellfire): no dash. He aims for 6 f, points the blade along a
;; lane and a line of fire walls rises along it (f4) and bursts at f20: a melee lane 1 -> 9 m, locked,
;; fire (chip 12 %). A hit with O held: the Kikon, Jokaku Enjo, on a red opponent, else the follow-up
;; (the lane again; KIKON-OUTCOME). Guardable; -14 on block, out of reach at range. Cooldown 90.
(defmove :ya-kikon :kind :kikon :clip :ya-stance :clip-2 :ya-enjo :callout "JOKAKU ENJO" :cine yama-kikon-cine
  :startup 20 :active 2 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0
  :vol (:cap 1.0 9.0 1.2 1.4) :on-hit :knockback :kb 2.0 :chip *chip-fire* :cooldown 90
  :on-frame ((4 yama-enjo-line))
  :params (:aura 6 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane))

;;; ================================================================ Hellfire (Gokuen)
(defmove :ya-nadegiri :kind :sp :clip :ya-nadegiri :callout "NADEGIRI" :cost 2
  :startup 20 :active 4 :recovery 30 :dmg 240 :adv-block -16
  :vol (:cap 0.3 8.0 1.0 0.5) :on-hit :knockdown :kb 3.0 :flags (:ranged)   ; line 8 m: the blade within Q1's
  :params (:melee-range 2.4))                                        ; reach 2.4 m, ranged beyond

;;; ================================================================ Bankai: Zanka no Tachi (design v3 §A)
;;; The compass: O = North (KITA: TENCHI, both stances), L = East / West (switch + a technique), Shift+L =
;;; South (the bind, both stances). J / K are each stance's own; Q2 and the Breaker are derived from the
;;; Shikai ones (East -1 f and reach x1.15, West +2 f).
;;; ---------------------------------------------------------------- East, Kyokujitsujin: fast thin lines
(defmove :ya-e-q1 :kind :quick :clip :ya-q1 :clip-s 9 :startup 8 :active 3 :recovery 12 :dmg 34 :adv-block -2
  :vol (:cap 0.2 3.1 1.1 0.25) :on-hit :flinch)                      ; edge line 3.1 m
;; the rising-sun thrust: R27 = +-0 on hit (no 1 f loop into E-Q1, the ender-gap rule)
(defmove :ya-e-q3 :kind :quick :clip :ya-e-thrust :startup 11 :active 3 :recovery 27 :dmg 55 :adv-block -12
  :vol (:cap 0.2 3.6 1.1 0.3) :on-hit :knockback :kb 1.2)
(defmove :ya-e-f1 :kind :flash :clip :ya-f1 :clip-s 18 :startup 16 :active 4 :recovery 20 :dmg 70 :adv-block -4
  :vol (:cap 0.2 3.8 1.1 0.3) :on-hit :stagger)                     ; edge sweep line
(defmove :ya-e-f2 :kind :flash :clip :ya-f2 :clip-s 22 :startup 19 :active 4 :recovery 26 :dmg 90 :adv-block -14
  :vol (:cap 0.2 3.8 1.3 0.35) :on-hit :launch)                     ; sun-edge rising cut
(defmove :ya-e-f2q :kind :flash :clip :ya-f2 :clip-s 22 :enter 6 :startup 19 :active 4 :recovery 26 :dmg 90 :adv-block -14
  :vol (:cap 0.2 3.8 1.3 0.35) :on-hit :launch)
;; L in East: NISHI, the blade planted, the garb flares (360 deg), and on its first active frame he is West: it
;; resolves there (no move armour)
(defmove :ya-to-west :kind :sig :clip :ya-to-west :callout "NISHI: ZANJITSU GOKUI" :startup 14 :active 4 :recovery 20
  :dmg 50 :adv-block -10 :vol (:arc 2.6 360 0.0 2.2) :on-hit :knockback :kb 3.5
  :cooldown *switch-cooldown* :flags (:cancel) :on-frame ((14 yama-switch)) :params (:to :bankai-west))
;; Shift+K in East: KYOKUJITSUJIN, the downward cut. The blade (f18-19, close) breaks guard; at f20 its tip
;; bites the ground and the heat runs forward: a 25 deg / 9 m cone, 130, blockable (never a break)
(defmove :ya-kyoku :kind :sp :clip :ya-kyoku :callout "KYOKUJITSUJIN" :startup 18 :active 5 :recovery 26
  :dmg 90 :adv-block -16 :vol (:arc 9.0 25 0.0 1.6)
  :hits ((18 20 :vol (:cap 0.3 2.4 1.0 0.4) :on-hit :knockback :kb 0.5 :flags (:guard-crush :heat))   ; the blade
         (20 23 :dmg 130 :on-hit :knockback :kb 4.0 :flags (:ranged)))                             ; the cone (ranged)
  :on-frame ((18 yama-kyoku-cut) (20 yama-kyoku-sheet)))

;;; ---------------------------------------------------------------- West, Zanjitsu Gokui: short rings, the garb, counters
;;; (guard v3, the user's decisions 2026-09-26: U is the garb guard, a blocked hit drains half its guard value and
;;; scorches a melee attacker; ranged hits are armoured at x*GARB-RANGED*; no move armour: passive :garb)
(defmove :ya-w-q1 :kind :quick :clip :ya-q1 :clip-s 9 :startup 11 :active 3 :recovery 12 :dmg 40 :adv-block -2
  :reach 1.9 :arc 220 :on-hit :flinch)                              ; garb sweep
(defmove :ya-w-q3 :kind :quick :clip :ya-w-shove :startup 13 :active 4 :recovery 22 :dmg 70 :adv-block -12
  :reach 2.4 :arc 360 :on-hit :knockback :kb 3.0)      ; garb shove
(defmove :ya-w-f1 :kind :flash :clip :ya-to-west :clip-s 14 :startup 20 :active 4 :recovery 20 :dmg 80 :adv-block -4
  :vol (:arc 2.6 360 0.0 2.2) :on-hit :stagger)       ; garb flare
(defmove :ya-w-f2 :kind :flash :clip :ya-q3 :clip-s 12 :startup 22 :active 5 :recovery 28 :dmg 110 :adv-block -14
  :reach 2.8 :arc 110 :on-hit :knockdown :kb 2.5)      ; garb crush
(defmove :ya-w-f2q :kind :flash :clip :ya-q3 :clip-s 12 :enter 8 :startup 22 :active 5 :recovery 28 :dmg 110 :adv-block -14
  :reach 2.8 :arc 110 :on-hit :knockdown :kb 2.5)
;; L in West: HIGASHI, a one-handed backhand sweep from low right; he is East from f12, so it hits at x1.2 and
;; chips 40 %
(defmove :ya-to-east :kind :sig :clip :ya-to-east :callout "HIGASHI" :startup 12 :active 3 :recovery 22
  :dmg 90 :adv-block -8 :vol (:cap 0.2 4.2 1.1 0.35) :on-hit :stagger :chip 0.4
  :cooldown *switch-cooldown* :flags (:cancel) :on-frame ((12 yama-switch)) :params (:to :bankai-east))
;; Shift+K in West: GOKUI GAESHI, a parry (f4-15, *PARRY-WINDOW*); a melee hit in it staggers the attacker
;; *PARRY-STUN* and starts the counter (the :land string: combat.lisp APPLY-HIT :parried). 46 f parried or not.
(defmove :ya-w-parry :kind :sp :clip :ya-w-parry :callout "GOKUI GAESHI" :startup 4 :active 12 :recovery 30 :flags (:parry)
  :on-frame ((4 yama-parry-up)))
(defmove :ya-w-counter :kind :sig :clip :ya-w-counter :startup 6 :active 3 :recovery 24 :dmg 150 :adv-block -12
  :vol (:arc 2.6 120 0.0 2.0) :on-hit :knockback :kb 3.0)

;;; ---------------------------------------------------------------- both: South (Shift+L) and North (O)
;; MINAMI, the bind: at f20 the blade is driven in and the point under the opponent (<= 10 m) is marked; a
;; :bind hazard grabs the feet there :delay frames later (f36), unguardable, 40 + bound *BIND-STUN* frames.
;; Step / Hoho out of the tell; a bound fighter may Burst (it books 2 combo hits); opener only
;; (RULES COMBO-STEP); any hit frees him. 600 f cooldown (kept through resets).
(defmove :ya-kaka :kind :sp :clip :ya-kaka :callout "MINAMI: KAKA JUMANOKUSHI DAISOJIN" :cost 2
  :startup 20 :active 1 :recovery 34 :cooldown 600 :flags (:bind)
  :on-frame ((20 yama-south))
  :params (:range 10.0 :radius 1.2 :height 0.6 :delay 16 :dmg 40 :stun *bind-stun* :hands 4))
;; O in Bankai, KITA: TENCHI: 10 f of aim, then a flash step, 36 m/s for at most 14 f, the direction
;; locked at take-off (a sidestep in the aim beats it), then one diagonal cut (Q1's, played faster):
;; 10 m, <= 30 f from the press. Tenchi Kaijin. Cooldown 90.
(defmove :ya-tenchi :kind :kikon :clip :sh-run :clip-2 :ya-q1 :clip-s 9 :callout "TENCHI KAIJIN" :cine yama-tenchi-cine
  :startup 6 :active 2 :recovery 26 :dmg 70 :adv-block -14 :reach 2.4 :arc 110 :on-hit :knockback :kb 2.5 :cooldown 90
  :on-frame ((5 yama-tenchi-slash))
  :params (:aura 10 :aim 120.0 :speed 36.0 :dash-max 14 :dash-track 0.0 :look :flash-step :sfx :hoho-out))

;;; ================================================================ forms
(defkit :yamamoto :base
  :name "YAMAMOTO" :body :yamamoto :weapon :ryujin-jakka :stance :ya-stance
  :intro :ya-intro :win :ya-win :intro-callout "BANSHO ISSAI KAIJIN TO NASE" :intro-weapon (:ya-cane 81)
  :walk *walk-yamamoto* :run *run-yamamoto* :reishi *reishi-max* :blade (:fire 1.0) :swing-sfx :fire-whoosh
  :commands (:q :ya-q1 :f :ya-f1 :sig :ya-sig :sp1 :ya-shiranui :sp2 :ya-taimatsu
             :breaker :ya-breaker :kikon :ya-kikon)
  :strings ((:ya-q1 :q :ya-q2) (:ya-q2 :q :ya-q3) (:ya-q2 :f :ya-f2q) (:ya-f1 :f :ya-f2))
  :meter (:name "INFERNO" :max *inferno-max* :full-form :hellfire)
  :awaken-form :bankai-east
  :ai (:intents (:approach 1 :pressure 1 :zone 3 :defend 1)
       :ranges (:approach (3.0 6.0) :pressure (1.5 3.0) :zone (7.0 9.5) :defend (4.0 7.0))
       :moves ((0.0 3.0 :q 4 :f 2 :breaker 1 :sp2 1 :step 1)
               (3.0 5.0 :f 1 :sig 2 :step 2 nil 2)
               (5.0 7.0 :sig 4 :sp1 1 :step 1 nil 1)
               (7.0 99.0 :sp1 4 :sig 2 :kikon 1 nil 1))                ; ENJO as a poke from range
       :guard 0.45 :hoho 0.35 :awaken-above 0.4 :sp-cancel-bars 2 :oki :sp1-full :oki-above 0.6
       :dash 0.25 :dash-back 0.5 :kikon-range 9.0))

(defkit :yamamoto :hellfire :inherit :base
  :callout "GOKUEN" :mult *hellfire-mult* :duration *hellfire-seconds* :burn *hellfire-burn* :blade (:fire 1.3)
  :enter-clips (:ya-hellfire) :enter-hook yama-ennetsu :aura :hellfire
  :commands (:sp2 :ya-nadegiri)
  :ai (:intents (:approach 1 :pressure 4 :zone 0 :defend 0)
       :ranges (:approach (3.0 5.0) :pressure (1.5 3.0) :zone (6.0 8.0) :defend (4.0 7.0))
       :moves ((0.0 3.0 :q 3 :f 3 :sp2 2 :breaker 1)
               (3.0 8.0 :f 1 :sig 2 :step 2)
               (8.0 99.0 :sp1 2 :step 2))
       :guard 0.4 :hoho 0.35 :awaken-above 0.4 :sp-cancel-bars 1 :dash 0.5 :kikon-range 9.0))

(defkit :yamamoto :bankai-east :inherit :base
  :awakening t :burnout t :feed *bankai-feed-east* :mult *bankai-mult* :taken *bankai-taken* :startup-add -1 :reach-mult 1.15
  :blade (:embers 1.4) :grade :spot :passives (:projectile-cut :recoil) :blade-chip *chip-blade* :meter nil   ; the body as
  ;; it is (the charcoal heat wisps), the charred blade with its ember-red edge line
  :weapon :zanka :aura :heat :enter-clips (:ya-bankai) :enter-hook yama-bankai-enter :swing-sfx :whoosh-heavy
  :cine yama-bankai-cine
  :commands (:q :ya-e-q1 :f :ya-e-f1 :sig :ya-to-west :sp1 :ya-kyoku :sp2 :ya-kaka :kikon :ya-tenchi)
  :strings ((:ya-e-q1 :q :ya-q2) (:ya-q2 :q :ya-e-q3) (:ya-q2 :f :ya-e-f2q) (:ya-e-f1 :f :ya-e-f2))
  ;; pressure up close, the cone from range; below :gg-low of his guard gauge he backs off and zones (his
  ;; recoil would burn him out); L ends a landed string half the time (:cancel); low Reishi: L x3 (:low; West is
  ;; the cheaper place for a low gauge now, so no gauge gate on it)
  :ai (:intents (:approach 2 :pressure 4 :zone 1 :defend 0)
       :ranges (:approach (3.0 5.0) :pressure (1.5 3.0) :zone (5.0 8.0) :defend (4.0 7.0))
       :moves ((0.0 3.0 :q 5 :f 2 :breaker 1 :sig 1 :sp2 1 nil 1)
               (3.0 6.0 :f 1 :sp1 2 :step 1 nil 1)
               (6.0 99.0 :sp1 3 :step 1 nil 1))
       :guard 0.35 :hoho 0.35 :awaken-above 0.4 :sp-cancel-bars 9 :dash 0.6 :dash-back 0.3 :kikon-range 9.0
       :cancel (:sig 0.5) :low (0.4 :sig 3) :gg-low 0.45 :block-string 0.85))

(defkit :yamamoto :bankai-west :inherit :bankai-east
  :mult 1.0 :taken 1.0 :feed *bankai-feed* :startup-add 2 :passives (:garb :scorch) :blade-chip nil
  :blade (:charcoal) :aura :garb                ; wrapped in red flames (the garb); the blade pure charcoal, no ember line
  :commands (:q :ya-w-q1 :f :ya-w-f1 :sig :ya-to-east :sp1 :ya-w-parry :sp2 :ya-kaka :kikon :ya-tenchi)
  :strings ((:ya-w-q1 :q :ya-q2) (:ya-q2 :q :ya-w-q3) (:ya-q2 :f :ya-w-f2q) (:ya-w-f1 :f :ya-w-f2)
            (:ya-w-parry :land :ya-w-counter))
  ;; defends (its U is the garb guard: half the gauge, scorches), parries a Flash startup it can still catch (:react)
  :ai (:intents (:approach 1 :pressure 2 :zone 1 :defend 3)
       :ranges (:approach (2.5 4.5) :pressure (1.2 2.5) :zone (3.5 5.0) :defend (2.5 4.5))
       :moves ((0.0 3.0 :q 3 :f 3 :sig 1 :breaker 1 :sp2 1 nil 2)
               (3.0 5.0 :sig 3 :f 1 :step 1 nil 2)
               (5.0 99.0 :sig 1 :step 1 nil 2))
       :guard 0.55 :hoho 0.3 :awaken-above 0.4 :sp-cancel-bars 9 :dash 0.4 :dash-back 0.2 :kikon-range 9.0
       :react (:flash-startup :sp1) :cancel (:sig 0.5)))

;;; ================================================================ hooks (called through the data's symbols)
(defun yama-fire-wave (e)
  "Signature f40: the flame wave leaves the blade (a hazard 3.5 m wide, 14 m/s, 12 m)."
  (multiple-value-bind (x z) (ahead e 1.0)
    (let ((speed (move-param e :speed)))
      (spawn-hazard :wave e :x x :z z :yaw (yaw-of e) :speed speed :size (* 0.5 (move-param e :width))
                            :life (round (* 60 (/ (move-param e :range) speed)))
                            :hw (make-hitwin :dmg (move-param e :dmg) :react (move-param e :on-hit) :kb (move-param e :kb)
                                             :hs *hitstop-heavy* :chip (move-param e :chip) :meter (move-param e :meter)
                                             :guard (move-param e :guard)))))
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
                                                   :meter (move-param e :meter)
                                                   :guard (round (lerp (move-param e :guard-min) (move-param e :guard-max) k))))))
    (when (>= k 1.0) (add-meter e (move-param e :full-meter)))
    (emit :sfx :fire-roar e)))

(defun yama-ennetsu (e)
  "Hellfire entry: Ennetsu Jigoku — a ring of fire pillars (2 hits max), and it burns Yamamoto too."
  (let ((p (pos-of e)) (g (gauges e)))
    (spawn-hazard :pillars e :x (aref p 0) :z (aref p 2) :size 3.0 :life (seconds->frames *ennetsu-seconds*)
                             :hits *ennetsu-hits*
                             :hw (make-hitwin :dmg *ennetsu-damage* :react :stagger :kb 2.0 :hs *hitstop-heavy* :guard 10))
    (setf (gauges-reishi g) (burn (gauges-reishi g) *ennetsu-self-burn*))
    (when (eq (fighter-state (fighter e)) :idle) (play-clip e :ya-hellfire :blend 3))
    (emit :sfx :fire-roar e)))

(defun yama-enjo-line (e)
  "ENJO f4: the line of fire walls starts rising along the locked lane (a look: the hit is the move's)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 9.0 :life 34 :look :enjo))
  (emit :sfx :fire-roar e))

(defun yama-tenchi-slash (e)
  "TENCHI: the cut's ring, just before it lands."
  (emit :sfx :kikon-slash e))

(defun yama-bankai-enter (e)
  "Bankai: every fire is drawn into the blade for good (Inferno empties; no more Hellfire)."
  (setf (gauges-meter (gauges e)) 0f0))


(defun yama-switch (e)
  "L's first active frame: the stance switches (its :params :to), so the technique resolves in the new one.
NISHI: the garb flares (a charcoal double ring, :heat-flare); HIGASHI: the white backhand crescent."
  (let ((to (move-param e :to)) (p (pos-of e)) (yaw (yaw-of e)))
    (set-form e to)
    (if (eq to :bankai-west)
        (progn (vfx-nishi (aref p 0) (aref p 2)) (emit :sfx :heat-flare e))
        (progn (vfx-higashi (aref p 0) (aref p 2) (fwd-x yaw) (fwd-z yaw)) (emit :sfx :sizzle e)))))

(defun yama-parry-up (e)
  "GOKUI GAESHI's window opens: the column of charcoal wisps (a look)."
  (let ((p (pos-of e))) (vfx-parry-up (aref p 0) (aref p 2))))

(defun yama-kyoku-cut (e)
  "KYOKUJITSUJIN f18: the charred blade comes straight down (a white vertical slit, a look)."
  (let ((p (pos-of e)) (yaw (yaw-of e)))
    (vfx-kyoku-slit (aref p 0) (aref p 2) (fwd-x yaw) (fwd-z yaw)))
  (emit :sfx :kikon-slash e))

(defun yama-kyoku-sheet (e)
  "KYOKUJITSUJIN f20: the tip bites the ground and a flat 25 deg sheet of heat runs 9 m ahead (a look: the
hit is the move's cone window)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 9.0 :life 40 :look :kyoku))
  (emit :sfx :heat-flare e))

(defun yama-south (e)
  "MINAMI f20: the blade driven in. The point under the opponent is sampled now (CAST-POINT, <= :range m);
the ground there cracks (a look) and :hands skeleton hands claw out; a :bind hazard grabs the feet
(a disc :radius x :height) :delay frames later: unguardable, :dmg + bound :stun frames (RULES COMBO-STEP)."
  (let* ((p (pos-of e)) (q (pos-of (opp-of e))) (r (move-param e :radius)) (delay (move-param e :delay)))
    (multiple-value-bind (x z) (cast-point (aref p 0) (aref p 2) (aref q 0) (aref q 2) (move-param e :range))
      ;; (a hazard's delay counts down in the step it is spawned in: +1 lands the grab exactly :delay frames later)
      (spawn-hazard :bind e :x x :z z :size r :y (move-param e :height) :delay (1+ delay) :life 2
                            :hw (make-hitwin :dmg (move-param e :dmg) :react :bind :stun (move-param e :stun)
                                             :hs *hitstop-heavy* :flags '(:unguardable)))
      (spawn-hazard :line e :x x :z z :size r :life (+ delay 40) :look :south)
      (dotimes (i (move-param e :hands))
        (let ((a (* i (/ +two-pi+ (move-param e :hands)))))
          (spawn-hand e (+ x (* 0.7 r (fwd-x a))) (+ z (* 0.7 r (fwd-z a))) (+ a +pi+) (- delay 8)))))
    (emit :sfx :ground-crack e)))

;;; ================================================================ cinematics
;;; The grammar of every cinematic is in cinema.lisp (docs/STYLE_STORM_DESIGN.md §5); Yamamoto (white haori) goes on
;;; the black card.
(defcine yama-kikon-cine (a v :len 186 :hold 112)
  "Jokaku Enjo (§5's worked example, paced by user review 3: few long shots, long holds, sharp hits): beat 0 (the
gameplay shot frozen, a negative); a black card, Yamamoto low and dutch under the 城郭炎上 stamp, silence; high and wide:
the walls of fire rise and close; cut low and wide-angle onto the victim inside them; a held push-in (poses held,
effects frozen, silence); the detonation: a negative, then a manga page (the fire the only colour), the Konpaku shatter
and an ink splash; the aftermath wide."
  (at 0 (face-each-other a v 3.2)
      (cine-clip a :ya-kikon :blend 2 :speed (/ 77.0 142.0))   ; its old timing, slowed to the new beats (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2)
      (play-sfx :fire-roar))
  (at 12 (card :black a) (shot-on a 25 2.9 0.7 :look 1.3 :off -0.8) (lens 45 10) (silence 52)
      (caption "城郭炎上" :reading "JOKAKU ENJO" :sub "KIKON" :side 1 :hanko t))
  (at 70 (card nil) (shot-pair a v (camera-side a) 7.5 3.6) (lens 50))
  (during (12 186) (unless *card*                        ; the card beat: only Yamamoto and his blade's fire; the dome
                     (let ((q (pos-of v)))               ; detonates at 85 % of its 1.96 s from f42: f142
                       (vfx-fire-dome (aref q 0) (aref q 2) 1.7 (/ (- cf 42) 60.0) 1.96 (cine-dt))
                       (add-point-light (aref q 0) 1.5 (aref q 2) 1.0 0.35 0.08 10.0 (+ 0.5 (* 1.5 u)) 5))))
  (at 100 (shot-on v 150 3.8 0.35 :look 1.4) (lens 88) (setf *caption* nil))
  (at 120 (hold-both a v 22) (silence 22) (lens 70))
  (during (120 142) (shot-on v 150 (- 3.6 (* 0.6 u)) (+ 0.4 (* 0.05 u)) :look 1.4))   ; a slow push-in, not cuts
  (at 142 (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3))
      (impact-frame :negative 2) (let ((q (pos-of v))) (impact-splash (aref q 0) 0.0 (aref q 2) 16 0.07))
      (play-sfx :explode) (play-sfx :konpaku-shatter) (shake 0.3 0.4))
  (at 144 (impact-frame :manga 12))
  (at 156 (shot-pair a v (- (camera-side a)) 9.0 1.6) (lens 48)))

(defcine yama-tenchi-cine (a v :len 168 :hold 26)
  "Tenchi Kaijin (§4.1; paced by user review 3): beat 0 in the Bankai's grey; a long black card, Yamamoto silhouetted
with a white back-rim under the 北 / 天地灰尽 stamp, silence; the slash: a white / ink two-tone frame with the hard white
slash, then a manga page; the victim flakes into ash (an ink splash) in the same shot; a low wide of him standing in the
grey world."
  (at 0 (face-each-other a v 2.4)
      (cine-clip a :ya-tenchi :blend 2 :speed (/ 18.0 68.0)) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (cine-grade :spot))
  (at 12 (card :black a) (back-rim 56) (shot-on a 70 3.2 0.9 :look 1.2 :off 0.8) (lens 42 -8) (silence 56)
      (caption "天地灰尽" :mark "北" :reading "TENCHI KAIJIN" :sub "ZANKA NO TACHI" :side 0 :hanko t))
  (during (68 168) (vfx-tenchi-slash (/ (- cf 68) 60.0) 0.8))
  (at 68 (card nil) (play-sfx :kikon-slash) (impact-frame :two-tone 4) (shot-pair a v 1 5.0 1.4) (lens 55))
  (at 72 (impact-frame :manga 12))
  (at 86 (multiple-value-bind (x y z) (actor-point v 1.0) (vfx-ash-burst x y z) (vfx-konpaku-shatter x y z 3))
      (setf (model-alpha (model v)) 0f0)
      (let ((q (pos-of v))) (impact-splash (aref q 0) 0.0 (aref q 2) 14 0.07))
      (play-sfx :konpaku-shatter) (play-sfx :sizzle) (shake 0.2 0.3))
  (at 110 (shot-on a -35 4.6 0.5 :look 1.3) (lens 48) (setf *caption* nil)))

(defcine yama-bankai-cine (a v :len 138 :hold 72)
  "BANKAI (§5's reveal; paced by user review 3): beat 0; every flame in the arena is drawn into the blade (close, low,
wide-angle, focus lines); from behind, in silence, the world drains to grey; the reveal, held long: a negative, then
Yamamoto a black silhouette on a white card, the only colour the ember line of the charred blade, the 卍解 / 残火の太刀
stamp in black with its splash; the charcoal burst and the plaza cracks in the grey world."
  (at 0 (cine-clip a :ya-bankai :blend 3 :speed (/ 2.2 1.8)) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (setf (model-weapon (model a)) :ryujin-jakka)
      (hold-both a v 12) (impact-frame :negative 2)
      (play-sfx :awaken-rise))
  (at 12 (let ((p (pos-of a))) (vfx-awaken-burst (aref p 0) 0.0 (aref p 2) :bankai))   ; every flame sucked in
      (shot-on a 25 1.5 0.45 :look 1.45) (lens 88 6) (focus-lines 36))
  (during (12 60) (let ((p (pos-of a)))
                    (vfx-charge (aref p 0) 2.4 (aref p 2) u (cine-dt))
                    (vfx-aura (aref p 0) 0.0 (aref p 2) 2.2 :hellfire (/ cf 60.0) (cine-dt) :k (- 1.0 u))))
  (at 40 (silence 20) (shot-on a 200 3.0 0.8 :look 1.4) (lens 50))
  (at 44 (cine-grade :spot))                             ; the form's grey (main.lisp FORM-GRADE takes over after)
  (at 60 (setf (model-weapon (model a)) :zanka)
      (impact-frame :negative 2) (card :white a) (silhouette-black a)
      (caption "卍解" :kanji2 "残火の太刀" :reading "BANKAI" :sub "ZANKA NO TACHI" :side 0 :ink t)
      (play-sfx :awaken-boom) (shake 0.25 0.4)
      (shot-on a 15 4.4 0.6 :look 1.25 :off 0.9) (lens 40))
  (at 118 (card nil) (unsilhouette) (shot-on a -30 6.5 1.6 :look 1.1) (lens 50)
      (let ((p (pos-of a)))                              ; back in the grey world: the charcoal burst, the plaza cracks
        (vfx-awaken-burst (aref p 0) 0.0 (aref p 2) :bankai-burst)
        (stage-crack-add (aref p 0) (aref p 2) 3.0)
        (stage-crack-add (+ (aref p 0) 3.5) (- (aref p 2) 2.0) 2.2)
        (stage-crack-add (- (aref p 0) 3.0) (+ (aref p 2) 2.5) 2.4))))
