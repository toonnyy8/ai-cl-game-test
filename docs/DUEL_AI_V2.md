# The per-character AI, v2 (the user, 2026-10-02)

The user: "請萊醬你用現在的設計邏輯與每個角色的特色規劃出新的 AI 設計與行動方針。並將這套改良版的 AI 與學習型 AI 整合後也整併到
auto 的輔助模式中。可以開啟 subagents 與 /anthropic-skills:dream-rsi 進行每個角色與連段應用的辯思與測試，並將這些經驗一同整合的
AI 的設計中。"

**Decisions (the user, 2026-10-02):**

- **Score.** Win rate + character colour. `tools/aieval.py`: 0.6 strength + 0.2 masher + 0.2 signature, 0 when the
  pacing check fails.
- **Budget.** 2 dream-rsi rounds x 4 variants per character.
- **Strength by difficulty.** EASY keeps its gaps, NORMAL stays near today's level, HARD is the full version.
- **Parallelism.** 5 subagents, one per character, each in its own git worktree.

**Method:**

- **The search.** Each character has a dream-rsi workspace (`research_notes/ai-v2-drsi/<character>/`). A cell is one
  variant of that character's `duel/lisp/<file>.lisp` AI: its forms' `:ai` tables and their reflex functions. The
  evaluator is `tools/aieval.py --char i`, run on the native sim against the other four characters' current CPUs.
- **After the rounds.** The best variant per character is merged. Then the learning CPU and the ASSIST auto mode take
  over its choices, and the full gates run.

**Baseline scores (main 0462476, 20 seeds):**

| character | score | strength (HARD) | masher (HARD) | signature |
|---|---|---|---|---|
| Yamamoto | 0.595 | 0.531 | 0.800 | 0.580 |
| Kenpachi | 0.291 | 0.175 | 0.400 | 0.528 |
| Rukia | 0.765 | 0.831 | 0.887 | 0.441 |
| Ichigo | 0.477 | 0.450 | 0.525 | 0.507 |
| Senjumaru | 0.571 | 0.512 | 0.700 | 0.619 |
