# dream-rsi 使用紀錄：SOUL DUEL 角色 AI v2（2026-10-02）

這份筆記整理 2026-10-02 用 dream-rsi skill 搜尋五個角色 CPU AI 的過程，給下次要再用時參考。設計本身和最終數字在 `docs/duel/DUEL_AI_V2.md`，決策過程在 `docs/DEVLOG.zh-TW.md` §77。這裡只寫「這個方法實際怎麼跑、哪裡出問題、下次怎麼做」。

**標記方式**

- `WS` = `docs/research/ai-v2-drsi/`。這是搜尋用的工作區，在 f8733ad commit，後來從 `research_notes/` 搬到這裡。
- 每條事實後面註明出處：檔案路徑、commit，或「transcript」。transcript 指 2026-10-02 那次對話的紀錄（session 3954810d）。
- 時間一律是 +0800。
- skill 本身稱為「dream-rsi skill」，它的目錄寫成 `$DREAM_RSI`。

---

## 1. 一句話

用 dream-rsi 替五個角色各自搜尋 CPU AI。每個變體只改 `duel/lisp/<角色>.lisp` 裡的 `:ai` 表和反射函式。評分器是跑在原生模擬上的 `tools/aieval.py`。每個角色選出一個變體後，交給一個整合 subagent 併進 main，再接上學習型 AI 和 ASSIST。（出處：`docs/duel/DUEL_AI_V2.md` 開頭、DEVLOG §77）

---

## 2. 設定與對應

| dream-rsi 的概念 | 這次的對應 | 出處 |
|---|---|---|
| task | `SOUL DUEL <角色> CPU AI (duel/lisp/<角色>.lisp :ai tables and reflexes), scored by tools/aieval.py --char i` | `WS/<角色>/config.json` |
| cell | `duel/lisp/<檔>.lisp` 的一個變體（檔名是 yama／ken／rukia／ichigo／senjumaru）。交付三個檔：`<檔>.lisp`、`proposal.md`、`score.json` | `WS/brief.py` |
| eval command | `python3 tools/aieval.py --char i -j 4`，在 cell 自己的 worktree 根目錄跑 | `config.json` |
| score | `0.6 strength + 0.2 masher + 0.2 signature`；NORMAL 節奏檢查沒過就是 0 | `tools/aieval.py` docstring |
| 網格 | `--branches 2 --refines 2`、`plan --beta 0.6`、λ = 0.25 | `config.json`；transcript（init 指令） |
| workers | 1：同一個角色一次只跑一格 | `config.json` |
| 預算 | 使用者選「2 輪 × 4 個」：每角色 8 格，五個角色共 40 次 subagent | transcript（AskUserQuestion）；DUEL_AI_V2 |
| 平行 | 5 個角色同時跑。每格是一個 `Agent(isolation: "worktree")`，在 `.claude/worktrees/agent-<id>` 裡工作 | transcript |
| 分配策略 | round 1 用 skill 內建的 `baseline_parallel_refine.py`；round 2 promote 成 `adaptive_template.py` | `WS/<角色>/policy/` |

**aieval 怎麼量**（出處：`tools/aieval.py`）

- **strength**：HARD 難度。這個角色對另外四隻 CPU，P1／P2 都打，每組 20 場，共 160 場，算勝率。
- **masher**：五個角色輪流當笨玩家（P1），對這個角色（P2）。每組 16 場，共 80 場。
- **signature**：這個角色造成的傷害裡，不是 J／K 連段（招式名符合 `-[JK]\d`）的比例。
- **pacing**：NORMAL 難度，這個角色當 P1 對另外四隻。每場都要 K.O.，而且 20 場的中位數要 ≤ 220 秒。
- **對手**：同一個 checkout 裡另外四隻角色的 CPU。每個 cell 的 worktree 開在 main 上，所以搜尋時的對手一直是「已上線的舊版 CPU」。

**協調腳本**（全部放在 `WS/`）

| 檔案 | 做什麼 |
|---|---|
| `brief.py` | 把 skill 的 exploration prompt 加上專案說明，產生一格的任務書 `nodes/<cell>.brief.md`。任務書要求先讀完整歷史、只改角色檔、新機率依難度分層、最後交回量測到的 JSON |
| `rescore.sh` | 在 `.claude/worktrees/rescore-<角色>`（detached 在 main）把交回的檔案蓋上去，用當下的 aieval 重量一次，結果寫成 `score.rescored.json` |
| `step.sh` | 一格結束時跑一次：必要時先從 agent 的 worktree 複製交付物，接著 rescore，再用重量的分數 `drsi.py record`，然後 `next-batch`，最後用 brief.py 寫下一格的任務書 |
| `integration.brief.md` | 搜尋結束後給整合 subagent 的任務書，共六步：選檔、NORMAL、學習型 AI、ASSIST、gate、文件 |

---

## 3. 實際流程（2026-10-02）

- **04:28**：使用者提出需求。萊醬載入 skill，用 AskUserQuestion 問了四件事：評分方式、預算、強度、平行數。使用者選了「勝率＋角色特色」「2 輪 × 4 個」「難度分層」「5 個，每角色 1 個」。（transcript）
- **04:33–04:35**：寫 `tools/aieval.py` 和 `tools/simgate/run-log.lisp`，量 baseline，init 五個 workspace 並開 round 1。（commit 7176715；transcript）
- **04:36**：五個角色的 b0a0 同時出發。（transcript）
- **05:08–05:09**：露琪亞 b0a0 回報時指出 aieval 的笨玩家判定有 bug。修正後重量全部 baseline，已交回的 cell 也重量。（commit 9df6ecc；transcript）
- **05:16**：把「重量、記錄、開下一格」寫成 `step.sh`，之後每格都走它。（transcript）
- **06:10、06:13**：兩次碰到用量上限，暫停派新 cell。背景的 subagent 繼續跑，額度恢復後再收結果。（transcript）
- **07:00–07:47**：劍八、千手丸、露琪亞、山本依序 `close-round 1` → `compare` → `promote adaptive_template.py` → 開 round 2。（transcript）
- **round 2**：每個角色只跑了 b0a0 一格。露琪亞和劍八在 HARD 已經接近全勝；山本 round 2 改用火焰招式，分數反而下降。所以都停了。一護 round 1 只跑 3 格，沒有 close，也沒進 round 2。（transcript；`WS/ichigo/` 沒有 `trace_pool/` 和 `compare.json`）
- **08:48–08:50**：最後一格（一護 b0a1）回來，接著派出整合 subagent。（transcript）
- **09:59**：整合回報，fast-forward 進 main（e07c316 … 9ccdd2b）。（git log；transcript）

**花費**

- 實際跑了 23 個 cell，加 1 個整合 subagent。原本計畫 40 個 cell。（`WS/*/rounds/*/trace.json`）
- 單格耗時從 10 分鐘（千手丸 r1 b0a1）到 2 小時 18 分（一護 r1 b0a0）不等；一次 `step.sh` 約 2–3 分鐘。（transcript 的派發與回報時間）
- 搜尋階段約 4 小時 15 分，整合約 1 小時 10 分。（transcript）

---

## 4. 成果

分數都是 20 場，用修正後的評分器。baseline 欄是修正後重量的值。（出處：`WS/<角色>/baseline/score.json`、`nodes/*/score.rescored.json`、DUEL_AI_V2「HARD strength against the new set」）

| 角色 | baseline | r1 b0a0 | r1 b1a0 | r1 b0a1 | r1 b0a2 | r2 b0a0 | 選用 | 搜尋分數（strength） | 整合後對新的一組（40 場） |
|---|---|---|---|---|---|---|---|---|---|
| 山本 | 0.635 | 0.864 | 0.747 | 0.861 | **0.899** | 0.873 | r1 b0a2，加上 r2 b0a0 的 NORMAL 修正 | 0.899（0.969） | 0.616（0.512） |
| 劍八 | 0.301 | 0.800 | 0.782 | 0.851 | 0.866 | **0.858** | r2 b0a0（整合時 80 場比較：0.749 對 0.747） | 0.858（0.938） | 0.762（0.781） |
| 露琪亞 | 0.750 | 0.870 | 0.911 | 0.934 | 0.952 | **0.953** | r2 b0a0 | 0.953（0.981） | 0.763（0.669） |
| 一護 | 0.507 | 0.787 | 0.660 | **0.816** | — | — | r1 b0a1 | 0.816（0.831） | 0（節奏沒過；0.312） |
| 千手丸 | 0.571 | 0.683 | 0.594 | 0.717 | 0.786 | **0.810** | r2 b0a0 | 0.810（0.856） | 0.432（0.225） |

- **除了露琪亞（b1a0 0.911 對 b0a0 0.870），b1a0 都比 b0a0 低**，也就是第二個「全新方向」大多不如第一個。最好的版本都來自改進格。劍八、露琪亞、千手丸、一護的 b0a1 都是「b0a0 加上 b1a0 不重疊的部分」；山本的 b0a1 量過這個組合，結果較差，沒有採用。（上表；各 cell 的 `proposal.md`；transcript 各 cell 回報）
- **整合後的五個 strength 平均是 0.4998**（0.512、0.781、0.669、0.312、0.225）。五隻互打、雙邊都打的勝率本來就會平均到 0.5。搜尋時每隻都在 0.83–0.98，是因為對手是舊版；大家一起變強之後，這部分加總不變。（由 DUEL_AI_V2 的數字算出）

---

## 5. 踩到的問題與解法

### 5.1 評分器在跑到一半時改了 bug

- **現象**：露琪亞 b0a0 回報說，笨玩家和自己同角色對打時，笨玩家贏的場次被算成這個角色的。（transcript 05:08）
- **原因**：masher 的工作把笨玩家放 P1、角色放 P2，但五個笨玩家裡有一個是角色自己。舊程式用 `side = 0 if c1 == c else 1` 判斷座位，在這一組就判成 P1。（`git show 9df6ecc`）
- **處理**：
  - 改成 `side = 1 if kind == 'mash' else ...`。
  - 五個 baseline 重量：山本 0.595 → 0.635、劍八 0.291 → 0.301、露琪亞 0.765 → 0.750、一護 0.477 → 0.507、千手丸不變。
  - 已交回的五個 r1 b0a0 重量，分數上升 0.005～0.04（例如山本 0.824 → 0.864）。
  - 從此 `step.sh` 一律記錄重量後的分數，不記 agent 自己報的。
  - （出處：commit 9df6ecc；`nodes/b0a0/score.json` 對 `score.rescored.json`；transcript）
- **留下的痕跡**：
  - `baseline/score.json` 修正時只改了 `score` 欄位，`masher` 還是舊值。例如山本寫 0.8，重量時其實是 1.0。（transcript 05:13 的修補指令；同一時段的重量輸出）
  - round 1 的 `trace.json`（還有 `trace_pool/iter01/`）裡的 `baseline_score` 是修正前的值，因為 round 1 在修正前就開了。
  - `docs/duel/DUEL_AI_V2.md` 的 baseline 表也是修正前的數字。
- **下次怎麼做**：
  - 開跑前先用 baseline 和一兩個手寫變體把評分器跑一遍，特別是對稱、內戰、座位這類邊角。確認沒問題後凍結（記下 commit），再 init。
  - 真的要中途修，就整份重量、整份覆寫 JSON，並重開 round。

### 5.2 worktree 不讓 agent 寫進共用的 NODE_DIR

- **現象**：
  - 劍八 r1 b0a1 回報「worktree refused writes to the shared NODE_DIR」，交付物只放在自己的 worktree 裡。
  - 千手丸 b0a0 的交付物也得從 worktree 複製出來。
  - （transcript 05:11、06:19）
- **原因**：`isolation: "worktree"` 的 agent 被限制在自己的 worktree 內，寫不到主 checkout 的路徑。
- **處理**：
  - brief.py 加上一段：寫不進 NODE_DIR 時，就寫到自己 worktree 裡的同一個相對路徑，並在回報裡說明。
  - `step.sh` 第 6 個參數是 agent 的 worktree 路徑；NODE_DIR 裡沒有 `.lisp` 時就從那裡複製。
  - （`WS/brief.py`、`WS/step.sh`）
- **下次怎麼做**：一開始就規定交付物寫在 worktree 內的固定相對路徑，由協調者負責複製。不要指望 agent 能寫到外面。

### 5.3 搜尋分數是對舊版 CPU 量的（過擬合、不可遞移）

- **現象**：
  - 搜尋分數 0.81～0.95，整合後對上新的一組只剩 0.43～0.76。一護還因為節奏檢查變成 0。
  - 千手丸的 strength 從 0.856 掉到 0.225。
  - （§4 表）
- **原因**：
  - 每個 cell 只換自己的角色檔，另外四隻都是 main 上的舊版。所以學到的是「怎麼打舊版的弱點」。
  - 五隻一起換掉之後，互打的勝率總和是固定的（平均 0.5）。
- **處理**：整合 brief 明寫「對新的一組只記錄、不設目標」，DUEL_AI_V2 也照實記錄。（`WS/integration.brief.md` Step 2；DUEL_AI_V2）
- **下次怎麼做**：
  - 搜尋時的對手組要固定，並寫進 config 的 task 說明。
  - 想要的是「整體更好」的話，評分就不要只看對舊版的勝率。可以改成對固定對手組加上對其他角色目前最佳 cell 的勝率，或是在 round 之間把各角色的最佳版本一起換上，重量 baseline 後再開下一輪。
  - 最後選檔時，一定要用「新的一組」再量一次。

### 5.4 20 場的雜訊大於變體之間的差距，挑到的常是運氣好的那次

- **現象**：
  - 20 場的總分大約有 ±0.03 的隨機波動，masher 單項約 ±0.06。（transcript 07:02；千手丸 b1a0 回報）
  - 山本 b0a2 在 20 場的 strength 是 0.969，80 場只剩 0.931。
  - 劍八 r2 b0a0 在 20 場比上一版低（0.858 對 0.866），40 場和 80 場反而比較高（80 場：0.853 對 0.844）。
  - （transcript 各 cell 回報）
- **原因**：每格只量 20 場，然後從中挑最高的，自然會偏向運氣好的那次。
- **處理**：
  - 07:02 之後派發的 prompt（山本 r1 b0a2、一護 r1 b0a1 和 round 2）改成「變體用 40 場判斷，最後交 20 場的官方分數」。（transcript 派發 prompt）
  - 整合時劍八的兩個候選用 80 場比，結果 0.749 對 0.747，等於平手。
- **下次怎麼做**：
  - 所有 cell 用同一組固定的 seed。
  - cell 內部比較用 40 場以上；最後選檔用 80 場。
  - 記錄到 dream-rsi 的分數要和選檔用的場數一致。

### 5.5 NORMAL 難度跟著變強

- **現象**：
  - 每隻 NORMAL CPU 對另外四隻 NORMAL、雙邊各 40 場，劍八的勝率從 0.397 跳到 0.806。
  - 露琪亞在劍八壓回之後變成 0.703（原本 0.603）。
  - 山本 r1 b0a2 在 NORMAL 也從 0.431 升到 0.500。
  - （DUEL_AI_V2「NORMAL stays near the shipped CPU」；transcript 山本 r2 回報）
- **原因**：
  - aieval 只量 HARD 的強度，NORMAL 只檢查節奏，所以 cell 加進去的 NORMAL 機率完全沒有被量到。
  - 劍八的中立判斷每一步都擲一次骰子（J1 突進、對非笨玩家的先手），就算每次機率很小，NORMAL 也幾乎每一步都會觸發。
- **處理**：
  - 劍八這兩項在 NORMAL 改成 0；走近、對笨玩家的架式和先手壓到 0.002～0.005；事件觸發的機率維持 cell 交回的值。
  - 露琪亞的 NORMAL 機率全部減半。
  - 山本的 NORMAL 反 Breaker J1 從 0.2 改成 0。
  - 調完後，每隻都在原本的 ±0.05 以內。
  - （commit 027d078；DUEL_AI_V2）
- **下次怎麼做**：
  - 把 NORMAL 對 NORMAL 的勝率差放進評分器，當作硬門檻（例如和原版差超過 0.05 就是 0 分）。
  - brief 裡寫明：每一步都會擲的機率，要用「每秒觸發幾次」來想，不能看單次機率。

### 5.6 cell 繞過了 `AI-AWAKEN-P`

- **現象**：
  - 千手丸的晚覺醒（`SENJU-AWAKEN`）沒有走 `AI-AWAKEN-P`。
  - 結果覺醒 A/B 測試裡「永不覺醒」那幾列還是會覺醒，SR 只有 21／24／18 勝（門檻 20）。
  - （DUEL_AI_V2 "Two fixes"；DEVLOG §77）
- **原因**：
  - brief 沒有列出哪些除錯用的開關必須遵守。
  - aieval 也沒有跑 A/B。
  - `WS/senjumaru/rounds/round02/nodes/b0a0/senjumaru.lisp` 裡完全沒有 `ai-awaken-p`。
- **處理**：整合時改成走 `AI-AWAKEN-P`，SR 變成 23／28／20。（commit 5948aad）
- **下次怎麼做**：
  - brief 列出 gate 依賴的鉤子（`AI-AWAKEN-P`、debug 模式），要求 cell 遵守。
  - 碰到覺醒的 cell，交回前自己跑一次 A/B。

### 5.7 學習型 AI 被角色反射擋掉

- **現象**：換上新檔、其他什麼都不改的情況下：
  - HARD 學習型 AI 的讀心次數下降：劍八 606 → 348、千手丸 452 → 240。
  - 讀中的次數也下降：劍八 172 → 66、千手丸 137 → 48。
  - （DUEL_AI_V2「The learning CPU and the new AIs」）
- **原因**：
  - 新的角色反射會在中立決策那一幀把決策搶走：重設 `brain-decide-t`，自己出招。
  - 或者每一步都回 `:wait`（例如劍八的走近）。
  - 這樣 `AI-DECIDE` 裡的 `LEARN-NEUTRAL` 就沒有機會跑。
- **處理**：
  - 讀心改用自己的時鐘，在 `AI-REFLEX` 裡、角色的 `:reflex` 之前執行（`LEARN-READ-DUE`）。只改了 ai.lisp。
  - 修正後讀心頻率回來了。不過在 HARD，劍八和露琪亞開學習反而輸得更多（34 → 22、38 → 29）。§77 把這點留給使用者決定，之後的 DEVLOG 沒看到結論。
  - （commit abe18b4；DUEL_AI_V2）
- **下次怎麼做**：在 brief 裡說明共用系統的接點：學習型 AI 在哪裡讀、ASSIST 會借用哪些鉤子。cell 交回前，用學習型 AI 的 gate 量一次。

### 5.8 ASSIST 拿不到新的 `:sp-ender`

- **現象**：一護 cell 的 `:sp-ender` 在沒有 brain 時回傳 NIL。人類玩家開 AUTO COMBO 時，用的是 ASSIST 借來的 brain，所以拿不到新的接續。千手丸的版本則會在 `SENJU-DP` 碰到 NIL。
- **出處**：transcript（一護 b0a0 回報「returns NIL without a brain, because the ASSIST calls string-reflex」）；DUEL_AI_V2「The ASSIST auto mode」。
- **處理**：角色的 CPU 程式改讀 `AI-BRAIN`，ASSIST 執行時就是借來的 HARD brain。（commit ff7127f）
- **下次怎麼做**：brief 要寫明「這些鉤子也會在 ASSIST 裡、用借來的 brain 被呼叫」。

### 5.9 signature 指標有漏洞，權重決定了搜尋往哪走

- **現象**：
  - 露琪亞 b0a0 自己的 Breaker 佔了她 27% 的傷害，而這也算進 signature。（transcript 露琪亞 b0a0 回報）
  - 山本 r2 想用火焰招式換掉 J／K 連段，量下來每少 1 分 strength 只換到 1.3～2.2 分 signature。在 0.6／0.2 的權重下要 3：1 才划算，所以分數下降。（transcript 山本 r2 回報）
- **原因**：aieval 把「不是 J／K 連段的任何傷害」都算成角色特色。
- **處理**：沒有改評分器，用使用者給的權重照實選。
- **下次怎麼做**：開跑前列出真正算「招牌」的招式（白名單），不要用「不是 J／K」這種否定式定義。權重要先跟使用者確認，讓他知道這組權重會讓搜尋往哪邊偏。

### 5.10 dreaming（compare／promote）在這個預算下幾乎沒有作用

- **現象**：`proposal_results/compare.json` 只比了 skill 內建的兩個策略。

  | 角色 | adaptive auc | baseline auc | parallel_penalty |
  |---|---|---|---|
  | 山本 | 0.923 | 0.899 | 1.0／1.0 |
  | 劍八 | 0.945 | 0.932 | 1.0／1.0 |
  | 露琪亞 | 0.831 | 0.801 | 1.0／1.0 |
  | 千手丸 | 0.720 | 0.640 | 1.0／1.0 |

- **原因**：
  - `workers=1`，所以 parallel_penalty 兩邊都是 1.0。reward = auc − 0.25，排名就只剩 auc 的排名。
  - 每個角色只有一個回放世界（`trace_pool/iter01`），也就是 round 1 的 4 格。
  - 沒有照 skill 的建議手寫 3～5 個修訂版：`policy/history/` 只有 `r0001_adaptive_template.py` 和 `r0001_previous.py`，`current.py` 就是 template 原樣。
  - round 2 只跑了 1 格，而 promote 後的策略讓這一格開新 branch（parent 是 None）。協調者在 prompt 裡改成「從 round 1 的最佳檔出發」，所以實際跑什麼不是策略決定的。（round 2 的 brief 都寫著 `PARENT_DIR = (none ...)`；transcript 07:16 的派發 prompt）
- **處理**：無。實際有用的是任務書的結構和協調者的判斷，不是回放。
- **下次怎麼做**：見 §6。如果真的要用 dreaming，W 要大於 1，每角色至少 3 輪、每輪 8 格以上，每輪寫幾個策略修訂版來 compare。

### 5.11 round 2 的方向是協調者用文字指定的

- **現象**：
  - round 2 的 prompt 直接寫了方向，例如劍八是「在不減少勝場的前提下提高招牌比例」，露琪亞是「增加冰溫帶、絕對零度的招牌運用」。
  - 五個角色 round 1 的 b0a1 也都在 prompt 裡寫明「可以合併 b1a0 不重疊的部分」。
  - （transcript round 1／2 派發 prompt）
- **和 skill 的說法對照**：skill 引論文 §5.1，說用文字給 agent「搜尋方向」反而讓兩組都變差，建議 `set-direction` 保持簡短、結構性。這次沒有對照組，看不出有沒有傷害。
- **下次怎麼做**：方向提示只寫結構（例如「開新方向」「在 parent 上改進」「可合併某格」），具體的想法讓 cell 自己從歷史裡讀出來。

### 5.12 其他流程上的事

- **一護的節奏貼著邊**：搜尋時一護對露琪亞的 NORMAL 中位數是 205.2 秒（門檻 220）。整合時用 40 場量，有 1 場打到時間到，所以分數是 0。正式的 seed gate（20 場、210 秒）IR 全部 K.O.，中位數 206.2 秒。（score.json；DUEL_AI_V2）→ 下次節奏離門檻 15 秒以內的 cell 要標成風險。
- **中途的通知很吵**：有些 agent 自己開了背景工作，回報前會一直送出「interim」通知。劍八 b0a1 在約 21 分鐘裡送了 8 次。（transcript）→ 只等 SubagentHandback，不用每次都回應。
- **用量上限**：碰到兩次。背景 subagent 會繼續跑，結果留在 NODE_DIR 或它的 worktree，額度恢復後用 `step.sh` 收。（transcript）
- **原生建置看 mtime**：06:22 之後派發的 prompt（含 round 2 和整合）都要求每次 eval 前 `touch` 一下角色檔，避免拿到舊的建置。（transcript）

---

## 6. 評估：這次值不值得用 dream-rsi

**skill 自己的說法**（`$DREAM_RSI/SKILL.md`、`references/paper-digest.md`）

- 預算要大（幾百次 agent 呼叫），要跑好幾輪，分數要能用程式算。
- round 1 和固定策略完全一樣，從 round 2 才開始有差別。
- 效益是「用更少的呼叫達到差不多或稍好的品質」（論文裡少 1.7～2.4 倍），不是更高的上限。
- 它的前提是評分器固定不變。

**這次的實際情況**

- 共 23 格，每角色 3～5 格，只有一個回放世界，W = 1。評分器中途改過一次，對手組和最後上線的也不一樣。這幾項都落在 skill 說「不值得」的那一邊。
- 真正有用的東西都和 dream-rsi 的回放無關：
  - **任務書的結構**：先讀完整歷史，相信量到的分數而不是 proposal 的說法，只改一個檔，依難度分層。
  - **「新方向／改進並合併」的兩種格子**：最好的版本都來自合併。
  - **協調者一律重量後再記錄**。
  - **每格留下 proposal.md**：整合時直接拿來寫 DUEL_AI_V2 的行動方針，以及共用程式的建議表。
- 結論：在這個專案、這種規模下，用「每角色一個 subagent、照同一份任務書跑固定的 branch／refine 網格、協調者重量並記錄」就夠了。`drsi.py` 的 record／next-batch 只是記帳工具，compare／promote 沒有發揮作用。（§5.10）

**什麼情況才值得開 dreaming**

- 同一個評分器、同一組對手，可以跑 3 輪以上，每輪 8 格以上。
- W ≥ 2（同一個任務同時跑好幾格），parallel_penalty 才有意義。
- 分數的雜訊比變體間的差距小，或是已經用固定 seed、足夠場數壓下來。
- 每輪願意花時間寫幾個策略修訂版來 compare。

---

## 7. 下次的檢查清單

**開跑前**

- [ ] 評分器先寫好、驗證、凍結。用 baseline 加一兩個手寫變體跑一遍，檢查內戰、座位、笨玩家這類邊角。記下評分器的 commit。
- [ ] 用凍結後的同一版評分器重量 baseline，整份 JSON 一起寫進 `baseline/score.json` 和 `init --baseline-score`。
- [ ] 固定搜尋時的對手組（例如「main 某個 commit 的另外四隻」），寫進 task 說明。決定好之後要不要在 round 之間換成各角色的最佳版本。
- [ ] 固定 seed；決定 cell 內比較用的場數（≥ 40）和選檔用的場數（80）。
- [ ] 評分器裡加入 NORMAL 對 NORMAL 的勝率差當門檻；節奏離門檻太近要標成風險。
- [ ] 「招牌」用白名單定義；權重和使用者確認過。
- [ ] 問使用者：評分、每輪預算、輪數、平行數。輪數少於 3、或總格數不到幾十，就直接說「不跑 dreaming，只用網格加記帳」。
- [ ] brief 列出必須遵守的共用接點：`AI-AWAKEN-P`／debug 模式、學習型 AI 的讀心位置、ASSIST 借 brain 呼叫的鉤子。
- [ ] 交付物寫在 agent 自己 worktree 裡的固定相對路徑，由協調者複製。

**每個 cell**

- [ ] 用 `step.sh` 收：複製、重量、`record`（記重量後的分數和真實的 `--fail-class`），然後開下一格。
- [ ] cell 自己交回前要過 rules test，NORMAL 要和原版比過，碰到覺醒的要跑 A/B。
- [ ] 回報只看 SubagentHandback；interim 通知不用處理。
- [ ] 分數差在雜訊範圍內（20 場約 ±0.03）時，不要當成真的變好。

**整合時**

- [ ] 候選用 80 場、同一組 seed 比較。
- [ ] 五個新檔一起換上之後，量每隻對新的一組的 HARD 分數（只記錄，不設目標）。
- [ ] NORMAL 對 NORMAL 的勝率，每隻都要在原版的 ±0.05 以內。
- [ ] 跑完整 gate：
  - `tools/simgate.py` 15 組全部 K.O.，跨角色 20 場中位數 ≤ 210 秒；超過的用 60 場確認。
  - 覺醒 A/B：streams 100／300／500，每列 ≥ 20／60。
  - `tools/assistgate.py`（k0／k2／k11，再加 `--p2-dumb 1`）。
  - 學習型 AI 的 gate（habit 1–4，m0／m1）。
  - host 測試：rules、control、learn、input。
  - `./build.sh duel`，0 個警告。
  - G2：`tests/style-gates.py cvc dist/duel` 跑完後更新 `tests/style-cvc-ref.txt`，`simgate.py --cvc` 要 PASS。
- [ ] 把 cell 的共用程式建議整理成表，標明做了哪些。（DUEL_AI_V2 最後一節就是這樣做的）

---

## 8. 檔案地圖（`docs/research/ai-v2-drsi/`）

```
docs/research/ai-v2-drsi/
├── brief.py              一格的任務書產生器（skill 的 exploration prompt + 專案說明）
├── step.sh               一格結束：複製 → rescore → record → next-batch → 下一格的 brief
├── rescore.sh            在 .claude/worktrees/rescore-<角色> 用目前的 aieval 重量一個檔
├── integration.brief.md  整合 subagent 的六步任務書
├── rk-next.json          露琪亞 r1 b1a0 的 work order（還沒有 step.sh 時手動存的，可忽略）
└── <角色>/               yamamoto kenpachi rukia ichigo senjumaru
    ├── config.json       drsi init 的設定：task、eval_command、baseline_score（修正後）、workers=1、2×2 網格、λ
    ├── baseline/
    │   ├── <檔>.lisp     出發時的角色檔（main 0462476 時的版本）
    │   ├── proposal.md   原版 AI 的說明
    │   └── score.json    修正後重量的 baseline（只有 score 欄位是新的，見 §5.1）
    ├── rounds/round0N/
    │   ├── trace.json    該輪每格的分數、fail_class、seq（round 1 的 baseline_score 是修正前的值）
    │   └── nodes/
    │       ├── <cell>.brief.md      這格的任務書（裡面的路徑還是 research_notes/）
    │       └── <cell>/
    │           ├── <檔>.lisp            這格交回的角色檔
    │           ├── proposal.md          行動方針、機制、依據、量測、風險、共用程式建議
    │           ├── score.json           agent 自己量的最後一行 JSON
    │           └── score.rescored.json  協調者用修正後的 aieval 重量的結果（記錄到 drsi 的是這個）
    ├── policy/
    │   ├── current.py    目前的分配策略（promote 後就是 adaptive_template 原樣）
    │   └── history/      r0001_previous.py（baseline_parallel_refine）、r0001_adaptive_template.py
    ├── trace_pool/iter01/ close-round 1 凍結的回放世界（trace.json + live_cycle_manifest.json）
    └── proposal_results/compare.json  round 1 後的策略比較（auc、parallel_penalty、reward）
```

- **空的 cell 目錄**：`nodes/` 底下有些格子只有 brief 或空目錄（r1 b1a1、r2 b1a0、一護 r1 b0a2）。那是 `next-batch` 開了但沒有派出去的格子。
- **一護**：只有 round 1，沒有 `trace_pool/` 和 `compare.json`。
- **相關文件**：
  - `docs/duel/DUEL_AI_V2.md`：每角色上線的行動方針、分數、NORMAL 表、學習型 AI 與 ASSIST 的整合、gate、共用程式建議。
  - `docs/DEVLOG.zh-TW.md` §77：使用者的原話、決定、量測。
  - `docs/guides/PLAYBOOK.zh-TW.md`：整個專案的開發方法。這份筆記是它在 AI 搜尋這一塊的補充。
- **重用腳本前**：搬家時，腳本和 `integration.brief.md` 裡的路徑已經改成 `docs/research/ai-v2-drsi/` 和 `docs/duel/`，但各格已經產生的 `<cell>.brief.md` 裡還是舊的 `research_notes/` 路徑。`brief.py`、`rescore.sh`、`step.sh` 都寫死了 repo 的絕對路徑（`brief.py` 還寫死了 ECL 的路徑）。`step.sh` 用 `$DREAM_RSI` 找 skill，沒設定時預設是 `~/.claude/skills/dream-rsi`。

---

## 9. 無法確認的部分

- 整合時劍八兩個候選在 80 場的分數（0.749、0.747），比劍八 r2 cell 自己量的 80 場（0.853）低很多。推測是因為量的時候另外四隻已經換成新檔，但 transcript 裡沒有明確寫出量測條件。
- HARD 學習型 AI 讓劍八和露琪亞輸更多這件事，§77 寫「留給使用者決定」，之後的紀錄裡沒找到結論。
