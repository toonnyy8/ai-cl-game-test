;;;; senjumaru.lisp — SHUTARA SENJUMARU (Zero Division, TYBW), docs/DUEL_SENJUMARU.md: her moves (DEFMOVE) and her seven
;;;; forms (DEFKIT): :base, the Shikai 刺絡 SHIGARAMI (a close-range tailor: every J / K / O contact sews stitches into his
;;;; clothes, L 悪い癖 pulls them all out as unguardable spikes; the Divine Soldier, the umbrella), and the Bankai
;;;; 娑闥迦羅骸刺絡辻 SHIGARAMI NO TSUJI as six hank forms :tsuji1 .. :tsuji6 (the loom: L held weaves the next hank, released
;;;; it unravels a zone under him, one live at a time, torn by a hit; the form is the hank the loom unravels next).
;;;; Everything of hers is here (the user's code layout, 2026-09-28): the rules of the stitches and the loom, the hazards'
;;;; own step / touch / close hooks (hazards.lisp HAZARD-HOOK), the kit hooks (kit.lisp KIT-HOOK: :tick :ok :hit :struck
;;;; :draw :deck), her HUD meter (hud.lisp's meter :draw / :label), the CPU tables and reflexes (ai.lisp
;;;; :reflex :opp-reflex :sig-hold), her debug tests and knobs, and her three cinematics. The looks, bodies, clips and
;;;; sounds are senjumaru-art.lisp's. This file loads after hud.lisp / onehand.lisp (MANIFEST): the meter drawing uses
;;;; their macros. Plain CL above the hooks: the host rules test loads it.
(in-package :duel)

;;; ================================================================ knobs (docs/DUEL_SENJUMARU.md §11)
(defparameter *walk-senju* 3.6 "Walk m/s, the Shikai.")
(defparameter *run-senju* 8.5 "Run m/s, the Shikai.")
(defparameter *walk-tsuji* 3.3 "Walk m/s, the Bankai (the loom holds her to her ground).")
(defparameter *run-tsuji* 8.0 "Run m/s, the Bankai.")
(defparameter *senju-mult* 1.6 "Damage dealt x, the Shikai (the first pacing knob; the gate moved it from the design's 1.0).")
(defparameter *senju-taken* 0.95 "Damage taken x, the Shikai.")
(defparameter *tsuji-mult* 1.55 "Damage dealt x, the Bankai (the A/B's first knob; the design's 1.0).")
(defparameter *tsuji-taken* 1.0 "Damage taken x, the Bankai.")
(defparameter *hari-max* 6 "Stitches at most.")
(defparameter *hari-idle* 180 "Frames without a new stitch before the first falls out.")
(defparameter *hari-fall* 30 "Then one falls every this many frames.")
(defparameter *hari-sew-hit* 2 "Stitches a hit (or counter-hit) of her J / K / O sews.")
(defparameter *hari-sew-block* 1 "Stitches any other contact sews (a block, the ward, DRINK, armour, the stance).")
(defparameter *hari-dmg* 13 "悪い癖: each spike (unguardable, :spare: never the last Reishi point; the user 2026-10-01: 16 -> ~20
after the Shikai's x1.6, 13 x 1.6 = 21: the hit window's damage is an integer).")
(defparameter *hari-gap* 2 "Frames between two spikes.")
(defparameter *hari-stun* 8 "A spike's flinch.")
(defparameter *hari-last-stun* 18 "The last spike's flinch (she is +6 after it: a frame trap, not a combo).")
(defparameter *shinpei-speed* 3.5 "The Divine Soldier's walk, m/s (the user's decision 2026-09-28: 2.4 -> 3.5).")
(defparameter *shinpei-turn* 120.0 "Its turn, degrees / s.")
(defparameter *shinpei-near* 2.4 "It stops and winds up within this many metres of him.")
(defparameter *shinpei-rise* 10 "Frames it stands in the tapestry: it moves the frame she is free (the user, 2026-10-01).")
(defparameter *shinpei-combo*
  '((18 :ru-q1 7 (:cap 0.3 2.6 1.2 0.35) 20 :flinch 22)
    (14 :ru-ring 21 (:arc 2.8 160 0.0 1.8) 20 :flinch 24)
    (16 :ru-thrust 17 (:cap 0.3 3.0 1.2 0.35) 34 :stagger nil))
  "Its one string (the user, 2026-10-01: a combo, no second approach): per hit its wind-up (frames from its stop, then
from the previous hit), its clip and that clip's startup (played to land on the hit), its volume, damage, reaction and
flinch (each flinch outlasts the next wind-up: a true combo once the first lands; blocked, a guard string).")
(defparameter *shinpei-life* 300 "Frames it lasts.")
(defparameter *kasa-base* 40 "傘: the tendrils' damage with nothing caught (the user's decision: it always fires).")
(defparameter *kasa-cap* 120 "... + half the largest caught hit, at most this.")
(defparameter *weave-pass* 20 "Frames of weaving per pass (1-3), summed over every segment on the hank.")
(defparameter *weave-tap* 10 "L held fewer frames is a tap (the release); this many is a weave (the user, 2026-09-29).")
(defparameter *weave-seg* 30 "The loom's CPU weaves at most this many frames per segment.")
(defparameter *unfold* 20 "Frames every zone unfolds (the tell; fragile: a hit on her tears it).")
(defparameter *unfold-combo* 10 "... the combo cut's (L after a K link).")
(defparameter *torn-lock* 90 "Frames L is locked after a torn hank.")
(defparameter *hank-range* 9.0 "The hanks cast under him (CAST-POINT) reach this far.")
(defparameter *hank-life-mult* 1.0 "Every zone's life x (a pacing knob).")
(defparameter *mirror-k* 0.3 "眼: his melee contact on her inside the ring costs him this much of its damage.")
(defparameter *ai-senju-hari* 0.1 "Her CPU's chance per free step to cash >= :min stitches out with L.")
(defparameter *ai-senju-tachi* 0.5 "The loom's CPU's chance to end a landed string with SP1 (when one of its two hanks hits).")
(defparameter *ai-senju-pair* 0.04 "The loom's CPU's chance per free step to open a designed SP1 pair that suits (SENJU-PAIR-P).")
(defparameter *tachi-second* 6 "TACHINAOSHI: frames between its two releases.")

;;; the six hanks (死出六色浮文機), their values at 3 passes (§4.2)
(defparameter *hanks*
  '((1 :name "BANRA NO ME" :short "ME" :kanji "万朶の眼" :r 3.0 :life 240)
    (2 :name "HAGANE NO YOROI" :short "HAGANE" :kanji "刃金のよろい" :r 2.0 :rise 16 :dmg 90 :guard 24 :after 20)
    (3 :name "KOKUSA NO HARAWATA" :short "KOKUSA" :kanji "黒砂の腸" :r 2.0 :life 240 :away 0.4 :period 60 :swirl 12 :dmg 40)
    (4 :name "ITETSUKU SHITONE" :short "SHITONE" :kanji "凍てつく褥" :r 2.0 :life 240 :dmg 70 :freeze 40 :frost 60)
    (5 :name "YAKENOHARA" :short "YAKENOHARA" :kanji "焼野原" :width 2.0 :max 10.0 :hits 2 :dmg 45 :life 150 :chip 0.12)
    (6 :name "YAMIYO NO HOSHIYO" :short "HOSHI" :kanji "闇夜の星よ" :r 3.5 :life 240 :reiatsu 30.0 :fs 15.0))
  "Hank number -> its plist.")
(defparameter *hank-order* '(3 2 4 5 1 6)
  "The loom's queue (the user, 2026-09-30): 黒砂 刃金 | 褥 焼野原 | 眼 星, then back to 黒砂. Three SP1 pairs (control, then
the strike; the freeze, then the burn; the mirror, then the drain): SP1 from an even slot releases one of them.")

;;; ================================================================ rules (pure: host-tested)
(defun hank (n key) "Hank N's value KEY (*HANKS*)." (getf (rest (assoc n *hanks*)) key))
(defun hank-next (n) "The loom's next hank after N in *HANK-ORDER*, the last wrapping to the first." (or (second (member n *hank-order*)) (first *hank-order*)))
(defun hank-slot (n) "Hank N's place in the queue, 0-5." (position n *hank-order*))
(defun tachi-aligned-p (n)
  "SP1 from the form whose next hank is N releases a designed pair (黒砂+刃金, 褥+焼野原, 眼+星: N on an even slot), not a
cross pair. SP1 keeps the parity; a single release (a tap, K -> L, a voided weave) flips it."
  (evenp (hank-slot n)))
(defun tachi-hanks (n)
  "SP1 裁ち直し from the form whose next hank is N (the user, 2026-09-29): values the two hanks it releases and the hank the
loom is on after them (+2 in *HANK-ORDER*, wrapping)."
  (values n (hank-next n) (hank-next (hank-next n))))
(defun hank-hits-p (n) "Hank N's zone deals a hit (刃金 黒砂 褥 焼野原; 眼 and 星 don't)." (and (hank n :dmg) t))
(defun hank-form (n) "The kit form whose next hank is N." (nth (1- n) '(:tsuji1 :tsuji2 :tsuji3 :tsuji4 :tsuji5 :tsuji6)))
(defun form-hank (form) "The next hank of FORM, or NIL (the Shikai)." (let ((i (position form '(:tsuji1 :tsuji2 :tsuji3 :tsuji4 :tsuji5 :tsuji6)))) (and i (1+ i))))
(defun weave-passes (hold) "Passes a weave of HOLD frames made: one per *WEAVE-PASS*, 1-3." (max 1 (min 3 (floor hold *weave-pass*))))
(defun weave-add (woven hold)
  "The hank's woven frames after one more frame of L held, the press's HOLDth: nothing while it may still be a tap (under
*WEAVE-TAP*), those frames at once when it becomes a weave, then one a frame; at most three passes' worth."
  (cond ((< hold *weave-tap*) woven)
        ((= hold *weave-tap*) (min (* 3 *weave-pass*) (+ woven *weave-tap*)))
        (t (min (* 3 *weave-pass*) (1+ woven)))))
(defun weave-stored (woven) "Passes WOVEN frames hold (0-3)." (min 3 (floor woven *weave-pass*)))
(defun release-passes (woven) "Passes a release makes (a tap, K -> L, SP1): the stored ones, at least 1." (max 1 (weave-stored woven)))
(defun release-ok-p (woven)
  "May a tap or K -> L release the hank with WOVEN frames on it: only with a pass stored (the user, 2026-09-29: \"J weaves,
K releases\"; SP1 is the one exception, it releases at 0 as at 1)."
  (>= (weave-stored woven) 1))
(defun quick-weave (woven) "J -> L HITOKOSHI: one more pass on the hank at once (its frames + *WEAVE-PASS*), at most three." (min (* 3 *weave-pass*) (+ woven *weave-pass*)))
(defun weave-tap-p (hold) "An L press released after HOLD frames is a tap (the release), not a weave." (< hold *weave-tap*))
(defun weave-release-act (hold woven live)
  "What letting L go after HOLD frames does, WOVEN frames on the hank, LIVE: a zone of hers lives. :stop (a weave: it just
stops), :release (a tap with a pass stored and no zone live), else :refused (a tap with nothing woven, or over a live
zone: the loom holds one hank; the :refused cue, then it stops)."
  (cond ((not (weave-tap-p hold)) :stop)
        ((and (release-ok-p woven) (not live)) :release)
        (t :refused)))
(defun loom-ok-p (command combo woven)
  "May a Bankai form's COMMAND start, WOVEN frames on the hank? Everything but K -> L always: L from neutral (it may
weave), J -> L (the quick weave), SP1 (it releases at 0 as at 1); K -> L (a COMBO move with :combo in its params) only
with a pass stored (RELEASE-OK-P)."
  (or (not (eq command :sig)) (not (and (move-p combo) (getf (mv-params combo) :combo))) (release-ok-p woven)))
(defun weave-void (n) "A hit on her while she weaves hank N: it is void. Values the next hank and the woven frames (0)." (values (hank-next n) 0))
(defparameter *pass-scale* '((0.7 0.85 1.0) (0.5 0.8 1.2) (0.7 1.0 1.4) (0.6 1.0 1.5))
  "The weave's scaling by passes 1 / 2 / 3, rows radius, life, damage, effect (the user, 2026-10-01: wider steps, a
stronger top; the radius tops at 1.0, a disc's edge stays a Step away).")
(defun hank-scale (passes)
  "The weave's scaling by PASSES (1-3): values radius x, life x, damage x, effect x (*PASS-SCALE*: more passes are never
weaker)."
  (let ((i (1- (max 1 (min 3 passes)))))
    (values-list (mapcar (lambda (row) (nth i row)) *pass-scale*))))
(defun hank-fx (n key passes)
  "Hank N's effect KEY after PASSES (the effect scale): 刃金's guard damage, 黒砂's drag, 褥's freeze and frost, 焼野原's
chip, 星's drain (and 眼's mirror, *MIRROR-K* x the same)."
  (* (nth-value 3 (hank-scale passes)) (hank n key)))
(defun hari-sew (n res)
  "The stitch count after one contact of her J / K / O window resolved as RES (RESOLVE-CONTACT): a real hit sews
*HARI-SEW-HIT*, any other contact *HARI-SEW-BLOCK*, capped at *HARI-MAX*; a parry sews nothing."
  (if (member res '(nil :parried :kikon))
      n
      (min *hari-max* (+ n (if (eq (contact-of res) :hit) *hari-sew-hit* *hari-sew-block*)))))
(defun hari-step (n idle locked)
  "The stitches one frame later: IDLE counts the frames since the last stitch (paused while LOCKED); at *HARI-IDLE* the
first falls out, then one every *HARI-FALL*. Values: n idle fell-p."
  (cond ((<= n 0) (values 0 0 nil))
        (locked (values n idle nil))
        (t (let ((i (min 9999 (1+ idle))))
             (if (and (>= i *hari-idle*) (zerop (mod (- i *hari-idle*) *hari-fall*)))
                 (values (1- n) i t)
                 (values n i nil))))))
(defun hari-falls-in (n idle)
  "Frames until the next stitch falls (N > 0), from IDLE."
  (declare (ignore n))
  (if (< idle *hari-idle*) (- *hari-idle* idle) (- *hari-fall* (mod (- idle *hari-idle*) *hari-fall*))))
(defun kasa-damage (caught) "The tendrils: *KASA-BASE* + half the largest CAUGHT hit, at most *KASA-CAP*." (min *kasa-cap* (+ *kasa-base* (floor caught 2))))
(defun hank-damage (n passes) "Hank N's hit after PASSES." (multiple-value-bind (r l d) (hank-scale passes) (declare (ignore r l)) (round (* d (hank n :dmg)))))
(defun hank-radius (n passes) "Hank N's radius after PASSES." (* (hank-scale passes) (hank n :r)))
(defun hank-life (n passes) "Hank N's life after PASSES (x *HANK-LIFE-MULT*)." (multiple-value-bind (r l) (hank-scale passes) (declare (ignore r)) (round (* l *hank-life-mult* (hank n :life)))))

;;; ================================================================ Shikai 刺絡 SHIGARAMI (base)
;;; the J / K strings (docs/DUEL_STRINGS.md §2.1 budget): the lightest in the game (the user, 2026-10-01: every form's J
;;; x0.9, K x0.8); every contact sews (SENJU-HIT). Every
;;; reach is where the art strikes (the user's playtest, 2026-09-29): the J links to the tip of the needle (1.44 m since the
;;; J cut, docs/DUEL_STRINGS.md §13: J light, short and fast, 0.6x; the needle 1.2 m), the K links to their props' far ends
;;; (senjumaru-art.lisp *SJ-STRIKE-REACH*; the host test checks)
(defmove :sj-j1 :kind :quick :clip :sj-q1 :startup 7 :active 3 :recovery 12 :dmg 25 :adv-block -2
  :reach 1.44 :arc 90 :on-hit :flinch :slide 0.5)                    ; HITOHARI: the upper right hand jabs the needle
(defmove :sj-j2 :kind :quick :clip :sj-q2 :startup 7 :active 3 :recovery 13 :dmg 25 :adv-block -2
  :reach 1.44 :arc 110 :on-hit :flinch)                              ; KAESHINUI: the backstitch
(defmove :sj-j3 :kind :quick :clip :sj-spin :startup 8 :active 3 :recovery 18 :dmg 32 :adv-block -4
  :reach 1.44 :arc 220 :on-hit :stagger :flags (:ender))             ; SENJU: all six hands whirl in a ring of needles
(defmove :sj-k1 :kind :flash :clip :sj-f1 :startup 17 :active 4 :recovery 20 :dmg 48 :adv-block -3
  :vol (:cap 0.3 2.9 1.1 0.3) :on-hit :stagger)                      ; MACHIBARI: two long pins driven straight out
(defmove :sj-k2 :kind :flash :clip :sj-f2 :enter 7 :startup 21 :active 4 :recovery 24 :dmg 40 :adv-block -3
  :reach 2.5 :arc 140 :on-hit :stagger)                              ; MATSURI: the hem stitch, a loop whipped over him
(defmove :sj-k3 :kind :flash :clip :sj-drop :enter 7 :startup 21 :active 5 :recovery 34 :dmg 59 :adv-block -20
  :reach 2.5 :arc 160 :height (0.0 1.4) :on-hit :crumple :flags (:ender))   ; KUKE: pins slammed down round his feet
(defmove-copy :sj-j2s :sj-j2)
(defmove-copy :sj-k2s :sj-k2)
;; L 悪い癖 WARUI KUSE: refused at 0 stitches; frame 0 spends them all: one unguardable spike (10, :spare) every 2 f from
;; f10, stuck to him (SENJU-WARUI-KUSE). She is free at f32, the last spike holds him to f38: +6, a frame trap
(defmove :sj-warui-kuse :kind :sig :clip :sj-yank :callout "WARUI KUSE" :startup 8 :active 0 :recovery 24
  :on-frame ((0 senju-warui-kuse)) :params (:first 10))
;; after a K link (the kit's :l-after-k, DUEL_STRINGS §12): S 6, spikes from f8: A 4 + 8 + 2 x 5 < stagger 26, a combo
;; (scaled). Its reach is 9 m: the follow-up chase leaves her where she stands (the needles are in him)
(defmove-copy :sj-warui-kuse-k :sj-warui-kuse :startup 6 :clip-s 8 :reach 9.0 :params (:first 8))
;; Shift+K SP1 神兵 SHINPEI: a tapestry drops 1.5 m ahead (f8), a Divine Soldier steps out (f10) and stands until she is
;; free (f20, *SHINPEI-RISE*: they attack together; the user, 2026-10-01); then it walks the line to him and strikes
;; one string (*SHINPEI-COMBO*: thrust, sweep, thrust; guarded facing her), then fades, 300 f at most; frail: any of his
;; windows or hazards kills it, and it sews one stitch into him as it bursts (the user's decision 2026-09-28)
(defmove :sj-shinpei :kind :sp :clip :sj-summon :clip-s 16 :callout "SHINPEI" :startup 10 :active 0 :recovery 10
  :on-frame ((8 senju-tapestry) (10 senju-shinpei)))
;; Shift+L SP2 傘 KASA: f4-27 the umbrella: a guard for melee (:shield), a catch for hazards / ranged hits (no stun, no
;; gauge: :catch), then at f28 the tendrils always fire (the user's decision): 40 + half the largest caught hit, <= 120
(defmove :sj-kasa :kind :sp :clip :sj-kasa :callout "KASA" :startup 4 :active 24 :recovery 18 :flags (:shield)
  :on-frame ((0 senju-kasa-open) (28 senju-kasa-fire))
  :params (:catch senju-kasa-catch :speed 16.0 :range 10.0 :width 1.6 :guard 14))
(defmove :sj-breaker :kind :breaker :clip :sj-breaker :clip-2 :sj-saidan :callout "SAIDAN")
;; O, the Kikon module 縫地 NUICHI: 6 f of aura, a flash step 26 m/s for <= 14 f (locked), the whirl of hands (it sews):
;; 7.7 m, <= 28 f from the press. Its Kikon is 仕立て直し SHITATE-NAOSHI. Cooldown 90
(defmove :sj-kikon :kind :kikon :clip :sh-run :clip-2 :sj-spin :callout "SHITATE-NAOSHI" :cine sj-kikon-cine
  :startup 8 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.4 :arc 200 :on-hit :knockback :kb 2.5 :cooldown 90
  :on-frame ((7 senju-nuichi-threads))
  :params (:aura 6 :aim 120.0 :speed 26.0 :dash-max 14 :dash-track 0.0 :look :flash-step :sfx :hoho-out))

;;; ================================================================ 娑闥迦羅骸刺絡辻 SHIGARAMI NO TSUJI (the six hank forms)
;; the J / K grid as the Shikai's (the same needle and loop: no reach derivation, the playtest), no sewing; two new links
(defmove :sj-t-k1 :kind :flash :clip :sj-tanmono :startup 17 :active 4 :recovery 20 :dmg 45 :adv-block -3
  :vol (:cap 0.3 3.8 1.1 0.3) :on-hit :stagger)                      ; TANMONO-UCHI: a bolt flung out and snapped back
(defmove :sj-t-k3 :kind :flash :clip :sj-makitori :enter 7 :startup 21 :active 5 :recovery 34 :dmg 58 :adv-block -20
  :reach 2.5 :arc 160 :height (0.0 1.4) :on-hit :crumple :flags (:ender)
  :params (:pull 1.4))                                               ; MAKITORI: wrapped and hauled in to 1.4 m
;; L 綛解かば KASE TOKABA (the user, 2026-09-29): held >= *WEAVE-TAP* f it weaves (a pass per 20 f, summed over segments on
;; the hank: SENJU-WEAVE-TICK); let go, the weave stops (6 f, SENJU-WEAVE-RELEASE), nothing unravels. A tap (< 10 f)
;; releases: S 6, the hank unravels at the stored passes (at least 1; SENJU-UNRAVEL) and the form advances. :bind + :tell:
;; a CPU victim's tell reflex, counted from the release
(defmacro def-kase (n callout tell tell-k)
  (let ((name (intern (format nil "SJ-KASE-~d" n) :keyword)) (k (intern (format nil "SJ-KASE-~d-K" n) :keyword)))
    `(progn
       (defmove ,name :kind :sig :clip :sj-weave :clip-2 :sj-unravel :callout ,callout :hold (1 600)
         :startup 6 :active 0 :recovery 22 :tick senju-weave-tick :release senju-weave-release :on-frame ((6 senju-unravel))
         :flags (:bind) :params (:hank ,n :tell ,tell))
       ;; after a K link (the combo cut, the overdraft rule): no hold, the stored passes, S 8, unfold 10; the live zone is cut
       (defmove-copy ,k ,name :hold nil :tick nil :release nil :startup 8 :clip :sj-unravel :clip-s 6 :reach 9.0
         :on-frame ((0 senju-combo-cut) (8 senju-unravel)) :params (:hank ,n :combo t :tell ,tell-k)))))
(def-kase 1 "BANRA NO ME" nil nil)                ; 眼: no hit of its own
(def-kase 2 "HAGANE NO YOROI" (34 44) (10 22))    ; 刃金: closes 16 f after the unfold (the combo cut: at its end)
(def-kase 3 "KOKUSA NO HARAWATA" (60 80) (10 22)) ; 黒砂: the first gulp (the combo cut: at the unfold's end)
(def-kase 4 "ITETSUKU SHITONE" (18 30) (10 22))   ; 褥: armed once unfolded
(def-kase 5 "YAKENOHARA" (18 30) (10 22))         ; 焼野原: burns once unfolded
(def-kase 6 "YAMIYO NO HOSHIYO" nil nil)          ; 星: no hit
;; J -> L 一越 HITOKOSHI (the user, 2026-09-29: "J weaves, K releases"): L after a J link (the kit's :l-after-j) throws the
;; shuttle once: +1 pass on the form's hank at f8 (QUICK-WEAVE, at most 3), never a release; 8/0/10. No bolt, so no void:
;; a hit before f8 just loses the pass. From a J1 / J2 hit (flinch 18, A 3): 18 - 3 - 18 = -3; from J3 (stagger 26): +5;
;; blocked (the chain opens 3 f before the link ends): J1 / J2 -2 + 3 - 18 = -17, J3 -4 + 3 - 18 = -19
(defmove :sj-hitokoshi :kind :sig :clip :sj-weave :startup 8 :active 0 :recovery 10 :on-frame ((8 senju-quick-weave)))
;; the weave let go: 6 f back to the loom stance (no hit, no release)
(defmove :sj-weave-stop :kind :sig :clip :sj-loom-stance :startup 1 :active 0 :recovery 5 :whiff 5)
;; Shift+K SP1 裁ち直し TACHINAOSHI (the user, 2026-09-29): 1 bar, no weave: frame 0 cuts the live zone(s) (the combo cut's
;; rule), f8 and f14 release the next two hanks as the combo cut does (1 pass, unfold 10; the form advances past both: +2).
;; A string ender (the universal SP cancel off a landed link): after a stagger (26 f) the first zone lands at +19, the
;; second at +25. One copy per form: :tell is its first hitting hank's (a CPU victim's tell reflex, from the move's f0)
(defmove :sj-tachinaoshi :kind :sp :clip :sj-snip :clip-s 16 :callout "TACHINAOSHI" :startup 8 :active 0 :recovery 22
  :reach 9.0 :flags (:bind) :on-frame ((0 senju-combo-cut) (8 senju-tachi-release) (14 senju-tachi-release)))
(defmove-copy :sj-tachinaoshi-1 :sj-tachinaoshi :params (:tell nil))       ; 眼 + 星: no hit (a pair)
(defmove-copy :sj-tachinaoshi-2 :sj-tachinaoshi :params (:tell (10 22)))   ; 刃金 + 褥 (cross)
(defmove-copy :sj-tachinaoshi-3 :sj-tachinaoshi :params (:tell (10 22)))   ; 黒砂 + 刃金 (a pair)
(defmove-copy :sj-tachinaoshi-4 :sj-tachinaoshi :params (:tell (10 22)))   ; 褥 + 焼野原 (a pair)
(defmove-copy :sj-tachinaoshi-5 :sj-tachinaoshi :params (:tell (10 22)))   ; 焼野原 + 眼 (cross)
(defmove-copy :sj-tachinaoshi-6 :sj-tachinaoshi :params (:tell (16 28)))   ; 星 + 黒砂 (cross; the second hits)
;; O, the Kikon module 浮文機 UKIMON NO HATA: ENJO's shape (no dash): the red carpet runs along a locked lane 8.5 m; its
;; Kikon is 死出六色浮文機
(defmove :sj-t-kikon :kind :kikon :clip :sj-loom-stance :clip-2 :sj-unravel :clip-s 6 :callout "SHIDE NO ROKUSHIKI UKIMON NO HATA"
  :cine sj-hata-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0 :vol (:cap 0.5 8.5 1.2 1.2)
  :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((4 senju-carpet))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0))

;;; ================================================================ forms
(defparameter *senju-meter* '(:name "HARI" :max 6 :start 0 :draw senju-hud-meter :label senju-hud-label)
  "Her one resource per form, on the kit-meter row: the stitches (the Shikai) or the loom (the Bankai).")
(defparameter *senju-hooks* '(:tick senju-tick :ok senju-ok :hit senju-hit :struck senju-struck :draw senju-draw :deck senju-ring
                              :siphon senju-siphon))

(defkit :senjumaru :base
  :name "SENJUMARU" :body :senjumaru :weapon :shigarami :stance :sj-stance :calm t
  :intro :sj-intro :win :sj-win :intro-callout "SHIGARAMI"
  :walk *walk-senju* :run *run-senju* :reishi *reishi-max* :swing-sfx :whoosh-light :mult *senju-mult* :taken *senju-taken*
  :stun-tolerance 13.0                          ; the hidden stun (DUEL_DESIGN.md): a weaver, not a brawler: blown away sooner
  :commands (:q :sj-j1 :f :sj-k1 :sig :sj-warui-kuse :sp1 :sj-shinpei :sp2 :sj-kasa :breaker :sj-breaker :kikon :sj-kikon)
  :grid (:sj-j1 :sj-j2 :sj-j3 :sj-k1 :sj-k2 :sj-k3 :sj-j2s :sj-k2s)
  :l-after-k :sj-warui-kuse-k                   ; the scaled cash-out after a K link
  :awaken-form :tsuji3 :reset-form :base        ; (the queue's first hank, 黒砂; a reset keeps the form and empties the
                                                ; stitches: the kit meter)
  :meter *senju-meter* :hooks *senju-hooks*
  ;; a close-range tailor: J1 up close, blocked strings still sew, the soldier and the O from range, L when the stitches
  ;; pay (:hari, SENJU-AI-REFLEX); she awakens as Ichigo does, once she has taken 150 (:awaken; the user 2026-09-30:
  ;; her old rule, a zoner or a rooted form only, left the Bankai to 27 % of CPU matches)
  :ai (:intents (:approach 2 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.4 5.0) :pressure (1.0 1.9) :zone (5.0 8.0) :defend (3.0 5.0))
       :moves ((0.0 1.7 :q 6 :f 2 :breaker 1)                          ; J up close only (DUEL_STRINGS §13), K beyond
               (1.7 2.6 :f 4 :breaker 1)
               (2.6 6.0 :sp1 2 :kikon 1 :step 1 nil 1)
               (6.0 99.0 :sp1 2 :kikon 2 nil 1))
       :guard 0.4 :hoho 0.3 :dash 0.7 :dash-back 0.1 :block-string 0.8 :o-ender 0.3 :l-after-k 0.3 :sp-cancel-bars 9   ; (no SP2
                                                ; cancel: 傘 is no combo ender; the bars go to the soldier and the umbrella)
       :kikon-range 7.7 :react (:projectile :sp2)
       :awaken (:min-taken 150)
       :hari (:min 4 :hurry 40) :reflex senju-ai-reflex :sig-hold senju-sig-hold :sp-ender senju-base-ender))

(defparameter *tsuji-ai*
  '(:intents (:approach 1 :pressure 1 :zone 4 :defend 2)
    :ranges (:approach (2.6 5.0) :pressure (1.0 2.4) :zone (5.0 8.0) :defend (4.0 6.0))
    :moves ((0.0 1.7 :q 3 :f 2 :breaker 1 :step 2)
            (1.7 2.8 :f 3 :breaker 1 :step 2)
            (2.8 4.0 :f 2 :step 2 nil 1)
            (4.0 5.0 :f 1 :sig 2 :step 1 nil 1)
            (5.0 9.0 :sig 5 :kikon 1 nil 1)
            (9.0 99.0 :sig 2 nil 2))
    :guard 0.45 :hoho 0.35 :dash 0.2 :dash-back 0.6 :o-ender 0.2 :l-after-k 0.3 :l-after-j 0.35 :sp-cancel-bars 9
    :kikon-range 8.5
    :react (:projectile :sp2) :weave (:far 6.5 :near 4.0) :sp-ender senju-sp-ender
    :opp-rush-hold 0.5 :opp-reflex senju-opp-reflex :reflex senju-ai-reflex :sig-hold senju-sig-hold)
  "The loom's CPU (every hank form; 星's weave distances are read by form in SENJU-SIG-HOLD; SP1 ends a string: SENJU-SP-ENDER).")

(defkit :senjumaru :tsuji1 :inherit :base
  :awakening t :form-name "TSUJI" :walk *walk-tsuji* :run *run-tsuji*
  :mult *tsuji-mult* :taken *tsuji-taken* :reset-form nil :stance :sj-loom-stance :aura senju-aura-tsuji :cine sj-tsuji-cine
  :commands (:f :sj-t-k1 :sig :sj-kase-1 :sp1 :sj-tachinaoshi-1 :sp2 :sj-kasa :breaker :sj-breaker :kikon :sj-t-kikon)
  :grid (:sj-j1 :sj-j2 :sj-j3 :sj-t-k1 :sj-k2 :sj-t-k3 :sj-j2s :sj-k2s)
  :l-after-k :sj-kase-1-k :l-after-j :sj-hitokoshi :meter *senju-meter* :ai *tsuji-ai*)
(defkit :senjumaru :tsuji2 :inherit :tsuji1 :commands (:sig :sj-kase-2 :sp1 :sj-tachinaoshi-2) :l-after-k :sj-kase-2-k)
(defkit :senjumaru :tsuji3 :inherit :tsuji1 :commands (:sig :sj-kase-3 :sp1 :sj-tachinaoshi-3) :l-after-k :sj-kase-3-k)
(defkit :senjumaru :tsuji4 :inherit :tsuji1 :commands (:sig :sj-kase-4 :sp1 :sj-tachinaoshi-4) :l-after-k :sj-kase-4-k)
(defkit :senjumaru :tsuji5 :inherit :tsuji1 :commands (:sig :sj-kase-5 :sp1 :sj-tachinaoshi-5) :l-after-k :sj-kase-5-k)
(defkit :senjumaru :tsuji6 :inherit :tsuji1 :commands (:sig :sj-kase-6 :sp1 :sj-tachinaoshi-6) :l-after-k :sj-kase-6-k)

;; her names in the brush tables (brush.lisp): the intro's column and the technique columns at her side (not on the host)
(when (boundp '*brush-names*)
(setf *brush-names* (append (remove :senjumaru *brush-names* :key #'first) '((:senjumaru "修多羅千手丸" "SHUTARA SENJUMARU")))
      *brush-callouts*
      (append (remove-if (lambda (c) (member (first c) '(:sj-warui-kuse :sj-warui-kuse-k :sj-shinpei :sj-kasa :sj-tachinaoshi
                                                          :sj-tachinaoshi-1 :sj-tachinaoshi-2 :sj-tachinaoshi-3
                                                          :sj-tachinaoshi-4 :sj-tachinaoshi-5 :sj-tachinaoshi-6)))
                         *brush-callouts*)
              '((:sj-warui-kuse "悪い癖" "WARUI KUSE" nil) (:sj-warui-kuse-k "悪い癖" "WARUI KUSE" nil)
                (:sj-shinpei "神兵" "SHINPEI" nil) (:sj-kasa "傘" "KASA" nil) (:sj-tachinaoshi "裁ち直し" "TACHINAOSHI" nil))
              (loop for n from 1 to 6 collect (list (intern (format nil "SJ-TACHINAOSHI-~d" n) :keyword) "裁ち直し" "TACHINAOSHI" nil))
              (loop for n from 1 to 6                   ; (the mark: the canon chant's numeral, 一綛 .. 六綛, not the queue's)
                    for mark in '("一" "二" "三" "四" "五" "六")
                    append (list (list (intern (format nil "SJ-KASE-~d" n) :keyword) (hank n :kanji) (hank n :name) mark)
                                 (list (intern (format nil "SJ-KASE-~d-K" n) :keyword) (hank n :kanji) (hank n :name) mark))))))

;;; ================================================================ per-side state (the sim's; reset with every match)
(defstruct (sjs (:conc-name sjs-))
  (e nil)                                 ; the fighter it belongs to: a new match's fighter gets a fresh state (SJ)
  (caught 0 :type fixnum)                 ; the umbrella's largest caught hit (this umbrella)
  (soldier -1) (live -1) (bolt -1)        ; handles: her soldier, her live zone, the weave's bolt
  (live-hank 0 :type fixnum) (live-life 1 :type fixnum)   ; the live zone's hank and life (the HUD's drain)
  (live2 -1)                              ; TACHINAOSHI's first zone while its second is the live one
  (woven 0 :type fixnum)                  ; frames woven on the form's hank (every segment; WEAVE-ADD)
  (tachi 0 :type fixnum)                  ; TACHINAOSHI: the woven frames both its hanks release at
  (torn -9999 :type fixnum) (torn-hank 0 :type fixnum)   ; *MATCH-TICK* of the last torn hank, and which
  (acc nil))                              ; the pacing log's counters (debug)
(defvar *sj* (vector (make-sjs) (make-sjs)) "Per side: her loom, soldier and umbrella.")
(defun sj (e)
  "E's state; a new fighter entity (a new match) gets a fresh one, keeping only the pacing log's counters (the native
gate found the loom's woven frames, torn clock and handles carried over from the match before: DEVLOG §38)."
  (let* ((i (fighter-side (fighter e))) (st (svref *sj* i)))
    (if (eql (sjs-e st) e) st (setf (svref *sj* i) (make-sjs :e e :acc (sjs-acc st))))))
(defmacro sj-count (e key &optional (n 1)) `(incf (getf (sjs-acc (sj ,e)) ,key 0) ,n))

;;; hazard data: her hazards carry one of these (HAZARD-DATA) and SENJU-HZ as their hook
(defstruct (sjh (:conc-name sjh-))
  (kind nil)                              ; :spike :soldier :thrust :bolt :zone :gulp :follow
  (hank 0 :type fixnum) (passes 1 :type fixnum)
  (r 0f0 :type single-float) (len 0f0 :type single-float)
  (x0 0f0 :type single-float) (z0 0f0 :type single-float)
  (clock 0 :type fixnum) (n 0 :type fixnum) (phase nil)
  (model nil) (vol nil) (link -1) (look-t 0f0 :type single-float)
  (combo nil))                            ; a zone of the combo cut: 刃金 closes and 黒砂 gulps at the unfold's end

(defun senju-spawn (kind owner data &rest keys)
  "One of her hazards: SPAWN-HAZARD with her hook and DATA."
  (apply #'spawn-hazard kind owner :hook 'senju-hz :data data keys))

(defun senju-look (e look x z &key (yaw 0.0) (size 1.0) (life 30) (delay 0) (kind :look) follow)
  "A look-only hazard (kind :fx) drawn by LOOK (senjumaru-art.lisp); FOLLOW: it stays on its owner."
  (senju-spawn :fx e (make-sjh :kind (if follow :follow kind)) :x x :z z :yaw yaw :size size :life life :delay delay :look look))

;;; ================================================================ the stitches (the Shikai's meter: the kit meter holds the count)
(defun hari (e) (round (gauges-meter (gauges e))))
(defun set-hari (e n)
  (let ((g (gauges e))) (setf (gauges-meter g) (f32 n))))
(defun hari-form-p (e) "E's form counts stitches (the Shikai)." (eq (fighter-form (fighter e)) :base))

(defun senju-tick (e f g)
  "Per step (her kit's :tick): the stitches fall out after *HARI-IDLE* frames without a new one (paused while locked)."
  (when (eq (fighter-form f) :base)
    (multiple-value-bind (n idle fell) (hari-step (hari e) (gauges-meter-idle g) (plusp (fighter-lock f)))
      (setf (gauges-meter g) (f32 n) (gauges-meter-idle g) idle)
      (when fell (sj-count e :fallen) (clog "~a stitch fell, ~d left" (side-name e) n)))))

(defun senju-ok (e command combo)
  "Her kit's refusals: the Shikai's L at 0 stitches; the Bankai's K -> L with no pass stored (LOOM-OK-P; its L from
neutral always starts: it may weave, and its tap is refused at release, SENJU-WEAVE-RELEASE; J -> L always weaves)."
  (cond ((not (eq command :sig)) t)
        ((hari-form-p e) (>= (hari e) 1))
        (t (loom-ok-p command combo (sjs-woven (sj e))))))

(defun senju-hit (att def res hw mv hazard ranged)
  "After a hit she dealt (her kit's :hit): her own J / K / O window's contact sews (the Shikai); MAKITORI hauls him in to
1.4 m; a gulp of the black sand pulls him to the pit's centre; the pacing log."
  (declare (ignore hw))
  (let ((hit (member res '(:hit :counter))))
    (when (and mv (not hazard) (not ranged) (eq (fighter-move (fighter att)) mv) (member (mv-kind mv) '(:quick :flash :kikon))
               (hari-form-p att))
      (let ((n (hari-sew (hari att) res)))
        (when (> n (hari att))
          (sj-count att (if hit :sewn-hit :sewn-block) (- n (hari att)))
          (set-hari att n) (setf (gauges-meter-idle (gauges att)) 0)
          (emit :sfx :thread-zip att))))
    (when (and hit mv (getf (mv-params mv) :pull))              ; MAKITORI: hauled in
      (senju-pull def (pos-of att) (getf (mv-params mv) :pull) 8))
    (when hazard
      (let ((d (hazard-data hazard)))
        (when (sjh-p d)
          (case (sjh-kind d)
            (:gulp (when hit (senju-pull def (vector (sjh-x0 d) 0f0 (sjh-z0 d)) 0.0 10)))
            (:thrust (sj-count att (if hit :soldier-hits :soldier-blocked))))
          (when (plusp (sjh-hank d)) (sj-count att (if hit (hank-key (sjh-hank d) "HIT") (hank-key (sjh-hank d) "BLK")))))))
    (when (and hazard (eq (hazard-look hazard) 'senju-tendril-look) hit) (sj-count att :tendril-hits))
    (when (and hazard (eq (hazard-look hazard) 'senju-spike-look) hit) (sj-count att :spike-dmg (hw-dmg (hazard-hw hazard))))))

(defun hank-key (n suffix) (intern (format nil "Z~d-~a" n suffix) :keyword))

(defun senju-pull (e to d frames)
  "Slide E toward the point TO (a vector x _ z) until D metres from it, over FRAMES (a hit's pull: her hook sets it
after the reaction, whose own slide it replaces)."
  (let* ((p (pos-of e)) (dx (- (aref to 0) (aref p 0))) (dz (- (aref to 2) (aref p 2))) (l (sqrt (+ (* dx dx) (* dz dz)))))
    (when (> l (+ d 0.05))
      (set-slide e (- l d) frames dx dz))))

(defun senju-struck (def att res hw mv hazard ranged)
  "After a hit she took (her kit's :struck): 眼's mirror: while her live ring stands under him, each of his melee contacts
on her (hit or block) burns him *MIRROR-K* of its damage (never kills)."
  (let ((z (senju-live-zone def 1)))
    (when (and mv (not hazard) (not ranged) (member (contact-of res) '(:hit :block)) z)
      (let ((hz (hazard z)))
        (when (and hz (<= (hazard-delay hz) 0))
          (let* ((q (pos-of att)) (dx (- (aref q 0) (hazard-x hz))) (dz (- (aref q 2) (hazard-z hz))))
            (when (<= (+ (* dx dx) (* dz dz)) (expt (hazard-size hz) 2))
              (let ((n (round (* *mirror-k* (nth-value 3 (hank-scale (sjh-passes (hazard-data hz)))) (hw-dmg hw)))) (g (gauges att)))
                (when (plusp n)
                  (setf (gauges-reishi g) (burn (gauges-reishi g) n))
                  (setf (sjh-look-t (hazard-data hz)) (f32 (fx-clock)))
                  (sj-count def :mirror n)
                  (emit :sfx :needle-burst att)
                  (clog "~a mirror ~d" (side-name att) n))))))))))

;;; ---------------------------------------------------------------- 悪い癖 WARUI KUSE: the stuck spikes
(defun senju-warui-kuse (e)
  "L f0: every stitch spent; one spike per stitch, stuck to him (it follows him: SENJU-HZ :spike), the first at the move's
:first frame, then one every *HARI-GAP*: 10 each, unguardable, ranged (no parry, no KOSEI), :spare (never his last
Reishi point: no Soul Break); a flinch of *HARI-STUN* (the last *HARI-LAST-STUN*). Iframes dodge them: a Hoho in the yank
is perfect (they are hazard threats from the start)."
  (let* ((n (hari e)) (o (opp-of e)) (q (pos-of o)) (first (move-param e :first)) (combo (plusp (fighter-combo-hits (fighter o)))))
    (set-hari e 0)
    (sj-count e (if combo :det-combo :det-free))
    (sj-count e :det-stitches n)
    (dotimes (i n)
      (senju-spawn :freeze e (make-sjh :kind :spike) :x (aref q 0) :z (aref q 2) :size 0.3 :y 2.0 :delay (+ first (* i *hari-gap*))
                   :life 2 :look 'senju-spike-look
                   :hw (make-hitwin :dmg *hari-dmg* :react :flinch :stun (if (= i (1- n)) *hari-last-stun* *hari-stun*) :hs 3
                                    :flags '(:unguardable :ranged :spare :thread))))
    (emit :sfx :thread-zip e)
    (clog "~a WARUI KUSE ~d" (side-name e) n)))

;;; ---------------------------------------------------------------- 神兵 SHINPEI: the Divine Soldier
(defun senju-shinpei-point (e)
  (let* ((p (pos-of e)) (q (pos-of (opp-of e))) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
         (d (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (k (min 1.5 (* 0.5 d))))
    (values (+ (aref p 0) (* k (/ dx d))) (+ (aref p 2) (* k (/ dz d))) (dir-yaw dx dz))))

(defun senju-tapestry (e)
  "SP1 f8: a tapestry drops where the soldier steps out (a look)."
  (multiple-value-bind (x z yaw) (senju-shinpei-point e)
    (senju-look e 'senju-tapestry-look x z :yaw yaw :size 1.0 :life 40))
  (emit :sfx :cloth-unfurl e))

(defun senju-shinpei (e)
  "SP1 f10: the Divine Soldier (one at a time: a new one replaces the old), standing in the tapestry *SHINPEI-RISE*."
  (let ((st (sj e)))
    (destroy-entity (sjs-soldier st))
    (multiple-value-bind (x z yaw) (senju-shinpei-point e)
      (let ((m (make-model :body (find-body :shinpei) :weapon :sj-spear)))
        (anim-play (model-anim m) :sj-stance :blend 0)
        (setf (sjs-soldier st)
              (senju-spawn :soldier e (make-sjh :kind :soldier :phase :rise :model m) :x x :z z :yaw yaw :size 0.4
                           :life *shinpei-life* :look 'senju-soldier-look))))
    (sj-count e :soldiers)
    (clog "~a SHINPEI" (side-name e))))

(defun senju-frail-hit-p (o x z)
  "Does one of O's open melee windows, or one of his active hazards, touch the soldier's cylinder at (X Z) (r 0.4, h 1.8)?"
  (let ((f (fighter o)) (x (f32 x)) (z (f32 z)))
    (or (and (eq (fighter-state f) :move) (eq (fighter-phase f) :main)
             (let* ((mv (fighter-move f)) (sf (fighter-sf f)) (p (pos-of o)) (yaw (yaw-of o))
                    (fx (f32 (fwd-x yaw))) (fz (f32 (fwd-z yaw))))
               (loop for w across (mv-hits mv)
                     thereis (and (<= (hw-from w) sf) (< sf (hw-to w))
                                  (loop for v in (hw-vols w)
                                        thereis (vol-hit-p v (aref p 0) (aref p 1) (aref p 2) fx fz x 0f0 z 0.4f0 1.8f0 0f0))))))
        (let ((hit nil))
          (do-entities (h (hz hazard))
            (when (and (not hit) (eql (hazard-owner hz) o) (hazard-active-p hz) (hazard-touches-p hz x 0f0 z 0.4f0 1.8f0))
              (setf hit t)))
          hit))))

(defun senju-soldier-step (h hz d)
  "The soldier, each step: frail first (his window or hazard on it: it bursts into red thread and sews one stitch into
him); walks the line to him (*SHINPEI-SPEED*, turning *SHINPEI-TURN*), stops within *SHINPEI-NEAR*, winds up
*SHINPEI-COMBO*'s string (SENJU-SHINPEI-STRIKE), then fades; it stands *SHINPEI-RISE* first."
  (let* ((e (hazard-owner hz)) (o (hazard-target hz)) (m (sjh-model d)))
    (when (or (not (entity-alive-p e)) (not (entity-alive-p o))) (return-from senju-soldier-step nil))
    (anim-advance (model-anim m) +step+)
    (when (and (not (eq (sjh-phase d) :fade)) (senju-frail-hit-p o (hazard-x hz) (hazard-z hz)))
      (destroy-entity (sjh-link d))
      (when (hari-form-p e)                             ; it bursts into thread: one stitch into him
        (set-hari e (min *hari-max* (1+ (hari e)))) (setf (gauges-meter-idle (gauges e)) 0))
      (senju-look e 'senju-burst-look (hazard-x hz) (hazard-z hz) :size 1.0 :life 30)
      (emit :sfx :needle-burst e)
      (sj-count e :soldier-killed)
      (clog "~a SHINPEI destroyed" (side-name e))
      (destroy-entity h)
      (return-from senju-soldier-step t))
    (let* ((q (pos-of o)) (dx (- (aref q 0) (hazard-x hz))) (dz (- (aref q 2) (hazard-z hz))) (dist (sqrt (+ (* dx dx) (* dz dz)))))
      (incf (sjh-clock d))
      (case (sjh-phase d)
        (:rise (when (>= (sjh-clock d) *shinpei-rise*)
                 (setf (sjh-phase d) :walk (sjh-clock d) 0)
                 (anim-play (model-anim m) :sh-walk-f :blend 4)))
        (:walk
         (setf (hazard-yaw hz) (f32 (angle-wrap (turn-toward (hazard-yaw hz) (dir-yaw dx dz) (track-step *shinpei-turn*)))))
         (if (<= dist *shinpei-near*)
             (progn (setf (sjh-phase d) :tell (sjh-clock d) 0 (sjh-n d) 0)
                    (senju-shinpei-strike e hz d dx dz))
             (let ((s (* *shinpei-speed* +step+)) (yaw (hazard-yaw hz)))
               (multiple-value-bind (x z) (clamp-to-circle (+ (hazard-x hz) (* s (fwd-x yaw))) (+ (hazard-z hz) (* s (fwd-z yaw)))
                                                           (- *arena-radius* 0.4))
                 (setf (hazard-x hz) (f32 x) (hazard-z hz) (f32 z))))))
        (:tell (when (>= (sjh-clock d) (first (nth (sjh-n d) *shinpei-combo*)))   ; this hit lands: wind up the next
                 (incf (sjh-n d))
                 (setf (sjh-clock d) 0)
                 (if (< (sjh-n d) (length *shinpei-combo*))
                     (senju-shinpei-strike e hz d dx dz)
                     (setf (sjh-phase d) :fade))))
        (:fade (when (= (sjh-clock d) 12) (anim-play (model-anim m) :sh-crumple :blend 4))
               (when (>= (sjh-clock d) 42) (destroy-entity h) (return-from senju-soldier-step t))))))
  nil)

(defun senju-shinpei-strike (e hz d dx dz)
  "The soldier winds up its string's hit (SJH-N D) at him (DX DZ away): it turns to him, plays the hit's clip to land on
its frame, and spawns the hit waiting that long (a hazard threat: a perfect Hoho reads it)."
  (destructuring-bind (wind clip clip-s vol dmg react stun) (nth (sjh-n d) *shinpei-combo*)
    (let ((yaw (f32 (dir-yaw dx dz))))
      (setf (hazard-yaw hz) yaw)
      (anim-play (model-anim (sjh-model d)) clip :blend 3 :speed (/ (float clip-s) wind))
      (setf (sjh-link d)
            (senju-spawn :sj-hit e (make-sjh :kind :thrust :vol (make-vol (first vol) (rest vol)))
                         :x (hazard-x hz) :z (hazard-z hz) :yaw yaw :delay wind :life 2 :src t
                         :hw (make-hitwin :dmg dmg :react react :stun stun :hs *hitstop-heavy* :guard 14 :flags '(:thread)))))))

;;; ---------------------------------------------------------------- 傘 KASA: the umbrella
(defun senju-kasa-open (e)
  "SP2 f0: nothing caught yet; the canopy of red thread opens between the six hands (a look over the window)."
  (setf (sjs-caught (sj e)) 0)
  (let ((p (pos-of e))) (senju-look e 'senju-kasa-look (aref p 0) (aref p 2) :yaw (yaw-of e) :size 1.2 :life 28 :follow t))
  (emit :sfx :cloth-unfurl e))

(defun senju-kasa-catch (def dmg)
  "A hazard or a ranged hit blocked in the umbrella's window (APPLY-HIT's :catch): no stun, no gauge; the largest one is
kept for the tendrils."
  (let ((st (sj def)))
    (setf (sjs-caught st) (max (sjs-caught st) dmg))
    (sj-count def :catches)
    (emit :sfx :thread-zip def)
    (clog "~a KASA caught ~d" (side-name def) dmg)))

(defun senju-kasa-fire (e)
  "SP2 f28: the tendrils always fire (the user's decision): a :wave from her at him, 16 m/s over 10 m, half-width 0.8 (a side
Step clears it), *KASA-BASE* + half the largest caught hit (<= *KASA-CAP*), stagger, ranged."
  (let* ((q (pos-of (opp-of e))) (yaw (face-yaw-to e (aref q 0) (aref q 2))) (speed (move-param e :speed))
         (dmg (kasa-damage (sjs-caught (sj e)))))
    (let ((p (pos-of e)))
      (spawn-hazard :wave e :x (+ (aref p 0) (fwd-x yaw)) :z (+ (aref p 2) (fwd-z yaw)) :yaw yaw :speed speed
                            :size (* 0.5 (move-param e :width)) :life (round (* 60 (/ (move-param e :range) speed)))
                            :look 'senju-tendril-look
                            :hw (make-hitwin :dmg dmg :react :stagger :hs *hitstop-heavy* :guard (move-param e :guard)
                                             :flags '(:ranged :thread))))
    (sj-count e :tendrils)
    (emit :sfx :thread-zip e)
    (clog "~a KASA fires ~d" (side-name e) dmg)))

;;; ---------------------------------------------------------------- 縫地 NUICHI / 浮文機 UKIMON NO HATA (looks)
(defun senju-nuichi-threads (e)
  "NUICHI's strike: threads shoot from the six hands into the plaza round his feet (a look)."
  (let ((q (pos-of (opp-of e)))) (senju-look e 'senju-pin-look (aref q 0) (aref q 2) :size 1.0 :life 30))
  (emit :sfx :thread-zip e))

(defun senju-carpet (e)
  "UKIMON NO HATA f4: the red carpet rolls out along the lane (a look; the hit is the move's lane)."
  (let ((p (pos-of e))) (senju-look e 'senju-carpet-look (aref p 0) (aref p 2) :yaw (yaw-of e) :size 8.5 :life 40))
  (emit :sfx :cloth-unfurl e))

;;; ---------------------------------------------------------------- the loom: weave, unravel, torn, skip
(defun senju-stored (e) "The passes woven on her form's hank (0-3)." (weave-stored (sjs-woven (sj e))))

(defun senju-weave-tick (e)
  "L held: from *WEAVE-TAP* frames on it is a weave: the hank's woven frames grow (WEAVE-ADD), the bolt is between her hands
(a fragile hazard: a hit on her voids the hank, SENJU-TORN), a shuttle clack per pass."
  (let* ((f (fighter e)) (h (fighter-hold f)) (st (sj e)))
    (when (and (eq (fighter-phase f) :hold) (>= h *weave-tap*))
      (when (= h *weave-tap*)
        (destroy-entity (sjs-bolt st))
        (let ((p (pos-of e)))
          (setf (sjs-bolt st) (senju-spawn :fx e (make-sjh :kind :bolt :hank (move-param e :hank)) :x (aref p 0) :z (aref p 2)
                                           :yaw (yaw-of e) :size 1.0 :life 10000 :delay 10000 :fragile t :look 'senju-bolt-look))))
      (let ((w (sjs-woven st)) (w2 (weave-add (sjs-woven st) h)))
        (setf (sjs-woven st) w2)
        (when (> (weave-stored w2) (weave-stored w))
          (sj-count e :passes-woven)
          (emit :sfx :shuttle e))))))

(defun senju-weave-release (e)
  "L let go (the move's :release, WEAVE-RELEASE-ACT): a tap with a pass stored goes on to the release (S 6,
SENJU-UNRAVEL); a weave just stops (the bolt goes, the passes stay on the hank), 6 f back to the stance; a tap with
nothing woven or over a live zone is refused (the :refused cue: the HUD's loom row flashes), then stops."
  (let* ((f (fighter e)) (st (sj e)) (act (weave-release-act (fighter-hold f) (sjs-woven st) (senju-live-zones e))))
    (unless (eq act :release)
      (if (eq act :stop)
          (sj-count e :weave-segments)
          (progn (emit :refused e :sig) (sj-count e :refused) (clog "~a refused L: ~d passes stored" (side-name e) (senju-stored e))))
      (destroy-entity (sjs-bolt st))
      (start-move e (find-move :sj-weave-stop)))))

(defun senju-quick-weave (e)
  "HITOKOSHI f8 (J -> L): one pass onto the form's hank at once (QUICK-WEAVE, at most three), the shuttle's clack."
  (let* ((st (sj e)) (w (sjs-woven st)) (w2 (quick-weave w)))
    (setf (sjs-woven st) w2)
    (when (> (weave-stored w2) (weave-stored w)) (sj-count e :passes-woven))
    (sj-count e :quick-weaves)
    (emit :sfx :shuttle e)
    (clog "~a HITOKOSHI ~d passes" (side-name e) (weave-stored w2))))

(defun senju-bolt-step (h hz d)
  "The weave's bolt, each step: it stays in her hands while she weaves (the hold, then the S frames before the unravel);
gone silently otherwise (only a hit tears it: CLOSE-RIFTS)."
  (declare (ignore d))
  (let* ((e (hazard-owner hz)) (f (and (entity-alive-p e) (fighter e))) (mv (and f (fighter-move f))))
    (if (and f (eq (fighter-state f) :move) mv (getf (mv-params mv) :hank)
             (or (eq (fighter-phase f) :hold) (and (eq (fighter-phase f) :main) (< (fighter-sf f) (mv-s mv)))))
        (let ((p (pos-of e))) (setf (hazard-x hz) (aref p 0) (hazard-z hz) (aref p 2) (hazard-yaw hz) (yaw-of e)) nil)
        (progn (destroy-entity h) t))))

(defun senju-torn (e hank advance)
  "A hit on her tore the hank. While she weaves (ADVANCE): it is void (the user, 2026-09-29): its passes are lost and the
form moves on to the next hank (WEAVE-VOID), no lock. An unfolding zone (it had already moved the form on): L locked
*TORN-LOCK* (its cooldown timer: no COOLDOWN row)."
  (let ((f (fighter e)) (st (sj e)))
    (setf (sjs-torn st) *match-tick* (sjs-torn-hank st) hank)
    (if (and advance (form-hank (fighter-form f)))
        (multiple-value-bind (next woven) (weave-void (form-hank (fighter-form f)))
          (setf (sjs-woven st) woven)
          (set-form e (hank-form next)))
        (setf (aref (fighter-cd f) (position :sig *kit-commands*)) *torn-lock*))
    (sj-count e :torn)
    (emit :sfx :shears e)
    (clog "~a TORN hank ~d" (side-name e) hank)))

(defun senju-live-zones (e) "Her live zones (one, or TACHINAOSHI's two)." (let ((st (sj e))) (remove-if-not #'entity-alive-p (list (sjs-live st) (sjs-live2 st)))))
(defun senju-live-zone (e n)
  "Her live zone of hank N, unfolded, or NIL."
  (find-if (lambda (z) (let ((hz (hazard z))) (and hz (<= (hazard-delay hz) 0) (= n (sjh-hank (hazard-data hz))))))
           (senju-live-zones e)))
(defun senju-cut-live (e)
  "Every live zone of hers ends (not torn). T when there was one."
  (let ((st (sj e)) (any (senju-live-zones e)))
    (destroy-entity (sjs-live st)) (destroy-entity (sjs-live2 st))
    (and any t)))

(defun senju-combo-cut (e)
  "The combo cut's frame 0 (and TACHINAOSHI's): the live zones end (not torn), the next unravel under him."
  (when (senju-cut-live e) (sj-count e :combo-cuts)))

(defun senju-tachi-release (e)
  "TACHINAOSHI's f8 / f14: the form's next hank unravels as the combo cut's does (unfold *UNFOLD-COMBO*) at the passes
stored when the move began (both hanks; the coordinator's default, 2026-09-29) and the form advances; the second keeps
the first alive beside it (LIVE2). Its name is called out."
  (let* ((f (fighter e)) (st (sj e)) (n (form-hank (fighter-form f))) (second (> (fighter-sf f) (mv-s (fighter-move f)))))
    (when n
      (if second
          (setf (sjs-live2 st) (sjs-live st) (sjs-live st) -1)   ; the first stays
          (setf (sjs-tachi st) (sjs-woven st)))                 ; (the level both use)
      (senju-cast e n (release-passes (sjs-tachi st)) *unfold-combo*)
      (sj-count e :tachi-hanks)
      (clog "~a TACHINAOSHI hank ~d" (side-name e) n)
      (callout e (hank n :name))
      (play-clip e :sj-unravel :blend 0 :time (/ 6 60.0)))))   ; (the fling of the unravel, once per hank)

(defun senju-unravel (e)
  "L's release + S (or the combo cut's S): the weave's bolt goes, the hank of the move unravels as its zone (unfolding
*UNFOLD* / *UNFOLD-COMBO* frames, fragile: SENJU-TORN), the form advances to the next hank."
  (let* ((st (sj e)) (n (move-param e :hank)) (combo (move-param e :combo))
         (passes (release-passes (sjs-woven st))) (unfold (if combo *unfold-combo* *unfold*)))
    (destroy-entity (sjs-bolt st))
    (senju-cut-live e)
    (senju-cast e n passes unfold)
    (sj-count e :weaves)
    (clog "~a UNRAVEL hank ~d passes ~d~:[~; (combo)~]" (side-name e) n passes combo)))

(defun senju-cast (e n passes unfold)
  "Hank N unravels as her live zone at the cast point under him (PASSES, UNFOLD frames); the form advances past it."
  (let* ((st (sj e)) (p (pos-of e)) (q (pos-of (opp-of e))))
    (multiple-value-bind (cx cz) (cast-point (aref p 0) (aref p 2) (aref q 0) (aref q 2) *hank-range*)
      (let ((z (senju-zone e n passes unfold cx cz)))
        (setf (sjs-live st) z (sjs-live-hank st) n
              (sjs-live-life st) (max 1 (let ((hz (hazard z))) (if hz (hazard-life hz) 1))))))
    (set-form e (hank-form (hank-next n)))
    (setf (sjs-woven st) 0)                             ; (a new hank: nothing woven on it yet)
    (sj-count e (hank-key n "CAST")) (sj-count e :passes passes)
    (emit :sfx :cloth-unfurl e)))

(defun senju-zone (e n passes unfold cx cz)
  "Hank N's zone at (CX CZ) (the cast point; 焼野原 runs from her, 星 is round her) after PASSES: its hazard, unfolding
UNFOLD frames (fragile), with SENJU-HZ as its hook."
  (let* ((r (hank-radius-or n passes)) (life (if (hank n :life) (hank-life n passes) 999)) (dmg (and (hank n :dmg) (hank-damage n passes)))
         (d (make-sjh :kind :zone :hank n :passes passes :r (f32 r) :x0 (f32 cx) :z0 (f32 cz) :phase unfold   ; (the look's unfold)
                      :combo (< unfold *unfold*)))
         (p (pos-of e)))
    (case n
      (4 (senju-spawn :freeze e d :x cx :z cz :size r :y 0.6 :delay unfold :life life :src t :fragile t :look 'senju-zone-look
                      :hw (make-hitwin :dmg dmg :react :bind :stun (round (hank-fx 4 :freeze passes)) :hs *hitstop-heavy* :guard 12
                                       :frost (round (hank-fx 4 :frost passes)) :flags '(:ice))))
      (5 (let* ((q (pos-of (opp-of e))) (yaw (face-yaw-to e (aref q 0) (aref q 2)))
                (dist (sqrt (+ (expt (- (aref q 0) (aref p 0)) 2) (expt (- (aref q 2) (aref p 2)) 2))))
                (len (min (hank 5 :max) (+ 0.5 dist))) (mid (+ 1.0 (* 0.5 len))))   ; from 1 m ahead of her, past him 1.5 m
           (setf (sjh-len d) (f32 len) (sjh-x0 d) (f32 (+ (aref p 0) (fwd-x yaw))) (sjh-z0 d) (f32 (+ (aref p 2) (fwd-z yaw))))
           (senju-spawn :sj-lane e d :x (+ (aref p 0) (* mid (fwd-x yaw))) :z (+ (aref p 2) (* mid (fwd-z yaw))) :yaw yaw
                        :size (* 0.5 (hank 5 :width)) :delay unfold :life life :hits (hank 5 :hits) :src t :fragile t
                        :look 'senju-zone-look
                        :hw (make-hitwin :dmg dmg :react :stagger :hs *hitstop-heavy* :guard 12 :chip (hank-fx 5 :chip passes)))))
      (6 (setf (sjh-x0 d) (aref p 0) (sjh-z0 d) (aref p 2))
         (senju-spawn :sj-zone e d :x (aref p 0) :z (aref p 2) :size r :delay unfold :life life :src t :fragile t
                      :look 'senju-zone-look))
      (t (senju-spawn :sj-zone e d :x cx :z cz :size r :delay unfold :life life :src t :fragile t :look 'senju-zone-look)))))

(defun hank-radius-or (n passes) (if (hank n :r) (hank-radius n passes) (* 0.5 (hank n :width))))

(defun senju-zone-step (h hz d)
  "A zone, each step once unfolded (HAZARD-AGE = frames since): 眼 turns his waves back; 刃金 closes once; 黒砂 drags his
walk away from its centre and gulps; 褥 and 焼野原 end once spent; 星 drains his Reiatsu and flash-step into hers (what it
really takes, each of hers kept at its max; the user, 2026-09-29: SENJU-SIPHON takes his gains too)."
  (let* ((e (hazard-owner hz)) (o (hazard-target hz)) (n (sjh-hank d)) (age (hazard-age hz)))
    (when (or (plusp (hazard-delay hz)) (not (entity-alive-p o))) (return-from senju-zone-step nil))
    (let* ((q (pos-of o)) (dx (- (aref q 0) (hazard-x hz))) (dz (- (aref q 2) (hazard-z hz)))
           (dist (sqrt (+ (* dx dx) (* dz dz)))) (inside (<= dist (sjh-r d))))
      (case n
        (1 (do-entities (w (wz hazard))                 ; the mirror-eyes: his waves / fireballs turn back
             (when (and (eql (hazard-owner wz) o) (member (hazard-kind wz) '(:wave :fireball)) (> (hazard-hits-left wz) 0)
                        (<= (+ (expt (- (hazard-x wz) (hazard-x hz)) 2) (expt (- (hazard-z wz) (hazard-z hz)) 2))
                            (expt (+ (sjh-r d) (hazard-size wz)) 2)))
               (setf (hazard-owner wz) e (hazard-yaw wz) (f32 (angle-wrap (+ (hazard-yaw wz) +pi+))) (hazard-src wz) nil
                     (sjh-look-t d) (f32 (fx-clock)))
               (sj-count e :reflects)
               (emit :sfx :shears e)
               (clog "~a ME reflects a ~a" (side-name e) (hazard-kind wz)))))
        (2 (when (= age (if (sjh-combo d) 0 (hank 2 :rise)))   ; the maiden closes: once (the combo cut: at once)
             (senju-spawn :freeze e (make-sjh :kind :maiden :hank 2) :x (hazard-x hz)
                          :z (hazard-z hz) :size (sjh-r d) :y 2.2 :life 2 :src t
                          :hw (make-hitwin :dmg (hank-damage 2 (sjh-passes d)) :react :crumple :hs *hitstop-heavy*
                                           :guard (round (hank-fx 2 :guard (sjh-passes d))) :flags '(:thread)))
             (setf (hazard-life hz) (+ age (hank 2 :after)))
             (emit :sfx :ground-crack e)))
        (3 (when (and inside (member (fighter-state (fighter o)) '(:idle :run)))   ; the drag: walking / running away
             (let* ((v (motion-vel (motion o))) (ux (/ dx (max dist 1e-3))) (uz (/ dz (max dist 1e-3)))
                    (along (+ (* (aref v 0) ux) (* (aref v 2) uz))))
               (when (> along 0)
                 (let ((k (* (min 1.0 (* (nth-value 3 (hank-scale (sjh-passes d))) (- 1.0 (hank 3 :away)))) along +step+)))
                   (setf (aref q 0) (f32 (- (aref q 0) (* k ux))) (aref q 2) (f32 (- (aref q 2) (* k uz))))))))
           (let ((period (hank 3 :period)))                 ; the gulps: 1 / 2 / 3 by passes, a 12 f swirl before each
             (when (and (< (sjh-n d) (sjh-passes d))
                        (= age (if (sjh-combo d) 0 (- (* period (1+ (sjh-n d))) (hank 3 :swirl)))))
               (incf (sjh-n d))
               (setf (sjh-look-t d) (f32 (fx-clock)))
               (senju-spawn :freeze e (make-sjh :kind :gulp :hank 3 :x0 (hazard-x hz) :z0 (hazard-z hz)) :x (hazard-x hz)
                            :z (hazard-z hz) :size (sjh-r d) :y 1.8 :delay (if (sjh-combo d) 0 (hank 3 :swirl)) :life 2 :src t
                            :hw (make-hitwin :dmg (hank-damage 3 (sjh-passes d)) :react :stagger :hs *hitstop-heavy* :guard 12
                                             :flags '(:thread)))
               (emit :sfx :ground-crack e))))
        ((4 5) (when (<= (hazard-hits-left hz) 0)          ; spent: the loom is free
                 (destroy-entity h) (return-from senju-zone-step t)))
        (6 (when inside                                     ; the star drains him into her
             (let ((g (gauges o)) (mine (gauges e)))
               (multiple-value-bind (his hers) (gauge-move (gauges-reiatsu g) (/ (hank-fx 6 :reiatsu (sjh-passes d)) 60.0) (gauges-reiatsu mine) *reiatsu-max*)
                 (setf (gauges-reiatsu g) (f32 his) (gauges-reiatsu mine) (f32 hers)))
               (multiple-value-bind (his hers) (gauge-move (gauges-fs g) (/ (hank-fx 6 :fs (sjh-passes d)) 60.0) (gauges-fs mine) *fs-max*)
                 (setf (gauges-fs g) (f32 his) (gauges-fs mine) (f32 hers)))
               (sj-count e :drain-frames)))))))
  nil)

(defun senju-siphon (e o)
  "Her kit's :siphon hook (combat.lisp SIPHON-OF): O stands in her live 星, unfolded (the user, 2026-09-29): he gains
nothing from a hit, a block or his blade, and his Reiatsu / flash-step gains are hers."
  (let ((z (senju-live-zone e 6)))
    (and z (let ((hz (hazard z)) (q (pos-of o)))
             (<= (+ (expt (- (aref q 0) (hazard-x hz)) 2) (expt (- (aref q 2) (hazard-z hz)) 2)) (expt (sjh-r (hazard-data hz)) 2))))))

(defun senju-closed (h hz d)
  "CLOSE-RIFTS closed one of her fragile hazards (a real hit on her): a weave's bolt or an unfolding zone is torn."
  (declare (ignore h))
  (let ((e (hazard-owner hz)))
    (when (entity-alive-p e)
      (case (sjh-kind d)
        (:bolt (senju-torn e (sjh-hank d) t))
        (:zone (senju-torn e (sjh-hank d) nil))))))

(defun senju-touches (hz d tx ty tz tr th)
  "The volume of her own kinds: the soldier's thrust (a capsule in its frame), 焼野原's lane (a box 2 m wide, its length)."
  (case (hazard-kind hz)
    (:sj-hit (let ((yaw (hazard-yaw hz)))
               (vol-hit-p (sjh-vol d) (hazard-x hz) 0f0 (hazard-z hz) (f32 (fwd-x yaw)) (f32 (fwd-z yaw)) tx ty tz tr th 0f0)))
    (:sj-lane (obox-cyl-hit-p (hazard-x hz) 1f0 (hazard-z hz) (hazard-yaw hz) (hazard-size hz) 1.2f0 (f32 (* 0.5 (sjh-len d)))
                              tx ty tz tr th))
    (t nil)))

(defun senju-hz (h hz ev &optional a b c dd ee)
  "Her hazards' hook (HAZARD-HOOK): :step, :close, :touches by the data's kind."
  (let ((d (hazard-data hz)))
    (case ev
      (:step (case (sjh-kind d)
               ((:spike :follow) (let* ((tg (if (eq (sjh-kind d) :spike) (hazard-target hz) (hazard-owner hz))))   ; stuck to him /
                                   (when (entity-alive-p tg)                                                        ; her
                                     (let ((q (pos-of tg))) (setf (hazard-x hz) (aref q 0) (hazard-z hz) (aref q 2)))))
                                 nil)
               (:soldier (senju-soldier-step h hz d))
               (:bolt (senju-bolt-step h hz d))
               (:zone (senju-zone-step h hz d))
               (t nil)))
      (:close (senju-closed h hz d))
      (:touches (senju-touches hz d a b c dd ee)))))

;;; ================================================================ AI (the kit's :reflex / :opp-reflex / :sig-hold)

;;; The action policy v2 (docs/DUEL_AI_V2.md; research_notes/ai-v2-drsi/senjumaru): every chance below by difficulty
;;; (SENJU-DP: EASY <= NORMAL <= HARD, NORMAL near the shipped CPU, HARD the full version).
;;;   enders    a J3 / K3 that hit pushes him out: the O ender (it always dashes after him) at :o-ender-p; else, after K3,
;;;             the stitches' L (WARUI KUSE, its K copy chases) with >= 3 stitches. The loom: SP1 first (SENJU-SP-ENDER).
;;;   punish    a recovery seen too far for J1: K1 (its line reaches 2.9 m, the loom's 3.8 m) when it lands in time, else the
;;;             O (the flash step: aura 6 + the dash at 26 m/s + S 8; the loom's lane: aura 8 + S 20) within its range
;;;   stitches  the spikes are unguardable: L with >= 3 stitches on a guard, a recovery or a reel he can't Hoho out of
;;;             before f10; against a J masher (AI-MASH-P: he never steps out) with >= 2
;;;   breaker   a guard held past *AI-GUARD-BREAK-HOLD* up close: SAIDAN at :break-p (the generic roll's 0.4 at NORMAL);
;;;             his own Breaker coming: the O meets it in its aura / dash (:anti-breaker-p; her J1 only by frames)
;;;   neutral   the Shikai's decisions at :neutral-p from *SENJU-NEUTRAL* (Breaker / K1 / O over J trades); the loom
;;;             keeps the kit's bands and its SP1 pairs (closer loom bands and fewer pairs both measured worse)
(defparameter *senju-dp*
  '(:o-ender-p (:easy 0.0 :normal 0.05 :hard 0.85)
    :l-ender-p (:easy 0.0 :normal 0.05 :hard 0.7)
    :punish-p (:easy 0.0 :normal 0.1 :hard 0.8)
    :hari-p (:easy 0.0 :normal 0.1 :hard 0.85)
    :break-p (:easy 0.3 :normal 0.4 :hard 0.7)
    :anti-breaker-p (:easy 0.0 :normal 0.1 :hard 0.85)
    :neutral-p (:easy 0.0 :normal 0.0 :hard 0.7)
    ;; the set-play conversion (cell b1a0, stacked in b0a1): SENJU-SETPLAY-REFLEX, SENJU-OKI, the loom's TACHINAOSHI ender
    :follow-p (:easy 0.0 :normal 0.15 :hard 0.9)
    :escort-p (:easy 0.0 :normal 0.1 :hard 0.8)
    :oki-p (:easy 0.0 :normal 0.2 :hard 0.9)
    :tachi-p (:easy 0.3 :normal 0.5 :hard 0.9))
  "Her CPU's policy chances by difficulty (SENJU-DP).")

(defparameter *senju-neutral*
  '((0.0 1.7 :q 4 :breaker 3 :f 1)
    (1.7 2.6 :breaker 2 :f 2 :kikon 1)
    (2.6 7.5 :kikon 2 :sp1 1 nil 2))
  "The Shikai's neutral bands of the policy (:neutral-p of the decisions): the Breaker on the guard every CPU holds, K1
and the O where J1 can't reach; beyond 7.5 m the kit's own bands.")

(defun senju-dp (b key)
  "Policy chance KEY of *SENJU-DP* at brain B's difficulty."
  (let ((p (getf *senju-dp* key))) (getf p (brain-difficulty b) (getf p :normal 0.0))))

(defun senju-o-arrive (mv d)
  "Frames her O rush MV takes to strike from D m: its aura, the dash to its strike reach, its startup."
  (+ (rush-param mv :aura) (mv-s mv)
     (if (plusp (rush-param mv :speed)) (ceiling (* 60 (max 0.0 (- d (mv-reach mv)))) (rush-param mv :speed)) 0)))

(defun senju-policy-reflex (e b s d)
  "The policy's free-state reflexes (above): the far punish, the stitches on a hit he can't leave, the long guard's
Breaker. A command or NIL."
  (let* ((f (fighter e)) (kit (fighter-kit f)) (q (kit-command-move kit :q)) (k (kit-command-move kit :f))
         (o (kit-command-move kit :kikon)) (left (- (snap-left s) (brain-delay b))))
    (cond
      ;; his Breaker's aura / dash coming (it strikes from 0.95 m, under her J1's reach only by frames): the Shikai's O
      ;; meets it from up to 6 m (aura 6 + the flash step + S 8); the loom's lane (aura 8 + S 20) only from 3 m out
      ((and o (eq (snap-kind s) :breaker) (member (snap-phase s) '(:aura :dash)) (< d 6.0)
            (or (hari-form-p e) (> d 3.0)) (kit-command-ok-p e :kikon)
            (< (brain-react-roll b) (senju-dp b :anti-breaker-p)))
       (why b :anti-breaker-o :kikon))
      ;; a neutral decision due (AI-NEUTRAL's clock), the Shikai: the policy's own bands (*SENJU-NEUTRAL*) at :neutral-p
      ;; (the loom keeps the kit's: its zoning bands measured better than close ones)
      ((and (hari-form-p e) (member (fighter-state f) '(:idle :run)) (<= (brain-decide-t b) 1)
            (not (and (eq (brain-act b) :dash) (plusp (brain-press-left b))))
            (not (member (snap-state s) '(:down :wakeup :hoho)))
            (band-weights *senju-neutral* d)
            (< (sim-rnd01) (senju-dp b :neutral-p)))
       (setf (brain-decide-t b) (+ (getf *ai-think* (brain-difficulty b) 24) (floor (* 40 (sim-rnd01)))))
       (let ((c (apply #'weighted-pick (sim-rnd01) (band-weights *senju-neutral* d))))
         (and c (kit-command-ok-p e c)
              (or (not (member c '(:q :f))) (<= d (+ 0.2 (mv-reach (kit-command-move kit c)))))
              (not (and (eq c :kikon) (ai-sb-finish-p e)))
              (why b :neutral-v2 c))))
      ;; a recovery out of J1's reach: K1, else the O
      ((and (eq (snap-state s) :move) (eq (snap-phase s) :main) (>= (snap-sf s) (snap-active-end s)) (< (snap-left s) 99)
            (>= d (+ (mv-reach q) 0.4)) (< (brain-react-roll b) (senju-dp b :punish-p)))
       (cond ((and k (< d (+ (mv-reach k) 0.2)) (>= left (+ (mv-s k) 1)) (kit-command-ok-p e :f)) (why b :far-punish :f))
             ((and o (< d (ai-table e :kikon-range 7.0)) (>= left (+ (senju-o-arrive o d) 1)) (kit-command-ok-p e :kikon)
                   (not (ai-sb-finish-p e)))
              (why b :far-punish :kikon))))
      ;; the stitches: unguardable, so a guard, a recovery or a reel is where they land
      ((and (hari-form-p e) (>= (hari e) 2) (kit-command-ok-p e :sig)
            (or (and (>= (hari e) 3)
                     (or (member (snap-state s) '(:guard :guard-hit))
                         (and (member (snap-state s) '(:move :stun)) (< (snap-left s) 99) (>= left 12))))
                (ai-mash-p b))
            (< (brain-hoho-roll b) (senju-dp b :hari-p)))
       (why b :hari-sure :sig))
      ;; a long guard up close: SAIDAN (the generic roll's key: one roll per guard)
      ((and (eq (snap-state s) :guard) (>= (snap-guard-t s) *ai-guard-break-hold*) (< d *ai-guard-break-range*)
            (/= (brain-break-key b) (snap-start s)) (kit-command-ok-p e :breaker))
       (setf (brain-break-key b) (snap-start s))
       (and (< (sim-rnd01) (senju-dp b :break-p)) (why b :guard-break :breaker))))))

(defun senju-soldier-live-p (e)
  "Her Divine Soldier stands, walks or strikes (not fading)."
  (let ((id (sjs-soldier (sj e))))
    (and (entity-alive-p id) (let ((hz (hazard id))) (and hz (member (sjh-phase (hazard-data hz)) '(:rise :walk :tell)))))))

(defun senju-setplay-reflex (e b s d)
  "The set-play policy's reflexes (above): FOLLOW returns a command; ESCORT only moves the intent (NIL)."
  (let* ((kit (kit-of e)) (q (kit-command-move kit :q)) (k (kit-command-move kit :f)) (o (kit-command-move kit :kikon))
         (left (- (snap-left s) (brain-delay b))))
    (cond
      ((and (eq (snap-state s) :stun) (< (snap-left s) 99) (>= d (+ (mv-reach q) 0.6))   ; (closer: the generic Q follow-up)
            (not (ai-mash-p b)) (< (brain-react-roll b) (senju-dp b :follow-p)))
       (cond ((and k (<= d (+ (mv-reach k) 0.1)) (>= left (+ (mv-s k) 1)) (kit-command-ok-p e :f)) (why b :set-follow :f))
             ((and o (<= d (ai-table e :kikon-range 7.0)) (>= left (+ (senju-o-arrive o d) 1)) (kit-command-ok-p e :kikon)
                   (not (ai-sb-finish-p e)))
              (why b :set-follow :kikon))
             ;; nothing of hers reaches him in time: what is stuck in him or laid under him does (the spikes from f10;
             ;; TACHINAOSHI's first hank at f8 + the combo cut's 10 f unfold)
             ((and (hari-form-p e) (>= (hari e) 2) (>= left 11) (kit-command-ok-p e :sig)) (why b :set-follow :sig))
             ((and (form-hank (kit-form kit)) (>= left 19) (kit-command-ok-p e :sp1)
                   (multiple-value-bind (a2 b2) (tachi-hanks (form-hank (kit-form kit))) (or (hank-hits-p a2) (hank-hits-p b2))))
              (why b :set-follow :sp1))))
      ((and (member (snap-state s) '(:down :wakeup)) (<= 2.5 d *hank-range*) (< (brain-react-roll b) (senju-dp b :oki-p)))
       (senju-oki e b s kit))
      ((and (> d 2.4) (senju-soldier-live-p e) (< (brain-hoho-roll b) (senju-dp b :escort-p)))
       (setf (brain-intent b) :pressure (brain-intent-t b) (max (brain-intent-t b) 20))
       nil))))

(defun senju-oki (e b s kit)
  "He is down (invulnerable: :down then :wakeup, 30 f each) out of her reach: set the next threat where he gets up. The loom
with a hitting hank next (刃金 黒砂 褥 焼野原) and nothing live: weave while nothing stored (he can't tear it), else tap
the release so it is out when he is up (褥 / 黒砂 / 焼野原 last; 刃金 closes once, 43 f after the tap: only when that is
past his wake-up); the Shikai: the soldier (SP1) walks to him. A command or NIL."
  (let ((n (form-hank (kit-form kit)))
        (inv (- (if (eq (snap-state s) :down) (- 60 (snap-sf s)) (- 30 (snap-sf s))) (brain-delay b))))
    (cond ((and n (member n '(2 3 4 5)) (null (senju-live-zones e)) (kit-command-ok-p e :sig))
           (cond ((< (senju-stored e) 1) (why b :oki-weave :sig))
                 ((or (/= n 2) (<= inv 43)) (why b :oki-tap :sig))))
          ((and (hari-form-p e) (not (senju-soldier-live-p e)) (kit-command-ok-p e :sp1)) (why b :oki-soldier :sp1)))))

(defun senju-base-ender (e kit)
  "The Shikai's :sp-ender (ai.lisp STRING-REFLEX, a J3 / K3 that hit, the push begun): the O ender (:o-ender-p; not
when hits finish him, AI-SB-FINISH-P); else after K3 the stitches' L with >= 3 (:l-ender-p)."
  (let* ((b (brain e)) (f (fighter e)) (mv (fighter-move f)))
    (cond ((and (member :ender (mv-flags mv)) (not (ai-sb-finish-p e)) (kit-command-ok-p e :kikon kit t)
                (< (sim-rnd01) (senju-dp b :o-ender-p)))
           :kikon)
          ((and (kit-k-link-p kit (mv-name mv)) (>= (hari e) 3) (kit-l-link kit (mv-name mv))
                (kit-command-ok-p e :sig kit nil (kit-l-link kit (mv-name mv))) (< (sim-rnd01) (senju-dp b :l-ender-p)))
           :sig))))

(defun senju-ai-reflex (e b s d)
  "Her CPU's own reflexes (free states): the policy's (SENJU-POLICY-REFLEX); the Shikai's L when the stitches pay (:hari (:min :hurry): >= :min now and then, always with >= 2 when the
first falls within :hurry frames); the loom's SP1 on a designed pair that suits (SENJU-PAIR-P, no zone live, now and
then). A command or NIL."
  (let* ((f (fighter e)) (g (gauges e)) (kit (fighter-kit f)) (ai (kit-ai kit)) (n (form-hank (kit-form kit))))
    (cond ((senju-policy-reflex e b s d))
          ((senju-setplay-reflex e b s d))
          ((and n (null (senju-live-zones e)) (kit-command-ok-p e :sp1) (senju-pair-p e b d n) (< (sim-rnd01) *ai-senju-pair*))
           (why b :pair :sp1))
          ((and (getf ai :hari) (hari-form-p e) (kit-command-ok-p e :sig))
           (let ((n (hari e)) (h (getf ai :hari)))
             (and (or (and (>= n 2) (<= (hari-falls-in n (gauges-meter-idle g)) (getf h :hurry 40)))
                      (and (>= n (getf h :min 4)) (< (sim-rnd01) *ai-senju-hari*)))
                  (why b :hari :sig)))))))

(defun senju-pair-p (e b d n)
  "Does the designed pair SP1 releases from next hank N suit now (a cross pair never does)? 黒砂 + 刃金 near him (under
3 m), 褥 + 焼野原 at mid range (3-7 m), 眼 + 星 when he zones (beyond 7 m, or 30 % of what she took was ranged) or she
defends."
  (and (tachi-aligned-p n)
       (case n
         (3 (< d 3.0))
         (4 (<= 3.0 d 7.0))
         (1 (let ((g (gauges e)))
              (or (> d 7.0) (eq (brain-intent b) :defend)
                  (> (gauges-taken-ranged g) (* 0.3 (+ (gauges-taken-ranged g) (gauges-taken-melee g))))))))))

(defun senju-sp-ender (e kit)
  "The loom's :sp-ender (ai.lisp STRING-REFLEX, a landed string's last link): SP1 when one of the two hanks it releases
hits, *AI-SENJU-TACHI* of the time on a designed pair, half that on a cross pair; else (the policy v2) the O ender, the
lane, at :o-ender-p (not when hits finish him)."
  (let ((n (form-hank (kit-form kit))) (mv (fighter-move (fighter e))))
    (or (and n (kit-command-ok-p e :sp1) (multiple-value-bind (a b) (tachi-hanks n) (or (hank-hits-p a) (hank-hits-p b)))
             (< (sim-rnd01) (* (if (brain e) (senju-dp (brain e) :tachi-p) *ai-senju-tachi*) (if (tachi-aligned-p n) 1.0 0.5))) :sp1)
        (and (brain e) (member :ender (mv-flags mv)) (not (ai-sb-finish-p e)) (kit-command-ok-p e :kikon kit t)
             (< (sim-rnd01) (senju-dp (brain e) :o-ender-p)) :kikon))))

(defun senju-opp-reflex (e b s d)
  "A CPU facing her (her kit's :opp-reflex, read off her kit: every other pairing unchanged): while she holds a weave within
9 m, one roll per hold at her :opp-rush-hold: rush with O within its kikon-range, else dash in, to tear it."
  (let* ((o (opp-of e)) (p (getf (kit-ai (kit-of o)) :opp-rush-hold)))
    (when (and p (eq (snap-state s) :move) (eq (snap-phase s) :hold) (eq (snap-kind s) :sig) (< d 9.0)
               (< (brain-react-roll b) p))
      (cond ((and (< d (ai-table e :kikon-range 7.0)) (kit-command-ok-p e :kikon)) (why b :tear :kikon))
            (t (ai-dash b 1.0 1.8) (why b :tear :pressed))))))

(defun senju-sig-hold (kit d &optional e)
  "Frames her CPU holds L (E: her, for the stored passes): the Shikai taps it. The loom wants 3 passes beyond :far, 2 beyond
:near and 1 inside :near (a tap needs one stored; 星, cast round her: :far 5 / :near 2.5); short of them it weaves one segment (at most
*WEAVE-SEG* frames, never a stand into a rush: each segment is a new decision), else it taps (the release at the stored
level). On a cross slot with a bar for SP1 it wants one pass: the quick single release that realigns the pairs."
  (if (or (not (form-hank (kit-form kit))) (and e (brain e) (eq (brain-why (brain e)) :oki-tap)))   ; (the oki's tap)
      1
      (let* ((w (getf (kit-ai kit) :weave)) (hoshi (eq (kit-form kit) :tsuji6))
             (far (if hoshi 5.0 (getf w :far 6.5))) (near (if hoshi 2.5 (getf w :near 4.0)))
             (want (cond ((> d far) 3) ((> d near) 2) (t 0))) (woven (if e (sjs-woven (sj e)) 0))
             (fix (and e (not (tachi-aligned-p (form-hank (kit-form kit))))    ; (a cross slot, a bar: realign)
                       (>= (floor (gauges-reiatsu (gauges e)) *reiatsu-bar*) (kit-command-cost kit :sp1))))
             (want (cond ((and e (senju-live-zones e)) 3)   ; (a zone lives: weave the next one up meanwhile;
                         (fix 1)                            ; nothing stored: one pass, never a refused tap)
                         (t (max 1 want)))))
        (if (<= want (weave-stored woven))
            1
            (+ 1 (max *weave-tap* (min *weave-seg* (- (* want *weave-pass*) woven))))))))

;;; ================================================================ HUD: her meter (hud.lisp's meter :draw / :label; the kit's :deck)
(defparameter *hank-dyes*
  '((0.416 0.353 0.494) (0.659 0.565 0.306) (0.133 0.133 0.165) (0.369 0.471 0.565) (0.494 0.227 0.204) (0.18 0.212 0.337))
  "The six hanks' dyes (S <= 0.45): 眼 purple, 刃金 gold, 黒砂 ink, 褥 blue, 焼野原 madder, 星 night blue.")
(defun hank-dye (n) (nth (1- n) *hank-dyes*))

(defun senju-hud-label (g kit)
  "The portrait block's label: HARI n, or the next hank's short name."
  (let ((n (form-hank (kit-form kit))))
    (if n (hank n :short) (format nil "HARI ~d" (round (gauges-meter g))))))

(defun-fast %sj-needle (x y w h lit flick)
  "One needle pip (a gold needle standing in the W x H slot at (X Y)); LIT: its eye threaded BLOOD; FLICK: its alpha."
  (declare (single-float x y w h flick) (boolean lit))
  (let* ((cx (+ x (* 0.5f0 w))) (nw (f-max 1f0 (* 0.16f0 w))) (a (if lit flick 0.8f0)))
    (declare (single-float cx nw a))
    (%hq (- cx nw) (+ y (* 0.18f0 h)) (+ cx nw) (+ y (* 0.18f0 h)) cx (+ y h) cx (+ y h)   ; the shaft, to the point
         (if lit 0.76f0 0.25f0) (if lit 0.66f0 0.24f0) (if lit 0.4f0 0.26f0) a)
    (%hrect (- cx nw) y (* 2f0 nw) (* 0.2f0 h) (if lit 0.76f0 0.25f0) (if lit 0.66f0 0.24f0) (if lit 0.4f0 0.26f0) a)   ; the eye
    (when lit (%hrect (- cx (* 0.5f0 nw)) (+ y (* 0.05f0 h)) nw (* 0.1f0 h) 0.82f0 0.06f0 0.11f0 a))   ; the thread
    nil))

(defun senju-hud-meter (e kit x y w h right tm lx ly ls)
  "Her kit-meter row (LX LY LS: where the landscape label goes, NIL in the portrait slot): the Shikai's six needle pips
(lit by the stitches, the next to fall flickering in its last 30 f, a refused L flashes the row) and the brush 針 HARI;
the Bankai's six hank swatches in the queue's order, in its three SP1 pairs (the next lit and raised, filling in three
steps while she weaves, the live zones' draining, a torn one slashed, a refused release washing the next one white; the
two SP1 would release framed: one gold frame round a designed pair, a grey one round each of a cross pair; bright with
the bar for it) and the brush 機 + the next hank's short name."
  (let* ((f (fighter e)) (g (gauges e)) (st (sj e)) (side (fighter-side f)) (x (f32 x)) (y (f32 y)) (w (f32 w)) (h (f32 h))
         (next (form-hank (kit-form kit))) (pw (if next (/ w 7.5) (/ w 6.6))) (gap (* 0.12 pw)) (pgap (if next (* 0.45 pw) 0.0))
         (hh (* 2.6 h)) (y0 (- y (* 0.8 h)))
         (refused (max 0.0 (- 1.0 (* 4.0 (- tm (aref *refused-t* side)))))))
    (flet ((slot-x (i) (let ((o (+ (* i (+ pw gap)) (* (floor i 2) pgap)))) (f32 (if right (- (+ x w) o pw) (+ x o))))))
    (when next                                          ; SP1's two hanks: a designed pair, or a cross pair
      (let* ((s (hank-slot next)) (a (if (>= (floor (gauges-reiatsu g) *reiatsu-bar*) (kit-command-cost kit :sp1)) 1.0 0.35))
             (top (f32 (- y0 (* 0.25 hh) 3))) (fh (f32 (+ (* 1.25 hh) 5))))
        (if (tachi-aligned-p next)
            (let ((x0 (min (slot-x s) (slot-x (1+ s)))))
              (%houtline (f32 (- x0 3)) top (f32 (+ pw pw gap 6)) fh 0.76f0 0.66f0 0.4f0 (f32 a)))
            (dolist (i (list s (mod (1+ s) 6)))
              (%houtline (f32 (- (slot-x i) 2)) top (f32 (+ pw 4)) fh 0.55f0 0.55f0 0.6f0 (f32 (* 0.8 a)))))))
    (dotimes (i 6)
      (let* ((px (slot-x i)))
        (if (null next)
            (let* ((n (round (gauges-meter g))) (lit (< i n))
                   (flick (if (and lit (= i (1- n)) (<= (hari-falls-in n (gauges-meter-idle g)) 30))
                              (+ 0.35 (* 0.65 (%pulse (f32 tm) 8.0))) 1.0)))
              (%sj-needle px (f32 y0) (f32 pw) (f32 hh) lit (f32 flick)))
            (let* ((k (nth i *hank-order*)) (dye (hank-dye k)) (lit (= k next)) (lift (if lit (* 0.25 hh) 0.0))
                   (live (find k (senju-live-zones e) :key (lambda (z) (let ((hz (hazard z))) (if hz (sjh-hank (hazard-data hz)) 0)))))
                   (a (if (or lit live) 1.0 0.55)) (torn-age (- *match-tick* (sjs-torn st))))
              (%hrect px (f32 (- y0 lift)) (f32 pw) (f32 hh) (f32 (first dye)) (f32 (second dye)) (f32 (third dye)) (f32 a))
              (%houtline px (f32 (- y0 lift)) (f32 pw) (f32 hh) (if lit 0.76f0 0.3f0) (if lit 0.66f0 0.3f0) (if lit 0.4f0 0.34f0) 1f0)
              (when lit                                  ; the passes stored on it fill it in three steps (every segment)
                (let ((p (senju-stored e)))
                  (%hrect px (f32 (+ (- y0 lift) (* hh (- 1.0 (/ p 3.0))))) (f32 pw) (f32 (* hh (/ p 3.0)))
                          0.95f0 0.9f0 0.8f0 0.55f0))
                  (when (> refused 0.0)                  ; a refused release (nothing woven): the swatch washes white
                    (%hrect px (f32 (- y0 lift)) (f32 pw) (f32 hh) 1f0 1f0 1f0 (f32 (* 0.85 refused)))))
              (when live                                 ; the live zone's life, draining
                (let* ((hz (hazard live))
                       (fr (if hz (if (plusp (hazard-delay hz)) 1.0 (max 0.0 (- 1.0 (/ (hazard-age hz) (float (max 1 (hazard-life hz))))))) 0.0)))
                  (%hrect px (f32 (+ y0 hh 2)) (f32 (* pw fr)) (f32 (max 1.0 (* 0.3 h))) 0.95f0 0.9f0 0.85f0 (f32 (+ 0.6 (* 0.4 (%pulse (f32 tm) 2.0)))))))
              (when (and (= k (sjs-torn-hank st)) (<= 0 torn-age *torn-lock*))   ; torn: a BLOOD slash, the lock grey
                (%hq (+ px (* 0.8 pw)) y0 (+ px pw) y0 (+ px (* 0.2 pw)) (+ y0 hh) px (+ y0 hh) 0.82f0 0.06f0 0.11f0
                     (f32 (max 0.3 (- 1.0 (/ torn-age 30.0)))))
                (%hrect px (f32 (+ y0 hh 2)) (f32 (* pw (- 1.0 (/ torn-age (float *torn-lock*))))) (f32 (max 1.0 (* 0.3 h)))
                        0.5f0 0.51f0 0.55f0 0.9f0)))))))
    (when (> refused 0.0) (%houtline (f32 (- x 2)) (f32 (- y0 2)) (f32 (+ w 4)) (f32 (+ hh 4)) 1f0 1f0 1f0 (f32 refused)))
    (when lx                                          ; the label: the brush 針 / 機 and HARI / the next hank
      (let* ((em (* 8 ls)) (kanji (if next "機" "針")) (col (if next '(0.76 0.66 0.4 1.0) '(0.82 0.06 0.11 1.0))))
        (set-line (if right (- lx (* 0.5 em)) (+ lx (* 0.5 em))) (+ ly (* 3.5 ls)) em col)
        (setf (aref *bl* 7) (line-width kanji))
        (brush-line kanji)
        (hud-text (if next (hank next :short) "HARI") (if right (- lx em (* 2 ls)) (+ lx em (* 2 ls))) ly ls col
                  :align (if right :right :left))))))

(defun senju-ring (e ox oy d)
  "The one-hand thumb ring (her kit's :deck hook): six needle ticks lit by the stitches; in the Bankai, while L is held, three
pass ticks filling in the next hank's dye."
  (let* ((f (fighter e)) (next (form-hank (fighter-form f))) (r (* d 56.0)))
    (if (null next)
        (let ((n (hari e)))
          (dotimes (i 6)
            (let* ((a (+ (* -0.5 pi) (* i (/ pi 3.0)))) (x (+ ox (* r (cos a)))) (y (+ oy (* r (sin a)))) (lit (< i n)))
              (%hrect (f32 (- x (* 2 d))) (f32 (- y (* 2 d))) (f32 (* 4 d)) (f32 (* 4 d))
                      (if lit 0.82f0 0.3f0) (if lit 0.06f0 0.3f0) (if lit 0.11f0 0.32f0) (if lit 1f0 0.6f0)))))
        (when (and (eq (fighter-phase f) :hold) (fighter-move f) (getf (mv-params (fighter-move f)) :hank))
          (let ((p (min 3 (floor (fighter-hold f) *weave-pass*))) (dye (hank-dye next)))
            (dotimes (i 3)
              (let* ((a (+ (* -0.5 pi) (* (1- i) 0.5))) (x (+ ox (* r (cos a)))) (y (+ oy (* r (sin a)))) (lit (< i p)))
                (%hrect (f32 (- x (* 3 d))) (f32 (- y (* 3 d))) (f32 (* 6 d)) (f32 (* 6 d))
                        (f32 (if lit (first dye) 0.2)) (f32 (if lit (second dye) 0.2)) (f32 (if lit (third dye) 0.22)) 1f0))))))))

;;; ================================================================ debug: tests, knobs, the pacing log (debug.lisp dispatches)
(defun senju-acc-reset () (dolist (st (coerce *sj* 'list)) (setf (sjs-acc st) nil)))

(defun senju-acc-line ()
  "After a gate row: a \"duel senju\" line per side that played her (the pacing log, docs/DUEL_SENJUMARU.md §9)."
  (dolist (e (list *p1* *p2*))
    (when (and (entity-alive-p e) (eq (fighter-character (fighter e)) :senjumaru))
      (log-msg "duel senju ~a seed ~d awakened ~a ~{~(~a~) ~a~^ ~}" (side-name e) *match-seed* (gauges-awakened (gauges e))
               (sjs-acc (sj e))))))

(defun senju-force-cine (k)
  "FORCE-CINE 16-18: her Kikon, her Bankai's Kikon, the awakening, P1 Senjumaru 3 m from Kenpachi."
  (ensure-battle :senjumaru :kenpachi) (place *p1* *p2* (if (= k 2) 5.0 3.0))
  (force-form *p1* (if (= k 0) :base :tsuji3))
  (start-cine (nth k '(sj-kikon-cine sj-hata-cine sj-tsuji-cine)) *p1* *p2*))

(defun senju-probe-line (tag)
  (let ((g1 (gauges *p1*)) (g2 (gauges *p2*)))
    (log-msg "duel probe senju ~a t ~d p1 ~a ~a r~d stitches ~d cd ~d | p2 ~a r~d rs ~,1f fs ~,1f"
             tag *match-tick* (fighter-form (fighter *p1*)) (state-of *p1*) (gauges-reishi g1) (round (gauges-meter g1))
             (aref (fighter-cd (fighter *p1*)) 2) (state-of *p2*) (gauges-reishi g2) (gauges-reiatsu g2) (gauges-fs g2))))

(defun senju-test (k)
  "2450+k (human P1 Senjumaru, P2's CPU off unless noted): 0 the Shikai 2.2 m from Kenpachi (a script plays J / K / L); 1 six
stitches, L at 5 m on a 50-Reishi Kenpachi (the spikes: 1 Reishi left); 2 the soldier vs an active Kenpachi CPU; 3 the
umbrella vs Yamamoto's full Shiranui; 4 a 3-pass weave hit at hold f30 (torn: the form +1, L locked); 5-10 hank k-4 cast at
Kenpachi 6 m (the zone's life logged); 11 the combo cut after K1 on a live 褥; 12 zero Rukia in 刃金; 13 the awakened
Senjumaru vs a Yamamoto CPU (眼 reflecting); 14 P1 awakened 5 m from Kenpachi (a script weaves); 30 the siphon
probe (星 round her, Kenpachi inside at 2.2 m, both at 0 Reiatsu / 20 flash-step; 2479 then has him hit her); 31-34 the
awakened Senjumaru near the rim (the drapes' fade stills): the pair on a tangent at z +14.8 / -14.8, P1 at the rim with P2
3 m inward, and swapped."
  (flet ((setup (c2 form dist &key cpu)
           (ensure-battle :senjumaru c2 :cpu cpu)
           (when (brain *p1*) (setf (brain-off (brain *p1*)) t))
           (unless (eq (fighter-form (fighter *p1*)) form) (force-form *p1* form))
           (place *p1* *p2* dist)
           (setf (gauges-reiatsu (gauges *p1*)) *reiatsu-max*)))
    (case k
      (0 (setup :kenpachi :base 2.2))
      (1 (setup :kenpachi :base 5.0) (set-hari *p1* 6) (setf (gauges-reishi (gauges *p2*)) 50)
         (try-command *p1* (fighter *p1*) :sig))
      (2 (setup :kenpachi :base 6.0) (setf (brain-off (brain *p2*)) nil) (try-command *p1* (fighter *p1*) :sp1))
      (3 (setup :yamamoto :base 9.0) (force-cmd *p2* :sp1))
      (4 (setup :kenpachi :tsuji1 3.0))
      ((5 6 7 8 9 10) (setup :kenpachi (hank-form (- k 4)) 6.0))
      (11 (setup :kenpachi :tsuji4 2.2))
      (12 (setup :rukia :tsuji2 6.0) (force-form *p2* :zero))
      (13 (setup :yamamoto :tsuji1 8.0) (setf (brain-off (brain *p2*)) nil))
      (14 (setup :kenpachi :tsuji1 5.0))
      ((20 21 22 23 24 25)                              ; review stills: hank k-19 standing under him (3 passes, unfolded)
       (let ((n (- k 19))) (setup :kenpachi (hank-form n) 5.0)
         (let* ((q (pos-of *p2*)) (z (senju-zone *p1* n 3 1 (aref q 0) (aref q 2))) (st (sj *p1*)))
           (setf (sjs-live st) z (sjs-live-hank st) n))))
      (26 (setup :kenpachi :base 2.6) (set-hari *p1* 6))  ; the stitches on him (the threads, the pips)
      (27 (setup :yamamoto :base 6.0) (try-command *p1* (fighter *p1*) :sp2))   ; the umbrella
      (28 (setup :kenpachi :tsuji3 5.0) (try-command *p1* (fighter *p1*) :sig :sig))   ; a weave (held by nobody: 1 pass)
      (29 (force-cmd *p2* :q))                          ; P2's J1 now (the torn-weave probe: hold L, then 2479)
      ((31 32 33 34)                                    ; the drapes near the rim (stills): 31 / 32 the pair on a tangent
       (setup :kenpachi :tsuji1 3.0)                    ; at z +14.8 / -14.8; 33 P1 at the rim (14.9 m at 80 deg: a drape behind her), P2 3 m inward; 34 swapped
       (let ((p (pos-of *p1*)) (q (pos-of *p2*)))
         (case k
           (31 (setf (aref p 2) 14.8f0 (aref q 2) 14.8f0))
           (32 (setf (aref p 2) -14.8f0 (aref q 2) -14.8f0))
           ((33 34) (let ((c (f32 (cos (deg 80.0)))) (sn (f32 (sin (deg 80.0)))) (a (if (= k 33) 14.9f0 11.9f0)))   ; (a drape
                      (v3-set! p (* a c) 0f0 (* a sn)) (v3-set! q (* (- 26.8f0 a) c) 0f0 (* (- 26.8f0 a) sn))))))        ; hangs at 80 deg)
       (face-each-other *p1* *p2*) (setf *cam-cut* t))
      (30 (setup :kenpachi :tsuji6 2.2)                 ; the siphon probe: 星 round her, him inside, both gauges low;
       (let ((p (pos-of *p1*)) (st (sj *p1*)))          ; then 2479 (his J1 on her: her Reiatsu grows, his doesn't)
         (setf (sjs-live st) (senju-zone *p1* 6 3 1 (aref p 0) (aref p 2)) (sjs-live-hank st) 6))
       (dolist (e (list *p1* *p2*)) (setf (gauges-reiatsu (gauges e)) 0f0 (gauges-fs (gauges e)) 20f0))))
    (senju-probe-line (format nil "test ~d" k))))

(defun senju-knob (c)
  "90000+ (docs/DUEL_SENJUMARU.md, Knobs): the pacing and A/B knobs without a rebuild."
  (flet ((kits (forms fn) (dolist (f forms) (funcall fn (find-kit :senjumaru f))))
         (tsuji () '(:tsuji1 :tsuji2 :tsuji3 :tsuji4 :tsuji5 :tsuji6)))
    (cond ((<= 90000 c 90999) (setf (kit-mult (find-kit :senjumaru :base)) (/ (- c 90000) 100.0)))
          ((<= 91000 c 91999) (setf (kit-taken (find-kit :senjumaru :base)) (/ (- c 91000) 100.0)))
          ((<= 92000 c 92999) (kits (tsuji) (lambda (k) (setf (kit-mult k) (/ (- c 92000) 100.0)))))
          ((<= 93000 c 93999) (kits (tsuji) (lambda (k) (setf (kit-taken k) (/ (- c 93000) 100.0)))))
          ((<= 94000 c 94499) (setf *torn-lock* (- c 94000)))
          ((<= 94500 c 94999) (setf *weave-pass* (- c 94500)))
          ((<= 95000 c 95499) (setf *unfold* (- c 95000)))
          ((<= 95500 c 95999) (kits (tsuji) (lambda (k) (setf (kit-walk k) (/ (- c 95500) 100.0)))))
          ((<= 96000 c 96499) (setf *hank-life-mult* (/ (- c 96000) 100.0)))
          ((<= 96500 c 96999) (setf *hank-range* (/ (- c 96500) 10.0)))
          ((<= 97000 c 97009) (loop for n from 1 to 6
                                    do (setf (mv-cost (find-move (intern (format nil "SJ-TACHINAOSHI-~d" n) :keyword))) (- c 97000))))
          ((<= 97100 c 97199) (setf *mirror-k* (/ (- c 97100) 100.0)))
          ((<= 97300 c 97309) (kits (tsuji) (lambda (k) (setf (getf (getf (kit-ai k) :intents) :zone) (- c 97300)))))
          ((<= 97400 c 97499) (kits (tsuji) (lambda (k) (setf (getf (kit-ai k) :opp-rush-hold) (/ (- c 97400) 100.0)))))
          ((<= 97500 c 97599) (setf (getf (kit-ai (find-kit :senjumaru :base)) :block-string) (/ (- c 97500) 100.0)))
          ((<= 97600 c 97699) (setf (getf (kit-ai (find-kit :senjumaru :base)) :dash) (/ (- c 97600) 100.0)))
          ((<= 97700 c 97799) (setf *ai-senju-hari* (/ (- c 97700) 100.0)))
          ((<= 97800 c 97899) (setf *shinpei-life* (* 10 (- c 97800))))
          ((<= 97900 c 97999) (setf *kasa-base* (- c 97900)))
          ((<= 98000 c 98099) (setf *hari-dmg* (- c 98000)))
          ((<= 98100 c 98999) (setf *hari-idle* (- c 98100)))
          ((<= 99000 c 99099) (setf *hari-sew-block* (- c 99000)))
          ((<= 99200 c 99299) (setf (getf (getf (kit-ai (find-kit :senjumaru :base)) :awaken) :min-taken) (* 10 (- c 99200))))
          ((<= 99300 c 99399) (setf (kit-walk (find-kit :senjumaru :base)) (/ (- c 99300) 10.0)))
          ((<= 99400 c 99409) (kits (cons :base (tsuji)) (lambda (k) (setf (getf (kit-ai k) :sp-cancel-bars) (- c 99400)))))
          ((<= 99500 c 99600) (setf (third *sj-drape-fade*) (/ (- c 99500) 100.0))))   ; the drapes' fade floor (100: off)
    (log-msg "duel senju knob ~d" c)))

(defun senju-debug (c)
  "Her debug commands (debug.lisp *CHAR-DEBUG*): 2450+k SENJU-TEST k; 76000+f / 77000+f / 78000+f her cinematics' stills
(FORCE-CINE 16-18) held at frame f; 90000+ SENJU-KNOB."
  (cond ((< c 2500) (senju-test (- c 2450)))
        ((< c 79000) (cine-at (+ 16 (floor (- c 76000) 1000)) (mod c 1000)))
        (t (senju-knob c))))
(dolist (r '((2450 2489 senju-debug) (76000 78999 senju-debug) (90000 99999 senju-debug)))
  (pushnew r *char-debug* :test #'equal))

;;; ================================================================ cinematics (§5, §6; unskippable; every shot SHOT-ON its subject)
;;; She wears white: the black card and a white back-rim (Yamamoto's rule). Madder cloth and the gold loom; BLOOD only in the
;;; threads and the Konpaku flames.
(defcine sj-kikon-cine (a v :len 186 :hold 112)
  "仕立て直し SHITATE-NAOSHI (the Shikai's Kikon; §5.1, ch. 598-599): beat 0, NUICHI's strike held, threads pinning his feet;
the black card, her white silhouette, the six gold arms fanned into a halo round the crescent, the brush stamp, silence;
the tailoring: six hands blur round him, red threads zig-zag over his torso, his robe turns white; the knot: she bites the
thread off, a small courtly bow; a held push-in on him, silence; the bad habit: needles burst from inside the garment, the
Konpaku shatter; she threads the needle again."
  (at 0 (face-each-other a v 2.4)
      (cine-clip a :sj-kikon :blend 2) (cine-clip v :sh-bound :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :thread-zip))
  (during (0 12) (let ((q (pos-of v))) (senju-pin-cine (aref q 0) (aref q 2))))
  (at 12 (card :black a) (back-rim 58) (shot-on a 20 4.2 0.9 :look 1.25 :off 0.9) (lens 42) (silence 58)
      (caption "仕立て直し" :reading "SHITATE-NAOSHI" :sub "WARUI KUSE  KIKON" :side 0 :hanko t))
  (at 70 (card nil) (caption-exit) (shot-on v 35 3.2 1.3 :look 1.15) (lens 55) (play-sfx :thread-zip)
      (cine-clip v :sh-kikon-victim :blend 4))
  (at 80 (play-sfx :thread-zip)) (at 90 (play-sfx :thread-zip))
  (during (70 150) (multiple-value-bind (x y z) (actor-point v 1.15)
                     (vfx-sj-threads x y z (min 1.0 (/ (- cf 70) 28.0)))
                     (when (>= cf 92) (setf (model-tint (model v)) '(1.35 1.35 1.4)))))   ; the robe re-tailored white
  (at 100 (shot-on a 25 1.6 1.35 :look 1.45) (lens 70) (cine-clip a :sj-knot :blend 4) (face-beat a :shout 1.4))   ; the smile
  (at 128 (shot-on v 150 3.8 0.5 :look 1.4) (hold-both a v 22) (silence 22) (lens 70))
  (during (128 150) (shot-on v 150 (- 3.8 (* 0.8 u)) (+ 0.5 (* 0.1 u)) :look 1.4))
  (at 150 (impact-frame :negative 2)
      (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x (+ y 0.1) z 3))
      (play-sfx :needle-burst) (play-sfx :konpaku-shatter) (shake 0.25 0.35))
  (during (150 172) (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-sj-needle-burst x y z (/ (- cf 150) 22.0))))
  (at 152 (impact-frame :manga 12))
  (at 170 (setf (model-tint (model v)) nil (model-alpha (model v)) 0f0)
      (shot-on a 160 5.0 1.0 :look 1.2) (lens 48) (cine-clip a :sj-win :blend 6)))

(defun senju-pin-cine (x z)
  "The Kikon's beat 0: threads pinning his feet to the plaza."
  (dotimes (i 6)
    (let ((a (* i 1.047)))
      (sj-thread x 1.6 z (+ x (* 0.5 (cos a))) 0.02 (+ z (* 0.5 (sin a))) 0.9 0.006 (float i)))))

(defcine sj-hata-cine (a v :len 198 :hold 120)
  "卍解 死出六色浮文機 SHIDE NO ROKUSHIKI UKIMON NO HATA (the Bankai's Kikon; §5.2, ep. 26): beat 0, the carpet lane held; on
him: the carpet lifts and a bolt of the next hank's dye wraps him from the clogs to the neck; the black card, her silhouette
before the golden loom, the 卍解 stamp; low and wide behind her, the loom overhead, her arms raised to it, threads to him;
the cut: great gold shears close on the threads, the bolt cut off the loom with him inside; a manga page: the bolt rises to
hang among the patterned bolts, the Konpaku flames drift out and shatter; her, the arms lowered."
  (at 0 (face-each-other a v 3.5)
      (cine-clip a :sj-unravel :blend 2 :speed 0.5) (cine-clip v :sh-bound :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :cloth-unfurl))
  (during (0 40) (let ((p (pos-of a))) (vfx-sj-carpet (aref p 0) (aref p 2) (yaw-of a) (min 3.5 (* 0.3 cf)))))
  (at 12 (shot-on v 30 3.6 1.0 :look 1.0) (lens 52) (play-sfx :cloth-unfurl))
  (during (12 150) (let ((q (pos-of v)))
                     (vfx-sj-wrap (aref q 0) (aref q 2) (* 1.55 (min 1.0 (/ (- cf 12) 28.0))) (or (form-hank (fighter-form (fighter a))) 1))))
  (at 40 (card :black a) (back-rim 58) (shot-on a 20 4.4 0.9 :look 1.4 :off 0.9) (lens 42)
      (caption "卍解" :kanji2 "死出六色浮文機" :reading "BANKAI" :sub "SHIDE NO ROKUSHIKI UKIMON NO HATA  KIKON" :side 0 :hanko t))
  (during (40 98) (let ((p (pos-of a))) (sj-prop :sj-torii (- (aref p 0) (* 2.5 (fwd-x (yaw-of a)))) 0.0
                                                (- (aref p 2) (* 2.5 (fwd-z (yaw-of a)))) :yaw (yaw-of a) :alpha 0.9)))
  (at 98 (card nil) (caption-exit) (shot-on a 165 4.5 0.4 :look 2.4) (lens 72) (cine-clip a :sj-awaken :blend 6 :time 0.8)
      (play-sfx :awaken-rise :pitch 0.8))
  (during (98 150) (let* ((p (pos-of a)) (q (pos-of v)) (lx (- (aref p 0) (* 1.6 (fwd-x (yaw-of a))))) (lz (- (aref p 2) (* 1.6 (fwd-z (yaw-of a))))))
                     (sj-prop :sj-torii lx 0.0 lz :yaw (yaw-of a))
                     (dotimes (i 5) (sj-thread lx 3.9 lz (aref q 0) (+ 0.4 (* 0.25 i)) (aref q 2) 0.9 0.006 (float i)))))
  (at 126 (shot-pair a v (camera-side a) 5.5 1.8) (lens 55) (play-sfx :shears))
  (during (126 150) (let ((q (pos-of v))) (sj-prop :sj-shears (aref q 0) (+ 2.2 (* -0.3 u)) (aref q 2) :yaw (yaw-of a) :roll (* 0.4 (- 1 u)) :s 1.6)))
  (at 150 (impact-frame :negative 1) (impact-frame :manga 12)
      (multiple-value-bind (x y z) (actor-point v 1.1) (vfx-konpaku-shatter x (+ y 0.1) z 3))
      (play-sfx :konpaku-shatter) (shake 0.2 0.3))
  (during (150 172) (let ((q (pos-of v)))                 ; the bolt rolled up, rising to hang among the others
                      (setf (model-alpha (model v)) 0f0)
                      (sj-seg :sj-bolt-3 (aref q 0) (* 3.0 u) (aref q 2) (aref q 0) (+ 2.6 (* 3.0 u)) (aref q 2) 3.0)))
  (at 172 (shot-on a 25 3.6 1.1 :look 1.3) (lens 50) (cine-clip a :sj-loom-stance :blend 8)))

(defcine sj-tsuji-cine (a v :len 180 :hold 120)
  "娑闥迦羅骸刺絡辻 SHIGARAMI NO TSUJI (the awakening; §6): beat 0, the arms lowered, silence; close and low on her: three
candles float before her and go out one by one (the Blood Oath, hinted), the plaza darkening; low and wide from behind: a
golden torii rises behind his line, her six arms raised to it as if praying; the torii becomes a loom pouring out red
bolts, a red carpet rolls from her clogs, madder cloth drops over the plaza's rim; the black card, 卍解 / 娑闥迦羅骸刺絡辻;
back in the plaza, the dark red domain, the loom at the rim, him small."
  (at 0 (cine-clip a :sj-awaken :blend 3) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (hold-both a v 12) (impact-frame :negative 2) (silence 12))
  (at 12 (shot-on a 12 1.5 1.35 :look 1.35) (lens 70) (setf *aura-off* a))
  (during (12 46) (multiple-value-bind (x y z) (actor-point a 1.1)
                    (let ((yaw (yaw-of a)))
                      (dotimes (i 3)
                        (let ((s (* 0.22 (- i 1))))
                          (vfx-sj-candle (+ x (* 0.55 (fwd-x yaw)) (* s (fwd-z yaw))) (+ y (* 0.05 (abs (- i 1))))
                                         (- (+ z (* 0.55 (fwd-z yaw))) (* s (fwd-x yaw))) (< cf (+ 20 (* 10 i)))))))
                    (setf *grade-desat* (min 0.6 (* 0.2 (floor (- cf 10) 10))))))
  (at 20 (play-sfx :candle-out)) (at 30 (play-sfx :candle-out)) (at 40 (play-sfx :candle-out))
  (at 46 (shot-on a 170 5.5 0.5 :look 2.2) (lens 76 -6) (play-sfx :awaken-rise :pitch 0.7))
  (during (46 106) (let* ((q (pos-of v)) (p (pos-of a)) (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2)))
                          (l (max 0.01 (sqrt (+ (* dx dx) (* dz dz))))) (tx (+ (aref q 0) (* 4.0 (/ dx l)))) (tz (+ (aref q 2) (* 4.0 (/ dz l)))))
                     (sj-prop :sj-torii tx (* -4.6 (max 0.0 (- 1.0 (/ (- cf 46) 24.0)))) tz :yaw (yaw-of a))))
  (at 80 (shot-on a 30 5.0 1.2 :look 1.3) (lens 55) (play-sfx :cloth-unfurl) (play-sfx :awaken-boom))
  (during (80 180) (let ((p (pos-of a))) (vfx-sj-carpet (aref p 0) (aref p 2) (yaw-of a) (min 8.0 (* 0.4 (- cf 80))))))
  (at 106 (card :black a) (back-rim 56) (shot-on a 20 4.4 0.8 :look 1.2 :off 0.9) (lens 42)
      (caption "卍解" :kanji2 "娑闥迦羅骸刺絡辻" :reading "BANKAI" :sub "SHATATSU KARAGARA SHIGARAMI NO TSUJI" :side 0))
  (at 162 (card nil) (caption-exit) (setf *aura-off* nil *grade-desat* 0.0) (shot-on a -30 7.5 2.0 :look 1.1) (lens 50)
      (cine-clip a :sj-loom-stance :blend 8)))
