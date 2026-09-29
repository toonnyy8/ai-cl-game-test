;;;; senjumaru-art.lisp — SHUTARA SENJUMARU as art data (docs/DUEL_SENJUMARU.md §2, §10): her body (158 cm on tall okobo,
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
;; 刺絡 SHIGARAMI: a white-gold sewing needle as tall as she is, 1.8 m (1.58 m at her scale; 0.9 until the playtest: her J
;; reach is its tip),
;; the eye just behind her fist (the red thread runs from it: SENJU-DRAW)
(defweapon :shigarami (:length 1.8 :base 0.1)
  (:solid (mbc mb #xEDE6D0)
          (with-xform (mb (xform :y 0.87)) (mb-cylinder mb 0.016 1.74 :segments 6 :top-radius 0.005))
          (with-xform (mb (xform :y 1.77)) (mb-cone mb 0.005 0.05 :segments 4))
          (mbc mb #xC2A866)
          (with-xform (mb (xform :y -0.03)) (mb-box mb 0.026 0.05 0.012))
          (mbc mb #x16161E)
          (with-xform (mb (xform :y -0.035)) (mb-box mb 0.012 0.03 0.014))))
(defweapon :sj-spear (:length 1.6)
  (:solid (mbc mb #x5A4034) (with-xform (mb (xform :y 0.4)) (mb-cylinder mb 0.022 1.9 :segments 6))
          (mbc mb #xB89A5A) (with-xform (mb (xform :y 1.4)) (mb-box mb 0.05 0.05 0.05))
          (mbc mb #xD8DCE4) (with-xform (mb (xform :y 1.55)) (mb-cone mb 0.04 0.26 :segments 4))))

;;; ---------------------------------------------------------------- props (drawn with DRAW-WEAPON at a world matrix)
(defparameter *sj-dye-hex* '(#x6A5A7E #xA8904E #x22222A #x5E7890 #x7E3A34 #x2E3656) "The hanks' dyes (S <= 0.45).")
(defun sj-dye-hex (n) (nth (1- n) *sj-dye-hex*))

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
rolled bolt of it: the weave, the wrap, the hanging bolts)."
  `(progn
     ,@(loop for n from 1 to 6 for hex in '(#x6A5A7E #xA8904E #x22222A #x5E7890 #x7E3A34 #x2E3656)   ; (*SJ-DYE-HEX*)
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
  (:root :f 0.32 :u -0.05) (:pelvis :twist 18) (:chest :twist 16) (:neck :twist -12) (:head :twist -10)
  (:arm-r :flex 92 :side 4) (:elbow-r :flex 2) (:hand-r :twist 0 :flex -90)
  (:arm-l :flex 20 :side 60) (:elbow-l :flex 40)
  (:thigh-r :flex 20) (:knee-r :flex 20) (:thigh-l :flex -8) (:knee-l :flex 8))
(defstrike :sj-q1 (7 3 12 :base :sj-stance)
  (0)
  (3 (:chest :twist -14) (:arm-r :flex 60 :side 10) (:elbow-r :flex 110) (:hand-r :flex -80) (:root :u -0.03))
  (:s :snap :sj-q1-hit)
  (:a (:root :f 0.34) (:arm-r :flex 93))
  (16 (:root :f 0.1) (:arm-r :flex 70 :side 18) (:elbow-r :flex 60) (:hand-r :flex -50) (:chest :twist 4))
  (:end :sj-stance))

;; J2 KAESHINUI: the backstitch: the needle drawn back across him, the thread taut
(defpose :sj-q2-hit (:base :sj-stance)
  (:root :f 0.28 :u -0.05 :yaw -8) (:pelvis :twist 16) (:chest :twist -22) (:neck :twist 10) (:head :twist 6)
  (:arm-r :side 86 :flex 30) (:elbow-r :flex 10 :twist 140) (:hand-r :twist 0 :flex -84)
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
  (:s :snap (:root :yaw 330 :u -0.02 :f 0.2) (:chest :twist 10) (:arm-r :side 88 :flex 40) (:elbow-r :flex 0) (:hand-r :flex -88)
      (:arm-l :side 88 :flex 40) (:elbow-l :flex 0) (:hand-l :flex -60))
  (:a (:root :yaw 360 :f 0.22) (:chest :twist 14))
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
      (:hand-l :flex -80) (:root :f 0.3 :u -0.08) (:spine :flex 10))
  (:a (:root :f 0.32))
  (24 (:root :f 0.14) (:arm-r :flex 70 :side 20) (:elbow-r :flex 50) (:arm-l :flex 40 :side 40) (:elbow-l :flex 50))
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
    (fx-ribbon ax ay az (- bx ax) (- by ay) (- bz az) w (* 0.7f0 w) 1f0 (- -60f0 seed) 0.02f0 (toon-a +pal-blood+ k)
               0.8f0 (- -60f0 seed) 0.02f0 (toon-a +pal-blood+ k) seed 0f0 :segs 2 :mode :toon)))

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

;; the K links' props (the user's playtest, 2026-09-29: the reach matches the art; docs/DUEL_SENJUMARU.md "Playtest"):
;; each is out to its move's hit-volume far edge at the hit frames. The host test (duel-rules-test) checks these against
;; the volumes, and the J links' needle tip against theirs
(defparameter *sj-strike-reach*
  '((:sj-f1 :pins 3.5) (:sj-f2 :loop 2.8) (:sj-drop :stakes 2.8) (:sj-tanmono :bolt 4.5) (:sj-makitori :wrap 2.8))
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
             (joint-point! v jm (ji :weapon-r) 0f0 0f0 -1.8f0)           ; ahead at him (two strands)
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

(defun sj-domain (e side)
  "The Bankai's domain (a look, §10 N12): madder drapes hung on the plaza's rim, the golden torii-loom at the rim behind
where she awakened (placed once); red threads from it to her upper hands while she weaves."
  (let ((o (opp-of e)) (at (svref *sj-loom-at* side)))
    (unless (and at (eql (first at) e))
      (let* ((p (pos-of e)) (q (pos-of o)) (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2)))
             (l (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (x (* 15.6 (/ dx l))) (z (* 15.6 (/ dz l))))
        (setf at (list e x z (dir-yaw (- x) (- z))) (svref *sj-loom-at* side) at)))
    (unless (and (= side 1) (entity-alive-p o) (eq (fighter-character (fighter o)) :senjumaru)
                 (kit-awakening (kit-of o)))                ; two awakened Senjumarus drape the rim once
      (dotimes (i 18)
        (let ((a (* i (/ (* 2 pi) 18))))
          (sj-prop :sj-drape (* 16.8 (cos a)) 0.0 (* 16.8 (sin a)) :yaw (- (/ pi 2) a)))))
    (destructuring-bind (ee x z yaw) at
      (declare (ignore ee))
      (sj-prop :sj-torii x 0.0 z :yaw yaw)
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
            (fx-ribbon bx 0.3f0 bz (* 1.6f0 fx) hh (* 1.6f0 fz) 0.05f0 0.01f0 1f0 (- -71f0 (i->f i)) 0.2f0 (toon-a +pal-ink+ 0.9f0)
                       0.3f0 (- -71f0 (i->f i)) 0.2f0 (toon-a +pal-ink+ 0.9f0) (+ (i->f i) dr) 0.1f0 :segs 4 :mode :toon)
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
          (sj-seg (intern (format nil "SJ-BOLT-~d" (sjh-hank d)) :keyword)
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
         (cloth (intern (format nil "SJ-CLOTH-~d" n) :keyword)) (tm (fx-clock)))
    (when (plusp (hazard-delay hz))                       ; the unfold: the bolt rolling out across its shape
      (sj-seg (intern (format nil "SJ-BOLT-~d" n) :keyword) (- x (* r u)) 0.1 (- z (* 0.9 r)) (- x (* r u)) 0.1 (+ z (* 0.9 r)) 1.0))
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
    (sj-seg (intern (format nil "SJ-BOLT-~d" (max 1 (min 6 n))) :keyword) x 0.0 z x (/ top 0.6) z 4.6)))   ; (the bolt fills 0.6 of it)

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

;;; ---------------------------------------------------------------- her brush glyphs (GLYPHS: baked by the scratchpad's
;;; bake.py over tools/glyph-bake.py, the same Yuji Syuku subset and licence as glyphs.lisp: the characters glyphs.lisp
;;; lacks, appended to *GLYPH-OUTLINES* before BRUSH-INIT triangulates them at load)
(setf *glyph-outlines*
      (append *glyph-outlines*
              '(
                (20181 1000 (979 480 970 484 830 476 691 484 683 547 679 715 673 787 761 786 790 781 821 770 862 774 950 824 963 847 959 854 892 856 711 848 629 851 532 862 476 879 451 890 430 882 421 883 362 841 340 813 398 802 534 796 605 788 602 738 611 717 602 695 604 682 610 673 602 622 597 492 499 502 461 511 432 526 423 520 392 520 395 509 358 500 354 489 332 470 326 459 328 446 345 444 593 421 599 362 592 217 551 122 606 129 641 146 676 172 720 218 707 252 694 305 683 406 688 411 712 416 764 416 795 413 858 399 890 400 921 409 944 422 974 447 982 459 983 469) (402 197 399 216 390 234 351 282 332 336 281 423 299 458 302 470 295 488 302 501 297 604 300 902 296 957 281 956 258 945 223 909 204 894 205 887 217 873 228 771 233 616 229 512 133 631 70 696 20 692 13 684 10 673 54 626 135 510 178 455 197 403 272 274 284 239 285 209 272 187 240 148 248 140 249 134 290 131 329 139 366 156 399 179)) ; 仕
                (31435 1000 (906 859 896 866 883 868 799 849 747 842 578 836 426 844 320 856 257 870 180 900 158 888 112 843 93 803 83 767 144 788 175 795 348 775 321 695 318 678 324 646 291 471 278 431 261 400 272 395 294 400 360 448 374 490 388 548 403 641 410 734 421 769 582 765 605 694 622 610 632 525 636 429 633 404 618 371 619 353 500 356 382 364 305 376 228 396 171 328 152 283 159 276 226 293 262 296 466 283 463 185 410 150 381 136 390 111 417 114 424 102 438 99 482 104 514 113 539 129 546 141 547 164 538 187 524 272 646 271 686 265 726 252 802 281 829 297 849 322 817 341 664 353 728 409 749 447 722 524 690 686 676 724 658 761 734 762 754 758 761 751 822 766 882 790 912 818 922 838)) ; 立
                (30452 1000 (818 408 797 430 750 427 746 505 665 535 653 504 647 431 638 410 630 402 619 398 587 396 436 422 434 490 514 482 562 483 603 494 635 521 431 547 428 600 453 603 537 587 560 589 610 612 641 642 426 660 424 724 656 712 651 613 659 604 662 592 665 535 746 505 756 652 755 707 744 764 722 811 714 807 704 811 696 806 665 769 643 761 547 767 435 784 425 805 382 795 349 774 332 744 328 725 341 707 351 665 350 636 340 612 354 593 360 562 355 514 342 495 351 484 354 474 350 463 337 445 291 414 312 402 319 395 322 382 353 370 462 364 509 354 506 299 504 286 398 298 371 306 338 274 291 194 304 190 329 191 406 217 445 224 473 223 503 215 504 187 500 164 463 73 465 46 504 57 540 72 569 94 581 107 595 132 600 156 595 199 680 196 745 201 781 218 801 237 783 264 593 274 577 295 563 349 582 352 618 348 658 327 698 327 734 337 769 352 799 372 817 394) (914 901 886 906 766 887 682 882 537 891 355 912 335 913 328 906 296 917 264 935 230 943 186 936 167 926 87 861 99 842 163 848 183 856 188 840 185 820 189 823 190 811 188 745 192 696 187 685 186 635 176 556 178 506 166 476 134 429 129 418 128 392 205 408 217 415 217 426 238 425 257 450 268 454 256 654 245 715 253 732 250 737 247 730 239 764 238 833 245 844 340 842 587 822 715 821 739 812 750 803 824 822 876 840 909 857 935 882)) ; 直
                (12375 1000 (784 850 767 873 736 884 708 898 649 901 566 893 517 878 496 868 479 854 440 806 421 771 407 732 393 653 390 537 400 248 394 191 377 137 380 133 396 133 425 145 472 176 510 220 522 254 521 281 503 317 493 365 474 586 478 682 487 723 504 762 532 794 561 810 578 815 636 819 787 800 814 802 829 816)) ; し
                (20986 1000 (872 346 858 367 848 403 835 527 829 546 806 560 766 545 732 513 602 510 546 514 538 798 586 803 696 796 737 803 745 756 742 719 690 591 712 591 746 608 766 607 786 622 824 637 845 651 851 661 852 680 838 704 834 720 828 859 819 898 811 914 786 915 748 904 736 877 719 858 705 853 666 851 476 865 360 878 292 894 276 917 253 918 212 910 194 902 129 854 160 850 179 854 193 830 200 798 202 762 195 712 161 651 158 628 202 635 235 648 253 661 288 694 282 762 282 819 334 818 465 808 469 728 463 514 307 535 285 551 261 556 217 547 134 503 159 492 190 489 194 414 186 368 142 300 136 273 175 275 215 285 251 303 276 330 267 472 319 472 459 460 455 309 441 214 361 106 415 103 473 112 524 137 549 167 558 186 549 271 543 456 584 458 694 450 733 455 749 462 756 424 755 323 730 263 724 229 802 264 830 280 861 312 874 336)) ; 出
                (20845 1000 (914 433 877 440 739 425 690 424 529 430 361 444 275 456 230 470 180 494 159 498 140 486 80 410 56 392 68 368 124 380 192 381 475 356 474 304 467 262 404 223 379 197 411 175 445 165 471 168 515 186 538 205 549 225 541 285 527 288 521 297 499 355 581 349 735 347 738 346 735 338 738 336 799 333 838 341 874 356 911 379 943 412) (831 867 809 874 785 871 754 825 703 716 675 682 662 648 607 577 589 541 613 542 649 562 669 567 778 644 809 674 831 708 844 744 848 856) (359 664 267 809 228 852 198 870 185 872 164 866 155 867 138 847 118 844 224 737 281 643 290 621 256 555 297 550 338 560 370 580 383 593 394 625)) ; 六
                (33394 1000 (914 850 898 864 834 895 758 913 647 920 532 916 357 898 276 851 244 819 230 795 223 769 226 739 233 746 236 740 228 724 228 719 235 726 238 634 228 587 242 556 241 527 226 485 187 412 207 407 204 397 272 392 438 372 478 296 507 213 424 214 363 210 328 245 319 250 308 249 314 254 312 259 196 365 142 406 100 429 86 410 63 391 192 287 258 216 293 161 286 151 264 136 262 130 266 116 298 118 328 108 363 112 395 126 408 137 420 161 491 150 504 143 513 133 580 142 619 153 653 174 667 188 653 207 599 221 573 267 532 360 618 348 626 412 542 414 518 420 516 473 436 474 427 432 384 434 316 451 333 472 339 486 328 513 322 572 377 570 431 564 436 474 516 473 501 560 570 554 596 558 622 473 626 412 618 348 647 331 699 339 746 356 766 367 794 397 802 416 765 431 726 439 694 558 679 589 660 602 527 609 322 635 305 695 300 739 304 781 310 801 376 823 492 835 555 833 618 826 704 805 748 785 756 771 769 718 769 639 780 642 788 649 804 684 812 692 850 711 875 730 911 793 936 815)) ; 色
                (28014 1000 (757 653 684 655 683 698 694 786 694 829 680 886 650 942 621 963 596 966 566 950 479 921 449 900 426 873 392 800 520 849 559 851 578 842 596 815 606 769 607 710 602 658 448 674 402 690 374 711 351 709 331 704 299 687 273 662 239 620 259 614 268 615 307 629 423 613 589 598 584 584 566 562 509 519 492 495 552 507 605 526 639 506 685 444 644 438 623 440 505 461 497 464 484 485 465 487 431 483 403 468 358 424 378 420 427 424 447 414 400 398 360 375 340 326 312 286 400 310 435 332 462 364 470 393 470 410 661 386 717 371 779 384 831 409 863 428 851 453 800 479 729 533 674 564 668 570 668 592 763 590 799 582 825 568 888 584 930 600 965 624 989 658) (738 181 617 224 563 252 602 282 628 320 635 356 634 378 625 382 582 380 541 314 534 268 490 281 448 284 405 276 364 262 383 242 401 250 394 242 400 236 418 238 423 244 433 238 463 233 453 229 485 218 509 205 527 208 530 193 559 182 646 129 603 89 672 88 720 97 753 111 773 125 794 155) (200 528 182 523 146 503 103 459 45 381 24 359 72 365 122 378 169 398 189 411 220 438 238 468 243 503 240 522) (261 750 265 786 264 846 252 904 237 933 186 915 155 892 124 860 83 806 116 806 193 829 253 725) (838 303 807 332 768 354 702 368 713 332 751 258 749 243 731 210 769 216 787 224 853 266) (307 254 282 264 229 223 202 187 191 166 176 117 236 142 272 165 296 192 307 224 310 244)) ; 浮
                (25991 1000 (900 890 881 890 881 909 841 911 810 905 764 906 743 903 705 889 671 868 643 842 545 723 513 691 426 770 366 818 314 855 255 886 191 914 165 915 108 905 77 904 103 893 117 897 143 879 229 836 232 840 205 854 190 867 216 854 232 840 229 836 256 813 256 819 239 834 264 821 305 786 284 796 289 791 308 782 316 783 364 727 372 731 458 626 416 553 335 438 290 366 373 427 498 543 508 548 518 542 529 525 559 451 576 398 566 387 554 348 577 348 599 353 618 363 665 405 657 446 645 481 624 524 573 608 603 644 640 672 768 738 807 764 830 771 840 778 881 815 903 829 918 883) (880 324 859 327 847 333 761 326 669 324 544 328 452 335 366 346 268 366 247 364 183 395 120 329 90 282 133 278 146 272 190 285 237 288 423 269 465 268 469 256 469 221 446 202 377 160 365 138 396 124 450 120 499 132 523 150 531 161 537 182 517 257 573 258 717 250 721 247 722 235 797 242 841 255 859 265 874 278 883 295 888 315)) ; 文
                (27231 1000 (886 947 850 930 832 916 784 864 723 766 667 822 637 860 622 868 592 876 573 856 555 856 644 780 640 776 639 769 660 759 658 751 661 742 690 701 668 641 650 576 568 586 528 597 545 618 548 629 549 640 538 666 582 713 599 742 604 759 601 795 572 787 531 752 512 741 512 723 490 746 446 810 422 824 414 807 412 802 382 829 375 838 375 845 410 813 414 807 422 824 424 834 394 848 379 863 344 858 326 845 313 931 292 936 274 935 257 901 191 828 171 795 160 791 144 778 118 719 180 771 250 813 258 767 263 696 257 551 203 604 116 710 62 759 44 755 13 727 176 542 226 476 267 411 236 412 161 439 112 400 99 385 82 339 90 340 96 335 98 327 95 324 175 340 214 340 254 331 274 321 271 229 264 188 239 113 221 80 226 66 233 59 254 60 303 77 312 97 345 137 354 165 343 296 355 314 399 341 409 360 339 389 332 414 326 482 385 546 401 575 406 594 373 586 320 554 327 766 326 838 353 828 387 796 436 737 458 690 469 633 455 612 402 572 440 555 482 544 640 522 609 189 597 156 560 104 551 80 561 79 572 68 584 66 667 112 697 156 690 263 703 274 732 236 744 204 747 170 736 134 790 151 805 160 814 173 819 188 815 213 766 280 756 299 792 332 769 360 750 343 700 321 685 299 683 381 686 418 719 427 769 360 792 332 811 312 842 267 842 254 834 234 835 224 864 228 888 237 907 253 912 266 915 281 820 375 779 429 802 428 845 413 849 356 867 364 882 377 894 395 901 426 892 461 850 463 769 484 718 488 713 472 703 456 688 442 688 464 693 518 748 510 793 512 819 521 839 538 845 551 831 556 798 562 729 565 704 571 714 614 729 651 740 632 736 599 754 591 771 589 786 594 809 617 816 633 772 686 756 719 793 786 816 815 830 826 849 832 872 834 876 828 882 778 878 705 890 710 898 720 920 766 926 772 935 773 947 822 952 866 950 909 941 953) (605 484 604 490 538 498 412 529 376 490 366 461 390 462 409 475 456 424 475 393 460 376 386 326 378 316 369 292 384 290 416 303 439 272 469 195 448 163 442 141 475 148 510 163 522 175 531 191 508 248 459 324 469 332 502 353 511 341 551 281 538 248 538 235 559 240 582 252 609 277 614 299 609 319 558 371 589 405 555 445 546 385 520 412 482 465 555 445 589 405 608 435 614 479) (908 608 889 581 844 530 822 490 858 495 876 502 910 524 934 557 940 578 941 601)) ; 機
                (23057 1000 (948 684 938 694 910 700 791 677 684 677 669 698 646 756 619 784 622 795 630 800 668 807 677 814 679 827 688 829 685 821 696 820 708 835 713 831 718 832 752 856 787 867 821 893 839 918 841 932 838 949 824 952 814 962 753 936 646 873 636 860 635 852 610 855 584 845 560 869 492 911 470 931 446 928 440 935 408 938 411 944 401 951 383 950 377 945 370 955 357 950 318 946 291 935 289 938 297 942 270 936 222 911 222 907 229 904 198 890 222 892 236 898 243 907 354 899 392 889 424 875 448 858 468 835 477 821 460 814 456 804 429 810 372 799 360 802 352 809 346 825 333 830 295 835 264 790 269 783 274 763 298 759 300 753 322 744 353 690 321 690 276 696 150 728 81 671 73 661 67 639 91 634 152 649 215 635 354 629 398 622 418 573 396 568 401 542 381 539 377 542 381 549 361 545 357 553 390 550 401 542 396 568 348 572 326 570 327 563 339 566 339 556 322 560 312 546 341 531 353 529 343 542 410 514 443 511 445 508 439 504 502 470 525 446 498 416 456 353 459 349 456 341 446 336 432 336 420 345 383 394 366 408 356 412 329 412 308 374 307 362 312 350 298 343 295 315 310 315 322 308 375 248 394 239 415 261 436 325 498 352 532 360 541 297 532 167 505 132 498 109 530 102 560 109 574 116 635 167 631 187 632 229 618 233 615 391 632 388 667 364 690 356 686 341 669 319 666 308 678 305 712 308 747 323 773 345 780 358 784 379 783 391 618 488 562 514 525 525 520 534 474 549 482 556 490 580 485 606 477 615 567 614 604 618 587 670 502 672 436 683 416 712 398 749 461 755 472 759 477 766 492 764 529 770 564 725 587 670 604 618 592 597 560 563 577 559 587 549 652 572 671 582 686 596 697 615 759 615 773 601 814 607 855 618 894 633 956 670) (869 392 856 377 828 369 801 350 783 325 759 311 716 262 694 246 695 231 701 222 802 259 853 290 880 318 891 334 900 353 894 367 902 372 906 380 904 394) (295 568 274 597 236 593 219 586 184 563 119 508 138 497 152 496 183 500 236 518 257 501 295 446 315 429 304 461 295 473 300 474 306 466 315 463 315 478 322 494) (265 406 254 406 219 393 136 339 121 307 95 284 129 277 148 279 229 301 241 322 256 338 274 350 272 368 288 398) (332 204 305 226 287 217 255 195 227 169 195 119 207 114 236 116 315 146 336 191)) ; 娑
                (38373 1000 (941 144 932 152 897 169 885 178 871 203 865 233 868 347 863 396 863 459 886 854 880 925 863 958 851 968 829 973 806 957 785 957 754 946 703 914 653 865 608 877 567 877 530 870 417 836 364 835 340 841 315 854 288 837 250 793 269 792 317 798 346 797 360 775 357 754 318 700 317 677 328 657 329 643 309 642 264 658 249 646 223 597 238 595 264 607 283 610 346 598 369 597 390 610 384 634 393 639 455 633 443 589 426 590 402 584 367 555 415 554 503 544 501 515 480 519 445 517 383 492 499 475 495 450 473 413 486 410 523 418 559 442 546 469 598 464 645 471 648 484 646 491 636 496 565 502 544 510 541 539 561 539 566 572 489 580 490 603 497 627 528 626 560 618 566 572 561 539 608 523 686 539 688 546 684 560 676 563 615 567 615 591 601 612 655 621 675 632 654 643 593 646 565 651 553 657 551 674 624 665 645 674 655 695 552 709 552 727 648 726 671 730 678 736 668 746 653 755 631 762 593 767 554 764 553 794 538 819 527 818 515 793 512 766 511 730 510 712 435 716 411 705 403 692 507 680 506 663 482 662 414 669 394 659 387 647 379 642 361 680 357 704 380 728 411 741 477 738 511 730 512 766 470 773 448 784 417 755 411 761 399 799 421 800 527 818 538 819 658 814 696 818 710 825 720 835 700 847 662 858 706 870 745 868 762 862 774 852 789 820 797 756 788 485 791 289 784 195 772 141 679 148 645 155 619 166 611 238 645 240 736 234 764 243 775 252 747 271 730 277 611 291 608 371 700 358 730 360 754 368 783 390 744 406 640 416 595 427 542 404 523 384 541 376 544 207 542 172 519 152 523 142 539 134 593 118 775 100 813 92 848 93 883 100 927 118 944 131) (443 206 437 252 441 369 437 395 426 415 418 421 378 417 359 420 360 368 357 292 357 250 356 207 348 171 265 180 184 200 196 231 197 279 298 256 357 250 357 292 258 314 238 317 201 311 200 403 360 368 359 420 232 448 195 448 190 517 192 710 195 880 200 921 195 947 177 942 145 923 130 909 109 878 103 862 102 833 117 791 125 654 129 440 124 284 118 243 109 231 74 206 52 172 94 170 252 138 327 130 336 127 352 111 360 108 431 114 463 120 490 135 509 163) (334 570 309 566 296 559 241 486 273 489 300 497 323 510 340 529 353 552)) ; 闥
                (36838 1000 (914 369 908 391 894 462 816 461 816 404 808 347 760 347 703 363 711 410 714 456 711 652 755 650 797 640 816 461 894 462 871 666 886 683 888 694 846 702 746 704 714 713 700 723 673 712 629 661 631 655 641 654 648 468 640 374 624 336 604 363 597 386 525 424 523 362 518 324 498 320 467 325 398 605 453 635 474 631 483 621 500 589 512 544 520 486 525 424 597 386 598 513 586 607 563 689 541 736 522 750 506 756 493 754 481 745 406 658 393 630 368 669 350 684 336 691 322 692 313 688 297 667 304 666 310 654 316 653 346 568 370 478 394 348 366 357 354 356 331 344 303 312 281 265 310 262 380 269 402 266 409 217 403 175 357 63 366 64 376 48 416 71 434 88 477 145 472 177 470 259 484 261 498 257 530 226 555 221 573 235 629 256 650 271 656 286 649 311 711 296 812 286 828 272 848 273 889 286 966 333 976 342 981 354 978 368) (924 897 895 923 805 940 711 942 653 935 579 890 444 819 309 802 260 812 217 833 188 842 173 843 146 835 93 788 70 774 78 761 87 753 98 751 186 769 220 765 238 757 247 722 246 706 234 676 155 585 143 565 196 478 220 418 174 431 160 451 147 448 115 452 64 403 44 373 60 363 83 368 87 361 126 370 157 368 189 358 212 341 244 349 302 371 307 390 324 412 328 423 300 436 279 460 232 554 213 581 261 633 290 674 318 741 400 748 443 763 714 806 826 811 836 804 918 823 954 837 958 854 955 876) (210 229 190 225 167 210 145 184 103 100 135 99 150 104 225 150 246 194 248 220)) ; 迦
                (32645 1000 (898 176 888 181 874 181 850 216 798 339 800 345 812 348 770 377 744 381 716 372 688 378 679 369 402 373 372 334 370 174 258 192 263 336 372 334 402 373 339 378 284 390 340 394 363 400 378 412 380 421 374 433 259 531 271 540 314 559 327 551 377 490 364 472 378 466 381 459 439 480 459 500 443 521 389 563 375 587 418 611 383 654 378 625 365 603 328 630 288 678 358 668 383 654 418 611 442 633 458 661 458 698 241 733 233 736 218 755 194 751 175 742 160 728 131 673 205 680 223 668 233 666 244 642 252 635 274 633 271 628 267 630 266 624 277 604 247 582 216 568 152 557 132 550 115 534 109 523 134 516 188 520 211 514 234 494 268 439 288 419 274 401 274 393 262 396 258 422 221 410 168 375 183 347 191 308 193 263 190 218 167 208 132 180 178 157 231 143 478 127 816 124 738 170 700 164 615 168 548 204 547 172 516 167 438 171 449 197 442 238 440 327 539 323 537 298 548 204 615 168 607 322 709 317 726 264 738 170 816 124 880 136 899 157 908 161) (909 913 896 914 890 920 738 902 669 900 598 906 563 911 560 929 564 956 548 957 522 948 475 896 485 872 501 848 494 798 498 699 495 643 501 635 504 620 505 595 478 596 440 586 443 578 457 567 471 535 525 452 543 415 519 387 553 378 570 378 625 395 624 421 620 432 585 483 575 508 610 510 637 507 657 499 673 488 684 473 714 417 686 391 738 385 764 392 777 400 784 411 785 425 774 444 728 474 711 497 759 487 815 491 857 504 885 526 739 544 734 608 792 613 822 620 845 632 853 642 817 652 737 663 735 722 674 703 673 667 671 620 668 558 648 551 620 550 559 559 562 631 671 620 673 667 560 674 554 705 554 742 670 734 674 703 735 722 801 730 828 738 851 751 842 760 826 766 739 778 732 800 729 852 678 846 670 838 668 828 670 790 667 779 557 785 563 860 668 859 669 854 678 846 729 852 749 853 767 842 792 843 883 863 911 887 915 896 914 907) (223 960 200 952 131 904 135 885 129 850 92 783 138 793 157 803 188 828 219 879 231 918 237 960) (340 908 330 904 290 868 273 857 253 792 238 765 278 779 324 814 347 846 356 865 366 907) (438 852 396 816 375 805 376 788 372 764 357 747 398 753 442 780 463 807 468 823 464 858)) ; 羅
                (39608 1000 (930 318 846 313 800 317 754 370 737 358 729 345 752 329 747 320 670 332 638 345 645 355 682 383 687 395 675 412 634 506 608 530 624 554 674 583 720 482 754 370 800 317 846 346 857 374 842 392 817 409 775 524 744 579 746 585 731 625 729 628 717 625 706 640 705 643 722 640 688 702 661 742 627 778 608 795 605 789 614 781 590 798 555 856 604 802 576 850 549 880 531 891 538 880 531 877 479 884 468 880 472 876 455 874 453 869 444 887 437 932 432 946 422 958 375 946 336 924 305 894 286 859 259 840 246 838 271 834 349 863 360 857 370 834 372 742 375 703 372 636 372 597 370 536 366 511 306 516 264 530 255 575 257 601 340 588 362 592 372 597 372 636 314 642 255 657 250 715 338 698 375 703 372 742 246 767 245 820 236 834 240 852 241 921 249 941 216 941 202 935 150 891 154 862 184 784 186 749 172 742 170 735 181 730 188 720 194 688 191 652 180 629 194 606 196 565 173 534 156 519 172 501 176 487 310 467 369 448 442 462 460 434 462 420 458 412 448 406 365 405 276 414 160 438 150 480 121 562 109 606 106 629 123 648 126 657 93 662 67 652 46 631 10 572 60 532 73 515 90 473 56 448 47 438 48 434 62 418 63 406 90 405 146 385 173 381 167 370 163 348 170 291 167 240 163 221 146 190 103 151 117 134 130 126 174 126 338 95 410 89 458 98 473 115 508 144 504 158 496 168 462 186 455 197 373 172 369 147 320 145 282 150 247 161 219 179 233 221 234 244 229 374 276 370 269 286 264 273 256 264 243 260 256 239 262 218 311 229 372 229 372 315 369 268 329 282 328 325 319 367 369 363 372 315 372 229 373 172 455 197 452 356 480 352 529 363 558 381 575 409 561 428 539 476 523 493 511 498 468 484 470 492 485 508 474 523 458 533 449 584 446 640 448 856 468 853 482 841 494 843 515 828 614 693 637 656 638 636 592 615 575 597 563 600 540 600 530 595 518 576 490 572 472 558 479 546 488 542 540 542 557 527 571 500 604 406 578 375 586 356 550 363 514 331 492 305 482 289 489 279 499 276 565 282 691 271 696 258 701 183 624 136 628 126 621 108 672 98 717 98 737 104 755 114 771 128 784 147 769 185 750 264 834 258 896 263 936 277 952 290 963 307) (948 929 915 922 872 890 837 848 825 804 819 792 800 774 800 749 795 748 790 752 784 774 770 781 774 792 769 802 744 834 734 834 708 870 690 887 668 899 655 901 648 919 617 906 581 902 586 892 634 853 641 841 654 841 656 832 672 810 677 795 685 801 696 794 711 750 793 603 800 586 794 566 784 562 804 526 838 532 854 542 879 568 887 583 820 710 880 758 928 818 951 867 966 926)) ; 骸
                (21050 1000 (576 413 571 418 567 437 556 446 566 456 559 553 554 575 544 594 530 609 508 607 474 594 448 571 402 520 468 520 477 509 484 475 480 403 470 394 443 391 395 394 389 408 382 462 392 550 469 607 502 641 520 673 531 712 498 706 444 679 412 652 389 620 386 678 391 852 388 895 377 938 340 939 310 927 236 869 236 846 204 830 225 828 282 840 311 842 320 818 324 786 323 620 288 645 211 721 176 747 131 763 88 793 86 788 91 783 107 772 98 768 74 787 81 797 52 800 22 794 32 782 51 780 46 771 131 710 180 666 297 540 300 514 308 508 326 507 326 407 290 404 224 421 220 482 228 614 208 612 192 606 178 595 160 563 155 521 162 475 120 436 102 412 137 388 160 382 322 361 321 334 312 315 230 322 182 268 167 229 268 243 312 242 308 200 288 106 301 104 332 110 362 128 388 154 403 184 405 200 394 231 432 234 476 221 517 253 533 271 536 284 512 295 416 302 398 308 388 351 430 354 500 340 533 340 548 352 598 376 603 384 604 395 599 409) (856 363 849 451 850 535 868 770 870 853 868 872 858 903 831 939 718 913 657 890 660 884 666 884 694 894 691 886 640 865 633 858 633 847 610 836 600 828 598 816 634 831 675 840 765 840 782 818 789 798 796 710 797 626 784 359 764 177 754 136 735 97 765 97 818 129 865 176 880 212) (698 582 692 641 678 638 654 626 638 607 616 565 618 558 632 545 626 546 629 545 624 415 620 397 597 362 598 353 638 351 674 364 700 386)) ; 刺
                (32097 1000 (986 705 976 714 946 721 900 716 845 698 743 659 628 666 579 680 576 780 585 840 679 836 720 829 734 772 743 659 845 698 835 722 821 819 809 850 831 862 842 872 848 885 817 896 801 897 704 892 589 895 584 903 578 926 572 934 556 930 533 912 519 886 500 829 508 805 510 776 503 711 441 742 394 699 402 692 440 685 450 679 472 655 483 652 476 637 464 627 470 622 498 623 520 613 539 597 596 515 627 453 628 443 622 424 566 356 533 395 499 422 473 429 454 446 438 438 427 439 432 425 454 408 499 343 556 210 549 193 514 148 513 140 526 134 529 126 618 146 638 163 644 178 710 176 720 224 668 224 621 230 592 296 582 321 654 384 720 224 710 176 723 171 733 161 790 164 848 180 864 190 876 203 884 220 878 229 870 235 829 248 806 272 789 279 767 337 723 418 721 443 727 457 750 486 790 523 743 593 681 516 618 611 702 603 743 593 790 523 893 585 946 625 976 658 990 694) (384 346 328 441 380 488 336 505 333 484 323 459 282 498 226 574 296 554 324 536 333 522 336 505 380 488 400 514 411 546 410 588 276 631 226 640 193 640 161 667 150 671 131 664 106 645 88 626 88 612 64 586 62 577 84 574 134 584 159 572 242 445 205 426 122 396 104 386 78 358 134 361 175 297 233 180 200 130 196 107 283 134 321 159 281 245 203 368 252 393 262 401 269 413 296 374 344 292 331 257 334 246 351 236 406 271 419 292 420 306) (165 905 157 925 123 912 75 866 72 811 48 713 107 746 141 779 164 814 173 848 173 866) (269 851 216 793 216 742 200 689 258 729 292 770 306 803 308 822 302 863) (380 791 354 762 337 723 318 657 364 688 401 724 419 759 420 807)) ; 絡
                (36795 1000 (943 891 921 906 869 929 809 943 713 948 653 909 582 871 398 792 346 786 289 792 250 803 220 822 200 822 168 813 136 783 104 729 102 725 110 720 112 708 118 703 192 721 256 725 294 721 304 696 306 667 298 649 248 624 225 599 218 583 216 566 222 534 262 465 194 476 135 496 122 492 102 476 73 427 55 405 62 397 56 381 58 373 84 383 137 395 178 411 202 415 233 405 254 386 277 382 302 390 368 431 350 472 294 533 274 572 336 622 363 652 374 680 366 716 547 765 657 787 735 793 878 790 916 795 950 809 956 828 974 845 978 854) (790 436 649 451 643 496 640 664 634 721 628 745 606 746 599 755 577 740 568 729 559 703 562 529 554 456 496 460 420 476 372 434 361 417 349 371 482 394 517 394 555 388 555 247 545 197 516 112 523 93 610 145 655 184 648 237 644 380 707 368 766 368 793 374 816 384 837 399 854 419) (287 282 282 287 238 291 166 222 144 190 129 147 145 146 173 154 230 188 250 195 284 244 289 272)) ; 辻
                (20462 1000 (969 624 945 629 894 630 867 625 804 600 786 589 756 559 752 567 752 592 684 628 689 632 742 640 765 650 781 669 784 684 749 715 726 724 716 736 686 751 679 758 702 764 756 760 781 763 803 779 804 794 796 818 780 836 726 869 703 889 644 912 628 923 566 937 559 923 545 933 523 920 512 919 508 910 512 905 570 887 622 862 682 817 697 801 696 794 674 760 605 786 562 795 527 782 508 770 627 710 666 678 683 659 678 645 667 635 598 651 569 654 538 646 563 631 532 636 525 634 617 585 661 557 648 536 676 535 746 548 702 503 677 483 579 555 515 594 528 580 529 573 518 578 490 604 470 602 438 612 419 611 416 781 412 843 397 849 373 844 348 814 325 763 339 747 348 728 354 682 352 589 357 414 347 335 335 296 268 386 274 779 264 787 272 817 259 871 262 873 269 863 272 874 266 900 268 917 254 926 243 928 234 924 210 900 191 871 178 838 193 795 206 711 209 463 179 492 122 563 90 592 50 615 35 619 5 617 9 591 20 573 63 521 112 453 173 395 275 239 288 209 287 186 249 146 273 134 321 134 352 146 377 166 390 194 391 210 349 263 390 288 405 306 415 327 422 352 440 344 462 324 476 323 486 294 501 273 492 262 491 249 520 243 545 208 568 159 529 91 535 84 563 74 589 88 646 109 656 119 660 134 658 155 653 165 618 210 607 231 590 234 595 243 612 246 716 236 781 226 814 215 854 224 895 238 930 254 951 269 955 275 902 283 738 294 673 300 586 305 555 301 537 328 572 345 603 366 638 384 613 431 569 392 516 354 500 371 461 397 452 379 425 359 420 441 417 599 447 586 496 554 504 547 509 533 526 530 554 496 587 467 613 431 638 384 657 362 672 332 673 300 738 294 752 313 755 331 747 354 721 402 715 422 756 448 847 486 909 519 954 561 976 610)) ; 修
                (22810 1000 (864 580 824 594 798 616 743 682 711 700 615 791 566 824 527 841 523 858 405 923 324 950 251 959 126 953 85 934 98 928 120 930 190 921 348 861 406 845 400 839 382 841 475 787 531 746 463 698 406 640 319 683 263 700 218 700 207 682 198 678 157 673 269 631 303 614 306 621 322 602 354 591 360 582 491 502 487 489 494 486 507 489 508 482 493 460 491 449 507 443 520 448 555 443 609 467 627 486 711 481 719 542 620 555 605 546 603 535 580 537 534 566 473 597 454 614 524 653 553 679 575 710 672 611 719 542 711 481 735 476 768 462 808 469 915 528 943 553 952 568) (788 228 731 239 711 248 681 274 645 323 631 337 619 337 587 373 552 393 450 474 382 513 330 532 336 525 275 534 238 534 190 522 153 522 246 491 326 456 372 426 414 390 383 363 330 301 304 312 254 341 223 353 177 354 152 334 133 331 303 236 398 172 359 148 346 130 387 117 410 116 454 120 495 135 527 159 598 153 587 215 498 211 472 215 444 227 370 278 414 294 479 347 510 306 535 294 542 274 576 238 587 215 598 153 614 144 615 136 669 138 705 148 739 164 775 188 808 219)) ; 多
                (25163 1000 (958 580 947 588 934 590 714 574 647 574 582 581 579 644 585 797 582 842 574 885 545 943 492 945 412 928 315 888 293 877 284 857 255 826 270 824 297 843 313 848 361 855 433 851 472 837 487 813 493 796 499 756 495 584 409 590 334 604 255 626 205 646 146 623 110 601 81 571 66 531 116 536 158 551 180 546 186 540 244 540 415 522 493 519 482 427 368 442 310 464 243 407 223 371 242 364 268 370 289 379 335 379 466 366 470 342 467 332 437 281 349 299 316 301 288 295 271 276 246 278 238 274 387 227 475 192 530 165 580 132 576 122 559 111 554 102 609 90 634 89 679 99 718 123 736 140 728 162 691 189 644 197 573 230 537 236 530 245 509 254 552 314 560 338 559 352 621 339 680 342 734 359 778 386 755 399 740 403 618 408 565 421 572 503 586 508 621 512 750 507 778 489 878 512 926 528 968 551 968 560 973 564)) ; 手
                (20024 1000 (915 874 894 887 845 904 786 908 714 901 655 884 616 863 580 832 557 795 537 749 528 722 521 654 525 569 538 484 571 364 526 366 443 378 426 495 415 535 393 588 452 662 459 678 461 697 457 718 432 716 420 712 365 674 306 773 281 804 283 811 263 828 258 839 226 858 223 864 228 868 173 910 151 921 171 900 162 900 140 916 128 914 122 917 109 931 122 910 142 897 140 893 155 868 170 862 198 822 208 814 221 811 215 804 277 686 301 629 268 591 197 530 216 515 242 514 272 522 328 547 346 496 364 389 308 397 261 412 224 435 211 456 189 458 154 448 64 381 66 372 61 353 92 357 118 367 370 321 375 256 373 187 297 84 333 78 368 79 413 91 432 101 449 115 463 133 473 154 458 234 450 311 539 302 574 294 605 280 625 258 661 263 700 277 749 307 767 328 743 354 678 374 663 387 636 426 620 463 600 529 587 621 588 686 599 731 609 750 637 782 674 804 694 810 739 814 761 811 792 801 810 790 820 765 820 727 789 573 826 652 842 697 849 672 879 707 883 701 875 686 880 685 898 706 912 711 936 772 950 836)) ; 丸
                (24746 1000 (812 319 802 325 802 339 792 336 766 414 758 463 752 465 760 475 761 482 716 488 579 481 573 549 688 549 723 563 748 580 767 601 758 607 738 612 677 609 506 618 517 563 516 482 515 434 513 298 512 250 510 208 495 179 430 184 402 191 416 208 428 231 426 257 512 250 513 298 455 302 430 309 426 439 362 409 358 313 336 313 262 328 258 362 264 454 292 455 335 448 356 449 362 409 426 439 515 434 516 482 433 487 424 522 428 561 517 563 506 618 392 633 349 631 304 639 270 654 230 637 207 622 191 601 183 571 304 576 365 565 360 494 337 505 294 516 268 538 205 506 192 489 187 467 199 396 193 358 169 344 132 304 142 298 142 291 204 287 353 265 348 224 336 203 319 197 263 209 234 188 203 146 199 121 205 110 235 116 280 132 320 134 572 115 616 107 656 90 678 96 702 112 736 141 750 159 708 168 613 172 564 178 587 218 592 245 644 246 662 242 684 228 714 239 692 298 596 294 584 380 585 436 642 434 668 428 680 390 692 298 714 239 737 236 836 276 860 300 868 318) (871 896 867 906 824 919 816 924 812 933 718 936 662 925 659 928 663 932 601 930 543 923 489 908 443 886 369 827 333 771 284 663 298 659 310 660 322 668 384 733 404 776 425 805 450 829 479 844 510 850 652 850 694 842 711 834 711 792 704 778 646 725 638 715 632 687 676 701 740 748 779 762 780 768 793 778 816 781 880 850 887 871 884 883) (213 926 194 915 163 884 130 830 157 797 164 780 174 672 181 671 199 681 213 694 230 727 236 767 237 890 254 914 258 926 255 938) (840 745 828 735 831 739 810 739 789 733 768 720 651 632 682 623 720 624 758 634 795 651 825 674 845 700 851 730 848 745) (543 764 523 753 489 721 449 664 484 662 520 669 553 685 567 696 587 723 592 739 590 775)) ; 悪
                (12356 1000 (396 656 388 659 396 670 397 676 388 676 382 729 362 779 323 777 287 766 229 713 207 679 186 631 164 551 151 466 136 298 226 379 243 406 252 443 246 486 258 548 259 582 284 653 309 645 329 632 391 553 391 564 384 579 346 637 361 639 365 646 371 643 375 634 381 640 385 639 394 627 401 624) (839 692 819 678 786 627 770 610 746 599 730 598 736 590 772 571 778 563 775 537 756 472 678 334 732 348 779 375 819 413 852 460 876 512 890 568 896 626 891 682) (386 605 378 624 365 634 359 632 384 597)) ; い
                (30294 1000 (892 744 749 744 738 912 722 955 706 974 692 966 682 911 677 831 680 748 642 754 596 756 553 745 538 790 527 873 504 888 488 884 472 870 433 865 394 871 334 896 315 877 307 853 304 827 307 740 303 712 279 787 248 839 218 857 180 862 239 747 260 695 267 668 247 647 267 643 290 578 298 524 290 498 307 490 310 440 308 412 296 392 259 568 246 608 229 639 233 661 223 661 217 702 179 783 179 807 165 807 163 827 139 869 146 876 124 900 118 920 104 916 112 927 102 930 102 938 97 940 82 933 80 944 74 950 47 954 70 928 131 786 155 757 145 753 176 666 181 622 162 632 143 648 138 660 137 673 117 671 84 660 70 651 46 626 27 591 50 590 67 594 78 601 94 599 136 575 181 558 197 545 208 526 208 498 173 485 142 461 116 430 83 380 117 380 136 386 217 425 220 366 211 315 195 291 153 249 140 219 147 214 165 210 177 201 191 216 268 211 402 194 476 191 477 167 469 149 417 114 406 90 417 88 424 82 427 72 463 66 496 72 515 83 531 98 544 117 521 186 654 185 694 178 730 163 825 191 878 217 854 239 808 250 710 246 526 250 385 263 276 287 294 314 297 334 418 320 442 311 456 296 518 307 558 323 591 350 567 379 698 367 693 316 652 281 642 259 686 254 717 261 731 268 743 277 755 305 741 327 732 356 752 362 766 418 695 420 632 429 642 436 655 456 664 481 678 548 679 603 642 613 606 606 574 582 555 549 592 554 630 549 610 523 598 426 566 405 554 400 480 402 475 369 412 371 365 384 374 404 374 416 369 486 438 474 476 474 480 402 554 400 531 525 479 525 362 540 344 595 343 613 445 600 488 600 470 652 412 652 363 664 369 827 436 822 461 823 468 759 470 652 488 600 528 606 564 619 580 629 604 658 596 668 568 683 565 689 567 698 634 686 679 686 679 603 678 548 736 545 766 418 752 362 806 349 830 354 879 377 901 396 907 408 881 412 828 413 836 439 833 469 822 499 798 536 858 566 885 587 850 597 776 598 748 603 744 675 829 681 884 694 929 712 948 724 948 739)) ; 癖
                (31070 1000 (948 396 923 416 913 429 894 602 871 692 841 692 822 700 805 680 793 677 713 680 706 740 700 889 687 949 668 991 645 954 636 911 631 851 632 731 628 681 559 688 524 685 494 673 470 648 476 637 466 604 468 512 464 487 458 480 465 453 464 440 452 418 442 409 419 399 407 398 435 362 474 342 508 333 626 316 626 266 620 222 583 62 616 72 717 150 726 182 711 227 708 311 778 313 804 306 821 381 814 376 811 367 746 367 719 372 704 385 700 397 706 418 698 446 700 461 635 470 630 380 582 382 535 392 533 482 635 470 700 461 736 474 796 514 708 522 703 623 634 579 629 531 584 536 534 532 539 629 630 631 634 579 703 623 772 620 798 628 816 543 821 381 804 306 819 291 837 293 898 308 903 316 946 338 951 346 980 356 989 364 996 378) (457 342 420 348 362 425 333 478 341 491 376 510 391 522 416 552 436 588 457 652 447 658 427 658 358 614 354 590 337 557 333 630 336 889 326 958 320 964 307 962 276 932 267 913 259 871 260 798 275 660 275 616 269 572 237 615 194 660 95 739 67 752 43 756 31 755 9 741 108 651 206 539 244 484 255 447 257 426 271 424 282 414 315 360 312 350 267 352 246 358 145 399 105 362 81 331 65 297 61 278 109 289 188 292 343 274 350 259 391 259 427 270 478 293 485 322) (407 146 397 169 349 227 342 181 335 163 284 140 271 131 249 100 315 88 354 88 390 102 404 121 407 133)) ; 神
                (20853 1000 (957 676 930 690 821 677 681 672 468 675 346 686 404 718 420 747 315 869 257 925 224 948 180 956 174 944 151 932 150 918 216 865 312 757 307 744 287 721 284 711 287 704 294 700 324 693 327 689 242 693 207 701 155 720 132 719 108 705 39 642 54 621 84 627 115 628 291 621 282 459 269 377 256 332 237 291 210 258 194 245 219 243 252 253 279 241 339 223 335 230 376 220 454 191 458 183 468 178 484 174 487 179 545 154 538 150 592 130 585 120 556 96 591 92 625 82 720 123 722 150 716 164 639 185 443 262 391 275 337 282 353 330 351 355 579 353 658 346 736 332 830 363 867 391 847 397 805 402 679 404 685 434 683 483 594 457 592 434 586 412 427 417 355 430 357 614 519 608 578 602 594 457 683 483 655 602 732 606 755 599 761 591 830 600 902 622 943 646 959 661) (826 941 807 943 752 926 723 889 656 766 602 709 595 683 657 703 771 766 793 792 820 853 833 873 841 933)) ; 兵
                (20632 1000 (960 567 927 575 895 573 842 550 819 545 784 497 722 400 684 357 671 337 604 248 533 163 499 176 455 227 464 230 485 223 505 231 538 254 560 288 566 310 556 324 543 454 578 417 606 372 617 347 605 334 603 324 634 325 671 337 684 357 681 374 661 404 704 439 730 464 758 514 752 521 738 518 694 498 654 463 634 437 603 474 618 480 614 508 612 499 597 481 587 492 574 498 549 498 547 564 553 601 576 572 614 508 618 480 664 485 673 490 678 509 671 534 708 563 729 585 743 612 745 645 704 635 656 594 637 568 616 599 596 617 573 627 549 625 546 638 553 652 682 645 699 641 704 635 745 645 799 666 823 680 837 700 839 712 639 703 563 705 553 712 539 898 523 986 519 992 512 992 502 986 485 912 479 715 424 715 367 720 308 733 270 749 190 709 155 685 170 681 182 688 221 673 265 665 482 652 482 524 479 494 472 324 452 237 442 237 361 340 392 344 414 362 422 384 419 395 398 414 479 494 482 524 438 507 400 485 374 451 321 496 280 520 245 526 219 518 236 501 236 511 265 494 250 491 270 474 280 471 291 447 342 395 352 375 354 351 247 459 206 488 124 558 87 576 66 581 32 581 1 574 29 549 100 501 106 502 60 536 50 549 98 514 106 502 100 501 125 474 132 481 138 477 145 458 156 461 174 452 192 434 186 427 211 401 237 378 263 364 263 352 283 324 361 244 438 116 418 90 418 73 464 67 507 71 537 87 549 100 554 117 593 153 723 303 798 368 826 387 860 397 876 407 974 476 987 493 996 512 999 535) (450 636 412 620 395 608 371 578 336 619 290 652 286 647 278 646 253 655 249 646 239 649 237 645 246 628 219 645 293 588 273 595 277 587 333 532 338 516 337 494 376 501 397 513 405 524 402 540 395 551 444 586 466 619 469 638)) ; 傘
                (35009 1000 (920 954 880 946 850 932 773 883 677 719 579 844 540 883 513 894 498 893 454 879 471 876 486 849 540 802 538 799 522 803 527 793 456 763 447 766 426 756 423 729 414 718 390 698 322 652 303 632 307 710 304 806 310 839 394 789 426 756 447 766 460 780 461 809 451 809 419 842 317 913 293 936 250 930 200 910 194 885 173 846 183 841 207 837 230 843 238 849 246 836 253 801 248 702 216 725 140 790 149 775 137 778 103 802 114 799 149 775 140 790 100 812 99 805 64 804 32 799 56 786 70 786 217 642 214 625 255 600 269 582 218 586 182 582 149 570 125 548 170 530 282 518 310 511 312 505 309 468 303 457 293 451 220 466 152 495 110 477 52 424 79 416 107 421 141 405 162 402 320 394 313 324 254 334 231 344 182 304 169 288 149 250 158 245 159 237 174 239 262 267 310 270 315 229 312 208 279 96 297 92 326 98 399 150 409 187 397 206 392 257 436 242 457 240 494 255 516 274 515 283 505 300 472 302 392 317 384 336 378 381 437 382 536 367 527 221 516 147 497 125 471 63 492 62 531 72 549 82 626 143 606 286 606 324 612 364 682 358 718 344 791 365 821 381 810 394 814 404 678 410 619 421 629 491 637 523 660 582 632 642 623 609 592 554 559 457 540 421 430 434 378 448 378 466 368 511 381 515 408 514 481 491 502 505 538 510 546 515 550 525 532 543 518 548 471 555 402 558 372 565 367 578 358 588 324 613 317 625 347 632 372 645 402 652 423 634 457 592 437 582 446 574 480 562 517 569 544 592 550 615 477 655 440 665 567 759 626 673 632 642 660 582 669 569 672 555 666 522 653 488 664 480 663 471 720 484 753 501 767 515 777 531 773 540 720 612 708 635 704 659 710 678 733 716 778 776 820 817 852 836 861 812 865 707 879 739 883 742 887 736 883 728 887 726 910 746 912 764 886 786 876 779 878 755 871 766 870 780 873 809 886 786 912 764 928 797 943 859 950 906 948 946) (814 317 785 305 759 282 687 187 743 192 793 216 831 257 845 292 849 311)) ; 裁
                (12385 1000 (782 762 747 810 709 846 672 870 608 899 542 915 491 918 418 912 541 849 596 811 647 769 692 721 700 682 696 652 688 641 675 634 656 632 612 638 570 650 504 678 408 731 375 720 362 709 346 680 336 624 337 541 360 376 316 374 281 361 211 325 218 311 229 304 290 300 376 280 401 188 415 155 432 131 455 120 478 125 485 131 493 153 495 196 479 263 514 260 544 253 571 240 589 221 658 244 677 262 683 276 685 292 669 303 615 324 516 343 466 360 445 410 430 460 411 615 435 613 524 580 577 570 631 567 691 572 749 593 785 620 805 652 812 672 813 692 808 712)) ; ち
                (26422 1000 (896 900 884 906 853 912 835 911 826 904 802 908 804 902 816 900 813 895 794 904 788 899 739 891 689 843 675 820 660 816 654 801 632 786 622 762 614 754 604 752 592 727 551 684 547 736 480 780 480 732 467 693 343 784 304 817 392 844 445 850 454 844 468 824 480 780 547 736 552 883 538 928 517 950 502 958 453 950 393 925 358 903 279 839 207 881 165 898 143 900 119 897 119 876 89 880 105 861 121 857 126 861 131 858 129 843 158 838 151 828 176 817 223 780 245 773 259 774 257 764 245 767 260 750 343 679 374 648 358 648 301 657 278 671 252 671 226 662 202 645 168 605 212 591 241 598 284 599 403 576 460 573 462 535 456 520 418 469 434 460 450 456 485 463 501 471 525 494 543 535 541 564 584 566 698 561 701 558 698 554 728 552 793 562 832 578 838 586 838 595 828 605 780 610 646 613 564 622 592 639 645 691 678 717 734 744 842 783 880 807 902 831 912 852 914 873 911 883) (781 311 772 318 735 332 727 342 731 400 724 457 714 492 696 521 670 541 653 546 632 548 596 543 556 516 505 460 520 458 553 466 575 464 593 457 606 445 615 430 627 391 634 315 524 314 509 298 501 274 518 268 532 258 542 244 553 211 564 131 440 148 452 184 440 269 418 380 392 454 362 503 320 540 304 536 272 538 308 489 315 475 311 475 304 488 297 490 307 470 319 467 314 446 355 325 367 246 365 205 358 188 345 176 314 182 272 170 250 167 275 145 290 137 327 125 371 116 497 103 580 89 642 87 699 96 714 102 718 109 700 137 700 150 675 147 663 160 644 192 622 246 702 249 754 259 779 277 784 297)) ; 朶
                (30524 1000 (973 893 937 920 927 925 905 926 868 920 835 905 806 880 723 770 670 823 650 833 627 860 543 920 543 939 522 939 489 932 476 924 448 897 405 849 412 841 412 833 440 836 482 847 492 599 490 542 481 491 489 412 491 328 483 252 470 212 460 198 425 218 420 320 340 447 331 393 324 389 334 370 330 246 321 184 220 198 187 214 173 225 178 259 175 353 211 345 246 343 277 347 307 356 334 370 324 389 298 391 212 416 172 415 167 535 232 524 288 522 323 533 340 544 340 447 420 320 420 681 412 794 373 807 349 787 316 742 338 683 337 567 296 570 199 593 168 593 166 713 212 710 299 689 338 683 316 742 202 774 146 784 94 779 64 763 51 750 59 744 110 726 78 676 87 639 95 577 108 413 110 319 104 281 95 259 79 242 33 208 38 198 57 177 279 131 325 127 370 129 438 148 446 140 447 125 473 136 610 135 749 123 768 108 785 102 808 107 872 136 902 154 914 166 923 182 928 202 904 202 884 208 870 218 852 250 843 293 760 270 757 181 633 192 565 211 560 270 563 316 596 314 694 300 735 304 755 313 756 344 666 364 567 374 562 475 678 461 743 437 756 344 755 313 760 270 843 293 832 411 827 432 806 463 817 486 800 499 790 502 738 504 723 511 632 522 601 521 678 608 784 543 823 513 841 497 839 492 827 486 847 466 876 463 907 474 921 484 939 511 939 525 927 548 888 574 724 650 680 705 649 664 562 525 551 816 646 750 671 722 680 705 724 650 760 684 806 718 856 747 908 771 935 804 989 857)) ; 眼
                (37329 1000 (943 647 906 649 866 640 800 611 640 352 513 176 489 194 392 336 326 422 406 419 455 411 501 400 529 379 587 395 633 423 656 450 610 452 517 465 527 485 528 498 523 551 581 540 591 533 596 524 694 560 716 580 723 595 525 612 507 828 609 829 639 819 652 809 697 815 749 830 781 845 807 865 822 890 802 900 773 902 615 886 518 886 445 890 364 903 299 930 274 935 248 927 221 908 189 865 177 840 177 831 220 846 263 850 448 833 449 618 384 627 359 642 334 638 294 618 249 574 447 554 444 510 427 479 411 484 395 485 380 480 316 438 274 493 214 561 137 634 74 687 58 692 17 680 1 679 82 605 196 479 288 360 386 220 418 153 412 141 382 117 375 107 371 93 440 81 489 86 508 96 520 107 528 120 529 135 621 231 769 397 802 424 918 500 951 528 980 569 999 628) (647 765 593 804 605 776 541 805 577 746 641 662 616 624 630 616 694 639 710 652 722 669 729 692) (358 813 342 808 313 787 278 741 249 674 265 675 295 686 376 742 392 810)) ; 金
                (40658 1000 (836 716 806 713 764 702 450 712 327 723 248 737 236 756 227 758 238 779 243 801 242 823 213 918 197 943 180 959 154 946 132 915 115 858 132 856 146 849 157 836 195 755 131 722 119 712 113 700 120 692 141 684 248 670 458 661 459 650 457 604 424 604 354 619 320 617 284 598 245 562 454 548 455 496 456 443 455 352 426 352 360 364 320 361 322 449 362 452 456 443 455 496 352 508 312 508 276 500 248 480 237 464 241 458 240 441 247 429 239 306 230 247 190 216 159 177 166 166 166 156 265 154 491 134 629 133 653 128 688 115 711 114 764 130 788 131 839 166 856 183 863 203 849 218 807 225 790 245 783 260 773 296 687 259 686 218 676 185 668 174 520 176 536 210 536 228 528 278 457 289 450 220 438 191 381 195 322 207 315 215 310 236 316 305 457 289 528 278 606 305 625 321 631 332 527 344 520 437 607 428 650 433 658 422 663 398 671 391 660 388 678 325 687 259 773 296 750 450 733 499 705 499 654 480 629 478 520 489 517 544 604 529 635 533 670 549 694 565 699 574 698 587 654 594 545 595 517 602 515 655 556 657 647 648 671 651 712 627 737 627 785 639 835 661 872 689 884 711) (874 934 873 942 853 939 818 924 804 911 768 861 717 755 686 710 723 717 740 726 803 774 836 792 863 830 872 852 880 888 883 928) (387 933 365 913 349 886 330 841 340 832 350 805 357 725 392 748 404 764 420 800 427 862 417 945) (577 904 564 892 546 863 534 807 534 716 568 734 581 748 601 783 616 844 618 885 614 921)) ; 黒
                (30722 1000 (476 235 396 241 357 249 364 280 306 397 279 473 338 469 354 464 379 441 414 440 472 456 501 476 509 487 513 500 510 514 498 527 477 539 474 551 470 553 463 665 392 620 383 517 318 524 282 537 267 546 279 734 348 725 379 716 388 669 392 620 463 665 446 722 458 742 456 750 431 761 332 774 292 784 273 793 274 828 267 844 243 842 234 836 220 817 202 759 214 723 216 702 209 591 135 693 83 748 49 752 37 751 28 745 6 745 37 720 63 692 154 574 159 552 166 541 177 536 174 528 160 517 157 506 198 485 214 464 244 386 264 308 267 271 239 268 189 279 161 271 132 228 115 215 116 205 111 180 184 194 244 197 335 190 412 172 440 170 478 188 495 189 499 199 512 213 515 223) (812 645 804 676 789 698 710 790 670 822 648 853 620 882 587 903 552 916 551 924 546 930 523 937 516 946 469 962 432 950 414 949 455 925 532 871 599 801 651 757 648 766 621 795 639 784 676 720 694 696 628 656 574 603 558 638 524 605 504 556 490 553 518 518 528 497 544 450 559 370 580 391 614 442 610 491 584 583 636 597 677 602 689 512 688 340 683 266 668 206 620 122 668 127 723 150 768 182 786 205 789 216 786 239 770 288 760 370 753 494 755 585 768 568 778 543 782 499 776 474 786 470 798 469 822 476 853 502 868 538 864 562) (972 603 945 598 886 536 871 508 856 458 820 388 818 377 821 368 829 360 907 412 952 458 970 491 982 530 987 601)) ; 砂
                (33144 1000 (936 516 894 521 705 520 644 525 626 529 616 546 592 562 555 621 522 615 502 634 435 668 411 684 411 816 473 749 513 699 555 621 592 562 607 567 641 571 730 564 760 565 778 551 788 548 839 549 858 545 887 568 952 608 941 624 895 631 888 642 881 666 786 660 784 611 737 608 740 651 643 809 636 814 607 855 640 860 697 849 733 811 764 754 779 709 786 660 881 666 885 677 846 828 818 885 791 915 713 948 678 935 649 916 623 895 621 890 626 885 612 870 595 867 548 872 536 867 525 856 583 788 631 716 656 667 673 618 655 614 636 618 607 670 574 718 537 762 496 802 451 839 436 836 414 823 405 894 387 918 363 914 322 896 222 809 224 794 216 773 291 802 327 806 338 721 339 634 333 407 216 430 203 452 200 464 199 539 260 534 294 539 320 557 330 572 265 588 228 590 192 588 145 763 122 826 111 829 109 856 103 868 78 902 54 896 34 884 57 850 74 808 112 667 128 625 126 585 137 437 125 377 134 354 134 337 125 271 116 258 76 222 68 209 79 188 89 184 171 174 310 166 333 209 233 225 195 245 208 264 210 276 206 342 209 370 250 367 284 371 320 389 333 403 333 209 310 166 317 162 322 145 327 139 408 152 445 165 478 185 476 194 481 215 472 225 445 236 434 245 405 395 401 479 488 486 532 539 460 532 436 524 401 502 411 651 476 595 532 539 488 486 580 484 801 473 828 459 868 462 908 471 944 485 972 506) (818 218 808 365 791 450 777 456 748 457 734 463 690 458 585 463 544 453 522 436 512 423 525 394 526 375 518 284 522 232 502 216 484 181 475 172 481 162 519 148 544 145 703 139 723 185 700 182 599 189 590 217 586 275 610 278 683 274 697 278 702 288 723 304 723 318 586 331 589 413 626 414 690 404 720 407 723 318 723 304 723 185 703 139 720 119 728 119 750 122 760 126 767 136 791 134 816 143 881 189)) ; 腸
                (12388 1000 (831 655 819 666 802 674 798 686 780 701 776 713 769 711 760 714 757 719 770 721 762 731 728 742 734 751 648 790 612 798 595 797 592 809 531 813 522 802 499 798 492 793 529 764 570 739 605 709 614 708 628 697 631 700 602 722 617 718 647 684 668 678 684 662 699 655 723 618 782 547 805 495 808 464 802 426 766 401 726 388 681 383 611 388 454 426 392 454 324 474 315 487 291 491 253 511 225 516 205 514 166 501 132 478 89 438 131 431 264 392 321 387 328 374 388 357 481 338 608 325 702 330 789 351 802 364 812 364 828 384 866 416 887 489 883 545)) ; つ
                (12367 1000 (684 892 669 910 638 916 603 902 554 837 537 827 519 791 504 774 462 736 367 664 328 626 311 598 300 564 300 509 312 479 388 395 493 287 564 206 564 178 545 134 588 140 630 158 647 170 661 184 675 206 680 231 676 242 665 258 648 268 638 290 624 306 505 403 461 451 446 455 440 471 425 478 400 510 387 532 378 558 382 570 402 591 516 682 598 756 657 823 679 861)) ; く
                (35109 1000 (798 682 793 723 796 818 792 866 780 910 768 929 751 946 674 928 630 910 594 885 580 869 581 858 566 847 596 849 609 853 615 862 686 860 710 852 722 832 727 808 728 687 653 690 575 705 604 727 627 757 635 791 634 802 623 825 592 808 581 795 537 716 514 724 492 720 430 683 405 730 369 818 351 853 328 884 319 882 296 888 283 882 350 745 377 701 372 696 372 688 391 645 349 633 313 605 283 573 273 659 271 924 269 945 259 942 238 929 219 910 209 890 199 855 214 821 220 786 220 613 225 545 170 608 83 717 44 731 20 732 10 706 12 699 69 632 105 604 96 601 178 490 228 413 252 373 245 370 269 326 235 331 181 351 118 377 112 390 76 380 27 334 34 324 58 312 83 313 90 318 93 305 208 291 250 280 278 267 300 240 311 233 347 230 365 234 396 252 415 280 418 297 416 315 381 332 353 356 319 399 268 478 275 488 286 522 295 533 308 536 333 509 358 463 360 448 348 420 349 406 411 435 433 459 434 486 428 482 405 512 373 535 353 541 317 542 360 580 394 628 406 595 421 522 434 486 433 459 439 440 454 353 456 307 452 261 433 201 408 167 680 155 748 144 807 125 881 146 907 178 838 193 649 203 522 229 518 268 521 282 692 262 766 248 806 244 838 248 850 254 871 273 879 288 854 296 654 314 558 336 536 332 515 315 508 333 507 368 807 329 845 330 870 338 888 355 894 369 872 377 824 378 792 391 792 382 665 400 681 418 700 430 731 433 786 406 792 391 824 378 876 408 886 419 866 434 765 468 790 486 869 505 917 529 935 545 940 555 941 565 932 581 920 592 908 596 850 597 786 577 739 542 696 497 633 423 608 413 592 415 596 452 583 547 624 534 696 497 739 542 709 563 582 625 553 627 538 621 512 596 484 543 512 551 535 552 533 450 524 430 505 414 464 596 442 653 487 657 537 654 719 628 711 594 711 566 766 588 806 626 859 626 871 622 879 613 945 628 984 652 999 679) (326 156 313 180 312 204 307 226 295 237 286 239 273 237 269 188 224 157 190 124 208 115 232 109 274 108 306 116 318 123 326 133 328 145)) ; 褥
                (28988 1000 (979 837 958 878 922 900 881 912 837 916 782 911 727 897 677 876 637 853 588 764 602 708 604 588 588 584 555 588 554 594 565 610 538 669 507 724 422 851 406 866 398 867 396 878 381 900 372 900 362 914 329 904 326 892 322 903 303 867 335 857 408 772 457 700 489 621 471 603 461 603 460 617 414 608 352 560 393 544 486 531 476 512 473 470 429 439 411 417 376 466 335 510 309 503 303 495 304 484 327 443 328 418 299 366 293 349 310 342 328 341 365 354 404 374 407 402 417 397 460 392 434 320 454 308 477 316 509 338 529 345 535 388 696 381 683 442 648 442 542 453 536 486 538 524 567 526 663 517 683 442 696 381 699 350 686 302 692 277 736 293 754 306 768 322 773 341 771 363 799 383 831 398 856 420 841 436 830 439 761 442 742 474 732 513 780 510 827 518 868 536 899 563 887 572 854 580 722 574 669 581 675 636 666 785 692 803 745 818 787 817 823 803 836 790 844 776 848 758 844 670 846 642 856 650 887 703 905 714 913 734 941 764 948 792 960 805 977 810) (352 789 321 753 289 682 257 567 239 648 195 767 186 768 176 794 170 799 162 799 160 810 150 829 96 871 62 858 47 842 44 828 90 817 94 801 106 787 126 774 123 766 133 755 136 742 140 747 139 763 142 759 154 716 162 710 179 661 202 549 211 430 203 318 193 266 178 217 176 212 165 209 160 184 142 141 188 145 232 174 240 183 244 195 261 208 272 225 281 284 284 394 268 495 267 531 348 614 351 642 382 740 388 778) (798 262 692 264 646 270 636 291 624 349 614 370 584 373 574 367 574 277 493 281 449 275 409 254 391 238 420 224 436 222 532 218 578 209 573 170 544 106 535 77 547 77 598 85 623 98 630 109 638 111 660 152 652 158 643 195 659 199 697 200 717 197 745 181 765 185 806 202 826 215 853 249) (149 553 112 516 80 474 86 448 73 388 124 418 151 445 167 478 172 538)) ; 焼
                (21407 1000 (882 194 812 190 771 195 765 184 688 200 530 208 507 240 486 212 337 227 345 252 346 284 342 328 334 347 370 333 457 321 507 240 530 208 556 222 577 246 583 259 584 287 576 299 562 310 603 314 711 308 708 354 560 360 420 381 424 452 456 454 570 441 608 442 650 457 672 481 431 505 442 582 604 572 690 555 704 444 708 354 711 308 711 294 778 299 802 305 843 325 859 338 870 353 875 370 868 381 857 389 817 404 807 413 775 555 751 618 666 610 609 616 616 648 608 710 614 853 602 897 585 925 572 937 557 948 547 938 505 931 470 916 432 889 366 823 400 840 427 829 482 843 508 839 520 829 535 797 538 733 524 631 478 627 458 631 415 653 364 594 362 494 357 446 342 406 331 389 318 417 308 421 297 477 280 528 243 606 212 655 215 666 212 676 204 690 198 691 194 708 182 719 183 724 188 726 181 733 175 730 161 778 141 793 148 804 105 857 99 845 65 856 57 865 72 863 78 868 96 852 99 845 105 857 85 875 74 882 71 880 78 872 71 873 51 890 41 885 40 876 34 877 20 890 27 867 66 817 74 794 99 769 143 687 164 659 160 642 184 606 217 501 240 464 243 426 266 319 267 272 258 240 226 198 218 168 206 159 204 151 260 146 294 152 309 160 721 131 767 124 794 113 848 130 885 148 901 164 914 183) (880 861 872 863 845 856 835 857 782 770 718 629 788 662 825 690 840 707 866 746 875 768 887 822 889 853) (348 767 327 831 309 862 300 862 280 849 263 825 251 798 247 775 249 765 277 716 317 633 326 639 343 664 360 708 362 751 352 770)) ; 原
                (38343 1000 (913 162 915 179 894 190 879 205 870 224 852 296 849 548 852 528 855 548 875 792 866 890 845 948 764 924 693 891 653 860 640 830 617 803 622 868 615 903 596 902 590 910 560 892 526 884 425 889 415 902 398 900 372 889 347 858 364 769 361 729 354 716 316 694 327 681 343 672 385 664 496 656 544 642 579 644 651 660 658 674 654 699 637 699 626 704 620 713 616 739 618 777 614 796 550 787 533 693 451 699 413 712 407 757 445 751 478 752 515 767 530 781 498 788 452 786 447 792 434 796 404 796 408 848 472 841 544 842 550 787 614 796 675 814 756 827 766 822 771 813 778 777 784 768 776 413 773 400 765 240 753 165 704 166 618 180 608 200 609 254 640 254 684 240 704 243 726 256 752 288 662 296 662 289 653 296 610 303 605 374 630 375 676 366 707 367 773 400 776 413 668 420 609 419 596 442 571 436 554 422 518 381 532 347 536 327 541 210 501 169 495 156 501 143 521 142 554 130 587 124 696 120 743 107 782 105 825 110 868 120 905 138 921 150) (602 619 541 629 504 626 441 630 378 641 312 662 257 633 243 605 277 610 376 596 368 545 339 540 314 531 295 517 281 498 318 498 416 481 448 479 453 460 422 428 399 441 370 428 354 428 259 449 222 450 216 499 203 790 208 876 216 902 216 918 206 928 183 919 142 877 121 865 117 848 120 809 133 803 143 682 161 267 116 233 108 222 102 207 110 195 118 197 117 192 105 184 154 168 331 142 349 137 378 119 454 134 475 144 490 160 496 188 467 202 447 234 363 232 356 200 350 190 293 197 212 218 238 256 230 275 232 284 252 284 324 272 352 278 362 288 362 308 227 332 222 365 221 400 244 401 324 388 357 388 362 308 362 288 363 232 447 234 441 272 433 382 421 412 457 410 478 412 511 428 522 445 510 462 510 472 533 466 582 464 629 471 652 482 656 494 668 502 658 509 644 511 592 507 571 510 524 536 516 517 443 519 418 535 431 560 435 575 433 589 511 585 524 536 571 510 583 527 586 538 582 574 652 576 687 585 713 603 721 617)) ; 闇
                (22812 1000 (919 286 884 294 748 287 604 288 493 294 386 307 409 328 416 352 416 368 383 397 333 471 347 504 345 522 352 530 375 536 381 545 472 440 521 371 504 336 505 316 570 311 589 315 605 326 618 343 638 344 687 341 700 395 625 400 590 406 561 422 541 453 583 467 645 518 605 578 569 552 541 520 508 492 498 514 477 535 452 552 420 567 464 602 545 652 577 617 605 578 645 518 685 439 700 395 687 341 694 332 697 320 750 317 785 327 817 343 871 383 888 399 804 445 758 486 736 535 620 695 631 704 686 729 695 740 742 754 758 768 796 773 835 784 870 802 885 814 901 846 933 862 933 868 924 890 924 903 881 934 855 944 834 947 793 945 677 903 574 796 506 733 471 731 492 716 424 642 347 577 344 709 352 759 340 882 354 945 351 960 344 970 308 957 294 947 272 921 246 873 263 815 272 753 276 548 186 654 93 736 70 748 55 750 36 750 32 742 5 737 33 721 86 669 112 651 99 654 98 648 124 636 133 626 139 612 122 626 131 609 199 531 221 488 297 386 311 358 311 343 306 327 274 330 218 350 192 355 132 298 116 267 111 248 212 252 470 235 475 219 473 196 459 180 403 147 393 121 404 115 414 116 438 96 470 92 504 98 546 115 555 137 557 157 551 176 515 226 742 222 752 218 763 203 773 200 895 237 931 254 946 266)) ; 夜
                (26143 1000 (898 910 874 910 711 897 482 899 320 913 192 941 163 933 138 913 92 851 103 846 114 845 159 854 228 854 472 830 473 824 471 770 374 781 333 778 292 760 269 735 277 721 288 716 345 723 422 713 463 714 468 695 469 646 355 651 313 648 310 654 312 658 277 706 231 750 174 719 243 625 273 558 261 538 247 525 241 505 279 496 301 496 341 505 357 514 375 533 380 544 378 570 369 585 466 579 470 543 465 506 456 493 443 484 387 490 344 490 302 482 284 473 271 461 261 445 266 344 262 305 252 270 236 247 175 192 174 182 184 178 186 170 201 165 289 147 477 130 614 128 636 124 670 109 734 114 773 121 806 134 832 154 850 183 855 201 845 213 833 218 796 224 775 234 760 323 658 270 657 227 651 183 493 186 341 206 340 214 327 223 328 268 336 291 394 284 478 282 476 278 495 273 534 272 585 288 610 307 618 318 547 328 409 338 337 352 341 422 398 423 578 412 648 417 658 270 760 323 726 465 714 469 705 480 621 468 581 469 543 475 548 498 545 571 602 566 647 551 728 589 742 605 753 624 546 635 542 652 540 695 552 702 566 704 611 693 650 696 682 712 700 728 726 761 684 763 592 758 541 762 539 826 579 826 702 834 725 832 744 826 759 814 816 818 904 854 927 882 930 903)) ; 星
                (19968 1000 (950 540 945 549 816 530 708 519 529 515 522 509 519 501 516 515 363 532 274 549 250 557 190 590 171 594 144 586 109 552 90 542 66 470 74 446 132 464 195 469 525 448 761 446 769 429 811 424 824 428 848 446 893 463 916 477 945 502 961 539)) ; 一
                (19977 1000 (963 808 951 828 928 841 893 837 809 816 750 816 676 808 637 811 643 803 571 804 430 812 316 824 238 840 151 866 125 862 100 846 70 795 42 765 37 751 63 748 118 762 156 763 349 743 441 738 598 736 751 743 776 725 805 726 859 737 885 746 932 772 972 802) (456 302 364 312 287 328 264 330 239 321 223 307 180 260 164 230 168 221 182 212 182 204 228 219 278 228 383 235 622 225 686 208 711 207 734 212 799 243 814 274 813 292) (721 546 544 545 440 550 391 559 318 581 258 542 240 525 212 491 294 484 550 474 645 461 698 475 745 497 760 527 762 542)) ; 三
                (22235 1000 (938 364 886 356 760 365 748 300 688 296 552 297 598 370 594 462 594 484 604 520 636 523 683 548 705 574 711 588 712 603 694 605 637 600 599 588 565 569 540 542 533 524 527 481 522 354 516 300 446 304 406 312 385 318 413 351 422 372 428 394 430 443 424 492 408 539 383 582 368 599 334 622 316 628 284 622 260 621 319 538 350 474 362 428 361 369 342 318 261 331 224 342 220 434 224 639 221 736 735 715 758 488 760 365 886 356 862 470 826 756 811 816 781 844 756 832 719 781 663 778 524 782 224 805 221 830 189 814 142 764 153 623 152 548 146 473 129 384 67 328 71 316 87 302 90 290 112 290 156 280 465 249 616 246 732 252 756 234 788 231 822 239 856 255 885 276 906 297 936 311 960 333 968 363)) ; 四
                (20116 1000 (948 862 923 863 727 830 629 828 510 830 248 846 206 854 179 864 163 875 135 880 98 872 62 851 23 809 16 797 21 791 44 788 79 797 115 788 296 778 311 736 317 728 326 726 327 717 322 706 351 652 391 533 316 547 253 573 214 562 181 542 156 515 144 484 212 488 405 477 442 353 444 313 441 295 421 263 363 271 270 276 230 242 207 227 202 216 180 194 177 178 190 171 216 170 291 196 315 199 682 168 691 156 763 174 808 197 826 223 818 232 798 240 722 237 584 254 516 256 540 283 545 296 545 324 534 353 500 422 487 465 603 470 651 530 614 522 592 522 464 533 421 644 420 621 412 642 408 655 406 664 391 696 391 702 372 738 382 733 388 722 391 702 391 696 404 681 406 664 408 655 421 651 372 775 542 776 615 771 609 765 649 603 651 530 603 470 668 452 706 460 776 494 796 524 800 537 780 545 765 559 754 579 712 736 694 765 731 775 758 776 783 770 800 758 842 763 886 775 958 807 972 826 974 853)) ; 五
                (37341 1000 (507 275 475 261 448 238 414 193 399 194 390 200 353 256 276 343 251 377 260 385 270 386 314 370 380 366 397 357 404 348 443 357 456 364 487 398 430 416 397 422 407 448 408 462 404 525 454 522 488 530 518 548 535 578 509 586 400 599 401 639 390 832 428 824 468 828 503 841 532 860 526 868 500 878 350 896 292 908 260 921 234 938 213 939 196 935 169 914 127 860 279 850 331 842 324 622 321 602 272 612 247 612 205 606 162 584 144 560 274 541 321 539 325 511 321 447 261 425 231 408 177 476 177 465 169 466 163 490 136 506 90 554 67 570 42 578 29 576 1 552 30 535 64 495 61 512 70 506 71 488 97 467 115 437 158 391 234 272 292 194 317 147 279 91 286 86 294 85 310 91 345 85 360 87 386 99 451 153 483 168 532 219 548 242 549 274) (988 510 968 515 848 508 799 511 791 587 788 789 783 868 768 952 762 963 752 965 739 953 734 941 723 888 716 836 713 525 618 532 557 526 523 514 509 505 490 479 571 467 709 454 711 376 707 303 689 201 664 94 671 85 678 84 787 170 813 205 820 225 804 305 796 451 871 451 885 442 898 438 911 439 952 459 999 494) (560 694 512 756 466 804 438 803 414 797 456 714 476 659 452 620 491 606 520 611 542 624 560 642 570 663 570 673) (263 809 236 798 208 767 191 729 175 641 209 656 224 667 248 695 268 734 275 758 279 811)) ; 針
                )))
