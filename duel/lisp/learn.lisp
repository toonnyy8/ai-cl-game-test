;;;; learn.lisp — the learning CPU's pure part (docs/duel/DUEL_LEARNING.md; the user, 2026-09-29). Plain CL, host-tested
;;;; (tests/learn-test.lisp); ai.lisp feeds it what the CPU perceives and asks it what to do. Character-free: the tables
;;;; are keyed by situations, action classes, distance bins and command keywords, never by a name.
;;;;   player model  per SITUATION (9), counts of the human's next ACTION CLASS (10): order 0, and order 1 keyed by his
;;;;                 previous class in that situation; decayed x*LEARN-DECAY* per observation (habits change);
;;;;                 LEARN-PREDICT blends order 1 into order 0 (backoff), LEARN-COUNTER answers the prediction
;;;;                 (防 > J > I > 防, DUEL_STRINGS §14)
;;;;   bandit        per CONTEXT (its form x its kit meter's third: 24), distance bin (5) and neutral command (10), a
;;;;                 discounted EXP3 score; the kit's :moves weight x exp(score) (LEARN-MULT), rewarded with the damage
;;;;                 balance of the next *LEARN-WINDOW* frames
;;;;   bursts        per burst colour (3) a use / don't two-armed EXP3: the base AI's chance re-weighted (LEARN-BURST-P)
;;;;   form          the human's recent results in [-1, 1]; LEARN-P-EXPLOIT reads him more when he wins, less when he loses
;;;;   storage       LEARN-ENCODE / LEARN-DECODE: a table as a short list of integers (the page keeps them, pwa.js)
(in-package :duel)

(defparameter *learn-situations* #(:wake :knock :h-blocked :c-blocked :whiff :c-hit :close :mid :far)
  "What just happened, seen from the CPU about the human: he wakes up / we wake up (his oki) / he blocked / we blocked
his string / his move whiffed / our string hit him (will he burst out?); else neutral by distance (LEARN-BAND). The first
+LEARN-EVENTS+ are events.")
(defconstant +learn-events+ 6 "Situations below this index are events (a counter is planned at their onset).")
(defparameter *learn-actions* #(:guard :j :k :i :hoho :back :l :sp :o :burst)
  "The human's coarse action classes: guard, J (Quick), K (Flash), I (Breaker, the grab), Hoho / Step, backing off, L
(Signature), SP (SP1 / SP2), O (Kikon rush), a burst (Shift+J, any colour). In :c-hit, a timeout (he took the string)
counts as guard.")
(defparameter *learn-arms* #(:q :f :sig :sp1 :sp2 :breaker :kikon :step :hoho nil)
  "The neutral commands a kit's :moves bands weigh (NIL = wait): the bandit's arms.")
(defparameter *learn-bins* #(1.6 3.0 5.0 7.0) "Bandit distance bins: their upper bounds, m (5 bins, the last open).")
(defparameter *learn-bands* #(2.5 5.0) "Neutral situations :close / :mid / :far: upper bounds, m.")
(defparameter *learn-counters*
  '((:guard :breaker) (:j :guard) (:k :q) (:i :q) (:hoho :hoho-punish) (:back nil) (:l :guard) (:sp :hoho) (:o :guard)
    (:burst :dash-in))
  "The answer to each predicted class: I beats guard, guard beats J, J beats K and I, a Hoho is not fed (the CPU waits)
and punished where he reappears (:hoho-punish, a reaction through the perception delay), a Signature / the rush guarded,
an SP stepped through. Backing off has none (chasing him paid off 5 % of the time in the gate: the kit's own ranges do
better). A burst in neutral (WHITE: he regenerates) is rushed (:dash-in).")
(defparameter *learn-sit-counters* '((:c-hit (:burst :bait) (:guard nil)))
  "Per situation, answers overriding *LEARN-COUNTERS*: while our string hits him, a predicted burst is baited (:bait: the
string ends after its second hit, then a guard: his BLUE breaks nothing), taking it goes on as usual.")

(defparameter *learn-decay* 0.97 "Counts x this per observation of their row (a habit fades in ~30 of them).")
(defparameter *learn-backoff* 2.0 "Pseudo-count of order 0 blended into an order-1 row.")
(defparameter *learn-min-n* 1.5 "Order-0 evidence needed before a prediction counts (two sightings).")
(defparameter *learn-confident* 0.4 "A prediction's probability needed to act on it.")
(defparameter *learn-eta* 0.15 "EXP3 step.")
(defparameter *learn-gamma* 0.98 "EXP3 discount of a bin's scores per update (the human adapts back).")
(defparameter *learn-s-max* (log 4.0) "Scores clamp here: a weight x 1/4 .. 4.")
(defparameter *learn-p-floor* 0.05 "An arm's probability floor in the importance weight.")
(defparameter *learn-window* 90 "Frames of damage balance a neutral pick is rewarded with.")
(defparameter *learn-norm* 150.0 "Damage that counts as a reward of 1.")
(defparameter *learn-p-exploit* '(:mid 0.35 :slope 0.4 :lo 0.15 :hi 0.6)
  "p_exploit = mid + slope x form, clamped to lo .. hi.")
(defparameter *learn-form-k* 0.05 "Form's EMA weight per *LEARN-FORM-T* frames of damage balance.")
(defparameter *learn-form-t* 120 "Frames per form sample.")
(defparameter *learn-form-match* 0.2 "Form's EMA weight of a match result (win +1, loss -1, draw 0).")
(defparameter *learn-episode* '(:event 75 :neutral 60) "Frames an episode waits for the human's action.")
(defparameter *learn-back* 1.2 "Metres the human moves away within an episode: :back.")
(defparameter *learn-cap* 400 "At most this many order-1 cells are saved (the largest).")
(defparameter *learn-arm-cap* 300 "At most this many bandit scores are saved (the largest in size).")
(defparameter *learn-burst-colors* #(:white :blue :orange) "The burst bandits' colours (BURST-MODE's).")

(defconstant +learn-s+ 9) (defconstant +learn-a+ 10) (defconstant +learn-arms+ 10) (defconstant +learn-nbins+ 5)
(defconstant +learn-forms+ 8 "Bandit contexts: a character's forms, in definition order (the rest share the last).")
(defconstant +learn-meters+ 3 "... x its kit meter in thirds.")
(defconstant +learn-ctx+ (* +learn-forms+ +learn-meters+))
(defconstant +learn-rows+ (* +learn-ctx+ +learn-nbins+) "Bandit rows: context x distance bin.")

(defstruct (ltab (:constructor make-ltab ()))
  "One CPU character's learned tables (docs/duel/DUEL_LEARNING.md)."
  (c0 (make-array (* +learn-s+ +learn-a+) :element-type 'single-float :initial-element 0f0))
  (c1 (make-array (* +learn-s+ +learn-a+ +learn-a+) :element-type 'single-float :initial-element 0f0))
  (prev (make-array +learn-s+ :element-type 'fixnum :initial-element -1))   ; his last class per situation
  (arms (make-array (* +learn-rows+ +learn-arms+) :element-type 'single-float :initial-element 0f0))
  (bursts (make-array 6 :element-type 'single-float :initial-element 0f0))   ; colour x (use, don't)
  (form 0f0 :type single-float))

(defun learn-sit (key) (position key *learn-situations*))
(defun learn-act (key) (position key *learn-actions*))
(defun learn-band (d) "Neutral situation index for distance D." (+ +learn-events+ (or (position-if (lambda (b) (< d b)) *learn-bands*) 2)))
(defun learn-bin (d) "Bandit bin for distance D." (or (position-if (lambda (b) (< d b)) *learn-bins*) 4))
(defun learn-clamp (x lo hi) (max lo (min hi x)))
(defun learn-ctx (form-i meter) "Bandit context for form index FORM-I and kit meter fraction METER (0..1)."
  (+ (* (min (1- +learn-forms+) (max 0 form-i)) +learn-meters+) (min (1- +learn-meters+) (floor (* +learn-meters+ (learn-clamp meter 0.0 1.0))))))
(defun learn-row (ctx bin) "The bandit row of context CTX and distance bin BIN." (+ (* ctx +learn-nbins+) bin))

;;; ---------------------------------------------------------------- the player model
(defun learn-observe! (tab sit act)
  "The human did class ACT (index) in situation SIT (index): decay the rows, count it, remember it as his last there."
  (let ((c0 (ltab-c0 tab)) (c1 (ltab-c1 tab)) (prev (aref (ltab-prev tab) sit)) (d (float *learn-decay* 1f0)))
    (flet ((bump (v base) (dotimes (a +learn-a+) (setf (aref v (+ base a)) (* d (aref v (+ base a)))))
             (incf (aref v (+ base act)) 1f0)))
      (bump c0 (* sit +learn-a+))
      (when (>= prev 0) (bump c1 (* (+ (* sit +learn-a+) prev) +learn-a+))))
    (setf (aref (ltab-prev tab) sit) act)
    tab))

(defun learn-dist (tab sit)
  "The human's next class in SIT as a probability vector (order 1 given his last class there, backed off to order 0 with
*LEARN-BACKOFF* pseudo-counts), and the order-0 evidence. Values: vector (or NIL without evidence), n0."
  (let* ((c0 (ltab-c0 tab)) (c1 (ltab-c1 tab)) (b0 (* sit +learn-a+)) (prev (aref (ltab-prev tab) sit))
         (b1 (and (>= prev 0) (* (+ b0 prev) +learn-a+)))
         (n0 (loop for a below +learn-a+ sum (aref c0 (+ b0 a))))
         (n1 (if b1 (loop for a below +learn-a+ sum (aref c1 (+ b1 a))) 0f0)))
    (if (<= n0 0f0)
        (values nil 0f0)
        (let ((p (make-array +learn-a+ :element-type 'single-float)) (k (float *learn-backoff* 1f0)))
          (dotimes (a +learn-a+ (values p n0))
            (let ((q0 (/ (aref c0 (+ b0 a)) n0)))
              (setf (aref p a) (if (plusp n1) (/ (+ (aref c1 (+ b1 a)) (* k q0)) (+ n1 k)) q0))))))))

(defun learn-predict (tab sit)
  "The human's most likely next class in SIT: values class index (NIL = no evidence), its probability, the evidence."
  (multiple-value-bind (p n) (learn-dist tab sit)
    (if (null p)
        (values nil 0f0 n)
        (let ((best (loop with b = 0 for a from 1 below +learn-a+ when (> (aref p a) (aref p b)) do (setf b a) finally (return b))))
          (values best (aref p best) n)))))

(defun learn-confident-p (p n) "Act on a prediction of probability P from evidence N?" (and (>= n *learn-min-n*) (>= p *learn-confident*)))

(defun learn-counter (act &optional sit)
  "The command answering class index ACT (in situation index SIT: *LEARN-SIT-COUNTERS* first, else *LEARN-COUNTERS*)."
  (let* ((k (aref *learn-actions* act)) (o (and sit (cdr (assoc (aref *learn-situations* sit) *learn-sit-counters*)))))
    (second (or (assoc k o) (assoc k *learn-counters*)))))

(defun learn-onset (hprev hs hcontact own-prev own open d &optional burst-open)
  "Which situation begins this step (index), or NIL. HPREV / HS: the human's perceived state last step / now (HCONTACT:
what his move last step touched, NIL = a whiff), OWN-PREV / OWN: ours, BURST-OPEN: our string's hit just made his burst
possible (its 2nd hit, his flash-step enough), OPEN: the episode open (-1 none), D: the perceived distance. Events override an open neutral episode; a neutral one opens when
none is open and both are free."
  (flet ((free (st) (member st '(:idle :guard :run))))
    (cond ((and (eq hs :wakeup) (not (eq hprev :wakeup))) 0)
          ((and (eq own :wakeup) (not (eq own-prev :wakeup))) 1)
          ((and (eq hprev :guard-hit) (not (eq hs :guard-hit))) 2)
          ((and (eq own-prev :guard-hit) (not (eq own :guard-hit))) 3)
          ((and (eq hprev :move) (null hcontact) (not (eq hs :move))) 4)
          ((and burst-open (/= open 5)) 5)
          ((and (< open 0) (free hs) (free own)) (learn-band d)))))

(defun learn-kind-class (kind)
  "A move kind's action class keyword (NIL: not one the model counts)."
  (case kind (:quick :j) (:flash :k) (:breaker :i) (:sig :l) (:sp :sp) (:kikon :o)))

(defun learn-action (hprev hs kind new-start away &optional burst)
  "The human's action class index starting this step, or NIL: a burst begun (BURST), a move (from a free state, or a new
link: NEW-START) by its KIND, a guard raised, a Hoho / Step, or AWAY metres backed off within the episode."
  (let ((k (cond (burst :burst)
                 ((and (eq hs :move) (or (not (eq hprev :move)) new-start)) (learn-kind-class kind))
                 ((and (eq hs :guard) (not (eq hprev :guard))) :guard)
                 ((and (member hs '(:hoho :step)) (not (eq hprev hs))) :hoho)
                 ((> away *learn-back*) :back))))
    (and k (learn-act k))))

(defun learn-episode (sit) "Frames situation SIT's episode waits." (getf *learn-episode* (if (< sit +learn-events+) :event :neutral)))

;;; ---------------------------------------------------------------- the bandit
(defun learn-mult (tab row arm) "The weight factor of arm index ARM in bandit ROW (LEARN-ROW)." (exp (aref (ltab-arms tab) (+ (* row +learn-arms+) arm))))

(defun %exp3! (v base n arm prob r)
  "Discounted EXP3 on the N scores of V from BASE: every one x *LEARN-GAMMA*, then ARM (picked with probability PROB) +
eta r / prob, clamped to +-*LEARN-S-MAX*."
  (let ((m (float *learn-s-max* 1f0)))
    (dotimes (a n) (setf (aref v (+ base a)) (* (float *learn-gamma* 1f0) (aref v (+ base a)))))
    (setf (aref v (+ base arm))
          (learn-clamp (float (+ (aref v (+ base arm)) (/ (* *learn-eta* r) (max prob *learn-p-floor*))) 1f0) (- m) m))))

(defun learn-reward! (tab row arm prob r)
  "The bandit's update of ROW: arm ARM picked with probability PROB earned R in [-1, 1] (%EXP3!)."
  (%exp3! (ltab-arms tab) (* row +learn-arms+) +learn-arms+ arm prob r)
  tab)

(defun learn-burst-p (tab color p)
  "The base AI's chance P of a burst of COLOR (index in *LEARN-BURST-COLORS*) re-weighted by that colour's use / don't
scores: p e^u / (p e^u + (1 - p) e^n)."
  (let ((u (* p (exp (aref (ltab-bursts tab) (* 2 color))))) (n (* (- 1 p) (exp (aref (ltab-bursts tab) (1+ (* 2 color)))))))
    (if (plusp (+ u n)) (/ u (+ u n)) 0.0)))

(defun learn-burst-reward! (tab color used prob r)
  "COLOR's bandit: USED (or not), that branch taken with probability PROB, earned R."
  (%exp3! (ltab-bursts tab) (* 2 color) 2 (if used 0 1) prob r)
  tab)

(defun learn-reward (dealt taken &optional (healed 0)) "Damage DEALT minus TAKEN (plus Reishi HEALED) in a window, as a reward in [-1, 1]."
  (learn-clamp (/ (+ (- dealt taken) healed) *learn-norm*) -1.0 1.0))

;;; ---------------------------------------------------------------- how much it reads
(defun learn-p-exploit (form)
  "The chance a decision takes the model's counter, for the human's FORM (-1 losing .. 1 winning): *LEARN-P-EXPLOIT*."
  (let ((c *learn-p-exploit*))
    (learn-clamp (+ (getf c :mid) (* (getf c :slope) form)) (getf c :lo) (getf c :hi))))

(defun learn-form-after (form r k) "FORM moved toward R (in [-1, 1]) by K." (float (learn-clamp (+ (* (- 1 k) form) (* k r)) -1.0 1.0) 1f0))

(defun learn-rnd (state)
  "The learner's own random stream (never SIM-RND01: a CPU without it draws exactly as before): values [0, 1), next state."
  (let ((s (mod (+ (* state 1103515245) 12345) 2147483648)))
    (values (/ (float (ash s -7)) 16777216.0) s)))

;;; ---------------------------------------------------------------- storage (pwa.js soulduel.learn.<roster index>)
;;; One integer per entry: index x 65536 + value + 32768. Format 2: index 0-89 order 0 (x10), 100-999 order 1 (x10),
;;; 1000-2199 the bandit scores (x1000), 2300-2308 the last class per situation (+1), 2400-2405 the burst scores (x1000),
;;; 2950 the form (x1000), 2999 the format version (2). Format 1 (999 = 1; 8 situations, 9 classes, 5 x 10 scores) is
;;; read into format 2: the model and the form carried over, the old bandit dropped (it relearns within a match).
(defun learn-encode (tab)
  "TAB as a list of integers: every counted cell (rounded to 0.1; order 1 only its *LEARN-CAP* largest), the bandit's
*LEARN-ARM-CAP* largest scores, the burst scores, the last classes and the form."
  (flet ((code (i v) (+ (* i 65536) (learn-clamp (round v) -32768 32767) 32768))
         (largest (v cap scale min)
           (let ((c nil))
             (loop for x across v for i from 0 when (>= (abs (round (* scale x))) min) do (push (cons i x) c))
             (loop for (i . x) in (sort c #'> :key (lambda (e) (abs (cdr e)))) repeat cap collect (cons i x)))))
    (let ((out (list (code 2999 2) (code 2950 (* 1000 (ltab-form tab))))))
      (dotimes (s +learn-s+) (let ((p (aref (ltab-prev tab) s))) (when (>= p 0) (push (code (+ 2300 s) (1+ p)) out))))
      (loop for v across (ltab-bursts tab) for i from 0 unless (zerop (round (* 1000 v))) do (push (code (+ 2400 i) (* 1000 v)) out))
      (loop for v across (ltab-c0 tab) for i from 0 when (>= (round (* 10 v)) 1) do (push (code i (* 10 v)) out))
      (loop for (i . v) in (largest (ltab-arms tab) *learn-arm-cap* 1000 1) do (push (code (+ 1000 i) (* 1000 v)) out))
      (nreconc out (loop for (i . v) in (largest (ltab-c1 tab) *learn-cap* 10 1) collect (code (+ 100 i) (* 10 v)))))))

(defun learn-decode (codes)
  "A table from LEARN-ENCODE's integers (format 1 migrated; unknown or out-of-range entries are skipped: a fresh table for
garbage)."
  (let ((tab (make-ltab))
        (v1 (find-if (lambda (c) (= (floor c 65536) 999)) codes))
        (sit1 (lambda (s) (if (< s 5) s (1+ s)))))           ; format 1's situations: :c-hit came in at 5
    (dolist (c codes tab)
      (multiple-value-bind (i v) (floor c 65536)
        (let ((v (- v 32768)))
          (if v1
              (cond ((< -1 i 72) (multiple-value-bind (st a) (floor i 9)
                                   (setf (aref (ltab-c0 tab) (+ (* (funcall sit1 st) +learn-a+) a)) (max 0f0 (/ v 10f0)))))
                    ((<= 100 i 747) (multiple-value-bind (st r) (floor (- i 100) 81)
                                      (multiple-value-bind (p a) (floor r 9)
                                        (setf (aref (ltab-c1 tab) (+ (* (+ (* (funcall sit1 st) +learn-a+) p) +learn-a+) a))
                                              (max 0f0 (/ v 10f0))))))
                    ((<= 900 i 907) (setf (aref (ltab-prev tab) (funcall sit1 (- i 900))) (if (<= 1 v 9) (1- v) -1)))
                    ((= i 950) (setf (ltab-form tab) (learn-clamp (/ v 1000f0) -1f0 1f0))))
              (cond ((< -1 i 90) (setf (aref (ltab-c0 tab) i) (max 0f0 (/ v 10f0))))
                    ((<= 100 i 999) (setf (aref (ltab-c1 tab) (- i 100)) (max 0f0 (/ v 10f0))))
                    ((<= 1000 i 2199) (setf (aref (ltab-arms tab) (- i 1000)) (/ v 1000f0)))
                    ((<= 2300 i 2308) (setf (aref (ltab-prev tab) (- i 2300)) (if (<= 1 v +learn-a+) (1- v) -1)))
                    ((<= 2400 i 2405) (setf (aref (ltab-bursts tab) (- i 2400)) (/ v 1000f0)))
                    ((= i 2950) (setf (ltab-form tab) (learn-clamp (/ v 1000f0) -1f0 1f0))))))))))
