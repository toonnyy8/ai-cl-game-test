;;;; barro-art.lisp — LILLE BARRO II's own looks (docs/duel/DUEL_LILLE_V2.md §7). His art is Lille's, shared by reference
;;;; (lille-art.lisp: the bodies, Diagramm, every :lb-* clip, LILLE-DRAW's wings / halos / legs, LB-LOOK's lines and beams);
;;;; this file holds only what is his: the draw hook BR-DRAW (Lille's, then his stance's aim line), his trace lines' floor
;;;; look (BR-TRACE-LOOK, his BRH data) and the 狙擊 gauge's HUD row. The clips Lille never had (the recall :br-recall and its
;;;; strings :br-rc1..3) come in the art batch; until then the moves play Lille's stand-ins (barro.lisp *BR-STAND-INS*).
;;;; Everything here is cosmetic: the sim never reads it. Loaded after lille-art.lisp (its macros and props) and before
;;;; barro.lisp (whose state and knobs these functions read at draw time).
(in-package :duel)

(declaim (special *br-trace-len*))                     ; (barro.lisp's, loaded after this file)

;;; ---------------------------------------------------------------- the draw hook
(defun-fast %br-aim-look (e f side)
  "The stance's aim line (Lille's %LB-AIM-LOOK on his moves): a thin line on the floor from under the muzzle to the wall,
grey while the stance (:br-kamae / :br-kamae-k) tracks, jade once the shot :br-k-shot locks until it fires; the reticle at
the opponent's distance, turning while it tracks, closing once locked."
  (declare (fixnum side))
  (setf side 0)                                         ; (unused: the slot memory is Lille's HUD tag's, not his)
  (let* ((mv (fighter-move f)) (nm (and mv (eq (fighter-state f) :move) (mv-name mv)))
         (stance (or (eq nm :br-kamae) (eq nm :br-kamae-k)))
         (locked (and (eq nm :br-k-shot) (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))))
    (when (or stance locked)
      (%lb-load-place! e)
      (let* ((v *lb-v*) (yaw (aref v 27)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
             (x0 (+ (aref v 24) (* 0.5f0 ux))) (z0 (+ (aref v 26) (* 0.5f0 uz)))
             (wall (%lb-wall x0 z0 ux uz)) (dist (the single-float (fighter-dist f)))
             (dq (f-clamp (- dist 0.5f0) 1f0 (f-max 1f0 wall)))
             (rx (+ x0 (* dq ux))) (rz (+ z0 (* dq uz)))
             (r (if locked (- 0.65f0 (* 0.018f0 (i->f (fighter-sf f)))) 1.1f0))
             (tm (fx-clock)))
        (declare (type f32vec v) (single-float yaw ux uz x0 z0 wall dist dq rx rz r tm))
        (%lb-floor-line (if locked 1 0) x0 z0 ux uz wall (if locked 0.06f0 0.035f0))
        (%lb-reticle locked rx rz r (if locked 0.785398f0 (* 1.4f0 tm)))))
    nil))

(defun-fast br-draw (e rdt)
  "His kit's :draw hook: Lille's (LILLE-DRAW: his forms carry Lille's form names, so the wings, the halos, the legs and the
cinematics' drives come out the same), then the stance's aim line (%BR-AIM-LOOK)."
  (declare (single-float rdt))
  (lille-draw e rdt)
  (let ((f (fighter e)))
    (when (eq (fighter-form f) :base) (%br-aim-look e f (fighter-side f))))
  nil)

;;; ---------------------------------------------------------------- his traces (cosmetic, 0 B a frame)
(defun-fast br-trace-look (hz rdt)
  "A live trace's look (HAZARD-DRAW): a faint jade line (the owl's gold) on the floor from 0.6 m ahead of where it was laid
to the wall, its width pulsing (SP2's thick one wider); nothing once materialised (LB-LOOK's flash takes over)."
  (declare (single-float rdt))
  (setf rdt 0f0)                                        ; (unused: HAZARD-DRAW's signature)
  (let ((d (hazard-data hz)))
    (when (and (brh-p d) (brh-live d))
      (let* ((x (hazard-x hz)) (z (hazard-z hz)) (yaw (hazard-yaw hz)) (ux (- (f-sin yaw))) (uz (- (f-cos yaw)))
             (x0 (+ x (* 0.6f0 ux))) (z0 (+ z (* 0.6f0 uz)))
             (pulse (+ 0.8f0 (* 0.2f0 (f-sin (+ (* 5f0 (fx-clock)) (* 0.7f0 (i->f (mod (brh-id d) 9))))))))
             (w (* pulse (if (eq (brh-src d) :sp2) 0.14f0 0.04f0))))
        (declare (single-float x z yaw ux uz x0 z0 pulse w))
        (%lb-floor-line (if (> (lb-fxs (if (eql (hazard-owner hz) *p1*) 0 1) 15) 0.5f0) 3 1)   ; (the owl's: gold; LILLE-DRAW's
                        x0 z0 ux uz (%lb-wall x0 z0 ux uz) w))))                                ;  flag, no lookup)
  nil)

;;; ---------------------------------------------------------------- the HUD: the 狙擊 gauge (DUEL_LILLE_V2 §4)
(defparameter *br-sn-strings* #("SN 0" "SN 1" "SN 2" "SN 3") "The 狙擊 row's label: SN + the pips.")
(defparameter *br-tr-strings* (let ((v (make-array 17))) (dotimes (i 17 v) (setf (svref v i) (format nil "TR ~d" i))))
  "The awakened forms' label: TR + the live traces.")

(defun br-hud-label (g kit)
  "The portrait block's label: SN n (the 狙擊 pips) in the base form, TR n (the live traces) awakened."
  (let* ((e (lb-side-of g)) (st (brs e)))
    (if (eq (kit-form kit) :base)
        (svref *br-sn-strings* (if st (max 0 (min 3 (brs-snipe st))) 0))
        (svref *br-tr-strings* (if st (max 0 (min 16 (brs-live st))) 0)))))

(defun br-hud-meter (e kit x y w h right tm lx ly ls)
  "His kit-meter row (LX LY LS: the landscape label's place, NIL in the portrait slot): the base form's three 狙擊 pips
(Lille's reticle glyph: a filled pip the open jade eye, an empty one the shut white), SN n; awakened, TR n (his live traces)."
  (let* ((st (brs e)) (v *lb-hud*) (n (if st (brs-snipe st) 0)))
    (setf (aref v 3) (f32 tm) (aref v 4) (f32 x) (aref v 5) (f32 y) (aref v 6) (f32 w) (aref v 7) (f32 h))
    (when (eq (kit-form kit) :base)
      (let* ((step (/ w 3.0)) (r (min (* 0.36 step) (max 7.0 (* 2.4 h)))))
        (dotimes (i 3)
          (setf (aref v 0) (f32 (if right (- (+ x w) (* step (+ i 0.5))) (+ x (* step (+ i 0.5)))))
                (aref v 1) (f32 (+ y (* 0.5 h))) (aref v 2) (f32 r))
          (%lb-pip (if (< i n) 1 0)))))
    (when lx
      (hud-text (br-hud-label (gauges e) kit) lx ly ls *c-lb-jade* :align (if right :right :left)))))
