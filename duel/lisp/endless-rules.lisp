;;;; endless-rules.lisp — ENDLESS 無限連戰 as pure rules (docs/DUEL_ENDLESS.md): the ramp, the opponent bag, the stage
;;;; seed, P1's carry-over between stages and the record comparison. Plain CL over kit.lisp's data (FIND-KIT and the kit
;;;; slots), so tests/duel-rules-test.lisp loads it on the host; the mode itself (state, screens, the page) is endless.lisp.
;;;; No character names in here: what a form carries over is kit data (:endless-form, :reset-form, :duration, :meter).
(in-package :duel)

(defparameter *endless-ramp*
  '((1 0 0 nil 100) (3 1 0 nil 100) (5 2 50 nil 100) (7 2 100 nil 100) (9 2 100 t 110) (12 2 100 t 120))
  "Per row, from its first stage on: (stage difficulty-steps-above-the-floor opponent-awakening-gauge opponent-awakened
opponent-reishi-%). The last row is the plateau (DUEL_ENDLESS §3).")

(defun endless-ramp (stage)
  "The ramp row in force at STAGE (1-based): (stage steps awaken awakened reishi-%)."
  (let ((row (first *endless-ramp*)))
    (dolist (r *endless-ramp* row) (when (>= stage (first r)) (setf row r)))))

(defun endless-difficulty (floor stage &optional (levels '(:easy :normal :hard)))
  "The CPU difficulty at STAGE for a run started at FLOOR: the ramp's steps above it, clamped at the last of LEVELS."
  (nth (min (1- (length levels)) (+ (or (position floor levels) 0) (second (endless-ramp stage)))) levels))

(defun endless-lcg (x) "One step of the bag's own LCG (not SIM-RND: the order never depends on the fights)." (mod (+ (* x 1103515245) 12345) 2147483648))

(defun endless-bag (seed b roster)
  "Bag B (0-based) of run SEED: a shuffle of ROSTER (Fisher-Yates on the LCG keyed on SEED and B)."
  (let ((v (coerce roster 'simple-vector)) (x (endless-lcg (+ (* seed 7919) (* b 104729) 1))))
    (loop for i from (1- (length v)) downto 1
          do (setf x (endless-lcg x))
             (rotatef (svref v i) (svref v (mod (floor x 65536) (1+ i)))))
    (coerce v 'list)))

(defun endless-opponent (seed stage roster)
  "The opponent of STAGE (1-based) in run SEED: bags of |ROSTER|, each the whole roster once; a bag whose first entry
equals the previous bag's last swaps its first two (never the same opponent twice in a row)."
  (let* ((n (length roster)) (b (floor (1- stage) n)) (prev nil) (bag nil))
    (dotimes (k (1+ b))
      (setf bag (endless-bag seed k roster))
      (when (and prev (rest bag) (eq (first bag) prev)) (rotatef (first bag) (second bag)))
      (setf prev (car (last bag))))
    (nth (mod (1- stage) n) bag)))

(defun endless-stage-seed (run stage) "The SIM-RND seed of STAGE in run RUN (a pure mix: stage n replays alone)." (mod (+ (* run 104729) (* stage 7919) 17) 1000000))

(defun endless-stay-form (kit)
  "The form KIT's fighter starts the next stage in when he stays awakened / is not awakened: its :endless-form, else its
:reset-form, else a timed form ends the way its timer would (its :inherit), else the same form."
  (or (kit-endless-form kit) (kit-reset-form kit) (and (kit-duration kit) (kit-inherit kit)) (kit-form kit)))

(defun endless-carry (snap choice)
  "P1's carry into the next stage. SNAP: plist (:character :form :konpaku :reiatsu :fs :awaken :awakened :meter) at the
clear; CHOICE :stay (CONTINUE) or :revert. Returns the plist (:form :konpaku :reiatsu :fs :awaken :awakened :meter) the
next stage applies over a fresh fighter (Reishi full and the guard gauge full come from the fresh spawn). The rules
(DUEL_ENDLESS §4, the user's decisions 2026-09-29): Konpaku + 2 (at most *KONPAKU-MAX*); Reiatsu and flash step kept;
REVERT: the base form, the awakening unused and full, the kit meter 0; otherwise the stay form (ENDLESS-STAY-FORM) with
the awakening as it was and the kit meter kept, except when the form has an :endless-form / :reset-form or the carry
changed the form (the new form's :start, else 0) or the meter is a :count meter (0)."
  (destructuring-bind (&key character form konpaku reiatsu fs awaken awakened meter) snap
    (let* ((kit (find-kit character form))
           (common (list :konpaku (min *konpaku-max* (+ konpaku 2)) :reiatsu reiatsu :fs fs)))
      (if (and (eq choice :revert) awakened)
          (list* :form :base :awaken *awaken-max* :awakened nil :meter 0.0 common)
          (let* ((to (endless-stay-form kit)) (new (find-kit character to)) (m (kit-meter new)))
            (list* :form to :awaken (if awakened 0.0 awaken) :awakened awakened
                   :meter (cond ((or (kit-endless-form kit) (kit-reset-form kit) (not (eq to form))) (float (or (getf m :start) 0)))
                                ((getf m :count) 0.0)
                                (t meter))
                   common))))))

(defun endless-better-p (stages secs best-stages best-secs)
  "Does a run of STAGES cleared in SECS beat the stored best (BEST-STAGES, BEST-SECS; 0 0 = no record)? More stages,
else less time; 0 stages is never a record."
  (and (plusp stages) (or (> stages best-stages) (and (= stages best-stages) (< secs best-secs))) t))
