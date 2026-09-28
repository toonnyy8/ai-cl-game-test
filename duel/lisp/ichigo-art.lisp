;;;; ichigo-art.lisp — KUROSAKI ICHIGO (TYBW) as art data (docs/DUEL_ICHIGO.md §2, §10): his body (a substitute
;;;; Shinigami's black shihakusho, no haori, the orange spiky head, the half-Hollow's single horn on the left; the KESSA
;;;; parts tagged :kessa: the second horn, the faint left marking, the blood-chain links at neck, wrists and ankles; the
;;;; Shikai's short blade tagged :shikai), his weapons (the long cleaver :zangetsu-long with its hole, the Bankai's one
;;;; blade :tensa; the hiltless short blade is a body part in the left fist), every :ic-* pose and clip, his looks (the
;;;; crescents, the chains, the clone, the auras), his four sounds, his brush glyphs and names, and his three
;;;; cinematics. The Getsuga is mono (an ink crescent, a white rim); BLOOD only in KESSA's chains and rims and the
;;;; cinematics' Cero core (docs/STYLE_STORM_DESIGN.md §A.2): no spot hue of his own.
(in-package :duel)
(declaim (special *p1* *p2*))                         ; (flow.lisp's: the auras find their fighter)

;;; ---------------------------------------------------------------- body
;; 1.80 m (scale 1.0), lean (width 0.96); the hurt cylinder r 0.38 / h 1.80. One black mass (the robe and the hakama),
;; white in the under-collar and the tabi; the orange head the only warm thing on the plaza (muted, S <= 0.45: not a
;; spot hue). An anime head x1.2 about the neck's top (~7.4 heads).
(defbody :ichigo (:scale 1.0 :width 0.96 :hunch 0 :hurt-r 0.38 :hurt-h 1.8
                  :girth ((:chest 0.98 1.0 0.95) (:spine 0.92 1.0 0.92) (:head 1.2 1.2 1.2))
                  :palette ((:skin #xD8B8A0) (:black #x16161E) (:hair #xB8733E) (:hair-l #xD89A66) (:white #xECECE8)
                            (:pupil #x5A3A22) (:core #x1A1210) (:shine #xFFFFFF) (:eye #xF2F0EC) (:lid #x141016)
                            (:mouth #x7A3A3C) (:fold #x3A3A46) (:tabi #xE8E8E4) (:sole #x262833) (:brow #x6A3A1C)
                            (:horn #xE8E4D8) (:mark #xF0EEE8) (:chain #x24242C) (:blood #xD0101C) (:blade #x121216)
                            (:edge #xC8CCD4) (:wrap #x2A2A30) (:clench #x141016))
                  :rim (#xFFD8B8 0.14))
  (:pelvis (:box 0.36 0.18 0.25 :c :black)
           (:box 0.37 0.04 0.26 :at (0 0.075 0) :c :black)                                       ; the black sash
           (:cyl 0.23 0.48 :top 0.17 :seg 8 :at (0 -0.22 0) :c :black)                          ; the hakama
           (:box 0.004 0.34 0.004 :at (0.06 -0.26 0.19) :rot (0 0 -4) :c :fold))                ; a pleat
  (:spine (:bevel 0.36 0.25 0.24 0.04 :at (0 0.11 0) :c :black))
  (:chest (:bevel 0.44 0.3 0.27 0.05 :at (0 0.11 0) :c :black)
          (:box 0.17 0.07 0.04 :at (0 0.27 -0.05) :rot (0 -8 0) :c :black)                        ; the collar
          (:box 0.018 0.18 0.01 :at (0.034 0.185 0.14) :rot (0 0 -24) :c :white)                 ; the white under-collar V
          (:box 0.018 0.18 0.01 :at (-0.034 0.185 0.14) :rot (0 0 24) :c :white)
          (:box 0.05 0.12 0.012 :at (0 0.19 0.138) :c :skin)                                     ; the chest in the V
          (:box 0.005 0.17 0.004 :at (0.08 0.07 0.142) :rot (0 0 -10) :c :fold)
          ;; KESSA: the blood-chain links round the neck (ink links, a BLOOD core)
          (:box 0.03 0.018 0.012 :at (0.07 0.27 0.08) :rot (0 30 -20) :c :chain :tag :kessa)
          (:box 0.03 0.018 0.012 :at (-0.07 0.27 0.08) :rot (0 -30 20) :c :chain :tag :kessa)
          (:box 0.03 0.018 0.012 :at (0.0 0.25 0.13) :c :chain :tag :kessa)
          (:glow 1.5 (:box 0.012 0.008 0.014 :at (0.0 0.25 0.132) :c :blood) :kessa)
          (:box 0.016 0.07 0.012 :at (0.04 0.2 0.14) :rot (0 0 -10) :c :chain :tag :kessa)       ; a loose end hanging
          (:glow 1.5 (:box 0.006 0.05 0.014 :at (0.04 0.2 0.142) :rot (0 0 -10) :c :blood) :kessa))
  (:neck (:cyl 0.04 0.17 :at (0 0.06 0) :c :skin))
  ;; the head: a long face, the scowl (the brows drawn down at the middle in every expression), brown eyes; the spiky
  ;; orange hair in cones standing up and back, the fringe falling over the brow; the horn of the half-Hollow on the left
  (:head (:sphere 0.066 :stretch 0.02 :at (0 0.14 -0.012) :seg 12 :c :skin)
         (:bevel 0.106 0.074 0.078 0.02 :at (0 0.126 0.022) :c :skin)
         (:bevel 0.052 0.076 0.068 0.014 :at (0.022 0.078 0.022) :rot (0 0 -20) :c :skin)
         (:bevel 0.052 0.076 0.068 0.014 :at (-0.022 0.078 0.022) :rot (0 0 20) :c :skin)
         (:wedge 0.012 0.022 0.013 :at (0 0.1 0.064) :rot (180 0 0) :c :skin)
         ;; :face-neutral: the scowl
         (:box 0.026 0.014 0.003 :at (0.027 0.119 0.0615) :c :eye :tag :face-neutral)
         (:box 0.026 0.014 0.003 :at (-0.027 0.119 0.0615) :c :eye :tag :face-neutral)
         (:box 0.012 0.014 0.003 :at (0.024 0.119 0.0622) :c :pupil :tag :face-neutral)
         (:box 0.012 0.014 0.003 :at (-0.024 0.119 0.0622) :c :pupil :tag :face-neutral)
         (:box 0.005 0.007 0.003 :at (0.024 0.119 0.0629) :c :core :tag :face-neutral)
         (:box 0.005 0.007 0.003 :at (-0.024 0.119 0.0629) :c :core :tag :face-neutral)
         (:box 0.03 0.0045 0.003 :at (0.027 0.127 0.0636) :rot (0 0 8) :c :lid :tag :face-neutral)
         (:box 0.03 0.0045 0.003 :at (-0.027 0.127 0.0636) :rot (0 0 -8) :c :lid :tag :face-neutral)
         (:box 0.032 0.006 0.003 :at (0.029 0.139 0.0625) :rot (0 0 14) :c :brow :tag :face-neutral)
         (:box 0.032 0.006 0.003 :at (-0.029 0.139 0.0625) :rot (0 0 -14) :c :brow :tag :face-neutral)
         (:box 0.022 0.003 0.003 :at (0 0.071 0.0585) :c :mouth :tag :face-neutral)
         ;; :face-shout
         (:box 0.026 0.012 0.003 :at (0.027 0.118 0.0615) :c :eye :tag :face-shout)
         (:box 0.026 0.012 0.003 :at (-0.027 0.118 0.0615) :c :eye :tag :face-shout)
         (:box 0.011 0.012 0.003 :at (0.023 0.118 0.0622) :c :pupil :tag :face-shout)
         (:box 0.011 0.012 0.003 :at (-0.023 0.118 0.0622) :c :pupil :tag :face-shout)
         (:box 0.034 0.007 0.003 :at (0.028 0.134 0.0625) :rot (0 0 22) :c :brow :tag :face-shout)
         (:box 0.034 0.007 0.003 :at (-0.028 0.134 0.0625) :rot (0 0 -22) :c :brow :tag :face-shout)
         (:box 0.03 0.02 0.003 :at (0 0.068 0.0585) :c :mouth :tag :face-shout)
         (:box 0.026 0.004 0.003 :at (0 0.0755 0.0592) :c :eye :tag :face-shout)
         ;; :face-hurt
         (:box 0.026 0.0045 0.003 :at (0.027 0.121 0.0625) :rot (0 0 14) :c :lid :tag :face-hurt)
         (:box 0.026 0.0045 0.003 :at (0.027 0.114 0.0625) :rot (0 0 -14) :c :lid :tag :face-hurt)
         (:box 0.026 0.0045 0.003 :at (-0.027 0.121 0.0625) :rot (0 0 -14) :c :lid :tag :face-hurt)
         (:box 0.026 0.0045 0.003 :at (-0.027 0.114 0.0625) :rot (0 0 14) :c :lid :tag :face-hurt)
         (:box 0.03 0.005 0.003 :at (0.028 0.138 0.0625) :rot (0 0 -16) :c :brow :tag :face-hurt)
         (:box 0.03 0.005 0.003 :at (-0.028 0.138 0.0625) :rot (0 0 16) :c :brow :tag :face-hurt)
         (:box 0.028 0.011 0.003 :at (0 0.069 0.0585) :c :mouth :tag :face-hurt)
         (:box 0.024 0.005 0.003 :at (0 0.069 0.0592) :c :eye :tag :face-hurt)
         (:box 0.024 0.0012 0.003 :at (0 0.069 0.0598) :c :clench :tag :face-hurt)
         ;; the hair: a cap, the back, and the spikes
         (:sphere 0.074 :stretch 0.02 :at (0 0.152 -0.016) :seg 12 :c :hair)
         (:bevel 0.14 0.1 0.08 0.03 :at (0 0.11 -0.05) :c :hair)
         (:bevel 0.028 0.09 0.09 0.012 :at (0.064 0.12 -0.006) :rot (0 0 -6) :c :hair)
         (:bevel 0.028 0.09 0.09 0.012 :at (-0.064 0.12 -0.006) :rot (0 0 6) :c :hair)
         (:cone 0.036 0.11 :at (0 0.21 -0.02) :rot (0 35 0) :seg 4 :c :hair)
         (:cone 0.034 0.1 :at (0.042 0.2 0.0) :rot (0 20 -38) :seg 4 :c :hair)
         (:cone 0.034 0.1 :at (-0.042 0.2 0.0) :rot (0 20 38) :seg 4 :c :hair)
         (:cone 0.03 0.1 :at (0.062 0.165 -0.03) :rot (0 30 -70) :seg 4 :c :hair)
         (:cone 0.03 0.1 :at (-0.062 0.165 -0.03) :rot (0 30 70) :seg 4 :c :hair)
         (:cone 0.032 0.1 :at (0 0.17 -0.065) :rot (0 80 0) :seg 4 :c :hair)
         (:cone 0.028 0.09 :at (0.04 0.13 -0.072) :rot (0 100 -30) :seg 4 :c :hair)
         (:cone 0.028 0.09 :at (-0.04 0.13 -0.072) :rot (0 100 30) :seg 4 :c :hair)
         (:cone 0.024 0.08 :at (0.03 0.175 0.052) :rot (0 196 12) :seg 4 :c :hair)             ; the fringe
         (:cone 0.024 0.085 :at (-0.018 0.178 0.056) :rot (0 196 -8) :seg 4 :c :hair)
         (:cone 0.02 0.07 :at (0.004 0.168 0.062) :rot (0 190 2) :seg 4 :c :hair)
         (:box 0.006 0.04 0.003 :at (0.02 0.215 0.02) :rot (200 -30 0) :c :hair-l)             ; the lighter strokes
         (:box 0.006 0.034 0.003 :at (-0.03 0.2 0.04) :rot (200 30 0) :c :hair-l)
         ;; the half-Hollow's horn (the Shikai's one, the left); KESSA adds the right one, and the faint left marking
         (:cone 0.022 0.13 :at (-0.05 0.19 0.045) :rot (0 -18 24) :seg 6 :c :horn)
         (:cone 0.022 0.13 :at (0.05 0.19 0.045) :rot (0 -18 -24) :seg 6 :c :horn :tag :kessa)
         (:box 0.004 0.04 0.003 :at (-0.036 0.1 0.064) :rot (0 0 -12) :c :mark :tag :mark)
         (:box 0.004 0.03 0.003 :at (-0.046 0.13 0.058) :rot (0 0 20) :c :mark :tag :mark))
  (:shoulder-r (:bevel 0.12 0.06 0.18 0.02 :at (0.02 -0.02 0) :rot (0 0 -20) :c :black))
  (:shoulder-l (:bevel 0.12 0.06 0.18 0.02 :at (-0.02 -0.02 0) :rot (0 0 20) :c :black))
  (:upper-arm-r (:box 0.13 0.3 0.14 :at (0 -0.15 0) :c :black))
  (:upper-arm-l (:box 0.13 0.3 0.14 :at (0 -0.15 0) :c :black))
  (:lower-arm-r (:box 0.15 0.2 0.16 :at (0 -0.1 0) :c :black) (:box 0.04 0.2 0.18 :at (0 -0.15 -0.05) :rot (0 -10 0) :c :black)
                (:box 0.055 0.08 0.055 :at (0 -0.23 0) :c :skin)
                (:box 0.07 0.02 0.07 :at (0 -0.21 0) :c :chain :tag :kessa)                        ; KESSA: the wrist's links
                (:box 0.018 0.06 0.012 :at (0.03 -0.26 0.02) :rot (0 0 12) :c :chain :tag :kessa)
                (:glow 1.5 (:box 0.006 0.045 0.014 :at (0.03 -0.26 0.022) :rot (0 0 12) :c :blood) :kessa)
                (:box 0.02 0.07 0.014 :at (0.03 -0.33 0.02) :c :chain :tag :kessa)      ; the chain hanging
                (:box 0.014 0.07 0.02 :at (0.03 -0.4 0.02) :c :chain :tag :kessa)
                (:glow 1.5 (:box 0.006 0.12 0.022 :at (0.03 -0.37 0.02) :c :blood) :kessa))
  (:lower-arm-l (:box 0.15 0.2 0.16 :at (0 -0.1 0) :c :black) (:box 0.04 0.2 0.18 :at (0 -0.15 -0.05) :rot (0 -10 0) :c :black)
                (:box 0.055 0.08 0.055 :at (0 -0.23 0) :c :skin)
                (:box 0.07 0.02 0.07 :at (0 -0.21 0) :c :chain :tag :kessa)
                (:box 0.018 0.06 0.012 :at (-0.03 -0.26 0.02) :rot (0 0 -12) :c :chain :tag :kessa)
                (:glow 1.5 (:box 0.006 0.045 0.014 :at (-0.03 -0.26 0.022) :rot (0 0 -12) :c :blood) :kessa)
                (:box 0.02 0.07 0.014 :at (-0.03 -0.33 0.02) :c :chain :tag :kessa)      ; the chain hanging
                (:box 0.014 0.07 0.02 :at (-0.03 -0.4 0.02) :c :chain :tag :kessa)
                (:glow 1.5 (:box 0.006 0.12 0.022 :at (-0.03 -0.37 0.02) :c :blood) :kessa))
  (:hand-r (:bevel 0.06 0.08 0.06 0.016 :at (0 -0.04 0) :c :skin))
  (:hand-l (:bevel 0.06 0.08 0.06 0.016 :at (0 -0.04 0) :c :skin))
  ;; the Shikai's short blade in the left fist: hiltless, stone-knife shaped, ink black with a white edge, held REVERSED
  ;; along the forearm (the :weapon-l joint's +Y, back toward the elbow)
  (:weapon-l (:box 0.03 0.1 0.03 :at (0 0.0 0.0) :c :wrap :tag :shikai)
             (:box 0.1 0.5 0.03 :at (0 0.3 0.05) :c :blade :tag :shikai)                        ; the flat, both ways:
             (:box 0.03 0.5 0.1 :at (0 0.3 0.05) :c :blade :tag :shikai)                        ; it reads from any side
             (:box 0.02 0.5 0.02 :at (0 0.31 0.105) :c :edge :tag :shikai)
             (:box 0.02 0.5 0.02 :at (0.055 0.31 0.05) :c :edge :tag :shikai))
  (:thigh-r (:cyl 0.11 0.44 :top 0.1 :seg 10 :at (0 -0.21 0) :c :black))
  (:thigh-l (:cyl 0.11 0.44 :top 0.1 :seg 10 :at (0 -0.21 0) :c :black))
  (:shin-r (:cyl 0.13 0.3 :top 0.11 :seg 10 :at (0 -0.1 0) :c :black) (:cyl 0.13 0.08 :top 0.12 :seg 10 :at (0 -0.27 0) :c :black)
           (:box 0.075 0.12 0.085 :at (0 -0.37 0) :c :tabi)
           (:box 0.1 0.02 0.1 :at (0 -0.32 0) :c :chain :tag :kessa)                               ; KESSA: the ankle's links
           (:glow 1.5 (:box 0.02 0.006 0.104 :at (0 -0.32 0) :c :blood) :kessa))
  (:shin-l (:cyl 0.13 0.3 :top 0.11 :seg 10 :at (0 -0.1 0) :c :black) (:cyl 0.13 0.08 :top 0.12 :seg 10 :at (0 -0.27 0) :c :black)
           (:box 0.075 0.12 0.085 :at (0 -0.37 0) :c :tabi)
           (:box 0.1 0.02 0.1 :at (0 -0.32 0) :c :chain :tag :kessa)
           (:glow 1.5 (:box 0.02 0.006 0.104 :at (0 -0.32 0) :c :blood) :kessa))
  (:foot-r (:bevel 0.085 0.055 0.21 0.02 :at (0 -0.02 0.05) :c :tabi) (:box 0.095 0.02 0.23 :at (0 -0.05 0.05) :c :sole))
  (:foot-l (:bevel 0.085 0.055 0.21 0.02 :at (0 -0.02 0.05) :c :tabi) (:box 0.095 0.02 0.23 :at (0 -0.05 0.05) :c :sole)))

;;; ---------------------------------------------------------------- weapons
;; Zangetsu, the long blade: a cleaver ~1.4 m, ink black with a steel-white edge, the hole between the hilt and the blade
;; (the true Zangetsu's), a short cloth-wrapped hilt
(defweapon :zangetsu-long (:length 1.55 :base 0.4)
  (:solid (mbc mb #x121216)
          (with-xform (mb (xform :y 0.94 :z 0.06)) (mb-bevel-box mb 0.03 1.12 0.24 0.006))       ; the slab, y 0.38-1.5
          (with-xform (mb (xform :y 1.53 :z 0.02 :pitch 0.5)) (mb-box mb 0.03 0.1 0.16))          ; the slanted tip
          (with-xform (mb (xform :y 0.22 :z -0.035)) (mb-box mb 0.03 0.32 0.05))                  ; beside the hole: the spine
          (with-xform (mb (xform :y 0.22 :z 0.155)) (mb-box mb 0.03 0.32 0.05))                   ; ... and the edge side
          (with-xform (mb (xform :y 0.07 :z 0.06)) (mb-box mb 0.03 0.04 0.24))                    ; the root under the hole
          (mbc mb #x2A2E36)                                                                     ; a dark fuller
          (with-xform (mb (xform :y 0.95 :z -0.02)) (mb-box mb 0.034 1.0 0.02))
          (mbc mb #xC8CCD4)                                                                     ; the white edge
          (with-xform (mb (xform :y 0.8 :z 0.185)) (mb-box mb 0.034 1.44 0.016))
          (mbc mb #xD8D6CC)                                                                     ; the short wrapped hilt
          (with-xform (mb (xform :y -0.14)) (mb-box mb 0.045 0.28 0.045))
          (mbc mb #x2A2A30)
          (loop for i below 4 do (with-xform (mb (xform :y (- -0.03 (* i 0.07)) :roll 0.785)) (mb-box mb 0.032 0.032 0.052)))
          (mbc mb #xD8D6CC)
          (with-xform (mb (xform :y -0.34 :z -0.02 :pitch 0.3)) (mb-box mb 0.035 0.16 0.012))))  ; the loose cloth end

;; Tensa Zangetsu (the Bankai: the two blades overlaid): one long straight blade, white with a thick black line from
;; mid-blade to the hilt (the manga's true Tensa), a black four-pointed guard, a black hilt, a broken chain at the pommel
(defweapon :tensa (:length 1.3 :base 0.3)
  (:solid :ink 0 (mb-blade mb :length 1.2 :width 0.05 :thickness 0.01 :curve 0.004 :blade-color '(0.84 0.86 0.9)
                              :edge-color '(0.97 0.98 1.0) :hilt nil))
  (:solid (mbc mb #x101014)
          (with-xform (mb (xform :y 0.32 :x 0.0)) (mb-box mb 0.014 0.6 0.024))                  ; the black line
          (with-xform (mb (xform :y 0.0)) (mb-box mb 0.03 0.026 0.17))                           ; the guard's cross
          (with-xform (mb (xform :y 0.0)) (mb-box mb 0.12 0.026 0.03))
          (with-xform (mb (xform :y -0.13)) (mb-box mb 0.036 0.24 0.036))                         ; the hilt
          (loop for i below 3 do (with-xform (mb (xform :y (- -0.28 (* i 0.05)) :yaw (* i 1.5708))) (mb-box mb 0.012 0.045 0.03)))))

;;; ---------------------------------------------------------------- poses (his rig notes)
;;; The right hand holds the long blade (the K links, L, the cross's right half), the left the short one (the J links);
;;; a horizontal cut is an arm held out (side ~88) swept by its flex (0 = to its own side, 90 = ahead, 130 = across);
;;; the blade runs on from the arm (hand flex ~ -86). KESSA's one blade is in the right hand; the left throws the chains.
(defpose :ic-stance ()                                 ; Shikai: the cleaver low and back, the short blade out ahead
  (:root :u -0.07) (:pelvis :twist 24) (:spine :flex 10) (:chest :twist -6) (:neck :twist -12) (:head :flex -4 :twist -10)
  (:arm-r :flex 30 :side 26) (:elbow-r :flex 40) (:hand-r :twist 0 :flex -40)
  (:arm-l :flex 50 :side 24) (:elbow-l :flex 70) (:hand-l :flex -20)
  (:thigh-r :flex -12 :side 10) (:thigh-l :flex 28 :side 8) (:knee-r :flex 24) (:knee-l :flex 32))
(defclip :ic-stance (1.6 :loop t :base :ic-stance)
  (0) (0.8 (:root :u -0.085) (:chest :flex 3) (:elbow-l :flex 60)))

(defpose :ic-k-stance ()                               ; KESSA: upright and still, Tensa low at his side, the left hand open
  (:root :u -0.03) (:pelvis :twist 14) (:spine :flex 4) (:chest :twist -4) (:neck :twist -8) (:head :flex 4 :twist -6)
  (:arm-r :flex 12 :side 16) (:elbow-r :flex 12) (:hand-r :twist 0 :flex -70)
  (:arm-l :flex 8 :side 20) (:elbow-l :flex 24) (:hand-l :flex -10)
  (:thigh-r :flex 8 :side 6) (:thigh-l :flex -4 :side 8) (:knee-r :flex 10) (:knee-l :flex 8))
(defclip :ic-k-stance (2.4 :loop t :base :ic-k-stance)
  (0) (1.2 (:root :u -0.04) (:head :flex 6) (:elbow-l :flex 28)))

;;; ---------------------------------------------------------------- the Shikai grid (§3.2)
(defpose :ic-q1-hit (:base :ic-stance)                 ; J1 KOKIBA: the short blade flicked across, stepping in
  (:root :f 0.26 :u -0.13 :yaw -4) (:pelvis :twist 18) (:spine :flex 10) (:chest :twist -14) (:neck :twist 6) (:head :twist 4)
  (:arm-l :side 88 :flex 104) (:elbow-l :flex 6) (:hand-l :flex -86)
  (:arm-r :flex -30 :side 30) (:elbow-r :flex 16) (:hand-r :flex -40)
  (:thigh-l :flex 46 :side 4) (:knee-l :flex 46) (:thigh-r :flex -24) (:knee-r :flex 22))
(defstrike :ic-q1 (7 3 12 :base :ic-stance)
  (0)
  (3 (:root :u -0.08 :yaw 10) (:chest :twist 30) (:neck :twist -10) (:arm-l :side 88 :flex -6) (:elbow-l :flex 18)
     (:hand-l :flex -84) (:arm-r :flex -20 :side 26))
  (:s :snap :ic-q1-hit)
  (8 (:chest :twist -18) (:arm-l :flex 110) (:root :f 0.28))
  (:a (:chest :twist -17) (:arm-l :flex 108) (:root :f 0.28))
  (16 (:chest :twist -10) (:arm-l :side 50 :flex 70) (:elbow-l :flex 30) (:hand-l :flex -70) (:root :f 0.12 :u -0.1))
  (:end :ic-stance))

(defpose :ic-q2-hit (:base :ic-stance)                 ; J2 KAESHI: the wrist turned, the short blade back across
  (:root :f 0.22 :u -0.11 :yaw 6) (:pelvis :twist 26) (:spine :flex 8) (:chest :twist 16) (:neck :twist -8)
  (:arm-l :side 88 :flex 36) (:elbow-l :flex 6 :twist -160) (:hand-l :flex -86)
  (:arm-r :flex -24 :side 34) (:elbow-r :flex 20) (:hand-r :flex -40)
  (:thigh-l :flex 38) (:knee-l :flex 40) (:thigh-r :flex -20) (:knee-r :flex 22))
(defstrike :ic-q2 (7 3 13 :base :ic-stance)
  (0)
  (3 (:root :u -0.09 :yaw -8) (:chest :twist -26) (:arm-l :side 88 :flex 126) (:elbow-l :flex 20 :twist -160) (:hand-l :flex -80))
  (:s :snap :ic-q2-hit)
  (8 (:chest :twist 18) (:arm-l :flex 32) (:root :f 0.24))
  (:a (:chest :twist 17) (:arm-l :flex 34) (:root :f 0.23))
  (17 (:chest :twist 6) (:arm-l :side 40 :flex 44) (:elbow-l :flex 30 :twist -40) (:hand-l :flex -64) (:root :f 0.08 :u -0.08))
  (:end :ic-stance))

(defstrike :ic-spin (8 3 18 :base :ic-stance)          ; J3 SOSEN-GIRI: a full turn, the cleaver high and the short blade low
  (0)
  (4 (:root :u -0.12 :yaw 18) (:knees :flex 40) (:chest :twist 30) (:arm-l :side 88 :flex -10) (:elbow-l :flex 6)
     (:arm-r :side 70 :flex -20) (:elbow-r :flex 10) (:hand-r :flex -80))
  (6 (:root :u -0.14 :yaw 28) (:chest :twist 36))
  (:s :snap (:root :yaw -360 :u -0.04 :f 0.3) (:pelvis :twist 16) (:chest :twist -8) (:neck :twist 8)
      (:arm-l :side 70 :flex 40) (:elbow-l :flex 4) (:hand-l :flex -88) (:arm-r :side 100 :flex 30) (:elbow-r :flex 4)
      (:hand-r :flex -88) (:thigh-l :flex 20) (:knee-l :flex 24) (:thigh-r :flex 10 :side 14) (:knee-r :flex 30))
  (:a (:root :yaw -382 :u -0.05 :f 0.32) (:chest :twist -12))
  (22 (:root :yaw -372 :u -0.08 :f 0.3) (:arm-l :side 40 :flex 40) (:elbow-l :flex 30) (:arm-r :side 40 :flex 10) (:elbow-r :flex 20))
  (:end :ic-stance (:root :yaw -360)))

(defpose :ic-f1-hit (:base :ic-stance)                 ; K1 OKIBA: the cleaver's waist-high sweep, a deep step
  (:root :f 0.44 :u -0.2 :yaw 6) (:pelvis :twist 8) (:spine :flex 14) (:chest :twist 20) (:neck :twist -18) (:head :twist -14)
  (:arm-r :side 88 :flex 118) (:elbow-r :flex 4) (:hand-r :twist 0 :flex -86)
  (:arm-l :flex -20 :side 50) (:elbow-l :flex 30) (:hand-l :flex -60)
  (:thigh-r :flex 62 :side 4) (:knee-r :flex 62) (:thigh-l :flex -32 :side 8) (:knee-l :flex 10))
(defstrike :ic-f1 (16 4 20 :base :ic-stance)
  (0)
  (7 (:root :u -0.12 :yaw -14) (:chest :twist -34) (:neck :twist 14) (:arm-r :side 80 :flex -34) (:elbow-r :flex 20)
     (:hand-r :twist 0 :flex -80) (:arm-l :flex 50 :side 20) (:elbow-l :flex 50) (:knees :flex 36))
  (13 (:root :u -0.14 :yaw -18) (:chest :twist -40) (:arm-r :flex -40))
  (:s :snap :ic-f1-hit)
  (18 (:arm-r :flex 126) (:chest :twist 26))
  (:a (:arm-r :flex 128) (:chest :twist 27))
  (32 (:root :f 0.24 :u -0.14) (:chest :twist 10) (:arm-r :side 50 :flex 60) (:elbow-r :flex 20) (:hand-r :flex -60)
      (:thigh-r :flex 40) (:knee-r :flex 40))
  (:end :ic-stance))

(defpose :ic-f2-hit (:base :ic-stance)                 ; K2 SHOGA: up from the floor, the cleaver swept high
  (:root :u 0.02 :f 0.2) (:pelvis :twist 16) (:spine :flex -12) (:chest :twist 10) (:neck :twist -10) (:head :flex -20)
  (:arm-r :flex 150 :side 18) (:elbow-r :flex 6) (:hand-r :twist 0 :flex -80)
  (:arm-l :flex 10 :side 60) (:elbow-l :flex 20)
  (:thigh-r :flex 26) (:knee-r :flex 18) (:thigh-l :flex -10) (:knee-l :flex 6))
(defstrike :ic-f2 (20 4 24 :base :ic-stance)
  (0)
  (10 (:root :u -0.2) (:spine :flex 36) (:chest :twist -16) (:neck :twist 10) (:head :flex 10) (:arm-r :flex 16 :side 10)
      (:elbow-r :flex 10) (:hand-r :twist 0 :flex -40) (:arm-l :flex 40 :side 30) (:knees :flex 56) (:thighs :flex 34))
  (17 (:root :u -0.22) (:spine :flex 38) (:arm-r :flex 10))
  (:s :snap :ic-f2-hit)
  (22 (:arm-r :flex 158) (:root :u 0.03))
  (:a (:arm-r :flex 156) (:root :u 0.03))
  (38 (:root :u -0.06 :f 0.1) (:spine :flex 4) (:arm-r :flex 90 :side 20) (:elbow-r :flex 20) (:hand-r :flex -60) (:knees :flex 22))
  (:end :ic-stance))

(defpose :ic-drop-hit (:base :ic-stance)               ; K3 RAKUGA: both hands on the long blade, dropped through him
  (:root :u -0.22 :f 0.38) (:pelvis :twist 10) (:spine :flex 32) (:chest :twist 0) (:neck :twist -6) (:head :flex -20)
  (:arm-r :flex 96 :side 0) (:elbow-r :flex 6) (:hand-r :twist 0 :flex -72)
  (:arm-l :flex 94 :side -12) (:elbow-l :flex 16) (:hand-l :flex -30)
  (:thigh-r :flex 60 :side 6) (:knee-r :flex 62) (:thigh-l :flex -24 :side 8) (:knee-l :flex 24))
(defstrike :ic-drop (21 5 34 :base :ic-stance)
  (0)
  (8 (:root :u 0.03) (:pelvis :twist 14) (:arm-r :flex 176 :side 6) (:elbow-r :flex 12) (:hand-r :twist 0 :flex -40)
     (:arm-l :flex 168 :side -14) (:elbow-l :flex 24) (:spine :flex -12) (:head :flex -30) (:thigh-r :flex 14) (:knee-r :flex 12))
  (17 (:root :u 0.04) (:arm-r :flex 180) (:arm-l :flex 172) (:spine :flex -15))
  (:s :snap :ic-drop-hit)
  (23 (:spine :flex 40) (:root :u -0.26 :f 0.4) (:arm-r :flex 50) (:arm-l :flex 48))
  (:a (:spine :flex 38) (:root :u -0.25 :f 0.4) (:arm-r :flex 52) (:arm-l :flex 50))
  (44 (:spine :flex 30) (:root :u -0.22 :f 0.36))
  (52 (:spine :flex 12) (:root :u -0.1 :f 0.14) (:arm-r :flex 20 :side 20) (:elbow-r :flex 20) (:hand-r :flex -50)
      (:arm-l :flex 40 :side 20) (:elbow-l :flex 50) (:thigh-r :flex 34) (:knee-r :flex 32))
  (:end :ic-stance))
(pushnew :ic-drop *grip-clips*)

(defpose :ic-cross-hit (:base :ic-stance)              ; the CROSS (J2s / K2s, SOGA, the JUJI strike): both blades in an X
  (:root :f 0.36 :u -0.16) (:pelvis :twist 4) (:spine :flex 20) (:chest :twist 0) (:neck :twist 0) (:head :flex -10)
  (:arm-r :side 30 :flex 80) (:elbow-r :flex 4) (:hand-r :twist -40 :flex -80)
  (:arm-l :side 30 :flex 80) (:elbow-l :flex 4) (:hand-l :twist -40 :flex -80)
  (:thigh-r :flex 56) (:knee-r :flex 58) (:thigh-l :flex -26) (:knee-l :flex 16))
(defstrike :ic-cross (7 3 24 :base :ic-stance)
  (0)
  (3 (:root :u -0.04 :f 0.1) (:spine :flex -8) (:arm-r :side 70 :flex 160) (:elbow-r :flex 20) (:hand-r :flex -60)
     (:arm-l :side 70 :flex 160) (:elbow-l :flex 20) (:hand-l :flex -60) (:head :flex -16))
  (:s :snap :ic-cross-hit)
  (:a (:root :f 0.38) (:arm-r :flex 76) (:arm-l :flex 76))
  (26 (:root :f 0.2 :u -0.1) (:arm-r :side 40 :flex 30) (:elbow-r :flex 20) (:arm-l :side 40 :flex 40) (:elbow-l :flex 40))
  (:end :ic-stance))

;;; ---------------------------------------------------------------- the rest of the Shikai (§3.3)
(defpose :ic-getsuga-hit (:base :ic-stance)            ; L GETSUGA TENSHO: the cleaver swung up and out, one-handed
  (:root :f 0.3 :u -0.16 :yaw 8) (:pelvis :twist 4) (:spine :flex 4) (:chest :twist 24) (:neck :twist -20) (:head :flex -8 :twist -16)
  (:arm-r :side 70 :flex 140) (:elbow-r :flex 4) (:hand-r :twist 0 :flex -86)
  (:arm-l :flex -30 :side 44) (:elbow-l :flex 30) (:hand-l :flex -50)
  (:thigh-r :flex 50) (:knee-r :flex 52) (:thigh-l :flex -30) (:knee-l :flex 10))
(defstrike :ic-getsuga (14 0 24 :base :ic-stance)
  (0)
  (8 (:root :u -0.16 :yaw -16) (:spine :flex 20) (:chest :twist -36) (:neck :twist 14) (:arm-r :side 60 :flex -40) (:elbow-r :flex 10)
     (:hand-r :twist 0 :flex -70) (:arm-l :flex 50 :side 20) (:elbow-l :flex 60) (:knees :flex 44))
  (12 (:root :u -0.17 :yaw -18) (:arm-r :flex -46) (:chest :twist -40))
  (:s :snap :ic-getsuga-hit)
  (20 (:arm-r :flex 150) (:chest :twist 28))
  (30 (:root :f 0.2 :u -0.12) (:arm-r :side 50 :flex 90) (:elbow-r :flex 20) (:hand-r :flex -60) (:chest :twist 10))
  (:end :ic-stance))

(defpose :ic-juji-pose (:base :ic-stance)              ; SP1 JUJISHO: both blades drawn back, crossed behind him
  (:root :u -0.18 :f -0.05) (:pelvis :twist 10) (:spine :flex 22) (:chest :twist 0) (:head :flex 4)
  (:arm-r :side 60 :flex -50) (:elbow-r :flex 20) (:hand-r :flex -60)
  (:arm-l :side 60 :flex -50) (:elbow-l :flex 20) (:hand-l :flex -60)
  (:knees :flex 50) (:thigh-r :flex 36) (:thigh-l :flex 10))
(defstrike :ic-juji (20 0 26 :base :ic-stance)
  (0)
  (6 :ic-juji-pose)
  (10 :ic-juji-pose (:root :u -0.2))
  (12 :snap (:root :u -0.16 :f 0.1) (:chest :twist 24) (:arm-r :side 70 :flex 140) (:elbow-r :flex 4) (:hand-r :flex -86)
      (:arm-l :side 60 :flex -50) (:spine :flex 10) (:knees :flex 44))
  (17 (:chest :twist 26) (:arm-r :flex 146))
  (:s :snap (:root :u -0.16 :f 0.3) (:chest :twist -20) (:arm-l :side 70 :flex 140) (:elbow-l :flex 4) (:hand-l :flex -86)
      (:arm-r :side 70 :flex 120) (:thigh-r :flex 50) (:knee-r :flex 52) (:thigh-l :flex -26) (:knee-l :flex 12))
  (34 (:root :f 0.2 :u -0.1) (:chest :twist 0) (:arm-l :side 50 :flex 70) (:arm-r :side 50 :flex 70))
  (:end :ic-stance))

(defclip :ic-breaker (0.4 :loop t :base :ic-stance)    ; the Breaker's dash: low, both blades trailing
  (0 (:root :u -0.12) (:pelvis :twist 8) (:spine :flex 36) (:chest :twist 0) (:head :flex -28)
     (:arm-r :flex -46 :side 30) (:elbow-r :flex 16) (:hand-r :flex -90) (:arm-l :flex -46 :side 30) (:elbow-l :flex 16) (:hand-l :flex -90)
     (:thigh-r :flex 45) (:knee-r :flex 20) (:thigh-l :flex -30) (:knee-l :flex 45))
  (0.2 (:root :u -0.08) (:thigh-l :flex 45) (:knee-l :flex 20) (:thigh-r :flex -30) (:knee-r :flex 45)))

(defstrike :ic-mine (8 4 18 :base :ic-stance)          ; I MINEUCHI: the cleaver's flat slammed sideways
  (0 (:root :u -0.12) (:chest :twist -36) (:arm-r :side 80 :flex -30) (:elbow-r :flex 20) (:hand-r :twist 90 :flex -80))
  (5 (:chest :twist -40) (:arm-r :flex -36))
  (:s :snap (:root :f 0.34 :u -0.14) (:chest :twist 24) (:arm-r :side 88 :flex 100) (:elbow-r :flex 4) (:hand-r :twist 90 :flex -86)
      (:arm-l :flex -20 :side 50) (:thigh-r :flex 50) (:knee-r :flex 50) (:thigh-l :flex -24))
  (:a (:root :f 0.36) (:arm-r :flex 104))
  (24 (:root :f 0.16 :u -0.1) (:arm-r :side 50 :flex 60) (:chest :twist 8))
  (:end :ic-stance))

(defclip :ic-intro (2.0 :base :ic-stance)              ; both blades brought out from behind, crossed, then down
  (0 (:root :u -0.02) (:pelvis :twist 10) (:chest :twist 0) (:head :flex 10) (:arm-r :flex 160 :side 10) (:elbow-r :flex 120)
     (:hand-r :flex -20) (:arm-l :flex 160 :side 10) (:elbow-l :flex 120) (:hand-l :flex -20))
  (0.5 (:head :flex 0) (:arm-r :flex 150 :side 30) (:elbow-r :flex 60) (:arm-l :flex 150 :side 30) (:elbow-l :flex 60))
  (0.9 :snap (:root :u -0.1 :f 0.1) (:spine :flex 16) (:arm-r :side 30 :flex 80) (:elbow-r :flex 4) (:hand-r :twist -40 :flex -80)
       (:arm-l :side 30 :flex 80) (:elbow-l :flex 4) (:hand-l :twist -40 :flex -80) (:knees :flex 30))
  (1.4 (:root :u -0.1 :f 0.1))
  (2.0 :ic-stance))

(defclip :ic-win (2.0 :base :ic-stance)                ; the cleaver swung onto his shoulder, the short blade lowered
  (0)
  (0.4 :snap (:arm-r :side 30 :flex 150) (:elbow-r :flex 120) (:hand-r :flex -10) (:chest :twist 10))
  (0.9 (:root :u -0.01 :yaw -16) (:pelvis :twist 8) (:spine :flex 2) (:chest :twist 4) (:neck :twist 14) (:head :flex 4 :twist 18)
       (:arm-r :side 40 :flex 140) (:elbow-r :flex 130) (:hand-r :flex 0) (:arm-l :flex 6 :side 12) (:elbow-l :flex 10) (:hand-l :flex -80)
       (:thigh-r :flex 4) (:thigh-l :flex -4) (:knees :flex 4))
  (2.0 (:root :u -0.01 :yaw -16) (:head :flex 6 :twist 20)))

(defclip :ic-awaken (2.8 :base :ic-stance)             ; the awakening: head down, the blades lowered, the short blade brought
  (0 (:root :u -0.02) (:spine :flex 16) (:head :flex 30) (:arm-r :flex 10 :side 14) (:elbow-r :flex 10) (:hand-r :flex -80)   ; into
     (:arm-l :flex 10 :side 14) (:elbow-l :flex 10) (:hand-l :flex -80) (:knees :flex 8))                                      ; the
  (0.9 (:head :flex 26) (:arm-r :flex 60 :side 0) (:elbow-r :flex 40) (:hand-r :twist -90 :flex -20)                            ; long
       (:arm-l :flex 60 :side -10) (:elbow-l :flex 50) (:hand-l :twist 90 :flex -20))                                           ; one's
  (1.1 :snap (:arm-l :flex 62 :side -18) (:elbow-l :flex 60))                                                                  ; hole
  (1.8 (:spine :flex -6) (:chest :flex -10) (:head :flex -20) (:arm-r :flex 20 :side 20) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -80)
       (:arm-l :flex 20 :side 60) (:elbow-l :flex 10) (:hand-l :flex 0))
  (2.8 (:spine :flex -8) (:head :flex -22) (:arm-l :side 64)))

;;; ---------------------------------------------------------------- KESSA's own motions (§4.4, §4.5)
(defpose :ic-k-thrust-hit (:base :ic-k-stance)         ; J1 KUSARI-ZUKI: the one-handed thrust, the chain paying out
  (:root :f 0.34 :u -0.12) (:pelvis :twist 16) (:spine :flex 10) (:chest :twist 10) (:neck :twist -20) (:head :flex -6 :twist -16)
  (:arm-r :flex 98 :side 2) (:elbow-r :flex 0) (:hand-r :twist -20 :flex -88)
  (:arm-l :flex -30 :side 40) (:elbow-l :flex 30) (:hand-l :flex -20)
  (:thigh-r :flex 50 :side 4) (:knee-r :flex 50) (:thigh-l :flex -28) (:knee-l :flex 6))
(defstrike :ic-k-thrust (10 3 12 :base :ic-k-stance)
  (0)
  (5 (:root :u -0.08 :f -0.04) (:chest :twist -20) (:arm-r :flex 10 :side 10) (:elbow-r :flex 110) (:hand-r :twist -10 :flex -70)
     (:arm-l :flex 40 :side 20) (:knees :flex 30))
  (:s :snap :ic-k-thrust-hit)
  (:a (:root :f 0.35) (:arm-r :flex 99))
  (20 (:root :f 0.14 :u -0.06) (:arm-r :flex 40 :side 12) (:elbow-r :flex 20) (:hand-r :flex -70))
  (:end :ic-k-stance))

(defpose :ic-k-lash-hit (:base :ic-k-stance)           ; J2 KUSARI-NAGI: the chain whipped back across from the left wrist
  (:root :f 0.18 :u -0.08 :yaw 6) (:pelvis :twist 20) (:chest :twist 20) (:neck :twist -12)
  (:arm-l :side 88 :flex 30) (:elbow-l :flex 4) (:hand-l :flex -40)
  (:arm-r :flex 20 :side 30) (:elbow-r :flex 20) (:hand-r :flex -70)
  (:thigh-l :flex 30) (:knee-l :flex 32) (:thigh-r :flex -16))
(defstrike :ic-k-lash (9 3 13 :base :ic-k-stance)
  (0)
  (4 (:root :yaw -8) (:chest :twist -24) (:arm-l :side 88 :flex 130) (:elbow-l :flex 30) (:hand-l :flex -20))
  (:s :snap :ic-k-lash-hit)
  (:a (:arm-l :flex 24))
  (18 (:chest :twist 6) (:arm-l :side 40 :flex 30) (:elbow-l :flex 30))
  (:end :ic-k-stance))

(defstrike :ic-k-wrap (10 3 18 :base :ic-k-stance)     ; J3 KUSARI-MAKI: a turn, the blade out, the chain wrapping round him
  (0)
  (5 (:root :u -0.08 :yaw -20) (:chest :twist -30) (:arm-r :side 80 :flex -10) (:elbow-r :flex 6) (:hand-r :flex -86)
     (:arm-l :side 60 :flex 60) (:knees :flex 24))
  (:s :snap (:root :yaw 360 :u -0.04 :f 0.2) (:chest :twist 10) (:arm-r :side 90 :flex 40) (:elbow-r :flex 0) (:hand-r :flex -88)
      (:arm-l :side 80 :flex 20) (:elbow-l :flex 10))
  (:a (:root :yaw 380 :f 0.22))
  (24 (:root :yaw 370 :u -0.05) (:arm-r :side 40 :flex 20) (:elbow-r :flex 16) (:arm-l :side 30 :flex 10))
  (:end :ic-k-stance (:root :yaw 360)))

(defstrike :ic-k-parry (4 12 24 :base :ic-k-stance)    ; U KUSARI-TATE: chest open, arms flung wide, the chains flaring
  (0 (:root :u -0.06) (:spine :flex 12) (:arm-r :flex 30 :side 20) (:arm-l :flex 30 :side 20))
  (:s :snap (:root :u -0.1) (:spine :flex -6) (:chest :flex -8) (:head :flex -12) (:arm-r :side 70 :flex 30) (:elbow-r :flex 10)
      (:hand-r :flex -70) (:arm-l :side 76 :flex 30) (:elbow-l :flex 10) (:hand-l :flex 10) (:knees :flex 30) (:thighs :flex 14))
  (:a (:root :u -0.1) (:arm-r :side 72) (:arm-l :side 78))
  (:end :ic-k-stance))

(defpose :ic-k-yank-hit (:base :ic-k-stance)           ; HIKI-GUSARI / KUSARI-BIKI: the left fist hauled back, the blade out
  (:root :f -0.1 :u -0.16) (:pelvis :twist 30) (:spine :flex 16) (:chest :twist -30) (:neck :twist 20) (:head :flex -6 :twist 16)
  (:arm-l :flex -40 :side 30) (:elbow-l :flex 80) (:hand-l :flex -20)
  (:arm-r :flex 80 :side 10) (:elbow-r :flex 10) (:hand-r :flex -86)
  (:thigh-r :flex 40) (:knee-r :flex 44) (:thigh-l :flex -20) (:knee-l :flex 30))
(defstrike :ic-k-yank (6 3 20 :base :ic-k-stance)
  (0 (:arm-l :flex 90 :side 10) (:elbow-l :flex 4) (:hand-l :flex -10) (:chest :twist 20))
  (:s :snap :ic-k-yank-hit)
  (:a (:root :f -0.12))
  (22 (:root :f -0.04 :u -0.08) (:arm-l :flex 10 :side 20) (:elbow-l :flex 40) (:chest :twist -8))
  (:end :ic-k-stance))

(defstrike :ic-k-wall (16 0 24 :base :ic-k-stance)     ; SP2 KUSARI-GAKI: Tensa driven into the plaza, chains ripping up
  (0)
  (8 (:root :u -0.02) (:arm-r :flex 170 :side 10) (:elbow-r :flex 20) (:hand-r :twist 180 :flex 20) (:spine :flex -8) (:head :flex -20))
  (:s :snap (:root :u -0.3) (:spine :flex 40) (:arm-r :flex 60 :side 6) (:elbow-r :flex 30) (:hand-r :twist 160 :flex 10)
      (:arm-l :flex 16 :side 50) (:elbow-l :flex 30) (:knees :flex 70) (:thighs :flex 44) (:head :flex 10))
  (30 (:root :u -0.26))
  (:end :ic-k-stance))

;;; ---------------------------------------------------------------- looks (cosmetic: RND01, the fx clock)
(defun-fast vfx-ic-crescent (x y z yaw w k tilt core)
  "A Getsuga crescent at (x y z) (its middle), flying along YAW, W m tip to tip, its tips TILT (-1..1) up / down: an ink
crescent bulging forward, a white rim (CORE 0), a BLOOD rim (1: KESSA's), a BLOOD core in a white rim (2: the Gran
Rey Cero); presence K."
  (with-floats (x y z yaw w k tilt)
    (let* ((fx (- (f-sin yaw))) (fz (- (f-cos yaw))) (px (- fz)) (pz fx) (hw (* 0.5f0 w)) (dr (drawing-no))
           (dy (* 0.3f0 w tilt)) (x0 (- x (* hw px))) (z0 (- z (* hw pz))) (x1 (+ x (* hw px))) (z1 (+ z (* hw pz)))
           (bx (+ x (* 0.5f0 w fx))) (bz (+ z (* 0.5f0 w fz))) (rw (* 0.035f0 w)) (ahead (* 0.04f0 w)))
      (declare (single-float fx fz px pz hw dr dy x0 z0 x1 z1 bx bz rw ahead))
      (fx-crescent x0 (- y dy) z0 x1 (+ y dy) z1 bx y bz (* 0.15f0 w) :lens 0.06f0 (+ 300f0 dr) +pal-ink+ k :push 0.1f0)
      (fx-crescent (+ x0 (* ahead fx)) (- y dy) (+ z0 (* ahead fz)) (+ x1 (* ahead fx)) (+ y dy) (+ z1 (* ahead fz))
                   (+ bx (* 1.5f0 ahead fx)) y (+ bz (* 1.5f0 ahead fz)) rw :lens 0.04f0 (+ 310f0 dr)
                   (if (= (the fixnum core) 1) +pal-blood+ +pal-hit+) k :push 0.16f0)
      (when (= (the fixnum core) 2)
        (fx-crescent x0 (- y dy) z0 x1 (+ y dy) z1 (+ bx (* ahead fx)) y (+ bz (* ahead fz)) (* 0.06f0 w) :lens 0.05f0 (+ 320f0 dr)
                     +pal-blood+ k :push 0.13f0)))
    nil))

(defun-fast vfx-ic-chain (x0 y0 z0 x1 y1 z1 k)
  "A blood chain from (x0 y0 z0) to (x1 y1 z1): an ink line of links (shards turned alternately), a BLOOD core, presence K."
  (with-floats (x0 y0 z0 x1 y1 z1 k)
    (let* ((dx (- x1 x0)) (dy (- y1 y0)) (dz (- z1 z0)) (l (f-max 0.01f0 (f-sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
           (ux (/ dx l)) (uy (/ dy l)) (uz (/ dz l)) (n (min 40 (max 2 (f->i (/ l 0.14f0))))) (dr (drawing-no)))
      (declare (single-float dx dy dz l ux uy uz dr) (fixnum n))
      (dotimes (i n)
        (let* ((u (/ (+ 0.5f0 (i->f i)) (i->f n))) (px (+ x0 (* u dx))) (py (+ y0 (* u dy))) (pz (+ z0 (* u dz))))
          (declare (single-float u px py pz))
          (fx-shard px py pz ux uy uz 0.16f0 (if (evenp i) 0.045f0 0.02f0) 0.05f0 (+ (i->f i) 400f0 dr) +pal-ink+ k)
          (when (evenp i) (fx-shard px py pz ux uy uz 0.08f0 0.012f0 0.05f0 (+ (i->f i) 460f0) +pal-blood+ k :push 0.14f0)))))
    nil))

(defun-fast vfx-ic-cero (x y z r k dt)
  "The Gran Rey Cero gathered on the blade (the base Kikon): a BLOOD core in an ink ring, sparks sucked in."
  (with-floats (x y z r k dt)
    (let ((dr (drawing-no)))
      (declare (single-float dr))
      (fx-disc x y z (* 1.2f0 r) 0.12f0 (+ 500f0 dr) +pal-ink+ k)
      (fx-disc x y z r 0.15f0 (+ 510f0 dr) +pal-blood+ k :push 0.05f0)
      (fx-disc x y z (* 0.35f0 r) 0.05f0 520f0 +pal-hit+ k :push 0.1f0)
      (dotimes (i (n-of (* 40f0 k) dt))
        (let ((a (rnd-range 0f0 6.2832f0)) (b (rnd-range -1f0 1f0)))
          (declare (single-float a b))
          (%t-shard (+ x (* 3f0 r (f-cos a))) (+ y (* 2f0 r b)) (+ z (* 3f0 r (f-sin a))) (* -6f0 r (f-cos a)) (* -4f0 r b)
                    (* -6f0 r (f-sin a)) 0.3f0 (rnd-range 0.03f0 0.06f0) 0f0 +pal-blood+)))
      (%light x y z 0.9f0 0.08f0 0.1f0 4f0 (* 1.5f0 k) 7))
    nil))

(defun ichigo-at (x z)
  "The fighter standing at (X Z) (an aura's own: DRAW-FIGHTER passes his feet), or NIL."
  (dolist (e (list *p1* *p2*))
    (when (and e (entity-alive-p e) (fighter e))
      (let ((p (pos-of e))) (when (and (< (abs (- (aref p 0) x)) 1e-3) (< (abs (- (aref p 2) z)) 1e-3)) (return e))))))

(declaim (type f32vec *ic-v* *ic-w*))
(defvar *ic-v* (make-f32 3) "A world point (a chain's anchor).")
(defvar *ic-w* (make-f32 3) "A world point (a chain's end).")

(defun ic-joint (e j &optional (out *ic-v*) (lx 0f0) (ly 0f0) (lz 0f0))
  "OUT = the world point of E's joint J (a local offset LX LY LZ)."
  (joint-point! out (model-joints (model e)) j lx ly lz) out)

;;; the hazards' draw functions (HAZARD-DRAW: (fn hazard rdt))
(defun ic-wave-k (hz)
  "A flying crescent's presence: whole while it flies, eroding over its last 8 f (and gone once spent)."
  (min 0.95 (/ (max 0 (- (hazard-life hz) (hazard-age hz))) 8.0)))

(defun ichigo-getsuga-look (hz rdt)
  "GETSUGA TENSHO: the ink crescent, its white rim, as wide as its hit box."
  (declare (ignore rdt))
  (when (<= (hazard-delay hz) 0)
    (vfx-ic-crescent (hazard-x hz) 1.2 (hazard-z hz) (hazard-yaw hz) (* 2 (hazard-size hz)) (ic-wave-k hz) 0.9 0)))

(defun ichigo-juji-look (hz rdt)
  "GETSUGA JUJISHO: the two crescents crossed into an X."
  (declare (ignore rdt))
  (when (<= (hazard-delay hz) 0)
    (let ((k (ic-wave-k hz)) (w (* 2 (hazard-size hz))))
      (vfx-ic-crescent (hazard-x hz) 1.1 (hazard-z hz) (hazard-yaw hz) w k 0.8 0)
      (vfx-ic-crescent (hazard-x hz) 1.1 (hazard-z hz) (hazard-yaw hz) w k -0.8 0))))

(defun ichigo-form-look (hz rdt)
  "JUJISHO's first crescent forming on the long blade before the fusion."
  (declare (ignore rdt))
  (vfx-ic-crescent (hazard-x hz) 1.2 (hazard-z hz) (hazard-yaw hz) (* (hazard-size hz) (min 1.0 (/ (hazard-age hz) 4.0)))
                   0.9 0.8 0))

(defun ichigo-giant-look (hz rdt)
  "The giant Getsuga (KESSA's L): a bigger ink crescent with a BLOOD rim."
  (declare (ignore rdt))
  (when (<= (hazard-delay hz) 0)
    (vfx-ic-crescent (hazard-x hz) 1.5 (hazard-z hz) (hazard-yaw hz) (* 2 (hazard-size hz)) (ic-wave-k hz) 0.8 1)))

(defun ichigo-residue-look (hz rdt)
  "残月 the residue: the crescent hanging still where the wave ended, pulsing, fading over its last 20 f."
  (declare (ignore rdt))
  (when (<= (hazard-delay hz) 0)
    (let ((k (* (min 0.9 (/ (- (hazard-life hz) (hazard-age hz)) 20.0)) (+ 0.75 (* 0.2 (sin (* 0.3 (hazard-age hz))))))))
      (vfx-ic-crescent (hazard-x hz) 1.5 (hazard-z hz) (hazard-yaw hz) (* 2 (hazard-size hz)) (max 0.02 k) 0.8 1))))

(defun ichigo-wall-look (hz rdt)
  "KUSARI-GAKI: chains ripping up out of the plaza along the wall, standing, then falling slack over its last 20 f."
  (declare (ignore rdt))
  (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (hw (hazard-size hz)) (px (- (fwd-z yaw))) (pz (fwd-x yaw))
         (rise (min 1.0 (/ (hazard-age hz) 6.0))) (k (max 0.02 (min 0.95 (/ (- (hazard-life hz) (hazard-age hz)) 20.0))))
         (n 9))
    (dotimes (i n)
      (let* ((u (- (* 2 (/ i (float (1- n)))) 1)) (bx (+ x (* u hw px))) (bz (+ z (* u hw pz)))
             (h (* rise (+ 1.6 (* 0.5 (sin (+ (* 3 i) 1.0)))))))
        (vfx-ic-chain bx 0.0 bz (+ bx (* 0.12 (sin (* 5 i)))) h (+ bz (* 0.12 (cos (* 5 i)))) k)))
    (vfx-ic-chain (- x (* hw px)) 1.1 (- z (* hw pz)) (+ x (* hw px)) 1.1 (+ z (* hw pz)) k)))

(defun ichigo-no-look (hz rdt) "The wall's hit (its look is the :fx beside it): nothing drawn." (declare (ignore hz rdt)) nil)

(defun ichigo-lane-look (hz rdt)
  "The KESSA module's chain flung straight out along the lane (SIZE m)."
  (declare (ignore rdt))
  (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (l (* (hazard-size hz) (min 1.0 (/ (1+ (hazard-age hz)) 4.0))))
         (k (max 0.02 (- 0.95 (* 0.06 (hazard-age hz))))))
    (vfx-ic-chain (+ x (* 0.5 (fwd-x yaw))) 1.2 (+ z (* 0.5 (fwd-z yaw))) (+ x (* l (fwd-x yaw))) 1.2 (+ z (* l (fwd-z yaw))) k)))

(defun ichigo-flare-look (hz rdt)
  "KUSARI-TATE: chains flaring out of his neck, wrists and ankles (the parry's tell)."
  (declare (ignore rdt))
  (let ((e (hazard-owner hz)))
    (when (and (entity-alive-p e) (fighter e))
      (let ((k (max 0.02 (- 0.95 (* 0.045 (hazard-age hz))))) (g (min 1.0 (/ (1+ (hazard-age hz)) 3.0))) (p (pos-of e)))
        (loop for j in '(:neck :hand-r :hand-l :foot-r :foot-l)
              do (let* ((v (ic-joint e (joint-index j))) (x (aref v 0)) (y (aref v 1)) (z (aref v 2))
                        (dx (- x (aref p 0))) (dz (- z (aref p 2))) (l (max 0.05 (sqrt (+ (* dx dx) (* dz dz)))))
                        (r (* 0.9 g)))
                   (vfx-ic-chain x y z (+ x (* r (/ dx l))) (+ y (* 0.3 g)) (+ z (* r (/ dz l))) k)))))))

(defvar *ic-clone-anim* (vector (make-anim) (make-anim)) "Per side: the clone's anim (posed afresh each draw).")
(defvar *ic-clone-joints* (vector (make-f32 (* +nj+ 16)) (make-f32 (* +nj+ 16))) "Per side: its posed joints.")

(defun ichigo-clone-look (hz rdt)
  "分身 the clone: KESSA's body at alpha 0.45, hit-flashed pale, a BLOOD ring at its feet; it winds the chain lash up
over its tell and slashes as it cuts (the :freeze hit beside it), then fades over 10 f."
  (declare (ignore rdt))
  (let* ((o (hazard-owner hz)) (side (if (and (entity-alive-p o) (fighter o)) (fighter-side (fighter o)) 0))
         (an (svref *ic-clone-anim* side)) (jm (svref *ic-clone-joints* side)) (b (find-body :ichigo))
         (x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (d (hazard-delay hz))
         (tm (/ (if (> d 0) (max 0 (- 9 d)) (+ 9 (hazard-age hz))) 60.0))
         (a (if (> d 0) 0.45 (* 0.45 (max 0.0 (- 1.0 (/ (hazard-age hz) 10.0)))))))
    (anim-play an :ic-k-lash :blend 0 :time tm)
    (pose-fk! jm (anim-eval an) (f32 x) 0f0 (f32 z) (f32 yaw) (body-scale b) (body-hunch b) (body-props b))
    (draw-body b jm x 0.0 z yaw :weapon :tensa :hide (svref (hide-set '(:shikai)) 0) :alpha (f32 a) :flash 0.35 :shadow nil)
    (with-floats (x z a)
      (%tring x 0f0 z 0.55f0 0.04f0 +pal-blood+ (* 1.8f0 a) 3f0 24))))

;;; the auras (DRAW-AURA: (fn x y z h k dt))
(defun ichigo-aura-base (x y z h k dt)
  "The Shikai: no aura; SOGA's flash step leaves the ink afterimages (TENCHI's) over its startup."
  (declare (ignore y h k dt))
  (let* ((e (ichigo-at x z)) (f (and e (fighter e))) (mv (and f (eq (fighter-state f) :move) (fighter-move f))))
    (when (and mv (eq (mv-name mv) :ic-soga) (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv))
               (zerop (mod (fighter-sf f) 4)))
      (start-ghost e))))

(defun ichigo-aura-kessa (x y z h k dt)
  "KESSA: a smoulder of blood-chain wisps at the neck, wrists and ankles (never a pillar: the Kikon's BLOOD stays the
tell; a trace in his own Kikon rush), and during a J / K link's active frames the chain along its hit volume, from the
right hand to the volume's far end."
  (declare (ignore y h))
  (let* ((e (ichigo-at x z)) (f (and e (fighter e))) (mv (and f (eq (fighter-state f) :move) (fighter-move f)))
         (kk (if (and mv (eq (mv-kind mv) :kikon)) (* 0.2 k) k)))
    (when e
      (with-floats (dt kk)
        (dolist (j '(:neck :hand-r :hand-l :shin-r :shin-l))
          (let ((v (ic-joint e (joint-index j))))
            (when (< (rnd01) (* 3f0 dt kk))
              (%t-blob (aref v 0) (aref v 1) (aref v 2) (rnd-range -0.2f0 0.2f0) (rnd-range 0.3f0 0.7f0) (rnd-range -0.2f0 0.2f0)
                       (rnd-range 0.3f0 0.5f0) (rnd-range 0.02f0 0.035f0) -0.1f0 0.05f0 +pal-blood+)))))
      (when (and mv (member (mv-kind mv) '(:quick :flash)) (eq (fighter-phase f) :main)
                 (<= (- (mv-s mv) 2) (fighter-sf f) (+ (mv-s mv) (mv-a mv) 3)))
        (let* ((v (ic-joint e (joint-index :hand-r))) (p (pos-of e)) (yaw (yaw-of e)) (r (mv-reach mv))
               (w *ic-w*) (sw (* 0.6 (sin (* 0.9 (- (fighter-sf f) (mv-s mv)))))))
          (setf (aref w 0) (f32 (+ (aref p 0) (* r (fwd-x (+ yaw sw))))) (aref w 1) 1.1f0 (aref w 2) (f32 (+ (aref p 2) (* r (fwd-z (+ yaw sw))))))
          (vfx-ic-chain (aref v 0) (aref v 1) (aref v 2) (aref w 0) (aref w 1) (aref w 2) 0.9))))))

;;; ---------------------------------------------------------------- sounds (docs/DUEL_ICHIGO.md §10)
(defsound :chain-rattle (:peak 0.7)                    ; link clatter: the parry, the wall, a chain shot
  (let ((b (au-buf 0.6)))
    (dotimes (i 18)
      (let ((at (au-rrange 0.0 0.35)))
        (au-ping! b at (au-rrange 1800 4200) (au-rrange 0.02 0.05) (au-rrange 0.2 0.45) :attack 0.001)
        (au-mix! b (au-fnoise 0.02 :bp (au-rrange 2500 6000) :q 3 :decay 0.008) at 0.3)))
    (au-reverb! b 0.2)))

(defsound :chain-snap (:peak 0.85)                     ; a taut snap: a catch, the yank, the pull's hit
  (let ((b (au-buf 0.5)))
    (au-mix! b (au-fnoise 0.03 :bp 3000 :q 2 :decay 0.01) 0.0 1.0)
    (au-ping! b 0.0 2600 0.06 0.5 :attack 0.001)
    (au-ping! b 0.01 3900 0.04 0.35 :attack 0.001)
    (au-thump! b 0.0 140 60 0.02 0.08 0.5)
    (au-reverb! b 0.15)))

(defsound :getsuga (:peak 0.9)                         ; a deep tearing whoosh with a low resonance (every crescent)
  (let ((b (au-buf 1.1)))
    (au-mix! b (au-whoosh 0.6 200 5000 :q 1.1 :peak 0.25) 0.0 0.9)
    (au-mix! b (au-fnoise 0.4 :bp 900 :q 1.5 :decay 0.2) 0.1 0.5)
    (au-thump! b 0.12 70 40 0.1 0.35 0.7)
    (au-partials! b 0.1 '((110 0.4 0.6) (165 0.25 0.5)))
    (au-reverb! b 0.3 :size 1.2)))

(defsound :clone (:peak 0.6)                           ; a glassy shimmer: a clone appears / slashes
  (let ((b (au-buf 0.7)))
    (au-mix! b (au-whoosh 0.4 2000 9000 :q 2.0 :peak 0.3) 0.0 0.5)
    (loop for f in '(1568 2093 2637) for i from 0 do (au-ping! b (* 0.05 i) f 0.3 0.3 :attack 0.02))
    (au-reverb! b 0.35 :size 1.3)))

;;; ---------------------------------------------------------------- brush names, callouts and glyphs
(setf *brush-names* (append *brush-names* '((:ichigo "黒崎一護" "KUROSAKI ICHIGO")))
      *brush-callouts*
      (append *brush-callouts*
              '((:ic-getsuga "月牙天衝" "GETSUGA TENSHO" nil) (:ic-getsuga-k "月牙天衝" "GETSUGA TENSHO" nil)
                (:ic-juji "月牙十字衝" "GETSUGA JUJISHO" nil) (:ic-soga "双牙" "SOGA" nil)
                (:ic-k-getsuga "月牙天衝" "GETSUGA TENSHO" "血") (:ic-k-getsuga-k "月牙天衝" "GETSUGA TENSHO" "血")
                (:ic-k-hiki "鎖引" "KUSARI-BIKI" "血") (:ic-k-wall "鎖垣" "KUSARI-GAKI" "血")
                (:ic-k-yank "鎖盾" "KUSARI-TATE" "血"))))

;; the brush glyphs his names and captions need beyond the shared set (tools/glyph-bake.py's functions on the same font,
;; Yuji Syuku, SIL OFL 1.1: duel/FONT-LICENSE-YujiSyuku.txt): 黒 崎 一 護 牙 衝 字 血 鎖 双 引 垣 王 虚 漆
(setf *glyph-outlines*
      (append *glyph-outlines*
              '(
    (40658 1000 (836 716 806 713 764 702 450 712 327 723 248 737 236 756 227 758 238 779 243 801 242 823 213 918 197 943 180 959 154 946 132 915 115 858 132 856 146 849 157 836 195 755 131 722 119 712 113 700 120 692 141 684 248 670 458 661 459 650 457 604 424 604 354 619 320 617 284 598 245 562 454 548 455 496 456 443 455 352 426 352 360 364 320 361 322 449 362 452 456 443 455 496 352 508 312 508 276 500 248 480 237 464 241 458 240 441 247 429 239 306 230 247 190 216 159 177 166 166 166 156 265 154 491 134 629 133 653 128 688 115 711 114 764 130 788 131 839 166 856 183 863 203 849 218 807 225 790 245 783 260 773 296 687 259 686 218 676 185 668 174 520 176 536 210 536 228 528 278 457 289 450 220 438 191 381 195 322 207 315 215 310 236 316 305 457 289 528 278 606 305 625 321 631 332 527 344 520 437 607 428 650 433 658 422 663 398 671 391 660 388 678 325 687 259 773 296 750 450 733 499 705 499 654 480 629 478 520 489 517 544 604 529 635 533 670 549 694 565 699 574 698 587 654 594 545 595 517 602 515 655 556 657 647 648 671 651 712 627 737 627 785 639 835 661 872 689 884 711) (874 934 873 942 853 939 818 924 804 911 768 861 717 755 686 710 723 717 740 726 803 774 836 792 863 830 872 852 880 888 883 928) (387 933 365 913 349 886 330 841 340 832 350 805 357 725 392 748 404 764 420 800 427 862 417 945) (577 904 564 892 546 863 534 807 534 716 568 734 581 748 601 783 616 844 618 885 614 921)) ; 黒
    (23822 1000 (934 464 830 457 832 466 850 486 840 754 840 813 846 862 840 900 828 932 807 954 792 959 751 957 671 931 612 897 590 869 560 862 548 850 644 865 691 867 735 858 748 850 757 836 766 777 769 590 761 524 741 471 683 464 506 492 469 485 435 464 429 530 546 526 600 519 616 493 650 499 718 526 728 559 705 580 693 607 615 614 614 579 609 563 553 569 531 581 531 712 556 716 603 701 615 614 693 607 677 720 662 760 556 768 534 780 527 793 482 770 449 734 450 723 465 716 472 614 452 576 432 552 426 578 420 661 412 690 393 688 363 668 360 636 327 650 213 674 181 691 160 720 141 719 106 707 91 696 65 670 45 639 52 629 87 632 93 614 97 584 98 513 94 458 85 433 52 379 51 367 63 362 76 363 119 382 133 385 160 437 163 451 158 506 156 621 197 615 232 603 233 394 229 318 219 269 207 248 199 243 198 220 182 191 183 173 228 174 247 181 279 207 304 243 314 265 302 348 288 588 310 588 366 574 376 440 376 411 364 382 336 346 332 334 334 319 372 319 389 324 419 343 441 369 449 385 437 403 435 413 448 418 474 419 499 410 523 392 556 350 593 274 541 284 498 283 462 274 444 265 412 238 441 222 456 218 564 215 606 208 605 165 598 148 563 106 567 73 577 72 586 66 604 70 641 88 665 92 668 104 692 135 681 166 678 197 698 203 722 203 757 193 770 179 807 180 859 199 898 228 908 238 871 251 715 260 788 346 804 381 744 395 721 380 686 318 665 300 605 372 580 413 715 403 744 395 804 381 810 402 832 406 846 403 860 398 879 384 962 426 982 447 987 460)) ; 崎
    (19968 1000 (950 540 945 549 816 530 708 519 529 515 522 509 519 501 516 515 363 532 274 549 250 557 190 590 171 594 144 586 109 552 90 542 66 470 74 446 132 464 195 469 525 448 761 446 769 429 811 424 824 428 848 446 893 463 916 477 945 502 961 539)) ; 一
    (35703 1000 (971 927 941 945 896 954 856 948 820 930 699 826 630 869 547 902 458 920 399 921 370 917 446 893 436 906 492 881 573 836 643 780 616 747 581 714 552 678 494 648 474 624 687 600 715 593 716 644 685 638 623 655 587 657 613 683 682 720 706 684 716 644 715 593 717 582 722 578 684 576 614 588 579 589 568 592 565 600 544 599 528 593 518 584 506 556 505 539 516 435 516 396 448 442 408 453 422 425 474 365 487 332 518 304 515 295 497 277 519 267 545 271 579 293 592 313 683 305 700 277 690 250 717 241 743 249 763 266 770 289 767 301 803 293 842 294 880 301 912 315 900 331 890 334 758 345 762 379 781 373 799 373 834 385 871 405 846 414 773 420 768 425 763 451 700 459 699 425 699 390 699 356 662 350 566 364 574 378 576 399 610 401 670 391 699 390 699 425 580 444 577 475 642 470 700 459 763 451 801 445 820 448 889 474 850 488 763 493 700 500 610 514 574 512 575 547 617 547 697 538 700 500 763 493 767 534 812 525 855 533 894 549 868 562 854 565 740 572 830 594 877 618 856 636 794 654 786 696 753 754 800 784 878 815 918 836 964 876 976 898 978 909) (468 676 450 679 435 723 400 865 358 872 251 878 208 889 210 925 208 930 196 930 174 922 127 880 129 858 137 842 136 777 131 749 113 701 85 660 67 643 74 631 84 626 130 632 158 625 282 618 306 615 338 660 279 663 208 679 203 694 200 730 210 834 245 836 326 825 336 774 338 660 306 615 344 598 385 602 453 624 474 655 478 668) (920 214 826 213 814 223 788 259 752 245 743 237 738 218 677 221 612 230 602 237 592 275 564 272 528 245 478 227 464 219 443 195 504 183 531 183 526 152 498 118 491 98 513 95 533 98 567 116 590 141 587 169 599 174 627 176 744 167 760 137 762 118 753 63 800 76 826 95 841 119 839 148 894 163 925 175 950 193 959 205) (393 283 210 302 150 320 115 340 98 337 70 322 32 275 9 256 8 232 39 227 54 228 139 247 176 249 303 224 302 184 295 149 282 140 242 123 221 102 259 84 314 79 364 90 376 99 383 110 386 124 338 224 370 219 404 225 444 248 455 270) (359 534 256 553 198 556 163 551 146 544 118 522 126 512 136 508 181 508 332 485 374 489 393 496 408 509 420 528) (354 417 230 437 186 431 164 424 130 405 134 394 143 388 326 366 368 370 385 376 398 386 408 401)) ; 護
    (29273 1000 (935 497 746 481 702 481 654 486 645 548 658 772 655 845 648 889 636 924 628 939 600 960 499 931 396 858 407 854 438 855 427 848 438 844 540 850 556 838 568 803 575 739 573 652 562 551 532 566 484 601 309 757 306 756 309 748 302 749 294 762 282 761 280 767 285 771 212 814 182 828 150 827 146 813 123 822 116 817 130 800 177 768 179 781 170 782 161 788 156 799 159 801 178 792 179 781 177 768 192 771 206 761 302 682 333 663 331 656 334 650 354 632 351 625 363 610 379 600 368 614 396 604 395 588 398 574 408 562 473 514 493 492 456 488 420 492 306 527 271 530 202 545 185 544 169 535 154 520 146 522 131 517 96 494 86 485 77 467 95 461 128 456 222 454 274 440 282 324 239 274 230 248 240 242 254 242 278 251 318 251 342 268 354 297 357 334 347 433 398 432 514 422 554 422 563 418 569 408 564 371 562 258 556 238 545 223 520 209 421 222 380 231 344 244 298 237 265 219 226 173 213 153 230 136 338 151 414 152 574 143 659 134 697 125 725 105 760 117 822 150 831 184 790 193 655 206 659 219 660 251 647 385 654 416 748 411 755 410 768 397 820 403 870 418 894 430 929 464 942 486)) ; 牙
    (34909 1000 (957 498 884 502 855 511 865 539 875 666 801 689 798 627 784 533 736 528 712 515 684 489 604 518 603 476 598 442 566 438 533 447 531 507 562 520 590 538 587 547 580 552 535 553 530 614 471 597 466 565 469 516 464 453 457 448 464 381 462 360 363 374 334 370 319 360 318 366 333 380 341 405 319 430 384 410 459 402 464 381 457 448 402 464 404 480 400 508 403 524 469 516 466 565 404 567 405 631 421 633 468 629 471 597 530 614 544 614 574 622 592 623 604 518 684 489 678 611 667 656 656 675 613 683 599 667 576 662 534 670 531 679 532 706 616 730 648 756 615 764 536 770 531 812 592 812 689 848 687 836 662 816 742 824 787 824 798 755 801 689 875 666 872 846 867 904 829 944 786 928 748 907 714 880 685 849 673 862 391 883 375 897 334 891 305 872 282 846 321 836 456 822 479 817 480 812 478 781 402 779 371 772 344 751 332 735 357 729 439 725 473 718 475 679 436 678 397 687 327 650 330 646 344 646 341 567 332 499 323 475 310 455 316 444 316 437 292 460 256 524 261 551 266 556 262 614 270 867 265 935 230 932 219 924 181 863 194 829 200 790 205 614 116 731 55 794 28 792 5 778 10 761 25 756 36 730 72 695 85 666 102 650 116 630 139 581 164 554 163 541 177 519 170 504 192 486 201 474 240 396 207 360 202 341 265 338 308 356 303 334 308 325 318 320 346 313 423 306 454 296 453 253 439 261 414 266 338 245 392 212 536 152 531 140 509 117 521 112 568 108 614 119 638 136 649 160 648 175 558 203 501 227 504 237 528 262 530 270 526 277 535 284 547 286 574 280 594 268 668 286 689 301 697 312 675 328 660 332 568 341 542 349 531 355 531 394 552 392 594 371 616 367 626 377 669 383 695 395 714 410 722 432 700 454 756 457 857 439 915 436 950 443 964 452 989 483) (270 249 234 297 221 301 201 331 150 356 140 354 114 357 101 353 126 315 202 225 231 177 198 131 204 124 210 121 237 127 237 116 302 122 336 158 343 185) (937 289 820 317 764 323 729 317 714 310 670 266 670 260 673 248 687 246 708 246 748 257 781 251 831 249 856 241 872 231 892 230 914 237 937 250 958 266 972 284)) ; 衝
    (23383 1000 (891 641 701 626 613 627 577 631 566 643 573 769 565 840 542 905 517 939 501 953 437 946 440 932 436 925 429 941 393 927 342 893 300 849 431 847 457 838 478 820 497 783 504 748 504 710 496 632 409 637 324 648 262 661 190 682 174 680 148 666 107 619 84 599 88 588 86 578 100 576 129 578 198 596 218 597 480 573 466 534 412 484 392 452 408 450 423 455 457 479 483 489 542 441 591 383 430 392 383 400 348 417 322 417 310 411 294 391 263 321 324 336 413 340 591 327 608 311 617 308 668 325 696 339 716 361 724 397 616 483 541 525 557 542 569 565 716 569 731 568 744 550 753 548 821 552 857 562 871 579 874 572 887 581 915 608 923 632) (916 348 883 369 834 416 810 428 798 428 736 379 781 302 797 257 763 238 723 232 685 232 562 242 505 243 486 262 469 245 431 252 300 258 274 264 242 281 240 309 215 352 196 412 186 459 185 483 200 518 197 535 158 520 142 509 116 481 83 435 121 391 140 353 145 334 143 293 128 269 115 259 114 245 120 237 129 231 152 226 176 228 253 216 464 202 463 174 443 157 386 125 371 107 397 90 430 80 464 80 497 88 525 106 534 118 541 133 527 150 519 195 559 200 688 194 726 196 750 180 776 178 816 185 842 196 861 209 865 226 890 245 902 263 919 315 920 342)) ; 字
    (34880 1000 (956 859 942 860 836 832 732 822 463 824 343 831 286 841 205 875 172 900 149 903 128 902 108 894 76 870 29 808 42 800 39 793 60 789 104 804 138 793 208 779 206 772 185 750 190 545 183 464 172 447 124 404 114 375 151 377 165 383 174 378 190 364 195 354 212 348 240 328 274 280 329 176 314 159 277 134 269 126 260 104 350 103 384 107 412 119 430 140 432 168 426 178 381 230 319 330 426 332 664 322 690 390 654 374 630 372 554 375 587 416 596 444 588 499 520 522 516 452 508 412 495 379 443 378 394 386 431 427 440 454 433 483 440 522 440 611 432 671 420 701 433 704 423 761 371 761 362 472 345 397 329 398 288 412 273 411 263 454 258 502 259 581 276 768 338 766 371 761 423 761 514 757 520 522 588 499 579 700 566 754 660 757 686 534 690 390 664 322 667 308 691 308 756 320 788 322 803 342 857 373 872 393 865 403 857 411 806 439 794 461 786 515 775 644 749 757 776 756 814 733 870 748 915 771 934 786 967 825 980 850)) ; 血
    (37782 1000 (912 427 903 451 906 538 903 562 828 573 825 488 817 430 803 393 797 387 791 393 735 388 680 390 633 400 616 411 624 442 623 472 652 472 722 458 743 470 781 501 620 526 617 583 640 585 706 566 766 587 785 609 723 613 611 634 614 701 815 690 825 640 828 573 903 562 911 604 912 644 901 794 889 796 885 801 832 768 822 745 812 740 763 738 797 762 871 802 900 830 936 882 947 927 951 973 927 973 899 961 872 943 848 921 833 898 803 835 752 765 746 747 757 743 759 738 661 745 669 757 677 789 667 796 648 826 637 833 622 836 622 844 632 850 576 886 566 895 553 918 512 934 504 945 461 938 450 929 550 832 566 813 588 772 519 747 490 722 512 720 544 706 559 705 537 680 528 644 532 624 538 617 544 530 553 478 552 456 544 432 521 415 505 378 494 371 519 362 553 358 669 354 677 282 674 185 651 165 621 108 646 102 700 107 746 149 760 168 749 282 725 350 774 347 790 343 810 329 817 343 820 329 838 332 873 342 958 379 962 399) (461 270 429 257 400 233 365 190 319 241 323 250 316 263 290 292 296 295 280 305 273 314 261 346 247 349 251 363 245 372 215 393 267 397 300 393 328 385 356 367 386 362 410 377 439 388 462 405 432 422 347 440 370 470 367 521 442 544 454 550 472 567 458 582 448 585 386 589 364 595 356 730 345 801 369 811 441 826 460 841 426 860 313 885 274 900 244 923 234 940 192 933 172 925 138 899 114 865 105 846 144 852 179 852 296 831 300 724 295 605 246 614 198 612 154 599 117 572 158 562 294 545 281 457 262 454 217 430 195 427 181 435 162 462 146 468 145 486 94 529 100 532 41 556 29 556 5 535 15 523 40 509 60 491 55 490 40 499 35 498 90 450 114 420 132 387 157 370 197 309 218 289 229 259 244 233 267 217 265 205 279 160 267 142 236 113 257 104 292 97 315 99 322 106 332 103 358 109 361 122 400 140 477 196 498 243 497 270) (919 246 877 283 869 305 842 315 803 313 790 316 796 295 830 233 831 210 809 167 809 157 817 150 840 153 915 187 926 206 925 234) (481 690 452 753 437 773 420 778 417 787 375 790 413 676 416 641 407 605 433 603 458 615 489 647 499 672) (244 792 240 798 218 793 201 784 188 770 172 732 154 643 174 642 192 648 222 674 233 692 247 731 253 788) (568 333 556 328 538 308 503 196 510 189 551 201 582 229 602 267 607 289 603 334)) ; 鎖
    (21452 1000 (966 830 962 850 954 863 928 879 880 888 850 887 827 882 788 862 758 832 698 741 674 711 630 764 591 798 574 811 566 802 559 802 558 807 566 822 485 873 491 860 459 876 440 878 381 868 389 862 406 861 438 847 493 810 590 702 610 671 625 635 594 579 502 455 464 393 504 411 540 434 662 548 691 469 714 379 723 318 726 255 642 263 629 266 610 281 580 273 546 243 511 193 520 188 526 176 538 178 582 196 616 200 728 186 746 159 796 174 818 185 837 198 868 231 889 272 820 284 732 617 822 697 860 719 901 737 936 786 962 809 965 818) (527 258 518 264 487 266 467 306 422 426 388 547 479 688 505 740 505 748 496 757 474 757 440 745 382 693 356 677 358 668 346 644 339 648 328 674 324 670 320 672 317 683 322 684 320 690 314 694 312 691 304 701 276 744 277 747 257 761 263 764 255 768 234 798 214 812 218 818 206 828 202 838 198 838 199 829 172 855 134 871 95 875 58 867 82 853 136 809 157 799 170 770 224 703 237 669 259 642 273 607 291 575 260 522 218 483 197 452 147 398 188 405 208 414 321 488 349 415 374 272 356 267 320 267 224 286 189 285 159 254 141 242 124 203 121 186 178 185 178 195 219 203 266 208 305 206 337 199 360 188 385 162 395 160 397 155 439 168 474 186 504 210 531 242)) ; 双
    (24341 1000 (557 578 515 589 491 828 475 869 454 895 432 908 429 921 403 922 360 914 272 872 246 828 219 810 202 805 236 806 324 826 341 827 374 820 395 792 413 735 420 666 417 593 414 569 335 572 266 583 241 592 212 614 187 616 147 604 124 589 110 570 107 559 113 538 143 542 163 532 176 512 185 483 193 407 163 381 166 371 185 352 242 349 256 352 269 360 381 352 404 341 411 332 420 307 425 198 385 194 342 200 288 214 233 240 189 208 159 178 151 158 149 135 163 131 193 135 218 146 224 153 265 144 369 135 408 126 424 114 435 97 508 124 547 148 556 158 563 183 544 200 531 217 507 233 494 352 477 404 367 414 268 436 248 520 277 526 312 524 393 514 409 493 473 494 514 507 532 518 547 532 559 549 566 570) (846 797 826 928 817 932 804 950 791 953 777 912 768 865 762 784 765 423 758 224 747 172 736 153 701 116 696 105 696 91 751 90 812 110 843 133 853 148 859 166 848 234 844 315 851 601)) ; 引
    (22435 1000 (932 379 931 387 886 389 851 401 844 482 753 550 747 368 685 365 617 370 550 383 512 398 515 499 618 488 662 471 723 506 741 532 645 540 516 559 516 693 573 690 745 670 753 550 844 482 837 653 824 728 794 736 750 726 709 726 564 750 521 752 481 746 443 726 446 716 456 714 453 704 439 693 435 685 444 624 445 542 439 534 412 517 417 514 444 516 442 427 432 408 402 372 399 364 401 342 440 346 452 341 462 329 723 305 722 294 752 295 804 300 848 311 885 332 901 347 925 354 933 362 937 376) (369 743 261 786 213 810 186 833 166 862 146 859 107 838 96 819 69 798 54 779 50 754 78 752 115 763 195 728 247 712 247 469 216 477 144 515 74 450 65 433 61 412 63 387 169 404 201 402 241 392 241 324 231 229 223 195 192 141 182 103 212 96 231 102 270 134 310 176 320 192 323 204 310 329 314 365 332 361 350 363 368 372 398 399 406 417 320 446 315 622 306 689 346 681 372 684 395 695 407 716) (942 896 909 900 864 883 813 874 756 871 665 874 470 897 458 912 445 920 430 922 415 920 382 905 314 857 324 849 347 842 517 822 619 814 784 807 806 792 834 788 861 793 868 804 942 833 962 850 970 880) (654 212 507 226 475 235 453 231 439 221 390 163 408 151 474 168 625 152 737 132 753 113 794 124 853 154 867 170 865 184)) ; 垣
    (29579 1000 (933 877 922 879 910 878 889 867 757 856 624 852 501 856 410 865 265 890 232 910 212 912 175 907 158 901 121 878 89 846 79 829 73 800 146 806 232 805 474 786 472 563 355 565 303 583 275 582 259 577 232 556 210 526 188 480 266 488 472 487 468 340 465 308 456 279 439 258 312 264 272 275 254 286 236 281 205 262 180 232 162 198 150 164 165 160 182 161 235 177 274 183 343 183 620 167 700 152 712 138 766 146 854 196 861 232 748 236 696 242 685 234 678 242 667 246 622 247 611 251 606 244 551 252 568 283 560 346 557 481 644 472 663 455 704 460 751 474 779 487 799 507 807 534 763 545 663 549 555 560 548 780 593 783 738 780 744 778 749 764 754 762 812 767 868 784 902 803 929 829 950 863)) ; 王
    (34394 1000 (884 380 810 450 754 438 706 420 704 407 709 394 747 338 701 330 650 330 476 343 414 344 473 354 505 367 525 389 529 406 527 426 608 419 664 422 702 432 734 458 720 471 684 479 524 478 519 510 521 542 564 545 670 538 706 542 737 556 759 584 697 594 607 600 554 626 546 622 530 602 487 591 462 570 450 540 446 484 411 495 379 492 350 479 315 453 312 433 354 439 446 431 446 416 439 404 400 369 399 360 406 348 308 363 289 370 273 381 285 389 308 423 290 546 275 584 262 599 263 629 258 650 223 744 179 839 176 832 172 835 145 878 158 881 230 880 405 863 410 698 402 653 393 634 382 619 366 608 367 601 373 597 434 611 467 630 478 642 486 656 489 671 480 756 482 859 543 858 553 780 554 626 607 600 616 606 634 632 626 692 622 793 659 759 711 676 691 644 691 631 744 636 777 648 801 670 807 686 808 706 784 724 736 782 714 800 686 812 668 813 650 802 622 804 619 856 688 855 713 859 728 841 852 876 890 901 905 918 864 928 842 928 696 912 503 916 413 924 343 936 307 947 289 960 232 946 201 930 138 889 131 906 100 930 93 942 36 940 94 854 155 730 198 612 218 518 221 464 215 433 203 412 162 376 142 335 123 317 145 301 156 300 203 312 306 300 436 291 436 130 380 84 366 57 412 54 451 57 489 66 520 82 531 94 537 108 539 124 522 158 521 181 588 171 642 168 676 176 710 199 683 217 647 226 519 231 512 283 654 275 738 275 748 270 753 258 840 277 885 295 922 326 938 346) (338 826 310 812 274 781 274 746 264 676 288 679 308 688 324 701 337 718 352 760 355 806 351 829)) ; 虚
    (28422 1000 (927 750 892 746 870 738 833 717 744 641 720 665 702 676 644 704 611 662 637 644 646 632 664 591 672 594 687 588 670 554 660 540 594 482 580 490 551 489 526 501 473 551 447 563 454 570 417 595 484 639 500 655 511 675 514 704 491 710 479 709 446 695 414 661 397 623 387 623 382 632 367 637 368 646 348 660 344 672 320 682 314 693 281 704 284 714 280 723 271 730 231 739 231 747 240 752 241 757 234 756 226 761 221 796 231 789 234 816 238 822 247 824 237 865 207 936 184 933 147 918 119 893 71 834 91 824 103 825 138 840 164 859 221 760 201 760 207 771 182 773 137 767 136 760 121 753 181 722 183 729 187 729 198 710 227 689 234 679 250 683 262 676 241 676 268 659 321 609 344 602 344 591 351 582 395 548 507 419 504 394 527 383 527 345 481 376 398 442 333 481 271 500 273 493 270 488 257 496 250 490 217 485 231 470 266 453 352 397 407 345 424 345 437 327 460 309 477 288 377 274 370 261 354 253 354 235 378 222 405 217 495 216 531 211 523 156 491 56 509 53 525 54 556 66 583 88 614 126 606 179 607 200 658 193 674 179 752 198 783 216 796 228 807 242 797 256 672 258 624 264 604 271 628 288 696 313 717 330 769 353 819 395 888 469 884 482 852 487 822 477 753 439 731 433 686 383 597 320 586 350 597 426 677 479 865 588 946 643 965 660 980 682 986 709 984 725) (610 908 605 926 588 954 521 931 481 908 455 877 448 858 510 866 524 862 534 847 543 771 542 657 537 598 514 521 517 514 543 512 567 523 596 553 607 577 601 674 615 849) (214 557 214 563 178 553 149 537 81 489 74 461 38 413 27 390 88 397 123 410 153 430 184 461 198 482 220 529 227 556) (277 256 254 254 231 240 197 212 174 200 170 178 144 132 141 116 170 117 218 129 256 153 272 171 284 192 297 246) (429 823 413 844 404 866 386 863 358 850 335 829 297 781 307 778 317 768 328 767 356 782 367 785 416 746 434 741 487 757 491 767) (807 862 781 869 760 864 741 853 704 818 684 806 675 784 632 740 624 718 651 722 700 737 744 764 784 804 811 855)) ; 漆
                )))

;;; ---------------------------------------------------------------- cinematics (§5, §6; unskippable, SHOT-ON framed)
(defcine ic-kikon-cine (a v :len 186 :hold 112)
  "月牙天衝 with a Gran Rey Cero (the Shikai's Kikon; the user's decision 2026-09-28): beat 0, the X held; a white card,
Ichigo black, the blades' white edges the only lines, the 月牙天衝 / 王虚の閃光 stamp, silence; low on him: the long blade
held out, a Cero gathering on its edge, red in black; from behind the victim: the black crescent with its BLOOD core
tearing at him; a held push-in, in silence; the impact: a negative, a manga page, the Konpaku; a wide, ash drifting."
  (at 0 (face-each-other a v 2.6) (shot-on a 60 3.6 1.1 :look 1.1) (lens 50)
      (cine-clip a :ic-cross :blend 2 :time 0.18) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :whoosh-heavy :pitch 1.1))
  (at 12 (card :white a) (shot-on a 30 3.2 0.7 :look 1.1 :off -0.8) (lens 44 -8) (silence 58)
      (caption "月牙天衝" :kanji2 "王虚の閃光" :reading "GETSUGA TENSHO" :sub "GRAN REY CERO  KIKON" :side 1 :ink t :hanko t))
  (at 70 (card nil) (caption-exit) (shot-on a 95 3.0 0.8 :look 1.3 :off 0.5) (lens 66 6)
      (cine-clip a :ic-getsuga :blend 4 :speed 0.3) (play-sfx :awaken-rise :pitch 0.8))
  (during (70 106) (multiple-value-bind (x y z) (actor-point a 1.4)   ; the Cero on the long blade
                     (let ((yaw (yaw-of a)))
                       (vfx-ic-cero (+ x (* 1.3 (fwd-x yaw))) (+ y 0.2) (+ z (* 1.3 (fwd-z yaw)))
                                    (* 0.3 (min 1.0 (/ (- cf 68) 20.0))) 0.95 (cine-dt)))))
  (at 104 (cine-clip a :ic-getsuga :blend 0 :time 0.2) (shot-on v 160 6.0 1.2 :look 1.3) (lens 58)
      (play-sfx :getsuga) (play-sfx :explode :pitch 0.6 :gain 0.6))
  (during (104 150) (let* ((p (pos-of a)) (q (pos-of v)) (u (min 1.0 (/ (- cf 104) 24.0))) (yaw (yaw-of a)))
                      (vfx-ic-crescent (+ (aref p 0) (* u (- (aref q 0) (aref p 0)))) 1.3 (+ (aref p 2) (* u (- (aref q 2) (aref p 2))))
                                       yaw 5.0 0.95 0.5 2)))
  (at 128 (hold-both a v 22) (silence 22) (lens 66))
  (during (128 150) (shot-on v 150 (- 4.2 (* 0.9 u)) (+ 0.8 (* 0.2 u)) :look 1.3))
  (at 150 (impact-frame :negative 2)
      (multiple-value-bind (x y z) (actor-point v 1.0) (vfx-konpaku-shatter x (+ y 0.1) z 3) (vfx-hit x (+ y 0.3) z :heavy))
      (let ((q (pos-of v))) (impact-splash (aref q 0) 0.0 (aref q 2) 14 0.08))
      (play-sfx :getsuga :pitch 0.7) (play-sfx :konpaku-shatter) (shake 0.3 0.4))
  (at 152 (impact-frame :manga 12))
  (at 170 (shot-on a 170 5.2 1.0 :look 1.2) (lens 48) (cine-clip a :ic-stance :blend 8)))

(defcine ic-kessa-kikon-cine (a v :len 192 :hold 118)
  "The KESSA Kikon: the anime's giant pitch-black Getsuga Tensho (the user's decision 2026-09-28): beat 0, the chain
lane held; chains lash in and bind him; a black card with a BLOOD back-rim, the 月牙天衝 / 漆黒 stamp, silence; low and
close: Tensa overhead, a crescent building on its edge far larger than his L; wide: the pitch-black crescent crosses
the plaza; the impact; the residue hanging over the plaza, fading."
  (at 0 (face-each-other a v 3.4) (shot-on a 60 4.0 1.1 :look 1.1) (lens 50)
      (cine-clip a :ic-k-thrust :blend 2 :time 0.2) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :chain-snap))
  (at 12 (shot-on v 30 4.0 1.1 :look 1.2) (lens 56) (cine-clip v :sh-bound :blend 4) (play-sfx :chain-rattle))
  (at 24 (play-sfx :chain-rattle :pitch 0.8))
  (during (12 40) (multiple-value-bind (x y z) (actor-point v 0.0)   ; the chains from the plaza's edge, wrapping him
                    (let ((g (min 1.0 (/ (- cf 12) 12.0))))
                      (dotimes (i 4)
                        (let ((ang (+ 0.6 (* i 1.57))))
                          (vfx-ic-chain (+ x (* 6.0 (cos ang))) 0.1 (+ z (* 6.0 (sin ang)))
                                        (+ x (* (- 6.0 (* g 5.7)) (cos ang))) (+ y 0.4 (* 0.35 i)) (+ z (* (- 6.0 (* g 5.7)) (sin ang)))
                                        0.95))))))
  (at 40 (card :black a) (back-rim 58 0.82 0.06 0.11) (shot-on a 20 4.2 0.9 :look 1.1 :off 0.9) (lens 42)
      (cine-clip a :ic-k-wall :blend 4 :time 0.12 :speed 0.0)
      (caption "月牙天衝" :kanji2 "漆黒" :reading "GETSUGA TENSHO" :sub "KESSA NO ICHIGO  KIKON" :side 0 :hanko t))
  (at 98 (card nil) (caption-exit) (shot-on a 30 2.8 0.4 :look 1.6 :off 0.5) (lens 78 -6)
      (cine-clip a :ic-drop :blend 6 :time 0.12 :speed 0.15) (play-sfx :awaken-rise :pitch 0.6))
  (during (98 124) (multiple-value-bind (x y z) (actor-point a 2.3)   ; the crescent building over his head
                     (vfx-ic-crescent x (+ y 0.6) z (yaw-of a) (* 12.0 (min 1.0 (/ (- cf 96) 22.0))) 0.95 0.2 1)))
  (at 122 (shot-pair a v (camera-side a) 12.0 5.0) (lens 54) (cine-clip a :ic-drop :blend 0 :time 0.33)
      (play-sfx :getsuga :pitch 0.7) (play-sfx :explode :pitch 0.5))
  (during (122 152) (let* ((p (pos-of a)) (q (pos-of v)) (u (min 1.0 (/ (- cf 122) 26.0))))
                      (vfx-ic-crescent (+ (aref p 0) (* u (- (aref q 0) (aref p 0)))) 2.4 (+ (aref p 2) (* u (- (aref q 2) (aref p 2))))
                                       (yaw-of a) 12.0 0.95 0.2 1)))
  (at 150 (impact-frame :negative 2)
      (multiple-value-bind (x y z) (actor-point v 1.0) (vfx-konpaku-shatter x (+ y 0.1) z 3) (vfx-hit x (+ y 0.3) z :heavy))
      (let ((q (pos-of v))) (impact-splash (aref q 0) 0.0 (aref q 2) 14 0.1))
      (play-sfx :getsuga :pitch 0.6) (play-sfx :chain-snap) (play-sfx :konpaku-shatter) (shake 0.35 0.45))
  (at 152 (impact-frame :manga 12))
  (at 170 (shot-on a 150 7.0 2.0 :look 2.0) (lens 50) (cine-clip a :ic-k-stance :blend 10))
  (during (170 192) (let* ((q (pos-of v)) (yaw (yaw-of a)))   ; the residue over the plaza, fading
                      (vfx-ic-crescent (+ (aref q 0) (* 2.0 (fwd-x yaw))) 3.0 (+ (aref q 2) (* 2.0 (fwd-z yaw))) yaw 12.0
                                       (max 0.05 (- 0.9 u)) 0.2 1))))

(defcine ic-kessa-cine (a v :len 168 :hold 120)
  "血鎖の一護 KESSA NO ICHIGO (the awakening, 168 f): beat 0, the blades lowered, head down, silence; close on his face:
the Hollow marking on the left, a low drone; medium and low: the short blade brought into the long one's hole, a white
flash, one blade (Tensa); low and wide from behind: the blood chains burst from neck, wrists and ankles, the second
horn; a black card, a BLOOD back-rim, the 血鎖の一護 stamp (no hanko: not a Kikon); back in the plaza, the chains
drifting."
  (at 0 (setf (model-weapon (model a)) :zangetsu-long (model-hide (model a)) (hide-set '(:kessa :mark)) *aura-off* a)
      (shot-on a 30 3.4 1.0 :look 1.0) (lens 50)
      (cine-clip a :ic-awaken :blend 3) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (hold-both a v 12) (impact-frame :negative 2) (silence 12))
  (at 12 (shot-on a 20 1.3 1.62 :look 1.62) (lens 70) (play-sfx :awaken-rise :pitch 0.6))
  (at 26 (setf (model-hide (model a)) (hide-set '(:kessa))))   ; the marking crawls on (the Shikai's blades still in hand)
  (at 40 (shot-on a 40 3.0 0.5 :look 1.1 :off 0.4) (lens 64 -4))
  (at 58 (setf (model-weapon (model a)) :tensa (model-hide (model a)) (hide-set '(:shikai :kessa)))
      (ui-flash 1 1 1 1 20.0) (play-sfx :awaken-boom :pitch 1.2))
  (at 70 (shot-on a 170 3.6 0.35 :look 1.0) (lens 76 -6) (setf (model-hide (model a)) (hide-set '(:shikai)))   ; the chains, the
      (play-sfx :chain-rattle) (play-sfx :awaken-boom))                                                         ; second horn
  (at 80 (play-sfx :chain-rattle :pitch 0.8) (shake 0.15 0.3))
  (during (70 168) (let ((g (min 1.0 (/ (- cf 70) 10.0))) (p (pos-of a)))   ; the chains bursting, then drifting
                     (loop for j in '(:neck :hand-r :hand-l :shin-r :shin-l) for i from 0
                           do (let* ((v (ic-joint a (joint-index j))) (x (aref v 0)) (y (aref v 1)) (z (aref v 2))
                                     (dx (- x (aref p 0))) (dz (- z (aref p 2))) (l (max 0.05 (sqrt (+ (* dx dx) (* dz dz)))))
                                     (r (* g (+ 0.8 (* 0.3 (sin (+ (* 0.1 cf) i)))))))
                                (vfx-ic-chain x y z (+ x (* r (/ dx l))) (+ y (* 0.4 g) (* 0.2 (sin (+ (* 0.13 cf) i))))
                                              (+ z (* r (/ dz l))) 0.9)))))
  (at 96 (card :black a) (back-rim 54 0.82 0.06 0.11) (shot-on a 20 4.4 0.9 :look 1.1 :off 0.9) (lens 42)
      (caption "血鎖の一護" :reading "KESSA NO ICHIGO" :sub "TENSA ZANGETSU" :side 0))
  (at 150 (card nil) (caption-exit) (shot-on a -30 6.0 1.4 :look 1.1) (lens 50) (setf *aura-off* nil)
      (cine-clip a :ic-k-stance :blend 10)))
