;;;; onehand.lisp — 片手 ONE-HAND, the portrait one-thumb mode (docs/DUEL_MOBILE_DESIGN.md, P0 + the PWA shell).
;;;; The engine's recogniser (engine/lisp/touch.lisp) turns the thumb into gestures; this file lays out the
;;;; flow pad and the chips, maps gestures to P1's vpad buttons (TOUCH-BUTTON, read through the (:touch ...)
;;;; bindings of control.lisp: fighters, rules and the AI never see touch), draws the deck, and talks to the
;;;; page (duel/web/pwa.js: coarse pointer, back gesture, wake lock, the saved SETTINGS). Since 2026-09-28 one-hand is a
;;;; setting (ONE-HAND MODE AUTO / ON / OFF, control.lisp *SETTINGS*): VS CPU and PRACTICE use the deck wherever it is
;;;; in effect (ONE-HAND-EFFECTIVE-P); SET-SETTING / APPLY-SETTINGS put HAND, TAP SPLIT, SENSITIVITY and CAMERA in force.
;;;;   per frame: ONEHAND-FRAME (before the flow)      per vpad read: TOUCH-READ-BEGIN (P1-READER)
;;;;   drawing:   HUD-DECK (battle), HUD-GESTURES (the static card that replaces CONTROLS)
(in-package :duel)

;; *TOUCH* *ONE-HAND* *HAND* *COARSE* *BACK-PRESS*: components.lisp (read by fighter.lisp and flow.lisp)
(defvar *touch-burst* nil "This vpad read: the live flick is a burst (down, P1 in hit / stun / air: BLUE; his move's hit
landed: ORANGE).")
(defvar *deck-key* (list 0 0 0 nil nil 0 0 0 nil) "Window w, h, density, hand, one-hand, safe top / bottom, UI scale, the U chip of the
last TOUCH-LAYOUT!.")
(defvar *wake* nil "Wake lock requested (battle).")
(defparameter *glyph-names* #("" "Q" "STEP" "F" "HOHO" "GUARD" "DASH" "BURST") "TOUCH-GLYPH kinds (7: the duel's Burst).")
(defvar *glyph-seen* -1f4 "TOUCH-GLYPH-T last logged.")

;;; page services (pf_page_get / pf_page_set, duel/web/pwa.js)
(defconstant +pg-coarse+ 0) (defconstant +pg-back+ 1) (defconstant +pg-safe-top+ 3) (defconstant +pg-safe-bottom+ 4)
(defconstant +ps-wake+ 0) (defconstant +ps-manual+ 1 "Page set 1: open the manual page (manual.html) in this window.")
(defconstant +pg-setting+ 10 "Page get / set 10 + i: SETTINGS row i (control.lisp *SETTINGS* order), option index + 1.")

(defun open-manual ()
  "MODE's MANUAL row: the page opens manual.html in the same window (an installed app stays in its window; the
manual's back link returns). Without the page service (the native gate) nothing happens."
  (log-msg "duel manual")
  (page-set +ps-manual+ 1))

(defun portrait-p () (> (window-height) (window-width)))
(defun one-hand-offered-p ()
  "ONE-HAND is listed when the window is portrait or the device is touch-first (a landscape desktop window
never offers it: the deck needs portrait)."
  (or *coarse* (portrait-p)))
(defun one-hand-effective-p ()
  "Would VS CPU / PRACTICE be one-handed here and now (the ONE-HAND MODE setting, control.lisp ONE-HAND-ON-P)?"
  (one-hand-on-p (setting :one-hand) *coarse* (portrait-p)))

;;; ---------------------------------------------------------------- the deck (design §3.3)
;;; Chip i: 0 O, 1 L, 2 I, 3 SP1, 4 SP2, 5 AWAKEN (held 300 ms), 6 pause, 7 RV (REVERSE: a burst, any mode; shown while one is possible, 2026-09-30). CSS px from the right-hand
;;; layout at 390 x 844: x from the right edge, y from the bottom edge; the left hand mirrors x.
;;; The user's playtest (2026-09-27): every chip 100 px higher, and the flow pad grown to the whole thumb area
;;; (chips inside it win their hit circles: TOUCH-LAYOUT! tests chips first).
(defparameter *chip-spots*
  '((170 396 36 "O") (72 380 26 "L") (72 310 26 "I") (72 240 26 "SP1") (72 170 26 "SP2") (270 396 26 "AWK") (32 -200 22 "II")
    (170 472 22 "RV"))
  "Per chip: x from the thumb-side edge, y from the bottom (negative: from the top), radius, label.")
(defparameter *chip-holds* '(0 0 0 0 0 300 0 0))
(defparameter *u-chip-holds* '(0 0 0 0 0 0 0 0) "... with the AWAKEN chip as U (U-CHIP-P): a tap.")

(defun deck-layout ()
  "Values: pad (x0 y0 x1 y1) and chips ((cx cy r) ...), window px, for the current window and *HAND*. P2 (safe-area
insets): the pad keeps 16 CSS px over the home indicator (no change on today's phones: 50 >= 34 + 16) and a chip placed
from the top (the pause chip) stays under the portrait HUD's top block. The chips' spots are the playtest's (§13), not
moved by the insets: the user tuned them on the phones, insets included."
  (let* ((d (pixel-density)) (w (/ (window-width) d)) (h (/ (window-height) d)) (left (eq *hand* :left))
         (hud (/ (portrait-hud-bottom (ui-scale)) d)))
    (flet ((x (from-right) (* d (if left from-right (- w from-right)))) (px (v) (* d v)))
      (values (list (if left (px 32) (px 16)) (px (- h 460)) (if left (px (- w 16)) (px (- w 32))) (px (- h (max 50 (+ *safe-bot* 16)))))
              (loop for (cx cy r) in *chip-spots*
                    collect (list (x cx) (px (if (minusp cy) (max (- cy) (+ hud 10 r)) (- h cy))) (px r)))))))

(declaim (type f32vec *deck*))
(defvar *deck* (make-f32 (+ 4 (* 3 8))) "The laid-out deck in window px: pad x0 y0 x1 y1, then cx cy r per chip.")

(defun deck-update ()
  "Re-lay the deck when the window, the density, the hand or the mode changed (conses: not every frame).
Outside ONE-HAND there is no pad and no chip: a stray finger only makes menu taps."
  (let ((k *deck-key*) (w (window-width)) (h (window-height)) (d (pixel-density)) (s (ui-scale))
        (st (page-get +pg-safe-top+)) (sb (page-get +pg-safe-bottom+)) (u (u-chip-p)))
    (unless (and (= (first k) w) (= (second k) h) (= (third k) d) (eq (fourth k) *hand*) (eq (fifth k) *one-hand*)
                 (= (sixth k) st) (= (seventh k) sb) (= (eighth k) s) (eq (ninth k) u))
      (setf (first k) w (second k) h (third k) d (fourth k) *hand* (fifth k) *one-hand* (sixth k) st (seventh k) sb (eighth k) s
            (ninth k) u *safe-top* st *safe-bot* sb)
      (multiple-value-bind (pad chips) (deck-layout)
        (replace *deck* (mapcar #'f32 (append pad (reduce #'append chips))))
        ;; the portrait frame: under P2's HUD block down to *PT-FRAME-BOTTOM* (over P1's block); the blocks' edges
        (let ((hb (/ (portrait-hud-bottom s) h)) (pt (/ (portrait-p1-top s h) h)))
          (setf (aref *band* 0) (f32 (+ hb 0.03)) (aref *band* 1) (f32 (min *pt-frame-bottom* (- pt 0.03)))
                (aref *band* 2) (f32 hb) (aref *band* 3) (f32 pt)))
        (if *one-hand*
            (touch-layout! *touch* d pad chips (if u *u-chip-holds* *chip-holds*))
            (touch-layout! *touch* d '(0 0 -1 -1) nil)))
      ;; G7: the scene near 1.6 MP on a phone (the UI stays native)
      (setf *scene-scale-cap* (if (or *coarse* *one-hand*) (f32 (min 1.0 (sqrt (/ 1.6e6 (max 1 (* w h)))))) 1f0)))))

(defun onehand-init ()
  "Once, at start: ask the page for the device kind and the saved SETTINGS (a missing or blocked storage answers 0:
the defaults)."
  (setf *coarse* (plusp (page-get +pg-coarse+)))
  (loop for (key) in *settings* for i from 0
        do (setf (svref *setting-ix* i) (setting-from-page key (page-get (+ +pg-setting+ i)))))
  (apply-settings)
  (when *coarse* (setf *auto-render-scale* t))
  (log-msg "duel page: coarse ~a hand ~a settings ~a" *coarse* *hand* (coerce *setting-ix* 'list)))

(defun apply-settings ()
  "Put the SETTINGS in force: HAND, the recogniser's tap split and flick distance, the CAMERA option."
  (let ((cfg (touch-cfg *touch*)))
    (setf *hand* (if (= 1 (setting :hand)) :left :right)
          (gc-tap-split cfg) (f32 (setting-value :tap-split))
          (gc-flick-min cfg) (f32 (setting-value :flick))))
  (set-cam-behind (zerop (setting :camera))))

(defun set-setting (key i)
  "SETTINGS row KEY to option I: in force now and saved by the page."
  (setf (svref *setting-ix* (setting-pos key)) i)
  (apply-settings)
  (page-set (+ +pg-setting+ (setting-pos key)) (1+ i))
  (log-msg "duel setting ~a ~a" key (nth i (third (assoc key *settings*)))))

(defun perfect-up-p (e st)
  "Would a Hoho by E (in state ST) started now be PERFECT? Then a one-hand up-flick is one, rested or not, where it
would be a Step (the user 2026-10-01: the perfect timing is too hard to hit from a rest on a phone), and PERFECT HINT
shows it (hud.lisp HUD-HINT). Free states that take a Hoho, the Hoho affordable (TRY-COMMAND's rule), PERFECT-NOW-P."
  (let ((f (fighter e)) (g (gauges e)))
    (and (member st '(:idle :guard :run)) (battle-p) (not (kit-rooted (fighter-kit f)))
         (hoho-allowed-p nil (gauges-fs g) (fighter-hoho-lock f) (gauges-burst g))
         (perfect-now-p e))))

(defun onehand-frame ()
  "Every frame, before the flow: the page (back gesture, wake lock), the text floor, the deck, then this
frame's finger events."
  (setf *back-press* (plusp (page-get +pg-back+))
        *ui-min-css* (if (portrait-p) 11 0))
  (let ((wake (and *coarse* (battle-p) t)))
    (unless (eq wake *wake*) (setf *wake* wake) (page-set +ps-wake+ (if wake 1 0))))
  (deck-update)
  (let ((st (and *one-hand* *p1* (entity-alive-p *p1*) (state-of *p1*))))
    (setf (touch-rest-up-ok *touch*) (and (member st '(:idle :guard)) t)   ; a rested up-flick is a Hoho from neutral / guard,
          (touch-up-hoho *touch*) (or (eq st :move)          ; any up-flick while attacking (the user 2026-09-30: no dash there),
                                      (perfect-up-p *p1* st))))   ; or when it would be a perfect Hoho (the user 2026-10-01)
  (touch-poll *touch*)
  (unless (sim-running-p) (touch-take! *touch*))            ; menus / pause: no gesture pulse waits for the match
  (let ((g (touch-glyph-t *touch*)))                        ; the combat log names each recognised gesture
    (when (and *combat-log* (/= g *glyph-seen*))
      (setf *glyph-seen* g)
      (clog "P1 gesture ~a" (svref *glyph-names* (touch-glyph *touch*))))))


(defun tap-p () "A tap ended this frame (menus)." (touch-tapped-p *touch*))
(defun touch-tap-zones-p () "Menus note their rows as tap targets (a touch device, or a portrait window)." (one-hand-offered-p))

;;; ---------------------------------------------------------------- touch -> vpad (G3)
(defun touch-read-begin ()
  "Start of P1's vpad read: this read's pulses (TOUCH-TAKE!) and whether a down-flick is a Burst."
  (let ((tr *touch*))
    (touch-take! tr)
    (setf *touch-burst* (and (touch-pulse-p tr +tp-flick+) (touch-flick-down-p tr) *p1*
                             (or (member (state-of *p1*) '(:stun :air)) (eq (burst-ok-p *p1*) :orange)) t))
    (when *touch-burst*                                   ; the contact is spent: no stick, no Step held after a Burst (the
      (touch-spend! tr)                                   ; thumb running on past the run ring held Step: ORANGE's freed
      (setf (touch-glyph tr) 7))))                        ; recovery back-stepped; the user 2026-09-30)

(defun u-chip-p ()
  "P1's form has a :u hook (its U is a move, not a guard: a parry): a resting thumb does nothing and the spent
AWAKEN chip is U (the user's default, DUEL_MOBILE_DESIGN §15.1)."
  (and *one-hand* *p1* (entity-alive-p *p1*) (fighter *p1*) (kit-hook (kit-of *p1*) :u) t))

(defun touch-button (name)
  "Is vpad button NAME down from the thumb deck (design §3.2 / §3.4; the 2026-09-28 remap, §15: a tap in the pad's
low zone = J, high zone = K, an up-flick = a forward Step, the dash)?"
  (let* ((tr *touch*) (burst *touch-burst*))
    (flet ((chip (i) (touch-chip-down-p tr i)) (pulse (b) (touch-pulse-p tr b)))
      (case name
        (:guard (if (u-chip-p) (chip 5) (touch-resting-p tr)))
        (:quick (or (pulse +tp-tap+) burst (chip 7)))         ; RV: a burst in any mode (the state picks it)
        (:mod (or burst (pulse +tp-hoho+) (chip 3) (chip 4) (chip 7)))
        (:step (and (not burst) (or (pulse +tp-flick+) (pulse +tp-hoho+) (touch-step-held-p tr))))
        (:flash (or (pulse +tp-tap-hi+) (chip 3)))
        (:sig (or (chip 1) (chip 4)))
        (:breaker (chip 2))
        (:kikon (chip 0))
        (:awaken (and (not (u-chip-p)) (chip 5)))))))

(defun touch-pause-p () "The pause chip was touched this frame." (and *one-hand* (touch-chip-hit-p *touch* 6)))

;;; ---------------------------------------------------------------- menus (G9)
(defvar *menu-rows* (make-array 16 :initial-element nil) "HUD-MENU's rows last drawn: #(x0 y0 x1 y1) each, NIL after.")
(defun note-menu-row (i x0 y0 x1 y1)
  (when (< i 15)
    (let ((r (or (svref *menu-rows* i) (setf (svref *menu-rows* i) (make-array 4)))))
      (setf (svref r 0) x0 (svref r 1) y0 (svref r 2) x1 (svref r 3) y1)
      (setf (svref *menu-rows* (1+ i)) nil))))
(defun tapped-row (n)
  "The menu row (< N) a tap landed on this frame, or NIL."
  (when (tap-p)
    (let ((x (touch-tap-x *touch*)) (y (touch-tap-y *touch*)))
      (loop for i below n for r = (svref *menu-rows* i) while r
            when (and (<= (svref r 0) x (svref r 2)) (<= (svref r 1) y (svref r 3))) do (return i)))))
(defun tap-third ()
  "A tap this frame: -1 left third of the screen, 1 right third, 0 the middle; NIL without a tap."
  (when (tap-p)
    (let ((u (/ (touch-tap-x *touch*) (max 1 (window-width))))) (cond ((< u 0.33) -1) ((> u 0.67) 1) (t 0)))))

;;; ---------------------------------------------------------------- drawing
(defun-fast %ring (cx cy r wd cr cg cb ca)
  "A ring of radius R, WD px wide, 24 segments."
  (declare (single-float cx cy r wd cr cg cb ca))
  (let ((r1 (+ r wd)))
    (declare (single-float r1))
    (dotimes (i 24)
      (let* ((a0 (* (i->f i) 0.2617994f0)) (a1 (+ a0 0.2617994f0))
             (c0 (f-cos a0)) (s0 (f-sin a0)) (c1 (f-cos a1)) (s1 (f-sin a1)))
        (declare (single-float a0 a1 c0 s0 c1 s1))
        (%hq (+ cx (* r c0)) (+ cy (* r s0)) (+ cx (* r1 c0)) (+ cy (* r1 s0)) (+ cx (* r1 c1)) (+ cy (* r1 s1))
             (+ cx (* r c1)) (+ cy (* r s1)) cr cg cb ca)))))

(defun-fast %arc (cx cy r wd frac cr cg cb ca)
  "FRAC (0..1) of a ring of radius R, WD px wide, clockwise from the top (Rukia's frost arc under the thumb)."
  (declare (single-float cx cy r wd frac cr cg cb ca))
  (let ((r1 (+ r wd)) (n (f->i (* 24f0 (f-clamp frac 0f0 1f0)))))
    (declare (single-float r1) (fixnum n))
    (dotimes (i n)
      (let* ((a0 (- (* (i->f i) 0.2617994f0) 1.5707964f0)) (a1 (+ a0 0.2617994f0))
             (c0 (f-cos a0)) (s0 (f-sin a0)) (c1 (f-cos a1)) (s1 (f-sin a1)))
        (declare (single-float a0 a1 c0 s0 c1 s1))
        (%hq (+ cx (* r c0)) (+ cy (* r s0)) (+ cx (* r1 c0)) (+ cy (* r1 s0)) (+ cx (* r1 c1)) (+ cy (* r1 s1))
             (+ cx (* r c1)) (+ cy (* r s1)) cr cg cb ca)))))

(defun-fast %disc (cx cy r cr cg cb ca)
  "A filled disc (a 24-gon)."
  (declare (single-float cx cy r cr cg cb ca))
  (dotimes (i 24)
    (let* ((a0 (* (i->f i) 0.2617994f0)) (a1 (+ a0 0.2617994f0)))
      (declare (single-float a0 a1))
      (%hq cx cy (+ cx (* r (f-cos a0))) (+ cy (* r (f-sin a0))) (+ cx (* r (f-cos a1))) (+ cy (* r (f-sin a1))) cx cy
           cr cg cb ca))))

(defparameter *c-chip* '(1 1 1 0.9))

(defparameter *chip-labels* (coerce (mapcar #'fourth *chip-spots*) 'simple-vector))

(defun hud-deck (s)
  "The thumb deck: the flow pad's outline and its tap split (F above, Q below), the chips (lit while held; AWAKEN only
at EVOLUTION or a Bankai ready), the ink ring under the thumb, and the recognised gesture's glyph at the thumb for 0.3 s
(the misread teacher)."
  (let* ((tr *touch*) (d (touch-dpx tr)) (dk *deck*)
         (u (u-chip-p))                                  ; a :u form: the chip is U
         (evo (and *p1* (or u (gauges-evolution (gauges *p1*)) (bankai-ready-p *p1*)))))   ; AWAKEN: EVOLUTION, or the Bankai
                                                                                          ; ready (cup 3, red, free)
    (%houtline (aref dk 0) (aref dk 1) (- (aref dk 2) (aref dk 0)) (- (aref dk 3) (aref dk 1)) 1f0 1f0 1f0 0.12f0)
    (let* ((y (touch-split-y tr)) (left (eq *hand* :left))                  ; the tap zones' line, named at the far edge
           (x (if left (- (aref dk 2) (* 6 d)) (+ (aref dk 0) (* 6 d)))) (al (if left :right :left)))
      (%hrect (aref dk 0) y (- (aref dk 2) (aref dk 0)) (max 1f0 d) 1f0 1f0 1f0 0.18f0)
      (hud-text "F" x (- y (* 13 s)) (* 1.5 s) '(1 1 1 0.4) :align al :shadow nil)
      (hud-text "Q" x (+ y (* 3 s)) (* 1.5 s) '(1 1 1 0.4) :align al :shadow nil))
    (dotimes (i 8)
      (unless (or (and (= i 5) (not evo)) (and (= i 7) (not (and *p1* (burst-ok-p *p1*)))))   ; RV: while a burst is possible
        (let ((on (touch-chip-down-p tr i)) (cx (aref dk (+ 4 (* 3 i)))) (cy (aref dk (+ 5 (* 3 i)))) (r (aref dk (+ 6 (* 3 i)))))
          (%disc cx cy r 0.05 0.04 0.07 (if on 0.85 0.45))
          (%ring cx cy r (* 2f0 d) 1.0 (if on 0.85 0.55) (if on 0.4 0.3) (if on 1.0 0.7))
          (when (= i 1)                                  ; a refused L (cooling, cold, its kit's refusal): the chip flashes
            (let ((fl (f32 (- 1.0 (* 4.0 (- (fx-clock) (aref *refused-t* 0)))))))
              (when (> fl 0.0) (%disc cx cy r 1.0 1.0 1.0 (* 0.7f0 fl)) (%ring cx cy (* 1.15 r) (* 3f0 d) 1.0 1.0 1.0 fl))))
          (hud-text (if (and u (= i 5)) "U" (svref *chip-labels* i)) cx (- cy (* 3.5 s)) s *c-chip* :align :center :shadow nil))))
    (when (touch-active-p tr)                              ; the floating stick: an ink ring at its origin
      (%ring (touch-ox tr) (touch-oy tr) (* d 48f0) (* 2f0 d) 1.0 1.0 1.0 (if (touch-resting-p tr) 0.35 0.6))
      (let ((h (and *p1* (kit-hook (kit-of *p1*) :deck)))) (when h (funcall h *p1* (touch-ox tr) (touch-oy tr) d)))   ; a form's own ring
      (let ((m (and *p1* (kit-meter (kit-of *p1*)))))      ; Rukia: resting cools her: the frost arc = C / 200 (the two
        (when (getf m :temp)                                 ; bars round the ring, a notch at the half), grey in the THAW
          (let* ((g (gauges *p1*)) (k (/ (gauges-meter g) *cold-max*)) (lock (plusp (gauges-meter-idle g)))   ; lock;
                 (zero (eq (fighter-form (fighter *p1*)) :zero)) (r (* d 52f0)))                       ; white ring at zero
            (when zero (%ring (touch-ox tr) (touch-oy tr) r (* 3f0 d) 1.0 1.0 1.0 0.35))
            (if lock
                (%arc (touch-ox tr) (touch-oy tr) r (* 3f0 d) k 0.55 0.56 0.6 0.8)
                (%arc (touch-ox tr) (touch-oy tr) r (* 3f0 d) k 0.92 0.96 1.0 (if zero (+ 0.6 (* 0.4 (hud-pulse 3.0))) 0.9)))
            (%hrect (- (touch-ox tr) d) (+ (touch-oy tr) r) (* 2f0 d) (* 3f0 d) 1.0 1.0 1.0 0.8))))) ; the half: bar 1 full
    (let ((age (- (* 1000f0 (elapsed-time)) (touch-glyph-t tr))))
      (when (and (< age 300) (plusp (touch-glyph tr)))
        (hud-text (svref *glyph-names* (touch-glyph tr)) (touch-glyph-x tr) (- (touch-glyph-y tr) (* 60 d)) (* 2 s)
                  '(1 0.85 0.4 1) :align :center)))))

(defparameter *gesture-card*
  '(("TAP LOW HALF" "QUICK  (J)") ("TAP HIGH HALF" "FLASH  (K)  3 TAPS = STRING") ("HOLD STILL" "GUARD")
    ("DRAG" "MOVE  (FAR = RUN)") ("FLICK UP" "DASH  (KEEP GOING = RUN)") ("FLICK DOWN / SIDE" "STEP BACK / SIDESTEP")
    ("HOLD, THEN FLICK UP" "HOHO")
    ("FLICK DOWN WHEN HIT" "BURST  (AS YOUR HIT LANDS: CHAIN)") ("O / RV" "KIKON RUSH (HOLD = KIKON) / REVERSE")
    ("L / I" "SIGNATURE / BREAKER")
    ("SP1 / SP2" "SPECIALS") ("AWK (HOLD)" "AWAKEN") ("II / BACK" "PAUSE"))
  "The static gesture card (ONE-HAND's CONTROLS).")

(defun hud-gestures (w h s)
  (ui-rect 0 0 w h '(0 0 0 0.75))
  (ui-big-text "ONE HAND" (floor w 2) (* 0.08 h) (* 3 s) *white* '(0.7 0.25 0.05 1) s)
  (let ((sc (fit-scale "FLICK DOWN WHEN HIT" s (* 0.9 w))))
    (loop for (a b) in *gesture-card* for i from 0
          for y = (+ (* 0.18 h) (* i (max (* 22 sc) (* 0.058 h)))) do   ; a tall screen: the rows spread down
            (ui-text a (floor w 2) y :scale sc :align :center :color *ember*)
            (ui-text b (floor w 2) (+ y (* 9 sc)) :scale (max 1 (fit-scale b sc (* 0.95 w))) :align :center :color *white*)))
  (ui-text "TAP TO GO BACK" (floor w 2) (* 0.94 h) :scale s :align :center :color *dim* :shadow t))
