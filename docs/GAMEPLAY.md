# RAVEN EDGE — Gameplay systems

(SOUL DUEL, the second game, has its own: `DUEL_GAMEPLAY.md`.)

Files (`game/lisp/`, MANIFEST order): data and rules first (`tuning`, `sounds`, `world`, `clips`,
`rules`, `moves`, `effects`), then the entity layer (`components`, `bodies`, `fighters`), the
systems (`combat`, `camera`, `player`, `enemy`, `projectiles`, `feedback`, `training`), the flow
and screens (`game`, `hud`, `debug`) and the frame (`main`). They sit on the engine's `ecs.lisp`,
`anim.lisp`, `time.lisp` and `fx.lisp` (`engine/lisp/`). The spec is `GAME_DESIGN.md`; its frame
data is authoritative and is copied as-is into the `defmove` tables. Background on the ECS /
rules / events split: ARCHITECTURE.md "Game structure", TUTORIAL.zh-TW.md steps 4–6 and 8.

## Time model
* `main.lisp` `ACCUMULATE-AND-STEP` runs **fixed 1/60 s steps** from real dt through the engine's
  `RUN-FIXED-STEPS` (time.lisp), at most 6 steps per frame. A longer backlog is dropped. Each step (`SIM-STEP`) runs `TIME-STEP` (engine time.lisp).
  It returns NIL during **hitstop** (`(hitstop n)`, the max wins). Then the whole sim is skipped
  while fx, shake, camera and UI keep running.
* `SIM-STEP` is the system list, in order: `player-system`, `enemy-system`, `projectile-system`,
  `separation-system`, `token-system`, `feedback-system`.
* **Slow-mo**: `(slowmo scale secs &optional others-only)` (others = the enemies). The lowest scale wins and it eases
  back to 1 over the last 0.1 s.
  `(slowmo-scale nil)` = player side (KP), `(slowmo-scale t)` = enemy side (KE).
* A fighter steps with **K = its time scale** (1.0 normally). `fighter-sf` (frames in state) advances by
  K, so frame numbers stay exact at K = 1. Events use "crossed frame N" tests. Seconds = `(* k +step+)`.
* Input presses are stamped with `*ptick*` (player time, 1/16 frames); the buffer is `*input-buffer*` (12 f).

## Entities and components (`components.lisp`, `fighters.lisp`)
Game objects are ECS entities (engine `ecs.lisp`). `components.lisp` defines every component and
lists the sets: REN = `transform motion model health fighter blade-trail player`; an enemy = the
same with `brain` instead of `player`; a training dummy adds `dummy`; a projectile =
`transform projectile`. Key slots: `transform-pos` (f32vec, m), `transform-yaw` (0 faces −Z),
`motion-vel`, `motion-grounded`, `motion-grav`/`grav-t`, `health-hp max-hp poise invuln alive`,
`fighter-state` (keyword), `fighter-sf` (frames in state), `fighter-phase`, `fighter-move` (current
MOVE), `fighter-target` (a handle), `fighter-crippled`, `model-flash` (real s), `model-hidden`
(joint bitmask), `brain-token`, `brain-cooldown`, `brain-block-chance`.
* `*player*` is REN's handle; `(pl)` is his `player` component (`player-raven`, `player-combo`, …).
* `(spawn-fighter body-name :x :z :yaw :team)` creates a fighter; `player-init`, `spawn-enemy` and
  `spawn-dummy` add their component. Visit fighters with `(do-entities (e fighter) …)`.
* Helpers every file uses: `pos-of`, `yaw-of`, `alive-p`, `enemy-p`, `state-of`, `body-of`,
  `kind-of`, `name-of`, `crippled-p`, `distance`, `face-toward`, `facing-p`, `turn-toward`,
  `fwd-x`/`fwd-z`, `yaw-to`, `downed-p`, `red-windup-p` (`turn-toward`, `fwd-x`/`fwd-z` and
  `yaw-to` are the engine's, math.lisp).
* Handles outlive their entities: a stored `target`, `owner` or `*boss*` may be dead; check
  `entity-alive-p` / `alive-p` before following one.

## Rig & animation (`anim.lisp`)
* 21 joints (§11.1), `(ji :hand-r)` gives the index at compile time. A pose is an f32vec of 68:
  `[3j]` flex, `[3j+1]` twist, `[3j+2]` side (radians), then root r u f (m), yaw, pitch.
* A joint's local rotation is **Rz(side)·Rx(flex)·Ry(twist)**: twist about the bone, then flex, then
  side, all in parent axes (§11.2). Left limbs mirror twist and side. Feet auto-level.
* `(defpose :name (:base :other) (group chan deg ...) ...)` and
  `(defclip :name (dur :loop t :base :stance) (time [:snap] [pose-name] (group chan val ...)) ...)`
  (all of them in `clips.lisp`).
  Groups are joints or the aliases `:arm-r :elbow-r :knee-l :arms :knees :thighs ...`, plus
  `:root` (`:r :u :f` m, `:yaw :pitch` deg). Every key starts from the previous key; `:snap` gives
  a linear strike.
* The spec's §11.4 arm angles make the blade point at the sky. Every attack key was re-solved so
  the **blade azimuth/elevation** matches the notes. The hand twist/flex values come from a small
  numeric FK mirror, `tools/pose-solve.py` (blade = weapon joint −Z).
  Do the same for new enemy clips (for example the `:rb-slash` notes).
* `(play-clip e :clip :blend frames :speed s :restart nil)` crossfades (attacks use 0 f).
  `pose-update` runs FK allocation-free into `model-joints` (21 × mat4).
  `(joint-point! out jm (ji :hand-r) x y z)` gives attachment points and
  `(blade-points! e base tip)` gives the blade.

## Body types (`bodies.lisp`)
```lisp
(defbody :needler (:scale 0.94 :width 0.85 :hurt-r 0.34 :hurt-h 1.7 :max-hp 45 :poise 5
                   :palette ((:suit #x262B4A) (:lens #x19E6FF)) :weapon nil)
  (:head (:bevel 0.2 0.24 0.22 0.03 :at (0 0.12 0) :c :suit)
         (:glow 3.0 (:box 0.06 0.06 0.02 :at (0 0.14 0.115) :c :lens) :eyes))
  (:lower-arm-l (:box 0.02 0.03 0.35 :at (0 -0.2 0.1) :c #xC8D0DA)) ...)
```
Shapes use the joint frame with `:at (right up fwd)` and `:rot (yaw pitch roll)`. A joint without
parts is not drawn. `:weapon (:katana len)` / `(:sword len #xRRGGBB)` go on `weapon_r` (blade
along −Z). `:hunch` adds spine flex. `bodies-init` (a startup step) builds every registered body
once after the GPU device is up. `draw-fighter` (fighters.lisp) makes one draw per part. It takes
`:tint :emissive :alpha :rim`, and hit flash comes from `model-flash`. `(detach-parts e mask vx vy vz)`
throws parts as debris; this is how crippling and death work.

## Moves & hits (`moves.lisp`, `combat.lisp`, `rules.lisp`)
```lisp
(defmove :rb-lunge (:clip :rb-lunge :s 30 :a 15 :r 42 :sfx :slash-heavy :pitch 0.9 :slide (30 45 5.0))
  (30 45 :dmg 18 :cap (0 1.6 1.1 0.5) :react :stagger :kb 1.2 :hs 4))
```
* Props: `:s :a :r` frames, `:light/:heavy` chain targets, `:chain-at/:heavy-at`, `:abort`,
  `:sfx :pitch` (played when each hit window opens), `:hw`, `:magnet`, `:iframes (a b)`,
  `:slide (from to m)` (scripted forward motion), `:air :hang :red :ravenable :jump :special`.
* Hits: `(from to &key dmg imp arc cap sph tsph react kb hs hw stun vy feet flags repeat every)`.
  The volumes are `:arc (r deg y0 y1)`, `:cap (a b h r)`, `:sph (fwd up r)` and `:tsph (r)` (a
  sphere at the attacker's `target`). `react` is `:flinch :stagger :knockdown :launch :air-flinch`.
  `stun` overrides the reaction frames. `flags` can hold `:ender :no-poise :no-raven :unblockable
  :guard-break :obliterate :ranged :quiet`. Each hit window has its own slot in `fighter-hit-log`,
  so a target is hit once per window.
* `defmove` builds `MOVE` / `HITDEF` records (structs in rules.lisp). Run a move with
  `(start-move e :rb-lunge)`; `move-tick` then advances it every step (slide, sounds, trail,
  `move-hit-scan`). A `:red` move plays `:warn`, pulses the red tint and a glint, and has hyper
  armor during its windup.
* The hit scan tests each open window's volumes with the pure function `vol-hit-p` (engine
  hitvol.lisp; RAVEN's `make-vol` volumes are built there too) and
  calls `(resolve-hit att tgt hitdef)`, the single entry point for any hit. It dispatches to
  `enemy-take-hit` (combat.lisp) or `player-take-hit` (player.lisp). Each of those asks a pure
  rule what happens — `enemy-hit-outcome` (poise, block, Raven Break, cripple, kill, BROKEN) or
  `player-hit-outcome` (just dodge, i-frames, anti-juggle, Raven Guard, parry, guard, guard break,
  damage × `*enemy-dmg-mult*`, reaction by damage) — applies the result to the components and
  emits events. `resolve-hit` returns `:hit :killed :crippled :armored :blocked :guard-break
  :parried :dodged` or NIL.
  **Projectiles**: make a hitdef once, e.g. `(parse-hit '(0 1 :dmg 8 :flags (:ranged)))`
  (`*hd-kunai*` in moves.lisp). When the kunai touches REN, `projectile-system` calls
  `(resolve-hit owner *player* hd)` and destroys the kunai on `:parried` or `:blocked`.

## Enemy AI hook-up
* `(enemy-system k)` visits every entity with a `brain`: dummies run `dummy-tick`
  (training.lisp), enemies `enemy-tick`, which wraps `(enemy-step e k #'enemy-think)`. It handles
  timers, poise regen, the current move (and releases the token at its end), reactions
  (`enemy-react-tick`), physics (`physics-step`, 22 m/s² gravity when launched), animation and
  trail. The think function runs only when the enemy is free. Crippled enemies arrive there in
  state `:crippled`, which is where crawl and Death Grip go. Dead enemies (`:dead`, `alive` nil)
  lie there until `fighter-corpse-t` runs out, then `destroy-entity`.
* Reactions: `(enemy-react e :stagger :stun 90)`. The states are `:flinch :stagger :knockdown
  :launched :crumple :crippled :guard-hit :guard-break :grabbed :dead`. `downed-p` and
  `red-windup-p` are available. Blocking: put the enemy in state
  `:guard`, or set `brain-block-chance` (rolled once per player string).
* **Tokens**: `(token-request e :melee|:ranged)` returns T, `:punish` (the free 3rd token; use
  windup × 0.8) or NIL; the decision is the pure rule `token-decision`. Release with
  `(token-release e)`. Reactions and death release automatically. `(attacks-paused-p)` and
  `(player-punishable-p)` are there; the boss ignores tokens. `token-system` counts the timers down.
* Utilities: `pick-target`, `face-toward`, `distance`, `facing-p`, `fwd-x/fwd-z`, `yaw-to`,
  `kind-of`, `separation-system`, `enemy-kill`, `enemy-to-idle`, `weighted-pick` (engine math.lisp).

## Feedback: events (`feedback.lisp`, presets in `effects.lisp`, engine `time.lisp` / `fx.lisp`)
Combat code does not play effects. It emits events (`emit-hit`, `emit-block`, `(emit :killed …)`,
`:player-hurt`, `:parried`, `:just-dodge`, `:sfx` …; the full list with arguments is the header of
feedback.lisp) and `FEEDBACK-SYSTEM`, at the end of each step and once per frame, turns them into
sounds, particles, rings, shake, hitstop, slow-mo, the hit flash (`model-flash`) and the combo /
kill counters. Hitstop and slow-mo set there act from the next step.
The tools it uses: `(hitstop f)`, `(slowmo s secs [enemies])`, `(shake amp dur)`,
`(fx-mist x y z dx dy dz n)`, `(fx-sparks x y z n r g b)`, `(fx-dust x z n)`, `(fx-orbs x y z gold
blue)` (orbs home to `*orb-target*`, the player, and call `orb-absorbed` through the engine hook
`*on-orb-absorbed*`), `(fx-burst type n ...)` with `+p-mist+ +p-spark+ +p-dust+ +p-glow+
+p-feather+ +p-orb-a+ +p-orb-b+`, `(fx-ring x y z r0 r1 dur r g b :flat t)` and
`(fx-debris mesh m offset vx vy vz spin)`, `sfx-at` (positional sound, engine audio.lisp).
Particles are a 2000-slot f32 pool written straight into the fx batch, so they don't cons.
`screen-hurt` and `fx-draw-screen` draw the vignettes.

## Player notes (`player.lisp`)
The input buffer uses priority Dodge > Jump > Heavy > Light, with the cancel windows of §2.
Soft-lock and magnetism run at attack f0. `(raven-gain n [source])`, `raven-form-p`.
Camera: §7.7 orbit with lag, auto-yaw, enemy-distance zoom, and Obliterate/Thunderfall framing.
Just dodge tests enemy volumes against a hurt radius inflated by `*just-dodge-reach*` (0.8 m)
during dodge f1–10. At 18 m/s a roll leaves a 2 m arc in about 2 f, so without this the window
is effectively a single frame.

## Debug & tests
* **F3** (dev sessions only, see below): overlay with fps, cons/frame, state, move frame, hit volumes (red) and hurt cylinders
  (green, blue = invulnerable). **T** toggles "training dummies attack" (training scene only).
* `*combat-log*` (default **NIL**, release) logs state changes, hits, damage, reactions, tokens, kills, and
  enables the 2 s `stats:` line (engine `*stats-log*`) and F3. The first `Module._debug_cmd` call turns it on, so the test
  scripts (which always send a debug command first) still see and assert on these lines.
* `Module._debug_cmd(n)` from the runner's `eval`: 1 fills the Raven gauge, 2 toggles attacks,
  3/4 makes the faced dummy slash / red-slash now, 5 heals the player.
* The game boots to the title; the training scene is title menu TRAINING or debug cmd 40
  (`gen.py` scripts send it first).
* `python3 tests/scripts/gen.py` writes `tests/scripts/*.json`, then run
  `node tools/run.mjs dist/game --secs 12 --script tests/scripts/raven.json` (also `light-string`,
  `launcher-air`, `defense`, `just-dodge`). Every screenshot
  stalls the script by about 1 s, so put shots after time-critical inputs.
* Measured in headless SwiftShader at about 8 fps (6 steps/frame), before the ECS restructure
  (which added about 10 % consing per real second): 17 KB/frame idle, 20–25 KB
  in combat with 4 fighters, about 90 KB with F3 on. Lisp time is about 1.3 ms sim + 0.6 ms queue
  per frame.

## Cuts / deviations
Lock-on (Tab is a no-op), threat framing, and just-dodge after-images (a glow burst is used
instead) are cut per §12.2. The scarf is procedural sway instead of springs. Player death
respawns after 3 s in training.

## Enemies (`enemy.lisp`)
* `(spawn-enemy kind x z :drop y)` → a fighter entity in state `:spawn` with a `brain` component
  (`brain-mode` keyword + timers, see components.lisp). `ENEMY-TICK` wraps `enemy-step`: `enemy-pre` (windup tracking until
  8 f before the strike, brute charge run), `ENEMY-THINK` (spawn / crippled / per type), `enemy-post`
  (move events when frame S is crossed: kunai release, slam impact, leap takeoff, roar, summon;
  move ends; reaction exit → `:recover`; crumple entry resets the crawl timer; boss phase check).
* `(enemy-attack e move :mult m :skip f)`: every AI attack goes through it. It faces the player,
  shortens the windup by skipping its start (punish token ×0.8, boss P2 ×0.85; red windups keep
  ≥ 42 f), and applies the off-screen rule (+10 f, `:warn`, HUD chevron via `brain-chevron-t`).
* RAINBLADE: approach → circle 3.5–5 m (strafe flips) → token → engage (≤ 1.5 s) → Slash /
  Double / Lunge (lunge from 3.5–6 m, forced after 2 s there); 40 % backstep after; 20 % feints
  without a token; 35 % block; Escape backflip after 6 flinches. NEEDLER: reposition 10 m out
  (biased into the camera view), strafe, retreat under 6 m, Kunai Fan / 30 % red Blast Kunai
  (ranged token, LOS raycast), cornered → Knife Swipe + invulnerable backflip. OXHEAD: slow
  turn (flank him), Swing / red Slam / red Bull Charge (wall → 90 f stun), Stomp if you hug or
  flank him > 1 s, taunt after 2 attacks, Rampage (chained charges) when crippled. ENRA: stalks
  in guard, 60 % block + counter-shove after 3 blocks, Iai Dash / Triple Cut / red Crimson
  Crescent / Blade Wave; at 50 %: 2 s invulnerable kneel → roar (shockwave to 6 m, 0.3× slow-mo,
  crimson rain ×1.5, music restarted at pitch 1.12), then Iai ×2, red Bloodrain Leap, summon at
  35 %. At 0 HP `boss-break` (called from `enemy-take-hit`) kneels him BROKEN: only Obliterate
  kills him (auto after 6 s).
* Crippled grunts / needlers crawl at 1.2 m/s for `*death-grip-delay*`, then the red Death Grip;
  they expire afterwards (no drops, no kill credit).
* Projectiles (`projectiles.lisp`) are entities (`transform` + `projectile`): `spawn-projectile`,
  `PROJECTILE-SYSTEM` per step, `DRAW-PROJECTILES` per frame, `clear-projectiles`. The hit belongs
  to the projectile's `owner`, so guard, parry and just dodge work as for melee. Kunai: blockable / parryable / cut by any active player slash in front. Blast kunai sticks,
  shows a red ring and detonates 0.9 s later (unblockable). Blade Wave: blockable, destroyed by
  Crimson Lance.

## Game flow (`game.lisp`) and screens (`hud.lisp`)
* `*game*`: `:title → :intro (2 s) → :fight` (waves 1–3, reinforcements at ≤ 2 alive, max 6) `→
  :clear (heal 25 %) → … → :boss-intro → :fight → :victory → :results → :title`; death →
  `:dying (2 s) → :over` (RETRY WAVE restores the checkpoint, HP ≥ 60 %). `*paused*` and the
  CONTROLS overlay freeze the sim (rain keeps falling). `GAME-FRAME` (main.lisp) calls `game-input`, `game-update`,
  `game-camera` (title orbit, intro sweep, camera kept inside the parapets).
* Score and rank per §6.4 (`run-score`, `run-rank`); the run timer excludes title/pause/results.

## Debug commands (`Module._debug_cmd(n)`, queued: several per frame are fine)
10 start run · 11–13 wave N · 14 boss · 15 boss to 50 % (phase 2) · 16 god mode · 17 kill all ·
18 autoplay bot (+god) · 19 boss BROKEN · 21–31 force an attack on the nearest enemy of a kind
(21 slash, 22 fan, 23 blast, 24 slam, 25 charge, 26 crescent, 27 leap, 28 blade wave, 29 iai,
30 triple, 31 swing) · 32 cripple the nearest grunt · 33 an off-screen enemy attacks · 40
training · 41 REN dies · 42 retry · 43 title · 50 near-freeze 3 s · 51 dump AI state · 52/53/54
near-freeze 1/10/24 f after the forced enemy's next move event · 55 freeze when a blast kunai
sticks · 56 enemy AI off · 57–60 spawn a rainblade/needler/oxhead/enra in front of REN · 61 soak loop (bot runs back
to back, release logging, `soak:` heap line every 30 s) · 62 toggle `*perf-log*` · 63 frame budget 18 ↔ 1000 ms (auto-render-scale test) · 64 raise a Lisp
error (tests the error overlay).
Scenario scripts: `python3 tests/scripts/e2.py` → `tests/scripts/e2-*.json` (grunt, offscreen,
needler, ox, boss, over, full, perf). Headless SwiftShader runs the sim at ~0.5× real time.

Measured (headless, wave 3 + reinforcements, 7 fighters + projectiles, before the ECS
restructure): 30–41 KB consed/frame, sim 2.0–3.9 ms/frame at 6 steps/frame. Full run title →
results with the bot (`e2-full.json`, after the restructure): results at 110.0–110.6 s, rank S,
no errors (DEVLOG §13).

## Cuts / deviations (enemies, game flow)
Music layers (only one music loop exists: boss phase 2 restarts it faster/higher), strafe clips
(walk clip is reused), Victory "blood flick" animation.

## Polish pass
* Rain loop volume per state (`rain-volume-update`: title 0.6, play 0.45, paused 0.3, boss P2 ×1.3) via
  `set-loop-gain`. Boss P2 music: restarted at pitch 1.12 and raised to volume 0.7 (no second layer).
* Camera: `*cam-fight-dist*` = 7.0 in the boss fight (6.5 in waves).
* Input buffer runs on `*ptick*` (player time, 1/16 frames, paused in hitstop), so presses survive
  slow-mo and hit freezes. Thunderfall grabs / soft-lock skip enemies still dropping in (`:spawn`).
* Auto-pause on window focus loss or pointer-lock loss mid-fight; the click that re-locks the
  pointer is not an attack. GAME OVER ignores input for 0.6 s. Retry kills in-flight essence orbs.
* Camera: eye kept 1.1 m inside the parapets and pulled in front of props (`arena-raycast`),
  snapping in and easing out.
* Readability: per-body rim (`:rim` in `defbody`, drawn with `draw-mesh :rim`), additive eye glows,
  thin faction glow accents (rainblade red, needler cyan); Enra's rim turns crimson in phase 2.
