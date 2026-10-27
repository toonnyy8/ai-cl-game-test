;;;; rukia.lisp — KUCHIKI RUKIA (TYBW), docs/duel/DUEL_RUKIA.md: her moves (DEFMOVE) and her four forms (DEFKIT): :base (the
;;;; Shikai 舞え、袖白雪, a mid-range placer of ice) and the awakening 絶対零度 ZETTAI REIDO, a cold gauge of two stacked
;;;; bars (the kit meter, C 0-200: rukia-meter.lisp RUKIA-COLD-STEP, rules TEMP-BAND) whose band is the form: :m18 (-18 C), :m50
;;;; (-50 C, bar 1 full) and :zero (-273.15 C, both full: rooted, the ward with freeze-touch, ranged hits guarded too). Guarding cools her,
;;;; not guarding warms her, actions spend cold (at -18 only L); colder is slower but longer, harder and wider in every
;;;; button, and the opponent is slower to leave her field. A CRACK (the zero ward broken) empties the gauge. Clip names
;;;; are the art contract (rukia-art.lisp). Below the data: her hooks and her three cinematics (DEFCINE). Every name
;;;; without a canon tag in the doc is the game's own.
(in-package :duel)
(declaim (special *match-seed*))   ; (flow.lisp's: RUKIA-ACC-LINE)

;;; ================================================================ Shikai (base)
;;; The Shikai's combat logic since 2026-10-24 (docs/duel/DUEL_RUKIA_TYBW.md §4.1-§4.4, the user's 「可以」): 霜の層, frost
;;; layers on him (0-3, the fighter's LAYERS / THAW; rules LAYERS-ADD / -THAW / LAYER-SPEED; tuning *RU-LAYER-MAX* *RU-THAW*
;;; *RU-LAYER-SLOW*): her K hits +1, J hits hold his thaw, TSUKISHIRO's pillar +2, ENBU +1; L after a J / K link that hit
;;; bursts them (six routes, link n up to n, each its own benefit, each the string's end); L tap BYAKURAI / held TSUKISHIRO;
;;; SP1 tap SOKATSUI / held RIKUJOKORO; SP2 SHIRAFUNE bursts all. RUKIA-HIT (the base kit's :hit hook) keeps the layers.
;;; The awakened bands keep their own moves, frost and rules (pinned in their kits below; the host test lists them).
;;; the J / K strings (docs/duel/DUEL_STRINGS.md §2.1 budget): J1 7 f beats every K1 in the game. The reach since the J cut
;;; (§13): J 0.6x, close; K -10 %. The J links are shared with the bands; the Shikai's K links lay a layer (:params :layers)
(defmove :ru-j1 :kind :quick :clip :ru-q1 :startup 7 :active 3 :recovery 12 :dmg 34 :adv-block -2
  :reach 1.44 :arc 100 :on-hit :flinch :slide 0.6)                              ; HATSUSHIMO: a one-handed flat cut
(defmove :ru-j2 :kind :quick :clip :ru-q2 :startup 7 :active 3 :recovery 13 :dmg 34 :adv-block -2
  :reach 1.32 :arc 100 :on-hit :flinch)                              ; KAZAHANA: the backhand along the same line
(defmove :ru-j3 :kind :quick :clip :ru-spin :startup 8 :active 3 :recovery 18 :dmg 42 :adv-block -4
  :reach 1.56 :arc 200 :on-hit :stagger :flags (:ender))             ; MAI-SODE: the pirouette, the ribbon whipping round
(defmove :ru-k1 :kind :flash :clip :ru-thrust :startup 17 :active 4 :recovery 20 :dmg 66 :adv-block -3
  :vol (:cap 0.2 2.55 1.1 0.3) :on-hit :stagger :params (:chill 1))   ; SHIMO-TSUKI: the fencer's lunge (a 冰凍值 point: two make a layer)
(defmove :ru-k2 :kind :flash :clip :ru-ring :enter 7 :startup 21 :active 4 :recovery 24 :dmg 58 :adv-block -3
  :reach 2.5 :arc 140 :on-hit :stagger :frost 60)                    ; HYORIN: the rising turn, a white ring (the bands')
(defmove :ru-k3 :kind :flash :clip :ru-drop :enter 7 :startup 21 :active 5 :recovery 34 :dmg 84 :adv-block -20
  :vol (:cap 0.3 2.7 1.2 0.35) :on-hit :crumple :flags (:ender) :params (:chill 1)    ; (a 冰凍值 point)
  :on-frame ((21 rukia-snow-burst)))                                 ; NADARE: both hands, held, dropped; snow bursts
(defmove-copy :ru-j2s :ru-j2)
(defmove-copy :ru-k2s :ru-k2)
;; the Shikai's K2 (the bands keep :ru-k2 with its frost 60): no frost, a layer
(defmove-copy :ru-sk2 :ru-k2 :frost 0 :params (:chill 1))
(defmove-copy :ru-sk2s :ru-sk2)
;; L after a J / K link that hit with >= 1 layer on him (the kit's per-link :l-after-j / :l-after-k, RUKIA-OK refuses it
;; at 0 layers or on a block: the string ends at that link): link n's own burst, up to n layers (:burst n; 3: all,
;; rules BURST-COUNT), :dmg + :per a layer burst (RUKIA-BURST-ARM at f0), the benefit at its hit (RUKIA-BURST!). Each ends
;; the string (a :sig: no link, no SP cancel, no O ender). After a J (A 3, flinch 18): S 10; after a K (A 4, stagger 26):
;; S 12; both combo with the link's hitstop (the host test). Clips: their own at speed 1 (the motion pass, DUEL_RUKIA_TYBW §13.3)
(defparameter *ru-burst-j-s* 10 "J1 / J2 / J3 + L: startup (S_eff; A 3 + 10 < flinch 18 with the hitstop; new 2026-10-24, the user, §4.4).")
(defparameter *ru-burst-k-s* 12 "K1 / K2 / K3 + L: startup (A 4 + 12 < stagger 26; new 2026-10-24, the user, §4.4).")
(defparameter *ru-hop* 2.5 "霜散 SHIMO-CHIRI: she hops back this far at its hit (new 2026-10-24, the user, §4.3).")
(defparameter *ru-refund* 0.08 "雪煙 SETSUEN: Reiatsu refunded per layer burst, x a bar (new 2026-10-24, the user, §4.4).")
(defparameter *ru-sojin* '(:r 3.0 :life 240 :per 30)
  "霜陣 SOJIN: the frost circle centred on him where the burst leaves him, radius m, frames, and a 冰凍值 point per this
many frames he stands in it (new 2026-10-24, the user, §4.4; round her, a layer a 60 f -> centred on him, a point a 30 f,
the user 2026-10-24, DUEL_RUKIA_TYBW §10).")
(defparameter *ru-tsurara-to* 6.0 "氷柱 TSURARA: he is pushed out to this distance (m) at its hit (new 2026-10-24, the user, §4.3).")
(defparameter *ru-hyoreki-stun* 34 "氷礫 HYOREKI: its stagger, frames (26 + 8; new 2026-10-24, the user, §4.4).")
;; (each burst crossfades 3 f out of the link it follows, :blend 3: a look, DUEL_RUKIA_TYBW §13.8)
(defmove :ru-shimochiri :kind :sig :clip :ru-s-shimochiri :blend 3 :callout "SHIMO-CHIRI" :startup *ru-burst-j-s* :active 3 :recovery 22
  :dmg 20 :adv-block -10 :reach 2.0 :arc 360 :on-hit :flinch :on-frame ((0 rukia-burst-arm))
  :params (:burst 1 :per 20 :fx :hop :opener :q))                               ; J1 + L 霜散: an ice spray, the hop back
(defmove :ru-setsuen :kind :sig :clip :ru-s-setsuen :blend 3 :callout "SETSUEN" :startup *ru-burst-j-s* :active 3 :recovery 22
  :dmg 20 :adv-block -10 :reach 2.0 :arc 360 :on-hit :flinch :on-frame ((0 rukia-burst-arm))
  :params (:burst 2 :per 20 :fx :refund :opener :q))                            ; J2 + L 雪煙: a mist burst, Reiatsu back
(defmove :ru-sojin :kind :sig :clip :ru-s-sojin :blend 3 :callout "SOJIN" :startup *ru-burst-j-s* :active 3 :recovery 22
  :dmg 20 :adv-block -10 :reach 2.0 :arc 360 :on-hit :flinch :on-frame ((0 rukia-burst-arm))
  :params (:burst 3 :per 20 :fx :circle :opener :q))                            ; J3 + L 霜陣: the shards lie as a frost circle
(defmove :ru-hyoreki :kind :sig :clip :ru-s-hyoreki :blend 3 :callout "HYOREKI" :startup *ru-burst-k-s* :active 4 :recovery 26
  :dmg 30 :adv-block -14 :vol (:cap 0.2 2.8 1.1 0.3) :on-hit :stagger :on-frame ((0 rukia-burst-arm))
  :hits ((12 16 :stun *ru-hyoreki-stun*)) :params (:burst 1 :per 30 :opener :f))   ; K1 + L 氷礫: the shard hits again
(defmove :ru-tsurara :kind :sig :clip :ru-s-tsurara :blend 3 :callout "TSURARA" :startup *ru-burst-k-s* :active 4 :recovery 26
  :dmg 30 :adv-block -14 :reach 2.8 :arc 160 :on-hit :stagger :on-frame ((0 rukia-burst-arm))
  :params (:burst 2 :per 25 :fx :push :opener :f))                              ; K2 + L 氷柱: a pillar under him, out to 6 m
(defmove :ru-hakuren-k :kind :sig :clip :ru-s-hakuren :blend 3 :callout "TSUGI NO MAI: HAKUREN" :startup *ru-burst-k-s* :active 4
  :recovery 26 :dmg 40 :adv-block -14 :vol (:cap 0.3 11.0 1.0 0.6) :on-hit :knockdown
  :on-frame ((0 rukia-burst-arm) (0 rukia-hakuren-spikes) (12 rukia-hakuren-k-wave))
  :params (:burst 3 :per 35 :fx :wave :opener :f))   ; K3 + L 次の舞・白漣 (雪崩 until the user 2026-10-24, §8): the four stabs, the 11 m wave
;; L, a tap: HADO NO YON: BYAKURAI, a straight beam from her fingers (a :ranged line 0.5 -> 6 m, 0.3 m wide), no bar; held
;; >= 12 f (RUKIA-L-HOLD at its f11, before its hit) it becomes TSUKISHIRO (the kit's non-button :hold string)
(defparameter *ru-l-hold* 12 "L held this many frames is TSUKISHIRO, fewer BYAKURAI (new 2026-10-24, the user, §4.4).")
(defmove :ru-byakurai :kind :sig :clip :ru-s-byakurai :callout "HADO NO YON: BYAKURAI" :startup 12 :active 3 :recovery 28
  :dmg 45 :adv-block -12 :guard 10 :vol (:cap 0.5 6.0 1.1 0.15) :on-hit :flinch :flags (:ranged) :tick rukia-l-hold
  :on-frame ((12 rukia-byakurai-beam)))
;; L held: SOME NO MAI: TSUKISHIRO: at f12 the point under the opponent (<= :range m, CAST-POINT) gets a white ring (the
;; tell); :delay frames later a pillar of ice erupts in it: a :bind disc, guardable from her side (:src), fragile (it
;; closes if she is hit first): :dmg + frozen :stun frames; its hit lays :layers (2; its frost 90 gone, 2026-10-24). A
;; Step (2.5 m) always clears it. No cooldown: S 12 / R 36
(defmove :ru-tsukishiro :kind :sig :clip :ru-s-tsukishiro :callout "SOME NO MAI: TSUKISHIRO" :startup 12 :active 0
  :recovery 36 :flags (:bind) :on-frame ((12 rukia-tsukishiro))   ; (no cooldown, the user 2026-09-29: S 12 / R 36 instead)
  :params (:range 8.0 :radius 1.8 :height 3.0 :delay 24 :dmg 60 :stun 36 :guard 14 :frost 0 :layers 2 :life 8 :tell (21 30)))
;; Shift+K, a tap: HADO NO SANJUSAN: SOKATSUI, blue fire from both palms (a 5 m cone, 40 deg, knockback 3 m), 1 bar; held
;; >= 16 f (RUKIA-SP1-RELEASE at the hold's end): BAKUDO NO ROKUJUICHI: RIKUJOKORO, six rods of light at him <= 6 m (the
;; ring under him at its f2, the bind 30 f later (14 -> 30, the user 2026-10-27: 「光環收束改成 30f」, DUEL_RUKIA_TYBW §17.13):
;; a :bind disc 45 f that no guard stops (the user 2026-10-24: a guarding victim is bound too, §8); it hits only on the
;; frame it shuts (:life 6 -> 1), so a Step or a Hoho out of the ring, or inside its iframes on that frame, escapes it)
(defmove :ru-sokatsui :kind :sp :clip :ru-s-kido :clip-2 :ru-s-sokatsui :callout "HADO NO SANJUSAN: SOKATSUI"
  :hold (1 16) :release rukia-sp1-release :startup 14 :active 4 :recovery 26 :dmg 90 :adv-block -16
  :reach 5.0 :arc 40 :height (0.2 1.8) :on-hit :knockback :kb 3.0 :flags (:ranged) :on-frame ((14 rukia-sokatsui-fire)))
(defparameter *ru-rikujo-max* 100
  "RIKUJOKORO: the longest bind (frames): SP1 held past its 16 f adds a frame a held frame to its 45 (:hold (0 56)), up to
this, which lasts from the bind at its farthest (6 m) until her O's Kikon follow-up lands (measured, debug 85028: her
recovery 26 + ENBU's hit 25 f after the press at 5.9 m + the follow-up 49 = 100) (the user 2026-10-24: 「長按可延長
六丈光牢的鎖定時間，最長可封鎖至毀魂技追擊打中」, DUEL_RUKIA_TYBW §10). While it seals him (FIGHTER-SEAL) a Kikon
follow-up treats him as red: no guard cancels its reel or blocks it.")
(defparameter *ru-rikujo-rate* 2
  "RIKUJOKORO: held frames per frame of bind past its 45 (1 -> 2, the user 2026-10-27: 「拉長到達蓄力上限所需要的時間（封鎖
時間跟之前的上限一樣）」: the 100 f cap now takes 111 held frames, :hold (0 111), not 56; DUEL_RUKIA_TYBW §17.13).")
(defmove :ru-rikujo :kind :sig :clip :ru-s-rikujo :clip-2 :ru-s-rikujo-cast :callout "BAKUDO NO ROKUJUICHI: RIKUJOKORO" :startup 32 :active 0
  :clip-s 16 :hold (0 111) :recovery 26 :flags (:bind) :on-frame ((2 rukia-rikujo))   ; (S 16 -> 32 = the ring's shut, its
  :params (:range 6.0 :radius 1.2 :height 2.2 :delay 30 :dmg 20 :stun 45 :guard 12 :life 1 :tell (2 32)))  ;  recovery after it)
;; Shift+L, SAN NO MAI: SHIRAFUNE: the ice blade grows off the point: a 5 m thrust (her own blade: melee), frost 150 (the
;; bands' own). The Shikai's copy: no frost, it bursts every layer: 110 + 25 a layer (alone or off any string hit)
(defmove :ru-shirafune :kind :sp :clip :ru-shirafune :callout "SAN NO MAI: SHIRAFUNE" :startup 16 :active 4 :recovery 28
  :dmg 110 :adv-block -14 :slide 1.0 :vol (:cap 0.3 5.0 1.1 0.3) :on-hit :knockback :kb 2.0 :frost 150
  :on-frame ((13 rukia-shirafune-ice)))
(defmove-copy :ru-shirafune-s :ru-shirafune :frost 0 :on-frame ((0 rukia-burst-arm) (13 rukia-shirafune-ice)) :params (:burst 3 :per 25))
(defmove :ru-breaker :kind :breaker :clip :ru-breaker :clip-2 :ru-hainawa :callout "BAKUDO NO YON: HAINAWA")
;; O, the Kikon rush module ENBU: 6 f of aura, a flash step at 24 m/s for <= 16 f (locked at take-off), then the pirouette:
;; 8.0 m, 360 deg, <= 30 f from the press; its hit lays a layer. Its Kikon is SOME NO MAI: TSUKISHIRO. Cooldown 90.
(defmove :ru-kikon :kind :kikon :clip :ru-s-enbu-run :clip-2 :ru-s-enbu :callout "SOME NO MAI: TSUKISHIRO" :cine ru-kikon-cine
  :startup 8 :active 3 :recovery 24 :dmg 70 :adv-block -14 :reach 2.4 :arc 360 :on-hit :knockback :kb 2.5 :cooldown 90
  :params (:aura 6 :aim 120.0 :speed 24.0 :dash-max 16 :dash-track 0.0 :look :flash-step :sfx :hoho-out :layers 1))

;;; ================================================================ 絶対零度 (the awakened bands, docs/duel/DUEL_RUKIA.md §4)
;; SP1 TSUGI NO MAI: HAKUREN, the bands' (the Shikai's button until 2026-10-24; the Shikai's K3 + L since): held 16-64 f,
;; one stab per 16 f (1-4, a spike each); released, the wave of cold (a :wave hazard): wider and harder per stab; a hit
;; freezes :stun frames; a side Step always clears it
(defmove :ru-hakuren :kind :sp :clip :ru-stab :clip-2 :ru-hakuren :callout "TSUGI NO MAI: HAKUREN"
  :hold (16 64) :startup 6 :active 1 :recovery 24 :tick rukia-hakuren-charge :on-frame ((6 rukia-hakuren-wave))
  :params (:speed 12.0 :range 11.0 :width 2.4 :width-per 0.4 :dmg 70 :dmg-per 20 :stun 24 :frost 120 :guard 12 :guard-per 2))
;; -18: the Shikai grid (reach x1.0) with two bare-hand / ice links of its own (the user's decision 2026-09-28): K1 TOSHU,
;; the left palm catching and freezing (a short lunge); K3 HYOKA, the palm driven into the plaza, an ice flower bursting
;; at his feet. -50 derives it (reach x1.1); zero (x1.35, rooted) swaps J2 / K1 / K3. The frames never change with the
;; band (DUEL_STRINGS §2.1): colder is longer reach, harder hits and other motions. -50's and zero's own moves name their
;; own clips (DUEL_RUKIA_TYBW §13.4: -50's key edits gone 2026-10-25)
(defmove :ru-a-k1 :kind :flash :clip :ru-palm :startup 17 :active 4 :recovery 20 :dmg 66 :adv-block -3
  :vol (:cap 0.2 2.0 1.2 0.35) :slide 0.8 :on-hit :stagger :frost 90)
(defmove :ru-a-k3 :kind :flash :clip :ru-flower :enter 7 :startup 21 :active 5 :recovery 34 :dmg 84 :adv-block -20
  :reach 2.4 :arc 160 :height (0.0 1.4) :on-hit :crumple :frost 120 :flags (:ender) :on-frame ((21 rukia-ice-flower)))
;; -50 (the links it doesn't derive are written at x1.1): palm and blade together, the pirouette two-handed, both palms down
(defmove-copy :ru-a-k1-50 :ru-a-k1 :clip :ru-50-k1 :vol (:cap 0.2 2.2 1.2 0.35))
(defmove-copy :ru-j3-50 :ru-j3 :clip :ru-50-j3 :reach 1.72)
(defmove-copy :ru-a-k3-50 :ru-a-k3 :clip :ru-50-k3 :reach 2.64)
;; absolute zero (written at x1.35): J2 the wrist flipped back (its own clip, DUEL_RUKIA_TYBW §13.4), K1 SHIMO-TSUKI's
;; reach with the ice lance (the reach she lost with her feet), K3 HYOKA with a frost that lasts
(defmove-copy :ru-z-j2 :ru-j2 :clip :ru-0-j2 :reach 1.78)
(defmove-copy :ru-z-j2s :ru-z-j2)
(defmove-copy :ru-z-k1 :ru-k1 :vol (:cap 0.2 3.78 1.1 0.3) :frost 90 :params nil)   ; (no Shikai layer)
(defmove-copy :ru-z-k3 :ru-a-k3 :reach 3.24 :frost 150)
;; L, one family that grows with the cold (the playtest fix: colder is never weaker): a disc round her, guardable
;; facing her (:src). -18 SHIMOBASHIRA, the frost pillars (r 2.5); -50 HYOSHIN, the ice quake (r 3.5, crumple); zero
;; REIDO TOKETSU (r 5.5 = the field, a 45 f freeze: a counter-hit on a Breaker's dash; it cashes the top bar)
(defmove :ru-shimobashira :kind :sig :clip :ru-18-shimobashira :callout "SHIMOBASHIRA" :startup 12 :active 0 :recovery 32
  :on-frame ((0 rukia-hyoshin-tell) (12 rukia-shimobashira))
  :params (:radius 2.5 :height 0.6 :dmg 60 :frost 90 :guard 12 :react :stagger :stun 42 :gc-from 40 :r-cancel (:q) :r-cancel-from 34))
(defmove :ru-hyoshin :kind :sig :clip :ru-50-hyoshin :callout "HYOSHIN" :startup 14 :active 0 :recovery 32
  :on-frame ((0 rukia-hyoshin-tell) (14 rukia-hyoshin))
  :params (:radius 3.5 :height 0.6 :dmg 85 :frost 120 :guard 16 :react :crumple :stun 42 :gc-from 42 :r-cancel (:q) :r-cancel-from 36))
(defmove :ru-reido :kind :sig :clip :ru-0-reido :callout "REIDO TOKETSU" :startup 10 :active 0 :recovery 36
  :on-frame ((10 rukia-reido)) :params (:radius 5.5 :height 2.2 :dmg 120 :stun 46 :frost 150 :guard 20 :gc-from 37 :r-cancel (:q) :r-cancel-from 36))
;; SP1 HAKUREN colder: -50 a stab every 12 f (hold 12-48), a faster, longer, harder wave; zero no hold: the four stabs at
;; once and the widest, hardest wave (a half-width of 1.8 m: a side Step still clears every one)
(defmove-copy :ru-hakuren-50 :ru-hakuren :hold (12 48)
  :params (:per 12 :speed 14.0 :range 12.0 :width 2.4 :width-per 0.4 :dmg 80 :dmg-per 23 :stun 30 :frost 120 :guard 12 :guard-per 2))
(defmove :ru-hakuren-0 :kind :sp :clip :ru-0-hakuren :callout "TSUGI NO MAI: HAKUREN" :startup 10 :active 1 :recovery 24
  :on-frame ((0 rukia-hakuren-spikes) (10 rukia-hakuren-wave))
  :params (:stabs 4 :speed 16.0 :range 14.0 :width 3.6 :width-per 0.0 :dmg 160 :dmg-per 0 :stun 36 :frost 150 :guard 18 :guard-per 0))
;; SP2 SHIRAFUNE colder: 5.0 m (-18) -> 6.0 m -> 7.5 m planted, crumpling
(defmove-copy :ru-shirafune-50 :ru-shirafune :dmg 125 :vol (:cap 0.3 6.0 1.1 0.3))
(defmove-copy :ru-shirafune-0 :ru-shirafune :dmg 140 :vol (:cap 0.3 7.5 1.1 0.3) :on-hit :crumple :slide 0.0)
;; O in every band, HAKKA NO TOGAME: ENJO's module shape (no dash): the blade raised (a white pillar at her, f4), then
;; levelled: the cold runs off the tip along a locked lane, 6.5 / 7.5 / 9.0 m by band. Its Kikon count never scales (3).
;; Cooldown 90 (the universal O's)
(defmove :ru-hakka :kind :kikon :clip :ru-cold-stance :clip-2 :ru-hakka :callout "HAKKA NO TOGAME" :cine ru-hakka-cine
  :startup 20 :active 3 :recovery 30 :whiff 30 :dmg 70 :adv-block -14 :track 0 :vol (:cap 0.5 7.5 1.2 1.2)
  :on-hit :knockback :kb 2.0 :frost 120 :cooldown 90 :on-frame ((4 rukia-hakka-pillar) (20 rukia-hakka-sheet))
  :params (:aura 8 :aim 120.0 :speed 0.0 :dash-max 0 :dash-track 0.0 :look :lane))
(defmove-copy :ru-hakka-18 :ru-hakka :vol (:cap 0.5 6.5 1.2 1.2))
(defmove-copy :ru-hakka-0 :ru-hakka :vol (:cap 0.5 9.0 1.2 1.2))

;;; ================================================================ forms
;; The Shikai's own clips (rukia-art.lisp, DUEL_RUKIA_TYBW §13.3; a look, the user 2026-10-24 「可以，先做始解」): its moves'
;; through the :base kit's :clip-map, the walk through :look-clips, the run set; the bands set their own (*RU-18-CLIPS*,
;; *RU-50-CLIPS*, *RU-0-CLIPS*)
(defparameter *ru-shikai-clips* '(:ru-q1 :ru-s-j1 :ru-q2 :ru-s-j2 :ru-spin :ru-s-j3 :ru-thrust :ru-s-k1 :ru-ring :ru-s-k2
                                  :ru-drop :ru-s-k3 :ru-shirafune :ru-s-shirafune :ru-breaker :ru-s-breaker
                                  :ru-hainawa :ru-s-hainawa)
  "The Shikai's :clip-map: J1-J3, K1-K3 (K2 / K2s), SP2 SHIRAFUNE, the Breaker HAINAWA on their own clips (ENBU names its own).")
(defparameter *ru-shikai-looks* '(:sh-walk-f :ru-s-walk-f :sh-walk-b :ru-s-walk-b :sh-strafe-r :ru-s-strafe-r
                                  :sh-strafe-l :ru-s-strafe-l)
  "The Shikai's :look-clips: the walk 摺り足 under her stance's arms.")
(defkit :rukia :base
  :name "RUKIA" :body :rukia :weapon :sode-no-shirayuki :stance :ru-s-stance :hide (:ice-trim :hand-crack)
  :clip-map *ru-shikai-clips* :look-clips *ru-shikai-looks* :run-clips (:ru-s-run :sh-skate-b :sh-slide-r :sh-slide-l)
  :intro :ru-intro :win :ru-win :intro-callout "MAE, SODE NO SHIRAYUKI" :intro-weapon (:ru-katana 70)
  :walk *walk-rukia* :run *run-rukia* :reishi *reishi-max* :swing-sfx :whoosh-light :mult *rukia-mult* :taken *rukia-taken*
  :stun-tolerance 13.0                          ; the hidden stun (DUEL_DESIGN.md): light, blown away sooner
  :commands (:q :ru-j1 :f :ru-k1 :sig :ru-byakurai :sp1 :ru-sokatsui :sp2 :ru-shirafune-s :breaker :ru-breaker :kikon :ru-kikon)
  :grid (:ru-j1 :ru-j2 :ru-j3 :ru-k1 :ru-sk2 :ru-k3 :ru-j2s :ru-sk2s)
  :strings ((:ru-byakurai :hold :ru-tsukishiro) (:ru-sokatsui :hold :ru-rikujo))   ; the held L / SP1 (RUKIA-L-HOLD, -SP1-RELEASE)
  ;; the six bursts (DUEL_RUKIA_TYBW §4.3): L after each J / K link that hit, >= 1 layer on him (RUKIA-OK)
  :l-after-j (:ru-j1 :ru-shimochiri :ru-j2 :ru-setsuen :ru-j2s :ru-setsuen :ru-j3 :ru-sojin)
  :l-after-k (:ru-k1 :ru-hyoreki :ru-sk2 :ru-tsurara :ru-sk2s :ru-tsurara :ru-k3 :ru-hakuren-k)
  :awaken-form :m18
  :hooks (:boss rukia-boss :hit rukia-hit :ok rukia-ok)   ; the DANGAI boss (rukia-meter.lisp); the layers; the bursts' price
  ;; 遠近各半 (§4.1): J up close, the bursts off J / K hits with layers on him (RUKIA-AI-BURST-P), BYAKURAI at 3-6 m and
  ;; TSUKISHIRO held beyond (RUKIA-AI-SIG-HOLD), SOKATSUI tapped / RIKUJOKORO held (RUKIA-AI-SP1-HOLD), SHIRAFUNE on a
  ;; frozen / staggered victim (:stun-follow) and at >= 2 layers (RUKIA-AI-ZONE); she awakens only against a melee
  ;; opponent (:awaken: >= 60 % of >= 150 taken from blades)
  :ai *ru-ai-base*)

;; -18's own clips (rukia-art.lisp, DUEL_RUKIA_TYBW §13.4; a look, the user 2026-10-24): its moves' through the :m18 kit's
;; :clip-map (SHIMOBASHIRA names its own: SP1's hold shares its old clip), the walk through :look-clips, the run set; -50
;; and zero set their own (*RU-50-CLIPS*, *RU-0-CLIPS*)
(defparameter *ru-18-clips* '(:ru-q1 :ru-18-j1 :ru-q2 :ru-18-j2 :ru-spin :ru-18-j3 :ru-palm :ru-18-k1 :ru-ring :ru-18-k2
                              :ru-flower :ru-18-k3 :ru-stab :ru-18-hakuren-hold :ru-hakuren :ru-18-hakuren
                              :ru-shirafune :ru-18-shirafune :ru-cold-stance :ru-18-stance :ru-hakka :ru-18-hakka
                              :ru-hainawa :ru-18-hainawa)
  "-18's :clip-map: J1-J3 (J2s), K1-K3 (K2s), SP1 HAKUREN's hold and release, SP2 SHIRAFUNE, O HAKKA (its aura and its
strike), the Breaker HAINAWA's strike on its own clips.")
(defparameter *ru-18-looks* '(:sh-walk-f :ru-18-walk-f :sh-walk-b :ru-18-walk-b :sh-strafe-r :ru-18-strafe-r
                              :sh-strafe-l :ru-18-strafe-l)
  "-18's :look-clips: the walk 摺り足 under her stance's arms (the palm held out).")
;; -50's own clips (rukia-art.lisp, DUEL_RUKIA_TYBW §13.4; a look, the user 2026-10-25): the quake (足拍子 J, both palms K,
;; the rime blade two-handed), its moves' through the :m50 kit's :clip-map, the walk through :look-clips, the run set
(defparameter *ru-50-clips* '(:ru-q1 :ru-50-j1 :ru-q2 :ru-50-j2 :ru-ring :ru-50-k2 :ru-stab :ru-50-hakuren-hold
                              :ru-hakuren :ru-50-hakuren :ru-shirafune :ru-50-shirafune :ru-cold-stance :ru-50-stance
                              :ru-hakka :ru-50-hakka :ru-hainawa :ru-50-hainawa)
  "-50's :clip-map: J1 / J2 (J2s), K2 (K2s), SP1 HAKUREN's hold and release, SP2 SHIRAFUNE, O HAKKA (its aura and its
strike), the Breaker HAINAWA's strike on its own clips (J3, K1, K3 and HYOSHIN, its own moves, name theirs).")
(defparameter *ru-50-looks* '(:sh-walk-f :ru-50-walk-f :sh-walk-b :ru-50-walk-b :sh-strafe-r :ru-50-strafe-r
                              :sh-strafe-l :ru-50-strafe-l)
  "-50's :look-clips: the heavy walk under her two-hand guard.")
;; -273's own clips (rukia-art.lisp, DUEL_RUKIA_TYBW §13.4; a look, the user 2026-10-25): rooted (扇の手 J, サシ / 袖 K, the
;; feet never move), its shared moves' through the :zero kit's :clip-map, its idle the stance (and O's aura); J2, REIDO and
;; HAKUREN name their own
(defparameter *ru-0-clips* '(:ru-q1 :ru-0-j1 :ru-spin :ru-0-j3 :ru-thrust :ru-0-k1 :ru-ring :ru-0-k2 :ru-flower :ru-0-k3
                             :ru-shirafune :ru-0-shirafune :ru-cold-stance :ru-0-stance :ru-hakka :ru-0-hakka)
  "-273's :clip-map: J1 / J3, K1-K3 (K2s), SP2 SHIRAFUNE, O HAKKA (its aura and its strike) on its own clips.")
;;; -18 C, the awakening's first band: the Shikai grid (+ TOSHU / HYOKA), frost on every hit, no chip on her; U guards
;;; and cools (the cold gauge, the kit meter); only L spends cold here (the user's decision 2026-09-28)
(defkit :rukia :m18 :inherit :base
  :awakening t :form-name "-18C" :walk *walk-m18* :run *run-m18* :passives (:chipless) :frost-touch *frost-touch*
  :mult *rukia-awake-mult* :taken *rukia-awake-taken*
  :meter (:name "COLD" :max *cold-max* :temp t :draw rukia-hud-meter :label temp-label) :warm *ru-warm-m18* :cold *ru-cold-m18* :field *ru-field-m18*
  :reset-form :m18 :u-tag "U: COOL" :hooks (:hoho rukia-hoho-cold :tick rukia-tick :reset rukia-reset)   ; (rukia-meter.lisp)
  :stance :ru-18-stance :aura rukia-aura-cold :cine ru-awaken-cine :swing-sfx :whoosh-light
  :clip-map *ru-18-clips* :look-clips *ru-18-looks* :run-clips (:ru-18-run :sh-skate-b :sh-slide-r :sh-slide-l)
  ;; (every command pinned: the Shikai's L / SP1 / SP2 and its bursts are its own since 2026-10-24, DUEL_RUKIA_TYBW §2)
  :commands (:q :ru-j1 :f :ru-a-k1 :sig :ru-shimobashira :sp1 :ru-hakuren :sp2 :ru-shirafune :breaker :ru-breaker :kikon :ru-hakka-18)
  :grid (:ru-j1 :ru-j2 :ru-j3 :ru-a-k1 :ru-k2 :ru-a-k3 :ru-j2s :ru-k2s)
  :l-after-k t                                  ; L after a K link: the band's own L (S 10-14: a combo as it is)
  :l-after-j nil                                ; (none after a J link: the Shikai's bursts are not the bands')
  :ai *ru-ai-m18*)

;;; -50 C: slower, hardened, reach x1.1, the rime blade, HYOSHIN for L; every action spends cold now; the whole bar 1
;;; spent (C 0) warms her back to -18, both bars full is absolute zero
(defkit :rukia :m50 :inherit :m18
  :reach-mult 1.1 :form-name "-50C" :walk *walk-m50* :run *run-m50* :mult *rukia-m50-mult* :taken *rukia-m50-taken*
  :frost-touch *frost-touch-m50* :warm *ru-warm-m50* :cold *ru-cold-m50* :field *ru-field-m50*
  :weapon :ru-rime :hide (:hand-crack) :aura rukia-aura-frost
  :stance :ru-50-stance :clip-map *ru-50-clips* :look-clips *ru-50-looks* :run-clips (:ru-50-run :sh-skate-b :sh-slide-r :sh-slide-l)
  :commands (:f :ru-a-k1-50 :sig :ru-hyoshin :sp1 :ru-hakuren-50 :sp2 :ru-shirafune-50 :kikon :ru-hakka)
  :grid (:ru-j1 :ru-j2 :ru-j3-50 :ru-a-k1-50 :ru-k2 :ru-a-k3-50 :ru-j2s :ru-k2s)
  :ai *ru-ai-m50*)

;;; -273.15 C, absolute zero (both bars full): rooted (no walk, run, Step, Hoho, slide or chase: the user's decision), the
;;; strongest version of every button at reach x1.35 with the ice blade, the largest field; the ward (360 deg, no
;;; blockstun, never refills) whose first melee hit freezes its attacker; ranged hits are guarded too (no optic since the
;;; user 2026-09-30); U braces
;;; (stops the warming, drains the guard gauge). No chosen exit: she leaves by spending the top bar, by warming, or by
;;; the CRACK (the ward crushed or broken: RUKIA-CRACK)
(defkit :rukia :zero :inherit :m18
  :reach-mult 1.35 :form-name "-273C" :walk 0.0 :run 0.0 :rooted t :mult *rukia-zero-mult* :taken *rukia-zero-taken*
  :passives (:ward :freeze-touch :chipless) :frost-touch *frost-touch-zero* :warm *ru-warm-zero* :cold *ru-cold-zero*
  :field *ru-field-zero* :crush-hook rukia-crack :u-tag "U: BRACE"
  :body :rukia-zero :weapon :ru-ice :hide (:ice-trim :hand-crack) :stance :ru-0-stance :aura rukia-aura-zero
  :enter-hook rukia-zero-enter :calm t                ; the white Rukia's face stays composed (never the shout)
  :clip-map *ru-0-clips* :look-clips nil :run-clips (:sh-run :sh-skate-b :sh-slide-r :sh-slide-l)   ; (no walk or run: rooted)
  :commands (:f :ru-z-k1 :sig :ru-reido :sp1 :ru-hakuren-0 :sp2 :ru-shirafune-0 :kikon :ru-hakka-0 :breaker nil)
  :grid (:ru-j1 :ru-z-j2 :ru-j3 :ru-z-k1 :ru-k2 :ru-z-k3 :ru-z-j2s :ru-k2s)
  ;; it can't move: answers within its reach (J to 2.1 m, K to 3.4, K1 3.8, REIDO 5.5, SHIRAFUNE 7.5, HAKUREN's wave to 14),
  ;; braces now and then while he is near and the guard gauge can pay; a CPU facing her backs off and waits it out (:opp-intent)
  :ai *ru-ai-zero*)

;;; ================================================================ hooks (called through the data's symbols)
(defun rukia-snow-burst (e)
  "NADARE f21: snow bursts from the plaza at the point (a look)."
  (multiple-value-bind (x z) (ahead e 2.4) (spawn-look e 'rukia-burst-look :x x :z z :size 1.0 :life 24))
  (emit :sfx :ice-shatter e))

(defun rukia-tsukishiro (e)
  "TSUKISHIRO f10: the point under the opponent (CAST-POINT, <= :range m); its white ring now (the tell), the pillar
:delay frames later: a :freeze disc (:radius x :height; guardable facing her: :src; it closes if she is hit first: :fragile)."
  (let* ((p (pos-of e)) (q (pos-of (opp-of e))) (r (move-param e :radius)) (d (1+ (move-param e :delay))))
    (multiple-value-bind (x z) (cast-point (aref p 0) (aref p 2) (aref q 0) (aref q 2) (move-param e :range))
      (spawn-hazard :freeze e :x x :z z :size r :y (move-param e :height) :delay d :life (move-param e :life) :src t :fragile t
                            :data (move-param e :layers)        ; (its hit's 霜の層: RUKIA-HIT)
                            :hw (make-hitwin :dmg (move-param e :dmg) :react :bind :stun (move-param e :stun) :hs *hitstop-heavy*
                                             :guard (move-param e :guard) :frost (move-param e :frost) :flags '(:ice)))
      (spawn-look e 'rukia-ring-look :x x :z z :size r :delay d :life 36 :fragile t)))
  (emit :sfx :frost-tick e))

;;; ---------------------------------------------------------------- 霜の層 and the Shikai's new moves (DUEL_RUKIA_TYBW §4.4)
(defun rukia-layers+ (v n)
  "N more 霜の層 on fighter V (capped: rules LAYERS-ADD), his thaw timer back to 0."
  (let ((f (fighter v))) (setf (fighter-layers f) (layers-add (fighter-layers f) n) (fighter-thaw f) 0)))

(defun rukia-chill+ (v n)
  "N more 冰凍值 points on fighter V (two make a layer: rules CHILL-ADD), his thaw timer back to 0."
  (let ((f (fighter v)))
    (multiple-value-bind (l c) (chill-add (fighter-layers f) (fighter-chill f) n)
      (setf (fighter-layers f) l (fighter-chill f) c (fighter-thaw f) 0))))

(defun rukia-ok (e cmd combo)
  "The Shikai's :ok hook: a burst (COMBO, an L link with :burst) only with >= 1 layer on him and off a link that hit
(pressed before the link's contact it waits for the chain, refused there on a block or with no layer): with 0 layers
the L is not taken and the string ends at that link (no 0-resource loop). Every other command: yes."
  (declare (ignore cmd))
  (or (null combo) (null (getf (mv-params combo) :burst))
      (layer-burst-ok-p (fighter-contact (fighter e)) (fighter-layers (fighter (opp-of e))))))

(defun rukia-burst-arm (e)
  "A burst's f0 (the six L links, SP2): the layers it will burst now (rules BURST-COUNT of its :burst link) as its damage
bonus, :per each (the hit bursts them: RUKIA-HIT)."
  (let ((f (fighter e)))
    (setf (fighter-dmg-bonus f)
          (* (move-param e :per) (burst-count (move-param e :burst) (fighter-layers (fighter (opp-of e))))))))

(defun rukia-burst! (att def mv n)
  "Burst move MV of ATT hit DEF bursting N layers: they go (RUKIA-BURST-ARM counted them), the shards fly, and its
benefit (:fx): :hop she hops back *RU-HOP*, :refund Reiatsu *RU-REFUND* a bar a layer, :circle the frost circle 霜陣
round her (*RU-SOJIN*), :push he is pushed out to *RU-TSURARA-TO*, :wave 白漣's look runs out (RUKIA-HAKUREN-K-WAVE).
Every burst leaves him out of its route's opener's reach (RUKIA-BURST-OUT: J1's after a J link, K1's after a K link; the
user 2026-10-24, DUEL_RUKIA_TYBW §9): the hop, the pillar's push and the knockdown already do; the rest are pushed."
  (let* ((fd (fighter def)) (p (pos-of att)) (q (pos-of def))
         (dx (- (aref q 0) (aref p 0))) (dz (- (aref q 2) (aref p 2))) (d (hypot dx dz)))
    (setf (fighter-layers fd) (max 0 (- (fighter-layers fd) n)))
    (pace att (mv-name mv)) (pace att :layers-burst n)
    (when (plusp n)
      (spawn-look att 'rukia-burst-look :x (aref q 0) :z (aref q 2) :size (+ 0.6 (* 0.4 n)) :life 24)
      (emit :sfx :ice-shatter att))
    (case (getf (mv-params mv) :fx)
      (:hop (set-slide att *ru-hop* 10 (- dx) (- dz)))
      (:refund (reiatsu-gain! att (* n *ru-refund* *reiatsu-bar*)))
      (:circle (let ((to (/ (max d (rukia-burst-out att def mv)) (max 1e-4 d))))   ; (where the burst's push leaves him)
                 (spawn-hazard :fx att :x (+ (aref p 0) (* dx to)) :z (+ (aref p 2) (* dz to)) :size (getf *ru-sojin* :r)
                                       :life (getf *ru-sojin* :life) :look 'rukia-sojin-look :hook 'rukia-sojin-step :data (list 0))))
      (:push (push-apart att def (max 0.0 (- *ru-tsurara-to* d)) 12)))
    (unless (or (null (getf (mv-params mv) :opener))   ; (SP2 SHIRAFUNE bursts too, but it ends no string: its own knockback)
                (member (getf (mv-params mv) :fx) '(:hop :push :wave)))   ; (their own move leaves him farther: no second slide)
      (let ((push (- (rukia-burst-out att def mv) d)))
        (when (plusp push) (push-apart att def push *ender-push-frames*))))
    (clog "~a BURST ~a ~d layers" (side-name att) (mv-name mv) n)))

(defun rukia-burst-out (att def mv)
  "How far burst MV of ATT must leave DEF: out of its route's opener's reach (its :opener, :q J1 / :f K1: its far edge,
MOVE-EDGE, §15), as a J3 / K3 ender's push is (fighter.lisp ENDER-PUSH): the opener's reach + its lunge + DEF's body + *ENDER-PUSH* (the user
2026-10-24: 「J/K+L 收尾記得都要至少退出到 J1 或 K1 的攻擊範圍之外」, by route)."
  (let ((op (kit-command-move (fighter-kit (fighter att)) (getf (mv-params mv) :opener) att)))
    (+ (move-edge op) (mv-slide op) (body-hurt-r (model-body (model def))) *ender-push*)))

(defun rukia-hit (att def res hw mv hazard ranged)
  "The Shikai's :hit hook (霜の層 on him, DUEL_RUKIA_TYBW §4.4): a real hit of a move with :layers (the K links, ENBU) or a
hazard carrying them (TSUKISHIRO's pillar: 2) adds them; a J link's holds his thaw; a burst's bursts what it counted.
The bands have no :hit hook: their moves neither add nor burst layers."
  (declare (ignore hw ranged))
  (when (and *combat-log* (member res '(:hit :counter)))   ; (the combat log only: tools/aieval.py's signature themes,
    (let ((tag (cond ((and mv (eq (mv-kind mv) :kikon) (plusp (fighter-seal (fighter def)))) "seal")   ;  DUEL_RUKIA_TYBW §17.4)
                     ((eq (gauges-burst (gauges att)) :orange) "orange")
                     ((and hazard (integerp (hazard-data hazard))) "tsukishiro")
                     ((and hazard (consp (hazard-data hazard))) "rikujo"))))
      (when tag (clog "~a ru-sig ~a" (side-name att) tag))))
  (when (member res '(:hit :counter))
    (cond (hazard (let ((n (hazard-data hazard)))
                    (cond ((integerp n) (rukia-layers+ def n) (pace att :layers-laid n))
                          ((consp n) (setf (fighter-seal (fighter def)) (getf n :seal 0))))))   ; RIKUJOKORO's seal
          ((null mv))
          ((getf (mv-params mv) :burst)
           (rukia-burst! att def mv (floor (fighter-dmg-bonus (fighter att)) (getf (mv-params mv) :per))))
          ((getf (mv-params mv) :layers) (rukia-layers+ def (getf (mv-params mv) :layers)) (pace att :layers-laid (getf (mv-params mv) :layers)))
          ((getf (mv-params mv) :chill) (rukia-chill+ def (getf (mv-params mv) :chill)) (pace att :chill-laid (getf (mv-params mv) :chill)))
          ((eq (mv-kind mv) :quick) (setf (fighter-thaw (fighter def)) 0)))))

(defun rukia-sojin-step (h hz event &rest args)
  "霜陣's circle (a look's hazard hook, each step): while he stands inside its radius, a 冰凍值 point every :per frames there."
  (declare (ignore h args))
  (when (eq event :step)
    (let ((v (hazard-target hz)) (c (hazard-data hz)))
      (when (and v (entity-alive-p v))
        (let ((q (pos-of v)) (r (hazard-size hz)))
          (when (and (< (+ (expt (- (aref q 0) (hazard-x hz)) 2) (expt (- (aref q 2) (hazard-z hz)) 2)) (* r r))
                     (zerop (mod (incf (car c)) (getf *ru-sojin* :per))))
            (rukia-chill+ v 1)
            (pace (hazard-owner hz) :sojin-chill)
            (emit :sfx :frost-tick v))))))
  nil)

(defun rukia-drift (h hz event &rest args)
  "A look that runs along its yaw at its :speed (the :fx kind stands still): K3 + L 白漣's wave."
  (declare (ignore h args))
  (when (eq event :step)
    (let ((d (* (hazard-speed hz) +step+)))
      (setf (hazard-x hz) (f32 (+ (hazard-x hz) (* d (fwd-x (hazard-yaw hz)))))
            (hazard-z hz) (f32 (+ (hazard-z hz) (* d (fwd-z (hazard-yaw hz))))))))
  nil)

(defun rukia-hakuren-k-wave (e)
  "K3 + L 白漣 at its hit frame: the four stabs' full wave runs out 11 m along her facing (a look; the hit is the move's line)."
  (multiple-value-bind (x z) (ahead e 0.8)
    (spawn-hazard :fx e :x x :z z :yaw (yaw-of e) :speed 18.0 :size 1.8 :life 37 :look 'rukia-wave-look :hook 'rukia-drift))
  (emit :sfx :ice-rise e))

(defun rukia-l-hold (e)
  "BYAKURAI's :tick: L still held at its frame *RU-L-HOLD* - 1 (before its hit): the hold's move instead (the kit's :hold
string: TSUKISHIRO), from its frame 0."
  (let ((f (fighter e)))
    (when (and (= (fighter-sf f) (1- *ru-l-hold*)) (fighter-button f) (vpad-down (pilot-vpad (pilot e)) (fighter-button f)))
      (let ((mv (kit-next (fighter-kit f) (mv-name (fighter-move f)) :hold)))
        (when mv (pace e :l-held) (start-move e mv (fighter-button f)))))))

(defun rukia-sp1-release (e)
  "SOKATSUI's :release: held to the end of its hold (16 f), the hold's move instead (RIKUJOKORO); let go sooner, SOKATSUI."
  (let* ((f (fighter e)) (mv (fighter-move f)))
    (if (>= (fighter-hold f) (second (mv-hold mv)))
        (let ((h (kit-next (fighter-kit f) (mv-name mv) :hold))) (when h (pace e :sp1-held) (start-move e h (fighter-button f))))
        (pace e :sp1-tap))))

(defun rukia-byakurai-beam (e)
  "BYAKURAI f12: the white lightning from her fingers along the line (a look; the hit is the move's line)."
  (pace e :byakurai)
  (spawn-look e 'rukia-beam-look :yaw (yaw-of e) :size (mv-reach (fighter-move (fighter e))) :life 12)
  (emit :sfx :kikon-slash e))

(defun rukia-sokatsui-fire (e)
  "SOKATSUI f14: blue fire out of both palms over the cone (a look; the hit is the move's cone)."
  (spawn-look e 'rukia-fire-look :yaw (yaw-of e) :size (mv-reach (fighter-move (fighter e))) :life 20)
  (emit :sfx :whoosh-heavy e))

(defun rukia-rikujo (e)
  "RIKUJOKORO f2: the point under him (<= :range m) marked by six rods' light (the tell), the bind :delay frames later: a
:freeze disc (:radius x :height), :dmg and a :bind of :stun frames that no guard stops (:unguardable: the user 2026-10-24;
a Step or a Hoho out of the ring escapes it)."
  (let* ((p (pos-of e)) (q (pos-of (opp-of e))) (r (move-param e :radius)) (d (1+ (move-param e :delay))))
    (multiple-value-bind (x z) (cast-point (aref p 0) (aref p 2) (aref q 0) (aref q 2) (move-param e :range))
      (let ((stun (min *ru-rikujo-max* (+ (move-param e :stun)                                    ; (held longer: a frame
                                          (floor (max 0 (1- (fighter-charge (fighter e)))) *ru-rikujo-rate*)))))   ;  a RATE)
        (spawn-hazard :freeze e :x x :z z :size r :y (move-param e :height) :delay d :life (move-param e :life) :src t
                              :data (list :seal stun)
                              :hw (make-hitwin :dmg (move-param e :dmg) :react :bind :stun stun :hs *hitstop-heavy*
                                               :guard (move-param e :guard) :flags '(:unguardable)))
        (spawn-look e 'rukia-rods-look :x x :z z :size r :delay d :life (+ stun 12)   ; (the rods stay while he is bound:
                    :data (list (opp-of e) stun nil nil)))))                     ;  the user 2026-10-24, §12)
  (emit :sfx :frost-tick e))

(defun rukia-acc-line ()
  "After a gate row: a \"duel rukia\" line per side that played her (the Shikai's pacing log: bursts by name, layers laid /
burst, the 霜陣 layers, the held / tapped L and SP1, BYAKURAI's beams, the CPU's burst picks)."
  (dolist (e (list *p1* *p2*))
    (when (and (entity-alive-p e) (eq (fighter-character (fighter e)) :rukia) (svref *pacing* (fighter-side (fighter e))))
      (log-msg "duel rukia ~a seed ~d ~{~(~a~) ~a~^ ~}" (side-name e) *match-seed* (svref *pacing* (fighter-side (fighter e)))))))

(defun rukia-spike (e i)
  "HAKUREN's stab I (0-3): an ice spike in a half circle before her."
  (let* ((a (+ (yaw-of e) (deg (- 45 (* 30 i))))) (p (pos-of e)))
    (spawn-look e 'rukia-spike-look :x (+ (aref p 0) (* 1.1 (fwd-x a))) :z (+ (aref p 2) (* 1.1 (fwd-z a)))
                                    :size (+ 0.5 (* 0.1 i)) :life 70)))

(defun rukia-hakuren-charge (e)
  "HAKUREN's hold: a stab into the plaza every :per f (16; -50: 12), 1-4 of them, an ice spike at each."
  (let* ((f (fighter e)) (h (fighter-hold f)) (per (or (move-param e :per) 16)))
    (when (and (plusp h) (zerop (mod h per)) (<= h (* 4 per)))
      (rukia-spike e (1- (floor h per)))
      (emit :sfx :frost-tick e))))

(defun rukia-hakuren-spikes (e)
  "Zero's HAKUREN f0: the four stabs at once."
  (dotimes (i 4) (rukia-spike e i))
  (emit :sfx :frost-tick e))

(defun rukia-stabs (e)
  "HAKUREN's stabs (1-4): the move's :stabs (zero: 4), else one per :per f of the charge (FIGHTER-CHARGE, set when it
was released)."
  (or (move-param e :stabs) (max 1 (min 4 (floor (fighter-charge (fighter e)) (or (move-param e :per) 16))))))

(defun rukia-hakuren-wave (e)
  "HAKUREN f6: the wave of cold leaves the blade: a :wave hazard :speed m/s over :range m, :width + :width-per per stab
wide (a half-width <= 1.8 m: a side Step clears it), :dmg + :dmg-per per stab; a hit freezes :stun frames, frost."
  (let* ((n (1- (rukia-stabs e))) (speed (move-param e :speed)) (w (+ (move-param e :width) (* n (move-param e :width-per)))))
    (multiple-value-bind (x z) (ahead e 1.0)
      (spawn-hazard :wave e :x x :z z :yaw (yaw-of e) :speed speed :size (* 0.5 w)
                            :life (round (* 60 (/ (move-param e :range) speed))) :look 'rukia-wave-look
                            :hw (make-hitwin :dmg (+ (move-param e :dmg) (* n (move-param e :dmg-per))) :react :bind
                                             :stun (move-param e :stun) :hs *hitstop-heavy* :frost (move-param e :frost)
                                             :guard (+ (move-param e :guard) (* n (move-param e :guard-per))) :flags '(:ice))))
    (emit :sfx :ice-rise e)))

(defun rukia-shirafune-ice (e)
  "SHIRAFUNE f13: the ice grows off the point along the thrust (a look; the hit is the move's line)."
  (spawn-look e 'rukia-blade-look :yaw (yaw-of e) :size (mv-reach (fighter-move (fighter e))) :life 20)
  (emit :sfx :freeze e))

(defun rukia-ice-flower (e)
  "HYOKA f21: the ice flower bursts at his feet, larger the colder she is (its size follows the link's reach; a look,
the hit is the move's arc)."
  (let ((k (/ (mv-reach (fighter-move (fighter e))) 2.7)))
    (multiple-value-bind (x z) (ahead e (* 1.9 k)) (spawn-look e 'rukia-flower-look :x x :z z :size (* 1.1 k k) :life 40)))
  (emit :sfx :ice-shatter e))

(defun rukia-hyoshin-tell (e)
  "HYOSHIN f0: the blade driven into the plaza, frost cracks radiating (the tell), then the quake at f14 (one look)."
  (spawn-look e 'rukia-quake-look :size (move-param e :radius) :delay 15 :life 30)
  (emit :sfx :frost-tick e))

(defun rukia-disc (e r h hw)
  "A disc hit round E (radius R, height H) this frame: a :freeze hazard from her position (guardable facing her)."
  (let ((p (pos-of e)))
    (spawn-hazard :freeze e :x (aref p 0) :z (aref p 2) :size r :y h :life 2 :src t :hw hw)))

(defun rukia-hyoshin (e)
  "HYOSHIN f14 (and SHIMOBASHIRA's disc): the ice quake: a disc round her, the move's :react + frost."
  (rukia-disc e (move-param e :radius) (move-param e :height)
              (make-hitwin :dmg (move-param e :dmg) :react (move-param e :react) :stun (move-param e :stun) :kb 1.0 :hs *hitstop-heavy*
                           :guard (move-param e :guard) :frost (move-param e :frost) :flags '(:ice)))
  (emit :sfx :ground-crack e))

(defun rukia-shimobashira (e)
  "SHIMOBASHIRA f12: frost pillars stand up in a ring round her (six spikes, a look) and the disc hits (HYOSHIN's)."
  (let ((p (pos-of e)) (r (* 0.8 (move-param e :radius))))
    (dotimes (i 6)
      (let ((a (+ (yaw-of e) (* i 1.0472))))
        (spawn-look e 'rukia-spike-look :x (+ (aref p 0) (* r (fwd-x a))) :z (+ (aref p 2) (* r (fwd-z a))) :size 0.7 :life 40))))
  (rukia-hyoshin e))

(defun rukia-reido (e)
  "REIDO TOKETSU f10: a disc round her (5.5 m, the field's radius) freezes :stun frames; the plaza whitens to its edge.
Its cold (the whole top bar) drops her to -50 once she is free."
  (rukia-disc e (move-param e :radius) (move-param e :height)
              (make-hitwin :dmg (move-param e :dmg) :react :bind :stun (move-param e :stun) :hs *hitstop-heavy*
                           :guard (move-param e :guard) :frost (move-param e :frost) :flags '(:ice)))
  (spawn-look e 'rukia-burst-look :size (move-param e :radius) :life 30)
  (emit :sfx :freeze e))

(defun rukia-hakka-pillar (e)
  "HAKKA f4: a white pillar of cold rises at her (a look)."
  (spawn-look e 'rukia-pillar-look :size 0.9 :life 40)
  (emit :sfx :ice-rise e))

(defun rukia-hakka-sheet (e)
  "HAKKA f20: the cold runs off the tip along the lane (a look; the hit is the move's lane)."
  (spawn-look e 'rukia-sheet-look :yaw (yaw-of e) :size (mv-reach (fighter-move (fighter e))) :life 34)
  (emit :sfx :kikon-slash e))

(defparameter *ru-hoho-cold* 50.0 "Cold a Hoho adds when she reappears behind him (-18 / -50; the user 2026-09-30: dive in and freeze).")

(defun rukia-hoho-cold (e)
  "The awakened bands' :hoho hook (the user 2026-09-30, 「Hoho 可以增加冷度量表」): reappearing behind him adds
*RU-HOHO-COLD*, and the band follows at once (TEMP-BAND; the steps' own resolve waits until she is free and warms her
first, so a Hoho to exactly 200 would never reach zero): she lands next to him at -273, the ward up (RUKIA-ZERO-ENTER).
Not in the THAW after a CRACK."
  (let* ((g (gauges e)) (f (fighter e)) (c (min *cold-max* (+ (gauges-meter g) *ru-hoho-cold*))) (band (temp-band c (fighter-form f))))
    (when (plusp (gauges-meter-idle g)) (return-from rukia-hoho-cold))   ; the THAW: nothing cools her
    (setf (gauges-meter g) (f32 c))
    (unless (eq band (fighter-form f))
      (set-form e band)
      (emit :sfx :frost-tick e))))

(defun rukia-zero-enter (e)
  "Absolute zero (:zero's :enter-hook): entered from a held guard or a Hoho's arrival, the ward is up at once (no hole); a new visit's
freeze-touch; the white burst."
  (let ((f (fighter e)))
    (when (member (fighter-state f) '(:guard :guard-hit :hoho)) (setf (fighter-guard-t f) *guard-raise*))   ; (a Hoho: RUKIA-HOHO-COLD)
    (setf (gauges-froze (gauges e)) nil)
    (spawn-look e 'rukia-burst-look :size 1.4 :life 24)
    (emit :sfx :freeze e)
    (clog "~a ZERO" (side-name e))))

(defun rukia-crack (e)
  "The CRACK (zero's :crush-hook: the ward crushed, bracing ran the guard gauge out, or a Guard Break): the gauge empties
(-18 at once), *CRACK-SELF* burnt (never below 1), a *CRACK-STUN* crumple in place when she isn't in a reaction already,
and the THAW lock (*RU-THAW-LOCK* frames in which guarding doesn't cool: the kit meter's idle clock)."
  (let ((f (fighter e)) (g (gauges e)) (p (pos-of e)))
    (set-form e (rukia-band-floor e :m18))           ; (the DANGAI boss: -50)
    (setf (gauges-meter g) 0f0 (gauges-meter-idle g) *ru-thaw-lock* (gauges-reishi g) (burn (gauges-reishi g) *crack-self*))
    (unless (member (fighter-state f) '(:stun :air :down :wakeup))
      (set-reaction e :crumple *crack-stun* (aref p 0) (aref p 2) 0.0))
    (emit :cold-crack e)
    (clog "~a CRACK r~d" (side-name e) (gauges-reishi g))))

;;; ================================================================ cinematics
;;; Rukia (black robe) goes on the white card; the Bankai 白霞罸 (white kimono) on the black one.
(declaim (type f32vec *ru-v*))
(defvar *ru-v* (make-f32 3) "A world point (the hand in 白霞罸's last shot).")

(defcine ru-kikon-cine (a v :len 186 :hold 112)
  "SOME NO MAI: TSUKISHIRO (the base Kikon; docs/duel/DUEL_RUKIA.md §5.1): beat 0, the pirouette held; a white card, Rukia
black, the blade and ribbon the only white, under the 初の舞 / 月白 stamp, silence; high and wide: the circle drawn round
the victim; low, wide-angle from outside it: the pillar of ice rises; a held push-in, poses and effects frozen, in
silence; the shatter: a negative, a manga page, the ice and the figure in shards, the Konpaku; a wide, ice dust falling."
  (at 0 (face-each-other a v 2.4)
      (cine-clip a :ru-kikon :blend 2) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :whoosh-heavy :pitch 1.2))
  (at 12 (card :white a) (shot-on a 30 3.0 0.6 :look 1.1 :off -0.8) (lens 44 -10) (silence 58)
      (caption "月白" :kanji2 "初の舞" :reading "SOME NO MAI" :sub "TSUKISHIRO  KIKON" :side 1 :ink t :hanko t))
  (at 70 (card nil) (caption-exit) (shot-pair a v (camera-side a) 8.0 5.2) (lens 50) (play-sfx :frost-tick))
  (during (70 186) (let ((q (pos-of v)))                   ; the circle drawn round him (in 20 f), then the pillar in it
                     (vfx-ru-ring (aref q 0) (aref q 2) 1.8 (min 1.0 (/ (- cf 70) 20.0)) (if (< cf 150) 1.0 (max 0.0 (- 1.0 (/ (- cf 150) 20.0)))))
                     (when (and (>= cf 100) (< cf 152))
                       (vfx-ru-pillar (aref q 0) (aref q 2) 1.8 4.5 (/ (- cf 100) 60.0) (cine-dt)))))
  (at 100 (shot-on v 150 5.5 0.3 :look 1.8) (lens 82) (play-sfx :ice-rise))
  (at 104 (setf (model-flash (model v)) 2.0))
  (push-in-on a v 128 3.8 0.8 0.5 0.1)
  (at 150 (impact-frame :negative 2)
      (multiple-value-bind (x y z) (actor-point v 1.0) (vfx-ru-dust x y z) (vfx-konpaku-shatter x (+ y 0.1) z 3))
      (setf (model-alpha (model v)) 0f0)
      (impact-splash-at v 0.0 14 0.07)
      (play-sfx :ice-shatter) (play-sfx :konpaku-shatter) (shake 0.25 0.35))
  (at 152 (impact-frame :manga 12))
  (at 170 (shot-on a 160 5.0 1.0 :look 1.2) (lens 48)))

(defcine ru-hakka-cine (a v :len 198 :hold 120)
  "卍解 白霞罸 HAKKA NO TOGAME (the awakened Kikon; §5.2, canon ch. 569-570): beat 0, the strike held; close and low, the
blade raised, silence, a white flash: the Bankai (white kimono, ice crown, white hair); a black card, a white back-rim,
the 卍解 / 白霞罸 stamp; low and wide between two lake-like frost discs, plaza and sky, a pillar with her at its root; along
the blade, the cold runs off the tip to him; held on him frozen, in silence; a manga page: he weathers into ice dust, the
Konpaku; the hand: a crack across its back (flavour only)."
  (at 0 (face-each-other a v 3.0) (setf *aura-off* a)
      (face-beat a :neutral 4.0)                          ; composed: no shout in any shot (the user's decision 2026-09-28)
      (cine-clip a :ru-hakka :blend 2 :speed 0.5) (cine-clip v :sh-kikon-victim :blend 4)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :freeze))
  (at 12 (shot-on a 25 1.8 0.5 :look 1.3) (lens 84 6) (silence 18) (cine-clip a :ru-hakka :blend 4 :speed 0.25))   ; the blade raised straight up (f4-16 of the clip), then levelled
  (at 24 (setf (model-body (model a)) (find-body :rukia-bankai) (model-weapon (model a)) :ru-ice
               (model-hide (model a)) (hide-set '(:hand-crack)))
      (ui-flash 1 1 1 1 30.0) (play-sfx :awaken-boom :pitch 1.3))
  (at 30 (card :black a) (back-rim 58) (shot-on a 20 4.2 0.8 :look 1.1 :off 0.9) (lens 42)
      (caption "卍解" :kanji2 "白霞罸" :reading "BANKAI" :sub "HAKKA NO TOGAME" :side 0 :hanko t))
  (at 88 (card nil) (caption-exit) (shot-on a 140 7.0 0.4 :look 3.0) (lens 70) (play-sfx :ice-rise) (play-sfx :awaken-rise :pitch 0.6))
  (during (88 198) (let ((p (pos-of a)))                  ; the two lakes of cold, her pillar between them
                     (vfx-ru-lake (aref p 0) (aref p 2) 6.0 0.02 (min 1.0 (/ (- cf 88) 18.0)))
                     (when (< cf 118)                  ; (gone for the over-the-shoulder shot: the lens would sit in it)
                       (vfx-ru-lake (aref p 0) (aref p 2) 6.0 7.5 (min 1.0 (/ (- cf 88) 18.0)))
                       (vfx-ru-pillar (aref p 0) (aref p 2) 1.2 6.0 (/ (- cf 88) 60.0) (cine-dt)))))
  (at 118 (shot-on a 165 2.4 1.5 :look 1.1 :ahead 2.6 :off 0.3) (lens 58) (play-sfx :kikon-slash))   ; over her shoulder
  (during (118 156) (let ((p (pos-of a)) (q (pos-of v)))  ; the cold runs off the tip to him
                      (vfx-ru-sheet (aref p 0) (aref p 2) (aref q 0) (aref q 2) (/ (- cf 118) 60.0) 0.6)))
  (at 136 (shot-on v 30 3.6 0.9 :look 1.1) (lens 64) (hold-both a v 20) (silence 20))
  (during (136 156) (setf (model-flash (model v)) 1.0)   ; frozen solid: encased in ice
    (let ((q (pos-of v))) (vfx-ru-pillar (aref q 0) (aref q 2) 0.7 2.3 (/ (- cf 132) 60.0) (cine-dt)))
    (multiple-value-bind (x y z) (actor-point v 0.9) (vfx-ru-crust x y z (cine-dt))))
  (at 156 (impact-frame :negative 1)
      (multiple-value-bind (x y z) (actor-point v 1.0) (vfx-ru-dust x y z) (vfx-konpaku-shatter x (+ y 0.1) z 3))
      (setf (model-alpha (model v)) 0f0)
      (play-sfx :ice-shatter) (play-sfx :konpaku-shatter) (shake 0.2 0.3))
  (at 158 (impact-frame :manga 12))
  (at 174 (refresh-look a) (setf (model-hide (model a)) (hide-set (remove :hand-crack (kit-hide (kit-of a)))) *aura-off* nil)
      (cine-clip a :ru-hand :blend 0) (lens 40) (play-sfx :hand-crack))
  (during (174 198) (let ((v *ru-v*) (p (pos-of a)) (yaw (yaw-of a)))   ; close on the right hand: the crack across it
                      (joint-point! v (model-joints (model a)) (ji :hand-r) 0f0 -0.04f0 0f0)
                      (cine-cam (+ (aref v 0) (* 0.55 (fwd-x (+ yaw 1.1)))) (+ (aref v 1) 0.12) (+ (aref v 2) (* 0.55 (fwd-z (+ yaw 1.1))))
                                (aref v 0) (aref v 1) (aref v 2))
                      (setf *cine-close* t (aref p 1) 0f0))))

(defcine ru-awaken-cine (a v :len 132 :hold 80)
  "絶対零度 ZETTAI REIDO (the awakening; §6): beat 0, the blade lowered, point down; close on her face: one last white
breath, then none, silence; low from behind: frost spreading from her feet over the plaza; a negative, then the white card,
Rukia black, the 絶対零度 stamp; back in the plaza at -18, the breath frosting again."
  (at 0 (cine-clip a :ru-awaken :blend 3) (cine-clip v (kit-stance (kit-of v)) :blend 6)
      (hold-both a v 12) (impact-frame :negative 2) (play-sfx :awaken-rise :pitch 1.2))
  (at 12 (shot-on a 12 1.3 1.45 :look 1.32) (lens 70) (silence 26)
      (multiple-value-bind (x y z) (actor-point a 1.18) (vfx-ru-breath x y z (yaw-of a))))
  (at 38 (shot-on a 170 3.2 0.35 :look 0.8) (lens 76 -6) (play-sfx :frost-tick))
  (during (38 132) (let ((p (pos-of a))) (vfx-ru-lake (aref p 0) (aref p 2) (* 4.0 (min 1.0 (/ (- cf 38) 24.0))) 0.02 1.0)))
  (at 46 (play-sfx :frost-tick)) (at 54 (play-sfx :frost-tick))
  (at 62 (impact-frame :negative 2) (card :white a) (shot-on a 20 4.4 0.8 :look 1.1 :off 0.9) (lens 42)
      (caption "絶対零度" :reading "ZETTAI REIDO" :sub "SODE NO SHIRAYUKI" :side 0 :ink t)
      (play-sfx :awaken-boom :pitch 1.2) (shake 0.15 0.3))
  (at 116 (card nil) (caption-exit) (shot-on a -30 6.0 1.4 :look 1.1) (lens 50)
      (multiple-value-bind (x y z) (actor-point a 1.18) (vfx-ru-breath x y z (yaw-of a)))))

;;; ================================================================ debug (RUKIA-DEBUG through *CHAR-DEBUG*; out of debug.lisp 2026-10-21)
(declaim (special *probe*))   ; (debug.lisp's)

(defparameter *rukia-tests*
  ;; k: P1-form P2 P2-form distance
  '((:base :kenpachi :base 5.0) (:m18 :kenpachi :base 2.2) (:m50 :kenpachi :base 2.2) (:zero :kenpachi :base 1.8)
    (:zero :yamamoto :base 7.0) (:zero :kenpachi :base 5.0) (:zero :kenpachi :base 5.0) (:zero :kenpachi :base 4.0)
    (:zero :kenpachi :base 3.0)))

(defun rukia-test (k)
  "Rukia's tests 2410+K (*RUKIA-TESTS*; human P1 Rukia, P2's CPU off): 3 P2's J1 into the ward (the freeze-touch), 4 P2's
full Shiranui (optic), 5 P2's Breaker (the CRACK), 6 the Breaker answered by REIDO TOKETSU when it is within 5.5 m, 7
zero left to warm out, 8 zero 3 m from him (hold U: braced to the CRACK). A :rukia probe logs \"duel probe rukia ...\" lines (form, state, Reishi, P2's state) every 10 f."
  (destructuring-bind (f1 c2 f2 d) (nth k *rukia-tests*)
    (setf *probe* nil)
    (ensure-battle :rukia c2)
    (force-form *p1* (if (eq f1 :zero) :m50 f1)) (force-form *p2* f2)
    (place *p1* *p2* d)
    (dolist (e (list *p1* *p2*)) (full-gauges! e 0f0))
    (setf (gauges-meter (gauges *p1*)) (case f1 (:m50 150f0) (:zero *cold-max*) (t 0f0)))   ; the band's cold
    (when (eq f1 :zero) (force-form *p1* :zero))
    (set-probe :rukia k)
    (let ((b (brain *p2*)))                             ; (the switched-off brain still writes its held button)
      (case k
        (3 (force-cmd *p2* :q))
        (4 (force-cmd *p2* :sp1) (setf (brain-press b) :flash (brain-press-mod b) t (brain-press-left b) 70))
        ((5 6) (force-cmd *p2* :breaker) (setf (brain-press b) :breaker (brain-press-mod b) nil (brain-press-left b) 60))))))

(defparameter *kl-tests* '((:base 0 nil) (:m18 60 nil) (:m50 150 nil) (:zero 200 nil) (:m18 10 nil) (:base 0 t) (:m18 60 t))
  "K -> L (2420+k): P1-form, its cold, P2 guarding. 4: -18 with 10 cold, short of L's 25 (refused); 5 / 6 blocked.")

(defun rukia-kl-test (k)
  "2420+k: human P1 Rukia (*KL-TESTS* k) 2.2 m from an idle Kenpachi (holding guard in 5 / 6); a :kl probe logs each hit
P2 takes: its reaction, his stun frames left just before it (> 0: a combo), the combo count, P1's move and cold."
  (destructuring-bind (form cold guard) (nth k *kl-tests*)
    (setf *probe* nil)
    (ensure-battle :rukia :kenpachi)
    (force-form *p1* (if (eq form :zero) :m50 form)) (force-form *p2* :base)
    (place *p1* *p2* 2.2)
    (dolist (e (list *p1* *p2*)) (full-gauges! e 0f0))
    (setf (gauges-meter (gauges *p1*)) (f32 cold))
    (when (eq form :zero) (force-form *p1* :zero))
    (when guard
      (setf (fighter-state (fighter *p2*)) :guard (fighter-guard-t (fighter *p2*)) 30
            (brain-press (brain *p2*)) :guard (brain-press-left (brain *p2*)) 999))
    (set-probe :kl k 0 0)))

(defparameter *ru-layer-tests*
  ;; k -> (P2's layers, distance (a J2 / J3 started on its own: 1.2 m, no opener's close-in), what P1 starts: a J / K link with L latched (its burst), :sig / :hold-l / :sp1 / :hold-sp1
  ;; / :sp2, NIL), P2's CPU on[, P2 holding guard]: 26 RIKUJOKORO into a held guard (bound all the same), 27 into his CPU (it
  ;; Steps or Hohos out of the ring: the user 2026-10-24, DUEL_RUKIA_TYBW §8); 28 RIKUJOKORO held to its end at 5.9 m (its longest bind: O
  ;; then, its Kikon follow-up sealed, §10)
  '((0 (0 2.2 nil nil)) (1 (1 2.2 nil nil)) (2 (2 2.2 nil nil)) (3 (3 2.2 nil nil))
    (10 (3 2.2 :ru-j1 nil)) (11 (3 1.2 :ru-j2 nil)) (12 (3 1.2 :ru-j3 nil)) (13 (3 2.2 :ru-k1 nil)) (14 (3 2.2 :ru-sk2 nil))
    (15 (3 2.2 :ru-k3 nil)) (16 (0 2.2 :ru-j1 nil)) (17 (1 2.2 :ru-sk2 nil))
    (20 (0 5.0 :sig nil)) (21 (0 6.0 :hold-l nil)) (22 (0 3.5 :sp1 nil)) (23 (0 5.0 :hold-sp1 nil)) (24 (3 3.0 :sp2 nil))
    (25 (0 3.0 :sp2 nil)) (26 (0 4.0 :hold-sp1 nil t)) (27 (0 4.0 :hold-sp1 t)) (28 (0 5.9 :hold-sp1-max nil)) (30 (3 3.0 nil nil)) (31 (3 8.0 nil t))
    (40 (3 1.2 :ru-j3 nil)))
  "85000+k (DUEL_GAMEPLAY \"Debug commands\"): the Shikai's 霜の層 scenes (RUKIA-LAYER-TEST).")

(defun rukia-layer-test (k)
  "85000+k: human P1 Rukia's Shikai vs Kenpachi (*RU-LAYER-TESTS*: P2's CPU off unless noted), both gauges full, P2 with
that many 霜の層; P1's link started with L latched (16: 0 layers, the L refused, the string ends; 17: one layer, K2's
burst bursts it), BYAKURAI / TSUKISHIRO / SOKATSUI / RIKUJOKORO / SP2 started; 30 the thaw, 31 his walk in under 3
layers (P2's CPU on), 40 霜陣's circle round him. A \"duel probe rukia 1xx\" line every 10 f (his layers, thaw, distance)."
  (destructuring-bind (layers d start cpu &optional guard) (or (second (assoc k *ru-layer-tests*)) '(0 2.2 nil nil))
    (setf *probe* nil)
    (ensure-battle :rukia :kenpachi)
    (force-form *p1* :base) (force-form *p2* :base)
    (place *p1* *p2* d)
    (dolist (e (list *p1* *p2*)) (full-gauges! e 0f0))
    (setf (fighter-layers (fighter *p2*)) layers (fighter-thaw (fighter *p2*)) 0 (brain-off (brain *p2*)) (not cpu))
    (setf (brain-press-left (brain *p2*)) 0)              ; (no held guard left over from an earlier scene)
    (when guard
      (setf (fighter-state (fighter *p2*)) :guard (fighter-guard-t (fighter *p2*)) 30
            (brain-press (brain *p2*)) :guard (brain-press-left (brain *p2*)) 999))
    (let* ((f (fighter *p1*)) (kit (fighter-kit f)))
      (case start
        ((nil))
        (:sig (try-command *p1* f :sig))
        (:hold-l (start-move *p1* (kit-next kit :ru-byakurai :hold)))
        (:sp1 (try-command *p1* f :sp1 :flash))
        (:hold-sp1 (start-move *p1* (kit-next kit :ru-sokatsui :hold) :flash))   ; (its hold: let go at once)
        (:hold-sp1-max (start-move *p1* (kit-next kit :ru-sokatsui :hold) :flash)    ; (held to its hold's end)
         (setf (fighter-hold f) (second (mv-hold (fighter-move f)))))
        (:sp2 (try-command *p1* f :sp2))
        (t (start-move *p1* (kit-move kit start)) (setf (fighter-queued f) :sig))))
    (set-probe :rukia (+ 100 k))))

(defun rukia-look-consing ()
  "85499: bytes consed by 10 calls of each of the Shikai's new looks (the layer crust at 1-3, 霜陣's circle, BYAKURAI's
beam, SOKATSUI's fire, RIKUJOKORO's marks and rods; 0 B wanted), a \"duel rukia look consing\" line."
  (let ((hz (make-hazard :kind :fx :x 0f0 :z 0f0 :yaw 0.5f0 :size 5f0 :life 30 :age 3 :data (list nil 60 0 :miss))))
    (flet ((bytes (fn) (let ((c0 (cons-bytes))) (dotimes (i 10) (funcall fn)) (- (cons-bytes) c0))))
      (log-msg "duel rukia look consing (10 calls, B): layers 1 ~d, 2 ~d, 3 ~d, sojin ~d, beam ~d, fire ~d, rods-tell ~d, rods ~d"
               (bytes (lambda () (vfx-ru-layers 0f0 0f0 1.8f0 1 0.016f0))) (bytes (lambda () (vfx-ru-layers 0f0 0f0 1.8f0 2 0.016f0)))
               (bytes (lambda () (vfx-ru-layers 0f0 0f0 1.8f0 3 0.016f0))) (bytes (lambda () (rukia-sojin-look hz 0.016f0)))
               (bytes (lambda () (rukia-beam-look hz 0.016f0))) (bytes (lambda () (rukia-fire-look hz 0.016f0)))
               (progn (setf (hazard-delay hz) 5) (bytes (lambda () (rukia-rods-look hz 0.016f0))))
               (progn (setf (hazard-delay hz) 0) (bytes (lambda () (rukia-rods-look hz 0.016f0))))))))

(defun rukia-debug (c)
  "Her debug commands (docs/duel/DUEL_GAMEPLAY.md \"Debug commands\"): 2410+k RUKIA-TEST k, 2420+k RUKIA-KL-TEST k; her
knobs 43000+k .. 66000+k, 72000+k / 73000+k (her CPU's :l-after-k); 67000+k P1's cold = k and its band, 68000 / 68001 the
white Rukia's earlier looks (stills); 85000+k RUKIA-LAYER-TEST k, 85499 the new looks' consing. Her cinematics' stills
(40000+, 69000+) stay with CINE-AT in debug.lisp."
  (cond ((<= 2410 c 2418) (rukia-test (- c 2410)))
        ((<= 2420 c 2426) (rukia-kl-test (- c 2420)))
        ((<= 43000 c 43100) (setf *frost-slow* (/ (- c 43000) 100.0)))
        ((<= 44000 c 44999) (setf *zero-brace-drain* (/ (- c 44000) 10.0)))
        ((<= 45000 c 45999) (setf *freeze-touch* (- c 45000)))
        ((<= 46000 c 46999) (setf *ru-cool-rate* (float (- c 46000))))
        ((<= 47000 c 47999) (setf *crack-self* (- c 47000)))
        ((<= 48000 c 48300) (setf (kit-mult (find-kit :rukia :zero)) (/ (- c 48000) 100.0)))   ; zero's damage x k / 100
        ((<= 49000 c 49099) (setf (getf (getf (kit-ai (find-kit :rukia :base)) :awaken) :melee-share) (/ (- c 49000) 100.0)))
        ((<= 50000 c 50100) (dolist (f '(:m18 :m50)) (setf (getf (getf (kit-ai (find-kit :rukia f)) :cool) :p) (/ (- c 50000) 100.0))))
        ((<= 51000 c 51999) (setf *ru-thaw-lock* (- c 51000)))
        ((<= 53000 c 53099) (dolist (f '(:m18 :m50)) (setf (getf (getf (kit-ai (find-kit :rukia f)) :cool) :near) (/ (- c 53000) 10.0))))
        ((<= 54000 c 54009) (setf (getf (getf (kit-ai (find-kit :rukia :base)) :intents) :zone) (- c 54000)))
        ((<= 55000 c 55999) (setf (kit-warm (find-kit :rukia :zero)) (/ (- c 55000) 10.0)))   ; zero's warming k / 10 per s
        ((<= 56000 c 56099) (setf (kit-walk (find-kit :rukia :m50)) (/ (- c 56000) 10.0)))
        ((<= 57000 c 57099) (setf (kit-walk (find-kit :rukia :m18)) (/ (- c 57000) 10.0)))
        ((<= 58000 c 58300) (setf (kit-mult (find-kit :rukia :base)) (/ (- c 58000) 100.0)))
        ((<= 60000 c 60200) (setf (kit-taken (find-kit :rukia :base)) (/ (- c 60000) 100.0)))
        ((<= 61000 c 61200) (loop for f in '(:m18 :m50 :zero) for r in '(1.0 0.9 0.889)   ; every band's damage taken,
                                  do (setf (kit-taken (find-kit :rukia f)) (* r (/ (- c 61000) 100.0)))))   ; -18's = k / 100
        ((<= 62000 c 62200) (setf *ru-block-cool* (/ (- c 62000) 100.0)))
        ((<= 63000 c 63100) (setf *ru-hit-warm* (/ (- c 63000) 100.0)))
        ((<= 65000 c 65100) (setf (getf (kit-field (find-kit :rukia :zero)) :away) (/ (- c 65000) 100.0)))
        ((<= 66000 c 66100) (setf *field-floor* (/ (- c 66000) 100.0)))
        ((<= 85000 c 85098) (rukia-layer-test (- c 85000)))   ; the Shikai's 霜の層 (2026-10-24, DUEL_RUKIA_TYBW §4.4)
        ((= c 85499) (rukia-look-consing))
        ((<= 72000 c 72100) (setf (getf (kit-ai (find-kit :rukia :base)) :l-after-k) (/ (- c 72000) 100.0)))   ; her CPU's
        ((<= 73000 c 73100) (dolist (f '(:m18 :m50 :zero))   ; L after a K link, k / 100 per hit: the Shikai / the bands
                              (setf (getf (kit-ai (find-kit :rukia f)) :l-after-k) (/ (- c 73000) 100.0))))
        ((= c 68000) (dolist (n '(:rukia-zero :rukia-bankai))   ; review stills: the white Rukia's look before the ice
                       (let ((b (find-body n)))                ; keyline (the ink, brows the hair's colour)
                         (setf (body-ink b) nil (body-palette b) (cons '(:brow #xE4E8EE) (body-palette b)))
                         (build-body b))))
        ((= c 68001) (dolist (n '(:rukia-zero :rukia-bankai))   ; review stills: the white Rukia's lashes before playtest 2
                       (let ((b (find-body n)))                ; (the ink's dark, not the brows' ice)
                         (setf (body-palette b) (cons '(:lid #x141016) (body-palette b)))
                         (build-body b))))
        ((<= 67000 c 67200) (let ((g (gauges *p1*)) (f (fighter *p1*)))   ; P1's cold = k and the band it asks for (stills)
                              (setf (gauges-meter g) (f32 (- c 67000)))
                              (when (getf (kit-meter (fighter-kit f)) :temp)
                                (let ((b (temp-band (gauges-meter g) (fighter-form f))))
                                  (unless (eq b (fighter-form f)) (force-form *p1* b))))))))
(dolist (r '((2410 2418 rukia-debug) (2420 2426 rukia-debug) (43000 68001 rukia-debug) (72000 73100 rukia-debug)
             (85000 85499 rukia-debug)))
  (pushnew r *char-debug* :test #'equal))

;; the Shikai's new names in the brush column (brush.lisp; not on the host): the kido, the bursts, its SP2 copy
(when (boundp '*brush-callouts*)
  (setf *brush-callouts*
        (append (remove-if (lambda (c) (member (first c) '(:ru-byakurai :ru-sokatsui :ru-rikujo :ru-shirafune-s :ru-shimochiri
                                                           :ru-setsuen :ru-sojin :ru-hyoreki :ru-tsurara :ru-hakuren-k)))
                           *brush-callouts*)
                '((:ru-byakurai "白雷" "HADO NO YON: BYAKURAI" "破") (:ru-sokatsui "蒼火墜" "HADO NO SANJUSAN: SOKATSUI" "破")
                  (:ru-rikujo "六杖光牢" "BAKUDO NO ROKUJUICHI: RIKUJOKORO" "縛") (:ru-shirafune-s "白刀" "SAN NO MAI: SHIRAFUNE" "参")
                  (:ru-shimochiri "霜散" "SHIMO-CHIRI" nil) (:ru-setsuen "雪煙" "SETSUEN" nil) (:ru-sojin "霜陣" "SOJIN" nil)
                  (:ru-hyoreki "氷礫" "HYOREKI" nil) (:ru-tsurara "氷柱" "TSURARA" nil) (:ru-hakuren-k "白漣" "TSUGI NO MAI: HAKUREN" nil)))))
