;;;; sounds.lisp — SOUL DUEL's sound bank (design §11): every SFX and the two music loops, described
;;;; with the engine's synthesis toolkit (engine/lisp/audio.lisp, docs/AUDIO.md) and rendered once at
;;;; startup, one sound per loading step, in this order. No samples, no voices. SFX ≤ 1.5 s.
;;;;
;;;; Keys (play with PLAY-SFX / PLAY-SFX-AT; loops with START-LOOP; music with MUSIC-PLAY):
;;;;   :whoosh-light     light katana swing (Quick attacks)
;;;;   :whoosh-heavy     heavy swing (Flash attacks, SP swings)
;;;;   :whoosh-cleaver   Nozarashi's huge, low swing
;;;;   :cut              blade hit on a body
;;;;   :cut-heavy        heavy / ender blade hit
;;;;   :punch            Ikkotsu fist / Ken's shoulder charge impact
;;;;   :clang            blocked hit (blade on blade)
;;;;   :guard-break      guard shattered by a Breaker
;;;;   :breaker-hum      Breaker aura hum (loop: START-LOOP / STOP-LOOP)
;;;;   :clash            Breaker vs Breaker
;;;;   :step             step dodge swish
;;;;   :hoho-out         Hoho vanish
;;;;   :hoho-in          Hoho reappear
;;;;   :perfect          perfect Hoho chime
;;;;   :launch           body launched into the air
;;;;   :land             body hits the ground
;;;;   :fire-whoosh      flame ignites along the blade
;;;;   :fire-roar        big roaring flames (Hellfire, Taimatsu, Ennetsu pillars)
;;;;   :fire-crackle     burning crackle (loop: stage fires, Shiranui charge, Hellfire aura)
;;;;   :fire-wave        the Signature flame wave travelling
;;;;   :explode          fireball / fire dome detonation
;;;;   :sizzle           Bankai blade hit: heat erasing what it touches
;;;;   :heat-flare       Bankai: the garb flaring (U to West, SHONETSU's tell), the heat sheet, a broken ward (low pitch):
;;;;                     a thump + a long hiss
;;;;   :ground-crack     ground split (Buttagiru, Split the Meteor, Bankai cracks)
;;;;   :bones            skeleton rattle (Bankai South)
;;;;   :kikon-slash      Kikon finishing cut (reverse swell into a heavy slash)
;;;;   :konpaku-shatter  a Konpaku soul flame breaking (glass)
;;;;   :awaken-boom      awakening burst
;;;;   :awaken-rise      rising swell into the awakening
;;;;   :evolution        the Awakening gauge is full
;;;;   :laugh            Ken's laugh-ish formant bark (no voice)
;;;;   :gulp             NOMIHOSE's DRINK: a throat thump and a wet swallow
;;;;   :arm-crack        Kenpachi's Bankai: a pip of the arm spent / cracked (a bone creak and a crack)
;;;;   :arm-burst        the arm bursting (a wet crack, a thump, spray)
;;;;   :yachiru-call     the Bankai cinematic's forest: a detuned, doubled chirp chord (the call; no voice)
;;;;   :frost-tick       Rukia: a crystalline tick (a temperature step reached, a stab, the ring's tell)
;;;;   :freeze           a crackle that locks (freeze-touch, TSUKISHIRO, REIDO, an ice hit)
;;;;   :ice-rise         a rising shimmer over a low bell (the pillars, the wave of cold)
;;;;   :ice-shatter      a glassy break (the pillar shattering, NADARE, the ice dust)
;;;;   :hand-crack       a small brittle crack (the CRACK, the hand in 白霞罸)
;;;;   :rift-open        KUKAN-GIRI's rift opening in the air (a thin rising shimmer)
;;;;   :rift-cut         the rift cutting (a bright slash, no reverse swell)
;;;;   :tier-up          a cup up the NOME ladder (a drum hit under a rising sweep)
;;;;   :bell             temple bell stinger (round start, Kikon available)
;;;;   :fight            "FIGHT!" taiko hits + gong
;;;;   :ko               K.O. stinger
;;;;   :select           menu cursor move
;;;;   :confirm          menu confirm
;;;;   :back             menu back
;;;;   :music            battle loop, 19.2 s: taiko, low saws in D phrygian, shakuhachi lead
;;;;   :music-title      title / select loop, 16 s: gong swells, koto-ish plucks, slow shakuhachi
;;;; For now MUSIC-PLAY plays the sound named :music; the engine's music-play will take a key later.
(in-package :duel)

;;; ---------------------------------------------------------------- blades and bodies
(defsound :whoosh-light (:peak 0.6)
  (let ((b (au-whoosh 0.26 1000 6500 :q 1.3 :peak 0.07)))
    (au-partials! b 0.04 '((3300 0.12 0.08) (5100 0.08 0.06)))))

(defsound :whoosh-heavy (:peak 0.8)
  (let ((b (au-whoosh 0.45 350 4200 :q 1.0 :peak 0.12)))
    (au-mix! b (au-whoosh 0.42 110 480 :q 1.4 :peak 0.12) 0.0 0.7)))

(defsound :whoosh-cleaver (:peak 0.9)
  (let ((b (au-whoosh 0.75 70 900 :q 0.9 :peak 0.3)))
    (au-mix! b (au-whoosh 0.7 40 200 :q 1.6 :peak 0.3) 0.0 0.9)
    (au-thump! b 0.3 70 40 0.1 0.15 0.35)
    (au-drive! b 1.6)))

(defsound :cut (:peak 0.85)
  (let ((b (au-buf 0.35)))
    (au-thump! b 0.0 150 55 0.05 0.07 1.0)
    (au-mix! b (au-drive! (au-fnoise 0.15 :hp 1800 :decay 0.03) 3) 0.0 0.7)
    (au-mix! b (au-fnoise 0.3 :bp 900 :to 350 :q 3 :decay 0.06) 0.004 0.5)
    (au-partials! b 0.0 '((4200 0.15 0.05) (6100 0.1 0.04)))))

(defsound :cut-heavy (:peak 0.95)
  (let ((b (au-buf 0.7)))
    (au-thump! b 0.0 110 36 0.08 0.16 1.0)
    (au-thump! b 0.01 60 30 0.1 0.25 0.6)
    (au-mix! b (au-drive! (au-fnoise 0.3 :lp 2600 :decay 0.06) 5) 0.0 0.8)
    (au-mix! b (au-fnoise 0.06 :hp 3000 :decay 0.01) 0.0 0.6)
    (au-mix! b (au-fnoise 0.45 :bp 600 :to 200 :q 3 :decay 0.1) 0.01 0.5)
    (au-drive! b 1.5)))

(defsound :punch (:peak 0.95)
  (let ((b (au-buf 0.6)))
    (au-thump! b 0.0 95 32 0.07 0.2 1.0)
    (au-mix! b (au-drive! (au-fnoise 0.12 :lp 1500 :decay 0.03) 4) 0.0 0.9)
    (au-mix! b (au-fnoise 0.5 :lp 300 :decay 0.15) 0.0 0.5)
    (au-drive! b 1.8)))

(defsound :clang (:peak 0.8)
  (let ((b (au-buf 0.9)))
    (au-partials! b 0.0 '((710 1.0 0.28) (722 0.5 0.25) (1930 0.7 0.2) (3510 0.5 0.13)
                          (5800 0.35 0.09) (8400 0.2 0.05)))
    (au-mix! b (au-fnoise 0.03 :hp 3000 :decay 0.004) 0.0 1.2)
    (au-drive! b 1.3)))

(defsound :guard-break (:peak 0.95)
  (let ((b (au-buf 1.2)))
    (au-thump! b 0.0 120 40 0.06 0.2 0.9)
    (au-partials! b 0.0 '((560 0.8 0.3) (1490 0.6 0.22) (2870 0.5 0.15)))
    (dotimes (i 30)                                     ; glassy shards
      (au-ping! b (au-rrange 0.0 0.5) (au-rrange 2500 9000) (au-rrange 0.01 0.05) (* 0.3 (- 1.0 (/ i 34.0)))))
    (au-mix! b (au-fnoise 0.4 :hp 2000 :decay 0.08) 0.0 0.6)
    (au-reverb! b 0.25)))

(defsound :breaker-hum (:peak 0.5 :loop t)
  ;; 1 s loop (+0.4 s for the crossfade): a pink, beating electric hum
  (let ((b (au-buf 1.4)))
    (au-render (b) ((p1 0.0) (p2 0.0) (p3 0.0))
      (au-ph+ p1 110.0) (au-ph+ p2 111.5) (au-ph+ p3 330.0)
      (* (+ 0.8 (* 0.2 (au-sin (* 6.0 tt)))) (+ (* 0.4 (au-saw p1)) (* 0.4 (au-saw p2)) (* 0.2 (au-sin p3)))))
    (au-svf! b :lp :from 1400 :q 2.0)
    (au-mix! b (au-svf! (au-noise 1.4 :hold 1.4 :decay 1.0) :bp :from 3000 :q 2) 0.0 0.05)
    (au-fold b (round (* 1.0 +au-rate+)) t)))

(defsound :clash (:peak 0.95)
  (let ((b (au-buf 1.4)))
    (au-partials! b 0.0 '((880 1.0 0.5) (893 0.6 0.45) (2430 0.7 0.35) (4750 0.4 0.22) (7860 0.25 0.12)))
    (au-thump! b 0.0 80 30 0.1 0.35 1.0)
    (au-mix! b (au-fnoise 0.6 :lp 400 :decay 0.2) 0.0 0.7)
    (dotimes (i 20) (au-ping! b (au-rrange 0.02 0.6) (au-rrange 3000 9000) (au-rrange 0.02 0.06) 0.3))
    (au-drive! b 1.4)
    (au-reverb! b 0.3 :size 1.1)))

;;; ---------------------------------------------------------------- movement
(defsound :step (:peak 0.5)
  (let ((b (au-whoosh 0.22 500 2200 :q 1.3 :peak 0.06)))
    (au-thump! b 0.16 110 70 0.02 0.03 0.4)))

(defsound :hoho-out (:peak 0.6)
  (let ((b (au-whoosh 0.28 1500 8000 :q 2.0 :peak 0.05)))
    (au-ping! b 0.0 1800 0.08 0.4 :glide 2.0)))

(defsound :hoho-in (:peak 0.7)
  (let ((b (reverse (au-whoosh 0.25 1500 7000 :q 2.0 :peak 0.05))))
    (au-thump! b 0.22 160 80 0.02 0.05 0.8)
    (au-mix! b (au-fnoise 0.05 :hp 4000 :decay 0.01) 0.22 0.5)))

(defsound :perfect (:peak 0.8)
  (let ((b (au-buf 1.4)))
    (au-partials! b 0.0 '((1318 1.0 0.5) (2637 0.5 0.4) (3951 0.3 0.3)))
    (au-partials! b 0.08 '((1976 0.9 0.6) (3951 0.4 0.45) (5927 0.2 0.3)))
    (au-reverb! b 0.4 :size 1.2)))

(defsound :launch (:peak 0.8)
  (let ((b (au-whoosh 0.4 300 2400 :q 1.2 :peak 0.08)))
    (au-thump! b 0.0 130 60 0.05 0.08 1.0)))

(defsound :land (:peak 0.75)
  (let ((b (au-buf 0.35)))
    (au-thump! b 0.0 85 40 0.05 0.08 1.0)
    (au-mix! b (au-fnoise 0.25 :lp 900 :decay 0.05) 0.0 0.7)
    (au-mix! b (au-fnoise 0.2 :hp 2500 :decay 0.05) 0.005 0.25)))

;;; ---------------------------------------------------------------- fire
(defun snd-fire-noise (secs lo hi &key (decay 0.3) (attack 0.02) (hold 0.0))
  "Roaring flame body: noise band-limited to LO..HI Hz with a slow random flutter."
  (let ((b (au-noise secs :attack attack :hold hold :decay decay)) (m 0.5) (target 0.5))
    (declare (type f32vec b) (single-float m target))
    (au-svf! b :lp :from hi)
    (au-svf! b :hp :from lo)
    (dotimes (i (length b) b)
      (when (zerop (mod i 1200)) (setf target (+ 0.55 (* 0.45 (au-rnd)))))
      (setf m (+ m (* 0.002 (- target m)))
            (aref b i) (* m (aref b i))))))

(defsound :fire-whoosh (:peak 0.75)
  (let ((b (au-whoosh 0.6 200 2500 :q 0.8 :peak 0.2)))
    (au-mix! b (snd-fire-noise 0.6 80 900 :attack 0.08 :decay 0.2) 0.0 0.8)))

(defsound :fire-roar (:peak 0.9)
  (let ((b (snd-fire-noise 1.4 50 1400 :attack 0.15 :hold 0.4 :decay 0.35)))
    (au-mix! b (au-whoosh 1.3 150 700 :q 0.8 :peak 0.4) 0.0 0.8)
    (dotimes (i 40) (au-mix! b (au-fnoise 0.03 :hp 2500 :decay 0.004) (au-rrange 0.0 1.2) (au-rrange 0.1 0.35)))
    (au-drive! b 1.6)))

(defsound :fire-crackle (:peak 0.45 :loop t)
  ;; 2 s loop (+0.5 s for the crossfade): soft roar bed + random pops
  (let ((b (au-buf 2.5)))
    (au-mix! b (au-normalize! (snd-fire-noise 2.5 60 700 :hold 2.5 :decay 1.0) 0.35) 0.0 1.0)
    (dotimes (i 70)
      (au-mix! b (au-fnoise 0.03 :bp (au-rrange 1500 6000) :q 1.5 :decay (au-rrange 0.002 0.008))
               (au-rrange 0.0 2.45) (au-rrange 0.15 0.6)))
    (au-fold b (* 2 +au-rate+) t)))

(defsound :fire-wave (:peak 0.9)
  (let ((b (snd-fire-noise 1.3 40 1000 :attack 0.05 :hold 0.3 :decay 0.35)))
    (au-mix! b (au-whoosh 1.2 120 1800 :q 0.9 :peak 0.25) 0.0 0.9)
    (au-thump! b 0.0 70 35 0.2 0.3 0.5)
    (au-drive! b 1.5)))

(defsound :explode (:peak 0.95)
  (let ((b (au-buf 1.5)))
    (au-thump! b 0.0 70 22 0.25 0.45 1.0)
    (au-mix! b (au-drive! (au-fnoise 0.25 :lp 3000 :decay 0.05) 5) 0.0 0.8)
    (au-mix! b (snd-fire-noise 1.5 30 800 :attack 0.01 :decay 0.4) 0.0 0.9)
    (dotimes (i 16) (au-mix! b (au-fnoise 0.05 :bp (au-rrange 1500 5000) :q 2 :decay 0.01) (au-rrange 0.05 0.9) 0.2))
    (au-drive! b 1.6)
    (au-reverb! b 0.2 :size 1.2)))

(defsound :sizzle (:peak 0.7)
  (let ((b (au-fnoise 0.8 :hp 3500 :to 6000 :attack 0.005 :hold 0.1 :decay 0.2)))
    (au-thump! b 0.0 200 90 0.03 0.05 0.5)
    (au-mix! b (au-fnoise 0.6 :bp 1200 :q 4 :decay 0.1) 0.0 0.3)))

(defsound :heat-flare (:peak 0.85)
  (let ((b (au-fnoise 1.2 :hp 2200 :to 5000 :attack 0.02 :hold 0.25 :decay 0.55)))
    (au-thump! b 0.0 90 35 0.12 0.3 1.0)
    (au-mix! b (snd-fire-noise 0.9 60 600 :attack 0.04 :decay 0.35) 0.0 0.45)
    (au-drive! b 1.3)))

(defsound :ground-crack (:peak 0.95)
  (let ((b (au-buf 1.3)))
    (au-thump! b 0.0 60 25 0.15 0.4 1.0)
    (dotimes (i 24)                                    ; splitting stone: dry clicks + crunches
      (au-mix! b (au-fnoise 0.06 :bp (au-rrange 400 2500) :q 2 :decay (au-rrange 0.005 0.02))
               (* (/ i 24.0) (au-rrange 0.6 0.9)) (au-rrange 0.3 0.7)))
    (au-mix! b (au-fnoise 1.2 :lp 250 :decay 0.4) 0.0 0.6)
    (au-drive! b 1.5)))

(defsound :bones (:peak 0.75)
  (let ((b (au-buf 0.8)))
    (dotimes (i 22)                                    ; hollow wooden knocks
      (let ((at (au-rrange 0.0 0.6)) (f (au-rrange 700 1600)))
        (au-ping! b at f 0.02 0.6)
        (au-ping! b at (* f 2.7) 0.012 0.3)))
    (au-mix! b (au-fnoise 0.7 :bp 900 :q 1.2 :decay 0.2) 0.0 0.2)
    b))

;;; ---------------------------------------------------------------- Kikon, Konpaku, awakening
(defsound :kikon-slash (:peak 0.95)
  ;; reverse swell leads in; the cut lands at 0.35 s
  (let* ((b (au-buf 1.5)) (hit 0.35)
         (swell (reverse (au-reverb! (au-fnoise 0.9 :bp 1500 :q 0.8 :decay 0.03) 1.0 :size 1.3 :fb 0.85))))
    (au-mix! b (au-normalize! swell 0.6) (- hit (/ (length swell) (float +au-rate+))))
    (au-mix! b (au-whoosh 0.3 600 7000 :q 1.2 :peak 0.05) (- hit 0.05) 0.8)
    (au-partials! b hit '((2600 0.5 0.3) (4100 0.4 0.25) (6300 0.3 0.15)))
    (au-thump! b hit 80 28 0.2 0.35 1.0)
    (au-mix! b (au-drive! (au-fnoise 0.2 :lp 2500 :decay 0.04) 4) hit 0.6)
    (au-reverb! b 0.25 :size 1.3)))

(defsound :konpaku-shatter (:peak 0.85)
  (let ((b (au-buf 1.0)))
    (au-partials! b 0.0 '((1780 0.6 0.25) (2950 0.5 0.2) (4600 0.4 0.15)))
    (dotimes (i 36)
      (au-ping! b (au-rrange 0.0 0.35) (au-rrange 3000 11000) (au-rrange 0.008 0.04) (* 0.35 (- 1.0 (/ i 40.0)))))
    (au-mix! b (au-fnoise 0.3 :hp 5000 :decay 0.05) 0.0 0.7)
    (au-reverb! b 0.3)))

(defsound :awaken-boom (:peak 0.95)
  (let ((b (au-buf 1.5)))
    (au-thump! b 0.0 55 20 0.3 0.6 1.0)
    (au-taiko! b 0.0 0.8 60)
    (au-gong! b 0.02 98 0.45 0.8)
    (au-mix! b (au-fnoise 1.2 :lp 200 :decay 0.5) 0.0 0.6)
    (au-drive! b 1.4)))

(defsound :awaken-rise (:peak 0.85)
  (let ((b (au-buf 1.5)) (pad (au-buf 1.5)))
    (au-render (pad) ((p1 0.0) (p2 0.0))
      (let ((f (au-sweep tt 55.0 220.0 1.4)))
        (au-ph+ p1 f) (au-ph+ p2 (* 1.502 f))
        (* (* tt tt 0.45) (+ (au-saw p1) (* 0.6 (au-saw p2))))))
    (au-svf! pad :lp :from 300 :to 5000 :q 1.5 :time 1.4)
    (au-mix! b pad 0.0 0.8)
    (au-mix! b (au-whoosh 1.5 300 6000 :q 1.0 :peak 1.4) 0.0 0.5)
    b))

(defsound :evolution (:peak 0.7)
  (let ((b (au-buf 0.9)))
    (loop for f in '(880 1318 1760 2637) for i from 0
          do (au-ping! b (* i 0.06) f 0.2 0.6 :attack 0.003))
    (au-reverb! b 0.35)))

(defsound :laugh (:peak 0.8)
  ;; "ha-ha-ha": four formant-filtered saw bursts, falling in pitch (no recorded voice)
  (let ((b (au-buf 1.3)))
    (loop for at in '(0.0 0.22 0.44 0.68) for f in '(150.0 142.0 136.0 124.0)
          do (let ((g (au-buf 0.26)) (f f))
               (declare (single-float f))
               (au-render (g) ((ph 0.0))
                 (au-ph+ ph (* f (+ 1.0 (* 0.05 (au-sin (* 18.0 tt))))))
                 (* (au-ar tt 0.02 0.07) (+ (au-saw ph) (* 0.3 (au-rnd)))))
               (let ((f1 (au-svf! (copy-seq g) :bp :from 750 :q 5)) (f2 (au-svf! (copy-seq g) :bp :from 1200 :q 6)))
                 (au-mix! b f1 at 1.0) (au-mix! b f2 at 0.6))))
    (au-drive! b 1.5)
    (au-reverb! b 0.15)))

(defsound :gulp (:peak 0.75)
  (let ((b (au-buf 0.45)))
    (au-thump! b 0.0 120 55 0.05 0.14 1.0)
    (au-mix! b (au-fnoise 0.18 :bp 420 :q 3 :decay 0.06) 0.03 0.6)
    (au-mix! b (au-fnoise 0.12 :bp 900 :q 5 :decay 0.03) 0.12 0.35)
    b))

(defsound :arm-crack (:peak 0.8)
  (let ((b (au-buf 0.5)))
    (dotimes (i 8)                                     ; the creak: low dry clicks
      (au-mix! b (au-fnoise 0.05 :bp (au-rrange 180 500) :q 4 :decay (au-rrange 0.01 0.03)) (* i 0.03) (au-rrange 0.4 0.7)))
    (au-mix! b (au-fnoise 0.08 :bp 2200 :q 1.5 :decay 0.02) 0.26 1.0)   ; the crack
    (au-thump! b 0.26 140 60 0.04 0.1 0.8)
    b))

(defsound :arm-burst (:peak 0.95)
  (let ((b (au-buf 1.0)))
    (au-thump! b 0.0 90 35 0.1 0.3 1.0)
    (au-mix! b (au-fnoise 0.15 :bp 1800 :q 1.2 :decay 0.04) 0.0 0.9)
    (dotimes (i 14)                                    ; the spray
      (au-mix! b (au-fnoise 0.04 :bp (au-rrange 600 3000) :q 2 :decay 0.015) (au-rrange 0.02 0.4) (au-rrange 0.2 0.5)))
    (au-mix! b (au-fnoise 0.6 :lp 700 :decay 0.25) 0.03 0.5)
    (au-drive! b 1.6)))

(defsound :yachiru-call (:peak 0.7)
  (let ((b (au-buf 1.2)))                              ; two voices a few cents apart, each note doubled: the multiplicity
    (loop for (at f) in '((0.0 1318) (0.0 1396) (0.18 1760) (0.18 1864) (0.36 1318) (0.36 1245))
          do (au-ping! b at f 0.18 0.5 :attack 0.02))
    (au-reverb! b 0.45 :size 1.4)))

;;; ---------------------------------------------------------------- Rukia's ice (docs/DUEL_RUKIA.md §10)
(defsound :frost-tick (:peak 0.6)
  (let ((b (au-buf 0.5)))
    (au-ping! b 0.0 3520 0.08 0.7 :attack 0.001)
    (au-ping! b 0.01 5270 0.05 0.4 :attack 0.001)
    (au-mix! b (au-fnoise 0.06 :hp 7000 :decay 0.02) 0.0 0.4)
    (au-reverb! b 0.3 :size 1.2)))

(defsound :freeze (:peak 0.85)
  (let ((b (au-buf 0.8)))
    (dotimes (i 26)                                    ; the crackle, tightening
      (au-mix! b (au-fnoise 0.03 :bp (au-rrange 2500 9000) :q 3 :decay (au-rrange 0.004 0.012)) (* 0.3 (sqrt (/ i 26.0)))
               (au-rrange 0.3 0.7)))
    (au-partials! b 0.3 '((2093 0.5 0.3) (3136 0.4 0.25) (4186 0.3 0.2)))   ; the lock: a hard glassy chord
    (au-thump! b 0.3 180 90 0.02 0.08 0.5)
    (au-reverb! b 0.25)))

(defsound :ice-rise (:peak 0.85)
  (let ((b (au-buf 1.4)))
    (au-mix! b (au-whoosh 1.0 400 9000 :q 1.4 :peak 0.9) 0.0 0.6)
    (loop for f in '(1760 2637 3520) for i from 0
          do (au-ping! b (* 0.12 i) f 0.5 0.35 :attack 0.05))
    (au-gong! b 0.0 196 0.4 1.2)
    (au-reverb! b 0.35 :size 1.3)))

(defsound :ice-shatter (:peak 0.9)
  (let ((b (au-buf 1.0)))
    (au-mix! b (au-fnoise 0.12 :hp 3000 :decay 0.04) 0.0 0.9)
    (dotimes (i 40)
      (au-ping! b (au-rrange 0.0 0.5) (au-rrange 2500 10000) (au-rrange 0.01 0.05) (* 0.4 (- 1.0 (/ i 45.0)))))
    (au-thump! b 0.0 120 50 0.05 0.12 0.6)
    (au-reverb! b 0.3)))

(defsound :hand-crack (:peak 0.7)
  (let ((b (au-buf 0.4)))
    (au-mix! b (au-fnoise 0.05 :bp 3200 :q 2 :decay 0.012) 0.0 1.0)
    (au-mix! b (au-fnoise 0.04 :bp 1800 :q 3 :decay 0.01) 0.05 0.6)
    (au-ping! b 0.02 4700 0.03 0.3)
    b))

(defsound :rift-open (:peak 0.6)
  (let ((b (au-buf 0.7)))
    (au-mix! b (au-whoosh 0.5 1800 9000 :q 2.0 :peak 0.35) 0.0 0.7)
    (au-partials! b 0.05 '((3100 0.3 0.4) (4700 0.2 0.3)))
    (au-reverb! b 0.2)))

(defsound :rift-cut (:peak 0.9)
  (let ((b (au-buf 0.8)))
    (au-mix! b (au-whoosh 0.2 800 8000 :q 1.2 :peak 0.03) 0.0 0.8)
    (au-partials! b 0.03 '((2400 0.5 0.25) (5200 0.35 0.15)))
    (au-thump! b 0.03 90 30 0.1 0.2 0.8)
    (au-reverb! b 0.2)))

(defsound :tier-up (:peak 0.85)
  (let ((b (au-buf 1.0)))
    (au-taiko! b 0.0 0.8 70)
    (au-mix! b (au-whoosh 0.6 300 5000 :q 1.0 :peak 0.5) 0.0 0.5)
    (au-drive! b 1.3)))

;;; ---------------------------------------------------------------- stingers and menus
(defsound :bell (:peak 0.8)
  (let ((b (au-buf 1.5)))
    (au-partials! b 0.0 '((196 1.0 1.2) (392 0.5 0.9) (466 0.35 0.7) (587 0.4 0.6) (784 0.3 0.45) (1046 0.2 0.3))
                  :glide 0.998)
    (au-mix! b (au-fnoise 0.05 :lp 1200 :decay 0.01) 0.0 0.4)
    b))

(defsound :fight (:peak 0.95)
  (let ((b (au-buf 1.5)))
    (au-taiko! b 0.0 1.0 72)
    (au-taiko! b 0.16 0.9 90)
    (au-gong! b 0.16 110 0.5 0.7)
    (au-reverb! b 0.25 :size 1.1)))

(defsound :ko (:peak 0.95)
  (let ((b (au-buf 1.5)))
    (au-taiko! b 0.0 1.0 60)
    (au-thump! b 0.0 50 22 0.3 0.5 0.8)
    (au-gong! b 0.0 73 0.7 1.0)
    (au-reverb! b 0.35 :size 1.3)))

(defsound :select (:peak 0.35)
  (let ((b (au-buf 0.08)))
    (au-ping! b 0.0 2200 0.012 1.0)
    (au-ping! b 0.0 3300 0.008 0.3)))

(defsound :confirm (:peak 0.5)
  (let ((b (au-buf 0.35)))
    (au-ping! b 0.0 880 0.05 1.0 :attack 0.002)
    (au-ping! b 0.06 1318 0.09 1.0 :attack 0.002)
    (au-ping! b 0.06 2637 0.05 0.3)))

(defsound :back (:peak 0.45)
  (let ((b (au-buf 0.25)))
    (au-ping! b 0.0 1318 0.04 1.0 :attack 0.002)
    (au-ping! b 0.05 880 0.07 1.0 :attack 0.002)))

;;; ---------------------------------------------------------------- music
(defsound :music (:peak 0.8 :loop t)
  ;; 100 BPM, 8 bars of 16ths = 128 steps x 0.15 s = 19.2 s, D phrygian (D Eb F G A Bb C)
  (let* ((step 0.15) (n (round (* 128 step +au-rate+))) (len 21.7)
         (b (au-buf len)) (bass (au-buf len)) (lead (au-buf len))
         (kick (au-buf 0.5)) (hat (au-fnoise 0.06 :hp 7000 :decay 0.012))
         (rim (au-fnoise 0.05 :bp 2500 :q 2 :decay 0.008))
         (roots '(38 39 38 36)))                         ; D2 Eb2 D2 C2, two bars each
    (au-thump! kick 0.0 150 45 0.05 0.18 1.0)
    (au-ping! rim 0.0 1600 0.02 0.8)
    ;; drums: taiko on the downbeats, driving kick, rims, hats
    (dotimes (s 128)
      (let ((bar (floor s 16)) (p (mod s 16)) (at (* s step)))
        (when (member p '(0 3 8 11)) (au-mix! b kick at (if (member p '(0 8)) 0.9 0.6)))
        (when (= p 0) (au-taiko! b at 1.0 (if (evenp bar) 68 76)))
        (when (and (= p 10) (oddp bar)) (au-taiko! b at 0.6 90))
        (when (and (= bar 7) (member p '(12 13 14 15))) (au-taiko! b at (+ 0.5 (* 0.1 (- p 12))) 100))
        (when (member p '(4 12)) (au-mix! b rim at 0.55))
        (when (evenp p) (au-mix! b hat at (if (member p '(2 6 10 14)) 0.3 0.15)))))
    ;; low saws: the root and a fifth, swelling per bar pair
    (loop for r in roots for i from 0 do
      (let ((f (au-midi r)))
        (au-saws! bass (* i 32 step) 4.6 (list f (* 1.5 f) (* 2 f)) 1.0 :a 0.3 :r 0.5)))
    (au-svf! bass :lp :from 380 :q 1.2)
    (let ((bass bass))                                  ; pump after every beat
      (declare (type f32vec bass) (optimize (speed 3) (safety 0)))
      (dotimes (i (length bass))
        (let ((sb (* 0.6 (au-frac (* (i->f i) +au-dt+ (/ 1.0 0.6))))))
          (declare (single-float sb))
          (setf (aref bass i) (* (aref bass i) (- 1.0 (* 0.5 (au-env-exp sb 0.12))))))))
    (au-mix! b (au-normalize! bass) 0.0 0.6)
    ;; shakuhachi lead: (step length-in-steps midi)
    (loop for (s l m) in '((0 6 62) (6 2 63) (8 8 65) (20 4 67) (24 8 65) (32 4 63) (36 4 62) (40 14 62)
                           (64 3 69) (67 3 70) (70 10 69) (84 4 67) (88 8 65) (96 6 63) (102 2 65) (104 16 62))
          do (au-shaku! lead (* s step) (* l step) (au-midi m) 0.5))
    (au-delay! lead (* 3 step) 0.3 0.25)
    (au-reverb! lead 0.5 :size 1.3 :fb 0.82)
    (au-mix! b (au-normalize! lead) 0.0 0.45)
    (au-fold b n)))

(defsound :music-title (:peak 0.7 :loop t)
  ;; 60 BPM, 4 bars = 16 s: gong swells, koto-ish plucks over a soft pad, a slow shakuhachi line
  (let* ((beat 1.0) (n (* 16 +au-rate+)) (len 18.5)
         (b (au-buf len)) (pad (au-buf len)) (pluck (au-buf len)) (lead (au-buf len)))
    (au-gong! b 0.0 73 0.6 1.3)
    (au-gong! b 8.0 82 0.45 1.2)
    (au-taiko! b 0.0 0.5 60) (au-taiko! b 8.0 0.4 60)
    (au-saws! pad 0.0 8.4 (mapcar #'au-midi '(50 57 62 65)) 1.0 :a 1.5 :r 1.5)
    (au-saws! pad 8.0 8.4 (mapcar #'au-midi '(48 55 60 64)) 1.0 :a 1.5 :r 1.5)
    (au-svf! pad :lp :from 900 :q 0.9)
    (au-mix! b (au-normalize! pad) 0.0 0.35)
    ;; koto-ish: a bright decaying saw pluck, (beat midi) in D minor pentatonic
    (loop for (bt m) in '((0 62) (0.5 69) (1 74) (2 72) (2.5 69) (3 67) (4 62) (4.5 65) (5 69) (6 67) (7 65)
                          (8 60) (8.5 67) (9 72) (10 70) (10.5 67) (11 65) (12 62) (12.5 65) (13 69) (14 74) (15 72))
          do (let ((note (au-buf 1.2)) (f (au-midi m)))
               (declare (single-float f))
               (au-render (note) ((ph 0.0)) (au-ph+ ph f) (* (au-ar tt 0.002 0.35) (au-saw ph)))
               (au-svf! note :lp :from 4000 :to 600 :q 1.5 :time 0.6)
               (au-mix! pluck note (* bt beat) 0.35)))
    (au-delay! pluck 0.75 0.3 0.3)
    (au-mix! b pluck 0.0 0.6)
    (loop for (bt l m) in '((1 3 74) (4 2 72) (6 2 69) (8.5 3 67) (12 1.5 69) (13.5 2 62))
          do (au-shaku! lead (* bt beat) (* l beat) (au-midi m) 0.5 :vib 0.018))
    (au-reverb! lead 0.55 :size 1.4 :fb 0.84)
    (au-mix! b (au-normalize! lead) 0.0 0.4)
    (au-fold b n)))
