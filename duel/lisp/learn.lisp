;;;; learn.lisp — the learning CPU's pure part (docs/DUEL_LEARNING.md; the user, 2026-09-29). Plain CL, host-tested
;;;; (tests/learn-test.lisp); ai.lisp feeds it what the CPU perceives and asks it what to do. Character-free: the tables
;;;; are keyed by situations, action classes, distance bins and command keywords, never by a name.
;;;;   player model  per SITUATION (8), counts of the human's next ACTION CLASS (9): order 0, and order 1 keyed by his
;;;;                 previous class in that situation; decayed x*LEARN-DECAY* per observation (habits change);
;;;;                 LEARN-PREDICT blends order 1 into order 0 (backoff), LEARN-COUNTER answers the prediction
;;;;                 (防 > J > I > 防, DUEL_STRINGS §14)
;;;;   bandit        per distance bin (5) and neutral command (10), a discounted EXP3 score; the kit's :moves weight x
;;;;                 exp(score) (LEARN-MULT), rewarded with the damage balance of the next *LEARN-WINDOW* frames
;;;;   form          the human's recent results in [-1, 1]; LEARN-P-EXPLOIT reads him more when he wins, less when he loses
;;;;   storage       LEARN-ENCODE / LEARN-DECODE: a table as a short list of integers (the page keeps them, pwa.js)
(in-package :duel)

(defparameter *learn-situations* #(:wake :knock :h-blocked :c-blocked :whiff :close :mid :far)
  "What just happened, seen from the CPU about the human: he wakes up / we wake up (his oki) / he blocked / we blocked
his string / his move whiffed; else neutral by distance (LEARN-BAND). The first +LEARN-EVENTS+ are events.")
(defconstant +learn-events+ 5 "Situations below this index are events (a counter is planned at their onset).")
(defparameter *learn-actions* #(:guard :j :k :i :hoho :back :l :sp :o)
  "The human's coarse action classes: guard, J (Quick), K (Flash), I (Breaker, the grab), Hoho / Step, backing off, L
(Signature), SP (SP1 / SP2), O (Kikon rush).")
(defparameter *learn-arms* #(:q :f :sig :sp1 :sp2 :breaker :kikon :step :hoho nil)
  "The neutral commands a kit's :moves bands weigh (NIL = wait): the bandit's arms.")
(defparameter *learn-bins* #(1.6 3.0 5.0 7.0) "Bandit distance bins: their upper bounds, m (5 bins, the last open).")
(defparameter *learn-bands* #(2.5 5.0) "Neutral situations :close / :mid / :far: upper bounds, m.")
(defparameter *learn-counters*
  '((:guard :breaker) (:j :guard) (:k :q) (:i :q) (:hoho :hoho-punish) (:back nil) (:l :guard) (:sp :hoho) (:o :guard))
  "The answer to each predicted class: I beats guard, guard beats J, J beats K and I, a Hoho is not fed (the CPU waits)
and punished where he reappears (:hoho-punish, a reaction through the perception delay), a Signature / the rush guarded,
an SP stepped through. Backing off has none (chasing him paid off 5 % of the time in the gate: the kit's own ranges do
better).")

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

(defconstant +learn-s+ 8) (defconstant +learn-a+ 9) (defconstant +learn-arms+ 10) (defconstant +learn-nbins+ 5)

(defstruct (ltab (:constructor make-ltab ()))
  "One CPU character's learned tables (docs/DUEL_LEARNING.md)."
  (c0 (make-array (* +learn-s+ +learn-a+) :element-type 'single-float :initial-element 0f0))
  (c1 (make-array (* +learn-s+ +learn-a+ +learn-a+) :element-type 'single-float :initial-element 0f0))
  (prev (make-array +learn-s+ :element-type 'fixnum :initial-element -1))   ; his last class per situation
  (arms (make-array (* +learn-nbins+ +learn-arms+) :element-type 'single-float :initial-element 0f0))
  (form 0f0 :type single-float))

(defun learn-sit (key) (position key *learn-situations*))
(defun learn-act (key) (position key *learn-actions*))
(defun learn-band (d) "Neutral situation index for distance D." (+ +learn-events+ (or (position-if (lambda (b) (< d b)) *learn-bands*) 2)))
(defun learn-bin (d) "Bandit bin for distance D." (or (position-if (lambda (b) (< d b)) *learn-bins*) 4))
(defun learn-clamp (x lo hi) (max lo (min hi x)))

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

(defun learn-counter (act) "The command answering class index ACT (*LEARN-COUNTERS*)." (second (assoc (aref *learn-actions* act) *learn-counters*)))

(defun learn-onset (hprev hs hcontact own-prev own open d)
  "Which situation begins this step (index), or NIL. HPREV / HS: the human's perceived state last step / now (HCONTACT:
what his move last step touched, NIL = a whiff), OWN-PREV / OWN: ours, OPEN: the episode open (-1 none), D: the perceived
distance. Events override an open neutral episode; a neutral one opens when none is open and both are free."
  (flet ((free (st) (member st '(:idle :guard :run))))
    (cond ((and (eq hs :wakeup) (not (eq hprev :wakeup))) 0)
          ((and (eq own :wakeup) (not (eq own-prev :wakeup))) 1)
          ((and (eq hprev :guard-hit) (not (eq hs :guard-hit))) 2)
          ((and (eq own-prev :guard-hit) (not (eq own :guard-hit))) 3)
          ((and (eq hprev :move) (null hcontact) (not (eq hs :move))) 4)
          ((and (< open 0) (free hs) (free own)) (learn-band d)))))

(defun learn-kind-class (kind)
  "A move kind's action class keyword (NIL: not one the model counts)."
  (case kind (:quick :j) (:flash :k) (:breaker :i) (:sig :l) (:sp :sp) (:kikon :o)))

(defun learn-action (hprev hs kind new-start away)
  "The human's action class index starting this step, or NIL: a move (from a free state, or a new link: NEW-START) by its
KIND, a guard raised, a Hoho / Step, or AWAY metres backed off within the episode."
  (let ((k (cond ((and (eq hs :move) (or (not (eq hprev :move)) new-start)) (learn-kind-class kind))
                 ((and (eq hs :guard) (not (eq hprev :guard))) :guard)
                 ((and (member hs '(:hoho :step)) (not (eq hprev hs))) :hoho)
                 ((> away *learn-back*) :back))))
    (and k (learn-act k))))

(defun learn-episode (sit) "Frames situation SIT's episode waits." (getf *learn-episode* (if (< sit +learn-events+) :event :neutral)))

;;; ---------------------------------------------------------------- the bandit
(defun learn-mult (tab bin arm) "The weight factor of arm index ARM in BIN." (exp (aref (ltab-arms tab) (+ (* bin +learn-arms+) arm))))

(defun learn-reward! (tab bin arm prob r)
  "Discounted EXP3: every score of BIN x *LEARN-GAMMA*, then arm ARM (picked with probability PROB) + eta r / prob;
clamped to +-*LEARN-S-MAX*. R: the reward in [-1, 1]."
  (let ((v (ltab-arms tab)) (base (* bin +learn-arms+)) (m (float *learn-s-max* 1f0)))
    (dotimes (a +learn-arms+) (setf (aref v (+ base a)) (* (float *learn-gamma* 1f0) (aref v (+ base a)))))
    (setf (aref v (+ base arm))
          (learn-clamp (float (+ (aref v (+ base arm)) (/ (* *learn-eta* r) (max prob *learn-p-floor*))) 1f0) (- m) m))
    tab))

(defun learn-reward (dealt taken) "Damage DEALT minus TAKEN in a window, as a reward in [-1, 1]." (learn-clamp (/ (- dealt taken) *learn-norm*) -1.0 1.0))

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
;;; One integer per entry: index x 65536 + value + 32768. Index 0-71 order 0 (x10), 100-747 order 1 (x10), 800-849 the
;;; scores (x1000), 900-907 the last class per situation (+1), 950 the form (x1000), 999 the format version.
(defun learn-encode (tab)
  "TAB as a list of integers: every counted cell (rounded to 0.1; order 1 only its *LEARN-CAP* largest), the scores,
the last classes and the form."
  (flet ((code (i v) (+ (* i 65536) (learn-clamp (round v) -32768 32767) 32768)))
    (let ((out (list (code 999 1) (code 950 (* 1000 (ltab-form tab))))) (c1 nil))
      (dotimes (s +learn-s+) (let ((p (aref (ltab-prev tab) s))) (when (>= p 0) (push (code (+ 900 s) (1+ p)) out))))
      (loop for v across (ltab-arms tab) for i from 0 unless (zerop (round (* 1000 v))) do (push (code (+ 800 i) (* 1000 v)) out))
      (loop for v across (ltab-c0 tab) for i from 0 when (>= (round (* 10 v)) 1) do (push (code i (* 10 v)) out))
      (loop for v across (ltab-c1 tab) for i from 0 when (>= (round (* 10 v)) 1) do (push (cons i v) c1))
      (setf c1 (sort c1 #'> :key #'cdr))
      (nreconc out (loop for (i . v) in c1 repeat *learn-cap* collect (code (+ 100 i) (* 10 v)))))))

(defun learn-decode (codes)
  "A table from LEARN-ENCODE's integers (unknown or out-of-range entries are skipped: a fresh table for garbage)."
  (let ((tab (make-ltab)))
    (dolist (c codes tab)
      (multiple-value-bind (i v) (floor c 65536)
        (let ((v (- v 32768)))
          (cond ((< -1 i 72) (setf (aref (ltab-c0 tab) i) (max 0f0 (/ v 10f0))))
                ((<= 100 i 747) (setf (aref (ltab-c1 tab) (- i 100)) (max 0f0 (/ v 10f0))))
                ((<= 800 i 849) (setf (aref (ltab-arms tab) (- i 800)) (/ v 1000f0)))
                ((<= 900 i 907) (setf (aref (ltab-prev tab) (- i 900)) (if (<= 1 v +learn-a+) (1- v) -1)))
                ((= i 950) (setf (ltab-form tab) (learn-clamp (/ v 1000f0) -1f0 1f0)))))))))
