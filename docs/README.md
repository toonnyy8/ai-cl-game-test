# 文件索引

專案總覽、快速開始和建置需求在根目錄的 [README.md](../README.md)。第一次接觸這個專案，先讀 [TUTORIAL.zh-TW.md](TUTORIAL.zh-TW.md)。技術參考文件大多是英文，是開發時各模組之間的「合約」；中文的開發紀錄說明這些決定背後的理由。

| 文件 | 內容 |
|---|---|
| [TUTORIAL.zh-TW.md](TUTORIAL.zh-TW.md) | 學習路徑：建置與執行、專案地圖、逐行讀 `examples/hello`、幀迴圈與 GC、ECS、純函式規則、事件、算圖、RAVEN EDGE 的組成、SOUL DUEL 的組成（虛擬手把、角色即資料、同時結算、過場導演、決定性）、練習題（中文） |
| [DEVLOG.zh-TW.md](DEVLOG.zh-TW.md) | 開發紀錄與技術思辨：從 GLES3 到 SDL_GPU（WebGPU）、建置管線、GC 問題、ECL 效能、算圖、音訊、玩法設計、團隊分工、已知限制、引擎／遊戲拆分與 ECS 重構、用第二款遊戲驗證引擎（中文） |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 建置管線、執行模型、GC 規則、ECS／規則／事件、模組分工表，以及一長串 ECL／Emscripten／WebGPU 踩過的坑 |
| [ENGINE_API.md](ENGINE_API.md) | 引擎 API 參考（依原始檔分組）：座標慣例、輸入與虛擬手把、數學、命中判定、算圖、模型產生、UI、音訊、動畫、剛體角色、時間、過場導演、特效、ECS、`RUN-GAME` |
| [GAME_DESIGN.md](GAME_DESIGN.md) | RAVEN EDGE 的設計規格 v1：操作、招式幀數表、戰鬥規則、敵人、波次、HUD、美術、音效對照、動畫 |
| [DUEL_DESIGN.md](DUEL_DESIGN.md) | SOUL DUEL 的設計（照實作）：與 RoS 的差異、規則、操作、共通機制、兩個角色的招式表、AI、流程、開發中改過的決定 |
| [DUEL_NOZARASHI_V2.md](DUEL_NOZARASHI_V2.md) | 劍八野晒形態的重新設計 v2「呑め」三杯梯（已決定、尚未實作），含西式「按住 U＝鎧甲」與移除 `:ignore-armor` |
| [DUEL_MOBILE_DESIGN.md](DUEL_MOBILE_DESIGN.md) | 單手（片手）直式手機模式的設計 v2（已決定、尚未實作）：預設右手、FULL 輔助不打折、不做本機直式雙人、日後藍牙／Wi-Fi 對戰 |
| [DUEL_GAMEPLAY.md](DUEL_GAMEPLAY.md) | SOUL DUEL 的建置與操作、時間模型、除錯指令、log、測試腳本、決定性檢查、節奏測試結果、效能、主機測試 |
| [GAMEPLAY.md](GAMEPLAY.md) | RAVEN EDGE 玩法系統的實作說明：時間模型、實體與元件、動畫、招式定義、敵人 AI、遊戲流程、除錯指令、砍掉的項目 |
| [WORLD.md](WORLD.md) | 頂樓場景：API、碰撞體、場景內容、光源配置、雨、效能數據 |
| [AUDIO.md](AUDIO.md) | 音訊：Lisp API、C 混音器設計、瀏覽器自動播放處理、合成工具、音效清單 |
| [STYLE_STORM_RESEARCH.md](STYLE_STORM_RESEARCH.md) | 《究極風暴》畫風解析，加上久保帶人畫風與千年血戰篇動畫的研究：角色著色、墨線、手繪式特效、鏡頭、舞台，附來源與可信度標記（英文，開頭有中文摘要） |
| [STYLE_STORM_DESIGN.md](STYLE_STORM_DESIGN.md) | SOUL DUEL 改成《究極風暴》畫風的設計 v4（究極風暴技術 × 久保帶人的黑白語言）：引擎算圖改動、特效系統、各招式重新設計、奧義鏡頭、舞台、預算、分階段計畫與驗收、辯論紀錄（英文，開頭有中文摘要與待決事項） |
| [research/ng4-notes.md](research/ng4-notes.md) | 《忍者外傳 4》玩法研究筆記，附來源和可信度標記 |
| [world-shots/](world-shots/) | 場景 demo 的截圖（出生點、各角落、俯視、水窪、頭目戰的血雨） |
