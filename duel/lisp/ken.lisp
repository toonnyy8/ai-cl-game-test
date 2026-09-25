;;;; ken.lisp — ZARAKI KENPACHI (TYBW), design-v1 §5.2: his moves (DEFMOVE) and his two forms
;;;; (DEFKIT): :base and :nozarashi (his permanent awakening). Nozarashi's inherited moves are
;;;; DERIVED by the kit (startup +3, reach x1.4; damage x1.15 via :mult), never copied here.
;;;; Clip names are the art contract (ken-art.lisp). Below the data: his hook functions and his
;;;; cinematics (DEFCINE).
(in-package :duel)

;;; ================================================================ base
(defmove :ke-q1 :kind :quick :clip :ke-q1 :startup 7 :active 3 :recovery 12 :dmg 35 :adv-block -2
  :reach 2.6 :arc 100 :on-hit :flinch :slide 0.8)                    ; wild slash, lunge 0.8 m
(defmove :ke-q2 :kind :quick :clip :ke-q2 :startup 7 :active 3 :recovery 13 :dmg 35 :adv-block -2
  :reach 2.6 :arc 100 :on-hit :flinch)
(defmove :ke-q3 :kind :quick :clip :ke-q3 :startup 11 :active 4 :recovery 22 :dmg 55 :adv-block -12
  :reach 2.6 :arc 360 :on-hit :knockback :kb 3.0)                    ; spinning cut
(defmove :ke-f1 :kind :flash :clip :ke-f1 :startup 16 :active 4 :recovery 20 :dmg 70 :adv-block -4
  :reach 3.0 :arc 120 :on-hit :stagger)                              ; two-handed cut
(defmove :ke-f2 :kind :flash :clip :ke-f2 :startup 20 :active 5 :recovery 28 :dmg 90 :adv-block -14
  :reach 2.6 :arc 90 :on-hit :launch)                                ; rising cleave
;; the Q Q -> F branch: entered 6 f into the wind-up so it combos off Q2's flinch (same -14)
(defmove :ke-f2q :kind :flash :clip :ke-f2 :enter 6 :startup 20 :active 5 :recovery 28 :dmg 90 :adv-block -14
  :reach 2.6 :arc 90 :on-hit :launch)
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
  :vol (:cap 0.0 3.0 0.5 0.6) :on-hit :knockdown :kb 2.0 :on-frame ((22 ken-ground-crack)))
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
;; the Kikon rush (O): red aura, dash, then the stance's huge cross-body cut. Red opponent + O held
;; when it connects = the Kikon; else a plain knockback hit (guardable unless he is red), -14 on block
(defmove :ke-kikon :kind :kikon :clip :sh-run :clip-2 :ke-stance-cut :cine ken-kikon-cine
  :startup 8 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.2 :arc 110 :on-hit :knockback :kb 2.5)

;;; ================================================================ Nozarashi
(defmove :ke-meteor :kind :sp :clip :ke-meteor :callout "SPLIT THE METEOR"
  :startup 26 :active 4 :recovery 30 :dmg 240 :adv-block -16
  :vol (:cap 0.3 12.0 0.5 0.5) :on-hit :knockdown :kb 3.0 :on-frame ((26 ken-meteor-cut)))
;; Nozarashi's own Kikon rush (own moves aren't derived): written with the derivation's numbers,
;; startup 8 + 3, reach 2.2 x 1.4; the rush's aura / dash / trigger range are unchanged
(defmove :ke-kikon-n :kind :kikon :clip :sh-run :clip-2 :ke-stance-cut :clip-s 8 :callout "SKY SPLIT" :cine ken-sky-split-cine
  :startup 11 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 3.08 :arc 110 :on-hit :knockback :kb 2.5)

;;; ================================================================ forms
(defkit :kenpachi :base
  :name "KENPACHI" :body :kenpachi :weapon :ken-katana :stance :ke-stance
  :intro :ke-intro :win :ke-win
  :walk *walk-kenpachi* :run *run-kenpachi* :reishi *reishi-max* :aura :reiatsu
  :cornered *cornered-per-konpaku* :cornered-max *cornered-max* :reset-reiatsu *reset-reiatsu-bonus*
  :absorb-sfx :laugh
  :commands (:q :ke-q1 :f :ke-f1 :sig :ke-stance :sp1 :ke-buttagiru :sp2 :ke-charge
             :breaker :ke-breaker :kikon :ke-kikon)
  :strings ((:ke-q1 :q :ke-q2) (:ke-q2 :q :ke-q3) (:ke-q2 :f :ke-f2q) (:ke-f1 :f :ke-f2)
            (:ke-charge :land :ke-flurry))
  :awaken-form :nozarashi
  :ai (:intents (:approach 2 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.0 4.0) :pressure (1.5 3.0) :zone (4.0 6.0) :defend (3.0 5.0))
       :moves ((0.0 3.0 :q 5 :f 2 :breaker 1 :sp2 1 :sig 2 nil 3)
               (3.0 4.0 :f 1 :sp1 2 :step 1 nil 2)
               (4.0 6.0 :sp1 4 :sp2 2 nil 1)
               (6.0 99.0 :step 1 nil 1))
       :guard 0.35 :hoho 0.2 :awaken-above 0.0 :sp-cancel-bars 1 :dash 0.8
       :react (:projectile :sig :flash-startup :sig)))

(defkit :kenpachi :nozarashi :inherit :base
  :awakening t :mult *nozarashi-mult* :startup-add *nozarashi-startup* :reach-mult *nozarashi-reach*
  :passives (:projectile-cut :ignore-armor) :heal *nozarashi-heal*
  :weapon :nozarashi :stance :ke-n-stance :hide (:eyepatch) :aura :nozarashi :swing-sfx :whoosh-cleaver
  :enter-clips (:ke-patch :ke-nome) :cine ken-nozarashi-cine
  :commands (:sp1 :ke-meteor :kikon :ke-kikon-n))

;;; ================================================================ hooks (called through the data's symbols)
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
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 3.5 :life 50 :look :crack))
  (emit :sfx :ground-crack e))

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

(defun ken-meteor-cut (e)
  "Split the Meteor: the cleave splits the ground 12 m ahead (a look)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 12.0 :life 60 :look :meteor))
  (emit :sfx :ground-crack e))

;;; ================================================================ cinematics
(defcine ken-kikon-cine (a v :len 114 :hold 72)
  "Base Kikon: three reckless cuts, laughing; the last one goes through the victim."
  (at 0 (face-each-other a v 2.0)
      (cine-clip a :ke-kikon :blend 2) (cine-clip v :sh-kikon-victim :blend 4)
      (shot-pair a v (camera-side a) 5.0 1.6)
      (caption "KIKON" :sub "MOTTO TANOSHIMASETE KURE YO!" :color '(1 0.2 0.25 1))
      (play-sfx :laugh))
  (at 21 (cine-slash v :cut) (shot-on v 120 3.8 1.2))
  (at 45 (cine-slash v :cut) (shot-on v -110 3.6 1.0))
  (at 72 (cine-slash v :heavy) (shot-pair a v (- (camera-side a)) 5.5 1.3)
      (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3))
      (play-sfx :kikon-slash) (play-sfx :konpaku-shatter) (shake 0.3 0.35) (ui-flash 1 1 1 0.6))
  (at 80 (play-sfx :laugh)))

(defun cine-slash (v kind)
  "A cinematic cut landing on V: sparks, sound, flash."
  (multiple-value-bind (x y z) (actor-point v 1.2) (vfx-hit x y z kind))
  (play-sfx (if (eq kind :heavy) :cut-heavy :cut))
  (setf (model-flash (model v)) 0.1))

(defcine ken-sky-split-cine (a v :len 90 :hold 34)
  "Nozarashi Kikon: one cleave; a vertical line of light splits the sky, the ground splits, the
screen halves shear apart for 12 frames."
  (at 0 (face-each-other a v 2.6)
      (cine-clip a :ke-kikon-n :blend 2) (cine-clip v :sh-kikon-victim :blend 4)
      (shot-on a 60 4.5 1.0 :look 1.6 :ahead 1.3)
      (caption "KIKON" :sub "NOZARASHI" :color '(1 0.9 0.35 1))
      (play-sfx :whoosh-cleaver))
  (at 25 (cine-slash v :heavy) (play-sfx :kikon-slash) (play-sfx :ground-crack) (shake 0.4 0.5) (ui-flash 1 1 0.8 0.8 3.0)
      (shot-on a 180 10.0 3.6 :look 1.2 :ahead 5.0)      ; down the cut: it splits the screen at its centre
      (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x y z 3)))
  ;; (the ground split is part of the look, on the cine clock: a sim hazard would freeze with the sim)
  (during (25 90) (let ((q (pos-of v))) (vfx-sky-split (aref q 0) (aref q 2) (yaw-of a) (/ (- cf 25) 60.0) 1.0))))

(defcine ken-nozarashi-cine (a v :len 72 :hold 52)
  "NOME, NOZARASHI: (1) the eyepatch torn off, a yellow reiatsu pillar and shockwave; (2) the katana
grows into the cleaver. 野晒."
  (at 0 (cine-clip a :ke-patch :blend 3) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (setf (model-weapon (model a)) :ken-katana (model-hide (model a)) nil)
      (shot-on a 10 1.9 1.9 :look 1.85)
      (play-sfx :awaken-rise))
  (at 18 (setf (model-hide (model a)) '(:eyepatch))
      (let ((p (pos-of a)))
        (vfx-awaken-burst (aref p 0) 1.0 (aref p 2) :nozarashi)
        (vfx-shockwave (aref p 0) (aref p 2) 7.0 0.6 :rgb '(1.0 0.9 0.3)))
      (play-sfx :awaken-boom) (shake 0.2 0.3))
  (during (0 72) (let ((p (pos-of a)))                  ; faint and narrow in the face close-up: the patch reads
                   (vfx-aura (aref p 0) 0.0 (aref p 2) (if (< cf 30) 2.0 3.2) :nozarashi (/ cf 60.0) (frame-dt)
                             :k (if (< cf 18) 0.1 1.0))))
  (at 30 (cine-clip a :ke-nome :blend 2) (shot-on a 30 4.6 1.3 :look 1.6))
  (at 51 (setf (model-weapon (model a)) :nozarashi)
      (caption "NOME, NOZARASHI" :kanji :nozarashi :color '(1 0.9 0.35 1))
      (play-sfx :whoosh-cleaver) (ui-flash 1 0.95 0.5 0.5)))
