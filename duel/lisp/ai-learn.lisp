;;;; ai-learn.lisp — the learning CPU's glue to the brain (moved out of ai.lisp unchanged; it loads right after it): the
;;;; per-character tables and their page storage, the LRN learner a CPU facing a human carries, its plan / fire / press of
;;;; a predicted counter, the bandit over the kit's :moves, the Burst and kit episodes. The pure part is learn.lisp
;;;; (host-tested); docs/duel/DUEL_LEARNING.md.
(in-package :duel)

;;; ---------------------------------------------------------------- the learning CPU (learn.lisp; docs/duel/DUEL_LEARNING.md)
;;; Only a CPU facing a human carries one (flow.lisp LEARN-MATCH-START: VS CPU, ENDLESS, the SETTINGS toggle; never CPU VS
;;; CPU or a debug command). Without it (BRAIN-LEARN NIL) none of this runs: the CPU draws and decides exactly as before.
;;; It sees what the CPU sees (the delayed SNAP; its own state at once), never an input, and it only chooses among the
;;; kit's own commands; its dice are its own stream (LEARN-RND), never SIM-RND01.
(defvar *learn-tables* (make-array 10 :initial-element nil)
  "Per roster index, that CPU character's learned table (LTAB), loaded from the page on first use (LEARN-TABLE).")
(defvar *learn-debug-off* nil "A debug command ran: no learner is attached any more (the gates stay exactly as they were).")
(defvar *learn-use* '(:model :bandit) "Its parts in use (the learning gate's A/B: 200000+, ON 2 model only, 3 bandit only).")
(defparameter *learn-read-t* 60 "Frames after a counter it counts as paid off (damage dealt, none taken).")
(defconstant +pg-learn+ 100 "Page get / set 100 + 1000 i: roster index i's saved table (entry count; + 1 + j entry j).")
(defvar *assist-learn-tables* (make-array 10 :initial-element nil)
  "ASSIST's learner (assist.lisp): per roster index, what a human's assist learned of THAT character's CPU (LTAB, its form
the CPU's), kept apart from the CPUs' tables of the human.")
(defconstant +pg-assist-learn+ 10100 "Page get / set 10100 + 1000 i: *ASSIST-LEARN-TABLES* i, as +PG-LEARN+ (pwa.js soulduel.learn.a<i>).")

(defstruct lrn
  "A learner's state within one match (BRAIN-LEARN); TAB is its character's table, kept across matches."
  tab
  (sit -1 :type fixnum) (ep-t 0 :type fixnum) (away 0f0 :type single-float)   ; the open episode, his way away since
  (hx 0f0 :type single-float) (hz 0f0 :type single-float) (hstate :idle) (hstart -1 :type fixnum) (hcontact nil)
  (own :idle)                                                                 ; ... the human (perceived) and we, last step
  (cmd nil) (delay 0 :type fixnum) (pend-t 0 :type fixnum)                    ; the planned counter, its wait, its life
  (arm -1 :type fixnum) (bin 0 :type fixnum) (prob 0f0 :type single-float)    ; the bandit's open window (BIN: its row)
  (bw -1 :type fixnum) (bw-used nil) (bw-prob 0f0 :type single-float) (bw-t 0 :type fixnum)   ; a burst bandit's window
  (bw-dealt 0 :type fixnum) (bw-taken 0 :type fixnum) (bw-reishi 0 :type fixnum) (bw-konpaku 0 :type fixnum)
  (hburst nil) (hcombo 0 :type fixnum)                                        ; his burst, our combo's hits on him, last step
  (win-t 0 :type fixnum) (w-dealt 0 :type fixnum) (w-taken 0 :type fixnum)
  (form-t 0 :type fixnum) (f-dealt 0 :type fixnum) (f-taken 0 :type fixnum)   ; the form clock
  (rng 1)
  (stats nil) (last nil)                                                      ; per counter (cmd reads paid); the last
  (reads 0 :type fixnum) (paid 0 :type fixnum) (read-t 0 :type fixnum) (r-dealt 0 :type fixnum) (r-taken 0 :type fixnum)
  (read-clock 0 :type fixnum)                                                 ; frames to its next neutral read (AI-REFLEX)
  (kit nil)                                   ; its character's own situations (LEARN-DEF-KIT's spec; NIL: none, nothing runs)
  (ksit -1 :type fixnum) (kep-t 0 :type fixnum) (kdata nil))   ; ... the kit episode open, its frames, the kit's own state

(defun learn-table (i &optional (tables *learn-tables*) (pg +pg-learn+))
  "Roster index I's table in TABLES (page base PG; the assist's: *ASSIST-LEARN-TABLES*): in memory, else the page's
(LEARN-DECODE; nothing saved or no storage: a fresh one)."
  (or (svref tables i)
      (setf (svref tables i)
            (let* ((base (+ pg (* 1000 i))) (n (min 999 (max 0 (page-get base)))))
              (learn-decode (loop for j from 1 to n collect (page-get (+ base j))))))))

(defun learn-save (i &optional (tables *learn-tables*) (pg +pg-learn+))
  "Roster index I's table of TABLES to the page (base PG; entries first, then the count, which commits them)."
  (let ((tab (svref tables i)) (base (+ pg (* 1000 i))))
    (when tab
      (let ((codes (learn-encode tab)))
        (loop for c in codes for j from 1 do (page-set (+ base j) c))
        (page-set base (length codes))))))

(defun learn-reset-all ()
  "SETTINGS' RESET LEARNING: every table forgotten, in memory and on the page."
  (dotimes (i (length *learn-tables*))
    (setf (svref *learn-tables* i) nil (svref *assist-learn-tables* i) nil)
    (page-set (+ +pg-learn+ (* 1000 i)) 0)
    (page-set (+ +pg-assist-learn+ (* 1000 i)) 0))
  (log-msg "duel learning reset"))

(defun learn-attach! (e)
  "Give CPU E a learner over its character's table (its own stream seeded from the sim stream's state: no draw), and its
character's own situations when it names some (LEARN-DEF-KIT; the ASSIST's learner never has them)."
  (let ((o (opp-of e)) (i (position (fighter-character (fighter e)) *roster*)))
    (setf (brain-learn (brain e))
          (make-lrn :tab (learn-table i) :hx (aref (pos-of o) 0) :hz (aref (pos-of o) 2)
                    :rng (1+ (mod (* 7919 (sim-rnd-state)) 2147483647))
                    :kit (learn-kit-spec (fighter-character (fighter e)))))))   ; (its own situations: DUEL_LEARNING §11)

(defun learn-roll-p (l)
  "Take the model's counter now? Its own stream against p_exploit for the human's form."
  (multiple-value-bind (r st) (learn-rnd (lrn-rng l))
    (setf (lrn-rng l) st)
    (< r (learn-p-exploit (ltab-form (lrn-tab l))))))

(defun learn-step (e b s d)
  "Each step (BRAIN-STEP): open / close the episodes and count the human's action (the perceived SNAP S, D), plan an
event's counter at its onset, and run the clocks: the counter's wait, the bandit's window, a read's outcome, the form;
then its character's own situations (the kit's :step, LEARN-DEF-KIT), before the human's last-step state moves on."
  (let* ((l (brain-learn b)) (tab (lrn-tab l)) (own (state-of e)) (hs (snap-state s)) (hprev (lrn-hstate l))
         (p (pos-of e)) (dealt (gauges-dealt (gauges e))) (taken (gauges-dealt (gauges (opp-of e))))
         (dx (- (snap-x s) (lrn-hx l))) (dz (- (snap-z s) (lrn-hz l))))
    (when (and (> d 0.01) (< (+ (* dx dx) (* dz dz)) 0.25))   ; his way away from us (a Hoho's jump is no walk)
      (incf (lrn-away l) (f32 (/ (+ (* dx (- (snap-x s) (aref p 0))) (* dz (- (snap-z s) (aref p 2)))) d))))
    (let ((on (learn-onset hprev hs (lrn-hcontact l) (lrn-own l) own (lrn-sit l) d
                           (let ((n (fighter-combo-hits (fighter (opp-of e)))))   ; our string's hit that opens his burst
                             (and (= n *burst-min-hits*) (/= (lrn-hcombo l) n)   ; (while his HUD bar has it)
                                  (>= (gauges-fs (gauges (opp-of e))) *fs-burst*))))))
      (when on
        (setf (lrn-sit l) on (lrn-ep-t l) 0 (lrn-away l) 0f0)
        (when (< on +learn-events+) (learn-plan b l on))))
    (let ((sit (lrn-sit l)))
      (when (>= sit 0)
        (let* ((burst (and (gauges-burst (gauges (opp-of e))) (not (lrn-hburst l))))   ; (a burst: its aura, at once)
               (c-hit (= sit (learn-sit :c-hit)))                ; (reeling, only a burst is his: the knockback isn't)
               (act (if c-hit
                        (and burst (learn-act :burst))
                        (learn-action hprev hs (snap-kind s) (/= (snap-start s) (lrn-hstart l)) (lrn-away l) burst))))
          (cond (act (learn-observe! tab sit act) (setf (lrn-sit l) -1))
                ((or (> (incf (lrn-ep-t l)) (learn-episode sit)) (and c-hit (not (member hs '(:stun :air)))))
                 (when (or (eq hs :guard) c-hit)                 ; he held guard through it / took our string
                   (learn-observe! tab sit (learn-act :guard)))
                 (setf (lrn-sit l) -1))))))
    (when (plusp (lrn-read-clock l)) (decf (lrn-read-clock l)))   ; the neutral read's clock (AI-REFLEX)
    (when (lrn-cmd l)
      (when (plusp (lrn-delay l)) (decf (lrn-delay l)))
      (when (<= (decf (lrn-pend-t l)) 0) (setf (lrn-cmd l) nil)))
    (when (and (>= (lrn-arm l) 0) (<= (decf (lrn-win-t l)) 0)) (learn-settle l dealt taken))
    (when (and (>= (lrn-bw l) 0) (<= (decf (lrn-bw-t l)) 0)) (learn-burst-settle e l dealt taken))
    (when (and (plusp (lrn-read-t l)) (zerop (decf (lrn-read-t l))) (= taken (lrn-r-taken l))
               (or (> dealt (lrn-r-dealt l)) (eq (lrn-last l) :guard)))   ; (a guard pays by taking nothing)
      (incf (lrn-paid l)) (incf (third (assoc (lrn-last l) (lrn-stats l)))))
    (when (>= (incf (lrn-form-t l)) *learn-form-t*)             ; his damage balance moves his form
      (setf (ltab-form tab) (learn-form-after (ltab-form tab) (learn-reward (- taken (lrn-f-taken l)) (- dealt (lrn-f-dealt l)))
                                              *learn-form-k*)
            (lrn-form-t l) 0 (lrn-f-dealt l) dealt (lrn-f-taken l) taken))
    (when (lrn-kit l) (funcall (getf (lrn-kit l) :step) e b s d l))   ; its character's own situations (LEARN-DEF-KIT)
    (setf (lrn-hburst l) (and (gauges-burst (gauges (opp-of e))) t) (lrn-hcombo l) (fighter-combo-hits (fighter (opp-of e))))
    (setf (lrn-hx l) (snap-x s) (lrn-hz l) (snap-z s) (lrn-hstate l) hs (lrn-hstart l) (snap-start s)
          (lrn-hcontact l) (snap-contact s) (lrn-own l) own)))

(defun learn-plan (b l sit)
  "An event's onset: when the model is confident and the roll says read him, plan its counter for the episode (on his
wake-up, a strike timed to meet the end of it: what the perception delay already cost and ~8 f of startup before it)."
  (multiple-value-bind (act p n) (learn-predict (lrn-tab l) sit)
    (when (and act (learn-counter act sit) (member :model *learn-use*) (learn-confident-p p n) (learn-roll-p l))
      (let ((c (learn-counter act sit)))
        (setf (lrn-cmd l) c (lrn-pend-t l) (learn-episode sit)
              (lrn-delay l) (if (and (= sit 0) (member c '(:q :breaker)))
                                (max 0 (- (getf *reaction-frames* :wakeup) (brain-delay b) 8))
                                0))))))

(defun learn-fire (e b s d)
  "The planned counter, once due and we are free: T when it pressed. :HOHO-PUNISH waits for his Hoho (seen through the
perception delay) and swings where he reappears."
  (let ((l (brain-learn b)) (f (fighter e)))
    (when (and (lrn-cmd l) (<= (lrn-delay l) 0) (member (fighter-state f) '(:idle :guard :run)) (zerop (fighter-lock f))
               (or (not (eq (lrn-cmd l) :hoho-punish)) (eq (snap-state s) :hoho)))
      (let ((c (lrn-cmd l))) (setf (lrn-cmd l) nil)
        (learn-press e b (case c (:hoho-punish :q) (:bait :guard) (t c)) d (eq c :hoho-punish))))))

(defun learn-press (e b cmd d &optional anywhere)
  "Press counter CMD at distance D when it can go (a J / K only within its reach, unless ANYWHERE: he reappears behind
us; an SP's Hoho without flash-step is a guard): T when pressed; the read is counted."
  (let* ((kit (kit-of e))
         (cmd (if (and (eq cmd :hoho) (not (hoho-ready-p e))) :guard cmd))
         (mv (and (member cmd *kit-commands*) (kit-command-move kit cmd))))
    (when (case cmd
            ((:q :f) (and mv (kit-command-ok-p e cmd) (or anywhere (<= d (+ (mv-reach mv) 0.4)))))
            (:guard (plusp (ai-guard-k e)))
            ((:hoho :dash-in) t)
            (t (and mv (kit-command-ok-p e cmd))))
      (case cmd (:guard (ai-press b :guard 30)) (:dash-in (ai-dash b 1.0 1.5)) (t (ai-command b kit cmd d e)))
      (clog "~a read ~a d ~,1f" (side-name e) cmd d)
      (learn-count-read e (brain-learn b) cmd)
      (setf (brain-why b) :read)
      t)))

(defun learn-count-read (e l cmd)
  "A read acted on with counter CMD (LEARN-PRESS; a kit's own, LEARN-KIT-ACTED): counted per counter, and watched
*LEARN-READ-T* frames for its pay-off (damage dealt, none taken; a guard pays by taking nothing)."
  (incf (lrn-reads l))
  (let ((st (or (assoc cmd (lrn-stats l)) (car (push (list cmd 0 0) (lrn-stats l))))))
    (incf (second st)) (setf (lrn-last l) cmd))
  (setf (lrn-read-t l) *learn-read-t* (lrn-r-dealt l) (gauges-dealt (gauges e))
        (lrn-r-taken l) (gauges-dealt (gauges (opp-of e)))))

(defun learn-neutral-due-p (e b s)
  "A learning CPU's neutral read is due this step: its own clock (LRN-READ-CLOCK, run by LEARN-STEP) is out, both are free
(the learner's neutral bands), no Kikon rush on a red opponent nor a pip hurry comes first (AI-DECIDE's order); no
scripted habit."
  (let ((l (brain-learn b)))
    (and l (not (brain-habit b)) (<= (lrn-read-clock l) 0)
         (member (fighter-state (fighter e)) '(:idle :run)) (member (snap-state s) '(:idle :guard :run))
         (not (kikon-ready-p e)) (not (ai-pip-hurry-p e)))))

(defun learn-read-due (e b s d)
  "AI-REFLEX: the neutral read when due (LEARN-NEUTRAL-DUE-P; the clock's next interval *AI-THINK* + up to 40 from its own
stream): T when it pressed."
  (when (learn-neutral-due-p e b s)
    (let ((l (brain-learn b)))
      (multiple-value-bind (r st) (learn-rnd (lrn-rng l))
        (setf (lrn-rng l) st (lrn-read-clock l) (+ (getf *ai-think* (brain-difficulty b) 24) (floor (* 40 r))))))
    (learn-neutral e b s d)))

(defun learn-neutral (e b s d)
  "A neutral read (AI-REFLEX, on the learner's own clock): read him for the band he is in (its counter, T when pressed); a
predicted Hoho is only primed (the decision goes on: the bait)."
  (declare (ignore s))
  (let ((l (brain-learn b)))
    (multiple-value-bind (act p n) (learn-predict (lrn-tab l) (learn-band d))
      (when (and act (learn-counter act) (member :model *learn-use*) (learn-confident-p p n) (learn-roll-p l))
        (let ((c (learn-counter act)))
          (if (eq c :hoho-punish)
              (progn (setf (lrn-cmd l) c (lrn-delay l) 0 (lrn-pend-t l) 60)   ; don't feed his Hoho: wait
                     (ai-press b :guard 12) (setf (brain-why b) :read-wait) t)
              (learn-press e b c d)))))))

(defun learn-context (e)
  "E's bandit context (LEARN-CTX): its form's index in its character's kits (definition order) x its kit meter's third."
  (let* ((kit (kit-of e)) (forms (gethash (kit-character kit) *kits*)) (m (kit-meter kit)))
    (learn-ctx (- (length forms) 1 (or (position (kit-form kit) forms :key #'car) 0))
               (if m (/ (gauges-meter (gauges e)) (float (getf m :max 100))) 0.0))))

(defparameter *learn-hoho-w* 0.3 "A learner's base weight for a neutral Hoho its kit's band leaves out (so it can learn one).")

(defun learn-weights (e l d weights)
  "The bandit's factors on a neutral pick's WEIGHTS (a fresh plist) for distance D in E's context; a Hoho the band leaves
out gets *LEARN-HOHO-W* first when it may go. Returns the plist."
  (let ((row (learn-row (learn-context e) (learn-bin d))) (tab (lrn-tab l)))
    (when (member :bandit *learn-use*)
      (unless (or (getf weights :hoho) (kit-rooted (kit-of e))
                  (not (hoho-ready-p e)))
        (setf weights (list* :hoho *learn-hoho-w* weights)))
      (loop for tail on weights by #'cddr
            for arm = (position (car tail) *learn-arms*)
            when arm do (setf (cadr tail) (* (cadr tail) (learn-mult tab row arm)))))
    weights))

(defun learn-window (e l d weights cmd)
  "The bandit's window for arm CMD, picked from WEIGHTS (its probability for the importance weight): the one still open
is settled first."
  (let ((arm (position cmd *learn-arms*)) (dealt (gauges-dealt (gauges e))) (taken (gauges-dealt (gauges (opp-of e))))
        (sum (loop for (nil w) on weights by #'cddr sum w)))
    (when (and arm (plusp sum) (member :bandit *learn-use*))
      (when (>= (lrn-arm l) 0) (learn-settle l dealt taken))
      (setf (lrn-arm l) arm (lrn-bin l) (learn-row (learn-context e) (learn-bin d)) (lrn-prob l) (f32 (/ (getf weights cmd 0) sum))
            (lrn-win-t l) *learn-window* (lrn-w-dealt l) dealt (lrn-w-taken l) taken))))

(defun learn-settle (l dealt taken)
  "Close the bandit's window: its damage balance rewards its arm (LEARN-REWARD!)."
  (learn-reward! (lrn-tab l) (lrn-bin l) (lrn-arm l) (lrn-prob l)
                 (learn-reward (- dealt (lrn-w-dealt l)) (- taken (lrn-w-taken l))))
  (setf (lrn-arm l) -1))

(defun learn-burst-open (e l color used prob)
  "A burst decision of COLOR (USED or not, that branch's probability from PROB) opens its bandit's window, unless one is
open (the rolls come in bursts: a WHITE one each neutral decision)."
  (let ((c (position color *learn-burst-colors*)) (g (gauges e)))
    (when (and c (< (lrn-bw l) 0) (member :bandit *learn-use*))
      (setf (lrn-bw l) c (lrn-bw-used l) used (lrn-bw-prob l) (f32 (if used prob (- 1 prob))) (lrn-bw-t l) *learn-window*
            (lrn-bw-dealt l) (gauges-dealt g) (lrn-bw-taken l) (gauges-dealt (gauges (opp-of e)))
            (lrn-bw-reishi l) (gauges-reishi g) (lrn-bw-konpaku l) (gauges-konpaku g)))))

(defun learn-burst-settle (e l dealt taken)
  "Close the burst window: the damage balance, plus the Reishi healed (WHITE) when no soul was lost in it."
  (let* ((g (gauges e)) (tk (- taken (lrn-bw-taken l)))
         (healed (if (= (gauges-konpaku g) (lrn-bw-konpaku l)) (max 0 (+ (- (gauges-reishi g) (lrn-bw-reishi l)) tk)) 0)))
    (learn-burst-reward! (lrn-tab l) (lrn-bw l) (lrn-bw-used l) (lrn-bw-prob l) (learn-reward (- dealt (lrn-bw-dealt l)) tk healed))
    (setf (lrn-bw l) -1)))

;;; A character's own situations (learn.lisp LEARN-DEF-KIT; DUEL_LEARNING §11): its :step function opens an episode by a
;;; situation its spec names (LEARN-KIT-OPEN), closes it with the human's answer (LEARN-KIT-CLOSE), and asks for a read
;;; once per event (LEARN-KIT-READ: the learner's own stream, as every read). A learner without a spec never gets here.
(defun learn-kit-open (l key)
  "Learner L's character opens its situation KEY (one its spec names; any other: nothing, NIL): the kit episode, from 0."
  (let ((i (learn-kit-sit (lrn-kit l) key)))
    (when i (setf (lrn-ksit l) i (lrn-kep-t l) 0))
    i))

(defun learn-kit-open-p (l key) "Is L's kit episode KEY open?" (let ((i (learn-kit-sit (lrn-kit l) key))) (and i (= i (lrn-ksit l)))))

(defun learn-kit-close (l act)
  "The human answered the open kit episode with class ACT (a key its spec names; NIL: no answer, nothing counted): the
kit model counts it, the episode closes."
  (let ((a (and act (learn-kit-act (lrn-kit l) act))))
    (when (and a (>= (lrn-ksit l) 0)) (learn-kit-observe! (lrn-tab l) (lrn-ksit l) a))
    (setf (lrn-ksit l) -1)))

(defun learn-kit-read (l key &optional (scale 1.0))
  "Read the human in L's kit situation KEY (once per event): his predicted answer (a class key) when the model is in use
and confident and the learner's own roll comes under p_exploit x SCALE (the kit's difficulty layer); else NIL."
  (let ((i (learn-kit-sit (lrn-kit l) key)))
    (when (and i (member :model *learn-use*))
      (multiple-value-bind (act p n) (learn-kit-predict (lrn-tab l) i)
        (when (and act (learn-confident-p p n))
          (multiple-value-bind (r st) (learn-rnd (lrn-rng l))
            (setf (lrn-rng l) st)
            (when (< r (* scale (learn-p-exploit (ltab-form (lrn-tab l)))))
              (aref (getf (lrn-kit l) :actions) act))))))))

(defun ai-burst-chance (b color p)
  "The base AI's chance P of a burst of COLOR, re-weighted by a learning CPU's burst bandit (LEARN-BURST-P)."
  (let ((l (brain-learn b)) (c (position color *learn-burst-colors*)))
    (if (and l c (member :bandit *learn-use*)) (learn-burst-p (lrn-tab l) c p) p)))

(defun ai-burst-rolled (e b color p)
  "Roll a burst of COLOR at the base chance P (a learner's bandit re-weighting it, and opening its window): T to burst."
  (let* ((q (ai-burst-chance b color p)) (yes (< (sim-rnd01) q)))
    (when (brain-learn b) (learn-burst-open e (brain-learn b) color yes q))
    yes))
