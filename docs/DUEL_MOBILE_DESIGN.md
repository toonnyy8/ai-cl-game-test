# SOUL DUEL: ONE-HAND (片手) mode, a portrait phone played with one thumb (design v2)

> Status: **P0 + the PWA part of P3 built (2026-09-26, the user's decision: "a simple one-hand mode + PWA")**, played
> on two real phones on 2026-09-27 and tuned from that playtest (§13); §12 lists what was built and where it deviates.
> **P2 (portrait presentation) built 2026-09-27** at the user's request, with two decisions of the user that replace
> parts of §4.1 / §4.2 (§14). **2026-09-28: the gestures remapped** (tap zones J / K, up-flick = the forward dash), the
> portrait HUD's flames enlarged onto the name row with thicker small gauges, and close-up cinematics not backed off (§15).
> **2026-09-28: one-hand is a setting** (§16): ONE-HAND MODE AUTO / ON / OFF on the new SETTINGS screen (with HAND, TAP
> SPLIT, SENSITIVITY, CAMERA); ONE-HAND VS CPU is merged into VS CPU, and PRACTICE is one-handed the same way.
> P1 and the rest of P3 are still design.
> Working notes (critiques, v1 drafts, research) were kept outside the repo; the debate outcome is recorded below.

v1 is kept as `design-mobile-v1.md`. This version answers `critique-mobile.md` (1 BLOCKER, 8 MAJOR, 7 MINOR);
§11 records each finding and how it was resolved. It includes the user's decisions of 2026-09-26: right hand
is the default and the left-hand mirror is an option; FULL assist has no damage scaling, only an ASSIST tag;
there is no local portrait 2P; future Bluetooth / Wi-Fi P2P netplay must stay possible.

## 給使用者的摘要（繁體中文）

- **新模式「片手 ONE-HAND」**：手機直拿，一根拇指對戰電腦。預設右手，選項裡可以換成左手。
- **2026-09-28 改成設定（§16）**：選單不再有單獨的「ONE-HAND VS CPU」，只有 VS CPU；新的 SETTINGS 畫面裡的 ONE-HAND（AUTO／ON／OFF，預設 AUTO＝觸控手機直拿時開）決定 VS CPU 和新的 PRACTICE 用不用拇指操作。HAND、點擊分界（TAP SPLIT）、撥動靈敏度（SENSITIVITY）、鏡頭也都在 SETTINGS，存在瀏覽器裡。
- **防禦不再是「一碰就擋」**：拇指按著不動超過約 0.12 秒才開始防禦，比這短的就是點擊，也就是 Quick。這樣連段、跑步取消都不會被誤觸的防禦打斷。代價是預先防禦慢了約 7 格；反應型防禦反正本來就來不及，重招照樣擋得住。
- **撥（flick）在劃過門檻的那一刻就出招**，不必等手指離開，延遲變得穩定。離開容許範圍後的前 120 ms 角色不會先走（2026-09-27 真機試玩後的調整，見 §13）。
- **2026-09-28 重新對應（使用者的決定，§15）**：手勢區以中線分上下兩塊，**點下半塊 = J（輕）、點上半塊 = K（重）**；**往上撥 = 向前衝刺**（往前的 Step，撥完手指繼續往前推就接著跑），不再是 K。
- **Hoho**：站著或防禦時，按住不動再往上撥。沒先按住的往上撥一律是向前衝刺。單手版少了「連段中取消成 Hoho」這一招。
- **連段**（2026-09-27，[DUEL_STRINGS.md](DUEL_STRINGS.md)）：點下半 = J、點上半 = K，最多三段，J 與 K 之間最多換一次（多換的那一下會被忽略）；下一段在前一段的任何時候都可以先按（會記住，打中或被擋才出）。完整打中第 3 段後按 O 晶片是 O 收尾：點一下只有擊退，按住就衝上去接毀魂技。
- **Burst**：被打中、硬直或浮空時往下撥，跟 Shift+J 一樣會記在緩衝裡。
- **拇指按著不動就是 U**（2026-09-26 的 guard v3 決定之後）：野晒三杯的「喝」本來就是防禦，所以任何型態按著不動都一樣。原本設計的「長按放開鎖住 U」手勢已經刪掉。2026-09-27 山本卍解重製之後：在『東』按著不動就切到『西』（全方位防禦、沒有防禦硬直），切過去之後不會自己切回東，要出 L、SP1 以外的招式才回東（[DUEL_YAMA_REWORK.md](DUEL_YAMA_REWORK.md)）。
- **放開拇指才會回防禦量表**：防禦中量表不回，等待回復的 1 秒也暫停計時（放開後接著算，不是重算）。所以單手時「拖、停、拖」的走位不會讓量表永遠回不來；防禦中拇指下的墨圈會變暗，提醒「抬起拇指喘口氣」。
- **按鈕重新排過**：手勢區是一整塊 342×410 px 的連續區域（2026-09-27 從 260×194 擴大，並把圓鈕那一欄包進去：落在圓鈕判定圓裡算按鈕，其他地方都是手勢）。所有圓鈕比原設計高 100 px，O 放在手勢區上方，其餘四顆（L、I、SP1、SP2）沿拇指側排成一列，不會碰到 Home 條和側邊的返回手勢區。覺醒要按住 0.3 秒。
- **防止誤退出**：會先 push 一筆瀏覽紀錄，擋住 Android 側滑返回和 iOS 返回，觸發時改成暫停；拇指那一側的邊緣也留 32 px 死區。
- **鏡頭**（2026-09-27 做好，§14）：直拿時改用專用的背後鏡頭，角色放大、放在畫面中下方，拇指擋到腳沒關係（使用者的決定）；鏡頭會把兩個人一起框進上下兩塊量表之間，太遠或靠牆時自動拉廣。貼身時的轉角從 40° 降到 15°。所有調整都只在畫面端，Hoho 後鏡頭怎麼追上也只在畫面端做（最多提前 20°），不改模擬端的 `*behind-turn*`。這樣兩台手機將來連線，搖桿方向的換算也不會不同步。
- **量表**（2026-09-27 做好，§14）：依角色分上下（使用者的決定）。對手的血條和量表在畫面最上方，自己的在最下方（Home 條上面），各佔整個寬度，所以字和條都能放大；計時器在上面那塊的右邊。文字最小 11 CSS px。
- **先做能玩的原型**：P0 直接做一個粗略但能打完整場的單手版，拿兩支真手機驗證；確定可行後才做直向排版、選單和 PWA。
- **延後的項目**：FULL 輔助、自動衝近、過場橫幅、震動、互動教學、觸控軌跡、主動 GC。LIGHT 輔助只保留「O 點一下就鎖住」。
- **將來連線對戰**：觸控和輔助都只寫 vpad，連線時交換的是每一步的 vpad，模擬端不需要知道你是用手機操作。另外新增一個測試：同一段觸控腳本跑兩次，雜湊必須完全一樣。
- **還需要你決定的**：無。原本的三個問題都已經有答案了。

---

Status: design only; nothing in the project was edited. Code references were re-checked for this revision:
fighter.lisp run-step 453–462 (guard before the Step release), move-commands 400–418, stun-step 420–426;
main.lisp pilot-read 43–47; hud.lisp `*refused-t*` 240–247; design-nozarashi.md §2.4 (U: ARMOUR / U: DRINK; since guard v3 both are guards: `U: GARB` / `U: DRINK`).

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
| **TAP** | lifted ≤ `tap-ms` (120) after down, travel < `slop` (10 px) | `:quick` pulse | J (Quick). A string is three taps / flicks↑ with at most one change between tap and flick (JJJ, JJK, JKK, KKK, KKJ, KJJ; an extra change is eaten, DUEL_STRINGS §2.1); the latch takes each gesture any time during the link before. After a link-3 hit the O chip is the O ender (a tap: its hit; held: the dash-in to the Kikon; the LIGHT latch is not built). |
| **REST** | still for `tap-ms` | U held (every form: since guard v3 U is a guard in every form, §3.4) | Guard (it blocks after the existing 2 f raise). Lifting after this point does **nothing** else. While a rest guards, the guard gauge neither refills nor counts its refill delay (GUARD HOLD, DUEL_DESIGN §4): **lift the thumb to breathe**. The delay is frozen, not restarted, so drag, rest, drag footsies still refill between rests. |
| **FLICK** (not up) | travel reaches `flick-min` (28 px) within `flick-window` (120 ms) of leaving the slop | fires **at the crossing**: `:step` pulse + stick = stroke direction | Step (↓ back, ←/→ sidestep, diagonals). If the thumb keeps going past the run ring, `:step` stays held: the hop, then the run, as holding Space does. |
| **FLICK ↓ in `:stun` / `:air`** | same | `:mod` + `:quick` | Burst Reverse, buffered like Shift+J (fires on hit 2 if pressed after hit 1) |
| **HOHO** | a REST contact (≥ `tap-ms` still) in neutral or guard, then an up-stroke crossing `flick-min` | fires at the crossing: `:mod` + `:step` | Hoho from guard. The perfect-Hoho read is intact. |
| **FLICK ↑ = F** | a fresh up-stroke (within `up-cone`, 60° either side of vertical since §13), or any up-stroke while in `:move` | `:flash` pulse once the thumb lifts within `up-lift-ms` (150 since §13; was 80) of the crossing; nothing moves before that | K (Flash): a K link anywhere in a string. Not lifted in time → DRAG instead (forward walk or run). |
| **DRAG** | left the slop, and the flick window closed without a flick (§13: until then the stroke is *undecided* and the stick stays at 0) | stick = Δ / `stick-r` (48 px); origin follows past 2 r | Walk / strafe (up = toward him, through the behind view) |
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

### 3.4 Chips (the U latch is deleted)

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
- **No U latch.** This design had one (a long rest-and-release toggling U on) for the forms whose U was not a
  guard: West's hold-U armour and Nozarashi T3's DRINK. Guard v3 (the user's decision 2026-09-26) replaced West's
  armour with the garb guard, and DRINK already was a guard, so **U is a guard in every form** and a rest holds
  it everywhere, exactly as §3.2. The latch, its knob, its glyph, its tests and its risk row are deleted. Since the
  Bankai rework (2026-09-27, DUEL_YAMA_REWORK.md) a rest in Bankai East switches him to West (the ward: a 360° guard
  with no blockstun); it doesn't flip back: an attack other than L / SP1 does.

### 3.5 Keyboard → one-hand map

| PC | One hand |
|---|---|
| WASD | Drag |
| Space (tap / hold) | Flick / drag far |
| U (hold) | Rest (every form) |
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

Everything decisive remains: the O ender off a completed string, the true Kikon hold and release, the perfect-Hoho
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

- The recognised gesture flashes its glyph at the thumb for 0.3 s (↑ F, ↓ STEP, 歩 HOHO). This is
  the misread teacher and stays in P0.
- The floating stick is an ink ring (run ring dashed). **GUARD HOLD cue**: while a rest guards and the guard
  gauge is below full (so its refill is frozen), the ring dims (render only; not for a Bankai, whose gauge never
  refills by time): "lift the thumb to breathe". Chips show pressed / cooldown / cost / refused states.
- Deferred: the brush touch trail and haptics (Android only anyway; WebKit has no Vibration API).

### 3.8 Knobs (one `gesture-config`; tuned in P0 / P4)

| Knob | Default |
|---|---|
| `tap-ms` | 120 ms |
| `slop` | 10 px |
| `flick-min` | 28 px |
| `flick-window` | 120 ms |
| `up-lift-ms` | deleted in §15 (was 150 ms; 80 until the §13 playtest) |
| `up-cone` | 1.73 = tan 60°: a flick is up while \|dx\| ≤ 1.73 \|dy\| (45° until §13); since §15 an up-flick is the dash, straightened to dead ahead |
| `tap-split` | 0.5 (§15): taps above this fraction of the pad's height are K, from it down J |
| `stick-r` | 48 px |
| `run-ring` | 1.6 r |
| `recenter` | 2 r |
| `chip-slop` | 8 px |
| dead bands | 32 px thumb side, 16 px other side, 16 px bottom |

Run grace is cut: it existed only to rescue v1's guard-on-touch-down.

## 4. Portrait presentation

### 4.1 Camera (render-side only)

> **As built (§14):** the user's decision of 2026-09-27 replaced the framing goal: larger fighters, low in the frame, the
> thumb may cover their feet. The numbers below (66°, shift 0.22, the 16 %–deck band) are the v2 design, kept for the record.

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

> **As built (§14):** the user's decision of 2026-09-27 splits the HUD by fighter instead: P2's block across the top, P1's
> across the bottom, both full width. The gauges did not move onto the chips.

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

> **As built (§14):** as written, plus a dolly (the eye backs off the shot's target) so the tall frame's width holds a
> landscape frame's central square; a shot's side offset is halved in portrait.

- Cinematics play full-frame with the existing letterbox. In portrait a shot's `lens` uses max(fov, 66°) and no
  lens shift; the deck is hidden (the sim is frozen; a tap no longer skips, 2026-09-28).
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
| G3 | **vpad fed by touch** | `(:touch name)` bindings in control.lisp; `p1-down-p` answers `:touch`; stick added to `ax ay`; the pilot extras (Burst rewrite, Hoho / F rule, Kikon latch) run after `vpad-read!` in the same reader | P0 / P1 |
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

> Superseded on 2026-09-28 by §16: one-hand is the ONE-HAND MODE setting, VS CPU and PRACTICE take the deck whenever it
> is in effect; the separate ONE-HAND VS CPU and HAND rows are gone. The text below is the P0 design.

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
     2-step frames; chip slide-off keeps the hold; the Kikon-latch swallow;
     `deck-layout-ok-p` at 4 sizes.
   - `duel-control-test` additions: gesture → vpad → command (rest→↑ in neutral = `:hoho`; in `:move` =
     `:f`; ↓ in stun = `:burst`; the SP chips modded).
2. **Determinism, two gates**:
   - (a) CvC hash lines unchanged vs `tests/style-cvc-ref.txt`: shared code untouched.
   - (b) **new**: a `--fixed-dt` touch script (tap / flick / hold / chip / Kikon latch) run twice gives identical
     hash lines, which catches any wall-clock leakage into the recogniser.
3. **Headless** (`--mobile --size 390x844`, DPR 2 or render-scale 0.5 for SwiftShader): `duel-touch-kit.json`
   produces all 11 commands + guard (DRINK and Bankai East → West included: a rest), walk, dash, and a Kikon on a red P2 (debug 2314).
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
| **P1 recogniser hardening** | every §3.2 rule, latency via SDL timestamps, the latest-contact rule, dead bands, CANCELED, Kikon latch (LIGHT), G14, host tests | touch-test + control-test pass; both determinism gates pass; 0 B per frame |
| **P2 portrait presentation** (built 2026-09-27, §14) | G6 lens shift, per-frame portrait camera, HUD re-layout, text floor, insets, deck-layout constraints at 4 sizes, cinematic lens clamp | framing and text probes pass at 4 sizes; mobile stills reviewed by the user; desktop stills unchanged |
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
| 4 | MAJOR: West's armoured attacks impossible; `:u-moves` duplicates the batch's data and depends on it | **Accepted**, then **superseded** by guard v3 (2026-09-26): the U latch it added is deleted because West's U is now the garb guard and every U is a guard (§3.4). The flag stays dropped. |
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

## 12. Build status (2026-09-26: P0 + the PWA part of P3)

The user asked for 「一個簡單的『手機單手直拿模式』，並以 PWA 建構出近似應用程式的體驗」. Built, in the leanest form:

| Piece | Where | As built |
|---|---|---|
| G1 finger input | `engine/c/platform.c` | `pf_pump` queues this frame's FINGER_DOWN / MOTION / UP / CANCELED (≤ 64) with the SDL event timestamp (ms) and a finger slot 0..9; UP / CANCELED free the slot, so the CANCELED SDL sends after every touch `pointerup` finds no slot and is dropped (idempotent, never a tap). FOCUS_LOST / HIDDEN / MINIMIZED clear every finger (a "cancel all" record). Mouse events with `which == SDL_TOUCH_MOUSEID` are dropped. `pf_touch_copy` hands the queue to Lisp in window px. `pf_density`, `pf_page_get / pf_page_set` (page services, below). |
| G2 recogniser | `engine/lisp/touch.lisp` (plain CL, `tests/touch-test.lisp`) | §3.2: TAP (lift ≤ `tap-ms` inside the slop), REST (still `tap-ms` inside the slop of the stick origin = guard; also "back to rest"), FLICK at the crossing (`flick-min` within `flick-window` of leaving the slop), FLICK ↑ = F only on a lift within `up-lift-ms`, rest → ↑ = Hoho at the crossing when the game allows it, DRAG (origin follows past 2 r), DRAG far (Step held, released inside 1.3 r), the latest pad contact wins, chips held until lift, a hold chip (AWAKEN 300 ms), the pulse latch, menu taps. Knobs: `gesture-config` (§3.8 defaults). `defun-fast`, squared distances: no per-event consing. |
| G3 vpad | `duel/lisp/control.lisp`, `fighter.lisp`, `onehand.lisp` | `(:touch name)` in P1's bindings; `p1-down-p` answers `:touch` through `touch-button`; the drag stick is added to pad 0's. Burst = a down-flick while P1 is in `:stun` / `:air` (decided per vpad read). Fighters, rules and the AI are untouched. |
| Chips | `onehand.lisp` | O, L, I, SP1, SP2 as plain circles at the §3.3 spots (CSS px from the thumb-side and bottom edges; LEFT mirrors x), AWAKEN at its spot only at EVOLUTION (hold 300 ms), a pause chip II. The recognised gesture's word flashes over the thumb for 0.3 s; an ink ring marks the stick origin (dim while resting). |
| G4 / G5 / G7 | `engine/lisp/ui.lisp`, `engine/web/shell.html`, `render.lisp` | `*ui-min-css*` 11 in any portrait window (desktop landscape: 0, unchanged); `100dvh`, `viewport-fit=cover`, no touch callout / tap highlight; back trap in `duel/web/pwa.js`; `*scene-scale-cap*` keeps the scene near 1.6 MP on a phone, `*auto-render-scale*` on coarse pointers. |
| Mode entry | `flow.lisp`, `hud.lisp` | MODE lists ONE-HAND VS CPU and HAND RIGHT / LEFT first when the window is portrait or the pointer is coarse (preselected on a coarse portrait device); HAND is saved in `localStorage` (try/catch). One-hand = VS CPU, behind camera, no CAMERA option. CONTROLS shows a static gesture card. Menu rows are tap targets; the select screen reads a tap's third (left / right / confirm); a tap skips the intro (battle cinematics can't be skipped: the user's decision 2026-09-28); the back gesture = Esc (back / pause). Landscape mid-match pauses with ROTATE TO PORTRAIT. |
| PWA | `duel/web/` (copied into `dist/duel` by `build.sh`; `head.html` goes into the shell), `tools/pwa-icons.py` | `manifest.webmanifest` (standalone, portrait, colours, icons 192 / 512 / maskable 512), apple meta + `apple-touch-icon.png`, `sw.js` (versioned cache: `build.sh` writes a hash of the build into it), wake lock in battle (re-requested on `visibilitychange`), Android fullscreen + `orientation.lock('portrait')` on the first tap (not iOS). |
| Tests | `tests/touch-test.lisp`, `tools/run.mjs --mobile [--dpr N]` (+ touch steps), `tests/scripts/duel-touch.py` → `duel-touch.json`, `duel-touch-left.json` | the headless script reaches a match by taps alone and produces Q, guard, Step (down, side), dash / run, Hoho, F, the Kikon rush and L; run twice under `--fixed-dt` its hash and combat lines are identical. Stills: `tests/shots/mobile-{battle,pause,left,rotate}.png` (390 × 844, DPR 3). |

**Deviations from the design** (each a simplification, to be revisited in P1 / P2 if the phones ask for it):
- G1 is a per-frame **event queue** (type, slot, x, y, timestamp), not a 10-finger state table: the recogniser needs the order and the times of the samples anyway.
- ~~The drag stick is live as soon as the thumb leaves the slop (the flick check runs alongside), so an up-flick walks forward for a few frames before its F.~~ This is what broke K on the phones; fixed in §13 (the stick waits for the flick window).
- After a non-up flick, Step stays held until the thumb stops for `tap-ms`, comes back under `flick-min`, or lifts (the design only said "past the run ring": this keeps flick → keep going = hop then run without a second Step press).
- The layout is fixed CSS px from the edges (moved up and the pad enlarged in §13) (no millimetres, no `deck-layout-ok-p`, no SP fold for short screens); the pause chip is a tap at the thumb side, 200 CSS px from the top (not a 300 ms hold).
- Portrait HUD: only the minimal fix. The text floor made the timer and the centre labels overlap the panels at 390 × 844, so in portrait the timer sits under the panels at half size and the panels' centre labels are drawn at half scale; the Kikon / Burst prompts move to 0.52 h in one-hand. No lens shift, no portrait camera (G6): the existing behind camera is playable at 390 × 844 (see the stills).
- Service worker: **cache-first from one versioned cache** for every file, index.html included, instead of network-first index.html: a network-first page could pair a new index.html with an old index.js / index.wasm. Updates still land: the browser re-checks `sw.js` on each launch, the new build installs a new cache and takes over, and `pwa.js` reloads the page once.
- The back trap, fullscreen / orientation lock, the service worker and the wake lock run only on a coarse pointer, so a desktop browser behaves exactly as before.
- Not built (as scoped): G6, G11 (device lost), G14, safe-area insets, the framing / text probes, LIGHT's Kikon latch and every assist, haptics, the tutorial, gesture-log misread counters, `duel-control-test` gesture rows.

**Known issues**: the duel's startup heap reads 87.1 MB instead of 55.4 MB (still under the 110 MB budget, wasm memory unchanged at 128 MB; RAVEN's identical binaries also flip between 57 and 71 MB, so it looks like a Boehm heap-growth threshold, not new data); the deck HUD's labels go through `hud-text` and cons a little per frame (not the 0 B of the P1 probe); a human P1 on desktop conses about +40 B / frame (two stick floats per vpad read).


## 13. Playtest 1 and its fixes (the user's decision 2026-09-27)

The user played P0 on two real phones.

**Passed:** a NORMAL match finished one-handed; fps smooth; the back gesture pauses; the screen stays awake; the
left-hand mirror works; the PWA launches offline.

**Problems (verbatim):**
1. 「步法和 K 非常難分開，非連擊中上撥幾乎會觸發步法而不觸發 K」: outside a string, an up-flick (K = F) almost always
   stepped instead.
2. 「整體按鍵位置應該要往上，手勢操作的接受範圍也要再擴大」: move the chips up; enlarge the gesture area.

**Root cause of 1.** The drag stick went live the moment the thumb left the 10 px slop, and it stayed live in the
up-pending phase while the F waited for the lift. A real flick keeps travelling well past the 28 px crossing
(60–140 px), so from neutral the stick walked forward, and past the run ring (1.6 × 48 = 77 px) it held Step:
the fighter hopped (a 24 f Step that no command cancels), and the F, when the lift came, was buffered into the hop
and lost. When the lift came more than 80 ms after the crossing, which is common for a relaxed flick, there
was no F at all, just a drag. A right thumb's "up" also sweeps up-left; beyond 45° it was read as a sidestep
flick. Inside a string none of this showed, because a move ignores the stick and Step.

**Fixes (engine/lisp/touch.lisp, knobs in `gesture-config`):**
- A new recogniser phase, **undecided** (6): the stroke has left the slop but the flick window (`flick-window`,
  120 ms) is still open. The stick reads 0 and Step is not held. The stroke becomes a DRAG when the window closes
  (on the next motion or on the frame clock, so a thumb that stops also resolves), or a flick at the crossing.
- The **up-pending** phase (4) no longer moves the stick or holds Step either: only a DRAG (2) does.
- `up-lift-ms` 80 → **150 ms**; `up-cone` (new) **60°** either side of vertical (was 45°).
- Cost: a slow drag starts moving up to 120 ms after it leaves the slop (the flick window), and a fast forward
  stroke that is not lifted starts its walk / run up to 150 ms after the crossing. Timing still uses the SDL event
  timestamps only.

**Fixes for 2 (duel/lisp/onehand.lisp, CSS px at 390 × 844, right hand):**

| | Before | Now |
|---|---|---|
| O, AWK (r 36, 26) | y 548 | y 448 (100 px up) |
| L, I, SP1, SP2 (x 318, r 26) | y 564 / 632 / 700 / 768 | y 464 / 534 / 604 / 674 |
| Flow pad | x 16–276, y 600–794 (260 × 194) | x 16–358, y 384–794 (342 × 410) |

The pad now covers the chip column and O: a touch-down inside a chip's hit circle (radius + 8) takes the chip,
as before; anywhere else in the pad starts a gesture, and a gesture that crosses a chip stays a gesture (chips
claim only touch-downs). The left hand mirrors x (pad 32–374). The pause chip is unchanged.

**Tests:** `tests/touch-test.lisp` adds a long neutral up-flick lifted 116 ms after the crossing (F, no stick, no
Step), a 50° slanted up-flick (F), a slow drag (0 while undecided, then walks; the clock alone also resolves it),
and flicks at a chip's boundary; `duel-touch.py` adds a 140 px up-flick from neutral (F, no Step in the log).

## 14. P2: portrait presentation (built 2026-09-27)

The user's request 2026-09-27: 「再來請你調整手機模式的 UI 與運鏡。」 (adjust the mobile mode's UI and camera work). The
stills of P0 showed the problems: the landscape HUD squeezed into two 0.36 w columns (nine Konpaku flames per side ran
into each other, the combo counter sat on the timer, the labels were under the text floor), prompts and callouts cut off
at the screen edge, the behind camera left the top half empty and put both fighters under the chips, and cinematics
framed for 16:9 showed a sliver of their subject.

**The user's decisions 2026-09-27** (given during the work; they replace parts of §4.1 and §4.2):
1. 「血條跟各種計量表 UI 我認為可以依據人物分開放上面與下面，如此就能放大 UI 使其不至於太小。」 The HUD is split by
   fighter: the opponent's (P2's) health and gauges across the top, the player's (P1's, the fighter near the camera)
   across the bottom, each block full width so it can be larger.
2. 「角色可以再放大然後往畫面中下方移動，就算被大拇指擋到人物下半身也沒關係。」 The fighters larger, lower in the frame;
   the thumb covering their lower bodies is fine. The framing check became: both fighters' upper bodies and heads visible
   and clear of the HUD blocks, at the four sizes, including at maximum separation.

| Piece | Where | As built |
|---|---|---|
| G6 lens shift | `engine/lisp/render.lisp` | `camera-shift-y` (NDC, 0 = none): `update-camera` writes `-shift` into the projection's row 1 column 2 only when it is not 0, so every landscape frame's matrices are the same floats as before. `world-to-screen`, the fx billboards and the shaders use the matrices, so nothing else changed. |
| Portrait camera | `duel/lisp/camera.lisp` `%portrait-camera` | Any battle in a portrait window (ONE-HAND, and CvC watched on a phone). Behind P1: `*pt-back*` 9 (x `*cam-close*` 0.6 = 5.4 m, + 0.2 m per metre of separation past 4 m), `*pt-up*` 2 m, `*pt-shoulder*` 0.5 m, the close-range swing `*pt-close*` 15° (landscape 40°). The orbit leads the sim's `*behind-yaw*` by at most `*pt-lead*` 20° toward P2 (smoothed at 8/s): the render-side catch-up after a Hoho or a sidestep; `*behind-yaw*` and `*behind-turn*` are untouched. The aim bisects the two fighters (azimuth: their centres; pitch: P1's near feet and 0.3 m over P2's head), within 20° of the orbit. The lens: the frame (`*band*`: under P2's block + 3 %, down to `*pt-frame-bottom*` 0.82 of the height) spans `*pt-band-fov*` 30°; the vertical FOV widens past that only when the pair needs it (a vertical fit, and a horizontal fit with 0.7 m of bulk), within `*pt-fov-min*` 40° .. `*pt-fov-max*` 100°, smoothed; the shift puts the aim on the frame's middle (0.089 at 390 × 844). Typical FOV 41–53°, about 64° right after a sidestep. 0 B per call except a boxed float when the FOV moves by > 0.1° (~3 B a frame). |
| Cinematics | `camera.lisp` `%portrait-dolly`, `cinema.lisp` | §4.3's lens clamp: FOV at least `*pt-cine-fov*` 66°, no shift, and the eye backed off the shot's target so the frame's width holds the landscape frame's central square (factor tan(lens/2) / (tan(fov/2) aspect), at most `*pt-dolly-max*` 2.4, kept inside the 18 m ring). `LENS` records the script's FOV in `*lens-fov*`; `SHOT-ON` halves a shot's side offset. Captions: glyphs at most 0.36 W (§4.3), callout columns stop at the frame's bottom. |
| HUD | `duel/lisp/hud.lisp` `hud-side-portrait` | Decision 1. P2's block under the top safe-area inset, P1's over the bottom one (at least 8 CSS px up), each 29 s tall (48 CSS px at DPR 3) on a soft ink gradient: row 1 the name at 1.4 s, the KOSEI tag (攻 ×n) after it, one label at the right end (EVOLUTION, else INFERNO / NOME / COOLDOWN, else U's tag) and on P2's block the timer; Reishi (5 s tall), the guard gauge (2 s); the Konpaku flames (r 2.4 s) at the left and four unlabelled small gauges beside them in the landscape colours: Reiatsu cells, flash step, Awakening, the kit meter or the L cooldown (one bar, 2026-09-28; Rukia's awakened form draws her cold gauge there instead). The combo counter hangs under P2's block / over P1's. KIKON / BURST prompts are centred under P2's block. Words (ANNOUNCE) use the frame's lanes; move callouts are smaller (0.03 h) and kept on the screen; callouts dodge the bottom block upward. The deck is hidden while paused. |
| Insets (G5) | `duel/web/pwa.js`, `onehand.lisp` | page get 3 / 4 = `env(safe-area-inset-top / -bottom)` in CSS px, measured once per window size (tests: `gamePage.testInsets = [top, bottom]`). The top one moves P2's block, the bottom one P1's; the pad's bottom keeps 16 px over it (no change on today's phones). The chips stay where the §13 playtest put them. |
| Menus | `hud.lisp`, `main.lisp` `menu-camera` | Portrait: the title's lines split to fit, MODE's rows from 0.52 h (toward the thumb), SELECT stacked (the pair from a diagonal above, P1 / P2 rows, tap help), RESULTS as the winner in the top part under 勝 and a black card with the table and the menu below, the gesture card's rows spread down the screen. |
| Probes | `debug.lisp` 2700+k, `tests/mobile-probe.py`, `tests/scripts/duel-mobile.py`, `tests/mobile-sheet.py` | 2700: every 30th battle frame, both fighters' upper halves clear of the two blocks with ≥ 70 % of their width on the screen; the smallest pixel-font glyph (engine `*ui-text-min*`). 2701 24 m apart, 2702 P2 flashed to P1's side, 2703 1 m, 2704 consing. `mobile-probe.py`: a 45 s YK CvC plus five set shots at 360 × 780, 390 × 844, 430 × 932, 412 × 915 and 390 × 844 with iPhone insets. |

**Results.** `mobile-probe.py`: ALL PASS, both upper halves clear in 83 / 83 CvC samples at every size, every set shot
inside (1 m, 2.2 m, 24 m with the eye pulled in by the wall, the sidestep 0.1 s and 0.5 s after), the smallest glyph
5 px = the floor at DPR 3. At 2.2 m P1's box fills 0.49 of the height and P2's 0.41 (P0's still: about 0.42 / 0.37, P1
cut at the left edge); FOV 41–46° up close, 49° at 24 m, 63–65° just after the sidestep. Landscape is unchanged: 41 desktop duel stills byte-identical to a build of the previous commit, G1
RAVEN identical, G2 CvC hashes unchanged, the duelstill identical, smoke passes; the touch script run twice under
`--fixed-dt` gives identical hash and combat lines (the same sequence as the previous build); G3: frame time x1.008,
startup heap 88.6 MB either way. The review sheets:
`tests/shots/mobile-review.png` (battle, before / after), `mobile-review-screens.png` (cinematics, menus),
`mobile-review-insets.png` (an iPhone's safe area).

**Deviations from §4.** The fixed 66° / shift 0.22 camera became the fit above (decision 2 wants the fighters larger than
66° allows; the band between the blocks is 0.87 h, not the 16 %–deck band). The own gauges did not move onto the chips
(decision 1 gave them a full-width block instead). Still not built: millimetre deck sizing, `deck-layout-ok-p`, the SP
fold for short screens (the deck is the §13 one in CSS px), chip faces (Reiatsu pips, cooldown sweeps).

**Known issues.** The fighters' feet stand among the chips (decision 2). The right-hand brush callout column (P2's SP
names) can overlap the chip column. The portrait HUD conses like the landscape one (about 1.5 KB a frame, HUD-TEXT);
the camera and the dolly are 0 B but for the FOV writes. The CvC framing probe's box is the hurt cylinder + 0.25 m, so a
wide sword swing can still cross the screen edge.

## 15. The user's decisions 2026-09-28: the gesture remap, the portrait HUD rows, close-up cinematics

**Requests (verbatim):**
1. 「手勢模式［右手模式］幫我調整為朝上方滑動判別為向前衝刺，然後點擊區域改成分上下區塊來分開輕重攻擊。」 An upward swipe is
   the forward dash; the tap area splits into an upper and a lower block for the light and the heavy attack.
2. 「狀態列將魂魄改成獨立的一列，然後加粗血量與防禦外的量表。」 The Konpaku flames get a row of their own; the gauges other
   than Reishi and the guard gauge get thicker.
3. 「卍解跟毀魂技拍攝自身角色特寫時，可以不用全身入鏡。」 Bankai / Kikon close-ups of a fighter need not show the whole body.
4. (follow-up to 2, the same day) 「魂魄火焰好像可以加大然後填滿在名字的後面耶？」 The flames larger, filling the name row
   after the name. This replaces 2's separate flame row.

### 15.1 The gestures (replaces the TAP, FLICK ↑ = F and HOHO rows of §3.2)

The pad splits at `touch-split-y` = its top + `tap-split` (0.5) × its height: at 390 × 844 the pad is y 384–794 and the
line is **y 589**. The **lower block is J** (light: the most used, where a resting right thumb already is), the **upper
block is K** (heavy). Where the thumb went down decides; a tap exactly on the line is J. A touch-down inside a chip's hit
circle is still the chip (the O chip and AWK sit in the upper block, L / I in the upper, SP1 / SP2 in the lower). The deck
draws the line faintly across the pad and names the blocks F (above) / Q (below) at the pad's far edge. The left hand
mirrors x only; the split is the same.

| Gesture | vpad | Meaning |
|---|---|---|
| Tap, lower block | `:quick` pulse | J (Quick) |
| Tap, upper block | `:flash` pulse | K (Flash); strings are zone taps: JJJ JJK JKK KKK KKJ KJJ, each tap latched during the link before |
| Rest (still `tap-ms`) | `:guard` held | U, guard |
| Drag | stick | walk; past the run ring `:step` held = the run |
| **Flick up** (within `up-cone`, 60° of vertical) | `:step` pulse + stick straight ahead, at the crossing | **the forward dash**: a forward Step (2.5 m hop, i-frames); a thumb that keeps going past the run ring keeps Step held, so the hop becomes the run, exactly like the other flicks |
| Flick down / sideways | `:step` + the stroke's direction | Step back / sidestep |
| Flick down in `:stun` / `:air` | `:mod` + `:quick` | Burst Reverse |
| Rest, then flick up (neutral / guard only) | `:mod` + `:step` | Hoho (unchanged: the rest first keeps it distinct from the dash) |
| O chip: tap / hold | `:kikon` | the O ender after a link-3 hit / the Kikon rush, held = the Kikon (unchanged) |
| L, I, SP1, SP2, AWK (hold 300 ms), II | unchanged | |

What went: the up-pending phase (4), `up-lift-ms`, the `+tp-up+` pulse (now `+tp-tap-hi+`, the upper tap). What stayed:
the undecided window (a stroke that left the slop reads a 0 stick until it is a flick or the 120 ms window closes: the
dash never walks first, a slow drag still walks), and `up-cone`, which now straightens a slanted right-thumb up-flick to
dead ahead (a flick past it keeps its direction: a sidestep). All times are SDL event timestamps. Latency: K is now a tap
(on the lift, 60–120 ms after touch-down) instead of a crossing plus a lift; the dash fires at the crossing (≈ 47 ms).
One hand no longer lacks a forward Step (§3.5).

### 15.2 The portrait HUD blocks (replaces the last row of §14's HUD)

Each block stays **29 s** tall (48 CSS px at 390 × 844; request 2's separate flame row made it 35 s / 58 px for a few
hours, request 4 took it back). From its top:
- **row 1: the name, then the nine Konpaku flames filling the rest of the row** (up to P2's timer): r = min(4 s, the free
  width / 21.6), spaced evenly (at most 4.5 r apart), their base at the name's baseline + 1.5 s (was r 2.4 s, 3.2 r apart,
  on the last row). `%hud-pips` takes the spacing as an argument; the landscape panel passes its 3.2 (unchanged floats);
- Reishi (5 s), the guard gauge (2 s);
- **the last row: the four small gauges, 4 s thick** (were 2.5 s) over the left 60 % (since the playtest decision at the
  end of this file: the whole width, the label and KOSEI moved to row 1) (Reiatsu cells, flash step,
  Awakening, the kit meter or the L cooldown), and at its right end **the label** (EVOLUTION / INFERNO / NOME /
  COOLDOWN / U's tag, moved off row 1) with **the KOSEI tag** (攻 ×n) right before it; its mote flies to the Reiatsu cells.
  With both the longest label and KOSEI on a 360-wide screen the tag's brush mark may touch the fourth gauge.

The camera frame follows the blocks (`*band*` from DECK-UPDATE), no camera knob changed. Landscape is unchanged.

### 15.3 Close-up cinematics

A `shot-on` at most `*pt-close-shot*` 5 m from its fighter is a close-up (`*cine-close*`; `shot-pair` and farther shots
are not). In portrait a close-up keeps the script's lens and eye: no 66° floor and no dolly-back, so the fighter fills the
frame's height as in landscape and his body may be cropped at the sides; its side offset is quartered (halved for the
rest) so the face stays in while the caption keeps its column. Two-shots and wide shots keep §14's anti-crop dolly.
Landscape is unchanged (the offset rule and `*cine-close*` act only in portrait).

### 15.4 Tests

`tests/touch-test.lisp` 60 checks: the zones and their boundary (on the line = J, just above = K, the pad's edges, a tap
wandering across the line inside the slop keeps its touch-down zone, the `tap-split` knob), the six string routes by
taps, the up-flick = a Step straight ahead at the crossing with no attack and nothing on the lift, a long up-stroke (no
stick while undecided, then Step held past the run ring), the slanted up-flick straightened, a side flick past the cone,
Hoho only after a rest, the dash from a fresh up-flick even when Hoho is allowed, a slow drag still walks, a chip's hit
circle still wins. `duel-touch.py`: J J K + the O ender, K K J, the dash twice, Hoho, guard, Steps, the run, the Kikon;
two `--fixed-dt` runs give identical hash and combat lines. `mobile-probe.py` (35 s blocks: ALL PASS at the four sizes and
with iPhone insets; the final 29 s blocks: ALL PASS at 360 × 780 and 390 × 844, 83 / 83 each,
every set shot inside; the landscape battle HUD stills byte-identical). Desktop: G1 RAVEN identical, G2 CvC = the
reference, smoke, the frozen duel still identical, six landscape cinematic stills byte-identical to the previous build.
Stills: `mobile-battle.png` (the split line), `mobile-gestures.png`, the `mobile-cine-*` close-ups, `mobile-review*.png`
(before = the P2 commit). Known: the Bankai card's caption still sits over the silhouette (as in §14; now larger).

### 15.5 Rukia's temperature on the thumb (2026-09-28, DUEL_RUKIA.md §8)

Her awakening cools with guarding, and on a phone a resting thumb is a guard. So while P1's kit meter is `:temp`, the
floating stick's ink ring gains a **white frost arc** just outside it (r 52 d, 3 d thick). **Since the cold-gauge rework
(2026-09-28, DUEL_RUKIA.md §4 / §8) the arc is the cold C / 200**, clockwise from the top: the two stacked bars go round
the ring, and a white tick at the bottom marks the half (bar 1 full: −50). At absolute zero a white ring joins it and the
arc pulses; a resting thumb there braces (the warming stops, the guard gauge drains). In the THAW lock after a CRACK the
arc is grey. A flick or a rest-flick at zero is eaten (rooted). The portrait block shows the same cold gauge in the
kit-meter slot of its last row (`%hud-temp` small: the two bars overlaid, the band pips, L's cost mark), the label the
band (−18C / −50C / −273C, THAW in the lock). Landscape and every other character: unchanged. The portrait COOLDOWN cell
of the other awakened forms is one L bar (the Shift+L line went with South's cooldown, 2026-09-28).

## 16. One-hand as a setting; SETTINGS and PRACTICE (2026-09-28)

**Request (verbatim):** 「請幫我添加『練習模式』與『設定』（調整手持模式與其開關等等）後將『one hand vs cpu』與『vs cpu』整合」:
add a practice mode and settings (the handheld mode and its switch, etc.), then merge ONE-HAND VS CPU into VS CPU. The
choices below were made for the user as defaults; each is a value the user can revise.

**MODE** is now VS CPU / PRACTICE / VS PLAYER / CPU VS CPU / SETTINGS / CONTROLS, the same on every device; the cursor
starts on VS CPU (row 0), so a touch phone held upright still lands on it. (2026-09-29: ENDLESS joined as row 1,
[DUEL_ENDLESS.md](DUEL_ENDLESS.md); it is one-handed like VS CPU and PRACTICE, and the rows below it moved down one.
Its portrait battle HUD adds `STAGE n` at 1.2 s, left-aligned under P2's block, clear of the pause chip on the right;
STAGE CLEAR and its RESULTS use the portrait results card, their rows at 0.8 h.) The ONE-HAND VS CPU and HAND rows are gone.

**One-hand is decided by the setting ONE-HAND MODE** (`control.lisp` `one-hand-on-p`, `onehand.lisp`
`one-hand-effective-p`), read when VS CPU or PRACTICE is chosen:

| ONE-HAND | touch-first + portrait | touch-first, landscape | portrait window, not touch-first | landscape desktop |
|---|---|---|---|---|
| **AUTO** (default) | one-handed | — | — | — |
| ON | one-handed | one-handed (paused until turned upright: ROTATE TO PORTRAIT) | one-handed | — (never offered) |
| OFF | — | — | — | — |

AUTO is exactly the old preselection (§6: ONE-HAND VS CPU was preselected on a coarse portrait device). Everything the
old entry did happens through VS CPU when it is in effect: `*one-hand*` T (the deck, its chips and gesture prompts), the
behind camera for steering (`set-cam-behind` now takes `*one-hand*` into account instead of overwriting the CAMERA
setting), the portrait camera and HUD (they follow the window, as before), no CAMERA row in the pause menu, the pause chip
and the back gesture. The CONTROLS screen still shows the gesture card wherever one-hand is offered.

**SETTINGS** (`*settings*`, data; drawn by `hud-settings` in both orientations, rows are tap targets): ONE-HAND
(AUTO / ON / OFF), HAND (RIGHT / LEFT), TAP SPLIT (40 / 45 / **50** / 55 / 60 %: the recogniser's `tap-split`), SENSITIVITY
(1–5 = `flick-min` 40 / 34 / **28** / 23 / 18 CSS px), CAMERA (BEHIND / SIDE), BACK. Confirm, left / right or a tap changes a
row; each change is in force at once (`apply-settings`: `*hand*`, the `gesture-config`, the camera) and saved. The note
line under the rows explains the selected row; for ONE-HAND it says whether it is in effect here. No sound row: the
engine exposes only the music bus gain.

**Storage** (`duel/web/pwa.js`): page get / set 10 + i = row i (option index + 1; 0 = never saved) in localStorage
`soulduel.onehand`, `soulduel.hand` (the key HAND used before, same values), `soulduel.split`, `soulduel.flick`,
`soulduel.camera`. Every access is in try/catch; a missing, private or blocked storage gives 0 and the defaults. The page
services 2 (get HAND) and 1 (set HAND) are replaced by these.

**PRACTICE** is one-handed by the same rule; its pause menu (RESUME / RESET POSITION / DUMMY / HP REFILL / GAUGES /
P1 HP / P1 KONPAKU / DUMMY HP / DUMMY KONPAKU / CHARACTER SELECT / TITLE: 11 rows one-handed) opens from the II chip or
the back gesture like VS CPU's, and its option rows change on a tap. The rows are packed between 0.4 and 0.9 of the
height, over P1's block (`hud-menu`'s BOTTOM). The rules are in DUEL_GAMEPLAY.md ("PRACTICE").

**Konpaku at stake** (the same day): on both portrait blocks' name rows, as in landscape, the last N flames are BLOOD
red, N = what the opponent's Kikon would take now (DUEL_DESIGN.md §10 HUD).

**Tests.** `duel-control-test` 65 checks (the table above, the page value's decoding, the defaults = the old behaviour,
the practice dummy's guard). `duel-touch.py`: the match is reached by the VS CPU row (the same tap as before: row 0), so
`duel-touch.json`'s taps and its hash / combat lines are unchanged; `duel-touch-left.json` sets HAND LEFT through
SETTINGS. `duel-mobile.py` needed no change (VS CPU and CONTROLS keep rows 0 and 5).

## Playtest decision: full-width small gauges (the user, 2026-09-28)

In the portrait split HUD, the row of side-by-side small gauges (SP / flash step / awakening and each character's own
meters) is stretched to the **same length as the HP bar**.

**Built (2026-09-28).** `hud-side-portrait` (hud.lisp): the last row's four small gauges (Reiatsu cells, flash step,
Awakening, the kit meter: Inferno / NOME / UDE / Rukia's cold gauge / the L cooldown) now split the **whole block width**
`bw`, the same as the Reishi bar and the guard gauge, for both blocks (P2 top, P1 bottom). The row had kept its right 40 %
for the label and the KOSEI tag; those moved to **row 1**: the name, then the label (EVOLUTION / INFERNO / NOME / UDE /
COOLDOWN / THAW / U's tag; not drawn when it only repeats the awakened form's name, e.g. Rukia's `-18C`, already in
"RUKIA  -18C"), then the nine Konpaku flames in the width left, then the KOSEI tag (攻 ×n, `kosei-tag-w`) at the row's
right end (P2: left of the timer); its mote still flies to the Reiatsu cells. The flames already size themselves to the
free width (r = min(4 s, fw / 21.6), so they never overlap); a crowded row keeps them at r ≥ 3 s by first shortening the
name (the awakened form's name / the character's), then dropping the label. The block stays 29 s, so the camera band,
the pad (it ends 50 CSS px over the bottom, above P1's block) and the chips (all above P1's block, the pause chip under
P2's) are unchanged and nothing new is drawn outside the blocks. Landscape (`hud-side`) is unchanged. Review: debug
2430+k (`hud-review`: both sides in given forms, gauges part-full, KOSEI shown) at 390 × 844 for Yamamoto (Shikai,
Hellfire, East, West), Kenpachi (base, the three cups, the Bankai, KATAUDE) and Rukia (Shikai, −18, −50, zero), P1 and
P2.

## 17. Ichigo's KESSA on the thumb (2026-09-28, DUEL_ICHIGO.md §8)

KESSA has no hold-guard: its U is the chain parry (20 of the chain gauge a press). A resting thumb is U on this deck, so
it would fire a parry on every rest. In a form whose U is a move (the kit's `:u` hook) **a resting thumb does nothing**
(rest → up-flick is still the Hoho), and **the spent AWAKEN chip becomes U** (labelled U, drawn always, a tap: the deck is
laid out again with no 300 ms hold on it; `u-chip-p`, `*u-chip-holds*`, onehand.lisp). The thumb ring gains the chain
gauge as a BLOOD arc (gauge / 100, dim below 20) with a white tick at U's 20 (the kit's `:deck` hook, ichigo.lisp). The
portrait block needs nothing new: the chain gauge is the guard row, which already spans the Reishi bar, and it carries
the CHAIN label and notches (`:hud-guard`). Every other character and landscape: unchanged.
