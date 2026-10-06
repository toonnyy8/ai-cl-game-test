# D. Development workflow, collaboration and game-design principles

Source repo: /media/8tsp/projects/ai-cl-game-test (RAVEN EDGE + SOUL DUEL, Lisp→wasm). Evidence paths are repo-relative
unless they start with `~/.claude` (auto-memory). "G" = generalizable, "P" = project-specific.

---------------------------------------------------------------------------------------------------------------------
## 1. The per-change loop

### 1.1 The loop as practised (G)
1. **User request, quoted verbatim.** Requests are short zh-TW lines, often several in a burst ("幫我將 J 的攻擊距離延長到至少 1.4"
   → "然後 break 也進行對應的延伸" → "我接受這個節奏"). Every one is recorded word for word (DEVLOG §81, STRINGS §20).
2. **Clarify only what changes the design, and offer a recommended default.**
   - Big features: the design doc ends with "Questions for the user (each with the recommended default)", bilingual,
     e.g. DUEL_SENJUMARU §14: 6 questions, each with "建議：是。" and an English line with **Default: yes**. The user
     usually takes the defaults and overrides one or two ("Questions 1–6: the recommended defaults" + 2 changes).
   - Small features: 2–3 options, then the user's pick goes in the log: DEVLOG §71 "在三個方案裡選了「J 被擋也能轉防禦」和
     「擋下 J 後更快能出招」，沒有選「J 被擋少扣量表」"; §75 "使用者的選擇" bullets; §70 asks a yes/no scope question first
     ("目前我方 AI 的行為會將 sp1 sp2 都也涵蓋進去嗎？" → answered what exists → "加！").
   - The research report fixes the user's wrong premises before designing (docs/research/tybw-characters/report.zh-TW.md "先更正四個前提": two names,
     one source, one plot detail), politely, in a table: claim / verified fact / design impact.
3. **Implement** in the smallest place (character files first; shared files get only generic hook points, §4.6).
4. **Tests + gates** (§1.3): host unit tests, build with 0 warnings, determinism refs, seed gate, A/B, scripted browser.
5. **Docs in the same pass** (§2): design doc section (EN), DEVLOG section (zh-TW), DUEL_DESIGN as-built line, manual
   (zh-TW) if player-facing, TUTORIAL/GAMEPLAY quote lines if the reference match changed. Example: commit 590f099
   touched DEVLOG, DUEL_DESIGN, DUEL_GAMEPLAY, DUEL_STRINGS, TUTORIAL, ai.lisp, tuning.lisp, manual.html,
   tests/scripts/duel.py, tests/style-cvc-ref.txt: code is 2 of 10 files.
6. **Commit + push at each gated milestone** without asking (~/.claude/.../feedback-autocommit.md, the user 2026-09-28:
   「你以後每實作一個進度就可以自行 commit & push，甚至依據需求開 branch 與 worktree」). Never commit a half-finished batch.
7. **Deploy only when the user says so** (feedback-pages-deploy.md, 2026-09-30: 「以後等我說完後才統一更新 github page」).
   Reply template: "已推送 main；GitHub Pages 等你說完再一起更新". Deploy = `tools/deploy-pages.sh` (dist → orphan gh-pages
   worktree, one commit "Deploy SOUL DUEL from main <rev>").
8. **Rebuild what the user actually runs before handing off** (feedback-rebuild-dist.md): the native sim build passed,
   but the phone ran a stale wasm → "The function VPAD-INDEX is undefined". Rule: the last build before commit/report is
   the shipping build; check the artifact is newer than every edited source.

### 1.2 Commit message conventions (G pattern, P content)
- One long descriptive subject line (often 200+ chars) = the whole change in prose: what rule, the knobs with old → new
  values, "(the user, YYYY-MM-DD)" attribution, the gate numbers, and the doc sections: e.g. 590f099 "The CPU learns
  Step -> J (the user, 2026-10-02): … (*ai-step-in-p* .05/.12/.25) … 15 pairings K.O., YK 60 seeds 131.3 s, A/B >= 23,
  masher vs HARD 3 %; G2 refreshed; DUEL_STRINGS §19, DEVLOG §80".
- Later commits move detail to a body paragraph and keep the subject shorter (c1f5ca0). Doc-only commits name the doc:
  "BABYLON_PORT: …", "DUEL_STRINGS §20 / DEVLOG §81: YK 119.5 s accepted (the user, 2026-10-06)".
- Scope caveats in the subject: "(Lisp only, the TS sim not mirrored yet)".
- "Fix:" prefix for bugs, with the user's report named ("(the user's report)").
- Parallel batches: "Babylon port M5 b3rukia (look batch; see docs/babylon/BABYLON_PORT.md Status)" and "Merge main into
  babylon-<batch>" commits, each merge message stating what was reconciled and the post-merge gate.
- Trailers: `Co-Authored-By: …` + `Claude-Session: …` on every commit (also put in subagent briefs).
- Recommendation: keep "who decided + date + gate numbers + doc § refs" in commits; move long prose to the body.

### 1.3 Gates: what "done" means (G idea, P instances)
- Layered: pure-rule host tests (tests/duel-rules-test.lisp grew 2589 → 4433 checks), build with 0 warnings, a package
  checker for undefined functions, a "character-name check" (shared files must contain no character names), G1/G2
  bit-exact reference logs (tests/style-cvc-ref.txt: rewrite on purpose, quote the new line in docs), a statistical
  **seed gate** (CPU vs CPU, all K.O., median 125–210 s), an **awaken A/B** (≥ 20/60 on 3 streams), a **masher/"dumb
  player" gate** for the CPU and assist (tools/assistgate.py), headless browser scripts with screenshots.
- **Gate cost is a design problem.** With 5 characters the browser gate took ~1 h (each Chrome ~6 cores). Fixes:
  gate policy (feedback-gate-policy.md: only affected pairings; 10 seeds first, 20 only if near the window edge) and a
  headless native sim runner built from the *same* sources (DEVLOG §38: 300 matches in 14 s vs ~1 h), validated
  line-by-line against the browser (found libm last-bit differences → preloaded the same musl; 2693/2693 lines equal).
- **Statistics discipline**: one 60-seed stream overfits ("every extra CPU roll reshuffles a whole match … ±15"), so
  A/B uses 3 independent streams (DUEL_DESIGN "Awakening balance target"); a borderline median is rerun at 60 seeds
  before acting (DEVLOG §80: YK 124.4 → 131.3 at 60).
- The user may waive gates: "內戰的數據超時沒關係" (mirrors may exceed 210 s), "劍八那邊就這樣給過即可" (YK 121.1 accepted),
  "我接受這個節奏". Each waiver is recorded as a rule in the gate policy, not just accepted once.
- A user's "不用再做測試" is obeyed for the decision, but a cheap check was still run and the result reported (§1.5).

### 1.4 Playtest-driven iteration (G)
- Agents can't feel the game: DEVLOG §9 "agent 看得到截圖和 log，但感受不到手感", §14.5 "沒有真人試玩過". The user's phone
  playtests drive most later work: "Playtest: reach matches the art" (Senjumaru), "一護 v2：試玩後重做" (15 changes),
  mobile §13 tuned from two real phones. Docs label "姿勢是用前向運動學對過數字，沒有逐一看畫面，需要使用者看".
- Turn each playtest complaint into a **checkable rule**: "判定距離比動畫顯示的長很多" → host test: every J/K hit volume ends
  within 0.15 m of where the art strikes (forward kinematics over every move of every form).

### 1.5 Faithful reporting (G)
- Report failing or regressed gates even when the user didn't ask: DEVLOG §39 "IR 213.5、II 231.9、SI 224.9 秒超過 210 秒上限
  … 先照使用者的決定保留，回報給使用者決定".
- Found-but-not-fixed behaviour changes are escalated, not silently fixed: §38 Senjumaru state leak "屬於遊戲行為，這次沒有修，
  留給使用者決定" (fixed next section after the user agreed).
- Own mistakes plainly: §73 "當初掃過全部招式…卻沒有檢查取消後能不能接著再出招，這是我的疏漏"; §71 "出錯過一次：一開始把 3 加在攻擊方
  的優勢上…查到後改成減 3".
- Record what was tried and dropped, with numbers (§72 "試過但拿掉", §75 "試過但沒採用", §69 Breaker read 51 → 42 % removed).
- Surface unexpected findings as separate reports: §68 the "dumb player" beat NORMAL 98 % without assist → "這是 CPU 本身的
  弱點，和輔助無關，另外回報給使用者" → became the next several sections of work.

---------------------------------------------------------------------------------------------------------------------
## 2. Documentation system

### 2.1 Doc types and languages (G structure, P names)
| Doc | Purpose | Language |
|---|---|---|
| README.md, docs/README.md | entry + index table of every doc with a one-line zh-TW summary | zh-TW |
| TUTORIAL.zh-TW.md | learning path (build → engine → ECS → each game's architecture → exercises) | zh-TW |
| DEVLOG.zh-TW.md | decision log / rationale, 81 numbered dated sections | zh-TW |
| ARCHITECTURE.md, ENGINE_API.md | contracts between modules/agents; gotchas list | EN |
| DUEL_DESIGN.md | the game "as built"; "when this file and the code disagree, the code wins"; §11.1 "Decided, not yet built"; §12 what changed and why; appended dated decision sections | EN |
| DUEL_GAMEPLAY.md | build/run, debug commands, test scripts, gate policy, measured gate tables | EN |
| Feature/character docs (DUEL_STRINGS, DUEL_RUKIA, DUEL_ICHIGO, DUEL_SENJUMARU, DUEL_KEN_BANKAI, DUEL_YAMA_REWORK, DUEL_NOZARASHI_V2, DUEL_ASSIST, DUEL_AI_V2, DUEL_MOBILE_DESIGN, BABYLON_PORT) | one per feature: request → decisions → design → self-critique → as-built deviations → measurements → later dated revisions | EN, user-facing summary/questions in zh-TW |
| docs/research/<topic>/ (tools first write research_notes/, reports/; moved here before commit) | source research with confidence tags | EN notes, zh-TW report |
| duel/web/manual.html | in-game player manual | zh-TW |

- Rule from the user (feedback-docs-sync.md, 2026-09-26: 「這些設計要求記得要同步更新到文檔中」): **every user decision goes
  into repo docs in the same pass**, including decided-but-unbuilt designs; never only in scratchpad notes.
- Docs double as **handoff memory for fresh subagents** (feedback-fresh-subagents.md): "put what the next agent needs into
  docs/, then spawn fresh".

### 2.2 Feature-doc anatomy (G template; DUEL_STRINGS is the model)
1. Title with date; **Status** paragraph: built/when, which § is design vs as-built vs later revisions.
2. "§0 The requests (verbatim)": quoted zh-TW blocks, then the interpretation ("毀魂技 is the Kikon").
3. "§0.1 User decisions": table `# | Question | Decision`, including corrections ("No, corrected: 「JJ, JK 不代表…」").
4. "What exists today, and what changes" table (code today | change).
5. Rules, per-character tables, controls + AI.
6. **"Balance and adversarial self-critique"**: predicted effect on pacing, then a findings table with severity
   (BLOCKER / MAJOR / MINOR, ids B1, M1, m1) and the resolution of each.
7. "Questions for the user" (or "None new").
8. Implementation sketch, file by file, including which doc sections to update.
9. "As built: what differs" table `# | Design | Built | Why`.
10. "Measured" (the gate tables).
11. Later sections appended as `## N. <rule in one line> (the user, YYYY-MM-DD)`: the user's quote, bullets of
    knobs (`*name*` old → new), tests added, gate numbers. Sections may be out of numeric order in the file (§16 before
    §15) - avoid that; append in order.

### 2.3 DEVLOG section format (G)
- `## N. <short zh-TW title>（YYYY-MM-DD）`; opens with `使用者：「…」` verbatim (multiple quotes chained with →).
- Then bold-labelled bullets: **使用者的決定／選擇**, **原因／查到的原因**, **改動／做法**, **試過但拿掉**, **調整過程**,
  **測試／結果** (15 pairings K.O., median range, A/B rows, masher %, host test counts, G2 lines), **還沒解決**.
- Earlier sections are long prose essays; later ones (§68+) are bullet lists: the bullets are easier to scan. Prefer them.
- Cross-refs both ways: DEVLOG §N ↔ STRINGS §M ↔ commit subject.
- Disagreements between parallel lines are labelled: §37 "（§36 是另一條線：…）".

### 2.4 Tuning knobs carry their history (G)
- Every number lives in code (tuning.lisp or the character file's top); docs reference knobs by name and show
  `old → new` ("*breaker-reach* 0.7 → 1.35"). Debug command ranges let gates override knobs at runtime (debug
  20000+k etc.) so sweeps don't need rebuilds.
- Reference results quoted in several docs (the YK G2 line in DUEL_GAMEPLAY, TUTORIAL 9.5, tests/scripts/duel.py) are
  listed in the brief as "update these when the reference changes" - keep a list of every place a number is quoted.

### 2.5 Player-facing docs kept in sync (G)
- The manual was a user request (DEVLOG §43, DUEL_DESIGN "In-game manual": 「完成後請寫一個中文版的遊戲系統與角色操作的 html
  說明文件，並在遊戲中可以跳轉到說明頁中。」). Rules: player wording, no internal names; "when the rules change, the manual
  changes with them"; self-contained, offline, mobile-first (stacked cards < 640 px, no horizontal scroll at 390 px);
  reachable from the main menu. Rule changes such as 590f099 touch manual.html in the same commit.
- Design docs for the user start with a zh-TW summary (DUEL_MOBILE_DESIGN "給使用者的摘要（繁體中文）", STYLE_STORM docs
  "開頭有中文摘要與待決事項").

---------------------------------------------------------------------------------------------------------------------
## 3. Research on source material (G method)

- Before a character: a deep-research pass producing `research_notes/<topic>/<char>.md` fact files (moved to `docs/research/<topic>/notes/`) (EN) and one
  synthesized zh-TW report `docs/research/tybw-characters/report.zh-TW.md` with inline citations.
- Fact files: scope line, legend **[MANGA] / [ANIME-ORIG] / [UNVERIFIED]**, sections Takeaway / Cited Findings /
  Inferences / **Gaps** (e.g. "Bleach Wiki returned HTTP 402 … I found no reliable source for …"). Weak sources flagged
  ("Low-reliability source"); conflicting dates resolved with reasoning.
- Design docs keep a **canon ledger** (DUEL_SENJUMARU §13): every element tagged [V] manga verified / [A] anime-only /
  [G] our invention; invented names must never read as canon (critique item m1).
- Canon beats are encoded as mechanics **written as the opponent's counterplay verb** (table Canon | Mechanic | The
  opponent's verb): "She is weak in a straight fight: Gerard shatters her needle" → lightest strings, short reach →
  "out-range her".
- Research looks at precedents in other games for the design problem, not just the source (report: Asuka R, Zato's
  Eddie, Susano'o from Dustloop for "sidegrade" awakenings), and notes when the reference game itself does the
  opposite ("使用者的 sidegrade 規則是刻意和 RoS 分道揚鑣").
- RAVEN EDGE precedent: "照結構抄，名字自己取" - copy structure, invent names; fan-study disclaimer on the title screen,
  all assets generated by code (DUEL_DESIGN "Fan study").

---------------------------------------------------------------------------------------------------------------------
## 4. Multi-agent practice

### 4.1 When and how to fan out (G)
- First game (DEVLOG §9, §14.1): parallel tracks (engine / audio / research+spec; then combat core / stage; then AI /
  flow), held together by **written contracts**: ARCHITECTURE module ownership table, ENGINE_API, stub APIs first
  (`world.lisp` stub so combat could start), per-agent build target names, a "Requests" section instead of editing
  another owner's file, clip names as the art/gameplay contract (missing clip → fallback + log line, so nobody waits).
- **Design debate before code**: a lead drafts, two opposed critics review (a fighting-game designer: "the numbers that
  decide playability", cut systems in half; a tech lead: budgets, additive-only engine changes), merged into
  "design v1" as the contract. Later docs keep this as the adversarial self-critique table. STYLE_STORM_DESIGN reached
  v4 after four review rounds plus "user review 1/2".
- Read-only auditors/reviewers: an engine gap audit (20 gaps), a code review (55 items, 9 bugs), a playtest review
  by an agent running 60 fixed-seed matches and analysing logs (22 issues); then fixers with non-overlapping files.
  The code review overturned the first pacing result: it had been tuned on top of a bug (DEVLOG §14.3).
- A final **harvest** agent moves proven-generic code into the engine, checking bit-identical match logs after each move.
- Large builds: "按需求分派多個 subagents 實作，再由一個主 Agent 監工與整合" (feedback-orchestrate-subagents.md, Babylon port).
  One worktree + branch per independent batch; the main agent verifies every report itself (tsc, tests, gate,
  screenshots), merges, resolves conflicts, updates the doc's Status, commits, pushes.
- Search problems fan out too: AI v2 = 5 subagents (one per character, own worktree) × 2 dream-rsi rounds × 4 variants,
  scored by `tools/aieval.py` (0.6 strength + 0.2 masher + 0.2 signature, 0 if pacing fails), then one integration
  agent (DUEL_AI_V2.md, docs/research/ai-v2-drsi/).

### 4.2 Briefs (G)
- **Fresh agent per batch with a compact brief**; don't resume a big one (feedback-fresh-subagents.md: a style agent
  hit ~650k tokens; every resume reloads the transcript). Small follow-ups in the same batch may resume.
- Brief skeleton (docs/research/ai-v2-drsi/integration.brief.md): reply language; worktree + "you MAY commit on your
  branch, do NOT push, do NOT touch main"; the attribution trailers; Context (the user's request and decisions);
  numbered Steps with exact commands; acceptance numbers per gate; exact list of files/quotes to update; Docs step
  (which doc, which §, DEVLOG entry "in Traditional Chinese, same style as §76"); Rules (bounded waits, no pkill, do not
  deploy, do not edit the scorer); Report format (tables, gate results, branch, commit ids).
- Search-cell briefs are generated by a script (docs/research/ai-v2-drsi/brief.py) with hard rules: "edit only this
  file", "do NOT change frame data … write shared changes as a recommendation in proposal.md", "trust score.json over
  any proposal's claims", "prefer a structurally different mechanism".
- Code-layout rule enables parallel character branches (DUEL_DESIGN "Character code layout", the user 2026-09-28:
  「每個角色用獨立的檔案實作，後續再將能復用的功能抽出到上層檔案中」): each character in its own 2 files; shared files only get
  small generic hook points; duplication allowed until a **second user** proves the abstraction; an extraction pass
  after both merge (DEVLOG §30 unified Ichigo's and Senjumaru's hooks; "A third user … is the moment to fold them").

### 4.3 Advisor model (G)
- A second model (Fable 5.1) used as discussion/review advisor at milestones: chose the port strategy ("translate the
  sim, rewrite the look"), did a fidelity review that found 3 real divergences, wrote the look-polish spec. Its advice
  is recorded as "(Fable 5.1's recommendation, adopted)".

### 4.4 Failures seen (G lessons)
- **Self-matching wait loops** (feedback-no-self-matching-pgrep.md): `until ! pgrep -f X` matched its own shell; 4 loops
  sat ~7 h; `until grep -q finished <file>` waited 16 h for a word that never came. The user had to find and kill
  them. Rule in every brief: bounded loops (`for i in $(seq 1 N)`), wait by PID or background notification, no
  `pkill -f`/`pgrep -f`, check `ps` for leftovers after an agent finishes.
- **Engine edits in the shared tree break others' builds** (build reads Lisp first, C minutes later): engine work moved
  to a separate checkout and was synced back after verification (DEVLOG §14.1).
- **Parallel uncommitted batches piled up** in one tree before the auto-commit rule (feedback-autocommit.md "Why").
- **Usage limit mid-fan-out**: six Babylon batches paused uncommitted in worktrees; the Status entry listed each
  worktree path and the next steps so work resumed cleanly. Write the resume plan into the doc before stopping.
- **Worktree litter**: `git worktree list` still shows 29 `.claude/worktrees/agent-*` worktrees/branches from finished
  agents. Add a cleanup step after merging.
- **Hidden state across runs** surfaced only when gates were split across processes (Senjumaru's per-side state never
  reset, DEVLOG §38) - running the same seeds in different process layouts is a cheap leak detector.
- **Over-optimised CPU results don't transfer**: AI v2 search scores dropped once all five improved CPUs met each other;
  NORMAL had to be pulled back within +0.05 of the old level.

### 4.5 The discontinued port (G lesson)
- Babylon.js + TS port (docs/babylon/BABYLON_PORT.md): milestone table with acceptance per milestone (M1 core … M6 platform),
  "traps to copy verbatim", a parity tool (first differing line / bit dumps), ~25 commits in 2 days, ended **bit-exact**
  with the native Lisp (15 pairings × 60 seeds, 900/900) - beyond its own plan, which had said "not bit-exact".
- Discontinued the day after M1–M6 finished (「Babylon 版已不再開發」); the next Lisp change (J floor) was already "not
  mirrored". Lessons: (1) two live implementations double every later change; ask early whether the port replaces the
  original or runs beside it, and what happens to parity after it ships; (2) make discontinuation clean: a banner at
  the top of the doc, a Status entry naming the first change it misses, memory updated ("do NOT mirror"); (3) scope
  creep (parity → bit parity) is expensive; confirm the bar with the user.

---------------------------------------------------------------------------------------------------------------------
## 5. Game-design principles the user holds

### 5.1 Generalizable principles
- **Faithful to source characterisation**, with canon checked and tagged (§3); the user's look decisions are canon-led
  (Rukia as TYBW lieutenant, no haori; Kenpachi's TYBW hair; Yamamoto's Bankai without the haori; anime proportions).
- **Awakening/transformation changes playstyle, not power** (character docs: "awakened vs base differ in playstyle and
  not in power"; the six sidegrade rules: named removals, no hidden heal, active vs forced exit priced differently,
  player chooses timing in-match). Then **relaxed by the user** (2026-09-28): 「覺醒偏強沒關係，只要不是強到無法贏就好」 →
  measurable gate: "never awaken" still wins ≥ 20/60 on 3 seed streams. Pattern: turn a design value into a numeric
  A/B gate. Exception kept where canon demands power (Kenpachi's Bankai: strong first, then pays with his arm).
- **Rock-paper-scissors loops, enforced by geometry**: 防 > J > I > 防 (guard beats J, J beats the grab, the grab beats
  guard). The grab's reach must be shorter than every J, and a triggered grab must connect; host tests assert both
  (DEVLOG §36, §81: 1.35 < 1.4 and 1.35 + 0.34 > 1.6).
- **Light short fast / heavy long slow**: "j 是輕短快的攻擊、k 是重長慢的攻擊"; K ≥ J + margin at every link; whiffs
  punished more for heavies; J floor 1.4 m added later when J got too short to use.
- **Readable reach = the art**: hit volumes must match what the animation shows within 0.15 m (playtest complaint →
  test). Every placed hazard has a tell; every awakened power has a visible cost (weave is held and interruptible).
- **Pacing target as a gate**: CPU-vs-CPU median 125–210 s (raised from 120–180 because "真人對戰比電腦對電腦快很多"),
  all K.O.; knobs adjusted, not rules, when out of window; user may accept exceptions.
- **No infinite pressure**: hidden hit-stun tolerance blows the victim away (§37); guard cancel must not restart a
  string sooner than recovery would (§73 bug); pushes put the victim "剛好在範圍外" so restarts whiff.
- **Reward aggression** (KŌSEI: more resources the lower your guard gauge, "從被動轉成主動").
- **CPU that teaches and answers mechanics**: every new mechanic gets a CPU rule in the same or next batch ("幫我教 CPU
  跟更新的兩個機制"); CPU answers mashing (§72, §74) so mashing doesn't win; difficulty layering EASY ≤ NORMAL ≤ HARD,
  EASY keeps gaps on purpose; a learning CPU reads the human's habits; success measured by a scripted "dumb player"
  (masher vs HARD 98 % → 3 %).
- **Accessibility**:
  - ASSIST (DUEL_ASSIST.md) from 「我打不過 AI（哭泣）」: three SETTINGS toggles (AUTO GUARD OFF/HOLD U/ALWAYS, AUTO COMBO,
    AUTO BREAK), "you press, the CPU chooses", a price (×0.8, never a perfect dodge) so manual play still pays, CPU-vs-CPU
    gates untouched. Measured honestly: AUTO COMBO makes play flashier, not stronger.
  - One-hand portrait phone mode (DUEL_MOBILE_DESIGN.md): right hand default, left mirror option, tap zones J/K, flicks,
    hold = guard; PWA install; later merged into SETTINGS (ONE-HAND AUTO/ON/OFF) instead of a separate menu mode;
    PERFECT HINT setting; key/pad rebinding; practice mode with infinite gauges.
  - In-game zh-TW manual; HUD prompts follow rebinding.
- **Settings over modes**: features become SETTINGS rows (one-hand, assist, hints) rather than new menu modes.
- **Deliberate nerfs stay nerfs**: "使用者明說這是刻意的削弱，不調其他數值補回來" (DEVLOG §14.3) - don't auto-rebalance the
  user's intentional changes.

### 5.2 Project-specific
- RoS mapping (Reishi/Konpaku, red at 30 %, Kikon on O, Soul Break = count + 1 cap 5, Burst modes white/blue/orange).
- Strings: up to 3 links, J/K switch at most once (「K J 不要來回交錯」), O ender only after a hit J3/K3.
- Per-character signature resources (one resource per form, one HUD row).
- Unskippable cinematics count toward sim time (determinism).

---------------------------------------------------------------------------------------------------------------------
## 6. Communication style with the user

- The user writes short zh-TW requests, sometimes playful ("萊醬萊醬，我打不過 AI（哭泣）… QQ") and sometimes sharp
  ("萊醬怎麼會這樣做呢？"). Reply in zh-TW, concise: what changed, the key numbers, what's pushed, what's pending
  (Pages), and any decision needed. Code comments/design docs in English.
- Ask before balance trade-offs; present options with a recommendation; record the pick. When a gate fails after the
  user's explicit decision, keep the decision and report the numbers.
- Distinguish verified vs not verified ("看過靜止畫面，還需要使用者看").
- Use the user's own words as the spec and quote them in docs; correct premises politely with sources.
- Bug reports from the user get: cause, repro (debug command), fix, the CPU's exploitation of it, gate deltas, and an
  explicit admission if it was our oversight.
- Bursts of small requests: implement each, commit+push each, hold the deploy until "done".

---------------------------------------------------------------------------------------------------------------------
## 7. Skill / playbook candidates distilled

1. `change-loop`: request → quote verbatim → options + recommended default → implement → gates → docs (EN design §,
   zh-TW DEVLOG §, manual) → commit (subject with user/date/gates/§ refs + trailers) → push → no deploy unless asked.
2. `feature-doc` template (§2.2) incl. adversarial self-critique table and "As built: differs" table.
3. `devlog-entry` template (§2.3, bullet form).
4. `subagent-brief` template (§4.2) + mandatory rules block (bounded waits, no pkill/pgrep -f, no push/deploy,
   trailers, docs to update, report format) + post-merge cleanup (worktree remove, `ps` check).
5. `canon-research` template (§3): fact files with tags + Gaps, report correcting premises, canon ledger, counterplay
   verbs, precedent games.
6. `balance-gates` recipe: deterministic sim, headless native runner from the same sources validated line-by-line,
   statistical pacing window, multi-stream A/B for "choice not power", scripted dumb-player gate for CPU/assist,
   affected-pairings-only + two-stage seeds, record user waivers as policy.
7. `port-or-not` checklist (§4.5) before starting a second implementation.
