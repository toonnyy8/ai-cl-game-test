# SOUL DUEL: Lille Barro (リジェ・バロ, zh-TW 利傑巴羅), 万物貫通 THE X-AXIS and 神の裁き JILLIEL

Status: **design in discussion** (started 2026-10-06). Nothing is built yet; the roster plumbing for a sixth character is in (DEVLOG §84). This file collects the user's decisions as
they are made; the open questions are at the end. Canon facts: `docs/research/tybw-characters/notes/lille_barro.md`
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
| Kyōraku's Bankai hurts him by rules, not contact; Nanao reflects his own Trompete [V ch. 647–653] | (open, Q4–Q6) | |

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
- The details (what passes through, what still lands, what it costs, which commands keep it) are open: §3 Q1–Q3.

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

- The second exception to "one awakening per match", after Kenpachi's Bankai (DUEL_KEN_BANKAI.md). Entry and cost: §3.

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

## 2. Draft kit (proposals; numbers come at the design pass)

**Base form 万物貫通 THE X-AXIS (Diagramm, the left eye shut)**
- J / K: rifle-butt and bayonet strings, the lightest in the roster; reach checked against the rifle art (±0.15 m).
- L **X-AXIS SHOT**: hold to aim (a thin ink line on the floor, the turn rate capped), release to fire a line hit that is
  effectively instant along the line, through guard (decision 2), projectiles and summons. Thin: a sidestep always clears
  it. Long whiff recovery. Implementation: a long `:cap` window with `:ranged` + `:melee-range` and a `:hold` charge,
  a `:line` hazard as the look (the existing beam pattern; nothing longer than 12 m exists today, the arena is 30 m).
- SP1 / SP2: a pressure shot and a Hirenkyaku back-step shot (the distance keeper).
- The **eye**: three pips of brief phase; the third fills the awakening gauge (decision 7).
- O / Kikon: a snipe lane (the ENJO-style Kikon lane module).

**Awakened 神の裁き JILLIEL (eight wings, three holes each, the halo)**
- U: the intangible stance (decisions 3–5).
- L **WING VOLLEY**: several thinner piercing shots from the wing holes in a fan, covering the sidestep angles that beat
  the base shot.
- The Kikon: a wing-volley lane or 神の裁き.

**Second awakening, the owl form (decision 6)**
- Revives golden, owl-headed after a beheading (decision 8); Sabaki no Kōmyō (golden chopping light waves) and 神の喇叭
  TROMPETE, which a perfect Hoho or guard reflects, breaking his halo (decision 9).

## 3. Open questions

Answered: Q1–Q8 (decisions 4–10). Next: the full design pass (frame data, damage, the CPU, the HUD, the cinematics),
then the user's review before the build.

## 4. Modelling references

The user (2026-10-06): 「請順便整理利傑巴羅各型態的參考圖作為建模依據」. The sheet is
`docs/research/tybw-characters/notes/lille_barro_model_sheet.md` (per form: silhouette, parts, proportions, colours,
poses, what the ink style may simplify; the image pages to save). Image hosts are blocked in the cloud environment, so the
pictures themselves go only into the git-ignored `.refs/Lille-Barro/` (`base/ diagramm/ jilliel/ owl/ trompete/`),
never into git. Two colour questions for the user are in the sheet: Jilliel's green (proposed: a muted jade, since the
style has only three spot hues) and the owl form's gold (proposed: Senjumaru's muted gold #B89A5A).
