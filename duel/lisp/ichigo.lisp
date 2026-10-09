;;;; ichigo.lisp — KUROSAKI ICHIGO (TYBW), docs/duel/DUEL_ICHIGO.md (v2, the playtest redesign of 2026-09-29): his moves
;;;; (DEFMOVE), his two forms (DEFKIT) and his mechanics. :base is the dual-blade Shikai 二刀の斬月 (the long cleaver in the
;;;; right hand, the hiltless short blade in the left, the half-Hollow's single horn: close-to-mid rushdown, the cross
;;;; links that grind a guard; L is the stance 月待 TSUKIMACHI with a J / K / L / Step follow-up). The awakening 血鎖の一護
;;;; KESSA NO ICHIGO (:kessa) holds one white slab: a normal guard, the easy parry 鎖盾 on L (from blockstun too), the
;;;; clones 分身 (a Step or a Hoho leaves one, up to three; every clone answers each J / K press, reversed: J a heavy, K a
;;;; light), O the clones' self-destructing charge 影討 (its Kikon 千影 worth 2 / 2 / 3 / 4 Konpaku by the clones at the
;;;; press), SP2 the afterimage state 残像. Everything of his lives here and in ichigo-art.lisp (the user's code layout,
;;;; docs/duel/DUEL_DESIGN.md "Character code layout"): the shared files only call his :hooks. Clip names are the art contract.
;;;; Most of his mechanics run in his :tick hook (after the hits of the step): the stance's follow-ups, the parry from
;;;; blockstun, the clones' answers (a J / K press edge), the Hoho clone, the O charge, the afterimages.
(in-package :duel)
(declaim (special *p1* *p2* *match-tick* *mode* *gate* *gate-seed0* *pairs* *match-seed*))   ; (flow.lisp's, debug.lisp's)

;;; ================================================================ knobs (debug 74000-75599, ICHIGO-DEBUG)
(defparameter *walk-ichigo* 4.2 "Ichigo's walk (Shikai).")
(defparameter *run-ichigo* 10.0 "Ichigo's run (Shikai).")
(defparameter *walk-kessa* 3.6 "KESSA's walk.")
(defparameter *run-kessa* 9.0 "KESSA's run.")
(defparameter *ichigo-mult* 1.0 "The Shikai's damage x (74100+k: 0.5 + k / 100; the user 2026-09-29: 1.6 -> 1.3 -> 1.0) ...")
(defparameter *ichigo-taken* 0.8 "... and the damage it takes x (74200+k; 0.7 for one build, back to 0.8 by the user 2026-09-29).")
(defparameter *kessa-mult* 0.95 "KESSA's damage x (74300+k; the user 2026-09-29: 1.35 -> 1.1 -> 0.95) ...")
(defparameter *kessa-taken* 1.0 "... and the damage it takes x (74400+k).")
;; the Shikai's stance 月待 TSUKIMACHI
(defparameter *tsuki-up* 6 "The stance's frame where it is up: the follow-ups fire from here.")
(defparameter *tsuki-tap* 30 "Frames the stance holds past its f6 on a tap of L ...")
(defparameter *tsuki-max* 60 "... and at most while L is held; then R 14.")
(defparameter *tsuki-dash-fs* 10.0 "TSUKIWATARI's flash-step price (once per stance).")
;; KESSA's parry 鎖盾 KUSARI-TATE (L)
(defparameter *kessa-parry-cost* 10.0 "The parry's guard-gauge price on its frame 0 (refused below it or guardless) ...")
(defparameter *kessa-parry-catch* 20.0 "... a catch refunds this (net +10; 74600+k) ...")
(defparameter *kessa-parry-stun* 40 "... and the caught attacker staggers this long (the shared 32 lengthened: the :parried hook).")
;; the clones 分身 BUNSHIN
(defparameter *clone-max* 3 "Live clones at most; a 4th replaces the oldest.")
(defparameter *clone-life* 300 "A clone's frames (74700+k: 10k).")
(defparameter *clone-cost* 15.0 "A clone (Step or Hoho) spends this much guard gauge; below it, or guardless, no clone (the user
2026-09-29: the v2 rework had made them free).")
(defparameter *clone-lag* 6 "A clone's answer starts this long after the press.")
(defparameter *clone-scale* 0.7 "A clone hit's damage x (its guard value too): every clone answers every press (the user's
choice), so the per-hit share is the knob (the worst case, a J string with three clones, docs/duel/DUEL_ICHIGO.md v2).")
(defparameter *clone-burst-dmg* 30 "O's strike gains this per charging clone (74800+k).")
(defparameter *clone-konpaku* '(2 2 3 4) "The Kikon's Konpaku by the clones at the O press, 0 / 1 / 2 / 3 (the user's table).")
;; SP2 残像 ZANZO
(defparameter *zanzo-life* 360 "The afterimage state's frames.")
(defparameter *zanzo-lag* 10 "An echo replays his move this many frames behind ...")
(defparameter *zanzo-mult* 0.5 "... at this x of its damage and guard value.")
;; the CPU
(defparameter *ai-ic-l-after-k* 0.3 "The Shikai CPU's stance after a K link that hit (per hit).")
(defparameter *ai-ic-parry-p* 0.35 "KESSA's CPU parries a hit it sees coming into the window this often (74950+k: k / 50;
NORMAL's: EASY 0.6x, HARD every one, the v2 layering) ...")
(defparameter *ai-ic-parry-bs-p* 0.3 "... and parries from blockstun after a blocked K link this often (NORMAL's: EASY 0.6x,
HARD 0.8).")
(defparameter *ai-kessa-o-p* 0.04 "KESSA's CPU: O per step with >= 2 clones within 8.6 m (x2 with 3), before the bank.")
(defparameter *ai-kessa-bank-at* 0.45 "KESSA's CPU banks clones for 千影 (side Steps to 2, 3 with the gauge) once the
opponent's Reishi is under this fraction (red is 0.30), so the O that comes (the ender, the rush) takes 3-4 Konpaku.")
(defparameter *ai-kessa-clone-j-p* 0.08 "KESSA's CPU: J / K per step while an idle clone is in its answer's reach of him.")

;;; ================================================================ 二刀の斬月 (base)
;;; J is the short blade (fast, short), K the long cleaver (slow, long, heavy on the gauge); a switched link 2 is the
;;; CROSS: both blades at once, the same frames, a heavier guard value (KAESHI-KIBA 12, KOGA 24). The reach since the J cut
;;; (docs/duel/DUEL_STRINGS.md §13): J1 / J2 0.5x (the short blade, a step in; KAESHI-KIBA's X closed at his chest: :ic-cross-j),
;;; J3 0.6x (the cleaver held up in the turn), K -10 %
(defmove :ic-j1 :kind :quick :clip :ic-q1 :startup 7 :active 3 :recovery 12 :dmg 32 :adv-block -2 :guard 8
  :reach 1.1 :arc 100 :on-hit :flinch :slide 0.6)                        ; KOKIBA: the short blade flicked, reversed
(defmove :ic-j2 :kind :quick :clip :ic-q2 :startup 7 :active 3 :recovery 13 :dmg 32 :adv-block -2 :guard 8
  :reach 1.1 :arc 100 :on-hit :flinch)                                   ; KAESHI: the wrist turns, back across
(defmove :ic-j3 :kind :quick :clip :ic-spin :startup 8 :active 3 :recovery 18 :dmg 40 :adv-block -4 :guard 8
  :reach 1.44 :arc 200 :on-hit :stagger :flags (:ender))                 ; SOSEN-GIRI: a full turn, both blades out
(defmove :ic-k1 :kind :flash :clip :ic-f1 :startup 16 :active 4 :recovery 20 :dmg 68 :adv-block -3 :guard 16
  :reach 2.7 :arc 150 :on-hit :stagger)                                  ; OKIBA: the cleaver's waist-high sweep
(defmove :ic-k2 :kind :flash :clip :ic-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 60 :adv-block -3 :guard 16
  :reach 2.7 :arc 90 :on-hit :stagger)                                   ; SHOGA: up from the floor
(defmove :ic-k3 :kind :flash :clip :ic-drop :enter 7 :startup 21 :active 5 :recovery 34 :dmg 84 :adv-block -20 :guard 22
  :vol (:cap 0.3 3.0 1.2 0.35) :on-hit :crumple :flags (:ender))         ; RAKUGA: both hands, held, dropped
(defmove-copy :ic-j2s :ic-j2 :clip :ic-cross-j :clip-s 7 :guard 12)        ; KAESHI-KIBA: after K1, under the cleaver's return
(defmove-copy :ic-k2s :ic-k2 :clip :ic-cross :clip-s 14 :guard 24)       ; KOGA: after J1, both blades in an X
;; GETSUGA TENSHO (the stance's L branch): at f14 a crescent leaves the long blade: a :wave 2.4 m wide (a side Step always
;; clears it), 16 m/s over 10 m; blocked, the hazard's 14 f blockstun
(defmove :ic-getsuga :kind :sig :clip :ic-getsuga :callout "GETSUGA TENSHO" :startup 14 :active 0 :recovery 34
  :reach 10.0 :on-frame ((14 ichigo-getsuga))
  :params (:width 2.4 :speed 16.0 :range 10.0 :dmg 90 :react :knockback :kb 2.5 :guard 18 :look ichigo-getsuga-look))
;; L, 月待 TSUKIMACHI (v2 §2; RoS's Syzygy): side-on, the short blade thrust at him, the cleaver drawn back; up at f6, then
;; held 30 f (60 while L is held), R 14. No defence. From f6 the first J / K / L / Step (ICHIGO-TICK, TSUKI-STEP) fires
;; RANGETSU / TSUKI-OTOSHI / GETSUGA / TSUKIWATARI; the follow-ups are its non-button :strings (:tsuki-j ...). L after a
;; K link opens it at f4 (the S2 copy), every branch combos. The Step branch dashes 3.5 m and comes back into the stance
;; (the re-entry copy, at f6: a fresh window), once per stance
(defmove :ic-tsuki :kind :sig :clip :ic-tsuki :startup 6 :active 0 :recovery 74 :track 360.0
  :flags (:step-branch))                    ; (its Step is TSUKIWATARI: a one-hand up-flick stays a Step, 2026-10-06)
(defmove-copy :ic-tsuki-k2 :ic-tsuki :enter 4)
(defmove-copy :ic-tsuki-re :ic-tsuki :enter 6)
(defmove :ic-tsuki-j :kind :sig :clip :ic-rangetsu :callout "RANGETSU" :startup 8 :active 12 :recovery 18 :dmg 18
  :adv-block -6 :guard 5 :reach 2.4 :arc 120 :slide 2.4 :hs *hitstop-light*
  :hits ((8 9) (11 12) (14 15) (17 20 :on-hit :stagger)))                ; 乱月 RANGETSU: a lunge, four short-blade slashes
(defmove :ic-tsuki-k :kind :sig :clip :ic-tsuki-otoshi :callout "TSUKI-OTOSHI" :startup 18 :active 4 :recovery 30 :dmg 100
  :adv-block -10 :guard 30 :reach 2.6 :arc 100 :slide 4.0 :on-hit :crumple)   ; 月落: the pounce (4 m, past TSUKIWATARI's 3.5: the user 2026-09-30)
;; (no cooldown, the user 2026-09-29: the branch's R 34 after a crescent, plus the stance's entry, is what stops a spam)
(defmove-copy :ic-tsuki-l :ic-getsuga :startup 8 :clip-s 14 :on-frame ((8 ichigo-getsuga)))
(defmove :ic-tsuki-dash :kind :sig :clip :ic-tsuki :startup 12 :active 0 :recovery 0
  :on-frame ((0 ichigo-tsuki-dash) (11 ichigo-tsuki-return)))            ; 月渡 TSUKIWATARI: the flash-step dash
;; Shift+K, GETSUGA JUJISHO: the long blade's crescent forms at f12, the short blade's at f20, fused into one cross wave
;; 3.6 m wide, 14 m/s over 12 m, a knockdown; it CUTS every opponent wave / fireball it meets (ICHIGO-TICK)
(defmove :ic-juji :kind :sp :clip :ic-juji :callout "GETSUGA JUJISHO" :startup 20 :active 0 :recovery 26 :reach 12.0
  :on-frame ((12 ichigo-juji-first) (20 ichigo-juji))
  :params (:width 3.6 :speed 14.0 :range 12.0 :dmg 150 :react :knockdown :kb 2.0 :guard 22 :look ichigo-juji-look))
;; Shift+L, SOGA: a flash-step lunge (5 m over the startup), then the X of both blades: guard 30, -14 on block
(defmove :ic-soga :kind :sp :clip :ic-cross :clip-s 7 :callout "SOGA" :startup 18 :active 4 :recovery 26 :dmg 130 :adv-block -14
  :guard 30 :slide 5.0 :reach 2.6 :arc 140 :on-hit :knockback :kb 2.5 :on-frame ((0 ichigo-soga-vanish)))
(defmove :ic-breaker :kind :breaker :clip :ic-breaker :clip-2 :ic-mine :callout "MINEUCHI")
;; O, the Kikon rush module JUJI: 6 f of aura, a flash step at 30 m/s for <= 14 f (locked), the X strike: 8.6 m. Its
;; Kikon is the Getsuga Tensho infused with a Gran Rey Cero. Cooldown 90
(defmove :ic-kikon :kind :kikon :clip :sh-run :clip-2 :ic-cross :clip-s 7 :callout "GETSUGA TENSHO" :cine ic-kikon-cine
  :startup 7 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.6 :arc 140 :on-hit :knockback :kb 2.5 :cooldown 90
  :params (:aura 6 :aim 120.0 :speed 30.0 :dash-max 14 :dash-track 0.0 :look :flash-step :sfx :hoho-out))

;;; ================================================================ 血鎖の一護 KESSA NO ICHIGO (the awakening)
;;; one white slab, no point and no guard: cuts only (the clones carry the range now); the J one-handed, the K two-handed
;;; (since the J cut, §13: J 0.6x with the slab's cuts pulled in, :ic-k-jab / :ic-k-wrap-j; the clones keep the long clips)
(defmove :ic-k-j1 :kind :quick :clip :ic-k-jab :startup 8 :active 3 :recovery 12 :dmg 30 :adv-block -2 :guard 8
  :reach 1.56 :arc 110 :on-hit :flinch)                                  ; 板薙 ITA-NAGI: swept up and across
(defmove :ic-k-j2 :kind :quick :clip :ic-k-back :startup 8 :active 3 :recovery 13 :dmg 30 :adv-block -2 :guard 8
  :reach 1.56 :arc 110 :on-hit :flinch)                                  ; 返板 KAESHI-ITA: the backhand
(defmove :ic-k-j3 :kind :quick :clip :ic-k-wrap-j :clip-s 10 :startup 9 :active 3 :recovery 18 :dmg 40 :adv-block -4 :guard 8
  :reach 1.68 :arc 200 :on-hit :stagger :flags (:ender))                 ; 板旋 ITA-SEN: a full turn, the slab held close
(defmove :ic-k-k1 :kind :flash :clip :ic-f1 :clip-s 16 :startup 18 :active 4 :recovery 20 :dmg 66 :adv-block -3 :guard 14
  :reach 2.9 :arc 150 :on-hit :stagger)                                  ; 大板 OITA: the waist-high sweep
(defmove :ic-k-k2 :kind :flash :clip :ic-f2 :clip-s 20 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 58 :adv-block -3
  :guard 14 :reach 2.9 :arc 90 :on-hit :stagger)                         ; 昇板 SHO-ITA: the rising cut
(defmove :ic-k-k3 :kind :flash :clip :ic-drop :clip-s 21 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 80 :adv-block -20
  :guard 20 :vol (:cap 0.3 3.2 1.2 0.35) :on-hit :crumple :flags (:ender))   ; 天鎖落 TENSA-OTOSHI: dropped with both hands
(defmove-copy :ic-k-j2s :ic-k-j2)                                         ; one blade: no cross links
(defmove-copy :ic-k-k2s :ic-k-k2)
;; the clones' answers (not a kit's: ICHIGO-CLONE-STEP plays them): J a heavy, K a light (the user's reversal)
(defmove :ic-c-heavy :kind :flash :clip :ic-f1 :clip-s 16 :startup 16 :active 4 :recovery 20 :dmg 50 :guard 12
  :reach 3.0 :arc 150 :on-hit :stagger)                                  ; 影断 KAGE-DACHI
(defmove :ic-c-heavy3 :kind :flash :clip :ic-drop :clip-s 21 :startup 18 :active 5 :recovery 30 :dmg 60 :guard 14
  :vol (:cap 0.3 3.4 1.2 0.35) :on-hit :crumple)
(defmove :ic-c-light :kind :quick :clip :ic-k-cut :startup 8 :active 3 :recovery 12 :dmg 26 :guard 6
  :reach 2.4 :arc 110 :on-hit :flinch)                                   ; 影薙 KAGE-NAGI
(defmove :ic-c-light3 :kind :quick :clip :ic-k-wrap :startup 9 :active 3 :recovery 18 :dmg 32 :guard 6
  :reach 2.8 :arc 200 :on-hit :stagger)
;; L, 鎖盾 KUSARI-TATE, the parry (v2 §5.3): 360 deg, its own window f2-25 (the move param :window: rules PARRY-FRAME-P),
;; 10 guard gauge on frame 0; from blockstun too (ICHIGO-TICK); a melee hit in the window is caught (the attacker
;; staggers *KESSA-PARRY-STUN*, +20 gauge) and 残月返し answers (the :land string); a ranged hit / hazard in it is
;; blocked with no blockstun (:parry-block); a whiff is R 18
(defmove :ic-k-parry :kind :sig :clip :ic-k-parry :startup 2 :active 24 :recovery 18 :flags (:parry)
  :params (:window (2 25)) :on-frame ((0 ichigo-parry-open)))
;; 残月返し ZANGETSU-GAESHI: the catch's counter: a pull to 1.6 m, a top-down cut, a crumple (+15: J1 combos)
(defmove :ic-k-gaeshi :kind :sig :clip :ic-drop :clip-s 21 :callout "KUSARI-TATE" :startup 6 :active 3 :recovery 22 :dmg 80
  :adv-block -12 :guard 14 :reach 3.0 :arc 100 :on-hit :crumple :on-frame ((0 ichigo-gaeshi-pull)) :params (:pull 1.6))
;; Shift+K, KUSARI-BIKI: a chain shot along a thin line to 7 m (the blade within 3.8 m, the chain beyond: :ranged), a hit
;; pulls him to 1.6 m and binds him 40 f (+13: a J string combos)
(defmove :ic-k-hiki :kind :sp :clip :ic-k-yank :clip-s 6 :callout "KUSARI-BIKI" :startup 16 :active 3 :recovery 24 :dmg 40
  :adv-block -14 :vol (:cap 0.5 7.0 1.1 0.3) :flags (:ranged) :on-hit :bind :hits ((16 19 :stun 40))
  :on-land ichigo-pull :params (:melee-range 3.8 :pull 1.6))
;; Shift+L, 残像 ZANZO (v2 §5.6): the slab swept before his face, a ghost peels off him; for *ZANZO-LIFE* every attack of
;; his is echoed *ZANZO-LAG* f later at *ZANZO-MULT* (2 bars; refused while it runs)
(defmove :ic-k-zanzo :kind :sp :clip :ic-k-zanzo :callout "ZANZO" :startup 12 :active 0 :recovery 16
  :on-frame ((12 ichigo-zanzo-on)))
;; O, 影討 KAGE-UCHI (v2 §5.5): the flash-step rush (8.6 m) and a vertical cut; every live clone at the press charges and
;; bursts on the strike's frame: its damage is the strike's (+30 per clone, the move's bonus); its Kikon 千影 is worth
;; 2 / 2 / 3 / 4 Konpaku by those clones. Cooldown 90
(defmove :ic-k-kikon :kind :kikon :clip :sh-run :clip-2 :ic-drop :clip-s 21 :callout "KAGE-UCHI" :cine ic-kessa-kikon-cine
  :startup 7 :active 3 :recovery 24 :dmg 70 :adv-block -14 :guard 20 :reach 2.8 :arc 120 :on-hit :knockback :kb 2.5
  :cooldown 90 :params (:aura 6 :aim 120.0 :speed 30.0 :dash-max 14 :dash-track 0.0 :look :flash-step :sfx :hoho-out))

;;; ================================================================ forms
(defparameter *tsuki-strings*
  (append (loop for s in '(:ic-tsuki :ic-tsuki-k2 :ic-tsuki-re)
                append `((,s :tsuki-j :ic-tsuki-j) (,s :tsuki-k :ic-tsuki-k) (,s :tsuki-l :ic-tsuki-l)
                         (,s :tsuki-step :ic-tsuki-dash)))
          '((:ic-tsuki-dash :tsuki-back :ic-tsuki-re)))
  "The stance's follow-ups: non-button strings (KIT-NEXT) the :tick hook starts (TSUKI-STEP).")
(defparameter *ichigo-hooks* '(:tick ichigo-tick :hit ichigo-hit :struck ichigo-struck))
(defparameter *kessa-hooks* '(:tick ichigo-tick :step ichigo-step-clone :ok ichigo-ok :parried ichigo-catch :hit ichigo-hit
                              :struck ichigo-struck :deck ichigo-deck :soul-break-cine ic-kessa-getsuga-cine
                              :kikon-worth ichigo-kikon-worth))

(defkit :ichigo :base
  :name "ICHIGO" :body :ichigo :weapon :zangetsu-long :stance :ic-stance :hide (:kessa :mark)
  :intro :ic-intro :win :ic-win :intro-callout "ZANGETSU"
  :walk *walk-ichigo* :run *run-ichigo* :reishi *reishi-max* :swing-sfx :whoosh-heavy :mult *ichigo-mult* :taken *ichigo-taken*
  :stun-tolerance 16.0                          ; the hidden stun (DUEL_DESIGN.md): the middle (KESSA inherits it)
  :commands (:q :ic-j1 :f :ic-k1 :sig :ic-tsuki :sp1 :ic-juji :sp2 :ic-soga :breaker :ic-breaker :kikon :ic-kikon)
  :grid (:ic-j1 :ic-j2 :ic-j3 :ic-k1 :ic-k2 :ic-k3 :ic-j2s :ic-k2s)
  :strings *tsuki-strings*
  :l-after-k :ic-tsuki-k2                       ; L after K1 / K2 / K3 (docs/duel/DUEL_STRINGS.md §12): the stance at f4
  :awaken-form :kessa :aura ichigo-aura-base
  :hooks *ichigo-hooks*
  ;; rushdown: J pressure at 1.4-2.4 m, the cleaver's K links into a guard (:block-string), the stance and SOGA in the
  ;; middle (the stance's branch: ICHIGO-AI-STANCE), JUJISHO against a projectile; he awakens once he has taken 150
  :ai (:intents (:approach 2 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.6 5.0) :pressure (1.0 1.8) :zone (5.0 7.0) :defend (3.0 5.0))
       :moves ((0.0 1.6 :q 5 :f 2 :breaker 1 :sp2 1 :sig 1)            ; J up close only (DUEL_STRINGS §13), K beyond
               (1.6 2.6 :f 4 :sig 2 :breaker 1 :sp2 1)                ; the stance from 1.6 m (RANGETSU's lunge reaches)
               (2.6 5.0 :sig 4 :sp2 2 :f 1 :step 1)
               (5.0 9.0 :sp2 2 :sig 2 :sp1 1 :kikon 1)
               (9.0 99.0 :sp1 2 :kikon 1 nil 1))
       :guard 0.4 :hoho 0.3 :dash 0.8 :dash-back 0.1 :block-string 0.8 :l-after-k *ai-ic-l-after-k* :sp-cancel-bars 1
       :kikon-range 8.6 :react (:projectile :sp1) :awaken (:min-taken 150)
       :reflex ichigo-ai-shikai :assist-guard ichigo-assist-guard :sp-ender ichigo-ai-ender))

;;; KESSA NO ICHIGO: permanent, no heal, Kikon 3 (O: 2-4 by the clones). A normal guard; L the parry (and from blockstun);
;;; a clone on a Step (:step) and a Hoho; the clones' answers, the O charge and the afterimages in his :tick hook
(defkit :ichigo :kessa :inherit :base
  :awakening t :form-name "KESSA" :walk *walk-kessa* :run *run-kessa* :mult *kessa-mult* :taken *kessa-taken*
  :weapon :tensa :hide (:shikai :mark) :stance :ic-k-stance :aura ichigo-aura-kessa :cine ic-kessa-cine
  :passives (:parry-block)
  :hooks *kessa-hooks*
  :meter (:name "BUNSHIN" :max 3 :draw ichigo-hud-meter :label ichigo-hud-label)   ; the clones' row (the gauge unused)
  :commands (:q :ic-k-j1 :f :ic-k-k1 :sig :ic-k-parry :sp1 :ic-k-hiki :sp2 :ic-k-zanzo :kikon :ic-k-kikon)
  :grid (:ic-k-j1 :ic-k-j2 :ic-k-j3 :ic-k-k1 :ic-k-k2 :ic-k-k3 :ic-k-j2s :ic-k-k2s)
  :strings ((:ic-k-parry :land :ic-k-gaeshi))
  :l-after-k nil
  ;; a mid-close brawler with posts: every back hop and Hoho posts a clone; the parry and O by the clones in its
  ;; :reflex (ICHIGO-AI-KESSA), from blockstun in the :tick hook
  :ai (:intents (:approach 3 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.6 6.0) :pressure (1.0 2.0) :zone (3.0 4.0) :defend (3.5 5.5))
       ;; the clones swing in place (the user, 2026-09-29): a Step posts one where he took off, so at 2.8-5 m the Hoho
       ;; (a clone 1.6 m in front of him, Ichigo behind him) takes half the Step's share
       :moves ((0.0 1.8 :q 5 :f 3 :breaker 1 :step 1)
               (1.8 2.8 :f 5 :breaker 1 :step 1)
               (2.8 5.0 :f 2 :step 1 :hoho 1 :sp2 1 :q 1)
               (5.0 9.0 :sp1 2 :hoho 2 :kikon 1 :step 1)
               (9.0 99.0 :kikon 1 :hoho 2 nil 1))
       :guard 0.4 :hoho 0.4 :dash 0.6 :dash-back 0.2 :o-ender 0.6 :attack 0.15 :l-after-k 0.0 :sp-cancel-bars 9
       :kikon-range 8.6 :stun-follow (:sp1 3.8 7.0) :reflex ichigo-ai-kessa :assist-guard ichigo-assist-guard
       :sp-ender ichigo-ai-ender))

;;; ================================================================ pure rules (host-tested: tests/duel-rules-test.lisp)
(defun clone-konpaku (n) "The Kikon's Konpaku with N clones at the O press (*CLONE-KONPAKU*)." (nth (max 0 (min 3 n)) *clone-konpaku*))
(defun clone-move (weight link)
  "The clone's move for the answer WEIGHT (:q a J press: the heavy; :f a K press: the light) at LINK (3: the ender's)."
  (find-move (if (eq weight :q) (if (= link 3) :ic-c-heavy3 :ic-c-heavy) (if (= link 3) :ic-c-light3 :ic-c-light))))
(defun clone-hit-frame (weight) "Frames from the press to a clone's link-1 hit." (+ *clone-lag* (mv-s (clone-move weight 1))))
(defun clone-after-string (touched life)
  "A clone's string ended: :fade when it touched him (hit or block) or its time is up, else :idle (a whiff keeps it)."
  (if (or touched (<= life 0)) :fade :idle))
(defun clone-vanish-p (res) "Does a hit on Ichigo with result RES clear his clones (a real hit, not a block)?" (eq (contact-of res) :hit))
(defun clone-evict (borns)
  "Making one more clone with live clones born at BORNS (ticks): the index of the one to replace (the oldest) at the cap."
  (and (>= (length borns) *clone-max*) (position (reduce #'min borns) borns)))
(defun echo-hitwin (hw mult)
  "A copy of hit HW at MULT of its damage and guard value, with a blade's hit look (a clone's or an echo's)."
  (let ((w (copy-hitwin hw)))
    (setf (hw-dmg w) (max 1 (round (* mult (hw-dmg hw)))) (hw-guard w) (and (hw-guard hw) (* mult (hw-guard hw)))
          (hw-flags w) (adjoin :blade (hw-flags hw)))
    w))
(defun echo-hit-frames (mv) "The frames (from his move's frame 0) an echo of MV hits on." (loop for w across (mv-hits mv) collect (+ *zanzo-lag* (hw-from w))))

;;; ================================================================ per-side state (the sim's; a new fighter entity = a fresh one)
(defstruct (ics (:conc-name ics-))
  (e nil)                                     ; the fighter it belongs to
  (hoho-done nil) (dashed nil) (o-live nil)
  (seen nil) (seen-main nil)                  ; the move the afterimage watch last saw start
  (hist (make-array 48 :initial-element 0f0)) (hist-i 0 :type fixnum)   ; his last 16 (x z yaw): the echoes replay them
  (rim nil) (rim-saved nil) (parry-sf -1 :type fixnum)
  (bs-key -1 :type fixnum) (bs-at -1 :type fixnum)    ; the CPU's parry from blockstun: which blockstun, pressed on which frame
  (o-at -9999 :type fixnum) (o-n 0 :type fixnum)      ; the last O press and its clones (the HUD's flash)
  (acc nil) (acc-mv nil) (acc-sf 0 :type fixnum) (acc-hit nil) (acc-kikons 0 :type fixnum))   ; the pacing log (debug)
(defvar *ic* (vector (make-ics) (make-ics)) "Per side: Ichigo's state.")
(defun ic (e)
  "E's state; a new fighter entity (a new match) gets a fresh one, keeping only the pacing log's counters."
  (let* ((i (fighter-side (fighter e))) (st (svref *ic* i)))
    (if (eql (ics-e st) e) st (setf (svref *ic* i) (make-ics :e e :acc (ics-acc st))))))
(defmacro ic-count (e key &optional (n 1)) `(incf (getf (ics-acc (ic ,e)) ,key 0) ,n))
(defun ic-key (&rest parts) (intern (format nil "~{~a~^-~}" parts) :keyword))
(defun ic-reach-key (x z e)
  "The pacing log's reach bucket of a point (X Z) to E's opponent: IN (<= 2.4 m, a light's), MID (<= 3.0, a heavy's), OUT."
  (let* ((q (pos-of (opp-of e))) (d (sqrt (+ (expt (- (aref q 0) x) 2) (expt (- (aref q 2) z) 2)))))
    (cond ((<= d 2.4) "IN") ((<= d 3.0) "MID") (t "OUT"))))

;;; hazard data: a clone (ICC), an afterimage (ICE); their hits are :ic-hit hazards whose data is the clone / :echo
(defstruct (icc (:conc-name icc-))
  (state :idle) (born 0 :type fixnum) (life 0 :type fixnum) (fade 0 :type fixnum) (src nil)
  (link 0 :type fixnum) (mv nil) (sf 0 :type fixnum) (queued nil)   ; (the presses waiting for its next links)
  (hit nil)                                   ; this link's own contact (:hit / :block)
  (touched nil))                              ; any link of this string touched him: the carried gate; spent at its end
(defstruct (ice (:conc-name ice-)) (mv nil) (sf 0 :type fixnum) (end 0 :type fixnum))

;;; ================================================================ helpers
(defun gg-spend! (e n)
  "E spends N of the guard gauge (the regen waits *GG-DELAY* again; never guardless by it)."
  (let ((g (gauges e))) (setf (gauges-gg g) (f32 (max 0.0 (- (gauges-gg g) n))) (gauges-gg-idle g) 0)))

(defun ichigo-pull-to (att d frames)
  "The chain drags ATT's opponent toward him to D metres over FRAMES (after the hit's own reaction: its slide replaced)."
  (let* ((v (opp-of att)) (p (pos-of att)) (q (pos-of v)) (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2)))
         (dist (sqrt (+ (* dx dx) (* dz dz)))))
    (when (> dist d)
      (set-slide v (- dist d) frames dx dz)
      (emit :sfx :chain-snap att))))
(defun ichigo-pull (e) "KUSARI-BIKI's hit: pulled to :pull m (and bound)." (ichigo-pull-to e (move-param e :pull) 10))
(defun ichigo-gaeshi-pull (e) "ZANGETSU-GAESHI f0: the staggered attacker dragged to :pull m, so the cut reaches." (ichigo-pull-to e (move-param e :pull) 6))

(defun ichigo-wave (e look &key (ahead 1.0) (yaw (yaw-of e)))
  "A crescent :wave from the move's :params (:width :speed :range :dmg :react :kb :guard), AHEAD m in front of E, drawn by
LOOK; a blade's hit (:blade)."
  (let ((speed (move-param e :speed)))
    (multiple-value-bind (x z) (ahead e ahead)
      (spawn-hazard :wave e :x x :z z :yaw yaw :speed speed :size (* 0.5 (move-param e :width))
                            :life (round (* 60 (/ (move-param e :range) speed))) :look look
                            :hw (make-hitwin :dmg (move-param e :dmg) :react (move-param e :react) :kb (move-param e :kb)
                                             :hs *hitstop-heavy* :guard (move-param e :guard) :flags '(:blade))))))

(defun ichigo-getsuga (e) "GETSUGA TENSHO's crescent leaves the long blade." (ichigo-wave e (move-param e :look)) (emit :sfx :getsuga e))
(defun ichigo-juji-first (e)
  "JUJISHO f12: the long blade's crescent forms on the edge (a look; the wave is f20's)."
  (multiple-value-bind (x z) (ahead e 1.0) (spawn-look e 'ichigo-form-look :x x :z z :yaw (yaw-of e) :size 1.8 :life 10))
  (emit :sfx :getsuga e))
(defun ichigo-juji (e) "JUJISHO f20: the two crescents fused into one cross wave." (ichigo-wave e (move-param e :look)) (emit :sfx :getsuga e))
(defun ichigo-soga-vanish (e) "SOGA f0: the flash step's vanish." (let ((p (pos-of e))) (emit :hoho-out e (aref p 0) (aref p 2))))

(defun ichigo-cut (e)
  "JUJISHO's cross wave CUTS every opponent wave / fireball it touches (a blade can't cut the ground)."
  (do-entities (h (hz hazard))
    (when (and (eql (hazard-owner hz) e) (eq (hazard-look hz) 'ichigo-juji-look) (<= (hazard-delay hz) 0)
               (< (hazard-age hz) (hazard-life hz)))
      (do-entities (o (oz hazard))
        (when (and (not (eql (hazard-owner oz) e)) (member (hazard-kind oz) '(:wave :fireball)) (<= (hazard-delay oz) 0)
                   (hazard-touches-p hz (hazard-x oz) 0f0 (hazard-z oz) (f32 (max 0.5 (hazard-size oz))) 1.8))
          (emit :hazard-cut (hazard-x oz) (f32 (+ 1.0 (hazard-y oz))) (hazard-z oz))
          (clog "~a cuts ~a" (side-name e) (hazard-kind oz))
          (destroy-entity o))))))

;;; ================================================================ the Shikai's stance
(defun tsuki-pressed (vp)
  "The stance's follow-up a human pressed (buffered, unmodified): :tsuki-j / -k / -l / -step, or NIL."
  (cond ((vpad-command-pressed-p vp :quick nil) :tsuki-j) ((vpad-command-pressed-p vp :flash nil) :tsuki-k)
        ((vpad-command-pressed-p vp :sig nil) :tsuki-l) ((vpad-command-pressed-p vp :step nil) :tsuki-step)))

(defun tsuki-step (e f st mv)
  "One step of the stance (MV): it re-aims at him; from f6 the first J / K / L / Step fires its branch (a CPU's is picked
once at f6: ICHIGO-AI-STANCE); no cooldown on L (the user 2026-09-29: its recovery is the price), a Step without its flash step or after the stance's one
dash waits (a plain Step after the stance); past the hold (30 f, 60 while L is held) the stance recovers (R 14)."
  (let* ((sf (fighter-sf f)) (vp (pilot-vpad (pilot e))) (b (brain e)))
    (turn-to-opp e f (track-step 360.0))
    (when (>= sf *tsuki-up*)
      (let* ((cmd (if b (and (= sf *tsuki-up*) (ichigo-ai-stance e f st)) (tsuki-pressed vp)))
             (button (getf '(:tsuki-j :quick :tsuki-k :flash :tsuki-l :sig :tsuki-step :step) cmd))
             (ok (case cmd
                   (:tsuki-step (and (not (ics-dashed st)) (>= (gauges-fs (gauges e)) *tsuki-dash-fs*)))
                   ((nil) nil)
                   (t t))))
        (when ok
          (unless b (vpad-consume! vp button))
          (case cmd
            (:tsuki-step (spend-fs (gauges e) *tsuki-dash-fs*) (setf (ics-dashed st) t)))
          (start-move e (kit-next (fighter-kit f) (mv-name mv) cmd))
          (return-from tsuki-step nil))))
    (when (and (<= (+ *tsuki-up* *tsuki-tap*) sf) (< sf (+ *tsuki-up* *tsuki-max*)) (not (vpad-down vp :sig)))
      (setf (fighter-sf f) (+ *tsuki-up* *tsuki-max*)))))

(defun ichigo-tsuki-dash (e)
  "TSUKIWATARI f0: 3.5 m in the stick direction (neutral: at him) over its 12 f, iframes f0-8, the flash step's vanish."
  (let* ((f (fighter e)) (p (pos-of e)))
    (multiple-value-bind (to st) (if (brain e) (values 1.0 0.0) (stick-relative e f))
      (multiple-value-bind (to st) (step-direction to st 1.0)
        (multiple-value-bind (dx dz) (world-dir e f to st)
          (set-slide e 3.5 12 dx dz))))
    (setf (fighter-invuln f) 9)
    (emit :hoho-out e (aref p 0) (aref p 2))
    (emit :sfx :whoosh-light e)))
(defun ichigo-tsuki-return (e) "TSUKIWATARI f11: back in the stance, a fresh window." (start-move e (kit-next (kit-of e) :ic-tsuki-dash :tsuki-back)))

(defun ichigo-ai-stance (e f st)
  "The CPU's branch at the stance's f6 (DUEL_ICHIGO v2 §10; by reach, the user 2026-09-29): after a K link's hit J / K /
L; within 4.2 m (RANGETSU's lunge + reach 4.8) TSUKI-OTOSHI on a guard (or a gauge < 50) else mostly RANGETSU; to 6.4 m
(the pounce's 6.6) TSUKI-OTOSHI or the dash in (a fresh stance at 1-2 m); farther the dash within 7.5 m, else the Getsuga."
  (let* ((o (opp-of e)) (fo (fighter o)) (d (fighter-dist f)) (r (sim-rnd01))
         (getsuga t) (dash (and (not (ics-dashed st)) (>= (gauges-fs (gauges e)) *tsuki-dash-fs*))))
    (cond ((member (fighter-state fo) '(:stun :air))
           (cond ((< r 0.5) :tsuki-j) ((< r 0.8) :tsuki-k) (getsuga :tsuki-l) (t :tsuki-j)))
          ((<= d 4.2)
           (if (or (member (fighter-state fo) '(:guard :guard-hit)) (< (gauges-gg (gauges o)) 50))
               (if (< r 0.6) :tsuki-k :tsuki-j)
               (if (< r 0.7) :tsuki-j :tsuki-k)))
          ((<= d 6.4) (if (and dash (< r 0.5)) :tsuki-step :tsuki-k))
          ((and dash (<= d 7.5) (< r 0.6)) :tsuki-step)
          (getsuga :tsuki-l)
          (dash :tsuki-step))))

;;; ================================================================ KESSA: the clones 分身
(defun clone-p (hz) (icc-p (hazard-data hz)))
(defun ichigo-clones (e)
  "E's clone hazards (entities), oldest first."
  (let ((out nil))
    (do-entities (h (hz hazard)) (when (and (eql (hazard-owner hz) e) (clone-p hz)) (push h out)))
    (sort out #'< :key (lambda (h) (icc-born (hazard-data (hazard h)))))))
(defun clone-live-p (c) (member (icc-state c) '(:idle :answer)))
(defun ichigo-kikon-worth (e)
  "KESSA's :kikon-worth hook: what 千影 would take if O were pressed now (CLONE-KONPAKU of the live clones), for the red
Konpaku hint (the user 2026-09-29: it followed the kit's fixed 3) and his Soul Break (this + 1, the user 2026-09-30)."
  (clone-konpaku (count-if (lambda (h) (clone-live-p (hazard-data (hazard h)))) (ichigo-clones e))))
(defun clone-count (e) "E's live clones (idle or answering)." (count-if (lambda (h) (clone-live-p (hazard-data (hazard h)))) (ichigo-clones e)))
(defun clone-fade (c) (setf (icc-state c) :fade (icc-fade c) 0))

(defun ichigo-clone-spawn (e x z src)
  "A clone at (X Z) facing the opponent; at the cap the oldest live one fades out (CLONE-EVICT)."
  (let* ((live (remove-if-not (lambda (h) (clone-live-p (hazard-data (hazard h)))) (ichigo-clones e)))
         (i (clone-evict (mapcar (lambda (h) (icc-born (hazard-data (hazard h)))) live)))
         (q (pos-of (opp-of e))))
    (when i (clone-fade (hazard-data (hazard (nth i live)))) (ic-count e :clone-evicted))
    (spawn-hazard :fx e :x x :z z :yaw (dir-yaw (- (aref q 0) x) (- (aref q 2) z)) :size 0.5 :life 99999
                        :look 'ichigo-clone-look :hook 'ichigo-clone-hz
                        :data (make-icc :born *match-tick* :life *clone-life* :src src))
    (emit :sfx :clone e)
    (clog "~a CLONE ~a ~d" (side-name e) src (1+ (- (length live) (if i 1 0))))))

(defun clone-pay! (e)
  "Pay *CLONE-COST* of E's guard gauge for a clone: T when paid; NIL (no clone, nothing spent) below it or guardless."
  (let ((g (gauges e)))
    (when (and (not (gauges-guardless g)) (>= (gauges-gg g) *clone-cost*))
      (gg-spend! e *clone-cost*)
      t)))

(defun ichigo-step-clone (e)
  "KESSA's :step hook: every Step's take-off point leaves a clone, paid (CLONE-PAY!; the user 2026-09-29: no gap between
them, the guard gauge is the limit)."
  (let ((why (let ((b (brain e))) (if (and b (eq (brain-act b) :dash)) (if (> (brain-dash b) 0) "DASH" "BACKDASH") "TAP"))))
    (if (clone-pay! e)
        (let ((p (pos-of e)))
          (ic-count e (ic-key "CLONE-STEP" why (ic-reach-key (aref p 0) (aref p 2) e)))
          (ichigo-clone-spawn e (aref p 0) (aref p 2) :step))
        (progn (ic-count e (ic-key "REFUSED-STEP" why)) (ic-count e :refused-gg (round (gauges-gg (gauges e))))))))

(defun hoho-clone (e)
  "A Hoho's reappearance leaves a clone 1.6 m in front of the opponent (the line from Ichigo, behind him, through him),
paid (CLONE-PAY!)."
  (if (not (clone-pay! e))
   (progn (ic-count e :refused-hoho) (ic-count e :refused-gg (round (gauges-gg (gauges e)))))
   (let* ((q (pos-of (opp-of e))) (p (pos-of e)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (l (max 1e-3 (sqrt (+ (* dx dx) (* dz dz))))))
    (multiple-value-bind (x z) (clamp-to-circle (+ (aref q 0) (* 1.6 (/ dx l))) (+ (aref q 2) (* 1.6 (/ dz l))) (- *arena-radius* 0.4))
      (ic-count e :clone-hoho)
      (ichigo-clone-spawn e x z :hoho)))))

(defun clone-link (c weight link)
  "Clone C starts answer LINK with WEIGHT (link 1 after the lag)."
  (setf (icc-state c) :answer (icc-mv c) (clone-move weight link) (icc-link c) link
        (icc-sf c) (if (= link 1) (- *clone-lag*) 0) (icc-hit c) nil)
  (when (= link 1) (setf (icc-touched c) nil (icc-queued c) nil)))

(defun ichigo-press (e button)
  "A J / K press edge of E's (the user's choice: EVERY clone answers): an idle clone starts its string where it stands
(the user, 2026-09-29: the clones swing in place); an answering one queues the press for a later link (each press one
link, in order, 3 links at most: the clone plays his whole string back, *CLONE-LAG* behind)."
  (let ((w (if (eq button :quick) :q :f)) (reach (if (eq button :quick) "3.0" "2.4")))
    (ic-count e (ic-key "PRESS" w))
    (dolist (h (ichigo-clones e))
      (let ((c (hazard-data (hazard h))))
        (when (clone-live-p c)
          (ic-count e (ic-key "PRESS" w "CLONES"))
          (when (or (string= (ic-reach-key (hazard-x (hazard h)) (hazard-z (hazard h)) e) "IN")
                    (and (eq w :q) (string= (ic-reach-key (hazard-x (hazard h)) (hazard-z (hazard h)) e) "MID")))
            (ic-count e (ic-key "PRESS" w "INREACH" reach))))))
    (dolist (h (ichigo-clones e))
      (let ((c (hazard-data (hazard h))))
        (case (icc-state c)
          (:idle (ic-count e :clone-answers) (clone-link c w 1))
          (:answer (when (< (+ (icc-link c) (length (icc-queued c))) 3)   ; each press one link, in order
                     (setf (icc-queued c) (append (icc-queued c) (list w))))))))))

(defun ichigo-strike (e x z yaw hw mult data)
  "A clone's / an echo's hit: an :ic-hit hazard with HW at MULT (ECHO-HITWIN) in the frame (X Z YAW), for its active
frames; guarded facing Ichigo (:src); a hazard: no KOSEI, it counts in his combo."
  (spawn-hazard :ic-hit e :x x :z z :yaw yaw :size 0.5 :life (max 1 (- (hw-to hw) (hw-from hw))) :hw (echo-hitwin hw mult)
                          :src t :hook 'ichigo-strike-hz :data data))

(defun ichigo-strike-hz (h hz ev &optional tx ty tz tr th)
  "The :ic-hit hazards' hook: their volume is the hit window's own (in the frame they were struck in)."
  (declare (ignore h))
  (when (eq ev :touches)
    (let ((yaw (hazard-yaw hz)))
      (vol-hit-p (first (hw-vols (hazard-hw hz))) (hazard-x hz) 0f0 (hazard-z hz) (f32 (fwd-x yaw)) (f32 (fwd-z yaw))
                 tx ty tz tr th 0f0))))

(defun clone-answer-step (e hz c)
  "An answering clone, one frame: the lag; its hit, struck where it stands (no chase: the user, 2026-09-29), facing him;
its next link once the chain opens (its own contact, CHAIN-OPEN-P; after a touch every latched press goes on); at the
string's end it fades if it touched him, else it idles where it stands."
  (let* ((mv (icc-mv c)) (sf (incf (icc-sf c))) (s (mv-s mv)))
    (cond ((< sf s) nil)
          (t (when (= sf s)
               (ichigo-strike e (hazard-x hz) (hazard-z hz) (hazard-yaw hz) (svref (mv-hits mv) 0) *clone-scale* c)
               (emit :sfx :whoosh-heavy e))
             (cond ((and (icc-queued c) (< (icc-link c) 3)
                         (chain-open-p sf s (mv-a mv) (mv-r mv) (or (icc-hit c) (icc-touched c))))
                    (clone-link c (pop (icc-queued c)) (1+ (icc-link c))))
                   ((>= sf (+ s (mv-a mv) (mv-r mv)))
                    (unless (icc-touched c) (ic-count e :clone-whiff-strings))
                    (if (eq (clone-after-string (icc-touched c) (icc-life c)) :fade)
                        (clone-fade c)
                        (setf (icc-state c) :idle (icc-queued c) nil))))))))

(defun clone-burst (e hz)
  "A charging clone bursts (ink and white, BLOOD sparks) on O's strike frame."
  (spawn-look e 'ichigo-burst-look :x (hazard-x hz) :z (hazard-z hz) :size 1.0 :life 16)
  (emit :sfx :clone e))

(defun ichigo-clone-step (h hz c)
  "A clone, each step (its hazard's own step): its life, its facing, and its state: :idle, :answer (CLONE-ANSWER-STEP),
:charge (runs at him at <= 40 m/s, bursts on O's strike frame or when the rush is over), :fade (8 f)."
  (let ((e (hazard-owner hz)) (o (hazard-target hz)))
    (unless (and (entity-alive-p e) (entity-alive-p o)) (destroy-entity h) (return-from ichigo-clone-step nil))
    (incf (hazard-age hz))
    (decf (icc-life c))
    (let* ((q (pos-of o)) (dx (- (aref q 0) (hazard-x hz))) (dz (- (aref q 2) (hazard-z hz))) (d (sqrt (+ (* dx dx) (* dz dz)))))
      (unless (eq (icc-state c) :fade)
        (setf (hazard-yaw hz) (f32 (angle-wrap (turn-toward (hazard-yaw hz) (dir-yaw dx dz) (track-step 720.0))))))
      (ecase (icc-state c)
        (:idle (when (<= (icc-life c) 0) (ic-count e :clone-expired) (clone-fade c)))
        (:answer (clone-answer-step e hz c))
        (:charge
         (let ((s (min (* 40.0 +step+) (max 0.0 (- d 1.0)))) (f (fighter e)))
           (when (> d 0.01)
             (setf (hazard-x hz) (f32 (+ (hazard-x hz) (* s (/ dx d)))) (hazard-z hz) (f32 (+ (hazard-z hz) (* s (/ dz d))))))
           (let ((mv (fighter-move f)))
             (unless (and (eq (fighter-state f) :move) mv (eq (mv-kind mv) :kikon)
                          (or (member (fighter-phase f) '(:aura :dash)) (and (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))))
               (clone-burst e hz)
               (destroy-entity h)))))
        (:fade (when (>= (incf (icc-fade c)) 8) (destroy-entity h)))))))

(defun ichigo-clone-hz (h hz ev &rest args)
  "The clones' hazard hook: their own step (T: the generic one skipped); no volume."
  (declare (ignore args))
  (when (eq ev :step) (ichigo-clone-step h hz (hazard-data hz)) t))

(defun ichigo-vanish (e)
  "E was really hit: every clone, afterimage and their hits in the air vanish (a puff where each clone stood)."
  (let ((at nil))
    (do-entities (h (hz hazard))
      (when (and (eql (hazard-owner hz) e) (or (clone-p hz) (ice-p (hazard-data hz)) (eq (hazard-kind hz) :ic-hit)))
        (when (clone-p hz) (push (cons (hazard-x hz) (hazard-z hz)) at))
        (destroy-entity h)))
    (dolist (p at) (spawn-look e 'ichigo-burst-look :x (car p) :z (cdr p) :size 0.6 :life 12))
    (when at (ic-count e :clones-vanished (length at)) (clog "~a CLONES GONE ~d" (side-name e) (length at)))))

(defun ichigo-o-press (e f st)
  "O pressed (a neutral rush or the ender): N = the live clones; they all charge; the strike gains *CLONE-BURST-DMG* x N (its
bonus); the Kikon is worth CLONE-KONPAKU N."
  (let ((n 0))
    (dolist (h (ichigo-clones e))
      (let ((c (hazard-data (hazard h))))
        (when (clone-live-p c) (incf n) (setf (icc-state c) :charge))))
    (ic-count e (ic-key (if (kikon-ready-p e) "O-RED" "O-POKE") n))
    (setf (fighter-kikon-n f) (clone-konpaku n) (fighter-dmg-bonus f) (* n *clone-burst-dmg*)
          (ics-o-at st) *match-tick* (ics-o-n st) n)
    (clog "~a KAGE-UCHI clones ~d konpaku ~d" (side-name e) n (clone-konpaku n))))

;;; ================================================================ KESSA: 残像 ZANZO, the afterimages
(defun zanzo-p (e)
  "Is E's afterimage state on (its timer, a look-only hazard: a reset clears it)?"
  (do-entities (h (hz hazard))
    (when (and (eql (hazard-owner hz) e) (eq (hazard-look hz) 'ichigo-zanzo-look)) (return-from zanzo-p t)))
  nil)
(defun ichigo-zanzo-on (e)
  "ZANZO f12: the state for *ZANZO-LIFE* frames."
  (spawn-look e 'ichigo-zanzo-look :life *zanzo-life*)
  (emit :sfx :clone e)
  (clog "~a ZANZO" (side-name e)))

(defun hist-push (st e)
  (let ((i (mod (1+ (ics-hist-i st)) 16)) (p (pos-of e)) (v (ics-hist st)))
    (setf (ics-hist-i st) i (svref v (* 3 i)) (aref p 0) (svref v (+ 1 (* 3 i))) (aref p 2) (svref v (+ 2 (* 3 i))) (yaw-of e))))
(defun hist-at (st lag)
  "Values x z yaw of Ichigo LAG steps ago (at most 15)."
  (let ((i (* 3 (mod (- (ics-hist-i st) (min 15 lag)) 16))) (v (ics-hist st)))
    (values (svref v i) (svref v (1+ i)) (svref v (+ 2 i)))))

(defun echo-watch (e f st)
  "A new attack of E's (a move with hits, not the Breaker; a Kikon rush at its strike) while ZANZO is on: its echo."
  (let* ((mv (and (eq (fighter-state f) :move) (fighter-move f))) (main (and mv (eq (fighter-phase f) :main))))
    (unless (and (eq mv (ics-seen st)) (eq main (ics-seen-main st)))
      (setf (ics-seen st) mv (ics-seen-main st) main)
      (when (and main (plusp (length (mv-hits mv))) (not (eq (mv-kind mv) :breaker)) (zanzo-p e))
        (let ((p (pos-of e)))
          (spawn-hazard :fx e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 0.5 :life 99999 :look 'ichigo-echo-look
                              :hook 'ichigo-echo-hz
                              :data (make-ice :mv mv :sf (- (fighter-sf f) *zanzo-lag*) :end (mv-total mv))))))))

(defun ichigo-echo-hz (h hz ev &rest args)
  "An afterimage: it replays his move *ZANZO-LAG* frames behind, where he stood then (his history), and strikes each of its
hit windows at *ZANZO-MULT*."
  (declare (ignore args))
  (when (eq ev :step)
    (let* ((d (hazard-data hz)) (e (hazard-owner hz)) (sf (incf (ice-sf d))) (mv (ice-mv d)))
      (incf (hazard-age hz))
      (if (or (not (entity-alive-p e)) (>= sf (ice-end d)))
          (destroy-entity h)
          (multiple-value-bind (x z yaw) (hist-at (ic e) *zanzo-lag*)
            (setf (hazard-x hz) (f32 x) (hazard-z hz) (f32 z) (hazard-yaw hz) (f32 yaw))
            (loop for w across (mv-hits mv)
                  when (= sf (hw-from w)) do (ichigo-strike e x z yaw w *zanzo-mult* :echo)))))
    t))

;;; ================================================================ KESSA: the parry
(defun ichigo-ok (e cmd combo)
  "KESSA's :ok hook: L (the parry) wants *KESSA-PARRY-COST* of the guard gauge and not guardless; SP2 is refused while
ZANZO runs."
  (declare (ignore combo))
  (let ((g (gauges e)))
    (case cmd
      (:sig (and (not (gauges-guardless g)) (>= (gauges-gg g) *kessa-parry-cost*)))
      (:sp2 (not (zanzo-p e)))
      (t t))))

(defun ichigo-parry-open (e)
  "KUSARI-TATE f0: its price, the chains flaring (the tell), the soft rising shimmer."
  (gg-spend! e *kessa-parry-cost*)
  (spawn-look e 'ichigo-flare-look :yaw (yaw-of e) :life 18)
  (emit :sfx :chain-rattle e)
  (emit :sfx :parry-open e))

(defun ichigo-catch (e att)
  "KESSA's :parried hook: +*KESSA-PARRY-CATCH* guard gauge, the attacker's stagger lengthened to *KESSA-PARRY-STUN*, a
12 f hitstop, a white flash, the kiin, 0.3 s of slow motion; the counter is the :land string (ZANGETSU-GAESHI)."
  (let ((g (gauges e)) (fa (fighter att)))
    (setf (gauges-gg g) (f32 (min *gg-max* (+ (gauges-gg g) *kessa-parry-catch*))) (gauges-gg-idle g) 0)
    (when (eq (fighter-state fa) :stun) (setf (fighter-stun fa) *kessa-parry-stun*)))
  (hitstop 12)
  (slowmo 0.4 0.3)
  (ui-flash 1 1 1 0.55 7.0)                             ; the white flash frame
  (emit :sfx :parry-ting e)
  (emit :sfx :chain-snap e)
  (clog "~a PARRY CATCH gg ~d" (side-name e) (round (gauges-gg (gauges e)))))

(defun parry-from-blockstun (e f st vp)
  "In blockstun L starts the parry at once (the blockstun ends), under its price; a CPU presses it after a blocked K
link *AI-IC-PARRY-BS-P* of the time, on the frame that puts the string's next hit in the window."
  (let ((b (brain e)))
    (when (and b (not (brain-off b)))
      (let ((sf (fighter-sf f)))
        (when (or (< (ics-bs-key st) 0) (< sf (ics-bs-key st)))   ; a new blockstun (a block restarts it at 0)
          (setf (ics-bs-at st) -1)
          (let ((om (fighter-move (fighter (opp-of e)))))
            (when (and om (or (and (eq (mv-kind om) :flash) (< (sim-rnd01) (ic-p b (* 0.6 *ai-ic-parry-bs-p*) *ai-ic-parry-bs-p* 0.8)))
                              ;; v2: a J masher's blocked J: his next J lands in the window (EASY 0 / NORMAL 0 / HARD 0.6)
                              (and (eq (mv-kind om) :quick) (not (brain-habit b)) (ai-mash-p b) (< (sim-rnd01) (ic-p b 0.0 0.0 0.6)))))
              (setf (ics-bs-at st) (max 1 (- (fighter-stun f) 6))))))
        (setf (ics-bs-key st) sf)
        (when (= sf (ics-bs-at st)) (setf (ics-bs-at st) -1) (ai-press b :sig 2)))))
  (when (and (vpad-command-pressed-p vp :sig nil) (kit-command-ok-p e :sig) (not (guard-locked-now-p f)))   ; (not held by the guard lock)
    (vpad-consume! vp :sig)
    (start-move e (kit-command-move (fighter-kit f) :sig))
    (clog "~a parry from blockstun" (side-name e))))

(defvar *parry-rims* nil "The parry window's white rims, 8 levels (made at first use: RIM-VEC is the engine's).")
(defun parry-rim (k)
  (unless *parry-rims* (setf *parry-rims* (coerce (loop for i from 1 to 8 collect (rim-vec #xFFFFFF (* 0.45 i))) 'simple-vector)))
  (svref *parry-rims* (max 0 (min 7 (floor (* 8 k))))))

(defun parry-watch (e f st)
  "The parry's window tell: a white rim, fading linearly over the window (its brightness is the timer); the parry frame
kept for the practice judge (ICHIGO-STRUCK)."
  (let* ((m (model e)) (mv (and (eq (fighter-state f) :move) (fighter-move f)))
         (in (and mv (member :parry (mv-flags mv)) (eq (fighter-phase f) :main))) (sf (fighter-sf f)))
    (setf (ics-parry-sf st) (if in sf -1))
    (if (and in (parry-frame-p sf (getf (mv-params mv) :window)))
        (let ((w (getf (mv-params mv) :window)))
          (unless (ics-rim-saved st) (setf (ics-rim-saved st) t (ics-rim st) (model-rim m)))
          (setf (model-rim m) (parry-rim (- 1.0 (/ (- sf (first w)) (float (max 1 (- (second w) (first w)))))))))
        (when (ics-rim-saved st) (setf (model-rim m) (ics-rim st) (ics-rim-saved st) nil)))))

;;; ================================================================ the pacing log (debug; docs/duel/DUEL_ICHIGO.md "The CPU with the stance and the clones")
(defun ic-acc-watch (e f st)
  "Each move instance of his, by name, and at its end its contact (NAME-HIT / -BLK / -WHF); the stance's entries by
distance; the ticks in KESSA; each Kikon he lands, by form and worth."
  (let* ((mv (and (eq (fighter-state f) :move) (fighter-move f))) (sf (fighter-sf f)) (old (ics-acc-mv st)))
    (when (and old (or (not (eq mv old)) (< sf (ics-acc-sf st))))
      (ic-count e (ic-key (mv-name old) (case (ics-acc-hit st) (:hit "HIT") (:block "BLK") (t "WHF"))))
      (setf (ics-acc-mv st) nil))
    (when (and mv (not (ics-acc-mv st)))
      (setf (ics-acc-mv st) mv (ics-acc-hit st) nil)
      (ic-count e (mv-name mv))
      (when (member (mv-name mv) '(:ic-tsuki :ic-tsuki-k2))
        (let ((d (fighter-dist f))) (ic-count e (ic-key (mv-name mv) (cond ((<= d 3.0) "D3") ((<= d 5.5) "D5") (t "DFAR")))))))
    (when mv
      (setf (ics-acc-sf st) sf)
      (let ((c (fighter-contact f)))
        (when c (setf (ics-acc-hit st) (if (or (eq c :hit) (eq (ics-acc-hit st) :hit)) :hit :block)))))
    (when (eq (fighter-form f) :kessa) (ic-count e :kessa-ticks))
    (let ((k (gauges-kikons (gauges e))))
      (when (> k (ics-acc-kikons st))
        (setf (ics-acc-kikons st) k)
        (ic-count e (ic-key "KIKON" (fighter-form f) (fighter-kikon-n f)))))))

(defun ichigo-acc-reset () (dotimes (i 2) (setf (ics-acc (svref *ic* i)) nil)))
(defun ichigo-acc-line ()
  "After a gate row: a \"duel ichigo\" line per side that played him (the pacing log)."
  (dolist (e (list *p1* *p2*))
    (when (and (entity-alive-p e) (eq (fighter-character (fighter e)) :ichigo))
      (log-msg "duel ichigo ~a seed ~d awakened ~a ~{~(~a~) ~a~^ ~}" (side-name e) *match-seed* (gauges-awakened (gauges e))
               (ics-acc (ic e))))))

;;; ================================================================ his hooks
(defun ichigo-hit (att def res hw mv hazard ranged)
  "Both forms' :hit hook: a clone's hit tells its clone what it did (its string's gate and its fate)."
  (declare (ignore def hw mv ranged))
  (when (and hazard (eq (hazard-look hazard) 'ichigo-getsuga-look) (contact-of res))
    (ic-count att (ic-key "GETSUGA-WAVE" (contact-of res))))
  (when (and hazard (eq (hazard-look hazard) 'ichigo-juji-look) (contact-of res))
    (ic-count att (ic-key "JUJI-WAVE" (contact-of res))))
  (when hazard
    (let ((c (hazard-data hazard)))
      (when (and (icc-p c) (contact-of res))
        (ic-count att (ic-key "CLONE" (contact-of res)))
        (setf (icc-hit c) (contact-of res) (icc-touched c) t)
        (clog "~a clone ~a" (side-name att) res)))))

(defun ichigo-struck (def att res hw mv hazard ranged)
  "Both forms' :struck hook: a real hit on him clears his clones and afterimages (CLONE-VANISH-P); in practice mode a
missed parry says EARLY (hit in its recovery) or LATE (hit within 3 f of pressing L)."
  (declare (ignore att hw mv hazard ranged))
  (when (clone-vanish-p res)
    (ichigo-vanish def)
    (when (and (eq *mode* :practice) (eq (fighter-form (fighter def)) :kessa))
      (let ((psf (ics-parry-sf (ic def))) (held (vpad-held (pilot-vpad (pilot def)) :sig)))
        (cond ((>= psf 25) (callout def "EARLY"))
              ((or (<= 0 psf 1) (<= 1 held 3)) (callout def "LATE")))))))

(defun ichigo-tick (e f g)
  "Both forms' :tick hook (every step, after the hits): JUJISHO's cut; the Shikai's stance; KESSA's clones (the J / K press
edges they answer, the Hoho clone, the O charge), the parry from blockstun and its tell, the afterimages."
  (declare (ignore g))
  (let ((st (ic e)))
    (ic-acc-watch e f st)
    (ichigo-cut e)
    (if (eq (fighter-form f) :kessa)
        (let* ((vp (pilot-vpad (pilot e))) (state (fighter-state f)) (mv (and (eq state :move) (fighter-move f))))
          (hist-push st e)
          (unless (member state '(:stun :air :down :wakeup :cine))
            (dolist (bt '(:quick :flash))
              (when (and (= 1 (vpad-held vp bt)) (not (vpad-modded-p vp bt))) (ichigo-press e bt))))
          (if (eq state :hoho)
              (when (and (>= (fighter-sf f) *hoho-appear*) (not (ics-hoho-done st))) (setf (ics-hoho-done st) t) (hoho-clone e))
              (setf (ics-hoho-done st) nil))
          (if (and mv (eq (mv-kind mv) :kikon))
              (unless (ics-o-live st) (setf (ics-o-live st) t) (ichigo-o-press e f st))
              (setf (ics-o-live st) nil))
          (if (eq state :guard-hit) (parry-from-blockstun e f st vp) (setf (ics-bs-key st) -1))
          (parry-watch e f st)
          (echo-watch e f st))
        (let ((mv (and (eq (fighter-state f) :move) (fighter-move f))))
          (if (and mv (member (mv-name mv) '(:ic-tsuki :ic-tsuki-k2 :ic-tsuki-re)))
              (tsuki-step e f st mv)
              (unless (and mv (eq (mv-name mv) :ic-tsuki-dash)) (setf (ics-dashed st) nil)))))))

;;; ================================================================ the CPU (KESSA's :ai :reflex, ai.lisp AI-REFLEX)
(defun incoming-hazard-in (e lo hi)
  "One of E's opponent's waves / fireballs reaches E within LO-HI frames."
  (let ((o (opp-of e)) (q (pos-of e)) (hit nil))
    (do-entities (h (hz hazard))
      (when (and (not hit) (eql (hazard-owner hz) o) (member (hazard-kind hz) '(:wave :fireball))
                 (> (hazard-hits-left hz) 0) (<= (hazard-delay hz) 0) (> (hazard-speed hz) 0.1))
        (let* ((dx (- (aref q 0) (hazard-x hz))) (dz (- (aref q 2) (hazard-z hz))) (dist (sqrt (+ (* dx dx) (* dz dz))))
               (fr (/ (* 60 (max 0.0 (- dist 1.0))) (hazard-speed hz))))
          (when (<= lo fr hi) (setf hit t)))))
    hit))

(defun clone-idle-in-reach (e)
  "The reach bucket of E's best idle clone to the opponent (docs/duel/DUEL_ICHIGO.md \"The CPU with the stance and the
clones\"): :light (<= 2.4 m: both answers land), :heavy (<= 3.0 m: J's heavy lands), or NIL."
  (let ((best nil) (q (pos-of (opp-of e))))
    (dolist (h (ichigo-clones e) best)
      (let* ((hz (hazard h)) (c (hazard-data hz))
             (dd (sqrt (+ (expt (- (aref q 0) (hazard-x hz)) 2) (expt (- (aref q 2) (hazard-z hz)) 2)))))
        (when (eq (icc-state c) :idle)
          (cond ((<= dd 2.4) (setf best :light)) ((and (<= dd 3.0) (null best)) (setf best :heavy))))))))

(defun ichigo-ai-kessa (e b s d)
  "KESSA's CPU reflexes (free states). v2 first (by difficulty, ICHIGO-AI-MASH / -PERFECT-HOHO, then the parry at EASY 0.6x
/ NORMAL x1 / HARD 1.0, ICHIGO-AI-LONG-PUNISH, ZANZO): L when a hit it can see (the opponent's move, as perceived) or a projectile will land
4-22 frames out (inside the window f2-25), one roll per opponent action at *AI-IC-PARRY-P*, with the price in hand.
The Kikon near (his Reishi under *AI-KESSA-BANK-AT*, O ready, not reeling): bank clones with side Steps, 3 m out and not
into a coming hit (2, 3 with the gauge for them); the O itself stays the generic ender / rush, which then finds them (千影
3-4 Konpaku), and nothing below spends them meanwhile. An idle clone in reach of him: J (the clones' heavies) or K (their lights, his K1 in reach),
*AI-KESSA-CLONE-J-P* per step. Else O with >= 2 clones within 8.6 m, *AI-KESSA-O-P* per step (x2 with 3)."
  (let* ((g (gauges e)) (n (clone-count e)) (gg (gauges-gg g)) (pay (and (not (gauges-guardless g)) (>= gg *clone-cost*))))
    (cond ((ichigo-ai-mash e b s d))
          ((ichigo-ai-perfect-hoho e b s d))
          ((ichigo-ai-red e b s d))                     ; (the Konpaku economy: HARD only)
          ((ichigo-ai-convert e b s d))
          ((and (>= gg *kessa-parry-cost*) (not (gauges-guardless g))
                (< (brain-react-roll b) (ic-p b (* 0.6 *ai-ic-parry-p*) *ai-ic-parry-p* 1.0))
                (let ((lead (- (snap-s s) (snap-sf s) (brain-delay b))))
                  (or (and (eq (snap-state s) :move) (eq (snap-phase s) :main) (member (snap-kind s) '(:quick :flash :sig :sp :kikon))
                           (<= 4 lead 22) (< d (+ (snap-reach s) 0.6))
                           (not (snap-x-axis-p s)))                ; (an :x-axis line is :ranged: no parry catches it)
                      (incoming-hazard-in e 4 22))))
           (why b :parry :sig))
          ((ichigo-ai-long-punish e b s d))
          ;; v2: ZANZO (2 bars, none running: every attack echoed at half, signature damage) at 2.6-7 m or while he is
          ;; down / launched, he not attacking; HARD 0.15 a step, EASY / NORMAL never
          ((and (or (<= 2.6 d 7.0) (member (snap-state s) '(:down :air))) (not (eq (snap-state s) :move))
                (kit-command-ok-p e :sp2) (< (sim-rnd01) (ic-p b 0.0 0.0 0.15)))
           (why b :zanzo :sp2))
          ((and (let ((go (gauges (opp-of e)))) (< (gauges-reishi go) (* *ai-kessa-bank-at* (gauges-reishi-max go))))
                (kit-command-ok-p e :kikon) (not (member (snap-state s) '(:stun :air :down :wakeup :hoho))))
           (and pay (< n (if (>= gg (+ *clone-cost* 25.0)) 3 2)) (>= d 3.0)
                (not (and (eq (snap-state s) :move) (snap-live-p s) (snap-near-p s e d 1.0)))   ; (a line: on it, ai.lisp)
                (why b :bank :side-step)))
          ((and (not (member :parry (snap-flags s))) (not (member (snap-state s) '(:down :wakeup :hoho)))
                (< (sim-rnd01) *ai-kessa-clone-j-p*))
           (let ((r (clone-idle-in-reach e)))
             (cond ((null r) nil)
                   ((and (eq r :light) (<= 1.6 d 3.0)) (why b :clone-reach :f))
                   (t (why b :clone-reach :q)))))
          ((and (>= n 2) (<= d 8.6) (kit-command-ok-p e :kikon) (< (sim-rnd01) (* (if (>= n 3) 2 1) *ai-kessa-o-p*)))
           (why b :clones :kikon)))))

;;; ================================================================ the CPU v2 (docs/duel/DUEL_AI_V2.md; every chance by difficulty)
(defun ic-p (b easy normal hard)
  "A chance by brain B's difficulty: EASY <= NORMAL <= HARD (the user's layering, 2026-10-02)."
  (case (brain-difficulty b) (:easy easy) (:hard hard) (t normal)))

(defun ic-hits-p (mv) (and mv (plusp (length (mv-hits mv)))))

(defun ichigo-ai-long-punish (e b s d)
  "Out of J's reach, an opponent still recovering (his move past its active frames, as perceived) or reeling: the
longest tool of the form that lands before he is free (K1; else the SP that hits: SOGA's 5 m lunge, KUSARI-BIKI's 7 m
chain), one roll per his action (the react roll) at (EASY 0 / NORMAL 0.15 / HARD 0.8). The generic punish keeps J's reach."
  (let* ((kit (kit-of e)) (left (snap-left-seen s b)))
    (when (and (snap-punishable-p s)
               (< (snap-left s) 99)
               (> d (+ (mv-reach (kit-command-move kit :q)) 0.4))
               (< (brain-react-roll b) (ic-p b 0.0 0.15 0.8)))
      (loop for c in '(:f :sp2 :sp1)
            for mv = (kit-command-move kit c)
            when (and (ic-hits-p mv) (kit-command-ok-p e c) (> left (mv-s mv))
                      (<= d (+ (mv-reach mv) (mv-slide mv) 0.1)))
              return (why b :long-punish c)))))

(defun ichigo-ai-mash (e b s d)
  "Against a J masher (AI-MASH-P, his perceived J starts): KESSA lays the parry where his next J lands (within 2 m, he not
guarding; it catches J, the counter crumples); either form K1s him walking in from out of his J (1.7-2.8 m). Per step
(EASY 0 / NORMAL 0.03 / HARD 0.25)."
  (when (and (ai-mash-p b) (not (member (snap-state s) '(:guard :guard-hit :down :wakeup :hoho :stun :air))))
    (let ((g (gauges e)) (kessa (eq (kit-form (kit-of e)) :kessa)))
      (cond ((and kessa (<= d 2.0) (not (gauges-guardless g)) (>= (gauges-gg g) (+ *kessa-parry-cost* 10.0))
                  (kit-command-ok-p e :sig) (< (sim-rnd01) (ic-p b 0.0 0.03 0.25)))
             (why b :mash-parry :sig))
            ((and (<= 1.7 d 2.8) (not (eq (snap-state s) :move)) (kit-command-ok-p e :f)
                  (< (sim-rnd01) (ic-p b 0.0 0.03 0.25)))
             (why b :mash-poke :f))))))

(defun ichigo-ai-perfect-hoho (e b s d)
  "The timed Hoho. His strike (any move with active frames in its main phase, as perceived: a slow J, K, L, SP, the
Breaker's strike, an O strike) lands 0-11 frames from now (its startup left minus our perception delay) within its reach
+ 1.5 m: Hoho now, inside the perfect window (*PERFECT-LEAD* 12: the automatic counter strike, his inputs locked 40 f,
15 flash-step back; KESSA's Hoho also posts a clone in front of him). One roll per his action (the Hoho roll) at (EASY 0 /
NORMAL 0 / HARD 1.0); only the Hoho's own price, no Burst reserve (the perfect refund pays most of it back), not in a burst."
  (let ((g (gauges e)) (lead (- (snap-s s) (snap-sf s) (brain-delay b))))
    (and (eq (snap-state s) :move) (eq (snap-phase s) :main) (member (snap-kind s) '(:quick :flash :sig :sp :breaker :kikon))
         (> (snap-active-end s) (snap-s s)) (<= 0 lead 11) (snap-near-p s e d 1.5)   ; (an :x-axis line: on it, ai.lisp)
         (not (snap-reflect-p s))                     ; (a reflect is :opp-reflect's, ai.lisp)
         (not (kit-rooted (kit-of e)))
         (hoho-ready-p e)
         (not (gauges-burst g))
         (< (brain-hoho-roll b) (ic-p b 0.0 0.0 1.0))
         (why b :perfect-hoho :hoho))))

(defun ichigo-bank-target (e b)
  "(b0a1: b1a0's always-bank / HARD O-poke-off measured worse on top of b0a0; KESSA banks as shipped. This is only the
bank ICHIGO-AI-CONVERT waits for.) KESSA's clones wanted for the Kikon (千影: 2 / 2 / 3 / 4 Konpaku by 0-3 clones; his Soul Break that + 1): shipped 2, 3
with the guard gauge for them (*CLONE-COST* + 25); HARD 3 down to *CLONE-COST* + 10 of the gauge."
  (let ((gg (gauges-gg (gauges e))))
    (if (>= gg (+ *clone-cost* (if (eq (brain-difficulty b) :hard) 10.0 25.0))) 3 2)))

(defun ichigo-ai-red-guard (e b s d)
  "ICHIGO-AI-RED's guard: red (HARD), his rush coming within 11 m: hold guard through its strike, one roll per his action."
  (let ((g (gauges e)))
    (and (gauges-red-p g) (plusp (ic-p b 0.0 0.0 1.0))
         (eq (snap-state s) :move) (eq (snap-kind s) :kikon)
         (or (member (snap-phase s) '(:aura :dash)) (and (eq (snap-phase s) :main) (< (snap-sf s) (snap-active-end s))))
         (< d 11.0) (plusp (ai-guard-k e)) (>= (gauges-gg g) 21.0)
         (< (brain-react-roll b) 0.95)
         (why b :red-guard :guard-long))))

(defun ichigo-assist-guard (e b s d)
  "Both forms' :assist-guard (assist.lisp AUTO GUARD): the defensive answers only, the timed Hoho and the red guard of a
rush (KESSA's parry is AUTO GUARD's own, PARRY-COMMAND)."
  (or (ichigo-ai-perfect-hoho e b s d) (ichigo-ai-red-guard e b s d)))

(defun ichigo-ai-red (e b s d)
  "We are red (his Kikon ready): live through it. His rush coming (aura, dash or the strike's startup, as perceived,
within 11 m): hold guard (the first strike is guardable red or not, KIKON-OUTCOME; the generic CPU only Hohos / Steps /
J1s it when red; blocked he is -14), one roll per his action, the gauge able to take the 20. Else SOUL REVERSE (WHITE,
+70 Reishi a second) to climb out of red while he isn't swinging at us, a roll a step: guarding alone only turned his
Kikons into Soul Breaks (worth one more). EASY / NORMAL 0 (the generic play), HARD 0.95 / 0.25."
  (let ((g (gauges e)))
    (when (and (gauges-red-p g) (plusp (ic-p b 0.0 0.0 1.0)))
      (cond ((ichigo-ai-red-guard e b s d))
            ((and (eq (burst-ok-p e) :white)
                  (not (and (eq (snap-state s) :move) (snap-live-p s) (snap-near-p s e d 1.5)))   ; (a line: ai.lisp)
                  (< (sim-rnd01) 0.25))
             (why b :red-white :burst))))))

(defun ichigo-rush-frames (d)
  "Frames from an O press at D m to its strike landing (both forms' rush: aura 6, 30 m/s to 1.6 m, S 7, + 2)."
  (+ 6 (max 0 (ceiling (- d 1.6) 0.5)) 7 2))

(defun ichigo-ai-convert (e b s d)
  "He is red (our Kikon ready; HARD only, EASY / NORMAL keep the generic play): turn it into the most Konpaku.
- KESSA's worth is its clones (2 / 2 / 3 / 4): no rush until the bank is up (ICHIGO-BANK-TARGET); the bank itself is
  ICHIGO-AI-KESSA's side Steps; up close a back Step posts one too.
- The rush only where his answer can't come: the generic CPU answers a rush it sees within 5 m (J1 / Hoho / Step), so
  rush when he is busy (recovering from a move, as perceived, longer than our rush takes: 0.9 per his action) or from
  7-8.4 m (he sees it inside 5 m only as it strikes: 0.3 a step); KESSA with its bank also chains him (KUSARI-BIKI at
  3.8-7 m, 0.15 a step: bound, the generic stun rush follows, every clone with it).
- Closer, the neutral decision is ours, without the generic neutral rush: J / K strings (their ender's O comes always on
  a red man, with the bank)."
  (when (and (kikon-ready-p e) (not (ai-sb-finish-p e)) (kit-command-ok-p e :kikon)
             (plusp (ic-p b 0.0 0.0 1.0))
             (not (member (snap-state s) '(:down :wakeup :hoho))))
    (let* ((kessa (eq (kit-form (kit-of e)) :kessa)) (g (gauges e))
           (short (and kessa (< (clone-count e) (ichigo-bank-target e b))
                       (not (gauges-guardless g)) (>= (gauges-gg g) *clone-cost*)))
           (left (snap-left-seen s b))
           (attacking (and (eq (snap-state s) :move) (< (snap-sf s) (snap-active-end s)))))
      (cond ((and (not short) (< d 8.4) (snap-recovering-p s) (< (snap-left s) 99) (>= left (ichigo-rush-frames d))
                  (< (brain-react-roll b) 0.9))
             (why b :rush-busy :kikon))
            ((and (not short) (<= 7.0 d 8.4) (not attacking) (< (sim-rnd01) 0.3))
             (why b :rush-far :kikon))
            ((and kessa (not short) (>= (clone-count e) 2) (<= 3.8 d 7.0) (not attacking) (kit-command-ok-p e :sp1)
                  (< (sim-rnd01) 0.15))
             (why b :chain :sp1))
            ((and (< d 7.0) (<= (brain-decide-t b) 1))
             (setf (brain-decide-t b) (ai-decide-time e b))
             (cond ((and short (< d 3.0) (not attacking)) (why b :bank :step))   ; (a back hop: a clone where it took off)
                   (short nil)                                                    ; (ICHIGO-AI-KESSA side-Steps it)
                   ;; (AI-ATTACK presses itself; :none keeps that press: no band below 5 m holds :kikon)
                   ((and (< d 5.0) (< (sim-rnd01) 0.7) (ai-attack e b (kit-of e) s d (brain-heat b) nil)) :none)))))))

;;; (b0a1: b0a0's reactive layer stacked with b1a0's Konpaku economy)
(defun ichigo-ai-shikai (e b s d)
  "The Shikai's :reflex (v2): the masher's answers, the timed Hoho, our red phase, the conversion on a red man, then the
long punish."
  (or (ichigo-ai-mash e b s d) (ichigo-ai-perfect-hoho e b s d) (ichigo-ai-red e b s d) (ichigo-ai-convert e b s d)
      (ichigo-ai-long-punish e b s d)))

(defun ichigo-ai-ender (e kit)
  "Both forms' :sp-ender (ai.lisp STRING-REFLEX: our J3 / K3 hit, the victim pushed just out of reach, no O ender rolled):
what chases him (a move started off a pushing ender chases, docs/duel/DUEL_STRINGS.md §16). The Shikai: SOGA (SP2, 130) with a
bar, else the O poke (70); KESSA: KUSARI-BIKI (SP1: the chain pulls him back to 1.6 m and binds him 40 f, then the J
follow-up). HARD: the SP 0.95, the Shikai's O poke all of the rest; NORMAL / EASY none (the generic SP cancel stays, the
shipped behaviour). AI-BRAIN: for a human the ASSIST's borrowed (HARD) brain (its AUTO COMBO calls STRING-REFLEX)."
  (let ((b (ai-brain e)))
    (when b
      (let ((bars (reiatsu-bars e)) (r (sim-rnd01)))
        (if (eq (kit-form kit) :kessa)
            (and (>= bars 1) (kit-command-ok-p e :sp1) (< r (ic-p b 0.0 0.0 0.95)) :sp1)
            (cond ((and (>= bars 1) (kit-command-ok-p e :sp2) (< r (ic-p b 0.0 0.0 0.95))) :sp2)
                  ((and (kit-command-ok-p e :kikon kit t) (< r (ic-p b 0.0 0.0 1.0))) :kikon)))))))

;;; ================================================================ the HUD: the clones' row (the kit meter's :draw / :label, :deck)
(defun ichigo-hud-label (g kit) "The portrait label." (declare (ignore g kit)) "BUNSHIN")

(defun ichigo-hud-meter (e kit x y w h right tm lx ly ls)
  "KESSA's kit-meter row: three clone pips (lit BLOOD-rimmed white per live clone, a thin arc of its life; pulsing at 3:
the 4-Konpaku Kikon), under them ZANZO's white bar draining, the label BUNSHIN xN (and on an O press the pips flash with
the Kikon's worth)."
  (declare (ignore kit))
  (let* ((st (ic e)) (hs (ichigo-clones e)) (live (remove-if-not (lambda (h) (clone-live-p (hazard-data (hazard h)))) hs))
         (n (length live)) (pw (/ w 3.6)) (hh (* 3.6 h)) (y0 (- (+ y (* 0.5 h)) (* 0.5 hh)))
         (flash (max 0.0 (- 1.0 (/ (- *match-tick* (ics-o-at st)) 40.0))))
         (pulse (if (= n 3) (+ 0.6 (* 0.4 (abs (sin (* 6.0 tm))))) 1.0)))
    (dotimes (i 3)
      (let* ((px (if right (- (+ x w) (* (1+ i) (+ pw (* 0.2 pw)))) (+ x (* i (+ pw (* 0.2 pw))))))
             (c (and (< i n) (hazard-data (hazard (nth i live))))) (cx (+ px (* 0.5 pw))))
        (flet ((figure (col rim)                       ; a small standing silhouette: head, shoulders, the robe
                 (when rim (ui-rect (- cx (* 0.27 hh)) (+ y0 (* 0.27 hh)) (* 0.54 hh) (* 0.75 hh) rim))
                 (ui-rect (- cx (* 0.12 hh)) y0 (* 0.24 hh) (* 0.26 hh) col)
                 (ui-rect (- cx (* 0.22 hh)) (+ y0 (* 0.3 hh)) (* 0.44 hh) (* 0.7 hh) col)))
          (if c
              (progn
                (figure (list 0.95 0.95 0.93 pulse) (list 0.82 0.06 0.11 pulse))
                (%arc (f32 cx) (f32 (+ y0 (* 0.5 hh))) (f32 (* 0.62 hh)) (f32 (max 1.0 (* 0.08 hh)))   ; its life
                      (f32 (max 0.0 (min 1.0 (/ (icc-life c) (float *clone-life*))))) 0.95 0.9 0.85 0.8))
              (figure '(0.3 0.3 0.34 0.6) nil)))
        (when (> flash 0.0) (ui-rect (- cx (* 0.4 pw)) (- y0 2) (* 0.8 pw) (+ hh 4) (list 1.0 1.0 1.0 (* 0.5 flash))))))
    (let ((z (block zz (do-entities (h (hz hazard)) (when (and (eql (hazard-owner hz) e) (eq (hazard-look hz) 'ichigo-zanzo-look))
                                                       (return-from zz hz))))))
      (when z                                       ; 残像: a white bar draining under the pips
        (let ((fr (max 0.0 (- 1.0 (/ (hazard-age z) (float (max 1 (hazard-life z))))))))
          (ui-rect (if right (+ x (- w (* w fr))) x) (+ y0 hh 2) (* w fr) (max 2.0 (* 0.35 h)) '(0.96 0.96 0.94 0.9)))))
    (when lx
      (let ((col '(0.82 0.06 0.11 1.0)))
        (hud-text (format nil "BUNSHIN x~d~:[~; ~d KONPAKU~]" n (> flash 0.0) (clone-konpaku (ics-o-n st)))
                  lx ly ls col :align (if right :right :left))))))

(defun ichigo-deck (e cx cy d)
  "KESSA's :deck hook (one hand): three BLOOD dots round the thumb, lit per live clone."
  (let ((n (clone-count e)) (r (* d 52.0)))
    (dotimes (i 3)
      (let* ((a (+ (* -0.5 pi) (* (1- i) 0.45))) (x (+ cx (* r (cos a)))) (y (+ cy (* r (sin a)))))
        (ui-rect (- x (* 3 d)) (- y (* 3 d)) (* 6 d) (* 6 d) (if (< i n) '(0.82 0.06 0.11 1.0) '(0.3 0.3 0.32 0.6)))))))

;;; ================================================================ debug (74000-75599, docs/duel/DUEL_ICHIGO.md "Knobs")
(pushnew '(74000 75599 ichigo-debug) *char-debug* :test #'equal)

(defparameter *ichigo-tests*
  ;; k: P1-form P2 P2-form distance P2's action P1's clones
  '((:base :kenpachi :base 3.0 nil 0) (:kessa :kenpachi :base 3.0 nil 0) (:kessa :kenpachi :base 2.6 :f 0)
    (:kessa :yamamoto :base 7.0 :sig 0) (:kessa :kenpachi :base 2.6 :breaker 0) (:base :yamamoto :base 8.0 :sig 0)
    (:base :kenpachi :base 8.0 nil 0) (:kessa :kenpachi :base 8.0 nil 3) (:kessa :kenpachi :base 2.2 nil 3)
    (:kessa :rukia :base 4.0 nil 0) (:kessa :kenpachi :base 2.4 :q 0))
  "ICHIGO-TEST k (74000+k): 0 / 1 the forms 3 m from an idle Kenpachi, 2 Kenpachi's K1 into KESSA (press L: the catch),
3 Yamamoto's L wave into KESSA at 7 m (press L: blocked, drained), 4 Kenpachi's Breaker (it breaks the parry), 5 the
Shikai vs Yamamoto's wave at 8 m (Shift+K: JUJISHO cuts it), 6 the Shikai 8 m from Kenpachi (the stance's dash / Getsuga),
7 KESSA with 3 clones 8 m out, 8 KESSA with 3 clones 2.2 m from an idle Kenpachi (a J string: the worst case), 9 KESSA
4 m from Rukia, 10 Kenpachi's J1 into KESSA (block it, L from blockstun catches J2).")

(defun ichigo-set-clones (e n)
  "E's clones: exactly N, on a ring 4 m round the opponent's side of him (stills, the worst-case probe)."
  (dolist (h (ichigo-clones e)) (destroy-entity h))
  (let* ((p (pos-of e)) (yaw (yaw-of e)))
    (dotimes (i n)
      (let ((a (+ yaw (* (- i 1) 0.9))))
        (ichigo-clone-spawn e (+ (aref p 0) (* 1.2 (fwd-x a))) (+ (aref p 2) (* 1.2 (fwd-z a))) :debug)))))

(defun ichigo-test (k)
  (destructuring-bind (f1 c2 f2 d act n) (nth k *ichigo-tests*)
    (ensure-battle :ichigo c2)
    (unless (eq (fighter-form (fighter *p1*)) f1) (force-form *p1* f1))
    (unless (eq (fighter-form (fighter *p2*)) f2) (force-form *p2* f2))
    (place *p1* *p2* d)
    (dolist (e (list *p1* *p2*))
      (let ((g (gauges e)))
        (fill (fighter-cd (fighter e)) 0)
        (setf (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) *fs-max* (gauges-gg g) *gg-max* (gauges-guardless g) nil
              (gauges-reishi g) (gauges-reishi-max g))))
    (when (plusp n) (ichigo-set-clones *p1* n))
    (when act
      (let ((b (brain *p2*)))
        (force-cmd *p2* act)
        (when (eq act :breaker) (setf (brain-press b) :breaker (brain-press-mod b) nil (brain-press-left b) 60))))))

(defun ichigo-cine-at (name f)
  "Stills: cinematic NAME (P1 Ichigo 3 m from Kenpachi, in the form it belongs to, 3 clones for 千影) held at frame F; when
it already runs it continues to F."
  (unless (and *cine* (eq (cine-name *cine*) name))
    (abort-cine)
    (setf *cine-hold* nil)
    (ensure-battle :ichigo :kenpachi) (place *p1* *p2* 3.0)
    (force-form *p1* (if (eq name 'ic-kikon-cine) :base :kessa))
    (when (eq name 'ic-kessa-kikon-cine) (setf (fighter-kikon-n (fighter *p1*)) 4))
    (start-cine name *p1* *p2*))
  (when *cine* (setf *cine-hold* t (cine-hold *cine*) f)))

(defun ichigo-debug (c)
  "74000+k ICHIGO-TEST k, 74080+k the 60-seed gate of pairing k (ICHIGO-AB-GATE); 74100+k .. 74400+k the forms' damage dealt / taken x (0.5 + k / 100) (Shikai dealt, taken,
KESSA dealt, taken); 74500+k the parry window's length = k (from f2); 74600+k *KESSA-PARRY-CATCH* = k; 74700+k
*CLONE-LIFE* = 10k; 74800+k *CLONE-BURST-DMG* = k; 74900+k (k 0-3) P1's clones = k, 74905 log P2's combo; 74910+k
*CLONE-SCALE* = k / 20 (k < 40); 74950+k *AI-IC-PARRY-P* = k / 50 (k < 40); 74990+k a pose still (*ICHIGO-POSES*), 74989
its camera turned 90 deg; 75000 + 150 i + k stills of cinematic i (0 the Shikai
Kikon, 1 千影, 2 the awakening, 3 the KESSA Getsuga Soul Break) held at frame 2k."
  (when (>= c 75000)
    (return-from ichigo-debug
      (ichigo-cine-at (nth (min 3 (floor (- c 75000) 150)) '(ic-kikon-cine ic-kessa-kikon-cine ic-kessa-cine ic-kessa-getsuga-cine))
                      (* 2 (mod (- c 75000) 150)))))
  (let ((k (mod c 100)) (b (floor (- c 74000) 100)))
    (case b
      (0 (if (>= k 80) (ichigo-ab-gate (- k 80)) (ichigo-test k)))
      (1 (setf (kit-mult (find-kit :ichigo :base)) (+ 0.5 (/ k 100.0))))
      (2 (setf (kit-taken (find-kit :ichigo :base)) (+ 0.5 (/ k 100.0))))
      (3 (setf (kit-mult (find-kit :ichigo :kessa)) (+ 0.5 (/ k 100.0))))
      (4 (setf (kit-taken (find-kit :ichigo :kessa)) (+ 0.5 (/ k 100.0))))
      (5 (setf (getf (mv-params (find-move :ic-k-parry)) :window) (list 2 (+ 1 k))))
      (6 (setf *kessa-parry-catch* (float k)))
      (7 (setf *clone-life* (* 10 k)))
      (8 (setf *clone-burst-dmg* k))
      (9 (cond ((< k 4) (ichigo-set-clones *p1* k))
               ((= k 89) (setf *ic-pose-ang* (mod (+ *ic-pose-ang* 90.0) 360.0)))
               ((= k 5) (let ((f (fighter *p2*)))
                          (log-msg "duel ichigo combo P2 hits ~d dmg ~d reishi ~d" (fighter-combo-hits f) (fighter-combo-dmg f)
                                   (gauges-reishi (gauges *p2*)))))
               ((<= 10 k 49) (setf *clone-scale* (/ (- k 10) 20.0)))
               ((<= 50 k 89) (setf *ai-ic-parry-p* (/ (- k 50) 50.0)))
               ((>= k 90) (ichigo-pose (- k 90))))))))

(defparameter *ichigo-poses*
  '((:base :ic-tsuki 0.2) (:base :ic-rangetsu 0.14) (:base :ic-tsuki-otoshi 0.2) (:base :ic-tsuki-otoshi 0.31)
    (:kessa :ic-k-stance 0.0) (:kessa :ic-k-cut 0.14) (:kessa :ic-k-back 0.14) (:kessa :ic-k-parry 0.1) (:kessa :ic-k-zanzo 0.2)
    (:base :ic-cero-raise 1.0))
  "74990+k: P1 Ichigo (in the form) frozen at time (s) of the clip, 3 m from an idle Kenpachi (pose review stills).")

(defun ichigo-ab-gate (k)
  "74080+k: the seed gate of pairing k (*PAIRS*, debug.lisp) over 60 seeds from *GATE-SEED0* + 1: one A/B stream in one run
(with 39000+10a+b for the awakening mode)."
  (start-gate (+ 10 k))                                 ; (it starts seed +1 at once)
  (setf *gate* (loop for seed from (+ 2 *gate-seed0*) to (+ 60 *gate-seed0*) collect (list seed (nth k *pairs*)))))

(defvar *ic-pose-ang* 30.0 "The pose stills' camera angle round P1 (74989 turns it 90 deg).")
(defun ichigo-pose (k)
  (destructuring-bind (form clip tm) (nth k *ichigo-poses*)
    (abort-cine)
    (ichigo-test (if (eq form :base) 0 1))
    (setf *cine-hold* t)
    (start-cine 'ic-pose-cine *p1* *p2*)
    (play-clip *p1* clip :blend 0 :time tm :speed 0.0)))
