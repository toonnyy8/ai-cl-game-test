# SOUL DUEL — Gameplay systems, debugging and tests

How to build, play, debug and test SOUL DUEL (`duel/`, package `DUEL`). The rules and every
number are in `DUEL_DESIGN.md`; the engine calls in `ENGINE_API.md`; the teaching walkthrough is
TUTORIAL.zh-TW.md step 9. RAVEN EDGE's equivalent of this file is `GAMEPLAY.md`.

## Build, run, play

```sh
./build.sh duel                                # duel/MANIFEST -> dist/duel/ (wasm ~5.9 MB)
python3 -m http.server -d dist/duel 8000       # open http://localhost:8000/ in a WebGPU browser
tools/pkgcheck.sh duel                         # 0 / 0 / 0 expected (exit 1 on any finding)
```

The build must log 0 warnings (`build/duel/lisp.log`). Sound starts after the first key press.
The pointer is never locked (`*pointer-lock*` NIL): a keyboard-only game.

| Action | P1 keys | P2 keys | Pad (P1 = pad 0, P2 = pad 1) |
|---|---|---|---|
| Move | W A S D | arrows | left stick / d-pad |
| Quick / Flash / Signature | J / K / L | KP1 / KP2 / KP3 | X / Y / B |
| Guard (hold; Bankai East: switch to West, whose ward is always up; cup 3: DRINK) | U | KP4 | LB |
| Breaker (hold) | I | KP5 | RB |
| Kikon rush (hold through the strike: the Kikon on a red opponent) | O | KP6 | RT |
| Step (hold = dash: run after the hop) | Space | KP0 | A |
| Reiatsu modifier (hold) | Left Shift | KP Enter | LT |
| Awaken | P | KP + | Back, or LS+RS |
| SP1 / SP2 / Hoho | Shift+K / Shift+L / Shift+Space | KP Enter + KP2 / KP3 / KP0 | LT + Y / B / A |
| Burst Reverse (in a combo, past its 2nd hit) | Shift+J | KP Enter + KP1 | LT + X |
| Pause (skip a cinematic) | Esc | Esc | Start |

Menus: up / down with W S, arrows or the d-pad; confirm Enter / J / KP1 / KP Enter / pad A; back
Esc / K / KP2 / pad B. The title also takes Space or Start. VS CPU uses the camera behind P1 (stick
up = at the opponent); CAMERA: BEHIND / SIDE is the pause menu's last item and the second row of the
select screen's difficulty page (up / down picks the row, left / right changes it). The CONTROLS screen (MODE menu) shows
the same table. The bindings are data: `*p1-bindings*` / `*p2-bindings*` in
`duel/lisp/control.lisp`.

**Flow** (`flow.lisp`, one `duel -> STATE` log line per change): TITLE → MODE (VS CPU / VS PLAYER
/ CPU VS CPU / CONTROLS) → SELECT (left / right picks P1, confirm, then P2 or the CPU, then the
CPU difficulty and, VS CPU, the camera; back steps back) → INTRO (a 5 s cinematic; Esc or confirm
skips) → BATTLE (Esc: RESUME / RESTART / CHARACTER SELECT / TITLE, VS CPU also CAMERA; losing focus
pauses) → FINISH (K.O. or TIME
cinematic) → RESULTS (REMATCH / CHARACTER SELECT / TITLE after 2.5 s). A menu match is seeded
from the clock; REMATCH takes a new seed.

## Files

`duel/MANIFEST` order: `package`, `tuning`, `rules`, `control` (plain CL, host-tested), `sounds`,
`components`, `body`, `kit`, `cinema`, `stage`, `vfx`, `yama-art`, `ken-art`, `yama`, `ken` (the
characters: data, hooks, cinematics), `fighter`, `combat`, `hazards`, `ai`, `camera`, `feedback`,
`flow`, `hud`, `debug`, `main` (the generic systems; only `debug.lisp` names characters, to set up
scenes). The module table is in ARCHITECTURE.md. The name-leak check (it must print nothing):

```sh
grep -nE ':ya-|:ke-|yama|kenpachi' duel/lisp/{rules,control,fighter,combat,hazards,ai,camera,flow}.lisp
```

Engine modules the duel was the first user of (moved into the engine by the harvest):
`engine/lisp/input.lisp` (the vpad), `hitvol.lisp` (hit volumes), `body.lisp` (rigid-part bodies),
`cine.lisp` (the cinematic director), `run-fixed-steps` (time.lisp), `fx-ribbon` / `fx-sector`
(fx.lisp), `ui-bitmap` / `ui-big-text` (ui.lisp), `defstrike` (anim.lisp).

## Time model (`main.lisp`)

* `game-frame`: flow (menus, pause) → the frame's fixed steps (`advance-sim`: the engine's
  `run-fixed-steps`, at most 6 per frame, only while a match runs) → camera → draw → HUD.
* `sim-step`, one 1/60 s step:
  - a cinematic runs (`*cine*`): read the humans' devices, then `cine-step` (engine cine.lisp);
  - hitstop (`time-step` returns NIL): read the devices only;
  - else slow motion by **step skipping**: `*slow-acc*` += the slow-mo scale; a sim frame runs
    only when it reaches 1 (`start-match` zeroes it: see Determinism). Then `pilot-system` (human vpads read their devices) and
    `sim-systems`: `brain-system` → `fighter-system` → `hazard-system` → `hit-system` →
    `gauge-system` → `match-system` (the last four skip when a Kikon started a cinematic mid-way);
  - always: `god-update`, `probe-update`, `feedback-system`, `hash-log`.
* A press made during hitstop, slow motion or a cinematic is still buffered afterwards
  (`pilot-read` reads devices without advancing the vpad clock); a cinematic's end forgets presses
  (`vpad-flush!`) so mashing through it fires nothing.
* Cosmetic work (particles, auras, cinematic looks, the camera) runs per rendered frame on real
  time and uses `rnd01`; everything the sim decides uses `sim-rnd01`.

## Entities (`components.lisp`)

A fighter = `transform motion model blade fighter gauges pilot` (+ `brain` when the CPU plays);
a hazard = `hazard` (fire wave, Shiranui, Ennetsu pillars, South's grab, ground-line looks); a South
hand (a skeleton's arm clawing out, a look) = `hazard transform model`. "Human or CPU" is only "has a `brain`": the brain writes the same
`pilot-vpad` the keyboard does. Key slots: `fighter-state` (`:idle :guard :guard-hit :step :run :hoho
:move :stun :air :down :wakeup :cine :intro :win :lose`), `fighter-sf` (frame in state),
`fighter-phase` (a move's `:hold :aura :dash :main`), `fighter-move` (a MOVE of the current
kit), `fighter-kit` / `fighter-form`, `fighter-contact` (`:hit` / `:block` / NIL), `fighter-burst` (a Burst
pressed this step, applied at the end of `fighter-system`), `fighter-invuln` (frames);
`gauges-reishi konpaku reiatsu awaken meter form-left` and the results stats.

## Characters as data (`kit.lisp`)

`(defmove :name :kind … :startup :active :recovery :dmg :adv-block :reach :arc … :on-frame ((f
hook)) :params (…))` and `(defkit :character :form :inherit … :commands (…) :grid (…) :strings (…) :ai (…))`
(the keys are documented in the two macros' docstrings; `:grid (J1 J2 J3 K1 K2 K3 J2s K2s)` is a form's J / K strings,
`defmove-copy` makes the switched link 2, DUEL_STRINGS.md). A form may `:inherit` another and derive
its moves (`:startup-add`, `:reach-mult`). Hooks are symbols called with FUNCALL (the kits load
before the hook DEFUNs). `*ROSTER*` lists every character with a `:base` kit, in load order; the
select screen cycles through it.

## Debug commands (`Module._debug_cmd(N)`, `debug.lisp`)

The first command turns on the combat log (`*combat-log*`) and the 2 s stats line. Arguments are
encoded in the integer.

| N | Effect |
|---|---|
| 2000+s | seeded CPU vs CPU now (NORMAL), both characters drawn from seed s (s < 100) |
| 3000+s / 4000+s / 5000+s | the same with a fixed pairing: YY / YK (P1 Yamamoto) / KK (s < 1000) |
| 2100 | toggle: skip every cinematic |
| 2101 | the next match starts with 2 Konpaku each (smoke runs) |
| 2102 | toggle turbo: up to 120 steps per frame, no scene drawn |
| 2103 | toggle the hitbox overlay: hurt cylinders (green), open melee windows (the volumes + a reach line, red), hazards (orange) |
| 2104 | toggle the CPU intent overlay (intent, current action, heat) |
| 2105 | toggle both CPUs off |
| 2106 | toggle the engine's perf log |
| 2107 | log both fighters' state (a hash line) |
| 2108 | fill both fighters' Reiatsu |
| 2109 | toggle the CAMERA option (BEHIND / SIDE; the behind camera is VS CPU's): `duel camera …` line |
| 2110+p | the seed gate: seeds 1–20 of pairing p (0 YY, 1 YK, 2 KK, 3 all three) back to back, turbo, cinematics on, combat log off; then `duel gate …` lines |
| 2120+k | toggle drawing part k off (0 HUD, 1 fighters, 2 stage, 3 hazards + cinematic looks): perf bisection |
| 2200+k | force cinematic k now and hold it at its hold frame: 0 Bankai, 1 Nozarashi, 2 Jokaku Enjo, 3 Tenchi Kaijin, 4 Kenpachi's Kikon, 5 sky split, 6 Soul Break, 7 intro, 8 K.O. |
| 2209 | a K.O. of P2 (Yamamoto vs Kenpachi): the K.O. cinematic, then the results screen (the 勝 card) |
| 10000+1000k+f | stills: cinematic k (as 2200+k) held at frame f with the effects frozen there (impact frames, particles, stamps); a later command for the same k continues it to its new f (`tests/style-4-shots.py`) |
| 2300+k | force a special now: 0 Hellfire + Ennetsu, 1 full Shiranui, 2 fire wave, 3 South (the bind) on Kenpachi 5 m away, 4 KYOKUJITSUJIN (the down-cut) at 6 m, 5 Split the Meteor, 6 Guard Break, 7 perfect Hoho, 8 Kenpachi's stance, 9 Buttagiru, 10 Kenpachi's SP2 flurry, 11 EVOLUTION for both, 12 Bankai (East) form, 13 Nozarashi form (cup 1), 14 P2 red (Reishi 200), 15 Nozarashi cup 2 (RYOTE, NOME 70), 16 cup 3 (NOMIHOSE, NOME 100) |
| 2315+k | frame probe, YY at 2 m: P1's move k (0 J1, 1 K3 (−20, entered at f8), 2 J3 (−4), 3 Taimatsu) into P2's held guard → `duel probe … advantage A (table T)` |
| 2319 | trade probe: both J1 on the same step → `duel probe trade …` hash line 40 steps later |
| 2320 | Burst test: human P1 Yamamoto (3 bars) 2 m from Kenpachi, whose switched-off CPU mashes Quick for 60 steps (J1 J2 J3); press Shift+J after the 2nd hit |
| 2321 | force a Burst Reverse now (P1 two hits into Kenpachi's string): screenshots |
| 2327 | guard gauge test: human P1 Yamamoto 2 m from Kenpachi, whose switched-off CPU presses Quick every other step for 20 s (both put back 2 m apart when he is free beyond 2.6 m, a `duel probe pressure t=… gg …` line each time); hold U: BLOCKED ×n (GUARD HOLD: no refill while he holds it), `P1 GUARD CRUSH`, hits land although U is held, `P1 GUARD BACK` (the guardless refill runs although U is held), blocked again — `duel-gauges.json` |
| 2328 | consing of the HUD's guard (steel, and the dimmed ember Bankai bar), flash-step, cooldown and NOME bars (100 draws each): `hud consing: … 0 B`; of Nozarashi's cup-3 aura and the rift (in the `vfx consing` line); and of the Bankai stance looks (10 draws each: West's flame garb, the bound ash, the heat sheet, KYOKKŌ's ray, South's crack, the aura crossfade): `vfx consing (10 draws, B): garb 0, …` (0 B each; the crossfade conses ~60 B a frame only during its 350 ms) |
| 2329 | consing of the brush captions (100 draws of each layout: cinematic, card, callout, results), the impact splash, the dutch roll and a brush Latin line: `brush consing (100 draws, B): cine 0, card 0, callout 0, results 0, splash 0, roll 0, line 0` |
| 2330+k | O module test: human P1 with module k mod 4 (0 ENJO, 1 TENCHI, 2 CHARGE, 3 LEAP CLEAVE) 1 m inside its reach from a Yamamoto CPU who, by k div 4: 0 stands, 1 holds guard, 2 stands red (Reishi 200), 3 holds guard red, 4 plays (HARD), 5 stands in 0.1× slow motion for 14 s (shots), 6 stands and holds guard once hit (the dash-in is BLOCKED), 7 the same red (the dash-in can't be guarded: the Kikon); press O (hold it, or tap it) — `duel-kikon.json` |
| 2370+k | Bankai stance test (human P1, P2's CPU off; `duel-stances.json`; DUEL_YAMA_REWORK.md): 0 East vs Kenpachi 3 m (L = KYOKKŌ; then U → West, L = SHŌNETSU JIGOKU, J drops to East), 1 East J strings into a guard the probe keeps full (`duel probe wall … P1 gg … P2 r…`: P2 loses the pierce's chip, 57 a string at a full gauge; P1's gauge stays full), 2 West's ward under Kenpachi's Quick mash (`duel probe ward … P1 gg … FORM …`: 31 a string (28 × 1.1), no blockstun, never refilled; GUARD CRUSH on the 4th string, `P1 WARD BROKEN`, East and guardless), 3 / 4 East Shift+K into a guard at 2 / 6 m, 5 West Shift+K with Kenpachi's F1 started as the parry opens (P1's gauge at 40: the catch refills it; the counter), 6 East Shift+L on Kenpachi 3 m, 7 / 8 human Kenpachi under a CPU East's South at 5 m (8 in 0.25× slow motion for 6 s), 9 West's ward vs ranged hits (the `:ranged` probe: a cup-3 Kenpachi 4.8 m away casts KUKAN-GIRI's rift twice (blocked), the cash-out (a Guard Break within 6 m: the ward breaks), then cup 1's Meteor, then the Meteor at 3 m; `duel probe ranged t=… P1 r… gg … STATE`) |
| 2380+k | Nozarashi v2 / West ward test (`nome-test`, human P1, P2's CPU off; `duel-nome.json`): 0 the ladder (the probe raises NOME +12 every 45 steps to 100, then lets it drain: `duel probe nome t=… m… FORM` every 30 steps, cups up then down), 1 DRINK (cup 3, U held, Bankai East mashes Quick: `duel probe drink … gg … m …`), 2 / 3 KUKAN-GIRI's rift into a guard / on a standing Yamamoto (K, K K), 4 the cash-out (cup 3, Shift+K into a red Yamamoto's guard at 4 m, then O held: a 2-Konpaku Kikon), 5 West's ward under RYOTE's K K (`duel probe cut … gg …`: the cut ×1.1, 53 a string, GUARD CRUSH on the 2nd → East) |
| 2362+k | Phase 5 looks (force-special 62+k): 0 Taimatsu (YK 4.5 m), 1 Nadegiri (forced Hellfire, 5 m), 2 Yamamoto's Breaker (Ikkotsu, 6 m), 3 Kenpachi entering cup 3 (NOMIHOSE, the rung event: the page, the grin with the head thrown back) |
| 2390 | consing of the Phase 5 looks (10 draws each: fireball, charge, pillar, dome, the Hellfire / Evolution / Breaker auras and ring, the garb flare, the rift, a spent wave's erosion, the Phase 5 stamps, the face / beat / move-beat choices): `vfx5 consing (10 draws, B): fireball 0, …` (0 B each) |
| 2366 | Phase 6 destruction still (looks only): YK 4 m apart, a scorch under Kenpachi, a crack and a burst of rubble chips beside him; Yamamoto shouts and Kenpachi is hurt for 0.6 s (face beats: both gameplay face accents) |
| 2391 | consing of the Phase 6 looks (10 draws each: the marks and chips with both pools full, a pillar and a fire wave beside the lens, the Nozarashi skull, the K.O. rain, both face accents, the face-change note, the left-hand grip step + IK, a caption slicing out): `vfx6 consing (10 draws, B): marks 0, …` (0 B each) |
| 2392 | the left fist's gap to the cleaver's handle over every grip clip (the RYOTE kendo set, KUKAN-GIRI, the stance) and every grip-clip → grip-clip crossfade, keys only and with the draw's `GRIP-LEFT!` (P1 must be Kenpachi, e.g. after 2383): `grip <clip> (raw/IK mm): …` per frame, `grip drift: raw max … mm, IK max … mm` |
| 2114+p | the seed gate of 2110+p with the combat log kept and a `pace t=… \| FORM m… r… g…[!] k… w…` line every 60 ticks per side (scratchpad `pace.py` reads it: cup times, stays, the Bankai gauge, scorches) |
| 2393 | the string test: the running match's fighters 2.2 m apart, facing, idle, nothing held (a switched-off CPU lets go of its guard): the scripts' string + O ender (`duel-touch.json`) |
| 2394+k | the string test (DUEL_STRINGS.md; `duel-strings.json`): human P1 in form k (0 Yamamoto Shikai, 1 Bankai East with his guard gauge at 30: KŌSEI ×2.4 on the HUD, 2 Kenpachi base, 3 RYOTE with NOME at 60) 2.2 m from an idle Kenpachi (CPU off); the script presses J / K / O |
| 24000+k … 29000+k | the strings' seed-gate knobs without a rebuild (before 2113): `*ai-o-ender*` = k / 100 (24000), NORMAL's `*ai-follow-guard-p*` = k / 100 (25000), every K2 / K3 (and copy) deals k % of its written damage (26000), `*kosei-reiatsu*` = k / 100 and `*kosei-fs*` half that (27000), `*ai-string-flash-p*` = k / 100 (28000), `*ai-sp-cancel-p*` = k / 100 (29000) |
| 2400 | toggle god mode: each step both fighters' Reishi is raised to at least 400 |
| 2500+k | human P1 vs an idle CPU, cinematics skipped: 0 Yamamoto vs Kenpachi, 1 Kenpachi vs Yamamoto, 2 YY, 3 KK |
| 2600+k | `*red-threshold*` = k % (pace the gate without a rebuild) |

Most scenario commands (2200–2319) first make sure the right battle runs (`ensure-battle`: a new
match with its intro skipped and P2's CPU switched off) and then place the fighters a few metres
apart (`place`).

## Log lines

| Line | From |
|---|---|
| `duel -> TITLE` … `duel -> RESULTS` | every flow change (`set-flow`) |
| `duel match seed 7 CPU-CPU YAMAMOTO vs KENPACHI NORMAL` | a match starts |
| `duel hash t=600 \| x y z yaw STATE FORM r<reishi> k<konpaku> a<reiatsu> f<flash-step> g<guard>[!] w<awaken> m<meter> n<kikon> h<heat> \| … \| cd <P1 cooldowns> <P2> \| haz N` | every 600 battle steps: positions in cm, yaw in 0.01 rad, gauges (`!` = guardless; m = Inferno or NOME, the FORM = Nozarashi's cup), n = the Konpaku the last Kikon rush was worth, CPU heat, each command slot's cooldown, hazard count (the determinism check) |
| `duel -> RESULTS winner P1 konpaku 7-0 ticks 7351 secs 122.5` | the match result (winner, Konpaku P1-P2, sim steps, seconds) |
| `duel gate YAMAMOTO KENPACHI: 20 matches, KOs 20, median … s, min …, max … \| …` | the seed gate summary |
| `duel probe YA-J1 blocked: attacker free at +27, defender at +25, advantage -2 (table -2)` | a frame probe |
| `[  tick] P1 move YA-J1 [why]` (the CPU's why: `STRING`, `O-ENDER`, `J-BEATS-K`, `PRESSURE`, …), `P1 YA-J1 -> P2 HIT 38`, `P1 YA-KIKON -> P2 KIKON 70` (a rush strike that became the Kikon; `BLOCKED` / `HIT` otherwise), `P1 KIKON FOLLOW-UP on P2 [(red)]` (it hit with O held: the knockback and the dash-in), `P1 BURNOUT RECOIL` (… `BLOCK` / `ARMOUR` / `BREAKER`: a Bankai stance's gauge ran out) and `P1 GUARDLESS BLOCK` (any gauge, by cause), `P1 form BANKAI-WEST` (the L switch), `P1 refused SIG: cooling 61` (a press while it cools), `P2 scorched 15` (West's armour / parry), `P1 BIND -> P2 HIT 40` (South's grab), `P1 KIKON on P2: -2 konpaku, 7 left`, `P1 GUARD CRUSH` / `P1 GUARD BACK`, `P1 form HELLFIRE`, Nozarashi's cups `P1 form RYOTE` / `NOMIHOSE` / `NOZARASHI`, `P1 DRINK 21 (+20 drunk)`, `P1 GUARD CRUSH (drinking)`, `P1 RIFT -> P2 HIT 50`, `P1 RIFT CLOSED`, `P1 CASH-OUT` (why `CASHOUT-PUNISH` / `-NEAR` on the move line), `KIKON on P2: -3 konpaku, 6 left (RYOTE)` (the attacker's form), `P1 PERFECT HOHO`, `P1 EVOLUTION`, `CLASH`, `cine NAME`, `P1 step [why]` / `P1 dash [why]` (a run starts; why DASH / DASH-BACK for the CPU) / `P1 run -> YA-Q1, carry 1.0 m` / `P1 BURST` / `hoho` / `guard` | the combat log (`clog`, components.lisp): move starts (with the CPU's reason), every applied hit and its result, Konpaku, forms, events |
| `duel camera CAMERA  SIDE` | the CAMERA option changed (menu or 2109) |
| `missing clip :name` | once per clip name the art lacks (the stance plays instead) |
| `stats: fps … cons/frame … draws … particles … \| ms/frame sim … queue … render … \| BATTLE t … p1 STATE reishi p2 … \| heap … MB \| fx-dropped N` | the engine's 2 s stats line plus the duel's tail |

## Test scripts (`tests/scripts/duel.py`)

`python3 tests/scripts/duel.py` writes `tests/scripts/duel-*.json`; run each with
`node tools/run.mjs dist/duel --secs N --script tests/scripts/duel-X.json` (headless Chrome,
SwiftShader WebGPU). Every script waits 9 s for startup.

| Script | --secs | What it does / what to check |
|---|---|---|
| `duel-cvc-yy.json`, `-yk`, `-kk` | 40 | turbo + seeded CPU vs CPU (debug 2102, then 3007 / 4007 / 5007): reaches `duel -> RESULTS winner …` in a few seconds; the determinism reference (below) |
| `duel-gate.json` | 1100 | debug 2113 (all three pairings × 20 seeds), then 2107 to turn the combat log back on: three `duel gate` lines, every match a K.O. |
| `duel-probe.json` | 20 | debug 2315–2319: each `advantage` must equal its `table` value; the trade line shows the same Reishi on both sides |
| `duel-keys.json` | 40 | P1's keyboard against an idle CPU (2500): log lines `P1 move YA-J1`, `YA-J2`, `YA-J3` (it walks in with W: VS CPU's behind camera, then 2393 puts him 2.2 m out, since a string needs contact), `YA-K1`, `YA-K2` (the second K latched during K1), `YA-SIG`, `YA-BREAKER`, `P1 guard`, `P1 step`, `P1 move YA-SHIRANUI`, `P1 hoho`, then SP2 (the K hits' Inferno and the full Shiranui make it Hellfire's `YA-NADEGIRI`), in that order; plus `P1 WAVE -> P2 HIT 110` and `P1 FIREBALL -> P2 HIT …` |
| `duel-extras.json` | 45 | P1's keyboard, VS CPU (behind camera): hold Space + W (`P1 step`, `P1 dash`), again with J out of the run (`P1 run -> YA-J1, carry 1.0 m`), Shift+Space (`P1 hoho`: the camera swings round), 2320 + Shift and J taps (`P2 KE-J2 -> P1 HIT`, then `P1 BURST`), 2321 (a forced Burst), pause → CAMERA → SIDE (`duel camera CAMERA  SIDE`). Shots `tests/shots/duel-extras-*.png`: behind, dash, hoho-a / -b, burst-a / -b, pause, side |
| `duel-kikon.json` | 170 | the O modules and the O rule by keyboard (2109 = the side camera, then 2330+k): each module in slow motion with O held on a standing opponent → `-> P2 HIT 70`, `KIKON FOLLOW-UP on P2` (the knockback and the dash-in), `-> P2 KIKON 70`, its cinematic (shots `tests/shots/duel-o-{enjo,tenchi,charge,leap}-{a,b,c,d,e}.png`: the aim, the lane / flash step / charge / leap, the strike, the dash-in, its strike); guarding, not red → `BLOCKED`; guarding **red**, O held → `BLOCKED`, no Kikon (the first strike is always guardable); red, standing → `HIT`, `FOLLOW-UP`, `KIKON`; the HARD CPU guards; not red, guarding once hit → `HIT`, `FOLLOW-UP`, `BLOCKED`; **red**, guarding once hit → `HIT`, `FOLLOW-UP (red)`, `KIKON`; O tapped on a red one → a plain `HIT` |
| `duel-gauges.json` | 52 | 2327 with U held (the guard gauge drains 24 per J J J string, `GUARD CRUSH` on the 5th, `HIT` while U is held, `GUARD BACK` about 17 s of ticks after it emptied: 1 s + 15.4 s of refill at 6.5/s, plus the hitstops); 2500 + Shift+Space ×4 (three `P1 hoho`, the 4th refused: flash-step 23); 2500, a Hoho, 2320 + Shift+J → `P1 BURST` (flash-step 70 → ~0). Shots `tests/shots/duel-gauges-*.png` |
| `duel-stances.json` | 70 | the Bankai stances by keyboard (2370+k, the side camera): L → `P1 move YA-E-KYOKKO`, `-> P2 HIT 85` (the log shows the base: 162 at a full gauge); U → `P1 form BANKAI-WEST`, L → `P1 move YA-W-SHONETSU`, `P1 PILLARS -> P2 HIT 45`, J → `P1 form BANKAI-EAST`, `P1 move YA-E-J1`; East J J J strings into a full guard → `BLOCKED`, P2's Reishi falls 51 a string (the pierce), P1's gauge stays 100; West's ward under Kenpachi's J J J → `BLOCKED` without blockstun, 26–27 a string, `P1 GUARDLESS BLOCK`, `P1 form BANKAI-EAST`, `P1 WARD BROKEN`, `P1 GUARD CRUSH` on the 4th, then `HIT`; (2379) the rifts `BLOCKED`, the cash-out `GUARD-BREAK` + `WARD BROKEN`; Shift+K at 2 m → `YA-KYOKU -> P2 GUARD-BREAK 90`, `-> P2 HIT 130`, at 6 m → `BLOCKED 130` only; West Shift+K → `KE-F1 -> P1 PARRIED 70`, `YA-W-COUNTER -> P2 HIT 150`, the gauge back to 100; Shift+L → `P1 BIND -> P2 HIT 40` exactly 16 f after the stab, J J → hits 3–4; as the bound Kenpachi Shift+J → `P1 BURST`; a Step in the tell → no `BIND` line. Shots `tests/shots/duel-yama-{kyokko,west-ward,shonetsu,ward-block,ward-crush}.png` (the rework) and `tests/shots/duel-stance-*.png` (east-idle, kyoku-break, kyoku-cone, kyoku-far, parry, counter, south-tell, south-bound, south-victim, south-burst, south-step) |
| `duel-nome.json` | 90 | Nozarashi v2 and West's ward by keyboard (2380+k, the side camera): the ladder probe (`m` 38 → 100 and back; `P1 form RYOTE` at 40, `NOMIHOSE` at 100, `RYOTE` below 50, `NOZARASHI` below 25); DRINK (`P2 YA-E-J1 -> P1 BLOCKED 34`, `P1 DRINK 17 (+17 drunk)` plus the East pierce's chip on top, … `P1 GUARD CRUSH (drinking)`); the rift (`KE-N-F1 -> P2 BLOCKED 90`, 20 f later `RIFT -> P2 BLOCKED 50`; on a standing target `HIT 90`, `RIFT -> HIT 50`, and K K `KE-R-K2 -> HIT 68`); the cash-out (`CASH-OUT`, `form NOZARASHI`, `KE-METEOR-N -> P2 GUARD-BREAK 390`, then O: `KIKON on P2: -2 konpaku`); West's ward under RYOTE's K K K (`KE-R-K1 -> P1 BLOCKED 85`, `KE-R-K2 … 68`, `KE-R-K3 … 92`, 76 of the gauge a string, `GUARD CRUSH` and `form BANKAI-EAST` on the 2nd). Shots `tests/shots/duel-nome-*.png` |
| `duel-strings.json` | 40 (`--fixed-dt 16.666667`) | the J / K strings by keyboard (2394+k, DUEL_STRINGS.md): Shikai J J J + O → `YA-J1`, `YA-J2`, `YA-J3`, `YA-KIKON` (O-ENDER: no aura, the strike 20 f after the press) `-> P2 HIT 70`; East K K K → `YA-E-K1`, `YA-E-K2`, `YA-E-K3` (the HUD's `攻 x2.2`: his gauge at 30); Kenpachi J K K + O → `KE-J1`, `KE-K2S`, `KE-K3`, `KE-KIKON`; RYOTE J J J and K K J → `KE-R-J1 J2 J3`, `KE-R-K1 K2 J3`; J J J → the kick; **J K J → `KE-J1`, `KE-K2S` and nothing more** (the third press eaten: J / K switch once). Shots `tests/shots/duel-string-{sodebi,o-ender,rakujitsu,tsuki,kick}.png`; the new clips' strips `duel-string-<clip>.png` come from `duel-view-strings.json` (dist/duelview) |
| `duel-flow.json` | 34 | the menus by keyboard: VS PLAYER (P2 confirms with KP1), skip the intro, pause / resume, pause → CHARACTER SELECT → back to TITLE, then VS CPU HARD; check the `duel ->` lines; shot `duel-flow-vs-cpu-hard.png` |
| `duel-perf.json` | 75 | 60 s of real-time CPU vs CPU (4003): the stats lines |
| `duel-shots.json` | 90 | the screenshot set `tests/shots/duel-*.png`: title, mode, select, intro, neutral, hit, guard break, perfect Hoho, Hellfire, fire wave, Shiranui, Kaka, Meteor, the six cinematics, results, the HUD at 800×450 |

Screenshots stall a script by ~0.5 s, so keys pressed right after one can arrive in the same frame
as their release and be lost; keep shots out of timed key sequences.

Stills of the Bankai rework (KYOKKŌ's ray, the ward raised, SHŌNETSU JIGOKU's ring, the ward under a Quick mash, the
broken ward back in East): `tests/shots/duel-yama-*.png`, from `duel-stances.json` (2370, 2372). (Guard v3's garb stills
`guard3-*.png` were removed with the garb.)

Stills of the Kenpachi batch (the awakening without an eyepatch, the three cups, DRINK, the rift, the cash-out, West's
hold-U armour, the run facing the opponent): `python3 tests/batch-shots.py` → `tests/shots/batch-*.png` and the contact
sheet `batch-sheet.png`.

Galleries (test targets, not the game; build lines in their headers): `tests/duel-view.lisp`
(bodies, weapons, clip strips, stage, every sound; `tests/scripts/duel-view.py`; scene 5 = 2005 lines up both
fighters' three expressions, 6300+k sets every actor's face: 0 neutral, 1 shout, 2 hurt; 7000+k shows grip clip k's four
worst-drift frames, each as a pair: keys only, then with the game's left-hand grip) and
`tests/duel-vfx.lisp` (every effect plus a worst-case scene; `tests/scripts/duel-vfx.py`).
Restyle Phase 5 stills: `python3 tests/style-5-shots.py` (the redone effects, the kendo and re-authored clips, the
expressions, before / after the previous build), `python3 tests/style-5-checks.py --run dist/duel` (3 expressions per
fighter, the Jokaku manga page, callouts clear of the HUD at 1280x720 and 800x450, 0 B for the new looks).

## Determinism

The same seed replays the same match: all gameplay randomness is `sim-rnd01` drawn inside fixed
steps (seeded by `start-match`), devices are read inside the step, the human stick is converted
through the sim-owned view (not the lagging render camera), hitstop and slow motion skip whole
steps, and cinematics run on the step clock. The camera choice cannot change a CPU match: CPU
pilots never read the view, and the view humans steer by is sim state for both cameras.

A match also starts from nothing of the one before: `spawn-pair` makes new entities (fighters,
vpads, brains; hazards gone) and clears hitstop / slow motion (`time-reset`), and `start-match`
reseeds the sim stream and zeroes `*match-tick*`, the timer and the slow-motion clock
(`reset-slow-clock`). That last one was a real leak: a perfect Hoho's slow motion leaves a
fraction in `*slow-acc*` (0.13, 0.5, 0.75, 0.88 ...), which used to carry into the next match and
shift the steps of its first slow motion, so a gate pairing gave other times when other matches
ran before it (KK alone median 135.8 s, after YY and YK 140.8). Check: each pairing's gate alone
(2110 / 2111 / 2112) gives the same per-seed `duel -> RESULTS` lines as inside 2113, and a seed
run fresh gives the same combat log as after a gate.

Reference (YK, seed 7, `duel-cvc-yk.json`):

```
duel -> RESULTS winner P2 konpaku 0-3 ticks 7123 secs 118.7
```

(The J / K strings, the O ender and KŌSEI, 2026-09-27 (DUEL_STRINGS.md): every pairing's lines changed; before them
`winner P1 konpaku 2-0 ticks 7688 secs 128.1`. The Bankai rework and the slower guard refill, 2026-09-27 (DUEL_YAMA_REWORK.md): every pairing's lines changed; before
it `winner P2 konpaku 0-4 ticks 9305 secs 155.1`. Guard v3, 2026-09-26: Reishi 1300, GUARD HOLD, Bankai's fed flame, West's garb guard and ranged armour, K3 and
`*bankai-taken*` 1.2 change every pairing; its follow-up the same day (Bankai drains ×1.3, East feeds 0.05, the blade /
line split) keeps this line and KK's, and changes YY and YK's hash lines; before it `winner P1 konpaku 7-0 ticks 7351 secs 122.5`, turbo and real
time alike. The Kenpachi batch, 2026-09-26: West's hold-U armour changed YY and YK (KK stayed identical), Nozarashi v2 changed YK
and KK (YY stayed identical once the hash line's new `n` field is set aside), the run facing the opponent changed none of
the three; before it `winner P2 konpaku 0-3 ticks 8594 secs 143.2`. User review 3 of the restyle lengthened the Kikon and awakening cinematics: the same match, every event later by the
cinematic frames added before it. With the ~1.45× slow-down alone it was `ticks 8384 secs 139.7`, before it `ticks 8054
secs 134.2`; before the Bankai stances, the Kikon dash-in and the slower guard refill it was `winner P1 konpaku 1-0
ticks 9438 secs 157.3`; before the gauges, the O rule and the O modules `winner P1 konpaku 2-0 ticks 9780 secs 163.0`;
before the Kikon rush `winner P2 konpaku 0-1 ticks 7298 secs 121.6`; before Bankai became
permanent, `winner P2 konpaku 0-4 ticks 5857 secs 97.6`; before Burst and the dash, `0-7 ticks
5302 secs 88.4`.)

To verify, run the script twice (or once without turbo: drop the 2102 step; real time takes
~90 s of sim) and compare every `duel` line:

```sh
node tools/run.mjs dist/duel --secs 40 --script tests/scripts/duel-cvc-yk.json > a.log
node tools/run.mjs dist/duel --secs 40 --script tests/scripts/duel-cvc-yk.json > b.log
diff <(grep '^duel' a.log) <(grep '^duel' b.log)          # empty
```

Any change to the rules, the AI, a kit or a tuning knob changes the reference; a change that
should not (a refactor, an engine move) must keep it and all thirteen `duel hash` lines identical.
`tests/style-cvc-ref.txt` holds all three pairings' result and hash lines (`python3
tests/style-gates.py cvc dist/duel` compares them).
The harvest was checked this way after each step.

## Pacing gate

`duel-gate.json` (20 seeds × pairing, NORMAL, turbo, cinematics included in the match time).
Target: every match ends by K.O. (before the 300 s timer), **median 125–210 s** per pairing (125–180 s until guard
v3: Reishi 1100 → 1300 is the user's decision 2026-09-26, because real human matches run much faster than CPU vs
CPU), win rates near even (YK within ±3 of 10 / 10). The gate runs ~15 min of turbo now: `--secs 1100`.

| Pairing | Median | Range | K.O. | Wins P1 / P2 |
|---|---|---|---|---|
| Yamamoto vs Yamamoto | 129.4 s | 97.7–165.1 | 20/20 | 9 / 11 |
| Yamamoto vs Kenpachi | 137.3 s | 77.0–196.1 | 20/20 | Yamamoto 10 / Kenpachi 10 |
| Kenpachi vs Kenpachi | 130.4 s | 97.4–172.0 | 20/20 | 7 / 13 |

(The J / K strings, the O ender and KŌSEI, the user's decisions 2026-09-27: K2 / K3 at 80 %, the CPU's string K 0.3,
O ender 0.15, SP cancel 0.3 (one roll), chosen by runtime sweeps (debug 24000–29000 before 2113; DUEL_STRINGS.md §10
has them). As designed the medians were YY 106.8 / YK 119.0 / KK 121.7 s. Before the strings: YY 128.6 s (88.2–160.2)
14 / 6, YK 129.9 s (96.3–153.2) Yamamoto 10 / 10, KK 169.2 s (111.9–196.9) 15 / 5.)

(The Bankai rework and the slower guard refill, the user's decisions 2026-09-27: `*pierce-max*` 0.45 and `*ward-mult*`
1.1 chosen by runtime sweeps (debug 20000+k / 21000+k before 2113; DUEL_DESIGN §7 has the sweep). The win counts come
from the per-match `duel -> RESULTS winner` lines, in gate order YY, YK, KK. Before it, guard v3 with its follow-up:
YY 165.3 s (123.3–231.9) 11 / 9, YK 155.1 s (107.2–205.0) Yamamoto 7 / 13, KK 169.2 s (111.9–196.9) 13 / 7.)

(Guard v3's follow-up, the user's decision 2026-09-26: every Bankai drain ×1.3, East's feed 0.05, the blade / line
melee-ranged split; a deliberate nerf, no knob retuned. Before it: YY 181.8 s (135.5–230.4), YK 157.8 (115.2–194.9),
KK identical; wins 10 / 10, 8 / 12. YK seeds 21–40: Yamamoto 7 / 13 (was 9 / 11), so 14 of 40 (was 17). Bankai's
gauge mean 77 % (YK) / 82 % (YY); burnouts 8 in 20 YK matches, 2 in YY; the human proxy still reaches cup 3 while
Yamamoto has ≥ 4 Konpaku in 20 / 20.)

(Guard v3, 2026-09-26 (DUEL_DESIGN §12): the rules alone at Reishi 1300 and `*bankai-taken*` 1.4 gave YY 153.2, YK
143.8 (Yamamoto 7 / 13), KK 169.2; East's taken 1.3 YY 171.5, YK 157.4 (7 / 13); 1.2 is the table. Seeds 21–40 (a
build with the gate's seeds moved) for the balance read: Yamamoto won 6 / 8 / 9 of 20 YK at taken 1.4 / 1.3 / 1.2,
so 13 / 15 / 17 of 40. Usage (the logged gate, 2114+p): Kenpachi's first cup 3 28.2 s (YK) / 28.7 s (KK) after the
awakening, stays mean 6.4 / 6.7 s (max 12.0 / 18.9), cash-outs 47 / 118; Bankai's gauge mean 85 % (YK) / 89 % (YY),
1 burnout in YK, 0 in YY; West 48 % of Bankai time, scorches 57 (YK) / 143 (YY); ranged hits armoured by West: 6
cash-outs in YK, ~7 heat cones in YY. The human proxy (Kenpachi on HARD, the rush at 0.9 in every cup, no stance)
reaches cup 3 while Yamamoto has ≥ 4 Konpaku in 20 / 20 matches, YK median 161.2 s.)

(Before guard v3 (the Kenpachi batch): YY 148.9 s (114.7–219.2), YK 140.3 s (97.8–180.6), KK 154.1 s (106.8–170.0),
wins 11 / 9, Yamamoto 7 / Kenpachi 13, 8 / 12. The Kenpachi batch, 2026-09-26, each item measured on its own (no knob retuned): before it YY 158.7 s (95.5–223.2), YK
152.1 (115.2–185.2), KK 159.7 (128.8–197.4), wins YY 9 / 11, YK 6 / 14, KK 10 / 10; + the run facing the opponent: YY
161.0 (95.5–223.2), YK 155.6 (115.8–185.2), KK 159.7 (unchanged); + West's hold-U armour (Nozarashi v2 off): YY 148.9,
YK 142.9 (107.8–188.4, wins 9 / 11), KK 159.7; + Nozarashi v2 without ignore-armor: the table. Usage (YK / KK, 20
matches each): cup-3 stays mean 5.6 / 6.2 s (max 10.8 / 19.8), cash-outs 32 / 75 (about half connect), drinks 1 / 20,
rifts 7 / 15, West's armoured hits 33 in YK (52 in YY); DUEL_NOZARASHI_V2.md "Built" has the table. The gate runs close to
300 s now: give it `--secs 330`.)

(User review 3 of the restyle (STYLE_STORM_DESIGN §14) lengthened the Kikon and awakening cinematics: slowed ~1.45×,
then their caption close-ups held +30 f. The same 60 matches, each longer by the added cinematic frames. With the
slow-down alone: YY 155.2 s (93.5–219.7), YK 149.6 (112.7–181.7), KK 157.2 (127.0–194.9); before it, exactly the
table below: YY 150.4 s (90.9–214.9), YK 145.5 (108.1–176.2), KK 152.4 (122.2–190.1).)

(The Bankai stances with burnout, the Kikon dash-in, the guard gauge refilling at 12/s after 60 f
(guardless 14/s), the CPUs' guard pressure; no pacing knob retuned. Usage over the 60 matches (per
match): L switches 214 (3.6; YY 6.4, YK 4.3), guard crushes 13 (0.22), burnouts 8 (0.13, all by a
blocked hit: CPUs keep a stance's own recoil / armour inside the gauge by the `:gg-low` / `:armor-gg`
keys), parries 44 (39 caught a hit, 0.65), South casts 40 (0.67), binds landed 18 (0.30), Bursts out of
a bind 5, KYOKUJITSUJIN 44 (0.73), blocked hits 1086 (18.1; 8.5 before the guard pressure), armoured hits
142, Kikon dash-ins 352 (5.9; 351 on a red victim: the CPUs' non-red O pokes are guarded at the first
strike, so a non-red dash-in is rare: 1, and it was blocked), Kikons 299, Bursts 248, Hohos 242. Before
the guard pressure the CPUs made 0 guard crushes and 0 burnouts in 60 matches.
Before (the guard and flash-step gauges, Reiatsu 3/s, the O rule with its follow-up, the four O modules with
the CPU's non-red O pokes; no knob retuned. With the gauges alone (the old rush): YY 181.9 s
(137.7–281.7), YK 135.8 (101.8–154.7), KK 141.9 (117.4–159.6); the O modules brought YY back inside.
Usage over the 60 matches: 353 Hohos, 215 Bursts, 199 perfect Hohos, 532 O presses, 333 Kikons, 1
follow-up, 0 guard crushes: CPUs block ~7 hits a match and guard less as their gauge runs low, so the
guard gauge rarely empties between CPUs (the keyboard script shows it does against a turtling human).
Before (the Kikon rush): YY 153.4 s (118.8–181.4), YK 136.9 (106.3–165.3), KK 140.6 (114.0–157.1).
9 Konpaku, Reishi 1100, red 0.30, CPU Burst chance NORMAL 0.6, Bankai permanent, the Kikon rush
with the CPU's `*ai-kikon-p*` 0.5; each pairing gives the same times alone. Before the Kikon rush
(the instant Kikon after a hit): YY 144.2 s (109.2–203.4), YK 138.1 (110.8–179.6), KK 140.8
(107.9–163.2). Before, with a 20 s Bankai and the slow-motion leak: YY 134.2, YK 120.1,
KK 135.8 s; before Burst and the dash: YY 129.7, YK 106.9, KK 134.8 s; with Burst at 0.4: 131.3 /
107.4 / 137.9.) Usage per match (combat log of the gate before Bankai became permanent, both fighters): Bursts YY 1.4, YK 1.2, KK 2.2; dashes (runs) YY 5.3 (2.3 in, 3.0 back),
YK 4.9 (Kenpachi dashes in 1.9 per match, Yamamoto 0.8 in + 1.5 back), KK 2.4; moves out of a run
YY 1.9, YK 0.5, KK 0.2 (mostly Yamamoto's Signature / Shiranui once back in his zone); Hohos 4.5 /
3.2 / 2.5; moves 70 / 71 / 89.

## Performance (headless SwiftShader, `duel-perf.json`, 60 s real-time CPU vs CPU)

| Measure | Value | Budget (design §14) |
|---|---|---|
| consed per frame | 13.2 KB mean, 17.5 KB max (before the Bankai stances 14.1 / 17.5; behind camera, VS CPU: 14.0 / 15.9; guard v3, `duel-perf.json`: 12.5 / 15.3) | ≤ 60 KB mean, ≤ 150 KB worst |
| Lisp ms per frame | sim 0.29, queue 1.49, render 0.35 | — |
| draws | 45–46 | < 600 |
| live particles | 331 mean, 525 max | ≤ 1200 |
| `fx-dropped` | 0 | 0 |
| startup heap | 103.1 MB (wasm memory 153.6 MB) | ≤ 110 MB |
| frame rate | ~70 fps on this machine's SwiftShader | — |

## Host tests (no build, no browser)

```sh
E=/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl
$E --norc --load tests/duel-rules-test.lisp      # duel-rules-test: 1403 checks, ALL PASS
$E --norc --load tests/duel-control-test.lisp    # duel-control-test: 53 checks, ALL PASS
$E --norc --load tests/input-test.lisp           # input-test: 31 checks, ALL PASS  (engine vpad)
$E --norc --load tests/cine-test.lisp            # cine-test: 18 checks, ALL PASS   (engine director)
```

* **duel-rules-test** loads `tuning`, `rules`, `kit`, `yama`, `ken` over the engine's plain-CL
  `math`, `hitvol`, `input` (DEFCINE stubbed): the triangle and clash matrix; block / whiff
  advantage, including a frame-by-frame replay of every move of every form against its table;
  damage and combo scaling; the contact rule; armour budgets; the J / K strings (DUEL_STRINGS: every form's six routes
  walked from J1 / K1, the §2.1 budget on every reachable link: J1 / K1 frames, J beats K, K2 / K3 at S_eff 14, every
  link pair a combo on hit, the block gaps (K ≥ 11 f, J ≤ his own J1), J3 −4 / K3 −20 and its punish, the enders,
  whiff R + 8 / R + 12, the copies equal their originals, the O ender always combos off link 3; route resolution through
  `string-latch`: JKJ / KJK end at link 2, the last allowed press wins, an eaten press overwrites nothing, link 3 latches
  nothing; the contact gate at every frame; KŌSEI's `kosei-mult` / `kosei-gain`); the Kikon rush (its phases with each
  module's aura / dash, reaches and press → hit times, cooldowns, `kikon-outcome`: guarded → nothing,
  held → the dash-in whose hit is the Kikon, released → a plain hit; the dash-in's window for every
  module (a non-red victim free `*kikon-follow-gap*` frames first, a red one reeling through it), its
  guard (blocked not red, unguardable red), its speed; every form's rush punishable on block), Konpaku
  counts, Soul Break, time-up; the guard gauge (guard values, drain, crush advantage, the 5.5/s after
  60 f refill, guardless 6.5/s, GUARD HOLD: `gg-regen` guarding, `gg-idle-next` frozen not restarted; East's pierce
  `pierce-rate` and its hit / through-guard arithmetic, the ward never refilled) and
  the flash-step gauge (costs, regen, refund); Reiatsu 3/s; burns; Burst eligibility and the CPU's Burst rule; the run (stop, carry, brake, kit speeds);
  combo limits; the perfect-Hoho window; facing, movement and arena; AI helpers; hit
  volumes; kit sanity (every form's commands, costs and derived Nozarashi numbers); the Bankai stances
  (DUEL_YAMA_REWORK: the forms' numbers, U's `:guard-to`, West's `:drop-to` / `:keep` via `kit-drop`, the ward in
  `resolve-contact` (360°, a Breaker / guard-crush breaks it, unguardables through, a hazard in the parry window
  blocked), KYOKKŌ and SHŌNETSU JIGOKU, East's combos, the ender-gap rule, Kenpachi's strings against the ward,
  KYOKUJITSUJIN's blade / cone against a guard, the parry window and counter, South's bind: cooldown,
  follow-up window, unguardable, opener only, Burst-able, the Step / Hoho escape windows, `cast-point`); which windows
  are `:ranged` (a parry can't catch them); Reishi 1300; the run clip sets; Nozarashi v2 (DUEL_NOZARASHI_V2
  §2.13 1–11: `nome-gain`, `meter-drain`, `ladder-rung`, `drink-split` / `drink-adv`, `cut-value` (RYOTE's K K K: 69), the Kikon count and
  its cap, the register-kit parent-move rule, the three cups' tables and links, the rift's +8, the cash-out, the looks
  and the AI keys).
* **duel-control-test**: the buffer window, consume and holds; command priority and modifier
  combos (a refused command doesn't hide the next); stick and opponent-relative directions; a
  device read through the binding tables equals direct injection.
* **input-test** and **cine-test** check the engine modules on their own (buffering, modifier,
  flush / clear, command tables, bindings; AT / DURING, length, hold, skip / abort, hooks, shots).

RAVEN's host tests (`ecs-test`, `rules-test`, `test-math`) are listed in README.md.
