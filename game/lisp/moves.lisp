;;;; moves.lisp — every attack in the game as data (GAME_DESIGN §3.2, §5): DEFMOVE, the parser that
;;;; turns a move spec into MOVE / HITDEF records (rules.lisp), REN's move set, the enemies' moves and
;;;; the stand-alone hitdefs of specials and projectiles. Frame data here is authoritative: S/A/R =
;;;; startup / active / recovery frames, hit windows [from, to) in frames from the move's start.
;;;; Who runs a move: MOVE-TICK (combat.lisp) for everyone; specials are handled by their owner.
(in-package :raven)

;;; Hit volumes: MAKE-VOL (engine/lisp/hitvol.lisp) builds each :arc / :cap / :sph / :tsph of a hit.

;;; ---------------------------------------------------------------- DEFMOVE
(defvar *moves* (make-hash-table :test 'eq))
(defun find-move (name) (or (gethash name *moves*) (error "unknown move ~s" name)))

(defun expand-hits (hits)
  (loop for h in hits
        append (destructuring-bind (from to &rest kv &key (repeat 1) (every 0) &allow-other-keys) h
                 (loop for i below repeat
                       collect (list* (+ from (* i every)) (+ to (* i every)) kv)))))

(defun parse-hit (h)
  (destructuring-bind (from to &key (dmg 0) (imp 0) arc cap sph tsph (react :flinch) (kb 0) (hs 3) hw
                                 (stun 0) (vy 0) (feet 99) flags &allow-other-keys) h
    (make-hitdef :from from :to to
                 :vols (append (and arc (list (make-vol :arc arc))) (and cap (list (make-vol :cap cap)))
                               (and sph (list (make-vol :sph sph))) (and tsph (list (make-vol :tsph tsph))))
                 :dmg (f32 dmg) :imp (f32 imp) :react react :kb (f32 kb) :hs hs :hw hw :stun (f32 stun)
                 :vy (f32 vy) :feet (f32 feet) :flags flags)))

(defun register-move (name props hits)
  (destructuring-bind (&key clip (speed 1.0) (blend 0) (s 0) (a 0) (r 0) light heavy (chain-at -1) (heavy-at -1)
                         (abort 0) sfx (pitch 1.0) hw (magnet :auto) iframes slide air hang red ravenable jump special)
      props
    (let* ((hd (map 'simple-vector #'parse-hit (expand-hits hits)))
           (reach (let ((m 0.0))
                    (loop for h across hd do
                      (dolist (v (hd-vols h))
                        (setf m (max m (case (round (aref v 0))
                                         (0 (aref v 1)) (1 (aref v 2)) (2 (+ (aref v 1) (aref v 3))) (t 0.0))))))
                    m))
           (tf (if (plusp (length hd)) (reduce #'min hd :key #'hd-from) s))
           (tt (if (plusp (length hd)) (reduce #'max hd :key #'hd-to) (+ s a))))
      (setf (gethash name *moves*)
            (make-move :name name :clip clip :clip-speed (f32 speed) :blend (f32 blend) :s s :a a :r r :hits hd
                       :light light :heavy heavy :chain-at chain-at :heavy-at heavy-at :abort abort :sfx sfx
                       :pitch (f32 pitch) :hw hw :reach (f32 reach)
                       :magnet (f32 (if (eq magnet :auto) (if hw *magnet-heavy* *magnet-light*) magnet))
                       :inv-from (if iframes (first iframes) -1) :inv-to (if iframes (second iframes) -1)
                       :slide slide :air air :hang hang :red red :ravenable ravenable :jump jump :special special
                       :trail-from (max 0 (1- tf)) :trail-to (+ tt 3))))))

(defmacro defmove (name (&rest props) &body hits)
  "Declarative move. PROPS: :clip :speed :blend :s :a :r (frame data), :light/:heavy chain
targets, :chain-at/:heavy-at (frames; default A_end), :abort n (dodge-abort in the first n f),
:sfx key :pitch, :hw, :magnet m, :iframes (from to), :slide (from to metres), :air, :hang,
:red (telegraphed unblockable windup), :ravenable, :jump (jump-cancel: :on-hit or frame),
:special keyword (custom per-frame logic in the owner's tick).
HITS: (from to &key dmg imp arc cap sph tsph react kb hs hw stun vy feet flags repeat every)."
  `(register-move ,name ',props ',hits))

;;; ================================================================ REN (§3.2)
(defmove :l1 (:clip :l1 :s 6 :a 4 :r 14 :light :l2 :heavy :rising-crow :abort 3 :sfx :slash-light :ravenable t)
  (6 10 :dmg 10 :imp 10 :arc (2.3 110 0.2 2.0) :react :flinch :kb 0.6 :hs 3))
(defmove :l2 (:clip :l2 :s 6 :a 4 :r 14 :light :l3 :heavy :crescent :sfx :slash-light :pitch 1.1 :ravenable t)
  (6 10 :dmg 10 :imp 10 :arc (2.3 110 0.2 2.0) :react :flinch :kb 0.6 :hs 3))
(defmove :l3 (:clip :l3 :s 7 :a 4 :r 16 :light :l4 :heavy :crescent :sfx :slash-light :pitch 1.2 :ravenable t)
  (7 11 :dmg 12 :imp 12 :arc (2.4 100 0.0 2.4) :react :flinch :kb 0.8 :hs 3))
(defmove :l4 (:clip :l4 :s 8 :a 10 :r 18 :light :l5 :heavy :raven-rain :sfx :slash-light :pitch 1.3 :ravenable t)
  (8 13 :dmg 8 :imp 10 :arc (2.5 360 0.2 2.0) :react :flinch :kb 1.0 :hs 3)
  (13 18 :dmg 8 :imp 10 :arc (2.5 360 0.2 2.0) :react :flinch :kb 1.0 :hs 3))
(defmove :l5 (:clip :l5 :s 12 :a 5 :r 28 :sfx :slash-heavy :hw t :jump :on-hit)
  (12 17 :dmg 24 :imp 40 :arc (2.7 70 0 2.2) :sph (1.8 0.3 1.2) :react :knockdown :kb 3.0 :hs 6 :hw t :flags (:ender)))
(defmove :h1 (:clip :h1 :s 14 :a 6 :r 22 :heavy :h2 :abort 3 :sfx :slash-heavy :hw t)
  (14 20 :dmg 24 :imp 35 :arc (2.7 150 0.2 2.0) :react :stagger :kb 1.5 :hs 6 :hw t))
(defmove :h2 (:clip :h2 :s 14 :a 6 :r 22 :heavy :h3 :sfx :slash-heavy :hw t)
  (14 20 :dmg 24 :imp 35 :arc (2.7 150 0.2 2.0) :react :stagger :kb 1.5 :hs 6 :hw t))
(defmove :h3 (:clip :h3 :s 20 :a 6 :r 34 :sfx :slash-heavy :hw t :jump :on-hit)
  (20 26 :dmg 36 :imp 50 :arc (2.8 60 0 2.2) :react :knockdown :kb 3.5 :hs 8 :hw t :flags (:ender))
  (20 22 :dmg 20 :imp 50 :sph (2.0 0 3.0) :feet 0.5 :react :knockdown :kb 3.5 :hs 8 :hw t :flags (:ender)))
(defmove :rising-crow (:clip :rising-crow :s 10 :a 5 :r 18 :sfx :slash-heavy :hw t :jump 15)
  (10 15 :dmg 18 :imp 30 :arc (2.3 70 0 2.4) :react :launch :vy 11 :kb 0.5 :hs 5 :hw t))
(defmove :crescent (:clip :crescent-sweep :s 12 :a 8 :r 22 :sfx :slash-heavy :hw t)
  (12 20 :dmg 26 :imp 45 :arc (2.9 360 0 1.8) :react :knockdown :kb 3.0 :hs 7 :hw t :flags (:ender)))
(defmove :raven-rain (:clip :raven-rain :s 8 :a 30 :r 24 :sfx :slash-light :pitch 1.4)
  (8 13 :repeat 6 :every 5 :dmg 5 :imp 8 :cap (0.3 2.6 1.1 1.0) :react :flinch :kb 0.2 :hs 2 :flags (:quiet))
  (38 40 :dmg 18 :imp 40 :cap (0.3 2.6 1.1 1.0) :react :stagger :kb 2.5 :hs 7 :hw t :flags (:ender)))
(defmove :gale-thrust (:clip :gale-thrust :s 8 :a 8 :r 18 :light :l2 :abort 3 :sfx :slash-heavy :hw t
                       :slide (0 16 4.0) :magnet 0)
  (8 16 :dmg 16 :imp 30 :cap (0.3 2.4 1.1 0.6) :react :stagger :kb 2.0 :hs 5 :hw t))
(defmove :riposte (:clip :riposte :s 5 :a 4 :r 18 :light :l2 :sfx :slash-light :hw t)
  (5 9 :dmg 35 :imp 60 :arc (2.4 90 0 2.2) :react :stagger :kb 1.5 :hs 8 :hw t))
(defmove :mirage (:clip :mirage :s 6 :a 4 :r 16 :light :l2 :sfx :slash-heavy :hw t :special :mirage
                  :iframes (0 10) :magnet 0)
  (6 10 :dmg 30 :imp 60 :tsph (1.2) :react :stagger :stun 54 :kb 1.0 :hs 8 :hw t))
(defmove :raven-burst (:clip :raven-burst :s 6 :a 4 :r 12 :iframes (0 21) :special :raven-burst :magnet 0
                       :sfx :slash-heavy)
  (6 10 :dmg 30 :imp 80 :sph (0 1.0 4.0) :react :knockdown :kb 4.0 :hs 6 :hw t :flags (:no-raven)))
(defmove :crimson-lance (:clip :crimson-lance :s 12 :a 6 :r 22 :heavy :crimson-lance :heavy-at 22 :sfx :slash-heavy :hw t)
  (12 18 :dmg 45 :imp 90 :cap (0.3 6.0 1.1 0.8) :react :stagger :stun 60 :kb 1.5 :hs 8 :hw t
   :flags (:guard-break :no-raven)))
(defmove :al1 (:clip :air-l1 :s 5 :a 4 :r 10 :light :al2 :sfx :slash-light :air t :hang t :ravenable t)
  (5 9 :dmg 8 :imp 10 :arc (2.2 120 0.18 2.38) :react :air-flinch :kb 0.1 :hs 3))
(defmove :al2 (:clip :air-l2 :s 5 :a 4 :r 10 :light :al3 :sfx :slash-light :pitch 1.1 :air t :hang t :ravenable t)
  (5 9 :dmg 8 :imp 10 :arc (2.2 120 0.18 2.38) :react :air-flinch :kb 0.1 :hs 3))
(defmove :al3 (:clip :air-l3 :s 5 :a 4 :r 10 :sfx :slash-light :pitch 1.2 :air t :hang t :ravenable t)
  (5 9 :dmg 8 :imp 10 :arc (2.2 120 0.18 2.38) :react :air-flinch :kb 0.1 :hs 3))
(defmove :thunderfall (:clip :thunderfall :s 6 :a 0 :r 12 :special :thunderfall :air t :iframes (0 9999) :magnet 0))
(defmove :kestrel (:clip :kestrel-start :s 6 :a 22 :r 16 :special :kestrel :air t :hw t :sfx :slash-heavy :magnet 0)
  (6 28 :dmg 30 :imp 40 :sph (0.4 1.1 0.9) :react :stagger :kb 2.0 :hs 6 :hw t))
(defmove :plunge (:clip :plunge-start :s 6 :a 0 :r 20 :special :plunge :air t :hw t :magnet 0))
(defmove :obliterate (:clip :obliterate :s 15 :a 1 :r 29 :special :obliterate :iframes (0 9999) :magnet 0))

;;; REN's specials that hit outside a move window (their own hit-log slots, see HITDEF-SCAN)
(defvar *hd-plunge-fall* (parse-hit '(0 999 :dmg 26 :imp 40 :cap (0 0.8 -0.5 0.8) :react :knockdown :kb 2.5 :hs 6 :hw t)))
(defvar *hd-plunge-shock* (parse-hit '(0 999 :dmg 20 :imp 40 :sph (0 0 2.5) :react :knockdown :kb 2.5 :hs 6 :hw t :flags (:ender))))
(defvar *hd-tf-target* (parse-hit '(0 999 :dmg 60 :react :knockdown :kb 2.5 :hs 10 :hw t :flags (:no-poise :ender))))
(defvar *hd-tf-aoe* (parse-hit '(0 999 :dmg 20 :imp 40 :sph (0 0 3.0) :react :knockdown :kb 2.5 :hs 10 :hw t)))
(defvar *hd-oblit* (parse-hit '(0 999 :dmg 999 :react :knockdown :hs 9 :hw t :flags (:no-poise :obliterate :unblockable))))

;;; ================================================================ RAINBLADE (§5.1)
(defmove :rb-slash (:clip :rb-slash :s 27 :a 7 :r 36 :sfx :slash-light :pitch 0.85)
  (27 34 :dmg 14 :arc (2.0 90 0.3 2.0) :react :flinch :kb 0.5 :hs 3))
(defmove :rb-double (:clip :rb-double :s 24 :a 29 :r 40 :sfx :slash-light :pitch 0.9)
  (24 31 :dmg 12 :arc (2.0 90 0.3 2.0) :react :flinch :kb 0.4 :hs 3)
  (46 53 :dmg 12 :arc (2.0 90 0.3 2.0) :react :flinch :kb 0.6 :hs 3))
(defmove :rb-lunge (:clip :rb-lunge :s 30 :a 15 :r 42 :sfx :slash-heavy :pitch 0.9 :slide (30 45 5.0))
  (30 45 :dmg 18 :cap (0 1.6 1.1 0.5) :react :stagger :kb 1.2 :hs 4))
(defmove :death-grip (:clip :rb-grip :s 48 :a 12 :r 30 :red t :slide (48 60 3.0) :sfx :slash-heavy :pitch 0.7)
  (48 60 :dmg 30 :cap (0 1.2 0.8 0.6) :react :knockdown :kb 3.0 :hs 5 :flags (:unblockable)))
(defmove :rb-backstep (:clip :backstep :s 0 :a 0 :r 18 :slide (0 18 -1.5)))
(defmove :rb-escape (:clip :backflip :speed 1.4 :s 0 :a 0 :r 22 :slide (0 18 -3.0)))
(defmove :rb-red (:clip :rb-red :s 48 :a 7 :r 42 :sfx :slash-heavy :pitch 0.8 :red t :magnet 0)   ; training only
  (48 55 :dmg 30 :arc (2.4 120 0.0 2.0) :react :knockdown :kb 3.0 :hs 4 :flags (:unblockable)))

;;; ================================================================ NEEDLER (§5.2)
(defmove :nd-fan (:clip :nd-fan :s 30 :a 1 :r 30 :special :kunai-fan))
(defmove :nd-blast (:clip :nd-blast :s 48 :a 1 :r 36 :red t :special :kunai-blast))
(defmove :nd-swipe (:clip :nd-swipe :s 18 :a 6 :r 30 :sfx :slash-light :pitch 1.2)
  (18 24 :dmg 10 :arc (1.8 90 0.2 1.9) :react :flinch :kb 0.5 :hs 3))
(defmove :nd-flip (:clip :backflip :speed 0.9 :s 0 :a 0 :r 30 :slide (0 27 -5.0)))

;;; ================================================================ OXHEAD (§5.3)
(defmove :ox-swing (:clip :ox-swing :s 42 :a 12 :r 54 :sfx :slash-heavy :pitch 0.6)
  (42 54 :dmg 22 :arc (3.2 140 0.0 2.6) :react :stagger :kb 2.0 :hs 5))
(defmove :ox-slam (:clip :ox-slam :s 54 :a 9 :r 84 :red t :special :slam)
  (54 63 :dmg 35 :sph (2.0 0.0 3.5) :react :knockdown :kb 3.0 :hs 6 :flags (:unblockable)))
(defmove :ox-charge (:clip :ox-charge :s 48 :a 72 :r 48 :red t :special :charge)
  (48 120 :dmg 30 :cap (0 1.0 1.2 0.9) :react :knockdown :kb 3.0 :hs 6 :flags (:unblockable)))
(defmove :ox-stomp (:clip :ox-stomp :s 24 :a 6 :r 30 :special :stomp)
  (24 30 :dmg 10 :sph (0 0 2.2) :react :flinch :kb 3.0 :hs 4))
(defmove :ox-taunt (:clip :ox-roar :s 0 :a 0 :r 60))

;;; ================================================================ ENRA (§5.4)
(defmove :en-iai (:clip :en-iai :s 30 :a 12 :r 48 :sfx :slash-heavy :pitch 0.75 :slide (30 42 8.0))
  (30 42 :dmg 22 :cap (-0.6 1.2 1.2 1.0) :react :stagger :kb 1.5 :hs 6))
(defmove :en-triple (:clip :en-triple :s 27 :a 46 :r 60 :sfx :slash-heavy :pitch 0.8)
  (27 31 :dmg 16 :arc (3.0 120 0 2.4) :react :flinch :kb 0.8 :hs 4)
  (48 52 :dmg 16 :arc (3.0 120 0 2.4) :react :flinch :kb 0.8 :hs 4)
  (69 73 :dmg 24 :arc (3.0 120 0 2.4) :react :knockdown :kb 3.0 :hs 6))
(defmove :en-crescent (:clip :en-crescent :s 48 :a 8 :r 72 :red t :sfx :slash-heavy :pitch 0.6)
  (48 56 :dmg 38 :arc (4.0 360 0 2.0) :react :knockdown :kb 3.5 :hs 8 :flags (:unblockable)))
(defmove :en-shove (:clip :en-shove :s 15 :a 4 :r 25 :sfx :slash-light :pitch 0.8)
  (15 19 :dmg 18 :arc (2.2 90 0.2 2.2) :react :stagger :kb 2.0 :hs 5))
(defmove :en-wave (:clip :en-wave :s 36 :a 1 :r 36 :special :blade-wave))
(defmove :en-leap (:clip :en-leap :s 54 :a 48 :r 60 :red t :special :leap))
(defmove :en-roar (:clip :en-roar :s 24 :a 0 :r 96 :special :roar))
(defmove :en-summon (:clip :en-summon :s 30 :a 0 :r 30 :special :summon))
(defmove :en-backstep (:clip :backstep :speed 1.2 :s 0 :a 0 :r 15 :slide (0 15 -4.0)))

;;; projectiles and the boss's leap landing
(defvar *hd-kunai* (parse-hit '(0 1 :dmg 8 :react :flinch :hs 3 :flags (:ranged))))
(defvar *hd-blast* (parse-hit '(0 1 :dmg 20 :react :knockdown :hs 6 :flags (:ranged :unblockable))))
(defvar *hd-wave* (parse-hit '(0 1 :dmg 20 :react :stagger :hs 5 :flags (:ranged))))
(defvar *hd-leap* (parse-hit '(0 999 :dmg 40 :sph (0 0 3.0) :react :knockdown :kb 3.5 :hs 8 :flags (:unblockable))))
