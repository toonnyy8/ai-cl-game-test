;;;; ken-art.lisp — ZARAKI KENPACHI (TYBW) as art data: his body, his notched katana and the true
;;;; Shikai NOZARASHI (a giant cleaver), and every :ke-* pose and clip (design §5.2). Attack clips
;;;; use DEFSTRIKE, so each reaches its hit pose at frame S and is back in his stance at S+A+R.
;;;; Look: 2.02 m, broad, long loose black spiky hair (no bells), both eyes open (no eyepatch in any
;;;; form: TYBW canon, the user's decision 2026-09-26), scar down the left side of the face, a grin, sleeveless tattered white haori over the black shihakusho, bare muscular arms.
(in-package :duel)

;;; ---------------------------------------------------------------- body
;; Proportions (user review 1: realistic, not chibi; TYBW's ~8 heads): a small narrow head and hair (the
;; girth factors), a broad but not boxy chest, long legs and arms (:props, the limb shapes as long), big hands.
(defbody :kenpachi (:scale 1.07 :width 1.18 :hunch 0 :hurt-r 0.45 :hurt-h 2.0
                    :girth ((:neck 0.85 1.3 0.85) (:chest 0.8 1.0 0.9) (:spine 0.8 1.0 0.9) (:pelvis 0.82 1.0 0.9)
                            (:shoulder-r 0.85 0.85 0.85) (:shoulder-l 0.85 0.85 0.85)
                            (:upper-arm-r 0.95 1.1 0.95) (:upper-arm-l 0.95 1.1 0.95)
                            (:lower-arm-r 0.95 1.1 0.95) (:lower-arm-l 0.95 1.1 0.95)
                            (:hand-r 1.2 1.25 1.2) (:hand-l 1.2 1.25 1.2)
                            (:thigh-r 0.95 1.1 0.95) (:thigh-l 0.95 1.1 0.95) (:shin-r 0.95 1.1 0.95) (:shin-l 0.95 1.1 0.95))
                    ;; v4 notan palette (docs/STYLE_STORM_DESIGN.md §2.5): black robe and solid black hair,
                    ;; the tattered haori V4 white, muted skin
                    :palette ((:skin #xCFA48C) (:skin-d #xB08C78) (:black #x16161E) (:white #xE8E8E4)
                              (:hair #x0C0C12) (:scar #x5A3430) (:teeth #xECECE8)
                              (:eye #x0C0C12) (:pupil #x0C0C12) (:crease #x7A5448) (:fold #xD8DCE4) (:obi #xC8CCD6) (:tabi #xE8E8E4) (:sole #x262833))
                    :rim (#xFFE070 0.2)
                    :props (:shoulders 1.08 :arms 1.1 :legs 1.1))  ; the bare arms hang clear of the haori
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
  ;; the haori over the torso: one rounded white shell, the black robe and the bare chest at its open front
  (:spine (:bevel 0.44 0.25 0.27 0.04 :at (0 0.11 -0.005) :c :white)
          (:box 0.14 0.25 0.02 :at (0 0.11 0.155) :c :black))
  (:chest (:bevel 0.5 0.33 0.29 0.05 :at (0 0.105 -0.005) :c :white)
          (:box 0.15 0.3 0.02 :at (0 0.1 0.156) :c :skin)                                ; the bare chest in the open collar ...
          (:box 0.05 0.33 0.02 :at (0.045 0.1 0.163) :rot (0 0 -14) :c :black)          ; ... between the robe's lapels
          (:box 0.05 0.33 0.02 :at (-0.045 0.1 0.163) :rot (0 0 14) :c :black))
  (:neck (:cyl 0.075 0.1 :at (0 0.04 0) :c :skin))
  ;; head in metres (not girth-scaled; x and z sizes x the body :width 1.18): a skull sphere under the hair,
  ;; a flat-fronted face (front at z 0.073) carrying the flat face shapes, one set per expression (tags :face-neutral,
  ;; :face-shout, :face-hurt: DRAW-BODY :face shows one); the scar and the face box are shared
  (:head (:sphere 0.061 :stretch 0.04 :at (0 0.13 -0.012) :seg 10 :c :skin)                ; skull
         (:bevel 0.1 0.15 0.076 0.018 :at (0 0.085 0.028) :c :skin)                         ; face, jaw
         (:bevel 0.07 0.03 0.06 0.01 :at (0 0.012 0.036) :c :skin)                          ; chin
         (:box 0.016 0.04 0.025 :at (0.064 0.105 0.0) :c :skin) (:box 0.016 0.04 0.025 :at (-0.064 0.105 0.0) :c :skin)
         (:wedge 0.024 0.042 0.03 :at (0 0.097 0.086) :rot (180 0 0) :c :skin)            ; nose
         ;; the left eye (his left = -x): narrow, small pupil, a heavy slanted lid and brow
         (:box 0.024 0.011 0.004 :at (-0.028 0.118 0.075) :c :teeth :tag :face-neutral)
         (:box 0.008 0.011 0.005 :at (-0.024 0.118 0.0755) :c :pupil :tag :face-neutral)
         (:box 0.035 0.006 0.005 :at (-0.028 0.125 0.0756) :rot (0 0 -10) :c :eye :tag :face-neutral)
         (:box 0.04 0.009 0.006 :at (-0.03 0.141 0.0757) :rot (0 0 -16) :c :eye :tag :face-neutral)
         ;; the right eye
         (:box 0.024 0.011 0.004 :at (0.028 0.118 0.075) :c :teeth :tag :face-neutral)
         (:box 0.008 0.011 0.005 :at (0.024 0.118 0.0755) :c :pupil :tag :face-neutral)
         (:box 0.035 0.006 0.005 :at (0.028 0.125 0.0756) :rot (0 0 10) :c :eye :tag :face-neutral)
         (:box 0.04 0.009 0.006 :at (0.03 0.141 0.0757) :rot (0 0 16) :c :eye :tag :face-neutral)
         (:box 0.006 0.12 0.004 :at (-0.037 0.108 0.0765) :rot (0 0 8) :c :scar)                ; scar through the left eye
         ;; the grin: a wide dark mouth, a row of teeth, corners pulled up
         (:box 0.06 0.02 0.004 :at (0 0.043 0.074) :c :eye :tag :face-neutral)
         (:box 0.054 0.009 0.004 :at (0 0.047 0.0746) :c :teeth :tag :face-neutral)
         (:box 0.014 0.006 0.004 :at (0.034 0.05 0.0746) :rot (0 0 32) :c :eye :tag :face-neutral)
         (:box 0.014 0.006 0.004 :at (-0.034 0.05 0.0746) :rot (0 0 -32) :c :eye :tag :face-neutral)
         ;; :face-shout, the berserker's roar / maniac laugh: eyes wide with pin pupils under a hard lid line, brows
         ;; high and hooked, the grin at full: a wide open dark mouth, both rows of teeth, corners up, cheek creases
         (:box 0.026 0.017 0.004 :at (-0.028 0.119 0.075) :c :teeth :tag :face-shout)
         (:box 0.005 0.006 0.005 :at (-0.026 0.119 0.0755) :c :pupil :tag :face-shout)
         (:box 0.032 0.004 0.004 :at (-0.028 0.1285 0.0757) :rot (0 0 -6) :c :eye :tag :face-shout)
         (:box 0.04 0.008 0.006 :at (-0.03 0.149 0.0757) :rot (0 0 -22) :c :eye :tag :face-shout)
         (:box 0.016 0.007 0.006 :at (-0.054 0.151 0.0762) :rot (0 0 50) :c :eye :tag :face-shout)
         (:box 0.026 0.017 0.004 :at (0.028 0.119 0.075) :c :teeth :tag :face-shout)
         (:box 0.005 0.006 0.005 :at (0.026 0.119 0.0755) :c :pupil :tag :face-shout)
         (:box 0.032 0.004 0.004 :at (0.028 0.1285 0.0757) :rot (0 0 6) :c :eye :tag :face-shout)
         (:box 0.04 0.008 0.006 :at (0.03 0.149 0.0757) :rot (0 0 22) :c :eye :tag :face-shout)
         (:box 0.016 0.007 0.006 :at (0.054 0.151 0.0762) :rot (0 0 -50) :c :eye :tag :face-shout)
         (:box 0.08 0.054 0.004 :at (0 0.041 0.074) :c :eye :tag :face-shout)                   ; the open mouth (Phase 6: bolder)
         (:box 0.07 0.01 0.004 :at (0 0.0625 0.0746) :c :teeth :tag :face-shout)                 ; upper teeth
         (:box 0.058 0.009 0.004 :at (0 0.0195 0.0746) :c :teeth :tag :face-shout)               ; lower teeth
         (:box 0.02 0.008 0.004 :at (0.048 0.069 0.0748) :rot (0 0 38) :c :eye :tag :face-shout) ; corners pulled up
         (:box 0.02 0.008 0.004 :at (-0.048 0.069 0.0748) :rot (0 0 -38) :c :eye :tag :face-shout)
         (:box 0.004 0.036 0.004 :at (0.037 0.083 0.0745) :rot (0 0 40) :c :crease :tag :face-shout)
         (:box 0.004 0.036 0.004 :at (-0.037 0.083 0.0745) :rot (0 0 -40) :c :crease :tag :face-shout)
         ;; :face-hurt, a grimacing grin: the left (scar) eye open, the right squeezed shut, brows knotted with two
         ;; creases between them, clenched teeth bared (the clench line and tooth gaps in ink), one corner up
         (:box 0.024 0.008 0.004 :at (-0.028 0.117 0.075) :c :teeth :tag :face-hurt)
         (:box 0.007 0.008 0.005 :at (-0.025 0.117 0.0755) :c :pupil :tag :face-hurt)
         (:box 0.034 0.007 0.005 :at (-0.028 0.1225 0.0758) :rot (0 0 -18) :c :eye :tag :face-hurt)
         (:box 0.022 0.003 0.004 :at (0.028 0.1155 0.075) :c :teeth :tag :face-hurt)
         (:box 0.034 0.009 0.005 :at (0.028 0.1195 0.0758) :rot (0 0 20) :c :eye :tag :face-hurt)
         (:box 0.026 0.003 0.004 :at (0.029 0.1105 0.0757) :rot (0 0 -8) :c :eye :tag :face-hurt)
         (:box 0.036 0.009 0.006 :at (-0.025 0.137 0.0757) :rot (0 0 -26) :c :eye :tag :face-hurt)
         (:box 0.036 0.009 0.006 :at (0.025 0.134 0.0757) :rot (0 0 28) :c :eye :tag :face-hurt)
         (:box 0.003 0.014 0.004 :at (-0.005 0.141 0.0757) :rot (0 0 -8) :c :crease :tag :face-hurt)
         (:box 0.003 0.014 0.004 :at (0.005 0.141 0.0757) :rot (0 0 8) :c :crease :tag :face-hurt)
         (:box 0.066 0.024 0.004 :at (0 0.043 0.074) :c :eye :tag :face-hurt)                   ; the bared mouth
         (:box 0.058 0.009 0.004 :at (0 0.0475 0.0746) :c :teeth :tag :face-hurt)                ; upper teeth
         (:box 0.056 0.008 0.004 :at (0 0.0375 0.0746) :c :teeth :tag :face-hurt)                ; lower teeth
         (:box 0.002 0.017 0.004 :at (-0.017 0.043 0.0752) :c :eye :tag :face-hurt)              ; tooth gaps
         (:box 0.002 0.017 0.004 :at (0 0.043 0.0752) :c :eye :tag :face-hurt)
         (:box 0.002 0.017 0.004 :at (0.017 0.043 0.0752) :c :eye :tag :face-hurt)
         (:box 0.018 0.007 0.004 :at (0.041 0.051 0.0748) :rot (0 0 32) :c :eye :tag :face-hurt) ; right corner up
         (:box 0.016 0.007 0.004 :at (-0.04 0.038 0.0748) :rot (0 0 22) :c :eye :tag :face-hurt) ; left corner dragged down
         (:box 0.004 0.03 0.004 :at (0.035 0.08 0.0745) :rot (0 0 36) :c :crease :tag :face-hurt)
         ;; long loose spiky hair: a cap over the skull, a back sheet, locks and spikes
         (:sphere 0.0695 :stretch 0.03 :at (0 0.15 -0.024) :seg 10 :c :hair)
         (:box 0.182 0.414 0.056 :at (0 0 -0.104) :rot (0 -8 0) :c :hair)
         (:cone 0.0413 0.324 :at (0.0805 0.045 -0.008) :rot (0 172 -14) :seg 4 :c :hair)      ; side locks
         (:cone 0.0413 0.324 :at (-0.0805 0.045 -0.008) :rot (0 172 14) :seg 4 :c :hair)
         (:cone 0.0338 0.234 :at (0.091 0.108 -0.056) :rot (0 160 -35) :seg 4 :c :hair)
         (:cone 0.0338 0.234 :at (-0.091 0.108 -0.056) :rot (0 160 35) :seg 4 :c :hair)
         (:cone 0.0375 0.216 :at (0.105 -0.18 -0.08) :rot (0 160 -20) :seg 4 :c :hair)
         (:cone 0.0375 0.234 :at (-0.105 -0.198 -0.08) :rot (0 160 20) :seg 4 :c :hair)
         (:cone 0.0375 0.198 :at (0.042 -0.27 -0.112) :rot (0 170 -8) :seg 4 :c :hair)
         (:cone 0.0375 0.216 :at (-0.042 -0.288 -0.112) :rot (0 170 8) :seg 4 :c :hair)
         (:cone 0.0375 0.216 :at (0.112 0.126 -0.064) :rot (0 140 -35) :seg 4 :c :hair)
         (:cone 0.0375 0.216 :at (-0.112 0.126 -0.064) :rot (0 140 35) :seg 4 :c :hair)
         (:cone 0.0375 0.234 :at (0.049 0.216 -0.112) :rot (0 115 -15) :seg 4 :c :hair)
         (:cone 0.0375 0.234 :at (-0.049 0.216 -0.112) :rot (0 115 15) :seg 4 :c :hair)
         (:cone 0.0225 0.108 :at (0.028 0.19 0.085) :rot (0 160 -10) :seg 4 :c :hair)         ; fringe
         (:cone 0.0225 0.108 :at (-0.035 0.19 0.085) :rot (0 160 15) :seg 4 :c :hair)
         ;; white highlight strokes on the black hair (Kubo's white-on-black)
         (:box 0.006 0.05 0.004 :at (0.028 0.215 0.036) :rot (0 -48 -12) :c :fold)
         (:box 0.006 0.04 0.004 :at (-0.034 0.21 0.034) :rot (0 -48 16) :c :fold)
         (:box 0.006 0.14 0.004 :at (0.035 -0.02 -0.136) :rot (0 -8 3) :c :fold)
         (:box 0.006 0.11 0.004 :at (-0.045 -0.05 -0.136) :rot (0 -8 -4) :c :fold))
  (:shoulder-r (:sphere 0.09 :at (0.06 -0.03 0) :c :skin)
               (:box 0.1 0.04 0.27 :at (-0.01 0.05 0) :rot (0 0 -10) :c :white))
  (:shoulder-l (:sphere 0.09 :at (-0.06 -0.03 0) :c :skin)
               (:box 0.1 0.04 0.27 :at (0.01 0.05 0) :rot (0 0 10) :c :white))
  (:upper-arm-r (:cyl 0.05 0.3 :top 0.056 :seg 8 :at (0 -0.15 0) :c :skin) (:sphere 0.05 :at (0 -0.13 0.028) :c :skin-d))
  (:upper-arm-l (:cyl 0.05 0.3 :top 0.056 :seg 8 :at (0 -0.15 0) :c :skin) (:sphere 0.05 :at (0 -0.13 0.028) :c :skin-d))
  (:lower-arm-r (:cyl 0.036 0.27 :top 0.048 :seg 8 :at (0 -0.125 0) :c :skin) (:sphere 0.045 :at (0 0 0) :c :skin))
  (:lower-arm-l (:cyl 0.036 0.27 :top 0.048 :seg 8 :at (0 -0.125 0) :c :skin) (:sphere 0.045 :at (0 0 0) :c :skin))
  (:hand-r (:bevel 0.075 0.1 0.08 0.02 :at (0 -0.045 0) :c :skin))
  (:hand-l (:bevel 0.075 0.1 0.08 0.02 :at (0 -0.045 0) :c :skin))
  (:thigh-r (:cyl 0.092 0.46 :top 0.088 :seg 10 :at (0 -0.22 0) :c :black))
  (:thigh-l (:cyl 0.092 0.46 :top 0.088 :seg 10 :at (0 -0.22 0) :c :black))
  (:shin-r (:cyl 0.11 0.34 :top 0.094 :seg 10 :at (0 -0.15 0) :c :black)
          (:box 0.005 0.2 0.004 :at (0.03 -0.16 0.125) :rot (0 -4 -5) :c :fold) (:box 0.085 0.12 0.09 :at (0 -0.37 0) :c :tabi))
  (:shin-l (:cyl 0.11 0.34 :top 0.094 :seg 10 :at (0 -0.15 0) :c :black)
          (:box 0.005 0.22 0.004 :at (-0.02 -0.15 0.125) :rot (0 -4 4) :c :fold) (:box 0.085 0.12 0.09 :at (0 -0.37 0) :c :tabi))
  (:foot-r (:bevel 0.09 0.06 0.23 0.02 :at (0 -0.02 0.06) :c :tabi) (:box 0.1 0.02 0.25 :at (0 -0.055 0.06) :c :sole))
  (:foot-l (:bevel 0.09 0.06 0.23 0.02 :at (0 -0.02 0.06) :c :tabi) (:box 0.1 0.02 0.25 :at (0 -0.055 0.06) :c :sole)))

;; the Bankai's oni (docs/DUEL_KEN_BANKAI.md §12, the user's decisions 2026-09-28: 片腕 stays the oni): the same body, the
;; skin a MUTED crimson (S <= 0.45: not a spot colour), two short horns at the hairline, the pupils white (irisless), four
;; thin BLOOD cracks on the right forearm (:crack-1 .. :crack-4, one shown per spent pip) and the torn forearm of 片腕
;; (:arm-wreck: skin shards, raw strips, ink splits)
(body-variant :kenpachi-oni :kenpachi
  :palette '((:skin #x9A4A42) (:skin-d #x7A3630) (:pupil #xF4F2EA) (:horn #x6E302C) (:blood #xD0101C) (:wound #x5A1418)
            (:split #x101018))
  :parts '((:head (:cone 0.02 0.11 :at (0.042 0.245 0.07) :rot (0 -20 -18) :seg 6 :c :horn)
                 (:cone 0.02 0.11 :at (-0.042 0.245 0.07) :rot (0 -20 18) :seg 6 :c :horn))
          (:lower-arm-r (:glow 1.6 (:box 0.006 0.075 0.004 :at (0.0 -0.06 0.052) :rot (0 0 25) :c :blood) :crack-1)
                        (:glow 1.6 (:box 0.004 0.075 0.006 :at (0.052 -0.1 0.012) :rot (0 0 -20) :c :blood) :crack-2)
                        (:glow 1.6 (:box 0.006 0.075 0.004 :at (-0.01 -0.15 0.05) :rot (0 0 -30) :c :blood) :crack-3)
                        (:glow 1.6 (:box 0.004 0.075 0.006 :at (0.05 -0.19 -0.01) :rot (0 0 15) :c :blood) :crack-4)
                        (:wedge 0.035 0.07 0.02 :at (0.03 -0.07 0.045) :rot (0 0 30) :c :skin-d :tag :arm-wreck)
                        (:wedge 0.03 0.06 0.02 :at (-0.03 -0.16 0.045) :rot (0 0 -25) :c :skin-d :tag :arm-wreck)
                        (:box 0.014 0.12 0.008 :at (0.004 -0.12 0.052) :rot (0 0 10) :c :wound :tag :arm-wreck)
                        (:box 0.008 0.1 0.012 :at (0.054 -0.15 0.0) :rot (0 0 -12) :c :wound :tag :arm-wreck)
                        (:box 0.004 0.13 0.006 :at (-0.02 -0.1 0.056) :rot (0 0 -18) :c :split :tag :arm-wreck)
                        (:box 0.006 0.11 0.004 :at (0.056 -0.08 0.02) :rot (0 0 8) :c :split :tag :arm-wreck))))

;;; ---------------------------------------------------------------- weapons
(defweapon :ken-katana (:length 1.08)                  ; battered, notched, chipped
  (:solid (mb-blade mb :width 0.036 :guard-color '(0.25 0.24 0.22) :handle-color '(0.1 0.09 0.09) :wrap-color '(0.3 0.28 0.26) :blade nil))
  (:solid :ink 0 (mb-blade mb :length 1.02 :width 0.036 :curve 0.018 :blade-color '(0.55 0.57 0.6) :edge-color '(0.78 0.8 0.82)
                              :hilt nil)
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
          (mbc mb #xA8A290)                              ; dull brass cap on top, collar (colour is spot-only)
          (with-xform (mb (xform :y 1.58 :z 0.1)) (mb-bevel-box mb 0.07 0.16 0.38 0.02))
          (with-xform (mb (xform :y 0.08 :z 0.07)) (mb-bevel-box mb 0.07 0.1 0.34 0.015))
          (mbc mb #xD8D6CC)                              ; long cloth-wrapped handle
          (with-xform (mb (xform :y -0.32)) (mb-box mb 0.05 0.72 0.05))
          (mbc mb #x5A5650)
          (loop for i below 7 do (with-xform (mb (xform :y (- -0.04 (* i 0.1)) :roll 0.785)) (mb-box mb 0.035 0.035 0.058)))
          (mbc mb #xA8A290)
          (with-xform (mb (xform :y -0.7)) (mb-bevel-box mb 0.065 0.05 0.065 0.01))
          (mbc mb #x3A4A3E)                              ; the tassel, a dark green-grey
          (with-xform (mb (xform :y -0.76)) (mb-box mb 0.04 0.06 0.04))
          (with-xform (mb (xform :y -0.9 :z -0.02 :pitch 0.2)) (mb-box mb 0.05 0.22 0.03))))

;; the Bankai's broken cleaver (anime ep. 44): Nozarashi's slab snapped off on a diagonal at ~1 m, ink-black with a white
;; edge line, no guard, no cap, a long cloth-wrapped tang like the first Zangetsu's hilt; no fire, no glow
(defweapon :ke-broken (:length 1.12 :base 0.18)
  (:solid (mbc mb #x1C1C22)                              ; the slab, snapped
          (with-xform (mb (xform :y 0.47 :z 0.07)) (mb-bevel-box mb 0.04 0.84 0.3 0.008))
          (with-xform (mb (xform :y 0.95 :z 0.0 :pitch 0.55)) (mb-bevel-box mb 0.04 0.3 0.16 0.006))   ; the diagonal break
          (mbc mb #x3A3A42)                              ; a dark fuller along the spine side
          (with-xform (mb (xform :y 0.5 :z -0.03)) (mb-box mb 0.044 0.72 0.022))
          (mbc mb #xE8E8E4)                              ; the white edge line
          (with-xform (mb (xform :y 0.45 :z 0.22)) (mb-box mb 0.012 0.8 0.018))
          (mbc mb #x0C0C10)                              ; the jagged break: bitten shards
          (loop for (y z r) in '((0.88 0.2 0.5) (0.98 0.12 -0.4) (1.06 0.03 0.7))
                do (with-xform (mb (xform :y y :z z :roll r)) (mb-box mb 0.046 0.04 0.05)))
          (mbc mb #xD8D6CC)                              ; the long cloth-wrapped tang
          (with-xform (mb (xform :y -0.4)) (mb-box mb 0.048 0.86 0.048))
          (mbc mb #x3A3634)
          (loop for i below 9 do (with-xform (mb (xform :y (- -0.02 (* i 0.095)) :roll 0.785)) (mb-box mb 0.034 0.034 0.056)))
          (mbc mb #xD8D6CC)                              ; the loose end of the cloth, hanging
          (with-xform (mb (xform :y -0.92 :z -0.03 :pitch 0.3)) (mb-box mb 0.04 0.24 0.012))))

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
  (3 (:chest :twist -32) (:arm-r :flex 158 :side 36) (:elbow-r :flex 30) (:hand-r :twist -15 :flex -15) (:spine :flex -2)
     (:root :u -0.03) (:head :twist 8))                                            ; anticipation, held
  (5 (:chest :twist -37) (:arm-r :flex 164 :side 38) (:spine :flex -5) (:root :u -0.04))
  (:s :snap (:arm-r :flex 40 :side -10) (:elbow-r :flex 10) (:hand-r :twist -15 :flex -75) (:chest :twist 40) (:spine :flex 24)
      (:root :f 0.45 :u -0.1) (:thigh-l :flex 50) (:knee-l :flex 45) (:head :twist -6))
  (:a (:chest :twist 50) (:arm-r :flex 26 :side -20) (:spine :flex 28) (:root :f 0.5 :u -0.12))    ; overshoot
  (15 (:chest :twist 46) (:arm-r :flex 30 :side -16) (:spine :flex 25) (:root :f 0.47 :u -0.1))
  (:end :ke-stance))
(defstrike :ke-q2 (7 3 13 :base :ke-stance)            ; backhand
  (0)
  (3 (:chest :twist 60) (:spine :side 10) (:arm-r :side -15 :flex 75) (:elbow-r :flex 15) (:hand-r :twist 55 :flex -80)
     (:root :u -0.03) (:head :twist -10))
  (5 (:chest :twist 67) (:spine :side 13) (:arm-r :side -20 :flex 78) (:root :u -0.05))
  (:s :snap (:chest :twist -60) (:arm-r :side 90 :flex 30) (:elbow-r :flex 10) (:hand-r :twist 5 :flex -70) (:spine :side 0)
      (:root :f 0.36 :u -0.06) (:thigh-l :flex 38) (:knee-l :flex 38) (:head :twist 8))
  (:a (:chest :twist -72) (:arm-r :side 100 :flex 22) (:root :f 0.4 :u -0.08))
  (15 (:chest :twist -67) (:arm-r :side 96 :flex 25) (:root :f 0.38 :u -0.06))
  (:end :ke-stance))
(defstrike :ke-q3 (11 4 22 :base :ke-stance)           ; spinning cut
  (0)
  (5 (:root :u -0.12 :yaw 0) (:knees :flex 40) (:chest :twist -20) (:arm-r :side 85 :flex 0) (:elbow-r :flex 5)
     (:hand-r :twist -5 :flex -90) (:arm-l :side 60 :flex 10))
  (8 (:root :u -0.16 :yaw -12) (:knees :flex 48) (:chest :twist -28))             ; coiled: held, a little further
  (:s :snap (:root :yaw 360 :u -0.1 :f 0.35) (:chest :twist 30) (:knees :flex 40))
  (:a (:root :yaw 386 :u -0.12 :f 0.38) (:chest :twist 36))                         ; overshoot
  (22 (:root :yaw 374 :u -0.1 :f 0.36) (:chest :twist 32))
  (:end :ke-stance (:root :yaw 360)))
;; J3 KENKA-GERI (docs/DUEL_STRINGS.md §3.3): no school: the rear knee chambered and held, a flat front kick to the gut,
;; leaning back, the sword thrown out wide the other way
(defstrike :ke-kick (8 3 18 :base :ke-stance)          ; J3 KENKA-GERI: the street fighter's front kick
  (0)
  (3 (:root :u 0.02 :f -0.05) (:spine :flex -6) (:chest :twist -10) (:thigh-r :flex 58 :side 4) (:knee-r :flex 96)
     (:thigh-l :flex 12) (:knee-l :flex 20) (:arm-r :flex 38 :side 58) (:elbow-r :flex 22) (:hand-r :flex -40)
     (:arm-l :flex 30 :side 12) (:elbow-l :flex 60) (:head :flex -4))                                ; chambered, held
  (6 (:thigh-r :flex 64) (:knee-r :flex 102) (:spine :flex -9) (:root :f -0.07))
  (:s :snap (:root :f 0.45 :u 0.0) (:spine :flex -18) (:chest :twist 12) (:thigh-r :flex 92 :side 0) (:knee-r :flex 4)
      (:thigh-l :flex -6) (:knee-l :flex 14) (:arm-r :flex 30 :side 95) (:elbow-r :flex 5) (:hand-r :flex -20)
      (:arm-l :flex 40 :side 30) (:elbow-l :flex 40) (:head :flex 6 :twist 6))
  (:a (:root :f 0.5) (:spine :flex -21) (:thigh-r :flex 96) (:knee-r :flex 2))                        ; overshoot
  (18 (:root :f 0.46) (:thigh-r :flex 72) (:knee-r :flex 60) (:spine :flex -13))
  (24 (:root :f 0.3 :u -0.05) (:thigh-r :flex 8) (:knee-r :flex 30) (:spine :flex 4) (:arm-r :flex 32 :side 40) (:elbow-r :flex 40))
  (:end :ke-stance))
(defstrike :ke-f1 (16 4 20 :base :ke-stance)           ; two-handed kendo cut
  (0)
  (8 (:root :u 0.05) (:arm-r :flex 175 :side 5) (:arm-l :flex 162 :side 38 :twist 4) (:elbows :flex 25) (:elbow-l :flex 12)
     (:hand-r :twist 0 :flex -50) (:chest :twist 0) (:spine :flex -10) (:pelvis :twist 0) (:head :flex -10))
  (13 (:root :u 0.08 :f -0.04) (:spine :flex -14) (:head :flex -13))                ; raised and held
  (:s :snap (:root :u -0.32 :f 0.4) (:spine :flex 48) (:arm-r :flex 25 :side 0) (:arm-l :flex 6 :side -36 :twist 0)
      (:elbows :flex 5) (:elbow-l :flex 0) (:hand-r :twist -10 :flex -35) (:knees :flex 72) (:thighs :flex 56))
  (:a (:spine :flex 53) (:root :u -0.35 :f 0.43))                                   ; overshoot
  (28 (:spine :flex 49) (:root :u -0.32 :f 0.41))
  (:end :ke-stance))
(defstrike :ke-f2 (20 5 28 :base :ke-stance)           ; rising cleave: launcher
  (0)
  (10 (:root :u -0.3) (:arm-r :flex -30 :side 20) (:hand-r :twist 155 :flex 15) (:arm-l :flex -10 :side 15) (:elbow-l :flex 60)
      (:knees :flex 60) (:spine :flex 30) (:chest :twist 20))
  (16 (:root :u -0.35) (:arm-r :flex -36 :side 22) (:knees :flex 66) (:spine :flex 34) (:chest :twist 26))   ; coiled, held
  (:s :snap (:root :u 0.14) (:arm-r :flex 172 :side 5) (:hand-r :twist -155 :flex 15) (:arm-l :flex 160 :side 5) (:elbow-l :flex 20)
      (:spine :flex -24) (:knees :flex 10) (:head :flex -25) (:chest :twist 0))
  (:a (:arms :flex 178) (:spine :flex -28) (:root :u 0.18) (:head :flex -28))        ; overshoot, up on the toes
  (34 (:arms :flex 175) (:spine :flex -24) (:root :u 0.12))
  (:end :ke-stance))
(defclip :ke-stance-hold (1.0 :loop t :base :ke-stance) ; "Kitte miro yo": arms flung wide (blend 6 f in)
  (0 (:root :u -0.02) (:pelvis :twist 0) (:chest :twist 0) (:spine :flex -12) (:head :flex -12 :twist 0)
     (:arms :side 78 :flex 15) (:elbows :flex 15) (:hand-r :twist 0 :flex -90) (:thigh-r :flex -5 :side 14) (:thigh-l :flex 5 :side 14)
     (:knees :flex 20))
  (0.5 (:spine :flex -14) (:arms :side 80) (:root :u -0.03)))
(defstrike :ke-stance-cut (8 4 24 :base :ke-stance)    ; the stance released: a huge cross-body cut
  (0 (:root :u -0.02) (:pelvis :twist 0) (:chest :twist -20) (:spine :flex -12) (:arms :side 78 :flex 15) (:elbows :flex 15)
     (:hand-r :twist 0 :flex -90))
  (4 (:chest :twist -32) (:spine :flex -15) (:arm-r :side 88) (:root :u -0.05))    ; wound further, held
  (6 (:chest :twist -35) (:spine :flex -16) (:root :u -0.06))
  (:s :snap (:chest :twist 75) (:arm-r :flex 80 :side 10) (:hand-r :twist 5 :flex -85) (:root :f 0.55 :u -0.17) (:spine :flex 22)
      (:thigh-l :flex 52) (:knee-l :flex 57) (:arm-l :side 40 :flex 20))
  (:a (:chest :twist 90) (:arm-r :flex 72 :side -14) (:spine :flex 25) (:root :f 0.6 :u -0.19))   ; overshoot
  (20 (:chest :twist 84) (:arm-r :flex 75 :side -10) (:spine :flex 22) (:root :f 0.57 :u -0.17))
  (:end :ke-stance))
(defstrike :ke-buttagiru (22 4 26 :base :ke-stance)    ; "Buttagiru": leap, two-handed overhead chop
  (0)
  (6 (:root :u -0.3) (:knees :flex 80) (:thighs :flex 60) (:spine :flex 30) (:arms :flex 40) (:elbows :flex 60))
  (12 (:root :u 0.6) (:thighs :flex 50) (:knees :flex 80) (:arm-r :flex 178 :side 5) (:arm-l :flex 165 :side 37 :twist 3)
      (:elbows :flex 25) (:elbow-l :flex 12) (:hand-r :twist 0 :flex -50) (:spine :flex -20) (:head :flex -15))
  (17 (:root :u 0.75) (:spine :flex -25) (:head :flex -18))
  (19 (:root :u 0.76) (:spine :flex -27))                                             ; hang at the apex
  (:s :snap (:root :u -0.37 :f 0.42) (:spine :flex 58) (:arm-r :flex 20 :side 0) (:arm-l :flex 2 :side -36 :twist 0)
      (:elbows :flex 5) (:elbow-l :flex 0) (:hand-r :twist -10 :flex -35) (:knees :flex 92) (:thighs :flex 71) (:head :flex -30))
  (:a (:spine :flex 63) (:root :u -0.4 :f 0.44))                                      ; overshoot
  (34 (:spine :flex 58) (:root :u -0.37 :f 0.42))
  (:end :ke-stance))
(defclip :ke-charge (0.4 :loop t :base :ke-stance)     ; SP2 dash: blade low and back, charging
  (0 (:spine :flex 28) (:head :flex -25) (:chest :twist -20) (:arm-r :flex -40 :side 35) (:elbow-r :flex 15) (:hand-r :twist 150 :flex 10)
     (:thigh-r :flex 55) (:knee-r :flex 25) (:thigh-l :flex -35) (:knee-l :flex 50) (:root :u -0.1))
  (0.2 (:thigh-l :flex 55) (:knee-l :flex 25) (:thigh-r :flex -35) (:knee-r :flex 50) (:root :u -0.05)))
(defstrike :ke-flurry (4 36 24 :base :ke-stance)       ; cuts at f4 10 16 22 28, launcher at f40
  (0 (:chest :twist -30) (:arm-r :flex 150 :side 35) (:elbow-r :flex 30) (:hand-r :twist -15 :flex -15))
  (4 :snap (:arm-r :flex 40 :side -10) (:elbow-r :flex 10) (:hand-r :twist -15 :flex -75) (:chest :twist 40) (:spine :flex 20))
  (6 (:chest :twist 46) (:arm-r :flex 34 :side -14) (:spine :flex 22))              ; each cut held 2 f past its extreme
  (10 :snap (:chest :twist -55) (:arm-r :side 90 :flex 30) (:hand-r :twist 5 :flex -70) (:spine :flex 10))
  (12 (:chest :twist -61) (:arm-r :side 95 :flex 27) (:spine :flex 11))
  (16 :snap (:chest :twist 50) (:arm-r :flex 60 :side -15) (:hand-r :twist -15 :flex -75) (:spine :flex 22))
  (18 (:chest :twist 56) (:arm-r :flex 54 :side -19) (:spine :flex 24))
  (22 :snap (:chest :twist -60) (:arm-r :side 95 :flex 40) (:hand-r :twist 5 :flex -70) (:spine :flex 12))
  (24 (:chest :twist -66) (:arm-r :side 100 :flex 37) (:spine :flex 13))
  (28 :snap (:chest :twist 55) (:arm-r :flex 45 :side -20) (:hand-r :twist -15 :flex -75) (:spine :flex 25))
  (30 (:chest :twist 60) (:arm-r :flex 40 :side -23) (:spine :flex 27))
  (34 (:root :u -0.3) (:arm-r :flex -30 :side 20) (:hand-r :twist 155 :flex 15) (:knees :flex 60) (:spine :flex 30) (:chest :twist 20))
  (37 (:root :u -0.34) (:arm-r :flex -34 :side 22) (:knees :flex 64) (:spine :flex 33) (:chest :twist 24))
  (40 :snap (:root :u 0.12) (:arm-r :flex 172 :side 5) (:hand-r :twist -155 :flex 15) (:spine :flex -22) (:knees :flex 10)
      (:head :flex -25) (:chest :twist 0))
  (46 (:arm-r :flex 178) (:spine :flex -27) (:root :u 0.16))                         ; overshoot
  (52 (:arm-r :flex 176) (:spine :flex -23) (:root :u 0.12))
  (:end :ke-stance))
(defclip :ke-breaker (0.4 :loop t :base :ke-stance)    ; Breaker aura dash: shoulder first
  (0 (:spine :flex 25) (:chest :twist 45) (:head :twist -35 :flex -15) (:arm-l :flex 20 :side 10) (:elbow-l :flex 90)
     (:arm-r :flex -20 :side 25) (:hand-r :twist 150 :flex 10)
     (:thigh-r :flex 50) (:knee-r :flex 25) (:thigh-l :flex -30) (:knee-l :flex 50) (:root :u -0.1))
  (0.2 (:thigh-l :flex 50) (:knee-l :flex 25) (:thigh-r :flex -30) (:knee-r :flex 50) (:root :u -0.05)))
(defstrike :ke-shoulder (8 4 18 :base :ke-stance)      ; shoulder charge
  (0 (:spine :flex 25) (:chest :twist 45) (:head :twist -35 :flex -15) (:arm-l :flex 20 :side 10) (:elbow-l :flex 90) (:root :u -0.1))
  (3 (:spine :flex 30) (:chest :twist 55) (:root :u -0.15 :f -0.08) (:thigh-r :flex 10) (:knees :flex 40))   ; coiled back, held
  (5 (:spine :flex 32) (:chest :twist 58) (:root :u -0.16 :f -0.1))
  (:s :snap (:spine :flex 12) (:chest :twist 70) (:shoulder-l :flex 20) (:arm-l :flex 10 :side 30) (:elbow-l :flex 100)
      (:root :f 0.7 :u -0.18) (:thigh-l :flex 58) (:knee-l :flex 45) (:thigh-r :flex -28) (:knee-r :flex 20) (:head :twist -40))
  (:a (:spine :flex 8) (:chest :twist 76) (:root :f 0.78 :u -0.2) (:thigh-r :flex -32))     ; overshoot
  (18 (:spine :flex 11) (:chest :twist 72) (:root :f 0.74 :u -0.18))
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
;; the run set (every form: the blade on his shoulder, TYBW's walk-in): forward run, back-skate, side slides
(defrun :ke-shoulder-rest :ke-run :ke-skate-b :ke-slide-r :ke-slide-l)
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
;; the NOME release (the awakening's first beat): head down, the grin, then head thrown back and the left arm flung
;; wide as the reiatsu bursts (0.3 s; the cinematic plays it at 2/3 speed: the burst on its frame 26)
(defclip :ke-release (0.5 :base :ke-stance)
  (0)
  (0.2 (:head :flex 22 :twist 6) (:spine :flex 16) (:chest :twist 8) (:arm-l :flex 30 :side 10) (:elbow-l :flex 70))
  (0.3 :snap (:arm-l :flex 110 :side 70) (:elbow-l :flex 10) (:head :flex -25 :twist -10) (:spine :flex -15) (:chest :twist -15))
  (0.5 (:arm-l :flex 90 :side 75) (:head :flex -30) (:spine :flex -18)))
(defclip :ke-nome (0.7 :base :ke-stance)               ; "Nome": blade up (weapon -> :nozarashi at 0.35 s), then down
  (0 (:arm-l :flex 90 :side 75) (:head :flex -30) (:spine :flex -18))
  (0.3 (:arm-r :flex 170 :side 10) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -10) (:arm-l :flex 40 :side 30) (:head :flex -30))
  (0.45 (:arm-r :flex 172))
  (0.7 :ke-n-stance))
;; O in Nozarashi, LEAP CLEAVE: 8 f of crouch, then airborne, the cleaver raised over the head (held while
;; the leap lasts; the strike is :ke-stance-cut)
(defclip :ke-n-leap (0.7 :base :ke-n-stance)
  (0)
  (0.13 (:root :u -0.35) (:knees :flex 85) (:thighs :flex 65) (:spine :flex 32) (:arms :flex 35) (:elbows :flex 60))
  (0.25 (:root :u 0.1) (:thighs :flex 55) (:knees :flex 90) (:arms :flex 175 :side 8) (:elbows :flex 25)
        (:hand-r :twist 0 :flex -50) (:spine :flex -18) (:head :flex -18))
  (0.7 (:root :u 0.1) (:thighs :flex 50) (:knees :flex 85) (:arms :flex 178 :side 6) (:spine :flex -22)))
(defclip :ke-n-stance (2.0 :loop t :base :ke-n-stance)
  (0) (1.0 (:chest :flex 3) (:root :u -0.07)))
;; Nozarashi v2, the cups read from the grip: cup 1 one hand (:ke-n-stance); cups 2 and 3 two-handed jodan, the
;; cleaver raised over the right shoulder in both hands, the green tassel hanging
(defpose :ke-r-stance (:base :ke-n-stance)
  (:pelvis :twist 10) (:chest :twist -4) (:spine :flex 4) (:head :flex -4)
  (:arm-r :flex 106 :side 17 :twist -5) (:elbow-r :flex 99) (:hand-r :twist -9 :flex -55)     ; the fists above the brow,
  (:arm-l :flex 118 :side 37 :twist 41) (:elbow-l :flex 43) (:hand-l :flex -30)                ; the left on the handle's end
  (:thigh-r :flex -10 :side 10) (:thigh-l :flex 22 :side 8) (:knee-r :flex 22) (:knee-l :flex 28))
(defclip :ke-r-stance (2.0 :loop t :base :ke-r-stance)
  (0) (1.0 (:chest :flex 3) (:root :u -0.06)))
;; DRINK (cup 3's U): a drunk hit, the head thrown back, the chest open (a variant of the stance's hold)
(defclip :ke-drink (0.3 :base :ke-r-stance)
  (0 :snap (:head :flex -32) (:spine :flex -14) (:chest :twist 6) (:root :u -0.03))
  (0.3 (:head :flex -20) (:spine :flex -8)))
;; the RYOTE kendo set (cups 2 and 3, DUEL_DESIGN §6.2), from jodan and back to it: kamae -> a big anticipation
;; held a few frames -> a :snap into the cut on frame S -> zanshin held through S+A with a small overshoot -> settle.
;; Both fists stay on the long handle: the left arm of every key was solved onto the handle (the right fist at the
;; collar, the left 0.16-0.42 down the handle); the right arm is posed and the wrist aims the blade. Phase 6: the draw
;; holds the left fist on the handle between the keys too (body.lisp GRIP-LEFT!, these clips registered below).
(defstrike :ke-r-q1 (10 3 12 :base :ke-r-stance)       ; MEN: the straight overhead, stepping in, down the centre line
  (0)
  (4 (:root :f -0.06 :u 0.03) (:spine :flex -8) (:head :flex -6) (:chest :twist -4)        ; furikaburi: the cleaver
     (:arm-r :flex 165 :side 12 :twist 23) (:elbow-r :flex 75) (:hand-r :flex -47 :twist -8) ; dropped behind the back
     (:arm-l :flex 157 :side 8 :twist 42) (:elbow-l :flex 65))
  (7 (:root :f -0.08 :u 0.05) (:spine :flex -11) (:head :flex -8))
  (:s :snap (:root :f 0.5 :u -0.1) (:spine :flex 14) (:head :flex 4) (:chest :twist 0) (:pelvis :twist 0)
      (:thigh-l :flex 48 :side 6) (:knee-l :flex 42) (:thigh-r :flex -32 :side 8) (:knee-r :flex 14)
      (:arm-r :flex 94 :side -12 :twist 11) (:elbow-r :flex 8) (:hand-r :flex -93 :twist 0)
      (:arm-l :flex 38 :side -61 :twist 71) (:elbow-l :flex 47))
  (:a (:root :f 0.55 :u -0.13) (:spine :flex 18) (:thigh-l :flex 52) (:knee-l :flex 48) (:thigh-r :flex -34) (:knee-r :flex 16)
      (:arm-r :flex 86 :side -12 :twist 11) (:elbow-r :flex 6) (:hand-r :flex -84 :twist -1)
      (:arm-l :flex 38 :side -55 :twist 64) (:elbow-l :flex 40))
  (18 (:root :f 0.52 :u -0.11) (:spine :flex 15) (:head :flex 0))                            ; zanshin
  (21 (:root :f 0.25 :u -0.05) (:spine :flex 8) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10) (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))          ; lifted back to jodan
  (:end :ke-r-stance))
(defstrike :ke-r-q3 (14 4 22 :base :ke-r-stance)       ; KESA: the diagonal, shoulder to hip
  (0)
  (6 (:root :u -0.06 :f -0.04) (:pelvis :twist 20) (:chest :twist -35) (:spine :flex -4) (:head :flex -4 :twist 20)
     (:arm-r :flex 150 :side 35 :twist -48) (:elbow-r :flex 70) (:hand-r :flex -47 :twist -7)
     (:arm-l :flex 133 :side -1 :twist 48) (:elbow-l :flex 71))
  (10 (:root :u -0.08 :f -0.06) (:chest :twist -40) (:spine :flex -6))
  (:s :snap (:root :f 0.35 :u -0.14) (:pelvis :twist -10) (:chest :twist 35) (:spine :flex 20) (:head :flex 0 :twist -15)
      (:thigh-l :flex 46 :side 8) (:knee-l :flex 45) (:thigh-r :flex -25 :side 10) (:knee-r :flex 18)
      (:arm-r :flex 55 :side -25 :twist -9) (:elbow-r :flex 10) (:hand-r :flex -67 :twist 4)
      (:arm-l :flex 29 :side -16 :twist 56) (:elbow-l :flex 54))
  (:a (:root :f 0.4 :u -0.16) (:pelvis :twist -14) (:chest :twist 44) (:spine :flex 24) (:head :twist -18)
      (:thigh-l :flex 50) (:knee-l :flex 50) (:thigh-r :flex -26) (:knee-r :flex 20)
      (:arm-r :flex 45 :side -30 :twist 2) (:elbow-r :flex 8) (:hand-r :flex -66 :twist -1)
      (:arm-l :flex 19 :side -3 :twist 56) (:elbow-l :flex 67))
  (27 (:root :f 0.38 :u -0.14) (:chest :twist 41) (:spine :flex 21))
  (33 (:root :f 0.18 :u -0.06) (:chest :twist 10) (:pelvis :twist 0) (:spine :flex 8) (:head :twist 0) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10) (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))
  (:end :ke-r-stance))
(defstrike :ke-r-f1 (19 4 20 :base :ke-r-stance)       ; DO: the wide body cut, from waki-gamae, stepping through
  (0)
  (3 (:chest :twist -20) (:pelvis :twist 18) (:arm-r :flex 50 :side 0 :twist -1) (:elbow-r :flex 110) (:hand-r :flex 18 :twist -14) (:arm-l :flex 43 :side -73 :twist 62) (:elbow-l :flex 47))
  (8 (:root :u -0.12 :f -0.05) (:pelvis :twist 25) (:chest :twist -50) (:spine :flex 8) (:head :flex -2 :twist 35) (:knees :flex 40)
     (:arm-r :flex 20 :side 25 :twist -90) (:elbow-r :flex 60) (:hand-r :flex -101 :twist -45)
     (:arm-l :flex 27 :side -62 :twist 48) (:elbow-l :flex 25))
  (14 (:root :u -0.15 :f -0.08) (:chest :twist -56) (:pelvis :twist 28) (:knees :flex 44))
  (:s :snap (:root :f 0.6 :u -0.2) (:pelvis :twist -20) (:chest :twist 55) (:spine :flex 22) (:head :flex 0 :twist -30)
      (:thigh-l :flex 55 :side 8) (:knee-l :flex 55) (:thigh-r :flex -30 :side 12) (:knee-r :flex 25)
      (:arm-r :flex 70 :side -35 :twist -26) (:elbow-r :flex 8) (:hand-r :flex -92 :twist 22)
      (:arm-l :flex 41 :side -28 :twist 67) (:elbow-l :flex 53))
  (:a (:root :f 0.66 :u -0.22) (:pelvis :twist -25) (:chest :twist 65) (:spine :flex 25) (:head :twist -35)
      (:thigh-l :flex 58) (:knee-l :flex 58) (:thigh-r :flex -32) (:knee-r :flex 26)
      (:arm-r :flex 65 :side -40 :twist -16) (:hand-r :flex -111 :twist 16) (:arm-l :flex 41 :side -27 :twist 68) (:elbow-l :flex 57))
  (32 (:root :f 0.63 :u -0.2) (:chest :twist 62) (:spine :flex 22))
  (37 (:root :f 0.3 :u -0.08) (:chest :twist 15) (:pelvis :twist 0) (:spine :flex 8) (:head :twist 0) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10) (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))
  (:end :ke-r-stance))
(defstrike :ke-r-f2 (21 5 28 :base :ke-r-stance)       ; KABUTO-WARI: scoop low, rise huge on the toes, crash (launch)
  (0)
  (3 (:root :u -0.12) (:spine :flex 12) (:chest :twist -15) (:pelvis :twist 12) (:knees :flex 45) (:arm-r :flex 50 :side 0 :twist -1) (:elbow-r :flex 110) (:hand-r :flex 18 :twist -14) (:arm-l :flex 43 :side -73 :twist 62) (:elbow-l :flex 47))
  (6 (:root :u -0.28 :f -0.05) (:spine :flex 26) (:head :flex -20) (:knees :flex 70) (:thighs :flex 45) (:chest :twist -25)
     (:pelvis :twist 15) (:arm-r :flex 10 :side 10 :twist -90) (:elbow-r :flex 20) (:hand-r :flex -82 :twist -41)
     (:arm-l :flex 20 :side -38 :twist 47) (:elbow-l :flex 42))
  (10 (:root :u 0.05) (:spine :flex 0) (:head :flex -20) (:chest :twist -8) (:pelvis :twist 5) (:knees :flex 25) (:thighs :flex 15)
      (:arm-r :flex 120 :side 20 :twist 2) (:elbow-r :flex 80) (:hand-r :flex -89 :twist -21) (:arm-l :flex 109 :side 11 :twist 48) (:elbow-l :flex 85))
  (13 (:root :u 0.3 :f 0.0) (:spine :flex -16) (:head :flex -22) (:chest :twist 0) (:pelvis :twist 0)
      (:thigh-l :flex 20) (:knee-l :flex 10) (:thigh-r :flex -8) (:knee-r :flex 6)
      (:arm-r :flex 178 :side 8 :twist 0) (:elbow-r :flex 10) (:hand-r :flex -93 :twist -8)
      (:arm-l :flex 163 :side 23 :twist 51) (:elbow-l :flex 45))
  (17 (:root :u 0.36) (:spine :flex -20) (:head :flex -26))
  (:s :snap (:root :u -0.3 :f 0.5) (:spine :flex 40) (:head :flex -30)
      (:thigh-l :flex 66 :side 8) (:knee-l :flex 80) (:thigh-r :flex -20 :side 10) (:knee-r :flex 45)
      (:arm-r :flex 64 :side -10 :twist 11) (:elbow-r :flex 5) (:hand-r :flex -49 :twist -5)
      (:arm-l :flex 29 :side -42 :twist 47) (:elbow-l :flex 17))
  (:a (:root :u -0.33 :f 0.52) (:spine :flex 44) (:head :flex -32) (:thigh-l :flex 68) (:knee-l :flex 84) (:knee-r :flex 48)
      (:arm-r :flex 58) (:hand-r :flex -44 :twist -6) (:arm-l :flex 25 :side -39 :twist 45) (:elbow-l :flex 15))
  (38 (:root :u -0.3 :f 0.5) (:spine :flex 40) (:head :flex -28))
  (46 (:root :u -0.08 :f 0.2) (:spine :flex 10) (:head :flex -8) (:thigh-l :flex 35) (:knee-l :flex 35) (:thigh-r :flex -12)
      (:knee-r :flex 25) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10) (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))
  (:end :ke-r-stance))
;; J2 KOTE (docs/DUEL_STRINGS.md §3.4): the only small motion in the set: a short lift from jodan, the wrists snap the
;; cleaver down to forearm height, a half step in
(defstrike :ke-r-kote (9 3 13 :base :ke-r-stance)      ; J2 KOTE: the small wrist snap
  (0)
  (4 (:root :f -0.03 :u 0.02) (:spine :flex -4) (:arm-r :flex 132 :side 12 :twist 15) (:elbow-r :flex 70) (:hand-r :flex -40 :twist -6)
     (:arm-l :flex 128 :side 14 :twist 40) (:elbow-l :flex 60))
  (7 (:root :f -0.04 :u 0.03) (:arm-r :flex 136) (:hand-r :flex -36))                              ; the lift, held
  (:s :snap (:root :f 0.32 :u -0.07) (:spine :flex 10) (:chest :twist -4) (:pelvis :twist 4)
      (:thigh-l :flex 36 :side 6) (:knee-l :flex 32) (:thigh-r :flex -22 :side 8) (:knee-r :flex 12)
      (:arm-r :flex 80 :side -10 :twist 11) (:elbow-r :flex 14) (:hand-r :flex -78 :twist 0)
      (:arm-l :flex 36 :side -58 :twist 68) (:elbow-l :flex 45))
  (:a (:root :f 0.35 :u -0.08) (:spine :flex 12) (:arm-r :flex 76) (:hand-r :flex -74))
  (18 (:root :f 0.3 :u -0.06) (:spine :flex 9))
  (22 (:root :f 0.14 :u -0.03) (:spine :flex 5) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10)
      (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))
  (:end :ke-r-stance))
;; K2 MOROTE-ZUKI (§3.4): both hands draw the cleaver back to the right hip, held, then drive it straight out, the back
;; foot sliding; held 4 f fully extended
(defstrike :ke-r-tsuki (21 4 24 :base :ke-r-stance)    ; K2 MOROTE-ZUKI: the two-handed thrust
  (0)
  (8 (:root :u -0.12 :f -0.1) (:pelvis :twist 22) (:chest :twist -28) (:spine :flex 10) (:head :flex -4 :twist 20) (:knees :flex 40)
     (:arm-r :flex 28 :side 14 :twist -30) (:elbow-r :flex 105) (:hand-r :flex -72 :twist -30)
     (:arm-l :flex 38 :side -40 :twist 50) (:elbow-l :flex 70))
  (17 (:root :u -0.15 :f -0.13) (:chest :twist -33) (:knees :flex 44) (:arm-r :flex 24) (:elbow-r :flex 112))   ; drawn back, held
  (:s :snap (:root :f 0.72 :u -0.16) (:pelvis :twist -6) (:chest :twist 6) (:spine :flex 18) (:head :flex 0 :twist 0)
      (:thigh-l :flex 56 :side 6) (:knee-l :flex 52) (:thigh-r :flex -42 :side 8) (:knee-r :flex 8)
      (:arm-r :flex 88 :side -6 :twist 10) (:elbow-r :flex 4) (:hand-r :flex -86 :twist -20)
      (:arm-l :flex 60 :side -40 :twist 70) (:elbow-l :flex 30))
  (:a (:root :f 0.78 :u -0.18) (:spine :flex 20) (:arm-r :flex 90) (:elbow-r :flex 2))
  (29 (:root :f 0.77 :u -0.18) (:spine :flex 20))                                                   ; held extended
  (38 (:root :f 0.45 :u -0.1) (:spine :flex 12) (:thigh-r :flex -24) (:knee-r :flex 14))
  (43 (:root :f 0.2 :u -0.05) (:spine :flex 6) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10)
      (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))
  (:end :ke-r-stance))
(defstrike :ke-n-f1 (20 4 22 :base :ke-r-stance)       ; KUKAN-GIRI: a flat cut at chest height, left to right; its
  (0)                                                   ; chord is the rift (f20)
  (3 (:chest :twist 15) (:pelvis :twist -5) (:arm-r :flex 70 :side -30 :twist 90) (:elbow-r :flex 90) (:hand-r :flex -62 :twist -54) (:arm-l :flex 31 :side 27 :twist 58) (:elbow-l :flex 85))
  (8 (:root :u -0.1 :f -0.04) (:pelvis :twist -15) (:chest :twist 45) (:spine :flex 6) (:head :flex -4 :twist -30) (:knees :flex 38)
     (:arm-r :flex 30 :side -50 :twist 42) (:elbow-r :flex 80) (:hand-r :flex -6 :twist 90)
     (:arm-l :flex 57 :side -17 :twist 53) (:elbow-l :flex 68))
  (15 (:root :u -0.13 :f -0.07) (:chest :twist 52) (:pelvis :twist -18) (:knees :flex 42))
  (:s :snap (:root :f 0.45 :u -0.14) (:pelvis :twist 20) (:chest :twist -45) (:spine :flex 12) (:head :flex 0 :twist 25)
      (:thigh-l :flex 48 :side 8) (:knee-l :flex 44) (:thigh-r :flex -28 :side 12) (:knee-r :flex 18)
      (:arm-r :flex 70 :side 30 :twist 34) (:elbow-r :flex 8) (:hand-r :flex -99 :twist -27)
      (:arm-l :flex 28 :side -55 :twist 52) (:elbow-l :flex 28))
  (:a (:root :f 0.5 :u -0.15) (:pelvis :twist 24) (:chest :twist -55) (:spine :flex 14) (:head :twist 30)
      (:thigh-l :flex 50) (:knee-l :flex 46) (:thigh-r :flex -30) (:knee-r :flex 20)
      (:arm-r :flex 66 :side 38 :twist 18) (:hand-r :flex -102 :twist -30) (:arm-l :flex 28 :side -57 :twist 48) (:elbow-l :flex 23))
  (34 (:root :f 0.48 :u -0.13) (:chest :twist -51) (:spine :flex 12))
  (40 (:root :f 0.2 :u -0.05) (:chest :twist -10) (:pelvis :twist 5) (:spine :flex 6) (:head :twist 0) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10) (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))
  (:end :ke-r-stance))
(setf *grip-clips* '(:ke-r-stance :ke-drink :ke-r-q1 :ke-r-q3 :ke-r-f1 :ke-r-f2 :ke-n-f1 :ke-r-kote :ke-r-tsuki))
(defstrike :ke-meteor (26 4 30 :base :ke-n-stance)     ; "Split the meteor": the huge two-handed cleave
  (0)
  (16 (:root :u 0.05) (:arm-r :flex 180 :side 5) (:arm-l :flex 165 :side 37 :twist 4) (:elbows :flex 30) (:elbow-l :flex 13)
      (:hand-r :twist 0 :flex -50) (:spine :flex -22) (:head :flex -20) (:chest :twist 0) (:pelvis :twist 0))
  (22 (:root :u 0.1 :f -0.05) (:spine :flex -27) (:head :flex -25))                  ; raised to the sky, held
  (:s :snap (:root :u -0.44 :f 0.42) (:spine :flex 62) (:arm-r :flex 20 :side 0) (:arm-l :flex -7 :side -36 :twist 0)
      (:elbows :flex 5) (:elbow-l :flex 0) (:hand-r :twist -10 :flex -35) (:knees :flex 92) (:thighs :flex 70) (:head :flex -35))
  (:a (:spine :flex 66) (:root :u -0.47 :f 0.44))                                     ; overshoot
  (44 (:root :u -0.41 :f 0.4) (:spine :flex 58))
  (:end :ke-n-stance))
(defclip :ke-kikon-n (1.5 :base :ke-n-stance)          ; the sky split: one colossal cleave
  (0)
  (0.35 (:root :u -0.2) (:chest :twist -80) (:arms :side 80 :flex 30) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -90)
        (:arm-l :side 20 :flex 60) (:knees :flex 50) (:spine :flex 15))
  (0.42 :snap (:chest :twist 80) (:arm-r :flex 80 :side 5) (:arm-l :flex 75 :side -5) (:hand-r :twist 5 :flex -85)
        (:root :f 0.6 :u -0.3) (:thigh-l :flex 55) (:knee-l :flex 60) (:spine :flex 25))
  (1.0 (:chest :twist 88))
  (1.5 :ke-n-stance))

;;; ---------------------------------------------------------------- the Bankai (docs/DUEL_KEN_BANKAI.md §12): 3 clips
;; the beast-like stance: hunched forward, knees wide, the left hand open like a claw, the broken cleaver dragging low in
;; the right, head down but the eyes up; the shoulders heave
(defpose :ke-b-stance (:base :ke-stance)
  (:root :u -0.16) (:pelvis :twist 12) (:spine :flex 30) (:chest :twist -8 :flex 6) (:head :flex -26 :twist -4)
  (:arm-r :flex 14 :side 26) (:elbow-r :flex 18) (:hand-r :flex -70 :twist 10)
  (:arm-l :flex 48 :side 32) (:elbow-l :flex 62) (:hand-l :flex 25)
  (:thigh-r :flex 22 :side 22) (:thigh-l :flex 40 :side 20) (:knee-r :flex 48) (:knee-l :flex 55))
(defclip :ke-b-stance (0.8 :loop t :base :ke-b-stance)
  (0) (0.4 (:chest :flex 12) (:spine :flex 26) (:root :u -0.13) (:head :flex -30)))
;; J3 GENKOTSU / SP2's NAGURI-TOBASHI: the left hook from the hip, the whole body behind it, held 3 f on contact, the
;; cleaver thrown out wide in the right
(defstrike :ke-b-fist (9 3 18 :base :ke-b-stance)
  (0)
  (4 (:chest :twist 36) (:spine :flex 22) (:arm-l :flex 40 :side 60) (:elbow-l :flex 110) (:hand-l :flex 0)
     (:root :u -0.14 :f -0.06) (:head :twist 12))                                          ; wound back
  (7 (:chest :twist 42) (:root :f -0.08))                                                  ; held
  (:s :snap (:chest :twist -48) (:spine :flex 20) (:arm-l :flex 92 :side 8) (:elbow-l :flex 22) (:hand-l :flex 0)
      (:root :f 0.42 :u -0.12) (:thigh-l :flex 52) (:knee-l :flex 45) (:thigh-r :flex -18) (:arm-r :side 70 :flex 25)
      (:head :twist -8))
  (:a (:chest :twist -56) (:root :f 0.47))                                                 ; overshoot, held on contact
  (20 (:chest :twist -50) (:root :f 0.44) (:arm-l :flex 80) (:elbow-l :flex 30))
  (:end :ke-b-stance))
;; L KAMICHIGIRI: coiled low, a lunge, the left hand clamps the arm, the head drives in, then the tearing jerk back
(defstrike :ke-b-bite (10 3 28 :base :ke-b-stance)
  (0)
  (5 (:root :u -0.26 :f -0.05) (:spine :flex 42) (:knees :flex 62) (:arm-l :flex 40 :side 22) (:elbow-l :flex 45))
  (8 (:root :u -0.28 :f -0.08) (:spine :flex 44))                                          ; coiled, held
  (:s :snap (:root :f 0.72 :u -0.2) (:spine :flex 46) (:head :flex 12) (:arm-l :flex 96 :side 6) (:elbow-l :flex 22)
      (:hand-l :flex 30) (:thigh-l :flex 60) (:knee-l :flex 50) (:thigh-r :flex -20) (:knee-r :flex 20))
  (:a (:root :f 0.76) (:head :flex 20))                                                    ; the teeth in
  (18 (:root :f 0.55 :u -0.12) (:spine :flex 12) (:head :flex -38) (:arm-l :flex 70 :side 24) (:elbow-l :flex 62))   ; torn off
  (27 (:root :f 0.45 :u -0.14) (:head :flex -30) (:spine :flex 18))
  (:end :ke-b-stance))
