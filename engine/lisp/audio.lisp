;;;; audio.lisp — zero-asset audio: a C mixer fed by an SDL3 audio-stream callback
;;;; (engine/c/audio.c), plus a Lisp synthesis toolkit. A game describes its sounds with DEFSOUND;
;;;; the engine renders each one once at startup (one startup step per sound, see app.lisp) and
;;;; plays them with PLAY-SFX / START-LOOP / MUSIC-PLAY. See docs/AUDIO.md.
(in-package :engine)

;;; ------------------------------------------------------------------ mixer (C)
;;; The mixer runs in C between frames, never while Lisp runs, and never touches Lisp objects
;;; (GC rule): see the header of engine/c/audio.c.


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defconstant +au-rate+ 48000)
  (defconstant +au-dt+ (/ 1f0 48000)))

;;; ------------------------------------------------------------ math helpers
;;; Macros (not functions) so they always inline into typed loops unboxed.
;;; Note ECL's MIN/MAX on floats are generic calls (boxing + NaN checks) even
;;; with declared types — use AU-FMIN/AU-FMAX in sample loops.
(defmacro au-c1 (code x) `(ffi:c-inline (,x) (:float) :float ,code :one-liner t))
(defmacro au-expf (x) `(au-c1 "expf(#0)" ,x))
(defmacro au-tanf (x) `(au-c1 "tanf(#0)" ,x))
(defmacro au-tanhf (x) `(au-c1 "tanhf(#0)" ,x))
(defmacro au-frac (x) `(au-c1 "((#0)-floorf(#0))" ,x))
(defmacro au-powf (x y) `(ffi:c-inline (,x ,y) (:float :float) :float "powf(#0,#1)" :one-liner t))
(defmacro au-rnd () "White noise sample in [-1,1)." `(ffi:c-inline () () :float "au_rand()" :one-liner t))
(defmacro au-finite-p (x) `(ffi:c-inline (,x) (:float) :bool "isfinite(#0)" :one-liner t))

;; oscillators: PH is phase in cycles
(defmacro au-sin (ph) `(f-sin (* 6.2831855 ,ph)))
(defmacro au-saw (ph) `(- (* 2.0 (au-frac ,ph)) 1.0))
(defmacro au-sqr (ph) `(if (< (au-frac ,ph) 0.5) 1.0 -1.0))
(defmacro au-ph+ (ph freq) "Advance phase accumulator PH by FREQ Hz for one sample."
  `(setf ,ph (au-frac (+ ,ph (* ,freq +au-dt+)))))

;; envelopes / sweeps (TT = seconds). Non-literal args must already be
;; single-float: (FLOAT x 1.0) on a typed float still boxes in ECL.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun au-fl (x) (if (numberp x) (float x 1.0) x)))
(defmacro au-env-exp (tt decay) `(au-expf (- (/ ,tt ,decay))))
(defmacro au-ar (tt a d)
  "Linear attack A, then exponential decay with time constant D."
  (let ((u (gensym)) (av (gensym)) (dv (gensym)))
    `(let ((,u ,tt) (,av ,(au-fl a)) (,dv ,(au-fl d)))
       (declare (single-float ,u ,av ,dv))
       (if (< ,u ,av) (/ ,u ,av) (au-expf (/ (- ,av ,u) ,dv))))))
(defmacro au-adsr (tt a d s r len)
  "Linear ADSR; the note is held until LEN seconds, then released over R."
  (let ((v (loop repeat 6 collect (gensym))))
    (destructuring-bind (u av dv sv rv lv) v
      `(let ((,u ,tt) (,av ,(au-fl a)) (,dv ,(au-fl d)) (,sv ,(au-fl s))
             (,rv ,(au-fl r)) (,lv ,(au-fl len)))
         (declare (single-float ,@v))
         (cond ((< ,u ,av) (/ ,u ,av))
               ((< ,u (+ ,av ,dv)) (- 1.0 (* (- 1.0 ,sv) (/ (- ,u ,av) ,dv))))
               ((< ,u ,lv) ,sv)
               (t (* ,sv (f-max 0.0 (- 1.0 (/ (- ,u ,lv) ,rv))))))))))
(defmacro au-sweep (tt f0 f1 time)
  "Exponential glide F0 -> F1 over TIME seconds, then hold."
  `(* ,f0 (au-powf (/ ,f1 ,f0) (f-min 1.0 (/ ,tt ,time)))))

(defun au-rrange (lo hi) (+ lo (* (- hi lo) (+ 0.5 (* 0.5 (au-rnd))))))
(defun au-midi (m) (* 440.0 (expt 2.0 (/ (- m 69) 12.0))))

;;; ---------------------------------------------------------- buffer toolkit
(defun au-buf (secs)
  (make-array (max 1 (round (* secs +au-rate+))) :element-type 'single-float :initial-element 0.0))

(defmacro au-render ((buf &key (at 0.0) dur) (&rest state) &body body)
  "ADD BODY (evaluated per sample; TT = seconds since AT) into BUF from AT for DUR
seconds (default: to the end). STATE = ((var init) ...) single-float locals kept
across samples (phase accumulators, filter memories). Returns BUF."
  (let ((b (gensym)) (s0 (gensym)) (s1 (gensym)) (i (gensym)))
    `(let* ((,b ,buf)
            (,s0 (min (length ,b) (max 0 (round (* ,at +au-rate+)))))
            (,s1 ,(if dur `(min (length ,b) (+ ,s0 (round (* ,dur +au-rate+)))) `(length ,b)))
            ,@(loop for (v init) in state collect `(,v ,(au-fl init))))
       (declare (type f32vec ,b) (fixnum ,s0 ,s1) (single-float ,@(mapcar #'first state)))
       (locally (declare (optimize (speed 3) (safety 0)))
         (loop for ,i of-type fixnum from ,s0 below ,s1 do
           (let ((tt (* (i->f (the fixnum (- ,i ,s0))) +au-dt+)))
             (declare (single-float tt) (ignorable tt))
             (incf (aref ,b ,i) (the single-float (progn ,@body))))))
       ,b)))

(defun au-peak (buf)
  (declare (type f32vec buf) (optimize (speed 3) (safety 0)))
  (let ((p 0.0)) (declare (single-float p))
    (dotimes (i (length buf) p) (setf p (f-max p (f-abs (aref buf i)))))))

(defun au-scale! (buf g)
  (declare (type f32vec buf) (optimize (speed 3) (safety 0)))
  (let ((g (float g 1.0))) (declare (single-float g))
    (dotimes (i (length buf) buf) (setf (aref buf i) (* g (aref buf i))))))

(defun au-normalize! (buf &optional (peak 1.0))
  (let ((p (au-peak buf))) (if (> p 0.0) (au-scale! buf (/ peak p)) buf)))

(defun au-mix! (dst src &optional (at 0.0) (gain 1.0))
  "Add SRC*GAIN into DST at AT seconds (negative AT drops the head of SRC)."
  (declare (type f32vec dst src))
  (let ((off (round (* at +au-rate+))) (g (float gain 1.0)) (nd (length dst)) (ns (length src)))
    (declare (fixnum off nd ns) (single-float g) (optimize (speed 3) (safety 0)))
    (loop for j of-type fixnum from (max 0 (- off)) below (min ns (- nd off))
          do (let ((k (the fixnum (+ j off))))
               (setf (aref dst k) (+ (aref dst k) (* g (aref src j))))))
    dst))

(defun au-svf! (buf mode &key (from 1000.0) (to from) (q 0.707) (time 0.0))
  "In-place TPT state-variable filter (Simper). MODE :lp :bp (unity peak) :hp.
Cutoff sweeps exponentially FROM -> TO over TIME seconds (0 = whole buffer)."
  (declare (type f32vec buf))
  (let* ((n (length buf)) (f0 (float from 1.0)) (f1 (float to 1.0)) (k (/ 1.0 (float q 1.0)))
         (ratio (/ f1 f0)) (m (ecase mode (:lp 0) (:bp 1) (:hp 2)))
         (sweep-n (float (if (> time 0) (max 1 (round (* time +au-rate+))) n) 1.0))
         (s1 0.0) (s2 0.0))
    (declare (fixnum n m) (single-float f0 f1 k ratio sweep-n s1 s2)
             (optimize (speed 3) (safety 0)))
    (dotimes (i n buf)
      (let* ((fc (if (= f0 f1) f0 (* f0 (au-powf ratio (f-min 1.0 (/ (i->f i) sweep-n))))))
             (g (au-tanf (* 3.1415927 +au-dt+ (f-min fc 20000.0))))
             (a1 (/ 1.0 (+ 1.0 (* g (+ g k))))) (a2 (* g a1)) (a3 (* g a2))
             (v0 (aref buf i)) (v3 (- v0 s2))
             (v1 (+ (* a1 s1) (* a2 v3)))
             (v2 (+ s2 (* a2 s1) (* a3 v3))))
        (declare (single-float fc g a1 a2 a3 v0 v3 v1 v2))
        (setf s1 (- (* 2.0 v1) s1) s2 (- (* 2.0 v2) s2))
        (setf (aref buf i) (case m (0 v2) (1 (* k v1)) (t (- v0 (* k v1) v2))))))))

(defun au-onepole! (buf mode freq)
  "In-place 6 dB/oct :lp or :hp."
  (declare (type f32vec buf))
  (let* ((a (au-expf (* -6.2831855 (float freq 1.0) +au-dt+))) (b (- 1.0 a)) (y 0.0) (hp (eq mode :hp)))
    (declare (single-float a b y) (optimize (speed 3) (safety 0)))
    (dotimes (i (length buf) buf)
      (let ((x (aref buf i)))
        (setf y (+ (* b x) (* a y)))
        (setf (aref buf i) (if hp (- x y) y))))))

(defun au-drive! (buf amount)
  "Normalize, then tanh waveshape: AMOUNT 1 = gentle, 5+ = crushed."
  (declare (type f32vec buf))
  (au-normalize! buf)
  (let* ((a (float amount 1.0)) (k (/ 1.0 (au-tanhf a))))
    (declare (single-float a k) (optimize (speed 3) (safety 0)))
    (dotimes (i (length buf) buf)
      (setf (aref buf i) (* k (au-tanhf (* a (aref buf i))))))))

(defun au-delay! (buf secs fb mix)
  "In-place feedback delay (echo)."
  (declare (type f32vec buf))
  (let* ((d (max 1 (round (* secs +au-rate+))))
         (line (make-array d :element-type 'single-float :initial-element 0.0))
         (fb (float fb 1.0)) (mix (float mix 1.0)) (j 0))
    (declare (fixnum d j) (single-float fb mix) (type f32vec line) (optimize (speed 3) (safety 0)))
    (dotimes (i (length buf) buf)
      (let ((y (aref line j)) (x (aref buf i)))
        (setf (aref line j) (+ x (* fb y)) (aref buf i) (+ x (* mix y)))
        (incf j) (when (>= j d) (setf j 0))))))

(defun au-reverb! (buf mix &key (size 1.0) (damp 0.3) (fb 0.8))
  "Schroeder/Freeverb-style reverb: 4 damped combs -> 2 allpasses, added at MIX."
  (declare (type f32vec buf))
  (let* ((n (length buf)) (wet (make-array n :element-type 'single-float :initial-element 0.0))
         (damp (float damp 1.0)) (fb (float fb 1.0)))
    (declare (fixnum n) (type f32vec wet) (single-float damp fb))
    (dolist (len '(1214 1293 1389 1475))
      (let ((l (max 1 (round (* len size)))) (j 0) (store 0.0))
        (declare (fixnum l j) (single-float store))
        (let ((line (make-array l :element-type 'single-float :initial-element 0.0)))
          (declare (type f32vec line) (optimize (speed 3) (safety 0)))
          (dotimes (i n)
            (let ((y (aref line j)))
              (setf store (+ (* y (- 1.0 damp)) (* store damp)))
              (setf (aref line j) (+ (aref buf i) (* store fb)))
              (setf (aref wet i) (+ (aref wet i) (* 0.25 y)))
              (incf j) (when (>= j l) (setf j 0)))))))
    (dolist (len '(605 480))
      (let* ((l (max 1 (round (* len size)))) (j 0)
             (line (make-array l :element-type 'single-float :initial-element 0.0)))
        (declare (fixnum l j) (type f32vec line) (optimize (speed 3) (safety 0)))
        (dotimes (i n)
          (let* ((x (aref wet i)) (y (aref line j)))
            (setf (aref line j) (+ x (* 0.5 y)) (aref wet i) (- y x))
            (incf j) (when (>= j l) (setf j 0))))))
    (au-mix! buf wet 0.0 mix)))

(defun au-fold (buf n &optional xfade)
  "Make a seamless loop of N samples: everything rendered past N (drum tails,
reverb) is added onto the head; with XFADE the tail is equal-power crossfaded
instead (for stationary noise)."
  (declare (type f32vec buf) (fixnum n))
  (let ((out (subseq buf 0 n)) (tl (- (length buf) n)))
    (declare (type f32vec out) (fixnum tl))
    (dotimes (i (min tl n) out)
      (let ((x (aref buf (+ n i))))
        (if xfade
            (let ((u (/ (float i 1.0) tl)))
              (setf (aref out i) (+ (* (sqrt u) (aref out i)) (* (sqrt (- 1.0 u)) x))))
            (incf (aref out i) x))))))

;;; --------------------------------------------------------- sound elements
(defun au-noise (secs &key (attack 0.002) (hold 0.0) (decay 0.1))
  "Fresh buffer: white noise under attack / hold / exponential decay."
  (let ((a (float attack 1.0)) (h (float hold 1.0)) (d (float decay 1.0)))
    (declare (single-float a h d))
    (au-render ((au-buf secs)) ()
      (* (au-rnd) (cond ((< tt a) (/ tt a)) ((< tt (+ a h)) 1.0) (t (au-expf (/ (- (+ a h) tt) d))))))))

(defun au-fnoise (secs mode from &key (to from) (q 0.707) (attack 0.002) (hold 0.0) (decay 0.1))
  "Filtered noise burst, normalized to peak 1."
  (au-normalize! (au-svf! (au-noise secs :attack attack :hold hold :decay decay) mode :from from :to to :q q)))

(defun au-whoosh (secs f0 f1 &key (q 1.2) (peak 0.3))
  "Air movement: band-passed noise sweeping F0 -> F1, swelling until PEAK secs."
  (let ((p (float peak 1.0)) (s (float secs 1.0)))
    (declare (single-float p s))
    (au-normalize!
     (au-svf! (au-render ((au-buf secs)) ()
                (* (au-rnd) (if (< tt p) (let ((u (/ tt p))) (* u u))
                                (let ((u (f-max 0.0 (/ (- s tt) (- s p))))) (* u u u)))))
              :bp :from f0 :to f1 :q q))))

(defun au-ping! (buf at freq decay gain &key (attack 0.001) (glide 1.0))
  "Sine partial with exponential decay; GLIDE = pitch ratio reached after DECAY."
  (let ((f (float freq 1.0)) (d (float decay 1.0)) (g (float gain 1.0)) (a (float attack 1.0)) (gl (float glide 1.0)))
    (declare (single-float f d g a gl))
    (au-render (buf :at at :dur (+ a (* 7 d))) ((ph 0.0))
      (au-ph+ ph (if (= gl 1.0) f (* f (au-powf gl (f-min 1.0 (/ tt d))))))
      (* g (au-ar tt a d) (au-sin ph)))))

(defun au-partials! (buf at partials &key (glide 1.0))
  "PARTIALS = ((freq amp decay) ...) — bells, blades, metal."
  (loop for (f a d) in partials do (au-ping! buf at f d a :glide glide))
  buf)

(defun au-thump! (buf at f0 f1 sweep decay gain)
  "Pitch-dropping sine: kicks, body impacts, booms."
  (let ((f0 (float f0 1.0)) (f1 (float f1 1.0)) (sw (float sweep 1.0)) (d (float decay 1.0)) (g (float gain 1.0)))
    (declare (single-float f0 f1 sw d g))
    (au-render (buf :at at :dur (* 7 d)) ((ph 0.0))
      (au-ph+ ph (au-sweep tt f0 f1 sw))
      (* g (au-ar tt 0.002 d) (au-sin ph)))))

(defun au-taiko! (buf at gain &optional (f 80.0))
  (au-thump! buf at (* f 1.5) f 0.03 0.35 gain)
  (au-ping! buf at (* f 2.31) 0.1 (* 0.3 gain))
  (au-mix! buf (au-onepole! (au-noise 0.1 :decay 0.012) :lp 1800) at (* 0.5 gain)))

(defun au-gong! (buf at f0 gain &optional (len 1.0))
  (au-partials! buf at (loop for r in '(1.0 1.51 2.07 2.62 3.2 4.1 5.3)
                             for a in '(1.0 0.8 0.65 0.5 0.4 0.3 0.2)
                             for d in '(2.0 1.5 1.1 0.8 0.6 0.45 0.3)
                             collect (list (* f0 r) (* a gain) (* d len)))
                :glide 0.985)
  (au-mix! buf (au-fnoise 0.1 :lp 900 :decay 0.02) at (* 0.3 gain)))

(defun au-shaku! (buf at dur freq gain &key (vib 0.012))
  "Shakuhachi-ish breathy note: scoop up into pitch, delayed vibrato, breath chiff."
  (let* ((f (float freq 1.0)) (d (float dur 1.0)) (v (float vib 1.0)) (len (+ d 0.25))
         (tone (au-buf len)))
    (declare (single-float f d v))
    (au-render (tone) ((ph 0.0))
      (let* ((bend (if (< tt 0.08) (+ 0.944 (* 0.056 (/ tt 0.08))) 1.0))
             (vd (* v (f-min 1.0 (/ tt 0.6))))
             (fr (* f bend (+ 1.0 (* vd (au-sin (* 5.2 tt)))))))
        (declare (single-float bend vd fr))
        (au-ph+ ph fr)
        (* (au-adsr tt 0.07 0.15 0.8 0.2 d)
           (+ (au-sin ph) (* 0.22 (au-sin (* 2.0 ph))) (* 0.07 (au-sin (* 3.0 ph)))))))
    (let ((br (au-render ((au-buf len)) () (* (au-rnd) (au-adsr tt 0.03 0.15 0.3 0.2 d)))))
      (au-svf! br :bp :from (* 2 f) :q 1.5)
      (au-mix! tone br 0.0 0.45))
    (au-mix! buf tone at gain)))

(defun au-saws! (buf at dur freqs gain &key (a 0.3) (r 0.6))
  "Detuned saw pad/drone over FREQS."
  (let ((d (float dur 1.0)) (g (/ (float gain 1.0) (length freqs))) (a (float a 1.0)) (r (float r 1.0)))
    (declare (single-float d g a r))
    (dolist (f0 freqs buf)
      (dolist (det '(0.996 1.004))
        (let ((f (* (float f0 1.0) det)))
          (declare (single-float f))
          (au-render (buf :at at :dur (+ d r)) ((ph (+ 0.5 (* 0.5 (au-rnd)))))
            (au-ph+ ph f)
            (* g (au-adsr tt a 0.1 1.0 r d) (au-saw ph))))))))

;;; ------------------------------------------------------------- sound bank
(defvar *au-defs* nil "((key peak loop-p fn) ...) in definition order")
(defconstant +au-slots+ 128 "Sound slots in the C mixer (AU_NS, engine/c/audio.c).")

(defmacro defsound (key (&key (peak 0.9) loop) &body body)
  "Define how to synthesize sound KEY (BODY returns a sample buffer, see AU-BUF / AU-RENDER); the
result is normalized to PEAK. LOOP: a seamless loop (rain, music). Sounds are synthesized at
startup in definition order."
  (let ((fn (intern (format nil "AU-SND-~a" key))))
    `(progn (defun ,fn () ,@body)
            (setf *au-defs* (append (remove ,key *au-defs* :key #'first)
                                    (list (list ,key ,peak ,loop ',fn))))
            (when (> (length *au-defs*) +au-slots+)
              (error "DEFSOUND ~s: more than ~d sounds (the mixer's slot count)" ,key +au-slots+)))))

;;; --------------------------------------------------------------- Lisp API
(defvar *audio-debug* nil "When true, AUDIO-INIT logs per-sound stats.")
(defun list-sounds ()
  "Keys of every DEFSOUND, in definition order (= synthesis order)."
  (mapcar #'first *au-defs*))
(defun sound-loop-p (key) "T if sound KEY was defined with :LOOP (music, ambience)." (third (assoc key *au-defs*)))
(defvar *au-ok* nil)
(defvar *au-index* (make-hash-table :test 'eq) "sound key -> C slot")
(defvar *au-music* -1)

(defun au-ticks () (ffi:c-inline () () :int "(int)SDL_GetTicks()" :one-liner t))

(defun au-sanitize! (buf)
  "Zero NaN/Inf samples; return how many there were."
  (declare (type f32vec buf))
  (let ((bad 0)) (declare (fixnum bad))
    (dotimes (i (length buf) bad)
      (unless (au-finite-p (aref buf i)) (setf (aref buf i) 0.0) (incf bad)))))

(defun au-finish! (buf)
  "One-shots: remove DC (15 Hz HP) and fade the last 5 ms to avoid end clicks."
  (declare (type f32vec buf))
  (au-onepole! buf :hp 15)
  (let* ((n (length buf)) (f (min n 240)))
    (dotimes (i f buf)
      (setf (aref buf (- n 1 i)) (* (aref buf (- n 1 i)) (/ (float i 1.0) f))))))

(defun au-moments (buf)
  "Sum and sum of squares of BUF's samples (doubles; unboxed loop, conses only the two results)."
  (declare (type f32vec buf) (optimize (speed 3) (safety 0)))
  (let ((sum 0d0) (sq 0d0))
    (declare (double-float sum sq))
    (dotimes (i (length buf) (values sum sq))
      (let ((x (ffi:c-inline ((aref buf i)) (:float) :double "(double)(#0)" :one-liner t)))   ; FLOAT boxes here
        (declare (double-float x)) (incf sum x) (incf sq (* x x))))))

(defun au-stats (key buf bad)
  (declare (type f32vec buf))
  (multiple-value-bind (sum sq) (au-moments buf)
   (let ((n (length buf)) (pk (au-peak buf)))
    (let ((dc (/ sum n)) (ms (round (* 1000 n) +au-rate+)))
      (log-msg "audio: ~15a ~5d ms  peak ~5,3f  rms ~5,3f  dc ~8,5f  nan/inf ~d~a" key ms pk
               (sqrt (/ sq n)) dc bad
               (if (or (> bad 0) (> pk 1.0) (> (abs dc) 0.01) (< ms 20)) "  <-- BAD" ""))))))

(defvar *au-t0* 0)
(defvar *au-total* 0)

(defun audio-init-begin ()
  "Open the device. T if the sound bank can be synthesized (then AUDIO-INIT-SOUND each index)."
  (handler-case
      (progn (setf *au-t0* (au-ticks) *au-total* 0)
             (ffi:c-inline () () :bool "au_open()" :one-liner t))
    (error (e) (log-msg "audio: init failed: ~a" e) nil)))

(defun audio-init-sound (idx)
  "Synthesize and upload sound IDX of *AU-DEFS* (one step; its temporaries become garbage)."
  (handler-case
      (destructuring-bind (key peak loop fn) (nth idx *au-defs*)
        (let* ((buf (funcall fn)) (bad (au-sanitize! buf)))
          (declare (type f32vec buf))
          (unless loop (au-finish! buf))
          (au-normalize! buf peak)
          (when *audio-debug* (au-stats key buf bad))
          (ffi:c-inline (idx buf (length buf)) (:int t :int) :void
                        "au_load(#0, #1->vector.self.sf, #2)" :one-liner t)
          (incf *au-total* (length buf))
          (setf (gethash key *au-index*) idx)))
    (error (e) (log-msg "audio: sound ~d failed: ~a" idx e) nil)))

(defun audio-init-end ()
  (ffi:c-inline () () :void "au_resume()" :one-liner t)
  (when *audio-debug*
    (log-msg "audio: ~d sounds, ~,1f MB samples, synthesized in ~d ms"
             (length *au-defs*) (/ (* 4 *au-total*) 1048576.0) (- (au-ticks) *au-t0*)))
  (setf *au-ok* t))

(defun au-play (idx gain pan pitch loop bus)
  (ffi:c-inline ((the fixnum idx) (float gain 1.0) (float pan 1.0) (float pitch 1.0) loop bus)
                (:int :float :float :float :int :int) :int
                "au_play(#0,#1,#2,#3,#4,#5)" :one-liner t))

(defun play-sfx (key &key (gain 1.0) (pitch 1.0) (pan 0.0) (pitch-jitter 0.05))
  "Play sound KEY once. Returns a voice id, or -1 (unknown key / no audio)."
  (let ((idx (and *au-ok* (gethash key *au-index*))))
    (if idx
        (au-play idx gain pan (* pitch (+ 1.0 (* pitch-jitter (au-rnd)))) 0 0)
        -1)))

(defun play-sfx-at (key x y z listener-x listener-z listener-yaw &rest keys)
  "Positional PLAY-SFX. Yaw rotates about +Y; yaw 0 looks down -Z with +X on the
right. Gain falls off as 1/(1+d/8); pan follows the listener's right vector."
  (declare (ignore y))
  (let* ((dx (- x listener-x)) (dz (- z listener-z)) (d (sqrt (+ (* dx dx) (* dz dz))))
         (pan (if (< d 0.01) 0.0
                  (* 0.8 (/ (- (* dx (cos listener-yaw)) (* dz (sin listener-yaw))) d))))
         (gain (/ (getf keys :gain 1.0) (+ 1.0 (/ d 8.0)))))
    (apply #'play-sfx key :gain gain :pan pan keys)))

(defun sfx-at (key x y z &key (gain 1.0) (pitch 1.0))
  "PLAY-SFX-AT with the camera as the listener: KEY sounds from (X Y Z) as heard from *CAMERA*
(e.g. every in-world sound of a third-person game)."
  (let ((c (camera-pos *camera*)) (f (camera-forward *camera*)))
    (play-sfx-at key x y z (aref c 0) (aref c 2) (atan (- (aref f 0)) (- (aref f 2))) :gain gain :pitch pitch)))

(defun start-loop (key &key (gain 1.0))
  "Start looping sound KEY (e.g. :rain) on the sfx bus. Returns id for STOP-LOOP."
  (let ((idx (and *au-ok* (gethash key *au-index*))))
    (if idx (au-play idx gain 0.0 1.0 1 0) -1)))

(defun stop-loop (id &optional (fade 0.15))
  "Fade out and stop voice ID over FADE seconds (works for one-shots too)."
  (ffi:c-inline ((the fixnum id) (max 1 (round (* fade +au-rate+)))) (:int :int) :void
                "au_stop(#0,#1)" :one-liner t))

(defun set-loop-gain (id g)
  "Change the gain of running loop voice ID (from START-LOOP) without restarting it."
  (ffi:c-inline ((the fixnum id) (float g 1.0)) (:int :float) :void "au_gain(#0,#1)" :one-liner t))

(defun set-music-volume (v)
  "Music bus gain, 0..2 (default 0.55). ponytail: master / sfx bus gains stay at 1 (C defaults)."
  (ffi:c-inline ((float (clamp v 0.0 2.0) 1.0)) (:float) :void "au_set_volume(2,#0)" :one-liner t))

(defun music-playing-p ()
  (ffi:c-inline ((the fixnum *au-music*)) (:int) :bool "au_alive(#0)" :one-liner t))

(defun music-play (&optional (key :music))
  "Start looping sound KEY (a DEFSOUND :loop t) on the music bus; no-op while music is playing.
One track plays at a time: to switch tracks, MUSIC-STOP first."
  (let ((idx (and *au-ok* (gethash key *au-index*))))
    (when (and idx (not (music-playing-p)))
      (setf *au-music* (au-play idx 1.0 0.0 1.0 1 1)))
    *au-music*))

(defun music-stop (&optional (fade 1.0))
  (stop-loop *au-music* fade)
  (setf *au-music* -1))

(defun music-intensify (&optional (key :music))
  "Intensify the music (e.g. a boss's second phase): restart track KEY a little faster and higher
(the one cheap layer we have)."
  (let ((idx (and *au-ok* (gethash key *au-index*))))
    (when idx
      (music-stop 0.4)
      (set-music-volume 0.7)
      (setf *au-music* (au-play idx 1.0 0.0 1.12 1 1)))))

(defun audio-stats ()
  "Debug: (values active-voices frames-mixed peak-since-last-call context-state)
context-state: 0 none, 1 suspended (autoplay), 2 running."
  (values (ffi:c-inline () () :int "au_active()" :one-liner t)
          (ffi:c-inline () () :int "au_frames_mixed()" :one-liner t)
          (ffi:c-inline () () :float "au_take_peak()" :one-liner t)
          (ffi:c-inline () () :int "au_ctx_state()" :one-liner t)))

(defun audio-locked-p ()
  "T while the browser keeps the AudioContext suspended (no user gesture yet): show a click hint."
  (and *au-ok* (= 1 (ffi:c-inline () () :int "au_ctx_state()" :one-liner t))))
