(in-package :duel)
;;; ================================================================ Kuchiki Rukia (docs/duel/DUEL_RUKIA.md)
(let ((b (kit :rukia :base)) (m18 (kit :rukia :m18)) (m50 (kit :rukia :m50)) (z (kit :rukia :zero)))
  ;; frost: max, not a sum; capped; x0.7 on walk / run only while it lasts
  (check (and (= 90 (frost-next 60 90)) (= 90 (frost-next 90 60)) (= *frost-cap* (frost-next 140 400)) (= 150 *frost-cap*)
              (~= (frost-speed 3.8 1) (* 3.8 *frost-slow*)) (~= (frost-speed 3.8 0) 3.8) (~= *frost-slow* 0.7)))
  ;; the cold gauge (two stacked bars, the user's decision 2026-09-28): guarding cools *RU-COOL-RATE*/s, not guarding warms
  ;; at the band's rate, clamped 0 .. 200
  (check (and (~= 200.0 *cold-max*) (~= 100.0 *cold-bar*) (~= 1.5 (temp-next 0.0 t 10.0)) (~= 200.0 (temp-next 199.5 t 10.0))
              (~= 0.0 (temp-next 0.1 nil 10.0)) (~= (- 150.0 (/ 12.0 60)) (temp-next 150.0 nil 12.0))))
  ;; the bands with hysteresis by bars: -18 -> -50 at 100, back at 0; -50 -> zero at 200, back at 100; several at once
  (check (and (eq :m18 (temp-band 99.9 :m18)) (eq :m50 (temp-band 100.0 :m18)) (eq :m50 (temp-band 0.5 :m50))
              (eq :m18 (temp-band 0.0 :m50)) (eq :m50 (temp-band 199.0 :m50)) (eq :zero (temp-band 200.0 :m50))
              (eq :zero (temp-band 100.5 :zero)) (eq :m50 (temp-band 100.0 :zero)) (eq :m18 (temp-band 0.0 :zero))
              (eq :zero (temp-band 200.0 :m18)) (eq :m50 (temp-band 150.0 :m50))))
  ;; the pacing (§1): guarding from -18 reaches zero in 134 f (2.2 s; the user's decision 2026-09-28: cool faster); a bar
  ;; of -50 warms out in ~8 s, one of
  ;; -18 in 10 s; zero's top bar in 20 s unbraced (the user's decision 2026-09-28: zero warms slowest, easier to hold)
  (flet ((walk (c band guarding warm)
           (loop for n from 1 to 2000 do (setf c (temp-next c guarding warm))
                 when (not (eq band (temp-band c band))) return n)))
    (check (and (= 67 (walk 0.0 :m18 t 0.0)) (= 67 (walk 100.0 :m50 t 0.0)) (= 67 (temp-cool-frames 0.0))
                (<= 1190 (walk 200.0 :zero nil (kit-warm z)) 1210) (<= 480 (walk 100.0 :m50 nil (kit-warm m50)) 520)
                (= 67 (temp-cool-frames 100.0)) (= 40 (temp-cool-frames 140.0)))))
  ;; the kit side: a :temp meter of 200 in every band, warming 10 / 12 / 5 (zero the slowest), reset to -18
  (check (and (eq (kit-awaken-form b) :m18) (every (lambda (k) (and (getf (kit-meter k) :temp) (~= 200.0 (getf (kit-meter k) :max)))) (list m18 m50 z))
              (> (kit-warm m50) (kit-warm m18) (kit-warm z)) (null (kit-meter b))
              (every (lambda (k) (eq (kit-reset-form k) :m18)) (list m18 m50 z)) (null (kit-reset-form b))
              (null (kit-duration z)) (kit-rooted z) (notany #'kit-rooted (list b m18 m50)) (eq 'rukia-crack (kit-crush-hook z))
              (null (kit-crush-hook m50)) (null (kit-drop-to z))))
  ;; spending (§3, rescaled): at -18 only L (refused below its cost); at -50 / zero everything; zero's L and SPs cash the
  ;; whole top bar (100: always back to -50); J / K cost the same whatever the link
  (check (and (equal (kit-cold m18) '(:sig 25)) (= 0 (getf (kit-cold m18) :q 0)) (= 0 (getf (kit-cold m18) :step 0))
              (every (lambda (c) (plusp (getf (kit-cold m50) c 0))) '(:q :f :sig :sp1 :sp2 :kikon :breaker :step))
              (= 0 (getf (kit-cold m50) :hoho 0)) (eq 'rukia-hoho-cold (kit-hook m50 :hoho)) (eq 'rukia-hoho-cold (kit-hook m18 :hoho))   ; a Hoho adds cold
              (eq :zero (temp-band (min *cold-max* (+ 150.0 *ru-hoho-cold*)) :m50)) (eq :m50 (temp-band (+ 60.0 *ru-hoho-cold*) :m18))
              (every (lambda (c) (>= (getf (kit-cold z) c 0) *cold-bar*)) '(:sig :sp1 :sp2))
              (< (getf (kit-cold m18) :sig) (getf (kit-cold m50) :sig) (getf (kit-cold z) :sig))
              (< (* 3 (getf (kit-cold z) :q)) *cold-bar*) (< (* 2 (getf (kit-cold z) :f)) *cold-bar*)))   ; zero's JJJ, KK fit its bar
  ;; the field (§4.1): only the away part of a walk is scaled; a side Step untouched, a back Step x :step; the floor
  (multiple-value-bind (vx vz) (field-velocity 2.0 0.0 1.0 0.0 0.55) (check (and (~= vx 1.1) (~= vz 0.0))))   ; straight away
  (multiple-value-bind (vx vz) (field-velocity -2.0 1.0 1.0 0.0 0.55) (check (and (~= vx -2.0) (~= vz 1.0))))  ; toward / strafe
  (multiple-value-bind (vx vz) (field-velocity 0.0 3.0 1.0 0.0 0.55) (check (and (~= vx 0.0) (~= vz 3.0))))   ; circling
  (check (and (~= 2.5 (field-step 2.5 0.0 0.75)) (~= (* 2.5 0.75) (field-step 2.5 -1.0 0.75)) (~= 2.5 (field-step 2.5 1.0 0.75))
              (< (* 2.5 0.75) (field-step 2.5 -0.5 0.75) 2.5)
              (~= (field-k 0.55 t) (/ *field-floor* *frost-slow*)) (~= (field-k 0.85 t) 0.85) (~= (field-k 0.55 nil) 0.55)
              (>= (* *frost-slow* (field-k 0.55 t)) (- *field-floor* 1e-4))))
  (check (and (< (getf (kit-field m18) :r) (getf (kit-field m50) :r) (getf (kit-field z) :r))
              (> (getf (kit-field m18) :away) (getf (kit-field m50) :away) (getf (kit-field z) :away))
              (null (kit-field b)) (~= (getf (kit-field z) :r) (getf (mv-params (kit-command-move z :sig)) :radius))))
  ;; colder is never weaker (the playtest fix, §4): damage x, frost on every hit, J / K reach, the L family (radius, damage),
  ;; SP1 / SP2 / O reach and damage grow band by band; -50 and zero take less
  (flet ((up (fn) (let ((v (mapcar fn (list m18 m50 z)))) (and (< (first v) (second v)) (< (second v) (third v)))))
         (sig (k key) (getf (mv-params (kit-command-move k :sig)) key)))
    (check (and (up #'kit-mult) (up #'kit-frost-touch) (up (lambda (k) (mv-reach (kit-command-move k :q))))
                (up (lambda (k) (mv-reach (kit-command-move k :f)))) (up (lambda (k) (sig k :radius))) (up (lambda (k) (sig k :dmg)))
                (up (lambda (k) (mv-reach (kit-command-move k :sp2)))) (up (lambda (k) (mv-dmg (kit-command-move k :sp2))))
                (up (lambda (k) (mv-reach (kit-command-move k :kikon))))
                (up (lambda (k) (getf (mv-params (kit-command-move k :sp1)) :dmg)))
                (> (kit-taken m18) (kit-taken m50) (kit-taken z))
                (~= 1.44 (mv-reach (kit-move m18 :ru-j1))) (~= 1.584 (mv-reach (kit-move m50 :ru-j1))) (~= 1.944 (mv-reach (kit-move z :ru-j1)))
                (~= 3.78 (mv-reach (kit-command-move z :f))) (~= 2.106 (mv-reach (kit-move z :ru-j3))) (~= 1.72 (mv-reach (kit-move m50 :ru-j3-50)))
                (~= 5.0 (mv-reach (kit-command-move m18 :sp2))) (~= 7.5 (mv-reach (kit-command-move z :sp2))))))
  ;; rooted zero: at zero no chase, so each follow-up link must still reach after a blocked link's push from where a J1
  ;; lands (the Shikai J1's reach): J2 >= J1 - *BLOCK-PUSHBACK* (the x1.35 reach covers the 0.6 m push)
  (let ((j1 (mv-reach (kit-move m18 :ru-j1))))
    (check (and (>= (+ (mv-reach (kit-move z :ru-z-j2)) 0.45) (+ j1 *block-pushback*))
                (>= (+ (mv-reach (kit-move z :ru-k2)) 0.45) (+ j1 *block-pushback*)))))
  ;; the moves each band has: L SHIMOBASHIRA / HYOSHIN / REIDO (no cooldown: the gauge is the limiter, no COOLDOWN row);
  ;; SP1 HAKUREN in every band (-50 faster stabs, zero no hold); no Breaker at zero; HAKKA in every band
  (check (and (eq :ru-shimobashira (mv-name (kit-command-move m18 :sig))) (eq :ru-hyoshin (mv-name (kit-command-move m50 :sig)))
              (eq :ru-reido (mv-name (kit-command-move z :sig))) (notany (lambda (k) (plusp (mv-cooldown (kit-command-move k :sig)))) (list m18 m50 z))
              (eq :ru-hakuren (mv-name (kit-command-move m18 :sp1))) (equal '(12 48) (mv-hold (kit-command-move m50 :sp1)))
              (null (mv-hold (kit-command-move z :sp1))) (null (kit-command-move z :breaker)) (kit-command-move m50 :breaker)
              (every (lambda (k) (eq 'ru-hakka-cine (mv-cine (kit-command-move k :kikon)))) (list m18 m50 z))
              (every (lambda (k) (null (kit-command-move k :step))) (list m18 m50 z))
              (eq (mv-name (kit-command-move m18 :f)) :ru-a-k1) (eq (mv-name (kit-next m18 :ru-k2 :f)) :ru-a-k3)
              (eq (mv-name (kit-next m50 :ru-j2 :q)) :ru-j3-50) (eq (mv-name (kit-next z :ru-j1 :q)) :ru-z-j2)
              (eq (mv-name (kit-next z :ru-k2 :f)) :ru-z-k3) (= 2 (kit-command-cost m18 :sp2)) (= 1 (kit-command-cost b :sp2))))
  ;; the passives: every band no chip; zero the ward, optic, freeze-touch
  (check (and (equal (kit-passives m18) '(:chipless)) (equal (kit-passives m50) '(:chipless))
              (equal (kit-passives z) '(:ward :freeze-touch :chipless)) (null (kit-passives b)) (= 0 (kit-frost-touch b))
              (~= *rukia-mult* (kit-mult b)) (~= *rukia-taken* (kit-taken b))))
  ;; optic: a ranged hit on the zero ward lands as on an open defender (the defender state :neutral), a melee one is blocked
  (check (and (optic-p t t t) (not (optic-p t t nil)) (not (optic-p nil t t)) (not (optic-p t nil t))
              (eq (resolve-contact (if (optic-p t t t) :neutral :guard) :hazard t) :hit)
              (eq (resolve-contact :guard :in-front nil :ward t) :blocked)))
  ;; walk / run by band (colder is slower; zero rooted)
  (check (and (~= (kit-walk b) 3.8) (~= (kit-run b) 9.0) (~= (kit-walk m18) 3.4) (~= (kit-run m18) 8.0) (~= (kit-walk m50) 2.8)
              (~= (kit-run m50) 6.4) (~= (kit-walk z) 0.0) (~= (kit-run z) 0.0)))
  ;; the Kikon counts: Shikai 2, every band 3; Soul Breaks 3 / 4; the cinematics
  (check (and (= 2 (kit-kikon-konpaku b)) (every (lambda (k) (= 3 (kit-kikon-konpaku k))) (list m18 m50 z))
              (= 3 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku b) t))) (= 4 (nth-value 1 (kikon-result 9 (kit-kikon-konpaku m18) t)))
              (eq 'ru-kikon-cine (kit-kikon-cine b)) (eq 'ru-hakka-cine (kit-kikon-cine m18)) (eq 'ru-hakka-cine (kit-kikon-cine z))
              (eq 'ru-awaken-cine (kit-cine m18))))
  ;; the reaches: ENBU 8.0 m in <= 30 f; HAKKA's lane 6.5 / 7.5 / 9.0, no dash; J1 S7 beats every K1 in the game
  (let ((en (kit-command-move b :kikon)))
    (check (and (~= 8.0 (kikon-rush-reach (getf (mv-params en) :speed) (getf (mv-params en) :dash-max))) (= 30 (+ (getf (mv-params en) :aura) (getf (mv-params en) :dash-max) (mv-s en)))
                (equal '(6.5 7.5 9.0) (mapcar (lambda (k) (mv-reach (kit-command-move k :kikon))) (list m18 m50 z)))
                (zerop (getf (mv-params (kit-command-move z :kikon)) :dash-max)) (= 7 (mv-s (kit-command-move b :q)))
                (< (mv-s (kit-command-move b :q)) (min (mv-s (mv :yamamoto :base :ya-k1)) (mv-s (mv :kenpachi :base :ke-k1)))))))
  ;; fairness: TSUKISHIRO's circle + Kenpachi's hurt radius < a Step; every HAKUREN's widest half-width + his hurt radius
  ;; < a Step (a side Step clears every wave, never shortened by the field); the ring's tell 24 f, one ring at a time (no
  ;; cooldown since 2026-09-29: the move outlasts its pillar)
  ;; (TSUKISHIRO: L held since 2026-10-24, the Shikai's :hold string off BYAKURAI; HAKUREN: the bands' SP1 only)
  (let* ((ts (kit-next b :ru-byakurai :hold)) (pa (mv-params ts)))
    (check (and (< (+ (getf pa :radius) 0.45) *step-distance*) (= 24 (getf pa :delay)) (> (mv-total ts) (+ (mv-s ts) (getf pa :delay)))
                (member :bind (mv-flags ts)) (equal (getf pa :tell) '(21 30))
                (every (lambda (k) (let ((hp (mv-params (kit-command-move k :sp1))))
                                     (< (+ (* 0.5 (+ (getf hp :width) (* 3 (getf hp :width-per)))) 0.45) *step-distance*)))
                       (list m18 m50 z))
                (equal (mv-hold (kit-command-move m18 :sp1)) '(16 64))
                (= 130 (let ((hp (mv-params (kit-command-move m18 :sp1)))) (+ (getf hp :dmg) (* 3 (getf hp :dmg-per))))))))
  ;; frost on the hits: no frost timer in the Shikai since 2026-10-24 (its K links lay 霜の層 instead); the bands' own
  (flet ((fr (k n) (hw-frost (svref (mv-hits (kit-move k n)) 0))))
    (check (and (= 0 (fr b :ru-k1)) (= 0 (fr b :ru-sk2)) (= 0 (fr b :ru-sk2s)) (= 0 (fr b :ru-k3)) (= 0 (fr b :ru-j1))
                (= 0 (fr b :ru-shirafune-s)) (= 0 (fr b :ru-kikon)) (= 0 (getf (mv-params (kit-next b :ru-byakurai :hold)) :frost))
                (= 60 (fr m18 :ru-k2)) (= 150 (fr m18 :ru-shirafune))
                (= 90 (fr m18 :ru-a-k1)) (= 120 (fr m18 :ru-a-k3)) (= 120 (fr m18 :ru-hakka-18)) (= 150 (fr z :ru-z-k3)))))
  ;; the route damage on hit (before multipliers): KKK 208, JJJ 110, the O ender 63
  (flet ((dmg (&rest names) (loop for n in names for i from 1 sum (hit-damage (mv-dmg (kit-move b n)) nil nil i nil))))
    (check (and (= 110 (dmg :ru-j1 :ru-j2 :ru-j3)) (= 208 (dmg :ru-k1 :ru-sk2 :ru-k3)) (= 60 (hit-damage 70 nil nil 4 nil)))))
  ;; the looks and the HUD: the body variants, the blades, the hidden tags, the U tags, the band names
  (check (and (eq :rukia (kit-body b)) (eq :rukia (kit-body m50)) (eq :rukia-zero (kit-body z))
              (equal '(:sode-no-shirayuki :ru-rime :ru-ice) (mapcar #'kit-weapon (list m18 m50 z)))
              (not (member :ice-trim (kit-hide m50))) (member :ice-trim (kit-hide m18)) (member :hand-crack (kit-hide z))
              (equal (mapcar #'kit-u-tag (list m18 m50 z)) '("U: COOL" "U: COOL" "U: BRACE"))
              (equal (mapcar #'kit-form-name (list m18 m50 z)) '("-18C" "-50C" "-273C")))))

;; L after a K link (the kit's :l-after-k, docs/duel/DUEL_STRINGS.md §12, the user's decision 2026-09-28): every K link of
;; every awakened band (K1 K2 K2s K3) has one, the band's own L, and no J link; on hit it combos: from the K link's hit its
;; A + the L's hit frame (the last :on-frame hook + a hazard's :delay) < the K link's hitstun. The Shikai's since
;; 2026-10-24: the bursts below (no other character's kit names :l-after-k but the ones listed)
(flet ((l-hit (l) (+ (first (car (last (mv-on-frame l)))) (or (getf (mv-params l) :delay) 0))))
  (dolist (form '(:m18 :m50 :zero))
    (let* ((k (kit :rukia form)) (ks (remove-if-not (lambda (l) (eq :f (car (last (third l))))) (link-moves k))))
      (check (= 4 (length (remove-duplicates (mapcar #'first ks)))))
      (dolist (l ks)
        (let* ((m (first l)) (lm (kit-l-link k (mv-name m))) (w (svref (mv-hits m) 0)))
          (check (and lm (eq (mv-kind lm) :sig)))
          (check (< (+ (- (mv-s m) (hw-from w)) (mv-a m) (l-hit lm)) (hitstun (hw-react w))))))
      (check (notany (lambda (l) (and (eq :q (car (last (third l)))) (kit-l-link k (mv-name (first l)))))
                     (link-moves k)))))
  (check (every (lambda (f) (eq (kit-l-link (kit :rukia f) :ru-k2) (kit-command-move (kit :rukia f) :sig))) '(:m18 :m50 :zero)))
  (check (every (lambda (cf) (null (kit-l-after-k (apply #'kit cf)))) (remove-if (lambda (c) (member c '(:rukia :ichigo :senjumaru :lille :barro))) *forms* :key #'first))))

;; ================================================================ the Shikai's 霜の層 (DUEL_RUKIA_TYBW §4.1-§4.4, the user 2026-10-24)
;; the layers (rules): +n capped at 3; one thaws per *RU-THAW* (150) frames without a new one (the timer back to 0 at each);
;; walk / run x 0.85 / 0.70 / 0.55; the bursts' count: link n up to n, link 3 all; a burst never off a block, at the chain
;; only with a layer (0 layers: the L is not taken)
(check (and (= 3 *ru-layer-max*) (= 150 *ru-thaw*) (= 1 (layers-add 0 1)) (= 3 (layers-add 2 2)) (= 3 (layers-add 3 1)) (= 2 (layers-add 0 2))
            (~= (layer-speed 3.8 0) 3.8) (~= (layer-speed 3.8 1) (* 3.8 0.85)) (~= (layer-speed 3.8 2) (* 3.8 0.7))
            (~= (layer-speed 9.0 3) (* 9.0 0.55)) (eql 3.8 (layer-speed 3.8 0))
            (equal '(1 1 1 0) (mapcar (lambda (n) (burst-count 1 n)) '(3 2 1 0)))
            (equal '(2 2 1 0) (mapcar (lambda (n) (burst-count 2 n)) '(3 2 1 0)))
            (equal '(3 2 1 0) (mapcar (lambda (n) (burst-count 3 n)) '(3 2 1 0)))
            (layer-burst-ok-p nil 0) (layer-burst-ok-p nil 2) (layer-burst-ok-p :hit 1) (not (layer-burst-ok-p :hit 0))
            (not (layer-burst-ok-p :block 3))))
(flet ((thaw-run (layers thaw n) (dotimes (i n (list layers thaw)) (multiple-value-setq (layers thaw) (layers-thaw layers thaw)))))
  (check (and (equal '(3 149) (thaw-run 3 0 149)) (equal '(2 0) (thaw-run 3 0 150)) (equal '(0 0) (thaw-run 3 0 450))
              (equal '(1 0) (thaw-run 3 0 300)) (equal '(0 0) (thaw-run 0 0 10)) (equal '(2 0) (thaw-run 3 140 10)))))
;; 冰凍值 (the user 2026-10-24, DUEL_RUKIA_TYBW §10): two points a layer (a K hit 1, 霜陣 1 a 30 f); capped at 3 layers with no
;; point kept; a lone point with no layer thaws like a layer; a layer thaws with its point kept
(check (and (= 2 *ru-chill-per*)
            (equal '(0 1) (multiple-value-list (chill-add 0 0 1))) (equal '(1 0) (multiple-value-list (chill-add 0 1 1)))
            (equal '(1 1) (multiple-value-list (chill-add 1 0 1))) (equal '(3 0) (multiple-value-list (chill-add 2 1 1)))
            (equal '(3 0) (multiple-value-list (chill-add 3 0 1))) (equal '(3 0) (multiple-value-list (chill-add 0 0 9)))
            (equal '(0 149 1) (let ((l 0) (th 0) (c 1)) (dotimes (i 149) (multiple-value-setq (l th c) (layers-thaw l th c))) (list l th c)))
            (equal '(0 0 0) (let ((l 0) (th 0) (c 1)) (dotimes (i 150) (multiple-value-setq (l th c) (layers-thaw l th c))) (list l th c)))
            (equal '(0 0 1) (let ((l 1) (th 0) (c 1)) (dotimes (i 150) (multiple-value-setq (l th c) (layers-thaw l th c))) (list l th c)))))
(let* ((b (kit :rukia :base))
       (links '((:ru-j1 :ru-shimochiri 1) (:ru-j2 :ru-setsuen 2) (:ru-j2s :ru-setsuen 2) (:ru-j3 :ru-sojin 3)
                (:ru-k1 :ru-hyoreki 1) (:ru-sk2 :ru-tsurara 2) (:ru-sk2s :ru-tsurara 2) (:ru-k3 :ru-hakuren-k 3)))
       (bursts '(:ru-shimochiri :ru-setsuen :ru-sojin :ru-hyoreki :ru-tsurara :ru-hakuren-k)))
  ;; the six routes: every J / K link of the Shikai's grid has its own burst, link n bursting up to n (:burst n); the J
  ;; routes S 10 / A 3 / R 22, the K routes S 12 / A 4 / R 26; each a :sig ending the string (no J / K / L link after it,
  ;; no :ender: no O ender; a :sig: no SP cancel); six distinct clips; their damage (§4.4)
  (check (= 8 (length (remove-duplicates (mapcar (lambda (l) (mv-name (first l))) (link-moves b))))))
  (dolist (l links)
    (destructuring-bind (link burst n) l
      (let ((m (kit-l-link b link)))
        (check (or (and m (eq burst (mv-name m)) (= n (getf (mv-params m) :burst))) (format t "  Rukia burst ~a -> ~a~%" link m))))))
  (dolist (n bursts)
    (let ((m (kit-move b n)) (j (member n '(:ru-shimochiri :ru-setsuen :ru-sojin))))
      (check (and (eq :sig (mv-kind m)) (null (kit-next b n :q)) (null (kit-next b n :f)) (null (kit-l-link b n))
                  (not (member :ender (mv-flags m))) (= 1 (length (mv-hits m)))
                  (equal (list (mv-s m) (mv-a m) (mv-r m)) (if j '(10 3 22) '(12 4 26)))
                  (member '(0 rukia-burst-arm) (mv-on-frame m) :test #'equal)))))
  (check (= 6 (length (remove-duplicates (mapcar (lambda (n) (mv-clip (kit-move b n))) bursts)))))
  (check (null (intersection (mapcar (lambda (n) (mv-clip (kit-move b n))) bursts)
                             (mapcar (lambda (l) (mv-clip (first l))) (link-moves b)))))   ; (not the openers' clips)
  (flet ((at (n layers) (let ((m (kit-move b n))) (+ (mv-dmg m) (* (getf (mv-params m) :per) (burst-count (getf (mv-params m) :burst) layers))))))
    (check (and (equal '(40 40 40) (mapcar (lambda (k) (at :ru-shimochiri k)) '(1 2 3)))
                (equal '(40 60 60) (mapcar (lambda (k) (at :ru-setsuen k)) '(1 2 3)))
                (equal '(40 60 80) (mapcar (lambda (k) (at :ru-sojin k)) '(1 2 3)))
                (equal '(60 60 60) (mapcar (lambda (k) (at :ru-hyoreki k)) '(1 2 3)))
                (equal '(55 80 80) (mapcar (lambda (k) (at :ru-tsurara k)) '(1 2 3)))
                (equal '(75 110 145) (mapcar (lambda (k) (at :ru-hakuren-k k)) '(1 2 3)))
                ;; SP2 SHIRAFUNE: 110 + 25 a layer, every layer (alone or off a string hit)
                (equal '(110 135 160 185) (mapcar (lambda (k) (at :ru-shirafune-s k)) '(0 1 2 3)))
                (eq :ru-shirafune-s (mv-name (kit-command-move b :sp2))) (= 3 (getf (mv-params (kit-command-move b :sp2)) :burst)))))
  ;; the benefits: 霜散 hops 2.5 m, 雪煙 8 % of a bar a layer, 霜陣 r 3 m round him for 4 s (a point a 30 f, §10), 氷礫 stagger 26 + 8,
  ;; 氷柱 out to 6 m, 白漣 a knockdown along an 11 m line; the J routes 2.0 m round her, the K routes 2.8 m
  (check (and (eq :hop (getf (mv-params (kit-move b :ru-shimochiri)) :fx)) (~= 2.5 *ru-hop*)
              (eq :refund (getf (mv-params (kit-move b :ru-setsuen)) :fx)) (~= 0.08 *ru-refund*)
              (eq :circle (getf (mv-params (kit-move b :ru-sojin)) :fx)) (equal *ru-sojin* '(:r 3.0 :life 240 :per 30))
              (= 34 (hw-stun (svref (mv-hits (kit-move b :ru-hyoreki)) 0))) (eq :stagger (hw-react (svref (mv-hits (kit-move b :ru-hyoreki)) 0)))
              (eq :push (getf (mv-params (kit-move b :ru-tsurara)) :fx)) (~= 6.0 *ru-tsurara-to*)
              (eq :knockdown (hw-react (svref (mv-hits (kit-move b :ru-hakuren-k)) 0))) (~= 11.0 (mv-reach (kit-move b :ru-hakuren-k)))
              (every (lambda (n) (~= 2.0 (mv-reach (kit-move b n)))) '(:ru-shimochiri :ru-setsuen :ru-sojin))
              (every (lambda (n) (~= 2.8 (mv-reach (kit-move b n)))) '(:ru-hyoreki :ru-tsurara))))
  ;; every burst leaves him out of its route's opener (the user 2026-10-24, DUEL_RUKIA_TYBW §9): the J routes J1's reach,
  ;; the K routes K1's (RUKIA-BURST-OUT: reach + lunge + his body + *ENDER-PUSH*); 霜散's hop and 氷柱's 6 m clear it by
  ;; themselves for the widest body (0.45 m), 霜陣's circle (r 3 m) still holds a man pushed out of J1
  (let ((jo (+ (mv-reach (kit-command-move b :q)) (mv-slide (kit-command-move b :q)) 0.45 *ender-push*))
        (ko (+ (move-edge (kit-command-move b :f)) (mv-slide (kit-command-move b :f)) 0.45 *ender-push*)))
    ;; the K route measures from K1's far edge (b + r: MOVE-EDGE), so a restarted K1 can't touch him after K3 or a K burst
    ;; (the user 2026-10-24: 「連打 K 能重複壓制，請縮短 K1 的攻擊距離」「要將半徑也計算進去」, §14–§15): K1 2.55 + 0.3
    (check (and (~= 2.85 (move-edge (kit-command-move b :f))) (~= 2.55 (mv-reach (kit-command-move b :f)))
                (~= 1.44 (move-edge (kit-command-move b :q))) (null (kit-push-reach b))))
    (check (and (every (lambda (n) (eq :q (getf (mv-params (kit-move b n)) :opener))) '(:ru-shimochiri :ru-setsuen :ru-sojin))
                (every (lambda (n) (eq :f (getf (mv-params (kit-move b n)) :opener))) '(:ru-hyoreki :ru-tsurara :ru-hakuren-k))
                (~= 2.54 jo) (> (+ 1.2 *ru-hop*) jo) (> *ru-tsurara-to* ko) (< jo (getf *ru-sojin* :r))
                ;; SP2 SHIRAFUNE bursts but ends no string: no :opener, no floor push (a missing one crashed the gate, §10)
                (getf (mv-params (kit-move b :ru-shirafune-s)) :burst) (null (getf (mv-params (kit-move b :ru-shirafune-s)) :opener)))))
  ;; every burst combos off its link with the link's hitstop on both sides: the link's chain opens at S + A on a hit, the
  ;; burst's hit S_eff later; the victim is free from the link's hit frame + its hitstop + 1 + its hitstun
  (dolist (l links)
    (let* ((ma (kit-move b (first l))) (mb (kit-move b (second l))) (w (svref (mv-hits ma) 0)) (hs (hw-hs w))
           (free (+ (hw-from w) hs 1 (or (hw-stun w) (hitstun (hw-react w)))))
           (hit (+ (mv-s ma) (mv-a ma) hs (- (mv-s mb) (mv-enter mb)))))
      (check (or (< hit free) (format t "  Rukia burst ~a -> ~a: hit ~d, free ~d~%" (first l) (second l) hit free)))))
  ;; the layers' sources: the K links a 冰凍值 point (K1 K2 K2s K3: two make a layer, §10), ENBU +1, TSUKISHIRO's pillar +2;
  ;; J, the kido and the bands: 0
  (check (and (every (lambda (n) (and (eql 1 (getf (mv-params (kit-move b n)) :chill)) (null (getf (mv-params (kit-move b n)) :layers))))
                     '(:ru-k1 :ru-sk2 :ru-sk2s :ru-k3))
              (eql 1 (getf (mv-params (kit-move b :ru-kikon)) :layers))
              (eql 2 (getf (mv-params (kit-next b :ru-byakurai :hold)) :layers))
              (notany (lambda (n) (getf (mv-params (kit-move b n)) :layers)) '(:ru-j1 :ru-j2 :ru-j3 :ru-byakurai :ru-sokatsui))
              (null (getf (mv-params (kit-next b :ru-sokatsui :hold)) :layers))
              (equal (kit-hooks b) '(:boss rukia-boss :hit rukia-hit :ok rukia-ok))
              (every (lambda (f) (and (null (kit-hook (kit :rukia f) :hit)) (null (kit-hook (kit :rukia f) :ok)))) '(:m18 :m50 :zero))))
  ;; the tap / hold splits: L tap BYAKURAI (12 / 3 / 28, 45, a :ranged line 0.5 -> 6 m, 0.3 m wide, flinch, guard 10, -12,
  ;; no bar), held >= 12 f TSUKISHIRO (the switch at its f11, before its hit; no :track that hides aim); SP1 tap SOKATSUI
  ;; (14 / 4 / 26, 90, a 5 m cone of 40 deg, knockback 3 m, 1 bar), held 16 f RIKUJOKORO (the rods at f32: the mark at f2,
  ;; the bind 30 f later (14 before §17.13), one frame only, 20, a :bind of 45 f, <= 6 m, :src; its :tell for a CPU victim)
  (let* ((by (kit-command-move b :sig)) (ts (kit-next b :ru-byakurai :hold)) (so (kit-command-move b :sp1)) (ri (kit-next b :ru-sokatsui :hold))
         (wb (svref (mv-hits by) 0)) (vb (first (hw-vols wb))) (ws (svref (mv-hits so) 0)))
    (check (and (eq :ru-byakurai (mv-name by)) (equal '(12 3 28) (list (mv-s by) (mv-a by) (mv-r by))) (= 45 (mv-dmg by))
                (member :ranged (mv-flags by)) (eq :flinch (hw-react wb)) (~= 10 (hw-guard wb)) (= -12 (mv-adv-block by))
                (~= 6.0 (mv-reach by)) (~= 0.5 (aref vb 1)) (~= 6.0 (aref vb 2)) (~= 0.15 (aref vb 4)) (null (mv-hold by))
                (= 0 (kit-command-cost b :sig)) (eq 'rukia-l-hold (mv-tick by)) (= 12 *ru-l-hold*) (< (1- *ru-l-hold*) (mv-s by))
                (eq :ru-tsukishiro (mv-name ts)) (= 12 (mv-s ts)) (equal '((12 rukia-tsukishiro)) (mv-on-frame ts))
                (<= (mv-track by) *track-heavy*) (<= (mv-track ts) *track-heavy*)
                (eq :ru-sokatsui (mv-name so)) (equal '(1 16) (mv-hold so)) (eq 'rukia-sp1-release (mv-release so))
                (equal '(14 4 26) (list (mv-s so) (mv-a so) (mv-r so))) (= 90 (mv-dmg so)) (~= 5.0 (mv-reach so))
                (eq :knockback (hw-react ws)) (~= 3.0 (hw-kb ws)) (member :ranged (mv-flags so)) (= 1 (kit-command-cost b :sp1))
                (eq :ru-rikujo (mv-name ri)) (= 32 (mv-s ri)) (~= 0.5 (mv-clip-speed ri)) (zerop (length (mv-hits ri))) (member :bind (mv-flags ri))
                (= 32 (+ 2 (getf (mv-params ri) :delay))) (= 1 (getf (mv-params ri) :life)) (equal '((2 rukia-rikujo)) (mv-on-frame ri))
                (= 20 (getf (mv-params ri) :dmg)) (= 45 (getf (mv-params ri) :stun)) (~= 6.0 (getf (mv-params ri) :range))
                ;; held past 16 f, a bind frame each *RU-RIKUJO-RATE* held frames up to *RU-RIKUJO-MAX* (§10, §17.13: 2 held frames a
                ;; bind frame, the cap 100 unchanged): its hold's end reaches the cap
                (= 2 *ru-rikujo-rate*) (= 100 *ru-rikujo-max*)
                (equal (list 0 (1+ (* *ru-rikujo-rate* (- *ru-rikujo-max* (getf (mv-params ri) :stun))))) (mv-hold ri))
                (= *ru-rikujo-max* (+ (getf (mv-params ri) :stun) (floor (1- (second (mv-hold ri))) *ru-rikujo-rate*)))
                (< (+ (getf (mv-params ri) :radius) 0.45) *step-distance*) (equal '(2 32) (getf (mv-params ri) :tell))
                (eq :ru-shirafune-s (mv-name (kit-command-move b :sp2))) (= 1 (kit-command-cost b :sp2)))))
  ;; removed from the Shikai: the K -> L TSUKISHIRO copy, HAKUREN on SP1, the K hits' frost (above)
  (check (and (not (gethash :ru-tsukishiro-k *moves*)) (not (gethash :ru-hakuren (kit-moves b)))
              (not (gethash :ru-k2 (kit-moves b))) (not (gethash :ru-tsukishiro-k (kit-moves b))))))
;; the awakened bands are pinned (DUEL_RUKIA_TYBW §2: their rules stay): every command, every link's follow-ups and L link,
;; their hits' frost, startup, reach and params, the kit keys, as on adcb94b (the parent of the Shikai's rebuild; printed
;; by the same expression there)
;; (the bands' damage x moved by the user 2026-10-24, DUEL_RUKIA_TYBW §11: -18 1.15 -> 1.1, -50 1.5 -> 1.25; the rest as adcb94b)
(defparameter *ru-bands-pinned* (quote ((:M18 (:RU-J1 :RU-A-K1 :RU-SHIMOBASHIRA :RU-HAKUREN :RU-SHIRAFUNE :RU-BREAKER :RU-HAKKA-18) ((:RU-J1 :RU-J2 :RU-K2S NIL (0) 7 1.44) (:RU-J2 :RU-J3 :RU-A-K3 NIL (0) 7 1.4) (:RU-J3 NIL NIL NIL (0) 8 1.56) (:RU-A-K3 NIL NIL :RU-SHIMOBASHIRA (120) 21 2.4) (:RU-K2S NIL :RU-A-K3 :RU-SHIMOBASHIRA (60) 21 2.5) (:RU-A-K3 NIL NIL :RU-SHIMOBASHIRA (120) 21 2.4) (:RU-A-K1 :RU-J2S :RU-K2 :RU-SHIMOBASHIRA (90) 17 2.0) (:RU-J2S :RU-J3 NIL NIL (0) 7 1.4) (:RU-J3 NIL NIL NIL (0) 8 1.56) (:RU-K2 :RU-J3 :RU-A-K3 :RU-SHIMOBASHIRA (60) 21 2.5) (:RU-J3 NIL NIL NIL (0) 8 1.56) (:RU-A-K3 NIL NIL :RU-SHIMOBASHIRA (120) 21 2.4)) ((:RU-J1 (0) 7 1.44 NIL) (:RU-A-K1 (90) 17 2.0 NIL) (:RU-SHIMOBASHIRA NIL 12 0.0 (:RADIUS 2.5 :HEIGHT 0.6 :DMG 60 :FROST 90 :GUARD 12 :REACT :STAGGER :STUN 42 :GC-FROM 40 :R-CANCEL (:Q) :R-CANCEL-FROM 34)) (:RU-HAKUREN NIL 6 0.0 (:SPEED 12.0 :RANGE 11.0 :WIDTH 2.4 :WIDTH-PER 0.4 :DMG 70 :DMG-PER 20 :STUN 24 :FROST 120 :GUARD 12 :GUARD-PER 2)) (:RU-SHIRAFUNE (150) 16 5.0 NIL) (:RU-BREAKER (0) 8 1.35 NIL) (:RU-HAKKA-18 (120) 20 6.5 (:AURA 8 :AIM 120.0 :SPEED 0.0 :DASH-MAX 0 :DASH-TRACK 0.0 :LOOK :LANE))) T NIL 30 (:SIG 25) (:HOHO RUKIA-HOHO-COLD :TICK RUKIA-TICK :RESET RUKIA-RESET) 3.4 8.0 0.825 0.95 (:R 3.0 :AWAY 0.85 :STEP 1.0)) (:M50 (:RU-J1 :RU-A-K1-50 :RU-HYOSHIN :RU-HAKUREN-50 :RU-SHIRAFUNE-50 :RU-BREAKER :RU-HAKKA) ((:RU-J1 :RU-J2 :RU-K2S NIL (0) 7 1.5840001) (:RU-J2 :RU-J3-50 :RU-A-K3-50 NIL (0) 7 1.4520001) (:RU-J3-50 NIL NIL NIL (0) 8 1.72) (:RU-A-K3-50 NIL NIL :RU-HYOSHIN (120) 21 2.64) (:RU-K2S NIL :RU-A-K3-50 :RU-HYOSHIN (60) 21 2.75) (:RU-A-K3-50 NIL NIL :RU-HYOSHIN (120) 21 2.64) (:RU-A-K1-50 :RU-J2S :RU-K2 :RU-HYOSHIN (90) 17 2.2) (:RU-J2S :RU-J3-50 NIL NIL (0) 7 1.4520001) (:RU-J3-50 NIL NIL NIL (0) 8 1.72) (:RU-K2 :RU-J3-50 :RU-A-K3-50 :RU-HYOSHIN (60) 21 2.75) (:RU-J3-50 NIL NIL NIL (0) 8 1.72) (:RU-A-K3-50 NIL NIL :RU-HYOSHIN (120) 21 2.64)) ((:RU-J1 (0) 7 1.5840001 NIL) (:RU-A-K1-50 (90) 17 2.2 NIL) (:RU-HYOSHIN NIL 14 0.0 (:RADIUS 3.5 :HEIGHT 0.6 :DMG 85 :FROST 120 :GUARD 16 :REACT :CRUMPLE :STUN 42 :GC-FROM 42 :R-CANCEL (:Q) :R-CANCEL-FROM 36)) (:RU-HAKUREN-50 NIL 6 0.0 (:PER 12 :SPEED 14.0 :RANGE 12.0 :WIDTH 2.4 :WIDTH-PER 0.4 :DMG 80 :DMG-PER 23 :STUN 30 :FROST 120 :GUARD 12 :GUARD-PER 2)) (:RU-SHIRAFUNE-50 (150) 16 6.0 NIL) (:RU-BREAKER (0) 8 1.35 NIL) (:RU-HAKKA (120) 20 7.5 (:AURA 8 :AIM 120.0 :SPEED 0.0 :DASH-MAX 0 :DASH-TRACK 0.0 :LOOK :LANE))) T NIL 60 (:Q 6 :F 12 :SIG 36 :SP1 40 :SP2 40 :KIKON 20 :BREAKER 20 :STEP 12) (:HOHO RUKIA-HOHO-COLD :TICK RUKIA-TICK :RESET RUKIA-RESET) 2.8 6.4 0.9375 0.85 (:R 4.0 :AWAY 0.7 :STEP 0.9)) (:ZERO (:RU-J1 :RU-Z-K1 :RU-REIDO :RU-HAKUREN-0 :RU-SHIRAFUNE-0 NIL :RU-HAKKA-0) ((:RU-J1 :RU-Z-J2 :RU-K2S NIL (0) 7 1.9440001) (:RU-Z-J2 :RU-J3 :RU-Z-K3 NIL (0) 7 1.78) (:RU-J3 NIL NIL NIL (0) 8 2.106) (:RU-Z-K3 NIL NIL :RU-REIDO (150) 21 3.24) (:RU-K2S NIL :RU-Z-K3 :RU-REIDO (60) 21 3.375) (:RU-Z-K3 NIL NIL :RU-REIDO (150) 21 3.24) (:RU-Z-K1 :RU-Z-J2S :RU-K2 :RU-REIDO (90) 17 3.78) (:RU-Z-J2S :RU-J3 NIL NIL (0) 7 1.78) (:RU-J3 NIL NIL NIL (0) 8 2.106) (:RU-K2 :RU-J3 :RU-Z-K3 :RU-REIDO (60) 21 3.375) (:RU-J3 NIL NIL NIL (0) 8 2.106) (:RU-Z-K3 NIL NIL :RU-REIDO (150) 21 3.24)) ((:RU-J1 (0) 7 1.9440001 NIL) (:RU-Z-K1 (90) 17 3.78 NIL) (:RU-REIDO NIL 10 0.0 (:RADIUS 5.5 :HEIGHT 2.2 :DMG 120 :STUN 46 :FROST 150 :GUARD 20 :GC-FROM 37 :R-CANCEL (:Q) :R-CANCEL-FROM 36)) (:RU-HAKUREN-0 NIL 10 0.0 (:STABS 4 :SPEED 16.0 :RANGE 14.0 :WIDTH 3.6 :WIDTH-PER 0.0 :DMG 160 :DMG-PER 0 :STUN 36 :FROST 150 :GUARD 18 :GUARD-PER 0)) (:RU-SHIRAFUNE-0 (150) 16 7.5 NIL) (:RU-HAKKA-0 (120) 20 9.0 (:AURA 8 :AIM 120.0 :SPEED 0.0 :DASH-MAX 0 :DASH-TRACK 0.0 :LOOK :LANE))) T NIL 90 (:Q 20 :F 40 :SIG 100 :SP1 100 :SP2 100 :KIKON 60) (:HOHO RUKIA-HOHO-COLD :TICK RUKIA-TICK :RESET RUKIA-RESET) 0.0 0.0 1.2375 0.8 (:R 5.5 :AWAY 0.55 :STEP 0.75)))))
(check (equal *ru-bands-pinned*
              (loop for form in '(:m18 :m50 :zero)
                    collect (let ((k (kit :rukia form)))
                              (list form
                                    (mapcar (lambda (c) (let ((m (kit-command-move k c))) (and m (mv-name m)))) *kit-commands*)
                                    (loop for l in (link-moves k)
                                          collect (let ((n (mv-name (first l))))
                                                    (list n (let ((m (kit-next k n :q))) (and m (mv-name m)))
                                                          (let ((m (kit-next k n :f))) (and m (mv-name m)))
                                                          (let ((m (kit-l-link k n))) (and m (mv-name m)))
                                                          (map 'list #'hw-frost (mv-hits (first l))) (mv-s (first l)) (mv-reach (first l)))))
                                    (loop for c in *kit-commands* for m = (kit-command-move k c)
                                          when m collect (list (mv-name m) (map 'list #'hw-frost (mv-hits m)) (mv-s m) (mv-reach m) (mv-params m)))
                                    (kit-l-after-k k) (kit-l-after-j k) (kit-frost-touch k) (kit-cold k) (kit-hooks k) (kit-walk k) (kit-run k)
                                    (kit-mult k) (kit-taken k) (kit-field k))))))

;; the awakened L's longer recovery (the user 2026-10-26, DUEL_RUKIA_TYBW §17.11: 「延長 L 的後搖」, +10): recovery 32 / 32 / 36
;; (was 22 / 22 / 26), hit stun 42 / 42 / 46 (on hit +9: her 7 f J1 combos, her 17 f K1 doesn't), and the guard cancel open
;; from move frame 40 / 42 / 37 whatever L touched (her guard 13 f after a blocked L frees him: every J1 (<= 10 f) lands,
;; every K1 (>= 16 f) is guarded); a move without :gc-from keeps the old rule
(let ((ls (mapcar (lambda (f) (kit-command-move (kit :rukia f) :sig)) '(:m18 :m50 :zero))))
  (check (and (equal '(32 32 36) (mapcar #'mv-r ls))
              (equal '(42 42 46) (mapcar (lambda (m) (getf (mv-params m) :stun)) ls))
              (equal '(40 42 37) (mapcar (lambda (m) (getf (mv-params m) :gc-from)) ls))
              (loop for m in ls for g = (getf (mv-params m) :gc-from)
                    always (and (not (guard-cancel-open-p (1- g) (mv-s m) (mv-a m) (mv-r m) :block (mv-kind m) (mv-whiff m) g))
                                (guard-cancel-open-p g (mv-s m) (mv-a m) (mv-r m) :block (mv-kind m) (mv-whiff m) g)
                                (guard-cancel-open-p g (mv-s m) (mv-a m) (mv-r m) nil (mv-kind m) (mv-whiff m) g)
                                (guard-cancel-open-p (+ (mv-s m) (mv-a m) (mv-r m) -1) (mv-s m) (mv-a m) (mv-r m) nil (mv-kind m) nil g)
                                (not (guard-cancel-open-p (+ (mv-s m) (mv-a m) (mv-r m)) (mv-s m) (mv-a m) (mv-r m) nil (mv-kind m) nil g))
                                (not (guard-cancel-open-p g (mv-s m) (mv-a m) (mv-r m) :block (mv-kind m) (mv-whiff m)))))
              (= 16 (- 42 (hitstun :stagger))) (= 2 (- 42 (hitstun :crumple)))   ; (over the reactions' own 26 / 40)
              ;; on a hit (her disc's: FIGHTER-HZ-HIT) J cancels her recovery into J1 10 frames before its end (the user
              ;; 2026-10-26: 「把露琪亞覺醒的 L 改成打傷對手的話可以透過 J1 提早一點取消」, 「提早 10 幀」; K never)
              (equal '((:q) (:q) (:q)) (mapcar (lambda (m) (getf (mv-params m) :r-cancel)) ls))
              (loop for m in ls always (= (getf (mv-params m) :r-cancel-from) (- (+ (mv-s m) (mv-a m) (mv-r m)) 10))))))

;; the combo band lock with overdraft (the user's decision 2026-09-28): inside a combo the band holds whatever C does; L is
;; refused short of its cold outside a combo, allowed on credit inside one while C > 0; once free the band re-resolves,
;; several at once: -273 K K K (40 each) leaves 80, the chained L (100) overdraws to 0, and she lands at -18
(let* ((z (kit :rukia :zero)) (kc (getf (kit-cold z) :f)) (lc (getf (kit-cold z) :sig))
       (c (- *cold-max* (* 3 kc))))
  (check (and (= 40 kc) (= 100 lc) (= 80 c)
              (not (cold-ok-p c lc nil)) (cold-ok-p c lc t) (not (cold-ok-p 0.0 lc t)) (cold-ok-p 100.0 lc nil)
              (eq :zero (temp-band-at c :zero :move)) (eq :zero (temp-band-at 0.0 :zero :move))   ; locked in the combo
              (eq :zero (temp-band-at 0.0 :zero :stun)) (eq :m50 (temp-band-at 80.0 :zero :idle))
              (eq :m18 (temp-band-at (max 0.0 (- c lc)) :zero :idle))                          ; the overdrawn combo: -18
              (eq :m50 (temp-band-at 150.0 :m50 :guard)) (eq :m18 (temp-band-at 0.0 :m50 :run))
              (eq :m18 (temp-band-at 10.0 :m18 :move)) (eq :zero (temp-band-at 200.0 :m18 :idle)))))

;; Ichigo v2 (docs/duel/DUEL_ICHIGO.md "v2: built"): the cross copies, the stance and its branches (every one combos after a K
;; link), KESSA's cuts, the clones (their timing, the Konpaku table, their fate), the parry's own window (GOKUI GAESHI's
;; unchanged), the counter, the afterimages, the pull, the Kikon counts and cinematics, the removed tools
(let* ((b (kit :ichigo :base)) (ks (kit :ichigo :kessa)) (parry (kit-move ks :ic-k-parry)) (gaeshi (kit-move ks :ic-k-gaeshi))
       (hiki (kit-move ks :ic-k-hiki)) (kj1 (kit-command-move ks :q)) (kk1 (kit-command-move ks :f)) (hk (svref (mv-hits hiki) 0))
       (tsuki (kit-command-move b :sig)) (tk2 (kit-l-link b :ic-k1)) (win (getf (mv-params parry) :window))
       (kr 0.45))                                          ; Kenpachi's hurt r (ken-art.lisp: the host loads no body)
  (flet ((gv (k n) (hw-guard (svref (mv-hits (kit-move k n)) 0))))
    ;; the CROSS: J2s / K2s = J2 / K2 with guard 12 / 24 (J2 / K2 8 / 16); KESSA's copies are plain (one blade)
    (check (and (= 8 (gv b :ic-j2)) (= 12 (gv b :ic-j2s)) (= 16 (gv b :ic-k2)) (= 24 (gv b :ic-k2s)) (= 22 (gv b :ic-k3))
                (eq :ic-cross (mv-clip (kit-move b :ic-k2s))) (equal (mv-spec (kit-move ks :ic-k-k2)) (mv-spec (kit-move ks :ic-k-k2s)))))
    ;; KESSA's cuts: ordinary reach (J 2.6, K 3.2), routes on hit JJJ 100 / KKK 204, blocked KKK drains 48
    (check (and (~= 1.56 (mv-reach kj1)) (~= 2.9 (mv-reach kk1)) (<= (mv-reach (kit-move ks :ic-k-k3)) 3.6)
                (= 100 (+ (mv-dmg kj1) (mv-dmg (kit-move ks :ic-k-j2)) (mv-dmg (kit-move ks :ic-k-j3))))
                (= 204 (+ (mv-dmg kk1) (mv-dmg (kit-move ks :ic-k-k2)) (mv-dmg (kit-move ks :ic-k-k3))))
                (= 48 (+ (gv ks :ic-k-k1) (gv ks :ic-k-k2) (gv ks :ic-k-k3))))))
  ;; the stance: up at f6, 30 f held (60 with L held) then R 14, no hits (hit as neutral); its branches are non-button
  ;; strings; L after a K link opens it at f4; L, L fires the Getsuga at the old L's f14; the dash comes back at f6
  (check (and (= 6 (mv-s tsuki)) (= 80 (mv-total tsuki)) (zerop (length (mv-hits tsuki))) (eq :ic-tsuki-k2 (mv-name tk2))
              (= 4 (mv-enter tk2)) (= 6 (mv-enter (find-move :ic-tsuki-re))) (= 80 (+ *tsuki-up* *tsuki-max* 14))
              (eq (kit-next b :ic-tsuki :tsuki-j) (find-move :ic-tsuki-j)) (eq (kit-next b :ic-tsuki-k2 :tsuki-k) (find-move :ic-tsuki-k))
              (eq (kit-next b :ic-tsuki-re :tsuki-step) (find-move :ic-tsuki-dash))
              (eq (kit-next b :ic-tsuki-dash :tsuki-back) (find-move :ic-tsuki-re))
              (= 14 (+ *tsuki-up* (mv-s (kit-next b :ic-tsuki :tsuki-l)))) (null (kit-l-link b :ic-j1))
              (not (string-link-p b :ic-tsuki))))
  ;; RANGETSU: four hits, -6 on block (J1 7 f doesn't punish it); TSUKI-OTOSHI: guard 30, -10
  (let ((rj (find-move :ic-tsuki-j)) (rk (find-move :ic-tsuki-k)))
    (check (and (= 4 (length (mv-hits rj))) (= 72 (* 4 (mv-dmg rj))) (= -6 (mv-adv-block rj)) (= 30 (hw-guard (svref (mv-hits rk) 0)))
                (= -10 (mv-adv-block rk)) (eq :crumple (hw-react (svref (mv-hits rk) 0))))))
  ;; every branch combos off a K link's hit: its A + 2 (the stance's f4 -> f6) + the branch's first hit (the wave's travel
  ;; from 1 m out to 3 m) < the K link's hitstun
  (dolist (k '(:ic-k1 :ic-k2 :ic-k3))
    (let* ((m (kit-move b k)) (st (hitstun (hw-react (svref (mv-hits m) 0)))))
      (check (and (< (+ (mv-a m) 2 (mv-first-hit (kit-next b :ic-tsuki-k2 :tsuki-j))) st)
                  (< (+ (mv-a m) 2 (mv-first-hit (kit-next b :ic-tsuki-k2 :tsuki-k))) st)
                  (< (+ (mv-a m) 2 (mv-s (kit-next b :ic-tsuki-k2 :tsuki-l)) (ceiling (* 60 (/ 2.0 16.0)))) st)))))
  ;; the clones: a J press's heavy lands inside Ichigo's J1 flinch (between J1 and J2), a K press's light before his K1;
  ;; an opponent's J1 (7 f) beats the light (a real hit on Ichigo clears every clone)
  (check (and (= 22 (clone-hit-frame :q)) (= 14 (clone-hit-frame :f))
              (< (mv-s kj1) (clone-hit-frame :q) (+ (mv-s kj1) (hitstun :flinch))) (< (clone-hit-frame :f) (mv-s kk1))
              (< (mv-s (mv :kenpachi :base :ke-j1)) (clone-hit-frame :f))
              (eq :stagger (hw-react (svref (mv-hits (clone-move :q 1)) 0))) (eq :crumple (hw-react (svref (mv-hits (clone-move :q 3)) 0)))
              (eq :flinch (hw-react (svref (mv-hits (clone-move :f 1)) 0)))))
  ;; the Kikon's Konpaku by the clones at the O press (the user's table 0 / 1 / 2 / 3 -> 2 / 2 / 3 / 4, at most 4)
  (check (and (equal '(2 2 3 4) (mapcar #'clone-konpaku '(0 1 2 3))) (= 4 (clone-konpaku 5)) (<= (clone-konpaku 3) *kikon-max-event*)))
  ;; a clone's life and fate: 300 f, 3 at most (the oldest replaced), 15 guard gauge each (no Step gap); its string touched him
  ;; (hit or block): it fades, a whiff keeps it (idle), its time up: it fades; a real hit on Ichigo (not a block, not a
  ;; parry) clears them all
  (check (and (= 300 *clone-life*) (= 3 *clone-max*) (= 15.0 *clone-cost*)
              (eq :idle (clone-after-string nil 100)) (eq :fade (clone-after-string t 100)) (eq :fade (clone-after-string nil 0))
              (null (clone-evict '(5 9))) (= 1 (clone-evict '(7 3 9)))
              (clone-vanish-p :hit) (clone-vanish-p :counter) (clone-vanish-p :guard-break)
              (not (clone-vanish-p :blocked)) (not (clone-vanish-p :parried)) (not (clone-vanish-p nil))))
  ;; the DANGAI boss (DUEL_ROGUE §5): only *RUN-BOSS*'s clones are free; the :boss hook is the base kit's
  (check (and (let ((*run-boss* nil)) (not (clone-free-p :x))) (let ((*run-boss* :x)) (and (clone-free-p :x) (not (clone-free-p :y))))
              (eq 'ichigo-boss (kit-hook (kit :ichigo :base) :boss))))
  ;; the parry: its own window f2-25 (24 f; the move's :window), 360 deg, 10 of the gauge, R 18; GOKUI GAESHI's shared
  ;; window is the same f2-25 since 2026-10-01; a catch staggers 40 f, and ZANGETSU-GAESHI (the :land string) is +15: his J1 combos
  (check (and (member :parry (mv-flags parry)) (equal '(2 25) win) (= 2 (mv-s parry)) (= 24 (mv-a parry)) (= 44 (mv-total parry))
              (parry-frame-p 2 win) (parry-frame-p 25 win) (not (parry-frame-p 1 win)) (not (parry-frame-p 26 win))
              (parry-frame-p 2) (parry-frame-p 25) (not (parry-frame-p 1)) (not (parry-frame-p 26))
              (eq (kit-next ks :ic-k-parry :land) gaeshi) (= 10 *kessa-parry-cost*) (= 20 *kessa-parry-catch*)
              (= 40 *kessa-parry-stun*) (< (mv-s gaeshi) *kessa-parry-stun*)
              (= 15 (- (+ (mv-s gaeshi) (hitstun :crumple)) (mv-total gaeshi))) (< (mv-s kj1) 15)
              (member :parry-block (kit-passives ks)) (not (member :parry-block (kit-passives b)))))
  ;; a :parry-block parry blocks a hazard and catches a melee hit
  (check (and (eq (resolve-contact :parry :hazard t :ward t) :blocked) (eq (resolve-contact :parry) :parried)
              (eq (resolve-contact :parry :breaker t) :stance-break) (eq (resolve-contact :parry :unguardable t) :hit)))
  ;; the afterimages: each hit repeats *ZANZO-LAG* (10) f later at x0.5 damage and guard, a blade's hit: J1's at f18,
  ;; RANGETSU's four at f18 21 24 27
  (let ((w (echo-hitwin (svref (mv-hits kj1) 0) *zanzo-mult*)))
    (check (and (equal '(18) (echo-hit-frames kj1)) (equal '(18 21 24 27) (echo-hit-frames (find-move :ic-tsuki-j)))
                (= 15 (hw-dmg w)) (~= 4.0 (hw-guard w)) (member :blade (hw-flags w)) (eq :flinch (hw-react w))
                (= 360 *zanzo-life*))))
  ;; KUSARI-BIKI: the far part ranged (beyond 3.8 m), bound 40 f from its f16 hit: +13, so his J1 (8 f) combos
  (check (and (member :ranged (hw-flags hk)) (= 40 (hw-stun hk)) (eq :bind (hw-react hk))
              (~= 3.8 (getf (mv-params hiki) :melee-range)) (= 13 (- (+ (hw-from hk) (hw-stun hk)) (mv-total hiki)))
              (< (mv-s kj1) 13)))
  ;; the Kikon counts 2 / 3 (a Soul Break 3 / 4); KESSA's Soul Break plays the Getsuga (its :soul-break-cine), its O 千影
  (check (and (= 2 (kit-kikon-konpaku b)) (= 3 (kit-kikon-konpaku ks)) (kit-awakening ks)
              (eq 'ic-kessa-getsuga-cine (kit-kikon-cine ks)) (eq 'ic-kikon-cine (kit-kikon-cine b))
              (eq 'ic-kessa-kikon-cine (mv-cine (kit-command-move ks :kikon)))
              (~= 8.6 (kikon-rush-reach 30.0 14)) (> (+ (mv-reach (kit-command-move ks :breaker)) 0.34) *breaker-trigger*)))
  ;; a side Step (2.5 m) clears every crescent: its half-width + Kenpachi's hurt r < 2.5
  (check (every (lambda (w) (< (+ (* 0.5 w) kr) *step-distance*))
                (list (getf (mv-params (kit-next b :ic-tsuki :tsuki-l)) :width) (getf (mv-params (kit-command-move b :sp1)) :width))))
  ;; U is a guard again in both forms (no :u hook, no chain skin); the removed base tools (sidegrade rule 2): no JUJISHO,
  ;; no SOGA, no cross links, no stance; slower
  (check (and (null (kit-hook ks :u)) (null (kit-hook ks :hud-guard)) (null (kit-u-tag ks)) (null (kit-l-after-k ks))
              (not (eq (kit-command-move ks :sp1) (kit-command-move b :sp1))) (not (eq (kit-command-move ks :sp2) (kit-command-move b :sp2)))
              (not (eq (kit-command-move ks :sig) tsuki)) (< (kit-walk ks) (kit-walk b)) (< (kit-run ks) (kit-run b))))
  ;; the CPU: the awakening after 150 taken; KESSA guards (0.4) and parries / sends the clones by its :reflex
  (check (and (equal (getf (kit-ai b) :awaken) '(:min-taken 150)) (eq 'ichigo-ai-kessa (getf (kit-ai ks) :reflex))
              (~= 0.4 (getf (kit-ai ks) :guard)) (equal (kit-form-name ks) "KESSA") (member :kessa (kit-hide b)) (member :shikai (kit-hide ks)))))
;; ================================================================ ENDLESS (docs/duel/DUEL_ENDLESS.md, endless-rules.lisp)
(defun snap (c f &rest kv)
  (append kv (list :character c :form f :konpaku 5 :reiatsu 123.5 :fs 42.25 :awaken 37.0 :awakened (kit-awakening (kit c f))
                   :meter 55.0)))
(defun carry (c f choice &rest kv) (endless-carry (apply #'snap c f kv) choice))
;; Konpaku + 2, at most 9; Reiatsu and flash step bit-identical; the rest comes from the fresh spawn
(check (equal '(3 9 9 9) (mapcar (lambda (k) (getf (carry :yamamoto :base :stay :konpaku k) :konpaku)) '(1 7 8 9))))
(check (every (lambda (cf) (let ((r (carry (first cf) (second cf) :stay)))
                             (and (eql 123.5 (getf r :reiatsu)) (eql 42.25 (getf r :fs)))))
              *forms*))
;; not awakened: the awakening gauge and the kit meter (Inferno) kept; Hellfire ends like its timer: the base, meter 0
(let ((r (carry :yamamoto :base :stay)))
  (check (and (eq :base (getf r :form)) (eql 37.0 (getf r :awaken)) (null (getf r :awakened)) (eql 55.0 (getf r :meter)))))
(let ((r (carry :yamamoto :hellfire :stay)))
  (check (and (eq :base (getf r :form)) (eql 37.0 (getf r :awaken)) (zerop (getf r :meter)))))
;; revert, every awakened form of every character: the base, not awakened, the awakening full, the meter 0
(check (every (lambda (cf) (let ((r (carry (first cf) (second cf) :revert)))
                             (and (eq :base (getf r :form)) (null (getf r :awakened)) (= *awaken-max* (getf r :awaken))
                                  (zerop (getf r :meter)))))
              (remove-if-not (lambda (cf) (kit-awakening (apply #'kit cf))) *forms*)))
;; stay: Yamamoto East / West -> East; every Kenpachi awakened form -> cup 1 at NOME 10 (the user's decision 2026-09-29:
;; no cup kept); Rukia's bands -> -18 at cold 0
(check (every (lambda (f) (eq :bankai-east (getf (carry :yamamoto f :stay) :form))) '(:bankai-east :bankai-west)))
(check (every (lambda (f) (let ((r (carry :kenpachi f :stay)))
                            (and (eq :nozarashi (getf r :form)) (= *nome-awaken* (getf r :meter)) (getf r :awakened)
                                 (zerop (getf r :awaken)))))
              '(:nozarashi :ryote :nomihose :bankai :kataude)))
(check (every (lambda (f) (let ((r (carry :rukia f :stay))) (and (eq :m18 (getf r :form)) (zerop (getf r :meter)))))
              '(:m18 :m50 :zero)))
(check (eq :base (getf (carry :kenpachi :base :stay) :form)))
;; generic guards (a new character's forms must satisfy them): every stay target of an awakened form is awakened, none
;; is any kit's :bankai-form or its arm's :to, and a timed form's stay target is not timed
(let ((targets (loop for cf in *forms* when (kit-awakening (apply #'kit cf))
                     collect (list (first cf) (endless-stay-form (apply #'kit cf)))))
      (second-forms (loop for cf in *forms* for k = (apply #'kit cf)
                          when (kit-bankai-form k) collect (list (first cf) (kit-bankai-form k))
                          when (kit-pips k) collect (list (first cf) (getf (kit-pips k) :to)))))
  (check (every (lambda (ct) (kit-awakening (apply #'kit ct))) targets))
  (check (notany (lambda (ct) (member ct second-forms :test #'equal)) targets))
  (check (every (lambda (cf) (null (kit-duration (kit (first cf) (endless-stay-form (apply #'kit cf))))))
                (remove-if-not (lambda (cf) (kit-duration (apply #'kit cf))) *forms*))))
;; §5: a Bankai at Konpaku 4 leaves 1, the clear gives 3, and cup 3 may take the Bankai again at 3
(check (and (= 3 (getf (carry :kenpachi :bankai :stay :konpaku 1) :konpaku)) (bankai-allowed-p t 3)))
;; the ramp: the difficulty never falls and clamps at HARD, equal from 12 on; the awakening and Reishi never fall
(check (every (lambda (fl)
                (loop for n from 1 to 40
                      for d = (position (endless-difficulty fl n) '(:easy :normal :hard)) and d0 = -1 then d
                      always (and d (>= d d0)) finally (return t)))
              '(:easy :normal :hard)))
(check (and (eq :hard (endless-difficulty :easy 5)) (eq :normal (endless-difficulty :easy 3)) (eq :hard (endless-difficulty :normal 3))
            (eq :easy (endless-difficulty :easy 1)) (eq :hard (endless-difficulty :hard 1))
            (every (lambda (fl) (loop for n from 12 to 60 always (equal (endless-ramp n) (endless-ramp 12)))) '(:easy :normal :hard))))
(check (loop for n from 1 to 40 for r = (endless-ramp n) and r0 = (endless-ramp 1) then r
             always (and (>= (third r) (third r0)) (or (fourth r) (not (fourth r0))) (>= (fifth r) (fifth r0)))))
(check (equal '(0 50 100 100) (mapcar (lambda (n) (third (endless-ramp n))) '(4 5 7 9))))
(check (and (not (fourth (endless-ramp 8))) (fourth (endless-ramp 9)) (= 110 (fifth (endless-ramp 11))) (= 120 (fifth (endless-ramp 12)))))
;; the bag: each bag the roster once; never the same opponent twice in a row (seeds 1-200); a seed replays; seeds differ
(flet ((run (seed n roster) (loop for s from 1 to n collect (endless-opponent seed s roster))))
  (dolist (roster (list *roster* '(:a :b) '(:a :b :c :d :e)))
    (let ((n (length roster)))
      (check (loop for seed from 1 to 200 for r = (run seed (* 6 n) roster)
                   always (and (loop for b below 6 always (null (set-exclusive-or (subseq r (* b n) (* (1+ b) n)) roster)))
                               (loop for (a b) on r while b never (eq a b)))))))
  (check (equal (run 7 12 *roster*) (run 7 12 *roster*)))
  (check (> (length (remove-duplicates (loop for seed from 1 to 20 collect (run seed 3 *roster*)) :test #'equal)) 2)))
(check (/= (endless-stage-seed 1 2) (endless-stage-seed 1 3) (endless-stage-seed 2 2)))
;; the record: more stages wins, equal stages less time, an empty record (0) loses to any stage, 0 stages never writes
(check (and (endless-better-p 3 500 2 100) (not (endless-better-p 2 50 3 900)) (endless-better-p 3 400 3 500)
            (not (endless-better-p 3 500 3 500)) (not (endless-better-p 3 600 3 500)) (endless-better-p 1 999 0 0)
            (not (endless-better-p 0 10 0 0))))


;; the DANGAI boss (DUEL_ROGUE §5, 永凍): the base kit's :boss hook; every band's :reset hook (back to -50) and :tick
(check (and (eq (kit-hook (kit :rukia :base) :boss) 'rukia-boss)
            (every (lambda (f) (and (eq (kit-hook (kit :rukia f) :reset) 'rukia-reset) (eq (kit-hook (kit :rukia f) :tick) 'rukia-tick)))
                   '(:m18 :m50 :zero))))

;;; >>> BEGIN RUKIA-CPU-TESTS: the checks of Rukia's own CPU's shipped values and pure RUKIA-AI-* functions (duel/lisp/rukia-ai.lisp;
;;; her CPU search, docs/research/rukia-ai-drsi, DUEL_RUKIA_TYBW §17: a cell may edit THIS SECTION ONLY, to pin its own CPU)
(let ((b (kit :rukia :base)) (m18 (kit :rukia :m18)) (m50 (kit :rukia :m50)) (z (kit :rukia :zero)))
  ;; AI keys: the awakening rule, cooling (-50 not below half a guard gauge), bracing at zero, the stun follow-ups, the
  ;; opponent's wait
  (check (and (equal (getf (kit-ai b) :awaken) '(:melee-share 0.6 :min-taken 1800)) (equal (getf (kit-ai b) :stun-follow) '(:sp2 2.4 5.0))
              (equal (getf (kit-ai m18) :cool) '(:p 0.3 :near 3.5)) (= 50 (getf (getf (kit-ai m50) :cool) :min-gg))
              (null (getf (kit-ai z) :cool)) (getf (kit-ai z) :brace) (null (getf (kit-ai z) :zero-exit))
              (equal (getf (kit-ai z) :opp-intent) '(:zone 2 :defend 2)) (null (getf (kit-ai b) :opp-intent))))
  ;; every band's L after a K link by its chance
  (check (every (lambda (f) (numberp (getf (kit-ai (kit :rukia f)) :l-after-k))) '(:m18 :m50 :zero)))
  ;; her CPU's hooks: the bursts' chance by its function (link 3 > link 2 > link 1, EASY <= NORMAL <= HARD), L held beyond
  ;; 6 m, SP1 held beyond 4.5 m
  (check (and (eq 'rukia-ai-burst-p (getf (kit-ai b) :l-after-k)) (eq 'rukia-ai-burst-p (getf (kit-ai b) :l-after-j))
              (eq 'rukia-ai-sig-hold (getf (kit-ai b) :sig-hold)) (eq 'rukia-ai-sp1-hold (getf (kit-ai b) :sp1-hold))
              (= 1 (rukia-ai-sig-hold b 4.0)) (> (rukia-ai-sig-hold b 7.0) *ru-l-hold*)
              (= 1 (rukia-ai-sp1-hold b 3.0)) (> (rukia-ai-sp1-hold b 5.5) 16)
              (null (getf (kit-ai b) :oki))
              (every (lambda (p) (<= (getf p :easy) (getf p :normal) (getf p :hard)))
                     (list *ai-ru-burst-1* *ai-ru-burst-2* *ai-ru-burst-3* *ai-ru-zone-kido* *ai-ru-sp2-layers*))
              (every (lambda (d) (<= (getf *ai-ru-burst-1* d) (getf *ai-ru-burst-2* d) (getf *ai-ru-burst-3* d))) '(:easy :normal :hard))))
  ;; cell b0a0 (round 1): the K string on a hit in every form (:string-k), no O ender on a victim who isn't red (the ender's
  ;; payoff pick instead: RUKIA-AI-SP-ENDER), RIKUJOKORO held 14 f past SOKATSUI's 16 (the bind long enough for the O)
  (check (and (every (lambda (k) (and (= 1.0 (getf (kit-ai k) :string-k)) (= 0.0 (getf (kit-ai k) :o-ender)))) (list b m18 m50 z))
              (eq 'rukia-ai-sp-ender (getf (kit-ai b) :sp-ender)) (eq 'rukia-ai-reflex (getf (kit-ai b) :reflex))
              (= 27 *ai-ru-rikujo-hold*) (= 43 (rukia-ai-sp1-hold b 5.5)) (= 1 *ai-ru-bind-bar*)
              (equal (getf (getf (kit-ai b) :ranges) :poke) '(2.1 2.8)) (equal (getf (getf (kit-ai b) :ranges) :mid) '(3.0 5.0))
              (every (lambda (p) (<= (getf p :easy) (getf p :normal) (getf p :hard)))
                     (list *ai-ru-mu-p* *ai-ru-mu-guard-p* *ai-ru-seal-o* *ai-ru-k-ender-l*))
              (= 1.0 (getf *ai-ru-mu-p* :hard)) (= 1.0 (getf *ai-ru-seal-o* :hard))))
  ;; her matchup tables: every zone's options are hers, their weights >= 0; the rows as shipped; Lille's :guard-on gone at the
  ;; merge (2026-10-26, DUEL_RUKIA_TYBW §17.9: the anti-dash Hoho answers his awakened dash L, the EN / SHIN stances' L)
  (let ((opts '(:q :f :byakurai :tsukishiro :sokatsui :rikujo :sp2 :enbu :breaker :guard :back :in :wait))
        (zones '(:close :his-j :k :mid :far :out)))
    (check (every (lambda (row)
                    (every (lambda (z) (loop for (o w) on (getf row z) by #'cddr always (and (member o opts) (realp w) (>= w 0))))
                           zones))
                  (cons *ai-ru-mu-default* (mapcar #'rest *ai-ru-mu*))))
    (check (every (lambda (z) (getf *ai-ru-mu-default* z)) zones))
    (check (equal (mapcar #'first *ai-ru-mu*) '(:barro :hisagi :yamamoto)))
    (check (and (= 0.0 (getf *ai-ru-mu-default* :breaker-p)) (notany (lambda (row) (getf (rest row) :breaker-p)) *ai-ru-mu*)))
    (check (and (notany (lambda (row) (getf (rest row) :guard-on)) *ai-ru-mu*) (null (getf *ai-ru-mu-default* :guard-on))))
    (check (and (eq :br-e-l1 (mv-name (kit-command-move (kit :barro :jilliel) :sig)))
                (eq :br-oe-l1 (mv-name (kit-command-move (kit :barro :shin) :sig)))
                (eq :br-to-en (mv-name (kit-command-move (kit :barro :jilliel-kin) :sig)))))
    ;; cell b0a1: the measured payoffs (:poke): every neutral poke 0 by default, RIKUJOKORO 1 against Yamamoto and Lille (Lille's
    ;; TSUKISHIRO / BYAKURAI 0.25), Lille's :no-busy and :hold-forms (his awakened stance EN: the kit forms he has)
    (let ((dp (getf *ai-ru-mu-default* :poke)) (br (rest (assoc :barro *ai-ru-mu*))))
      (check (and (equal dp '(:f 0.0 :byakurai 0.0 :tsukishiro 0.0 :rikujo 0.0 :sokatsui 0.0 :sp2 0.0 :breaker 0.0))
                  (equal (getf (rest (assoc :yamamoto *ai-ru-mu*)) :poke) '(:rikujo 1.0))
                  (equal (getf br :poke) '(:rikujo 1.0 :tsukishiro 0.25 :byakurai 0.25))
                  (eq t (getf br :no-busy)) (equal (getf br :hold-forms) '(:jilliel :shin))
                  (every (lambda (f) (kit :barro f)) (getf br :hold-forms))
                  (loop for (o w) on dp by #'cddr always (and (member o opts) (zerop w)))))))
  ;; cell b0a1 (b2a0's reactive layer, ported): the oki, the anti-step, the range punish (EASY <= NORMAL <= HARD), the plain O
  ;; out of the neutral and the cash (no ENBU in the Shikai's :moves, *AI-RU-CASH-O* 0), the SPs out of the Shikai's :moves,
  ;; his knockdown's frames left (:down 30 + :wakeup 30, seen at HARD's delay 8), the oki's lead in its verified window
  (check (and (every (lambda (p) (<= (getf p :easy) (getf p :normal) (getf p :hard)))
                     (list *ai-ru-oki* *ai-ru-anti-step* *ai-ru-range-p* *ai-ru-sharp* *ai-ru-mu-guard-p*))
              (= 1.0 (getf *ai-ru-anti-step* :hard)) (= 1.0 (getf *ai-ru-mu-guard-p* :hard)) (= 0.95 (getf *ai-ru-burst-3* :hard))
              (every (lambda (d) (zerop (getf *ai-ru-cash-o* d))) '(:easy :normal :hard))
              (notany (lambda (band) (or (getf (cddr band) :kikon) (getf (cddr band) :sp1) (getf (cddr band) :sp2)))
                      (getf (kit-ai b) :moves))
              (= 52 (rukia-ai-free-in :down 0 8)) (= 12 (rukia-ai-free-in :wakeup 10 8)) (null (rukia-ai-free-in :stun 3 8))
              (<= 29 *ai-ru-oki-lead* 33) (= 331 *ai-ru-route*))))
  ;; cell b0a2: the awakening after 1800 taken (above); his first-strike envelope at a neutral decision (EASY <= NORMAL <= HARD,
  ;; HARD 0.95), b1a0's values by default, off against Yamamoto (:front :none); the envelope from his J1 (reach + lunge + 0.3 +
  ;; his closing over his J1's startup and her delay)
  (check (and (<= (getf *ai-ru-front* :easy) (getf *ai-ru-front* :normal) (getf *ai-ru-front* :hard)) (= 0.95 (getf *ai-ru-front* :hard))
              (equal *ai-ru-front-values* '(:guard 40 :q 50 :step 25 :f 60 :sp1 55))
              (eq :none (getf (rest (assoc :yamamoto *ai-ru-mu*)) :front)) (null (getf *ai-ru-mu-default* :front))
              (let ((his (kit-command-move (kit :kenpachi :base) :q)))
                (and (~= (+ (mv-reach his) (min 0.8 (mv-slide his)) 0.3) (rukia-ai-envelope 8 his 0.0))
                     (~= (+ (mv-reach his) (min 0.8 (mv-slide his)) 0.3 (* 0.1 (+ (mv-s his) 8)))
                         (rukia-ai-envelope 8 his 0.1))))))
;; cell b1a2: his charged dash (a :dash L: Lille's awakened stance forms only) met with the timed Hoho at the predicted gap
;; (it stands until its S, then slides the clamped d + 1.6 m over 8 frames), and the wait at a neutral decision against it
(check (and (every (lambda (p) (<= (getf p :easy) (getf p :normal) (getf p :hard))) (list *ai-ru-anti-dash* *ai-ru-mu-dash*))
            (= 1.0 (getf *ai-ru-anti-dash* :hard)) (= 1.0 (getf *ai-ru-mu-dash* :hard))
            (= 0.0 (getf *ai-ru-anti-dash* :easy)) (= 0.0 (getf *ai-ru-mu-dash* :easy))
            (= 3.4 *ai-ru-dash-gap*) (= 1 *ai-ru-dash-lead*)
            (= 5.0 (rukia-ai-dash-gap 5.0 0 12 12))                       ; (standing through its S)
            (< (abs (- (rukia-ai-dash-gap 5.0 0 12 16) (- 5.0 (* 4 (/ 6.6 8))))) 1e-4)
            (< (abs (- (rukia-ai-dash-gap 5.0 0 12 30) (- 5.0 6.6))) 1e-4)   ; (the slide's 8 frames, then no more)
            (< (abs (- (rukia-ai-dash-gap 0.2 0 12 13) -0.05)) 1e-4)      ; (the 2 m floor)
            (flet ((dash-l-p (k) (let ((l (kit-command-move k :sig))) (and l (getf (mv-params l) :dash)))))
              (and (every (lambda (f) (dash-l-p (kit :barro f))) '(:jilliel :shin))
                   (notany (lambda (f) (dash-l-p (kit :barro f))) '(:base :jilliel-kin :shin-kin))
                   (notany (lambda (c) (dash-l-p (kit c :base))) '(:yamamoto :kenpachi :rukia :ichigo :senjumaru :hisagi))))))
;;; <<< END RUKIA-CPU-TESTS
