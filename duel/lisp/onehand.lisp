;;;; onehand.lisp — 片手 ONE-HAND, the portrait one-thumb mode (docs/DUEL_MOBILE_DESIGN.md, P0 + the PWA shell).
;;;; The engine's recogniser (engine/lisp/touch.lisp) turns the thumb into gestures; this file lays out the
;;;; flow pad and the chips, maps gestures to P1's vpad buttons (TOUCH-BUTTON, read through the (:touch ...)
;;;; bindings of control.lisp: fighters, rules and the AI never see touch), draws the deck, and talks to the
;;;; page (duel/web/pwa.js: coarse pointer, back gesture, wake lock, the saved HAND).
;;;;   per frame: ONEHAND-FRAME (before the flow)      per vpad read: TOUCH-READ-BEGIN (P1-READER)
;;;;   drawing:   HUD-DECK (battle), HUD-GESTURES (the static card that replaces CONTROLS)
(in-package :duel)

;; *TOUCH* *ONE-HAND* *HAND* *COARSE* *BACK-PRESS*: components.lisp (read by fighter.lisp and flow.lisp)
(defvar *touch-burst* nil "This vpad read: the live flick is a Burst (down, P1 in hit / stun / air).")
(defvar *deck-key* (list 0 0 0 nil nil) "Window w, h, density, hand, one-hand of the last TOUCH-LAYOUT!.")
(defvar *wake* nil "Wake lock requested (battle).")
(defparameter *glyph-names* #("" "Q" "STEP" "F" "HOHO" "GUARD" "BURST") "TOUCH-GLYPH kinds (6: the duel's Burst).")
(defvar *glyph-seen* -1f4 "TOUCH-GLYPH-T last logged.")

;;; page services (pf_page_get / pf_page_set, duel/web/pwa.js)
(defconstant +pg-coarse+ 0) (defconstant +pg-back+ 1) (defconstant +pg-hand+ 2)
(defconstant +ps-wake+ 0) (defconstant +ps-hand+ 1)

(defun portrait-p () (> (window-height) (window-width)))
(defun one-hand-offered-p ()
  "ONE-HAND is listed when the window is portrait or the device is touch-first (a landscape desktop window
never offers it: the deck needs portrait)."
  (or *coarse* (portrait-p)))

;;; ---------------------------------------------------------------- the deck (design §3.3)
;;; Chip i: 0 O, 1 L, 2 I, 3 SP1, 4 SP2, 5 AWAKEN (held 300 ms), 6 pause. CSS px from the right-hand
;;; layout at 390 x 844: x from the right edge, y from the bottom edge; the left hand mirrors x.
(defparameter *chip-spots*
  '((170 296 36 "O") (72 280 26 "L") (72 212 26 "I") (72 144 26 "SP1") (72 76 26 "SP2") (270 296 26 "AWK") (32 -200 22 "II"))
  "Per chip: x from the thumb-side edge, y from the bottom (negative: from the top), radius, label.")
(defparameter *chip-holds* '(0 0 0 0 0 300 0))

(defun deck-layout ()
  "Values: pad (x0 y0 x1 y1) and chips ((cx cy r) ...), window px, for the current window and *HAND*."
  (let* ((d (pixel-density)) (w (/ (window-width) d)) (h (/ (window-height) d)) (left (eq *hand* :left)))
    (flet ((x (from-right) (* d (if left from-right (- w from-right)))) (px (v) (* d v)))
      (values (list (if left (px 114) (px 16)) (px (- h 244)) (if left (px (- w 16)) (px (- w 114))) (px (- h 50)))
              (loop for (cx cy r) in *chip-spots*
                    collect (list (x cx) (px (if (minusp cy) (- cy) (- h cy))) (px r)))))))

(declaim (type f32vec *deck*))
(defvar *deck* (make-f32 (+ 4 (* 3 7))) "The laid-out deck in window px: pad x0 y0 x1 y1, then cx cy r per chip.")

(defun deck-update ()
  "Re-lay the deck when the window, the density, the hand or the mode changed (conses: not every frame).
Outside ONE-HAND there is no pad and no chip: a stray finger only makes menu taps."
  (let ((k *deck-key*) (w (window-width)) (h (window-height)) (d (pixel-density)))
    (unless (and (= (first k) w) (= (second k) h) (= (third k) d) (eq (fourth k) *hand*) (eq (fifth k) *one-hand*))
      (setf (first k) w (second k) h (third k) d (fourth k) *hand* (fifth k) *one-hand*)
      (multiple-value-bind (pad chips) (deck-layout)
        (replace *deck* (mapcar #'f32 (append pad (reduce #'append chips))))
        (if *one-hand*
            (touch-layout! *touch* d pad chips *chip-holds*)
            (touch-layout! *touch* d '(0 0 -1 -1) nil)))
      ;; G7: the scene near 1.6 MP on a phone (the UI stays native)
      (setf *scene-scale-cap* (if (or *coarse* *one-hand*) (f32 (min 1.0 (sqrt (/ 1.6e6 (max 1 (* w h)))))) 1f0)))))

(defun onehand-init ()
  "Once, at start: ask the page for the device kind and the saved HAND."
  (setf *coarse* (plusp (page-get +pg-coarse+))
        *hand* (if (= 2 (page-get +pg-hand+)) :left :right))
  (when *coarse* (setf *auto-render-scale* t))
  (log-msg "duel page: coarse ~a hand ~a" *coarse* *hand*))

(defun set-hand (hand)
  (setf *hand* hand)
  (page-set +ps-hand+ (if (eq hand :left) 2 1))
  (log-msg "duel hand ~a" hand))

(defun onehand-frame ()
  "Every frame, before the flow: the page (back gesture, wake lock), the text floor, the deck, then this
frame's finger events."
  (setf *back-press* (plusp (page-get +pg-back+))
        *ui-min-css* (if (portrait-p) 11 0))
  (let ((wake (and *coarse* (battle-p) t)))
    (unless (eq wake *wake*) (setf *wake* wake) (page-set +ps-wake+ (if wake 1 0))))
  (deck-update)
  (setf (touch-rest-up-ok *touch*)                        ; a rested up-flick is a Hoho only from neutral / guard
        (and *one-hand* *p1* (entity-alive-p *p1*) (member (state-of *p1*) '(:idle :guard)) t))
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
    (setf *touch-burst* (and (touch-pulse-p tr +tp-flick+) (touch-flick-down-p tr)
                             *p1* (member (state-of *p1*) '(:stun :air)) t))
    (when *touch-burst*                                   ; no Step held after a Burst (it would buffer a Step)
      (setf (touch-flick-hold tr) 0 (touch-glyph tr) 6))))

(defun touch-button (name)
  "Is vpad button NAME down from the thumb deck (design §3.2 / §3.4)?"
  (let* ((tr *touch*) (burst *touch-burst*))
    (flet ((chip (i) (touch-chip-down-p tr i)) (pulse (b) (touch-pulse-p tr b)))
      (case name
        (:guard (touch-resting-p tr))
        (:quick (or (pulse +tp-tap+) burst))
        (:mod (or burst (pulse +tp-hoho+) (chip 3) (chip 4)))
        (:step (and (not burst) (or (pulse +tp-flick+) (pulse +tp-hoho+) (touch-step-held-p tr))))
        (:flash (or (pulse +tp-up+) (chip 3)))
        (:sig (or (chip 1) (chip 4)))
        (:breaker (chip 2))
        (:kikon (chip 0))
        (:awaken (chip 5))))))

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
  "The thumb deck: the flow pad's outline, the chips (lit while held; AWAKEN only at EVOLUTION), the ink ring under
the thumb, and the recognised gesture's glyph at the thumb for 0.3 s (the misread teacher)."
  (let* ((tr *touch*) (d (touch-dpx tr)) (dk *deck*) (evo (and *p1* (gauges-evolution (gauges *p1*)))))
    (%houtline (aref dk 0) (aref dk 1) (- (aref dk 2) (aref dk 0)) (- (aref dk 3) (aref dk 1)) 1f0 1f0 1f0 0.12f0)
    (dotimes (i 7)
      (unless (and (= i 5) (not evo))
        (let ((on (touch-chip-down-p tr i)) (cx (aref dk (+ 4 (* 3 i)))) (cy (aref dk (+ 5 (* 3 i)))) (r (aref dk (+ 6 (* 3 i)))))
          (%disc cx cy r 0.05 0.04 0.07 (if on 0.85 0.45))
          (%ring cx cy r (* 2f0 d) 1.0 (if on 0.85 0.55) (if on 0.4 0.3) (if on 1.0 0.7))
          (hud-text (svref *chip-labels* i) cx (- cy (* 3.5 s)) s *c-chip* :align :center :shadow nil))))
    (when (touch-active-p tr)                              ; the floating stick: an ink ring at its origin
      (%ring (touch-ox tr) (touch-oy tr) (* d 48f0) (* 2f0 d) 1.0 1.0 1.0 (if (touch-resting-p tr) 0.35 0.6)))
    (let ((age (- (* 1000f0 (elapsed-time)) (touch-glyph-t tr))))
      (when (and (< age 300) (plusp (touch-glyph tr)))
        (hud-text (svref *glyph-names* (touch-glyph tr)) (touch-glyph-x tr) (- (touch-glyph-y tr) (* 60 d)) (* 2 s)
                  '(1 0.85 0.4 1) :align :center)))))

(defparameter *gesture-card*
  '(("TAP" "QUICK  (TAP TAP TAP = STRING)") ("HOLD STILL" "GUARD") ("DRAG" "MOVE  (FAR = DASH / RUN)")
    ("FLICK" "STEP  (DOWN = BACK)") ("FLICK UP + LIFT" "FLASH") ("HOLD, THEN FLICK UP" "HOHO")
    ("FLICK DOWN WHEN HIT" "BURST REVERSE") ("O" "KIKON RUSH  (HOLD = KIKON)") ("L / I" "SIGNATURE / BREAKER")
    ("SP1 / SP2" "SPECIALS") ("AWK (HOLD)" "AWAKEN") ("II / BACK" "PAUSE"))
  "The static gesture card (ONE-HAND's CONTROLS).")

(defun hud-gestures (w h s)
  (ui-rect 0 0 w h '(0 0 0 0.75))
  (ui-big-text "ONE HAND" (floor w 2) (* 0.08 h) (* 3 s) *white* '(0.7 0.25 0.05 1) s)
  (let ((sc (fit-scale "FLICK DOWN WHEN HIT" s (* 0.9 w))))
    (loop for (a b) in *gesture-card* for i from 0
          for y = (+ (* 0.18 h) (* i 22 sc)) do
            (ui-text a (floor w 2) y :scale sc :align :center :color *ember*)
            (ui-text b (floor w 2) (+ y (* 9 sc)) :scale (max 1 (fit-scale b sc (* 0.95 w))) :align :center :color *white*)))
  (ui-text "TAP TO GO BACK" (floor w 2) (* 0.94 h) :scale s :align :center :color *dim* :shadow t))
