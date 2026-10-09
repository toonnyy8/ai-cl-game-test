;;;; rukia-art.lisp — KUCHIKI RUKIA (TYBW) as art data: her body (the 13th Division lieutenant: black shihakusho, the
;;;; lieutenant's armband, no haori) and its two variants (:rukia-zero, absolute zero: white hair and irises, the ice
;;;; half-crown; :rukia-bankai, 白霞罸 in the cinematic only: the white kimono; both with ice-blue keylines and brows),
;;;; her four blades (the sealed :ru-katana, the white Sode no Shirayuki, -50's rimed :ru-rime, the ice :ru-ice), every :ru-* pose and clip (docs/duel/DUEL_RUKIA.md §10), and her ice
;;;; looks (the hazards' draw functions, the auras, frost on a victim, the cinematics' frost discs, pillar and dust).
;;;; Attack clips use DEFSTRIKE (the hit pose at frame S, back in the stance at S+A+R). Ice is mono: white cores and the
;;;; SOUL glass palette, never STEEL (the guard's) and no spot hue of her own (docs/style/STYLE_STORM_DESIGN.md §A.2).
(in-package :duel)

;;; ---------------------------------------------------------------- body
;; 1.44 m (scale 0.80; ~1.50 m to the crown with the x1.3 head), slight (width 0.92). The hurt cylinder is r 0.34 /
;; h 1.50 (a fairness floor, not her true 0.30 / 1.44: arcs built against the men's bodies don't pass over her). One black
;; mass: the robe and the bob; white only in the under-collar, the armband, the tabi and the blade; a light obi at a narrow
;; waist; the hakama a knee-long flare.
(defbody :rukia (:scale 0.8 :width 0.92 :hunch 0 :hurt-r 0.34 :hurt-h 1.5
                 :girth ((:chest 0.84 1.0 0.86) (:spine 0.78 1.0 0.82) (:pelvis 0.9 1.0 0.9)
                         (:shoulder-r 0.8 0.8 0.8) (:shoulder-l 0.8 0.8 0.8)
                         (:upper-arm-r 0.82 1.0 0.82) (:upper-arm-l 0.82 1.0 0.82) (:lower-arm-r 0.82 1.0 0.82)
                         (:lower-arm-l 0.82 1.0 0.82) (:hand-r 0.9 0.9 0.9) (:hand-l 0.9 0.9 0.9)
                         (:thigh-r 0.9 1.0 0.9) (:thigh-l 0.9 1.0 0.9) (:shin-r 0.9 1.0 0.9) (:shin-l 0.9 1.0 0.9)
                         ;; playtest 1 (2026-09-28): an anime head, x1.3 about the head joint (the neck's top): ~7
                         ;; heads tall (was ~8.7; Yamamoto ~7.8, Kenpachi ~8). The crown variants' parts scale too. Art only
                         (:head 1.3 1.3 1.3))
                 :palette ((:skin #xDCC0AE) (:black #x16161E) (:hair #x0C0C12) (:white #xECECE8) (:badge #x101018)
                           (:pupil #x5A5070) (:core #x16121C) (:shine #xFFFFFF) (:eye #xF2F0EC) (:lid #x141016)
                           (:mouth #x7A3A3C) (:fold #xD8DCE4) (:obi #xC8CCD6) (:tabi #xE8E8E4) (:sole #x262833)
                           (:ice #xE6ECF4) (:blood #xD0101C) (:brow #x0C0C12) (:clench #x141016))
                 :rim (#xD8E4FF 0.18))
  (:pelvis (:box 0.34 0.18 0.24 :c :black)
           (:box 0.35 0.045 0.25 :at (0 0.075 0) :c :obi)                                        ; the obi at the waist
           (:box 0.05 0.03 0.02 :at (0.07 0.074 0.13) :rot (0 0 -12) :c :obi)                   ; its knot
           (:cyl 0.2 0.44 :top 0.15 :seg 8 :at (0 -0.2 0) :c :black)                            ; the hakama's flare
           (:box 0.004 0.3 0.004 :at (0.05 -0.24 0.17) :rot (0 0 -4) :c :fold))                 ; a pleat
  (:spine (:bevel 0.34 0.25 0.23 0.04 :at (0 0.11 0) :c :black))
  (:chest (:bevel 0.4 0.28 0.25 0.05 :at (0 0.11 0) :c :black)
          (:box 0.16 0.07 0.04 :at (0 0.262 -0.05) :rot (0 -8 0) :c :black)                      ; the collar round the neck
          (:box 0.035 0.07 0.11 :at (0.066 0.258 0.0) :rot (0 0 -8) :c :black)
          (:box 0.035 0.07 0.11 :at (-0.066 0.258 0.0) :rot (0 0 8) :c :black)
          (:box 0.016 0.17 0.01 :at (0.032 0.182 0.13) :rot (0 0 -24) :c :white)                ; the white under-collar V
          (:box 0.016 0.17 0.01 :at (-0.032 0.182 0.13) :rot (0 0 24) :c :white)
          (:box 0.005 0.16 0.004 :at (0.07 0.07 0.132) :rot (0 0 -10) :c :fold)                  ; a fold highlight
          (:box 0.02 0.08 0.012 :at (0.04 0.2 0.132) :rot (0 0 -24) :c :ice :tag :ice-trim)      ; -50: frost on the collar
          (:box 0.02 0.08 0.012 :at (-0.04 0.2 0.132) :rot (0 0 24) :c :ice :tag :ice-trim))
  (:neck (:cyl 0.034 0.17 :at (0 0.06 0) :c :skin))
  ;; the head (metres before the :girth x1.3; x sizes x the body width): a small skull, a flat-fronted face narrowing
  ;; in a V to a small chin, large eyes (a heavy lash line, violet-grey irises under S 0.3, a catch-light), a small nose
  ;; and mouth; the short black bob hugging the head with pointed locks, the strand between the eyes, white highlight
  ;; strokes on the crown
  (:head (:sphere 0.064 :stretch 0.02 :at (0 0.14 -0.012) :seg 12 :c :skin)                        ; skull
         (:bevel 0.104 0.07 0.076 0.02 :at (0 0.127 0.023) :c :skin)                                ; brow and cheeks
         (:bevel 0.05 0.072 0.066 0.014 :at (0.021 0.08 0.024) :rot (0 0 -24) :c :skin)            ; the jaw in a V
         (:bevel 0.05 0.072 0.066 0.014 :at (-0.021 0.08 0.024) :rot (0 0 24) :c :skin)
         (:wedge 0.012 0.018 0.012 :at (0 0.097 0.064) :rot (180 0 0) :c :skin)                    ; nose
         ;; :face-neutral: wide eyes, level brows, a small closed mouth
         (:box 0.028 0.021 0.003 :at (0.027 0.117 0.0615) :c :eye :tag :face-neutral)
         (:box 0.028 0.021 0.003 :at (-0.027 0.117 0.0615) :c :eye :tag :face-neutral)
         (:box 0.016 0.021 0.003 :at (0.024 0.116 0.0622) :c :pupil :tag :face-neutral)
         (:box 0.016 0.021 0.003 :at (-0.024 0.116 0.0622) :c :pupil :tag :face-neutral)
         (:box 0.007 0.011 0.003 :at (0.024 0.115 0.0629) :c :core :tag :face-neutral)
         (:box 0.007 0.011 0.003 :at (-0.024 0.115 0.0629) :c :core :tag :face-neutral)
         (:box 0.005 0.005 0.003 :at (0.028 0.121 0.0636) :c :shine :tag :face-neutral)
         (:box 0.005 0.005 0.003 :at (-0.02 0.121 0.0636) :c :shine :tag :face-neutral)
         (:box 0.036 0.0065 0.003 :at (0.027 0.128 0.0638) :rot (0 0 -6) :c :lid :tag :face-neutral)   ; lash lines
         (:box 0.036 0.0065 0.003 :at (-0.027 0.128 0.0638) :rot (0 0 6) :c :lid :tag :face-neutral)
         (:box 0.011 0.004 0.003 :at (0.046 0.124 0.0638) :rot (0 0 -35) :c :lid :tag :face-neutral)   ; their flicks
         (:box 0.011 0.004 0.003 :at (-0.046 0.124 0.0638) :rot (0 0 35) :c :lid :tag :face-neutral)
         (:box 0.026 0.0035 0.003 :at (0.028 0.145 0.0625) :rot (0 0 -6) :c :brow :tag :face-neutral)  ; brows
         (:box 0.026 0.0035 0.003 :at (-0.028 0.145 0.0625) :rot (0 0 6) :c :brow :tag :face-neutral)
         (:box 0.016 0.003 0.003 :at (0 0.07 0.0585) :c :mouth :tag :face-neutral)
         ;; :face-shout: the eyes narrowed and hard, the lash lines and brows down at the middle, the mouth open
         (:box 0.028 0.015 0.003 :at (0.027 0.115 0.0615) :c :eye :tag :face-shout)
         (:box 0.028 0.015 0.003 :at (-0.027 0.115 0.0615) :c :eye :tag :face-shout)
         (:box 0.014 0.015 0.003 :at (0.023 0.115 0.0622) :c :pupil :tag :face-shout)
         (:box 0.014 0.015 0.003 :at (-0.023 0.115 0.0622) :c :pupil :tag :face-shout)
         (:box 0.006 0.009 0.003 :at (0.023 0.115 0.0629) :c :core :tag :face-shout)
         (:box 0.006 0.009 0.003 :at (-0.023 0.115 0.0629) :c :core :tag :face-shout)
         (:box 0.036 0.007 0.003 :at (0.027 0.1235 0.0638) :rot (0 0 10) :c :lid :tag :face-shout)
         (:box 0.036 0.007 0.003 :at (-0.027 0.1235 0.0638) :rot (0 0 -10) :c :lid :tag :face-shout)
         (:box 0.028 0.005 0.003 :at (0.028 0.138 0.0625) :rot (0 0 18) :c :brow :tag :face-shout)
         (:box 0.028 0.005 0.003 :at (-0.028 0.138 0.0625) :rot (0 0 -18) :c :brow :tag :face-shout)
         (:box 0.024 0.018 0.003 :at (0 0.067 0.0585) :c :mouth :tag :face-shout)
         (:box 0.02 0.004 0.003 :at (0 0.0735 0.0592) :c :eye :tag :face-shout)                         ; upper teeth
         ;; :face-hurt: eyes squeezed shut (> <), the brows up at the middle, a clenched grimace
         (:box 0.026 0.0045 0.003 :at (0.027 0.121 0.0625) :rot (0 0 14) :c :lid :tag :face-hurt)
         (:box 0.026 0.0045 0.003 :at (0.027 0.113 0.0625) :rot (0 0 -14) :c :lid :tag :face-hurt)
         (:box 0.026 0.0045 0.003 :at (-0.027 0.121 0.0625) :rot (0 0 -14) :c :lid :tag :face-hurt)
         (:box 0.026 0.0045 0.003 :at (-0.027 0.113 0.0625) :rot (0 0 14) :c :lid :tag :face-hurt)
         (:box 0.028 0.004 0.003 :at (0.028 0.141 0.0625) :rot (0 0 -18) :c :brow :tag :face-hurt)
         (:box 0.028 0.004 0.003 :at (-0.028 0.141 0.0625) :rot (0 0 18) :c :brow :tag :face-hurt)
         (:box 0.026 0.011 0.003 :at (0 0.068 0.0585) :c :mouth :tag :face-hurt)
         (:box 0.022 0.005 0.003 :at (0 0.068 0.0592) :c :eye :tag :face-hurt)
         (:box 0.022 0.0012 0.003 :at (0 0.068 0.0598) :c :clench :tag :face-hurt)                     ; the clench (dark in every look)
         ;; the bob: a cap over the skull, the back to the nape, side sheets over the ears, pointed jaw-length locks
         ;; flaring out a little at the tips, the fringe of pointed locks and the strand between the eyes
         (:sphere 0.074 :stretch 0.02 :at (0 0.15 -0.018) :seg 12 :c :hair)
         (:bevel 0.15 0.11 0.08 0.03 :at (0 0.1 -0.052) :c :hair)                                   ; the back, to the nape
         (:bevel 0.03 0.11 0.1 0.012 :at (0.064 0.108 -0.004) :rot (0 0 -4) :c :hair)              ; over the ears
         (:bevel 0.03 0.11 0.1 0.012 :at (-0.064 0.108 -0.004) :rot (0 0 4) :c :hair)
         (:cone 0.024 0.078 :at (0.066 0.04 0.03) :rot (0 180 -10) :seg 4 :c :hair)                 ; jaw-length locks
         (:cone 0.024 0.078 :at (-0.066 0.04 0.03) :rot (0 180 10) :seg 4 :c :hair)
         (:cone 0.026 0.07 :at (0.07 0.046 -0.02) :rot (0 180 -14) :seg 4 :c :hair)
         (:cone 0.026 0.07 :at (-0.07 0.046 -0.02) :rot (0 180 14) :seg 4 :c :hair)
         (:cone 0.028 0.06 :at (0.04 0.05 -0.07) :rot (0 190 -8) :seg 4 :c :hair)                   ; the nape's points
         (:cone 0.028 0.06 :at (-0.04 0.05 -0.07) :rot (0 190 8) :seg 4 :c :hair)
         (:bevel 0.108 0.028 0.036 0.012 :at (0 0.178 0.047) :rot (0 -24 0) :c :hair)              ; the fringe ...
         (:cone 0.02 0.056 :at (0.036 0.158 0.062) :rot (0 186 8) :seg 4 :c :hair)                  ; ... its locks
         (:cone 0.018 0.05 :at (0.013 0.162 0.066) :rot (0 186 2) :seg 4 :c :hair)
         (:cone 0.018 0.05 :at (-0.016 0.162 0.066) :rot (0 186 -4) :seg 4 :c :hair)
         (:cone 0.02 0.056 :at (-0.04 0.158 0.062) :rot (0 186 -10) :seg 4 :c :hair)
         (:cone 0.008 0.064 :at (0.005 0.134 0.068) :rot (0 184 -4) :seg 4 :c :hair)                ; the strand between the eyes
         (:box 0.006 0.028 0.003 :at (-0.039 0.206 0.029) :rot (222 -36 0) :c :fold)               ; white highlight strokes
         (:box 0.006 0.024 0.003 :at (-0.017 0.21 0.039) :rot (198 -40 0) :c :fold)
         (:box 0.006 0.028 0.003 :at (0.023 0.208 0.038) :rot (156 -38 0) :c :fold)
         (:box 0.006 0.05 0.003 :at (0.031 0.199 -0.077) :rot (30 -30 0) :c :fold)
         ;; the ice rims of -50 (:ice-trim, hidden elsewhere): icicles on the locks' tips
         (:cone 0.012 0.03 :at (0.071 0.008 0.03) :rot (0 180 -10) :seg 4 :c :ice :tag :ice-trim)
         (:cone 0.012 0.03 :at (-0.071 0.008 0.03) :rot (0 180 10) :seg 4 :c :ice :tag :ice-trim)
         (:cone 0.012 0.028 :at (0.077 0.016 -0.02) :rot (0 180 -14) :seg 4 :c :ice :tag :ice-trim)
         (:cone 0.012 0.028 :at (-0.077 0.016 -0.02) :rot (0 180 14) :seg 4 :c :ice :tag :ice-trim))
  (:shoulder-r (:bevel 0.11 0.06 0.17 0.02 :at (0.02 -0.02 0) :rot (0 0 -20) :c :black))
  (:shoulder-l (:bevel 0.11 0.06 0.17 0.02 :at (-0.02 -0.02 0) :rot (0 0 20) :c :black))
  (:upper-arm-r (:box 0.12 0.3 0.13 :at (0 -0.15 0) :c :black))
  ;; the lieutenant's armband on the left upper arm: a white band, 十三 and the snowdrop in ink on its outside
  (:upper-arm-l (:box 0.12 0.3 0.13 :at (0 -0.15 0) :c :black)
                (:box 0.13 0.08 0.14 :at (0 -0.1 0) :c :white)
                (:box 0.004 0.044 0.022 :at (-0.066 -0.1 0.0) :c :badge)
                (:box 0.004 0.006 0.038 :at (-0.066 -0.1 0.0) :c :badge)
                (:box 0.004 0.02 0.006 :at (-0.066 -0.088 0.014) :rot (0 30 0) :c :badge))
  (:lower-arm-r (:box 0.15 0.2 0.16 :at (0 -0.1 0) :c :black)                                     ; the wide sleeve
                (:box 0.04 0.2 0.18 :at (0 -0.15 -0.05) :rot (0 -10 0) :c :black)
                (:box 0.13 0.01 0.14 :at (0 -0.2 0) :c :ice :tag :ice-trim)                       ; the frosted hem
                (:box 0.05 0.07 0.05 :at (0 -0.23 0) :c :skin))
  (:lower-arm-l (:box 0.15 0.2 0.16 :at (0 -0.1 0) :c :black)
                (:box 0.04 0.2 0.18 :at (0 -0.15 -0.05) :rot (0 -10 0) :c :black)
                (:box 0.13 0.01 0.14 :at (0 -0.2 0) :c :ice :tag :ice-trim)
                (:box 0.05 0.07 0.05 :at (0 -0.23 0) :c :skin))
  ;; the right hand; CRACK (:hand-crack): a BLOOD hairline zigzag across its back (the outside, +x, on the grip)
  (:hand-r (:bevel 0.056 0.076 0.056 0.016 :at (0 -0.038 0) :c :skin)
           (:glow 1.8 (:box 0.004 0.026 0.005 :at (0.0262 -0.022 0.012) :rot (0 32 0) :c :blood) :hand-crack)
           (:glow 1.8 (:box 0.004 0.026 0.005 :at (0.0262 -0.042 0.004) :rot (0 -40 0) :c :blood) :hand-crack)
           (:glow 1.8 (:box 0.004 0.022 0.005 :at (0.0262 -0.06 0.01) :rot (0 24 0) :c :blood) :hand-crack))
  (:hand-l (:bevel 0.056 0.076 0.056 0.016 :at (0 -0.038 0) :c :skin))
  (:thigh-r (:cyl 0.1 0.44 :top 0.09 :seg 10 :at (0 -0.21 0) :c :black)
            (:box 0.005 0.26 0.004 :at (0.03 -0.2 0.106) :rot (0 -3 -4) :c :fold))
  (:thigh-l (:cyl 0.1 0.44 :top 0.09 :seg 10 :at (0 -0.21 0) :c :black))
  (:shin-r (:cyl 0.12 0.3 :top 0.1 :seg 10 :at (0 -0.1 0) :c :black) (:cyl 0.125 0.08 :top 0.12 :seg 10 :at (0 -0.27 0) :c :black)
           (:box 0.07 0.12 0.08 :at (0 -0.37 0) :c :tabi))
  (:shin-l (:cyl 0.12 0.3 :top 0.1 :seg 10 :at (0 -0.1 0) :c :black) (:cyl 0.125 0.08 :top 0.12 :seg 10 :at (0 -0.27 0) :c :black)
           (:box 0.07 0.12 0.08 :at (0 -0.37 0) :c :tabi))
  (:foot-r (:bevel 0.08 0.055 0.2 0.02 :at (0 -0.02 0.05) :c :tabi) (:box 0.09 0.02 0.22 :at (0 -0.05 0.05) :c :sole))
  (:foot-l (:bevel 0.08 0.055 0.2 0.02 :at (0 -0.02 0.05) :c :tabi) (:box 0.09 0.02 0.22 :at (0 -0.05 0.05) :c :sole)))

;; the half-crown of ice (absolute zero and the Bankai): crystals fanned out behind the head
;; the half-crown of ice (absolute zero and the Bankai): crystals fanned out behind the head, past its outline
(defparameter *ru-crown*
  '((:cone 0.02 0.17 :at (0.0 0.22 -0.085) :rot (0 18 0) :seg 4 :c :ice)
    (:cone 0.018 0.15 :at (0.028 0.203 -0.085) :rot (0 18 -28) :seg 4 :c :ice)
    (:cone 0.018 0.15 :at (-0.028 0.203 -0.085) :rot (0 18 28) :seg 4 :c :ice)
    (:cone 0.016 0.12 :at (0.036 0.176 -0.085) :rot (0 18 -54) :seg 4 :c :ice)
    (:cone 0.016 0.12 :at (-0.036 0.176 -0.085) :rot (0 18 54) :seg 4 :c :ice)
    (:cone 0.013 0.09 :at (0.03 0.155 -0.085) :rot (0 18 -80) :seg 4 :c :ice)
    (:cone 0.013 0.09 :at (-0.03 0.155 -0.085) :rot (0 18 80) :seg 4 :c :ice)))

;; absolute zero (-273.15 C, the canon Bankai colouring on her own clothes): white hair and irises, the skin cold-shifted,
;; the half-crown of ice behind the head, crystals on the shoulders
(defparameter *ru-ice-ink* '((t . #x7F97B4))
  "The white Rukia's keyline (absolute zero, the Bankai; the user's decision 2026-09-28): ice blue on every shape instead of
the ink (the style's ICE keyline, docs/style/STYLE_STORM_DESIGN.md §2.4).")

(body-variant :rukia-zero :rukia :ink *ru-ice-ink* :clips '(:ru-q1 :ru-q1-z :ru-thrust :ru-thrust-z)
  :palette '((:hair #xE4E8EE) (:pupil #xDDE4EE) (:core #x9AA8BE) (:skin #xD6CCCA) (:fold #x9AA8BE) (:brow #xCFE3F2)
             (:lid #xCFE3F2))                   ; the lashes the brows' pale ice (playtest 2, 2026-09-28)
  :parts `((:head ,@*ru-crown*)
           (:shoulder-r (:cone 0.016 0.06 :at (0.05 0.04 0.01) :rot (0 0 -24) :seg 4 :c :ice)
                        (:cone 0.012 0.045 :at (0.02 0.04 -0.03) :rot (0 16 -8) :seg 4 :c :ice))
           (:shoulder-l (:cone 0.016 0.06 :at (-0.05 0.04 0.01) :rot (0 0 24) :seg 4 :c :ice)
                        (:cone 0.012 0.045 :at (-0.02 0.04 -0.03) :rot (0 16 8) :seg 4 :c :ice))))

;; 白霞罸 (the cinematic only, ch. 570 pp6-7): the ankle-length white kimono (black -> white), the ice collar standing
;; round the neck, the obi's ribbon loops and long tails at her back, an ice flower on the chest, the half-crown, white hair
(body-variant :rukia-bankai :rukia :ink *ru-ice-ink*
  :palette '((:black #xEEEEEA) (:hair #xE4E8EE) (:pupil #xDDE4EE) (:core #x9AA8BE) (:skin #xD6CCCA) (:fold #x9AA8BE)
             (:obi #x9AA8BE) (:brow #xCFE3F2) (:lid #xCFE3F2))
  :parts `((:pelvis (:cyl 0.2 0.9 :top 0.15 :seg 10 :at (0 -0.41 0) :c :black)                   ; the long skirt
                    (:box 0.2 0.1 0.03 :at (0.1 0.08 -0.17) :rot (0 30 -30) :c :ice)             ; the ribbon loops ...
                    (:box 0.2 0.1 0.03 :at (-0.1 0.08 -0.17) :rot (0 30 30) :c :ice)
                    (:box 0.06 0.62 0.02 :at (0.05 -0.28 -0.2) :rot (0 -8 -4) :c :ice)           ; ... and their tails
                    (:box 0.06 0.52 0.02 :at (-0.05 -0.23 -0.2) :rot (0 -8 5) :c :ice))
           (:chest (:cone 0.05 0.1 :at (0.07 0.28 -0.01) :rot (0 -10 -40) :seg 4 :c :ice)            ; the ice collar
                   (:cone 0.05 0.1 :at (-0.07 0.28 -0.01) :rot (0 -10 40) :seg 4 :c :ice)
                   (:cone 0.045 0.1 :at (0.03 0.3 -0.07) :rot (0 30 -15) :seg 4 :c :ice)
                   (:cone 0.045 0.1 :at (-0.03 0.3 -0.07) :rot (0 30 15) :seg 4 :c :ice)
                   (:cone 0.032 0.03 :at (0 0.12 0.14) :rot (0 90 0) :seg 6 :c :ice)             ; the ice flower
                   (:cone 0.018 0.05 :at (0.032 0.13 0.138) :rot (0 90 -60) :seg 4 :c :ice)
                   (:cone 0.018 0.05 :at (-0.032 0.13 0.138) :rot (0 90 60) :seg 4 :c :ice)
                   (:cone 0.018 0.05 :at (0 0.16 0.138) :rot (0 90 0) :seg 4 :c :ice))
           (:head ,@*ru-crown*)
           (:shoulder-r (:cone 0.03 0.1 :at (0.05 0.03 0) :rot (0 0 -30) :seg 4 :c :ice))
           (:shoulder-l (:cone 0.03 0.1 :at (-0.05 0.03 0) :rot (0 0 30) :seg 4 :c :ice))
           (:lower-arm-r (:cone 0.03 0.08 :at (0.04 -0.12 -0.04) :rot (0 -30 -50) :seg 4 :c :ice))
           (:lower-arm-l (:cone 0.03 0.08 :at (-0.04 -0.12 -0.04) :rot (0 -30 50) :seg 4 :c :ice))))

;;; ---------------------------------------------------------------- weapons
(defun ru-snow-guard (mb r c)
  "The hollow snowflake guard in the weapon frame (the XZ plane at the grip): a hexagonal ring of radius R, six short
points out of its corners, in colour C."
  (mbc mb c)
  (dotimes (i 6)
    (let ((a (* i (/ pi 3))))
      (with-xform (mb (xform :x (* r (cos a)) :z (* r (sin a)) :yaw (- (+ a (/ pi 2)))))    ; a side of the hexagon
        (mb-box mb (* 1.16 r) 0.01 0.011))
      (let ((b (+ a (/ pi 6))) (rr (* 1.12 r)))                                            ; a point off its corner
        (with-xform (mb (xform :x (* rr (cos b)) :z (* rr (sin b)) :yaw (- b) :roll (- (/ pi 2))))
          (mb-cone mb 0.006 0.022 :segments 4))))))

(defun ru-ribbon (mb n l bend twist w)
  "A ribbon of N segments L long hanging on from the pommel (the weapon frame's -Y), curling toward the spine by BEND
and turning by TWIST (radians) at each segment: static geometry, short enough never to poke far out of a pose."
  (when (plusp n)
    (with-xform (mb (xform :y (* -0.5 l))) (mb-box mb 0.004 l w))
    (with-xform (mb (xform :y (- l) :pitch bend :yaw twist)) (ru-ribbon mb (1- n) l bend twist w))))

(defweapon :ru-katana (:length 0.86)                   ; sealed: a plain katana (the intro only)
  (:solid (mb-blade mb :width 0.03 :guard-color '(0.3 0.3 0.32) :handle-color '(0.08 0.07 0.08) :wrap-color '(0.2 0.2 0.24) :blade nil))
  (:solid :ink 0 (mb-blade mb :length 0.8 :width 0.03 :curve 0.012 :blade-color '(0.6 0.62 0.66) :edge-color '(0.86 0.88 0.9) :hilt nil)))

;; Sode no Shirayuki: blade, hilt and guard pure white; the guard a hollow snowflake ring; a long white ribbon from the
;; pommel, curling back behind the fist
(defweapon :sode-no-shirayuki (:length 0.9)
  (:solid :ink 0 (mb-blade mb :length 0.84 :width 0.032 :curve 0.01 :blade-color '(0.94 0.95 0.97) :edge-color '(1.0 1.0 1.0) :hilt nil))
  (:solid (mbc mb #xECEEF2)                            ; the white hilt, its wrap in the cold shade, the pommel cap
          (with-xform (mb (xform :y -0.1)) (mb-bevel-box mb 0.026 0.2 0.032 0.006))
          (with-xform (mb (xform :y 0.02)) (mb-box mb 0.014 0.03 0.036))
          (with-xform (mb (xform :y -0.206)) (mb-bevel-box mb 0.03 0.016 0.036 0.004))
          (mbc mb #x9AA8BE)
          (loop for i below 4 do (with-xform (mb (xform :y (- -0.035 (* i 0.045)) :roll 0.785)) (mb-box mb 0.02 0.02 0.034)))
          (ru-snow-guard mb 0.042 #xF4F6F8))
  (:solid :ink 0.6 (mbc mb #xF4F6F8)                   ; the ribbon: a long curl and a short one
          (with-xform (mb (xform :y -0.212 :z -0.006)) (ru-ribbon mb 8 0.05 0.17 0.07 0.026))
          (with-xform (mb (xform :y -0.212 :z 0.006 :yaw 0.5)) (ru-ribbon mb 5 0.05 0.24 -0.1 0.02))))

;; -50 C: Sode no Shirayuki rimed: the white blade with an ice edge grown along it, the guard frosted
(defweapon :ru-rime (:length 1.0)
  (:solid :ink 0 (mb-blade mb :length 0.9 :width 0.036 :curve 0.01 :blade-color '(0.9 0.93 0.97) :edge-color '(0.78 0.86 0.96) :hilt nil))
  (:solid (mbc mb #xECEEF2)
          (with-xform (mb (xform :y -0.1)) (mb-bevel-box mb 0.026 0.2 0.032 0.006))
          (with-xform (mb (xform :y 0.02)) (mb-box mb 0.014 0.03 0.036))
          (with-xform (mb (xform :y -0.206)) (mb-bevel-box mb 0.03 0.016 0.036 0.004))
          (mbc mb #x9AA8BE)
          (loop for i below 4 do (with-xform (mb (xform :y (- -0.035 (* i 0.045)) :roll 0.785)) (mb-box mb 0.02 0.02 0.034)))
          (ru-snow-guard mb 0.046 #xE6ECF4))
  (:solid :ink 0.6 (mbc mb #xE6ECF4)                   ; ice crystals along the back of the blade, the ribbon stiff with frost
          (loop for i below 4 do (with-xform (mb (xform :y (+ 0.2 (* i 0.17)) :z -0.02 :pitch 0.5)) (mb-cone mb 0.008 0.05 :segments 4)))
          (with-xform (mb (xform :y -0.212 :z -0.006)) (ru-ribbon mb 7 0.05 0.12 0.05 0.026))))

;; the Bankai's ice blade (the 白霞罸 cinematic, and absolute zero in play): pale ice, a white core line, the snowflake ring in ice, an ice hilt
(defweapon :ru-ice (:length 1.0)
  (:solid :ink 0 (mb-blade mb :length 0.96 :width 0.04 :curve 0.008 :blade-color '(0.86 0.9 0.95) :edge-color '(1.0 1.0 1.0) :hilt nil))
  (:solid (mbc mb #xE6ECF4)
          (with-xform (mb (xform :y -0.1)) (mb-bevel-box mb 0.028 0.2 0.034 0.006))
          (with-xform (mb (xform :y -0.215)) (mb-cone mb 0.02 0.05 :segments 4))
          (ru-snow-guard mb 0.05 #xE6ECF4))
  (:solid :ink 0.6 (mbc mb #xE6ECF4)
          (with-xform (mb (xform :y -0.22 :z -0.006)) (ru-ribbon mb 7 0.05 0.2 0.08 0.024))))

;;; ---------------------------------------------------------------- poses
;;; Her rig notes: the right side leads (a fencer's stance: the right foot forward, the body turned left, the head turned
;;; back to him); the blade is one-handed and runs on from the arm (hand flex ~ -90); a horizontal cut is the arm held out
;;; (side ~88) swept by its flex (0 = to her right, 90 = ahead, 130 = ahead-left); the free left arm dances (out and back
;;; in the cuts, forward in the kido and the bare-hand links). Hit poses (DEFSTRIKE :s) put the blade or the palm where
;;; the move's volume is (rukia.lisp: its reach, arc and line).
(defpose :ru-stance ()                                 ; Shikai: light on the balls of the feet, the white blade low forward
  (:root :u -0.045) (:pelvis :twist 28) (:spine :flex 8) (:chest :twist 6) (:neck :twist -14) (:head :flex -6 :twist -16)
  (:arm-r :flex 34 :side 14) (:elbow-r :flex 22) (:hand-r :twist -10 :flex -66)
  (:arm-l :flex 34 :side 40) (:elbow-l :flex 70) (:hand-l :flex -20)
  (:thigh-r :flex 24 :side 6) (:thigh-l :flex -14 :side 10) (:knee-r :flex 22) (:knee-l :flex 18))

(defclip :ru-stance (1.8 :loop t :base :ru-stance)    ; a light bounce; the point breathes
  (0) (0.9 (:root :u -0.058) (:chest :flex 2) (:hand-r :flex -62) (:elbow-l :flex 74)))

(defpose :ru-cold-stance ()                            ; the cold body: lower and stiller, the blade reversed back along the
  (:root :u -0.1) (:pelvis :twist 18) (:spine :flex 12) (:chest :twist -16) (:neck :twist 8) (:head :flex -8 :twist -2)
  (:arm-r :flex -12 :side 24) (:elbow-r :flex 30) (:hand-r :twist 160 :flex 20)                  ; forearm, the bare left
  (:arm-l :flex 58 :side 10) (:elbow-l :flex 30) (:hand-l :flex -40)                             ; palm open ahead
  (:thigh-r :flex 30 :side 8) (:thigh-l :flex -18 :side 12) (:knee-r :flex 38) (:knee-l :flex 16))

(defclip :ru-cold-stance (2.6 :loop t :base :ru-cold-stance)
  (0) (1.3 (:root :u -0.107) (:elbow-l :flex 33)))

(defpose :ru-zero-pose ()                              ; absolute zero: still, upright, the point down, the head a little bowed
  (:root :u -0.015) (:pelvis :twist 10) (:spine :flex 2) (:chest :twist -4) (:neck :twist -4) (:head :flex 12)
  (:arm-r :flex 14 :side 12) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -80)
  (:arm-l :flex 6 :side 8) (:elbow-l :flex 14) (:hand-l :flex -10)
  (:thigh-r :flex 6 :side 5) (:thigh-l :flex -2 :side 6) (:knee-r :flex 6) (:knee-l :flex 4))

(defclip :ru-zero (4.0 :loop t :base :ru-zero-pose) (0) (2.0 (:root :u -0.02) (:head :flex 13)))

;;; ---------------------------------------------------------------- the Shikai grid (§3.2)
(defpose :ru-q1-hit (:base :ru-stance)                 ; J1 HATSUSHIMO: the flat one-handed cut through, the left arm flung back
  (:root :f 0.32 :u -0.13 :yaw 4) (:pelvis :twist 24) (:spine :flex 10) (:chest :twist 12) (:neck :twist -10) (:head :twist -10)
  (:arm-r :side 88 :flex 94) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -86)
  (:arm-l :flex -30 :side 62) (:elbow-l :flex 20) (:hand-l :flex -30)
  (:thigh-r :flex 46 :side 4) (:knee-r :flex 46) (:thigh-l :flex -26) (:knee-l :flex 20))
(defstrike :ru-q1 (7 3 12 :base :ru-stance)
  (0)
  (3 (:root :u -0.07 :yaw -10) (:chest :twist -34) (:neck :twist 10) (:head :twist -6) (:arm-r :side 88 :flex -12) (:elbow-r :flex 16)
     (:hand-r :twist 0 :flex -84) (:arm-l :flex 40 :side 30) (:elbow-l :flex 60) (:knee-r :flex 30))
  (:s :snap :ru-q1-hit)
  (8 (:chest :twist 18) (:arm-r :flex 100) (:root :f 0.34))
  (:a (:chest :twist 16) (:arm-r :flex 98) (:root :f 0.34))
  (16 (:chest :twist 14) (:arm-r :side 50 :flex 70) (:elbow-r :flex 20) (:hand-r :flex -70) (:root :f 0.1 :u -0.1 :yaw 2)
      (:arm-l :flex 10 :side 50) (:elbow-l :flex 50))
  (:end :ru-stance))

(defpose :ru-q2-hit (:base :ru-stance)                 ; J2 KAZAHANA: the wrist turned over, the backhand back along the line
  (:root :f 0.02 :u -0.11 :yaw -6) (:pelvis :twist 24) (:spine :flex 8 :side 6) (:chest :twist -14) (:neck :twist 0) (:head :twist -4)
  (:arm-r :side 88 :flex 42) (:elbow-r :flex 20 :twist 160) (:hand-r :twist 0 :flex -86)
  (:arm-l :flex 50 :side 56) (:elbow-l :flex 30) (:hand-l :flex -30)
  (:thigh-r :flex 38) (:knee-r :flex 40) (:thigh-l :flex -22) (:knee-l :flex 22))
(defstrike :ru-q2 (7 3 13 :base :ru-stance)
  (0)
  (3 (:root :u -0.08 :yaw 8) (:chest :twist 26) (:neck :twist -20) (:head :twist -16) (:arm-r :side 88 :flex 128) (:elbow-r :flex 20 :twist 160)
     (:hand-r :twist 0 :flex -80) (:arm-l :flex -20 :side 50) (:elbow-l :flex 30))
  (:s :snap :ru-q2-hit)
  (8 (:chest :twist -18) (:arm-r :flex 36) (:root :f 0.04))
  (:a (:chest :twist -17) (:arm-r :flex 38) (:root :f 0.03))
  (17 (:chest :twist -4) (:arm-r :side 40 :flex 40) (:elbow-r :flex 24 :twist 40) (:hand-r :twist 0 :flex -60) (:root :f 0.02 :u -0.07)
      (:arm-l :flex 30 :side 44) (:elbow-l :flex 60))
  (:end :ru-stance))

(defstrike :ru-spin (8 3 18 :base :ru-stance)          ; J3 MAI-SODE: the pirouette on the ball of the foot, the blade and the
  (0)                                                  ; left arm out wide, the rear leg drawn up: "the dance"
  (4 (:root :u -0.1 :yaw -16) (:knees :flex 36) (:chest :twist -30) (:neck :twist 14) (:arm-r :side 88 :flex -6) (:elbow-r :flex 4)
     (:hand-r :twist 0 :flex -88) (:arm-l :side 70 :flex 30) (:elbow-l :flex 20) (:head :flex -4))
  (6 (:root :u -0.12 :yaw -26) (:chest :twist -36))
  (:s :snap (:root :yaw 360 :u -0.01 :f 0.22) (:pelvis :twist 20) (:chest :twist 10) (:neck :twist -10) (:head :twist -10 :flex 4)
      (:arm-r :side 88 :flex 26) (:elbow-r :flex 10) (:hand-r :flex -88) (:arm-l :side 86 :flex 24) (:elbow-l :flex 10)
      (:thigh-r :flex 6) (:knee-r :flex 8) (:thigh-l :flex 26 :side 14) (:knee-l :flex 84))
  (:a (:root :yaw 382 :u -0.02 :f 0.24) (:chest :twist 14))
  (22 (:root :yaw 372 :u -0.07 :f 0.2) (:chest :twist 10) (:arm-r :side 50 :flex 30) (:elbow-r :flex 24) (:hand-r :flex -60)
      (:arm-l :side 50 :flex 40) (:elbow-l :flex 40) (:thigh-l :flex -6) (:knee-l :flex 24) (:thigh-r :flex 20) (:knee-r :flex 24))
  (:end :ru-stance (:root :yaw 360)))

(defpose :ru-thrust-hit (:base :ru-stance)             ; K1 SHIMO-TSUKI: the fencer's lunge, the rear arm flung up behind
  (:root :f 0.46 :u -0.2 :yaw -4) (:pelvis :twist 18) (:spine :flex 12) (:chest :twist 6) (:neck :twist -26) (:head :flex -8 :twist -20)
  (:arm-r :flex 98 :side 2) (:elbow-r :flex 0) (:hand-r :twist -20 :flex -88)
  (:arm-l :flex -50 :side 50) (:elbow-l :flex 30) (:hand-l :flex -40)
  (:thigh-r :flex 66 :side 4) (:knee-r :flex 64) (:thigh-l :flex -34 :side 8) (:knee-l :flex 6))
(defstrike :ru-thrust (17 4 20 :base :ru-stance)
  (0)
  (6 (:root :u -0.09 :f -0.04) (:chest :twist -20) (:neck :twist 6) (:arm-r :flex 10 :side 10) (:elbow-r :flex 120)
     (:hand-r :twist -10 :flex -70) (:arm-l :flex 56 :side 20) (:elbow-l :flex 20) (:knees :flex 32))
  (14 (:root :u -0.11 :f -0.06) (:chest :twist -24) (:arm-r :flex 6) (:elbow-r :flex 126) (:arm-l :flex 60))
  (:s :snap :ru-thrust-hit)
  (18 (:root :f 0.5) (:arm-r :flex 100))
  (:a (:root :f 0.49) (:arm-r :flex 99))
  (32 (:root :f 0.26 :u -0.12) (:arm-r :flex 50 :side 12) (:elbow-r :flex 24) (:hand-r :twist -10 :flex -66) (:thigh-r :flex 40)
      (:knee-r :flex 40) (:arm-l :flex 10 :side 40) (:elbow-l :flex 50))
  (:end :ru-stance))

(defpose :ru-ring-hit (:base :ru-stance)               ; K2 HYORIN: out of the turn, the blade swept up before her
  (:root :u 0.02 :f 0.18) (:pelvis :twist 18) (:spine :flex -10) (:chest :twist 14) (:neck :twist -12) (:head :flex -20 :twist -10)
  (:arm-r :flex 124 :side 12) (:elbow-r :flex 4) (:hand-r :twist -10 :flex -84)
  (:arm-l :flex 10 :side 76) (:elbow-l :flex 10)
  (:thigh-r :flex 22) (:knee-r :flex 16) (:thigh-l :flex -10) (:knee-l :flex 4))
(defstrike :ru-ring (21 4 24 :base :ru-stance)
  (0)
  (10 (:root :u -0.15 :yaw -120) (:pelvis :twist 10) (:chest :twist -10) (:spine :flex 26) (:neck :twist 24) (:head :flex 6 :twist 30)
      (:arm-r :flex -24 :side 30) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -70) (:arm-l :flex 40 :side 40) (:elbow-l :flex 40)
      (:knees :flex 52) (:thighs :flex 30))
  (18 (:root :u -0.17 :yaw -136) (:spine :flex 28) (:arm-r :flex -30) (:knees :flex 56))
  (:s :snap :ru-ring-hit)
  (23 (:arm-r :flex 132) (:root :u 0.03))
  (:a (:arm-r :flex 130) (:root :u 0.03))
  (38 (:root :u -0.04 :f 0.1) (:spine :flex 4) (:arm-r :flex 90 :side 16) (:elbow-r :flex 20) (:hand-r :flex -66) (:head :flex -8)
      (:arm-l :flex 30 :side 50) (:elbow-l :flex 50) (:knees :flex 22))
  (:end :ru-stance))

(defpose :ru-drop-hit (:base :ru-stance)               ; K3 NADARE: both hands, dropped from high through him, a deep step
  (:root :u -0.2 :f 0.36 :yaw -2) (:pelvis :twist 10) (:spine :flex 30) (:chest :twist 0) (:neck :twist -6) (:head :flex -20 :twist -6)
  (:arm-r :flex 96 :side 0) (:elbow-r :flex 6) (:hand-r :twist -10 :flex -72)
  (:arm-l :flex 94 :side -12) (:elbow-l :flex 16) (:hand-l :flex -30)
  (:thigh-r :flex 58 :side 6) (:knee-r :flex 60) (:thigh-l :flex -24 :side 8) (:knee-l :flex 24))
(defstrike :ru-drop (21 5 34 :base :ru-stance)
  (0)
  (8 (:root :u 0.03) (:pelvis :twist 14) (:chest :twist 0) (:neck :twist -6) (:arm-r :flex 176 :side 6) (:elbow-r :flex 12)
     (:hand-r :twist -5 :flex -40) (:arm-l :flex 168 :side -14) (:elbow-l :flex 24) (:spine :flex -12) (:head :flex -30)
     (:thigh-r :flex 14) (:knee-r :flex 12) (:thigh-l :flex -6) (:knee-l :flex 8))
  (17 (:root :u 0.04) (:arm-r :flex 180) (:arm-l :flex 172) (:spine :flex -15))
  (:s :snap :ru-drop-hit)
  (23 (:spine :flex 38) (:root :u -0.24 :f 0.38) (:arm-r :flex 52) (:arm-l :flex 50))
  (:a (:spine :flex 36) (:root :u -0.23 :f 0.38) (:arm-r :flex 54) (:arm-l :flex 52))
  (44 (:spine :flex 30) (:root :u -0.2 :f 0.34))
  (52 (:spine :flex 12) (:root :u -0.09 :f 0.14) (:arm-r :flex 40 :side 14) (:elbow-r :flex 24) (:hand-r :flex -64)
      (:arm-l :flex 30 :side 30) (:elbow-l :flex 60) (:thigh-r :flex 34) (:knee-r :flex 32) (:head :flex -10))
  (:end :ru-stance))
(pushnew :ru-drop *grip-clips*)                        ; the two-handed drop: the left fist held on the handle

;;; ---------------------------------------------------------------- the rest of the Shikai (§3.3)
(defstrike :ru-tsukishiro (10 0 26 :base :ru-stance)   ; L TSUKISHIRO: low, the point on the plaza drawn round in one sweep,
  (0)                                                  ; the body turning with it, the left arm out for the balance
  (4 (:root :u -0.16 :yaw -10) (:knees :flex 52) (:thighs :flex 20) (:spine :flex 24) (:chest :twist -20) (:neck :twist 10)
     (:head :flex 16) (:arm-r :side 44 :flex 30) (:elbow-r :flex 4) (:hand-r :twist 0 :flex -86) (:arm-l :side 70 :flex 10)
     (:elbow-l :flex 20))
  (:s :snap (:root :u -0.2 :yaw 150) (:arm-r :side 46 :flex 34) (:spine :flex 26) (:knees :flex 56))
  (24 (:root :u -0.19 :yaw 350) (:arm-r :side 44 :flex 36))
  (32 (:root :u -0.1 :yaw 360) (:spine :flex 10) (:arm-r :side 30 :flex 30) (:elbow-r :flex 26) (:hand-r :flex -60) (:knees :flex 30)
      (:thighs :flex 10))
  (:end :ru-stance (:root :yaw 360)))

(defpose :ru-stab-pose (:base :ru-stance)              ; SP1's hold (and HYOSHIN): the point driven into the plaza before her
  (:root :u -0.2) (:pelvis :twist 16) (:knees :flex 64) (:thighs :flex 40) (:spine :flex 36) (:chest :twist 0) (:neck :twist -6)
  (:head :flex 14) (:arm-r :flex 56 :side 6) (:elbow-r :flex 30) (:hand-r :twist 160 :flex 10)
  (:arm-l :flex 16 :side 46) (:elbow-l :flex 30) (:hand-l :flex -30))
(defclip :ru-stab (0.27 :loop t :base :ru-stab-pose)   ; stab, lift, stab: one stab per 16 f
  (0 :snap (:arm-r :flex 50) (:root :u -0.21))
  (0.1 (:arm-r :flex 72) (:elbow-r :flex 44) (:root :u -0.18))
  (0.2 (:arm-r :flex 64) (:root :u -0.19)))

(defpose :ru-hakuren-hit (:base :ru-stab-pose)         ; SP1 release: the blade swept up out of the plaza, the cold off the tip
  (:root :u -0.02 :f 0.2) (:knees :flex 22) (:thighs :flex 10) (:spine :flex -8) (:arm-r :flex 126 :side 12) (:elbow-r :flex 4)
  (:hand-r :twist -10 :flex -84) (:head :flex -16) (:arm-l :side 70 :flex -10) (:elbow-l :flex 10))
(defstrike :ru-hakuren (6 1 24 :base :ru-stance)
  (0 :ru-stab-pose)
  (:s :snap :ru-hakuren-hit)
  (:a (:arm-r :flex 130))
  (20 (:arm-r :flex 100 :side 18) (:elbow-r :flex 20) (:hand-r :flex -60) (:spine :flex 4) (:knees :flex 26) (:root :u -0.06 :f 0.1))
  (:end :ru-stance))

(defpose :ru-shirafune-hit (:base :ru-thrust-hit)      ; SP2 SHIRAFUNE: the deepest one-handed thrust, the rear leg straight
  (:root :f 0.66 :u -0.27) (:spine :flex 16) (:chest :twist 8) (:thigh-r :flex 78) (:knee-r :flex 80) (:thigh-l :flex -44)
  (:knee-l :flex 2) (:arm-r :flex 102) (:arm-l :flex -60 :side 40))
(defstrike :ru-shirafune (16 4 28 :base :ru-stance)
  (0)
  (7 (:root :u -0.12 :f -0.06) (:chest :twist -26) (:neck :twist 10) (:arm-r :flex 6 :side 10) (:elbow-r :flex 124)
     (:hand-r :twist -10 :flex -70) (:arm-l :flex 60 :side 16) (:elbow-l :flex 16) (:knees :flex 40))
  (13 (:root :u -0.14 :f -0.08) (:chest :twist -30) (:arm-r :flex 2) (:elbow-r :flex 130))
  (:s :snap :ru-shirafune-hit)
  (:a (:root :f 0.7) (:arm-r :flex 103))
  (36 (:root :f 0.5 :u -0.22))
  (44 (:root :f 0.2 :u -0.1) (:arm-r :flex 44 :side 14) (:elbow-r :flex 26) (:hand-r :twist -10 :flex -64) (:thigh-r :flex 36)
      (:knee-r :flex 36) (:thigh-l :flex -18) (:knee-l :flex 18) (:arm-l :flex 20 :side 40) (:elbow-l :flex 50))
  (:end :ru-stance))

(defclip :ru-breaker (0.4 :loop t :base :ru-stance)    ; the Breaker's dash: low, the blade trailing behind, the left hand ahead
  (0 (:root :u -0.1) (:pelvis :twist 10) (:spine :flex 34) (:chest :twist -6) (:neck :twist 0) (:head :flex -28 :twist 0)
     (:arm-r :flex -40 :side 26) (:elbow-r :flex 16) (:hand-r :twist 0 :flex -100)
     (:arm-l :flex 64 :side 10) (:elbow-l :flex 36)
     (:thigh-r :flex 45) (:knee-r :flex 20) (:thigh-l :flex -30) (:knee-l :flex 45))
  (0.2 (:root :u -0.06) (:thigh-l :flex 45) (:knee-l :flex 20) (:thigh-r :flex -30) (:knee-r :flex 45)))

(defpose :ru-hainawa-hit (:base :ru-stance)            ; I HAINAWA: the left hand snaps forward, two fingers pointed; the blade
  (:root :f 0.34 :u -0.12) (:pelvis :twist 0) (:spine :flex 10) (:chest :twist -26) (:neck :twist 14) (:head :flex -6 :twist 12)
  (:arm-l :flex 96 :side 2) (:elbow-l :flex 0) (:hand-l :flex -80)                             ; held back behind her
  (:arm-r :flex -34 :side 30) (:elbow-r :flex 20) (:hand-r :twist 0 :flex -96)
  (:thigh-r :flex 44) (:knee-r :flex 42) (:thigh-l :flex -20) (:knee-l :flex 16))
(defstrike :ru-hainawa (8 4 18 :base :ru-stance)
  (0 (:arm-l :flex 30 :side 20) (:elbow-l :flex 110) (:chest :twist 16) (:root :u -0.1))
  (5 (:arm-l :flex 26) (:elbow-l :flex 122) (:chest :twist 20) (:root :u -0.11))
  (:s :snap :ru-hainawa-hit)
  (:a (:root :f 0.36) (:arm-l :flex 97))
  (24 (:arm-l :flex 44 :side 26) (:elbow-l :flex 50) (:chest :twist -4) (:root :f 0.14 :u -0.08))
  (:end :ru-stance))

;;; ---------------------------------------------------------------- cinematics / intro / win (§5, §6)
(defclip :ru-kikon (2.0 :base :ru-stance)              ; ENBU's Kikon: the pirouette ending; held as a dancer (the card's
  (0 (:root :yaw 384 :u -0.02 :f 0.3) (:pelvis :twist 20) (:chest :twist 14) (:neck :twist -10) (:head :twist -10)   ; silhouette:
     (:arm-r :side 88 :flex 30) (:elbow-r :flex 0) (:hand-r :twist 0 :flex -88)                ; the blade out, the left arm
     (:arm-l :side 86 :flex 24) (:elbow-l :flex 10) (:thigh-l :flex 26 :side 14) (:knee-l :flex 84)      ; up, a foot drawn up)
     (:thigh-r :flex 6) (:knee-r :flex 8))
  (0.2 (:root :yaw 366) (:arm-l :side 150 :flex 16) (:elbow-l :flex 36) (:hand-l :flex -20) (:head :flex -8))
  (0.95 (:root :yaw 362 :u -0.03) (:arm-l :side 154) (:head :flex -10))
  (1.2 (:root :u -0.16 :yaw 360 :f 0.2) (:knees :flex 56) (:thighs :flex 22) (:spine :flex 24) (:chest :twist -20)   ; then low,
       (:neck :twist 10) (:head :flex 16) (:arm-r :side 44 :flex 30) (:hand-r :flex -86) (:arm-l :side 70 :flex 10)  ; the point
       (:elbow-l :flex 20) (:thigh-l :flex 20 :side 8) (:knee-l :flex 56))                     ; on the plaza drawn round
  (1.7 (:root :u -0.17 :yaw 700 :f 0.2) (:arm-r :flex 30))
  (2.0 (:root :u -0.06 :yaw 720 :f 0.1) (:knees :flex 20) (:thighs :flex 6) (:spine :flex 6) (:chest :twist 0) (:head :flex 0)
       (:arm-r :side 20 :flex 16) (:elbow-r :flex 10) (:hand-r :flex -70) (:arm-l :side 14 :flex 10) (:elbow-l :flex 20)
       (:thigh-l :flex -8) (:knee-l :flex 14)))

(defclip :ru-intro (2.0 :base :ru-stance)              ; the sealed katana held out before her and turned counter-clockwise
  (0 (:root :u -0.01) (:pelvis :twist 16) (:chest :twist 4) (:neck :twist -10) (:head :flex -4 :twist -10)   ; (her view) a full
     (:arm-r :flex 60 :side 6) (:elbow-r :flex 30) (:hand-r :twist 0 :flex -20) (:arm-l :flex 10 :side 12)    ; turn; white at the
     (:elbow-l :flex 20) (:thigh-r :flex 10) (:thigh-l :flex -6) (:knees :flex 6))                           ; release (f70)
  (0.35 (:arm-r :flex 84 :side 4) (:elbow-r :flex 6) (:hand-r :twist 0 :flex 0))
  (0.55 (:hand-r :twist 90))
  (0.75 (:hand-r :twist 180))
  (0.95 (:hand-r :twist 270))
  (1.12 (:hand-r :twist 350))
  (1.17 :snap (:arm-r :flex 70 :side 20) (:hand-r :twist 360 :flex -80) (:chest :twist 14) (:head :flex -8)
        (:arm-l :flex 20 :side 40) (:elbow-l :flex 40))
  (1.5 (:arm-r :flex 50 :side 16) (:hand-r :twist 356 :flex -70))
  (2.0 :ru-stance (:hand-r :twist 350)))

(defclip :ru-win (2.0 :base :ru-stance)                ; a flick of the blade, then lowered at her side, turned half away
  (0)
  (0.25 (:arm-r :side 60 :flex 30) (:elbow-r :flex 4) (:hand-r :flex -86) (:chest :twist -10))
  (0.4 :snap (:arm-r :side 30 :flex -10) (:hand-r :flex -80) (:chest :twist 4))
  (0.9 (:root :u -0.005 :yaw 20) (:pelvis :twist 10) (:spine :flex 2) (:chest :twist 0) (:neck :twist -10) (:head :flex 6 :twist -20)
       (:arm-r :flex 12 :side 14) (:elbow-r :flex 6) (:hand-r :twist 0 :flex -84) (:arm-l :flex 30 :side 6) (:elbow-l :flex 96)
       (:hand-l :flex -10) (:thigh-r :flex 4) (:thigh-l :flex -4) (:knees :flex 4))
  (2.0 (:root :u -0.005 :yaw 20) (:head :flex 8 :twist -22)))

(defclip :ru-hand (2.0 :base :ru-zero-pose)            ; 白霞罸's last shot: her right hand on the hilt before her, the back of
  (0 (:arm-r :flex 60 :side -20) (:elbow-r :flex 90) (:hand-r :twist -175 :flex 20) (:head :flex 24) (:spine :flex 6))  ; the fist
  (0.6 (:arm-r :flex 56) (:elbow-r :flex 86) (:hand-r :flex 16))                                  ; (the crack) turned to the
  (2.0 (:arm-r :flex 34 :side -10) (:elbow-r :flex 60) (:hand-r :twist -170 :flex -10) (:head :flex 20)))   ; lens; lowered

(defclip :ru-awaken (2.0 :base :ru-zero-pose)          ; 絶対零度: the blade lowered, point down, the head bowing, the eyes closing
  (0 (:head :flex 0) (:arm-r :flex 30 :side 14) (:hand-r :flex -60))
  (0.6 (:head :flex 12) (:root :u -0.02) (:arm-r :flex 16) (:hand-r :flex -76) (:arm-l :flex 24 :side 4) (:elbow-l :flex 80))
  (2.0 (:head :flex 16) (:root :u -0.025) (:arm-r :flex 14) (:hand-r :flex -80) (:arm-l :flex 26 :side 4) (:elbow-l :flex 84)))

;;; ---------------------------------------------------------------- the awakened moves (§4.2; the user's decision: 2 new links)
(defpose :ru-palm-hit (:base :ru-cold-stance)          ; K1 TOSHU: the bare left palm driven out, catching; the blade kept back
  (:root :f 0.44 :u -0.16) (:pelvis :twist -4) (:spine :flex 12) (:chest :twist -30) (:neck :twist 18) (:head :flex -6 :twist 14)
  (:arm-l :flex 98 :side 0) (:elbow-l :flex 2) (:hand-l :flex -70)
  (:arm-r :flex -26 :side 30) (:elbow-r :flex 30) (:hand-r :twist 160 :flex 20)
  (:thigh-r :flex 50) (:knee-r :flex 48) (:thigh-l :flex -26) (:knee-l :flex 12))
(defstrike :ru-palm (17 4 20 :base :ru-cold-stance)
  (0)
  (8 (:arm-l :flex 34 :side 30) (:elbow-l :flex 110) (:hand-l :flex -20) (:chest :twist 14) (:neck :twist -8) (:root :u -0.16)
     (:knees :flex 42))
  (15 (:arm-l :flex 30) (:elbow-l :flex 120) (:chest :twist 18) (:root :u -0.17))
  (:s :snap :ru-palm-hit)
  (:a (:root :f 0.46) (:arm-l :flex 99))
  (32 (:root :f 0.24 :u -0.11) (:arm-l :flex 60 :side 10) (:elbow-l :flex 30) (:chest :twist -20) (:thigh-r :flex 36) (:knee-r :flex 40))
  (:end :ru-cold-stance))

(defpose :ru-flower-hit (:base :ru-cold-stance)        ; K3 HYOKA: down on one knee, the palm driven flat into the plaza
  (:root :u -0.5 :f 0.26) (:pelvis :twist 0) (:spine :flex 46) (:chest :twist -16) (:neck :twist 10) (:head :flex -16 :twist 6)
  (:arm-l :flex 36 :side 4) (:elbow-l :flex 0) (:hand-l :flex 50)
  (:arm-r :flex -30 :side 40) (:elbow-r :flex 26) (:hand-r :twist 160 :flex 20)
  (:thigh-r :flex 74) (:knee-r :flex 116) (:thigh-l :flex -4 :side 12) (:knee-l :flex 100))
(defstrike :ru-flower (21 5 34 :base :ru-cold-stance)
  (0)
  (8 (:root :u 0.02) (:arm-l :flex 160 :side 10) (:elbow-l :flex 16) (:hand-l :flex -30) (:spine :flex -8) (:chest :twist 10)
     (:head :flex -24) (:thigh-r :flex 20) (:knee-r :flex 16) (:thigh-l :flex -10) (:knee-l :flex 10))
  (17 (:root :u 0.03) (:arm-l :flex 168) (:spine :flex -11))
  (:s :snap :ru-flower-hit)
  (:a (:root :u -0.51) (:spine :flex 48))
  (46 (:root :u -0.49 :f 0.26))
  (54 (:root :u -0.2 :f 0.12) (:spine :flex 22) (:arm-l :flex 44 :side 10) (:elbow-l :flex 30) (:hand-l :flex -30) (:thigh-r :flex 50)
      (:knee-r :flex 60) (:thigh-l :flex -10) (:knee-l :flex 50))
  (:end :ru-cold-stance))

(defstrike :ru-reido (6 0 26 :base :ru-zero-pose)      ; REIDO TOKETSU: the eyes open, the left palm swept out low, a burst
  (0)
  (3 (:arm-l :flex 40 :side -24) (:elbow-l :flex 50) (:root :u -0.05) (:chest :twist 20))
  (:s :snap (:arm-l :flex 24 :side 58) (:elbow-l :flex 0) (:hand-l :flex -40) (:root :u -0.08) (:knees :flex 28) (:thighs :flex 12)
      (:spine :flex 14) (:chest :twist -16) (:neck :twist 8) (:head :flex -6) (:hand-r :flex -60))
  (18 (:arm-l :flex 22 :side 56) (:root :u -0.075))
  (:end :ru-cold-stance))

(defpose :ru-hakka-hit (:base :ru-cold-stance)         ; HAKKA: the blade levelled at him, the cold running off the tip
  (:root :u -0.1 :f 0.22) (:pelvis :twist 14) (:spine :flex 6) (:chest :twist 2) (:neck :twist -20) (:head :flex -8 :twist -16)
  (:arm-r :flex 98 :side 2) (:elbow-r :flex 0) (:hand-r :twist 0 :flex -88)
  (:arm-l :flex 20 :side 40) (:elbow-l :flex 40) (:hand-l :flex -30)
  (:thigh-r :flex 36) (:knee-r :flex 40))
(defstrike :ru-hakka (20 3 30 :base :ru-cold-stance)
  (0)
  (4 (:root :u 0.0) (:pelvis :twist 14) (:chest :twist 0) (:neck :twist -6) (:arm-r :flex 176 :side 4) (:elbow-r :flex 4)
     (:hand-r :twist 0 :flex -86) (:spine :flex -8) (:head :flex -26) (:arm-l :flex 10 :side 20) (:elbow-l :flex 20)
     (:thigh-r :flex 10) (:knee-r :flex 10) (:thigh-l :flex -6) (:knee-l :flex 8))
  (16 (:arm-r :flex 180) (:root :u 0.01))
  (:s :snap :ru-hakka-hit)
  (:a (:root :f 0.24))
  (40 (:root :f 0.18 :u -0.1) (:arm-r :flex 60 :side 10) (:elbow-r :flex 20) (:hand-r :twist 60 :flex -40))
  (:end :ru-cold-stance))

;;; ---------------------------------------------------------------- the colder bands' motions (key edits, §4.2 / §4.3)
;; -50 C: TOSHU with the blade driven in beside the palm; MAI-SODE two-handed and low; HYOKA with both palms; the quake
;; with both hands on the hilt. Zero: J1 and the thrust with the feet pinned (rooted: the ice reaches, she doesn't step)
(defpose :ru-palm-50-hit (:base :ru-palm-hit)
  (:arm-r :flex 70 :side 10) (:elbow-r :flex 10) (:hand-r :twist 0 :flex -80) (:chest :twist -20) (:root :u -0.2))
(defstrike :ru-palm-50 (17 4 20 :base :ru-cold-stance)
  (0)
  (8 (:arm-l :flex 34 :side 30) (:elbow-l :flex 110) (:arm-r :flex 20 :side 20) (:elbow-r :flex 90) (:chest :twist 14)
     (:root :u -0.18) (:knees :flex 46))
  (15 (:arm-l :flex 30) (:elbow-l :flex 120) (:arm-r :flex 16) (:chest :twist 18) (:root :u -0.19))
  (:s :snap :ru-palm-50-hit)
  (:a (:root :f 0.46) (:arm-l :flex 99) (:arm-r :flex 72))
  (32 (:root :f 0.24 :u -0.12) (:arm-l :flex 60 :side 10) (:elbow-l :flex 30) (:arm-r :flex 20 :side 24) (:elbow-r :flex 30)
      (:chest :twist -20) (:thigh-r :flex 36) (:knee-r :flex 40))
  (:end :ru-cold-stance))

(defstrike :ru-spin-50 (8 3 18 :base :ru-cold-stance)   ; MAI-SODE at -50: both hands on the hilt, low and heavy
  (0)
  (4 (:root :u -0.18 :yaw -16) (:knees :flex 50) (:chest :twist -30) (:neck :twist 14) (:arm-r :side 70 :flex 10) (:elbow-r :flex 20)
     (:hand-r :twist 0 :flex -88) (:arm-l :side 50 :flex 40) (:elbow-l :flex 60))
  (6 (:root :u -0.2 :yaw -26) (:chest :twist -36))
  (:s :snap (:root :yaw 360 :u -0.14 :f 0.3) (:pelvis :twist 20) (:chest :twist 10) (:neck :twist -10) (:head :twist -10 :flex 4)
      (:arm-r :side 80 :flex 30) (:elbow-r :flex 10) (:hand-r :flex -88) (:arm-l :side 60 :flex 48) (:elbow-l :flex 56)
      (:thigh-r :flex 30) (:knee-r :flex 40) (:thigh-l :flex -10 :side 14) (:knee-l :flex 30))
  (:a (:root :yaw 378 :u -0.15 :f 0.32) (:chest :twist 14))
  (22 (:root :yaw 370 :u -0.12 :f 0.28) (:chest :twist 8) (:arm-r :side 44 :flex 30) (:elbow-r :flex 30) (:hand-r :flex -60)
      (:arm-l :side 40 :flex 40) (:elbow-l :flex 50))
  (:end :ru-cold-stance (:root :yaw 360)))

(defpose :ru-flower-50-hit (:base :ru-flower-hit)
  (:arm-r :flex 36 :side -4) (:elbow-r :flex 0) (:hand-r :twist 0 :flex 50) (:chest :twist 0) (:spine :flex 52))
(defstrike :ru-flower-50 (21 5 34 :base :ru-cold-stance)   ; HYOKA at -50: both palms driven down
  (0)
  (8 (:root :u 0.02) (:arm-l :flex 160 :side 10) (:elbow-l :flex 16) (:arm-r :flex 160 :side -10) (:elbow-r :flex 16)
     (:hand-r :twist 0) (:spine :flex -8) (:head :flex -24) (:thigh-r :flex 20) (:knee-r :flex 16) (:thigh-l :flex -10) (:knee-l :flex 10))
  (17 (:root :u 0.03) (:arm-l :flex 168) (:arm-r :flex 168) (:spine :flex -11))
  (:s :snap :ru-flower-50-hit)
  (:a (:root :u -0.51) (:spine :flex 54))
  (46 (:root :u -0.49 :f 0.26))
  (54 (:root :u -0.2 :f 0.12) (:spine :flex 22) (:arm-l :flex 44 :side 10) (:elbow-l :flex 30) (:arm-r :flex -20 :side 36)
      (:elbow-r :flex 26) (:hand-r :twist 160 :flex 20) (:thigh-r :flex 50) (:knee-r :flex 60) (:thigh-l :flex -10) (:knee-l :flex 50))
  (:end :ru-cold-stance))

(defpose :ru-stab-2h-pose (:base :ru-stab-pose)        ; HYOSHIN: both hands on the hilt, driving the blade into the plaza
  (:arm-l :flex 60 :side -10) (:elbow-l :flex 34) (:hand-l :flex 0) (:chest :twist -8) (:root :u -0.24) (:spine :flex 42))
(defclip :ru-stab-2h (0.4 :base :ru-stab-2h-pose)
  (0 :snap (:arm-r :flex 70) (:arm-l :flex 74) (:root :u -0.14) (:spine :flex 20))
  (0.2 :snap (:arm-r :flex 50) (:arm-l :flex 56) (:root :u -0.26) (:spine :flex 44))
  (0.4 (:root :u -0.24)))

(defstrike :ru-q1-z (7 3 12 :base :ru-zero-pose)        ; J1 at zero: the flat cut from where she stands (feet pinned)
  (0)
  (3 (:chest :twist -34) (:arm-r :side 88 :flex -12) (:elbow-r :flex 16) (:hand-r :twist 0 :flex -84) (:arm-l :flex 30 :side 30))
  (:s :snap :ru-q1-hit (:root :f 0.0 :u -0.05) (:thigh-r :flex 14) (:knee-r :flex 16) (:thigh-l :flex -8) (:knee-l :flex 8))
  (:a (:chest :twist 16) (:arm-r :flex 98) (:root :f 0.0 :u -0.05))
  (16 (:chest :twist 8) (:arm-r :side 40 :flex 50) (:elbow-r :flex 20) (:hand-r :flex -70) (:root :f 0.0 :u -0.03))
  (:end :ru-zero-pose))

(defstrike :ru-thrust-z (17 4 20 :base :ru-zero-pose)   ; K1 at zero: the thrust from a planted stance, the ice does the reaching
  (0)
  (8 (:chest :twist -20) (:arm-r :flex 10 :side 10) (:elbow-r :flex 120) (:hand-r :twist -10 :flex -70) (:root :u -0.06))
  (14 (:chest :twist -24) (:arm-r :flex 6) (:elbow-r :flex 126) (:root :u -0.07))
  (:s :snap :ru-thrust-hit (:root :f 0.06 :u -0.08) (:thigh-r :flex 20) (:knee-r :flex 22) (:thigh-l :flex -10) (:knee-l :flex 6))
  (:a (:arm-r :flex 99) (:root :f 0.06 :u -0.08))
  (32 (:root :f 0.02 :u -0.04) (:arm-r :flex 40 :side 12) (:elbow-r :flex 24) (:hand-r :twist -10 :flex -70))
  (:end :ru-zero-pose))

;;; ---------------------------------------------------------------- ice looks (cosmetic: RND01, the fx clock)
(defun-fast vfx-ru-ring (x z r grow k)
  "A white ring of radius R on the plaza (x z) drawn round in GROW (0..1 of its circle: the blade tip's sweep) with ink
ticks, presence K: TSUKISHIRO's circle, the tell."
  (with-floats (x z r grow k)
    (let* ((dr (drawing-no)) (sd (i->f (mod (f->i dr) 5))) (n (f->i (* 32f0 (f-clamp grow 0f0 1f0)))))
      (declare (single-float dr sd) (fixnum n))
      (when (>= n 32) (%tring x 0.01f0 z r 0.06f0 +pal-hit+ k sd 32))
      (when (and (> n 0) (< n 32))                       ; the arc being drawn
        (dotimes (i n)
          (let* ((a0 (* 0.19635f0 (i->f i))) (a1 (+ a0 0.19635f0)))
            (declare (single-float a0 a1))
            (toon-ground-seg (+ x (* r (f-cos a0))) (+ z (* r (f-sin a0))) (+ x (* r (f-cos a1))) (+ z (* r (f-sin a1)))
                             0.02f0 0.06f0 1f0 1f0 (+ sd 3f0) 0.12f0 (toon-a +pal-hit+ k)))))
      (dotimes (i 8)                                      ; ink ticks round it
        (let* ((a (* 0.7854f0 (i->f i))) (c (f-cos a)) (s (f-sin a)))
          (declare (single-float a c s))
          (when (< (i->f i) (* 8f0 grow))
            (toon-ground-seg (+ x (* (- r 0.2f0) c)) (+ z (* (- r 0.2f0) s)) (+ x (* (+ r 0.15f0) c)) (+ z (* (+ r 0.15f0) s))
                             0.025f0 0.02f0 1f0 1f0 (+ 9f0 (i->f i)) 0.1f0 (toon-a +pal-ink+ k))))))
    nil))

(defun-fast vfx-ru-pillar (x z r height age dt)
  "A pillar of white light and ice HEIGHT m tall rising from the plaza (x z), radius R: SOUL-glass tongues over white
cores, rising over its first 0.15 s, shards thrown out, ice motes (TSUKISHIRO, 白霞罸's pillar, a victim encased)."
  (with-floats (x z r height age dt)
    (let* ((rise (f-clamp (/ age 0.15f0) 0f0 1f0)) (h (* height rise)) (dr (drawing-no)) (k (f-clamp (- 1.4f0 (* 0.8f0 age)) 0.1f0 0.98f0)))
      (declare (single-float rise h dr k))
      (when (> h 0.05f0)
        (dotimes (i 7)
          (let* ((f (i->f i)) (a (+ (* 0.8976f0 f) (* 0.3f0 (hash01 f 2.1f0)))) (rr (* r 0.6f0))
                 (hh (* h (+ 0.75f0 (* 0.35f0 (hash01 (+ f dr) 4.3f0))))) (sd (- -1f0 (+ f (* 3f0 (i->f (mod (f->i dr) 4)))))))
            (declare (single-float f a rr hh sd))
            (toon-ribbon ((+ x (* rr (f-cos a))) 0f0 (+ z (* rr (f-sin a)))) (0f0 hh 0f0) ((* 0.35f0 r) 0.05f0) :heat (1f0 0.3f0) :seed sd :wob 0.15f0
                         :pal +pal-soul+ :k k :ph (+ f dr) :sway 0.05f0 :segs 5)))
        (toon-ribbon (x 0f0 z) (0f0 (* 1.1f0 h) 0f0) ((* 0.22f0 r) 0.02f0) :heat (1f0 0.5f0) :seed -3f0 :wob 0.1f0 :pal +pal-hit+ :k k :ph dr
                     :sway 0.02f0 :segs 4)
        (%tring x 0f0 z r 0.08f0 +pal-soul+ k (i->f (mod (f->i dr) 5)) 24))
      (dotimes (i (n-of (* 30f0 k) dt))
        (%t-blob (+ x (rnd-range (- r) r)) (rnd-range 0.2f0 h) (+ z (rnd-range (- r) r)) 0f0 (rnd-range 0.5f0 1.5f0) 0f0
                 (rnd-range 0.5f0 0.9f0) (rnd-range 0.02f0 0.05f0) 0f0 0.1f0 +pal-hit+))
      (when (< age 0.1f0)
        (dotimes (i (n-of 120f0 dt))
          (let ((a (rnd-range 0f0 6.2832f0)) (sp (rnd-range 2f0 5f0)))
            (declare (single-float a sp))
            (%t-shard x (rnd-range 0.2f0 1.5f0) z (* sp (f-cos a)) (rnd-range 1f0 4f0) (* sp (f-sin a)) (rnd-range 0.5f0 0.9f0)
                      (rnd-range 0.08f0 0.16f0) 6f0 +pal-soul+))))
      (%light x 1.5f0 z 0.85f0 0.9f0 1f0 5f0 (* 1.6f0 k) 6))
    nil))

(defun-fast vfx-ru-lake (x z r y k)
  "A flat, lake-like disc of frost of radius R at height Y over (x z): a white rim, SOUL-glass rings inside, ink cracks
(the plaza whitening under her; 白霞罸's two lakes, plaza and sky)."
  (with-floats (x z r y k)
    (when (> r 0.05f0)
      (let* ((dr (drawing-no)) (sd (i->f (mod (f->i dr) 5))))
        (declare (single-float dr sd))
        (%tring x y z r 0.08f0 +pal-hit+ k sd 32)
        (%tring x y z (* 0.72f0 r) 0.12f0 +pal-soul+ (* 0.8f0 k) (+ sd 1f0) 32)
        (%tring x y z (* 0.42f0 r) 0.1f0 +pal-soul+ (* 0.6f0 k) (+ sd 2f0) 24)
        (dotimes (i 6)
          (let* ((a (+ (* 1.0472f0 (i->f i)) (hash01 (i->f i) 5.5f0))) (c (f-cos a)) (s (f-sin a)))
            (declare (single-float a c s))
            (toon-ground-seg (+ x (* 0.2f0 r c)) (+ z (* 0.2f0 r s)) (+ x (* 0.95f0 r c)) (+ z (* 0.95f0 r s)) (+ y 0.01f0)
                             0.025f0 1f0 0.3f0 (+ 20f0 (i->f i)) 0.2f0 (toon-a +pal-ink+ (* 0.7f0 k)))))))
    nil))

(defun-fast vfx-ru-sheet (x0 z0 x1 z1 age life)
  "The cold running off the blade's tip along the ground from (x0 z0) toward (x1 z1): a white sheet racing out in 0.15 s,
SOUL-glass edges, eroding over LIFE (HAKKA's lane, the Hakuren-like wave of 白霞罸)."
  (with-floats (x0 z0 x1 z1 age life)
    (let* ((dx (- x1 x0)) (dz (- z1 z0)) (l (f-max 0.01f0 (f-hypot dx dz))) (ux (/ dx l)) (uz (/ dz l))
           (run (f-clamp (/ age 0.15f0) 0f0 1f0)) (k (f-clamp (* 0.98f0 (- 1f0 (/ age (f-max life 0.01f0)))) 0f0 0.98f0))
           (dr (drawing-no)) (sd (i->f (mod (f->i dr) 5))) (e (* run l)))
      (declare (single-float dx dz l ux uz run k dr sd e))
      (when (> k 0.02f0)
        (toon-ground-seg (+ x0 (* 0.5f0 ux)) (+ z0 (* 0.5f0 uz)) (+ x0 (* e ux)) (+ z0 (* e uz)) 0.03f0 0.9f0 1f0 0.4f0 (+ sd 30f0)
                         0.25f0 (toon-a +pal-soul+ k))
        (toon-ground-seg (+ x0 (* 0.5f0 ux)) (+ z0 (* 0.5f0 uz)) (+ x0 (* e ux)) (+ z0 (* e uz)) 0.035f0 0.35f0 1f0 0.6f0 (+ sd 34f0)
                         0.12f0 (toon-a +pal-hit+ k))
        (dotimes (i 5)                                   ; ice spikes standing along it
          (let* ((u (* (+ 0.15f0 (* 0.18f0 (i->f i))) e)))
            (declare (single-float u))
            (toon-ribbon ((+ x0 (* u ux)) 0f0 (+ z0 (* u uz))) (0f0 (* 0.9f0 k (+ 0.6f0 (hash01 (i->f i) 3.3f0))) 0f0) (0.12f0 0.01f0)
                         :heat (1f0 0.3f0) :seed (- -5f0 (i->f i)) :wob 0.1f0 :pal +pal-soul+ :k k :ph (i->f i) :segs 3)))))
    nil))

(defun-fast vfx-ru-dust (x y z)
  "A figure weathering into ice dust (x y z = the feet): SOUL-glass shards peeling off the whole body and drifting up and
away, white flakes (TENCHI's ash crumble, re-coloured). One-shot."
  (with-floats (x y z)
    (dotimes (i 48)
      (%t-shard (+ x (rnd-range -0.3f0 0.3f0)) (+ y (rnd-range 0.1f0 1.8f0)) (+ z (rnd-range -0.3f0 0.3f0))
                (rnd-range -1.2f0 1.2f0) (rnd-range 0.4f0 1.6f0) (rnd-range -1.2f0 1.2f0) (rnd-range 1.2f0 2.2f0)
                (rnd-range 0.05f0 0.12f0) -0.3f0 +pal-soul+))
    (dotimes (i 20)
      (%t-blob (+ x (rnd-range -0.3f0 0.3f0)) (+ y (rnd-range 0.2f0 1.7f0)) (+ z (rnd-range -0.3f0 0.3f0)) (rnd-range -0.6f0 0.6f0)
               (rnd-range 0.4f0 1.2f0) (rnd-range -0.6f0 0.6f0) (rnd-range 1f0 1.8f0) (rnd-range 0.03f0 0.06f0) -0.2f0 0.1f0 +pal-hit+))
    nil))

(defun-fast vfx-ru-crust (x y z dt)
  "A victim frozen solid: white ice crystals round his body (x y z = the body's middle), on twos."
  (declare (ignore dt))
  (with-floats (x y z)
    (let* ((dr (drawing-no)))
      (declare (single-float dr))
      (dotimes (i 9)
        (let* ((f (i->f i)) (a (* 0.698f0 f)) (h (+ -0.7f0 (* 1.6f0 (hash01 f 1.9f0)))))
          (declare (single-float f a h))
          (fx-shard (+ x (* 0.32f0 (f-cos a))) (+ y h) (+ z (* 0.32f0 (f-sin a))) (* 0.3f0 (f-cos a)) 0.9f0 (* 0.3f0 (f-sin a))
                    (+ 0.25f0 (* 0.15f0 (hash01 (+ f dr) 2.2f0))) 0.06f0 0.1f0 (+ f 40f0) +pal-soul+ 0.9f0))))
    nil))

(defun-fast vfx-ru-breath (x y z yaw)
  "One white breath puff from her mouth (x y z), drifting forward along YAW. One-shot."
  (with-floats (x y z yaw)
    (let ((fx (- (f-sin yaw))) (fz (- (f-cos yaw))))
      (declare (single-float fx fz))
      (dotimes (i 4)
        (%t-blob (+ x (* 0.1f0 fx)) y (+ z (* 0.1f0 fz)) (* fx (rnd-range 0.3f0 0.6f0)) (rnd-range 0.05f0 0.2f0)
                 (* fz (rnd-range 0.3f0 0.6f0)) (rnd-range 0.4f0 0.7f0) (rnd-range 0.015f0 0.03f0) -0.05f0 0.2f0 +pal-hit+)))
    nil))

(defun-fast vfx-frost (x z k dt)
  "Frost on a fighter's feet and shins (x z; K 0..1: its time left): SOUL-glass shards crusting them, a white ring (the
status is read on the model, not the HUD)."
  (with-floats (x z k dt)
    (let* ((dr (drawing-no)) (kk (f-clamp (+ 0.3f0 k) 0.3f0 0.95f0)))
      (declare (single-float dr kk))
      (%tring x 0f0 z 0.42f0 0.05f0 +pal-soul+ kk (i->f (mod (f->i dr) 5)) 16)
      (dotimes (i 6)
        (let* ((f (i->f i)) (a (+ (* 1.0472f0 f) 0.3f0)))
          (declare (single-float f a))
          (fx-shard (+ x (* 0.2f0 (f-cos a))) (+ 0.12f0 (* 0.25f0 (hash01 f 3.1f0))) (+ z (* 0.2f0 (f-sin a)))
                    (* 0.4f0 (f-cos a)) 0.9f0 (* 0.4f0 (f-sin a)) 0.18f0 0.045f0 0.1f0 (+ f 60f0) +pal-soul+ kk)))
      (dotimes (i (n-of 4f0 dt))
        (%t-blob (+ x (rnd-range -0.3f0 0.3f0)) 0.2f0 (+ z (rnd-range -0.3f0 0.3f0)) 0f0 (rnd-range 0.2f0 0.5f0) 0f0
                 (rnd-range 0.5f0 0.8f0) (rnd-range 0.02f0 0.035f0) 0f0 0.1f0 +pal-hit+)))
    nil))

;;; the hazards' draw functions (HAZARD-DRAW: (fn hazard rdt); a :fx hazard is a look only)
(defun rukia-ring-look (hz rdt)
  "TSUKISHIRO: the white ring while it waits (the tell: it pulses faster as it nears), then the pillar."
  (let ((x (hazard-x hz)) (z (hazard-z hz)) (r (hazard-size hz)))
    (if (> (hazard-delay hz) 0)
        (vfx-ru-ring x z r (min 1.0 (/ (- 25 (hazard-delay hz)) 6.0)) (if (evenp (floor (hazard-delay hz) (if (< (hazard-delay hz) 10) 2 4))) 0.95 0.6))
        (progn (vfx-ru-ring x z r 1.0 (max 0.05 (- 0.95 (/ (hazard-age hz) 36.0))))
               (vfx-ru-pillar x z r 4.5 (/ (hazard-age hz) 60.0) rdt)))))

(defun rukia-spike-look (hz rdt)
  "HAKUREN's stab: an ice spike standing in the plaza, then crumbling."
  (declare (ignore rdt))
  (let* ((age (/ (hazard-age hz) 60.0)) (k (max 0.02 (- 0.95 (* 0.9 (/ (hazard-age hz) (max 1 (hazard-life hz)))))))
         (h (* (hazard-size hz) (min 1.0 (/ age 0.06)))))
    (with-floats (h k)
      (let ((x (hazard-x hz)) (z (hazard-z hz)))
        (toon-ribbon (x 0f0 z) (0.05f0 h 0f0) (0.09f0 0.005f0) :heat (1f0 0.3f0) :seed -7f0 :wob 0.1f0 :pal +pal-soul+ :k k :segs 3)
        (toon-ribbon (x 0f0 z) (0.02f0 (* 0.7f0 h) 0f0) (0.03f0 0.002f0) :heat (1f0 0.5f0) :seed -8f0 :wob 0.05f0 :pal +pal-hit+ :k k :segs 2)))))

(defun rukia-wave-look (hz rdt)
  "HAKUREN's wave: an avalanche of cold rolling along the ground, as wide as its hit box: a white crest over SOUL glass."
  (when (and (<= (hazard-delay hz) 0) (< (hazard-age hz) (hazard-life hz)))
    (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (hw (hazard-size hz))
           (px (- (fwd-z yaw))) (pz (fwd-x yaw)) (fx (fwd-x yaw)) (fz (fwd-z yaw)) (dr (drawing-no)))
      (with-floats (x z hw px pz fx fz dr)
        (dotimes (i 7)
          (let* ((u (- (* (/ (i->f i) 6f0) 2f0) 1f0)) (bx (+ x (* u hw px))) (bz (+ z (* u hw pz)))
                 (hh (* (+ 0.8f0 (* 0.6f0 (hash01 (+ (i->f i) dr) 1.7f0))) (- 1.2f0 (* 0.5f0 (f-abs u))))))
            (declare (single-float u bx bz hh))
            (toon-ribbon (bx 0f0 bz) ((* 0.3f0 fx) hh (* 0.3f0 fz)) (0.32f0 0.05f0) :heat (1f0 0.3f0) :seed (- -11f0 (i->f i)) :wob 0.2f0
                         :pal +pal-soul+ :k 0.9f0 :ph (+ (i->f i) dr) :sway 0.05f0 :segs 4)
            (toon-ribbon (bx 0.05f0 bz) ((* 0.3f0 fx) (* 0.6f0 hh) (* 0.3f0 fz)) (0.12f0 0.02f0) :heat (1f0 0.5f0) :seed (- -21f0 (i->f i)) :wob 0.1f0
                         :pal +pal-hit+ :k 0.9f0 :ph (+ (i->f i) dr) :sway 0.03f0 :segs 3)))
        (toon-ground-seg (- x (* 1.2f0 fx)) (- z (* 1.2f0 fz)) x z 0.02f0 hw 0.4f0 1f0 (+ 50f0 dr) 0.2f0 (toon-a +pal-soul+ 0.8f0))
        (dotimes (i (n-of 40f0 (f32 rdt)))
          (%t-blob (+ x (* (rnd-range -1f0 1f0) hw px)) (rnd-range 0.1f0 1f0) (+ z (* (rnd-range -1f0 1f0) hw pz))
                   (rnd-range -0.5f0 0.5f0) (rnd-range 0.3f0 1.2f0) (rnd-range -0.5f0 0.5f0) (rnd-range 0.4f0 0.7f0)
                   (rnd-range 0.04f0 0.08f0) -0.1f0 0.2f0 +pal-hit+))))))

(defun rukia-blade-look (hz rdt)
  "SHIRAFUNE: the ice blade grown off the point along the thrust (SIZE m), in three stepped drawings, then gone."
  (declare (ignore rdt))
  (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (l (hazard-size hz)) (age (hazard-age hz))
         (grow (min 1.0 (/ (1+ (floor age 2)) 3.0))) (k (max 0.02 (- 0.95 (* 0.06 (max 0 (- age 6))))))
         (x1 (+ x (* grow l (fwd-x yaw)))) (z1 (+ z (* grow l (fwd-z yaw)))))
    (with-floats (x z x1 z1 k)
      (fx-crescent x 1.1f0 z x1 1.1f0 z1 (* 0.5f0 (+ x x1)) 1.12f0 (* 0.5f0 (+ z z1)) 0.07f0 :lens 0.05f0 71f0 +pal-soul+ k :push 0.2f0)
      (fx-crescent x 1.1f0 z x1 1.1f0 z1 (* 0.5f0 (+ x x1)) 1.12f0 (* 0.5f0 (+ z z1)) 0.025f0 :lens 0.03f0 72f0 +pal-hit+ k :push 0.24f0))))

(defun rukia-burst-look (hz rdt)
  "A burst of cold (NADARE's snow, REIDO's release, the entry to zero): a white ring out to SIZE m, SOUL-glass shards."
  (let* ((x (hazard-x hz)) (z (hazard-z hz)) (r (hazard-size hz)) (age (/ (hazard-age hz) 60.0))
         (k (max 0.02 (- 0.95 (/ (hazard-age hz) (max 1.0 (float (hazard-life hz))))))))
    (with-floats (x z r age k rdt)
      (%tring x 0f0 z (* r (f-min 1f0 (* 6f0 age))) 0.08f0 +pal-hit+ k 3f0 24)
      (%tring x 0f0 z (* 0.7f0 r (f-min 1f0 (* 6f0 age))) 0.06f0 +pal-soul+ k 4f0 24)
      (when (< age 0.05f0)
        (dotimes (i (n-of 400f0 rdt))
          (let ((a (rnd-range 0f0 6.2832f0)) (sp (rnd-range 2f0 5f0)))
            (declare (single-float a sp))
            (%t-shard x (rnd-range 0.2f0 1.2f0) z (* sp (f-cos a)) (rnd-range 1f0 3f0) (* sp (f-sin a)) (rnd-range 0.4f0 0.8f0)
                      (rnd-range 0.06f0 0.12f0) 6f0 +pal-soul+)))))))

(defun rukia-flower-look (hz rdt)
  "HYOKA: the ice flower bursting at his feet: six SOUL-glass petals standing out of the plaza round a white core."
  (declare (ignore rdt))
  (let* ((x (hazard-x hz)) (z (hazard-z hz)) (r (hazard-size hz)) (age (hazard-age hz))
         (g (min 1.0 (/ age 5.0))) (k (max 0.02 (- 0.95 (* 0.025 (max 0 (- age 12)))))))
    (with-floats (x z r g k)
      (dotimes (i 6)
        (let* ((a (* 1.0472f0 (i->f i))) (c (f-cos a)) (s (f-sin a)))
          (declare (single-float a c s))
          (toon-ribbon ((+ x (* 0.15f0 r c)) 0f0 (+ z (* 0.15f0 r s))) ((* 0.8f0 r g c) (* 1.3f0 g) (* 0.8f0 r g s)) (0.16f0 0.01f0) :heat (1f0 0.3f0)
                       :seed (- -31f0 (i->f i)) :wob 0.1f0 :pal +pal-soul+ :k k :ph (i->f i) :segs 3)))
      (toon-ribbon (x 0f0 z) (0f0 (* 1.6f0 g) 0f0) (0.1f0 0.005f0) :heat (1f0 0.5f0) :seed -38f0 :wob 0.05f0 :pal +pal-hit+ :k k :segs 3)
      (%tring x 0f0 z r 0.06f0 +pal-soul+ k 7f0 24))))

(defun rukia-quake-look (hz rdt)
  "HYOSHIN: frost cracks radiating from her (the tell, while it waits), then the quake: a white ring out to SIZE m."
  (let ((x (hazard-x hz)) (z (hazard-z hz)) (r (hazard-size hz)))
    (with-floats (x z r)
      (let ((grow (if (> (hazard-delay hz) 0) (f-min 1f0 (/ (i->f (- 15 (hazard-delay hz))) 14f0)) 1f0))
            (k (if (> (hazard-delay hz) 0) 0.9f0 (f-max 0.02f0 (- 0.95f0 (/ (i->f (hazard-age hz)) 30f0))))))
        (declare (single-float grow k))
        (dotimes (i 7)
          (let* ((a (+ (* 0.8976f0 (i->f i)) (hash01 (i->f i) 8.1f0))) (c (f-cos a)) (s (f-sin a)) (rr (* r grow (+ 0.7f0 (* 0.3f0 (hash01 (i->f i) 2.7f0))))))
            (declare (single-float a c s rr))
            (toon-ground-seg (+ x (* 0.3f0 c)) (+ z (* 0.3f0 s)) (+ x (* rr c)) (+ z (* rr s)) 0.02f0 0.04f0 1f0 0.3f0
                             (+ 80f0 (i->f i)) 0.2f0 (toon-a +pal-soul+ k))))
        (when (<= (hazard-delay hz) 0)
          (%tring x 0f0 z (* r (f-min 1f0 (/ (i->f (hazard-age hz)) 6f0))) 0.1f0 +pal-hit+ k 5f0 32)
          (when (< (hazard-age hz) 3)
            (dotimes (i (n-of 300f0 (f32 rdt)))
              (let ((a (rnd-range 0f0 6.2832f0)) (d (rnd-range 0.5f0 r)))
                (declare (single-float a d))
                (%t-shard (+ x (* d (f-cos a))) 0.1f0 (+ z (* d (f-sin a))) 0f0 (rnd-range 2f0 5f0) 0f0 (rnd-range 0.4f0 0.7f0)
                          (rnd-range 0.08f0 0.16f0) 9f0 +pal-soul+)))))))))

(defun rukia-pillar-look (hz rdt)
  "HAKKA f4: the white pillar of cold at her."
  (vfx-ru-pillar (hazard-x hz) (hazard-z hz) (hazard-size hz) 2.4 (/ (hazard-age hz) 60.0) rdt))

(defun rukia-sheet-look (hz rdt)
  "HAKKA f20: the cold running off the tip along the lane (SIZE m)."
  (declare (ignore rdt))
  (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (l (hazard-size hz)))
    (vfx-ru-sheet x z (+ x (* l (fwd-x yaw))) (+ z (* l (fwd-z yaw))) (/ (hazard-age hz) 60.0) (/ (hazard-life hz) 60.0))))

;;; the auras (DRAW-AURA's kinds are VFX-AURA's; a symbol that names a function draws with it: (fn x y z h k dt))
(defun rukia-field-ring (x y z field k)
  "The cold field 寒域 (the band's :field radius): a thin dim white ring on the plaza round her."
  (let ((r (getf field :r)))
    (with-floats (x y z r k)
      (%tring x (+ y 0.01f0) z r 0.05f0 +pal-hit+ (* 0.6f0 k) 6f0 48))))

(defun rukia-aura-cold (x y z h k dt)
  "-18 C: frost motes at her feet, a white breath puff every 40 f, the field's ring."
  (rukia-field-ring x y z *ru-field-m18* k)
  (with-floats (x y z h k dt)
    (dotimes (i (n-of (* 5f0 k) dt))
      (%t-blob (+ x (rnd-range -0.35f0 0.35f0)) (+ y 0.05f0) (+ z (rnd-range -0.35f0 0.35f0)) 0f0 (rnd-range 0.2f0 0.5f0) 0f0
               (rnd-range 0.6f0 1f0) (rnd-range 0.015f0 0.03f0) 0f0 0.1f0 +pal-hit+))
    (when (< (f-mod (fx-clock) 0.667f0) dt)
      (vfx-ru-breath x (+ y (* 0.92f0 h)) z 0f0))))

(defun rukia-aura-frost (x y z h k dt)
  "-50 C: the plaza whitening in a 1 m disc under her, low white mist, rising motes, the field's ring."
  (rukia-field-ring x y z *ru-field-m50* k)
  (with-floats (x y z h k dt)
    (vfx-ru-lake x z 1.0f0 (+ y 0.01f0) (* 0.8f0 k))
    (dotimes (i (n-of (* 10f0 k) dt))
      (%t-blob (+ x (rnd-range -0.5f0 0.5f0)) (+ y 0.05f0) (+ z (rnd-range -0.5f0 0.5f0)) (rnd-range -0.2f0 0.2f0) (rnd-range 0.1f0 0.3f0)
               (rnd-range -0.2f0 0.2f0) (rnd-range 0.8f0 1.3f0) (rnd-range 0.06f0 0.1f0) -0.05f0 0.2f0 +pal-hit+))
    (dotimes (i (n-of (* 6f0 k) dt))
      (%t-blob (+ x (rnd-range -0.4f0 0.4f0)) (+ y (* h (rnd-range 0.1f0 0.8f0))) (+ z (rnd-range -0.4f0 0.4f0)) 0f0
               (rnd-range 0.5f0 1f0) 0f0 (rnd-range 0.5f0 0.8f0) (rnd-range 0.015f0 0.03f0) 0f0 0.1f0 +pal-hit+))))

(defun rukia-aura-zero (x y z h k dt)
  "Absolute zero: a thin white ring at her feet and still motes (no breath), the field's ring (5.5 m: REIDO's reach)."
  (declare (ignore h))
  (rukia-field-ring x y z *ru-field-zero* k)
  (with-floats (x y z k dt)
    (%tring x y z 0.85f0 0.03f0 +pal-hit+ (* 0.95f0 k) 2f0 32)
    (vfx-ru-lake x z 1.4f0 (+ y 0.01f0) (* 0.6f0 k))
    (dotimes (i (n-of (* 3f0 k) dt))
      (%t-blob (+ x (rnd-range -0.6f0 0.6f0)) (+ y (rnd-range 0.2f0 1.4f0)) (+ z (rnd-range -0.6f0 0.6f0)) 0f0 0.02f0 0f0
               (rnd-range 1f0 1.5f0) (rnd-range 0.015f0 0.025f0) 0f0 0.05f0 +pal-hit+))))
