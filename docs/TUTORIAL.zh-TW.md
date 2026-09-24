# 學習路徑：從 HELLO 讀到 RAVEN EDGE

這份教材的對象是會一點程式、也許碰過一點 Lisp、想知道「網頁上的 3D 遊戲引擎和遊戲是怎麼做出來的」的人。它不從零教 Common Lisp，而是帶你照順序讀這個專案的真實程式碼。每一步都標了檔案和行號，建議把檔案開在旁邊對著看。

路線是這樣：先把最小的範例 `examples/hello` 建起來、跑起來、從頭讀到尾（第 0～2 步），再往下看引擎的四根柱子：幀迴圈與 GC、ECS、純函式規則、事件（第 3～6 步），接著是算圖（第 7 步），最後用同樣的眼光讀完整的遊戲 RAVEN EDGE（第 8 步）。第 9 步是練習題。

![HELLO：一個會發光的方塊和幾顆旋轉的寶石](../tests/shots/hello.png)

---

## 第 0 步：準備、建置、執行

### 需要什麼

| 東西 | 用途 | 這台機器上的位置 |
|---|---|---|
| 32 位元的 host ECL 24.5.10 | 把 Lisp 編成 C | `/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host`（環境變數 `ECL_HOST` 可覆寫） |
| emsdk 4.0.12 | 把 C 編成 wasm | `/media/8tsp/projects/emsdk`（`EMSDK_DIR` 可覆寫） |
| `vendor/` | wasm 版 ECL、SDL3（WebGPU 後端）、Dawn 的 WebGPU C API | 已經在專案裡，不用自己建 |
| Node.js ≥ 22 | 無頭測試器 `tools/run.mjs` | |
| Google Chrome | 看遊戲、無頭測試 | 系統的 `google-chrome` |

換一台機器要從頭準備工具鏈的話，步驟寫在根目錄 [README.md](../README.md) 的「建置需求」。

### 建置和執行 hello

```sh
./build.sh examples/hello                    # 產生 dist/hello/{index.html,index.js,index.wasm}
python3 -m http.server -d dist/hello 8000    # 任何靜態伺服器都行
```

用 Chrome 開 `http://localhost:8000/`。直接雙擊 `index.html`（`file://`）不行，瀏覽器不允許這樣載入 wasm。

畫面需要 WebGPU。Windows、macOS、ChromeOS 上的 Chrome／Edge 113 以上預設就有。Linux 要看顯示卡和驅動；如果頁面顯示 `WEBGPU UNAVAILABLE`，可以這樣啟動 Chrome 再試：

```sh
google-chrome --enable-unsafe-webgpu --enable-features=Vulkan
```

聲音要等你在頁面上點一下或按一個鍵才會出來，這是瀏覽器的自動播放限制。

### 不開瀏覽器也能跑：無頭測試器

```sh
node tools/run.mjs dist/hello --secs 10 --shot out.png
```

`tools/run.mjs` 不需要安裝任何套件。它起一個小 HTTP 伺服器，開無頭 Chrome（WebGPU 走 SwiftShader 軟體算圖），把頁面的 console 印到終端機，最後拍一張截圖。加 `--script steps.json` 可以在指定秒數按鍵，格式寫在檔頭。頁面丟出 JS 例外時結束碼是 1。上面那張截圖就是這樣拍的。

### 在主機上一秒跑完的測試

有三個檔案是純 Common Lisp，不用建置、不用瀏覽器，直接用 host ECL 就能測：

```sh
E=/media/8tsp/projects/ecl-24.5.10/ecl-emscripten-host/bin/ecl
$E --norc --load tests/ecs-test.lisp          # ecs-test: ALL PASS
$E --norc --load tests/rules-test.lisp        # rules-test: ALL PASS
$E --norc --load engine/lisp/package.lisp --load engine/lisp/math.lisp --load tests/test-math.lisp   # test-math: OK
```

這件事為什麼做得到，第 5 步會講。

---

## 第 1 步：專案地圖

```
engine/     可重複使用的引擎（ENGINE 套件）。不知道任何一款遊戲的存在。
  lisp/       Lisp 部分：數學、平台、算圖、模型產生、UI、音訊、動畫、時間、特效、ECS、app
  c/          C 部分：engine.h（Lisp 會呼叫的所有 C 函式）、main.c、render.c……
  shaders/    所有 WGSL 著色器
  web/        HTML 外殼 shell.html
game/       RAVEN EDGE（RAVEN 套件），用引擎做出來的完整遊戲
examples/   只用引擎的小範例：hello（本教材）、engine-demo（算圖、模型產生、特效、UI 的展示）
tests/      主機上的測試、wasm 版的 demo、無頭測試腳本產生器、截圖
tools/      build.lisp（編譯腳本）、run.mjs（無頭測試器）、pkgcheck.sh、vendor 腳本
docs/       文件（索引在 docs/README.md）
```

引擎和遊戲的界線是套件：引擎的公開 API 就是 `engine/lisp/package.lisp` 第 7～71 行的 export 清單，遊戲用 `(defpackage :raven (:use :cl :engine))` 看到這些名字。引擎的程式碼裡沒有任何一行提到 RAVEN。

### MANIFEST：一個建置目標的原始檔清單

每個建置目標是一個目錄，裡面有一個 `MANIFEST`。hello 的長這樣（`examples/hello/MANIFEST`）：

```
# title: HELLO
# The smallest complete game on the engine: ./build.sh examples/hello
# Walkthrough: docs/TUTORIAL.zh-TW.md, step 2.
hello.lisp
```

每一行是一個相對於該目錄的原始檔，`#` 開頭是註解，`# title:` 會變成網頁標題。`.lisp` 檔依序串起來編譯，`.c` 檔在連結時交給 emcc。引擎自己也有一份 `engine/MANIFEST`，`build.sh` 永遠把它排在最前面。遊戲的 `game/MANIFEST` 有 22 個 Lisp 檔和一個 C 檔，順序有意義：巨集、結構、元件要先定義才能用。

### build.sh：Lisp → C → wasm

```
engine/MANIFEST + examples/hello/MANIFEST
        │  .lisp 依序串成一個檔案
        ▼
build/hello/game-all.lisp
        │  32 位元 host ECL：compile-file，C 編譯器換成 emcc（tools/build.lisp）
        ▼
build/hello/libgame.a              ← Lisp 變成的 wasm 物件檔，初始化函式 init_game
        │  emcc：加上 .c 檔、vendor/ecl 的 libecl/GC/GMP、vendor/sdl3-webgpu 的 SDL3、Dawn 的 WebGPU port
        ▼
dist/hello/index.html  index.js  index.wasm
```

`build.sh` 只有 48 行，可以直接讀。讀的時候留意這幾件事：

- **ECL 把 Lisp 編成 C。** 這是 ECL 的特色：Lisp 函式會變成真的 C 函式，所以再交給 Emscripten 就能變成 wasm。host 版 ECL 必須是 32 位元，因為 wasm32 的指標和 fixnum 也是 32 位元，ECL 會把這類常數寫死進產生的 C。
- **為什麼整個專案只有一個編譯單元。** 一般的 ECL 專案會一個檔案一個檔案編譯，編 B 之前先把 A 載入，讓 A 的巨集在編 B 時看得到。這裡做不到：很多檔案用了 `ffi:c-inline`（直接嵌一段 C），host 上的 ECL 沒辦法執行它們，而編好的東西又是 wasm，host 也載不進去。所以 `tools/build.lisp` 第 26～37 行把所有檔案接成一個 `game-all.lisp`，一次編完。代價是改一行就全部重編（hello 約 6 秒，遊戲約 13 秒），而且編譯錯誤的行號要對照 `build/NAME/game-all.lisp`，每個原始檔開頭都有 `;;;; ---- engine/lisp/xxx.lisp` 這樣的標記方便找。
- **ECL 不會警告未定義的函式。** 遊戲如果用到引擎沒有 export 的函式名，會悄悄變成遊戲套件裡的另一個符號，編譯照樣成功，執行時才出錯。所以有 `tools/pkgcheck.sh`：

  ```sh
  tools/pkgcheck.sh examples/hello
  ```

  輸出 `0 symbols that look like unexported ENGINE names` 就是沒問題；如果列出 `HELLO::某名稱`，代表你用了引擎沒有 export 的東西（去 `engine/lisp/package.lisp` 找找正確的名字），或是剛好和引擎內部名稱撞名（換個名字）。

---

## 第 2 步：從頭讀 examples/hello

`examples/hello/hello.lisp` 共 123 行，照順序讀。你控制一個發光的方塊，碰到寶石就得分，寶石會換個地方重生。

**第 6～7 行：自己的套件。** `(defpackage :hello (:use :cl :engine))`。引擎 export 的東西（`draw-mesh`、`defcomponent`……）可以直接用。

**第 11～14 行：一個音效。** `defsound` 定義「怎麼合成」這個聲音，本體回傳一段取樣資料。這個專案沒有任何音訊檔，所有聲音都是啟動時用程式合成的。`au-ping!` 在第 0 秒放一個 1320 Hz、快速衰減的音，60 毫秒後再疊一個高五度的音，聽起來就是「叮」。

**第 16～26 行：模型。** `build-mesh` 給你一個建構器 `mb`，在裡面呼叫 `mb-plane`、`mb-bevel-box`、`mb-cone` 這些基本形狀，最後上傳到 GPU。`with-xform` 在一段範圍內套用位移或旋轉：寶石是兩個錐體，一個朝上、一個用 `:roll pi` 翻過來朝下。`:jitter` 讓每個面的亮度隨機差一點，這是整個專案低面數畫風的來源。建模型會配置很多暫時的記憶體，所以只在啟動時做一次（第 3 步會說明為什麼啟動時可以、每幀不行）。

**第 28～34 行：三種元件。** 這是 ECS 的「C」。

```lisp
(defcomponent pos "Where it stands on the floor (metres)."
  (x 0.0 :type single-float) (z 0.0 :type single-float))
(defcomponent player "Moved by the keyboard." (speed 5.0 :type single-float))
(defcomponent gem "Collectable; spins." (angle 0.0 :type single-float) (value 10 :type fixnum))
```

`defcomponent` 和 `defstruct` 很像：它給你 `make-pos`、`pos-x` 這些函式，另外還有一個 `(pos e)`，傳回實體 `e` 身上的 `pos` 元件，沒有的話傳回 `nil`。

**第 36～42 行：生出實體。** 實體（entity）只是一個整數編號，本身沒有資料。它「是什麼」取決於掛了哪些元件：玩家是 `pos + player`，寶石是 `pos + gem`。`start` 在載入完成後執行一次，生出一個玩家和 8 顆寶石。`rnd-range` 是引擎的亂數（C 寫的 xorshift，不配置記憶體）。

**第 45～47 行：一條純規則。**

```lisp
(defun touching-p (ax az bx bz reach)
  (<= (+ (expt (- ax bx) 2) (expt (- az bz) 2)) (* reach reach)))
```

參數進、答案出，不讀全域變數、不改任何東西。這種函式最好測、最好理解。RAVEN EDGE 的戰鬥規則全都寫成這種形式（第 5 步）。

**第 51～73 行：系統。** 系統就是普通的函式，用 `do-entities` 拜訪「同時擁有某些元件」的每個實體：

```lisp
(do-entities (e pos player)          ; 每個有 pos 也有 player 的實體
  (setf (pos-x pos) ...))            ; pos、player 已經綁好該實體的元件
```

- `move-system`（55～61 行）：讀鍵盤（`key-down`、`key-pressed`），移動所有 `player`。按空白鍵播放低八度的「叮」。
- `spin-system`（63～65 行）：讓所有寶石轉。
- `pickup-system`（67～73 行）：兩層 `do-entities`，玩家對每顆寶石問規則 `touching-p`。碰到了就 `emit` 一個事件 `(:picked x z value)`，然後 `destroy-entity` 移除寶石。注意它**不**加分、**不**放音效。`(me pos)` 這種寫法是把元件綁到自己取的變數名，因為兩層都有 `pos`。

**第 76～87 行：處理事件。** `feedback-system` 用 `take-events` 取出這一幀累積的所有事件，一個一個處理：加分、放音效、在地上放一個擴散的圓環（`fx-ring`），再生一顆新寶石。「規則判斷、事件回報、另一個系統負責表現」這個分工是第 6 步的主題。

**第 90～103 行：畫圖。**

- 先設鏡頭（`camera-look-at`，跟著玩家），因為之後的特效要用鏡頭方向算。
- `draw-mesh` 把一個模型和一個 4×4 矩陣排進繪製佇列。矩陣用 `m4-euler!` 從位置和角度算出來，寫進同一個暫存矩陣 `*m*`；`draw-mesh` 會複製它，所以一個就夠。結尾是 `!` 的函式會把結果寫進第一個參數，不配置新記憶體。
- `add-point-light` 在玩家頭上放一盞青色點光源，`fx-decal` 在腳下畫一塊淡淡的影子。
- 寶石用 `:emissive 1.2` 自己發光，畫面後製的 bloom 會讓它暈開。

**第 105～108 行：UI。** `ui-text` 用引擎內建的 5×7 點陣字畫文字，`ui-scale` 依視窗高度給一個整數倍率。

**第 111～123 行：一幀，以及註冊遊戲。**

```lisp
(defun frame (dt)
  (move-system dt)
  (spin-system dt)
  (pickup-system)
  (feedback-system)
  (draw-system dt)
  (hud))

(run-game :title "HELLO"
          :load (list #'build-meshes)
          :start #'start
          :frame #'frame)
```

系統的呼叫順序就是設計：先移動，再判斷撿到，再表現，最後畫。`run-game` 告訴引擎三件事：啟動時要跑哪些載入步驟、載入完成後做什麼、每幀呼叫什麼。`dt` 是這一幀經過的真實秒數（最多 0.1）。

試著追一次「按住 D」：`move-system` 把玩家的 `pos-x` 加大 → `pickup-system` 發現碰到寶石，發出 `:picked` → `feedback-system` 加 10 分、叮一聲、放圓環 → `draw-system` 在新位置畫方塊，鏡頭跟過去 → `hud` 顯示 `SCORE 10`。

---

## 第 3 步：幀迴圈，以及為什麼 GC 只在幀與幀之間跑

`run-game` 只是把函式存起來（`engine/lisp/app.lisp` 第 23～25 行）。實際驅動迴圈的是 C 的 `engine/c/main.c`：

- `main`（第 74～86 行）：`cl_boot` 啟動 ECL，**立刻 `GC_disable()`**，載入編譯好的 Lisp（`ecl_init_module`），回收一次，然後把 `frame` 交給瀏覽器的 `emscripten_set_main_loop`，之後瀏覽器每畫一幀就呼叫它一次。
- `frame`（第 46～72 行）：啟動階段每幀呼叫一次 `ENGINE::%INIT-STEP`，每一步之後完整回收一次；啟動完成後每幀呼叫 `ENGINE::%FRAME`，回來之後如果這段時間配置超過 24 MB（第 17 行的 `GC_BUDGET`）就回收。

Lisp 這一側在 `app.lisp`：

- `run-init-step`（第 49～63 行）：啟動步驟依序是 `engine-init`（視窗、GPU、UI）→ 你的每個 `:load` 函式 → 開音訊裝置 → 每個 `defsound` 一步 → 你的 `:start`。一步一幀，所以頁面的載入條會動，瀏覽器也不會以為頁面當掉。
- `run-frame`（第 94～111 行）：`platform-poll`（讀輸入）→ `begin-frame`（清空佇列）→ 除錯指令 → 你的 `:frame` → `end-frame`（真的畫出來）。
- `%frame`（第 113～116 行）：一個 `handler-case` 包住整幀。沒處理的錯誤最後都在這裡被接住，顯示在頁面上，主迴圈停止（`%init-step` 對啟動步驟做一樣的事）。

```
瀏覽器的一幀                       瀏覽器的一幀
│ %FRAME ─ 你的 :frame ─ END-FRAME │ (GC) │ %FRAME ─ …
│ ← GC 關閉，Lisp 在執行 →         │ 堆疊上沒有 Lisp 物件：可以安全回收
```

### 為什麼要這樣

ECL 用的 Boehm GC 是「保守式」的：它掃描堆疊和暫存器，看到像指標的值就當成指標，藉此知道哪些物件還活著。在 wasm 上這個假設不成立：wasm 函式的區域變數不在記憶體裡，GC 看不到。如果 GC 在某個 Lisp 函式執行到一半時觸發，那個函式手上只存在區域變數裡的物件就可能被當成垃圾收走。

標準解法是用 Emscripten 的 ASYNCIFY 重建一切，但它會讓程式變大變慢，而且 ECL 的例外處理（setjmp/longjmp）和它合不來。這個專案選了另一條路：只在「確定沒有任何 Lisp 程式正在執行」的時候回收，也就是兩幀之間，`%FRAME` 已經回傳、堆疊空了的那一刻。

這帶來三條規則（完整版在 [ARCHITECTURE.md](ARCHITECTURE.md) 的 "The GC rule"）：

1. Lisp 裡永遠不要呼叫 `(ext:gc)`。
2. C 的全域變數如果存了 Lisp 物件，要用 `ecl_register_root` 登記（`main.c` 第 82～83 行就是例子）。更好的做法是 C 根本不存 Lisp 物件。
3. 每幀配置的記憶體要少。一幀之內配置的東西在這幀結束前都不會被收，而且每 24 MB 就要付一次幾毫秒的完整回收。

第 3 條是引擎很多寫法的原因：預先配置的矩陣、`!` 結尾的函式、`defun-fast`。想看自己每幀配置多少，在 hello 的 `start` 裡加一行 `(setf *stats-log* t)`，console 每 2 秒會印一行 `stats: fps … cons/frame … B …`。

對照一下啟動完成時的堆大小：hello 是 23.2 MB，RAVEN EDGE 是 87.1 MB（console 的 `startup: heap … MB`）。

---

## 第 4 步：ECS（Entity-Component-System）

打開 `engine/lisp/ecs.lisp`，154 行，開頭 1～26 行的註解就是整個設計。

**為什麼不用類別繼承。** 遊戲物件之間的差別在「帶了哪些資料」，不在「是哪一種類別」。主角、小兵、飛出去的苦無都有位置，只有戰鬥者有血量，只有苦無是飛行道具。用繼承會很快卡在「苦無要不要繼承角色」這種問題上。ECS 把三件事拆開：

| | 是什麼 | 在程式裡 |
|---|---|---|
| Entity 實體 | 一個編號，沒有資料 | 一個 fixnum，`spawn-entity` 傳回 |
| Component 元件 | 一包資料 | `defcomponent` 定義的 struct，每個實體每種最多一個 |
| System 系統 | 一段邏輯 | 普通函式，用 `do-entities` 找到需要的實體 |

**儲存方式。** 每一種元件有一個長度 256 的向量，用實體的「槽位」當索引（第 36～40 行）。所以 `(pos e)` 就是兩次陣列讀取。`do-entities`（第 123～139 行）展開後是一個掃過所有使用中槽位的迴圈，只要有一種元件是 `nil` 就跳過。

**編號與世代（第 58～69 行）。** 實體被刪掉後，槽位會給新的實體重用。如果編號只是槽位，別人手上留著的舊編號就會指到新實體，這是很難抓的 bug。所以編號 = 槽位 + 256 × 世代：`destroy-entity`（第 107～116 行）把該槽位的世代加一，舊編號的世代對不上，`entity-alive-p` 傳回 `nil`，所有元件 getter 也傳回 `nil`。因此實體之間可以放心互相記編號，例如 RAVEN 的飛行道具記著丟它的人（`projectile-owner`），丟的人死掉也不會出事。

**`defcomponent` 做了什麼（第 72～84 行）。** 一個 `defstruct`，加上一個 inline 的 getter `(name e)`。每種元件在編譯時拿到一個固定的儲存索引，直接寫死在 getter 裡。

**限制。** 最多 256 個實體、64 種元件，世界是全域的（一個程式一個）。對一個場上十幾個角色的動作遊戲來說夠用。

**測試。** `tests/ecs-test.lisp` 在主機上檢查了生成、查詢順序、移除元件、世代、事件佇列。`ecs.lisp` 是純 Common Lisp，所以可以這樣測。

**RAVEN EDGE 的元件。** `game/lisp/components.lisp` 第 1～18 行列出每種實體由哪些元件組成：

```
REN            transform motion model health fighter blade-trail player
an enemy       transform motion model health fighter blade-trail brain
a dummy        the enemy set + dummy
a projectile   transform projectile
```

粒子、雨、碎片、刀光的頂點**不是**實體。它們有好幾千個，每個只有幾個 float，放在引擎的大 float 陣列裡（`engine/lisp/fx.lisp`、`game/c/world.c`），每個幾乎零成本。實體留給「遊戲物件」。

---

## 第 5 步：函數式核心、命令式外殼

打開 `game/lisp/rules.lisp`。檔頭 1～7 行說明了規矩：這個檔案裡的函式只看參數、只回傳結果，不碰元件、不讀特殊變數、沒有副作用，連亂數都是從參數傳進來的一個數字。這叫「函數式核心」。

最好的例子是 `enemy-hit-outcome`（第 98～144 行）：一下攻擊打到敵人會怎樣？輸入全部是關鍵字參數：是不是 Raven 型態、是不是頭目、在不在防禦、在不在紅色蓄力、剩多少韌性和血量……輸出是一個小結構 `enemy-hit`（第 86～96 行）：結果（`:hit`、`:blocked`、`:killed`、`:crippled`……）、扣多少血、停頓幾幀。它不知道實體是什麼，也不知道畫面長什麼樣子。

「命令式外殼」是呼叫它的地方：`game/lisp/combat.lisp` 的 `enemy-take-hit`（第 197～252 行）。它從元件收集輸入、呼叫規則、再把結果套回元件（扣血、改狀態、擊退），最後發事件。

### 為什麼這樣切

**因為規則可以一秒測完。** `rules.lisp` 是純 Common Lisp，`tests/rules-test.lisp` 直接在主機上載入它：

```lisp
(let ((r (grunt l1)))                                 ; poise 10 - 10 breaks: a flinch
  (check (and (eq (eh-result r) :hit) (eq (eh-react r) :flinch) (~= (eh-hp r) 50) ...)))
```

不用建置、不用開瀏覽器、不用在遊戲裡等敵人出招。改完一條規則，0.04 秒就知道有沒有打破別的東西。遊戲裡要驗證同一件事，得建置、開無頭 Chrome、下除錯指令、翻 log。

**因為規則集中在一個檔案，讀得懂。** 想知道「格擋視窗是幾幀」「紅色攻擊能不能擋」，看 `player-hit-outcome`（第 163～194 行）就好，不用在 800 行的玩家狀態機裡找。

### 那為什麼外殼還是直接改資料？

純函式式的做法是每一步都產生新的元件，不改舊的。這裡刻意沒有這樣做，原因在 ECL：

- **浮點數會裝箱。** ECL 裡的 `single-float` 只要存進「一般的地方」（串列、沒宣告型別的欄位、一般變數），就會被包成一個堆上的物件，約 16 位元組。一個角色每步要更新十幾個 float，每秒 60 步，十幾個角色，全部複製一份的話每秒會多出幾 MB 的垃圾。
- **垃圾就是卡頓。** 第 3 步說過，GC 只能在幀之間做完整回收，垃圾越多，回收越頻繁。

所以取捨是：**決定**用純函式（好測、好讀、只在事件發生時跑，例如命中時），**狀態**留在元件裡原地修改。規則回傳的小結構也會配置記憶體，但一秒只有幾次命中，可以接受。攻擊判定期間每一步都要跑的 `vol-hit-p`（第 48～83 行）則寫成只收 float、只回傳真假值，本體用 `(safety 0)` 編譯，裡面不配置記憶體（不過照 ECL 的規矩，呼叫時傳進去的 float 還是會各裝箱一次）。

這次重構在同樣的自動遊玩測試下，每秒配置量大約多了 10%（見 [DEVLOG](DEVLOG.zh-TW.md) 第 13 節）。

---

## 第 6 步：事件和 feedback 系統

事件佇列在 `ecs.lisp` 第 141～154 行，只有兩個函式：`(emit kind data…)` 把一個串列推進佇列，`(take-events)` 依發生順序全部取出並清空。

RAVEN EDGE 的戰鬥程式碼從不直接放音效或特效。`combat.lisp` 的 `emit-hit`（第 104～107 行）只記下「誰打到誰、在哪裡、是不是重擊、要停頓幾幀」：

```lisp
(emit :hit att tgt (aref p 0) (aref p 1) (aref p 2) (fwd-x yaw) (fwd-z yaw) heavy hitstop ender)
```

`game/lisp/feedback.lisp` 的檔頭（第 1～18 行）列出所有事件的格式，`feedback-system`（第 21～61 行）把它們變成血霧、火花、音效、鏡頭震動、命中停頓、慢動作，順便累計連擊數和擊殺數。

它在 `game/lisp/main.lisp` 被呼叫兩次：每個模擬步長的最後（第 22 行），以及每幀一次（第 67 行，處理遊戲流程和除錯指令發的事件）。

好處：

- **規則和表現分開。** 要調「打擊感」（停頓多久、震多大、聲音多響），只要改 `feedback.lisp`，不會動到判定。
- **同一件事只表現一次。** 命中不管是從近戰、飛行道具還是投技來的，都走同一個 `:hit` 分支（`show-hit`，第 63～70 行）。
- **時序不變。** hitstop 和慢動作在步長結尾設定，從下一步開始生效（`engine/lisp/time.lisp` 的 `time-step`），跟規則自己設定的效果一樣。

hello 的 `:picked` 事件是同一個模式的最小版。

---

## 第 7 步：算圖

### 模型

`build-mesh`（`engine/lisp/meshgen.lisp`）在 CPU 上產生三角形，每個頂點 9 個 float：位置、法線、顏色。`make-mesh`（`engine/lisp/render.lisp` 第 56～62 行）呼叫 C 的 `r_mesh_new`（`engine/c/render.c` 第 131～145 行），把資料上傳進 GPU 頂點緩衝（每塊 4 MB，滿了就開新的一塊；`R_CHUNK`）。模型建好就不再改，也不會釋放，所以只能在啟動時建。

### 繪製佇列

`draw-mesh`（`render.lisp` 第 228～257 行）不會馬上畫，只是在陣列 `*dq*` 後面寫一筆 28 個 float 的紀錄：矩陣、色調、自發光、閃白、鏡面強度、模型編號、邊緣光。這個格式和 WGSL 裡的 `struct Draw`（`engine/shaders/lit-io.wgsl` 第 4 行）一模一樣。

一幀結束時，`end-frame`（`render.lisp` 第 349 行起）用**一個** `ffi:c-inline` 呼叫把整個佇列、特效頂點、UI 頂點交給 C 的 `r_frame`（`render.c` 第 211 行起）。C 把佇列當成一個 storage buffer 上傳，每次繪製只帶一個索引，頂點著色器用 `draws[instance_index]` 讀自己的那筆資料。這樣比每次繪製都推一次 uniform 快：錄 258 次繪製，CPU 時間從 0.33 ms 降到 0.10 ms。

`r_frame` 的一幀：

```
copy pass    上傳 繪製紀錄 · 特效頂點 · UI 頂點
scene pass   4x MSAA：天空 → 不透明模型 → 半透明模型 → 特效（alpha）→ 特效（加法）
bloom        取亮部 → 模糊 ×4（1/2、1/4 解析度）
swapchain    合成（場景 + bloom + 暈影）→ UI
```

### WGSL 著色器與 `// #include`

所有著色器都是 `engine/shaders/` 下的檔案。`render.lisp` 第 12～39 行的 `wgsl` 巨集在**編譯時**讀檔：`// #include "frame.wgsl"` 這一行會被換成那個檔案的內容，註解和空行被拿掉，結果變成一個字串常數編進 wasm。所以改了著色器要重新建置。

幾個你一定會撞到的規矩（細節在 [ARCHITECTURE.md](ARCHITECTURE.md) 的 Gotchas）：

- WGSL 不能寫在 C 字串或 `ffi:c-inline` 裡，因為 ECL 會把 `@` 當成自己的語法，`@group` 會被改壞。這正是著色器獨立成檔案的原因。
- SDL 的 WebGPU 後端是掃描著色器原始碼來推算綁定的，所以變數名稱不要含有 `sampler`、`read`、`write`。

### C 這一側

Lisp 呼叫的每個 C 函式都宣告在 `engine/c/engine.h`，在 `engine/lisp/platform.lisp` 第 5 行用 `ffi:clines` 引入一次，整個編譯單元都看得到。呼叫方式是一行 `ffi:c-inline`，例如：

```lisp
(ffi:c-inline (data n) (t :int) :int "r_mesh_new(#0->vector.self.sf,#1)" :one-liner t)
```

`#0`、`#1` 是參數，`->vector.self.sf` 是 float 陣列在 C 裡的指標。`#` 後面只讀一個字元，而且是 36 進位：第 11 個以後的參數寫成 `#a`、`#b`……；寫 `#10` 會被當成 `#1` 後面接一個 `0`。C 端只在這一次呼叫期間使用這個指標，不會留著（第 3 步的 GC 規則）。

---

## 第 8 步：RAVEN EDGE 是怎麼組起來的

有了前面的概念，打開 `game/lisp/main.lisp`（95 行），整個遊戲的一幀都在這裡。

`game-frame`（第 57～74 行）：輸入 → 遊戲流程 → 模擬 → 鏡頭 → 畫場景 → HUD，和 hello 的 `frame` 是同一個形狀，只是多了一層：

**固定步長。** 動作遊戲的招式數據以 1/60 秒的「幀」為單位（「第 15 幀開始有判定」）。為了讓這句話在任何幀率下都成立，`accumulate-and-step`（第 25～31 行）把真實時間累積起來，每滿 1/60 秒跑一次 `sim-step`，每幀最多 6 次。

`sim-step`（第 11～23 行）就是系統清單，順序即設計：

```lisp
(player-system kp)          ; REN：輸入緩衝 → 狀態機 → 物理 → 姿勢
(enemy-system ke)           ; 每個敵人：AI → 招式 → 物理 → 姿勢
(projectile-system ke)      ; 苦無、爆裂苦無、刀氣
(separation-system)         ; 把重疊的身體推開
(token-system (* ke +step+)); 攻擊權杖計時
(feedback-system)           ; 這一步的事件 → 聲音、血、震動、停頓
```

`time-step` 在命中停頓期間傳回 `nil`，整步跳過（模擬凍結，但粒子、雨、鏡頭照常動）。`kp`、`ke` 是慢動作倍率，玩家和敵人可以不一樣（Just Dodge 時只有敵人變慢）。

### 一下攻擊的旅程

用小兵 RAINBLADE 的突刺打中 REN 當例子，從資料一路走到音效：

```
資料        moves.lisp 135-136   (defmove :rb-lunge (... :s 30 :a 15 :r 42 ...)
                                   (30 45 :dmg 18 :cap (0 1.6 1.1 0.5) :react :stagger ...))
             └ register-move / parse-hit（39、30 行）→ MOVE 與 HITDEF 結構（rules.lisp 13-39）
AI 出招     enemy.lisp 291       (enemy-attack e :rb-lunge ...) → start-move（combat.lisp 10）
每一步      enemy-system → enemy-tick → enemy-step（combat.lisp 338）
             └ move-tick（23）→ move-hit-scan（64）→ hitdef-scan（42）
判定（規則） vol-hit-p（rules.lisp 48）：膠囊碰到 REN 的受擊圓柱了嗎？
套用        resolve-hit（combat.lisp 72）→ player-take-hit（player.lisp 642）
結果（規則） player-hit-outcome（rules.lisp 163）：閃掉？格擋？彈反？受傷？
事件        (emit :player-hurt x y z fx fz heavy hitstop)
表現        feedback-system（feedback.lisp 21）：血霧、閃白、停頓、震動、紅色暈影、音效
```

反方向（REN 打中敵人）走的是 `enemy-take-hit` → `enemy-hit-outcome` → `emit-hit` → `:hit` → `show-hit`，結構完全對稱。

除了「判定」和「結果」兩格，其餘步驟都只是在搬資料。遊戲規則集中在 `rules.lisp`，數值集中在 `game/lisp/tuning.lisp`（跑速、彈反視窗、權杖數量）和 `moves.lisp`（每一招的幀數據），角色外觀和屬性在 `bodies.lisp`，動畫在 `clips.lisp`，音效在 `sounds.lisp`。這些「資料檔」大多是宣告式的巨集呼叫，改它們不需要懂系統怎麼運作。

各檔案的分工表在 [ARCHITECTURE.md](ARCHITECTURE.md)，玩法系統的細節和除錯指令在 [GAMEPLAY.md](GAMEPLAY.md)。

---

## 第 9 步：練習

每一題都附了提示。改完記得重新建置，並用 `tools/pkgcheck.sh` 檢查一下。

**1. 在 hello 加一個元件。** 讓寶石 10 秒沒被撿走就消失，換地方重生。

> 提示：`(defcomponent lifetime (left 10.0 :type single-float))`，在 `spawn-gem` 裡多掛一個 `(make-lifetime)`，寫一個 `lifetime-system`：`(do-entities (e lifetime) (decf (lifetime-left lifetime) dt) (when (<= … 0) …))`，時間到就 `destroy-entity` 並 `spawn-gem`。記得把它加進 `frame`，並想想要放在 `pickup-system` 之前還是之後。

**2. 改一個平衡數字。** 讓彈反更容易：把 `game/lisp/tuning.lisp` 的 `*parry-window*` 從 8 改成 12，或把 `*enemy-dmg-mult*` 改成 0.5。

> 提示：`./build.sh` 之後自己玩一下。想用數字確認的話，`python3 tests/scripts/e2.py` 產生腳本，再跑 `node tools/run.mjs dist/game --secs 30 --script tests/scripts/e2-grunt.json`，看 console 裡 `REN HURT … dmg` 的數字。

**3. 加一條規則和它的測試。** 在 `game/lisp/rules.lisp` 加一個純函式，例如 `(combo-rank hits)`：10 下以上傳回 `"GREAT"`，30 下以上 `"INSANE"`，否則 `nil`。在 `tests/rules-test.lisp` 加幾個 `check`。

> 提示：規則只能用標準 Common Lisp，不能用引擎的巨集（`rules-test` 把檔案載入一個空的套件）。測試用 `$E --norc --load tests/rules-test.lisp` 跑。想接進遊戲的話，HUD 的連擊數在 `game/lisp/hud.lisp`。

**4. 替 RAINBLADE 加一招。** 用 `defmove` 加一個大範圍橫掃 `:rb-sweep`。

> 提示：在 `game/lisp/moves.lisp` 的 RAINBLADE 區塊（第 129 行起）仿照 `:rb-slash` 寫，動畫先借用 `:clip :rb-slash`，判定用比較寬的 `:arc`（例如 `(2.4 160 0.3 2.0)`：半徑、角度、高度範圍）。然後改 `game/lisp/enemy.lisp` 的 `grunt-strike`（第 297～300 行），用 `rules.lisp` 的 `weighted-pick` 在三招之間選，例如 `(weighted-pick (rnd01) :rb-slash 50 :rb-double 30 :rb-sweep 20)`。用 `e2-grunt.json` 跑一次，在 console 找 `move RB-SWEEP`；測試時可以先把新招的權重調高，比較快看到。

**5. 改一個著色器。** 把最終畫面變成黑白。

> 提示：`engine/shaders/composite.frag.wgsl` 第 14 行，回傳前算亮度：`let g = dot(c, vec3f(0.299, 0.587, 0.114));`，改成 `return vec4f(vec3f(g), 1.0);`。著色器在編譯時讀入，所以要重新建置。這個檔案是引擎的，hello 和 RAVEN EDGE 都會變。

**6. 故意犯一個錯。** 在 hello 的 `start` 裡加一行 `(render-init 4)`。這是引擎內部的函式，沒有 export。看看 `./build.sh` 會不會報錯、執行時頁面顯示什麼，再跑 `tools/pkgcheck.sh examples/hello`，它會列出 `HELLO::RENDER-INIT`。

---

## 接下來讀什麼

- [ARCHITECTURE.md](ARCHITECTURE.md)：建置管線、執行模型、GC 規則、模組分工，以及一長串 ECL／WebGPU 踩過的坑。寫效能敏感的程式前一定要看 Gotchas。
- [ENGINE_API.md](ENGINE_API.md)：引擎每個公開函式的參考。
- [GAMEPLAY.md](GAMEPLAY.md)、[GAME_DESIGN.md](GAME_DESIGN.md)：RAVEN EDGE 的系統實作和設計規格。
- [DEVLOG.zh-TW.md](DEVLOG.zh-TW.md)：每個技術決定背後的理由。
- `examples/engine-demo/demo.lisp`：算圖、模型產生、特效和 UI 的更多用法。
