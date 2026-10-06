;;;; touch.lisp — one-thumb gesture recogniser (docs/duel/DUEL_MOBILE_DESIGN.md §3.2, G2). Plain CL, host-tested
;;;; (tests/touch-test.lisp); platform.lisp's TOUCH-POLL feeds it the frame's finger events (engine/c/platform.c).
;;;;   (make-touch)                       a recogniser; (touch-layout! tr ...) sets its flow pad and chips
;;;;   (touch-feed! tr n)                 process N queued events (TOUCH-Q, 5 floats each), then the clock (TOUCH-NOW)
;;;;   reads: TOUCH-PULSE-P (a latched tap / high tap / flick / hoho, see TOUCH-TAKE!), TOUCH-RESTING-P (guard),
;;;;          TOUCH-STEP-HELD-P, TOUCH-SX / TOUCH-SY (the drag stick), TOUCH-CHIP-DOWN-P, TOUCH-TAPPED-P (menus)
;;;; Coordinates are window pixels; the knobs (GESTURE-CONFIG) are CSS px and ms, scaled by TOUCH-DPX.
;;;; A contact that starts in the flow pad is the gesture contact (the latest one wins); one that starts on a
;;;; chip holds that chip until it lifts; anything else only counts as a menu tap. Timing uses the events'
;;;; own timestamps, so it is frame-rate independent and deterministic under run.mjs --fixed-dt.
;;;; No consing per event or per frame (DEFUN-FAST, squared distances, no generic MIN / MAX on floats).
(in-package :engine)

(defstruct (gesture-config (:conc-name gc-))
  "The recogniser's knobs (design §3.8): px are CSS pixels, times ms."
  (tap-ms 120f0 :type single-float)       ; a lift before this, inside the slop = a tap; still this long = rest
  (slop 10f0 :type single-float)          ; px a thumb may wander and still be a tap / rest
  (flick-min 28f0 :type single-float)     ; px of travel that makes a flick ...
  (flick-window 120f0 :type single-float) ; ... within this many ms of leaving the slop
  (up-cone 1.73f0 :type single-float)     ; a flick is "up" (straight ahead) while |dx| <= this x |dy| (60 deg either side)
  (tap-split 0.5f0 :type single-float)    ; a tap above this fraction of the pad's height is a high tap (TOUCH-SPLIT-Y)
  (stick-r 48f0 :type single-float)       ; px of drag for a full stick
  (run-ring 1.6f0 :type single-float)     ; stick radii: Step held (dash, run) beyond this ...
  (run-release 1.3f0 :type single-float)  ; ... released back inside this
  (recenter 2f0 :type single-float)       ; stick radii: the origin follows the thumb past this
  (chip-slop 8f0 :type single-float)      ; px added to a chip's radius for its hit circle
  (menu-tap-ms 350f0 :type single-float)) ; menus: a lift this soon, inside the slop, is a tap

(defconstant +tp-tap+ 1) (defconstant +tp-flick+ 2) (defconstant +tp-tap-hi+ 4) (defconstant +tp-hoho+ 8)   ; tap: the low zone
(defconstant +touch-fingers+ 10)
(defconstant +touch-chips+ 8)
(defconstant +touch-events+ 64)

(defun %f32s (n) (make-array n :element-type 'single-float :initial-element 0f0))
(defun %fixs (n init) (make-array n :element-type 'fixnum :initial-element init))

(defstruct (touch (:constructor make-touch (&key (cfg (make-gesture-config)))))
  "One recogniser. PHASE of the gesture contact: 0 none, 1 pending (still inside the slop since touch-down),
2 drag, 3 rest (guard), 5 spent (a Hoho fired: ignored until it lifts), 6 undecided (left the slop, the flick
window still open). Only a drag (2) moves the stick or holds Step, so a flick never walks before it fires (the
user's playtest, 2026-09-27). (4, the up-flick waiting for its lift, went with the 2026-09-28 remap.)"
  (cfg (make-gesture-config) :type gesture-config)
  (q (%f32s (* 5 +touch-events+)) :type (simple-array single-float (*)))   ; TOUCH-POLL's copy of the frame's events
  (dpx 1f0 :type single-float)                                             ; window px per CSS px
  (pad (%f32s 4) :type (simple-array single-float (*)))                    ; flow pad x0 y0 x1 y1
  (chips (%f32s (* 3 +touch-chips+)) :type (simple-array single-float (*))); chip cx cy r
  (nchips 0 :type fixnum)
  (chip-hold (%f32s +touch-chips+) :type (simple-array single-float (*)))  ; ms a chip must be held before it is down
  (chip-slot (%fixs +touch-chips+ -1) :type (simple-array fixnum (*)))     ; finger holding chip i, -1 none
  (chip-t (%f32s +touch-chips+) :type (simple-array single-float (*)))     ; when it went down
  (chip-on 0 :type fixnum) (chip-hit 0 :type fixnum)                       ; bits: down now / touched this frame
  (now 0f0 :type single-float)              ; the clock TOUCH-FEED! runs to (ms, set by the caller)
  (rest-up-ok nil)                          ; the game: may a rested up-flick be a Hoho now (neutral / guard)?
  (up-hoho nil)                             ; the game: is any up-flick a Hoho now, no rest needed (while attacking)?
  ;; the gesture contact
  (gid -1 :type fixnum) (phase 0 :type fixnum)
  (t0 0f0 :type single-float) (x 0f0 :type single-float) (y 0f0 :type single-float)
  (ox 0f0 :type single-float) (oy 0f0 :type single-float)          ; stick origin
  (ax 0f0 :type single-float) (ay 0f0 :type single-float)          ; flick anchor (the last still point)
  (tleave -1f0 :type single-float) (armed 1 :type fixnum) (rested 0 :type fixnum)
  (px 0f0 :type single-float) (py 0f0 :type single-float) (pt 0f0 :type single-float)   ; still point, since
  (flick-hold 0 :type fixnum) (run-hold 0 :type fixnum)
  (fx 0f0 :type single-float) (fy 0f0 :type single-float)          ; last flick's stroke (px, y down)
  ;; pulses: set by the recogniser (PEND), shown to exactly one reader call (LIVE, TOUCH-TAKE!)
  (pend 0 :type fixnum) (live 0 :type fixnum)
  ;; menus: per finger start, travel, and this frame's tap
  (fx0 (%f32s +touch-fingers+) :type (simple-array single-float (*)))
  (fy0 (%f32s +touch-fingers+) :type (simple-array single-float (*)))
  (ft0 (%f32s +touch-fingers+) :type (simple-array single-float (*)))
  (fmoved (%fixs +touch-fingers+ 1) :type (simple-array fixnum (*)))   ; 1 = not a tap (moved, cancelled, unknown)
  (tapped 0 :type fixnum) (tap-x 0f0 :type single-float) (tap-y 0f0 :type single-float)
  ;; feedback: the last recognised gesture (1 tap 2 flick 3 high tap 4 hoho 5 rest 6 up-flick), when (ms) and where
  (glyph 0 :type fixnum) (glyph-t -1f4 :type single-float) (glyph-x 0f0 :type single-float) (glyph-y 0f0 :type single-float))

;;; ---------------------------------------------------------------- layout
(defun touch-layout! (tr dpx pad chips &optional holds)
  "Set TR's scale DPX (window px per CSS px), flow PAD (x0 y0 x1 y1, px) and CHIPS (a list of (cx cy r), px;
HOLDS: a list of ms each chip must be held first, default 0). Releases held chips. Not per frame (conses)."
  (setf (touch-dpx tr) (float dpx 1f0))
  (loop for v in pad for i from 0 do (setf (aref (touch-pad tr) i) (float v 1f0)))
  (setf (touch-nchips tr) (min +touch-chips+ (length chips)))
  (loop for c in chips for i below +touch-chips+
        do (loop for v in c for j from 0 do (setf (aref (touch-chips tr) (+ (* 3 i) j)) (float v 1f0)))
           (setf (aref (touch-chip-hold tr) i) (float (or (nth i holds) 0) 1f0)))
  (fill (touch-chip-slot tr) -1)
  (setf (touch-chip-on tr) 0)
  tr)

;;; ---------------------------------------------------------------- the gesture contact
(defmacro %knob (tr k) `(,(intern (format nil "GC-~a" k) :engine) (touch-cfg ,tr)))
(defmacro %px (tr k) `(* (touch-dpx ,tr) (%knob ,tr ,k)))

(defun-fast %glyph! (tr kind x y ms)
  (declare (fixnum kind) (single-float x y ms))
  (setf (touch-glyph tr) kind (touch-glyph-t tr) ms (touch-glyph-x tr) x (touch-glyph-y tr) y)
  nil)

(defun-fast %release (tr)
  "The gesture contact ends: nothing held, no stick."
  (setf (touch-gid tr) -1 (touch-phase tr) 0 (touch-flick-hold tr) 0 (touch-run-hold tr) 0)
  nil)

(defun-fast %gesture-down (tr slot x y ms)
  (declare (fixnum slot) (single-float x y ms))
  (setf (touch-gid tr) slot (touch-phase tr) 1 (touch-t0 tr) ms (touch-x tr) x (touch-y tr) y
        (touch-ox tr) x (touch-oy tr) y (touch-ax tr) x (touch-ay tr) y (touch-px tr) x (touch-py tr) y (touch-pt tr) ms
        (touch-tleave tr) -1f0 (touch-armed tr) 1 (touch-rested tr) 0 (touch-flick-hold tr) 0 (touch-run-hold tr) 0)
  nil)

(defun-fast %flick (tr dx dy ms)
  "A flick crossed FLICK-MIN with stroke (DX DY) (px, y down)."
  (declare (single-float dx dy ms))
  (setf (touch-armed tr) 0 (touch-fx tr) dx (touch-fy tr) dy)
  (let ((x (touch-x tr)) (y (touch-y tr)) (ax (if (< dx 0f0) (- dx) dx)))
    (declare (single-float x y ax))
    (cond ((and (< dy 0f0) (>= (* (- dy) (%knob tr up-cone)) ax)   ; up (within UP-CONE) from a rest, or any while the
                (or (touch-up-hoho tr) (and (= (touch-rested tr) 1) (touch-rest-up-ok tr))))   ; game says so: Hoho
           (setf (touch-pend tr) (logior (touch-pend tr) +tp-hoho+) (touch-phase tr) 5)
           (%glyph! tr 4 x y ms))
          (t (setf (touch-pend tr) (logior (touch-pend tr) +tp-flick+) (touch-flick-hold tr) 1 (touch-phase tr) 2)
             (if (and (< dy 0f0) (>= (* (- dy) (%knob tr up-cone)) ax))
                 (progn (setf (touch-fx tr) 0f0) (%glyph! tr 6 x y ms))   ; up: straight ahead (a slanted thumb too)
                 (%glyph! tr 2 x y ms)))))
  (setf (touch-rested tr) 0)
  nil)

(defun-fast %gesture-move (tr x y ms)
  (declare (single-float x y ms))
  (setf (touch-x tr) x (touch-y tr) y)
  (unless (= (touch-phase tr) 5)
    (let* ((slop (%px tr slop)) (hs (* 0.5f0 slop))
           (dx (- x (touch-px tr))) (dy (- y (touch-py tr))))
      (declare (single-float slop hs dx dy))
      (when (> (+ (* dx dx) (* dy dy)) (* hs hs))              ; moved: a new still point
        (setf (touch-px tr) x (touch-py tr) y (touch-pt tr) ms))
      ;; flick: from the anchor, FLICK-MIN within FLICK-WINDOW of leaving the slop
      (let* ((ax (- x (touch-ax tr))) (ay (- y (touch-ay tr))) (d2 (+ (* ax ax) (* ay ay))) (fm (%px tr flick-min)))
        (declare (single-float ax ay d2 fm))
        (when (and (< (touch-tleave tr) 0f0) (> d2 (* slop slop))) (setf (touch-tleave tr) ms))
        (when (and (= (touch-armed tr) 1) (>= (touch-tleave tr) 0f0))
          (cond ((> (- ms (touch-tleave tr)) (%knob tr flick-window))
                 (setf (touch-armed tr) 0 (touch-rested tr) 0)
                 (when (= (touch-phase tr) 6) (setf (touch-phase tr) 2)))   ; no flick: it was a drag
                ((>= d2 (* fm fm)) (%flick tr ax ay ms))))
        (when (and (= (touch-flick-hold tr) 1) (< d2 (* fm fm))) (setf (touch-flick-hold tr) 0)))
      ;; drag: the stick from the origin (which follows past RECENTER radii), Step held beyond the run ring
      (let* ((r (%px tr stick-r)) (sx (- x (touch-ox tr))) (sy (- y (touch-oy tr))) (m2 (+ (* sx sx) (* sy sy)))
             (rc (* r (%knob tr recenter))))
        (declare (single-float r sx sy m2 rc))
        (when (and (member (touch-phase tr) '(1 3)) (> m2 (* slop slop)))
          (setf (touch-phase tr) (if (= (touch-armed tr) 1) 6 2)))     ; a drag only once no flick can come
        (when (> m2 (* rc rc))
          (let ((k (/ rc (sqrt m2))))
            (declare (single-float k))
            (setf (touch-ox tr) (- x (* k sx)) (touch-oy tr) (- y (* k sy)) m2 (* rc rc))))
        (let ((run (* r (%knob tr run-ring))) (rel (* r (%knob tr run-release))))
          (declare (single-float run rel))
          (cond ((>= m2 (* run run)) (setf (touch-run-hold tr) 1))
                ((< m2 (* rel rel)) (setf (touch-run-hold tr) 0)))))))
  nil)

(defun-fast touch-split-y (tr)
  "The window y splitting the pad's taps: above it a high tap (+TP-TAP-HI+), from it down a tap (+TP-TAP+)."
  (let ((p (touch-pad tr)))
    (+ (aref p 1) (* (%knob tr tap-split) (- (aref p 3) (aref p 1))))))

(defun-fast %gesture-lift (tr ms)
  (declare (single-float ms))
  (when (and (= (touch-phase tr) 1) (<= (- ms (touch-t0 tr)) (%knob tr tap-ms)))   ; never left the slop, short: a tap
    (let ((hi (< (touch-oy tr) (the single-float (touch-split-y tr)))))            ; where it went down
      (setf (touch-pend tr) (logior (touch-pend tr) (if hi +tp-tap-hi+ +tp-tap+)))
      (%glyph! tr (if hi 3 1) (touch-x tr) (touch-y tr) ms)))
  (%release tr))

(defun-fast %touch-clock (tr now)
  "Time-based transitions at NOW (ms): an undecided stroke whose flick window closed is a drag; a thumb still for
TAP-MS re-anchors (re-arming the flick) and, inside the slop of the stick origin, rests (guard);
held chips that need a hold come on."
  (declare (single-float now))
  (when (>= (touch-gid tr) 0)
    (when (and (= (touch-phase tr) 6) (> (- now (touch-tleave tr)) (%knob tr flick-window)))
      (setf (touch-phase tr) 2 (touch-armed tr) 0 (touch-rested tr) 0))
    (when (and (/= (touch-phase tr) 5) (>= (- now (touch-pt tr)) (%knob tr tap-ms)))
      (let* ((sx (- (touch-x tr) (touch-ox tr))) (sy (- (touch-y tr) (touch-oy tr))) (slop (%px tr slop))
             (in (<= (+ (* sx sx) (* sy sy)) (* slop slop))))
        (declare (single-float sx sy slop))
        (setf (touch-ax tr) (touch-x tr) (touch-ay tr) (touch-y tr) (touch-tleave tr) -1f0 (touch-armed tr) 1
              (touch-flick-hold tr) 0)
        (if in
            (progn (unless (= (touch-phase tr) 3) (%glyph! tr 5 (touch-x tr) (touch-y tr) now))
                   (setf (touch-phase tr) 3 (touch-rested tr) 1 (touch-ox tr) (touch-x tr) (touch-oy tr) (touch-y tr)))
            (setf (touch-rested tr) 0 (touch-phase tr) 2)))))
  (let ((on 0))
    (declare (fixnum on))
    (dotimes (i (touch-nchips tr))
      (when (and (>= (aref (touch-chip-slot tr) i) 0)
                 (>= (- now (aref (touch-chip-t tr) i)) (aref (touch-chip-hold tr) i)))
        (setf on (logior on (ash 1 i)))))
    (setf (touch-chip-on tr) on))
  nil)

;;; ---------------------------------------------------------------- events
(defun-fast %chip-at (tr x y)
  "Index of the chip whose hit circle holds (X Y), or -1."
  (declare (single-float x y))
  (let ((c (touch-chips tr)) (s (%px tr chip-slop)))
    (declare (single-float s))
    (dotimes (i (touch-nchips tr) -1)
      (let* ((dx (- x (aref c (* 3 i)))) (dy (- y (aref c (+ 1 (* 3 i))))) (r (+ s (aref c (+ 2 (* 3 i))))))
        (declare (single-float dx dy r))
        (when (<= (+ (* dx dx) (* dy dy)) (* r r)) (return i))))))

(defun-fast %touch-event (tr type slot x y ms)
  (declare (fixnum type slot) (single-float x y ms))
  (let ((slop (%px tr slop)))
    (declare (single-float slop))
    (case type
      (0 (when (< -1 slot +touch-fingers+)                     ; down
           (setf (aref (touch-fx0 tr) slot) x (aref (touch-fy0 tr) slot) y (aref (touch-ft0 tr) slot) ms
                 (aref (touch-fmoved tr) slot) 0))
         (let ((c (%chip-at tr x y)) (p (touch-pad tr)))
           (declare (fixnum c))
           (cond ((>= c 0) (setf (aref (touch-chip-slot tr) c) slot (aref (touch-chip-t tr) c) ms
                                 (touch-chip-hit tr) (logior (touch-chip-hit tr) (ash 1 c))))
                 ((and (<= (aref p 0) x (aref p 2)) (<= (aref p 1) y (aref p 3)))
                  (%gesture-down tr slot x y ms)))))            ; the latest contact in the pad wins
      (1 (when (< -1 slot +touch-fingers+)                     ; motion
           (let ((dx (- x (aref (touch-fx0 tr) slot))) (dy (- y (aref (touch-fy0 tr) slot))))
             (declare (single-float dx dy))
             (when (> (+ (* dx dx) (* dy dy)) (* slop slop)) (setf (aref (touch-fmoved tr) slot) 1))))
         (when (= slot (touch-gid tr)) (%gesture-move tr x y ms)))
      ((2 3) (when (< -1 slot +touch-fingers+)                 ; up / canceled (a cancel is never a tap)
               (when (and (= type 2) (= 0 (aref (touch-fmoved tr) slot))
                          (<= (- ms (aref (touch-ft0 tr) slot)) (%knob tr menu-tap-ms)))
                 (setf (touch-tapped tr) 1 (touch-tap-x tr) x (touch-tap-y tr) y))
               (setf (aref (touch-fmoved tr) slot) 1))
       (dotimes (i (touch-nchips tr)) (when (= slot (aref (touch-chip-slot tr) i)) (setf (aref (touch-chip-slot tr) i) -1)))
       (when (= slot (touch-gid tr))
         (if (= type 2) (%gesture-lift tr ms) (%release tr))))
      (4 (fill (touch-fmoved tr) 1) (fill (touch-chip-slot tr) -1) (%release tr))))   ; every finger gone (focus lost)
  nil)

(defun-fast touch-feed! (tr n)
  "Process the first N events of TOUCH-Q (type slot x y ms, as engine/c/platform.c writes them; x y already in
window px), then run the clock to TOUCH-NOW (ms). Clears last frame's menu tap and chip touches first."
  (declare (fixnum n))
  (setf (touch-tapped tr) 0 (touch-chip-hit tr) 0)
  (let ((q (touch-q tr)))
    (dotimes (i n)
      (let ((o (* 5 i)))
        (declare (fixnum o))
        (%touch-event tr (the fixnum (truncate (aref q o))) (the fixnum (truncate (aref q (+ o 1))))
                      (aref q (+ o 2)) (aref q (+ o 3)) (aref q (+ o 4))))))
  (%touch-clock tr (touch-now tr))
  tr)

;;; ---------------------------------------------------------------- reads
(defun touch-take! (tr)
  "Call once at the start of each vpad read: the pending pulses become live for exactly this read (a pulse
latched while no fixed step ran stays pending until one does)."
  (setf (touch-live tr) (touch-pend tr) (touch-pend tr) 0)
  tr)
(defun touch-pulse-p (tr bit) (logtest (touch-live tr) bit))
(defun touch-spend! (tr)
  "The game took this read's flick for itself (a burst): the contact gives nothing more until it lifts, as after a Hoho
(no stick, no Step held however far the thumb travels on)."
  (setf (touch-phase tr) 5 (touch-flick-hold tr) 0 (touch-run-hold tr) 0
        (touch-live tr) (logandc2 (touch-live tr) +tp-flick+))
  tr)
(defun touch-active-p (tr) "A gesture contact is down." (>= (touch-gid tr) 0))
(defun touch-resting-p (tr) (= (touch-phase tr) 3))
(defun touch-step-held-p (tr)
  (and (= (touch-phase tr) 2) (or (= 1 (touch-flick-hold tr)) (= 1 (touch-run-hold tr)))))
(defun touch-flick-down-p (tr)
  "The last flick went down (within 45 degrees)."
  (let ((dx (touch-fx tr)) (dy (touch-fy tr))) (and (> dy 0f0) (>= dy (abs dx)))))
(defun-fast touch-sx (tr)
  "The stick, x right, -1..1 (unclamped length: VPAD-STICK! clamps); a live flick gives its direction."
  (let ((r (%px tr stick-r)))
    (declare (single-float r))
    (cond ((logtest (touch-live tr) +tp-flick+) (/ (touch-fx tr) (%px tr flick-min)))
          ((= (touch-phase tr) 2) (/ (- (touch-x tr) (touch-ox tr)) r))
          (t 0f0))))
(defun-fast touch-sy (tr)
  "The stick, y up."
  (let ((r (%px tr stick-r)))
    (declare (single-float r))
    (cond ((logtest (touch-live tr) +tp-flick+) (/ (- (touch-fy tr)) (%px tr flick-min)))
          ((= (touch-phase tr) 2) (/ (- (touch-oy tr) (touch-y tr)) r))
          (t 0f0))))
(defun touch-chip-down-p (tr i) (logbitp i (touch-chip-on tr)))
(defun touch-chip-hit-p (tr i) "Chip I was touched this frame." (logbitp i (touch-chip-hit tr)))
(defun touch-tapped-p (tr) "A tap (anywhere) ended this frame, at TOUCH-TAP-X / -Y." (= 1 (touch-tapped tr)))
