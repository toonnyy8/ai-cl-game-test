;;;; hud.lisp — the battle HUD (design-v1 §10) and every screen of the flow (title, mode, controls,
;;;; select, results, pause). Per side, P2 mirrored: Reishi bar (red + pulsing below *RED-THRESHOLD*,
;;;; white damage trail), the guard gauge under it (steel, a white drain trail, 30 % darker while he guards below full
;;;; (GUARD HOLD: no refill); Bankai's is ember, flashing white when fed, "HIT TO FEED" once; guardless: grey with a red
;;;; fill climbing back), *KONPAKU-MAX* Konpaku soul flames that shatter, Reiatsu 3 bars, the flash-step bar
;;;; (ticks at a Hoho's and a Burst's cost; the Burst part glows while a Burst is possible), Awakening bar (EVOLUTION
;;;; blinks; drains in a timed awakening; BURNOUT while a stance is burned out, the name dimmed), the kit meter
;;;; (Inferno; drains in Hellfire) or, for an awakened form with cooldown commands, the L / Shift+L cooldown bars
;;;; (a refused press flashes its bar), the timer, the
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
(defvar *feed-hint* (vector nil nil) "Per side: \"HIT TO FEED\" was shown this match (once).")
(defun clear-words () (setf *words* nil (svref *feed-hint* 0) nil (svref *feed-hint* 1) nil))

(defun announce (text &key sub (color *white*) (secs 1.0) small side)
  "Show TEXT big in the middle (SMALL: smaller, upper lane; SIDE 0 / 1: over that side's panel),
with SUB under it."
  (let ((wd (make-word text sub color secs small side)))
    (setf (first (word-col wd)) (f32 (first color)) (second (word-col wd)) (f32 (second color))
          (third (word-col wd)) (f32 (third color)))
    (setf *words* (cons wd (remove-if (lambda (w) (and (not (word-side w)) (eq (word-small w) small))) *words*)))))

(defun word-layout (x w h)
  "Word X on a W x H screen. Values: centre x, the caps' middle y, the brush em in px (the pop-in shrinks it over
the first 0.08 s; a long word shrinks to 92 % of the width)."
  (let* ((k (min 1.0 (/ (- (fx-clock) (word-t0 x)) 0.08)))
         (em (* h (cond ((word-side x) 0.05) ((word-small x) 0.085) (t (* 0.13 (+ 1.0 (* 0.5 (- 1 k)))))))))
    (values (case (word-side x) (0 (* 0.2 w)) (1 (* 0.8 w)) (t (* 0.5 w)))
            (if (or (word-side x) (word-small x)) (* 0.3 h) (* 0.45 h))
            (min em (/ (* 0.92 w) (max 0.1 (line-width (word-text x))))))))

(defun word-box (x w h)
  "Screen box of word X (text + sub). Values: x0 y0 x1 y1."
  (multiple-value-bind (cx cy em) (word-layout x w h)
    (let ((hw (* 0.5 em (line-width (word-text x)))))
      (values (- cx hw) (- cy (* 0.45 em)) (+ cx hw) (+ cy (if (word-sub x) (* 1.05 em) (* 0.45 em)))))))

(defun draw-words (w h)
  "The big words (ANNOUNCE) in brush Latin, fading out over their last 0.25 s."
  (setf *words* (delete-if (lambda (x) (> (- (fx-clock) (word-t0 x)) (word-secs x))) *words*))
  (dolist (x *words*)
    (let* ((age (- (fx-clock) (word-t0 x)))
           (fade (min 1.0 (/ (- (word-secs x) age) 0.25))) (col (word-col x)))
      (multiple-value-bind (cx cy em) (word-layout x w h)
        (set-line cx cy em col fade) (setf (aref *bl* 7) (line-width (word-text x))) (brush-line (word-text x))
        (when (word-sub x)
          (let ((se (max (* 0.032 h) (* 0.36 em))))
            (set-line cx (+ cy (* 0.55 em) (* 0.5 se)) se col fade) (setf (aref *bl* 7) (line-width (word-sub x)))
            (brush-line (word-sub x))))))))

;;; ---------------------------------------------------------------- side panels: the meters
(declaim (type f32vec *trail-v* *gg-seen* *pip-t* *hud-v*))
(defvar *trail-v* (make-f32 4) "Damage trail per side (fraction): [side] Reishi, [2 + side] the guard gauge.")
(defvar *gg-seen* (make-f32 4) "Per side: [side] the guard gauge the HUD saw last frame, [2 + side] when it was last fed (FX-CLOCK).")
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

(defun-fast %gg-seen! (gs side gg tm fed)
  "The HUD's view of SIDE's guard gauge GG (GS = *GG-SEEN*): a FED gauge (Bankai) that rose since last frame was fed
at TM (the bar's white flash)."
  (declare (type f32vec gs) (fixnum side) (single-float gg tm))
  (when (and fed (> gg (+ (aref gs side) 0.01f0))) (setf (aref gs (+ 2 side)) tm))
  (setf (aref gs side) gg)
  nil)

(defun-fast %hud-guard (x y bw bh frac trail right guardless mode gs side tm)
  "The guard gauge: dark back, white drain TRAIL, the fill by MODE: 0 steel, 1 steel 30 % darker (he guards below
full: GUARD HOLD, no refill), 2 ember (Bankai: the fed flame), flashing white for 0.1 s after a feed (GS = *GG-SEEN*,
SIDE); GUARDLESS: a grey bar whose red fill climbs back (pulsing) until it is full and he can guard again (Bankai:
it REIGNITEs)."
  (declare (single-float x y bw bh frac trail tm) (fixnum mode side) (type f32vec gs))
  (let* ((p (%pulse tm 3.0)) (k (if (= mode 1) 0.7f0 1f0)) (em (= mode 2))
         (flash (if em (f-max 0f0 (- 1f0 (* 10f0 (- tm (aref gs (+ 2 side)))))) 0f0))
         (r0 (* k (if em 1f0 0.84f0))) (g0 (* k (if em 0.62f0 0.88f0))) (b0 (* k (if em 0.25f0 0.94f0)))
         (r1 (* k (if em 0.78f0 0.48f0))) (g1 (* k (if em 0.24f0 0.55f0))) (b1 (* k (if em 0.06f0 0.66f0))))
    (declare (single-float p k flash r0 g0 b0 r1 g1 b1))
    (%hrect x y bw bh 0.05f0 0.04f0 0.07f0 0.75f0)
    (if guardless
        (progn (%hrect x y bw bh 0.32f0 0.32f0 0.35f0 0.9f0)
               (%hbar x y bw bh frac right 0.9f0 0.12f0 0.15f0 (+ 0.6f0 (* 0.4f0 p)) 0.6f0 0.02f0 0.05f0 (+ 0.6f0 (* 0.4f0 p))))
        (progn (%hbar x y bw bh trail right 1f0 1f0 1f0 0.95f0)
               (%hbar x y bw bh frac right (+ r0 (* flash (- 1f0 r0))) (+ g0 (* flash (- 1f0 g0))) (+ b0 (* flash (- 1f0 b0))) 1f0
                      (+ r1 (* flash (- 1f0 r1))) (+ g1 (* flash (- 1f0 g1))) (+ b1 (* flash (- 1f0 b1))) 1f0)))))

(defun-fast %hud-flash (x y w h fill right burst tm)
  "The flash-step bar: dark back, a steel-blue FILL (0..1), white ticks at a Hoho's and a Burst's cost;
while a Burst is possible (BURST) the part past the Burst tick glows."
  (declare (single-float x y w h fill tm))
  (let* ((hk (/ (the single-float (f32 *fs-hoho*)) (the single-float (f32 *fs-max*))))
         (bk (/ (the single-float (f32 *fs-burst*)) (the single-float (f32 *fs-max*))))
         (p (%pulse tm 4.0)))
    (declare (single-float hk bk p))
    (%hrect x y w h 0.05f0 0.04f0 0.07f0 0.75f0)
    (%hbar x y w h fill right 0.55f0 0.75f0 1f0 1f0 0.25f0 0.45f0 0.8f0 1f0)
    (when (and burst (> fill bk))
      (let* ((sw (* w (- fill bk))) (sx (if right (+ x (- w fill)) (+ x (* w bk)))))
        (declare (single-float sw sx))
        (%hrect sx (- y 1f0) sw (+ h 2f0) 0.85f0 0.95f0 1f0 (+ 0.5f0 (* 0.5f0 p)))))
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

(defun-fast %hud-pips (x py bw r side n right red tm)
  "The Konpaku: N intact soul flames (blue; red when RED), shattering ones (0.6 s of shards after
PIPS-SHATTER), and dim embers for the lost ones."
  (declare (single-float x py bw r tm) (fixnum side n))
  (let* ((pt *pip-t*) (p (%pulse tm 2.0)))
    (declare (type f32vec pt) (single-float p))
    (dotimes (i *konpaku-max*)
      (let* ((fi (i->f i)) (d (* (+ fi 0.5f0) 3.2f0 r)) (cx (if right (- (+ x bw) d) (+ x d)))
             (j (+ (* side *konpaku-max*) i)) (t0 (aref pt j)) (u (/ (- tm t0) 0.6f0))
             (lean (* 0.3f0 r (f-sin (+ (* 7f0 tm) (* 1.7f0 fi))))))
        (declare (single-float fi d cx t0 u lean) (fixnum j))
        (cond ((< i n)
               (setf (aref pt j) 0f0)
               (if red
                   (%soul-flame cx py r lean 1f0 0.5f0 0.5f0 (* 0.5f0 (+ 0.7f0 (* 0.3f0 p))) 1f0 0.15f0 0.2f0 (+ 0.7f0 (* 0.3f0 p)))
                   (%soul-flame cx py r lean 0.75f0 0.95f0 1f0 0.45f0 0.35f0 0.7f0 1f0 1f0)))
              ((and (> t0 0f0) (< u 1f0))                      ; shattering: 4 shards fly apart
               (dotimes (k 4)
                 (let* ((a (* (i->f k) 1.5707964f0)) (sx (+ cx (* 14f0 (/ r 4.5f0) u (f-cos a))))
                        (sy (+ py (* 14f0 (/ r 4.5f0) u (f-sin a)))) (sr (* r 0.4f0 (- 1f0 u))))
                   (declare (single-float a sx sy sr))
                   (%hq sx (- sy (* 1.6f0 sr)) (+ sx sr) sy sx (+ sy sr) (- sx sr) sy
                        0.8f0 0.95f0 1f0 (- 1f0 u)))))
              (t (%soul-flame cx py (* 0.5f0 r) 0f0 0.3f0 0.3f0 0.35f0 0.3f0 0.3f0 0.3f0 0.35f0 0.6f0)))))))

(defun-fast %hud-reiatsu (x y sw sh gap ra right)
  "Reiatsu: 3 bars of *REIATSU-BAR* each (full ones bright), from the panel's outer edge."
  (declare (single-float x y sw sh gap ra))
  (let* ((bar (the single-float (f32 *reiatsu-bar*))))
    (declare (single-float bar))
    (dotimes (i 3)
      (let* ((fi (i->f i)) (bx (if right (- x (* (+ fi 1f0) (+ sw gap))) (+ x (* fi (+ sw gap)))))
             (fill (f-clamp (/ (- ra (* fi bar)) bar) 0f0 1f0)))
        (declare (single-float fi bx fill))
        (%hrect bx y sw sh 0.05f0 0.04f0 0.07f0 0.75f0)
        (if (>= fill 1f0)
            (%hbar bx y sw sh fill right 0.6f0 0.92f0 1f0 1f0 0.25f0 0.65f0 1f0 1f0)
            (%hbar bx y sw sh fill right 0.2f0 0.45f0 0.7f0 1f0))))))

(declaim (type f32vec *refused-t*))
(defvar *refused-t* (make-f32 4) "Per side x (L, Shift+L): FX-CLOCK of the last refused press (its bar flashes).")
(defparameter *cd-commands* '(:sig :sp2) "The commands whose cooldown the panel shows (L's switch, Shift+L).")

(defun hud-refused (e cmd)
  "E pressed CMD while it was cooling (the :refused event): its cooldown bar flashes."
  (let ((i (position cmd *cd-commands*)))
    (when i (setf (aref *refused-t* (+ (* 2 (fighter-side (fighter e))) i)) (f32 (fx-clock))))))

(defun-fast %hud-cd (x y w h fill flash right r g b)
  "One cooldown bar: dark back, the FILL (1 = ready) bright in (R G B) when ready, dim while cooling; FLASH (0..1)
washes it white (a refused press)."
  (declare (single-float x y w h fill flash r g b))
  (let* ((k (if (>= fill 1f0) 1f0 0.45f0)))
    (declare (single-float k))
    (%hrect x y w h 0.05f0 0.04f0 0.07f0 0.75f0)
    (%hbar x y w h fill right (* k r) (* k g) (* k b) 1f0)
    (when (> flash 0f0) (%hrect x (- y 1f0) w (+ h 2f0) 1f0 1f0 1f0 flash))))

(defun-fast %hud-thin (x y w h fill right r g b a0 hz tm)
  "A thin gauge (Awakening, the kit meter): dark back, FILL in (R G B), alpha A0, pulsing up to 1
at HZ when HZ > 0."
  (declare (single-float x y w h fill r g b a0 hz tm))
  (let* ((a (if (> hz 0f0) (+ a0 (* (- 1f0 a0) (+ 0.5f0 (* 0.5f0 (f-sin (* 6.2831855f0 hz tm)))))) a0)))
    (declare (single-float a))
    (%hrect x y w h 0.05f0 0.04f0 0.07f0 0.75f0)
    (%hbar x y w h fill right r g b a)))

;;; ---------------------------------------------------------------- side panels: per-kit strings
(defvar *kit-hud* (make-hash-table :test 'eq) "KIT -> #(label meter u-tag): the panel name, the kit meter, U's tag.")

(defun kit-hud (kit)
  "The cached HUD data of KIT: the name label (\"YAMAMOTO  BANKAI\"), the kit meter (inherited
from the base form when this form has none) and the tag of what a U that guards adds (\"U: GARB\", \"U: DRINK\": U is
a guard in every form, two forms' guards do more)."
  (or (gethash kit *kit-hud*)
      (setf (gethash kit *kit-hud*)
            (vector (format nil "~a~@[  ~a~]" (kit-name kit) (and (not (eq (kit-form kit) :base)) (kit-form-name kit)))
                    (or (kit-meter kit) (kit-meter (find-kit (kit-character kit) :base)))
                    (cond ((member :garb (kit-passives kit)) "U: GARB") ((member :drink (kit-passives kit)) "U: DRINK"))))))

;;; combo counter: per victim side, the last combo with dealt damage (knockdown zeroes the running
;;; total, so the counter keeps the last non-zero one) and its string, rebuilt when it changes
(defstruct (combo-show (:conc-name cs-)) (hits 0) (dmg 0) (t0 -10.0) (str ""))
(defvar *combo-show* (vector (make-combo-show) (make-combo-show)))

(defun combo-string (c hits dmg)
  (unless (and (= hits (cs-hits c)) (= dmg (cs-dmg c)))
    (setf (cs-hits c) hits (cs-dmg c) dmg (cs-str c) (format nil "~d HITS  ~d" hits dmg)))
  (setf (cs-t0 c) (fx-clock))
  c)

(defvar *c-evo* (list 1.0 0.85 0.3 1.0))
(defvar *u-tag* (list 1.0 0.72 0.35 1.0))
(defvar *c-kikon* (list 1.0 0.2 0.25 1.0))
(defvar *c-burst* (list 0.5 0.75 1.0 1.0))
(defvar *c-callout* (list 1.0 0.85 0.55 1.0))

(defun hud-side (e w h s)
  (let* ((f (fighter e)) (g (gauges e)) (kit (fighter-kit f)) (kh (kit-hud kit)) (side (fighter-side f)) (right (= side 1))
         (m (* 0.03 w)) (bw (* 0.36 w)) (x (if right (- w m bw) m)) (edge (if right (+ x bw) x))
         (align (if right :right :left)) (y (* 0.05 h)) (bh (max (* 7 s) (* 0.028 h)))
         (ns (max 2 s)) (tm (fx-clock))
         (frac (/ (gauges-reishi g) (float (gauges-reishi-max g)))) (red (red-p (gauges-reishi g) (gauges-reishi-max g))))
    ;; name + form (dimmed while the stance is burned out)
    (hud-text (svref kh 0) edge (- y (* 8 ns) s) ns (cond ((burnout-p e) '(0.5 0.52 0.58 1)) ((kit-awakening kit) *ember*) (t *white*))
              :align align)
    ;; Reishi + trail
    (let ((tr (aref *trail-v* side)))
      (setf (aref *trail-v* side) (f32 (if (> tr frac) (max frac (- tr (* 0.35 (hud-dt)))) frac)))
      (%hud-reishi (f32 x) (f32 y) (f32 bw) (f32 bh) (f32 frac) (aref *trail-v* side) right red tm))
    ;; the guard gauge, right under it
    (let* ((gf (/ (gauges-gg g) *gg-max*)) (ti (+ 2 side)) (tr (aref *trail-v* ti)) (fed (kit-burnout kit)))
      (setf (aref *trail-v* ti) (f32 (if (> tr gf) (max gf (- tr (* 0.5 (hud-dt)))) gf)))
      (%gg-seen! *gg-seen* side (gauges-gg g) tm (and fed (not (gauges-guardless g))))   ; fed: the white flash
      (when (and fed (not (svref *feed-hint* side)) (not (gauges-guardless g)) (< gf 0.5))   ; once a match
        (setf (svref *feed-hint* side) t)
        (announce "HIT TO FEED" :color '(1 0.55 0.2 1) :secs 1.2 :small t :side side))
      (%hud-guard (f32 x) (f32 (+ y bh (* 2 s))) (f32 bw) (f32 (max (* 3 s) (* 0.3 bh))) (f32 gf) (aref *trail-v* ti)
                  right (gauges-guardless g)
                  (cond (fed 2) ((and (member (fighter-state f) '(:guard :guard-hit)) (< gf 1.0)) 1) (t 0))
                  *gg-seen* side tm))
    ;; Konpaku soul flames
    (%hud-pips (f32 x) (f32 (+ y bh (* 16 s))) (f32 bw) (f32 (max (* 4.5 s) (* 0.013 h))) side (gauges-konpaku g) right red tm)
    ;; Reiatsu: 3 bars + label
    (let* ((sy (+ y bh (* 25 s))) (sw (* 0.075 w)) (sh (max (* 3 s) (* 0.011 h))) (gap (* 3 s)) (row (* 11 s))
           (lx (if right (- edge (* 3 (+ sw gap)) (* 3 s)) (+ edge (* 3 (+ sw gap)) (* 3 s)))))
      (%hud-reiatsu (f32 edge) (f32 sy) (f32 sw) (f32 sh) (f32 gap) (gauges-reiatsu g) right)
      (hud-text "REIATSU" lx (- (+ sy (* 0.5 sh)) (* 3.5 s)) s '(0.45 0.8 1 0.9) :align align)
      ;; flash-step (Hoho, Burst), Awakening (drains during a timed awakening), the kit meter (Inferno; drains in its form)
      (let* ((fy (+ sy row)) (ay (+ fy row)) (aw (+ (* 3 sw) (* 6 s))) (ah (max (* 3 s) (* 0.009 h))) (ty (- (* 0.5 ah) (* 3.5 s)))
             (ax (if right (- edge aw) x)) (lx (if right (- edge aw (* 6 s)) (+ edge aw (* 6 s))))
             (timed (and (kit-awakening kit) (plusp (gauges-form-total g))))
             (hot (or (gauges-evolution g) (kit-awakening kit)))
             (afill (cond (timed (timer-fill (gauges-form-left g) (gauges-form-total g) 1.0))
                          ((kit-awakening kit) 1.0) (t (/ (gauges-awaken g) *awaken-max*)))))
        (%hud-flash (f32 ax) (f32 fy) (f32 aw) (f32 ah) (f32 (/ (gauges-fs g) *fs-max*)) right (burst-ok-p e) tm)
        (hud-text "FLASH STEP" lx (+ fy ty) s '(0.6 0.78 1 0.9) :align align)
        (%hud-thin (f32 ax) (f32 ay) (f32 aw) (f32 ah) (f32 afill) right 1f0 (if hot 0.85f0 0.75f0) 0.3f0
                   (if hot 0.6f0 1f0) (if hot 4f0 0f0) tm)
        (cond ((gauges-evolution g)
               (hud-text "EVOLUTION" lx (+ ay ty) s (alpha! *c-evo* (hud-pulse 3.0)) :align align))
              ((burnout-p e) (hud-text "BURNOUT" lx (+ ay ty) s '(0.62 0.64 0.7 1) :align align))
              ((svref kh 2) (hud-text (svref kh 2) lx (+ ay ty) s *u-tag* :align align))   ; what this form's guard adds
              ((kit-awakening kit) (hud-text (kit-form-name kit) lx (+ ay ty) s *ember* :align align))
              (t (hud-text "AWAKEN" lx (+ ay ty) s '(0.95 0.8 0.4 0.9) :align align)))
        (let ((l (kit-command-move kit :sig)) (sp (kit-command-move kit :sp2)))   ; the L / Shift+L cooldowns
          (when (and (kit-awakening kit) (plusp (mv-cooldown l)))
            (let* ((my (+ ay row)) (hw (* 0.5 (- aw (* 2 s)))) (cd (fighter-cd f)) (o (* 2 side))
                   (fl (max 0.0 (- 1.0 (* 4.0 (- tm (aref *refused-t* o))))))
                   (fs (max 0.0 (- 1.0 (* 4.0 (- tm (aref *refused-t* (1+ o))))))))
              (%hud-cd (f32 (if right (+ ax hw (* 2 s)) ax)) (f32 my) (f32 hw) (f32 ah)
                       (f32 (- 1.0 (/ (aref cd (position :sig *kit-commands*)) (float (mv-cooldown l))))) (f32 fl) right
                       0.84f0 0.88f0 0.94f0)
              (%hud-cd (f32 (if right ax (+ ax hw (* 2 s)))) (f32 my) (f32 hw) (f32 ah)
                       (f32 (- 1.0 (/ (aref cd (position :sp2 *kit-commands*)) (float (max 1 (mv-cooldown sp)))))) (f32 fs) right
                       1f0 0.45f0 0.15f0)
              (hud-text "COOLDOWN" lx (+ my ty) s '(0.84 0.88 0.94 0.9) :align align))))
        (let ((meter (svref kh 1)))
          (when (getf meter :ladder)                    ; NOME: the cup ladder (Nozarashi), yellow
            (let* ((ladder (getf meter :ladder)) (rung (or (position (kit-form kit) ladder :key #'first) 0))
                   (mx (getf meter :max)))
              (%hud-nome (f32 ax) (f32 (+ ay row)) (f32 aw) (f32 ah) (f32 (/ (gauges-meter g) mx)) right rung
                         (f32 (/ (fifth (nth rung ladder)) mx)) tm)
              (hud-text (getf meter :name) lx (+ ay row ty) s '(1 0.85 0.3 0.95) :align align)))
          (when (and meter (not (kit-awakening kit)))
            (let* ((my (+ ay row)) (burning (plusp (gauges-form-left g)))
                   (mfill (if burning
                              (timer-fill (gauges-form-left g) (gauges-form-total g) 1.0)
                              (/ (gauges-meter g) (getf meter :max)))))
              (%hud-thin (f32 ax) (f32 my) (f32 aw) (f32 ah) (f32 mfill) right 1f0 (if burning 0.4f0 0.45f0) (if burning 0.1f0 0.12f0)
                         (if burning 0.7f0 1f0) (if burning 5f0 0f0) tm)
              (hud-text (getf meter :name) lx (+ my ty) s '(1 0.55 0.25 0.9) :align align))))))
    ;; combo counter under this side's bar (this side is the victim): the last total that dealt damage
    (let ((c (svref *combo-show* side)))
      (when (and (> (fighter-combo-hits f) 1) (plusp (fighter-combo-dmg f)))
        (combo-string c (fighter-combo-hits f) (fighter-combo-dmg f)))
      (when (< (- tm (cs-t0 c)) 1.2)
        (hud-text (cs-str c) edge (+ y bh (* 62 s)) (* 2 s) '(1 0.9 0.6 1) :align align)))
    ;; KIKON / BURST prompts for a human
    (when (and (not (brain e)) (member *flow* '(:battle)))
      (cond ((kikon-ready-p e)                            ; the opponent is red: the rush, held, Kiko's
             (hud-text (if (pad-connected-p side) "HOLD RT  KIKON" (if right "HOLD KP6  KIKON" "HOLD O  KIKON"))
                       (if right (* 0.75 w) (* 0.25 w)) (* 0.78 h) (* 3 s) (alpha! *c-kikon* (+ 0.5 (* 0.5 (hud-pulse 4.0))))
                       :align :center))
            ((burst-ok-p e)
             (hud-text (if (pad-connected-p side) "LT+X  BURST" (if right "KP ENTER+KP1  BURST" "SHIFT+J  BURST"))
                       (if right (* 0.75 w) (* 0.25 w)) (* 0.78 h) (* 2 s) (alpha! *c-burst* (+ 0.5 (* 0.5 (hud-pulse 4.0))))
                       :align :center))))))

;;; ---------------------------------------------------------------- over the fighters
(defvar *callout-box* (vector nil 0 0 0 0) "The callout drawn first this frame: #(drawn x0 y0 x1 y1).")

(defun boxes-overlap-p (ax0 ay0 ax1 ay1 bx0 by0 bx1 by1)
  (and (< ax0 bx1) (< bx0 ax1) (< ay0 by1) (< by0 ay1)))

(defun callout-y (x0 y0 x1 y1 w h s)
  "Top edge for a callout box (X0 Y0 X1 Y1) that steps out of the big words' boxes and the other
callout: above the box it hits, or below it when above would reach the side panels."
  (let ((th (- y1 y0)) (gap (* 4 s)))
    (flet ((dodge (bx0 by0 bx1 by1)
             (when (boxes-overlap-p x0 y0 x1 y1 bx0 by0 bx1 by1)
               (let ((up (- by0 gap th)))
                 (setf y0 (if (>= up (* 0.22 h)) up (+ by1 gap)) y1 (+ y0 th))))))
      (dolist (wd *words*)
        (multiple-value-bind (bx0 by0 bx1 by1) (word-box wd w h) (dodge bx0 by0 bx1 by1)))
      (let ((cb *callout-box*))
        (when (svref cb 0) (dodge (svref cb 1) (svref cb 2) (svref cb 3) (svref cb 4)))))
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
      (let* ((str (fighter-callout f)) (em (* 0.045 h)) (tw (round (* em (line-width str)))) (th (round (* 0.8 em)))
             (x0 (round (- (aref v 0) (* 0.5 tw)))) (y0 (callout-y x0 (round (aref v 1)) (+ x0 tw) (+ (round (aref v 1)) th) w h s))
             (cb *callout-box*))
        (setf (svref cb 0) t (svref cb 1) x0 (svref cb 2) (round y0) (svref cb 3) (+ x0 tw) (svref cb 4) (+ (round y0) th))
        (set-line (+ x0 (* 0.5 tw)) (+ y0 (* 0.5 th)) em *c-callout* (min 1.0 (/ (fighter-callout-t f) 20.0)))
        (setf (aref *bl* 7) (line-width str))
        (brush-line str)))
    (when (red-p (gauges-reishi g) (gauges-reishi-max g))
      (vfx-soul-flame (aref p 0) top (aref p 2) (fx-clock)))))

(defvar *timer-strings* (make-array 1000 :initial-element nil) "Seconds -> their string, made once.")

(declaim (type f32vec *hud-v2*))
(defvar *hud-v2* (make-f32 3))

(defun hud-rush-lines (e)
  "Speed lines along a Kikon rush's dash-in (RUSH-DASHING-P in its :follow phase), on the screen direction
from the rusher to his victim."
  (let ((f (fighter e)))
    (when (and (eq (fighter-state f) :move) (eq (fighter-phase f) :follow) (rush-dashing-p f))
      (let ((p (pos-of e)) (a *hud-v*) (b *hud-v2*))
        (when (and (world-to-screen a (aref p 0) 1f0 (aref p 2)) (world-to-screen b (fighter-ox f) 1f0 (fighter-oz f)))
          (ui-speed-lines (f32 (atan (- (aref b 1) (aref a 1)) (- (aref b 0) (aref a 0)))) 14 '(1 1 1 0.55)
                          (f->i (* 12f0 (fx-clock)))))))))

(defun hud-battle (w h s)
  (setf (svref *callout-box* 0) nil)
  (dolist (e (list *p1* *p2*)) (when (entity-alive-p e) (hud-rush-lines e)))
  (dolist (e (list *p1* *p2*)) (when (entity-alive-p e) (hud-side e w h s) (hud-world e w h s)))
  (let* ((secs (min 999 (ceiling (max 0 *timer*) 60)))
         (str (or (svref *timer-strings* secs) (setf (svref *timer-strings* secs) (format nil "~d" secs)))))
    (ui-big-text str (floor w 2) (* 0.07 h) (* 4 s) (if (< secs 30) '(1 0.3 0.3 1) *white*) '(0 0 0 0.7) s :shear 0.0)))

;;; ---------------------------------------------------------------- screens
(defun hud-menu (items y0 w h s &optional (cx (/ w 2)))
  "Vertical menu centred on CX from Y0 (fraction of H); *MENU* is highlighted."
  (let ((sc (* 2 s)) (dy (* 22 s)))
    (loop for it in items for i from 0 do
      (let* ((sel (= i *menu*)) (y (+ (* h y0) (* i dy))) (tw (text-width it sc)))
        (when sel
          (ui-gradient (- cx (* 0.5 tw) (* 14 s)) (- y (* 3 s)) (+ tw (* 28 s)) (+ (* 7 sc) (* 6 s))
                       '(0.8 0.3 0.05 0.0) '(0.8 0.3 0.05 0.8) :vertical nil))
        (ui-text it (round cx) y :scale sc :align :center :color (if sel *white* '(0.8 0.78 0.85 1)) :shadow t)))))

(defparameter *controls-text*
  '(("MOVE" "W A S D" "ARROWS") ("QUICK" "J" "KP1") ("FLASH" "K" "KP2") ("SIGNATURE" "L" "KP3")
    ("GUARD" "U" "KP4") ("BREAKER" "I" "KP5") ("KIKON RUSH (HOLD = KIKON)" "O" "KP6") ("STEP" "SPACE" "KP0")
    ("REIATSU (HOLD)" "LSHIFT" "KP ENTER") ("AWAKEN" "P" "KP +") ("SP1 / SP2" "SHIFT+K / SHIFT+L" "")
    ("HOHO" "SHIFT+SPACE" "") ("BURST REVERSE" "SHIFT+J" "") ("DASH" "HOLD SPACE" "HOLD KP0") ("PAUSE" "ESC" "")))

(defun hud-controls (w h s)
  (ui-rect 0 0 w h '(0 0 0 0.7))
  (ui-big-text "CONTROLS" (floor w 2) (* 0.1 h) (* 4 s) *white* '(0.7 0.25 0.05 1) s)
  (loop for (a p1 p2) in *controls-text* for i from 0
        for y = (+ (* 0.2 h) (* i 14 s)) do
          (ui-text a (* 0.3 w) y :scale s :align :right :color *dim*)
          (ui-text p1 (* 0.36 w) y :scale s :color *white*)
          (ui-text p2 (* 0.62 w) y :scale s :color *white*))
  (ui-text "P1: KEYBOARD LEFT + PAD 1      P2: ARROWS + NUMPAD + PAD 2      PAD: X Y B = Q F SIG, LB GUARD, RB BREAKER, RT KIKON, A STEP (HOLD = DASH), LT MOD, LT+X BURST"
           (floor w 2) (* 0.9 h) :scale 1 :align :center :color *dim*))

(defun hud-title (w h s)
  (ui-big-text "SOUL DUEL" (floor w 2) (* 0.34 h) (* 9 s) '(1 0.92 0.8 1) '(0.7 0.18 0.05 1) s)
  (ui-text "YAMAMOTO GENRYUSAI  VS  ZARAKI KENPACHI" (floor w 2) (* 0.46 h) :scale (* 2 s) :align :center :color *ember* :shadow t)
  (when (< (mod (fx-clock) 1.2) 0.8)
    (ui-text "PRESS START" (floor w 2) (* 0.68 h) :scale (* 2 s) :align :center :color *white* :shadow t))
  (ui-text "A FAN STUDY INSPIRED BY BLEACH: REBIRTH OF SOULS" (floor w 2) (- h (* 16 s)) :scale s :align :center
           :color '(0.93 0.93 0.96 1) :shadow t))

(defun hud-select (w h s)
  (ui-big-text "SELECT YOUR FIGHTER" (floor w 2) (* 0.09 h) (* 4 s) *white* '(0.7 0.25 0.05 1) s)
  (dolist (e (list *p1* *p2*))
    (let* ((side (fighter-side (fighter e))) (x (if (zerop side) (* 0.25 w) (* 0.75 w)))
           (active (= side (min 1 *select-phase*))) (cpu (or (eq *mode* :cpu-cpu) (and (= side 1) (eq *mode* :vs-cpu)))))
      (ui-text (format nil "~a~a" (if (zerop side) "P1" "P2") (if cpu " CPU" "")) x (* 0.72 h) :scale (* 2 s) :align :center
               :color (if (zerop side) '(1 0.6 0.3 1) '(0.5 0.7 1 1)) :shadow t)
      (ui-text (format nil "~:[  ~;< ~]~a~:[  ~; >~]" (and active (< *select-phase* 2)) (kit-name (kit-of e)) (and active (< *select-phase* 2)))
               x (* 0.78 h) :scale (* 3 s) :align :center :color (if active *white* *dim-ink*) :shadow active)))
  (when (and (/= *select-phase* 0) (/= *select-phase* 1) (not (eq *mode* :vs-player)))
    (let ((cam (eq *mode* :vs-cpu)))                    ; VS CPU: a second row, up / down picks the row
      (ui-text (format nil "CPU  < ~a >" (symbol-name *difficulty*)) (floor w 2) (* (if cam 0.85 0.88) h) :scale (* 2 s)
               :align :center :color (if (and cam (= *menu* 1)) *dim-ink* '(1 0.85 0.3 1)) :shadow (not (and cam (= *menu* 1))))
      (when cam
        (ui-text (format nil "< ~a >" (camera-label)) (floor w 2) (* 0.9 h) :scale (* 2 s)
                 :align :center :color (if (= *menu* 1) '(1 0.85 0.3 1) *dim-ink*) :shadow (= *menu* 1)))))
  (ui-text (if (and (= *select-phase* 2) (eq *mode* :vs-cpu))
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

(defun hud-results (w h s)
  "RESULTS: a panel in the left part of the screen (the winner model stays visible on the right):
WINNER + name, the stats table (P1 / P2 columns), the match time, the menu."
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
    (aura-cap-update)
    (when (> (aref f 3) 0)
      (let ((c *c-flash*))
        (setf (first c) (aref f 0) (second c) (aref f 1) (third c) (aref f 2) (fourth c) (aref f 3))
        (ui-rect 0 0 w h c))
      (setf (aref f 3) (f32 (max 0.0 (- (aref f 3) (* (aref f 4) (hud-dt)))))))
    (draw-screen-fx w h)                                 ; focus lines (under the HUD)
    (when *cine*                                         ; letterbox + the cinematic's brush title
      (ui-rect 0 0 w (* 0.09 h) '(0 0 0 1)) (ui-rect 0 (* 0.91 h) w (* 0.09 h) '(0 0 0 1))
      (when *caption* (draw-bcap *caption* w h)))
    (case *flow*
      (:title (hud-title w h s))
      (:mode (ui-big-text "SOUL DUEL" (floor w 2) (* 0.2 h) (* 6 s) '(1 0.92 0.8 1) '(0.7 0.18 0.05 1) s)
       (hud-menu *mode-menu* 0.42 w h s))
      (:controls (hud-controls w h s))
      (:select (hud-select w h s))
      ((:battle :finish) (unless *cine* (hud-battle w h s)))
      (:results (hud-results w h s)))
    (draw-words w h)
    (when (and *paused* (eq *flow* :battle))
      (ui-rect 0 0 w h '(0 0 0 0.55))
      (ui-big-text "PAUSED" (floor w 2) (* 0.3 h) (* 5 s) *white* '(0.7 0.25 0.05 1) s)
      (hud-menu (pause-items) 0.45 w h s))
    (debug-hud w h s)))
