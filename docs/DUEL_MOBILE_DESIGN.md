# SOUL DUEL: ONE-HAND (片手) mode, a portrait phone played with one thumb (design v2)

> Status: **decided, not yet built**. Working notes (critiques, v1 drafts, research) were kept outside the repo; the debate outcome is recorded below.

v1 is kept as `design-mobile-v1.md`. This version answers `critique-mobile.md` (1 BLOCKER, 8 MAJOR, 7 MINOR);
§11 records each finding and how it was resolved. It includes the user's decisions of 2026-09-26: right hand
is the default and the left-hand mirror is an option; FULL assist has no damage scaling, only an ASSIST tag;
there is no local portrait 2P; future Bluetooth / Wi-Fi P2P netplay must stay possible.

## 給使用者的摘要（繁體中文）

- **新模式「片手 ONE-HAND」**：手機直拿，一根拇指對戰電腦。預設右手，選項裡可以換成左手。
- **防禦不再是「一碰就擋」**：拇指按著不動超過約 0.12 秒才開始防禦，比這短的就是點擊，也就是 Quick。這樣連段、跑步取消都不會被誤觸的防禦打斷。代價是預先防禦慢了約 7 格；反應型防禦反正本來就來不及，重招照樣擋得住。
- **撥（flick）在劃過門檻的那一刻就出招**，不必等手指離開，延遲變得穩定。只有「往上撥 = Flash」要多等 80 ms 確認不是往前拖著跑。
- **Hoho**：站著或防禦時，按住再往上撥。出招途中往上撥一律是 Flash，所以 J J K 分支不會誤觸成 Hoho。單手版少了「連段中取消成 Hoho」這一招。
- **Burst**：被打中、硬直或浮空時往下撥，跟 Shift+J 一樣會記在緩衝裡。
- **山本西、野晒三杯這類「U 不是防禦」的型態**：長按後放開就鎖住 U（霸體或喝），再長按一次解除，量表歸零時自動解除。鎖住之後點擊和撥照樣出招，所以攻擊時也有霸體。
- **按鈕重新排過**：手勢區是一整塊至少 260×194 px 的連續區域。O 放在手勢區上方，其餘四顆（L、I、SP1、SP2）沿拇指側排成一列，不會碰到 Home 條和側邊的返回手勢區。覺醒要按住 0.3 秒。
- **防止誤退出**：會先 push 一筆瀏覽紀錄，擋住 Android 側滑返回和 iOS 返回，觸發時改成暫停；拇指那一側的邊緣也留 32 px 死區。
- **鏡頭**：直向改為 FOV 66°，畫面往上平移 0.22，貼身時的轉角從 40° 降到 15°。所有調整都只在畫面端，Hoho 後鏡頭怎麼追上也只在畫面端做，不改模擬端的 `*behind-turn*`。這樣兩台手機將來連線，搖桿方向的換算也不會不同步。
- **先做能玩的原型**：P0 直接做一個粗略但能打完整場的單手版，拿兩支真手機驗證；確定可行後才做直向排版、選單和 PWA。
- **延後的項目**：FULL 輔助、自動衝近、過場橫幅、震動、互動教學、觸控軌跡、主動 GC。LIGHT 輔助只保留「O 點一下就鎖住」。
- **將來連線對戰**：觸控和輔助都只寫 vpad，連線時交換的是每一步的 vpad，模擬端不需要知道你是用手機操作。另外新增一個測試：同一段觸控腳本跑兩次，雜湊必須完全一樣。
- **還需要你決定的**：無。原本的三個問題都已經有答案了。

---

Status: design only; nothing in the project was edited. Code references were re-checked for this revision:
fighter.lisp run-step 453–462 (guard before the Step release), move-commands 400–418, stun-step 420–426;
main.lisp pilot-read 43–47; hud.lisp `*refused-t*` 240–247; design-nozarashi.md §2.4 (U: ARMOUR / U: DRINK).

## 1. What exists today (unchanged from v1, two corrections)

| Area | Now | Consequence for a phone |
|---|---|---|
| Touch input | `pf_pump` handles keys, mouse and pads. **No finger events.** | SDL3 already turns touch pointer events into `SDL_EVENT_FINGER_*` with 0..1 coordinates (SDL file 745–784), but nothing reads them. SDL also maps `pointerleave` to FINGER_CANCELED, which fires after every touch `pointerup` (1054–1056 → 924–949). |
| vpad | Devices, the CPU and scripts write it once per fixed step; readers are data (bindings + `down-p`) | Touch is one more `(:touch name)` binding. Fighters, rules and AI stay as they are. |
| Canvas | CSS `100vw × 100vh`, backing store = CSS × DPR | Mobile `100vh` puts the bottom under the browser bar. At DPR 3 a frame is 3 MP. |
| Text | `ui-scale` = min(round(h/360), floor(w/480)) | On a 1179×2556 iPhone s = 2, so a glyph is **4.7 CSS px** tall. (v1 said 5.3.) |
| FOV | vertical 60°, reset by every cinematic (cinema.lisp:42) | At 9:19.5 that is about 30° horizontal. |
| HUD | two 0.36 w panels, prompts at 0.78 h, captions at 0.8 h | Prompts and captions land under the thumb. |
| Audio | resumes on `keydown/pointerdown/touchend` (audio.c:127) | Fine for touch. |
| Focus loss | `pf_pump` zeroes keys and mouse on FOCUS_LOST / HIDDEN / MINIMIZED (platform.c:74–75); `visibilitychange` already arrives as WINDOW_HIDDEN → `pf_flost` → pause (flow.lisp) | Fingers must be cleared there too (G1). |

## 2. Research, briefly (unchanged; sources at the end)

- Hoober's 1,333 observations: 49 % one-handed grip, about 75 % thumb use. The easy zone is the lower middle.
- Minimum targets: Apple 44 pt, Material 48 dp, about 9 mm.
- *MCOC* tap / swipe / hold with block and dash-back. *MKX* two-finger block. *Bleach: Brave Souls* flick
  anywhere to dodge, big attack button, cooldown buttons. *Archero* floating stick for one thumb.
  *SF6* Modern assist combos.
- Platform: SDL3 finger events plus synthetic mouse; Safari 26 has WebGPU by default; iPhone has no element
  fullscreen; iOS PWAs are **standalone**, not fullscreen (the status bar and insets stay); Screen Wake Lock
  works everywhere; **WebKit has no Vibration API** (treat iOS as unsupported); iOS Low Power Mode caps rAF at
  30 fps; Android `orientation.lock` needs fullscreen; Android gesture navigation takes "back" from both side
  edges, and a page cannot exclude it.

## 3. The control scheme (one thumb, portrait)

### 3.1 Principles

1. **The thumb on the glass is a held button, once the input is unambiguous.** Nothing that commits a move
   comes from an input that could still be something else (v1's "guard at touch-down" broke this; see §11 #1).
2. **The gesture carries the direction.**
3. **Frequent, split-second actions are gestures. Named or gauge moves are chips.** Gestures start only in one
   contiguous flow pad; chips live outside it.
4. **The pilot only writes the vpad.** Rules, frames, AI and the sim-side view are unchanged. A UI mode never
   changes how a vpad state moves a fighter (netplay, §9).
5. **Fail safe.** When the input is ambiguous, the pilot chooses guard or nothing.

### 3.2 Recogniser (per contact; timestamps from SDL events, not frames)

A contact that starts in the flow pad is *the* gesture contact. **The latest one wins**, so a stuck or palm
contact cannot lock input. A contact that starts in a dead band never claims the slot.

| State / event | Condition | vpad writes | Meaning |
|---|---|---|---|
| **TAP** | lifted ≤ `tap-ms` (120) after down, travel < `slop` (10 px) | `:quick` pulse | Quick. Taps chain Q1 Q2 Q3; the J J K branch is tap, tap, flick↑. |
| **REST** | still for `tap-ms` | U held (guard forms); nothing in latch forms (§3.4) | Guard (it blocks after the existing 2 f raise). Lifting after this point does **nothing** else. |
| **FLICK** (not up) | travel reaches `flick-min` (28 px) within `flick-window` (120 ms) of leaving the slop | fires **at the crossing**: `:step` pulse + stick = stroke direction | Step (↓ back, ←/→ sidestep, diagonals). If the thumb keeps going past the run ring, `:step` stays held: the hop, then the run, as holding Space does. |
| **FLICK ↓ in `:stun` / `:air`** | same | `:mod` + `:quick` | Burst Reverse, buffered like Shift+J (fires on hit 2 if pressed after hit 1) |
| **HOHO** | a REST contact (≥ `tap-ms` still) in neutral or guard, then an up-stroke crossing `flick-min` | fires at the crossing: `:mod` + `:step` | Hoho from guard. The perfect-Hoho read is intact. |
| **FLICK ↑ = F** | a fresh up-stroke, or any up-stroke while in `:move` | `:flash` pulse once the thumb lifts within `up-lift-ms` (80) of the crossing | Flash, the Q2 → F branch. Not lifted in time → DRAG instead (forward walk or run). |
| **DRAG** | left the slop without a flick | stick = Δ / `stick-r` (48 px); origin follows past 2 r | Walk / strafe (up = toward him, through the behind view) |
| **DRAG far** | deflection ≥ `run-ring` (1.6 r) | `:step` held + stick | Dash then run; back inside 1.3 r releases Step (the existing brake) |
| **Back to rest** | a drag returns inside the slop and stays still `tap-ms` | as REST | "Walk back, then block" without lifting |
| **CANCELED** | SDL FINGER_CANCELED | release whatever it held; never a tap | Idempotent for unknown or already-ended ids |

The pulse latch keeps a tap or flick down until one fixed step has read it; at 120 Hz a frame can run 0 steps.

**Latency, honestly** (classification delay from touch-down, plus 1–2 frames of rAF → pump → step):

| Gesture | Delay | Note |
|---|---|---|
| Chip | 0 | Fires on touch-down; chips sit outside the pad |
| Rest / guard | `tap-ms` ≈ 120 ms (7 f) | Pre-emptive guard only. Reacting to 9–11 f Quicks is humanly impossible anyway; 14–22 f heavies are still blockable. |
| Drag | 20–60 ms | |
| Tap | 60–120 ms | Fires on lift. The press moment is the lift. |
| Flick, not up | ≈ 47 ms minimum, and consistent, since it fires at the crossing | |
| Flick ↑ (F) | crossing + ≤ 80 ms | The one deliberately slower gesture; F startups are 16–22 f |
| Hoho | rest ≥ 120 ms, then the crossing | From guard, the rest has usually already happened |

The 10 f input buffer only keeps *early* presses alive (presses during recovery or blockstun). It does not
hide latency from neutral. v1's claim that it did was wrong.

### 3.3 Layout (CSS px on a 390×844 phone; data, mirrored x → W − x for the left hand)

```
 y   0 ┌──────────────────────────────────┐ safe top (≈ 47)
    47 │ KENPACHI ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░  87 ⏸│ opponent panel ≈ 90 px (name, Reishi, timer, pause)
       │ ◆◆◆◆◆◆◆◆◆ guard ▬▬▬ ●●○ ▭ ◌       │ Konpaku, guard gauge, Reiatsu dots, flash-step, awaken ring
   140 ├──────────────────────────────────┤
       │ ARENA  (behind camera, lens shift)│
   478 │ YAMAMOTO ▓▓▓▓▓▓▓▓▓░░ ◆◆◆◆◆◆◆◆◆ ▬  │ own vital strip ≈ 30 px
   508 ├──────────────────────────────────┤ THUMB DECK
       │  (AWK)     (  O  )          (L)   │ O r 36 at (220,548); AWAKEN (120,548) only at EVOLUTION, hold 300 ms
   600 │┌─────────────────────────┐   (I)  │ L (318,564) I (318,632) SP1 (318,700) SP2 (318,768), r 26
       ││ FLOW PAD 260 × 194      │  (SP1) │ contiguous; gestures start only here
       ││ x 16–276, y 600–794     │  (SP2) │
   794 │└─────────────────────────┘    ┆┆  │ right dead band x ≥ 358 (32 px), left 16, bottom 16
   810 └──────────────────────────────────┘ home-indicator inset (34)
```

The constraints are checked by a host test (`deck-layout-ok-p`) at 360×640, 375×667, 390×844 and 430×932:
- each chip's hit circle (radius + 8 slop) keeps ≥ 16 px from every other chip and from the pad;
- every chip centre is ≥ radius + 16 above the bottom inset and outside the dead bands;
- the pad is ≥ 220×180, which the 390×844 example meets at 260×194.

Sizes are in millimetres (CSS px per mm from the pixel density), so a short screen gets the same deck and a
smaller arena; the minimum arena is 35 % of h. On screens where the column does not fit, SP1 and SP2 fold into
one SP chip: tap = SP1, flick up off it = SP2.

The column's lowest chip is the rarest (SP2). The O spot and the column order are tuned on real phones in
P0, whose exit criteria include reach.

### 3.4 Chips and the U latch

- **Chips** fire on touch-down (they are outside the pad, so no gesture starts on them). A chip **stays held
  until lift**, even if the thumb slides off, so a sliding thumb never drops a Kikon hold.

  | Chip | vpad |
  |---|---|
  | O | `:kikon` |
  | L | `:sig` |
  | I | `:breaker` |
  | SP1 | `:mod` + `:flash` |
  | SP2 | `:mod` + `:sig` |
  | AWAKEN | `:awaken`, after a 300 ms hold |

  Every hold rule stays the same: the Kikon held through the strike, Kenpachi's stance, the Breaker's longer
  dash, Shiranui's charge, Kenpachi's SP2 hold. Chip faces come from kit data: the module name on O, 東 / 西
  on L in Bankai, Reiatsu pips on SP, cooldown sweeps.
- **Refused presses flash the chip.** This needs a small cosmetic addition, because `*refused-t*` has only
  L / Shift+L slots and a no-bar press emits nothing today. Give `*refused-t*` one slot per chip, and emit a
  `:refused` event on a no-bar press as well as a cooling one. It is cosmetic; the fixed-dt touch gate (§7)
  confirms the hash is unaffected.
- **U latch** (forms where U is not a guard: West `U: ARMOUR`, Nozarashi T3 `U: DRINK`). The pilot keys off
  the batch's own per-form U mode (the value behind the panel tag; `:guard` until that batch merges). No new
  kit flag.
  - A still rest of ≥ `latch-ms` (250) **released without a stroke** toggles U on; the next one toggles it
    off.
  - Gauge 0 / burnout clears it. The panel tag glows while it is latched.
  - While latched, taps, flicks and chips attack **with U held**, as on keyboard. This restores West's
    armoured attacks, which v1 lost.
  - Rest → stroke never toggles, so Hoho still works.
  - Guard forms have no latch: rest = hold U, exactly as §3.2.

### 3.5 Keyboard → one-hand map

| PC | One hand |
|---|---|
| WASD | Drag |
| Space (tap / hold) | Flick / drag far |
| U (hold) | Rest (guard forms) or the U latch (armour / drink forms) |
| J / K | Tap / flick ↑ |
| L | L chip |
| I | I chip |
| O (hold) | O chip, held |
| Shift+K / Shift+L | SP1 / SP2 chip |
| Shift+Space (Hoho) | Rest → flick ↑ (neutral / guard) |
| Shift+J (Burst) | Flick ↓ in stun / air |
| P | AWAKEN chip (hold 300 ms) |
| Esc | ⏸ (hold 300 ms), app switch, or a back gesture |

**What one hand loses** compared with keyboard:
- the Hoho *cancel* from a landed string;
- Hoho out of a run (rest first);
- a forward Step (use the run);
- walking while pressing a chip (a two-thumb player can still do it: chips accept a second contact);
- pre-emptive guard costs about 7 f more.

Everything decisive remains: the O cancel from a string, the true Kikon hold and release, the perfect-Hoho
read, the triangle, guard-gauge pressure, run cancels with carry, SP holds, Burst timing and stance switching.

### 3.6 Assists

- **OFF** and **LIGHT** (default) ship first. LIGHT = the **Kikon latch** only: a tap on O holds `:kikon` until
  the strike resolves. The next touch releases it early (the plain hit), and that releasing contact is
  **swallowed**: it starts no gesture and buffers no Quick.
- **FULL** (auto-guard + auto-string, no damage scaling, ASSIST tag on the results, per the user) is
  **deferred** until playtests show it is needed. When built, auto-guard gets its **own** snap ring advanced
  only on sim steps (not in `pilot-read` during hitstop or cinematics) and draws no `sim-rnd01`; ai.lisp's
  reflex rolls it.
- **Approach tap** is deferred. It changes what a tap means, hurts the transfer to OFF, and needs a toward-stick
  and a chase cap.

### 3.7 Feedback (v2 scope)

- The recognised gesture flashes its glyph at the thumb for 0.3 s (↑ F, ↓ STEP, 歩 HOHO, 鎖 U-LATCH). This is
  the misread teacher and stays in P0.
- The floating stick is an ink ring (run ring dashed). Chips show pressed / cooldown / cost / refused states.
- Deferred: the brush touch trail and haptics (Android only anyway; WebKit has no Vibration API).

### 3.8 Knobs (one `gesture-config`; tuned in P0 / P4)

| Knob | Default |
|---|---|
| `tap-ms` | 120 ms |
| `slop` | 10 px |
| `flick-min` | 28 px |
| `flick-window` | 120 ms |
| `up-lift-ms` | 80 ms |
| `latch-ms` | 250 ms |
| `stick-r` | 48 px |
| `run-ring` | 1.6 r |
| `recenter` | 2 r |
| `chip-slop` | 8 px |
| dead bands | 32 px thumb side, 16 px other side, 16 px bottom |

Run grace is cut: it existed only to rescue v1's guard-on-touch-down.

## 4. Portrait presentation

### 4.1 Camera (render-side only)

- One-hand mode uses **BEHIND**; the camera option is not shown.
- **Per frame** in `duel-camera` when `portrait-p` and no cinematic, because cinema.lisp:42 resets the FOV to
  60 after every cinematic:
  - vertical FOV 66°, lens shift y +0.22;
  - `*behind-up*` 3.0, `*behind-back*` 6.5, `*behind-look*` 0.7;
  - `*behind-close*` 40° → 15° (at 2 m the 40° swing put P2 at the edge of a 33° horizontal view).
- There is **no FOV-fit rule**: v1's "0.6 of 16:9 coverage" works out to a vertical FOV of about 100°, which
  contradicted its own 66°.
- **`*behind-turn*` is unchanged** (sim state: it steers the human's stick). If the framing probe fails after
  a Hoho, the render yaw may lead the sim yaw by at most 20° toward P1 → P2. The stick still maps through the
  sim yaw.
- The framing probe decides. It logs both fighters' screen bounds every 30 f of a CvC run and requires the
  16 %–(deck top) band ≥ 95 % of the time, at the four sizes of §3.3.

### 4.2 HUD

- Top: the opponent's full panel in one row across the width. The own vital strip sits on the deck top.
- Own secondary gauges go onto their controls:
  - Reiatsu pips on SP1 / SP2;
  - flash-step as a line on the deck edge, ticks at 30 / 70;
  - cooldowns on O, L and SP2;
  - Fighting Spirit on the AWAKEN slot;
  - Inferno as an arc on L.
- Lanes: small words 0.30 h, big words 0.40 h, captions and callouts ≤ 0.52 h. Nothing informative inside
  the deck except the deck itself.
- Text floor: glyph ≥ 11 CSS px (`s = ceil(11 · dpr / 7)`, so 5 at DPR 3); `fit-scale` for long lines; short
  labels in portrait.

### 4.3 Cinematics (v2: full frame, no band)

- Cinematics play full-frame with the existing letterbox. In portrait a shot's `lens` uses max(fov, 66°) and no
  lens shift; the deck is hidden (the sim is frozen, and a tap skips).
- The vertical brush captions hang down the tall frame; clamp the glyph size to `min(0.6 h / n, 0.36 W)`.
- v1's band and its FOV formula are cut. A 129° full-frame FOV at `lens 88`, 55 % of pixels under the bars,
  bloom centred wrong. A proper band needs a viewport rect (G6b), deferred until stills show it is worth it.

### 4.4 Menus

- v2 adds tap zones to the **existing** screens (G9): every `hud-menu` row, the select arrows, and confirm.
  Menus render bottom-aligned into the deck area in portrait.
- A static gesture card replaces CONTROLS in one-hand mode.
- The full portrait re-layout of select and results, and the 6-card interactive tutorial, are deferred.

## 5. Engine gaps

| # | Gap | Minimal change | Phase |
|---|---|---|---|
| G1 | **Finger input** | `pf_pump`: FINGER_DOWN / MOTION / UP / CANCELED into a static 10-finger table (id, x, y in window px, x0, y0, **SDL event timestamp per sample**, down / began / ended). CANCELED is idempotent and never a lift-tap. **Fingers are cleared on FOCUS_LOST / HIDDEN / MINIMIZED** (with keys and mouse). Synthetic mouse buttons with `which == SDL_TOUCH_MOUSEID` are dropped (it only matters to RAVEN; the duel runs with `*pointer-lock*` nil, main.lisp:299). A debug hint `SDL_HINT_MOUSE_TOUCH_EVENTS=1` lets the mouse act as a finger. `pf_touch_*` accessors, 0 B. Under `run.mjs --fixed-dt`, `SDL_GetTicksNS` follows the virtual clock, so timestamps are deterministic. | P0 |
| G2 | **Recogniser + zones + pulse latch** | `engine/lisp/touch.lisp`, plain CL, host-tested; `gesture-config` | P0 crude, P1 hardened |
| G3 | **vpad fed by touch** | `(:touch name)` bindings in control.lisp; `p1-down-p` answers `:touch`; stick added to `ax ay`; the pilot extras (Burst rewrite, Hoho / F rule, U latch, Kikon latch) run after `vpad-read!` in the same reader | P0 / P1 |
| G4 | **DPR text floor** | `ui-scale` = max(current, ceil(`*ui-min-css*` · dpr / 7)); `*ui-min-css*` 0 on desktop (unchanged), 11 in portrait; `(pixel-density)` | P0 (one line) |
| G5 | **Viewport + back trap** | shell: `height:100dvh` (fallback 100vh), `viewport-fit=cover`, `-webkit-touch-callout:none`, safe-area probe → `(safe-inset side)`, `(portrait-p)`. **History trap**: `history.pushState` on the first tap (after user activation, or Chrome skips the entry); `popstate` → `Module` flag → pause + push again. | P0 (dvh, trap), P2 (insets) |
| G6 | **Lens shift** | camera `shift-x / shift-y` added in `m4-perspective!` (math.lisp:160), about 5 lines. G6b (a viewport rect for a cinematic band) is deferred. | P2 |
| G7 | **High-DPR pixel cap** | `*max-scene-pixels*` (1.6 MP) → `*render-scale*` at resize; `*auto-render-scale*` on touch devices; UI stays native | P0 (needed to measure fps honestly) |
| G9 | **Menu hit-testing** | `hud-menu` rows register G2 zones while drawing; `menu-nav` returns a tapped row | P3 |
| G10 | **Lifecycle** | wake lock in battle, re-requested on `visibilitychange` (the pause itself already exists via WINDOW_HIDDEN); PWA manifest (standalone, portrait) — **standalone, not fullscreen, on iOS**; check whether iOS 26's default "open as web app" makes the apple meta redundant; Android: `requestFullscreen` + `orientation.lock` on the first tap | P3 |
| G11 | **Device lost** (iOS often drops the GPU on backgrounding) | v1 of the answer: the existing fatal veil gets "TAP TO RELOAD", with settings in `localStorage`. No reinit. | P3 |
| G13 | **Tests** | run.mjs `--mobile` (DPR 3, `mobile:true`, touch emulation) **carried through `size` steps** (they currently reset `deviceScaleFactor:1, mobile:false`); touch steps → `Input.dispatchTouchEvent` (verify in P0 that pointer events with `pointerType:"touch"` result); `tests/scripts/touch.py` (tap / flick / hold / drag) | P0 |
| G14 | **Refusal cue** (duel, cosmetic) | a `*refused-t*` slot per chip; `:refused` on a no-bar press | P1 |
| — | Deferred until measured or asked | G8 haptics; G12 `request-gc` (24 MB / 13 KB ≈ 30 s is shorter than the gap between resets, so it would not prevent mid-fight GCs; measure the pause on a phone first and prefer cutting per-frame consing); G6b | — |

**Performance** (unchanged reasoning): about 2.1 ms of Lisp per frame on desktop, so expect 6–8 ms on a mid
phone. Pixels dominate, and G7 caps them. Low Power Mode at 30 fps is absorbed by the fixed step. The wasm is
5.6 MB and memory about 154 MB.

## 6. Mode integration

- **ONE-HAND VS CPU** (`*mode* :vs-cpu`, `*one-hand* t`) is preselected when `(pointer: coarse)` and portrait.
  It is listed whenever the window is portrait or touch-first. Desktop testing uses `--size 390x844`, a narrow
  window, or devtools device mode; a landscape desktop window does not offer it, because the layout needs
  portrait.
- A rotation to landscape during a match pauses and shows ROTATE TO PORTRAIT.
- Settings: HAND (RIGHT default / LEFT), ASSIST (OFF / LIGHT; FULL later), difficulty as today. Saved in
  `localStorage` (try/catch).
- CPU VS CPU is watchable in portrait with the same camera.
- There is no portrait VS PLAYER; see §9 for netplay.

## 7. Test strategy

1. **Host**:
   - `tests/touch-test.lisp`: every row of §3.2 and every boundary knob; CANCELED after `pointerup`;
     the latest-contact rule; dead-band starts; focus-loss clearing; the pulse latch across 0-step and
     2-step frames; chip slide-off keeps the hold; U-latch toggle and clear; the Kikon-latch swallow;
     `deck-layout-ok-p` at 4 sizes.
   - `duel-control-test` additions: gesture → vpad → command (rest→↑ in neutral = `:hoho`; in `:move` =
     `:f`; ↓ in stun = `:burst`; the SP chips modded).
2. **Determinism, two gates**:
   - (a) CvC hash lines unchanged vs `tests/style-cvc-ref.txt`: shared code untouched.
   - (b) **new**: a `--fixed-dt` touch script (tap / flick / hold / chip / latch) run twice gives identical
     hash lines, which catches any wall-clock leakage into the recogniser.
3. **Headless** (`--mobile --size 390x844`, DPR 2 or render-scale 0.5 for SwiftShader): `duel-touch-kit.json`
   produces all 11 commands + guard, walk, dash, the U latch, and a Kikon on a red P2 (debug 2314).
   Screenshots `tests/shots/mobile-*.png`.
4. **Probes**:
   - framing, at 4 sizes;
   - text floor;
   - 0 B consed by the recogniser and the deck HUD.
5. **Real phones** (P0 onwards):
   - one gesture-navigation Android (Chrome) and one iPhone on iOS 26 (Safari, later the PWA);
   - check fps, heap, 10-minute thermals, audio unlock, the back trap, dead bands, reach, and a GC pause
     measurement.
6. **Playtest logs**: gesture classification counts, plus misreads, counted as:
   - a Kikon released within 3 f of its press;
   - a Hoho not preceded by an opponent move within 20 f;
   - a Q fired within 30 f after a rest intended as a block.

## 8. Phased plan (lean first)

| Phase | Work | Exit / acceptance |
|---|---|---|
| **P0 playable prototype** | G1, G2 crude (rest / tap / flick / drag / the Hoho rule), G3, O / L / I / SP chips as plain circles, the glyph flash, G4, G5 (dvh + back trap), G7, G13; the existing behind camera and HUD at `--size 390x844` | On two real phones, a NORMAL match can be finished one-handed; gesture logs show misreads < 10 %; ≥ 50 fps after G7; the back gesture pauses instead of leaving; the P0 report tunes chip reach and knobs |
| **P1 recogniser hardening** | every §3.2 rule, latency via SDL timestamps, the latest-contact rule, dead bands, CANCELED, U latch, Kikon latch (LIGHT), G14, host tests | touch-test + control-test pass; both determinism gates pass; 0 B per frame |
| **P2 portrait presentation** | G6 lens shift, per-frame portrait camera, HUD re-layout, text floor, insets, deck-layout constraints at 4 sizes, cinematic lens clamp | framing and text probes pass at 4 sizes; mobile stills reviewed by the user; desktop stills unchanged |
| **P3 mode + shell** | MODE entry and auto-detect, settings, G9 menu taps, static gesture card, G10 wake lock + PWA (standalone), G11 reload | a fresh profile reaches a match in < 60 s of taps; the PWA runs standalone portrait on iOS; wake lock holds a 5-min match |
| **P4 tuning** | knobs, chip layout, auto-scale levels | playtest misreads < 5 %; a NORMAL median of 125–180 s; no throttle below 45 fps in 10 min |
| **Later, only on evidence** | FULL assist, approach tap, cinematic band (G6b), haptics (G8), interactive tutorial, touch trail, `request-gc` (G12), select / results re-layout, calibration card | each needs a playtest or measurement that asks for it |

## 9. Netplay-readiness (the user's future BT / Wi-Fi P2P versus)

- Touch and every assist only write the vpad. The **per-step vpad (buttons + stick) is the exchange unit**; a
  peer never needs to know about touch.
- Assists run in the local reader. Under rollback they must not re-run on re-simulation; the exchanged vpad
  already contains their output.
- Nothing mode-specific is sim state: `*behind-turn*` is unchanged, and portrait camera catch-up is
  render-side.
- One prerequisite noted for that future work, not built now: `*behind-yaw*` is a single global that assumes one
  camera-relative human. Netplay needs a view yaw per pilot (each peer is "P1" of its own view).

## 10. Risks

| Risk | Mitigation |
|---|---|
| Gesture misreads (slow flick vs drag, rest vs tap, fresh ↑ vs forward run) | Knobs, the glyph flash, fail-safe ordering, the P0 real-phone exit gate |
| Resting guard is 7 f slower than keyboard | Stated honestly. Pre-emptive guard only; heavies are still blockable. |
| The West / Nozarashi U batch lands differently | The pilot keys off that batch's own U mode; the latch is generic |
| Android back gesture, iOS home swipe | History trap, dead bands, P0 test on gesture navigation |
| iOS: standalone only, no vibrate, GPU loss on backgrounding, a reported 26.4 GPU-process crash | Stated in P3's acceptance; the reload veil; test the oldest iPhone in P0 |
| Phone GPU / thermals at DPR 3 | G7 + auto-render-scale, measured in P0 |
| GC pauses mid-fight | Measure in P0; cut per-frame consing before adding G12 |
| Chip reach varies with the hand | Layout is data with host-checked constraints; tuned in P0 / P4; the fold-SP variant for short screens |

## 11. Debate record (critique-mobile.md)

| # | Finding | Resolution |
|---|---|---|
| 1 | BLOCKER: guard at touch-down kills run cancels (run-step checks guard before Step, fighter.lisp:459), turns Q2 into Q1 after a fall to `:guard`, flickers the guard clip, gives free blocking to mashers, and a short block fires a Quick | **Accepted.** Guard engages only at `tap-ms`; a lift after that does nothing; run grace is cut; §10 states the 7 f cost. The code was re-checked (run-step, neutral-step, move-commands). |
| 2 | MAJOR: latency claim wrong; jitter hurts perfect Hoho and block strings | **Accepted.** Flicks fire at the crossing; only flick↑ = F waits ≤ 80 ms; timing uses SDL event timestamps; the §3.2 latency table replaces the claim. |
| 3 | MAJOR: Hoho vs F collide (guard → F impossible; a waiting thumb turns the Q2 → F branch into a Hoho cancel) | **Accepted.** Up-stroke in `:move` = F; Hoho only from neutral / guard after a rest; the string Hoho cancel is listed as lost. |
| 4 | MAJOR: West's armoured attacks impossible; `:u-moves` duplicates the batch's data and depends on it | **Accepted.** A U latch (toggle by long rest-and-release) keyed off the batch's own per-form U mode; attacks while latched are armoured. The flag is dropped. |
| 5 | MAJOR: the chip arc walls off the pad, I sits in the home band, the hit circles overlap, AWAKEN appears under the thumb, O commits wherever a gesture starts | **Accepted.** One contiguous pad; O above it, four chips in a thumb-side column; constraints host-checked at 4 sizes; AWAKEN held 300 ms; chips outside the pad, so touch-down firing is safe. |
| 6 | MAJOR: back gesture ends the match; palm contacts mute the thumb | **Accepted.** History trap (G5), 32 px thumb-side dead band, the latest-contact rule, a gesture-navigation Android in P0. |
| 7 | MAJOR: engine gaps (fingers not cleared on focus loss; CANCELED after every pointerup; frame-time quantisation; back trap; iOS device loss; visibility pause already exists; run.mjs resets DPR on size; refused-cue slots) | **All accepted**: G1 (clear, idempotent, timestamps), G5, G11, G10 note, G13 carry-through, G14. |
| 8 | MAJOR: the fit rule contradicts 66°; the cinematic band costs 129° FOV and 55 % hidden pixels; `*behind-close*` 40° puts P2 at the edge; cinema resets the FOV | **Accepted.** No fit rule; per-frame portrait FOV + shift; `*behind-close*` 15°; cinematics full-frame with a lens clamp; band / G6b deferred. |
| 9 | MINOR: `*behind-turn*` 420 in one-hand mode changes the sim for one peer (netplay) | **Accepted** (coordinator: keep it sim-side unchanged). Catch-up is render-side only; §9 records the netplay shape and the per-pilot yaw prerequisite. |
| 10 | MINOR: the CvC gate doesn't exercise the pilot | **Accepted.** New gate: a fixed-dt touch script run twice → identical hashes. |
| 11 | MINOR: assist details (approach-tap stick and cap; auto-guard reusing `sim-rnd01` and running in pilot-read; the latch's releasing contact buffers a Q; Burst gating at lift) | **Accepted.** Approach tap and FULL deferred (with the snap-ring rules written down); swallow the releasing contact; Burst = ↓ in `:stun` / `:air` writes `:mod` + `:quick`, buffered like Shift+J. |
| 12 | MINOR: drag semantics unspecified | **Accepted.** Back inside the slop and still for `tap-ms` → REST. |
| 13 | MINOR: small phones | **Accepted.** Deck in mm, a minimum arena of 35 %, probes and layout test at 360×640 / 375×667 / 390×844 / 430×932, SP chips fold on short screens. |
| 14 | MINOR: platform facts (vibrate, iOS PWA standalone, iOS 26 web-app default, 4.7 px nit) | **Accepted.** Wording fixed, P3 acceptance changed to standalone, the iOS 26 default to be verified, the nit corrected. |
| 15 | MINOR: G12 won't prevent mid-fight GCs; desktop landscape can't host the mode | **Accepted.** G12 deferred until a phone measurement; desktop testing via portrait-sized windows / `--size`. |
| 16 | MAJOR: phase order and scope | **Accepted** in full: P0 is a crude playable prototype on real phones; the deferred list is §8's last row; kept: pulse latch, DPR text floor, dvh / insets, G7, the left-hand mirror. |

No finding was rebutted. Each one was checked against the cited code and held.

## Sources

[Smashing: The Thumb Zone](https://www.smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users/) ·
[A List Apart: How We Hold Our Gadgets](https://alistapart.com/article/how-we-hold-our-gadgets/) ·
[LogRocket: touch target sizes](https://blog.logrocket.com/ux-design/all-accessible-touch-target-sizes/) ·
[Android: touch target size](https://support.google.com/accessibility/android/answer/7101858?hl=en) ·
[BlueStacks: MCOC guide](https://www.bluestacks.com/blog/game-guides/marvel-contest-of-champions/mcoc-beginners-guide-en.html) ·
[Law of Game Design: MCOC](https://lawofgamedesign.com/2014/12/19/theory-marvel-contest-of-champions-and-2d-fighting-with-few-controls/) ·
[TouchArcade: MKX](https://toucharcade.com/2015/04/08/mortal-kombat-x-review/) ·
[Bleach: Brave Souls official](https://www.bleach-bravesouls.com/en/howto/article07.html) ·
[Nekki: Shadow Fight 3 controls](https://nekki.helpshift.com/hc/en/8-shadow-fight-3/faq/170-in-game-controls/) ·
[Deconstructor of Fun: Archero](https://www.deconstructoroffun.com/blog/2019/8/9/why-archero-banked-25m-but-leaves-25m-hanging-hlx9n) ·
[Mobile Free To Play: control mechanics](https://mobilefreetoplay.com/control-mechanics/) ·
[Capcom SF6 WTB #004](https://www.streetfighter.com/6/column/detail/wtb004) ·
[SDL wiki README-touch](https://wiki.libsdl.org/SDL3/README-touch) ·
[SDL #13161](https://github.com/libsdl-org/SDL/issues/13161) ·
[WebGPU in iOS 26](https://appdevelopermagazine.com/webgpu-in-ios-26/) ·
[Apple forums: iOS 26.4 GPU crash](https://developer.apple.com/forums/thread/822200) ·
[web.dev: Screen Wake Lock](https://web.dev/blog/screen-wake-lock-supported-in-all-browsers) ·
[mdn/bcd #29166](https://github.com/mdn/browser-compat-data/issues/29166)

## User decisions (2026-09-26)
1. Default handedness: RIGHT (left-hand mirror still built, selectable in options).
2. FULL assist: NO damage scaling; only the ASSIST tag on the results screen.
3. Portrait local VS PLAYER: out of scope. Future: online versus over Bluetooth / Wi-Fi P2P. Nothing to build now; only do not preclude it (touch stays a vpad device; inputs, not state, are what a netcode layer would exchange; the sim is already deterministic).
