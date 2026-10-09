# Refactor 2026-10: simplify, abstract, promote to the engine

Status: done on branch `claude/loving-euler-qhsjxo` (2026-10-09). Nothing in it changes the sim or a pixel: every batch
passed the bit-identity gates below. DEVLOG §153 is the decision log entry.

## 1. Request

The user (2026-10-09), verbatim: 「目前的程式經過多次開發後產生了許多新的程式碼。請你重新識別每項實作是否可精簡、抽象化，將冗於與影響效能部份優化並將可被復用的元件整合回到遊戲引擎中。確保整體不會有過度設計的同時並保證可讀性，以及維持函數式編程與 Entity-Component-System 的設計初衷。」
and 「由於此次將會經歷重大改動，因此要請你開啟新的 branch 並指揮 subagents 進行協作開發，並配合 Fable 5.1 作為指導顧問。另一方面，一些簡單的處理工作也可以指派 sonnet 5.5 實作。」

After the macro discussion (whether Lisp macros leave more room to abstract), the user: 「第 1 和第 3 項加進第三波，第 2 項下一輪再做」:
- item 1: the per-side character state (Ichigo `ics`, Senjumaru `sjs`, Lille `lbs`) becomes ECS components (batch B8);
- item 3: `with-cam` takes its binding names from the caller and the engine withdraws the six exports `rx ry rz ux uy uz`
  that its anaphoric form had forced (batch B9);
- item 2 (a `defdebug` registry that generates the DUEL_GAMEPLAY debug table) is the next round, not this one.

## 2. Method

1. Four read-only audits (Sonnet): engine + RAVEN EDGE (A1-A17), SOUL DUEL systems (B1-B19), presentation (C1-C15),
   character kits (D1-D15): 66 candidates with sites, line estimates, risk and an over-design check.
2. The advisor (Fable) spot-checked the claims in the code and ruled on each: 31 accept / accept-modified, 27 reject,
   8 defer (§7). Its guard: a helper must remove real repetition (about 6+ sites) or a real per-frame cost, read better
   than what it replaces, be a plain function or a small macro, and expand to the identical code; prefer deletion; the
   engine only takes what is game-agnostic.
3. Batches with disjoint files, one git worktree + subagent each (Opus for sim / engine work, Sonnet for mechanical
   batches), merged by the lead after its own gate run, in three waves.

## 3. The gates (every batch, and the merged head)

- 8 host suites (duel-rules 6481 checks, duel-control 89, learn 131, input 33, touch 64, cine 18, ecs, RAVEN rules);
  `tools/pkgcheck.sh` duel + game.
- Native simgate, 15 pairings x 10 seeds: the full row output (601 lines, including the 210 lille / ichigo / senju
  pacing lines and the 139 band / cups lines) BYTE-IDENTICAL to main 09c6102's.
- G2 cvc 3/3 (yy 134.1 s, yk 103.7 s, kk 140.8 s: the hash lines of the browser reference).
- Both builds with 0 warnings; smoke runs; G1 RAVEN stills byte-identical (title, wave; cons/frame 17369 B).
- The new looks gate (`tests/style-gates.py looks BASE NEW`, written for this refactor): 108 fixed stills of SOUL DUEL
  under `--fixed-dt` (menus, select, four CPU matches at several times, every Kikon / awakening / form-change
  cinematic, the HUD in every form both orientations, VFX scenes, ENDLESS, the portrait layout, RESULTS), BASE rendered
  twice for the noise floor (0 px), byte identity required. `--keep-base` reuses BASE's renders across a series.
## 4. What was done, by batch

Every batch passed the gates of §3 in its own worktree; the lead merged it and re-ran them on the merged head (wave 1:
all PASS, 108 stills identical; final head: §5).

| batch | model | what | numbers |
|---|---|---|---|
| B0 engine promotions | Opus | engine gains `hypot` / `f-hypot` (macros, exact expansion; host-checked in tests/test-math.lisp), `countdown!`, `f-exp`, `with-floats`, `transform` + `pos-of` / `yaw-of` (both games' copies deleted), `do-events`, the toon macro kit (`hash01`, `%t-blob`, `%t-shard`, `%tring`, `%sector-verts`, `%light`, `with-cam`, `drawing-no`, `%away-from-eye`, `%near-cam`, `%tongue`, `toon-ribbon`), `%trail-push` / `%trail-drop` (trail-push / trail-decay copy forward: no REPLACE), `fx-smear-capture!` (the three smear captures), the 0 B UI quads (`%hq %hrect %hbar %houtline %pulse %ring %arc %disc`), `mb-at`, `set-sfx-volume`; `f-acos` / `f-asin` deleted. Duel: `do-sides`, `*pacing-log*` / `pace`. | engine +~300 (moves), duel −~200 |
| B1 sim helpers | Opus | `hoho-ready-p` (16 sites), `reishi-frac`, `gauges-red-p`, `reiatsu-bars`, `halt!`, `world-dir`; `snap-recovering-p` / `snap-punishable-p` / `snap-left-seen` (28); the 6 hand copies of `ai-decide-time`; `ai-chance` (yama-dif + rukia-ai-p); `ken-punish`; `spawn-look` / `spawn-ground-line` (23); `register-kit` by `apply` (the kit keys listed once, not three times; all 32 kits dumped identical); the learning CPU moved to `ai-learn.lisp` (ai.lisp 1165 -> 868 lines); dead `*awaken-cine-seconds*`, `*lb-misuji-fan*`, `learn-clamp` | 17 files |
| B2 dead code, debug | Sonnet | debug.lisp header 128 -> 14 lines (the missing ranges added to DUEL_GAMEPLAY "Debug commands" first); `set-probe`, `full-gauges!`, `hold-guard!`, `cons-per`; Senjumaru's per-draw `intern`/`format` keys -> load-time vectors; 6 duplicate glyph outlines and `vfx-ic-cero`, `sj-dye-hex` deleted | −130 |
| B3 HUD / draw / flow | Sonnet | main.lisp's drawing moved to `draw.lisp` (main 450 -> 124 lines); `brush-text` (10 sites); `results-card` shared by RESULTS and ENDLESS; `trail-step!`, `guard-gauge-bits`, `awaken-fill`, `prompt-alpha`, `refused-flash`; `do-sides` at the per-frame `(list *p1* *p2*)` sites; both games' `feedback-system` on `do-events` (+ an ecs-test check) | 14 files |
| B4 pacing log | Opus | the three per-character pacing logs (137 count sites) -> one `pace` into `*pacing*`, behind `*pacing-log*` (set by `start-cvc`): the browser no longer formats / interns a key per event; band / cup accumulators under the same flag; the 349 gate lines byte-identical, awaken A/B streams identical | −4 |
| B5 fx sites, glyphs | Sonnet | 39 of 40 hand-written `fx-ribbon :mode :toon` calls -> `toon-ribbon` (each macroexpanded and compared to the original); 82 glyph outlines out of three art files into `glyphs-extra.lisp` (259 entries, same order) | −4 |
| B8 per-side state as components (the user's item 1) | Opus | `ics` / `sjs` / `lbs` are `defcomponent`s on the fighter entity; `*ic*` / `*sj*` / `*lb*` and the entity back-pointers are gone; the accessors keep their names; Lille's draw reads the bare getter (never creates) | +38 / −40 |
| ECS fix (from B8's probe) | lead | `*used*` read with `aref`, not `sbit`: ECL compiles `sbit` to the varargs `cl_sbit`, 8 B per component getter / `do-entities` slot | Lille draw 240 -> 0 B per 10 draws, meter 560 -> 400, ring 400 -> 240; RAVEN 17369 -> 13613 B per frame |
| B9 with-cam names (the user's item 3) | Opus | `(with-cam (rx ry rz ux uy uz) ...)`; the engine's six exports withdrawn; no other engine macro read them; ARCHITECTURE's gotcha: names a body needs come from the caller, never anaphoric | +20 / −16 |
| B6 sweep | Sonnet | 150 `hypot` / `f-hypot` sites (engine 25, RAVEN 26, duel 99; flavour kept, `(expt x 2)` never folded), 19 `countdown!`, 2 more `brush-text`, `cine-shatter` (11 beats) and `push-in-on` (3); every changed file's forms compared EQUAL after inlining the macros (scripted) | +196 / −188 |
| looks gate | Sonnet + lead | `tests/style-gates.py looks` (108 stills), `--keep-base`; the raven mode's runs get `--timeout 7200` | |

## 5. Numbers

- Lines (Lisp only): engine 4791 -> 5079 (+288, the promoted kit), SOUL DUEL 30995 -> 30618 (−377), RAVEN EDGE 5739 ->
  5733 (−6): 41525 -> 41430 in all. The gain is less in line count than in what the lines say: ~300 call sites name what
  they do (`hypot`, `hoho-ready-p`, `snap-left-seen`, `toon-ribbon`, `do-sides`, `pace`), three copies of the smear
  capture, the trail ops and the pacing log are one each, and `register-kit` lists its keys once.
- Allocation: Senjumaru's per-draw `intern` + `format` gone; the pacing log's per-event `format` + `intern` gone from the
  browser; the per-frame `(list *p1* *p2*)` conses on the draw path gone; every ECS component read and `do-entities`
  slot 8 B -> 0 B (RAVEN 17369 -> 13613 B per frame in G1).
- Final head (the lead's gate): see DEVLOG §153.

## 6. Deferred (next round, with what to measure first)

- **`defdebug`** (the user's item 2, 「第 2 項下一輪再做」): one declaration per debug command range carrying its handler
  and its line of the DUEL_GAMEPLAY table, which it generates (B2 found the header and the doc had drifted apart).
- D11 / C12: Ichigo's and Senjumaru's HUD meters cons per frame (`list`, `sort`, `format`); Lille's equivalents are probe
  checked at 0 B, theirs have no probe. Add the probe first.
- The advisor's find: `hud-text` (~200 B per call, dozens per frame) is the biggest remaining HUD allocator; a
  per-string cache, probe first.
- senjumaru-art.lisp has no `defun-fast` (boxing on `sj-seg` / `sj-prop`); measure with a probe before the next
  Senjumaru rework.
- debug.lisp mixes the gate machinery (`start-cvc`, `gate-update`, `state-hash-line`) with scenarios: a `gate.lisp`
  split (with B3.3, the character scenarios out of debug.lisp).
- `toon-ground-seg` stays in stage.lisp: four sites read the macro's own `x0` / `z0` binding (vfx.lisp 703, 726;
  rukia-art 714, 716); rewrite them with the value spelled out before moving it.
- C4 `stamp-code`, C9 sound shower helpers (needs an audio buffer diff), the art-file `mb-at` sweep.

## 7. Verdicts (the advisor's table, as decided)

Legend: A = ACCEPT, AM = ACCEPT-MODIFIED, R = REJECT, D = DEFER (not in this pass; recorded in REFACTOR doc). "Batch" = where it is implemented (§4).

### Audit A (engine, RAVEN)
| id | verdict | how / why | batch |
|---|---|---|---|
| A1 hypot | AM | Two macros, not a defun: `hypot` (generic `sqrt`) in engine math.lisp and `f-hypot` (`f-sqrt`, single-float) in package.lisp, both `(a b &optional c)` so the 51 three-term `f-sqrt` sites are covered too. Exact expansion rule in §8. No `unit-xz` (eps differs per site: 1e-4, 1e-3, 0.01). Never fold `(expt x 2)` forms (4 sim sites ai.lisp:92,768 hazards.lisp:81 combat.lisp:154 and the presentation ones stay as they are). Merges B10-hypot2, D15-xz-len. | B0 def, B6 sweep |
| A2 countdown! | A | `(defmacro countdown! (place dt) `(setf ,place (f32 (max 0.0 (- ,place ,dt)))))` in math.lisp; only the ~22 sites of exactly this shape (not the `(f32 (max 0.0 (- 1.0 ...)))` ones). Sim sites fighter.lisp:267,298 ichigo.lisp:283 expand to the same text. | B0 def, B6 sweep |
| A3 intern/format per frame | A | senjumaru-art.lisp:876,894,896,959: two 7-slot keyword vectors `*sj-bolt-keys*` / `*sj-cloth-keys*` filled by `def-hank-cloths`' loop; sites become `(svref ...)`. lille.lisp:1393,1833, `ic-key`, `lb-band-key`, `hank-key` are pacing-log keys: covered by D4's `pace` (key form not evaluated when the log is off). Merges C1. | B2 (senju-art), B4 (lille/ichigo keys) |
| A4 pacing log | AM | See D4 (one flag, one macro, one per-side vector; the three line printers stay). | B4 |
| A5 %tsector = fx-sector | AM | Not a compiler macro: engine fx.lisp gets `(defmacro %sector-verts (mode segs x y z r0 r1 yaw half l0 l1 l2 l3))` = the current %tsector body with `da = (/ (* 2f0 half) (i->f segs))` (value-identical to `,(float segs 1f0)` for literals) and `with-fx-verts (d o ,mode (* 6 ,segs))`; `fx-sector` keeps its signature and calls it; duel's `%tsector` is deleted and its 4 sites call `(%sector-verts :toon n ...)` with the same arg order. fx-sector's only consumer is tests/engine-check.lisp, so the wrapper is kept purely for the API. Merges C3's %tsector line. | B0 |
| A6 hash01 | A | Move `hash01` verbatim to engine fx.lisp beside `%h01` (export), comment the difference (`%h01` = v - trunc(v), may differ for negative v; never alias), delete `st-h01` (stage.lisp:289, 6 uses -> hash01). Merges C3. | B0 |
| A7 f-exp / damp | AM | Add `f-exp` to package.lisp next to f-sin (`expf`); `au-expf` becomes `(f-exp ,x)`, duel `%expf` deleted (camera.lisp:61, uses -> f-exp: same C). NO `damp`/`smooth-k` (two spellings 1.0/exp vs 1f0/expf must each stay; a helper would have to exist twice), NO `f-tan` (tanf != sinf/cosf bits: pixel risk). Do not touch the generic `(exp ...)` sites in behind-camera / game camera. Merges B10, C10-expf. | B0 |
| A8 transform | A | `transform` (pos f32vec3, yaw single-float; the two definitions are identical, docstrings differ by one word) + inline `pos-of` / `yaw-of` move to engine ecs.lisp (end of file, after defcomponent); delete game/components.lisp:22-25, game/fighters.lisp:34-36, duel/components.lisp:13-16, :211-213. Kind indices shift inside one compilation unit only; run ecs-test (defines its own `pos`, no clash) and G1. | B0 |
| A9 UI quad macros | A | Pure move, names kept and exported (`%ui-poly4` sets the precedent): `%hq %hrect %hbar %houtline %pulse` (hud.lisp:52-88) and `%ring %arc %disc` (onehand.lisp:217-248) -> engine ui.lisp after `%ui-poly4`. `hud-text` stays in duel. RAVEN untouched. Merges B18. | B0 |
| A10 dead | A | Delete `f-acos` `f-asin` (+ export + ENGINE_API.md:606 mention). Keep `sim-rnd-range` (documented twin). Rest of A10 under B17/C7/D12 below. | B0 (engine), B2 (duel) |
| A11 do-fighters | AM | `(defmacro do-sides ((e) &body body) `(progn (let ((,e *p1*)) ,@body) (let ((,e *p2*)) ,@body)))` in components.lisp (after the `declaim special` that ichigo.lisp already needs; `*p1*`/`*p2*` are defvar'd in flow.lisp, add `(declaim (special *p1* *p2*))` in components.lisp). Body is duplicated, so only use it where the body is <= 3 lines; NO alive check inside (keep it at the site). Required at the 8 per-frame sites (main.lisp:362,417; hud.lisp:881,882,884,966,983; camera.lisp:216 keeps its own `(dolist (e (list a b)))` -> `(do-sides ...)` is wrong there (a b are parameters): write it as two `let`s or leave). The other 29 sites optional. Merges B5, C-P4. | B0 def, B3 sites |
| A12 setup RNG / at / annulus | R | RAVEN is finished; 12 lines; its visuals depend on its own stream. (`mb-at` is taken via C8 for the duel only.) | - |
| A13 update-camera x4 | R | Tens of microseconds; dropping the begin-frame call risks stale matrices for world-to-screen input reads. | - |
| A14 fx-billboard dup | R | -12 lines inside the finished renderer; moving macros across render/fx for that is churn. | - |
| A15 with-floats | A | Move verbatim to engine package.lisp beside `f32`, export; delete vfx.lisp:35-39. Engine's 6 hand-written sites: leave (optional later). Merges C3. | B0 |
| A16 small cross-game dups | R | All below the bar (heap-bytes 2 sites, fx-frame dts differ, menu-nav, play-music, portrait-p). | - |
| A17 rejected list | R | Agreed on every item (find-* registry, body-base, RAVEN buffer, vol-hit-p boxing, pool scans, %euler!). | - |

### Audit B (duel systems)
| id | verdict | how / why | batch |
|---|---|---|---|
| B1 brush-text | A | `(defun brush-text (str x y em color &optional (alpha 1.0)) (set-line x y em color alpha) (setf (aref *bl* 7) (line-width str)) (brush-line str))` in brush.lisp; 13 sites (hud 10, debug 1, lille-art 1, senjumaru 1). Same three calls in the same order. | B3 (hud, brush), B4 (senjumaru.lisp:1149 + debug.lisp:585), B5 (lille-art:3130) |
| B2 results / select dedupe | AM | Only textually identical blocks: `results-card` (the two `ui-rect`s; move `endless-card` to hud.lisp and make both results screens call it, each keeping its own y0), the 勝/DRAW block, and the `*results-rows*` table loop if the two bodies diff clean. Select label helper only if the two bodies diff clean. Condition: RESULTS (both orientations) and SELECT stills are in the looks gate; else defer. | B3 |
| B3 debug.lisp | AM | (1) header: keep ~12 lines + pointer to DUEL_GAMEPLAY.md "Debug commands" AFTER diffing that the doc lists every range in the header (add missing ones to the doc first). (4) helpers `full-gauges!`, `set-probe`, `hold-guard!`, top-level `cons-per` macro replacing the four local `per` macrolets (debug.lisp:580,610,817,841; lille.lisp:3369 stays). (2) knob table: R (a cond of one-line clauses already is the table; a data table + walker is a mechanism for -50 lines). (3) character scenarios out of debug.lisp: D (organisational, ~500 moved lines, load-order caveats, conflicts with the kit batches; record as follow-up). | B2 |
| B4 named predicates | A | In fighter.lisp top ("small helpers"): `hoho-ready-p (e)` (17 sites; the kits call it at runtime, order is fine), `reishi-frac (g)` (9), `gauges-red-p (g)` (9), `reiatsu-bars (e)` (6, from D7), `halt! (e)` (8). NOT `why-of`/`opp-fighter` (3 sites each). Wrappers around the identical expression with the same argument evaluation (pure reads). Merges D7. | B1 (defs + sim sites), B3 (hud/onehand sites) |
| B5 per-frame list conses | A | = A11. | B0/B3 |
| B6 landscape cameras to defun-fast | R | The generic path goes through double `deg`/`sin`/`exp`; a single-float port moves the eye by ulps and the looks gate is pixel identity. A consing probe can be added later; no port in this pass. | - |
| B7 band/cup-acc-step every step | A | Guard both with the same `*pacing-log*` flag as D4 (set in `start-cvc`, which both the seed gate (via gate-update) and the 2000+s/3000+s cvc debug commands call; tools/simgate/run.lisp drives `*gate*`/`*gate-busy*`, so every gate line survives). | B4 |
| B8 do-events | A | Engine ecs.lisp: `(defmacro do-events ((kind) &body clauses))` expanding to exactly `(dolist (ev (take-events)) (destructuring-bind (,kind &rest args) ev (case ,kind ...)))` where a clause `(:hit (att def ...) body)` becomes `(:hit (destructuring-bind (att def ...) args body))`, a clause with lambda-list `args` keeps the raw list, `(t ...)` passes through (RAVEN adds `(t (error ...))` to keep its ecase). Convert both feedback-systems (RAVEN mechanical; G1 + rules-test). | B0 def, B3 both feedback.lisp |
| B9 ai-learn split, pilot-system | AM | Pure move: ai.lisp:875-1165 -> `duel/lisp/ai-learn.lisp` (MANIFEST right after ai.lisp; `lrn` struct / `*learn-use*` precede assist.lisp as before); `pilot-system` -> fighter.lisp (pilot-read stays in main.lisp). NOT the learn-result!/make-learner dedupe (2 sites, different constants). | B1 |
| B10 engine additions | AM | hypot -> A1; f-exp -> A7; f-tan R; smooth-k R. | - |
| B11 assist as a component | R | `assist-brain` reads `(sim-rnd-state)` lazily on its first step; creating it at spawn moves that read and changes the ASSIST gate. Low value. | - |
| B12 hud-side vs portrait | AM | Only identical blocks, each a 2-5 line function: `trail-step!`, `guard-gauge-bits`, `awaken-fill`, `refused-flash`, `prompt-alpha`. Not the kit-meter dispatch or the combo block unless they diff clean. Condition: landscape + portrait HUD stills in the looks gate (debug 2430+k hud-review). | B3 |
| B13 draw.lisp split | A | main.lisp:57-381 -> `duel/lisp/draw.lisp` listed right before main.lisp; main.lisp keeps the frame/entry. `smear-joints!` stays in duel. | B3 |
| B14 world-dir | A | `(defun world-dir (e f to st) (let ((p (pos-of e))) (toward-strafe-dir to st (aref p 0) (aref p 2) (fighter-ox f) (fighter-oz f))))` in fighter.lisp; 6 sites (fighter 3, ichigo 1, lille 2). Same argument order; pure reads. | B1 |
| B15 run-hook | R | Each site is already one line; borderline macro. | - |
| B16 timers / raise-guard / spawn-intro-pair | R | 7-12 sites of a 1-line idiom; a macro over fixnum decf adds nothing readable. | - |
| B17 dead / duplicate | A | `*awaken-cine-seconds*` (tuning.lisp:221) delete; `learn-clamp` -> engine `clamp` (same `(max lo (min hi x))`, learn-test loads package.lisp); components.lisp:208 comment fragment delete. Keep `mv-first-hit`, `kit-clips`, `cpu-p`, `hoho-allowed-p`'s stunned arg. | B1 (tuning, learn), B0 (components comment) |
| B18 UI macros to engine | A | = A9. | B0 |
| B19 menu code | R | Agreed. | - |

### Audit C (duel presentation)
| id | verdict | how / why | batch |
|---|---|---|---|
| C1 Senju intern/format | A | = A3. | B2 |
| C2 smear capture x3, trail replace | A | Engine fx.lisp: (1) `trail-push`/`trail-decay` use the explicit forward copy (`(dotimes (i (* 6 (1- n))) (setf (aref tr i) (aref tr (+ i 6))))`: same result as the overlapping `replace`, 0 B; RAVEN uses them -> G1); (2) macros `%trail-push (tr bx by bz tx ty tz)` and `%trail-drop (tr n)` = Lille's bodies renamed, `trail-push`/`trail-decay` call them; delete lille-art.lisp:2463-2480; (3) `(defmacro fx-smear-capture! (tr sm n dr u width-form k-form))` = the shared `i0 im i1 o0 om o1` / three-point / control-point / `lx ly lz` block (binds `len` for width-form; in the claw case the unused len is computed, harmless) and the three callers keep their own draw call. Float order identical to the three existing bodies (they already match). | B0 |
| C3 toon macros to engine | A | Move verbatim and export: `with-floats` (-> package.lisp), `hash01`, `%t-blob`, `%t-shard`, `%tring`, `%sector-verts` (A5), `toon-ground-seg` (stage.lisp:236), `%light` + `*light-v*`, `with-cam`, `drawing-no`, `%away-from-eye`, `%near-cam`, `%tongue` -> engine fx.lisp after fx-envelope. `clock` and `n-of` stay in vfx.lisp (`n-of` reads `*fire-density*`; `clock` is a 1-line alias). `*st-toon*` -> `*toon-ground*` (same value). Also move `engine::%euler!` export if stage.lisp:372 uses it unexported. pkgcheck rule 2: every duel copy must be deleted in the same batch. | B0 |
| C4 defstamp | R | A compile-time registry macro that generates the dispatch is the "registry for its own sake" the brief forbids; the three-way sync is real but small. Optional later: `(stamp-code :heavy)` reading `*stamp-kinds*` at macroexpansion time for the magic numbers. | - |
| C5 glyph duplicates / move | A | (1) delete the 6 duplicate glyph lines in senjumaru-art (19977 22235 35009 31070 40658 19968; byte-identical after whitespace) and ichigo-art's 40658/19968 if they are the duplicates (keep one copy of each, in glyphs.lisp when it has it). (2) move the three `(setf *glyph-outlines* (append ...))` blocks to `duel/lisp/glyphs-extra.lisp` after glyphs.lisp in the MANIFEST (lookup is by code; no order dependence once duplicates are gone). | B2 (1), B5 (2) |
| C6 toon-ribbon | AM | Engine fx.lisp (next to fx-ribbon): `(defmacro toon-ribbon ((x y z) (ax ay az) (w0 w1) &key (heat '(1f0 0.2f0)) seed (wob 0.3f0) pal k k1 ph sway (segs 6)))` expanding to the one `fx-ribbon ... :mode :toon` call with the argument FORMS placed in fx-ribbon's positional order (so `rnd01`/`hash01` evaluation order is unchanged); `%tongue` re-expressed through it. Convert the 41 sites. NO `fx-streak` (8 sites). | B0 def, B5 sites |
| C7 dead | A | `vfx-ic-cero` (ichigo-art.lisp:657-671) delete; `sj-dye-hex` + `*sj-dye-hex*` delete, keep the literal list in `def-hank-cloths` with a comment (no eval-when games). API vestiges with ignored args: R. | B2 |
| C8 mb-loft / mb-at | AM | Only `(defmacro mb-at ((mb &rest xf) &body body) `(with-xform (,mb (xform ,@xf)) ,@body))` in engine meshgen.lisp; `st-at` deleted (stage.lisp uses mb-at). `mb-loft`: R (2 sites). The 172-site art-file sed and RAVEN's `at`: D (optional later). | B0 |
| C9 sound showers | R | No audio gate; a buffer-diff tool would be needed; -25 lines in both games is not worth a sound change risk. | - |
| C10 cinema FFI / expf | AM | `set-sfx-volume` in engine audio.lisp beside set-music-volume; the 3 raw c-inlines use it; `silence-end` / `back-rim-end` helpers (2 copies each). `%expf` -> A7. | B0 |
| C11 Lille-art local dups | R | A probe-tuned 0 B file; -25 lines vs touching Gram-Schmidt order and wing branches. | - |
| C12 Rukia hilt / ic-rgb | R | Hilt: 8 setup-time lines. `ic-rgb` boxing: folded into the D11 deferral list. | - |
| C13 mirrored joints DSL | R | A DSL change over data for -60 lines nobody reads. | - |
| C14 defstrike sugar | R | Agreed. | - |
| C15 with-hazard | R | 1-2 lines per look. | - |

### Audit D (duel characters)
| id | verdict | how / why | batch |
|---|---|---|---|
| D1 ai-decide-time copies | A | 6 sites -> `(ai-decide-time e b)`; only Kenpachi has `:tempo` (ken.lisp:231), so n is unchanged; one sim-rnd01 at the same point. | B1 |
| D2 difficulty lookups | AM | Merge only the textually identical pair: `yama-dif` + `rukia-ai-p` -> `ai-chance (e plist)` in ai.lisp (`(getf plist :normal 0.0)` default; verify every Yama table has `:normal`). `ic-p` -> `(case (brain-difficulty b) (:easy easy) (:hard hard) (t normal))` (same result, no consing). Leave ken-p, senju-dp, lb-ai-level, opp-chance, lb-ai-chance, ken-roll. | B1 |
| D3 perception predicates | A | `snap-recovering-p`, `snap-punishable-p`, `snap-left-seen` in ai.lisp beside snap-live-p; convert only sites with the exact shape (11 / 6 / 18); `lb-ai-busy-p` keeps its arithmetic. Pure `and` chains, same order. | B1 |
| D4 pacing log | AM | components.lisp (B0 adds): `(defvar *pacing-log* nil)`, `(defvar *pacing* (vector nil nil))`, `(defmacro pace (e key &optional (n 1)) `(when *pacing-log* (incf (getf (svref *pacing* (fighter-side (fighter ,e))) ,key 0) ,n)))`. B4: `ic-count`/`sj-count`/`lb-count` sites -> `pace` (sed), lille.lisp:801 stance-max under the flag with the same `(setf (getf ...) (max ...))`, `ic-acc-watch` call under the flag, `:acc` slot removed from ics/sjs/lbs and the accessors become "fresh state when the entity changed" (no carry), one `pacing-reset` (start-cvc) replacing the three resets, the three `*-acc-line` printers kept (different formats) reading `(svref *pacing* side)`, band/cup-acc-step guarded (B7). `*pacing-log*` set T in `start-cvc` before `start-match`. Byte identity of the 210 lines follows from the identical `incf getf` sequence (keys are pushed to the plist front in first-seen order). | B4 |
| D5 per-side state as components | D | The ECS-faithful form, but it needs the browser consing probe (debug 79195) for lille-art's `lb-state` path; do after this pass merges, opus, its own gate. | B8 (the user moved it into wave 3: 「第 1 和第 3 項加進第三波」) |
| D6 hazard spawn helpers | AM | hazards.lisp: `spawn-look (e look &key x z yaw size life delay fragile data)` (x z default to E's feet) replaces `rukia-look`/`ichigo-look` and their 15 `(let ((p (pos-of e))) ...)` sites; `spawn-ground-line (e size life look)` for the 7 `:line` sites. `spawn-wave`: R (the four hitwins differ). senju-look / lb-spawn-look-at untouched. Identical keyword values reach spawn-hazard; hazards are in the state hash -> cvc proves it. | B1 |
| D7 hoho / reiatsu-bars | A | = B4. | B1 |
| D8 ken-punish | A | One `ken-punish (e b s d tag table near)` with the `and` conditions in the same order; the two reflexes become one-line calls. | B1 |
| D9 register-kit triple list | A | `(apply #'make-kit ... (strip-keys merged '(:startup-add :reach-mult :grid)))` after diffing every `&key` default against the struct default (the audit checked; the implementer re-checks and lists them in the commit). Load-time data: duel-rules-test (6481 checks) + simgate + cvc prove it. | B1 |
| D10 cinematic scaffolding | AM | `cine-shatter (v n &key (up 1.1) (dy 0.0))` (vfx only, sfx/shake stay at the site) and the Ken pair as one defun with a colour; `push-in-on` (3 sites) ok; `kikon-open`: D (blends/speeds/victim clips vary; keyword soup). Cosmetic (cine clock); requires two kikon-cine stills in the looks gate. | B6 |
| D11 HUD meter consing | D | Needs the browser probe; replacing `ui-rect` with the float API is a pixel-path change to verify. Record with C12's ic-rgb and D15's `ichigo-live-clones` as the follow-up list. | - |
| D12 dead / test-only | AM | `*lb-misuji-fan*` delete. Test-only model functions (lb-trace-oldest/-lay, weave-passes, echo-hit-frames): KEEP (host-tested rules models; deleting tests loses coverage). | B1 |
| D13 :ai-hooks key | R | A new merge rule in register-kit changing how kit data composes; the data stays explicit. | - |
| D14 stance engine | R | Agreed. | - |
| D15 small | R | All below the bar (breaker knobs are separately tuned data; Lille hard-levels are the dream-rsi record; kikon params are the move table). `cine-still`/`refill-both`: R (cross-file debug-only). | - |


## 8. Determinism rules (per accepted item)

General: the native sim is compiled from the same sources (musl, SSE2, no fp-contract); byte identity holds iff the compiled expressions are the same. So every helper is a MACRO (or an `inline` defun whose body is the old expression) and the implementer may only replace text whose expansion is the old text. Rules:
1. `hypot` / `f-hypot`: expansion is exactly `(sqrt (+ (* a a) (* b b) [(* c c)]))` / `(f-sqrt ...)`. Never change the flavour at a site (generic `sqrt` stays `sqrt`, `f-sqrt` stays `f-sqrt`). If an argument is a symbol it is used as is (no rebinding, so declared types are kept); an expression is bound once with `let*` in argument order (pure expressions only; none of the 94 sites contains a call with side effects, the implementer confirms per site). The `(expt x 2)` forms are never folded. Suggested definition:
 `(defmacro hypot (a b &optional c) (let* ((fs (remove nil (list a b c))) (ss (mapcar (lambda (f) (if (symbolp f) f (gensym "H"))) fs)) (bs (loop for f in fs for s in ss unless (symbolp f) collect (list s f)))) `(let* ,bs (sqrt (+ ,@(mapcar (lambda (s) `(* ,s ,s)) ss))))))` and `f-hypot` the same with `f-sqrt` and `(declare (single-float ,@gensyms))`.
2. `countdown!`: exactly `(setf ,place (f32 (max 0.0 (- ,place ,dt))))`; place evaluated twice as today.
3. Named predicates (B4/D7/D3/B14/D1/D8/D2/D6): plain defuns whose bodies are the old expression with the same argument evaluation order; arguments are pure reads (`gauges-fs`, `snap-*`, `pos-of`); no `sim-rnd01` is moved into or out of a helper (`ai-decide-time` keeps its one draw; `ken-roll` untouched; `ic-p`'s `case` returns the same value as the `getf`).
4. D9 register-kit: same slot values (defaults diffed), same `:spec merged`; proven by duel-rules-test + simgate + cvc.
5. D4/B7 pacing: the only sim-visible effect of the log is the gate text; identity of the text needs (a) `(incf (getf PLIST key 0) n)` with the same key forms in the same order, (b) the flag set in `start-cvc` before `start-match`, (c) the three printers unchanged in format. `pace` must not evaluate `key`/`n` when the flag is off (no `format`/`intern` in the browser). The `(lb e)` refresh side effect at former `lb-count` sites is irrelevant (every sim read calls `(lb e)` itself).
6. Presentation-only (cannot change a hash, must keep pixels): A5/C3 (macro bodies moved verbatim; `%sector-verts` da/cy identical), A6, A7 (`f-exp` is the same `expf`; generic `exp` sites untouched), A9, A11 (P1 then P2, alive checks kept at the site), B1, B2, B8 (same `case` order), B12, B13, C2 (float order of the three bodies already identical; forward copy == overlapping `replace`), C5, C6 (argument forms forwarded in fx-ribbon's positional order), C8, C10, D10 (same calls inside each `at`), A8 (struct layout unchanged).
7. Never: swap `atan`/`yaw-to`, touch `dir-yaw`, `+pi+`, `turn-toward`; port `behind-camera`/`duel-camera` pair branch to single-float; change any `sim-rnd01` call count.


## 9. Advisor notes (review of the plan)
- Risks: (1) pkgcheck rule 2 fails a build whose target still DEFines a now-engine export: every move deletes the duel copy in the same batch. (2) The pacing lines are byte-compared: any reordering of `pace` calls or a changed key form changes the text; B4 must sed, not rewrite. (3) `do-sides` duplicates the body: keep bodies to one call. (4) The looks gate must cover both HUD orientations, RESULTS, SELECT, stamps, Senju domain, Lille wings/claws, two kikon cinematics; if a batch's screen is not in it, defer that item (B2, B12, D10). (5) Wave ordering matters: B3/B4/B5/B6 need B0's definitions; B6 needs everything merged.
- Do NOT: fold `(expt x 2)`; swap sqrt/f-sqrt flavours; port cameras to single-float; merge `%h01`/`hash01`; merge ken-roll with `(< (sim-rnd01) p)`; deep-merge `:ai` plists; make assist a component; convert RAVEN beyond transform/feedback/trail (finished game).
- Missed by the audits / bigger opportunities: (a) `hud-text` (~200 B/call, dozens of calls per frame) dwarfs every 32 B list cons found; a per-string block-text cache is the real HUD allocation win (probe first; follow-up with D11). (b) senjumaru-art.lisp has no defun-fast at all (C-P2): measure with debug 79195 before the next Senjumaru rework. (c) debug.lisp mixes the gate machinery (start-cvc, gate-update, state-hash-line) with scenarios and knobs; a `gate.lisp` split would protect the gate code from scenario churn (follow-up with B3.3). (d) The 51 three-term `f-sqrt` sites are more than the two-term ones the audits counted; `f-hypot` with an optional third arg covers them. (e) Three stale agent worktrees in .claude/worktrees (never commit). (f) gate.sh matches touch-test on " 0 failures" (its summary line is not "ALL PASS"): fine, but base-host.txt shows it empty because it was grepped for ALL PASS only.

