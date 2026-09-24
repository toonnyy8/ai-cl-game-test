# RAVEN EDGE 開發紀錄與技術思辨

這份筆記記錄做 RAVEN EDGE 時幾個比較關鍵的決定：遇到什麼問題、考慮過哪些做法、最後選了什麼、代價是什麼。英文技術文件（`ARCHITECTURE.md`、`ENGINE_API.md` 等）寫的是「現在長怎樣」，這裡寫的是「為什麼會長這樣」。

先說清楚一件事：文中所有 FPS 和毫秒數，除非特別註明，都是在無頭 Chrome 的 SwiftShader（CPU 軟體算圖）上量的。SwiftShader 比任何一張真的顯示卡慢很多，而且慢的地方也不一樣，所以這些數字只能拿來比較「改之前」和「改之後」，不能當成實際遊玩時的效能。團隊沒有在實體 GPU 上跑過，這點在最後的「已知限制」會再提。

---

## 1. 圖形 API：先走 GLES3，後來換成 SDL_GPU

題目本身限定了 SDL3。SDL3 有三條畫圖的路：SDL_GPU、SDL_Renderer，或者只拿 SDL3 開一個 OpenGL context、自己下 GL 指令。

SDL_GPU 是最現代的選擇，可惜 emsdk 4.0.12 內建的 SDL 是 3.2.4，這個版本的 SDL_GPU 沒有 web 後端，在瀏覽器裡根本建不起裝置。SDL_Renderer 可以用，但它是 2D API，沒有深度緩衝，要做 3D 動作遊戲就得自己排序所有三角形，不實際。

所以第一版的分工是：SDL3 負責視窗、GL context、輸入、計時和音訊，畫圖全部走 OpenGL ES 3.0（在 Emscripten 上就是 WebGL2）。整個遊戲先用這套做完。

之後使用者問「SDL_GPU 真的不能用嗎」。實測確認 SDL 3.2.4 的 `SDL_GetNumGPUDrivers()` 在瀏覽器裡回傳 0；SDL 3.4 也還沒有 WebGPU 後端，但有一個進行中的草稿 PR #16020。我們拿這個分支自己建 SDL，修掉幾個擋路的問題，把整個算圖層搬到 SDL_GPU，GL 程式碼全部刪除。來龍去脈寫在第 11 節。現在的代價是瀏覽器必須支援 WebGPU，而且依賴一個尚未合併的 SDL 分支。

## 2. 建置管線

### 2.1 Lisp → C → wasm

ECL 的特色是把 Lisp 編成 C。要跑在瀏覽器裡，C 這一段就交給 Emscripten。實際流程（`build.sh`、`tools/build.lisp`）：

1. 把 `engine/MANIFEST` 和 `game/MANIFEST`（當時是 `src/MANIFEST`）列的所有 `.lisp` 依序串成一個 `build/NAME/game-all.lisp`。
2. 用 **32 位元的 host ECL** 對這個檔案做 `compile-file :system-p t`，同時把 ECL 內部的 C 編譯器換成 `emcc`、`ar` 換成 `emar`。產出的 `.o` 已經是 wasm 物件檔。
3. `c:build-static-library` 包成 `libgame.a`，初始化函式叫 `init_game`。
4. `emcc` 把 `engine/c/main.c`（當時是 `src/main.c`）與其他 `.c` 檔、`libgame.a`、`vendor/ecl/` 下的 `libecl.a`、`libeclgc.a`、`libeclgmp.a`，以及 `vendor/sdl3-webgpu/lib/libSDL3.a` 連起來，WebGPU 的 C API 由 `vendor/emdawn/` 的 emdawnwebgpu port 提供，輸出 `dist/NAME/index.{html,js,wasm}`。

host 必須是 32 位元，因為 wasm32 的指標和 fixnum 都是 32 位元，ECL 在 host 上產生的 C 會把 fixnum 範圍之類的常數寫死進去，兩邊不一致就會出錯。ECL 原始碼裡 `INSTALL` 的「Cross-compile for the WASM platform」一節也是先建 `ABI=32` 的 host 版。

### 2.2 自己組一個靜態的 libecl.a

照 ECL 的說明做完交叉編譯，`build/` 目錄裡會有一個 `libecl.so`。我們一開始想直接連它，結果發現它其實是 Emscripten 的 SIDE_MODULE（檔頭有 `dylink.0` 區段），是給動態連結用的，而我們想要一個單純的靜態 wasm 執行檔。

解法是自己組：交叉建置的中間產物裡本來就有 `libeclmin.a`（C 寫的核心）、`liblsp.a`（編譯好的 Lisp 核心）和 `c/all_symbols2.o`（符號表）。`tools/vendor-ecl.sh` 把 `liblsp.a` 拆開，每個物件檔加上 `lsp_` 前綴免得撞名，全部塞進 `libeclmin.a` 的副本裡，得到 `vendor/ecl/libecl.a`（約 6.2 MB）。GC 和 GMP 則直接複製。

### 2.3 那個一定要加的 `-DECL_C_COMPATIBLE_VARIADIC_DISPATCH`

交叉建置的 `configure` 在 wasm 上自動加了 `-DECL_C_COMPATIBLE_VARIADIC_DISPATCH`（見 `build/config.log` 的 `CFLAGS`）。這個巨集會讓 `struct ecl_cfun` 和 `struct ecl_cclosure` 多一個 `entry_variadic` 欄位，並改成透過一個分派函式去呼叫可變參數的 Lisp 函式。原本是為了 ARM64 蘋果平台那種「固定參數和可變參數呼叫慣例不同」的架構設計的；wasm 的 `call_indirect` 會嚴格檢查函式簽章，所以也需要。

遊戲自己的程式碼如果沒加這個旗標，編出來的結構欄位位置就跟 libecl 對不上，執行時在 `call_indirect` 直接 trap，錯誤訊息完全看不出原因。現在 `build.sh` 的連結步驟和 `tools/build.lisp` 的 `c::*cc-flags*` 都有加，`build.lisp` 裡也留了註解。

### 2.4 為什麼全部串成一個編譯單元

正常的 ECL 專案會一個檔案一個檔案 `compile-file`，編 B 之前先 `load` A，讓 A 定義的 macro、struct、常數在編 B 時看得到。我們做不到這件事：大部分檔案都有 `ffi:clines` 或 `ffi:c-inline`，這些東西只在「編成 C」時才有意義，host 的直譯器沒辦法載入執行；就算先編好，編出來的也是 wasm 物件檔，host 載不進去。

最省事的做法是把所有原始碼接成一個檔案，一次編完。後果：

- MANIFEST（現在是 `engine/MANIFEST` 與 `game/MANIFEST`）的順序變得很重要，macro、struct、常數要先定義才能用。
- 編譯錯誤的行號是 `game-all.lisp` 的行號，所以每個檔案開頭都插了 `;;;; ---- engine/lisp/xxx.lisp` 這類標記。
- 所有 `ffi:clines` 會落在同一個 C 檔，C 的 static 變數要加模組前綴（`r_`、`au_`、`w_`……）以免撞名。
- 改一行就要全部重編。後面第 5 節會講到，這一度讓建置時間變得很難看。

`tools/build.lisp` 裡留了一句 `ponytail:` 註解，說明哪天編譯時間真的受不了，再拆成每個檔案各自的物件檔。

## 3. GC：整個專案最棘手的問題

### 3.1 問題

ECL 用 Boehm GC（bdwgc），它是保守式 GC：掃描堆疊、暫存器和資料段，看到像指標的值就當成指標。在 wasm 上，這個假設有兩個地方不成立。

第一，wasm 的區域變數不在線性記憶體裡，GC 掃不到。bdwgc 在 Emscripten 上靠 `emscripten_scan_registers()` 補這個洞，但 `src/bdwgc/os_dep.c` 裡這段只在定義了 `EMSCRIPTEN_ASYNCIFY` 時才會編進去，而且要連結時加 `-sASYNCIFY`。我們的 libecl 沒有用 ASYNCIFY 建置，所以 GC 在任意時間點觸發時，某個 Lisp 函式正抓在手上、只存在 wasm 區域變數裡的物件，可能被當成垃圾回收掉。

第二，資料段不會被掃描。`gcconfig.h` 在 Emscripten 下把 `DATASTART` 和 `DATAEND` 定義成同一個值，等於資料段長度是零。C 的全域變數如果指向 Lisp 物件，GC 看不到。幸好 wasm 版 ECL 的設定有 `ECL_DYNAMIC_VV`（見 `ecl-emscripten/ecl/config.h`），編譯好的模組常數向量（VV）會用 `ecl_alloc` 配置在 GC 堆上，由模組的 codeblock 物件持有（`src/c/read.d`），而 codeblock 又能從編譯出來的函式物件一路追到，不必靠掃描靜態資料段，所以 Lisp 程式碼裡的常數不受影響。

### 3.2 考慮過的做法

- **用 ASYNCIFY 重建。** 這是官方支援的路，但 ASYNCIFY 會改寫幾乎所有函式，讓它們能中途暫停再恢復，一般會讓 wasm 變大、執行變慢。而且 libecl、GC、我們的程式碼全部要重建。對一個需要穩定 60 Hz 的動作遊戲，這個代價不划算。
- **binaryen 的 `--spill-pointers`。** 這個 pass 會把可能是指標的區域變數溢出到線性記憶體的堆疊上，讓保守式 GC 看得到。同樣有效能代價，而且要對 libecl 和遊戲都做。
- **找一個「保證堆疊上沒有 Lisp 物件」的時間點才回收。**

前兩個我們沒有實際量過，是看了機制之後判斷代價太高。第三個在這個專案的執行模型下剛好成立。

### 3.3 決定：Lisp 執行時關閉 GC，只在幀與幀之間回收

瀏覽器的主迴圈是 `emscripten_set_main_loop`，每一幀呼叫一次 `NG::GAME-FRAME`（現在是 `ENGINE::%FRAME`），回傳之後 wasm 的呼叫堆疊就整個清空了。這時所有還活著的 Lisp 物件一定掛在某個根上：symbol、特殊變數、ECL 登記的根，不會只存在某個區域變數裡。

所以 `src/main.c`（現在是 `engine/c/main.c`）的做法是：

1. `cl_boot` 之後立刻 `GC_disable()`，然後才初始化遊戲模組。
2. 每一幀在 `ECL_CATCH_ALL` 裡呼叫 `GAME-FRAME`（現在是 `ENGINE::%FRAME`）。
3. 回傳之後，如果 `GC_get_bytes_since_gc()` 超過 24 MB，就 `GC_enable(); GC_gcollect(); GC_disable();`。

這套規則衍生出幾條紀律，寫在 `ARCHITECTURE.md` 的「The GC rule」：Lisp 裡永遠不准呼叫 `(ext:gc)`；C 的 static 變數如果存了 Lisp 物件，要用 `ecl_register_root` 登記（`main.c` 對 `frame_sym` 就是這樣做的）；每幀配置量要壓低。音訊回呼剛好也符合：它是在兩幀之間由瀏覽器事件觸發，而且完全不碰 Lisp 物件（第 7 節）。

### 3.4 驗證

最早的管線驗證程式 `tests/spike.lisp`（改用 SDL_GPU 後已刪除，它畫的是 GL 三角形）就是為了這件事寫的：每一幀配置大約 20000 個短串列當垃圾，另外保留一個每幀更新的陣列加字串，然後檢查內容有沒有被破壞，沒有的話不會印出 `CORRUPTION`。當初用它跑了 1440 幀確認可行。整理這份文件時我們又用現在的 `main.c` 在無頭 Chrome 重跑一次，跑到第 1680 幀：回收了 60 次，堆大小一直停在 32,501,760 位元組，沒有任何 `CORRUPTION`。

### 3.5 後果

- 一幀之內配置的東西在幀結束前都不會被回收。某一幀配置特別多，堆就會長大（`-sALLOW_MEMORY_GROWTH=1`，初始 128 MB）。早期 `world-init` 啟動時會一次配置約 50 MB，雖然第一次幀間 GC 就收掉，卻拉高了 wasm 堆的峰值；後來模型產生改成不逐三角形配置，啟動也拆成一步一幀、每步之後回收一次（`engine/lisp/app.lisp`）。
- 一次完整 GC 在約 32 MB 的堆上要幾毫秒，會造成一次小卡頓。遊戲中每幀大約配置 17～41 KB（見第 4 節），照 24 MB 的預算推算，大概每 600～1400 幀才回收一次。
- 這套做法依賴「主迴圈每幀回到瀏覽器」這個前提。哪天要用 pthread、或在 Lisp 裡等待非同步事件，就得重新想。

## 4. ECL 效能：浮點數裝箱是頭號敵人

ECL 生成的 C 大多很直接，但浮點數很容易被「裝箱」：包成堆上的物件，每個大約 16 位元組。對一個每幀要算幾千次向量的遊戲來說，這會變成大量垃圾，而且因為上一節的 GC 策略，垃圾越多，卡頓越頻繁。我們的做法是寫完熱點函式就去看 ECL 生成的 C，搜尋 `ecl_make_single_float`、`ecl_times`、`ecl_divide`。以下是一路踩到的坑（完整版在 `ARCHITECTURE.md` 的 Gotchas）：

- `single-float` 存進一般的地方（串列、沒宣告型別的 struct 欄位、`defvar`、一般陣列）就會裝箱，只有 `(simple-array single-float (*))` 和有宣告型別的區域變數不會。所以熱資料一律放在 f32 陣列裡。
- ECL 24.5 在 `(safety 1)` 下，連有宣告型別的 `let` 初始值都會用泛型的 `ecl_times` 算完再拆箱；陣列參數的型別檢查還會走很慢的 `cl_typep`。為此寫了 `defun-fast` 巨集（`package.lisp`）：進函式時做便宜的型別檢查，然後在 `(safety 0)` 下執行本體。型別錯了照樣會丟 `type-error`。
- 平行 `let` 如果遮蔽同名變數，會先把所有初始值算進裝箱的暫存變數，要改用 `let*`。
- 浮點數的 `min`、`max`、`abs` 在 ECL 24.5 是泛型呼叫，就算參數有宣告也一樣，`min`/`max` 還多了 NaN 檢查。熱迴圈裡改用 `ffi:c-inline` 呼叫 `fminf`、`fmaxf`、`fabsf`。
- `(incf (aref v i) x)` 會裝箱，除非 `x` 包在 `(the single-float ...)` 裡，要寫成 `(setf (aref v i) (+ (aref v i) x))`。
- 傳給非 inline 函式、或從它回傳的浮點數一定裝箱。熱路徑改成傳 f32 陣列（那些 `!` 結尾的函式），或宣告 inline。
- wasm32 上 fixnum 只有 30 位元（`CL_FIXNUM_MAX` 是 536870911），`(* seed 1103515245)` 這種線性同餘亂數會變成 bignum，每次呼叫都在配置記憶體。亂數改用 C 的 `long long` 算。

效果：`draw-mesh`、`m4-euler!`、`m4-mul!`、`fx-billboard` 每次呼叫配置 0 位元組；場景的 `world-update`＋`world-draw` 每幀約 1.2 KB；實際遊戲待機每幀約 17 KB，4 個角色打起來 20～25 KB，第 3 波 7 個角色加飛行道具是 30～41 KB。

## 5. 建置時間：從 2 分 18 秒回到 5 秒

有一陣子 `-O2` 建置突然要 2 分 18 秒。用 `emcc -O1 -c -ftime-trace` 對保留下來的 C 檔做分析，發現幾乎所有時間都花在同一個函式上：一個 1.7k 行、裡面有大量巢狀 `with-xform` 的場景建構函式。

原因是 `unwind-protect`、`handler-case`、`catch` 在 ECL 裡都編成 `setjmp`。一個函式裡的 `setjmp` 一多，控制流程就變成不可約（irreducible），clang 的 wasm 後端要先把它修成可約的（Fix Irreducible Control Flow），再做暫存器著色，兩者都是超線性成長。把大函式拆成小函式之後，建置時間回到 5 秒。

之後的規則是：`handler-case` 只在每幀最外層放一個（現在是引擎 `app.lisp` 的 `%FRAME`，啟動步驟另有一個 `%INIT-STEP`），大型建構程式碼要拆小。同一類問題還有一個變種：`EM_ASM` 不能出現在任何被 inline 進「有 `handler-case`／`catch`／`unwind-protect` 的 Lisp 函式」的地方，clang 會報「Cannot use EM_ASM* alongside setjmp/longjmp」。音訊模組改用 `EM_JS` 解決，因為 `EM_JS` 是 import，永遠不會被 inline。

## 6. 算圖

### 6.1 美術方向：程式產生的平面著色低面數模型

沒有美術素材，所有東西都要用程式產生，所以一開始就選了平面著色（flat shading）加頂點色的低面數風格。`meshgen.lisp` 提供方塊、圓柱、錐、球、刀等基本形狀，用 `with-xform` 組合，每個面的亮度隨機抖動一點（`:jitter`），看起來比較有手工感。頂點格式只有位置、法線、顏色共 9 個 float。

角色是「每個關節掛一個剛體部件」，一個部件一次 draw call，沒有蒙皮。這讓動畫系統簡單很多，也讓「打殘」變得很容易做：把手臂那幾個部件拆下來當碎片丟出去就好（第 8 節）。代價是 draw call 多，訓練場 4 個角色時 F3 顯示大約 103 次。

### 6.2 光源與後製

場景的樣子靠兩件事撐起來：雨夜的霧和霓虹。每幀最多 8 個點光源，挑離鏡頭注視點最近的；完全在視錐外的光源不佔名額。算圖先畫進一個多重取樣（MSAA 4x）的離屏目標，解析之後做 bloom 再合成到畫面上（GL 版用 FBO 和 `glBlitFramebuffer`，SDL_GPU 版改成 render pass 的 resolve，見第 11 節）。粒子、刀光、雨、貼花全部進兩個 fx 批次（加法混合和 alpha 混合），每批每幀 16384 個頂點。場景的雨和倒影甚至是 C 程式（現在是 `game/c/world.c`）直接寫進 fx 批次的 buffer，完全不經過 Lisp。

場景作者提出「每個 draw 要能有自己的鏡面反射強度」：地板想要 0.9 的濕亮反光，牆面只要 0.2，全域只有一個值只能折衷。引擎後來加了 `draw-mesh` 的 `:specular` 參數。

### 6.3 SwiftShader 量出來的數字要打折看

在 SwiftShader 上做效能分析時（以下是 GL 版時期的數字），有幾個結論和真 GPU 完全相反：

- 場景 demo 在 1280×720 下，8 個逐像素光源約佔整幀的 55%；bloom、天空、MSAA 各自不到 5%。場景 demo 約 9 fps，把場景光源關掉是 18 fps。
- 我們照直覺在 shader 裡加了 `if (d2 >= r*r) continue;` 想提早跳過沒照到的像素，結果在 SwiftShader 上毫無作用：它是在 CPU 上用 SIMD 模擬 GPU，分歧的分支兩邊都會執行。真 GPU 遇到一致的分支會跳過，所以這個提早跳出還是留著。
- 在 SwiftShader 上真正有用的是：減少迴圈次數、把工作移到頂點、減少像素。所以引擎加了 `*pixel-lights*`（只有最近的 N 個光源逐像素算，其餘改在頂點算，8 降到 1 可以省約 40%）和 `*render-scale*`（離屏解析度，0.7 大約讓整幀時間減半）。

這些知識最後變成動態畫質：`*auto-render-scale*` 打開後，每秒平均一次幀時間，超過預算（18 ms 的 1.25 倍）就降一級，先把解析度從 1.0 每次降 0.1 降到 0.7，再把逐像素光源降到 3、再降到 1；連續 3 秒有餘裕就升回去，而且有遲滯和退避，避免來回抖動。引擎預設是關的，這樣無頭截圖才會穩定可比較；遊戲本身在打磨階段已經在啟動完成時打開（現在是 `game/lisp/main.lisp` 的 `start-game`）。

實際遊戲在 SwiftShader 下大約 8 fps，每幀跑滿 6 個模擬步長，更多的積壓直接丟掉，所以無頭測試裡的遊戲時間大約只有實際時間的一半。Lisp 這邊每幀約 1.3 ms 模擬加 0.6 ms 排繪製佇列，瓶頸明顯在（軟體）GPU 上。

## 7. 音訊

一樣沒有素材，所以 26 個音效（包含雨聲和配樂兩個迴圈）全部在啟動時用 Lisp 合成：振盪器、包絡、狀態變數濾波器、延遲、殘響、和一組做太鼓、銅鑼、尺八的「樂器」。合成全部花 770～810 ms，樣本共 9.1 MB，存在 C 配置的記憶體裡；Lisp 那邊的暫存 buffer 在第一幀之後就被回收。配樂是 96 BPM、D 小調五聲音階的 8 小節迴圈（20 秒），渲染時多算 2.5 秒再折回開頭，鼓聲和殘響的尾巴才能無縫接上。

混音器是純 C，掛在 `SDL_OpenAudioDeviceStream` 的回呼上（F32、雙聲道、48 kHz、32 個聲部，最後過一個峰值限制器）。為什麼不在每幀由 Lisp 餵資料？

- 在 web 上，SDL 3.2.4 用 `ScriptProcessorNode` 的 `onaudioprocess` 事件驅動回呼，每次 2048 幀（約 43 ms）。JS 是單執行緒，這個事件只可能在兩幀之間觸發，不會打斷 Lisp。回呼本身也不碰 Lisp 物件，剛好符合第 3 節的 GC 規則。
- 遊戲卡頓、GC 或分頁切到背景時，音訊不會餓死，也沒有待補的佇列。
- AudioContext 不是 48 kHz 的裝置（例如 44.1 kHz），SDL 會自己重新取樣。

瀏覽器的自動播放限制：AudioContext 一開始是 `suspended`，要等使用者互動。SDL 3.2.4 自己有個計時器會在 `navigator.userActivation.hasBeenActive` 變成 true 後呼叫 `resume()`，但 Safari 要求 `resume()` 必須在手勢處理函式裡面呼叫。所以 `au_open` 另外在 `window` 上掛了 `keydown`、`pointerdown`、`touchend` 的 capture 監聽器，直接在手勢裡 resume。無頭 Chrome 預設不擋自動播放，要加 `--autoplay-policy=document-user-activation-required` 才測得到；這樣測時，第一次按鍵前狀態是 `suspended`，按下去之後是 `running`。

## 8. 玩法設計

設計規格在 `GAME_DESIGN.md`，背後的研究在 `research/ng4-notes.md`。研究筆記最後的結論有兩條直接變成了遊戲核心：

1. 《忍者外傳 4》最新的點子是「用量表變身來反制紅色攻擊」的猜拳關係（閃開，或花量表硬破）。
2. 打斷肢體會出現處決提示；用剛體部件做角色的話，這件事很好實作。

以下是幾個比較有意思的設計決定。

**判定形狀和動畫脫鉤。** 攻擊判定是寫死在攻擊者本地座標的幾何形狀（扇形 ARC、膠囊 CAP、球 SPH），不跟著動畫裡的刀走；刀的實際位置只用來畫刀光和火花。這樣平衡數值和動畫可以分開調，動畫師（其實也是程式）改姿勢不會改到難度。實作時還遇到一個插曲：規格裡照關節角度寫的攻擊姿勢，實際算出來刀都指向天空。後來寫了 `tools/pose-solve.py`，用和 `anim.lisp` 一樣的前向運動學反推手腕角度，讓每個攻擊關鍵影格的刀身方位角和仰角符合規格描述。

**60 Hz 固定步長。** 規格的所有幀數據都以 60 fps 的「幀」為單位，模擬也就用 1/60 秒固定步長跑，每幀最多補 6 步，積壓更多就丟掉。這讓「第 15 幀命中」這種描述在任何幀率下都成立。慢動作透過每個角色自己的時間倍率 K 實現，事件判斷用「是否跨過第 N 幀」，所以 K = 1 時幀數完全精確。

**hitstop 是全域凍結。** 命中停頓期間整個遊戲模擬停止（dt = 0），但粒子、鏡頭震動、UI 和雨照常跑。同一幀有多個停頓事件取最大值，不相加。這比「只凍結攻擊者和被打的人」簡單很多，也更有打擊感。輸入緩衝用的時間戳 `*tick*` 在 hitstop 期間照常前進，所以停頓時按的鍵會被記住。

**攻擊權杖。** 我們想要「很兇但公平」：近戰權杖只有 2 個、遠程 1 個，拿到權杖才能出招，沒拿到的敵人在外圈繞圈，偶爾做假動作。但玩家出了大硬直（≥ 14 幀恢復）時，附近的敵人可以拿第 3 個「懲罰權杖」，而且蓄力縮短為 0.8 倍。從鏡頭外攻擊的敵人蓄力多 10 幀，並在畫面邊緣顯示紅色箭頭。規格的第一條原則是「每一次被打中都是你自己的錯」，這些規則都是為了它。

**紅色攻擊。** 蓄力至少 48 幀（頭目第二階段 42 幀），蓄力期間有霸體，全部造成擊倒，擋了會破防加全額傷害。應對方式只有三種：閃避、在蓄力中用 Raven 型態的攻擊打斷（Raven Break），或在 Raven 型態下花 15 量表硬擋。

**打殘與 Obliterate。** 重攻擊把敵人打到 30% 血以下（OXHEAD 25%）就拆掉它的武器手，頭上跳出提示，按重攻擊一刀處決。殘兵不處理的話，3 秒後會發動紅色的 Death Grip 撲上來。系列作裡「斷肢的敵人會自爆式反撲」這點在研究筆記標為未證實，我們還是採用了，因為它會逼玩家主動去收尾。

**Raven 量表。** 打中 +2、重攻擊命中 +4、擊殺 +3、格擋和 Just Dodge 各 +8、Obliterate +25，不在 Raven 型態時每秒自然 +1。40 以上可以發動，Raven 型態每秒掉 10。規格估計每波可以變身 2～3 次、頭目戰 3～4 次。

**Just Dodge 的判定放寬。** 規格寫的是「閃避前 10 幀內碰到敵人判定」。但翻滾速度是 18 m/s，一個 2 公尺寬的攻擊弧大約 2 幀就穿過去了，實際上變成一幀的窗口。所以閃避期間用 `*just-dodge-reach*`（0.8 m）把玩家的受擊半徑放大來判定。

**原創名稱。** 研究筆記的原則是「照結構抄，名字自己取」。遊戲裡沒有用《忍者外傳》的任何角色、名稱或素材：主角是 REN，變身叫 Raven Form，量表叫 Raven gauge，Izuna Drop 風格的抓摔叫 Thunderfall，飛燕風格的飛身斬叫 Kestrel Strike，舞台是虛構的 Neo-Kasumi 市 Tsukuyomi Tower 頂樓，敵人是雨之軍團和 ENRA。

## 9. 團隊與流程

這個專案是由多個 AI agent 分工完成的，大致分成這幾個階段：

1. 第一階段三條線平行：引擎（平台、數學、算圖、模型產生、文字）、音訊、以及玩法研究和設計規格（產出 `research/ng4-notes.md` 和 `GAME_DESIGN.md`）。
2. 第二階段：戰鬥核心（動畫、角色、判定、玩家、特效、HUD）和場景（`world.lisp`）平行進行。
3. 第二階段 b：敵人 AI 與遊戲流程（`enemy.lisp`、`game.lisp`），同時另一條線做算圖效能。
4. 最後是審查、打磨和文件。

能平行做而不互相踩到，靠的是幾份事先寫好的「合約」：

- `ARCHITECTURE.md` 定下模組表（誰負責哪個檔案）、`MANIFEST` 順序、GC 規則和 C static 的命名前綴。
- `ENGINE_API.md` 把引擎的每個呼叫、座標慣例、「`!` 函式不配置記憶體」這類規則寫清楚，玩法那邊只照文件寫，不用讀 render 的原始碼。
- `world.lisp` 一開始先有一個 stub，只提供 `world-init`、`world-update`、`world-draw`、`arena-resolve`、`arena-ground-height`、`*arena-half*` 這組 API，戰鬥核心拿 stub 先開工，場景作者再把內容填進去。`WORLD.md` 的 API 表裡標了「added」的項目，就是後來在合約之外加的。
- 每個人用自己的 `NAME` 呼叫 `./build.sh NAME ...` 建測試目標，建置產物不會撞在一起。
- 發現對方模組需要改的地方，寫進文件的「Requests」或「Engine requests」段落，由負責人處理，而不是直接改別人的檔案。

另一個關鍵是無頭測試工具 `tools/run.mjs`。它不依賴任何 npm 套件，用 Chrome DevTools 協定開無頭 Chrome，照 JSON 腳本在指定秒數送按鍵、滑鼠和 `eval`，拍截圖，把 console 輸出轉出來，頁面有 JS 例外就回傳非零結束碼。配合遊戲裡的 `Module._debug_cmd(n)`（跳波次、強制某個敵人出某一招、在蓄力中凍結畫面、開無敵、自動遊玩 bot），agent 不需要真的「玩」也能驗證每個招式和每種敵人的行為。`*combat-log*` 會把狀態變化、命中、傷害、權杖都印到 console，測試腳本就對這些文字做斷言。`tests/shots/` 裡那些截圖都是這樣拍的。讓 bot 從標題一路打到結算畫面，全程沒有錯誤（最近一次的量測見第 13 節）。

這套做法也有盲點：agent 看得到截圖和 log，但感受不到手感。打擊感、鏡頭、難度這些東西，最終還是需要真人拿手把玩過才算數。

## 10. 已知限制與之後可以做的事

**畫面只在 SwiftShader 上比對過。** 截圖都來自無頭 Chrome 的軟體算圖。搬到 SDL_GPU 時曾在本機的 RTX 4090 上量過時間（見第 11 節），但無頭模式下用實體 GPU 拍到的畫布是空白的，所以實體 GPU 上的畫面沒有人親眼確認過，也不確定不同瀏覽器和顯示卡上有沒有相容性問題。

**libecl 是 `-O0` 建的。** 交叉建置時 `configure` 給的 `CFLAGS` 是 `-O0`，我們自己的 Lisp 程式碼則是 `-O2`。ECL 執行期函式（泛型算術、`format`、雜湊表等）都在跑沒最佳化的程式碼。用 `-O2` 重建 libecl 應該是投資報酬率最高的效能改善，順便也可能縮小 wasm（目前約 5.5 MB）。

**GC 會造成偶發卡頓。** 每次幀間 GC 是一次完整的 stop-the-world 回收，32 MB 左右的堆要幾毫秒。不用 ASYNCIFY 的增量回收，或是讓 ECL 用 shadow stack 記錄根，都是可以研究的方向，不過都不是小工程。

**動態畫質**在打磨階段已經預設開啟（見第 6.3 節）；它只在幀時間超出預算時才降低解析度。

**規格裡砍掉或簡化的部分**（詳見 `GAMEPLAY.md` 的 Cuts）：

- 鎖定目標（Tab 目前無作用）和威脅方向的自動轉鏡頭。
- Just Dodge 的殘影改成一團光。
- 圍巾用程式擺動，沒有彈簧模擬。
- 配樂只有一個迴圈，頭目第二階段是把它用 1.12 倍音高重新播放，沒有分層；雨聲音量也不會隨狀態改變。
- 頭目戰的 7 公尺鏡頭距離、橫移動畫、勝利時甩血的動作。

**文件裡還開著的請求**：第二層配樂（`GAMEPLAY.md`）。雨聲隨狀態調整、頭目戰 7 公尺鏡頭、模型產生不再逐三角形配置記憶體，都已在後續階段完成。

**SDL 的 WebGPU 後端還是草稿。** 我們固定在 PR #16020 的某個 commit，加上本地 patch。等上游合併、emsdk 內建的 emdawnwebgpu 版本跟上之後，應該換回官方版本，並把 patch 裡仍然需要的部分由人確認後回報上游（第 11.4 節）。有了 WebGPU，compute shader 和更好的多光源方案也變得可行。

## 11. 改用 SDL_GPU（WebGPU 後端）

### 11.1 先確認「不能用」是真的

第一版選 GLES3 的理由是 SDL_GPU 沒有 web 後端。被問到時先實測：用 emsdk 內建的 SDL 3.2.4 在無頭 Chrome 裡呼叫 `SDL_GetNumGPUDrivers()`，回傳 0，`SDL_CreateGPUDevice` 回報 `No supported SDL_GPU backend found!`。SDL 3.4 的後端也只有 Vulkan、Metal、D3D12。社群第一次嘗試的 PR #12046 在 2025 年 3 月被關掉；2026 年 7 月開的 PR #16020 支援 Emscripten，但仍是草稿。結論是官方版本確實不能用，只能拿草稿分支自己建。

### 11.2 一路上撞到的牆

1. **建立裝置會卡死。** 後端用忙等迴圈等 `requestAdapter` 的結果，瀏覽器裡這需要 ASYNCIFY 或 JSPI。作者的範例用 ASYNCIFY，但我們不能用：ECL 的 `handler-case` 底層是 setjmp／longjmp，會經過 JS 的 `invoke_*` 包裝，JSPI 無法跨越 JS 堆疊框暫停，ASYNCIFY 則會讓整個 ECL 變大變慢。最後的做法是讓網頁在 `preRun` 裡先用 JS 非同步要好 adapter 和 device，再開始跑 wasm；SDL 那邊加一段 patch，直接匯入這兩個物件。這樣建立裝置時就完全不用等待。
2. **ABI 不一致。** SDL 分支內附的 `webgpu.h` 比 emsdk 4.0.12 內建的 emdawnwebgpu 新，連 `WGPUTextureFormat_RGBA8Unorm` 的數值都不一樣（0x16 對 0x12），表現出來是「surface 不支援 SDR」這種莫名其妙的錯誤。改用 Dawn 2026-09-17 的 emdawnwebgpu 套件後，兩邊的列舉值就一致了。
3. **只有第一幀有畫面。** 後端只在會等待的 `WaitAndAcquire` 裡回收已完成的 command buffer；我們不能等待，只能用非阻塞的 `AcquireGPUSwapchainTexture`，結果 in-flight 計數卡在上限，之後每幀都拿不到 swapchain。修正是讓非阻塞版本在達到上限時先輪詢一次 fence。
4. **無頭測試環境。** 無頭 Chrome 預設的 WebGPU 在 SwiftShader 上會立刻回報 device lost，連純 JS 頁面也一樣，原因是 WebGPU 的 swapchain 和走 GL 的合成器之間沒有可共用的影像格式。改用 `--enable-features=Vulkan --use-vulkan=swiftshader --use-webgpu-adapter=swiftshader --use-angle=vulkan` 讓合成器也走 Vulkan 之後就正常了，這組參數現在是 `tools/run.mjs` 的預設值。
5. **ECL 的 `@`。** `ffi:clines` 和 `c-inline` 會把 C 字串裡的 `@` 當成自己的語法，WGSL 的 `@group`、`@location` 全被改寫壞。WGSL 因此都放在 Lisp 字串裡，當成資料傳給 C。

### 11.3 搬遷後的樣子

算圖層共有 11 條 pipeline（受光著色的四種變體、天空、兩種 fx、bloom 三段、UI）。每幀一個 command buffer：先用一個 copy pass 上傳四個緩衝，再畫 4x MSAA 的場景，接著五個 bloom pass，最後合成到 swapchain 並畫 UI。每次 draw 的資料不是逐次 push uniform，而是整批放進 storage buffer，由 vertex shader 用 instance 索引讀取；在 RTX 4090 上錄 258 次 draw，這樣做的 CPU 時間是 0.10 ms，逐次 push 則是 0.33 ms。`m4-perspective!` 直接產生 WebGPU 的 [0,1] 深度。

在同一套無頭環境下，兩個版本每幀的配置量都在 15～19 KB。實體 GPU 上兩者都卡在 vsync 的 16.7 ms，SDL_GPU 版每幀的 CPU 成本多約 0.15 ms。SwiftShader 下的畫面和 WebGL 版逐張比對，看不出差異（`tests/shots/gpu-*` 對 `webgl-*`）。

### 11.4 本地 patch 與上游

`vendor/sdl3-webgpu.patch` 裡每一處都標了 `raven-edge patch:`：匯入預先建立的裝置、非阻塞 acquire 也會回收 fence、`IndirectFirstInstance` 改成選用（SwiftShader 沒有，我們也用不到）、canvas selector 的長度欄位沒有初始化、bind group 沒變就不重設（錄 258 次 draw 從 0.55 ms 降到 0.03 ms）、SDL 不含 GLES 時跳過 WebGL 相關的掛鉤，以及 device lost 時印出原因。

SDL 專案的 `CLAUDE.md` 明訂不接受 AI 產生的程式碼貢獻。這些修正只給本專案用；如果要回報上游，必須由人自己確認問題、自己寫修正。

## 12. 最後的減法

功能完成後，照 ponytail 的原則（能刪就刪、標準函式庫有的不自己寫、只有一個呼叫者的層就拿掉）分三塊平行清理：引擎與工具、場景與遊戲流程、戰鬥。刪掉的主要是沒人用的東西：整套四元數 API、幾個輸入查詢函式、每個 mesh 都在算卻沒人讀的邊界、24 個多餘的 `:magnet 0`、重複的 guard、只在一處使用的包裝函式，以及可以由產生器重建的 JSON 腳本和舊截圖。為了 ECL 效能刻意寫成的熱路徑（`defun-fast`、`let*`、C 的 `fminf` 等）一律保留。每一塊清完都重新建置、跑數學測試、比對戰鬥 log 和截圖，並讓 bot 從標題打到結算，確認行為沒有改變。

## 13. 拆出引擎、改成 ECS，並整理成教材

遊戲完成後，使用者提出新的要求：把嵌在 Lisp 裡的 C 和 WGSL 拆成獨立檔案；核心邏輯改用函數式程式設計加 ECS 重構；可重用的架構獨立成引擎；整個專案要變成適合初學者的學習範例。工作分三個階段，每個階段結束都重新建置、跑主機測試，並讓 bot 從標題自動打到結算，確認行為沒變。

| 時間點 | bot 打到結算 | 評價 | 分數 |
|---|---|---|---|
| 重構前 | 112.3 秒 | S | 7100 |
| 第一階段後 | 115.6 秒 | S | 7130 |
| 第二階段後 | 110.0～110.6 秒 | S | |

### 13.1 第一階段：拆檔、抽出引擎

原本的 `src/` 分成三塊：`engine/`（ENGINE 套件）、`game/`（RAVEN 套件）、`examples/`。

- **C 回到 C 檔。** 以前 C 程式碼寫在 `ffi:clines` 的字串裡，編輯器沒有語法高亮，編譯錯誤也很難對照。現在引擎的 C 在 `engine/c/*.c`，全部宣告集中在 `engine/c/engine.h`，場景的 C 在 `game/c/world.c`。Lisp 這邊只剩一行一個的 `ffi:c-inline` 呼叫。
- **WGSL 回到 WGSL 檔。** 著色器搬到 `engine/shaders/`，共用的部分（`Frame` 結構、光照、霧）用 `// #include "frame.wgsl"` 引入。`render.lisp` 的 `wgsl` 巨集在編譯時讀檔、展開 include、去掉註解，結果仍是編進 wasm 的字串常數：執行時不用讀檔，也照樣避開 ECL 對 `@` 的特殊處理（第 11.2 節）。
- **每個建置目標一份 MANIFEST。** `./build.sh DIR` 讀 `DIR/MANIFEST`，引擎的 MANIFEST 永遠排在前面，網頁標題取自 `# title:` 那一行。
- **引擎掌握主迴圈。** 啟動步驟、每幀流程、錯誤顯示、除錯指令佇列都搬進 `engine/lisp/app.lisp`，遊戲只用 `run-game` 登記自己的載入步驟和每幀函式。引擎的程式碼不再提到遊戲，`examples/engine-demo` 不帶任何遊戲程式碼也能建置。
- **補上 `tools/pkgcheck.sh`。** 分成兩個套件之後出現一種新的錯誤：遊戲用到引擎沒有 export 的函式名，會悄悄變成遊戲套件自己的符號，而 ECL 對未定義的函式不發警告。這支腳本只讀原始碼、不編譯，列出這種符號。

### 13.2 第二階段：ECS 與函數式核心

- **自己寫一個很小的 ECS。** `engine/lisp/ecs.lisp` 一百多行：實體是一個 fixnum（槽位加世代），每種元件一個長度 256 的向量，`do-entities` 展開成一個普通迴圈。沒有用現成的函式庫：需要的功能就這麼多，一個檔案寫得完，而且是純 Common Lisp，可以直接在主機上測（`tests/ecs-test.lisp`）。編號帶世代，是為了讓「記住別人的編號」這件事安全：實體刪掉後，舊編號自動失效。
- **什麼是實體，什麼不是。** REN、敵人、訓練假人、飛行道具是實體（以前的 `actor` 結構拆成 `transform`、`motion`、`model`、`health`、`fighter`、`blade-trail`、`player`、`brain` 等元件；飛行道具以前是一個 32 格的 float 池）。粒子、雨、碎片不是：它們有好幾千個，放在 float 陣列裡幾乎零成本，做成實體只會變慢。
- **規則是純函式。** 判定、命中結果、取消視窗、Raven 量表、攻擊權杖、分數評價都搬進 `game/lisp/rules.lisp`，只收參數、只回傳值。這個檔案是純 Common Lisp，`tests/rules-test.lisp` 在主機上一秒內就能跑完，不用建置也不用瀏覽器。
- **狀態仍然原地修改。** 系統（命令式外殼）收集規則需要的輸入、呼叫規則、再把結果寫回元件。沒有改成「每步產生新元件」，因為 ECL 會把存進一般位置的 float 裝箱（第 4 節），全部複製一份會讓垃圾量和 GC 停頓成倍增加。
- **事件取代直接呼叫特效。** 戰鬥程式碼改成 `emit` 事件，`feedback.lisp` 的 `feedback-system` 在每個步長結尾統一播放聲音、血霧、震動、停頓和慢動作。hitstop 和慢動作在步長結尾設定、從下一步生效，時序和以前規則直接設定時一樣。
- **資料集中。** 招式（`moves.lisp`）、角色外觀（`bodies.lisp`）、動畫（`clips.lisp`）、音效（`sounds.lisp`）都是宣告式的資料檔，平衡數值集中在 `tuning.lisp`。函式也順便改了名，例如 `actor-start-move` → `start-move`、`make-enemy` → `spawn-enemy`、`hit-feedback` → `emit-hit` 加 `feedback-system`（`GAMEPLAY.md` 已全部改用新名稱）。

代價：同一段自動遊玩，**每秒真實時間的配置量多了約 10%**。規則回傳的結構和事件串列都是每次命中新配置的短命物件。**啟動完成時的堆從 71 MB 變成 87 MB**，但實際增加的只有模組載入時的 1.8 MB 常數資料：它剛好越過 Boehm GC 的一個堆擴張門檻，堆一次長了一大格。兩項都還在預算內。

### 13.3 第三階段：教材

- **`examples/hello`**：123 行、讀得完的最小遊戲。用到 `run-game` 的載入步驟和每幀函式、`build-mesh`、鏡頭、三種元件、三個用 `do-entities` 寫的系統、一條純規則、一個事件、鍵盤輸入、UI 文字和一個合成音效。它刻意不用固定步長和 `defun-fast`，改用真實 dt 和一般的 `defun`，讓第一次讀的人只需要面對 ECS 的概念；什麼時候需要那些工具，教材第 3、8 步會講。它啟動完成時的堆是 23 MB，wasm 4.8 MB（大部分是 libecl）。
- **`docs/TUTORIAL.zh-TW.md`**：從建置、專案地圖、逐行讀 hello，到幀迴圈與 GC、ECS、純函式規則、事件、算圖，最後追蹤 RAVEN EDGE 的一下攻擊從招式資料到音效的完整路徑，每一步都標了檔案和行號，最後附練習題。
- 根目錄 `README.md` 改寫成入口頁；`ARCHITECTURE.md`、`ENGINE_API.md`、`GAMEPLAY.md` 更新到新的程式碼，刪掉已經不成立的敘述。


### 13.4 第四階段：獨立審查

另開一個 agent 只讀不改，把原本的 `src/`（第一階段前的備份）和新程式逐項對照：資料檔逐條比對、抽出來的 C 對照原本的字串、WGSL 去掉註解後比對、`emit` 和 `feedback-system` 的參數逐一核對、在 host 上編譯每個目標檢查有沒有未定義的函式。重構本身沒有造成嚴重的行為差異，但查出一個**原本就有**的錯誤：

- **按住防禦幾乎每次都變成彈反。** 防禦按鍵的時間戳記用的是 `*ptick*`（1/16 幀），判斷彈反視窗時卻拿 `*tick*`（幀）去減，差出來永遠是很大的負數，永遠落在 8 幀的視窗內；防連打的 20 幀判斷也因為單位錯了而從不觸發。改成兩邊都用 `*ptick*` 換算幀數之後，重跑同一個腳本（訓練模式，敵人攻擊，Q 從第 8 秒按到第 24 秒）：原本 0 次格擋全是彈反，改完 9 次格擋、0 次彈反，防禦量表耗盡會破防，跟設計一致。
- 敵人屍體留存時間 2 → 2.5 秒：重構後投射物命中要靠丟出者的實體還在，而爆裂苦無飛行加引信最長約 2.4 秒。
- `do-entities` 寫錯元件名稱現在會在編譯時報錯（原本會悄悄註冊一種新元件）；C 的隱式函式宣告改成錯誤（`-Werror=implicit-function-declaration`）。
- 修正文件：`c-inline` 的 `#` 後面是一個 36 進位的字元（第 11 個參數寫 `#a`），不是「只能到 `#9`」；教材裡幾處行號、頂點緩衝的描述。

最後一次完整自動遊玩：`game -> RESULTS (wave 4, run 114.5 s)`，無錯誤。
