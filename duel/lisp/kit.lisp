;;;; kit.lisp — characters as data (design-v1 §5, §12): DEFMOVE (one plist per move) and DEFKIT
;;;; (one plist per character form), parsed at load into MOVE / HITWIN / KIT structs. The generic
;;;; fighter code reads only these structs; what a character does beyond the data is a hook: a
;;;; SYMBOL in the data (:on-frame ((40 yama-fire-wave)), :tick, :release, :on-land, :cine,
;;;; :enter-hook, :exit-hook), called with FUNCALL. Kits load before the hook DEFUNs (one
;;;; compilation unit), so #' would fail at load time: hooks stay symbols.
;;;; Numbers in the data may name a tuning knob: *EARMUFFED* symbols are replaced by their value
;;;; at load (RESOLVE-TUNING), so tuning.lisp stays the one place for shared numbers.
;;;; Frames: a move's frame SF counts from 0 (its first frame); startup S, active A, recovery R;
;;;; hit windows [from, to) in move frames. Plain CL: loaded on the host by the rules test.
(in-package :duel)

(defun tuning-ref-p (x)
  (and (symbolp x) x (not (keywordp x)) (not (eq x t))
       (let ((n (symbol-name x)))
         (and (> (length n) 2) (char= (char n 0) #\*) (char= (char n (1- (length n))) #\*)))))

(defun resolve-tuning (tree)
  "TREE with every *EARMUFFED* symbol replaced by its value."
  (cond ((tuning-ref-p tree) (symbol-value tree))
        ((consp tree) (cons (resolve-tuning (car tree)) (resolve-tuning (cdr tree))))
        (t tree)))

;;; ================================================================ moves
(defstruct (hitwin (:conc-name hw-))
  "One active window of a move: [FROM, TO) in move frames, its damage and effect on hit."
  (from 0 :type fixnum) (to 0 :type fixnum)
  (dmg 0 :type fixnum)
  (vols nil)                    ; list of volumes (MAKE-VOL, rules.lisp) in the attacker's frame
  (react :flinch)               ; :flinch :stagger :knockback :launch :knockdown
  (kb 0.0)                      ; knockback slide, metres
  (hs 0 :type fixnum)           ; global hitstop frames
  (chip nil)                    ; chip fraction on block, NIL = none
  (meter 0.0)                   ; the kit meter (Inferno) gained on hit
  (stun nil)                    ; hitstun override in frames (NIL = the reaction's, *REACTION-FRAMES*)
  (flags nil))                  ; :breaker :guard-crush

(defstruct (move (:conc-name mv-))
  "A move: frame data, hit windows and hooks. See DEFMOVE for the fields."
  (name nil) (kind nil) (clip nil) (clip-2 nil) (callout nil)
  (s 0 :type fixnum) (a 0 :type fixnum) (r 0 :type fixnum) (whiff 0 :type fixnum)
  (dmg 0 :type fixnum) (adv-block nil) (track 0.0) (reach 0.0)
  (hits #() :type simple-vector)
  (cost nil) (hold nil) (slide 0.0) (flags nil)
  (on-frame nil) (tick nil) (release nil) (on-land nil) (cine nil) (params nil)
  (enter 0 :type fixnum)        ; the move starts at this frame (its clip too): a faster string branch
  (clip-speed 1.0)              ; clip playback speed: the clip's startup (:clip-s, else the base
                                ; startup of a derived form) / this startup, so it hits on frame S
  (blend 0.0)                   ; crossfade frames into the clip (0 = snap, attacks)
  (planted nil)                 ; the weapon is planted in the ground during the strike (Ikkotsu)
  (spec nil))                   ; the DEFMOVE plist (resolved), re-parsed for derived forms

(defun mv-total (mv) "S + A + R." (+ (mv-s mv) (mv-a mv) (mv-r mv)))
(defun mv-first-hit (mv) "Frame of the first hit window (or S)."
  (if (plusp (length (mv-hits mv))) (hw-from (svref (mv-hits mv) 0)) (mv-s mv)))

(defvar *moves* (make-hash-table :test 'eq) "Move name -> MOVE, as written in the kit files.")
(defun find-move (name) (or (gethash name *moves*) (error "unknown move ~s" name)))

(defun scale-vol-spec (spec m)
  "Volume spec (kind . args) with its lengths x M (reach)."
  (destructuring-bind (kind &rest a) spec
    (ecase kind
      (:arc (list* :arc (* m (first a)) (rest a)))
      (:cap (list* :cap (* m (first a)) (* m (second a)) (cddr a)))
      (:sph (list :sph (* m (first a)) (second a) (* m (third a))))
      (:tsph spec))))

(defun vol-spec-reach (spec)
  (destructuring-bind (kind &rest a) spec
    (ecase kind (:arc (first a)) (:cap (second a)) (:sph (+ (first a) (third a))) (:tsph 0.0))))

(defun parse-move (name spec &key (startup-add 0) (reach-mult 1.0))
  "SPEC (a resolved DEFMOVE plist) -> MOVE. STARTUP-ADD / REACH-MULT derive a form's version
(Nozarashi): every frame from the startup on shifts, every reach scales."
  (destructuring-bind (&key kind clip clip-2 callout startup active recovery whiff (dmg 0) adv-block
                         track reach (arc 90) (height '(0.2 2.0)) vol on-hit (kb 0.0) hs chip (meter 0.0)
                         cost hold (slide 0.0) flags hits on-frame tick release on-land cine params
                         (enter 0) (blend 0.0) planted clip-s)
      spec
    (let* ((breaker (eq kind :breaker))
           (s (+ startup-add (or startup (if breaker *breaker-startup* 0))))
           (a (or active (if breaker *breaker-active* 0)))
           (r (or recovery (if breaker *breaker-recovery* 0)))
           (dmg (if (and breaker (zerop dmg)) *breaker-damage* dmg))
           (reach (let ((rr (or reach (and vol (vol-spec-reach vol)) (and breaker *breaker-reach*))))
                    (and rr (* reach-mult rr))))
           (vol (cond (vol (scale-vol-spec vol reach-mult))
                      (reach (list* :arc reach arc height))))
           (react (or on-hit (if breaker :knockback :flinch)))
           (kb (if (and breaker (zerop kb)) *breaker-knockback* kb))
           (hs (or hs (case kind (:quick *hitstop-light*) (:breaker *hitstop-breaker*) (t *hitstop-heavy*))))
           (flags (if breaker (adjoin :breaker flags) flags)))
      (flet ((window (from to &key (dmg dmg) (on-hit react) (kb kb) ((:vol hit-vol)) ((:reach hit-reach))
                                   (chip chip) (meter meter) (flags flags) (hs hs) stun)
               ;; a window's own :reach / :vol (scaled like the move's), else the move's volume
               (let ((v (cond (hit-reach (list* :arc (* reach-mult hit-reach) arc height))
                              (hit-vol (scale-vol-spec hit-vol reach-mult))
                              (t vol))))
                 (make-hitwin :from (+ from startup-add) :to (+ to startup-add) :dmg dmg :react on-hit
                              :kb kb :hs hs :chip chip :meter meter :flags flags :stun stun
                              :vols (and v (list (make-vol (first v) (rest v))))))))
        (make-move
         :name name :kind kind :clip clip :clip-2 clip-2 :callout callout
         :s s :a a :r r :whiff (or whiff (if breaker *breaker-whiff* (+ r *whiff-extra*)))
         :dmg dmg :adv-block (if breaker (or adv-block :guard-break) adv-block)
         :track (or track (case kind (:quick *track-quick*) (:breaker *track-breaker*) (:kikon *kikon-track*) (t *track-heavy*)))
         :reach (or reach 0.0)
         :hits (coerce (cond (hits (loop for h in hits collect (apply #'window h)))
                             ((and (plusp dmg) vol) (list (window (- s startup-add) (+ (- s startup-add) a)))))
                       'simple-vector)
         :cost cost :hold hold :slide slide :flags flags
         :on-frame (loop for (f hook) in on-frame collect (list (+ f startup-add) hook))
         :tick tick :release release :on-land on-land :cine cine :params params :spec spec
         :enter (if (plusp enter) (+ enter startup-add) 0) :blend blend :planted planted
         :clip-speed (if (and startup (or clip-s (plusp startup-add))) (/ (or clip-s startup) (float s)) 1.0))))))

(defun register-move (name spec)
  (let ((spec (resolve-tuning spec)))
    (setf (gethash name *moves*) (parse-move name spec))))

(defmacro defmove (name &rest spec)
  "One move as ONE plist (critique-design §3.4). Keys:
  :kind     :quick :flash :sig :sp :breaker :kikon (sets the defaults of :track, :hs; a :breaker
            takes S/A/R, whiff, damage, reach, knockback from tuning.lisp unless given; a :kikon is
            the Kikon rush: aura and dash from tuning.lisp, then its own strike S/A/R, and :cine)
  :clip :clip-2  clip names (§5; :clip-2 = the second part: throw, strike, cut, flurry)
  :clip-s   the startup the :clip-2 / :clip was authored with (a clip reused at another startup
            plays at clip-s / S speed, so it still reaches its hit pose on frame S)
  :callout  move name shown above the user (Signature / SP / Breaker / Kikon)
  :startup :active :recovery  frame data; :whiff  recovery after a whiff (default R + 6)
  :dmg :adv-block  damage and block advantage (§5 table; NIL = no melee block data)
  :track    deg/s turn during startup; :reach metres; :arc degrees; :height (y0 y1) of the arc;
  :vol      explicit volume (:arc r deg y0 y1 | :cap a b h r | :sph fwd up r) instead of reach/arc
  :on-hit   reaction; :kb knockback m; :hs hitstop f; :chip block chip fraction; :meter kit meter gain
  :cost     Reiatsu bars (default by command, KIT-COMMAND-COST); :hold (min max) frames the button
            is held before the move proper (charge / stance); :slide metres moved during the move
  :flags    :breaker :guard-crush :stance
  :hits     ((from to &key dmg on-hit kb vol reach chip meter flags hs) ...) multi-hit windows;
            default: one window [S, S+A) when the move has damage and a volume
  :on-frame ((frame hook) ...), :tick hook (every frame), :release hook (button released during
            :hold), :on-land hook (first hit connects), :cine hook (Kikon cinematic)
  :params   free plist for the hooks (projectile speed, flurry hits ...)
  :enter    start at this move frame (skips that much of the wind-up and of the clip): a string
            branch that must combo (Q2 -f-> F2); a derived form adds its startup-add to it
  :blend    crossfade frames into the clip (default 0, attacks snap); :planted  weapon planted
            in the ground during the strike (drawn with DRAW-PLANTED-WEAPON)
  hits: :stun  hitstun override (frames)"
  `(register-move ,name ',spec))

;;; ================================================================ kits
(defparameter *kit-commands* '(:q :f :sig :sp1 :sp2 :breaker :kikon)
  "Commands every kit form maps to a move (:step :hoho :burst :awaken are universal).")

(defstruct (kit (:conc-name kit-))
  "One character in one form. See DEFKIT for the fields."
  (character nil) (form nil) (inherit nil) (name nil)
  (awakening nil) (awaken-form nil) (duration nil) (burn 0.0) (heal 0)
  (mult 1.0) (cornered 0.0) (cornered-max 0.0) (passives nil) (blade-chip nil)
  (walk 3.0) (run 8.0) (reishi *reishi-max*) (body nil) (weapon nil) (stance nil) (hide nil) (aura nil)
  (intro nil) (win nil) (intro-callout nil) (intro-weapon nil) (callout nil)
  (swing-sfx nil) (absorb-sfx nil)
  (enter-clips nil) (enter-hook nil) (exit-hook nil)
  (meter nil) (reset-reiatsu 0.0) (ai nil) (cine nil) (blade nil) (grade nil)
  (commands nil)                ; plist command -> move name
  (strings nil)                 ; ((from-move command to-move) ...)
  (moves (make-hash-table :test 'eq))   ; move name -> this form's MOVE
  (spec nil))

(defvar *kits* (make-hash-table :test 'eq) "Character -> alist (form . KIT) (no consing to look one up).")
(defvar *roster* nil "Every character with a :base kit, in the order the kit files define them (select screen).")
(defun find-kit (character form)
  (or (cdr (assoc form (gethash character *kits*))) (error "unknown kit ~s ~s" character form)))

(defun kit-move (kit name)
  (or (gethash name (kit-moves kit)) (error "kit ~s ~s has no move ~s" (kit-character kit) (kit-form kit) name)))
(defun kit-command-move (kit command)
  "The move COMMAND starts from neutral, or NIL."
  (let ((name (getf (kit-commands kit) command))) (and name (kit-move kit name))))
(defun kit-next (kit move-name command)
  "The string follow-up of MOVE-NAME for COMMAND (Q1 -q-> Q2, Q2 -f-> F2 ...), a MOVE or NIL."
  (loop for (from cmd to) in (kit-strings kit)
        when (and (eq from move-name) (eq cmd command)) return (kit-move kit to)))
(defun kit-command-cost (kit command)
  "Reiatsu bars COMMAND's move costs: its :cost, else SP1 / SP2 *COST-SP* (SP2 in an awakened form
*COST-SP-AWAKENED*), else 0."
  (let ((mv (kit-command-move kit command)))
    (or (and mv (mv-cost mv))
        (case command
          (:sp1 *cost-sp*)
          (:sp2 (if (kit-awakening kit) *cost-sp-awakened* *cost-sp*))
          (t 0)))))
(defun kit-atk-mods (kit lost)
  "The attacker plist for HIT-DAMAGE: the form's multiplier and Cornered with LOST Konpaku."
  (list :mult (kit-mult kit) :cornered (kit-cornered kit) :cornered-max (kit-cornered-max kit) :lost lost))
(defun kit-clips (kit)
  "Every clip name the form uses (moves, stance, intro/win, entry cinematic)."
  (remove-duplicates
   (remove nil (append (list (kit-stance kit) (kit-intro kit) (kit-win kit)) (kit-enter-clips kit)
                       (loop for mv being the hash-values of (kit-moves kit)
                             collect (mv-clip mv) collect (mv-clip-2 mv))))))

(defun register-kit (character form spec)
  (let* ((spec (resolve-tuning spec))
         (parent (and (getf spec :inherit) (find-kit character (getf spec :inherit))))
         (pspec (and parent (kit-spec parent)))
         (commands (append (getf spec :commands) (and parent (kit-commands parent))))
         (strings (append (getf spec :strings) (and parent (kit-strings parent))))
         ;; the child's keys come first, so they win (&key takes the leftmost)
         (merged (list* :commands commands :strings strings
                        (append spec (loop for (k v) on pspec by #'cddr
                                           unless (member k '(:inherit :startup-add :reach-mult))
                                             append (list k v))))))
    (destructuring-bind (&key inherit name awakening awaken-form duration (burn 0.0) (heal 0) (mult 1.0)
                           (cornered 0.0) (cornered-max 0.0) passives blade-chip (walk 3.0) (run 8.0) (reishi *reishi-max*)
                           body weapon stance hide aura intro win intro-callout intro-weapon callout swing-sfx absorb-sfx
                           enter-clips enter-hook exit-hook meter (reset-reiatsu 0.0) ai cine blade grade
                           (startup-add 0) (reach-mult 1.0) commands strings)
        merged
      (let ((kit (make-kit :character character :form form :inherit inherit :name name
                           :awakening awakening :awaken-form awaken-form :duration duration :burn burn
                           :heal heal :mult mult :cornered cornered :cornered-max cornered-max
                           :passives passives :blade-chip blade-chip :walk walk :run run :reishi reishi :body body
                           :weapon weapon :stance stance :hide hide :aura aura :intro intro :win win
                           :intro-callout intro-callout :intro-weapon intro-weapon :callout callout
                           :swing-sfx swing-sfx :absorb-sfx absorb-sfx
                           :enter-clips enter-clips :enter-hook enter-hook :exit-hook exit-hook
                           :meter meter :reset-reiatsu reset-reiatsu :ai ai :cine cine :blade blade :grade grade
                           :commands commands :strings strings :spec merged))
            (own (loop for (nil m) on (getf spec :commands) by #'cddr collect m)))
        ;; every move the form can reach; inherited ones get the form's derivation (Nozarashi)
        (dolist (m (remove-duplicates
                    (append (loop for (nil m) on commands by #'cddr collect m)
                            (loop for (from nil to) in strings collect from collect to))))
          (let ((mv (find-move m)))
            (setf (gethash m (kit-moves kit))
                  (if (or (member m own) (and (eql startup-add 0) (= reach-mult 1)))
                      mv
                      (parse-move m (mv-spec mv) :startup-add startup-add :reach-mult reach-mult)))))
        (when (and (eq form :base) (not (member character *roster*)))
          (setf *roster* (append *roster* (list character))))
        (let ((forms (remove form (gethash character *kits*) :key #'car)))
          (setf (gethash character *kits*) (acons form kit forms)))
        kit))))

(defmacro defkit (character form &rest spec)
  "One character form as one plist. :inherit FORM takes every key of that (earlier) form; the
child's keys win, :commands merge per command, :strings add. Keys:
  :name :body :weapon :stance :hide (body part tags hidden) :aura  look (art agent's names)
  :walk :run :reishi                 stats (walk / run speed m/s)
  :commands (:q m :f m :sig m :sp1 m :sp2 m :breaker m :kikon m)   see *KIT-COMMANDS*
  :strings ((from-move command to-move) ...)   Q1 -q-> Q2 -q-> Q3, Q2 -f-> F2, F1 -f-> F2; a
                                     non-button command (:land) names a follow-up a hook starts
                                     (KIT-NEXT), so derived forms derive it too
  :mult :cornered :cornered-max      §4 damage (KIT-ATK-MODS)
  :passives (:armor-vs-quick :projectile-cut :ignore-armor)   :blade-chip fraction
  :awakening T (an awakened form)    :awaken-form FORM (what Awaken turns this character into)
  :duration seconds (NIL = permanent; then back to :inherit)   :burn Reishi fraction/s   :heal
  :startup-add :reach-mult           derive the inherited moves (not inherited themselves)
  :meter (:name :max :full-form)     the character's meter (Inferno -> :hellfire)
  :enter-clips :enter-hook :exit-hook  form change presentation
  :swing-sfx :absorb-sfx             sounds of a non-Quick swing (default :whoosh-heavy) and of a
                                     hit the stance absorbs (Kenpachi's laugh)
  :cine SYMBOL                       the DEFCINE played when the form is entered (awakening)
  :blade (look power)                blade look drawn along the held weapon: (:fire 1.0) (:embers 1.0)
  :grade                             the world's grade while the form is on: NIL, or :SPOT (grey but the ember
                                     hue: the composite's spot-keep mode, main.lisp FORM-GRADE)
  :intro :win :intro-callout :callout  clips / texts; :intro-weapon (key frame) = a prop held in the
                                     intro clip until FRAME (Yamamoto's cane)   :reset-reiatsu  bonus at each Kikon reset
  :ai (:intents plist :ranges plist :moves ((lo hi cmd w ...) ...) :guard p :hoho p
       :awaken-above reishi-fraction :react plist :sp-cancel-bars n :oki cmd :oki-above fraction
       :dash p :dash-back p)   CPU identity (§8, ai.lisp)"
  `(register-kit ,character ,form ',spec))
