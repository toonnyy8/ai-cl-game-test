# SOUL DUEL: Rukia, TYBW look, motion modules and a new Shikai (2026-10-24)

Status: **in design** (the request and the scope are decided, §1–§2; the diagnosis §3; the Shikai's combat logic: 霜の層, approved as
the §4.4 frame table; the build starts with the sim batch and the look batch, §5). Skills: `duel-move-modules` (the Shikai's grammar), `duel-motion-style` (decide,
research, plan, measure, draw), `duel-character-rework` (presentation vs sim, the proofs). Research:
`docs/research/rukia-rework/` (`canon-looks.md`, `canon-motion.md`, `style-refs.md`: canon looks, canon motion, nihon buyō archetypes and draft motion bars) on top of
`docs/research/tybw-characters/notes/rukia_tybw.md`. Earlier design: `DUEL_RUKIA.md` (the kit as built 2026-09-28 and
every decision since; it stays the record of the awakening's rules), `DUEL_STRINGS.md` §2 / §12.

## 1. The request

> 我想要請你依據 repo 中的 skill 重新調查與設計露琪亞的動作模組，並與我討論設計細節
> (the user, 2026-10-24)

The lead's diagnosis (§3) and three directions (A: one 舞 stance grammar for both forms; B: rebuild the awakening only;
C: motion only) went to the user with four questions. The answers:

> 範圍：「重作整體造型模組，並重新設計始解的戰鬥邏輯。覺醒只改動作模組跟對應的攻防距離，核心的戰鬥邏輯不變」
> 動作風格：「原作舉止＋日本舞踊」
> (the user, 2026-10-24; no preference on the awakening's cold sources and on −273 °C, which follow from the scope)

## 2. Scope (decided)

| Part | In scope | Kind of change |
|---|---|---|
| Look (model) | the whole model of every form: the TYBW Shikai battle look, the −273 white look, the 白霞罸 Bankai look | presentation (stills, byte-identical sim) |
| Shikai `:base` | **the combat logic is redesigned** (the move set's grammar, its resource, its routes), then its motion modules | sim change: gated against the parent, her pairings at 20 seeds |
| Awakening `:m18` / `:m50` / `:zero` | **the motion modules and the matching attack / defence distances** (reach follows the drawn motion: 「對應的攻防距離」); **the core rules stay**: the cold gauge (two bars, its gains, warming, spending, the band lock, the overdraft), the bands' walk / run, −273's rooting, ward, freeze-touch, bracing, the CRACK, the field, the Hoho cold | reach only: a sim change limited to hit volumes, gated; every other awakened number byte-identical |
| Motion style | 「原作舉止＋日本舞踊」: canon manner and the canon dances (grade A), the strikes in nihon buyō's body language (扇の手, 回り, 摺り足, 見得; grade D proposals) | — |
| Not in scope | the awakened kits' rules above; the DANGAI cards that read them (永凍, 永久凍土, 霜柱無尽 …; re-checked once the Shikai's rules settle) | — |

Implementation note: the awakened kits `:inherit :base`, so any Shikai command, string or knob the new logic changes must
be pinned in `:m18` (or overridden) so the bands keep their rules (a host test lists the awakened kits' commands and grids
before and after).

## 3. Diagnosis (main e378418, 2026-10-24)

### 3.1 The Shikai's grammar (the `duel-move-modules` checklist)
- The attack state is the universal grid (J1–J3 / K1–K3, the six routes, DUEL_STRINGS §2.1); K hits frost (walk / run
  ×0.7). L is TSUKISHIRO (a ring under him ≤ 8 m, the pillar 24 f later; the K → L copy at S 8). SP1 HAKUREN (held 1–4
  stabs, a wave), SP2 SHIRAFUNE (a 5 m ice thrust), I HAINAWA, O ENBU (a shunpo rush into a spin).
- **No resource of her own and no routes**: each canon dance is one button, the universal bars pay for SP. Nothing gives
  a button a role (gain / refill / damage) and nothing follows a string except K → L and the O ender.
- It works: the gates are inside the window and the dances are canon. What it lacks is a decision inside her strings.

### 3.2 The awakening (kept by the scope; recorded for the motion and reach pass)
- The cold gauge has about 15 special rules stacked over a month (the hysteresis by bars, the band switch only while
  free, the combo band lock, the K → L overdraft, only L spending at −18, three warming rates, the ward that also guards
  shots, freeze-touch, bracing, the CRACK, the THAW lock, the Hoho's +50, the field, the DANGAI 永凍 floor). The skill reads
  this as a redesign signal; the user keeps the rules (§2), so only motion and reach change there.
- The user's playtest-1 point 5 (「越冷越強，而且每個階段要有看得出不同的動作」, DUEL_RUKIA "Playtest 1") is met only in part:
  see §3.3.

### 3.3 Clip inventory (31 clips; S / A / R in frames, loops in seconds)

| Clip | S/A/R | Plays | Note |
|---|---|---|---|
| `:ru-stance` | loop 1.8 s | Shikai idle | a light bounce |
| `:ru-cold-stance` | loop 2.6 s | −18 / −50 idle; 白霞罸's tell | |
| `:ru-zero` | loop 4.0 s | −273 idle | |
| `:ru-q1` | 7/3/12 | J1 in Shikai, −18, −50 (and −273 through the white body's swap to `:ru-q1-z`) | **one clip, three forms** |
| `:ru-q2` | 7/3/13 | J2 in Shikai, −18, −50 | **one clip, three forms** |
| `:ru-spin` | 8/3/18 | J3 in Shikai, −18, −273; **ENBU's strike** | shared with O |
| `:ru-thrust` | 17/4/20 | Shikai K1 (−273 swaps to `:ru-thrust-z`) | |
| `:ru-ring` | 21/4/24 | **K2 in all four forms** | the one clip that never changes |
| `:ru-drop` | 21/5/34 | Shikai K3 | |
| `:ru-tsukishiro` | 10/0/26 | L, its K → L copy | |
| `:ru-stab` | loop | HAKUREN's charge; **−18's SHIMOBASHIRA** | shared |
| `:ru-hakuren` | 6/1/24 | SP1 release (Shikai, −50, −273 at `:clip-s 6`) | |
| `:ru-shirafune` | 16/4/28 | SP2 in all four forms | |
| `:ru-breaker`, `:ru-hainawa` | loop, 8/4/18 | I | |
| `:ru-kikon` | 2.0 s | ENBU's Kikon pose | |
| `:ru-intro`, `:ru-win`, `:ru-awaken`, `:ru-hand` | 2.0 s | intro, win, the awakening, 白霞罸's last shot | |
| `:ru-palm` | 17/4/20 | −18 K1 TŌSHU; **−273 J2 at `:clip-s 17`** | a K clip sped up for a J (the skill's red flag) |
| `:ru-flower` | 21/5/34 | −18 K3 HYŌKA; −273 K3 | |
| `:ru-palm-50`, `:ru-spin-50`, `:ru-flower-50` | 17/4/20, 8/3/18, 21/5/34 | −50 K1, J3, K3 | |
| `:ru-stab-2h` | 0.4 s | −50 L HYŌSHIN | |
| `:ru-reido` | 6/0/26 | −273 L at `:clip-s 6` | |
| `:ru-hakka` | 20/3/30 | O 白霞罸 (all bands) | |
| `:ru-q1-z`, `:ru-thrust-z` | 7/3/12, 17/4/20 | −273 J1, K1 (the white body's clip swap) | |

Strike clips of its own per form (J1–J3, K1–K3; the rest are another form's): Shikai 6 of 6, −18 2 (K1, K3), −50 3
(J3, K1, K3), −273 2 (J1, K1; its J2 is −18's K1 sped up, its K3 is −18's). Every clip dates from 2026-09-28, before the motion-style
skill: no anticipation squats, no follow-through, the hit poses held on a planted stance (the same findings as Ichigo's and
Yamamoto's TYBW diagnoses). The FK reach report and the 8-frame strips come with the motion plan.

## 4. The Shikai's combat logic: proposals (under discussion)

The user decided the scope; the shape is still open. Three whole candidates, each a grammar the `duel-move-modules`
recipe can encode once (a segment table, its knobs in `rukia.lisp`); the user may pick or combine.

| | 1. 舞 stance (Lille's grammar) | 2. 舞の順 the dance order | 3. 霜の層 frost layers on him |
|---|---|---|---|
| Attack state | the universal J / K grid | the universal J / K grid | the universal J / K grid |
| L | enters the stance; inside it L1–3 stab the plaza (gain 雪 +1 each), J1–3 shunpo cuts (reposition, refill Reiatsu), K1–3 ice cuts (damage) | **the next dance in canon order**: 初の舞 月白 (ring) → 次の舞 白漣 (wave) → 参の舞 白刀 (ice blade) → 初 again; each dance that hits makes the next one stronger | TSUKISHIRO as now; its freeze adds 2 layers |
| Resource | 雪 pips 0–6 (hers) | the dance index 初 / 次 / 参 (a position, not a meter) | **霜 layers 0–3 on the opponent** (each slows his walk / run ×0.85 / 0.7 / 0.55 and thaws over time) |
| Routes | J3 → JL1–3 月白 rings ≤ 8 m (1 pip each); K3 → KL1–3 白漣 lanes (1 pip each) | K → L plays the current dance as a combo copy | K hits and the dances add layers; at 3 layers he is brittle |
| SP2 | 参の舞 白刀, spend-all (length and damage by pips), only off a string hit | 舞・終: the three dances in one move | 参の舞 白刀 **shatters** the layers (damage by layers, resets them) |
| Identity | a stance dancer like Lille | a dancer who plans her next figure | a freezer who builds and shatters, the awakening's frost-on-every-hit foreshadowed |
| Risk | the most work; close to Lille's grammar (「避免同質化」) | predictable for the opponent; the CPU must plan the order | a new status rule on the victim (host tests, the CPU's thaw read) |

The lead recommends **3** (her own resource on the victim, the canon "freeze, then shatter" of Tsukishiro and
Shirafune's wound that keeps freezing, the fewest new moves), optionally with 2's dance order for L. The questions the
skill asks before any build (tap or hold per button and its one-hand mapping, what a press does with nothing to pay,
which hits reach far, where each string ends, what she does at 2 m) follow once the shape is chosen, as a segment table
for the user's yes.

### 4.1 Chosen: 3, 霜の層; her role 遠近各半 (the user, 2026-10-24)

> 始解戰鬥邏輯：「3 霜の層」；定位：「遠近各半」
> (the user, 2026-10-24; candidates 1 and 2 rejected, 2's dance order not taken)

「遠近各半」 restated: close (1–3 m) and far (5–8 m) both get a full kit, each with a way to add layers and a way to cash
them; neither is the fallback. The lead's restatement as a segment table (numbers are proposals, knobs in `rukia.lisp`):

| Move | Enter by | Range | 霜 layers (on him) | Cashes | Note |
|---|---|---|---|---|---|
| J1–J3 | J | 1.4–1.6 m (close) | **+0** (keeps his thaw timer from running) | — | her fast close answer, S 7 beats every K1 |
| K1–K3 | K | 2.5–2.8 m (close) | **+1 a hit** (KKK = 3) | — | the close gain |
| K → L 月白 (combo copy) | L after a K link | at him | **+2** | — | the close route to 3 layers |
| L 初の舞・月白 | L | ≤ 8 m (far) | **+2** on the pillar's hit | — | the far gain; tell, guardable, a Step clears it (as now) |
| SP1 次の舞・白漣 | Shift+K, held | 11 m wave (far) | **+1** | — | lanes; a side Step clears it (as now) |
| SP2 参の舞・白刀 | Shift+L; off a string hit or alone | 5 m (mid) | **all → 0** | **shatter**: damage by the layers it breaks | the one sink, from close (after a string) and far (after a ring) |
| O 円舞 | O / the O ender | 8 m rush | +1 (proposal) | — | |
| I 這縄 | I | universal | 0 | — | |

| Layer | His walk / run | Look (on his model) |
|---|---|---|
| 0 | ×1.0 | — |
| 1 | ×0.85 | an ice crust on the feet |
| 2 | ×0.70 | to the knees |
| 3 (cap) | ×0.55, brittle | to the waist, a white breath |

- Step, Hoho, dashes and every frame number stay untouched by the layers (the old frost's rule, DUEL_RUKIA §3.1: the
  universal escapes hold).
- Thaw: one layer a **150 f** without a new layer (proposal; the old frost cap).
- Shatter damage (proposal): **70 + 25 a layer** (0: 70, 1: 95, 2: 120, 3: 145; today's SHIRAFUNE 110), before the combo
  scaling.
- The awakening keeps its own frost (frost on every hit, 30 / 60 / 90 f, the core rules, §2): the layers are a separate
  status that only the Shikai's moves add; whether layers survive her awakening is an open question.

### 4.2 The details (the user, 2026-10-24)

> J：「J 不加層，只停住退冰」
> 震碎：「能透過 J1/2/3+L 與 K1/2/3+L 爆開不同的層數並帶來多樣化的效益，並配合鬼道對中程實施壓制逼對手踏入近身陷阱。」
> 0 層白刀：「保留現在的 110」
> 覺醒時的層數：「留著自然退冰」
> (the user, 2026-10-24)

What changes in §4.1:
- **The bursts replace SP2 as the sink**: L after any J link or K link (J1–J3, K1–K3: six routes) **bursts** layers on
  him; each route bursts its own number of layers and gives its own benefit. The K → L 月白 combo copy (+2) gives way to
  the K bursts. The burst table is the lead's proposal below, for the user's yes.
- **Kidō at mid range** (3–5 m): pressure that makes the middle distance costly, so he either backs out to her far tools
  or steps into her close traps. Which kidō (canon manga: 破道の四 白雷, 破道の三十三 蒼火墜, 縛道の六十一 六杖光牢; 這縄 is the
  Breaker) and on which button: open.
- **SP2 白刀 at 0 layers keeps today's 110** (whether it still bursts layers on top: open).
- **Her awakening leaves his layers on him**, thawing as usual; the awakened moves neither add nor burst them (the
  awakening's rules stay, §2).

### 4.3 The bursts, the kidō, SP2 (the user, 2026-10-24)

> 爆開表：「可以，照這張表」　鬼道：「1+2」　白刀：「爆全部：110 ＋ 每層 25」　0 層接 L：「不接，連段在這裡結束」
> (the user, 2026-10-24)

The burst table (the lead's proposal, approved; numbers are knobs). L after a J or K link with at least one layer on him:
**link n bursts up to n layers** (link 1: 1, link 2: 2, link 3: all three); the J routes give position and resource, the
K routes damage and distance. Every burst ends the string (an `:end` row: no link after it); with 0 layers the L is not
taken and the string ends at that link (no 0-resource loop).

| Route | Name [G] | Bursts | Benefit |
|---|---|---|---|
| J1 + L | 霜散 SHIMO-CHIRI | 1 | an ice spray off the blade, a small hit; she hops back 2.5 m, out to the kidō's middle distance |
| J2 + L | 雪煙 SETSUEN | ≤ 2 | a mist burst; refunds Reiatsu (the SP gauge) for each layer burst |
| J3 + L | 霜陣 SŌJIN (the close trap) | all | the shards lie as a frost circle round her, r 3 m, 4 s: while he stands in it he gains a layer every 60 f |
| K1 + L | 氷礫 HYŌREKI | 1 | the shard hits again: extra damage, the stagger lengthened |
| K2 + L | 氷柱 TSURARA | ≤ 2 | an ice pillar out of the plaza under him pushes him to 6 m, into her far tools |
| K3 + L | 雪崩 NADARE-KUDAKI | all | the big shatter: damage by the layers, a knockdown |

The kidō, 「1+2」 (both of the lead's options, joined; the reading below is confirmed with the user):
- **L tap = 破道の四 白雷 BYAKURAI** (a fast straight beam, 3–6 m, no bar; repeats limited by its recovery); **L held =
  初の舞・月白** (the ring ≤ 8 m, as now, a pillar's hit +2 layers).
- **SP1 = kidō**: 破道の三十三 蒼火墜 SŌKATSUI (1 bar; the tap / hold split of option 2 has 白雷 already on L, so SP1 is 蒼火墜).
- **次の舞・白漣 moves into K3 + L** (the avalanche of cold off the shatter, canon ch. 235's release), so 雪崩 is drawn
  as 白漣's wave.

SP2 参の舞・白刀: bursts every layer, **110 + 25 a layer** (0: 110, 3: 185), usable alone (off a ring's freeze at 5 m)
and off any string hit; the one spend-all.

The user confirmed the burst table as shown in full (「可以，照這張表」) and amended the kidō reading: 「SP1 也分輕按／長按」
(the user, 2026-10-24): **SP1 tap = 破道の三十三 蒼火墜, SP1 held = 縛道の六十一 六杖光牢 RIKUJŌKŌRŌ** (six rods of light
pin him). 白漣 stays inside K3 + L.

### 4.4 The whole Shikai, frames and numbers (approved: the user, 2026-10-24: 「可以」)

Frames S / A / R at 60 Hz; every number a knob in `rukia.lisp` (docstring: old → new, date, who). The one-hand deck plays
the same buttons, so a tap and a hold on the L / SP1 chips are the keys' tap and hold.

| Input | Move | S / A / R | Dmg | Range | 霜 | Note |
|---|---|---|---|---|---|---|
| J1–J3 | the universal J (as now) | 7/3/12, 7/3/13, 8/3/18 | 34 / 34 / 42 | 1.44 / 1.32 / 1.56 m | +0, his thaw paused | frost timers removed from the Shikai |
| K1–K3 | the universal K (as now) | 17/4/20, 21→14/4/24, 21→14/5/34 | 66 / 58 / 84 | 2.8 / 2.5 / 2.7 m | **+1 a hit** | |
| J1 / J2 / J3 + L | 霜散 / 雪煙 / 霜陣 | S_eff 10 (A 3 + 10 < flinch 18), A 3, R 22 | 20 + 20 a layer burst | 2.0 m round her | bursts 1 / ≤ 2 / all | 霜散 hops back 2.5 m; 雪煙 refunds 8 % of a bar a layer; 霜陣 the r 3 m circle, 4 s, +1 a 60 f inside |
| K1 / K2 / K3 + L | 氷礫 / 氷柱 / 雪崩 | S_eff 12 (A 4 + 12 < stagger 26), A 4, R 26 | 30 + 30 / 30 + 25 / **40 + 35** a layer | 2.8 m; 雪崩's wave 6 m | bursts 1 / ≤ 2 / all | 氷礫 stagger +8 f; 氷柱 push to 6 m; 雪崩 knockdown (3 layers: 145) |
| L tap | 破道の四 白雷 | 12 / 3 / 28 | 45 | a line 0.5 → 6 m, 0.3 m wide | +0 | `:ranged`, flinch, guard 10, block −12; no bar |
| L held (≥ 12 f) | 初の舞・月白 | from the hold: ring at S, pillar 24 f later (as now) | 60 | ≤ 8 m, r 1.8 | **+2** on the pillar's hit | freeze 36 f as now; guardable, a Step clears it |
| Shift+K tap | SP1 破道の三十三 蒼火墜 | 14 / 4 / 26 | 90 | a 5 m cone, 40° | +0 | knockback 3 m; 1 bar |
| Shift+K held (≥ 16 f) | SP1 縛道の六十一 六杖光牢 | the rods at f16 after the hold, a 14 f tell | 20 | ≤ 6 m at him | +0 | `:bind` 45 f (an opener: he may Burst); guardable from her side; 1 bar |
| Shift+L | SP2 参の舞・白刀 | 16 / 4 / 28 (as now) | **110 + 25 a layer** | a line to 5 m | **bursts all** | alone or off any string hit; the one spend-all |
| O | 円舞 ENBU (as now) | as now | 70 | 8 m rush | +1 | |
| I | 縛道の四 這縄 (the Breaker, as now) | universal | 150 | | +0 | |

| 霜 layer | 0 | 1 | 2 | 3 (cap) |
|---|---|---|---|---|
| His walk / run | ×1.0 | ×0.85 | ×0.70 | ×0.55 |
| Thaw | — | one layer a 150 f without a new one (J hits hold the timer) | | |

Removed from today's Shikai: the K hits' frost timers (60 / 90 f), the K → L 月白 combo copy, SP1 次の舞・白漣 as a button
(its wave lives on in 雪崩). The awakened kits keep their own commands, grids and frost (§2), pinned by a host test.

## 5. Next steps
1. The research notes (`docs/research/rukia-rework/`), then the look plan (a model-sheet review against canon, stills).
2. The Shikai's grammar chosen → its segment table → the user's 「可以」 → the sim batch, host tests, gates vs the parent.
3. The motion plan per form (inventory → archetype per string → slot table) → 「可以」 → the clips, FK reach, the awakened
   bands' volumes moved to the drawn reach (gated), before/after sheets from both cameras, landscape and portrait.

### 5.1 Baseline (main eee02f4, before the new Shikai; 20 seeds, match time without cinematics)

| Pairing | RY | RK | RR | IR | SR | BR | HR |
|---|---|---|---|---|---|---|---|
| Median (s) | 92.0 | 94.5 | 116.5 | 117.2 | 120.8 | 135.3 | 138.8 |
| Wins (P1 / P2) | 13 / 7 | 9 / 11 | 8 / 12 | 9 / 11 | 10 / 10 | 6 / 14 | 3 / 17 |

All 140 K.O. Five of the seven already sit under the 125 s floor on main: the global whiff / block recovery and Kikon
changes of 2026-10-23 (DEVLOG §319–§335) moved many pairings below it before this rework (YY 85.5, YK 87.1 there). The new
Shikai is judged against this parent, not the window alone.

## 6. As built: the new Shikai's rules (batch ru-sim, 3d2b045, merged cd97427; 2026-10-24)

- **霜 layers**: a per-fighter status separate from the frost timer (0–3 + a thaw timer). K hits +1, J hits reset his
  thaw, TSUKISHIRO's pillar +2, ENBU +1, the 霜陣 circle +1 a 60 f inside; one layer thaws a 150 f; walk / run ×0.85 /
  0.70 / 0.55; nothing else slows.
- **Bursts**: the generic `:l-after-j` / `:l-after-k` also take a per-link plist (every other kit's data unchanged). A
  burst needs ≥ 1 layer and a hit (refused on a block), ends the string, and combos off its link including hitstop
  (host-tested).
- **Tap / hold**: L tap BYAKURAI, L held ≥ 12 f TSUKISHIRO (`*ru-l-hold*`); SP1 tap SŌKATSUI, held 16 f RIKUJŌKŌRŌ;
  SP2 110 + 25 a layer.
- **Removed**: the K → L TSUKISHIRO copy, the Shikai's HAKUREN button, every Shikai frost timer.
- **Awakened kits pinned**: their commands and `:l-after-j nil` are set in `:m18`; a host test checks their kit data
  equals adcb94b's. The Shikai's K2 is renamed `:ru-sk2` / `:ru-sk2s` so the bands keep `:ru-k2` with its frost 60.
- **CPU**: `string-reflex` takes a kit function for `:l-after-*` (shared with AUTO COMBO) and a new `:sp1-hold` hook;
  every new move fires in 40 CPU matches, though rarely 霜散 (0), the held TSUKISHIRO (3) and RIKUJŌKŌRŌ (1).
- **DANGAI**: card 119 白船不沈 now covers the Shikai's SP2 too.
- **Knobs**: `*ru-burst-j-s*` `*ru-burst-k-s*` `*ru-hop*` `*ru-refund*` `*ru-sojin*` `*ru-tsurara-to*`
  `*ru-hyoreki-stun*` `*ru-l-hold*`; the CPU's `*ai-ru-burst-1/2/3*` `*ai-ru-zone-kido*` `*ai-ru-sp2-layers*`
  `*ai-ru-l-far*` `*ai-ru-sp1-far*`. Debug 85000+k the scenes, 85499 the looks' consing check (0 B a frame); a
  `duel rukia` pacing line follows her gate rows. 10 kanji baked into `glyphs-extra.lisp`.
- **Placeholder clips** (the motion pass replaces them): 霜散 `:ru-q1-z`, 雪煙 `:ru-spin-50`, 霜陣 `:ru-reido`, 氷礫
  `:ru-thrust-z`, 氷柱 `:ru-flower-50`, 雪崩 `:ru-hakka`, BYAKURAI `:ru-palm-50`, SŌKATSUI `:ru-palm` (its hold
  `:ru-cold-stance`), RIKUJŌKŌRŌ `:ru-flower`. The FK report: every melee burst's drawn tip falls short of its volume
  (霜散 −82 cm, 雪煙 −46, 霜陣 −131, 氷礫 −179, 氷柱 −185); none overshoots.
- **Deviations from §4.4** (the lead's calls, reported to the user): frost also left the Shikai's SP2, TSUKISHIRO and
  ENBU (§4.4 named only the K hits); a 霜陣 laid before her awakening keeps adding layers after it; RIKUJŌKŌRŌ marks
  his spot at its f2 and binds at f16; SŌKATSUI's startup counts from the release, so a tap hits 1–6 f later than S 14.

### 6.1 Checks and gates (the merged main)

Host tests 10220 ALL PASS (control 89, learn 131), pkgcheck clean, the debug ranges check passes, `./build.sh duel` 0
warnings, a browser smoke exit 0 (the batch ran `duel-rukia.json` to the end: every burst fires). Non-Rukia pairings
(YY YK KK IY IK II SS SI, 10 seeds) identical to adcb94b; G2 `--cvc` identical to the reference. Her pairings, 20 seeds,
all K.O. (median s and Rukia's wins of 20, parent → now): RY 92.0 → 97.3 (13 → 11), RK 94.5 → 89.7 (9 → 6), RR 116.5 →
114.5, IR 117.2 → 108.0 (11 → 13), SR 120.8 → 123.4 (10 → 14), BR 135.3 → 131.3 (14 → 13), HR 138.8 → 139.9 (17 →
14). The playtest Artifact is v150.

Awaken A/B (the merged main; Rukia never awakens, the other side on its rule; her wins of 60 at seed0 100 / 300 / 500;
`--cmd 39020` with her as P1, `39002` as P2): RY 38 / 42 / 43, RK 21 / 21 / 32, RR 29 / 30 / 32, IR 28 / 30 / 28, SR
33 / 43 / 36, BR 41 / 40 / 41, HR 44 / 47 / 45: every row ≥ 20, pass (RK the closest). All 1260 matches K.O.; `--cvc`
PASS (yy / yk / kk identical).

## 7. As built: the look (batch ru-look, 9337f55, merged 57c31f7; 2026-10-24; presentation only)

By the gap numbers of `docs/research/rukia-rework/canon-looks.md` §5:

| Gap | As built |
|---|---|
| #1 the ribbon | a 1.8 m chain from the pommel, lying behind her and out to her right, looping in turns; stiffer and shorter in the colder bands (canon ~6 m: cut so it stays out of the behind camera) |
| #2–#4 the sleeves | the left a short puffed cap with the 十三 plaque (muted tan #B4A486, S < 0.3); white fingerless tekkō on both arms; the right sleeve a hanging panel swinging behind the arm |
| #5 the hakama | an 8-panel bell that trails her and flares in turns (Yamamoto's hem spring, rotated, never scaled); wide hakama legs |
| #6 the scabbard | black, at her left hip |
| #7 the guard | a round ring with six spokes |
| #8 the sash | white |
| #10 the irises | a lighter lavender #7A7096 |
| #12 / #17 the ornament | −273 and the Bankai share one ice spray on her left side wrapping behind the head (replaces the symmetric half-crown) |
| #13–#16, #18 the Bankai | four stacked ice collar rings, tiered shoulder plates, an ankle-length white kimono bell, knee-length hanging sleeves, a bow of four loops and three ribbons on her back, a chest snowflake with a tassel |
| skipped | #9, #11 (already canon); #19 the Bankai's guard (a bar or a ring: the user's call); #20 the Ep411 stole (optional) |

The −50 frost rims and the white looks' ice keyline cover the new cloth too. Shared files: `body.lisp` (`defweapon`
takes `:ink-color`, so a cloth part can carry the black-cloth or the ice keyline), `tests/duel-rules/art.lisp` (a body
variant takes its base body's rig: `:rukia` is now built on `:rukia-core`). Her look's draw hook is registered on every form
at the end of `rukia-meter.lisp`. Debug 85500+10l+s the model sheets (l: 0 the Shikai, 1 −18, 2 −50, 3 −273, 4 the
Bankai costume; s: 0 front, 1 left side, 2 back, 3 three-quarters, 4 face, 5 the blade out, 6 the J3 turn from behind, 7
the match from behind, 8 the same walking in), 85900 the consing line.

Checks: on its base, `simgate --seeds 10 --summary` and `--cvc` byte-identical; after the merge with the new Shikai the
host tests 10220 ALL PASS, pkgcheck clean, the ranges check passes, the build 0 warnings, the merged stills checked, the
consing lines 0 B in all five looks (standing / J1 hit) and for every new Shikai look (layers, 霜陣, the beam, the fire,
the rods). After the merge, `simgate --seeds 10 --summary` over all 28 pairings is byte-identical to main 8f452e0 (the new Shikai
without the look). Before / after sheets (landscape and portrait) went to the user; the playtest Artifact is v151.

### 7.1 The left sleeve is the long sleeve pulled up (the user, 2026-10-24)

> 「不對稱的袖子也是跟右邊一樣的寬鬆長袖往上拉後再用臂章固定，所以應該會在上手臂有寬鬆的袖口」
> (the user, 2026-10-24)

The ru-look batch drew the left sleeve as a short puffed cap with a tie (gap #2 read as a cut sleeve). Rebuilt in
`:rukia-core`'s `:upper-arm-l`: the gathered fabric above (a bevel 0.15 × 0.12 × 0.16), the white armband holding it
(0.13 × 0.04 × 0.14, the tan plaque with 十三 on its outside), the sleeve's **loose mouth flaring below the band** round the
upper arm (a black frustum r 0.07 → 0.145, 0.115 tall), the white under-sleeve beneath, and −50's frosted hem on the mouth.
Presentation only: host tests 10220 ALL PASS; her seven pairings at 10 seeds byte-identical to the build before.

## 8. RIKUJŌKŌRŌ through a guard; K3 + L becomes 白漣 (the user, 2026-10-24)

> 「六丈光牢就算對手在防禦也能強制讓對手陷入 45f 的硬直差。但要可以用 step 跟 hoho 躲避」
> 「K3+L 的雪崩直接改成白漣」
> (the user, 2026-10-24)

- **RIKUJŌKŌRŌ**: its bind's hitwin is `:unguardable` (rules RESOLVE-CONTACT: a guard is read as neutral), so a guarding
  victim is bound 45 f all the same. It stays a disc marked at its f2 (r 1.2 m) that shuts at f16: a Step (2.5 m) or a
  Hoho out of the ring escapes it (a walk can't: 14 f at 3.8 m/s is 0.9 m, the ring plus his body 1.56 m). The CPU's
  anti-bind (ai.lisp: step sideways or Hoho inside a `:bind` move's `:tell`) already reads it. Debug 85026 (into a held
  guard: bound, 20 damage) and 85027 (into his CPU: in four tries it Stepped out once, ran in and hit her once, was
  bound twice).
- **K3 + L is 次の舞・白漣** (`:ru-hakuren-k`, was `:ru-nadare` 雪崩): the four stabs at once at its f0 (zero's
  HAKUREN-SPIKES), the full four-stab wave (half-width 1.8) running 11 m at its f12, the callout and brush 白漣; the burst
  is unchanged (all layers, 40 + 35 a layer, a knockdown, S_eff 12), its line hit lengthened 6 → 11 m to match the drawn
  wave (taken only off a K3 hit, so the reach matters little). The clip is HAKUREN's release (`:ru-hakuren` at `:clip-s`
  12; a placeholder until the motion pass).
- Host tests 10220 ALL PASS (the K route's checks renamed, its reach 11 m); her gate rows follow below.

Gates after §8 (her pairings, 20 seeds, all K.O.; median s, Rukia's wins of 20; §6.1's numbers before): RY 96.5 (11;
97.3, 11), RK 89.7 (6; 89.7, 6), RR 114.5 (114.5), IR 108.0 (13; 108.0, 13), SR 123.4 (14; 123.4, 14), BR 131.3 (13;
131.3, 13), HR 141.1 (14; 139.9, 14). Only RY and HR moved: her CPU seldom holds SP1 (RIKUJŌKŌRŌ), and K3 + L's damage is
unchanged. `--cvc` PASS.

## 9. Every burst leaves him out of its route's opener (the user, 2026-10-24)

> 「然後（始解的）J/K+L 收尾記得都要至少退出到 J1 或 K1 的攻擊範圍之外，萊醬你先跟我說打算怎麼修改」
> → the plan (below) and the reading: 「依路線：J 推出 J1、K 推出 K1」 (the user, 2026-10-24; the other reading, every
> burst out of K1, rejected: it would push 霜陣's victim out of its own 3 m circle)

The measure is the J3 / K3 enders' (DUEL_STRINGS §16, fighter.lisp ENDER-PUSH): the opener's reach + its lunge + his
body + `*ender-push*` (0.05 m): J1 1.44 + 0.6 + 0.45 + 0.05 = 2.54 m, K1 2.8 + 0.45 + 0.05 = 3.30 m against Kenpachi.
`RUKIA-BURST-OUT` (each burst's `:opener` :q / :f) gives the floor; `RUKIA-BURST!` pushes him to it over
`*ender-push-frames*` (8 f; she moves only when the arena's edge holds him, PUSH-APART), except where the burst's own
effect already leaves him farther (霜散's hop, 氷柱's 6 m, 白漣's knockdown: no second slide over theirs).

| Burst (3 layers, vs Kenpachi; debug 85010–85015) | End distance before | After | Out of |
|---|---|---|---|
| J1 + L 霜散 | 3.29 m (her hop) | 3.29 | J1 (2.54) |
| J2 + L 雪煙 | 1.20 | **2.54** | J1 |
| J3 + L 霜陣 | 1.60 | **2.54** (still inside the r 3 m circle) | J1 |
| K1 + L 氷礫 | 0.79 | **3.30** | K1 (3.30) |
| K2 + L 氷柱 | 6.00 | 6.00 | K1 |
| K3 + L 白漣 | 4.30 (knockdown) | 4.30 | K1 |

Damage unchanged. Host tests 10221 ALL PASS (a new check: the routes' `:opener`, the floors, the hop and 氷柱 clear them for
the widest body, 霜陣's circle wider than J1's floor); pkgcheck clean; the build 0 warnings; the playtest Artifact v154.

## 10. RIKUJŌKŌRŌ held longer; 冰凍值; 霜陣 round him (the user, 2026-10-24)

> 「1. 長按可延長六丈光牢的鎖定時間，最長可封鎖至毀魂技追擊打中。
> 2. 改成每次 K 能累積 1 點冰凍值，兩點冰凍值提升一層。
> 3. 霜陣每 30f 加一點冰凍值，並改成以對手為中心展開。」
> (the user, 2026-10-24)

1. **RIKUJŌKŌRŌ held**: after SOKATSUI's 16 f hold it has its own hold, `:hold (0 56)`; a held frame adds a bind frame to
   its 45, up to `*ru-rikujo-max*` **100**, measured (debug 85028, the victim at 5.9 m): the bind at its f16, her recovery 26
   f, ENBU pressed at once hits 25 f later, its Kikon follow-up 49 f after that: 26 + 25 + 49 = 100. While a bind seals him
   (`FIGHTER-SEAL`, the bind's frames, a new shared slot, 0 for everyone else) a Kikon follow-up treats him as red
   (combat.lisp: the pending hit's `:red`), so no guard cancels its reel or blocks it: O pressed in time makes the Kikon
   certain ("KIKON FOLLOW-UP on P2 (red)" in the log). The CPU still holds SP1 only to 16 f.
2. **冰凍值**: K1–K3 add a point (`:chill 1`), `*ru-chill-per*` 2 points a layer (rules CHILL-ADD, a new shared slot
   `chill`, 0 for everyone else); KKK leaves 1 layer + 1 point. TSUKISHIRO's pillar (+2 layers) and ENBU (+1) unchanged. A
   lone point with no layer thaws after 150 f like a layer (LAYERS-THAW); a burst spends layers only.
3. **霜陣**: centred on him where the burst's push leaves him (2.54 m off her vs Kenpachi), r 3 m, 4 s; a point a 30 f
   he stands in it (was a layer a 60 f round her).

Host tests 10222 ALL PASS (the chill rules, the sources, the hold's cap); pkgcheck clean; the build 0 warnings.

Gates after §9 and §10 (with the SP2 crash fixed, ea81e90; her pairings 20 seeds, all K.O.; median s, Rukia's wins of 20):
RY 92.3 (10), RK 89.9 (11), RR 105.6, IR 99.9 (14), SR 115.9 (9), BR 143.2 (14), HR 144.0 (11, one draw). The 18 pairings
without her, 10 seeds, identical to 8f452e0 line for line (the two new shared slots stay 0 for them); `--cvc` PASS. The §9
gate run (a1de708) had died on RY's seed 2: SP2 SHIRAFUNE carries `:burst` without an `:opener`, and §9's floor push asked
for a NIL move; SP2 now keeps its own knockback (a host check pins it). Playtest v154 had that crash; v155 fixed it.

## 11. Her numbers back into the roster's range (the user, 2026-10-24)

> 「修改的期間能先列出露琪亞的數值表與其他角色的平均值比較嗎？」 → the table (the six others' mean, min–max, her % off)
> 「等跑完後幫我將露琪亞的數值調回正常區間，另外覺醒的三階段倍率調動成 1.1/1.25/1.65」
> (the user, 2026-10-24)

The table (base forms; resolved from the loaded kits): her frames, reaches and movement sit at the mean (J1 7 f vs 7.3,
K1 17 vs 17.3, walk / run 3.8 / 9.0 vs 3.77 / 9.0); her raw strings are 11–13 % over it (JJJ 110 vs 97, KKK 208 vs 188).
What set her apart was the form's multipliers: dealt ×1.5 (the six 1.0–1.6, mean 1.17) and taken ×0.8 (mean 0.96), so
JJJ / KKK after them were +49 % / +46 %, the roster's highest. Other rows off the mean stay as designed: the stun tolerance
13 (light, blown away sooner; tied lowest), the smallest body (0.34 / 1.5 m), the kidō's damage (just decided).

| Knob | Before | After |
|---|---|---|
| `*rukia-mult*` (Shikai dealt) | 1.5 | **1.0** (JJJ 110 vs the six's after-multiplier mean 111) |
| `*rukia-taken*` (Shikai taken) | 0.8 | **1.0** (most of the six) |
| `*rukia-awake-mult*` / `*rukia-m50-mult*` / `*rukia-zero-mult*` | 1.15 / 1.5 / 1.65 | **1.1 / 1.25 / 1.65** (the user's numbers) |
| the bands' taken (0.95 / 0.85 / 0.8) | — | unchanged (the user named only the dealt) |

The awakened kits' pinned snapshot (§2) moves with the two band multipliers. Host tests 10222 ALL PASS; the build 0
warnings; playtest v156. Gates and the awaken A/B: below when they finish.

### 11.1 Gates after §11 (main 2a8511f)

Her pairings, 20 seeds, all K.O. (median s, Rukia's wins of 20; §10's in brackets): RY 96.9 (10; 92.3, 10), RK 101.8 (4;
89.9, 11), RR 114.0 (105.6), IR 128.1 (10; 99.9, 14), SR 113.0 (10; 115.9, 9), BR 133.7 (5; 143.2, 14), HR 137.5 (6;
144.0, 11). `--cvc` PASS. RY / RK / SR stay under 125 s (as they were before the rework, §5.1): 60-seed reruns started.

**The awaken A/B fails on every row** (Rukia never awakens, her wins of 60 at seed0 100 / 300 / 500; pass ≥ 20): RY 15 /
17 / 18, RK 5 / 6 / 5, RR 6 / 10 / 9, IR 4 / 9 / 6, SR 9 / 8 / 10, BR 9 / 9 / 7, HR 9 / 11 / 4 (before §11 they passed
21–47). With the Shikai at ×1.0 / ×1.0 her awakening (×1.1–1.65 dealt, ×0.8–0.95 taken) decides the match. Reported to
the user; no other knob retuned (the gate policy).

## 12. RIKUJŌKŌRŌ's rods last until his stun ends (the user, 2026-10-24)

> 「六丈光牢的特效要維持到硬直解除」 (the user, 2026-10-24)

The rods look (`rukia-rods-look`) lives the bind's frames + 12 (was a fixed 50 f, gone before a held bind's 100) and
stays full while he is in the bind's stun; from the frame he is free (the stun over, a Burst, his death) it fades over 12
f. Its data (the victim, the bind's frames, the age he was seen free) is the look's own note; the sim reads none of it.
Presentation only: host tests 10222 ALL PASS, the build 0 warnings, consing 0 B (85499); stills of 85028 (a 100 f bind):
the rods on him at 0.4 / 0.9 / 1.4 / 1.75 / 1.95 s.

### 11.2 The A/B left to the CPU rebuild (the user, 2026-10-24)

> 「目前應該是 AI 的機制對不上，等後續重建 AI 就沒問題了」 (the user, 2026-10-24)

The failing awaken A/B rows (§11.1) stand as they are, read as her CPU not yet playing the new Shikai (霜の層, the bursts,
the held kidō: it holds SP1 only to 16 f, seldom bursts off J1) rather than a balance verdict; no knob moves. Her CPU is
to be rebuilt later (skill `duel-character-cpu`), and the A/B is re-run then.

60-seed reruns of §11.1's three short pairings (all K.O.): RY 95.8 s (Rukia 30 of 60), RK 101.0 s (14), SR 113.0 s
(29). Still under 125 s, as on main before the rework (§5.1: RY 92.0, RK 94.5, SR 120.8) and as many pairings without
her since the global recovery and Kikon changes of 2026-10-23; reported, no knob moved.

### 12.1 The rods stick to him (the user, 2026-10-24)

> 「六丈光牢的特效要黏在對手身上」 (the user, 2026-10-24)

While the bind waits, the six marks stay at the cast point (the ring he must Step out of); from the frame it shuts, a
bind that hit (his seal set: RUKIA-HIT) draws the rods at his feet wherever he is, through ENBU's knockback and the Kikon
follow-up's dash, until his stun ends (§12's 12 f fade). A bind that missed shuts on its empty ring and fades. Presentation
only: host tests 10222 ALL PASS, the build 0 warnings, consing 0 B; stills of 85028 with O pressed as she recovers: the
rods on him at the bind, through ENBU's hit and into the Kikon (bind f17, ENBU's hit f77, the Kikon f126).

## 13. The motion plan (approved: the user, 2026-10-24, §13.7)

> 「可以開始準備動作設計了」 (the user, 2026-10-24)

Skill `duel-motion-style`: the style is settled (「原作舉止＋日本舞踊」, §2; archetypes and sources:
`docs/research/rukia-rework/style-refs.md` §2), so this is the plan step: the clips today, their drawn reach, the slot
tables per form, then the user's yes before any clip is drawn. The Shikai's table replaces style-refs §3.1 (which predates
the new Shikai); the bands' tables are style-refs §3.2–§3.4 with the reach column added here.

### 13.1 Drawn reach today (host FK over the art, main 273fa0a)

The blade's tip (the palm for `:ru-palm`, two fingers for `:ru-hainawa`) at the hit frames against the volume's far edge
(an arc's r, a capsule's b + r):

| Form | Strike (clip) | edge | drawn | gap |
|---|---|---|---|---|
| Shikai | J1 / J2 / J3 (`:ru-q1` / `:ru-q2` / `:ru-spin`) | 1.44 / 1.40 / 1.56 | 1.39 / 1.30 / 1.51 | −5 / −10 / −5 cm |
| | K1 / K2 / K3 (`:ru-thrust` / `:ru-ring` / `:ru-drop`) | 3.10 / 2.50 / 3.05 | 1.66 / 0.86 / 1.60 | −144 / −164 / −145 |
| | 霜散 / 雪煙 / 霜陣 (placeholders `:ru-q1-z` / `:ru-spin-50` / `:ru-reido`) | 2.00 round her | 1.18 / 1.54 / 0.69 | −82 / −46 / −131 |
| | 氷礫 / 氷柱 (`:ru-thrust-z` / `:ru-flower-50`) | 3.10 / 2.80 | 1.31 / 0.95 | −179 / −185 |
| | I (`:ru-hainawa`) | 1.35 | 0.82 | −53 |
| −18 | J1–J3 (the Shikai's clips) | 1.44 / 1.40 / 1.56 | as the Shikai | −5 / −10 / −5 |
| | K1 TŌSHU / K2 / K3 HYŌKA (`:ru-palm` / `:ru-ring` / `:ru-flower`) | 2.35 / 2.50 / 2.40 | 0.90 / 0.86 / 0.67 | −145 / −164 / −173 |
| −50 | J1 / J2 / J3 (`:ru-q1` / `:ru-q2` / `:ru-spin-50`) | 1.58 / 1.45 / 1.72 | 1.46 / 1.38 / 1.62 | −12 / −7 / −10 |
| | K1 / K2 / K3 (`:ru-palm-50` / `:ru-ring` / `:ru-flower-50`) | 2.55 / 2.75 / 2.64 | 1.43 / 0.91 / 1.02 | −112 / −184 / −162 |
| −273 | J1 / J2 / J3 (`:ru-q1` / `:ru-palm` / `:ru-spin`) | 1.94 / 1.78 / 2.11 | 1.46 / 0.91 / 1.59 | −48 / −87 / −51 |
| | K1 / K2 / K3 (`:ru-thrust` / `:ru-ring` / `:ru-flower`) | 4.08 / 3.38 / 3.24 | 1.74 / 0.91 / 0.74 | −234 / −247 / −250 |

The J's are drawn where they hit (the J cut, ±0.15 m), except at −273 (its ×1.35 reach on clips drawn for ×1.0). **Every
K falls 1.1–2.5 m short**: she is the smallest fighter (1.44 m), the blade 0.84 m, and a one-hand lunge reaches about
1.7 m; the universal K reach (2.5–2.8 m, K beyond J, DUEL_STRINGS §13) is out of her body's range, today carried by
nothing drawn. The rules test allows a K to fall short (ice, fire and cloth carry it, never over by > 0.15 m); the skill
counts it a red flag (Kenpachi's K1 / K2 drawn 1.6 m short).

### 13.2 How a K reaches (the lead's proposal; ⚠ the user's call)

Canon carries her reach in the cold off the blade (the 白刀 ice blade, ch. 268 [A]; the cold "released from the tip" [A,
canon-motion.md]); Ichigo's TYBW closed the same gap with 月牙の残光, an ink crescent from the drawn tip to the volume's
edge (DUEL_ICHIGO_TYBW §3.3). The proposal: **霜の穂先 (frost points)**, a solid drawn piece of ice for each K, part of
the strike, measured by the FK test as the striking point (the tip of the ice, ±0.15 m of the edge):

- **Shikai**: the ice grows off the point over the startup's last frames and shatters into snow after the hit (K1 a
  spike along the thrust; K2 a curved sheet trailing the cut; K3 a column dropped with the blade). Volumes unchanged
  (§4.4's approved numbers): **presentation only**, byte-identical.
- **The bands** (the scope: motion and reach follow each other): each band's ice is its own shape (−18 the palm's frost
  bloom, the sleeve's frost sheet, the ice flower; −50 the rime spike, the ice wall, both palms' flowers; −273 the long ice
  blade, lengthened 0.96 → 1.30 m for its ×1.35 J reach, and the lance off the levelled guard). The ice is sized to
  today's volumes where the new body fits them, and the volume moves only where the new archetype changes the shape
  (listed per row below, "→"): a sim change, gated against the parent.

Options for the user: (1) the above; (2) the Shikai's K glide made real (`:slide`, its capsule shortened by the same, the
effective reach kept: Ichigo's K3, DUEL_ICHIGO_TYBW §3.4) plus a shorter frost point (a sim change); (3) reach strictly the
blade and body: every K shrinks to about 1.7 m (her 遠近各半 role and the gates move a lot).

### 13.3 Shikai 袖白雪 (replaces style-refs §3.1)

Notation as style-refs §3 (B1 blade right hand, B1b backhand, B1r reversed, B2 both hands, P left palm, F the left index
finger, F2 two fingers, S a sleeve leading; planes H→ H← ↘ ↗ V↓ V↑ T T-hi, ⟲ ⟳ turns, G a circle on the plaza, stab, pt).
Grades A canon, C dance reference, D the lead's proposal. Every strike: a tell inside its startup, the hit pose on S,
an impact hold, follow-through and a settle key in the recovery; turns keyed every 90°.

**Idle** 構え: hips low, knees close, the blade one-handed level at chest height (A), the left hand at the chest (A), no
bounce (the hips sink 1 cm with the breath). **Walk** 摺り足, no head bob. **Run** crouched, the blade trailing level
behind (A).

| # | Archetype | Body in one line | Grade | Slot (S/A/R; volume) | Reach |
|---|---|---|---|---|---|
| J1 | 回り | a quarter turn ⟲ on the ball of the right foot, hips low; the blade flat across at chest height, the left hand at the chest [H→ / B1] | D (⟲ A) | 7/3/12; arc 100°, 1.44 | blade |
| J2 | 回り back | a quarter turn ⟳; the wrist turns over: a rising backhand from her left hip to above the right shoulder, the ribbon flipping over [↗ / B1b] | D | 7/3/13; 100°, 1.40 | blade |
| J3 | 回り, finale | a full turn ⟲ keyed every 90°, arms in a T, the hakama belling, the ribbon a hip ring; a small 決まり [⟲ / B1] | A + D | 8/3/18; 200°, 1.56 | blade |
| K1 | 剣舞・摺り足 | from the two-hand high guard (hilt at the right temple, A) a 0.5 m glide (drawn, recovered in R) and a two-hand thrust at the head line; the frost spike off the point [T-hi / B2] | A + D | 17/4/20; cap 0.2–2.8 r 0.3 | ice 3.10 |
| K2 | 剣舞 | the hips turn out of the thrust: a two-hand cut across the waist, sleeves flaring, weight back; a frost sheet trails the cut [H← / B2] | D | 21/4/24; arc 140°, 2.50 | ice 2.50 |
| K3 | 剣舞 → 見得 | a step in, the blade raised straight overhead (A), held 3 f, dropped with an ice column; the low finish held 12+ f, the head last [V↓ / B2] | A + C | 21/5/34; cap 0.3–2.7 r 0.35 | ice 3.05 |
| 霜散 J1+L | 袖返し + ヒラキ | the left sleeve flung round her as she hops back 2.5 m, frost scattering off it; lands in a low 決まり [⟳ / S] | C + D | 10/3/22; 360°, 2.0 | sleeve + frost 2.0 |
| 雪煙 J2+L | 扇の手 (かざし) | the blade raised over her head and spun flat on the wrist (要返し), a halo; snow-smoke falls round her [overhead ⟲ / B1] | C + D | 10/3/22; 360°, 2.0 | blade + snow 2.0 |
| 霜陣 J3+L | 足拍子 + 突き | one stamp and one stab point-down at her feet (canon 白漣's first stab draws the circle, A); the circle opens round him [stab / B1r] | A + C | 10/3/22; 360°, 2.0 | snow ring 2.0 |
| 氷礫 K1+L | 剣舞 (返し) | out of the thrust the point flicks up, throwing a spray of ice pebbles ahead [V↑ / B1] | D | 12/4/26; cap 0.2–2.8 r 0.3 | pebbles 3.10 |
| 氷柱 K2+L | 剣舞 (突き立て) | the blade reversed and driven into the plaza in both hands; icicles erupt in a fan ahead and shove him [stab / B2r] | A (pillars) + D | 12/4/26; arc 160°, 2.8 | icicles 2.80 |
| 白漣 K3+L | canon 白漣 | from K3's low finish the blade swept up and forward from the plaza, the wave running out 11 m [↗ / B2] | A | 12/4/26; cap 0.3–11 r 0.6 | the wave (not the blade) |
| L tap 白雷 | 鬼道 | the left arm drawn back to the right shoulder (the tell), then shot straight, one finger: the lightning line [T / F] | D | 12/3/28; line to 6 m | the line |
| L hold 月白 | canon 月白 (能・円) | the blade reversed, a glow (A); she sinks into the deep crouch (A) and sweeps round ⟲, the tip drawing the circle (A); rises, turns half away (A) [G / B1r] | **A** | ring ≤ 8 m | the ring |
| SP1 tap 蒼火墜 | canon 鬼道 | the left palm driven at his face (A, ch. 266), the right hand brought to the left wrist; the blue fire cone [T-hi / P] | **A** + D | 14/4/26; cone 40°, 5 m | the fire |
| SP1 hold 六杖光牢 | 鬼道 + 巫女舞 | the hold: two fingers raised straight overhead, the sleeve hanging, the ribbon rising; the release: dropped to point at him, the rods [V↓ / F2] | D | the rods ≤ 6 m | the rods |
| SP2 白刀 | canon 白刀 (サシコミ) | the right arm rises from low and drives straight at his face (A), the ice growing in three steps; after a burst, ヒラキ: three steps back opening both arms (C) [T / B1] | **A** + C | 16/4/28; cap 0.3–5.0 r 0.3 | the ice blade 5.3 |
| O 円舞 | 回り reversed + shunpo | the crouched shunpo run, blade trailing (A); a turn ⟳ with the blade raised overhead in two hands, descending in a spiral to the waist [⟳ / B2] | A + D | 8/3/24; 360°, 2.4 | blade + snow |
| I 這縄 | 仕舞 サシ | a low dash; the left arm rises from the side to point forward-high, two fingers (A ch. 266, C), the blade low and back point-down [↗ pt / F2] | A + C | 8/4/18; 1.35 | the rope (fingers 0.82) |

Check (plane / hand set): J1 H→ B1, J2 ↗ B1b, J3 ⟲ B1, K1 T-hi B2, K2 H← B2, K3 V↓ B2, 霜散 ⟳ S, 雪煙 overhead ⟲ B1
(a halo above her, against J3's ring at the chest), 霜陣 stab B1r, 氷礫 V↑ B1, 氷柱 stab B2r, 白漣 ↗ B2, 白雷 T F, 月白 G
B1r, 蒼火墜 T-hi P, 六杖光牢 V↓ F2, 白刀 T B1, 円舞 ⟳ B2, 這縄 ↗ F2. No two share both. One archetype a string: J = 回り
(its bursts the 回り's finishes: sleeve, fan, stamp), K = 剣舞 (its bursts the sword dance's ends: flick, plant, the
canon wave); the kidō are the canon gestures.

### 13.4 The bands (style-refs §3.2–§3.4, bodies unchanged; reach added)

Each band its own clips, no clip shared with another form. Reach: the striking point the proposal of §13.2 draws; "keep"
= the volume as today, "→" = moved (a gated sim change).

| Band | J1 / J2 / J3 | K1 / K2 / K3 | L / SP1 / SP2 / O / I |
|---|---|---|---|
| −18 (摺り足 J, 袖・素手 K) | ↘ B1 / ↖ B1b / H← B1 pass; blade, keep 1.44 / 1.40 / 1.56 | TŌSHU palm + frost bloom, keep 2.35; sleeve-led cut + frost sheet, keep 2.50; HYŌKA palm + ice flower, keep 2.40 | 霜柱 stab + ⟲ (disc r 2.5); 白漣 one-hand stabs gliding; 白刀 glide + thrust 5.0; 白霞罸 overhead raise, levelled; I サシ low |
| −50 (足拍子 J, 両掌 K) | ↘ B2 / ↗ B2 / H← low B2, each on a stamp; the rime blade (1.0 m) two-handed: 1.58 / 1.45 → 1.40 (a two-hand rising cut is shorter) / 1.72 | palm + the point beside it, rime spike, keep 2.55; the ice wall rising from both palms, keep 2.75; both palms down, flowers, keep 2.64 | 氷震 two stamps + the stab (disc r 3.5); 白漣 by stamps; 白刀 low two-hand 6.0; 白霞罸 two-hand raise; I stamp + point |
| −273 (扇の手 J, サシ / 袖 K; feet never move) | wrist flicks of the ice blade lengthened 0.96 → 1.30 m (a look): H→ / ↙ B1b / overhead ⟲; keep 1.94 / 1.78 / 2.11 | the guard levelled, the lance off it, keep 4.08; 袂払い sleeve + frost sheet, keep 3.38; the bow, palm, ice flower, keep 3.24 | 零度凍結 the sleeve swept low (disc r 5.5); 白漣 one stab, the wave; 白刀 7.5; 白霞罸 levelled from point-down; no I |

Only one volume moves in this proposal (−50 J2 1.45 → 1.40); the bands' reach follows their motion by sizing the drawn ice
to it. If the user wants the bands to differ more in reach than ×1.0 / ×1.1 / ×1.35 already makes them, the rows are
where to say it.

### 13.5 Inventory: new clips and what retires

- **Shikai** 22: idle, walk, run; J1–J3, K1–K3; the six bursts; 白雷, 月白 (redrawn), 蒼火墜, 六杖光牢 (cast + hold
  loop), 白刀 (+ its ヒラキ after a burst), 円舞 (its own run and turn, off `:sh-run` / `:ru-spin`), 這縄 (dash + strike).
- **−18** 12, **−50** 12, **−273** 11 (style-refs §3.2–§3.4 plus each band's idle). The cinematics, intro, win and the
  awakening keep their clips.
- Retire when nothing plays them: `:ru-q1-z`, `:ru-thrust-z`, `:ru-spin-50`, `:ru-flower-50`, `:ru-palm-50`,
  `:ru-ring` (four forms' K2), `:ru-palm` (−273's J2), `:ru-reido` (re-timed into −273's own L), `:ru-stab` (shared).
- 霜の穂先: one look (`rukia-art.lisp`, a stamp per band) drawn from the strike's clip hook, 0 B a frame, the sim reads
  none of it.

### 13.6 Order and checks

1. The user's 「可以」 on §13.2–§13.4 (and the questions with them).
2. **Shikai first** (presentation only): the clips, the FK report (every strike's drawing point ±0.15 m of its edge, the
   Shikai's K and bursts included, the 85000+ scenes for the in-match look), 8-frame strips from the side and the front,
   then the playtest; host tests, the looks gate is moved on purpose (her stills), `--cvc` identical, her pairings
   identical to the parent.
3. **−18, −50, −273** one band at a time: the clips, the FK report, the volume changes with their gates against the parent
   (her seven pairings, `--cvc`; the A/B stays deferred, §11.2), the playtest.

### 13.7 Decided (the user, 2026-10-24)

- The K reach: 「霜の穂先」 (§13.2 option 1; rejected: the Shikai's real glide, reach strictly blade and body).
- The bands' reach: 「大致維持現在」 (the ice sized to today's ×1.0 / ×1.1 / ×1.35; rejected: three bands set further apart).
- The tables §13.3–§13.4: 「可以，先做始解」: the Shikai first, presentation only; then −18, −50, −273.

### 13.8 As built: the Shikai's clips (batches ru-mA ae50225, ru-mB 25f4a33, merged; presentation only)

- **Wiring.** The Shikai plays its own `:ru-s-` clips; the bands play today's, untouched. The `:base` kit maps the shared
  strike clips through `:clip-map *ru-shikai-clips*` (J1–J3, K1–K3, SP2, I), its walk through `:look-clips`, its run
  through `:run-clips`, its idle `:stance :ru-s-stance`; `:m18` sets the three back (−50 and −273 inherit that). ENBU,
  the bursts and the kidō name their new clips directly (base-only moves). The bursts crossfade 3 f out of the link
  they follow (`:blend 3`).
- **Clips (29)**: `:ru-s-stance`, `-walk-f / -walk-b / -strafe-r / -strafe-l`, `-run`, `-j1 / -j2 / -j3`, `-k1 / -k2 /
  -k3`, `-shirafune` (its recovery a small ヒラキ), `-enbu-run`, `-enbu` (⟳ keyed every 90°, two hands, descending),
  `-breaker`, `-hainawa`; `-shimochiri`, `-setsuen`, `-sojin`, `-hyoreki`, `-tsurara`, `-hakuren`, `-byakurai`,
  `-tsukishiro` (its frame 0 is 白雷's tell, so the hold switch at f11 does not snap), `-kido` (蒼火墜's gather),
  `-sokatsui`, `-rikujo` (the hold, two fingers overhead, readable at any length to 100 f), `-rikujo-cast` (the release).
- **霜の穂先**: `*ru-frost-points*` (K1 1.40 m a four-sided spike, K2 1.30 m a curved sheet, K3 1.40 m a hex column, past
  the blade's tip along its axis), read by the look (`%ru-frost!` in her draw hook: grows over the last 6 startup frames,
  held through the active frames, shatters over 6) and by the FK test. Consing 0 B (the 85900 line).
- **Drawn reach** (tip, or tip + ice, at the hit frames vs the volume's edge; checked both ways ±0.15 m): J1 1.48 / 1.44
  (+4 cm), J2 1.47 / 1.40 (+7), J3 1.54 / 1.56 (−2), K1 3.07 / 3.10 (−3), K2 2.46 / 2.50 (−4), K3 3.05 / 3.05 (0), I
  1.28 / 1.35 (−7, the fingers). The bursts (never over the edge): 霜散 1.39 / 2.00, 雪煙 0.82 / 2.00, 霜陣 0.65 / 2.00,
  氷礫 1.63 / 3.10, 氷柱 0.74 / 2.80, 白漣 1.19 / 11.6; their frost, snow ring, pebbles, icicles and wave carry the rest
  (the burst looks of §6). Not in the test: SP2 (the ice blade carries it to 5 m), ENBU (1.4 m blade + snow on a 2.4 m arc).
- Old clips no form plays now (`:ru-stance`, `:ru-drop`, `:ru-tsukishiro`) stay until the bands' batches retire the rest.
- **Checks on the merge**: host tests 10223 ALL PASS; pkgcheck clean; the build 0 warnings; the browser smoke run exit
  0; her seven pairings × 10 seeds line for line identical to the parent b86ef45 (RY 104.7, RK 101.8, RR 123.0, IR 126.8,
  SR 114.4, BR 111.5, HR 129.8 s, all K.O.), `--cvc` identical (3 PASS). Playtest Artifact v159. Checked by numbers and
  8-frame strips from both sides; the feel needs the user's playtest.

## 14. K1 shorter; the K route pushes out of its edge (the user, 2026-10-24)

> 「目前始解的 K 連段結尾推的不夠遠，導致連打 K 能重複壓制，請縮短 K1 的攻擊距離」 (the user, 2026-10-24)

- **Why it reached.** K3's ender push (fighter.lisp ENDER-PUSH) and the K bursts' floor push (§9, RUKIA-BURST-OUT)
  measured K1's reach as its capsule's length b (2.8 m), but a capsule hits out to b + r (3.1 m): he was left 0.25 m
  inside a restarted K1 every time, so K K K, K K K ... kept him pinned.
- **Changed.** K1 `:vol (:cap 0.2 2.8 1.1 0.3)` → `(:cap 0.2 2.55 1.1 0.3)` (edge 3.10 → 2.85 m; still 0.5 m past J1's
  2.04 with its lunge, DUEL_STRINGS §13). The Shikai kit's new `:push-reach *ru-k-push-reach*` 2.85 (K1's edge, b + r)
  is what K3's push and the K bursts' floor push measure from: he lands out of K1 by *ender-push* (0.05 m) plus his
  walk-in, as every other K1 (K1 + L 氷礫 pushes to 2.85 + 0.45 + 0.05 = 3.35 m against Kenpachi, §9's 3.30 before). The
  bands set `:push-reach nil` (unchanged). The frost point on K1 1.40 → 1.15 m (drawn 2.82 / 2.85, −3 cm).
- **Tests.** Host 10203 ALL PASS (a check that the push reach is K1's b + r, the bands without one; Hisagi's hook-inertness
  check knows Rukia's Shikai sets `:push-reach`); pkgcheck clean, build 0 warnings, smoke exit 0.
- **Gates** (20 seeds, vs the parent 1a350d2; all K.O.; `--cvc` identical 3 PASS): RY 96.9 → 101.6 s (Rukia 10 → 8 of
  20), RK 101.8 → 101.0 (4 → 9), RR 114.0 → 114.0, IR 128.1 → 126.8 (10 → 11), SR 113.0 → 114.4 (10 → 11), BR 133.7 →
  152.6 (5 → 7), HR 137.5 → 140.0 (6 → 4). RY / RK / SR stay under 125 s as before the rework (§11.2, reported then).
  Playtest Artifact v160.

## 15. The ender push counts a capsule's radius, for everyone (the user, 2026-10-24)

> 「請修改推開規則，要將半徑也計算進去。其他角色我試過沒有這問題。」「沒改程式不用測試」 (the user, 2026-10-24)

- The shared rule (kit.lisp `move-edge`, ENDER-PUSH-REACH; RUKIA-BURST-OUT): a J3 / K3 ender (and Rukia's bursts) pushes
  him out of the opener's **far edge**, its reach + its first volume's radius when that is a capsule (b + r), not its
  capsule length alone. §14's Rukia-only `:push-reach` 2.85 (`*ru-k-push-reach*`) is removed: her K1's edge is 2.85 by
  the shared rule. A kit's own `:push-reach` (Hisagi) still wins.
- Openers it moves (the push grows by the capsule's r): Senjumaru K1 (2.90 → 3.20) and TSUJI K1 (3.80 → 4.10), Lille's
  SHIN / JILLIEL J1 (+0.40) and K1 (+0.40), Kenpachi's RYŌTE / NOMIHOSE J1 (+0.50), Yamamoto's Bankai J1 (+0.25) and K1
  (+0.30), Rukia's −18 / −50 / −273 K1 (+0.35 / +0.35 / +0.30); every arc opener is unchanged.
- Tests: host 10224 ALL PASS (every kit's ender push reach = its opener's MOVE-EDGE; Rukia's K1 edge 2.85, J1 1.44); build
  0 warnings, smoke exit 0. **No sim gate**: the user said no testing for the other characters (their code is unchanged).
  Playtest v161.

## 16. Combo damage scaling −10 % → −15 % a hit (the user, 2026-10-24)

> 「幫我提高連段的傷害減免」 (the user, 2026-10-24)

`*combo-decay*` 0.10 → 0.15 (tuning.lisp; hits 1–3 full, then 85 / 70 / 55 %, the 40 % floor from hit 7; it was hit 9).
The pinned damage checks follow (70 at hit 4: 63 → 60; Hisagi's B4c routes 174 / 132 → 170 / 130). DUEL_DESIGN "Combo
limits" and the manual's 連段傷害衰減 updated. Host 10224 ALL PASS, build 0 warnings, smoke exit 0; no sim gate run
(§15's word), playtest v161.

### 16.1 The floor 40 % → 20 % (the user, 2026-10-24)

> 「減免最低 20%」 (the user, 2026-10-24)

`*combo-floor*` 0.40 → 0.20: hits 1–3 full, then 85 / 70 / 55 / 40 / 25 %, 20 % from hit 9. Host checks follow
(`combo-scale` 8 0.25, 9 and 12 0.2; hit 20 of 100: 40 → 20); DUEL_DESIGN and the manual updated. Host 10224 ALL PASS,
build 0 warnings, smoke exit 0; no sim gate (§15). Playtest v162.

### 16.2 ORANGE restarts the scaling; Lille's awakened KL unscaled (the user, 2026-10-24)

> 「1. 橙色爆氣會將減免補正重置，且期間減免速度改成 10%、最低 50%　2. 利捷（覺醒）的架勢 L > K 之後再按 L 消耗翼打出的追加傷害連段不受減免補正影響。」 (the user, 2026-10-24)

- **ORANGE** (combat.lisp BURST!, COMBAT's damage; rules COMBO-SCALE / HIT-DAMAGE's ORANGE): the burst stores his combo's
  hit count (new fighter slot `combo-from`, reset with the combo in TO-IDLE); the scaling counts from the next hit (hits
  1–3 after it full again), and while the attacker's ORANGE runs each hit past 3 loses `*orange-combo-decay*` 0.10 down to
  `*orange-combo-floor*` 0.50 (85 / 70 / ... / 20 % otherwise). The HUD's hit count still counts the whole combo.
- **Lille** (DUEL_LILLE_V3 §31): the awakened stances' KL1–3 windows carry `:unscaled` (combo index 1; form and taken
  multipliers as before); the base stance's KL and every other segment scale as usual.
- Host 10226 ALL PASS (orange 4: 0.9, 7: 0.6, 8+: 0.5; the six KL moves flagged, the base's and the K / JL not); pkgcheck
  clean, build 0 warnings, smoke exit 0; no sim gate (§15's word). DUEL_DESIGN "Combo limits" and "Burst modes", the
  manual's 連段傷害衰減. Playtest v163.

### 16.3 Every SP ignores the combo scaling (the user, 2026-10-24)

> 「對了，順便幫我將所有角色的 SP 也都設置成不受傷害減免影響（包含一護卍解 SP2 的殘影攻擊）」 (the user, 2026-10-24)

- `sp-move-p` (kit.lisp): kind `:sp`, or the form's SP1 / SP2 command's move of another kind (Hisagi's ranged KUBIKAKE
  `:flash`, Lille's SHIN recall `:sig`). Its own hits are dealt at combo index 1 (COMBAT), as are its hazards': a hazard
  spawned while its owner plays an SP carries the new slot `sp` (SPAWN-HAZARD's default, overridable). Ichigo's KESSA SP2
  ZANZO: its afterimage echoes (`:ic-hit` hazards, data `:echo`) are `:sp` too, his clones are not. Form, taken and counter
  multipliers as before; the hits still count in the combo (the HUD, the next hits' scaling).
- Host 10227 ALL PASS (which moves count); pkgcheck clean, build 0 warnings, smoke exit 0; no sim gate. DUEL_DESIGN
  "Combo limits", the manual. Playtest v164.

### 13.9 As built: −18's clips (batch ru-m18 a36d567, merged; presentation only)

- **Wiring.** The `:m18` kit plays its own `:ru-18-` clips through `:clip-map *ru-18-clips*` (`:ru-q1 / q2 / spin / palm /
  ring / flower / stab / hakuren / shirafune / cold-stance / hakka / hainawa`), `:look-clips *ru-18-looks*` (the walks),
  `:run-clips` and `:stance :ru-18-stance`; SHIMOBASHIRA names `:ru-18-shimobashira` directly (`:ru-stab` is also SP1's
  hold). −50 and −273 set the three back (−50 its stance too): they play what they played. The Kikon cinematic and the
  Breaker's dash keep their shared clips.
- **Clips (18)**: `-stance` (the canon catch: left arm forward-high, palm open, blade low and back, hips 5 cm under the
  Shikai's), `-walk-f / -walk-b / -strafe-r / -strafe-l` (摺り足), `-run`, `-j1` (↘ with a drawn 0.3 m glide), `-j2` (↖
  backhand), `-j3` (the pass: a 0.6 m glide across his line, a flat cut, ends side-on), `-k1` TŌSHU, `-k2` (the sleeve
  leads, the blade under it), `-k3` HYŌKA (one knee, the palm on the plaza, the head up last at f47), `-shimobashira`
  (three point-down taps at −90 / 0 / +90°), `-hakuren-hold` (a stab a 16 f with a sideways glide), `-hakuren`, `-shirafune`
  (a 0.42 m glide, the thrust), `-hakka`, `-hainawa`.
- **霜の穂先**: `*ru-frost-points*` + `(:ru-18-k1 1.5 :ru-frost-bloom :palm)` (grown from the wrist along the forearm),
  `(:ru-18-k2 1.2 :ru-frost-sleeve)`, `(:ru-18-k3 1.8 :ru-frost-flower :flat)` (along the forearm's heading, laid on the
  plaza). Consing 0 B (the 85900 probe's warm-up 240 → 1000 calls: six frost meshes grow the draw queue inside a slot).
- **Drawn reach** (both ways ±0.15 m): J1 1.44 / 1.44 (0), J2 1.46 / 1.40 (+6), J3 1.47 / 1.56 (−9), K1 palm + bloom
  2.36 / 2.35 (+1), K2 blade + sheet 2.50 / 2.50 (0), K3 palm + flower 2.40 / 2.40 (0), HAINAWA 1.27 / 1.35 (−8); the
  Shikai, −50 and −273 lines unchanged.
- **Checks on the merge**: host 10227 ALL PASS, pkgcheck clean, build 0 warnings, smoke exit 0; her seven pairings × 10
  seeds identical to the parent (the batch's run). The G2 reference `tests/style-cvc-ref.txt` regenerated from the browser
  for §15–§16.3's intended changes (stale since them; native `--cvc` 3 PASS against it): yy winner P2 0-2 122.8 s, yk P2
  0-1 95.5 s, kk P1 5-0 101.8 s. Playtest v165. Notes for the playtest: the point grazes the plaza 2–3 cm for a frame in
  J2, SHIRAFUNE and HAKKA; SP1's release from the middle stab's pose turns up to 60° in a frame after a short hold.

### 16.4 Hisagi's chain tip unscaled (the user, 2026-10-25)

> 「幫我將修兵卍解遠距的尖端判定也設成不受連擊衰減的影響」 (the user, 2026-10-25)

A kit `:unscaled` hook (combat.lisp) next to §16.3's SP rule; Hisagi's ranged mode answers it for a chain-tip hit
(DUEL_HISAGI §25.36). Host 10228 ALL PASS, build 0 warnings, smoke exit 0; no sim gate. Playtest v166.

### 13.10 As built: −50's clips (batch ru-m50 fd8cd90, merged; presentation only)

- **Wiring.** The `:m50` kit: `:stance :ru-50-stance`, `:clip-map *ru-50-clips*` (HYŌSHIN included), `:look-clips
  *ru-50-looks*`, `:run-clips`. −273 inherits `:m18` and keeps the map off. Every two-hand clip (the guard, walks, run, the
  blade strikes) is in `*grip-clips*` (the left fist on the hilt); the K's and HAINAWA leave the left hand free. The old
  −50 key edits (`:ru-palm-50 :ru-spin-50 :ru-flower-50 :ru-stab-2h`) play nowhere now (kept until the clean-up).
- **Clips (18)**: `-stance` (low, wide, both hands on the hilt at the navel), `-walk-f / -walk-b / -strafe-r / -strafe-l`
  (a heavy shuffle), `-run`, `-j1` (the right knee up, the chop on the right stamp), `-j2` (the left stamp, the rising cut),
  `-j3` (the knee-height half turn, keyed every ~90°, a double stamp), `-k1` (the palm forward-low, the point ~10 cm into the
  plaza beside it), `-k2` (both palms swept up: the ice wall), `-k3` (both palms down in a deep squat, the head up last at
  f47), `-hyoshin` (two stamps, the two-hand stab), `-hakuren-hold` (a stamp a 12 f, turning to each spike), `-hakuren`
  (swept low across), `-shirafune` (the deep lunge, the back knee near the plaza), `-hakka`, `-hainawa` (a stamp, the
  fingers).
- **霜の穂先** (`:flat` from the left palm): K1 1.83 m `:ru-frost-rime` (a crust, a spike at the tip), K2 2.29 m
  `:ru-frost-wall` (a wall of shards at the end), K3 1.90 m `:ru-frost-flowers`. Consing 0 B.
- **Drawn reach** (two-hand J's fit, no volume moved): J1 1.56 / 1.58 (−2 cm), J2 1.46 / 1.45 (+0), J3 1.67 / 1.72 (−5),
  K1 2.54 / 2.55 (−1), K2 2.75 / 2.75 (0), K3 2.64 / 2.64 (0), HAINAWA 1.28 / 1.35 (−7); the other forms' lines unchanged.
- **Checks on the merge**: host 10228 ALL PASS, pkgcheck clean, build 0 warnings, smoke exit 0, `--cvc` 3 PASS; her
  seven pairings × 10 seeds identical to the parent (the batch's run). Playtest v167. For the playtest: the left fist
  falls 0.1–0.2 m short of the hilt in the wide tells (J2, SP1's hold, J3's end); K1's point (~10 cm) and HYŌSHIN's (~18
  cm) go into the plaza on purpose; up close the K ice runs past him to the edge.

### 13.11 As built: −273's clips and the clean-up (batch ru-m0 317217a, merged; presentation only)

- **Clips (11, `:ru-0-`; feet never move, 序破急)**: `-stance` (upright, head bowed, no breath, the point low across her),
  `-j1` (the flick up flat across, the arm straight, the hips 0.12 m forward over the feet), `-j2` (the backhand ↙), `-j3`
  (the halo over her head, the torso ~60° on planted feet, hips 0.2 m), `-k1` (the vertical guard tipped slowly level, the
  lance), `-k2` (the sleeve brushed out at the waist, the frost sheet), `-k3` (the bow, the palm on the plaza, the head up at
  f49), `-reido` (the head lifts, the sleeve swept low, sudden), `-hakuren` (one stab, the blade raised at him), `-shirafune`
  (the arm raised straight forward), `-hakka` (levelled from point-down); helper poses `:ru-0-low` / `-low-r` keep the
  1.3 m point out of the plaza on the way back.
- **Wiring**: the `:zero` kit `:stance :ru-0-stance`, `:clip-map *ru-0-clips*`; `:ru-z-j2`, `:ru-reido`, `:ru-hakuren-0`
  name their clips; −50's `:ru-a-k1-50 / :ru-j3-50 / :ru-a-k3-50 / :ru-hyoshin` name theirs (out of `*ru-50-clips*`; what
  −50 plays is unchanged). The ice blade `:ru-ice` 0.96 → 1.30 m (length 1.34; a look).
- **霜の穂先**: K1 2.57 m `:ru-frost-lance`, K2 2.95 m `:ru-frost-veil` (`:palm`), K3 2.92 m `:ru-frost-lotus` (`:flat`).
  Consing 0 B.
- **Drawn reach** (zero now checked both ways, out of `*reach-one-sided*`): J1 1.88 / 1.94 (−7 cm), J2 1.71 / 1.78 (−7),
  J3 1.98 / 2.11 (−13), K1 4.08 / 4.08 (0), K2 3.39 / 3.38 (+2), K3 3.24 / 3.24 (0); the other forms unchanged. The J's
  reach their ×1.35 arcs only with the arm straight and the hips leaning over the planted feet (J3 a visible lean).
- **Retired**: the clips `:ru-q1-z :ru-thrust-z` (and the white body's `:clips` swap), `:ru-reido :ru-zero :ru-stance
  :ru-tsukishiro :ru-palm-50 :ru-spin-50 :ru-flower-50 :ru-stab-2h :ru-shirafune :ru-cold-stance` (with their only poses;
  `:ru-stance` / `:ru-cold-stance` stay as poses). **Kept**: `:ru-q1 :ru-ring` (Senjumaru's Divine Soldier), `:ru-hakka` (the
  白霞罸 cinematic), `:ru-spin` (the model sheet), and the inherited moves' clip keys every form maps (`:ru-q2 :ru-thrust
  :ru-drop :ru-stab :ru-hakuren :ru-palm :ru-flower :ru-breaker :ru-hainawa`), the intro / win / Kikon / awakening clips.
- **Checks on the merge**: host 10228 ALL PASS, pkgcheck clean, build 0 warnings, smoke exit 0, `--cvc` 3 PASS; her seven
  pairings × 10 seeds identical to the parent (the batch's run). Playtest v168. For the playtest: 白霞罸's card shows the
  raised ice blade off the top of the frame; K2's sleeve reads weakly from behind (the sheet carries it); K3's reversed
  blade stands up behind her in the bow; O's pillar hides her levelling.
- **The motion pass is complete**: every Rukia form plays its own clips (the Shikai 29, −18 18, −50 18, −273 11).

## 17. Her CPU: the catalogue first (the user, 2026-10-25)

> 「我希望將步驟改成先從幀數表、取消規則、位移與量表消耗等資訊展開出可行的連段與攻擊手段，在思考如何將這些手段引用至對戰策略中」
> (the user, 2026-10-25)

The CPU work's order (skill `duel-character-cpu` "Order", for every fighter from now): (1) a data sheet per form from
the kit; (2) a catalogue of hit-confirmed combos and non-combo means, each verified in the native sim against a dummy;
(3) a strategy (situations → catalogue entries, styles as weightings) for the user's pick; (4) the CPU encoding it, a
search only tuning it under a frozen evaluator; then the gates (her pairings, the awaken A/B deferred since §11.2,
ASSIST, G2). Rukia's comes first: the Shikai, then −18, −50, −273.

### 17.1 Step 1: the Shikai's data sheet (2026-10-25)

`tools/move-sheet.lisp -- rukia base` (new, any character / form; host only) prints the sheet from the kit:
`docs/research/rukia-cpu/sheet-shikai.md` (the kit's numbers; every move's S / A / R, whiff and block recovery, hit
windows and damage, reaction and stun, hit and block advantage, volume and far edge, slide / kb, cost, params; the
on-hit cancel edges with their frame math; the shared rules). Every edge it lists combos on paper (J1 → K2s +2 and J2 →
K3 +2 the tightest; the SP cancels off J1 / J2 +3 to +5); step 2 verifies them in the native sim against a dummy.

### 17.2 Step 2: the Shikai's catalogue, sim-verified (2026-10-25)

> 「繼續」 (the user, 2026-10-25)

- **The trial player** (debug only, sim-neutral: `--cvc` 3 PASS identical): `scripted.lisp` TRIAL-STEP (brain habit
  `:trial`, wired in ai.lisp BRAIN-STEP next to the button-masher): it presses only `*trial-script*`'s steps, each `(button
  frames &key modded wait on stick)`, the next once the last started its move (`:on :hit` once it landed, `:on :free` once
  she is neutral), `:walk` for the stick alone; a "press" combat-log line each. `tools/simgate/trial.lisp` (a native
  process: per trial a fresh placement, gauges, layers, a standing or guarding dummy, cinematics skipped) and
  `tools/combo-trial.py` (builds the native sim as simgate does, prints the table: damage, the gaps before each hit, the
  advantage, the distance, Reiatsu / flash step, his layers).
- **The catalogue**: `docs/research/rukia-cpu/catalogue-shikai.md` (findings + all 53 trials of
  `trials-shikai.lisp`). Highlights: K1 K2 K3 ORANGE K1 K2 K3 416; K1 K2 K3 SP2 at 3 layers 393; I K1 K2 K3 345; K1 K2
  K3 +L 白漣 331 with no bar (the K string makes its own layer, so the burst is always on); the K string alone 208, +1; the
  J3 enders +5 at 2.54 m; 氷礫 the one plus burst (+4); 氷柱 pushes to 6 m (TSUKISHIRO after it is not a combo, 52 f
  free); RIKUJOKORO → O lands the Kikon from full health (the seal's red); RIKUJOKORO → Step in → K is not a combo (17 f).
  Blocked: J1 −4, K1 −6; a blocked K string's K2 whiffs and K3 is −26; SP2 −14.
- Host tests 10228 / control 89 / learn 131 ALL PASS, pkgcheck clean, the build 0 warnings.

### 17.3 Step 3 by a strategy search (the user, 2026-10-25)

> 「利用新的 /anthropic-skills:dream-rsi 來探索在面對不同對手、距離、量表、等等條件下，適合使用的戰術策略。請先以每個角色的幀數表、攻防距離等等資訊為基礎來規劃策略並逐步改進。」;
> RIKUJOKORO → O and ORANGE's use: 「依據攻防戰略的探索結果來決定」 (the user, 2026-10-25)

The three styles of `docs/research/rukia-cpu/strategy-shikai.md` are not picked by hand: a dream-rsi search explores the
tactics by condition (the opponent and his form, the distance, both sides' gauges, his layers / red), starting from a
plan built on every character's frame data and reach, and improves it round by round. The base: every form's data sheet
(`docs/research/rukia-cpu/opponents/*.md`, `tools/move-sheet.lisp`) and her matchup sheet
(`docs/research/rukia-cpu/matchups-shikai.md`, new `tools/matchup-sheet.lisp`: per opponent form his J1 / K1 startup and
far edge, his fastest hit, his longest reach, what her J1 (7 f) punishes on his block, his pokes). The evaluator, budget
and parallelism are confirmed with the user before the first cell (the skill's rule).

### 17.4 The search's settings (the user, 2026-10-25)

> 「0.3/0.2/0.5 招牌至上，如果有複數種選項都能帶來優勢效益，那就根據帶來的效益依機率選擇出招。」; the signature themes
> 「中近距離牽制與霜層的回收」「霜層爆開與收割」「鬼道」「封印毀魂」「K 連段與橙色爆氣」; 「先跑 1 輪 8 格，同時 2 個」;
> 「四個型態一起，在開始前先試打來驗證覺醒的資料表」 (the user, 2026-10-25)

- **Score** = 0.3 strength + 0.2 masher + 0.5 signature (× the NORMAL factor), Hisagi's weights; where several options pay,
  the CPU picks among them **by probability weighted by their payoff** (not the single best).
- **Signature**: five themes (a whitelist per theme, frozen with the evaluator): mid / close pokes and layer recovery, the
  bursts and their harvest, the kido, the seal → Kikon, the K string and ORANGE.
- **Budget**: one round of 8 cells, W = 2.
- **Scope**: all four forms; first the awakened bands' data sheets verified by trials (as the Shikai's, §17.2).

### 17.5 The search, frozen (2026-10-25)

- **Her CPU split out**: `duel/lisp/rukia-ai.lisp` (loads before rukia.lisp) holds the four forms' :ai plists
  (`*ru-ai-base*` .. `*ru-ai-zero*`; the DEFKITs read them by name), every RUKIA-AI-* function and *AI-RU-* knob; the kits'
  :ai values identical before / after (compared), `--cvc` 3 PASS, the build 0 warnings. Her CPU's host checks moved into one
  `RUKIA-CPU-TESTS` section (10228 ALL PASS, the same count).
- **The awakened bands' catalogue**: `docs/research/rukia-cpu/catalogue-awakened.md` (trials-m18 / -m50 / -zero; every route
  a combo; K string + L 285 / 349 / 512, + SP2 350 / 415 / 575, + SP1 held 306 / 388 / 608; at −273 an ORANGE restart's K
  links spend cold and she warms to −50 mid-combo).
- **The evaluator**: `tools/aieval.py --char 2`: 0.3 / 0.2 / 0.5, the NORMAL band [0.30, 0.60], `SIG_RUKIA`'s five themes by
  name and by the sim's "Px ru-sig seal / orange / tsukishiro / rikujo" tags (rukia.lisp RUKIA-HIT, combat log only), a
  new "str_by_opp" (her HARD wins by opponent). **Baseline 0.5898** at 40 seeds: strength 0.273 (Ichigo 58 / 80, Senjumaru
  44, Yamamoto 29, **Kenpachi, Lille, Hisagi 0**), masher 1.0, signature 0.616 (burst 0.23, poke 0.23, kstring 0.13, kido
  0.03, seal 0.002), NORMAL 0.423, pacing ok (medians 100.8–140.4 s).
- **The workspace** `docs/research/rukia-ai-drsi/` (README, step.sh, rescore.sh, brief.py, splice-tests.py; W = 2, 4 × 2
  cells, λ 0.25); the branches open the condition axes: the opponent, her resources, the distance, the awakening and bands.

### 17.6 Two CPU bugs, fixed in her own CPU (the user, 2026-10-25)

Cell b0a0 (round 1) reported two things her file could not reach. The user: 「請調查原因並修復你說的兩個問題：1. 劍八的毀魂追擊會穿過防禦
2. CPU 擋下攻擊後不會反擊」; then, mid-fix, 「請逐步將共用 AI 的功能轉移給專屬 AI」, with the picks 「可替換的預設步驟」 (the shared
CPU's parts become named steps a character's own CPU may replace) and 「只修露琪亞專屬 AI」 (the other CPUs keep both bugs until
their own turn).

- **Cause 1 (the Kikon through her guard).** Not a rule: the follow-up is blocked by a held guard (a scripted trial: BLOCKED).
  Her CPU held Guard through the stagger and the dash-in, but on the strike's own step her perfect-Hoho reflex pressed Step;
  under the Kikon lock no Hoho can start, so the only effect was that Guard was let go: she was :neutral when the strike
  was collected, and the Kikon landed (traced in the native sim, seed 1: def-state NEUTRAL, red NIL, in front).
  **Fix**: her `:held` step (RUKIA-AI-HELD): under a Kikon lock 1 a guard she holds stays held, nothing else is chosen.
- **Cause 2 (no punish after a block).** The generic CPU rolls on each blocked hit (*AI-HOLD-GUARD*, HARD 0.8) to hold Guard
  for the blockstun + 20 steps, and no reflex runs while it holds (the block punish included). Still holding when the
  blockstun ends, she went back into a guard, and an attack waits *GUARD-EXIT* after it is let go. **Fix**: her
  `:block-hold` step tags that press, and her `:held` step lets it go on the blockstun's last step once nothing is left to
  chain (FIGHTER-GLOCK off): she comes out in neutral and the block punish / her reflexes run on the next step.
- **The steps** (ai.lisp *AI-STEPS*, AI-STEP; DUEL_AI_V2 "Replaceable steps"): `:block-hold` (default AI-BLOCK-HOLD, the old
  code) and `:held` (default none); a kit's :ai names its own. Only her four forms name them.
- **Proof the others are untouched**: `--cvc` 3 PASS (identical to the reference), host tests 10228 ALL PASS, pkgcheck clean.
- **Effect** (10 HARD matches, Rukia P1 vs Kenpachi, seeds 1–10): his non-red follow-ups blocked 6 → 51, Kikons landed 42 → 25
  (the red ones are unguardable by rule); her wins **0 → 4 of 10**.
- **Gates** (her seven pairings, 20 seeds, vs the parent 2bf0488; all K.O.; median s, Rukia's wins of 20): RY 102.2 → 103.5
  (8 → 10), RK 99.2 → 94.0 (9 → 8), RR 121.8 → 132.0, IR 107.9 → 112.0 (11 → 10), SR 107.6 → 111.0 (7 → 13), BR 132.1 →
  137.0 (6 → 7), HR 134.6 → 126.5 (7 → 6). RY / RK / IR / SR stay under 125 s as on the parent (her short pairings since
  §11.1, not this change); the awaken A/B stays deferred (§11.2).

### 17.7 Her damage x0.75 (the user, 2026-10-25)

> 「請在將露琪亞的基礎傷害量減少 25%，先讓我確認你會怎麼修改後再開始行動」

Proposed and confirmed (「四個型態都 ×0.75」; the search: 「跑完這輪再重新凍結」): only the four forms' dealt multipliers move,
no move's own damage (one place, every move, link and hazard, the forms' ratios kept; rounding per move avoided).

| Knob | Old | New |
|---|---|---|
| `*rukia-mult*` (Shikai) | 1.0 | **0.75** |
| `*rukia-awake-mult*` (−18) | 1.1 | **0.825** |
| `*rukia-m50-mult*` (−50) | 1.25 | **0.9375** |
| `*rukia-zero-mult*` (−273) | 1.65 | **1.2375** |

Unchanged: the combo scaling, the Kikon (Konpaku), the damage she takes, frames, reach. Down with it: the Reiatsu she gains
by dealing damage (the rule). Host tests 10228 ALL PASS (the pinned bands' multipliers updated). The search's round 1 runs
on to its 8 cells at the freeze 2a68ece (the old damage); the pick is integrated and re-scored on this damage.
`docs/research/rukia-cpu/stats-vs-roster.md` regenerated.

Gates (her seven pairings, 20 seeds, all K.O.; median s and Rukia's wins of 20, §17.6's numbers before): RY 103.5 → 110.4
(10 → 11), RK 94.0 → 105.4 (8 → 8), RR 132.0 → 156.1, IR 112.0 → 128.0 (10 → 7), SR 111.0 → 134.4 (13 → 6), BR 137.0 →
152.0 (7 → 6), HR 126.5 → 141.0 (6 → 5). IR and SR now in the 125–210 s window; the edge reruns at 60 seeds: **RY 108.5 s**
(Rukia 28 of 60), **RK 102.7 s** (20 of 60), still under 125 s as they have been since §11.1: reported to the user, who
accepted them: 「RY 和 RK 先列為例外」 (2026-10-25).
- **The search**: cells b0a0 and b1a0 were made on the freeze 2a68ece (without these steps); the remaining cells start from
  the new commit, and the baseline is re-scored on it (§17.5's 0.5898 was before).

### 17.8 The search's round 1 (8 cells, 2026-10-25 / 26)

Every cell rescored at the freeze 2a68ece (the evaluator's 40 seeds; the rescore's freeze pinned after b2a0 was first
measured at 4b8e80f, the damage x0.75 commit). Strength = her HARD wins share, signature = her five themes' share.

| Cell | Parent | Direction | Score | Strength | Signature | HARD wins of 80: Y K I S Lille H | Awaken A/B rows passing |
|---|---|---|---|---|---|---|---|
| baseline | — | — | 0.5898 | 0.273 | 0.616 | 29 0 58 44 0 0 | 3 / 21 |
| b0a0 | — | the opponent | 0.7154 | 0.325 | 0.836 | 35 0 55 31 8 27 | 7 |
| b1a0 | — | her resources | 0.7506 | 0.410 | 0.855 | 42 0 78 65 0 12 | 1 |
| b2a0 | — | distance | 0.8421 | 0.671 | 0.882 | 71 9 80 67 16 79 | 17 |
| b3a0 | — | the awakening | 0.7190 | 0.329 | 0.841 | 39 1 64 33 1 20 | 2 |
| b0a1 | b0a0 | + b2a0's reactive layer, measured-payoff pokes per opponent | 0.8839 | 0.742 | 0.923 | 76 6 80 71 43 80 | 20 |
| b1a1 | b1a0 | + b2a0's anti-step and oki seal, awaken at 1800 taken | 0.8906 | 0.750 | 0.931 | 72 35 79 74 20 80 | 16 |
| **b1a2** | b1a1 | + the anti-dash Hoho against Lille's awakened charged dash | **0.9214** | 0.863 | 0.925 | 72 35 79 74 **74** 80 | — (only BR moves: 35 / 28 / 21, pass) |
| b0a2 | b0a1 | + the comeback awakening (1800), b1a0's first-strike envelope per opponent | 0.9188 | 0.827 | **0.941** | **78 38 80 79** 42 80 | **21** |

What every strong cell shares: J1 meeting his Step-in (HARD, read on the hop's first frame), the K route into 白漣, the
knockdown cashed by RIKUJOKORO on his wake-up and the O on the sealed victim (the Kikon from full health), a bar kept for the
seal, no plain O, the Breaker out of the neutral; and the awakening as a comeback (her Shikai out-scores her bands at the
freeze). Open: Kenpachi (35-38 of 80; §17.6's guard bug at the freeze) and, outside b1a2, Lille's awakened dash.

The dream (round 1's world): the adaptive policy (the skill's template) replayed 0.3577 against the floor's 0.1929 and is
promoted for a next round. Two more cells the policy asked for (b2a1, b3a1) were not run: the user's budget, 8 cells.

### 17.9 The pick (the user, 2026-10-26)

Asked which CPU to ship and what to do with her rare awakening, the user picked 「b0a2 + b1a2 的反衝刺」 and 「照搜尋結果（1800
翻盤）」: b0a2's file (its per-opponent matchup tables and payoff-weighted pokes, b1a0's first-strike envelope, the comeback
awakening at :min-taken 1800, the anti-step J1, the K route into 白漣, the oki RIKUJOKORO → O seal, no plain O, no neutral
Breaker) with b1a2's anti-dash (RUKIA-AI-ANTI-DASH: the perfect Hoho timed on Lille's released charged dash by its predicted
slide, *AI-RU-DASH-GAP* 3.4 m, EASY 0 / NORMAL 0.3 / HARD 1.0; RUKIA-AI-MU-DASH: wait beyond J1 against a dash form; both in
her ASSIST's AUTO GUARD too), on main's code: her §17.6 steps (`:block-hold` / `:held`), the damage x0.75 (§17.7) and the
shared CPU's replaceable steps (DUEL_AI_V2). Integration: one file, both cells' CPU tests, re-scored on main, her gates.

**As integrated (2026-10-26)**: `duel/lisp/rukia-ai.lisp` is b0a2's file with main's §17.6 steps and b1a2's anti-dash knobs and
functions (RUKIA-AI-ANTI-DASH in the reflex after the anti-step, before the perfect Hoho; RUKIA-AI-MU-DASH after
RUKIA-AI-MU-DECIDE; her ASSIST's AUTO GUARD tries the anti-dash first). Two overlaps: (1) b1a2's wait goes after b0a2's
matchup decision and skips a red opponent (66 vs 67 of 80 either order); (2) b0a2's Lille `:guard-on` row (a long guard on his
stance entry and both dash moves) is removed: with it the anti-dash Hoho fired 260 times in 40 matches but HARD won 25 of 80
against Lille, without it 67 of 80 (b1a2 alone on main 71, b0a2 alone 22; ablations: no dash-move guard 23, no entry guard 25).
RUKIA-AI-MU-GUARD stays, listed by no row. The removal approved by the user (「可以」, 2026-10-26). CPU tests: b0a2's section + b1a2's anti-dash block, Lille's `:guard-on` pinned absent.
aieval on main (40 seeds): **0.9398** (strength 0.892, masher 1.0, signature 0.945; NORMAL share 0.477 in its 0.3-0.6 band;
HARD vs Yamamoto 70, Kenpachi 53, Ichigo 80, Senjumaru 78, Lille 67, Hisagi 80 of 80). Her gates (with §17.11's L): DEVLOG §392.

**Her gates** (the CPU with §17.11's L, 2026-10-26): every match K.O.; 20 seeds RI 140.6 s, RS 147.5 s, RL 156.9 s, RH 148.6 s,
the mirror 157.6 s; RY 117.0 s and RK 119.6 s, rerun at 60 seeds: **RY 115.9 s, RK 111.8 s**, outside the window: accepted as the
exception on record (the user, 2026-10-26: 「沿用例外」; it was 108.5 s / 102.7 s, §17.7). Awaken A/B: all 21 rows pass (the never-awaken side 21-40 of 60;
before, 4-18, §11.1-§11.2: the rebuilt CPU closes that). aieval 0.9386 (NORMAL share 0.479). ASSIST (the masher's wins): off
26%, GUARD 1 / 2 27% / 57%, COMBO 69%, BREAK 34%, all 78%, all with GUARD 2 97%. `--cvc` 3 PASS.



### 17.10 Her awakened L blocked: the frames (measured, the user, 2026-10-26)

The user asked 「覺醒後的 L 後搖有幾幀？」 and 「如果對手防住 L 後用 J 回擊，會在幾幀打中？」, then: 「把這套資訊記錄，如果受到覺醒露琪亞 K+L
的連段壓制，除了 hoho 跟藍色爆氣外還能想辦法防禦等待中間的確反」. Measured in the native sim (P1 her L, P2 every opponent with
GUARD ALL and the practice COUNTER J1; frames from her L press; before §17.11's +10 recovery):

| Band | L | S / A / R (whiff / blocked R) | blocked at | he is free | she is free | gap |
|---|---|---|---|---|---|---|
| −18 | 霜柱 `ru-shimobashira` | 12 / 0 / 22 (28 / 22) | f12 | f29 | f37 | −8 |
| −50 | 氷針 `ru-hyoshin` | 14 / 0 / 22 (28 / 22) | f14 | f31 | f39 | −8 |
| −273 | REIDO `ru-reido` | 10 / 0 / 26 (32 / 26) | f10 | f27 | f39 | −12 |

His J1 lands, from 1.0 m (1.6 m after the block push): −18 Lille f36, Kenpachi / Ichigo / Senjumaru f37, Hisagi f38,
Yamamoto f39; −50 two frames later each; −273 Lille f34, the three f35, Hisagi f36, Yamamoto f37. So a J1 of 7 f or less is
a true punish at −18 / −50, every J1 at −273; from 1.8 m (2.4 m after the push) only Kenpachi's lunging J1 reaches.
(Corrected in §17.11: at −273 those J1s touch her absolute-zero ward, which stays until REIDO ends, so they do not stun her.)

**Her K string + L, blocked** (K1+L, K1 K2+L, K1 K2 K3+L, all three bands): the guard lock (FIGHTER-GLOCK) holds him in
blockstun from the first blocked K to the end of the L, no gap; both free on the same frame (−18: f79 / f120 / f173; −50 and
−273: f80 / f122 / f175): ±0, no punish; only BLUE breaks it (the lock lets nothing else through, Hoho included). Asked whether
to open a punish there (release the lock on the L, or a gap between K and L), the user chose 「維持現狀，只記錄」. The manual's
Rukia tips quote both rows.

**Her loop K1 K2 K3 +L, K1 K2 K3 +L** (the user, 2026-10-26: 「重點在於對方不斷使用 K123+L , K123+L 迴圈時要等中間的破綻」): the
gap is the restart. Both are free on the same frame after each loop (±0); her next K1 needs 17 f, so his J1 pressed on his first
free frame lands first: measured (2.2 m, GUARD ALL + COUNTER J1) at −18 her K1 restarts f174-175 and Kenpachi's / Hisagi's /
Yamamoto's J1 land f182 / f182 / f183; at −50 (restart f176) f183 / f184 / f185; at −273 REIDO leaves him 4.6 m away, beyond
every J1 (the gap is for closing in or a Hoho). Guarding only, the loop goes on (and her blocked hits cool her: −18 → −50 after
the first loop). If she restarts with J1 (7 f) instead, it is J1 against J1. The manual's tip says so.


### 17.11 Her awakened L's longer recovery (the user, 2026-10-26)

The user: 「然後幫我延長 L 的後搖，但要保證 1. L 打中後能接上 J1 2. L 打中後接 K 是不安全的 3. L 打空（防禦也算）後面對對手的 J1
不安全，但對 K1 安全（可以用防禦取消調整） 在修改前先告訴我你的調整策略」. Offered +6 / +10 / +14 frames with the hit stun and a
guard cancel set to keep the three rules, the user picked 「+10 幀 (Recommended)」.

| Band | L | recovery | hit stun | guard cancel from (move frame) |
|---|---|---|---|---|
| −18 | 霜柱 `ru-shimobashira` | 22 → 32 | stagger 26 → 42 (`:stun`) | 40 |
| −50 | 氷針 `ru-hyoshin` | 22 → 32 | crumple 40 → 42 (`:stun`) | 42 |
| −273 | REIDO `ru-reido` | 26 → 36 | bind 45 → 46 | 37 |

- **The hit stun** (`:stun` in the move's params, the disc's hit window: COMBAT's override when the reaction is the window's own)
  keeps her on hit at +9 in every band (she is free f53 / f55 / f55, he f62 / f64 / f64): her 7 f J1 combos, her 17 f K1
  does not (he is free 8 frames before it lands). A counter-hit gets no extra stun on these three (the override).
- **The guard cancel**: a new `:gc-from` move param. GUARD-CANCEL-OPEN-P takes it (FROM) and, when set, is open from that move
  frame to S + A + R whatever the move touched (a hazard move never sets its owner's contact, so the old rule never opened
  for L). Both callers (FIGHTER's step and AI-GUARD-CANCEL) pass `(getf (mv-params mv) :gc-from)`; no other move has it, so
  every other move keeps the old rule. The frames are set so her guard is up 13 frames after a blocked L frees him (measured:
  he is free f30 / f32 / f28, her guard f43 / f45 / f41). Every J1 in the roster (6-10 f; Hisagi's Bankai ranged J1 14 f is the
  one ranged exception) lands before it; every K1 (16 f or more) is guarded. Without the guard she is free f47 / f49 / f49
  after a block: −18 / −18 / −22 (was −8 / −8 / −12).
- **Measured** (native sim, P1 her L, P2 each of the six opponents' base forms at 1.0 / 1.8 m, his J1 or K1 pressed on his first
  free frame): with her U held from L's start, at 1.0 m every J1 hits her and every K1 that reaches is blocked (Lille's and
  Hisagi's base K1 never touch at that range); from 1.8 m (2.4 m after the block push) only Kenpachi's lunging J1 reaches.
  On hit, from 1.0 m (2.0 m after the knock-back) her J1 combos, from 1.8 m (2.8 m) it is out of reach; −273's bind does not push.
- **−273's ward**: absolute zero's passives (`:ward :freeze-touch`) stay on until REIDO ends (the cold drops her to −50 when she
  is free). So without the guard cancel his J1 into a blocked REIDO meets her ward (no stun, and the first touch of the visit
  freezes him); with it, the cancel ends REIDO early, she drops to −50 there and his J1 hits her. Rule 3 at −273 holds only
  once she leaves zero. Asked whether REIDO should drop her to −50 at its strike, the user chose 「維持」 (2026-10-26): kept.
- **Her K string + L blocked** (§17.10): the guard lock still holds him to the L's end, so it stays ±0, 10 frames later (−18
  f89 / f130 / f183, −50 and −273 f90 / f132 / f185); the loop's gap is still the restart.
- Tests: `tests/duel-rules/rukia.lisp` (the three moves' recovery / stun / `:gc-from`, the cancel's window, the bands' pin).
  Her CPU: AI-GUARD-CANCEL now guards out of a blocked or whiffed L too (it asks the same rule).

### 17.12 Her awakened L on a hit: J1 cancels 10 frames sooner (the user, 2026-10-26)

The user: 「把露琪亞覺醒的 L 改成打傷對手的話可以透過 J1 提早一點取消」; asked how much sooner, 「提早 10 幀 (Recommended)」.

- On a hit (her disc's: a hazard never sets her contact, so APPLY-HIT now marks `fighter-hz-hit` when a hazard of hers hits),
  J cancels her L's recovery into J1 from move frame 34 / 36 / 36 (S + A + R − 10: on a hit the old 22 / 22 / 26 recovery,
  §17.11's +10 kept for a block or a whiff). K never cancels (rule 2 holds: her K1 still starts at +9). The kit side:
  `:r-cancel (:q) :r-cancel-from N` in the three moves' params; MOVE-COMMANDS' `:r-cancel` clause takes `:r-cancel-from`
  (from that frame, her contact or a hazard hit) and keeps Hisagi's rule without it (from S + A, his melee hit).
- Measured (native sim, Kenpachi dummy, J held from L's start): J1 starts f43 / f44 / f44 instead of her free frame f53 /
  f54 / f54 and combos (from 1.0 m; from 1.8 m the knock-back leaves him 2.8 m away at −18 / −50, beyond J1; −273's bind
  does not push, so it combos there too); K: none, she is free f52 / f54 / f54 and he blocks.
- Tests: `tests/duel-rules/rukia.lisp` (the three moves' `:r-cancel` / `:r-cancel-from` = S + A + R − 10, the bands' pin),
  `tests/duel-rules/hisagi.lisp` (the moves with `:r-cancel`: Hisagi's two and Rukia's three).

### 17.13 RIKUJŌKŌRŌ: a 30 f shut, a slower charge, a Step's iframes escape it (the user, 2026-10-27)

The user: 「露琪亞的六丈光牢必須要有更長的蓄力時間且要更容易用 step 躲開，不然性能太過頭了」. Asked (the ring shut 14 f after
its mark, a Step needs ~8 f to leave it: ~6 f to react), the user chose: 「拉長到達蓄力上限所需要的時間（封鎖時間跟之前的上限
一樣）並將光環收束改成 30f」 and 「Step 無敵幀也算躲開」.

| Knob (`duel/lisp/rukia.lisp` `:ru-rikujo`) | Old → new |
|---|---|
| The ring's shut after its mark (`:delay`) | 14 → **30** f (the mark at f2, the bind at f32) |
| Its startup (S = the shut; her recovery 26 after it, as before) | 16 → **32** (`:clip-s` 16: the cast clip at half speed) |
| `*ru-rikujo-rate*` (new): held frames per bind frame past the 45 | 1 → **2**: the cap `*ru-rikujo-max*` 100 unchanged, reached at 111 held frames (`:hold (0 111)`, was 56) |
| The bind's hit (`:life`) | 6 → **1** frame: it binds only on the frame it shuts, so a Step or a Hoho out of the ring, **or inside its iframes on that frame**, escapes it |
| `:tell` (the CPU victims' anti-bind window) | (2 16) → **(2 32)** |
| Her CPU: `*ai-ru-rikujo-hold*` | 14 → **27** (the same 58 f bind at rate 2); the cash-out's stun floor uses S 32; `*ai-ru-oki-lead*` 15 → **31** (the oki's bind still on his wake-up: the shut 16 f later) |

The SOKATSUI / RIKUJOKORO hold threshold (16 f) is unchanged.

- Host tests: `tests/duel-rules/rukia.lisp` re-pinned (S 32, the shut at S, life 1, the rate, the hold reaching the cap
  exactly, the tell, the CPU's hold 27 / 43 and the oki lead 29..33). duel-rules 10244, learn 131, control 97 ALL PASS;
  pkgcheck clean; built.
- Smoke (browser): 85026 (into a held guard) binds at tick 33; 85027 (into his CPU): Kenpachi ran in and hit her during the
  longer cast; 85028 (held to its end at 5.9 m): the bind lasts ~100 f, she is free ~25 f after it starts.
- Manual: the row says 0.5 s to the shut, the hold's longer cap and that a Step / Hoho in its iframes on the shut escapes.

**Gates** (her 7 pairings, 10 seeds, all K.O.; median s, before = 146ef31 at 10 seeds; her wins of 10):

| Pairing | Before | After | Her wins before → after |
|---|---|---|---|
| RY | 114.6 | 117.5 | 4 → 3 |
| RK | 102.3 | 114.8 | 3 → 3 |
| RR (mirror) | 168.6 | 204.6 | — |
| IR | 150.7 | 127.3 | 5 → 2 |
| SR | 140.0 | 157.4 | 6 → 2 |
| BR | 163.9 | 182.6 | 5 → 2 |
| HR | 147.5 | 163.4 | 4 → 1 |

IR at 20 seeds (its quick pass under 135 s): 132.7 s, 20 K.O., her wins 4 of 20: inside 125–210. RY / RK stay under
125 s as before (their accepted exceptions, §17.9). `--cvc` 3 PASS (no Rukia in G2's three matches). Her CPU leaned on the bind: its wins outside the mirror 27 → 13 of 60.

**Awaken A/B** (`--cmd 39020` / `39002`, 60 seeds a stream; her never-awaken side's wins at seed0 100 / 300 / 500): RY 5 / 10 / 10,
RK 1 / 3 / 3, RR 15 / 16 / 15, IR 4 / 5 / 2, SR 9 / 7 / 2, BR 3 / 3 / 2, HR 8 / 8 / 8 of 60: **all 21 rows under 20** (they all
passed at 21-40 on 2026-10-26, §17.9, before the Reiatsu change of DEVLOG §394; no baseline A/B re-run on 146ef31). Read with
the 10-seed rows above: her Shikai CPU lost its main tool. Reported to the user, nothing retuned.
