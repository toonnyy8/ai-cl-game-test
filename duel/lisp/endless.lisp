;;;; endless.lisp — ENDLESS 無限連戰 (docs/duel/DUEL_ENDLESS.md): one human P1 against a gauntlet of CPU stages, the carry-over
;;;; between them, the record per character. The rules (the ramp, the opponent bag, the carry, the record comparison) are
;;;; endless-rules.lisp; this file is the run, its screens (STAGE CLEAR, the run's RESULTS, the STAGE tag), the record on
;;;; the page (duel/web/pwa.js, page get / set 30 + 2i = stages, 31 + 2i = seconds of roster index i) and the debug
;;;; entries 80000-80999 (ENDLESS-DEBUG). Hooks elsewhere: flow.lisp (the MODE row, SELECT, START-MATCH, GO-RESULTS,
;;;; :clear, the pause's RETIRE, RESULTS), hud.lisp (HUD-DRAW :clear, HUD-BATTLE's tag, HUD-RESULTS, SELECT's START row),
;;;; main.lisp (MENU-CAMERA: :clear keeps the results' shot).
;;;; Log: "duel endless start ...", "duel endless stage ...", "duel endless clear ...", "duel endless over ...".
(in-package :duel)

(defvar *endless-seed* 1 "The run seed: the opponent bag and every stage's sim seed.")
(defvar *endless-stage* 0 "The stage being played (1-based).")
(defvar *endless-cleared* 0 "Stages cleared in this run.")
(defvar *endless-floor* :normal "START DIFFICULTY: the ramp's floor.")
(defvar *endless-carry* nil "P1's carry into the stage being started (ENDLESS-CARRY's plist); NIL = a fresh P1.")
(defvar *endless-snap* nil "P1 at the last clear (the carry's input).")
(defvar *endless-ticks* 0 "Battle ticks of the cleared stages: the run time.")
(defvar *endless-stats* (make-array 4 :initial-element 0) "The run's DAMAGE, KIKONS, PERFECT HOHOS, BEST COMBO (P1's).")
(defvar *endless-foes* nil "The opponents faced, newest first.")
(defvar *endless-record* nil "This run wrote a new best record.")
(defvar *endless-debug* nil "A debug run (80000+): the record is never written.")
(defvar *endless-auto* nil "Autopilot (debug 80990+): the CLEAR policy :stay / :revert, NIL = off.")
(defvar *endless-queue* nil "Autopilot: the (character seed) runs still to play.")
(defvar *endless-runs* nil "Autopilot: (character stages secs) of the finished runs.")
(defvar *endless-rows* nil "STAGE CLEAR: the row keys (:stay [:revert] :quit).")
(defvar *endless-lines* nil "STAGE CLEAR / the run's RESULTS: the screen's strings, made once per screen.")
(defvar *stage-strings* (make-array 100 :initial-element nil) "Stage -> \"STAGE n\", made once (the battle tag conses nothing).")
(defparameter *endless-results-menu* '("NEW RUN" "CHARACTER SELECT" "TITLE"))
(defconstant +pg-endless+ 30 "Page get / set 30 + 2i: roster index i's best stages, 31 + 2i its seconds (i < 10).")

(defun endless-p () (eq *mode* :endless))
(defun mm-ss (secs) (format nil "~d:~2,'0d" (floor secs 60) (mod secs 60)))
(defun roster-ix () (position (first *picks*) *roster*))
(defun endless-best ()
  "P1's character's stored best: values stages seconds (0 0 = none; no storage answers 0)."
  (let ((i (roster-ix)))
    (if (< i 10) (values (page-get (+ +pg-endless+ (* 2 i))) (page-get (+ +pg-endless+ 1 (* 2 i)))) (values 0 0))))

;;; ---------------------------------------------------------------- the run
(defun endless-new-seed ()
  "A fresh run seed from the clock and its stage-1 opponent on the plaza (GO-SELECT's hook)."
  (setf *endless-seed* (1+ (mod (floor (now-ms)) 100000))
        (second *picks*) (endless-opponent *endless-seed* 1 *roster*)))

(defun endless-start (&key debug (stage 1))
  "A run of P1 (FIRST *PICKS*) from STAGE (1 from the menu) at the START DIFFICULTY (*DIFFICULTY*), P1 fresh."
  (setf *endless-debug* debug *endless-floor* *difficulty* *endless-stage* (1- stage) *endless-cleared* 0
        *endless-carry* nil *endless-ticks* 0 *endless-foes* nil *endless-record* nil)
  (fill *endless-stats* 0)
  (log-msg "duel endless start seed ~d P1 ~(~a~) floor ~(~a~)~:[~; debug~]" *endless-seed* (first *picks*) *endless-floor* debug)
  (endless-next-stage))

(defun endless-next-stage ()
  "The next stage: its opponent from the bag, its seed, then START-MATCH (which calls ENDLESS-APPLY!)."
  (let ((n (incf *endless-stage*)))
    (setf (second *picks*) (endless-opponent *endless-seed* n *roster*)
          *match-seed* (endless-stage-seed *endless-seed* n))
    (push (second *picks*) *endless-foes*)
    (start-match)))

(defun endless-apply! ()
  "START-MATCH's hook: P1's carry over his fresh fighter, P2's ramp (difficulty, Reishi, awakening), the autopilot's
brain on P1."
  (let* ((n *endless-stage*) (r (endless-ramp n)) (d (endless-difficulty *endless-floor* n *difficulties*))
         (g1 (gauges *p1*)) (g2 (gauges *p2*)) (b (brain *p2*)) (c *endless-carry*))
    (when c
      (unless (eq (getf c :form) (fighter-form (fighter *p1*))) (set-form *p1* (getf c :form)))
      (setf (gauges-konpaku g1) (getf c :konpaku) (gauges-reiatsu g1) (f32 (getf c :reiatsu)) (gauges-fs g1) (f32 (getf c :fs))
            (gauges-awaken g1) (f32 (getf c :awaken)) (gauges-awakened g1) (getf c :awakened) (gauges-meter g1) (f32 (getf c :meter))))
    (setf (brain-difficulty b) d (brain-delay b) (getf *ai-delay* d 14))
    (let ((rm (round (* (gauges-reishi-max g2) (fifth r)) 100)))
      (setf (gauges-reishi-max g2) rm (gauges-reishi g2) rm (gauges-awaken g2) (f32 (third r))))
    (when (fourth r)                                      ; spawned awakened: the awaken form, no cinematic
      (set-form *p2* (kit-awaken-form (kit-of *p2*)))
      (setf (gauges-awakened g2) t (gauges-awaken g2) 0f0)
      (let ((st (getf (kit-meter (kit-of *p2*)) :start))) (when st (setf (gauges-meter g2) (f32 st)))))
    (when *endless-auto*                                  ; the autopilot: P1 is a HARD CPU
      (add-component *p1* (make-brain :difficulty :hard :delay (getf *ai-delay* :hard 8)))
      (setf (vpad-reader (pilot-vpad (pilot *p1*))) nil (pilot-cam-relative (pilot *p1*)) nil))
    (log-msg "duel endless stage ~d vs ~(~a~) diff ~(~a~) reishi ~d awaken ~a seed ~d P1 form ~(~a~) konpaku ~d awaken ~d meter ~d"
             n (second *picks*) d (gauges-reishi-max g2) (if (fourth r) "awakened" (third r)) *match-seed*
             (fighter-form (fighter *p1*)) (gauges-konpaku g1) (round (gauges-awaken g1)) (round (gauges-meter g1)))))

(defun endless-stage-end ()
  "GO-RESULTS' hook: the stage's stats into the run; a P1 win is a clear (the snapshot, the record, STAGE CLEAR), anything
else ends the run (its RESULTS)."
  (let ((g (gauges *p1*)) (s *endless-stats*))
    (incf (aref s 0) (gauges-dealt g)) (incf (aref s 1) (gauges-kikons g)) (incf (aref s 2) (gauges-perfects g))
    (setf (aref s 3) (max (aref s 3) (gauges-best-combo g)))
    (if (eql *winner* 0)
        (progn
          (incf *endless-cleared*)
          (incf *endless-ticks* *match-tick*)
          (setf *endless-snap* (list :character (fighter-character (fighter *p1*)) :form (fighter-form (fighter *p1*))
                                     :konpaku (gauges-konpaku g) :reiatsu (gauges-reiatsu g) :fs (gauges-fs g)
                                     :awaken (gauges-awaken g) :awakened (gauges-awakened g) :meter (gauges-meter g)))
          (endless-save-record)
          (endless-clear-lines)
          (set-flow :clear))
        (endless-over))))

(defun endless-save-record ()
  "At every clear (not in a debug run): the run so far into the page when it beats the stored best."
  (let ((i (roster-ix)) (secs (round *endless-ticks* 60)))
    (unless (or *endless-debug* (>= i 10))
      (multiple-value-bind (bs bt) (endless-best)
        (when (endless-better-p *endless-cleared* secs bs bt)
          (page-set (+ +pg-endless+ (* 2 i)) *endless-cleared*)
          (page-set (+ +pg-endless+ 1 (* 2 i)) secs)
          (setf *endless-record* t))))))

(defun endless-over ()
  "The run is over (a loss, a draw, RETIRE, QUIT): the log line, the RESULTS strings, the autopilot's tally."
  (let ((secs (round *endless-ticks* 60)))
    (multiple-value-bind (bs bt) (endless-best)
      (log-msg "duel endless over stages ~d secs ~d best ~d secs ~d record ~a" *endless-cleared* secs bs bt *endless-record*)
      (when *endless-auto* (push (list (first *picks*) *endless-cleared* secs) *endless-runs*))
      (let ((s *endless-stats*) (lost (not (eql *winner* 0))))
        (setf *endless-lines*
              (vector (format nil "ENDLESS  ~a" (kit-name (find-kit (first *picks*) :base)))
                      (format nil "STAGES CLEARED  ~d" *endless-cleared*)
                      (format nil "TIME  ~a" (mm-ss secs))
                      (if (plusp bs) (format nil "BEST  ~d  ~a" bs (mm-ss bt)) "BEST  -")
                      (list "DAMAGE" "KIKONS" "PERFECT HOHOS" "BEST COMBO")
                      (loop for v across s collect (format nil "~d" v))
                      (format nil "~{~a~^ ~}~:[~; X~]"      ; the opponents faced; X: the last one ended the run
                              (mapcar (lambda (c) (char (kit-name (find-kit c :base)) 0)) (reverse *endless-foes*))
                              lost)))))))

(defun endless-retire ()
  "The pause's RETIRE: the stage is lost, the run's RESULTS."
  (setf *paused* nil *winner* 1)
  (abort-cine)
  (go-results))

;;; ---------------------------------------------------------------- STAGE CLEAR
(defun endless-row-note (k)
  "What STAGE CLEAR's row K does (shown under the rows for the selected one): CONTINUE names the form carried."
  (let* ((snap *endless-snap*) (c (getf snap :character)) (from (getf snap :form))
         (to (getf (endless-carry snap :stay) :form)) (name (lambda (f) (kit-form-name (find-kit c f)))))
    (case k
      (:stay (cond ((not (getf snap :awakened)) (format nil "ON TO STAGE ~d" (1+ *endless-stage*)))
                   ((eq from to) (format nil "STAY ~a" (funcall name to)))
                   (t (format nil "~a -> ~a" (funcall name from) (funcall name to)))))
      (:revert "BACK TO BASE  AWAKENING FULL")
      (:quit "END THE RUN"))))

(defun endless-clear-lines ()
  "STAGE CLEAR's rows and strings (made once per clear): the stage, its time and the run's, the carry, the next stage."
  (let* ((snap *endless-snap*) (n *endless-stage*) (next (1+ n)) (r (endless-ramp next))
         (opp (endless-opponent *endless-seed* next *roster*)) (k (getf snap :konpaku)))
    (setf *endless-rows* (if (getf snap :awakened) '(:stay :revert :quit) '(:stay :quit))
          *endless-lines*
          (vector (format nil "STAGE ~d CLEAR" n)
                  (format nil "TIME ~a   RUN ~a" (mm-ss (round *match-tick* 60)) (mm-ss (round *endless-ticks* 60)))
                  (format nil "KONPAKU  ~d -> ~d" k (min *konpaku-max* (+ k 2)))
                  "REISHI FULL   GUARD FULL"
                  "REIATSU  FLASH STEP  KEPT"
                  (format nil "NEXT  STAGE ~d  ~a  ~a" next (kit-name (find-kit opp :base))
                          (endless-difficulty *endless-floor* next *difficulties*))
                  (format nil "~:[~;AWAKENED AT FIGHT~]~:[~*~;AWAKENING ~d~]~:[~*~;  REISHI ~d%~]"
                          (fourth r) (and (not (fourth r)) (plusp (third r))) (third r) (> (fifth r) 100) (fifth r))
                  (mapcar (lambda (k) (case k (:stay "CONTINUE") (:revert "REVERT") (t "QUIT"))) *endless-rows*)
                  (mapcar #'endless-row-note *endless-rows*)))))

(defun endless-choose (k)
  "A STAGE CLEAR row: CONTINUE (:stay) / REVERT carry P1 into the next stage, QUIT ends the run."
  (if (eq k :quit)
      (progn (endless-over) (set-flow :results))
      (let ((snap *endless-snap*))
        (setf *endless-carry* (endless-carry snap k))
        (log-msg "duel endless clear ~d konpaku ~d->~d choice ~(~a~) form ~(~a~)->~(~a~) meter ~d ticks ~d"
                 *endless-stage* (getf snap :konpaku) (getf *endless-carry* :konpaku) k (getf snap :form)
                 (getf *endless-carry* :form) (round (getf *endless-carry* :meter)) *endless-ticks*)
        (endless-next-stage))))

(defun endless-clear-update ()
  "STAGE CLEAR per frame: the rows take input after 1 s (a masher doesn't skip it); back does nothing. The autopilot
picks its policy at once."
  (cond (*endless-auto* (endless-choose (if (member *endless-auto* *endless-rows*) *endless-auto* :stay)))
        ((> *ft* 1.0) (let ((i (menu-nav (length *endless-rows*)))) (when i (endless-choose (nth i *endless-rows*)))))))

(defun endless-results-update ()
  "The run's RESULTS per frame: NEW RUN (a new seed) / CHARACTER SELECT / TITLE after 2.5 s; the autopilot's next run."
  (cond (*endless-auto* (endless-auto-next))
        ((> *ft* 2.5) (case (menu-nav 3)
                        (0 (endless-new-seed) (endless-start))
                        (1 (go-select))
                        (2 (go-title))))))

;;; ---------------------------------------------------------------- drawing
(defun endless-card (w h s)
  "The black card of STAGE CLEAR / the run's RESULTS (the results' layout: the left panel, portrait the lower part).
Values: its centre x, top y, width."
  (if (portrait-p)
      (let ((top (* 0.42 h)))
        (ui-rect 0 top w (- h top) '(0.031 0.031 0.047 0.94))
        (ui-rect 0 top w (max 1 (round s 2)) '(0.96 0.96 0.94 0.8))
        (values (* 0.5 w) (+ top (* 8 s)) w))
      (let* ((sc (max 1 (round (* 1.5 s)))) (px (* 0.04 w)) (pw (+ (* 28 s) (* 131 sc))))
        (ui-rect px 0 pw h '(0.031 0.031 0.047 0.94))
        (ui-rect (+ px pw) 0 (max 1 (round s 2)) h '(0.96 0.96 0.94 0.8))
        (values (+ px (* 0.5 pw)) (* 0.2 h) pw))))

(defun hud-endless-clear (w h s)
  "STAGE CLEAR: the stage, the times, what carries over, the next stage, the rows (CONTINUE / REVERT / QUIT)."
  (let ((l *endless-lines*))
    (multiple-value-bind (cx y pw) (endless-card w h s)
      (let* ((row (* 11 (max 1 (round (* 1.5 s))))))
        (ui-big-text (svref l 0) (round cx) (round (+ y (* 4 s))) (fit-scale (svref l 0) (* 3 s) (- pw (* 8 s)))
                     '(1 0.92 0.8 1) '(0.7 0.18 0.05 1) s :shear 0.0)
        (loop for i from 1 to 6 for yy = (+ y (* 6 s) (* i row)) do
          (hud-text (svref l i) cx yy (fit-scale (svref l i) (* 1.5 s) (- pw (* 8 s))) (case i (1 *white*) (5 *ember*) (t *dim*))
                    :align :center))
        (when (> *ft* 1.0)
          (let* ((y0 (if (portrait-p) 0.8 0.72)) (note (nth *menu* (svref l 8))))
            (hud-text note cx (- (* y0 h) (* 14 s)) (fit-scale note (* 1.5 s) (- pw (* 8 s))) *ember* :align :center)
            (hud-menu (svref l 7) y0 w h s cx)))))))

(defun hud-endless-results (w h s)
  "The run's RESULTS: the character, STAGES CLEARED, TIME, BEST (NEW RECORD), the run's totals, the opponents faced, the
menu (NEW RUN / CHARACTER SELECT / TITLE)."
  (let ((l *endless-lines*))
    (multiple-value-bind (cx y pw) (endless-card w h s)
      (let* ((sc (max 1 (fit-scale "PERFECT HOHOS  00000" (round (* 1.5 s)) (- pw (* 8 s))))) (row (* 9 sc))
             (lx (- cx (* 0.42 pw))) (vx (+ cx (* 0.38 pw))))
        (ui-big-text (svref l 0) (round cx) (round (+ y (* 4 s))) (fit-scale (svref l 0) (* 3 s) (- pw (* 8 s)))
                     '(1 0.92 0.8 1) '(0.7 0.18 0.05 1) s :shear 0.0)
        (hud-text (svref l 1) cx (+ y (* 6 s) row) (fit-scale (svref l 1) (* 1.5 sc) (- pw (* 8 s))) *white* :align :center)
        (hud-text (svref l 2) cx (+ y (* 6 s) (* 2.5 row)) sc *white* :align :center)
        (hud-text (svref l 3) cx (+ y (* 6 s) (* 3.5 row)) sc *dim* :align :center)
        (when *endless-record*
          (hud-text "NEW RECORD" cx (+ y (* 6 s) (* 4.5 row)) sc (if (< (mod (fx-clock) 1.0) 0.7) *ember* *white*) :align :center))
        (loop for label in (svref l 4) for v in (svref l 5) for i from 6
              for yy = (+ y (* 6 s) (* i row)) do
                (hud-text label lx yy sc *dim*)
                (hud-text v vx yy sc *white* :align :right))
        (hud-text (svref l 6) cx (+ y (* 6 s) (* 10.5 row)) sc *dim* :align :center)
        (when (> *ft* 2.5) (hud-menu *endless-results-menu* (if (portrait-p) 0.8 0.72) w h s cx))))))

(defun hud-endless-tag (w h s)
  "The battle's STAGE n: landscape under the timer, portrait left under P2's block (the pause chip is on the right)."
  (let* ((n (min 99 *endless-stage*))
         (str (or (svref *stage-strings* n) (setf (svref *stage-strings* n) (format nil "STAGE ~d" n)))))
    (if (portrait-p)
        (hud-text str (* 4 s) (+ (portrait-hud-bottom s) s) (* 1.2 s) *dim*)
        (hud-text str (floor w 2) (* 0.13 h) (* 2 s) *dim* :align :center))))

;;; ---------------------------------------------------------------- debug (80000-80999; DUEL_GAMEPLAY.md)
(defun endless-debug-clear ()
  "Debug 80980: clear the running stage now (P2's last Konpaku: the K.O. path to STAGE CLEAR)."
  (when (and (endless-p) (member *flow* '(:intro :battle)))
    (setf (gauges-konpaku (gauges *p2*)) 0)
    (match-over *p1*)))

(defun endless-debug-bankai ()
  "Debug 80981: P1 into his kit's form with a :bankai-form (awakened, Konpaku 4), then that Bankai (BANKAI!)."
  (let* ((e *p1*) (g (gauges e)) (cup (find-if #'kit-bankai-form (gethash (fighter-character (fighter e)) *kits*) :key #'cdr)))
    (if (not cup)
        (log-msg "duel endless debug: no bankai for ~(~a~)" (fighter-character (fighter e)))
        (progn (set-form e (car cup))
               (setf (gauges-awakened g) t (gauges-awaken g) 0f0 (gauges-konpaku g) 4 (gauges-meter g) 100f0)
               (bankai! e)))))

(defun endless-debug-form (k)
  "Debug 80982+k: P1 into his kit's K-th form (definition order: 0 the base) with its meter full, awakened as the form
is, then the clear (80980): STAGE CLEAR with that form's carry."
  (let* ((e *p1*) (g (gauges e)) (f (car (nth k (reverse (gethash (fighter-character (fighter e)) *kits*))))))
    (when f
      (set-form e f)
      (setf (gauges-awakened g) (kit-awakening (kit-of e)) (gauges-meter g) (f32 (or (getf (kit-meter (kit-of e)) :max) 0))))
    (endless-debug-clear)))

(defun endless-auto-next ()
  "The autopilot: the queue's next run (P1 its character, the run seed, NORMAL floor), or the summary per character."
  (if *endless-queue*
      (destructuring-bind (c seed) (pop *endless-queue*)
        (setf *mode* :endless *picks* (list c c) *difficulty* :normal *endless-seed* seed)
        (endless-start :debug t))
      (progn
        (dolist (c *roster*)
          (let ((st (sort (loop for (rc n) in *endless-runs* when (eq rc c) collect n) #'<)))
            (when st
              (log-msg "duel endless gate P1 ~(~a~) policy ~(~a~) runs ~d median ~a stages ~a" c *endless-auto* (length st)
                       (nth (floor (length st) 2) st) st))))
        (setf *endless-auto* nil *turbo* nil *skip-cines* nil)
        (go-title))))

(defun endless-debug (k)
  "Debug 80000+K: 100c+n (n 1-99) a debug run of roster c from stage n (seed 1, fresh, no record); 980 clear the stage;
981 P1's Bankai; 982+f P1 in his f-th form, then clear; 990+p the autopilot (p 0 stay / 1 revert) over every character x
seeds 1-20; 992+p the autopilot once (P1's pick, seed 1)."
  (cond ((= k 980) (endless-debug-clear))
        ((= k 981) (endless-debug-bankai))
        ((<= 982 k 989) (endless-debug-form (- k 982)))
        ((<= 990 k 993)
         (setf *endless-auto* (if (evenp k) :stay :revert) *endless-runs* nil *turbo* t *skip-cines* t
               *endless-queue* (if (< k 992)
                                   (loop for c in *roster* append (loop for seed from 1 to 20 collect (list c seed)))
                                   (list (list (first *picks*) 1))))
         (endless-auto-next))
        (t (let ((c (nth (floor k 100) *roster*)) (n (mod k 100)))
             (when (and c (plusp n))
               (setf *mode* :endless *picks* (list c c) *endless-seed* 1 *one-hand* (one-hand-effective-p))
               (let ((*skip-cines* t)) (endless-start :debug t :stage n)))))))
