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
| Guard (hold) | U | KP4 | LB |
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
a hazard = `hazard` (fire wave, Shiranui, Ennetsu pillars, ground-line looks); a Kaka skeleton =
`hazard transform model`. "Human or CPU" is only "has a `brain`": the brain writes the same
`pilot-vpad` the keyboard does. Key slots: `fighter-state` (`:idle :guard :guard-hit :step :run :hoho
:move :stun :air :down :wakeup :cine :intro :win :lose`), `fighter-sf` (frame in state),
`fighter-phase` (a move's `:hold :aura :dash :main`), `fighter-move` (a MOVE of the current
kit), `fighter-kit` / `fighter-form`, `fighter-contact` (`:hit` / `:block` / NIL), `fighter-burst` (a Burst
pressed this step, applied at the end of `fighter-system`), `fighter-invuln` (frames);
`gauges-reishi konpaku reiatsu awaken meter form-left` and the results stats.

## Characters as data (`kit.lisp`)

`(defmove :name :kind … :startup :active :recovery :dmg :adv-block :reach :arc … :on-frame ((f
hook)) :params (…))` and `(defkit :character :form :inherit … :commands (…) :strings (…) :ai (…))`
(the keys are documented in the two macros' docstrings). A form may `:inherit` another and derive
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
| 2300+k | force a special now: 0 Hellfire + Ennetsu, 1 full Shiranui, 2 fire wave, 3 Kaka skeletons, 4 Kyokujitsujin, 5 Split the Meteor, 6 Guard Break, 7 perfect Hoho, 8 Kenpachi's stance, 9 Buttagiru, 10 Kenpachi's SP2 flurry, 11 EVOLUTION for both, 12 Bankai form, 13 Nozarashi form, 14 P2 red (Reishi 200) |
| 2315+k | frame probe, YY at 2 m: P1's move k (0 Q1, 1 Q3, 2 F2, 3 Taimatsu) into P2's held guard → `duel probe … advantage A (table T)` |
| 2319 | trade probe: both Q1 on the same step → `duel probe trade …` hash line 40 steps later |
| 2320 | Burst test: human P1 Yamamoto (3 bars) 2 m from Kenpachi, whose switched-off CPU mashes Quick for 60 steps (Q1 Q2 Q3); press Shift+J after the 2nd hit |
| 2321 | force a Burst Reverse now (P1 two hits into Kenpachi's string): screenshots |
| 2327 | guard gauge test: human P1 Yamamoto 2 m from Kenpachi, whose switched-off CPU presses Quick every other step for 20 s (both put back 2 m apart when he is free beyond 2.6 m, a `duel probe pressure t=… gg …` line each time); hold U: BLOCKED ×n, `P1 GUARD CRUSH`, hits land although U is held, `P1 GUARD BACK`, blocked again — `duel-gauges.json` |
| 2328 | consing of the HUD's guard and flash-step bars (100 draws each): `hud consing: … 0 B` |
| 2330+k | O module test: human P1 with module k mod 4 (0 ENJO, 1 TENCHI, 2 CHARGE, 3 LEAP CLEAVE) 1 m inside its reach from a Yamamoto CPU who, by k div 4: 0 stands, 1 holds guard, 2 stands red (Reishi 200), 3 holds guard red, 4 plays (HARD), 5 stands in 0.1× slow motion for 8 s (shots), 6 stands and holds guard once hit (a guarded follow-up); press O (hold it, or tap it) — `duel-kikon.json` |
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
| `duel hash t=600 \| x y z yaw STATE FORM r<reishi> k<konpaku> a<reiatsu> f<flash-step> g<guard>[!] w<awaken> m<meter> h<heat> \| … \| cd <P1 cooldowns> <P2> \| haz N` | every 600 battle steps: positions in cm, yaw in 0.01 rad, gauges (`!` = guardless), CPU heat, each command slot's cooldown, hazard count (the determinism check) |
| `duel -> RESULTS winner P1 konpaku 1-0 ticks 9438 secs 157.3` | the match result (winner, Konpaku P1-P2, sim steps, seconds) |
| `duel gate YAMAMOTO KENPACHI: 20 matches, KOs 20, median … s, min …, max … \| …` | the seed gate summary |
| `duel probe YA-Q1 blocked: attacker free at +27, defender at +25, advantage -2 (table -2)` | a frame probe |
| `[  tick] P1 move YA-Q1 [why]`, `P1 YA-Q1 -> P2 HIT 38`, `P1 YA-KIKON -> P2 KIKON 70` (a rush strike that became the Kikon; `BLOCKED` / `HIT` otherwise), `P1 KIKON FOLLOW-UP on P2` (it hit a non-red opponent with O held), `P1 KIKON on P2: -2 konpaku, 7 left`, `P1 GUARD CRUSH` / `P1 GUARD BACK`, `P1 form HELLFIRE`, `P1 PERFECT HOHO`, `P1 EVOLUTION`, `CLASH`, `cine NAME`, `P1 step [why]` / `P1 dash [why]` (a run starts; why DASH / DASH-BACK for the CPU) / `P1 run -> YA-Q1, carry 1.0 m` / `P1 BURST` / `hoho` / `guard` | the combat log (`clog`, components.lisp): move starts (with the CPU's reason), every applied hit and its result, Konpaku, forms, events |
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
| `duel-gate.json` | 300 | debug 2113 (all three pairings × 20 seeds), then 2107 to turn the combat log back on: three `duel gate` lines, every match a K.O. |
| `duel-probe.json` | 20 | debug 2315–2319: each `advantage` must equal its `table` value; the trade line shows the same Reishi on both sides |
| `duel-keys.json` | 32 | P1's keyboard against an idle CPU (2500): log lines `P1 move YA-Q1`, `YA-Q2`, `YA-Q3`, `YA-F1`, `YA-SIG`, `YA-BREAKER`, `P1 guard`, `P1 step`, `P1 move YA-SHIRANUI`, `P1 hoho`, `P1 move YA-TAIMATSU`, in that order (it walks in with W: VS CPU's behind camera; Q3's knockback puts P2 out of F1's reach, F1 whiffs, and the second K, 21 f later, expires before a whiffed move's chain window opens, so there is no F2, although the script's comment lists one); plus `P1 WAVE -> P2 HIT 110` and `P1 FIREBALL -> P2 HIT …` |
| `duel-extras.json` | 45 | P1's keyboard, VS CPU (behind camera): hold Space + W (`P1 step`, `P1 dash`), again with J out of the run (`P1 run -> YA-Q1, carry 1.0 m`), Shift+Space (`P1 hoho`: the camera swings round), 2320 + Shift and J taps (`P2 KE-Q2 -> P1 HIT`, then `P1 BURST`), 2321 (a forced Burst), pause → CAMERA → SIDE (`duel camera CAMERA  SIDE`). Shots `tests/shots/duel-extras-*.png`: behind, dash, hoho-a / -b, burst-a / -b, pause, side |
| `duel-kikon.json` | 150 | the O modules and the O rule by keyboard (2109 = the side camera, then 2330+k): each module in slow motion with O held on a standing opponent → `-> P2 HIT 70`, `KIKON FOLLOW-UP on P2`, `-> P2 KIKON 70`, its cinematic (shots `tests/shots/duel-o-{enjo,tenchi,charge,leap}-{a,b,c}.png`: the aim, the lane / flash step / charge / leap, the strike); guarding, not red → `BLOCKED`; guarding **red**, O held → `BLOCKED`, no Kikon; red → `KIKON` at once; the HARD CPU guards; guarding once hit → `HIT`, `FOLLOW-UP`, `BLOCKED`; O tapped on a red one → a plain `HIT` |
| `duel-gauges.json` | 52 | 2327 with U held (the guard gauge drains 28 per Q string, `GUARD CRUSH` on the 4th, `HIT` while U is held, `GUARD BACK` 4.75 s after it emptied); 2500 + Shift+Space ×4 (three `P1 hoho`, the 4th refused: flash-step 23); 2500, a Hoho, 2320 + Shift+J → `P1 BURST` (flash-step 70 → ~0). Shots `tests/shots/duel-gauges-*.png` |
| `duel-flow.json` | 34 | the menus by keyboard: VS PLAYER (P2 confirms with KP1), skip the intro, pause / resume, pause → CHARACTER SELECT → back to TITLE, then VS CPU HARD; check the `duel ->` lines; shot `duel-flow-vs-cpu-hard.png` |
| `duel-perf.json` | 75 | 60 s of real-time CPU vs CPU (4003): the stats lines |
| `duel-shots.json` | 90 | the screenshot set `tests/shots/duel-*.png`: title, mode, select, intro, neutral, hit, guard break, perfect Hoho, Hellfire, fire wave, Shiranui, Kaka, Meteor, the six cinematics, results, the HUD at 800×450 |

Screenshots stall a script by ~0.5 s, so keys pressed right after one can arrive in the same frame
as their release and be lost; keep shots out of timed key sequences.

Galleries (test targets, not the game; build lines in their headers): `tests/duel-view.lisp`
(bodies, weapons, clip strips, stage, every sound; `tests/scripts/duel-view.py`) and
`tests/duel-vfx.lisp` (every effect plus a worst-case scene; `tests/scripts/duel-vfx.py`).

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
duel -> RESULTS winner P1 konpaku 1-0 ticks 9438 secs 157.3
```

(Before the gauges, the O rule and the O modules it was `winner P1 konpaku 2-0 ticks 9780 secs 163.0`;
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
should not (a refactor, an engine move) must keep it and all fifteen `duel hash` lines identical.
`tests/style-cvc-ref.txt` holds all three pairings' result and hash lines (`python3
tests/style-gates.py cvc dist/duel` compares them).
The harvest was checked this way after each step.

## Pacing gate

`duel-gate.json` (20 seeds × pairing, NORMAL, turbo, cinematics included in the match time).
Target: every match ends by K.O., median 125–180 s, max 240 s.

| Pairing | Median | Range | K.O. |
|---|---|---|---|
| Yamamoto vs Yamamoto | 168.1 s | 148.5–204.3 | 20/20 |
| Yamamoto vs Kenpachi | 154.8 s | 122.4–175.9 | 20/20 |
| Kenpachi vs Kenpachi | 150.3 s | 116.7–177.1 | 20/20 |

(The guard and flash-step gauges, Reiatsu 3/s, the O rule with its follow-up, the four O modules with
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
| consed per frame | 14.1 KB mean, 17.5 KB max (behind camera, VS CPU: 14.0 / 15.9) | ≤ 60 KB mean, ≤ 150 KB worst |
| Lisp ms per frame | sim 0.29, queue 1.49, render 0.35 | — |
| draws | 45–46 | < 600 |
| live particles | 331 mean, 525 max | ≤ 1200 |
| `fx-dropped` | 0 | 0 |
| startup heap | 103.1 MB (wasm memory 153.6 MB) | ≤ 110 MB |
| frame rate | ~70 fps on this machine's SwiftShader | — |

## Host tests (no build, no browser)

```sh
E=/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl
$E --norc --load tests/duel-rules-test.lisp      # duel-rules-test: 430 checks, ALL PASS
$E --norc --load tests/duel-control-test.lisp    # duel-control-test: 53 checks, ALL PASS
$E --norc --load tests/input-test.lisp           # input-test: 31 checks, ALL PASS  (engine vpad)
$E --norc --load tests/cine-test.lisp            # cine-test: 18 checks, ALL PASS   (engine director)
```

* **duel-rules-test** loads `tuning`, `rules`, `kit`, `yama`, `ken` over the engine's plain-CL
  `math`, `hitvol`, `input` (DEFCINE stubbed): the triangle and clash matrix; block / whiff
  advantage, including a frame-by-frame replay of every move of every form against its table;
  damage and combo scaling; the contact rule; armour budgets; the Kikon rush (its phases with each
  module's aura / dash, reaches and press → hit times, cooldowns, `kikon-outcome`: guarded → nothing,
  red + held → the Kikon, not red + held → the follow-up whose hit is the Kikon, released → a plain
  hit; the follow-up's wait for every module; every form's rush punishable on block), Konpaku counts,
  Soul Break, time-up; the guard gauge (guard values, drain, crush advantage, regen, guardless) and
  the flash-step gauge (costs, regen, refund); Reiatsu 3/s; burns; Burst eligibility and the CPU's Burst rule; the run (stop, carry, brake, kit speeds);
  combo limits; the perfect-Hoho window; facing, movement and arena; AI helpers; hit
  volumes; kit sanity (every form's commands, costs and derived Nozarashi numbers).
* **duel-control-test**: the buffer window, consume and holds; command priority and modifier
  combos (a refused command doesn't hide the next); stick and opponent-relative directions; a
  device read through the binding tables equals direct injection.
* **input-test** and **cine-test** check the engine modules on their own (buffering, modifier,
  flush / clear, command tables, bindings; AT / DURING, length, hold, skip / abort, hooks, shots).

RAVEN's host tests (`ecs-test`, `rules-test`, `test-math`) are listed in README.md.
