;;;; ken.lisp — ZARAKI KENPACHI (TYBW), design-v1 §5.2: his moves (DEFMOVE) and his forms (DEFKIT): :base and
;;;; his permanent awakening Nozarashi, three cups of the NOME ladder (docs/DUEL_NOZARASHI_V2.md): :nozarashi
;;;; (KATATE, one hand), :ryote (two hands) and :nomihose (drink it dry). Inherited moves are DERIVED by the kit
;;;; (KATATE startup +2 / reach x1.3, RYOTE +3 / x1.4; damage via :mult), never copied here; NOMIHOSE derives
;;;; nothing: it plays RYOTE's. He wears no eyepatch in any form (TYBW).
;;;; Clip names are the art contract (ken-art.lisp). Below the data: his hook functions and his
;;;; cinematics (DEFCINE).
(in-package :duel)

;;; ================================================================ base
;;; the J / K strings (docs/DUEL_STRINGS.md §3.3): no school, a street fighter with a sword who kicks. The grid as
;;; Yamamoto's (yama.lisp): up to three links, switching J / K at most once; every K at link 2 / 3 at S_eff 14, at 80 % of
;;; the design's damage (the seed gate: 75 -> 60, 100 -> 80; RYOTE 85 -> 68, 115 -> 92)
(defmove :ke-j1 :kind :quick :clip :ke-q1 :startup 7 :active 3 :recovery 12 :dmg 35 :adv-block -2
  :reach 2.6 :arc 100 :on-hit :flinch :slide 0.8)                    ; ARAGIRI: a lazy slash, lunge 0.8 m
(defmove :ke-j2 :kind :quick :clip :ke-q2 :startup 7 :active 3 :recovery 13 :dmg 35 :adv-block -2
  :reach 2.6 :arc 100 :on-hit :flinch)                               ; KAESHIGIRI: the backhand
(defmove :ke-j3 :kind :quick :clip :ke-kick :startup 8 :active 3 :recovery 18 :dmg 42 :adv-block -4
  :reach 2.2 :arc 60 :on-hit :stagger :flags (:ender))               ; KENKA-GERI: a front kick to the gut
(defmove :ke-k1 :kind :flash :clip :ke-f1 :startup 16 :active 4 :recovery 20 :dmg 70 :adv-block -3
  :reach 3.0 :arc 120 :on-hit :stagger)                              ; OBURI: the huge two-handed swing
(defmove :ke-k2 :kind :flash :clip :ke-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 60 :adv-block -3
  :reach 2.6 :arc 90 :on-hit :stagger)                               ; KIRIAGE: from the floor up
(defmove :ke-k3 :kind :flash :clip :ke-q3 :clip-s 11 :enter 6 :startup 20 :active 5 :recovery 34 :dmg 80 :adv-block -20
  :reach 2.8 :arc 360 :on-hit :crumple :flags (:ender))              ; BUNMAWASHI: the full spin
(defmove-copy :ke-j2s :ke-j2)
(defmove-copy :ke-k2s :ke-k2)
;; "KITTE MIRO YO": :hold = 6 f in (hit = counter-hit), then super armour up to 60 f storing damage;
;; release (or 60 f) -> the cut, 100 + stored, guard-crushing when stored >= 150 (the hooks decide)
(defmove :ke-stance :kind :sig :clip :ke-stance-hold :clip-2 :ke-stance-cut :callout "KITTE MIRO YO"
  :hold (*stance-in* *stance-hold-max*) :flags (:stance) :blend 6
  :startup 8 :active 4 :recovery 24 :dmg *stance-base-damage* :adv-block -14
  :reach 2.8 :arc 120 :on-hit :knockback :kb 3.0
  :release ken-stance-release)
;; leap 5 m, overhead, a 3 m ground-crack line
(defmove :ke-buttagiru :kind :sp :clip :ke-buttagiru :callout "BUTTAGIRU"
  :startup 22 :active 4 :recovery 26 :dmg 180 :adv-block -14 :slide 5.0
  :vol (:cap 0.0 3.0 0.5 0.6) :on-hit :knockdown :kb 2.0 :flags (:ranged) :on-frame ((22 ken-ground-crack))
  :params (:melee-range 2.6))                          ; the blade within Q1's reach 2.6 m, the crack beyond: ranged
;; dash 6 m at 14 m/s during the 26 active frames (the tick hook); contact = flurry hit 1 of 5
;; (25 each), then :KE-FLURRY (4 more + a 60 launcher). Still holding at the dash: guard-crushing.
(defmove :ke-charge :kind :sp :clip :ke-charge :clip-2 :ke-flurry :callout "ORE NI KIRENEE MON WA NEE"
  :startup 14 :active 26 :recovery 24 :dmg 25 :adv-block -16
  :vol (:cap 0.0 1.4 1.1 0.6) :on-hit :flinch
  :tick ken-charge-tick :on-land ken-flurry
  :params (:dash-speed 14.0))
;; not a command: KEN-FLURRY starts it when the charge connects (the kit's (:ke-charge :land :ke-flurry)
;; string, so Nozarashi derives it too; clip cuts at f4 10 16 22 28, launch f40)
(defmove :ke-flurry :kind :sp :clip :ke-flurry :startup 10 :active 31 :recovery 24 :dmg 25 :adv-block -16
  :reach 2.2 :arc 120 :on-hit :flinch
  :hits ((10 11) (16 17) (22 23) (28 29) (40 41 :dmg 60 :on-hit :launch)))
(defmove :ke-breaker :kind :breaker :clip :ke-breaker :clip-2 :ke-shoulder :callout "SHOULDER CHARGE")
;; O, the Kikon rush module CHARGE: 5 f of aura, then a charge at 13 m/s for at most 36 f that keeps
;; turning at him (150 deg/s) and eats one hit on its armour (a Breaker or a second hit stops it), then
;; the stance's huge cross-body cut: 9.4 m, <= 50 f. A hit with O held: the Kikon on a red opponent,
;; else the follow-up (KIKON-OUTCOME). -14 on block. Cooldown 90.
(defmove :ke-kikon :kind :kikon :clip :ke-charge :clip-2 :ke-stance-cut :clip-s 8 :cine ken-kikon-cine
  :startup 9 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.4 :arc 110 :on-hit :knockback :kb 2.5
  :armor-hits 1 :cooldown 90
  :params (:aura 5 :aim 120.0 :speed 13.0 :dash-max 36 :dash-track 150.0 :look :charge :sfx :laugh))

;;; ================================================================ Nozarashi
(defmove :ke-meteor :kind :sp :clip :ke-meteor :callout "SPLIT THE METEOR"
  :startup 26 :active 4 :recovery 30 :dmg 240 :adv-block -16
  :vol (:cap 0.3 12.0 0.5 0.5) :on-hit :knockdown :kb 3.0 :flags (:ranged) :on-frame ((26 ken-meteor-cut))
  :params (:melee-range 3.4))                          ; the cleaver within KATATE's Q reach (3.38 m), the line beyond: ranged
;; O in Nozarashi, LEAP CLEAVE (his own move: not derived): 8 f of crouch, then a leap at 18 m/s for at
;; most 30 f, the direction locked at take-off (the height is a look, :lift), then the widest cleave,
;; 3.08 m over 160 deg, and a gash where it lands: 10.6 m, <= 49 f. Cooldown 90.
(defmove :ke-kikon-n :kind :kikon :clip :ke-n-leap :clip-2 :ke-stance-cut :clip-s 8 :callout "SKY SPLIT" :cine ken-sky-split-cine
  :startup 11 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 3.08 :arc 160 :on-hit :knockback :kb 2.5 :cooldown 90
  :on-frame ((11 ken-leap-cleave))
  :params (:aura 8 :aim 120.0 :speed 18.0 :dash-max 30 :dash-track 0.0 :look :leap :lift 1.6 :sfx :whoosh-cleaver))

;;; ---------------------------------------------------------------- RYOTE (cup 2): two-handed kendo, straight and long
;;; (their own clips, ken-art.lisp; :clip-s = the clip's authored S, so each plays at speed 1)
(defmove :ke-r-j1 :kind :quick :clip :ke-r-q1 :clip-s 10 :startup 10 :active 3 :recovery 12 :dmg 40 :adv-block -2
  :vol (:cap 0.3 3.9 1.2 0.5) :on-hit :flinch)                       ; MEN: the straight overhead
(defmove :ke-r-j2 :kind :quick :clip :ke-r-kote :startup 9 :active 3 :recovery 13 :dmg 38 :adv-block -2
  :reach 3.6 :arc 60 :on-hit :flinch)                                ; KOTE: the small wrist snap
(defmove :ke-r-j3 :kind :quick :clip :ke-r-q3 :clip-s 14 :startup 10 :active 3 :recovery 18 :dmg 48 :adv-block -4
  :reach 3.8 :arc 140 :on-hit :stagger :flags (:ender))              ; KESA: the diagonal
(defmove :ke-r-k1 :kind :flash :clip :ke-r-f1 :clip-s 19 :startup 19 :active 4 :recovery 20 :dmg 85 :adv-block -3
  :reach 4.2 :arc 160 :on-hit :stagger)                              ; DO: the wide body cut
(defmove :ke-r-k2 :kind :flash :clip :ke-r-tsuki :enter 7 :startup 21 :active 4 :recovery 24 :dmg 68 :adv-block -3
  :vol (:cap 0.3 4.4 1.2 0.5) :on-hit :stagger)                      ; MOROTE-ZUKI: both hands drive it straight out
(defmove :ke-r-k3 :kind :flash :clip :ke-r-f2 :clip-s 21 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 92 :adv-block -20
  :vol (:cap 0.3 4.2 1.2 0.55) :on-hit :crumple :flags (:ender))      ; KABUTO-WARI: the helm splitter
(defmove-copy :ke-r-j2s :ke-r-j2)
(defmove-copy :ke-r-k2s :ke-r-k2)
;;; ---------------------------------------------------------------- NOMIHOSE (cup 3)
;; K: KUKAN-GIRI, the space cut: its blade leaves a rift in the air (f20) that cuts again *RIFT-DELAY* frames
;; later (KEN-RIFT: a :rift hazard, closed if he is hit before it cuts)
(defmove :ke-n-f1 :kind :flash :clip :ke-n-f1 :clip-s 20 :callout "KUKAN-GIRI" :startup 20 :active 4 :recovery 22 :dmg 90
  :adv-block -4 :reach 4.2 :arc 150 :on-hit :stagger :on-frame ((20 ken-rift))
  :params (:rift-dmg 50 :rift-guard 12 :rift-chip 0.2 :rift-vol (:cap 1.0 4.4 1.4 0.5)))
;; Shift+K: NOMIHOSE, Split the Meteor with the whole cup: on its first frame NOME is 0 and he is back in cup 1
;; (KEN-DRINK-DRY), so it resolves at KATATE's x1.0 and an O after it is KATATE's 2-Konpaku Kikon (no O ender: not a string). 390; within
;; 6 m it breaks guard (:crush-range), beyond it is blockable (guard 22)
(defmove :ke-meteor-n :kind :sp :clip :ke-meteor :callout "NOMIHOSE" :startup 26 :active 4 :recovery 30 :dmg 390
  :adv-block -16 :vol (:cap 0.3 12.0 0.5 0.5) :on-hit :knockdown :kb 3.0 :flags (:ranged)
  :on-frame ((0 ken-drink-dry) (26 ken-meteor-cut)) :params (:crush-range 6.0 :melee-range 3.9))   ; blade <= cup 3's MEN 3.9 m

;;; ================================================================ Bankai (卍解) and 片腕 KATAUDE (docs/DUEL_KEN_BANKAI.md)
;;; The oni: the broken cleaver hacks, a fist, one gouge, one drop, the teeth, the shield-and-all cut, the punch and the
;;; split. Every K link, L, SP1, SP2, I and O spends a pip of the arm (UDE); the K links and the specials :rend (armour
;;; and his mirror's stance don't stop them). Frame data: the DUEL_STRINGS §2.1 budget (J 8 / 8 / 9, K1 17, K2 / K3 S_eff 14).
(defmove :ke-b-j1 :kind :quick :clip :ke-q1 :clip-s 7 :startup 8 :active 3 :recovery 12 :dmg 38 :adv-block -2
  :reach 3.2 :arc 100 :on-hit :flinch :slide 1.0)                   ; TATAKI-GIRI: hacked down, lunging like a beast
(defmove :ke-b-j2 :kind :quick :clip :ke-q2 :clip-s 7 :startup 8 :active 3 :recovery 13 :dmg 38 :adv-block -2
  :reach 3.2 :arc 100 :on-hit :flinch)                               ; NAGI-HARAI: the backhand sweep
(defmove :ke-b-j3 :kind :quick :clip :ke-b-fist :startup 9 :active 3 :recovery 18 :dmg 50 :adv-block -4
  :reach 2.0 :arc 60 :on-hit :stagger :slide 0.6 :flags (:ender))    ; GENKOTSU: a left hook to the face
(defmove :ke-b-k1 :kind :flash :clip :ke-f1 :clip-s 16 :startup 17 :active 4 :recovery 20 :dmg 120 :adv-block -3
  :reach 3.6 :arc 120 :on-hit :stagger :guard 28 :flags (:rend))     ; ONATA: the hatchet chop
(defmove :ke-b-k2 :kind :flash :clip :ke-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 100 :adv-block -3
  :reach 3.2 :arc 90 :on-hit :stagger :guard 28 :flags (:rend))      ; EGURI-AGE: gouging up from the floor
(defmove :ke-b-k3 :kind :flash :clip :ke-r-f2 :clip-s 21 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 150 :adv-block -20
  :vol (:cap 0.3 4.0 1.2 0.55) :on-hit :crumple :guard 36 :flags (:ender :rend))   ; TATAKI-OTOSHI: the drop
(defmove-copy :ke-b-j2s :ke-b-j2)
(defmove-copy :ke-b-k2s :ke-b-k2)
;; L, KAMICHIGIRI: a short lunge, the left hand clamps, the teeth: nothing guards it (guard, DRINK, the ward, a parry, a
;; stance, armour); Step / Hoho iframes dodge it. +9 on hit: his J1 combos after it (knob: R 28 -> 30)
(defmove :ke-b-bite :kind :sig :clip :ke-b-bite :callout "KAMICHIGIRI" :startup 10 :active 3 :recovery 28 :dmg 120
  :reach 1.5 :arc 60 :slide 0.8 :on-hit :crumple :flags (:grab :unguardable :rend))
;; Shift+K, TATE-GOTO: through guard and arm together: the whole 6 m line guard-crushes (a Guard Break)
(defmove :ke-b-split :kind :sp :clip :ke-meteor :clip-s 26 :callout "TATE-GOTO" :startup 24 :active 4 :recovery 30 :dmg 260
  :adv-block -16 :vol (:cap 0.3 6.0 0.5 0.5) :on-hit :knockdown :kb 3.0 :flags (:ranged :guard-crush :rend)
  :on-frame ((24 ken-tate-goto)) :params (:melee-range 3.2))
;; Shift+L's follow-up, NAGURI-TOBASHI: the charge connects, then a left straight into the chest, 6 m (not a command: the
;; kit's (:ke-charge :land :ke-b-punch) string, which KEN-FLURRY starts)
(defmove :ke-b-punch :kind :sp :clip :ke-b-fist :clip-s 9 :callout "NAGURI-TOBASHI" :startup 6 :active 3 :recovery 30 :dmg 150
  :adv-block -16 :reach 2.0 :arc 90 :on-hit :knockback :kb 6.0 :guard 22 :flags (:rend))
;; O, MAPPUTATSU: LEAP CLEAVE with the Bankai's Kikon cinematic (the Gerard cleaved in two)
(defmove-copy :ke-b-kikon :ke-kikon-n :clip :ke-b-leap :callout "MAPPUTATSU" :cine ken-oni-kikon-cine)   ; (the oni's leap: art only)
;; 片腕: the base moves at reach x0.7 (the kit derives them); the kick is a leg: as written, under its own name
(defmove-copy :ke-a-j3 :ke-j3)

;;; ================================================================ forms
(defkit :kenpachi :base
  :name "KENPACHI" :body :kenpachi :weapon :ken-katana :stance :ke-stance
  :intro :ke-intro :win :ke-win
  :walk *walk-kenpachi* :run *run-kenpachi* :run-clips (:ke-run :ke-skate-b :ke-slide-r :ke-slide-l) :reishi *reishi-max* :aura :reiatsu
  :cornered *cornered-per-konpaku* :cornered-max *cornered-max* :reset-reiatsu *reset-reiatsu-bonus*
  :absorb-sfx :laugh
  :commands (:q :ke-j1 :f :ke-k1 :sig :ke-stance :sp1 :ke-buttagiru :sp2 :ke-charge
             :breaker :ke-breaker :kikon :ke-kikon)
  :grid (:ke-j1 :ke-j2 :ke-j3 :ke-k1 :ke-k2 :ke-k3 :ke-j2s :ke-k2s)
  :strings ((:ke-charge :land :ke-flurry))
  :awaken-form :nozarashi
  :ai (:intents (:approach 2 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.0 4.0) :pressure (1.5 3.0) :zone (4.0 6.0) :defend (3.0 5.0))
       :moves ((0.0 3.0 :q 5 :f 2 :breaker 1 :sp2 1 :sig 2 nil 3)
               (3.0 4.0 :f 1 :sp1 2 :step 1 nil 2)
               (4.0 6.0 :sp1 4 :sp2 2 nil 1)
               (6.0 99.0 :step 1 :kikon 1 nil 1))                      ; the charge / leap as a poke
       :guard 0.35 :hoho 0.2 :awaken-above 0.0 :sp-cancel-bars 1 :dash 0.8 :kikon-range 9.0
       :react (:projectile :sig :flash-startup :sig) :block-string 0.8))   ; a blocked string goes on (guard pressure)

(defkit :kenpachi :nozarashi :inherit :base    ; cup 1, KATATE: one hand, as the awakening leaves him
  :awakening t :mult *nozarashi-mult* :startup-add *nozarashi-startup* :reach-mult *nozarashi-reach*
  :passives (:projectile-cut) :heal *nozarashi-heal* :form-name "KATATE" :kikon-konpaku 2
  :weapon :nozarashi :stance :ke-n-stance :aura :reiatsu :swing-sfx :whoosh-cleaver
  :enter-clips (:ke-release :ke-nome) :cine ken-nozarashi-cine :respect-callout "OMOSHIREE!"
  :meter (:name "NOME" :max *nome-max* :start *nome-awaken*
          :ladder ((:nozarashi 0.0 0 0.0 0.0) (:ryote *nome-drain-t2* *nome-delay* *nome-up-t2* *nome-down-t2*)
                   (:nomihose *nome-drain-t3* 0 *nome-up-t3* *nome-down-t3*)))
  :meter-gain (:dealt *nome-dealt* :taken *nome-taken* :drunk *nome-drunk*)
  :commands (:sp1 :ke-meteor :kikon :ke-kikon-n)
  ;; toys with his opponent (a Kikon only 0.25 per decision until the last minute: it is worth 2 here; the O ender on
  ;; one who isn't red per cup, :o-ender, docs/DUEL_STRINGS.md §4)
  :ai (:intents (:approach 2 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.0 4.0) :pressure (1.5 3.0) :zone (4.0 6.0) :defend (3.0 5.0))
       :moves ((0.0 3.4 :q 5 :f 2 :sig 3 :breaker 1 :sp2 1 nil 3)
               (3.4 4.2 :f 1 :sp1 2 :step 1 nil 2)
               (4.2 6.0 :sp1 4 :sp2 2 nil 1)
               (6.0 99.0 :step 1 :kikon 1 nil 1))
       :guard 0.35 :hoho 0.2 :awaken-above 0.0 :sp-cancel-bars 1 :dash 0.8 :kikon-range 9.0 :kikon-p 0.25 :o-ender 0.25
       :react (:projectile :sig :flash-startup :sig) :block-string 0.8))

(defkit :kenpachi :ryote :inherit :nozarashi       ; cup 2, RYOTE (NOME >= 40): two-handed kendo, the cut
  :mult *ryote-mult* :startup-add *ryote-startup* :reach-mult *ryote-reach* :form-name "RYOTE" :kikon-konpaku 3
  :passives (:projectile-cut :cut) :stance :ke-r-stance :aura :nozarashi :enter-hook ken-ryote-enter
  :commands (:q :ke-r-j1 :f :ke-r-k1 :sp1 :ke-meteor :kikon :ke-kikon-n)   ; (the cup-1 moves as written: not re-derived)
  :grid (:ke-r-j1 :ke-r-j2 :ke-r-j3 :ke-r-k1 :ke-r-k2 :ke-r-k3 :ke-r-j2s :ke-r-k2s)
  :ai (:intents (:approach 2 :pressure 5 :zone 0 :defend 1)
       :ranges (:approach (2.0 4.5) :pressure (1.5 3.5) :zone (4.0 6.0) :defend (3.0 5.0))
       :moves ((0.0 3.4 :q 5 :f 3 :sig 1 :breaker 1 nil 3)
               (3.4 4.2 :f 2 :sp1 2 :step 1 nil 2)
               (4.2 6.0 :sp1 4 :sp2 2 nil 1)
               (6.0 99.0 :step 1 :kikon 1 nil 1))
       :guard 0.35 :hoho 0.2 :awaken-above 0.0 :sp-cancel-bars 1 :dash 0.8 :kikon-range 9.0 :kikon-p 0.5 :o-ender 0.35
       :react (:projectile :sig :flash-startup :sig) :block-string 0.85))

(defkit :kenpachi :nomihose :inherit :ryote        ; cup 3, NOMIHOSE (NOME = 100): no guard, U drinks; RYOTE's moves
  :mult *nomihose-mult* :form-name "NOMIHOSE" :kikon-konpaku 4 :blade-chip *nomihose-chip* :bankai-form :bankai
  :passives (:projectile-cut :cut :drink) :aura :nomihose :drink-clip :ke-drink :enter-hook ken-nomihose-enter
  :commands (:f :ke-n-f1 :sp1 :ke-meteor-n)
  :strings ((:ke-n-f1 :f :ke-r-k2) (:ke-n-f1 :q :ke-r-j2s))   ; KUKAN-GIRI is cup 3's K1
  :ai (:intents (:approach 3 :pressure 6 :zone 0 :defend 0)
       :ranges (:approach (2.0 4.5) :pressure (1.5 3.5) :zone (4.0 6.0) :defend (3.0 5.0))
       :moves ((0.0 3.4 :q 4 :f 4 :breaker 1 nil 2)
               (3.4 6.0 :f 2 :step 1 nil 1)
               (6.0 99.0 :step 1 :kikon 1 nil 1))
       :guard 0.45 :hoho 0.2 :awaken-above 0.0 :sp-cancel-bars 1 :dash 1.0 :kikon-range 9.0 :kikon-p 0.9 :o-ender 0.6
       :cashout (:punish 30 :near 6.0 :below 60.0)
       ;; the Bankai as a finisher, weighing his own Konpaku (entry leaves him 1): nothing to lose (the opponent's next
       ;; Soul Break would take them all anyway), or the opponent near the end (Reishi <= :opp-below, Konpaku <=
       ;; :opp-konpaku) while he has <= :own-konpaku left; one roll per cup-3 stay (ai.lisp AI-BANKAI-P)
       :bankai (:p 0.6 :opp-below 0.6 :opp-konpaku 4 :own-konpaku 4)
       :react (:projectile :sig :flash-startup :sig) :block-string 0.85))

;;; the Bankai (P in cup 3, red, free: combat.lisp BANKAI!): his Konpaku -> 1, his Reishi -> full (the user's decisions
;;; 2026-09-28); ×1.2; U is still DRINK; every heavy command spends a pip of the arm (UDE, the kit meter)
(defkit :kenpachi :bankai :inherit :nomihose
  :awakening t :mult *bankai-ken-mult* :heal 0 :form-name "BANKAI" :kikon-konpaku 4 :blade-chip *nomihose-chip*
  :bankai-form nil :passives (:projectile-cut :drink)
  :meter (:name "UDE" :max *arm-pips* :start *arm-pips*) :meter-gain nil
  :pips (:n *arm-pips* :to :kataude :cmds (:f :sig :sp1 :sp2 :breaker :kikon))
  :body :kenpachi-oni :weapon :ke-broken :stance :ke-b-stance :aura :oni :hide (:arm-wreck :crack-1 :crack-2 :crack-3 :crack-4)
  :run-clips (:ke-b-run :ke-b-skate-b :ke-b-slide-r :ke-b-slide-l)
  :cine ken-bankai-cine :enter-hook nil :swing-sfx :whoosh-cleaver
  :commands (:q :ke-b-j1 :f :ke-b-k1 :sig :ke-b-bite :sp1 :ke-b-split :sp2 :ke-charge :breaker :ke-breaker :kikon :ke-b-kikon)
  :grid (:ke-b-j1 :ke-b-j2 :ke-b-j3 :ke-b-k1 :ke-b-k2 :ke-b-k3 :ke-b-j2s :ke-b-k2s)
  :strings ((:ke-charge :land :ke-b-punch))
  ;; all in: pressure, K links 0.6 (:string-k), the pips spent before they crack (:pip-hurry), the bite up close only;
  ;; a CPU facing him backs off and waits the arm out (:opp-intent)
  :ai (:intents (:approach 3 :pressure 7 :zone 0 :defend 0)
       :ranges (:approach (2.0 4.5) :pressure (1.2 3.0) :zone (4.0 6.0) :defend (3.0 5.0))
       :moves ((0.0 1.5 :q 3 :f 3 :sig 3 :breaker 1 nil 1)
               (1.5 3.4 :q 4 :f 4 :breaker 1 nil 1)
               (3.4 6.0 :sp1 3 :sp2 2 :step 1 nil 1)
               (6.0 99.0 :kikon 1 :step 1 nil 1))
       :guard 0.2 :hoho 0.2 :awaken-above 0.0 :sp-cancel-bars 2 :dash 1.0 :kikon-range 10.6 :kikon-p 0.9 :o-ender 0.8
       :string-k 0.6 :pip-hurry 90 :block-string 0.85 :opp-intent (:zone 2 :defend 2)))

;;; 片腕 KATAUDE (the arm burst): the rest of the match. The base moves at reach x0.7 (the ruined arm can't extend); the
;;; kick, the Breaker and O (CHARGE) as written; x1.0; U is a guard again; Kikon 3 (the universal awakened count)
(defkit :kenpachi :kataude :inherit :base
  :awakening t :form-name "KATAUDE" :kikon-konpaku 3 :mult 1.0 :reach-mult *kataude-reach*
  :body :kenpachi-oni :weapon :ke-broken :aura nil :hide (:crack-1 :crack-2 :crack-3 :crack-4) :swing-sfx :whoosh-cleaver
  :stance :ke-b-stance :run-clips (:ke-b-run :ke-b-skate-b :ke-b-slide-r :ke-b-slide-l)   ; still the oni (the feral pass)
  :commands (:breaker :ke-breaker :kikon :ke-kikon)
  :grid (:ke-j1 :ke-j2 :ke-a-j3 :ke-k1 :ke-k2 :ke-k3 :ke-j2s :ke-k2s)
  :ai (:intents (:approach 2 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (1.5 3.0) :pressure (1.0 2.0) :zone (4.0 6.0) :defend (3.0 5.0))
       :moves ((0.0 2.0 :q 5 :f 2 :sig 2 :breaker 1 :sp2 1 nil 3)
               (2.0 4.0 :f 1 :sp1 2 :step 1 nil 2)
               (4.0 6.0 :sp2 2 nil 1)
               (6.0 99.0 :step 1 :kikon 1 nil 1))
       :guard 0.35 :hoho 0.2 :awaken-above 0.0 :sp-cancel-bars 2 :dash 0.9 :kikon-range 9.0 :kikon-p 0.5 :o-ender 0.25
       :react (:projectile :sig :flash-startup :sig) :block-string 0.8))

;;; ================================================================ hooks (called through the data's symbols)
(defun ken-rift (e)
  "KUKAN-GIRI f20: the blade's chord stays in the air as a rift, fixed in the world, that cuts *RIFT-DELAY*
frames later (a 2 f window): hazard :rift, hazards.lisp; it closes if he is hit before it cuts."
  (let ((p (pos-of e)))
    (spawn-hazard :rift e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 4.4 :delay (1+ *rift-delay*) :life 2
                          :hw (make-hitwin :dmg (move-param e :rift-dmg) :react :stagger :kb 1.0 :hs *hitstop-heavy*
                                           :chip (move-param e :rift-chip) :guard (move-param e :rift-guard)
                                           :vols (let ((v (move-param e :rift-vol))) (list (make-vol (first v) (rest v)))))))
  (emit :sfx :rift-open e))

(defun ken-drink-dry (e)
  "NOMIHOSE (Shift+K in cup 3), its first frame: the whole cup is drunk at once: NOME 0 and cup 1 now (the one
rung change that doesn't wait for him to be free), so the cut and an O after it resolve in KATATE."
  (setf (gauges-meter (gauges e)) 0f0)
  (clog "~a CASH-OUT" (side-name e))
  (set-form e :nozarashi))

(defun ken-ryote-enter (e)
  "Cup 2: the left hand closes on the handle (a look: the stance clip), a yellow ring."
  (let ((p (pos-of e))) (vfx-shockwave (aref p 0) (aref p 2) 2.5 0.35 :rgb '(1.0 0.85 0.25))))

(defun ken-nomihose-enter (e)
  "Cup 3: the yellow pillar (a full one on the first cup 3 of a match, then a half-height flare: MODEL-T3 counts them, a
look), 2 rings, a 1 f negative frame and a 12 f manga page (feedback :rung)."
  (let ((p (pos-of e)) (m (model e)))
    (incf (model-t3 m))
    (vfx-awaken-burst (aref p 0) 1.0 (aref p 2) (if (> (model-t3 m) 1) :nozarashi-half :nozarashi))
    (vfx-shockwave (aref p 0) (aref p 2) 5.0 0.5 :rgb '(1.0 0.9 0.3))
    (vfx-shockwave (aref p 0) (aref p 2) 3.0 0.35 :rgb '(1.0 1.0 0.9))))

(defun ken-stance-release (e)
  "The stance is released: the cut deals 100 + stored and crushes guard at stored >= 150."
  (let ((f (fighter e)))
    (multiple-value-bind (dmg crush) (stance-release (fighter-stored f))
      (setf (fighter-dmg-bonus f) (- dmg *stance-base-damage*) (fighter-crush f) crush (fighter-stored f) 0)
      (when crush (callout e "KITTE MIRO YO!"))
      (emit :sfx (if crush :laugh :whoosh-heavy) e))))

(defun ken-ground-crack (e)
  "Buttagiru lands: a 3 m crack in the ground (a look)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 3.5 :life 50 :look :crack)
    (ground-scar p (yaw-of e) '(1.2 2.8) 0.9))
  (emit :sfx :ground-crack e))

(defun ground-scar (p yaw ds r)
  "A look: crack marks R m wide at DS metres ahead of P along YAW, that stay for the round, and chips thrown up
(stage.lisp STAGE-MARK / STAGE-DEBRIS; Phase 6 destruction)."
  (dolist (d ds)
    (let ((x (+ (aref p 0) (* d (fwd-x yaw)))) (z (+ (aref p 2) (* d (fwd-z yaw)))))
      (stage-mark :crack x z r) (stage-debris x z 3))))

(defun ken-charge-tick (e)
  "SP2 dash: 14 m/s during the active frames until it touches; still holding the button when the
dash starts = guard-crushing (the Breaker property)."
  (let* ((f (fighter e)) (mv (fighter-move f)) (sf (fighter-sf f)))
    (when (eq (fighter-phase f) :main)
      (when (and (= sf (mv-s mv)) (vpad-down (pilot-vpad (pilot e)) (fighter-button f)))
        (setf (fighter-crush f) t))
      (when (and (<= (mv-s mv) sf) (< sf (+ (mv-s mv) (mv-a mv))) (null (fighter-contact f)) (> (fighter-dist f) 1.2))
        (let ((v (motion-vel (motion e))) (sp (move-param e :dash-speed)) (yaw (yaw-of e)))
          (setf (aref v 0) (f32 (* sp (fwd-x yaw))) (aref v 2) (f32 (* sp (fwd-z yaw)))))))))

(defun ken-flurry (e)
  "The SP2 dash connected: on a hit, the flurry (4 more cuts + a launcher)."
  (when (eq (fighter-contact (fighter e)) :hit)
    (start-move e (kit-next (kit-of e) :ke-charge :land))
    (setf (fighter-contact (fighter e)) :hit (fighter-land-sf (fighter e)) 0)))

(defun ken-leap-cleave (e)
  "LEAP CLEAVE lands: a short gash split into the ground ahead (a look)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 3.0 :life 45 :look :meteor))
  (emit :sfx :ground-crack e))

(defun ken-meteor-cut (e)
  "Split the Meteor: the cleave splits the ground 12 m ahead (a look)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 12.0 :life 60 :look :meteor)
    (ground-scar p (yaw-of e) '(2.0 5.0 8.0 11.0) 1.2))
  (emit :sfx :ground-crack e))

(defun ken-tate-goto (e)
  "TATE-GOTO: the cut goes through guard and arm and splits the ground 6 m ahead (a look)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 6.0 :life 50 :look :meteor)
    (ground-scar p (yaw-of e) '(1.5 3.5 5.5) 1.0))
  (emit :sfx :ground-crack e))

;;; ================================================================ cinematics
;;; The grammar of every cinematic is in cinema.lisp (docs/STYLE_STORM_DESIGN.md §5); Kenpachi (black robe, black
;;; hair) goes on the white card.
(defcine ken-kikon-cine (a v :len 192 :hold 112)
  "Base Kikon (paced by user review 3): beat 0; Kenpachi on a white card, low and dutch under the 呑め、野晒 stamp in
black (his release words), silence; two reckless cuts from two sides, laughing; before the last a held close
wide-angle push in silence; the last cut through the victim: a negative, then a manga page (the blood and the yellow
stay), the Konpaku shatter and a splash; he laughs; a wide from behind."
  (at 0 (face-each-other a v 2.0)
      (cine-clip a :ke-kikon :blend 2 :speed (/ 72.0 142.0))   ; its old timing, slowed to the new beats (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2))
  (at 12 (card :white a) (shot-on a 30 3.0 0.6 :look 1.4 :off -0.8) (lens 44 -12) (silence 52)
      (caption "呑め、野晒" :reading "NOME, NOZARASHI" :sub "MOTTO TANOSHIMASETE KURE YO!" :side 1 :ink t :hanko t))
  (at 70 (card nil) (cine-slash v :cut) (shot-on v 120 3.8 1.2) (lens 55) (play-sfx :laugh))
  (at 98 (cine-slash v :cut) (shot-on v -110 3.6 1.0) (caption-exit))
  (at 122 (hold-both a v 20) (silence 20) (lens 86))
  (during (122 142) (shot-on a 20 (+ 1.5 (* 0.4 u)) 0.5 :look 1.45))   ; a slow pull, not cuts
  (at 142 (cine-slash v :heavy) (shot-pair a v (- (camera-side a)) 5.5 1.3) (lens 55)
      (impact-frame :negative 2)
      (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3))
      (let ((q (pos-of v))) (impact-splash (aref q 0) 0.0 (aref q 2) 16 0.07))
      (play-sfx :kikon-slash) (play-sfx :konpaku-shatter) (shake 0.3 0.35))
  (at 144 (impact-frame :manga 12))
  (at 152 (play-sfx :laugh))
  (at 162 (shot-on a 160 4.2 0.8 :look 1.3) (lens 50)))

(defun cine-slash (v kind)
  "A cinematic cut landing on V: sparks, sound, flash."
  (multiple-value-bind (x y z) (actor-point v 1.2) (vfx-hit x y z kind))
  (play-sfx (if (eq kind :heavy) :cut-heavy :cut))
  (setf (model-flash (model v)) 0.1))

(defcine ken-sky-split-cine (a v :len 162 :hold 40)
  "Nozarashi Kikon (§4.2 sky split; paced by user review 3): beat 0; a long black card, Kenpachi silhouetted with a
yellow back-rim under the 呑め、野晒 stamp, silence; the cleave: a negative, then a manga page, the line of light (white,
ink borders) splits the sky, focus lines, poses held 12 f, the screen halves shear apart; down the cut, then the ground
split from the side, then Kenpachi."
  (at 0 (face-each-other a v 2.6)
      (cine-clip a :ke-kikon-n :blend 2 :speed (/ 25.0 68.0)) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :whoosh-cleaver))
  (at 12 (card :black a) (back-rim 56 1.0 0.85 0.23) (shot-on a 60 4.2 0.7 :look 1.6 :ahead 1.3 :off 0.8) (lens 46 8) (silence 56)
      (caption "呑め、野晒" :reading "NOME, NOZARASHI" :sub "SKY SPLIT" :side 0 :hanko t))
  (at 68 (card nil) (cine-slash v :heavy) (play-sfx :kikon-slash) (play-sfx :ground-crack) (shake 0.4 0.5)
      (impact-frame :negative 2) (hold-both a v 12) (focus-lines 30)
      (shot-on a 180 10.0 3.6 :look 1.2 :ahead 5.0) (lens 60)     ; down the cut: it splits the screen at its centre
      (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3)))
  (at 70 (impact-frame :manga 12))
  ;; (the ground split is part of the look, on the cine clock: a sim hazard would freeze with the sim)
  (during (68 162) (let ((q (pos-of v))) (vfx-sky-split (aref q 0) (aref q 2) (yaw-of a) (/ (- cf 68) 60.0) 1.5)))
  (at 102 (shot-on v 95 7.5 1.2 :look 1.0) (lens 50) (caption-exit))
  (at 132 (shot-on a -20 5.0 0.7 :look 1.4) (lens 45)))

(defcine ken-nozarashi-cine (a v :len 108 :hold 84)
  "NOME, NOZARASHI (§5; paced by user review 3; no eyepatch in any form, TYBW: the release is the whole first beat):
beat 0 on the face close-up, the head down, the reiatsu rising round him; NOME: the head thrown back grinning as it
bursts (a negative); the yellow reiatsu pillar held long on a black card, Kenpachi silhouetted with a yellow back-rim
(the only time yellow floods the frame), a skull flashing in it for 2 drawings (f40-49); close, low and wide-angle while the katana grows into the cleaver, in silence;
the 野晒 / 呑め、 stamp in black on a white card."
  (at 0 (cine-clip a :ke-release :blend 3 :speed (/ 1.0 1.5)) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (setf (model-weapon (model a)) :ken-katana)
      (shot-on a 10 1.9 1.9 :look 1.85)
      (hold-both a v 10) (impact-frame :negative 2) (play-sfx :awaken-rise))
  (at 26 (let ((p (pos-of a)))
        (vfx-awaken-burst (aref p 0) 1.0 (aref p 2) :nozarashi)
        (vfx-shockwave (aref p 0) (aref p 2) 7.0 0.6 :rgb '(1.0 0.9 0.3)))
      (impact-frame :negative 2) (play-sfx :awaken-boom) (shake 0.2 0.3))
  (at 28 (card :black a) (back-rim 30 1.0 0.85 0.23) (shot-on a 0 4.6 0.8 :look 1.6) (lens 52))
  (during (0 108) (let ((p (pos-of a)))                 ; rising through the face close-up (it lifts the hair), full at NOME
                    (vfx-aura (aref p 0) 0.0 (aref p 2) (cond ((< cf 28) 2.0) ((< cf 58) 6.5) (t 3.2)) :nozarashi (/ cf 60.0) (cine-dt)
                              :k (if (< cf 26) (+ 0.1 (* 0.02 cf)) 1.0))))   ; 28-58: the pillar
  (during (40 50) (let* ((p (pos-of a)) (yaw (yaw-of a)))   ; the skull in the pillar, 2 drawings (Phase 6)
                    (vfx-skull (- (aref p 0) (* 0.25 (fwd-x yaw))) 2.9 (- (aref p 2) (* 0.25 (fwd-z yaw))) 0.98)))
  (at 54 (cine-clip a :ke-nome :blend 2))
  (at 58 (card nil) (shot-on a 30 1.6 0.45 :look 1.5) (lens 86 -8) (silence 20))
  (at 78 (setf (model-weapon (model a)) :nozarashi)
      (impact-frame :negative 2) (card :white a) (shot-on a 20 4.4 0.8 :look 1.3 :off 0.9) (lens 42)
      (caption "野晒" :kanji2 "呑め、" :reading "NOME, NOZARASHI" :side 0 :ink t)
      (play-sfx :whoosh-cleaver))
  (at 80 (impact-frame :manga 10)))

;;; ---------------------------------------------------------------- the Bankai (docs/DUEL_KEN_BANKAI.md §1.2, §3.1)
(defparameter *forest-trunks* '((0.03 0.05) (0.1 0.022) (0.62 0.04) (0.71 0.018) (0.8 0.06) (0.93 0.03))
  "The forest card's ink trunks: (x-fraction width-fraction) of the screen; Kenpachi kneels in the gap at the left third.")

(defun ken-forest (cf)
  "The Kusajishi forest (anime ep. 44, [A]; the user's decision 2026-09-28: Yachiru a tiny mono ink silhouette): on the
white card, black ink trunks (a few branches), white petals falling on twos over them, and for two drawings (f24-31) a
small ink child cut-out in front of him. UI space, a look (the cine clock CF)."
  (let* ((w (window-width)) (h (window-height)) (ink '(0.03 0.03 0.047 1)) (paper '(0.96 0.96 0.94 1))
         (dr (floor cf 2)))
    (loop for (fx fw) in *forest-trunks* for i from 0
          do (let* ((x (* fx w)) (tw (* fw w)) (lean (* (if (evenp i) 0.02 -0.015) w)))
               (%ui-poly4 (+ x lean) 0 (+ x lean tw) 0 (+ x (* 1.2 tw)) h (- x (* 0.2 tw)) h ink ink)
               (let ((by (* h (+ 0.18 (* 0.11 (mod i 3))))) (dir (if (evenp i) 1 -1)))      ; a branch
                 (%ui-poly4 (+ x (* 0.5 tw)) by (+ x (* 0.5 tw) (* dir 0.09 w)) (- by (* 0.07 h))
                            (+ x (* 0.5 tw) (* dir 0.09 w)) (- by (* 0.06 h)) (+ x (* 0.5 tw)) (+ by (* 0.02 h)) ink ink))))
    (dotimes (k 18)                                      ; the petals, re-drawn every drawing
      (let* ((px (* w (mod (+ (* k 0.137) (* 0.003 dr) (* 0.01 (sin (+ k dr)))) 1.0)))
             (py (* h (mod (+ (* k 0.071) (* 0.012 dr)) 1.0))) (r (* 0.006 h)))
        (%ui-poly4 px (- py r) (+ px r) py px (+ py r) (- px r) py paper paper)
        (ui-rect-outline (- px r) (- py r) (* 2 r) (* 2 r) ink 1)))
    (when (<= 24 cf 31)                                  ; Yachiru: 2 drawings, then gone
      (let* ((cx (* 0.52 w)) (base (* 0.8 h)) (u (* 0.05 h)) (j (if (< cf 28) 0 (* 0.08 u))))
        (%ui-poly4 (- cx (* 0.35 u)) (- base (* 1.3 u)) (+ cx (* 0.35 u)) (- base (* 1.3 u))
                   (+ cx (* 0.6 u)) base (- cx (* 0.6 u)) base ink ink)                          ; the little kimono
        (dotimes (k 8)                                                                             ; the head
          (let ((a0 (* k 0.785)) (a1 (* (1+ k) 0.785)) (hx cx) (hy (- base (* 1.75 u) j)) (r (* 0.42 u)))
            (%ui-poly4 hx hy (+ hx (* r (cos a0))) (+ hy (* r (sin a0))) (+ hx (* r (cos a1))) (+ hy (* r (sin a1))) hx hy ink ink)))
        (%ui-poly4 (+ cx (* 0.2 u)) (- base (* 2.1 u) j) (+ cx (* 0.55 u)) (- base (* 2.35 u) j)
                   (+ cx (* 0.5 u)) (- base (* 1.95 u) j) (+ cx (* 0.3 u)) (- base (* 1.9 u) j) ink ink)))))   ; a tuft

(defcine ken-bankai-cine (a v :len 186 :hold 120)
  "The Bankai (paced like user review 3: long holds, few shots; the user's decisions 2026-09-28): beat 0, Kenpachi down on
one knee, head bowed, silence (ch. 669: beaten, bleeding out); the Kusajishi forest on a white card, ink trunks, petals,
Yachiru a small ink cut-out for two drawings, the distorted doubled call (anime ep. 44); he rises into the crimson oni,
the BLOOD pillar and two rings, a negative then a manga page; close, low, wide-angle on the face: horns, white irisless
eyes, the roar held in silence; the black card, a BLOOD back-rim, the 卍解 column with the red hanko; a wide from behind,
the pillar on ones. The rules are already settled (his Konpaku 1, Reishi full): only the looks here."
  (at 0 (face-each-other a v)
      (setf (model-body (model a)) (find-body :kenpachi) (model-weapon (model a)) :nozarashi *aura-off* a)
      (cine-clip a :sh-crumple :blend 0 :time 0.95) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (shot-on a 35 3.0 0.7 :look 0.9 :off -0.7) (lens 50 -6)
      (hold-pose v 12) (freeze 12) (impact-frame :negative 2) (silence 12)   ; (a held pose would keep his standing one)
      (let ((p (pos-of a))) (impact-splash (aref p 0) 0.4 (aref p 2) 10 0.05)))
  (at 12 (card :white a) (shot-on a 20 3.6 0.8 :look 0.9 :off -1.0) (lens 44)
      (caption "草鹿" :reading "KUSAJISHI" :sub "KEN-CHAN" :side 1 :ink t))
  (at 14 (play-sfx :yachiru-call))
  (during (12 58) (ken-forest cf))
  (at 58 (card nil) (refresh-look a) (setf *aura-off* nil) (caption-exit)
      (cine-clip a :ke-b-roar :blend 2)
      (let ((p (pos-of a)))
        (vfx-awaken-burst (aref p 0) 0.0 (aref p 2) :oni)
        (vfx-shockwave (aref p 0) (aref p 2) 7.0 0.6 :pal +pal-blood+)
        (vfx-shockwave (aref p 0) (aref p 2) 4.0 0.4 :pal +pal-ink+))
      (shot-on a 25 5.2 1.0 :look 1.6) (lens 55)
      (impact-frame :negative 1) (play-sfx :awaken-boom) (play-sfx :laugh :pitch 0.7) (shake 0.25 0.35))
  (at 60 (impact-frame :manga 12))
  (at 78 (shot-on a 14 1.05 1.5 :look 1.58) (lens 80 -8) (silence 20) (face-beat a :shout 0.6))
  (at 108 (card :black a) (back-rim 58 0.82 0.06 0.11) (shot-on a 20 4.4 0.8 :look 1.3 :off 0.9) (lens 42)
      (cine-clip a :ke-b-stance :blend 8)
      (caption "卍解" :reading "BANKAI" :side 0 :hanko t))
  (at 166 (card nil) (shot-on a 165 5.6 1.7 :look 1.4) (lens 50) (caption-exit))
  (during (58 186) (let ((p (pos-of a)))                ; the pillar: full from the burst, on ones in the wide
                     (vfx-aura (aref p 0) 0.0 (aref p 2) 2.4 :oni (/ cf 60.0) (cine-dt) :k (if (< cf 78) 1.0 0.8)))))

(defcine ken-oni-kikon-cine (a v :len 162 :hold 40)
  "The Bankai's Kikon MAPPUTATSU (also its Soul Break cinematic, the user's decision 2026-09-27): the sky split re-cut in the
oni's colours: beat 0; the black card, a BLOOD back-rim, the oni silhouetted with the broken cleaver raised under 卍解 /
MAPPUTATSU and the hanko, silence; one vertical cut: a negative, then a manga page, the white line splitting the victim
and the screen, the halves shearing apart (ch. 669: the Vollständig Gerard cut in two); the split from the side, ash;
Kenpachi laughing, head back."
  (at 0 (face-each-other a v 2.6) (setf *aura-off* a)      ; (the pillar smoulders out: the cut reads)
      (cine-clip a :ke-b-kikon :blend 2 :speed (/ 25.0 68.0)) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :whoosh-cleaver))
  (at 12 (card :black a) (back-rim 56 0.82 0.06 0.11) (shot-on a 60 4.2 0.7 :look 1.6 :ahead 1.3 :off 0.8) (lens 46 8)
      (silence 56) (caption "卍解" :reading "BANKAI" :sub "MAPPUTATSU" :side 0 :hanko t))
  (at 68 (card nil) (cine-slash v :heavy) (play-sfx :kikon-slash) (play-sfx :ground-crack) (shake 0.45 0.5)
      (impact-frame :negative 2) (hold-both a v 12) (focus-lines 30)
      (shot-on v 0 5.5 1.3 :look 1.1) (lens 55)                  ; face on: the line splits him and the screen
      (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3))
      (let ((q (pos-of v))) (impact-splash (aref q 0) 1.0 (aref q 2) 16 0.08)))
  (at 70 (impact-frame :manga 12))
  (during (68 162) (let ((q (pos-of v))) (vfx-sky-split (aref q 0) (aref q 2) (yaw-of a) (/ (- cf 68) 60.0) 1.5)))
  (at 102 (shot-on v 95 7.5 1.2 :look 1.0) (lens 50) (caption-exit))
  (at 132 (shot-on a 60 4.6 0.7 :look 1.4) (lens 45) (face-beat a :shout 1.0 t) (play-sfx :laugh :pitch 0.8)))
