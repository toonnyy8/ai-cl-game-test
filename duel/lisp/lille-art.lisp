;;;; lille-art.lisp — LILLE BARRO as art data (docs/duel/DUEL_LILLE.md §3, §12 Art; the model sheet
;;;; docs/research/tybw-characters/notes/lille_barro_model_sheet.md): his three bodies (:lille 182 cm, dark skin #7A6155, all
;;;; in white with the green fur cap / stole / panel, the left eye shut under the mark; :lille-jilliel, the holed cream column
;;;; floating, armless to the eye: the rig's arms are the front pair of wing blades, the other six are static plates; and
;;;; :lille-shin, the owl: white, four stilt legs, long arms, an S-neck, a small owl head, gold #B89A5A only on the wings and the
;;;; halo), Diagramm (2.4 m: the barrel through a fur sleeve, the plank across the rear, the muzzle cross), the props of his
;;;; looks (the aim line, the shots, the beams, the SABAKI blasts, the trumpet), every :lb-* pose and clip, his draw hook and his
;;;; hazards' look. Batch 1 (functional art): the strikes put the plank (J1 / J2 / the Breaker), the muzzle (J3, K) or the
;;;; wing / arm tips (Jilliel, the owl) where the moves' volumes end (*LB-STRIKE-POINTS*; the host FK test checks them). The
;;;; jade is an ink tone (decision 11): the three spot hues stay FIRE, REIATSU and BLOOD.
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
  ;; white trousers, the buttoned green front panel
  (:pelvis (:box 0.34 0.2 0.24 :c :white)
           (:box 0.1 0.24 0.02 :at (0 -0.1 0.125) :c :green)
           (:box 0.02 0.02 0.01 :at (0.04 -0.04 0.137) :c :button) (:box 0.02 0.02 0.01 :at (-0.04 -0.04 0.137) :c :button)
           (:box 0.02 0.02 0.01 :at (0.04 -0.12 0.137) :c :button) (:box 0.02 0.02 0.01 :at (-0.04 -0.12 0.137) :c :button))
  ;; the wide white waist band, three buttons on his right
  (:spine (:bevel 0.32 0.24 0.22 0.04 :at (0 0.1 0) :c :white)
          (:box 0.34 0.12 0.24 :at (0 0.02 0) :c :white)
          (:box 0.02 0.02 0.01 :at (0.1 0.05 0.122) :c :button) (:box 0.02 0.02 0.01 :at (0.1 0.0 0.122) :c :button))
  ;; the white shirt, a V of skin, the long green fur stole down the right chest
  (:chest (:bevel 0.42 0.3 0.26 0.05 :at (0 0.11 0) :c :white)
          (:box 0.07 0.1 0.01 :at (0 0.22 0.13) :c :skin)
          (:box 0.13 0.46 0.07 :at (0.11 0.06 0.13) :c :green)
          (:box 0.02 0.42 0.02 :at (0.17 0.06 0.168) :c :green-d)
          (:box 0.025 0.025 0.01 :at (0.06 0.18 0.168) :c :button) (:box 0.025 0.025 0.01 :at (0.06 0.06 0.168) :c :button)
          (:box 0.025 0.025 0.01 :at (0.06 -0.06 0.168) :c :button)
          (:bevel 0.3 0.06 0.08 0.02 :at (0 0.27 -0.08) :c :green))           ; the stole rings the back of the collar
  (:neck (:cyl 0.05 0.14 :at (0 0.06 0) :c :skin))
  ;; the head (x1.2): the right eye open, the left shut under the ring-of-four-arcs mark; the green fur cap, two ridges
  ;; left and right of the long white crown, a steel disc on each side; cream sideburns
  (:head (:sphere 0.072 :stretch 0.02 :at (0 0.13 -0.01) :seg 12 :c :skin)
         (:bevel 0.1 0.08 0.08 0.02 :at (0 0.1 0.02) :c :skin)
         (:box 0.024 0.01 0.003 :at (0.028 0.125 0.062) :c :eye)
         (:box 0.011 0.01 0.003 :at (0.026 0.125 0.0635) :c :pupil)
         (:box 0.026 0.004 0.003 :at (0.028 0.142 0.0625) :c :brow)
         (:box 0.026 0.004 0.003 :at (-0.028 0.124 0.0625) :c :lid)                 ; the shut left eye
         (:box 0.006 0.016 0.003 :at (-0.028 0.146 0.0635) :c :black)               ; the mark: four arcs, the X open
         (:box 0.006 0.016 0.003 :at (-0.028 0.102 0.0635) :c :black)
         (:box 0.016 0.006 0.003 :at (-0.05 0.124 0.0635) :c :black)
         (:box 0.016 0.006 0.003 :at (-0.006 0.124 0.0635) :c :black)
         (:box 0.016 0.003 0.003 :at (0 0.075 0.058) :c :mouth)
         (:box 0.018 0.05 0.03 :at (0.068 0.12 0.0) :c :hair) (:box 0.018 0.05 0.03 :at (-0.068 0.12 0.0) :c :hair)
         (:cyl 0.085 0.05 :at (0 0.175 -0.01) :seg 12 :c :green)                    ; the fur rim, low on the brow
         (:bevel 0.06 0.1 0.24 0.02 :at (0.055 0.23 -0.01) :c :green)               ; the two ridges (the bicorne's points)
         (:bevel 0.06 0.1 0.24 0.02 :at (-0.055 0.23 -0.01) :c :green)
         (:box 0.05 0.09 0.22 :at (0 0.225 -0.01) :c :white)                        ; the white crown between them
         (:sphere 0.018 :at (0.09 0.2 0) :c :button) (:sphere 0.018 :at (-0.09 0.2 0) :c :button))
  (:shoulder-r (:bevel 0.16 0.09 0.2 0.03 :at (0.03 0 0) :c :green))               ; the stole's fur mass
  (:shoulder-l (:sphere 0.06 :at (0.0 -0.01 0) :c :skin))
  (:upper-arm-r (:cyl 0.055 0.3 :top 0.05 :at (0 -0.15 0) :c :white))             ; the white right sleeve
  (:upper-arm-l (:cyl 0.052 0.3 :top 0.045 :at (0 -0.15 0) :c :skin))             ; the bare left arm
  (:lower-arm-r (:cyl 0.045 0.27 :top 0.04 :at (0 -0.13 0) :c :white))
  (:lower-arm-l (:cyl 0.044 0.27 :top 0.038 :at (0 -0.13 0) :c :skin) (:cyl 0.05 0.06 :at (0 -0.24 0) :c :white))
  (:hand-r (:bevel 0.07 0.09 0.04 0.012 :at (0 -0.04 0) :c :white))
  (:hand-l (:bevel 0.07 0.09 0.04 0.012 :at (0 -0.04 0) :c :white))
  (:thigh-r (:cyl 0.09 0.44 :top 0.075 :seg 10 :at (0 -0.21 0) :c :white))
  (:thigh-l (:cyl 0.09 0.44 :top 0.075 :seg 10 :at (0 -0.21 0) :c :white))
  (:shin-r (:cyl 0.07 0.43 :top 0.06 :seg 10 :at (0 -0.2 0) :c :white))
  (:shin-l (:cyl 0.07 0.43 :top 0.06 :seg 10 :at (0 -0.2 0) :c :white))
  (:foot-r (:bevel 0.08 0.06 0.22 0.02 :at (0 -0.03 0.05) :c :white))
  (:foot-l (:bevel 0.08 0.06 0.22 0.02 :at (0 -0.03 0.05) :c :white)))

;; 神の裁き JILLIEL: the holed cream column (no legs drawn: the rig's legs carry nothing), its face in a round window, two
;; horn points, the thin flat jade halo above; the rig's arms (x2.6 long) are the front pair of the eight wing blades (the J
;; / K strike at the hands), the other six fan out behind as static plates (muted jade, decision 11)
(defbody :lille-jilliel (:scale 1.0 :width 1.0 :hunch 0 :hurt-r 0.38 :hurt-h 1.8 :props (:arms 2.6)
                         :palette ((:cream #xEDE6CC) (:jade #x6E9A80) (:jade-d #x4E6E5C) (:hole #x2A2A30) (:skin #x7A6155)
                                   (:eye #xF2F0EC) (:pupil #x2A3124))
                         :rim (#xFFE8C8 0.14))
  (:pelvis (:cyl 0.15 0.7 :top 0.13 :seg 12 :at (0 -0.3 0) :c :cream)
           (:cone 0.07 0.3 :at (0.08 -0.8 0) :rot (180 0 0) :seg 6 :c :cream)        ; the two prongs
           (:cone 0.07 0.3 :at (-0.08 -0.8 0) :rot (180 0 0) :seg 6 :c :cream)
           (:sphere 0.03 :at (0.05 -0.2 0.135) :c :hole) (:sphere 0.03 :at (-0.06 -0.38 0.13) :c :hole)
           (:sphere 0.03 :at (0.04 -0.52 0.125) :c :hole))
  (:spine (:cyl 0.13 0.3 :top 0.15 :seg 12 :at (0 0.1 0) :c :cream) (:sphere 0.028 :at (-0.05 0.1 0.13) :c :hole))
  (:chest (:cyl 0.16 0.42 :top 0.19 :seg 12 :at (0 0.14 0) :c :cream)
          (:sphere 0.03 :at (0.07 0.2 0.16) :c :hole) (:sphere 0.03 :at (-0.07 0.08 0.16) :c :hole)
          ;; the six static wings: from one root behind the neck, three a side at +38 / -15 / -40 degrees
          (:box 0.15 0.95 0.015 :at (0.4 0.6 -0.18) :rot (0 0 -52) :c :jade) (:box 0.15 0.95 0.015 :at (-0.4 0.6 -0.18) :rot (0 0 52) :c :jade)
          (:box 0.14 0.9 0.015 :at (0.44 0.18 -0.2) :rot (0 0 -105) :c :jade) (:box 0.14 0.9 0.015 :at (-0.44 0.18 -0.2) :rot (0 0 105) :c :jade)
          (:box 0.13 0.85 0.015 :at (0.34 -0.02 -0.22) :rot (0 0 -130) :c :jade-d) (:box 0.13 0.85 0.015 :at (-0.34 -0.02 -0.22) :rot (0 0 130) :c :jade-d)
          (:sphere 0.03 :at (0.55 0.71 -0.17) :c :hole) (:sphere 0.03 :at (-0.55 0.71 -0.17) :c :hole)
          (:sphere 0.03 :at (0.6 0.16 -0.19) :c :hole) (:sphere 0.03 :at (-0.6 0.16 -0.19) :c :hole))
  (:neck (:cyl 0.13 0.15 :seg 12 :at (0 0.06 0) :c :cream))
  (:head (:sphere 0.15 :stretch 0.03 :at (0 0.12 0) :seg 12 :c :cream)
         (:cyl 0.075 0.02 :at (0 0.12 0.13) :rot (90 0 0) :seg 12 :c :hole)          ; the face window
         (:sphere 0.055 :at (0 0.12 0.1) :c :skin)
         (:box 0.018 0.008 0.003 :at (0.02 0.13 0.153) :c :eye) (:box 0.018 0.008 0.003 :at (-0.02 0.13 0.153) :c :eye)
         (:cone 0.035 0.13 :at (0.11 0.27 0) :rot (0 0 -18) :seg 5 :c :cream) (:cone 0.035 0.13 :at (-0.11 0.27 0) :rot (0 0 18) :seg 5 :c :cream)
         ;; the halo: a thin flat ring of twelve segments floating above the column
         (:box 0.24 0.012 0.04 :at (0 0.46 0.45) :c :jade) (:box 0.24 0.012 0.04 :at (0 0.46 -0.45) :c :jade)
         (:box 0.04 0.012 0.24 :at (0.45 0.46 0) :c :jade) (:box 0.04 0.012 0.24 :at (-0.45 0.46 0) :c :jade)
         (:box 0.24 0.012 0.04 :at (0.32 0.46 0.32) :rot (0 45 0) :c :jade) (:box 0.24 0.012 0.04 :at (-0.32 0.46 -0.32) :rot (0 45 0) :c :jade)
         (:box 0.24 0.012 0.04 :at (0.32 0.46 -0.32) :rot (0 -45 0) :c :jade) (:box 0.24 0.012 0.04 :at (-0.32 0.46 0.32) :rot (0 -45 0) :c :jade))
  (:shoulder-r (:sphere 0.08 :c :cream))
  (:shoulder-l (:sphere 0.08 :c :cream))
  ;; the front wing pair on the arm chains (upper 0.78 m, fore 0.70 m at x2.6), three holes each, the tip at the hand
  (:upper-arm-r (:box 0.17 0.8 0.02 :at (0 -0.4 0) :c :jade) (:sphere 0.03 :at (0 -0.5 0.012) :c :hole))
  (:upper-arm-l (:box 0.17 0.8 0.02 :at (0 -0.4 0) :c :jade) (:sphere 0.03 :at (0 -0.5 0.012) :c :hole))
  (:lower-arm-r (:box 0.14 0.7 0.02 :at (0 -0.35 0) :c :jade) (:sphere 0.03 :at (0 -0.2 0.012) :c :hole)
                (:sphere 0.03 :at (0 -0.5 0.012) :c :hole))
  (:lower-arm-l (:box 0.14 0.7 0.02 :at (0 -0.35 0) :c :jade) (:sphere 0.03 :at (0 -0.2 0.012) :c :hole)
                (:sphere 0.03 :at (0 -0.5 0.012) :c :hole))
  (:hand-r (:wedge 0.1 0.12 0.02 :at (0 -0.03 0) :rot (180 0 0) :c :jade))
  (:hand-l (:wedge 0.1 0.12 0.02 :at (0 -0.03 0) :rot (180 0 0) :c :jade)))

;; 真の姿 the owl: a white body on four stilt legs (the rig's legs x1.5, two more static on the hips), long thin arms
;; (x2.2), a fur ruff, the segmented S-neck to a tiny owl face, the small spiked gold halo, eight gold holed wings behind
(defbody :lille-shin (:scale 1.0 :width 1.0 :hunch 0 :hurt-r 0.38 :hurt-h 1.8 :props (:arms 2.2 :legs 1.5)
                      :palette ((:white #xECECE8) (:shade #xBCC1CC) (:fur #xD8DCE4) (:face #xE8E4DC) (:gold #xB89A5A)
                                (:gold-l #xC2A866) (:ink #x16161E) (:hole #x2A2A30))
                      :rim (#xFFE8C8 0.14))
  (:pelvis (:bevel 0.36 0.2 0.62 0.05 :at (0 0 -0.12) :c :white)
           (:cyl 0.035 1.5 :top 0.012 :at (0.13 -0.62 -0.5) :rot (14 0 4) :seg 6 :c :white)   ; the two hind stilts
           (:cyl 0.035 1.5 :top 0.012 :at (-0.13 -0.62 -0.5) :rot (14 0 -4) :seg 6 :c :white)
           (:box 0.02 0.6 0.004 :at (0.1 -0.3 -0.42) :rot (20 0 0) :c :fur) (:box 0.02 0.6 0.004 :at (-0.1 -0.3 -0.42) :rot (20 0 0) :c :fur))
  (:spine (:cyl 0.11 0.26 :top 0.13 :seg 10 :at (0 0.1 0) :c :white))
  (:chest (:bevel 0.3 0.28 0.2 0.04 :at (0 0.11 0) :c :white)
          (:sphere 0.17 :stretch -0.04 :at (0 0.27 -0.02) :seg 10 :c :fur)             ; the fur ruff
          ;; eight gold wings behind, from one root, four a side
          (:box 0.15 1.0 0.015 :at (0.42 0.66 -0.2) :rot (0 0 -52) :c :gold) (:box 0.15 1.0 0.015 :at (-0.42 0.66 -0.2) :rot (0 0 52) :c :gold)
          (:box 0.15 0.95 0.015 :at (0.5 0.36 -0.22) :rot (0 0 -80) :c :gold-l) (:box 0.15 0.95 0.015 :at (-0.5 0.36 -0.22) :rot (0 0 80) :c :gold-l)
          (:box 0.14 0.9 0.015 :at (0.46 0.12 -0.24) :rot (0 0 -105) :c :gold) (:box 0.14 0.9 0.015 :at (-0.46 0.12 -0.24) :rot (0 0 105) :c :gold)
          (:box 0.13 0.85 0.015 :at (0.34 -0.04 -0.26) :rot (0 0 -130) :c :gold-l) (:box 0.13 0.85 0.015 :at (-0.34 -0.04 -0.26) :rot (0 0 130) :c :gold-l)
          (:sphere 0.03 :at (0.58 0.78 -0.19) :c :hole) (:sphere 0.03 :at (-0.58 0.78 -0.19) :c :hole))
  ;; the S-neck: segments curving back, then forward and up (plates on the front, a fur crest behind)
  (:neck (:cyl 0.05 0.2 :at (0 0.1 -0.03) :rot (-20 0 0) :seg 8 :c :white)
         (:cyl 0.045 0.2 :at (0 0.28 -0.08) :rot (-8 0 0) :seg 8 :c :white)
         (:box 0.02 0.36 0.03 :at (0 0.2 -0.1) :rot (-14 0 0) :c :fur))
  (:head (:cyl 0.042 0.2 :at (0 0.36 -0.04) :rot (18 0 0) :seg 8 :c :white)
         (:cyl 0.04 0.18 :at (0 0.52 0.04) :rot (30 0 0) :seg 8 :c :white)
         (:sphere 0.085 :stretch 0.0 :at (0 0.66 0.1) :seg 10 :c :face)                ; the tiny owl face
         (:sphere 0.022 :at (0.03 0.67 0.17) :c :ink) (:sphere 0.022 :at (-0.03 0.67 0.17) :c :ink)
         (:cone 0.014 0.05 :at (0 0.63 0.18) :rot (110 0 0) :seg 4 :c :shade)
         ;; the small spiked halo: a ring of six gold spikes above the head
         (:cyl 0.11 0.012 :at (0 0.8 0.1) :seg 12 :c :gold)
         (:cone 0.016 0.07 :at (0.1 0.83 0.1) :seg 4 :c :gold-l) (:cone 0.016 0.07 :at (-0.1 0.83 0.1) :seg 4 :c :gold-l)
         (:cone 0.016 0.07 :at (0.05 0.83 0.19) :seg 4 :c :gold-l) (:cone 0.016 0.07 :at (-0.05 0.83 0.19) :seg 4 :c :gold-l)
         (:cone 0.016 0.07 :at (0.05 0.83 0.01) :seg 4 :c :gold-l) (:cone 0.016 0.07 :at (-0.05 0.83 0.01) :seg 4 :c :gold-l))
  (:shoulder-r (:sphere 0.06 :c :white))
  (:shoulder-l (:sphere 0.06 :c :white))
  (:upper-arm-r (:cyl 0.035 0.66 :top 0.03 :seg 8 :at (0 -0.33 0) :c :white))
  (:upper-arm-l (:cyl 0.035 0.66 :top 0.03 :seg 8 :at (0 -0.33 0) :c :white))
  (:lower-arm-r (:cyl 0.03 0.6 :top 0.025 :seg 8 :at (0 -0.3 0) :c :white))
  (:lower-arm-l (:cyl 0.03 0.6 :top 0.025 :seg 8 :at (0 -0.3 0) :c :white))
  (:hand-r (:box 0.05 0.14 0.02 :at (0 -0.06 0) :c :white) (:box 0.008 0.08 0.008 :at (0.015 -0.16 0) :c :shade))
  (:hand-l (:box 0.05 0.14 0.02 :at (0 -0.06 0) :c :white) (:box 0.008 0.08 0.008 :at (-0.015 -0.16 0) :c :shade))
  (:thigh-r (:cyl 0.05 0.66 :top 0.035 :seg 8 :at (0 -0.33 0) :c :white))
  (:thigh-l (:cyl 0.05 0.66 :top 0.035 :seg 8 :at (0 -0.33 0) :c :white))
  (:shin-r (:cyl 0.035 0.64 :top 0.012 :seg 6 :at (0 -0.32 0) :c :white))
  (:shin-l (:cyl 0.035 0.64 :top 0.012 :seg 6 :at (0 -0.32 0) :c :white))
  (:foot-r (:cone 0.02 0.06 :at (0 -0.03 0) :rot (180 0 0) :seg 4 :c :shade))
  (:foot-l (:cone 0.02 0.06 :at (0 -0.03 0) :rot (180 0 0) :seg 4 :c :shade)))

;;; ---------------------------------------------------------------- Diagramm and the props
;; ディアグラム DIAGRAMM: 2.4 m. The grip at the sleeve's rear: the barrel runs 1.75 m to the muzzle cross (the weapon's
;; length: the tip the FK test measures), 0.65 m back to the tall black plank across the rear (the butt, measured at a
;; negative weapon-length point, *LB-BUTT*); the green fur sleeve over the barrel's rear part, a dial knob on the plank
(defparameter *lb-butt* 0.6 "Diagramm: the plank's strike point, metres behind the grip (the weapon frame's -Y; the FK test).")
(defweapon :diagramm (:length 1.75 :base 0.3)
  (:solid (mbc mb #x16161E)
          (with-xform (mb (xform :y 0.55)) (mb-cylinder mb 0.024 2.4 :segments 6))           ; the barrel, -0.65 .. 1.75
          (with-xform (mb (xform :y 1.72)) (mb-box mb 0.2 0.07 0.05) (mb-box mb 0.05 0.07 0.2))   ; the muzzle cross
          (with-xform (mb (xform :y -0.6 :z 0.15)) (mb-box mb 0.035 0.1 1.2))                 ; the plank, across the rear
          (with-xform (mb (xform :y -0.62 :z -0.38)) (mb-box mb 0.12 0.08 0.04))              ; its two lower plates
          (mbc mb #xBCC1CC) (with-xform (mb (xform :y -0.56 :z 0.42 :x 0.03)) (mb-cylinder mb 0.03 0.02 :segments 8)))
  (:solid (mbc mb #x434D3B) (with-xform (mb (xform :y 0.2)) (mb-cylinder mb 0.1 0.6 :segments 8))      ; the fur sleeve
          (mbc mb #x2A3124) (with-xform (mb (xform :y 0.3 :z 0.1)) (mb-box mb 0.03 0.03 0.012))
          (with-xform (mb (xform :y 0.1 :z 0.1)) (mb-box mb 0.03 0.03 0.012))))
;; the looks' props, unit along +Y (drawn from A to B by LB-SEG)
(defweapon :lb-line (:length 1.0) (:solid :ink 0 (mbc mb #x3A3E48) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))
(defweapon :lb-line-jade (:length 1.0) (:solid :ink 0 (mbc mb #x6E9A80) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))
(defweapon :lb-line-grey (:length 1.0) (:solid :ink 0 (mbc mb #x9A9EA6) (with-xform (mb (xform :y 0.5)) (mb-box mb 1.0 1.0 1.0))))
(defweapon :lb-beam-jade (:length 1.0)
  (:solid :ink 0 (mbc mb #x9CC4AC) (with-xform (mb (xform :y 0.5)) (mb-cylinder mb 1.0 1.0 :segments 10))))
(defweapon :lb-beam-gold (:length 1.0)
  (:solid :ink 0 (mbc mb #xD8C080) (with-xform (mb (xform :y 0.5)) (mb-cylinder mb 1.0 1.0 :segments 10))))
(defweapon :lb-blast (:length 1.0)                     ; a SABAKI blast: a gold flame-cone
  (:solid :ink 0 (mbc mb #xB89A5A) (mb-cone mb 0.5 1.0 :segments 5)
          (mbc mb #xF2E6C0) (with-xform (mb (xform :y 0.05)) (mb-cone mb 0.25 0.7 :segments 5))))
(defweapon :lb-trumpet (:length 5.0)                   ; 神の喇叭: a long plain gold horn, the bell ring with four struts
  (:solid (mbc mb #xB89A5A) (with-xform (mb (xform :y 2.0)) (mb-cylinder mb 0.06 4.0 :segments 8 :top-radius 0.3))
          (with-xform (mb (xform :y 4.1)) (mb-cylinder mb 0.9 0.2 :segments 16 :top-radius 0.9))
          (mbc mb #xC2A866) (with-xform (mb (xform :y 4.22)) (mb-box mb 1.8 0.04 0.06) (mb-box mb 0.06 0.04 1.8))
          (with-xform (mb (xform :y 0.5 :z 0.15 :pitch 0.4)) (mb-cone mb 0.08 0.6 :segments 4))
          (with-xform (mb (xform :y 0.6 :z -0.15 :pitch -0.4)) (mb-cone mb 0.08 0.6 :segments 4))))

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
;;; Floating 0.5 m up (the hurt cylinder stays on the ground), the front wings (the arms) raised into the fan; the strikes
;;; are the wings snapping forward, their tips at the moves' reach.
(defpose :lb-w-stance ()
  (:root :u 0.5) (:spine :flex 0) (:head :flex 4)
  (:arm-r :flex 10 :side 78) (:elbow-r :flex 8) (:arm-l :flex 10 :side 78) (:elbow-l :flex 8)
  (:thighs :flex 0) (:knees :flex 0))
(defclip :lb-w-stance (3.0 :loop t :base :lb-w-stance)
  (0) (1.5 (:root :u 0.56) (:arm-r :side 72) (:arm-l :side 72)))
(defpose :lb-w-fold-pose (:base :lb-w-stance)        ; 無実体 MUJITTAI: the wings folded round the column
  (:root :u 0.55) (:arm-r :flex 40 :side 24 :twist 30) (:elbow-r :flex 30) (:arm-l :flex 40 :side 24 :twist -30) (:elbow-l :flex 30)
  (:head :flex 10))
(defclip :lb-w-fold (2.0 :loop t :base :lb-w-fold-pose) (0) (1.0 (:root :u 0.6)))
(defpose :lb-w-q1-hit (:base :lb-w-stance)
  (:root :f 0.08 :u 0.5) (:chest :twist 14) (:arm-r :flex 88 :side 8) (:elbow-r :flex 6))
(defstrike :lb-w-q1 (8 3 12 :base :lb-w-stance)
  (0) (4 (:arm-r :flex 20 :side 100)) (:s :snap :lb-w-q1-hit) (:a :lb-w-q1-hit) (:end :lb-w-stance))
(defpose :lb-w-q2-hit (:base :lb-w-stance)
  (:root :f 0.08 :u 0.5) (:chest :twist -14) (:arm-l :flex 88 :side 8) (:elbow-l :flex 6))
(defstrike :lb-w-q2 (7 3 13 :base :lb-w-stance)
  (0) (4 (:arm-l :flex 20 :side 100)) (:s :snap :lb-w-q2-hit) (:a :lb-w-q2-hit) (:end :lb-w-stance))
(defpose :lb-w-q3-hit (:base :lb-w-stance)
  (:root :f 0.18 :u 0.5) (:arm-r :flex 86 :side 14) (:arm-l :flex 86 :side 14) (:elbow-r :flex 2) (:elbow-l :flex 2))
(defstrike :lb-w-q3 (9 3 18 :base :lb-w-stance)
  (0) (5 (:arm-r :flex 30 :side 110) (:arm-l :flex 30 :side 110)) (:s :snap :lb-w-q3-hit) (:a :lb-w-q3-hit) (:end :lb-w-stance))
(defpose :lb-w-f1-hit (:base :lb-w-stance)
  (:root :f 0.62 :u 0.45) (:spine :flex 10) (:chest :twist -10) (:arm-r :flex 88 :side 4) (:elbow-r :flex 2) (:arm-l :flex 70 :side 30))
(defstrike :lb-w-f1 (17 4 21 :base :lb-w-stance)
  (0) (10 (:root :f -0.1) (:arm-r :flex 0 :side 120) (:chest :twist 20)) (:s :snap :lb-w-f1-hit) (:a :lb-w-f1-hit) (:end :lb-w-stance))
(defpose :lb-w-f2-hit (:base :lb-w-stance)
  (:root :f 0.62 :u 0.45) (:spine :flex 10) (:chest :twist 10) (:arm-l :flex 88 :side 4) (:elbow-l :flex 2) (:arm-r :flex 70 :side 30))
(defstrike :lb-w-f2 (20 4 24 :base :lb-w-stance)
  (0) (12 (:root :f -0.1) (:arm-l :flex 0 :side 120) (:chest :twist -20)) (:s :snap :lb-w-f2-hit) (:a :lb-w-f2-hit) (:end :lb-w-stance))
(defpose :lb-w-f3-hit (:base :lb-w-stance)
  (:root :f 0.72 :u 0.4) (:spine :flex 14) (:arm-r :flex 86 :side 4) (:arm-l :flex 86 :side 4) (:elbow-r :flex 2) (:elbow-l :flex 2))
(defstrike :lb-w-f3 (21 5 34 :base :lb-w-stance)
  (0) (12 (:root :f -0.1 :u 0.7) (:arm-r :flex 170 :side 20) (:arm-l :flex 170 :side 20)) (:s :snap :lb-w-f3-hit) (:a :lb-w-f3-hit)
  (:end :lb-w-stance))
(defpose :lb-w-aim-pose (:base :lb-w-stance)          ; the volley: the wings snapped forward, their holes aimed
  (:arm-r :flex 60 :side 40) (:elbow-r :flex 10) (:arm-l :flex 60 :side 40) (:elbow-l :flex 10) (:head :flex 6))
(defclip :lb-w-aim (0.6 :loop t :base :lb-w-aim-pose) (0) (0.3 (:root :u 0.52)))
(defstrike :lb-w-fire (4 2 24 :base :lb-w-aim-pose)
  (0) (:s :snap (:root :f -0.05)) (:a (:root :f -0.1) (:arm-r :side 50) (:arm-l :side 50)) (:end :lb-w-stance))
(defstrike :lb-w-nijushi (40 6 30 :base :lb-w-stance) ; all 24 holes: the wings spread wide, held, then the beam
  (0) (10 (:arm-r :flex 30 :side 100) (:arm-l :flex 30 :side 100) (:root :u 0.7)) (:s :snap (:root :f -0.15) (:arm-r :flex 60 :side 70)
                                                                                     (:arm-l :flex 60 :side 70))
  (:a (:root :f -0.2)) (:end :lb-w-stance))
(defclip :lb-w-breaker (0.4 :loop t :base :lb-w-stance)
  (0 (:root :u 0.3 :pitch 14) (:arm-r :flex -30 :side 40) (:arm-l :flex -30 :side 40)) (0.2 (:root :u 0.34 :pitch 14)))
(defpose :lb-w-ram-hit (:base :lb-w-stance)
  (:root :f 0.0 :u 0.4) (:spine :flex 4) (:arm-r :flex 66 :side 52) (:elbow-r :flex 24) (:arm-l :flex 66 :side 52) (:elbow-l :flex 24))
(defstrike :lb-w-ram (8 4 18 :base :lb-w-stance)
  (0 (:arm-r :flex 10 :side 120) (:arm-l :flex 10 :side 120)) (:s :snap :lb-w-ram-hit) (:a :lb-w-ram-hit) (:end :lb-w-stance))

;;; ---------------------------------------------------------------- the owl
;;; Upright on the stilts, the long arms hanging, the neck in an S; the claws (the hands) strike at the moves' reach.
(defpose :lb-o-stance ()
  (:root :u -0.02) (:spine :flex 4) (:head :flex 10)
  (:arm-r :flex 8 :side 10) (:elbow-r :flex 12) (:arm-l :flex 8 :side 10) (:elbow-l :flex 12)
  (:thigh-r :flex 6 :side 6) (:thigh-l :flex -4 :side 6) (:knees :flex 6))
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

;;; ---------------------------------------------------------------- props at a world point (cosmetic)
(declaim (special *volley-spread*))                    ; (lille.lisp's knob, loaded after this file)
(declaim (type f32vec *lb-m* *lb-p*))
(defvar *lb-m* (m4) "A prop's world matrix (LB-SEG).")
(defvar *lb-p* (make-f32 3))

(defun lb-seg (key ax ay az bx by bz w &optional (alpha 1.0))
  "Draw prop KEY (built along +Y, unit length) from A to B, W wide (a line, a beam)."
  (let* ((dx (- bx ax)) (dy (- by ay)) (dz (- bz az)) (l (max 1e-4 (sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
         (ux (/ dx l)) (uy (/ dy l)) (uz (/ dz l))
         (px (if (> (abs uy) 0.9) 1.0 (- uz))) (py 0.0) (pz (if (> (abs uy) 0.9) 0.0 ux))
         (pl (max 1e-4 (sqrt (+ (* px px) (* pz pz))))) (px (/ px pl)) (pz (/ pz pl))
         (qx (- (* uy pz) (* uz py))) (qy (- (* uz px) (* ux pz))) (qz (- (* ux py) (* uy px)))
         (m *lb-m*))
    (setf (aref m 0) (f32 (* w px)) (aref m 1) (f32 (* w py)) (aref m 2) (f32 (* w pz)) (aref m 3) 0f0
          (aref m 4) (f32 dx) (aref m 5) (f32 dy) (aref m 6) (f32 dz) (aref m 7) 0f0
          (aref m 8) (f32 (* w qx)) (aref m 9) (f32 (* w qy)) (aref m 10) (f32 (* w qz)) (aref m 11) 0f0
          (aref m 12) (f32 ax) (aref m 13) (f32 ay) (aref m 14) (f32 az) (aref m 15) 1f0)
    (setf (aref *toon-body* 1) 0f0)
    (draw-weapon key m :alpha (f32 alpha))))

(defun lb-wall (x z yaw &optional (from 0.6))
  "Metres from FROM ahead of (X Z) along YAW to the arena's wall (a line drawn to it)."
  (let ((ux (fwd-x yaw)) (uz (fwd-z yaw)))
    (+ from (ray-room (+ x (* from ux)) (+ z (* from uz)) ux uz *arena-radius*))))

(defun lb-ray (key x y z yaw from len w alpha)
  "A straight prop line along YAW at height Y, FROM .. LEN metres ahead of (X Z), clipped at the wall."
  (let* ((l (min len (lb-wall x z yaw from))) (ux (fwd-x yaw)) (uz (fwd-z yaw)))
    (when (> l from)
      (lb-seg key (+ x (* from ux)) y (+ z (* from uz)) (+ x (* l ux)) y (+ z (* l uz)) w alpha))))

;;; ---------------------------------------------------------------- his draw hook: the aim line, the trumpet
(defun lille-draw (e rdt)
  "His kit's :draw hook (after his body): the aim line of a held X-axis shot (grey while it tracks, jade once locked:
cosmetic, read off FIGHTER-HOLD and his yaw), the volley's five lines, the trumpet over the owl's wind-up."
  (declare (ignore rdt))
  (let* ((f (fighter e)) (mv (and (eq (fighter-state f) :move) (fighter-move f))) (p (pos-of e)) (yaw (yaw-of e)))
    (when mv
      (case (mv-name mv)
        (:lb-x-axis
         (when (eq (fighter-phase f) :hold)
           (let ((locked (>= (fighter-hold f) (getf (mv-params mv) :lock 34))) (v *lb-p*))
             (joint-point! v (model-joints (model e)) (ji :weapon-r) 0f0 0f0 (f32 (- (* 1.75 (body-scale (model-body (model e)))))))
             (let* ((l (lb-wall (aref v 0) (aref v 2) yaw 0.0)))
               (lb-seg (if locked :lb-line-jade :lb-line-grey) (aref v 0) (aref v 1) (aref v 2)
                       (+ (aref v 0) (* l (fwd-x yaw))) (aref v 1) (+ (aref v 2) (* l (fwd-z yaw))) (if locked 0.03 0.015))))))
        (:lb-volley
         (when (eq (fighter-phase f) :hold)
           (let ((locked (>= (fighter-hold f) (getf (mv-params mv) :lock 24))))
             (dolist (a '(-12 -6 0 6 12))
               (lb-ray (if locked :lb-line-jade :lb-line-grey) (aref p 0) 1.6 (aref p 2) (+ yaw (deg (* a (/ *volley-spread* 6.0))))
                       0.6 31.0 (if locked 0.025 0.012) 1.0)))))
        (:lb-trompete
         (when (eq (fighter-phase f) :main)
           (let* ((sf (fighter-sf f)) (k (min 1.0 (/ sf 50.0))) (h 2.6))
             (when (< sf 90)
               (lb-seg :lb-trumpet (- (aref p 0) (* 0.6 (fwd-x yaw))) h (- (aref p 2) (* 0.6 (fwd-z yaw)))
                       (+ (aref p 0) (* 4.4 (fwd-x yaw))) (+ h 0.4) (+ (aref p 2) (* 4.4 (fwd-z yaw))) (* 0.2 k)
                       (max 0.3 k))))))))))

;;; ---------------------------------------------------------------- his hazards' look (kind :lb-fx, :lb-sabaki)
(defun lb-look (hz rdt)
  "His hazards' draw function (HAZARD-DRAW): a shot's line (ink, or jade for an aimed one), the volley's five, a beam (jade,
gold in the owl), a Kikon lane, the SABAKI line's gold blasts along its burning span. Fading over the hazard's life."
  (declare (ignore rdt))
  (let* ((d (hazard-data hz)) (x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz))
         (fade (max 0.0 (- 1.0 (/ (hazard-age hz) (float (max 1 (hazard-life hz)))))))
         (owl (let ((o (hazard-owner hz))) (and (entity-alive-p o) (eq (fighter-form (fighter o)) :shin)))))
    (when (and (lbh-p d) (<= (hazard-delay hz) 0))
      (case (lbh-kind d)
        (:shot (lb-ray (if (lbh-lock d) :lb-line-jade :lb-line) x 1.2 z yaw 0.6 (lbh-len d) (* (lbh-width d) (+ 0.4 fade)) fade))
        (:volley (dolist (a '(-12 -6 0 6 12))
                   (lb-ray :lb-line-jade x 1.6 z (+ yaw (deg (* a (/ *volley-spread* 6.0)))) 0.6 (lbh-len d) (* (lbh-width d) (+ 0.4 fade)) fade)))
        (:beam (lb-ray (if owl :lb-beam-gold :lb-beam-jade) x 1.3 z yaw 0.6 (lbh-len d) (* (lbh-width d) (+ 0.3 (* 0.7 fade))) (* 0.85 fade)))
        (:lane (lb-ray (if owl :lb-beam-gold :lb-line-jade) x 0.05 z yaw 0.6 (lbh-len d) (lbh-width d) (* 0.8 fade)))
        (:sabaki (multiple-value-bind (from to) (lb-sabaki-span (hazard-age hz))
                   (loop for r from (ceiling from) to (floor to)
                         do (let ((bx (+ x (* r (fwd-x yaw)))) (bz (+ z (* r (fwd-z yaw))))
                                  (h (* 1.2 (min 1.0 (/ (- to r) 3.0)))))
                              (when (> h 0.05)
                                (lb-seg :lb-blast bx 0.0 bz bx h bz (* 0.5 (lbh-width d)) 1.0))))))))))
