;;;; ken-art.lisp — ZARAKI KENPACHI (TYBW) as art data: his body, his notched katana and the true
;;;; Shikai NOZARASHI (a giant cleaver), and every :ke-* pose and clip (design §5.2). Attack clips
;;;; use DEFSTRIKE, so each reaches its hit pose at frame S and is back in his stance at S+A+R.
;;;; Look: 2.02 m, broad, long loose black spiky hair (no bells), eyepatch over the RIGHT eye (tag
;;;; :eyepatch — awakened Ken is drawn with :hide :eyepatch), scar down the left side of the face,
;;;; a grin, sleeveless tattered white haori over the black shihakusho, bare muscular arms.
(in-package :duel)

;;; ---------------------------------------------------------------- body
(defbody :kenpachi (:scale 1.13 :width 1.18 :hunch 0 :hurt-r 0.45 :hurt-h 2.0
                    :palette ((:skin #xC4885C) (:skin-d #xA87048) (:black #x141418) (:white #xD3CFC5)
                              (:hair #x111116) (:patch #x070707) (:scar #x8A3A2C) (:teeth #xF2EEE2)
                              (:eye #x141414) (:obi #xC2BEB2) (:tabi #xC6C2B6) (:sole #x3A3028))
                    :rim (#xFFE070 0.2)
                    :props (:shoulders 1.3 :arms 1.06))  ; broad chest: the bare arms hang clear of the haori
  (:pelvis (:box 0.34 0.18 0.24 :c :black)
           (:box 0.35 0.07 0.25 :at (0 0.06 0) :c :obi)
           ;; the tattered haori hem: strips of different lengths
           (:box 0.15 0.62 0.02 :at (-0.14 -0.26 -0.14) :rot (0 -4 0) :c :white)
           (:box 0.14 0.76 0.02 :at (0.0 -0.33 -0.145) :rot (0 -4 0) :c :white)
           (:box 0.15 0.56 0.02 :at (0.14 -0.23 -0.14) :rot (0 -4 0) :c :white)
           (:box 0.02 0.5 0.13 :at (0.215 -0.2 -0.06) :rot (0 0 4) :c :white)
           (:box 0.02 0.66 0.12 :at (0.215 -0.28 0.06) :rot (0 0 4) :c :white)
           (:box 0.02 0.58 0.13 :at (-0.215 -0.24 -0.06) :rot (0 0 -4) :c :white)
           (:box 0.02 0.46 0.12 :at (-0.215 -0.18 0.06) :rot (0 0 -4) :c :white)
           (:box 0.1 0.64 0.02 :at (0.17 -0.27 0.135) :rot (0 4 0) :c :white)
           (:box 0.1 0.52 0.02 :at (-0.17 -0.21 0.135) :rot (0 4 0) :c :white))
  (:spine (:box 0.32 0.24 0.21 :at (0 0.11 0) :c :black)
          (:box 0.4 0.25 0.03 :at (0 0.11 -0.12) :c :white)
          (:box 0.03 0.25 0.24 :at (0.2 0.11 0) :c :white)
          (:box 0.03 0.25 0.24 :at (-0.2 0.11 0) :c :white)
          (:box 0.1 0.25 0.03 :at (0.16 0.11 0.12) :c :white)
          (:box 0.1 0.25 0.03 :at (-0.16 0.11 0.12) :c :white))
  (:chest (:bevel 0.44 0.3 0.25 0.03 :at (0 0.11 0) :c :black)
          (:box 0.13 0.2 0.02 :at (0 0.15 0.124) :c :skin)                               ; open collar
          (:box 0.1 0.08 0.02 :at (0 0.07 0.124) :rot (0 0 45) :c :skin)
          (:box 0.48 0.32 0.03 :at (0 0.11 -0.135) :c :white)
          (:box 0.5 0.03 0.28 :at (0 0.265 0) :c :white)
          (:box 0.03 0.3 0.27 :at (0.235 0.1 0) :c :white)
          (:box 0.03 0.3 0.27 :at (-0.235 0.1 0) :c :white)
          (:box 0.12 0.32 0.03 :at (0.18 0.11 0.135) :c :white)
          (:box 0.12 0.32 0.03 :at (-0.18 0.11 0.135) :c :white))
  (:neck (:cyl 0.075 0.1 :at (0 0.04 0) :c :skin))
  (:head (:bevel 0.18 0.26 0.2 0.03 :at (0 0.12 0) :c :skin)
         (:wedge 0.04 0.05 0.045 :at (0 0.11 0.11) :rot (180 0 0) :c :skin)
         (:box 0.05 0.02 0.012 :at (-0.045 0.145 0.102) :c :eye)
         (:box 0.018 0.2 0.014 :at (-0.047 0.13 0.103) :rot (0 0 6) :c :scar)          ; scar, left side
         (:glow 0.5 (:box 0.1 0.028 0.012 :at (0 0.058 0.106) :c :teeth))                ; the grin
         (:box 0.11 0.01 0.01 :at (0 0.045 0.105) :c :eye)
         (:bevel 0.075 0.065 0.03 0.01 :at (0.045 0.145 0.106) :c :patch :tag :eyepatch) ; eyepatch (right)
         (:box 0.205 0.014 0.22 :at (0 0.185 0) :rot (0 0 -18) :c :patch :tag :eyepatch)
         ;; long loose spiky hair
         (:bevel 0.22 0.1 0.23 0.03 :at (0 0.24 -0.01) :c :hair)
         (:box 0.26 0.46 0.07 :at (0 0.0 -0.13) :rot (0 -8 0) :c :hair)
         (:cone 0.055 0.36 :at (0.115 0.05 -0.01) :rot (0 172 -14) :seg 4 :c :hair)      ; side locks
         (:cone 0.055 0.36 :at (-0.115 0.05 -0.01) :rot (0 172 14) :seg 4 :c :hair)
         (:cone 0.045 0.26 :at (0.13 0.12 -0.07) :rot (0 160 -35) :seg 4 :c :hair)
         (:cone 0.045 0.26 :at (-0.13 0.12 -0.07) :rot (0 160 35) :seg 4 :c :hair)
         (:cone 0.05 0.24 :at (0.15 -0.2 -0.1) :rot (0 160 -20) :seg 4 :c :hair)
         (:cone 0.05 0.26 :at (-0.15 -0.22 -0.1) :rot (0 160 20) :seg 4 :c :hair)
         (:cone 0.05 0.22 :at (0.06 -0.3 -0.14) :rot (0 170 -8) :seg 4 :c :hair)
         (:cone 0.05 0.24 :at (-0.06 -0.32 -0.14) :rot (0 170 8) :seg 4 :c :hair)
         (:cone 0.05 0.24 :at (0.16 0.14 -0.08) :rot (0 140 -35) :seg 4 :c :hair)
         (:cone 0.05 0.24 :at (-0.16 0.14 -0.08) :rot (0 140 35) :seg 4 :c :hair)
         (:cone 0.05 0.26 :at (0.07 0.24 -0.14) :rot (0 115 -15) :seg 4 :c :hair)
         (:cone 0.05 0.26 :at (-0.07 0.24 -0.14) :rot (0 115 15) :seg 4 :c :hair)
         (:cone 0.045 0.2 :at (0 0.3 -0.1) :rot (0 100 0) :seg 4 :c :hair)
         (:cone 0.03 0.12 :at (0.04 0.2 0.11) :rot (0 160 -10) :seg 4 :c :hair)         ; fringe
         (:cone 0.03 0.12 :at (-0.05 0.2 0.11) :rot (0 160 15) :seg 4 :c :hair))
  (:shoulder-r (:sphere 0.09 :at (0.06 -0.03 0) :c :skin)
               (:box 0.1 0.04 0.27 :at (-0.01 0.05 0) :rot (0 0 -10) :c :white))
  (:shoulder-l (:sphere 0.09 :at (-0.06 -0.03 0) :c :skin)
               (:box 0.1 0.04 0.27 :at (0.01 0.05 0) :rot (0 0 10) :c :white))
  (:upper-arm-r (:bevel 0.12 0.3 0.12 0.025 :at (0 -0.15 0) :c :skin) (:sphere 0.065 :at (0 -0.13 0.035) :c :skin-d))
  (:upper-arm-l (:bevel 0.12 0.3 0.12 0.025 :at (0 -0.15 0) :c :skin) (:sphere 0.065 :at (0 -0.13 0.035) :c :skin-d))
  (:lower-arm-r (:bevel 0.1 0.27 0.105 0.02 :at (0 -0.125 0) :c :skin))
  (:lower-arm-l (:bevel 0.1 0.27 0.105 0.02 :at (0 -0.125 0) :c :skin))
  (:hand-r (:box 0.085 0.1 0.09 :at (0 -0.045 0) :c :skin))
  (:hand-l (:box 0.085 0.1 0.09 :at (0 -0.045 0) :c :skin))
  (:thigh-r (:box 0.19 0.46 0.21 :at (0 -0.22 0) :c :black))
  (:thigh-l (:box 0.19 0.46 0.21 :at (0 -0.22 0) :c :black))
  (:shin-r (:box 0.2 0.34 0.22 :at (0 -0.15 0) :c :black) (:box 0.085 0.12 0.09 :at (0 -0.37 0) :c :tabi))
  (:shin-l (:box 0.2 0.34 0.22 :at (0 -0.15 0) :c :black) (:box 0.085 0.12 0.09 :at (0 -0.37 0) :c :tabi))
  (:foot-r (:box 0.09 0.06 0.23 :at (0 -0.02 0.06) :c :tabi) (:box 0.1 0.02 0.25 :at (0 -0.055 0.06) :c :sole))
  (:foot-l (:box 0.09 0.06 0.23 :at (0 -0.02 0.06) :c :tabi) (:box 0.1 0.02 0.25 :at (0 -0.055 0.06) :c :sole)))

;;; ---------------------------------------------------------------- weapons
(defweapon :ken-katana (:length 1.08)                  ; battered, notched, chipped
  (:solid (mb-blade mb :length 1.02 :width 0.036 :curve 0.018 :blade-color '(0.55 0.57 0.6) :edge-color '(0.78 0.8 0.82)
                       :guard-color '(0.25 0.24 0.22) :handle-color '(0.1 0.09 0.09) :wrap-color '(0.3 0.28 0.26))
          (mbc mb #x2A2A2E)                              ; chips: dark notches bitten out of the edge
          (loop for (y d) in '((0.22 0.012) (0.37 0.008) (0.55 0.014) (0.71 0.009) (0.86 0.011))
                do (with-xform (mb (xform :y y :z (- 0.016 (* 0.018 (/ y 1.02) (/ y 1.02))) :roll 0.6))
                     (mb-box mb 0.012 d d)))))

(defweapon :nozarashi (:length 1.62 :base 0.2)         ; ~1.8 m of blade at Ken's scale
  (:solid (mbc mb #x464E58)                              ; the slab: dark steel, bevelled so its rims catch light
          (with-xform (mb (xform :y 0.82 :z 0.07)) (mb-bevel-box mb 0.04 1.46 0.3 0.008))
          (mbc mb #x2A2E34)                              ; a dark fuller groove along the spine side
          (with-xform (mb (xform :y 0.84 :z -0.03)) (mb-box mb 0.044 1.3 0.022))
          (mbc mb #x8E98A0)                              ; the ground bevel: a light band on both faces
          (with-xform (mb (xform :y 0.8 :z 0.18)) (mb-box mb 0.046 1.44 0.07))
          (with-xform (mb (xform :y 0.8 :z 0.25)) (mb-box mb 0.026 1.44 0.08))
          (mbc mb #xD4DADE)                              ; the bright edge
          (with-xform (mb (xform :y 0.8 :z 0.3)) (mb-box mb 0.012 1.44 0.025))
          (mbc mb #x2A2A2E)                              ; chips bitten out of the edge
          (loop for (y d) in '((0.35 0.03) (0.62 0.02) (0.9 0.035) (1.21 0.025))
                do (with-xform (mb (xform :y y :z 0.3 :roll 0.6)) (mb-box mb 0.03 d d)))
          (mbc mb #x3A3E42)                              ; the dark spine
          (with-xform (mb (xform :y 0.82 :z -0.085)) (mb-box mb 0.05 1.46 0.03))
          (mbc mb #xC9A04A)                              ; brass cap on top, brass collar
          (with-xform (mb (xform :y 1.58 :z 0.1)) (mb-bevel-box mb 0.07 0.16 0.38 0.02))
          (with-xform (mb (xform :y 0.08 :z 0.07)) (mb-bevel-box mb 0.07 0.1 0.34 0.015))
          (mbc mb #xD9CFB0)                              ; long cloth-wrapped handle
          (with-xform (mb (xform :y -0.32)) (mb-box mb 0.05 0.72 0.05))
          (mbc mb #x7A6A50)
          (loop for i below 7 do (with-xform (mb (xform :y (- -0.04 (* i 0.1)) :roll 0.785)) (mb-box mb 0.035 0.035 0.058)))
          (mbc mb #xC9A04A)
          (with-xform (mb (xform :y -0.7)) (mb-bevel-box mb 0.065 0.05 0.065 0.01))
          (mbc mb #x3E8E3A)                              ; green tassel off the pommel
          (with-xform (mb (xform :y -0.76)) (mb-box mb 0.04 0.06 0.04))
          (with-xform (mb (xform :y -0.9 :z -0.02 :pitch 0.2)) (mb-box mb 0.05 0.22 0.03))))

;;; ---------------------------------------------------------------- poses
(defpose :ke-stance ()
  (:root :u -0.06) (:pelvis :twist 18) (:spine :flex 10) (:chest :twist -12) (:head :flex -6 :twist -6)
  (:arm-r :flex 30 :side 30) (:elbow-r :flex 45) (:hand-r :flex -55)
  (:arm-l :flex 10 :side 22) (:elbow-l :flex 30)
  (:thigh-r :flex -12 :side 12) (:thigh-l :flex 25 :side 8) (:knee-r :flex 25) (:knee-l :flex 30))

(defclip :ke-stance (2.0 :loop t :base :ke-stance)
  (0) (1.0 (:chest :flex 3) (:root :u -0.07)))

;;; ---------------------------------------------------------------- base kit (§5.2 table)
;;; One-handed wild swings; the left hand joins the grip only for the two-handed Flash cuts.
(defstrike :ke-q1 (7 3 12 :base :ke-stance)            ; wild slash: diagonal down, 0.8 m lunge
  (0)
  (4 (:chest :twist -30) (:arm-r :flex 155 :side 35) (:elbow-r :flex 30) (:hand-r :twist -15 :flex -15) (:spine :flex 0))
  (:s :snap (:arm-r :flex 40 :side -10) (:elbow-r :flex 10) (:hand-r :twist -15 :flex -75) (:chest :twist 40) (:spine :flex 24)
      (:root :f 0.4 :u -0.08) (:thigh-l :flex 45) (:knee-l :flex 40))
  (:a (:chest :twist 45) (:arm-r :flex 30 :side -15))
  (:end :ke-stance))
(defstrike :ke-q2 (7 3 13 :base :ke-stance)            ; backhand
  (0)
  (4 (:chest :twist 60) (:spine :side 10) (:arm-r :side -15 :flex 75) (:elbow-r :flex 15) (:hand-r :twist 55 :flex -80))
  (:s :snap (:chest :twist -60) (:arm-r :side 90 :flex 30) (:elbow-r :flex 10) (:hand-r :twist 5 :flex -70) (:spine :side 0)
      (:root :f 0.3))
  (:a (:chest :twist -66) (:arm-r :side 95 :flex 25))
  (:end :ke-stance))
(defstrike :ke-q3 (11 4 22 :base :ke-stance)           ; spinning cut
  (0)
  (7 (:root :u -0.12 :yaw 0) (:knees :flex 40) (:chest :twist -20) (:arm-r :side 85 :flex 0) (:elbow-r :flex 5)
     (:hand-r :twist -5 :flex -90) (:arm-l :side 60 :flex 10))
  (:s :snap (:root :yaw 360 :u -0.1 :f 0.3) (:chest :twist 30))
  (:a (:root :yaw 380))
  (:end :ke-stance (:root :yaw 360)))
(defstrike :ke-f1 (16 4 20 :base :ke-stance)           ; two-handed kendo cut
  (0)
  (10 (:root :u 0.05) (:arms :flex 175 :side 5) (:elbows :flex 25) (:hand-r :twist 0 :flex -50) (:chest :twist 0) (:spine :flex -10)
      (:pelvis :twist 0) (:head :flex -10))
  (:s :snap (:root :u -0.3 :f 0.35) (:spine :flex 45) (:arms :flex 25 :side 0) (:elbows :flex 5) (:hand-r :twist -10 :flex -35)
      (:knees :flex 70) (:thighs :flex 55))
  (:a (:spine :flex 48))
  (:end :ke-stance))
(defstrike :ke-f2 (20 5 28 :base :ke-stance)           ; rising cleave: launcher
  (0)
  (14 (:root :u -0.3) (:arm-r :flex -30 :side 20) (:hand-r :twist 155 :flex 15) (:arm-l :flex -10 :side 15) (:elbow-l :flex 60)
      (:knees :flex 60) (:spine :flex 30) (:chest :twist 20))
  (:s :snap (:root :u 0.12) (:arm-r :flex 172 :side 5) (:hand-r :twist -155 :flex 15) (:arm-l :flex 160 :side 5) (:elbow-l :flex 20)
      (:spine :flex -22) (:knees :flex 10) (:head :flex -25) (:chest :twist 0))
  (:a (:arms :flex 176))
  (:end :ke-stance))
(defclip :ke-stance-hold (1.0 :loop t :base :ke-stance) ; "Kitte miro yo": arms flung wide (blend 6 f in)
  (0 (:root :u -0.02) (:pelvis :twist 0) (:chest :twist 0) (:spine :flex -12) (:head :flex -12 :twist 0)
     (:arms :side 78 :flex 15) (:elbows :flex 15) (:hand-r :twist 0 :flex -90) (:thigh-r :flex -5 :side 14) (:thigh-l :flex 5 :side 14)
     (:knees :flex 20))
  (0.5 (:spine :flex -14) (:arms :side 80) (:root :u -0.03)))
(defstrike :ke-stance-cut (8 4 24 :base :ke-stance)    ; the stance released: a huge cross-body cut
  (0 (:root :u -0.02) (:pelvis :twist 0) (:chest :twist -20) (:spine :flex -12) (:arms :side 78 :flex 15) (:elbows :flex 15)
     (:hand-r :twist 0 :flex -90))
  (:s :snap (:chest :twist 75) (:arm-r :flex 80 :side 10) (:hand-r :twist 5 :flex -85) (:root :f 0.5 :u -0.15) (:spine :flex 20)
      (:thigh-l :flex 50) (:knee-l :flex 55) (:arm-l :side 40 :flex 20))
  (:a (:chest :twist 85) (:arm-r :flex 75 :side -10))
  (:end :ke-stance))
(defstrike :ke-buttagiru (22 4 26 :base :ke-stance)    ; "Buttagiru": leap, two-handed overhead chop
  (0)
  (6 (:root :u -0.3) (:knees :flex 80) (:thighs :flex 60) (:spine :flex 30) (:arms :flex 40) (:elbows :flex 60))
  (12 (:root :u 0.6) (:thighs :flex 50) (:knees :flex 80) (:arms :flex 178 :side 5) (:elbows :flex 25) (:hand-r :twist 0 :flex -50)
      (:spine :flex -20) (:head :flex -15))
  (18 (:root :u 0.75) (:spine :flex -25))
  (:s :snap (:root :u -0.35 :f 0.4) (:spine :flex 58) (:arms :flex 20 :side 0) (:elbows :flex 5) (:hand-r :twist -10 :flex -35)
      (:knees :flex 90) (:thighs :flex 70) (:head :flex -30))
  (:a)
  (:end :ke-stance))
(defclip :ke-charge (0.4 :loop t :base :ke-stance)     ; SP2 dash: blade low and back, charging
  (0 (:spine :flex 28) (:head :flex -25) (:chest :twist -20) (:arm-r :flex -40 :side 35) (:elbow-r :flex 15) (:hand-r :twist 150 :flex 10)
     (:thigh-r :flex 55) (:knee-r :flex 25) (:thigh-l :flex -35) (:knee-l :flex 50) (:root :u -0.1))
  (0.2 (:thigh-l :flex 55) (:knee-l :flex 25) (:thigh-r :flex -35) (:knee-r :flex 50) (:root :u -0.05)))
(defstrike :ke-flurry (4 36 24 :base :ke-stance)       ; cuts at f4 10 16 22 28, launcher at f40
  (0 (:chest :twist -30) (:arm-r :flex 150 :side 35) (:elbow-r :flex 30) (:hand-r :twist -15 :flex -15))
  (4 :snap (:arm-r :flex 40 :side -10) (:elbow-r :flex 10) (:hand-r :twist -15 :flex -75) (:chest :twist 40) (:spine :flex 20))
  (10 :snap (:chest :twist -55) (:arm-r :side 90 :flex 30) (:hand-r :twist 5 :flex -70) (:spine :flex 10))
  (16 :snap (:chest :twist 50) (:arm-r :flex 60 :side -15) (:hand-r :twist -15 :flex -75) (:spine :flex 22))
  (22 :snap (:chest :twist -60) (:arm-r :side 95 :flex 40) (:hand-r :twist 5 :flex -70) (:spine :flex 12))
  (28 :snap (:chest :twist 55) (:arm-r :flex 45 :side -20) (:hand-r :twist -15 :flex -75) (:spine :flex 25))
  (34 (:root :u -0.3) (:arm-r :flex -30 :side 20) (:hand-r :twist 155 :flex 15) (:knees :flex 60) (:spine :flex 30) (:chest :twist 20))
  (40 :snap (:root :u 0.12) (:arm-r :flex 172 :side 5) (:hand-r :twist -155 :flex 15) (:spine :flex -22) (:knees :flex 10)
      (:head :flex -25) (:chest :twist 0))
  (46 (:arm-r :flex 176))
  (:end :ke-stance))
(defclip :ke-breaker (0.4 :loop t :base :ke-stance)    ; Breaker aura dash: shoulder first
  (0 (:spine :flex 25) (:chest :twist 45) (:head :twist -35 :flex -15) (:arm-l :flex 20 :side 10) (:elbow-l :flex 90)
     (:arm-r :flex -20 :side 25) (:hand-r :twist 150 :flex 10)
     (:thigh-r :flex 50) (:knee-r :flex 25) (:thigh-l :flex -30) (:knee-l :flex 50) (:root :u -0.1))
  (0.2 (:thigh-l :flex 50) (:knee-l :flex 25) (:thigh-r :flex -30) (:knee-r :flex 50) (:root :u -0.05)))
(defstrike :ke-shoulder (8 4 18 :base :ke-stance)      ; shoulder charge
  (0 (:spine :flex 25) (:chest :twist 45) (:head :twist -35 :flex -15) (:arm-l :flex 20 :side 10) (:elbow-l :flex 90) (:root :u -0.1))
  (:s :snap (:spine :flex 12) (:chest :twist 70) (:shoulder-l :flex 20) (:arm-l :flex 10 :side 30) (:elbow-l :flex 100)
      (:root :f 0.6 :u -0.18) (:thigh-l :flex 55) (:knee-l :flex 45) (:thigh-r :flex -25) (:head :twist -40))
  (:a)
  (:end :ke-stance))
(defclip :ke-kikon (1.9 :base :ke-stance)              ; three reckless cuts, laughing; the last goes through
  (0)
  (0.25 (:chest :twist -30) (:arm-r :flex 155 :side 35) (:elbow-r :flex 30) (:hand-r :twist -15 :flex -15))
  (0.35 :snap (:arm-r :flex 40 :side -10) (:elbow-r :flex 10) (:hand-r :twist -15 :flex -75) (:chest :twist 40) (:spine :flex 22)
        (:root :f 0.3))
  (0.65 (:chest :twist 60) (:arm-r :side -15 :flex 75) (:elbow-r :flex 15) (:hand-r :twist 55 :flex -80) (:spine :flex 10))
  (0.75 :snap (:chest :twist -60) (:arm-r :side 90 :flex 30) (:hand-r :twist 5 :flex -70) (:root :f 0.5))
  (1.05 (:root :u 0.05 :f 0.5) (:arms :flex 176 :side 5) (:elbows :flex 20) (:hand-r :twist 0 :flex -50) (:spine :flex -15)
        (:chest :twist 0) (:head :flex -30))
  (1.2 :snap (:root :u -0.35 :f 1.4) (:spine :flex 58) (:arms :flex 20 :side 0) (:elbows :flex 5) (:hand-r :twist -10 :flex -35)
       (:knees :flex 85) (:thighs :flex 65) (:head :flex -35))
  (1.5 (:root :u -0.2 :f 1.4) (:spine :flex -15) (:head :flex -40) (:arm-l :side 40 :flex 10) (:knees :flex 40) (:thighs :flex 30))
  (1.9 :ke-stance (:root :f 1.4)))

;;; ---------------------------------------------------------------- intro / win
(defpose :ke-shoulder-rest (:base :ke-stance)          ; the blade resting on his right shoulder, blade pointing back
  (:pelvis :twist 10) (:chest :twist -5) (:spine :flex 2) (:head :flex -10 :twist 10)
  (:arm-r :flex 110 :side 25 :twist 0) (:elbow-r :flex 130) (:hand-r :twist 0 :flex -90)
  (:arm-l :flex 5 :side 18) (:elbow-l :flex 20))
(defclip :ke-intro (2.0 :base :ke-shoulder-rest)       ; grin, sword on the shoulder, a laugh, then ready
  (0) (0.7 (:head :flex -30) (:spine :flex -8)) (0.9 (:head :flex -25)) (1.1 (:head :flex -32)) (1.4 (:head :flex -12))
  (2.0 :ke-stance))
(defclip :ke-win (2.0 :base :ke-shoulder-rest)         ; laughing, holds
  (0) (0.5 (:head :flex -35) (:spine :flex -12) (:arm-l :flex 10 :side 30)) (0.8 (:head :flex -28)) (1.1 (:head :flex -36))
  (1.6 (:head :flex -20) (:spine :flex -4)) (2.0 (:head :flex -20) (:spine :flex -4)))

;;; ---------------------------------------------------------------- awakening: NOME, NOZARASHI
(defpose :ke-n-stance (:base :ke-stance)               ; Nozarashi: the cleaver across the right shoulder
  (:pelvis :twist 15) (:chest :twist -8) (:spine :flex 6) (:head :flex -8)
  (:arm-r :flex 95 :side 30) (:elbow-r :flex 120) (:hand-r :twist 0 :flex -85)
  (:arm-l :flex 15 :side 22) (:elbow-l :flex 25))
(defclip :ke-patch (0.5 :base :ke-stance)              ; tears the eyepatch off (hide :eyepatch from 0.3 s)
  (0)
  (0.2 (:arm-l :flex 150 :side -35) (:elbow-l :flex 125) (:hand-l :flex 20) (:head :flex 10 :twist 10) (:chest :twist 10))
  (0.3 :snap (:arm-l :flex 110 :side 70) (:elbow-l :flex 10) (:head :flex -25 :twist -10) (:spine :flex -15) (:chest :twist -15))
  (0.5 (:arm-l :flex 90 :side 75) (:head :flex -30) (:spine :flex -18)))
(defclip :ke-nome (0.7 :base :ke-stance)               ; "Nome": blade up (weapon -> :nozarashi at 0.35 s), then down
  (0 (:arm-l :flex 90 :side 75) (:head :flex -30) (:spine :flex -18))
  (0.3 (:arm-r :flex 170 :side 10) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -10) (:arm-l :flex 40 :side 30) (:head :flex -30))
  (0.45 (:arm-r :flex 172))
  (0.7 :ke-n-stance))
(defclip :ke-n-stance (2.0 :loop t :base :ke-n-stance)
  (0) (1.0 (:chest :flex 3) (:root :u -0.07)))
(defstrike :ke-meteor (26 4 30 :base :ke-n-stance)     ; "Split the meteor": the huge two-handed cleave
  (0)
  (18 (:root :u 0.05) (:arms :flex 180 :side 5) (:elbows :flex 30) (:hand-r :twist 0 :flex -50) (:spine :flex -22) (:head :flex -20)
      (:chest :twist 0) (:pelvis :twist 0))
  (:s :snap (:root :u -0.42 :f 0.4) (:spine :flex 62) (:arms :flex 20 :side 0) (:elbows :flex 5) (:hand-r :twist -10 :flex -35)
      (:knees :flex 90) (:thighs :flex 68) (:head :flex -35))
  (:a)
  (44 (:root :u -0.4 :f 0.4) (:spine :flex 58))
  (:end :ke-n-stance))
(defclip :ke-kikon-n (1.5 :base :ke-n-stance)          ; the sky split: one colossal cleave
  (0)
  (0.35 (:root :u -0.2) (:chest :twist -80) (:arms :side 80 :flex 30) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -90)
        (:arm-l :side 20 :flex 60) (:knees :flex 50) (:spine :flex 15))
  (0.42 :snap (:chest :twist 80) (:arm-r :flex 80 :side 5) (:arm-l :flex 75 :side -5) (:hand-r :twist 5 :flex -85)
        (:root :f 0.6 :u -0.3) (:thigh-l :flex 55) (:knee-l :flex 60) (:spine :flex 25))
  (1.0 (:chest :twist 88))
  (1.5 :ke-n-stance))
