;;;; barro-art.lisp — LILLE BARRO II's own looks (docs/duel/DUEL_LILLE_V2.md §7). His art is Lille's, shared by reference
;;;; (lille-art.lisp: the bodies, Diagramm, every :lb-* clip, LILLE-DRAW's wings / halos / legs, LB-LOOK's lines and beams);
;;;; this file holds only what is his: the draw hook BR-DRAW (Lille's, then his stance's aim line), his trace lines' floor
;;;; look (BR-TRACE-LOOK, his BRH data) and the 狙擊 gauge's HUD row. The clips Lille never had (the recall :br-recall and its
;;;; strings :br-rc1..3) come in the art batch; until then the moves play Lille's stand-ins (barro.lisp *BR-STAND-INS*).
;;;; Everything here is cosmetic: the sim never reads it. Loaded after lille-art.lisp (its macros and props) and before
;;;; barro.lisp (whose state and knobs these functions read at draw time).
(in-package :duel)

(declaim (special *br-trace-len* *br-trace-r-thick*))  ; (barro.lisp's, loaded after this file)

;;; ---------------------------------------------------------------- his clips (DUEL_LILLE_V2 §7, §12: the art batch)
;;; The motions Lille never had, timed to barro.lisp's frame data. JILLIEL's on its rig (the front wing pair's tips are the
;;; rig's hands, Lille's convention; the keys' comments give their aims, azimuth / elevation in the chest frame, + = his
;;; right / up, as lille-art.lisp's); the owl's twins (:br-o-*, its claws are the hands) through the owl kits' :clip-map.
;;; - 回収 the recall :br-recall (8 f; its f0 takes the traces back, its f7 starts the string): the wings flung open wide and
;;;   high, the column arched back and rising (f3-f6) while the traces' light flies into him (BR-DRAW), then drawn in round
;;;   the gathered light (f8 = the strings' first frame).
;;; - the derivative strings, every beat a line fired from the wing tips at him (BR-DRAW draws each tip's line and flash):
;;;   :br-rc0 空收 one beat (f6, both wings), :br-rc1 二連 two (f6 the right wing, f16 the left), :br-rc2 四連 four (f6 R,
;;;   f14 L, f22 R, f32 the launch: both wings swept up from low), :br-rc3 裁き five (f6 R, f12 L, f18 R, f24 L, f36 the
;;;   finisher: risen into NIJUSHI-KO's ring over f26-35, the beam on f36 blowing him back). Each beat: cocked (2-3 f),
;;;   snapped at him on its frame, kicked back.
;;; - :br-to-en (12 f, ranged at f11): folded, rising with the wings thrown open, EN's float. The backstep keeps Lille's
;;;   :lb-w-tenshin (14 f) in JILLIEL; the owl's :br-o-to-en steps the root down by the owl's lift (*BR-OWL-LIFT* 0.35) on
;;;   the frame the form turns ranged (f11), as :lb-o-tenshin does on Lille's f6; its :br-o-backstep turns ranged at f0
;;;   (decision V6), so its keys are written in EN's lift throughout (§17).
(defpose :br-open-pose (:base :lb-w-stance)          ; flung open: R 105/35, L -105/35, the column arched back, rising
  (:root :f -0.06 :u 0.18 :pitch -8) (:spine :flex -12) (:head :flex -10) (:arm-r :flex -14 :side 128) (:elbow-r :flex 8)
  (:arm-l :flex -14 :side 128) (:elbow-l :flex 8) (:thigh-r :flex -8) (:thigh-l :flex -8))
(defpose :br-gather-pose (:base :lb-w-stance)        ; drawn in round the gathered light: R 62/4, L -62/4, bowed over it
  (:root :f 0.02 :u 0.14 :pitch 3) (:spine :flex 8) (:head :flex 8) (:arm-r :flex 28 :side 84) (:elbow-r :flex 34)
  (:arm-l :flex 28 :side 84) (:elbow-l :flex 34) (:thigh-r :flex -4) (:thigh-l :flex -4))
(defpose :br-cock-r (:base :lb-w-stance)             ; R 135/18 (cocked high behind), L -95/-8
  (:root :f -0.08 :u 0.12 :yaw -10) (:spine :flex -4) (:chest :twist -20) (:arm-r :flex -42.3 :side 114.7) (:elbow-r :flex 30)
  (:arm-l :flex -5 :side 82) (:elbow-l :flex 8) (:thigh-r :flex -12) (:thigh-l :flex 14))
(defpose :br-fire-r (:base :lb-w-stance)             ; R 30/-2 (with the turn: at him), L -104/-12
  (:root :f 0.14 :u 0.06 :yaw 12) (:spine :flex 10) (:chest :twist 18) (:arm-r :flex 59.9 :side 86) (:elbow-r :flex 2)
  (:arm-l :flex -13.7 :side 77.6) (:elbow-l :flex 6) (:thigh-r :flex 24) (:thigh-l :flex -16))
(defpose :br-kick-r (:base :lb-w-stance)             ; R 36/16 (kicked up by the shot), L -104/-12
  (:root :f -0.12 :u 0.1 :yaw 10) (:spine :flex -4) (:chest :twist 14) (:head :flex -2) (:arm-r :flex 51 :side 116)
  (:elbow-r :flex 12) (:arm-l :flex -13.7 :side 77.6) (:elbow-l :flex 6) (:thigh-r :flex 16) (:thigh-l :flex -10))
(defpose :br-cock-l (:base :lb-w-stance)             ; the mirrors: L -135/18, R 95/-8
  (:root :f -0.08 :u 0.12 :yaw 10) (:spine :flex -4) (:chest :twist 20) (:arm-l :flex -42.3 :side 114.7) (:elbow-l :flex 30)
  (:arm-r :flex -5 :side 82) (:elbow-r :flex 8) (:thigh-l :flex -12) (:thigh-r :flex 14))
(defpose :br-fire-l (:base :lb-w-stance)
  (:root :f 0.14 :u 0.06 :yaw -12) (:spine :flex 10) (:chest :twist -18) (:arm-l :flex 59.9 :side 86) (:elbow-l :flex 2)
  (:arm-r :flex -13.7 :side 77.6) (:elbow-r :flex 6) (:thigh-l :flex 24) (:thigh-r :flex -16))
(defpose :br-kick-l (:base :lb-w-stance)
  (:root :f -0.12 :u 0.1 :yaw -10) (:spine :flex -4) (:chest :twist -14) (:head :flex -2) (:arm-l :flex 51 :side 116)
  (:elbow-l :flex 12) (:arm-r :flex -13.7 :side 77.6) (:elbow-r :flex 6) (:thigh-l :flex 16) (:thigh-r :flex -10))
(defpose :br-cock-both (:base :lb-w-stance)          ; R 140/30, L -140/30 (both raised behind)
  (:root :f -0.18 :u 0.18 :pitch -6) (:spine :flex -10) (:head :flex -4) (:arm-r :flex -41.6 :side 131.9) (:elbow-r :flex 34)
  (:arm-l :flex -41.6 :side 131.9) (:elbow-l :flex 34) (:thigh-r :flex -10) (:thigh-l :flex 10))
(defpose :br-fire-both (:base :lb-w-stance)          ; R 5/-3, L -5/-3 (both at him)
  (:root :f 0.2 :u 0.02 :pitch 4) (:spine :flex 14) (:head :flex 4) (:arm-r :flex 84.2 :side 59) (:elbow-r :flex 2)
  (:arm-l :flex 84.2 :side 59) (:elbow-l :flex 2) (:thigh-r :flex 22) (:thigh-l :flex -18))
(defpose :br-kick-both (:base :lb-w-stance)          ; R 14/20, L -14/20 (blown up and back)
  (:root :f -0.32 :u 0.08 :pitch -9) (:spine :flex -12) (:head :flex -8) (:arm-r :flex 65.8 :side 146.4) (:elbow-r :flex 12)
  (:arm-l :flex 65.8 :side 146.4) (:elbow-l :flex 12) (:thigh-r :flex 8) (:thigh-l :flex -6))
(defpose :br-settle-both (:base :lb-w-stance)        ; R 42/6, L -42/6
  (:root :f -0.3 :u 0.06 :pitch -6) (:spine :flex -6) (:arm-r :flex 47.7 :side 98.9) (:elbow-r :flex 14)
  (:arm-l :flex 47.7 :side 98.9) (:elbow-l :flex 14))
(defpose :br-low-both (:base :lb-w-stance)           ; the launch's wind-up: crouched, both wings swept low before him
  (:root :f -0.04 :u -0.06 :pitch 8) (:spine :flex 22) (:head :flex 10) (:arm-r :flex 70 :side 22) (:elbow-r :flex 6)
  (:arm-l :flex 70 :side 22) (:elbow-l :flex 6) (:thigh-r :flex 16) (:thigh-l :flex -12))
(defpose :br-launch-both (:base :lb-w-stance)        ; the launch: risen, both wings swept up at him (the tips ahead, high)
  (:root :f 0.16 :u 0.3 :pitch -6) (:spine :flex -8) (:head :flex -10) (:arm-r :flex 80 :side 150) (:elbow-r :flex 2)
  (:arm-l :flex 80 :side 150) (:elbow-l :flex 2) (:thigh-r :flex 10) (:thigh-l :flex -10))
(defpose :br-ring-pose (:base :lb-w-stance)          ; the finisher's ring (NIJUSHI-KO's): R 75/-22, L -75/-22, risen
  (:root :f -0.04 :u 0.34 :pitch -1) (:spine :flex -4) (:arm-r :flex 13.9 :side 67.3) (:elbow-r :flex 4)
  (:arm-l :flex 13.9 :side 67.3) (:elbow-l :flex 4) (:thigh-r :flex -6) (:thigh-l :flex -6))
(defpose :br-blown-pose (:base :lb-w-stance)         ; the beam's recoil: R 118/-4, L -118/-4, blown back
  (:root :f -0.62 :u 0.4 :pitch -14) (:spine :flex -20) (:head :flex -10) (:arm-r :flex -27.9 :side 85.5) (:elbow-r :flex 22)
  (:arm-l :flex -27.9 :side 85.5) (:elbow-l :flex 22) (:thigh-r :flex -6) (:thigh-l :flex -6))

(defstrike :br-recall (8 0 0 :base :lb-w-stance)   ; 回収: flung open (the light flies in), drawn round it
  (0) (3 :br-open-pose) (6 :br-open-pose (:root :u 0.22 :pitch -9) (:arm-r :side 134) (:arm-l :side 134))
  (:end :br-gather-pose))
(defstrike :br-rc0 (6 2 24 :base :lb-w-stance)   ; 空收: one line, both wings
  (0 :br-gather-pose) (3 :br-cock-both) (:s :snap :br-fire-both) (:a :br-kick-both) (20 :br-settle-both)
  (:end :lb-w-stance))
(defstrike :br-rc1 (6 12 24 :base :lb-w-stance)   ; 二連: the right wing f6, the left f16
  (0 :br-gather-pose) (3 :br-cock-r) (:s :snap :br-fire-r) (9 :br-kick-r) (13 :br-cock-l) (16 :snap :br-fire-l)
  (:a :br-kick-l) (30 :br-settle-both) (:end :lb-w-stance))
(defstrike :br-rc2 (6 28 24 :base :lb-w-stance)   ; 四連: R f6, L f14, R f22, the launch f32 (both wings swept up)
  (0 :br-gather-pose) (3 :br-cock-r) (:s :snap :br-fire-r) (9 :br-kick-r) (12 :br-cock-l) (14 :snap :br-fire-l)
  (17 :br-kick-l) (20 :br-cock-r) (22 :snap :br-fire-r) (25 :br-kick-r) (29 :br-low-both) (32 :snap :br-launch-both)
  (:a :br-launch-both (:root :u 0.36 :pitch -9) (:spine :flex -12)) (46 :br-settle-both) (:end :lb-w-stance))
(defstrike :br-rc3 (6 32 26 :base :lb-w-stance)   ; 裁き: R f6, L f12, R f18, L f24, the ring f26-35, the beam f36
  (0 :br-gather-pose) (3 :br-cock-r) (:s :snap :br-fire-r) (8 :br-kick-r) (10 :br-cock-l) (12 :snap :br-fire-l)
  (14 :br-kick-l) (16 :br-cock-r) (18 :snap :br-fire-r) (20 :br-kick-r) (22 :br-cock-l) (24 :snap :br-fire-l)
  (26 :br-kick-l) (31 :br-ring-pose) (35 :br-ring-pose (:root :f -0.12 :u 0.34 :pitch -4) (:spine :flex -10))
  (36 :snap :br-blown-pose) (:a :br-blown-pose (:root :f -0.7 :u 0.42 :pitch -15) (:spine :flex -22))
  (50 :br-settle-both (:root :u 0.2)) (:end :lb-w-stance))
(defstrike :br-to-en (12 0 0 :base :lb-w-stance)   ; melee -> ranged: folded, rising with the wings thrown open, EN
  (0 :lb-w-fold-pose) (5 (:root :u 0.16 :pitch -4) (:spine :flex -6) (:arm-r :flex 10 :side 60) (:elbow-r :flex 60)
                         (:arm-l :flex 10 :side 60) (:elbow-l :flex 60))
  (9 :br-open-pose (:root :f -0.02 :u 0.12)) (:end :lb-w-stance))

;; the owl's twins (base :lb-o-stance: the claws are the hands; the claw keys are lille-art.lisp's solved ones: J1 / J2's
;; wind-ups and rakes for the single beats, J3's spread and scissor for both, EN K3's raised-and-thrown for the finisher)
(defpose :br-o-open-pose (:base :lb-o-stance)        ; both claws spread high and wide, the neck raised, arched back
  (:root :f -0.1 :u 0.1 :pitch -7) (:spine :flex 4) (:neck :flex -14) (:head :flex -22)
  (:arm-r :flex 119.6 :side -74.8) (:elbow-r :flex 86.6) (:hand-r :flex -40) (:arm-l :flex 119.6 :side -74.8)
  (:elbow-l :flex 86.6) (:hand-l :flex -40) (:thigh-r :flex -8) (:thigh-l :flex 8))
(defpose :br-o-gather-pose (:base :lb-o-stance)      ; the claws drawn in before the chest, hunched over the light
  (:root :u -0.02) (:spine :flex 26) (:neck :flex 30) (:head :flex 12) (:arm-r :flex 50 :side 20) (:elbow-r :flex 104)
  (:hand-r :flex 30) (:arm-l :flex 50 :side 20) (:elbow-l :flex 104) (:hand-l :flex 30))
(defpose :br-o-cock-r (:base :lb-o-stance)           ; R (0.62 2.72 -0.05): J1's wind-up
  (:root :f -0.14 :u 0.04 :yaw -12 :pitch -4) (:spine :flex 8) (:chest :twist -26) (:neck :flex 2) (:head :flex -14)
  (:arm-r :flex 118.3 :side -17.9) (:elbow-r :flex 79.2) (:hand-r :flex -40) (:arm-l :flex 17.3 :side 60.3)
  (:elbow-l :flex 89.3) (:hand-l :flex 10) (:thigh-r :flex -12) (:thigh-l :flex 14))
(defpose :br-o-fire-r (:base :lb-o-stance)           ; R (0.3 1.5 1.66): J1's rake at him
  (:root :f 0.2 :u -0.06 :yaw 6 :pitch 4) (:spine :flex 30) (:chest :twist 14) (:neck :flex 34) (:head :flex 12)
  (:arm-r :flex 93 :side -50.8) (:elbow-r :flex 70.8) (:hand-r :flex 30) (:arm-l :flex -44 :side 16.4)
  (:elbow-l :flex 148.1) (:hand-l :flex 10) (:thigh-r :flex 32) (:thigh-l :flex -20))
(defpose :br-o-kick-r (:base :lb-o-stance)           ; R (-0.12 1.12 1.66): through
  (:root :f 0.1 :u -0.07 :yaw 12 :pitch 5) (:spine :flex 33) (:chest :twist 24) (:neck :flex 36) (:head :flex 14)
  (:arm-r :flex 84.3 :side -72.9) (:elbow-r :flex 68.5) (:hand-r :flex 50) (:arm-l :flex -46.9 :side 17.5)
  (:elbow-l :flex 130) (:hand-l :flex 10) (:thigh-r :flex 32) (:thigh-l :flex -20))
(defpose :br-o-cock-l (:base :lb-o-stance)           ; the mirrors (J2's)
  (:root :f -0.14 :u 0.04 :yaw 12 :pitch -4) (:spine :flex 8) (:chest :twist 26) (:neck :flex 2) (:head :flex -14)
  (:arm-r :flex 17.3 :side 60.3) (:elbow-r :flex 89.3) (:hand-r :flex 10) (:arm-l :flex 118.3 :side -17.9)
  (:elbow-l :flex 79.2) (:hand-l :flex -40) (:thigh-r :flex 14) (:thigh-l :flex -12))
(defpose :br-o-fire-l (:base :lb-o-stance)
  (:root :f 0.2 :u -0.06 :yaw -6 :pitch 4) (:spine :flex 30) (:chest :twist -14) (:neck :flex 34) (:head :flex 12)
  (:arm-r :flex -44 :side 16.4) (:elbow-r :flex 148.1) (:hand-r :flex 10) (:arm-l :flex 93 :side -50.8)
  (:elbow-l :flex 70.8) (:hand-l :flex 30) (:thigh-r :flex -20) (:thigh-l :flex 32))
(defpose :br-o-kick-l (:base :lb-o-stance)
  (:root :f 0.1 :u -0.07 :yaw -12 :pitch 5) (:spine :flex 33) (:chest :twist -24) (:neck :flex 36) (:head :flex 14)
  (:arm-r :flex -46.9 :side 17.5) (:elbow-r :flex 130) (:hand-r :flex 10) (:arm-l :flex 84.3 :side -72.9)
  (:elbow-l :flex 68.5) (:hand-l :flex 50) (:thigh-r :flex -20) (:thigh-l :flex 32))
(defpose :br-o-cock-both (:base :lb-o-stance)        ; J3's spread: R (1.05 2.15 0.2), L mirrored
  (:root :f -0.1 :u 0.07 :pitch -6) (:spine :flex 6) (:neck :flex -12) (:head :flex -22)
  (:arm-r :flex 119.6 :side -74.8) (:elbow-r :flex 86.6) (:hand-r :flex -40) (:arm-l :flex 119.6 :side -74.8)
  (:elbow-l :flex 86.6) (:hand-l :flex -40) (:thigh-r :flex -8) (:thigh-l :flex 8))
(defpose :br-o-fire-both (:base :lb-o-stance)        ; J3's scissor at him: R (-0.08 1.5 1.7), L (0.14 1.62 1.66)
  (:root :f 0.22 :u -0.05 :pitch 5) (:spine :flex 30) (:neck :flex 50) (:head :flex 26)
  (:arm-r :flex 39.8 :side -141.6) (:elbow-r :flex 50.7) (:hand-r :flex 30) (:arm-l :flex 29.4 :side -141.9)
  (:elbow-l :flex 58.5) (:hand-l :flex 30) (:thigh-r :flex 28) (:thigh-l :flex -20))
(defpose :br-o-kick-both (:base :lb-o-stance)        ; blown back, the claws up
  (:root :f -0.2 :u 0.04 :pitch -6) (:spine :flex 10) (:neck :flex 10) (:head :flex -10)
  (:arm-r :flex 98.4 :side -28.2) (:elbow-r :flex 99.9) (:hand-r :flex -30) (:arm-l :flex 98.4 :side -28.2)
  (:elbow-l :flex 99.9) (:hand-l :flex -30) (:thigh-r :flex 6) (:thigh-l :flex -4))
(defpose :br-o-low-both (:base :lb-o-stance)         ; the launch's wind-up: crouched, both claws low before him
  (:root :f 0.1 :u -0.12 :pitch 12) (:spine :flex 38) (:neck :flex 40) (:head :flex 18)
  (:arm-r :flex 90.2 :side -4.3) (:elbow-r :flex 37.4) (:hand-r :flex 50) (:arm-l :flex 88.6 :side -4.1)
  (:elbow-l :flex 45) (:hand-l :flex 50) (:thigh-r :flex 20) (:thigh-l :flex -14))
(defpose :br-o-launch-both (:base :lb-o-stance)      ; the launch: risen, both claws thrown up at him
  (:root :f 0.3 :u 0.16 :pitch -6) (:spine :flex 4) (:neck :flex -6) (:head :flex -14)
  (:arm-r :flex 112 :side -8) (:elbow-r :flex 20) (:hand-r :flex -10) (:arm-l :flex 112 :side -8)
  (:elbow-l :flex 20) (:hand-l :flex -10) (:thigh-r :flex 10) (:thigh-l :flex -10))
(defpose :br-o-raise-both (:base :lb-o-stance)       ; the finisher's wind-up: risen, both claws raised overhead (EN K3's)
  (:root :f 0.1 :u 0.32 :pitch -8) (:spine :flex -10) (:neck :flex -14) (:head :flex -14)
  (:arm-r :flex 103.1 :side -22.4) (:elbow-r :flex 84.7) (:hand-r :flex -40) (:arm-l :flex 103.1 :side -22.4)
  (:elbow-l :flex 84.7) (:hand-l :flex -40))
(defpose :br-o-throw-both (:base :lb-o-stance)       ; the finisher: both claws thrown at him, R (0.2 1.3 2.29)
  (:root :f 0.6 :u 0 :pitch 16) (:spine :flex 34) (:neck :flex 36) (:head :flex 16)
  (:arm-r :flex 106.6 :side 1.3) (:elbow-r :flex 27.5) (:hand-r :flex 40) (:arm-l :flex 106.2 :side 1.2)
  (:elbow-l :flex 33.2) (:hand-l :flex 40))

(defstrike :br-o-recall (8 0 0 :base :lb-o-stance)
  (0) (3 :br-o-open-pose) (6 :br-o-open-pose (:root :u 0.14 :pitch -8)) (:end :br-o-gather-pose))
(defstrike :br-o-rc0 (6 2 24 :base :lb-o-stance)
  (0 :br-o-gather-pose) (3 :br-o-cock-both) (:s :snap :br-o-fire-both) (:a :br-o-fire-both (:root :f 0.26))
  (20 :br-o-kick-both) (:end :lb-o-stance))
(defstrike :br-o-rc1 (6 12 24 :base :lb-o-stance)
  (0 :br-o-gather-pose) (3 :br-o-cock-r) (:s :snap :br-o-fire-r) (9 :br-o-kick-r) (13 :br-o-cock-l) (16 :snap :br-o-fire-l)
  (:a :br-o-kick-l) (30 :br-o-gather-pose) (:end :lb-o-stance))
(defstrike :br-o-rc2 (6 28 24 :base :lb-o-stance)
  (0 :br-o-gather-pose) (3 :br-o-cock-r) (:s :snap :br-o-fire-r) (9 :br-o-kick-r) (12 :br-o-cock-l) (14 :snap :br-o-fire-l)
  (17 :br-o-kick-l) (20 :br-o-cock-r) (22 :snap :br-o-fire-r) (25 :br-o-kick-r) (29 :br-o-low-both)
  (32 :snap :br-o-launch-both) (:a :br-o-launch-both (:root :u 0.2)) (46 :br-o-gather-pose) (:end :lb-o-stance))
(defstrike :br-o-rc3 (6 32 26 :base :lb-o-stance)
  (0 :br-o-gather-pose) (3 :br-o-cock-r) (:s :snap :br-o-fire-r) (8 :br-o-kick-r) (10 :br-o-cock-l) (12 :snap :br-o-fire-l)
  (14 :br-o-kick-l) (16 :br-o-cock-r) (18 :snap :br-o-fire-r) (20 :br-o-kick-r) (22 :br-o-cock-l) (24 :snap :br-o-fire-l)
  (26 :br-o-kick-l) (31 :br-o-raise-both) (35 :br-o-raise-both (:root :u 0.36 :pitch -10))
  (36 :snap :br-o-throw-both) (:a :br-o-throw-both (:root :f 0.64 :u -0.1)) (52 :br-o-gather-pose) (:end :lb-o-stance))
(defstrike :br-o-to-en (12 0 0 :base :lb-o-stance)   ; KIN -> EN (the form and its lift 0 -> 0.35 at f11)
  (0 :lb-o-fold-pose) (6 (:root :u 0.3 :pitch -6) (:spine :flex 6) (:arm-r :flex -40 :side 40) (:arm-l :flex -40 :side 40))
  (11 (:root :u 0.4 :pitch -6) (:spine :flex 6) (:arm-r :flex -40 :side 40) (:arm-l :flex -40 :side 40))
  (11.5 :snap (:root :u 0.05 :pitch -6) (:spine :flex 6) (:arm-r :flex -40 :side 40) (:arm-l :flex -40 :side 40))
  (:end :lb-oe-stance))
;; the backstep into EN: the form (and its lift, *BR-OWL-LIFT* 0.35) turns at f0 since decision V6, so every key is written
;; in EN's lift (drawn = u + 0.35): f0 the fold on the floor (u -0.38 = drawn -0.03, the J3 it leaves stands on the floor),
;; the leap up and back (drawn 0.3 at f6, 0.4 at f13), EN's float by f17 (drawn 0.35). No step anywhere (§17; it stepped
;; 0.35 m down on f13 when the form turned there, and popped 0.35 m up on f0 once it turned at f0).
(defstrike :br-o-backstep (14 0 8 :base :lb-o-stance)
  (0 :lb-o-fold-pose (:root :u -0.38))
  (6 (:root :u -0.05 :pitch -6) (:spine :flex 6) (:arm-r :flex -40 :side 40) (:arm-l :flex -40 :side 40))
  (13 (:root :u 0.05 :pitch -6) (:spine :flex 6) (:arm-r :flex -40 :side 40) (:arm-l :flex -40 :side 40))
  (17 :lb-oe-stance) (:end :lb-oe-stance))

;;; ---------------------------------------------------------------- the draw hook
(defun-fast %br-aim-look (e f side)
  "The stance's aim line (Lille's %LB-AIM-LOOK on his moves): a thin line on the floor from under the muzzle to the wall,
grey while the stance (:br-kamae / :br-kamae-k / :br-kamae-re) tracks, jade once the shot :br-k-shot locks until it fires; the reticle at
the opponent's distance, turning while it tracks, closing once locked."
  (declare (fixnum side))
  (setf side 0)                                         ; (unused: the slot memory is Lille's HUD tag's, not his)
  (let* ((mv (fighter-move f)) (nm (and mv (eq (fighter-state f) :move) (mv-name mv)))
         (stance (or (eq nm :br-kamae) (eq nm :br-kamae-k) (eq nm :br-kamae-re)))
         (locked (and (eq nm :br-k-shot) (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))))
    (when (or stance locked)
      (%lb-load-place! e)
      (let* ((v *lb-v*) (yaw (aref v 27)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
             (x0 (+ (aref v 24) (* 0.5f0 ux))) (z0 (+ (aref v 26) (* 0.5f0 uz)))
             (wall (%lb-wall x0 z0 ux uz)) (dist (the single-float (fighter-dist f)))
             (dq (f-clamp (- dist 0.5f0) 1f0 (f-max 1f0 wall)))
             (rx (+ x0 (* dq ux))) (rz (+ z0 (* dq uz)))
             (r (if locked (- 0.65f0 (* 0.018f0 (i->f (fighter-sf f)))) 1.1f0))
             (tm (fx-clock)))
        (declare (type f32vec v) (single-float yaw ux uz x0 z0 wall dist dq rx rz r tm))
        (%lb-floor-line (if locked 1 0) x0 z0 ux uz wall (if locked 0.06f0 0.035f0))
        (%lb-reticle locked rx rz r (if locked 0.785398f0 (* 1.4f0 tm)))))
    nil))

;;; ---------------------------------------------------------------- the recall and its strings' looks (§12)
(defparameter *br-rc-beats*
  '((:br-rc0 (6 3)) (:br-rc1 (6 1) (16 2)) (:br-rc2 (6 1) (14 2) (22 1) (32 3)) (:br-rc3 (6 1) (12 2) (18 1) (24 2) (36 4)))
  "The recall strings' beats (their moves' line frames, barro.lisp): (frame kind), kind 1 the right wing / claw fires, 2 the
left, 3 both, 4 the finisher (the ring and the beam). The clips (above) and the looks (BR-RC-DRIVE, BR-DRAW) read them.")
(dolist (c '(:br-recall :br-rc0 :br-rc1 :br-rc2 :br-rc3))   ; the six table wings fan out through the recall and its strings
  (pushnew c *lb-spread-clips*))                             ;  (LILLE-DRAW's spread: an SP's; Lille never plays these clips)

(defun-fast br-rc-beat (nm sf)
  "The latest beat of recall string NM at its frame SF: (+ (* 1000 kind) age), age the frames since it (<= 999), or -1
before the first (or NM not a string). 0 B (a constant list walked)."
  (declare (fixnum sf))
  (let ((best -1))
    (declare (fixnum best))
    (dolist (b (cdr (assoc nm *br-rc-beats*)) best)
      (let ((fr (first b)))
        (declare (fixnum fr))
        (when (<= fr sf) (setf best (+ (* 1000 (the fixnum (second b))) (min 999 (- sf fr)))))))))

(defmacro %br-chain-clock (nm sf)
  "The recall's look clock: its own frame through :br-recall, 7 + the string's frame through :br-rc0..3 (its f7 starts
it), else -1."
  `(let ((%nm ,nm) (%sf ,sf))
     (declare (fixnum %sf))
     (cond ((eq %nm :br-recall) %sf) ((member %nm '(:br-rc0 :br-rc1 :br-rc2 :br-rc3)) (+ 7 %sf)) (t -1))))

(defun-fast br-rc-drive (f mv)
  "Lille's %LB-SP-DRIVE! for his recall strings (JILLIEL's wings; its clause calls this): each beat kicks the firing wing
(SANREN's whip: a virtual speed back, easing out over *LB-SP-KICK* frames) and flashes its holes; the finisher (:br-rc3's
f36) rises into NIJUSHI-KO's ring over f26-35 (lit, shaking), the beam blows it back. The numbers go out through
*LB-SP-EXT* (ring, cup, shake, speed, flash, lit bits, the striking wings' mask, the other wings' share). T when it set
them. Reads the move's frame only (cosmetic). 0 B."
  (let* ((x *lb-sp-ext*) (sf (fighter-sf f)) (nm (mv-name mv)) (b (br-rc-beat nm sf)))
    (declare (type f32vec x) (fixnum sf b))
    (when (eq (fighter-phase f) :main)
      (cond ((and (eq nm :br-rc3) (>= sf 26))                ; the finisher: NIJUSHI-KO's ring, its beam (frames, no scale)
             (let ((post (i->f (- sf 36))) (pre (/ (i->f (- sf 26)) 10f0)))
               (declare (single-float post pre))
               (setf (aref x 5) 255f0 (aref x 6) 3f0 (aref x 7) 0.8f0 (aref x 2) 0f0 (aref x 4) 0f0)
               (if (< post 0f0)
                   (setf (aref x 0) (%lb-ss (/ pre 0.35f0))
                         (aref x 1) (- 0.35f0 (* 0.25f0 (%lb-ss (/ (- pre 0.4f0) 0.6f0))))
                         (aref x 2) (* (the single-float *lb-ring-shake*) (%lb-ss (/ (- pre 0.3f0) 0.7f0)) (+ 0.3f0 (* 0.7f0 pre)))
                         (aref x 3) (* 0.5f0 (the single-float *lb-strike-in*) (%lb-ss (/ (- pre 0.5f0) 0.5f0))))
                   (let ((bl (f-max 0f0 (- 1f0 (/ post 10f0)))))
                     (declare (single-float bl))
                     (setf (aref x 0) (- 1f0 (%lb-ss (/ (- post 18f0) 16f0)))
                           (aref x 1) (* -0.85f0 (%lb-ss (/ post 2.5f0)) (- 1f0 (%lb-ss (/ (- post 8f0) 18f0))))
                           (aref x 3) (* (the single-float *lb-ring-blow*) bl bl)
                           (aref x 5) (if (< post 6f0) 255f0 0f0) (aref x 4) (f-max 0f0 (- 1f0 (/ post 6f0))))))
               t))
            ((>= b 0)                                         ; a beat: SANREN's kick on the firing wing
             (let ((kind (floor b 1000)) (age (mod b 1000)))
               (declare (fixnum kind age))
               (when (< age (the fixnum *lb-sp-kick*))
                 (let ((u (- 1f0 (/ (i->f age) (i->f (the fixnum *lb-sp-kick*))))))
                   (declare (single-float u))
                   (setf (aref x 0) 0f0 (aref x 1) 0f0 (aref x 2) 0f0
                         (aref x 3) (- (* (the single-float *lb-sp-whip*) u u (if (= kind 3) 1.3f0 1f0)))
                         (aref x 4) (f-max 0f0 (- 1f0 (/ (i->f age) 6f0)))
                         (aref x 5) (case kind (1 16f0) (2 32f0) (t 48f0)) (aref x 6) (i->f (min 3 kind)) (aref x 7) 0.6f0)
                   t))))))))

;; the traces' light flying back (the recall): BR-TRACE-LOOK notes each live trace it draws (*BR-SEEN*), BR-DRAW keeps the
;; last frame's set while he is not recalling (*BR-FLY*) and draws it flying into him through the recall's look clock
(declaim (type f32vec *br-seen* *br-fly*))
(defvar *br-seen* (make-f32 (* 2 65)) "Per side (65 a side): [0] the traces noted this frame, then x z yaw thick per trace (16).")
(defvar *br-fly* (make-f32 (* 2 65)) "Per side: the last frame's traces before the recall (as *BR-SEEN*).")
(defparameter *br-fly-f* 9 "The recall's look: the traces' far ends reach him on this frame of its clock (their near ends at 2/3) ...")
(defparameter *br-gather-f* '(5 15) "... and the light gathered at his chest flares over these frames.")
(declaim (type fixnum *br-art-hold* *br-art-hold-next*))
(defvar *br-art-hold* -1 "Debug 82200+f (art stills): the sim freezes once his look clock (BR-HOLD-CLOCK) reaches f; -1 none.")
(defvar *br-art-hold-next* -1 "... armed by 82200+f, taken by the next scene (82100+k) once it is set up.")

(defun-fast %br-recall-look (e jm side c)
  "The recall's look at its clock C (frames): each trace taken back (*BR-FLY*) a jade line (the owl's gold) whose near end
rushes along the floor and up into his chest by 2/3 of *BR-FLY-F* and whose far end follows from the wall by *BR-FLY-F*,
brightening, a light at its head; then the gathered light flares at his chest (*BR-GATHER-F*, bigger with more traces; a
faint puff for none). 0 B."
  (declare (type f32vec jm) (fixnum side c))
  (setf e nil)                                          ; (unused: the hook's entity, kept for the signature)
  (let* ((v *br-fly*) (o (* 65 side)) (n (min 16 (f->i (aref v o)))) (pal (if (> (lb-fxs side 15) 0.5f0) +pal-gold+ +pal-jade+))
         (ff (i->f (the fixnum *br-fly-f*))) (cf (i->f c)) (b (%lb-ss (/ cf ff))) (a (%lb-ss (/ cf (* 0.667f0 ff))))
         (k (- 1f0 (%lb-ss (/ (- cf (- ff 2f0)) 3f0)))) (p *lb-p*))
    (declare (type f32vec v p) (fixnum o n) (single-float pal ff cf b a k))
    (joint-point! p jm (ji :chest) 0f0 0f0 0f0)
    (let ((cx (aref p 0)) (cy (aref p 1)) (cz (aref p 2)))
      (declare (single-float cx cy cz))
      (when (> k 0.01f0)
        (dotimes (i n)
          (let* ((q (+ o 1 (* 4 i))) (yaw (aref v (+ q 2))) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
                 (ox (+ (aref v q) (* 0.6f0 ux))) (oz (+ (aref v (+ q 1)) (* 0.6f0 uz))) (l (%lb-wall ox oz ux uz))
                 (fx0 (+ ox (* l ux))) (fz0 (+ oz (* l uz)))
                 (nx (+ ox (* a (- cx ox)))) (ny (+ 0.05f0 (* a (- cy 0.05f0)))) (nz (+ oz (* a (- cz oz))))
                 (fx (+ fx0 (* b (- cx fx0)))) (fy (+ 0.05f0 (* b (- cy 0.05f0)))) (fz (+ fz0 (* b (- cz fz0))))
                 (w (* (if (> (aref v (+ q 3)) 0.5f0) 0.12f0 0.045f0) (+ 1f0 (* 1.4f0 b)))) (sd (i->f i)))
            (declare (fixnum q) (single-float yaw ux uz ox oz l fx0 fz0 nx ny nz fx fy fz w sd))
            (toon-ribbon (fx fy fz) ((- nx fx) (- ny fy) (- nz fz)) ((* 0.5f0 w) w) :heat (0.8f0 1f0) :seed (- -61f0 sd) :wob 0.04f0
                         :pal pal :k (* 0.95f0 k) :k1 k :segs 3)
            (toon-ribbon (fx fy fz) ((- nx fx) (- ny fy) (- nz fz)) ((* 0.15f0 w) (* 0.35f0 w)) :heat (1f0 1f0) :seed (- -62f0 sd)
                         :wob 0.02f0 :pal +pal-hit+ :k (* 0.9f0 k) :k1 (* 0.9f0 k) :segs 2)
            (when (< a 0.98f0)                              ; the light's head
              (fx-star nx ny nz 0.05f0 0.16f0 6 (+ sd (* 0.3f0 cf)) 0f0 0f0 0.1f0 (+ 63f0 sd) pal (* 0.9f0 k) :push 0.2f0)))))
      (let* ((g0 (i->f (the fixnum (first *br-gather-f*)))) (g1 (i->f (the fixnum (second *br-gather-f*))))
             (u (/ (- cf g0) (- g1 g0))) (s (+ 0.3f0 (* 0.12f0 (i->f n)))))
        (declare (single-float g0 g1 u s))
        (when (< 0f0 u 1f0)
          (let ((kk (* (if (zerop n) 0.5f0 0.95f0) (f-sin (* 3.1415927f0 u)))))
            (declare (single-float kk))
            (fx-star cx cy cz (* 0.15f0 s kk) (* 0.55f0 s kk) 10 (* 2f0 cf 0.1f0) 0f0 0f0 0.15f0 64f0 pal kk :push 0.35f0)
            (fx-star cx cy cz (* 0.06f0 s kk) (* 0.22f0 s kk) 6 (* -3f0 cf 0.1f0) 0f0 0f0 0.05f0 65f0 +pal-hit+ kk :push 0.4f0))))))
  nil)

(defun-fast %br-beat-look (e f jm side mv)
  "A recall string's beat (*BR-RC-BEATS*), its first 5 frames: from each firing wing tip (the claw: the rig's hand) a line
at him (to his chest, the line's height), jade (the owl's gold), thinning, a flash at the tip; the finisher's from both
(wider). 0 B but the opponent's place (one lookup on those frames)."
  (declare (type f32vec jm) (fixnum side))
  (setf e nil)
  (let* ((b (br-rc-beat (mv-name mv) (fighter-sf f))) (kind (if (>= b 0) (floor b 1000) 0)) (age (if (>= b 0) (mod b 1000) 99)))
    (declare (fixnum b kind age))
    (when (and (eq (fighter-phase f) :main) (< age 5))
      (let* ((q (pos-of (fighter-opp f))) (p *lb-p*) (k (- 1f0 (/ (i->f age) 5f0)))
             (pal (if (> (lb-fxs side 15) 0.5f0) +pal-gold+ +pal-jade+)) (w (* k (if (= kind 4) 0.16f0 0.06f0)))
             (tx (aref q 0)) (ty 1.2f0) (tz (aref q 2)))
        (declare (type f32vec q p) (single-float k pal w tx ty tz))
        (dotimes (h 2)
          (when (logbitp h (if (= kind 4) 3 kind))
            (joint-point! p jm (if (= h 0) (ji :hand-r) (ji :hand-l)) 0f0 0f0 0f0)
            (let ((hx (aref p 0)) (hy (aref p 1)) (hz (aref p 2)) (sd (i->f (+ h (* 2 kind)))))
              (declare (single-float hx hy hz sd))
              (toon-ribbon (hx hy hz) ((- tx hx) (- ty hy) (- tz hz)) (w (* 0.6f0 w)) :heat (1f0 0.7f0) :seed (- -71f0 sd)
                           :wob 0.02f0 :pal pal :k (* 0.95f0 k) :k1 (* 0.7f0 k) :segs 2)
              (toon-ribbon (hx hy hz) ((- tx hx) (- ty hy) (- tz hz)) ((* 0.35f0 w) (* 0.2f0 w)) :heat (1f0 1f0) :seed (- -72f0 sd)
                           :wob 0f0 :pal +pal-hit+ :k (* 0.9f0 k) :k1 (* 0.6f0 k) :segs 2)
              (fx-star hx hy hz (* 0.05f0 k) (* (if (= kind 4) 0.4f0 0.2f0) k) 6 sd 0f0 0f0 0.1f0 (+ 73f0 sd) pal k :push 0.25f0)))))))
  nil)

(defun br-hold-clock (f)
  "The art stills' clock of F's move (debug 82200+f): the recall chain's (%BR-CHAIN-CLOCK), else the move's frame, else -1."
  (let ((mv (and (eq (fighter-state f) :move) (fighter-move f))))
    (if mv (let ((c (%br-chain-clock (mv-name mv) (fighter-sf f)))) (if (>= c 0) c (fighter-sf f))) -1)))

;;; ---------------------------------------------------------------- his aim points' look (cosmetic, 0 B a frame; §17)
;;; Decision V7's aim points, drawn in the game's ink (DUEL_LILLE_V2 §17, 2026-10-10): each point a sigil on the floor (a
;;; ring, eight ticks, a chevron along its line toward him, Lille's eye mark turning inside; jade, the owl's gold), its line
;;; in value steps that read "pivoting on him": dim from the point to him, the light tone 2.5 m behind to 3.5 m past him,
;;; then the plain tone thinning past 12 / 20 m to the 31 m end, a light dash running from the point through him and on;
;;; SP2's thick one wider, its 1.2 m lane edged on both sides and a second ring round its sigil. Set: the sigil stamped in
;;; (1.5 x, settling), a flash and a ring at the point, the line drawn out to its end in 4 frames. Fired (materialised by a
;;; J / K): a light head runs along it from the point through him and on in 5 frames, the spent line flashes on the floor,
;;; the sigil bursts; a miss leaves an ink puff and a dashed gap where the line passed him by. Both players see all of it
;;; (the counterplay: step off the line). Numbers go through f32vecs and macros (a DEFUN-FAST call boxes floats).
(declaim (type f32vec *br-at* *br-shot* *br-tv*))
(defvar *br-at* (make-f32 16)
  "Per side (8 a side), written by BR-DRAW every frame for his traces' looks (HAZARD-DRAW runs after the fighters): [0 1]
his x z, [2 3] the opponent's, [4] 1 once written.")
(defvar *br-shot* (let ((v (make-f32 (* 2 4 12)))) (dotimes (i 8 v) (setf (aref v (+ (* 12 i) 1)) -1f6)))
  "Per side, 4 fired traces (12 each, the oldest reused): [0] the trace's id, [1] the fx clock when first seen fired, [2 3]
its point, [4] its yaw, [5] 1 thick, [6] 1 once it connected (hit or block: HAZARD-CONNECTED spent its hit), [7] his
distance along it then, [8 9] the opponent then, [10] 1 the owl's, [11] the fx clock it was last seen (the hazard lives 3
frames: gone, an unspent one missed).")
(defvar *br-tv* (make-f32 16) "The trace looks' scratch numbers ([0..7] %BR-FLOOR's, [8..11] %BR-SIGIL's).")
(defparameter *br-fire-f* 5 "Fired: the light head runs the whole line in this many frames (from the point through him) ...")
(defparameter *br-fire-life* 0.6 "... and the fired look (the burst, the spent line, a miss's mark) lasts this many seconds.")

(defun br-sigil-mesh (mb)
  "The aim point's sigil, unit radius, flat in XZ: a ring, eight short ticks outside it, a chevron past it along +Z (the line,
toward him)."
  (lb-ring mb 0.88 1.0 0.03 :n 32)
  (dotimes (i 8)
    (let ((a (* i (/ pi 4))))
      (with-xform (mb (xform :x (* 1.1 (cos a)) :z (* 1.1 (sin a)) :yaw (- a))) (mb-box mb (if (evenp i) 0.18 0.1) 0.03 0.045))))
  (dolist (s '(-1 1))
    (with-xform (mb (xform :x (* s 0.12) :z 1.32 :yaw (* s -0.8))) (mb-box mb 0.055 0.03 0.34))))
(defweapon :br-sigil-jade (:length 1.0) (:solid :ink 0 (mbc mb #xB4DCC4) (br-sigil-mesh mb)))
(defweapon :br-sigil-gold (:length 1.0) (:solid :ink 0 (mbc mb #xE2CC8E) (br-sigil-mesh mb)))
(defweapon :br-reticle-gold (:length 1.0) (:solid :ink 0 (mbc mb #xE2CC8E) (lb-reticle-mesh mb)))   ; (Lille's has jade / grey)
(defweapon :br-line-jade-hi (:length 1.0) (:solid :ink 0 (mbc mb #xB4DCC4) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))
(defweapon :br-line-gold-hi (:length 1.0) (:solid :ink 0 (mbc mb #xEAD9A4) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))

(defmacro %br-floor (kind x0 z0 ux uz s0 s1 w)
  "A flat line on the floor along the unit (UX UZ), from S0 to S1 m past (X0 Z0), W wide: KIND 0 jade, 1 the owl's gold,
2 / 3 their light tones, 4 grey. Nothing when S1 <= S0 (single-float forms through *BR-TV*: 0 B)."
  `(let ((%v *br-tv*))
     (declare (type f32vec %v))
     (setf (aref %v 0) ,x0 (aref %v 1) ,z0 (aref %v 2) ,ux (aref %v 3) ,uz (aref %v 4) ,s0 (aref %v 5) ,s1 (aref %v 6) ,w)
     (%br-floor* ,kind)))
(defun-fast %br-floor* (kind)
  (declare (fixnum kind))
  (let* ((m *lb-m*) (v *br-tv*) (ux (aref v 2)) (uz (aref v 3)) (s0 (aref v 4)) (len (- (aref v 5) s0)) (w (aref v 6)))
    (declare (type f32vec m v) (single-float ux uz s0 len w))
    (when (and (> len 0.01f0) (> w 0.001f0))
      (setf (aref m 0) (* w (- uz)) (aref m 1) 0f0 (aref m 2) (* w ux) (aref m 3) 0f0
            (aref m 4) (* len ux) (aref m 5) 0f0 (aref m 6) (* len uz) (aref m 7) 0f0
            (aref m 8) 0f0 (aref m 9) 0.006f0 (aref m 10) 0f0 (aref m 11) 0f0
            (aref m 12) (+ (aref v 0) (* s0 ux)) (aref m 13) 0.022f0 (aref m 14) (+ (aref v 1) (* s0 uz)) (aref m 15) 1f0)
      (setf (aref *toon-body* 1) 0f0)
      (case kind (0 (draw-weapon :lb-line-jade m)) (1 (draw-weapon :lb-line-gold m)) (2 (draw-weapon :br-line-jade-hi m))
            (3 (draw-weapon :br-line-gold-hi m)) (t (draw-weapon :lb-line-grey m))))
    nil))

(defmacro %br-sigil (gold x z r spin)
  "The sigil (BR-SIGIL-MESH) flat on the floor at (X Z), radius R, its chevron along the yaw SPIN + pi (jade, GOLD the owl's)."
  `(let ((%v *br-tv*))
     (declare (type f32vec %v))
     (setf (aref %v 8) ,x (aref %v 9) ,z (aref %v 10) ,r (aref %v 11) ,spin)
     (%br-sigil* ,gold)))
(defun-fast %br-sigil* (gold)
  (let* ((m *lb-m*) (v *br-tv*) (r (aref v 10)) (spin (aref v 11)) (c (f-cos spin)) (s (f-sin spin)))
    (declare (type f32vec m v) (single-float r spin c s))
    (setf (aref m 0) (* r c) (aref m 1) 0f0 (aref m 2) (* r (- s)) (aref m 3) 0f0
          (aref m 4) 0f0 (aref m 5) r (aref m 6) 0f0 (aref m 7) 0f0
          (aref m 8) (* r s) (aref m 9) 0f0 (aref m 10) (* r c) (aref m 11) 0f0
          (aref m 12) (aref v 8) (aref m 13) 0.034f0 (aref m 14) (aref v 9) (aref m 15) 1f0)
    (setf (aref *toon-body* 1) 0f0)
    (if gold (draw-weapon :br-sigil-gold m) (draw-weapon :br-sigil-jade m))
    nil))
(defmacro %br-eye (gold x z r spin)
  "Lille's eye mark (the reticle) flat at (X Z), radius R, turned SPIN: jade, GOLD the owl's (through *LB-V*, %LB-RETICLE's)."
  `(if ,gold
       (let ((%v *lb-v*))
         (declare (type f32vec %v))
         (setf (aref %v 17) ,x (aref %v 18) ,z (aref %v 19) ,r (aref %v 20) ,spin)
         (%br-eye-gold*))
       (%lb-reticle t ,x ,z ,r ,spin)))
(defun-fast %br-eye-gold* ()
  (let* ((m *lb-m*) (v *lb-v*) (r (aref v 19)) (spin (aref v 20)) (c (f-cos spin)) (s (f-sin spin)))
    (declare (type f32vec m v) (single-float r spin c s))
    (setf (aref m 0) (* r c) (aref m 1) 0f0 (aref m 2) (* r (- s)) (aref m 3) 0f0
          (aref m 4) 0f0 (aref m 5) r (aref m 6) 0f0 (aref m 7) 0f0
          (aref m 8) (* r s) (aref m 9) 0f0 (aref m 10) (* r c) (aref m 11) 0f0
          (aref m 12) (aref v 17) (aref m 13) 0.03f0 (aref m 14) (aref v 18) (aref m 15) 1f0)
    (setf (aref *toon-body* 1) 0f0)
    (draw-weapon :br-reticle-gold m)
    nil))

(defmacro %br-place! (e opp side)
  "*BR-AT* [8 SIDE ..] = E's and OPP's x z, read in a DO-ENTITIES pass over the transforms (a component getter conses
8 B in this build; the pass does not)."
  `(let ((%at *br-at*) (%o (* 8 ,side)) (%e ,e) (%q ,opp))
     (declare (type f32vec %at) (fixnum %o))
     (do-entities (%h (%tr transform))
       (cond ((eql %h %e) (let ((%p (transform-pos %tr)))
                            (declare (type f32vec %p))
                            (setf (aref %at %o) (aref %p 0) (aref %at (+ %o 1)) (aref %p 2) (aref %at (+ %o 4)) 1f0)))
             ((eql %h %q) (let ((%p (transform-pos %tr)))
                            (declare (type f32vec %p))
                            (setf (aref %at (+ %o 2)) (aref %p 0) (aref %at (+ %o 3)) (aref %p 2))))))))

(defun-fast %br-live-look (hz d side gold)
  "A live trace (decision V7): the sigil on its point, its line through him in value steps (§17), the running dash, SP2's
lane edges, and the set's flare over its first 14 frames (the hazard's age: sim frames, held in a hitstop)."
  (declare (fixnum side))
  (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
         (thick (eq (brh-src d) :sp2)) (at *br-at*) (o (* 8 side))
         (sl (if (> (aref at (+ o 4)) 0.5f0) (f-max 0f0 (+ (* (- (aref at o) x) ux) (* (- (aref at (+ o 1)) z) uz))) 0.5f0))
         (end (f-min (the single-float (f32 *br-trace-len*)) (%lb-wall x z ux uz)))
         (age (hazard-age hz)) (af (i->f age)) (tm (fx-clock)) (sd (i->f (mod (brh-id d) 9)))
         (r (if thick 0.7f0 0.42f0)) (w (if thick 0.11f0 0.042f0)) (sa (* 1.62f0 r))
         (grow (f-min end (+ sa (* 7.5f0 (+ af 1f0)))))     ; (the set: the line drawn out to its end in 4 frames)
         (k0 (if gold 1 0)) (k1 (if gold 3 2)) (pal (if gold +pal-gold+ +pal-jade+))
         (u8 (f-min 1f0 (/ af 8f0))) (rs (* r (+ 1f0 (* 0.5f0 (- 1f0 u8) (- 1f0 u8))))))
    (declare (type f32vec at) (fixnum o age k0 k1)
             (single-float x z yaw ux uz sl end af tm sd r w sa grow pal u8 rs))
    ;; the sigil, the eye mark turning inside it (SP2's: a second ring at its lane's width)
    (%br-sigil gold x z rs (+ yaw 3.1415927f0))
    (%br-eye gold x z (* 0.58f0 rs) (+ (* 0.9f0 tm) (* 0.7f0 sd)))
    (when thick (%tring x 0f0 z (the single-float (f32 *br-trace-r-thick*)) 0.025f0 pal 0.75f0 (+ 3f0 sd) 32))
    ;; the line: dim to him, the light tone round him, then thinning to its end
    (let ((b0 (f-max sa (- sl 2.5f0))) (b1 (+ sl 3.5f0)))
      (declare (single-float b0 b1))
      (%br-floor k0 x z ux uz sa (f-min grow b0) (* 0.8f0 w))
      (%br-floor k1 x z ux uz b0 (f-min grow b1) (* 1.35f0 w))
      (%br-floor k0 x z ux uz b1 (f-min grow (+ sl 12f0)) w)
      (%br-floor k0 x z ux uz (+ sl 12f0) (f-min grow (+ sl 20f0)) (* 0.6f0 w))
      (%br-floor k0 x z ux uz (+ sl 20f0) grow (* 0.35f0 w)))
    (when thick                                          ; SP2's lane: its 1.2 m edges either side
      (let ((hw (the single-float (f32 *br-trace-r-thick*))))
        (declare (single-float hw))
        (dotimes (i 2)
          (let* ((sg (if (= i 0) -1f0 1f0)) (ex (+ x (* sg hw (- uz)))) (ez (+ z (* sg hw ux))))
            (declare (single-float sg ex ez))
            (%br-floor k0 ex ez ux uz sa (f-min grow (%lb-wall ex ez ux uz)) 0.024f0)))))
    ;; the dash running from the point through him and on (once a 3.8 s lap; its own phase per trace)
    (let* ((sp (+ sa (f-mod (+ (* 9f0 tm) (* 3.7f0 sd)) 34f0))) (tl (f-max sa (- sp 1.6f0)))
           (fade (if (<= sp sl) 1f0 (f-clamp (- 1f0 (/ (- sp sl) (f-max 1f0 (- end sl)))) 0f0 1f0))))
      (declare (single-float sp tl fade))
      (when (and (< sp grow) (> fade 0.05f0) (>= af 14f0))
        (toon-ribbon ((+ x (* tl ux)) 0.07f0 (+ z (* tl uz))) ((* (- sp tl) ux) 0f0 (* (- sp tl) uz))
                     (0f0 (* (if thick 2.2f0 1f0) 0.05f0)) :heat (0.6f0 1f0) :seed (- -91f0 sd) :wob 0.02f0 :pal pal
                     :k (* 0.5f0 fade) :k1 (* 0.95f0 fade) :segs 2)))
    ;; the set: a white flash and a ring at the point, a star, the line's head running out to its end
    (when (< af 14f0)
      (fx-envelope (sc kk fl ph) ((/ af 60f0) 1 3 2 8)
        (let ((u (/ af 14f0)))
          (declare (single-float u))
          (when (> fl 0f0) (fx-disc x 0.2f0 z (* 1.4f0 r) 0.04f0 (+ 81f0 sd) +pal-hit+ 0.95f0 :push 0.3f0))
          (%tring x 0f0 z (* r (+ 1.2f0 (* 2.6f0 u))) 0.05f0 pal kk (+ 82f0 sd) 32)
          (fx-star x 0.3f0 z (* 0.05f0 sc) (* (if thick 0.9f0 0.6f0) sc) 8 (* 0.4f0 sd) 0f0 0f0 0.1f0 (+ 83f0 sd) +pal-hit+ kk
                   :push 0.3f0)
          (when (< grow end)
            (let ((tl (f-max sa (- grow 3f0))))
              (declare (single-float tl))
              (toon-ribbon ((+ x (* tl ux)) 0.08f0 (+ z (* tl uz))) ((* (- grow tl) ux) 0f0 (* (- grow tl) uz))
                           (0f0 0.07f0) :heat (0.7f0 1f0) :seed (- -84f0 sd) :wob 0.02f0 :pal +pal-hit+ :k 0.6f0 :k1 0.95f0 :segs 2)
              (fx-star (+ x (* grow ux)) 0.1f0 (+ z (* grow uz)) 0.03f0 0.2f0 6 sd 0f0 0f0 0.1f0 (+ 85f0 sd) pal 0.9f0
                       :push 0.2f0))))))
    ;; noted for the recall's look (BR-DRAW)
    (let* ((s *br-seen*) (o2 (* 65 side)) (n (f->i (aref s o2))))
      (declare (type f32vec s) (fixnum o2 n))
      (when (< n 16)
        (let ((q (+ o2 1 (* 4 n))))
          (declare (fixnum q))
          (setf (aref s q) x (aref s (+ q 1)) z (aref s (+ q 2)) yaw (aref s (+ q 3)) (if thick 1f0 0f0)
                (aref s o2) (i->f (1+ n)))))))
  nil)

(defun-fast %br-fired-note (hz d side gold)
  "A materialised trace's 3 frames (its hit window): kept in *BR-SHOT* (its point, line, his place on it and the opponent's
then; connected once its hit is spent) for BR-DRAW's fired look (%BR-FIRED-LOOK), which outlives the hazard."
  (declare (fixnum side))
  (let* ((v *br-shot*) (o (* 48 side)) (id (i->f (brh-id d))) (tm (fx-clock)) (slot -1) (old o) (ot 1f30))
    (declare (type f32vec v) (fixnum o slot old) (single-float id tm ot))
    (dotimes (i 4)
      (let ((q (+ o (* 12 i))))
        (declare (fixnum q))
        (if (and (= (aref v q) id) (< (- tm (aref v (+ q 11))) 0.25f0))
            (setf slot q)
            (when (< (aref v (+ q 1)) ot) (setf ot (aref v (+ q 1)) old q)))))
    (when (< slot 0)
      (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
             (at *br-at*) (oa (* 8 side)))
        (declare (single-float x z yaw ux uz) (type f32vec at) (fixnum oa))
        (setf slot old
              (aref v slot) id (aref v (+ slot 1)) tm (aref v (+ slot 2)) x (aref v (+ slot 3)) z (aref v (+ slot 4)) yaw
              (aref v (+ slot 5)) (if (eq (brh-src d) :sp2) 1f0 0f0) (aref v (+ slot 6)) 0f0
              (aref v (+ slot 7)) (f-max 0f0 (+ (* (- (aref at oa) x) ux) (* (- (aref at (+ oa 1)) z) uz)))
              (aref v (+ slot 8)) (aref at (+ oa 2)) (aref v (+ slot 9)) (aref at (+ oa 3)) (aref v (+ slot 10)) (if gold 1f0 0f0))))
    (when (<= (hazard-hits-left hz) 0) (setf (aref v (+ slot 6)) 1f0))
    (setf (aref v (+ slot 11)) tm))
  nil)

(defun-fast %br-fired-look (side)
  "SIDE's fired traces (*BR-SHOT*, the fx clock): a light head running the line from the point through him to its end over
*BR-FIRE-F* frames (at the shot's height, 1.2 m), the spent line flashing on the floor, the sigil bursting at the point, a
star where it passed through him; a miss (its hazard gone, its hit unspent): a grey puff and two ink streaks where the line
passed him by and a dashed ink gap from there to him. Over *BR-FIRE-LIFE* s. 0 B."
  (declare (fixnum side))
  (let* ((v *br-shot*) (o (* 48 side)) (tm (fx-clock)) (life (the single-float (f32 *br-fire-life*)))
         (ff (i->f (the fixnum *br-fire-f*))))
    (declare (type f32vec v) (fixnum o) (single-float tm life ff))
    (dotimes (i 4)
      (let* ((q (+ o (* 12 i))) (age (- tm (aref v (+ q 1)))))
        (declare (fixnum q) (single-float age))
        (when (and (> (aref v q) 0.5f0) (>= age 0f0) (< age life))
          (let* ((x (aref v (+ q 2))) (z (aref v (+ q 3))) (yaw (aref v (+ q 4))) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
                 (thick (> (aref v (+ q 5)) 0.5f0)) (gold (> (aref v (+ q 10)) 0.5f0)) (sl (aref v (+ q 7)))
                 (pal (if gold +pal-gold+ +pal-jade+)) (end (f-min (the single-float (f32 *br-trace-len*)) (%lb-wall x z ux uz)))
                 (a (* 60f0 age)) (k (- 1f0 (/ age life))) (r (if thick 0.7f0 0.42f0)) (sd (+ (i->f i) (* 4f0 (i->f side)))))
            (declare (single-float x z yaw ux uz sl pal end a k r sd))
            (when (< a (+ ff 2f0))                    ; the head: from the point, through him, on to the end
              (let* ((hp (f-min 1f0 (/ (+ a 1f0) ff))) (sh (+ 0.6f0 (* hp (- end 0.6f0)))) (st (f-max 0.6f0 (- sh 7f0)))
                     (fd (if (< a ff) 1f0 (- 1f0 (* 0.5f0 (- a ff))))) (hw (if thick 0.32f0 0.1f0)))
                (declare (single-float hp sh st fd hw))
                (toon-ribbon ((+ x (* st ux)) 1.2f0 (+ z (* st uz))) ((* (- sh st) ux) 0f0 (* (- sh st) uz)) ((* 0.2f0 hw) hw)
                             :heat (0.7f0 1f0) :seed (- -101f0 sd) :wob 0.02f0 :pal pal :k (* 0.6f0 fd) :k1 (* 0.98f0 fd) :segs 3)
                (toon-ribbon ((+ x (* st ux)) 1.2f0 (+ z (* st uz))) ((* (- sh st) ux) 0f0 (* (- sh st) uz)) (0f0 (* 0.4f0 hw))
                             :heat (1f0 1f0) :seed (- -102f0 sd) :wob 0f0 :pal +pal-hit+ :k (* 0.5f0 fd) :k1 (* 0.95f0 fd) :segs 2)
                (when (< a ff)
                  (fx-star (+ x (* sh ux)) 1.2f0 (+ z (* sh uz)) 0.05f0 (if thick 0.6f0 0.32f0) 6 (* 0.5f0 a) 0f0 0f0 0.1f0
                           (+ 103f0 sd) +pal-hit+ 0.95f0 :push 0.3f0))
                (when (and (>= a 1f0) (< a 6f0) (> sl 0.6f0))   ; through him
                  (fx-star (+ x (* sl ux)) 1.2f0 (+ z (* sl uz)) 0.06f0 (* 0.4f0 (- 1f0 (/ a 6f0))) 8 1.1f0 0f0 0f0 0.1f0
                           (+ 104f0 sd) pal 0.9f0 :push 0.35f0))))
            (when (< a 14f0)                          ; the spent line flashes on the floor, the sigil bursts
              (let ((u (/ a 14f0)))
                (declare (single-float u))
                (%br-floor (if gold 3 2) x z ux uz 0.6f0 end (* (if thick 0.42f0 0.16f0) (- 1f0 u)))
                (%tring x 0f0 z (* r (+ 1f0 (* 3f0 u))) 0.06f0 pal (- 1f0 u) (+ 105f0 sd) 32)
                (when (< a 4f0)
                  (fx-star x 0.3f0 z 0.06f0 (* (if thick 1f0 0.7f0) (- 1f0 (* 0.25f0 a))) 8 sd 0f0 0f0 0.12f0 (+ 106f0 sd)
                           +pal-hit+ 0.95f0 :push 0.3f0))))
            (when (and (< (aref v (+ q 6)) 0.5f0) (> (- tm (aref v (+ q 11))) 0.03f0))   ; a miss: the line passed him by
              (let* ((qx (aref v (+ q 8))) (qz (aref v (+ q 9)))
                     (s (f-clamp (+ (* (- qx x) ux) (* (- qz z) uz)) 0.6f0 end))
                     (mx (+ x (* s ux))) (mz (+ z (* s uz))) (gx (- qx mx)) (gz (- qz mz)) (gl (f-max 0.01f0 (f-hypot gx gz)))
                     (km (* k k)))
                (declare (single-float qx qz s mx mz gx gz gl km))
                (fx-disc mx 1.2f0 mz (* 0.26f0 (+ 1f0 (* 0.8f0 (- 1f0 k)))) 0.18f0 (+ 107f0 sd) +pal-smoke+ (* 0.7f0 km) :push 0.3f0)
                (dotimes (j 2)
                  (let ((sg (if (= j 0) -1f0 1f0)))
                    (declare (single-float sg))
                    (fx-shard (+ mx (* 0.35f0 (+ 0.3f0 (- 1f0 k)) ux) (* sg 0.12f0 uz)) (+ 1.2f0 (* sg 0.1f0))
                              (+ mz (* 0.35f0 (+ 0.3f0 (- 1f0 k)) uz) (* sg -0.12f0 ux)) ux 0f0 uz 0.6f0 0.05f0 0.05f0
                              (+ 108f0 (i->f j) sd) +pal-ink+ km :push 0.2f0)))
                (when (> gl 0.5f0)                    ; the gap it missed him by: three ink dashes to him
                  (dotimes (j 3)
                    (let* ((f0 (+ 0.12f0 (* 0.3f0 (i->f j)))) (f1 (+ f0 0.16f0)))
                      (declare (single-float f0 f1))
                      (toon-ribbon ((+ mx (* f0 gx)) 1.2f0 (+ mz (* f0 gz))) ((* (- f1 f0) gx) 0f0 (* (- f1 f0) gz)) (0.045f0 0.045f0)
                                   :heat (0.7f0 0.7f0) :seed (- -109f0 sd (i->f j)) :wob 0f0 :pal +pal-ink+ :k (* 0.85f0 km)
                                   :segs 1))))))))))
    nil))

(defun-fast br-trace-look (hz rdt)
  "A trace's look (HAZARD-DRAW; decision V7, §17): live, its sigil and line through him (%BR-LIVE-LOOK; noted in *BR-SEEN*
for the recall's look); materialised, its 3 frames noted for the fired look (%BR-FIRED-NOTE; BR-DRAW draws it, with
LB-LOOK's shot / beam / judgement the sim spawns). Gold while he is the owl (LILLE-DRAW's flag, no lookup). 0 B."
  (declare (single-float rdt))
  (setf rdt 0f0)                                        ; (unused: HAZARD-DRAW's signature)
  (let ((d (hazard-data hz)))
    (when (brh-p d)
      (let* ((side (if (eql (hazard-owner hz) *p1*) 0 1)) (gold (> (lb-fxs side 15) 0.5f0)))
        (declare (fixnum side))
        (if (brh-live d) (%br-live-look hz d side gold) (%br-fired-note hz d side gold)))))
  nil)

(defun-fast %br-hinge (side)
  "Where his lines cross (§17): while he has live traces (last frame's count, *BR-SEEN*), a thin ring on the floor under
him (jade, the owl's gold): the hinge they all turn on. 0 B."
  (declare (fixnum side))
  (let ((at *br-at*) (o (* 8 side)))
    (declare (type f32vec at) (fixnum o))
    (when (and (> (aref *br-seen* (* 65 side)) 0.5f0) (> (aref at (+ o 4)) 0.5f0))
      (let ((x (aref at o)) (z (aref at (+ o 1))) (pal (if (> (lb-fxs side 15) 0.5f0) +pal-gold+ +pal-jade+)))
        (declare (single-float x z pal))
        (%tring x 0f0 z 0.62f0 0.022f0 pal 0.8f0 (+ 7f0 (i->f side)) 32))))
  nil)

(defun-fast br-draw (e rdt)
  "His kit's :draw hook: Lille's (LILLE-DRAW: his forms carry Lille's form names, so the wings, the halos, the legs and the
cinematics' drives come out the same; his recall strings drive its SP looks through BR-RC-DRIVE), then the stance's aim
line (%BR-AIM-LOOK); awakened, his place and the opponent's for his traces' looks (%BR-PLACE!), the hinge ring under him
(%BR-HINGE) and his fired traces (%BR-FIRED-LOOK, §17); the recall's traces flying back (%BR-RECALL-LOOK: *BR-SEEN* kept as
*BR-FLY* while he is not recalling) and each string beat's lines from the wing tips (%BR-BEAT-LOOK)."
  (declare (single-float rdt))
  (lille-draw e rdt)
  (let* ((f (fighter e)) (side (fighter-side f)) (mv (and (eq (fighter-state f) :move) (fighter-move f)))
         (c (if mv (%br-chain-clock (mv-name mv) (fighter-sf f)) -1)) (s *br-seen*) (o (* 65 side)))
    (declare (fixnum side c o) (type f32vec s))
    (if (eq (fighter-form f) :base)
        (%br-aim-look e f side)
        (progn (%br-place! e (fighter-opp f) side)        ; (his place for his traces' looks, drawn after him: §17)
               (%br-hinge side)
               (%br-fired-look side)))
    (if (< c 0)
        (let ((d *br-fly*)) (declare (type f32vec d)) (dotimes (i 65) (setf (aref d (+ o i)) (aref s (+ o i)))))   ; (his traces as last seen)
        (let ((jm (model-joints (model e))))
          (when (<= c 16) (%br-recall-look e jm side c))
          (when (not (eq (mv-name mv) :br-recall)) (%br-beat-look e f jm side mv))))
    (setf (aref s o) 0f0)
    (when (and (>= *br-art-hold* 0) (>= (the fixnum (br-hold-clock f)) *br-art-hold*))   ; (debug stills)
      (setf *br-art-hold* -1)
      (hitstop 100000)))
  nil)

(defun br-draw-sealed-p (e)
  "LILLE-DRAW's owl look for him (his own state, no LBS): Trompete reflected, SP2 sealed (the broken halo, the reflect)."
  (let ((st (brs e))) (and st (brs-sealed st) t)))

;;; ---------------------------------------------------------------- the art stills (debug 82100-82399, DUEL_GAMEPLAY)
(defun br-art-scene (k)
  "82100+k: Lille II (P1; k + 20: P2, facing the behind camera: the front view) 4 m from an idle Kenpachi, Reiatsu and flash
step full: k 0-3 JILLIEL melee with 0 / 2 / 4 / 6 traces laid from behind him, the recall started (its string by the
count: 空收 / 二連 / 四連 / 裁き); 4-7 the same as the owl (melee); 8 / 9 JILLIEL's melee -> ranged turn / J3 -> L backstep;
10 / 11 the owl's; 12 the owl's Trompete (the trumpet forming); 13 82007's reflected Trompete (P1 only: the reflect and
the broken halo from its f59); 14 JILLIEL melee's SANREN (the wings' kick, Lille's SP look). The aim points' looks (§17):
15 JILLIEL ranged 6 m out with a thick SP2 point (3 m behind, -35 deg) and an L point (2.5 m, +30 deg), then the L lay
started (its point set on f4: the set's flare); 16 the owl's (82016's three points, then its lay; P1 only); 17 JILLIEL
melee 3 m out with one L point 4 m behind, 50 deg off (its line ~2.3 m beside him), J1 started (a whiff: the trace picked
and missed); 18 the same with a thick SP2 point 12 deg off (its 1.2 m lane on him: J1 whiffs, the line hits); 19 17 as
the owl (P1 only)."
  (let* ((front (>= k 20)) (k (mod k 20)) (owl (or (<= 4 k 7) (<= 10 k 13))))
    (when (and (not front) (member k '(16 19)))         ; (the owl's: 82016 sets him up, its revival's clearing off)
      (barro-test 16)
      (if (= k 16)
          (start-move *p1* (find-move :br-oe-lay))
          (progn (force-form *p1* :shin-kin) (place *p1* *p2* 3.0) (br-clear-traces *p1*)
                 (multiple-value-bind (x z) (br-art-behind *p1* *p2* 4.0 50.0) (br-art-point *p1* :l x z))
                 (start-move *p1* (find-move :br-o-j1))))
      (setf *br-art-hold* *br-art-hold-next* *br-art-hold-next* -1)
      (return-from br-art-scene nil))
    (if front (ensure-battle :kenpachi :barro) (ensure-battle :barro :kenpachi))
    (let* ((b (if front *p2* *p1*)) (o (if front *p1* *p2*)) (g (gauges b)))
      (force-form b (cond ((= k 15) :jilliel) (owl :shin-kin) (t :jilliel-kin)))
      (place *p1* *p2* (case k (15 6.0) ((17 18) 3.0) (t 4.0)))
      (setf (gauges-reiatsu g) *reiatsu-max* (gauges-fs g) (f32 *fs-max*)
            (gauges-reishi (gauges o)) (gauges-reishi-max (gauges o)))   ; (no K.O. across a script's scenes)
      (case k
        ((0 1 2 3 4 5 6 7)
         (let* ((n (nth (mod k 4) '(0 2 4 6))) (p (pos-of b)) (q (pos-of o)) (x0 (aref p 0)) (z0 (aref p 2)) (yaw0 (yaw-of b))
                (dx (- (aref q 0) x0)) (dz (- (aref q 2) z0)) (l (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (ux (/ dx l)) (uz (/ dz l)))
           (dotimes (i n)                               ; laid from behind him, spread across, each aimed at him
             (let* ((lat (* 1.7 (- i (* 0.5 (1- n))))) (back (+ 1.2 (* 0.9 (mod i 2))))
                    (x (+ x0 (* -1 back ux) (* lat (- uz)))) (z (+ z0 (* -1 back uz) (* lat ux))))
               (v3-set! p (f32 x) 0f0 (f32 z))
               (setf (transform-yaw (transform b)) (f32 (atan (- (- (aref q 0) x)) (- (- (aref q 2) z)))))
               (br-lay-trace b :l 0.0)))
           (v3-set! p (f32 x0) 0f0 (f32 z0)) (setf (transform-yaw (transform b)) yaw0)
           (let ((s *br-fly*) (o (* 65 (fighter-side (fighter b)))) (i 0))   ; (as a drawn frame would have noted them:
             (do-entities (h (hz hazard))                                     ;  the recall takes them back on its f0)
               (when (and (eql (hazard-owner hz) b) (eq (hazard-look hz) 'br-trace-look) (< i 16))
                 (let ((q (+ o 1 (* 4 i))))
                   (setf (aref s q) (hazard-x hz) (aref s (+ q 1)) (hazard-z hz) (aref s (+ q 2)) (hazard-yaw hz)
                         (aref s (+ q 3)) 0f0))
                 (incf i)))
             (setf (aref s o) (f32 i)))
           (start-move b (find-move :br-recall))))
        ((8 10) (start-move b (find-move :br-to-en)))
        ((9 11) (start-move b (find-move :br-backstep)))
        (12 (start-move b (find-move :br-trompete)))
        (13 (barro-test 7))
        (14 (start-move b (find-move :br-w-sanren)))                          ; (82007: Trompete reflected by P2's guard on f54: sealed at f59)
        (15 (multiple-value-bind (x z) (br-art-behind b o 3.0 -35.0) (br-art-point b :sp2 x z))
            (multiple-value-bind (x z) (br-art-behind b o 2.5 30.0) (br-art-point b :l x z))
            (start-move b (find-move :br-e-lay)))
        ((17 18) (multiple-value-bind (x z) (br-art-behind b o 4.0 (if (= k 17) 50.0 12.0))
                   (br-art-point b (if (= k 17) :l :sp2) x z))
                 (start-move b (find-move :br-w-j1))))
      (setf *br-art-hold* *br-art-hold-next* *br-art-hold-next* -1))))

(defun br-art-behind (b o dist deg)
  "The scenes' place DIST m behind B, DEG degrees off his line to O (+ = toward his right): values x z."
  (let* ((p (pos-of b)) (q (pos-of o)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (l (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (fx (/ dx l)) (fz (/ dz l)) (a (* deg (/ pi 180))) (c (cos a)) (s (sin a)))
    (values (- (aref p 0) (* dist (- (* c fx) (* s fz)))) (- (aref p 2) (* dist (+ (* c fz) (* s fx)))))))

(defun br-art-point (b src px pz)
  "A scene's aim point of SRC at (PX PZ), its line through B (BR-LAY-TRACE with him stood 0.5 m past it, facing away)."
  (let* ((p (pos-of b)) (x0 (aref p 0)) (z0 (aref p 2)) (yaw0 (yaw-of b))
         (dx (- x0 px)) (dz (- z0 pz)) (l (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (ux (/ dx l)) (uz (/ dz l)))
    (v3-set! p (f32 (+ px (* 0.5 ux))) 0f0 (f32 (+ pz (* 0.5 uz))))
    (setf (transform-yaw (transform b)) (f32 (atan (- ux) (- uz))))
    (br-lay-trace b src 0.0)
    (v3-set! p (f32 x0) 0f0 (f32 z0))
    (setf (transform-yaw (transform b)) yaw0)))

(defun br-art-cine (f)
  "82300+k: his awakening (Lille's lb-jilliel-cine, his caption) with P1 Lille II 6 m from Kenpachi, held at frame 10 k."
  (unless (and *cine* (eq (cine-name *cine*) 'lb-jilliel-cine))
    (abort-cine) (setf *cine-hold* nil)
    (ensure-battle :barro :kenpachi) (place *p1* *p2* 6.0) (force-form *p1* :jilliel-kin)
    (start-cine 'lb-jilliel-cine *p1* *p2*))
  (when *cine* (setf *cine-hold* t (cine-hold *cine*) f)))

(defun barro-art-debug (c)
  "His art stills (barro.lisp registers 82100-82399 ahead of BARRO-DEBUG): 82100+k BR-ART-SCENE k (k 0-19, + 20 the front
view); 82200+f the sim freezes once his look clock reaches f (the recall chain's: the recall's frame, 7 + its string's;
else the move's frame; issue it before the scene), 82299 lets go; 82300+k his awakening held at frame 10 k (BR-ART-CINE)."
  (let ((n (- c 82100)))
    (cond ((< n 100) (br-art-scene n))
          ((< n 199) (setf *br-art-hold-next* (- n 100)))
          ((= n 199) (setf *br-art-hold* -1 *br-art-hold-next* -1 *hitstop* 0))
          ((< n 219) (br-art-cine (* 10 (- n 200))))
          ((= n 298) (br-cons-probe))
          (t (log-msg "duel barro: no debug command ~d" c)))))

(defun br-cons-probe ()
  "82398: bytes consed by 10 draws of P1 Lille II's :draw hook (BR-DRAW, LILLE-DRAW's lookups included), of his recall look
at its clock 4 (the traces flying back, *BR-FLY*) and of a string beat's lines (when a string runs), of his live traces'
looks (BR-TRACE-LOOK), and of §17's parts: his place (%BR-PLACE!), the hinge, a fired trace's look (a miss, faked in slot
0), in the running scene (a \"barro consing\" line)."
  (let* ((e *p1*) (f (fighter e)) (side (fighter-side f)) (jm (model-joints (model e)))
         (mv (and (eq (fighter-state f) :move) (fighter-move f))) (hz-n 0))
    (macrolet ((per (form) `(let ((c0 (cons-bytes))) (dotimes (i 10) ,form) (- (cons-bytes) c0))))
      (log-msg "barro consing (10 draws, B): form ~a clock ~d traces ~d draw ~d (Lille's ~d) recall ~d beat (lines drive beat) ~a looks ~d (~d hazards) place ~d hinge ~d fired ~d"
               (fighter-form f) (br-hold-clock f) (round (aref *br-fly* (* 65 side)))
               (per (br-draw e 0.016f0)) (per (lille-draw e 0.016f0)) (per (%br-recall-look e jm side 4))
               (if (and mv (member (mv-name mv) '(:br-rc0 :br-rc1 :br-rc2 :br-rc3)))
                   (list (per (%br-beat-look e f jm side mv)) (per (br-rc-drive f mv)) (per (br-rc-beat (mv-name mv) (fighter-sf f))))
                   -1)
               (let ((c0 (cons-bytes)))
                 (dotimes (i 10) (do-entities (h (hz hazard))
                                   (when (and (eql (hazard-owner hz) e) (eq (hazard-look hz) 'br-trace-look))
                                     (incf hz-n) (br-trace-look hz 0.016f0))))
                 (- (cons-bytes) c0))
               (floor hz-n 10)
               (per (%br-place! e (fighter-opp f) side)) (per (%br-hinge side))
               (let ((v *br-shot*) (q (* 48 side)) (tm (fx-clock)))   ; (a missed shot 0.1 s old in slot 0, then cleared)
                 (setf (aref v q) 999f0 (aref v (+ q 1)) (- tm 0.1f0) (aref v (+ q 2)) 0f0 (aref v (+ q 3)) 0f0 (aref v (+ q 4)) 0f0
                       (aref v (+ q 5)) 0f0 (aref v (+ q 6)) 0f0 (aref v (+ q 7)) 2f0 (aref v (+ q 8)) 1.5f0 (aref v (+ q 9)) -4f0
                       (aref v (+ q 10)) 0f0 (aref v (+ q 11)) (- tm 0.1f0))
                 (prog1 (per (%br-fired-look side)) (setf (aref v q) 0f0 (aref v (+ q 1)) -1f6)))))))

;;; ---------------------------------------------------------------- the HUD: the 狙擊 gauge (DUEL_LILLE_V2 §4)
(defparameter *br-sn-strings* #("SN 0" "SN 1" "SN 2" "SN 3") "The 狙擊 row's label: SN + the pips.")
(defparameter *br-tr-strings* (let ((v (make-array 17))) (dotimes (i 17 v) (setf (svref v i) (format nil "TR ~d" i))))
  "The awakened forms' label: TR + the live traces.")

(defun br-hud-label (g kit)
  "The portrait block's label: SN n (the 狙擊 pips) in the base form, TR n (the live traces) awakened."
  (let* ((e (lb-side-of g)) (st (brs e)))
    (if (eq (kit-form kit) :base)
        (svref *br-sn-strings* (if st (max 0 (min 3 (brs-snipe st))) 0))
        (svref *br-tr-strings* (if st (max 0 (min 16 (brs-live st))) 0)))))

(defun br-hud-meter (e kit x y w h right tm lx ly ls)
  "His kit-meter row (LX LY LS: the landscape label's place, NIL in the portrait slot): the base form's three 狙擊 pips
(Lille's reticle glyph: a filled pip the open jade eye, an empty one the shut white), SN n; awakened, TR n (his live traces)."
  (let* ((st (brs e)) (v *lb-hud*) (n (if st (brs-snipe st) 0)))
    (setf (aref v 3) (f32 tm) (aref v 4) (f32 x) (aref v 5) (f32 y) (aref v 6) (f32 w) (aref v 7) (f32 h))
    (when (eq (kit-form kit) :base)
      (let* ((step (/ w 3.0)) (r (min (* 0.36 step) (max 7.0 (* 2.4 h)))))
        (dotimes (i 3)
          (setf (aref v 0) (f32 (if right (- (+ x w) (* step (+ i 0.5))) (+ x (* step (+ i 0.5)))))
                (aref v 1) (f32 (+ y (* 0.5 h))) (aref v 2) (f32 r))
          (%lb-pip (if (< i n) 1 0)))))
    (when lx
      (hud-text (br-hud-label (gauges e) kit) lx ly ls *c-lb-jade* :align (if right :right :left)))))
