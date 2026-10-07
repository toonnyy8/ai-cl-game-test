# SOUL DUEL: Lille Barro (リジェ・バロ, zh-TW 利傑巴羅), 万物貫通 THE X-AXIS and 神の裁き JILLIEL

Status: **full design pass written 2026-10-06 and revised after an adversarial review the same day (22 findings; the
lock, the eye's rest rule, MUJITTAI as a ward); the user's review answered 2026-10-06 (decisions 12–15)** (§2–§16). **Build started 2026-10-06** (the user:
「就麻煩萊醬開始下一步啦」), in batches:
1. the sim, the kits, the functional art and the tests;
2. the AI perception (G1, `:opp-aim`, `:opp-reflect`), alongside batch 1;
3. his own reflexes, the HUD, the cinematics and the VFX;
4. the gates, the tuning and the player docs. nothing is built yet; the roster
plumbing for a sixth character is in (DEVLOG §84). §1 holds the user's decisions; §16 the questions on the design pass. Canon facts: `docs/research/tybw-characters/notes/lille_barro.md`
(web-search summaries only, each claim with a confidence flag; check chapter numbers before quoting them in the manual).

The request (the user, 2026-10-06): 「我想要請你依據之前 duel 的開發經驗幫我製作新角色『利傑巴羅』，先與我討論整體設計構想，並在討論期間指派 agent 建制環境。」

## 0. Frame

- Roster **index 5**, keyword `:lille`, move and clip prefix `:lb-`. Appended **last** (the roster is append-only:
  learn tables, ENDLESS records and every index-keyed tool depend on it; DUEL_ENDLESS.md). Files `duel/lisp/lille.lisp` +
  `duel/lisp/lille-art.lisp`, loaded after `senjumaru.lisp` (DUEL_DESIGN "Character code layout").
- Canon marks as in DUEL_SENJUMARU.md: **[V]** manga, **[A]** anime-only, **[G]** our game interpretation.
- The canon beats this kit encodes (research note §2–§4):

| Canon | Mechanic | The opponent's verb |
|---|---|---|
| The X-Axis pierces everything on the line from the muzzle to the target; no barrier stops it (Nimaiya shot through two Royal Guards' shields) [V ch. 601–602] | the X-Axis shot goes **through guard**, projectiles and summons | **step off the line** |
| A sniper with no melee technique; he wins by never being in reach [V] | the weakest close range in the roster | **close the distance** |
| Jilliel: constantly intangible, "no weapon or spell can wound" him [V ch. 646] | a **phase stance** on U that any attack ends (decision 3) | **make him attack**, then punish |
| The left eye opens in a crisis; three openings unlock the Vollständig [V ch. 645–646] | three **eye** pips of a timed phase; the third fills EVOLUTION (decision 7) | **bait the eye**, then strike |
| Beheaded by Kyōraku's Bankai, he revives owl-headed [V ch. 649–650] | a **second awakening** at ≤ 4 Konpaku, Konpaku → 1 (decisions 6, 8) | **finish him**: one Kikon ends it |
| Nanao reflects his own Trompete; the halo breaks [V ch. 653] | a perfect Hoho / guard **reflects** Trompete and seals it (decision 9) | **time the guard** to the trumpet |

## 1. User decisions

### Decision 1 (2026-10-06): a pure long-range sniper

The user chose 「純遠距狙擊」 from: pure long-range sniper / mid-range hybrid / long range + strong escape.

- The roster's first true zoner: the lightest J / K strings (rifle butt and bayonet, short reach), strong at range.
- The opponent's plan is to close in and sidestep. The CPU and the pacing gate must not let him stall (the 125–210 s
  window applies as for everyone).

### Decision 2 (2026-10-06): the X-Axis pierces guard but only drains the guard gauge

The user chose 「穿防但只削防禦槽」 from: pierce guard but only drain the gauge / fully unguardable / blockable, pierce
projectiles only.

- A guarded X-Axis shot deals little Reishi (chip; chip never kills) and a large guard-gauge drain, so it leads to
  GUARD CRUSH. The main answer is a sidestep off the line, which a visible aim line telegraphs.

### Decision 3 (2026-10-06): Jilliel's intangibility works like Yamamoto's Bankai West

The user's words: 「設計成跟山本卍解相同，按下防禦開啟無實體狀態、攻擊就解除」 (rejecting: intangible when not attacking with
a gauge / the pure canon rule / intangible to ranged only).

- In the awakened form, **U switches him into the intangible stance** (as Yamamoto's U = East → West, kit
  `:guard-to`, DUEL_DESIGN §6.1 / DUEL_YAMA_REWORK.md), and **attacking drops it** (as West's `:drop-to … :keep`).
- The details: decisions 4–5 and §5.2.

### Decision 4 (2026-10-06): the intangible stance's cost and breaker (Q1, Q2)

The user chose 「穿過的攻擊削防禦槽，Breaker 能破」 (rejecting: fully invincible, only a Breaker breaks it / passed hits
drain Reiatsu).

- As West's ward: every hit that passes through him drains its guard value from the guard gauge, which **does not refill**
  while he is in the stance; empty = the stance drops and GUARD CRUSH.
- A **Breaker** (the grab) and the **unguardables** land on him in the stance.

### Decision 5 (2026-10-06): which commands keep the stance (Q3)

The user chose 「移動與 Step／Hoho 保留，所有攻擊解除」 (rejecting: walking only / the wing volley also keeps it).

- Walk, run, Step and Hoho keep the stance; **every attack** (J, K, L, SP1, SP2, I, O) drops it on the move's frame 0
  (West's `kit-drop`, with no `:keep` list).

### Decision 6 (2026-10-06): the second form is a second awakening (Q4)

The user chose 「第二次覺醒（像劍八卍解）」 (rejecting: a last stage inside the awakening / the Kikon cinematic only),
after the research came in (the owl-headed "true form" that revives after Kyōraku beheads him, Trompete, Sabaki no
Kōmyō; research note §4).

- The second exception to "one awakening per match", after Kenpachi's Bankai (DUEL_KEN_BANKAI.md). Entry and cost: decision 8 and §6.1.

### Decision 7 (2026-10-06): the left eye, three openings (Q5)

The user chose 「做：3 格眼，用完第 3 格補滿覺醒槽」 (rejecting: three pips not tied to the awakening / no eye rule).

- Base form: a three-pip **eye** meter, no refill in the match. U pressed at the moment he is hit spends a pip for a
  brief phase (a Hoho without the displacement; canon: he opens the left eye in a crisis, the blade passes through, ch. 645).
- The **third** opening fills the awakening gauge to EVOLUTION (canon: three openings is "heresy" and he releases
  Jilliel, ch. 646). It does not awaken him by itself; P still does.

### Decision 8 (2026-10-06): the second awakening is a revival after a beheading (Q6)

The user chose 「被斬首後復活」 (rejecting: exactly Kenpachi's Bankai rule / a higher threshold at a lighter cost).

- Canon: Kyōraku's Bankai beheads him and he revives owl-headed (ch. 649–650). The entry: in Jilliel, when a Kikon takes
  his Konpaku and he has **≤ 4 of his own Konpaku** left, **P** revives him into the owl form.
- The cost as Kenpachi's Bankai: his Konpaku go to **1**, his Reishi is refilled; the halo shrinks and the intangible
  stance is gone (the owl form trades the defence for the attack). Once a match by construction.
- **Superseded by decision 16** (2026-10-06): no beheading needed, ≤ 4 Konpaku in any Jilliel form is enough.

### Decision 9 (2026-10-06): Trompete can be reflected, and a reflection breaks his form (Q7)

The user chose 「反射成功還會打斷他的形態」 (rejecting: a perfect Hoho / guard reflects part of it / no reflection).

- Canon: Nanao's Hakkyōken turns Trompete back into him, takes an arm and a set of wings and breaks his halo (ch. 653).
- A perfect Hoho or a perfect guard against Trompete reflects part of it back onto him **and breaks his halo**: the
  owl form loses Trompete for the rest of the match (the exact loss is set at the design pass; the largest swing in the
  kit, so its timing window is a gate item).

### Decision 10 (2026-10-06): the X-Axis shot reaches the whole arena, more damage the farther (Q8)

The user chose 「全場，越遠傷害越高」 (rejecting: the whole arena at a fixed damage / about 15 m).

- One shot reaches the arena's edge (30 m across); its damage rises with distance, so he wants range and the opponent
  wants to close in. The aim line gives the opponent time to step off it. The CPU's perception and `:moves` bands must
  cover 8–30 m (nothing today is longer than 12 m).

### Decisions 12–15 (2026-10-06): the user's review of the design pass

The user answered the four questions that changed the design (the other two of §16, the volley's and Trompete's
numbers, stand at their defaults):
- **12. The lock** 「照設計」: the line locks after 24 f of tracking, the shot fires ≥ 10 f after the lock (auto at 30),
  the aim can be cancelled before the lock (§4.3).
- **13. The eye** 「U 放開 ≥ 10 f 後的點按」: a deliberate tap after U rested ≥ 10 f, ≤ 8 f before a hit; no cost on a
  miss (§4.1).
- **14. MUJITTAI's clock**: 「向山本一樣無實體不恢復防禦槽，正常狀態防禦槽恢復量大減。使整體設計更容易被破防」 (rejecting a
  3 / s or 6 / s self-drain, or a run that drops the stance). Read as: the stance never refills (as West, no self-drain),
  and **Jilliel's refill outside the stance is cut hard**, 5.5 → **2.0 / s** (`:gg-regen`), so the design breaks
  more easily. The base form keeps the universal refill; the user confirmed it (「只套用在 Jilliel 的架式外沒錯」,
  2026-10-06).
- **15. The owl's cost** 「不加代價」: no burn, no partial refill. The revival costs what decision 8 says (Konpaku → 1) and
  nothing more; at 1 Konpaku it is free, accepted.

### Decisions 16–20 (2026-10-06): the user's rework after the first playtest build

The user's request, verbatim: 「1. 只要魂魄數小於等於 4 就能透過 P 復活，否則在練習模式無法進入梟頭型態。 2. 把非覺醒的 L 改成擺出射擊架式，並參照一護的架式玩法進行設計。利用架式賦予其機動性，使利捷·巴羅能再近戰遠攻之間靈活切換。 3. 把覺醒的 L 會在近戰（長出與梟頭型態一樣的腿）與遠程模式（與目前 Jilliel 一樣的狀態）切換，遠程模式的特點是可以一邊行動一邊把連招動作打完，而且攻擊並不會有傷害只會留下萬物貫通的射擊軌道，只有在通過 L 切換模式時會將軌道上的攻擊實體化。每次通過 L 切換模式時，都會發動向一護始解架式時的墊步閃身來拉近（變成近戰）或拉遠（變成遠攻）。 4. Jilliel 是揮舞八片刀刃狀的翼發動攻擊，而手臂則是背影藏在柱身內部，但現在的建模看起來就像是手臂變成一對翅膀，剩下三對則死板的掛在身後。 5. 梟頭型態原作不是四根高蹺般的腿，而是兩隻細長腿，只是在腿部中間又出現分岔看起來像四條腿。」
Then, to the four questions that changed the design: 「快射＋蓄力」, 「兩模式都無實體」, 「留到切換、最多 8 條」,
「遠程模式留粗軌道，近戰模式直接打出」.

- **16. The revival** (replaces decision 8's beheading condition): in any Jilliel form, free (idle / guard, MUJITTAI
  included), with **≤ 4 of his own Konpaku** (`*bankai-konpaku*`, Kenpachi's rule exactly), **P** revives him into the
  owl. No beheading flag; so PRACTICE's KONPAKU row reaches the owl. The revival cinematic keeps the canon beheading.
- **17. Base L is a shooting stance** after Ichigo's TSUKIMACHI, with a dash for mobility; the stance's L is a quick
  shot (flat) or, after ≥ 24 f in the stance, the charged shot (the distance curve). §22.1.
- **18. Jilliel's L switches between two modes**: ranged (as Jilliel was: floating; attacks while moving; they deal no
  damage and leave X-Axis traces, at most 8, kept until the switch) and melee (the owl's legs, the wing-blade strings,
  normal hits). Every switch is a flash-step dash (in → melee, out → ranged) and materialises every trace. U is MUJITTAI
  in both modes. SP2 leaves a thick trace in the ranged mode and fires directly in the melee mode. §22.2.
- **19. Jilliel's wings are the weapons**, eight separate blades in two fans of four, swung one or two at a time; the
  arms are hidden in the column. §22.3.
- **20. The owl has two long thin legs, each forking halfway** into two (it reads as four). §22.3.

### Decisions 21–27 (2026-10-06): the user's second playtest of the rework

The user's request, verbatim: 「# 常態改動 1. L 射擊架勢接 J 改成向前跳飛並在空中射出連射三發短程子彈（擊中後可與 j/k 串成 combo）；接 K 則會向後拉開距離打出一發中程子彈；在 step 飛廉腳完之後會直接將準心重新對準對手。 2. 這應該算是 bug，在手機觸控模式下 L 射擊架勢時，向上滑動被判定成 hoho（但不會觸發 hoho 瞬移）而不是 step。 # 覺醒改動 1. 近戰與梟頭的腿部是從分岔點向後延伸出垂直支架，在末端才以折角往下延伸，呈現出 ㄇ 字型。 2. 請大幅提升變換戰型後的衝刺距離。並讓衝刺後可以直接銜接 J K 攻擊取消後搖，使預留的貫通軌道能串連 J/K 形成 combo。 3. 把翅膀調整成半透明以免遮擋視線。 4. 梟頭型態的建模在原作中會呈現以目前的近戰型態為基礎，並將頭部換成長頸梟頭與增加額外的手臂。」

- **21. Stance J is a leaping triple shot**: a forward leap, three short-range bullets fired in the air; on a hit he may
  link J or K after it (a combo). §23.1.
- **22. Stance K is a backstep shot**: he slides back and fires one mid-range bullet. §23.1.
- **23. After the stance's HIRENKYAKU the aim snaps onto the opponent** (no 60°/s turn back). §23.1.
- **24. Bug (touch)**: in the stance, an upward flick reads as a Hoho (with no Hoho) instead of a Step. Fixed. §23.1.
- **25. TENSHIN's dash is much longer, and J / K cancel its recovery** so a materialised trace links into J / K (a combo).
  §23.2.
- **26. The legs are ㄇ-shaped**: from the fork a strut runs back, and at its end the leg bends down. §23.3.
- **27. The wings are translucent** (so they don't hide the fight), and **the owl's model is KIN's** with the head swapped
  for the long-necked owl head and an extra pair of arms. §23.3.
- **28. EN's J / K / SP1 / SP2 start and recover much faster** (the user, 2026-10-06, the same evening: 「再補一個：覺醒的遠程模式
  J/K/SP1/SP2 的前後搖都大幅縮短。」). §23.2.
- **29. Traces: at most 16** (was 8; the user: 「然後將射擊軌道的留存上限改成 16。」). §23.2.
- **30. TENSHIN's startup depends on where it starts** (the user: 「如果是中立遠程狀態按 L 的話，增加約 0.1~0.15 的型態變換與衝刺前搖動作，如果是遠程攻擊狀態按 L 的話則大幅減少前搖動作。」):
  from EN's neutral it gets a wind-up; as a cancel out of an EN attack almost none. §23.2.
- **31. HŌSHA leaps farther and shoots shorter; TAISHA shoots shorter** (the user's third playtest, 2026-10-06: 「# 常態修改
  1. L > J 前跳距離加長&射程縮短。 2. L > K 射程縮短>」). §23.1.
- **32. The wings' rims translucent too, and every wing jointed** (the user, 2026-10-06: 「萊醬你能幫我將覺醒後翅膀的不透明邊界也
  都換成半透明嗎？然後每片翅膀改成中間加 2 節可以彎折的連接觸，讓整體動作與攻擊動畫不會太死板。」): the opaque rim, teeth and
  hole rings go see-through as well; each blade becomes three segments joined at two bending joints, so the idle, the
  folds and the strikes curl and whip instead of swinging as rigid planks. §23.8.
- **33. Jilliel no longer sinks when he moves** (the user, 2026-10-06: 「還有覺醒狀態移動的時候整個角色很明顯下沉，請修改回正常
  高度」). §23.10.
- **34. TENSHIN's tempo and the flash-step economy** (the user, 2026-10-06: 「# 覺醒改動 1. 遠程模式從中立按 L 的前搖的前搖增加到 16 f。
  2. L 切換戰型取消冷卻限制，並且從『遠』變『近』不消耗閃步量表，但遠程 J/K 每條軌跡消耗 3 點閃步量表，相對的每打中一條鬼機會額外回收 2 點閃步量表。」;
  「鬼機會」 read as 「軌跡會」): §23.11.
- **35. EN's J / K need 3 flash step to swing** (the user, 2026-10-06: 「如果閃步剩不到 3 點時，就讓 J／K 不揮出，藉由這樣設計限制 L
  在沒有閃步時量表時就不能靠空揮 J ／K 達成沒有前搖的衝刺。」): under `*lb-trace-fs*` (3) the press is refused (`lb-en-dry-p`),
  so an empty swing can't buy TENSHIN's 2 f cancel. §23.14.
- **36. The owl's system is Jilliel's** (the user, 2026-10-06: 「請讓梟頭型態的系統設計完全與 Jilliel 對齊，只是萬物貫通的射擊特效改成審判光明
  （沿地面的金色爆炸線）、SP1 特效與動作用審判光明、SP2 特效與動作用神之喇叭。與 Jilliel 的主要差異是具有更高的攻擊力、更高的軌跡命中回收比例
  與更優異的優勢幀。」; then 「也是無實體」, 「保留反射與封印」, 「小」): §23.14.
- **37. A Hoho in EN switches to KIN** (the user, 2026-10-06: 「另外添加一個新設計，覺醒後在遠攻狀態使用閃步就會自動切換成近戰狀態」, then
  「只有 Hoho 會切換」): §23.16.
- **38. The owl's EN and KIN must read apart, and EN Trompete is faster** (the user, 2026-10-06: 「1. 梟頭模式幫我設計更明顯的遠程和
  近戰視覺差異，目前看不出『遠程模式翼張開、站直，近戰模式翼往後收、身體前傾』這樣的設計。 2. SP2 神之喇叭在遠程模式的前後搖再縮短。」).
  §23.18.
- **39. Laying a trace fires a 1-damage shot along it** (the user, 2026-10-06: 「請萊醬你再幫我多加一個設定，覺醒後在遠程狀態產生軌道時，
  軌道上會對敵人造成傷害為 1 的射擊傷害。」, then 「輕微硬直但可防禦」). §23.20.
- **40. The owl's EN Trompete trace materialises as KIN Trompete's blast** (the user, 2026-10-06: 「神之喇叭的遠程軌跡在透過 L 實體化之後的
  特效（現在是使用跟審判光明一樣的『沿地面的金色爆炸線』）請改成跟近戰版本一樣」): `lb-materialise` spawns the `:beam` look at
  `:lb-trompete`'s width (1.2) with its explosion sound for an owl SP2 trace; the other owl traces keep 審判光明's ground
  blasts. A look only (the hit is the trace's). Checked in a still against KIN Trompete's.
- **41. No laying shot; the trace snaps when it materialises; crossing a trace slows the match** (the user, 2026-10-07:
  「我希望去除掉軌道設置時造成的 1 點傷害，但這樣的話有會很難讓實體化能打中對手，你有什麼好想法嗎？」, then 「C+對手經過軌道的瞬間會有時緩」
  and 「全場慢動作」). Decision 39 is undone. §23.23.
- **42. TENSHIN in reaches 1.3× as far** (the user, 2026-10-07: 「另外 L 轉成近戰時能跳躍的範圍要提升 1.3 倍」): `*lb-switch-in*`
  8.0 → 10.4 m, the same 14 f. §23.24.
- **43. TENSHIN out 10 m, in 13 m; an L after a KIN K string no longer stops short; the crossing slow motion at half speed**
  (the user, 2026-10-07: 「1. 後撤距離提升到 10m，接近距離也提升到 13m。 2. 現在近戰 K 打完連擊後接到 L 後撤的距離會被限制住，這應該是 bug？
  3. 時緩改成放慢 1 倍。」). §23.25.
- **44. Close traces slow the match once** (the user, 2026-10-07: 「［討論］如果我希望非常相近的軌道不要連續觸發時緩效果應該要怎麼做呢？」,
  then 「用 A，N 先用 10 f，等這輪跑完再改」): the slow motion fires when he steps onto his live traces from off all of them,
  after ≥ 10 sim frames off. §23.26.
- **45. A fresh trace on him always slows; old traces slow longer** (the user, 2026-10-07: 「如果是才剛新生成的軌道就算重疊也一樣
  觸發時緩，而經過舊軌道的時緩參數改成 0.3 倍速持續 1 秒。」): a trace laid onto him fires 0.1 for 0.3 s whatever else; stepping
  onto old traces (decision 44's rule) fires 0.3 for 1 s. §23.27.
- **46. The slow motions retimed** (the user, 2026-10-07: 「再稍微換一下時緩參數 新軌：0.1 倍速 0.1 秒 舊軌：0.3 倍速 0.3 秒」):
  a fresh trace 0.1 for 0.1 s, old traces 0.3 for 0.3 s. §23.28.
- **47. The slow motions retimed again** (the user, 2026-10-07: 「再稍微換一下時緩參數 新軌：0.1 倍速 0.2 秒 舊軌：0.2 倍速 0.5 秒」):
  a fresh trace 0.1 for 0.2 s, old traces 0.2 for 0.5 s. §23.29.
- **49. TENSHIN 3 m shorter both ways** (the user, 2026-10-07: 「覺醒後 L 的近遠切換移動距離減少 3m」): in up to 10 m, out 7 m. §23.30.
- **50. Jilliel's strikes redone, EN and KIN** (the user, 2026-10-07: 「Jilliel 近戰的動作不太明顯，能跟我討論要如何修改動作模組嗎？」,
  then 「全身出招」「每招獨立造型」「翼尖斬痕」「八翼一起斬」, 「近戰＋遠程都換」). §23.31.
- **51. Two open items kept as they are** (the user, 2026-10-07: 「HOSHA read at HARD 跟 Awaken A/B, still failing 兩個問題都維持現狀就行」):
  the learning CPU's HOSHA-guard answer stays at HARD (Lille takes 646 a match instead of 605 against that habit, still
  winning every match), and the awaken A/B stays failing as an accepted exception (§24.11's rows). §24.12.
- **52. TENSHIN in 4.5 m, a trial** (the user, 2026-10-07: 「幫我試試看把覺醒後 L 的前衝距離改成 4.5m」): in up to 4.5 m
  (out stays 7 m). §23.32.
- **53. TENSHIN at a fixed speed, no chase on its link** (the user, 2026-10-07, asked why KIN's J1 after TENSHIN in also
  dashes forward: 「完全拿掉追擊，L 前衝停在對手前 1m，移動改成固定速度而不是固定時間，後徹距離改成兩個 step 的長度、前衝距離改成兩個 step +
  0.5m 的長度」; then 30 m/s, the chase removed from TENSHIN's link only): in up to 5.5 m stopping 1 m short, out 5.0 m, both
  at 30 m/s; HOSHA's link keeps its chase. §23.33.
- **54. TENSHIN in up to 7 m** (the user, 2026-10-07: 「將前衝距離改成最多 7m」): 5.5 → 7.0 m, still 1 m short, 14 f at
  30 m/s. §23.34.

## 2. Summary of the design pass (2026-10-06; every number is a proposal until the gate)

- **Three forms, three temperaments** (research note §6): the base form is a still, patient sniper; Jilliel is an untouchable
  floating judge; the owl form is a shrieking last stand.
- **Base 万物貫通 THE X-AXIS** (`:base`). L is held to **aim**: a thin ink line runs from Diagramm's muzzle to the arena wall,
  and he turns to follow the opponent at the Signature rate (60°/s). After 24 f of aim the line **locks** (it turns jade
  and stops turning). The shot fires on release, **never sooner than 10 f after the lock**, along the locked line,
  the whole arena long. Once the line is locked, one Step clears it. Its damage grows with distance: **40 at ≤ 4 m, 120 at ≥ 20 m**. It **goes through
  guard** (decision 2): a blocked shot lets 15 % through as chip and drains **30** from the guard gauge. It goes through
  projectiles, hazards, summons and Senjumaru's umbrella. Stance, armour and DRINK take it as they take any hit.
- **His J / K strings are the weakest in the roster** (rifle-butt and barrel strikes, J1 22). SP1 is a three-shot burst and
  SP2 a Hirenkyaku back-slide with one quick shot. **U is a guard with the eye**: a deliberate U tap (after U has been up ≥ 10 f) timed
  ≤ 8 f before a hit opens the left eye. The hit passes through him and he is intangible for 16 f, which costs one of **three pips**
  for the whole match. The third opening fills his awakening gauge to EVOLUTION (decision 7).
- **Awakened 神の裁き JILLIEL** (`:jilliel`). **U switches him into 無実体 MUJITTAI, the intangible stance** (Yamamoto's West,
  decisions 3–5). Hits pass through him and drain their guard value from a gauge that does not refill. A Breaker or an
  unguardable lands; any attack drops the stance; walk, run, Step and Hoho keep it.
  - L is the **WING VOLLEY**: a fan of five thin lines from the wing holes, 6° apart. It covers a sidestep at mid range, but
    the gaps grow with distance.
  - SP2 is **二十四孔 NIJŪSHI-KŌ**, all 24 holes at once: one wide beam after a long tell.
  - What he gives up: the normal guard, the eye, the long precision shot's distance bonus, the back-slide.
- **Second awakening, the owl** (`:shin`, 真の姿 the "true form"; decision 8). In Jilliel, once a Kikon or Soul Break has left him
  with **1–4 Konpaku**, **P** revives him: his Konpaku go to **1** and his Reishi is refilled; the stance is gone and U is a
  plain guard again. No running cost (decision 15).
  - Damage ×1.2 and Kikon 4.
  - L is **裁きの光明 SABAKI NO KŌMYŌ**, the arm chop that runs a line of golden blasts along the ground.
  - SP2 is **神の喇叭 TROMPETE**: a 60 f wind-up, then a 2.4 m-wide beam to the wall. **Reflecting it** with a perfect Hoho
    started f48–f60, or a **perfect guard** (a fresh U press on f50–f58), returns half its damage onto him, staggers him
    60 f and **breaks his halo**: Trompete is sealed for the match (decision 9).
- **The CPU** (§11): it zones at 8–20 m with the aim line and Steps out when a string touches it. It opens the eye on a
  roll per threat, uses the stance only as a reaction (≤ 3 s, anti-stall) and revives when the race can be won.
  **Opponents get two keys read off his kits**:
  - `:opp-aim`: Step off a locked line, Hoho behind a long aim, dash in inside 12 m;
  - `:opp-reflect`: time a guard to Trompete.
- **Cinematics** (five; review-3 pacing, every shot `shot-on` its subject; §10): the awakening (the third eye-opening, "tantamount to
  heresy"), the base Kikon 万物貫通, the Jilliel Kikon 神の裁き, the revival, the owl Kikon 神の喇叭.

---

## 3. Identity and silhouette (the model sheet is the reference; this is what the code must keep)

- **Base**: 182 cm, the default rig. White trousers with a buttoned green front panel, a white sleeve on the right arm and a
  bare left arm, a long green fur stole with three buttons, and the green fur bicorne (the points sit left and right).
  Dark skin #7A6155 (the style's saturation cap), cream crew cut, **the left eye shut under the ring-of-four-arcs mark**.
  No cloak in combat.
- **Diagramm**: about 2.4 m long. A thin barrel runs through a fur sleeve, crossed at the rear by a tall black plank; the
  muzzle is a black cross. There is no scope, only a small dial knob on the plank. It is held at the hip pointing forward
  (idle) or shouldered with the open right eye along the barrel (aim). The J / K strikes use the plank (the butt) and the
  barrel's cross (the muzzle). The FK reach test measures the muzzle cross (the weapon tip) and the plank at a
  negative weapon-length point (§12 Art).
- **Jilliel**: a holed, cream-white column with a face window near its top, ending in two prongs, floating 0.6 m up (the
  hurt cylinder stays on the ground, so flight is visual only). Eight flat blade wings, each with three oval holes, are
  fanned round him in **muted jade** (decision 11), with a wide thin halo. **No arms**: the J / K strikes are wing blades.
  The 24 holes are the muzzles.
- **The owl**: a white body on **two long thin legs, each forking at the knee into two shanks** (it reads as four; decision 20), long thin arms, a segmented S-neck and a tiny barn-owl face. A small
  spiked halo and gold (#B89A5A) only on the wings, the halo and the glow.
- **The eye mark is the motif**: the scope reticle on the aim line's far end, the HUD's eye pips and the trumpet bell's
  ring are the same glyph (`:lb-reticle`, baked once).

---

## 4. Base kit: 万物貫通 THE X-AXIS (form `:base`) [V names; G mechanics]

### 4.1 The one resource: 眼 ME, the left eye [V ch. 645–646; G mechanic]

| Rule | Value (knob) |
|---|---|
| Pips | **3** (`*lb-eyes*`), full at the start, **never refilled** in the match (canon scarcity), kept through Kikon resets |
| Trigger | a **deliberate tap**: a U press after U has been **up for ≥ 10 f** (`*lb-eye-rest*`), so a held or re-pressed reactive guard never opens it, while an opponent hit window (move or hazard) is active now or within **8 f** and overlaps his hurt cylinder grown by 1 m (the perfect Hoho's threat test, `perfect-hoho-p`, with a shorter look-ahead: `*lb-eye-lead*` 8 against Hoho's 12). From idle, walk, run and the recovery of a Step; **not** in a move, hitstun or blockstun (U is already held there). Implementation: a kit `:tick` hook (a form with a `:u` hook loses its guard, fighter.lisp:410) sets the existing `fighter-invuln` (Ichigo's slot, ichigo.lisp:363) |
| Effect | he is **intangible 16 f** (`*lb-eye-phase*`, `fighter-invuln`): every hit in that time resolves to nothing, no damage, no stun, no chip, no guard drain. He keeps his state (the tap is also a guard press), and the attacker's hit is a **whiff** for the string gate (a link-1 whiff stops the string, R + 8 / R + 12: the punish) |
| A miss | a press with no threat in the window is a plain guard press: nothing spent (the risk is the timing, as for the perfect Hoho) |
| Third opening | the awakening gauge is set to **100** (EVOLUTION) unless he has awakened already; the line 「三度も眼を開かされるとは…」 as a brush callout. P still awakens (a choice) |
| Look | the left eye opens (a face-texture swap on the hit frame), the reticle mark flares jade, a ghosted afterimage where the hit lands; the pip turns from shut ― to open ◉ |
| Not in the other forms | Jilliel and the owl keep the left eye open (no pips; §5.6 named removal) |

Why a pip and not a gauge: three discrete openings are canon's own count, and a finite resource can't be farmed. An
escape that costs nothing on a miss is fair because it needs a deliberate tap timed like a perfect Hoho, and it is gone
after three. The rest rule (U up ≥ 10 f) keeps ordinary guarding, a human's or the CPU's generic guard reflex, from
spending the pips by accident.

### 4.2 J / K grid (DUEL_STRINGS §2.1 budget; the lightest strings in the roster) [G]

The rifle is long, but he fights with its butt plank and its muzzle cross at close range: short, light, defensive.
**Damage before `*lille-mult*`** (proposed 1.0; Senjumaru's 25 / 1.6 are the comparison).

| Link | Move | S / A / R | Dmg | Adv (block) | Reach (art) | Notes |
|---|---|---|---|---|---|---|
| J1 | 床尾打 SHŌBI-UCHI `:lb-j1` | 8 / 3 / 12 | 22 | −2 | 1.45 m | the plank swung up from the hip, flinch |
| J2 | 返し KAESHI `:lb-j2` | 7 / 3 / 13 | 22 | −2 | 1.45 m | the plank's backhand |
| J3 | 銃口突 JŪKŌ-TSUKI `:lb-j3` | 9 / 3 / 18 | 28 | −4 | 1.6 m | the muzzle cross jabbed, stagger (+5); `:ender` |
| K1 | 銃身薙 JŪSHIN-NAGI `:lb-k1` | 17 / 4 / 21 | 48 | −3 | 2.05 m | the barrel swept flat (K ≥ J + 0.5), stagger |
| K2 | 振り下ろし FURIOROSHI `:lb-k2` | 20 / 4 / 24, `:enter` 6 (S_eff 14) | 48 | −3 | 2.05 m | the barrel brought down |
| K3 | 零距離 REI-KYORI `:lb-k3` | 21 / 5 / 34, `:enter` 7 (S_eff 14) | 70 | −20 | 2.15 m | the muzzle pressed in and fired point-blank (a melee hit, not `:ranged`: it pays KŌSEI), crumple; `:ender` |
| J2s / K2s | copies (`defmove-copy`) | | | | | |

- `:l-after-k :lb-x-quick`: **K → L** fires a 6 f snap shot (no aim, 40 flat, line 12 m, `:ranged :x-axis :uncatchable`)
  as a string ender: his only cash-out from a close string, scaled as hit 3 or 4.
- No `:l-after-j`.

### 4.3 L 万物貫通 X-AXIS SHOT `:lb-x-axis` (hold) [V ch. 601–602, 644; G frame data]

| Phase | Frames | What |
|---|---|---|
| Raise | f0–10 | Diagramm shouldered, the right eye to the barrel; turning at 60°/s; hittable (no armour) |
| Aim (tracking) | f10–34 (24 f) | **planted** (no walk), turning at **60°/s** toward the opponent (`*lb-aim-track*`); the **aim line** is drawn from the muzzle to the wall in **grey** (drawn by the kit's `:draw` hook from `fighter-hold` and his yaw: cosmetic, no sim entity) |
| **Lock** | f34 | the line turns **jade** and **stops turning** (track 0 from here to the shot, the fire frame included): the direction is committed |
| Release | L released at any time; the hold is `:hold (34 64)` (counted from move frame 0); auto-fire at f64 | the reticle at the line's far end contracts; the shot fires at **max(release + 4, lock + 10)** (`*lb-x-delay*` 4, `*lb-lock-min*` 10): **at least 10 f between the visible lock and the shot** |
| Fire | **active 2 f** | a **line hit**: `(:cap 0.6 31.0 1.2 0.25)` from the muzzle (the arena is 30 m across), `:ranged :x-axis :uncatchable` (§8). Hits every fighter on the line; summons and hazards on the line don't stop it (a hit window never collides with hazards: verified); a KASA catch doesn't stop it |
| Recovery | 26 f (whiff +6) | the recoil, the plank drops |
| Cancel | Step or U from f10 until the lock | he may abort the aim (a Hoho behind him, a rush) at the cost of the time spent |

- **Damage by distance** d (centre to centre at the fire frame): **40 + 80 × clamp((d − 4) / 16, 0, 1)**: 40 at ≤ 4 m, 80 at
  12 m, 120 at ≥ 20 m (× `*lille-mult*`). Combo scaling as usual. On hit: stagger, knockback 1.0 m (2.0 m at ≥ 12 m).
- **Blocked** (a guard, West's ward, a `:shield` window such as KASA, a `:parry-block`): **15 % of the hit through as chip**
  (the hitwin's existing `:chip`, never kills) and a **guard drain of 30** (the hitwin's `:guard`), `:adv-block −14`
  (blockstun 14 f). So a full gauge breaks on the **4th** blocked shot. **Not changed**: Kenpachi's stance absorbs it
  (full damage, as any absorbed hit), armour takes it (full damage), DRINK drinks half; none of them pay the guard gauge
  (DUEL_DESIGN §4). Zero Rukia's optic ward lets it through as a full hit; Rukia at −18 / −50 °C is `:chipless` (no chip).
- **Dodged**: before the lock, by out-turning him (a Step's slide sweeps 716 / d °/s, so it beats 60°/s within 12 m; a
  run within v / 1.05 m: 8–9.5 m), or by Hoho; **after the lock, by any Step or walk off the line** (0.65 m from its
  centre: a Step clears it by its f4, a walk in 11 f). The shot always gives ≥ 10 f to see the lock; a HARD CPU
  (8 f) can Step on it, a human must read it. **A perfect Hoho** works against it (the window is a hit window).
- **Hoho at range**: a Hoho reappears behind him at any distance (rules.lisp:65–71). Against a long aim it is the
  strongest answer (30 flash-step), which is why the aim can be cancelled into U or Step before the lock.
- **KŌSEI**: none (ranged). **No cooldown**: the aim time and the 26 f recovery pace it. Minimum cycle 34 + 10 + 2 + 26
  = **72 f** (1.2 s).
- **Callout**: 万物貫通 as a brush column the first time in a match, then the reticle only.

### 4.4 The rest of the buttons

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| Shift+K (SP1) | 三連 SANREN `:lb-sanren` | 12 / 3×(2) / 24 | 30 × 3 (flat) | 1 bar; three unaimed X-axis lines at f12, f22, f32, turning 90°/s between shots (the 2nd and 3rd follow a Step); each line 20 m, `:ranged :x-axis :uncatchable` (chip 15 %, drain **12** each); three hit windows (each hits once); cancels a landed J / K link (`:cancel`). The anti-sidestep tool, paid with a bar |
| Shift+L (SP2) | 飛廉脚 HIRENKYAKU `:lb-hiren` | 20 / 2 / 22 | the shot (by distance) | 1 bar; a 6 m back-slide over f0–14 (**no** iframes: decision 1 refused a strong escape), then at f20 a quick X-axis shot from where he lands (the §4.3 line and damage, `:ranged :x-axis :uncatchable`, track 0 after f14) |
| I | Breaker (derived, universal frame data) | | 150 | the plank slammed down |
| O | 照準 SHŌJUN, the Kikon module `:lb-kikon` | aura 8, no dash | 70 | the lane module (Rukia's / Senjumaru's `:look :lane`): `(:cap 0.5 12.0 1.2 1.2)`, guardable like every Kikon strike (no `:x-axis`); the follow-up dash is a Hirenkyaku afterimage (`:follow-speed 14`). Kikon **2**; cinematic `lb-kikon-cine` (§10.2) |
| U | guard + the eye (§4.1) | | | |
| Walk / run | 3.4 / 8.5 m/s | | | `*walk-lille*`, `*run-lille*` |

### 4.5 What the base form plays like

Keep 8–20 m and aim; lock where he will be, then pick the moment to fire (10–30 f after the lock) against his Step.
Each blocked shot takes 30 off the gauge, so four end in a GUARD CRUSH, which pulls a turtle out of his shell; the
locked line itself pushes him sideways, away from approaching. When someone reaches him, he Steps back or SP2s out and guards; when
a string comes he times the eye. He loses up close: J1 22 against Kenpachi's 35, and K links that lose to a J1.

---

## 5. The awakened kit: 神の裁き JILLIEL (form `:jilliel`) [V look and names; G mechanics]

### 5.1 The awakening

- Generic: P on EVOLUTION (decision 7's third eye fills it, as does the usual gauge); heals 20 %; the cinematic
  `lb-jilliel-cine` (§10.1). Once.
- Kit: `:awakening t :form-name "JILLIEL" :walk 3.0 :run 8.0 :mult *jilliel-mult* 1.0 :taken *jilliel-taken* 1.1
  :kikon-konpaku 3 :guard-to :jilliel-mujittai`. The left eye is open (no eye pips).

### 5.2 U: 無実体 MUJITTAI, the intangible stance (decisions 3–5)

Two kit forms, as Yamamoto's East / West: `:jilliel` (`:guard-to :jilliel-mujittai`: U enters the stance) and
`:jilliel-mujittai` (`:drop-to :jilliel`, **no `:keep`**: every kit command drops it on its frame 0;
`:passives (:ward :intangible)`, `:u-tag "U: MUJITTAI"`). It **is West's ward** with one flag: everything keyed on
`:ward` works for it unchanged (GUARD HOLD, the 360° guard state, `ward-drop` on a crush or a Breaker, Kenpachi's cut
×1.5, the HUD, the CPU's anti-ward rule), and the `:intangible` flag changes three numbers in the ward branch.

| Rule | Value |
|---|---|
| Enter | U held from idle / walk / run (not in a move, a reaction, blockstun or guardless); up 2 f later (`*guard-raise*`) |
| A hit on him | **passes through**: no damage, no stun, no blockstun, **no chip** (hitwin chip, blade chip and East's pierce all skipped), **no push**. Its **guard value** is drained × `*mujittai-mult*` **1.0** (West's `*ward-mult*` is 1.1); for the attacker it is **contact** (a block for the string gate and KŌSEI), so a string continues and keeps draining. A hazard drains its 12 and passes. An X-axis shot in the mirror drains its 30 |
| The gauge | **never refills** in the stance (GUARD HOLD, as West); no self-drain (decision 14). **Outside the stance, Jilliel's refill is cut hard**: `:gg-regen` **0.36** (× the universal 5.5 / s = **2.0 / s**; `*jilliel-gg-regen*`, the user's 「大減」), so a stance that ran the gauge down stays down: 0 → 100 takes 50 s + the delay |
| Empty | the stance drops to `:jilliel` and **GUARD CRUSH** (40 f, guardless: U can't enter the stance until the gauge is full again, as for any guard) |
| What lands anyway | a **Breaker** (Guard Break 50 f, drops the stance, drains 35: West's `ward-drop`) and **unguardables** (South's bind, a red victim's Kikon follow-up, Senjumaru's spikes, Rukia's freeze touch) as normal hits. An opponent's perfect-Hoho counter strike is not unguardable: it **passes** like any hit (West's ward blocks it too) |
| Kept | walk, run, Step, Hoho (decision 5); the stance survives a Step's iframes and a Hoho |
| Dropped | J, K, L, SP1, SP2, I, O (each on its frame 0; a refused command doesn't drop it). **His own perfect-Hoho counter strike also drops it** (it is an attack; one line in his `:tick`, since it is not a kit command). A Burst needs hitstun, which the stance never gives, so it can't start from the stance |
| Look | the wings fold round the column, the jade dims to a ghost tone, the column turns half-transparent; a pass-through ripples the wings |
| HUD | the form tag `U: MUJITTAI` (`hud-guard`), the guard bar as West's |

Why the guard value is the price: the stance is a guard with no blockstun and no chip. The opponent's answers are the
three West already has: pressure (each hit drains; the gauge never refills), the Breaker, and waiting until he must
attack. Kenpachi's NOMIHOSE cut (×1.5 on Flash / Signature / SP) empties it faster, so the Kenpachi matchup leans on that.

### 5.3 J / K (wing blades, the base budget)

Eight wings, the front pair striking. There are no arms, so there is no rifle up close.

| Link | Move | S / A / R | Dmg | Reach |
|---|---|---|---|---|
| J1 / J2 / J3 | 翼刃 YOKUJIN 1–3 `:lb-w-j1…` | as base (§4.2) | 24 / 24 / 30 | 1.6 / 1.6 / 1.7 m (the front wing tips) |
| K1 / K2 / K3 | 双翼 SŌYOKU 1–3 `:lb-w-k1…` | as base (§4.2) | 50 / 50 / 72 | 2.2 / 2.2 / 2.3 m |

Damage before `*jilliel-mult*` 1.0. No K → L.

### 5.4 The rest of the awakened buttons

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| L (hold) | 翼の斉射 WING VOLLEY `:lb-volley` | raise 8, track f8–24, **lock f24**, `:hold (24 54)`, fire max(release + 4, lock + 10), active 2, R 24 | **55** flat | **five lines** fanned at −12°, −6°, 0°, +6°, +12° (`*volley-spread*` 6°), each `(:cap 0.6 31.0 1.2 0.2)` with its own yaw, **one hit window holding five volumes** (so one line at most hits a fighter: `collect-melee` hits once per window; gap G11), `:ranged :x-axis :uncatchable` (chip 15 %, drain **18**). The fan's width: 1.7 m at 4 m (a Step clears it), 4.25 m at 10 m (it doesn't), 8.5 m at 20 m with 2.1 m gaps (a fighter standing in a gap is missed): **mid range is its range**. Track and lock as the base shot |
| Shift+K (SP1) | 三連 SANREN (wings) | as base | 30 × 3 | inherited (the lines start from the wings) |
| Shift+L (SP2) | 二十四孔 NIJŪSHI-KŌ `:lb-nijushi` | 40 / 6 / 30 | **180** | **2 bars** (awakened SP2). All 24 holes glow for 40 f (the tell: planted, `:track` 60°/s until f20, then 0). Then a **1.2 m-radius beam** to the wall (`(:cap 0.6 31.0 1.2 1.2)`), `:ranged :x-axis :uncatchable`: chip 15 %, drain **45**. A Step taken by f40 clears it (1.2 + 0.4 m < 2.5 m) |
| I | Breaker (derived; the column rams) | | 150 | |
| O | 神の裁き Kikon module `:lb-w-kikon` | aura 8, no dash | 70 | lane `(:cap 0.5 12.0 1.2 1.2)`, guardable (no `:x-axis`); Kikon **3**; cinematic `lb-jilliel-kikon-cine` |
| U | 無実体 (§5.2) | | | |

### 5.5 What Jilliel plays like

He floats at 8–14 m. He volleys, and when something comes at him he holds U and lets it pass while the gauge falls, then
shoots once it whiffs. The CPU's stance can't catch a J1 (perception 8–24 f + 2 f raise > S 7–10): it answers K links,
L, SPs and projectiles; a human can stand in it beforehand. Up close the wing blades reach further than the base butt, but every attack is a moment he is
solid.

### 5.6 Removed base tools (sidegrade rule 2, named)

The **normal guard** (U is the stance; he can't block a thing while attacking or after the stance breaks), **the eye** (3
pips), **the precision shot** (the 120 at 20 m; the volley is flat 55), **HIRENKYAKU** (SP2 is now the beam), and some walk
(3.4 → 3.0). Taken ×1.1 (`*jilliel-taken*`): when he is solid, he is fragile.

### 5.7 Why it is a sidegrade

- **Better against** pressure and zoning that is not a Breaker: Yamamoto's waves and pillars, Senjumaru's zones, Rukia's
  rings. Each drains the gauge and nothing more.
- **Worse against** Breaker-happy rushers (Kenpachi, Ichigo) and against Kenpachi's ×1.5 cut: the stance falls fast, and
  he has no guard when it does.
- **Base precision vs the volley**: the base form's 120 at 20 m is the biggest ranged hit in the game. The volley is flat
  55 and gives up that range, but it catches Steps at mid range.

---

## 6. The second awakening: the owl, 真の姿 (form `:shin`) [V ch. 650–653; A ep. 37; G mechanics]

### 6.1 Entry (decision 8)

| Rule | Value |
|---|---|
| Condition | form `:jilliel` or `:jilliel-mujittai`, **and** the flag **BEHEADED** is set, **and** free: idle, guard or the stance (the kit predicate checks the state itself, since the P command's generic `awaken-state-p` would also allow blockstun and a combo reaction) |
| BEHEADED | set when a **Kikon or a Soul Break settles on him in Jilliel** and leaves him with **1–4 Konpaku** (`*lb-revive-konpaku*` 4), through a new generic `:settled (def lost left)` kit hook called by `settle-konpaku` (gap G7; a Kikon reaches `:struck` before it is settled, and a Soul Break's count exists only there). It stays set for the rest of the match (P may wait) |
| Command | **P** (the phone's AWAKEN chip) |
| On entry | form `:shin`; **Konpaku := 1**, **Reishi := full** (`bankai!`'s generic part, decision 8; it also breaks the attack like a Burst: `repel!`, 20 f invulnerable); guard gauge, Reiatsu, flash-step and cooldowns kept; the stance gone; the cinematic `lb-revive-cine` (§10.3). `bankai!`'s arm-meter line is skipped for a form without `:pips` (gap G7) |
| Once | structural: `:shin` has no `:bankai-form`, and there is no way back to Jilliel |
| Prompt | the awakening row blinks 「P  REVIVE」 in gold while it is allowed (Kenpachi's 「P BANKAI」 path, `bankai-allowed-p` + a kit predicate, gap G7) |

The generic Bankai path (`:bankai-form`, `bankai-allowed-p`: free with ≤ `*bankai-konpaku*` 4 Konpaku) is reused, with
one generic kit predicate added for BEHEADED (gap G7). The Konpaku := 1 and the Reishi refill are Kenpachi's code.

### 6.2 The owl kit

`:awakening t :form-name "SHIN" :walk 4.0 :run 9.0 :mult *shin-mult* 1.2 :taken 1.0 :kikon-konpaku 4`;
U is a plain guard (200°, the universal gauge).

| Input | Move | S / A / R | Dmg | Rule |
|---|---|---|---|---|
| J / K | 鉤爪 KAGIZUME (the long arms) | base budget (§4.2) | J 26 / 26 / 32, K 54 / 54 / 78 | reach J 1.7, K 2.3 m (long thin arms) |
| L | 裁きの光明 SABAKI NO KŌMYŌ `:lb-sabaki` | 16 / – / 24 | 90 | the arm chop at f16 sends a **ground line of golden blasts** from 1 m to 18 m, erupting outward at 40 m/s (a delayed line hazard of his own kind through the `:hook` path, **not a `:rift`**, which `close-rifts` cancels when its owner is hit; 0.6 m wide; each point hits once, 0.4 s life; `:x-axis :uncatchable`: chip 15 %, drain 18). A sideways Step from where he aims always clears it; the eruption's travel time (0.45 s to 18 m) leaves time to see it |
| Shift+K (SP1) | 三筋 MISUJI | 18 / – / 26 | 70 | 1 bar; three Sabaki lines at −20°, 0°, +20° at once, **one hit group** (a fighter is hit by one line at most; gap G12) |
| Shift+L (SP2) | **神の喇叭 TROMPETE** `:lb-trompete` | wind-up **60** / active **30** / R 40 | **240** | **2 bars**. The fist at the beak (f0), the golden trumpet with its plume forming overhead (f10–60, the tell: rising pitch, planted, **turning 30°/s until f40, then locked**); then a **beam 2.4 m wide** (radius 1.2) to the wall for 30 f (`(:cap 0.6 31.0 1.4 1.2)`, one window: one hit per fighter), `:ranged :x-axis :uncatchable`. Blocked: chip 15 %, drain **60**. Once he is locked a Step clears it (1.2 + 0.4 m < 2.5 m). The reflect: §6.3. Sealed after a reflect |
| I | Breaker (derived; the four legs stamp) | | 150 | |
| O | 神の喇叭 Kikon module `:lb-o-kikon` | aura 10, no dash | 80 | lane `(:cap 0.5 12.0 1.4 1.4)`, guardable; Kikon **4** (Kenpachi's Bankai value); Soul Break 5; cinematic `lb-trompete-cine` |

### 6.3 The reflect: Hakkyōken's rule (decision 9)

| Rule | Value |
|---|---|
| Who | the opponent, around Trompete's **first active frame** (f60) |
| Perfect Hoho | a Hoho **started f48–f60** that the beam makes perfect: instead of its counter strike, the **reflect**. (The universal test also accepts f61–f89 against a 30 f window; those dodge as a normal perfect Hoho, with its counter strike, but don't reflect) |
| Perfect guard | a guard **started f50–f58** (`fighter-guard-t` at f60 between 2 and 10; with `*guard-raise*` 2 a press on f59 or later isn't up yet), held through f60, facing him (the 200° arc). A guard raised earlier only blocks (chip + drain 60) |
| Who can't | **Bankai West** (its guard time counts from entering West: Hoho only), **KESSA** (no guard: Hoho only), **zero Rukia** (rooted, an optic ward: she can't reflect and must not stand in its line). The A/B logs the reflect source per pairing |
| Reflect | the beam turns back along its line: **he takes 50 % of it** (120 × 1.2 = 144) as a real hit (it can Soul Break him; red or not, it is not a Kikon) and **staggers 60 f**. His **halo breaks**: Trompete is **sealed for the rest of the match** (SP2 refused; the HUD halo cracked) and the owl's O module keeps working. The reflector takes nothing; a "REFLECT" callout and a mirror-flash |
| Why not more | the beheading already took him to 1 Konpaku. A reflect that also ended the form would leave him with no last-stand tools; the seal removes the one move that made the form worth the gamble |

### 6.4 What the owl plays like, and the gamble

With one Konpaku, any Kikon or Soul Break on him is the K.O. So the owl wins only by taking the opponent's Konpaku first.
He has Kikon 4, ×1.2 damage, Trompete's 288, and Sabaki's ground lines. Against a fresh opponent with 9 Konpaku, three
owl Kikons are needed; against one at ≤ 4, one. The CPU rule (§11) revives only when that race can be won.

---

## 7. Kikon counts and events

| Form | Kikon | Soul Break (+1, cap 5) |
|---|---|---|
| base | 2 | 3 |
| Jilliel / MUJITTAI | 3 | 4 |
| owl | **4** | **5** |

The fewest events to K.O. 9 Konpaku stays two (owl Soul Break 5 + a 4), as for Kenpachi's Bankai.

---

## 8. Hit and guard rules this kit adds (one place)

Most of it is existing code (the review of 2026-10-06 checked each against the source):

| Rule | How |
|---|---|
| **Through guard**: a **blocked** hit (a guard, West's ward, a `:shield` window, `:parry-block`) lets 15 % through as chip and drains the move's `:guard` | **existing**: the hitwin's `:chip 0.15 :guard 30` (kit.lisp:31–35, combat.lisp:284–291) and `:adv-block −14`; stance absorb, armour and DRINK resolve as for any hit (no change) |
| **Never caught** by KASA | **new**: the `:uncatchable` flag, one test at combat.lisp:279 (gap G2) |
| **The flags per move** | `:ranged :x-axis :uncatchable`: the X-axis shot, the K → L snap shot, SANREN, HIRENKYAKU's shot, the volley, NIJŪSHI-KŌ, Sabaki, MISUJI, Trompete. **None** of them on the Kikon lanes (a Kikon strike stays guardable) or on any J / K (K3's point-blank shot is melee) |
| **Distance damage** | **existing**: an `:on-frame` hook on the fire frame sets `fighter-dmg-bonus` (the hit carries it as `pending-bonus`: damage = the hitwin's 40 + bonus) |
| **The eye** | **existing slot**: his `:tick` hook sets `fighter-invuln` 16 on a qualifying tap (§4.1); every hit then resolves to nothing, a whiff for the attacker |
| **MUJITTAI** | **existing ward** + the `:intangible` passive: one test in the ward branch (drain × `*mujittai-mult*`, no push, no chip); Jilliel's `:gg-regen` 0.36 (a multiplier) is an existing kit key (gap G4) |
| **The lock** | his `:tick` sets the move's tracking to 0 from the lock frame; the fire frame from `fighter-hold` (no shared change) |
| **Reflect** | Trompete's own `:hit` hook reads the defender's `fighter-guard-t` (2–10 at f60) and the Hoho start frame (lille.lisp only) |
| **BEHEADED** | a new generic `:settled (def lost left)` kit hook in `settle-konpaku` (gap G7) |

## 9. HUD and the one-hand controls

- **Base: 眼 ME.** Three eye pips (the reticle glyph) in the kit-meter row; a used pip shows the open eye in jade. The
  label is the brush 眼 + `ME n`. The third opening flashes the awakening row (EVOLUTION).
- **The aim line** (both players see it): a thin ink line on the floor from the muzzle to the wall, grey while it tracks,
  jade once it locks (it stops turning; the shot is ≥ 10 f away), and the reticle at its far end. It is not drawn for the CPU's own view (there is none) but it
  is in the replay.
- **Jilliel**: no kit meter. The guard bar carries the `U: MUJITTAI` tag; in the stance the guard bar is outlined jade
  and drains (never refills) as West's.
- **Owl**: the halo icon in the meter row, whole or cracked (sealed). The name line reads "LILLE  SHIN". While BEHEADED
  holds in Jilliel, the awakening row blinks 「P  REVIVE」.
- **Distance tag** (base only): next to the reticle on the aim line, a small number for the damage the shot would deal
  now (40–120 × mult). It shows only to a human playing Lille.
- **Portrait**: the same pips / halo in the portrait meter slot; `portrait-label` `ME n` / `MUJITTAI` / `HALO`.
- **One hand** (DUEL_MOBILE_DESIGN §15.1): the **L chip held is the aim** (Rukia's SP1 hold path: the chip's down state is
  the hold), and releasing it fires. The thumb ring shows three eye ticks (base). **A resting thumb is a guard**: in the
  base form the eye needs a deliberate tap after ≥ 10 f with U up, so a resting thumb never spends a pip. In Jilliel the resting thumb is the
  stance (as West). In the owl it is a guard. Note: the stance gives a phone player a strong default; the gate does not
  measure phones, so this is a playtest item.

---

## 10. Cinematics (60 Hz, review-3 pacing; unskippable; every shot `shot-on` its subject)

### 10.1 The awakening `lb-jilliel-cine` (186 f) [V ch. 646]

| Shot | Frames | What |
|---|---|---|
| close | 0–30 | the face, the left eye shut under the mark; silence |
| the eye | 30–60 | the left eye **opens** (the third time); the mark flares jade; a 1 f negative |
| caption card | 60–120 | black card, jade back-rim: the line 「三度も眼を開かされるとは 異端に等しい」 as a brush column, the brush **神の裁き** with the reading JILLIEL |
| the cocoon | 120–160 | the body sheathed in the cream column, eight wings unfold one pair per 8 f, the halo draws itself |
| wide | 160–186 | from below, the winged column hovering, the opponent small |

### 10.2 The base Kikon `lb-kikon-cine` 万物貫通 (168 f) [V ch. 601–602]

The reticle view (the eye-mark ring), the shot, then the cross-shaped hole of light through the opponent's silhouette,
held. Last card: 万物貫通 with the reading THE X-AXIS.

### 10.3 The revival `lb-revive-cine` (180 f) [V ch. 649–650]

The headless column falls still; silence 30 f. It rises into the air, the jade turning to gold over 30 f, and the owl head
grows on the S-neck from light. The caption 「武器では死なず 霊圧で首を落としても尚死なない」, then the wide shot with
four stilt legs and a small spiked halo.

### 10.4 The Jilliel Kikon `lb-jilliel-kikon-cine` 神の裁き (162 f) and the owl Kikon `lb-trompete-cine` 神の喇叭 (186 f)

Jilliel's Kikon is 24 lines out of the wings, the opponent pinned at their crossing. The owl's is the trumpet's sound card:
the beam erases the horizon, and then there is silence. The 神の喇叭 card carries the reading TROMPETE.

---

## 11. AI (`:ai` per form; generic code in ai.lisp; difficulty scales every chance)

### 11.1 Tables

| Form | Intents (A / P / Z / D) | Ranges | Bands (lo hi weights) | Other keys |
|---|---|---|---|---|
| **base** | 1 / 1 / **5** / 2 | **Z 8–20 m**, D 5–9, P 1.3–2.2 | 0–2.2 `:q 4 :f 2 :breaker 1 :step 2`; 2.2–6 `:sp2 2 :step 2 :sp1 1 nil 1`; 6–30 `:sig 6 :sp1 1 nil 1` | guard 0.5, hoho 0.3, dash 0.3, **dash-back 0.7**, block-string 0.3, o-ender 0.3, `:l-after-k 0.4`, kikon-range 7.7, `:awaken (:min-taken 150)`, **`:eye (:p 0.5)`** (§11.2), **`:sig-hold lb-aim-hold`**, `:opp-aim` (§11.3) |
| **jilliel** | 1 / 1 / **4** / 2 | Z 8–14, D 5–9, P 1.4–2.4 | 0–2.4 `:q 3 :f 3 :breaker 1 :step 1`; 2.4–8 `:sig 3 :step 2 nil 1`; 8–16 `:sig 5 :sp2 1 nil 1`; 16–30 `:sig 2 :step 1 nil 2` (dash in) | **`:stance (:p 0.6 :max 180)`** (§11.2), hoho 0.3, dash 0.4, dash-back 0.5, kikon-range 8.5, **`:bankai (:p 0.9 :opp-konpaku 4 :own-konpaku 1)`** (the generic Bankai key: its nothing-to-lose rule and the 31000+10a+b A/B already exist, ai.lisp:264–280), `:opp-aim` |
| **shin** | 3 / 4 / 2 / 1 | P 1.4–2.6, Z 6–16 | 0–2.6 `:q 4 :f 4 :breaker 1`; 2.6–8 `:sig 3 :sp1 2 :step 1`; 8–20 `:sp2 3 :sig 2 nil 1` | guard 0.4, hoho 0.3, dash 0.8, o-ender 0.6, kikon-range 9.0, **`:trompete (:when-recovering t :far 8)`**, `:opp-reflect` (§11.3) |

### 11.2 His own reflexes (each rolls once per event, never per step; every lead is the *perceived* one)

- **`lb-aim-hold`** (`:sig-hold`, which returns a hold length at the press): **34 + a rolled 10–30 f** after the lock
  (HARD rolls nearer 10, i.e. fires on the lock against a still opponent, and nearer 30 against a strafer: the
  opponent's lateral speed is read once, at the press). No early release: a `:sig-hold` is fixed at the press
  (ai.lisp:138), and the CPU's reflexes don't run inside a move (ai.lisp:363).
- **The eye** (`:reflex`; it **takes over from the generic guard reflex** in the base form). On a threat it perceives
  (the generic perception delay, 8 / 14 / 24 f by difficulty: the lead is `s − sf − delay`, as Ichigo's perfect-Hoho
  reflex at ichigo.lisp:858, never the true sim state), it rolls once per threatening window:
  - `:eye :p` × difficulty (EASY 0.25, NORMAL 0.5, HARD 0.75): a **tap** of U, only if U has rested ≥ 10 f and a pip is
    left;
  - otherwise a guard held from now, or a Step if the threat is a lane.
  The third pip is used the same way; P then follows the generic awaken rule.
- **The stance** (`:reflex`, Jilliel): when it perceives an opponent move starting within its reach + 1 m, or a hazard /
  ranged threat within 12 f, it rolls `:stance :p` → U. It can't catch a J1 (§5.5). It **leaves the stance by
  attacking**:
  - on the opponent's whiff or recovery;
  - after `:max` 180 f (3 s, anti-stall);
  - when the gauge is below 30.
  It never holds the stance while the opponent is out of reach and idle (no turtling).
- **Revive**: the generic `:bankai` reflex. Once the kit predicate allows it, P with p 0.9 when the opponent has ≤ 4
  Konpaku or his own Konpaku are already 1. Otherwise it waits (BEHEADED stays).
- **Trompete**: SP2 only when the opponent is ≥ 8 m away **or** in a recovery / reaction (a punish), never into an idle
  opponent within 8 m.

### 11.3 Opponents facing him (two keys read off his kits through `:opp-reflex`, ai.lisp:380; every other pairing's hash stays)

- **`:opp-aim (:step 0.6 :hoho 0.25 :rush 12)`** on `:base` and `:jilliel`. A CPU whose opponent is aiming (a `:hold`
  move with `:x-axis`) rolls once per aim:
  - **after it perceives the lock** (jade; the shot is ≥ 10 f away), with p `:step` × difficulty, a sideways Step off the
    line (HARD perceives in 8 f and makes it; NORMAL's 14 f and EASY's 24 f are late, so they **pre-Step** at a rolled
    frame between the lock and lock + 10);
  - **before the lock**, with p `:hoho` × difficulty (if flash-step ≥ 30), a Hoho behind him (the strongest answer to a
    long aim, rules.lisp:65–71);
  - **within `:rush` 12 m**, the dash-in / O rush instead (Senjumaru's `:opp-rush-hold` path, generalised).
- **`:opp-reflect (:p 0.3)`** on the `:shin` kit: × difficulty (EASY 0.1, HARD 0.5), once per Trompete, a guard pressed
  at a perceived f52 (or a Hoho at f50 when the guard is unavailable).
- **The existing reflexes that would misread his 31 m lines** (gap G1): the generic threat test (ai.lisp:486 counts any
  move within reach + 1.5 m from its first frame, so every CPU would guard through each aim and each wind-up and feed
  the crush), `ken-hoho-commit` (ken.lisp:497) and Ichigo's perfect-Hoho / guard reflexes (ichigo.lisp:791, 803, 858,
  897), which would perfect-Hoho, and so reflect, most Trompetes at HARD p 1.0. For moves flagged `:x-axis` only,
  they use the point-to-line distance and the move's real active window (not the hold phase). The old moves keep the old
  test, so the old pairings stay byte-identical.
- **MUJITTAI**: the anti-ward rule (ai.lisp:62, 191) keys on the `:ward` passive, which the stance carries. Nothing new.

---

## 12. Build list and the generic gaps (character code in `lille.lisp` / `lille-art.lisp`; shared files get hook points only)

| Gap | Where | What |
|---|---|---|
| G1 | ai.lisp, ken.lisp, ichigo.lisp | threat perception for `:x-axis` moves only: the point-to-line distance and the real active window (§11.3) |
| G2 | combat.lisp | `:uncatchable` (KASA's catch skips it). Everything else of "through guard" is the existing hitwin `:chip` / `:guard` |
| G3 | — | none: distance damage is `fighter-dmg-bonus` set from an `:on-frame` hook |
| G4 | combat.lisp | the `:intangible` passive inside the ward branch: drain × `*mujittai-mult*`, no push, no chip (hitwin chip, blade chip, East's pierce) |
| G5 | — | none: the reflect reads `fighter-guard-t` and the Hoho's start in Trompete's own hook |
| G6 | hud.lisp | the kit meter `:draw` for eye pips / halo (Senjumaru's pattern); the `:u-tag` for MUJITTAI |
| G7 | combat.lisp, fighter.lisp | a kit predicate `:bankai-ok` beside `bankai-allowed-p` (BEHEADED + idle / guard / stance); `bankai!` skips the arm-meter line when the form has no `:pips`; a generic `:settled (def lost left)` kit hook in `settle-konpaku` |
| G8 | ai.lisp | `:opp-aim`, `:opp-reflect` (read off his kits) |
| G9 | debug.lisp, DUEL_GAMEPLAY | `roster-pairs` already makes LY LK LR LI LS LL (k 15–20; group 2141); claim the character range **79000–79999** |
| G10 | tests | `duel-rules-test`: the load list, `*forms*` (four: `:base :jilliel :jilliel-mujittai :shin`), clips, weapons, `*roster*` (six), the FK reach list. Host tests: distance damage; four blocked shots crush; stance / armour / DRINK unchanged by `:x-axis`; the lock (no turn after f34, fire ≥ lock + 10); the eye's rest rule, whiff and third-eye EVOLUTION; MUJITTAI pass / no chip / Breaker / drop on attack / no refill, Jilliel's 2.0 / s refill outside it; BEHEADED + the revive cost; the reflect edges (Hoho f47 / f48 / f60 / f61; guard f49 / f50 / f58 / f59); one hit per volley and per MISUJI |
| G11 | kit.lisp, engine hitvol | a `:vols` key in `parse-move` (several volumes in one hit window) and a **yaw offset on `:cap`** (today a cap runs along the facing only, engine/lisp/hitvol.lisp:19–27, 46–54): the volley's five lines |
| G12 | hazards.lisp | a hit group shared by several hazards (MISUJI's three lines overlap near him: 0.34 m apart at 1 m) |

**Art** (`lille-art.lisp`; the rig is the fixed 21-joint humanoid, anim.lisp:48):
- Bodies: `:lille` (base), `:lille-jilliel` (the column + the wings, armless to the eye) and `:lille-shin` (the white
  body, the S-neck and the owl head).
- **Jilliel's front wing pair is parented to the arm chains**, so the J / K wing-tip strikes are measured at the hands
  (`*strikers*` entries). The other six wings are static parts.
- **The owl's extra legs** are static parts on the hips; its arms are the rig's arms, lengthened.
- **The base strikes**: the J plank strikes are measured at a negative weapon-length point (the butt), the K and J3 at
  the muzzle cross (the weapon tip). So the FK reach test (±0.15 m) covers every J / K; no `*lb-strike-reach*` bypass.
- Weapons: Diagramm and the trumpet prop. Strikes for three J / K grids.
- Looks:
  - the aim line, from the `:draw` hook (not a hazard);
  - the volley, beam and ground-line looks;
  - five cinematics.
- Glyphs (万 物 貫 通 眼 神 裁 喇 叭 翼 斉 射 光 明 無 実 体 二 十 四 孔 三 連 飛 廉 脚 照 準 鉤 爪 真 姿 異 端 筋 …)
  are baked with `tools/glyph-bake.py`, which needs `fonttools` + `skia-pathops` installed in the container.

**Order** (one character, one branch; a subagent per batch):
1. rules + host tests;
2. the base kit;
3. Jilliel;
4. the owl;
5. the AI;
6. the HUD;
7. art;
8. the cinematics;
9. the gates.

---

## 13. Balance plan

**Every existing pairing must stay byte-identical** (G2 references, the 15 pairings at seeds 1–20). Everything above is
behind his kit, his hit flags or keys read off his kit.

**The gate grows by six pairings** (k 15–20, debug 2141; 21 pairings, 420 matches). Predictions:

| Pairing | Median guess | Why | Risk |
|---|---|---|---|
| **LY** | 140–180 s | two zoners, but Yamamoto's waves are blocked chips and his Bankai West's ward is drained by the shots | > 210 if both stand off |
| **LK** | 125–150 s | Kenpachi closes and wins up close; Lille's eye and back-slide stretch it | **Lille wins too little** |
| **LR** | 140–190 s | Rukia's rings vs lines (−18 / −50 °C are `:chipless`: no chip from his shots); **zero Rukia is rooted**: her optic ward takes every shot as a full hit at full distance damage | **a rooted zero is free prey**: the user's call (a Rukia or a Lille knob), not pre-tuned |
| **LI** | 135–175 s | Ichigo's rushdown vs the eye; KESSA's parry can't catch a ranged hit | — |
| **LS** | 150–200 s | Senjumaru's zones drain the stance; the shots go through KASA | > 210 |
| **LL** | 170–210 s | a mirror (allowed past 210) | the timer |

- **Win targets**: each new pairing 10 ± 3 of 20.
- **Awaken A/B** (the current criterion, the user's 2026-09-28 decision): P1 Lille in "never awaken" wins ≥ 20 / 60 on
  each of three streams (100 / 300 / 500) against each opponent.
- **The revival gamble test** (Kenpachi's Bankai §9 pattern): LY / LK over seeds 1–60 with the existing Bankai A/B
  (31000 + 10a + b: always / never). The win-rate difference must be within ±9 / 60.
- **Pacing log** (`duel lille` lines, the companion regex already accepts any tag):
  - shots aimed / fired / hit / guarded / stepped / run-across, by distance band;
  - damage by distance;
  - eye openings and what they dodged;
  - awakening tick;
  - stance frames, passes, Breaker breaks, crushes;
  - volleys;
  - BEHEADED / revive ticks;
  - Trompete fired / hit / guarded / reflected, and the reflect's source (Hoho / guard) by pairing;
  - stance time per match and the longest stance (the stall watch, decision 14).

**Knobs, in order**:
- **Medians over 210 s**: the base Z intent 5 → 4, `:opp-aim :rush` 12 → 15, the shot's recovery 26 → 30, the stance
  `:max` 180 → 120 (the CPU's own cap; a self-drain was offered and declined, decision 14).
- **Under 125 s**: `*lb-x-guard*` 30 → 22, the far damage 120 → 100.
- **Lille wins too much**: `*lb-lock-min*` 10 → 14, the far damage 120 → 100, the stance's `*mujittai-mult*` 1.0 → 1.2,
  `*jilliel-gg-regen*` 0.36 → 0.27 (2.0 → 1.5 / s).
- **Too little**: `*lille-mult*` 1.0 → 1.3 (Rukia / Senjumaru precedent), the eye window 8 → 10, J1 22 → 26,
  `*lb-lock-min*` 10 → 8.
- **The A/B, awakening an upgrade**: `*jilliel-taken*` 1.1 → 1.2, the volley 55 → 48, `*mujittai-mult*` → 1.2.
- **The A/B, awakening a trap**: the volley spread 6° → 5°, `*jilliel-taken*` → 1.0, the stance enter 2 f → 1 f.

---

## 14. Adversarial self-critique

1. **"Through guard" against the sidegrade note's advice** (research sidegrade_design Q4 B.4: a zoner's projectiles should
   not crush from full screen). The user chose the drain (decision 2). What keeps it fair: the shot is a lane, and after
   the lock one Step clears it. It needs a 34 f aim with a visible line, then ≥ 10 f between the lock and the shot, and
   he is planted throughout. The drain needs four blocked shots, about 4.8 s at the minimum cycle. A guard is the wrong
   answer to it on purpose, and the gate measures it.
2. **The first draft let the line track after release** (the review of 2026-10-06, its blocker): a Step out-turns 60°/s
   only within 12 m, so from 12–20 m the shot was a blind guess or a guard. Fixed by **the lock**: from the jade frame
   the line doesn't turn, and the shot is ≥ 10 f away. Before the lock, the answers are the out-turn, the Hoho, or
   cancelling his aim by rushing.
3. **The eye has no cost on a miss.** It is timed like the perfect Hoho, but Hoho costs 30 flash-step. Three uses, no
   refill: at most three free escapes a match. Kept. **The rest rule** (a tap after U was up ≥ 10 f) stops a reactive
   guard spending it, which the first draft would have done in the first exchanges (the generic guard reflex presses U
   during active frames).
4. **MUJITTAI and the phone**: a resting thumb is the stance. A phone player in Jilliel turtles by default, and the
   gauge is the only clock on that. Playtest item, noted in §9.
5. **The owl at 1 Konpaku.** Any K.O. event ends him, so is the revival ever worth it? The CPU rule only revives when it
   is free (own Konpaku 1) or the opponent is ≤ 4. The gamble test checks it either way.
6. **Rooted zero Rukia vs the sniper**: zero can't Step. With 120 a shot at 20 m, LR could fall below 125 s. The answer
   would be the user's (a Rukia knob or a Lille knob); noted, not pre-tuned.
7. **Hit-window lines of 31 m**: the AI's threat test, `snap-reach` and two characters' reflexes were written for ≤ 12 m
   (G1). Restricting the fix to `:x-axis` moves keeps the old pairings byte-identical; it is still the riskiest change.
9. **MUJITTAI and the timer** (found by the review): the stance needs no held button and running keeps it, so a leading
   Lille could run out the clock; only a Breaker or an unguardable reaches him. The user declined a self-drain and chose
   West's rule plus a much slower refill outside the stance (decision 14): the stance is still unbounded in time, but
   every hit it takes is gone for ~50 s. **Open risk**, watched by the pacing log; the CPU's own cap is 180 f.
10. **A free revival** (found by the review): at 1 Konpaku the revive costs nothing, heals fully and breaks the attack
    like a Burst. The user kept it without a cost (decision 15); the gamble test (§13) shows whether it is an upgrade.
11. **Through guard vs stance, armour, DRINK**: the first draft would have turned those full / half hits into 15 % chip,
    and drained gauges that DUEL_DESIGN §4 says they never pay. Now only blocks are X-axis'd. (Found by the review.)
8. **Trompete's reflect is a human's read**: a guard started on f50–f58 (a 9 f window) after a 60 f wind-up with a rising
   pitch, or a Hoho started on f48–f60. That is generous on purpose: the owl is already at 1 Konpaku. Three forms can't
   perfect-guard (West, KESSA, zero Rukia; §6.3).

## 15. Canon ledger

| Item | Canon |
|---|---|
| X-Axis through barriers, Nimaiya shot through two guards | [V] ch. 601–602 |
| The left eye: three openings, then the Vollständig | [V] ch. 645–646 |
| Jilliel: eight wings × three holes, constant intangibility | [V] ch. 646 |
| Intangibility as a stance broken by a Breaker and by attacking | [G] (decisions 3–5) |
| The 24-hole blast cutting the city | [V] (med) |
| Beheaded by the Bankai, revives owl-headed | [V] ch. 649–650 |
| Sabaki no Kōmyō as the owl's chop | [V] (med; the wiki's version) |
| Trompete, reflected by Hakkyōken, halo broken | [V] ch. 653 |
| The reflect as a perfect Hoho / perfect guard | [G] (decision 9) |
| Every frame number, damage and distance | [G] |
| Move names 床尾打, 銃身薙, 零距離, 三連, 翼刃, 双翼, 鉤爪, 三筋, 照準 | [G] invented |

## 16. Questions for the user

Answered 2026-10-06: decisions 12–15 (§1). The volley (five lines, 6°, one hit, 55 flat) and Trompete (60 f, 2.4 m wide,
2 bars, 240; the reflect on a Hoho f48–f60 or a guard f50–f58) stand at the proposed defaults.

## 17. Modelling references

The user (2026-10-06): 「請順便整理利傑巴羅各型態的參考圖作為建模依據」, and after opening the network policy: 「我以變更網路政策，請再次嘗試整理利傑巴羅各型態的參考圖作為建模依據」.

- The sheet: `docs/research/tybw-characters/notes/lille_barro_model_sheet.md` (per form: silhouette, parts, proportions
  re-measured from the official full-body visual, colours sampled from the stills, poses, what the ink style may simplify,
  the source list with page and file URLs).
- The pictures: 49 images (anime stills, the official digital colour manga, the official site's visual) in the
  git-ignored `.refs/Lille-Barro/` (`base/ diagramm/ jilliel/ owl/ trompete/`, `INDEX.md`, one contact sheet per form);
  third-party art, never committed.
- What the images corrected (the sheet has the full list): he fights without the cloak; Diagramm is about 2.4 m, a thin
  barrel through a fur sleeve crossed at the rear by a tall black plank, no telescopic scope; the eye mark (a ring of four
  arcs with four inward ticks) is also the reticle and the trumpet bell's ring; Jilliel is a holed column with a face
  window and eight flat blade wings with three oval holes each; the owl form is white with gold only on the wings, halo
  and glow, on four stilt legs.
- **Decision 11 (2026-10-06), the colours** (the sheet's §9): Jilliel's green is a **muted jade** (「低彩度玉色」; not a
  fourth spot hue, not the manga's pale gold-white): an ink tone, so the style keeps its three spot hues FIRE, REIATSU,
  BLOOD. The owl form's gold is **Senjumaru's muted gold #B89A5A** (「千手丸的低彩度金」; not REIATSU yellow, which is
  Kenpachi's, and not a near-colourless white-gold), on the wings, halo and glow only; the body stays white.

## 18. Built: deviations (batch 1, 2026-10-06)

Batch 1 (the sim, the kits, the functional art, the host tests, the registration, a basic CPU table) is in
`duel/lisp/lille.lisp` + `duel/lisp/lille-art.lisp`. The smallest faithful deviations from §1–§13, each kept to the
decisions:

1. **The aim's hold is `(40 60)`, the volley's `(30 50)`, each with a 4 f main-phase startup** (the spec wrote `(34 64)` /
   `(24 54)`). The generic hold ends at max(release, lo) or hi, so the shot fires on max(release + 4, lock + 10), by itself
   on f64 (the volley f54): exactly decision 12's rule (`lb-fire-frame`, host-tested for every release frame). The lock
   (the line stops turning) stays at f34 / f24, the `:params :lock` the AI batch reads.
2. **Trompete's reflect is decided at the end of its f59** (the step before the beam), so the beam never fires on a
   reflect and the reflector takes nothing. The guard window is the spec's (a press f50–f58 = `fighter-guard-t` 2–10 there).
   The **Hoho window is f48–f59**: a Hoho started on f60 is on its frame 0, not yet invulnerable, so the beam's first frame
   hits it (it could never dodge, so it can't reflect).
3. **The eye is tested in the kit's `:tick`**, after the step's hits: a tap protects from the next step on (the same one-frame
   latency as a guard's raise). The third opening's line 「三度も眼を開かされるとは…」 is a romaji pixel callout for now (the
   brush line is batch 3). The pips live in his per-side state (the HUD meter is batch 3), not the kit meter.
4. **`:bankai-ok` is the kit slot** the AI batch added (a function of the fighter), not a `:hooks` entry; P, the HUD prompt
   and the CPU's Bankai reflex all read it.
5. **`*mujittai-mult*` lives in `tuning.lisp`** (combat.lisp reads it in the ward branch); the knob name is the spec's.
6. **The arms are the strikers**: Jilliel's front wing pair *is* the rig's arm chain (×2.6 long, the tips at the hands),
   and the owl's arms are ×2.2 (1.25 m, not the sheet's 0.9 m) so the hands reach J 1.7 / K 2.3 m. Jilliel floats 0.5 m.
7. **Unspecified numbers chosen**: the base form's damage taken ×1.0; SANREN's lines flinch (kb 0.5), drain 12;
   NIJŪSHI-KŌ / Trompete knock back (2.0 / 3.0 m), −14 on block; SABAKI / MISUJI staggers (kb 1.0); the shot's 2.0 m
   knockback at ≥ 12 m is the `:hit` hook's slide; HIRENKYAKU turns at 90°/s until f14; an aim may also be cancelled by a
   Hoho (the reason §4.3 gives for the cancel).
8. **MISUJI's one-hit group** is tested structurally on the host (three `:fan` lines, one `make-hit-group`); the group's
   own behaviour runs in the native sim (hazards.lisp is not loaded by the host test).

Generic hook points (each inert for the five existing characters: no existing data uses them):
- `engine/lisp/hitvol.lisp` MAKE-VOL / VOL-HIT-P: a `:cap` yaw offset in slot 5 (radians; 0, and a hand-made 5-float vol,
  take the old path unchanged; RAVEN EDGE's rules test passes);
- `duel/lisp/kit.lisp` PARSE-MOVE: `:vols` (several volumes in one window; the window still hits once);
- `duel/lisp/combat.lisp`: `:uncatchable` (KASA's `:catch` skips it), the ward's `:intangible` (drain × `*mujittai-mult*`,
  no push, no chip), BANKAI-OK-P beside BANKAI-ALLOWED-P (P and the HUD), BANKAI! without `:pips` skips the arm meter, the
  `:settled (def lost left)` hook in SETTLE-KONPAKU;
- `duel/lisp/hazards.lisp`: MAKE-HIT-GROUP / the hazard's `group` (one hit for several hazards, one of them a step).

Batch 1's gates (2026-10-06; the AI batch merged underneath): host tests ALL PASS (duel-rules 5714 checks, control, learn,
input, touch, cine; RAVEN EDGE's rules test after the hitvol change); `tools/pkgcheck.sh duel` 0 / 0 / 0; the name-leak grep
empty. **Inert**: `simgate.py --seeds 10`, the fifteen old pairings' 150 rows and their companion lines byte-identical to
the run before the change, every summary line too; `--cvc` PASS (yy / yk / kk). **His six pairings** (seeds 1–10, NORMAL,
every match a K.O.; untuned, batch 4):

| Pairing | Median | Lille wins | Note |
|---|---|---|---|
| LY | 152.5 s | 1 / 10 | |
| LK | 158.0 s | 1 / 10 | 22 blow-aways in 10 matches |
| LR | 154.9 s | 0 / 10 | |
| LI | 178.5 s | 3 / 10 | |
| LS | 170.2 s | 0 / 10 | |
| LL | 241.8 s | 6 / 4 | a mirror (allowed past 210) |

The pacing log per side and match (70 sides): every side awakened, 60 of 70 ended in the owl (the revive fires; the owl
at 1 Konpaku then loses), the eye opened 1.8 times, the stance ~1230 frames a match (~20 s) with ~5 passes, ~2.3 aimed
shots fired and ~2.7 volleys. He loses most of his pairings: the tuning (§13 "too little") and his own reflexes are batches
3–4.

## 19. Built: the CPU (batch 3a, 2026-10-06)

His own reflexes (§11.2) are in `duel/lisp/lille.lisp`'s AI section: one kit `:reflex`, `lb-ai-reflex`, on all four forms,
dispatching on the form, plus the `:sig-hold` `lb-aim-hold-ai`. No shared file changed. Every chance is the kit's `:p` ×
`*lb-ai-diff*` (EASY 0.5 / NORMAL 1.0 / HARD 1.5, capped at 1), so EASY ≤ NORMAL ≤ HARD. Every roll is made once per
event: per threatening window (`lbai-key`: his move's start tick, or a hazard's spawn tick) or per opponent action (the
generic react roll). Every lead is the perceived one, `snap-s − snap-sf − delay`.

- **The eye** (base, `lb-ai-eye`; `:eye (:p 0.5)`). It takes over from the generic guard reflex. On a threat the generic
  test would answer (`lb-ai-threat-p`: an attack in its main phase, live, within reach + 1.5 m, or on an `:x-axis` line;
  not a parry, a bind or a `:reflectable` blast; an aim stays `:opp-aim`'s), it makes one roll (`lb-ai-eye-plan`):
  - **the eye**, if r < p and it can still be made (`lb-ai-eye-ready-p`: a pip, lead ≥ 1, and U rested 10 f by the
    tap). U is let go, then **tapped** (a 2 f press) at a perceived lead of 1–4 f (`*lb-ai-eye-tap*`, inside the sim's
    8). A tap the sim did not take turns into a guard.
  - otherwise, a **Step** off a lane (an `:x-axis` line or a `:look :lane` Kikon module), from a Breaker / grab, or from
    a Kikon while he is red;
  - otherwise, a **guard** held while the threat lives, with `ai-guard-k`'s share of the roll. A low gauge Steps instead,
    as the generic does.
  The third opening gives EVOLUTION; P then follows the generic `:awaken` rule.
- **The stance** (Jilliel, `lb-ai-stance-in`; `:stance (:p 0.6 :max 180 :gg 30)`). It triggers on a move starting within
  reach + 1 m (not a Breaker or a grab, which land on it; those stay generic), or on one of his hazards within 12 f (a
  wave or fireball by its flight time, a delayed one under him). One roll: U (p 0 when the gauge is under `:gg`);
  otherwise a Step off a lane, a Hoho on the generic Hoho roll, or nothing. It never falls through to the generic guard,
  which would enter the stance. `:neutral-guard 0.0` on Jilliel's table keeps the neutral decision from entering it too
  (§2: "only as a reaction"; the `:defend` intent's +0.2 remains).
- **Leaving MUJITTAI** (`lb-ai-stance-out`; deterministic, `lb-stance-exit`). It leaves by attacking (K1 if he stays
  busy for its startup, else J1 in reach, else the volley) when any of these holds:
  - he whiffs or recovers, or is reeling;
  - after `:max` 180 f;
  - the gauge is under 30;
  - he is out of his J / K reach + 1 m and idle.
  The whiff and idle rules wait while one of his hazards is still coming.
- **Trompete** (the owl, `lb-ai-trompete`; `:trompete (:p 0.5 :left 30)`): SP2 as a punish from beyond J's reach, when he
  stays recovering or reeling ≥ 30 more frames (perceived), on the react roll. The neutral bands give SP2 only from 8 m.
- **The aim** (`lb-aim-hold-ai`, `lb-aim-extra`): it fires 10–30 f after the lock. The opponent's lateral speed is read
  once at the press, from two perceived snaps 6 steps apart (`lb-ai-lateral`). The fire frame is centred at lock + 10
  for a still opponent and lock + 30 for one strafing ≥ 3 m/s; the roll spreads it by ±10 × (EASY 1.0 / NORMAL 0.6 /
  HARD 0.25). In 10 seeds of his six pairings, 225 presses read a strafer and 870 a still opponent.
- **Revive**: the generic `:bankai` reflex fires, needing no change (below).
- Host tests: `lb-ai-chance`, `lb-ai-eye-ready-p`, `lb-ai-eye-tap-p`, `lb-ai-eye-plan`, `lb-ai-stance-plan`,
  `lb-stance-exit`, `lb-aim-extra`, and the kits' keys (duel-rules 5722 checks ALL PASS). New pacing counters on the
  `duel lille` line: `ai-eye-plan`, `ai-eye-tap`, `ai-eye-miss`, `ai-guard`, `ai-step`, `ai-stance`, `ai-pass`,
  `ai-exit-{whiff,max,gauge,idle}`, `ai-trompete`, `ai-aim-{strafer,still}`.

**Gates** (NORMAL, untuned: balance is batch 4):
- **Inert**: `simgate.py --seeds 10`'s fifteen old pairings (390 rows and companion lines, 30 summary lines) are
  byte-identical to f7be712.
- `--cvc` PASS (yy / yk / kk).
- pkgcheck 0 / 0 / 0.
- Host tests duel-rules, duel-control and learn ALL PASS.
- `./build.sh duel` succeeds.

His six pairings, seeds 1–20 (every match a K.O.):

| Pairing | Before (f7be712): median, Lille wins | After |
|---|---|---|
| LY | 148.6 s, 4 / 20 | 162.3 s, 4 / 20 |
| LK | 158.0 s, 2 / 20 | 166.5 s, 2 / 20 |
| LR | 154.9 s, 2 / 20 | 161.9 s, 1 / 20 |
| LI | 182.6 s, 4 / 20 | 180.1 s, 5 / 20 |
| LS | 170.2 s, 1 / 20 | 166.0 s, 4 / 20 |
| LL | 241.8 s, P1 12 / 8 | 237.3 s, P1 11 / 9 (a mirror) |

Pacing per Lille side and match, before → after (the five cross pairings; the mirror in brackets):
- **Eye openings**: 1.9–2.2 → 2.2–2.7 (2.2). Of these, 0.4–0.9 are the planned taps; a tap the sim missed is 0.1 at
  most. The third opening's EVOLUTION came in 3–13 of 20 matches before, 10–17 of 20 after.
- **The stance**: 667–1383 → 328–564 frames a match (1766 → 400); the longest stance 233–339 → 93–140 f (327 → 61).
  - Exits per match: whiff 8–11 (17), idle 0.8–1.4, gauge 0.1–0.9, max 0.1–0.3 (0.0).
  - Entries by the reflex: 2.3–3.7. The other stances mostly follow his own hits: the generic guard cancel holds U
    through his recovery, and the whiff rule ends them on the victim's stun.
- **Revive**: 15–20 / 20 → 17–19 / 20 sides (36 / 40); all but 0–3 BEHEADED sides per pairing revive.
- **Trompete**: fired 0.1–0.2 a match before and after; reflected by a guard 0.1–0.2. The punish reflex almost never
  finds a 30 f opening beyond J's reach. The owl lives briefly at 1 Konpaku, and its two bars are rarely there.
- **Aims (shots + volleys)**: 2.5–4.7 → 6.3–12.4 (12.4 → 24.1). The stance's exits fire volleys.

## 20. Measured: batch 4 (2026-10-06)

Batch 4 tuned his own knobs in §13's order (native `simgate.py`, NORMAL; Lille is P1 in LY LK LR LI LS, k 15–19; LL is
k 20). **Verdict: the pacing passes, the win target and the awaken A/B fail; stopped and reported** (AGENTS.md "Edge
rerun": no other knobs turned). The user's call is needed (below).

### 20.1 Knobs (one at a time, each measured at seeds 1–20 and on the never-awaken stream 100)

| Knob | Old → new | Kept | Lille's wins LY / LK / LR / LI / LS (of 20) | "Never awaken" wins, stream 100 (of 60) |
|---|---|---|---|---|
| (start, eef44e0) | | | 4 / 2 / 1 / 5 / 4 | — |
| `*lille-mult*` | 1.0 → **1.3** | **yes** (§13 "too little" #1) | 9 / 4 / 2 / 4 / 5 | 5 / 2 / 1 / 0 / 0 |
| `*lb-eye-lead*` (the eye window) | 8 → 10 | **no**: decision 13 fixes "≤ 8 f before a hit"; measured inert (one row changed) | 10 / 4 / 2 / 4 / 5 | 4 / 2 / 1 / 0 / 0 |
| J1 `:lb-j1 :dmg` | 22 → **26** | **yes** (§13 "too little" #3) | 8 / 3 / 3 / 5 / 5 (with the eye window 10) | 4 / 1 / 1 / 0 / 4 |
| `*lb-lock-min*` (+ the holds (38 60) / (28 50)) | 10 → 8 | **no**: decision 12 fixes "≥ 10 f after the lock"; noise | 5 / 3 / 2 / 7 / 8 | 2 / 1 / 1 / 2 / 3 |

The two kept changes, with their docstring / comment in `lille.lisp`: `*lille-mult*` 1.3 and J1 26. §13's other "too
little" knobs (the eye window, `*lb-lock-min*`) are the user's decisions 12–13, so they were measured and put back.

**Probes, not kept** (to size the gap for the user; each from the kept state, seeds 1–20 / stream 100):

| Probe | Wins LY / LK / LR / LI / LS (of 20) | Never awaken, stream 100 (of 60) |
|---|---|---|
| base CPU kites more (intents A 0 / P 1 / Z 6 / D 3, `:dash-back` 1.0) | 3 / 2 / 1 / 5 / 5 | 4 / 1 / 0 / 1 / 1 |
| `*lille-mult*` 1.6 | 8 / 7 / 3 / 4 / 4 | 10 / 5 / 7 / 3 / 11 |
| `*lille-taken*` 0.7 | 8 / 5 / 4 / 4 / 6 | 7 / 0 / 3 / 8 / 7 |
| `*jilliel-mult*` 1.3, `*jilliel-taken*` 1.0 | 14 / 5 / 2 / 9 / 6 | (no effect by construction: the never side never awakens) |

Where the base form's time goes (a per-frame distance count, a probe removed afterwards; seeds 1–20, the five cross
pairings, the kept state): **83–93 % of it under 6 m** (35–54 % under 2.2 m), 2–5 % beyond 8 m. He fires 0.9–1.6
X-axis shots a match (aimed or HIRENKYAKU's), none from ≥ 14 m. The opponents close in (`:opp-aim :rush` 12 m, the
heat's shrinking range), and his CPU fights them with the roster's lightest strings. In the never-awaken matches (seeds
1–20) the base form deals 200–400 X-axis damage (before ×1.3) in about 3.5 minutes.

### 20.2 The seed gate (kept state)

Seeds 1–20 (`simgate.py --pairs 15,16,17,18,19,20`), before (eef44e0) → after:

| Pairing | Median | Range | K.O. | Wins Lille / opponent | Blow-aways |
|---|---|---|---|---|---|
| Lille vs Yamamoto | 162.3 → **163.7 s** | 120.4–201.9 | 20/20 | 4 → **7** / 13 | 1 |
| Lille vs Kenpachi | 166.5 → **144.5 s** | 123.3–201.9 | 20/20 | 2 → **3** / 17 | 35 |
| Lille vs Rukia | 161.9 → **167.0 s** | 120.7–210.1 | 20/20 | 1 → **3** / 17 | 1 |
| Lille vs Ichigo | 180.1 → **173.1 s** | 135.7–233.7 | 20/20 | 5 → **5** / 15 | 10 |
| Lille vs Senjumaru | 166.0 → **157.1 s** | 101.9–214.5 | 20/20 | 4 → **5** / 15 | 4 |
| Lille vs Lille | 237.3 → **212.1 s** | 144.9–259.2 | 20/20 | P1 11 → 6 / 14 (a mirror) | 0 |

Every match a K.O.; every cross median inside 125–210 s (the mirror may exceed 210). **Wins are outside 10 ± 3 in four
of five pairings** (LY 7 is the edge). The 60-seed rerun (seeds 1–60):

| Pairing | Median | Range | K.O. | Lille's wins of 60 | Blow-aways |
|---|---|---|---|---|---|
| LY | 155.8 s | 120.4–201.9 | 60/60 | **21** (35 %) | 1 |
| LK | 155.2 s | 99.5–229.8 | 60/60 | **7** (12 %) | 103 |
| LR | 159.8 s | 95.3–232.6 | 60/60 | **8** (13 %) | 8 |
| LI | 176.5 s | 110.3–233.7 | 60/60 | **13** (22 %) | 38 |
| LS | 166.4 s | 101.9–257.8 | 60/60 | **15** (25 %) | 14 |
| LL | 215.7 s | 144.9–302.0 | 60/60 | P1 22 / 38 (a mirror) | 2 |

Still outside 10 ± 3 of 20 (30–65 %) in every cross pairing but LY: **reported, not tuned further**.

Pacing (seeds 1–20, per Lille side): 15–19 of 20 sides end as the owl (35 / 40 in the mirror); eye openings 2.0–2.7;
stance 300–550 frames a match; 5–14 aims (shots + volleys).

### 20.3 The awaken A/B (Lille P1 "never awaken", 39020; the opponent on its own rule; wins of 60)

| Stream | vs Y | vs K | vs R | vs I | vs S |
|---|---|---|---|---|---|
| 100 | 4 | 0 | 1 | 0 | 4 |
| 300 | 3 | 3 | 0 | 0 | 3 |
| 500 | 3 | 3 | 0 | 2 | 2 |

**Fails every cell** (≥ 20 needed). Only the base form plays in it, so Jilliel's and the owl's knobs can't move it; the
§13 "awakening an upgrade" knobs would only lower his gate wins further.

### 20.4 The revival gamble test (LY / LK, seeds 1–60, Lille P1 `:bankai` always 31010 / never 31020)

| Pairing | Always | Never | Always − never | Median always / never |
|---|---|---|---|---|
| LY | 18 | 16 | **+2** | 152.6 / 155.5 s |
| LK | 8 | 6 | **+2** | 149.5 / 158.1 s |

Within ±9 / 60: the revival is a gamble, not an upgrade or a trap (passes). The CPU's revive filter is unchanged.

### 20.5 The CPU and ASSIST

- `aieval.py --char 5`: score **0.285**: strength (HARD, both seats) **0.025**, masher **0.979**, signature **0.371**;
  pacing OK (medians 144–172 s, 100 / 100 K.O.).
- `assistgate.py` (NORMAL, seeds 1–20, the masher P1 vs the CPU P2): the masher's win % over all 36 pairings per
  setting k (AUTO GUARD + 3 × COMBO + 6 × BREAK): k0 59, k1 71, k2 98, k3 60, k6 68, k10 80, k11 98.
  Lille's rows (wins of 100 over the five cross pairings; the mirror of 20):

  | k | 0 | 1 | 2 | 3 | 6 | 10 | 11 |
  |---|---|---|---|---|---|---|---|
  | the masher playing Lille vs a CPU | 47 | 64 | 96 | 26 | 65 | 60 | 100 |
  | the masher vs Lille's CPU | 22 | 36 | 96 | 65 | 17 | 83 | 99 |
  | the mirror (masher Lille vs CPU Lille) | 0 / 20 | 0 | 18 | 2 | 0 | 9 | 18 |

  A mashing Lille at k0 beats the CPUs 47 % of the time (vs S 18 / 20, R 14, K 10, Y 4, I 1), more than his own CPU
  wins at NORMAL (64 / 300 = 21 % at seeds 1–60). This suggests his CPU's play, not only his numbers, is the weak part.

### 20.6 Inertness and the rest

- `simgate.py --seeds 10`: the fifteen old pairings' 420 lines (rows, companion lines, summaries) byte-identical to eef44e0.
- `--cvc` PASS (yy / yk / kk).
- Host tests duel-rules (5722), duel-control (86), learn (100): ALL PASS (no test pins the changed values).
- `tools/pkgcheck.sh duel` 0 / 0 / 0; `./build.sh duel` succeeds.

### 20.7 For the user (the decision)

The numbers say the base form, as his CPU plays it, can't win a third of its matches alone: even ×1.6 damage or ×0.7
taken leaves the never-awaken side at 0–11 of 60. Options:
1. **Accept the A/B as a known exception** for him (the awakening is the plan of the character: three eye openings
   force it), and tune the gate wins with Jilliel's numbers (the probe `*jilliel-mult*` 1.3 / `*jilliel-taken*` 1.0 gave
   14 / 5 / 2 / 9 / 6 of 20), the order then being Jilliel's knobs.
2. **Rework the base CPU's zoning** (a batch of its own): his CPU fights 85–90 % of the base form under 6 m. A sniper
   needs a way back to range (e.g. HIRENKYAKU without a bar, a faster walk back, or his CPU's own anti-rush reflex).
3. **Raise the base form's numbers past §13's list** (`*lille-mult*` 1.6+, `*lille-taken*` ≤ 0.8), knowing the probes
   show these alone don't reach the A/B.

### The user's decision on the failed gates (2026-10-06)

「先試玩再決定」: play it first, then decide. The options offered and not chosen:
- a way back to range for the base form (a kiting CPU reflex, HIRENKYAKU on a cooldown instead of a bar);
- accept the A/B as an exception and tune the win rate with Jilliel's numbers;
- both.

The balance stays at batch 4's state until the user's playtest of the build with batch 3b's art and cinematics.

## 21. Built: art, HUD, cinematics (batch 3b, 2026-10-06)

The look of §3, §9 and §10, built from the model sheet and the reference pictures (looked at one by one; third-party art, never
committed). Everything here is cosmetic: the sim never reads it (inertness below).

**Bodies** (`lille-art.lisp`):
- **Base**: the green fur bicorne worn crosswise (a fur rim low on the brow, a dome, two fur ridges left and right rising to
  their points at the front, the white crown between them as a stripe from the brow over the top, a steel emblem disc on
  each side, jagged fur on the rim); the long fur stole from the neck over the right shoulder down the right chest
  (three grey buttons on its inner edge, jagged fur on its outer one, ringing the back of the collar); the green front
  panel's notched point; the left eye shut under **the ring of four arcs with four inward ticks** (12 strokes, no hull).
- **Jilliel**: the holed cream column (four holes near the top, six near the bottom, flush ink discs), its face in a round
  window (the mouth covered, both eyes open), two horn points, two prongs. The front wing pair stays on the arm chains
  (batch 1's strikers; the FK reach test is unchanged): a flat blade, narrow at the root, widest at the elbow, a pointed
  tip at the hand, three oval holes (dark, a light core), a torn trailing edge.
- **The owl**: the hind stilts moved behind the rig's legs and splayed back (batch 1's read in front); a shaggy fur ruff;
  the **segmented S-neck** (five segments rising back then forward over, belly plates in front, a fur crest behind); a
  tiny barn-owl face (a pale round facial disc in a dark rim, two big ink eyes with glints, a small hooked beak, the hair
  swept back); long thin arms with long fingers.

**Props and the draw hook** (`LILLE-DRAW`; its draws 0 B: f32vec arguments, frames filled by macros, the alphas pre-boxed; see Consing):
- **The wing blade** (one prop, unit length): a convex leaf, four teeth on the trailing edge, three oval holes. Jilliel's
  other six are fanned round the column at +40 / +10 / −42° a side (the arms at −12° between: the sheet's fan), muted jade;
  **MUJITTAI folds them** down round the column (5 / s), see-through (0.7), and **a pass-through ripples them** (the guard
  gauge dropping in the stance: ±14°, 0.5 s). NIJŪSHI-KŌ's 40 f tell lights the 24 holes. The owl draws the same blade eight
  times in gold, half open.
- **Halos**: Jilliel's wide thin flat jade ring (⌀ 0.96 m, 0.52 m over the column, breathing); the owl's small ring with six
  spikes (⌀ 0.26 m), **broken once Trompete is sealed** (a piece out, an arc dropped and tilted, a spike lying; gold
  shards when it cracks).
- **The aim line**: on the floor from under the muzzle to the wall, grey (3.5 cm) while it tracks, jade (6 cm) from the
  lock; **the reticle** (the eye mark, the motif) lies on it where the opponent stands: 1.1 m and turning while it tracks,
  snapped to 0.65 m at the lock (the lane's half-width: what a Step must clear), closing to 0.47 m between the release and
  the shot. The volley: its five lines fanned, the same colours. His `:charge` hook replaces the generic fire charge at the
  muzzle (FIRE is Yamamoto's) with a jade glint once locked.
- **The eye opening**: a ghosted afterimage where the hit lands (the Hoho afterimage, `START-GHOST`), the left eye open over
  the lid for 0.7 s (a face overlay prop in the head's frame: the white, a jade iris), the mark flaring jade along its X
  for 0.35 s.
- **Trompete**: the golden horn (no valves, the bell's outer ring on four struts, five plume feathers) grows over his head
  from f10 to f60, its bell before him gathering a gold star; the beam leaves the bell. **The reflect**: a white mirror
  hexagon flashes at the reflector, a gold band runs back onto him, the halo cracks.
- **Hazard looks** (`LB-LOOK`, toon fx; see Consing): the shots are toon ribbons at the volume's height (jade when aimed, ink
  for a snap shot) with a white core and the muzzle's cross flash on their first frames; NIJŪSHI-KŌ / Trompete a wide toon
  band (jade / gold, a white core) as wide as the volume; the Kikon lanes a floor line; SABAKI's ground line gold tongues
  erupting along its burning span over a thin gold sheet.
- Two **toon fx palettes** were added for these (engine, `fx-toon-pal.wgsl`): 13 JADE (#9CC4AC body, #6E9A80 shade) and 14
  GOLD (#D8C080, #B89A5A): ink tones of the existing scheme (decision 11), not spot hues.

**HUD** (§9; hud.lisp's existing kit-meter `:draw` / `:label`, `:hud-guard` and `:deck` hooks):
- base: three **eye pips** (the reticle glyph; unspent: the shut eye ― in a white ring, the last one pulsing; spent: the
  open eye in jade) and the brush **眼 + ME n**; the third opening's line 「三度も眼を開かされるとは」 as a brush column at his
  side (batch 1's romaji callout is replaced by it on screen);
- Jilliel: no meter (U's tag says `U: MUJITTAI`); in the stance the guard bar is **outlined jade**;
- the owl: the **halo icon**, whole or cracked, and HALO / SEALED;
- 「**P  REVIVE**」 in gold while BEHEADED allows it (Kenpachi's BANKAI prompt path, the words and colour from his meter);
- the **distance tag** (a human Lille only): the damage the shot would deal now (40–120 × his damage ×) next to the
  reticle, grey while tracking, jade once locked;
- portrait: the same pips / halo in the meter slot; the label ME n / MUJITTAI / HALO (SEALED).

**One hand**: the L chip held is already the aim (its down state is `:sig`); his `:deck` ring shows three eye ticks over the
thumb ring in the base form (white unspent, jade spent).

**Cinematics** (§10; lille.lisp's last section; 60 Hz, unskippable, every shot `shot-on` its subject, review-3 pacing):
| Script | Frames | Shots |
|---|---|---|
| `lb-jilliel-cine` | 186 | the base face close (his body shown as the base form for the beat), silence 30; the left eye opens, the mark flares, 1 f negative; the black card, jade back-rim, 「三度も眼を開かされるとは / 異端に等しい」 then 神の裁き / JILLIEL as he becomes the column (f92); the cocoon: the wings unfold a pair per 8 f, the halo draws itself; from below, the winged column, the opponent small |
| `lb-kikon-cine` | 168 | the aim held; over his shoulder (a portrait screen: from straight behind and above, his head low, the line rising), the reticle closing round him, silence 50; the shot, the jade line; his silhouette on the white card with a cross of light through it, held 44 f in silence; the Konpaku shatter; the last card 万物貫通 / THE X-AXIS |
| `lb-revive-cine` | 180 | the headless column (the face tagged `:jl-head`, hidden) still, silence 30; it rises, the jade wings turning gold f30–f60, a ball of light where the head grows (the owl's body from f66); the card 「武器では死なず / 霊圧で首を落としても尚死なない」 SHIN NO SUGATA; the wide shot: the stilts, the spiked halo, one long arm raised |
| `lb-jilliel-kikon-cine` | 162 | the card 神の裁き / KAMI NO SABAKI, the holes lit; from the side, 24 jade lines out of the wings crossing on him; on him, held in silence; the shatter; the winged column |
| `lb-trompete-cine` | 186 | the fist at the beak, the note; the trumpet forming over him; the sound card 神の喇叭 / TROMPETE, silence 50; the beam erasing the horizon, a gold flash; the shatter; 46 f of silence, the world draining grey |

Stills: debug 79100 + 19 i + k (cinematic i at frame 10 k), 79195 the consing probe, 79196 an eye opening's look
(DUEL_GAMEPLAY "Debug commands").

**Sounds** (`defsound`): `:lb-crack` (the shot: a dry crack, a low thump, a tail), `:lb-lock` (the lock: a dial click and a
glint), `:lb-trumpet` (a brass note swelling a fourth: Trompete's tell). The emits in lille.lisp's mechanics now name them
(the lock, the aimed shot, Trompete's tell; sound only).

**Glyphs** baked (tools/glyph-bake.py's `GLYPH()`, the Yuji Syuku subset, appended in lille-art.lisp): か さ ず で と な を 器 圧
姿 尚 武 異 端 等 落 開 霊 首 (19).

**Generic hooks** (each inert for the other characters: nothing else uses them):
- `duel/lisp/main.lisp` DRAW-FIGHTER: a kit `:body-alpha` hook (the body's draw alpha; default 1) and a `:charge` hook (drawn
  instead of the fire charge of a held move);
- `duel/lisp/hud.lisp` HUD-SIDE / HUD-SIDE-PORTRAIT: the BANKAI prompt's words and colour may come from the kit meter's
  `:bankai-prompt` (default the old strings and BLOOD);
- `engine/shaders/fx-toon-pal.wgsl`, `fx-toon.frag.wgsl`, `engine/lisp/fx.lisp`: toon palettes 13 JADE and 14 GOLD (the
  shader clamps to 14 instead of 12; no existing call passes more than 12);
- `duel/lisp/kit.lisp`: the defkit docstring lists them.

**Deviations** (the smallest, each kept to the design):
1. **The reticle sits where the opponent stands on the line**, not at the wall: at 20–30 m the wall end is off screen or a
   speck, and the ring's radius at the lock is the lane's half-width, which is what the opponent has to read.
2. **The line is drawn on the floor** (§9 says so), not at the muzzle's height as batch 1 drew it.
3. **MUJITTAI's see-through is the engine's translucent draw** (the dark phantom of Ichigo's clones), the column at 0.72, the
   wings and halo at 0.7: a light ghost is not available without a shader change. Needs the user's eyes.
4. **The owl's wings**: batch 3b lightened them to #CDB47A because #B89A5A "reads brown in the toon shade at play
   distance". That overrode the user's decision 11, so the lead restored **#B89A5A** (the teeth #9A8048, a darker step of
   the same hue) at the merge. The lighter gold goes to the user as a playtest question.
5. **The cinematics' length is sim time** (`*MATCH-TICK*` runs during a cinematic): the placeholders were 120 f, the five are
   186 / 168 / 180 / 162 / 186, so his six pairings' match times move (below).

**Inertness** (2026-10-06): host tests ALL PASS (duel-rules 5714, control 86, learn 100, input 33, touch 64, cine 18);
`tools/pkgcheck.sh duel` 0 / 0 / 0; the name-leak grep empty. `simgate.py --seeds 10`: **byte-identical** to the run before
the change (602 lines) with the cinematics at the placeholders' 120 f; at the designed lengths the fifteen old pairings
and their companion lines are identical and his six pairings keep every winner, form and pacing count, only their
seconds and tick stamps move by the longer cinematics (LILLE YAMAMOTO seed 1: 145.6 → 149.1 s). `--cvc` PASS.
Their medians (seeds 1–10) before → after: LY 152.5 → 155.3, LK 158.0 → 161.9, LR 154.9 → 158.1, LI 178.5 → 182.8,
LS 170.2 → 173.4, LL 241.8 → 250.3 s (all K.O.). The balance pass re-gates these.

**Consing** (debug 79195, logged as `lille consing`): the props, wings, halos, reticle, trumpet and HUD draw 0 B; what is
left is the floor of this build's ECS lookups, **8 B per component lookup** (`fighter`, `model`, `transform` each box their
result; measured 80 B per 10 calls): the draw hook 16 B a frame (fighter + model), 24 B while aiming, during Trompete or
in MUJITTAI (+ transform); each Lille hazard's look 8 B. Removing that floor is an engine change (out of this batch).

---

## 22. Rework (decisions 16–20, 2026-10-06): the stance, the two modes, the rig

Every number is a proposal until the gate (the §13 targets stand). Names: [G] ours.

### 22.1 Base L: 狙撃構え SOGEKI-GAMAE, the shooting stance `:lb-kamae` (decision 17) [G]

| | Value |
|---|---|
| Stance | up at **f6**, held **30 f** (a tap) or up to **90 f** while L is held, R 14; no defence (hit as neutral); **tracks at 60°/s** (`*lb-aim-track*`) with the grey aim line drawn; walk off (planted) |
| Charge | frames spent in the stance (the dash's frames included; `*lb-charge-f*` **24**): the line glows brighter at 24 |
| L 万物貫通 `:lb-k-shot` | **locks on the press** (jade, track 0), fires **10 f later** (`*lb-lock-min*`: the visible-lock rule stays), active 2, R 26. **Quick** (charge < 24): **40 flat**. **Charged** (≥ 24): **40 + 80 × clamp((d − 4) / 16)** (40–120). × `*lille-mult*`. Blocked: chip 15 %, drain 30, −14 (§4.3) |
| J 零距離 REIKYORI `:lb-k-j` | S8 A3 R18, a 2.0 m lunge, the muzzle jammed in and fired: **40**, stagger, reach 1.8 m, −6 on block, guard 8 (a melee hit, guardable, not `:x-axis`) |
| K 薙払 NAGIHARAI `:lb-k-k` | S16 A4 R28, Diagramm swept flat, 2.6 m 180°: **80**, crumple, **guard 30**, −10 |
| Step 飛廉脚 HIRENKYAKU `:lb-k-dash` | **3.5 m in the stick direction (neutral: away from him)** over 12 f, iframes f0–8, afterimages; back in the stance at f6 with the charge kept (dash back, then the charged shot: the kite); **once per stance**, 10 flash step |
| L after a K link | the stance entered at f4 (2 f to its f6): every branch combos off K1 / K2 / K3 (host test) |

- The old hold shot `:lb-x-axis` goes (the stance replaces it). Cycle: f6 + 24 + 10 + 2 + 26 = 68 f (the old 72).
- SP1 SANREN and SP2 HIRENKYAKU stay (SP2 overlaps the stance's dash; reviewed after the playtest). U (guard + the eye),
  I and O unchanged.
- **CPU** (Ichigo's `tsuki-step` pattern, at the stance's f6, rolled once): ≥ 8 m hold to the charge then L; 3–8 m the
  dash back then the charged L (or the quick L on a whiffed recovery); ≤ 3 m K on a guard (or a gauge < 50), else J;
  after a K link's hit L 0.6 / J 0.4. Bands: the stance `:sig` in every band (the old `:sig` slots).

### 22.2 Jilliel: 遠 EN (ranged) and 近 KIN (melee), L switches (decision 18) [G]

Forms: `:jilliel` (EN, floating, as built) and its stance `:jilliel-mujittai`; `:jilliel-kin` (KIN, the owl's forked
legs) and its stance `:jilliel-kin-mujittai`. The awakening enters EN. Both modes: taken ×1.1, `:gg-regen` 0.36, U =
MUJITTAI (§5.2, unchanged), I the Breaker, O the Kikon module (direct, Kikon 3), P the revival (decision 16).

| | Value |
|---|---|
| L 転身 TENSHIN `:lb-switch` (both modes) | **frame 0: every live trace materialises** (below); a flash-step dash **3.5 m at him (EN → KIN) or away (KIN → EN)** over 12 f, iframes f0–8, 10 flash step; the form changes at f6; R 8. At most one every **30 f** (`*lb-switch-cd*`). Also cancels his own J / K / SP1 from their active end (EN: always, the lines never hit; KIN: as a K link's L) |
| EN: J / K / SP1 | **mobile**: the stick walks him at 3.0 m/s through the whole move (facing kept toward the opponent); **no hit window**: each line is laid as a **trace**: J1–J3 one line, K1–K3 a fan of three (−6°, 0°, +6°), SP1 SANREN its three (1 bar) |
| EN: SP2 NIJŪSHI-KŌ | 2 bars, the 40 f tell (planted, not mobile), then a **thick trace** (radius 1.2 m) |
| Trace | a static line in the world (from where the wing was, at its yaw, 31 m, radius 0.6; SP2 1.2), drawn faint jade on the floor with a pulse; **at most 8** (a 9th drops the oldest), **kept until his next switch** (gone on a revival or at the round's end) |
| Materialising | at the switch's frame 0, every trace is a 2-frame hit `:ranged :x-axis :uncatchable` (each hits a fighter once; **a K's fan of three is one hit group**: at most one of its lines hits a fighter (`make-hit-group`; the lead's merge fix, 2026-10-06: at 5 m all three overlapped him, 72 for one K); several in one window count as one combo): J line **30**, K line **24**, SP1 line **30**, SP2 **180**; × `*jilliel-mult*`. Blocked: the X-Axis rule (chip 15 %, drain 18 a line, 45 SP2) |
| KIN: J / K | the wing-blade strings (§5.3: 24 / 24 / 30, 50 / 50 / 72), normal hits; walk **3.8**, run 8.5 |
| KIN: SP1 / SP2 | SANREN as built (direct lines); NIJŪSHI-KŌ as built (the direct beam) |

- The volley `:lb-volley` goes (L is the switch).
- **CPU**: EN at 6–12 m lays K fans and J lines while walking off his line; switches (dash in) when ≥ 3 traces are live
  and the opponent (perceived) stands within 0.6 m of one, or on a whiffed recovery near a trace; KIN runs a string, then
  switches out on a block, a gauge < 40 or after the string. The opponents step off a trace (the batch-2 point-to-line
  perception, one roll per new trace) when his switch is ready.

### 22.3 The rig (decisions 19, 20)

- **Jilliel's wings** are eight separate blades drawn by his draw hook, rooted behind the column's top, **two fans of
  four** (the refs: the upper pair high and out, the lowest pair down and out), curved leaf blades with three oval
  holes. The rig's arms are **not drawn** (hidden in the column); a **striking wing is drawn from its root to the rig's
  hand**, so the wing tip is the hand and the host FK reach test keeps reading the hand (±0.15 m). J swings one front
  wing, K the two front ones, the SPs spread all eight; idle, each wing sways on its own phase; MUJITTAI folds them.
- **The legs** (the owl and KIN): two long thin legs, each **forking at the knee into two shanks** (fore and aft), so it
  reads as four. The owl keeps its long arms (its claws are the hands) and gets the same eight-wing fans in gold.

### 22.4 Built: rules and CPU (rework R, 2026-10-06)

The rules + CPU half of decisions 16–18 (§22.1, §22.2), in `duel/lisp/lille.lisp`; its functional clips in one new
section of `duel/lisp/lille-art.lisp` (";;; ---- rework R"). **No shared file changed**: the mobile EN moves, the traces and
TENSHIN are his own hooks (the moves' `:tick`, `:on-frame`, his hazards' hook), so nothing generic was needed.

**What is built**
- **The revival** (decision 16): `lille-bankai-ok` = `lb-revive-ok-p`: any of Jilliel's four forms, idle / guard (the
  stances included), Konpaku ≤ `*bankai-konpaku*` (4). The BEHEADED flag, its `:settled` hook (`lille-settled`), its
  callout, `lb-beheaded-p` and `*lb-revive-konpaku*` are gone; the revive cinematic is kept. Debug 79005 is now "EN with 3
  Konpaku". (The generic `:settled` hook point in combat.lisp `settle-konpaku` stays, now unused by any kit.)
- **The shooting stance** `:lb-kamae` (+ `:lb-kamae-k` entered at f4 as `:l-after-k`, `:lb-kamae-re` the dash's re-entry
  at f6): S6, held 30 f / 90 f with L held, R 14 (110 f), turning 60°/s, planted, hitless. `lb-kamae-tick` (TSUKIMACHI's
  pattern) fires the first L / J / K / Step from f6: `:lb-k-shot` (S10 A2 R26, `:params :lock 0`: locked on the press, a
  jade lane drawn for its 10 f; quick 40 flat, charged = `lb-x-damage`), `:lb-k-j` REIKYORI, `:lb-k-k` NAGIHARAI,
  `:lb-k-dash` HIRENKYAKU (3.5 m, neutral = away, iframes f0–8, 10 flash step, once per stance). The charge
  (`lb-kamae-clock`) counts each step from f6, the dash's included, once a step. `:lb-x-axis` and the K → L snap shot
  `:lb-x-quick` are removed (L after a K link is the stance).
- **Jilliel EN** (`:jilliel`, `:jilliel-mujittai`): J / K = `:lb-e-j1…k3` (the wing strings' S / A / R / enter, no hit
  window), SP1 `:lb-e-sanren` (3 lines), SP2 `:lb-e-nijushi` (the 40 f tell, then one thick trace). `lb-en-tick` walks him
  at 3.0 m/s on the stick (frost / cold field as a walk), facing the opponent; `lb-en-lay` lays the traces on the first
  active frame and sets `fighter-chained` so the string's next link opens without contact (the lines never hit). L from
  the active end cancels into TENSHIN.
- **Jilliel KIN** (`:jilliel-kin`, `:jilliel-kin-mujittai`): the wing-blade strings, SP1 `:lb-sanren` and SP2
  `:lb-nijushi` as built, walk 3.8 / run 8.5, `:l-after-k t` (TENSHIN after a K link), body `:lille-jilliel` until the art
  batch's `:lille-jilliel-kin` lands. Both modes: ×1.1 taken, `:gg-regen` 0.36, U = MUJITTAI, P the revival.
- **Traces**: a hazard `:lb-trace` each (no hit while live; a `:cap 0.6 31 1.2 r` line, r 0.6 / SP2 1.2), ids counting up
  per side; at most 8 live (the 9th destroys the smallest id); kept until his next switch, cleared on the revival (and by
  any reset's `clear-hazards`). `lb-trace-look` draws a faint jade floor line with a width pulse (lille.lisp's last
  section, `defun-fast` through lille-art's `%lb-floor-line`: no allocation; the 79195 probe now calls it).
- **TENSHIN** `:lb-switch` (S12 A0 R8, `:cooldown 30`): f0 `lb-materialise` turns every live trace into a 2-frame hit
  (`lb-trace-hitwin`: J 30 / K 24 / SP1 30 / SP2 180 × his damage, `:ranged :x-axis :uncatchable`, chip 15 %, drain 18 /
  45; a stagger, SP2 a knockback) with the X-axis line's flash, then dashes 3.5 m at him (EN → KIN) or away, iframes f0–8,
  10 flash step; the form changes at f6. Refused (the cue) under 10 flash step (`lille-ok`).
- **The CPU**: the stance's branch is planned once at its first up step (`lb-ai-kamae-plan`, one roll; the §22.1 table);
  EN switches in when ≥ 3 traces are live and the perceived opponent is on one (axis ≤ 0.6 m; a thick trace counts 0.6 m
  wider), or reels / recovers within 1.5 m of one (`lb-switch-in-rule`, deterministic; in a move the tick checks it from
  the active end); EN walks 6–12 m and across the opponent's line on its strafe, and latches the same button's next link
  (no roll); KIN switches out after any string (blocked or not) or with the gauge under 40 (`lb-ai-kin`). A CPU facing EN
  (`:opp-reflex lb-opp-trace`, `:opp-trace (:p 0.5)` × `opp-chance`) Steps off a trace it stands on, seen (age ≥ its
  delay), newer than the ones it rolled for, while his TENSHIN is ready: one roll for each new set. The base `:moves` have
  `:sig` (the stance) in every band (0–2.2 m weight 1, 2.2–6 m weight 2, the far band's 6 as before); `:sig-hold`,
  `lb-aim-hold-ai` and `:opp-aim` are gone from his kits (the generic `ai-opp-aim` stays, unused).

**Deviations from §22 (the smallest, each with its reason)**
1. **EN's J / K keep their active frames** (A 3 / 4 / 5) with no hit window: the lines are laid on S and TENSHIN cancels
   from S + A, as "from their active end" says. An opponent CPU may read them as a close threat within reach + margin
   (1.6–2.3 m): harmless (nothing hits).
2. **KIN's TENSHIN cancel is the K-link L latch only** (`:l-after-k t`); "as a K link's L" read literally, so a KIN J link
   or SANREN does not cancel into it.
3. **The stance's grey aim line is not drawn yet**: lille-art.lisp's `%lb-aim-look` keys on `:lb-x-axis` / `:lb-volley`
   (the art batch owns that hook). The lock is shown by a jade lane look-hazard for the shot's 10 f. The art batch should
   key the aim look on `:lb-kamae*` (grey, tracking) and `:lb-k-shot` (jade, locked), and add `:jilliel-kin*` to
   `lille-draw`'s Jilliel look and `lille-body-alpha`'s MUJITTAI (today KIN falls back to the base look).
4. **Unspecified numbers chosen**: the trace hit reactions (stagger, kb 1.0; SP2 knockback 2.0, heavy hitstop); KIN's
   `:form-name` "JILLIEL KIN"; the EN and KIN `:ai` tables (EN zone 6–12 m, bands `:f 4 :q 3 :sp1 1 :sp2 1` at 3–14 m;
   KIN an approach / pressure melee table); `:opp-trace :p` 0.5; TENSHIN refused without its 10 flash step (TSUKIWATARI
   waits instead).
5. **Debug** 79014 / 79015: forced KIN / its MUJITTAI 5 m from Kenpachi.

**Tests** (host): duel-rules 5914 checks ALL PASS (the stance's frames, branches and hold, charge 23 vs 24 and the
clock through the dash, the K-link → stance f4 combos off K1 / K2 / K3, REIKYORI / NAGIHARAI data, the revival at
Konpaku 4 from EN and KIN and refused at 5, TENSHIN's data / targets / cooldown, EN's frames = the wing strings', the
traces' fans, cap 8 / FIFO, materialise once, the hits and drains, the CPU's plan and switch rule, the kits' keys);
duel-control 86, learn 100, input 33, touch 64, cine 18 ALL PASS. FK reach (±0.15 m): REIKYORI 1.85 / 1.80 m, NAGIHARAI
2.59 / 2.60 m. `tools/pkgcheck.sh duel` 0 / 0 / 0. `tests/scripts/duel-lille.json` regenerated (the stance, its
branches, EN's traces, TENSHIN, KIN).

**Gates** (native, NORMAL, seeds 1–10): the fifteen old pairings' 420 lines (rows, companion lines, summaries)
**byte-identical** to the run before the change; `--cvc` PASS (yy / yk / kk). His six pairings (untuned; no knob turned):

| Pairing | Before: median, Lille wins / 10 | After: median, K.O., Lille wins / 10 | Blow-aways |
|---|---|---|---|
| LY | 172.3 s, 3 | **182.0 s**, 10/10, **4** | 1 |
| LK | 146.6 s, 1 | **170.1 s**, 10/10, **1** | 28 |
| LR | 177.5 s, 2 | **169.7 s**, 10/10, **1** | 1 |
| LI | 176.3 s, 2 | **214.8 s**, 10/10, **2** | 7 |
| LS | 174.7 s, 1 | **205.3 s**, 10/10, **4** | 3 |
| LL | 226.8 s, P1 2 / 8 | **298.9 s**, **8/10** (seeds 1 and 6 time out at 343 s), P1 5 / 5 | 0 |

LI's median is past 210 s and the mirror has two time-outs: reported, not tuned (the 20-seed verdict and the tuning are
the next batch's). Per Lille side and match (means of 10; the mirror's two sides in brackets):

| | LY | LK | LR | LI | LS | (LL) |
|---|---|---|---|---|---|---|
| stance entries | 5.4 | 2.3 | 2.8 | 3.5 | 2.0 | (8.3 / 7.5) |
| shots quick / charged | 0.7 / 3.6 | 0.6 / 0.5 | 0.5 / 1.5 | 1.1 / 0.9 | 0.3 / 0.9 | (0.2 / 6.3, 0.4 / 5.6) |
| shot hits / REIKYORI hits | 4.0 / 0.9 | 1.0 / 1.0 | 2.0 / 0.6 | 1.9 / 1.4 | 1.1 / 0.6 | (5.8 / 0.5) |
| HIRENKYAKU dashes | 3.4 | 0.4 | 1.5 | 0.9 | 0.8 | (5.6 / 4.3) |
| TENSHIN in / out | 6.1 / 6.0 | 5.9 / 5.4 | 7.5 / 7.4 | 7.5 / 7.6 | 9.1 / 8.7 | (13.2, 15.6) |
| traces laid / materialised | 13.2 / 12.2 | 13.2 / 12.5 | 16.4 / 15.8 | 17.1 / 16.9 | 14.0 / 13.6 | (27.7 / 27.0, 33.1 / 32.7) |
| trace hits / guarded | 5.1 / 2.6 | 7.6 / 2.3 | 7.8 / 2.6 | 7.4 / 1.7 | 7.7 / 1.2 | (10.4 / 4.5, 15.2 / 4.2) |
| opponent's trace rolls / Steps | 2.2 / 1.2 | 2.1 / 1.0 | 3.0 / 1.9 | 3.6 / 1.9 | 2.7 / 1.4 | (7.7 / 4.5) |

A browser smoke run (`tools/run.mjs`, a probe script: EN K, K, J then L; the base stance's charged shot from 14 m; 79005
then P) logs no error: seven traces materialise as seven hits (6 × 24 + 30), the stance's L 27 f in hits for 90 at
14 m, P revives at 3 Konpaku. The 79195 consing line costs 8 B per live hazard and draw, the same as LB-LOOK's (the
probe's component lookup; the looks themselves allocate nothing). `./build.sh duel`: 0 warnings.

KIN's switches out: mostly after a string (4.7–7.0 a match), after a block 0.2–1.2, on the gauge 0–1.5. The revival
fires in 8–10 of 10 sides.

### 22.5 Built: the rig (rework A, 2026-10-06)

The user's words (decisions 19, 20): 「Jilliel 是揮舞八片刀刃狀的翼發動攻擊，而手臂則是背影藏在柱身內部，但現在的建模看起來就像是手臂變成一對翅膀，剩下三對則死板的掛在身後。」 and 「梟頭型態原作不是四根高蹺般的腿，而是兩隻細長腿，只是在腿部中間又出現分岔看起來像四條腿。」 All of it is cosmetic (`lille-art.lisp`; two debug stills in `lille.lisp`); no move, frame, reach, damage, kit or AI changed.

**Jilliel's wings** (`:jilliel`, `:jilliel-mujittai`, and the KIN forms `:jilliel-kin`, `:jilliel-kin-mujittai`):
- The rig's arms are **not drawn** (the body has no arm, shoulder or hand parts: hidden in the column). The rig keeps its x2.6 arms: the hands are the strike points.
- **Eight separate blades** drawn by LILLE-DRAW (`*LB-WINGS-JL*`, rows of 10: side, elevation, length, sweep, fold target, front, flip, sway phase), rooted 0.07 m either side of a point behind the column's top (the chest frame (0, 0.30, 0.13 back)), **two fans of four**: +40° (1.6 m), +13° (1.75 m), the **front pair** (about −16° idle), −40° (1.5 m, its torn edge turned up).
- **The front pair runs from its root to the rig's hand**: the drawn tip is the hand, which is what the host FK reach test reads (unchanged, ALL PASS; the hit poses were not touched). Its blade keeps a fixed 1.75 m width scale whatever its length, its torn edge down and out (normal = (−Y + 0.5 s X) × the wing). So J1 / J2 swing one front wing, J3 and the K links both (the existing clips), and the idle hands sit in the fan.
- **Idle sway**: each of the six table wings sways ±3° on its own phase (the fx clock: cosmetic, never sim state); the front pair sways out of step through `:lb-w-stance`'s clip (keys 0.8 / 1.5 / 2.3 s, the right and left arm extremes offset). The pass-through ripple (±14°, 0.5 s) stays.
- **The SPs fan them out**: during any `:sp` / `:kikon` move or the clips `:lb-w-aim`, `:lb-w-fire`, `:lb-w-nijushi`, `:lb-o-trompete` the six table wings open 22 % wider and sweep 0.7 forward (the holes facing him), easing in and out over 0.12 s (`*LB-FX*` [16]; the per-side memory grew from 16 to 24 slots).
- **MUJITTAI** folds the six round the column (as before, 5 / s, 0.7 see-through) and the front pair crosses low before it (`:lb-w-fold-pose`: arms flex 0 side 30 twist ±45, elbows 110).
- **The blade** (`lb-wing-blade`): a bowed leaf (its centreline bows 0.07 toward the torn edge and comes back onto the root-tip chord, so the tip is exact), narrow root, widest at the middle (0.285 of its length), a long point, four teeth on the trailing edge, three oval holes on the centreline; built of quads (the bowed leaf is not convex). The `%LB-FRAME!` macro takes a separate width scale.
- The cinematics follow: the awakening unfolds four pairs (f112–144), the revival turns them gold a pair at a time (four pairs), the Kikon's 24 lines leave the new fan (`*LB-HOLE-FAN*`).

**The legs** (decision 20):
- `:lille-shin` (the owl): the fixed hind stilts are gone. Two long thin legs (the rig's, x1.5): a 0.66 m thigh to the knee, then **two shanks of 0.75 m, 21° fore and aft and 4° out**, tapering to points on the floor; a knee knob. The rig's feet carry nothing. The owl keeps its long arms (the claws are the hands) and gets the same eight blades in gold #B89A5A (decision 11 kept; `*LB-WINGS-OWL*`: +34 / +11 / −11 / −34°, 1.9 / 2.05 / 1.95 / 1.7 m, the lowest pair flipped).
- **New body `:lille-jilliel-kin`** (KIN): Jilliel's column from the hips up (the long lower column and prongs become a short rounded hip mass), the same no-arms rule and wings, on the owl's legs at Jilliel's rig: a 0.44 m thigh, then two shanks of 1.06 m, 20° fore and aft. **It is built for the Jilliel clips' float (root `:u` 0.5)**: the rig's feet hang 0.5 m up, so the shanks run on past them to the floor; a KIN clip should keep `:u` near 0.5 (a clip at `:u` 0 sinks the shanks 0.5 m).

**The base form's aim line** (after the rules batch's §22.1): the grey tracking line and turning reticle now show during the stance (every move named `LB-KAMAE*`, wider from its f30), the jade locked line and the closing reticle (0.65 → 0.47 m) during `:lb-k-shot` until it fires; the volley's fan went (L in Jilliel is the switch). The `:charge` hook's jade glint also shows on `:lb-k-shot`.

**Stills** (debug, DUEL_GAMEPLAY "Debug commands"): **79197** P1 Lille as JILLIEL KIN 5 m from Kenpachi (the `:jilliel-kin` form once its kit exists, else JILLIEL wearing the KIN body); **79198** Lille as P2 facing the behind camera 4 m out, each call the next of JILLIEL / KIN / the owl (the front view). Looked at against the reference contact sheets: Jilliel idle from the front, behind and the side, J1, K1 (wind-up and hit), K3, MUJITTAI (side, behind), KIN (front, side), the owl (front, side), the awakening at f120 / f150 / f170, the revival at f50 (gold turning pair by pair), the Jilliel Kikon card: two fans of four, no arms, the swinging front wing reads as a blade; the owl and KIN legs read as two forking into four from the side.

**Gates**: host tests ALL PASS (duel-rules 5722 with the FK reach test, cine 18, control 86, learn 100, input 33, touch 64); `tools/pkgcheck.sh duel` 0 / 0 / 0; `simgate.py --seeds 10 --summary` **byte-identical** to the run before the change (the art moves nothing); `--cvc` PASS (yy, yk, kk); `./build.sh duel` 0 warnings.

**Consing** (debug 79195, 10 draws): the draw hook 160 B in the base form, Jilliel (idle and mid-K), KIN and the owl, 240 B in MUJITTAI: 16 / 24 B a frame, the ECS lookup floor of §21, unchanged; the new wing paths (the hand-driven front pair, the sway, the spread) draw 0 B.

### 22.6 Measured after the merge (the lead, 2026-10-06)

The lead's merge (rules R + rig A) plus two fixes: a K fan's three traces are **one hit group** (in the browser at 5 m a
J + K then TENSHIN hit 30 + 24 + 24 + 24 before, 30 + 24 after), and the stance's damage tag shows the quick 40 until the
charge (it showed the curve from the first frame), its sum in float math. The tag still costs one `hud-text` call
(~200 B a frame by hud.lisp's design, as every HUD text). Host tests ALL PASS (duel-rules 5914, control 86, learn 100,
input 33, touch 64, cine 18, RAVEN rules-test); pkgcheck 0 / 0 / 0; `--seeds 10`: the fifteen old pairings' 180 gate
lines identical to the baseline before the rework; `--cvc` PASS; `./build.sh duel` 0 warnings.

**Seeds 1–20** (every match K.O., the mirror's two time-outs at 10 seeds gone at 20):

| Pairing | Median | Lille wins / 20 |
|---|---|---|
| LY | 171.4 s | 6 |
| LK | 163.1 s | 2 |
| LR | 198.3 s | 2 |
| LI | 198.1 s | 3 |
| LS | 204.0 s | 4 |
| LL | 290.8 s (mirror) | P1 9 / P2 11 |

Pacing passes (125–210 s); his wins are under the 10 ± 3 target in every pairing (batch 4: 7 / 3 / 3 / 5 / 5).

**Awaken A/B** (39020, Lille P1 never awakens; wins of 60, streams 100 / 300 / 500; pass ≥ 20): LY 13 / 19 / 12, LK 1 / 3
/ 3, LR 3 / 4 / 5, LI 3 / 4 / 2, LS 5 / 6 / 11. Fails everywhere, as in §20.3 (0–4), a little closer against Yamamoto
and Senjumaru. Not tuned: the balance direction waits for the user's playtest (「先試玩再決定」).

---

## 23. Second rework (decisions 21–27, 2026-10-06)

Numbers are proposals until the gate; the lead picked them where the user gave none (the user may move any of them).

### 23.1 The base stance (decisions 21–24)

| Follow-up | Value |
|---|---|
| J 跳射 HŌSHA `:lb-k-j` (replaces REIKYORI) | a **forward leap 5.0 m** (3.0 before decision 31) over f0–14 (airborne look, hurtbox as normal; no iframes), three bullets at **f6, f10, f14**: each a short line `(:cap 0.6 3.0 1.2 0.25)` (6.0 before decision 31) from the muzzle, **16** damage, flinch (the 3rd a stagger), **guardable** (a bullet, not the X-Axis: chip as a normal ranged hit, guard 6 each), each its own window (3 hits); R 16 after landing. **On any bullet's hit, his recovery cancels into J1 or K1** (the link: a combo). Blocked: −8 |
| K 退射 TAISHA `:lb-k-k` (replaces NAGIHARAI) | a **back-slide 3.0 m** over f0–12, then at **f16** one bullet: a line `(:cap 0.6 6.0 1.2 0.3)` (12.0 before decision 31), **60** flat × `*lille-mult*`, stagger, knockback 1.0 m, **`:ranged :x-axis :uncatchable`** (through guard: chip 15 %, drain **30**, as the shot); R 24 |
| Step HIRENKYAKU `:lb-k-dash` | as built (3.5 m, once per stance, the charge kept); **at its end the stance's yaw snaps to the opponent** (track resumes from there) |
| Touch (bug) | in the stance an upward flick must give the Step, as on the keys (the control / touch path is fixed, not the stance; a host test pins it) |

- The CPU: J (HŌSHA) at 3–6 m and after a K link's hit; K (TAISHA) at ≤ 3 m to make room, or on a guard; the rest as
  §22.1.

### 23.2 TENSHIN (decision 25)

| | Value |
|---|---|
| Dash in (EN → KIN) | **up to 13.0 m at him over 14 f, stopping 1.5 m short** (`*lb-switch-in*` 13.0 since decision 43; 10.4 by decision 42, 8.0 before; `*lb-switch-stop*` 1.5); iframes f0–8 |
| Dash out (KIN → EN) | **10.0 m** away over 14 f (`*lb-switch-out*`; 7.0 before decision 43) |
| Cancel | from the dash's end (f14) his **J or K cancels the recovery** (either mode; EN's J / K lay traces, KIN's hit) |
| A materialised trace | stagger with **hitstun long enough for the dash plus a J1** (≥ 14 + 8 + 4 f), **no knockback** (the SP2 thick trace keeps its knockback), so a trace hit → TENSHIN in → J / K is a combo (host test) |

**Traces (decision 29)**: `*lb-trace-max*` 8 → **16** (a 17th drops the oldest).

**TENSHIN's startup (decision 30)**, EN → KIN only (KIN → EN as built): the traces materialise and the dash starts at the
end of the startup (iframes from there).

| Pressed from | Startup | Note |
|---|---|---|
| EN neutral (idle / walk / run / MUJITTAI) | **8 f** (0.13 s; the user's 0.1–0.15 s) | the form-change / dash wind-up, visible (the wings snap back); hittable |
| an EN attack (J / K / SP1 / SP2 cancel) | **2 f** | "大幅減少": the cancel almost at once |

**EN's tempo (decision 28)**: startup and recovery about **halved** in the ranged mode only (KIN and the base form keep
theirs); the active frames stay (a trace is laid on the first). Lead's numbers (S / A / R):

| EN move | Before | After |
|---|---|---|
| J1 / J2 / J3 | 8/3/12, 7/3/13, 9/3/18 | **4/3/6, 4/3/6, 5/3/9** |
| K1 / K2 / K3 | 17/4/21, 20/4/24, 21/5/34 | **9/4/10, 10/4/12, 11/5/17** |
| SP1 SANREN | 12 / lines at f12, f22, f32 / 24 | **6 / lines at f6, f12, f18 / 12** |
| SP2 NIJŪSHI-KŌ | 40 f tell / 6 / 30 | **20 f tell / 6 / 15** (the thick trace at f20) |

### 23.3 The rig (decisions 26, 27)

- **ㄇ legs** (KIN and the owl): thigh down to the fork; from the fork a **strut runs back** (horizontal), and at its end
  the leg **bends down** to the floor; the front shank goes down from the fork: the two shanks and the strut read as ㄇ
  from the side.
- **Translucent wings** (every Jilliel form and the owl): drawn see-through so the fight stays visible; they must stay
  readable as jade / gold blades with their holes.
- **The owl = KIN's model** (the column, the ㄇ legs, the eight wings in gold #B89A5A, decision 11) with **the long
  S-neck owl head** in place of Jilliel's top, and an **extra pair of long arms** relative to KIN (one pair in all: the rig's, the claws the
  strike points; §23.7).


### 23.4 Built: rules, CPU, touch (round 2)

The rules + CPU half of decisions 21–25 and 28–30 (§23.1, §23.2; decisions 28–30 came through the lead the same day: 28
「覺醒的遠程模式 J/K/SP1/SP2 的前後搖都大幅縮短。」, 29 traces 8 → 16, 30 TENSHIN in's wind-up), in `duel/lisp/lille.lisp`, its two clips in lille-art.lisp's ";;; ---- rework R"
section, and the touch fix in `control.lisp` / `onehand.lisp` (+ one flag on Ichigo's TSUKIMACHI). §23.3 is the art batch's.

**What is built**
- **J 跳射 HŌSHA** `:lb-k-j` (REIKYORI's slot; clip `:lb-k-hosha`): S6 A10 R16 (32 f). f0 `lb-hosha-leap`: a 3.0 m leap along
  his facing over f0–14 (`*lb-hosha-leap*`, `*lb-hosha-leap-f*`), stopping `*lunge-stop*` short of him; the clip lifts him
  (root up to 0.66 m) while the hurt cylinder stays on the floor; no iframes; he turns 90°/s at him through f14. Three
  bullets, each its own 2-frame window, (6 8) (10 12) (14 16): the line `(:cap 0.6 6.0 1.2 0.25)`, 16 each, guard 6,
  `:ranged` (no parry catches it; guardable, no chip, not the X-axis), light hitstop; the first two flinch held
  **`*lb-hosha-stun*` 30** frames, the third staggers (26); −8 on block. **The link**: J / K pressed during HŌSHA is
  latched (`lb-link-tick`, the last press wins) and, once a bullet hit, from f16 (its recovery) starts J1 / K1 through
  `try-command`, chasing him in its startup (`fighter-end-chase`, the Breaker's J1 / K1 rule). Host test with the real
  frames: every bullet's frame + its stun > 16 + J1's (8) / K1's (17) first hit (bullet 1: 6 + 30 = 36 > 33).
- **K 退射 TAISHA** `:lb-k-k` (NAGIHARAI's slot; clip `:lb-k-taisha`): S16 A2 R24. f0 the back-slide 3.0 m over 12 f
  (`*lb-taisha-slide*`, `-f*`; SP2 HIRENKYAKU's slide hook, which now counts `:taisha` / `:hiren` by move), turning 90°/s
  until f12, then locked (`:lock 12`: the CPU's line perception starts there); f16 one bullet `(:cap 0.6 12.0 1.2 0.3)`, 60
  flat × `*lille-mult*` (no distance bonus), stagger kb 1.0, `:ranged :x-axis :uncatchable` (chip 15 %, drain 30), −14.
- **HIRENKYAKU's aim snap**: `lb-kamae-back` (the dash's f11) re-enters the stance and turns him straight at the opponent;
  the 60°/s tracking goes on from there.
- **TENSHIN**: the dash is 14 f (`*lb-switch-f*`); in is `min(13.0, d − 1.5)` m at him (8.0 before decision 42, 10.4 before decision 43) (`*lb-switch-in*`,
  `*lb-switch-stop*`; none when nearer than 1.5 m), out 10.0 m (`*lb-switch-out*`; 7.0 before decision 43) (`lb-switch-dist`); iframes for the
  dash's f0–8, the form 6 f into the dash. **Three moves** (decision 30): KIN → EN `:lb-switch` (KIN's L and its K-link
  L): no wind-up, the dash at f0, S14 A0 R8. EN → KIN from EN's neutral (idle / walk / run; MUJITTAI drops to EN and
  takes it) `:lb-switch-in` (EN's L): **an 8 f wind-up** (`*lb-switch-windup*`; hittable, no iframes), then the traces
  materialise and the dash starts at f8, the form at f14, S22 A0 R8 (clip `:lb-w-tenshin-in`: the front wings drawn back,
  then the fold and the flash step); as a cancel out of an EN attack (J / K / SP1 / SP2, `lb-en-tick`) the same move
  entered at its f6, `:lb-switch-in-c` (**2 f**, `*lb-switch-windup-c*`; started with `try-command`'s WITH, under L's
  checks, cooldown and price). `:lb-switch`'s clip is retimed to its 14 f. **From f14 his J / K cancel the recovery** in either mode
  (`lb-link-tick`, `:params :link`: 14, or 22 after the wind-up; a press before is latched): EN's J1 / K1 lay traces, KIN's hit (a KIN link
  after a switch in chases like HŌSHA's). **A materialised trace** (J / K / SP1) is now a stagger of **`*lb-trace-stun*`
  26** frames with **no knockback** (1.0 m before); SP2's thick trace keeps its knockback 2.0. Host test: 26 ≥ 14 + KIN J1's
  8 + 4, and for both wind-up paths (the stun counts from the materialise, the dash's f0): 26 > 14 + 8.
- **EN's frames** (decision 28; EN only, KIN and the base form keep theirs; active frames and the trace on the first active
  frame kept; **at most 16 live traces**, a 17th drops the oldest: decision 29, `*lb-trace-max*` 8 → 16): J1 4/3/6, J2 4/3/6, J3 5/3/9; K1 9/4/10, K2 10/4/12 (enter 3), K3 11/5/17 (enter 4); SP1 SANREN S6, lines at
  f6 / f12 / f18, A14 (to f20, two past the last line as before), R12; SP2 NIJŪSHI-KŌ the tell 20 f (the thick trace at
  f20), turning 60°/s until f10 (`:lock 10`, 20 before), A6, R15. The wing clips play at `:clip-s` / S (J1 ×2, K1 ×1.89 …
  SP2 ×2), so each hit pose lands on the new first active frame. The EN strings still run without contact: a laid line sets
  `fighter-chained`, which opens the next link in the last `*chain-lead*` (3) frames of the recovery; host-tested for every
  link (each R > 3).
- **The CPU** (one roll per event, as before): the stance's plan (`lb-ai-kamae-plan`, at its f6) is now: after a K link's
  hit L 0.6 / J (HŌSHA) 0.4; ≥ 8 m the charged shot; 6–8 m the quick shot on a whiff, else the dash back then the charged
  shot; **3–6 m TAISHA on a guard, the quick shot on a whiff, else HŌSHA; ≤ 3 m TAISHA** (the gauge-low input is no longer
  read). Its link (`lb-ai-link-plan`, once a move): after HŌSHA's hit one roll, J1 under 0.5 else K1; after TENSHIN, J1
  only when it switched **in** and a materialised trace hit (the combo), no roll. EN's switch-in rule now knows the
  wind-up (decision 30): its "busy near a trace" branch needs him busy for the wind-up still to come (8 f from neutral,
  2 f as a cancel), and from neutral its "on a trace, ≥ 3 live" branch skips a running / stepping / Hoho-ing opponent
  (`lb-switch-in-rule`'s MOVING).
- **Pacing log** (`duel lille` lines): `hosha`, `hosha-shots`, `lb-k-j-hit/-blk` (per bullet), `hosha-link`,
  `hosha-combo` / `-drop` (the link's first hit with the victim's combo counter > 1, or not), `taisha`, `lb-k-k-hit/-blk`,
  `tenshin-link`, `tenshin-combo` / `-drop`.
- Brush callouts 跳射 HOSHA, 退射 TAISHA (`tools/glyph-bake.py` gained 跳 退; `glyphs.lisp` re-baked: 177 glyphs, the old
  175 byte-identical).

**The touch bug (decision 24)**: reproduced on the host. Root cause: onehand.lisp set the recogniser's `up-hoho` ("any
up-flick is a Hoho, no rest needed") whenever P1's state was `:move` (the user's 2026-09-30 rule: no dash while attacking).
The shooting stance is a move, so an up-flick pulsed a Hoho (the HOHO glyph): `:mod` + `:step`, the `:hoho` command; the
stance only reads an unmodified Step, and a `:sig` move takes no Hoho cancel, so nothing happened. **Ichigo's TSUKIMACHI
had the same bug** (its Step TSUKIWATARI, same pattern). Fix: a move flag **`:step-branch`** (a stance whose `:tick` takes
Step as a follow-up) on `:lb-kamae` and `:ic-tsuki` (their copies inherit it), and `control.lisp UP-FLICK-HOHO-P` (state,
step-branch, perfect): a Hoho while attacking unless the move has `:step-branch`, or when perfect; onehand.lisp calls it.
The recogniser (engine/lisp/touch.lisp) is unchanged; keys and pads never went through this path. Tests:
duel-control-test (the rule, and the whole path: a rested up-flick in the stance → the flick pulse straight ahead → the
unmodified `:step` command; in any other move still `:hoho`); duel-rules-test (exactly the six stance moves carry the
flag).

**Deviations and choices (the smallest, each with its reason)**
1. HŌSHA's first two bullets flinch for 30 f, not the flinch's 18: with 18, K1 off the first bullet (f6 + 18 = 24 < 33)
   and J1 off it (24 = 24: the victim is free on that step) were not combos. "On any bullet's hit … a combo" needs ≥ 28.
2. The leap stops `*lunge-stop*` short of him (a lunge's rule), so it is under 3.0 m inside 3.95 m; the bullets'
   hitstop is the light one; HŌSHA links chase (`fighter-end-chase`) so a link from a 6 m start (3 m after the leap) reaches.
3. A J / K pressed any time during HŌSHA / TENSHIN is latched (the string latch's feel) rather than only buffered
   (`*input-buffer*` 10 f would drop a press made before f6 / f4).
4. TAISHA −14 on block (the shot's), unspecified; it tracks 90°/s until f12 (HIRENKYAKU's tick) then locks.
5. EN K2 / K3 keep an `:enter` scaled by the same ratio (3, 4; the wing strings' 6, 7): the lines never hit, so the
   enter only keeps the links' rhythm.
6. The `:step-branch` flag touches Ichigo's file (one flag on `:ic-tsuki`): his TSUKIMACHI had the bug too.
7. TENSHIN in's 2 f cancel is the 8 f move entered at its f6 (one move, one clip; its first 6 f of wind-up skipped), and
   it is not in the EN kit's move table (started by name through `try-command`'s WITH; nothing looks it up by name).

**Tests** (host): duel-rules **5938** ALL PASS (HŌSHA / TAISHA data, the link combo arithmetic, the link plan, the stance
plan, TENSHIN's distances / link frames / both wind-up paths, the trace stun, the 16-trace FIFO, EN's new frames and string links, the `:step-branch` set; the FK
reach test no longer lists the stance's J / K: line hits), duel-control **89**, learn 100, input 33, touch 64, cine 18 ALL
PASS; `tools/pkgcheck.sh duel` 0 / 0 / 0. `tests/scripts/duel.py` (shots `hosha`, `taisha`) → `duel-lille.json`.

**Gates** (native, NORMAL): `--seeds 10`, the fifteen old pairings' **420 lines byte-identical** to the baseline taken in
this worktree first (checked after decisions 21–28 and again after 29–30); `--cvc` PASS (yy / yk / kk). His six pairings,
seeds 1–20, everything in (decisions 21–30; no knob turned beyond the spec):

| Pairing | Median (§22.6 before) | K.O. | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|---|
| LY | **159.5 s** (171.4) | 20/20 | **8** (6) | 3 |
| LK | **168.0 s** (163.1) | 20/20 | **9** (2) | 32 |
| LR | **194.0 s** (198.3) | 20/20 | **5** (2) | 17 |
| LI | **206.8 s** (198.1) | 20/20 | **8** (3) | 8 |
| LS | **196.1 s** (204.0) | 20/20 | **8** (4) | 12 |
| LL | 246.1 s (290.8; mirror) | 20/20 | P1 10 / P2 10 | 13 |

Pacing passes in every cross pairing (125–210 s; LI the nearest edge). (Before decisions 29–30, with 21–28 only: LY 175.8 s
11 wins, LK 162.2 / 6, LR 193.4 / 5, LI 197.6 / 5, LS 201.1 / 5, LL 225.0.) Per Lille side and match (means of 20; the
mirror's 40 sides):

| | LY | LK | LR | LI | LS | (LL) |
|---|---|---|---|---|---|---|
| stance entries | 6.0 | 3.2 | 2.95 | 2.95 | 2.7 | (7.9) |
| HŌSHA uses / bullets hit / blocked | 2.95 / 8.1 / 0.45 | 0.9 / 2.3 / 0 | 1.15 / 3.05 / 0 | 1.1 / 3.0 / 0 | 1.0 / 2.5 / 0 | (2.6 / 7.2 / 0) |
| HŌSHA links / combos | 2.65 / 2.55 | 0.7 / 0.7 | 1.0 / 1.0 | 0.95 / 0.9 | 0.85 / 0.75 | (2.45 / 2.3) |
| TAISHA uses / hits / blocked | 0.75 / 0.35 / 0.25 | 0.9 / 0.45 / 0.25 | 0.3 / 0.25 / 0.05 | 0.4 / 0.25 / 0.1 | 0.45 / 0.35 / 0.1 | (0.35 / 0.28 / 0) |
| HIRENKYAKU dashes | 0.7 | 0.5 | 0.5 | 0.55 | 0.45 | (2.25) |
| TENSHIN in / out | 6.55 / 6.4 | 7.8 / 7.75 | 9.2 / 9.15 | 10.6 / 10.6 | 9.35 / 9.3 | (11.6 / 11.6) |
| traces laid / trace hits / dropped (> 16) | 15.1 / 6.0 / 0 | 19.5 / 8.85 / 0 | 22.9 / 8.5 / 0.35 | 29.1 / 11.0 / 0 | 17.5 / 7.7 / 0 | (26.5 / 10.75 / 0.12) |
| TENSHIN links / combos (trace hit → J hit) | 3.0 / 2.7 | 5.05 / 4.85 | 4.8 / 4.55 | 6.0 / 5.7 | 4.2 / 3.85 | (5.9 / 5.67) |

Read: HŌSHA lands almost every bullet (blocked 0–0.45 a match): at 3–6 m its S6 is under the opponents' perception +
guard raise, and the stance shows no hit window to read beforehand. Every HŌSHA link and nearly every TENSHIN link is a
combo (the rest: the link whiffed). Not tuned (the user's playtest decides). `./build.sh duel`: 0 warnings.

### 23.5 Built: the rig (round 2) (rework A2, 2026-10-06)

The user's words (decisions 26, 27): 「近戰與梟頭的腿部是從分岔點向後延伸出垂直支架，在末端才以折角往下延伸，呈現出 ㄇ 字型。」
「把翅膀調整成半透明以免遮擋視線。」「梟頭型態的建模在原作中會呈現以目前的近戰型態為基礎，並將頭部換成長頸梟頭與增加額外的手臂。」
All of it is cosmetic (`lille-art.lisp`: bodies, props, the draw hook, the owl's stance legs); no move, frame, reach, damage,
kit, AI or tuning changed. Looked at against `owl_fullbody_three-quarter-back_anime_ep37`, `owl_fullbody_three-quarter_manga-colour_ch650`,
`owl_fullbody_front_arms_manga-colour_ch650` and the Jilliel contact sheet.

**The ㄇ legs** (KIN `:lille-jilliel-kin` and the owl `:lille-shin`; `%LB-LEGS`):
- The body keeps the thighs (0.44 m) and a knob at their end: **the fork**. The rest is drawn by LILLE-DRAW in the thigh's
  frame: the **front shank** straight down from the fork (tilted 0.1 forward, 0.07 out), the **strut** running **back** from
  the fork (0.52 m, `*lb-leg-strut*`; horizontal in the thigh's frame) to **the corner's knob**, and the **rear shank** down
  from it (0.12 back, 0.07 out). From the side: two shanks and the top bar, ㄇ.
- **The feet stay on the floor**: each shank's length is where its line meets the floor of his body's draw (the feet height
  DRAW-BODY leaves in `*TOON-BODY*` [1]: 0 B, no lookup), clamped to 0.45–1.35 of its 1 m rest; a leg pitched far from
  upright (a knockdown) keeps the rest length and goes with the body. So KIN's float (Jilliel's clips, root `:u` 0.5 with its
  bob 0.5–0.56, K3's 0.7, the Breaker's 0.3) and the owl's own clips (`:u` −0.02) all stand. The owl's stance legs were
  squared (thighs flex 0 / side 5, knees 0; were flex 6 / −4, knees 6) so the strut stays level.
- The old fixed fore / aft shanks (KIN 1.06 m, the owl 0.75 m, 20–21°) are gone; both bodies now share the same legs (the
  owl's rig is still x1.5 legs, so its fork sits at 0.91 m against KIN's 0.99 m; the shanks take it up).
- Shanks: unit-length tapered rods (r 0.048 → 0.006, ink hull); strut: r 0.04 m with the corner knob; cream for KIN, white for the
  owl; MUJITTAI draws them at its body alpha (0.72), the hit flash flashes them.

**Translucent wings** (every Jilliel form and the owl; `%LB-WINGS`):
- **The engine path**: `DRAW-MESH`'s ALPHA < 1 (its transparent pass: the lit shader after the opaque scene, no depth write,
  depth-tested; the toon pass is opaque only). Drawn plain it reads as the dark phantom of §21 deviation 3 (the duel's light is
  the toon one), so the glass carries an **emissive glow x its own colour** (`*lb-glass-glow*` 1.0) that brings it back to its
  jade / gold. No shader change.
- **Each blade is two meshes**: the **glass** (`:lb-wing`, `:lb-wing-gold`): the leaf's two faces only, row by row, with the
  **three holes cut through** (a row inside a hole splits in two: through a hole the fight shows clear), drawn at
  **alpha 0.35** (`*lb-glass-alpha*`); and the **rim** (`:lb-wing-rim`, `:lb-wing-gold-rim`, `:lb-wing-lit`): an **opaque** band
  inside the outline (0.016 of the length), the four teeth and a ring round each hole, in a dark step of the same hue (jade
  #2F4A3C, gold #8A7038), toon-drawn: what keeps it reading as a holed blade. NIJŪSHI-KŌ's tell fills the 24 holes with light
  (the lit rim). The owl's glass is **#B89A5A** (decision 11 kept; the glow makes it read gold, not brown).
- **MUJITTAI is more ghostly**: the glass at 0.18 (`*lb-glass-ghost*`) and the rim see-through too (0.4, `*lb-rim-ghost*`, with
  the glow), its halo drawn with the glow (it read dark blue). The column itself is still the engine's 0.72 phantom (§21
  deviation 3): a lighter body needs a glow on the body's draw, a shared-file hook (main.lisp) left to the lead.
- In the behind camera the opponent now shows through Jilliel's / KIN's fan (stills below); the halos stay opaque.

**The owl on KIN's model** (`:lille-shin`):
- KIN's column (the rounded hip mass, the spine, the column widening to its top) in the owl's **white #ECECE8** (the model
  sheet §5.4: white, gold only on the wings, the halo and the glow), its holes kept but quiet in the **cold shade #BCC1CC**
  (KIN's model, the white owl of the refs); the ribbon tendrils from the hips; the shaggy fur ruff (#D8DCE4) on the column's top;
  the **long segmented S-neck to the barn-owl face** (unchanged) in place of Jilliel's face; the ㄇ legs; the eight gold wings
  rooted as KIN's (chest (0, 0.30, 0.13 back); was 0.26 / 0.14).
- **The extra pair of arms** (`%LB-ARMS2`, cosmetic): rooted 0.13 m below and 0.05 m behind the rig's shoulders, each segment
  the rig arm's bone length, its direction half the rig arm's and half hanging down (and out 0.2 / 0.06), swaying ±0.07 on its
  own phase (the fx clock): it follows every strike at a smaller swing, so the four long arms read in the idle, the claws, SABAKI's
  raised arm and Trompete. The rig's arms (x2.2) and their claws are still the strike points (the host FK reach test unchanged).

**Stills** (`/tmp/claude-0/lb-art2/`, never committed; 79197 / 79198 / 79002–79004 / 79014 / cinematics 79100 + 19 i + k, the
side camera 2109): KIN side (`r2-kin-side`, `r3-kin-k1-side`), KIN behind in the fight (`r2-kin-behind`), Jilliel behind in a
fight and mid-J1 (`r2-jl-behind`, `r3-jl-j1-behind`), MUJITTAI (`r2-mujittai-behind`), the owl front / side (`r3-owl-front`,
`r2-owl-side`), the owl from the cinematic cameras (the revival f100 / f130 / f170 `r3-revive-*`, Trompete's card `r3-trompete-f90`), before
(`b0-*`).

**Gates**: host tests ALL PASS (duel-rules 5914 with the FK reach test, control 86, learn 100, input 33, touch 64, cine 18);
`tools/pkgcheck.sh duel` 0 / 0 / 0; `simgate.py --seeds 10 --summary` **byte-identical** to the run before the change; `--cvc`
PASS; `./build.sh duel` 0 warnings. **Consing** (79195, 10 draws): the draw hook 160 B in KIN and the owl, 240 B in KIN MUJITTAI and
MUJITTAI (16 / 24 B a frame: the ECS lookup floor of §21, unchanged); the legs, the extra arms and the glass / rim draws 0 B.

### 23.6 Measured after the round-2 merge (the lead, 2026-10-06)

Rules (§23.4) and rig (§23.5) merged. Host tests ALL PASS (duel-rules 5938, control 89, learn 100, input 33, touch 64,
cine 18, RAVEN rules-test); pkgcheck 0 / 0 / 0; `--seeds 10`: the fifteen old pairings identical to the baseline before
the first rework (the touch fix and Ichigo's `:step-branch` flag move no sim line); `--cvc` PASS; `./build.sh duel` 0
warnings. Stills of the merged build: HŌSHA's three bullets hit (16 × 3), KIN on the ㄇ legs, the owl on KIN's model
with the translucent gold wings.

Seeds 1–20 (§23.4's run, every match K.O.): LY 159.5 s / 8 wins, LK 168.0 / 9, LR 194.0 / 5, LI 206.8 / 8, LS 196.1 / 8,
LL 246.1 (mirror): every cross median inside 125–210 s; wins up from 6 / 2 / 2 / 3 / 4 (§22.6), LR still under 10 ± 3.

**Awaken A/B** (39020, wins of 60, streams 100 / 300 / 500; pass ≥ 20): LY 18 / 20 / 18, LK 2 / 6 / 7, LR 8 / 10 / 10,
LI 5 / 10 / 8, LS 17 / 13 / 14. Closer than §22.6 (1–19) but failing every row except LY's stream 300: awakening is
still a large upgrade. Not tuned (the user's playtest decides the direction).

### 23.7 Decision 31 (the third playtest, 2026-10-06)

「# 常態修改 1. L > J 前跳距離加長&射程縮短。 2. L > K 射程縮短>」. The lead's numbers:

| Knob | Before | After |
|---|---|---|
| `*lb-hosha-leap*` (over 14 f, stopping `*lunge-stop*` short) | 3.0 m | **5.0 m** |
| HŌSHA bullet line (`:vol`, look `:len`) | 6.0 m (6.6) | **3.0 m** (3.6) |
| TAISHA bullet line | 12.0 m (12.6) | **6.0 m** (6.6) |

HŌSHA now threatens up to ~8 m (the leap closes, the bullets reach 3 m: the first at f6 after 2.1 m of leap, the third at
f14 at its end). TAISHA after its 3 m back-slide reaches an opponent who stood within ~3 m. So the CPU's guard case at
3–6 m moved off TAISHA (it would now whiff) to the quick shot (through guard); its bands are otherwise unchanged
(`lb-ai-kamae-plan`, host test updated).

Measured (seeds 1–20, every match K.O.): LY 167.7 s / 8 wins, LK 169.4 / 11, LR 194.0 / 5, LI 206.8 / 8, LS 193.5 / 6,
LL 244.6 (mirror); every cross median inside 125–210 s; `--cvc` PASS; pkgcheck 0.

**The owl's arms (the user, 2026-10-06: 「然後梟頭狀態多了一組手臂喔www 萊醬」)**: decision 27's "extra arms" were
relative to KIN, which draws none, so the owl has **one** pair: the rig's long arms (the claws, the strike points).
The second, cosmetic pair §23.5 added (`%LB-ARMS2`, the `:lb-limb` / `:lb-claw` weapons) is cut.

### 23.8 Decision 32: translucent rims, three-segment wings (2026-10-06)

- **Rims**: the rim band, the teeth and the hole rings drawn translucent as well (a little stronger than the glass, so the
  outline still reads), every Jilliel form and the owl; MUJITTAI fainter still.
- **Joints**: every wing blade is three segments (root, middle, tip) joined at **two joints** at about 1/3 and 2/3 of its
  length; each joint bends about the blade's own fold axis. Cosmetic only (the sim never reads it):
  - idle: a travelling wave root → tip on each wing's own phase;
  - strikes: the front wing(s) lag then whip (the joints trail the root on the swing, snap straight at the active frames,
    overshoot in recovery); **at the active frames the striking wing's tip is still the rig's hand** (the host FK reach
    test keeps passing, ±0.15 m);
  - folds (MUJITTAI) curl round the column; SP spreads unfurl from the root.

### 23.10 Decision 33: the float is the form's, not the clip's (2026-10-06)

Cause: Jilliel's float (0.5 m) lived in his own clips (`:lb-w-stance` root `:u 0.5` and every `:lb-w-*` key), but walking,
strafing, running, steps, the Hoho and the hit reactions play the shared `:sh-*` clips at root 0, so he dropped 0.5 m
whenever he moved (KIN's legs shrank to their floor). Fix:
- a generic kit key **`:lift`** (metres; kit.lisp, default 0): main.lisp `BODY-LIFT` draws the body that much higher in
  every clip **while it wears the form's own `:body`** (an awakening cinematic still showing the base body stays on the
  ground). A look only: the sim, the hurt cylinder and the hit volumes never read it.
- Jilliel's kit `:lift *lb-jilliel-lift*` **0.5** (KIN and both MUJITTAI inherit it), the owl `:lift 0.0`; every
  `:lb-w-*` pose / key and the TENSHIN clips rebased by −0.5 (`:u 0.5` → 0, 0.53 → 0.03 …), so his own clips look as
  before and the shared ones float too.
- The revival cinematic runs in the owl form (no lift): its first 30 f (the beheaded column, `:lb-w-fold`) sit 0.5 m
  lower than before, then `:lb-rise` lifts it as before.

### 23.11 Decision 34: TENSHIN's tempo, the flash-step economy (2026-10-06); and the legs' floor

| Knob | Before | After |
|---|---|---|
| TENSHIN in from EN's neutral, wind-up (`*lb-switch-windup*`) | 8 f | **16 f** (the cancel out of an EN attack stays 2 f: the move entered at its f14) |
| The order (the user: 「按 L 觸發軌跡的順序是：前搖 → 軌跡觸發 → 衝刺 → J」) | | **wind-up → the traces materialise → the dash → J**: the trace's stun counts from the materialise, so trace → dash → J is a combo on both paths (16 f and 2 f) |
| TENSHIN cooldown (`*lb-switch-cd*`) | 30 f | **none** |
| TENSHIN EN → KIN flash step | 10 | **0** |
| TENSHIN KIN → EN flash step | 10 | 10 (unchanged; refused without it) |
| EN J / K: each trace line laid | free | **3 flash step a line** (a J 3, a K's fan of three 9); a line is laid only while 3 remain (the swing still plays) |
| A materialised trace that hits | — | **+4 flash step back** per trace (+2 at first; the user, the same day: 「我希望能將軌跡命中回收量上調到 4」; a K fan's hit group hits once: +4); **a guarded one +2** (the user: 「擋下回收 2，且所有軌跡都具備『萬物貫通』的穿透效果」; asked, the user chose 「維持現狀」 for the second half: every trace already is the X-Axis, decision 2: through guard as chip 15 % and the guard drain, never stopped by summons or hazards) |

SP1 / SP2 traces cost nothing (the user named J / K). The CPU must budget it (the flash step also pays Step, Hoho and
KIN → EN).

**The legs' floor (the user: 「萊醬你是不是不小心把覺醒的腿改短了？」)**: yes, decision 33's lift. The ㄇ legs reach the floor
from DRAW-BODY's feet height (`*toon-body*` [1]), which is the y the body is drawn at, so with the lift it sat 0.5 m up and
the shanks shrank to it. LILLE-DRAW now takes the form's lift off it (`BODY-LIFT`): the legs reach the ground again.


### 23.12 Built: decision 34

The rules + CPU half of §23.11 (decision 34), in `duel/lisp/lille.lisp`, one clip in lille-art.lisp's ";;; ---- rework R"
section, and the host tests. **No shared file changed.**

**What is built**
- **TENSHIN in's wind-up 8 → 16 f** (`*lb-switch-windup*` 16): `:lb-switch-in` S 22 → **30** (A0 R8), `:on-frame` the
  materialise + dash at **f16**, the form at **f22**, `:params (:link 30 :go 16)`; the cancel copy `:lb-switch-in-c` is
  entered at **f14** (still 2 f, `*lb-switch-windup-c*`). The order stays wind-up → the traces materialise (LB-SWITCH-GO's
  first act) → the dash → the J / K link at the dash's end (the user confirmed it, 2026-10-06). The clip `:lb-w-tenshin-in`
  is retimed +8 f (keys 6 / 8 / 14 / 22 → 14 / 16 / 22 / 30, `(30 0 8)`; decision 33's −0.5 root heights kept), so the cancel
  still enters at the drawn-back pose and the fold snaps at the materialise.
- **The combo on both paths**: the trace stun (26) counts from the materialise, which is the end of either wind-up, so
  the dash (14) + KIN's J1 (8) = 22 < 26 holds from neutral as from the cancel (host test per path: the materialise at
  the path's wind-up end, the link at the dash's end, the stun outlasting both). The longer neutral wind-up only delays
  the materialise; it does not break the combo.
- **No cooldown**: `*lb-switch-cd*` deleted, `:cooldown` gone from all three TENSHIN moves; `lb-switch-ready-p` no longer
  reads the cooldown (nothing else of his read it).
- **The flash-step price by direction**: `lb-switch-price` (form) is `*lb-switch-fs*` 10 out of KIN (or its stance), 0
  from EN; `lb-switch-ok-p` (form fs) and `lille-ok` refuse only KIN → EN under 10 (the cue); LB-SWITCH-GO spends the price
  only when it is positive.
- **Trace lines cost flash step**: `*lb-trace-fs*` 3 for each EN J / K line (`lb-trace-cost`: SP1 / SP2 free).
  LB-EN-LAY pays line by line (`lb-trace-pay`: one is laid only while 3 are left); the swing always plays. A K fan that
  can pay only one or two lays **its middle line first** (`lb-trace-pick`: one → 0°, two → −6° and 0°), in the fan's
  order, under the fan's one hit group. Each unpaid line counts `traces-unpaid` in the pacing log.
- **The refund**: `*lb-trace-refund*` 2 (`lb-trace-refund`: 2 on `:hit`, 0 guarded). LILLE-HIT, on a materialised trace's
  hit, pays it through the generic PAY-GAUGES (clamped at `*fs-max*`; nothing during a burst, the generic rule) to him, or
  to a siphoning opponent (SIPHON-OF, the generic gain rule). A K fan is one hit group, so it hits a fighter once and
  refunds once. Pacing log `trace-refund`.
- **The CPU's budget** (no new roll; deterministic):
  - `*lb-ai-fs-reserve*` **10** (the KIN → EN price): his CPU in EN (or its stance) starts a J / K only while its lines
    leave ≥ 10 (`lb-ai-lay-ok-p`: J needs 13, K 19), through LILLE-OK for a brain only (a human's press always swings);
    LB-AI-EN-NEXT latches the string's next link under the same rule (a chained link bypasses the `:ok` hook).
  - KIN switches out (after a string, a blocked one, or the gauge under 40) only with the price + the reserve + a K
    fan's lines (`lb-ai-out-ok-p`: ≥ 29), so EN never arrives starved.
  - EN's switch in prefers the 2 f cancel: when the switch rule holds for a J1's 7 f + 2 f (9 f) and a J line is
    affordable, it presses J1 (its line laid) and the tick cancels into TENSHIN from J1's active end; else the neutral
    16 f rule (the MOVING exclusion kept); else the stance reflex; else, **starved** (no J line above the reserve), it
    switches in from neutral (free; KIN regains the flash step), unless the opponent runs / steps / Hohos
    (`lb-switch-in-rule`'s new STARVED argument).
  - The opponents' `lb-opp-trace` still keys on "his TENSHIN is ready", which from EN is now always.
- Pacing log keys added: `traces-unpaid`, `trace-refund`, `ai-switch-via-j`, `ai-switch-starved`.

**Choices (unspecified by the user)**: the middle-line-first order of a short K fan; the refund for any materialised
trace that hits, SP1 / SP2's included (the user named the refund per trace, the cost for J / K); the refund under the
generic gain rules (burst, siphon); the CPU's reserve 10 and the out rule's 29.

**Tests** (host): duel-rules **5942** ALL PASS (windup 16 / cancel 2 and the move frames; no cooldown and
`*lb-switch-cd*` unbound; EN → KIN free and allowed at 0 flash step, KIN → EN 10 and refused at 9 / 9.9; the line cost
and the ≥ 3 rule per line (J at 3 / 2.9, a K fan at 9 / 8 / 5 / 2), SP1 / SP2 free; the short fan's pick; the refund 2 on
a hit, 0 guarded, the K fan a single group; the combo on both wind-up paths; the CPU's reserve, out rule and STARVED
switch), duel-control 89, learn 100, input 33, touch 64, cine 18 ALL PASS. `tools/pkgcheck.sh duel` 0 / 0 / 0.

**Gates** (native, NORMAL): `--seeds 10 --summary` taken first in a clean worktree at the parent commit; after the
change the fifteen old pairings' 30 summary lines are **byte-identical**; `--cvc` PASS (yy / yk / kk). His six pairings,
seeds 1–20, every match K.O.:

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | **169.3 s** (167.7) | **7** (8) | 1 |
| LK | **158.8 s** (169.4) | **7** (11) | 38 |
| LR | **194.9 s** (194.0) | **4** (5) | 12 |
| LI | **194.1 s** (206.8) | **7** (8) | 10 |
| LS | **170.7 s** (193.5) | **6** (6) | 13 |
| LL | 222.4 s (244.6; mirror) | P1 9 / P2 11 | 10 |

Every cross median is inside 125–210 s. Per Lille side and match (means of 20; the mirror's sides in brackets; before
in parentheses):

| | LY | LK | LR | LI | LS | (LL) |
|---|---|---|---|---|---|---|
| TENSHIN in / out | 7.35 / 6.95 (6.5 / 6.5) | 7.0 / 6.75 (7.65 / 7.7) | 10.3 / 10.4 (8.7 / 8.7) | 10.65 / 10.25 (10.6 / 10.6) | 6.2 / 5.9 (8.8 / 8.7) | (10.7 / 10.8, 10.5 / 10.1) |
| traces laid (before) | 12.35 (16.5) | 12.95 (19.15) | 17.2 (20.15) | 22.65 (29.1) | 8.5 (16.95) | (19.5, 18.85; 28.2, 26.65) |
| lines unpaid | 0 | 0 | 0 | 0 | 0 | (0) |
| trace hits = refunds / guarded | 5.45 / 1.95 | 6.4 / 1.45 | 8.1 / 1.75 | 10.7 / 1.05 | 5.4 / 0.05 | (9.0 / 1.95, 8.3 / 1.9) |
| TENSHIN links / combos | 3.35 / 3.1 | 3.95 / 3.6 | 4.45 / 4.35 | 6.25 / 6.05 | 2.95 / 2.65 | (5.35 / 5.25, 4.6 / 4.35) |
| CPU switch in: trace rule / via J / starved | 4.75 / 0.15 / 0.75 | 4.7 / 0.05 / 1.2 | 6.0 / 0.1 / 1.5 | 7.95 / 0.05 / 0.95 | 3.2 / 0.3 / 1.1 | (6.75 / 0.1 / 1.7, 6.25 / 0.05 / 1.3) |

Read: his CPU lays a fifth to a half fewer lines (it keeps its reserve, so it never swings an unpaid line:
`traces-unpaid` 0, the human-only case), and every hit trace refunds (refunds = trace hits). Wins move within the
20-seed noise except LK (11 → 7). Not tuned (the user's playtest decides). `./build.sh duel`: 0 warnings.

### 23.9 Built: jointed translucent wings (decision 32, 2026-10-06)

The user's words: 「萊醬你能幫我將覺醒後翅膀的不透明邊界也都換成半透明嗎？然後每片翅膀改成中間加 2 節可以彎折的連接觸，讓整體動作與攻擊動畫不會太死板。」
All of it is cosmetic (`lille-art.lisp` only); no move, frame, reach, damage, kit, AI, tuning or other character changed, and no
pose or clip key (the `:u` floats untouched).

**Translucent rims** (every Jilliel form and the owl):
- The rim (outline band, teeth, hole rings, and the new joint bands and pins) is drawn see-through with the glass's glow:
  `*lb-rim-alpha*` **0.6** (was opaque, 1.0), the glass still 0.35, so the outline reads a step stronger than the leaf; both
  carry the emissive glow x their colour (`*lb-glass-glow*` 1.0), so neither goes to the dark phantom. The owl's colours are
  unchanged (glass #B89A5A, rim #8A7038; decision 11). NIJŪSHI-KŌ's lit holes fill at the rim's alpha.
- MUJITTAI fainter still: the glass 0.18 (unchanged), the rim `*lb-rim-ghost*` 0.4 → **0.3**.

**Three segments, two joints** (every blade, all eight wings of every form):
- The blade is cut at **1/3 and 2/3** of its length into three meshes (root, middle, tip) per look: `:lb-wing-0..2`,
  `:lb-wing-rim-0..2`, `:lb-wing-lit-0..2`, `:lb-wing-gold-0..2`, `:lb-wing-gold-rim-0..2` (15 weapons, replacing the 5 whole-
  blade ones). Segment I is the leaf from I/3 to (I+1)/3 moved down by I/3: its **pivot** (on the root–tip chord) is its frame's
  origin. Each rim segment has a cross band inside each cut and a pin at its pivot (the joint reads as a joint).
- **Holes and teeth redistributed**, one hole per segment (y 0.2 / 0.5 / 0.79, radii 0.045×0.065 / 0.05×0.075 / 0.038×0.052;
  were 0.36 / 0.55 / 0.73, the first straddled the joint) and the four teeth of the torn trailing edge each inside one segment
  (0.19 / 0.40 / 0.53 / 0.71; were 0.3 / 0.47 / 0.63 / 0.77).
- **Drawing** (`%LB-WINGS`, 0 B: f32vec scratch `*lb-wf*`, DEFUN-FAST helpers taking fixnums only): the straight blade's unit
  frame as before (`%LB-BASIS!`), then each joint **tilts** the next segment's frame (`%LB-TILT!`: toward the blade's width
  axis = a bend in its plane, toward its normal = a curl out of it; the frame stays orthonormal), each segment drawn from the
  previous one's end. Straight, the three segments are exactly the old blade.

**What bends them** (the fx clock, his pose and the move's frame, read only for the look; never sim state or `sim-rnd01`):
- **Idle wave**: each joint ±`*lb-wave-amp*` 0.22 rad in the plane and ±`*lb-wave-curl*` 0.1 rad out of it at
  `*lb-wave-speed*` 2.3 rad/s on the wing's own phase (the table's sway phase; the front pair offset by side), the tip's joint
  `*lb-wave-lag*` 1.1 rad behind the root's: a wave travelling root → tip. The front pair at 0.6 x, a folded wing at 0.4 x.
- **Lag and whip**: per wing a damped spring (ω 16 rad/s, ζ 0.45; memory `*lb-wm*`, per side and wing) toward a bend of
  `*lb-lag-gain*` 0.045 rad per m/s of its drive point's speed (a front wing's hand, another wing's straight tip; at most
  `*lb-lag-max*` 0.75 rad; the tip's joint 1.4 x; a jump over 1 m in a frame (a cut, a reset) counts as still). In a strike (a
  move's main phase with active frames, not an SP / Kikon; `%LB-DRIVE!`) a virtual speed along his facing and up (up share
  `*lb-strike-up*` 0.7, so the fan bends in its own plane and reads from behind) is added: the **wind-up** rises to
  `*lb-strike-in*` 14 m/s (smoothstep over the startup: the joints cock back and down, trailing), the **active frames** zero the
  spring (**snapped straight**), the **recovery** starts at −`*lb-strike-out*` 12 m/s easing out ((1−u)²: thrown forward, the
  overshoot, then the spring settles). A free wing's tip trails the motion; a front wing is pinned at both ends, so its middle
  bows behind the motion. The striking front wing takes all of it (J1 / K1's clip the right, J2 / K2's the left, the rest
  both), the other front wing 0.3, Jilliel's six table wings 0.35, the owl's eight 0.7.
- **MUJITTAI** curls each joint `*lb-fold-curl*` 0.38 rad toward the column (the tip's 1.2 x; the pinned front pair 0.5 x):
  the folded fan wraps round it.
- **SP / Kikon spread**: a slower per-side ramp (`*LB-FX*` [17]: up 2.2 / s while the spread clips play, down 3 / s) furls the
  joints `*lb-furl*` 0.55 rad toward his facing over its first 0.12, then unfurls them **from the root** (the root's joint
  over 0.12–0.52, the tip's over 0.3–0.8).

**The strike tip stays the hand**: after the joints bend, a front wing's chain (end T = (Y0 + Y1 + Y2) / 3 in blade lengths) is
turned about its root (Rodrigues, `%LB-TURN-CHAIN!`) so T points at the rig's hand, and its length set to |root → hand| / |T|:
the drawn end is the hand at every frame, bent or not (only the interior joints show the bend). Measured with a temporary
probe in the browser (KIN K1, Jilliel EN SANREN; 480 front-wing draws, joint tilts up to 0.48 rad): the chain's end missed the
hand by **0.00000 m**; on the active frames the tilts are 0 (straight). The host FK reach test reads the hand (unchanged):
ALL PASS.

**Stills** (`/tmp/claude-0/lb-art3/`, never committed; 79002 / 79014 / 79003 / 79004 / 79198, keys J / K / Shift+K, the side
camera 2109): idle behind at two moments (`b-jl-idle-a`, `-b`), the front view at two moments (`b-front-jl-a`, `-b`, the wave),
KIN K1 from behind (`b-kin-idle-behind`, `b-kin-k-windup-behind`, `-active-`, `-rec1-`, `-rec2-`) and from the side
(`b-kin-k-*-side`), Jilliel EN K and J (`b-jl-en-k-*-side`, `b-jl-j-*`), MUJITTAI behind and side (`b-mujittai-*`), the owl
behind, front, side and J (`b-owl-*`, `b-front-owl`), SANREN's furl / unfurl (`c-sp-1..4`); contact sheets `sheet-*.png`. Looked
at: the blades read as three jointed plates (the cross bands and pins at the joints, the kinks in the wave and the wind-up),
the rims see-through (Kenpachi shows through the fan's outlines from the behind camera), MUJITTAI a curled cage round the
column, the owl's wings gold. First pass (wave 0.13, strike 9 / 8 m/s along the facing only) read as planks from behind;
raised to the numbers above. Needs the user's eyes for feel.

**Gates**: host tests ALL PASS (duel-rules 5938 with the FK reach test, cine 18); `tools/pkgcheck.sh duel` 0 / 0 / 0;
`simgate.py --seeds 10 --summary` **byte-identical** to the run before the change; `--cvc` PASS; `./build.sh duel` 0
warnings. **Consing** (79195, 10 draws): the draw hook 160 B in JILLIEL, KIN and the owl, 240 B in MUJITTAI (16 / 24 B a
frame, the ECS lookup floor of §21, unchanged): the jointed wings, the springs and the drive draw 0 B. Draw calls: 48 wing
draws a form (8 blades x 3 segments x glass + rim; were 16).

### 23.13 Merged: decisions 32–34 together (the lead, 2026-10-06)

The jointed translucent wings (§23.9) and decision 34 (§23.12) merged onto decision 33's lift. Host tests ALL PASS
(duel-rules 5942, control 89, cine 18); pkgcheck 0 / 0 / 0; `--seeds 10`: the fifteen old pairings identical, and his
six pairings' lines identical with and without the wing art (the art moves no sim line); `--cvc` PASS; `./build.sh duel`
0 warnings. Stills: KIN idle and mid-K (jointed jade wings see-through, the ㄇ legs on the floor), the owl (gold). The
draw hook's steady cost is 16 B a frame in every Jilliel form and the owl (the leg floor reuses the bound fighter: a
second lookup had made it 24); the first draw of the owl after the revival builds its gold segment meshes once (~13 KB,
not per frame). Decision 34 at 20 seeds (§23.12): all K.O., medians 158.8–194.9 s, wins 7 / 7 / 4 / 7 / 6.

Measured with the refunds 4 (hit) / 2 (guarded) (seeds 1–20, every match K.O.): LY 175.5 s / 7 wins, LK 161.1 / 9,
LR 204.7 / 6, LI 181.5 / 6, LS 182.0 / 7, LL 227.2 (mirror); every cross median inside 125–210 s.

### 23.14 Decisions 35–36: the dry swing; the owl on Jilliel's system (2026-10-06)

**35** is built (lille.lisp LILLE-OK, `lb-en-dry-p`; host test): EN's J / K are refused under 3 flash step, a human's
press too (the CPU's reserve rule stands). A K with 3–8 flash step still swings and lays what it can pay (the middle line
first).

**36: the owl (`:shin`) runs Jilliel's whole system**, so everything in §22.2, §23.2, §23.11 and decision 35 holds for it:
- **Forms**: 遠 EN `:shin` (the revival enters it), its MUJITTAI `:shin-mujittai`, 近 KIN `:shin-kin`, its MUJITTAI
  `:shin-kin-mujittai`. The owl body (`:lille-shin`, the ㄇ legs, lift 0) in all four; the modes read by the wings
  and the pose.
- **L** TENSHIN (wind-up 16 f / 2 f as a cancel; wind-up → materialise → dash → J; no cooldown; EN → KIN free, KIN →
  EN 10). **U** MUJITTAI in both modes (the user: 「也是無實體」; decisions 8 / 15's "the owl trades the defence" is
  superseded), `:gg-regen` as Jilliel. **EN J / K** lay traces at 3 flash step a line (refused under 3), **SP1 / SP2**
  traces free; at most 16 traces; KIN J / K / SP direct.
- **The look**: the owl's traces (laid: a faint gold line on the floor) **materialise as 裁きの光明 審判光明, a gold
  explosion line along the ground** (the existing `:sabaki` look), not the X-Axis's jade line. **SP1** is 審判光明 (its
  motion and look: in EN it lays its lines, in KIN they burst at once); **SP2** is 神の喇叭 Trompete (its motion and
  look: in EN the wind-up then a thick trace, in KIN the direct blast). **Trompete's reflect and seal stay** (decision 9;
  the user: 「保留反射與封印」) on the direct (KIN) blast; a sealed halo seals SP2 in both modes.
- **The differences from Jilliel** (the user picked 「小」):

| | Jilliel | Owl |
|---|---|---|
| Damage multiplier (`*shin-mult*`) | 1.0 | **1.1** (was 1.2) |
| A trace's refund, hit / guarded | 4 / 2 | **5 / 2** |
| Frame advantage | as built | **+1 on every attack** (each J / K / SP recovery −1 f, so block and hit advantage +1; strings and combos re-checked) |

- Unchanged: the revival (P in any Jilliel form at ≤ 4 Konpaku: Konpaku → 1, Reishi full), taken ×1.1, the owl's Kikon
  (worth 4) and its cinematic, Trompete's numbers.

### 23.16 Decision 37: a Hoho in EN goes KIN (2026-10-06)

In **either EN form** (Jilliel `:jilliel` / `:jilliel-mujittai` and the owl's `:shin` / `:shin-mujittai`), **a Hoho**
(only: the user corrected the lead's first reading, 「只有 Hoho 會切換」; a Step does not) switches him to the KIN form of
the pair (EN → KIN, EN MUJITTAI → KIN MUJITTAI) at its frame 0, for no extra cost (the Hoho pays its own flash step
as always). **The traces are not materialised** (only L does that: decision 18); they stay live and the next
L (KIN → EN) materialises them. The CPU counts it: an EN CPU that Hohos lands in KIN.


### 23.15 Built: the owl on Jilliel's system (decision 36; and decision 37's Hoho, 2026-10-06)

The user's words (decision 36): 「請讓梟頭型態的系統設計完全與 Jilliel 對齊，只是萬物貫通的射擊特效改成審判光明（沿地面的金色爆炸線）、SP1
特效與動作用審判光明、SP2 特效與動作用神之喇叭。與 Jilliel 的主要差異是具有更高的攻擊力、更高的軌跡命中回收比例與更優異的優勢幀。」, then
「也是無實體」, 「保留反射與封印」, 「小」. Decision 37 came through the lead the same day (§23.16 on main): 「覺醒後在遠攻狀態使用閃步就會自動切換成近戰
狀態」, corrected to 「只有 Hoho 會切換」. In `duel/lisp/lille.lisp`, `duel/lisp/lille-art.lisp` (one new section of clips, the
draw hook, the looks, the HUD rows) and the host tests. **No shared file changed.**

**What is built**
- **Four owl forms** (kits): 遠 EN `:shin` (the revival enters it, as before), its MUJITTAI `:shin-mujittai`, 近 KIN `:shin-kin`, its
  MUJITTAI `:shin-kin-mujittai`; `:shin` inherits Jilliel EN, `:shin-kin` inherits `:shin` (as KIN inherits EN). All four: body
  `:lille-shin` (the ㄇ legs, lift 0), ×1.1 dealt (`*shin-mult*` 1.2 → **1.1**), ×1.1 taken (`*shin-taken*` 1.0 → **1.1**,
  Jilliel's: §23.14's "taken ×1.1"), Jilliel's `:gg-regen` 0.36, Kikon worth 4 (the owl's O module and its cinematic as built),
  form names **SHIN** / **SHIN KIN**, U tag 「U: MUJITTAI」, no `:bankai-form` / `:bankai-ok` (no revival from any owl form; the
  host test asks all four), `:endless-form :jilliel`. EN walks / runs as Jilliel EN (3.0 / 8.0), KIN as Jilliel KIN (3.8 / 8.5);
  the owl's own 4.0 / 9.0 (`*walk-shin*`, `*run-shin*`) are gone with "完全對齊".
- **The predicates** (pure, host-tested): `lb-owl-form-p`, `lb-mode-form-p` (the eight forms on the system), `lb-en-form-p`,
  `lb-kin-form-p` (now both pairs), `lb-stance-form-p`; `lb-jilliel-form-p` stays Jilliel's four (the revival's test).
  `lb-switch-target` keeps each pair (`:shin` ↔ `:shin-kin`, a MUJITTAI to the other mode); `lb-switch-price` / `-ok-p`
  (KIN → EN 10, EN → KIN free) read `lb-kin-form-p`, so they hold for the owl unchanged. LILLE-OK: TENSHIN's price and EN's dry
  refusal (decision 35) on both pairs; **a sealed halo refuses SP2 in all four owl forms** (`lb-sp2-sealed-p`).
- **Moves** (every owl J / K / SP: **R −1 f and `:adv-block` +1**, `*shin-adv*` 1, so +1 on hit and on block):

| | Owl | Jilliel (for comparison) |
|---|---|---|
| EN J1 / J2 / J3 `:lb-oe-j1…` (claw clips at `:clip-s`) | 4/3/**5**, 4/3/**5**, 5/3/**8** | 4/3/6, 4/3/6, 5/3/9 |
| EN K1 / K2 / K3 `:lb-oe-k1…` | 9/4/**9**, 10/4/**11** (enter 3), 11/5/**16** (enter 4) | 9/4/10, 10/4/12, 11/5/17 |
| EN SP1 裁きの光明 `:lb-oe-sabaki` (three chops; a trace each at f6 / f12 / f18) | S6 A14 **R11** | SANREN S6 A14 R12 |
| EN SP2 神の喇叭 `:lb-oe-trompete` (Trompete's wind-up at 3×, the trumpet forming; a thick trace at f20) | 20 / 6 / **14**, lock f10 | NIJŪSHI-KŌ 20 / 6 / 15 |
| KIN J1 / J2 / J3 (the owl's claws, 26 / 26 / 32) | 8/3/**11** −1, 7/3/**12** −1, 9/3/**17** −3 | wing strings 8/3/12 −2, 7/3/13 −2, 9/3/18 −4 |
| KIN K1 / K2 / K3 (54 / 54 / 78) | 17/4/**20** −2, 20/4/**23** −2, 21/5/**33** −19 | 17/4/21 −3, 20/4/24 −3, 21/5/34 −20 |
| KIN SP1 裁きの光明 `:lb-misuji` (three ground lines at once, one hit group; callout SABAKI NO KOMYO, was MISUJI) | 18 / – / **25** | SANREN 12/22/24 |
| KIN SP2 神の喇叭 `:lb-trompete` (240, beam, reflect + seal) | 60 / 30 / **39**, **−13** | NIJŪSHI-KŌ 40/6/30 |

  The old owl L 裁きの光明 (`:lb-sabaki`, the single line) is gone (L is TENSHIN); its hazard code serves KIN's SP1. TENSHIN for
  the owl's body: `:lb-o-switch` / `:lb-o-switch-in` / `:lb-o-switch-in-c` are Jilliel's three moves (frames, wind-ups 16 / 2 f,
  link, frame hooks) on the owl's clips; LB-EN-TICK's 2 f cancel picks the form's (`lb-switch-cancel-move`). Breaker and the
  O module unchanged. Trompete's damage, wind-up, active, reflect windows and seal unchanged; its reflect now costs him 50 % ×
  1.1 = **132** (×1.2 = 144 before).
- **Traces**: as Jilliel's (3 flash step a J / K line, refused under 3, at most 16, kept until L; materialised ×1.1: J 33, K
  26, SP1 33, SP2 198); **refund 5 on a hit, 2 guarded** (`*shin-trace-refund*`, `*shin-trace-refund-block*`; Jilliel 4 / 2),
  `lb-trace-refund` with the attacker in an owl form.
- **Decision 37 (Hoho only)**: a **Hoho started in an EN form of either pair** (Jilliel `:jilliel` / `:jilliel-mujittai`, the owl
  `:shin` / `:shin-mujittai`) switches him to that pair's KIN (`lb-hoho-target`: EN → KIN, EN MUJITTAI → KIN MUJITTAI) in LILLE-TICK
  on the Hoho's frame 0 (the tick runs after the fighter system started it). No price (the Hoho paid its flash step), **no
  materialise** (the traces stay live for the next L, KIN → EN); a Step (a tap, a run, a back-step) doesn't switch. A perfect
  Hoho out of EN MUJITTAI lands in KIN MUJITTAI and the stance's own counter-strike drop takes it to KIN, as before. The CPU
  needs no new rule: its Hoho (the generic Hoho roll, the stance's `:pass`) lands in KIN behind the opponent, where KIN's CPU runs a
  string and switches out (TENSHIN out materialises the traces); its spacing never Hohos on purpose. Pacing keys `hoho-kin`,
  `owl-hoho-kin`.
- **The CPU**: the owl EN runs Jilliel EN's reflex (LB-AI-EN: the trace switch, the 2 f cancel through a J, the starved switch, the
  stance) and table (no `:bankai`, `:kikon-range` 9.0); KIN runs Trompete's punish (LB-AI-TROMPETE, as built) then Jilliel KIN's
  (LB-AI-KIN: out after a string / on the gauge, with the flash step for EN's lines), its far band `:sp2 2` (as built: SP2 from
  8 m), `:opp-reflect (:p 0.3)` kept; both MUJITTAI the stance-out rule. KIN's string record and TENSHIN's J link read the owl's KIN.
- **The look** (cosmetic, 0 B a frame): a live owl trace is a **faint gold floor line** (`%lb-floor-line` kind 3, `:lb-line-gold`
  #CDB070; LB-TRACE-LOOK reads the draw hook's owl flag, no lookup); a materialised one is **裁きの光明's gold explosion line along
  the ground** (`:judge`, LB-LOOK: the SABAKI blasts every 1.5 m from 0.6 m to the wall, erupting at 240 m/s, each burning 0.3 s,
  a gold sheet under them and a white core on the first frames; SP2's wide). EN vs KIN read by the wings and the pose: **EN** stands
  upright, head raised, the long arms held out low (`:lb-oe-stance`), the eight gold wings fanned out (a standing spread, `*LB-FX*`
  [18], ramping 3 / s); **KIN** the hunched claw stance (`:lb-o-stance`), the wings swept back. **MUJITTAI**: the arms crossed low,
  the head bowed (`:lb-o-fold`), the wings curled round the column and ghostly (glass 0.18 / rim 0.3), the column the 0.72 phantom,
  the halo with the glow. Functional clips (lille-art.lisp ";;; ---- the owl on Jilliel's system"): `:lb-oe-stance`, `:lb-o-fold`,
  `:lb-oe-sabaki` (three chops, right / left / both), `:lb-o-tenshin` (14 f), `:lb-o-tenshin-in` (30 f; the arms raised in the
  wind-up); EN's J / K play the claw clips at `:clip-s`, EN's SP2 Trompete's clip at 3× (the trumpet look follows its frame × 3).
  The HUD: the halo row (HALO / SEALED) in all four owl forms.
- **Debug**: 79004 sets up the owl EN (`:shin`), 79007 / 79008 (the reflects) the owl KIN; new **79016 / 79017 / 79018**: forced owl
  KIN / owl EN MUJITTAI / owl KIN MUJITTAI 5 m from Kenpachi (DUEL_GAMEPLAY). `tests/scripts/duel.py`'s Lille script: the owl EN's
  traces, the materialise, its SP1 / SP2, MUJITTAI, KIN, Trompete.

**Choices (unspecified)**: the owl's walk / run as Jilliel's modes; taken ×1.1 (§23.14's table); KIN keeps the owl's claw
strings (their 26 / 54 base damage, over Jilliel KIN's 24 / 50) rather than the wing strings' numbers; KIN SP1 is the three-line
burst (MISUJI's) renamed 裁きの光明; the refund decided by his form when the trace hits (traces are cleared on the revival, so a
trace that hits an owl's opponent is the owl's); the `:judge` look's speed and burn; the EN spread (0.6 of the SP spread).

**Tests** (host): duel-rules **6367** ALL PASS (the four forms' keys, no revival from them, the predicates, TENSHIN's pairs /
prices / moves = Jilliel's on the owl's clips, every owl J / K / SP's R = Jilliel's − 1 and adv + 1, EN's string chains, the SPs'
data, the seal in both modes, the refunds 5 / 2 vs 4 / 2, ×1.1 traces, decision 37's targets; DUEL_STRINGS's budget + `owl-adv`
for the owl KIN forms, the FK reach test now on all four owl forms ±0.15 m), duel-control 89, learn 100, input 33, touch 64, cine
18 ALL PASS; `tools/pkgcheck.sh duel` 0 / 0 / 0.

**Gates** (native, NORMAL): `--seeds 10 --summary` taken first at 580f037; after, the fifteen old pairings' 30 summary lines
**byte-identical**; `--cvc` PASS (yy / yk / kk). His six pairings, seeds 1–20 (before = 580f037, the same run), every match K.O.:

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | **174.0 s** (175.5) | **14** (7) | 2 |
| LK | **168.5 s** (161.1) | **6** (9) | 36 |
| LR | **218.2 s** (204.7) | **6** (6) | 12 |
| LI | **200.2 s** (181.5) | **5** (6) | 13 |
| LS | **187.1 s** (182.0) | **6** (7) | 10 |
| LL | 232.9 s (227.2; mirror) | P1 5 / P2 15 | 9 |

LR's 20-seed median is past 210 s: the edge rerun at 60 seeds gives **207.6 s** (580f037: 199.8 s), inside the window, Lille 23
/ 60 (18). Per Lille side and match (means; the mirror's sides):

| | LY | LK | LR | LI | LS | (LL) |
|---|---|---|---|---|---|---|
| revived (sides) (before) | 14 / 19 (16) | 17 / 20 (18) | 15 / 20 (19) | 17 / 20 (16) | 15 / 20 (17) | (32 / 39 (30)) |
| owl TENSHIN in / out | 2.16 / 1.74 | 2.0 / 2.1 | 3.8 / 3.65 | 2.8 / 2.7 | 3.4 / 3.9 | (3.26 / 3.44) |
| owl traces laid / hit / guarded | 4.74 / 2.53 / 0.26 | 3.95 / 1.95 / 0.3 | 7.15 / 2.65 / 1.45 | 5.7 / 2.65 / 0.45 | 5.15 / 2.95 / 0.4 | (6.72 / 3.15 / 0.49) |
| owl flash step refunded | 13.2 | 10.35 | 16.15 | 14.15 | 15.55 | (16.74) |
| Hoho → KIN, Jilliel / owl (decision 37) | 1.05 / 0.21 | 1.2 / 0.65 | 1.5 / 0.2 | 1.1 / 0.4 | 1.75 / 1.05 | (0.72 / 0.49) |
| Trompete fired / reflected (sealed sides) | 0.05 / 0 (0) | 0.2 / 0.05 (1) | 0.05 / 0.35 (7) | 0.05 / 0.15 (3) | 0.05 / 0.3 (6) | (0.38 / 0.03 (1)) |
| all TENSHIN in / out (Jilliel + owl) | 8.58 / 8.68 | 7.75 / 8.8 | 15.15 / 16.45 | 12.0 / 12.8 | 10.8 / 12.8 | (13.33 / 13.85) |

**The revival gamble** (§20.4's test: LY / LK, seeds 1–60, Lille P1 always 31010 / never 31020; wins of 60):

| Pairing | Always | Never | Always − never | Before (580f037): always / never |
|---|---|---|---|---|
| LY | 33 | 24 | **+9** | 31 / 18 (+13) |
| LK | 15 | 15 | **0** | 20 / 20 (0) |

(The "never" side changed too: decision 37 moves Jilliel.) Medians always / never: LY 169.1 / 168.9 s, LK 171.4 / 177.3 s.
Read: the revival is still a gamble (LY at the ±9 edge, LK even), the owl now lays a handful of gold traces a match and
refunds about 5 a hit; Trompete stays rare (its KIN band and punish fire little, as built) and Rukia's / Senjumaru's guards
reflect it most. Not tuned beyond the spec.

**Consing** (79195, 10 draws): the draw hook 160 B in EN and KIN, 240 B in both MUJITTAI (16 / 24 B a frame, the ECS floor);
the gold floor lines and the `:judge` blasts cost what Jilliel's traces and line flashes cost (the probe's 8 B lookup per
hazard: owl and Jilliel identical, measured side by side); the first owl draw of a session builds its meshes once (~131 KB).
`./build.sh duel`: 0 warnings. Stills (`/tmp/claude-0/lb-owl/stills/`, never committed): the EN idle behind / side, EN K1, the
gold traces, the wind-up, the 裁きの光明 materialise at its f1 / f5 / f10 / f19, KIN after it, KIN idle / side / K1, both MUJITTAI,
EN SP1 (chops, lines, burst), EN SP2 (tell, the thick trace, its burst), KIN SP1, KIN Trompete's tell and beam, the reflect
(SEALED, the broken halo), decision 37's Hoho from owl EN / Jilliel EN / owl MUJITTAI.

### 23.17 Merged: the owl on Jilliel's system (the lead, 2026-10-06)

§23.15 merged. Host tests ALL PASS (duel-rules 6367, control 89, learn 100, input 33, touch 64, cine 18); pkgcheck 0 /
0 / 0; `--seeds 10`: the fifteen old pairings identical; `--cvc` PASS; `./build.sh duel` 0 warnings. Stills checked: the
owl's laid traces (faint gold floor lines) and their materialise (the gold explosion line along the ground). Seeds 1–20
(§23.15): every match K.O.; LY 174.0 s / 14 wins, LK 168.5 / 6, LR 218.2 / 6 (60 seeds 207.6: inside), LI 200.2 / 5,
LS 187.1 / 6, LL 232.9. Revival gamble LY +9 (the ±9 edge), LK 0.

### 23.18 Decision 38: the owl's two modes at a glance; EN Trompete faster (2026-10-06)

**The look** (the lead's design; cosmetic): mirror Jilliel's own split (EN floats legless, KIN stands on legs), so the
silhouette alone tells the mode:
- **Owl EN**: **floats** (the form's `:lift`, as Jilliel EN's 0.5 m) with the **ㄇ legs folded up** under the column
  (tucked, not on the floor); upright, the S-neck raised tall; the eight gold wings **spread wide and forward** in a
  full fan (the holes facing the opponent), the long arms hanging open at the sides.
- **Owl KIN**: **stands on the ㄇ legs** (lift 0), the column **pitched forward** (~20°), the neck lowered and thrust
  forward like a stalking bird, the wings **swept back and narrowed** behind (blades trailing), the claws raised forward.
- MUJITTAI keeps each mode's silhouette (EN floating tucked, KIN on its legs), ghosted.
- TENSHIN plays the change (legs unfold / tuck, wings sweep) inside its dash.

**EN Trompete** (`:lb-oe-trompete`): S 20 → **12** (the tell; its track / lock scaled), R 14 → **8**; A 6 and the
thick trace unchanged. The KIN (direct) Trompete is unchanged.

### 23.20 Decision 39: the laying shot (2026-10-06)

Every trace laid in EN (Jilliel and the owl; J, K, SP1 and SP2) fires a shot along its line at the laying frame: a
2-frame hazard of its own (`:lb-nick`, the trace's `:cap`), **1 damage** (× the form's multiplier, rounded: 1), a
**flinch held 10 f** (`*lb-nick-stun*`; it interrupts a move like any hit and counts in a combo), no hitstop, **guardable
as a plain ranged hit** (no chip, 2 guard gauge drained; not the X-Axis), `:ranged`. A K fan's three lines share one hit
group (one shot hits a fighter once). It is not the trace: it gives no flash-step refund and the trace still waits for
L to materialise. The lead picked 10 f and 2 (the user may move them).

Measured (seeds 1–20, every match K.O.; the fifteen old pairings identical at 10 seeds): LY 177.3 s / 12 wins, LK 182.2
/ 5, LR **223.2** / 6, LI **220.4** / 8, LS 206.3 / 6, LL 248.4. The browser shows the shot: EN J1's line hit for 1, a K
fan's once. **LR and LI past 210 s**, so the edge rerun at 60 seeds: **LR 229.6 s** (22 wins of 60), **LI 216.2 s** (24 of
60): still outside the window. By the gate policy this goes to the user; no other knob was retuned (the 10 f flinch
interrupts and lengthens the matches).


### 23.19 Built: decision 38 (2026-10-06)

The user's words: 「1. 梟頭模式幫我設計更明顯的遠程和近戰視覺差異，目前看不出『遠程模式翼張開、站直，近戰模式翼往後收、身體前傾』這樣的設計。
2. SP2 神之喇叭在遠程模式的前後搖再縮短。」 In `duel/lisp/lille.lisp` (the owl kits' `:lift`, EN Trompete, the EN MUJITTAI
stance, two cinematic stance clips, debug 79198), `duel/lisp/lille-art.lisp` (poses, clips, the legs, the wings) and the host
tests. **No shared file changed** (DUEL_GAMEPLAY's 79198 line updated).

**1. The two modes at a glance** (cosmetic: the sim never reads it)

| | 遠 EN (`:shin`, `:shin-mujittai`) | 近 KIN (`:shin-kin`, `:shin-kin-mujittai`) |
|---|---|---|
| Height | **floats**: kit `:lift` `*lb-owl-lift*` **0.35 m** (was 0 in all four) | stands, lift 0 |
| ㄇ legs (`%LB-LEGS`) | **folded up**: the tuck (`*LB-V*` [8], 0..1) turns the front shank back and the rear one forward by `*lb-tuck-turn*` 1.4 rad, each `*lb-tuck-len*` 0.48 m: a short bar under the column, ~0.8 m above the floor | down to the floor, as built (decision 26) |
| Column / neck (`:lb-oe-stance` / `:lb-o-stance`) | bolt upright (spine 0, was −4), the S-neck raised (neck −6, head −4), the long arms hanging open (flex 10, side 30), thighs 12 | **pitched forward**: spine 22 (was 4), the neck lowered and thrust forward (neck 26, head 8), the claws raised forward (arms flex 58 side 14, elbows 70; were 8 / 12) |
| The eight gold wings (`%LB-WINGS`) | **spread wide and forward**: `*lb-owl-en-spread*` **0.9** of the SP spread (was 0.6) | **swept back** (`*LB-V*` [29] the sweep, 0..1): the fan closed into a narrow sheaf (elevations × 0.35 − 48°, out × 0.3), trailing back (+1.3) and down (−0.9) along the pitched back, 0.8 × long, the blade faces turned to the side (edge-on from behind) |
| MUJITTAI | `:lb-oe-fold` (new; EN's upright pose, arms crossed, afloat, legs tucked), ghosted | `:lb-o-fold` (now on the pitched KIN pose), on its legs, ghosted |

- **One ramp** carries the change: `*LB-FX*` [18] runs toward EN at **5 / s** (was 3 / s, the wings only) and drives the
  tuck ([8] = it) and the sweep ([29] = 1 − it) for the owl only (Jilliel's are 0: unchanged). It now runs before the legs are
  drawn (moved out of the owl's wing branch).
- **TENSHIN plays the change**: the form (and with it the lift) flips inside the dash (KIN → EN at f6 of 14, EN → KIN at
  f22 of 30); the ramp folds / unfolds the legs and sweeps / fans the wings over the next 12 f. The clips hide the lift's
  step: `:lb-o-tenshin` rises 0.4 m to f6 then keys u 0.05 at f6.5 (the draw sees f6 before the form and f7 after), and
  `:lb-o-tenshin-in` dives to u −0.25 at f22 then 0.1 at f22.5 (both steps are the 0.35 lift; the clips say so).
  `:lb-o-tenshin-in`'s fold key is EN's (`:lb-oe-fold-pose`).
- **The strike points did not move**: the KIN hit poses set the spine, the striking arm and (new: `:lb-o-q3-hit`,
  `:lb-o-f3-hit`) both elbows (12, the old stance's) themselves, so the new stance changes no hand position on an active frame;
  the host FK reach test passes unchanged on all four owl forms (±0.15 m). EN's J / K still play the claw clips (no hit
  volumes).
- The revival cinematic (enters EN) and Trompete's Kikon cinematic now end in **the form's own stance**
  (`(kit-stance (kit-of a))`, was `:lb-o-stance`); `:lb-o-point` / `:lb-o-reveal` are posed on EN's stance. In the revival the
  lift appears at f66 (the body change, under its negative impact frame).
- Debug 79198 cycles four looks: JILLIEL / KIN / the owl EN / **the owl KIN** (the front view of both owl modes).

**2. EN Trompete** (`:lb-oe-trompete`): S 20 → **12**, R 14 → **8**, A 6 and the thick trace unchanged (laid at f12, was f20);
the planted turn's lock f10 → **f6** at 60 → **100** deg/s (the same 10° at most); the clip (Trompete's 60 f wind-up) plays at
**5×** (was 3×: `:clip-s` 60 / S 12) and the trumpet look follows the clip's speed (LILLE-DRAW: sf × 60 / S). The KIN
(direct) Trompete is unchanged. The test that pinned EN SP2 = Jilliel EN's SP2 − 1 now pins 12 / 6 / 8, the on-frames,
the lock, the turn, the clip speed and no hit volume.

**Deviations from §23.18** (the lead's design):
- **The lift is 0.35 m, not Jilliel's 0.5**: the owl is about a metre taller than Jilliel (x1.5 legs, the S-neck), and at 0.5
  its head went under the HUD in the behind and side cameras; with the legs tucked its lowest point still clears the floor by
  ~0.8 m (the shadow far below it), so the float reads at 0.35. A one-number change (`*lb-owl-lift*`, plus the two TENSHIN
  steps).
- KIN's wings are swept back **and down** (a folded bird's along the pitched back), not straight back: straight back (or up)
  they pointed at the behind camera and loomed larger than EN's fan (first two passes).
- EN MUJITTAI got its own pose / clip `:lb-oe-fold` (upright) so MUJITTAI keeps each mode's silhouette.

**Tests** (host): duel-rules **6367** ALL PASS (the owl's lifts: EN / EN MUJITTAI 0.35, KIN / KIN MUJITTAI 0; EN Trompete
12 / 6 / 8 and its keys; EN MUJITTAI's stance; the FK reach test on all four owl forms), duel-control 89, learn 100, cine 18
ALL PASS; `tools/pkgcheck.sh duel` 0 / 0 / 0.

**Gates** (native, NORMAL): `--seeds 10 --summary` taken first at 0186b8b; after, the fifteen old pairings' 30 summary lines
**byte-identical**; `--cvc` PASS (yy / yk / kk). His six pairings, seeds 1–20, every match K.O. (before: §23.15's run of the
same sim code):

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | **174.3 s** (174.0) | **15** (14) | 2 |
| LK | **165.1 s** (168.5) | **6** (6) | 36 |
| LR | **218.2 s** (218.2) | **7** (6) | 12 |
| LI | **200.2 s** (200.2) | **4** (5) | 13 |
| LS | **200.9 s** (187.1) | **4** (6) | 10 |
| LL | 226.7 s (232.9; mirror) | P1 6 / P2 14 | 9 |

LR's 20-seed median is past 210 s (as before): the edge rerun at 60 seeds gives **207.6 s** (§23.15: 207.6 s), inside the
window, every match K.O., Lille 25 / 60 (23).

The art moves no sim line (the lift, the legs and the wings are draw-only; the old fifteen are identical); the shifts above
are the EN Trompete's (it is rare: §23.15's pacing had it 0.05–0.4 a match).

**Consing** (79195, 10 draws): the draw hook **160 B** in EN and KIN, **240 B** in both MUJITTAI (16 / 24 B a frame, the ECS
floor, unchanged): the tuck, the sweep and the ramp draw 0 B. (The probe's first call of a session reports ~131 KB: the
probe's own queue growing once; its second call in the same form reads 160.) `./build.sh duel`: 0 warnings.

**Stills** (`/tmp/claude-0/lb-owl2/`, never committed; 79004 / 79016 / 79017 / 79018 / 79198, the side camera 2109, keys L,
J, Shift+L): `contact-owl-modes.png` (EN | KIN from behind, the side and the front, both MUJITTAI behind and side),
`contact-owl-motion.png` (TENSHIN in at f14 / f22 / f25 and from behind at f22, TENSHIN out at f15 and after, EN Trompete's
tell at f2 / f10 and the thick trace at f14, KIN J1, EN J1), `contact-before-after.png` (the build before and after, behind and
side). Read: EN is a tall, floating, upright figure under a wide gold fan with its legs folded up; KIN a pitched stalker
on its ㄇ stilts, claws forward, the wings a narrow sheaf behind; from the front KIN's wings all but vanish. The feel needs the
user's eyes.

### 23.21 Merged: decisions 38 and 39 together (the lead, 2026-10-06)

§23.19 (the owl's two silhouettes, EN Trompete S 12 / R 8) merged onto decision 39 (the laying shot). Host tests ALL PASS
(duel-rules 6367, control 89, cine 18); pkgcheck 0 / 0 / 0; `--seeds 10`: the fifteen old pairings identical; `--cvc`
PASS; `./build.sh duel` 0 warnings. The contact sheet shows the owl EN floating (legs tucked, the fan spread) and KIN
standing pitched forward (the wings swept back). Seeds 1–20: LY 173.1 s / 13 wins, LK 182.2 / 6, LR **223.8** / 6, LI
**219.9** / 8, LS 206.3 / 6, LL 239.5 with **one time-out** (19 of 20 K.O.). LR and LI stay past 210 s (decision 39's
open question, with the user) and the mirror lost a K.O.: reported, not retuned.

### 23.22 Accepted exception: LR and LI past 210 s (the user, 2026-10-06)

Asked about decision 39's pacing (LR 229.6 s, LI 216.2 s at 60 seeds; §23.20), the user chose: 「接受這兩組例外」. Both
pairings are recorded as accepted exceptions (AGENTS.md "Tests and gates"); the 10 f flinch of the laying shot stays.
The mirror (LL) had one time-out in 20 seeds (§23.21; the gate wants every match K.O.); asked, the user added it:
「也算進例外」 (2026-10-06): the Lille mirror's time-outs are an accepted exception too.

### 23.23 Decision 41: the snap and the crossing slow motion replace the laying shot (2026-10-07)

The user's words: 「我希望去除掉軌道設置時造成的 1 點傷害，但這樣的話有會很難讓實體化能打中對手，你有什麼好想法嗎？」. The lead
proposed four ways (A a pierce mark, B a 0-damage flinch, C a snap at materialise, D a slowing zone). The user chose 「C+對手經過軌道的
瞬間會有時緩」, and for the slow, 「全場慢動作」 (the whole match, like a perfect Hoho's, not only the opponent).

- **The laying shot is gone** (decision 39's `:lb-nick` hazard, `lb-nick-hitwin`, `*lb-nick-dmg*` / `-stun*` / `-guard*`):
  laying a trace deals nothing and holds nothing.
- **The snap** (`lb-snap-yaw`, `*lb-snap-max*` **10°**, the lead's number): at TENSHIN's materialise every live trace turns
  about where it was laid toward the opponent by at most 10°, then hits along the turned line (the look flashes there).
  At 10 m that is ~1.7 m sideways; a K fan's three lines may all turn onto him, but they are one hit group (hit once).
- **The crossing slow motion** (`lb-trace-cross` in `lb-hz`'s `:step`, `lb-cross-p`): a live trace tests the opponent's hurt
  cylinder against its line (the hit's own test) each step; his stepping onto it (on now, off last step; a trace laid
  on him counts) runs `SLOWMO` for everyone at **0.35** for **0.3 s** of real time (`*lb-cross-scale*`, `*lb-cross-secs*`;
  a perfect Hoho's is 0.25 for 0.45 s), not again for **30 steps** (`*lb-cross-rearm*`, a K fan or a walk along 16 traces
  would chain it). The crossed line flares (2.5× width for 24 frames). The sim frames are the same: slow motion only gives
  a human more real time to press L (a CPU acts in sim frames). All three numbers are the lead's.
- **His CPU** reads the gap to a trace as it would materialise (`lb-ai-trace-gap` with `lb-snap-yaw`). The combat log's
  combo opener no longer skips a nick.
- **The search** (§24): b0a0 / b1a0 were measured on decision 39's rules; b1a0's opener (§24.3) rode the nick's 10 f
  flinch, which is gone. The paused search restarts from a new freeze on these rules (the evaluator's drift reference
  and the baseline re-measured).

Tests: duel-rules **6370** ALL PASS (the knobs, the snap's turn and clamp, a snapped line through him, the crossing's edge
and re-arm; decision 39's hitwin checked gone); control 89, learn 100, cine 18; `tools/pkgcheck.sh duel` 0 / 0 / 0.

Gates (native, NORMAL; only `duel/lisp/lille.lisp` changed, so his pairings): seeds 1–20, every match K.O. (before:
§23.21, decisions 38 + 39):

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | **164.7 s** (173.1) | **10** (13) | 1 |
| LK | **166.4 s** (182.2) | **10** (6) | 38 |
| LR | **200.0 s** (223.8) | **7** (6) | 14 |
| LI | **223.9 s** (219.9) | **6** (8) | 15 |
| LS | **194.0 s** (206.3) | **12** (6) | 11 |
| LL | 231.1 s (239.5; mirror, one time-out before) | P1 12 / P2 8 | 11 |

LR is back inside the window (the 10 f flinch had lengthened it, §23.20). LI's edge rerun at 60 seeds: **212.1 s** (§23.20:
216.2 s), every match K.O., Lille **12 / 60** (24): still just past 210 s, inside the accepted exception (§23.22), so
reported, not retuned. Without the nick's flinch he wins less against Ichigo. The mirror had no time-out in 20.
`./build.sh duel` 0 warnings; the page starts with no error (`tools/run.mjs`, 6 s). The awaken A/B was not re-run (as for
decision 39). Slow motion leaves every sim frame as it was; its feel (0.35 / 0.3 s / 30 steps) needs the user's playtest.

### 23.24 Decision 42: TENSHIN in reaches 10.4 m (2026-10-07)

The user's words: 「另外 L 轉成近戰時能跳躍的範圍要提升 1.3 倍」. TENSHIN in's dash (EN → KIN, Jilliel's and the owl's) goes up to
**10.4 m** at him (`*lb-switch-in*` 8.0 × 1.3), still over 14 f (`*lb-switch-f*`, so 0.74 m a frame instead of 0.57) and
still stopping 1.5 m short; the out dash (7.0 m) is unchanged. The clips are not stretched: the leap's arc is the same
frames, it covers more ground.

Tests: duel-rules 6370 ALL PASS (`lb-switch-dist` at 12, 20 and 11 m: 10.4, 10.4, 9.5).

Gates (native, NORMAL; his pairings), seeds 1–20, every match K.O. (before: §23.23, decision 41):

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | 164.7 s (164.7) | **11** (10) | 1 |
| LK | 166.4 s (166.4) | 10 (10) | 38 |
| LR | 200.0 s (200.0) | 7 (7) | 14 |
| LI | **208.7 s** (223.9) | 6 (6) | 15 |
| LS | **196.6 s** (194.0) | **11** (12) | 11 |
| LL | **203.9 s** (231.1; mirror) | P1 10 / P2 10 | 11 |

Every cross pairing is inside 125–210 s at 20 seeds (LI too, so no edge rerun). His CPU switches in from the gap to a
trace, not from the distance, so the longer reach changes little in CPU play; the feel is the user's playtest.
`./build.sh duel` 0 warnings.

### 23.25 Decision 43: longer TENSHIN, the K → L bug, half-speed slow motion (2026-10-07)

The user's words: 「1. 後撤距離提升到 10m，接近距離也提升到 13m。 2. 現在近戰 K 打完連擊後接到 L 後撤的距離會被限制住，這應該是 bug？
3. 時緩改成放慢 1 倍。」

1. **TENSHIN** (Jilliel's and the owl's): out (KIN → EN) **10.0 m** (`*lb-switch-out*` 7.0 → 10.0), in (EN → KIN) up to
   **13.0 m** at him (`*lb-switch-in*` 10.4 → 13.0, still stopping 1.5 m short); both still over 14 f.
2. **The bug, confirmed and fixed.** An L pressed during a KIN K link is latched (KIT-L-LINK) and starts TENSHIN out as a
   chained follow-up. `main-phase-step` gives a chained non-J / K move the string chase in its startup, and TENSHIN's whole
   14 f dash is its startup. So the chase ran him at the opponent while the slide carried him away. It was worst after
   K3, whose push sends the opponent off and makes the chase fast. A browser script (`79014` KIN, `2393` 2.2 m apart,
   K K K then L, `2107` hash lines) measured the old build's dash after K3 at **0.88 m** (x 0.33 → −0.55, of 7.0). The fix
   is the switch moves' new tick `lb-switch-tick`, which zeroes his walk / chase velocity each frame before
   `lb-link-tick`, so the dash's slide is the switch's only movement (in and out alike; Lille's file only). The same
   script on the fixed build: **10.0 m** (x 0.33 → −9.67).
3. **The crossing slow motion**: first read as half speed (0.35 → 0.5); the user corrected it: 「抱歉，應該是倍率改 0.1
   然後可重複觸發」. So `*lb-cross-scale*` **0.1** (a tenth of the speed; a perfect Hoho's is 0.25), still 0.3 s of real
   time (about 2 sim frames), and **every crossing fires** (`*lb-cross-rearm*` 30 → 0; each trace still fires once per
   crossing onto it, its on / off edge).

Tests: duel-rules 6370 ALL PASS (`lb-switch-dist`: in 10.5 m at 12 m, 13.0 at 20 and 14.5 m; out 10.0; the switch moves'
tick `lb-switch-tick`; the slow at 0.1, no re-arm).

Gates (native, NORMAL; his pairings), seeds 1–20, every match K.O. (before: §23.24, decision 42):

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | **177.3 s** (164.7) | **14** (11) | 1 |
| LK | **162.9 s** (166.4) | **7** (10) | 37 |
| LR | **222.1 s** (200.0) | **8** (7) | 16 |
| LI | **203.5 s** (208.7) | 6 (6) | 11 |
| LS | **182.3 s** (196.6) | **10** (11) | 12 |
| LL | 222.9 s (203.9; mirror) | P1 12 / P2 8 | 9 |

LR is past 210 s again. The edge rerun at 60 seeds gives **222.8 s**, every match K.O., Lille 22 / 60. That is still outside
the window but under the 229.6 s the user accepted for LR (§23.22), so it is reported to the user, not retuned. A longer
back dash (10 m) keeps Rukia's matches at range longer. pkgcheck 0 / 0 / 0; `./build.sh duel` 0 warnings.

With the corrected slow motion (0.1, no re-arm), seeds 1–20, every match K.O.:

| Pairing | Median (with 0.5) | Lille wins / 20 (with 0.5) | Blow-aways |
|---|---|---|---|
| LY | 178.6 s (177.3) | **8** (14) | 1 |
| LK | 172.5 s (162.9) | 8 (7) | 37 |
| LR | **235.4 s** (222.1) | 8 (8) | 13 |
| LI | 203.5 s (203.5) | 6 (6) | 7 |
| LS | 197.7 s (182.3) | 10 (10) | 11 |
| LL | 253.5 s (222.9; mirror) | P1 6 / P2 14 | 10 |

The gate times a match in fixed steps (`*match-tick*` / 60, real time, as a player feels it), so every crossing's
0.3 s at 0.1 adds ~0.27 s to the measured length. The win counts move too: the slow motion shifts how sim frames fall
on steps, and code that reads `*match-tick*` sees that (the same as a perfect Hoho's slow motion; deterministic).
LR's edge rerun at 60 seeds: **217.5 s**, every match K.O., Lille 20 / 60: outside the window, under the accepted
229.6 s; reported, not retuned.

**Accepted** (the user, 2026-10-07): asked whether LR 217.5 s (60 seeds) stays an exception, the user answered
「可以接受」. It is recorded in AGENTS.md "Tests and gates" with the earlier LR / LI exceptions.

### 23.26 Decision 44: the traces' slow motion counts them as one region (2026-10-07)

The user asked: 「［討論］如果我希望非常相近的軌道不要連續觸發時緩效果應該要怎麼做呢？」. The lead proposed four ways: (A) every live
trace as one region plus a time off, (B) one state per move's lines, (C) skip a crossing near the last one, and (D) merge
lines at laying. The lead also noted that the re-arm counted fixed steps, which the slow motion itself runs through
~18 at a time at 0.1. The user chose: 「用 A，N 先用 10 f，等這輪跑完再改」 (made after round 1's first two cells, §24.4).

- **The rule** (`lb-trace-cross`, now per sim frame from `lille-tick` in any non-base form; `lb-cross-p`, `lb-cross-off-next`):
  the opponent is "on the traces" when his hurt cylinder touches any of Lille's live trace lines (the hit's own test).
  The slow motion (0.1 for 0.3 s, unchanged) fires when he is on them after **≥ 10 sim frames** (`*lb-cross-off*`)
  on none. Any frame on any line resets the count.
  - A K fan, lines laid side by side, and a gap crossed in under 10 frames (≈ 0.6 m at a 3.8 m/s walk) slow it once.
  - Well-spaced lines still fire one each.
  - A trace laid on him counts as stepping on.
  - The lines he is on when it fires flare.
- Decision 43's per-trace edge (`lbh-on`, its own hazard `:step`) and the step-counted re-arm (`*lb-cross-rearm*`,
  `lbs-cross-t`) are gone. The count is in sim frames (the kit's `:tick` runs once a sim frame), so the slow motion
  can't shorten it.

Tests: duel-rules 6370 ALL PASS (`*lb-cross-off*` 10; `lb-cross-p`: on after 10 and 9999 frames off fires, after 9 or 0
doesn't, off never; the count resets on, counts up off, caps at 9999). pkgcheck 0 / 0 / 0.

Gates (native, NORMAL; his pairings), seeds 1–20, every match K.O. (before: §23.25's 0.1 run):

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | 173.5 s (178.6) | 8 (8) | 1 |
| LK | 166.5 s (172.5) | 9 (8) | 34 |
| LR | **204.4 s** (235.4) | 10 (8) | 16 |
| LI | 211.1 s (203.5) | 9 (6) | 17 |
| LS | 205.4 s (197.7) | 6 (10) | 10 |
| LL | 236.0 s (253.5; mirror) | P1 8 / P2 12 | 10 |

LR is back inside the window: fewer slow motions, so fewer seconds added (the gate times real time, §23.25). LI's 211.1 s
is just past 210, and its edge rerun at 60 seeds gives **207.5 s**, every match K.O., Lille 29 / 60. Every cross pairing
is inside 125–210 s. `./build.sh duel` 0 warnings.

### 23.27 Decision 45: fresh traces vs old traces (2026-10-07)

The user's words: 「如果是才剛新生成的軌道就算重疊也一樣觸發時緩，而經過舊軌道的時緩參數改成 0.3 倍速持續 1 秒。」

- **A fresh trace** (laid this frame: `lbh-fresh`, set at laying, cleared after its first test in `lb-trace-cross`) that
  touches him starts the slow motion at **0.1 for 0.3 s** (`*lb-fresh-scale*`, `*lb-fresh-secs*`: decision 43's numbers).
  It fires whatever other traces he stands on and however long he has been off them.
- **Old traces** keep decision 44's rule: stepping onto the live traces after ≥ 10 sim frames off all of them. Their slow
  motion is now **0.3 for 1.0 s** (`*lb-cross-scale*` 0.1 → 0.3, `*lb-cross-secs*` 0.3 → 1.0).
- Both on the same frame: the fresh one only (`lb-cross-kind`: `:fresh` before `:cross`). Either resets the off count
  (he is on a trace). The lines that started it flare.
- Read by the lead: the fresh rule keeps 0.1 / 0.3 s (the request names new numbers only for the old traces).

Tests: duel-rules 6370 ALL PASS (the four numbers; `lb-cross-kind`: fresh fires with 0 or 50 frames off, old after 10,
not after 9, nothing off the traces). pkgcheck 0 / 0 / 0.

Gates (native, NORMAL; his pairings), seeds 1–20, every match K.O. (before: §23.26):

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | 184.4 s (173.5) | 8 (8) | 1 |
| LK | 174.5 s (166.5) | 11 (9) | 40 |
| LR | **236.2 s** (204.4) | 7 (10) | 11 |
| LI | **214.3 s** (211.1) | 7 (9) | 9 |
| LS | 198.2 s (205.4) | 12 (6) | 12 |
| LL | 242.9 s (236.0; mirror) | P1 6 / P2 14 | 10 |

The gate times real time, and each old-trace slow motion now adds ~0.7 s (1 s at 0.3). The edge reruns at 60 seeds, every
match K.O.:
- **LR 222.5 s**, Lille 15 / 60; the accepted LR was 229.6 s (§23.22), then 217.5 s (§23.25).
- **LI 215.9 s**, Lille 18 / 60; the accepted LI was 216.2 s (§23.22).

Both are outside the window and reported to the user, not retuned. `./build.sh duel` 0 warnings.

### 23.28 Decision 46: the slow motions retimed (2026-10-07)

The user's words: 「再稍微換一下時緩參數 新軌：0.1 倍速 0.1 秒 舊軌：0.3 倍速 0.3 秒」. The fresh trace: `*lb-fresh-scale*` 0.1
(as before), `*lb-fresh-secs*` 0.3 → **0.1**; the old traces: `*lb-cross-scale*` 0.3 (as before), `*lb-cross-secs*` 1.0 →
**0.3**. The rules (decisions 44, 45) are unchanged. Each fresh slow now costs ~0.09 s of real time and each old one ~0.21 s
(they were ~0.27 s and ~0.7 s).

Tests: duel-rules 6370 ALL PASS (the four numbers).

Gates (native, NORMAL; his pairings), seeds 1–20, every match K.O. (before: §23.27):

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | 165.7 s (184.4) | 13 (8) | 2 |
| LK | 168.4 s (174.5) | 6 (11) | 43 |
| LR | **222.6 s** (236.2) | 6 (7) | 15 |
| LI | 199.1 s (214.3) | 7 (7) | 12 |
| LS | 196.9 s (198.2) | 11 (12) | 12 |
| LL | 225.5 s (242.9; mirror) | P1 5 / P2 14 | 12 |

LI is back inside the window. LR's edge rerun at 60 seeds gives **217.8 s**, every match K.O., Lille 23 / 60. That is
about the 217.5 s the user accepted (§23.25), but still outside 210, so it is reported to the user. `./build.sh duel`
0 warnings.

### 23.29 Decision 47: the slow motions retimed again (2026-10-07)

The user's words: 「再稍微換一下時緩參數 新軌：0.1 倍速 0.2 秒 舊軌：0.2 倍速 0.5 秒」.
- The fresh trace: `*lb-fresh-scale*` stays 0.1, `*lb-fresh-secs*` 0.1 → **0.2**.
- The old traces: `*lb-cross-scale*` 0.3 → **0.2**, `*lb-cross-secs*` 0.3 → **0.5**.
- The rules (decisions 44, 45) are unchanged.
- Real time per slow motion: ~0.18 s for a fresh trace, ~0.4 s for old traces.

Tests: duel-rules 6370 ALL PASS (the four numbers).

Gates (native, NORMAL; his pairings), seeds 1–20, every match K.O. (before: §23.28):

| Pairing | Median (before) | Lille wins / 20 (before) | Blow-aways |
|---|---|---|---|
| LY | 177.9 s (165.7) | 9 (13) | 1 |
| LK | 169.3 s (168.4) | 5 (6) | 43 |
| LR | **193.5 s** (222.6) | 9 (6) | 12 |
| LI | 203.9 s (199.1) | 8 (7) | 10 |
| LS | 195.6 s (196.9) | 8 (11) | 10 |
| LL | 259.4 s (225.5; mirror, may exceed) | P1 6 / P2 14 | 9 |

Every cross pairing is inside 125–210 s at 20 seeds, so no edge rerun. LR is back inside: the slow motions shift how
sim frames fall on steps, so the 20-seed medians move by more than the seconds they add. `./build.sh duel` 0 warnings.

### 23.30 Decision 49: TENSHIN 3 m shorter (2026-10-07)

The user's words: 「覺醒後 L 的近遠切換移動距離減少 3m」.
- `*lb-switch-in*` 13.0 → **10.0** m (still stopping 1.5 m short), `*lb-switch-out*` 10.0 → **7.0** m; both still over 14 f.
- His CPU's EN web band follows TENSHIN in's reach (`*lb-ai-web-band*` (2.5 13.0) → **(2.5 10.0)**, so the dash still brings
  KIN's J1 to him; the host test pins the band within in + stop).

Tests: duel-rules 6388 ALL PASS (`lb-switch-dist`: in 10.0 at 12 and 20 m, 9.5 at 11 m; out 7.0). Gates, seeds 1–20,
every match K.O.:

| Pairing | Median (before, §24.8) | Lille wins / 20 |
|---|---|---|
| LY | 176.6 s (177.9) | 14 |
| LK | 173.2 s (169.3) | 6 |
| LR | 196.4 s (193.5) | 10 |
| LI | 206.8 s (203.9) | 9 |
| LS | 192.4 s (195.6) | 5 |
| LL | 235.7 s (259.4; mirror) | P1 10 / P2 10 |

Every cross pairing is inside the window. His HARD CPU (`aieval --char 5 --seeds 40`): **0.9992** (strength 1.000,
signature 0.998), drift 0.44 (the reference), pacing all K.O.

### 23.31 Decision 50: Jilliel's strikes redone (2026-10-07)

The user: 「Jilliel 近戰的動作不太明顯，能跟我討論要如何修改動作模組嗎？」. As built, EN and KIN share one set of clips
(`:lb-w-q1`…`:lb-w-f3`):
- only the front wing pair swings, and the column slides 0.08–0.72 m;
- KIN's ㄇ legs don't move;
- the other six wings follow at 35 %.

The lead proposed four directions. The user chose all four and both modes: 「全身出招」「每招獨立造型」「翼尖斬痕」「八翼一起斬」,
「近戰＋遠程都換」.
1. **Whole body**: KIN's legs step or lunge, the column leans and twists, the wings swing in wide arcs, each strike a
   clear wind-up → swing → recovery.
2. **Each strike its own shape**: J1 / J2 left / right cuts, J3 a two-wing cross, K1 a spin, K2 the counter-spin, K3 a
   rising two-wing cleave with a landing.
3. **Wing-tip slash trails**: a jade arc behind the striking tips (a look only).
4. **All eight wings strike**: the other six converge on the target in the active frames (in turn), not 35 % sway.

EN (laying traces) gets its own reworked clips too. Presentation only: the sim never reads art, the hit volumes and
frame data are unchanged, and the drawn reach must still equal the hit reach (the host FK test, ±0.15 m). The owl's
forms are not in scope.

**Built** (art batch, 2026-10-07; `duel/lisp/lille-art.lisp`, the EN defmoves' `:clip` in `lille.lisp`, the host test).

*Two clip sets.* KIN keeps the names `:lb-w-q1 … :lb-w-f3`, redone in place. EN gets its own six casts
`:lb-e-q1 … :lb-e-f3`, authored at EN's frames: `:lb-e-j1 … :lb-e-k3` point at them, and their `:clip-s` is gone (clip
speed 1; it was KIN's clips at ×1.75–2). Every key is written as the wings' aim: azimuth and elevation in the chest frame
(the comment above each key). The column moves with them:
- the root's turn, forward slide, height and pitch;
- the spine's lean and the chest's twist;
- on KIN, the thighs, so the ㄇ legs stride; the shanks keep their feet on the floor.

| Strike | Frames (S / A / R) | What it does |
|---|---|---|
| KIN J1 左斬 | 8 / 3 / 12 | The right wing cocked high behind (f5–7: twist −28°, turned 10° right, leaning back, the weight back), then a step in (right thigh +30°, left −18°): the wing cuts right → left, through the front at S, across to the left at f15. |
| KIN J2 右斬 | 7 / 3 / 13 | J1's mirror: the left wing, left → right. |
| KIN J3 十字 | 9 / 3 / 18 | Both wings raised high and wide (70° up), the column arched back and 0.12 m up, then both crossed down through the front (an X) with a step and a 0.3 m lunge, on down and through. |
| KIN K1 旋 | 17 / 4 / 21 | Coiled 58° right and crouched (f6–8.5), then one full turn left on the legs (408° by S): the right wing sweeps through the front at S with a 0.6 m lunge, and the turn's overshoot settles. |
| KIN K2 逆旋 | 20 / 4 / 24 (enter 6) | The counter-spin, K1's mirror: coiled left from its entry, one full turn right, the left wing. |
| KIN K3 昇翼 | 21 / 5 / 34 (enter 7) | A crouch (0.2 m down), both wings swept low behind, then a rising two-wing cleave: forward at S with a 0.72 m lunge, up through the active frames. He rises 0.5 m, so the shanks leave the floor and the legs fold. Then the landing: 0.16 m down, the legs splayed, the wings down, and back up. |
| EN J1 | 4 / 3 / 6 | A cast: the right wing raised high behind, the column leaning back, then thrown forward and down along the line on S (the lay frame), on down to −46°. |
| EN J2 | 4 / 3 / 6 | J1's mirror (the left wing). |
| EN J3 | 5 / 3 / 9 | Both wings raised overhead and crossed down onto the line. |
| EN K1 | 9 / 4 / 10 | A whirl: coiled, one full turn, the right wing fanning low across the front through the active frames (the fan of three). |
| EN K2 | 10 / 4 / 12 (enter 3) | The counter-whirl, the left wing. |
| EN K3 | 11 / 5 / 17 (enter 4) | Rising 0.34 m with both wings overhead, then slammed down onto the line on S, the column dropping 0.2 m (the landing). |

*The spins.* A full turn of the root without an unwinding turn at the clip's end:
- two keys 0.0001 f apart (at a half frame, 8.5 / 8.5001 in K1) are the same pose with the root's yaw 360° apart;
- the turn runs from there to S;
- so every clip starts and ends at yaw 0. The sampling window between the two keys is 1.7 µs, never hit by a 60 Hz frame.

*The reach* (the host FK test, the art at the active frames vs the volume's end):
- KIN J1 / J2 1.65 m against 1.60, J3 1.70 / 1.70, K1 / K2 2.20 / 2.20, K3 2.25 / 2.30, all within ±0.15.
- EN's casts have no hit window, so a new check (after the FK block) wants the cast's tip at the move's `:reach` on S,
  the frame its line is laid, ±0.15 m. Measured: J1 / J2 1.62 (1.6), J3 1.71 (1.7), K1 / K2 2.25 (2.2), K3 2.31 (2.3).
- The EN frame check now wants EN's own clip at speed 1 (it pinned KIN's clip at `:clip-s` / S).
- The clip list of §5 gains the six casts.

**八翼一起斬, the eight wings converge** (`%LB-WINGS`, `%LB-CONV-SHARE`):
- In a Jilliel strike (`*LB-JILLIEL-STRIKES*`), the six table wings turn from their fan places toward a target. Each is
  stretched to reach it (at most ×`*lb-conv-stretch*` 1.3), its face turned to his side.
- They go in turn: the striking side's wing first, the top pair down, both sides at once when both front wings strike.
  The first launches `*lb-conv-from*` −2 f from S, the next ones `*lb-conv-step-j*` 0.8 f (K: `-k` 1.0) apart. Each
  arrives over `*lb-conv-ramp*` 2.5 f, is held to the active end + `*lb-conv-hold*` 3 f, and goes back to its fan place
  over `*lb-conv-out*` 0.5 of the recovery.
- **KIN's target** is his hit point: where he stands along his facing at the move's reach − 0.1 m, at chest height. The
  six tips meet in a ring `*lb-conv-ring*` 0.22 m wide round it, each on its own side, top, middle or below.
- **EN's target** is the line ahead on the floor: the top pair `*lb-conv-near*` 2.2 m out, each pair below
  `*lb-conv-gap*` 0.9 m further. A K's top pair aims at its middle line and the pairs below at its outer lines (±6°); a J's at its one line.
- "Where he stands and faces" takes the clip's root offset and turn out of the pelvis frame, so a spin's or a lunge's
  pose doesn't move the target.
- The springs zero on the active frames as before, so the converged blades are straight. The 35 % share of the strike
  drive stays; it bends the wings on the way in and out.
- Jilliel's lag springs count a drive point as a jump (no lag) only past 2 m a frame (`*lb-jump-jl*` 4 m²; the owl
  keeps 1 m²). His spins sweep a tip up to ~1.8 m a frame, and that should still trail.

**翼尖斬痕, the tip trails** (`%LB-TRAILS`, `%LB-SMEAR`):
- Per side and front wing: a trail of the elbow → hand (the wing's outer stretch), recorded while the strike's window is
  open (S + `*lb-trail-from*` −5 to the active end + `*lb-trail-to*` 3) and the tip has moved (a hitstop keeps the arc).
  Outside the window it fades a sample a frame.
- It is drawn as the duel's sword smear (vfx.lisp `VFX-SMEAR`'s comet crescent, re-captured on the fx clock's drawings),
  in jade (`+pal-jade+`), through the 0.85 point (`*lb-smear-at*`), half-width 0.14 × the elbow → hand length
  (`*lb-smear-w*`), presence 0.7 (`*lb-smear-k*`).
- The striking wings: J1 / K1 and EN's the right, J2 / K2 the left, J3 / K3 both.
- A first pass at VFX-SMEAR's own numbers (0.7 point, 0.33 width, 0.98 presence) read as a jade plank across the
  screen; it was cut to the numbers above.

**The owl is untouched**: its clips are not on the list, so its wings take the old path; its jump stays 1 m² and it has
no trails.

**Gates**
- Host tests ALL PASS: duel-rules **6412** (6388 + the 24 EN cast checks), control 89, learn 100, cine 18.
- `tools/pkgcheck.sh duel` 0 / 0 / 0; `./build.sh duel` 0 warnings.
- `simgate.py --seeds 10 --summary` (all 21 pairings, 42 lines) is **byte-identical** to the same run at `8c93f92`;
  `--cvc` PASS (yy, yk, kk).

**Consing** (debug 79195, 10 draws of the draw hook, in the running scene; KIN, EN, the owl EN and KIN, each idle, at
f3 / 9 / 15 / 18 / 22 / 30 of a K and f2 / 5 / 9 / 12 / 18 of a J):
- Before and after alike: **160 B** for every sample (16 B a frame, the ECS lookup floor of §21). The first sample
  builds the meshes once (131 256 B), the same before and after.
- A first build drew 184 B once, in EN 7 f after a K. The trail shifted its samples with REPLACE (the engine's
  TRAIL-PUSH / TRAIL-DECAY do the same), and REPLACE of a vector onto itself allocated here. The shift is now an explicit
  forward copy (`%LB-TRAIL-DROP`): 0 B.

**Stills** (`/tmp/…/scratchpad/jilliel-art/`, never committed):
- Debug 79014 (KIN) / 79002 (EN), then 2393 and six frames of W in, then the J and K strings mashed. Shots every 2
  frames, behind and side camera (2109); the same script on `8c93f92`'s build.
- Contact sheets `review/after-*-keys.png`: wind-up, before, the hit, follow-through, recovery.
- `review/before-after-*.png`; per-strike strips `review/strips/`; GIF sequences `review/seq/`.
- Checked by numbers (FK, the converge targets logged in a scratch build). The look needs the user's eyes.

### 23.32 Decision 52: TENSHIN in 4.5 m, a trial (2026-10-07)

The user's words: 「幫我試試看把覺醒後 L 的前衝距離改成 4.5m」 (a trial: kept while the user plays it).
- `*lb-switch-in*` 10.0 → **4.5** m (still stopping 1.5 m short, over 14 f); `*lb-switch-out*` stays 7.0 m.
- His CPU's EN web band follows TENSHIN in's reach as at decision 49 (`*lb-ai-web-band*` (2.5 10.0) → **(2.5 4.5)**).

Tests: duel-rules 6411 ALL PASS (`lb-switch-dist`: in 3.5 at 5 m, 4.5 at 6 / 12 / 20 m; out 7.0). Gates, seeds 1–20,
every match K.O.:

| Pairing | Median (decision 49, §23.30) | Lille wins / 20 (before) |
|---|---|---|
| LY | 177.6 s (176.6) | 11 (14) |
| LK | 179.5 s (173.2) | 5 (6) |
| LR | 204.1 s (196.4) | 9 (10) |
| LI | 203.5 s (206.8) | 10 (9) |
| LS | 205.1 s (192.4) | 8 (5) |
| LL | 238.4 s (235.7; mirror) | P1 8 / P2 12 |

Every cross pairing is inside the window. His HARD CPU (`aieval --char 5 --seeds 40`): **0.9983** (strength 1.000, masher
1.000, signature 0.996, drift share 0.4475 vs 0.44: ok; 0.9992 before): trace combos 21.7 %, HOSHA link 18.5 %, charged
shot 8.6 %, about as before. `./build.sh duel` 0 warnings.

### 23.33 Decision 53: TENSHIN at a fixed speed; its link no longer chases (2026-10-07)

The user asked (discuss first, then change): 「為什麼 L 前衝後的 J1 也會往前衝呢？」. The answer: since round 2 (decision
25) a J / K latched during TENSHIN in fires at the dash's end with `fighter-end-chase` set (`lb-link-tick`), the Breaker's
J1 / K1 rule: its startup chases him at up to `*ender-chase-max*` 40 m/s until he is in reach. With decision 52's 4.5 m
dash that undid the cut: J1 still landed from ≈ 11 m, K1 from ≈ 17 m. Offered: chase only the 1.5 m gap, no chase,
the plain link's 18 m/s cap, or keep it. The user's answer: 「完全拿掉追擊，L 前衝停在對手前 1m，移動改成固定速度而不是固定時間，
後徹距離改成兩個 step 的長度、前衝距離改成兩個 step + 0.5m 的長度」; asked the speed and the scope: **30 m/s** (TENSHIN out's
old 7 m / 14 f), the chase removed from **TENSHIN's link only** (HOSHA's keeps it: its loop needs it).

- `*lb-switch-in*` 4.5 → **5.5** m (`(+ (* 2 *step-distance*) 0.5)`), `*lb-switch-stop*` 1.5 → **1.0** m,
  `*lb-switch-out*` 7.0 → **5.0** m (`(* 2 *step-distance*)`): both follow the Step's length.
- New `*lb-switch-speed*` **30** m/s: the dash takes `lb-switch-dash-f` = ⌈60 d / 30⌉ frames (at most `*lb-switch-f*` 14):
  5.5 m 11 f, 5.0 m 10 f, 2 m 4 f. The move follows the dash: its end (`lbs-dash-end`) is the link frame
  (`lb-link-frame`, also ASSIST's `lb-as-tenshin`), and with nothing linked `lb-switch-tick` skips the rest of the startup
  into the 8 f recovery (the form changes there if the dash ended before its f6). Before, every dash took 14 f.
- `lb-link-tick`: only HOSHA's link sets `fighter-end-chase`; TENSHIN's J1 / K1 start where the dash left him.
- His CPU's EN web band follows TENSHIN in's reach: `*lb-ai-web-band*` (2.5 4.5) → **(2.5 5.5)**.

Measured in the browser (`tools/run.mjs`, `2107` hash lines): KIN K K K then L from 2.2 m: the back dash **4.99 m**
(x 0.33 → −4.66), done within 10 f; EN 9.1 m out, L then J: the dash **5.5 m** (x −8.00 → −2.50) over 11 f, then KIN's J1
**in place** (x −2.50 through its frames: a whiff 3.6 m short); from 2.2 m the dash is 1.2 m and stops 1.0 m short.

Tests: duel-rules 6411 ALL PASS (the knobs; `lb-switch-dist` in 4.0 at 5 m, 5.0 at 6, 5.5 at 12 / 20, 0 at 0.9; out 5.0;
`lb-switch-dash-f` 11 / 10 / 4 / 1 / 0 / 14), learn 131; pkgcheck 0 / 0 / 0; `./build.sh duel` 0 warnings.

Gates, seeds 1–20 (NORMAL):

| Pairing | Median (decision 52, §23.32) | Lille wins / 20 (before) |
|---|---|---|
| LY | 161.4 s (177.6) | 10 (11) |
| LK | 169.0 s (179.5) | 7 (5) |
| LR | 205.9 s (204.1) | 4 (9) |
| LI | 190.2 s (203.5) | 1 (10) |
| LS | 195.5 s (205.1) | 4 (8) |
| LL | 235.0 s, 19 K.O. (238.4; mirror, its time-outs an accepted exception) | P1 9 / P2 11 |

Every cross median is inside 125–210 s, but **Lille's NORMAL wins fall** (LR 4, LI 1, LS 4 of 20). His HARD CPU
(`aieval --char 5 --seeds 40`): strength 0.995, masher 1.000, signature 0.993, but the **drift check fails** (share 0.3325
vs the frozen 0.44 ± 0.05: the score reads 0): trace combos 21.7 → 13.9 %, the SANREN cash-out 0.8 → 5.3 %. His CPU was
tuned (dream-rsi b3a2) on a dash that brought J1 to him from 11.5 m. Not retuned: reported to the user (AGENTS.md).

### 23.34 Decision 54: TENSHIN in up to 7 m (2026-10-07)

The user's words: 「將前衝距離改成最多 7m」.
- `*lb-switch-in*` 5.5 → **7.0** m (decision 53's rules kept: 1 m short, 30 m/s, no chase on its link): a 7 m dash takes
  14 f (`lb-switch-dash-f`, the cap). TENSHIN out stays 5.0 m.
- His CPU's EN web band follows: `*lb-ai-web-band*` (2.5 5.5) → **(2.5 7.0)**.

Tests: duel-rules 6435 ALL PASS (`lb-switch-dist` in 7.0 at 12 / 20 m, 6.5 at 7.5 m; `lb-switch-dash-f` 7 m → 14).
Gates, seeds 1–20 (NORMAL), every match K.O.:

| Pairing | Median (decision 53, §23.33) | Lille wins / 20 (before) |
|---|---|---|
| LY | 162.9 s (161.4) | 9 (10) |
| LK | 169.0 s (169.0) | 7 (7) |
| LR | 200.7 s (205.9) | 8 (4) |
| LI | 184.2 s (190.2) | 2 (1) |
| LS | 195.5 s (195.5) | 6 (4) |
| LL | 245.9 s (235.0; mirror) | P1 5 / P2 15 |

Every cross median is inside 125–210 s. Lille's wins come back against Rukia and Senjumaru; Ichigo stays at 2 of 20.
His HARD CPU (`aieval --char 5 --seeds 40`): strength 1.000, masher 1.000, signature 0.998 (trace combos back to 21.4 %,
13.9 % at decision 53), but the drift check still fails (share 0.3425 vs the frozen 0.44 ± 0.05; the score reads 0): not
retuned, reported. `./build.sh duel` 0 warnings.

---

## 24. The adaptive, in-character CPU (dream-rsi; the user, 2026-10-06)

The user: 「然後幫我依據 @docs/guides/DREAM_RSI.zh-TW.md 的 AI 開發經驗設計並強化更具有角色風格的利捷巴羅自適應 AI，記得要能與玩家輔助 AI
系統結合，以幫助玩家打出更具風格的漂亮連段。」 Asked (DREAM_RSI §7's pre-run questions), the user chose: 「完整 dream-rsi」,
「風格偏重 0.4/0.2/0.4」, 「完整招牌路線」, 「學習玩家習慣」.

### 24.1 The plan (DREAM_RSI's checklist applied)

1. **Freeze the evaluator first** (`tools/aieval.py --char 5`, one commit, checked on the baseline and one or two
   hand-made variants before any cell runs):
   - **score = 0.4 strength + 0.2 masher + 0.4 signature** for Lille (the other characters keep 0.6 / 0.2 / 0.2);
   - **signature = a whitelist** (DREAM_RSI §5.9), the share of Lille's dealt damage from: materialised traces
     (`LB-TRACE`, Jilliel's and the owl's), any J / K hit in a combo a trace hit started (trace → TENSHIN → J / K),
     HŌSHA's bullets and the J1 / K1 they link into, the charged X-Axis shot, TAISHA, the SPs (SANREN, NIJŪSHI-KŌ,
     審判光明, Trompete) and his Kikon; never the Breaker, never a plain J / K string;
   - **a NORMAL drift gate**: Lille NORMAL vs each other NORMAL CPU, both seats; its win share more than 0.05 away from
     the frozen baseline's → score 0 (DREAM_RSI §5.5);
   - **pacing** as before (every NORMAL match a K.O., median ≤ 220 s at 20 seeds) except the accepted exceptions: LR /
     LI ≤ 240 s (§23.22);
   - fixed seeds; cells compare at 40 seeds, the final pick at 80.
2. **Opponents fixed** at the freeze commit (the other five CPUs as shipped); every cell's worktree starts there.
3. **Cells** change only `duel/lisp/lille.lisp`'s `:ai` tables and CPU functions (and its CPU knobs), keep every
   shared hook working (`AI-AWAKEN-P`, the revival's `:bankai` reflex, debug modes, the learning CPU's read clock, the
   ASSIST's borrowed brain: `AI-BRAIN`), every chance per event and difficulty-scaled; pass the host tests; run the awaken
   A/B before handing back if they touch the awakening; write deliverables inside their own worktree (the lead copies).
4. **dream-rsi**: W = 2 (two cells at a time), ≥ 3 rounds × 8 cells, `plan --beta 0.6`, between rounds 3–5 written
   policy revisions compared on the replay pool; `set-direction` only structural. The lead re-scores every cell with
   the frozen evaluator before `record`.
5. **Integration** (after the search, one agent): the learning CPU (`learn.lisp`, DUEL_LEARNING) gains Lille's own
   situations (e.g. which way the player steps off a trace, whether he guards or Hohos a materialise, his answer to
   HŌSHA), and the ASSIST's AUTO COMBO gets **his full signature routes** on the player's J (HŌSHA hit → J1 / K1; enough
   traces with the opponent on a line → TENSHIN → J; a KIN string done → TENSHIN out), assisted presses ×0.8 as always;
   then the full gate (simgate, A/B, assistgate, the learning gate, host tests, G2, build).

### 24.2 The frozen evaluator (phase 0, 2026-10-06)

`tools/aieval.py --char 5` (the other characters' scoring unchanged: `--char 0..4` at 4 seeds give the same JSON as
before, part for part), the workspace `docs/research/lille-ai-drsi/` (README there). **The freeze commit is the last
commit touching `tools/aieval.py`, `tests/duel-rules-test.lisp` or the workspace's `baseline/drift-ref.json`** (the one
that adds the LILLE-CPU-TESTS markers below; the scripts find it with `git log -1 --` those paths; `FREEZE=<hash>`
overrides).

**Score** = 0.4 strength + 0.2 masher + 0.4 signature for Lille (the user: 「風格偏重 0.4/0.2/0.4」); the others keep
0.6 / 0.2 / 0.2. 0 when a gate fails.
- **strength**: HARD Lille vs each of the five other HARD CPUs, both seats; his win share. **The mirror is not played**
  (as for every character: Lille vs Lille is 0.5 by symmetry and tells nothing).
- **masher**: HARD Lille as P2 vs the button-masher bot as P1, each of the six characters (his own included: the masher
  plays none of his CPU), N × 4 / 5 seeds each; his win share (his seat is always P2: the 2026-10-02 seat fix).
- **signature**: the share of his dealt damage (the written damage of his hit lines, strength runs) on the whitelist:
  - by name: the materialised traces (`LB-TRACE`, Jilliel's and the owl's), HOSHA's bullets (`LB-K-J`), TAISHA
    (`LB-K-K`), the SPs: SANREN (`LB-SANREN`), the base SP2 HIRENKYAKU (`LB-HIREN`: an SP and an X-Axis shot; the plan's
    list didn't name it, the lead's call), NIJŪSHI-KŌ (`LB-NIJUSHI`), 審判光明 / 裁きの光明 (the owl KIN's ground lines,
    hazard `LB-SABAKI`), Trompete (`LB-TROMPETE`; EN's SP1 / SP2 lay traces, their damage is `LB-TRACE`'s), the Kikons
    (`LB-KIKON`, `LB-W-KIKON`, `LB-O-KIKON`);
  - by a log tag the sim writes after the hit (`Px lb-sig TAG`, `LB-SIG-LOG` in lille.lisp, only while `*COMBAT-LOG*` is
    on): `charged` (the stance's X-Axis shot fired charged; the quick shot is not his signature), `hosha-link` (the
    J1 / K1 a HOSHA hit linked into; only that link, not the string after it), `trace-combo` (any J / K hit in a combo a
    materialised trace opened; a combo's opener is its first hit that isn't a laying shot, so the via-J switch's nick
    → traces → TENSHIN → J counts);
  - never: the Breakers, a plain J / K string, the quick shot, the Hoho's counter strike; the laying shot `LB-NICK`
    (1 damage) counts on neither side. The JSON's `sig_by` breaks his damage down by these categories.
  - The tag is log-only: no sim state reads `lbs-sig-origin`; `simgate.py --seeds 10 --summary` (all 21 pairings, 42
    lines) is byte-identical before and after it.
- **pacing**: NORMAL Lille (P1) vs each other character: every match a K.O., median ≤ 220 s, vs Rukia and vs Ichigo
  ≤ 240 s (the accepted exceptions, §23.22). A K.O. is read off the RESULTS line's Konpaku for him: the old rule ("a
  match under 299.5 s") counts his K.O.s past 300 s of match ticks (the cinematics run in them) as time-ups; the other
  characters keep the old rule (frozen 2026-10-02; the same latent bug, a follow-up for their next search).
- **drift**: NORMAL Lille vs each other NORMAL CPU, both seats (the pacing runs are the P1 half); his win share more
  than 0.05 from the frozen baseline's at the same seed count (`baseline/drift-ref.json`: 40 seeds 0.4275, 80 seeds
  0.4188) → 0; no reference for the seed count → 0.
- **Seeds**: fixed, 1..N; `--seeds` default 20; the cells compare at 40, the final pick at 80. `--pace-seeds` /
  `--drift-seeds` (a cheaper split) exist but aren't needed (below). `--write-drift-ref` wrote the references.

**Timings** (this machine, 4 cores): one `--char 5 --seeds 40` eval **318 s at -j 2, 163 s at -j 4** (the same JSON);
two cells' evals at once, -j 2 each, with their native builds (~3 min): **503 / 530 s**; 80 seeds at -j 4: 315 s. So
no split: every part at 40 seeds.

**The baseline** (the freeze, 40 seeds; `baseline/score.json`): **score 0.4769** = strength **0.140**, masher
**1.000**, signature **0.552**; pacing LY 175.0 / LK 176.0 / LR 223.5 (cap 240) / LI 217.1 (cap 240) / LS 205.3 s, all
K.O.; drift 0.4275 (Y 42, K 29, R 29, I 37, S 34 of 80). His damage: plain J / K 37 %, trace combos 19 %, traces 14 %,
the Kikons 12 %, Breaker 4 %, counters 3 %, HOSHA 2.5 % + its links 1.8 %, NIJŪSHI-KŌ 2 %, HIRENKYAKU 1.6 %, the charged
shot 1.2 %, the quick shot 1 %, SANREN 0.7 %, TAISHA 0.4 %, Trompete 0.3 %. At 80 seeds (`score80.json`): 0.4836 =
0.154 / 1.000 / 0.555, drift 0.4188.

**Hand-made variants** (40 seeds, the parts move as they should):

| Variant | Score | Strength | Masher | Signature | Drift | What moved |
|---|---|---|---|---|---|---|
| baseline | 0.4769 | 0.140 | 1.000 | 0.552 | 0.4275 | |
| never switches modes (EN never TENSHINs in, KIN never out) | **0** | 0.072 | 0.922 | 0.316 | **0.2925 (fail)** | traces 14 → 2.5 %, trace combos 19 → 2.7 % (MUJITTAI's exit still TENSHINs), plain J / K 37 → 58 % |
| never uses the shooting stance (base `:sig` out of the bands, `:l-after-k` 0) | 0.4729 | 0.133 | 1.000 | 0.550 | 0.4075 | charged shot, HOSHA, its links, TAISHA, the quick shot → 0; the rest's shares up |

Read: the base stance is a small share of his damage as shipped (~6 %); the signature lives in Jilliel's traces and
their combos. The masher part is saturated (1.000): it adds a constant 0.2 unless a cell breaks it. The strength part
is the room (0.14 at HARD, while his NORMAL drift share is 0.43). LS's NORMAL median (205 s) is within 15 s of its cap:
a pacing risk for any cell that slows him down.

**The loop, dry-run** (on a throwaway copy of the workspace): `plan --beta 0.6` → `step.sh next` wrote b0a0 / b1a0's
briefs; `step.sh done` with the baseline file as b0a0 re-measured it in the rescore worktree at the freeze (host test,
then the eval: 492 s) as **0.4769, the same JSON**, recorded `ok`; the never-switch variant as b1a0 was recorded score 0,
`--fail-class correctness`, "gate failed: drift"; the no-stance variant failed the frozen host test (a check pins the
stance in every base band) and was recorded `correctness`.

**The host test's CPU section** (the lead, 2026-10-06: decision 1 of the phase-0 report). The host test pins his CPU's
shipped keys and values (the eye, the stance, the switch tables, the flash-step reserve 10, the stance's branch table),
so a cell could only route around them. Now `tests/duel-rules-test.lisp` marks his own CPU's checks with
`;;; >>> BEGIN LILLE-CPU-TESTS` … `;;; <<< END LILLE-CPU-TESTS`; a cell may edit that section and deliver the file, and
`rescore.sh` splices only those lines into the frozen test (`splice-tests.py`), writing the section's diff to
`NODE_DIR/test-section.diff` for the coordinator's review. The section's checks must still pin the cell's own shipped
values (a pin is updated, not deleted) and may not weaken a test of shared behaviour, a rule, a hook or another character.
Those stay outside the markers, frozen: a new check before the markers pins `:reflex LB-AI-REFLEX` on all ten forms, no
`:opp-aim`, and the keys a CPU facing him reads (`:opp-reflex LB-OPP-TRACE` on EN, `:opp-trace :p 0.5`, none on KIN or
the base form); the owl section keeps its rule (the trace stun) with `:opp-reflex` / `:opp-reflect` / `:reflex`, and the
owl's own CPU values (`:switch`, `:trompete`, `:stance`) moved into the marked section. duel-rules **6369** checks ALL PASS
(6367 + those two); pkgcheck 0 / 0 / 0; `simgate.py --seeds 10 --summary` identical (no sim change).
Dry run again (a throwaway copy of the workspace): the baseline as b0a0 re-scored at the freeze reproduces **0.4769**
(498 s); the no-stance variant as b1a0 with its section edited (the base-band pin turned into "no `:sig` in any band") and,
outside the markers, a frozen check deliberately broken: the splice took only the section (the diff shows that one line),
the outside edit was ignored, the host test passed (6369), recorded `ok` at **0.4729** (488 s), the same as its run above.

### 24.3 The snap opener is accepted (the user, 2026-10-06)

Round 1's cell b1a0 (rescored 0.9027 at 40 seeds: strength 0.140 → 0.932, signature 0.552 → 0.824, NORMAL drift and
pacing unchanged) found a HARD-only opener: EN J1 laid straight at the opponent, its laying shot's 10 f flinch, J1's 2 f
TENSHIN cancel, the materialise → KIN J string. It is nearly unreactable for a human too. Asked, the user chose
「接受，繼續搜尋」: the rules and the frozen evaluator stay; the search goes on; a rule change after a playtest would mean a
re-measure of the search's results.

### 24.4 The search restarts on decisions 41–43 (the user, 2026-10-07)

The user paused the search (「先暫停」, 2026-10-06) during round 1. The rules then changed: the laying shot is gone, traces
snap at materialise, crossing a trace slows the match, and TENSHIN reaches 13 m in / 10 m out (decisions 41–43, §23.23–§23.25).
Then the user asked: 「可以接受，請幫我 commit&push 並推送到 gh page，之後重新開始風格化自適應 AI 的研究。」

- **The old run is archived** under the workspace's `archive/v1/`: its config, policy, round 1 (b0a0 0.9124, b1a0 0.9027
  rescored; b2a0 / b3a0 stopped unfinished, their partial worktrees removed) and its baseline. Those numbers were measured on
  decision 39's rules; b1a0's opener rode the laying shot's 10 f flinch, which no longer exists (§24.3 is moot). The
  briefs point the new cells at it as ideas to re-test, not results.
- **The new freeze** is the commit that writes the new `baseline/drift-ref.json` (the scripts find it as before). The
  evaluator is unchanged apart from a comment (`PACE_CAP` still 240 s vs Rukia and Ichigo, now covering the accepted
  217.5 s LR of §23.25). The laying shot `LB-NICK` no longer exists, so its "counts nowhere" rule in §24.2 is moot.
- **The new baseline** (`duel/lisp/lille.lisp` at the freeze, `baseline/lille.lisp`):

| Seeds | Score | Strength | Masher | Signature | Drift (the new reference) |
|---|---|---|---|---|---|
| 40 | **0.4496** | 0.105 | 1.000 | 0.519 | **0.4125** (Y 39, K 32, R 27, I 28, S 39 of 80) |
| 80 | 0.4513 | 0.109 | 0.995 | 0.522 | **0.4400** |

  Pacing at 40 seeds (NORMAL, all K.O.): LY 176.8, LK 170.2, LR 216.2 (cap 240), LI 203.9 (cap 240), LS 196.8 s (cap
  220). His damage: plain J / K 39.8 %, trace combos 17.7 %, traces 10.3 %, the Kikons 12 %, Breaker 3.7 %, counters
  3.4 %, HOSHA 2.9 % + its links 2 %, NIJŪSHI-KŌ 2.2 %, HIRENKYAKU 1.8 %, the charged shot 1.4 %, the quick shot 1.1 %.
  Against the old baseline (0.4769, strength 0.140, signature 0.552), he is weaker at HARD without the flinch.
- **`drsi.py init` again**: W 2, branches 4 × refines 2, λ 0.25, the baseline 0.4496, the default policy (the same file
  as before), `eval_command` unchanged. The plan of §24.1 holds: at least 3 rounds, dreaming between them, then the
  integration (the learning CPU's Lille situations, ASSIST's signature routes) and the full gate.

### 24.5 Round 1's first batch, and the re-freeze on decision 44 (2026-10-07)

Round 1's first two cells, rescored at the freeze `03fb042` (40 seeds; NORMAL drift and pacing identical to the
baseline in both; every new behaviour is a HARD-only layer):

| Cell | Score | Strength | Signature | The mechanism |
|---|---|---|---|---|
| b0a0 | **0.9612** | 0.970 | 0.933 | EN "mark and spring": J1 laid straight at an open opponent, TENSHIN's 2 f cancel when he is on a line (its materialise 9 f after the press, inside a HARD CPU's perception), the KIN J string; KIN "vanish" (out again once it can pay); the base form's "hunt": the stance → HOSHA, its link K1 with L latched (bullets → K1 → stance → bullets) |
| b1a0 | **0.9600** | 0.975 | 0.925 | EN "web": a J line every 6 f at 2.5–13 m, the switch when enough hit groups would hit where he will be (1 on a free opponent, 2–3 on a committed one), a wary read after 2 misses; KIN hit-and-run; the same HOSHA → K1 → stance loop; an SP2 cash-out on a landed string (`:sp-ender`, also used by the ASSIST) |

Both found the same two engines on their own: the near-instant materialise (decision 39's flinch was never what made
round 1 v1's opener work) and the HOSHA loop. The cells' recommendations for shared code (the generic ORANGE burst breaks
the HOSHA loop; AI-ATTACK's no-whiff rule keeps EN's J / K silent at range at NORMAL; re-run `tools/assistgate.py` for
b1a0's `:sp-ender`) are kept for the integration. The first rescore of b0a0 aborted on the rescore worktree's leftover
files (recorded 0 by mistake): `rescore.sh` now forces its checkout, and b0a0 was re-recorded (`FORCE`).

Then the user's decision 44 (§23.26: 「用 A，N 先用 10 f，等這輪跑完再改」) changed the rules after that batch. **The re-freeze**
is the commit that writes the new `drift-ref.json`. The new baseline (the shipped CPU on decision 44):

| Seeds | Score | Strength | Masher | Signature | Drift (the new reference) |
|---|---|---|---|---|---|
| 40 | **0.4480** | 0.098 | 0.995 | 0.525 | **0.4675** (Y 38, K 36, R 34, I 43, S 36 of 80) |
| 80 | 0.4495 | 0.099 | 0.997 | 0.526 | **0.4550** |

Pacing at 40 seeds: LY 177.2, LK 165.8, LR 210.3 (cap 240), LI 208.9 (cap 240), LS 200.2 s (cap 220): all K.O.

The two recorded cells are re-measured at the new freeze `6081a39`. This was done with `FORCE`, because the rule changed
under them; it was not a retry for a better score.
- Their files carried the old freeze's rules code, so the frozen host test failed on decision 44's `*LB-CROSS-OFF*`.
- Each cell's change is therefore ported onto the new freeze's `lille.lisp` by a 3-way merge (base: the old freeze's file).
  Both merged cleanly, and their diffs against their base are the same lines.
- The cells' originals stay in their nodes as `lille.cell-03fb042.lisp`.

| Cell | Score at `03fb042` | Score at `6081a39` | Strength | Signature |
|---|---|---|---|---|
| b0a0 | 0.9612 | **0.9518** | 0.948 | 0.932 |
| b1a0 | 0.9600 | **0.9563** | 0.968 | 0.923 |

Drift 0.4675 and pacing are identical to the new baseline in both. The round goes on with b2a0 / b3a0 from the new freeze;
their first briefs, written at the old freeze, were withdrawn undispatched.

### 24.6 Round 1's branches, and the re-freeze on decision 47 (2026-10-07)

Round 1's four branch cells, all rescored at `6081a39` (decision 44; 40 seeds; NORMAL drift 0.4675 and pacing identical
to that baseline in every one):

| Cell | Score | Strength | Signature | What it added |
|---|---|---|---|---|
| b0a0 | 0.9518 | 0.948 | 0.932 | EN mark and spring, KIN vanish, the base hunt and the HOSHA → K1 → stance loop |
| b1a0 | 0.9563 | 0.968 | 0.923 | EN web (a J line every 6 f, the snap volley, a wary read), KIN hit-and-run, the loop, an SP2 cash-out |
| b2a0 | **0.9941** | 1.000 | 0.985 | both openers + composure (a held J keeps the generic ORANGE from breaking the loop), okizeme (stance / J1 timed to his wake-up), KIN's J1 → K2s → K3 route and its exits |
| b3a0 | 0.9869 | 0.993 | 0.975 | b1a0's engines + a spacing rule (HOSHA only beyond J1's reach + 0.2 m: ORANGE off HOSHA 1.98 → 0.15 a match), the KIN → EN → KIN crossfire off K3's crumple, enders by frames left, refusals (no Breaker, no non-red O over a combo) |

Read: the strength part is saturated at HARD (0.95–1.0); signature is the room left, and both of the best cells closed
the same leak (the generic ORANGE off a HOSHA bullet) in two different ways. All four test diffs only add checks.
Shared-code recommendations collected for the integration: an ORANGE kit key (so composure's held-J trick can go), an
AI-ATTACK reach-filter flag for EN's ranged J / K at NORMAL, a wake-up field in the snap, and `tools/assistgate.py`
re-run for the `:sp-ender` hooks (they act for an assisted human).

Then decisions 45–47 changed the slow motions (a gate-timed rule, §23.27–§23.29). Round 1's refine cells (b0a1 …) had
not started; their briefs, written at the old freeze, were withdrawn. **The re-freeze** is the commit that writes the new
`drift-ref.json`. The new baseline (the shipped CPU on decision 47):

| Seeds | Score | Strength | Masher | Signature | Drift (the new reference) |
|---|---|---|---|---|---|
| 40 | **0.4449** | 0.095 | 1.000 | 0.517 | **0.4400** (Y 44, K 28, R 31, I 35, S 38 of 80) |
| 80 | 0.4529 | 0.113 | 1.000 | 0.520 | **0.4650** |

Pacing at 40 seeds: LY 174.2, LK 169.2, LR 198.1, LI 209.0, LS 194.7 s, all K.O. The four branch cells are ported onto the
new freeze's `lille.lisp` by a 3-way merge (base: `6081a39`'s file; all four clean, the originals kept as
`lille.cell-6081a39.lisp`). They are re-measured (`FORCE`, the rule changed under them), and round 1's refine cells then
start from the new freeze.

| Cell | At `6081a39` | At `1a7f135` (decision 47) |
|---|---|---|
| b0a0 | 0.9518 | **0.9548** |
| b1a0 | 0.9563 | **0.9586** |
| b2a0 | 0.9941 | **0.9945** |
| b3a0 | 0.9869 | **0.9883** |

### 24.7 Round 1 closed (2026-10-07)

All twelve cells, rescored at `1a7f135` (40 seeds; NORMAL drift 0.44 and pacing identical to the baseline in every one;
every new behaviour a HARD-only level, no new roll; every test diff only adds checks):

| Branch | a0 | a1 | a2 |
|---|---|---|---|
| b0 | 0.9548 | 0.9957 | 0.9991 |
| b1 | 0.9586 | 0.9937 | 0.9984 |
| b2 | 0.9945 | 0.9994 | **0.9996** |
| b3 | 0.9883 | 0.9995 | 0.9992 |

The score is saturated: from a1 on, strength is 1.000 and signature 0.996–0.999, so the 40-seed score no longer tells
the best cells apart. The refines were judged on held-out seeds (wins, damage and Konpaku taken) and style:
- **b2a2** (the best score): a loop-led executioner. The HOSHA loop is 73 % of his damage, traces 16 %, HIRENKYAKU 8 %.
  It won 1200 / 1200 on seeds 1–120, with 254 / 247 damage taken a match on held-out seeds.
- **b3a1 / b3a2**: the most varied mix, the KIN → EN → KIN pendulum. HOSHA loop 39–40 %, trace combos 23–24 %, X-Axis
  lines 34 %, the charged shot 8.6 % in b3a2. b3a2 won 800 / 800 held-out, with 374 damage taken and 0.13 Konpaku lost a match.

Located fixes the cells shared (credited in each proposal):
- no hunt into an attack or a rush;
- the burst read, through what the CPU perceives (b2a2, b3a2);
- composure, and its buffered-J bug (b2a2);
- okizeme answering `:none`;
- the turtle and no Breaker at HARD;
- KIN's SP enders and SANREN cash-in;
- EN never entering KIN empty.

Shared-code recommendations kept for the integration:
- an ORANGE kit key, so composure's held-J trick can go;
- an `ai-press` that leaves no buffered press;
- `:awaken :min-taken` by difficulty;
- the generic Breaker reflexes asking `:ok`;
- AI-ATTACK's reach filter for EN at NORMAL;
- a wake-up field in the snap;
- `tools/assistgate.py` re-run, because the `:sp-ender` hooks act for an assisted human.

`drsi.py close-round` wrote `trace_pool/iter01` (best b2a2 0.9996 at depth 2).

### 24.8 Decision 48: b3a2 ships; the integration next (the user, 2026-10-07)

Asked what next with the score saturated, the user chose 「直接進入整合」 and, for his HARD CPU, 「b3a2 風格最多樣」.
- `duel/lisp/lille.lisp` is now round 1's b3a2 (its CPU code only; the rules are the freeze's), and its LILLE-CPU-TESTS
  section is spliced into `tests/duel-rules-test.lisp`: duel-rules **6388** ALL PASS, control 89, learn 100, cine 18;
  pkgcheck 0 / 0 / 0.
- The final pick at **80 seeds**: **0.9994** (strength 1.000, masher 1.000, signature 0.999), drift 0.465 (the 80-seed
  reference), pacing all K.O. His damage: trace combos 23.4 %, HOSHA bullets 21.6 % + links 18.4 %, TAISHA 17.6 %,
  the charged shot 8.7 %, traces 6.7 %, the Kikon 2 %, plain J / K 0.1 %.
- NORMAL and EASY are the shipped CPU bit for bit (every new rule is a HARD-only level, no new roll), so his six NORMAL
  pairings are identical to §23.29's gate (LY 177.9, LK 169.3, LR 193.5, LI 203.9, LS 195.6, LL 259.4 s; all K.O.).
- The cell's eleven HARD-layer knobs (`*lb-ai-close*` … `*lb-ai-rush-wary*`) were defined after the functions that read
  them (11 ECL style warnings in `./build.sh duel`). They are moved to the head of the AI section; the build is back to
  0 warnings and the 40-seed eval reproduces the rescore exactly (0.9992).
- Next, the integration of §24.1 step 5: the learning CPU's Lille situations, ASSIST AUTO COMBO's signature routes
  (b3a2's `:sp-ender` already acts for an assisted human), then the full gate.


### 24.9 The learning CPU's Lille situations (§24.1 step 5; the integration, 2026-10-07)

The user's plan (§24.1 step 5, from the choice 「學習玩家習慣」): the learning CPU (DUEL_LEARNING) gains **Lille's own
situations**, so a Lille CPU learns the human's habits against his signature and answers them in character. It is built
on a new generic part of the learner, the kit model (DUEL_LEARNING §11: `learn-def-kit`, separate tables, storage format
3). His part is the section "AI: the learning CPU's Lille situations" at the end of `lille.lisp`'s AI part.

**When it runs.** Only a learner runs it: a CPU Lille facing a human (VS CPU, ENDLESS) or the learning gate. CPU VS CPU,
the seed gates, the ASSIST's learner and every other character never get there (`lrn-kit` is NIL), so nothing of theirs
moves (verified below). The rules are the learner's:
- the human's state is what Lille's CPU perceives (the delayed snap); his own state is felt at once;
- a read is one roll of the learner's own stream per event (`learn-kit-read`, never `sim-rnd01`), against p_exploit ×
  `*lb-learn-diff*` (EASY ≤ NORMAL ≤ HARD), and only on a confident prediction (n0 ≥ 1.5, p ≥ 0.4, as the generic model);
- every answer is a command of his kit.

**The three situations** (8 answer classes: `:left :right :back :guard :hoho :step :attack :take`):

| Situation | Onset (as his CPU sees it) | The human's answers | The read's answer |
|---|---|---|---|
| `:trace` | he stands on one of Lille's live traces he could have seen (laid at least the perception delay before), Lille in EN, no other episode open | `:right` / `:left` off the line as Lille laid it (facing along it); `:back` along it (still on it, > 1.2 m); a `:hoho`; a `:guard` raised on it; `:take` (still on it after 45 f + the delay). An attack is no answer: the question is how he leaves the line | a side: **the snap timed for his step**: TENSHIN in once his step off is seen (a Step, or 0.6 m that way) and the live traces, turned toward his landing (*STEP-DISTANCE* 2.5 m that way), would hit him there; before that, if they wouldn't, **a K fan** at him (its side line + the 10° snap reach his landing from ~9 m). `:back`: TENSHIN in at once (the lines run 31 m) |
| `:tenshin` | his own TENSHIN in from EN's neutral (the 16 f wind-up the human can see) | `:guard`, `:hoho`, `:step`, `:attack` (a new move), `:back`, `:take` (20 f + the delay); a guard, Hoho or Step under way at the onset counts | read where his CPU would switch from neutral (one read per 60 f window): `:guard` → **the materialise is held** (no neutral switch) until he is busy; `:hoho` → **held until his Hoho is spent** (seen within its lockout, or no flash step for one). The fast cancels (J1's line + 2 f: too fast to answer) still go |
| `:hosha` | the stance's plan is HOSHA on a free opponent (watched only when HOSHA fires) | as `:tenshin` (18 f + the delay); no reaction beats HOSHA's first bullet, so an answer already under way at the plan counts | read at the plan: `:guard` (him standing) and `:hoho` → **the HIRENKYAKU dash back (iframes), then the charged shot** (through guard); `:step` / `:back` → **the charged shot** (its aim follows him through the charge); `:attack` → **the dash back, then HOSHA** (TAISHA without the dash) |

Hooks in his shipped CPU (one line each): `lb-ai-reflex`'s EN branch asks `lb-learn-en` first; `lb-ai-en`'s two neutral
switches ask `lb-learn-hold-p`; `lb-en-tick`'s cancel asks `lb-learn-cancel-p`; `lb-ai-kamae` passes its plan through
`lb-learn-kamae`. Without a learner each returns the shipped answer, with no side effect and no roll.

**Knobs** (all new, the integration agent's, 2026-10-07):

| Knob | Value | What |
|---|---|---|
| `*lb-learn-diff*` | EASY 0.5, NORMAL 1.0, HARD 1.5 | × p_exploit (0.15–0.6) for his reads: ≤ 0.9 at HARD |
| `*lb-learn-episode*` | `:trace` 45, `:tenshin` 20, `:hosha` 18 | frames a situation waits for his answer, + the perception delay |
| `*lb-learn-hold*` | 60 | frames one `:tenshin` read's window lasts at most |
| `*lb-learn-holds*` | `(:guard :hoho)` | the `:tenshin` reads that hold the switch |
| `*lb-learn-step-off*` | 0.6 m | toward the read side: his step off begun |

**The HOSHA guard answer, measured** (habit 9, P1 HARD Yamamoto, Lille HARD; Lille wins all; damage Lille took a match,
8 runs × 30 unless noted):

| `:guard` → | Lille took (learner) | without his situations (m 4) |
|---|---|---|
| TAISHA within 3 m, else the charged shot (4 runs) | 725 | 525 |
| TAISHA within 3 m, else the quick shot (on him standing) | 658 | 546 |
| **the dash back, then the charged shot (kept)** | 580 | 546 |

A HARD opponent perfect-Hohos or punishes TAISHA's and the quick shot's startup (b3a2's TAISHA read found the same). The
dash back (iframes f0–8) then the charged shot is b3a2's own answer to a punisher, and his signature.

**The learning gate** (P1 Yamamoto with a scripted habit, P2 Lille; 4 fresh runs × 30 matches = 120 per cell; m 0 the
plain CPU, 1 the learner, 4 the learner without Lille's situations; blocks of 10 matches). New habits (debug.lisp
`*habits*`, functions in his section):
- **7** steps off any trace it sees under it to the line's right while his TENSHIN is ready (`lb-habit-trace`);
- **8** Hohos his TENSHIN in's wind-up (`lb-habit-tenshin`);
- **9** guards HOSHA as its leap begins (`lb-habit-hosha`): no reaction beats the first bullet, so the habit plays a
  player who expects HOSHA from the stance.

NORMAL (P2's win rate; Lille's reads acted on, paid = damage dealt and none taken within 60 f):

| Human (P1) habit | plain (m 0) | learner (m 1): matches 1–10 / 11–20 / 21–30 | without his situations (m 4) | his reads (paid) a run |
|---|---|---|---|---|
| plain CPU | .62 | .65 / .68 / .72 (**.68**) | .79 | K fan 3 (3), snap 1.5 (0.5), TENSHIN held 2 |
| steps off traces to the right | .53 | .75 / .72 / .78 (**.75**) | .72 | K fan 5 (5), snap 2 (1) |
| Hohos TENSHIN | .52 | .68 / .78 / .75 (**.73**) | .78 | TENSHIN held 10, K fan 3 (2.5) |
| guards HOSHA | .51 | .75 / .72 / .65 (**.71**) | .66 | dash + charged shot 11 (10) |

HARD (Lille wins all 120 in every cell; damage he took a match / match length):

| Human (P1) habit | plain | learner | without his situations |
|---|---|---|---|
| plain CPU | 525 / 81.4 s | 503 / 80.1 s | 519 / 81.2 s |
| steps off traces to the right | 480 / 80.4 s | 477 / 80.2 s | 503 / 80.0 s |
| Hohos TENSHIN | 500 / 80.4 s | 543 / 81.6 s | 546 / 81.7 s |
| guards HOSHA | 605 / 93.6 s | 646 / 95.1 s | 525 / 92.1 s |

What the model learned (its prediction after the last match of each run):
- NORMAL: habit 7 `trace=right` 0.47–0.69, habit 8 `tenshin=hoho` 0.51–0.60, habit 9 `hosha=guard` 0.78–0.83; the plain
  CPU `trace` left / take (0.33–0.58), `tenshin=take`, `hosha=take`.
- HARD: habit 7 `trace=right` 0.86–0.95. HARD's EN switches through the fast cancels, so neutral TENSHINs are rare
  (`tenshin` evidence 0–6).
- HARD also reads little: the scripted human loses every match, so his form sits near −1 and p_exploit at its floor
  (0.15 × 1.5). His reads acted 1–3 times in 120 matches, except the HOSHA guard answer (103).

Read:
- **Every habit is learned within the first matches**, and the learner beats the plain CPU by 6–22 points at NORMAL.
- **His own situations' share is small and noisy.** At NORMAL a match brings ~1 HOSHA, ~11 traces and a few neutral
  TENSHINs, so his reads act ~5–15 times in a 30-match run. The cells with and without them differ by −0.11 … +0.05, inside the
  learner's own run-to-run spread: the same configuration with the learner's stream perturbed (one extra draw per kit
  read, never acted on) moved the plain cell from .80 to .72 (8 runs each); 28 runs each pooled give .71 with and .77
  without.
- **The reads that act pay:** the HOSHA guard answer 91 % at NORMAL (40 of 44) and 78 % at HARD (80 of 103), the K fan
  96 % (48 of 50), the timed snap 42 % (8 of 19). The TENSHIN holds measured neutral: holding nothing, only `:hoho`, or
  both gave the same win rates to ±0.03 (8 runs, habits 0 / 8 / 9). They are kept: they don't feed his Hoho or guard the trace hits.
- **At HARD the HOSHA guard answer costs damage.** Against the guarder Lille takes 646 a match instead of 525 without it,
  and still wins every match. An 8-run measurement of nearly the same rule gave 580 vs 546. The per-run spread is large
  (469–801 a match).

**Other characters: bit-identical.**
- `simgate.py --seeds 10`, all 21 pairings, is byte-identical to the same run at `8544c23` (rows and `--summary`). That
  includes Lille's six CPU pairings: the learner never runs in CPU vs CPU.
- `simgate.py --cvc`: PASS (yy, yk, kk).
- The learning gate's YK and KR cells (habits plain, grab-happy, Hoho-happy, burst-happy; plain and learner; 4 runs ×
  30) are **row-identical** to `8544c23` (64 of 64 files). At `8544c23`, P2's win rate plain / learner: YK .68 / .88,
  .67 / .66, .53 / .62, .68 / .91; KR .55 / .57, .21 / .33, .54 / .68, .54 / .63. (DUEL_LEARNING §10's table predates the
  later rules.)

Tests:
- learn **131**: the registry, the kit model's own tables, its numbers equal to the generic model's, format 3, a format 2
  table read back, the size caps;
- duel-rules **6405**: his spec, the knobs, the side of a line, the landing, his answers, the stance's branches, the
  hold, `learn` in the name-leak check;
- control 89, cine 18, input 33, touch 64;
- `tools/pkgcheck.sh duel` 0 / 0 / 0; `./build.sh duel` 0 warnings.

The manual and the tutorial have no Lille section yet, so nothing was added there.

### 24.10 ASSIST AUTO COMBO's Lille routes (§24.1 step 5, 2026-10-07)

The user's wish (§24): 「記得要能與玩家輔助 AI 系統結合，以幫助玩家打出更具風格的漂亮連段」; the plan (「完整招牌路線」, §24.1 step 5):
AUTO COMBO plays his full signature routes on the player's J, assisted presses ×0.8 as always.

**The hook (shared code, `assist.lisp`).** `AUTO-ROUTE` asks the function a form's kit `:ai` names `:assist-combo`, on
every step AUTO COMBO is on, free or in a move, before the generic AUTO COMBO. It answers a command (pressed by
`AI-COMMAND` and stamped on the vpad, marked `FIGHTER-ASSIST-NEXT`, the AUTO tag shown, like every assisted press),
`:none` (the route holds the step: no generic AUTO COMBO, SP or read) or NIL (the generic AUTO COMBO as before). Only his
nine kits name it (`LB-ASSIST-COMBO`, set after DEFKIT in his AI part), so every other character's assisted play is the
generic one, bit for bit; a human with AUTO COMBO OFF and every CPU never reach it.

**"You press, the CPU chooses."** The choices are his CPU's (b3a2's functions, on the assist's borrowed HARD brain through
`AI-BRAIN`), pressed as the buttons his ticks read from a human (the stance's J / K / L / Step, HOSHA's and TENSHIN's
latched link, EN's L cancel). Where his own J is the choice (HOSHA out of the stance, a J1 link he latched), it stays his,
unassisted. A route starts on his J and carries on through the moves it (or the assist) pressed until he is free again:
the CPU's route needs no J for its own next step (its K latch, its L link, its TENSHIN's link). His J pressed after a
route latched a link is eaten (a string's latch takes the last press: his mashed J would replace the route's K / L).

| Route | On his J | His CPU's choice (the function reused) |
|---|---|---|
| 1 HOSHA | a bullet hit, J latched in HOSHA (or the route's HOSHA), decided at the link frame (f16) as the CPU | K1 (`LB-AI-LINK`); none into a blown-away opponent (his J emptied), whose wake-up then gets the charged shot / HIRENKYAKU (`LB-AI-OKI-SHOT`, from neutral) |
| | the base K1 out of HOSHA | L latched at once (b1a0's loop, `*LB-AI-HOSHA-LOOP*`) |
| | the shooting stance (the route's or the assist's L, or J pressed in it) | from its f6, its branch (`LB-AI-KAMAE`: HOSHA again on the reeling opponent, TAISHA by the spacing rule, the dash back, the charged shot, the blow-away aim held for his first hittable frame); the stance held (L down) while it waits |
| 2 EN | an EN attack (his J, or J pressed in it) | from its active end, TENSHIN's 2 f cancel where his EN tick would cancel: ≥ 3 traces with him on a line as it would materialise (`LB-AI-SWITCH-IN-P`), the crossfire's line, the web's count (`LB-AI-WEB-CANCEL-P`) |
| | TENSHIN in (the route's) | its link J1 on a trace hit (`LB-AI-LINK`), then K latched on it (b3a1's route, `*LB-AI-ROUTE*`: J1 K2s K3) and K3 at K2s's hit |
| 3 KIN | a J3 / K3 that hit (KIN's, and the base form's) | a red opponent's Kikon (the generic rule); else `LB-AI-SP-ENDER`: KIN K3's crossfire (L → TENSHIN out → EN's J1 laid at him → route 2's cancel → TENSHIN in → J1 …), else SANREN / NIJŪSHI-KŌ; the base K3's L into the stance, the base J3's HIRENKYAKU; no generic SP cancel or ORANGE off his ender (his CPU's) |

**Lille code outside the routes' section** (one line each, identity for his CPU: `AI-BRAIN` is his own brain outside the
assist): `LB-AI-KAMAE`'s plan, `LB-AI-LINK`, `LB-AI-XFIRE-OK-P` / `LB-AI-XFIRE-P` and `LB-AI-BLOW-STEP` read `AI-BRAIN`
(the crossfire was "his own CPU only" while the assist could not carry it on); `LB-AI-SP-ENDER` no longer turns the base
K3's L into SP2 for the assist (its route plays the stance now); `LB-MATERIALISE` deals ×`*ASSIST-MULT*` when the assist
pressed that TENSHIN (`LB-AS-TRACE-MULT`: a hazard's hit has no move for `APPLY-HIT`'s ×0.8, and the traces are that
press's hits); his five ticks (the stance, HIRENKYAKU's direction, EN's walk / cancel / next link, HOSHA's and TENSHIN's
link) decide on `LB-TICK-BRAIN`: his own CPU's brain, NIL for a human **and for the ASSIST gate's button-masher** (habit
`:dumb`). Before, the masher playing Lille took his CPU's tick rules on its own brain (the stance's branch, HOSHA's K1
and the loop), unassisted at ×1.0; it now reads its vpad as a human's, so the gate measures these routes.

**Knobs:** none new. The routes read his CPU's levels on the assist's HARD brain (`*lb-ai-link-k*`, `*lb-ai-hosha-loop*`,
`*lb-ai-oki*`, `*lb-ai-blow*`, `*lb-ai-space*`, `*lb-ai-route*`, `*lb-ai-xfire*`, `*lb-ai-web*`, `*lb-ai-sp-end*` …);
`*assist-mult*` 0.8 now covers the traces an assisted TENSHIN materialises too.

**Tests:** `tests/duel-rules-test.lisp` 6388 → **6394** ALL PASS (every Lille kit names `LB-ASSIST-COMBO`, no other kit
has `:assist-combo`; the move data the routes read; the pure choices `LB-AS-KIND` (which route step a move is),
`LB-AS-STANCE-CMD` (the stance's branch as a press, HOSHA left to his own buffered J) and `LB-AS-LINK-CMD` (HOSHA's /
TENSHIN's link against his latch: the CPU's K1 over his J, his J where J1 is the plan, none empties his J, his K stays
his)); control 89, learn 100, cine 18 ALL PASS; `tools/pkgcheck.sh duel` 0 / 0 / 0; `./build.sh duel` 0 warnings.

**Gates** (the parent `8544c23` vs this change, same machine):
- `simgate.py --seeds 10 --summary` (all 21 pairings, 42 lines): **byte-identical**; `simgate.py --cvc` PASS (no CPU
  plays the assist).
- `tools/assistgate.py --rows` (36 pairings × 20 seeds, the masher P1): every row without Lille as P1 is **identical**,
  and so are Lille's rows with AUTO COMBO off (k 0 1 2 6); the totals:

| assist (k) | vs NORMAL before → after | vs HARD before → after |
|---|---|---|
| none (0) | 57% → 57% | 4% → 4% |
| GUARD HOLD U (1) | 68% → 68% | 8% → 8% |
| GUARD ALWAYS (2) | 96% → 96% | 38% → 38% |
| COMBO (3) | 57% (407) → 56% (400) | 9% → 9% |
| BREAK (6) | 66% → 66% | 4% → 4% |
| HOLD U + COMBO + BREAK (10) | 74% (532) → 74% (533) | 17% (120) → 17% (119) |
| ALWAYS + COMBO + BREAK (11) | 96% (694) → 97% (700) | 54% (390) → 55% (397) |

  Lille as P1 alone (6 opponents × 20 seeds): NORMAL k3 31 → 24, k10 59 → 60, k11 114 → 120 of 120; HARD k3 0 → 0,
  k10 1 → 0, k11 53 → 60 of 120. The masher stands at J1's reach: AUTO COMBO alone (k3) mostly ends his strings in the base
  K3's L → the stance → TAISHA (the spacing rule's 3 m back-slide), after which it walks back in; with the guard on (k11)
  the routes pay.
- **The routes fired** (their pacing-log counts, Lille P1, 120 matches each; the masher never awakens, so routes 2 / 3
  never come up in this gate): HARD k11: HOSHA → K1 924, the loop's L 923, HOSHA's link refused on a blow-away 226, the
  wake-up charged shot 276, the stance's HOSHA 715 / TAISHA 535 / the shot 419 / the dash back 143, the enders' L 808 /
  SP 923 / red Kikon 422; NORMAL k11: 435 / 435 / 95 / 113, the stance 329 / 1309 / 190 / 77, the enders 1151 / 1229 / 590.
  Before, the masher's Lille ran his CPU's tick rules on its own brain (HOSHA 518 a run at HARD k11), unassisted.
- **Each route in the native sim** (a human P1 with AUTO COMBO on, J every 8 f, a CPU-off Kenpachi; the combat log):
  route 1 (79000 at 4 m, L once): the stance → his J's HOSHA → three bullets → `assist F` (K1) → `assist SIG` (L) →
  the stance at f4 → `assist F` (TAISHA, the spacing rule); route 2 (79002, JILLIEL EN 5 m): EN J1 → `assist SIG` (the
  2 f cancel) → the trace hits → his J1 → `assist F` (K2s) → `assist F` (K3) → route 3: `assist SIG` (the crossfire) →
  TENSHIN out → EN J1 → `assist SIG` → TENSHIN in …, three swings until the stun tolerance blew him away (as-en-trace 3,
  as-xfire 3, as-kin-route 4); the same in KIN (79014), the owl's KIN (79016) and the owl's EN (79004).

### 24.11 The full gate after the integration (2026-10-07)

On the merged tree (`2da0477`: decision 49 + §24.10's ASSIST routes + §24.9's learning situations):
- **Seed gate**: `simgate.py --seeds 10`, all 21 pairings: the 15 without Lille are row-identical to `8544c23`; Lille's 6
  are row-identical to `8c93f92` (decision 49 alone). The integration moves no CPU-vs-CPU match (neither part runs
  there); the pacing verdict stays decision 49's (§23.30: LY 176.6, LK 173.2, LR 196.4, LI 206.8, LS 192.4 s at 20 seeds).
- **G2** `--cvc`: PASS (yy, yk, kk).
- **CPU score** `aieval.py --char 5`: strength 1.000, masher 1.000, signature 0.998, drift share 0.455 (ref 0.44 ± 0.05):
  0.9992, as at `8544c23`.
- **Awaken A/B** (39020, Lille P1 never awakens; wins of 60, streams 100 / 300 / 500; pass ≥ 20): LY 16 / 18 / 18,
  LK 3 / 5 / 6, LR 6 / 6 / 9, LI 3 / 8 / 10, LS 10 / 15 / 10. Still failing, as since §20.3 (the user: 「先試玩再決定」,
  open); not tuned.
- **ASSIST** `assistgate.py --rows` vs §24.10's run at `8544c23`: every row without Lille and every row with Lille as P1
  (the masher) is identical; only rows with Lille as the CPU P2 move (decision 49's TENSHIN and his learner's
  situations: the gate's P2 is a learner). Masher P1 wins: k0 408 → 411, k1 487 → 478, k2 688 → 686, k3 400 → 402,
  k6 473 → 477, k10 533 → 541, k11 700 → 692 of 720.
- Host tests duel-rules 6411, learn 131, control 89, cine 18, input 33, touch 64 ALL PASS; `tools/pkgcheck.sh duel`
  0 / 0 / 0.

### 24.12 Decision 51: the HOSHA read at HARD and the awaken A/B kept as they are (the user, 2026-10-07)

The user, on the two open items of §24.9 / §24.11: 「HOSHA read at HARD 跟 Awaken A/B, still failing 兩個問題都維持現狀就行」.
- **The HOSHA-guard read at HARD stays** (`*lb-learn-diff*` :hard 1.5, `lb-learn-kamae-plan` unchanged): against a human
  who guards HOSHA, a HARD learner Lille takes 646 a match instead of 605 (plain CPU) and still wins every match (§24.9).
- **The awaken A/B is an accepted exception** for Lille (open since §20.3, 「先試玩再決定」): LY 16 / 18 / 18, LK 3 / 5 / 6,
  LR 6 / 6 / 9, LI 3 / 8 / 10, LS 10 / 15 / 10 of 60 (pass ≥ 20; §24.11). The gate keeps reporting it; it is not tuned.
- No code changed; AGENTS.md's accepted exceptions list it.
