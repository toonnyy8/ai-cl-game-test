;;;; hud.lisp — the battle HUD (design-v1 §10) and every screen of the flow (title, mode, controls,
;;;; select, results, pause). Per side, P2 mirrored: Reishi bar (red + pulsing below *RED-THRESHOLD*,
;;;; white damage trail), the guard gauge under it (steel, a white drain trail, 30 % darker while he guards below full
;;;; (GUARD HOLD: no refill; Bankai West's ward always); Bankai's is ember (East's pierce reads it); guardless: grey with
;;;; a red fill climbing back), *KONPAKU-MAX* Konpaku soul flames that shatter, Reiatsu 3 bars, the flash-step bar
;;;; (ticks at a Hoho's cost and the burst threshold; the part past it glows in the mode's colour while a burst is possible,
;;;; the fill is the running burst's colour as it drains), Awakening bar (EVOLUTION
;;;; blinks; drains in a timed awakening; WARD while Bankai West's ward is up), the kit meter
;;;; (Inferno; drains in Hellfire) or, for an awakened form whose L has a cooldown, the L cooldown bar (one cell; a thin
;;;; ember line under it while a Shift+L with a cooldown cools; a refused press flashes its bar), the timer, the
;;;; combo counter under the victim's bar, move-name callouts over the user, the HOLD O KIKON prompt, the red
;;;; soul flame over a Kikon-able victim, and the big words (ANNOUNCE). Cosmetic only: the fx clock (it stops
;;;; while paused, so the HUD's pulses and fades hold too), RND01.
;;;; Screen lanes (top to bottom): side panels + timer (0 .. ~0.22 h), small words (0.3 h), big words
;;;; (0.45 h), captions (0.8 h). Callouts float over the user's head and step out of a word's box.
;;;; Consing: the battle HUD runs every frame, so its strings are cached (timer, labels, combo), its
;;;; quads are written by DEFUN-FAST helpers with WITH-UI-VERTS (0 bytes), its text is drawn with
;;;; HUD-TEXT (block text, ~200 B a call however long) and UI-BIG-TEXT, and colours are quoted lists (ELT on a literal
;;;; list conses nothing) or preallocated lists whose alpha is set in place.
(in-package :duel)

(defparameter *white* '(1 1 1 1))
(defparameter *dim* '(0.72 0.7 0.78 1))
(defparameter *dim-ink* '(0.14 0.15 0.19 1) "Select screen: the unselected entries, dark ink on the mid-grey plaza (*DIM* vanished there).")
(defparameter *ember* '(1 0.55 0.2 1))
(defparameter *shade* '(0 0 0 0.75) "HUD-TEXT's drop shadow.")

(defmacro hud-dt () "This frame's HUD seconds: 0 while the effects are frozen (paused: nothing moves under the pause menu)." `(if (fx-frozen-p) 0.0 (frame-dt)))

(defun hud-pulse (hz)
  "0..1, HZ times a second (real time)."
  (+ 0.5 (* 0.5 (sin (* 6.2831855 (f32 hz) (the single-float (fx-clock)))))))

(defun alpha! (color a)
  "COLOR (a preallocated, mutable 4-list) with its alpha set to A: a pulsing colour without a
fresh list every frame."
  (setf (fourth color) a)
  color)

(defun hud-text (str x y scale color &key (align :left) (shadow *shade*))
  "UI-TEXT's look (the 5x7 font at integer SCALE, top edge Y, ALIGN relative to X) drawn as block
text on whole pixels: ~200 B a call whatever the length. SHADOW: colour or NIL. (The engine's
UI-TEXT no longer conses per glyph either; the HUD keeps its block look.)"
  (let* ((s (max 1 (round scale)))
         (x0 (round (ecase align (:left x) (:center (- x (/ (text-width str s) 2))) (:right (- x (text-width str s))))))
         (y0 (round y)))
    (when shadow (ui-block-text str (+ x0 s) (+ y0 s) s :color shadow))
    (ui-block-text str x0 y0 s :color color)))

;;; ---------------------------------------------------------------- zero-cons quads
;;; Macros over WITH-UI-VERTS for DEFUN-FAST code: every argument a single-float form.
(defmacro %hq (x0 y0 x1 y1 x2 y2 x3 y3 r g b a &optional r1 g1 b1 a1)
  "One quad TL TR BR BL; colour (R G B A) on the top edge, (R1 G1 B1 A1) (default the same) on the bottom."
  (let ((vs (loop repeat 16 collect (gensym "Q"))))
    (destructuring-bind (px0 py0 px1 py1 px2 py2 px3 py3 cr cg cb ca dr dg db da) vs
      `(let* (,@(mapcar #'list (subseq vs 0 12) (list x0 y0 x1 y1 x2 y2 x3 y3 r g b a))
              (,dr ,(or r1 cr)) (,dg ,(or g1 cg)) (,db ,(or b1 cb)) (,da ,(or a1 ca)))
         (declare (single-float ,@vs))
         (with-ui-verts (d o 6)
           (uvtx ,px0 ,py0 ,cr ,cg ,cb ,ca) (uvtx ,px1 ,py1 ,cr ,cg ,cb ,ca) (uvtx ,px2 ,py2 ,dr ,dg ,db ,da)
           (uvtx ,px0 ,py0 ,cr ,cg ,cb ,ca) (uvtx ,px2 ,py2 ,dr ,dg ,db ,da) (uvtx ,px3 ,py3 ,dr ,dg ,db ,da))))))

(defmacro %hrect (x y w h r g b a &optional r1 g1 b1 a1)
  "Axis-aligned rect, top colour (R G B A), bottom colour (R1 G1 B1 A1)."
  (let ((x0 (gensym)) (y0 (gensym)) (x1 (gensym)) (y1 (gensym)))
    `(let* ((,x0 ,x) (,y0 ,y) (,x1 (+ ,x0 ,w)) (,y1 (+ ,y0 ,h)))
       (declare (single-float ,x0 ,y0 ,x1 ,y1))
       (%hq ,x0 ,y0 ,x1 ,y0 ,x1 ,y1 ,x0 ,y1 ,r ,g ,b ,a ,r1 ,g1 ,b1 ,a1))))

(defmacro %hbar (x y w h frac right r g b a &optional r1 g1 b1 a1)
  "Fill FRAC (clamped 0..1) of the W x H box at (X Y), from the left, or from the right when RIGHT."
  (let ((fw (gensym)) (bx (gensym)) (ww (gensym)))
    `(let* ((,ww ,w) (,fw (* ,ww (f-clamp ,frac 0f0 1f0))) (,bx (if ,right (+ ,x (- ,ww ,fw)) ,x)))
       (declare (single-float ,ww ,fw ,bx))
       (when (> ,fw 0f0) (%hrect ,bx ,y ,fw ,h ,r ,g ,b ,a ,r1 ,g1 ,b1 ,a1)))))

(defmacro %houtline (x y w h r g b a)
  "1 px outline of the W x H box at (X Y)."
  (let ((x0 (gensym)) (y0 (gensym)) (ww (gensym)) (hh (gensym)))
    `(let* ((,x0 ,x) (,y0 ,y) (,ww ,w) (,hh ,h))
       (declare (single-float ,x0 ,y0 ,ww ,hh))
       (%hrect ,x0 ,y0 ,ww 1f0 ,r ,g ,b ,a) (%hrect ,x0 (+ ,y0 ,hh -1f0) ,ww 1f0 ,r ,g ,b ,a)
       (%hrect ,x0 (+ ,y0 1f0) 1f0 (- ,hh 2f0) ,r ,g ,b ,a) (%hrect (+ ,x0 ,ww -1f0) (+ ,y0 1f0) 1f0 (- ,hh 2f0) ,r ,g ,b ,a))))

(defmacro %pulse (tm hz)
  "0..1, HZ times a second at time TM (single-float)."
  `(+ 0.5f0 (* 0.5f0 (f-sin (* ,(* 2 (float pi 1f0) hz) ,tm)))))

;;; ---------------------------------------------------------------- big words
(defstruct (word (:constructor make-word (text sub color secs small side)))
  text sub color secs small side (t0 (fx-clock))
  (col (list 1.0 1.0 1.0 1.0)))                                   ; its colour (r g b 1)
(defvar *words* nil "Big words on screen, newest first.")
(defun clear-words () (setf *words* nil))

(defun announce (text &key sub (color *white*) (secs 1.0) small side)
  "Show TEXT big in the middle (SMALL: smaller, upper lane; SIDE 0 / 1: over that side's panel),
with SUB under it."
  (let ((wd (make-word text sub color secs small side)))
    (setf (first (word-col wd)) (f32 (first color)) (second (word-col wd)) (f32 (second color))
          (third (word-col wd)) (f32 (third color)))
    (setf *words* (cons wd (remove-if (lambda (w) (and (not (word-side w)) (eq (word-small w) small))) *words*)))))

(defun word-layout (x w h)
  "Word X on a W x H screen. Values: centre x, the caps' middle y, the brush em in px (the pop-in shrinks it over
the first 0.08 s; a long word shrinks to 92 % of the width). A word whose box would overlap a HUD side panel
(*PANEL-BOX*) is moved down under it (Phase 5: e.g. NOMIHOSE! over the P2 labels)."
  (let* ((k (min 1.0 (/ (- (fx-clock) (word-t0 x)) 0.08)))
         (em (* h (cond ((word-side x) 0.05) ((word-small x) 0.085) (t (* 0.13 (+ 1.0 (* 0.5 (- 1 k))))))))
         (em (min em (/ (* 0.92 w) (max 0.1 (line-width (word-text x))))))
         (cx (case (word-side x) (0 (* 0.2 w)) (1 (* 0.8 w)) (t (* 0.5 w))))
         (cy (if (portrait-p)                                   ; portrait: in the arena band (§4.2 lanes)
                 (* h (if (or (word-side x) (word-small x)) (+ (aref *band* 0) 0.05) (* 0.5 (+ (aref *band* 0) (aref *band* 1)))))
                 (if (or (word-side x) (word-small x)) (* 0.3 h) (* 0.45 h))))
         (hw (* 0.5 em (line-width (word-text x)))) (pb *panel-box*))
    (dotimes (i 2)
      (let ((o (* 4 i)))
        (when (and (< (- cx hw) (aref pb (+ o 2))) (< (aref pb o) (+ cx hw)) (< (- cy (* 0.45 em)) (aref pb (+ o 3)))
                   (= (aref pb (+ o 1)) 0f0))                   ; (a panel at the bottom, portrait P1's, is under the lanes)
          (setf cy (+ (aref pb (+ o 3)) (* 0.012 h) (* 0.45 em))))))
    (values cx cy em)))

(defun word-box (x w h)
  "Screen box of word X (text + sub). Values: x0 y0 x1 y1."
  (multiple-value-bind (cx cy em) (word-layout x w h)
    (let ((hw (* 0.5 em (line-width (word-text x)))))
      (values (- cx hw) (- cy (* 0.45 em)) (+ cx hw) (+ cy (if (word-sub x) (* 1.05 em) (* 0.45 em)))))))

(defvar *hud-warned* nil "Strings already logged as drawn over a HUD panel (HUD-OVER-PANEL).")
(defun hud-over-panel (what str x0 y0 x1 y1 w h)
  "Log once per string that the WHAT (callout / word) STR at (X0 Y0 X1 Y1) overlaps a HUD panel (tests/style-5-checks.py
greps \"over the P\")."
  (let ((side (panel-hit (f32 x0) (f32 y0) (f32 x1) (f32 y1))))
    (when (and side (not (member str *hud-warned* :test #'equal)))
      (push str *hud-warned*)
      (log-msg "hud: ~a ~a over the P~d panel on the ~dx~d screen: ~d ~d ~d ~d" what str (1+ side) w h
               (round x0) (round y0) (round x1) (round y1)))))

(defun draw-words (w h)
  "The big words (ANNOUNCE) in brush Latin, fading out over their last 0.25 s."
  (setf *words* (delete-if (lambda (x) (> (- (fx-clock) (word-t0 x)) (word-secs x))) *words*))
  (dolist (x *words*)
    (multiple-value-bind (x0 y0 x1 y1) (word-box x w h) (hud-over-panel "word" (word-text x) x0 y0 x1 y1 w h))
    (let* ((age (- (fx-clock) (word-t0 x)))
           (fade (min 1.0 (/ (- (word-secs x) age) 0.25))) (col (word-col x)))
      (multiple-value-bind (cx cy em) (word-layout x w h)
        (set-line cx cy em col fade) (setf (aref *bl* 7) (line-width (word-text x))) (brush-line (word-text x))
        (when (word-sub x)
          (let ((se (max (* 0.032 h) (* 0.36 em))))
            (set-line cx (+ cy (* 0.55 em) (* 0.5 se)) se col fade) (setf (aref *bl* 7) (line-width (word-sub x)))
            (brush-line (word-sub x))))))))

;;; ---------------------------------------------------------------- side panels: the meters
(declaim (type f32vec *trail-v* *pip-t* *hud-v*))
(defvar *trail-v* (make-f32 4) "Damage trail per side (fraction): [side] Reishi, [2 + side] the guard gauge.")
(defvar *pip-t* (make-f32 (* 2 *konpaku-max*)) "Per side x pip: ELAPSED-TIME it shattered (0 = intact).")
(defvar *hud-v* (make-f32 3))

(defun pips-shatter (v lost)
  "LOST more of V's Konpaku pips break (HUD shards + glass burst in the world)."
  (let* ((side (fighter-side (fighter v))) (left (gauges-konpaku (gauges v))))
    (loop for i from left below (min *konpaku-max* (+ left lost))
          do (setf (aref *pip-t* (+ (* side *konpaku-max*) i)) (f32 (fx-clock))))
    (multiple-value-bind (x y z) (actor-point v 1.6) (vfx-konpaku-shatter x y z lost))
    (play-sfx :konpaku-shatter)))

(defun-fast %hud-reishi (x y bw bh frac trail right red tm)
  "The Reishi bar: dark back, white damage TRAIL, the fill (amber, lit from the top; red and
pulsing when RED), a thin outline (red and pulsing when RED)."
  (declare (single-float x y bw bh frac trail tm))
  (let* ((p (%pulse tm 3.0)))
    (declare (single-float p))
    (%hrect x y bw bh 0.05f0 0.04f0 0.07f0 0.75f0)
    (%hbar x y bw bh trail right 0.95f0 0.9f0 0.85f0 0.9f0)
    (if red
        (%hbar x y bw bh frac right 1f0 0.35f0 0.35f0 (+ 0.65f0 (* 0.35f0 p)) 0.8f0 0.05f0 0.1f0 (+ 0.65f0 (* 0.35f0 p)))
        (%hbar x y bw bh frac right 1f0 0.78f0 0.36f0 1f0 0.88f0 0.45f0 0.12f0 1f0))
    (if red
        (%houtline (- x 1f0) (- y 1f0) (+ bw 2f0) (+ bh 2f0) 1f0 0.2f0 0.2f0 p)
        (%houtline (- x 1f0) (- y 1f0) (+ bw 2f0) (+ bh 2f0) 1f0 1f0 1f0 0.4f0))))

(defun-fast %hud-guard (x y bw bh frac trail right guardless mode tm)
  "The guard gauge: dark back, white drain TRAIL, the fill by MODE bits: 1 30 % darker (he guards below full: GUARD
HOLD, no refill; Bankai West's ward), 2 ember (Bankai: East's pierce reads it), else steel; GUARDLESS: a grey bar whose
red fill climbs back (pulsing) until it is full and he can guard again. Bit 4: LOCK, a pulsing blue rim (the guard lock
holds him past his blockstun: only BLUE breaks it)."
  (declare (single-float x y bw bh frac trail tm) (fixnum mode))
  (let* ((p (%pulse tm 3.0)) (k (if (logtest mode 1) 0.7f0 1f0)) (em (logtest mode 2))
         (r0 (* k (if em 1f0 0.84f0))) (g0 (* k (if em 0.62f0 0.88f0))) (b0 (* k (if em 0.25f0 0.94f0)))
         (r1 (* k (if em 0.78f0 0.48f0))) (g1 (* k (if em 0.24f0 0.55f0))) (b1 (* k (if em 0.06f0 0.66f0))))
    (declare (single-float p k r0 g0 b0 r1 g1 b1))
    (%hrect x y bw bh 0.05f0 0.04f0 0.07f0 0.75f0)
    (if guardless
        (progn (%hrect x y bw bh 0.32f0 0.32f0 0.35f0 0.9f0)
               (%hbar x y bw bh frac right 0.9f0 0.12f0 0.15f0 (+ 0.6f0 (* 0.4f0 p)) 0.6f0 0.02f0 0.05f0 (+ 0.6f0 (* 0.4f0 p))))
        (progn (%hbar x y bw bh trail right 1f0 1f0 1f0 0.95f0)
               (%hbar x y bw bh frac right r0 g0 b0 1f0 r1 g1 b1 1f0)))
    (when (logtest mode 4) (%houtline (- x 1f0) (- y 1f0) (+ bw 2f0) (+ bh 2f0) 0.35f0 0.6f0 1f0 (+ 0.5f0 (* 0.4f0 p))))))

(defun-fast %hud-flash (x y w h fill right burst running tm)
  "The flash-step bar: dark back, a steel-blue FILL (0..1), white ticks at a Hoho's and a burst's threshold; while a
burst RUNNING (its mode) drains it, the fill is that burst's colour (BURST-COLOR) with a pulsing bright edge; while one is
possible (BURST: the mode a press would start) the part past the burst tick glows in that mode's colour."
  (declare (single-float x y w h fill tm))
  (let* ((hk (/ (the single-float (f32 *fs-hoho*)) (the single-float (f32 *fs-max*))))
         (bk (/ (the single-float (f32 *fs-burst*)) (the single-float (f32 *fs-max*))))
         (p (%pulse tm 4.0)))
    (declare (single-float hk bk p))
    (%hrect x y w h 0.05f0 0.04f0 0.07f0 0.75f0)
    (if running
        (let* ((c (burst-color running)) (r (f32 (first c))) (g (f32 (second c))) (b (f32 (third c))))
          (declare (single-float r g b))
          (%hbar x y w h fill right r g b 1f0 (* 0.7f0 r) (* 0.7f0 g) (* 0.7f0 b) 1f0)
          (%hrect (if right (+ x (* w (- 1f0 fill))) (+ x (* w fill) -2f0)) (- y 1f0) 2f0 (+ h 2f0) 1f0 1f0 1f0 (+ 0.4f0 (* 0.6f0 p))))
        (%hbar x y w h fill right 0.55f0 0.75f0 1f0 1f0 0.25f0 0.45f0 0.8f0 1f0))
    (when (and burst (> fill bk))
      (let* ((sw (* w (- fill bk))) (sx (if right (+ x (* w (- 1f0 fill))) (+ x (* w bk))))   ; (right: fills from the right edge)
             (c (burst-color burst)))
        (declare (single-float sw sx))
        (%hrect sx (- y 1f0) sw (+ h 2f0) (f32 (first c)) (f32 (second c)) (f32 (third c)) (+ 0.5f0 (* 0.5f0 p)))))
    (%hrect (if right (+ x (* w (- 1f0 hk))) (+ x (* w hk))) (- y 2f0) 1f0 (+ h 4f0) 1f0 1f0 1f0 0.9f0)
    (%hrect (if right (+ x (* w (- 1f0 bk))) (+ x (* w bk))) (- y 2f0) 1f0 (+ h 4f0) 1f0 1f0 1f0 0.9f0)))

(defun-fast %hud-nome (x y w h fill right rung floor tm)
  "Nozarashi's NOME bar: dark back, the REIATSU yellow FILL (pulsing while within 10 of the current cup's FLOOR,
where it would drop a cup), bright marks at a cup's entry (40, 100), dim floor ticks (25, 50), and three cup pips
inside the frame, RUNG + 1 of them lit."
  (declare (single-float x y w h fill floor tm) (fixnum rung))
  (let* ((near (and (> floor 0f0) (< fill (+ floor 0.1f0))))
         (a (if near (+ 0.55f0 (* 0.45f0 (%pulse tm 5.0))) 1f0)))
    (declare (single-float a))
    (%hrect x y w h 0.05f0 0.04f0 0.07f0 0.75f0)
    (%hbar x y w h fill right 1f0 0.88f0 0.3f0 a 0.9f0 0.62f0 0.1f0 a)
    (macrolet ((tick (v r g b al) `(let ((k (/ (the single-float (f32 ,v)) (the single-float (f32 *nome-max*)))))
                                     (declare (single-float k))
                                     (%hrect (if right (+ x (* w (- 1f0 k))) (+ x (* w k))) (- y 2f0) 1f0 (+ h 4f0) ,r ,g ,b ,al))))
      (tick *nome-up-t2* 1f0 1f0 0.9f0 0.95f0)
      (tick *nome-down-t2* 0.6f0 0.6f0 0.55f0 0.6f0)
      (tick *nome-down-t3* 0.6f0 0.6f0 0.55f0 0.6f0))
    (dotimes (i 3)                                        ; the cups, from the bar's inner end
      (let* ((ps (f-max 2f0 (* 0.6f0 h))) (px (+ x (* 1.5f0 ps (i->f i)) 1f0)) (px (if right (- (+ x w) (- px x) ps) px)))
        (declare (single-float ps px))
        (if (<= i rung)
            (%hrect px (+ y (* 0.2f0 h)) ps ps 1f0 1f0 0.95f0 1f0)
            (%hrect px (+ y (* 0.2f0 h)) ps ps 0.3f0 0.3f0 0.28f0 0.8f0))))
    nil))

(defun-fast %hud-arm (x y w h pips idle right tm)
  "Kenpachi's Bankai arm meter UDE (docs/DUEL_KEN_BANKAI.md §7) in the W x H slot at (X Y): four BLOOD claw-slash pips from
the slot's inner end (RIGHT: mirrored), PIPS of them intact; a spent pip INK with a white crack line; under the next
pip to crack a thin line draining over the *ARM-CRACK* clock (IDLE frames of it gone), the pip flickering in its last
60 f."
  (declare (single-float x y w h tm) (fixnum pips idle))
  (let* ((pw (/ w 4.6f0)) (gap (* 0.2f0 pw)) (hh (* 2.4f0 h)) (y0 (- y (* 0.7f0 h))) (sl (* 0.35f0 pw))
         (left (- (the fixnum *arm-crack*) idle)) (fl (if (< left 60) (+ 0.35f0 (* 0.65f0 (%pulse tm 8.0))) 1f0)))
    (declare (single-float pw gap hh y0 sl fl) (fixnum left))
    (dotimes (i 4)
      (let* ((k (i->f i)) (px (if right (- (+ x w) (* (+ k 1f0) (+ pw gap))) (+ x (* k (+ pw gap)))))
             (lit (< i pips)) (nx (= i (1- pips))) (a (if nx fl 1f0)))
        (declare (single-float k px a))
        (if lit
            (%hq (+ px sl) y0 (+ px pw) y0 (- (+ px pw) sl) (+ y0 hh) px (+ y0 hh) 0.82f0 0.06f0 0.11f0 a 0.55f0 0.03f0 0.06f0 a)
            (progn (%hq (+ px sl) y0 (+ px pw) y0 (- (+ px pw) sl) (+ y0 hh) px (+ y0 hh) 0.05f0 0.05f0 0.07f0 0.85f0)
                   (%hq (+ px (* 0.55f0 pw)) (+ y0 (* 0.15f0 hh)) (+ px (* 0.62f0 pw)) (+ y0 (* 0.15f0 hh))
                        (+ px (* 0.4f0 pw)) (+ y0 (* 0.85f0 hh)) (+ px (* 0.33f0 pw)) (+ y0 (* 0.85f0 hh)) 0.9f0 0.9f0 0.92f0 0.8f0)))
        (when nx                                          ; the crack clock under the next pip
          (%hrect px (+ y0 hh 2f0) (* pw (f-clamp (/ (i->f left) (i->f *arm-crack*)) 0f0 1f0)) (f-max 1f0 (* 0.3f0 h))
                  0.95f0 0.9f0 0.85f0 0.9f0))))
    nil))

(defun-fast %hud-temp (x y w h c band cost lock crack refused right tm)
  "Rukia's cold gauge (docs/DUEL_RUKIA.md §8) in the W x H slot at (X Y): two stacked bars overlaid in one strip (the user's
decision 2026-09-28), bar 1 (cold C 0..100) steel-ice, bar 2 (100..200) white over it. BAND 0 / 1 / 2 (-18 / -50 /
zero): as many ice pips lit at the strip's inner end; at zero bar 2 pulses, flickering in its last tenth. COST: L's
cold, the part of the top bar it would spend dimmed (a hollow notch at the cost when C is short of it; REFUSED 0..1
flashes it). LOCK: the THAW lock after a CRACK (grey). CRACK 0..1: a BLOOD hairline across it. White on ink: ice is mono."
  (declare (single-float x y w h c cost crack refused tm) (fixnum band) (boolean lock))
  (let* ((bar (the single-float (f32 *cold-bar*)))
         (f1 (f-clamp (/ c bar) 0f0 1f0)) (f2 (f-clamp (/ (- c bar) bar) 0f0 1f0))
         (a2 (cond ((and (= band 2) (< f2 0.1f0)) (+ 0.35f0 (* 0.65f0 (%pulse tm 8.0))))
                   ((= band 2) (+ 0.75f0 (* 0.25f0 (%pulse tm 3.0))))
                   (t 1f0))))
    (declare (single-float bar f1 f2 a2))
    (%hrect x y w h 0.05f0 0.04f0 0.07f0 0.75f0)
    (if lock
        (%hbar x y w h f1 right 0.5f0 0.51f0 0.55f0 0.9f0 0.38f0 0.39f0 0.43f0 0.9f0)
        (progn (%hbar x y w h f1 right 0.55f0 0.66f0 0.8f0 1f0 0.34f0 0.43f0 0.56f0 1f0)
               (when (> f2 0f0) (%hbar x y w h f2 right 0.97f0 0.98f0 1f0 a2 0.8f0 0.86f0 0.95f0 a2))))
    (when (and (> cost 0f0) (not lock))                   ; L's cost on the top bar
      (let* ((top (if (> c bar) f2 f1)) (base (if (> c bar) bar 0f0))
             (lo (f-clamp (/ (- c cost base) bar) 0f0 1f0)) (k (f-max 0.45f0 refused)))
        (declare (single-float top base lo k))
        (if (>= c cost)
            (let ((sx (if right (+ x (* w (- 1f0 top))) (+ x (* w lo)))))
              (declare (single-float sx))
              (%hrect sx y (* w (- top lo)) h 0.05f0 0.04f0 0.07f0 (* 0.55f0 k)))
            (let ((cx (if right (+ x (* w (- 1f0 (/ cost bar)))) (+ x (* w (/ cost bar))))))
              (declare (single-float cx))
              (%hrect cx (- y 2f0) 1f0 (+ h 4f0) 1f0 1f0 1f0 (f-max 0.35f0 refused))))))
    (dotimes (i 3)                                        ; the band: -18 | -50 | -273
      (let* ((ps (f-max 2f0 (* 0.6f0 h))) (px (+ x (* 1.5f0 ps (i->f i)) 1f0)) (px (if right (- (+ x w) (- px x) ps) px)))
        (declare (single-float ps px))
        (%hrect (- px 1f0) (- (+ y (* 0.2f0 h)) 1f0) (+ ps 2f0) (+ ps 2f0) 0.05f0 0.05f0 0.08f0 1f0)   ; an ink box
        (if (<= i band)                                   ; lit: ice white; unlit: dark
            (%hrect px (+ y (* 0.2f0 h)) ps ps 0.85f0 0.93f0 1f0 1f0)
            (%hrect px (+ y (* 0.2f0 h)) ps ps 0.22f0 0.24f0 0.3f0 1f0))))
    (when (> crack 0f0)                                   ; the hand cracked: a BLOOD hairline across the strip
      (%hrect x (+ y (* 0.4f0 h)) w (f-max 1f0 (* 0.25f0 h)) 0.82f0 0.06f0 0.11f0 crack))
    nil))

(declaim (type f32vec *refused-t*))
(defvar *refused-t* (make-f32 2) "Per side: FX-CLOCK of the last refused L press (its bar, or the cold gauge's cost, flashes).")

(defun hud-temp (e kit x y w h right tm)
  "Draw E's cold gauge (KIT has a :temp meter) at (X Y), W x H: HUD-TEMP's numbers from the gauges and the form."
  (let* ((g (gauges e)) (side (fighter-side (fighter e))))
    (%hud-temp (f32 x) (f32 y) (f32 w) (f32 h) (gauges-meter g) (case (kit-form kit) (:m50 1) (:zero 2) (t 0))
               (f32 (cold-cost kit :sig)) (plusp (gauges-meter-idle g))
               (f32 (max 0.0 (- 1.0 (* 2.5 (- tm (aref *crack-t* side))))))
               (f32 (max 0.0 (- 1.0 (* 4.0 (- tm (aref *refused-t* side))))))
               right tm)))

(defparameter *temp-kanji* "凍")
(defparameter *c-ice* (list 0.9 0.94 1.0 1.0))
(defun temp-label (g kit) "The cold gauge's label: the band, or THAW in the lock after a CRACK."
  (if (plusp (gauges-meter-idle g)) "THAW" (kit-form-name kit)))

(defun hud-temp-label (x y s right name)
  "The cold gauge's label: the brush glyph 凍 and the band (-18C, -50C, -273C, or THAW in the lock), from X toward the
panel's outside."
  (let* ((em (* 8 s)))
    (set-line (if right (- x (* 0.5 em)) (+ x (* 0.5 em))) (+ y (* 3.5 s)) em *c-ice*)
    (setf (aref *bl* 7) (line-width *temp-kanji*))
    (brush-line *temp-kanji*)
    (hud-text name (if right (- x em (* 2 s)) (+ x em (* 2 s))) y s *c-ice* :align (if right :right :left))))

(defmacro %soul-flame (cx cy r lean r0 g0 b0 a0 r1 g1 b1 a1)
  "A soul-flame glyph centred at (CX CY), radius R: a rounded base and a pointed tip leaning LEAN px;
colour 0 at the tip, colour 1 at the base, plus a pale core."
  `(let* ((fx ,cx) (fy ,cy) (fr ,r) (fl ,lean) (tx (+ fx fl)) (ty (- fy (* 2.1f0 fr))))
     (declare (single-float fx fy fr fl tx ty))
     (%hq tx ty tx ty (+ fx fr) fy (- fx fr) fy ,r0 ,g0 ,b0 ,a0 ,r1 ,g1 ,b1 ,a1)            ; tip
     (%hq (- fx (* 0.9f0 fr) (* 0.4f0 fl)) (- fy (* 1.25f0 fr)) (- fx (* 0.9f0 fr) (* 0.4f0 fl)) (- fy (* 1.25f0 fr))
          fx fy (- fx fr) (+ fy (* 0.2f0 fr)) ,r0 ,g0 ,b0 ,a0 ,r1 ,g1 ,b1 ,a1)                ; side lick
     (%hq (- fx fr) fy (+ fx fr) fy (+ fx (* 0.55f0 fr)) (+ fy (* 0.85f0 fr)) (- fx (* 0.55f0 fr)) (+ fy (* 0.85f0 fr))
          ,r1 ,g1 ,b1 ,a1)                                                                   ; round base
     (%hq (+ fx (* 0.5f0 fl)) (- fy (* 0.9f0 fr)) (+ fx (* 0.5f0 fl)) (- fy (* 0.9f0 fr))
          (+ fx (* 0.4f0 fr)) (+ fy (* 0.3f0 fr)) (- fx (* 0.4f0 fr)) (+ fy (* 0.3f0 fr))
          1f0 1f0 1f0 (* 0.2f0 ,a1) 1f0 1f0 1f0 (* 0.75f0 ,a1))))                           ; core

(defun-fast %hud-pips (x py bw r side n right red tm pitch stake)
  "The Konpaku: N intact soul flames, blue but the last STAKE of them in blood red (what the opponent's Kikon would take
now: KONPAKU-AT-STAKE; they pulse while RED, i.e. while that Kikon is live), shattering ones (0.6 s of shards after
PIPS-SHATTER), and dim embers for the lost ones; PITCH radii apart (the landscape panel: 3.2)."
  (declare (single-float x py bw r tm pitch) (fixnum side n stake))
  (let* ((pt *pip-t*) (p (%pulse tm 2.0)))
    (declare (type f32vec pt) (single-float p))
    (dotimes (i *konpaku-max*)
      (let* ((fi (i->f i)) (d (* (+ fi 0.5f0) pitch r)) (cx (if right (- (+ x bw) d) (+ x d)))
             (j (+ (* side *konpaku-max*) i)) (t0 (aref pt j)) (u (/ (- tm t0) 0.6f0))
             (lean (* 0.3f0 r (f-sin (+ (* 7f0 tm) (* 1.7f0 fi))))))
        (declare (single-float fi d cx t0 u lean) (fixnum j))
        (cond ((< i n)
               (setf (aref pt j) 0f0)
               (if (>= i (- n stake))                            ; at stake: *C-BLOOD* at the base
                   (let ((a (if red (+ 0.7f0 (* 0.3f0 p)) 1f0)))
                     (declare (single-float a))
                     (%soul-flame cx py r lean 1f0 0.45f0 0.4f0 (* 0.6f0 a) 0.82f0 0.06f0 0.11f0 a))
                   (%soul-flame cx py r lean 0.75f0 0.95f0 1f0 0.45f0 0.35f0 0.7f0 1f0 1f0)))
              ((and (> t0 0f0) (< u 1f0))                      ; shattering: 4 shards fly apart
               (dotimes (k 4)
                 (let* ((a (* (i->f k) 1.5707964f0)) (sx (+ cx (* 14f0 (/ r 4.5f0) u (f-cos a))))
                        (sy (+ py (* 14f0 (/ r 4.5f0) u (f-sin a)))) (sr (* r 0.4f0 (- 1f0 u))))
                   (declare (single-float a sx sy sr))
                   (%hq sx (- sy (* 1.6f0 sr)) (+ sx sr) sy sx (+ sy sr) (- sx sr) sy
                        0.8f0 0.95f0 1f0 (- 1f0 u)))))
              (t (%soul-flame cx py (* 0.5f0 r) 0f0 0.3f0 0.3f0 0.35f0 0.3f0 0.3f0 0.3f0 0.35f0 0.6f0)))))))

(defun at-stake (e)
  "E's Konpaku flames the opponent's Kikon would take if it landed now: its current worth (combat.lisp KIKON-WORTH:
the running rush's, a kit's :kikon-worth hook, else its :kikon-konpaku), capped (control.lisp KONPAKU-AT-STAKE)."
  (let ((o (fighter-opp (fighter e))))
    (if (and o (entity-alive-p o)) (konpaku-at-stake (gauges-konpaku (gauges e)) (kikon-worth o)) 0)))

(defun-fast %hud-reiatsu (x y sw sh gap ra right)
  "Reiatsu: 3 bars of *REIATSU-BAR* each (full ones bright), from the panel's outer edge."
  (declare (single-float x y sw sh gap ra))
  (let* ((bar (the single-float (f32 *reiatsu-bar*))))
    (declare (single-float bar))
    (dotimes (i 3)
      (let* ((fi (i->f i)) (bx (if right (- x (* (+ fi 1f0) sw) (* fi gap)) (+ x (* fi (+ sw gap)))))
             (fill (f-clamp (/ (- ra (* fi bar)) bar) 0f0 1f0)))
        (declare (single-float fi bx fill))
        (%hrect bx y sw sh 0.05f0 0.04f0 0.07f0 0.75f0)
        (if (>= fill 1f0)
            (%hbar bx y sw sh fill right 0.6f0 0.92f0 1f0 1f0 0.25f0 0.65f0 1f0 1f0)
            (%hbar bx y sw sh fill right 0.2f0 0.45f0 0.7f0 1f0))))))


(defun hud-refused (e cmd)
  "E pressed CMD while it was cooling or short of cold (the :refused event): L's bar flashes."
  (when (eq cmd :sig) (setf (aref *refused-t* (fighter-side (fighter e))) (f32 (fx-clock)))))

(defun-fast %hud-cd (x y w h fill flash right r g b)
  "One cooldown bar: dark back, the FILL (1 = ready) bright in (R G B) when ready, dim while cooling; FLASH (0..1)
washes it white (a refused press)."
  (declare (single-float x y w h fill flash r g b))
  (let* ((k (if (>= fill 1f0) 1f0 0.45f0)))
    (declare (single-float k))
    (%hrect x y w h 0.05f0 0.04f0 0.07f0 0.75f0)
    (%hbar x y w h fill right (* k r) (* k g) (* k b) 1f0)
    (when (> flash 0f0) (%hrect x (- y 1f0) w (+ h 2f0) 1f0 1f0 1f0 flash))))

(defun hud-cooldowns (f kit x y w h right tm)
  "An awakened form's L cooldown, W x H at (X Y): ONE bar (steel; L has one use per cooldown, so one cell: playtest 1,
2026-09-28). A refused press flashes it."
  (%hud-cd (f32 x) (f32 y) (f32 w) (f32 h)
           (f32 (max 0.0 (- 1.0 (/ (aref (fighter-cd f) (position :sig *kit-commands*))
                                   (float (mv-cooldown (kit-command-move kit :sig)))))))
           (f32 (max 0.0 (- 1.0 (* 4.0 (- tm (aref *refused-t* (fighter-side f))))))) right 0.84f0 0.88f0 0.94f0))

(defun-fast %hud-thin (x y w h fill right r g b a0 hz tm)
  "A thin gauge (Awakening, the kit meter): dark back, FILL in (R G B), alpha A0, pulsing up to 1
at HZ when HZ > 0."
  (declare (single-float x y w h fill r g b a0 hz tm))
  (let* ((a (if (> hz 0f0) (+ a0 (* (- 1f0 a0) (+ 0.5f0 (* 0.5f0 (f-sin (* 6.2831855f0 hz tm)))))) a0)))
    (declare (single-float a))
    (%hrect x y w h 0.05f0 0.04f0 0.07f0 0.75f0)
    (%hbar x y w h fill right r g b a)))

;;; ---------------------------------------------------------------- KOSEI (攻勢): the tag and the motes (docs/DUEL_STRINGS.md §5)
(declaim (type f32vec *kosei-v*))
(defvar *kosei-v* (make-f32 10) "Per side: FX-CLOCK of the last paying contact, its multiplier and its screen x y (the mote).")
(defparameter *kosei-kanji* "攻")
(defparameter *kosei-tags* (coerce (loop for i from 15 to 30 collect (format nil "x~,1f" (/ i 10.0))) 'simple-vector)
  "The tag's multiplier text, x1.5 .. x3.0 in tenths (no string made per frame).")
(defparameter *c-kosei* (list 1.0 0.55 0.2 1.0))

(defun kosei-mote (e m x y z)
  "A paying contact of E's (the :kosei event): one ember mote from the hit at (X Y Z) (its screen point now) to his
Reiatsu bar, sized by M; none when the hit is off screen."
  (let ((o (* 5 (fighter-side (fighter e)))) (v *kosei-v*))
    (setf (aref v o) (if (world-to-screen *hud-v* (f32 x) (f32 y) (f32 z)) (f32 (fx-clock)) 0f0) (aref v (+ o 1)) (f32 m)
          (aref v (+ o 2)) (aref *hud-v* 0) (aref v (+ o 3)) (aref *hud-v* 1))))

(defun hud-kosei (side gg x y right tx ty s &optional (ek 8))
  "KOSEI on side SIDE's panel: at a multiplier >= 1.5 (his guard gauge GG) the ember 攻 xM tag ending at X (the inner
end of his guard bar, on the Konpaku row: its middle at Y), toward his side of the screen (RIGHT: the right panel);
the last paying contact's mote flying to (TX TY), his Reiatsu bar, 0.35 s."
  (let ((m (kosei-mult gg)))
    (when (>= m 1.5)
      (let* ((em (* ek s)) (str (svref *kosei-tags* (max 0 (min 15 (- (round (* 10 m)) 15)))))
             (tw (text-width str s)) (kx (if right (+ x (* 0.5 em)) (- x tw (* 2 s) (* 0.5 em)))))
        (set-line kx y em *c-kosei*)
        (setf (aref *bl* 7) (line-width *kosei-kanji*))
        (brush-line *kosei-kanji*)
        (hud-text str (if right (+ x em (* 2 s)) x) (- y (* 3.5 s)) s *c-kosei* :align (if right :left :right)))))
  (%kosei-mote (* 5 side) (f32 tx) (f32 ty) (f32 s)))

(defun kosei-tag-w (gg s &optional (ek 8))
  "The width, px, of HUD-KOSEI's tag at guard gauge GG (0 when it isn't shown: the multiplier below 1.5)."
  (let ((m (kosei-mult gg)))
    (if (>= m 1.5)
        (+ (text-width (svref *kosei-tags* (max 0 (min 15 (- (round (* 10 m)) 15)))) s) (* 2 s) (* ek s))
        0)))

(defun-fast %kosei-mote (o tx ty s)
  "The mote of the paying contact at offset O of *KOSEI-V*, flying from its hit to (TX TY) over 0.35 s (0 B)."
  (declare (fixnum o) (single-float tx ty s))
  (let* ((v *kosei-v*) (t0 (aref v o)) (u (/ (- (fx-clock) t0) 0.35f0)))
    (declare (type f32vec v) (single-float t0 u))
    (when (and (> t0 0f0) (> u 0f0) (< u 1f0))
      (let* ((k (* u u)) (x (aref v (+ o 2))) (y (aref v (+ o 3)))
             (cx (+ x (* k (- tx x)))) (cy (+ y (* k (- ty y)))) (r (* s (+ 1.5f0 (* 1.5f0 (aref v (+ o 1)))))) (a (- 1f0 (* 0.5f0 u))))
        (declare (single-float k x y cx cy r a))
        (dotimes (i 12)                                   ; an ember disc (a 12-gon, drawn here: no boxed arguments)
          (let* ((a0 (* (i->f i) 0.5235988f0)) (a1 (+ a0 0.5235988f0)))
            (declare (single-float a0 a1))
            (%hq cx cy (+ cx (* r (f-cos a0))) (+ cy (* r (f-sin a0))) (+ cx (* r (f-cos a1))) (+ cy (* r (f-sin a1))) cx cy
                 1f0 0.55f0 0.2f0 a)))))))

;;; ---------------------------------------------------------------- side panels: per-kit strings
(defvar *kit-hud* (make-hash-table :test 'eq) "KIT -> #(label meter u-tag): the panel name, the kit meter, U's tag.")

(defun kit-hud (kit)
  "The cached HUD data of KIT: the name label (\"YAMAMOTO  BANKAI\"), the kit meter (inherited
from the base form when this form has none) and the tag of what U does in the form (\"U: WEST\", \"WARD\", \"U: DRINK\")."
  (or (gethash kit *kit-hud*)
      (setf (gethash kit *kit-hud*)
            (vector (format nil "~a~@[  ~a~]" (kit-name kit) (and (not (eq (kit-form kit) :base)) (kit-form-name kit)))
                    (or (kit-meter kit) (kit-meter (find-kit (kit-character kit) :base)))
                    (cond ((kit-u-tag kit)) ((kit-guard-to kit) "U: WEST") ((member :ward (kit-passives kit)) "WARD")
                          ((member :drink (kit-passives kit)) "U: DRINK"))))))

;;; combo counter: per victim side, the last combo with dealt damage (knockdown zeroes the running
;;; total, so the counter keeps the last non-zero one) and its string, rebuilt when it changes
(defstruct (combo-show (:conc-name cs-)) (hits 0) (dmg 0) (t0 -10.0) (str ""))
(defvar *combo-show* (vector (make-combo-show) (make-combo-show)))

(defun combo-string (c hits dmg)
  (unless (and (= hits (cs-hits c)) (= dmg (cs-dmg c)))
    (setf (cs-hits c) hits (cs-dmg c) dmg (cs-str c) (format nil "~d HIT~:P  ~d" hits dmg)))
  (setf (cs-t0 c) (fx-clock))
  c)

(defvar *c-evo* (list 1.0 0.85 0.3 1.0))
(defvar *u-tag* (list 1.0 0.72 0.35 1.0))
(defvar *c-kikon* (list 1.0 0.2 0.25 1.0))
(defun burst-prompt (mode keys side)
  "The HUD prompt for burst MODE (:blue BURST, :orange CHAIN) of SIDE pressed with KEYS (:flick, else :pad / :key: his
bindings, CONTROLS-KEY-PROMPT)."
  (if (eq keys :flick)
      (if (eq mode :orange) "FLICK DOWN  CHAIN" "FLICK DOWN  BURST")
      (key-prompt *bind-pair* side keys (if (eq mode :orange) :chain :burst))))
(defvar *c-callout* (list 1.0 0.85 0.55 1.0))
(defvar *c-hint* (list 0.6 0.95 1.0 1.0) "PERFECT HINT's HOHO!.")

(defparameter *arm-kanji* "腕")
(defparameter *c-blood* (list 0.82 0.06 0.11 1.0))
(defun hud-arm-label (x y s right)
  "The arm meter's label: the brush glyph 腕 and UDE, from X toward the panel's outside (RIGHT: the right panel)."
  (let* ((em (* 8 s)) (tw (text-width "UDE" s)))
    (set-line (if right (- x (* 0.5 em)) (+ x (* 0.5 em))) (+ y (* 3.5 s)) em *c-blood*)
    (setf (aref *bl* 7) (line-width *arm-kanji*))
    (brush-line *arm-kanji*)
    (hud-text "UDE" (if right (- x em (* 2 s)) (+ x em (* 2 s))) y s *c-blood* :align (if right :right :left))
    tw))

(defun hud-side (e w h s)
  (let* ((f (fighter e)) (g (gauges e)) (kit (fighter-kit f)) (kh (kit-hud kit)) (side (fighter-side f)) (right (= side 1))
         (m (* 0.03 w)) (bw (* 0.36 w)) (x (if right (- w m bw) m)) (edge (if right (+ x bw) x))
         (align (if right :right :left)) (y (* 0.05 h)) (bh (max (* 7 s) (* 0.028 h)))
         (ns (max 2 s)) (tm (fx-clock)) (ls s)
         (frac (/ (gauges-reishi g) (float (gauges-reishi-max g)))) (red (red-p (gauges-reishi g) (gauges-reishi-max g))))
    ;; name + form
    (hud-text (svref kh 0) edge (- y (* 8 ns) s) ns (if (kit-awakening kit) *ember* *white*)
              :align align)
    ;; Reishi + trail
    (let ((tr (aref *trail-v* side)))
      (setf (aref *trail-v* side) (f32 (if (> tr frac) (max frac (- tr (* 0.35 (hud-dt)))) frac)))
      (%hud-reishi (f32 x) (f32 y) (f32 bw) (f32 bh) (f32 frac) (aref *trail-v* side) right red tm))
    ;; the guard gauge, right under it
    (let* ((gf (/ (gauges-gg g) *gg-max*)) (ti (+ 2 side)) (tr (aref *trail-v* ti)) (ward (passive-p e :ward)))
      (setf (aref *trail-v* ti) (f32 (if (> tr gf) (max gf (- tr (* 0.5 (hud-dt)))) gf)))
      (%hud-guard (f32 x) (f32 (+ y bh (* 2 s))) (f32 bw) (f32 (max (* 3 s) (* 0.3 bh))) (f32 gf) (aref *trail-v* ti)
                  right (gauges-guardless g)
                  (logior (if (and (or ward (member (fighter-state f) '(:guard :guard-hit))) (< gf 1.0)) 1 0)
                          (if (or ward (passive-p e :pierce)) 2 0) (if (guard-locked-now-p f) 4 0))
                  tm)
      (let ((hk (kit-hook kit :hud-guard)))              ; a form's own look of the bar (drawn over it)
        (when hk (funcall hk e x (+ y bh (* 2 s)) bw (max (* 3 s) (* 0.3 bh)) right s tm))))
    ;; KOSEI: the tag at the guard bar's inner end (on the Konpaku row, clear of the pips), the mote to the Reiatsu bars
    (hud-kosei side (gauges-gg g) (if right x (+ x bw)) (+ y bh (* 16 s) (* 0.5 (max (* 4.5 s) (* 0.013 h))))
               right (if right (- edge (* 0.12 w)) (+ edge (* 0.12 w))) (+ y bh (* 26 s)) s)
    ;; Konpaku soul flames
    (%hud-pips (f32 x) (f32 (+ y bh (* 16 s))) (f32 bw) (f32 (max (* 4.5 s) (* 0.013 h))) side (gauges-konpaku g) right red tm 3.2f0
               (at-stake e))
    ;; Reiatsu: 3 bars + label
    (let* ((sy (+ y bh (* 25 s))) (sw (* 0.075 w)) (sh (max (* 3 s) (* 0.011 h))) (gap (* 3 s)) (row (* 11 s))
           (lx (if right (- edge (* 3 (+ sw gap)) (* 3 s)) (+ edge (* 3 (+ sw gap)) (* 3 s)))))
      (%hud-reiatsu (f32 edge) (f32 sy) (f32 sw) (f32 sh) (f32 gap) (gauges-reiatsu g) right)
      (hud-text "REIATSU" lx (- (+ sy (* 0.5 sh)) (* 3.5 s)) ls '(0.45 0.8 1 0.9) :align align)
      ;; flash-step (Hoho, Burst), Awakening (drains during a timed awakening), the kit meter (Inferno; drains in its form)
      (let* ((fy (+ sy row)) (ay (+ fy row)) (aw (+ (* 3 sw) (* 6 s))) (ah (max (* 3 s) (* 0.009 h))) (ty (- (* 0.5 ah) (* 3.5 s)))
             (ax (if right (- edge aw) x)) (lx (if right (- edge aw (* 6 s)) (+ edge aw (* 6 s))))
             (timed (and (kit-awakening kit) (plusp (gauges-form-total g))))
             (hot (or (gauges-evolution g) (kit-awakening kit)))
             (afill (cond (timed (timer-fill (gauges-form-left g) (gauges-form-total g) 1.0))
                          ((kit-awakening kit) 1.0) (t (/ (gauges-awaken g) *awaken-max*)))))
        (%hud-flash (f32 ax) (f32 fy) (f32 aw) (f32 ah) (f32 (/ (gauges-fs g) *fs-max*)) right (burst-ok-p e) (gauges-burst g) tm)
        (hud-text "FLASH STEP" lx (+ fy ty) ls '(0.6 0.78 1 0.9) :align align)
        (%hud-thin (f32 ax) (f32 ay) (f32 aw) (f32 ah) (f32 afill) right 1f0 (if hot 0.85f0 0.75f0) 0.3f0
                   (if hot 0.6f0 1f0) (if hot 4f0 0f0) tm)
        (cond ((gauges-evolution g)
               (hud-text "EVOLUTION" lx (+ ay ty) ls (alpha! *c-evo* (hud-pulse 3.0)) :align align))
              ((svref kh 2) (hud-text (svref kh 2) lx (+ ay ty) ls *u-tag* :align align))   ; what this form's guard adds
              ((kit-awakening kit) (hud-text (kit-form-name kit) lx (+ ay ty) ls *ember* :align align))
              (t (hud-text "AWAKEN" lx (+ ay ty) ls '(0.95 0.8 0.4 0.9) :align align)))
        (let ((l (kit-command-move kit :sig)))   ; the L cooldown (+ Shift+L's line: HUD-COOLDOWNS)
          (when (and l (kit-awakening kit) (plusp (mv-cooldown l)))   ; (a form without an L: Rukia's THAW)
            (let ((my (+ ay row)))
              (hud-cooldowns f kit ax my aw ah right tm)
              (hud-text "COOLDOWN" lx (+ my ty) ls '(0.84 0.88 0.94 0.9) :align align))))
        (let ((meter (svref kh 1)))
          (when (getf meter :ladder)                    ; NOME: the cup ladder (Nozarashi), yellow
            (let* ((ladder (getf meter :ladder)) (rung (or (position (kit-form kit) ladder :key #'first) 0))
                   (mx (getf meter :max)))
              (%hud-nome (f32 ax) (f32 (+ ay row)) (f32 aw) (f32 ah) (f32 (/ (gauges-meter g) mx)) right rung
                         (f32 (/ (fifth (nth rung ladder)) mx)) tm)
              (hud-text (getf meter :name) lx (+ ay row ty) ls '(1 0.85 0.3 0.95) :align align)))
          (when (kit-pips kit)                          ; UDE: the Bankai's arm (Kenpachi), BLOOD pips
            (%hud-arm (f32 ax) (f32 (+ ay row)) (f32 aw) (f32 ah) (round (gauges-meter g)) (gauges-meter-idle g) right tm)
            (hud-arm-label lx (+ ay row ty) ls right))
          (when (getf meter :temp)                      ; Rukia's cold gauge (the awakened form has no L cooldown: the row
            (hud-temp e kit ax (+ ay row) aw ah right tm) ; is hers alone)
            (hud-temp-label lx (+ ay row ty) ls right (temp-label g kit)))
          (when (getf meter :draw)                      ; a character's own meter (its :draw function, e.g. Senjumaru's)
            (funcall (getf meter :draw) e kit ax (+ ay row) aw ah right tm lx (+ ay row ty) ls))
          (when (and meter (not (kit-awakening kit)) (not (getf meter :draw)))
            (let* ((my (+ ay row)) (burning (plusp (gauges-form-left g)))
                   (mfill (if burning
                              (timer-fill (gauges-form-left g) (gauges-form-total g) 1.0)
                              (/ (gauges-meter g) (getf meter :max)))))
              (%hud-thin (f32 ax) (f32 my) (f32 aw) (f32 ah) (f32 mfill) right 1f0 (if burning 0.4f0 0.45f0) (if burning 0.1f0 0.12f0)
                         (if burning 0.7f0 1f0) (if burning 5f0 0f0) tm)
              (hud-text (getf meter :name) lx (+ my ty) ls '(1 0.55 0.25 0.9) :align align))))))
    ;; combo counter under this side's bar (this side is the victim): the last total that dealt damage
    (let ((c (svref *combo-show* side)))
      (when (and (> (fighter-combo-hits f) (if (eq *mode* :practice) 0 1)) (plusp (fighter-combo-dmg f)))
        (combo-string c (fighter-combo-hits f) (fighter-combo-dmg f)))
      (when (or (< (- tm (cs-t0 c)) 1.2) (eq *mode* :practice))   ; PRACTICE: the last combo stays up
        (hud-text (cs-str c) edge (+ y bh (* 62 s)) (* 2 s) '(1 0.9 0.6 1) :align align)))
    ;; the panel's box (the callouts and words keep clear of it): its bars, labels and combo counter
    (let ((o (* 4 side)) (pb *panel-box*))
      (setf (aref pb o) (f32 (- x (* 4 s))) (aref pb (+ o 1)) 0f0 (aref pb (+ o 2)) (f32 (+ x bw (* 4 s)))
            (aref pb (+ o 3)) (f32 (+ y bh (* 78 s)))))
    ;; KIKON / BURST prompts for a human
    (when (and (not (brain e)) (member *flow* '(:battle)))
      (cond ((bankai-ready-p e)                           ; cup 3, <= 4 Konpaku, free: P enters the Bankai (Kenpachi)
             (hud-text (cond ((pad-connected-p side) "BACK  BANKAI") (right "KP+  BANKAI") (t "P  BANKAI"))
                       (if right (* 0.75 w) (* 0.25 w)) (* 0.72 h) (* 3 s) (alpha! *c-blood* (+ 0.5 (* 0.5 (hud-pulse 4.0))))
                       :align :center)
             (when (kikon-ready-p e)
               (hud-text (if (pad-connected-p side) "HOLD RT  KIKON" (if right "HOLD KP6  KIKON" "HOLD O  KIKON"))
                         (if right (* 0.75 w) (* 0.25 w)) (* 0.78 h) (* 3 s) (alpha! *c-kikon* (+ 0.5 (* 0.5 (hud-pulse 4.0))))
                         :align :center)))
            ((kikon-ready-p e)                            ; the opponent is red: the rush, held, Kiko's
             (hud-text (if (pad-connected-p side) "HOLD RT  KIKON" (if right "HOLD KP6  KIKON" "HOLD O  KIKON"))
                       (if right (* 0.75 w) (* 0.25 w)) (* 0.78 h) (* 3 s) (alpha! *c-kikon* (+ 0.5 (* 0.5 (hud-pulse 4.0))))
                       :align :center))
            ((member (burst-ok-p e) '(:blue :orange))    ; (WHITE: most of neutral; the bar's glow says it)
             (hud-text (burst-prompt (burst-ok-p e) (cond (*one-hand* :flick) ((pad-connected-p side) :pad) (t :key)) side)
                       (if right (* 0.75 w) (* 0.25 w)) (* 0.78 h) (* 2 s) (alpha! (burst-color (burst-ok-p e)) (+ 0.5 (* 0.5 (hud-pulse 4.0))))
                       :align :center))))))

;;; ---------------------------------------------------------------- portrait blocks (P2, docs/DUEL_MOBILE_DESIGN.md §4.2)
;;; A tall screen splits the HUD by fighter (the user's decision 2026-09-27): the opponent's (P2's) block across the top
;;; under the safe-area inset, the player's (P1's, the fighter near the camera) across the bottom over the home
;;; indicator, each full width so its bars and flames can be large. A block, in S units from its top edge: row 1 the name
;;; (1.4 s), the KOSEI tag after it, and at the right end ONE label (EVOLUTION, else the kit meter's name / COOLDOWN, else
;;; U's tag) and, on P2's block, the timer; Reishi (5 s tall); the guard gauge (2 s); the Konpaku flames at the left and a
;;; row of small unlabelled gauges beside them in the landscape panel's colours (Reiatsu cells, flash step, Awakening, the
;;; kit meter or the awakened form's L cooldown). The user's decisions 2026-09-28 (DUEL_MOBILE_DESIGN §15.2):
;;; the flames, larger (r up to 4 s), fill row 1 after the name (up to P2's timer); the small gauges are 4 s thick
;;; (were 2.5 s) on the last row, with the label and the KOSEI tag at its right end. The block stays 29 s.
;;; The combo counter hangs under P2's block / over P1's.
(defvar *safe-top* 0 "The safe-area inset at the top, CSS px (onehand.lisp DECK-UPDATE; 0 off a notched phone).")
(defvar *safe-bot* 0 "The safe-area inset at the bottom (the home indicator), CSS px (DECK-UPDATE).")
(defun portrait-block-h (s) "A portrait HUD block's height, px." (* 29 s))
(defun portrait-top-px (s) "Top edge of P2's block, px." (+ (* *safe-top* (pixel-density)) (* 2 s)))
(defun portrait-hud-bottom (s) "Bottom of P2's block at the top, px." (+ (portrait-top-px s) (portrait-block-h s)))
(defun portrait-p1-top (s h) "Top edge of P1's block at the bottom, px (over the home indicator, at least 8 CSS px up)."
  (- h (* (max 8 (+ *safe-bot* 4)) (pixel-density)) (portrait-block-h s)))

(defun portrait-label (g kit kh meter)
  "The one label of a portrait block, or NIL: EVOLUTION, the kit meter's name / COOLDOWN, U's tag."
  (cond ((gauges-evolution g) "EVOLUTION")
        ((getf meter :label) (funcall (getf meter :label) g kit))   ; a character's own meter
        ((kit-pips kit) (getf meter :name))                ; UDE
        ((getf meter :temp) (temp-label g kit))            ; Rukia's band: -18C, -50C, -273C, THAW
        ((getf meter :ladder) (getf meter :name))
        ((and (kit-awakening kit) (kit-command-move kit :sig) (plusp (mv-cooldown (kit-command-move kit :sig)))) "COOLDOWN")
        ((and meter (not (kit-awakening kit))) (getf meter :name))
        (t (svref kh 2))))

(defun hud-side-portrait (e w h s)
  (let* ((f (fighter e)) (g (gauges e)) (kit (fighter-kit f)) (kh (kit-hud kit)) (side (fighter-side f)) (top (= side 1))
         (tm (fx-clock)) (y (if top (portrait-top-px s) (portrait-p1-top s h))) (m (* 4 s)) (bw (- w m m))
         (ns (round (* 1.4 s))) (tsc (round (* 1.4 s)))
         (frac (/ (gauges-reishi g) (float (gauges-reishi-max g)))) (red (red-p (gauges-reishi g) (gauges-reishi-max g)))
         (ry (+ y (* 7 ns) (* 2 s))) (bh (* 5 s)) (gy (+ ry bh s))
         (yb (+ gy (* 5 s))) (bar (* 4 s))                                ; the last row: the small gauges
         (meter (svref kh 1)) (label (portrait-label g kit kh meter))
         (rx (- (+ m bw) (if top (+ (* 17 tsc) (* 4 s)) 0))))          ; the right end of row 1 (P2: left of the timer)
    (if top                                                  ; a soft ink backing: the block reads on a white card too
        (ui-gradient 0 0 w (+ y (portrait-block-h s) (* 6 s)) '(0 0 0 0.5) '(0 0 0 0))
        (ui-gradient 0 (- y (* 6 s)) w (- h (- y (* 6 s))) '(0 0 0 0) '(0 0 0 0.5)))
    ;; row 1 (playtest 2, 2026-09-28: the last row's gauges span the Reishi bar, so its label and KOSEI tag moved up
    ;; here): the name, the label after it (not when it repeats the form's name: Rukia's band), the Konpaku flames in
    ;; what is left, the KOSEI tag at the row's right end (P2: left of the timer, HUD-BATTLE). The flames shrink to fit
    ;; (r <= fw / 2.4 n: never overlapping), so nothing overlaps them
    (let* ((str (svref kh 0)) (sc (fit-scale str ns (* 0.45 bw)))
           (lab (and label (not (and (kit-awakening kit) (string= label (kit-form-name kit)))) label))
           (kw (kosei-tag-w (gauges-gg g) s 7)))
      (flet ((fw () (- rx m (text-width str sc) (* 5 s) (if lab (+ (text-width lab s) (* 4 s)) 0) (if (plusp kw) (+ kw (* 3 s)) 0)))
             (short () (setf str (if (kit-awakening kit) (kit-form-name kit) (kit-name kit)) sc (fit-scale str ns (* 0.45 bw)))))
        (when (< sc s) (short))
        ;; a crowded row (P2's timer, a long name, the label and KOSEI): the flames keep r >= 3 s; the short name first,
        ;; then the label goes
        (let ((fmin (* 2.4 *konpaku-max* 3 s)))
          (when (< (fw) fmin) (short))
          (when (< (fw) fmin) (setf lab nil))))
      (hud-text str m y sc (if (kit-awakening kit) *ember* *white*))
      (let* ((lx (+ m (text-width str sc) (* 4 s)))
             (x0 (if lab (+ lx (text-width lab s) (* 4 s)) lx)) (fw (- rx x0 s (if (plusp kw) (+ kw (* 3 s)) 0)))
             (n *konpaku-max*) (r (min (* 4 s) (/ fw (* 2.4 n)))) (pitch (min 4.5 (/ fw (* n r)))))
        (when lab
          (hud-text lab lx (+ y (* 7 ns) (* -7 s)) s
                    (cond ((gauges-evolution g) (alpha! *c-evo* (hud-pulse 3.0))) ((eq lab (svref kh 2)) *u-tag*)
                          (t '(1 0.62 0.3 0.95)))))
        (%hud-pips (f32 x0) (f32 (+ y (* 7 ns) (* 1.5 s) (* -0.85 r))) (f32 fw) (f32 r) side (gauges-konpaku g) nil red tm
                   (f32 pitch) (at-stake e))
        (hud-kosei side (gauges-gg g) (- rx s) (+ y (* 3.5 ns)) nil (+ m (* 0.1 bw)) (+ yb (* 0.5 bar)) s 7)))
    ;; Reishi + trail, the guard gauge
    (let ((tr (aref *trail-v* side)))
      (setf (aref *trail-v* side) (f32 (if (> tr frac) (max frac (- tr (* 0.35 (hud-dt)))) frac)))
      (%hud-reishi (f32 m) (f32 ry) (f32 bw) (f32 bh) (f32 frac) (aref *trail-v* side) nil red tm))
    (let* ((gf (/ (gauges-gg g) *gg-max*)) (ti (+ 2 side)) (tr (aref *trail-v* ti)) (ward (passive-p e :ward)))
      (setf (aref *trail-v* ti) (f32 (if (> tr gf) (max gf (- tr (* 0.5 (hud-dt)))) gf)))
      (%hud-guard (f32 m) (f32 gy) (f32 bw) (f32 (* 2 s)) (f32 gf) (aref *trail-v* ti) nil (gauges-guardless g)
                  (logior (if (and (or ward (member (fighter-state f) '(:guard :guard-hit))) (< gf 1.0)) 1 0)
                          (if (or ward (passive-p e :pierce)) 2 0) (if (guard-locked-now-p f) 4 0))
                  tm)
      (let ((hk (kit-hook kit :hud-guard))) (when hk (funcall hk e m gy bw (* 2 s) nil s tm))))
    ;; the small gauges (the last row, as long as the Reishi bar): Reiatsu cells, flash step, Awakening, the kit meter /
    ;; cooldowns
    (let* ((x0 m) (a bw) (gap (* 3 s)) (cd (and (kit-awakening kit) (kit-command-move kit :sig)
                                                        (plusp (mv-cooldown (kit-command-move kit :sig)))))
           (kitp (or (getf meter :draw) (getf meter :ladder) (kit-pips kit) (getf meter :temp) cd (and meter (not (kit-awakening kit)))))
           (n (if kitp 4 3)) (gw (/ (- a (* (1- n) gap)) n)) (sw (/ (- gw (* 2 s)) 3))
           (timed (and (kit-awakening kit) (plusp (gauges-form-total g))))
           (hot (or (gauges-evolution g) (kit-awakening kit)))
           (afill (cond (timed (timer-fill (gauges-form-left g) (gauges-form-total g) 1.0))
                        ((kit-awakening kit) 1.0) (t (/ (gauges-awaken g) *awaken-max*)))))
      (%hud-reiatsu (f32 x0) (f32 yb) (f32 sw) (f32 bar) (f32 s) (gauges-reiatsu g) nil)
      (%hud-flash (f32 (+ x0 gw gap)) (f32 yb) (f32 gw) (f32 bar) (f32 (/ (gauges-fs g) *fs-max*)) nil (burst-ok-p e) (gauges-burst g) tm)
      (%hud-thin (f32 (+ x0 (* 2 (+ gw gap)))) (f32 yb) (f32 gw) (f32 bar) (f32 afill) nil 1f0 (if hot 0.85f0 0.75f0) 0.3f0
                 (if hot 0.6f0 1f0) (if hot 4f0 0f0) tm)
      (when kitp
        (let ((kx (+ x0 (* 3 (+ gw gap)))))
          (cond ((getf meter :draw) (funcall (getf meter :draw) e kit kx yb gw bar nil tm nil nil nil))   ; its own meter
                ((kit-pips kit)                          ; UDE: the Bankai's arm
                 (%hud-arm (f32 kx) (f32 yb) (f32 gw) (f32 bar) (round (gauges-meter g)) (gauges-meter-idle g) nil tm))
                ((getf meter :temp) (hud-temp e kit kx yb gw bar nil tm))   ; Rukia's cold gauge
                ((getf meter :ladder)
                 (let* ((ladder (getf meter :ladder)) (rung (or (position (kit-form kit) ladder :key #'first) 0)) (mx (getf meter :max)))
                   (%hud-nome (f32 kx) (f32 yb) (f32 gw) (f32 bar) (f32 (/ (gauges-meter g) mx)) nil rung
                              (f32 (/ (fifth (nth rung ladder)) mx)) tm)))
                (cd (hud-cooldowns f kit kx yb gw bar nil tm))
                (t (let ((burning (plusp (gauges-form-left g))))
                     (%hud-thin (f32 kx) (f32 yb) (f32 gw) (f32 bar)
                                (f32 (if burning (timer-fill (gauges-form-left g) (gauges-form-total g) 1.0) (/ (gauges-meter g) (getf meter :max))))
                                nil 1f0 (if burning 0.4f0 0.45f0) (if burning 0.1f0 0.12f0) (if burning 0.7f0 1f0) (if burning 5f0 0f0) tm)))))))
    ;; the combo counter (this side is the victim): under P2's block, over P1's
    (let ((c (svref *combo-show* side)) (bh2 (portrait-block-h s)))
      (when (and (> (fighter-combo-hits f) (if (eq *mode* :practice) 0 1)) (plusp (fighter-combo-dmg f)))
        (combo-string c (fighter-combo-hits f) (fighter-combo-dmg f)))
      (when (or (< (- tm (cs-t0 c)) 1.2) (eq *mode* :practice))   ; PRACTICE: the last combo stays up
        (hud-text (cs-str c) m (if top (+ y bh2 (* 2 s)) (- y (* 16 s))) (* 2 s) '(1 0.9 0.6 1)))
      (let ((o (* 4 side)) (pb *panel-box*))                 ; the block's box (+ the combo counter's lane)
        (setf (aref pb o) 0f0 (aref pb (+ o 2)) (f32 w)
              (aref pb (+ o 1)) (f32 (if top 0 (- y (* 16 s)))) (aref pb (+ o 3)) (f32 (if top (+ y bh2 (* 16 s)) h)))))
    ;; KIKON / BURST prompts for a human: centred under P2's block (clear of the thumb and of the fighters' heads' lane)
    (when (and (not (brain e)) (member *flow* '(:battle)))
      (flet ((prompt (str col)
               (let ((k (fit-scale str (* 2 s) (* 0.94 w))))
                 (hud-text str (* 0.5 w) (+ (portrait-hud-bottom s) (* 17 s)) k col :align :center))))
        (cond ((bankai-ready-p e)
               (prompt (if *one-hand* "AWAKEN  BANKAI" (if (pad-connected-p side) "BACK  BANKAI" "P  BANKAI"))
                       (alpha! *c-blood* (+ 0.5 (* 0.5 (hud-pulse 4.0))))))
              ((kikon-ready-p e)
               (prompt (if *one-hand* "HOLD O  KIKON" (key-prompt *bind-pair* side (if (pad-connected-p side) :pad :key) :kikon))
                       (alpha! *c-kikon* (+ 0.5 (* 0.5 (hud-pulse 4.0))))))
              ((member (burst-ok-p e) '(:blue :orange))
               (prompt (burst-prompt (burst-ok-p e) (cond (*one-hand* :flick) ((pad-connected-p side) :pad) (t :key)) side)
                       (alpha! (burst-color (burst-ok-p e)) (+ 0.5 (* 0.5 (hud-pulse 4.0)))))))))))

;;; ---------------------------------------------------------------- over the fighters
(defvar *callout-box* (vector nil 0 0 0 0) "The callout drawn first this frame: #(drawn x0 y0 x1 y1).")

(defun boxes-overlap-p (ax0 ay0 ax1 ay1 bx0 by0 bx1 by1)
  (and (< ax0 bx1) (< bx0 ax1) (< ay0 by1) (< by0 ay1)))

(defun callout-y (x0 y0 x1 y1 w h s)
  "Top edge for a callout box (X0 Y0 X1 Y1) that steps out of the big words' boxes and the other
callout: above the box it hits, or below it when above would reach the side panels; last, below a HUD
side panel it would overlap (*PANEL-BOX*; Phase 5)."
  (let ((th (- y1 y0)) (gap (* 4 s)))
    (flet ((dodge (bx0 by0 bx1 by1)
             (when (boxes-overlap-p x0 y0 x1 y1 bx0 by0 bx1 by1)
               (let ((up (- by0 gap th)))
                 (setf y0 (if (>= up (* 0.22 h)) up (+ by1 gap)) y1 (+ y0 th))))))
      (dolist (wd *words*)
        (multiple-value-bind (bx0 by0 bx1 by1) (word-box wd w h) (dodge bx0 by0 bx1 by1)))
      (let ((cb *callout-box*))
        (when (svref cb 0) (dodge (svref cb 1) (svref cb 2) (svref cb 3) (svref cb 4))))
      (let ((pb *panel-box*))
        (dotimes (i 2)
          (let ((o (* 4 i)))
            (when (boxes-overlap-p x0 y0 x1 y1 (aref pb o) (aref pb (+ o 1)) (aref pb (+ o 2)) (aref pb (+ o 3)))
              (if (> (aref pb (+ o 1)) 0f0)                  ; a panel at the bottom (portrait P1): above it
                  (setf y0 (- (aref pb (+ o 1)) gap th) y1 (+ y0 th))
                  (setf y0 (+ (aref pb (+ o 3)) gap) y1 (+ y0 th))))))))
    y0))

(defvar *callout-seen* (vector nil nil 0 0) "Per side: the callout string last seen and its frames left then.")
(defvar *side-caps* (vector nil nil) "Per side: the brush callout (a BCAP, brush.lisp *BRUSH-CALLOUTS*) or NIL.")

(defun side-cap (e)
  "Fighter E's brush callout: a new callout (a new string, or its frames reset) of a move with a brush name
(*BRUSH-CALLOUTS*) starts one at his side of the screen; T while it is shown (the pixel callout then stays off)."
  (let* ((f (fighter e)) (side (fighter-side f)) (seen *callout-seen*) (str (fighter-callout f)) (ct (fighter-callout-t f)))
    (when (and str (> ct 0) (or (not (eq str (svref seen side))) (> ct (svref seen (+ 2 side)))))
      (let ((entry (and (fighter-move f) (assoc (mv-name (fighter-move f)) *brush-callouts*))))
        (setf (svref *side-caps* side)
              (and entry (destructuring-bind (kanji reading mark) (rest entry)
                           (make-bcap kanji :reading reading :mark mark :layout :callout :side side :secs 1.3))))))
    (setf (svref seen side) str (svref seen (+ 2 side)) ct)
    (let ((c (svref *side-caps* side)))
      (and c (or (draw-bcap c (window-width) (window-height)) (setf (svref *side-caps* side) nil))))))

(defun hud-world (e w h s)
  "Over fighter E in the world: his move-name callout (or its brush column at his side); the red soul flame
when he is red."
  (let* ((f (fighter e)) (g (gauges e)) (p (pos-of e)) (v *hud-v*)
         (top (+ (aref p 1) (body-hurt-h (model-body (model e))) 0.5)))
    (when (and (not (side-cap e)) (> (fighter-callout-t f) 0) (fighter-callout f)
               (world-to-screen v (aref p 0) (+ top 0.3) (aref p 2)))
      (let* ((str (fighter-callout f)) (pt (portrait-p))   ; portrait: smaller, and kept on the screen
             (em (if pt (min (* 0.03 h) (/ (* 0.94 w) (line-width str))) (* 0.045 h)))
             (tw (round (* em (line-width str)))) (th (round (* 0.8 em)))
             (x0 (if pt
                     (round (max (* 0.03 w) (min (- (* 0.97 w) tw) (- (aref v 0) (* 0.5 tw)))))
                     (round (- (aref v 0) (* 0.5 tw)))))
             (y0 (callout-y x0 (round (aref v 1)) (+ x0 tw) (+ (round (aref v 1)) th) w h s))
             (cb *callout-box*))
        (setf (svref cb 0) t (svref cb 1) x0 (svref cb 2) (round y0) (svref cb 3) (+ x0 tw) (svref cb 4) (+ (round y0) th))
        (hud-over-panel "callout" str x0 y0 (+ x0 tw) (+ y0 th) w h)
        (set-line (+ x0 (* 0.5 tw)) (+ y0 (* 0.5 th)) em *c-callout* (min 1.0 (/ (fighter-callout-t f) 20.0)))
        (setf (aref *bl* 7) (line-width str))
        (brush-line str)))
    (when (red-p (gauges-reishi g) (gauges-reishi-max g))
      (vfx-soul-flame (aref p 0) top (aref p 2) (fx-clock)))))

(defun hud-hint (e h)
  "PERFECT HINT (SETTINGS, the user 2026-10-01): HOHO! at human fighter E's head while a Hoho started now would be
perfect (PERFECT-UP-P: a free state, the Hoho affordable, PERFECT-NOW-P)."
  (let ((p (pos-of e)) (v *hud-v*))
    (when (and (= 1 (setting :hint)) (not (cpu-p e)) (perfect-up-p e (state-of e))
               (world-to-screen v (aref p 0) (+ (aref p 1) (body-hurt-h (model-body (model e))) 0.15) (aref p 2)))
      (set-line (aref v 0) (aref v 1) (* (if (portrait-p) 0.035 0.045) h) *c-hint*)
      (setf (aref *bl* 7) (line-width "HOHO!"))
      (brush-line "HOHO!"))))

(defvar *timer-strings* (make-array 1000 :initial-element nil) "Seconds -> their string, made once.")

(declaim (type f32vec *hud-v2*))
(defvar *hud-v2* (make-f32 3))

(defun hud-rush-lines (e)
  "Speed lines along a Kikon rush's dash-in (RUSH-DASHING-P in its :follow phase), on the screen direction
from the rusher to his victim; and along Kenpachi's SP2 dash (§4.2 SP2 dash, Phase 5: its active frames), on his
facing."
  (let* ((f (fighter e)) (mv (fighter-move f))
         (charge (and mv (eq (fighter-state f) :move) (eq (mv-name mv) :ke-charge) (eq (fighter-phase f) :main)
                      (<= (mv-s mv) (fighter-sf f) (+ (mv-s mv) (mv-a mv) -1)))))
    (when (or charge (and (eq (fighter-state f) :move) (eq (fighter-phase f) :follow) (rush-dashing-p f)))
      (let ((p (pos-of e)) (a *hud-v*) (b *hud-v2*))
        (when (and (world-to-screen a (aref p 0) 1f0 (aref p 2))
                   (if charge
                       (world-to-screen b (f32 (+ (aref p 0) (* 2 (fwd-x (yaw-of e))))) 1f0 (f32 (+ (aref p 2) (* 2 (fwd-z (yaw-of e))))))
                       (world-to-screen b (fighter-ox f) 1f0 (fighter-oz f))))
          (ui-speed-lines (f32 (atan (- (aref b 1) (aref a 1)) (- (aref b 0) (aref a 0)))) 14 '(1 1 1 0.55)
                          (f->i (* 12f0 (fx-clock)))))))))

(defun hud-battle (w h s)
  (setf (svref *callout-box* 0) nil)
  (dolist (e (list *p1* *p2*)) (when (entity-alive-p e) (hud-rush-lines e)))
  (dolist (e (list *p1* *p2*))                                                   ; both panels first: the callouts
    (when (entity-alive-p e) (if (portrait-p) (hud-side-portrait e w h s) (hud-side e w h s))))
  (dolist (e (list *p1* *p2*)) (when (entity-alive-p e) (hud-world e w h s) (hud-hint e h)))  ; keep clear of them
  (when (eq *mode* :endless) (hud-endless-tag w h s))    ; STAGE n (endless.lisp)
  (when (eq *mode* :practice)                            ; no timer: PRACTICE's tag in its place (landscape)
    (unless (portrait-p) (hud-text "PRACTICE" (floor w 2) (* 0.06 h) (* 2 s) *dim* :align :center))
    (return-from hud-battle))
  (let* ((secs (min 999 (ceiling (max 0 *timer*) 60)))
         (str (or (svref *timer-strings* secs) (setf (svref *timer-strings* secs) (format nil "~d" secs)))))
    (if (portrait-p)                                     ; portrait: the right end of P2's name row
        (let ((k (round (* 1.4 s))))
          (ui-big-text str (- w (* 4 s) (* 8.5 k)) (+ (portrait-top-px s) (* 3.5 k)) k
                       (if (< secs 30) '(1 0.3 0.3 1) *white*) '(0 0 0 0.7) (ceiling s 2) :shear 0.0))
        (ui-big-text str (floor w 2) (* 0.07 h) (* 4 s)
                     (if (< secs 30) '(1 0.3 0.3 1) *white*) '(0 0 0 0.7) s :shear 0.0))))

;;; ---------------------------------------------------------------- screens
(defun hud-menu (items y0 w h s &optional (cx (/ w 2)) (bottom 0.97))
  "Vertical menu centred on CX from Y0 (fraction of H) down to at most BOTTOM (a long list, e.g. PRACTICE's pause, packs
its rows and shrinks its text to fit); *MENU* is highlighted."
  (let* ((k (min 1 (/ (* h (- bottom y0)) (* (length items) 22 s)))) (sc (max 1 (floor (* 2 s k)))) (dy (* 22 s k)))
    (loop for it in items for i from 0 do
      (let* ((sel (= i *menu*)) (y (+ (* h y0) (* i dy))) (sc (fit-scale it sc (* 0.94 w))) (tw (text-width it sc)))
        (when sel
          (ui-gradient (- cx (* 0.5 tw) (* 14 s)) (- y (* 3 s)) (+ tw (* 28 s)) (+ (* 7 sc) (* 6 s))
                       '(0.8 0.3 0.05 0.0) '(0.8 0.3 0.05 0.8) :vertical nil))
        (when (touch-tap-zones-p)                          ; the row as a tap target (onehand.lisp TAPPED-ROW)
          (note-menu-row i (- cx (max (* 0.5 tw) (* 0.3 w))) (- y (* 0.5 (- dy (* 7 sc)))) (+ cx (max (* 0.5 tw) (* 0.3 w)))
                         (+ y (* 7 sc) (* 0.5 (- dy (* 7 sc))))))
        (ui-text it (round cx) y :scale sc :align :center :color (if sel *white* '(0.8 0.78 0.85 1)) :shadow t)))))

(defun hud-controls (w h s)
  "CONTROLS (the user, 2026-10-01): each action's key and pad button for P1 and P2, the selected cell lit (blinking
while it waits for a key), then RESET DEFAULTS and BACK; the fixed combinations and the help below."
  (ui-rect 0 0 w h '(0 0 0 0.7))
  (ui-big-text "CONTROLS" (floor w 2) (* 0.08 h) (* 4 s) *white* '(0.7 0.25 0.05 1) s)
  (let* ((n (length *bind-actions*)) (dy (* 12 s)) (y0 (* 0.2 h)) (cols (list (* 0.42 w) (* 0.54 w) (* 0.68 w) (* 0.8 w)))
         (wait (and *capture* (< (mod (fx-clock) 0.6) 0.4))))
    (loop for t1 in '("P1 KEY" "P1 PAD" "P2 KEY" "P2 PAD") for x in cols
          do (ui-text t1 (round x) (- y0 dy) :scale s :align :center :color '(1 0.85 0.3 1)))
    (loop for a in *bind-actions* for label in *bind-row-names* for i from 0 for y = (+ y0 (* i dy))
          do (ui-text label (round (* 0.34 w)) y :scale s :align :right :color (if (= i *menu*) *white* *dim*))
             (loop for x in cols for c from 0
                   for sel = (and (= i *menu*) (= c *bind-col*))
                   for txt = (if (and sel *capture*) (if (evenp c) "PRESS A KEY" "PRESS A BUTTON")
                                 (bind-label (binding-name (svref *bind-pair* (floor c 2)) a (if (evenp c) :key :pad))))
                   do (when (and sel (not (and *capture* (not wait))))
                        (ui-rect (- x (* 0.055 w)) (- y (* 2 s)) (* 0.11 w) (* 11 s) '(0.8 0.3 0.05 0.8)))
                      (ui-text txt (round x) y :scale (fit-scale txt s (* 0.11 w)) :align :center :color *white*)))
    (loop for it in '("RESET DEFAULTS" "BACK") for i from n for y = (+ y0 (* (+ i 0.4) dy))
          do (when (= i *menu*)
               (ui-rect (- (* 0.5 w) (* 0.12 w)) (- y (* 2 s)) (* 0.24 w) (* 11 s) '(0.8 0.3 0.05 0.8)))
             (ui-text it (floor w 2) y :scale s :align :center :color *white*)))
  (let ((help (if *capture* "PRESS THE NEW KEY OR BUTTON    ESC / START: CANCEL"
                  "UP / DOWN: ACTION    LEFT / RIGHT: COLUMN    ENTER: CHANGE    ESC: BACK"))
        (combos "SP1 = REIATSU+FLASH   SP2 = REIATSU+SIGNATURE   HOHO = REIATSU+STEP   BURST = REIATSU+QUICK   DASH = HOLD STEP   PAUSE = ESC / START"))
    (ui-text combos (floor w 2) (- h (* 34 s)) :scale (fit-scale combos s (* 0.96 w)) :align :center :color *dim*)
    (ui-text help (floor w 2) (- h (* 20 s)) :scale (fit-scale help s (* 0.96 w)) :align :center :color *ember* :shadow t)))

(defun hud-settings (w h s)
  "SETTINGS: the rows (confirm, left / right or a tap changes one), BACK, the selected row's note and the help line."
  (ui-big-text "SETTINGS" (floor w 2) (* 0.2 h) (fit-scale "SETTINGS" (* 6 s) (* 0.8 w)) '(1 0.92 0.8 1) '(0.7 0.18 0.05 1) s)
  (hud-menu (settings-items) (if (portrait-p) 0.46 0.36) w h s (/ w 2) (/ (- h (* 38 s)) h))   ; above the note (7 rows since PERFECT HINT)
  (let ((note (settings-note)) (help (if (touch-tap-zones-p) "TAP A ROW TO CHANGE IT" "LEFT / RIGHT CHANGE    ESC BACK")))
    (ui-text note (floor w 2) (- h (* 34 s)) :scale (fit-scale note s (* 0.94 w)) :align :center :color *ember* :shadow t)
    (ui-text help (floor w 2) (- h (* 20 s)) :scale (fit-scale help s (* 0.94 w)) :align :center :color *dim* :shadow t)))

(defun hud-title (w h s)
  (ui-big-text "SOUL DUEL" (floor w 2) (* 0.34 h) (* 9 s) '(1 0.92 0.8 1) '(0.7 0.18 0.05 1) s)
  (when (portrait-p)                                    ; portrait: the credit on two lines
    (when (< (mod (fx-clock) 1.2) 0.8)
      (ui-text "TAP TO START" (floor w 2) (* 0.68 h) :scale (* 2 s) :align :center :color *white* :shadow t))
    (ui-text "A FAN STUDY INSPIRED BY" (floor w 2) (- h (* 30 s)) :scale s :align :center :color '(0.93 0.93 0.96 1) :shadow t)
    (ui-text "BLEACH: REBIRTH OF SOULS" (floor w 2) (- h (* 20 s)) :scale s :align :center :color '(0.93 0.93 0.96 1) :shadow t)
    (return-from hud-title))
  (when (< (mod (fx-clock) 1.2) 0.8)
    (ui-text "PRESS START" (floor w 2) (* 0.68 h) :scale (* 2 s) :align :center :color *white* :shadow t))
  (ui-text "A FAN STUDY INSPIRED BY BLEACH: REBIRTH OF SOULS" (floor w 2) (- h (* 16 s)) :scale s :align :center
           :color '(0.93 0.93 0.96 1) :shadow t))

(defun hud-select-portrait (w h s)
  "SELECT on a tall screen: the pair above (main.lisp MENU-CAMERA), P1's and P2's pick on two rows, the CPU difficulty,
and the tap help (left / right third: choose, the middle: confirm)."
  (ui-big-text "SELECT YOUR FIGHTER" (floor w 2) (* 0.08 h) (fit-scale "SELECT YOUR FIGHTER" (* 4 s) (* 0.9 w)) *white* '(0.7 0.25 0.05 1) s)
  (dolist (e (list *p1* *p2*))
    (let* ((side (fighter-side (fighter e))) (y (* h (if (zerop side) 0.6 0.7)))
           (active (= side (min 1 *select-phase*))) (cpu (or (eq *mode* :cpu-cpu) (and (= side 1) (vs-cpu-p))))
           (name (format nil "~:[  ~;< ~]~a~:[  ~; >~]" (and active (< *select-phase* 2)) (kit-name (kit-of e)) (and active (< *select-phase* 2)))))
      (ui-text (format nil "~a~a" (if (zerop side) "P1" "P2") (if cpu " CPU" "")) (floor w 2) y :scale s :align :center
               :color (if (zerop side) '(1 0.6 0.3 1) '(0.5 0.7 1 1)) :shadow t)
      (ui-text name (floor w 2) (+ y (* 10 s)) :scale (fit-scale name (* 3 s) (* 0.94 w)) :align :center
               :color (if active *white* *dim-ink*) :shadow active)))
  (when (and (/= *select-phase* 0) (/= *select-phase* 1) (not (eq *mode* :vs-player)))
    (ui-text (format nil "~a  < ~a >" (if (eq *mode* :endless) "START" "CPU") (symbol-name *difficulty*)) (floor w 2) (* 0.82 h) :scale (* 2 s)
             :align :center :color '(1 0.85 0.3 1) :shadow t))
  (ui-text "TAP LEFT / RIGHT: CHOOSE" (floor w 2) (- h (* 30 s)) :scale s :align :center :color *white* :shadow t)
  (ui-text "TAP THE MIDDLE: CONFIRM" (floor w 2) (- h (* 20 s)) :scale s :align :center :color *white* :shadow t))

(defun hud-select (w h s)
  (when (portrait-p) (return-from hud-select (hud-select-portrait w h s)))
  (ui-big-text "SELECT YOUR FIGHTER" (floor w 2) (* 0.09 h) (* 4 s) *white* '(0.7 0.25 0.05 1) s)
  (dolist (e (list *p1* *p2*))
    (let* ((side (fighter-side (fighter e))) (x (if (zerop side) (* 0.25 w) (* 0.75 w)))
           (active (= side (min 1 *select-phase*))) (cpu (or (eq *mode* :cpu-cpu) (and (= side 1) (vs-cpu-p)))))
      (ui-text (format nil "~a~a" (if (zerop side) "P1" "P2") (if cpu " CPU" "")) x (* 0.72 h) :scale (* 2 s) :align :center
               :color (if (zerop side) '(1 0.6 0.3 1) '(0.5 0.7 1 1)) :shadow t)
      (ui-text (format nil "~:[  ~;< ~]~a~:[  ~; >~]" (and active (< *select-phase* 2)) (kit-name (kit-of e)) (and active (< *select-phase* 2)))
               x (* 0.78 h) :scale (* 3 s) :align :center :color (if active *white* *dim-ink*) :shadow active)))
  (when (and (/= *select-phase* 0) (/= *select-phase* 1) (not (eq *mode* :vs-player)))
    (let ((cam (vs-cpu-p)))                             ; VS CPU / PRACTICE: a second row, up / down picks the row
      (ui-text (format nil "~a  < ~a >" (if (eq *mode* :endless) "START" "CPU") (symbol-name *difficulty*)) (floor w 2) (* (if cam 0.85 0.88) h) :scale (* 2 s)
               :align :center :color (if (and cam (= *menu* 1)) *dim-ink* '(1 0.85 0.3 1)) :shadow (not (and cam (= *menu* 1))))
      (when cam
        (ui-text (format nil "< ~a >" (camera-label)) (floor w 2) (* 0.9 h) :scale (* 2 s)
                 :align :center :color (if (= *menu* 1) '(1 0.85 0.3 1) *dim-ink*) :shadow (= *menu* 1)))))
  (ui-text (if (and (= *select-phase* 2) (vs-cpu-p))
               "UP / DOWN ROW    LEFT / RIGHT CHOOSE    ENTER / J CONFIRM    ESC BACK"
               "LEFT / RIGHT CHOOSE    ENTER / J CONFIRM    ESC BACK")
           (floor w 2) (- h (* 12 s)) :scale s :align :center :color *white* :shadow t))

(defparameter *results-rows* '("DAMAGE" "KIKONS" "PERFECT HOHOS" "BEST COMBO" "KONPAKU LEFT"))
(defvar *results-cache* (cons nil nil) "(match-tick . strings) of the results table, made once per match.")

(defvar *results-cap* (make-bcap "勝" :layout :results) "The results screen's 勝 stamp (white on the black card).")

(defun results-strings ()
  "The results table's strings: #(winner-line p1-values p2-values time-line), cached per match."
  (let ((c *results-cache*))
    (unless (eql (car c) *match-tick*)
      (flet ((values-of (e)
               (let ((g (gauges e)))
                 (mapcar (lambda (n) (format nil "~d" n))
                         (list (gauges-dealt g) (gauges-kikons g) (gauges-perfects g) (gauges-best-combo g) (gauges-konpaku g))))))
        (bcap-restart *results-cap*)                           ; a new result: the 勝 stamps in again
        (setf (car c) *match-tick*
              (cdr c) (vector (case *winner* (0 (format nil "~a  (P1)" (kit-name (kit-of *p1*))))
                                            (1 (format nil "~a  (P2)" (kit-name (kit-of *p2*)))))
                              (values-of *p1*) (values-of *p2*)
                              (format nil "~d S" (round *match-tick* 60))))))
    (cdr c)))

(defun hud-results-portrait (w h s)
  "RESULTS on a tall screen: the winner in the top part (main.lisp MENU-CAMERA) under the 勝 stamp at the left, a black
card over the lower part with the winner's name, the stats table and the menu."
  (let* ((rs (results-strings)) (sc (max s (fit-scale "PERFECT HOHOS  00000  00000" (round (* 1.5 s)) (* 0.9 w)))) (row (* 11 sc))
         (top (* 0.42 h)) (cx (* 0.5 w)))
    (ui-rect 0 top w (- h top) '(0.031 0.031 0.047 0.94))
    (ui-rect 0 top w (max 1 (round s 2)) '(0.96 0.96 0.94 0.8))
    (if (svref rs 0)
        (let ((c *results-cap*))
          (setf (aref (bcap-f c) 6) 0.2f0)
          (draw-bcap c w h)
          (hud-text (svref rs 0) cx (+ top (* 6 s)) (fit-scale (svref rs 0) (* 2 s) (* 0.92 w)) *white* :align :center))
        (progn (set-line cx (* 0.12 h) (* 0.13 h) *white*) (setf (aref *bl* 7) (line-width "DRAW")) (brush-line "DRAW")))
    (let* ((y0 (+ top (* 16 s))) (lx (* 0.06 w)) (c2 (* 0.9 w)) (c1 (- c2 (* 30 sc))))
      (hud-text "P1" c1 y0 sc '(1 0.6 0.3 1) :align :center)
      (hud-text "P2" c2 y0 sc '(0.5 0.7 1 1) :align :center)
      (loop for label in *results-rows* for a in (svref rs 1) for b in (svref rs 2) for i from 1
            for y = (+ y0 (* i row)) do
              (when (oddp i) (ui-rect 0 (- y (* 2 s)) w (+ row (* -2 s)) '(1 1 1 0.05)))
              (hud-text label lx y sc *dim*)
              (hud-text a c1 y sc *white* :align :center)
              (hud-text b c2 y sc *white* :align :center))
      (hud-text "TIME" lx (+ y0 (* 6 row)) sc *dim*)
      (hud-text (svref rs 3) (* 0.5 (+ c1 c2)) (+ y0 (* 6 row)) sc *white* :align :center))
    (when (> *ft* 2.5) (hud-menu *results-menu* 0.8 w h s cx))))

(defun hud-results (w h s)
  "RESULTS: a panel in the left part of the screen (the winner model stays visible on the right):
WINNER + name, the stats table (P1 / P2 columns), the match time, the menu."
  (when (eq *mode* :endless) (return-from hud-results (hud-endless-results w h s)))   ; the run's results (endless.lisp)
  (when (portrait-p) (return-from hud-results (hud-results-portrait w h s)))
  (let* ((rs (results-strings)) (sc (max 1 (round (* 1.5 s)))) (row (* 11 sc))
         (px (* 0.04 w)) (pw (+ (* 28 s) (* 131 sc))) (cx (+ px (* 0.5 pw))))   ; fits "PERFECT HOHOS" + 2 columns
    (ui-rect px 0 pw h '(0.031 0.031 0.047 0.94))                ; a black card (§4.4)
    (ui-rect (+ px pw) 0 (max 1 (round s 2)) h '(0.96 0.96 0.94 0.8))
    (if (svref rs 0)
        (let ((c *results-cap*))                                 ; the big brush 勝 replaces WINNER
          (setf (aref (bcap-f c) 6) (f32 (/ cx w)))
          (draw-bcap c w h)
          (hud-text (svref rs 0) cx (* 0.29 h) (fit-scale (svref rs 0) (* 2 s) (- pw (* 8 s))) *white* :align :center))
        (progn (set-line cx (* 0.12 h) (* 0.13 h) *white*) (setf (aref *bl* 7) (line-width "DRAW")) (brush-line "DRAW")))
    (let* ((y0 (* 0.36 h)) (lx (+ px (* 10 s))) (c1 (+ px (* 18 s) (* 89 sc))) (c2 (+ c1 (* 30 sc))))
      (hud-text "P1" c1 y0 sc '(1 0.6 0.3 1) :align :center)
      (hud-text "P2" c2 y0 sc '(0.5 0.7 1 1) :align :center)
      (loop for label in *results-rows* for a in (svref rs 1) for b in (svref rs 2) for i from 1
            for y = (+ y0 (* i row)) do
              (when (oddp i) (ui-rect px (- y (* 2 s)) pw (+ row (* -2 s)) '(1 1 1 0.05)))
              (hud-text label lx y sc *dim*)
              (hud-text a c1 y sc *white* :align :center)
              (hud-text b c2 y sc *white* :align :center))
      (hud-text "TIME" lx (+ y0 (* 6 row)) sc *dim*)
      (hud-text (svref rs 3) (* 0.5 (+ c1 c2)) (+ y0 (* 6 row)) sc *white* :align :center))
    (when (> *ft* 2.5) (hud-menu *results-menu* 0.72 w h s cx))))

(defvar *c-flash* (list 1.0 1.0 1.0 0.0))

(defun aura-cap-update ()
  "Set vfx.lisp's *AURA-CAP* for the next frame: 0.5 while the fighters stand within 2.5 m, 1 from
3.5 m (two auras, or one over the other fighter, sum to a white blob up close)."
  (setf *aura-cap*
        (if (and *p1* *p2* (entity-alive-p *p1*) (entity-alive-p *p2*))
            (let* ((p (pos-of *p1*)) (q (pos-of *p2*))
                   (d (sqrt (+ (expt (- (aref p 0) (aref q 0)) 2) (expt (- (aref p 2) (aref q 2)) 2)))))
              (max 0.5 (min 1.0 (+ 0.5 (* 0.5 (- d 2.5))))))
            1.0)))

(defun hud-draw ()
  "The UI of this frame, by screen."
  (let* ((w (window-width)) (h (window-height)) (s (ui-scale)) (f *ui-flash*))
    (fill *panel-box* 0f0)                               ; HUD-SIDE sets them when the panels are drawn
    (aura-cap-update)
    (when (> (aref f 3) 0)
      (let ((c *c-flash*))
        (setf (first c) (aref f 0) (second c) (aref f 1) (third c) (aref f 2) (fourth c) (aref f 3))
        (ui-rect 0 0 w h c))
      (setf (aref f 3) (f32 (max 0.0 (- (aref f 3) (* (aref f 4) (hud-dt)))))))
    (draw-screen-fx w h)                                 ; focus lines (under the HUD)
    (when *cine*                                         ; letterbox + the cinematic's brush title
      (ui-rect 0 0 w (* 0.09 h) '(0 0 0 1)) (ui-rect 0 (* 0.91 h) w (* 0.09 h) '(0 0 0 1))
      (when *caption* (unless (draw-bcap *caption* w h) (setf *caption* nil))))
    (when *caption-out* (unless (draw-bcap *caption-out* w h) (setf *caption-out* nil)))   ; an ended cinematic's title
    (case *flow*
      (:title (hud-title w h s))
      (:mode (ui-big-text "SOUL DUEL" (floor w 2) (* 0.2 h) (fit-scale "SOUL DUEL" (* 6 s) (* 0.8 w)) '(1 0.92 0.8 1) '(0.7 0.18 0.05 1) s)
       (hud-menu *mode-menu* (if (portrait-p) 0.52 0.42) w h s))   ; portrait: lower, toward the thumb
      (:settings (hud-settings w h s))
      (:controls (if (one-hand-offered-p) (hud-gestures w h s) (hud-controls w h s)))
      (:select (hud-select w h s))
      ((:battle :finish) (unless *cine* (hud-battle w h s) (when (and *one-hand* (portrait-p) (not *paused*)) (hud-deck s))))
      (:results (hud-results w h s))
      (:clear (hud-endless-clear w h s)))
    (draw-words w h)
    (when (and *paused* (eq *flow* :battle))
      (ui-rect 0 0 w h '(0 0 0 0.55))
      (if (and *one-hand* (not (portrait-p)))
          (ui-big-text "ROTATE TO PORTRAIT" (floor w 2) (* 0.3 h) (fit-scale "ROTATE TO PORTRAIT" (* 4 s) (* 0.9 w)) *white* '(0.7 0.25 0.05 1) s)
          (ui-big-text "PAUSED" (floor w 2) (* 0.3 h) (* 5 s) *white* '(0.7 0.25 0.05 1) s))
      (hud-menu (pause-items) (if (eq *mode* :practice) 0.4 0.45) w h s (/ w 2) 0.9))   ; PRACTICE's long list: above P1's block
    (debug-hud w h s)))
