;;;; barro.lisp — LILLE BARRO II (roster index 6, kit :barro, display name "LILLE II"), docs/duel/DUEL_LILLE_V2.md: the
;;;; rebuilt Lille, a separate fighter built from a copy of lille.lisp (the old Lille stays as he is, index 5). The user's
;;;; rules (2026-10-09): 萬物貫通 THE X-AXIS on the lines (a block drains 40 of the guard gauge and lets 30 % through, the
;;;; line runs 31 m); the base form's L is the shooting stance whose L / SP1 / SP2 carry it and fill the 狙擊 gauge (3 pips,
;;;; +1 a hit), whose J / K spend a pip for a snap shot / TAISHA; the awakening JILLIEL in two modes: melee (:jilliel-kin)
;;;; and ranged (:jilliel, its L / SP1 / SP2 lay trace lines for flash step); J / K go back to melee; J touching him or any
;;;; K's first active frame materialises the traces near him (萬物貫通 hits); J3 -> L the backstep into ranged, K3 -> L the
;;;; recall (every trace taken back, a derivative string by their count); U in every awakened form the intangible stance
;;;; MUJITTAI (the user 2026-10-09: 「覺醒後的 U 還是保持開了就進入無敵的狀態」); melee SP1 / SP2 fire directly as the old KIN's
;;;; (the user 2026-10-09: 「近戰模式的 SP1／SP2 跟原版一樣會直接放出，只有遠程才會變成軌跡」); the owl's revival (P at <= 4
;;;; Konpaku) on the same two modes, the old owl's numbers (x1.1 / x1.1, R - 1, refunds 5 / 2, Kikon 4, Trompete's reflect
;;;; and seal kept on the owl's melee SP2).
;;;; Sim code shares nothing with lille.lisp (every function, knob, struct, move and hazard here is BR- / :BR-: a change to
;;;; either file never moves the other's gate rows). The art is shared by reference (the user: 「角色動畫可以將之前的版本進行
;;;; 重新組織」): his moves name Lille's clips, bodies (:lille :lille-jilliel :lille-jilliel-kin :lille-shin), weapon :diagramm,
;;;; his kits Lille's cinematics and draw hook (LILLE-DRAW: it reads only the form and the move's clip), his look-only hazards
;;;; Lille's LB-LOOK (their data an LBH, read by nothing in the sim). barro-art.lisp holds his own looks (the trace lines, the
;;;; stance's aim line, the 狙擊 pips) and, later, the clips Lille never had (*BR-STAND-INS*).
;;;; Plain CL above the hooks: the host rules test loads it.
(in-package :duel)

;;; ================================================================ knobs (DUEL_LILLE_V2 §3-§6)
;; 萬物貫通 THE X-AXIS (§3, decision V1)
(defparameter *br-x-guard* 40
  "萬物貫通: the guard gauge a blocked line drains (gauge 100, a usual block ~30; the 3rd blocked one breaks guard). New,
2026-10-09, the user's decision V1 「被擋扣 40、穿透 30%」 (the old Lille's *LB-X-GUARD* 30).")
(defparameter *br-x-chip* 0.30
  "萬物貫通: the fraction of a blocked line's damage that goes through (the chip rule: it never kills). New, 2026-10-09, the
user's decision V1 (the old 0.15).")
(defparameter *br-x-len* 31.0
  "萬物貫通 「射程距離無限」: a line's length, metres (the arena's diameter, radius 15, + 1; the old shot's). New, 2026-10-09,
the user (as metres).")

;; the base form (§4)
(defparameter *br-walk* 3.4 "Walk m/s, the base form (the old Lille's *WALK-LILLE*, copied 2026-10-09).")
(defparameter *br-run* 8.5 "Run m/s, the base form (copied 2026-10-09).")
(defparameter *br-mult* 1.3 "Damage dealt x, the base form (the old *LILLE-MULT* 1.3, copied 2026-10-09; [G] a gate knob).")
(defparameter *br-taken* 1.0 "Damage taken x, the base form (copied 2026-10-09).")
(defparameter *br-aim-track* 60.0 "Degrees / s he turns in the shooting stance (copied 2026-10-09).")
(defparameter *br-kamae-up* 6 "The stance's frame where it is up: its follow-ups fire from here (copied 2026-10-09).")
(defparameter *br-kamae-tap* 30 "Frames the stance holds past its f6 on a tap of L (copied 2026-10-09) ...")
(defparameter *br-kamae-max* 90 "... and at most while L is held; then R 14 (copied 2026-10-09).")
(defparameter *br-snipe-max* 3
  "The 狙擊 gauge's pips (BRS-SNIPE): 0-3; +1 when the stance's L / SP1 / SP2 hits (once a move, not on a block), -1 for
each J / K conversion. New, 2026-10-09, the user's decision V1 「3 格，命中 +1，轉換一次 -1」.")
(defparameter *br-shot-dmg* 50 "The stance's L 万物貫通: damage, flat (new 2026-10-09 [G]; the old quick shot 40).")
(defparameter *br-k-sanren-dmg* 30 "The stance's SP1: each of its three 萬物貫通 lines (new 2026-10-09 [G]).")
(defparameter *br-k-hiren-dmg* 50 "The stance's SP2: the shot after the 6 m back-slide (new 2026-10-09 [G]).")
(defparameter *br-snap-dmg* 40 "The stance's J at >= 1 pip, 速射 the snap shot (new 2026-10-09 [G]).")
(defparameter *br-taisha-dmg* 70 "The stance's K at >= 1 pip, 退射 TAISHA (new 2026-10-09 [G]; the old 60 on a 6 m line).")
(defparameter *br-sanren-dmg* 30 "SP1 outside the stance: each of three lines, 20 m, no 萬物貫通 (new 2026-10-09 [G]).")
(defparameter *br-hiren-dmg* 40 "SP2 outside the stance: the shot after the slide, 20 m, no 萬物貫通 (new 2026-10-09 [G]).")
(defparameter *br-plain-len* 20.0 "SP1 / SP2 outside the stance: their lines' length, metres (new 2026-10-09 [G]).")

;; JILLIEL (§5)
(defparameter *br-walk-en* 3.0 "Walk m/s, ranged (EN, afloat; the old *WALK-JILLIEL*, copied 2026-10-09).")
(defparameter *br-run-en* 8.0 "Run m/s, ranged (the old *RUN-JILLIEL*, copied 2026-10-09).")
(defparameter *br-walk-kin* 3.8 "Walk m/s, melee (KIN's legs; the old *WALK-KIN*, copied 2026-10-09).")
(defparameter *br-run-kin* 8.5 "Run m/s, melee (the old *RUN-KIN*, copied 2026-10-09).")
(defparameter *br-jilliel-mult* 1.0 "Damage dealt x, JILLIEL (copied 2026-10-09).")
(defparameter *br-jilliel-taken* 1.1 "Damage taken x, JILLIEL (copied 2026-10-09).")
(defparameter *br-gg-regen* 0.36
  "JILLIEL's (and the owl's) guard gauge refill x outside MUJITTAI (the stance never refills): the old *JILLIEL-GG-REGEN*,
copied 2026-10-09 with MUJITTAI (the user: 「覺醒後的 U 還是保持開了就進入無敵的狀態」).")
(defparameter *br-jilliel-lift* 0.5 "JILLIEL is drawn this many metres up (kit :lift; a look; copied 2026-10-09).")
(defparameter *br-owl-lift* 0.35 "The owl's ranged form is drawn this many metres up (a look; copied 2026-10-09).")
(defparameter *br-to-en-f* 12 "Melee L: the turn into ranged mode, frames (new 2026-10-09 [G]).")
(defparameter *br-backstep* 5.0 "J3 -> L 後撤: metres back over *BR-BACKSTEP-F* (new 2026-10-09 [G]) ...")
(defparameter *br-backstep-f* 14 "... frames (new 2026-10-09 [G]) ...")
(defparameter *br-backstep-iframes* 7 "... invulnerable on its frames 0-6, then ranged mode (new 2026-10-09 [G]).")
(defparameter *br-lay-l* 3.0
  "Ranged L: the flash step its one trace line costs; a lay is refused when the flash step is short of its price (new
2026-10-09, the user: 「留下軌跡會消耗閃步量表」, 3 a line).")
(defparameter *br-lay-sp1* 9.0 "Ranged SP1: three lines, 3 each (new 2026-10-09, the user's rule; [G] the price).")
(defparameter *br-lay-sp2* 9.0 "Ranged SP2: one thick line (new 2026-10-09 [G]).")
(defparameter *br-trace-max* 16 "Live traces at most; a 17th drops the oldest (the old *LB-TRACE-MAX*, copied 2026-10-09).")
(defparameter *br-trace-len* 31.0 "A trace's length, metres from 0.6 m ahead of where it was laid (*BR-X-LEN*; 2026-10-09).")
(defparameter *br-trace-r* 0.6 "A trace's radius, metres (copied 2026-10-09) ...")
(defparameter *br-trace-r-thick* 1.2 "... ranged SP2's thick one (copied 2026-10-09).")
(defparameter *br-sp1-fan* '((6 -6.0) (12 0.0) (18 6.0))
  "Ranged SP1's three lines: (move frame, yaw offset in degrees) each, a fan laid shot by shot (new 2026-10-09 [G]).")
(defparameter *br-near-deg* 10.0
  "Materialising: a trace is near when the opponent lies within its snap correction: the angle on the ground between the
trace's direction and the direction from its origin to him is at most this many degrees (and he is within its length);
the materialised line then turns by that angle onto him. One knob for the selection and the snap (the old *LB-SNAP-MAX*
10). The user 2026-10-09: 「「附近」指對手在軌跡線的 10° 補正範圍以內。」 (the design's 2.5 m point-to-segment rule before).")
(defparameter *br-mat-dmg* 30 "A materialised L / SP1 line's damage, before the form's x (new 2026-10-09 [G]; the old 30).")
(defparameter *br-mat-thick* 90 "A materialised SP2 thick line's damage, before the form's x (new 2026-10-09 [G]; the old 180).")
(defparameter *br-mat-stun* 26 "A materialised line (not SP2's) staggers this many frames in place (the old, 2026-10-09).")
(defparameter *br-refund* 4.0 "A materialised trace that hits gives this much flash step back (the old, 2026-10-09) ...")
(defparameter *br-refund-block* 2.0 "... a blocked one this much (the old, 2026-10-09).")
(defparameter *br-owl-refund* 5.0 "The owl's materialised trace that hits: flash step back (the old owl's, 2026-10-09) ...")
(defparameter *br-owl-refund-block* 2.0 "... blocked (the old owl's, 2026-10-09).")
(defparameter *br-recall-f* 8 "K3 -> L 回收: the recall's frames before its derivative string (new 2026-10-09 [G]).")
(defparameter *br-recall-tiers* '((0 0) (1 1) (2 1) (3 2) (4 2) (5 2))
  "The recall's tier by the traces counted (n tier); 6 and up: tier 3 (new 2026-10-09 [G]: 0 / 1-2 / 3-5 / 6+).")
(defparameter *br-rc0-dmg* 30 "Recall tier 0 空收 (n = 0): one 萬物貫通 line (new 2026-10-09 [G]; the gate's lever).")
(defparameter *br-rc1-dmg* 40 "Recall tier 1 二連 (n 1-2): each of two lines (new 2026-10-09 [G]).")
(defparameter *br-rc2-dmg* 35 "Recall tier 2 四連 (n 3-5): each of the first three lines ... (new 2026-10-09 [G])")
(defparameter *br-rc2-last* 45 "... and the launching fourth (new 2026-10-09 [G]).")
(defparameter *br-rc3-dmg* 30 "Recall tier 3 裁き (n >= 6): each of the first four lines ... (new 2026-10-09 [G])")
(defparameter *br-rc3-last* 90 "... and the fifth (new 2026-10-09 [G]).")
(defparameter *br-rc-stun* 28 "The recall strings' lines before the last stagger this many frames: the next line combos (new 2026-10-09 [G]).")
(defparameter *br-rc-track* 360.0 "Degrees / s he turns at the opponent through the recall strings (new 2026-10-09 [G]).")

;; MUJITTAI's and the old KIN SPs' (copied from lille.lisp under BR- names, 2026-10-09, the user's two changes)
(defparameter *br-misuji-from* 1.0 "Owl melee SP1 裁きの光明: the ground line starts this many metres ahead (copied 2026-10-09) ...")
(defparameter *br-misuji-to* 18.0 "... and runs to this many (copied 2026-10-09).")
(defparameter *br-misuji-speed* 40.0 "... erupting outward at this many m/s (copied 2026-10-09).")
(defparameter *br-misuji-life* 24 "Frames each point of the line burns (copied 2026-10-09).")
(defparameter *br-misuji-width* 0.6 "The line's width, metres (copied 2026-10-09).")
(defparameter *br-reflect-hoho* '(48 59) "Owl melee SP2 Trompete: reflected by a perfect Hoho started on these frames (copied 2026-10-09).")
(defparameter *br-reflect-guard* '(2 10) "... or a guard whose FIGHTER-GUARD-T at its f59 is in this range (copied 2026-10-09).")
(defparameter *br-reflect-k* 0.5 "The reflect: he takes this share of Trompete's damage x his form's (copied 2026-10-09) ...")
(defparameter *br-reflect-stun* 60 "... and staggers this many frames (copied 2026-10-09).")

;; the owl (§6)
(defparameter *br-owl-mult* 1.1 "Damage dealt x, the owl (the old *SHIN-MULT*, copied 2026-10-09).")
(defparameter *br-owl-taken* 1.1 "Damage taken x, the owl (the old *SHIN-TAKEN*, copied 2026-10-09).")
(defparameter *br-owl-adv* 1
  "The owl's J / K strings and lays recover this many frames sooner than JILLIEL's (+1 on hit and block; the old *SHIN-ADV*,
copied 2026-10-09; the moves carry the numbers).")

;;; ================================================================ rules (pure: host-tested)
(defun br-owl-form-p (form) "Is FORM one of the owl's (melee, ranged, their MUJITTAI)?"
  (and (member form '(:shin-kin :shin :shin-kin-mujittai :shin-mujittai)) t))
(defun br-awake-form-p (form) "Is FORM awakened (JILLIEL's or the owl's, either mode, MUJITTAI too)?"
  (and (member form '(:jilliel-kin :jilliel :jilliel-kin-mujittai :jilliel-mujittai
                      :shin-kin :shin :shin-kin-mujittai :shin-mujittai))
       t))
(defun br-jilliel-form-p (form) "Is FORM one of JILLIEL's four (the revival's sources)?"
  (and (member form '(:jilliel-kin :jilliel :jilliel-kin-mujittai :jilliel-mujittai)) t))
(defun br-ranged-form-p (form) "Is FORM a ranged mode (JILLIEL's or the owl's, not MUJITTAI)?" (and (member form '(:jilliel :shin)) t))
(defun br-melee-form-p (form) "Is FORM a melee mode (JILLIEL's or the owl's, not MUJITTAI)?" (and (member form '(:jilliel-kin :shin-kin)) t))
(defun br-ranged-of (form) "The ranged mode of FORM's pair (melee -> ranged; else FORM)."
  (case form (:jilliel-kin :jilliel) (:shin-kin :shin) (t form)))
(defun br-melee-of (form) "The melee mode of FORM's pair (ranged -> melee; else FORM)."
  (case form (:jilliel :jilliel-kin) (:shin :shin-kin) (t form)))

(defun br-x-hit-p (hw)
  "Does hit window HW carry 萬物貫通 (§3): an :x-axis line through guard (:uncatchable) with *BR-X-GUARD* / *BR-X-CHIP*?"
  (and (member :x-axis (hw-flags hw)) (member :uncatchable (hw-flags hw)) (member :ranged (hw-flags hw))
       (eql (hw-guard hw) *br-x-guard*) (hw-chip hw) (< (abs (- (hw-chip hw) *br-x-chip*)) 1e-6) t))

(defun br-snipe-after (n contact)
  "The 狙擊 gauge after one of the stance's L / SP1 / SP2 moves made CONTACT (:hit / :block / NIL) for the first time: +1 on a
hit, at most *BR-SNIPE-MAX*; a block or a whiff nothing (decision V1)."
  (if (eq contact :hit) (min *br-snipe-max* (1+ n)) n))
(defun br-snipe-spend (n)
  "One J / K conversion out of the stance at N pips: values the pips left and whether it converts (N >= 1); at 0 the
stance drops into J1 / K1 (「一般攻擊」)."
  (if (>= n 1) (values (1- n) t) (values n nil)))
(defun br-kamae-pick (cmd snipe)
  "The move the stance's follow-up CMD (:kamae-l -sp1 -sp2 -j -k) starts at SNIPE pips (§4): L the 万物貫通 shot, SP1 /
SP2 the stance's 萬物貫通 SPs, J / K the snap shot / TAISHA at >= 1 pip, else J1 / K1."
  (case cmd
    (:kamae-l :br-k-shot) (:kamae-sp1 :br-k-sanren) (:kamae-sp2 :br-k-hiren)
    (:kamae-j (if (>= snipe 1) :br-k-snap :br-j1))
    (:kamae-k (if (>= snipe 1) :br-k-taisha :br-k1))))
(defun br-kamae-hold-over-p (sf held)
  "Does the stance (move frame SF, L HELD) end its hold now: past its tap with L up, before the held maximum?"
  (and (<= (+ *br-kamae-up* *br-kamae-tap*) sf) (< sf (+ *br-kamae-up* *br-kamae-max*)) (not held)))

(defun br-lay-price (form command)
  "The flash step COMMAND lays traces for in FORM (§5.2): a ranged mode's L *BR-LAY-L*, SP1 *BR-LAY-SP1*, SP2 *BR-LAY-SP2*;
anything else 0 (melee SP1 / SP2 fire directly, the user 2026-10-09)."
  (if (br-ranged-form-p form)
      (case command (:sig *br-lay-l*) (:sp1 *br-lay-sp1*) (:sp2 *br-lay-sp2*) (t 0.0))
      0.0))
(defun br-lay-ok-p (form command fs) "May COMMAND start in FORM with FS flash step (BR-LAY-PRICE: refused when short)?"
  (>= fs (br-lay-price form command)))
(defun br-line-cost (src) "The flash step one trace line of SRC (:l :sp1 :sp2) costs when laid."
  (case src (:sp2 *br-lay-sp2*) (:sp1 (/ *br-lay-sp1* (length *br-sp1-fan*))) (t *br-lay-l*)))
(defun br-trace-lay (ids id)
  "The FIFO of live trace IDS (oldest first) after trace ID is laid: values the new list and the id dropped (the oldest,
when *BR-TRACE-MAX* were live) or NIL."
  (let ((drop (and (>= (length ids) *br-trace-max*) (reduce #'min ids))))
    (values (append (remove drop ids) (list id)) drop)))
(defun br-trace-angle (x z yaw ox oz)
  "The opponent at (OX OZ) seen from a trace laid at (X Z) along YAW: values the angle in degrees on the ground between the
trace's direction and the direction to him (0-180; 0 when he stands on its origin) and his distance from the origin."
  (let ((dx (- ox x)) (dz (- oz z)))
    (if (< (+ (* dx dx) (* dz dz)) 1e-4)
        (values 0.0 0.0)
        (values (abs (* (angle-wrap (- (dir-yaw dx dz) yaw)) 57.29578)) (sqrt (+ (* dx dx) (* dz dz)))))))
(defun br-near-p (angle dist)
  "Is a trace near the opponent (§5.3, the user 2026-10-09): he lies within its *BR-NEAR-DEG* snap correction (ANGLE) and
within its length (DIST <= *BR-TRACE-LEN*)?"
  (and (<= angle *br-near-deg*) (<= dist *br-trace-len*)))
(defun br-snap-yaw (yaw x z ox oz)
  "A trace laid at (X Z) along YAW, materialising with the opponent at (OX OZ): turned toward him by at most *BR-NEAR-DEG*."
  (let ((dx (- ox x)) (dz (- oz z)))
    (if (< (+ (* dx dx) (* dz dz)) 1e-4)
        yaw
        (f32 (angle-wrap (turn-toward yaw (dir-yaw dx dz) (deg *br-near-deg*)))))))
(defun br-trace-hitwin (src mult)
  "The hit a materialised trace of SRC deals (once): *BR-MAT-DMG* (SP2's *BR-MAT-THICK*) x MULT with 萬物貫通 (chip
*BR-X-CHIP*, drain *BR-X-GUARD*, :ranged :x-axis :uncatchable); a *BR-MAT-STUN* stagger in place, SP2's a knockback."
  (let ((sp2 (eq src :sp2)))
    (make-hitwin :dmg (round (* (if sp2 *br-mat-thick* *br-mat-dmg*) mult)) :react (if sp2 :knockback :stagger)
                 :kb (if sp2 2.0 0.0) :stun (if sp2 nil *br-mat-stun*) :hs (if sp2 *hitstop-heavy* *hitstop-light*)
                 :chip *br-x-chip* :guard *br-x-guard* :flags (list :ranged :x-axis :uncatchable))))
(defun br-refund (contact &optional owl)
  "The flash step a materialised trace's CONTACT gives back: a hit *BR-REFUND* (the owl's *BR-OWL-REFUND*), a block
*BR-REFUND-BLOCK* (*BR-OWL-REFUND-BLOCK*), else 0."
  (case contact
    (:hit (if owl *br-owl-refund* *br-refund*))
    (:block (if owl *br-owl-refund-block* *br-refund-block*))
    (t 0.0)))
(defun br-recall-tier (n) "The recall's tier (0-3) for N traces taken back (*BR-RECALL-TIERS*: 0 / 1-2 / 3-5 / 6+)."
  (or (second (assoc n *br-recall-tiers*)) 3))
(defun br-recall-move (tier) "The derivative string's move for TIER." (svref #(:br-rc0 :br-rc1 :br-rc2 :br-rc3) tier))
(defun br-recall-damage (tier)
  "The damages of TIER's lines in order, before the form's x (the host test's view of the moves' windows)."
  (case tier
    (0 (list *br-rc0-dmg*)) (1 (list *br-rc1-dmg* *br-rc1-dmg*))
    (2 (list *br-rc2-dmg* *br-rc2-dmg* *br-rc2-dmg* *br-rc2-last*))
    (t (list *br-rc3-dmg* *br-rc3-dmg* *br-rc3-dmg* *br-rc3-dmg* *br-rc3-last*))))
(defun br-l-link-ok-p (l-name cur-name cur-kind cur-ender)
  "May the L link L-NAME start off the running move (CUR-NAME, CUR-KIND, CUR-ENDER its :ender flag): the recall only off a
K3 (a :flash ender), the backstep only off a J3 (a :quick ender); the stance after any K link (the old rule); anything else
yes (§5.1: 「K 連段的結尾接入 L」, 「J 連段的結尾接入 L」)."
  (declare (ignore cur-name))
  (case l-name
    (:br-recall (and cur-ender (eq cur-kind :flash)))
    (:br-backstep (and cur-ender (eq cur-kind :quick)))
    (t t)))
(defun br-l-route (cur-kind cur-ender)
  "The move L pressed in a melee string link starts (the kit's :l-after-k / :l-after-j name the router :BR-L-LINK): off K3
(a :flash ender, CUR-ENDER) the recall, off J3 (a :quick ender) the backstep, off J1 / J2 / K1 / K2 the plain L, the mode
turn into ranged, as a cancel in the window the enders' links use (batch 4, 2026-10-09: the press was refused and eaten)."
  (cond ((and cur-ender (eq cur-kind :flash)) :br-recall)
        ((and cur-ender (eq cur-kind :quick)) :br-backstep)
        (t :br-to-en)))
(defun br-revive-ok-p (form free konpaku)
  "May P revive him into the owl (§6): any JILLIEL FORM (melee, ranged, MUJITTAI), FREE as for the first awakening, at most
*BANKAI-KONPAKU* Konpaku."
  (and (br-jilliel-form-p form) free (<= konpaku *bankai-konpaku*) t))
(defun br-sp2-sealed-p (command form sealed)
  "Is COMMAND refused in FORM because Trompete was reflected (SEALED): the owl's SP2 in every owl form (the old rule)."
  (and (eq command :sp2) (br-owl-form-p form) sealed t))
(defun br-reflect-hoho-p (start) "A perfect Hoho started on Trompete frame START reflects it (*BR-REFLECT-HOHO*)?"
  (<= (first *br-reflect-hoho*) start (second *br-reflect-hoho*)))
(defun br-reflect-guard-p (guard-t) "A guard at FIGHTER-GUARD-T = GUARD-T on Trompete's f59 reflects it (*BR-REFLECT-GUARD*)?"
  (<= (first *br-reflect-guard*) guard-t (second *br-reflect-guard*)))
(defun br-misuji-span (age)
  "The burning part of a 裁きの光明 ground line AGE frames after it erupted: values from to (metres ahead)."
  (let* ((front (min *br-misuji-to* (+ *br-misuji-from* (* *br-misuji-speed* (/ age 60.0)))))
         (tail (max *br-misuji-from* (+ *br-misuji-from* (* *br-misuji-speed* (/ (- age *br-misuji-life*) 60.0))))))
    (values (min tail front) front)))
(defun br-misuji-frames () "A 裁きの光明 line's life." (+ (ceiling (* 60 (- *br-misuji-to* *br-misuji-from*)) *br-misuji-speed*) *br-misuji-life*))
(defun br-ai-kamae-plan (r d reeling snipe sp-ok)
  "His CPU's follow-up in the stance, picked once at its f6 from one roll R (§8): a REELING opponent the shot (it combos);
>= 1 pip and inside 4 m TAISHA (its back-slide) or the snap shot, half each; with the bars (SP-OK) a quarter of the time
the stance's SP2 (inside 5 m) or SP1; else the shot."
  (cond (reeling :kamae-l)
        ((and (>= snipe 1) (< d 4.0)) (if (< r 0.5) :kamae-k :kamae-j))
        ((and sp-ok (< r 0.25)) (if (< d 5.0) :kamae-sp2 :kamae-sp1))
        (t :kamae-l)))

;;; ================================================================ base 万物貫通 (§4)
;; the J / K strings: the old Lille's frames and clips, literal numbers (DUEL_STRINGS §2.1's budget)
(defmove :br-j1 :kind :quick :clip :lb-q1 :startup 8 :active 3 :recovery 12 :dmg 26 :adv-block -2
  :reach 1.45 :arc 100 :on-hit :flinch)
(defmove :br-j2 :kind :quick :clip :lb-q2 :startup 7 :active 3 :recovery 13 :dmg 22 :adv-block -2
  :reach 1.45 :arc 110 :on-hit :flinch)
(defmove :br-j3 :kind :quick :clip :lb-jab :startup 9 :active 3 :recovery 18 :dmg 28 :adv-block -4
  :reach 1.6 :arc 70 :on-hit :stagger :flags (:ender))
(defmove :br-k1 :kind :flash :clip :lb-f1 :startup 17 :active 4 :recovery 21 :dmg 48 :adv-block -3
  :reach 2.05 :arc 150 :on-hit :stagger)
(defmove :br-k2 :kind :flash :clip :lb-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 48 :adv-block -3
  :reach 2.05 :arc 100 :on-hit :stagger)
(defmove :br-k3 :kind :flash :clip :lb-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 70 :adv-block -20
  :reach 2.15 :arc 60 :on-hit :crumple :flags (:ender))
(defmove-copy :br-j2s :br-j2)
(defmove-copy :br-k2s :br-k2)
;; L 狙擊架式: up at f6, held 30 f (90 while L is held), R 14; turning 60 deg/s; from f6 the first L / SP1 / SP2 / J / K
;; picks the follow-up (BR-KAMAE-TICK through the non-button :strings). L after a K link opens it at f4
(defmove :br-kamae :kind :sig :clip :lb-kamae :startup 6 :active 0 :recovery 104 :track 60.0 :tick br-kamae-tick
  :on-frame ((0 br-kamae-enter)))
(defmove-copy :br-kamae-k :br-kamae :enter 4 :on-frame ((4 br-kamae-enter)))
;; stance -> L 万物貫通: locked on the press, fired 10 f later; 50 flat, 萬物貫通; a hit fills a pip
(defmove :br-k-shot :kind :sig :clip :lb-k-shot :callout "X-AXIS" :startup 10 :active 2 :recovery 26 :dmg *br-shot-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :on-frame ((0 br-k-lock) (10 br-shot-fire)) :params (:lock 0 :snipe t :len *br-x-len*))
;; stance -> SP1: three 萬物貫通 lines (f12 / f22 / f32), turning 90 deg/s between them
(defmove :br-k-sanren :kind :sp :clip :lb-sanren :callout "SANREN" :startup 12 :active 22 :recovery 24 :dmg *br-k-sanren-dmg*
  :adv-block -14 :track 90 :vol (:cap 0.6 *br-x-len* 1.2 0.25) :on-hit :flinch :kb 0.5 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :hits ((12 14) (22 24) (32 34)) :tick br-sanren-tick
  :on-frame ((12 br-line-shot) (22 br-line-shot) (32 br-line-shot)) :params (:len *br-x-len* :snipe t))
;; stance -> SP2: the 6 m back-slide (no iframes), then one 萬物貫通 shot at f20
(defmove :br-k-hiren :kind :sp :clip :lb-hiren :callout "HIRENKYAKU" :startup 20 :active 2 :recovery 22 :dmg *br-k-hiren-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick br-slide-tick :on-frame ((0 br-slide) (20 br-shot-fire))
  :params (:slide 6.0 :slide-f 14 :lock 14 :snipe t :len *br-x-len*))
;; stance -> J at >= 1 pip: 速射 the snap shot from the hip (Lille's unused :lb-snap), 40, 萬物貫通, a pip spent
(defmove :br-k-snap :kind :sig :clip :lb-snap :callout "SOKUSHA" :startup 6 :active 2 :recovery 20 :dmg *br-snap-dmg*
  :adv-block -12 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.25) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :on-frame ((6 br-shot-fire)) :params (:lock 0 :len *br-x-len*))
;; stance -> K at >= 1 pip: 退射 TAISHA, a 3 m back-slide, then one 萬物貫通 shot of 70, a pip spent
(defmove :br-k-taisha :kind :sig :clip :lb-k-taisha :callout "TAISHA" :startup 16 :active 2 :recovery 24 :dmg *br-taisha-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick br-slide-tick :on-frame ((0 br-slide) (16 br-shot-fire))
  :params (:slide 3.0 :slide-f 12 :lock 12 :len *br-x-len*))
;; SP1 / SP2 outside the stance: no 萬物貫通 (the kind's chip and drain), 20 m lines, no pip
(defmove :br-sanren :kind :sp :clip :lb-sanren :callout "SANREN" :startup 12 :active 22 :recovery 24 :dmg *br-sanren-dmg*
  :adv-block -14 :track 90 :vol (:cap 0.6 *br-plain-len* 1.2 0.25) :on-hit :flinch :kb 0.5 :flags (:ranged)
  :hits ((12 14) (22 24) (32 34)) :tick br-sanren-tick
  :on-frame ((12 br-line-shot) (22 br-line-shot) (32 br-line-shot)) :params (:len *br-plain-len*))
(defmove :br-hiren :kind :sp :clip :lb-hiren :callout "HIRENKYAKU" :startup 20 :active 2 :recovery 22 :dmg *br-hiren-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-plain-len* 1.2 0.25) :on-hit :stagger :kb 1.0 :flags (:ranged)
  :tick br-slide-tick :on-frame ((0 br-slide) (20 br-shot-fire)) :params (:slide 6.0 :slide-f 14 :lock 14 :len *br-plain-len*))
(defmove :br-breaker :kind :breaker :clip :lb-breaker :clip-2 :lb-butt :callout "SHOBI-UCHI")
(defmove :br-kikon :kind :kikon :clip :lb-aim :clip-2 :lb-fire :clip-s 4 :callout "BANBUTSU KANTSU" :cine lb-kikon-cine
  :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0 :vol (:cap 0.5 12.0 1.2 1.2)
  :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 br-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))

;;; ================================================================ JILLIEL (§5)
;; melee: the wing blades. A J that touches him (hit or block) materialises the near traces (BARRO-HIT, :params :mat);
;; every K materialises them at its first active frame, hit or whiff (BR-K-MAT). Each starts by putting him in melee
;; (BR-MELEE-IN: J / K pressed in ranged mode or its MUJITTAI, 「切回近戰並發動攻擊」)
(defmove :br-w-j1 :kind :quick :clip :lb-w-q1 :startup 8 :active 3 :recovery 12 :dmg 24 :adv-block -2
  :reach 1.6 :arc 110 :on-hit :flinch :on-frame ((0 br-melee-in)) :params (:mat t))
(defmove :br-w-j2 :kind :quick :clip :lb-w-q2 :startup 7 :active 3 :recovery 13 :dmg 24 :adv-block -2
  :reach 1.6 :arc 110 :on-hit :flinch :params (:mat t))
(defmove :br-w-j3 :kind :quick :clip :lb-w-q3 :startup 9 :active 3 :recovery 18 :dmg 30 :adv-block -4
  :reach 1.7 :arc 120 :on-hit :stagger :flags (:ender) :params (:mat t))
(defmove :br-w-k1 :kind :flash :clip :lb-w-f1 :startup 17 :active 4 :recovery 21 :dmg 50 :adv-block -3
  :reach 2.2 :arc 150 :on-hit :stagger :on-frame ((0 br-melee-in) (17 br-k-mat)))
(defmove :br-w-k2 :kind :flash :clip :lb-w-f2 :enter 6 :startup 20 :active 4 :recovery 24 :dmg 50 :adv-block -3
  :reach 2.2 :arc 110 :on-hit :stagger :on-frame ((20 br-k-mat)))
(defmove :br-w-k3 :kind :flash :clip :lb-w-f3 :enter 7 :startup 21 :active 5 :recovery 34 :dmg 72 :adv-block -20
  :reach 2.3 :arc 90 :on-hit :crumple :flags (:ender) :on-frame ((21 br-k-mat)))
(defmove-copy :br-w-j2s :br-w-j2)
(defmove-copy :br-w-k2s :br-w-k2)
;; melee SP1 / SP2: the old KIN's, fired directly (the user 2026-10-09: 「近戰模式的 SP1／SP2 跟原版一樣會直接放出」): SANREN
;; on his wings (3 lines 20 m, 30 each, chip 15 %, guard 12) and NIJUSHI-KO (the 40 f tell, a 1.2 m beam, 180)
(defmove :br-w-sanren :kind :sp :clip :lb-w-sanren :clip-s 12 :callout "SANREN" :startup 12 :active 22 :recovery 24 :dmg 30
  :adv-block -14 :track 90 :vol (:cap 0.6 20.0 1.2 0.25) :on-hit :flinch :kb 0.5 :chip 0.15 :guard 12
  :flags (:ranged :x-axis :uncatchable) :hits ((12 14) (22 24) (32 34)) :tick br-sanren-tick
  :on-frame ((12 br-line-shot) (22 br-line-shot) (32 br-line-shot)) :params (:len 20.0))
(defmove :br-w-nijushi :kind :sp :clip :lb-w-nijushi :callout "NIJUSHI-KO" :startup 40 :active 6 :recovery 30 :dmg 180
  :adv-block -14 :track 0 :vol (:cap 0.6 31.0 1.2 1.2) :on-hit :knockback :kb 2.0 :chip 0.15 :guard 45
  :flags (:ranged :x-axis :uncatchable) :tick br-planted-tick :on-frame ((0 br-nijushi-tell) (40 br-beam-shot))
  :params (:lock 20 :track 60.0 :width 1.2))
;; melee L: the turn into ranged mode (12 f); J3 -> L 後撤 the backstep (5 m / 14 f, iframes f0-6) into ranged; K3 -> L
;; 回收 the recall (every live trace taken back, counted, then the derivative string for the count: :strings :rc0 .. :rc3)
(defmove :br-to-en :kind :sig :clip :lb-w-fold :callout "EN" :startup *br-to-en-f* :active 0 :recovery 0 :tick br-halt-tick
  :on-frame ((11 br-go-ranged)))
;; L latched in a melee J / K link (the kits' :l-after-k / :l-after-j): a router that lives no frame: its f0 starts the
;; move BARRO-OK routed off the link it was pressed in (BR-L-ROUTE: K3 the recall, J3 the backstep, else :br-to-en; batch 4)
(defmove :br-l-link :kind :sig :clip :lb-w-fold :startup 1 :active 0 :recovery 0 :on-frame ((0 br-l-link-go)))
(defmove :br-backstep :kind :sig :clip :lb-w-tenshin :callout "KOTAI" :startup *br-backstep-f* :active 0 :recovery 8
  :tick br-halt-tick :on-frame ((0 br-backstep-go) (13 br-go-ranged)))
(defmove :br-recall :kind :sig :clip :lb-w-fold :callout "KAISHU" :startup *br-recall-f* :active 0 :recovery 0
  :tick br-halt-tick :on-frame ((0 br-recall-go) (7 br-recall-fire)))
;; the recall's derivative strings (§5.4): every line 萬物貫通 from him at the opponent (BR-RC-TICK keeps him on him)
(defmove :br-rc0 :kind :sig :clip :lb-w-q3 :callout "KAISHU" :startup 6 :active 2 :recovery 24 :dmg *br-rc0-dmg* :adv-block -14
  :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 1.0 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :tick br-rc-tick :on-frame ((6 br-rc-shot)) :params (:lock 0 :len *br-x-len*))
(defmove :br-rc1 :kind :sig :clip :lb-w-sanren :clip-s 12 :callout "NIREN" :startup 6 :active 12 :recovery 24 :dmg *br-rc1-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 0.5 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable) :hits ((6 8 :stun *br-rc-stun*) (16 18)) :tick br-rc-tick
  :on-frame ((6 br-rc-shot) (16 br-rc-shot)) :params (:lock 0 :len *br-x-len*))
(defmove :br-rc2 :kind :sig :clip :lb-e-sanren :clip-s 6 :callout "YONREN" :startup 6 :active 28 :recovery 24 :dmg *br-rc2-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 0.3 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable)
  :hits ((6 8 :stun *br-rc-stun*) (14 16 :stun *br-rc-stun*) (22 24 :stun *br-rc-stun*) (32 34 :dmg *br-rc2-last* :on-hit :launch))
  :tick br-rc-tick :on-frame ((6 br-rc-shot) (14 br-rc-shot) (22 br-rc-shot) (32 br-rc-shot)) :params (:lock 0 :len *br-x-len*))
(defmove :br-rc3 :kind :sig :clip :lb-w-nijushi :clip-s 6 :callout "SABAKI" :startup 6 :active 32 :recovery 26 :dmg *br-rc3-dmg*
  :adv-block -14 :track 0 :vol (:cap 0.6 *br-x-len* 1.2 0.3) :on-hit :stagger :kb 0.3 :chip *br-x-chip* :guard *br-x-guard*
  :flags (:ranged :x-axis :uncatchable)
  :hits ((6 8 :stun *br-rc-stun*) (12 14 :stun *br-rc-stun*) (18 20 :stun *br-rc-stun*) (24 26 :stun *br-rc-stun*)
         (36 38 :dmg *br-rc3-last* :on-hit :knockback :kb 2.0))
  :tick br-rc-tick :on-frame ((6 br-rc-shot) (12 br-rc-shot) (18 br-rc-shot) (24 br-rc-shot) (36 br-beam-shot))
  :params (:lock 0 :len *br-x-len* :width 1.2))
(defmove :br-w-breaker :kind :breaker :clip :lb-w-breaker :clip-2 :lb-w-ram :callout "JILLIEL")
(defmove :br-w-kikon :kind :kikon :clip :lb-w-kikon :clip-2 :lb-w-kikon-fire :callout "KAMI NO SABAKI"
  :cine lb-jilliel-kikon-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.2 1.2) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 br-lane-shot))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))
;; ranged: L lays one trace (3), SP1 three in a fan (9), SP2 one thick (9); laying deals nothing; refused when short
(defmove :br-e-lay :kind :sig :clip :lb-e-q1 :startup 4 :active 3 :recovery 6 :on-frame ((4 br-lay)) :params (:trace :l))
(defmove :br-e-sanren :kind :sp :clip :lb-e-sanren :callout "SANREN" :startup 6 :active 14 :recovery 12
  :on-frame ((6 br-lay) (12 br-lay) (18 br-lay)) :params (:trace :sp1))
(defmove :br-e-nijushi :kind :sp :clip :lb-w-nijushi :clip-s 40 :callout "NIJUSHI-KO" :startup 20 :active 6 :recovery 15
  :track 0 :tick br-planted-tick :on-frame ((0 br-nijushi-tell) (20 br-lay)) :params (:lock 10 :track 60.0 :trace :sp2))

;;; ================================================================ the owl (§6): the old owl's numbers (R - 1, adv + 1)
(defmove :br-o-j1 :kind :quick :clip :lb-o-q1 :startup 8 :active 3 :recovery 11 :dmg 26 :adv-block -1
  :reach 1.7 :arc 110 :on-hit :flinch :on-frame ((0 br-melee-in)) :params (:mat t))
(defmove :br-o-j2 :kind :quick :clip :lb-o-q2 :startup 7 :active 3 :recovery 12 :dmg 26 :adv-block -1
  :reach 1.7 :arc 110 :on-hit :flinch :params (:mat t))
(defmove :br-o-j3 :kind :quick :clip :lb-o-q3 :startup 9 :active 3 :recovery 17 :dmg 32 :adv-block -3
  :reach 1.7 :arc 120 :on-hit :stagger :flags (:ender) :params (:mat t))
(defmove :br-o-k1 :kind :flash :clip :lb-o-f1 :startup 17 :active 4 :recovery 20 :dmg 54 :adv-block -2
  :reach 2.3 :arc 150 :on-hit :stagger :on-frame ((0 br-melee-in) (17 br-k-mat)))
(defmove :br-o-k2 :kind :flash :clip :lb-o-f2 :enter 6 :startup 20 :active 4 :recovery 23 :dmg 54 :adv-block -2
  :reach 2.3 :arc 110 :on-hit :stagger :on-frame ((20 br-k-mat)))
(defmove :br-o-k3 :kind :flash :clip :lb-o-f3 :enter 7 :startup 21 :active 5 :recovery 33 :dmg 78 :adv-block -19
  :reach 2.3 :arc 90 :on-hit :crumple :flags (:ender) :on-frame ((21 br-k-mat)))
(defmove-copy :br-o-j2s :br-o-j2)
(defmove-copy :br-o-k2s :br-o-k2)
;; owl melee SP1 裁きの光明 (the old MISUJI: three SABAKI ground lines at -20 / 0 / +20 deg, one hit group, 70 each, 18 m)
(defmove :br-misuji :kind :sp :clip :lb-o-chop :clip-s 16 :callout "SABAKI NO KOMYO" :startup 18 :active 0 :recovery 25
  :reach 18.0 :track 90 :on-frame ((18 br-misuji)) :params (:dmg 70 :guard 18 :fan (-20.0 0.0 20.0)))
;; owl melee SP2 神の喇叭 TROMPETE (the old: 60 f wind-up, a 2.4 m-wide beam 30 f, 240; reflected by a perfect Hoho f48-f59
;; or a guard f50-f58: he takes half, staggers, SP2 sealed in both owl modes for the match)
(defmove :br-trompete :kind :sp :clip :lb-o-trompete :callout "TROMPETE" :startup 60 :active 30 :recovery 39 :dmg 240
  :adv-block -13 :track 0 :vol (:cap 0.6 31.0 1.4 1.2) :on-hit :knockback :kb 3.0 :chip 0.15 :guard 60
  :flags (:ranged :x-axis :uncatchable :reflectable) :tick br-planted-tick :on-frame ((0 br-trompete-tell) (60 br-beam-shot))
  :params (:lock 40 :blast 60 :track 30.0 :width 1.2))
(defmove :br-o-breaker :kind :breaker :clip :lb-o-breaker :clip-2 :lb-o-stamp :callout "KAGIZUME")
(defmove :br-o-kikon :kind :kikon :clip :lb-o-trompete :clip-2 :lb-o-chop :clip-s 4 :callout "TROMPETE"
  :cine lb-trompete-cine :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 80 :adv-block -14 :track 0
  :vol (:cap 0.5 12.0 1.4 1.4) :on-hit :knockback :kb 2.0 :cooldown 90 :on-frame ((20 br-lane-shot))
  :params (:aura 10 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane :follow-speed 14.0 :len 12.0))
;; owl ranged: the old owl EN's casts with R - 1, laying as JILLIEL ranged's
(defmove :br-oe-lay :kind :sig :clip :lb-oe-q1 :startup 4 :active 3 :recovery 5 :on-frame ((4 br-lay)) :params (:trace :l))
(defmove :br-oe-sabaki :kind :sp :clip :lb-oe-sabaki :callout "SABAKI NO KOMYO" :startup 6 :active 14 :recovery 11
  :on-frame ((6 br-lay) (12 br-lay) (18 br-lay)) :params (:trace :sp1))
(defmove :br-oe-trompete :kind :sp :clip :lb-o-trompete :clip-s 60 :callout "TROMPETE" :startup 12 :active 6 :recovery 8
  :track 0 :tick br-planted-tick :on-frame ((0 br-trompete-tell) (12 br-lay)) :params (:lock 6 :track 100.0 :trace :sp2))

;;; The stand-in clips (the art batch swaps these for barro-art.lisp's new clips, DUEL_LILLE_V2 §7): move -> (the clip it
;;; plays now in JILLIEL, the owl's through its kits' :clip-map, the new clip to come)
(defparameter *br-stand-ins*
  '((:br-recall :lb-w-fold :lb-o-fold :br-recall) (:br-rc0 :lb-w-q3 :lb-o-q3 :br-recall)
    (:br-rc1 :lb-w-sanren :lb-o-f2 :br-rc1) (:br-rc2 :lb-e-sanren :lb-o-f3 :br-rc2) (:br-rc3 :lb-w-nijushi :lb-o-chop :br-rc3)
    (:br-to-en :lb-w-fold :lb-o-fold :br-to-en) (:br-backstep :lb-w-tenshin :lb-o-tenshin nil))
  "The moves Lille never had, on his clips for now (batch 1, 2026-10-09).")
(defparameter *br-owl-clip-map* '(:lb-w-fold :lb-o-fold :lb-w-q3 :lb-o-q3 :lb-w-sanren :lb-o-f2 :lb-e-sanren :lb-o-f3
                                  :lb-w-nijushi :lb-o-chop :lb-w-tenshin :lb-o-tenshin)
  "The owl kits' :clip-map: the shared moves (the recall, its strings, the mode turns) on the claws (*BR-STAND-INS*).")

;;; ================================================================ forms
(defparameter *barro-hooks* '(:tick barro-tick :ok barro-ok :hit barro-hit :struck barro-struck :draw br-draw)
  "His mechanics (kit.lisp KIT-HOOK): the trace count, MUJITTAI's perfect-Hoho drop, Trompete's reflect, the revival's
clearing (:tick); the lay prices, the L links, the seal (:ok); the 狙擊 gauge, the J's materialise, the refunds (:hit); the
pacing log (:struck); his looks (:draw, barro-art.lisp).")

(defparameter *br-kamae-strings*
  (append (loop for s in '(:br-kamae :br-kamae-k)
                append `((,s :kamae-l :br-k-shot) (,s :kamae-sp1 :br-k-sanren) (,s :kamae-sp2 :br-k-hiren)
                         (,s :kamae-j :br-k-snap) (,s :kamae-k :br-k-taisha))))
  "The shooting stance's follow-ups: non-button strings (KIT-NEXT) its :tick starts (BR-KAMAE-TICK).")
(defparameter *br-recall-strings*
  '((:br-recall :rc0 :br-rc0) (:br-recall :rc1 :br-rc1) (:br-recall :rc2 :br-rc2) (:br-recall :rc3 :br-rc3))
  "The recall's derivative strings: non-button strings its f7 starts (BR-RECALL-FIRE).")
(defparameter *br-melee-strings*
  (append *br-recall-strings*
          '((:br-l-link :br-recall :br-recall) (:br-l-link :br-backstep :br-backstep) (:br-l-link :br-to-en :br-to-en)))
  "The melee forms' non-button strings: the recall's, and the L router's three targets (BR-L-LINK-GO; batch 4).")

(defkit :barro :base
  :name "LILLE II" :body :lille :weapon :diagramm :stance :lb-stance :calm t
  :intro :lb-intro :win :lb-win :intro-callout "THE X-AXIS"
  :walk *br-walk* :run *br-run* :reishi *reishi-max* :swing-sfx :whoosh-light :mult *br-mult* :taken *br-taken*
  :commands (:q :br-j1 :f :br-k1 :sig :br-kamae :sp1 :br-sanren :sp2 :br-hiren :breaker :br-breaker :kikon :br-kikon)
  :grid (:br-j1 :br-j2 :br-j3 :br-k1 :br-k2 :br-k3 :br-j2s :br-k2s)
  :strings *br-kamae-strings*
  :l-after-k :br-kamae-k                        ; L after K1 / K2 / K3: the stance at f4 (the old rule)
  :awaken-form :jilliel-kin :kikon-konpaku 2 :hooks *barro-hooks*
  :ai (:intents (:approach 1 :pressure 1 :zone 5 :defend 2)
       :ranges (:approach (2.2 8.0) :pressure (1.3 2.2) :zone (8.0 20.0) :defend (5.0 9.0))
       :moves ((0.0 2.2 :q 4 :f 2 :breaker 1 :step 2 :sig 1)
               (2.2 6.0 :sp2 1 :step 2 :sp1 1 :sig 3 nil 1)
               (6.0 99.0 :sig 6 :sp1 1 nil 1))
       :guard 0.5 :hoho 0.3 :dash 0.3 :dash-back 0.7 :block-string 0.3 :o-ender 0.3 :l-after-k 0.6 :kikon-range 7.7
       :awaken (:min-taken 150)
       :zone (:p 0.5 :near 6.0) :pip (:p 0.6 :near 4.0) :reflex br-ai-reflex))   ; (his CPU: batch 4, §13)

;; JILLIEL melee (the awakening enters it [G]): the wing strings, SP1 / SP2 the old KIN's, L to ranged, J3 -> L the
;; backstep, K3 -> L the recall, U MUJITTAI, P the revival
(defkit :barro :jilliel-kin :inherit :base
  :lift *br-jilliel-lift* :awakening t :form-name "JILLIEL KIN" :walk *br-walk-kin* :run *br-run-kin*
  :mult *br-jilliel-mult* :taken *br-jilliel-taken* :kikon-konpaku 3 :guard-to :jilliel-kin-mujittai :gg-regen *br-gg-regen*
  :bankai-form :shin :bankai-ok barro-bankai-ok :endless-form :jilliel-kin
  :body :lille-jilliel-kin :weapon nil :stance :lb-w-stance :cine lb-jilliel-cine :u-tag "U: MUJITTAI" :swing-sfx :whoosh-heavy
  :commands (:q :br-w-j1 :f :br-w-k1 :sig :br-to-en :sp1 :br-w-sanren :sp2 :br-w-nijushi :breaker :br-w-breaker
             :kikon :br-w-kikon)
  :grid (:br-w-j1 :br-w-j2 :br-w-j3 :br-w-k1 :br-w-k2 :br-w-k3 :br-w-j2s :br-w-k2s)
  :strings *br-melee-strings*
  :l-after-k :br-l-link :l-after-j :br-l-link     ; (the router: K3 the recall, J3 the backstep, else the mode turn: BR-L-ROUTE)
  :ai (:intents (:approach 3 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.4 6.0) :pressure (1.4 2.4) :zone (3.0 6.0) :defend (3.0 6.0))
       :moves ((0.0 2.4 :q 4 :f 4 :breaker 1)
               (2.4 8.0 :sig 2 :step 1 :sp1 1 nil 1)
               (8.0 99.0 :sig 4 :step 1 nil 1))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.8 :block-string 0.3 :o-ender 0.3 :kikon-range 8.5
       :string-k 0.6 :recall (:p 0.6 :n 3 :low-n 1 :low 0.35) :backstep (:p 0.5 :fs 9.0) :fire (:p 0.6 :n 4 :busy-n 1)
       :stance (:p 0.4 :max 120 :gg 30) :bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1)
       :sp-ender br-ai-sp-ender :opp-trace (:p 0.5) :opp-reflex br-opp-trace :reflex br-ai-reflex))

;; U in every awakened form: 無実体 MUJITTAI (the old Lille's, the user 2026-10-09): West's ward with :intangible; every
;; command drops it (no :keep)
(defkit :barro :jilliel-kin-mujittai :inherit :jilliel-kin
  :guard-to nil :drop-to :jilliel-kin :passives (:ward :intangible) :stance :lb-w-fold :u-tag "U: MUJITTAI")

;; JILLIEL ranged (EN, afloat): L / SP1 / SP2 lay traces, J / K back to melee (their moves are melee's, BR-MELEE-IN)
(defkit :barro :jilliel :inherit :jilliel-kin
  :form-name "JILLIEL" :walk *br-walk-en* :run *br-run-en* :guard-to :jilliel-mujittai :body :lille-jilliel
  :commands (:sig :br-e-lay :sp1 :br-e-sanren :sp2 :br-e-nijushi)
  :ai (:intents (:approach 1 :pressure 0 :zone 5 :defend 2)
       :ranges (:approach (6.0 12.0) :pressure (6.0 9.0) :zone (6.0 12.0) :defend (8.0 12.0))
       :moves ((0.0 3.0 :q 2 :f 2 :step 1)
               (3.0 14.0 :sig 4 :sp1 1 :sp2 1 :f 1 nil 1)
               (14.0 99.0 :sig 2 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.4 :dash-back 0.6 :kikon-range 8.5
       :fire (:p 0.6 :n 4 :in 4.0 :busy-n 1) :lay (:far 4.0 :reserve 15.0 :every 12 :sp1 0.3)
       :stance (:p 0.4 :max 120 :gg 30) :bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1)
       :opp-trace (:p 0.5) :opp-reflex br-opp-trace :reflex br-ai-reflex))

(defkit :barro :jilliel-mujittai :inherit :jilliel
  :guard-to nil :drop-to :jilliel :passives (:ward :intangible) :stance :lb-w-fold :u-tag "U: MUJITTAI")

;; the owl (P at <= 4 Konpaku in any JILLIEL form, Kenpachi's Bankai path: Konpaku -> 1, Reishi full, the traces cleared;
;; the revival enters its ranged mode, as the old): melee the claws, SP1 裁きの光明, SP2 Trompete (reflect and seal); ranged
;; the old owl EN's casts laying traces. x1.1 dealt, x1.1 taken, R - 1, refunds 5 / 2, Kikon 4, no revival from here
(defkit :barro :shin-kin :inherit :jilliel-kin
  :lift 0.0 :form-name "SHIN KIN" :mult *br-owl-mult* :taken *br-owl-taken* :kikon-konpaku 4
  :guard-to :shin-kin-mujittai :bankai-form nil :bankai-ok nil :body :lille-shin :stance :lb-o-stance :cine lb-revive-cine
  :clip-map *br-owl-clip-map*
  :commands (:q :br-o-j1 :f :br-o-k1 :sp1 :br-misuji :sp2 :br-trompete :breaker :br-o-breaker :kikon :br-o-kikon)
  :grid (:br-o-j1 :br-o-j2 :br-o-j3 :br-o-k1 :br-o-k2 :br-o-k3 :br-o-j2s :br-o-k2s)
  :ai (:intents (:approach 3 :pressure 4 :zone 0 :defend 1)
       :ranges (:approach (2.6 6.0) :pressure (1.4 2.6) :zone (3.0 6.0) :defend (3.0 6.0))
       :moves ((0.0 2.6 :q 4 :f 4 :breaker 1)
               (2.6 8.0 :step 1 :sp1 1 nil 1)
               (8.0 99.0 :sp2 2 :sig 1 :step 1 nil 1))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.8 :block-string 0.3 :o-ender 0.3 :kikon-range 9.0
       :string-k 0.6 :recall (:p 0.6 :n 3 :low-n 1 :low 0.35) :backstep (:p 0.5 :fs 9.0) :fire (:p 0.6 :n 4 :busy-n 1)
       :stance (:p 0.4 :max 120 :gg 30) :opp-reflect (:p 0.3)
       :sp-ender br-ai-sp-ender :opp-trace (:p 0.5) :opp-reflex br-opp-trace :reflex br-ai-reflex))

(defkit :barro :shin-kin-mujittai :inherit :shin-kin
  :guard-to nil :drop-to :shin-kin :passives (:ward :intangible) :stance :lb-o-fold :u-tag "U: MUJITTAI")

(defkit :barro :shin :inherit :shin-kin
  :lift *br-owl-lift* :form-name "SHIN" :walk *br-walk-en* :run *br-run-en* :guard-to :shin-mujittai :stance :lb-oe-stance
  :commands (:sig :br-oe-lay :sp1 :br-oe-sabaki :sp2 :br-oe-trompete)
  :ai (:intents (:approach 1 :pressure 0 :zone 5 :defend 2)
       :ranges (:approach (6.0 12.0) :pressure (6.0 9.0) :zone (6.0 12.0) :defend (8.0 12.0))
       :moves ((0.0 3.0 :q 2 :f 2 :step 1)
               (3.0 14.0 :sig 4 :sp1 1 :sp2 1 :f 1 nil 1)
               (14.0 99.0 :sig 2 :step 1 nil 2))
       :guard 0.4 :neutral-guard 0.0 :hoho 0.3 :dash 0.4 :dash-back 0.6 :kikon-range 9.0
       :fire (:p 0.6 :n 4 :in 4.0 :busy-n 1) :lay (:far 4.0 :reserve 15.0 :every 12 :sp1 0.3)
       :stance (:p 0.4 :max 120 :gg 30) :opp-trace (:p 0.5) :opp-reflex br-opp-trace :reflex br-ai-reflex))

(defkit :barro :shin-mujittai :inherit :shin
  :guard-to nil :drop-to :shin :passives (:ward :intangible) :stance :lb-oe-fold :u-tag "U: MUJITTAI")

(defparameter *br-forms* '(:base :jilliel-kin :jilliel-kin-mujittai :jilliel :jilliel-mujittai :shin-kin :shin-kin-mujittai
                           :shin :shin-mujittai)
  "Every form of his (the HUD meter, the host tests).")

;; his names in the brush tables (brush.lisp): the intro's column and the technique columns (not on the host); only the
;; names whose glyphs Lille's already brought (the new moves show their plain callout)
(when (boundp '*brush-names*)
  (setf *brush-names* (append (remove :barro *brush-names* :key #'first) '((:barro "リジェ・バロ" "LILLE II")))
        *brush-callouts*
        (append (remove-if (lambda (c) (member (first c) '(:br-k-shot :br-k-sanren :br-k-hiren :br-k-taisha :br-sanren :br-hiren
                                                            :br-e-sanren :br-e-nijushi :br-w-sanren :br-w-nijushi :br-misuji
                                                            :br-trompete :br-oe-sabaki :br-oe-trompete)))
                           *brush-callouts*)
                '((:br-k-shot "万物貫通" "THE X-AXIS" nil) (:br-k-sanren "三連" "SANREN" nil) (:br-k-hiren "飛廉脚" "HIRENKYAKU" nil)
                  (:br-k-taisha "退射" "TAISHA" nil) (:br-sanren "三連" "SANREN" nil) (:br-hiren "飛廉脚" "HIRENKYAKU" nil)
                  (:br-e-sanren "三連" "SANREN" nil) (:br-e-nijushi "二十四孔" "NIJUSHI-KO" nil)
                  (:br-w-sanren "三連" "SANREN" nil) (:br-w-nijushi "二十四孔" "NIJUSHI-KO" nil)
                  (:br-misuji "裁きの光明" "SABAKI NO KOMYO" nil) (:br-trompete "神の喇叭" "TROMPETE" nil)
                  (:br-oe-sabaki "裁きの光明" "SABAKI NO KOMYO" nil) (:br-oe-trompete "神の喇叭" "TROMPETE" nil)))))

;;; ================================================================ his state (the sim's): a component on his fighter entity
(defcomponent brs
  "Lille II's state: on his fighter entity, made on its first use, so a new match's fighter starts fresh."
  (snipe 0 :type fixnum)                  ; the 狙擊 gauge, 0-3
  (armed nil)                             ; the running stance L / SP1 / SP2 may still fill a pip (once a move)
  (k-plan nil)                            ; his CPU's stance follow-up (picked once at its f6)
  (l-to :br-to-en)                        ; the melee L router's target (BARRO-OK, BR-L-ROUTE), started at its f0
  (opp-roll 0 :type fixnum)               ; a CPU facing him: the newest trace id it rolled for (BR-OPP-TRACE)
  (trace-n 0 :type fixnum)                ; the traces laid (their ids count up)
  (live 0 :type fixnum)                   ; live traces now (counted each step: the HUD, his CPU)
  (recall-n 0 :type fixnum)               ; the recall's count (its f0) for its string (its f7)
  (stance 0 :type fixnum)                 ; frames of the current MUJITTAI
  (sealed nil)                            ; the owl's Trompete was reflected: SP2 sealed for the match
  (awake-t -1 :type fixnum) (revive-t -1 :type fixnum))   ; ticks of the awakening and the revival (the pacing log)
(defvar *br-reflect-test* nil "Debug 82007 / 82008: P2 reflects P1's Trompete by a guard (:guard) / a perfect Hoho (:hoho).")
(defun br (e)
  "E's Lille II state (his BRS component, attached on the first call: a new fighter entity, a new match, gets a fresh one)."
  (or (brs e) (let ((st (make-brs))) (add-component e st) st)))

;;; hazard data: his traces carry one of these and BR-HZ as their hook (his look-only hazards carry Lille's LBH, LB-LOOK)
(defstruct (brh (:conc-name brh-))
  (src nil)                               ; what laid it: :l :sp1 :sp2 (its damage, its width)
  (id 0 :type fixnum)                     ; they count up per side (the oldest drops first)
  (live t)                                ; laid, not yet materialised
  (width 0f0 :type single-float)          ; its radius (0.6, SP2's 1.2)
  (vol nil))                              ; its line: a :cap volume in its own frame

;;; ================================================================ hooks
(defun br-tick-brain (e)
  "The brain his ticks decide on (the stance's follow-up): his own CPU's; NIL for a human (no brain, or one switched off) and
for the ASSIST gate's button-masher (habit :dumb, read as a human)."
  (let ((b (brain e))) (and b (not (brain-off b)) (not (eq (brain-habit b) :dumb)) b)))

(defun barro-ok (e command combo)
  "His kit's refusals: a lay short of its flash step (BR-LAY-OK-P: ranged L 3, SP1 9, SP2 9); the melee L router (an L
latched in a J / K link) routed off the link it was pressed in (BR-L-ROUTE, kept in BRS-L-TO for its f0), his CPU's only
when it pays (BR-AI-L-OK-P: the recall at its count, the backstep with no trace and the flash step for lines); the owl's
SP2 once sealed."
  (let* ((f (fighter e)) (form (fighter-form f)) (g (gauges e)) (b (br-tick-brain e))
         (cur (and (eq (fighter-state f) :move) (fighter-move f))))
    (cond ((br-sp2-sealed-p command form (brs-sealed (br e))) nil)
          ((and (eq command :sig) (typep combo 'move))
           (let ((l (mv-name combo)))
             (and cur
                  (if (eq l :br-l-link)
                      (let ((to (br-l-route (mv-kind cur) (and (member :ender (mv-flags cur)) t))))
                        (setf (brs-l-to (br e)) to)
                        (or (null b) (br-ai-l-ok-p e to)))
                      (br-l-link-ok-p l (mv-name cur) (mv-kind cur) (member :ender (mv-flags cur))))
                  t)))
          (t (br-lay-ok-p (or (kit-drop-to (fighter-kit f)) form) command (gauges-fs g))))))   ; (MUJITTAI: its mode's price)

(defun barro-bankai-ok (e)
  "His kit's :bankai-ok: P revives him into the owl from any JILLIEL form where the first awakening could be taken, with <=
*BANKAI-KONPAKU* Konpaku (BR-REVIVE-OK-P)."
  (let ((f (fighter e))) (br-revive-ok-p (fighter-form f) (awaken-state-p e f) (gauges-konpaku (gauges e)))))

(defun barro-tick (e f g)
  "Per step (his kit's :tick): his live traces counted; the awakening's and the revival's clocks (the revival clears every
trace); MUJITTAI's own perfect-Hoho drop (his counter strike is an attack: solid) and its frame count; Trompete's reflect
check on its f59."
  (declare (ignore g))
  (let ((st (br e)) (form (fighter-form f)))
    (setf (brs-live st) (br-live-traces e))
    (when (and (br-awake-form-p form) (minusp (brs-awake-t st)))
      (setf (brs-awake-t st) *match-tick*) (pace e :awaken-tick *match-tick*))
    (when (and (br-owl-form-p form) (minusp (brs-revive-t st)))
      (setf (brs-revive-t st) *match-tick*) (pace e :revive-tick *match-tick*)
      (br-clear-traces e)
      (setf (brs-live st) 0))
    (cond ((member :intangible (kit-passives (fighter-kit f)))
           (when (and (eq (fighter-state f) :hoho) (fighter-perfect f))
             (set-form e (kit-drop-to (fighter-kit f)))
             (clog "~a MUJITTAI dropped: the perfect Hoho's counter" (side-name e)))
           (incf (brs-stance st))
           (pace e :stance-frames))
          (t (setf (brs-stance st) 0)))
    (let ((mv (fighter-move f)))
      (when (and (eq (fighter-state f) :move) mv (eq (mv-name mv) :br-trompete) (eq (fighter-phase f) :main))
        (when *br-reflect-test* (br-reflect-test-step e f))
        (when (= (fighter-sf f) 59) (br-reflect-check e st mv))))))

(defun barro-hit (att def res hw mv hazard ranged)
  "After a hit he dealt (his kit's :hit): the stance's L / SP1 / SP2 fill a pip on their first hit (BR-SNIPE-AFTER); an
awakened J touching him (hit or block) materialises the traces near him; a materialised trace's flash step back
(BR-REFUND); the pacing log."
  (declare (ignore def ranged))
  (let ((st (br att)) (c (contact-of res)))
    (when (and mv (not hazard) (getf (mv-params mv) :snipe) (brs-armed st) (eq c :hit))   ; (a block fills nothing and
      (setf (brs-armed st) nil)                                                           ;  leaves the move armed)
      (let ((n (br-snipe-after (brs-snipe st) c)))
        (when (> n (brs-snipe st)) (pace att :snipe-fill))
        (setf (brs-snipe st) n)))
    (when (and mv (not hazard) (getf (mv-params mv) :mat) (member c '(:hit :block)))
      (br-materialise-near att))
    (when (and hazard (brh-p (hazard-data hazard)))
      (let* ((owl (br-owl-form-p (fighter-form (fighter att)))) (fs (br-refund c owl)))
        (when (plusp fs) (pay-gauges (or (siphon-of att) att) 0.0 fs) (pace att :trace-refund)))
      (pace att (if (eq c :hit) :trace-hit :trace-guarded)))
    (when (and hw (br-x-hit-p hw))
      (pace att (if (eq c :hit) :x-hit :x-guarded)))))

(defun barro-struck (def att res hw mv hazard ranged)
  "After a hit he took (his kit's :struck): MUJITTAI's pacing (passes)."
  (declare (ignore att hw mv hazard ranged))
  (when (and (member :intangible (kit-passives (kit-of def))) (eq res :blocked)) (pace def :passes)))

;;; ---------------------------------------------------------------- the shooting stance (§4)
(defun br-kamae-enter (e)
  "A fresh stance (L from neutral at f0, or after a K link at f4): no CPU plan yet."
  (setf (brs-k-plan (br e)) nil)
  (pace e :kamae))

(defun br-kamae-pressed (vp)
  "The stance's follow-up a human pressed (buffered): :kamae-sp2 / -sp1 (Shift+L / Shift+K) / -j / -k / -l, or NIL."
  (cond ((vpad-command-pressed-p vp :sig t) :kamae-sp2) ((vpad-command-pressed-p vp :flash t) :kamae-sp1)
        ((vpad-command-pressed-p vp :quick nil) :kamae-j) ((vpad-command-pressed-p vp :flash nil) :kamae-k)
        ((vpad-command-pressed-p vp :sig nil) :kamae-l)))

(defun br-kamae-go (e f st mv cmd)
  "Start the stance's follow-up CMD from stance move MV: L / SP1 / SP2 armed to fill a pip (SP1 / SP2 under their command's
bars, TRY-COMMAND's WITH); J / K a pip's conversion (the snap shot / TAISHA), at 0 the plain J1 / K1. T when it started."
  (let* ((kit (fighter-kit f)) (snipe (brs-snipe st)) (name (br-kamae-pick cmd snipe)))
    (case cmd
      (:kamae-l (start-move e (kit-next kit (mv-name mv) cmd)) (setf (brs-armed st) t) (pace e :k-shot) t)
      ((:kamae-sp1 :kamae-sp2)
       (when (try-command e f (if (eq cmd :kamae-sp1) :sp1 :sp2) nil nil (kit-next kit (mv-name mv) cmd))
         (setf (brs-armed st) t) (pace e (if (eq cmd :kamae-sp1) :k-sanren :k-hiren)) t))
      ((:kamae-j :kamae-k)
       (multiple-value-bind (left ok) (br-snipe-spend snipe)
         (if ok
             (progn (setf (brs-snipe st) left) (start-move e (kit-next kit (mv-name mv) cmd))
                    (pace e (if (eq cmd :kamae-j) :snap :taisha)))
             (progn (start-move e (kit-move kit name)) (pace e :kamae-drop)))
         t)))))

(defun br-kamae-tick (e)
  "One step of the stance: it turns at *BR-AIM-TRACK*; from f6 the first L / SP1 / SP2 / J / K fires its follow-up (his
CPU's: BR-AI-KAMAE's plan); past the hold (30 f, 90 while L is held) the stance recovers (R 14)."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (when (and (eq (fighter-state f) :move) mv (member (mv-name mv) '(:br-kamae :br-kamae-k)))
      (let* ((st (br e)) (sf (fighter-sf f)) (vp (pilot-vpad (pilot e))) (b (br-tick-brain e)))
        (turn-to-opp e f (track-step *br-aim-track*))
        (when (>= sf *br-kamae-up*)
          (let ((cmd (if b (br-ai-kamae e f st b) (br-kamae-pressed vp))))
            (when cmd
              (let ((button (getf '(:kamae-j :quick :kamae-k :flash :kamae-l :sig :kamae-sp1 :flash :kamae-sp2 :sig) cmd)))
                (if (br-kamae-go e f st mv cmd)
                    (progn (unless b (vpad-consume! vp button)) (return-from br-kamae-tick nil))
                    (if b (setf (brs-k-plan st) :kamae-l) (vpad-consume! vp button)))))))
        (when (br-kamae-hold-over-p sf (vpad-down vp :sig))
          (setf (fighter-sf f) (+ *br-kamae-up* *br-kamae-max*)))))))

(defun br-ai-kamae (e f st b)
  "His CPU's follow-up in the stance (BR-KAMAE-TICK, from f6): the plan picked once, on the first step it is up (one roll,
BR-AI-KAMAE-PLAN), then carried out."
  (unless (brs-k-plan st)
    (let* ((o (opp-of e)) (fo (fighter o)))
      (setf (brs-k-plan st)
            (br-ai-kamae-plan (sim-rnd01) (fighter-dist f) (and (member (fighter-state fo) '(:stun :air)) t) (brs-snipe st)
                              (>= (gauges-reiatsu (gauges e)) (* (kit-command-cost (fighter-kit f) :sp1) *reiatsu-bar*))))
      (setf (brs-k-plan st) (br-learn-kamae e b (brs-k-plan st)))   ; (a learner's read of the shot, §13)
      (pace e (intern (format nil "AI-~a" (brs-k-plan st)) :keyword))
      (why b :kamae (brs-k-plan st))))
  (brs-k-plan st))

(defun br-k-lock (e)
  "The stance's L, f0: locked on the press: the jade lane along it (the 10 f before it fires)."
  (br-spawn-look e :lane *br-x-len* 0.5 t)
  (emit :sfx :lb-lock e))

(defun br-shot-fire (e)
  "A shot's fire frame (the stance's L, SP2, the snap shot, TAISHA, SP2 outside the stance): the line's look (jade with
萬物貫通), the crack."
  (let ((mv (fighter-move (fighter e))))
    (br-spawn-look e :shot (move-param e :len) 0.05 (and (member :x-axis (mv-flags mv)) t))
    (emit :sfx :lb-crack e)))

(defun br-line-shot (e)
  "SANREN's shots (f12, f22, f32): the line's look."
  (br-spawn-look e :shot (move-param e :len) 0.04 (and (member :uncatchable (mv-flags (fighter-move (fighter e)))) t))
  (emit :sfx :rift-cut e))

(defun br-lane-shot (e)
  "A Kikon module's lane: its look (the hit is the move's lane)."
  (br-spawn-look e :lane (move-param e :len) 0.5 t)
  (emit :sfx :kikon-slash e))

(defun br-beam-shot (e)
  "NIJUSHI-KO's / Trompete's / the recall's last line: the beam's look."
  (br-spawn-look e :beam 31.0 (or (move-param e :width) 1.2) t)
  (emit :sfx :explode e))

(defun br-sanren-tick (e)
  "SANREN: he turns 90 deg/s between the shots."
  (let* ((f (fighter e)) (sf (fighter-sf f)))
    (when (and (eq (fighter-phase f) :main) (< 14 sf 32) (not (<= 22 sf 24)))
      (turn-to-opp e f (track-step 90.0)))))

(defun br-slide (e)
  "The stance's SP2 / TAISHA / SP2 f0: the back-slide, the move's :slide metres over :slide-f frames (no iframes)."
  (let* ((p (pos-of e)) (f (fighter e)))
    (set-slide e (move-param e :slide) (move-param e :slide-f) (- (aref p 0) (fighter-ox f)) (- (aref p 2) (fighter-oz f)))
    (emit :sfx :hoho-out e)))

(defun br-slide-tick (e)
  "The back-slides: he keeps turning to the opponent while he slides, then the line is fixed (from :lock)."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (move-param e :lock))) (turn-to-opp e f (track-step 90.0)))))

(defun br-planted-tick (e)
  "A planted wind-up (NIJUSHI-KO, Trompete, their lays): turning at the move's :track until its :lock frame, then locked."
  (let ((f (fighter e)))
    (when (and (eq (fighter-phase f) :main) (< (fighter-sf f) (move-param e :lock)))
      (turn-to-opp e f (track-step (move-param e :track))))))

(defun br-nijushi-tell (e) "NIJUSHI-KO f0: the 24 holes glow (the tell)." (setf (model-super (model e)) 0.6) (emit :sfx :awaken-rise e))
(defun br-trompete-tell (e) "Trompete f0: the rising pitch (the tell)." (setf (model-super (model e)) 1.0) (emit :sfx :lb-trumpet e))

(defun br-spawn-look (e kind len width lock)
  "A look-only hazard of his along his facing: a shot, a beam or a lane (Lille's LB-LOOK draws it; no hit)."
  (let ((p (pos-of e))) (br-spawn-look-at e kind (aref p 0) (aref p 2) (yaw-of e) len width lock)))
(defun br-spawn-look-at (e kind x z yaw len width lock)
  "BR-SPAWN-LOOK from (X Z) along YAW (a materialised trace's flash; the owl's :judge, LOCK :thick for SP2's wide one)."
  (spawn-hazard :br-fx e :x x :z z :yaw yaw :size len :life (case kind ((:beam :judge) 30) (t 16))
                         :hook 'br-hz :data (make-lbh :kind kind :len (f32 len) :width (f32 width) :lock lock) :look 'lb-look))

;;; ---------------------------------------------------------------- JILLIEL: the modes, the traces (§5)
(defun br-melee-in (e)
  "A melee J1 / K1's frame 0: pressed in a ranged mode (or its MUJITTAI, dropped there first), he is back in melee (the move
goes on: the same move is melee's)."
  (let* ((form (fighter-form (fighter e))) (to (br-melee-of form)))
    (unless (eq to form) (set-form e to) (pace e :to-melee))))

(defun br-go-ranged (e)
  "The turn's / the backstep's last frame: ranged mode."
  (let* ((form (fighter-form (fighter e))) (to (br-ranged-of form)))
    (unless (eq to form) (set-form e to) (pace e :to-ranged))))

(defun br-l-link-go (e)
  "The melee L router's f0: the move BARRO-OK routed it to (the recall off K3, the backstep off J3, else the mode turn)."
  (let ((f (fighter e)))
    (start-move e (kit-next (fighter-kit f) :br-l-link (brs-l-to (br e))))
    (pace e (case (brs-l-to (br e)) (:br-recall :l-recall) (:br-backstep :l-backstep) (t :l-to-en)))))

(defun br-halt-tick (e) "The mode turns, the backstep, the recall: no string chase (the slide is their only movement)." (halt! e))

(defun br-backstep-go (e)
  "J3 -> L f0: *BR-BACKSTEP* m straight back from him over *BR-BACKSTEP-F*, iframes f0-6."
  (let* ((f (fighter e)) (p (pos-of e)))
    (set-slide e *br-backstep* *br-backstep-f* (- (aref p 0) (fighter-ox f)) (- (aref p 2) (fighter-oz f)))
    (setf (fighter-invuln f) (max (fighter-invuln f) *br-backstep-iframes*))
    (pace e :backstep)
    (emit :hoho-out e (aref p 0) (aref p 2))
    (emit :sfx :whoosh-light e)))

(defun br-live-traces (e)
  "His live traces: values how many and the oldest one's entity (the smallest id), or NIL."
  (let ((n 0) (old nil) (oid 0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d))
          (incf n)
          (when (or (null old) (< (brh-id d) oid)) (setf old h oid (brh-id d))))))
    (values n old)))

(defun br-lay-trace (e src yaw-off)
  "One trace of SRC (:l :sp1 :sp2) from where he stands, at his facing + YAW-OFF degrees, *BR-TRACE-LEN* long: a hazard
with no hit (drawn by BR-TRACE-LOOK) until materialised; at most *BR-TRACE-MAX* live (the oldest dropped)."
  (let ((st (br e)) (p (pos-of e)) (r (if (eq src :sp2) *br-trace-r-thick* *br-trace-r*)))
    (multiple-value-bind (n old) (br-live-traces e)
      (when (>= n *br-trace-max*) (destroy-entity old) (pace e :traces-dropped)))
    (spawn-hazard :br-trace e :x (aref p 0) :z (aref p 2) :yaw (+ (yaw-of e) (deg yaw-off)) :size *br-trace-len*
                              :life 1000000 :hook 'br-hz :look 'br-trace-look
                              :data (make-brh :src src :id (incf (brs-trace-n st)) :live t :width (f32 r)
                                              :vol (make-vol :cap (list 0.6 *br-trace-len* 1.2 r))))
    (pace e :traces)))

(defun br-lay (e)
  "A ranged lay's line frame: he faces the opponent, pays the line (BR-LINE-COST; short of it, none) and lays it (SP1's fan
by its frame, *BR-SP1-FAN*). Laying deals nothing."
  (let* ((f (fighter e)) (g (gauges e)) (src (move-param e :trace)) (cost (br-line-cost src))
         (off (if (eq src :sp1) (or (second (assoc (fighter-sf f) *br-sp1-fan*)) 0.0) 0.0)))
    (turn-to-opp e f 10.0)
    (if (>= (gauges-fs g) cost)
        (progn (spend-fs g cost) (br-lay-trace e src off))
        (pace e :traces-unpaid))
    (emit :sfx :rift-cut e)))

(defun br-materialise! (e h hz d q)
  "Trace D (hazard HZ, entity H) of E materialises with the opponent at Q: turned toward him (BR-SNAP-YAW), a 2-frame hit
(BR-TRACE-HITWIN x his form's damage), then gone; its flash (the owl's: 裁きの光明's gold)."
  (declare (ignore h))
  (let ((owl (br-owl-form-p (fighter-form (fighter e)))))
    (setf (brh-live d) nil
          (hazard-yaw hz) (br-snap-yaw (hazard-yaw hz) (hazard-x hz) (hazard-z hz) (aref q 0) (aref q 2))
          (hazard-hw hz) (br-trace-hitwin (brh-src d) (kit-mult (kit-of e)))
          (hazard-hits-left hz) 1 (hazard-life hz) (+ (hazard-age hz) 3))
    (cond (owl (br-spawn-look-at e :judge (hazard-x hz) (hazard-z hz) (hazard-yaw hz) 31.0 (brh-width d)
                                 (if (eq (brh-src d) :sp2) :thick t)))
          (t (br-spawn-look-at e (if (eq (brh-src d) :sp2) :beam :shot) (hazard-x hz) (hazard-z hz) (hazard-yaw hz) 31.0
                               (if (eq (brh-src d) :sp2) 1.2 0.05) t)))))

(defun br-materialise-near (e)
  "Every live trace of E with the opponent inside its *BR-NEAR-DEG* snap correction and its length materialises (§5.3,
BR-NEAR-P). Values the count."
  (let ((q (pos-of (opp-of e))) (hs nil))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d)
                   (multiple-value-call #'br-near-p (br-trace-angle (hazard-x hz) (hazard-z hz) (hazard-yaw hz) (aref q 0) (aref q 2))))
          (push (list h hz d) hs))))
    (dolist (x hs) (destructuring-bind (h hz d) x (br-materialise! e h hz d q)))
    (when hs (pace e :materialised (length hs)) (emit :sfx :lb-crack e))
    (length hs)))

(defun br-k-mat (e) "A melee K's first active frame: the near traces materialise, hit or whiff (§5.3)." (br-materialise-near e))

(defun br-clear-traces (e)
  "His live traces vanish (the revival, the recall). Values how many."
  (let ((gone nil))
    (do-entities (h (hz hazard)) (let ((d (hazard-data hz))) (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d)) (push h gone))))
    (dolist (h gone) (destroy-entity h))
    (length gone)))

(defun br-recall-go (e)
  "K3 -> L, f0: every live trace taken back and counted (§5.4)."
  (let ((n (br-clear-traces e)))
    (setf (brs-recall-n (br e)) n (brs-live (br e)) 0)
    (pace e :recall) (pace e (intern (format nil "RECALL-T~d" (br-recall-tier n)) :keyword))
    (emit :sfx :rift-open e)))

(defun br-recall-fire (e)
  "The recall's f7: the derivative string for its count (BR-RECALL-TIER), facing him."
  (let* ((f (fighter e)) (tier (br-recall-tier (brs-recall-n (br e)))))
    (turn-to-opp e f 10.0)
    (start-move e (kit-next (fighter-kit f) :br-recall (svref #(:rc0 :rc1 :rc2 :rc3) tier)))))

(defun br-rc-tick (e) "The recall strings: he keeps on the opponent (*BR-RC-TRACK*)." (halt! e) (turn-to-opp e (fighter e) (track-step *br-rc-track*)))
(defun br-rc-shot (e) "A recall string's line: its look." (br-spawn-look e :shot *br-x-len* 0.05 t) (emit :sfx :lb-crack e))

(defun br-hz (h hz ev &optional a b c dd ee)
  "His hazards' hook: a trace's line (only a materialised one has a hit), a 裁きの光明 ground line's burning span; the looks
touch nothing."
  (declare (ignore h))
  (let ((d (hazard-data hz)))
    (case ev
      (:touches
       (cond ((brh-p d)
              (let ((yaw (hazard-yaw hz)))
                (vol-hit-p (brh-vol d) (hazard-x hz) 0f0 (hazard-z hz) (f32 (fwd-x yaw)) (f32 (fwd-z yaw))
                           (f32 a) (f32 b) (f32 c) (f32 dd) (f32 ee) 0f0)))
             ((and (eq (hazard-kind hz) :br-misuji))
              (multiple-value-bind (from to) (br-misuji-span (hazard-age hz))
                (and (> to from)
                     (let* ((yaw (hazard-yaw hz)) (mid (* 0.5 (+ from to))))
                       (obox-cyl-hit-p (f32 (+ (hazard-x hz) (* mid (fwd-x yaw)))) 1f0 (f32 (+ (hazard-z hz) (* mid (fwd-z yaw))))
                                       yaw (f32 (* 0.5 *br-misuji-width*)) 1.2f0 (f32 (* 0.5 (- to from)))
                                       a b c dd ee)))))))
      (t nil))))

;;; ---------------------------------------------------------------- the owl's melee SPs (the old KIN's, copied)
(defun br-misuji (e)
  "The chop's frame: a 裁きの光明 ground line per :fan angle (one hit group: one line at most hits him), each erupting from
1 m to 18 m (BR-MISUJI-SPAN), through guard (chip 15 %, the :guard drain), once."
  (let* ((p (pos-of e)) (fan (move-param e :fan)) (group (make-hit-group 1)))
    (dolist (a fan)
      (spawn-hazard :br-misuji e :x (aref p 0) :z (aref p 2) :yaw (+ (yaw-of e) (deg a)) :size *br-misuji-to*
                                 :life (br-misuji-frames) :group group :hook 'br-hz :look 'lb-look
                                 :data (make-lbh :kind :sabaki :len (f32 *br-misuji-to*) :width (f32 *br-misuji-width*))
                                 :hw (make-hitwin :dmg (move-param e :dmg) :react :stagger :kb 1.0 :hs *hitstop-heavy*
                                                  :chip 0.15 :guard (move-param e :guard)
                                                  :flags '(:ranged :x-axis :uncatchable))))
    (pace e :misuji)
    (emit :sfx :ground-crack e)))

(defun br-reflect-check (e st mv)
  "Trompete at the end of its f59: the opponent in a perfect Hoho started f48-f59, or in a guard pressed f50-f58 (facing
him, not a ward) reflects it."
  (let* ((o (opp-of e)) (fo (fighter o)) (go (gauges o)) (p (pos-of e)) (q (pos-of o))
         (src (cond ((and (eq (fighter-state fo) :hoho) (fighter-perfect fo) (br-reflect-hoho-p (- 59 (fighter-sf fo)))) :hoho)
                    ((and (eq (fighter-state fo) :guard) (not (passive-p o :ward)) (br-reflect-guard-p (fighter-guard-t fo))
                          (can-guard-p (gauges-gg go) (gauges-guardless go))
                          (in-front-p (yaw-of o) (aref q 0) (aref q 2) (aref p 0) (aref p 2) *guard-arc*))
                     :guard))))
    (when src (br-reflect! e o st mv src))))

(defun br-reflect! (e o st mv src)
  "The reflect: he takes *BR-REFLECT-K* of Trompete x his form's damage as a real hit, staggers *BR-REFLECT-STUN*; SP2 is
sealed in the owl's modes for the match. The reflector takes nothing."
  (let* ((dmg (round (* *br-reflect-k* (hw-dmg (svref (mv-hits mv) 0)) (kit-mult (kit-of e))))) (q (pos-of o)) (p (pos-of e)))
    (setf (brs-sealed st) t (fighter-perfect (fighter o)) nil)
    (callout o "REFLECT")
    (pace e (if (eq src :hoho) :reflect-hoho :reflect-guard))
    (hitstop *hitstop-breaker*)
    (emit :hit o e (aref p 0) (+ (aref p 1) 1.1) (aref p 2) *hitstop-breaker* nil dmg :sp)
    (unless (deal-damage o e dmg)
      (set-reaction e :stagger *br-reflect-stun* (aref q 0) (aref q 2) 1.0))
    (clog "~a TROMPETE REFLECTED by ~a (~a): ~d, sealed" (side-name e) (side-name o) src dmg)))

(defun br-reflect-test-step (e f)
  "Debug 82007 / 82008 (*BR-REFLECT-TEST*): the opponent's (CPU-off) brain presses guard on Trompete's f54, or Hoho on f52."
  (let* ((o (opp-of e)) (b (brain o)) (sf (fighter-sf f)))
    (when b
      (cond ((and (eq *br-reflect-test* :guard) (= sf 53)) (ai-press b :guard 200 :act :hold))
            ((and (eq *br-reflect-test* :hoho) (= sf 51)) (ai-press b :step 1 :modded t :act :hoho))))))

;;; ================================================================ AI (batch 4, 2026-10-09: DUEL_LILLE_V2 §8, §13)
;;; His CPU: his kits' :ai keys (every chance a :p there, x *BR-AI-DIFF* by difficulty: EASY <= NORMAL <= HARD) and these
;;; reflexes (the kits' :reflex BR-AI-REFLEX, ai.lisp AI-REFLEX: free states, before the generic answers). Every roll is
;;; made once per event: a decision window (the base form's every *BR-AI-EVERY* f), a threat window (his move's start tick,
;;; a hazard's spawn), a trace laid (the fire roll), a link's land frame (the enders), a stance (its plan at f6).
;;;   base      the stance at range (:zone: L, then its plan: the 萬物貫通 shot), the stance in close with a 狙擊 pip (:pip:
;;;             its plan TAISHA / the snap shot); strings up close (the generic bands); L after a K link (:l-after-k, the
;;;             stance at f4, its plan the shot on the reeling opponent)
;;;   melee     strings (the bands); K3 -> L the recall at :recall's count (n >= :n, or >= :low-n under :low of his Reishi),
;;;             J3 -> L the backstep with no trace and the flash step for lines (:backstep :fs) (BR-AI-SP-ENDER on the
;;;             ender's hit); K at the traces near him (:fire :n: K materialises them at its first active frame)
;;;   ranged    lay lines at him (L, SP1 the fan: :lay) while the flash step stays over :reserve, from :far m; at :fire :n
;;;             traces near him, or him inside :in m, or reeling / recovering for K1's startup with one near: K / J in
;;;   MUJITTAI  U as a reaction to a threat (:stance :p, one roll per window: BR-AI-STANCE-IN, the old stance rule's shape);
;;;             out by attacking on his whiff, after :max frames, under :gg of the guard gauge, or him idle out of reach
;;;   the owl   the same rules; the revival (P) is the generic :bankai key with the JILLIEL kits' :bankai-ok
;;;   opponents a CPU facing his awakened forms steps off his live traces near it, one roll per new trace (BR-OPP-TRACE)
(defparameter *br-ai-diff* '(:easy 0.5 :normal 1.0 :hard 1.5)
  "His CPU's chances (his kits' :ai :p values) x this by difficulty, at most 1 (new 2026-10-09, batch 4: the old Lille's
*LB-AI-DIFF*).")
(defparameter *br-ai-every* 30
  "Frames between two of the base form's stance decisions (:zone / :pip, one roll each; new 2026-10-09, batch 4).")

;; pure: host-tested (tests/duel-rules-test.lisp)
(defun br-ai-chance (p difficulty) "A chance P of his kit's :ai at DIFFICULTY: x *BR-AI-DIFF*, at most 1." (min 1.0 (* p (getf *br-ai-diff* difficulty 1.0))))
(defun br-ai-base-plan (r d snipe threat zone pip difficulty)
  "The base form's stance decision from one roll R (§8): with a 狙擊 pip (SNIPE >= 1) and him inside PIP's :near m, PIP's
:p: :PIP (the stance; its plan TAISHA / the snap); from ZONE's :near m, ZONE's :p: :ZONE (the stance; its plan the shot);
none while THREAT (his attack coming: the generic answers it) or without the keys."
  (cond (threat nil)
        ((and pip (>= snipe 1) (< d (getf pip :near 4.0)) (< r (br-ai-chance (getf pip :p 0.0) difficulty))) :pip)
        ((and zone (>= d (getf zone :near 6.0)) (< r (br-ai-chance (getf zone :p 0.0) difficulty))) :zone)))
(defun br-ai-recall-p (n reishi-frac k)
  "Does his CPU recall (K3 -> L) with N traces live at REISHI-FRAC of his Reishi (K: the kit's :recall): N >= :n, or N >=
:low-n under :low (§8: 「n >= 3 (or n >= 1 at low HP)」)?"
  (and k (or (>= n (getf k :n 3)) (and (>= n (getf k :low-n 1)) (< reishi-frac (getf k :low 0.35)))) t))
(defun br-ai-backstep-p (n fs k)
  "Does his CPU back off (J3 -> L) with N traces live and FS flash step (K: the kit's :backstep): no trace left to recall and
the flash step for a fan of lines (:fs)?"
  (and k (zerop n) (>= fs (getf k :fs 9.0)) t))
(defun br-ai-fire-plan (near d busy k1-s q-reach k)
  "His ranged / melee CPU going in (K: the kit's :fire), NEAR traces near him (his perceived spot), D metres, BUSY his frames
reeling / recovering left (NIL: free): K (:F, it materialises them at its first active frame) at >= :n near, or at >=
:busy-n near while he stays busy past K1's startup K1-S; inside :in m J (:Q) within its reach Q-REACH + 0.4, else K; NIL."
  (cond ((null k) nil)
        ((>= near (getf k :n 4)) :f)
        ((and busy (>= busy k1-s) (>= near (getf k :busy-n 1))) :f)
        ((< d (getf k :in 0.0)) (if (<= d (+ q-reach 0.4)) :q :f))))
(defun br-ai-lay-plan (fs bars d near r k)
  "His ranged CPU's lay (K: the kit's :lay) at D metres with FS flash step and BARS Reiatsu bars, NEAR traces near him: from
:far m while fewer than :n of :fire lie near (passed as NEAR's cap by the caller), the price leaving >= :reserve: SP1's fan
(:SP1) on one roll R under :sp1 with a bar, else L (:SIG); NIL."
  (when (and k (>= d (getf k :far 4.0)) (< near (getf k :cap 99)))
    (let ((res (getf k :reserve 15.0)))
      (cond ((and (>= bars 1) (>= (- fs *br-lay-sp1*) res) (< r (getf k :sp1 0.0))) :sp1)
            ((>= (- fs *br-lay-l*) res) :sig)))))
(defun br-ai-stance-plan (r p line)
  "An awakened form's answer to one threatening window, from its one roll R: :STANCE (R < P: U, MUJITTAI), else :STEP off a
LINE, else :PASS (a Hoho on the generic roll, or nothing)."
  (cond ((< r p) :stance) (line :step) (t :pass)))
(defun br-stance-exit (busy frames max gg gg-min idle-far)
  "Why his CPU leaves MUJITTAI now (by attacking), or NIL: :WHIFF (he is BUSY), :MAX (FRAMES in it >= MAX), :GAUGE (the
guard gauge GG under GG-MIN), :IDLE (he is out of reach and idle: IDLE-FAR)."
  (cond (busy :whiff) ((>= frames max) :max) ((< gg gg-min) :gauge) (idle-far :idle)))

;; the shell
(defstruct (brai (:conc-name brai-))
  (e nil) (b nil)                         ; the fighter and the brain it belongs to (a new match: a fresh one)
  (key -1 :type fixnum)                   ; MUJITTAI: the threatening window rolled for (his move's start; a hazard's -2 - spawn)
  (plan nil)                              ; ... its answer: :stance :step :pass :done
  (exit -1 :type fixnum)                  ; the MUJITTAI whose exit was counted (its start tick)
  (base-t 0 :type fixnum)                 ; the base form's next stance decision tick
  (lay-t 0 :type fixnum)                  ; the ranged form's next lay tick
  (fire-key -1 :type fixnum) (fire-go nil))   ; the fire roll's event (the traces laid so far) and its answer
(defvar *br-ai* (vector (make-brai) (make-brai)) "Per side: his CPU's state.")
(defun br-ai-state (e b)
  (let* ((i (fighter-side (fighter e))) (st (svref *br-ai* i)))
    (if (and (eql (brai-e st) e) (eq (brai-b st) b)) st (setf (svref *br-ai* i) (make-brai :e e :b b)))))

(defun br-near-count (e x z)
  "How many of E's live traces have (X Z) inside their *BR-NEAR-DEG* snap (BR-NEAR-P): what a K would materialise there."
  (let ((n 0))
    (do-entities (h (hz hazard))
      (let ((d (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p d) (brh-live d)
                   (multiple-value-call #'br-near-p (br-trace-angle (hazard-x hz) (hazard-z hz) (hazard-yaw hz) x z)))
          (incf n))))
    n))

(defun br-ai-threat-p (e s d margin)
  "Is his perceived move S a threat: an attack in its main phase with hit frames, still to hit and within its reach + MARGIN
(an :x-axis line: E on it), not a parry, a bind's tell or a :reflectable blast?"
  (and (eq (snap-state s) :move) (eq (snap-phase s) :main)
       (member (snap-kind s) '(:quick :flash :sig :sp :breaker :kikon))
       (> (snap-active-end s) (snap-s s))
       (snap-live-p s) (snap-near-p s e d margin)
       (not (intersection '(:parry :bind :reflectable) (snap-flags s)))))

(defun br-ai-line-p (s)
  "Is his perceived move a lane: an :x-axis line or a Kikon module's lane? A Step clears it."
  (or (snap-x-axis-p s) (and (snap-move s) (eq (getf (mv-params (snap-move s)) :look) :lane))))

(defun br-ai-side-step (e b s)
  "A sideways Step off his perceived line (LINE-OFF-STRAFE; anything else: the current strafe)."
  (when (br-ai-line-p s)
    (let ((p (pos-of e)))
      (setf (brain-strafe b) (f32 (line-off-strafe (snap-x s) (snap-z s) (snap-yaw s) (aref p 0) (aref p 2) (snap-x s) (snap-z s))))))
  :side-step)

(defun br-ai-hazard-key (e lead)
  "One of his opponent's hazards about to hit E within LEAD frames (a wave / fireball flying at him, or a delayed one under
him whose delay is at most LEAD): its key (-2 - its spawn tick), or NIL."
  (let* ((o (opp-of e)) (q (pos-of e)) (bd (model-body (model e))) (key nil))
    (do-entities (h (hz hazard))
      (when (and (null key) (eql (hazard-owner hz) o) (hazard-hw hz) (> (hazard-hits-left hz) 0)
                 (if (and (member (hazard-kind hz) '(:wave :fireball)) (<= (hazard-delay hz) 0) (> (hazard-speed hz) 0.1))
                     (let ((dist (sqrt (+ (expt (- (aref q 0) (hazard-x hz)) 2) (expt (- (aref q 2) (hazard-z hz)) 2)))))
                       (<= (/ (* 60 (max 0.0 (- dist 1.0))) (hazard-speed hz)) lead))
                     (and (< 0 (hazard-delay hz) (1+ lead))
                          (hazard-touches-p hz (aref q 0) (aref q 1) (aref q 2) (body-hurt-r bd) (body-hurt-h bd)))))
        (setf key (- -2 (- *match-tick* (hazard-age hz))))))
    key))

(defun br-ai-busy-p (s delay frames)
  "Is he, as perceived, recovering or reeling, with at least FRAMES of it left after DELAY? (FRAMES 0: just busy.)"
  (and (< (snap-left s) 99) (snap-punishable-p s) (>= (- (snap-left s) delay) frames)))

(defun br-ai-stance-in (e b s d)
  "An awakened mode (§8, the old Lille's stance rule): a move of his starting within its reach + 1 m (an :x-axis line: E on
it), not a Breaker / grab, or a hazard of his within 12 f: one roll per window, :stance :p x the difficulty (0 under :gg of
the guard gauge): U (MUJITTAI, the kit's :guard-to). Else a sideways Step off a lane, or a Hoho on the generic Hoho roll
(his move >= 6 f out), else the generic answers (its guard is U: MUJITTAI as well)."
  (let* ((solid (not (or (eq (snap-kind s) :breaker) (member :grab (snap-flags s)))))
         (mv-threat (and solid (br-ai-threat-p e s d 1.0)))
         (key (if mv-threat (snap-start s) (br-ai-hazard-key e 12))))
    (if (null key)
        (and solid (br-ai-threat-p e s d *ai-threat-margin*) (why b :stance-out-of-reach :none))
        (let ((ai (br-ai-state e b)) (k (ai-table e :stance)) (g (gauges e)))
          (when (/= key (brai-key ai))
            (setf (brai-key ai) key
                  (brai-plan ai) (br-ai-stance-plan (sim-rnd01)
                                                    (if (or (gauges-guardless g) (< (gauges-gg g) (getf k :gg 30))) 0.0
                                                        (br-ai-chance (getf k :p 0.0) (brain-difficulty b)))
                                                    (and mv-threat (br-ai-line-p s))))
            (pace e (case (brai-plan ai) (:stance :ai-stance) (:step :ai-step) (t :ai-pass))))
          (case (brai-plan ai)
            (:stance (setf (brai-plan ai) :done) (ai-press b :guard 4 :act :hold) (why b :stance :none))
            (:step (setf (brai-plan ai) :done) (why b :stance-step (br-ai-side-step e b s)))
            (:pass (setf (brai-plan ai) :done)
                   (if (and mv-threat (>= (- (snap-s s) (snap-sf s)) 6) (hoho-ready-p e)
                            (ai-hoho-spare-p (gauges-fs g) (gauges-reishi g) (gauges-reishi-max g))
                            (< (brain-hoho-roll b) (ai-table e :hoho 0.2)))
                       (why b :stance-hoho :hoho)
                       nil))                              ; (the generic answers: a guard is U, MUJITTAI too)
            (t nil))))))

(defun br-ai-opp-reach (e)
  "His longest J / K reach (his current kit): what 'in reach' means for MUJITTAI's idle rule."
  (let ((kit (kit-of (opp-of e))))
    (loop for c in '(:q :f) for mv = (kit-command-move kit c) maximize (if mv (mv-reach mv) 0.0))))

(defun br-ai-exit-cmd (e b s d)
  "The attack that ends MUJITTAI: K1 when he stays busy for its startup within its reach, J1 within its, the traces near him
K (:fire), else L (ranged: a lay; melee: the turn to ranged) when it may start, else K1."
  (let* ((kit (kit-of e)) (q (kit-command-move kit :q)) (fm (kit-command-move kit :f)))
    (cond ((and fm (<= d (+ (mv-reach fm) 0.2)) (br-ai-busy-p s (brain-delay b) (mv-s fm)) (kit-command-ok-p e :f)) :f)
          ((and q (<= d (+ (mv-reach q) 0.2)) (kit-command-ok-p e :q)) :q)
          ((and fm (<= d (+ (mv-reach fm) 0.2)) (kit-command-ok-p e :f)) :f)
          ((and (>= (br-near-count e (snap-x s) (snap-z s)) (getf (ai-table e :fire) :n 4)) (kit-command-ok-p e :f)) :f)
          ((kit-command-ok-p e :sig) :sig)
          ((kit-command-ok-p e :f) :f))))

(defun br-ai-stance-out (e b s d)
  "MUJITTAI (§8): he leaves it only by attacking: on his whiff or recovery (as perceived), after :max frames in it, under :gg
of the guard gauge, or with him out of reach (+ 1 m) and idle; the whiff and idle rules wait while a hazard of his is
coming. Deterministic on what it sees, no roll."
  (let* ((k (ai-table e :stance)) (st (br e)) (calm (not (br-ai-hazard-key e 12))) (read (br-learn-mujittai b))
         (why (br-stance-exit (and calm (br-ai-busy-p s (brain-delay b) 0)) (brs-stance st)
                              (if (eq read :stay) 9999 (getf k :max 120))   ; (a learner's read: §13)
                              (gauges-gg (gauges e)) (getf k :gg 30)
                              (and calm (not (eq read :stay))
                                   (or (eq read :leave)
                                       (and (member (snap-state s) '(:idle :guard)) (> d (+ (br-ai-opp-reach e) 1.0))))))))
    (when why
      (let ((cmd (br-ai-exit-cmd e b s d)) (ai (br-ai-state e b)) (t0 (- *match-tick* (brs-stance st))))
        (when cmd
          (when (/= (brai-exit ai) t0)
            (setf (brai-exit ai) t0)
            (pace e (case why (:whiff :ai-exit-whiff) (:max :ai-exit-max) (:gauge :ai-exit-gauge) (t :ai-exit-idle))))
          (why b :br-stance-exit cmd))))))

(defun br-ai-base (e b s d)
  "The base form (§8): every *BR-AI-EVERY* f one roll (BR-AI-BASE-PLAN): the stance with a pip close (its plan TAISHA / the
snap), at range (its plan the shot); L pressed (the stance), or NIL."
  (let ((ai (br-ai-state e b)))
    (when (and (>= *match-tick* (brai-base-t ai)) (kit-command-ok-p e :sig))
      (setf (brai-base-t ai) (+ *match-tick* *br-ai-every*))
      (let ((plan (br-ai-base-plan (sim-rnd01) d (brs-snipe (br e)) (br-ai-threat-p e s d *ai-threat-margin*)
                                   (ai-table e :zone) (ai-table e :pip) (brain-difficulty b))))
        (when plan
          (pace e (if (eq plan :pip) :ai-pip :ai-zone))
          (why b plan :sig))))))

(defun br-ai-fire (e b s d)
  "Melee / ranged (§8): going in at the traces near him (BR-AI-FIRE-PLAN at his perceived spot): one roll per trace laid
(:fire :p x the difficulty; a no waits for the next line), a J inside :in m on the generic react roll. K / J, or NIL."
  (let* ((k (ai-table e :fire)) (kit (kit-of e)) (q (kit-command-move kit :q)) (fm (kit-command-move kit :f)))
    (when (and k q fm (not (br-learn-hold-p e b s)))   ; (a learner's Hoho read holds it: §13)
      (let* ((near (br-near-count e (snap-x s) (snap-z s)))
             (busy (and (br-ai-busy-p s (brain-delay b) 0) (snap-left-seen s b)))
             (cmd (br-ai-fire-plan near d busy (mv-s fm) (mv-reach q) k)))
        (when (and cmd (kit-command-ok-p e cmd))
          (let ((ai (br-ai-state e b)) (p (br-ai-chance (getf k :p 0.0) (brain-difficulty b))))
            (if (>= near (getf k :busy-n 1))
                (let ((key (brs-trace-n (br e))))     ; (one roll per trace laid)
                  (when (/= key (brai-fire-key ai))
                    (setf (brai-fire-key ai) key (brai-fire-go ai) (< (sim-rnd01) p)))
                  (and (brai-fire-go ai) (progn (pace e :ai-fire) (why b :br-fire cmd))))
                (and (< (brain-react-roll b) p) (progn (pace e :ai-in) (why b :br-in cmd))))))))))

(defun br-ai-lay (e b s d)
  "The ranged form (§8): a lay at him every :lay :every f (BR-AI-LAY-PLAN: SP1's fan on one roll per lay, else L), while the
flash step stays over :reserve and fewer than :fire :n traces lie near him. L / SP1, or NIL."
  (let ((k (ai-table e :lay)) (ai (br-ai-state e b)))
    (when (and k (>= *match-tick* (brai-lay-t ai)))
      (let* ((g (gauges e))
             (plan (br-ai-lay-plan (gauges-fs g) (reiatsu-bars e) d
                                   (min (br-near-count e (snap-x s) (snap-z s)) 99)
                                   (sim-rnd01) (list* :cap (getf (ai-table e :fire) :n 4) k))))
        (setf (brai-lay-t ai) (+ *match-tick* (getf k :every 12)))
        (when (and plan (kit-command-ok-p e plan))
          (pace e (if (eq plan :sp1) :ai-lay-fan :ai-lay))
          (why b :br-lay plan))))))

(defun br-ai-reflex (e b s d)
  "Every form's :reflex (ai.lisp AI-REFLEX, free states): the base form's stance (BR-AI-BASE); MUJITTAI's exit
(BR-AI-STANCE-OUT); ranged: MUJITTAI on a threat, going in, laying; melee: MUJITTAI on a threat, K at the traces near him.
A command, :NONE (the window is his), or NIL."
  (let* ((kit (kit-of e)) (form (kit-form kit)))
    (cond ((eq form :base) (br-ai-base e b s d))
          ((member :intangible (kit-passives kit)) (br-ai-stance-out e b s d))
          ((br-ranged-form-p form) (or (br-ai-stance-in e b s d) (br-learn-trace e b s d) (br-ai-fire e b s d) (br-ai-lay e b s d)))
          ((br-melee-form-p form) (or (br-ai-stance-in e b s d) (br-learn-trace e b s d) (br-ai-fire e b s d))))))

(defun br-ai-l-ok-p (e to)
  "His CPU's L link (BARRO-OK's CPU clause) to TO: the recall at :recall's count (BR-AI-RECALL-P), the backstep with no
trace and the flash step for lines (BR-AI-BACKSTEP-P), the mode turn always."
  (let ((st (br e)) (g (gauges e)))
    (case to
      (:br-recall (br-ai-recall-p (brs-live st) (reishi-frac g) (ai-table e :recall)))
      (:br-backstep (br-ai-backstep-p (brs-live st) (gauges-fs g) (ai-table e :backstep)))
      (t t))))

(defun br-ai-sp-ender (e kit)
  "The melee forms' :sp-ender (ai.lisp STRING-REFLEX: a landed J3 / K3, no O ender rolled; AI-BRAIN: his CPU's, or the
ASSIST's for a human): K3 -> L the recall (BR-AI-RECALL-P), J3 -> L the backstep (BR-AI-BACKSTEP-P), one roll on the land
frame at :recall / :backstep :p x the difficulty. :SIG, or NIL (the generic SP2 cancel)."
  (let* ((b (ai-brain e)) (f (fighter e)) (mv (fighter-move f)) (st (br e)) (g (gauges e)))
    (when (and b mv (member :ender (mv-flags mv)) (br-melee-form-p (kit-form kit)))
      (let* ((to (br-l-route (mv-kind mv) t)) (key (if (eq to :br-recall) :recall :backstep)) (k (getf (kit-ai kit) key)))
        (when (and (if (eq to :br-recall)
                       (br-ai-recall-p (brs-live st) (reishi-frac g) k)
                       (br-ai-backstep-p (brs-live st) (gauges-fs g) k))
                   (kit-command-ok-p e :sig kit nil (kit-l-link kit (mv-name mv)))
                   (< (sim-rnd01) (br-ai-chance (getf k :p 0.0) (brain-difficulty b))))
          (pace e (if (eq to :br-recall) :ai-recall :ai-backstep))
          :sig)))))

(defun br-opp-trace (e b s d)
  "A CPU facing his awakened forms (his kits' :opp-reflex, :opp-trace (:p)): standing inside the snap of one of his traces
it has seen (laid at least its perception delay ago) newer than the ones it rolled for: one roll for the new ones, :p x
the difficulty (OPP-CHANCE): a sideways Step off that line (LINE-OFF-STRAFE). Rooted forms can't. (The old Lille's
LB-OPP-TRACE, copied 2026-10-09: his K materialises them at any time, so no readiness test.)"
  (declare (ignore s d))
  (let* ((o (opp-of e)) (k (getf (kit-ai (kit-of o)) :opp-trace)))
    (when (and k (not (kit-rooted (kit-of e))) (br-awake-form-p (fighter-form (fighter o))))
      (let* ((st (br o)) (p (pos-of e)) (on nil) (newest 0))
        (do-entities (h (hz hazard))
          (let ((dd (hazard-data hz)))
            (when (and (eql (hazard-owner hz) o) (brh-p dd) (brh-live dd) (>= (hazard-age hz) (brain-delay b)))
              (setf newest (max newest (brh-id dd)))
              (when (and (> (brh-id dd) (brs-opp-roll st))
                         (multiple-value-call #'br-near-p
                           (br-trace-angle (hazard-x hz) (hazard-z hz) (hazard-yaw hz) (aref p 0) (aref p 2)))
                         (or (null on) (> (brh-id dd) (brh-id (hazard-data on)))))
                (setf on hz)))))
        (when on
          (setf (brs-opp-roll st) newest)
          (pace o :opp-trace-roll)
          (when (< (sim-rnd01) (opp-chance (getf k :p 0.0) (brain-difficulty b)))
            (pace o :opp-trace-step)
            (let ((q (pos-of o)))
              (setf (brain-strafe b) (f32 (line-off-strafe (hazard-x on) (hazard-z on) (hazard-yaw on) (aref p 0) (aref p 2)
                                                           (aref q 0) (aref q 2)))))
            (why b :trace-step :side-step)))))))

;;; ================================================================ AI: the learning CPU's situations (DUEL_LILLE_V2 §13)
;;; The old Lille's pattern (DUEL_LILLE §24.9): only a learner runs this (a CPU facing a human: VS CPU, ENDLESS, the learning
;;; gate; LRN-KIT); CPU VS CPU and the gates never get here. A read is one roll of the learner's own stream per event
;;; (LEARN-KIT-READ: p_exploit x *BR-LEARN-DIFF*), every answer a command of his kit.
;;;   :shot      his stance's 萬物貫通 shot on a free opponent (the stance's plan :kamae-l): the human's answer (:guard :hoho
;;;              :step :attack :back :take). Read at that plan: a guard -> the stance's SP1 (three lines, 120 of guard);
;;;              a Step / backing off -> the snap shot (S6) with a pip, else SP1 (it turns 90 deg/s); a Hoho / an attack ->
;;;              TAISHA's back-slide with a pip, else the stance's SP2 (the 6 m slide)
;;;   :trace     awakened, the human inside a live trace's snap (perceived, one he could have seen): his answer (:step off
;;;              it, :guard, :hoho, :attack, :back along it, :take). Read at the onset: a guard -> K now (萬物貫通 through
;;;              it); a Step -> SP1's fan at him (ranged, the bar and the flash step there); a Hoho -> the fire held while
;;;              he is free (*BR-LEARN-HOLD* f); an attack -> MUJITTAI (U) once he is inside 4 m
;;;   :mujittai  his MUJITTAI with the human inside 5 m: his answer (:attack into it, :guard, :hoho, :step, :back, :take). Read
;;;              at the onset: an attack -> he stays (no :max / idle exit: the whiff exit only); waiting (:guard :back :take)
;;;              -> he leaves at once (MUJITTAI's exit command)
(defparameter *br-learn-diff* '(:easy 0.5 :normal 1.0 :hard 1.5)
  "His learning CPU's read chance x this by difficulty (on the learner's p_exploit): EASY <= NORMAL <= HARD (new 2026-10-09,
batch 4; the old Lille's *LB-LEARN-DIFF*).")
(defparameter *br-learn-episode* '(:shot 24 :trace 40 :mujittai 60)
  "Frames a situation waits for his answer, + the perception delay (new 2026-10-09, batch 4).")
(defparameter *br-learn-hold* 60 "Frames a :trace read of a Hoho holds the fire at most (new 2026-10-09, batch 4).")

;; pure: host-tested
(defun br-learn-answer (hprev hs new away)
  "His answer starting this step (perceived HPREV -> HS, NEW: a new move of his, AWAY: metres he moved away since the onset):
:HOHO, :STEP, :ATTACK, :GUARD, :BACK, or NIL (the old Lille's LB-LEARN-ANSWER)."
  (cond ((and (eq hs :hoho) (not (eq hprev :hoho))) :hoho)
        ((and (eq hs :step) (not (eq hprev :step))) :step)
        ((and (eq hs :move) (or (not (eq hprev :move)) new)) :attack)
        ((and (eq hs :guard) (not (eq hprev :guard))) :guard)
        ((> away *learn-back*) :back)))
(defun br-learn-onset-answer (hs) "His answer already under way at the onset (perceived HS): a guard, a Hoho, a Step, or NIL."
  (case hs ((:guard :guard-hit) :guard) (:hoho :hoho) (:step :step)))
(defun br-learn-kamae-plan (read snipe sp-ok plan)
  "The stance's follow-up instead of PLAN (the shot) for his predicted answer READ to it (SNIPE pips, SP-OK the bars): a
guard the stance's SP1; a Step / backing off the snap shot (a pip) else SP1; a Hoho / an attack TAISHA (a pip) else the
stance's SP2; else PLAN."
  (case read
    (:guard (if sp-ok :kamae-sp1 plan))
    ((:step :back) (cond ((>= snipe 1) :kamae-j) (sp-ok :kamae-sp1) (t plan)))
    ((:hoho :attack) (cond ((>= snipe 1) :kamae-k) (sp-ok :kamae-sp2) (t plan)))
    (t plan)))
(defun br-learn-trace-plan (read)
  "The :trace read's answer: a guard :FIRE (K now), a Step :FAN (SP1 at him), a Hoho :HOLD (the fire waits), an attack
:STANCE (MUJITTAI), else NIL."
  (case read (:guard :fire) (:step :fan) (:hoho :hold) (:attack :stance)))
(defun br-learn-mujittai-plan (read)
  "The :mujittai read's answer: an attack :STAY (only the whiff exit), waiting (:guard :back :take) :LEAVE (out at once)."
  (case read (:attack :stay) ((:guard :back :take) :leave)))

;; the shell
(defstruct (brl (:conc-name brl-))
  "His learner's own state within a match (LRN-KDATA)."
  (own-mv nil) (own-sf 0 :type fixnum)                      ; his move last step (the shot's onset)
  (ox 0f0 :type single-float) (oz 0f0 :type single-float)   ; the open situation's onset: his perceived position,
  (ux 0f0 :type single-float) (uz 0f0 :type single-float)   ; ... the way from Lille II to him (his :back)
  (len 0 :type fixnum)                                      ; ... its episode's frames
  (on-id 0 :type fixnum)                                    ; the newest trace he was perceived near (id; 0 none)
  (trace-plan nil) (trace-until -1 :type fixnum) (trace-done nil)   ; the :trace read's answer, its life, acted
  (mu-t0 -1 :type fixnum) (mu-plan nil))                    ; the MUJITTAI read (its start tick) and its answer
(defun br-learn-state (l) (or (lrn-kdata l) (setf (lrn-kdata l) (make-brl))))
(defun br-learn-l (b) "Brain B's learner when it reads his situations (LRN-KIT), else NIL." (let ((l (and b (brain-learn b)))) (and l (lrn-kit l) l)))
(defun br-learn-scale (b) (float (getf *br-learn-diff* (brain-difficulty b) 1.0) 1.0))
(defun br-learn-acted (e l cmd)
  "A read of his situations acted on with CMD: the learner's count (LEARN-COUNT-READ), the log."
  (learn-count-read e l cmd)
  (pace e cmd)
  (clog "~a read ~a" (side-name e) cmd))

(defun br-learn-open (e s l k key)
  "Open his situation KEY at the perceived SNAP S: the onset's position, the way to him; an answer already under way
(BR-LEARN-ONSET-ANSWER) counts at once."
  (let* ((dx (- (snap-x s) (aref (pos-of e) 0))) (dz (- (snap-z s) (aref (pos-of e) 2))) (m (max 1e-3 (hypot dx dz))))
    (setf (brl-ox k) (snap-x s) (brl-oz k) (snap-z s) (brl-ux k) (f32 (/ dx m)) (brl-uz k) (f32 (/ dz m))
          (brl-len k) (+ (getf *br-learn-episode* key 30) (brain-delay (brain e)))))
  (learn-kit-open l key)
  (let ((now (br-learn-onset-answer (snap-state s))))
    (when now (learn-kit-close l now))))

(defun br-learn-near-id (e x z age)
  "The newest of E's live traces at least AGE frames old with (X Z) inside its snap (BR-NEAR-P): its id, 0 for none."
  (let ((id 0))
    (do-entities (h (hz hazard))
      (let ((dd (hazard-data hz)))
        (when (and (eql (hazard-owner hz) e) (brh-p dd) (brh-live dd) (>= (hazard-age hz) age) (> (brh-id dd) id)
                   (multiple-value-call #'br-near-p (br-trace-angle (hazard-x hz) (hazard-z hz) (hazard-yaw hz) x z)))
          (setf id (brh-id dd)))))
    id))

(defun br-learn-step (e b s d l)
  "His learner's step (LEARN-DEF-KIT's :step): the onsets (his stance's shot; MUJITTAI with him inside 5 m; the human inside
a trace's snap, perceived), the open situation's answer (BR-LEARN-ANSWER; :trace's :step when he left every snap; at its
end :TAKE, or :GUARD held through), the :trace and :mujittai reads at their onsets (one roll each)."
  (let* ((k (br-learn-state l)) (f (fighter e)) (mv (and (eq (fighter-state f) :move) (fighter-move f)))
         (hs (snap-state s)) (hprev (lrn-hstate l)) (new (/= (snap-start s) (lrn-hstart l))) (st (br e))
         (x (snap-x s)) (z (snap-z s)))
    (when (and mv (or (not (eq mv (brl-own-mv k))) (< (fighter-sf f) (brl-own-sf k)))
               (eq (mv-name mv) :br-k-shot) (< (lrn-ksit l) 0) (member hs '(:idle :run :guard)))
      (br-learn-open e s l k :shot))
    (setf (brl-own-mv k) mv (brl-own-sf k) (if mv (fighter-sf f) 0))
    (when (and (member :intangible (kit-passives (fighter-kit f))) (< d 5.0))
      (let ((t0 (- *match-tick* (brs-stance st))))
        (when (/= t0 (brl-mu-t0 k))
          (setf (brl-mu-t0 k) t0
                (brl-mu-plan k) (br-learn-mujittai-plan (learn-kit-read l :mujittai (br-learn-scale b))))
          (when (brl-mu-plan k) (br-learn-acted e l (if (eq (brl-mu-plan k) :stay) :br-mu-stay :br-mu-leave)))
          (when (< (lrn-ksit l) 0) (br-learn-open e s l k :mujittai)))))
    (when (and (br-awake-form-p (fighter-form f)) (plusp (brs-live st)))
      (let ((id (br-learn-near-id e x z (brain-delay b))))
        (when (and (> id (brl-on-id k)) (< (lrn-ksit l) 0))
          (br-learn-open e s l k :trace)
          (setf (brl-trace-plan k) (br-learn-trace-plan (learn-kit-read l :trace (br-learn-scale b)))
                (brl-trace-until k) (+ *match-tick* (if (eq (brl-trace-plan k) :hold) *br-learn-hold* (brl-len k)))
                (brl-trace-done k) nil))
        (setf (brl-on-id k) (max id (brl-on-id k)))))
    (when (>= (lrn-ksit l) 0)
      (let ((sit (aref (getf (lrn-kit l) :situations) (lrn-ksit l))) (end (>= (incf (lrn-kep-t l)) (brl-len k)))
            (away (+ (* (- x (brl-ox k)) (brl-ux k)) (* (- z (brl-oz k)) (brl-uz k)))))
        (cond ((member hs '(:stun :air :down :wakeup)) (learn-kit-close l (if (eq sit :trace) nil :take)))
              (t (let ((ans (or (br-learn-answer hprev hs new away)
                                (and (eq sit :trace) (zerop (br-near-count e x z)) :step))))
                   (cond (ans (learn-kit-close l ans))
                         (end (learn-kit-close l (if (member hs '(:guard :guard-hit)) :guard :take)))))))))))

(defun br-learn-trace (e b s d)
  "Melee / ranged free (BR-AI-REFLEX, before BR-AI-FIRE): the :trace read's answer, once a read: K at the traces near him (a
guard read), SP1's fan at him (a Step read, ranged), U (an attack read, him inside 4 m). A command, or NIL. (A Hoho read
holds the fire: BR-LEARN-HOLD-P.)"
  (let ((l (br-learn-l b)))
    (when l
      (let* ((k (br-learn-state l)) (p (brl-trace-plan k)))
        (when (and p (not (brl-trace-done k)) (<= *match-tick* (brl-trace-until k)))
          (case p
            (:fire (when (and (plusp (br-near-count e (snap-x s) (snap-z s))) (kit-command-ok-p e :f))
                     (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-fire) (why b :learn-fire :f)))
            (:fan (when (and (br-ranged-form-p (fighter-form (fighter e))) (kit-command-ok-p e :sp1))
                    (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-fan) (why b :learn-fan :sp1)))
            (:stance (when (< d 4.0)
                       (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-stance)
                       (ai-press b :guard 4 :act :hold) (why b :learn-stance :none)))))))))

(defun br-learn-hold-p (e b s)
  "Does a :trace read of a Hoho hold his fire now (the read's window, him free: BR-AI-FIRE waits)?"
  (let ((l (br-learn-l b)))
    (and l (let ((k (br-learn-state l)))
             (and (eq (brl-trace-plan k) :hold) (<= *match-tick* (brl-trace-until k))
                  (not (br-ai-busy-p s (brain-delay b) 0))
                  (progn (unless (brl-trace-done k) (setf (brl-trace-done k) t) (br-learn-acted e l :br-trace-hold)) t))))))

(defun br-learn-mujittai (b)
  "The :mujittai read's answer for MUJITTAI's exit (BR-AI-STANCE-OUT): :STAY, :LEAVE, or NIL."
  (let ((l (br-learn-l b))) (and l (brl-mu-plan (br-learn-state l)))))

(defun br-learn-kamae (e b plan)
  "The stance's PLAN (BR-AI-KAMAE, once a stance, his CPU): the shot on a free opponent is read (one roll: :shot) and
answered (BR-LEARN-KAMAE-PLAN); anything else, or no learner, as planned."
  (let ((l (br-learn-l b)))
    (if (and l (eq plan :kamae-l) (not (member (state-of (opp-of e)) '(:stun :air))))
        (let* ((r (learn-kit-read l :shot (br-learn-scale b)))
               (p (br-learn-kamae-plan r (brs-snipe (br e))
                                       (>= (gauges-reiatsu (gauges e)) (* (kit-command-cost (kit-of e) :sp1) *reiatsu-bar*)) plan)))
          (unless (eq p plan) (br-learn-acted e l (intern (format nil "BR-SHOT-~a" r) :keyword)))
          p)
        plan)))

(learn-def-kit :barro :situations #(:shot :trace :mujittai) :actions #(:guard :hoho :step :attack :back :take)
               :step 'br-learn-step)

;;; ================================================================ ASSIST AUTO COMBO's routes (DUEL_LILLE_V2 §8, §13)
;;; His kits' :ai name BR-ASSIST-COMBO as :assist-combo (assist.lisp AUTO-ROUTE: asked every step AUTO COMBO is on, before
;;; the generic AUTO COMBO; the old Lille's LB-ASSIST-COMBO's shape). "You press J, the CPU chooses": the routes press his
;;; buttons as a human's (his ticks read his vpad: BR-TICK-BRAIN is NIL for a human), x*ASSIST-MULT*, the AUTO tag.
;;;   base    J J J -> L -> L: his J string's J3 that hit -> the stance on his first free step -> its plan (BR-AI-KAMAE-PLAN:
;;;           the 萬物貫通 shot; TAISHA / the snap with a pip close) pressed once it is up; his J eaten meanwhile
;;;   melee   K K K -> L: his J in a melee link that hit -> its K link (to K3) on the land frame -> K3 -> L the recall with a
;;;           trace to take back (n >= 1); J3 -> L the backstep with no trace and 9 flash step; his J eaten after a press
;;;   ranged  L: his J pressed while free in ranged mode -> a lay at him (L) from 4 m while the flash step allows, K in once
;;;           :fire's count of traces lies near him; else his J (J1 back to melee)
(defstruct (bras (:conc-name bras-))
  (b nil)                                 ; the assist brain it belongs to (a new match: a fresh one)
  (mv nil) (sf -1 :type fixnum)           ; the move instance seen
  (j nil)                                 ; his J seen during it (pressed, buffered or latched)
  (done nil)                              ; the route pressed in it (his J eaten after)
  (route nil)                             ; a route runs (the stance's)
  (stance nil) (plan nil))                ; the base route: the stance due on his first free step, its plan
(defvar *br-as* (vector (make-bras) (make-bras)) "Per side: the ASSIST routes' state (BR-ASSIST-COMBO).")

(defun br-as-track (f b vp)
  "The route state of F's side for brain B, its move instance brought up to date, his J this step noted."
  (let* ((side (fighter-side f)) (a (svref *br-as* side)) (mv (and (eq (fighter-state f) :move) (fighter-move f))))
    (unless (eq (bras-b a) b) (setf a (make-bras :b b) (svref *br-as* side) a))
    (cond ((null mv) (setf (bras-mv a) nil (bras-j a) nil (bras-done a) nil))
          ((or (not (eq mv (bras-mv a))) (< (fighter-sf f) (bras-sf a)))
           (setf (bras-mv a) mv (bras-j a) nil (bras-done a) nil)
           (unless (member (mv-name mv) '(:br-kamae :br-kamae-k)) (setf (bras-route a) nil (bras-plan a) nil))))
    (when mv
      (setf (bras-sf a) (fighter-sf f))
      (when (or (vpad-command-pressed-p vp :quick nil) (eq (fighter-queued f) :q)) (setf (bras-j a) t)))
    a))

(defun br-as-press (e a key cmd)
  "A route press: counted in his pacing log (the gates' route counts), his J eaten after it in this move. CMD."
  (setf (bras-done a) t)
  (pace e key)
  cmd)

(defun br-as-kamae (e f vp a)
  "Route base, the stance of the route's: his J eaten till it is up, then its plan (one roll, BR-AI-KAMAE-PLAN) pressed once."
  (cond ((bras-done a) (vpad-consume! vp :quick) :none)
        ((< (1+ (fighter-sf f)) *br-kamae-up*) (vpad-consume! vp :quick) :none)
        (t (unless (bras-plan a)
             (setf (bras-plan a) (br-ai-kamae-plan (sim-rnd01) (fighter-dist f) (member (state-of (opp-of e)) '(:stun :air))
                                                   (brs-snipe (br e))
                                                   (>= (gauges-reiatsu (gauges e)) (* (kit-command-cost (fighter-kit f) :sp1) *reiatsu-bar*)))))
           (br-as-press e a :as-stance-plan
                        (case (bras-plan a) (:kamae-j :q) (:kamae-k :f) (:kamae-sp1 :sp1) (:kamae-sp2 :sp2) (t :sig))))))

(defun br-as-melee (e f vp a mv)
  "Route melee, a link that hit with his J in it: on its land frame its K link (to K3), K3 -> L the recall (n >= 1), J3 -> L
the backstep (no trace, 9 flash step); his J eaten after a press. A command, :NONE, or NIL (the generic AUTO COMBO)."
  (let* ((kit (fighter-kit f)) (st (br e)) (nf (kit-next kit (mv-name mv) :f)))
    (cond ((bras-done a) (vpad-consume! vp :quick) (when (eq (fighter-queued f) :q) (setf (fighter-queued f) nil)) :none)
          ((not (and (bras-j a) (eq (fighter-contact f) :hit) (= (fighter-sf f) (fighter-land-sf f)))) nil)
          (nf (br-as-press e a :as-k-link :f))
          ((and (member :ender (mv-flags mv)) (not (eq (state-of (opp-of e)) :air))
                (if (eq (mv-kind mv) :flash) (>= (brs-live st) 1) (br-ai-backstep-p (brs-live st) (gauges-fs (gauges e)) '(:fs 9.0)))
                (kit-command-ok-p e :sig kit nil (kit-l-link kit (mv-name mv))))
           (br-as-press e a (if (eq (mv-kind mv) :flash) :as-recall :as-backstep) :sig)))))

(defun br-as-ranged (e f s vp)
  "Route ranged, his J pressed while free: K in at :fire's count near him, else a lay (L) at him from 4 m with the flash step
over 15, else NIL (his J)."
  (when (and s (vpad-command-pressed-p vp :quick nil))
    (let ((near (br-near-count e (snap-x s) (snap-z s))))
      (cond ((and (>= near (getf (ai-table e :fire) :n 4)) (kit-command-ok-p e :f)) (pace e :as-fire) :f)
            ((and (>= (fighter-dist f) 4.0) (>= (- (gauges-fs (gauges e)) *br-lay-l*) 15.0) (kit-command-ok-p e :sig))
             (pace e :as-lay) :sig)))))

(defun br-assist-combo (e f b s d vp)
  "His kits' :assist-combo (assist.lisp AUTO-ROUTE): the routes above on the assist's brain B (S, D as it perceives him), his
vpad VP: a command, :NONE (the route holds the step) or NIL (the generic AUTO COMBO)."
  (declare (ignore d))
  (let* ((a (br-as-track f b vp)) (mv (bras-mv a)) (form (fighter-form f))
         (free (and (member (fighter-state f) '(:idle :guard :run)) (zerop (fighter-lock f)))))
    (cond ((and free (eq form :base) (bras-stance a))       ; (route base: the stance on the first free step)
           (setf (bras-stance a) nil)
           (if (kit-command-ok-p e :sig) (progn (setf (bras-route a) t) (pace e :as-stance) :sig) nil))
          ((and mv (member (mv-name mv) '(:br-kamae :br-kamae-k)) (bras-route a)) (br-as-kamae e f vp a))
          ((and mv (eq form :base) (eq (mv-name mv) :br-j3) (eq (fighter-contact f) :hit) (bras-j a))
           (setf (bras-stance a) t) (vpad-consume! vp :quick) :none)
          ((and mv (br-melee-form-p form) (member (mv-kind mv) '(:quick :flash))) (br-as-melee e f vp a mv))
          ((and free (br-ranged-form-p form)) (br-as-ranged e f s vp)))))

;; every form of his names it (assist.lisp AUTO-ROUTE reads the key off the form's kit)
(dolist (form *br-forms*)
  (let ((k (find-kit :barro form)))
    (unless (getf (kit-ai k) :assist-combo)
      (setf (kit-ai k) (list* :assist-combo 'br-assist-combo (kit-ai k))))))

;;; ================================================================ debug: tests, the pacing log (debug.lisp dispatches)
(defun barro-acc-line ()
  "After a gate row: a \"duel barro\" line per side that played him (the pacing log, DUEL_LILLE_V2 §11)."
  (dolist (e (list *p1* *p2*))
    (when (and (entity-alive-p e) (eq (fighter-character (fighter e)) :barro))
      (let ((st (br e)))
        (log-msg "duel barro ~a seed ~d awakened ~a form ~a snipe ~d live ~d sealed ~a ~{~(~a~) ~a~^ ~}" (side-name e) *match-seed*
                 (gauges-awakened (gauges e)) (fighter-form (fighter e)) (brs-snipe st) (brs-live st) (brs-sealed st)
                 (svref *pacing* (fighter-side (fighter e))))))))

(defun barro-probe-line (tag)
  (let ((g1 (gauges *p1*)) (g2 (gauges *p2*)) (st (br *p1*)))
    (log-msg "duel probe barro ~a t ~d p1 ~a ~a r~d k~d fs ~d snipe ~d live ~d revive ~a | p2 ~a r~d gg ~d"
             tag *match-tick* (fighter-form (fighter *p1*)) (state-of *p1*) (gauges-reishi g1) (gauges-konpaku g1)
             (round (gauges-fs g1)) (brs-snipe st) (br-live-traces *p1*) (bankai-ready-p *p1*)
             (state-of *p2*) (gauges-reishi g2) (round (gauges-gg g2)))))

(defun barro-test (k)
  "82000+k (human P1 Lille II, P2's CPU off unless noted; a \"duel probe barro\" line): 0 the base form 2.2 m from Kenpachi;
1 the base form 14 m out; 2 forced JILLIEL melee 5 m out; 3 forced ranged 8 m out; 4 forced owl melee 5 m out; 5 ranged
8 m out with 6 traces laid through P2 (the recall: J / K in, then K K K L); 6 the base form 4 m out with 3 狙擊 pips;
7 / 8 the owl melee 6 m out, Trompete started, P2 reflecting it by a guard on f54 / a Hoho on f52; 9 forced owl ranged
8 m out; 10 JILLIEL melee with 3 Konpaku (P revives); 11 / 12 forced melee / ranged MUJITTAI 5 m out; 20 both CPUs (the
mirror) 12 m apart."
  (flet ((setup (c2 form dist &key cpu)
           (ensure-battle :barro c2 :cpu cpu)
           (when (brain *p1*) (setf (brain-off (brain *p1*)) (not cpu)))
           (unless (eq (fighter-form (fighter *p1*)) form) (force-form *p1* form))
           (place *p1* *p2* dist)
           (setf (gauges-reiatsu (gauges *p1*)) *reiatsu-max* (gauges-fs (gauges *p1*)) (f32 *fs-max*))))
    (setf *br-reflect-test* nil)
    (case k
      (0 (setup :kenpachi :base 2.2))
      (1 (setup :kenpachi :base 14.0))
      (2 (setup :kenpachi :jilliel-kin 5.0))
      (3 (setup :kenpachi :jilliel 8.0))
      (4 (setup :kenpachi :shin-kin 5.0))
      (5 (setup :kenpachi :jilliel 8.0)
       (dolist (a '(-6.0 -3.6 -1.2 1.2 3.6 6.0)) (br-lay-trace *p1* :l a)))
      (6 (setup :kenpachi :base 4.0) (setf (brs-snipe (br *p1*)) 3))
      ((7 8) (setup :kenpachi :shin-kin 6.0) (setf *br-reflect-test* (if (= k 7) :guard :hoho)) (force-cmd *p1* :sp2))
      (9 (setup :kenpachi :shin 8.0))
      (10 (setup :kenpachi :jilliel-kin 5.0) (setf (gauges-konpaku (gauges *p1*)) 3))
      (11 (setup :kenpachi :jilliel-kin-mujittai 5.0))
      (12 (setup :kenpachi :jilliel-mujittai 5.0))
      (20 (setup :barro :base 12.0 :cpu t)))
    (barro-probe-line (format nil "test ~d" k))))

(defun barro-debug (c)
  "His debug commands (debug.lisp *CHAR-DEBUG*, the range 82000-82999, docs/duel/DUEL_GAMEPLAY.md): 82000+k BARRO-TEST k."
  (if (< c 82100) (barro-test (- c 82000)) (log-msg "duel barro: no debug command ~d" c)))
(pushnew '(82000 82999 barro-debug) *char-debug* :test #'equal)

;;; ================================================================ the HUD (barro-art.lisp's functions; not on the host)
(when (fboundp 'br-hud-meter)
  (let ((meter (list :name "SN" :max 3 :draw 'br-hud-meter :label 'br-hud-label
                     :bankai-prompt (list :key "P  REVIVE" :right "KP+  REVIVE" :pad "BACK  REVIVE" :one-hand "AWAKEN  REVIVE"
                                          :rgb (symbol-value '*c-lb-revive*)))))
    (dolist (form *br-forms*)
      (setf (kit-meter (find-kit :barro form)) meter))))
