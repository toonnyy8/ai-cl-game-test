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
  :vol (:cap 0.3 12.0 0.5 0.5) :on-hit :knockdown :kb 3.0 :on-frame ((26 ken-meteor-cut)))
;; O in Nozarashi, LEAP CLEAVE (his own move: not derived): 8 f of crouch, then a leap at 18 m/s for at
;; most 30 f, the direction locked at take-off (the height is a look, :lift), then the widest cleave,
;; 3.08 m over 160 deg, and a gash where it lands: 10.6 m, <= 49 f. Cooldown 90.
(defmove :ke-kikon-n :kind :kikon :clip :ke-n-leap :clip-2 :ke-stance-cut :clip-s 8 :callout "SKY SPLIT" :cine ken-sky-split-cine
  :startup 11 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 3.08 :arc 160 :on-hit :knockback :kb 2.5 :cooldown 90
  :on-frame ((11 ken-leap-cleave))
  :params (:aura 8 :aim 120.0 :speed 18.0 :dash-max 30 :dash-track 0.0 :look :leap :lift 1.6 :sfx :whoosh-cleaver))

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
               (6.0 99.0 :step 1 :kikon 1 nil 1))                      ; the charge / leap as a poke
       :guard 0.35 :hoho 0.2 :awaken-above 0.0 :sp-cancel-bars 1 :dash 0.8 :kikon-range 9.0
       :react (:projectile :sig :flash-startup :sig) :block-string 0.8))   ; a blocked string goes on (guard pressure)

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

(defun ken-leap-cleave (e)
  "LEAP CLEAVE lands: a short gash split into the ground ahead (a look)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 3.0 :life 45 :look :meteor))
  (emit :sfx :ground-crack e))

(defun ken-meteor-cut (e)
  "Split the Meteor: the cleave splits the ground 12 m ahead (a look)."
  (let ((p (pos-of e)))
    (spawn-hazard :line e :x (aref p 0) :z (aref p 2) :yaw (yaw-of e) :size 12.0 :life 60 :look :meteor))
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
  (at 98 (cine-slash v :cut) (shot-on v -110 3.6 1.0) (setf *caption* nil))
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
  (at 102 (shot-on v 95 7.5 1.2 :look 1.0) (lens 50) (setf *caption* nil))
  (at 132 (shot-on a -20 5.0 0.7 :look 1.4) (lens 45)))

(defcine ken-nozarashi-cine (a v :len 108 :hold 84)
  "NOME, NOZARASHI (§5; paced by user review 3): beat 0 on the face close-up; the eyepatch tears (a negative); the
yellow reiatsu pillar held long on a black card, Kenpachi silhouetted with a yellow back-rim (the only time yellow floods
the frame); close, low and wide-angle while the katana grows into the cleaver, in silence; the 野晒 / 呑め、 stamp in
black on a white card."
  (at 0 (cine-clip a :ke-patch :blend 3 :speed (/ 1.0 1.5)) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (setf (model-weapon (model a)) :ken-katana (model-hide (model a)) nil)
      (shot-on a 10 1.9 1.9 :look 1.85)
      (hold-both a v 10) (impact-frame :negative 2) (play-sfx :awaken-rise))
  (at 26 (setf (model-hide (model a)) '(:eyepatch))
      (let ((p (pos-of a)))
        (vfx-awaken-burst (aref p 0) 1.0 (aref p 2) :nozarashi)
        (vfx-shockwave (aref p 0) (aref p 2) 7.0 0.6 :rgb '(1.0 0.9 0.3)))
      (impact-frame :negative 2) (play-sfx :awaken-boom) (shake 0.2 0.3))
  (at 28 (card :black a) (back-rim 30 1.0 0.85 0.23) (shot-on a 0 4.6 0.8 :look 1.6) (lens 52))
  (during (0 108) (let ((p (pos-of a)))                 ; faint and narrow in the face close-up: the patch reads
                    (vfx-aura (aref p 0) 0.0 (aref p 2) (cond ((< cf 28) 2.0) ((< cf 58) 6.5) (t 3.2)) :nozarashi (/ cf 60.0) (cine-dt)
                              :k (if (< cf 26) 0.1 1.0))))   ; 28-58: the pillar
  (at 54 (cine-clip a :ke-nome :blend 2))
  (at 58 (card nil) (shot-on a 30 1.6 0.45 :look 1.5) (lens 86 -8) (silence 20))
  (at 78 (setf (model-weapon (model a)) :nozarashi)
      (impact-frame :negative 2) (card :white a) (shot-on a 20 4.4 0.8 :look 1.3 :off 0.9) (lens 42)
      (caption "野晒" :kanji2 "呑め、" :reading "NOME, NOZARASHI" :side 0 :ink t)
      (play-sfx :whoosh-cleaver))
  (at 80 (impact-frame :manga 10)))
