;;;; senjumaru-art.lisp — SHUTARA SENJUMARU as art data (docs/duel/DUEL_SENJUMARU.md §2, §10): her body (158 cm on tall okobo,
;;;; the anime head x1.3, a white haori over a white over-robe, long black hair, the gold crescent with rays; the rig's two
;;;; arms are the upper pair of her six gold bone arms, the sleeves hang empty from the shoulders), the Divine Soldier's
;;;; body (:shinpei), the needle 刺絡 (:shigarami) and the soldier's spear, the props (the echo arms' bones, the loom and
;;;; torii, the domain's drapes, the hank cloths, the carpet, the shears, the candles), every :sj-* pose and clip, the
;;;; hazards' looks, the Bankai's aura, her draw hook (the four echo arms, the red thread, the stitches on him, the
;;;; domain), her six sounds and her brush glyphs. Gold and madder are muted (S <= 0.45, not spot hues); BLOOD only in
;;;; thin threads (§12 M1).
(in-package :duel)

;;; ---------------------------------------------------------------- body
;; 158 cm (scale 0.88), slight (width 0.9), the okobo lift her 0.10 m (the pelvis raised over the rig's legs:
;; SJ-OKOBO-PROPS, the clogs fill the gap), the head x1.3 (the user's anime-head rule): ~1.68 m to the crown, ~1.95 m to
;; the crescent's top. The hurt cylinder r 0.36 / h 1.70 is a fairness floor (the crescent and the arms add none).
(defbody :senjumaru (:scale 0.88 :width 0.9 :hunch 0 :hurt-r 0.36 :hurt-h 1.7
                     :girth ((:chest 0.9 1.0 0.9) (:spine 0.84 1.0 0.86) (:pelvis 0.94 1.0 0.94) (:head 1.3 1.3 1.3))
                     :palette ((:white #xECECE8) (:black #x16161E) (:hair #x0C0C12) (:skin #xE2CCBC) (:gold #xB89A5A)
                               (:gold-l #xC2A866) (:madder #x7A2E34) (:fold #xD8DCE4) (:eye #xF2F0EC) (:pupil #x3A3440)
                               (:core #x16121C) (:lid #x141016) (:brow #x0C0C12) (:mouth #x8A4A48) (:lacquer #x1C1416)
                               (:tabi #xE8E8E4) (:shine #xFFFFFF) (:lining #xC8CAD2) (:clench #x141016))
                     :rim (#xFFE8C8 0.16))
  ;; the white over-robe, ankle-length, over the black shihakusho; a gold cord at the waist
  (:pelvis (:box 0.34 0.18 0.24 :c :white)
           (:box 0.35 0.025 0.25 :at (0 0.075 0) :c :gold)
           (:cyl 0.25 0.9 :top 0.18 :seg 10 :at (0 -0.42 0) :c :white)
           (:box 0.004 0.62 0.004 :at (0.07 -0.4 0.2) :rot (0 0 -3) :c :lining)
           (:box 0.004 0.55 0.004 :at (-0.1 -0.38 0.19) :rot (0 0 4) :c :lining))
  (:spine (:bevel 0.33 0.25 0.23 0.04 :at (0 0.11 0) :c :white))
  (:chest (:bevel 0.4 0.28 0.25 0.05 :at (0 0.11 0) :c :white)
          (:box 0.018 0.18 0.012 :at (0.034 0.18 0.13) :rot (0 0 -24) :c :black)     ; the shihakusho's black V
          (:box 0.018 0.18 0.012 :at (-0.034 0.18 0.13) :rot (0 0 24) :c :black)
          (:box 0.03 0.2 0.012 :at (0.06 0.17 0.132) :rot (0 0 -24) :c :white)       ; the haori's collar band
          (:box 0.03 0.2 0.012 :at (-0.06 0.17 0.132) :rot (0 0 24) :c :white)
          (:box 0.17 0.07 0.05 :at (0 0.262 -0.05) :rot (0 -8 0) :c :white)
          (:box 0.2 0.52 0.04 :at (0 -0.08 -0.15) :c :hair)                          ; the long hair down her back
          (:box 0.005 0.4 0.004 :at (0.05 -0.06 -0.172) :c :fold))
  (:neck (:cyl 0.034 0.17 :at (0 0.06 0) :c :skin))
  ;; the head (x1.3 by :girth): a small face, half-lidded eyes, a small closed mouth; the long straight black hair with
  ;; the side locks to the chest; the gold crescent with rays standing off the back of the skull
  (:head (:sphere 0.064 :stretch 0.02 :at (0 0.14 -0.012) :seg 12 :c :skin)
         (:bevel 0.104 0.07 0.076 0.02 :at (0 0.127 0.023) :c :skin)
         (:bevel 0.05 0.072 0.066 0.014 :at (0.021 0.08 0.024) :rot (0 0 -22) :c :skin)
         (:bevel 0.05 0.072 0.066 0.014 :at (-0.021 0.08 0.024) :rot (0 0 22) :c :skin)
         (:wedge 0.012 0.016 0.012 :at (0 0.097 0.064) :rot (180 0 0) :c :skin)
         ;; :face-neutral: half-lidded, level, serene
         (:box 0.028 0.012 0.003 :at (0.027 0.114 0.0615) :c :eye :tag :face-neutral)
         (:box 0.028 0.012 0.003 :at (-0.027 0.114 0.0615) :c :eye :tag :face-neutral)
         (:box 0.014 0.012 0.003 :at (0.024 0.113 0.0622) :c :pupil :tag :face-neutral)
         (:box 0.014 0.012 0.003 :at (-0.024 0.113 0.0622) :c :pupil :tag :face-neutral)
         (:box 0.036 0.009 0.003 :at (0.027 0.121 0.0638) :rot (0 0 -4) :c :lid :tag :face-neutral)   ; the heavy lids
         (:box 0.036 0.009 0.003 :at (-0.027 0.121 0.0638) :rot (0 0 4) :c :lid :tag :face-neutral)
         (:box 0.026 0.003 0.003 :at (0.028 0.145 0.0625) :rot (0 0 -4) :c :brow :tag :face-neutral)
         (:box 0.026 0.003 0.003 :at (-0.028 0.145 0.0625) :rot (0 0 4) :c :brow :tag :face-neutral)
         (:box 0.014 0.003 0.003 :at (0 0.07 0.0585) :c :mouth :tag :face-neutral)
         ;; :face-shout (never shouted: :calm): the small closed smile, eyes nearly closed
         (:box 0.03 0.004 0.003 :at (0.027 0.116 0.0638) :rot (0 0 8) :c :lid :tag :face-shout)
         (:box 0.03 0.004 0.003 :at (-0.027 0.116 0.0638) :rot (0 0 -8) :c :lid :tag :face-shout)
         (:box 0.026 0.003 0.003 :at (0.028 0.146 0.0625) :rot (0 0 -6) :c :brow :tag :face-shout)
         (:box 0.026 0.003 0.003 :at (-0.028 0.146 0.0625) :rot (0 0 6) :c :brow :tag :face-shout)
         (:box 0.008 0.003 0.003 :at (0.007 0.071 0.0585) :rot (0 0 16) :c :mouth :tag :face-shout)
         (:box 0.008 0.003 0.003 :at (-0.007 0.071 0.0585) :rot (0 0 -16) :c :mouth :tag :face-shout)
         ;; :face-hurt: the narrowed glare
         (:box 0.028 0.006 0.003 :at (0.027 0.116 0.0615) :c :eye :tag :face-hurt)
         (:box 0.028 0.006 0.003 :at (-0.027 0.116 0.0615) :c :eye :tag :face-hurt)
         (:box 0.01 0.006 0.003 :at (0.023 0.116 0.0622) :c :core :tag :face-hurt)
         (:box 0.01 0.006 0.003 :at (-0.023 0.116 0.0622) :c :core :tag :face-hurt)
         (:box 0.036 0.006 0.003 :at (0.027 0.121 0.0638) :rot (0 0 12) :c :lid :tag :face-hurt)
         (:box 0.036 0.006 0.003 :at (-0.027 0.121 0.0638) :rot (0 0 -12) :c :lid :tag :face-hurt)
         (:box 0.028 0.004 0.003 :at (0.028 0.139 0.0625) :rot (0 0 16) :c :brow :tag :face-hurt)
         (:box 0.028 0.004 0.003 :at (-0.028 0.139 0.0625) :rot (0 0 -16) :c :brow :tag :face-hurt)
         (:box 0.018 0.004 0.003 :at (0 0.069 0.0585) :c :clench :tag :face-hurt)
         ;; the hair: a cap, the straight fall behind, the side locks, a blunt fringe, three white highlight strokes
         (:sphere 0.074 :stretch 0.02 :at (0 0.15 -0.018) :seg 12 :c :hair)
         (:bevel 0.16 0.24 0.07 0.02 :at (0 0.06 -0.06) :c :hair)
         (:box 0.026 0.2 0.03 :at (0.062 0.04 0.02) :rot (0 0 -3) :c :hair)
         (:box 0.026 0.2 0.03 :at (-0.062 0.04 0.02) :rot (0 0 3) :c :hair)
         (:bevel 0.118 0.03 0.034 0.01 :at (0 0.172 0.05) :rot (0 -20 0) :c :hair)
         (:box 0.006 0.03 0.003 :at (-0.035 0.206 0.03) :rot (220 -36 0) :c :fold)
         (:box 0.006 0.026 0.003 :at (0.015 0.21 0.04) :rot (200 -40 0) :c :fold)
         (:box 0.006 0.05 0.003 :at (0.03 0.19 -0.08) :rot (30 -30 0) :c :fold)
         ;; the crescent: a gold arc behind the skull, horns up, with rays (it scales with the head): a halo
         (:box 0.07 0.03 0.014 :at (0 0.0 -0.15) :c :gold)
         (:box 0.07 0.03 0.014 :at (0.085 0.03 -0.15) :rot (0 0 24) :c :gold)
         (:box 0.07 0.03 0.014 :at (-0.085 0.03 -0.15) :rot (0 0 -24) :c :gold)
         (:box 0.066 0.028 0.014 :at (0.15 0.1 -0.15) :rot (0 0 52) :c :gold)
         (:box 0.066 0.028 0.014 :at (-0.15 0.1 -0.15) :rot (0 0 -52) :c :gold)
         (:box 0.06 0.024 0.014 :at (0.185 0.19 -0.15) :rot (0 0 76) :c :gold-l)
         (:box 0.06 0.024 0.014 :at (-0.185 0.19 -0.15) :rot (0 0 -76) :c :gold-l)
         (:cone 0.016 0.13 :at (0 -0.075 -0.15) :rot (0 0 180) :seg 4 :c :gold-l)     ; the rays, outward
         (:cone 0.014 0.12 :at (0.14 -0.03 -0.15) :rot (0 0 140) :seg 4 :c :gold-l)
         (:cone 0.014 0.12 :at (-0.14 -0.03 -0.15) :rot (0 0 -140) :seg 4 :c :gold-l)
         (:cone 0.012 0.1 :at (0.235 0.08 -0.15) :rot (0 0 112) :seg 4 :c :gold-l)
         (:cone 0.012 0.1 :at (-0.235 0.08 -0.15) :rot (0 0 -112) :seg 4 :c :gold-l))
  ;; the shoulders: the haori's; the empty sleeves hang from them (her own hands stay inside)
  (:shoulder-r (:bevel 0.12 0.06 0.18 0.02 :at (0.02 -0.02 0) :rot (0 0 -20) :c :white)
               (:box 0.15 0.46 0.2 :at (0.06 -0.26 0) :rot (0 0 -6) :c :white)
               (:box 0.13 0.015 0.17 :at (0.08 -0.49 0) :rot (0 0 -6) :c :black))
  (:shoulder-l (:bevel 0.12 0.06 0.18 0.02 :at (-0.02 -0.02 0) :rot (0 0 20) :c :white)
               (:box 0.15 0.46 0.2 :at (-0.06 -0.26 0) :rot (0 0 6) :c :white)
               (:box 0.13 0.015 0.17 :at (-0.08 -0.49 0) :rot (0 0 6) :c :black))
  ;; the upper pair of the six gold bone arms: a humerus, two forearm bones, the knuckled joints, a skeletal hand
  (:upper-arm-r (:sphere 0.036 :at (0 0 0) :c :gold-l) (:cyl 0.02 0.28 :top 0.016 :seg 6 :at (0 -0.15 0) :c :gold)
                (:sphere 0.03 :at (0 -0.3 0) :c :gold-l))
  (:upper-arm-l (:sphere 0.036 :at (0 0 0) :c :gold-l) (:cyl 0.02 0.28 :top 0.016 :seg 6 :at (0 -0.15 0) :c :gold)
                (:sphere 0.03 :at (0 -0.3 0) :c :gold-l))
  (:lower-arm-r (:cyl 0.012 0.26 :seg 5 :at (0.012 -0.13 0) :c :gold) (:cyl 0.011 0.26 :seg 5 :at (-0.012 -0.13 0.004) :c :gold))
  (:lower-arm-l (:cyl 0.012 0.26 :seg 5 :at (-0.012 -0.13 0) :c :gold) (:cyl 0.011 0.26 :seg 5 :at (0.012 -0.13 0.004) :c :gold))
  (:hand-r (:box 0.05 0.045 0.018 :at (0 -0.024 0) :c :gold-l)
           (:box 0.009 0.07 0.009 :at (0.018 -0.08 0) :c :gold) (:box 0.009 0.075 0.009 :at (0.006 -0.083 0) :c :gold)
           (:box 0.009 0.07 0.009 :at (-0.006 -0.08 0) :c :gold) (:box 0.009 0.06 0.009 :at (-0.018 -0.075 0) :c :gold)
           (:box 0.009 0.05 0.009 :at (0.03 -0.04 0.02) :rot (0 30 -20) :c :gold))
  (:hand-l (:box 0.05 0.045 0.018 :at (0 -0.024 0) :c :gold-l)
           (:box 0.009 0.07 0.009 :at (-0.018 -0.08 0) :c :gold) (:box 0.009 0.075 0.009 :at (-0.006 -0.083 0) :c :gold)
           (:box 0.009 0.07 0.009 :at (0.006 -0.08 0) :c :gold) (:box 0.009 0.06 0.009 :at (0.018 -0.075 0) :c :gold)
           (:box 0.009 0.05 0.009 :at (-0.03 -0.04 0.02) :rot (0 -30 20) :c :gold))
  ;; the legs under the over-robe (white: a leg through the robe reads as a fold), the tabi, the okobo
  (:thigh-r (:cyl 0.11 0.44 :top 0.1 :seg 10 :at (0 -0.21 0) :c :white))
  (:thigh-l (:cyl 0.11 0.44 :top 0.1 :seg 10 :at (0 -0.21 0) :c :white))
  (:shin-r (:cyl 0.12 0.34 :top 0.105 :seg 10 :at (0 -0.12 0) :c :white) (:box 0.07 0.12 0.08 :at (0 -0.38 0) :c :tabi))
  (:shin-l (:cyl 0.12 0.34 :top 0.105 :seg 10 :at (0 -0.12 0) :c :white) (:box 0.07 0.12 0.08 :at (0 -0.38 0) :c :tabi))
  (:foot-r (:bevel 0.08 0.05 0.19 0.02 :at (0 -0.03 0.05) :c :tabi)
           (:box 0.085 0.115 0.19 :at (0 -0.113 0.045) :c :lacquer) (:box 0.02 0.012 0.07 :at (0 -0.052 0.1) :c :madder))
  (:foot-l (:bevel 0.08 0.05 0.19 0.02 :at (0 -0.03 0.05) :c :tabi)
           (:box 0.085 0.115 0.19 :at (0 -0.113 0.045) :c :lacquer) (:box 0.02 0.012 0.07 :at (0 -0.052 0.1) :c :madder)))

(defun sj-okobo-props ()
  "Her rig proportions: the standard bones, the pelvis raised by the okobo (0.10 m world at scale 0.88), so the feet stand
on the clogs."
  (let ((v (make-rig-proportions :shoulders 1.04)))
    (setf (aref v (* 3 +nj+)) (f32 (+ 0.98 (/ 0.1 0.88))))
    v))
(setf (body-props (find-body :senjumaru)) (sj-okobo-props))

;; the Divine Soldier (神兵): 1.9 m, faceless, wrapped in cream cloth with madder bands (no hurt volume of its own: the
;; hazard's cylinder)
(defbody :shinpei (:scale 1.06 :width 1.1 :hunch 4 :hurt-r 0.4 :hurt-h 1.8
                   :palette ((:wrap #xD8D0C0) (:band #x7A2E34) (:ink #x16161E) (:gold #xB89A5A))
                   :rim (#xFFE8C8 0.1))
  (:pelvis (:box 0.34 0.2 0.25 :c :wrap) (:box 0.35 0.04 0.26 :at (0 0.02 0) :c :band)
           (:cyl 0.22 0.36 :top 0.17 :seg 8 :at (0 -0.18 0) :c :wrap))
  (:spine (:bevel 0.33 0.26 0.24 0.04 :at (0 0.11 0) :c :wrap) (:box 0.34 0.03 0.25 :at (0 0.06 0) :c :band))
  (:chest (:bevel 0.44 0.3 0.28 0.05 :at (0 0.11 0) :c :wrap) (:box 0.45 0.03 0.29 :at (0 0.14 0) :c :band)
          (:box 0.06 0.3 0.29 :at (0.08 0.1 0) :rot (0 0 -30) :c :band))
  (:neck (:cyl 0.05 0.14 :at (0 0.06 0) :c :wrap))
  (:head (:sphere 0.1 :stretch 0.04 :at (0 0.12 0) :seg 10 :c :wrap)                      ; faceless, wrapped
         (:box 0.1 0.012 0.02 :at (0 0.13 0.09) :c :ink)
         (:box 0.21 0.02 0.21 :at (0 0.08 0) :rot (0 0 8) :c :band))
  (:shoulder-r (:bevel 0.14 0.07 0.2 0.02 :at (0.03 -0.02 0) :c :wrap))
  (:shoulder-l (:bevel 0.14 0.07 0.2 0.02 :at (-0.03 -0.02 0) :c :wrap))
  (:upper-arm-r (:box 0.12 0.3 0.12 :at (0 -0.15 0) :c :wrap) (:box 0.125 0.03 0.125 :at (0 -0.2 0) :c :band))
  (:upper-arm-l (:box 0.12 0.3 0.12 :at (0 -0.15 0) :c :wrap) (:box 0.125 0.03 0.125 :at (0 -0.2 0) :c :band))
  (:lower-arm-r (:box 0.1 0.26 0.1 :at (0 -0.13 0) :c :wrap))
  (:lower-arm-l (:box 0.1 0.26 0.1 :at (0 -0.13 0) :c :wrap))
  (:hand-r (:bevel 0.06 0.08 0.06 0.015 :at (0 -0.04 0) :c :wrap))
  (:hand-l (:bevel 0.06 0.08 0.06 0.015 :at (0 -0.04 0) :c :wrap))
  (:thigh-r (:cyl 0.1 0.44 :top 0.085 :seg 8 :at (0 -0.21 0) :c :wrap))
  (:thigh-l (:cyl 0.1 0.44 :top 0.085 :seg 8 :at (0 -0.21 0) :c :wrap))
  (:shin-r (:cyl 0.08 0.42 :top 0.065 :seg 8 :at (0 -0.2 0) :c :wrap) (:box 0.09 0.03 0.09 :at (0 -0.1 0) :c :band))
  (:shin-l (:cyl 0.08 0.42 :top 0.065 :seg 8 :at (0 -0.2 0) :c :wrap) (:box 0.09 0.03 0.09 :at (0 -0.1 0) :c :band))
  (:foot-r (:bevel 0.09 0.06 0.2 0.02 :at (0 -0.03 0.05) :c :wrap))
  (:foot-l (:bevel 0.09 0.06 0.2 0.02 :at (0 -0.03 0.05) :c :wrap)))

;;; ---------------------------------------------------------------- the needle and the spear
;; 刺絡 SHIGARAMI: a white-gold sewing needle, 1.2 m (1.06 m at her scale; 1.8 m, as tall as she is, from the first reach
;; playtest until the second, 2026-09-29: J is light, short and fast, so the needle is two thirds of it and her J reach
;; its tip, close in), the eye just behind her fist (the red thread runs from it: SENJU-DRAW)
(defweapon :shigarami (:length 1.2 :base 0.1)
  (:solid (mbc mb #xEDE6D0)
          (with-xform (mb (xform :y 0.57)) (mb-cylinder mb 0.016 1.14 :segments 6 :top-radius 0.005))
          (with-xform (mb (xform :y 1.17)) (mb-cone mb 0.005 0.05 :segments 4))
          (mbc mb #xC2A866)
          (with-xform (mb (xform :y -0.03)) (mb-box mb 0.026 0.05 0.012))
          (mbc mb #x16161E)
          (with-xform (mb (xform :y -0.035)) (mb-box mb 0.012 0.03 0.014))))
(defweapon :sj-spear (:length 1.6)
  (:solid (mbc mb #x5A4034) (with-xform (mb (xform :y 0.4)) (mb-cylinder mb 0.022 1.9 :segments 6))
          (mbc mb #xB89A5A) (with-xform (mb (xform :y 1.4)) (mb-box mb 0.05 0.05 0.05))
          (mbc mb #xD8DCE4) (with-xform (mb (xform :y 1.55)) (mb-cone mb 0.04 0.26 :segments 4))))

;;; ---------------------------------------------------------------- props (drawn with DRAW-WEAPON at a world matrix)
(defun sj-pattern (mb n)
  "Hank N's pattern on a unit cloth (the XZ plane at y 0.006, radius 1): eyes, gold diamonds, a grey spiral, snowflakes,
ink trees, a white star."
  (case n
    (1 (dotimes (i 6) (let ((a (* i (/ pi 3))))            ; eyes
                        (mbc mb #xECECE8) (with-xform (mb (xform :x (* 0.6 (cos a)) :y 0.006 :z (* 0.6 (sin a)) :yaw (- a))) (mb-box mb 0.22 0.004 0.1))
                        (mbc mb #x16121C) (with-xform (mb (xform :x (* 0.6 (cos a)) :y 0.008 :z (* 0.6 (sin a)))) (mb-box mb 0.06 0.004 0.06)))))
    (2 (mbc mb #xD8C080) (dotimes (i 8) (let ((a (* i (/ pi 4))))
                                          (with-xform (mb (xform :x (* 0.6 (cos a)) :y 0.006 :z (* 0.6 (sin a)) :yaw 0.785)) (mb-box mb 0.14 0.004 0.14)))))
    (3 (mbc mb #x6A6E7A) (dotimes (i 14) (let* ((a (* i 0.7)) (r (+ 0.12 (* 0.06 i))))
                                           (with-xform (mb (xform :x (* r (cos a)) :y 0.006 :z (* r (sin a)) :yaw (- a))) (mb-box mb 0.05 0.004 0.2)))))
    (4 (mbc mb #xF2F4F8) (dotimes (i 5) (let ((a (* i (/ (* 2 pi) 5))))
                                          (with-xform (mb (xform :x (* 0.55 (cos a)) :y 0.006 :z (* 0.55 (sin a))))
                                            (mb-box mb 0.26 0.004 0.03) (with-xform (mb (xform :yaw 1.047)) (mb-box mb 0.26 0.004 0.03))
                                            (with-xform (mb (xform :yaw -1.047)) (mb-box mb 0.26 0.004 0.03))))))
    (5 (mbc mb #x16161E) (dotimes (i 4) (let ((a (+ 0.4 (* i (/ pi 2)))))
                                          (with-xform (mb (xform :x (* 0.55 (cos a)) :y 0.006 :z (* 0.55 (sin a)) :yaw (- a)))
                                            (mb-box mb 0.04 0.004 0.34) (with-xform (mb (xform :z 0.06 :yaw 0.6)) (mb-box mb 0.03 0.004 0.2))
                                            (with-xform (mb (xform :z -0.04 :yaw -0.6)) (mb-box mb 0.03 0.004 0.18))))))
    (6 (mbc mb #xF2F4F8) (dotimes (i 5) (let ((a (* i (/ (* 2 pi) 5))))
                                          (with-xform (mb (xform :x (* 0.14 (cos a)) :y 0.006 :z (* 0.14 (sin a)) :yaw (- (/ pi 2) a)))
                                            (mb-box mb 0.08 0.004 0.3)))))))

(defmacro def-hank-cloths ()
  "Per hank N: :sj-cloth-N (a unit cloth disc in its dye and pattern: the zones' floor, the unfold) and :sj-bolt-N (a
rolled bolt of it: the weave, the wrap, the hanging bolts). Also *SJ-CLOTH-KEYS* / *SJ-BOLT-KEYS*: those weapon keys
indexed by hank 1..6 (slot 0 unused), so the per-draw sites need no INTERN / FORMAT."
  `(progn
     (defparameter *sj-cloth-keys* ,(cons 'vector (cons nil (loop for n from 1 to 6 collect (intern (format nil "SJ-CLOTH-~d" n) :keyword)))))
     (defparameter *sj-bolt-keys* ,(cons 'vector (cons nil (loop for n from 1 to 6 collect (intern (format nil "SJ-BOLT-~d" n) :keyword)))))
     ,@(loop for n from 1 to 6 for hex in '(#x6A5A7E #xA8904E #x22222A #x5E7890 #x7E3A34 #x2E3656)   ; the hanks' dyes (S <= 0.45)
             collect `(defweapon ,(intern (format nil "SJ-CLOTH-~d" n) :keyword) (:length 1.0)
                        (:solid :ink 0 (mbc mb ,hex) (mb-cylinder mb 1.0 0.01 :segments 24) (sj-pattern mb ,n)))
             collect `(defweapon ,(intern (format nil "SJ-BOLT-~d" n) :keyword) (:length 0.6)
                        (:solid (mbc mb ,hex) (with-xform (mb (xform :y 0.3)) (mb-cylinder mb 0.09 0.6 :segments 8))
                                (mbc mb #xB89A5A) (with-xform (mb (xform :y 0.3)) (mb-cylinder mb 0.093 0.03 :segments 8))
                                (with-xform (mb (xform :y 0.05)) (mb-cylinder mb 0.093 0.02 :segments 8))
                                (with-xform (mb (xform :y 0.55)) (mb-cylinder mb 0.093 0.02 :segments 8)))))))
(def-hank-cloths)

(defweapon :sj-bone (:length 1.0)                     ; a unit bone along +Y (the echo arms: scaled per segment)
  (:solid :ink 0.5 (mbc mb #xB89A5A) (with-xform (mb (xform :y 0.5)) (mb-cylinder mb 1.0 1.0 :segments 5 :top-radius 0.8))
          (mbc mb #xC2A866) (mb-sphere mb 1.25 :segments 5 :rings 4)))
(defweapon :sj-hand (:length 0.12)                   ; a skeletal hand, fingers along +Y (the echo arms' hands)
  (:solid :ink 0.5 (mbc mb #xC2A866) (with-xform (mb (xform :y 0.02)) (mb-box mb 0.05 0.045 0.018))
          (mbc mb #xB89A5A)
          (loop for x in '(-0.018 -0.006 0.006 0.018) for l in '(0.06 0.07 0.075 0.065)
                do (with-xform (mb (xform :x x :y (+ 0.045 (* 0.5 l)))) (mb-box mb 0.009 l 0.009)))
          (with-xform (mb (xform :x -0.03 :y 0.03 :z 0.015 :roll 0.4)) (mb-box mb 0.009 0.05 0.009))))
(defweapon :sj-pin (:length 1.0)                    ; a unit marking pin along +Y, the head at 0 (MACHIBARI, KUKE: SJ-SEG)
  (:solid :ink 0 (mbc mb #xEDE6D0) (with-xform (mb (xform :y 0.47)) (mb-cylinder mb 1.0 0.94 :segments 6 :top-radius 0.6))
          (with-xform (mb (xform :y 0.97)) (mb-cone mb 0.6 0.06 :segments 4))
          (mbc mb #xC2A866) (with-xform (mb (xform :y 0.015)) (mb-cylinder mb 1.9 0.03 :segments 8))))
(defweapon :sj-stake (:length 0.8)                  ; a pin standing point-down, its head 0.8 m up (KUKE: SJ-PROP)
  (:solid (mbc mb #xEDE6D0) (with-xform (mb (xform :y 0.43)) (mb-cylinder mb 0.018 0.74 :segments 6))
          (with-xform (mb (xform :y 0.03 :roll 3.14159)) (mb-cone mb 0.018 0.06 :segments 4))
          (mbc mb #xC2A866) (with-xform (mb (xform :y 0.8)) (mb-sphere mb 0.04 :segments 6 :rings 4))))
(defweapon :sj-strip (:length 1.0)                   ; a loose strip of madder cloth (the aura, the burning procession)
  (:solid :ink 0 (mbc mb #x7A2E34) (with-xform (mb (xform :y 0.5)) (mb-box mb 0.14 1.0 0.008))
          (mbc mb #xB89A5A) (with-xform (mb (xform :y 0.03)) (mb-box mb 0.145 0.02 0.01))))
(defweapon :sj-drape (:length 4.0)                   ; the domain's drape on the rim: madder cloth, a gold hem
  (:solid (mbc mb #x7A2E34) (with-xform (mb (xform :y 2.0)) (mb-box mb 2.4 4.0 0.04))
          (mbc mb #x5E2228) (with-xform (mb (xform :x 0.6 :y 2.0 :z 0.025)) (mb-box mb 0.05 3.9 0.01))
          (with-xform (mb (xform :x -0.5 :y 2.0 :z 0.025)) (mb-box mb 0.05 3.9 0.01))
          (mbc mb #xB89A5A) (with-xform (mb (xform :y 0.08)) (mb-box mb 2.42 0.12 0.05))
          (with-xform (mb (xform :y 3.96)) (mb-box mb 2.6 0.1 0.08))))
(defweapon :sj-torii (:length 5.0)                   ; the golden torii-loom (4.4 m wide, 4.6 m tall): posts, the two lintels,
  (:solid (mbc mb #xB89A5A)                          ; the warp beam and its red warp
          (with-xform (mb (xform :x 1.8 :y 2.2)) (mb-cylinder mb 0.14 4.4 :segments 8))
          (with-xform (mb (xform :x -1.8 :y 2.2)) (mb-cylinder mb 0.14 4.4 :segments 8))
          (with-xform (mb (xform :y 4.5)) (mb-box mb 5.0 0.24 0.3))
          (with-xform (mb (xform :y 3.8)) (mb-box mb 4.2 0.16 0.22))
          (mbc mb #xC2A866) (with-xform (mb (xform :y 1.2)) (mb-cylinder mb 0.1 3.6 :segments 8 :top-radius 0.1))
          (with-xform (mb (xform :y 1.2 :roll 1.5708)) (mb-cylinder mb 0.12 3.5 :segments 8)))
  (:solid :ink 0 (mbc mb #x9A2A30)
          (loop for i from 0 below 12 do (with-xform (mb (xform :x (- (* 0.28 i) 1.54) :y 2.5)) (mb-box mb 0.014 2.5 0.014)))))
(defweapon :sj-carpet (:length 1.0)                  ; one metre of the red carpet (madder, gold edges)
  (:solid :ink 0 (mbc mb #x7A2E34) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.3 1.0 0.012))
          (mbc mb #xB89A5A) (with-xform (mb (xform :x 0.62 :y 0.5 :z 0.004)) (mb-box mb 0.06 1.0 0.012))
          (with-xform (mb (xform :x -0.62 :y 0.5 :z 0.004)) (mb-box mb 0.06 1.0 0.012))))
(defweapon :sj-tapestry (:length 2.0)                ; the tapestry the soldier steps out of
  (:solid (mbc mb #x7A2E34) (with-xform (mb (xform :y 1.0)) (mb-box mb 1.2 1.9 0.03))
          (mbc mb #xB89A5A) (with-xform (mb (xform :y 1.95)) (mb-cylinder mb 0.04 1.4 :segments 6))
          (with-xform (mb (xform :y 1.0 :z 0.02)) (mb-box mb 0.9 1.6 0.01))
          (mbc mb #x7A2E34) (with-xform (mb (xform :y 1.0 :z 0.03)) (mb-box mb 0.8 1.5 0.01))
          (mbc mb #xB89A5A) (with-xform (mb (xform :y 1.1 :z 0.04)) (mb-box mb 0.3 0.5 0.01))))
(defweapon :sj-shears (:length 1.2)                  ; the great gold shears (the Kikon's cut, the skip)
  (:solid (mbc mb #xB89A5A)
          (with-xform (mb (xform :y 0.55 :roll 0.12)) (mb-box mb 0.06 1.0 0.02))
          (with-xform (mb (xform :y 0.55 :roll -0.12 :z 0.02)) (mb-box mb 0.06 1.0 0.02))
          (mbc mb #xC2A866)
          (with-xform (mb (xform :y -0.1 :x 0.08)) (mb-cylinder mb 0.08 0.03 :segments 8))
          (with-xform (mb (xform :y -0.1 :x -0.08)) (mb-cylinder mb 0.08 0.03 :segments 8))))
(defweapon :sj-candle (:length 0.3)                  ; a white candle on a gold dish (the Blood Oath, hinted)
  (:solid (mbc mb #xECECE8) (with-xform (mb (xform :y 0.12)) (mb-cylinder mb 0.03 0.24 :segments 8))
          (mbc mb #xB89A5A) (mb-cylinder mb 0.08 0.02 :segments 10)))
(defweapon :sj-mirror (:length 1.2)                  ; 眼's mirror-eye: a gold oval frame on a post, an eye in it
  (:solid (mbc mb #xB89A5A) (with-xform (mb (xform :y 0.4)) (mb-cylinder mb 0.03 0.8 :segments 6))
          (with-xform (mb (xform :y 1.05 :pitch 1.5708)) (mb-cylinder mb 0.26 0.04 :segments 12))
          (mbc mb #xECECE8) (with-xform (mb (xform :y 1.05 :z 0.022 :pitch 1.5708)) (mb-cylinder mb 0.2 0.01 :segments 12))
          (mbc mb #x6A5A7E) (with-xform (mb (xform :y 1.05 :z 0.03 :pitch 1.5708)) (mb-cylinder mb 0.09 0.01 :segments 10))
          (mbc mb #x16121C) (with-xform (mb (xform :y 1.05 :z 0.036 :pitch 1.5708)) (mb-cylinder mb 0.04 0.01 :segments 8))))
(defweapon :sj-sheet (:length 1.8)                   ; 刃金: a spiked gold sheet cut in her likeness
  (:solid (mbc mb #xD0B870) (with-xform (mb (xform :y 0.9)) (mb-box mb 0.7 1.8 0.03))
          (with-xform (mb (xform :y 1.85)) (mb-cylinder mb 0.14 0.03 :segments 8))
          (mbc mb #xD8DCE4) (loop for i below 5 do (with-xform (mb (xform :y (+ 0.25 (* 0.33 i)) :z 0.06 :pitch 1.5708))
                                                     (mb-cone mb 0.04 0.14 :segments 4)))))
(defweapon :sj-dome (:length 1.0)                    ; 星's dome: a unit hemisphere (drawn see-through)
  (:solid :ink 0 (mbc mb #x2E3656) (mb-sphere mb 1.0 :segments 16 :rings 8)))
(defweapon :sj-star (:length 0.6)                    ; a white star
  (:solid :ink 0.5 (mbc mb #xF2F4F8) (dotimes (i 5) (with-xform (mb (xform :roll (* i 1.2566))) (with-xform (mb (xform :y 0.18)) (mb-cone mb 0.08 0.36 :segments 3))))))
(defweapon :sj-tree (:length 1.6)                    ; 焼野原's ink tree
  (:solid :ink 0 (mbc mb #x16161E) (with-xform (mb (xform :y 0.6)) (mb-box mb 0.08 1.2 0.08))
          (with-xform (mb (xform :y 1.1 :x 0.2 :roll -0.8)) (mb-box mb 0.05 0.6 0.05))
          (with-xform (mb (xform :y 1.0 :x -0.18 :roll 0.9)) (mb-box mb 0.05 0.5 0.05))
          (with-xform (mb (xform :y 1.35 :x 0.05 :roll -0.2)) (mb-box mb 0.04 0.5 0.04))))

;;; ---------------------------------------------------------------- poses and clips (§10: 21 new clips)
;;; Her rig notes: upright and still, the clogs together, the head level; the needle rides in the upper right bone hand
;;; (the right arm is the needle arm, the left the free upper hand); the echo arms (SENJU-DRAW) repeat every motion 2 / 4
;;; frames late, so a strike reads as a fan of hands arriving in a ripple. Hit poses (DEFSTRIKE :s) put the needle or the
;;; hands where the move's volume is (senjumaru.lisp).
(defpose :sj-stance ()                                ; the needle raised at shoulder height, the free hand open aside
  (:root :u -0.01) (:pelvis :twist 10) (:spine :flex 2) (:chest :twist -6) (:neck :twist -4) (:head :flex 4 :twist -4)
  (:arm-r :flex 62 :side 24) (:elbow-r :flex 78) (:hand-r :twist -20 :flex -30)
  (:arm-l :flex 30 :side 46) (:elbow-l :flex 56) (:hand-l :flex -24)
  (:thigh-r :flex 4 :side 2) (:thigh-l :flex -2 :side 2) (:knee-r :flex 5) (:knee-l :flex 4))
(defclip :sj-stance (2.4 :loop t :base :sj-stance)     ; a slow breath; the needle's point circles a little
  (0) (1.2 (:root :u -0.018) (:chest :flex 2) (:hand-r :flex -26) (:elbow-l :flex 60)))

(defpose :sj-loom-stance ()                           ; the Bankai: the arms spread wider, the upper pair raised as at a loom
  (:root :u -0.01) (:pelvis :twist 0) (:spine :flex -2) (:chest :twist 0) (:head :flex 2)
  (:arm-r :flex 70 :side 58) (:elbow-r :flex 64) (:hand-r :twist -30 :flex -20)
  (:arm-l :flex 70 :side 58) (:elbow-l :flex 64) (:hand-l :twist 30 :flex -20)
  (:thigh-r :flex 2 :side 3) (:thigh-l :flex 2 :side 3) (:knees :flex 4))
(defclip :sj-loom-stance (3.0 :loop t :base :sj-loom-stance)
  (0) (1.5 (:root :u -0.016) (:arm-r :side 62) (:arm-l :side 62) (:hand-r :flex -14) (:hand-l :flex -14)))

;; J1 HITOHARI: the upper right hand jabs the needle straight out
(defpose :sj-q1-hit (:base :sj-stance)
  (:root :f 0.06 :u -0.05) (:pelvis :twist 18) (:chest :twist 16) (:neck :twist -12) (:head :twist -10)
  (:arm-r :flex 80 :side 4) (:elbow-r :flex 20) (:hand-r :twist 0 :flex -64)
  (:arm-l :flex 20 :side 60) (:elbow-l :flex 40)
  (:thigh-r :flex 20) (:knee-r :flex 20) (:thigh-l :flex -8) (:knee-l :flex 8))
(defstrike :sj-q1 (7 3 12 :base :sj-stance)
  (0)
  (3 (:chest :twist -14) (:arm-r :flex 60 :side 10) (:elbow-r :flex 110) (:hand-r :flex -80) (:root :u -0.03))
  (:s :snap :sj-q1-hit)
  (:a (:root :f 0.08) (:arm-r :flex 81))
  (16 (:root :f 0.03) (:arm-r :flex 70 :side 18) (:elbow-r :flex 60) (:hand-r :flex -50) (:chest :twist 4))
  (:end :sj-stance))

;; J2 KAESHINUI: the backstitch: the needle drawn back across him, the thread taut
(defpose :sj-q2-hit (:base :sj-stance)
  (:root :f 0.06 :u -0.05 :yaw -8) (:pelvis :twist 16) (:chest :twist -22) (:neck :twist 10) (:head :twist 6)
  (:arm-r :side 50 :flex 30) (:elbow-r :flex 80 :twist 140) (:hand-r :twist 0 :flex -84)
  (:arm-l :flex 60 :side 20) (:elbow-l :flex 50) (:hand-l :flex -40))
(defstrike :sj-q2 (7 3 13 :base :sj-stance)
  (0)
  (3 (:chest :twist 20) (:arm-r :side 86 :flex 118) (:elbow-r :flex 18 :twist 140) (:hand-r :flex -80) (:root :u -0.04 :yaw 6))
  (:s :snap :sj-q2-hit)
  (:a (:chest :twist -24) (:arm-r :flex 28))
  (17 (:chest :twist -6) (:arm-r :side 40 :flex 50) (:elbow-r :flex 50 :twist 40) (:hand-r :flex -50))
  (:end :sj-stance))

;; J3 SENJU (and NUICHI's strike): all six hands fan out and whirl in a ring of needles, the clogs planted
(defstrike :sj-spin (8 3 18 :base :sj-stance)
  (0)
  (4 (:root :u -0.04 :yaw -20) (:chest :twist -30) (:arm-r :side 80 :flex 10) (:elbow-r :flex 10) (:hand-r :flex -80)
     (:arm-l :side 80 :flex 10) (:elbow-l :flex 10) (:hand-l :flex -40))
  (6 (:root :yaw -30) (:chest :twist -36))
  (:s :snap (:root :yaw 330 :u -0.02 :f 0.04) (:chest :twist 10) (:arm-r :side 60 :flex 40) (:elbow-r :flex 65) (:hand-r :flex -88)
      (:arm-l :side 60 :flex 40) (:elbow-l :flex 65) (:hand-l :flex -60))
  (:a (:root :yaw 360 :f 0.05) (:chest :twist 14))
  (22 (:root :yaw 360 :u -0.02 :f 0.06) (:arm-r :side 50 :flex 40) (:elbow-r :flex 40) (:hand-r :flex -50)
      (:arm-l :side 60 :flex 30) (:elbow-l :flex 50))
  (:end :sj-stance (:root :yaw 360)))

;; K1 MACHIBARI: both upper hands draw long pins back past the hip and drive them straight out
(defpose :sj-f1-hit (:base :sj-stance)
  (:root :f 0.34 :u -0.1) (:pelvis :twist 6) (:spine :flex 10) (:chest :twist 4) (:head :flex -6)
  (:arm-r :flex 96 :side 6) (:elbow-r :flex 0) (:hand-r :twist 0 :flex -90)
  (:arm-l :flex 94 :side 8) (:elbow-l :flex 0) (:hand-l :flex -70)
  (:thigh-r :flex 34) (:knee-r :flex 34) (:thigh-l :flex -16) (:knee-l :flex 10))
(defstrike :sj-f1 (17 4 20 :base :sj-stance)
  (0)
  (7 (:root :u -0.06 :f -0.06) (:chest :twist -4) (:arm-r :flex -20 :side 16) (:elbow-r :flex 70) (:hand-r :flex -40)
     (:arm-l :flex -24 :side 18) (:elbow-l :flex 70) (:knees :flex 20))
  (14 (:root :u -0.08 :f -0.08) (:arm-r :flex -28) (:arm-l :flex -30))
  (:s :snap :sj-f1-hit)
  (:a (:root :f 0.36) (:arm-r :flex 97) (:arm-l :flex 95))
  (32 (:root :f 0.16 :u -0.05) (:arm-r :flex 70 :side 20) (:elbow-r :flex 50) (:arm-l :flex 50 :side 30) (:elbow-l :flex 50))
  (:end :sj-stance))

;; K2 MATSURI: the hem stitch: a rising loop of thread whipped up and over him
(defpose :sj-f2-hit (:base :sj-stance)
  (:root :u 0.02 :f 0.14) (:spine :flex -8) (:chest :twist 10) (:head :flex -14)
  (:arm-r :flex 150 :side 20) (:elbow-r :flex 10) (:hand-r :flex -60)
  (:arm-l :flex 120 :side 40) (:elbow-l :flex 20) (:hand-l :flex -40))
(defstrike :sj-f2 (21 4 24 :base :sj-stance)
  (0)
  (10 (:root :u -0.12 :yaw -60) (:spine :flex 22) (:chest :twist -12) (:arm-r :flex -10 :side 30) (:elbow-r :flex 20)
      (:arm-l :flex -10 :side 40) (:elbow-l :flex 30) (:knees :flex 40) (:thighs :flex 20))
  (18 (:root :u -0.14 :yaw -70) (:spine :flex 26) (:arm-r :flex -20))
  (:s :snap :sj-f2-hit)
  (23 (:arm-r :flex 156) (:root :u 0.03))
  (:a (:arm-r :flex 154))
  (38 (:root :u -0.02 :f 0.08) (:spine :flex 2) (:arm-r :flex 80 :side 24) (:elbow-r :flex 60) (:arm-l :flex 50 :side 40))
  (:end :sj-stance))

;; K3 KUKE: the blind stitch: all six hands slam pins down round his feet, held 3 f
(defpose :sj-drop-hit (:base :sj-stance)
  (:root :u -0.28 :f 0.3) (:spine :flex 38) (:chest :twist 0) (:head :flex -18)
  (:arm-r :flex 70 :side 10) (:elbow-r :flex 0) (:hand-r :flex -40)
  (:arm-l :flex 70 :side 10) (:elbow-l :flex 0) (:hand-l :flex -40)
  (:thigh-r :flex 50) (:knee-r :flex 70) (:thigh-l :flex 30) (:knee-l :flex 60))
(defstrike :sj-drop (21 5 34 :base :sj-stance)
  (0)
  (8 (:root :u 0.03) (:spine :flex -12) (:arm-r :flex 170 :side 20) (:elbow-r :flex 20) (:arm-l :flex 170 :side 20)
     (:elbow-l :flex 20) (:head :flex -24))
  (17 (:root :u 0.04) (:arm-r :flex 176) (:arm-l :flex 176) (:spine :flex -15))
  (:s :snap :sj-drop-hit)
  (24 :sj-drop-hit)
  (:a (:spine :flex 40) (:root :u -0.29 :f 0.3))
  (46 (:spine :flex 30) (:root :u -0.22 :f 0.26))
  (54 (:spine :flex 10) (:root :u -0.08 :f 0.12) (:arm-r :flex 60 :side 20) (:elbow-r :flex 50) (:arm-l :flex 40 :side 30)
      (:elbow-l :flex 50) (:thigh-r :flex 20) (:knee-r :flex 20) (:thigh-l :flex 10) (:knee-l :flex 14))
  (:end :sj-stance))

;; L WARUI KUSE: the upper hands grip the threads and yank them back over her shoulder
(defstrike :sj-yank (8 0 24 :base :sj-stance)
  (0 (:arm-r :flex 90 :side 10) (:elbow-r :flex 10) (:hand-r :flex -60) (:arm-l :flex 90 :side 10) (:elbow-l :flex 10))
  (5 (:arm-r :flex 96) (:arm-l :flex 96) (:chest :twist 6))
  (:s :snap (:arm-r :flex 150 :side 30) (:elbow-r :flex 120) (:hand-r :flex 20) (:arm-l :flex 140 :side 30) (:elbow-l :flex 120)
      (:hand-l :flex 20) (:spine :flex -10) (:chest :twist -20) (:head :flex -6 :twist 10) (:root :f -0.1 :u -0.02))
  (20 (:arm-r :flex 146) (:arm-l :flex 136) (:spine :flex -8))
  (:end :sj-stance))

;; SP1 SHINPEI: the hands part an unseen tapestry to the side; the upper pair gestures him forward
(defstrike :sj-summon (16 0 22 :base :sj-stance)
  (0)
  (8 (:arm-r :flex 30 :side 70) (:elbow-r :flex 20) (:hand-r :flex -30) (:arm-l :flex 30 :side 70) (:elbow-l :flex 20)
     (:chest :twist 0) (:head :flex 0))
  (:s :snap (:arm-r :flex 100 :side 10) (:elbow-r :flex 20) (:hand-r :flex -80) (:arm-l :flex 70 :side 60) (:elbow-l :flex 10)
      (:root :f 0.05) (:head :flex -4))
  (30 (:arm-r :flex 90) (:arm-l :side 64))
  (:end :sj-stance))

;; SP2 KASA: the six arms open like ribs, the canopy snapping taut; then it inverts and the threads lash out
(defpose :sj-kasa-open (:base :sj-stance)
  (:root :u -0.03) (:spine :flex -4) (:head :flex -8)
  (:arm-r :flex 150 :side 50) (:elbow-r :flex 10) (:hand-r :flex -10) (:arm-l :flex 150 :side 50) (:elbow-l :flex 10) (:hand-l :flex -10))
(defstrike :sj-kasa (4 24 18 :base :sj-stance)
  (0)
  (:s :snap :sj-kasa-open)
  (16 :sj-kasa-open (:root :u -0.04))
  (:a :snap (:arm-r :flex 90 :side 20) (:elbow-r :flex 0) (:hand-r :flex -90) (:arm-l :flex 90 :side 20) (:elbow-l :flex 0)
      (:hand-l :flex -90) (:spine :flex 12) (:root :f 0.12))
  (40 (:arm-r :flex 70 :side 24) (:elbow-r :flex 50) (:arm-l :flex 50 :side 36) (:elbow-l :flex 50) (:spine :flex 4))
  (:end :sj-stance))

;; I SAIDAN: the dash (low on the clogs, the arms folded back), the strike (two upper hands close like shears)
(defclip :sj-breaker (0.4 :loop t :base :sj-stance)
  (0 (:root :u -0.1) (:spine :flex 30) (:head :flex -24) (:arm-r :flex -40 :side 30) (:elbow-r :flex 30) (:arm-l :flex -40 :side 30)
     (:elbow-l :flex 30) (:thigh-r :flex 30) (:knee-r :flex 20) (:thigh-l :flex -20) (:knee-l :flex 30))
  (0.2 (:root :u -0.08) (:thigh-l :flex 30) (:knee-l :flex 20) (:thigh-r :flex -20) (:knee-r :flex 30)))
(defstrike :sj-saidan (8 4 18 :base :sj-stance)
  (0 (:arm-r :flex 90 :side 60) (:elbow-r :flex 10) (:arm-l :flex 90 :side 60) (:elbow-l :flex 10) (:root :u -0.06))
  (5 (:arm-r :side 70) (:arm-l :side 70))
  (:s :snap (:arm-r :flex 92 :side -6) (:elbow-r :flex 0) (:hand-r :flex -80) (:arm-l :flex 92 :side -6) (:elbow-l :flex 0)
      (:hand-l :flex -80) (:root :f 0.14 :u -0.08) (:spine :flex 10))
  (:a (:root :f 0.16))
  (24 (:root :f 0.07) (:arm-r :flex 70 :side 20) (:elbow-r :flex 50) (:arm-l :flex 40 :side 40) (:elbow-l :flex 50))
  (:end :sj-stance))

;; the intro (the needle drawn out of the air, the thread following), the win (she threads the needle), the awakening's
;; praying pose (the six arms raised to the torii)
(defclip :sj-intro (2.0 :base :sj-stance)
  (0 (:arm-r :flex 150 :side 30) (:elbow-r :flex 20) (:hand-r :flex -80) (:arm-l :flex 20 :side 30) (:elbow-l :flex 40)
     (:head :flex -10))
  (0.5 (:arm-r :flex 156) (:hand-r :flex -84))
  (0.9 :snap (:arm-r :flex 110 :side 40) (:elbow-r :flex 60) (:hand-r :flex -40) (:head :flex 2))
  (1.4 :sj-stance)
  (2.0 :sj-stance))
(defclip :sj-win (2.0 :base :sj-stance)
  (0)
  (0.4 (:arm-r :flex 80 :side 10) (:elbow-r :flex 100) (:hand-r :flex -40) (:arm-l :flex 80 :side 0) (:elbow-l :flex 100)
       (:hand-l :flex -40) (:head :flex 14))
  (1.2 (:arm-r :flex 84) (:arm-l :flex 82) (:head :flex 16))
  (2.0 (:arm-r :flex 82) (:arm-l :flex 80) (:head :flex 10 :twist -8)))
(defpose :sj-pray (:base :sj-loom-stance)
  (:arm-r :flex 160 :side 20) (:elbow-r :flex 30) (:hand-r :flex 10) (:arm-l :flex 160 :side 20) (:elbow-l :flex 30)
  (:hand-l :flex 10) (:head :flex -16) (:spine :flex -6))
(defclip :sj-awaken (2.0 :base :sj-stance)
  (0 (:arm-r :flex 20 :side 10) (:elbow-r :flex 20) (:hand-r :flex -40) (:arm-l :flex 20 :side 10) (:elbow-l :flex 20)
     (:head :flex 10))
  (0.8 :sj-pray)
  (2.0 :sj-pray (:head :flex -20)))

;;; the Bankai's clips
(defpose :sj-weave-pose (:base :sj-loom-stance)        ; the six hands work in a ripple before her chest
  (:arm-r :flex 70 :side 30) (:elbow-r :flex 90) (:hand-r :flex -10) (:arm-l :flex 70 :side 30) (:elbow-l :flex 90)
  (:hand-l :flex -10) (:head :flex 12))
(defclip :sj-weave (0.34 :loop t :base :sj-weave-pose)  ; a pass per 20 f: the shuttle thrown left, right
  (0 (:arm-r :side 40) (:arm-l :side 22) (:chest :twist 6))
  (0.17 (:arm-r :side 22) (:arm-l :side 40) (:chest :twist -6)))
(defstrike :sj-unravel (6 0 22 :base :sj-loom-stance)   ; released: the upper pair flings the bolt out; it unrolls where it lands
  (0 :sj-weave-pose)
  (3 (:arm-r :flex 40 :side 20) (:elbow-r :flex 100) (:arm-l :flex 40 :side 20) (:elbow-l :flex 100))
  (:s :snap (:arm-r :flex 110 :side 10) (:elbow-r :flex 0) (:hand-r :flex -70) (:arm-l :flex 110 :side 10) (:elbow-l :flex 0)
      (:hand-l :flex -70) (:root :f 0.1) (:spine :flex 6))
  (16 (:arm-r :flex 100) (:arm-l :flex 100))
  (:end :sj-loom-stance))
(defpose :sj-tanmono-hit (:base :sj-loom-stance)      ; K1 TANMONO-UCHI: a bolt of cloth flung straight out from two hands
  (:root :f 0.3 :u -0.08) (:spine :flex 8) (:arm-r :flex 94 :side 8) (:elbow-r :flex 0) (:hand-r :flex -80)
  (:arm-l :flex 94 :side 8) (:elbow-l :flex 0) (:hand-l :flex -80) (:thigh-r :flex 26) (:knee-r :flex 26))
(defstrike :sj-tanmono (17 4 20 :base :sj-loom-stance)
  (0)
  (8 (:arm-r :flex 30 :side 30) (:elbow-r :flex 110) (:arm-l :flex 30 :side 30) (:elbow-l :flex 110) (:root :u -0.05))
  (14 (:arm-r :flex 20) (:arm-l :flex 20) (:root :f -0.06))
  (:s :snap :sj-tanmono-hit)
  (:a (:root :f 0.32))
  (30 (:root :f 0.12) (:arm-r :flex 60) (:elbow-r :flex 60) (:arm-l :flex 60) (:elbow-l :flex 60))
  (:end :sj-loom-stance))
(defpose :sj-makitori-hit (:base :sj-loom-stance)     ; K3 MAKITORI: cloth wraps him from the feet up, the hands haul it in
  (:root :f -0.1 :u -0.12) (:spine :flex -6) (:arm-r :flex 60 :side 10) (:elbow-r :flex 110) (:hand-r :flex 20)
  (:arm-l :flex 60 :side 10) (:elbow-l :flex 110) (:hand-l :flex 20) (:thigh-r :flex 10) (:thigh-l :flex 36) (:knees :flex 30))
(defstrike :sj-makitori (21 5 34 :base :sj-loom-stance)
  (0)
  (10 (:arm-r :flex 90 :side 6) (:elbow-r :flex 0) (:hand-r :flex -80) (:arm-l :flex 90 :side 6) (:elbow-l :flex 0)
      (:root :f 0.12))
  (18 (:arm-r :flex 94) (:arm-l :flex 94) (:root :f 0.14))
  (:s :snap :sj-makitori-hit)
  (:a (:root :f -0.12))
  (50 (:root :f 0 :u -0.04) (:arm-r :flex 70 :side 40) (:elbow-r :flex 70) (:arm-l :flex 70 :side 40) (:elbow-l :flex 70))
  (:end :sj-loom-stance))
(defstrike :sj-snip (12 0 18 :base :sj-loom-stance)    ; SP1 TACHINAOSHI: two upper hands close shears in the air
  (0 (:arm-r :flex 140 :side 50) (:elbow-r :flex 10) (:arm-l :flex 140 :side 50) (:elbow-l :flex 10))
  (8 (:arm-r :side 60) (:arm-l :side 60))
  (:s :snap (:arm-r :flex 140 :side 0) (:arm-l :flex 140 :side 0) (:head :flex -10))
  (20 (:arm-r :flex 120 :side 10) (:arm-l :flex 120 :side 10))
  (:end :sj-loom-stance))

;;; the cinematics' own clips (played by the DEFCINEs)
(defclip :sj-kikon (2.0 :base :sj-stance)              ; 仕立て直し: the whirl ending held, then the hands blur round him
  (0 (:root :yaw 360 :f 0.12) (:arm-r :side 88 :flex 40) (:elbow-r :flex 0) (:arm-l :side 88 :flex 40) (:elbow-l :flex 0))
  (0.3 (:root :yaw 360) (:arm-r :flex 160 :side 30) (:arm-l :flex 160 :side 30) (:head :flex -6))
  (1.2 (:root :yaw 360) (:arm-r :flex 100 :side 10) (:elbow-r :flex 40) (:arm-l :flex 110 :side 20) (:elbow-l :flex 30))
  (2.0 (:root :yaw 360) (:arm-r :flex 90 :side 30) (:elbow-r :flex 60) (:arm-l :flex 70 :side 40) (:elbow-l :flex 60)))
(defclip :sj-knot (1.6 :base :sj-stance)               ; the thread drawn to her lips and bitten off; a small courtly bow
  (0 (:arm-r :flex 120 :side 10) (:elbow-r :flex 130) (:hand-r :flex -10) (:head :flex -4))
  (0.6 (:arm-r :flex 124) (:head :flex 6))
  (1.0 :snap (:arm-r :flex 70 :side 30) (:elbow-r :flex 80) (:spine :flex 14) (:head :flex 18))
  (1.6 (:spine :flex 10) (:head :flex 14)))

;;; ---------------------------------------------------------------- props at a world point (cosmetic)
(defvar *weave-pass* 20 "(senjumaru.lisp's knob: frames per weave pass; declared here for the bolt's look.)")
(declaim (type f32vec *sj-m* *sj-p* *sj-q*))
(defvar *sj-m* (m4) "A prop's world matrix (SJ-PROP, SJ-SEG).")
(defvar *sj-p* (make-f32 3))
(defvar *sj-q* (make-f32 3))

(defun sj-prop (key x y z &key (yaw 0.0) (pitch 0.0) (roll 0.0) (s 1.0) sx sy sz (alpha 1.0) (feet 0.0))
  "Draw prop KEY (a DEFWEAPON built with the weapons) at (X Y Z), turned YAW / PITCH / ROLL, scaled S (or SX SY SZ). FEET:
the toon's darker-toward-the-feet height (a cloth lying on the plaza passes -2: no darkening)."
  (m4-euler! *sj-m* (f32 x) (f32 y) (f32 z) (f32 yaw) (f32 pitch) (f32 roll) (f32 (or sx s)) (f32 (or sy s)) (f32 (or sz s)))
  (setf (aref *toon-body* 1) (f32 feet))
  (draw-weapon key *sj-m* :alpha (f32 alpha)))

(defun sj-seg (key ax ay az bx by bz w &optional (alpha 1.0))
  "Draw prop KEY (built along +Y, unit length) from A to B, W wide (a bone of an echo arm, a bolt)."
  (let* ((dx (- bx ax)) (dy (- by ay)) (dz (- bz az)) (l (max 1e-4 (sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
         (ux (/ dx l)) (uy (/ dy l)) (uz (/ dz l))
         ;; a unit perpendicular (the side axis), then the third
         (px (if (> (abs uy) 0.9) 1.0 (- uz))) (py (if (> (abs uy) 0.9) 0.0 0.0)) (pz (if (> (abs uy) 0.9) 0.0 ux))
         (pl (max 1e-4 (sqrt (+ (* px px) (* py py) (* pz pz))))) (px (/ px pl)) (py (/ py pl)) (pz (/ pz pl))
         (qx (- (* uy pz) (* uz py))) (qy (- (* uz px) (* ux pz))) (qz (- (* ux py) (* uy px)))
         (m *sj-m*))
    (setf (aref m 0) (f32 (* w px)) (aref m 1) (f32 (* w py)) (aref m 2) (f32 (* w pz)) (aref m 3) 0f0
          (aref m 4) (f32 dx) (aref m 5) (f32 dy) (aref m 6) (f32 dz) (aref m 7) 0f0
          (aref m 8) (f32 (* w qx)) (aref m 9) (f32 (* w qy)) (aref m 10) (f32 (* w qz)) (aref m 11) 0f0
          (aref m 12) (f32 ax) (aref m 13) (f32 ay) (aref m 14) (f32 az) (aref m 15) 1f0)
    (setf (aref *toon-body* 1) 0f0)
    (draw-weapon key m :alpha (f32 alpha))))

(defun sj-thread (ax ay az bx by bz &optional (k 0.9) (w 0.006) (seed 0.0))
  "A thin BLOOD thread from A to B (the only BLOOD she shows: 1-2 px lines)."
  (with-floats (ax ay az bx by bz k w seed)
    (toon-ribbon (ax ay az) ((- bx ax) (- by ay) (- bz az)) (w (* 0.7f0 w)) :heat (1f0 0.8f0) :seed (- -60f0 seed) :wob 0.02f0 :pal +pal-blood+ :k k
                 :ph seed :segs 2)))

;;; ---------------------------------------------------------------- her draw hook: echo arms, the thread, his stitches, the domain
(declaim (type f32vec *sj-hist*))
(defvar *sj-hist* (make-f32 (* 2 8 6)) "Per side, 8 drawings of the rig hands (right xyz, left xyz): the echo arms' lag.")
(defvar *sj-hist-i* (make-array 2 :initial-element 0) "Per side, the newest drawing in *SJ-HIST*.")
(declaim (type f32vec *sj-echo*))
(defvar *sj-echo* (make-f32 (* 2 4 3)) "Per side, the four echo hands drawn last (the umbrella's ribs).")
(defvar *sj-loom-at* (vector nil nil) "Per side: (entity x z yaw) of the loom at the rim, placed when her Bankai is first drawn.")

(defun sj-hist-push (side jm)
  (let* ((i (mod (1+ (svref *sj-hist-i* side)) 8)) (o (+ (* side 48) (* i 6))) (v *sj-p*))
    (setf (svref *sj-hist-i* side) i)
    (joint-point! v jm (ji :hand-r) 0f0 -0.06f0 0f0)
    (setf (aref *sj-hist* o) (aref v 0) (aref *sj-hist* (+ o 1)) (aref v 1) (aref *sj-hist* (+ o 2)) (aref v 2))
    (joint-point! v jm (ji :hand-l) 0f0 -0.06f0 0f0)
    (setf (aref *sj-hist* (+ o 3)) (aref v 0) (aref *sj-hist* (+ o 4)) (aref v 1) (aref *sj-hist* (+ o 5)) (aref v 2))))

(defun sj-hist (side lag hand)
  "Values x y z of rig hand HAND (0 right, 1 left) LAG drawings ago."
  (let ((o (+ (* side 48) (* (mod (- (svref *sj-hist-i* side) lag) 8) 6) (* 3 hand))))
    (values (aref *sj-hist* o) (aref *sj-hist* (+ o 1)) (aref *sj-hist* (+ o 2)))))

(defparameter *sj-echo-arms* '((1 28 2 0.02) (-1 28 2 0.02) (1 52 4 -0.17) (-1 52 4 -0.17))
  "The four echo arms (§2, engine gap N12): per arm its side (+1 right), its spread (degrees about the spine), its lag
(drawings) and its anchor's height on the back (chest frame).")

(defvar *sj-act* (make-array 2 :initial-element 0.0) "Per side, 0..1: how far the echo arms follow her strike (0: the rest fan).")

(defun sj-echo-arms (e side m rdt)
  "Four gold bone chains from anchors on her upper back to her rig hands' positions of 2 / 4 drawings ago, turned about
her spine by +-28 / +-52 degrees: every strike ripples through six hands; at rest they settle into a half-fan behind her,
framing the crescent (eased over ~0.1 s either way)."
  (let* ((jm (model-joints m)) (p (pos-of e)) (cx (aref p 0)) (cz (aref p 2)) (a *sj-p*) (r *sj-q*) (i 0)
         (f (fighter e)) (want (if (member (fighter-state f) '(:move :hoho :cine)) 1.0 0.0))
         (act (setf (svref *sj-act* side) (+ (svref *sj-act* side) (* (- want (svref *sj-act* side)) (min 1.0 (* 10.0 rdt)))))))
    (dolist (arm *sj-echo-arms*)
      (destructuring-bind (s spread lag up) arm
        (joint-point! a jm (ji :chest) (f32 (* s 0.09)) (f32 up) 0.1f0)            ; (joint frames: +z is behind)
        (joint-point! r jm (ji :chest) (f32 (* s (if (< up 0) 0.42 0.3))) (f32 (if (< up 0) 0.12 0.42)) 0.34f0)   ; the rest fan
        (multiple-value-bind (hx hy hz) (sj-hist side lag (if (plusp s) 0 1))
          (let* ((ang (* s (deg spread))) (c (cos ang)) (sn (sin ang))
                 (rx (- hx cx)) (rz (- hz cz))
                 (tx (+ cx (- (* c rx) (* sn rz)))) (tz (+ cz (+ (* sn rx) (* c rz)))) (ty (+ hy (if (< up 0) -0.12 0.02)))
                 (tx (+ (* act tx) (* (- 1 act) (aref r 0)))) (ty (+ (* act ty) (* (- 1 act) (aref r 1))))
                 (tz (+ (* act tz) (* (- 1 act) (aref r 2))))
                 (ax (aref a 0)) (ay (aref a 1)) (az (aref a 2))
                 (mx (* 0.5 (+ ax tx))) (mz (* 0.5 (+ az tz))) (ox (- mx cx)) (oz (- mz cz)) (ol (max 1e-3 (sqrt (+ (* ox ox) (* oz oz)))))
                 (ex (+ mx (* 0.16 (/ ox ol)))) (ey (+ (* 0.5 (+ ay ty)) 0.06)) (ez (+ mz (* 0.16 (/ oz ol)))))
            (sj-seg :sj-bone ax ay az ex ey ez 0.018)
            (sj-seg :sj-bone ex ey ez tx ty tz 0.013)
            (sj-seg :sj-hand tx ty tz (+ tx (* 0.8 (- tx ex))) (+ ty (* 0.8 (- ty ey))) (+ tz (* 0.8 (- tz ez))) 1.0)
            (let ((o (+ (* side 12) (* 3 i))))
              (setf (aref *sj-echo* o) (f32 tx) (aref *sj-echo* (+ o 1)) (f32 ty) (aref *sj-echo* (+ o 2)) (f32 tz)))
            (incf i)))))))

(defun sj-needle-thread (e m)
  "The endless red reishi thread from the needle's eye, trailing where the hand has been."
  (let* ((jm (model-joints m)) (v *sj-p*) (side (fighter-side (fighter e))))
    (joint-point! v jm (ji :weapon-r) 0f0 0f0 0.035f0)
    (let ((x0 (aref v 0)) (y0 (aref v 1)) (z0 (aref v 2)))
      (loop for lag from 1 to 5
            do (multiple-value-bind (x y z) (sj-hist side lag 0)
                 (let ((x1 (+ x (* 0.02 lag))) (y1 (- y (* 0.08 lag))) (z1 z))
                   (sj-thread x0 y0 z0 x1 y1 z1 (- 0.9 (* 0.12 lag)) 0.004 (float lag))
                   (setf x0 x1 y0 y1 z0 z1)))))))

;; the K links' props (the user's playtest, 2026-09-29: the reach matches the art; docs/duel/DUEL_SENJUMARU.md "Playtest"):
;; each is out to its move's hit-volume far edge at the hit frames. The host test (duel-rules-test) checks these against
;; the volumes, and the J links' needle tip against theirs
(defparameter *sj-strike-reach*
  '((:sj-f1 :pins 3.2) (:sj-f2 :loop 2.5) (:sj-drop :stakes 2.5) (:sj-tanmono :bolt 4.1) (:sj-makitori :wrap 2.5))
  "Clip -> (kind far): the prop the clip's K link throws and its far end, metres from her centre along her facing
(MACHIBARI's two long pins, MATSURI's loop of thread, KUKE's pins round his feet, TANMONO-UCHI's bolt, MAKITORI's cloth).")

(defun sj-strike-out (sf s a)
  "0..1: how far a K prop is out at move frame SF (S / A: the move's): flung over the 4 frames before S, all the way out
through the active frames, drawn back over the 8 after."
  (cond ((< sf s) (max 0.0 (min 1.0 (/ (- sf (- s 4)) 4.0))))
        ((< sf (+ s a)) 1.0)
        (t (max 0.0 (- 1.0 (/ (- sf (+ s a)) 8.0))))))

(defun sj-strike-props (e f)
  "The K link's prop (*SJ-STRIKE-REACH*), drawn from her rig hands out to its far end."
  (let* ((mv (fighter-move f))
         (spec (and mv (eq (fighter-state f) :move) (eq (fighter-phase f) :main) (rest (assoc (mv-clip mv) *sj-strike-reach*))))
         (sf (fighter-sf f)) (k (if spec (sj-strike-out sf (mv-s mv) (mv-a mv)) 0.0)))
    (when (> k 0.0)
      (let* ((jm (model-joints (model e))) (p (pos-of e)) (cx (aref p 0)) (cz (aref p 2)) (yaw (yaw-of e))
             (fx (fwd-x yaw)) (fz (fwd-z yaw)) (v *sj-p*) (w *sj-q*) (d (second spec)))
        (joint-point! v jm (ji :hand-r) 0f0 -0.06f0 0f0)
        (joint-point! w jm (ji :hand-l) 0f0 -0.06f0 0f0)
        (flet ((fwd (x z) (+ (* (- x cx) fx) (* (- z cz) fz)))            ; metres ahead of her centre
               (turned (a) (let ((c (cos (deg a))) (s (sin (deg a)))) (values (- (* c fx) (* s fz)) (+ (* s fx) (* c fz))))))
          (ecase (first spec)
            (:pins                                     ; MACHIBARI: a long pin out of each hand, straight ahead
             (dolist (h (list v w))
               (let* ((x (aref h 0)) (y (aref h 1)) (z (aref h 2)) (hf (fwd x z)) (l (* k (- d hf))))
                 (when (> l 0.05) (sj-seg :sj-pin x y z (+ x (* l fx)) y (+ z (* l fz)) 0.016)))))
            (:loop                                     ; MATSURI: a loop of thread whipped up from the needle and down
             (joint-point! v jm (ji :weapon-r) 0f0 0f0 -1.2f0)           ; ahead at him (two strands)
             (let* ((x0 (aref v 0)) (y0 (aref v 1)) (z0 (aref v 2)) (r (* k d)) (ex (+ cx (* r fx))) (ez (+ cz (* r fz)))
                    (mx (* 0.5 (+ x0 ex))) (my (+ (max y0 2.2) 0.5)) (mz (* 0.5 (+ z0 ez))))
               (dotimes (strand 2)
                 (let ((px x0) (py y0) (pz z0) (lx (* strand 0.06 (- fz))) (lz (* strand 0.06 fx)))
                   (loop for i from 1 to 10
                         do (let* ((u (/ i 10.0)) (a (* (- 1 u) (- 1 u))) (b (* 2 u (- 1 u))) (c (* u u))
                                   (qx (+ (* a x0) (* b mx) (* c ex) (* u lx))) (qy (+ (* a y0) (* b (- my (* 0.1 strand))) (* c 0.6)))
                                   (qz (+ (* a z0) (* b mz) (* c ez) (* u lz))))
                              (sj-thread px py pz qx qy qz (* 0.95 k) 0.011 (float (+ i (* 10 strand))))
                              (setf px qx py qy pz qz)))))))
            (:stakes                                   ; KUKE: five pins slammed down round his feet, threads from the hands
             (let ((drop (if (< sf (mv-s mv)) (* 1.2 (- 1.0 k)) 0.0)) (a (if (< sf (mv-s mv)) 1.0 k)))
               (dotimes (i 5)
                 (multiple-value-bind (dx dz) (turned (* 20 (- i 2)))
                   (let* ((r (* d (if (evenp i) 1.0 0.75))) (x (+ cx (* r dx))) (z (+ cz (* r dz))) (h (if (evenp i) v w)))
                     (sj-prop :sj-stake x drop z :alpha a)
                     (sj-thread (aref h 0) (aref h 1) (aref h 2) x (+ 0.8 drop) z (* 0.9 a) 0.006 (float i)))))))
            (:bolt                                     ; TANMONO-UCHI: a bolt of cloth flung straight out from both hands
             (let* ((x (* 0.5 (+ (aref v 0) (aref w 0)))) (y (* 0.5 (+ (aref v 1) (aref w 1)))) (z (* 0.5 (+ (aref v 2) (aref w 2))))
                    (l (* k (- d (fwd x z)))))
               (when (> l 0.05) (sj-seg :sj-strip x y z (+ x (* l fx)) y (+ z (* l fz)) 2.6))))
            (:wrap                                     ; MAKITORI: a cloth from each hand down to his feet
             (loop for h in (list v w) for s in '(-10 10)
                   do (multiple-value-bind (dx dz) (turned s)
                        (let ((r (max (fwd (aref h 0) (aref h 2)) (* k d))))
                          (sj-seg :sj-strip (aref h 0) (aref h 1) (aref h 2) (+ cx (* r dx)) 0.35 (+ cz (* r dz)) 1.6)))))))))))

(defun sj-stitches-on (o n)
  "N red threads standing out of opponent O's torso: the stitches she has sewn into his clothes (a look, from her meter)."
  (let* ((m (model o)) (jm (model-joints m)) (v *sj-p*) (yaw (yaw-of o)))
    (joint-point! v jm (ji :chest) 0f0 0.1f0 0f0)
    (dotimes (i n)
      (let* ((a (+ yaw (* i 1.047) 0.5)) (x (aref v 0)) (y (+ (aref v 1) (* 0.08 (- i 2.5)))) (z (aref v 2)))
        (sj-thread x y z (+ x (* 0.28 (sin a))) (- y 0.12) (+ z (* 0.28 (cos a))) 0.95 0.005 (float i))))))

(declaim (special *cam-eye* *cam-at*))               ; (camera.lisp loads later)
(defparameter *sj-drape-fade* '(1.5 2.0 0.15)
  "The domain's props on the rim fade in front of the fighters (the playtest, 2026-09-29: near the rim the drapes hid them):
a prop LEAD metres or more nearer the camera than the nearer fighter is at alpha FLOOR, from there it ramps up to 1 over
RAMP metres (lead ramp floor; debug 99500+k sets the floor to k / 100).")

(defun sj-rim-alpha (x z near vx vz)
  "The alpha of a domain prop at (X Z): its depth along the camera's view (unit VX VZ, from *CAM-EYE*) against NEAR, the
nearer fighter's depth; 1 behind him (the backdrop), down to the floor in front of him (*SJ-DRAPE-FADE*)."
  (destructuring-bind (lead ramp floor) *sj-drape-fade*
    (let ((d (- (+ (* (- x (aref *cam-eye* 0)) vx) (* (- z (aref *cam-eye* 2)) vz)) near)))
      (max floor (min 1.0 (/ (+ d lead) ramp))))))

(defun sj-domain (e side)
  "The Bankai's domain (a look, §10 N12): madder drapes hung on the plaza's rim, the golden torii-loom at the rim behind
where she awakened (placed once); red threads from it to her upper hands while she weaves. The camera can stand outside
the drapes' ring (it keeps to *CAM-MAX-R* 18 m, the drapes hang at 16.8), so the ones between it and the fighters fade
(SJ-RIM-ALPHA), in every camera: landscape, the portrait / behind camera, the cinematics."
  (let* ((o (opp-of e)) (at (svref *sj-loom-at* side))
         (ex (aref *cam-eye* 0)) (ez (aref *cam-eye* 2))
         (vx (- (aref *cam-at* 0) ex)) (vz (- (aref *cam-at* 2) ez)) (vl (max 1e-3 (sqrt (+ (* vx vx) (* vz vz)))))
         (vx (/ vx vl)) (vz (/ vz vl))
         (near (flet ((depth (q) (+ (* (- (aref q 0) ex) vx) (* (- (aref q 2) ez) vz))))
                 (if (entity-alive-p o) (min (depth (pos-of e)) (depth (pos-of o))) (depth (pos-of e))))))
    (unless (and at (eql (first at) e))
      (let* ((p (pos-of e)) (q (pos-of o)) (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2)))
             (l (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (x (* 15.6 (/ dx l))) (z (* 15.6 (/ dz l))))
        (setf at (list e x z (dir-yaw (- x) (- z))) (svref *sj-loom-at* side) at)))
    (unless (and (= side 1) (entity-alive-p o) (eq (fighter-character (fighter o)) :senjumaru)
                 (kit-awakening (kit-of o)))                ; two awakened Senjumarus drape the rim once
      (dotimes (i 18)
        (let ((a (* i (/ (* 2 pi) 18))))
          (let ((x (* 16.8 (cos a))) (z (* 16.8 (sin a))))
            (sj-prop :sj-drape x 0.0 z :yaw (- (/ pi 2) a) :alpha (sj-rim-alpha x z near vx vz))))))
    (destructuring-bind (ee x z yaw) at
      (declare (ignore ee))
      (sj-prop :sj-torii x 0.0 z :yaw yaw :alpha (sj-rim-alpha x z near vx vz))
      (let ((f (fighter e)))
        (when (and (eq (fighter-state f) :move) (eq (fighter-phase f) :hold))
          (let* ((jm (model-joints (model e))) (v *sj-q*))
            (dolist (h (list (ji :hand-r) (ji :hand-l)))
              (joint-point! v jm h 0f0 -0.05f0 0f0)
              (sj-thread x 3.9 z (aref v 0) (aref v 1) (aref v 2) 0.9 0.006))))))))

(defun senju-draw (e rdt)
  "Her kit's :draw hook (after her body): the four echo arms, the needle's red thread (the Shikai), the stitches on him, the
Bankai's domain."
  (let* ((m (model e)) (f (fighter e)) (side (fighter-side f)) (o (opp-of e)))
    (when (> rdt 0) (sj-hist-push side (model-joints m)))
    (when (>= (model-alpha m) 0.999)
      (sj-echo-arms e side m rdt)
      (sj-strike-props e f)
      (when (eq (fighter-form f) :base) (sj-needle-thread e m)))
    (when (and (entity-alive-p o) (eq (fighter-form f) :base) (plusp (round (gauges-meter (gauges e)))))
      (sj-stitches-on o (round (gauges-meter (gauges e)))))
    (when (kit-awakening (fighter-kit f)) (sj-domain e side))))

;;; ---------------------------------------------------------------- the Bankai's aura (the see-through strips)
(defun senju-aura-tsuji (x y z h k dt)
  "SHIGARAMI NO TSUJI: loose madder strips and red threads drifting round her at alpha 0.45 (the see-through aura rule)."
  (declare (ignore dt))
  (let ((tm (fx-clock)))
    (dotimes (i 6)
      (let* ((a (+ (* i 1.047) (* 0.35 tm))) (r (+ 0.65 (* 0.15 (sin (+ tm i))))) (hh (+ 0.3 (* 0.2 i))))
        (sj-prop :sj-strip (+ x (* r (cos a))) (+ y hh (* 0.1 (sin (* 2 (+ tm i))))) (+ z (* r (sin a)))
                 :yaw (- (/ pi 2) a) :roll (* 0.3 (sin (+ tm (* 2 i)))) :s 0.5 :alpha (* 0.45 k))))
    (dotimes (i 3)
      (let ((a (+ (* i 2.09) (* -0.5 tm))))
        (sj-thread (+ x (* 0.5 (cos a))) (+ y 0.2) (+ z (* 0.5 (sin a)))
                   (+ x (* 0.8 (cos (+ a 0.8)))) (+ y (* 0.8 h)) (+ z (* 0.8 (sin (+ a 0.8)))) (* 0.6 k) 0.004 (float i))))))

;;; ---------------------------------------------------------------- the hazards' looks (HAZARD-DRAW: (fn hz rdt))
(defun senju-spike-look (hz rdt)
  "悪い癖: a spike bursting out of his clothes (drawn on its hit frame): a fan of white-gold needles."
  (declare (ignore rdt))
  (when (and (<= (hazard-delay hz) 0) (<= (hazard-age hz) 1))
    (let ((x (hazard-x hz)) (z (hazard-z hz)))
      (dotimes (i 5)
        (let ((a (+ (* i 1.2566) (* 0.4 (hazard-life hz)))))
          (with-floats (x z a)
            (fx-shard x (+ 1.0f0 (* 0.1f0 (i->f i))) z (f-cos a) 0.3f0 (f-sin a) 0.5f0 0.03f0 0.05f0 (i->f i) +pal-hit+ 0.95f0)))))))

(defun senju-tapestry-look (hz rdt)
  "神兵: the tapestry drops (8 f) and fades."
  (declare (ignore rdt))
  (let* ((age (hazard-age hz)) (y (* 2.5 (max 0.0 (- 1.0 (/ age 8.0))))) (a (min 1.0 (/ (- (hazard-life hz) age) 12.0))))
    (sj-prop :sj-tapestry (hazard-x hz) y (hazard-z hz) :yaw (hazard-yaw hz) :alpha a)))

(defun senju-soldier-look (hz rdt)
  "The Divine Soldier: its body posed by its own animation (1.9 m, faceless, the spear), fading in and out."
  (declare (ignore rdt))
  (let* ((d (hazard-data hz)) (m (sjh-model d)) (b (model-body m))
         (a (min 1.0 (/ (hazard-age hz) 8.0) (/ (- (hazard-life hz) (hazard-age hz)) 10.0)
                 (if (eq (sjh-phase d) :fade) (max 0.0 (- 1.0 (/ (sjh-clock d) 30.0))) 1.0))))
    (pose-fk! (model-joints m) (anim-eval (model-anim m)) (hazard-x hz) 0f0 (hazard-z hz) (hazard-yaw hz)
              (body-scale b) (body-hunch b) (body-props b))
    (draw-body b (model-joints m) (hazard-x hz) 0.0 (hazard-z hz) (hazard-yaw hz) :weapon :sj-spear :alpha (f32 (max 0.0 a)))))

(defun senju-burst-look (hz rdt)
  "The soldier bursting into red thread and cloth scraps (it sews one stitch into him)."
  (when (<= (hazard-age hz) 1)
    (let ((x (hazard-x hz)) (z (hazard-z hz)))
      (with-floats (x z rdt)
        (dotimes (i (n-of 600f0 rdt))
          (let ((a (rnd-range 0f0 6.2832f0)) (sp (rnd-range 1f0 4f0)))
            (declare (single-float a sp))
            (%t-shard x (rnd-range 0.3f0 1.8f0) z (* sp (f-cos a)) (rnd-range 0.5f0 2.5f0) (* sp (f-sin a)) (rnd-range 0.4f0 0.8f0)
                      (rnd-range 0.04f0 0.09f0) 3f0 +pal-ash+)))
        (dotimes (i 8)
          (let ((a (* i 0.785)))
            (sj-thread x 1.0 z (+ x (* 1.4 (cos a))) (+ 1.0 (* 0.6 (sin (* 3 a)))) (+ z (* 1.4 (sin a))) 0.9 0.006 (float i))))))))

(defun senju-kasa-look (hz rdt)
  "傘: a canopy of red thread strung over her from the six hands (its ribs are the arms)."
  (declare (ignore rdt))
  (let* ((e (hazard-owner hz)))
    (when (entity-alive-p e)
      (let* ((jm (model-joints (model e))) (side (fighter-side (fighter e))) (v *sj-p*) (p (pos-of e))
             (cx (aref p 0)) (cy 2.3) (cz (aref p 2)) (k (min 0.95 (/ (- (hazard-life hz) (hazard-age hz)) 6.0))))
        (dolist (h (list (ji :hand-r) (ji :hand-l)))
          (joint-point! v jm h 0f0 -0.06f0 0f0)
          (sj-thread cx cy cz (aref v 0) (aref v 1) (aref v 2) k 0.008))
        (dotimes (i 4)
          (let ((o (+ (* side 12) (* 3 i))))
            (sj-thread cx cy cz (aref *sj-echo* o) (aref *sj-echo* (+ o 1)) (aref *sj-echo* (+ o 2)) k 0.008 (float i))))
        (with-floats (cx cz k) (%tring cx 1.5f0 cz 1.1f0 0.02f0 +pal-blood+ (* 0.5f0 k) 3f0 24))))))

(defun senju-tendril-look (hz rdt)
  "傘's tendrils: red-cored ink strands lashing along the ground at him, as wide as their hit box."
  (declare (ignore rdt))
  (when (and (<= (hazard-delay hz) 0) (< (hazard-age hz) (hazard-life hz)))
    (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (hw (hazard-size hz))
           (px (- (fwd-z yaw))) (pz (fwd-x yaw)) (fx (fwd-x yaw)) (fz (fwd-z yaw)) (dr (drawing-no)))
      (with-floats (x z hw px pz fx fz dr)
        (dotimes (i 5)
          (let* ((u (- (* (/ (i->f i) 4f0) 2f0) 1f0)) (bx (+ x (* u hw px) (* -1.4f0 fx))) (bz (+ z (* u hw pz) (* -1.4f0 fz)))
                 (hh (+ 0.5f0 (* 0.4f0 (hash01 (+ (i->f i) dr) 2.3f0)))))
            (declare (single-float u bx bz hh))
            (toon-ribbon (bx 0.3f0 bz) ((* 1.6f0 fx) hh (* 1.6f0 fz)) (0.05f0 0.01f0) :heat (1f0 0.3f0) :seed (- -71f0 (i->f i)) :wob 0.2f0
                         :pal +pal-ink+ :k 0.9f0 :ph (+ (i->f i) dr) :sway 0.1f0 :segs 4)
            (sj-thread bx 0.35 bz (+ bx (* 1.6 fx)) (+ 0.35 hh) (+ bz (* 1.6 fz)) 0.95 0.006 (i->f i))))))))

(defun senju-pin-look (hz rdt)
  "縫地: threads shoot from above into the plaza round his feet, sewing him to the ground."
  (declare (ignore rdt))
  (let ((x (hazard-x hz)) (z (hazard-z hz)) (k (min 0.95 (/ (- (hazard-life hz) (hazard-age hz)) 10.0))))
    (dotimes (i 6)
      (let ((a (* i 1.047)))
        (sj-thread x 1.8 z (+ x (* 0.55 (cos a))) 0.02 (+ z (* 0.55 (sin a))) k 0.006 (float i))))))

(defun senju-carpet-look (hz rdt)
  "浮文機: the red carpet unrolling along the lane (1 m per 2 f), fading at the end."
  (declare (ignore rdt))
  (let* ((n (min (floor (hazard-size hz)) (floor (hazard-age hz) 2))) (yaw (hazard-yaw hz))
         (a (min 1.0 (/ (- (hazard-life hz) (hazard-age hz)) 10.0))))
    (dotimes (i n)
      (sj-prop :sj-carpet (+ (hazard-x hz) (* (+ i 0.5) (fwd-x yaw))) 0.012 (+ (hazard-z hz) (* (+ i 0.5) (fwd-z yaw)))
               :yaw yaw :pitch (- (/ pi 2)) :alpha a :feet -2.0))))

(defun senju-bolt-look (hz rdt)
  "The weave: a bolt of the hank's dye growing between her hands, a fold per pass."
  (declare (ignore rdt))
  (let ((e (hazard-owner hz)))
    (when (entity-alive-p e)
      (let* ((d (hazard-data hz)) (jm (model-joints (model e))) (v *sj-p*) (w *sj-q*)
             (p (max 1 (senju-stored e))))
        (joint-point! v jm (ji :hand-r) 0f0 -0.06f0 0f0)
        (joint-point! w jm (ji :hand-l) 0f0 -0.06f0 0f0)
        (let* ((mx (* 0.5 (+ (aref v 0) (aref w 0)))) (my (* 0.5 (+ (aref v 1) (aref w 1)))) (mz (* 0.5 (+ (aref v 2) (aref w 2))))
               (yaw (yaw-of e)) (l (* 0.3 (+ 1 p))))
          (sj-seg (svref *sj-bolt-keys* (sjh-hank d))
                  (- mx (* l (cos yaw))) my (+ mz (* l (sin yaw))) (+ mx (* l (cos yaw))) my (- mz (* l (sin yaw)))
                  (+ 0.8 (* 0.25 p))))))))

(defun sj-ring-props (key x z r n y &key (tilt 0.0) (alpha 1.0) (s 1.0))
  "N props KEY standing round a circle of radius R at (X Z), facing its centre, TILT toward it."
  (dotimes (i n)
    (let ((a (* i (/ (* 2 pi) n))))
      (sj-prop key (+ x (* r (cos a))) y (+ z (* r (sin a))) :yaw (dir-yaw (- (cos a)) (- (sin a))) :pitch tilt :alpha alpha :s s))))

(defun senju-zone-look (hz rdt)
  "The six hanks' zones: every one first unfolds (its cloth unrolling onto its shape, 20 f), then 眼's mirror-eyes, 刃金's
rising gold sheets closing, 黒砂's black spiral and its swirl before each gulp, 褥's snowflake bed, 焼野原's burning cloth
procession with ink trees, 星's night-blue dome with a white star."
  (declare (ignore rdt))
  (let* ((d (hazard-data hz)) (n (sjh-hank d)) (x (hazard-x hz)) (z (hazard-z hz)) (r (sjh-r d))
         (unfold (max 1 (or (sjh-phase d) 20))) (u (if (plusp (hazard-delay hz)) (- 1.0 (/ (hazard-delay hz) (float unfold))) 1.0))
         (left (- (hazard-life hz) (hazard-age hz))) (k (min 1.0 (/ (max 0 left) 15.0))) (age (hazard-age hz))
         (cloth (svref *sj-cloth-keys* n)) (tm (fx-clock)))
    (when (plusp (hazard-delay hz))                       ; the unfold: the bolt rolling out across its shape
      (sj-seg (svref *sj-bolt-keys* n) (- x (* r u)) 0.1 (- z (* 0.9 r)) (- x (* r u)) 0.1 (+ z (* 0.9 r)) 1.0))
    (case n
      (5 (let* ((yaw (hazard-yaw hz)) (len (sjh-len d)) (hw (hazard-size hz)) (fx (fwd-x yaw)) (fz (fwd-z yaw)))
           (sj-prop cloth x 0.012 z :yaw yaw :sx hw :sy 1.0 :sz (* 0.5 len u) :alpha k :feet -2.0)
           (when (<= (hazard-delay hz) 0)
             (loop for s from 0.5 below len by 1.2
                   do (dolist (side '(1.0 -1.0))
                        (let ((bx (+ x (* (- s (* 0.5 len)) fx) (* side hw (- fz)))) (bz (+ z (* (- s (* 0.5 len)) fz) (* side hw fx))))
                          (sj-prop :sj-strip bx 0.0 bz :yaw yaw :s 1.1 :roll (* 0.12 (sin (+ tm s))) :alpha k)
                          (with-floats (bx bz k s)
                            (%tongue bx 1.0f0 bz 0f0 0.5f0 0f0 0.09f0 +pal-fire+ (* 0.9f0 k) (+ s (drawing-no)) s 0.05f0 :segs 4)))))
             (loop for s from 1.2 below len by 3.0
                   do (sj-prop :sj-tree (+ x (* (- s (* 0.5 len)) fx) (* 1.5 hw (- fz))) 0.0 (+ z (* (- s (* 0.5 len)) fz) (* 1.5 hw fx))
                               :yaw yaw :alpha k)))))
      (t
       (unless (= n 6) (sj-prop cloth x 0.012 z :s (* r u) :sy 1.0 :alpha k :feet -2.0))
       (when (<= (hazard-delay hz) 0)
         (case n
           (1 (let ((flash (< (- tm (sjh-look-t d)) 0.25)))   ; eight mirror-eyes round the ring; one flashes on a reflection
                (sj-ring-props :sj-mirror x z (* 0.95 r) 8 0.0 :alpha k :s (if flash 1.15 1.0))
                (with-floats (x z r k) (%tring x 0.02f0 z r 0.05f0 +pal-soul+ (* 0.8f0 k) 5f0 40))))
           (2 (let* ((rise (hank 2 :rise)) (up (min 1.0 (/ age (float rise))))
                     (close (if (>= age rise) (min 1.0 (/ (- age rise) 4.0)) 0.0)))
                (sj-ring-props :sj-sheet x z (* 0.92 r) 8 (* -1.9 (- 1.0 up)) :tilt (* -0.9 close) :alpha k)))
           (3 (let ((swirl (< (- tm (sjh-look-t d)) 0.2)))
                (dotimes (i 10)
                  (let* ((a0 (+ (* i 0.628) (* (if swirl 6.0 1.2) tm))) (a1 (+ a0 0.9)) (r0 (* r 0.2)) (r1 (* r 0.9)))
                    (with-floats (x z a0 a1 r0 r1 k)
                      (toon-ground-seg (+ x (* r0 (f-cos a0))) (+ z (* r0 (f-sin a0))) (+ x (* r1 (f-cos a1))) (+ z (* r1 (f-sin a1)))
                                       0.03f0 0.05f0 1f0 0.4f0 (+ 90f0 (i->f i)) 0.2f0 (toon-a +pal-dust+ (* 0.8f0 k))))))))
           (4 (with-floats (x z r k tm)
                (%tring x 0.02f0 z r 0.06f0 +pal-soul+ (* (+ 0.6f0 (* 0.3f0 (f-sin (* 5f0 tm)))) k) 7f0 40)))
           (6 (sj-prop :sj-dome x 0.0 z :sx r :sy (* 0.65 r) :sz r :alpha (* 0.35 k))
              (sj-prop :sj-star x (+ 0.3 (* 0.65 r)) z :yaw (* 0.5 tm) :s 1.2 :alpha k)
              (with-floats (x z r k) (%tring x 0.02f0 z r 0.05f0 +pal-hit+ (* 0.7f0 k) 3f0 48)))))))))

;;; ---------------------------------------------------------------- the cinematics' looks (cosmetic)
(defun vfx-sj-candle (x y z lit)
  "A candle on a gold dish before her; LIT: its small flame."
  (sj-prop :sj-candle x y z)
  (when lit
    (with-floats (x y z)
      (%tongue x (+ y 0.25f0) z 0f0 0.12f0 0f0 0.025f0 +pal-fire+ 0.9f0 (drawing-no) 0f0 0.01f0 :segs 3))))

(defun vfx-sj-needle-burst (x y z age)
  "Dozens of needles bursting outward from inside the garment (the bad habit), AGE 0..1."
  (with-floats (x y z age)
    (dotimes (i 28)
      (let* ((f (i->f i)) (a (* f 0.2244f0)) (e (+ -0.5f0 (hash01 f 3.7f0))) (d (* (+ 0.2f0 (* 1.2f0 age)) (+ 0.6f0 (hash01 f 1.1f0)))))
        (declare (single-float f a e d))
        (fx-shard (+ x (* d (f-cos a))) (+ y (* d e)) (+ z (* d (f-sin a))) (f-cos a) e (f-sin a) 0.35f0 0.02f0 0.05f0 (+ f 100f0)
                  +pal-hit+ (f-clamp (- 1.2f0 age) 0.05f0 0.95f0))))))

(defun vfx-sj-threads (x y z age)
  "Red threads zig-zagging over a body (the tailoring), AGE 0..1 of the stitching."
  (dotimes (i (min 12 (floor (* 14 age))))
    (let ((a (* i 0.9)) (b (* (1+ i) 0.9)))
      (sj-thread (+ x (* 0.3 (cos a))) (+ y (* 0.1 i) -0.4) (+ z (* 0.3 (sin a)))
                 (+ x (* 0.3 (cos b))) (+ y (* 0.1 i) -0.3) (+ z (* 0.3 (sin b))) 0.95 0.005 (float i)))))

(defun vfx-sj-wrap (x z top n)
  "A bolt of hank N's dye wrapping a figure at (X Z) from the feet to TOP metres."
  (when (> top 0.05)
    (sj-seg (svref *sj-bolt-keys* (max 1 (min 6 n))) x 0.0 z x (/ top 0.6) z 4.6)))   ; (the bolt fills 0.6 of it)

(defun vfx-sj-carpet (x z yaw len)
  "The red carpet from (X Z) along YAW, LEN metres."
  (dotimes (i (floor len))
    (sj-prop :sj-carpet (+ x (* (+ i 0.5) (fwd-x yaw))) 0.012 (+ z (* (+ i 0.5) (fwd-z yaw))) :yaw yaw :pitch (- (/ pi 2)) :feet -2.0)))

;;; ---------------------------------------------------------------- her six sounds (synthesized at startup; sounds.lisp's toolkit)
(defsound :thread-zip (:peak 0.6)                     ; a fast thread pull: a rising filtered hiss with a taut tick
  (let ((b (au-buf 0.35)))
    (au-mix! b (au-whoosh 0.18 2500 9000 :q 3.0 :peak 0.05) 0.0 0.8)
    (au-ping! b 0.16 3950 0.03 0.4 :attack 0.001)
    (au-mix! b (au-fnoise 0.03 :hp 6000 :decay 0.01) 0.17 0.5)
    b))

(defsound :needle-burst (:peak 0.9)                   ; a dense metallic spray (L's spikes, the Kikon's bad habit)
  (let ((b (au-buf 0.9)))
    (dotimes (i 30)
      (au-ping! b (au-rrange 0.0 0.25) (au-rrange 3500 9000) (au-rrange 0.02 0.08) (* 0.35 (- 1.0 (/ i 34.0))) :attack 0.001))
    (au-mix! b (au-fnoise 0.12 :hp 4000 :decay 0.05) 0.0 0.7)
    (au-thump! b 0.0 160 70 0.04 0.1 0.5)
    (au-reverb! b 0.25)))

(defsound :shuttle (:peak 0.7)                        ; a wooden loom clack (each weave pass)
  (let ((b (au-buf 0.4)))
    (au-mix! b (au-fnoise 0.03 :bp 900 :q 4 :decay 0.012) 0.0 1.0)
    (au-thump! b 0.0 420 240 0.02 0.05 0.7)
    (au-mix! b (au-fnoise 0.02 :bp 1600 :q 5 :decay 0.008) 0.06 0.5)
    (au-reverb! b 0.12 :size 0.6)))

(defsound :cloth-unfurl (:peak 0.8)                   ; a heavy cloth whoosh (every unfold, the carpet)
  (let ((b (au-buf 0.9)))
    (au-mix! b (au-whoosh 0.6 180 2200 :q 0.9 :peak 0.25) 0.0 0.9)
    (dotimes (i 6) (au-mix! b (au-fnoise 0.05 :bp (au-rrange 400 1200) :q 2 :decay 0.03) (+ 0.1 (* 0.07 i)) 0.35))
    (au-thump! b 0.5 90 50 0.06 0.15 0.5)
    (au-reverb! b 0.2)))

(defsound :shears (:peak 0.85)                        ; a heavy snip (SAIDAN, the skip, the Kikon's cut, a torn hank)
  (let ((b (au-buf 0.6)))
    (au-mix! b (au-fnoise 0.08 :bp 3200 :q 2 :decay 0.03) 0.0 0.6)
    (au-partials! b 0.07 '((1900 0.4 0.2) (3100 0.3 0.15) (5200 0.2 0.1)))
    (au-thump! b 0.07 200 90 0.02 0.08 0.7)
    (au-reverb! b 0.2)))

(defsound :candle-out (:peak 0.6)                     ; a soft puff with a low bell tail (the awakening's candles)
  (let ((b (au-buf 1.6)))
    (au-mix! b (au-fnoise 0.15 :lp 1200 :attack 0.02 :decay 0.08) 0.0 0.7)
    (au-gong! b 0.08 196 0.35 1.3)
    (au-reverb! b 0.4 :size 1.4)))

;;; her extra brush glyphs (三 四 神 裁 live in glyphs.lisp): glyphs-extra.lisp
