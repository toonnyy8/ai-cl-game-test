;;;; tuning.lisp — SOUL DUEL's balance knobs in one place (design-v1 §1–§4, §8, §14). Change a
;;;; number here and rebuild; nothing else needs to know. Units: frames are 60 Hz fixed steps,
;;;; distances metres, speeds m/s, angles degrees, Reishi integer points, fractions 0..1.
;;;; Per-move frame data (startup, damage, block advantage) lives with the moves (yama.lisp,
;;;; ken.lisp); a kit may also name a knob here by symbol (:walk *walk-yamamoto*): kit.lisp
;;;; resolves *EARMUFFED* symbols in kit/move data to their value at load.
;;;; Plain Common Lisp: loaded on the host by tests/duel-rules-test.lisp.
(in-package :duel)

;;; ================================================================ §1 rules
(defparameter *reishi-max* 1300
  "Reishi (health) of every fighter at the start, integer points. 1100 -> 1300 (guard v3, the user's decision
2026-09-26: real human matches run much faster than CPU vs CPU, so longer CvC matches are fine; the seed gate's
median window moved from 125-180 s to 125-210 s).")
(defparameter *konpaku-max* 9 "Konpaku (soul pips) per fighter, as in RoS; the one at 0 loses.")
(defparameter *red-threshold* 0.30
  "Red = Reishi below this fraction of max: the Kikon rush's dash-in follow-up can't be guarded (rules
KIKON-FOLLOW-UNGUARDABLE-P; above red he may guard it).
The §8 gate's pacing knob if seeded CPU matches run long (fix round: 0.10 .. 0.30 moved the gate
medians by only ~10 s, see p2-log).")
(defparameter *kikon-konpaku* 2 "Konpaku a Kikon removes (a kit's default :kikon-konpaku).")
(defparameter *kikon-konpaku-awakened* 3 "Konpaku a Kikon removes when the attacker is awakened (the default of an awakened kit).")
(defparameter *soul-break-extra* 1 "A Soul Break (Reishi reached 0) removes the attacker's current Kikon count + this ...")
(defparameter *kikon-max-event* 4
  "... but a Kikon never removes more than this (Nozarashi v2 §2.7) ...")
(defparameter *soul-break-max-event* 5
  "... and a Soul Break never more than this (the user's decision 2026-09-27: the Soul Break's own cap, so NOMIHOSE's
4 + 1 = 5; a Kikon stays capped at *KIKON-MAX-EVENT*).")
;;; the Kikon rush (the Kikon button, any time): aura, dash, then the kit's strike (frame data per kit)
;;; (each character's rush module sets its own aura, dash speed and range: the move's :params)
(defparameter *kikon-trigger* 1.6
  "... and the strike starts as soon as the opponent is within this range (a blocked strike pushes
him 0.6 m back: 2.2 m, still inside both characters' Q1 reach, so the -14 is punishable).")
(defparameter *kikon-follow-kb* 2.5
  "A rush strike that hits with the button held knocks the victim this far back (a short stagger) ...")
(defparameter *kikon-follow-stun* 16
  "... for this long (a victim who isn't red; a red one reels until the Kikon lands: KIKON-FOLLOW-STUN) ...")
(defparameter *kikon-follow-gap* 12
  "... while the rusher dashes in after him: its strike (the Kikon) lands this many frames after he can act
again, so he can guard it (not red), Step or Hoho out (KIKON-FOLLOW-WAIT).")
(defparameter *kikon-track* 120.0 "Default :track (deg/s) of a Kikon rush strike's startup (like the Breaker's dash).")
(defparameter *armor-from* 6 "A move's armour (:armor-hits) starts on this move frame (no frame-1 reversals).")
(defparameter *reset-distance* 8.0 "After a Kikon / Soul Break both fighters are placed this far apart.")
(defparameter *reset-neutral* 48 "Frames of neutral (inputs ignored) after the reset (0.8 s).")
(defparameter *reset-reiatsu-bonus* 10.0 "Reiatsu a kit with :reset-reiatsu gets at each reset (Kenpachi).")
(defparameter *match-seconds* 300 "Match timer. Time-up: more Konpaku wins, then higher Reishi %, else draw.")
(defparameter *chip-fire* 0.12 "Chip-damage fraction of fire projectiles on block (never kills).")

;;; ================================================================ §2 controls
(defparameter *input-buffer* 10 "Frames a button press stays buffered in the vpad.")

;;; ================================================================ §3 universal mechanics
;;; ---------------------------------------------------------------- facing, walk, step, guard
(defparameter *face-rate* 18.0 "Degrees per frame a fighter auto-turns to the opponent (idle/walk/guard).")
(defparameter *track-quick* 360.0 "Default :track (deg/s turn allowed during startup) of Quick moves.")
(defparameter *track-heavy* 60.0 "Default :track of Flash, Signature and SP moves.")
(defparameter *track-breaker* 120.0
  "Default :track of the Breaker dash: a sideways Step from >= 3 m beats it, a back Step doesn't.")
(defparameter *walk-yamamoto* 3.2 "Yamamoto's walk / strafe speed.")
(defparameter *walk-kenpachi* 4.4 "Kenpachi's walk / strafe speed.")
(defparameter *step-distance* 2.5 "Step hop length (stick direction; neutral = back).")
(defparameter *step-frames* 24 "Step total frames.")
(defparameter *step-iframes* '(3 9) "Step invulnerable frames, inclusive.")
(defparameter *run-yamamoto* 8.0 "Yamamoto's run (dash) speed: Step held past the hop.")
(defparameter *run-kenpachi* 10.0 "Kenpachi's run speed.")
(defparameter *run-turn* 300.0 "Degrees per second a runner turns toward the stick direction.")
(defparameter *run-stop* 1.2 "A run toward the opponent stops this close to him.")
(defparameter *run-brake* 6 "Frames of braking after Step is released (committed, like recovery).")
(defparameter *run-carry* 1.0 "A move started out of a run slides this far along the run (momentum) ...")
(defparameter *run-carry-frames* 10 "... over this many frames (never past *RUN-STOP* from the opponent).")
(defparameter *guard-raise* 2 "Frames of holding Guard before it blocks.")
(defparameter *guard-arc* 200.0 "Guard covers this many degrees in front (while the guard gauge lasts).")
(defparameter *block-pushback* 0.6 "Metres a blocked hit pushes the defender back.")
(defparameter *whiff-extra* 6 "A move that touched nothing recovers R + this (a J / K link: the two below).")
(defparameter *whiff-extra-j* 8
  "A J link (a :quick move) that touched nothing recovers R + this, a single swing with no string after it
(docs/DUEL_STRINGS.md §2.2, the user's decision 2026-09-27) ...")
(defparameter *whiff-extra-k* 12 "... and a K link (a :flash move) R + this.")
(defparameter *hazard-blockstun* 14
  "Blockstun of a blocked hazard hit (fire wave, Shiranui, pillars): a projectile has no
attacker recovery to measure advantage against, so it is a fixed stun.")
(defparameter *chain-lead* 3
  "On block a string's next link starts this many frames before the current link's recovery ends. With a -2 link
this leaves S_eff(next) - 2 frames of gap (J2 after J1: 5-7 f): Step / Hoho fit, J1 doesn't; a K link leaves >= 11 f,
so any J1 interrupts it (docs/DUEL_STRINGS.md §2.1). On hit the chain opens at the end of the active frames
instead (true combos); on a whiff never (the contact gate, §2.2).")
(defparameter *counter-mult* 1.25 "Damage multiplier of a counter-hit (Breaker / stance hit during startup).")
(defparameter *counter-stun* 10 "Extra hitstun frames of a counter-hit.")

;;; ---------------------------------------------------------------- Breaker
(defparameter *breaker-aura* 12 "Aura frames before the Breaker dash starts.")
(defparameter *breaker-dash-min* 12 "Shortest dash (a tapped Breaker) before the strike.")
(defparameter *breaker-dash-max* 45 "Longest dash while the button is held.")
(defparameter *breaker-speed-min* 9.0 "Dash speed at the start of the dash (m/s)...")
(defparameter *breaker-speed-max* 10.0 "... rising to this at *breaker-dash-max*.")
(defparameter *breaker-trigger* 2.2 "The strike starts when the opponent is within this range.")
(defparameter *breaker-startup* 8 "Strike startup (the aura brightens over it: the 'hit it now' tell).")
(defparameter *breaker-active* 4 "Strike active frames.")
(defparameter *breaker-recovery* 18 "Strike recovery.")
(defparameter *breaker-whiff* 30 "Strike recovery after a whiff.")
(defparameter *breaker-damage* 150 "Strike damage on a non-guarding opponent.")
(defparameter *breaker-reach* 2.6 "Strike hit reach (> trigger range, so a triggered strike connects).")
(defparameter *breaker-knockback* 3.0 "Strike knockback slide.")
(defparameter *guard-break-stun* 50 "Stun of a Guard Break.")
(defparameter *stance-break-stun* 40 "Crumple of a stance broken by a Breaker.")
(defparameter *clash-range* 3.0 "Breaker vs Breaker (both dashing/striking) within this range = CLASH.")
(defparameter *clash-push* 4.0 "A clash pushes both fighters this far apart ...")
(defparameter *clash-stun* 24 "... and stuns both this long.")
(defparameter *guard-break-kb* 0.8 "Slide of a guard-broken fighter.")
(defparameter *stance-break-kb* 0.5 "Slide of a broken stance.")

;;; ---------------------------------------------------------------- Reiatsu gauge (3 bars): SPs only
(defparameter *reiatsu-max* 300.0 "Reiatsu gauge maximum (3 bars).")
(defparameter *reiatsu-bar* 100.0 "One bar.")
(defparameter *reiatsu-regen* 3.0
  "Reiatsu per second, always (5 before the flash-step gauge took Hoho and Burst off it: design v3 G.3).")
(defparameter *reiatsu-dealt* 0.08 "Reiatsu per point of damage dealt.")
(defparameter *reiatsu-taken* 0.10 "Reiatsu per point of damage taken.")
(defparameter *cost-sp* 1 "Bars an SP1 / SP2 costs.")
(defparameter *cost-sp-awakened* 2 "Bars an SP2 costs in an awakened form.")

;;; ---------------------------------------------------------------- KOSEI (攻勢), the aggression reward (docs/DUEL_STRINGS.md §5)
;;; Every contact of the attacker's own melee hit window (hit, block, ward, DRINK, armour, absorb; not a parry, a
;;; hazard, a :ranged window or a Kikon) pays Reiatsu and flash-step, g x rate x m, g = the hit's guard value and
;;; m = 1 + *KOSEI-BONUS* x (1 - his own guard gauge / max): x1 at a full gauge ... x3 at an empty one.
(defparameter *kosei-bonus* 2.0 "KOSEI: the multiplier's range above 1 (x1 full gauge .. x(1 + this) empty).")
(defparameter *kosei-reiatsu* 0.20 "KOSEI: Reiatsu per guard point of a paying contact (x m).")
(defparameter *kosei-fs* 0.10 "KOSEI: flash-step per guard point of a paying contact (x m).")

;;; ---------------------------------------------------------------- flash-step gauge (design v3 G.1): Hoho, Burst
(defparameter *fs-max* 100.0 "Flash-step gauge maximum; full at the match start, kept through Kikon resets.")
(defparameter *fs-hoho* 30.0 "Flash-step a Hoho costs.")
(defparameter *fs-burst* 70.0 "Flash-step a Burst Reverse costs.")
(defparameter *fs-regen* 3.0 "Flash-step per second ...")
(defparameter *fs-delay* 60 "... once this many frames passed since the last spend.")
(defparameter *fs-taken* 0.03 "Flash-step per point of damage taken (a full 1300 Reishi bar = +39).")
(defparameter *fs-refund* 15.0 "A perfect Hoho gives this back (net cost 15: it rewards the read).")

;;; ---------------------------------------------------------------- guard gauge (design v3 G.2)
(defparameter *gg-max* 100.0 "Guard gauge maximum; full at the start and after every Kikon reset (both).")
(defparameter *gg-kind* '(:quick 8 :flash 14 :sig 18 :sp 22 :kikon 20)
  "Guard value (the gauge a blocked hit drains) by move kind; a hitwin / move :guard overrides it.")
(defparameter *gg-hazard* 12 "Guard value of a blocked hazard hit without its own :guard.")
(defparameter *gg-ender* 4 "+ this for a string ender (Quick / Flash / Signature with block advantage <= *GG-ENDER-ADV*).")
(defparameter *gg-ender-adv* -10 "The block advantage that makes a Quick / Flash / Signature an ender.")
(defparameter *gg-breaker* 35 "A Breaker's Guard Break also drains this.")
(defparameter *gg-delay* 60
  "The gauge refills only after this many frames without a drain (the user: 45 -> 60), counting only frames he is
not guarding (GUARD HOLD, guard v3: while he guards, in :guard / :guard-hit, it neither refills nor counts; the
count is frozen, not restarted: a phone's resting thumb is a guard) ...")
(defparameter *gg-regen* 5.5
  "... at this per second (the user: 20 -> 12; then, the user's request 2026-09-27 (大幅減少防禦量表的恢復速度): 12 -> 5.5,
46 %) ...")
(defparameter *gg-regen-guardless* 6.5
  "... or this while guardless (the user: 25 -> 14; 2026-09-27: 14 -> 6.5, 46 %; 0 -> 100 in 15.4 s + the delay).")
(defparameter *guard-crush-stun* 40
  "A blocked hit that empties the gauge is still blocked, then the defender reels this long (GUARD CRUSH)
and can't guard until the gauge is full again.")

;;; ---------------------------------------------------------------- Hoho
(defparameter *hoho-distance* 1.6 "Hoho reappears this far behind the opponent, facing him.")
(defparameter *hoho-frames* 24 "Hoho total frames.")
(defparameter *hoho-iframes* '(1 14) "Hoho invulnerable frames, inclusive.")
(defparameter *hoho-lockout* 60 "Frames between two Hohos.")
(defparameter *perfect-lead* 8 "Perfect Hoho: an opponent hit volume active now or within this many frames...")
(defparameter *perfect-inflate* 1.0 "... overlapping our hurt cylinder grown by this (radius and height).")
(defparameter *perfect-slowmo-seconds* 0.45 "Perfect Hoho slow motion, both fighters.")
(defparameter *perfect-slowmo-scale* 0.25 "Perfect Hoho time scale.")
(defparameter *perfect-counter-damage* 60 "The automatic counter strike (can't be Hoho'd or Burst).")
(defparameter *perfect-counter-stun* 36 "Hitstun of the counter strike.")
(defparameter *perfect-lock* 40 "Frames the perfect-Hoho victim's inputs are locked.")
(defparameter *hoho-appear* 6 "Hoho frame on which the fighter reappears behind the opponent ...")
(defparameter *hoho-counter-pose* 10 "... a perfect Hoho's counter swing starts ...")
(defparameter *hoho-counter-strike* 14 "... and its strike lands.")

;;; ---------------------------------------------------------------- Fighting Spirit (awakening)
(defparameter *awaken-max* 100.0 "Awakening gauge maximum: full = EVOLUTION (once per match).")
(defparameter *awaken-dealt* 0.05 "Awakening per point of damage dealt.")
(defparameter *awaken-taken* 0.07 "Awakening per point of damage taken.")
(defparameter *awaken-per-konpaku* 15.0 "Awakening per Konpaku lost.")
(defparameter *awaken-cine-seconds* 1.8 "Awakening cinematic (sim frozen; documentation only: the scripts own their :len).")

;;; ---------------------------------------------------------------- hit reactions, combos, hitstop
(defparameter *reaction-frames*
  '(:flinch 18 :stagger 26 :knockback 30 :launch 0 :knockdown 0 :guard-break 50 :crumple 40
    :down 30 :wakeup 30)
  "Stun frames per reaction. :launch / :knockdown are airborne / falling until they land (physics),
then :down + :wakeup (iframes in both).")
(defparameter *knockback-slide-frames* 18 "A grounded reaction's slide lasts at most this long.")
(defparameter *air-vy* '(:launch 7.5 :knockdown 3.5 :air 4.0)
  "Upward speed (m/s) given by a launch, a knockdown, and any other hit on an airborne fighter.")
(defparameter *air-slide* 0.6 "An airborne reaction slides this x the hit's :kb (1 m without one) ...")
(defparameter *air-slide-frames* 20 "... over this many frames.")
(defparameter *gravity* 22.0 "Airborne fighters fall at this (m/s^2).")
(defparameter *lunge-stop* 1.3 "A lunging move (:slide) stops moving this close to the opponent.")
;; the string follow-up's chase (docs/DUEL_STRINGS.md §2.2, the user's decision 2026-09-28): once a link of the string
;; touched him, every later link closes in during its startup so its hit window reaches him (motion only: guard, Step /
;; Hoho / down iframes still work)
(defparameter *chase-max* 18.0 "A follow-up link closes in at most this fast (m/s; the Kikon dash's speed) ...")
(defparameter *chase-margin* 0.4 "... to this far inside its reach (never nearer than *LUNGE-STOP*) ...")
(defparameter *chase-track* 360.0 "... turning toward him at least this fast (deg/s; a K link's own is 60).")
(defparameter *callout-frames* 90 "Frames a move name stays above its user.")
(defparameter *combo-launches* 1 "Launches per combo; a later launch becomes a knockback.")
(defparameter *combo-air-hits* 3 "Airborne hits per combo; the last one knocks down.")
(defparameter *combo-full-hits* 3 "Hits 1..this deal full damage...")
(defparameter *combo-decay* 0.10 "... then each hit deals this much less ...")
(defparameter *combo-floor* 0.40 "... down to this fraction.")
(defparameter *combo-cap* 10 "Hit N of a combo is a forced knockdown.")
(defparameter *hitstop-light* 4 "Global hitstop of Quick hits.")
(defparameter *hitstop-heavy* 8 "Global hitstop of every other hit.")
(defparameter *hitstop-breaker* 10 "Global hitstop of a Breaker hit / Guard Break / clash.")
(defparameter *hitstop-block* 3 "Global hitstop of a blocked, armoured or absorbed hit.")
(defparameter *super-flash* 6 "SP start: frames of the rim-light super flash...")
(defparameter *super-freeze* 4 "... and frames the opponent alone is frozen.")

;;; ---------------------------------------------------------------- arena, Burst Reverse
(defparameter *arena-radius* 15.0 "Circular arena; fighters are clamped inside (invisible wall).")
(defparameter *burst-min-hits* 2
  "Burst Reverse (mod + Quick, *FS-BURST* flash-step) only in hitstun / airborne after this many hits of
a combo (critique-design 1.7: not from hit 1).")
(defparameter *burst-invuln* 20 "Frames the Burst user stays invulnerable (he is neutral at once).")
(defparameter *burst-push* 5.0 "Burst pushes the attacker this far (no stun; his move ends) ...")
(defparameter *burst-push-frames* 20 "... over this many frames.")
(defparameter *burst-hitstop* 8 "Global hitstop of a Burst.")

;;; ================================================================ §4 damage multipliers
(defparameter *hellfire-mult* 1.30 "Damage x in Hellfire (Gokuen).")
(defparameter *nozarashi-mult* 1.0 "Damage x in Nozarashi's first cup, KATATE (v2: x1.15 before the ladder).")
(defparameter *ryote-mult* 1.15 "Damage x in the second cup, RYOTE.")
(defparameter *nomihose-mult* 1.20 "Damage x in the third cup, NOMIHOSE.")
(defparameter *bankai-taken* 1.5
  "Damage x Bankai East takes (the defender's :taken): the extreme stance. The Bankai rework (the user's spec
2026-09-27, docs/DUEL_YAMA_REWORK.md): 1.2 -> 1.5, East only (West takes x1.0). Not a tuning knob: the spec's value.")
(defparameter *pierce-min* 0.1
  "Bankai East's pierce (passive :pierce, rules PIERCE-RATE): k = this at an empty guard gauge ...")
(defparameter *pierce-max* 0.45
  "... rising linearly to this at a full one (the user's decision 2026-09-27: full gauge = sharpest). A hit deals
x(1 + k); a blocked hit lets k x its damage through as chip (never kills). East's balance knob: the spec's 0.5 -> 0.45
at the seed gate (with *WARD-MULT* 1.1: YK Yamamoto 10 / 20, medians YY 128.6 / YK 129.9 s; at 0.5 / 1.0 the YK
median fell to 123.6 s).")
(defparameter *ward-mult* 1.1
  "Bankai West's ward (passive :ward): a hit it blocks drains this x its guard value (after Kenpachi's cut). The main YK
balance knob of the rework (replaces the x1.3 Bankai drain, deleted: the user's decision 2026-09-27); 1.0 -> 1.1 at
the seed gate (see *PIERCE-MAX*).")
(defparameter *cornered-per-konpaku* 0.05 "Cornered: + this damage fraction per Konpaku lost ...")
(defparameter *cornered-max* 0.25 "... up to this.")

;;; ================================================================ §5 form numbers (used by the kits)
(defparameter *inferno-max* 100.0 "Inferno (Goen) gauge; full -> Hellfire.")
(defparameter *inferno-flash* 20.0 "Inferno per Flash hit.")
(defparameter *inferno-sig* 15.0 "Inferno per Signature hit (the cuts and the wave).")
(defparameter *meter-on-block* 5.0 "Kit meter (Inferno) for a blocked hazard that gains meter on hit (wave, Shiranui).")
(defparameter *hellfire-seconds* 10.0 "Hellfire length (the Inferno bar drains over it).")
(defparameter *hellfire-burn* 0.05 "Hellfire burns this fraction of max Reishi per second (floor 1).")
(defparameter *ennetsu-damage* 60 "Ennetsu Jigoku (Hellfire entry) pillar damage per hit...")
(defparameter *ennetsu-hits* 2 "... at most this many hits ...")
(defparameter *ennetsu-self-burn* 30 "... and it burns the caster for this (floor 1).")
(defparameter *ennetsu-pillars* 7 "Pillars in the Ennetsu ring.")
(defparameter *ennetsu-seconds* 0.8 "Ennetsu duration.")
;;; Bankai stances (docs/DUEL_YAMA_REWORK.md): East / West are kit forms; U switches East -> West, an attack other
;;; than SP1 / L drops West back to East
(defparameter *scorch* 15 "West (:scorch): a melee hit his parry catches burns the attacker this much (never kills; the parry also refills his
guard gauge: the rework).")
(defparameter *parry-window* '(4 15) "GOKUI GAESHI: the move frames (inclusive) its parry catches a melee hit ...")
(defparameter *parry-stun* 32 "... the parried attacker staggers this long (his move ends) ...")
(defparameter *parry-slide* 0.5 "... sliding this far.")
(defparameter *bind-stun* 60 "South (the bind): frames the victim's feet are held. Pacing knob (design v3 §E): 60 -> 45.")
(defparameter *nozarashi-heal* 150 "Reishi Nozarashi's awakening heals.")
(defparameter *nozarashi-reach* 1.3 "Nozarashi KATATE (cup 1): reach x of the inherited moves (1.4 before the ladder).")
(defparameter *nozarashi-startup* 2 "Nozarashi KATATE (cup 1): extra startup frames of the inherited moves (3 before: F1->F2 was a 0 gap).")
(defparameter *ryote-reach* 1.4 "RYOTE (cup 2): reach x of the base moves it doesn't list.")
(defparameter *ryote-startup* 3 "RYOTE (cup 2): extra startup frames of the base moves it doesn't list.")
;;; Nozarashi v2, NOME (呑め): the three-cup ladder (docs/DUEL_NOZARASHI_V2.md). The meter is the kit meter
;;; (GAUGES-METER); a rung is a kit form, changed only while he is free (combat.lisp NOME-STEP)
(defparameter *nome-max* 100.0 "The NOME gauge.")
(defparameter *nome-awaken* 10.0 "NOME at the awakening (cup 1).")
(defparameter *nome-dealt* 0.08 "NOME per point of damage he deals ...")
(defparameter *nome-taken* 0.12 "... per point he loses (a drink's taken half too, the stance's absorbed points) ...")
(defparameter *nome-drunk* 0.30 "... and per point drunk: a DRINK's swallowed half, all the stance absorbs. Knob: 0.30 -> 0.20.")
(defparameter *nome-delay* 180 "RYOTE drains only after this many frames without a gain (guard v3: 60 -> 180) ...")
(defparameter *nome-drain-t2* 1.5 "... at this per second (guard v3: 3.0 -> 1.5) ...")
(defparameter *nome-drain-t3* 10.0 "... NOMIHOSE drains this per second, always (no delay). Knob: 10 -> 12.")
(defparameter *nome-up-t2* 40.0 "Up to RYOTE at this ...")
(defparameter *nome-down-t2* 25.0 "... back to KATATE below this ...")
(defparameter *nome-up-t3* 100.0 "... up to NOMIHOSE at this ...")
(defparameter *nome-down-t3* 50.0 "... back to RYOTE below this.")
(defparameter *nomihose-chip* 0.2 "NOMIHOSE: blade chip through guard.")
(defparameter *cut-mult* 1.5
  "The cut (RYOTE and NOMIHOSE, passive :cut): his blocked Flash / Signature / SP hits drain this x their guard value
(no gauge-paid armour is left for it to cut).")
(defparameter *drink-adv* 4 "DRINK (NOMIHOSE's U): a drunk melee hit leaves the attacker this many frames worse off than a block.")
(defparameter *rift-delay* 20 "KUKAN-GIRI: the rift it leaves cuts this many frames after its blade (f20 -> f40). Knob: 20 -> 18.")
(defparameter *stance-in* 6 "Stance Signature: frames to enter the stance (hit = counter-hit).")
(defparameter *stance-hold-max* 60 "Longest stance hold before the cut comes out by itself.")
(defparameter *stance-store-rate* 1.0 "Stance stores this x the damage it absorbs...")
(defparameter *stance-store-cap* 200 "... up to this.")
(defparameter *stance-base-damage* 100 "Stance cut damage before the stored bonus.")
(defparameter *stance-crush-at* 150 "Stored >= this: the cut crushes guard.")
;;; Kenpachi's Bankai and 片腕 KATAUDE (docs/DUEL_KEN_BANKAI.md; the user's decisions 2026-09-28): a second awakening from
;;; cup 3, red, P; his own Konpaku -> 1 and his Reishi -> full on entry; the arm meter UDE (the kit meter, GAUGES-METER)
;;; spends a pip per heavy command; at 0 the arm bursts (then 片腕 for the rest of the match)
(defparameter *bankai-ken-mult* 1.2 "Damage x in Kenpachi's Bankai.")
(defparameter *bankai-konpaku* 4
  "Kenpachi may enter his Bankai (P in cup 3) with at most this many of his own Konpaku left (the user's decision
2026-09-28, replacing the red-Reishi condition).")
(defparameter *arm-pips* 4 "The arm meter UDE: pips at the Bankai's entry (the 4th spent: the arm bursts).")
(defparameter *arm-crack* 300 "A pip cracks by itself after this many frames without a spend (paused while locked): <= 20 s of Bankai.")
(defparameter *arm-self* 60
  "Reishi each spent pip burns (BURN: never below 1). The design's 30 against a red Kenpachi; x2 now that the entry refills
him to full (the user's decision 2026-09-28): the gate's knob.")
(defparameter *arm-burst-self* 120 "Reishi the burst burns (the design's 60, x2 with the full refill).")
(defparameter *arm-burst-stun* 40 "The burst's self-inflicted crumple, frames.")
(defparameter *kataude-reach* 0.7 "片腕 KATAUDE: reach x of his sword moves (the kick, the Breaker and O as written).")
;;; Kuchiki Rukia (docs/DUEL_RUKIA.md): frost, the one new status, and the cold gauge of 絶対零度 (the awakened bands
;;; :m18 :m50 :zero; the kit meter holds the cold C, 0 .. *COLD-MAX*, two stacked bars: combat.lisp TEMP-STEP)
(defparameter *walk-rukia* 3.8 "Rukia's walk (Shikai).")
(defparameter *rukia-mult* 1.5
  "Damage x of the Shikai (the base kit's :mult; 58000+k at run time). The seed gate's lever: the CPU's Shikai fights the
opponents' awakened forms for most of a match (docs/DUEL_RUKIA.md, Measurements) ...")
(defparameter *rukia-taken* 0.8 "... and the damage it takes x this (60000+k).")
(defparameter *rukia-awake-mult* 1.15 "Damage x at -18 C (48000+k sets zero's, the colder-never-weaker lever) ...")
(defparameter *rukia-m50-mult* 1.5 "... at -50 C ...")
(defparameter *rukia-zero-mult* 1.65 "... and at absolute zero (melee and ranged alike).")
(defparameter *rukia-awake-taken* 0.95 "Damage taken x at -18 C (61000+k scales every band) ...")
(defparameter *rukia-m50-taken* 0.85 "... at -50 C (hardened) ...")
(defparameter *rukia-zero-taken* 0.8 "... and at absolute zero (a ranged hit passes the ward: optic).")
(defparameter *run-rukia* 9.0 "Rukia's run (Shikai).")
(defparameter *walk-m18* 3.4 "-18 C: walk ...")
(defparameter *run-m18* 8.0 "... and run.")
(defparameter *walk-m50* 2.8 "-50 C: walk ...")
(defparameter *run-m50* 6.4 "... and run. Absolute zero: rooted (0).")
(defparameter *frost-slow* 0.7 "Frost: a frosted fighter walks and runs x this (Step, Hoho, lunges, dashes and frames untouched).")
(defparameter *frost-cap* 150 "Frost: the timer never exceeds this (a hit sets it to max(current, n): it never stacks).")
(defparameter *frost-touch* 30 "-18 C: every real hit of hers frosts this long (the kit's :frost-touch; a hit window's own :frost wins if longer) ...")
(defparameter *frost-touch-m50* 60 "... at -50 C ...")
(defparameter *frost-touch-zero* 90 "... at absolute zero.")
(defparameter *cold-max* 200.0 "The cold gauge: two stacked bars of *COLD-BAR* (the user's decision 2026-09-28).")
(defparameter *cold-bar* 100.0
  "One bar of cold. -18 -> -50 when C reaches it, -50 -> -18 when C falls to 0; -50 -> zero when C reaches *COLD-MAX*,
zero -> -50 when C falls to it (rules TEMP-BAND).")
(defparameter *ru-cool-rate* 90.0
  "Cold per second while she guards (the GUARD HOLD test; bracing at zero): a bar in 1.1 s, -18 -> zero in 2.2 s (the
user's decision 2026-09-28: cool faster; the design's pacing was 3.3 s; 46000+k).")
(defparameter *ru-block-cool* 1.5 "A blocked melee hit cools her this x its guard value (x1.5 with the faster cooling; 62000+k: x0.01).")
(defparameter *ru-hit-warm* 0.2 "A real hit taken warms her this x its damage (63000+k: x0.01).")
(defparameter *ru-warm-m18* 10.0 "Warming, cold per second while she isn't guarding, at -18 C (a full bar: 10 s) ...")
(defparameter *ru-warm-m50* 12.0 "... at -50 C (a bar: 8.3 s) ...")
(defparameter *ru-warm-zero* 5.0
  "... at absolute zero, the slowest (the user's decision 2026-09-28: zero is easier to hold; half of -18's; unbraced 20 s
to warm the top bar away; 55000+k).")
(defparameter *ru-cold-m18* '(:sig 25)
  "Cold each command spends at -18 C (the user's decision: only L; refused below its cost) ...")
(defparameter *ru-cold-m50* '(:q 6 :f 12 :sig 36 :sp1 40 :sp2 40 :kikon 20 :breaker 20 :step 12 :hoho 20) "... at -50 C ...")
(defparameter *ru-cold-zero* '(:q 20 :f 40 :sig 100 :sp1 100 :sp2 100 :kikon 60)
  "... and at absolute zero (L and the SPs cash the whole top bar: she drops to -50; J / K / O 15 / 30 / 50 -> 20 / 40 / 60
with the faster cooling: the A/B).")
(defparameter *ru-field-m18* '(:r 3.0 :away 0.85 :step 1.0)
  "The cold field 寒域 at -18 C: within :r m of her the opponent walks / runs away from her x :away, his away Step x :step ...")
(defparameter *ru-field-m50* '(:r 4.0 :away 0.7 :step 0.9) "... at -50 C ...")
(defparameter *ru-field-zero* '(:r 5.5 :away 0.55 :step 0.75) "... at absolute zero (65000+k: :away x0.01).")
(defparameter *field-floor* 0.45 "The field x frost never slows the away walk below this (66000+k: x0.01).")
(defparameter *zero-brace-drain* 8.0 "Absolute zero: bracing (U held) stops the warming but drains the guard gauge this per second (44000+k).")
(defparameter *ru-thaw-lock* 120 "After a CRACK her guard doesn't cool for this many frames (51000+f).")
(defparameter *crack-self* 60 "The CRACK (the ward crushed or broken at zero) burns this much (never below 1) ...")
(defparameter *crack-stun* 30 "... and crumples her in place this long when she isn't in a reaction already.")
(defparameter *freeze-touch* 18 "Absolute zero: the first melee hit the ward blocks freezes its attacker this long (once per zero visit; the
design's 24 -> 18: the A/B).")
;;; hazard shapes and timing (hazards.lisp)
(defparameter *hazard-rehit* 16 "Frames a multi-hit hazard (pillars) waits between two hits.")
(defparameter *wave-box* '(1.2 0.5) "Fire wave box: half-height, half-length (half-width = its :width / 2).")
(defparameter *pillar-size* '(0.7 5.0) "Ennetsu pillar cylinder: radius, height.")
(defparameter *pillar-window* '(6 8) "Pillars hit from this many frames after they erupt until this many before they end.")

;;; ================================================================ §8 CPU AI
(defparameter *ai-delay* '(:easy 24 :normal 14 :hard 8) "Perception delay (frames) per difficulty.")
(defparameter *ai-repick* 12 "Frames between intent re-picks.")
(defparameter *ai-aggression* '(:pressure 0.45 :approach 0.3 :zone 0.5 :defend 0.1)
  "Chance a neutral decision is an attack, per intent (+ 0.04 per heat point, at most 0.9).")
(defparameter *ai-respect* 120 "Frames a CPU stays in DEFEND after a reaction / blockstun ends.")
(defparameter *ai-think* '(:easy 56 :normal 40 :hard 20)
  "Frames (+ 0..40 random) between two neutral decisions (attack / guard / wait): the CPU's tempo.")
(defparameter *ai-guard-hold* '(14 20) "A neutral guard is held this + 0..that frames.")
(defparameter *ai-strafe-time* '(40 80) "The strafe direction is re-rolled every this + 0..that frames.")
(defparameter *ai-punish-adv* -8 "Punish a recovering opponent whose advantage is at or below this.")
(defparameter *ai-block-punish-p* '(:easy 0.25 :normal 0.6 :hard 0.9)
  "Chance the CPU punishes, with Q1, a blocked move whose block advantage is <= *AI-PUNISH-ADV*. It
feels its own blockstun (no perception delay), so this is the only thing that decides it.")
(defparameter *ai-string-flash-p* 0.3
  "On hit, a string that can go on with J or K takes K this often (the design's 0.5; 0.3 at the seed gate: K links
are the heavy ones).")
(defparameter *ai-o-ender* 0.15
  "The O ender (a completed string: a link-3 hit) on an opponent who isn't red, per string: a kit's :o-ender, else
this (on a red one always). A pacing knob of the seed gate (docs/DUEL_STRINGS.md §4, §6, §9: the design's 0.35 -> 0.15).")
(defparameter *ai-ru-l-after-k* 0.05
  "The CPU's L after a K link that hit, per hit (a kit's :ai :l-after-k; Rukia's Shikai, docs/DUEL_STRINGS.md §12). A
pacing knob of the seed gate (debug 72000+k sets it to k / 100).")
(defparameter *ai-ru-l-after-k-awake* 0.1
  "The same in her awakened bands (the awaken A/B's knob: debug 73000+k sets it to k / 100).")
(defparameter *ai-follow-guard-p* '(:easy 0.6 :normal 0.85 :hard 0.95)
  "A CPU who isn't red guards a Kikon rush's dash-in follow-up with this chance (the B1 knob: DUEL_STRINGS §6).")
(defparameter *ai-j-beats-k-p* '(:easy 0.2 :normal 0.45 :hard 0.7)
  "J beats K: an opponent's K link still >= S(J1) + 2 frames from its hit, within J1's reach: J1 with this chance.")
(defparameter *ai-sp-cancel-p* 0.3
  "A string that ends on a hit with no link left (link 3, or a link the CPU doesn't go on from) is cancelled into SP2
with this chance, one roll (the kit's :sp-cancel-bars permitting). Link 3 staggers / crumples, so SP2 always combos
off it (Kenpachi's flurry): a seed-gate pacing knob (docs/DUEL_STRINGS.md §9).")
(defparameter *ai-block-k-p* 0.15
  "On block a string goes on with a K link only this x the kit's :block-string (a J link otherwise; never a K ender).")
(defparameter *ai-kosei-aggression* 0.2
  "KOSEI: a neutral decision attacks + this x (1 - its own guard gauge / max) more often.")
(defparameter *ai-guard-break-hold* 24 "Breaker a guard held longer than this (0.4 s) ...")
(defparameter *ai-guard-break-range* 3.0 "... within this range ...")
(defparameter *ai-guard-break-p* 0.4 "... with this probability.")
(defparameter *ai-anti-breaker-p* '(:easy 0.4 :normal 0.55 :hard 0.7) "Answer an incoming Breaker aura.")
(defparameter *ai-anti-breaker-range* 5.0 "... seen within this range: Hoho (a bar), Q1 beyond ...")
(defparameter *ai-anti-breaker-q* 1.8 "... this range, else a sideways Step.")
(defparameter *ai-react-p* 0.7 "Chance of a kit :react answer (Kenpachi's stance) to what triggers it.")
(defparameter *ai-threat-margin* 1.5 "A committed opponent move is a threat within its reach + this.")
(defparameter *ai-projectile-range* 7.0 "An incoming projectile is 'seen' within this range.")
(defparameter *ai-heat-rate* 1.5 "Heat per second without dealing damage (reset by dealing any).")
(defparameter *ai-heat-far* 6.0 "Beyond this distance heat rises twice as fast (two zoners staring).")
(defparameter *ai-heat-range* 0.3 "Preferred range shrinks this much per heat point ...")
(defparameter *ai-min-range* 1.0 "... but never below this.")
(defparameter *ai-heat-breaker* 8.0 "At this heat the Breaker weight doubles.")
(defparameter *ai-burst-p* '(:easy 0.2 :normal 0.6 :hard 0.85)
  "Chance (one roll per combo) the CPU bursts once it is worth it (AI-BURST-WANTED-P), no sooner
than its perception delay after the combo's *BURST-MIN-HITS*th hit.")
(defparameter *ai-burst-low* 0.5 "Burst is worth it below this fraction of Reishi ...")
(defparameter *ai-dash-gap* 2.5
  "The CPU dashes (the kit's :dash / :dash-back chance, at a neutral decision) when it stands this
far outside its preferred range: toward it from beyond, away from it from inside; it lets go in the
middle of the range.")
(defparameter *ai-dash-frames* 70 "Longest the CPU holds a dash.")
(defparameter *ai-hold-guard* '(:easy 0.97 :normal 0.92 :hard 0.8)
  "In blockstun a CPU keeps holding Guard through the string with this chance per blocked hit, whatever its
guard gauge (turtling mid-string is what a Guard Crush punishes): the easier CPU turtles and gets crushed,
the harder one steps out. (Its neutral guard choice still shrinks with the gauge: AI-GUARD-MULT.)")
(defparameter *ai-kikon-p* 0.5
  "The CPU rushes a red opponent within its kit's :kikon-range (a stunned one at once) with this chance
per neutral decision; one who isn't red only as a poke (the kit's :moves bands).")

;;; ================================================================ §14 budgets
(defparameter *fire-density* 1.0 "Scales every fire emitter's rate (0.5 if the perf gate fails).")
