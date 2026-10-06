;;;; lille-art.lisp — LILLE BARRO as art data (docs/duel/DUEL_LILLE.md §3, §9, §10, §12 Art; the model sheet
;;;; docs/research/tybw-characters/notes/lille_barro_model_sheet.md): his four bodies (:lille 182 cm, dark skin #7A6155, all
;;;; in white with the green fur bicorne / stole / panel, the left eye shut under the ring-of-four-arcs mark; :lille-jilliel,
;;;; the holed cream column floating, its face in a round window, its arms hidden in it (the rig's hands are the front wing
;;;; pair's tips); :lille-jilliel-kin, that column on two ㄇ-shaped legs; and :lille-shin, the owl on KIN's model: the column
;;;; in white, the ㄇ legs, long arms and an extra cosmetic pair, a segmented S-neck to a tiny barn-owl face),
;;;; Diagramm (2.4 m: the barrel through a fur sleeve, the plank across the rear, the muzzle cross), the props of his looks
;;;; (the wing blades with their three oval holes, the halos, the open eye, the reticle, the trumpet), every :lb-* pose and
;;;; clip, his draw hook (Jilliel's eight wing blades in two fans / folded in MUJITTAI, the owl's eight gold wings, all of
;;;; them translucent glass in a translucent rim, each blade three jointed segments; the ㄇ legs' shanks and struts; the owl's extra arms; the halos, the aim line
;;;; and its reticle, the eye opening, the trumpet, the reflect), his hazards' look, his HUD meter
;;;; (the eye pips, the halo icon), his one-hand ring, his sounds and brush glyphs, and the cinematics' looks.
;;;; Batch 1 built the functional art (the strikes put the plank (J1 / J2 / the Breaker), the muzzle (J3, K) or the wing /
;;;; arm tips (Jilliel, the owl) where the moves' volumes end: *LB-STRIKE-POINTS*; the host FK test checks them); batch 3b
;;;; (2026-10-06) the look. Everything here is cosmetic: the sim never reads it. The jade is an ink tone and the owl's gold
;;;; is Senjumaru's muted #B89A5A (decision 11): the three spot hues stay FIRE, REIATSU and BLOOD.
(in-package :duel)

;;; ---------------------------------------------------------------- bodies
;; 182 cm (scale 1.0), long-limbed, the anime head x1.2; the hurt cylinder r 0.38 / h 1.80 in every form (the cap, the wings,
;; the halos and the neck add none: a fairness floor)
(defbody :lille (:scale 1.0 :width 1.04 :hunch 0 :hurt-r 0.38 :hurt-h 1.8
                 :girth ((:head 1.2 1.2 1.2))
                 :palette ((:white #xECECE8) (:green #x434D3B) (:green-d #x2A3124) (:skin #x7A6155) (:hair #xD8D2C0)
                           (:button #xBCC1CC) (:black #x16161E) (:eye #xF2F0EC) (:pupil #x2A3124) (:brow #x2A2420)
                           (:mouth #x4A2E2A) (:lid #x2A2420))
                 :rim (#xFFE8C8 0.14))
  ;; white trousers, the buttoned green front panel with its notched point
  (:pelvis (:box 0.34 0.2 0.24 :c :white)
           (:box 0.1 0.24 0.02 :at (0 -0.1 0.125) :c :green)
           (:box 0.07 0.07 0.02 :at (0 -0.22 0.125) :rot (0 0 45) :c :green)
           (:box 0.02 0.02 0.01 :at (0.04 -0.04 0.137) :c :button) (:box 0.02 0.02 0.01 :at (-0.04 -0.04 0.137) :c :button)
           (:box 0.02 0.02 0.01 :at (0.04 -0.12 0.137) :c :button) (:box 0.02 0.02 0.01 :at (-0.04 -0.12 0.137) :c :button))
  ;; the wide white waist band, three buttons on his right
  (:spine (:bevel 0.32 0.24 0.22 0.04 :at (0 0.1 0) :c :white)
          (:box 0.34 0.12 0.24 :at (0 0.02 0) :c :white)
          (:box 0.02 0.02 0.01 :at (0.1 0.09 0.122) :c :button) (:box 0.02 0.02 0.01 :at (0.1 0.05 0.122) :c :button)
          (:box 0.02 0.02 0.01 :at (0.1 0.01 0.122) :c :button))
  ;; the white shirt, a V of skin, the long green fur stole from the neck down the right chest (three grey buttons on its
  ;; inner edge, jagged fur on its outer one), ringing the back of the collar
  (:chest (:bevel 0.42 0.3 0.26 0.05 :at (0 0.11 0) :c :white)
          (:box 0.07 0.1 0.01 :at (0 0.22 0.13) :c :skin)
          (:bevel 0.15 0.52 0.08 0.03 :at (0.105 0.05 0.12) :rot (0 0 -5) :c :green)
          (:box 0.02 0.46 0.02 :at (0.17 0.05 0.155) :rot (0 0 -5) :c :green-d)
          (:cone 0.022 0.06 :at (0.19 0.2 0.12) :rot (0 0 -100) :seg 4 :c :green)
          (:cone 0.022 0.06 :at (0.195 0.06 0.12) :rot (0 0 -95) :seg 4 :c :green)
          (:cone 0.022 0.06 :at (0.19 -0.08 0.12) :rot (0 0 -105) :seg 4 :c :green)
          (:cone 0.03 0.07 :at (0.11 -0.22 0.12) :rot (0 0 180) :seg 4 :c :green)                   ; its tail
          (:box 0.025 0.025 0.012 :at (0.045 0.18 0.162) :c :button) (:box 0.025 0.025 0.012 :at (0.047 0.06 0.162) :c :button)
          (:box 0.025 0.025 0.012 :at (0.049 -0.06 0.162) :c :button)
          (:bevel 0.32 0.07 0.09 0.025 :at (0 0.27 -0.08) :c :green))           ; the stole rings the back of the collar
  (:neck (:cyl 0.05 0.14 :at (0 0.06 0) :c :skin)
         (:bevel 0.1 0.08 0.08 0.025 :at (0.06 0.06 -0.02) :rot (0 0 -20) :c :green))     ; the stole round his neck
  ;; the head (x1.2): the right eye open, the left shut under the mark (a ring broken into four arcs, four ticks pointing
  ;; in at the diagonals: an X with its centre open); the green fur bicorne worn crosswise: a fur rim low on the brow, a
  ;; dome, two fur ridges left and right rising to their points at the front, the white crown between them (a stripe
  ;; from the brow over the top), a steel emblem disc on each side; cream sideburns
  (:head (:sphere 0.072 :stretch 0.02 :at (0 0.13 -0.01) :seg 12 :c :skin)
         (:bevel 0.1 0.08 0.08 0.02 :at (0 0.1 0.02) :c :skin)
         (:box 0.024 0.01 0.003 :at (0.028 0.125 0.062) :c :eye)
         (:box 0.011 0.01 0.003 :at (0.026 0.125 0.0635) :c :pupil)
         (:box 0.026 0.004 0.003 :at (0.028 0.142 0.0625) :c :brow)
         (:box 0.026 0.004 0.003 :at (-0.028 0.124 0.0625) :c :lid)                 ; the shut left eye
         (:box 0.022 0.004 0.003 :at (-0.028 0.146 0.0625) :c :brow)
         (:box 0.0085 0.0028 0.002 :at (-0.0116 0.1196 0.0636) :rot (0 0 75) :c :black)      ; the mark: four arcs
         (:box 0.0085 0.0028 0.002 :at (-0.0116 0.1284 0.0636) :rot (0 0 105) :c :black)
         (:box 0.0085 0.0028 0.002 :at (-0.0236 0.1404 0.0636) :rot (0 0 165) :c :black)
         (:box 0.0085 0.0028 0.002 :at (-0.0324 0.1404 0.0636) :rot (0 0 195) :c :black)
         (:box 0.0085 0.0028 0.002 :at (-0.0444 0.1284 0.0636) :rot (0 0 255) :c :black)
         (:box 0.0085 0.0028 0.002 :at (-0.0444 0.1196 0.0636) :rot (0 0 285) :c :black)
         (:box 0.0085 0.0028 0.002 :at (-0.0324 0.1076 0.0636) :rot (0 0 345) :c :black)
         (:box 0.0085 0.0028 0.002 :at (-0.0236 0.1076 0.0636) :rot (0 0 375) :c :black)
         (:box 0.009 0.0026 0.002 :at (-0.0156 0.1364 0.0636) :rot (0 0 45) :c :black)        ; ... and four inward ticks
         (:box 0.009 0.0026 0.002 :at (-0.0404 0.1364 0.0636) :rot (0 0 135) :c :black)
         (:box 0.009 0.0026 0.002 :at (-0.0404 0.1116 0.0636) :rot (0 0 225) :c :black)
         (:box 0.009 0.0026 0.002 :at (-0.0156 0.1116 0.0636) :rot (0 0 315) :c :black)
         (:box 0.016 0.003 0.003 :at (0 0.075 0.058) :c :mouth)
         (:box 0.018 0.05 0.03 :at (0.068 0.12 0.0) :c :hair) (:box 0.018 0.05 0.03 :at (-0.068 0.12 0.0) :c :hair)
         (:box 0.11 0.02 0.04 :at (0 0.11 -0.07) :c :hair)                                    ; the cream undercut at the nape
         (:cyl 0.088 0.055 :at (0 0.172 -0.012) :seg 14 :c :green)                           ; the fur rim, low on the brow
         (:sphere 0.08 :at (0 0.205 -0.015) :seg 12 :c :green)                               ; the dome
         (:sphere 0.044 :stretch 0.065 :at (0.05 0.245 -0.01) :rot (0 105 0) :seg 10 :c :green)   ; the two ridges, the
         (:sphere 0.044 :stretch 0.065 :at (-0.05 0.245 -0.01) :rot (0 105 0) :seg 10 :c :green) ; front ends raised
         (:sphere 0.038 :stretch 0.03 :at (0.056 0.282 0.045) :rot (0 -20 -14) :seg 10 :c :green)  ; the points, left and
         (:sphere 0.038 :stretch 0.03 :at (-0.056 0.282 0.045) :rot (0 -20 14) :seg 10 :c :green)  ; right: rounded lobes
         (:bevel 0.03 0.04 0.2 0.012 :at (0 0.252 -0.012) :c :white)                       ; the white crown between them
         (:bevel 0.03 0.07 0.014 0.006 :at (0 0.224 0.086) :c :white)                      ; its stripe down the front
         (:cone 0.016 0.035 :at (0.075 0.16 0.07) :rot (0 0 -150) :seg 4 :c :green-d)       ; jagged fur on the rim
         (:cone 0.016 0.035 :at (-0.075 0.16 0.07) :rot (0 0 150) :seg 4 :c :green-d)
         (:cone 0.016 0.035 :at (0.09 0.16 -0.04) :rot (0 0 -120) :seg 4 :c :green-d)
         (:cone 0.016 0.035 :at (-0.09 0.16 -0.04) :rot (0 0 120) :seg 4 :c :green-d)
         (:cyl 0.022 0.012 :at (0.094 0.215 -0.01) :rot (0 0 90) :seg 10 :c :button)        ; the emblem discs
         (:cyl 0.022 0.012 :at (-0.094 0.215 -0.01) :rot (0 0 90) :seg 10 :c :button))
  (:shoulder-r (:bevel 0.17 0.1 0.22 0.035 :at (0.03 0 0) :c :green)                         ; the stole's fur mass
               (:cone 0.025 0.06 :at (0.13 -0.02 0) :rot (0 0 -95) :seg 4 :c :green)
               (:cone 0.025 0.06 :at (0.1 -0.03 0.08) :rot (0 0 -110) :seg 4 :c :green))
  (:shoulder-l (:sphere 0.06 :at (0.0 -0.01 0) :c :skin))
  (:upper-arm-r (:cyl 0.055 0.3 :top 0.05 :at (0 -0.15 0) :c :white))             ; the white right sleeve
  (:upper-arm-l (:cyl 0.052 0.3 :top 0.045 :at (0 -0.15 0) :c :skin))             ; the bare left arm
  (:lower-arm-r (:cyl 0.045 0.27 :top 0.04 :at (0 -0.13 0) :c :white) (:cyl 0.056 0.06 :top 0.05 :at (0 -0.24 0) :c :white))
  (:lower-arm-l (:cyl 0.044 0.27 :top 0.038 :at (0 -0.13 0) :c :skin) (:cyl 0.056 0.06 :top 0.05 :at (0 -0.24 0) :c :white))
  (:hand-r (:bevel 0.07 0.09 0.04 0.012 :at (0 -0.04 0) :c :white))
  (:hand-l (:bevel 0.07 0.09 0.04 0.012 :at (0 -0.04 0) :c :white))
  (:thigh-r (:cyl 0.09 0.44 :top 0.075 :seg 10 :at (0 -0.21 0) :c :white))
  (:thigh-l (:cyl 0.09 0.44 :top 0.075 :seg 10 :at (0 -0.21 0) :c :white))
  (:shin-r (:cyl 0.07 0.43 :top 0.065 :seg 10 :at (0 -0.2 0) :c :white))
  (:shin-l (:cyl 0.07 0.43 :top 0.065 :seg 10 :at (0 -0.2 0) :c :white))
  (:foot-r (:bevel 0.08 0.06 0.22 0.02 :at (0 -0.03 0.05) :c :white))
  (:foot-l (:bevel 0.08 0.06 0.22 0.02 :at (0 -0.03 0.05) :c :white)))

;; 神の裁き JILLIEL: the slender holed cream column (no legs drawn: the rig's legs carry nothing), widest at the top, ending in
;; two prongs; round holes pierce it (four near the top, six near the bottom); its face shows in a round window near the
;; top (the mouth covered), two horn points at the top corners. No arms (decision 19, 2026-10-06): the rig's arms (x2.6
;; long) are hidden in the column and drawn as nothing; his eight wing blades are drawn by his :draw hook (LILLE-DRAW: two
;; fans of four rooted behind the column's top; the front pair runs from its root to the rig's hands, so a J / K strikes
;; with a wing tip at the hand; folded in MUJITTAI) with the wide halo. Muted jade (decision 11).
(defbody :lille-jilliel (:scale 1.0 :width 1.0 :hunch 0 :hurt-r 0.38 :hurt-h 1.8 :props (:arms 2.6)
                         :palette ((:cream #xEDE6CC) (:cream-d #xD9D0B2) (:jade #x6E9A80) (:jade-d #x4E6E5C) (:hole #x2A2A30)
                                   (:core #x9CC4AC) (:skin #x7A6155) (:eye #xF2F0EC) (:pupil #x2A3124))
                         :rim (#xFFE8C8 0.14))
  (:pelvis (:cyl 0.15 0.7 :top 0.13 :seg 12 :at (0 -0.3 0) :c :cream)
           (:cone 0.075 0.32 :at (0.085 -0.8 0) :rot (0 0 172) :seg 6 :c :cream)        ; the two prongs
           (:cone 0.075 0.32 :at (-0.085 -0.8 0) :rot (0 0 188) :seg 6 :c :cream)
           (:cyl 0.15 0.05 :top 0.15 :seg 12 :at (0 -0.66 0) :c :cream-d)
           (:cyl 0.03 0.012 :at (0.05 -0.15 0.138) :rot (0 90 0) :seg 10 :c :hole)      ; six holes near the bottom
           (:cyl 0.03 0.012 :at (-0.06 -0.3 0.14) :rot (0 90 0) :seg 10 :c :hole)
           (:cyl 0.03 0.012 :at (0.045 -0.46 0.143) :rot (0 90 0) :seg 10 :c :hole)
           (:cyl 0.028 0.012 :at (-0.04 -0.58 0.145) :rot (0 90 0) :seg 10 :c :hole)
           (:cyl 0.03 0.012 :at (0.142 -0.36 0) :rot (0 0 90) :seg 10 :c :hole)
           (:cyl 0.03 0.012 :at (-0.143 -0.42 0) :rot (0 0 90) :seg 10 :c :hole)
           (:cyl 0.03 0.012 :at (0.02 -0.28 -0.142) :rot (0 90 0) :seg 10 :c :hole))
  (:spine (:cyl 0.13 0.3 :top 0.15 :seg 12 :at (0 0.1 0) :c :cream)
          (:cyl 0.026 0.012 :at (-0.05 0.12 0.138) :rot (0 90 0) :seg 10 :c :hole))
  (:chest (:cyl 0.16 0.42 :top 0.19 :seg 12 :at (0 0.14 0) :c :cream)
          (:cyl 0.032 0.012 :at (0.07 0.24 0.178) :rot (0 90 0) :seg 10 :c :hole)       ; four holes near the top
          (:cyl 0.032 0.012 :at (-0.075 0.2 0.176) :rot (0 90 0) :seg 10 :c :hole)
          (:cyl 0.03 0.012 :at (0.0 0.06 0.17) :rot (0 90 0) :seg 10 :c :hole)
          (:cyl 0.03 0.012 :at (0.168 0.16 0.0) :rot (0 0 90) :seg 10 :c :hole)
          (:cyl 0.03 0.012 :at (-0.17 0.12 0.0) :rot (0 0 90) :seg 10 :c :hole)
          (:cyl 0.03 0.012 :at (0.05 0.2 -0.18) :rot (0 90 0) :seg 10 :c :hole)
          (:sphere 0.09 :stretch 0.04 :at (0 0.3 -0.13) :rot (0 0 90) :seg 10 :c :cream-d))   ; the wings' root, behind the top
  (:neck (:cyl 0.13 0.15 :seg 12 :at (0 0.06 0) :c :cream :tag :jl-head))
  ;; the top of the column: the face in a round window (tagged: the revival's headless column hides it), two horn points
  (:head (:sphere 0.15 :stretch 0.03 :at (0 0.12 0) :seg 12 :c :cream :tag :jl-head)
         (:cyl 0.078 0.024 :at (0 0.12 0.138) :rot (0 90 0) :seg 14 :c :hole :tag :jl-head)    ; the face window
         (:sphere 0.058 :at (0 0.12 0.1) :seg 10 :c :skin :tag :jl-head)
         (:box 0.02 0.008 0.003 :at (0.022 0.135 0.157) :c :eye :tag :jl-head)                 ; both eyes open
         (:box 0.02 0.008 0.003 :at (-0.022 0.135 0.157) :c :eye :tag :jl-head)
         (:box 0.008 0.008 0.003 :at (0.022 0.135 0.159) :c :pupil :tag :jl-head)
         (:box 0.008 0.008 0.003 :at (-0.022 0.135 0.159) :c :pupil :tag :jl-head)
         (:box 0.13 0.06 0.02 :at (0 0.085 0.15) :c :cream :tag :jl-head)                     ; the mouth covered
         (:cone 0.038 0.15 :at (0.11 0.28 0) :rot (0 0 -20) :seg 5 :c :cream :tag :jl-head)    ; the two horn points
         (:cone 0.038 0.15 :at (-0.11 0.28 0) :rot (0 0 20) :seg 5 :c :cream :tag :jl-head)
         (:cyl 0.026 0.012 :at (0.08 0.2 0.12) :rot (0 90 0) :seg 10 :c :hole :tag :jl-head)))

;; JILLIEL 近 KIN (decision 18, §22.2): the same column from the hips up on two long thin cream legs: the column's lower half
;; becomes a short rounded hip mass. The legs are ㄇ-shaped (decision 26, 2026-10-06: 「近戰與梟頭的腿部是從分岔點向後延伸出垂直
;; 支架，在末端才以折角往下延伸，呈現出 ㄇ 字型」): a thigh down to the fork (here: the thigh and the fork's knob), then the
;; front shank straight down from the fork, a strut running back from it and, at its end, the corner and the rear shank
;; down; LILLE-DRAW draws the shanks and the strut in the thigh's frame, each shank's tip on the floor (they stretch or
;; shrink a little with the clips' float, so the feet stay down). Arms hidden and wings drawn as :lille-jilliel.
(defbody :lille-jilliel-kin (:scale 1.0 :width 1.0 :hunch 0 :hurt-r 0.38 :hurt-h 1.8 :props (:arms 2.6)
                             :palette ((:cream #xEDE6CC) (:cream-d #xD9D0B2) (:hole #x2A2A30) (:skin #x7A6155) (:eye #xF2F0EC)
                                       (:pupil #x2A3124))
                             :rim (#xFFE8C8 0.14))
  (:pelvis (:cyl 0.15 0.26 :top 0.13 :seg 12 :at (0 -0.08 0) :c :cream)
           (:sphere 0.15 :stretch -0.03 :at (0 -0.2 0) :seg 12 :c :cream)                ; the rounded hip mass
           (:cyl 0.03 0.012 :at (0.05 -0.1 0.138) :rot (0 90 0) :seg 10 :c :hole)
           (:cyl 0.028 0.012 :at (-0.06 -0.2 0.135) :rot (0 90 0) :seg 10 :c :hole)
           (:cyl 0.03 0.012 :at (0.142 -0.12 0) :rot (0 0 90) :seg 10 :c :hole)
           (:cyl 0.03 0.012 :at (-0.143 -0.16 0) :rot (0 0 90) :seg 10 :c :hole))
  (:spine (:cyl 0.13 0.3 :top 0.15 :seg 12 :at (0 0.1 0) :c :cream)
          (:cyl 0.026 0.012 :at (-0.05 0.12 0.138) :rot (0 90 0) :seg 10 :c :hole))
  (:chest (:cyl 0.16 0.42 :top 0.19 :seg 12 :at (0 0.14 0) :c :cream)
          (:cyl 0.032 0.012 :at (0.07 0.24 0.178) :rot (0 90 0) :seg 10 :c :hole)
          (:cyl 0.032 0.012 :at (-0.075 0.2 0.176) :rot (0 90 0) :seg 10 :c :hole)
          (:cyl 0.03 0.012 :at (0.0 0.06 0.17) :rot (0 90 0) :seg 10 :c :hole)
          (:cyl 0.03 0.012 :at (0.168 0.16 0.0) :rot (0 0 90) :seg 10 :c :hole)
          (:cyl 0.03 0.012 :at (-0.17 0.12 0.0) :rot (0 0 90) :seg 10 :c :hole)
          (:cyl 0.03 0.012 :at (0.05 0.2 -0.18) :rot (0 90 0) :seg 10 :c :hole)
          (:sphere 0.09 :stretch 0.04 :at (0 0.3 -0.13) :rot (0 0 90) :seg 10 :c :cream-d))
  (:neck (:cyl 0.13 0.15 :seg 12 :at (0 0.06 0) :c :cream :tag :jl-head))
  (:head (:sphere 0.15 :stretch 0.03 :at (0 0.12 0) :seg 12 :c :cream :tag :jl-head)
         (:cyl 0.078 0.024 :at (0 0.12 0.138) :rot (0 90 0) :seg 14 :c :hole :tag :jl-head)
         (:sphere 0.058 :at (0 0.12 0.1) :seg 10 :c :skin :tag :jl-head)
         (:box 0.02 0.008 0.003 :at (0.022 0.135 0.157) :c :eye :tag :jl-head)
         (:box 0.02 0.008 0.003 :at (-0.022 0.135 0.157) :c :eye :tag :jl-head)
         (:box 0.008 0.008 0.003 :at (0.022 0.135 0.159) :c :pupil :tag :jl-head)
         (:box 0.008 0.008 0.003 :at (-0.022 0.135 0.159) :c :pupil :tag :jl-head)
         (:box 0.13 0.06 0.02 :at (0 0.085 0.15) :c :cream :tag :jl-head)
         (:cone 0.038 0.15 :at (0.11 0.28 0) :rot (0 0 -20) :seg 5 :c :cream :tag :jl-head)
         (:cone 0.038 0.15 :at (-0.11 0.28 0) :rot (0 0 20) :seg 5 :c :cream :tag :jl-head)
         (:cyl 0.026 0.012 :at (0.08 0.2 0.12) :rot (0 90 0) :seg 10 :c :hole :tag :jl-head))
  ;; the thighs (0.44 m) to the fork's knob; the ㄇ below it is LILLE-DRAW's (%LB-LEGS)
  (:thigh-r (:cyl 0.042 0.46 :top 0.055 :seg 8 :at (0 -0.22 0) :c :cream) (:sphere 0.05 :seg 8 :at (0 -0.44 0) :c :cream-d))
  (:thigh-l (:cyl 0.042 0.46 :top 0.055 :seg 8 :at (0 -0.22 0) :c :cream) (:sphere 0.05 :seg 8 :at (0 -0.44 0) :c :cream-d)))

;; 真の姿 the owl, built on KIN's model (decision 27, 2026-10-06: 「梟頭型態的建模在原作中會呈現以目前的近戰型態為基礎，並將頭部換成
;; 長頸梟頭與增加額外的手臂」): KIN's column (the rounded hip mass, the column widening to its top, its holes quiet in a cold
;; shade) in the owl's white (the sheet's §5.4: white, gold only on the wings, the halo and the glow), the ribbon tendrils
;; trailing from the hips, the ㄇ legs (the thighs here, the shanks and the strut drawn by LILLE-DRAW as KIN's), a shaggy fur
;; ruff on the column's top and, in place of Jilliel's face, the segmented S-neck (belly plates in front, a fur crest behind)
;; to a tiny barn-owl face (a pale round facial disc, two big dark eyes, a small hooked beak, the hair swept back into the
;; neck fur). Its long thin arms (x2.2) are the rig's: the claws are the hands (the strike points). They are decision 27's
;; "extra arms" (KIN has none drawn; a second cosmetic pair was cut, the user 2026-10-06: 「梟頭狀態多了一組手臂」); LILLE-DRAW
;; adds the eight gold wings and the small spiked halo (it cracks when Trompete is sealed).
(defbody :lille-shin (:scale 1.0 :width 1.0 :hunch 0 :hurt-r 0.38 :hurt-h 1.8 :props (:arms 2.2 :legs 1.5)
                      :palette ((:white #xECECE8) (:shade #xBCC1CC) (:fur #xD8DCE4) (:face #xF0ECE4) (:gold #xB89A5A)
                                (:gold-l #xC2A866) (:ink #x16161E) (:hole #x2A2A30) (:beak #x8C8E96))
                      :rim (#xFFE8C8 0.14))
  (:pelvis (:cyl 0.15 0.26 :top 0.13 :seg 12 :at (0 -0.08 0) :c :white)
           (:sphere 0.15 :stretch -0.03 :at (0 -0.2 0) :seg 12 :c :white)                ; the rounded hip mass
           (:cyl 0.03 0.012 :at (0.05 -0.1 0.138) :rot (0 90 0) :seg 10 :c :shade)
           (:cyl 0.028 0.012 :at (-0.06 -0.2 0.135) :rot (0 90 0) :seg 10 :c :shade)
           (:cyl 0.03 0.012 :at (0.142 -0.12 0) :rot (0 0 90) :seg 10 :c :shade)
           (:cyl 0.03 0.012 :at (-0.143 -0.16 0) :rot (0 0 90) :seg 10 :c :shade)
           (:box 0.02 0.55 0.004 :at (0.1 -0.3 -0.3) :rot (0 30 0) :c :fur)                  ; ribbon tendrils
           (:box 0.02 0.55 0.004 :at (-0.1 -0.3 -0.3) :rot (0 30 0) :c :fur)
           (:box 0.02 0.45 0.004 :at (0 -0.26 -0.32) :rot (0 36 0) :c :fur))
  (:spine (:cyl 0.13 0.3 :top 0.15 :seg 12 :at (0 0.1 0) :c :white)
          (:cyl 0.026 0.012 :at (-0.05 0.12 0.138) :rot (0 90 0) :seg 10 :c :shade))
  (:chest (:cyl 0.16 0.42 :top 0.19 :seg 12 :at (0 0.14 0) :c :white)
          (:cyl 0.032 0.012 :at (0.07 0.2 0.172) :rot (0 90 0) :seg 10 :c :shade)
          (:cyl 0.032 0.012 :at (-0.075 0.16 0.17) :rot (0 90 0) :seg 10 :c :shade)
          (:cyl 0.03 0.012 :at (0.0 0.04 0.168) :rot (0 90 0) :seg 10 :c :shade)
          (:cyl 0.03 0.012 :at (0.05 0.2 -0.18) :rot (0 90 0) :seg 10 :c :shade)
          (:sphere 0.2 :stretch -0.06 :at (0 0.36 -0.01) :seg 10 :c :fur)                 ; the fur ruff, shaggy, on the top
          (:cone 0.06 0.14 :at (0.2 0.37 0) :rot (0 0 -80) :seg 4 :c :fur) (:cone 0.06 0.14 :at (-0.2 0.37 0) :rot (0 0 80) :seg 4 :c :fur)
          (:cone 0.06 0.14 :at (0.14 0.39 0.14) :rot (0 -40 -50) :seg 4 :c :fur) (:cone 0.06 0.14 :at (-0.14 0.39 0.14) :rot (0 -40 50) :seg 4 :c :fur)
          (:cone 0.06 0.14 :at (0.12 0.39 -0.16) :rot (0 40 -50) :seg 4 :c :fur) (:cone 0.06 0.14 :at (-0.12 0.39 -0.16) :rot (0 40 50) :seg 4 :c :fur)
          (:cone 0.06 0.14 :at (0 0.39 0.19) :rot (0 -70 0) :seg 4 :c :fur) (:cone 0.06 0.14 :at (0 0.39 -0.2) :rot (0 70 0) :seg 4 :c :fur)
          (:sphere 0.09 :stretch 0.04 :at (0 0.3 -0.13) :rot (0 0 90) :seg 10 :c :fur))   ; the wings' root, behind the top
  (:neck (:cyl 0.05 0.16 :at (0 0.06 0) :seg 8 :c :white))
  ;; the S-neck (five segments rising back, then forward and over), then the face
  (:head (:cyl 0.046 0.186 :top 0.041 :at (0 0.075 -0.035) :rot (0 25.0 0) :seg 8 :c :white)
         (:box 0.05 0.012 0.02 :at (0 0.092 0.0) :rot (0 25.0 0) :c :shade)
         (:box 0.016 0.149 0.03 :at (0 0.056 -0.077) :rot (0 25.0 0) :c :fur)
         (:cyl 0.042 0.181 :top 0.038 :at (0 0.23 -0.08) :rot (0 7.1 0) :seg 8 :c :white)
         (:box 0.05 0.012 0.02 :at (0 0.234 -0.045) :rot (0 7.1 0) :c :shade)
         (:box 0.016 0.145 0.03 :at (0 0.225 -0.122) :rot (0 7.1 0) :c :fur)
         (:cyl 0.038 0.178 :top 0.034 :at (0 0.385 -0.065) :rot (0 -18.4 0) :seg 8 :c :white)
         (:box 0.05 0.012 0.02 :at (0 0.375 -0.034) :rot (0 -18.4 0) :c :shade)
         (:box 0.016 0.142 0.03 :at (0 0.397 -0.101) :rot (0 -18.4 0) :c :fur)
         (:cyl 0.034 0.169 :top 0.031 :at (0 0.515 0.01) :rot (0 -42.3 0) :seg 8 :c :white)
         (:box 0.05 0.012 0.02 :at (0 0.496 0.031) :rot (0 -42.3 0) :c :shade)
         (:box 0.016 0.134 0.03 :at (0 0.538 -0.015) :rot (0 -42.3 0) :c :fur)
         (:cyl 0.031 0.141 :top 0.028 :at (0 0.595 0.115) :rot (0 -65.6 0) :seg 8 :c :white)
         (:box 0.05 0.012 0.02 :at (0 0.571 0.126) :rot (0 -65.6 0) :c :shade)
         (:box 0.016 0.109 0.03 :at (0 0.623 0.102) :rot (0 -65.6 0) :c :fur)
         ;; the tiny barn-owl face, looking ahead from the top of the hook
         (:sphere 0.068 :at (0 0.62 0.2) :seg 10 :c :white)                                 ; the skull
         (:box 0.05 0.03 0.1 :at (0 0.665 0.15) :rot (0 -20 0) :c :fur)                      ; the hair swept back
         (:cyl 0.084 0.016 :at (0 0.615 0.252) :rot (0 90 0) :seg 14 :c :shade)              ; the disc's dark rim
         (:cyl 0.076 0.02 :at (0 0.615 0.262) :rot (0 90 0) :seg 14 :c :face)                ; the pale facial disc
         (:box 0.012 0.07 0.01 :at (0 0.625 0.274) :c :fur)                                  ; the heart's middle ridge
         (:sphere 0.022 :at (0.033 0.628 0.27) :seg 8 :c :ink) (:sphere 0.022 :at (-0.033 0.628 0.27) :seg 8 :c :ink)
         (:box 0.008 0.008 0.004 :at (0.028 0.636 0.291) :c :face :ink 0) (:box 0.008 0.008 0.004 :at (-0.038 0.636 0.291) :c :face :ink 0)
         (:cone 0.013 0.045 :at (0 0.585 0.282) :rot (0 200 0) :seg 4 :c :beak))           ; the small hooked beak
  (:shoulder-r (:sphere 0.055 :c :white))
  (:shoulder-l (:sphere 0.055 :c :white))
  (:upper-arm-r (:cyl 0.032 0.66 :top 0.027 :seg 8 :at (0 -0.33 0) :c :white))
  (:upper-arm-l (:cyl 0.032 0.66 :top 0.027 :seg 8 :at (0 -0.33 0) :c :white))
  (:lower-arm-r (:cyl 0.027 0.6 :top 0.022 :seg 8 :at (0 -0.3 0) :c :white))
  (:lower-arm-l (:cyl 0.027 0.6 :top 0.022 :seg 8 :at (0 -0.3 0) :c :white))
  (:hand-r (:box 0.05 0.12 0.02 :at (0 -0.06 0) :c :white) (:box 0.008 0.1 0.008 :at (0.015 -0.16 0) :c :shade)
           (:box 0.008 0.09 0.008 :at (-0.012 -0.15 0) :c :shade))
  (:hand-l (:box 0.05 0.12 0.02 :at (0 -0.06 0) :c :white) (:box 0.008 0.1 0.008 :at (-0.015 -0.16 0) :c :shade)
           (:box 0.008 0.09 0.008 :at (0.012 -0.15 0) :c :shade))
  ;; the thighs (0.44 m, KIN's) to the fork's knob; the ㄇ below it is LILLE-DRAW's (%LB-LEGS)
  (:thigh-r (:cyl 0.04 0.46 :top 0.05 :seg 8 :at (0 -0.22 0) :c :white) (:sphere 0.048 :seg 8 :at (0 -0.44 0) :c :shade))
  (:thigh-l (:cyl 0.04 0.46 :top 0.05 :seg 8 :at (0 -0.22 0) :c :white) (:sphere 0.048 :seg 8 :at (0 -0.44 0) :c :shade)))

;;; ---------------------------------------------------------------- Diagramm and the props
;; ディアグラム DIAGRAMM: 2.4 m. The grip at the sleeve's rear: the barrel runs 1.75 m to the muzzle cross (the weapon's
;; length: the tip the FK test measures), 0.65 m back to the tall black plank across the rear (the butt, measured at a
;; negative weapon-length point, *LB-BUTT*); the green fur sleeve over the barrel's rear part (two dark ports, jagged fur
;; at its ends), a dial knob on the plank
(defparameter *lb-butt* 0.6 "Diagramm: the plank's strike point, metres behind the grip (the weapon frame's -Y; the FK test).")
(defweapon :diagramm (:length 1.75 :base 0.3)
  (:solid (mbc mb #x16161E)
          (with-xform (mb (xform :y 0.55)) (mb-cylinder mb 0.024 2.4 :segments 6))           ; the barrel, -0.65 .. 1.75
          (with-xform (mb (xform :y 1.72)) (mb-box mb 0.2 0.07 0.05) (mb-box mb 0.05 0.07 0.2))   ; the muzzle cross
          (with-xform (mb (xform :y -0.6 :z 0.15)) (mb-box mb 0.035 0.1 1.2))                 ; the plank, across the rear
          (with-xform (mb (xform :y -0.62 :z -0.38)) (mb-box mb 0.12 0.08 0.04))              ; its two lower plates
          (mbc mb #xBCC1CC) (with-xform (mb (xform :y -0.56 :z 0.42 :x 0.03)) (mb-cylinder mb 0.03 0.02 :segments 8)))
  (:solid (mbc mb #x434D3B) (with-xform (mb (xform :y 0.2)) (mb-cylinder mb 0.1 0.6 :segments 8))      ; the fur sleeve
          (with-xform (mb (xform :y 0.5 :x 0.1 :roll -1.4)) (mb-cone mb 0.03 0.06 :segments 4))      ; jagged fur
          (with-xform (mb (xform :y -0.09 :x -0.1 :roll 1.6)) (mb-cone mb 0.03 0.06 :segments 4))
          (mbc mb #x2A3124) (with-xform (mb (xform :y 0.3 :z 0.1)) (mb-box mb 0.03 0.03 0.012))
          (with-xform (mb (xform :y 0.1 :z 0.1)) (mb-box mb 0.03 0.03 0.012))))

;;; the props' mesh helpers (load time only: they allocate)
(defun lb-plate (mb pts th &optional (z0 0.0))
  "A flat plate: the convex polygon PTS ((x y) ...) in the XY plane, TH thick round Z0: both faces and the rim."
  (let* ((n (length pts)) (cx (/ (reduce #'+ pts :key #'first) n)) (cy (/ (reduce #'+ pts :key #'second) n))
         (c (list cx cy z0)) (h (* 0.5 th))
         (f (mapcar (lambda (p) (v3 (first p) (second p) (+ z0 h))) pts))
         (b (mapcar (lambda (p) (v3 (first p) (second p) (- z0 h))) pts)))
    (mb-poly-out mb f :center c) (mb-poly-out mb b :center c)
    (dotimes (i n)
      (let ((j (mod (1+ i) n))) (mb-poly-out mb (list (nth i f) (nth j f) (nth j b) (nth i b)) :center c)))))

(defun lb-oval (mb cx cy rx ry th &optional (n 12))
  "An oval plate at (CX CY) in the XY plane, radii RX RY, TH thick."
  (lb-plate mb (loop for i below n collect (let ((a (* 2 pi (/ i n)))) (list (+ cx (* rx (cos a))) (+ cy (* ry (sin a)))))) th))

(defun lb-ring (mb r0 r1 th &key (n 24) (from 0) (to n) (y 0.0))
  "A flat ring (an annulus prism) in the XZ plane at height Y, radii R0..R1, TH thick, segments FROM..TO of N."
  (loop for i from from below to
        do (let* ((a0 (* 2 pi (/ i n))) (a1 (* 2 pi (/ (1+ i) n))) (h (* 0.5 th))
                  (p (lambda (r a yy) (v3 (* r (cos a)) yy (* r (sin a)))))
                  (c (list (* 0.5 (+ r0 r1) (cos (* 0.5 (+ a0 a1)))) y (* 0.5 (+ r0 r1) (sin (* 0.5 (+ a0 a1)))))))
             (flet ((q (ra aa rb ab y0 y1) (mb-poly-out mb (list (funcall p ra aa y0) (funcall p rb ab y0) (funcall p rb ab y1)
                                                                 (funcall p ra aa y1)) :center c)))
               (q r0 a0 r0 a1 (- y h) (+ y h)) (q r1 a0 r1 a1 (- y h) (+ y h))
               (mb-poly-out mb (list (funcall p r0 a0 (+ y h)) (funcall p r1 a0 (+ y h)) (funcall p r1 a1 (+ y h))
                                     (funcall p r0 a1 (+ y h))) :center c)
               (mb-poly-out mb (list (funcall p r0 a0 (- y h)) (funcall p r1 a0 (- y h)) (funcall p r1 a1 (- y h))
                                     (funcall p r0 a1 (- y h))) :center c)))))

;; a wing blade (decision 19: the refs' leaf), unit length along +Y from its root to its point, the flat face along Z: narrow
;; at the root, widest at the middle, a long point; its centreline bows toward +X (the trailing edge, torn into four teeth,
;; and the tip comes back onto the root-tip chord: a drawn tip is exactly where the frame puts it); three oval holes along it
;; (the 24 muzzles). Translucent since decision 27 (2026-10-06: 「把翅膀調整成半透明以免遮擋視線」): two meshes per look, the
;; GLASS (the leaf's two faces with the holes cut through, drawn see-through) and the RIM (a dark band round the outline, the
;; teeth and a ring round each hole: what keeps it reading as a holed blade; see-through as well since decision 32).
;; Jointed since decision 32 (2026-10-06: 「每片翅膀改成中間加 2 節可以彎折的連接觸」): the blade is cut at 1/3 and 2/3 of its
;; length into three SEGMENTS (root, middle, tip), each its own mesh in its own frame: segment I is the leaf's part from
;; I/3 to (I+1)/3, moved down by I/3 so its joint (the pivot, on the root-tip chord: x 0) is its origin; LILLE-DRAW chains
;; the three frames (each bends at its pivot). One hole and one or two teeth per segment; a cross band at each cut and a
;; pin at each pivot (the joint). Load time only.
(defparameter *lb-wing-bow* 0.07 "The blade's centreline bow at its middle (unit length).")
(defparameter *lb-wing-stations* '((0.0 0.03 0.03) (0.08 0.06 0.07) (0.2 0.1 0.12) (0.35 0.125 0.15) (0.5 0.13 0.155)
                                   (0.65 0.115 0.14) (0.8 0.08 0.1) (0.91 0.042 0.05) (1.0 0.0 0.0))
  "The blade's outline: y, the leading (-x) and the trailing (+x) half-widths off the bowed centreline.")
(defparameter *lb-wing-teeth* '(0.19 0.40 0.53 0.71)
  "Where the trailing edge's teeth start (unit length; each spans y-0.03..y+0.11, inside one segment; were 0.3 / 0.47 / 0.63
/ 0.77 before the joints, decision 32).")
(defparameter *lb-wing-holes* '((0.2 0.045 0.065) (0.5 0.05 0.075) (0.79 0.038 0.052))
  "y rx ry (unit length), on the centreline: one per segment (were 0.36 / 0.55 / 0.73 before the joints, decision 32).")
(defparameter *lb-wing-band* 0.016 "The rim's band round the outline and the holes (unit length).")
(defparameter *lb-wing-cuts* '(0.0 0.33333334 0.6666667 1.0) "The segments' ends (unit length): the joints at 1/3 and 2/3.")
(defun lb-wing-c (y) (* *lb-wing-bow* 4 y (- 1 y)))
(defun lb-wing-half (y col)
  "The half-width at Y off the centreline: COL 1 the leading side, 2 the trailing side (the stations interpolated)."
  (let ((lo (find-if (lambda (r) (>= (first r) y)) *lb-wing-stations*))
        (hi (find-if (lambda (r) (<= (first r) y)) *lb-wing-stations* :from-end t)))
    (if (or (eq lo hi) (= (first lo) (first hi))) (nth col lo)
        (+ (nth col hi) (* (- y (first hi)) (/ (- (nth col lo) (nth col hi)) (- (first lo) (first hi))))))))
(defun lb-wing-edge (y) "The trailing edge's x at Y." (+ (lb-wing-c y) (lb-wing-half y 2)))
(defun lb-wing-lead (y) "The leading edge's x at Y." (- (lb-wing-c y) (lb-wing-half y 1)))
(defun lb-wing-hole-x (y) "A hole's centre x at Y." (+ 0.01 (lb-wing-c y)))
(defun lb-wing-ys (ya yb)
  "The glass's rows from YA to YB: every 0.025, the stations, finer through each hole (its ends exact, so a row is in or
out), and the segment's ends."
  (sort (remove-duplicates
         (remove-if-not (lambda (y) (<= (- ya 1e-5) y (+ yb 1e-5)))
                        (append (list ya yb) (loop for i to 40 collect (/ i 40.0)) (mapcar #'first *lb-wing-stations*)
                                (loop for (y nil ry) in *lb-wing-holes* append (loop for i to 12 collect (+ (- y ry) (* (/ i 12.0) 2 ry))))))
         :test (lambda (a b) (< (abs (- a b)) 1e-4)))
        #'<))
(defun lb-wing-seg (seg) "Segment SEG's ends (values ya yb)." (values (nth seg *lb-wing-cuts*) (nth (1+ seg) *lb-wing-cuts*)))
(defun lb-shift (pts y0) "PTS ((x y) ...) moved down by Y0 (into a segment's frame)." (mapcar (lambda (p) (list (first p) (- (second p) y0))) pts))
(defun lb-face (mb pts z up)
  "One face of the glass: the convex polygon PTS ((x y) ...) at Z, facing +Z when UP else -Z (no rim: a single layer)."
  (let ((pts (remove-duplicates pts :test (lambda (a b) (< (+ (abs (- (first a) (first b))) (abs (- (second a) (second b)))) 1e-5)))))
    (when (>= (length pts) 3)
      (let ((cx (/ (reduce #'+ pts :key #'first) (length pts))) (cy (/ (reduce #'+ pts :key #'second) (length pts))))
        (mb-poly-out mb (mapcar (lambda (p) (v3 (first p) (second p) z)) pts) :center (list cx cy (if up (- z 1) (+ z 1))))))))
(defun lb-wing-glass (mb body seg)
  "Segment SEG of the see-through leaf: both faces, row by row, its hole cut through (a row inside a hole splits in two)."
  (mbc mb body)
  (multiple-value-bind (ya yb) (lb-wing-seg seg)
    (let ((h 0.008))
      (loop for (y0 y1) on (lb-wing-ys ya yb) while y1
            do (let* ((ym (* 0.5 (+ y0 y1)))
                      (hole (find-if (lambda (hh) (< (abs (- ym (first hh))) (third hh))) *lb-wing-holes*))
                      (spans
                        (if hole
                            (destructuring-bind (hy rx ry) hole
                              (flet ((hw (y) (* rx (sqrt (max 0.0 (- 1 (expt (/ (- y hy) ry) 2)))))))
                                (list (list (list (lb-wing-lead y0) y0) (list (- (lb-wing-hole-x y0) (hw y0)) y0)
                                            (list (- (lb-wing-hole-x y1) (hw y1)) y1) (list (lb-wing-lead y1) y1))
                                      (list (list (+ (lb-wing-hole-x y0) (hw y0)) y0) (list (lb-wing-edge y0) y0)
                                            (list (lb-wing-edge y1) y1) (list (+ (lb-wing-hole-x y1) (hw y1)) y1)))))
                            (list (list (list (lb-wing-lead y0) y0) (list (lb-wing-edge y0) y0)
                                        (list (lb-wing-edge y1) y1) (list (lb-wing-lead y1) y1))))))
                 (dolist (q spans) (let ((q (lb-shift q ya))) (lb-face mb q h t) (lb-face mb q (- h) nil))))))))
(defun lb-wing-rim (mb dark hole-fill seg)
  "Segment SEG's rim: a band inside the outline (leading and trailing edges), its teeth on the trailing edge, a ring round
its hole, a cross band at each cut and a pin at the pivot it hangs from (the joints); HOLE-FILL (a colour, NIJUSHI-KO's
tell) fills the hole with light."
  (mbc mb dark)
  (multiple-value-bind (ya yb) (lb-wing-seg seg)
    (let ((bw *lb-wing-band*) (th 0.024))
      (flet ((plate (pts &optional (th th)) (lb-plate mb (lb-shift pts ya) th)))
        (loop for (y0 y1) on (lb-wing-ys ya yb) while y1
              do (flet ((w (y) (min bw (* 0.5 (+ (lb-wing-half y 1) (lb-wing-half y 2)))))
                        (band (x0 x1 d0 d1)
                          (let ((q (remove-duplicates (list (list x0 y0) (list (+ x0 d0) y0) (list (+ x1 d1) y1) (list x1 y1))
                                                      :test (lambda (a b) (< (+ (abs (- (first a) (first b))) (abs (- (second a) (second b)))) 1e-5)))))
                            (when (>= (length q) 3) (plate q)))))
                   (band (lb-wing-lead y0) (lb-wing-lead y1) (w y0) (w y1))
                   (band (lb-wing-edge y0) (lb-wing-edge y1) (- (w y0)) (- (w y1)))))
        (dolist (y *lb-wing-teeth*)
          (when (<= ya y yb)
            (let ((e0 (lb-wing-edge y)) (e1 (lb-wing-edge (+ y 0.11))))
              (plate (list (list (- e0 0.02) y) (list (- e1 0.02) (+ y 0.11)) (list (+ e0 0.07) (- y 0.03)))))))
        (dolist (yc (list ya yb))                         ; the joints: a cross band inside each cut (not the root, not the point)
          (when (< 0.01 yc 0.99)
            (let ((y1 (if (= yc ya) (+ yc (* 1.4 bw)) (- yc (* 1.4 bw)))))
              (plate (list (list (lb-wing-lead yc) yc) (list (lb-wing-edge yc) yc) (list (lb-wing-edge y1) y1) (list (lb-wing-lead y1) y1))))))
        (when (> ya 0.01)                                 ; ... and the pin at the pivot this segment hangs from
          (lb-oval mb 0.0 0.0 0.024 0.024 0.04 12))
        (dolist (hh *lb-wing-holes*)
          (destructuring-bind (y rx ry) hh
            (when (< ya y yb)
              (let ((x (lb-wing-hole-x y)) (n 16))
                (dotimes (i n)
                  (let ((a0 (* 2 pi (/ i n))) (a1 (* 2 pi (/ (1+ i) n))))
                    (flet ((pt (a r) (list (+ x (* (+ rx r) (cos a))) (+ y (* (+ ry r) (sin a))))))
                      (plate (list (pt a0 0) (pt a0 (* 0.8 bw)) (pt a1 (* 0.8 bw)) (pt a1 0))))))
                (when hole-fill
                  (mbc mb hole-fill) (lb-oval mb x (- y ya) rx ry 0.02 16) (mbc mb dark))))))))))
;; per look, three glass segments and three rim segments (I = 0 root, 1 middle, 2 tip)
(defweapon :lb-wing-0 (:length 1.0) (:solid :ink 0 (lb-wing-glass mb #x6E9A80 0)))   ; Jilliel's glass (muted jade)
(defweapon :lb-wing-1 (:length 1.0) (:solid :ink 0 (lb-wing-glass mb #x6E9A80 1)))
(defweapon :lb-wing-2 (:length 1.0) (:solid :ink 0 (lb-wing-glass mb #x6E9A80 2)))
(defweapon :lb-wing-rim-0 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x2F4A3C nil 0)))   ; ... its rim (the outline, teeth,
(defweapon :lb-wing-rim-1 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x2F4A3C nil 1)))   ;  hole rings and joints)
(defweapon :lb-wing-rim-2 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x2F4A3C nil 2)))
(defweapon :lb-wing-lit-0 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x2F4A3C #xEAF4EE 0)))   ; NIJUSHI-KO's tell: the
(defweapon :lb-wing-lit-1 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x2F4A3C #xEAF4EE 1)))   ;  rim with the holes lit
(defweapon :lb-wing-lit-2 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x2F4A3C #xEAF4EE 2)))
(defweapon :lb-wing-gold-0 (:length 1.0) (:solid :ink 0 (lb-wing-glass mb #xB89A5A 0)))   ; the owl's glass (#B89A5A,
(defweapon :lb-wing-gold-1 (:length 1.0) (:solid :ink 0 (lb-wing-glass mb #xB89A5A 1)))   ;  decision 11)
(defweapon :lb-wing-gold-2 (:length 1.0) (:solid :ink 0 (lb-wing-glass mb #xB89A5A 2)))
(defweapon :lb-wing-gold-rim-0 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x8A7038 nil 0)))   ; ... its rim (a darker
(defweapon :lb-wing-gold-rim-1 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x8A7038 nil 1)))   ;  step of the same hue)
(defweapon :lb-wing-gold-rim-2 (:length 1.0) (:solid :ink 0 (lb-wing-rim mb #x8A7038 nil 2)))
;; the ㄇ legs' props (decision 26), drawn by LILLE-DRAW from the fork at the thigh's end: a shank (unit length along +Y, its
;; root at the origin, tapering to a point; drawn at its length so its tip meets the floor) and the strut (unit along +Y, the
;; corner's knob at its end; drawn at 0.52 m), cream (KIN) or white (the owl)
(defun lb-shank (mb c) (mbc mb c) (with-xform (mb (xform :y 0.5)) (mb-cylinder mb 0.048 1.0 :segments 8 :top-radius 0.006 :smooth t)))
(defun lb-strut (mb c d)
  (mbc mb c) (with-xform (mb (xform :y 0.5)) (mb-cylinder mb 0.08 1.0 :segments 8 :top-radius 0.074 :smooth t))
  (mbc mb d) (with-xform (mb (xform :y 1.0)) (mb-sphere mb 0.11 :segments 8 :rings 5 :smooth t)))
(defweapon :lb-shank-cream (:length 1.0) (:solid (lb-shank mb #xEDE6CC)))
(defweapon :lb-shank-white (:length 1.0) (:solid (lb-shank mb #xECECE8)))
(defweapon :lb-strut-cream (:length 1.0) (:solid (lb-strut mb #xEDE6CC #xD9D0B2)))
(defweapon :lb-strut-white (:length 1.0) (:solid (lb-strut mb #xECECE8 #xBCC1CC)))
;; the halos, unit radius: Jilliel's wide thin flat ring; the owl's small ring with six spikes; the owl's broken one
(defweapon :lb-halo (:length 1.0) (:solid (mbc mb #x9CC4AC) (lb-ring mb 0.9 1.0 0.03 :n 32)))
(defun lb-spikes (mb n &key (skip nil))
  (dotimes (i n)
    (unless (member i skip)
      (let ((a (* 2 pi (/ i n))))
        (with-xform (mb (xform :x (* 0.95 (cos a)) :z (* 0.95 (sin a)) :y 0.18 :yaw (- (/ pi 2) a) :pitch 0.0 :roll -0.25))
          (mb-cone mb 0.09 0.38 :segments 4))))))
(defweapon :lb-halo-gold (:length 1.0) (:solid (mbc mb #xB89A5A) (lb-ring mb 0.82 1.0 0.1 :n 24) (mbc mb #xC2A866) (lb-spikes mb 6)))
(defweapon :lb-halo-broken (:length 1.0)              ; sealed: a piece out, an arc dropped and tilted, a spike lying
  (:solid (mbc mb #x8C7440) (lb-ring mb 0.82 1.0 0.1 :n 24 :from 0 :to 6) (lb-ring mb 0.82 1.0 0.1 :n 24 :from 16 :to 24)
          (with-xform (mb (xform :y -0.16 :x 0.1 :roll 0.28 :pitch 0.12)) (lb-ring mb 0.82 1.0 0.1 :n 24 :from 8 :to 14))
          (mbc mb #x9A8456) (lb-spikes mb 6 :skip '(2 3))
          (with-xform (mb (xform :x 0.2 :y -0.3 :z 0.5 :roll 1.3)) (mb-cone mb 0.09 0.38 :segments 4))))
;; the left eye opened (the base form), in the head joint's frame (the body's x1.2 head girth applied): the eye white, a
;; jade iris, the mark recoloured jade and flaring into four long strokes along its X
(defparameter *lb-eye-at* '(-0.0336 0.1488 -0.0763) "The left eye's centre in the head joint frame (x right, y up, z back).")
(defweapon :lb-eye-open (:length 0.1)
  (:solid :ink 0
          (destructuring-bind (x y z) *lb-eye-at*
            (mbc mb #xF2F0EC) (with-xform (mb (xform :x x :y y :z (- z 0.0012))) (mb-box mb 0.031 0.013 0.003))
            (mbc mb #x6E9A80) (with-xform (mb (xform :x (+ x 0.001) :y y :z (- z 0.0022))) (mb-box mb 0.014 0.013 0.003))
            (mbc mb #x16161E) (with-xform (mb (xform :x (+ x 0.001) :y y :z (- z 0.003))) (mb-box mb 0.006 0.008 0.003))
            (with-xform (mb (xform :x x :y (+ y 0.0085) :z (- z 0.0026))) (mb-box mb 0.032 0.0035 0.003))
            (mbc mb #x9CC4AC)
            (dolist (a '(0 90 180 270))
              (dolist (d '(-15 15))
                (let ((tt (* (/ pi 180) (+ a d))))
                  (with-xform (mb (xform :x (+ x (* 0.0204 (cos tt))) :y (+ y (* 0.0204 (sin tt))) :z (- z 0.0034)
                                         :roll (+ tt (/ pi 2))))
                    (mb-box mb 0.0104 0.0036 0.002)))))
            (mbc mb #xEAF4EE)
            (dolist (a '(45 135 225 315))
              (let ((tt (* (/ pi 180) a)))
                (with-xform (mb (xform :x (+ x (* 0.045 (cos tt))) :y (+ y (* 0.045 (sin tt))) :z (- z 0.004) :roll tt))
                  (mb-box mb 0.058 0.004 0.002)))))))
;; the reticle (the eye mark, the motif: DUEL_LILLE §3): four arcs and four inward ticks, unit radius, flat in XZ
(defun lb-reticle-mesh (mb)
  (dolist (k '(0 6 12 18)) (lb-ring mb 0.84 1.0 0.03 :n 24 :from (- k 2) :to (+ k 2)))
  (dolist (a '(0.7854 2.3562 3.927 5.4978))
    (with-xform (mb (xform :x (* 0.76 (cos a)) :z (* 0.76 (sin a)) :yaw (- a))) (mb-box mb 0.4 0.03 0.11))))
(defweapon :lb-reticle-grey (:length 1.0) (:solid :ink 0 (mbc mb #xE4E6EA) (lb-reticle-mesh mb)))
(defweapon :lb-reticle-jade (:length 1.0) (:solid :ink 0 (mbc mb #xB4DCC4) (lb-reticle-mesh mb)))
;; the looks' line props, unit along +Y (a floor line: X across, Z its thickness)
(defweapon :lb-line (:length 1.0) (:solid :ink 0 (mbc mb #x3A3E48) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))
(defweapon :lb-line-jade (:length 1.0) (:solid :ink 0 (mbc mb #x7FAE92) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))
(defweapon :lb-line-grey (:length 1.0) (:solid :ink 0 (mbc mb #xB4B8C0) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))
;; 神の喇叭 the trumpet, unit length along +Y from the mouthpiece to the bell: a long plain gold horn (no valves) flaring to
;; a wide bell whose ring is joined to an outer ring by four struts (the reticle again), a plume of five curved feather
;; blades rising (+X) near the mouthpiece
(defweapon :lb-trumpet (:length 1.0)
  (:solid (mbc mb #xB89A5A)
          (with-xform (mb (xform :y 0.4)) (mb-cylinder mb 0.022 0.8 :segments 8 :top-radius 0.05))
          (with-xform (mb (xform :y 0.875)) (mb-cylinder mb 0.05 0.15 :segments 12 :top-radius 0.17))
          (with-xform (mb (xform :y 0.955)) (mb-cylinder mb 0.17 0.02 :segments 16 :top-radius 0.19))
          (with-xform (mb (xform :y 0.0)) (mb-cylinder mb 0.035 0.04 :segments 8 :top-radius 0.02))
          (mbc mb #xC2A866) (lb-ring mb 0.24 0.27 0.02 :n 20 :y 0.975)
          (with-xform (mb (xform :x 0.215 :y 0.968)) (mb-box mb 0.06 0.014 0.016))
          (with-xform (mb (xform :x -0.215 :y 0.968)) (mb-box mb 0.06 0.014 0.016))
          (with-xform (mb (xform :z 0.215 :y 0.968)) (mb-box mb 0.016 0.014 0.06))
          (with-xform (mb (xform :z -0.215 :y 0.968)) (mb-box mb 0.016 0.014 0.06))
          (loop for y in '(0.12 0.17 0.22 0.27 0.32) for r in '(0.2 0.4 0.62 0.84 1.05) for c in '(#xC2A866 #xF2E6C0 #xC2A866 #xF2E6C0 #xC2A866)
                do (mbc mb c) (with-xform (mb (xform :y y :roll r)) (lb-plate mb '((0 -0.02) (0.4 0.06) (0.44 0.12) (0 0.02)) 0.014))))
  (:solid :ink 0 (mbc mb #xF2E6C0) (with-xform (mb (xform :y 0.958)) (mb-cylinder mb 0.15 0.012 :segments 16))))
;; the reflect's mirror: a flat white hexagon on its edge (Hakkyoken's look, a generic reflector)
(defweapon :lb-mirror (:length 1.0)
  (:solid (mbc mb #xF4F6FA) (lb-plate mb (loop for i below 6 collect (let ((a (* i (/ pi 3)))) (list (cos a) (sin a)))) 0.04)
          (mbc mb #xB4BAC8) (lb-plate mb (loop for i below 6 collect (let ((a (* i (/ pi 3)))) (list (* 0.7 (cos a)) (* 0.7 (sin a))))) 0.06)))
(defweapon :lb-beam-jade (:length 1.0)
  (:solid :ink 0 (mbc mb #x9CC4AC) (with-xform (mb (xform :y 0.5)) (mb-cylinder mb 1.0 1.0 :segments 12))))
(defweapon :lb-beam-gold (:length 1.0)
  (:solid :ink 0 (mbc mb #xE2CC8C) (with-xform (mb (xform :y 0.5)) (mb-cylinder mb 1.0 1.0 :segments 12))))
(defweapon :lb-blast (:length 1.0)                     ; a SABAKI blast: a gold flame-cone, a pale core
  (:solid :ink 0 (mbc mb #xB89A5A) (mb-cone mb 0.5 1.0 :segments 5)
          (mbc mb #xF2E6C0) (with-xform (mb (xform :y 0.05)) (mb-cone mb 0.25 0.7 :segments 5))))

;;; ---------------------------------------------------------------- the strike points (the host FK test)
(defparameter *lb-strike-points*
  '((:lb-q1 :weapon) (:lb-q2 :weapon) (:lb-butt :weapon)                 ; the plank (*LB-BUTT* behind the grip)
    (:lb-w-q1 :hand-r) (:lb-w-q2 :hand-l) (:lb-w-q3 :hand-r) (:lb-w-f1 :hand-r) (:lb-w-f2 :hand-l) (:lb-w-f3 :hand-r)
    (:lb-w-ram :hand-r)                                                  ; the front wings' tips (the rig's hands)
    (:lb-o-q1 :hand-r) (:lb-o-q2 :hand-l) (:lb-o-q3 :hand-r) (:lb-o-f1 :hand-r) (:lb-o-f2 :hand-l) (:lb-o-f3 :hand-r)
    (:lb-o-stamp :hand-r))                                               ; the owl's long arms
  "Clip -> what strikes in it when it isn't Diagramm's muzzle (the weapon tip): :weapon = the plank, *LB-BUTT* behind the
grip; a joint = that joint (the wing blades and the owl's arms end at the rig's hands). The host FK test reads it.")

;;; ---------------------------------------------------------------- poses and clips: the base form
;;; Upright and still, Diagramm levelled at the hip (idle) or shouldered (aim). The J links swing the plank (the rifle
;;; reversed), J3 and the K links strike with the muzzle cross.
(defpose :lb-stance ()
  (:root :u -0.03) (:pelvis :twist 12) (:spine :flex 2) (:chest :twist -8) (:neck :twist -4) (:head :twist -4)
  (:arm-r :flex 16 :side 12) (:elbow-r :flex 64) (:hand-r :flex -78)
  (:arm-l :flex 44 :side 4) (:elbow-l :flex 70) (:hand-l :flex -20)
  (:thigh-r :flex -4 :side 4) (:thigh-l :flex 6 :side 4) (:knee-r :flex 6) (:knee-l :flex 8))
(defclip :lb-stance (2.6 :loop t :base :lb-stance)
  (0) (1.3 (:root :u -0.04) (:chest :flex 2) (:elbow-l :flex 74)))

(defpose :lb-aim-pose (:base :lb-stance)              ; shouldered: the cheek on the sleeve, the right eye along the barrel
  (:root :u -0.06) (:pelvis :twist 20) (:chest :twist -14) (:neck :twist -10) (:head :flex 6 :twist 18)
  (:arm-r :flex 60 :side 30) (:elbow-r :flex 110) (:hand-r :flex -170)
  (:arm-l :flex 80 :side 4) (:elbow-l :flex 20) (:hand-l :flex -10)
  (:thigh-r :flex -8 :side 8) (:thigh-l :flex 18 :side 6) (:knees :flex 14))
(defclip :lb-aim (0.6 :loop t :base :lb-aim-pose) (0) (0.3 (:root :u -0.065) (:chest :flex 1)))
(defstrike :lb-fire (4 2 26 :base :lb-aim-pose)       ; the shot: the recoil, the plank drops
  (0)
  (:s :snap (:root :f -0.04) (:head :flex 2))
  (:a (:root :f -0.1) (:arm-r :flex 70 :side 32) (:chest :flex -6))
  (20 (:root :f -0.04) (:arm-r :flex 50) (:elbow-r :flex 90) (:hand-r :flex -140))
  (:end :lb-stance))
(defstrike :lb-snap (6 2 20 :base :lb-stance)          ; K -> L: the snap shot from the hip
  (0 (:arm-r :flex 40) (:hand-r :flex -100))
  (:s :snap (:root :f -0.03) (:arm-r :flex 30 :side 14) (:elbow-r :flex 60) (:hand-r :flex -90) (:chest :twist -12))
  (:a (:root :f -0.08))
  (:end :lb-stance))

;; J1 SHOBI-UCHI: the rifle reversed, the plank swung up from the hip into him
(defpose :lb-q1-hit (:base :lb-stance)
  (:root :f 0.26 :u -0.05) (:pelvis :twist 10) (:chest :twist 10) (:arm-r :flex 82 :side 6) (:elbow-r :flex 8) (:hand-r :flex 90)
  (:arm-l :flex 60 :side 10) (:elbow-l :flex 40) (:thigh-r :flex 20) (:knee-r :flex 18) (:thigh-l :flex -8))
(defstrike :lb-q1 (8 3 12 :base :lb-stance)
  (0)
  (4 (:arm-r :flex 10 :side 16) (:elbow-r :flex 20) (:hand-r :flex 120) (:root :u -0.06) (:chest :twist -6))
  (:s :snap :lb-q1-hit)
  (:a :lb-q1-hit)
  (17 (:root :f 0.1) (:arm-r :flex 50) (:elbow-r :flex 40) (:hand-r :flex 20))
  (:end :lb-stance))
;; J2 KAESHI: the plank's backhand, across him
(defpose :lb-q2-hit (:base :lb-stance)
  (:root :f 0.3 :u -0.05 :yaw -10) (:pelvis :twist -10) (:chest :twist -24) (:arm-r :flex 84 :side 22) (:elbow-r :flex 6)
  (:hand-r :flex 92) (:arm-l :flex 40 :side 20) (:elbow-l :flex 40))
(defstrike :lb-q2 (7 3 13 :base :lb-stance)
  (0 (:arm-r :flex 70 :side 40) (:hand-r :flex 90) (:chest :twist 20))
  (:s :snap :lb-q2-hit)
  (:a :lb-q2-hit)
  (17 (:root :f 0.1) (:chest :twist -6) (:arm-r :flex 40) (:hand-r :flex 0))
  (:end :lb-stance))
;; J3 JUKO-TSUKI: the muzzle cross jabbed up into his face, the hand at the hip
(defpose :lb-jab-hit (:base :lb-stance)
  (:root :f 0.0 :u -0.06) (:chest :twist 4) (:arm-r :flex 24 :side 12) (:elbow-r :flex 46) (:hand-r :flex -24)
  (:arm-l :flex 70) (:elbow-l :flex 30) (:thigh-r :flex 16) (:knee-r :flex 14))
(defstrike :lb-jab (9 3 18 :base :lb-stance)
  (0)
  (5 (:root :f -0.06) (:arm-r :flex 0) (:elbow-r :flex 40) (:hand-r :flex -40))
  (:s :snap :lb-jab-hit)
  (:a :lb-jab-hit)
  (22 (:arm-r :flex 16) (:elbow-r :flex 60) (:hand-r :flex -70))
  (:end :lb-stance))
;; K1 JUSHIN-NAGI: the barrel swept flat across him
(defpose :lb-f1-hit (:base :lb-stance)
  (:root :f 0.0 :u -0.08) (:pelvis :twist -6) (:chest :twist -20) (:arm-r :flex 36 :side 16) (:elbow-r :flex 6) (:hand-r :flex -42)
  (:arm-l :flex 50 :side 10) (:elbow-l :flex 30) (:thigh-l :flex 16) (:knees :flex 12))
(defstrike :lb-f1 (17 4 21 :base :lb-stance)
  (0)
  (10 (:root :u -0.08) (:chest :twist 36) (:arm-r :flex 40 :side 50) (:elbow-r :flex 20) (:hand-r :flex -60))
  (:s :snap :lb-f1-hit)
  (:a :lb-f1-hit)
  (30 (:chest :twist -10) (:arm-r :flex 30 :side 20) (:elbow-r :flex 40))
  (:end :lb-stance))
;; K2 FURIOROSHI: the barrel raised overhead and brought down onto him
(defpose :lb-f2-hit (:base :lb-stance)
  (:root :f 0.0 :u -0.1) (:spine :flex 14) (:arm-r :flex 66 :side 8) (:elbow-r :flex 4) (:hand-r :flex -80)
  (:arm-l :flex 70) (:elbow-l :flex 20) (:knees :flex 16))
(defstrike :lb-f2 (20 4 24 :base :lb-stance)
  (0)
  (10 (:spine :flex -8) (:arm-r :flex 150 :side 10) (:elbow-r :flex 20) (:hand-r :flex -100) (:arm-l :flex 150) (:elbow-l :flex 20))
  (16 (:spine :flex -10) (:arm-r :flex 160))
  (:s :snap :lb-f2-hit)
  (:a :lb-f2-hit)
  (34 (:spine :flex 4) (:arm-r :flex 40) (:elbow-r :flex 40))
  (:end :lb-stance))
;; K3 REI-KYORI: the muzzle pressed in level and fired point-blank
(defpose :lb-f3-hit (:base :lb-stance)
  (:root :f 0.0 :u -0.1) (:spine :flex 8) (:arm-r :flex 38 :side 8) (:elbow-r :flex 34) (:hand-r :flex -72)
  (:arm-l :flex 74) (:elbow-l :flex 10) (:thigh-r :flex 18) (:knee-r :flex 16))
(defstrike :lb-f3 (21 5 34 :base :lb-stance)
  (0)
  (12 (:root :f -0.08) (:arm-r :flex 20) (:elbow-r :flex 80) (:hand-r :flex -100))
  (:s :snap :lb-f3-hit)
  (:a (:root :f -0.04) (:head :flex 4))                ; the shot's kick
  (44 (:arm-r :flex 20) (:elbow-r :flex 60))
  (:end :lb-stance))

;; SP1 SANREN: three snap shots from the shoulder, turning between them
(defstrike :lb-sanren (12 22 24 :base :lb-aim-pose)
  (0)
  (:s :snap (:root :f -0.05))
  (16 (:root :f 0))
  (22 :snap (:root :f -0.05))
  (26 (:root :f 0))
  (32 :snap (:root :f -0.06))
  (:a (:root :f -0.08))
  (:end :lb-stance))
;; SP2 HIRENKYAKU: the back-slide (the body low, the rifle shouldered), then the quick shot
(defstrike :lb-hiren (20 2 22 :base :lb-aim-pose)
  (0 (:root :u -0.2 :pitch 8) (:knees :flex 40) (:thighs :flex 30))
  (14 (:root :u -0.1 :pitch 0) (:knees :flex 20))
  (:s :snap (:root :f -0.05))
  (:a (:root :f -0.1))
  (:end :lb-stance))
;; I: the dash (the rifle levelled), the strike: the plank slammed down
(defclip :lb-breaker (0.4 :loop t :base :lb-stance)
  (0 (:root :u -0.1) (:spine :flex 22) (:arm-r :flex 30 :side 10) (:elbow-r :flex 50) (:hand-r :flex 90)
     (:thigh-r :flex 30) (:knee-r :flex 20) (:thigh-l :flex -20) (:knee-l :flex 30))
  (0.2 (:root :u -0.08) (:thigh-l :flex 30) (:knee-l :flex 20) (:thigh-r :flex -20) (:knee-r :flex 30)))
(defpose :lb-butt-hit (:base :lb-stance)
  (:root :f 0.1 :u -0.1) (:spine :flex 16) (:arm-r :flex 70 :side 6) (:elbow-r :flex 10) (:hand-r :flex 120)
  (:arm-l :flex 70) (:elbow-l :flex 20) (:knees :flex 20))
(defstrike :lb-butt (8 4 18 :base :lb-stance)
  (0 (:arm-r :flex 160 :side 10) (:elbow-r :flex 20) (:hand-r :flex 100) (:spine :flex -8))
  (:s :snap :lb-butt-hit)
  (:a :lb-butt-hit)
  (24 (:spine :flex 6) (:arm-r :flex 40))
  (:end :lb-stance))
;; the intro (the cloak thrown off: the rifle brought up and levelled) and the win (the rifle stood upright beside him)
(defclip :lb-intro (2.0 :base :lb-stance)
  (0 (:arm-r :flex 0 :side 6) (:elbow-r :flex 10) (:hand-r :flex 90) (:head :flex 8))
  (0.8 (:arm-r :flex 0) (:hand-r :flex 90))
  (1.2 :snap :lb-aim-pose)
  (2.0 :lb-aim-pose))
(defclip :lb-win (2.0 :base :lb-stance)
  (0)
  (0.6 (:arm-r :flex 10 :side 14) (:elbow-r :flex 70) (:hand-r :flex 20) (:head :flex 6))
  (2.0 (:arm-r :flex 10 :side 14) (:elbow-r :flex 70) (:hand-r :flex 20) (:head :flex 8 :twist 10)))

;;; ---------------------------------------------------------------- JILLIEL
;;; Floating 0.5 m up (the hurt cylinder stays on the ground). The arms are hidden in the column (decision 19): the rig's
;;; hands are the tips of the front wing pair (LILLE-DRAW draws each from its root behind the column's top to the hand), so
;;; the strikes are the front wings swung forward, their tips at the moves' reach. Idle, the hands sit in the fan (about
;;; -16 degrees, the third pair) and sway out of step (the other six sway on their own phases in the draw hook).
(defpose :lb-w-stance ()
  (:root :u 0) (:spine :flex 0) (:head :flex 4)
  (:arm-r :flex 2 :side 78) (:elbow-r :flex 8) (:arm-l :flex 2 :side 78) (:elbow-l :flex 8)
  (:thighs :flex 0) (:knees :flex 0))
(defclip :lb-w-stance (3.0 :loop t :base :lb-w-stance)
  (0) (0.8 (:root :u 0.03) (:arm-r :side 74) (:arm-l :side 81)) (1.5 (:root :u 0.06) (:arm-r :side 72) (:arm-l :side 77))
  (2.3 (:root :u 0.03) (:arm-r :side 80) (:arm-l :side 73)))
(defpose :lb-w-fold-pose (:base :lb-w-stance)        ; 無実体 MUJITTAI: the wings folded round the column, the front pair
  (:root :u 0.05) (:arm-r :flex 0 :side 30 :twist 45) (:elbow-r :flex 110)   ; crossed low before it
  (:arm-l :flex 0 :side 30 :twist -45) (:elbow-l :flex 110) (:head :flex 10))
(defclip :lb-w-fold (2.0 :loop t :base :lb-w-fold-pose) (0) (1.0 (:root :u 0.1)))
(defpose :lb-w-q1-hit (:base :lb-w-stance)
  (:root :f 0.08 :u 0) (:chest :twist 14) (:arm-r :flex 88 :side 8) (:elbow-r :flex 6))
(defstrike :lb-w-q1 (8 3 12 :base :lb-w-stance)
  (0) (4 (:arm-r :flex 20 :side 100)) (:s :snap :lb-w-q1-hit) (:a :lb-w-q1-hit) (:end :lb-w-stance))
(defpose :lb-w-q2-hit (:base :lb-w-stance)
  (:root :f 0.08 :u 0) (:chest :twist -14) (:arm-l :flex 88 :side 8) (:elbow-l :flex 6))
(defstrike :lb-w-q2 (7 3 13 :base :lb-w-stance)
  (0) (4 (:arm-l :flex 20 :side 100)) (:s :snap :lb-w-q2-hit) (:a :lb-w-q2-hit) (:end :lb-w-stance))
(defpose :lb-w-q3-hit (:base :lb-w-stance)
  (:root :f 0.18 :u 0) (:arm-r :flex 86 :side 14) (:arm-l :flex 86 :side 14) (:elbow-r :flex 2) (:elbow-l :flex 2))
(defstrike :lb-w-q3 (9 3 18 :base :lb-w-stance)
  (0) (5 (:arm-r :flex 30 :side 110) (:arm-l :flex 30 :side 110)) (:s :snap :lb-w-q3-hit) (:a :lb-w-q3-hit) (:end :lb-w-stance))
(defpose :lb-w-f1-hit (:base :lb-w-stance)
  (:root :f 0.62 :u -0.05) (:spine :flex 10) (:chest :twist -10) (:arm-r :flex 88 :side 4) (:elbow-r :flex 2) (:arm-l :flex 70 :side 30))
(defstrike :lb-w-f1 (17 4 21 :base :lb-w-stance)
  (0) (10 (:root :f -0.1) (:arm-r :flex 0 :side 120) (:chest :twist 20)) (:s :snap :lb-w-f1-hit) (:a :lb-w-f1-hit) (:end :lb-w-stance))
(defpose :lb-w-f2-hit (:base :lb-w-stance)
  (:root :f 0.62 :u -0.05) (:spine :flex 10) (:chest :twist 10) (:arm-l :flex 88 :side 4) (:elbow-l :flex 2) (:arm-r :flex 70 :side 30))
(defstrike :lb-w-f2 (20 4 24 :base :lb-w-stance)
  (0) (12 (:root :f -0.1) (:arm-l :flex 0 :side 120) (:chest :twist -20)) (:s :snap :lb-w-f2-hit) (:a :lb-w-f2-hit) (:end :lb-w-stance))
(defpose :lb-w-f3-hit (:base :lb-w-stance)
  (:root :f 0.72 :u -0.1) (:spine :flex 14) (:arm-r :flex 86 :side 4) (:arm-l :flex 86 :side 4) (:elbow-r :flex 2) (:elbow-l :flex 2))
(defstrike :lb-w-f3 (21 5 34 :base :lb-w-stance)
  (0) (12 (:root :f -0.1 :u 0.2) (:arm-r :flex 170 :side 20) (:arm-l :flex 170 :side 20)) (:s :snap :lb-w-f3-hit) (:a :lb-w-f3-hit)
  (:end :lb-w-stance))
(defpose :lb-w-aim-pose (:base :lb-w-stance)          ; the volley: the wings snapped forward, their holes aimed
  (:arm-r :flex 60 :side 40) (:elbow-r :flex 10) (:arm-l :flex 60 :side 40) (:elbow-l :flex 10) (:head :flex 6))
(defclip :lb-w-aim (0.6 :loop t :base :lb-w-aim-pose) (0) (0.3 (:root :u 0.02)))
(defstrike :lb-w-fire (4 2 24 :base :lb-w-aim-pose)
  (0) (:s :snap (:root :f -0.05)) (:a (:root :f -0.1) (:arm-r :side 50) (:arm-l :side 50)) (:end :lb-w-stance))
(defstrike :lb-w-nijushi (40 6 30 :base :lb-w-stance) ; all 24 holes: the wings spread wide, held, then the beam
  (0) (10 (:arm-r :flex 30 :side 100) (:arm-l :flex 30 :side 100) (:root :u 0.2)) (:s :snap (:root :f -0.15) (:arm-r :flex 60 :side 70)
                                                                                     (:arm-l :flex 60 :side 70))
  (:a (:root :f -0.2)) (:end :lb-w-stance))
(defclip :lb-w-breaker (0.4 :loop t :base :lb-w-stance)
  (0 (:root :u -0.2 :pitch 14) (:arm-r :flex -30 :side 40) (:arm-l :flex -30 :side 40)) (0.2 (:root :u -0.16 :pitch 14)))
(defpose :lb-w-ram-hit (:base :lb-w-stance)
  (:root :f 0.0 :u -0.1) (:spine :flex 4) (:arm-r :flex 66 :side 52) (:elbow-r :flex 24) (:arm-l :flex 66 :side 52) (:elbow-l :flex 24))
(defstrike :lb-w-ram (8 4 18 :base :lb-w-stance)
  (0 (:arm-r :flex 10 :side 120) (:arm-l :flex 10 :side 120)) (:s :snap :lb-w-ram-hit) (:a :lb-w-ram-hit) (:end :lb-w-stance))

;;; ---------------------------------------------------------------- the owl
;;; Upright on the stilts, the long arms hanging, the neck in an S; the claws (the hands) strike at the moves' reach.
(defpose :lb-o-stance ()
  (:root :u -0.02) (:spine :flex 4) (:head :flex 10)
  (:arm-r :flex 8 :side 10) (:elbow-r :flex 12) (:arm-l :flex 8 :side 10) (:elbow-l :flex 12)
  (:thigh-r :flex 0 :side 5) (:thigh-l :flex 0 :side 5) (:knees :flex 0))   ; (the ㄇ legs stand square: decision 26)
(defclip :lb-o-stance (2.4 :loop t :base :lb-o-stance)
  (0) (1.2 (:root :u -0.04) (:head :flex 18 :twist 10) (:arm-r :flex 14) (:arm-l :flex 4)))
(defpose :lb-o-q1-hit (:base :lb-o-stance) (:root :f 0.42) (:spine :flex 16) (:arm-r :flex 80 :side 6) (:elbow-r :flex 6))
(defstrike :lb-o-q1 (8 3 12 :base :lb-o-stance)
  (0) (4 (:arm-r :flex 120 :side 30) (:elbow-r :flex 60)) (:s :snap :lb-o-q1-hit) (:a :lb-o-q1-hit) (:end :lb-o-stance))
(defpose :lb-o-q2-hit (:base :lb-o-stance) (:root :f 0.42) (:spine :flex 16) (:arm-l :flex 80 :side 6) (:elbow-l :flex 6))
(defstrike :lb-o-q2 (7 3 13 :base :lb-o-stance)
  (0) (4 (:arm-l :flex 120 :side 30) (:elbow-l :flex 60)) (:s :snap :lb-o-q2-hit) (:a :lb-o-q2-hit) (:end :lb-o-stance))
(defpose :lb-o-q3-hit (:base :lb-o-stance) (:root :f 0.42) (:spine :flex 16) (:arm-r :flex 82 :side 10) (:arm-l :flex 82 :side 10))
(defstrike :lb-o-q3 (9 3 18 :base :lb-o-stance)
  (0) (5 (:arm-r :flex 140 :side 30) (:arm-l :flex 140 :side 30)) (:s :snap :lb-o-q3-hit) (:a :lb-o-q3-hit) (:end :lb-o-stance))
(defpose :lb-o-f1-hit (:base :lb-o-stance) (:root :f 1.05) (:spine :flex 28) (:arm-r :flex 78 :side 6) (:elbow-r :flex 4))
(defstrike :lb-o-f1 (17 4 21 :base :lb-o-stance)
  (0) (10 (:root :f -0.1) (:arm-r :flex 150 :side 40)) (:s :snap :lb-o-f1-hit) (:a :lb-o-f1-hit) (:end :lb-o-stance))
(defpose :lb-o-f2-hit (:base :lb-o-stance) (:root :f 1.05) (:spine :flex 28) (:arm-l :flex 78 :side 6) (:elbow-l :flex 4))
(defstrike :lb-o-f2 (20 4 24 :base :lb-o-stance)
  (0) (12 (:root :f -0.1) (:arm-l :flex 150 :side 40)) (:s :snap :lb-o-f2-hit) (:a :lb-o-f2-hit) (:end :lb-o-stance))
(defpose :lb-o-f3-hit (:base :lb-o-stance) (:root :f 1.05) (:spine :flex 28) (:arm-r :flex 78 :side 8) (:arm-l :flex 78 :side 8))
(defstrike :lb-o-f3 (21 5 34 :base :lb-o-stance)
  (0) (12 (:root :f -0.1) (:arm-r :flex 170 :side 20) (:arm-l :flex 170 :side 20)) (:s :snap :lb-o-f3-hit) (:a :lb-o-f3-hit)
  (:end :lb-o-stance))
(defstrike :lb-o-chop (16 0 24 :base :lb-o-stance)  ; SABAKI NO KOMYO: the right arm raised high, chopped straight down
  (0) (10 (:arm-r :flex 170 :side 6) (:elbow-r :flex 4) (:head :flex -10))
  (:s :snap (:arm-r :flex 60 :side 4) (:spine :flex 20) (:root :f 0.1))
  (24 (:arm-r :flex 40) (:spine :flex 12))
  (:end :lb-o-stance))
(defstrike :lb-o-trompete (60 30 40 :base :lb-o-stance)   ; TROMPETE: the fist at the beak, the head bent to it
  (0 (:arm-r :flex 120 :side 10) (:elbow-r :flex 150) (:head :flex 24))
  (40 (:arm-r :flex 124) (:spine :flex -6) (:head :flex 28))
  (:s :snap (:root :f -0.08) (:spine :flex -10))
  (:a (:root :f -0.12))
  (:end :lb-o-stance))
(defclip :lb-o-breaker (0.4 :loop t :base :lb-o-stance)
  (0 (:root :u -0.06) (:spine :flex 26) (:arm-r :flex -20) (:arm-l :flex -20) (:thigh-r :flex 30) (:thigh-l :flex -20))
  (0.2 (:thigh-l :flex 30) (:thigh-r :flex -20)))
(defpose :lb-o-stamp-hit (:base :lb-o-stance) (:root :f 0.1 :u -0.04) (:spine :flex 22) (:arm-r :flex 70 :side 10) (:elbow-r :flex 10))
(defstrike :lb-o-stamp (8 4 18 :base :lb-o-stance)
  (0 (:arm-r :flex 160 :side 20)) (:s :snap :lb-o-stamp-hit) (:a :lb-o-stamp-hit) (:end :lb-o-stance))

;;; ---------------------------------------------------------------- the cinematics' clips (§10)
(defclip :lb-rise (1.0 :base :lb-w-fold-pose)          ; the revival: the headless column rising into the air
  (0 (:root :u 0.5)) (1.0 (:root :u 1.5) (:arm-r :side 50) (:arm-l :side 50)))
(defpose :lb-o-point (:base :lb-o-stance)              ; the owl, one long arm raised high, the finger up (ch. 652)
  (:arm-r :flex 172 :side 8) (:elbow-r :flex 4) (:head :flex -6) (:spine :flex -4))
(defclip :lb-o-reveal (2.0 :base :lb-o-stance)
  (0) (0.6 :lb-o-point) (2.0 :lb-o-point))

;;; ---- rework R (decisions 17, 18): base stance + TENSHIN clips
;;; (Functional clips of the rules batch, DUEL_LILLE §22.1 / §22.2; the art batch owns everything above.) The shooting
;;; stance 狙撃構え: Diagramm levelled at the hip, knees bent, the right eye along the barrel; its L fires from there.
;;; HOSHA leaps and fires three bullets, TAISHA slides back and fires one (round 2: line hits from the muzzle, no melee
;;; volume); the HIRENKYAKU dash crouches low; TENSHIN (Jilliel) folds into the flash step and opens in the new mode.
(defpose :lb-kamae-pose (:base :lb-aim-pose)          ; low, the rifle levelled from the hip-shoulder, aimed
  (:root :u -0.12) (:pelvis :twist 24) (:chest :twist -16) (:spine :flex 6) (:head :flex 8 :twist 20)
  (:thigh-r :flex -14 :side 10) (:thigh-l :flex 30 :side 8) (:knee-l :flex 34) (:knee-r :flex 22))
(defclip :lb-kamae (0.8 :loop t :base :lb-kamae-pose) (0) (0.4 (:root :u -0.13) (:chest :flex 1)))
(defstrike :lb-k-shot (10 2 26 :base :lb-kamae-pose)  ; the stance's L: still on the line 10 f, the crack, the recoil
  (0) (:s :snap (:root :f -0.05) (:head :flex 2))
  (:a (:root :f -0.12) (:arm-r :flex 70 :side 32) (:chest :flex -6))
  (24 (:root :f -0.05) (:arm-r :flex 50) (:elbow-r :flex 90) (:hand-r :flex -140))
  (:end :lb-stance))
;; J 跳射 HOSHA (round 2, §23.1): the crouch, the leap (the sim carries him 3 m over f0-14; the clip only lifts him: the hurt
;; cylinder stays on the floor), Diagramm levelled from the hip in the air, a recoil on each bullet (f6, f10, f14), the
;; landing at f16, then back in the stance. The bullets are line hits from the muzzle (no melee volume: no FK reach test)
(defpose :lb-k-hosha-air (:base :lb-kamae-pose)
  (:root :u 0.55 :pitch -4) (:spine :flex 2) (:thigh-r :flex 46 :side 10) (:knee-r :flex 84) (:thigh-l :flex 18 :side 8)
  (:knee-l :flex 62))
(defstrike :lb-k-hosha (6 10 16 :base :lb-kamae-pose)
  (0) (2 (:root :u -0.2 :pitch 6) (:knees :flex 44) (:thighs :flex 30))
  (:s :snap :lb-k-hosha-air (:root :u 0.62) (:arm-r :flex 66))
  (8 :lb-k-hosha-air (:root :u 0.66))
  (10 :snap :lb-k-hosha-air (:root :u 0.6) (:arm-r :flex 68))
  (12 :lb-k-hosha-air (:root :u 0.48))
  (14 :snap :lb-k-hosha-air (:root :u 0.3) (:arm-r :flex 68))
  (:a (:root :u -0.16 :pitch 4) (:knees :flex 40) (:thighs :flex 26))
  (26 (:root :u -0.1) (:knees :flex 20))
  (:end :lb-stance))
;; K 退射 TAISHA (round 2, §23.1): the back-slide crouched low (the sim slides him 3 m over f0-12), the rifle shouldered on
;; the line from f12, the crack at f16, the recoil, back in the stance
(defpose :lb-k-taisha-slide (:base :lb-kamae-pose)
  (:root :u -0.26 :pitch -8) (:spine :flex 10) (:knees :flex 46) (:thighs :flex 36))
(defstrike :lb-k-taisha (16 2 24 :base :lb-kamae-pose)
  (0) (3 :lb-k-taisha-slide) (11 :lb-k-taisha-slide (:root :u -0.2))
  (14 :lb-aim-pose (:root :u -0.14))
  (:s :snap :lb-aim-pose (:root :f -0.06 :u -0.14) (:head :flex 2))
  (:a :lb-aim-pose (:root :f -0.14 :u -0.12) (:arm-r :flex 72 :side 32) (:chest :flex -6))
  (32 (:root :f -0.05) (:arm-r :flex 50) (:elbow-r :flex 90) (:hand-r :flex -140))
  (:end :lb-stance))
;; Step 飛廉脚 HIRENKYAKU: the flash-step dash, crouched low, the rifle kept on the line
(defstrike :lb-k-dash (12 0 0 :base :lb-kamae-pose)
  (0 (:root :u -0.3 :pitch 10) (:knees :flex 50) (:thighs :flex 40))
  (6 (:root :u -0.26 :pitch 6) (:knees :flex 40))
  (12 :lb-kamae-pose))
;; L 転身 TENSHIN (Jilliel, both modes): the wings fold, the flash step, the wings open in the new mode
(defstrike :lb-w-tenshin (14 0 8 :base :lb-w-stance)
  (0 :lb-w-fold-pose) (6 (:root :u 0.12) (:arm-r :flex 30 :side 30) (:arm-l :flex 30 :side 30))
  (14 :lb-w-stance) (:end :lb-w-stance))
;; TENSHIN in (EN -> KIN, round 2, decision 30; decision 34: 8 -> 16 f): the wind-up first, 16 f (2 f as a cancel: the
;; same clip entered at its f14), the front wings drawn back and the column rising, then the fold and the flash step as
;; above (its frames + 16)
(defstrike :lb-w-tenshin-in (30 0 8 :base :lb-w-stance)
  (0) (14 (:root :u 0.2 :pitch -6) (:arm-r :flex -20 :side 50) (:arm-l :flex -20 :side 50))
  (16 :snap :lb-w-fold-pose) (22 (:root :u 0.12) (:arm-r :flex 30 :side 30) (:arm-l :flex 30 :side 30))
  (30 :lb-w-stance) (:end :lb-w-stance))

;;; ================================================================ drawing (cosmetic; 0 B a frame: f32vecs, macros, DEFUN-FAST)
;;; A DEFUN-FAST call boxes its float arguments (engine/lisp/package.lisp), so these helpers take their numbers in the
;;; scratch vectors below, the frames are filled by macros, and a draw's alpha is one of the boxed *LB-ALPHAS*.
(declaim (special *lb-sabaki-from* *lb-sabaki-speed* *lb-sabaki-life* *lb-sabaki-width*   ; (lille.lisp's knobs,
                   *lb-x-near* *lb-x-far* *lb-x-min* *lb-x-max*))                                ;  loaded after this file)
(declaim (type f32vec *lb-m* *lb-p* *lb-v* *lb-fx* *lb-hud*))
(defvar *lb-m* (m4) "A prop's world matrix.")
(defvar *lb-p* (make-f32 3))
(defvar *lb-v* (make-f32 32)
  "The draw helpers' arguments: [0..2] the wings' root (the joint's frame); [11] the fold 0..1, [12] the ripple (degrees),
[13] the fx clock, [14] the wings' alpha, [15] the pairs shown (a cinematic's unfolding), [16] the wings' length x; [17..22]
the line / reticle / halo / trumpet macros' numbers; [23] the first pair drawn; [24..27] his x y z and yaw
(%LB-LOAD-PLACE!); [28] the wings' spread 0..1.")
(defvar *lb-fx* (make-f32 (* 2 24))
  "Per side (24 each), the looks' memory: [0] the eye's tick seen, [1] its fx clock, [2] the guard gauge seen, [3] the
last pass-through (fx clock), [4] the fold 0..1, [5] sealed seen (1), [6] the seal's fx clock, [7..9] the reticle's point,
[10] the reticle shown (1 tracking, 2 locked), [11] the distance there, [12 13] the reflector's x z, [14] the eye's tick
whose third-opening line was shown, [15] 1 while he is the owl (his hazards' gold), [16] the wings' spread 0..1 (an SP
fans them out), [17] its joints' unfurl 0..1 (slower: they furl, then open from the root).")
(dotimes (s 2) (setf (aref *lb-fx* (* 24 s)) -1f0 (aref *lb-fx* (+ (* 24 s) 14)) -1f0))
(defvar *lb-hud* (make-f32 8) "The HUD pip's arguments: cx cy r, [3] the fx clock.")
(defvar *lb-alphas* (let ((v (make-array 21))) (dotimes (i 21 v) (setf (svref v i) (f32 (/ i 20.0)))))
  "Boxed alphas 0, 0.05 .. 1: a draw's :ALPHA without consing.")
(defmacro lb-alpha (a) `(svref *lb-alphas* (f->i (+ 0.5f0 (* 20f0 (f-clamp ,a 0f0 1f0))))))

(defmacro %lb-frame! (m ox oy oz dx dy dz nx ny nz s &optional sw)
  "Fill M with the frame at (OX OY OZ): +Y along the unit (DX DY DZ), +Z the normal (NX NY NZ) made square to it, +X =
Y x Z, +Y scaled by S, +X and +Z by SW (default S). Single-float forms; a macro: 0 B."
  `(let* ((%dx ,dx) (%dy ,dy) (%dz ,dz) (%nx ,nx) (%ny ,ny) (%nz ,nz) (%s ,s) (%w ,(or sw '%s))
          (%d (+ (* %nx %dx) (* %ny %dy) (* %nz %dz)))
          (%ax (- %nx (* %d %dx))) (%ay (- %ny (* %d %dy))) (%az (- %nz (* %d %dz)))
          (%al (f-max 1f-5 (f-sqrt (+ (* %ax %ax) (* %ay %ay) (* %az %az)))))
          (%zx (/ %ax %al)) (%zy (/ %ay %al)) (%zz (/ %az %al))
          (%xx (- (* %dy %zz) (* %dz %zy))) (%xy (- (* %dz %zx) (* %dx %zz))) (%xz (- (* %dx %zy) (* %dy %zx)))
          (%m ,m))
     (declare (single-float %dx %dy %dz %nx %ny %nz %s %w %d %ax %ay %az %al %zx %zy %zz %xx %xy %xz) (type f32vec %m))
     (setf (aref %m 0) (* %w %xx) (aref %m 1) (* %w %xy) (aref %m 2) (* %w %xz) (aref %m 3) 0f0
           (aref %m 4) (* %s %dx) (aref %m 5) (* %s %dy) (aref %m 6) (* %s %dz) (aref %m 7) 0f0
           (aref %m 8) (* %w %zx) (aref %m 9) (* %w %zy) (aref %m 10) (* %w %zz) (aref %m 11) 0f0
           (aref %m 12) ,ox (aref %m 13) ,oy (aref %m 14) ,oz (aref %m 15) 1f0)))

(defmacro %lb-joint-frame! (m jm o lx ly lz s)
  "Fill M with joint frame O (= 16 x the joint) of JM, its axes scaled by S, its origin moved to the local point (LX LY LZ)."
  `(let* ((%jm ,jm) (%o ,o) (%m ,m) (%lx ,lx) (%ly ,ly) (%lz ,lz) (%s ,s))
     (declare (type f32vec %jm %m) (fixnum %o) (single-float %lx %ly %lz %s))
     (dotimes (%i 12) (setf (aref %m %i) (* %s (aref %jm (+ %o %i)))))
     (setf (aref %m 3) 0f0 (aref %m 7) 0f0 (aref %m 11) 0f0 (aref %m 15) 1f0)
     (dotimes (%k 3)
       (setf (aref %m (+ 12 %k)) (+ (* (aref %jm (+ %o %k)) %lx) (* (aref %jm (+ %o 4 %k)) %ly) (* (aref %jm (+ %o 8 %k)) %lz)
                                    (aref %jm (+ %o 12 %k)))))))

(defmacro %lb-wall (x z ux uz)
  "Metres from (X Z) along the unit (UX UZ) to the arena's wall (*ARENA-RADIUS*). Single-float forms; 0 B."
  `(let* ((%x ,x) (%z ,z) (%ux ,ux) (%uz ,uz) (%r (the single-float (f32 *arena-radius*)))
          (%b (+ (* %x %ux) (* %z %uz))) (%c (- (+ (* %x %x) (* %z %z)) (* %r %r))) (%q (- (* %b %b) %c)))
     (declare (single-float %x %z %ux %uz %r %b %c %q))
     (if (< %q 0f0) 0f0 (f-max 0f0 (+ (- %b) (f-sqrt %q))))))

(defmacro %lb-floor-line (kind x0 z0 ux uz len w)
  "A flat line on the floor from (X0 Z0) along the unit (UX UZ), LEN long, W wide: KIND 0 grey, 1 jade, 2 ink (its numbers
go through *LB-V* [17..22]: a DEFUN-FAST call would box them)."
  `(let ((%v *lb-v*))
     (declare (type f32vec %v))
     (setf (aref %v 17) ,x0 (aref %v 18) ,z0 (aref %v 19) ,ux (aref %v 20) ,uz (aref %v 21) ,len (aref %v 22) ,w)
     (%lb-floor-line* ,kind)))
(defun-fast %lb-floor-line* (kind)
  (declare (fixnum kind))
  (let* ((m *lb-m*) (v *lb-v*) (x0 (aref v 17)) (z0 (aref v 18)) (ux (aref v 19)) (uz (aref v 20)) (len (aref v 21)) (w (aref v 22)))
    (declare (type f32vec m v) (single-float x0 z0 ux uz len w))
    (setf (aref m 0) (* w (- uz)) (aref m 1) 0f0 (aref m 2) (* w ux) (aref m 3) 0f0
          (aref m 4) (* len ux) (aref m 5) 0f0 (aref m 6) (* len uz) (aref m 7) 0f0
          (aref m 8) 0f0 (aref m 9) 0.006f0 (aref m 10) 0f0 (aref m 11) 0f0
          (aref m 12) x0 (aref m 13) 0.022f0 (aref m 14) z0 (aref m 15) 1f0)
    (setf (aref *toon-body* 1) 0f0)
    (case kind (0 (draw-weapon :lb-line-grey m)) (1 (draw-weapon :lb-line-jade m)) (t (draw-weapon :lb-line m)))
    nil))

(defmacro %lb-reticle (jade x z r spin)
  "The reticle (the eye mark) flat on the floor at (X Z), radius R, turned SPIN: JADE (locked) or grey (*LB-V* [17..20])."
  `(let ((%v *lb-v*))
     (declare (type f32vec %v))
     (setf (aref %v 17) ,x (aref %v 18) ,z (aref %v 19) ,r (aref %v 20) ,spin)
     (%lb-reticle* ,jade)))
(defun-fast %lb-reticle* (jade)
  (let* ((m *lb-m*) (v *lb-v*) (x (aref v 17)) (z (aref v 18)) (r (aref v 19)) (spin (aref v 20)) (c (f-cos spin)) (s (f-sin spin)))
    (declare (type f32vec m v) (single-float x z r spin c s))
    (setf (aref m 0) (* r c) (aref m 1) 0f0 (aref m 2) (* r (- s)) (aref m 3) 0f0
          (aref m 4) 0f0 (aref m 5) r (aref m 6) 0f0 (aref m 7) 0f0
          (aref m 8) (* r s) (aref m 9) 0f0 (aref m 10) (* r c) (aref m 11) 0f0
          (aref m 12) x (aref m 13) 0.03f0 (aref m 14) z (aref m 15) 1f0)
    (setf (aref *toon-body* 1) 0f0)
    (if jade (draw-weapon :lb-reticle-jade m) (draw-weapon :lb-reticle-grey m))
    nil))

;;; ---------------------------------------------------------------- the wings (Jilliel's eight, the owl's eight)
;; Translucent (decision 27, 2026-10-06: 「把翅膀調整成半透明以免遮擋視線」): the engine draws an alpha < 1 in its transparent
;; pass (the lit shader, after the opaque scene, no depth write: what is behind shows through; the toon pass is opaque only),
;; where a plain colour reads dark (the duel's toon light is not the lit shader's), so the glass carries a glow (emissive x
;; its colour) that brings it back to its jade / gold. Decision 32 (2026-10-06: 「萊醬你能幫我將覺醒後翅膀的不透明邊界也都換成
;; 半透明嗎？」): the rim (outline band, teeth, hole rings, joints) is see-through too, a little stronger than the glass and
;; with the same glow, so the outline still reads and it is not the dark phantom.
(defparameter *lb-glass-alpha* 0.35 "The wings' glass alpha (decision 27): the fight shows through a blade.")
(defparameter *lb-glass-glow* 1.0 "The glass's (and since decision 32 the rim's) emissive (x its colour): the translucent
path's colour back to the jade / gold.")
(defparameter *lb-rim-alpha* 0.6
  "The rim's alpha (decision 32, the user 2026-10-06: the rims see-through too; was opaque, 1.0): a little stronger than the
glass (0.35) so the blade's outline, teeth and holes still read.")
(defparameter *lb-glass-ghost* 0.18 "MUJITTAI's glass alpha (more ghostly than the normal wings) ...")
(defparameter *lb-rim-ghost* 0.3 "... and its rim's (fainter still: 0.4 -> 0.3 with decision 32, the normal rim being 0.6).")
;; Jointed (decision 32, 2026-10-06: 「每片翅膀改成中間加 2 節可以彎折的連接觸，讓整體動作與攻擊動畫不會太死板」): each blade is
;; three segments chained at two joints (1/3, 2/3); each joint TILTS the next segment's frame (toward the blade's width
;; axis: a bend in its plane; toward its normal: a curl out of it). What bends them, all cosmetic (the fx clock, his pose
;; and the move's frame; never sim state or the sim's RNG):
;; - the idle WAVE: each joint on the wing's own phase, the tip's joint lagging the root's (travelling root -> tip);
;; - the LAG: a damped spring per wing (*LB-WM*) toward a bend set by the speed of its drive point (a front wing's hand,
;;   another wing's straight tip), plus, in a strike, a virtual speed along his facing: the wind-up cocks the joints back
;;   (trailing), the active frames snap them straight (the spring zeroed), the recovery throws them forward (the overshoot)
;;   and the spring settles them. A free wing's tip trails its motion; a front wing is pinned at both ends (root and hand),
;;   so its middle bows behind the motion;
;; - MUJITTAI curls them round the column (toward it), an SP / Kikon spread furls them then unfurls them from the root.
;; A FRONT wing's chain is then turned about its root so its end is exactly the rig's hand and its length set to reach it:
;; the drawn tip is the hand at every frame (the strike point the host FK test reads), bent or not.
(defparameter *lb-wave-amp* 0.22 "The idle wave: each joint's bend in the blade's plane (radians, at its peak).")
(defparameter *lb-wave-curl* 0.1 "... and its curl out of the plane (radians).")
(defparameter *lb-wave-speed* 2.3 "The wave's angular speed (rad/s of the fx clock).")
(defparameter *lb-wave-lag* 1.1 "The wave's phase lag from the root's joint to the tip's (radians): it travels root -> tip.")
(defparameter *lb-lag-gain* 0.045 "The lag spring's target bend per m/s of the drive point (radians).")
(defparameter *lb-lag-max* 0.75 "... at most (radians a joint; the tip's joint bends 1.4 x).")
(defparameter *lb-strike-in* 14.0 "A strike's wind-up: the virtual speed (m/s) along his facing and up (*LB-STRIKE-UP*) that
cocks the joints back and down.")
(defparameter *lb-strike-up* 0.7 "... the up share of that direction (so the fan's joints bend in its plane too: it reads from behind).")
(defparameter *lb-strike-out* 12.0 "A strike's recovery: the virtual speed back (m/s, easing out) that throws them forward.")
(defparameter *lb-fold-curl* 0.38 "MUJITTAI: each joint's curl toward the column (radians; the tip's 1.2 x).")
(defparameter *lb-furl* 0.55 "An SP / Kikon spread: the joints' furl before they unfurl from the root (radians).")
;; Two fans of four (decision 19; the refs: the upper pair high and out, the lowest pair down and out), rooted behind the
;; column's top (the owl: behind the ruff). Per wing, a row of 10 in an f32vec (read in DEFUN-FAST code without consing):
;; side, elevation (degrees above the horizontal), length (m), sweep back, where it folds to (MUJITTAI: down round the
;; column, wrapping forward; x y z), front (1: its tip is the rig's hand, the strike point), flip (1: the torn edge up, the
;; lowest pair), the idle sway's phase. Rows in pairs, top pair first (a cinematic unfolds them a pair at a time).
(defparameter *lb-wings-jl*
  (coerce (mapcar #'f32 '( 1  40 1.6  0.18 0.45 -0.75 -0.55 0 0 0.0    -1  40 1.6  0.18 0.45 -0.75 -0.55 0 0 2.1
                           1  13 1.75 0.22 0.62 -0.75 -0.2  0 0 1.1    -1  13 1.75 0.22 0.62 -0.75 -0.2  0 0 3.4
                           1 -16 1.75 0.0  0.5  -0.8  -0.5  1 0 0.0    -1 -16 1.75 0.0  0.5  -0.8  -0.5  1 0 0.0
                           1 -40 1.5  0.18 0.5  -0.86 0.15  0 1 2.6    -1 -40 1.5  0.18 0.5  -0.86 0.15  0 1 0.5))
          'f32vec)
  "Jilliel's eight wing blades: +40 / +13 / the front pair (the rig's hands: about -16 idle) / -40 degrees a side.")
(defparameter *lb-wings-owl*
  (coerce (mapcar #'f32 '( 1  34 1.9  0.25 0.4 -0.8 -0.4   0 0 0.7    -1  34 1.9  0.25 0.4 -0.8 -0.4   0 0 2.9
                           1  11 2.05 0.3  0.5 -0.8 -0.2   0 0 1.8    -1  11 2.05 0.3  0.5 -0.8 -0.2   0 0 0.2
                           1 -11 1.95 0.3  0.5 -0.85 0.0   0 0 3.1    -1 -11 1.95 0.3  0.5 -0.85 0.0   0 0 1.3
                           1 -34 1.7  0.25 0.45 -0.9 0.2   0 1 2.2    -1 -34 1.7  0.25 0.45 -0.9 0.2   0 1 4.0))
          'f32vec)
  "The owl's eight gold wing blades, two fans of four (+34 / +11 / -11 / -34 degrees a side, long: the refs' wide spread);
its claws are its hands.")
(declaim (type f32vec *lb-wings-jl* *lb-wings-owl* *lb-wf* *lb-wm*))
(defvar *lb-wf* (make-f32 48)
  "The jointed wings' scratch: [0..26] the three segments' unit frames (9 each: X Y Z), [30 31] a tilt's numbers (toward X,
toward Z), [32..35] the chain's turn (axis, angle); per call (LILLE-DRAW's %LB-DRIVE!): [39] the strike's virtual speed
(m/s along his facing), [40] the striking front wings (bit 0 right, bit 1 left), [41] 1 on the active frames (straight),
[42] the spread's unfurl 0..1, [43] the step (s; 0 = no spring step), [44] the strike's share for the other wings.")
(defvar *lb-wm* (make-f32 (* 2 8 9))
  "Per side and wing (9 each): [0..2] its drive point last frame, [3..5] the lag spring's bend (a world vector, radians),
[6..8] its rate. Cosmetic memory (never sim state).")
(defmacro %lb-ss (x) "Smoothstep of X clamped to 0..1 (single-float; 0 B)." `(let ((%x (f-clamp ,x 0f0 1f0))) (declare (single-float %x)) (* %x %x (- 3f0 (* 2f0 %x)))))

(defmacro %lb-basis! (w o dx dy dz nx ny nz)
  "Fill W [O..O+8] with a unit frame X Y Z: Y the unit (DX DY DZ), Z the normal (NX NY NZ) made square to it, X = Y x Z
(%LB-FRAME!'s axes, unscaled). Single-float forms; 0 B."
  `(let* ((%w ,w) (%o ,o) (%dx ,dx) (%dy ,dy) (%dz ,dz) (%nx ,nx) (%ny ,ny) (%nz ,nz)
          (%d (+ (* %nx %dx) (* %ny %dy) (* %nz %dz)))
          (%ax (- %nx (* %d %dx))) (%ay (- %ny (* %d %dy))) (%az (- %nz (* %d %dz)))
          (%al (f-max 1f-5 (f-sqrt (+ (* %ax %ax) (* %ay %ay) (* %az %az)))))
          (%zx (/ %ax %al)) (%zy (/ %ay %al)) (%zz (/ %az %al)))
     (declare (type f32vec %w) (fixnum %o) (single-float %dx %dy %dz %nx %ny %nz %d %ax %ay %az %al %zx %zy %zz))
     (setf (aref %w %o) (- (* %dy %zz) (* %dz %zy)) (aref %w (+ %o 1)) (- (* %dz %zx) (* %dx %zz))
           (aref %w (+ %o 2)) (- (* %dx %zy) (* %dy %zx))
           (aref %w (+ %o 3)) %dx (aref %w (+ %o 4)) %dy (aref %w (+ %o 5)) %dz
           (aref %w (+ %o 6)) %zx (aref %w (+ %o 7)) %zy (aref %w (+ %o 8)) %zz)))

(defun-fast %lb-tilt! (a b)
  "*LB-WF*'s frame at B = its frame at A tilted at the joint: its Y turned toward X by [30] and toward Z by [31] (radians;
the turn's axis is square to Y, so the frame stays orthonormal). 0 B."
  (declare (fixnum a b))
  (let* ((w *lb-wf*) (tx (aref w 30)) (tz (aref w 31)) (an (f-sqrt (+ (* tx tx) (* tz tz)))))
    (declare (type f32vec w) (single-float tx tz an))
    (if (< an 1f-5)
        (dotimes (q 9) (setf (aref w (+ b q)) (aref w (+ a q))))
        (let ((c (f-cos an)) (s (f-sin an)) (p (/ tx an)) (r (/ tz an)))
          (declare (single-float c s p r))
          (dotimes (q 3)                                 ; d = the tilt's direction (p X + r Z), e = Y x d (the axis)
            (let* ((x (aref w (+ a q))) (y (aref w (+ a 3 q))) (z (aref w (+ a 6 q)))
                   (d (+ (* p x) (* r z))) (e (- (* r x) (* p z))) (d2 (- (* c d) (* s y))))
              (declare (single-float x y z d e d2))
              (setf (aref w (+ b 3 q)) (+ (* c y) (* s d))
                    (aref w (+ b q)) (+ (* p d2) (* r e))
                    (aref w (+ b 6 q)) (- (* r d2) (* p e)))))))
    nil))

(defun-fast %lb-turn-chain! ()
  "Turn the three frames of *LB-WF* [0..26] about the unit axis [32..34] by the angle [35] (Rodrigues). 0 B."
  (let* ((w *lb-wf*) (kx (aref w 32)) (ky (aref w 33)) (kz (aref w 34)) (an (aref w 35))
         (c (f-cos an)) (s (f-sin an)) (c1 (- 1f0 c)))
    (declare (type f32vec w) (single-float kx ky kz an c s c1))
    (dotimes (i 9)
      (let* ((o (* 3 i)) (x (aref w o)) (y (aref w (+ o 1))) (z (aref w (+ o 2)))
             (kv (* c1 (+ (* kx x) (* ky y) (* kz z)))))
        (declare (fixnum o) (single-float x y z kv))
        (setf (aref w o) (+ (* c x) (* s (- (* ky z) (* kz y))) (* kx kv))
              (aref w (+ o 1)) (+ (* c y) (* s (- (* kz x) (* kx z))) (* ky kv))
              (aref w (+ o 2)) (+ (* c z) (* s (- (* kx y) (* ky x))) (* kz kv)))))
    nil))

(defmacro %lb-seg-m! (m w b ox oy oz len wd)
  "Fill M with *LB-WF*'s segment frame at B (unit X Y Z), at (OX OY OZ), +Y scaled by LEN (the blade's length), +X and +Z
by WD (its width scale). 0 B."
  `(let ((%m ,m) (%w ,w) (%b ,b) (%l ,len) (%d ,wd))
     (declare (type f32vec %m %w) (fixnum %b) (single-float %l %d))
     (dotimes (%q 3)
       (setf (aref %m %q) (* %d (aref %w (+ %b %q))) (aref %m (+ 4 %q)) (* %l (aref %w (+ %b 3 %q)))
             (aref %m (+ 8 %q)) (* %d (aref %w (+ %b 6 %q)))))
     (setf (aref %m 3) 0f0 (aref %m 7) 0f0 (aref %m 11) 0f0 (aref %m 12) ,ox (aref %m 13) ,oy (aref %m 14) ,oz (aref %m 15) 1f0)))

(defmacro %lb-wing-draw (kind g ga ra)
  "Draw segment G (0 root, 1 middle, 2 tip) of a blade at *LB-M*: its glass at GA, then its rim at RA (both see-through
with the glow), KIND 0 jade, 1 jade with the holes lit, 2 gold."
  (flet ((pair (glass rim) `((draw-weapon ,glass *lb-m* :alpha ,ga :emissive *lb-glass-glow*)
                             (draw-weapon ,rim *lb-m* :alpha ,ra :emissive *lb-glass-glow*))))
    `(case ,kind
       (0 (case ,g (0 ,@(pair :lb-wing-0 :lb-wing-rim-0)) (1 ,@(pair :lb-wing-1 :lb-wing-rim-1)) (t ,@(pair :lb-wing-2 :lb-wing-rim-2))))
       (1 (case ,g (0 ,@(pair :lb-wing-0 :lb-wing-lit-0)) (1 ,@(pair :lb-wing-1 :lb-wing-lit-1)) (t ,@(pair :lb-wing-2 :lb-wing-lit-2))))
       (t (case ,g (0 ,@(pair :lb-wing-gold-0 :lb-wing-gold-rim-0)) (1 ,@(pair :lb-wing-gold-1 :lb-wing-gold-rim-1))
            (t ,@(pair :lb-wing-gold-2 :lb-wing-gold-rim-2)))))))

(defun-fast %lb-wings (jm o tbl n kind side)
  "N wings of table TBL (rows of 10) from joint frame O of JM, KIND 0 jade, 1 jade with the holes lit, 2 gold, for SIDE's
fighter: their root (the joint's local point, each side 0.07 m out) in *LB-V* [0..2], the fold [11], the ripple [12] at the
fx clock [13], their alpha [14], the pairs shown [15] from the pair [23], the length x [16], the spread [28] (the SPs: the
fan wider and swept forward); the joints' drive in *LB-WF* [39..44] (%LB-DRIVE!). Idle, each sways on its own phase (the fx
clock: cosmetic). A front wing runs from its root to the rig's hand: the drawn tip is the hand, the strike point the host FK
test reads (*LB-STRIKE-POINTS*), its jointed chain turned and stretched to end there. Each blade is three segments (decision
32), each its glass (*LB-GLASS-ALPHA*) and its rim (*LB-RIM-ALPHA*), both see-through with a glow; an alpha [14] under 1
(MUJITTAI) is the ghost: fainter (*LB-GLASS-GHOST*, *LB-RIM-GHOST*)."
  (declare (type f32vec jm tbl) (fixnum o n kind side))
  (let* ((v *lb-v*) (w *lb-wf*) (mm *lb-wm*) (k (aref v 11)) (j (- 1f0 k)) (rip (aref v 12)) (tm (aref v 13)) (a (aref v 14))
         (ghost (< a 0.99f0))
         (ga (lb-alpha (if ghost (the single-float *lb-glass-ghost*) (* a (the single-float *lb-glass-alpha*)))))
         (ra (lb-alpha (if ghost (the single-float *lb-rim-ghost*) (* a (the single-float *lb-rim-alpha*)))))
         (pairs (f->i (aref v 15))) (lk (aref v 16)) (from (f->i (aref v 23))) (sp (aref v 28))
         (rx (aref v 0)) (ry (aref v 1)) (rz (aref v 2))
         (xx (aref jm o)) (xy (aref jm (+ o 1))) (xz (aref jm (+ o 2)))
         (yx (aref jm (+ o 4))) (yy (aref jm (+ o 5))) (yz (aref jm (+ o 6)))
         (zx (aref jm (+ o 8))) (zy (aref jm (+ o 9))) (zz (aref jm (+ o 10)))
         (xl (f-max 1f-5 (f-sqrt (+ (* xx xx) (* xy xy) (* xz xz))))) (zl (f-max 1f-5 (f-sqrt (+ (* zx zx) (* zy zy) (* zz zz)))))
         (fx (- (/ zx zl))) (fy (- (/ zy zl))) (fz (- (/ zz zl)))   ; his facing (the joint's -Z) and side (X), unit
         (sx (/ xx xl)) (sy (/ xy xl)) (sz (/ xz xl))
         (yl (f-max 1f-5 (f-sqrt (+ (* yx yx) (* yy yy) (* yz yz))))) (su (the single-float *lb-strike-up*))
         (vx0 (+ fx (* su (/ yx yl)))) (vy0 (+ fy (* su (/ yy yl)))) (vz0 (+ fz (* su (/ yz yl))))
         (vl (f-max 1f-5 (f-sqrt (+ (* vx0 vx0) (* vy0 vy0) (* vz0 vz0)))))
         (dvx (/ vx0 vl)) (dvy (/ vy0 vl)) (dvz (/ vz0 vl))           ; a strike's drive direction: forward and up
         (vb (aref w 39)) (mask (f->i (aref w 40))) (act (> (aref w 41) 0.5f0)) (u (aref w 42)) (dt (aref w 43)) (tsc (aref w 44))
         (rise (f-min 1f0 (/ u 0.12f0)))                  ; the spread: furl (u 0 -> 0.12), then unfurl from the root
         (c1 (* rise (- 1f0 (%lb-ss (/ (- u 0.12f0) 0.4f0)))))
         (c2 (* rise (- 1f0 (%lb-ss (/ (- u 0.3f0) 0.5f0)))))
         (gl (the single-float *lb-lag-gain*)) (lm (the single-float *lb-lag-max*))
         (wa (the single-float *lb-wave-amp*)) (wc (the single-float *lb-wave-curl*)) (ws (the single-float *lb-wave-speed*))
         (wl (the single-float *lb-wave-lag*)) (fc (the single-float *lb-fold-curl*)) (fu (the single-float *lb-furl*)))
    (declare (type f32vec v w mm) (fixnum pairs from mask)
             (single-float k j rip tm a lk sp rx ry rz xx xy xz yx yy yz zx zy zz xl zl fx fy fz sx sy sz yl su vx0 vy0 vz0 vl dvx dvy dvz vb u dt tsc rise c1 c2
                           gl lm wa wc ws wl fc fu))
    (dotimes (i n)
      (when (<= from (floor i 2) (1- pairs))
        (let* ((r (* 10 i)) (s (aref tbl r)) (lx (+ rx (* 0.07f0 s)))
               (ox (+ (* xx lx) (* yx ry) (* zx rz) (aref jm (+ o 12))))
               (oy (+ (* xy lx) (* yy ry) (* zy rz) (aref jm (+ o 13))))
               (oz (+ (* xz lx) (* yz ry) (* zz rz) (aref jm (+ o 14))))
               (front (> (aref tbl (+ r 7)) 0.5f0)) (mo (* 9 (+ i (* 8 side))))
               (len 0f0) (wd 0f0) (px 0f0) (py 0f0) (pz 0f0))
          (declare (fixnum r mo) (single-float s lx ox oy oz len wd px py pz))
          ;; 1. the straight blade's frame (segment 0's) and its drive point
          (if front
              ;; a front wing, root to hand; its torn edge down and out: the normal D x U, D = the joint's -Y + 0.5 s X
              (let* ((h (if (> s 0f0) (* 16 (ji :hand-r)) (* 16 (ji :hand-l))))
                     (hx (aref jm (+ h 12))) (hy (aref jm (+ h 13))) (hz (aref jm (+ h 14)))
                     (dx (- hx ox)) (dy (- hy oy)) (dz (- hz oz))
                     (dl (f-max 0.05f0 (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
                     (ux (/ dx dl)) (uy (/ dy dl)) (uz (/ dz dl))
                     (ddx (- (* 0.5f0 s xx) yx)) (ddy (- (* 0.5f0 s xy) yy)) (ddz (- (* 0.5f0 s xz) yz)))
                (declare (fixnum h) (single-float hx hy hz dx dy dz dl ux uy uz ddx ddy ddz))
                (%lb-basis! w 0 ux uy uz (- (* ddy uz) (* ddz uy)) (- (* ddz ux) (* ddx uz)) (- (* ddx uy) (* ddy ux)))
                (setf len dl wd (* lk (aref tbl (+ r 2))) px hx py hy pz hz))
              (let* ((e (* 0.017453292f0 (+ (* (aref tbl (+ r 1)) (+ 1f0 (* 0.22f0 sp)))
                                              (* 3f0 j (f-sin (+ (* 1.9f0 tm) (aref tbl (+ r 9)))))
                                              (* rip (f-sin (+ (* 31f0 tm) (* 1.7f0 (i->f i))))))))
                     (ax (* s (f-cos e))) (ay (f-sin e)) (az (- (aref tbl (+ r 3)) (* 0.7f0 sp)))
                     (lx2 (+ (* j ax) (* k s (aref tbl (+ r 4))))) (ly2 (+ (* j ay) (* k (aref tbl (+ r 5)))))
                     (lz2 (+ (* j az) (* k (aref tbl (+ r 6)))))
                     (fl (if (> (aref tbl (+ r 8)) 0.5f0) (- s) s)) (nlx (* k fl)) (nlz (* j fl))
                     (dx (+ (* xx lx2) (* yx ly2) (* zx lz2))) (dy (+ (* xy lx2) (* yy ly2) (* zy lz2)))
                     (dz (+ (* xz lx2) (* yz ly2) (* zz lz2))) (dl (f-max 1f-5 (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
                     (ln (* lk (aref tbl (+ r 2)) (- 1f0 (* 0.15f0 k)))))
                (declare (single-float e ax ay az lx2 ly2 lz2 fl nlx nlz dx dy dz dl ln))
                (%lb-basis! w 0 (/ dx dl) (/ dy dl) (/ dz dl)
                            (+ (* xx nlx) (* zx nlz)) (+ (* xy nlx) (* zy nlz)) (+ (* xz nlx) (* zz nlz)))
                (setf len ln wd ln px (+ ox (* ln (aref w 3))) py (+ oy (* ln (aref w 4))) pz (+ oz (* ln (aref w 5))))))
          ;; 2. the lag spring: its target from the drive point's speed and the strike's virtual speed (a free wing's tip
          ;; trails: bend against the motion; a pinned front wing bends with it, so its middle bows behind)
          (when (> dt 0f0)
            (let* ((qx (- px (aref mm mo))) (qy (- py (aref mm (+ mo 1)))) (qz (- pz (aref mm (+ mo 2))))
                   (iv (if (> (+ (* qx qx) (* qy qy) (* qz qz)) 1f0) 0f0 (/ 1f0 dt)))   ; (a jump: a cut, a reset)
                   (sw (if front (if (/= 0 (logand mask (if (> s 0f0) 1 2))) 1f0 0.3f0) tsc))
                   (sg (if front gl (- gl)))
                   (tx (* sg (+ (* qx iv) (* vb sw dvx)))) (ty (* sg (+ (* qy iv) (* vb sw dvy)))) (tz (* sg (+ (* qz iv) (* vb sw dvz))))
                   (tl (f-sqrt (+ (* tx tx) (* ty ty) (* tz tz)))) (tc (if (> tl lm) (/ lm tl) 1f0))
                   (om 16f0) (o2 (* om om)) (dmp (* 2f0 0.45f0 om)))
              (declare (single-float qx qy qz iv sw sg tx ty tz tl tc om o2 dmp))
              (setf (aref mm mo) px (aref mm (+ mo 1)) py (aref mm (+ mo 2)) pz)
              (if act                                    ; the active frames: snapped straight
                  (dotimes (q 6) (setf (aref mm (+ mo 3 q)) 0f0))
                  (macrolet ((spring (q tq)
                               `(let ((%b (aref mm (+ mo 3 ,q))) (%r (aref mm (+ mo 6 ,q))))
                                  (declare (single-float %b %r))
                                  (setf %r (+ %r (* dt (- (* o2 (- (* tc ,tq) %b)) (* dmp %r))))
                                        (aref mm (+ mo 6 ,q)) %r (aref mm (+ mo 3 ,q)) (+ %b (* dt %r))))))
                    (spring 0 tx) (spring 1 ty) (spring 2 tz)))))
          ;; 3. the joints: the spring's bend (the tip's joint 1.4 x), MUJITTAI's curl toward the column, the spread's furl,
          ;; and the wave (in the blade's frame, the tip's joint lagging)
          (let* ((bx (aref mm (+ mo 3))) (by (aref mm (+ mo 4))) (bz (aref mm (+ mo 5)))
                 (ff (if front 0.5f0 1f0)) (kc (* k fc ff (- s))) (u1 (* c1 fu ff)) (u2 (* c2 fu ff))
                 (b1x (+ bx (* kc sx) (* u1 fx))) (b1y (+ by (* kc sy) (* u1 fy))) (b1z (+ bz (* kc sz) (* u1 fz)))
                 (b2x (+ (* 1.4f0 bx) (* 1.2f0 kc sx) (* u2 fx))) (b2y (+ (* 1.4f0 by) (* 1.2f0 kc sy) (* u2 fy)))
                 (b2z (+ (* 1.4f0 bz) (* 1.2f0 kc sz) (* u2 fz)))
                 (wv (* (if act (if front 0f0 0.3f0) 1f0) (if front 0.6f0 1f0) (- 1f0 (* 0.6f0 k))))
                 (ph (+ (* ws tm) (aref tbl (+ r 9)) (if front (* 1.7f0 s) 0f0))))
            (declare (single-float bx by bz ff kc u1 u2 b1x b1y b1z b2x b2y b2z wv ph))
            (setf (aref w 30) (+ (* b1x (aref w 0)) (* b1y (aref w 1)) (* b1z (aref w 2)) (* wv wa (f-sin ph)))
                  (aref w 31) (+ (* b1x (aref w 6)) (* b1y (aref w 7)) (* b1z (aref w 8)) (* wv wc (f-sin (+ ph 0.8f0)))))
            (%lb-tilt! 0 9)
            (setf (aref w 30) (+ (* b2x (aref w 9)) (* b2y (aref w 10)) (* b2z (aref w 11)) (* wv wa (f-sin (- ph wl))))
                  (aref w 31) (+ (* b2x (aref w 15)) (* b2y (aref w 16)) (* b2z (aref w 17)) (* wv wc (f-sin (- (+ ph 0.8f0) wl)))))
            (%lb-tilt! 9 18))
          ;; 4. a front wing: turn the chain about its root so its end is on the hand, and stretch it to reach it
          (when front
            (let* ((tx (* 0.33333334f0 (+ (aref w 3) (aref w 12) (aref w 21))))
                   (ty (* 0.33333334f0 (+ (aref w 4) (aref w 13) (aref w 22))))
                   (tz (* 0.33333334f0 (+ (aref w 5) (aref w 14) (aref w 23))))
                   (tl (f-max 1f-4 (f-sqrt (+ (* tx tx) (* ty ty) (* tz tz)))))
                   (ex (/ tx tl)) (ey (/ ty tl)) (ez (/ tz tl))
                   (hx (/ (- px ox) len)) (hy (/ (- py oy) len)) (hz (/ (- pz oz) len))
                   (kx (- (* ey hz) (* ez hy))) (ky (- (* ez hx) (* ex hz))) (kz (- (* ex hy) (* ey hx)))
                   (kl (f-sqrt (+ (* kx kx) (* ky ky) (* kz kz)))) (cs (+ (* ex hx) (* ey hy) (* ez hz))))
              (declare (single-float tx ty tz tl ex ey ez hx hy hz kx ky kz kl cs))
              (when (> kl 1f-6)
                (setf (aref w 32) (/ kx kl) (aref w 33) (/ ky kl) (aref w 34) (/ kz kl) (aref w 35) (f-atan2 kl cs))
                (%lb-turn-chain!))
              (setf len (/ len tl))))
          ;; 5. the three segments, each from the last one's end
          (let ((qx ox) (qy oy) (qz oz) (l3 (* len 0.33333334f0)))
            (declare (single-float qx qy qz l3))
            (dotimes (g 3)
              (let ((b (* 9 g)))
                (declare (fixnum b))
                (%lb-seg-m! *lb-m* w b qx qy qz len wd)
                (%lb-wing-draw kind g ga ra)
                (setf qx (+ qx (* l3 (aref w (+ b 3)))) qy (+ qy (* l3 (aref w (+ b 4)))) qz (+ qz (* l3 (aref w (+ b 5)))))))))))
    nil))

(defmacro %lb-drive! (f mv rdt owl)
  "Set *LB-WF* [39..44], the jointed wings' drive for F's draw (MV his move or nil, RDT the step, OWL the owl's wings): in a
strike (a move's main phase with active frames, not an SP or Kikon) the wind-up's virtual speed rising to *LB-STRIKE-IN*,
the active frames' straight flag, the recovery's virtual speed back (*LB-STRIKE-OUT*, easing out); which front wings strike
(J1 / K1's clip the right, J2 / K2's the left, the rest both); the other wings' share (Jilliel's 0.35, the owl's 0.7).
Reads the move's frame only for the look. 0 B."
  `(let ((%w *lb-wf*) (%f ,f) (%mv ,mv) (%vb 0f0) (%act 0f0) (%mask 3))
     (declare (type f32vec %w) (single-float %vb %act) (fixnum %mask))
     (when (and %mv (eq (fighter-phase %f) :main) (> (the fixnum (mv-a %mv)) 0) (not (member (mv-kind %mv) '(:sp :kikon))))
       (let ((%sf (fighter-sf %f)) (%s (mv-s %mv)) (%a (mv-a %mv)) (%r (mv-r %mv)))
         (declare (fixnum %sf %s %a %r))
         (cond ((< %sf %s) (setf %vb (* (the single-float *lb-strike-in*) (%lb-ss (/ (i->f (1+ %sf)) (i->f (max 1 %s)))))))
               ((< %sf (+ %s %a)) (setf %act 1f0))
               (t (let ((%u (f-min 1f0 (/ (i->f (- %sf %s %a)) (i->f (max 1 %r))))))
                    (declare (single-float %u))
                    (setf %vb (- (* (the single-float *lb-strike-out*) (- 1f0 %u) (- 1f0 %u)))))))
         (setf %mask (case (mv-clip %mv) ((:lb-w-q1 :lb-w-f1) 1) ((:lb-w-q2 :lb-w-f2) 2) (t 3)))))
     (setf (aref %w 39) %vb (aref %w 40) (i->f %mask) (aref %w 41) %act
           (aref %w 43) (f-min ,rdt 0.034f0) (aref %w 44) (if ,owl 0.7f0 0.35f0))))

(defmacro %lb-halo (jm o kind lift r)
  "A halo LIFT m above joint frame O of JM (its local up), radius R: KIND 0 Jilliel's wide jade ring, 1 the owl's spiked
gold one, 2 the owl's broken one. The alpha: *LB-V* [14]; LIFT and R go through [17 18]."
  `(progn (setf (aref *lb-v* 17) ,lift (aref *lb-v* 18) ,r) (%lb-halo* ,jm ,o ,kind)))
(defun-fast %lb-halo* (jm o kind)
  (declare (type f32vec jm) (fixnum o kind))
  (%lb-joint-frame! *lb-m* jm o 0f0 (aref *lb-v* 17) (if (= kind 0) 0f0 -0.2f0) (aref *lb-v* 18))
  (let ((al (lb-alpha (aref *lb-v* 14))))
    (case kind
      (0 (draw-weapon :lb-halo *lb-m* :alpha al :emissive (if (< (aref *lb-v* 14) 0.99f0) *lb-glass-glow* (svref *lb-alphas* 0))))
      (1 (draw-weapon :lb-halo-gold *lb-m* :alpha al))
      (t (draw-weapon :lb-halo-broken *lb-m* :alpha al))))
  nil)

;;; ---------------------------------------------------------------- the ㄇ legs (KIN and the owl) and the owl's extra arms
;; Decision 26: from the fork (the thigh's end, 0.44 m below the hip: the body's knob) the front shank runs down, the strut
;; runs back (horizontal in the thigh's frame) and from its end (the corner's knob) the rear shank runs down: from the side
;; the two shanks and the strut read as ㄇ. Drawn in the thigh's frame (so a hit reaction or a knockdown carries the whole
;; leg); each shank's length is where its line meets the floor (the feet height of his body's draw, *TOON-BODY* [1]), within
;; 0.45-1.35 of its 1 m rest (the clips' float moves the fork; a leg pitched far from upright keeps the rest length).
(defparameter *lb-leg-fork* 0.44 "The fork's distance down the thigh (m; the body's knob).")
(defparameter *lb-leg-strut* 0.52 "The strut's length back from the fork (m): the ㄇ's top bar.")
(defmacro %lb-shank-len (py dy)
  "The shank from height PY along the unit direction's DY: where it meets the floor (*LB-V* [3]), clamped; else 1 m."
  `(let ((%py ,py) (%dy ,dy))
     (declare (single-float %py %dy))
     (if (< %dy -0.35f0) (f-clamp (/ (- %py (aref *lb-v* 3)) (- %dy)) 0.45f0 1.35f0) 1f0)))
(defmacro %lb-unit! (x y z)
  "Normalise the single-float places X Y Z in place (0 B)."
  `(let ((%l (f-max 1f-5 (f-sqrt (+ (* ,x ,x) (* ,y ,y) (* ,z ,z)))))) (declare (single-float %l))
     (setf ,x (/ ,x %l) ,y (/ ,y %l) ,z (/ ,z %l))))
(defun-fast %lb-legs (jm white fl)
  "Both ㄇ legs (decision 26) from the thighs of JM: WHITE 1 the owl's, else KIN's cream; FL 1 the hit flash. The floor's
height in *LB-V* [3], the alpha in [4] (MUJITTAI's body alpha)."
  (declare (type f32vec jm) (fixnum white fl))
  (let ((al (lb-alpha (aref *lb-v* 4))) (fla (svref *lb-alphas* (if (= fl 1) 9 0))))   ; (boxed: 0 B)
    (dotimes (side 2)
      (let* ((o (if (= side 0) (* 16 (ji :thigh-r)) (* 16 (ji :thigh-l)))) (s (if (= side 0) 1f0 -1f0))
             (ox (* s (aref jm o))) (oy (* s (aref jm (+ o 1)))) (oz (* s (aref jm (+ o 2))))            ; out
             (yx (aref jm (+ o 4))) (yy (aref jm (+ o 5))) (yz (aref jm (+ o 6)))                      ; up the thigh
             (bx (aref jm (+ o 8))) (by (aref jm (+ o 9))) (bz (aref jm (+ o 10)))                     ; back
             (fk (the single-float *lb-leg-fork*)) (ls (the single-float *lb-leg-strut*))
             (px (- (aref jm (+ o 12)) (* fk yx))) (py (- (aref jm (+ o 13)) (* fk yy))) (pz (- (aref jm (+ o 14)) (* fk yz)))
             ;; the front shank: down, a little forward and out
             (fx (- (* 0.07f0 ox) yx (* 0.1f0 bx))) (fy (- (* 0.07f0 oy) yy (* 0.1f0 by))) (fz (- (* 0.07f0 oz) yz (* 0.1f0 bz)))
             ;; the strut: back, a little out; the rear shank: down, a little back and out
             (sx (+ bx (* 0.04f0 ox))) (sy (+ by (* 0.04f0 oy))) (sz (+ bz (* 0.04f0 oz)))
             (rx (+ (- yx) (* 0.12f0 bx) (* 0.07f0 ox))) (ry (+ (- yy) (* 0.12f0 by) (* 0.07f0 oy)))
             (rz (+ (- yz) (* 0.12f0 bz) (* 0.07f0 oz))))
        (declare (fixnum o) (single-float s ox oy oz yx yy yz bx by bz fk ls px py pz fx fy fz sx sy sz rx ry rz))
        (%lb-unit! fx fy fz) (%lb-unit! sx sy sz) (%lb-unit! rx ry rz)
        (let ((lf (%lb-shank-len py fy)) (cx (+ px (* ls sx))) (cy (+ py (* ls sy))) (cz (+ pz (* ls sz))))
          (declare (single-float lf cx cy cz))
          (%lb-frame! *lb-m* px py pz fx fy fz ox oy oz lf 1f0)
          (if (= white 1) (draw-weapon :lb-shank-white *lb-m* :alpha al :flash fla) (draw-weapon :lb-shank-cream *lb-m* :alpha al :flash fla))
          (%lb-frame! *lb-m* px py pz sx sy sz ox oy oz ls)
          (if (= white 1) (draw-weapon :lb-strut-white *lb-m* :alpha al :flash fla) (draw-weapon :lb-strut-cream *lb-m* :alpha al :flash fla))
          (let ((lr (%lb-shank-len cy ry)))
            (declare (single-float lr))
            (%lb-frame! *lb-m* cx cy cz rx ry rz ox oy oz lr 1f0)
            (if (= white 1) (draw-weapon :lb-shank-white *lb-m* :alpha al :flash fla)
                (draw-weapon :lb-shank-cream *lb-m* :alpha al :flash fla)))))))
  nil)

;;; ---------------------------------------------------------------- the looks keyed on his state
(defmacro lb-fxs (side i) `(aref *lb-fx* (+ (* 24 ,side) ,i)))

(defun lb-cine-frame (e name)
  "The running cinematic's frame when it is NAME with E as its subject, else NIL (a look the script drives)."
  (let ((c *cine*)) (and c (eq (cine-name c) name) (eq (cine-a c) e) (cine-cf c))))

;;; Every component lookup of an entity conses 8 B in this build (an ECS getter: the reads probe, debug 79195), so the
;;; draw hook makes the fewest: his fighter and model each frame, his transform only while a look needs his place, his
;;; per-side state read straight from *LB* (not through LB, which looks his fighter up again).
(declaim (special *lb*))
(defmacro lb-state (e side) `(let ((%st (svref *lb* ,side))) (and (eql (lbs-e %st) ,e) %st)))
(defmacro %lb-load-place! (e)
  "*LB-V* [24..27] = E's x y z and yaw (one transform lookup)."
  `(let* ((%tr (transform ,e)) (%p (transform-pos %tr)) (%v *lb-v*))
     (declare (type f32vec %p %v))
     (setf (aref %v 24) (aref %p 0) (aref %v 25) (aref %p 1) (aref %v 26) (aref %p 2) (aref %v 27) (transform-yaw %tr))))

(defun-fast %lb-eye-look (e m st side)
  "The base form's eye (§4.1 Look): when it opens (his eye's tick changes) a ghosted afterimage where the hit lands; for
0.7 s the left eye open over the shut lid (the face swap), the mark flaring jade for the first 0.35 s."
  (declare (fixnum side))
  (let* ((tk (if st (i->f (lbs-eye-t st)) -1f0)) (now (fx-clock)) (jm (model-joints m)))
    (declare (single-float tk now) (type f32vec jm))
    (when (and (>= tk 0f0) (/= tk (lb-fxs side 0)))
      (setf (lb-fxs side 0) tk (lb-fxs side 1) now)
      (start-ghost e))
    (let ((age (- now (lb-fxs side 1))) (cf (lb-cine-frame e 'lb-jilliel-cine)))
      (declare (single-float age))
      (when (or (and (>= (lb-fxs side 0) 0f0) (< age 0.7f0)) (and cf (>= (the fixnum cf) 30)))
        (let ((o (* 16 (ji :head))))
          (declare (fixnum o))
          (%lb-joint-frame! *lb-m* jm o 0f0 0f0 0f0 1f0)
          (draw-weapon :lb-eye-open *lb-m*)
          (when (or (< age 0.35f0) (and cf (< 30 (the fixnum cf) 60)))
            (let* ((x (+ (* (aref jm o) -0.0336f0) (* (aref jm (+ o 4)) 0.1488f0) (* (aref jm (+ o 8)) -0.08f0) (aref jm (+ o 12))))
                   (y (+ (* (aref jm (+ o 1)) -0.0336f0) (* (aref jm (+ o 5)) 0.1488f0) (* (aref jm (+ o 9)) -0.08f0) (aref jm (+ o 13))))
                   (z (+ (* (aref jm (+ o 2)) -0.0336f0) (* (aref jm (+ o 6)) 0.1488f0) (* (aref jm (+ o 10)) -0.08f0) (aref jm (+ o 14))))
                   (k (if cf 0.9f0 (- 0.95f0 (* 2.4f0 age)))) (rt (camera-right *camera*)) (up (camera-upv *camera*)))
              (declare (single-float x y z k) (type f32vec rt up))
              (dotimes (i 4)                             ; the X flaring into four long light strokes
                (let* ((a (+ 0.7853982f0 (* 1.5707964f0 (i->f i)))) (c (f-cos a)) (s (f-sin a))
                       (dx (+ (* c (aref rt 0)) (* s (aref up 0)))) (dy (+ (* c (aref rt 1)) (* s (aref up 1))))
                       (dz (+ (* c (aref rt 2)) (* s (aref up 2)))))
                  (declare (single-float a c s dx dy dz))
                  (fx-shard (+ x (* 0.07f0 dx)) (+ y (* 0.07f0 dy)) (+ z (* 0.07f0 dz)) dx dy dz 0.09f0 0.007f0 0.05f0
                            (+ 3f0 (i->f i)) +pal-jade+ k :push 0.12f0)))
              (fx-star x y z 0.012f0 0.026f0 8 0.4f0 0f0 0f0 0.1f0 7f0 +pal-jade+ k :push 0.1f0))))))
    nil))

(defun-fast %lb-aim-look (e f side)
  "The aim line (§9, §22.1; both players see it): a thin line on the floor from under the muzzle to the wall, grey while
the shooting stance (:lb-kamae and its entries, every move named LB-KAMAE*) tracks (wider once charged, from its f30: up at
f6 + 24), jade (and wider) once the shot :lb-k-shot locks (its frame 0) until it fires; the reticle (the eye mark) on it at
the opponent's distance, turning while it tracks, snapped to the lane's width at the lock (0.65 m: a Step clears it) and
closing until the shot. The reticle's point is kept for the HUD's distance tag (*LB-FX*). (The volley went with the
rework: L in Jilliel is the mode switch.)"
  (declare (fixnum side))
  (setf (lb-fxs side 10) 0f0)
  (let* ((mv (fighter-move f)) (nm (and mv (eq (fighter-state f) :move) (mv-name mv)))
         (stance (and nm (search "LB-KAMAE" (symbol-name nm)) t))
         (locked (and (eq nm :lb-k-shot) (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))))
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
        (%lb-floor-line (if locked 1 0) x0 z0 ux uz wall
                        (cond (locked 0.06f0) ((>= (the fixnum (fighter-sf f)) 30) 0.05f0) (t 0.035f0)))
        (%lb-reticle locked rx rz r (if locked 0.785398f0 (* 1.4f0 tm)))
        (setf (lb-fxs side 7) rx (lb-fxs side 8) 0.05f0 (lb-fxs side 9) rz (lb-fxs side 10) (if locked 2f0 1f0)
              (lb-fxs side 11) dist)))
    nil))

(defmacro %lb-trumpet (k)
  "神の喇叭 forming over the owl (Trompete's tell, f10-60): the long gold horn from behind his head down to its bell before
him (the beam leaves the bell), its plume rising; K 0..1 how far it has formed (*LB-V* [17]; his place in [24..27])."
  `(progn (setf (aref *lb-v* 17) ,k) (%lb-trumpet*)))
(defun-fast %lb-trumpet* ()
  (let* ((v *lb-v*) (k (aref v 17)) (yaw (aref v 27)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
         (ax (- (aref v 24) (* 0.9f0 ux))) (ay 3.3f0) (az (- (aref v 26) (* 0.9f0 uz)))
         (bx (+ (aref v 24) (* 2.0f0 ux))) (by 1.7f0) (bz (+ (aref v 26) (* 2.0f0 uz)))
         (dx (- bx ax)) (dy (- by ay)) (dz (- bz az)) (l (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz)))) (s (* l (+ 0.15f0 (* 0.85f0 k)))))
    (declare (type f32vec v) (single-float k yaw ux uz ax ay az bx by bz dx dy dz l s))
    (%lb-frame! *lb-m* ax ay az (/ dx l) (/ dy l) (/ dz l) uz 0f0 (- ux) s)
    (setf (aref *toon-body* 1) 0f0)
    (draw-weapon :lb-trumpet *lb-m*)          ; (whole: a see-through toon draw reads dark; it forms by growing)
    (when (> k 0.3f0)                                    ; the light gathering in the bell
      (fx-star bx by bz (* 0.2f0 k) (* 0.5f0 k) 10 (* 3f0 (fx-clock)) 0f0 0f0 0.15f0 11f0 +pal-gold+ (* 0.9f0 k) :push 0.3f0))
    nil))

(defun-fast %lb-seal-look (e f m st side)
  "The reflect (§6.3): when Trompete is sealed, a mirror flash at the reflector, the beam turned back onto him (gold), and
his halo cracking (gold shards); the broken halo stays (LILLE-DRAW draws it). Lookups only while it plays."
  (declare (fixnum side))
  (let ((now (fx-clock)))
    (declare (single-float now))
    (if (and st (lbs-sealed st))
        (when (< (lb-fxs side 5) 0.5f0)
          (let ((q (pos-of (fighter-opp f))))
            (declare (type f32vec q))
            (setf (lb-fxs side 5) 1f0 (lb-fxs side 6) now (lb-fxs side 12) (aref q 0) (lb-fxs side 13) (aref q 2))))
        (setf (lb-fxs side 5) 0f0))
    (let ((age (- now (lb-fxs side 6))))
      (declare (single-float age))
      (when (and (> (lb-fxs side 5) 0.5f0) (< age 0.6f0))
        (%lb-load-place! e)
        (let* ((v *lb-v*) (qx (lb-fxs side 12)) (qz (lb-fxs side 13)) (k (- 1f0 (/ age 0.6f0)))
               (dx (- (aref v 24) qx)) (dz (- (aref v 26) qz)) (dl (f-max 0.01f0 (f-sqrt (+ (* dx dx) (* dz dz))))))
          (declare (type f32vec v) (single-float qx qz k dx dz dl))
          (%lb-frame! *lb-m* (+ qx (* 0.7f0 (/ dx dl))) 1.2f0 (+ qz (* 0.7f0 (/ dz dl))) 0f0 1f0 0f0 (/ dx dl) 0f0 (/ dz dl)
                      (* 0.8f0 (+ 0.6f0 (* 0.4f0 k))))
          (draw-weapon :lb-mirror *lb-m* :alpha (lb-alpha (* 1.4f0 k)))
          (fx-star (+ qx (* 0.75f0 (/ dx dl))) 1.2f0 (+ qz (* 0.75f0 (/ dz dl))) 0.5f0 1.1f0 6 0.5f0 0f0 0f0 0.05f0 21f0 +pal-hit+ k :push 0.4f0)
          (fx-ribbon qx 1.3f0 qz dx 0f0 dz (* 0.9f0 k) (* 0.6f0 k) 1f0 -21f0 0.05f0 (toon-a +pal-gold+ k)
                     0.6f0 -21f0 0.05f0 (toon-a +pal-gold+ k) 0f0 0f0 :segs 2 :mode :toon)
          (when (< age 0.05f0)
            (joint-point! *lb-p* (model-joints m) (ji :head) 0f0 0.74f0 -0.2f0)
            (dotimes (i 10)
              (let* ((a (* 0.6283f0 (i->f i))) (sp (+ 1.5f0 (* 0.3f0 (i->f (mod i 3))))))
                (declare (single-float a sp))
                (%t-shard (aref *lb-p* 0) (aref *lb-p* 1) (aref *lb-p* 2) (* sp (f-cos a)) 2.5f0 (* sp (f-sin a))
                          0.8f0 0.12f0 7f0 +pal-gold+)))))))
    nil))

(defparameter *lb-spread-clips* '(:lb-w-aim :lb-w-fire :lb-w-nijushi :lb-o-trompete)
  "The clips (besides every :sp and :kikon move) that fan the wings out (the volley, the beam, Trompete).")
(defmacro lb-jilliel-form-p (form) `(member ,form '(:jilliel :jilliel-mujittai :jilliel-kin :jilliel-kin-mujittai)))
(defmacro lb-mujittai-p (form) `(member ,form '(:jilliel-mujittai :jilliel-kin-mujittai)))

(defun-fast lille-draw (e rdt)
  "His kit's :draw hook (after his body; cosmetic): the base form's eye opening and its aim line / reticle; Jilliel's eight
wing blades (both modes: two fans of four behind the column, the front pair reaching to the rig's hands, each swaying on
its own phase; folded round the column in MUJITTAI, rippling on each pass-through, their holes lit in NIJUSHI-KO's tell,
fanned out in the SPs; translucent, fainter in MUJITTAI; each three jointed segments that wave, lag and whip in the
strikes, curl in MUJITTAI and unfurl in the SPs) and the wide jade halo; on the KIN and owl bodies the ㄇ legs (and
the owl's extra pair of arms); the owl's eight gold wings, its spiked halo (broken once sealed), the trumpet
forming over Trompete's wind-up, the reflect. The awakening's and the revival's cinematics drive the wings and halos
(the unfolding, the jade turning gold). Its only allocation is the entity lookups (two a frame; a third while he aims
or a gold look plays; a fourth in MUJITTAI)."
  (declare (single-float rdt))
  (let* ((f (fighter e)) (side (fighter-side f)) (form (fighter-form f)) (m (model e)) (jm (model-joints m))
         (st (lb-state e side))
         (mv (and (eq (fighter-state f) :move) (fighter-move f))) (v *lb-v*) (tm (fx-clock))
         (cj (lb-cine-frame e 'lb-jilliel-cine)) (cr (lb-cine-frame e 'lb-revive-cine))
         (ct (lb-cine-frame e 'lb-trompete-cine)) (ck (lb-cine-frame e 'lb-jilliel-kikon-cine))
         (look (cond ((and cj (< (the fixnum cj) 92)) :base) ((and cr (< (the fixnum cr) 66)) :revive)
                     ((lb-jilliel-form-p form) :jilliel) ((eq form :shin) :shin) (t :base))))
    (declare (fixnum side) (type f32vec jm v) (single-float tm))
    (setf (lb-fxs side 15) (if (eq form :shin) 1f0 0f0))   ; (his hazards' looks read it: gold or jade)
    (let ((spread (and mv (or (member (mv-kind mv) '(:sp :kikon)) (member (mv-clip mv) *lb-spread-clips*)))))
      (setf (lb-fxs side 16)                             ; the SPs fan the wings out (0.12 s either way) ...
            (if spread (f-min 1f0 (+ (lb-fxs side 16) (* 8f0 rdt))) (f-max 0f0 (- (lb-fxs side 16) (* 8f0 rdt))))
            (lb-fxs side 17)                             ; ... and their joints furl then unfurl from the root (decision 32)
            (if spread (f-min 1f0 (+ (lb-fxs side 17) (* 2.2f0 rdt))) (f-max 0f0 (- (lb-fxs side 17) (* 3f0 rdt))))))
    (setf (aref *lb-wf* 42) (lb-fxs side 17))
    (%lb-drive! f mv rdt (eq form :shin))                ; the joints' strike drive (cosmetic: the move's frame)
    (setf (aref v 28) (lb-fxs side 16)
          (aref v 3) (- (aref *toon-body* 1)             ; his body's feet height (DRAW-BODY's) less the form's drawn
                        (the single-float (f32 (body-lift (fighter-kit (fighter e)) (model-body m))))))   ; lift: the floor
    (when (>= (model-alpha m) 0.999f0)
      (let ((bn (body-name (model-body m))) (fl (if (> (model-flash m) 0f0) 1 0)))
        (when (or (eq bn :lille-jilliel-kin) (eq bn :lille-shin))   ; the ㄇ legs (decision 26)
          (setf (aref v 4) (if (lb-mujittai-p form) 0.72f0 1f0))
          (%lb-legs jm (if (eq bn :lille-shin) 1 0) fl)
          nil))
      (case look
        (:base (%lb-eye-look e m st side) (%lb-aim-look e f side))
        ((:jilliel :revive)
         (let ((stance (lb-mujittai-p form)))
           (when stance                                  ; a hit passed through: the guard gauge dropped in the stance
             (let ((gg (gauges-gg (gauges e))))
               (declare (single-float gg))
               (when (< gg (- (lb-fxs side 2) 0.5f0)) (setf (lb-fxs side 3) tm))
               (setf (lb-fxs side 2) gg)))
           (unless stance (setf (lb-fxs side 2) 100f0))
           (setf (lb-fxs side 4) (if stance (f-min 1f0 (+ (lb-fxs side 4) (* 5f0 rdt))) (f-max 0f0 (- (lb-fxs side 4) (* 5f0 rdt)))))
           (let* ((rip (- tm (lb-fxs side 3))) (k (if (and cr (< (the fixnum cr) 30)) 0.8f0 (lb-fxs side 4)))
                  (gold (if cr (f-clamp (/ (- (i->f cr) 30f0) 30f0) 0f0 1f0) 0f0))
                  (lit (or (and mv (eq (mv-name mv) :lb-nijushi) (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))
                           (and ck (< 8 (the fixnum ck) 110))))
                  (o (* 16 (ji :chest))))
             (declare (single-float rip k gold) (fixnum o))
             (setf (aref v 0) 0f0 (aref v 1) 0.3f0 (aref v 2) 0.13f0 (aref v 11) k
                   (aref v 12) (if (< rip 0.5f0) (* 14f0 (- 1f0 (* 2f0 rip))) 0f0) (aref v 13) tm
                   (aref v 14) (if stance 0.7f0 1f0) (aref v 16) 1f0 (aref v 23) 0f0
                   (aref v 15) (if (and cj (< (the fixnum cj) 160)) (f-max 0f0 (/ (- (i->f cj) 112f0) 8f0)) 9f0))
             (if (> gold 0f0)                            ; the revival: the jade turning gold over 30 f, a pair at a time
                 (let ((pg (i->f (min 4 (f->i (* 4.2f0 gold))))))
                   (declare (single-float pg))
                   (setf (aref v 15) pg) (%lb-wings jm o *lb-wings-jl* 8 2 side)
                   (setf (aref v 15) 9f0 (aref v 23) pg) (%lb-wings jm o *lb-wings-jl* 8 0 side)
                   (setf (aref v 23) 0f0))
                 (%lb-wings jm o *lb-wings-jl* 8 (if lit 1 0) side))
             (unless cr                                  ; the wide thin halo (the headless column has none)
               (setf (aref v 14) (if stance 0.7f0 1f0))
               (if (and cj (< (the fixnum cj) 160))
                   (let ((u (f-clamp (/ (- (i->f cj) 120f0) 40f0) 0f0 1f0)))   ; the awakening: it draws itself
                     (declare (single-float u))
                     (when (> u 0f0) (%lb-halo jm (* 16 (ji :head)) 0 0.52f0 (* 0.48f0 u))))
                   (%lb-halo jm (* 16 (ji :head)) 0 (+ 0.52f0 (* 0.02f0 (f-sin (* 2f0 tm)))) 0.48f0))))))
        (:shin
         (let ((grow (if cr (f-clamp (/ (- (i->f cr) 66f0) 30f0) 0.05f0 1f0) 1f0)))
           (declare (single-float grow))
           (setf (aref v 0) 0f0 (aref v 1) 0.3f0 (aref v 2) 0.13f0 (aref v 11) 0f0 (aref v 12) 0f0 (aref v 13) tm
                 (aref v 14) 1f0 (aref v 15) 9f0 (aref v 23) 0f0 (aref v 16) (+ 0.3f0 (* 0.7f0 grow)))
           (%lb-wings jm (* 16 (ji :chest)) *lb-wings-owl* 8 2 side)
           (%lb-halo jm (* 16 (ji :head)) (if (and st (lbs-sealed st)) 2 1) 0.76f0 (* 0.13f0 grow))
           (let ((tsf (cond (ct (if (< 8 (the fixnum ct) 120) (- (the fixnum ct) 8) -1))
                            ((and mv (eq (mv-name mv) :lb-trompete) (eq (fighter-phase f) :main)) (fighter-sf f))
                            (t -1))))
             (declare (fixnum tsf))
             (when (<= 10 tsf 89)
               (%lb-load-place! e)
               (%lb-trumpet (f-clamp (/ (- (i->f tsf) 10f0) 50f0) 0f0 1f0))))
           (%lb-seal-look e f m st side)))))
    nil))

(defun lille-body-alpha (e)
  "His kit's :body-alpha hook: MUJITTAI's column is half see-through (§5.2 Look); a constant (no boxing)."
  (if (lb-mujittai-p (fighter-form (fighter e))) 0.72 1f0))

(defun-fast lille-charge (e rdt)
  "His kit's :charge hook (instead of the fire charge at the weapon tip while a move is held): a small jade glint at the
muzzle cross once the line is locked, nothing while it tracks (the line is the tell)."
  (declare (single-float rdt))
  (setf rdt 0f0)                                        ; (unused: the hook's signature)
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (when (and mv (eq (fighter-form f) :base)                ; (the rework's shot locks on its frame 0)
               (or (eq (mv-name mv) :lb-k-shot)
                   (>= (the fixnum (fighter-hold f)) (the fixnum (or (getf (mv-params mv) :lock) 34)))))
      (let ((m (model e)))
        (joint-point! *lb-p* (model-joints m) (ji :weapon-r) 0f0 0f0 -1.75f0)
        (fx-star (aref *lb-p* 0) (aref *lb-p* 1) (aref *lb-p* 2) 0.04f0 0.12f0 4 0.785f0 0f0 0f0 0.05f0 5f0 +pal-jade+ 0.85f0
                 :push 0.15f0))))
  nil)

;;; ---------------------------------------------------------------- his hazards' look (kind :lb-fx, :lb-sabaki)
(defun-fast lb-look (hz rdt)
  "His hazards' draw function (HAZARD-DRAW): a shot's line at the volume's height (jade for an aimed one, ink for a snap
shot; a white core and the muzzle's cross flash on its first frames), the volley's five, a beam (a wide toon band, jade or
the owl's gold, a white core), a Kikon lane on the floor, the SABAKI line's gold blasts erupting along its burning span (a
thin gold sheet under them). Fading over the hazard's life. 0 B."
  (declare (single-float rdt))
  (setf rdt 0f0)                                        ; (unused: HAZARD-DRAW's signature)
  (let* ((d (hazard-data hz)))
    (when (and (lbh-p d) (<= (hazard-delay hz) 0))
      (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
             (age (hazard-age hz)) (fade (f-max 0f0 (- 1f0 (/ (i->f age) (i->f (max 1 (hazard-life hz)))))))
             (owl (> (lb-fxs (if (eql (hazard-owner hz) *p1*) 0 1) 15) 0.5f0))   ; (no lookup: LILLE-DRAW's flag)
             (kind (lbh-kind d)) (len (hazard-size hz))   ; (the struct's float slots would box through an accessor
             (w (case kind (:beam 1.2f0) (:lane 0.5f0) (:sabaki (the single-float (f32 *lb-sabaki-width*))) (t 0.05f0)))   ; call)
             (wall (%lb-wall x z ux uz)) (l (f-min len wall)) (sd (i->f (mod age 97))))
        (declare (single-float x z yaw ux uz fade len w wall l sd) (fixnum age))
        (case kind
          (:shot                                       ; (the volley's five-line fan went with rework R)
           (let ((n 1) (sp 0f0) (y 1.2f0))
             (declare (fixnum n) (single-float sp y))
             (dotimes (i n)
               (let* ((a (if (= n 1) yaw (+ yaw (* sp (i->f (- i 2)))))) (vx (- (f-sin a))) (vz (- (f-cos a)))
                      (ll (f-min len (%lb-wall x z vx vz))) (ww (* (if (lbh-lock d) 0.07f0 0.05f0) (+ 0.3f0 fade))))
                 (declare (single-float a vx vz ll ww))
                 (fx-ribbon (+ x (* 0.6f0 vx)) y (+ z (* 0.6f0 vz)) (* (- ll 0.6f0) vx) 0f0 (* (- ll 0.6f0) vz) ww ww
                            1f0 (- -11f0 sd) 0.02f0 (toon-a (if (lbh-lock d) +pal-jade+ +pal-ink+) (* 0.98f0 fade))
                            0.7f0 (- -11f0 sd) 0.02f0 (toon-a (if (lbh-lock d) +pal-jade+ +pal-ink+) (* 0.9f0 fade)) 0f0 0f0
                            :segs 2 :mode :toon)
                 (when (< age 4)                        ; the first frames: a white core, the cross flash at the muzzle
                   (fx-ribbon (+ x (* 0.6f0 vx)) y (+ z (* 0.6f0 vz)) (* (- ll 0.6f0) vx) 0f0 (* (- ll 0.6f0) vz) (* 0.4f0 ww) (* 0.4f0 ww)
                              1f0 (- -12f0 sd) 0.0f0 (toon-a +pal-hit+ 0.95f0) 1f0 (- -12f0 sd) 0f0 (toon-a +pal-hit+ 0.9f0) 0f0 0f0
                              :segs 2 :mode :toon)
                   (fx-star (+ x (* 1.0f0 vx)) y (+ z (* 1.0f0 vz)) 0.06f0 0.32f0 4 0f0 0f0 0f0 0.05f0 (+ 13f0 (i->f i))
                            +pal-hit+ (- 0.98f0 (* 0.2f0 (i->f age))) :push 0.2f0))))))
          (:beam
           (let* ((ww (* w (+ 0.35f0 (* 0.65f0 fade)))) (pal (if owl +pal-gold+ +pal-jade+)))
             (declare (single-float ww pal))
             (fx-ribbon (+ x (* 0.6f0 ux)) 1.3f0 (+ z (* 0.6f0 uz)) (* (- l 0.6f0) ux) 0f0 (* (- l 0.6f0) uz) ww ww
                        1f0 (- -31f0 sd) 0.05f0 (toon-a pal (* 0.98f0 fade)) 0.8f0 (- -31f0 sd) 0.05f0 (toon-a pal (* 0.9f0 fade)) 0f0 0f0
                        :segs 3 :mode :toon)
             (fx-ribbon (+ x (* 0.6f0 ux)) 1.3f0 (+ z (* 0.6f0 uz)) (* (- l 0.6f0) ux) 0f0 (* (- l 0.6f0) uz) (* 0.35f0 ww) (* 0.35f0 ww)
                        1f0 (- -32f0 sd) 0.05f0 (toon-a +pal-hit+ (* 0.95f0 fade)) 1f0 (- -32f0 sd) 0.05f0 (toon-a +pal-hit+ (* 0.9f0 fade))
                        0f0 0f0 :segs 3 :mode :toon)))
          (:lane (%lb-floor-line 1 (+ x (* 0.6f0 ux)) (+ z (* 0.6f0 uz)) ux uz (- l 0.6f0) (* w fade)))
          (:sabaki
           (let* ((a2 (/ (i->f age) 60f0)) (r0 (the single-float (f32 *lb-sabaki-from*))) (sp (the single-float (f32 *lb-sabaki-speed*)))
                  (from (f-max r0 (* sp (- a2 (/ (i->f (the fixnum *lb-sabaki-life*)) 60f0))))) (to (f-min len (+ r0 (* sp a2)))))
             (declare (single-float a2 r0 sp from to))
             (when (> to from)
               (fx-ribbon (+ x (* from ux)) 0.2f0 (+ z (* from uz)) (* (- to from) ux) 0f0 (* (- to from) uz) 0.1f0 0.06f0
                          1f0 (- -41f0 sd) 0.05f0 (toon-a +pal-gold+ 0.95f0) 0.6f0 (- -41f0 sd) 0.05f0 (toon-a +pal-gold+ 0.8f0) 0f0 0f0
                          :segs 4 :mode :toon)
               (do ((r (f-max 1f0 (i->f (f->i from))) (+ r 1f0))) ((> r to))
                 (declare (single-float r))
                 (let* ((h (* 1.7f0 (f-min 1f0 (/ (- to r) 3f0)) (f-min 1f0 (* 0.5f0 (- r from -0.6f0)))))
                        (bx (+ x (* r ux))) (bz (+ z (* r uz))))
                   (declare (single-float h bx bz))
                   (when (> h 0.05f0)
                     (%tongue bx 0f0 bz 0f0 h 0f0 (* 0.32f0 w) +pal-gold+ 0.95f0 (+ r (* 7f0 sd)) (* 3f0 r) 0.1f0)))))))))))
  nil)

;;; ================================================================ the HUD (DUEL_LILLE §9; hud.lisp's kit-meter / :hud-guard / :deck hooks)
(defparameter *c-lb-jade* (list 0.61 0.77 0.67 1.0) "The HUD's jade (the eye, MUJITTAI's outline; an ink tone).")
(defparameter *c-lb-gold* (list 0.72 0.6 0.35 1.0) "The HUD's owl gold (#B89A5A).")
(defparameter *c-lb-revive* (list 0.85 0.72 0.4 1.0) "The 「P  REVIVE」 prompt's gold (pulsing: ALPHA! sets its alpha).")
(defparameter *lb-me-strings* #("ME 0" "ME 1" "ME 2" "ME 3") "The eye row's label: ME + the pips left.")
(defparameter *lb-dmg-strings* (let ((v (make-array 400))) (dotimes (i 400 v) (setf (svref v i) (format nil "~d" i))))
  "The distance tag's numbers (made once).")
(defparameter *lb-me-kanji* "眼")
(defparameter *c-lb-dull* (list 0.6 0.55 0.45 0.9) "The sealed halo's label.")
(defparameter *c-lb-grey* (list 0.78 0.8 0.84 1.0) "The distance tag while the line tracks.")

(defun-fast %lb-pip (state)
  "One eye pip (the reticle glyph: four arcs, four ticks pointing in) centred at *LB-HUD* [0 1], radius [2]: STATE 0
unspent (the shut eye ― in a white ring), 1 spent (the open eye in jade, a jade ring), 2 unspent and flashing."
  (declare (fixnum state))
  (let* ((v *lb-hud*) (cx (aref v 0)) (cy (aref v 1)) (r (aref v 2)) (ri (* 0.74f0 r))
         (cr (if (= state 1) 0.61f0 0.93f0)) (cg (if (= state 1) 0.77f0 0.93f0)) (cb (if (= state 1) 0.67f0 0.9f0))
         (ca (if (= state 2) (+ 0.4f0 (* 0.6f0 (%pulse (aref v 3) 6.0))) 1f0)))
    (declare (type f32vec v) (single-float cx cy r ri cr cg cb ca))
    (dotimes (q 4)                                       ; the four arcs (3 segments each, +-30 degrees)
      (dotimes (k 3)
        (let* ((a0 (+ (* 1.5707964f0 (i->f q)) (* 0.34906584f0 (i->f (- k 1))) -0.17453292f0)) (a1 (+ a0 0.34906584f0))
               (c0 (f-cos a0)) (s0 (f-sin a0)) (c1 (f-cos a1)) (s1 (f-sin a1)))
          (declare (single-float a0 a1 c0 s0 c1 s1))
          (%hq (+ cx (* r c0)) (+ cy (* r s0)) (+ cx (* r c1)) (+ cy (* r s1)) (+ cx (* ri c1)) (+ cy (* ri s1))
               (+ cx (* ri c0)) (+ cy (* ri s0)) cr cg cb ca))))
    (dotimes (q 4)                                       ; the four ticks pointing in, at the diagonals
      (let* ((a (+ 0.7853982f0 (* 1.5707964f0 (i->f q)))) (c (f-cos a)) (s (f-sin a)) (w (* 0.09f0 r))
             (x0 (+ cx (* 0.98f0 r c))) (y0 (+ cy (* 0.98f0 r s))) (x1 (+ cx (* 0.58f0 r c))) (y1 (+ cy (* 0.58f0 r s))))
        (declare (single-float a c s w x0 y0 x1 y1))
        (%hq (- x0 (* w s)) (+ y0 (* w c)) (+ x0 (* w s)) (- y0 (* w c)) (+ x1 (* w s)) (- y1 (* w c)) (- x1 (* w s)) (+ y1 (* w c))
             cr cg cb ca)))
    (if (= state 1)                                      ; the open eye: a jade almond, the dark pupil
        (progn (%hq (- cx (* 0.5f0 r)) cy cx (- cy (* 0.28f0 r)) (+ cx (* 0.5f0 r)) cy cx (+ cy (* 0.28f0 r)) 0.43f0 0.6f0 0.5f0 1f0)
               (%hrect (- cx (* 0.12f0 r)) (- cy (* 0.12f0 r)) (* 0.24f0 r) (* 0.24f0 r) 0.06f0 0.06f0 0.08f0 1f0))
        (%hrect (- cx (* 0.42f0 r)) (- cy (* 0.06f0 r)) (* 0.84f0 r) (* 0.12f0 r) cr cg cb ca))   ; the shut eye ―
    nil))

(defun-fast %lb-halo-icon (cracked)
  "The owl's halo (the kit-meter row): a small gold ring with six spikes at *LB-HUD* [0 1], radius [2]; CRACKED (Trompete
sealed): a piece out, an arc dropped, dull."
  (let* ((v *lb-hud*) (cx (aref v 0)) (cy (aref v 1)) (r (aref v 2)) (ri (* 0.72f0 r))
         (cr (if cracked 0.5f0 0.72f0)) (cg (if cracked 0.44f0 0.6f0)) (cb (if cracked 0.3f0 0.35f0)))
    (declare (type f32vec v) (single-float cx cy r ri cr cg cb))
    (dotimes (i 12)
      (unless (and cracked (<= 4 i 5))
        (let* ((drop (if (and cracked (<= 6 i 8)) (* 0.25f0 r) 0f0))
               (a0 (* 0.5235988f0 (i->f i))) (a1 (+ a0 0.5235988f0)) (c0 (f-cos a0)) (s0 (* 0.55f0 (f-sin a0)))
               (c1 (f-cos a1)) (s1 (* 0.55f0 (f-sin a1))))
          (declare (single-float drop a0 a1 c0 s0 c1 s1))
          (%hq (+ cx (* r c0)) (+ cy drop (* r s0)) (+ cx (* r c1)) (+ cy drop (* r s1)) (+ cx (* ri c1)) (+ cy drop (* ri s1))
               (+ cx (* ri c0)) (+ cy drop (* ri s0)) cr cg cb 1f0))))
    (dotimes (i 6)                                       ; the spikes, up
      (unless (and cracked (= i 2))
        (let* ((a (+ 0.2617994f0 (* 1.0471976f0 (i->f i)))) (x (+ cx (* r (f-cos a)))) (y (+ cy (* 0.55f0 r (f-sin a)))))
          (declare (single-float a x y))
          (%hq (- x (* 0.12f0 r)) y (+ x (* 0.12f0 r)) y x (- y (* 0.6f0 r)) x (- y (* 0.6f0 r)) cr cg cb 1f0))))
    (when cracked                                        ; the crack, a dark zigzag across the gap
      (%hq (+ cx (* 0.1f0 r)) (- cy r) (+ cx (* 0.2f0 r)) (- cy r) (- cx (* 0.1f0 r)) (+ cy r) (- cx (* 0.2f0 r)) (+ cy r)
           0.08f0 0.08f0 0.1f0 1f0))
    nil))

(defun lb-side-of (g) "The fighter whose gauges are G." (if (and *p1* (eq (gauges *p1*) g)) *p1* *p2*))

(defun lille-hud-label (g kit)
  "The portrait block's label (§9): ME n (the eye pips left), MUJITTAI, HALO / SEALED."
  (let ((e (lb-side-of g)))
    (case (kit-form kit)
      (:base (svref *lb-me-strings* (max 0 (min 3 (lbs-eyes (lb e))))))
      (:shin (if (lbs-sealed (lb e)) "SEALED" "HALO"))
      (t "MUJITTAI"))))

(defun-fast %lb-eye-row (n right)
  "The three eye pips across the slot *LB-HUD* [4..7] (x y w h): N unspent (from the panel's outside), the last one
pulsing; RIGHT mirrors them."
  (declare (fixnum n))
  (let* ((v *lb-hud*) (x (aref v 4)) (y (aref v 5)) (w (aref v 6)) (h (aref v 7)) (step (/ w 3f0))
         (r (f-min (* 0.36f0 step) (f-max 7f0 (* 2.4f0 h)))))
    (declare (type f32vec v) (single-float x y w h step r))
    (dotimes (i 3)
      (setf (aref v 0) (if right (- (+ x w) (* step (+ (i->f i) 0.5f0))) (+ x (* step (+ (i->f i) 0.5f0))))
            (aref v 1) (+ y (* 0.5f0 h)) (aref v 2) r)
      (%lb-pip (cond ((>= i n) 1) ((= i (1- n)) (if (= n 1) 2 0)) (t 0))))
    nil))

(defun lille-hud-meter (e kit x y w h right tm lx ly ls)
  "His kit-meter row (LX LY LS: the landscape label's place, NIL in the portrait slot; §9): the base form's three eye pips
(the reticle glyph; a spent one shows the open eye in jade, the last one left pulsing) and the brush 眼 + ME n; nothing in
Jilliel (U's tag says MUJITTAI); the owl's halo, whole or cracked (Trompete sealed), and HALO / SEALED. Also the third
opening's line as a brush column at his side, and a human's distance tag on the aim line."
  (let* ((st (lb e)) (form (kit-form kit)) (v *lb-hud*) (side (fighter-side (fighter e))))
    (setf (aref v 3) (f32 tm) (aref v 4) (f32 x) (aref v 5) (f32 y) (aref v 6) (f32 w) (aref v 7) (f32 h))   ; (stored unboxed: no arithmetic here)
    (case form
      (:base
       (let ((n (lbs-eyes st)))
         (%lb-eye-row n right)
         (when lx                                       ; the label: the brush 眼 and ME n
           (let ((em (* 8 ls)))
             (set-line (if right (- lx (* 0.5 em)) (+ lx (* 0.5 em))) (+ ly (* 3.5 ls)) em *c-lb-jade*)
             (setf (aref *bl* 7) (line-width *lb-me-kanji*))
             (brush-line *lb-me-kanji*)
             (hud-text (svref *lb-me-strings* (max 0 (min 3 n))) (if right (- lx em (* 2 ls)) (+ lx em (* 2 ls))) ly ls
                       *c-lb-jade* :align (if right :right :left))))
         (when (and (zerop n) (/= (lbs-eye-t st) (round (lb-fxs side 14)))   ; the third opening: 三度も眼を開かされるとは
                    (fighter-callout (fighter e)) (eq (svref *callout-seen* side) (fighter-callout (fighter e))))
           (setf (lb-fxs side 14) (f32 (lbs-eye-t st))
                 (svref *side-caps* side) (make-bcap "三度も眼を開かされるとは" :reading "SANDO MO ME WO HIRAKASARERU TO WA"
                                                     :layout :callout :side side :secs 2.4)))))
      (:shin
       (%lb-halo-slot right (lbs-sealed st))
       (when lx
         (hud-text (if (lbs-sealed st) "SEALED" "HALO") lx ly ls (if (lbs-sealed st) *c-lb-dull* *c-lb-gold*)
                   :align (if right :right :left)))))
    (lb-hud-tag e side)))

(defun-fast %lb-halo-slot (right cracked)
  "The owl's halo icon at the outer end of the slot *LB-HUD* [4..7]."
  (let* ((v *lb-hud*) (x (aref v 4)) (y (aref v 5)) (w (aref v 6)) (h (aref v 7)) (r (f-max 9f0 (* 2.6f0 h))))
    (declare (type f32vec v) (single-float x y w h r))
    (setf (aref v 0) (if right (- (+ x w) (* 1.3f0 r)) (+ x (* 1.3f0 r))) (aref v 1) (+ y (* 0.5f0 h) (* 0.2f0 r)) (aref v 2) r)
    (%lb-halo-icon cracked)
    nil))

(defun-fast %lb-tag-dmg (side charged mult)
  "The distance tag's number: the stance's shot at the reticle's distance *LB-FX* [11] (SIDE), CHARGED the curve
(40-120, LB-X-DAMAGE's) else the quick shot's *LB-X-MIN*, x MULT (his kit's damage x). In float math (0 B a frame)."
  (declare (fixnum side))
  (let* ((d (lb-fxs side 11)) (near (the single-float (f32 *lb-x-near*))) (far (the single-float (f32 *lb-x-far*)))
         (lo (the single-float (f32 *lb-x-min*))) (hi (the single-float (f32 *lb-x-max*)))
         (m (the single-float (f32 mult)))
         (k (if charged (f-max 0f0 (f-min 1f0 (/ (- d near) (- far near)))) 0f0)))
    (declare (single-float d near far lo hi m k))
    (the fixnum (truncate (+ 0.5f0 (* m (+ lo (* k (- hi lo)))))))))

(defun lb-hud-tag (e side)
  "The distance tag (§9, base form, a human Lille only): the damage the stance's shot would deal now (quick 40, charged 40-120; x his damage x) next
to the reticle on the aim line (LILLE-DRAW keeps its point), grey while it tracks, jade once locked."
  (when (and (> (lb-fxs side 10) 0.5) (not (brain e)) (eq (fighter-form (fighter e)) :base))
    (let ((v *lb-p*))
      (when (world-to-screen v (lb-fxs side 7) (lb-fxs side 8) (lb-fxs side 9))
        (let* ((st (lb e))
               (charged (if (> (lb-fxs side 10) 1.5) (lbs-k-charged st) (lb-kamae-charged-p (lbs-charge st))))
               (dmg (%lb-tag-dmg side charged (kit-mult (kit-of e))))
               (s (max 2 (round (ui-scale)))))
          (hud-text (svref *lb-dmg-strings* (max 0 (min 399 dmg))) (+ (aref v 0) (* 26 s)) (- (aref v 1) (* 30 s)) (* 2 s)
                    (if (> (lb-fxs side 10) 1.5) *c-lb-jade* *c-lb-grey*)))))))

(defun-fast %lb-guard-outline (s tm)
  "MUJITTAI's jade outline round the guard bar *LB-HUD* [4..7] (two strokes, breathing)."
  (declare (fixnum s) (single-float tm))
  (let* ((v *lb-hud*) (x (aref v 4)) (y (aref v 5)) (bw (aref v 6)) (h (aref v 7)) (o (i->f (max 1 s)))
         (a (+ 0.7f0 (* 0.3f0 (f-sin (* 4f0 tm))))))
    (declare (type f32vec v) (single-float x y bw h o a))
    (%houtline (- x o) (- y o) (+ bw o o) (+ h o o) 0.61f0 0.77f0 0.67f0 a)
    (%houtline (- x o o) (- y o o) (+ bw (* 4f0 o)) (+ h (* 4f0 o)) 0.43f0 0.6f0 0.5f0 (* 0.6f0 a))
    nil))

(defun lille-hud-guard (e x y bw h right s tm)
  "His :hud-guard hook (over the guard bar): in MUJITTAI (EN or KIN) the bar outlined jade (the stance: GUARD HOLD, never refilling)."
  (declare (ignore right))
  (when (lb-mujittai-p (fighter-form (fighter e)))
    (let ((v *lb-hud*)) (setf (aref v 4) (f32 x) (aref v 5) (f32 y) (aref v 6) (f32 bw) (aref v 7) (f32 h)))
    (%lb-guard-outline (round s) (f32 tm))))

(defun-fast %lb-ring (n)
  "The thumb ring's three eye ticks round *LB-HUD* [4 5] (ox oy), [6] d: N unspent (white, a shut eye), the rest jade."
  (declare (fixnum n))
  (let* ((v *lb-hud*) (ox (aref v 4)) (oy (aref v 5)) (d (aref v 6)) (r (* d 56f0)))
    (declare (type f32vec v) (single-float ox oy d r))
    (dotimes (i 3)
      (let* ((a (+ -1.5707964f0 (* 0.45f0 (i->f (1- i))))) (x (+ ox (* r (f-cos a)))) (y (+ oy (* r (f-sin a)))) (lit (< i n)))
        (declare (single-float a x y))
        (%hrect (- x (* 3f0 d)) (- y (* 1.2f0 d)) (* 6f0 d) (* 2.4f0 d)
                (if lit 0.93f0 0.43f0) (if lit 0.93f0 0.6f0) (if lit 0.9f0 0.5f0) 1f0)
        (unless lit (%hrect (- x (* 1.2f0 d)) (- y (* 1.2f0 d)) (* 2.4f0 d) (* 2.4f0 d) 0.06f0 0.06f0 0.08f0 1f0))))
    nil))

(defun lille-ring (e ox oy d)
  "The one-hand thumb ring (his :deck hook; DUEL_MOBILE_DESIGN §15.1): in the base form three eye ticks over it, white while
unspent, jade once opened."
  (when (eq (fighter-form (fighter e)) :base)
    (let ((v *lb-hud*)) (setf (aref v 4) (f32 ox) (aref v 5) (f32 oy) (aref v 6) (f32 d)))
    (%lb-ring (lbs-eyes (lb e)))))

;;; ================================================================ his sounds (synthesized at startup; sounds.lisp's toolkit)
(defsound :lb-crack (:peak 0.95)                      ; the X-axis shot: a dry crack through everything, a low thump, a tail
  (let ((b (au-buf 1.0)))
    (au-mix! b (au-fnoise 0.025 :hp 2500 :decay 0.012) 0.0 1.0)
    (au-thump! b 0.0 180 45 0.05 0.18 0.9)
    (au-ping! b 0.0 1250 0.06 0.35 :glide 0.6)
    (au-mix! b (au-whoosh 0.5 4000 600 :q 1.5 :peak 0.12) 0.02 0.5)
    (au-reverb! b 0.3 :size 1.3)))

(defsound :lb-lock (:peak 0.6)                        ; the lock: a small dial click and a high glint (the line turns jade)
  (let ((b (au-buf 0.35)))
    (au-mix! b (au-fnoise 0.01 :bp 3000 :q 3 :decay 0.004) 0.0 0.8)
    (au-ping! b 0.005 2637 0.08 0.5)
    (au-ping! b 0.05 3951 0.1 0.3)
    b))

(defsound :lb-trumpet (:peak 0.85)                    ; 神の喇叭: a brass note swelling and rising a fourth (Trompete's tell)
  (let ((b (au-buf 1.8)) (pad (au-buf 1.8)))
    (au-render (pad) ((p1 0.0) (p2 0.0) (p3 0.0))
      (let ((f (* (au-sweep tt 233.0 311.0 1.6) (+ 1.0 (* 0.006 (au-sin (* 5.5 tt)))))))
        (au-ph+ p1 f) (au-ph+ p2 (* 1.5 f)) (au-ph+ p3 (* 2.0 f))
        (* (min 1.0 (* 2.0 tt)) (if (> tt 1.5) (* 3.3 (- 1.8 tt)) 1.0)
           (+ (au-saw p1) (* 0.5 (au-saw p2)) (* 0.3 (au-sqr p3))))))
    (au-svf! pad :lp :from 900 :to 4200 :q 1.2 :time 1.5)
    (au-mix! b pad 0.0 0.7)
    (au-reverb! b 0.35 :size 1.6)))

;;; ================================================================ the cinematics' looks (cosmetic; DURING forms, lille.lisp §10)
(defun vfx-lb-reticle-view (v k)
  "万物貫通's reticle view: the eye mark round V's chest, facing the camera, closing as K goes 1 -> 0."
  (multiple-value-bind (x y z) (actor-point v 1.25)
    (let* ((eye (camera-eye *camera*)) (dx (- (aref eye 0) x)) (dy (- (aref eye 1) y)) (dz (- (aref eye 2) z))
           (dl (max 1e-3 (sqrt (+ (* dx dx) (* dy dy) (* dz dz))))))
      (%lb-frame! *lb-m* (f32 x) (f32 y) (f32 z) (f32 (/ dx dl)) (f32 (/ dy dl)) (f32 (/ dz dl)) 0f0 1f0 0f0
                  (f32 (+ 0.45 (* 0.9 k))))
      (draw-weapon :lb-reticle-jade *lb-m*))))

(defun vfx-lb-shot-line (a k)
  "万物貫通's shot: the jade line from his muzzle along his facing, through everything to the wall, a white core, the muzzle's
cross flash; K its presence."
  (let* ((p (pos-of a)) (yaw (yaw-of a)) (ux (fwd-x yaw)) (uz (fwd-z yaw))
         (x (+ (aref p 0) (* 1.6 ux))) (z (+ (aref p 2) (* 1.6 uz))))
    (with-floats (x z ux uz k)
      (fx-ribbon x 1.45f0 z (* 30f0 ux) 0f0 (* 30f0 uz) (* 0.09f0 k) (* 0.06f0 k) 1f0 -81f0 0.02f0 (toon-a +pal-jade+ k)
                 0.8f0 -81f0 0.02f0 (toon-a +pal-jade+ k) 0f0 0f0 :segs 2 :mode :toon)
      (fx-ribbon x 1.45f0 z (* 30f0 ux) 0f0 (* 30f0 uz) (* 0.035f0 k) (* 0.025f0 k) 1f0 -82f0 0f0 (toon-a +pal-hit+ k)
                 1f0 -82f0 0f0 (toon-a +pal-hit+ k) 0f0 0f0 :segs 2 :mode :toon)
      (fx-star x 1.45f0 z (* 0.1f0 k) (* 0.5f0 k) 4 0.785f0 0f0 0f0 0.05f0 83f0 +pal-hit+ k :push 0.3f0))))

(defun vfx-lb-cross-hole (v k)
  "万物貫通's hole: a cross of white light through V's silhouette (the muzzle's cross), K its presence."
  (multiple-value-bind (x y z) (actor-point v 1.2)
    (with-floats (x y z k)
      (with-cam ()
        (dotimes (i 4)
          (let* ((sx (if (< i 2) rx ux)) (sy (if (< i 2) ry uy)) (sz (if (< i 2) rz uz)) (sg (if (evenp i) 1f0 -1f0)))
            (declare (single-float sx sy sz sg))
            (fx-shard (+ x (* 0.32f0 sg sx)) (+ y (* 0.32f0 sg sy)) (+ z (* 0.32f0 sg sz)) (* sg sx) (* sg sy) (* sg sz)
                      0.8f0 0.09f0 0.02f0 (+ 31f0 (i->f i)) +pal-hit+ k :push 0.6f0)))
        (fx-star x y z 0.08f0 0.2f0 4 0.785f0 0f0 0f0 0.03f0 35f0 +pal-hit+ k :push 0.6f0)))))

(defparameter *lb-hole-fan* '((1 40) (-1 40) (1 13) (-1 13) (1 -16) (-1 -16) (1 -40) (-1 -40))
  "神の裁き's 24 muzzles: the eight wings (side, elevation), three holes each.")
(defun vfx-lb-converge (a v k)
  "神の裁き's Kikon: 24 jade lines out of the wings' holes, crossing on V (K their presence, 0..1)."
  (let* ((p (pos-of a)) (yaw (yaw-of a)) (ux (fwd-x yaw)) (uz (fwd-z yaw)) (rx (- uz)) (rz ux))
    (multiple-value-bind (tx ty tz) (actor-point v 1.2)
      (loop for (s e) in *lb-hole-fan* for w from 0
            do (dotimes (h 3)
                 (let* ((d (+ 0.5 (* 0.32 h))) (ea (* e (/ pi 180)))
                        (x (+ (aref p 0) (* s (cos ea) d rx) (* -0.25 ux))) (y (+ 2.05 (* (sin ea) d))) (z (+ (aref p 2) (* s (cos ea) d rz) (* -0.25 uz))))
                   (with-floats (x y z tx ty tz k)
                     (let ((sd (i->f (+ (* 3 w) h))))
                       (declare (single-float sd))
                       (fx-ribbon x y z (- tx x) (- ty y) (- tz z) 0.022f0 0.016f0 1f0 (- -51f0 sd) 0.02f0 (toon-a +pal-jade+ k)
                                  0.8f0 (- -51f0 sd) 0.02f0 (toon-a +pal-jade+ k) 0f0 0f0 :segs 2 :mode :toon)
                       (fx-disc x y z 0.05f0 0.05f0 sd +pal-jade+ k)))))))))

(defun vfx-lb-horizon (a k)
  "神の喇叭's Kikon: the beam out of the bell, erasing the horizon (a wide gold band, a white core), K its presence."
  (let* ((p (pos-of a)) (yaw (yaw-of a)) (ux (fwd-x yaw)) (uz (fwd-z yaw))
         (x (+ (aref p 0) (* 2.0 ux))) (z (+ (aref p 2) (* 2.0 uz))))
    (with-floats (x z ux uz k)
      (fx-ribbon x 1.7f0 z (* 70f0 ux) 1.2f0 (* 70f0 uz) (* 1.6f0 k) (* 6f0 k) 1f0 -61f0 0.05f0 (toon-a +pal-gold+ (* 0.98f0 k))
                 0.7f0 -61f0 0.05f0 (toon-a +pal-gold+ (* 0.9f0 k)) 0f0 0f0 :segs 4 :mode :toon)
      (fx-ribbon x 1.7f0 z (* 70f0 ux) 1.2f0 (* 70f0 uz) (* 0.6f0 k) (* 2.5f0 k) 1f0 -62f0 0.05f0 (toon-a +pal-hit+ (* 0.95f0 k))
                 1f0 -62f0 0.05f0 (toon-a +pal-hit+ (* 0.9f0 k)) 0f0 0f0 :segs 4 :mode :toon)
      (fx-star x 1.7f0 z (* 0.4f0 k) (* 1.1f0 k) 12 (* 2f0 (fx-clock)) 0f0 0f0 0.12f0 63f0 +pal-gold+ k :push 0.6f0))))

(defun vfx-lb-light (x y z r k)
  "A ball of gold light (the revival's head growing, the trumpet's charge): a gold disc and its rays."
  (with-floats (x y z r k)
    (fx-disc x y z r 0.08f0 71f0 +pal-gold+ k)
    (fx-star x y z (* 0.6f0 r) (* 1.9f0 r) 10 (* 1.5f0 (fx-clock)) 0f0 0f0 0.12f0 72f0 +pal-hit+ (* 0.9f0 k) :push 0.3f0)))

;;; ================================================================ his brush glyphs (the cinematics' captions, §10)
;;; Baked by the scratchpad's bake.py over tools/glyph-bake.py's GLYPH() (the same Yuji Syuku subset and licence as
;;; glyphs.lisp): the characters the captions 「三度も眼を開かされるとは 異端に等しい」, 「武器では死なず 霊圧で首を落としても尚死なない」
;;; and 真の姿 need that glyphs.lisp, ichigo-art and senjumaru-art lack, appended before BRUSH-INIT triangulates them.
(setf *glyph-outlines*
      (append *glyph-outlines*
              '(
                (12363 1000 (565 561 552 636 525 719 493 788 479 811 450 837 373 869 354 861 338 848 318 814 304 759 302 685 310 679 315 649 321 700 329 733 344 761 366 779 399 761 414 747 442 709 472 636 488 555 486 482 467 421 457 404 429 401 399 412 381 432 350 502 328 524 330 536 321 546 326 552 308 595 308 614 290 630 294 635 302 633 302 637 286 646 282 666 273 669 282 679 247 759 216 748 179 711 188 670 231 614 230 592 234 578 272 502 279 473 228 479 182 471 162 461 145 448 131 430 121 408 164 411 200 404 324 353 368 194 385 144 393 141 403 147 419 172 433 233 430 288 408 337 455 348 496 362 531 383 546 397 560 414 568 508) (921 685 868 681 855 677 838 661 822 624 789 514 770 478 713 392 695 350 699 343 722 345 782 385 833 429 864 469 884 506 899 546 931 675)) ; か
                (12373 1000 (797 312 782 331 756 331 754 335 746 337 743 344 615 366 580 371 547 370 527 383 529 425 542 455 575 485 660 529 684 548 700 574 705 612 671 611 527 593 488 598 443 615 490 584 543 560 489 511 472 487 463 454 453 442 447 389 346 392 276 383 216 360 182 334 192 318 324 311 447 289 454 208 462 172 476 145 498 130 530 134 521 163 519 195 527 279 604 272 669 257 624 215 676 229 769 244 774 256 797 273 805 286) (603 905 571 917 566 925 451 899 409 877 389 863 344 817 308 757 296 716 295 696 303 672 332 647 355 638 376 638 374 646 361 659 365 686 385 743 405 773 437 799 538 838 572 855 598 879 608 896)) ; さ
                (12378 1000 (823 376 794 379 592 373 586 426 595 539 594 551 586 559 599 565 598 571 590 575 596 594 595 634 601 652 594 748 587 791 570 830 530 859 516 883 436 901 465 869 488 831 503 786 509 731 494 638 490 622 475 593 442 560 408 540 387 541 379 547 378 560 386 587 417 624 443 642 469 652 482 652 490 648 494 638 509 731 453 717 429 704 408 686 375 644 363 619 348 565 346 508 349 480 388 473 429 482 467 500 515 534 516 490 508 383 438 392 267 440 224 444 202 441 162 425 127 401 98 373 377 321 510 309 518 222 528 172 540 149 561 140 586 148 596 158 607 184 606 208 593 268 591 297 656 298 712 285 748 289 785 303 816 324 838 349 843 363) (809 265 779 235 734 132 738 127 750 129 783 147 814 170 827 184 841 209 845 232 837 271) (938 232 930 235 911 229 882 208 864 177 837 103 891 122 922 145 943 176 950 216)) ; ず
                (12391 1000 (817 308 806 316 711 348 685 361 641 392 606 431 592 454 568 509 548 587 543 638 544 688 554 734 574 774 600 803 649 827 658 849 661 859 656 875 643 885 620 891 600 884 562 862 514 812 481 756 467 707 464 681 467 600 485 518 514 440 561 353 365 368 278 360 241 349 210 330 187 303 174 266 246 278 365 285 370 282 371 275 482 274 595 260 664 244 726 224 768 236 797 254 819 276 823 298) (938 203 921 191 896 159 868 101 926 116 959 135 972 147 988 178 987 203 981 217) (856 251 829 230 810 200 790 146 831 154 850 162 880 184 897 215 898 234 894 256)) ; で
                (12392 1000 (779 348 629 404 547 442 522 458 513 466 517 544 505 554 492 556 464 549 439 535 422 549 406 565 381 604 366 648 364 670 365 692 377 729 388 743 420 766 461 780 514 790 604 791 611 789 613 781 713 792 746 804 762 818 768 828 758 844 745 856 730 862 690 869 602 873 509 866 452 854 401 834 357 806 338 789 308 748 298 724 286 675 290 632 313 577 390 475 397 458 387 418 368 376 268 214 318 231 382 270 424 312 460 370 473 367 473 389 571 330 675 278 668 266 656 260 627 252 634 243 658 233 688 231 722 234 754 242 788 257 814 294 814 313 808 324)) ; と
                (12394 1000 (819 463 759 475 701 495 657 515 631 533 609 596 606 627 613 684 696 700 741 721 776 752 790 771 788 795 793 803 766 817 706 832 712 838 709 842 696 845 669 862 645 864 690 810 702 783 703 768 679 756 662 752 619 752 622 801 614 848 588 905 577 919 569 917 564 923 542 910 486 900 461 889 418 857 364 800 371 803 371 787 379 761 408 732 448 713 545 694 547 761 492 770 448 787 480 817 504 828 525 827 540 812 545 799 547 761 545 694 542 589 548 545 561 510 647 442 695 414 748 390 730 360 732 345 786 353 823 371 840 385 853 400 861 419 863 439 858 461) (423 362 353 555 291 695 263 704 241 695 226 674 212 636 278 520 311 441 326 389 232 359 194 335 198 327 366 280 386 228 409 124 438 78 463 98 479 129 485 164 484 183 474 218 504 236 548 245 554 258 574 282 576 300)) ; な
                (12434 1000 (813 539 754 570 571 633 561 699 551 720 543 727 519 733 497 724 483 700 473 672 438 683 403 701 376 725 367 739 364 755 365 772 375 785 406 804 447 813 492 815 599 796 636 796 675 808 690 820 700 833 704 850 654 878 610 888 507 892 456 887 408 875 348 846 318 818 298 781 291 735 310 701 340 678 400 645 469 617 465 571 447 534 435 520 408 499 395 493 372 490 325 496 316 495 300 484 297 466 300 444 336 347 300 339 273 327 216 287 245 272 263 268 346 266 364 262 378 245 410 174 439 141 472 119 507 112 526 113 533 124 546 132 545 168 527 173 510 184 483 218 464 253 508 244 544 230 560 214 561 203 556 192 564 192 636 226 643 249 638 268 624 284 595 301 557 313 461 336 432 350 409 377 393 424 467 460 503 487 526 514 542 547 581 503 631 464 688 436 727 427 728 482 680 489 634 509 597 538 573 575 676 526 709 503 728 482 727 427 781 430 815 444 846 471 847 509)) ; を
                (22120 1000 (957 751 937 760 901 761 840 750 802 731 793 738 782 756 768 828 751 858 776 864 796 880 769 890 728 896 607 897 596 919 562 907 537 885 517 858 529 782 528 721 512 668 490 643 546 629 665 625 703 668 672 666 603 671 595 746 600 848 644 852 686 844 701 753 703 668 665 625 528 484 484 489 460 499 438 516 362 599 287 646 339 644 366 636 376 687 355 687 310 695 263 713 266 826 270 869 304 867 366 855 376 687 366 636 373 630 395 634 467 654 514 692 496 712 479 714 470 724 457 752 438 869 455 890 397 906 277 919 267 931 255 936 228 927 202 906 184 883 196 820 194 731 136 764 107 776 74 781 33 777 94 721 117 706 125 707 232 620 257 603 273 597 270 586 318 548 359 505 315 511 266 530 226 536 209 532 180 516 139 463 160 459 203 466 235 464 418 434 427 424 445 382 427 352 418 346 416 356 406 371 404 385 264 400 226 415 211 427 198 422 159 388 146 382 157 365 164 344 166 320 163 237 105 194 159 166 215 155 338 141 349 187 307 191 232 208 235 357 314 349 345 339 349 187 338 141 353 132 356 124 433 133 486 151 510 177 469 180 455 193 436 230 421 300 500 344 521 364 528 378 525 388 516 408 497 431 668 424 702 412 722 412 783 430 837 456 811 476 732 472 596 480 622 502 696 548 720 572 822 604 919 646 952 688 971 735) (839 187 816 201 724 219 720 166 600 187 607 321 640 324 717 318 724 219 816 201 796 360 741 374 732 364 718 361 639 368 607 364 589 389 567 375 531 339 535 278 531 184 497 148 506 138 521 135 584 138 676 124 717 125 736 112 759 111 802 116 822 131 874 149 895 164 902 177)) ; 器
                (22311 1000 (911 845 904 852 885 857 698 835 535 835 405 852 347 875 332 873 285 847 274 845 274 831 270 824 243 800 246 784 242 774 387 777 460 771 532 759 535 546 442 553 373 568 335 532 318 510 306 476 309 460 380 474 427 479 479 479 533 472 530 393 526 362 516 342 479 288 478 256 522 262 564 278 601 306 614 323 624 344 614 364 609 385 608 464 676 460 715 446 799 469 819 482 831 501 829 530 746 527 611 534 602 604 598 762 691 770 725 766 755 753 810 761 849 773 883 792 907 819 913 836) (872 230 860 231 684 224 522 232 416 246 311 267 315 335 313 402 297 511 274 590 230 686 204 776 180 827 147 873 145 886 131 895 111 894 104 908 95 952 81 946 34 958 44 936 62 919 75 894 162 698 201 587 229 467 233 409 228 338 214 298 173 244 164 202 153 180 159 170 180 166 203 169 248 186 365 183 686 162 709 157 740 143 754 142 789 147 856 169 882 197 892 218) (120 916 106 920 107 910 117 907 118 901 127 905)) ; 圧
                (23039 1000 (912 656 743 642 675 646 650 722 582 660 578 639 474 646 430 653 399 707 392 734 537 768 565 719 581 680 582 660 650 722 613 792 764 858 820 895 844 928 837 939 847 942 827 956 806 959 777 955 716 939 668 899 575 847 518 895 483 914 439 930 398 939 360 942 290 938 277 934 268 925 261 928 233 905 252 904 278 915 282 908 291 904 337 905 341 898 388 882 440 858 495 820 457 799 410 786 368 768 324 808 313 813 290 810 275 799 268 786 270 761 294 730 337 700 330 697 337 694 351 674 358 670 350 663 327 658 280 665 205 683 162 702 140 704 87 676 66 647 47 632 46 623 64 598 144 607 326 597 382 598 394 576 393 564 389 560 382 557 372 563 352 566 300 550 275 551 292 538 337 520 354 493 378 479 408 450 434 413 442 395 450 363 448 338 437 316 427 306 395 318 364 340 379 292 428 202 447 156 402 88 442 82 474 88 544 129 548 141 544 161 509 200 582 199 678 190 678 238 639 238 518 260 466 262 457 268 451 282 489 284 521 301 556 332 569 333 588 325 609 310 678 238 678 190 702 186 713 175 726 169 741 168 771 176 801 193 834 219 851 241 851 255 795 272 668 358 648 367 602 374 640 396 747 446 778 465 792 476 789 483 801 489 808 500 820 523 817 536 796 550 753 558 714 556 671 544 651 525 598 454 527 384 499 432 440 500 472 521 492 554 468 588 561 588 554 564 554 551 621 557 655 573 671 585 765 586 777 584 796 571 832 572 870 582 957 619 968 636 968 649) (298 464 274 530 264 541 240 548 201 534 148 501 126 482 99 449 122 439 136 440 180 450 209 466 233 440 295 343 294 365 289 384 302 394 296 406 298 419 316 438) (270 258 231 230 202 186 182 132 192 129 250 154 300 192 324 231 327 260 323 275)) ; 姿
                (23578 1000 (929 463 879 481 862 496 852 612 852 669 841 712 821 829 808 870 765 907 749 930 713 922 671 905 615 868 594 842 570 840 540 822 655 813 689 805 718 788 737 758 749 716 755 666 756 584 751 500 746 439 714 427 647 423 411 440 273 452 265 468 229 469 241 574 255 804 266 885 249 900 196 876 155 838 135 804 153 772 161 732 164 560 160 519 121 470 111 435 154 418 204 406 443 381 441 186 385 140 365 107 410 97 455 102 496 118 513 129 540 157 504 376 706 374 788 363 812 364 829 370 844 385 873 388 886 396 942 446) (708 559 690 563 673 575 660 596 651 622 561 640 559 567 524 560 504 560 406 575 403 628 410 719 556 707 561 640 651 622 631 728 610 761 531 768 408 770 402 789 388 788 366 777 332 735 339 689 335 622 324 570 314 558 302 526 330 510 368 518 414 516 535 508 538 507 535 499 558 492 602 492 647 504 668 514 701 538 711 552) (782 249 774 254 721 272 686 298 613 336 594 328 577 326 590 303 649 242 667 218 674 186 664 165 653 154 681 146 719 156 786 206 790 228) (334 346 326 356 304 352 284 343 264 328 226 285 165 198 255 219 305 248 330 276 339 295 346 341)) ; 尚
                (27494 1000 (943 930 918 938 894 940 858 935 807 910 777 886 749 857 704 789 641 661 598 552 561 421 477 434 440 445 447 475 445 560 484 551 526 552 567 560 600 575 590 584 561 598 441 629 443 714 440 763 462 762 486 754 496 748 500 739 595 754 617 762 637 772 631 782 622 788 553 798 465 818 348 852 246 891 231 908 190 926 176 914 106 842 118 821 167 830 196 824 190 717 183 664 164 616 140 592 146 570 153 566 192 575 258 608 267 673 263 803 355 786 373 777 368 654 358 615 343 599 333 594 340 587 367 574 362 500 360 485 348 463 272 475 161 511 110 449 90 410 99 402 104 402 135 414 141 413 146 407 176 416 208 416 327 388 544 360 533 270 347 301 242 327 226 300 190 256 173 214 196 214 255 233 288 236 354 227 454 194 519 210 519 188 514 178 467 117 461 106 457 82 537 106 602 141 613 178 615 199 618 350 678 342 696 328 785 354 806 367 812 377 798 390 778 400 754 405 621 415 658 535 703 645 762 742 796 784 835 821 850 788 853 753 849 710 834 628 852 642 897 700 917 713 927 716 934 744 943 839 950 858 973 890 974 901 968 916) (868 348 849 352 837 350 813 336 780 299 720 202 700 183 738 189 774 199 820 222 841 238 859 257 873 279 889 334)) ; 武
                (30064 1000 (965 720 910 724 725 712 630 713 664 743 745 791 768 823 781 828 820 916 828 962 820 959 817 960 821 962 802 963 783 959 766 952 734 928 651 828 649 808 597 748 590 737 583 713 497 717 413 727 437 748 441 759 438 781 423 803 404 822 346 872 330 876 333 891 306 903 268 944 216 944 190 934 199 916 196 910 224 897 277 855 301 843 290 839 316 813 335 775 337 755 333 735 244 744 213 756 193 780 156 780 125 768 37 698 61 689 66 683 88 688 136 689 276 672 344 672 351 612 324 610 297 623 262 617 203 593 200 578 186 552 185 530 202 538 238 545 330 538 330 530 310 494 311 486 319 478 294 477 276 470 262 458 248 421 246 363 250 278 247 236 171 158 192 145 214 140 236 128 369 123 478 110 616 113 648 109 682 90 695 87 748 94 807 124 840 154 861 187 855 196 844 199 785 199 770 213 666 230 658 158 564 156 525 161 529 206 518 251 453 262 450 193 442 172 402 170 323 191 317 246 319 273 453 262 518 251 554 254 568 259 622 288 611 290 619 310 596 308 542 318 514 318 453 321 364 338 349 338 323 329 320 384 326 418 397 407 445 411 452 366 453 321 514 318 507 403 550 404 613 391 648 389 666 230 770 213 766 292 742 444 648 456 658 469 608 515 604 494 583 452 448 461 400 473 377 482 401 515 434 529 474 532 608 515 658 469 684 490 783 531 808 549 817 560 782 568 691 571 674 607 597 582 490 584 427 593 424 664 586 660 597 582 674 607 662 649 720 657 756 657 778 652 810 634 901 653 931 664 956 682 973 709)) ; 異
                (31471 1000 (957 655 913 671 906 679 904 773 816 740 810 631 787 621 775 620 728 625 737 662 737 684 724 836 725 851 742 858 757 862 781 857 797 841 805 824 814 780 816 740 904 773 895 794 899 823 897 841 886 874 860 920 863 921 858 935 840 952 816 958 784 952 750 930 734 915 716 879 704 885 692 884 685 878 678 685 669 630 615 638 628 670 623 711 618 888 594 884 571 868 568 716 558 673 548 654 518 661 508 658 500 689 501 793 495 830 506 867 518 937 487 936 460 921 438 897 412 853 444 814 446 791 443 805 439 785 441 774 448 767 448 752 442 763 434 703 419 666 407 650 391 639 401 625 413 615 501 600 523 592 541 575 542 554 556 524 506 522 475 514 449 496 432 466 505 458 683 449 719 443 744 432 772 437 812 458 854 494 801 502 689 504 652 512 605 561 596 581 646 588 741 577 781 578 779 569 806 564 852 565 894 576 951 607 946 622 963 646) (393 359 247 377 190 396 155 403 203 498 212 706 216 706 218 717 272 706 288 695 291 686 288 689 289 678 310 552 315 493 312 458 293 402 296 379 331 383 346 391 371 418 398 467 381 520 352 689 423 720 418 731 400 743 310 757 232 780 174 809 138 837 103 837 72 821 48 792 40 775 33 736 124 738 175 728 144 685 136 666 136 648 142 638 145 623 131 410 107 408 63 380 45 364 36 351 33 338 42 334 60 315 84 318 132 336 155 339 270 318 269 229 226 202 205 179 198 166 218 152 261 145 318 153 323 163 333 167 333 197 321 251 312 278 292 314 329 306 367 308 400 321 424 345) (847 397 728 393 560 403 529 410 499 429 477 430 457 425 438 414 423 398 406 363 424 358 443 362 439 273 416 241 401 201 430 190 445 191 473 202 518 239 509 290 507 343 560 346 614 341 620 260 616 199 606 165 578 127 564 102 585 91 612 90 640 96 678 116 692 134 694 169 680 284 678 336 751 333 782 342 794 300 792 257 781 215 761 167 794 158 830 166 862 184 897 221)) ; 端
                (31561 1000 (929 571 889 576 766 563 651 565 664 592 664 618 718 607 773 610 831 632 879 664 863 679 832 688 669 676 674 858 662 929 654 950 617 976 609 988 584 990 540 983 520 974 412 898 372 878 552 895 567 884 579 869 586 850 592 816 592 778 584 678 421 690 271 711 248 692 195 673 186 664 179 649 217 631 249 627 579 621 581 608 578 592 565 563 483 573 267 584 213 594 155 613 131 606 70 558 55 541 48 518 78 519 137 538 181 527 230 520 447 508 451 496 450 461 358 466 291 480 280 477 260 462 215 399 250 394 277 404 444 404 450 379 446 368 411 301 410 289 434 288 456 293 476 303 536 351 532 364 533 398 643 390 693 391 738 402 758 411 791 435 751 448 710 454 535 456 530 464 521 499 754 504 764 501 777 489 799 492 889 513 931 530 965 553) (507 233 500 238 464 248 452 256 374 261 382 305 385 369 370 372 347 392 330 380 317 364 308 344 300 310 297 271 290 268 261 264 195 328 178 338 166 338 125 351 128 337 217 211 223 188 243 149 238 138 210 116 198 96 236 94 301 104 328 114 351 129 349 144 342 158 295 209 374 203 444 203 488 213 509 222) (856 234 731 245 736 260 734 274 703 336 686 354 659 365 641 367 646 360 645 356 606 360 628 327 643 289 657 251 650 244 624 239 614 234 539 295 524 302 488 302 507 261 568 170 588 130 555 73 591 72 626 76 648 83 666 94 680 109 660 154 636 194 728 192 764 186 791 175 876 200 898 215 905 226) (490 844 465 854 433 840 405 822 380 800 361 773 345 742 333 706 410 730 459 757 483 781 491 796 499 832)) ; 等
                (33853 1000 (949 736 933 747 871 748 813 734 779 714 710 664 684 636 619 582 538 674 650 673 710 664 779 714 741 882 680 812 680 725 582 727 526 736 533 801 533 876 670 862 680 812 741 882 769 896 776 904 776 917 562 924 492 941 476 919 450 868 456 831 452 745 415 769 396 775 377 778 372 769 363 766 335 767 333 802 327 821 262 941 222 919 186 892 155 862 129 826 131 820 148 820 213 840 266 780 335 662 341 706 335 750 347 750 370 740 431 690 416 665 428 660 458 662 561 541 568 528 499 452 484 464 439 528 415 552 405 557 356 536 439 427 485 354 460 331 454 312 517 316 541 324 559 340 631 332 650 382 581 387 545 382 510 434 597 487 637 423 650 382 631 332 653 326 657 308 676 310 731 328 792 355 810 367 814 375 813 385 807 399 759 415 739 428 706 461 664 522 714 554 843 616 894 647 922 672 934 688 951 725) (879 242 830 250 659 247 633 286 617 296 594 295 582 310 573 309 580 276 580 253 508 248 384 257 375 310 362 336 354 346 328 351 310 262 266 266 171 289 141 268 111 240 91 203 114 199 161 210 189 202 296 193 287 150 265 81 299 89 316 96 346 119 368 149 377 188 580 183 594 160 595 131 588 102 573 64 588 62 619 74 682 126 670 176 732 176 762 169 773 162 866 193 895 214 907 228) (258 642 224 625 198 600 149 527 115 496 115 491 137 491 195 502 265 526 306 595 310 626 305 642) (339 420 338 432 332 444 307 466 274 444 247 416 226 382 209 344 240 342 272 350 314 374 332 396)) ; 落
                (38283 1000 (896 189 873 199 868 230 860 322 855 537 870 779 866 868 869 900 845 959 788 956 745 946 707 928 668 888 648 887 667 904 659 904 629 887 599 860 568 850 565 838 551 817 545 792 549 682 547 659 547 604 543 550 536 524 431 534 438 566 439 615 547 604 547 659 472 663 438 669 416 769 390 821 356 857 303 864 328 832 346 794 364 742 375 676 314 682 268 675 246 662 239 653 236 627 376 622 376 578 368 544 345 551 327 537 273 529 260 515 274 502 292 494 314 490 456 485 606 464 670 470 705 488 698 501 698 508 651 518 603 518 608 598 682 602 707 609 727 624 739 650 709 654 640 652 610 659 615 782 610 844 698 853 753 854 771 816 775 797 778 734 770 314 760 152 664 150 621 156 585 169 582 238 642 232 678 234 706 245 714 256 719 271 694 282 616 288 583 301 583 360 616 363 685 356 719 357 746 369 756 380 757 388 753 396 736 399 582 409 571 429 530 409 496 380 508 342 512 308 508 276 496 255 510 251 514 217 504 185 491 175 472 169 472 159 465 152 471 142 503 126 570 122 752 99 801 98 855 108 890 130 929 144 948 161 951 176) (454 205 441 205 427 238 418 365 346 360 345 304 342 278 340 224 325 182 248 191 213 199 187 215 178 228 203 258 208 281 293 262 311 263 327 268 342 278 345 304 298 309 208 337 201 418 296 399 339 385 346 360 418 365 400 422 266 454 202 462 196 830 200 920 187 922 162 915 139 899 102 857 117 803 127 746 140 487 141 384 134 322 127 294 116 268 92 253 76 232 72 208 77 195 99 172 159 159 256 148 280 142 318 120 349 110 422 134 446 148 464 167 472 195)) ; 開
                (38666 1000 (913 424 887 457 837 491 831 478 816 480 793 471 753 425 808 329 806 319 789 297 543 292 524 293 527 447 511 504 495 504 481 499 468 488 453 463 450 446 456 422 458 394 453 300 329 307 237 320 221 349 194 426 176 455 182 479 182 521 160 541 150 544 98 497 81 474 69 442 104 415 138 355 147 333 130 313 118 306 124 291 133 282 145 276 201 266 221 257 453 240 443 194 429 190 402 190 326 206 304 199 237 109 239 101 247 95 289 100 353 125 558 116 650 102 727 140 743 158 715 172 711 181 511 188 522 217 521 240 740 240 804 248 843 259 879 280 890 310 926 362 931 392) (817 932 718 914 666 910 518 909 531 854 524 672 496 669 437 679 443 726 440 850 531 854 518 909 407 917 273 933 218 956 124 870 149 863 202 873 382 857 376 686 352 683 327 695 314 692 285 696 271 692 236 672 216 652 206 634 208 626 213 623 260 636 269 630 350 625 690 612 744 625 773 645 785 659 726 668 582 669 588 682 602 689 588 791 589 850 674 852 692 842 695 831 785 859 837 884 862 903 868 916 869 930) (693 564 347 590 332 584 318 583 309 576 278 537 266 511 340 520 427 522 513 514 582 498 649 520 705 554) (696 812 666 837 628 817 621 808 682 715 670 691 669 679 716 680 744 689 766 706 776 732) (343 782 343 796 331 834 290 822 274 812 250 784 218 709 224 702 264 715 305 739 337 768) (678 498 643 498 586 444 579 433 573 405 642 427 671 443 686 460 692 488) (394 408 376 419 355 410 320 385 292 353 279 336 280 333 289 326 356 342 383 362 398 392) (676 396 650 399 612 376 582 344 577 332 576 303 604 312 618 310 626 321 671 350 684 370 685 386) (353 508 334 500 317 487 304 470 276 415 338 430 364 446 380 468 385 498)) ; 霊
                (39318 1000 (934 313 924 315 767 308 494 315 505 328 508 351 497 374 469 410 506 414 592 413 625 398 687 400 777 425 785 443 808 462 814 473 777 492 742 517 738 608 737 917 735 939 724 946 717 958 679 943 647 923 635 906 626 885 640 841 639 598 629 456 555 452 376 470 369 565 391 568 438 564 500 546 569 571 601 589 540 603 461 613 392 620 366 613 360 641 356 705 496 692 532 692 570 700 589 711 606 728 433 752 391 754 349 749 355 797 354 840 580 834 640 841 626 885 567 882 485 887 369 900 362 910 325 904 300 886 262 844 241 827 256 789 270 733 290 577 279 566 287 555 294 534 289 514 277 493 234 449 246 437 266 434 281 438 293 428 306 422 364 415 385 391 418 334 374 328 352 330 206 360 169 363 132 362 102 335 40 264 58 262 62 257 104 271 171 275 341 261 335 250 264 189 257 154 231 101 320 137 351 159 372 184 384 208 388 257 428 253 514 254 542 249 567 237 590 215 648 126 639 112 610 86 604 72 620 65 660 62 702 72 733 91 753 112 761 137 754 163 742 172 686 199 667 216 649 243 686 247 776 246 794 238 814 234 836 236 880 249 902 260 921 272 950 299)) ; 首
                )))

;;; (the consing probe's parts, debug 79195: what a draw path's single reads cost in DEFUN-FAST code)
(defun-fast %lbt-fighter (e) (fighter e) nil)
(defun-fast %lbt-pos (e) (pos-of e) nil)
(defun-fast %lbt-yaw (e) (let ((y (yaw-of e))) (declare (single-float y)) (setf y 0f0)) nil)
(defun-fast %lbt-lb (e) (lb e) nil)
(defun-fast %lbt-alpha (e) (let ((a (model-alpha (model e)))) (declare (single-float a)) (setf a 0f0)) nil)
(defun-fast %lbt-eyet (e) (let ((x (i->f (lbs-eye-t (lb e))))) (declare (single-float x)) (setf x 0f0)) nil)
