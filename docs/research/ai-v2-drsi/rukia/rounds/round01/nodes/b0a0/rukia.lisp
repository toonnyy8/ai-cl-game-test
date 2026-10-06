;;;; rukia.lisp — KUCHIKI RUKIA (TYBW), docs/DUEL_RUKIA.md: her moves (DEFMOVE) and her four forms (DEFKIT): :base (the
;;;; Shikai 舞え、袖白雪, a mid-range placer of ice) and the awakening 絶対零度 ZETTAI REIDO, a cold gauge of two stacked
;;;; bars (the kit meter, C 0-200: combat.lisp TEMP-STEP, rules TEMP-BAND) whose band is the form: :m18 (-18 C), :m50
;;;; (-50 C, bar 1 full) and :zero (-273.15 C, both full: rooted, the ward with freeze-touch, ranged hits guarded too). Guarding cools her,
;;;; not guarding warms her, actions spend cold (at -18 only L); colder is slower but longer, harder and wider in every
;;;; button, and the opponent is slower to leave her field. A CRACK (the zero ward broken) empties the gauge. Clip names
;;;; are the art contract (rukia-art.lisp). Below the data: her hooks and her three cinematics (DEFCINE). Every name
;;;; without a canon tag in the doc is the game's own.
(in-package :duel)

;;; ================================================================ Shikai (base)
;;; the J / K strings (docs/DUEL_STRINGS.md §2.1 budget): J1 7 f beats every K1 in the game; the K links frost. The reach
;;; since the J cut (§13): J 0.6x, close; K -10 %
(defmove :ru-j1 :kind :quick :clip :ru-q1 :startup 7 :active 3 :recovery 12 :dmg 34 :adv-block -2
  :reach 1.44 :arc 100 :on-hit :flinch :slide 0.6)                              ; HATSUSHIMO: a one-handed flat cut
(defmove :ru-j2 :kind :quick :clip :ru-q2 :startup 7 :active 3 :recovery 13 :dmg 34 :adv-block -2
  :reach 1.32 :arc 100 :on-hit :flinch)                              ; KAZAHANA: the backhand along the same line
(defmove :ru-j3 :kind :quick :clip :ru-spin :startup 8 :active 3 :recovery 18 :dmg 42 :adv-block -4
  :reach 1.56 :arc 200 :on-hit :stagger :flags (:ender))             ; MAI-SODE: the pirouette, the ribbon whipping round
(defmove :ru-k1 :kind :flash :clip :ru-thrust :startup 17 :active 4 :recovery 20 :dmg 66 :adv-block -3
  :vol (:cap 0.2 2.8 1.1 0.3) :on-hit :stagger :frost 60)            ; SHIMO-TSUKI: the fencer's lunge
(defmove :ru-k2 :kind :flash :clip :ru-ring :enter 7 :startup 21 :active 4 :recovery 24 :dmg 58 :adv-block -3
  :reach 2.5 :arc 140 :on-hit :stagger :frost 60)                    ; HYORIN: the rising turn, a white ring
(defmove :ru-k3 :kind :flash :clip :ru-drop :enter 7 :startup 21 :active 5 :recovery 34 :dmg 84 :adv-block -20
  :vol (:cap 0.3 2.7 1.2 0.35) :on-hit :crumple :frost 90 :flags (:ender)
  :on-frame ((21 rukia-snow-burst)))                                 ; NADARE: both hands, held, dropped; snow bursts
(defmove-copy :ru-j2s :ru-j2)
(defmove-copy :ru-k2s :ru-k2)
;; L, SOME NO MAI: TSUKISHIRO: at f10 the point under the opponent (<= :range m, CAST-POINT) gets a white ring (the tell);
;; :delay frames later a pillar of ice erupts in it: a :bind disc, guardable from her side (:src), fragile (it closes if
;; she is hit first): :dmg + frozen :stun frames + frost. A Step (2.5 m) always clears it. No cooldown: S 12 / R 36.
(defmove :ru-tsukishiro :kind :sig :clip :ru-tsukishiro :callout "SOME NO MAI: TSUKISHIRO" :startup 12 :active 0
  :recovery 36 :flags (:bind) :on-frame ((12 rukia-tsukishiro))   ; (no cooldown, the user 2026-09-29: S 12 / R 36 instead)
  :params (:range 8.0 :radius 1.8 :height 3.0 :delay 24 :dmg 60 :stun 36 :guard 14 :frost 90 :life 8 :tell (21 30)))
;; TSUKISHIRO after a K link (the kit's :l-after-k, the user's decision 2026-09-28: K -> L is a combo): the ring at f8, the
;; pillar 10 f later (f18 < a K link's stagger 26 - its A 4), its clip played at 10 / 8. Its reach is the ring's range, so
;; the follow-up chase (which closes to the reach) leaves her where she stands: the ring is cast at him
(defmove-copy :ru-tsukishiro-k :ru-tsukishiro :startup 8 :clip-s 10 :reach 8.0 :on-frame ((8 rukia-tsukishiro))
  :params (:range 8.0 :radius 1.8 :height 3.0 :delay 10 :dmg 60 :stun 36 :guard 14 :frost 90 :life 8 :tell (8 17)))
;; Shift+K, TSUGI NO MAI: HAKUREN: held 16-64 f, one stab per 16 f (1-4, a spike each); released, the wave of cold
;; (a :wave hazard): wider and harder per stab; a hit freezes :stun frames; a side Step always clears it
(defmove :ru-hakuren :kind :sp :clip :ru-stab :clip-2 :ru-hakuren :callout "TSUGI NO MAI: HAKUREN"
  :hold (16 64) :startup 6 :active 1 :recovery 24 :tick rukia-hakuren-charge :on-frame ((6 rukia-hakuren-wave))
  :params (:speed 12.0 :range 11.0 :width 2.4 :width-per 0.4 :dmg 70 :dmg-per 20 :stun 24 :frost 120 :guard 12 :guard-per 2))
;; Shift+L, SAN NO MAI: SHIRAFUNE: the ice blade grows off the point: a 5 m thrust (her own blade: melee), frost 150
(defmove :ru-shirafune :kind :sp :clip :ru-shirafune :callout "SAN NO MAI: SHIRAFUNE" :startup 16 :active 4 :recovery 28
  :dmg 110 :adv-block -14 :slide 1.0 :vol (:cap 0.3 5.0 1.1 0.3) :on-hit :knockback :kb 2.0 :frost 150
  :on-frame ((13 rukia-shirafune-ice)))
(defmove :ru-breaker :kind :breaker :clip :ru-breaker :clip-2 :ru-hainawa :callout "BAKUDO NO YON: HAINAWA")
;; O, the Kikon rush module ENBU: 6 f of aura, a flash step at 24 m/s for <= 16 f (locked at take-off), then the pirouette:
;; 8.0 m, 360 deg, <= 30 f from the press. Its Kikon is SOME NO MAI: TSUKISHIRO. Cooldown 90.
(defmove :ru-kikon :kind :kikon :clip :sh-run :clip-2 :ru-spin :callout "SOME NO MAI: TSUKISHIRO" :cine ru-kikon-cine
  :startup 8 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.4 :arc 360 :on-hit :knockback :kb 2.5 :cooldown 90
  :params (:aura 6 :aim 120.0 :speed 24.0 :dash-max 16 :dash-track 0.0 :look :flash-step :sfx :hoho-out))

;;; ================================================================ 絶対零度 (the awakened bands, docs/DUEL_RUKIA.md §4)
;; -18: the Shikai grid (reach x1.0) with two bare-hand / ice links of its own (the user's decision 2026-09-28): K1 TOSHU,
;; the left palm catching and freezing (a short lunge); K3 HYOKA, the palm driven into the plaza, an ice flower bursting
;; at his feet. -50 derives it (reach x1.1) with key-edited clips; zero (x1.35, rooted) swaps J2 / K1 / K3. The frames
;; never change with the band (DUEL_STRINGS §2.1): colder is longer reach, harder hits and other motions.
(defmove :ru-a-k1 :kind :flash :clip :ru-palm :startup 17 :active 4 :recovery 20 :dmg 66 :adv-block -3
  :vol (:cap 0.2 2.0 1.2 0.35) :slide 0.8 :on-hit :stagger :frost 90)
(defmove :ru-a-k3 :kind :flash :clip :ru-flower :enter 7 :startup 21 :active 5 :recovery 34 :dmg 84 :adv-block -20
  :reach 2.4 :arc 160 :height (0.0 1.4) :on-hit :crumple :frost 120 :flags (:ender) :on-frame ((21 rukia-ice-flower)))
;; -50 (the links it doesn't derive are written at x1.1): palm and blade together, the pirouette two-handed, both palms down
(defmove-copy :ru-a-k1-50 :ru-a-k1 :clip :ru-palm-50 :vol (:cap 0.2 2.2 1.2 0.35))
(defmove-copy :ru-j3-50 :ru-j3 :clip :ru-spin-50 :reach 1.72)
(defmove-copy :ru-a-k3-50 :ru-a-k3 :clip :ru-flower-50 :reach 2.64)
;; absolute zero (written at x1.35): J2 a palm backhand (the TOSHU clip re-timed), K1 SHIMO-TSUKI's thrust with the ice
;; blade (the reach she lost with her feet), K3 HYOKA with a frost that lasts
(defmove-copy :ru-z-j2 :ru-j2 :clip :ru-palm :clip-s 17 :reach 1.78)
(defmove-copy :ru-z-j2s :ru-z-j2)
(defmove-copy :ru-z-k1 :ru-k1 :vol (:cap 0.2 3.78 1.1 0.3) :frost 90)
(defmove-copy :ru-z-k3 :ru-a-k3 :reach 3.24 :frost 150)
;; L, one family that grows with the cold (the playtest fix: colder is never weaker): a disc round her, guardable
;; facing her (:src). -18 SHIMOBASHIRA, the frost pillars (r 2.5); -50 HYOSHIN, the ice quake (r 3.5, crumple); zero
;; REIDO TOKETSU (r 5.5 = the field, a 45 f freeze: a counter-hit on a Breaker's dash; it cashes the top bar)
(defmove :ru-shimobashira :kind :sig :clip :ru-stab :callout "SHIMOBASHIRA" :startup 12 :active 0 :recovery 22
  :on-frame ((0 rukia-hyoshin-tell) (12 rukia-shimobashira))
  :params (:radius 2.5 :height 0.6 :dmg 60 :frost 90 :guard 12 :react :stagger))
(defmove :ru-hyoshin :kind :sig :clip :ru-stab-2h :callout "HYOSHIN" :startup 14 :active 0 :recovery 22
  :on-frame ((0 rukia-hyoshin-tell) (14 rukia-hyoshin))
  :params (:radius 3.5 :height 0.6 :dmg 85 :frost 120 :guard 16 :react :crumple))
(defmove :ru-reido :kind :sig :clip :ru-reido :clip-s 6 :callout "REIDO TOKETSU" :startup 10 :active 0 :recovery 26
  :on-frame ((10 rukia-reido)) :params (:radius 5.5 :height 2.2 :dmg 120 :stun 45 :frost 150 :guard 20))
;; SP1 HAKUREN colder: -50 a stab every 12 f (hold 12-48), a faster, longer, harder wave; zero no hold: the four stabs at
;; once and the widest, hardest wave (a half-width of 1.8 m: a side Step still clears every one)
(defmove-copy :ru-hakuren-50 :ru-hakuren :hold (12 48)
  :params (:per 12 :speed 14.0 :range 12.0 :width 2.4 :width-per 0.4 :dmg 80 :dmg-per 23 :stun 30 :frost 120 :guard 12 :guard-per 2))
(defmove :ru-hakuren-0 :kind :sp :clip :ru-hakuren :clip-s 6 :callout "TSUGI NO MAI: HAKUREN" :startup 10 :active 1 :recovery 24
  :on-frame ((0 rukia-hakuren-spikes) (10 rukia-hakuren-wave))
  :params (:stabs 4 :speed 16.0 :range 14.0 :width 3.6 :width-per 0.0 :dmg 160 :dmg-per 0 :stun 36 :frost 150 :guard 18 :guard-per 0))
;; SP2 SHIRAFUNE colder: 5.0 m (-18) -> 6.0 m -> 7.5 m planted, crumpling
(defmove-copy :ru-shirafune-50 :ru-shirafune :dmg 125 :vol (:cap 0.3 6.0 1.1 0.3))
(defmove-copy :ru-shirafune-0 :ru-shirafune :dmg 140 :vol (:cap 0.3 7.5 1.1 0.3) :on-hit :crumple :slide 0.0)
;; O in every band, HAKKA NO TOGAME: ENJO's module shape (no dash): the blade raised (a white pillar at her, f4), then
;; levelled: the cold runs off the tip along a locked lane, 6.5 / 7.5 / 9.0 m by band. Its Kikon count never scales (3).
;; Cooldown 90 (the universal O's)
(defmove :ru-hakka :kind :kikon :clip :ru-cold-stance :clip-2 :ru-hakka :callout "HAKKA NO TOGAME" :cine ru-hakka-cine
  :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0 :vol (:cap 0.5 7.5 1.2 1.2)
  :on-hit :knockback :kb 2.0 :frost 120 :cooldown 90 :on-frame ((4 rukia-hakka-pillar) (20 rukia-hakka-sheet))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane))
(defmove-copy :ru-hakka-18 :ru-hakka :vol (:cap 0.5 6.5 1.2 1.2))
(defmove-copy :ru-hakka-0 :ru-hakka :vol (:cap 0.5 9.0 1.2 1.2))

;;; ================================================================ forms
(defkit :rukia :base
  :name "RUKIA" :body :rukia :weapon :sode-no-shirayuki :stance :ru-stance :hide (:ice-trim :hand-crack)
  :intro :ru-intro :win :ru-win :intro-callout "MAE, SODE NO SHIRAYUKI" :intro-weapon (:ru-katana 70)
  :walk *walk-rukia* :run *run-rukia* :reishi *reishi-max* :swing-sfx :whoosh-light :mult *rukia-mult* :taken *rukia-taken*
  :stun-tolerance 13.0                          ; the hidden stun (DUEL_DESIGN.md): light, blown away sooner
  :commands (:q :ru-j1 :f :ru-k1 :sig :ru-tsukishiro :sp1 :ru-hakuren :sp2 :ru-shirafune :breaker :ru-breaker :kikon :ru-kikon)
  :grid (:ru-j1 :ru-j2 :ru-j3 :ru-k1 :ru-k2 :ru-k3 :ru-j2s :ru-k2s)
  :l-after-k :ru-tsukishiro-k                   ; L after K1 / K2 / K3 (docs/DUEL_STRINGS.md §12): the combo ring
  :awaken-form :m18
  ;; a mid-range zoner: the ring and the waves at 5-8 m, J1 up close, Shirafune on a frozen / staggered victim
  ;; (:stun-follow); she awakens only against a melee opponent (:awaken: >= 60 % of >= 150 taken from blades)
  :ai (:intents (:approach 2 :pressure 3 :zone 2 :defend 1)
       :ranges (:approach (2.8 5.0) :pressure (1.0 2.4) :zone (5.0 7.5) :defend (3.5 6.0))
       :moves ((0.0 1.8 :q 6 :f 2 :breaker 1 :sp2 1)                   ; J up close only (DUEL_STRINGS §13), K beyond
               (1.8 2.8 :f 4 :breaker 1 :sp2 1)
               (2.8 5.0 :f 1 :sp2 2 :sig 2 :kikon 1 :step 1)
               (5.0 8.0 :sig 4 :sp1 2 :kikon 2 :step 1)
               (8.0 99.0 :sp1 2 :kikon 2 nil 1))
       :guard 0.4 :hoho 0.35 :sp-cancel-bars 1 :oki :sp1-full :oki-above 0.4 :dash 0.5 :dash-back 0.4 :kikon-range 8.0
       :stun-follow (:sp2 2.4 5.0) :awaken (:melee-share 0.6 :min-taken 150) :l-after-k *ai-ru-l-after-k*
       :sp-ender rukia-ai-sp-ender :reflex rukia-ai-reflex))

;;; -18 C, the awakening's first band: the Shikai grid (+ TOSHU / HYOKA), frost on every hit, no chip on her; U guards
;;; and cools (the cold gauge, the kit meter); only L spends cold here (the user's decision 2026-09-28)
(defkit :rukia :m18 :inherit :base
  :awakening t :form-name "-18C" :walk *walk-m18* :run *run-m18* :passives (:chipless) :frost-touch *frost-touch*
  :mult *rukia-awake-mult* :taken *rukia-awake-taken*
  :meter (:name "COLD" :max *cold-max* :temp t) :warm *ru-warm-m18* :cold *ru-cold-m18* :field *ru-field-m18*
  :reset-form :m18 :u-tag "U: COOL" :hooks (:hoho rukia-hoho-cold)
  :stance :ru-cold-stance :aura rukia-aura-cold :cine ru-awaken-cine :swing-sfx :whoosh-light
  :commands (:f :ru-a-k1 :sig :ru-shimobashira :kikon :ru-hakka-18)
  :grid (:ru-j1 :ru-j2 :ru-j3 :ru-a-k1 :ru-k2 :ru-a-k3 :ru-j2s :ru-k2s)
  :l-after-k t                                  ; L after a K link: the band's own L (S 10-14: a combo as it is)
  :ai (:intents (:approach 2 :pressure 3 :zone 1 :defend 2)
       :ranges (:approach (2.5 4.5) :pressure (1.0 2.2) :zone (4.5 7.0) :defend (3.0 5.0))
       :moves ((0.0 1.8 :q 5 :f 2 :breaker 1 :sig 1)
               (1.8 2.8 :f 3 :breaker 1 :sig 1)
               (2.8 5.0 :sp2 2 :step 1 nil 2)
               (5.0 99.0 :sp1 2 nil 2))
       :guard 0.5 :hoho 0.3 :dash 0.2 :dash-back 0.2 :o-ender 0.25 :l-after-k *ai-ru-l-after-k-awake* :kikon-range 6.5 :sp-cancel-bars 2
       :cool (:p 0.3 :near 3.5) :stun-follow (:sp2 2.4 5.0) :sp-ender rukia-ai-sp-ender :reflex rukia-ai-reflex))

;;; -50 C: slower, hardened, reach x1.1, the rime blade, HYOSHIN for L; every action spends cold now; the whole bar 1
;;; spent (C 0) warms her back to -18, both bars full is absolute zero
(defkit :rukia :m50 :inherit :m18
  :reach-mult 1.1 :form-name "-50C" :walk *walk-m50* :run *run-m50* :mult *rukia-m50-mult* :taken *rukia-m50-taken*
  :frost-touch *frost-touch-m50* :warm *ru-warm-m50* :cold *ru-cold-m50* :field *ru-field-m50*
  :weapon :ru-rime :hide (:hand-crack) :aura rukia-aura-frost
  :commands (:f :ru-a-k1-50 :sig :ru-hyoshin :sp1 :ru-hakuren-50 :sp2 :ru-shirafune-50 :kikon :ru-hakka)
  :grid (:ru-j1 :ru-j2 :ru-j3-50 :ru-a-k1-50 :ru-k2 :ru-a-k3-50 :ru-j2s :ru-k2s)
  :ai (:intents (:approach 1 :pressure 3 :zone 0 :defend 2)
       :ranges (:approach (2.0 3.5) :pressure (1.0 2.3) :zone (3.0 5.0) :defend (2.0 3.5))
       :moves ((0.0 1.9 :q 4 :f 2 :sig 3)
               (1.9 3.5 :f 3 :sig 3)
               (3.5 99.0 :sp2 1 :sp1 1 nil 2))
       :guard 0.45 :hoho 0.25 :dash 0.1 :dash-back 0.1 :o-ender 0.25 :l-after-k *ai-ru-l-after-k-awake* :kikon-range 7.5 :sp-cancel-bars 2
       :cool (:p 0.35 :near 4.0 :no-projectile t :min-gg 50) :stun-follow (:sp2 2.4 6.0) :reflex rukia-ai-reflex
       :sp-ender rukia-ai-sp-ender))

;;; -273.15 C, absolute zero (both bars full): rooted (no walk, run, Step, Hoho, slide or chase: the user's decision), the
;;; strongest version of every button at reach x1.35 with the ice blade, the largest field; the ward (360 deg, no
;;; blockstun, never refills) whose first melee hit freezes its attacker; ranged hits are guarded too (no optic since the
;;; user 2026-09-30); U braces
;;; (stops the warming, drains the guard gauge). No chosen exit: she leaves by spending the top bar, by warming, or by
;;; the CRACK (the ward crushed or broken: RUKIA-CRACK)
(defkit :rukia :zero :inherit :m18
  :reach-mult 1.35 :form-name "-273C" :walk 0.0 :run 0.0 :rooted t :mult *rukia-zero-mult* :taken *rukia-zero-taken*
  :passives (:ward :freeze-touch :chipless) :frost-touch *frost-touch-zero* :warm *ru-warm-zero* :cold *ru-cold-zero*
  :field *ru-field-zero* :crush-hook rukia-crack :u-tag "U: BRACE"
  :body :rukia-zero :weapon :ru-ice :hide (:ice-trim :hand-crack) :stance :ru-zero :aura rukia-aura-zero
  :enter-hook rukia-zero-enter :calm t                ; the white Rukia's face stays composed (never the shout)
  :commands (:f :ru-z-k1 :sig :ru-reido :sp1 :ru-hakuren-0 :sp2 :ru-shirafune-0 :kikon :ru-hakka-0 :breaker nil)
  :grid (:ru-j1 :ru-z-j2 :ru-j3 :ru-z-k1 :ru-k2 :ru-z-k3 :ru-z-j2s :ru-k2s)
  ;; it can't move: answers within its reach (J to 2.1 m, K to 3.4, K1 3.8, REIDO 5.5, SHIRAFUNE 7.5, HAKUREN's wave to 14),
  ;; braces now and then while he is near and the guard gauge can pay; a CPU facing her backs off and waits it out (:opp-intent)
  :ai (:intents (:approach 0 :pressure 3 :zone 0 :defend 2)
       :ranges (:approach (0.0 99.0) :pressure (0.0 99.0) :zone (0.0 99.0) :defend (0.0 99.0))
       :moves ((0.0 2.2 :q 4 :f 3)
               (2.2 3.5 :f 4 nil 1)
               (3.5 5.5 :sig 3 :f 1 nil 1)
               (5.5 7.5 :sp2 1 :sp1 2 nil 2)
               (7.5 14.0 :sp1 2 nil 2)
               (14.0 99.0 nil 1))
       :guard 0.0 :hoho 0.0 :o-ender 0.25 :l-after-k *ai-ru-l-after-k-awake* :kikon-range 9.0 :sp-cancel-bars 2
       :brace (:p 0.2 :near 5.5 :min-gg 30) :opp-intent (:zone 2 :defend 2) :sp-ender rukia-ai-sp-ender))

;;; ================================================================ hooks (called through the data's symbols)
(defun rukia-look (e kind x z &key (yaw 0.0) (size 1.0) (life 30) (delay 0) fragile)
  "A look-only hazard (kind :fx) drawn by the function KIND (rukia-art.lisp): no hit, no sim effect but its entity."
  (spawn-hazard :fx e :x x :z z :yaw yaw :size size :life life :delay delay :look kind :fragile fragile))

(defun rukia-snow-burst (e)
  "NADARE f21: snow bursts from the plaza at the point (a look)."
  (multiple-value-bind (x z) (ahead e 2.4) (rukia-look e 'rukia-burst-look x z :size 1.0 :life 24))
  (emit :sfx :ice-shatter e))

(defun rukia-tsukishiro (e)
  "TSUKISHIRO f10: the point under the opponent (CAST-POINT, <= :range m); its white ring now (the tell), the pillar
:delay frames later: a :freeze disc (:radius x :height; guardable facing her: :src; it closes if she is hit first: :fragile)."
  (let* ((p (pos-of e)) (q (pos-of (opp-of e))) (r (move-param e :radius)) (d (1+ (move-param e :delay))))
    (multiple-value-bind (x z) (cast-point (aref p 0) (aref p 2) (aref q 0) (aref q 2) (move-param e :range))
      (spawn-hazard :freeze e :x x :z z :size r :y (move-param e :height) :delay d :life (move-param e :life) :src t :fragile t
                            :hw (make-hitwin :dmg (move-param e :dmg) :react :bind :stun (move-param e :stun) :hs *hitstop-heavy*
                                             :guard (move-param e :guard) :frost (move-param e :frost) :flags '(:ice)))
      (rukia-look e 'rukia-ring-look x z :size r :delay d :life 36 :fragile t)))
  (emit :sfx :frost-tick e))

(defun rukia-spike (e i)
  "HAKUREN's stab I (0-3): an ice spike in a half circle before her."
  (let* ((a (+ (yaw-of e) (deg (- 45 (* 30 i))))) (p (pos-of e)))
    (rukia-look e 'rukia-spike-look (+ (aref p 0) (* 1.1 (fwd-x a))) (+ (aref p 2) (* 1.1 (fwd-z a))) :size (+ 0.5 (* 0.1 i))
                :life 70)))

(defun rukia-hakuren-charge (e)
  "HAKUREN's hold: a stab into the plaza every :per f (16; -50: 12), 1-4 of them, an ice spike at each."
  (let* ((f (fighter e)) (h (fighter-hold f)) (per (or (move-param e :per) 16)))
    (when (and (plusp h) (zerop (mod h per)) (<= h (* 4 per)))
      (rukia-spike e (1- (floor h per)))
      (emit :sfx :frost-tick e))))

(defun rukia-hakuren-spikes (e)
  "Zero's HAKUREN f0: the four stabs at once."
  (dotimes (i 4) (rukia-spike e i))
  (emit :sfx :frost-tick e))

(defun rukia-stabs (e)
  "HAKUREN's stabs (1-4): the move's :stabs (zero: 4), else one per :per f of the charge (FIGHTER-CHARGE, set when it
was released)."
  (or (move-param e :stabs) (max 1 (min 4 (floor (fighter-charge (fighter e)) (or (move-param e :per) 16))))))

(defun rukia-hakuren-wave (e)
  "HAKUREN f6: the wave of cold leaves the blade: a :wave hazard :speed m/s over :range m, :width + :width-per per stab
wide (a half-width <= 1.8 m: a side Step clears it), :dmg + :dmg-per per stab; a hit freezes :stun frames, frost."
  (let* ((n (1- (rukia-stabs e))) (speed (move-param e :speed)) (w (+ (move-param e :width) (* n (move-param e :width-per)))))
    (multiple-value-bind (x z) (ahead e 1.0)
      (spawn-hazard :wave e :x x :z z :yaw (yaw-of e) :speed speed :size (* 0.5 w)
                            :life (round (* 60 (/ (move-param e :range) speed))) :look 'rukia-wave-look
                            :hw (make-hitwin :dmg (+ (move-param e :dmg) (* n (move-param e :dmg-per))) :react :bind
                                             :stun (move-param e :stun) :hs *hitstop-heavy* :frost (move-param e :frost)
                                             :guard (+ (move-param e :guard) (* n (move-param e :guard-per))) :flags '(:ice))))
    (emit :sfx :ice-rise e)))

(defun rukia-shirafune-ice (e)
  "SHIRAFUNE f13: the ice grows off the point along the thrust (a look; the hit is the move's line)."
  (let ((p (pos-of e)))
    (rukia-look e 'rukia-blade-look (aref p 0) (aref p 2) :yaw (yaw-of e) :size (mv-reach (fighter-move (fighter e))) :life 20))
  (emit :sfx :freeze e))

(defun rukia-ice-flower (e)
  "HYOKA f21: the ice flower bursts at his feet, larger the colder she is (its size follows the link's reach; a look,
the hit is the move's arc)."
  (let ((k (/ (mv-reach (fighter-move (fighter e))) 2.7)))
    (multiple-value-bind (x z) (ahead e (* 1.9 k)) (rukia-look e 'rukia-flower-look x z :size (* 1.1 k k) :life 40)))
  (emit :sfx :ice-shatter e))

(defun rukia-hyoshin-tell (e)
  "HYOSHIN f0: the blade driven into the plaza, frost cracks radiating (the tell), then the quake at f14 (one look)."
  (let ((p (pos-of e)))
    (rukia-look e 'rukia-quake-look (aref p 0) (aref p 2) :size (move-param e :radius) :delay 15 :life 30))
  (emit :sfx :frost-tick e))

(defun rukia-disc (e r h hw)
  "A disc hit round E (radius R, height H) this frame: a :freeze hazard from her position (guardable facing her)."
  (let ((p (pos-of e)))
    (spawn-hazard :freeze e :x (aref p 0) :z (aref p 2) :size r :y h :life 2 :src t :hw hw)))

(defun rukia-hyoshin (e)
  "HYOSHIN f14 (and SHIMOBASHIRA's disc): the ice quake: a disc round her, the move's :react + frost."
  (rukia-disc e (move-param e :radius) (move-param e :height)
              (make-hitwin :dmg (move-param e :dmg) :react (move-param e :react) :kb 1.0 :hs *hitstop-heavy*
                           :guard (move-param e :guard) :frost (move-param e :frost) :flags '(:ice)))
  (emit :sfx :ground-crack e))

(defun rukia-shimobashira (e)
  "SHIMOBASHIRA f12: frost pillars stand up in a ring round her (six spikes, a look) and the disc hits (HYOSHIN's)."
  (let ((p (pos-of e)) (r (* 0.8 (move-param e :radius))))
    (dotimes (i 6)
      (let ((a (+ (yaw-of e) (* i 1.0472))))
        (rukia-look e 'rukia-spike-look (+ (aref p 0) (* r (fwd-x a))) (+ (aref p 2) (* r (fwd-z a))) :size 0.7 :life 40))))
  (rukia-hyoshin e))

(defun rukia-reido (e)
  "REIDO TOKETSU f10: a disc round her (5.5 m, the field's radius) freezes :stun frames; the plaza whitens to its edge.
Its cold (the whole top bar) drops her to -50 once she is free."
  (rukia-disc e (move-param e :radius) (move-param e :height)
              (make-hitwin :dmg (move-param e :dmg) :react :bind :stun (move-param e :stun) :hs *hitstop-heavy*
                           :guard (move-param e :guard) :frost (move-param e :frost) :flags '(:ice)))
  (let ((p (pos-of e))) (rukia-look e 'rukia-burst-look (aref p 0) (aref p 2) :size (move-param e :radius) :life 30))
  (emit :sfx :freeze e))

(defun rukia-hakka-pillar (e)
  "HAKKA f4: a white pillar of cold rises at her (a look)."
  (let ((p (pos-of e))) (rukia-look e 'rukia-pillar-look (aref p 0) (aref p 2) :size 0.9 :life 40))
  (emit :sfx :ice-rise e))

(defun rukia-hakka-sheet (e)
  "HAKKA f20: the cold runs off the tip along the lane (a look; the hit is the move's lane)."
  (let ((p (pos-of e)))
    (rukia-look e 'rukia-sheet-look (aref p 0) (aref p 2) :yaw (yaw-of e) :size (mv-reach (fighter-move (fighter e))) :life 34))
  (emit :sfx :kikon-slash e))

(defparameter *ru-hoho-cold* 50.0 "Cold a Hoho adds when she reappears behind him (-18 / -50; the user 2026-09-30: dive in and freeze).")

(defun rukia-hoho-cold (e)
  "The awakened bands' :hoho hook (the user 2026-09-30, 「Hoho 可以增加冷度量表」): reappearing behind him adds
*RU-HOHO-COLD*, and the band follows at once (TEMP-BAND; the steps' own resolve waits until she is free and warms her
first, so a Hoho to exactly 200 would never reach zero): she lands next to him at -273, the ward up (RUKIA-ZERO-ENTER).
Not in the THAW after a CRACK."
  (let* ((g (gauges e)) (f (fighter e)) (c (min *cold-max* (+ (gauges-meter g) *ru-hoho-cold*))) (band (temp-band c (fighter-form f))))
    (when (plusp (gauges-meter-idle g)) (return-from rukia-hoho-cold))   ; the THAW: nothing cools her
    (setf (gauges-meter g) (f32 c))
    (unless (eq band (fighter-form f))
      (set-form e band)
      (emit :sfx :frost-tick e))))

(defparameter *ai-ru-hoho-in* 0.05 "-50's CPU: chance per free step to Hoho in when that Hoho reaches -273 (RUKIA-AI-HOHO-IN).")

(defun rukia-ai-hoho-in (e b s d)
  "-50's :ai :reflex: beyond 3 m, when a Hoho's cold (RUKIA-HOHO-COLD) would reach -273 and the Hoho is allowed, dive in
now and then (*AI-RU-HOHO-IN* per free step). A command or NIL."
  (declare (ignore s))
  (let ((g (gauges e)) (f (fighter e)))
    (and (> d 3.0) (zerop (gauges-meter-idle g)) (>= (+ (gauges-meter g) *ru-hoho-cold*) *cold-max*)
         (hoho-allowed-p nil (gauges-fs g) (fighter-hoho-lock f) (gauges-burst g)) (< (sim-rnd01) *ai-ru-hoho-in*)
         (why b :hoho-in :hoho))))

;;; ---------------------------------------------------------------- her CPU's action policy (AI v2, docs/DUEL_AI_V2.md)
;;; Every chance is per difficulty (EASY <= NORMAL <= HARD; NORMAL near the shipped CPU, HARD the full version).
(defparameter *ai-ru-k-ender-l* '(:easy 0.05 :normal 0.15 :hard 0.9)
  "Her K3 (the K ender, crumple) hit: the band's L chained after it (the K -> L latch: TSUKISHIRO-K, SHIMOBASHIRA, HYOSHIN,
REIDO), per ender hit (RUKIA-AI-SP-ENDER).")
(defparameter *ai-ru-j-ender-sp2* '(:easy 0.1 :normal 0.3 :hard 0.85)
  "Her J3 (the J ender, stagger) hit: SHIRAFUNE off it (it chases the pushed victim), per ender hit, the bars permitting.")
(defparameter *ai-ru-whiff-sp2* '(:easy 0.0 :normal 0.1 :hard 0.7)
  "A recovering opponent beyond her J1, within SHIRAFUNE's line: SP2 punishes him (RUKIA-AI-REFLEX), one roll per action.")

(defparameter *ai-ru-ender-o* '(:easy 0.0 :normal 0.1 :hard 0.6)
  "An ender hit with neither of those taken: the O ender after all (it chases the pushed victim), per ender hit.")
(defparameter *ai-ru-guard-break* '(:easy 0.1 :normal 0.4 :hard 0.75)
  "He holds guard within 3 m (seen >= *AI-RU-GUARD-BREAK-HOLD* f): HAINAWA (the Breaker), one roll per guard of his.")
(defparameter *ai-ru-guard-break-hold* 10 "... seen held this many frames (the generic CPU waits *AI-GUARD-BREAK-HOLD*).")

(defun rukia-ai-p (e plist)
  "PLIST's chance (:easy :normal :hard) at E's CPU difficulty (NORMAL's without a brain)."
  (let ((b (brain e))) (getf plist (if b (brain-difficulty b) :normal) (getf plist :normal 0.0))))

(defun rukia-ai-bars-p (e)
  "Bars enough for an SP and the kit's reserve (:sp-cancel-bars) after it."
  (>= (floor (gauges-reiatsu (gauges e)) *reiatsu-bar*) (ai-table e :sp-cancel-bars 1)))

(defun rukia-ai-sp-ender (e kit)
  "Her :sp-ender (ai.lisp STRING-REFLEX; a landed ender, no link after it): after a K ender the band's L link (a combo off
the crumple, free in the Shikai, cold in the bands: a chained L overdraws), after a J ender SHIRAFUNE (not at zero: it
would cash the top bar for less than REIDO). A command or NIL."
  (let* ((name (mv-name (fighter-move (fighter e)))) (l (kit-l-link kit name)))
    (cond ((and l (kit-k-link-p kit name) (kit-command-ok-p e :sig kit nil l) (< (sim-rnd01) (rukia-ai-p e *ai-ru-k-ender-l*)))
           :sig)
          ((and (kit-j-link-p kit name) (not (kit-rooted kit)) (kit-command-ok-p e :sp2) (rukia-ai-bars-p e)
                (< (sim-rnd01) (rukia-ai-p e *ai-ru-j-ender-sp2*)))
           :sp2)
          ((and (not (ai-sb-finish-p e)) (kit-command-ok-p e :kikon kit t) (< (sim-rnd01) (rukia-ai-p e *ai-ru-ender-o*))) :kikon))))

(defparameter *ai-ru-anti-breaker* '(:easy 0.2 :normal 0.4 :hard 0.9)
  "An incoming Breaker (aura or dash): meet it with the first of J1 / SHIRAFUNE / K1 whose active frames reach him before
his strike does (RUKIA-AI-ANTI-BREAKER), one roll per phase of his (the generic answer, J1 late, is what's left).")

(defun rukia-ai-anti-breaker (e b s d)
  "J beats I, timed (the generic answer waits for the dash to enter J1's reach + 1.4 m as seen through the perception delay:
too late, his strike lands first). From what she saw: the frames of dash he has run by now (his phase began SNAP-START;
the aura is *BREAKER-AURA*), so where he is now (~0.16 m a frame) and when his strike starts (at *BREAKER-TRIGGER*, then
*BREAKER-STARTUP*). The first of J1, SHIRAFUNE (bars permitting), K1 that is active before that and reaches him then. A
command or NIL."
  (let* ((kit (kit-of e)) (v 0.16)
         (el (- *match-tick* (snap-start s)))
         (aura-left (if (eq (snap-phase s) :aura) (max 0 (- *breaker-aura* el)) 0))
         (ran (if (eq (snap-phase s) :aura) (- el *breaker-aura*) el))       ; dash frames run by now (<= 0: none yet)
         (dr (max *breaker-trigger* (- d (* v (max 0 (min (brain-delay b) ran))))))
         (strike (+ aura-left (/ (- dr *breaker-trigger*) v) *breaker-startup*)))
    (flet ((meets (cmd)
             (let ((mv (kit-command-move kit cmd)))
               (and mv (kit-command-ok-p e cmd)
                    (<= (+ (mv-s mv) 2) strike)
                    (<= (max *breaker-trigger* (- dr (* v (max 0 (- (mv-s mv) aura-left)))))
                        (+ (mv-reach mv) (mv-slide mv) 0.25))))))
      (cond ((meets :q) :q)
            ((and (meets :sp2) (rukia-ai-bars-p e)) :sp2)
            ((meets :f) :f)))))

(defun rukia-ai-reflex (e b s d)
  "Her forms' :reflex: an incoming Breaker met in time (RUKIA-AI-ANTI-BREAKER); a recovering opponent past her J1 but
inside SHIRAFUNE's line, his recovery outlasting its startup after the perception delay: SP2 (one roll per action of
his, *AI-RU-WHIFF-SP2*); at -50 the Hoho in (RUKIA-AI-HOHO-IN)."
  (let* ((kit (kit-of e)) (sp2 (kit-command-move kit :sp2)) (q (kit-command-move kit :q)))
    (cond ((and (eq (snap-kind s) :breaker) (member (snap-phase s) '(:aura :dash)) (< d 6.0)
                (< (brain-react-roll b) (rukia-ai-p e *ai-ru-anti-breaker*)))
           (let ((c (rukia-ai-anti-breaker e b s d))) (and c (why b :anti-breaker-t c))))
          ((and (eq (snap-state s) :guard) (>= (snap-guard-t s) *ai-ru-guard-break-hold*) (< d 3.0)
                (kit-command-ok-p e :breaker) (< (brain-react-roll b) (rukia-ai-p e *ai-ru-guard-break*)))
           (why b :guard-break-t :breaker))
          ((and sp2 (eq (snap-state s) :move) (eq (snap-phase s) :main) (>= (snap-sf s) (snap-active-end s))
                (< (snap-left s) 99) (>= (- (snap-left s) (brain-delay b)) (+ (mv-s sp2) 2))
                (> d (+ (mv-reach q) 0.4)) (< d (- (mv-reach sp2) 0.4))
                (kit-command-ok-p e :sp2) (rukia-ai-bars-p e)
                (< (brain-react-roll b) (rukia-ai-p e *ai-ru-whiff-sp2*)))
           (why b :whiff-sp2 :sp2))
          ((eq (kit-form kit) :m50) (rukia-ai-hoho-in e b s d)))))

(defun rukia-zero-enter (e)
  "Absolute zero (:zero's :enter-hook): entered from a held guard or a Hoho's arrival, the ward is up at once (no hole); a new visit's
freeze-touch; the white burst."
  (let ((f (fighter e)))
    (when (member (fighter-state f) '(:guard :guard-hit :hoho)) (setf (fighter-guard-t f) *guard-raise*))   ; (a Hoho: RUKIA-HOHO-COLD)
    (setf (gauges-froze (gauges e)) nil)
    (let ((p (pos-of e))) (rukia-look e 'rukia-burst-look (aref p 0) (aref p 2) :size 1.4 :life 24))
    (emit :sfx :freeze e)
    (clog "~a ZERO" (side-name e))))

(defun rukia-crack (e)
  "The CRACK (zero's :crush-hook: the ward crushed, bracing ran the guard gauge out, or a Guard Break): the gauge empties
(-18 at once), *CRACK-SELF* burnt (never below 1), a *CRACK-STUN* crumple in place when she isn't in a reaction already,
and the THAW lock (*RU-THAW-LOCK* frames in which guarding doesn't cool: the kit meter's idle clock)."
  (let ((f (fighter e)) (g (gauges e)) (p (pos-of e)))
    (set-form e :m18)
    (setf (gauges-meter g) 0f0 (gauges-meter-idle g) *ru-thaw-lock* (gauges-reishi g) (burn (gauges-reishi g) *crack-self*))
    (unless (member (fighter-state f) '(:stun :air :down :wakeup))
      (set-reaction e :crumple *crack-stun* (aref p 0) (aref p 2) 0.0))
    (emit :cold-crack e)
    (clog "~a CRACK r~d" (side-name e) (gauges-reishi g))))

;;; ================================================================ cinematics
;;; Rukia (black robe) goes on the white card; the Bankai 白霞罸 (white kimono) on the black one.
(declaim (type f32vec *ru-v*))
(defvar *ru-v* (make-f32 3) "A world point (the hand in 白霞罸's last shot).")

(defcine ru-kikon-cine (a v :len 186 :hold 112)
  "SOME NO MAI: TSUKISHIRO (the base Kikon; docs/DUEL_RUKIA.md §5.1): beat 0, the pirouette held; a white card, Rukia
black, the blade and ribbon the only white, under the 初の舞 / 月白 stamp, silence; high and wide: the circle drawn round
the victim; low, wide-angle from outside it: the pillar of ice rises; a held push-in, poses and effects frozen, in
silence; the shatter: a negative, a manga page, the ice and the figure in shards, the Konpaku; a wide, ice dust falling."
  (at 0 (face-each-other a v 2.4)
      (cine-clip a :ru-kikon :blend 2) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :whoosh-heavy :pitch 1.2))
  (at 12 (card :white a) (shot-on a 30 3.0 0.6 :look 1.1 :off -0.8) (lens 44 -10) (silence 58)
      (caption "月白" :kanji2 "初の舞" :reading "SOME NO MAI" :sub "TSUKISHIRO  KIKON" :side 1 :ink t :hanko t))
  (at 70 (card nil) (caption-exit) (shot-pair a v (camera-side a) 8.0 5.2) (lens 50) (play-sfx :frost-tick))
  (during (70 186) (let ((q (pos-of v)))                   ; the circle drawn round him (in 20 f), then the pillar in it
                     (vfx-ru-ring (aref q 0) (aref q 2) 1.8 (min 1.0 (/ (- cf 70) 20.0)) (if (< cf 150) 1.0 (max 0.0 (- 1.0 (/ (- cf 150) 20.0)))))
                     (when (and (>= cf 100) (< cf 152))
                       (vfx-ru-pillar (aref q 0) (aref q 2) 1.8 4.5 (/ (- cf 100) 60.0) (cine-dt)))))
  (at 100 (shot-on v 150 5.5 0.3 :look 1.8) (lens 82) (play-sfx :ice-rise))
  (at 104 (setf (model-flash (model v)) 2.0))
  (at 128 (hold-both a v 22) (silence 22) (lens 70))
  (during (128 150) (shot-on v 150 (- 3.8 (* 0.8 u)) (+ 0.5 (* 0.1 u)) :look 1.4))
  (at 150 (impact-frame :negative 2)
      (multiple-value-bind (x y z) (actor-point v 1.0) (vfx-ru-dust x y z) (vfx-konpaku-shatter x (+ y 0.1) z 3))
      (setf (model-alpha (model v)) 0f0)
      (let ((q (pos-of v))) (impact-splash (aref q 0) 0.0 (aref q 2) 14 0.07))
      (play-sfx :ice-shatter) (play-sfx :konpaku-shatter) (shake 0.25 0.35))
  (at 152 (impact-frame :manga 12))
  (at 170 (shot-on a 160 5.0 1.0 :look 1.2) (lens 48)))

(defcine ru-hakka-cine (a v :len 198 :hold 120)
  "卍解 白霞罸 HAKKA NO TOGAME (the awakened Kikon; §5.2, canon ch. 569-570): beat 0, the strike held; close and low, the
blade raised, silence, a white flash: the Bankai (white kimono, ice crown, white hair); a black card, a white back-rim,
the 卍解 / 白霞罸 stamp; low and wide between two lake-like frost discs, plaza and sky, a pillar with her at its root; along
the blade, the cold runs off the tip to him; held on him frozen, in silence; a manga page: he weathers into ice dust, the
Konpaku; the hand: a crack across its back (flavour only)."
  (at 0 (face-each-other a v 3.0) (setf *aura-off* a)
      (face-beat a :neutral 4.0)                          ; composed: no shout in any shot (the user's decision 2026-09-28)
      (cine-clip a :ru-hakka :blend 2 :speed 0.5) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :freeze))
  (at 12 (shot-on a 25 1.8 0.5 :look 1.3) (lens 84 6) (silence 18) (cine-clip a :ru-hakka :blend 4 :speed 0.25))   ; the blade raised straight up (f4-16 of the clip), then levelled
  (at 24 (setf (model-body (model a)) (find-body :rukia-bankai) (model-weapon (model a)) :ru-ice
               (model-hide (model a)) (hide-set '(:hand-crack)))
      (ui-flash 1 1 1 1 30.0) (play-sfx :awaken-boom :pitch 1.3))
  (at 30 (card :black a) (back-rim 58) (shot-on a 20 4.2 0.8 :look 1.1 :off 0.9) (lens 42)
      (caption "卍解" :kanji2 "白霞罸" :reading "BANKAI" :sub "HAKKA NO TOGAME" :side 0 :hanko t))
  (at 88 (card nil) (caption-exit) (shot-on a 140 7.0 0.4 :look 3.0) (lens 70) (play-sfx :ice-rise) (play-sfx :awaken-rise :pitch 0.6))
  (during (88 198) (let ((p (pos-of a)))                  ; the two lakes of cold, her pillar between them
                     (vfx-ru-lake (aref p 0) (aref p 2) 6.0 0.02 (min 1.0 (/ (- cf 88) 18.0)))
                     (when (< cf 118)                  ; (gone for the over-the-shoulder shot: the lens would sit in it)
                       (vfx-ru-lake (aref p 0) (aref p 2) 6.0 7.5 (min 1.0 (/ (- cf 88) 18.0)))
                       (vfx-ru-pillar (aref p 0) (aref p 2) 1.2 6.0 (/ (- cf 88) 60.0) (cine-dt)))))
  (at 118 (shot-on a 165 2.4 1.5 :look 1.1 :ahead 2.6 :off 0.3) (lens 58) (play-sfx :kikon-slash))   ; over her shoulder
  (during (118 156) (let ((p (pos-of a)) (q (pos-of v)))  ; the cold runs off the tip to him
                      (vfx-ru-sheet (aref p 0) (aref p 2) (aref q 0) (aref q 2) (/ (- cf 118) 60.0) 0.6)))
  (at 136 (shot-on v 30 3.6 0.9 :look 1.1) (lens 64) (hold-both a v 20) (silence 20))
  (during (136 156) (setf (model-flash (model v)) 1.0)   ; frozen solid: encased in ice
    (let ((q (pos-of v))) (vfx-ru-pillar (aref q 0) (aref q 2) 0.7 2.3 (/ (- cf 132) 60.0) (cine-dt)))
    (multiple-value-bind (x y z) (actor-point v 0.9) (vfx-ru-crust x y z (cine-dt))))
  (at 156 (impact-frame :negative 1)
      (multiple-value-bind (x y z) (actor-point v 1.0) (vfx-ru-dust x y z) (vfx-konpaku-shatter x (+ y 0.1) z 3))
      (setf (model-alpha (model v)) 0f0)
      (play-sfx :ice-shatter) (play-sfx :konpaku-shatter) (shake 0.2 0.3))
  (at 158 (impact-frame :manga 12))
  (at 174 (refresh-look a) (setf (model-hide (model a)) (hide-set (remove :hand-crack (kit-hide (kit-of a)))) *aura-off* nil)
      (cine-clip a :ru-hand :blend 0) (lens 40) (play-sfx :hand-crack))
  (during (174 198) (let ((v *ru-v*) (p (pos-of a)) (yaw (yaw-of a)))   ; close on the right hand: the crack across it
                      (joint-point! v (model-joints (model a)) (ji :hand-r) 0f0 -0.04f0 0f0)
                      (cine-cam (+ (aref v 0) (* 0.55 (fwd-x (+ yaw 1.1)))) (+ (aref v 1) 0.12) (+ (aref v 2) (* 0.55 (fwd-z (+ yaw 1.1))))
                                (aref v 0) (aref v 1) (aref v 2))
                      (setf *cine-close* t (aref p 1) 0f0))))

(defcine ru-awaken-cine (a v :len 132 :hold 80)
  "絶対零度 ZETTAI REIDO (the awakening; §6): beat 0, the blade lowered, point down; close on her face: one last white
breath, then none, silence; low from behind: frost spreading from her feet over the plaza; a negative, then the white card,
Rukia black, the 絶対零度 stamp; back in the plaza at -18, the breath frosting again."
  (at 0 (cine-clip a :ru-awaken :blend 3) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :awaken-rise :pitch 1.2))
  (at 12 (shot-on a 12 1.3 1.45 :look 1.32) (lens 70) (silence 26)
      (multiple-value-bind (x y z) (actor-point a 1.18) (vfx-ru-breath x y z (yaw-of a))))
  (at 38 (shot-on a 170 3.2 0.35 :look 0.8) (lens 76 -6) (play-sfx :frost-tick))
  (during (38 132) (let ((p (pos-of a))) (vfx-ru-lake (aref p 0) (aref p 2) (* 4.0 (min 1.0 (/ (- cf 38) 24.0))) 0.02 1.0)))
  (at 46 (play-sfx :frost-tick)) (at 54 (play-sfx :frost-tick))
  (at 62 (impact-frame :negative 2) (card :white a) (shot-on a 20 4.4 0.8 :look 1.1 :off 0.9) (lens 42)
      (caption "絶対零度" :reading "ZETTAI REIDO" :sub "SODE NO SHIRAYUKI" :side 0 :ink t)
      (play-sfx :awaken-boom :pitch 1.2) (shake 0.15 0.3))
  (at 116 (card nil) (caption-exit) (shot-on a -30 6.0 1.4 :look 1.1) (lens 50)
      (multiple-value-bind (x y z) (actor-point a 1.18) (vfx-ru-breath x y z (yaw-of a)))))
