# 文件索引

專案總覽、快速開始和建置需求在根目錄的 [README.md](../README.md)；給 AI agent 的專案總覽與工作規則在 [AGENTS.md](../AGENTS.md)。第一次接觸這個專案，先讀 [guides/TUTORIAL.zh-TW.md](guides/TUTORIAL.zh-TW.md)。技術參考文件大多是英文，是開發時各模組之間的「合約」；中文的開發紀錄說明這些決定背後的理由。

Claude skill 在 repo 根目錄的 `skills/`（連結到 `~/.claude/skills/`），對應 [guides/PLAYBOOK.zh-TW.md](guides/PLAYBOOK.zh-TW.md)。

## 入門與經驗

| 文件 | 內容 |
|---|---|
| [TUTORIAL.zh-TW.md](guides/TUTORIAL.zh-TW.md) | 學習路徑：建置與執行、專案地圖、逐行讀 `examples/hello`、幀迴圈與 GC、ECS、純函式規則、事件、算圖、RAVEN EDGE 的組成、SOUL DUEL 的組成（虛擬手把、角色即資料、同時結算、過場導演、決定性）、練習題（中文） |
| [PLAYBOOK.zh-TW.md](guides/PLAYBOOK.zh-TW.md) | 遊戲開發經驗手冊：引擎與工具鏈、模擬與平衡測試、美術與演出風格、開發流程與協作、新遊戲啟動清單；對應 repo 裡 `skills/` 的六個 Claude skill（中文） |
| [CHARACTER_DESIGN.zh-TW.md](guides/CHARACTER_DESIGN.zh-TW.md) | 角色設計與開發手冊（以利傑·巴羅為範本）：開工前必須先確認的設計意圖（⚠ 清單與每項的代價）、流程、建模注意事項、動作模組要點、玩法系統規劃、平衡、演出與過場、多 agent 分工、新角色提問單；對應 skill `duel-character`、`duel-character-rework`（中文） |
| [DREAM_RSI.zh-TW.md](guides/DREAM_RSI.zh-TW.md) | 用 dream-rsi 搜尋每個角色 CPU AI 的經驗筆記：設定、流程與分數、踩到的問題、下次的檢查清單（中文） |
| [DEVLOG.zh-TW.md](DEVLOG.zh-TW.md) | 開發紀錄與技術思辨：從 GLES3 到 SDL_GPU（WebGPU）、建置管線、GC 問題、ECL 效能、算圖、音訊、玩法設計、團隊分工、已知限制、引擎／遊戲拆分與 ECS 重構、用第二款遊戲驗證引擎（中文） |

## 引擎（`engine/`）

| 文件 | 內容 |
|---|---|
| [ARCHITECTURE.md](engine/ARCHITECTURE.md) | 建置管線、執行模型、GC 規則、ECS／規則／事件、模組分工表，以及一長串 ECL／Emscripten／WebGPU 踩過的坑 |
| [ENGINE_API.md](engine/ENGINE_API.md) | 引擎 API 參考（依原始檔分組）：座標慣例、輸入與虛擬手把、數學、命中判定、算圖、模型產生、UI、音訊、動畫、剛體角色、時間、過場導演、特效、ECS、`RUN-GAME` |
| [AUDIO.md](engine/AUDIO.md) | 音訊：Lisp API、C 混音器設計、瀏覽器自動播放處理、合成工具、音效清單 |
| [REFACTOR_2026-10.md](engine/REFACTOR_2026-10.md) | 2026-10 的重構：精簡、抽象化、搬進引擎的元件；66 個候選項的判定、確定性規則、各批結果與延後清單 |
| [REFACTOR_NEXT.md](engine/REFACTOR_NEXT.md) | 下一輪重構的待辦清單（N1–N7）：`defdebug`、HUD 每幀配置、`hud-text` 快取、千手丸 `defun-fast`、`gate.lisp` 拆檔、`toon-ground-seg` 搬進引擎等，各附先量什麼與完成條件 |
| [WORLD.md](engine/WORLD.md) | 頂樓場景：API、碰撞體、場景內容、光源配置、雨、效能數據 |
| [world-shots/](engine/world-shots/) | 場景 demo 的截圖（出生點、各角落、俯視、水窪、頭目戰的血雨） |

## RAVEN EDGE（`raven-edge/`）

| 文件 | 內容 |
|---|---|
| [GAME_DESIGN.md](raven-edge/GAME_DESIGN.md) | RAVEN EDGE 的設計規格 v1：操作、招式幀數表、戰鬥規則、敵人、波次、HUD、美術、音效對照、動畫 |
| [GAMEPLAY.md](raven-edge/GAMEPLAY.md) | RAVEN EDGE 玩法系統的實作說明：時間模型、實體與元件、動畫、招式定義、敵人 AI、遊戲流程、除錯指令、砍掉的項目 |

## SOUL DUEL（`duel/`）

| 文件 | 內容 |
|---|---|
| [DUEL_DESIGN.md](duel/DUEL_DESIGN.md) | SOUL DUEL 的設計（照實作）：與 RoS 的差異、規則、操作、共通機制、兩個角色的招式表、AI、流程、開發中改過的決定 |
| [DUEL_GAMEPLAY.md](duel/DUEL_GAMEPLAY.md) | SOUL DUEL 的建置與操作、時間模型、除錯指令、log、測試腳本、決定性檢查、節奏測試結果、效能、主機測試 |
| [DUEL_STRINGS.md](duel/DUEL_STRINGS.md) | J／K 連段、O 收尾與「攻勢」KŌSEI（2026-09-27，已實作）：最多三段、J／K 只能切換一次、接觸閘門、揮空硬直、幀數預算、O 收尾只接在打中的第 3 段之後、進攻獎勵的公式、AI 調整、使用者的決定、實作偏離之處與節奏測試結果（英文） |
| [DUEL_YAMA_REWORK.md](duel/DUEL_YAMA_REWORK.md) | 山本卍解重製（2026-09-27，已實作）：U 從『東・旭日刃』切到『西・殘日獄衣』、東的穿透、西的全方位霸體防禦、新 L 技旭光／焦熱地獄、使用者的決定與實作偏離之處（英文） |
| [DUEL_NOZARASHI_V2.md](duel/DUEL_NOZARASHI_V2.md) | 劍八野晒形態的重新設計 v2「呑め」三杯梯（已實作），含西式「按住 U＝鎧甲」與移除 `:ignore-armor`；三杯之後的卍解見 DUEL_KEN_BANKAI.md |
| [DUEL_KEN_BANKAI.md](duel/DUEL_KEN_BANKAI.md) | 劍八卍解（第二次覺醒）與片腕（2026-09-28，已實作）：三杯紅血按 P、魂魄變 1 且 HP 回滿、「腕」4 格與爆裂、卍解招式表（咬、盾ごと、殴り飛ばし、真っ二つ）、片腕、過場、HUD、AI 的進入規則、使用者的決定、實作偏離之處、節奏測試與「必開／不開」A/B（英文）。同時記錄 Soul Break 的新規則（播攻擊方的毀魂技動畫、上限 5） |
| [DUEL_KEN_REWORK.md](duel/DUEL_KEN_REWORK.md) | 劍八動作與造型重做（2026-10-08，討論中）：現況診斷、研究摘要、待決問題（英文） |
| [DUEL_RUKIA.md](duel/DUEL_RUKIA.md) | 朽木露琪亞（血戰篇）：袖白雪與絶対零度的設計與實作（英文） |
| [DUEL_ICHIGO.md](duel/DUEL_ICHIGO.md) | 黑崎一護（血戰篇）：二刀斬月與血鎖の一護，含試玩後的 v2 重新設計（英文） |
| [DUEL_SENJUMARU.md](duel/DUEL_SENJUMARU.md) | 修多羅千手丸：刺絡與卍解娑闥迦羅骸刺絡辻的設計與實作（英文） |
| [DUEL_LILLE.md](duel/DUEL_LILLE.md) | 利傑巴羅（2026-10-06 起，討論中）：純遠距狙擊、萬物貫通穿防、覺醒 Jilliel 的無實體架式，使用者的決定與待決問題（英文） |
| [DUEL_AI_V2.md](duel/DUEL_AI_V2.md) | 每個角色的 AI v2（2026-10-02，已實作）：dream-rsi 搜尋、選用的變體、各角色行動方針、NORMAL 校正、與學習型 AI 和 ASSIST 的整合、gate 結果（英文） |
| [DUEL_LEARNING.md](duel/DUEL_LEARNING.md) | 學習型 CPU：從對戰中學玩家習慣的讀心與反制、學習 gate（英文） |
| [DUEL_ASSIST.md](duel/DUEL_ASSIST.md) | ASSIST：AUTO GUARD／AUTO COMBO／AUTO BREAK 輔助模式與它的代價、assistgate（英文） |
| [DUEL_ENDLESS.md](duel/DUEL_ENDLESS.md) | ENDLESS 無限連戰：CPU 關卡、規則與 gate（英文） |
| [DUEL_MOBILE_DESIGN.md](duel/DUEL_MOBILE_DESIGN.md) | 單手（片手）直式手機模式的設計 v2：預設右手、FULL 輔助不打折、不做本機直式雙人、日後藍牙／Wi-Fi 對戰；§12 是 2026-09-26 已做好的簡單版（P0 + PWA）與偏離之處 |

## 畫風（`style/`）

| 文件 | 內容 |
|---|---|
| [STYLE_STORM_RESEARCH.md](style/STYLE_STORM_RESEARCH.md) | 《究極風暴》畫風解析，加上久保帶人畫風與千年血戰篇動畫的研究：角色著色、墨線、手繪式特效、鏡頭、舞台，附來源與可信度標記（英文，開頭有中文摘要） |
| [STYLE_STORM_DESIGN.md](style/STYLE_STORM_DESIGN.md) | SOUL DUEL 改成《究極風暴》畫風的設計 v4（究極風暴技術 × 久保帶人的黑白語言）：引擎算圖改動、特效系統、各招式重新設計、奧義鏡頭、舞台、預算、分階段計畫與驗收、辯論紀錄（英文，開頭有中文摘要與待決事項） |

## Babylon 移植版（`babylon/`，已停止）

| 文件 | 內容 |
|---|---|
| [BABYLON_PORT.md](babylon/BABYLON_PORT.md) | Babylon.js + TypeScript 移植版的計畫與狀態（2026-10-06 起不再開發）（英文） |
| [BABYLON_LOOK.md](babylon/BABYLON_LOOK.md) | Babylon 版的畫面規格 M5 B2–B5（不再開發）（英文） |

## 研究（`research/`）

| 文件 | 內容 |
|---|---|
| [ng4-notes.md](research/ng4-notes.md) | 《忍者外傳 4》玩法研究筆記，附來源和可信度標記 |
| [tybw-characters/report.zh-TW.md](research/tybw-characters/report.zh-TW.md) | 血戰篇四角色（劍八卍解、二刀一護、露琪亞、千手丸）的格鬥設計研究報告，附來源；`notes/` 是各角色的研究筆記（英文；`lille_barro.md` 是利傑巴羅，2026-10-06） |
| [ai-v2-drsi/](research/ai-v2-drsi/) | AI v2 的 dream-rsi 工作區：五個角色的 baseline、兩輪 cell（brief、proposal、lisp、分數）、policy 與 trace，加上 coordinator 腳本（`brief.py`、`step.sh`、`rescore.sh`） |
| [lille-retrospective/digest.md](research/lille-retrospective/digest.md) | 利傑巴羅的設計回顧摘要：56 個決定的時間線、10 條重工鏈與各自該先問的問題、做對的流程／設計／技術模式、建模與系統筆記、數字（英文，2026-10-08） |
| [kenpachi-rework/](research/kenpachi-rework/) | 劍八重做的研究：`canon-looks.md` 各型態的原作外觀與建模清單，`motion-refs.md` 各場戰鬥的打法、遊戲參考與三個型態的招式動作清單（英文，附來源與可信度，2026-10-08） |
| [lille-ai-drsi/](research/lille-ai-drsi/) | 利傑巴羅自適應 AI 的 dream-rsi 工作區（DUEL_LILLE §24）：凍結的 baseline（lille.lisp、proposal、40／80 場分數、NORMAL 漂移參考值）、drsi 設定與 policy，加上 coordinator 腳本（`brief.py`、`step.sh`、`rescore.sh`）；見其 README |
