;;;; ichigo.lisp — KUROSAKI ICHIGO (TYBW), docs/DUEL_ICHIGO.md: his moves (DEFMOVE), his two forms (DEFKIT) and his
;;;; mechanics. :base is the dual-blade Shikai 二刀の斬月 (the long cleaver in the right hand, the hiltless short blade in the
;;;; left, the single horn of his half-Hollow: close-to-mid rushdown, a two-blade rhythm, the cross links that grind a
;;;; guard). The awakening 血鎖の一護 KESSA NO ICHIGO (:kessa, anime-only) overlays the two blades into one Tensa Zangetsu:
;;;; mid-range chain control. It has no hold-guard: U is the chain parry 鎖盾, every Step leaves a reiatsu clone, L is the
;;;; giant Getsuga and its residue, and the one resource is the guard gauge re-skinned as the blood-chain gauge 血鎖 (U
;;;; 20, a catch +40, a clone 15 above a 20 reserve, L 30). Everything of his lives here and in ichigo-art.lisp (the user's
;;;; code layout, docs/DUEL_DESIGN.md "Character code layout"): the shared files only call his :hooks. Clip names are the
;;;; art contract (ichigo-art.lisp, with the looks, auras, sounds, glyphs and the three cinematics). Move names without a
;;;; canon tag in the doc are the game's own.
(in-package :duel)
(declaim (special *p1* *p2*))                         ; (flow.lisp's, read by the debug tests below)

;;; ================================================================ knobs (debug 74000+, ICHIGO-DEBUG)
(defparameter *walk-ichigo* 4.2 "Ichigo's walk (Shikai).")
(defparameter *run-ichigo* 10.0 "Ichigo's run (Shikai).")
(defparameter *walk-kessa* 3.6 "KESSA's walk: he holds ground at chain range.")
(defparameter *run-kessa* 9.0 "KESSA's run.")
(defparameter *ichigo-mult* 1.6 "The Shikai's damage x (74100+k: 0.5 + k / 100; the gate: a light string needs it, as Rukia's) ...")
(defparameter *ichigo-taken* 0.8 "... and the damage it takes x (74200+k).")
(defparameter *kessa-mult* 1.15 "KESSA's damage x (74300+k) ...")
(defparameter *kessa-taken* 0.9 "... and the damage it takes x (74400+k).")
(defparameter *chain-u-cost* 20.0 "The chain parry's price on its frame 0, caught or not (74500+k).")
(defparameter *chain-catch* 40.0 "A melee hit caught by the parry refunds this (74600+k).")
(defparameter *clone-cost* 15.0 "A clone (every KESSA Step) spends this ...")
(defparameter *clone-reserve* 20.0 "... only while this much stays for the parry after it.")
(defparameter *clone-delay* 20 "Frames the clone stands (the tell) before it slashes.")
(defparameter *clone-dmg* 40 "The clone's slash.")
(defparameter *kessa-l-cost* 30.0 "The giant Getsuga's chain price (no cooldown: the gauge is its limiter).")
(defparameter *ai-ic-l-after-k* 0.3 "The CPU's Getsuga after a K link that hit (per hit, both forms).")
(defparameter *ai-ic-parry-p* 0.6 "KESSA's CPU parries a blade / projectile it sees coming into the window this often (74950+k).")

;;; ================================================================ 二刀の斬月 (base)
;;; J is the short blade (fast, short), K the long cleaver (slow, long, heavy on the gauge); a switched link 2 is the
;;; CROSS: both blades at once, the same frames, a heavier guard value (KAESHI-KIBA 12, KOGA 24)
(defmove :ic-j1 :kind :quick :clip :ic-q1 :startup 7 :active 3 :recovery 12 :dmg 32 :adv-block -2 :guard 8
  :reach 2.2 :arc 100 :on-hit :flinch :slide 0.6)                        ; KOKIBA: the short blade flicked, reversed
(defmove :ic-j2 :kind :quick :clip :ic-q2 :startup 7 :active 3 :recovery 13 :dmg 32 :adv-block -2 :guard 8
  :reach 2.2 :arc 100 :on-hit :flinch)                                   ; KAESHI: the wrist turns, back across
(defmove :ic-j3 :kind :quick :clip :ic-spin :startup 8 :active 3 :recovery 18 :dmg 40 :adv-block -4 :guard 8
  :reach 2.4 :arc 200 :on-hit :stagger :flags (:ender))                  ; SOSEN-GIRI: a full turn, both blades out
(defmove :ic-k1 :kind :flash :clip :ic-f1 :startup 16 :active 4 :recovery 20 :dmg 68 :adv-block -3 :guard 16
  :reach 3.0 :arc 150 :on-hit :stagger)                                  ; OKIBA: the cleaver's waist-high sweep
(defmove :ic-k2 :kind :flash :clip :ic-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 60 :adv-block -3 :guard 16
  :reach 3.0 :arc 90 :on-hit :stagger)                                   ; SHOGA: up from the floor
(defmove :ic-k3 :kind :flash :clip :ic-drop :enter 7 :startup 21 :active 5 :recovery 34 :dmg 84 :adv-block -20 :guard 22
  :vol (:cap 0.3 3.4 1.2 0.35) :on-hit :crumple :flags (:ender))         ; RAKUGA: both hands, held, dropped
(defmove-copy :ic-j2s :ic-j2 :clip :ic-cross :clip-s 7 :guard 12)        ; KAESHI-KIBA: after K1, under the cleaver's return
(defmove-copy :ic-k2s :ic-k2 :clip :ic-cross :clip-s 14 :guard 24)       ; KOGA: after J1, both blades in an X
;; L, GETSUGA TENSHO: at f14 a crescent leaves the long blade: a :wave 2.4 m wide (a side Step always clears it), 16 m/s
;; over 10 m; blocked, the hazard's 14 f blockstun. Cooldown 100. After a K link (:l-after-k) the S10 copy combos
(defmove :ic-getsuga :kind :sig :clip :ic-getsuga :callout "GETSUGA TENSHO" :startup 14 :active 0 :recovery 24 :cooldown 100
  :reach 10.0 :on-frame ((14 ichigo-getsuga))
  :params (:width 2.4 :speed 16.0 :range 10.0 :dmg 90 :react :knockback :kb 2.5 :guard 18 :look ichigo-getsuga-look))
(defmove-copy :ic-getsuga-k :ic-getsuga :startup 10 :clip-s 14 :on-frame ((10 ichigo-getsuga)))
;; Shift+K, GETSUGA JUJISHO: the long blade's crescent forms at f12, the short blade's at f20, fused into one cross wave
;; 3.6 m wide, 14 m/s over 12 m, a knockdown; it CUTS every opponent wave / fireball it meets (ICHIGO-TICK), not the
;; ground's discs
(defmove :ic-juji :kind :sp :clip :ic-juji :callout "GETSUGA JUJISHO" :startup 20 :active 0 :recovery 26 :reach 12.0
  :on-frame ((12 ichigo-juji-first) (20 ichigo-juji))
  :params (:width 3.6 :speed 14.0 :range 12.0 :dmg 150 :react :knockdown :kb 2.0 :guard 22 :look ichigo-juji-look))
;; Shift+L, SOGA: a flash-step lunge (5 m over the startup), then the X of both blades: guard 30, -14 on block
(defmove :ic-soga :kind :sp :clip :ic-cross :clip-s 7 :callout "SOGA" :startup 18 :active 4 :recovery 26 :dmg 130 :adv-block -14
  :guard 30 :slide 5.0 :reach 2.6 :arc 140 :on-hit :knockback :kb 2.5 :on-frame ((0 ichigo-soga-vanish)))
(defmove :ic-breaker :kind :breaker :clip :ic-breaker :clip-2 :ic-mine :callout "MINEUCHI")
;; O, the Kikon rush module JUJI: 6 f of aura, a flash step at 30 m/s for <= 14 f (locked), the X strike: 8.6 m. Its
;; Kikon is the Getsuga Tensho infused with a Gran Rey Cero (the user's decision 2026-09-28). Cooldown 90
(defmove :ic-kikon :kind :kikon :clip :sh-run :clip-2 :ic-cross :clip-s 7 :callout "GETSUGA TENSHO" :cine ic-kikon-cine
  :startup 7 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.6 :arc 140 :on-hit :knockback :kb 2.5 :cooldown 90
  :params (:aura 6 :aim 120.0 :speed 30.0 :dash-max 14 :dash-track 0.0 :look :flash-step :sfx :hoho-out))

;;; ================================================================ 血鎖の一護 KESSA NO ICHIGO (the awakening)
;;; one blade plus the chain: the longest J / K reach in the game, ~10 % lighter, light on the guard gauge; the K links
;;; play the Shikai's long-blade clips (the chain is an fx along the hit volume: ICHIGO-AURA-KESSA)
(defmove :ic-k-j1 :kind :quick :clip :ic-k-thrust :startup 10 :active 3 :recovery 12 :dmg 30 :adv-block -2 :guard 6
  :vol (:cap 0.3 3.8 1.1 0.3) :on-hit :flinch)                           ; KUSARI-ZUKI: the thrust, the chain paying out
(defmove :ic-k-j2 :kind :quick :clip :ic-k-lash :startup 9 :active 3 :recovery 13 :dmg 30 :adv-block -2 :guard 6
  :reach 3.4 :arc 120 :on-hit :flinch)                                   ; KUSARI-NAGI: the chain whipped back across
(defmove :ic-k-j3 :kind :quick :clip :ic-k-wrap :startup 10 :active 3 :recovery 18 :dmg 38 :adv-block -4 :guard 6
  :reach 3.6 :arc 200 :on-hit :stagger :flags (:ender))                  ; KUSARI-MAKI: a turn, the chain round him
(defmove :ic-k-k1 :kind :flash :clip :ic-f1 :clip-s 16 :startup 20 :active 4 :recovery 20 :dmg 60 :adv-block -3 :guard 10
  :reach 4.5 :arc 160 :on-hit :stagger)                                  ; KUSARI-BARAI: the sweep, the chain trailing
(defmove :ic-k-k2 :kind :flash :clip :ic-f2 :clip-s 20 :enter 8 :startup 22 :active 4 :recovery 24 :dmg 56 :adv-block -3
  :guard 10 :reach 4.0 :arc 120 :on-hit :stagger)                        ; KUSARI-SEN: the rising cut, chains spiralling
(defmove :ic-k-k3 :kind :flash :clip :ic-drop :clip-s 21 :enter 8 :startup 22 :active 5 :recovery 34 :dmg 76 :adv-block -20
  :guard 14 :vol (:cap 0.3 4.2 1.2 0.35) :on-hit :crumple :flags (:ender))   ; TENSA-OTOSHI: the blade dropped, chains lashing
(defmove-copy :ic-k-j2s :ic-k-j2)                                         ; one blade: no cross links
(defmove-copy :ic-k-k2s :ic-k-k2)
;; U, KUSARI-TATE, the chain parry (a :u hook, ICHIGO-PARRY; 20 chain on frame 0): 360 deg, the window f4-15 (the shared
;; *PARRY-WINDOW*); a melee hit in it is caught (the attacker staggers *PARRY-STUN*, +40 chain) and HIKI-GUSARI answers
;; (the :land string), a ranged hit / hazard in it is blocked with no blockstun (:parry-block), draining its guard value
(defmove :ic-k-parry :kind :sig :clip :ic-k-parry :startup 4 :active 12 :recovery 24 :flags (:parry)
  :on-frame ((0 ichigo-chains-flare)))
(defmove :ic-k-yank :kind :sig :clip :ic-k-yank :startup 6 :active 3 :recovery 20 :dmg 40 :adv-block -12 :guard 10
  :vol (:arc 4.6 360 0.0 2.0) :on-hit :stagger :on-land ichigo-yank-pull :params (:pull 1.8))   ; HIKI-GUSARI: +3
;; L, the giant GETSUGA TENSHO (30 chain, no cooldown): a 4 m crescent, 12 m/s over 8 m, a knockdown; at its end the
;; residue 残月 hangs 1.5 s (one hit, one at a time). Clearly smaller than the Kikon's pitch-black crescent (the user's
;; decision 2026-09-28: 12 m in the cinematic)
(defmove :ic-k-getsuga :kind :sig :clip :ic-getsuga :clip-s 14 :callout "GETSUGA TENSHO" :startup 18 :active 0 :recovery 26
  :reach 8.0 :on-frame ((0 ichigo-l-spend) (18 ichigo-giant))
  :params (:width 4.0 :speed 12.0 :range 8.0 :dmg 110 :react :knockdown :kb 2.0 :guard 20 :look ichigo-giant-look
           :res-life 90 :res-dmg 50 :res-guard 12))
(defmove-copy :ic-k-getsuga-k :ic-k-getsuga :startup 10 :on-frame ((0 ichigo-l-spend) (10 ichigo-giant))
  :params (:width 4.0 :speed 18.0 :range 8.0 :dmg 110 :react :knockdown :kb 2.0 :guard 20 :look ichigo-giant-look
           :res-life 90 :res-dmg 50 :res-guard 12))
;; Shift+K, KUSARI-BIKI: a chain shot along a thin line to 7 m (the blade within 3.8 m, the chain beyond: :ranged), a hit
;; pulls him to 1.6 m and binds him 40 f (+13: a J string combos)
(defmove :ic-k-hiki :kind :sp :clip :ic-k-yank :clip-s 6 :callout "KUSARI-BIKI" :startup 16 :active 3 :recovery 24 :dmg 40
  :adv-block -14 :vol (:cap 0.5 7.0 1.1 0.3) :flags (:ranged) :on-hit :bind :hits ((16 19 :stun 40))
  :on-land ichigo-pull :params (:melee-range 3.8 :pull 1.6))
;; Shift+L, KUSARI-GAKI: chains erupt in a line 3 m ahead, 5 m wide, for 2 s: one hit, and it eats every projectile that
;; touches it (ICHIGO-TICK). One wall at a time
(defmove :ic-k-wall :kind :sp :clip :ic-k-wall :callout "KUSARI-GAKI" :startup 16 :active 0 :recovery 24 :reach 3.0
  :on-frame ((16 ichigo-wall)) :params (:dist 3.0 :width 5.0 :life 120 :dmg 50 :guard 12))
;; O, the module KESSA (ENJO's shape: no dash): the chain flung straight out along a locked 8 m lane; its Kikon is the
;; anime's giant pitch-black Getsuga Tensho (the user's decision 2026-09-28). Cooldown 90
(defmove :ic-k-kikon :kind :kikon :clip :ic-k-stance :clip-2 :ic-k-thrust :clip-s 10 :callout "GETSUGA TENSHO"
  :cine ic-kessa-kikon-cine :startup 16 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0
  :vol (:cap 0.5 8.0 1.2 1.0) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((16 ichigo-lane))
  :params (:aura 6 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0))

;;; ================================================================ forms
(defkit :ichigo :base
  :name "ICHIGO" :body :ichigo :weapon :zangetsu-long :stance :ic-stance :hide (:kessa :mark)
  :intro :ic-intro :win :ic-win :intro-callout "ZANGETSU"
  :walk *walk-ichigo* :run *run-ichigo* :reishi *reishi-max* :swing-sfx :whoosh-heavy :mult *ichigo-mult* :taken *ichigo-taken*
  :commands (:q :ic-j1 :f :ic-k1 :sig :ic-getsuga :sp1 :ic-juji :sp2 :ic-soga :breaker :ic-breaker :kikon :ic-kikon)
  :grid (:ic-j1 :ic-j2 :ic-j3 :ic-k1 :ic-k2 :ic-k3 :ic-j2s :ic-k2s)
  :l-after-k :ic-getsuga-k                      ; L after K1 / K2 / K3 (docs/DUEL_STRINGS.md §12): the combo crescent
  :awaken-form :kessa :aura ichigo-aura-base
  :hooks (:tick ichigo-tick)                    ; JUJISHO's projectile cut
  ;; rushdown: J pressure at 1.4-2.4 m, the cleaver's K links into a guard (:block-string), GETSUGA and SOGA in the
  ;; middle, JUJISHO against a projectile; he awakens only once zoning has hurt him (:ranged-share)
  :ai (:intents (:approach 2 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.6 5.0) :pressure (1.4 2.4) :zone (5.0 7.0) :defend (3.0 5.0))
       :moves ((0.0 2.6 :q 5 :f 3 :breaker 1 :sp2 1)
               (2.6 5.0 :sig 2 :sp2 2 :f 1 :step 1)
               (5.0 9.0 :sp2 2 :sig 2 :sp1 1 :kikon 1)
               (9.0 99.0 :sp1 2 :kikon 1 nil 1))
       :guard 0.4 :hoho 0.3 :dash 0.8 :dash-back 0.1 :block-string 0.8 :l-after-k *ai-ic-l-after-k* :sp-cancel-bars 1
       :kikon-range 8.6 :react (:projectile :sp1) :awaken (:min-taken 150)))

;;; KESSA NO ICHIGO: permanent, no heal, Kikon 3. No hold-guard (U is the parry: the :u hook), a clone on every Step
;;; (:step), L and U paid from the chain gauge (:ok, :hud-guard), a projectile blocked in the parry (:parry-block)
(defkit :ichigo :kessa :inherit :base
  :awakening t :heal 0 :form-name "KESSA" :walk *walk-kessa* :run *run-kessa* :mult *kessa-mult* :taken *kessa-taken*
  :weapon :tensa :hide (:shikai) :stance :ic-k-stance :aura ichigo-aura-kessa :cine ic-kessa-cine :u-tag "U: CHAIN"
  :passives (:parry-block)
  :hooks (:u ichigo-parry :step ichigo-clone :ok ichigo-ok :parried ichigo-catch :tick ichigo-tick
          :hud-guard ichigo-hud-chain :deck ichigo-deck)
  :commands (:q :ic-k-j1 :f :ic-k-k1 :sig :ic-k-getsuga :sp1 :ic-k-hiki :sp2 :ic-k-wall :kikon :ic-k-kikon)
  :grid (:ic-k-j1 :ic-k-j2 :ic-k-j3 :ic-k-k1 :ic-k-k2 :ic-k-k3 :ic-k-j2s :ic-k-k2s)
  :strings ((:ic-k-parry :land :ic-k-yank))
  :l-after-k :ic-k-getsuga-k
  ;; the chain band 3.2-4.4 m; too close, step back (a clone); the pull on a stunned victim beyond J reach; no guard
  ;; rolls (U is the parry, 20 a press): the :reflex times it (ICHIGO-AI-PARRY)
  :ai (:intents (:approach 1 :pressure 1 :zone 3 :defend 2)
       :ranges (:approach (3.8 6.0) :pressure (2.8 3.8) :zone (3.2 4.4) :defend (4.0 6.0))
       :moves ((0.0 2.4 :q 2 :f 1 :breaker 1 :step 3 nil 1)
               (2.4 4.4 :q 5 :f 3 :sig 1 nil 1)
               (4.4 7.5 :sp1 2 :sig 3 :sp2 1 nil 2)
               (7.5 99.0 :sig 2 :kikon 1 :sp2 1 nil 2))
       :guard 0.0 :hoho 0.35 :dash 0.2 :dash-back 0.6 :o-ender 0.2 :l-after-k *ai-ic-l-after-k* :sp-cancel-bars 9
       :kikon-range 8.0 :stun-follow (:sp1 3.8 7.0) :sig-gg 0.5 :reflex ichigo-ai-parry))

;;; ================================================================ the chain gauge (the guard gauge, re-skinned)
(defun chain-spend! (e n)
  "E spends N of the chain gauge (his own spend: the refill waits *GG-DELAY* again; never guardless by it)."
  (let ((g (gauges e))) (setf (gauges-gg g) (f32 (max 0.0 (- (gauges-gg g) n))) (gauges-gg-idle g) 0)))

(defun ichigo-ok (e cmd)
  "KESSA's :ok hook: L is refused below its *KESSA-L-COST* chain."
  (or (not (eq cmd :sig)) (>= (gauges-gg (gauges e)) *kessa-l-cost*)))

(defun ichigo-l-spend (e) "The giant Getsuga's frame 0: its chain." (chain-spend! e *kessa-l-cost*))

(defun ichigo-parry (e)
  "KESSA's :u hook: U pressed from a free state starts KUSARI-TATE for *CHAIN-U-COST* chain (refused below it, or
guardless after a crush). T when it started."
  (let ((g (gauges e)))
    (when (and (not (gauges-guardless g)) (>= (gauges-gg g) *chain-u-cost*))
      (chain-spend! e *chain-u-cost*)
      (start-move e (kit-move (kit-of e) :ic-k-parry) :guard)
      t)))

(defun ichigo-catch (e att)
  "KESSA's :parried hook: a melee hit caught by the chains refunds *CHAIN-CATCH* (the counter, HIKI-GUSARI, is the
:land string)."
  (declare (ignore att))
  (let ((g (gauges e)))
    (setf (gauges-gg g) (f32 (min *gg-max* (+ (gauges-gg g) *chain-catch*))) (gauges-gg-idle g) 0))
  (callout e "KUSARI-TATE")
  (emit :sfx :chain-snap e)
  (clog "~a CHAIN CATCH gg ~d" (side-name e) (round (gauges-gg (gauges e)))))

(defun ichigo-pull-to (att d frames)
  "The chain drags ATT's opponent toward him to D metres over FRAMES (after the hit's own reaction: its slide replaced)."
  (let* ((v (opp-of att)) (p (pos-of att)) (q (pos-of v)) (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2)))
         (dist (sqrt (+ (* dx dx) (* dz dz)))))
    (when (> dist d)
      (set-slide v (- dist d) frames dx dz)
      (emit :sfx :chain-snap att))))

(defun ichigo-yank-pull (e) "HIKI-GUSARI's hit: yanked to :pull m." (ichigo-pull-to e (move-param e :pull) 6))
(defun ichigo-pull (e) "KUSARI-BIKI's hit: pulled to :pull m (and bound)." (ichigo-pull-to e (move-param e :pull) 10))

;;; ================================================================ hazards
(defun ichigo-look (e look x z &key (yaw 0.0) (size 1.0) (life 30) (delay 0) fragile)
  "A look-only hazard (kind :fx) drawn by the function LOOK (ichigo-art.lisp): no hit, no sim effect but its entity."
  (spawn-hazard :fx e :x x :z z :yaw yaw :size size :life life :delay delay :look look :fragile fragile))

(defun ichigo-remove (e look)
  "E's hazards drawn by LOOK go (one clone, one residue, one wall at a time)."
  (do-entities (h (hz hazard))
    (when (and (eql (hazard-owner hz) e) (eq (hazard-look hz) look)) (destroy-entity h))))

(defun ichigo-wave (e look &key (ahead 1.0) (delay 0) (yaw (yaw-of e)))
  "A crescent :wave from the move's :params (:width :speed :range :dmg :react :kb :guard), AHEAD m in front of E, drawn by
LOOK; a blade's hit (:blade: the cut's hit look, not fire)."
  (let ((speed (move-param e :speed)))
    (multiple-value-bind (x z) (ahead e ahead)
      (spawn-hazard :wave e :x x :z z :yaw yaw :speed speed :size (* 0.5 (move-param e :width)) :delay delay
                            :life (round (* 60 (/ (move-param e :range) speed))) :look look
                            :hw (make-hitwin :dmg (move-param e :dmg) :react (move-param e :react) :kb (move-param e :kb)
                                             :hs *hitstop-heavy* :guard (move-param e :guard) :flags '(:blade))))))

(defun ichigo-getsuga (e)
  "GETSUGA TENSHO's crescent leaves the long blade."
  (ichigo-wave e (move-param e :look))
  (emit :sfx :getsuga e))

(defun ichigo-juji-first (e)
  "JUJISHO f12: the long blade's crescent forms on the edge (a look; the wave is f20's)."
  (multiple-value-bind (x z) (ahead e 1.0) (ichigo-look e 'ichigo-form-look x z :yaw (yaw-of e) :size 1.8 :life 10))
  (emit :sfx :getsuga e))

(defun ichigo-juji (e)
  "JUJISHO f20: the two crescents fused into one cross wave (it cuts projectiles: ICHIGO-TICK)."
  (ichigo-wave e (move-param e :look))
  (emit :sfx :getsuga e))

(defun ichigo-soga-vanish (e)
  "SOGA f0: the flash step's vanish (the lunge is the move's slide)."
  (let ((p (pos-of e))) (emit :hoho-out e (aref p 0) (aref p 2))))

(defun ichigo-giant (e)
  "The giant Getsuga: the wave, and its residue 残月 at the wave's end once it has travelled (a still crescent, one hit,
:res-life frames; one at a time)."
  (ichigo-wave e (move-param e :look))
  (ichigo-remove e 'ichigo-residue-look)
  (let* ((range (move-param e :range)) (travel (round (* 60 (/ range (move-param e :speed))))))
    (multiple-value-bind (x z) (ahead e (+ 1.0 range))
      (spawn-hazard :wave e :x x :z z :yaw (yaw-of e) :speed 0.0 :size (* 0.5 (move-param e :width)) :delay travel
                            :life (move-param e :res-life) :look 'ichigo-residue-look
                            :hw (make-hitwin :dmg (move-param e :res-dmg) :react :stagger :hs *hitstop-heavy*
                                             :guard (move-param e :res-guard) :flags '(:blade)))))
  (emit :sfx :getsuga e))

(defun ichigo-wall (e)
  "KUSARI-GAKI f16: the chain fence :dist m ahead, :width wide, for :life frames: a look (:fx; it eats projectiles:
ICHIGO-TICK) and its one hit (a still :wave, gone once it hits). One wall at a time."
  (ichigo-remove e 'ichigo-wall-look)
  (ichigo-remove e 'ichigo-no-look)
  (multiple-value-bind (x z) (ahead e (move-param e :dist))
    (ichigo-look e 'ichigo-wall-look x z :yaw (yaw-of e) :size (* 0.5 (move-param e :width)) :life (move-param e :life))
    (spawn-hazard :wave e :x x :z z :yaw (yaw-of e) :speed 0.0 :size (* 0.5 (move-param e :width)) :life (move-param e :life)
                          :look 'ichigo-no-look
                          :hw (make-hitwin :dmg (move-param e :dmg) :react :stagger :hs *hitstop-heavy* :guard (move-param e :guard)
                                           :flags '(:blade))))
  (emit :sfx :chain-rattle e)
  (emit :sfx :ground-crack e))

(defun ichigo-lane (e)
  "The KESSA module's strike: the chain flung out along the lane (a look; the hit is the move's lane)."
  (let ((p (pos-of e)))
    (ichigo-look e 'ichigo-lane-look (aref p 0) (aref p 2) :yaw (yaw-of e) :size (mv-reach (fighter-move (fighter e))) :life 16))
  (emit :sfx :chain-snap e))

(defun ichigo-chains-flare (e)
  "KUSARI-TATE f0: the chains flare from his neck, wrists and ankles (a look)."
  (let ((p (pos-of e))) (ichigo-look e 'ichigo-flare-look (aref p 0) (aref p 2) :yaw (yaw-of e) :size 1.0 :life 18))
  (emit :sfx :chain-rattle e))

(defun ichigo-clone (e)
  "KESSA's :step hook: a Step's frame 0 leaves a reiatsu clone at the take-off point, facing the opponent, when the chain
gauge can pay *CLONE-COST* and keep *CLONE-RESERVE* and none of his is alive: it stands *CLONE-DELAY* f (the tell),
then slashes (a disc 1 m ahead of it: guarded facing him, :src; gone if he is hit first, :fragile). A hazard: no
contact, no KOSEI."
  (let ((g (gauges e)) (f (fighter e)))
    (when (and (>= (gauges-gg g) (+ *clone-cost* *clone-reserve*)) (not (gauges-guardless g))
               (not (block alive (do-entities (h (hz hazard))
                                   (when (and (eql (hazard-owner hz) e) (eq (hazard-look hz) 'ichigo-clone-look))
                                     (return-from alive t))))))
      (chain-spend! e *clone-cost*)
      (let* ((p (pos-of e)) (yaw (face-yaw-to e (fighter-ox f) (fighter-oz f)))
             (x (+ (aref p 0) (fwd-x yaw))) (z (+ (aref p 2) (fwd-z yaw))))
        (spawn-hazard :freeze e :x x :z z :yaw yaw :size 1.4 :y 2.0 :delay *clone-delay* :life 2 :src t :fragile t
                              :hw (make-hitwin :dmg *clone-dmg* :react :flinch :hs *hitstop-light* :guard 8 :flags '(:blade)))
        (ichigo-look e 'ichigo-clone-look (aref p 0) (aref p 2) :yaw yaw :life 10 :delay *clone-delay* :fragile t))
      (emit :sfx :clone e)
      (clog "~a CLONE gg ~d" (side-name e) (round (gauges-gg g))))))

(defun ichigo-tick (e)
  "Both forms' :tick hook: JUJISHO's cross wave and the chain wall (its look's box) CUT every opponent wave / fireball
they touch (a blade can't cut the ground: his rings and binds stay)."
  (do-entities (h (hz hazard))
    (when (and (eql (hazard-owner hz) e) (member (hazard-look hz) '(ichigo-juji-look ichigo-wall-look))
               (<= (hazard-delay hz) 0) (< (hazard-age hz) (hazard-life hz)))
      (do-entities (o (oz hazard))
        (when (and (not (eql (hazard-owner oz) e)) (member (hazard-kind oz) '(:wave :fireball)) (<= (hazard-delay oz) 0)
                   (let ((r (f32 (max 0.5 (hazard-size oz)))))
                     (if (eq (hazard-kind hz) :fx)            ; the wall: a box 1.2 m deep, 2.4 m tall
                         (obox-cyl-hit-p (hazard-x hz) 1f0 (hazard-z hz) (hazard-yaw hz) (hazard-size hz) 1.2f0 0.6f0
                                         (hazard-x oz) 0f0 (hazard-z oz) r 1.8f0)
                         (hazard-touches-p hz (hazard-x oz) 0f0 (hazard-z oz) r 1.8))))
          (emit :hazard-cut (hazard-x oz) (f32 (+ 1.0 (hazard-y oz))) (hazard-z oz))
          (clog "~a cuts ~a" (side-name e) (hazard-kind oz))
          (destroy-entity o))))))

;;; ================================================================ the CPU's parry (KESSA's :ai :reflex, ai.lisp AI-REFLEX)
(defun ichigo-ai-parry (e b s d)
  "Press U (:guard: the chain parry) when a hit it can see will land inside the window (move frames 4-15 of the parry):
the opponent's non-Breaker move whose hit frame (as perceived, S - SF - the perception delay) is 5-14 frames away and
reaches him, or one of his waves / fireballs 5-14 frames out; one roll per opponent action (the react roll) at
*AI-IC-PARRY-P*. Not below the parry's price. J links (7-10 f, under the perception delay) can't be read: it never tries."
  (let ((g (gauges e)) (p *ai-ic-parry-p*))
    (when (and (>= (gauges-gg g) *chain-u-cost*) (not (gauges-guardless g)) (< (brain-react-roll b) p))
      (let ((lead (- (snap-s s) (snap-sf s) (brain-delay b))))
        (cond ((and (eq (snap-state s) :move) (eq (snap-phase s) :main) (member (snap-kind s) '(:flash :sig :sp :kikon))
                    (<= 5 lead 14) (< d (+ (snap-reach s) 0.6)))
               (why b :parry :guard))
              ((let ((o (opp-of e)) (q (pos-of e)) (hit nil))
                 (do-entities (h (hz hazard))
                   (when (and (not hit) (eql (hazard-owner hz) o) (member (hazard-kind hz) '(:wave :fireball))
                              (> (hazard-hits-left hz) 0) (<= (hazard-delay hz) 0) (> (hazard-speed hz) 0.1))
                     (let* ((dx (- (aref q 0) (hazard-x hz))) (dz (- (aref q 2) (hazard-z hz))) (dist (sqrt (+ (* dx dx) (* dz dz))))
                            (fr (/ (* 60 (max 0.0 (- dist 1.0))) (hazard-speed hz))))
                       (when (<= 5 fr 14) (setf hit t)))))
                 hit)
               (why b :parry-projectile :guard)))))))

;;; ================================================================ the HUD: the chain gauge (the guard bar re-skinned)
(defun ichigo-hud-chain (e x y w h right s tm)
  "KESSA's :hud-guard hook, over the guard bar (X Y W H px, filling from the right when RIGHT): a BLOOD cast on the fill,
an ink link every 10, a white notch at U's 20 and a dim one at the clone's 35, the 鎖 CHAIN label at its outer end."
  (declare (ignore tm))
  (let* ((g (gauges e)) (fr (/ (gauges-gg g) *gg-max*)) (fw (* w (max 0.0 (min 1.0 fr)))))
    (flet ((at (u) (if right (+ x (- w (* u w))) (+ x (* u w)))))
      (unless (gauges-guardless g)
        (ui-rect (if right (+ x (- w fw)) x) y fw h (list 0.82 0.06 0.11 0.55)))
      (loop for i from 1 below 10 do (ui-rect (- (at (/ i 10.0)) 0.5) y 1 h '(0.06 0.06 0.08 0.7)))
      (ui-rect (- (at (/ *chain-u-cost* *gg-max*)) 1) (- y 1) 2 (+ h 2) '(1 1 1 0.95))
      (ui-rect (- (at (/ (+ *clone-cost* *clone-reserve*) *gg-max*)) 0.5) y 1 h '(1 1 1 0.4))
      (hud-text (if (>= (gauges-gg g) *chain-u-cost*) "CHAIN" "CHAIN --") (if right (- x (* 3 s)) (+ x w (* 3 s)))
                (- (+ y (* 0.5 h)) (* 3.5 s)) s '(0.9 0.25 0.3 0.95) :align (if right :right :left)))))

(defun ichigo-deck (e cx cy d)
  "KESSA's :deck hook (one hand): the chain gauge as a BLOOD arc round the thumb, a white tick at U's 20, dim below it."
  (let* ((g (gauges e)) (k (/ (gauges-gg g) *gg-max*)) (r (* d 52f0)) (ok (>= (gauges-gg g) *chain-u-cost*)))
    (%arc (f32 cx) (f32 cy) (f32 r) (* 3f0 d) (f32 k) 0.82 0.06 0.11 (if ok 0.9 0.4))
    (%arc (f32 cx) (f32 cy) (+ (f32 r) (* 3f0 d)) (* 2f0 d) (f32 (/ *chain-u-cost* *gg-max*)) 1.0 1.0 1.0 0.35)))

;;; ================================================================ debug (74000+, docs/DUEL_ICHIGO.md "Knobs")
(defvar *char-debug* nil "(lo hi fn): debug commands a character file handles (debug.lisp).")
(pushnew '(74000 75599 ichigo-debug) *char-debug* :test #'equal)

(defparameter *ichigo-tests*
  ;; k: P1-form P2 P2-form distance P2's action
  '((:base :kenpachi :base 3.0 nil) (:kessa :kenpachi :base 3.0 nil) (:kessa :kenpachi :base 2.6 :f)
    (:kessa :yamamoto :base 7.0 :sig) (:kessa :kenpachi :base 2.6 :breaker) (:base :yamamoto :base 8.0 :sig)
    (:base :kenpachi :base 8.0 nil) (:kessa :kenpachi :base 8.0 nil) (:kessa :yamamoto :base 8.0 :sig) (:kessa :rukia :base 4.0 nil))
  "ICHIGO-TEST k (74000+k): 0 / 1 the forms 3 m from an idle Kenpachi, 2 Kenpachi's K1 into KESSA (press U: the catch),
3 Yamamoto's L wave into KESSA at 7 m (press U: blocked, drained), 4 Kenpachi's Breaker (it breaks the parry), 5 the
Shikai vs Yamamoto's wave at 8 m (Shift+K: JUJISHO cuts it), 6 / 7 the forms 8 m from Kenpachi (the crescents in
flight), 8 KESSA vs Yamamoto's wave at 8 m (Shift+L: the wall eats it), 9 KESSA 4 m from Rukia.")

(defun ichigo-test (k)
  (destructuring-bind (f1 c2 f2 d act) (nth k *ichigo-tests*)
    (ensure-battle :ichigo c2)
    (unless (eq (fighter-form (fighter *p1*)) f1) (force-form *p1* f1))
    (unless (eq (fighter-form (fighter *p2*)) f2) (force-form *p2* f2))
    (place *p1* *p2* d)
    (dolist (e (list *p1* *p2*))
      (let ((g (gauges e)))
        (fill (fighter-cd (fighter e)) 0)
        (setf (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) *fs-max* (gauges-gg g) *gg-max* (gauges-guardless g) nil
              (gauges-reishi g) (gauges-reishi-max g))))
    (when act
      (let ((b (brain *p2*)))
        (force-cmd *p2* act)
        (when (eq act :breaker) (setf (brain-press b) :breaker (brain-press-mod b) nil (brain-press-left b) 60))))))

(defun ichigo-cine-at (name f)
  "Stills: cinematic NAME (P1 Ichigo 3 m from Kenpachi, in the form it belongs to) held at frame F; when it already runs
it continues to F."
  (unless (and *cine* (eq (cine-name *cine*) name))
    (abort-cine)
    (setf *cine-hold* nil)
    (ensure-battle :ichigo :kenpachi) (place *p1* *p2* 3.0)
    (force-form *p1* (if (eq name 'ic-kikon-cine) :base :kessa))
    (start-cine name *p1* *p2*))
  (when *cine* (setf *cine-hold* t (cine-hold *cine*) f)))

(defun ichigo-debug (c)
  "74000+k ICHIGO-TEST k; 74100+k .. 74400+k the forms' damage dealt / taken x (0.5 + k / 100) (Shikai dealt, taken,
KESSA dealt, taken); 74500+k / 74600+k *CHAIN-U-COST* / *CHAIN-CATCH* = k; 74700+k *CLONE-COST* = k; 74800+k *KESSA-L-COST* = k;
74900+k P1's chain gauge = 2k (k < 50, stills), 74950+k *AI-IC-PARRY-P* = k / 50; 75000+f / 75200+f / 75400+f stills of the Shikai Kikon / the KESSA Kikon / the
awakening held at frame f."
  (when (>= c 75000)
    (return-from ichigo-debug
      (ichigo-cine-at (nth (floor (- c 75000) 200) '(ic-kikon-cine ic-kessa-kikon-cine ic-kessa-cine)) (mod (- c 75000) 200))))
  (let ((k (mod c 100)) (b (floor (- c 74000) 100)))
    (case b
      (0 (ichigo-test k))
      (1 (setf (kit-mult (find-kit :ichigo :base)) (+ 0.5 (/ k 100.0))))
      (2 (setf (kit-taken (find-kit :ichigo :base)) (+ 0.5 (/ k 100.0))))
      (3 (setf (kit-mult (find-kit :ichigo :kessa)) (+ 0.5 (/ k 100.0))))
      (4 (setf (kit-taken (find-kit :ichigo :kessa)) (+ 0.5 (/ k 100.0))))
      (5 (setf *chain-u-cost* (float k)))
      (6 (setf *chain-catch* (float k)))
      (7 (setf *clone-cost* (float k)))
      (8 (setf *kessa-l-cost* (float k)))
      (9 (if (< k 50) (setf (gauges-gg (gauges *p1*)) (f32 (* 2 k))) (setf *ai-ic-parry-p* (/ (- k 50) 50.0)))))))
