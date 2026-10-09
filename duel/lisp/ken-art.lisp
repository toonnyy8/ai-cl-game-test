;;;; ken-art.lisp — ZARAKI KENPACHI (TYBW) as art data: his body, his notched katana and the true
;;;; Shikai NOZARASHI (a giant cleaver), and every :ke-* pose and clip (design §5.2). Attack clips
;;;; use DEFSTRIKE, so each reaches its hit pose at frame S and is back in his stance at S+A+R.
;;;; Look: 2.02 m, broad, long loose black spiky hair (no bells), both eyes open (no eyepatch in any
;;;; form: the user's decision 2026-09-26, kept 2026-10-08; canon TYBW still wears a strapless patch, DUEL_KEN_REWORK §3), scar down the left side of the face, a grin, sleeveless tattered white haori over the black shihakusho, bare muscular arms.
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
                    ;; v4 notan palette (docs/style/STYLE_STORM_DESIGN.md §2.5): black robe and solid black hair,
                    ;; the tattered haori V4 white, muted skin
                    :palette ((:skin #xCFA48C) (:skin-d #xB08C78) (:black #x16161E) (:white #xE8E8E4)
                              (:hair #x0C0C12) (:scar #x5A3430) (:teeth #xECECE8)
                              (:eye #x0C0C12) (:pupil #x0C0C12) (:crease #x7A5448) (:fold #xD8DCE4) (:obi #xDEDED8) (:tabi #xE8E8E4) (:sole #x262833))
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
           (:box 0.1 0.52 0.02 :at (-0.17 -0.21 0.135) :rot (0 4 0) :c :white)
           ;; the sawtooth hem (DUEL_KEN_REWORK §5.1, 「羽織與腰帶」): a white diamond behind each strip's foot, its lower half a
           ;; tooth; round holes punched near the hem
           (:box 0.05 0.05 0.02 :at (-0.178 -0.57 -0.158) :rot (0 -4 45) :c :white)
           (:box 0.05 0.05 0.02 :at (-0.103 -0.57 -0.158) :rot (0 -4 45) :c :white)
           (:box 0.047 0.047 0.02 :at (-0.035 -0.709 -0.168) :rot (0 -4 45) :c :white)
           (:box 0.047 0.047 0.02 :at (0.035 -0.709 -0.168) :rot (0 -4 45) :c :white)
           (:box 0.05 0.05 0.02 :at (0.103 -0.51 -0.156) :rot (0 -4 45) :c :white)
           (:box 0.05 0.05 0.02 :at (0.177 -0.51 -0.156) :rot (0 -4 45) :c :white)
           (:box 0.02 0.044 0.044 :at (0.228 -0.45 -0.092) :rot (0 45 0) :c :white)
           (:box 0.02 0.044 0.044 :at (0.228 -0.45 -0.027) :rot (0 45 0) :c :white)
           (:box 0.02 0.081 0.081 :at (0.234 -0.609 0.06) :rot (0 45 0) :c :white)
           (:box 0.02 0.044 0.044 :at (-0.231 -0.53 -0.092) :rot (0 45 0) :c :white)
           (:box 0.02 0.044 0.044 :at (-0.231 -0.53 -0.027) :rot (0 45 0) :c :white)
           (:box 0.02 0.081 0.081 :at (-0.227 -0.41 0.06) :rot (0 45 0) :c :white)
           (:box 0.067 0.067 0.02 :at (0.17 -0.589 0.153) :rot (0 4 45) :c :white)
           (:box 0.067 0.067 0.02 :at (-0.17 -0.47 0.149) :rot (0 4 45) :c :white)
           (:cyl 0.017 0.004 :at (-0.015 -0.539 -0.173) :rot (0 86 0) :seg 8 :c :black :ink 0)
           (:cyl 0.017 0.004 :at (0.16 -0.409 -0.166) :rot (0 86 0) :seg 8 :c :black :ink 0)
           (:cyl 0.017 0.004 :at (-0.12 -0.449 -0.166) :rot (0 86 0) :seg 8 :c :black :ink 0)
           (:cyl 0.015 0.004 :at (0.244 -0.509 0.06) :rot (0 0 94) :seg 8 :c :black :ink 0)
           ;; the white obi tied in a bow at the front: the knot, two loops, two tails
           (:box 0.045 0.04 0.03 :at (0 0.06 0.135) :c :obi)
           (:box 0.075 0.042 0.02 :at (0.055 0.068 0.135) :rot (0 0 -18) :c :obi)
           (:box 0.075 0.042 0.02 :at (-0.055 0.068 0.135) :rot (0 0 18) :c :obi)
           (:box 0.032 0.12 0.015 :at (0.022 -0.02 0.14) :rot (0 0 -12) :c :obi)
           (:box 0.032 0.1 0.015 :at (-0.024 -0.01 0.14) :rot (0 0 14) :c :obi))
  ;; the haori over the torso: one rounded white shell, the black robe and the bare chest at its open front
  (:spine (:bevel 0.44 0.25 0.27 0.04 :at (0 0.11 -0.005) :c :white)
          ;; the 11th Division's mark on the back: 十一 stacked in a diamond (ink strokes), below the mane
          (:box 0.1 0.008 0.004 :at (0.035 0.09 -0.163) :rot (0 0 -45) :c :black :ink 0)
          (:box 0.1 0.008 0.004 :at (-0.035 0.09 -0.163) :rot (0 0 45) :c :black :ink 0)
          (:box 0.1 0.008 0.004 :at (0.035 0.02 -0.163) :rot (0 0 45) :c :black :ink 0)
          (:box 0.1 0.008 0.004 :at (-0.035 0.02 -0.163) :rot (0 0 -45) :c :black :ink 0)
          (:box 0.007 0.04 0.004 :at (0 0.073 -0.163) :c :black :ink 0)
          (:box 0.042 0.007 0.004 :at (0 0.075 -0.163) :c :black :ink 0)
          (:box 0.046 0.007 0.004 :at (0 0.035 -0.163) :c :black :ink 0)
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
         ;; TYBW hair (DUEL_KEN_REWORK §5.1, the user 2026-10-08: 「頭髮：刺狀頭頂＋長鬃髮」): a cap over the skull, an upswept
         ;; spiky crown (up, back and out), a back sheet and ragged ends hanging to mid-back, strands over the shoulders, the
         ;; side locks and two fringe strands; no bells
         (:sphere 0.0695 :stretch 0.03 :at (0 0.15 -0.024) :seg 10 :c :hair)
         (:box 0.2 0.44 0.04 :at (0 -0.03 -0.15) :rot (0 -18 0) :c :hair)
         (:cone 0.0413 0.324 :at (0.0805 0.045 -0.008) :rot (0 172 -14) :seg 4 :c :hair)      ; side locks
         (:cone 0.0413 0.324 :at (-0.0805 0.045 -0.008) :rot (0 172 14) :seg 4 :c :hair)
         (:cone 0.032 0.17 :at (0.057 0.281 -0.012) :rot (0 19 -18) :seg 4 :c :hair) ; crown, front
         (:cone 0.036 0.2 :at (0.106 0.264 -0.074) :rot (0 31 -31) :seg 4 :c :hair) ; crown, side
         (:cone 0.038 0.21 :at (0.052 0.273 -0.133) :rot (0 45 -12) :seg 4 :c :hair) ; crown, back
         (:cone 0.036 0.19 :at (0.136 0.186 -0.133) :rot (0 58 -44) :seg 4 :c :hair) ; behind the ears
         (:cone 0.032 0.17 :at (-0.057 0.281 -0.012) :rot (0 19 18) :seg 4 :c :hair)
         (:cone 0.036 0.2 :at (-0.106 0.264 -0.074) :rot (0 31 31) :seg 4 :c :hair)
         (:cone 0.038 0.21 :at (-0.052 0.273 -0.133) :rot (0 45 12) :seg 4 :c :hair)
         (:cone 0.036 0.19 :at (-0.136 0.186 -0.133) :rot (0 58 44) :seg 4 :c :hair)
         (:cone 0.04 0.22 :at (0.000 0.306 -0.083) :rot (0 29 -0) :seg 4 :c :hair) ; crown, top
         (:cone 0.05 0.26 :at (-0.091 -0.294 -0.200) :rot (0 162 3) :seg 4 :c :hair)
         (:cone 0.05 0.32 :at (-0.049 -0.352 -0.209) :rot (0 162 1) :seg 4 :c :hair)
         (:cone 0.05 0.36 :at (0.000 -0.371 -0.215) :rot (0 162 -0) :seg 4 :c :hair)
         (:cone 0.05 0.3 :at (0.049 -0.343 -0.206) :rot (0 162 -1) :seg 4 :c :hair)
         (:cone 0.05 0.24 :at (0.091 -0.284 -0.197) :rot (0 162 -3) :seg 4 :c :hair)
         (:cone 0.034 0.38 :at (0.141 -0.103 -0.068) :rot (0 174 -14) :seg 4 :c :hair) ; over the shoulders
         (:cone 0.034 0.38 :at (-0.141 -0.103 -0.068) :rot (0 174 14) :seg 4 :c :hair)
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

;; the Bankai's oni (docs/duel/DUEL_KEN_BANKAI.md §12, the user's decisions 2026-09-28: 片腕 stays the oni): the same body, the
;; skin a MUTED crimson (S <= 0.45: not a spot colour), two short horns at the hairline, the pupils white (irisless), four
;; thin BLOOD cracks on the right forearm (:crack-1 .. :crack-4, one shown per spent pip) and the torn forearm of 片腕
;; (:arm-wreck: skin shards, raw strips, ink splits)
(body-variant :kenpachi-oni :kenpachi
  :palette '((:skin #x9A4A42) (:skin-d #x7A3630) (:pupil #xF4F2EA) (:horn #x6E302C) (:blood #xD0101C) (:wound #x5A1418)
            (:split #x101018))
  ;; his own prowl and guard for the shared clips (the feral pass, 2026-09-28): art only
  :clips '(:sh-guard :ke-b-guard :sh-guard-hit :ke-b-guard-hit :sh-walk-f :ke-b-walk-f :sh-walk-b :ke-b-walk-b
           :sh-strafe-r :ke-b-strafe-r :sh-strafe-l :ke-b-strafe-l)
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
  ;; the hilt (DUEL_KEN_REWORK §5.1, 「封印刀的刀鍔與柄」): a grey collar, a long spindle tsuba (16 x 5 cm, pointed along the
  ;; edge and the spine) with teeth round its rim in dark iron, a white bandage-wrapped grip with diagonal seams, a grey cap
  (:solid (mbc mb #x8A8A90)
          (with-xform (mb (xform :y 0.025)) (mb-box mb 0.013 0.04 0.041))
          (mbc mb #x4A4542)
          (with-xform (mb (xform :y -0.004 :sx 0.31)) (mb-cylinder mb 0.08 0.015 :segments 4))
          (loop for (x z) in '((0.0063 0.06) (0.0125 0.04) (0.0188 0.02) (0.0063 -0.06) (0.0125 -0.04) (0.0188 -0.02)
                               (-0.0063 0.06) (-0.0125 0.04) (-0.0188 0.02) (-0.0063 -0.06) (-0.0125 -0.04) (-0.0188 -0.02))
                do (with-xform (mb (xform :x x :y -0.004 :z z :yaw (atan (* -0.025 (signum z)) (* 0.08 (signum x)))
                                          :roll (* -0.5 pi)))
                     (mb-cone mb 0.007 0.03 :segments 4)))
          (mbc mb #xE6E4DC)
          (with-xform (mb (xform :y -0.17)) (mb-bevel-box mb 0.03 0.31 0.038 0.006))
          (mbc mb #x9A988E)
          (loop for i below 6 do (with-xform (mb (xform :y (- -0.045 (* i 0.05)) :roll 0.35)) (mb-box mb 0.034 0.005 0.04)))
          (mbc mb #x8A8A90)
          (with-xform (mb (xform :y -0.33)) (mb-bevel-box mb 0.034 0.018 0.042 0.004)))
  (:solid :ink 0 (mb-blade mb :length 1.02 :width 0.036 :curve 0.018 :blade-color '(0.55 0.57 0.6) :edge-color '(0.78 0.8 0.82)
                              :hilt nil)
          (mbc mb #x2A2A2E)                              ; chips: dark notches bitten out of the edge
          (loop for (y d) in '((0.22 0.012) (0.37 0.008) (0.55 0.014) (0.71 0.009) (0.86 0.011))
                do (with-xform (mb (xform :y y :z (- 0.016 (* 0.018 (/ y 1.02) (/ y 1.02))) :roll 0.6))
                     (mb-box mb 0.012 d d)))))

;; NOZARASHI (DUEL_KEN_REWORK §6.1, the user 2026-10-08: 「改成原作形狀，大小貼合現有判定」): the canon war cleaver at the old
;; length (the hit reaches are the sim's): a long cloth-wrapped haft, then a broad cleaver head from a rounded heel, its
;; cutting edge (+Z) bulging from 0.22 to 0.46 m and ending in a raked point at the top; a near-black body, a pale bevel band with chips along the edge, a brass
;; box cap over the top's spine-side corner with a stepped notch, and the green tassel (the manga's colour) hung from it
(defun ke-mb-prism (mb profile x0 x1)
  "A prism of the convex PROFILE ((y z) ...) between the planes x = X0 and X1 (a blade's faces and its rim)."
  (let* ((n (length profile))
         (cy (/ (loop for (y nil) in profile sum y) n)) (cz (/ (loop for (nil z) in profile sum z) n))
         (c (list (* 0.5 (+ x0 x1)) cy cz))
         (f0 (loop for (y z) in profile collect (v3 x0 y z))) (f1 (loop for (y z) in profile collect (v3 x1 y z))))
    (mb-poly-out mb f0 :center c)
    (mb-poly-out mb f1 :center c)
    (loop for i below n for j = (mod (1+ i) n)
          do (mb-poly-out mb (list (nth i f0) (nth j f0) (nth j f1) (nth i f1)) :center c))))
(defun ke-noz-edge (u)
  "The cleaver's cutting edge at U (0 the haft end, 1 the top): (y z)."
  (list (+ 0.3 (* 1.28 u)) (+ 0.22 (* 0.24 (- 1 (expt (- 1 u) 2))))))

(defweapon :nozarashi (:length 1.62 :base 0.2)         ; the haft below the grip, the head above it
  (:solid (mbc mb #x24262E)                              ; the head: near-black, convex
          (ke-mb-prism mb (append (list (list 0.32 -0.05) (list 0.24 0.04) (list 0.25 0.16))   ; the rounded heel
                                  (loop for k to 8 collect (ke-noz-edge (/ k 8.0)))
                                  (list (list 1.63 0.44) (list 1.62 -0.05)))
                       -0.021 0.021)
          (mbc mb #xD8DCE2)                              ; the pale bevel band along the edge, both faces
          (loop for k below 8
                do (let ((a (ke-noz-edge (/ k 8.0))) (b (ke-noz-edge (/ (1+ k) 8.0))))
                     (ke-mb-prism mb (list a b (list (first b) (- (second b) 0.07)) (list (first a) (- (second a) 0.07)))
                                  -0.023 0.023)))
          (mbc mb #x24262E)                              ; chips bitten out of the edge
          (loop for u in '(0.18 0.41 0.63 0.86)
                do (destructuring-bind (y z) (ke-noz-edge u)
                     (with-xform (mb (xform :y y :z z :roll 0.6)) (mb-box mb 0.05 0.035 0.035))))
          (mbc mb #xBFA868)                              ; the brass cap over the top's spine side, its stepped notch
          (with-xform (mb (xform :y 1.56 :z 0.1)) (mb-bevel-box mb 0.075 0.2 0.36 0.015))
          (with-xform (mb (xform :y 1.53 :z 0.31)) (mb-bevel-box mb 0.06 0.13 0.08 0.01))
          (with-xform (mb (xform :y 0.2 :z 0.0)) (mb-bevel-box mb 0.07 0.07 0.12 0.012))   ; the collar at the head
          (mbc mb #xD9CBB0)                              ; the long cloth-wrapped haft
          (with-xform (mb (xform :y -0.23)) (mb-box mb 0.05 0.86 0.05))
          (mbc mb #x5A5650)
          (loop for i below 8 do (with-xform (mb (xform :y (- 0.12 (* i 0.1)) :roll 0.785)) (mb-box mb 0.035 0.035 0.058)))
          (mbc mb #x7A6A3C)
          (with-xform (mb (xform :y -0.69)) (mb-bevel-box mb 0.065 0.05 0.065 0.01))
          (mbc mb #x2F4A35)                              ; the tassel: a cord from the cap's back corner, a bundle of strands
          (with-xform (mb (xform :y 1.47 :z -0.1)) (mb-box mb 0.03 0.05 0.03))
          (loop for (dz r) in '((-0.02 0.1) (0.0 0.0) (0.02 -0.1) (-0.035 0.2) (0.035 -0.2))
                do (with-xform (mb (xform :y 1.22 :z (- -0.12 dz) :roll r :pitch (* 4 dz)))
                     (mb-cone mb 0.022 0.48 :segments 4)))))

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

;; the idle (DUEL_KEN_REWORK §5.2): the blade hanging from the loose right hand, the tip trailing near the floor behind him,
;; the free left hand half open; the strikes still start from the pose (the blend takes the blade up)
(defclip :ke-stance (2.0 :loop t :base :ke-stance)
  (0 (:arm-r :flex -12 :side 14) (:elbow-r :flex 12) (:hand-r :flex -115 :twist 0) (:arm-l :flex 8 :side 26) (:elbow-l :flex 25))
  (1.0 (:chest :flex 3) (:root :u -0.07) (:arm-r :flex -14 :side 15) (:hand-r :flex -112)))

;;; ---------------------------------------------------------------- base kit (§5.2 table)
;;; One-handed wild swings; the left hand joins the grip only for the two-handed Flash cuts.
;; the base strikes (DUEL_KEN_REWORK §5.2, the user 2026-10-08: each its own arc, the whole body behind it; frame data,
;; reaches and hit volumes unchanged). J1 ARAGIRI: the lunging hack: cocked behind the head, weight back, then down from
;; the right shoulder to the left hip as the right foot lunges; ends low and open
(defstrike :ke-q1 (7 3 12 :base :ke-stance)
  (0)
  (3 (:pelvis :twist 30) (:chest :twist -45) (:spine :flex -6) (:arm-r :flex 165 :side 50) (:elbow-r :flex 75)
     (:hand-r :twist -15 :flex -30) (:arm-l :flex 40 :side 30) (:elbow-l :flex 40) (:root :u -0.02 :f -0.05) (:head :twist 12))
  (5 (:chest :twist -50) (:arm-r :flex 170 :side 52) (:elbow-r :flex 85) (:root :f -0.07))                   ; held
  (:s :snap (:pelvis :twist -10) (:chest :twist 40) (:spine :flex 28) (:arm-r :flex 45 :side -15) (:elbow-r :flex 8)
      (:hand-r :twist -15 :flex -80) (:arm-l :flex -25 :side 35) (:elbow-l :flex 20) (:root :f 0.38 :u -0.12)
      (:thigh-r :flex 55 :side 6) (:knee-r :flex 50) (:thigh-l :flex -18) (:knee-l :flex 30) (:head :twist -8))
  (:a (:chest :twist 52) (:arm-r :flex 28 :side -32) (:spine :flex 32) (:root :f 0.41 :u -0.14))              ; overshoot
  (15 (:chest :twist 48) (:arm-r :flex 30 :side -28) (:spine :flex 28) (:root :f 0.25 :u -0.11))
  (:end :ke-stance))
;; J2 KAESHIGIRI: the sloppy backhand: coiled low on the left, then a rising reverse diagonal out to the right as the hips
;; unwind, the free hand flung out for balance; it follows through up and out
(defstrike :ke-q2 (7 3 13 :base :ke-stance)
  (0)
  (3 (:pelvis :twist -25) (:chest :twist 58) (:spine :flex 18 :side 8) (:arm-r :flex 15 :side -35) (:elbow-r :flex 25)
     (:hand-r :twist 55 :flex -60) (:arm-l :flex 20 :side 20) (:root :u -0.1) (:knees :flex 45) (:head :twist -12))
  (5 (:chest :twist 64) (:arm-r :flex 10 :side -40) (:root :u -0.12))                                        ; held
  (:s :snap (:pelvis :twist 15) (:chest :twist -45) (:spine :flex 4 :side -6) (:arm-r :flex 50 :side 60) (:elbow-r :flex 80)
      (:hand-r :twist 5 :flex -30) (:arm-l :flex 30 :side 75) (:elbow-l :flex 10) (:root :f 0.45 :u -0.04)
      (:thigh-l :flex 38) (:knee-l :flex 38) (:knee-r :flex 20) (:head :twist 10))
  (:a (:chest :twist -58) (:arm-r :flex 105 :side 70) (:spine :flex -4) (:root :f 0.48 :u 0.0))               ; up and out
  (16 (:chest :twist -52) (:arm-r :flex 98 :side 66) (:root :f 0.3))
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
;; J3 KENKA-GERI (docs/duel/DUEL_STRINGS.md §3.3): no school: the rear knee chambered and held, a flat front kick to the gut,
;; leaning back, the sword thrown out wide the other way
(defstrike :ke-kick (8 3 18 :base :ke-stance)          ; J3 KENKA-GERI: the street fighter's front kick
  (0)
  (3 (:root :u 0.02 :f -0.05) (:spine :flex -6) (:chest :twist -10) (:thigh-r :flex 58 :side 4) (:knee-r :flex 96)
     (:thigh-l :flex 12) (:knee-l :flex 20) (:arm-r :flex 38 :side 58) (:elbow-r :flex 22) (:hand-r :flex -40)
     (:arm-l :flex 30 :side 12) (:elbow-l :flex 60) (:head :flex -4))                                ; chambered, held
  (6 (:thigh-r :flex 64) (:knee-r :flex 102) (:spine :flex -9) (:root :f -0.07))
  (:s :snap (:root :f 0.44 :u 0.0) (:spine :flex -18) (:chest :twist 12) (:thigh-r :flex 92 :side 0) (:knee-r :flex 45)
      (:thigh-l :flex -6) (:knee-l :flex 14) (:arm-r :flex 30 :side 95) (:elbow-r :flex 5) (:hand-r :flex -20)
      (:arm-l :flex 40 :side 30) (:elbow-l :flex 40) (:head :flex 6 :twist 6))
  (:a (:root :f 0.47) (:spine :flex -21) (:thigh-r :flex 96) (:knee-r :flex 44))                       ; overshoot
  (18 (:root :f 0.25) (:thigh-r :flex 72) (:knee-r :flex 60) (:spine :flex -13))
  (24 (:root :f 0.23 :u -0.05) (:thigh-r :flex 8) (:knee-r :flex 30) (:spine :flex 4) (:arm-r :flex 32 :side 40) (:elbow-r :flex 40))
  (:end :ke-stance))
;; K1 OBURI: the shoulder-launch chop: the blade up onto the right shoulder, up on the toes and held, then one vertical
;; stroke as he drops into bent knees; the blade bites the floor (one hand: the left thrown back)
(defstrike :ke-f1 (16 4 20 :base :ke-stance)
  (0)
  (6 (:arm-r :flex 110 :side 25 :twist 0) (:elbow-r :flex 130) (:hand-r :twist 0 :flex -90) (:chest :twist -10) (:root :u 0.02))
  (9 (:root :u 0.07 :f -0.05) (:spine :flex -12) (:chest :twist -15) (:arm-r :flex 150 :side 20) (:elbow-r :flex 120)
     (:hand-r :flex -80) (:arm-l :flex 60 :side 30) (:elbow-l :flex 30) (:head :flex -10) (:thigh-r :flex -5) (:knees :flex 8))
  (13 (:root :u 0.09 :f -0.06) (:spine :flex -16) (:arm-r :flex 160 :side 15) (:elbow-r :flex 110))           ; held at the top
  (:s :snap (:root :u -0.3 :f 0.55) (:spine :flex 42) (:chest :twist 10) (:arm-r :flex 75 :side 0) (:elbow-r :flex 0)
      (:hand-r :twist 0 :flex -40) (:arm-l :flex -30 :side 40) (:elbow-l :flex 10) (:thigh-r :flex 60) (:knee-r :flex 70)
      (:thigh-l :flex -10) (:knee-l :flex 60) (:head :flex -15))
  (:a (:spine :flex 50) (:arm-r :flex 40) (:hand-r :flex -55) (:root :u -0.34 :f 0.58))                       ; into the floor
  (28 (:spine :flex 46) (:arm-r :flex 42) (:root :u -0.32 :f 0.56))
  (:end :ke-stance))
;; K2 KIRIAGE: the drag-up launcher: turned, the tip dropped to the floor behind him and dragged as he steps in, then the
;; rising cut in front as the whole body stands up onto the toes
(defstrike :ke-f2 (20 5 28 :base :ke-stance)
  (0)
  (8 (:pelvis :twist 0) (:chest :twist -15) (:spine :flex 30) (:root :u -0.25 :f -0.05) (:knees :flex 55)
     (:arm-r :flex -45 :side 15) (:elbow-r :flex 5) (:hand-r :twist 0 :flex -30) (:arm-l :flex 45 :side 25) (:elbow-l :flex 40)
     (:head :flex -20))                                                                                        ; the tip on the floor behind
  (16 (:root :u -0.3 :f 0.2) (:chest :twist -10) (:spine :flex 34) (:arm-r :flex -50 :side 16) (:thigh-r :flex 30)
      (:thigh-l :flex -20))                                                                                    ; held: stepping in, scraping
  (:s :snap (:pelvis :twist 0) (:root :u 0.05 :f 0.5) (:arm-r :flex 70 :side 5) (:elbow-r :flex 5) (:hand-r :twist 0 :flex -45)
      (:arm-l :flex -20 :side 40) (:spine :flex -10) (:knees :flex 15) (:thigh-r :flex 20) (:thigh-l :flex -10) (:head :flex -15)
      (:chest :twist -10))
  (:a (:arm-r :flex 165) (:hand-r :flex -30) (:spine :flex -26) (:root :u 0.16 :f 0.52) (:head :flex -28))                        ; up on the toes
  (36 (:arm-r :flex 160) (:spine :flex -22) (:root :u 0.1 :f 0.5))
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
;; SP1 BUTTAGIRU: the leap overhead hack, one hand: knees tucked, the blade cocked behind his head, the left arm out, then
;; a one-handed vertical drop that cracks the floor
(defstrike :ke-buttagiru (22 4 26 :base :ke-stance)
  (0)
  (6 (:root :u -0.3) (:knees :flex 80) (:thighs :flex 60) (:spine :flex 30) (:arm-r :flex 30 :side 30) (:elbow-r :flex 60)
     (:arm-l :flex 30 :side 30) (:elbow-l :flex 40))
  (12 (:root :u 0.6) (:thighs :flex 70) (:knees :flex 100) (:arm-r :flex 170 :side 30) (:elbow-r :flex 100) (:hand-r :twist 0 :flex -40)
      (:arm-l :flex 70 :side 70) (:elbow-l :flex 10) (:spine :flex -22) (:head :flex -15))
  (17 (:root :u 0.75) (:spine :flex -27) (:elbow-r :flex 115) (:head :flex -18))
  (19 (:root :u 0.76) (:spine :flex -29))                                                                      ; hang at the apex
  (:s :snap (:root :u -0.37 :f 0.42) (:spine :flex 55) (:arm-r :flex 25 :side 0) (:elbow-r :flex 0) (:hand-r :twist 0 :flex -40)
      (:arm-l :flex -35 :side 45) (:elbow-l :flex 10) (:knees :flex 92) (:thighs :flex 71) (:head :flex -30))
  (:a (:spine :flex 60) (:root :u -0.4 :f 0.44))                                                              ; overshoot
  (34 (:spine :flex 56) (:root :u -0.37 :f 0.42))
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
  (:s :snap (:root :f 0.04 :u -0.1) (:spine :flex 14) (:head :flex 4) (:chest :twist 0) (:pelvis :twist 0)
      (:thigh-l :flex 48 :side 6) (:knee-l :flex 42) (:thigh-r :flex -32 :side 8) (:knee-r :flex 14)
      (:arm-r :flex 94 :side -12 :twist 11) (:elbow-r :flex 8) (:hand-r :flex -125 :twist 0)
      (:arm-l :flex 38 :side -61 :twist 71) (:elbow-l :flex 47))
  (:a (:root :f 0.07 :u -0.13) (:spine :flex 18) (:thigh-l :flex 52) (:knee-l :flex 48) (:thigh-r :flex -34) (:knee-r :flex 16)
      (:arm-r :flex 86 :side -12 :twist 11) (:elbow-r :flex 6) (:hand-r :flex -125 :twist -1)
      (:arm-l :flex 38 :side -55 :twist 64) (:elbow-l :flex 40))
  (18 (:root :f 0.06 :u -0.11) (:spine :flex 15) (:head :flex 0))                            ; zanshin
  (21 (:root :f 0.03 :u -0.05) (:spine :flex 8) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10) (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))          ; lifted back to jodan
  (:end :ke-r-stance))
(defstrike :ke-r-q3 (14 4 22 :base :ke-r-stance)       ; KESA: the diagonal, shoulder to hip
  (0)
  (6 (:root :u -0.06 :f -0.04) (:pelvis :twist 20) (:chest :twist -35) (:spine :flex -4) (:head :flex -4 :twist 20)
     (:arm-r :flex 150 :side 35 :twist -48) (:elbow-r :flex 70) (:hand-r :flex -47 :twist -7)
     (:arm-l :flex 133 :side -1 :twist 48) (:elbow-l :flex 71))
  (10 (:root :u -0.08 :f -0.06) (:chest :twist -40) (:spine :flex -6))
  (:s :snap (:root :f 0.03 :u -0.14) (:pelvis :twist -10) (:chest :twist 35) (:spine :flex 20) (:head :flex 0 :twist -15)
      (:thigh-l :flex 46 :side 8) (:knee-l :flex 45) (:thigh-r :flex -25 :side 10) (:knee-r :flex 18)
      (:arm-r :flex 10 :side -25 :twist -9) (:elbow-r :flex 140) (:hand-r :flex -180 :twist 4)
      (:arm-l :flex 29 :side -16 :twist 56) (:elbow-l :flex 54))
  (:a (:root :f 0.06 :u -0.16) (:pelvis :twist -14) (:chest :twist 44) (:spine :flex 24) (:head :twist -18)
      (:thigh-l :flex 50) (:knee-l :flex 50) (:thigh-r :flex -26) (:knee-r :flex 20))
  (27 (:root :f 0.05 :u -0.14) (:chest :twist 41) (:spine :flex 21))
  (33 (:root :f 0.02 :u -0.06) (:chest :twist 10) (:pelvis :twist 0) (:spine :flex 8) (:head :twist 0) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10) (:arm-l :flex 32 :side -52 :twist 55) (:elbow-l :flex 39))
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
;; J2 KOTE (docs/duel/DUEL_STRINGS.md §3.4): the only small motion in the set: a short lift from jodan, the wrists snap the
;; cleaver down to forearm height, a half step in
(defstrike :ke-r-kote (9 3 13 :base :ke-r-stance)      ; J2 KOTE: the small wrist snap
  (0)
  (4 (:root :f -0.03 :u 0.02) (:spine :flex -4) (:arm-r :flex 132 :side 12 :twist 15) (:elbow-r :flex 70) (:hand-r :flex -40 :twist -6)
     (:arm-l :flex 128 :side 14 :twist 40) (:elbow-l :flex 60))
  (7 (:root :f -0.04 :u 0.03) (:arm-r :flex 136) (:hand-r :flex -36))                              ; the lift, held
  (:s :snap (:root :f 0.03 :u -0.07) (:spine :flex 10) (:chest :twist -4) (:pelvis :twist 4)
      (:thigh-l :flex 36 :side 6) (:knee-l :flex 32) (:thigh-r :flex -22 :side 8) (:knee-r :flex 12)
      (:arm-r :flex 10 :side -10 :twist 11) (:elbow-r :flex 120) (:hand-r :flex -170 :twist 0)
      (:arm-l :flex 36 :side -58 :twist 68) (:elbow-l :flex 45))
  (:a (:root :f 0.05 :u -0.08) (:spine :flex 12))
  (18 (:root :f 0.04 :u -0.06) (:spine :flex 9))
  (22 (:root :f 0.02 :u -0.03) (:spine :flex 5) (:arm-r :flex 55 :side -10 :twist -3) (:elbow-r :flex 95) (:hand-r :flex -67 :twist 10)
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

;;; ---------------------------------------------------------------- the Bankai (docs/duel/DUEL_KEN_BANKAI.md §12): the oni
;; The feral pass (the user's request 2026-09-28, 「更野性」): a beast, not a swordsman. A deep forward-leaning crouch on
;; bent, splayed legs, the back rounded and the shoulders hunched over it, the head low and thrust forward, the eyes up;
;; the arms hang loose and wide, the left hand a claw, the broken cleaver dragged low behind him in the right. His strikes
;; lunge from the crouch. Art only: the moves' S / A / R, reach and hit volumes are unchanged.
(defpose :ke-b-stance (:base :ke-stance)
  (:root :u -0.3 :f 0.04) (:pelvis :twist 16) (:spine :flex 40) (:chest :flex 16 :twist -10) (:neck :flex 8)
  (:head :flex -58 :twist -6)
  (:arm-r :flex -16 :side 30 :twist 0) (:elbow-r :flex 22) (:hand-r :flex -100 :twist 10)
  (:arm-l :flex 40 :side 42) (:elbow-l :flex 60) (:hand-l :flex 45)
  (:thigh-r :flex -12 :side 22) (:knee-r :flex 60) (:thigh-l :flex 62 :side 22) (:knee-l :flex 84))
;; the idle: the back heaves (breath through the teeth), the claw flexing, the blade tip scraping
(defclip :ke-b-stance (0.8 :loop t :base :ke-b-stance)
  (0) (0.4 (:chest :flex 24) (:spine :flex 38) (:root :u -0.33) (:head :flex -62) (:hand-l :flex 60) (:elbow-l :flex 70)
           (:hand-r :flex -96)))
;; guard: crouched lower still behind the raised left forearm, the broken blade turned flat across the body
(defpose :ke-b-guard (:base :ke-b-stance)
  (:root :u -0.34) (:spine :flex 34) (:chest :flex 12 :twist -18) (:head :flex -44)
  (:arm-r :flex 62 :side 18 :twist 20) (:elbow-r :flex 76) (:hand-r :twist 60 :flex -70)
  (:arm-l :flex 82 :side 12) (:elbow-l :flex 118) (:hand-l :flex 30)
  (:thigh-r :flex -6 :side 24) (:knee-r :flex 66) (:thigh-l :flex 60 :side 24) (:knee-l :flex 88))
(defclip :ke-b-guard (0.6 :loop t :base :ke-b-guard) (0) (0.3 (:root :u -0.37) (:chest :flex 16)))
(defclip :ke-b-guard-hit (0.2 :base :ke-b-guard)
  (0) (0.05 :snap (:spine :flex 24) (:root :f -0.14 :u -0.3) (:head :flex -30)) (0.2 :ke-b-guard))
;; the prowl and the run: the shared leg cycles laid under the crouch (deeper hips and knees, the back rounded more)
(defun oni-keys (keys &key (du -0.28) (dthigh 38) (dknee 60) (dspine 18) (dhead -18))
  "KEYS (DEFCLIP key lists of the shared walk / run legs) sunk into the oni's crouch: every :root :u, thigh and knee
flex and the spine / head flex shifted by these."
  (flet ((shift (spec)
           (destructuring-bind (group &rest cv) spec
             (cons group (loop for (ch v) on cv by #'cddr
                               append (list ch (+ v (cond ((and (eq group :root) (eq ch :u)) du)
                                                          ((not (eq ch :flex)) 0)
                                                          ((member group '(:thigh-r :thigh-l :thighs)) dthigh)
                                                          ((member group '(:knee-r :knee-l :knees)) dknee)
                                                          ((eq group :spine) dspine)
                                                          ((eq group :head) dhead)
                                                          (t 0)))))))))
    (loop for (tm . specs) in keys collect (cons tm (mapcar #'shift specs)))))
(defparameter *oni-walk*
  '((:ke-b-walk-f 0.9 ((0 (:thigh-r :flex 25) (:knee-r :flex 10) (:thigh-l :flex -15) (:knee-l :flex 20))
                       (0.225 (:root :u -0.03) (:thigh-r :flex 0) (:knee-r :flex 20) (:thigh-l :flex 5) (:knee-l :flex 55))
                       (0.45 (:root :u -0.05) (:thigh-l :flex 25) (:knee-l :flex 10) (:thigh-r :flex -15) (:knee-r :flex 20))
                       (0.675 (:root :u -0.03) (:thigh-l :flex 0) (:knee-l :flex 20) (:thigh-r :flex 5) (:knee-r :flex 55))))
    (:ke-b-walk-b 0.9 ((0 (:thigh-r :flex -15) (:knee-r :flex 20) (:thigh-l :flex 25) (:knee-l :flex 10))
                       (0.225 (:root :u -0.03) (:thigh-r :flex 5) (:knee-r :flex 55) (:thigh-l :flex 0) (:knee-l :flex 20))
                       (0.45 (:root :u -0.05) (:thigh-l :flex -15) (:knee-l :flex 20) (:thigh-r :flex 25) (:knee-r :flex 10))
                       (0.675 (:root :u -0.03) (:thigh-l :flex 5) (:knee-l :flex 55) (:thigh-r :flex 0) (:knee-r :flex 20))))
    (:ke-b-strafe-r 0.8 ((0 (:thigh-r :side 22 :flex 5) (:thigh-l :side -2 :flex 20) (:knee-l :flex 25) (:knee-r :flex 10))
                         (0.2 (:root :u -0.04) (:thigh-r :side 8) (:knee-r :flex 45) (:thigh-l :side 5))
                         (0.4 (:thigh-r :side 4) (:thigh-l :side 18 :flex 10) (:knee-l :flex 20))
                         (0.6 (:root :u -0.04) (:thigh-l :side 5) (:knee-l :flex 45) (:thigh-r :side 10))))
    (:ke-b-strafe-l 0.8 ((0 (:thigh-l :side 22 :flex 30) (:thigh-r :side -2 :flex 0) (:knee-r :flex 25) (:knee-l :flex 10))
                         (0.2 (:root :u -0.04) (:thigh-l :side 8) (:knee-l :flex 45) (:thigh-r :side 12))
                         (0.4 (:thigh-l :side 4) (:thigh-r :side 22 :flex -5) (:knee-r :flex 20))
                         (0.6 (:root :u -0.04) (:thigh-r :side 8) (:knee-r :flex 45) (:thigh-l :side 10)))))
  "The oni's prowl: the shared walk / strafe legs (body.lisp), each clip (name seconds keys) sunk by ONI-KEYS.")
(loop for (name dur keys) in *oni-walk* do (build-clip name dur t :ke-b-stance (oni-keys keys)))
;; the run: on the shoulder-rest set the blade rides his shoulder; the oni runs bent double, the blade trailing
(loop for name in '(:ke-b-run :ke-b-skate-b :ke-b-slide-r :ke-b-slide-l)
      for keys in (list *run-keys* *skate-keys* *slide-r-keys* *slide-l-keys*)
      do (build-clip name 0.5 t :ke-b-stance (oni-keys keys :du -0.2 :dthigh 22 :dknee 40 :dspine 22 :dhead -22)))
;; J3 GENKOTSU / SP2's NAGURI-TOBASHI: from the crouch he springs, the left hook thrown with the whole body, the cleaver
;; flung out wide behind, held 3 f on contact
(defstrike :ke-b-fist (9 3 18 :base :ke-b-stance)
  (0)
  (4 (:chest :twist 40 :flex 20) (:spine :flex 46) (:arm-l :flex 30 :side 70) (:elbow-l :flex 115) (:hand-l :flex 0)
     (:root :u -0.36 :f -0.1) (:head :twist 14 :flex -60) (:knee-l :flex 92) (:thigh-l :flex 66))    ; coiled lower
  (7 (:chest :twist 46) (:root :u -0.37 :f -0.12))                                                  ; held
  (:s :snap (:chest :twist -52 :flex 8) (:spine :flex 30) (:arm-l :flex 94 :side 6) (:elbow-l :flex 18) (:hand-l :flex 0)
      (:root :f 0.5 :u -0.2) (:thigh-l :flex 58) (:knee-l :flex 52) (:thigh-r :flex -34) (:knee-r :flex 24)
      (:arm-r :flex -40 :side 75) (:hand-r :flex -90) (:head :twist -10 :flex -40))
  (:a (:chest :twist -60) (:root :f 0.56))                                                           ; overshoot, held
  (20 (:chest :twist -52) (:root :f 0.5 :u -0.24) (:arm-l :flex 80) (:elbow-l :flex 34) (:spine :flex 36))
  (:end :ke-b-stance))
;; J3 GENKOTSU alone (the J cut, docs/duel/DUEL_STRINGS.md §13): the same hook thrown from where he stands, close (SP2's punch
;; keeps the long spring above)
(defstrike :ke-b-hook (9 3 18 :base :ke-b-stance)
  (0)
  (4 (:chest :twist 40 :flex 20) (:spine :flex 46) (:arm-l :flex 30 :side 70) (:elbow-l :flex 115) (:hand-l :flex 0)
     (:root :u -0.36 :f -0.1) (:head :twist 14 :flex -60) (:knee-l :flex 92) (:thigh-l :flex 66))    ; coiled lower
  (7 (:chest :twist 46) (:root :u -0.37 :f -0.12))                                                  ; held
  (:s :snap (:chest :twist -52 :flex 8) (:spine :flex 30) (:arm-l :flex 94 :side 6) (:elbow-l :flex 40) (:hand-l :flex 0)
      (:root :f 0.0 :u -0.2) (:thigh-l :flex 58) (:knee-l :flex 52) (:thigh-r :flex -34) (:knee-r :flex 24)
      (:arm-r :flex -40 :side 75) (:hand-r :flex -90) (:head :twist -10 :flex -40))
  (:a (:chest :twist -60) (:root :f 0.03))                                                           ; overshoot, held
  (20 (:chest :twist -52) (:root :f 0.02 :u -0.24) (:arm-l :flex 80) (:elbow-l :flex 44) (:spine :flex 36))
  (:end :ke-b-stance))
;; L KAMICHIGIRI: down on all fours-low, a lunge, the left claw clamps the arm, the head drives in, the tearing jerk back
(defstrike :ke-b-bite (10 3 28 :base :ke-b-stance)
  (0)
  (5 (:root :u -0.44 :f -0.08) (:spine :flex 56) (:chest :flex 18) (:head :flex -66) (:knees :flex 96) (:thigh-l :flex 74)
     (:arm-l :flex 60 :side 30) (:elbow-l :flex 40) (:hand-l :flex 50))
  (8 (:root :u -0.46 :f -0.12) (:spine :flex 58))                                                   ; coiled, held
  (:s :snap (:root :f 0.78 :u -0.26) (:spine :flex 50) (:chest :flex 10) (:head :flex -10) (:arm-l :flex 100 :side 8)
      (:elbow-l :flex 20) (:hand-l :flex 55) (:thigh-l :flex 66) (:knee-l :flex 62) (:thigh-r :flex -34) (:knee-r :flex 22))
  (:a (:root :f 0.82) (:head :flex 4))                                                               ; the teeth in
  (18 (:root :f 0.6 :u -0.2) (:spine :flex 18) (:head :flex -48) (:arm-l :flex 70 :side 30) (:elbow-l :flex 62))  ; torn off
  (27 (:root :f 0.5 :u -0.26) (:head :flex -52) (:spine :flex 30))
  (:end :ke-b-stance))
;; O MAPPUTATSU's rush (the aura / dash; the strike is :ke-stance-cut): he drops almost to all fours, the claw on the
;; ground, then springs, the broken cleaver swung up one-handed over his head, the claw reaching ahead
(defclip :ke-b-leap (0.7 :base :ke-b-stance)
  (0)
  (0.13 (:root :u -0.5) (:knees :flex 104) (:thighs :flex 80) (:spine :flex 62) (:chest :flex 20) (:head :flex -70)
        (:arm-l :flex 70 :side 20) (:elbow-l :flex 20) (:hand-l :flex 60) (:arm-r :flex -40 :side 40) (:hand-r :flex -95))
  (0.25 (:root :u 0.05) (:thighs :flex 60) (:knees :flex 96) (:spine :flex 10) (:chest :flex 0) (:head :flex -30)
        (:arm-r :flex 185 :side 20) (:elbow-r :flex 30) (:hand-r :twist 0 :flex -60) (:arm-l :flex 110 :side 30) (:elbow-l :flex 30))
  (0.7 (:root :u 0.05) (:thighs :flex 55) (:knees :flex 90) (:arm-r :flex 188 :side 18) (:spine :flex 4)))
;; the MAPPUTATSU cinematic (ken-oni-kikon-cine plays it at 25/68 speed: the snap at 0.42 lands on its frame 68): the
;; wind-up is the beast rearing: sunk into the crouch, then up on his toes, back arched, the cleaver swung high over
;; his head in the right, the left claw thrust out, the jaw open; then one vertical crash, lunging through
(defclip :ke-b-kikon (1.5 :base :ke-b-stance)
  (0)
  (0.15 (:root :u -0.46) (:spine :flex 58) (:chest :flex 20) (:head :flex -68) (:knees :flex 100) (:thighs :flex 76)
        (:arm-r :flex -45 :side 36) (:hand-r :flex -95) (:arm-l :flex 50 :side 50) (:elbow-l :flex 40))
  (0.35 (:root :u -0.1 :f -0.1) (:spine :flex -16) (:chest :flex -10 :twist -20) (:head :flex -22)
        (:arm-r :flex 195 :side 24) (:elbow-r :flex 36) (:hand-r :twist 0 :flex -70)
        (:arm-l :flex 95 :side 40) (:elbow-l :flex 10) (:hand-l :flex 60)
        (:thigh-r :flex -20 :side 16) (:knee-r :flex 40) (:thigh-l :flex 50 :side 16) (:knee-l :flex 60))
  (0.42 :snap (:root :u -0.42 :f 0.8) (:spine :flex 66) (:chest :flex 16 :twist 10) (:head :flex -60)
        (:arm-r :flex 30 :side 8) (:elbow-r :flex 5) (:hand-r :twist -10 :flex -110) (:arm-l :flex 40 :side 60) (:elbow-l :flex 30)
        (:thigh-l :flex 78) (:knee-l :flex 84) (:thigh-r :flex -28) (:knee-r :flex 40))
  (1.0 (:root :u -0.4 :f 0.8) (:spine :flex 62))
  (1.5 :ke-b-stance (:root :f 0.8)))
;; the Bankai's burst (ken-bankai-cine f58): he rises out of the crouch, head thrown back, arms flung wide and low, claws
;; open, the knees still bent; then the roar comes forward at the opponent (the close-up on the face at f78)
(defclip :ke-b-roar (1.0 :base :ke-b-stance)
  (0 (:root :u -0.44) (:spine :flex 60) (:head :flex -70) (:knees :flex 100) (:thighs :flex 74))
  (0.12 :snap (:root :u -0.2) (:spine :flex -10) (:chest :flex -14) (:neck :flex -10) (:head :flex -34)
        (:arm-l :flex 20 :side 88) (:elbow-l :flex 30) (:hand-l :flex 60) (:arm-r :flex -10 :side 70) (:hand-r :flex -95)
        (:thigh-r :flex -6 :side 24) (:knee-r :flex 50) (:thigh-l :flex 44 :side 24) (:knee-l :flex 64))
  (0.3 (:spine :flex 14) (:chest :flex 4) (:neck :flex 0) (:head :flex -30) (:arm-l :side 92) (:arm-r :side 74))  ; at them
  (1.0 (:spine :flex 16) (:chest :flex 6) (:head :flex -32) (:root :u -0.22)))
