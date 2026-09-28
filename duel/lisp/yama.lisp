;;;; yama.lisp — YAMAMOTO GENRYUSAI SHIGEKUNI (TYBW), design-v1 §5.1: his moves (DEFMOVE) and his
;;;; four forms (DEFKIT): :base (shikai), :hellfire (Gokuen: the Inferno meter full, 10 s), and his
;;;; awakening Bankai (Zanka no Tachi, kept to the end of the match) as two stances: :bankai-east (Kyokujitsujin,
;;;; the edge: pierce, x1.5 taken) and :bankai-west (Zanjitsu Gokui, the ward); U switches East -> West, any attack but
;;;; SP1 / L drops West back to East (docs/DUEL_YAMA_REWORK.md). Frame data here is the §5 table; clip names are
;;;; the art contract (yama-art.lisp authors them). Below the data: his hook functions (called by
;;;; the generic fighter code through the symbols in the data) and his cinematics (DEFCINE).
(in-package :duel)

;;; ================================================================ shikai (base)
;;; the J / K strings (docs/DUEL_STRINGS.md §3.1): up to three links, each J or K, switching at most once (JJJ JJK JKK KKK
;;; KKJ KJJ). One move per (link, button); J2s / K2s, the switched link 2, are copies (DEFMOVE-COPY) whose string allows
;;; only the new button. Every K at link 2 / 3 enters at S_eff 14 (:enter), so it combos after a J and a K link alike;
;;; the enders (:ender) stagger / crumple, and their hit opens the O ender. Hellfire plays these at x1.3. K2 / K3 deal
;;; 80 % of the design's numbers (the seed gate's first lever, docs/DUEL_STRINGS.md §9: 80 -> 64, 110 -> 88; East 75 -> 60,
;;; 105 -> 84).
(defmove :ya-j1 :kind :quick :clip :ya-q1 :startup 9 :active 3 :recovery 12 :dmg 38 :adv-block -2
  :reach 2.4 :arc 100 :on-hit :flinch)                               ; HISEN: the flat cut from the draw
(defmove :ya-j2 :kind :quick :clip :ya-q2 :startup 8 :active 3 :recovery 13 :dmg 38 :adv-block -2
  :reach 2.4 :arc 100 :on-hit :flinch)                               ; KAESHIBI: the backhand along the same line
(defmove :ya-j3 :kind :quick :clip :ya-sleeve :startup 9 :active 3 :recovery 18 :dmg 45 :adv-block -4
  :reach 2.2 :arc 140 :on-hit :stagger :flags (:ender))              ; SODEBI: the burning empty sleeve
(defmove :ya-k1 :kind :flash :clip :ya-f1 :startup 18 :active 4 :recovery 20 :dmg 75 :adv-block -3
  :reach 3.0 :arc 150 :on-hit :stagger :meter *inferno-flash*)      ; HOMURA-NAGI: the waist-high sweep
(defmove :ya-k2 :kind :flash :clip :ya-f2 :enter 8 :startup 22 :active 4 :recovery 24 :dmg 64 :adv-block -3
  :reach 2.6 :arc 90 :on-hit :stagger :meter *inferno-flash*)       ; SHOEN: the rising flame column
(defmove :ya-k3 :kind :flash :clip :ya-q3 :clip-s 12 :enter 8 :startup 22 :active 5 :recovery 34 :dmg 88 :adv-block -20
  :reach 2.8 :arc 120 :on-hit :crumple :meter *inferno-flash* :flags (:ender))   ; ENBAKU: the dome at his feet
(defmove-copy :ya-j2s :ya-j2)
(defmove-copy :ya-k2s :ya-k2)
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

;;; ================================================================ Bankai: Zanka no Tachi (docs/DUEL_YAMA_REWORK.md)
;;; The compass: O = North (KITA: TENCHI), Shift+L = South (the bind), U = East -> West (the kit's :guard-to), L = each
;;; stance's own technique (East KYOKKO, West SHONETSU JIGOKU). J / K are East's own strings; the Breaker is derived
;;; from the Shikai one (-1 f, reach x1.15). In West every command but SP1 / L goes back to East first (:drop-to / :keep):
;;; West's J / K switch him to East and start East's string.
;;; ---------------------------------------------------------------- East, Kyokujitsujin: fast thin lines, the pierce
;; the East strings (docs/DUEL_STRINGS.md §3.2): thin ember lines, the sun's path
(defmove :ya-e-j1 :kind :quick :clip :ya-q1 :clip-s 9 :startup 8 :active 3 :recovery 12 :dmg 34 :adv-block -2
  :vol (:cap 0.2 3.1 1.1 0.25) :on-hit :flinch)                      ; HIZASHI: a flat edge line 3.1 m
(defmove :ya-e-j2 :kind :quick :clip :ya-q2 :clip-s 8 :startup 7 :active 3 :recovery 13 :dmg 38 :adv-block -2
  :vol (:cap 0.2 3.1 1.1 0.25) :on-hit :flinch)                      ; ZANSHO: the return stroke
(defmove :ya-e-j3 :kind :quick :clip :ya-e-thrust :clip-s 11 :startup 8 :active 3 :recovery 18 :dmg 42 :adv-block -4
  :vol (:cap 0.2 3.6 1.1 0.3) :on-hit :stagger :flags (:ender))      ; SENKO: a short thrust, no lunge
(defmove :ya-e-k1 :kind :flash :clip :ya-f1 :clip-s 18 :startup 16 :active 4 :recovery 20 :dmg 70 :adv-block -3
  :vol (:cap 0.2 3.8 1.1 0.3) :on-hit :stagger)                     ; KAGERO: the wide sweep
(defmove :ya-e-k2 :kind :flash :clip :ya-f2 :clip-s 22 :enter 5 :startup 19 :active 4 :recovery 24 :dmg 60 :adv-block -3
  :vol (:cap 0.2 3.8 1.3 0.35) :on-hit :stagger)                    ; NISSHO: the rising cut
(defmove :ya-e-k3 :kind :flash :clip :ya-e-drop :enter 7 :startup 21 :active 5 :recovery 34 :dmg 84 :adv-block -20
  :vol (:cap 0.3 3.6 1.2 0.3) :on-hit :crumple :flags (:ender))      ; RAKUJITSU: the vertical drop, the setting sun
(defmove-copy :ya-e-j2s :ya-e-j2)
(defmove-copy :ya-e-k2s :ya-e-k2)
;; L in East: KYOKKO (旭光), the first ray of the rising sun: a one-handed lunge (1.6 m over the startup) whose point
;; runs a 4.6 m line; double pierce (:pierce-mult 2: 0.2 .. 0.9), so at a full gauge 162 on hit and 77 through a
;; guard (chip: never kills). Ends a landed Q / F string (:cancel); cooldown 100
(defmove :ya-e-kyokko :kind :sig :clip :ya-e-thrust :clip-s 11 :callout "KYOKKO" :startup 15 :active 3 :recovery 26
  :dmg 85 :adv-block -12 :slide 1.6 :vol (:cap 0.2 4.6 1.1 0.3) :on-hit :knockback :kb 2.0
  :cooldown 100 :flags (:cancel) :on-frame ((1 yama-kyokko-flare) (15 yama-kyokko)) :params (:pierce-mult 2.0))
;; Shift+K in East: KYOKUJITSUJIN, the downward cut. The blade (f18-19, close) breaks guard; at f20 its tip
;; bites the ground and the heat runs forward: a 25 deg / 9 m cone, 130, blockable (never a break)
(defmove :ya-kyoku :kind :sp :clip :ya-kyoku :callout "KYOKUJITSUJIN" :startup 18 :active 5 :recovery 26
  :dmg 90 :adv-block -16 :vol (:arc 9.0 25 0.0 1.6)
  :hits ((18 20 :vol (:cap 0.3 2.4 1.0 0.4) :on-hit :knockback :kb 0.5 :flags (:guard-crush))   ; the blade
         (20 23 :dmg 130 :on-hit :knockback :kb 4.0 :flags (:ranged)))                      ; the cone (ranged)
  :on-frame ((18 yama-kyoku-cut) (20 yama-kyoku-sheet)))

;;; ---------------------------------------------------------------- West, Zanjitsu Gokui: the ward (passive :ward)
;; L in West: SHONETSU JIGOKU (焦熱地獄), the garb erupts: the blade planted, the garb flares for 16 f (the tell), then a
;; ring of fire pillars where he stands (Ennetsu's :pillars, radius 2 m): 45 x at most 2, blockable, 360 deg. He
;; stays West (his ward up throughout). Cooldown 150
(defmove :ya-w-shonetsu :kind :sig :clip :ya-shonetsu :clip-s 14 :callout "SHONETSU JIGOKU" :startup 16 :active 0
  :recovery 24 :cooldown 150 :on-frame ((0 yama-shonetsu-tell) (16 yama-shonetsu))
  :params (:size 2.0 :life 48 :hits 2 :dmg 45 :kb 2.0 :guard 12))
;; Shift+K in West: GOKUI GAESHI, a parry (f4-15, *PARRY-WINDOW*); a melee hit in it staggers the attacker
;; *PARRY-STUN*, refills his guard gauge and starts the counter (the :land string: combat.lisp APPLY-HIT :parried).
;; 46 f parried or not; he stays West through it and the counter (both SP1)
(defmove :ya-w-parry :kind :sp :clip :ya-w-parry :callout "GOKUI GAESHI" :startup 4 :active 12 :recovery 30 :flags (:parry)
  :on-frame ((4 yama-parry-up)))
(defmove :ya-w-counter :kind :sig :clip :ya-w-counter :startup 6 :active 3 :recovery 24 :dmg 150 :adv-block -12
  :vol (:arc 2.6 120 0.0 2.0) :on-hit :knockback :kb 3.0)

;;; ---------------------------------------------------------------- both: South (Shift+L) and North (O)
;; MINAMI, the bind: at f20 the blade is driven in and the point under the opponent (<= 10 m) is marked; a
;; :bind hazard grabs the feet there :delay frames later (f36), unguardable, 40 + bound *BIND-STUN* frames.
;; Step / Hoho out of the tell; a bound fighter may Burst (it books 2 combo hits); opener only
;; (RULES COMBO-STEP); any hit frees him. No cooldown: the 2 Reiatsu bars are its limiter, like every SP2 (the
;; user's decision 2026-09-28).
(defmove :ya-kaka :kind :sp :clip :ya-kaka :callout "MINAMI: KAKA JUMANOKUSHI DAISOJIN" :cost 2
  :startup 20 :active 1 :recovery 34 :flags (:bind)
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
  :commands (:q :ya-j1 :f :ya-k1 :sig :ya-sig :sp1 :ya-shiranui :sp2 :ya-taimatsu
             :breaker :ya-breaker :kikon :ya-kikon)
  :grid (:ya-j1 :ya-j2 :ya-j3 :ya-k1 :ya-k2 :ya-k3 :ya-j2s :ya-k2s)
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
  :awakening t :taken *bankai-taken* :startup-add -1 :reach-mult 1.15 :guard-to :bankai-west
  :endless-form :bankai-east                    ; ENDLESS: West (inheriting it) stays as East
  :blade (:embers 1.4) :grade :spot :passives (:projectile-cut :pierce) :meter nil   ; the body as it is (the charcoal
  ;; heat wisps), the charred blade with its ember-red edge line
  :weapon :zanka :aura :heat :enter-clips (:ya-bankai) :enter-hook yama-bankai-enter :swing-sfx :whoosh-heavy
  :cine yama-bankai-cine
  :commands (:q :ya-e-j1 :f :ya-e-k1 :sig :ya-e-kyokko :sp1 :ya-kyoku :sp2 :ya-kaka :kikon :ya-tenchi)
  :grid (:ya-e-j1 :ya-e-j2 :ya-e-j3 :ya-e-k1 :ya-e-k2 :ya-e-k3 :ya-e-j2s :ya-e-k2s)
  ;; pressure up close, the cone from range; U (:guard) is going West now; below :gg-low of his guard gauge he backs
  ;; off and zones while it refills; KYOKKO (L) in the close and middle bands, halved below :sig-gg of the gauge (it
  ;; pierces with a full edge), and ends a landed string half the time (:cancel); low Reishi: L x3 (:low)
  :ai (:intents (:approach 2 :pressure 4 :zone 1 :defend 0)
       :ranges (:approach (3.0 5.0) :pressure (1.5 3.0) :zone (5.0 8.0) :defend (4.0 7.0))
       :moves ((0.0 3.0 :q 5 :f 2 :breaker 1 :sig 2 :sp2 1 nil 1)
               (3.0 6.0 :f 1 :sp1 2 :sig 2 :step 1 nil 1)
               (6.0 99.0 :sp1 3 :step 1 nil 1))
       :guard 0.45 :hoho 0.35 :awaken-above 0.4 :sp-cancel-bars 9 :dash 0.6 :dash-back 0.3 :kikon-range 9.0
       :cancel (:sig 0.5) :low (0.4 :sig 3) :gg-low 0.3 :block-string 0.85 :sig-gg 0.6))

(defkit :yamamoto :bankai-west :inherit :bankai-east
  :taken 1.0 :guard-to nil :drop-to :bankai-east :keep (:sig :sp1) :passives (:ward :scorch)
  :blade (:charcoal) :aura :garb                ; wrapped in red flames (the garb); the blade pure charcoal, no ember line
  :enter-hook yama-ward-up :exit-hook yama-ward-down
  :commands (:sig :ya-w-shonetsu :sp1 :ya-w-parry)
  :strings ((:ya-w-parry :land :ya-w-counter))
  ;; the ward holds (U does nothing more); every pick but L / SP1 is East's move (the drop); parries a Flash startup it
  ;; can still catch (:react); SHONETSU when the ward just took a hit up close (:ward-reversal)
  :ai (:intents (:approach 2 :pressure 2 :zone 0 :defend 2)
       :ranges (:approach (2.5 4.5) :pressure (1.2 2.5) :zone (3.5 5.0) :defend (2.5 4.5))
       :moves ((0.0 3.0 :q 3 :f 2 :sig 2 :breaker 1 :sp2 1 nil 3)
               (3.0 6.0 :f 1 :sp1 2 :step 1 nil 2)
               (6.0 99.0 :sp1 2 :step 1 nil 2))
       :guard 0.3 :hoho 0.3 :awaken-above 0.4 :sp-cancel-bars 9 :dash 0.4 :dash-back 0.2 :kikon-range 9.0
       :react (:flash-startup :sp1) :ward-reversal 0.35))

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


(defun yama-ward-up (e)
  "West's :enter-hook (U in East): the garb flares on round him (a charcoal double ring, ASH shards)."
  (let ((p (pos-of e))) (vfx-nishi (aref p 0) (aref p 2)))
  (emit :sfx :heat-flare e))

(defun yama-ward-down (e)
  "West's :exit-hook (an attack drops him to East, or a crush / a Guard Break blows the garb off): an ember puff."
  (let ((p (pos-of e))) (vfx-ember (aref p 0) 1.2 (aref p 2) :scale 0.8))
  (emit :sfx :sizzle e))

(defun yama-kyokko-flare (e)
  "KYOKKO f1: the ember edge line flares white-hot (the lunge's tell)."
  (setf (model-super (model e)) 0.2)
  (emit :sfx :sizzle e))

(defun yama-kyokko (e)
  "KYOKKO f15: the ray (a look: the hit is the move's line window): a white core over an ember rim along the 4.6 m
line and a small sun at its tip (the :line hazard look :kyokko)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 4.6 :life 14
                          :look :kyokko))
  (emit :sfx :kikon-slash e))

(defun yama-shonetsu-tell (e)
  "SHONETSU JIGOKU f0: the blade goes to the ground and the garb flares hard (its aura x1.9 fading over the startup:
the tell), the charcoal column rises."
  (setf (model-flare (model e)) 0.45)
  (let ((p (pos-of e))) (vfx-parry-up (aref p 0) (aref p 2)))
  (emit :sfx :heat-flare e))

(defun yama-shonetsu (e)
  "SHONETSU JIGOKU f16: the garb erupts: a ring of fire pillars (:pillars, :size m round where he stands, :life
frames, :hits x :dmg, blockable) and the plaza cracks under him."
  (let ((p (pos-of e)))
    (spawn-hazard :pillars e :x (aref p 0) :z (aref p 2) :size (move-param e :size) :life (move-param e :life)
                             :hits (move-param e :hits)
                             :hw (make-hitwin :dmg (move-param e :dmg) :react :stagger :kb (move-param e :kb) :hs *hitstop-heavy*
                                              :guard (move-param e :guard) :chip *chip-fire*))
    (vfx-garb-flare (aref p 0) (aref p 2))
    (stage-crack-add (aref p 0) (aref p 2) 1.5))
  (emit :sfx :fire-roar e))

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
  (at 100 (shot-on v 150 3.8 0.35 :look 1.4) (lens 88) (caption-exit))
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
  (at 110 (shot-on a -35 4.6 0.5 :look 1.3) (lens 48) (caption-exit)))

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
