# SOUL DUEL: Lille Barro (リジェ・バロ, zh-TW 利傑巴羅), 万物貫通 THE X-AXIS and 神の裁き JILLIEL

Status: **design in discussion** (started 2026-10-06). Nothing is built yet. This file collects the user's decisions as
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

### Pending (the user, 2026-10-06): the second form

「等考據結果再決定」: the owl-headed "true form" (Trompete, Sabaki no Kōmyō) waits for the research. The research is in;
the options are §3 Q4.

## 2. Draft kit (proposals; numbers come at the design pass)

**Base form 万物貫通 THE X-AXIS (Diagramm, the left eye shut)**
- J / K: rifle-butt and bayonet strings, the lightest in the roster; reach checked against the rifle art (±0.15 m).
- L **X-AXIS SHOT**: hold to aim (a thin ink line on the floor, the turn rate capped), release to fire a line hit that is
  effectively instant along the line, through guard (decision 2), projectiles and summons. Thin: a sidestep always clears
  it. Long whiff recovery. Implementation: a long `:cap` window with `:ranged` + `:melee-range` and a `:hold` charge,
  a `:line` hazard as the look (the existing beam pattern; nothing longer than 12 m exists today, the arena is 30 m).
- SP1 / SP2: a pressure shot and a Hirenkyaku back-step shot (the distance keeper).
- The **eye** (canon: the left eye opens in a crisis, three openings unlock the Vollständig): a three-pip meter, Q5.
- O / Kikon: a snipe lane (the ENJO-style Kikon lane module).

**Awakened 神の裁き JILLIEL (eight wings, three holes each, the halo)**
- U: the intangible stance (decision 3).
- L **WING VOLLEY**: several thinner piercing shots from the wing holes in a fan, covering the sidestep angles that beat
  the base shot.
- The Kikon: 神の喇叭 TROMPETE or Sabaki no Kōmyō (Q4).

## 3. Open questions (asked 2026-10-06)

1. In the intangible stance, what still lands (Breaker, unguardables, hazards / status)?
2. What it costs (the guard gauge drains per passed hit like West's ward / Reiatsu / nothing)?
3. Which commands keep it (none / Step and Hoho / the wing volley)?
4. The second form: cinematic only / a last-stand phase inside the awakening / a second awakening like Kenpachi's Bankai.
5. The base form's eye meter (three openings of brief phase; the third fills the awakening?) — keep or drop.
6. Trompete's counter (canon: Nanao reflects it): a perfect Hoho or guard reflects part of it back — keep or drop.
