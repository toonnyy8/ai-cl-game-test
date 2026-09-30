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
  (guard nil)                   ; guard gauge a block drains (GUARD-VALUE; NIL = a hazard's *GG-HAZARD*)
  (frost 0 :type fixnum)        ; frames of frost a real hit sets (FROST-NEXT; Rukia's ice)
  (flags nil))                  ; :breaker :guard-crush :unguardable :ranged :ice

(defstruct (move (:conc-name mv-))
  "A move: frame data, hit windows and hooks. See DEFMOVE for the fields."
  (name nil) (kind nil) (clip nil) (clip-2 nil) (callout nil)
  (s 0 :type fixnum) (a 0 :type fixnum) (r 0 :type fixnum) (whiff 0 :type fixnum)
  (dmg 0 :type fixnum) (adv-block nil) (track 0.0) (reach 0.0)
  (hits #() :type simple-vector)
  (cost nil) (hold nil) (slide 0.0) (flags nil)
  (armor-hits 0 :type fixnum) (cooldown 0 :type fixnum)
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
                         (enter 0) (blend 0.0) planted clip-s guard (armor-hits 0) (cooldown 0) (frost 0))
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
           (flags (if breaker (adjoin :breaker flags) flags))
           (guard (guard-value kind adv-block guard)))
      (flet ((window (from to &key (dmg dmg) (on-hit react) (kb kb) ((:vol hit-vol)) ((:reach hit-reach))
                                   (chip chip) (meter meter) (flags flags) (hs hs) stun (guard guard) (frost frost))
               ;; a window's own :reach / :vol (scaled like the move's), else the move's volume
               (let ((v (cond (hit-reach (list* :arc (* reach-mult hit-reach) arc height))
                              (hit-vol (scale-vol-spec hit-vol reach-mult))
                              (t vol))))
                 (make-hitwin :from (+ from startup-add) :to (+ to startup-add) :dmg dmg :react on-hit
                              :kb kb :hs hs :chip chip :meter meter :flags flags :stun stun :guard guard :frost frost
                              :vols (and v (list (make-vol (first v) (rest v))))))))
        (make-move
         :name name :kind kind :clip clip :clip-2 clip-2 :callout callout
         :s s :a a :r r :whiff (or whiff (if breaker *breaker-whiff* (+ r (case kind (:quick *whiff-extra-j*) (:flash *whiff-extra-k*) (t *whiff-extra*)))))
         :dmg dmg :adv-block (if breaker (or adv-block :guard-break) adv-block)
         :track (or track (case kind (:quick *track-quick*) (:breaker *track-breaker*) (:kikon *kikon-track*) (t *track-heavy*)))
         :reach (or reach 0.0)
         :hits (coerce (cond (hits (loop for h in hits collect (apply #'window h)))
                             ((and (plusp dmg) vol) (list (window (- s startup-add) (+ (- s startup-add) a)))))
                       'simple-vector)
         :cost cost :hold hold :slide slide :flags flags :armor-hits armor-hits :cooldown cooldown
         :on-frame (loop for (f hook) in on-frame collect (list (+ f startup-add) hook))
         :tick tick :release release :on-land on-land :cine cine :params params :spec spec
         :enter (if (plusp enter) (+ enter startup-add) 0) :blend blend :planted planted
         :clip-speed (if (and startup (or clip-s (/= 0 startup-add))) (/ (or clip-s startup) (float s)) 1.0))))))

(defun register-move (name spec)
  (let ((spec (resolve-tuning spec)))
    (setf (gethash name *moves*) (parse-move name spec))))

(defmacro defmove-copy (name of &rest overrides)
  "Move NAME: a copy of move OF (its plist, :enter and all) under another name: a switched string link (J2s, K2s),
whose kit string allows only the new button (docs/DUEL_STRINGS.md §2.1; no new clip). OVERRIDES: keys that replace
OF's (they go first in the plist, so DEFMOVE's &key takes them: the Bankai's MAPPUTATSU is LEAP CLEAVE with its own
callout and cinematic)."
  `(register-move ,name (append ',overrides (mv-spec (find-move ,of)))))

(defun string-grid (grid)
  "A kit's :grid (J1 J2 J3 K1 K2 K3 J2s K2s) as its :strings: up to three links, each J (:q) or K (:f), switching
at most once (JJJ JJK JKK KKK KKJ KJJ). After a switch the alias (J2s after K1, K2s after J1) goes on only with the
new button."
  (destructuring-bind (j1 j2 j3 k1 k2 k3 j2s k2s) grid
    `((,j1 :q ,j2) (,j1 :f ,k2s) (,k1 :f ,k2) (,k1 :q ,j2s) (,j2 :q ,j3) (,j2 :f ,k3) (,k2 :f ,k3) (,k2 :q ,j3)
      (,j2s :q ,j3) (,k2s :f ,k3))))

(defmacro defmove (name &rest spec)
  "One move as ONE plist (critique-design §3.4). Keys:
  :kind     :quick :flash :sig :sp :breaker :kikon (sets the defaults of :track, :hs; a :breaker
            takes S/A/R, whiff, damage, reach, knockback from tuning.lisp unless given; a :kikon is
            the Kikon rush: :params (:aura f :aim deg/s :speed m/s :dash-max f :dash-track deg/s, 0 =
            locked at take-off), then its own strike S/A/R, and :cine)
  :clip :clip-2  clip names (§5; :clip-2 = the second part: throw, strike, cut, flurry)
  :clip-s   the startup the :clip-2 / :clip was authored with (a clip reused at another startup
            plays at clip-s / S speed, so it still reaches its hit pose on frame S)
  :callout  move name shown above the user (Signature / SP / Breaker / Kikon)
  :startup :active :recovery  frame data; :whiff  recovery after a whiff (default R + 6; a J link, :quick, R +
            *WHIFF-EXTRA-J*, a K link, :flash, R + *WHIFF-EXTRA-K*)
  :dmg :adv-block  damage and block advantage (§5 table; NIL = no melee block data)
  :track    deg/s turn during startup; :reach metres; :arc degrees; :height (y0 y1) of the arc;
  :vol      explicit volume (:arc r deg y0 y1 | :cap a b h r | :sph fwd up r) instead of reach/arc
  :on-hit   reaction; :kb knockback m; :hs hitstop f; :chip block chip fraction; :meter kit meter gain
  :guard    guard gauge a block drains (default by kind, GUARD-VALUE)
  :armor-hits  hits the move's armour takes (move frames *ARMOR-FROM* .. S-1; a Kikon rush: its dash)
  :cooldown frames before its command may start again (from the move start; kept through resets)
  :cost     Reiatsu bars (default by command, KIT-COMMAND-COST); :hold (min max) frames the button
            is held before the move proper (charge / stance); :slide metres moved during the move
  :flags    :ender (a string's link 3, J3 / K3: a hit on it opens the O ender, docs/DUEL_STRINGS.md §2.4)
            :breaker :guard-crush :stance :parry (a parry move: *PARRY-WINDOW*) :cancel (a Signature
            that may cancel a landed Quick / Flash, like an SP) :bind (South: the CPU's trap reflex)
            :ranged (a hit delivered by fire / a ground line, not the blade: like a hazard, no parry catches it;
            with :params (:melee-range r) only beyond r of the attacker: nearer it is the blade, a melee hit;
            one window, so it still hits once)
  :frost    frames of frost a real hit sets (the victim walks and runs x*FROST-SLOW*: Rukia's ice)
  :hits     ((from to &key dmg on-hit kb vol reach chip meter flags hs guard frost) ...) multi-hit windows;
            default: one window [S, S+A) when the move has damage and a volume
  :on-frame ((frame hook) ...), :tick hook (every frame), :release hook (button released during
            :hold), :on-land hook (first hit connects), :cine hook (Kikon cinematic)
  :params   free plist for the hooks (projectile speed, flurry hits ...)
  :enter    start at this move frame (skips that much of the wind-up and of the clip): a string
            link that must combo after a J and a K link alike (every K2 / K3: S_eff 14); a derived form adds its startup-add to it
  :blend    crossfade frames into the clip (default 0, attacks snap); :planted  weapon planted
            in the ground during the strike (drawn with DRAW-PLANTED-WEAPON)
  hits: :stun  hitstun override (frames)
  flags also: :rend (armour and a stance don't stop it: RESOLVE-CONTACT) :grab (a grab: the CPU never guards it)"
  `(register-move ,name ',spec))

;;; ================================================================ kits
(defparameter *kit-commands* '(:q :f :sig :sp1 :sp2 :breaker :kikon)
  "Commands every kit form maps to a move (:step :hoho :burst :awaken are universal).")

(defstruct (kit (:conc-name kit-))
  "One character in one form. See DEFKIT for the fields."
  (character nil) (form nil) (inherit nil) (name nil)
  (awakening nil) (awaken-form nil) (duration nil) (burn 0.0)
  (mult 1.0) (taken 1.0) (guard-to nil) (drop-to nil) (keep nil) (cornered 0.0) (cornered-max 0.0) (passives nil) (blade-chip nil)
  (walk 3.0) (run 8.0) (run-clips '(:sh-run :sh-skate-b :sh-slide-r :sh-slide-l)) (reishi *reishi-max*) (body nil) (weapon nil) (stance nil) (hide nil) (aura nil)
  (intro nil) (win nil) (intro-callout nil) (intro-weapon nil) (callout nil)
  (swing-sfx nil) (absorb-sfx nil)
  (enter-clips nil) (enter-hook nil) (exit-hook nil)
  (meter nil) (reset-reiatsu 0.0) (ai nil) (cine nil) (blade nil) (grade nil)
  (kikon-konpaku 2 :type fixnum)        ; Konpaku a Kikon of this form removes (read at rush start)
  (meter-gain nil)                      ; NOME gains (:dealt :taken :drunk) per point
  (form-name nil)                       ; the form's name on the HUD (default its keyword)
  (drink-clip nil)                      ; the clip of a drunk hit (DRINK)
  (respect-callout nil)                 ; said when the opponent outplays him (a counter-hit, a perfect Hoho, a parry, a Burst)
  (bankai-form nil)                     ; P (red, free) in this form enters that form (Kenpachi's cup 3 -> :bankai)
  (pips nil)                            ; the arm meter UDE (:n :cmds :to): a form whose heavy commands spend pips
  (crush-hook nil)                      ; called instead of the :drop-to switch when the ward breaks (Rukia's CRACK)
  (rooted nil)                          ; no Step, Hoho, run, move slide or string chase in this form (Rukia's zero)
  (field nil)                           ; the cold field (:r :away :step) round this fighter (Rukia's awakened bands)
  (warm 0.0)                            ; a :temp meter's warming, cold per second while not guarding
  (cold nil)                            ; plist command -> cold it spends (a :temp meter); L is refused without it
  (frost-touch 0 :type fixnum)          ; frames of frost every real hit of this form sets
  (reset-form nil)                      ; a Kikon / Soul Break reset puts the fighter in this form
  (u-tag nil)                           ; the HUD's tag for what U does in the form (default by its passives)
  (calm nil)                            ; the face never shouts in this form (a look: MAIN.LISP FACE-OF)
  (stun-tolerance nil)                  ; the hidden stun it takes (NIL: *STUN-TOLERANCE*; STUN-TOLERANCE-OF)
  (gg-regen 1.0)                        ; x the guard gauge's refill rate in this form, not guardless (rules GG-REGEN)
  (l-after-k nil)                       ; L chained after a K link (docs/DUEL_STRINGS.md §12): T its L, or a move (a combo copy)
  (l-after-j nil)                       ; ... after a J link (J1 / J2 / J2s / J3): T its L, or a move
  (hooks nil)                           ; plist hook point -> the character file's function (KIT-HOOK; docs/DUEL_DESIGN.md
                                        ; "Character code layout")
  (endless-form nil)                    ; ENDLESS: the form a stay-awakened carry starts the next stage in (endless-rules.lisp)
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
  "The string follow-up of MOVE-NAME for COMMAND (J1 -q-> J2, J2 -f-> K3 ...), a MOVE or NIL."
  (loop for (from cmd to) in (kit-strings kit)
        when (and (eq from move-name) (eq cmd command)) return (kit-move kit to)))
(defun move-follows-p (kit mv next)
  "Is move NEXT a continuation of move MV in KIT: its string follow-up for any button (a latched J / K link, a :land
follow-up a hook starts: SP2's punch) or, after a link 3 (:ender), the O ender's rush? (The arm's pending burst waits
through the whole chain: combat.lisp ARM-STEP.)"
  (or (loop for (from nil to) in (kit-strings kit) thereis (and (eq from (mv-name mv)) (eq (kit-move kit to) next)))
      (and (member :ender (mv-flags mv)) (eq (mv-kind next) :kikon) t)))

(defun string-link-p (kit move-name)
  "Does MOVE-NAME go on as a J / K string (a :q or :f follow-up)? While it runs every J / K press is taken by the
latch (STRING-LATCH); link 3 has none, so presses there are plain buffered presses (a new J1 after it)."
  (and (or (kit-next kit move-name :q) (kit-next kit move-name :f)) t))
(defun kit-k-link-p (kit move-name)
  "Is MOVE-NAME a K link of KIT's J / K strings: K1 (the :f command's move), or an :f follow-up (K2, K2s, K3)?"
  (or (eq move-name (getf (kit-commands kit) :f))
      (loop for (nil cmd to) in (kit-strings kit) thereis (and (eq cmd :f) (eq to move-name)))))
(defun kit-j-link-p (kit move-name)
  "Is MOVE-NAME a J link of KIT's J / K strings: J1 (the :q command's move), or a :q follow-up (J2, J2s, J3)?"
  (or (eq move-name (getf (kit-commands kit) :q))
      (loop for (nil cmd to) in (kit-strings kit) thereis (and (eq cmd :q) (eq to move-name)))))
(defun kit-l-link (kit move-name)
  "The L link after string link MOVE-NAME (docs/DUEL_STRINGS.md §12): after a K link the kit's :l-after-k, after a J
link its :l-after-j; the form's L (T) or the named copy of it, a MOVE; NIL when the form has none for that link."
  (let ((l (cond ((kit-k-link-p kit move-name) (kit-l-after-k kit)) ((kit-j-link-p kit move-name) (kit-l-after-j kit)))))
    (and l (if (eq l t) (kit-command-move kit :sig) (kit-move kit l)))))
(defun string-latch (kit move-name command queued)
  "The latch (docs/DUEL_STRINGS.md §2.1, §2.3): a J / K press (COMMAND :q / :f) during string link MOVE-NAME, with
QUEUED latched so far. The new latched command: COMMAND when the string may go on with it (the last press wins),
else QUEUED: the press is eaten (after a switch the original button is ignored and overwrites nothing)."
  (if (kit-next kit move-name command) command queued))
(defun kit-command-cost (kit command)
  "Reiatsu bars COMMAND's move costs: its :cost, else SP1 / SP2 *COST-SP* (SP2 in an awakened form
*COST-SP-AWAKENED*), else 0."
  (let ((mv (kit-command-move kit command)))
    (or (and mv (mv-cost mv))
        (case command
          (:sp1 *cost-sp*)
          (:sp2 (if (kit-awakening kit) *cost-sp-awakened* *cost-sp*))
          (t 0)))))
(defun kit-hook (kit point)
  "The character file's function for hook POINT in KIT (its :hooks plist), or NIL: the generic code calls it where the
point is (docs/DUEL_DESIGN.md \"Character code layout\")."
  (getf (kit-hooks kit) point))
(defvar *char-debug* nil "(lo hi fn): debug commands LO..HI a character file handles (debug.lisp calls FN with the command).")
(defun kit-pip-cmd-p (kit command)
  "Does COMMAND spend a pip of the arm meter in KIT (its :pips :cmds)?"
  (and (member command (getf (kit-pips kit) :cmds)) t))
(defun kit-kikon-cine (kit)
  "The cinematic a Soul Break by a fighter in KIT plays (the user's decision 2026-09-27): the form's own (its :hooks
:soul-break-cine, a cinematic's name), else its Kikon cinematic, the one its O would play now (its :kikon move's :cine),
else the generic SOUL-BREAK-CINE."
  (let ((mv (kit-command-move kit :kikon)))
    (or (kit-hook kit :soul-break-cine) (and mv (mv-cine mv)) 'soul-break-cine)))
(defun stun-tolerance-of (kit) "The hidden stun KIT's form takes (its :stun-tolerance, else *STUN-TOLERANCE*)." (or (kit-stun-tolerance kit) *stun-tolerance*))
(defun kit-drop (kit cmd)
  "The form a kit command CMD drops KIT's form to first (its :drop-to, unless CMD is in its :keep: Bankai West's
attacks but SP1 / L go back to East), or NIL."
  (and (kit-drop-to kit) (not (member cmd (kit-keep kit))) (kit-drop-to kit)))

(defun kit-atk-mods (kit lost &optional (pierce 1.0))
  "The attacker plist for HIT-DAMAGE: the form's multiplier (x PIERCE: 1 + Bankai East's pierce k on a hit) and
Cornered with LOST Konpaku."
  (list :mult (* (kit-mult kit) pierce) :cornered (kit-cornered kit) :cornered-max (kit-cornered-max kit) :lost lost))
(defun kit-def-mods (kit)
  "The defender plist for HIT-DAMAGE: the damage the form takes (:taken)."
  (list :mult (kit-taken kit)))
(defun kit-clips (kit)
  "Every clip name the form uses (moves, stance, intro/win, entry cinematic, the run)."
  (remove-duplicates
   (remove nil (append (list (kit-stance kit) (kit-intro kit) (kit-win kit)) (kit-enter-clips kit) (kit-run-clips kit) (list (kit-drink-clip kit))
                       (loop for mv being the hash-values of (kit-moves kit)
                             collect (mv-clip mv) collect (mv-clip-2 mv))))))

(defun register-kit (character form spec)
  (let* ((spec (resolve-tuning spec))
         (parent (and (getf spec :inherit) (find-kit character (getf spec :inherit))))
         (pspec (and parent (kit-spec parent)))
         (commands (append (getf spec :commands) (and parent (kit-commands parent))))
         (strings (append (getf spec :strings) (and (getf spec :grid) (string-grid (getf spec :grid)))
                          (and parent (kit-strings parent))))
         ;; the child's keys come first, so they win (&key takes the leftmost)
         (merged (list* :commands commands :strings strings
                        (append spec (loop for (k v) on pspec by #'cddr
                                           unless (member k '(:inherit :startup-add :reach-mult :grid))
                                             append (list k v))))))
    (destructuring-bind (&key inherit name awakening awaken-form duration (burn 0.0) (mult 1.0) (taken 1.0) guard-to drop-to keep
                           (cornered 0.0) (cornered-max 0.0) passives blade-chip (walk 3.0) (run 8.0)
                           (run-clips '(:sh-run :sh-skate-b :sh-slide-r :sh-slide-l)) (reishi *reishi-max*)
                           body weapon stance hide aura intro win intro-callout intro-weapon callout swing-sfx absorb-sfx
                           enter-clips enter-hook exit-hook meter (reset-reiatsu 0.0) ai cine blade grade
                           kikon-konpaku meter-gain form-name drink-clip respect-callout bankai-form pips
                           crush-hook rooted field (warm 0.0) cold (frost-touch 0) reset-form u-tag l-after-k l-after-j calm hooks endless-form
                           stun-tolerance (gg-regen 1.0) (startup-add 0) (reach-mult 1.0) commands strings grid)
        merged
      (declare (ignore grid))
      (let ((kit (make-kit :character character :form form :inherit inherit :name name
                           :awakening awakening :awaken-form awaken-form :duration duration :burn burn
                           :mult mult :taken taken :guard-to guard-to :drop-to drop-to :keep keep :cornered cornered :cornered-max cornered-max
                           :passives passives :blade-chip blade-chip :walk walk :run run :run-clips run-clips :reishi reishi :body body
                           :weapon weapon :stance stance :hide hide :aura aura :intro intro :win win
                           :intro-callout intro-callout :intro-weapon intro-weapon :callout callout
                           :swing-sfx swing-sfx :absorb-sfx absorb-sfx
                           :enter-clips enter-clips :enter-hook enter-hook :exit-hook exit-hook
                           :meter meter :reset-reiatsu reset-reiatsu :ai ai :cine cine :blade blade :grade grade
                           :kikon-konpaku (or kikon-konpaku (if awakening *kikon-konpaku-awakened* *kikon-konpaku*))
                           :meter-gain meter-gain :form-name (or form-name (symbol-name form)) :drink-clip drink-clip
                           :respect-callout respect-callout :bankai-form bankai-form :pips pips
                           :crush-hook crush-hook :rooted rooted :field field :warm warm :cold cold
                           :frost-touch frost-touch :reset-form reset-form :u-tag u-tag :l-after-k l-after-k :l-after-j l-after-j :calm calm :endless-form endless-form
                           :stun-tolerance stun-tolerance :gg-regen gg-regen
                           :hooks hooks :commands commands :strings strings :spec merged))
            (own (loop for (nil m) on (getf spec :commands) by #'cddr collect m)))
        ;; every move the form can reach. The derivation rule (design v2 §0): a move is as written when the
        ;; form lists it in its own :commands or the parent form doesn't have it (new to this form: its
        ;; own strings); an inherited one gets the form's derivation (:startup-add / :reach-mult), and a form
        ;; with no derivation takes the parent's version of it (Nozarashi v2 §2.8: NOMIHOSE plays RYOTE's
        ;; derived moves, not the written ones)
        (dolist (m (remove-duplicates
                    (append (loop for (nil m) on commands by #'cddr when m collect m)   ; (a NIL command: none in this form)
                            (loop for (from nil to) in strings collect from collect to)
                            (loop for l in (list l-after-k l-after-j) when (and l (not (eq l t))) collect l))))
          (let ((mv (find-move m)) (pmv (and parent (gethash m (kit-moves parent)))))
            (setf (gethash m (kit-moves kit))
                  (cond ((or (member m own) (not pmv)) mv)
                        ((and (eql startup-add 0) (= reach-mult 1)) pmv)
                        (t (parse-move m (mv-spec mv) :startup-add startup-add :reach-mult reach-mult))))))
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
  :run-clips (fwd back right left)  the run's clips (he faces the opponent: forward run, back-skate, side
                                     slides; body.lisp DEFRUN), default the shared :sh-* set
  :commands (:q m :f m :sig m :sp1 m :sp2 m :breaker m :kikon m)   see *KIT-COMMANDS*
  :grid (J1 J2 J3 K1 K2 K3 J2s K2s)  the J / K strings as one grid (STRING-GRID), added to :strings
  :strings ((from-move command to-move) ...)   the J / K grid (docs/DUEL_STRINGS.md §1): J1 -q-> J2 -q-> J3,
                                     J1 -f-> K2s -f-> K3 ... (a switched link-2 alias allows only the new
                                     button: J / K switch at most once); a non-button command (:land) names a
                                     follow-up a hook starts (KIT-NEXT), so derived forms derive it too
  :mult :cornered :cornered-max      §4 damage dealt (KIT-ATK-MODS)   :taken  damage x taken (KIT-DEF-MODS)
  :passives (:ward :pierce :projectile-cut :scorch :cut :drink)   :blade-chip fraction
                                     (:ward: Bankai West blocks 360 deg in his free states and own moves, with
                                     no blockstun, drains x*WARD-MULT*, never refills; :pierce: Bankai East's
                                     hits x(1 + k), k of a blocked hit goes through (PIERCE-RATE); :scorch: his
                                     parry burns; :cut: his heavy hits drain guard x*CUT-MULT*; :drink: U drinks:
                                     combat.lisp)
  :guard-to FORM                     U (held, from idle / walk / run) switches to FORM instead of guarding
                                     (Bankai East -> West)
  :drop-to FORM :keep (cmd ...)      any kit command not in :keep switches to FORM on its frame 0 and starts
                                     FORM's move (Bankai West: every attack but SP1 / L goes back to East)
  :awakening T (an awakened form)    :awaken-form FORM (what Awaken turns this character into)
  :duration seconds (NIL = permanent; then back to :inherit)   :burn Reishi fraction/s
  :startup-add :reach-mult           derive the inherited moves (not inherited themselves)
  :meter (:name :max :full-form)     the character's meter (Inferno -> :hellfire)
  :enter-clips :enter-hook :exit-hook  form change presentation
  :swing-sfx :absorb-sfx             sounds of a non-Quick swing (default :whoosh-heavy) and of a
                                     hit the stance absorbs (Kenpachi's laugh)
  :cine SYMBOL                       the DEFCINE played when the form is entered (awakening)
  :kikon-konpaku n                   Konpaku a Kikon removes in this form (default 2, awakened 3; read when the
                                     rush starts; a Soul Break +1, at most *KIKON-MAX-EVENT*)
  :meter (... :start n :ladder ((form drain/s delay up-at down-below) ...))   a meter that picks the form
                                     (Nozarashi's NOME: rules LADDER-RUNG, combat.lisp NOME-STEP); :start = its value
                                     at the awakening
  :meter-gain (:dealt :taken :drunk) the meter per point dealt / lost / drunk (DRINK, the stance's absorb)
  :form-name :drink-clip :respect-callout  the HUD's form name; the clip of a drunk hit; the callout when the
                                     opponent outplays him
  :bankai-form FORM                  P, red and free, enters FORM (Kenpachi's cup 3: the Bankai, docs/DUEL_KEN_BANKAI.md)
  :pips (:n :cmds (cmd ...) :to FORM)  the arm meter (the kit meter holds the pips): each command in :cmds (and every
                                     latched K link) spends one on its frame 0 (refused at 0); at 0 the arm bursts to
                                     FORM (combat.lisp ARM-STEP)
  :crush-hook SYMBOL                 a broken ward calls it instead of dropping to :drop-to (Rukia's CRACK)
  :rooted T                          no Step / Hoho / run, no move slide or string chase   :reset-form FORM  the form
                                     after a Kikon reset
  :l-after-k T | MOVE                L latched during a K link (K1 / K2 / K2s / K3) starts when that link's chain opens
                                     (its own contact, docs/DUEL_STRINGS.md §12): T the form's L, else MOVE, a combo copy
  :l-after-j T | MOVE                the same after a J link (J1 / J2 / J2s / J3)
  :calm T                            the face stays calm (no shout: a look, FACE-OF)
  :gg-regen x                        x the guard gauge's refill rate in this form (default 1.0)
  :stun-tolerance n                  the hidden stun the form takes before the blow-away (default *STUN-TOLERANCE*;
                                     a derived form inherits it)
  :hooks (point fn ...)              the character's own mechanics (KIT-HOOK; DUEL_DESIGN.md, Character code
                                     layout): :u (e: U pressed; the form never guards), :step (e: a Step's frame 0), :hoho (e: a Hoho reappears),
                                     :ok (e cmd combo: may the command start; NIL refuses it with the :refused cue),
                                     :tick (e f g: every sim step), :hit / :struck (e other res hw mv hazard ranged: after
                                     a hit it dealt / took), :parried (e att: a catch by its parry), :draw (e rdt: looks
                                     on the posed body), :hud-guard (drawn over its guard bar), :deck (e x y d: the
                                     one-hand thumb ring)
  :endless-form FORM                 ENDLESS: staying awakened starts the next stage in FORM, its meter at FORM's :start
                                     (docs/DUEL_ENDLESS.md §4)
  :u-tag STRING                      the HUD's tag for U   :meter (:name :max :temp t)  Rukia's cold gauge (combat.lisp
                                     TEMP-STEP: the kit meter holds the cold C, the band is the form, rules TEMP-BAND)
  :warm n  :cold (cmd n ...)         a :temp form's warming per second; the cold each command spends (L refused without)
  :field (:r :away :step)            the cold field: the opponent within :r m moves away from her x :away, Steps away x :step
  :frost-touch n                     every real hit of the form frosts n frames
  :blade (look power)                blade look drawn along the held weapon: (:fire 1.0) (:embers 1.0)
  :grade                             the world's grade while the form is on: NIL, or :SPOT (grey but the ember
                                     hue: the composite's spot-keep mode, main.lisp FORM-GRADE)
  :intro :win :intro-callout :callout  clips / texts; :intro-weapon (key frame) = a prop held in the
                                     intro clip until FRAME (Yamamoto's cane)   :reset-reiatsu  bonus at each Kikon reset
  :ai (:intents plist :ranges plist :moves ((lo hi cmd w ...) ...) :guard p :hoho p :kikon-range m
       :awaken-above reishi-fraction :react plist :sp-cancel-bars n :oki cmd :oki-above fraction
       :dash p :dash-back p)   CPU identity (§8, ai.lisp)"
  `(register-kit ,character ,form ',spec))
