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
                                   (:core #x9CC4AC) (:lining #x15130F) (:nose #x6B5348) (:ridge #x4A3A31) (:band #xCFC6B0) (:skin #x7A6155) (:eye #xF2F0EC) (:pupil #x2A3124))
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
  ;; the top of the column (decision 57, 2026-10-08): a collar round the head, its rim cut on a slant (low at the front,
  ;; at the chin; high behind, a little over the crown), black inside; the head brown, narrow (x0.8), cut by two pale rings
  ;; through its centre tilted 15 deg to each side (their rims the crown's bands, crossing on top), both eyes open, a darker
  ;; nose a trapezoid in profile (narrow at the top), a white cylinder over the face's lower half, the chin on a round knob
  ;; (tagged: the revival's headless column hides the head, keeps the collar)
  ;; (the collar's outside on the column's top radius, 0.19 m; the head the base form's size, set 3 cm into the collar: the
  ;; user, 2026-10-08)
  (:head (:sphere 0.086 :at (0 0.14 0) :seg 16 :squash (0.8 1 1) :c :skin :tag :jl-head)        ; the base form's head size
         (:cyl 0.0885 0.017 :at (0 0.14 0) :rot (15 0 90) :seg 24 :squash (0.8 1 1) :c :band :tag :jl-head)        ; two rings through his centre,
         (:cyl 0.0885 0.017 :at (0 0.14 0) :rot (-15 0 90) :seg 24 :squash (0.8 1 1) :c :band :tag :jl-head)       ;  their rims the crown's pale bands
         (:box 0.018 0.008 0.003 :at (0.019 0.155 0.083) :c :eye :tag :jl-head)                    ; both eyes open
         (:box 0.018 0.008 0.003 :at (-0.019 0.155 0.083) :c :eye :tag :jl-head)
         (:box 0.008 0.008 0.003 :at (0.019 0.155 0.085) :c :pupil :tag :jl-head)
         (:box 0.008 0.008 0.003 :at (-0.019 0.155 0.085) :c :pupil :tag :jl-head)
         (:wedge 0.018 0.044 0.016 :at (0 0.128 0.105) :rot (180 0 0) :c :nose :ink 0.6 :tag :jl-head)   ; (the slope ...
         (:box 0.018 0.044 0.024 :at (0 0.128 0.085) :c :nose :ink 0.6 :tag :jl-head)                    ;  on a flat: a trapezoid, the nose)
         (:sphere 0.032 :at (0 0.052 0.072) :seg 10 :c :cream :tag :jl-head)                   ; the chin knob
         (:cyl 0.084 0.06 :at (0 0.08 0) :seg 18 :squash (0.8 1 1) :c :cream :tag :jl-head)   ; the white cylinder over the face's lower half
         (:box 0.05 0.080 0.024 :at (0.0000 0.0000 0.1780) :rot (-0.0 0 0) :c :cream)
         (:box 0.046 0.072 0.01 :at (0.0000 -0.0040 0.1630) :rot (-0.0 0 0) :c :lining)
         (:box 0.05 0.084 0.024 :at (0.0461 0.0021 0.1719) :rot (-15.0 0 0) :c :cream)
         (:box 0.046 0.076 0.01 :at (0.0422 -0.0019 0.1574) :rot (-15.0 0 0) :c :lining)
         (:box 0.05 0.097 0.024 :at (0.0890 0.0084 0.1542) :rot (-30.0 0 0) :c :cream)
         (:box 0.046 0.089 0.01 :at (0.0815 0.0044 0.1412) :rot (-30.0 0 0) :c :lining)
         (:box 0.05 0.117 0.024 :at (0.1259 0.0183 0.1259) :rot (-45.0 0 0) :c :cream)
         (:box 0.046 0.109 0.01 :at (0.1153 0.0143 0.1153) :rot (-45.0 0 0) :c :lining)
         (:box 0.05 0.142 0.024 :at (0.1542 0.0312 0.0890) :rot (-60.0 0 0) :c :cream)
         (:box 0.046 0.134 0.01 :at (0.1412 0.0272 0.0815) :rot (-60.0 0 0) :c :lining)
         (:box 0.05 0.173 0.024 :at (0.1719 0.0463 0.0461) :rot (-75.0 0 0) :c :cream)
         (:box 0.046 0.165 0.01 :at (0.1574 0.0423 0.0422) :rot (-75.0 0 0) :c :lining)
         (:box 0.05 0.205 0.024 :at (0.1780 0.0625 0.0000) :rot (-90.0 0 0) :c :cream)
         (:box 0.046 0.197 0.01 :at (0.1630 0.0585 0.0000) :rot (-90.0 0 0) :c :lining)
         (:box 0.05 0.237 0.024 :at (0.1719 0.0787 -0.0461) :rot (-105.0 0 0) :c :cream)
         (:box 0.046 0.229 0.01 :at (0.1574 0.0747 -0.0422) :rot (-105.0 0 0) :c :lining)
         (:box 0.05 0.267 0.024 :at (0.1542 0.0937 -0.0890) :rot (-120.0 0 0) :c :cream)
         (:box 0.046 0.259 0.01 :at (0.1412 0.0897 -0.0815) :rot (-120.0 0 0) :c :lining)
         (:box 0.05 0.293 0.024 :at (0.1259 0.1067 -0.1259) :rot (-135.0 0 0) :c :cream)
         (:box 0.046 0.285 0.01 :at (0.1153 0.1027 -0.1153) :rot (-135.0 0 0) :c :lining)
         (:box 0.05 0.313 0.024 :at (0.0890 0.1166 -0.1542) :rot (-150.0 0 0) :c :cream)
         (:box 0.046 0.305 0.01 :at (0.0815 0.1126 -0.1412) :rot (-150.0 0 0) :c :lining)
         (:box 0.05 0.326 0.024 :at (0.0461 0.1229 -0.1719) :rot (-165.0 0 0) :c :cream)
         (:box 0.046 0.318 0.01 :at (0.0422 0.1189 -0.1574) :rot (-165.0 0 0) :c :lining)
         (:box 0.05 0.330 0.024 :at (0.0000 0.1250 -0.1780) :rot (-180.0 0 0) :c :cream)
         (:box 0.046 0.322 0.01 :at (0.0000 0.1210 -0.1630) :rot (-180.0 0 0) :c :lining)
         (:box 0.05 0.326 0.024 :at (-0.0461 0.1229 -0.1719) :rot (-195.0 0 0) :c :cream)
         (:box 0.046 0.318 0.01 :at (-0.0422 0.1189 -0.1574) :rot (-195.0 0 0) :c :lining)
         (:box 0.05 0.313 0.024 :at (-0.0890 0.1166 -0.1542) :rot (-210.0 0 0) :c :cream)
         (:box 0.046 0.305 0.01 :at (-0.0815 0.1126 -0.1412) :rot (-210.0 0 0) :c :lining)
         (:box 0.05 0.293 0.024 :at (-0.1259 0.1067 -0.1259) :rot (-225.0 0 0) :c :cream)
         (:box 0.046 0.285 0.01 :at (-0.1153 0.1027 -0.1153) :rot (-225.0 0 0) :c :lining)
         (:box 0.05 0.268 0.024 :at (-0.1542 0.0938 -0.0890) :rot (-240.0 0 0) :c :cream)
         (:box 0.046 0.260 0.01 :at (-0.1412 0.0898 -0.0815) :rot (-240.0 0 0) :c :lining)
         (:box 0.05 0.237 0.024 :at (-0.1719 0.0787 -0.0461) :rot (-255.0 0 0) :c :cream)
         (:box 0.046 0.229 0.01 :at (-0.1574 0.0747 -0.0422) :rot (-255.0 0 0) :c :lining)
         (:box 0.05 0.205 0.024 :at (-0.1780 0.0625 -0.0000) :rot (-270.0 0 0) :c :cream)
         (:box 0.046 0.197 0.01 :at (-0.1630 0.0585 -0.0000) :rot (-270.0 0 0) :c :lining)
         (:box 0.05 0.173 0.024 :at (-0.1719 0.0463 0.0461) :rot (-285.0 0 0) :c :cream)
         (:box 0.046 0.165 0.01 :at (-0.1574 0.0423 0.0422) :rot (-285.0 0 0) :c :lining)
         (:box 0.05 0.142 0.024 :at (-0.1542 0.0312 0.0890) :rot (-300.0 0 0) :c :cream)
         (:box 0.046 0.134 0.01 :at (-0.1412 0.0272 0.0815) :rot (-300.0 0 0) :c :lining)
         (:box 0.05 0.117 0.024 :at (-0.1259 0.0183 0.1259) :rot (-315.0 0 0) :c :cream)
         (:box 0.046 0.109 0.01 :at (-0.1153 0.0143 0.1153) :rot (-315.0 0 0) :c :lining)
         (:box 0.05 0.097 0.024 :at (-0.0890 0.0084 0.1542) :rot (-330.0 0 0) :c :cream)
         (:box 0.046 0.089 0.01 :at (-0.0815 0.0044 0.1412) :rot (-330.0 0 0) :c :lining)
         (:box 0.05 0.084 0.024 :at (-0.0461 0.0021 0.1719) :rot (-345.0 0 0) :c :cream)
         (:box 0.046 0.076 0.01 :at (-0.0422 -0.0019 0.1574) :rot (-345.0 0 0) :c :lining)))

;; JILLIEL 近 KIN (decision 18, §22.2): the same column from the hips up on two long thin cream legs: the column's lower half
;; becomes a short rounded hip mass. The legs are ㄇ-shaped (decision 26, 2026-10-06: 「近戰與梟頭的腿部是從分岔點向後延伸出垂直
;; 支架，在末端才以折角往下延伸，呈現出 ㄇ 字型」): a thigh down to the fork (here: the thigh and the fork's knob), then the
;; front shank straight down from the fork, a strut running back from it and, at its end, the corner and the rear shank
;; down; LILLE-DRAW draws the shanks and the strut in the thigh's frame, each shank's tip on the floor (they stretch or
;; shrink a little with the clips' float, so the feet stay down). Arms hidden and wings drawn as :lille-jilliel.
(defbody :lille-jilliel-kin (:scale 1.0 :width 1.0 :hunch 0 :hurt-r 0.38 :hurt-h 1.8 :props (:arms 2.6)
                             :palette ((:cream #xEDE6CC) (:cream-d #xD9D0B2) (:hole #x2A2A30) (:lining #x15130F) (:nose #x6B5348) (:ridge #x4A3A31) (:band #xCFC6B0) (:skin #x7A6155) (:eye #xF2F0EC)
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
  ;; the top of the column (decision 57, 2026-10-08): a collar round the head, its rim cut on a slant (low at the front,
  ;; at the chin; high behind, a little over the crown), black inside; the head brown, narrow (x0.8), cut by two pale rings
  ;; through its centre tilted 15 deg to each side (their rims the crown's bands, crossing on top), both eyes open, a darker
  ;; nose a trapezoid in profile (narrow at the top), a white cylinder over the face's lower half, the chin on a round knob
  ;; (tagged: the revival's headless column hides the head, keeps the collar)
  ;; (the collar's outside on the column's top radius, 0.19 m; the head the base form's size, set 3 cm into the collar: the
  ;; user, 2026-10-08)
  (:head (:sphere 0.086 :at (0 0.14 0) :seg 16 :squash (0.8 1 1) :c :skin :tag :jl-head)        ; the base form's head size
         (:cyl 0.0885 0.017 :at (0 0.14 0) :rot (15 0 90) :seg 24 :squash (0.8 1 1) :c :band :tag :jl-head)        ; two rings through his centre,
         (:cyl 0.0885 0.017 :at (0 0.14 0) :rot (-15 0 90) :seg 24 :squash (0.8 1 1) :c :band :tag :jl-head)       ;  their rims the crown's pale bands
         (:box 0.018 0.008 0.003 :at (0.019 0.155 0.083) :c :eye :tag :jl-head)                    ; both eyes open
         (:box 0.018 0.008 0.003 :at (-0.019 0.155 0.083) :c :eye :tag :jl-head)
         (:box 0.008 0.008 0.003 :at (0.019 0.155 0.085) :c :pupil :tag :jl-head)
         (:box 0.008 0.008 0.003 :at (-0.019 0.155 0.085) :c :pupil :tag :jl-head)
         (:wedge 0.018 0.044 0.016 :at (0 0.128 0.105) :rot (180 0 0) :c :nose :ink 0.6 :tag :jl-head)   ; (the slope ...
         (:box 0.018 0.044 0.024 :at (0 0.128 0.085) :c :nose :ink 0.6 :tag :jl-head)                    ;  on a flat: a trapezoid, the nose)
         (:sphere 0.032 :at (0 0.052 0.072) :seg 10 :c :cream :tag :jl-head)                   ; the chin knob
         (:cyl 0.084 0.06 :at (0 0.08 0) :seg 18 :squash (0.8 1 1) :c :cream :tag :jl-head)   ; the white cylinder over the face's lower half
         (:box 0.05 0.080 0.024 :at (0.0000 0.0000 0.1780) :rot (-0.0 0 0) :c :cream)
         (:box 0.046 0.072 0.01 :at (0.0000 -0.0040 0.1630) :rot (-0.0 0 0) :c :lining)
         (:box 0.05 0.084 0.024 :at (0.0461 0.0021 0.1719) :rot (-15.0 0 0) :c :cream)
         (:box 0.046 0.076 0.01 :at (0.0422 -0.0019 0.1574) :rot (-15.0 0 0) :c :lining)
         (:box 0.05 0.097 0.024 :at (0.0890 0.0084 0.1542) :rot (-30.0 0 0) :c :cream)
         (:box 0.046 0.089 0.01 :at (0.0815 0.0044 0.1412) :rot (-30.0 0 0) :c :lining)
         (:box 0.05 0.117 0.024 :at (0.1259 0.0183 0.1259) :rot (-45.0 0 0) :c :cream)
         (:box 0.046 0.109 0.01 :at (0.1153 0.0143 0.1153) :rot (-45.0 0 0) :c :lining)
         (:box 0.05 0.142 0.024 :at (0.1542 0.0312 0.0890) :rot (-60.0 0 0) :c :cream)
         (:box 0.046 0.134 0.01 :at (0.1412 0.0272 0.0815) :rot (-60.0 0 0) :c :lining)
         (:box 0.05 0.173 0.024 :at (0.1719 0.0463 0.0461) :rot (-75.0 0 0) :c :cream)
         (:box 0.046 0.165 0.01 :at (0.1574 0.0423 0.0422) :rot (-75.0 0 0) :c :lining)
         (:box 0.05 0.205 0.024 :at (0.1780 0.0625 0.0000) :rot (-90.0 0 0) :c :cream)
         (:box 0.046 0.197 0.01 :at (0.1630 0.0585 0.0000) :rot (-90.0 0 0) :c :lining)
         (:box 0.05 0.237 0.024 :at (0.1719 0.0787 -0.0461) :rot (-105.0 0 0) :c :cream)
         (:box 0.046 0.229 0.01 :at (0.1574 0.0747 -0.0422) :rot (-105.0 0 0) :c :lining)
         (:box 0.05 0.267 0.024 :at (0.1542 0.0937 -0.0890) :rot (-120.0 0 0) :c :cream)
         (:box 0.046 0.259 0.01 :at (0.1412 0.0897 -0.0815) :rot (-120.0 0 0) :c :lining)
         (:box 0.05 0.293 0.024 :at (0.1259 0.1067 -0.1259) :rot (-135.0 0 0) :c :cream)
         (:box 0.046 0.285 0.01 :at (0.1153 0.1027 -0.1153) :rot (-135.0 0 0) :c :lining)
         (:box 0.05 0.313 0.024 :at (0.0890 0.1166 -0.1542) :rot (-150.0 0 0) :c :cream)
         (:box 0.046 0.305 0.01 :at (0.0815 0.1126 -0.1412) :rot (-150.0 0 0) :c :lining)
         (:box 0.05 0.326 0.024 :at (0.0461 0.1229 -0.1719) :rot (-165.0 0 0) :c :cream)
         (:box 0.046 0.318 0.01 :at (0.0422 0.1189 -0.1574) :rot (-165.0 0 0) :c :lining)
         (:box 0.05 0.330 0.024 :at (0.0000 0.1250 -0.1780) :rot (-180.0 0 0) :c :cream)
         (:box 0.046 0.322 0.01 :at (0.0000 0.1210 -0.1630) :rot (-180.0 0 0) :c :lining)
         (:box 0.05 0.326 0.024 :at (-0.0461 0.1229 -0.1719) :rot (-195.0 0 0) :c :cream)
         (:box 0.046 0.318 0.01 :at (-0.0422 0.1189 -0.1574) :rot (-195.0 0 0) :c :lining)
         (:box 0.05 0.313 0.024 :at (-0.0890 0.1166 -0.1542) :rot (-210.0 0 0) :c :cream)
         (:box 0.046 0.305 0.01 :at (-0.0815 0.1126 -0.1412) :rot (-210.0 0 0) :c :lining)
         (:box 0.05 0.293 0.024 :at (-0.1259 0.1067 -0.1259) :rot (-225.0 0 0) :c :cream)
         (:box 0.046 0.285 0.01 :at (-0.1153 0.1027 -0.1153) :rot (-225.0 0 0) :c :lining)
         (:box 0.05 0.268 0.024 :at (-0.1542 0.0938 -0.0890) :rot (-240.0 0 0) :c :cream)
         (:box 0.046 0.260 0.01 :at (-0.1412 0.0898 -0.0815) :rot (-240.0 0 0) :c :lining)
         (:box 0.05 0.237 0.024 :at (-0.1719 0.0787 -0.0461) :rot (-255.0 0 0) :c :cream)
         (:box 0.046 0.229 0.01 :at (-0.1574 0.0747 -0.0422) :rot (-255.0 0 0) :c :lining)
         (:box 0.05 0.205 0.024 :at (-0.1780 0.0625 -0.0000) :rot (-270.0 0 0) :c :cream)
         (:box 0.046 0.197 0.01 :at (-0.1630 0.0585 -0.0000) :rot (-270.0 0 0) :c :lining)
         (:box 0.05 0.173 0.024 :at (-0.1719 0.0463 0.0461) :rot (-285.0 0 0) :c :cream)
         (:box 0.046 0.165 0.01 :at (-0.1574 0.0423 0.0422) :rot (-285.0 0 0) :c :lining)
         (:box 0.05 0.142 0.024 :at (-0.1542 0.0312 0.0890) :rot (-300.0 0 0) :c :cream)
         (:box 0.046 0.134 0.01 :at (-0.1412 0.0272 0.0815) :rot (-300.0 0 0) :c :lining)
         (:box 0.05 0.117 0.024 :at (-0.1259 0.0183 0.1259) :rot (-315.0 0 0) :c :cream)
         (:box 0.046 0.109 0.01 :at (-0.1153 0.0143 0.1153) :rot (-315.0 0 0) :c :lining)
         (:box 0.05 0.097 0.024 :at (-0.0890 0.0084 0.1542) :rot (-330.0 0 0) :c :cream)
         (:box 0.046 0.089 0.01 :at (-0.0815 0.0044 0.1412) :rot (-330.0 0 0) :c :lining)
         (:box 0.05 0.084 0.024 :at (-0.0461 0.0021 0.1719) :rot (-345.0 0 0) :c :cream)
         (:box 0.046 0.076 0.01 :at (-0.0422 -0.0019 0.1574) :rot (-345.0 0 0) :c :lining))
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
(defweapon :lb-line-gold (:length 1.0) (:solid :ink 0 (mbc mb #xCDB070) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))   ; the owl's traces
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
    (:lb-e-q1 :hand-r) (:lb-e-q2 :hand-l) (:lb-e-q3 :hand-r) (:lb-e-f1 :hand-r) (:lb-e-f2 :hand-l) (:lb-e-f3 :hand-r)   ; EN's casts
    (:lb-o-q1 :hand-r) (:lb-o-q2 :hand-l) (:lb-o-q3 :hand-r) (:lb-o-f1 :hand-r) (:lb-o-f2 :hand-l) (:lb-o-f3 :hand-r)
    (:lb-o-stamp :hand-r)                                                ; the owl's long arms (its claws)
    (:lb-oe-q1 :hand-r) (:lb-oe-q2 :hand-l) (:lb-oe-q3 :hand-r) (:lb-oe-f1 :hand-r) (:lb-oe-f2 :hand-l) (:lb-oe-f3 :hand-r))   ; its EN casts
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
;; Decision 50 (2026-10-07, DUEL_LILLE §23.31: 「全身出招」「每招獨立造型」): every J / K is its own whole-body strike, KIN's
;; (melee, on the ㄇ legs) and EN's (laying lines: casts) apart. Each key's comment gives the wings' aims (azimuth / elevation
;; in degrees, the chest's frame: + = his right / up); the hand is the wing tip, so the hit pose (on S, through S + A) puts
;; it at the move's reach (the host FK test; EN's casts at :reach on S, the line's frame). The chest twist and the root
;; turn add to the arm's aim (+ twist / yaw = turned to his left). The spins (K1 / K2, EN's too) turn the root a full turn:
;; their two keys 0.0001 f apart differ by exactly 360 degrees of root yaw (the same pose: the turn's count is unwound
;; between two frames, never sampled), so the clip starts and ends at yaw 0 with no unwinding turn and no blend.
(defstrike :lb-w-q1 (8 3 12 :base :lb-w-stance)   ; J1 左斬: the right wing cocked high behind, a step in, cut right -> left
  (0)
  ;; R 128/24, L -86/-6
  (5 (:root :f -0.12 :u 0.03 :yaw -8) (:spine :flex -5) (:chest :twist -24) (:arm-r :flex -34.2 :side 119.5)
   (:elbow-r :flex 30) (:arm-l :flex 4 :side 84) (:elbow-l :flex 4) (:thigh-r :flex -14) (:thigh-l :flex 16))
  ;; R 138/30, L -84/-4
  (7 (:root :f -0.14 :u 0.03 :yaw -10) (:spine :flex -6) (:chest :twist -28) (:arm-r :flex -40.1 :side 130.8)
   (:elbow-r :flex 34) (:arm-l :flex 6 :side 86) (:elbow-l :flex 4) (:thigh-r :flex -16) (:thigh-l :flex 18))
  ;; R 34/3, L -102/-10
  (:s :snap (:root :f 0.04 :u -0.04 :yaw 6) (:spine :flex 12) (:chest :twist 16) (:arm-r :flex 55.9 :side 95.4)
   (:elbow-r :flex 22) (:arm-l :flex -11.8 :side 79.8) (:elbow-l :flex 4) (:thigh-r :flex 30) (:thigh-l :flex -18))
  ;; R 14/-4, L -110/-12
  (:a (:root :f 0.06 :u -0.04 :yaw 10) (:spine :flex 13) (:chest :twist 26) (:arm-r :flex 75.5 :side 73.9)
   (:elbow-r :flex 22) (:arm-l :flex -19.5 :side 77.3) (:elbow-l :flex 4) (:thigh-r :flex 30) (:thigh-l :flex -18))
  ;; R -33/-16, L -114/-10
  (15 (:root :f 0.2 :u -0.03 :yaw 12) (:spine :flex 12) (:chest :twist 30) (:arm-r :flex 126.3 :side 117.8)
   (:elbow-r :flex 10) (:arm-l :flex -23.6 :side 79.1) (:elbow-l :flex 4) (:thigh-r :flex 24) (:thigh-l :flex -14))
  (:end :lb-w-stance))
(defstrike :lb-w-q2 (7 3 13 :base :lb-w-stance)   ; J2 右斬: the mirror, the left wing, cut left -> right
  (0)
  ;; R 86/-6, L -128/24
  (4 (:root :f -0.12 :u 0.03 :yaw 8) (:spine :flex -5) (:chest :twist 24) (:arm-r :flex 4 :side 84)
   (:elbow-r :flex 4) (:arm-l :flex -34.2 :side 119.5) (:elbow-l :flex 30) (:thigh-r :flex 16) (:thigh-l :flex -14))
  ;; R 84/-4, L -138/30
  (6 (:root :f -0.14 :u 0.03 :yaw 10) (:spine :flex -6) (:chest :twist 28) (:arm-r :flex 6 :side 86)
   (:elbow-r :flex 4) (:arm-l :flex -40.1 :side 130.8) (:elbow-l :flex 34) (:thigh-r :flex 18) (:thigh-l :flex -16))
  ;; R 102/-10, L -34/3
  (:s :snap (:root :f 0.04 :u -0.04 :yaw -6) (:spine :flex 12) (:chest :twist -16) (:arm-r :flex -11.8 :side 79.8)
   (:elbow-r :flex 4) (:arm-l :flex 55.9 :side 95.4) (:elbow-l :flex 22) (:thigh-r :flex -18) (:thigh-l :flex 30))
  ;; R 110/-12, L -14/-4
  (:a (:root :f 0.06 :u -0.04 :yaw -10) (:spine :flex 13) (:chest :twist -26) (:arm-r :flex -19.5 :side 77.3)
   (:elbow-r :flex 4) (:arm-l :flex 75.5 :side 73.9) (:elbow-l :flex 22) (:thigh-r :flex -18) (:thigh-l :flex 30))
  ;; R 114/-10, L 33/-16
  (14 (:root :f 0.2 :u -0.03 :yaw -12) (:spine :flex 12) (:chest :twist -30) (:arm-r :flex -23.6 :side 79.1)
   (:elbow-r :flex 4) (:arm-l :flex 126.3 :side 117.8) (:elbow-l :flex 10) (:thigh-r :flex -14) (:thigh-l :flex 24))
  (:end :lb-w-stance))
(defstrike :lb-w-q3 (9 3 18 :base :lb-w-stance)   ; J3 十字: both wings raised high and wide, crossed down through the front (an X)
  (0)
  ;; R 50/62, L -50/62
  (6 (:root :f -0.1 :u 0.1 :pitch -6) (:spine :flex -10) (:head :flex -4) (:arm-r :flex 17.6 :side 157.8)
   (:elbow-r :flex 20) (:arm-l :flex 17.6 :side 157.8) (:elbow-l :flex 20) (:thigh-r :flex -10) (:thigh-l :flex 10))
  ;; R 46/70, L -46/70
  (8 (:root :f -0.12 :u 0.12 :pitch -7) (:spine :flex -12) (:head :flex -4) (:arm-r :flex 13.7 :side 165.3)
   (:elbow-r :flex 24) (:arm-l :flex 13.7 :side 165.3) (:elbow-l :flex 24) (:thigh-r :flex -12) (:thigh-l :flex 12))
  (:s :snap (:root :f 0.32 :u -0.05 :pitch 4) (:spine :flex 16) (:arm-r :flex 106.1 :side 120.2) (:elbow-r :flex 4)
   (:arm-l :flex 106.1 :side 120.2) (:elbow-l :flex 4) (:thigh-r :flex 26) (:thigh-l :flex -20))   ; R -14/-8, L 14/-8
  (:a (:root :f 0.26 :u -0.05 :pitch 5) (:spine :flex 18) (:arm-r :flex 129.2 :side 130) (:elbow-r :flex 4)
   (:arm-l :flex 129.2 :side 130) (:elbow-l :flex 4) (:thigh-r :flex 26) (:thigh-l :flex -20))   ; R -32/-24, L 32/-24
  ;; R -55/-42, L 55/-42
  (18 (:root :f 0.2 :u -0.06 :pitch 5) (:spine :flex 20) (:arm-r :flex 154.8 :side 137.7) (:elbow-r :flex 10)
   (:arm-l :flex 154.8 :side 137.7) (:elbow-l :flex 10) (:thigh-r :flex 22) (:thigh-l :flex -16))
  (:end :lb-w-stance))
(defstrike :lb-w-f1 (17 4 21 :base :lb-w-stance)   ; K1 旋: coiled right, one full turn left on the legs, the right wing sweeping through
  (0)
  ;; R 105/10, L -55/20
  (6 (:root :u -0.08 :yaw -50) (:spine :flex 8) (:chest :twist -18) (:arm-r :flex -14.8 :side 100.3)
   (:elbow-r :flex 20) (:arm-l :flex 32.6 :side 114) (:elbow-l :flex 20) (:thigh-r :flex -16) (:thigh-l :flex 18))
  ;; R 108/12, L -52/22
  (8.5 (:root :u -0.08 :yaw -58) (:spine :flex 8) (:chest :twist -22) (:arm-r :flex -17.6 :side 102.6)
   (:elbow-r :flex 22) (:arm-l :flex 34.8 :side 117.1) (:elbow-l :flex 22) (:thigh-r :flex -16) (:thigh-l :flex 18))
  ;; R 108/12, L -52/22
  (8.5001 :snap (:root :u -0.08 :yaw -418) (:spine :flex 8) (:chest :twist -22) (:arm-r :flex -17.6 :side 102.6)
   (:elbow-r :flex 22) (:arm-l :flex 34.8 :side 117.1) (:elbow-l :flex 22) (:thigh-r :flex -16) (:thigh-l :flex 18))
  ;; R 92/0, L -92/0
  (13 :snap (:root :u 0.02 :f 0.2 :yaw -200) (:spine :flex 4) (:chest :twist 0) (:arm-r :flex -2 :side 90)
   (:elbow-r :flex 6) (:arm-l :flex -2 :side 90) (:elbow-l :flex 6) (:thigh-r :flex 6) (:thigh-l :flex -6))
  ;; R 14/0, L -118/8
  (:s :snap (:root :f 0.62 :u -0.04 :yaw -10) (:spine :flex 12) (:chest :twist 10) (:arm-r :flex 76 :side 90)
   (:elbow-r :flex 4) (:arm-l :flex -27.7 :side 99) (:elbow-l :flex 10) (:thigh-r :flex 28) (:thigh-l :flex -20))
  ;; R 7/-3, L -122/6
  (:a (:root :f 0.64 :u -0.04 :yaw 14) (:spine :flex 12) (:chest :twist 18) (:arm-r :flex 82.4 :side 66.7)
   (:elbow-r :flex 4) (:arm-l :flex -31.8 :side 97.1) (:elbow-l :flex 10) (:thigh-r :flex 28) (:thigh-l :flex -20))
  ;; R -24/-14, L -118/0
  (28 (:root :f 0.55 :u -0.03 :yaw 24) (:spine :flex 10) (:chest :twist 22) (:arm-r :flex 117.6 :side 121.5)
   (:elbow-r :flex 10) (:arm-l :flex -28 :side 90) (:elbow-l :flex 10) (:thigh-r :flex 22) (:thigh-l :flex -14))
  (:end :lb-w-stance))
(defstrike :lb-w-f2 (20 4 24 :base :lb-w-stance)   ; K2 逆旋: the counter-spin (entered at f6 in its strings), the left wing
  (0)
  (10 (:root :u -0.08 :yaw 50) (:spine :flex 8) (:chest :twist 18) (:arm-r :flex 32.6 :side 114) (:elbow-r :flex 20)
   (:arm-l :flex -14.8 :side 100.3) (:elbow-l :flex 20) (:thigh-r :flex 18) (:thigh-l :flex -16))   ; R 55/20, L -105/10
  ;; R 52/22, L -108/12
  (12.5 (:root :u -0.08 :yaw 58) (:spine :flex 8) (:chest :twist 22) (:arm-r :flex 34.8 :side 117.1)
   (:elbow-r :flex 22) (:arm-l :flex -17.6 :side 102.6) (:elbow-l :flex 22) (:thigh-r :flex 18) (:thigh-l :flex -16))
  ;; R 52/22, L -108/12
  (12.5001 :snap (:root :u -0.08 :yaw 418) (:spine :flex 8) (:chest :twist 22) (:arm-r :flex 34.8 :side 117.1)
   (:elbow-r :flex 22) (:arm-l :flex -17.6 :side 102.6) (:elbow-l :flex 22) (:thigh-r :flex 18) (:thigh-l :flex -16))
  ;; R 92/0, L -92/0
  (17 :snap (:root :u 0.02 :f 0.2 :yaw 200) (:spine :flex 4) (:chest :twist 0) (:arm-r :flex -2 :side 90)
   (:elbow-r :flex 6) (:arm-l :flex -2 :side 90) (:elbow-l :flex 6) (:thigh-r :flex -6) (:thigh-l :flex 6))
  ;; R 118/8, L -14/0
  (:s :snap (:root :f 0.62 :u -0.04 :yaw 10) (:spine :flex 12) (:chest :twist -10) (:arm-r :flex -27.7 :side 99)
   (:elbow-r :flex 10) (:arm-l :flex 76 :side 90) (:elbow-l :flex 4) (:thigh-r :flex -20) (:thigh-l :flex 28))
  ;; R 122/6, L -7/-3
  (:a (:root :f 0.64 :u -0.04 :yaw -14) (:spine :flex 12) (:chest :twist -18) (:arm-r :flex -31.8 :side 97.1)
   (:elbow-r :flex 10) (:arm-l :flex 82.4 :side 66.7) (:elbow-l :flex 4) (:thigh-r :flex -20) (:thigh-l :flex 28))
  ;; R 118/0, L 24/-14
  (31 (:root :f 0.55 :u -0.03 :yaw -24) (:spine :flex 10) (:chest :twist -22) (:arm-r :flex -28 :side 90)
   (:elbow-r :flex 10) (:arm-l :flex 117.6 :side 121.5) (:elbow-l :flex 10) (:thigh-r :flex -14) (:thigh-l :flex 22))
  (:end :lb-w-stance))
(defstrike :lb-w-f3 (21 5 34 :base :lb-w-stance)   ; K3 昇翼: crouched, both wings swept low behind, a rising cleave into the air, the landing
  (0)
  ;; R 150/-28, L -150/-28
  (13 (:root :u -0.2 :pitch 10 :f -0.05) (:spine :flex 22) (:head :flex 6) (:arm-r :flex -49.9 :side 43.2)
   (:elbow-r :flex 20) (:arm-l :flex -49.9 :side 43.2) (:elbow-l :flex 20) (:thigh-r :flex 28) (:thigh-l :flex 22))
  ;; R 110/-40, L -110/-40
  (18 (:root :u -0.16 :pitch 8 :f 0.1) (:spine :flex 18) (:arm-r :flex -15.2 :side 48.2) (:elbow-r :flex 10)
   (:arm-l :flex -15.2 :side 48.2) (:elbow-l :flex 10) (:thigh-r :flex 26) (:thigh-l :flex 10))
  (:s :snap (:root :f 0.72 :u 0.12 :pitch -2) (:spine :flex 6) (:arm-r :flex 81.8 :side 104.1) (:elbow-r :flex 4)
   (:arm-l :flex 81.8 :side 104.1) (:elbow-l :flex 4) (:thigh-r :flex 22) (:thigh-l :flex -14))   ; R 8/2, L -8/2
  (:a (:root :f 0.7 :u 0.34 :pitch -6) (:spine :flex -4) (:arm-r :flex 47.7 :side 173.4) (:elbow-r :flex 4)
   (:arm-l :flex 47.7 :side 173.4) (:elbow-l :flex 4) (:thigh-r :flex 30) (:thigh-l :flex 10))   ; R 6/42, L -6/42
  ;; R 5/78, L -5/78
  (33 (:root :f 0.55 :u 0.5 :pitch -8) (:spine :flex -10) (:head :flex -6) (:arm-r :flex 12 :side 178.9)
   (:elbow-r :flex 8) (:arm-l :flex 12 :side 178.9) (:elbow-l :flex 8) (:thigh-r :flex 40) (:thigh-l :flex 30))
  (41 :snap (:root :f 0.4 :u -0.16 :pitch 10) (:spine :flex 22) (:arm-r :flex 53.4 :side 33) (:elbow-r :flex 8)
   (:arm-l :flex 53.4 :side 33) (:elbow-l :flex 8) (:thigh-r :flex 26) (:thigh-l :flex -24))   ; R 22/-30, L -22/-30
  (47 (:root :f 0.36 :u -0.12 :pitch 8) (:spine :flex 18) (:arm-r :flex 43 :side 32.6) (:elbow-r :flex 10)
   (:arm-l :flex 43 :side 32.6) (:elbow-l :flex 10) (:thigh-r :flex 24) (:thigh-l :flex -20))   ; R 30/-38, L -30/-38
  (:end :lb-w-stance))
(defstrike :lb-e-q1 (4 3 6 :base :lb-w-stance)   ; EN J1: the right wing raised high, thrown down along the line (the cast)
  (0)
  (2 (:root :u 0.06 :pitch -6) (:spine :flex -8) (:chest :twist -16) (:arm-r :flex -8.5 :side 145.9)
   (:elbow-r :flex 24) (:arm-l :flex -5 :side 84) (:elbow-l :flex 4))   ; R 105/55, L -95/-6
  (3 (:root :u 0.07 :pitch -7) (:spine :flex -9) (:chest :twist -18) (:arm-r :flex -9.8 :side 151.5)
   (:elbow-r :flex 26) (:arm-l :flex -5 :side 84) (:elbow-l :flex 4))   ; R 110/60, L -95/-6
  (:s :snap (:root :f 0.12 :u -0.03 :pitch 6) (:spine :flex 14) (:chest :twist 12) (:arm-r :flex 69.5 :side 60.3)
   (:elbow-r :flex 4) (:arm-l :flex -9.7 :side 75.8) (:elbow-l :flex 4))   ; R 18/-10, L -100/-14
  (:a (:root :f 0.1 :u -0.03 :pitch 6) (:spine :flex 16) (:chest :twist 14) (:arm-r :flex 57.9 :side 3.2)
   (:elbow-r :flex 4) (:arm-l :flex -13.6 :side 75.6) (:elbow-l :flex 4))   ; R 2/-32, L -104/-14
  (10 (:root :f 0.08 :u -0.02 :pitch 4) (:spine :flex 12) (:chest :twist 10) (:arm-r :flex 40.8 :side -18.3)
   (:elbow-r :flex 8) (:arm-l :flex -9.8 :side 77.8) (:elbow-l :flex 4))   ; R -20/-46, L -100/-12
  (:end :lb-w-stance))
(defstrike :lb-e-q2 (4 3 6 :base :lb-w-stance)   ; EN J2: the mirror, the left wing
  (0)
  (2 (:root :u 0.06 :pitch -6) (:spine :flex -8) (:chest :twist 16) (:arm-r :flex -5 :side 84) (:elbow-r :flex 4)
   (:arm-l :flex -8.5 :side 145.9) (:elbow-l :flex 24))   ; R 95/-6, L -105/55
  (3 (:root :u 0.07 :pitch -7) (:spine :flex -9) (:chest :twist 18) (:arm-r :flex -5 :side 84) (:elbow-r :flex 4)
   (:arm-l :flex -9.8 :side 151.5) (:elbow-l :flex 26))   ; R 95/-6, L -110/60
  (:s :snap (:root :f 0.12 :u -0.03 :pitch 6) (:spine :flex 14) (:chest :twist -12) (:arm-r :flex -9.7 :side 75.8)
   (:elbow-r :flex 4) (:arm-l :flex 69.5 :side 60.3) (:elbow-l :flex 4))   ; R 100/-14, L -18/-10
  (:a (:root :f 0.1 :u -0.03 :pitch 6) (:spine :flex 16) (:chest :twist -14) (:arm-r :flex -13.6 :side 75.6)
   (:elbow-r :flex 4) (:arm-l :flex 57.9 :side 3.2) (:elbow-l :flex 4))   ; R 104/-14, L -2/-32
  (10 (:root :f 0.08 :u -0.02 :pitch 4) (:spine :flex 12) (:chest :twist -10) (:arm-r :flex -9.8 :side 77.8)
   (:elbow-r :flex 4) (:arm-l :flex 40.8 :side -18.3) (:elbow-l :flex 8))   ; R 100/-12, L 20/-46
  (:end :lb-w-stance))
(defstrike :lb-e-q3 (5 3 9 :base :lb-w-stance)   ; EN J3: both wings raised, crossed down onto the line
  (0)
  (3 (:root :u 0.08 :pitch -8) (:spine :flex -10) (:arm-r :flex 18.1 :side 161) (:elbow-r :flex 20)
   (:arm-l :flex 18.1 :side 161) (:elbow-l :flex 20))   ; R 45/64, L -45/64
  (4 (:root :u 0.09 :pitch -9) (:spine :flex -11) (:arm-r :flex 14.7 :side 166.3) (:elbow-r :flex 22)
   (:arm-l :flex 14.7 :side 166.3) (:elbow-l :flex 22))   ; R 42/70, L -42/70
  (:s :snap (:root :f 0.4 :u -0.04 :pitch 8) (:spine :flex 16) (:arm-r :flex 104.4 :side 146.8) (:elbow-r :flex 4)
   (:arm-l :flex 104.4 :side 146.8) (:elbow-l :flex 4))   ; R -8/-12, L 8/-12
  (:a (:root :f 0.36 :u -0.04 :pitch 8) (:spine :flex 18) (:arm-r :flex 131.8 :side 147) (:elbow-r :flex 4)
   (:arm-l :flex 131.8 :side 147) (:elbow-l :flex 4))   ; R -26/-34, L 26/-34
  (12 (:root :f 0.08 :u -0.03 :pitch 6) (:spine :flex 14) (:arm-r :flex 149.2 :side 149.9) (:elbow-r :flex 10)
   (:arm-l :flex 149.2 :side 149.9) (:elbow-l :flex 10))   ; R -40/-48, L 40/-48
  (:end :lb-w-stance))
(defstrike :lb-e-f1 (9 4 10 :base :lb-w-stance)   ; EN K1: a whirl, the right wing fanning low across the front (the three lines)
  (0)
  (2 (:root :yaw -50) (:spine :flex 6) (:chest :twist -16) (:arm-r :flex -19.5 :side 102.7) (:elbow-r :flex 20)
   (:arm-l :flex 33.5 :side 109.3) (:elbow-l :flex 20))   ; R 110/12, L -55/16
  (2.5 (:root :yaw -52) (:spine :flex 6) (:chest :twist -17) (:arm-r :flex -21.5 :side 102.9) (:elbow-r :flex 20)
   (:arm-l :flex 34.4 :side 109.5) (:elbow-l :flex 20))   ; R 112/12, L -54/16
  (2.5001 :snap (:root :yaw -412) (:spine :flex 6) (:chest :twist -17) (:arm-r :flex -21.5 :side 102.9)
   (:elbow-r :flex 20) (:arm-l :flex 34.4 :side 109.5) (:elbow-l :flex 20))   ; R 112/12, L -54/16
  (6 :snap (:root :yaw -200) (:spine :flex 4) (:chest :twist 0) (:arm-r :flex -5 :side 86) (:elbow-r :flex 6)
   (:arm-l :flex -5 :side 86) (:elbow-l :flex 6))   ; R 95/-4, L -95/-4
  (:s :snap (:root :f 0.72 :pitch 6 :yaw -8) (:spine :flex 12) (:chest :twist 10) (:arm-r :flex 59 :side 74.3)
   (:elbow-r :flex 4) (:arm-l :flex -29.9 :side 94.6) (:elbow-l :flex 10))   ; R 30/-8, L -120/4
  (:a (:root :f 0.66 :pitch 6 :yaw 10) (:spine :flex 12) (:chest :twist 18) (:arm-r :flex 73.7 :side 10.3)
   (:elbow-r :flex 4) (:arm-l :flex -31.9 :side 94.7) (:elbow-l :flex 10))   ; R 3/-16, L -122/4
  (17 (:root :f 0.4 :pitch 4 :yaw 18) (:spine :flex 10) (:chest :twist 20) (:arm-r :flex 57.9 :side -40.1)
   (:elbow-r :flex 10) (:arm-l :flex -28 :side 90) (:elbow-l :flex 10))   ; R -22/-24, L -118/0
  (:end :lb-w-stance))
(defstrike :lb-e-f2 (10 4 12 :base :lb-w-stance)   ; EN K2: the counter-whirl (entered at f3), the left wing
  (0)
  (3 (:root :yaw 30) (:spine :flex 4) (:chest :twist 10) (:arm-r :flex 33.5 :side 109.3) (:elbow-r :flex 16)
   (:arm-l :flex -9.8 :side 100.2) (:elbow-l :flex 16))   ; R 55/16, L -100/10
  (4 (:root :yaw 50) (:spine :flex 6) (:chest :twist 16) (:arm-r :flex 33.5 :side 109.3) (:elbow-r :flex 20)
   (:arm-l :flex -19.5 :side 102.7) (:elbow-l :flex 20))   ; R 55/16, L -110/12
  (4.5 (:root :yaw 52) (:spine :flex 6) (:chest :twist 17) (:arm-r :flex 34.4 :side 109.5) (:elbow-r :flex 20)
   (:arm-l :flex -21.5 :side 102.9) (:elbow-l :flex 20))   ; R 54/16, L -112/12
  (4.5001 :snap (:root :yaw 412) (:spine :flex 6) (:chest :twist 17) (:arm-r :flex 34.4 :side 109.5)
   (:elbow-r :flex 20) (:arm-l :flex -21.5 :side 102.9) (:elbow-l :flex 20))   ; R 54/16, L -112/12
  (7 :snap (:root :yaw 200) (:spine :flex 4) (:chest :twist 0) (:arm-r :flex -5 :side 86) (:elbow-r :flex 6)
   (:arm-l :flex -5 :side 86) (:elbow-l :flex 6))   ; R 95/-4, L -95/-4
  (:s :snap (:root :f 0.72 :pitch 6 :yaw 8) (:spine :flex 12) (:chest :twist -10) (:arm-r :flex -29.9 :side 94.6)
   (:elbow-r :flex 10) (:arm-l :flex 59 :side 74.3) (:elbow-l :flex 4))   ; R 120/4, L -30/-8
  (:a (:root :f 0.66 :pitch 6 :yaw -10) (:spine :flex 12) (:chest :twist -18) (:arm-r :flex -31.9 :side 94.7)
   (:elbow-r :flex 10) (:arm-l :flex 73.7 :side 10.3) (:elbow-l :flex 4))   ; R 122/4, L -3/-16
  (18 (:root :f 0.4 :pitch 4 :yaw -18) (:spine :flex 10) (:chest :twist -20) (:arm-r :flex -28 :side 90)
   (:elbow-r :flex 10) (:arm-l :flex 57.9 :side -40.1) (:elbow-l :flex 10))   ; R 118/0, L 22/-24
  (:end :lb-w-stance))
(defstrike :lb-e-f3 (11 5 17 :base :lb-w-stance)   ; EN K3: rising, both wings overhead, slammed down onto the line (the landing)
  (0)
  (4 (:root :u 0.08) (:spine :flex -4) (:arm-r :flex 22.5 :side 134.1) (:elbow-r :flex 20)
   (:arm-l :flex 22.5 :side 134.1) (:elbow-l :flex 20))   ; R 60/40, L -60/40
  (8 (:root :u 0.3 :pitch -10) (:spine :flex -10) (:head :flex -8) (:arm-r :flex 10.7 :side 170.9)
   (:elbow-r :flex 20) (:arm-l :flex 10.7 :side 170.9) (:elbow-l :flex 20))   ; R 40/76, L -40/76
  (10 (:root :u 0.34 :pitch -11) (:spine :flex -11) (:head :flex -8) (:arm-r :flex 6.5 :side 175.3)
   (:elbow-r :flex 24) (:arm-l :flex 6.5 :side 175.3) (:elbow-l :flex 24))   ; R 36/82, L -36/82
  (:s :snap (:root :f 0.9 :u -0.1 :pitch 8) (:spine :flex 16) (:arm-r :flex 99.4 :side 211.8) (:elbow-r :flex 4)
   (:arm-l :flex 99.4 :side 211.8) (:elbow-l :flex 4))   ; R 5/-8, L -5/-8
  (:a (:root :f 0.7 :u -0.2 :pitch 10) (:spine :flex 20) (:arm-r :flex 130.2 :side 184.8) (:elbow-r :flex 4)
   (:arm-l :flex 130.2 :side 184.8) (:elbow-l :flex 4))   ; R 4/-40, L -4/-40
  (22 (:root :f 0.5 :u -0.16 :pitch 8) (:spine :flex 16) (:arm-r :flex 132.3 :side 186.6) (:elbow-r :flex 8)
   (:arm-l :flex 132.3 :side 186.6) (:elbow-l :flex 8))   ; R 6/-42, L -6/-42
  (:end :lb-w-stance))
;; Decision 56 (2026-10-08, DUEL_LILLE §23.37; the user: 「Jilliel 的 SP1, SP2 跟毀魂技動畫」 redone 「全改」): his SPs and his
;; Kikon in play, whole-body moves like decision 50's strikes (each key's comment: the front wings' aims, azimuth / elevation
;; in the chest frame, + = his right / up; the chest twist and the root turn add to it, + = turned to his left).
;; - SP1 三連 SANREN: three thrusts, the right wing, the left, both, each straight at him on its shot frame, then kicked back
;;   (the column 0.26-0.5 m back, the tip up) while he turns into the next. KIN's (:lb-w-sanren, the move :lb-sanren's
;;   frames 12 22 24, shots f12 / f22 / f32) plays through the KIN kit's :clip-map (the base form's :lb-sanren is the rifle's);
;;   EN's own (:lb-e-sanren, 6 14 12, its lines f6 / f12 / f18). LILLE-DRAW whips the wings and flashes the firing wing's holes.
;; - SP2 二十四孔 NIJUSHI-KO (:lb-w-nijushi, KIN 40 6 30; EN at :clip-s 40, x2): rising 0.3 m, the front wings out into the
;;   ring's lower places (LILLE-DRAW turns the six table wings into the rest of the ring, the holes to him), the bow drawn
;;   (leaning back, shaking harder each 2 f), the shot on S a 0.6 m recoil with the wings blown back, the recovery.
;; - the Kikon 神の裁き in play: the aura (:lb-w-kikon, 8 f) rises toward the ring, the strike (:lb-w-kikon-fire, 20 3 30)
;;   charges it (shaking), fires the 24 lines on S with the recoil, then the wings close down before him (the verdict).
(defpose :lb-w-ring-in (:base :lb-w-stance)          ; the Kikon's aura end: rising, the front wings swung up and out
  (:root :f -0.02 :u 0.16) (:spine :flex -2) (:head :flex 2) (:arm-r :flex 5.9 :side 98) (:elbow-r :flex 12)   ; R 84/8
  (:arm-l :flex 5.9 :side 98) (:elbow-l :flex 12) (:thigh-r :flex -6) (:thigh-l :flex -6))                     ; L -84/8
;; the Kikon cinematic's (decision 56's storyboard, DUEL_LILLE §23.37): the ring held 0.3 m up, the front wings in its
;; lower places (R 75/-22, L -75/-22; LILLE-DRAW turns the six table wings into the rest), and the verdict: the wings
;; closed down before him (R 26/-66, L -26/-66), the column bowed
(defpose :lb-w-ring-pose (:base :lb-w-stance)
  (:root :f -0.04 :u 0.3 :pitch -1) (:spine :flex -4) (:head :flex 0) (:arm-r :flex 13.9 :side 67.3) (:elbow-r :flex 4)
  (:arm-l :flex 13.9 :side 67.3) (:elbow-l :flex 4) (:thigh-r :flex -6) (:thigh-l :flex -6))
(defpose :lb-w-verdict-pose (:base :lb-w-stance)
  (:root :f -0.1 :u 0.08 :pitch 7) (:spine :flex 16) (:head :flex 16) (:arm-r :flex 21.4 :side 11) (:elbow-r :flex 12)
  (:arm-l :flex 21.4 :side 11) (:elbow-l :flex 12) (:thigh-r :flex -4) (:thigh-l :flex -4))
(defclip :lb-w-judge-volley (0.1 :loop t :base :lb-w-ring-pose)   ; beat 4: the volley's recoils, 6 f a cycle
  (0 (:root :f -0.16 :u 0.32 :pitch -5) (:spine :flex -8)) (0.05 (:root :f -0.27 :u 0.33 :pitch -8) (:spine :flex -12)))
(defstrike :lb-w-sanren (12 22 24 :base :lb-w-stance)
  ;; KIN SP1 三連: thrusts f12 the right wing, f22 the left, f32 both; each kicks the column back
  (0)
  ;; R 135/18, L -95/-8
  (5 (:root :f -0.08 :u -0.02 :yaw -10) (:spine :flex -4) (:chest :twist -20) (:arm-r :flex -42.3 :side 114.7)
   (:elbow-r :flex 30) (:arm-l :flex -5 :side 82) (:elbow-l :flex 8) (:thigh-r :flex -12) (:thigh-l :flex 14))
  ;; R 148/24, L -98/-10
  (9 (:root :f -0.12 :u -0.04 :yaw -14) (:spine :flex -6) (:chest :twist -26) (:arm-r :flex -50.8 :side 130)
   (:elbow-r :flex 36) (:arm-l :flex -7.9 :side 79.9) (:elbow-l :flex 8) (:thigh-r :flex -14) (:thigh-l :flex 16))
  ;; R 30/-2, L -104/-12
  (:s :snap (:root :f 0.14 :u -0.06 :yaw 12) (:spine :flex 10) (:chest :twist 18) (:arm-r :flex 59.9 :side 86)
   (:elbow-r :flex 2) (:arm-l :flex -13.7 :side 77.6) (:elbow-l :flex 6) (:thigh-r :flex 24) (:thigh-l :flex -16))
  ;; R 36/16, L -104/-12
  (14 (:root :f -0.12 :u -0.02 :yaw 10) (:spine :flex -4) (:chest :twist 14) (:head :flex -2) (:arm-r :flex 51 :side 116)
   (:elbow-r :flex 12) (:arm-l :flex -13.7 :side 77.6) (:elbow-l :flex 6) (:thigh-r :flex 16) (:thigh-l :flex -10))
  ;; R 56/8, L -104/-12
  (16 (:root :f -0.14 :u -0.02 :yaw 4) (:spine :flex -4) (:chest :twist 8) (:head :flex 4) (:arm-r :flex 33.6 :side 99.6)
   (:elbow-r :flex 16) (:arm-l :flex -13.7 :side 77.6) (:elbow-l :flex 6) (:thigh-r :flex 10) (:thigh-l :flex -6))
  ;; R 98/-10, L -148/24
  (19 (:root :f -0.12 :u -0.04 :yaw 14) (:spine :flex -6) (:chest :twist 26) (:head :flex 4)
   (:arm-r :flex -7.9 :side 79.9) (:elbow-r :flex 10) (:arm-l :flex -50.8 :side 130) (:elbow-l :flex 36)
   (:thigh-r :flex -14) (:thigh-l :flex 16))
  ;; R 104/-12, L -30/-2
  (22 :snap (:root :f 0.14 :u -0.06 :yaw -12) (:spine :flex 10) (:chest :twist -18) (:head :flex 4)
   (:arm-r :flex -13.7 :side 77.6) (:elbow-r :flex 6) (:arm-l :flex 59.9 :side 86) (:elbow-l :flex 2)
   (:thigh-r :flex -16) (:thigh-l :flex 24))
  ;; R 104/-12, L -36/16
  (24 (:root :f -0.12 :u -0.02 :yaw -10) (:spine :flex -4) (:chest :twist -14) (:head :flex -2)
   (:arm-r :flex -13.7 :side 77.6) (:elbow-r :flex 6) (:arm-l :flex 51 :side 116) (:elbow-l :flex 12)
   (:thigh-r :flex -10) (:thigh-l :flex 16))
  ;; R 104/-12, L -56/8
  (26 (:root :f -0.14 :u -0.02 :yaw -4) (:spine :flex -4) (:chest :twist -8) (:head :flex 4)
   (:arm-r :flex -13.7 :side 77.6) (:elbow-r :flex 6) (:arm-l :flex 33.6 :side 99.6) (:elbow-l :flex 16)
   (:thigh-r :flex -6) (:thigh-l :flex 10))
  ;; R 140/30, L -140/30
  (29 (:root :f -0.18 :u 0.06 :pitch -6 :yaw 0) (:spine :flex -10) (:chest :twist 0) (:head :flex -4)
   (:arm-r :flex -41.6 :side 131.9) (:elbow-r :flex 34) (:arm-l :flex -41.6 :side 131.9) (:elbow-l :flex 34)
   (:thigh-r :flex -10) (:thigh-l :flex 10))
  ;; R 5/-3, L -5/-3
  (32 :snap (:root :f 0.2 :u -0.08 :pitch 4 :yaw 0) (:spine :flex 14) (:chest :twist 0) (:head :flex 4)
   (:arm-r :flex 84.2 :side 59) (:elbow-r :flex 2) (:arm-l :flex 84.2 :side 59) (:elbow-l :flex 2) (:thigh-r :flex 22)
   (:thigh-l :flex -18))
  ;; R 14/20, L -14/20
  (:a (:root :f -0.32 :u -0.02 :pitch -9 :yaw 0) (:spine :flex -12) (:chest :twist 0) (:head :flex -8)
   (:arm-r :flex 65.8 :side 146.4) (:elbow-r :flex 12) (:arm-l :flex 65.8 :side 146.4) (:elbow-l :flex 12)
   (:thigh-r :flex 8) (:thigh-l :flex -6))
  ;; R 32/10, L -32/10
  (40 (:root :f -0.38 :u -0.03 :pitch -6 :yaw 0) (:spine :flex -8) (:chest :twist 0) (:head :flex -2)
   (:arm-r :flex 56.6 :side 108.4) (:elbow-r :flex 16) (:arm-l :flex 56.6 :side 108.4) (:elbow-l :flex 16)
   (:thigh-r :flex 8) (:thigh-l :flex -6))
  ;; R 64/-8, L -64/-8
  (48 (:root :f -0.2 :u -0.02 :pitch -2 :yaw 0) (:spine :flex -2) (:chest :twist 0) (:head :flex 4)
   (:arm-r :flex 25.7 :side 81.1) (:elbow-r :flex 12) (:arm-l :flex 25.7 :side 81.1) (:elbow-l :flex 12)
   (:thigh-r :flex 4) (:thigh-l :flex -2))
  (:end :lb-w-stance))
(defstrike :lb-e-sanren (6 14 12 :base :lb-w-stance)
  ;; EN SP1 三連: the lines f6 the right wing, f12 the left, f18 both, each a thrust and a kick back
  (0)
  ;; R 140/22, L -95/-8
  (3 (:root :f -0.08 :u 0.04 :pitch -4 :yaw -12) (:spine :flex -6) (:chest :twist -22) (:arm-r :flex -45.3 :side 122.2)
   (:elbow-r :flex 32) (:arm-l :flex -5 :side 82) (:elbow-l :flex 8))
  ;; R 30/-2, L -104/-12
  (:s :snap (:root :f 0.14 :u -0.03 :pitch 4 :yaw 12) (:spine :flex 10) (:chest :twist 18) (:arm-r :flex 59.9 :side 86)
   (:elbow-r :flex 2) (:arm-l :flex -13.7 :side 77.6) (:elbow-l :flex 6))
  ;; R 38/16, L -104/-12
  (8 (:root :f -0.14 :u 0.02 :pitch -5 :yaw 10) (:spine :flex -5) (:chest :twist 14) (:head :flex -2)
   (:arm-r :flex 49.2 :side 115) (:elbow-r :flex 12) (:arm-l :flex -13.7 :side 77.6) (:elbow-l :flex 6))
  ;; R 98/-10, L -140/22
  (10 (:root :f -0.1 :u 0.04 :pitch -4 :yaw 12) (:spine :flex -6) (:chest :twist 22) (:head :flex 4)
   (:arm-r :flex -7.9 :side 79.9) (:elbow-r :flex 10) (:arm-l :flex -45.3 :side 122.2) (:elbow-l :flex 32))
  ;; R 104/-12, L -30/-2
  (12 :snap (:root :f 0.14 :u -0.03 :pitch 4 :yaw -12) (:spine :flex 10) (:chest :twist -18) (:head :flex 4)
   (:arm-r :flex -13.7 :side 77.6) (:elbow-r :flex 6) (:arm-l :flex 59.9 :side 86) (:elbow-l :flex 2))
  ;; R 104/-12, L -38/16
  (14 (:root :f -0.14 :u 0.02 :pitch -5 :yaw -10) (:spine :flex -5) (:chest :twist -14) (:head :flex -2)
   (:arm-r :flex -13.7 :side 77.6) (:elbow-r :flex 6) (:arm-l :flex 49.2 :side 115) (:elbow-l :flex 12))
  ;; R 138/30, L -138/30
  (16 (:root :f -0.14 :u 0.08 :pitch -6 :yaw 0) (:spine :flex -10) (:chest :twist 0) (:head :flex -4)
   (:arm-r :flex -40.1 :side 130.8) (:elbow-r :flex 32) (:arm-l :flex -40.1 :side 130.8) (:elbow-l :flex 32))
  ;; R 5/-3, L -5/-3
  (18 :snap (:root :f 0.18 :u -0.04 :pitch 6 :yaw 0) (:spine :flex 14) (:chest :twist 0) (:head :flex 4)
   (:arm-r :flex 84.2 :side 59) (:elbow-r :flex 2) (:arm-l :flex 84.2 :side 59) (:elbow-l :flex 2))
  ;; R 14/20, L -14/20
  (:a (:root :f -0.32 :u 0.05 :pitch -10 :yaw 0) (:spine :flex -12) (:chest :twist 0) (:head :flex -8)
   (:arm-r :flex 65.8 :side 146.4) (:elbow-r :flex 12) (:arm-l :flex 65.8 :side 146.4) (:elbow-l :flex 12))
  ;; R 42/6, L -42/6
  (25 (:root :f -0.3 :u 0.03 :pitch -6 :yaw 0) (:spine :flex -6) (:chest :twist 0) (:head :flex 0)
   (:arm-r :flex 47.7 :side 98.9) (:elbow-r :flex 14) (:arm-l :flex 47.7 :side 98.9) (:elbow-l :flex 14))
  (:end :lb-w-stance))
(defstrike :lb-w-nijushi (40 6 30 :base :lb-w-stance)
  ;; SP2 二十四孔: rising, the wings opened into a ring, the bow drawn (shaking), the recoil, blown back
  (0)
  ;; R 84/8, L -84/8
  (8 (:root :f -0.02 :u 0.16) (:spine :flex -2) (:head :flex 2) (:arm-r :flex 5.9 :side 98) (:elbow-r :flex 12)
   (:arm-l :flex 5.9 :side 98) (:elbow-l :flex 12) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 75/-22, L -75/-22
  (16 (:root :f -0.04 :r 0 :u 0.3 :pitch -1) (:spine :flex -4) (:head :flex 0) (:arm-r :flex 13.9 :side 67.3)
   (:elbow-r :flex 4) (:arm-l :flex 13.9 :side 67.3) (:elbow-l :flex 4) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 75/-22, L -75/-22
  (20 (:root :f -0.06 :r 0.008 :u 0.3 :pitch -2) (:spine :flex -6) (:head :flex 0) (:arm-r :flex 13.9 :side 67.3)
   (:elbow-r :flex 4) (:arm-l :flex 13.9 :side 67.3) (:elbow-l :flex 4) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 75.8/-22.4, L -75.8/-22.4
  (22 (:root :f -0.076 :r -0.008 :u 0.3 :pitch -2.556) (:spine :flex -7) (:head :flex 0) (:arm-r :flex 13.1 :side 66.9)
   (:elbow-r :flex 4.7) (:arm-l :flex 13.1 :side 66.9) (:elbow-l :flex 4.7) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 76.6/-22.9, L -76.6/-22.9
  (24 (:root :f -0.091 :r 0.01 :u 0.3 :pitch -3.111) (:spine :flex -8) (:head :flex 0) (:arm-r :flex 12.4 :side 66.5)
   (:elbow-r :flex 5.3) (:arm-l :flex 12.4 :side 66.5) (:elbow-l :flex 5.3) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 77.3/-23.3, L -77.3/-23.3
  (26 (:root :f -0.107 :r -0.012 :u 0.3 :pitch -3.667) (:spine :flex -9) (:head :flex 0) (:arm-r :flex 11.6 :side 66.1)
   (:elbow-r :flex 6) (:arm-l :flex 11.6 :side 66.1) (:elbow-l :flex 6) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 78.1/-23.8, L -78.1/-23.8
  (28 (:root :f -0.122 :r 0.014 :u 0.3 :pitch -4.222) (:spine :flex -10) (:head :flex 0) (:arm-r :flex 10.9 :side 65.8)
   (:elbow-r :flex 6.7) (:arm-l :flex 10.9 :side 65.8) (:elbow-l :flex 6.7) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 78.9/-24.2, L -78.9/-24.2
  (30 (:root :f -0.138 :r -0.018 :u 0.3 :pitch -4.778) (:spine :flex -11) (:head :flex 0) (:arm-r :flex 10.1 :side 65.4)
   (:elbow-r :flex 7.3) (:arm-l :flex 10.1 :side 65.4) (:elbow-l :flex 7.3) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 79.7/-24.7, L -79.7/-24.7
  (32 (:root :f -0.153 :r 0.022 :u 0.3 :pitch -5.333) (:spine :flex -12) (:head :flex 0) (:arm-r :flex 9.4 :side 65)
   (:elbow-r :flex 8) (:arm-l :flex 9.4 :side 65) (:elbow-l :flex 8) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 80.4/-25.1, L -80.4/-25.1
  (34 (:root :f -0.169 :r -0.027 :u 0.3 :pitch -5.889) (:spine :flex -13) (:head :flex 0) (:arm-r :flex 8.6 :side 64.6)
   (:elbow-r :flex 8.7) (:arm-l :flex 8.6 :side 64.6) (:elbow-l :flex 8.7) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 81.2/-25.6, L -81.2/-25.6
  (36 (:root :f -0.184 :r 0.033 :u 0.3 :pitch -6.444) (:spine :flex -14) (:head :flex 0) (:arm-r :flex 7.9 :side 64.2)
   (:elbow-r :flex 9.3) (:arm-l :flex 7.9 :side 64.2) (:elbow-l :flex 9.3) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 82/-26, L -82/-26
  (38 (:root :f -0.2 :r -0.04 :u 0.3 :pitch -7) (:spine :flex -15) (:head :flex 0) (:arm-r :flex 7.2 :side 63.8)
   (:elbow-r :flex 10) (:arm-l :flex 7.2 :side 63.8) (:elbow-l :flex 10) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 118/-4, L -118/-4
  (:s :snap (:root :f -0.62 :r 0 :u 0.38 :pitch -14) (:spine :flex -20) (:head :flex -10) (:arm-r :flex -27.9 :side 85.5)
   (:elbow-r :flex 22) (:arm-l :flex -27.9 :side 85.5) (:elbow-l :flex 22) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 126/4, L -126/4
  (:a (:root :f -0.7 :r 0 :u 0.4 :pitch -15) (:spine :flex -22) (:head :flex -10) (:arm-r :flex -35.9 :side 94.9)
   (:elbow-r :flex 28) (:arm-l :flex -35.9 :side 94.9) (:elbow-l :flex 28) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 106/-12, L -106/-12
  (56 (:root :f -0.48 :r 0 :u 0.26 :pitch -8) (:spine :flex -10) (:head :flex -4) (:arm-r :flex -15.6 :side 77.5)
   (:elbow-r :flex 16) (:arm-l :flex -15.6 :side 77.5) (:elbow-l :flex 16) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 92/-14, L -92/-14
  (66 (:root :f -0.2 :r 0 :u 0.1 :pitch -3) (:spine :flex -4) (:head :flex 2) (:arm-r :flex -1.9 :side 76)
   (:elbow-r :flex 10) (:arm-l :flex -1.9 :side 76) (:elbow-l :flex 10) (:thigh-r :flex -2) (:thigh-l :flex -2))
  (:end :lb-w-stance))
(defstrike :lb-w-kikon (8 0 0 :base :lb-w-stance)
  ;; Kikon 神の裁き, the aura (8 f): rising, the wings swinging up toward the ring
  (0)
  (:end :lb-w-ring-in))
(defstrike :lb-w-kikon-fire (20 3 30 :base :lb-w-stance)
  ;; Kikon 神の裁き, the strike: the ring charged (shaking), the 24 lines on S with a recoil, the wings closed down (the verdict)
  (0 :lb-w-ring-in)
  ;; R 75/-22, L -75/-22
  (7 (:root :f -0.04 :r 0 :u 0.3 :pitch -1) (:spine :flex -4) (:head :flex 0) (:arm-r :flex 13.9 :side 67.3)
   (:elbow-r :flex 4) (:arm-l :flex 13.9 :side 67.3) (:elbow-l :flex 4))
  ;; R 75/-22, L -75/-22
  (10 (:root :f -0.07 :r 0.012 :u 0.3 :pitch -3) (:spine :flex -7) (:head :flex 0) (:arm-r :flex 13.9 :side 67.3)
   (:elbow-r :flex 4) (:arm-l :flex 13.9 :side 67.3) (:elbow-l :flex 4))
  ;; R 76.2/-22.8, L -76.2/-22.8
  (12 (:root :f -0.095 :r -0.013 :u 0.3 :pitch -3.75) (:spine :flex -8.5) (:head :flex 0) (:arm-r :flex 12.7 :side 66.6)
   (:elbow-r :flex 5) (:arm-l :flex 12.7 :side 66.6) (:elbow-l :flex 5))
  ;; R 77.5/-23.5, L -77.5/-23.5
  (14 (:root :f -0.12 :r 0.018 :u 0.3 :pitch -4.5) (:spine :flex -10) (:head :flex 0) (:arm-r :flex 11.4 :side 66)
   (:elbow-r :flex 6) (:arm-l :flex 11.4 :side 66) (:elbow-l :flex 6))
  ;; R 78.8/-24.2, L -78.8/-24.2
  (16 (:root :f -0.145 :r -0.025 :u 0.3 :pitch -5.25) (:spine :flex -11.5) (:head :flex 0) (:arm-r :flex 10.2 :side 65.3)
   (:elbow-r :flex 7) (:arm-l :flex 10.2 :side 65.3) (:elbow-l :flex 7))
  ;; R 80/-25, L -80/-25
  (18 (:root :f -0.17 :r 0.036 :u 0.3 :pitch -6) (:spine :flex -13) (:head :flex 0) (:arm-r :flex 9.1 :side 64.7)
   (:elbow-r :flex 8) (:arm-l :flex 9.1 :side 64.7) (:elbow-l :flex 8))
  ;; R 118/-4, L -118/-4
  (:s :snap (:root :f -0.55 :r 0 :u 0.36 :pitch -13) (:spine :flex -18) (:head :flex -8) (:arm-r :flex -27.9 :side 85.5)
   (:elbow-r :flex 22) (:arm-l :flex -27.9 :side 85.5) (:elbow-l :flex 22))
  ;; R 124/2, L -124/2
  (:a (:root :f -0.62 :r 0 :u 0.38 :pitch -14) (:spine :flex -20) (:head :flex -8) (:arm-r :flex -34 :side 92.4)
   (:elbow-r :flex 26) (:arm-l :flex -34 :side 92.4) (:elbow-l :flex 26))
  ;; R 28/-62, L -28/-62
  (30 (:root :f -0.36 :r 0 :u 0.16 :pitch 6) (:spine :flex 14) (:head :flex 14) (:arm-r :flex 24.5 :side 14)
   (:elbow-r :flex 12) (:arm-l :flex 24.5 :side 14) (:elbow-l :flex 12))
  ;; R 24/-66, L -24/-66
  (40 (:root :f -0.3 :r 0 :u 0.1 :pitch 7) (:spine :flex 16) (:head :flex 16) (:arm-r :flex 21.8 :side 10.3)
   (:elbow-r :flex 12) (:arm-l :flex 21.8 :side 10.3) (:elbow-l :flex 12))
  (:end :lb-w-stance))
(defstrike :lb-w-judge-open (24 0 64 :base :lb-w-stance)
  ;; the Kikon cinematic, beat 1 (decision 56, Amendment 2): the wings gathered round the column and shaking harder
  ;; (f4-22, a side jolt every 2 f), snapped open into the ring on f24 (S), held; beat 2: the charge's jolts (f60-86)
  (0)
  (4 :lb-w-fold-pose (:root :u 0.06) (:spine :flex 6) (:head :flex 12))
  (6 :lb-w-fold-pose (:root :u 0.06 :r 0.006) (:spine :flex 6) (:head :flex 12))
  (8 :lb-w-fold-pose (:root :u 0.065 :r -0.006) (:spine :flex 6.375) (:head :flex 12))
  (10 :lb-w-fold-pose (:root :u 0.07 :r 0.008) (:spine :flex 6.75) (:head :flex 12))
  (12 :lb-w-fold-pose (:root :u 0.075 :r -0.01) (:spine :flex 7.125) (:head :flex 12))
  (14 :lb-w-fold-pose (:root :u 0.08 :r 0.013) (:spine :flex 7.5) (:head :flex 12))
  (16 :lb-w-fold-pose (:root :u 0.085 :r -0.016) (:spine :flex 7.875) (:head :flex 12))
  (18 :lb-w-fold-pose (:root :u 0.09 :r 0.021) (:spine :flex 8.25) (:head :flex 12))
  (20 :lb-w-fold-pose (:root :u 0.095 :r -0.026) (:spine :flex 8.625) (:head :flex 12))
  (22 :lb-w-fold-pose (:root :u 0.1 :r 0.032) (:spine :flex 9) (:head :flex 12))
  (:s :snap :lb-w-ring-pose)
  (58 :lb-w-ring-pose)
  (60 :lb-w-ring-pose (:root :f -0.04 :r 0.006 :u 0.3 :pitch -1) (:spine :flex -4))
  (62 :lb-w-ring-pose (:root :f -0.049 :r -0.006 :u 0.3 :pitch -1.385) (:spine :flex -4.615))
  (64 :lb-w-ring-pose (:root :f -0.058 :r 0.007 :u 0.3 :pitch -1.769) (:spine :flex -5.231))
  (66 :lb-w-ring-pose (:root :f -0.068 :r -0.007 :u 0.3 :pitch -2.154) (:spine :flex -5.846))
  (68 :lb-w-ring-pose (:root :f -0.077 :r 0.008 :u 0.3 :pitch -2.538) (:spine :flex -6.462))
  (70 :lb-w-ring-pose (:root :f -0.086 :r -0.01 :u 0.3 :pitch -2.923) (:spine :flex -7.077))
  (72 :lb-w-ring-pose (:root :f -0.095 :r 0.011 :u 0.3 :pitch -3.308) (:spine :flex -7.692))
  (74 :lb-w-ring-pose (:root :f -0.105 :r -0.013 :u 0.3 :pitch -3.692) (:spine :flex -8.308))
  (76 :lb-w-ring-pose (:root :f -0.114 :r 0.015 :u 0.3 :pitch -4.077) (:spine :flex -8.923))
  (78 :lb-w-ring-pose (:root :f -0.123 :r -0.018 :u 0.3 :pitch -4.462) (:spine :flex -9.538))
  (80 :lb-w-ring-pose (:root :f -0.132 :r 0.02 :u 0.3 :pitch -4.846) (:spine :flex -10.154))
  (82 :lb-w-ring-pose (:root :f -0.142 :r -0.023 :u 0.3 :pitch -5.231) (:spine :flex -10.769))
  (84 :lb-w-ring-pose (:root :f -0.151 :r 0.026 :u 0.3 :pitch -5.615) (:spine :flex -11.385))
  (86 :lb-w-ring-pose (:root :f -0.16 :r -0.03 :u 0.3 :pitch -6) (:spine :flex -12))
  (:end :lb-w-ring-pose))
(defstrike :lb-w-judge-shot (2 0 14 :base :lb-w-ring-pose)
  ;; the Kikon cinematic, beat 3: a shot's recoil out of the ring, back into it
  ;; R 112/-6, L -112/-6
  (0 (:root :f -0.42 :u 0.34 :pitch -10) (:spine :flex -14) (:head :flex -6) (:arm-r :flex -21.9 :side 83.5)
   (:elbow-r :flex 18) (:arm-l :flex -21.9 :side 83.5) (:elbow-l :flex 18) (:thigh-r :flex -6) (:thigh-l :flex -6))
  ;; R 118/-2, L -118/-2
  (2 (:root :f -0.48 :u 0.35 :pitch -11) (:spine :flex -16) (:head :flex -6) (:arm-r :flex -28 :side 87.7)
   (:elbow-r :flex 22) (:arm-l :flex -28 :side 87.7) (:elbow-l :flex 22) (:thigh-r :flex -6) (:thigh-l :flex -6))
  (:end :lb-w-ring-pose))
(defstrike :lb-w-judge-close (6 0 40 :base :lb-w-ring-pose)
  ;; the Kikon cinematic, beat 6: the verdict, the wings closed down before him (on f6)
  (0)
  ;; R 26/-66, L -26/-66
  (6 :snap (:root :f -0.1 :u 0.08 :pitch 7) (:spine :flex 16) (:head :flex 16) (:arm-r :flex 21.4 :side 11)
   (:elbow-r :flex 12) (:arm-l :flex 21.4 :side 11) (:elbow-l :flex 12) (:thigh-r :flex -4) (:thigh-l :flex -4))
  (:end :lb-w-verdict-pose))
(defclip :lb-w-breaker (0.4 :loop t :base :lb-w-stance)
  (0 (:root :u -0.2 :pitch 14) (:arm-r :flex -30 :side 40) (:arm-l :flex -30 :side 40))
   (0.2 (:root :u -0.16 :pitch 14)))
(defpose :lb-w-ram-hit (:base :lb-w-stance)
  (:root :f 0.0 :u -0.1) (:spine :flex 4) (:arm-r :flex 66 :side 52) (:elbow-r :flex 24) (:arm-l :flex 66 :side 52)
   (:elbow-l :flex 24))
(defstrike :lb-w-ram (8 4 18 :base :lb-w-stance)
  (0 (:arm-r :flex 10 :side 120) (:arm-l :flex 10 :side 120)) (:s :snap :lb-w-ram-hit) (:a :lb-w-ram-hit)
   (:end :lb-w-stance))

;;; ---------------------------------------------------------------- the owl
;;; 近 KIN (decision 38, 2026-10-06: 「近戰模式翼往後收、身體前傾」): on the ㄇ stilts, the column pitched forward (the spine,
;;; so the hips and the legs stay square), the S-neck lowered and thrust forward like a stalking bird, the long arms raised
;;; forward with the claws up (the wings swept back: LILLE-DRAW). The claws (the hands) strike at the moves' reach: the
;;; strike keys set every channel they move themselves, so the stance moves no strike point (FK test).
(defpose :lb-o-stance ()
  (:root :u -0.02) (:spine :flex 22) (:neck :flex 26) (:head :flex 8)
  (:arm-r :flex 58 :side 14) (:elbow-r :flex 70) (:arm-l :flex 58 :side 14) (:elbow-l :flex 70)
  (:thigh-r :flex 0 :side 5) (:thigh-l :flex 0 :side 5) (:knees :flex 0))   ; (the ㄇ legs stand square: decision 26)
(defclip :lb-o-stance (2.4 :loop t :base :lb-o-stance)
  (0) (1.2 (:root :u -0.04) (:spine :flex 24) (:head :flex 14 :twist 10) (:arm-r :flex 64) (:arm-l :flex 52)))
;; Decision 56 (2026-10-08, DUEL_LILLE §23.37: 「猛禽爪擊」「全身出招」): each J / K is a raptor's claw strike of the whole body,
;; a clear wind-up -> strike -> recovery: the ㄇ legs step or lunge (the thighs; the shanks keep their feet on the floor), the
;; column leans and twists, the S-neck (:neck / :head) strikes with it, the hands (:hand-r / -l) open back in the wind-up and
;; hook in the strike. The arms were solved to world targets for the claws (the comment above each key: right / up /
;; forward in m from where he stands, e = the elbow), so the hit pose (S through S + A) puts the striking claw at the move's
;; reach (the host FK test). KIN's EN twins are their own casts below (:lb-oe-q1 ..).
(defstrike :lb-o-q1 (8 3 12 :base :lb-o-stance)   ; J1 右爪撕: reared up, the right claw cocked high, a step in: raked down across, high right -> low left
  (0)
  ;; R (0.45 2.3 0.35) e119, L (-0.1 1.55 0.95) e85
  (3 (:root :f -0.06 :u 0.02 :yaw -6 :pitch -2) (:spine :flex 14) (:chest :twist -14) (:neck :flex 14)
   (:head :flex -4) (:arm-r :flex 88.7 :side -11.4) (:elbow-r :flex 119.2) (:hand-r :flex -20)
   (:arm-l :flex 35.5 :side 53.2) (:elbow-l :flex 85.4) (:hand-l :flex 10) (:thigh-r :flex -6) (:thigh-l :flex 8))
  ;; R (0.62 2.72 -0.05) e79, L (-0.05 1.6 0.85) e89
  (6 (:root :f -0.14 :u 0.04 :yaw -12 :pitch -4) (:spine :flex 8) (:chest :twist -26) (:neck :flex 2)
   (:head :flex -14) (:arm-r :flex 118.3 :side -17.9) (:elbow-r :flex 79.2) (:hand-r :flex -40)
   (:arm-l :flex 17.3 :side 60.3) (:elbow-l :flex 89.3) (:hand-l :flex 10) (:thigh-r :flex -12) (:thigh-l :flex 14))
  ;; R (0.3 1.5 1.66) e71, L (-0.35 1.45 0.4) e148 MISS 0.04
  (:s :snap (:root :f 0.4 :u -0.06 :yaw 6 :pitch 4) (:spine :flex 30) (:chest :twist 14) (:neck :flex 34)
   (:head :flex 12) (:arm-r :flex 93 :side -50.8) (:elbow-r :flex 70.8) (:hand-r :flex 30)
   (:arm-l :flex -44 :side 16.4) (:elbow-l :flex 148.1) (:hand-l :flex 10) (:thigh-r :flex 32) (:thigh-l :flex -20))
  ;; R (-0.12 1.12 1.66) e68, L (-0.45 1.35 0.25) e130
  (:a (:root :f 0.46 :u -0.07 :yaw 12 :pitch 5) (:spine :flex 33) (:chest :twist 24) (:neck :flex 36)
   (:head :flex 14) (:arm-r :flex 84.3 :side -72.9) (:elbow-r :flex 68.5) (:hand-r :flex 50)
   (:arm-l :flex -46.9 :side 17.5) (:elbow-l :flex 130) (:hand-l :flex 10) (:thigh-r :flex 32) (:thigh-l :flex -20))
  ;; R (-0.6 0.72 1.15) e47 MISS 0.04, L (-0.4 1.3 0.3) e134
  (16 (:root :f 0.38 :u -0.08 :yaw 18 :pitch 5) (:spine :flex 34) (:chest :twist 30) (:neck :flex 30)
   (:head :flex 10) (:arm-r :flex 86.6 :side -149.4) (:elbow-r :flex 47.3) (:hand-r :flex 50)
   (:arm-l :flex -33.7 :side -1.1) (:elbow-l :flex 134.5) (:hand-l :flex 10) (:thigh-r :flex 26) (:thigh-l :flex -16))
  (:end :lb-o-stance))
(defstrike :lb-o-q2 (7 3 13 :base :lb-o-stance)   ; J2 左爪撕: the mirror, the left claw, high left -> low right
  (0)
  ;; L (-0.45 2.3 0.35) e119, R (0.1 1.55 0.95) e85
  (3 (:root :f -0.06 :u 0.02 :yaw 6 :pitch -2) (:spine :flex 14) (:chest :twist 14) (:neck :flex 14) (:head :flex -4)
   (:arm-r :flex 35.5 :side 53.2) (:elbow-r :flex 85.4) (:hand-r :flex 10) (:arm-l :flex 88.7 :side -11.4)
   (:elbow-l :flex 119.2) (:hand-l :flex -20) (:thigh-r :flex 8) (:thigh-l :flex -6))
  ;; L (-0.62 2.72 -0.05) e79, R (0.05 1.6 0.85) e89
  (5 (:root :f -0.14 :u 0.04 :yaw 12 :pitch -4) (:spine :flex 8) (:chest :twist 26) (:neck :flex 2) (:head :flex -14)
   (:arm-r :flex 17.3 :side 60.3) (:elbow-r :flex 89.3) (:hand-r :flex 10) (:arm-l :flex 118.3 :side -17.9)
   (:elbow-l :flex 79.2) (:hand-l :flex -40) (:thigh-r :flex 14) (:thigh-l :flex -12))
  ;; L (-0.3 1.5 1.66) e71, R (0.35 1.45 0.4) e148 MISS 0.04
  (:s :snap (:root :f 0.4 :u -0.06 :yaw -6 :pitch 4) (:spine :flex 30) (:chest :twist -14) (:neck :flex 34)
   (:head :flex 12) (:arm-r :flex -44 :side 16.4) (:elbow-r :flex 148.1) (:hand-r :flex 10)
   (:arm-l :flex 93 :side -50.8) (:elbow-l :flex 70.8) (:hand-l :flex 30) (:thigh-r :flex -20) (:thigh-l :flex 32))
  ;; L (0.12 1.12 1.66) e68, R (0.45 1.35 0.25) e130
  (:a (:root :f 0.46 :u -0.07 :yaw -12 :pitch 5) (:spine :flex 33) (:chest :twist -24) (:neck :flex 36)
   (:head :flex 14) (:arm-r :flex -46.9 :side 17.5) (:elbow-r :flex 130) (:hand-r :flex 10)
   (:arm-l :flex 84.3 :side -72.9) (:elbow-l :flex 68.5) (:hand-l :flex 50) (:thigh-r :flex -20) (:thigh-l :flex 32))
  ;; L (0.6 0.72 1.15) e47 MISS 0.04, R (0.4 1.3 0.3) e134
  (15 (:root :f 0.38 :u -0.08 :yaw -18 :pitch 5) (:spine :flex 34) (:chest :twist -30) (:neck :flex 30)
   (:head :flex 10) (:arm-r :flex -33.7 :side -1.1) (:elbow-r :flex 134.5) (:hand-r :flex 10)
   (:arm-l :flex 86.6 :side -149.4) (:elbow-l :flex 47.3) (:hand-l :flex 50) (:thigh-r :flex -16) (:thigh-l :flex 26))
  (:end :lb-o-stance))
(defstrike :lb-o-q3 (9 3 18 :base :lb-o-stance)   ; J3 雙爪剪: both claws spread high and wide, the neck coiled back, then scissored across with a peck
  (0)
  ;; R (0.85 2 0.3) e112, L (-0.85 2 0.3) e112
  (3 (:root :f -0.04 :u 0.04 :pitch -3) (:spine :flex 12) (:neck :flex 4) (:head :flex -10)
   (:arm-r :flex 105 :side -74.2) (:elbow-r :flex 112.2) (:hand-r :flex -20) (:arm-l :flex 105 :side -74.2)
   (:elbow-l :flex 112.2) (:hand-l :flex -20) (:thigh-r :flex -4) (:thigh-l :flex 4))
  ;; R (1.05 2.15 0.2) e87, L (-1.05 2.15 0.2) e87
  (7 (:root :f -0.1 :u 0.07 :pitch -6) (:spine :flex 6) (:neck :flex -12) (:head :flex -22)
   (:arm-r :flex 119.6 :side -74.8) (:elbow-r :flex 86.6) (:hand-r :flex -40) (:arm-l :flex 119.6 :side -74.8)
   (:elbow-l :flex 86.6) (:hand-l :flex -40) (:thigh-r :flex -8) (:thigh-l :flex 8))
  ;; R (-0.08 1.5 1.7) e51, L (0.14 1.62 1.66) e58
  (:s :snap (:root :f 0.42 :u -0.05 :pitch 5) (:spine :flex 30) (:neck :flex 50) (:head :flex 26)
   (:arm-r :flex 39.8 :side -141.6) (:elbow-r :flex 50.7) (:hand-r :flex 30) (:arm-l :flex 29.4 :side -141.9)
   (:elbow-l :flex 58.5) (:hand-l :flex 30) (:thigh-r :flex 28) (:thigh-l :flex -20))
  ;; R (-0.42 1.3 1.62) e32, L (0.42 1.42 1.6) e47
  (:a (:root :f 0.46 :u -0.06 :pitch 6) (:spine :flex 32) (:neck :flex 56) (:head :flex 30)
   (:arm-r :flex 40 :side -111.4) (:elbow-r :flex 32.5) (:hand-r :flex 50) (:arm-l :flex 29.4 :side -117.4)
   (:elbow-l :flex 46.7) (:hand-l :flex 50) (:thigh-r :flex 28) (:thigh-l :flex -20))
  ;; R (-0.75 0.9 1.05) e4 MISS 0.08, L (0.75 1 1.05) e4
  (20 (:root :f 0.36 :u -0.08 :pitch 5) (:spine :flex 34) (:neck :flex 30) (:head :flex 12)
   (:arm-r :flex 38 :side -71.6) (:elbow-r :flex 4) (:hand-r :flex 40) (:arm-l :flex 36.4 :side -75.8)
   (:elbow-l :flex 4) (:hand-l :flex 40) (:thigh-r :flex 22) (:thigh-l :flex -16))
  (:end :lb-o-stance))
(defstrike :lb-o-f1 (17 4 21 :base :lb-o-stance)   ; K1 掠爪: a wing beat, coiled low, a low glide, the right claw hooked wide across (right -> left)
  (0)
  ;; R (0.8 1.45 -0.55) e94, L (-0.15 1.35 0.8) e114 MISS 0.05
  (4 (:root :f -0.1 :u -0.1 :yaw -10 :pitch 4) (:spine :flex 30) (:chest :twist -16) (:neck :flex 20) (:head :flex 0)
   (:arm-r :flex -44.4 :side 55) (:elbow-r :flex 93.6) (:hand-r :flex -20) (:arm-l :flex 60.5 :side -62)
   (:elbow-l :flex 114.2) (:hand-l :flex 10) (:thigh-r :flex -10) (:thigh-l :flex 18))
  ;; R (1.05 1.5 -0.45) e78, L (-0.25 1.3 0.7) e127
  (10 (:root :f -0.16 :u -0.14 :yaw -22 :pitch 6) (:spine :flex 34) (:chest :twist -30) (:neck :flex 16)
   (:head :flex -4) (:arm-r :flex -1 :side 77.4) (:elbow-r :flex 78.4) (:hand-r :flex -40)
   (:arm-l :flex 94.5 :side -83.1) (:elbow-l :flex 127.4) (:hand-l :flex 10) (:thigh-r :flex -16) (:thigh-l :flex 22))
  ;; R (1.2 1.35 0.6) e87, L (-0.35 1.2 0.9) e137
  (14 (:root :f 0.35 :u -0.16 :yaw -14 :pitch 8) (:spine :flex 44) (:chest :twist -24) (:neck :flex 24)
   (:head :flex 6) (:arm-r :flex 8.6 :side 94.6) (:elbow-r :flex 87.3) (:hand-r :flex -20)
   (:arm-l :flex 104.9 :side -102.6) (:elbow-l :flex 136.9) (:hand-l :flex 10) (:thigh-r :flex 6) (:thigh-l :flex -24))
  ;; R (0.55 1.2 2.24) e4, L (-0.45 1.2 1.1) e140 MISS 0.04
  (:s :snap (:root :f 0.75 :u -0.14 :yaw 4 :pitch 8) (:spine :flex 46) (:chest :twist 10) (:neck :flex 34)
   (:head :flex 12) (:arm-r :flex 38.9 :side 137.4) (:elbow-r :flex 4) (:hand-r :flex 40)
   (:arm-l :flex 54.4 :side -139.5) (:elbow-l :flex 139.6) (:hand-l :flex 10) (:thigh-r :flex 30) (:thigh-l :flex -26))
  ;; R (-0.45 1.1 2.22) e40, L (-0.6 1.25 0.9) e141
  (:a (:root :f 0.8 :u -0.14 :yaw 14 :pitch 8) (:spine :flex 46) (:chest :twist 24) (:neck :flex 34) (:head :flex 12)
   (:arm-r :flex 33.1 :side 155.2) (:elbow-r :flex 39.6) (:hand-r :flex 50) (:arm-l :flex 64.5 :side -168.9)
   (:elbow-l :flex 141.1) (:hand-l :flex 10) (:thigh-r :flex 30) (:thigh-l :flex -26))
  ;; R (-1.15 0.95 1.2) e42 MISS 0.04, L (-0.5 1.3 0.5) e138
  (30 (:root :f 0.6 :u -0.1 :yaw 22 :pitch 6) (:spine :flex 40) (:chest :twist 32) (:neck :flex 28) (:head :flex 8)
   (:arm-r :flex 81 :side 100) (:elbow-r :flex 41.8) (:hand-r :flex 40) (:arm-l :flex 87.9 :side -184.4)
   (:elbow-l :flex 137.5) (:hand-l :flex 10) (:thigh-r :flex 22) (:thigh-l :flex -18))
  (:end :lb-o-stance))
(defstrike :lb-o-f2 (20 4 24 :base :lb-o-stance)   ; K2 回爪 (entered at f6): a half turn to the left, unwound, the left claw lashed back the other way (left -> right)
  (0)
  (6 (:root :f 0 :u -0.02 :yaw 0 :pitch 0) (:spine :flex 22) (:chest :twist 0) (:neck :flex 26) (:head :flex 8)
   (:arm-r :flex 58 :twist 0 :side 14) (:elbow-r :flex 70) (:hand-r :flex 0) (:arm-l :flex 58 :twist 0 :side 14)
   (:elbow-l :flex 70) (:hand-l :flex 0) (:thigh-r :flex 0) (:thigh-l :flex 0))
  ;; R (-0.66 1.36 -0.14) e94, L (-0.42 1.27 0.58) e108
  (9 (:root :f 0.1 :u -0.08 :yaw 40 :pitch 4) (:spine :flex 30) (:chest :twist 26) (:neck :flex 20) (:head :flex 0)
   (:arm-r :flex -11.1 :twist 0 :side -65.1) (:elbow-r :flex 93.9) (:hand-r :flex 10)
   (:arm-l :flex 86.5 :twist 0 :side 102) (:elbow-l :flex 108.5) (:hand-l :flex -20) (:thigh-r :flex 14)
   (:thigh-l :flex -12))
  ;; R (-0.02 1.48 -0.63) e94, L (-0.62 1.22 0.02) e109
  (14 (:root :f 0 :u -0.12 :yaw 95 :pitch 6) (:spine :flex 34) (:chest :twist 30) (:neck :flex 14) (:head :flex -6)
   (:arm-r :flex -23 :twist 0 :side -72.6) (:elbow-r :flex 93.5) (:hand-r :flex 10)
   (:arm-l :flex 91.8 :twist 0 :side 99.1) (:elbow-l :flex 108.8) (:hand-l :flex -40) (:thigh-r :flex 20)
   (:thigh-l :flex -16))
  ;; R (0.2 1.3 0.6) e134 MISS 0.04, L (-1.4 1.4 1.2) e34
  (18 (:root :f 0.4 :u -0.1 :yaw 30 :pitch 6) (:spine :flex 40) (:chest :twist 10) (:neck :flex 24) (:head :flex 4)
   (:arm-r :flex -59.4 :twist 0 :side 27.7) (:elbow-r :flex 134.2) (:hand-r :flex 10)
   (:arm-l :flex 41.8 :twist 0 :side 158.2) (:elbow-l :flex 34.2) (:hand-l :flex -20) (:thigh-r :flex -10)
   (:thigh-l :flex 10))
  ;; R (0.45 1.25 1) e139, L (-0.5 1.25 2.24) e4
  (:s :snap (:root :f 0.75 :u -0.1 :yaw -2 :pitch 8) (:spine :flex 44) (:chest :twist -10) (:neck :flex 34)
   (:head :flex 12) (:arm-r :flex -14.1 :twist 0 :side 29.5) (:elbow-r :flex 139.1) (:hand-r :flex 10)
   (:arm-l :flex 43.8 :twist 0 :side 143.4) (:elbow-l :flex 4) (:hand-l :flex 40) (:thigh-r :flex -24)
   (:thigh-l :flex 30))
  ;; R (0.6 1.25 0.9) e137, L (0.45 1.15 2.22) e38
  (:a (:root :f 0.8 :u -0.1 :yaw -14 :pitch 8) (:spine :flex 44) (:chest :twist -24) (:neck :flex 34)
   (:head :flex 12) (:arm-r :flex -8.8 :twist 0 :side 5.8) (:elbow-r :flex 136.7) (:hand-r :flex 10)
   (:arm-l :flex 35.4 :twist 0 :side 153.5) (:elbow-l :flex 38.1) (:hand-l :flex 50) (:thigh-r :flex -24)
   (:thigh-l :flex 30))
  ;; R (0.5 1.3 0.5) e136, L (1.15 0.95 1.2) e37 MISS 0.04
  (33 (:root :f 0.6 :u -0.08 :yaw -22 :pitch 6) (:spine :flex 40) (:chest :twist -30) (:neck :flex 28)
   (:head :flex 8) (:arm-r :flex -29.9 :twist 0 :side -4.5) (:elbow-r :flex 136.1) (:hand-r :flex 10)
   (:arm-l :flex 84.8 :twist 0 :side 100.2) (:elbow-l :flex 36.9) (:hand-l :flex 40) (:thigh-r :flex -18)
   (:thigh-l :flex 22))
  (:end :lb-o-stance))
(defstrike :lb-o-f3 (21 5 34 :base :lb-o-stance)   ; K3 俯衝 (entered at f7): crouched, a leap with the claws and wings raised high, a stoop, both claws down, landed crouched
  (0)
  (7 (:root :f 0 :u -0.02 :pitch 0) (:spine :flex 22) (:neck :flex 26) (:head :flex 8) (:arm-r :flex 58 :side 14)
   (:elbow-r :flex 70) (:hand-r :flex 0) (:arm-l :flex 58 :side 14) (:elbow-l :flex 70) (:hand-l :flex 0)
   (:thigh-r :flex 0 :side 5) (:thigh-l :flex 0 :side 5))
  ;; R (0.45 1 -0.35) e92, L (-0.45 1 -0.35) e92
  (11 (:root :f 0 :u -0.18 :pitch 10) (:spine :flex 34) (:neck :flex 14) (:head :flex 4)
   (:arm-r :flex -44.5 :side 15.3) (:elbow-r :flex 92.2) (:hand-r :flex -20) (:arm-l :flex -44.5 :side 15.3)
   (:elbow-l :flex 92.2) (:hand-l :flex -20) (:thigh-r :flex 26 :side 5) (:thigh-l :flex 22 :side 5))
  ;; R (0.55 2.95 0.1) e104 MISS 0.03, L (-0.55 2.95 0.1) e104 MISS 0.03
  (16 (:root :f 0.3 :u 0.42 :pitch -8) (:spine :flex 4) (:neck :flex 0) (:head :flex -16)
   (:arm-r :flex -56.8 :side 152) (:elbow-r :flex 104.4) (:hand-r :flex -40) (:arm-l :flex -56.8 :side 152)
   (:elbow-l :flex 104.4) (:hand-l :flex -40) (:thigh-r :flex 40 :side 5) (:thigh-l :flex 34 :side 5))
  ;; R (0.35 2.45 1.6) e102, L (-0.35 2.45 1.6) e102
  (18.5 (:root :f 0.6 :u 0.45 :pitch 12) (:spine :flex 30) (:neck :flex 30) (:head :flex 10)
   (:arm-r :flex -18.2 :side 168.7) (:elbow-r :flex 102) (:hand-r :flex -10) (:arm-l :flex -18.2 :side 168.7)
   (:elbow-l :flex 102) (:hand-l :flex -10) (:thigh-r :flex 30 :side 5) (:thigh-l :flex 24 :side 5))
  ;; R (0.24 1.1 2.29) e4 MISS 0.09, L (-0.24 1.15 2.29) e4 MISS 0.06
  (:s :snap (:root :f 0.85 :u 0.2 :pitch 16) (:spine :flex 46) (:neck :flex 44) (:head :flex 16)
   (:arm-r :flex 60.3 :side 177.9) (:elbow-r :flex 4) (:hand-r :flex 40) (:arm-l :flex 58.5 :side 178)
   (:elbow-l :flex 4) (:hand-l :flex 40) (:thigh-r :flex 16 :side 5) (:thigh-l :flex 8 :side 5))
  ;; R (0.3 0.8 2.2) e4, L (-0.3 0.85 2.2) e19
  (:a (:root :f 0.9 :u 0 :pitch 16) (:spine :flex 50) (:neck :flex 44) (:head :flex 18)
   (:arm-r :flex 63.3 :side 171.6) (:elbow-r :flex 4) (:hand-r :flex 50) (:arm-l :flex 54.4 :side 171.9)
   (:elbow-l :flex 19.3) (:hand-l :flex 50) (:thigh-r :flex 14 :side 5) (:thigh-l :flex 6 :side 5))
  ;; R (0.6 0.45 1.6) e21 MISS 0.03, L (-0.6 0.45 1.6) e21 MISS 0.03
  (31 (:root :f 0.75 :u -0.2 :pitch 12) (:spine :flex 44) (:neck :flex 30) (:head :flex 8)
   (:arm-r :flex 99 :side 245.2) (:elbow-r :flex 20.8) (:hand-r :flex 30) (:arm-l :flex 99 :side 245.2)
   (:elbow-l :flex 20.8) (:hand-l :flex 30) (:thigh-r :flex 30 :side 16) (:thigh-l :flex -10 :side 16))
  ;; R (0.55 0.8 1.3) e74, L (-0.55 0.8 1.3) e74
  (42 (:root :f 0.55 :u -0.14 :pitch 8) (:spine :flex 36) (:neck :flex 28) (:head :flex 8)
   (:arm-r :flex 79.8 :side 234) (:elbow-r :flex 73.7) (:hand-r :flex 20) (:arm-l :flex 79.8 :side 234)
   (:elbow-l :flex 73.7) (:hand-l :flex 20) (:thigh-r :flex 22 :side 12) (:thigh-l :flex -6 :side 12))
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

;;; ---- the owl on Jilliel's system (decision 36, DUEL_LILLE §23.14): functional clips. 遠 EN (decision 38: 「遠程模式翼張開、
;;; 站直」) floats (the kit's :lift, *LB-OWL-LIFT*) bolt upright, the S-neck raised tall, the long arms hanging open at the
;;; sides, the thighs a little forward and the ㄇ legs folded up under the column (LILLE-DRAW tucks them), the eight wings fanned wide
;;; and forward; 近 KIN is the pitched claw stance above (the wings swept back). MUJITTAI keeps each mode's silhouette: EN's
;;; upright, floating (:lb-oe-fold), KIN's pitched on its legs (:lb-o-fold); the arms crossed low before the column (the
;;; wings curl round it). EN's SP1 裁きの光明: three chops, right, left, both, one a line (f6, f12, f18). TENSHIN: the owl
;;; crouched, the arms swept back, the flash step (in: the wind-up first, the arms raised, 16 f; the cancel enters it at
;;; f14); the form (and its lift) changes inside the dash, so the clip's root height steps by the lift there to hide it.
(defpose :lb-oe-stance (:base :lb-o-stance)
  (:root :u 0.0) (:spine :flex 0) (:neck :flex -6) (:head :flex -4) (:arm-r :flex 10 :side 30) (:elbow-r :flex 8)
  (:arm-l :flex 10 :side 30) (:elbow-l :flex 8) (:thigh-r :flex 12 :side 8) (:thigh-l :flex 12 :side 8))
(defclip :lb-oe-stance (2.6 :loop t :base :lb-oe-stance)
  (0) (1.3 (:root :u 0.06) (:head :flex 0 :twist -8) (:arm-r :side 35) (:arm-l :side 26) (:thighs :flex 8)))
(defpose :lb-o-fold-pose (:base :lb-o-stance)
  (:root :u -0.03) (:spine :flex 26) (:head :flex 14) (:arm-r :flex 34 :side 18 :twist 45) (:elbow-r :flex 118)
  (:arm-l :flex 34 :side 18 :twist -45) (:elbow-l :flex 118))
(defclip :lb-o-fold (2.0 :loop t :base :lb-o-fold-pose) (0) (1.0 (:root :u -0.06)))
(defpose :lb-oe-fold-pose (:base :lb-oe-stance)
  (:root :u 0.0) (:head :flex 6) (:arm-r :flex 34 :side 18 :twist 45) (:elbow-r :flex 118)
  (:arm-l :flex 34 :side 18 :twist -45) (:elbow-l :flex 118))
(defclip :lb-oe-fold (2.0 :loop t :base :lb-oe-fold-pose) (0) (1.0 (:root :u 0.05)))
;; Decision 56: the owl EN's own six casts at EN's frames (KIN's claw clips at :clip-s / S before): upright and afloat, the
;; claws thrown down onto the ground line, the striking claw's tip at the move's :reach on S (the frame the line is laid;
;; the host's cast check). Solved as KIN's above.
(defstrike :lb-oe-q1 (4 3 5 :base :lb-oe-stance)   ; EN J1: upright, the right claw raised high, thrown down onto the line (the cast)
  (0)
  ;; R (0.45 2.65 0.15) e97, L (-0.45 1.3 0.3) e108
  (2 (:root :f 0 :u 0.06 :pitch -5) (:spine :flex -6) (:chest :twist -14) (:neck :flex -10) (:head :flex -8)
   (:arm-r :flex 100.3 :side -9.8) (:elbow-r :flex 96.6) (:hand-r :flex -30) (:arm-l :flex -38.4 :side 22.7)
   (:elbow-l :flex 108.3) (:hand-l :flex 0))
  ;; R (0.5 2.75 0.05) e85, L (-0.45 1.3 0.25) e109
  (3 (:root :f 0 :u 0.07 :pitch -6) (:spine :flex -8) (:chest :twist -18) (:neck :flex -12) (:head :flex -10)
   (:arm-r :flex 108.8 :side -10.9) (:elbow-r :flex 85) (:hand-r :flex -40) (:arm-l :flex -47.1 :side 21.4)
   (:elbow-l :flex 109) (:hand-l :flex 0))
  ;; R (0.15 1.35 1.69) e28, L (-0.5 1.3 0.2) e122
  (:s :snap (:root :f 0.28 :u -0.04 :pitch 8) (:spine :flex 28) (:chest :twist 10) (:neck :flex 20) (:head :flex 10)
   (:arm-r :flex 96.1 :side -19.1) (:elbow-r :flex 28) (:hand-r :flex 40) (:arm-l :flex -45.9 :side 26.5)
   (:elbow-l :flex 122) (:hand-l :flex 0))
  ;; R (0.05 0.95 1.5) e31 MISS 0.06, L (-0.5 1.25 0.2) e118
  (:a (:root :f 0.28 :u -0.05 :pitch 9) (:spine :flex 30) (:chest :twist 14) (:neck :flex 24) (:head :flex 12)
   (:arm-r :flex 80.9 :side -58.1) (:elbow-r :flex 31.4) (:hand-r :flex 50) (:arm-l :flex -39 :side 24)
   (:elbow-l :flex 118.3) (:hand-l :flex 0))
  ;; R (0.1 0.95 1.15) e31, L (-0.45 1.3 0.25) e126
  (10 (:root :f 0.15 :u -0.02 :pitch 5) (:spine :flex 14) (:chest :twist 8) (:neck :flex 8) (:head :flex 4)
   (:arm-r :flex 49.5 :side 1.5) (:elbow-r :flex 30.7) (:hand-r :flex 30) (:arm-l :flex -36.1 :side 22.6)
   (:elbow-l :flex 125.8) (:hand-l :flex 0))
  (:end :lb-oe-stance))
(defstrike :lb-oe-q2 (4 3 5 :base :lb-oe-stance)   ; EN J2: the mirror, the left claw
  (0)
  ;; L (-0.45 2.65 0.15) e97, R (0.45 1.3 0.3) e108
  (2 (:root :f 0 :u 0.06 :pitch -5) (:spine :flex -6) (:chest :twist 14) (:neck :flex -10) (:head :flex -8)
   (:arm-r :flex -38.4 :side 22.7) (:elbow-r :flex 108.3) (:hand-r :flex 0) (:arm-l :flex 100.3 :side -9.8)
   (:elbow-l :flex 96.6) (:hand-l :flex -30))
  ;; L (-0.5 2.75 0.05) e85, R (0.45 1.3 0.25) e109
  (3 (:root :f 0 :u 0.07 :pitch -6) (:spine :flex -8) (:chest :twist 18) (:neck :flex -12) (:head :flex -10)
   (:arm-r :flex -47.1 :side 21.4) (:elbow-r :flex 109) (:hand-r :flex 0) (:arm-l :flex 108.8 :side -10.9)
   (:elbow-l :flex 85) (:hand-l :flex -40))
  ;; L (-0.15 1.35 1.69) e28, R (0.5 1.3 0.2) e122
  (:s :snap (:root :f 0.28 :u -0.04 :pitch 8) (:spine :flex 28) (:chest :twist -10) (:neck :flex 20) (:head :flex 10)
   (:arm-r :flex -45.9 :side 26.5) (:elbow-r :flex 122) (:hand-r :flex 0) (:arm-l :flex 96.1 :side -19.1)
   (:elbow-l :flex 28) (:hand-l :flex 40))
  ;; L (-0.05 0.95 1.5) e31 MISS 0.06, R (0.5 1.25 0.2) e118
  (:a (:root :f 0.28 :u -0.05 :pitch 9) (:spine :flex 30) (:chest :twist -14) (:neck :flex 24) (:head :flex 12)
   (:arm-r :flex -39 :side 24) (:elbow-r :flex 118.3) (:hand-r :flex 0) (:arm-l :flex 80.9 :side -58.1)
   (:elbow-l :flex 31.4) (:hand-l :flex 50))
  ;; L (-0.1 0.95 1.15) e31, R (0.45 1.3 0.25) e126
  (10 (:root :f 0.15 :u -0.02 :pitch 5) (:spine :flex 14) (:chest :twist -8) (:neck :flex 8) (:head :flex 4)
   (:arm-r :flex -36.1 :side 22.6) (:elbow-r :flex 125.8) (:hand-r :flex 0) (:arm-l :flex 49.5 :side 1.5)
   (:elbow-l :flex 30.7) (:hand-l :flex 30))
  (:end :lb-oe-stance))
(defstrike :lb-oe-q3 (5 3 8 :base :lb-oe-stance)   ; EN J3: both claws raised overhead, crossed down onto the line with a peck
  (0)
  ;; R (0.6 2.6 0.2) e97, L (-0.6 2.6 0.2) e97
  (3 (:root :f 0 :u 0.08 :pitch -6) (:spine :flex -8) (:neck :flex -10) (:head :flex -12)
   (:arm-r :flex 100.6 :side -31.8) (:elbow-r :flex 97.3) (:hand-r :flex -30) (:arm-l :flex 100.6 :side -31.8)
   (:elbow-l :flex 97.3) (:hand-l :flex -30))
  ;; R (0.62 2.72 0.1) e87, L (-0.62 2.72 0.1) e87
  (4 (:root :f 0 :u 0.09 :pitch -7) (:spine :flex -10) (:neck :flex -12) (:head :flex -14)
   (:arm-r :flex 110.7 :side -30) (:elbow-r :flex 86.8) (:hand-r :flex -40) (:arm-l :flex 110.7 :side -30)
   (:elbow-l :flex 86.8) (:hand-l :flex -40))
  ;; R (-0.08 1.35 1.69) e9, L (0.12 1.42 1.68) e22
  (:s :snap (:root :f 0.3 :u -0.04 :pitch 9) (:spine :flex 30) (:neck :flex 40) (:head :flex 20)
   (:arm-r :flex 110.2 :side 32.9) (:elbow-r :flex 9.4) (:hand-r :flex 40) (:arm-l :flex 107.9 :side 33.8)
   (:elbow-l :flex 21.9) (:hand-l :flex 40))
  ;; R (-0.3 0.95 1.45) e4 MISS 0.04, L (0.3 1 1.45) e4
  (:a (:root :f 0.3 :u -0.05 :pitch 10) (:spine :flex 32) (:neck :flex 46) (:head :flex 24)
   (:arm-r :flex 112 :side 84.4) (:elbow-r :flex 4) (:hand-r :flex 50) (:arm-l :flex 112.8 :side 80.6)
   (:elbow-l :flex 4) (:hand-l :flex 50))
  ;; R (-0.3 1 1.1) e11, L (0.3 1.05 1.1) e28
  (12 (:root :f 0.15 :u -0.03 :pitch 6) (:spine :flex 16) (:neck :flex 20) (:head :flex 8)
   (:arm-r :flex 117.8 :side 129.2) (:elbow-r :flex 10.8) (:hand-r :flex 30) (:arm-l :flex 109.2 :side 125.9)
   (:elbow-l :flex 27.9) (:hand-l :flex 30))
  (:end :lb-oe-stance))
(defstrike :lb-oe-f1 (9 4 9 :base :lb-oe-stance)   ; EN K1: coiled and risen, the glide, the right claw raked low across the fan of three
  (0)
  ;; R (0.85 2.2 -0.4) e104, L (-0.4 1.4 0.5) e110
  (3 (:root :f 0 :u 0.08 :yaw -14 :pitch -4) (:spine :flex -4) (:chest :twist -20) (:neck :flex -10) (:head :flex -8)
   (:arm-r :flex -30.1 :side 111.3) (:elbow-r :flex 104.5) (:hand-r :flex -30) (:arm-l :flex -36.2 :side 33.1)
   (:elbow-l :flex 109.9) (:hand-l :flex 0))
  ;; R (1.05 2 -0.3) e84, L (-0.4 1.4 0.5) e107
  (6 (:root :f 0 :u 0.12 :yaw -22 :pitch -5) (:spine :flex -6) (:chest :twist -26) (:neck :flex -12)
   (:head :flex -10) (:arm-r :flex 4.5 :side 90) (:elbow-r :flex 83.8) (:hand-r :flex -40)
   (:arm-l :flex -49.1 :side 32.5) (:elbow-l :flex 106.9) (:hand-l :flex 0))
  ;; R (0.7 1.25 2.2) e4, L (-0.45 1.3 0.9) e129
  (:s :snap (:root :f 0.85 :u -0.02 :yaw 0 :pitch 14) (:spine :flex 30) (:chest :twist 6) (:neck :flex 26)
   (:head :flex 12) (:arm-r :flex 53 :side 123.7) (:elbow-r :flex 4) (:hand-r :flex 40) (:arm-l :flex -38.3 :side 25)
   (:elbow-l :flex 129) (:hand-l :flex 0))
  ;; R (-0.7 1.15 2.18) e4, L (-0.55 1.3 0.8) e131
  (:a (:root :f 0.85 :u -0.03 :yaw 14 :pitch 14) (:spine :flex 30) (:chest :twist 22) (:neck :flex 26)
   (:head :flex 12) (:arm-r :flex 69.1 :side 163.3) (:elbow-r :flex 4) (:hand-r :flex 50)
   (:arm-l :flex -29.5 :side 6.3) (:elbow-l :flex 131.3) (:hand-l :flex 0))
  ;; R (-0.9 1.05 1.25) e4 MISS 0.11, L (-0.5 1.3 0.4) e127
  (18 (:root :f 0.4 :u -0.02 :yaw 12 :pitch 8) (:spine :flex 16) (:chest :twist 16) (:neck :flex 12) (:head :flex 4)
   (:arm-r :flex 114.9 :side 124.5) (:elbow-r :flex 4) (:hand-r :flex 30) (:arm-l :flex -30.6 :side 14.6)
   (:elbow-l :flex 127) (:hand-l :flex 0))
  (:end :lb-oe-stance))
(defstrike :lb-oe-f2 (10 4 11 :base :lb-oe-stance)   ; EN K2 (entered at f3): the mirror, the left claw raked back across
  (0)
  (3 (:root :f 0 :u 0 :yaw 0 :pitch 0) (:spine :flex 0) (:chest :twist 0) (:neck :flex -6) (:head :flex -4)
   (:arm-r :flex 10 :side 30) (:elbow-r :flex 8) (:hand-r :flex 0) (:arm-l :flex 10 :side 30) (:elbow-l :flex 8)
   (:hand-l :flex 0))
  ;; L (-0.85 2.2 -0.4) e104, R (0.4 1.4 0.5) e110
  (5 (:root :f 0 :u 0.08 :yaw 14 :pitch -4) (:spine :flex -4) (:chest :twist 20) (:neck :flex -10) (:head :flex -8)
   (:arm-r :flex -36.2 :side 33.1) (:elbow-r :flex 109.9) (:hand-r :flex 0) (:arm-l :flex -30.1 :side 111.3)
   (:elbow-l :flex 104.5) (:hand-l :flex -30))
  ;; L (-1.05 2 -0.3) e84, R (0.4 1.4 0.5) e107
  (7.5 (:root :f 0 :u 0.12 :yaw 22 :pitch -5) (:spine :flex -6) (:chest :twist 26) (:neck :flex -12)
   (:head :flex -10) (:arm-r :flex -49.1 :side 32.5) (:elbow-r :flex 106.9) (:hand-r :flex 0)
   (:arm-l :flex 4.5 :side 90) (:elbow-l :flex 83.8) (:hand-l :flex -40))
  ;; L (-0.7 1.25 2.2) e4, R (0.45 1.3 0.9) e129
  (:s :snap (:root :f 0.85 :u -0.02 :yaw 0 :pitch 14) (:spine :flex 30) (:chest :twist -6) (:neck :flex 26)
   (:head :flex 12) (:arm-r :flex -38.3 :side 25) (:elbow-r :flex 129) (:hand-r :flex 0) (:arm-l :flex 53 :side 123.7)
   (:elbow-l :flex 4) (:hand-l :flex 40))
  ;; L (0.7 1.15 2.18) e4, R (0.55 1.3 0.8) e131
  (:a (:root :f 0.85 :u -0.03 :yaw -14 :pitch 14) (:spine :flex 30) (:chest :twist -22) (:neck :flex 26)
   (:head :flex 12) (:arm-r :flex -29.5 :side 6.3) (:elbow-r :flex 131.3) (:hand-r :flex 0)
   (:arm-l :flex 69.1 :side 163.3) (:elbow-l :flex 4) (:hand-l :flex 50))
  ;; L (0.9 1.05 1.25) e4 MISS 0.11, R (0.5 1.3 0.4) e127
  (20 (:root :f 0.4 :u -0.02 :yaw -12 :pitch 8) (:spine :flex 16) (:chest :twist -16) (:neck :flex 12)
   (:head :flex 4) (:arm-r :flex -30.6 :side 14.6) (:elbow-r :flex 127) (:hand-r :flex 0)
   (:arm-l :flex 114.9 :side 124.5) (:elbow-l :flex 4) (:hand-l :flex 30))
  (:end :lb-oe-stance))
(defstrike :lb-oe-f3 (11 5 16 :base :lb-oe-stance)   ; EN K3 (entered at f4): rising, both claws and the wings raised high, both thrown down onto the line
  (0)
  (4 (:root :f 0 :u 0 :pitch 0) (:spine :flex 0) (:neck :flex -6) (:head :flex -4) (:arm-r :flex 10 :side 30)
   (:elbow-r :flex 8) (:hand-r :flex 0) (:arm-l :flex 10 :side 30) (:elbow-l :flex 8) (:hand-l :flex 0))
  ;; R (0.55 2.7 0.2) e100, L (-0.55 2.7 0.2) e100
  (7 (:root :f 0 :u 0.18 :pitch -6) (:spine :flex -8) (:neck :flex -12) (:head :flex -12)
   (:arm-r :flex 98.4 :side -28.2) (:elbow-r :flex 99.9) (:hand-r :flex -30) (:arm-l :flex 98.4 :side -28.2)
   (:elbow-l :flex 99.9) (:hand-l :flex -30))
  ;; R (0.5 2.98 0.3) e85, L (-0.5 2.98 0.3) e85
  (9.5 (:root :f 0.1 :u 0.32 :pitch -8) (:spine :flex -10) (:neck :flex -14) (:head :flex -14)
   (:arm-r :flex 103.1 :side -22.4) (:elbow-r :flex 84.7) (:hand-r :flex -40) (:arm-l :flex 103.1 :side -22.4)
   (:elbow-l :flex 84.7) (:hand-l :flex -40))
  ;; R (0.2 1.3 2.29) e28, L (-0.2 1.35 2.29) e33
  (:s :snap (:root :f 0.85 :u 0 :pitch 16) (:spine :flex 34) (:neck :flex 36) (:head :flex 16)
   (:arm-r :flex 106.6 :side 1.3) (:elbow-r :flex 27.5) (:hand-r :flex 40) (:arm-l :flex 106.2 :side 1.2)
   (:elbow-l :flex 33.2) (:hand-l :flex 40))
  ;; R (0.25 0.85 2.15) e37, L (-0.25 0.9 2.15) e45
  (:a (:root :f 0.88 :u -0.15 :pitch 16) (:spine :flex 38) (:neck :flex 40) (:head :flex 18)
   (:arm-r :flex 90.2 :side -4.3) (:elbow-r :flex 37.4) (:hand-r :flex 50) (:arm-l :flex 88.6 :side -4.1)
   (:elbow-l :flex 45) (:hand-l :flex 50))
  ;; R (0.4 0.9 1.1) e69, L (-0.4 0.95 1.1) e75
  (24 (:root :f 0.35 :u -0.08 :pitch 8) (:spine :flex 18) (:neck :flex 16) (:head :flex 6)
   (:arm-r :flex 27.5 :side 19) (:elbow-r :flex 68.8) (:hand-r :flex 30) (:arm-l :flex 26 :side 20.6)
   (:elbow-l :flex 75.1) (:hand-l :flex 30))
  (:end :lb-oe-stance))
(defstrike :lb-oe-sabaki (6 14 11 :base :lb-oe-stance)
  (0) (4 (:arm-r :flex 170 :side 6) (:elbow-r :flex 4) (:head :flex -10))
  (:s :snap (:arm-r :flex 60 :side 4) (:spine :flex 16) (:root :f 0.06))
  (10 (:arm-r :flex 40 :side 10) (:arm-l :flex 170 :side 6) (:elbow-l :flex 4) (:head :flex -10))
  (12 :snap (:arm-r :flex 40 :side 10) (:arm-l :flex 60 :side 4) (:spine :flex 16) (:root :f 0.06))
  (16 (:arm-r :flex 172 :side 8) (:arm-l :flex 172 :side 8) (:elbow-r :flex 4) (:elbow-l :flex 4) (:head :flex -12))
  (18 :snap (:arm-r :flex 62 :side 6) (:arm-l :flex 62 :side 6) (:spine :flex 22) (:root :f 0.12))
  (:a (:arm-r :flex 44) (:arm-l :flex 44) (:spine :flex 14))
  (:end :lb-oe-stance))
;; KIN -> EN (the form, lift 0 -> *LB-OWL-LIFT* 0.35, at f6: LB-SWITCH-FORM): the fold, the leap up and back (the root
;; rising 0.4 m to f6, then the same height in EN's lift: u 0.4 -> 0.05 across f6-6.5, a step the draw never sees: it draws
;; f6 before the form and f7 after), the legs folding up and the wings fanning out (LILLE-DRAW's ramps), EN's stance. (The
;; 0.35 steps here and in TENSHIN in are *LB-OWL-LIFT*: change them with it.)
(defstrike :lb-o-tenshin (14 0 8 :base :lb-o-stance)
  (0 :lb-o-fold-pose) (6 (:root :u 0.4 :pitch -6) (:spine :flex 6) (:arm-r :flex -40 :side 40) (:arm-l :flex -40 :side 40))
  (6.5 :snap (:root :u 0.05 :pitch -6) (:spine :flex 6) (:arm-r :flex -40 :side 40) (:arm-l :flex -40 :side 40))
  (14 :lb-oe-stance) (:end :lb-oe-stance))
;; EN -> KIN (the form at f22, lift *LB-OWL-LIFT* 0.35 -> 0): the arms raised (the wind-up), the fold, the dash diving down
;; to the floor (u -0.25 in EN's lift at f22 = 0.1 in KIN's at f22.5), the legs unfolding and the wings sweeping back, KIN
(defstrike :lb-o-tenshin-in (30 0 8 :base :lb-oe-stance)
  (0) (14 (:root :u 0.06 :pitch -6) (:head :flex -10) (:arm-r :flex -24 :side 64) (:arm-l :flex -24 :side 64))
  (16 :snap :lb-oe-fold-pose)
  (22 (:root :u -0.25 :pitch 12) (:spine :flex 26) (:arm-r :flex -40 :side 30) (:arm-l :flex -40 :side 30))
  (22.5 :snap (:root :u 0.1 :pitch 12) (:spine :flex 26) (:arm-r :flex -40 :side 30) (:arm-l :flex -40 :side 30))
  (30 :lb-o-stance) (:end :lb-o-stance))

;;; ---------------------------------------------------------------- the cinematics' clips (§10)
(defclip :lb-rise (1.0 :base :lb-w-fold-pose)          ; the revival: the headless column rising into the air
  (0 (:root :u 0.5)) (1.0 (:root :u 1.5) (:arm-r :side 50) (:arm-l :side 50)))
(defpose :lb-o-point (:base :lb-oe-stance)             ; the owl (EN, the revival's form), one long arm raised high, the
  (:arm-r :flex 172 :side 8) (:elbow-r :flex 4) (:head :flex -6) (:spine :flex -4))   ; finger up (ch. 652)
(defclip :lb-o-reveal (2.0 :base :lb-oe-stance)
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
(%LB-LOAD-PLACE!); [28] the wings' spread 0..1; [8] the owl EN's leg tuck 0..1 and [29] the owl KIN's wing sweep 0..1
(decision 38); [31] his drawn scale (a cinematic's giant, CINE-SCALE: decision 56).")
(defvar *lb-fx* (make-f32 (* 2 24))
  "Per side (24 each), the looks' memory: [0] the eye's tick seen, [1] its fx clock, [2] the guard gauge seen, [3] the
last pass-through (fx clock), [4] the fold 0..1, [5] sealed seen (1), [6] the seal's fx clock, [7..9] the reticle's point,
[10] the reticle shown (1 tracking, 2 locked), [11] the distance there, [12 13] the reflector's x z, [14] the eye's tick
whose third-opening line was shown, [15] 1 while he is the owl (his hazards' gold), [16] the wings' spread 0..1 (an SP
fans them out), [17] its joints' unfurl 0..1 (slower: they furl, then open from the root), [18] the owl's EN spread 0..1
(decision 36: EN fans the wings out, KIN sweeps them back; decision 38: also EN's legs folded up, 5 / s).")
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
  "A flat line on the floor from (X0 Z0) along the unit (UX UZ), LEN long, W wide: KIND 0 grey, 1 jade, 2 ink, 3 the owl's
gold (its numbers
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
    (case kind (0 (draw-weapon :lb-line-grey m)) (1 (draw-weapon :lb-line-jade m)) (3 (draw-weapon :lb-line-gold m))
          (t (draw-weapon :lb-line m)))
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
;; Decision 50 (2026-10-07, DUEL_LILLE §23.31; the user: 「Jilliel 近戰的動作不太明顯」, then all four directions for both modes,
;; 「全身出招」「每招獨立造型」「翼尖斬痕」「八翼一起斬」「近戰＋遠程都換」): every J / K of KIN (:lb-w-q1 .. :lb-w-f3) and of EN (its own
;; casts :lb-e-q1 .. :lb-e-f3) is its own whole-body strike, the striking tips leave a jade smear, and around the hit the six
;; table wings converge in turn: KIN's round his hit point ahead (a ring at his reach), EN's on the line ahead on the floor (a K's
;; on its fan of three). All of it a look: the move's frame read for the timing only, never sim state.
(defparameter *lb-jilliel-strikes* '(:lb-w-q1 :lb-w-q2 :lb-w-q3 :lb-w-f1 :lb-w-f2 :lb-w-f3 :lb-e-q1 :lb-e-q2 :lb-e-q3
                                     :lb-e-f1 :lb-e-f2 :lb-e-f3)
  "Jilliel's strike clips (decision 50): KIN's six, EN's six casts. Their moves drive the convergence and the trails.")
(defparameter *lb-conv-from* -2.0 "The convergence: the first table wing launches this many frames from the strike's S ...")
(defparameter *lb-conv-step-j* 0.8 "... the next ones in turn this many frames apart (a J; striking side first, top pair down) ...")
(defparameter *lb-conv-step-k* 1.0 "... (a K) ...")
(defparameter *lb-conv-ramp* 2.5 "... each reaching its target over this many frames (smoothstep) ...")
(defparameter *lb-conv-hold* 3.0 "... held this many frames past the active end ...")
(defparameter *lb-conv-out* 0.5 "... then back to the fan over this share of the recovery.")
(defparameter *lb-conv-stretch* 1.3 "A converging wing reaches its target, at most this many times its own length.")
(defparameter *lb-conv-ring* 0.22 "KIN: the six tips meet in a ring this wide (m) round his hit point (his facing x reach - 0.1 m).")
(defparameter *lb-conv-near* 2.2 "EN: the top pair aims this far ahead on the line (m), each pair below *LB-CONV-GAP* further.")
(defparameter *lb-conv-gap* 0.9 "EN: (the pairs' spacing along the line, m).")
(defparameter *lb-jump-jl* 4.0
  "Jilliel's lag spring jump (m^2; the owl's 1): his spins sweep a tip up to ~1.8 m a frame, still a motion to trail.")
(defparameter *lb-trail-from* -5 "The tip trails record from this frame of the strike (from S) ...")
(defparameter *lb-trail-to* 3 "... to its active end + this; else they fade a sample a frame (the smear: %LB-SMEAR).")
;; Decision 56 (2026-10-08, DUEL_LILLE §23.37; the user: 「梟頭模式近戰的動作不太明顯」, then 「猛禽爪擊」 with 「全身出招」
;; 「金色爪痕」「金翼振翅」「八翼匯聚」 and its EN 「另做一套」): the owl's J / K are a raptor's claws (KIN :lb-o-q1 .. :lb-o-f3, EN's
;; own casts :lb-oe-q1 .. :lb-oe-f3); its eight gold wings beat once into each strike (%LB-OWL-BEAT!), then all eight converge
;; in turn on Jilliel's targets (KIN his hit point, EN the line ahead: its arms are the claws, so no wing is a front wing and
;; every one is free), and the striking claws leave three thin gold streaks (%LB-CLAW-TRAILS). All of it a look: the move's
;; frame read for the timing only, never sim state.
(defparameter *lb-owl-strikes* '(:lb-o-q1 :lb-o-q2 :lb-o-q3 :lb-o-f1 :lb-o-f2 :lb-o-f3 :lb-oe-q1 :lb-oe-q2 :lb-oe-q3
                                 :lb-oe-f1 :lb-oe-f2 :lb-oe-f3)
  "The owl's claw strikes (decision 56): KIN's six, EN's six casts. Their moves drive the beat, the convergence and the
claw trails.")
(defparameter *lb-owl-conv-from* -1.0
  "The owl's convergence: its first wing launches this many frames from the strike's S (Jilliel's -2: the beat's down-stroke
reads first) ...")
(defparameter *lb-owl-conv-step-j* 0.5 "... the next ones in turn this many frames apart (a J: eight wings, Jilliel's six 0.8) ...")
(defparameter *lb-owl-conv-step-k* 0.7 "... (a K; Jilliel's 1.0). Its ramp, hold, return, stretch, ring and line are Jilliel's knobs.")
(defparameter *lb-owl-trail-from* -1
  "The claw trails record from this frame of the strike (from S; Jilliel's tips -5): the rake itself, not the wind-up.")
(defparameter *lb-owl-beat-up* 38.0 "The beat (金翼振翅): the eight wings raised this many degrees over the wind-up ...")
(defparameter *lb-owl-beat-down* 30.0
  "... struck down to this many degrees below their place into S, held through the active frames, back over the recovery ...")
(defparameter *lb-owl-beat-stroke* 3 "... the down-stroke over the startup's last this many frames (a K's + 1) ...")
(defparameter *lb-owl-beat-open* 0.45 "... opening KIN's swept-back sheaf this far (0..1) through it ...")
(defparameter *lb-owl-beat-k3* 1.6
  "... K3's (the stoop) raised and pressed down this many times as far, and held flared into the landing.")
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
(defvar *lb-wf* (make-f32 72)
  "The jointed wings' scratch: [0..26] the three segments' unit frames (9 each: X Y Z), [30 31] a tilt's numbers (toward X,
toward Z), [32..35] the chain's turn (axis, angle); per call (LILLE-DRAW's %LB-DRIVE!): [39] the strike's virtual speed
(m/s along his facing), [40] the striking front wings (bit 0 right, bit 1 left), [41] 1 on the active frames (straight),
[42] the spread's unfurl 0..1, [43] the step (s; 0 = no spring step), [44] the strike's share for the other wings, [45] the
lag spring's jump (m^2: a drive point moving further in a frame counts as still; 1 the owl, *LB-JUMP-JL* Jilliel's), and
for a Jilliel strike (decision 50) [46] its clock (frames since S), [47] 1 = the six table wings converge, [48] 1 = EN (on
the line ahead) else KIN (round his hit point ahead), [49] 1 = a K (EN: its fan of three lines), [50] A, [51] R, [52] 1 =
the tip trails record (*LB-TRAIL-FROM* .. A + *LB-TRAIL-TO*), [54] the move's reach; per draw [53] the clip's root turn,
[59 60] its root f / r (LILLE-DRAW), and %LB-WINGS' [55 56] where he stands, [57 58] his facing (the clip's turn out); the
SP / Kikon looks (decision 56, %LB-SP-DRIVE!): [61] the ring 0..1, [62] its cup, [63] its shake, [64] the close, [65] the
wings drawn with their holes lit (bits by row), [66] their muzzle flash 0..1, [67] the holes glowing (the first N, the
Kikon cinematic's card); for the owl's claws (decision 56, %LB-OWL-BEAT!) [68] the wing beat's elevation (degrees), [69] its
opening of KIN's swept sheaf 0..1, [70] 1 = an owl strike (all eight wings converge, four pairs).")
(declaim (type f32vec *lb-holes* *lb-judge-pierce*))
;; Decision 56's Kikon cinematic (LB-JILLIEL-KIKON-CINE; the storyboard, DUEL_LILLE §23.37): 48 jade lines out of the 24
;; holes (each twice), the first three spaced, then faster and faster; each pierces the opponent and leaves a white hole in
;; him (on the white card, his black silhouette) until the verdict shatters him (VFX-LB-JUDGE). All read from the
;; cinematic's frame, no memory: a skipped or aborted cinematic leaves nothing.
(defparameter *lb-judge-shots*
  (let ((v (make-array 48 :element-type 'fixnum)))
    (dotimes (n 48 v)
      (setf (aref v n) (case n (0 96) (1 143) (2 174) (t (+ 192 (round (* 46 (sqrt (/ (- n 3) 44.0))))))))))
  "The cinematic frame pierce N is fired on (its line flies *LB-JUDGE-FLY* frames of the cinematic's effect time to the
hit): 96 / 143 / 174 (beat 3, Amendment 2: each hit slowed, *LB-JUDGE-SLOW*), then 192 + 46 sqrt((n - 3) / 44) to 238
(beat 4: 7 f apart at first, several a frame at the end).")
(defparameter *lb-judge-fly* 3.0 "A pierce's line flies this many frames (of the cinematic's effect time) to the hit.")
(defparameter *lb-judge-slow* '((99 139 0.2) (146 171 0.33333334) (177 192 0.5))
  "Amendment 2 (the user 2026-10-08: 「1/5 → 1/3 → 1/2」): the first three hits' slow motion, (from to rate) in cinematic
frames: the actors' clips and the effects at RATE (CINE-SLOW, set by the script on the same frames), and the effect time
the lines and holes run on (*LB-JUDGE-TIME*).")
(declaim (type f32vec *lb-judge-time*))
(defparameter *lb-judge-time*
  (let ((v (make-f32 401)) (tm 0.0))
    (dotimes (c 401 v)
      (setf (aref v c) (f32 tm))
      (incf tm (or (loop for (a b k) in *lb-judge-slow* when (and (<= a c) (< c b)) return k) 1.0))))
  "The Kikon cinematic's effect time at each of its frames (frames at speed 1, slower in *LB-JUDGE-SLOW*): the lines'
flight and fade, the holes' and stars' timing, the ring's kicks. Frames past 400 read 400's.")
(defmacro %lb-judge-t (c) "The effect time at cinematic frame C (a fixnum form)." `(aref *lb-judge-time* (min 400 (max 0 ,c))))
(defparameter *lb-judge-pierce*
  (let ((v (make-f32 (* 48 3))))
    (dotimes (n 48 v)
      (let* ((h1 (let ((x (* 43758.547 (sin (+ (* n 12.9898) 4.1))))) (- x (floor x))))
             (h2 (let ((x (* 43758.547 (sin (+ (* n 78.233) 1.3))))) (- x (floor x))))
             (y (+ 0.3 (* 1.42 h2)))                    ; up his body; the half-width by part: legs, torso, head
             (hw (cond ((< y 0.85) 0.17) ((< y 1.48) 0.24) (t 0.09))))
        (setf (aref v (* 3 n)) (f32 (* hw (- (* 2 h1) 1))) (aref v (+ 1 (* 3 n))) (f32 y)
              (aref v (+ 2 (* 3 n))) (f32 (+ 0.045 (* 0.015 (mod (* 7 n) 3))))))))
  "Pierce N's point on the opponent (3 each: across his body, + = his right (m), up from his feet (m), its hole's radius),
hashed once (a fixed pattern).")
(defmacro %lb-judge-hole (n) "The hole pierce N fires from (each hole twice, scattered round the ring)." `(mod (* 7 ,n) 24))
(defvar *lb-holes* (make-f32 (* 2 24 3))
  "Per side, the 24 holes' world points as last drawn (%LB-WINGS: wing I's hole G at 3 I + G; decision 56): the Kikon
cinematic's muzzles (VFX-LB-JUDGE). Cosmetic memory.")
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

(defmacro %lb-conv-share (i s mask)
  "Decision 50: how far table wing I (side S, the strike's front-wing MASK) has converged, 0..1, from *LB-WF* [46 49 50 51]:
in turn, the striking side first and the top pair down (both sides at once when both front wings strike), each launching
*LB-CONV-STEP-J* / *-K* frames after the last from *LB-CONV-FROM*, in over *LB-CONV-RAMP*, held to the active end +
*LB-CONV-HOLD*, out over *LB-CONV-OUT* of the recovery. Single-float forms; 0 B."
  `(let* ((%w *lb-wf*) (%i ,i) (%s ,s) (%m ,mask) (%q (floor %i 2)) (%ow (> (aref %w 70) 0.5f0))   ; (the owl: four pairs,
          (%p (if (or %ow (/= %q 3)) %q 2))                                                              ;  decision 56)
          (%rank (+ (* 2 %p) (if (or (= %m 3) (if (= %m 1) (> %s 0f0) (< %s 0f0))) 0 1)))
          (%t (aref %w 46))
          (%go (if %ow
                   (+ (the single-float *lb-owl-conv-from*)
                      (* (i->f %rank) (if (> (aref %w 49) 0.5f0) (the single-float *lb-owl-conv-step-k*) (the single-float *lb-owl-conv-step-j*))))
                   (+ (the single-float *lb-conv-from*)
                      (* (i->f %rank) (if (> (aref %w 49) 0.5f0) (the single-float *lb-conv-step-k*) (the single-float *lb-conv-step-j*))))))
          (%in (%lb-ss (/ (- %t %go) (the single-float *lb-conv-ramp*))))
          (%out (%lb-ss (/ (- %t (aref %w 50) (the single-float *lb-conv-hold*))
                           (f-max 1f0 (* (the single-float *lb-conv-out*) (aref %w 51)))))))
     (declare (type f32vec %w) (fixnum %i %m %q %p %rank) (single-float %s %t %go %in %out))
     (* %in (- 1f0 %out))))

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
         (sb (* (aref v 29) (- 1f0 (aref w 69))))        ; (the owl's beat opens KIN's sheaf: decision 56)
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
             (single-float k j rip tm a lk sp sb rx ry rz xx xy xz yx yy yz zx zy zz xl zl fx fy fz sx sy sz yl su vx0 vy0 vz0 vl dvx dvy dvz vb u dt tsc rise c1 c2
                           gl lm wa wc ws wl fc fu))
    (when (> (aref w 47) 0.5f0)                         ; decision 50: where he stands and faces, the clip's root offset and
      (let* ((pfx (- (aref jm 8))) (pfz (- (aref jm 10)))   ; turn taken out (its spins): [55 56] x z, [57 58] the facing
             (pfl (f-max 1f-5 (f-sqrt (+ (* pfx pfx) (* pfz pfz))))) (ux (/ pfx pfl)) (uz (/ pfz pfl))
             (ry (aref w 53)) (cr (f-cos ry)) (sr (f-sin ry)))
        (declare (single-float pfx pfz pfl ux uz ry cr sr))
        (setf (aref w 55) (- (aref jm 12) (* (aref w 59) ux) (* (aref w 60) (- uz)))
              (aref w 56) (- (aref jm 14) (* (aref w 59) uz) (* (aref w 60) ux))
              (aref w 57) (- (* ux cr) (* uz sr)) (aref w 58) (+ (* ux sr) (* uz cr)))))
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
              ;; (the sweep SB, the owl's KIN, decision 38: the fan closed up into a narrow sheaf lowered along his back,
              ;; the blades trailing back and down close to his midline (a folded bird's), shorter, their faces turned to
              ;; the side: a narrow sheaf from behind, the long swept blades from the side)
              (let* ((e (* 0.017453292f0 (+ (* (aref tbl (+ r 1)) (+ 1f0 (* 0.22f0 sp)) (- 1f0 (* 0.65f0 sb))) (* -48f0 sb)
                                              (aref w 68)                  ; (the owl's wing beat, decision 56)
                                              (* 3f0 j (f-sin (+ (* 1.9f0 tm) (aref tbl (+ r 9)))))
                                              (* rip (f-sin (+ (* 31f0 tm) (* 1.7f0 (i->f i))))))))
                     (ax (* s (f-cos e) (- 1f0 (* 0.7f0 sb)))) (ay (- (f-sin e) (* 0.9f0 sb)))
                     (az (+ (- (aref tbl (+ r 3)) (* 0.7f0 sp)) (* 1.3f0 sb)))
                     (lx2 (+ (* j ax) (* k s (aref tbl (+ r 4))))) (ly2 (+ (* j ay) (* k (aref tbl (+ r 5)))))
                     (lz2 (+ (* j az) (* k (aref tbl (+ r 6)))))
                     (fl (if (> (aref tbl (+ r 8)) 0.5f0) (- s) s)) (nlx (+ (* k fl) (* j fl 0.85f0 sb))) (nlz (* j fl (- 1f0 (* 0.85f0 sb))))
                     (dx (+ (* xx lx2) (* yx ly2) (* zx lz2))) (dy (+ (* xy lx2) (* yy ly2) (* zy lz2)))
                     (dz (+ (* xz lx2) (* yz ly2) (* zz lz2))) (dl (f-max 1f-5 (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
                     (ln (* lk (aref tbl (+ r 2)) (- 1f0 (* 0.15f0 k)) (- 1f0 (* 0.2f0 sb)))))
                (declare (single-float e ax ay az lx2 ly2 lz2 fl nlx nlz dx dy dz dl ln))
                ;; decision 50: converging in turn (C 0..1), round his hit point (KIN) or on the line ahead (EN): the blade
                ;; turned from its fan place toward its target T, stretched to reach it, its face turned to his side
                (let* ((c (if (> (aref w 47) 0.5f0) (%lb-conv-share i s mask) 0f0)) (c1 (- 1f0 c))
                       (ow (> (aref w 70) 0.5f0))                    ; (the owl's four pairs, decision 56)
                       (pr (let ((q (floor i 2))) (if (or ow (/= q 3)) q 2))) (en (> (aref w 48) 0.5f0))
                       (dist (if en (+ (the single-float *lb-conv-near*) (* (the single-float *lb-conv-gap*) (i->f pr)))
                                 (- (aref w 54) 0.1f0)))                       ; (EN: along the line; KIN: his reach)
                       (lat (if en (* s (if (and (> (aref w 49) 0.5f0) (> pr 0)) (* 0.105f0 dist) 0.08f0)) 0f0))
                       (rg (if en 0f0 (the single-float *lb-conv-ring*)))
                       (qx (* rg s (case pr (0 0.6f0) (1 1f0) (2 (if ow 1f0 0.6f0)) (t 0.6f0))))
                       (qy (* rg (case pr (0 0.8f0) (1 (if ow 0.3f0 0.1f0)) (2 (if ow -0.3f0 -0.8f0)) (t -0.8f0))))
                       (yl1 (/ 1f0 yl))
                       (tx (+ (aref w 55) (* dist (aref w 57)) (* lat (- (aref w 58))) (* qx sx) (* qy yx yl1)))
                       (ty (if en (+ (aref v 3) 0.03f0) (+ (- (aref jm (+ (* 16 (ji :chest)) 13)) 0.12f0) (* qx sy) (* qy yy yl1))))
                       (tz (+ (aref w 56) (* dist (aref w 58)) (* lat (aref w 57)) (* qx sz) (* qy yz yl1)))
                       (gx (- tx ox)) (gy (- ty oy)) (gz (- tz oz)) (gl (f-max 1f-3 (f-sqrt (+ (* gx gx) (* gy gy) (* gz gz)))))
                       (bx (+ (* c1 (/ dx dl)) (* c (/ gx gl)))) (by (+ (* c1 (/ dy dl)) (* c (/ gy gl))))
                       (bz (+ (* c1 (/ dz dl)) (* c (/ gz gl))))
                       (bl (f-max 1f-5 (f-sqrt (+ (* bx bx) (* by by) (* bz bz)))))
                       (l2 (+ (* c1 ln) (* c (f-min gl (* (the single-float *lb-conv-stretch*) ln))))))
                  (declare (single-float c c1 dist lat rg qx qy yl1 tx ty tz gx gy gz gl bx by bz bl l2) (fixnum pr))
                  (cond
                    ((> (aref w 61) 0f0)
                     ;; decision 56: the ring (NIJUSHI-KO, the Kikon): the pair's place round him in the plane facing his
                     ;; opponent (from the top 22.5 / 67.5 / 157.5 degrees off his up, the front pair's 112.5 the clip's), cupped
                     ;; forward or blown back ([62]), shaking ([63]), closed down ([64]: every place swung to 178 degrees, before
                     ;; him); the face to him
                     (let* ((rg (aref w 61)) (rg1 (- 1f0 rg)) (cl (aref w 64))
                            (th0 (case pr (0 0.3926991f0) (1 1.1780972f0) (t 2.7488935f0)))
                            (th (+ th0 (* cl (- 3.1066861f0 th0)) (* (aref w 63) (f-sin (+ (* 37f0 tm) (* 2.3f0 (i->f i)))))))
                            (ca (f-cos th)) (sa (* s (f-sin th))) (cu (+ (aref w 62) (* 0.3f0 cl)))
                            (gx (+ (* ca yx yl1) (* sa sx) (* cu fx))) (gy (+ (* ca yy yl1) (* sa sy) (* cu fy)))
                            (gz (+ (* ca yz yl1) (* sa sz) (* cu fz))) (gl (f-max 1f-5 (f-sqrt (+ (* gx gx) (* gy gy) (* gz gz)))))
                            (bx (+ (* rg1 (/ dx dl)) (* rg (/ gx gl)))) (by (+ (* rg1 (/ dy dl)) (* rg (/ gy gl))))
                            (bz (+ (* rg1 (/ dz dl)) (* rg (/ gz gl))))
                            (bl (f-max 1f-5 (f-sqrt (+ (* bx bx) (* by by) (* bz bz))))))
                       (declare (single-float rg rg1 cl th0 th ca sa cu gx gy gz gl bx by bz bl))
                       (%lb-basis! w 0 (/ bx bl) (/ by bl) (/ bz bl)
                                   (+ (* rg1 (+ (* xx nlx) (* zx nlz))) (* rg fx)) (+ (* rg1 (+ (* xy nlx) (* zy nlz))) (* rg fy))
                                   (+ (* rg1 (+ (* xz nlx) (* zz nlz))) (* rg fz)))))
                    ((> c 0f0)                           ; (the owl's turn their faces up, edge-on from the side: its
                     (let ((ux (if ow (* yx yl1) sx)) (uy (if ow (* yy yl1) sy)) (uz (if ow (* yz yl1) sz)))   ;  claws show)
                       (declare (single-float ux uy uz))
                       (%lb-basis! w 0 (/ bx bl) (/ by bl) (/ bz bl)
                                   (+ (* c1 (+ (* xx nlx) (* zx nlz))) (* c fl ux)) (+ (* c1 (+ (* xy nlx) (* zy nlz))) (* c fl uy))
                                   (+ (* c1 (+ (* xz nlx) (* zz nlz))) (* c fl uz)))))
                    (t (%lb-basis! w 0 (/ dx dl) (/ dy dl) (/ dz dl)
                                   (+ (* xx nlx) (* zx nlz)) (+ (* xy nlx) (* zy nlz)) (+ (* xz nlx) (* zz nlz)))))
                  (let ((lq (cond ((> (aref w 61) 0f0) (* ln (+ 1f0 (* 0.08f0 (aref w 61))))) ((> c 0f0) l2) (t ln))))
                    (declare (single-float lq))
                    (setf len lq wd ln px (+ ox (* lq (aref w 3))) py (+ oy (* lq (aref w 4))) pz (+ oz (* lq (aref w 5))))))))
          ;; 2. the lag spring: its target from the drive point's speed and the strike's virtual speed (a free wing's tip
          ;; trails: bend against the motion; a pinned front wing bends with it, so its middle bows behind)
          (when (> dt 0f0)
            (let* ((qx (- px (aref mm mo))) (qy (- py (aref mm (+ mo 1)))) (qz (- pz (aref mm (+ mo 2))))
                   (iv (if (> (+ (* qx qx) (* qy qy) (* qz qz)) (aref w 45)) 0f0 (/ 1f0 dt)))   ; (a jump: a cut, a reset)
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
          ;; 5. the three segments, each from the last one's end; a wing in [65]'s bits drawn with its holes lit (decision
          ;; 56: SANREN's firing wing, NIJUSHI-KO's and the Kikon's charge) and, while [66] > 0, the muzzle flash at its holes
          (let* ((qx ox) (qy oy) (qz oz) (l3 (* len 0.33333334f0))
                 (lw (and (= kind 0) (logbitp i (f->i (aref w 65))))) (kd (if lw 1 kind)) (mf (if lw (aref w 66) 0f0)))
            (declare (single-float qx qy qz l3 mf) (fixnum kd))
            (dotimes (g 3)
              (let ((b (* 9 g)))
                (declare (fixnum b))
                (%lb-seg-m! *lb-m* w b qx qy qz len wd)
                (%lb-wing-draw kd g ga ra)
                (let* ((ly (* len (case g (0 0.2f0) (1 0.16666667f0) (t 0.12333333f0))))   ; the hole on this segment
                       (lx (* wd (case g (0 0.055f0) (1 0.08f0) (t 0.056f0))))            ;  (*LB-WING-HOLES*: 0.2 / 0.5 /
                       (hx (+ qx (* ly (aref w (+ b 3))) (* lx (aref w b))))              ;  0.79 of the blade, its centre
                       (hy (+ qy (* ly (aref w (+ b 4))) (* lx (aref w (+ b 1)))))        ;  off the chord), kept for the
                       (hz (+ qz (* ly (aref w (+ b 5))) (* lx (aref w (+ b 2)))))        ;  Kikon cinematic's lines
                       (hi (+ (* 3 i) g)) (ho (* 3 (+ (* 24 side) hi))) (sd (i->f (+ 90 hi))))
                  (declare (single-float ly lx hx hy hz sd) (fixnum hi ho))
                  (when (< i 8) (setf (aref *lb-holes* ho) hx (aref *lb-holes* (+ ho 1)) hy (aref *lb-holes* (+ ho 2)) hz))
                  (when (< hi (f->i (aref w 67)))           ; lit one by one (the Kikon cinematic's card)
                    (fx-disc hx hy hz (* 0.06f0 (aref v 31)) 0.04f0 (+ 60f0 sd) +pal-jade+ 0.95f0 :push 0.15f0)
                    (fx-disc hx hy hz (* 0.028f0 (aref v 31)) 0.03f0 (+ 160f0 sd) +pal-hit+ 0.95f0 :push 0.18f0))
                  (when (> mf 0f0)                          ; the muzzle flash
                    (fx-star hx hy hz (* 0.06f0 mf (aref v 31)) (* 0.22f0 mf (aref v 31)) 6 (* 0.7f0 sd) 0f0 0f0 0.1f0 sd
                             +pal-jade+ mf :push 0.2f0)
                    (fx-star hx hy hz (* 0.03f0 mf (aref v 31)) (* 0.1f0 mf (aref v 31)) 4 (* 1.3f0 sd) 0f0 0f0 0.05f0
                             (+ 40f0 sd) +pal-hit+ mf :push 0.25f0)))
                (setf qx (+ qx (* l3 (aref w (+ b 3)))) qy (+ qy (* l3 (aref w (+ b 4)))) qz (+ qz (* l3 (aref w (+ b 5)))))))))))
    nil))

(defmacro %lb-owl-beat! (be bo clip sf s a r enter)
  "Decision 56, 金翼振翅: set BE (the eight gold wings' elevation offset, degrees) and BO (KIN's swept sheaf opened, 0..1)
at frame SF of an owl strike playing CLIP (S A R, entered at ENTER): raised over the wind-up from the entry, struck down
over the startup's last *LB-OWL-BEAT-STROKE* frames (a K's + 1; at most half the startup) into S, held down through the
active frames, back over the recovery; K3 (the stoop) raised and pressed *LB-OWL-BEAT-K3* x as far, held flared into the
landing. Single-float forms; 0 B."
  `(let* ((%c ,clip) (%k3 (member %c '(:lb-o-f3 :lb-oe-f3))) (%kk (if %k3 (the single-float *lb-owl-beat-k3*) 1f0))
          (%up (* %kk (the single-float *lb-owl-beat-up*))) (%dn (* %kk (the single-float *lb-owl-beat-down*)))
          (%sf ,sf) (%s ,s) (%a ,a) (%r ,r) (%e ,enter)
          (%d (min (+ (the fixnum *lb-owl-beat-stroke*) (if (member %c '(:lb-o-f1 :lb-o-f2 :lb-o-f3 :lb-oe-f1 :lb-oe-f2 :lb-oe-f3)) 1 0))
                   (max 1 (floor (- %s %e) 2))))
          (%w0 (- %s %d)))
     (declare (single-float %kk %up %dn) (fixnum %sf %s %a %r %e %d %w0))
     (cond ((< %sf %w0) (let ((%u (%lb-ss (/ (i->f (- (1+ %sf) %e)) (i->f (max 1 (- %w0 %e)))))))
                          (declare (single-float %u))
                          (setf ,be (* %up %u) ,bo %u)))
           ((< %sf %s) (let ((%u (%lb-ss (/ (i->f (- (1+ %sf) %w0)) (i->f %d)))))
                         (declare (single-float %u))
                         (setf ,be (- %up (* (+ %up %dn) %u)) ,bo 1f0)))
           ((< %sf (+ %s %a)) (setf ,be (- %dn) ,bo 1f0))
           (t (let* ((%u (/ (i->f (- %sf %s %a)) (i->f (max 1 %r))))
                     (%k (- 1f0 (%lb-ss (if %k3 (/ (- %u 0.25f0) 0.6f0) (/ %u 0.6f0))))))
                (declare (single-float %u %k))
                (setf ,be (* (- %dn) %k) ,bo %k))))
     (setf ,bo (* ,bo (the single-float *lb-owl-beat-open*)))))

(defmacro %lb-drive! (f mv rdt owl)
  "Set *LB-WF* [39..52], the jointed wings' drive for F's draw (MV his move or nil, RDT the step, OWL the owl's wings): in a
strike (a move's main phase with active frames, not an SP or Kikon) the wind-up's virtual speed rising to *LB-STRIKE-IN*,
the active frames' straight flag, the recovery's virtual speed back (*LB-STRIKE-OUT*, easing out); which front wings strike
(J1 / K1's clip the right, J2 / K2's the left, the rest both); the other wings' share (Jilliel's 0.35, the owl's 0.7); the lag
spring's jump (the owl's 1 m^2, Jilliel's *LB-JUMP-JL*); in a Jilliel strike (*LB-JILLIEL-STRIKES*, decision 50) the
convergence's clock and kind and the trails' window; in an owl strike (*LB-OWL-STRIKES*, decision 56) the same, its
eight wings converging, and its wing beat (%LB-OWL-BEAT!). Reads the move's frame only for the look. 0 B."
  `(let ((%w *lb-wf*) (%f ,f) (%mv ,mv) (%vb 0f0) (%act 0f0) (%mask 3) (%cv 0f0) (%tr 0f0) (%be 0f0) (%bo 0f0) (%ow 0f0))
     (declare (type f32vec %w) (single-float %vb %act %cv %tr %be %bo %ow) (fixnum %mask))
     (when (and %mv (eq (fighter-phase %f) :main) (> (the fixnum (mv-a %mv)) 0) (not (member (mv-kind %mv) '(:sp :kikon))))
       (let ((%sf (fighter-sf %f)) (%s (mv-s %mv)) (%a (mv-a %mv)) (%r (mv-r %mv)))
         (declare (fixnum %sf %s %a %r))
         (cond ((< %sf %s) (setf %vb (* (the single-float *lb-strike-in*) (%lb-ss (/ (i->f (1+ %sf)) (i->f (max 1 %s)))))))
               ((< %sf (+ %s %a)) (setf %act 1f0))
               (t (let ((%u (f-min 1f0 (/ (i->f (- %sf %s %a)) (i->f (max 1 %r))))))
                    (declare (single-float %u))
                    (setf %vb (- (* (the single-float *lb-strike-out*) (- 1f0 %u) (- 1f0 %u)))))))
         (setf %mask (case (mv-clip %mv) ((:lb-w-q1 :lb-w-f1 :lb-e-q1 :lb-e-f1 :lb-o-q1 :lb-o-f1 :lb-oe-q1 :lb-oe-f1) 1)
                           ((:lb-w-q2 :lb-w-f2 :lb-e-q2 :lb-e-f2 :lb-o-q2 :lb-o-f2 :lb-oe-q2 :lb-oe-f2) 2) (t 3)))
         (when (if ,owl (member (mv-clip %mv) *lb-owl-strikes*) (member (mv-clip %mv) *lb-jilliel-strikes*))   ; decisions 50, 56
           (setf %cv 1f0
                 %tr (if (<= (+ %s (if ,owl (the fixnum *lb-owl-trail-from*) (the fixnum *lb-trail-from*))) %sf
                             (+ %s %a (the fixnum *lb-trail-to*) -1))
                         1f0 0f0)
                 (aref %w 46) (i->f (- %sf %s))
                 (aref %w 48) (if (member (mv-clip %mv) '(:lb-e-q1 :lb-e-q2 :lb-e-q3 :lb-e-f1 :lb-e-f2 :lb-e-f3 :lb-oe-q1 :lb-oe-q2
                                                          :lb-oe-q3 :lb-oe-f1 :lb-oe-f2 :lb-oe-f3))
                                  1f0 0f0)
                 (aref %w 49) (if (eq (mv-kind %mv) :flash) 1f0 0f0) (aref %w 50) (i->f %a) (aref %w 51) (i->f %r)
                 (aref %w 54) (let ((%rc (mv-reach %mv))) (if (typep %rc 'single-float) %rc 2f0)))
           (when ,owl                                    ; the owl's: all eight converge, after the wing beat
             (setf %ow 1f0)
             (%lb-owl-beat! %be %bo (mv-clip %mv) %sf %s %a %r (the fixnum (mv-enter %mv)))))))
     (setf (aref %w 39) %vb (aref %w 40) (i->f %mask) (aref %w 41) %act
           (aref %w 43) (f-min ,rdt 0.034f0) (aref %w 44) (if ,owl 0.7f0 0.35f0)
           (aref %w 45) (if ,owl 1f0 (the single-float *lb-jump-jl*)) (aref %w 47) %cv (aref %w 52) %tr
           (aref %w 68) %be (aref %w 69) %bo (aref %w 70) %ow)))

;; Decision 56 (2026-10-08, DUEL_LILLE §23.37): the SPs' and the Kikon's looks on the wings (the clips move the column and
;; the front pair; these the rest). SANREN: each shot kicks the firing wing (a virtual speed back: the joints whip forward)
;; and flashes its holes. NIJUSHI-KO and the Kikon: the six table wings swing into a ring round him facing his opponent
;; (the front pair's places the clip's), lit through the charge, which shakes harder; the shot blows them back (cupped back,
;; the joints bent by a burst of virtual speed), the muzzles flash; the Kikon's then close down before him (the verdict).
(defparameter *lb-sp-whip* 16.0 "SANREN: each shot's kick, a virtual speed back (m/s, easing out over *LB-SP-KICK* frames) ...")
(defparameter *lb-sp-kick* 8 "... frames (the firing wing's holes flash for 6).")
(defparameter *lb-ring-blow* 30.0 "NIJUSHI-KO / the Kikon: the shot's virtual speed (m/s, easing out over 10 f) that blows the wings back.")
(defparameter *lb-ring-shake* 0.07 "... and the charge's shake at its height (radians on each table wing's place in the ring, at 37 rad/s).")
(defmacro %lb-sp-drive! (f mv owl ck)
  "Decision 56: Jilliel's SP / Kikon looks for F's draw (MV his move or nil; nothing for the owl, OWL): *LB-WF* [61] the ring
0..1, [62] its cup (+ forward, - blown back), [63] the shake, [64] the close, [65] the wings lit (bits by row: 16 the right
front wing, 32 the left, 255 all), [66] their muzzle flash; at a shot also the strike drive [39 40 44] (the kick). The
timing: SANREN's shots S + 10 i (KIN) / 6 i (EN); NIJUSHI-KO's charge 0..1 over its startup (EN's 20 f, KIN's 40), the
frames after S in its clip's (x 40 / S); the Kikon's charge over its aura (8) and startup (20), then its own frames. Reads
the move's frame only (cosmetic). 0 B."
  `(let ((%w *lb-wf*) (%f ,f) (%mv ,mv) (%rg 0f0) (%cup 0f0) (%sh 0f0) (%cl 0f0) (%lit 0) (%fl 0f0) (%vb 0f0) (%mask -1)
         (%ts 0.6f0))
     (declare (type f32vec %w) (single-float %rg %cup %sh %cl %fl %vb %ts) (fixnum %lit %mask))
     (when ,ck                                            ; the Kikon cinematic (decision 56's storyboard, Amendment 2):
       (let* ((%c ,ck) (%sv *lb-judge-shots*) (%last -1))   ; the ring snapped open on f24 (gathered and shaking before:
         (declare (fixnum %c %last) (type (simple-array fixnum (*)) %sv))   ; LILLE-DRAW), its holes lit one by one through
         (dotimes (%n 48) (when (<= (aref %sv %n) %c) (setf %last %n)))     ; the card (f42-88), the charge shaking, each
         (let* ((%age (if (>= %last 0) (- (%lb-judge-t %c) (%lb-judge-t (aref %sv %last))) 99f0))   ; shot kicking it back
                (%k (if (< %age 6f0) (- 1f0 (/ %age 6f0)) 0f0))           ; (on the effect time: slowed on the first hits),
                (%n (if (< %c 268) (min 24 (max 0 (floor (- %c 40) 2))) 0)))   ; the verdict closing it (f262-268),
           (declare (single-float %age %k) (fixnum %n))                        ; settling after 277
           (setf %rg (* (%lb-ss (/ (- (i->f %c) 24f0) 3f0)) (- 1f0 (%lb-ss (/ (- (i->f %c) 277f0) 18f0))))
                 %cl (%lb-ss (/ (- (i->f %c) 262f0) 6f0))
                 %cup (- 0.3f0 (* 1.0f0 %k %k))
                 %sh (cond ((< %c 90) (* (the single-float *lb-ring-shake*) (%lb-ss (/ (- (i->f %c) 60f0) 30f0))))
                           ((< 192 %c 242) 0.03f0) (t 0f0))
                 %vb (* 0.6f0 (the single-float *lb-ring-blow*) %k %k) %mask 3 %ts 0.8f0
                 %fl (if (< %age 3f0) (- 1f0 (/ %age 3f0)) 0f0)
                 (aref %w 67) (i->f %n))
           (dotimes (%i 8) (when (>= %n (+ 3 (* 3 %i))) (setf %lit (logior %lit (ash 1 %i)))))
           (when (and (> %fl 0f0) (< %c 268))               ; the firing wing's muzzles flash
             (setf %lit (logior %lit (ash 1 (floor (%lb-judge-hole %last) 3))))))))
     (unless ,ck (setf (aref %w 67) 0f0))
     (when (and %mv (not ,owl))
       (let ((%nm (mv-name %mv)) (%ph (fighter-phase %f)) (%sf (fighter-sf %f)) (%s (mv-s %mv)))
         (declare (fixnum %sf %s))
         (case %nm
           ((:lb-sanren :lb-e-sanren)
            (when (and (eq %ph :main) (>= %sf %s))
              (let* ((%st (if (eq %nm :lb-sanren) 10 6)) (%n (min 2 (floor (- %sf %s) %st))) (%age (- %sf %s (* %n %st))))
                (declare (fixnum %st %n %age))
                (when (< %age (the fixnum *lb-sp-kick*))
                  (let ((%u (- 1f0 (/ (i->f %age) (i->f (the fixnum *lb-sp-kick*))))))
                    (declare (single-float %u))
                    (setf %mask (case %n (0 1) (1 2) (t 3)) %vb (- (* (the single-float *lb-sp-whip*) %u %u))
                          %lit (case %n (0 16) (1 32) (t 48)) %fl (f-max 0f0 (- 1f0 (/ (i->f %age) 6f0)))))))))
           ((:lb-nijushi :lb-e-nijushi :lb-w-kikon)
            (let* ((%kk (eq %nm :lb-w-kikon))
                   (%pre (cond ((eq %ph :aura) (/ (i->f (the fixnum (fighter-hold %f))) 28f0))   ; (the charge 0..1)
                               ((not (eq %ph :main)) 0.99f0)                                   ; (the Kikon's follow dash)
                               (%kk (f-min 1f0 (/ (+ 8f0 (i->f %sf)) 28f0)))
                               (t (f-min 1f0 (/ (i->f %sf) (i->f (max 1 %s)))))))
                   (%post (if (and (eq %ph :main) (>= %sf %s))                                ; (frames after the shot)
                              (if %kk (i->f (- %sf %s)) (/ (* 40f0 (i->f (- %sf %s))) (i->f (max 1 %s))))
                              -1f0)))
              (declare (single-float %pre %post))
              (setf %mask 3 %ts 0.8f0)
              (if (< %post 0f0)
                  (setf %rg (%lb-ss (/ %pre 0.35f0))
                        %cup (- 0.35f0 (* 0.25f0 (%lb-ss (/ (- %pre 0.4f0) 0.6f0))))
                        %sh (* (the single-float *lb-ring-shake*) (%lb-ss (/ (- %pre 0.3f0) 0.7f0)) (+ 0.3f0 (* 0.7f0 %pre)))
                        %vb (* 0.5f0 (the single-float *lb-strike-in*) (%lb-ss (/ (- %pre 0.5f0) 0.5f0)))
                        %lit 255)
                  (let ((%b (f-max 0f0 (- 1f0 (/ %post 10f0)))))
                    (declare (single-float %b))
                    (setf %rg (- 1f0 (%lb-ss (if %kk (/ (- %post 20f0) 12f0) (/ (- %post 18f0) 16f0))))
                          %cup (* -0.85f0 (%lb-ss (/ %post 2.5f0)) (- 1f0 (%lb-ss (if %kk (/ (- %post 4f0) 6f0) (/ (- %post 8f0) 18f0)))))
                          %cl (if %kk (%lb-ss (/ (- %post 4f0) 8f0)) 0f0)
                          %vb (* (the single-float *lb-ring-blow*) %b %b)
                          %lit (if (< %post 6f0) 255 0) %fl (f-max 0f0 (- 1f0 (/ %post 6f0)))))))))))
     (setf (aref %w 61) %rg (aref %w 62) %cup (aref %w 63) %sh (aref %w 64) %cl (aref %w 65) (i->f %lit) (aref %w 66) %fl)
     (when (>= %mask 0) (setf (aref %w 39) %vb (aref %w 40) (i->f %mask) (aref %w 44) %ts))))

;; 翼尖斬痕 the wing-tip slash trails (decision 50): per side and front wing a sword trail (the engine's +TRAIL-N+ samples:
;; the elbow -> the hand, i.e. the wing's outer stretch) recorded through the strike's window (*LB-WF* [52]) while the tip
;; moves, faded a sample a frame after (%TRAIL-DROP); drawn as the duel's smear (vfx.lisp's VFX-SMEAR: a comet crescent through the 0.7
;; points of the last samples, re-captured on the fx clock's drawings) in jade.
(defparameter *lb-smear-at* 0.85 "The jade smear runs through this point of each sample's elbow -> hand (the wing's tip end) ...")
(defparameter *lb-smear-w* 0.14 "... its half-width this share of the newest sample's elbow -> hand length ...")
(defparameter *lb-smear-k* 0.7 "... and its presence (toon alpha).")
(defvar *lb-trails* (let ((v (make-array 4))) (dotimes (i 4 v) (setf (svref v i) (make-trail))))
  "The tip trails: side x 2 + wing (0 the right front wing, 1 the left).")
(defvar *lb-smears* (let ((v (make-array 4))) (dotimes (i 4 v) (setf (svref v i) (make-f32 12))))
  "Their smears' state (VFX-SMEAR's SM: x0 y0 z0 x1 y1 z1 bx by bz, half-width, drawing, presence).")
(defun-fast %lb-smear (tr sm)
  "VFX-SMEAR's comet (vfx.lisp) in jade, through *LB-SMEAR-AT*, *LB-SMEAR-W* wide: captured from trail TR into SM on each new drawing. 0 B."
  (declare (type f32vec tr sm))
  (let* ((n (f->i (trail-count tr))) (dr (drawing-no)))
    (declare (fixnum n) (single-float dr))
    (fx-smear-capture! tr sm n dr (the single-float *lb-smear-at*) (len (* (the single-float *lb-smear-w*) len))
                       (* (the single-float *lb-smear-k*) (if (>= n 5) 1f0 0.65f0)))
    (when (> (aref sm 11) 0f0)
      (fx-crescent (aref sm 0) (aref sm 1) (aref sm 2) (aref sm 3) (aref sm 4) (aref sm 5) (aref sm 6) (aref sm 7) (aref sm 8)
                   (aref sm 9) :comet 0.06f0 (+ 17f0 dr) +pal-jade+ (aref sm 11) :push 0.15f0))
    nil))
(defun-fast %lb-trails (jm side)
  "SIDE's two tip trails from JM (decision 50): each striking front wing ([40]'s bits) records its elbow -> hand while the
strike's window is open ([52]) and the tip moved (a hitstop holds the arc), else fades; then its smear. 0 B."
  (declare (type f32vec jm) (fixnum side))
  (let ((w *lb-wf*))
    (declare (type f32vec w))
    (dotimes (g 2)
      (let* ((tr (svref *lb-trails* (+ (* 2 side) g))) (n (f->i (trail-count tr)))
             (h (if (= g 0) (* 16 (ji :hand-r)) (* 16 (ji :hand-l)))) (b (if (= g 0) (* 16 (ji :lower-arm-r)) (* 16 (ji :lower-arm-l))))
             (hx (aref jm (+ h 12))) (hy (aref jm (+ h 13))) (hz (aref jm (+ h 14))))
        (declare (type f32vec tr) (fixnum n h b) (single-float hx hy hz))
        (if (and (> (aref w 52) 0.5f0) (/= 0 (logand (f->i (aref w 40)) (if (= g 0) 1 2))))
            (let* ((o (* 6 (max 0 (1- n)))) (qx (- hx (aref tr (+ o 3)))) (qy (- hy (aref tr (+ o 4)))) (qz (- hz (aref tr (+ o 5)))))
              (declare (fixnum o) (single-float qx qy qz))
              (when (or (= n 0) (> (+ (* qx qx) (* qy qy) (* qz qz)) 1f-4))
                (%trail-push tr (aref jm (+ b 12)) (aref jm (+ b 13)) (aref jm (+ b 14)) hx hy hz)))
            (when (> n 0) (%trail-drop tr n)))
        (%lb-smear tr (svref *lb-smears* (+ (* 2 side) g))))))
  nil)

;; 金色爪痕 the owl's claw trails (decision 56): per side and claw a trail of its talons, the sample's ends the claw's tip (the
;; hand's -Y, *LB-CLAW-TIP* out) moved -/+ *LB-CLAW-SPREAD* along the forearm, so the swing leaves three concentric streaks,
;; recorded through the strike's window (*LB-WF* [52], Jilliel's) while it moves and faded a sample a frame after; drawn as
;; three thin gold comets (VFX-SMEAR's crescent, each through its own talon's point of the samples), not one crescent.
(defparameter *lb-claw-tip* 0.2 "The claw trail's middle streak: this far down the hand (m; the talons end about there) ...")
(defparameter *lb-claw-spread* 0.13 "... the outer two this far either side of it along the forearm (m) ...")
(defparameter *lb-claw-w* 0.08 "... each streak's half-width (m) ...")
(defparameter *lb-claw-k* 0.95 "... and its presence (toon alpha).")
(defvar *lb-claw-trails* (let ((v (make-array 4))) (dotimes (i 4 v) (setf (svref v i) (make-trail))))
  "The owl's claw trails: side x 2 + claw (0 the right, 1 the left).")
(defvar *lb-claw-smears* (let ((v (make-array 12))) (dotimes (i 12 v) (setf (svref v i) (make-f32 12))))
  "Their streaks' state: side x 6 + claw x 3 + streak (VFX-SMEAR's SM, as *LB-SMEARS*).")
(defun-fast %lb-claw-smears (tr side g)
  "Claw trail TR's (SIDE, claw G) three gold streaks: each a comet through its talon's point (0, 1/2, 1 across the
samples) of the last samples, *LB-CLAW-W* wide, re-captured on each new drawing. 0 B."
  (declare (type f32vec tr) (fixnum side g))
  (let* ((n (f->i (trail-count tr))) (dr (drawing-no)))
    (declare (fixnum n) (single-float dr))
    (dotimes (k 3)
      (let ((sm (svref *lb-claw-smears* (+ (* 6 side) (* 3 g) k))) (u (* 0.5f0 (i->f k))))
        (declare (type f32vec sm) (single-float u))
        (fx-smear-capture! tr sm n dr u (len (the single-float *lb-claw-w*))
                           (* (the single-float *lb-claw-k*) (if (>= n 5) 1f0 0.65f0)))
        (when (> (aref sm 11) 0f0)
          (fx-crescent (aref sm 0) (aref sm 1) (aref sm 2) (aref sm 3) (aref sm 4) (aref sm 5) (aref sm 6) (aref sm 7) (aref sm 8)
                       (aref sm 9) :comet 0.04f0 (+ 23f0 (* 3f0 (i->f k)) dr) +pal-gold+ (aref sm 11) :push 0.45f0)))))
  nil)
(defun-fast %lb-claw-trails (jm side)
  "SIDE's two claw trails from JM (decision 56): each striking claw ([40]'s bits: J1 / K1 the right, J2 / K2 the left, J3 /
K3 both) records its talons' span while the strike's window is open ([52]) and it moved, else fades; then its streaks. 0 B."
  (declare (type f32vec jm) (fixnum side))
  (let ((w *lb-wf*) (ct (the single-float *lb-claw-tip*)) (cs (the single-float *lb-claw-spread*)))
    (declare (type f32vec w) (single-float ct cs))
    (dotimes (g 2)
      (let* ((tr (svref *lb-claw-trails* (+ (* 2 side) g))) (n (f->i (trail-count tr)))
             (h (if (= g 0) (* 16 (ji :hand-r)) (* 16 (ji :hand-l)))) (b (if (= g 0) (* 16 (ji :lower-arm-r)) (* 16 (ji :lower-arm-l))))
             (hx (aref jm (+ h 12))) (hy (aref jm (+ h 13))) (hz (aref jm (+ h 14)))
             (yx (aref jm (+ h 4))) (yy (aref jm (+ h 5))) (yz (aref jm (+ h 6)))   ; the hand's +Y (its talons: -Y)
             (yl (f-max 1f-5 (f-sqrt (+ (* yx yx) (* yy yy) (* yz yz)))))
             (px (- hx (* ct (/ yx yl)))) (py (- hy (* ct (/ yy yl)))) (pz (- hz (* ct (/ yz yl))))
             (ax (- hx (aref jm (+ b 12)))) (ay (- hy (aref jm (+ b 13)))) (az (- hz (aref jm (+ b 14))))   ; the forearm
             (al (/ cs (f-max 1f-5 (f-sqrt (+ (* ax ax) (* ay ay) (* az az))))))
             (ux (* al ax)) (uy (* al ay)) (uz (* al az)))
        (declare (type f32vec tr) (fixnum n h b) (single-float hx hy hz yx yy yz yl px py pz ax ay az al ux uy uz))
        (if (and (> (aref w 52) 0.5f0) (/= 0 (logand (f->i (aref w 40)) (if (= g 0) 1 2))))
            (let* ((o (* 6 (max 0 (1- n)))) (qx (- px (aref tr (+ o 3)) (- ux))) (qy (- py (aref tr (+ o 4)) (- uy)))
                   (qz (- pz (aref tr (+ o 5)) (- uz))))
              (declare (fixnum o) (single-float qx qy qz))
              (when (or (= n 0) (> (+ (* qx qx) (* qy qy) (* qz qz)) 1f-4))
                (%trail-push tr (- px ux) (- py uy) (- pz uz) (+ px ux) (+ py uy) (+ pz uz))))
            (when (> n 0) (%trail-drop tr n)))
        (%lb-claw-smears tr side g))))
  nil)

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
      (1 (draw-weapon :lb-halo-gold *lb-m* :alpha al :emissive (if (< (aref *lb-v* 14) 0.99f0) *lb-glass-glow* (svref *lb-alphas* 0))))
      (t (draw-weapon :lb-halo-broken *lb-m* :alpha al
                                      :emissive (if (< (aref *lb-v* 14) 0.99f0) *lb-glass-glow* (svref *lb-alphas* 0))))))
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
  "The shank from height PY along the unit direction's DY: where it meets the floor (*LB-V* [3]), clamped; else 1 m (x his
drawn scale [31])."
  `(let ((%py ,py) (%dy ,dy) (%sc (aref *lb-v* 31)))
     (declare (single-float %py %dy %sc))
     (if (< %dy -0.35f0) (f-clamp (/ (- %py (aref *lb-v* 3)) (- %dy)) (* 0.45f0 %sc) (* 1.35f0 %sc)) %sc)))
(defmacro %lb-unit! (x y z)
  "Normalise the single-float places X Y Z in place (0 B)."
  `(let ((%l (f-max 1f-5 (f-sqrt (+ (* ,x ,x) (* ,y ,y) (* ,z ,z)))))) (declare (single-float %l))
     (setf ,x (/ ,x %l) ,y (/ ,y %l) ,z (/ ,z %l))))
(defparameter *lb-tuck-turn* 1.4
  "The owl's EN folds its ㄇ legs up (decision 38): at full tuck each shank turns this many radians about the thigh's side
axis, the front one back and the rear one forward, so both fold under the strut (a short bar under the floating column).")
(defparameter *lb-tuck-len* 0.48 "... and is this long (m; standing, a shank runs to the floor).")
(defun-fast %lb-legs (jm white fl)
  "Both ㄇ legs (decision 26) from the thighs of JM: WHITE 1 the owl's, else KIN's cream; FL 1 the hit flash. The floor's
height in *LB-V* [3], the alpha in [4] (MUJITTAI's body alpha), the tuck 0..1 in [8] (the owl's EN folds them up, decision
38: the front shank turned back, the rear one forward, both *LB-TUCK-LEN* long)."
  (declare (type f32vec jm) (fixnum white fl))
  (let* ((al (lb-alpha (aref *lb-v* 4))) (fla (svref *lb-alphas* (if (= fl 1) 9 0)))   ; (boxed: 0 B)
         (tk (aref *lb-v* 8)) (tt (* tk (the single-float *lb-tuck-turn*))) (ct (f-cos tt)) (st (f-sin tt))
         (sc (aref *lb-v* 31)) (tl (* sc (the single-float *lb-tuck-len*)))   ; (x his drawn scale: a giant's legs)
         (fyc (- (* -0.1f0 st) ct)) (fbc (- st (* 0.1f0 ct)))          ; the front shank's up / back shares, turned back
         (ryc (- (* -0.12f0 st) ct)) (rbc (+ (- st) (* 0.12f0 ct))))   ; the rear's, turned forward
    (declare (single-float tk tt ct st sc tl fyc fbc ryc rbc))
    (dotimes (side 2)
      (let* ((o (if (= side 0) (* 16 (ji :thigh-r)) (* 16 (ji :thigh-l)))) (s (if (= side 0) 1f0 -1f0))
             (ox (* s (aref jm o))) (oy (* s (aref jm (+ o 1)))) (oz (* s (aref jm (+ o 2))))            ; out
             (yx (aref jm (+ o 4))) (yy (aref jm (+ o 5))) (yz (aref jm (+ o 6)))                      ; up the thigh
             (bx (aref jm (+ o 8))) (by (aref jm (+ o 9))) (bz (aref jm (+ o 10)))                     ; back
             (fk (the single-float *lb-leg-fork*)) (ls (* sc (the single-float *lb-leg-strut*)))
             (px (- (aref jm (+ o 12)) (* fk yx))) (py (- (aref jm (+ o 13)) (* fk yy))) (pz (- (aref jm (+ o 14)) (* fk yz)))
             ;; the front shank: down, a little forward and out (tucked: turned back under the strut)
             (fx (+ (* 0.07f0 ox) (* fyc yx) (* fbc bx))) (fy (+ (* 0.07f0 oy) (* fyc yy) (* fbc by)))
             (fz (+ (* 0.07f0 oz) (* fyc yz) (* fbc bz)))
             ;; the strut: back, a little out; the rear shank: down, a little back and out (tucked: turned forward)
             (sx (+ bx (* 0.04f0 ox))) (sy (+ by (* 0.04f0 oy))) (sz (+ bz (* 0.04f0 oz)))
             (rx (+ (* ryc yx) (* rbc bx) (* 0.07f0 ox))) (ry (+ (* ryc yy) (* rbc by) (* 0.07f0 oy)))
             (rz (+ (* ryc yz) (* rbc bz) (* 0.07f0 oz))))
        (declare (fixnum o) (single-float s ox oy oz yx yy yz bx by bz fk ls px py pz fx fy fz sx sy sz rx ry rz))
        (%lb-unit! fx fy fz) (%lb-unit! sx sy sz) (%lb-unit! rx ry rz)
        (let ((lf (+ (* (- 1f0 tk) (%lb-shank-len py fy)) (* tk tl))) (cx (+ px (* ls sx))) (cy (+ py (* ls sy))) (cz (+ pz (* ls sz))))
          (declare (single-float lf cx cy cz))
          (%lb-frame! *lb-m* px py pz fx fy fz ox oy oz lf sc)
          (if (= white 1) (draw-weapon :lb-shank-white *lb-m* :alpha al :flash fla) (draw-weapon :lb-shank-cream *lb-m* :alpha al :flash fla))
          (%lb-frame! *lb-m* px py pz sx sy sz ox oy oz ls)
          (if (= white 1) (draw-weapon :lb-strut-white *lb-m* :alpha al :flash fla) (draw-weapon :lb-strut-cream *lb-m* :alpha al :flash fla))
          (let ((lr (+ (* (- 1f0 tk) (%lb-shank-len cy ry)) (* tk tl))))
            (declare (single-float lr))
            (%lb-frame! *lb-m* cx cy cz rx ry rz ox oy oz lr sc)
            (if (= white 1) (draw-weapon :lb-shank-white *lb-m* :alpha al :flash fla)
                (draw-weapon :lb-shank-cream *lb-m* :alpha al :flash fla)))))))
  nil)

;;; ---------------------------------------------------------------- the looks keyed on his state
(defmacro lb-fxs (side i) `(aref *lb-fx* (+ (* 24 ,side) ,i)))

(defun lb-cine-frame (e name)
  "The running cinematic's frame when it is NAME with E as its subject, else NIL (a look the script drives)."
  (let ((c *cine*)) (and c (eq (cine-name c) name) (eq (cine-a c) e) (cine-cf c))))

;;; Every component lookup of an entity conses 8 B in this build (an ECS getter: the reads probe, debug 79195), so the
;;; draw hook makes the fewest: his fighter and model each frame, his state (LBS, read as it is: the draw never makes one)
;;; only in the looks that read it (the base form's eye, the owl's seal), his transform only while a look needs his place.
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
          (toon-ribbon (qx 1.3f0 qz) (dx 0f0 dz) ((* 0.9f0 k) (* 0.6f0 k)) :heat (1f0 0.6f0) :seed -21f0 :wob 0.05f0 :pal +pal-gold+ :k k :segs 2)
          (when (< age 0.05f0)
            (joint-point! *lb-p* (model-joints m) (ji :head) 0f0 0.74f0 -0.2f0)
            (dotimes (i 10)
              (let* ((a (* 0.6283f0 (i->f i))) (sp (+ 1.5f0 (* 0.3f0 (i->f (mod i 3))))))
                (declare (single-float a sp))
                (%t-shard (aref *lb-p* 0) (aref *lb-p* 1) (aref *lb-p* 2) (* sp (f-cos a)) 2.5f0 (* sp (f-sin a))
                          0.8f0 0.12f0 7f0 +pal-gold+)))))))
    nil))

(defparameter *lb-owl-en-spread* 0.9
  "The owl's EN fans its wings out this far of an SP's spread (decision 36: 0.6; decision 38, the user 2026-10-06:
「遠程模式翼張開」: 0.6 -> 0.9, wide and forward, the holes to the opponent).")
(defparameter *lb-spread-clips* '(:lb-w-nijushi :lb-o-trompete)
  "The clips (besides every :sp and :kikon move) that fan the wings out (NIJUSHI-KO's beam, Trompete; the volley's :lb-w-aim went with decision 56).")
(defmacro lb-jilliel-form-p (form) `(member ,form '(:jilliel :jilliel-mujittai :jilliel-kin :jilliel-kin-mujittai)))
(defmacro %lb-owl-p (form) "The owl's four forms (decision 36)." `(member ,form '(:shin :shin-mujittai :shin-kin :shin-kin-mujittai)))
(defmacro lb-mujittai-p (form) `(member ,form '(:jilliel-mujittai :jilliel-kin-mujittai :shin-mujittai :shin-kin-mujittai)))
(defmacro %lb-stance-fx! (e side stance tm rdt)
  "MUJITTAI's look memory for SIDE (Jilliel's and the owl's): a hit passed through (the guard gauge dropped in the
stance: [3] the ripple's start), [2] the gauge seen, [4] the fold 0..1 (5 / s). The gauge lookup only in the stance."
  `(progn
     (if ,stance
         (let ((%gg (gauges-gg (gauges ,e))))
           (declare (single-float %gg))
           (when (< %gg (- (lb-fxs ,side 2) 0.5f0)) (setf (lb-fxs ,side 3) ,tm))
           (setf (lb-fxs ,side 2) %gg))
         (setf (lb-fxs ,side 2) 100f0))
     (setf (lb-fxs ,side 4) (if ,stance (f-min 1f0 (+ (lb-fxs ,side 4) (* 5f0 ,rdt))) (f-max 0f0 (- (lb-fxs ,side 4) (* 5f0 ,rdt)))))))

(defun-fast lille-draw (e rdt)
  "His kit's :draw hook (after his body; cosmetic): the base form's eye opening and its aim line / reticle; Jilliel's eight
wing blades (both modes: two fans of four behind the column, the front pair reaching to the rig's hands, each swaying on
its own phase; folded round the column in MUJITTAI, rippling on each pass-through, their holes lit in NIJUSHI-KO's tell,
fanned out in the SPs; translucent, fainter in MUJITTAI; each three jointed segments that wave, lag and whip in the
strikes, curl in MUJITTAI and unfurl in the SPs) and the wide jade halo; on the KIN and owl bodies the ㄇ legs; the
owl's eight gold wings, its spiked halo (broken once sealed), the trumpet
forming over Trompete's wind-up, the reflect. The awakening's and the revival's cinematics drive the wings and halos
(the unfolding, the jade turning gold). Its only allocation is the entity lookups (two a frame, three in the base form
and the owl; one more while he aims or a gold look plays; one more in MUJITTAI)."
  (declare (single-float rdt))
  (let* ((f (fighter e)) (side (fighter-side f)) (form (fighter-form f)) (m (model e)) (jm (model-joints m))
         (mv (and (eq (fighter-state f) :move) (fighter-move f))) (v *lb-v*) (tm (fx-clock))
         (cj (lb-cine-frame e 'lb-jilliel-cine)) (cr (lb-cine-frame e 'lb-revive-cine))
         (ct (lb-cine-frame e 'lb-trompete-cine)) (ck (lb-cine-frame e 'lb-jilliel-kikon-cine))
         (look (cond ((and cj (< (the fixnum cj) 92)) :base) ((and cr (< (the fixnum cr) 66)) :revive)
                     ((lb-jilliel-form-p form) :jilliel) ((%lb-owl-p form) :shin) (t :base))))
    (declare (fixnum side) (type f32vec jm v) (single-float tm))
    (setf (lb-fxs side 15) (if (%lb-owl-p form) 1f0 0f0))   ; (his hazards' looks read it: gold or jade)
    (let ((spread (and mv (or (member (mv-kind mv) '(:sp :kikon)) (member (mv-clip mv) *lb-spread-clips*)))))
      (setf (lb-fxs side 16)                             ; the SPs fan the wings out (0.12 s either way) ...
            (if spread (f-min 1f0 (+ (lb-fxs side 16) (* 8f0 rdt))) (f-max 0f0 (- (lb-fxs side 16) (* 8f0 rdt))))
            (lb-fxs side 17)                             ; ... and their joints furl then unfurl from the root (decision 32)
            (if spread (f-min 1f0 (+ (lb-fxs side 17) (* 2.2f0 rdt))) (f-max 0f0 (- (lb-fxs side 17) (* 3f0 rdt))))))
    (setf (aref *lb-wf* 42) (lb-fxs side 17))
    ;; the owl's two modes (decision 38): [18] 0..1 toward EN (5 / s: inside TENSHIN's dash): EN's legs folded up ([8] the
    ;; tuck) and its wings fanned wide and forward ([28] the spread); KIN's legs down and its wings swept back ([29])
    (let ((en (and (%lb-owl-p form) (member form '(:shin :shin-mujittai)))))
      (setf (lb-fxs side 18) (if en (f-min 1f0 (+ (lb-fxs side 18) (* 5f0 rdt))) (f-max 0f0 (- (lb-fxs side 18) (* 5f0 rdt))))
            (aref v 8) (if (%lb-owl-p form) (lb-fxs side 18) 0f0)
            (aref v 29) (if (%lb-owl-p form) (- 1f0 (lb-fxs side 18)) 0f0)))
    (%lb-drive! f mv rdt (%lb-owl-p form))               ; the joints' strike drive (cosmetic: the move's frame)
    (%lb-sp-drive! f mv (%lb-owl-p form) ck)             ; the SPs', the Kikon's and its cinematic's (decision 56)
    (let ((pz (anim-pose (model-anim m))) (w *lb-wf*))   ; (the clip's root turn and offset: decision 50's targets)
      (declare (type f32vec pz w))
      (setf (aref w 53) (aref pz 66) (aref w 59) (aref pz 65) (aref w 60) (aref pz 63)))
    (setf (aref v 28) (lb-fxs side 16)
          (aref v 31) (draw-scale-of e)                  ; (the Jilliel Kikon's giant: his wings, holes, legs and flashes)
          (aref v 3) (- (aref *toon-body* 1)             ; his body's feet height (DRAW-BODY's) less the form's drawn
                        (* (aref v 31) (the single-float (f32 (body-lift (fighter-kit f) (model-body m)))))))   ; lift: the floor
    (when (>= (model-alpha m) 0.999f0)
      (let ((bn (body-name (model-body m))) (fl (if (> (model-flash m) 0f0) 1 0)))
        (when (or (eq bn :lille-jilliel-kin) (eq bn :lille-shin))   ; the ㄇ legs (decision 26)
          (setf (aref v 4) (if (lb-mujittai-p form) 0.72f0 1f0))
          (%lb-legs jm (if (eq bn :lille-shin) 1 0) fl)
          nil))
      (case look
        (:base (%lb-eye-look e m (lbs e) side) (%lb-aim-look e f side))
        ((:jilliel :revive)
         (let ((stance (lb-mujittai-p form)))
           (%lb-stance-fx! e side stance tm rdt)        ; (a hit passed through, the fold)
           (let* ((rip (- tm (lb-fxs side 3))) (k (if (and cr (< (the fixnum cr) 30)) 0.8f0 (lb-fxs side 4)))
                  (gold (if cr (f-clamp (/ (- (i->f cr) 30f0) 30f0) 0f0 1f0) 0f0))
                  (gather (if (and ck (< (the fixnum ck) 24)) (i->f ck) -1f0))   ; (the Kikon cinematic's beat 1:
                  (o (* 16 (ji :chest))))                                         ;  gathered round him, shaking, f0-23)
             (declare (single-float rip k gold gather) (fixnum o))
             (setf (aref v 0) 0f0 (aref v 1) 0.3f0 (aref v 2) 0.13f0
                   (aref v 11) (if (>= gather 0f0) (f-max k (* 0.85f0 (%lb-ss (/ gather 6f0)))) k)
                   (aref v 12) (cond ((>= gather 0f0) (+ 3f0 (* 0.4f0 gather))) ((< rip 0.5f0) (* 14f0 (- 1f0 (* 2f0 rip))))
                                     (t 0f0))
                   (aref v 13) tm
                   (aref v 14) (if stance 0.7f0 1f0) (aref v 16) (aref v 31) (aref v 23) 0f0
                   (aref v 15) (if (and cj (< (the fixnum cj) 160)) (f-max 0f0 (/ (- (i->f cj) 112f0) 8f0)) 9f0))
             (if (> gold 0f0)                            ; the revival: the jade turning gold over 30 f, a pair at a time
                 (let ((pg (i->f (min 4 (f->i (* 4.2f0 gold))))))
                   (declare (single-float pg))
                   (setf (aref v 15) pg) (%lb-wings jm o *lb-wings-jl* 8 2 side)
                   (setf (aref v 15) 9f0 (aref v 23) pg) (%lb-wings jm o *lb-wings-jl* 8 0 side)
                   (setf (aref v 23) 0f0))
                 (%lb-wings jm o *lb-wings-jl* 8 0 side))   ; (the holes lit: [65], %LB-SP-DRIVE!)
             (unless cr (%lb-trails jm side))            ; the tip trails (decision 50)
             (unless cr                                  ; the wide thin halo (the headless column has none)
               (setf (aref v 14) (if stance 0.7f0 1f0))
               (if (and cj (< (the fixnum cj) 160))
                   (let ((u (f-clamp (/ (- (i->f cj) 120f0) 40f0) 0f0 1f0)))   ; the awakening: it draws itself
                     (declare (single-float u))
                     (when (> u 0f0) (%lb-halo jm (* 16 (ji :head)) 0 0.52f0 (* 0.48f0 u))))
                   (%lb-halo jm (* 16 (ji :head)) 0 (+ 0.52f0 (* 0.02f0 (f-sin (* 2f0 tm)))) 0.48f0))))))
        (:shin                                           ; the owl (decision 36: Jilliel's four forms, the owl's look)
         (let* ((grow (if cr (f-clamp (/ (- (i->f cr) 66f0) 30f0) 0.05f0 1f0) 1f0))
                (stance (lb-mujittai-p form)) (st (lbs e)))
           (declare (single-float grow))
           (%lb-stance-fx! e side stance tm rdt)          ; MUJITTAI: the wings curl round the column, ghostly
           ;; EN vs KIN (decision 38): EN fans its eight wings out wide and forward (a standing spread, [18]), KIN sweeps
           ;; them back ([29], set above)
           (let ((rip (- tm (lb-fxs side 3))))
             (declare (single-float rip))
             (setf (aref v 0) 0f0 (aref v 1) 0.3f0 (aref v 2) 0.13f0 (aref v 11) (lb-fxs side 4)
                   (aref v 12) (if (< rip 0.5f0) (* 14f0 (- 1f0 (* 2f0 rip))) 0f0) (aref v 13) tm
                   (aref v 14) (if stance 0.7f0 1f0) (aref v 15) 9f0 (aref v 23) 0f0
                   (aref v 16) (* (aref v 31) (+ 0.3f0 (* 0.7f0 grow)))
                   (aref v 28) (f-max (aref v 28) (* (the single-float *lb-owl-en-spread*) (lb-fxs side 18)))))
           (%lb-wings jm (* 16 (ji :chest)) *lb-wings-owl* 8 2 side)
           (unless cr (%lb-claw-trails jm side))         ; the claw trails (decision 56)
           (%lb-halo jm (* 16 (ji :head)) (if (and st (lbs-sealed st)) 2 1) 0.76f0 (* 0.13f0 grow))
           (let ((tsf (cond (ct (if (< 8 (the fixnum ct) 120) (- (the fixnum ct) 8) -1))
                            ((and mv (eq (mv-name mv) :lb-trompete) (eq (fighter-phase f) :main)) (fighter-sf f))
                            ((and mv (eq (mv-name mv) :lb-oe-trompete) (eq (fighter-phase f) :main))   ; (EN's: its clip's
                             (truncate (* 60 (the fixnum (fighter-sf f))) (max 1 (the fixnum (mv-s mv)))))   ;  speed, 5 x)
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
(defmacro %lb-judge-speed () "The owl's materialised trace (裁きの光明, decision 36): its gold blasts erupt along the line at
this many m/s (31 m in 8 f: the hit is the whole line at once, the look follows it fast; a literal: 0 B) ..." 240f0)
(defmacro %lb-judge-burn () "... each point burning this many seconds." 0.3f0)
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
             (w (case kind (:beam 1.2f0) (:lane 0.5f0) (:sabaki (the single-float (f32 *lb-sabaki-width*)))   ; call)
                      (:judge (if (eq (lbh-lock d) :thick) 1.2f0 0.6f0)) (t 0.05f0)))
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
                 (toon-ribbon ((+ x (* 0.6f0 vx)) y (+ z (* 0.6f0 vz))) ((* (- ll 0.6f0) vx) 0f0 (* (- ll 0.6f0) vz)) (ww ww) :heat (1f0 0.7f0)
                              :seed (- -11f0 sd) :wob 0.02f0 :pal (if (lbh-lock d) +pal-jade+ +pal-ink+) :k (* 0.98f0 fade) :k1 (* 0.9f0 fade) :segs 2)
                 (when (< age 4)                        ; the first frames: a white core, the cross flash at the muzzle
                   (fx-ribbon (+ x (* 0.6f0 vx)) y (+ z (* 0.6f0 vz)) (* (- ll 0.6f0) vx) 0f0 (* (- ll 0.6f0) vz) (* 0.4f0 ww) (* 0.4f0 ww)
                              1f0 (- -12f0 sd) 0.0f0 (toon-a +pal-hit+ 0.95f0) 1f0 (- -12f0 sd) 0f0 (toon-a +pal-hit+ 0.9f0) 0f0 0f0
                              :segs 2 :mode :toon)
                   (fx-star (+ x (* 1.0f0 vx)) y (+ z (* 1.0f0 vz)) 0.06f0 0.32f0 4 0f0 0f0 0f0 0.05f0 (+ 13f0 (i->f i))
                            +pal-hit+ (- 0.98f0 (* 0.2f0 (i->f age))) :push 0.2f0))))))
          (:beam
           (let* ((ww (* w (+ 0.35f0 (* 0.65f0 fade)))) (pal (if owl +pal-gold+ +pal-jade+)))
             (declare (single-float ww pal))
             (toon-ribbon ((+ x (* 0.6f0 ux)) 1.3f0 (+ z (* 0.6f0 uz))) ((* (- l 0.6f0) ux) 0f0 (* (- l 0.6f0) uz)) (ww ww) :heat (1f0 0.8f0)
                          :seed (- -31f0 sd) :wob 0.05f0 :pal pal :k (* 0.98f0 fade) :k1 (* 0.9f0 fade) :segs 3)
             (toon-ribbon ((+ x (* 0.6f0 ux)) 1.3f0 (+ z (* 0.6f0 uz))) ((* (- l 0.6f0) ux) 0f0 (* (- l 0.6f0) uz)) ((* 0.35f0 ww) (* 0.35f0 ww))
                          :heat (1f0 1f0) :seed (- -32f0 sd) :wob 0.05f0 :pal +pal-hit+ :k (* 0.95f0 fade) :k1 (* 0.9f0 fade) :segs 3)))
          (:lane (%lb-floor-line 1 (+ x (* 0.6f0 ux)) (+ z (* 0.6f0 uz)) ux uz (- l 0.6f0) (* w fade)))
          (:judge                                      ; the owl's trace materialised (decision 36): 裁きの光明, gold blasts
           (let* ((a2 (/ (i->f age) 60f0)) (sp (%lb-judge-speed))   ; erupting along the ground to the wall
                  (from (f-max 0.6f0 (* sp (- a2 (%lb-judge-burn))))) (to (f-min l (+ 0.6f0 (* sp a2)))))
             (declare (single-float a2 sp from to))
             (when (> to from)
               (toon-ribbon ((+ x (* from ux)) 0.2f0 (+ z (* from uz))) ((* (- to from) ux) 0f0 (* (- to from) uz)) ((* 0.2f0 w) (* 0.12f0 w))
                            :heat (1f0 0.6f0) :seed (- -43f0 sd) :wob 0.05f0 :pal +pal-gold+ :k 0.95f0 :k1 0.8f0 :segs 4)
               (do ((r (+ 1f0 (* 1.5f0 (i->f (f->i (/ from 1.5f0))))) (+ r 1.5f0))) ((> r to))
                 (declare (single-float r))
                 (let* ((h (* (+ 1.2f0 (* 0.9f0 w)) (f-min 1f0 (/ (- to r) 2.5f0)) (f-min 1f0 (* 0.4f0 (- r from -0.6f0)))))
                        (bx (+ x (* r ux))) (bz (+ z (* r uz))))
                   (declare (single-float h bx bz))
                   (when (> h 0.05f0)
                     (%tongue bx 0f0 bz 0f0 h 0f0 (* 0.4f0 w) +pal-gold+ 0.95f0 (+ r (* 7f0 sd)) (* 3f0 r) 0.1f0))))
               (when (< age 3)                          ; the first frames: a white core along the line
                 (toon-ribbon ((+ x (* 0.6f0 ux)) 0.25f0 (+ z (* 0.6f0 uz))) ((* (- l 0.6f0) ux) 0f0 (* (- l 0.6f0) uz)) ((* 0.08f0 w) (* 0.08f0 w))
                              :heat (1f0 1f0) :seed (- -44f0 sd) :wob 0f0 :pal +pal-hit+ :k 0.9f0 :k1 0.8f0 :segs 2)))))
          (:sabaki
           (let* ((a2 (/ (i->f age) 60f0)) (r0 (the single-float (f32 *lb-sabaki-from*))) (sp (the single-float (f32 *lb-sabaki-speed*)))
                  (from (f-max r0 (* sp (- a2 (/ (i->f (the fixnum *lb-sabaki-life*)) 60f0))))) (to (f-min len (+ r0 (* sp a2)))))
             (declare (single-float a2 r0 sp from to))
             (when (> to from)
               (toon-ribbon ((+ x (* from ux)) 0.2f0 (+ z (* from uz))) ((* (- to from) ux) 0f0 (* (- to from) uz)) (0.1f0 0.06f0) :heat (1f0 0.6f0)
                            :seed (- -41f0 sd) :wob 0.05f0 :pal +pal-gold+ :k 0.95f0 :k1 0.8f0 :segs 4)
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
      ((:shin :shin-mujittai :shin-kin :shin-kin-mujittai) (if (lbs-sealed (lb e)) "SEALED" "HALO"))
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
      ((:shin :shin-mujittai :shin-kin :shin-kin-mujittai)
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
      (toon-ribbon (x 1.45f0 z) ((* 30f0 ux) 0f0 (* 30f0 uz)) ((* 0.09f0 k) (* 0.06f0 k)) :heat (1f0 0.8f0) :seed -81f0 :wob 0.02f0 :pal +pal-jade+
                   :k k :segs 2)
      (toon-ribbon (x 1.45f0 z) ((* 30f0 ux) 0f0 (* 30f0 uz)) ((* 0.035f0 k) (* 0.025f0 k)) :heat (1f0 1f0) :seed -82f0 :wob 0f0 :pal +pal-hit+ :k k
                   :segs 2)
      (fx-star x 1.45f0 z (* 0.1f0 k) (* 0.5f0 k) 4 0.785f0 0f0 0f0 0.05f0 83f0 +pal-hit+ k :push 0.3f0))))

(defun vfx-lb-cross-hole (v k)
  "万物貫通's hole: a cross of white light through V's silhouette (the muzzle's cross), K its presence."
  (multiple-value-bind (x y z) (actor-point v 1.2)
    (with-floats (x y z k)
      (with-cam (rx ry rz ux uy uz)
        (dotimes (i 4)
          (let* ((sx (if (< i 2) rx ux)) (sy (if (< i 2) ry uy)) (sz (if (< i 2) rz uz)) (sg (if (evenp i) 1f0 -1f0)))
            (declare (single-float sx sy sz sg))
            (fx-shard (+ x (* 0.32f0 sg sx)) (+ y (* 0.32f0 sg sy)) (+ z (* 0.32f0 sg sz)) (* sg sx) (* sg sy) (* sg sz)
                      0.8f0 0.09f0 0.02f0 (+ 31f0 (i->f i)) +pal-hit+ k :push 0.6f0)))
        (fx-star x y z 0.08f0 0.2f0 4 0.785f0 0f0 0f0 0.03f0 35f0 +pal-hit+ k :push 0.6f0)))))

(defun-fast vfx-lb-judge (a v cf)
  "The Kikon cinematic's lines and holes at its frame CF (decision 56's storyboard and Amendment 2; A Lille, V the
opponent), on its effect time (*LB-JUDGE-TIME*: slowed on the first three hits): each pierce's jade line (a white core)
flies from its hole (*LB-HOLES*) to V in *LB-JUDGE-FLY* frames, goes 3 m on through him over 2 more and fades over 5; a
star where it enters, growing over 3; from the hit a white hole in V (*LB-JUDGE-PIERCE*: facing the camera, pushed over
his silhouette), until the verdict (frame 268). From the frame alone: nothing outlives the cinematic. 0 B but its two
position reads."
  (declare (fixnum cf))
  (let* ((p (pos-of a)) (q (pos-of v)) (side (if (eql a *p1*) 0 1)) (hs *lb-holes*) (pp *lb-judge-pierce*)
         (sv *lb-judge-shots*) (tc (%lb-judge-t cf)) (fly (the single-float *lb-judge-fly*))
         (dx (- (aref p 0) (aref q 0))) (dz (- (aref p 2) (aref q 2))) (dl (f-max 0.01f0 (f-sqrt (+ (* dx dx) (* dz dz)))))
         (rx (- (/ dz dl))) (rz (/ dx dl)) (qx (aref q 0)) (qy (aref q 1)) (qz (aref q 2)))   ; (his right, facing A)
    (declare (type f32vec p q hs pp) (type (simple-array fixnum (*)) sv) (fixnum side)
             (single-float tc fly dx dz dl rx rz qx qy qz))
    (when (< cf 268)
      (dotimes (n 48)
        (let ((sf (aref sv n)))
          (declare (fixnum sf))
          (when (<= sf cf)
            (let* ((o (* 3 n)) (u (aref pp o)) (tx (+ qx (* u rx))) (ty (+ qy (aref pp (+ o 1)))) (tz (+ qz (* u rz)))
                   (age (- tc (%lb-judge-t sf))) (sd (i->f n)))
              (declare (fixnum o) (single-float u tx ty tz age sd))
              (when (>= age fly)                         ; the hole, from the hit
                (fx-disc tx ty tz (aref pp (+ o 2)) 0.04f0 (+ 600f0 sd) +pal-hit+ 0.98f0 :push 0.35f0))
              (when (< age (+ fly 7f0))                  ; the line: flying, through him, fading
                (let* ((k (if (< age (+ fly 2f0)) 1f0 (- 1f0 (* 0.2f0 (- age fly 2f0)))))
                       (h (* 3 (+ (* 24 side) (%lb-judge-hole n))))
                       (x0 (aref hs h)) (y0 (aref hs (+ h 1))) (z0 (aref hs (+ h 2)))
                       (ax (- tx x0)) (ay (- ty y0)) (az (- tz z0)) (al (f-max 0.01f0 (f-sqrt (+ (* ax ax) (* ay ay) (* az az)))))
                       (e (if (< age fly) (/ age fly) (/ (+ al (* 3f0 (f-min 1f0 (* 0.5f0 (- age fly))))) al)))
                       (ex (* ax e)) (ey (* ay e)) (ez (* az e)))
                  (declare (single-float k x0 y0 z0 ax ay az al e ex ey ez) (fixnum h))
                  (toon-ribbon (x0 y0 z0) (ex ey ez) ((* 0.065f0 k) (* 0.05f0 k)) :heat (1f0 0.8f0) :seed (- -151f0 sd) :wob 0.02f0 :pal +pal-jade+
                               :k k :segs 2)
                  (toon-ribbon (x0 y0 z0) (ex ey ez) ((* 0.018f0 k) (* 0.014f0 k)) :heat (1f0 1f0) :seed (- -251f0 sd) :wob 0f0 :pal +pal-hit+ :k k
                               :segs 2)
                  (when (and (>= age fly) (< age (+ fly 3f0)))   ; the star where it enters, growing
                    (let ((g (+ 0.5f0 (* 0.25f0 (- age fly)))))
                      (declare (single-float g))
                      (fx-star tx ty tz (* 0.06f0 g) (* 0.3f0 g) 6 (* 0.9f0 sd) 0f0 0f0 0.1f0 (+ 700f0 sd) +pal-jade+
                               0.95f0 :push 0.4f0))))))))))
    nil))

(defun vfx-lb-horizon (a k)
  "神の喇叭's Kikon: the beam out of the bell, erasing the horizon (a wide gold band, a white core), K its presence."
  (let* ((p (pos-of a)) (yaw (yaw-of a)) (ux (fwd-x yaw)) (uz (fwd-z yaw))
         (x (+ (aref p 0) (* 2.0 ux))) (z (+ (aref p 2) (* 2.0 uz))))
    (with-floats (x z ux uz k)
      (toon-ribbon (x 1.7f0 z) ((* 70f0 ux) 1.2f0 (* 70f0 uz)) ((* 1.6f0 k) (* 6f0 k)) :heat (1f0 0.7f0) :seed -61f0 :wob 0.05f0 :pal +pal-gold+
                   :k (* 0.98f0 k) :k1 (* 0.9f0 k) :segs 4)
      (toon-ribbon (x 1.7f0 z) ((* 70f0 ux) 1.2f0 (* 70f0 uz)) ((* 0.6f0 k) (* 2.5f0 k)) :heat (1f0 1f0) :seed -62f0 :wob 0.05f0 :pal +pal-hit+
                   :k (* 0.95f0 k) :k1 (* 0.9f0 k) :segs 4)
      (fx-star x 1.7f0 z (* 0.4f0 k) (* 1.1f0 k) 12 (* 2f0 (fx-clock)) 0f0 0f0 0.12f0 63f0 +pal-gold+ k :push 0.6f0))))

(defun vfx-lb-light (x y z r k)
  "A ball of gold light (the revival's head growing, the trumpet's charge): a gold disc and its rays."
  (with-floats (x y z r k)
    (fx-disc x y z r 0.08f0 71f0 +pal-gold+ k)
    (fx-star x y z (* 0.6f0 r) (* 1.9f0 r) 10 (* 1.5f0 (fx-clock)) 0f0 0f0 0.12f0 72f0 +pal-hit+ (* 0.9f0 k) :push 0.3f0)))

;;; his extra brush glyphs (the cinematics' captions, §10): glyphs-extra.lisp


;;; (the consing probe's parts, debug 79195: what a draw path's single reads cost in DEFUN-FAST code)
(defun-fast %lbt-fighter (e) (fighter e) nil)
(defun-fast %lbt-pos (e) (pos-of e) nil)
(defun-fast %lbt-yaw (e) (let ((y (yaw-of e))) (declare (single-float y)) (setf y 0f0)) nil)
(defun-fast %lbt-lb (e) (lb e) nil)
(defun-fast %lbt-alpha (e) (let ((a (model-alpha (model e)))) (declare (single-float a)) (setf a 0f0)) nil)
(defun-fast %lbt-eyet (e) (let ((x (i->f (lbs-eye-t (lb e))))) (declare (single-float x)) (setf x 0f0)) nil)
