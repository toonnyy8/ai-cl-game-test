# RAVEN EDGE — Game Design Spec (v1)

Scope: a polished demo of 5–10 minutes. It runs title → 3 waves → boss → results.
Background research is in `docs/research/ng4-notes.md`. Technical context is in `docs/ARCHITECTURE.md`.
Every number here is a **default**. Put them in named constants (§12) and tune by feel.

---

## 0. Conventions (read first)

- **Time.** Gameplay runs at a fixed 60 Hz step. **f** means frames at 60 fps (1 f = 0.0167 s). Seconds are given where natural.
- **Time scale.** Hitstop and slow-mo change the sim `dt` (§7). Rain, UI and camera shake always run on real time.
- **World axes.** Right-handed, **+Y up**, **north = −Z**, **east = +X**, 1 unit = 1 m. The roof surface is y = 0 and the arena centre is (0, 0, 0).
- **Yaw.** Yaw 0 faces −Z. Positive yaw turns counter-clockwise seen from above, so +90° faces −X (west).
- **Character local frame.** **fwd** = facing direction, **up** = +Y, **right** = fwd × up. Hit volumes are written in these terms, e.g. `SPH(fwd 1.5, up 1.0, r 1.2)`.
- **Hit volumes** are *gameplay shapes* in the attacker's local frame. They do **not** follow the animated blade, so animation can change freely without changing balance. The blade position is used only for trails and sparks.
  - `ARC(r, deg, y0–y1)`: a horizontal sector centred on fwd. A target is hit if its hurt-capsule axis at a height in [y0, y1] lies within `r + target.radius` and within ±deg/2 of fwd.
  - `CAP(fwd a→b, up h, r)`: a capsule along fwd from a to b metres, at height h.
  - `SPH(fwd, up, r)`: a sphere.
- **One hit per target per swing.** An attack instance hits each target once, unless the row lists multiple hits.
- **Hurt capsules** (vertical, radius / height): player 0.35 / 1.8. Grunt 0.38 / 1.8. Thrower 0.34 / 1.7. Brute 0.75 / 2.6. Boss 0.55 / 2.4.

---

## 1. Pillars & premise

**Pillars**
1. **Relentless, readable aggression.** Enemies attack together and punish your recovery. Every attack is telegraphed, so every hit you take is your own fault.
2. **Kill fast or get overwhelmed.** Crippling an enemy lights up an OBLITERATE prompt. Finishing it quickly refills your meter and stops the fight from snowballing.
3. **Red means answer, not block.** A glowing-red attack must be *dodged* or *broken* with Raven Form. The only way to block it is Raven Guard, which spends gauge.
4. **Weight in every frame.** Each hit has hitstop, crimson mist, shake and a sound. Rain, neon and a silhouette against the city do the rest.

**Premise.** Near-future **Neo-Kasumi**, a sprawling Tokyo-like megacity. It has rained for forty days, and the rain carries a crimson taint that animates the dead. REN, the last blade of a disbanded shadow order, is caught on the roof of the Tsukuyomi Tower. The rain has woken the **Rain Legion** (armoured corpse-soldiers) and their commander, **ENRA, THE CRIMSON GENERAL**. The scene is night, 60 storeys up, under magenta and cyan billboards, a pale moon behind cloud and endless rain. Cut through the Legion and break the General before dawn.

---

## 2. Controls

### Keyboard + mouse
| Action | Key | Notes |
|---|---|---|
| Move | WASD | Relative to the camera. Walking is not a separate key. Keyboard always runs. |
| Camera | Mouse (pointer lock). Arrow keys as fallback | Mouse sens yaw 0.15°/px, pitch 0.12°/px. Arrows 150°/s. |
| Light attack | J / LMB | |
| Heavy attack | K / RMB | Also Obliterate when the prompt is showing. |
| Jump | Space | |
| Dodge | Shift / L | Goes in the input direction, or backward if there is no input. |
| Guard | Q (hold) | A fresh press is also the parry. |
| Raven Burst / exit Raven Form | E | |
| Lock-on toggle | Tab / F | |
| Pause | Enter / Esc | Esc also releases pointer lock (browser behaviour). The first click on the canvas re-locks. |

### Gamepad (SDL standard layout)
| Action | Button |
|---|---|
| Move / camera | L-stick / R-stick (radial deadzone 0.20, camera 200°/s at full tilt) |
| Light / Heavy | X (□) / Y (△) |
| Jump / Dodge | A (✕) / B (○) |
| Guard | RT (R2) hold, threshold 0.35 |
| Raven Burst | LT (L2), threshold 0.5 |
| Lock-on | R3 or RB |
| Pause | Start |

### Buffering & cancels
- **Input buffer: 12 f (0.20 s)** for Light, Heavy, Jump and Dodge. Each action keeps the timestamp of its most recent press. When a cancel window opens, the most recent buffered action within 12 f is consumed. If several are pending, priority is **Dodge > Jump > Heavy > Light**.
- **Chain window.** Opens at the end of the active frames (`A_end`) and closes at the end of recovery. A buffered press fires at the first frame the window is open.
- **Dodge cancel.** Allowed from `A_end` of any attack. **On hit** it is allowed from the hit frame. It is never allowed during startup, except in the first 3 f of Light 1, Heavy 1 and Dash attack (so you can abort an accidental press).
- **Guard cancel.** Allowed from `A_end + 4 f`.
- **Jump cancel.** Only from the launcher (Rising Crow) and from the ground-shock enders on hit (H3, L5).
- **Movement cancel.** Stick or keys interrupt an attack only after its recovery ends. Recovery is committal on purpose.
- **Hitstop does not advance frame counters.** Inputs pressed during hitstop go into the buffer.

---

## 3. Player kit — REN

### 3.1 Stats & movement
| Param | Value |
|---|---|
| Max HP | **200** |
| Run speed | 7.5 m/s. Analog < 0.5 tilt walks at 3.0 m/s. |
| Ground accel / decel | 60 m/s² / 50 m/s² (0.125 s to full speed) |
| Turn rate (ground) | 900°/s. It snaps instantly at attack startup when a soft-lock target exists. |
| Jump | vy = **9.5 m/s**, gravity **28 m/s²**. Apex 1.61 m at 0.34 s. |
| Fall speed cap | 25 m/s |
| Air control | accel 20 m/s², max horizontal 7.5 m/s. Air turn 540°/s. |
| Land recovery | 4 f. It becomes 10 f if the fall lasted more than 0.8 s (no fall damage). |
| Dodge (ground) | Roll **5.0 m in 0.35 s** (21 f): 18 m/s for 12 f, then linear decel over 9 f. **I-frames f1–f16.** From f17 it can cancel into any attack or guard. Cooldown: none, but a 2nd dodge within 0.15 s of the last dodge ending has no i-frames (stops roll-spam). |
| Dodge (air) | Dash 3.5 m in 0.25 s. I-frames f1–f10. One per airtime. Zeroes vy and ignores gravity for its duration. |
| Guard move speed | 2.2 m/s. Faces the soft-lock target, or else camera forward. |
| Footsteps | Every 0.25 s while running (2 steps per 0.5 s cycle) |

### 3.2 Frame data
Legend: **S/A/R** = startup / active / recovery in frames. **Imp** = poise damage (impact). **HS** = hitstop in frames, applied to attacker and victim (§7). **HW** = heavy-weight: this hit can **cripple** (§4.4). Knockback (KB) is the push distance applied to the target over 6 f, away from the player.

#### Ground
| Move | Input | S | A | R | Dmg | Imp | Hit volume | Reaction / KB | HS | Cancels (besides §2 rules) |
|---|---|---|---|---|---|---|---|---|---|---|
| **L1** Rain Cut (R→L horizontal) | J | 6 | 4 | 14 | 10 | 10 | ARC(2.3, 110°, 0.2–2.0) | flinch, 0.6 m | 3 | →L2, →K = Rising Crow |
| **L2** Return Cut (L→R) | J after L1 | 6 | 4 | 14 | 10 | 10 | ARC(2.3, 110°, 0.2–2.0) | flinch, 0.6 m | 3 | →L3, →K = Crescent Sweep |
| **L3** Rising Diagonal | J after L2 | 7 | 4 | 16 | 12 | 12 | ARC(2.4, 100°, 0.0–2.4) | flinch, 0.8 m | 3 | →L4, →K = Crescent Sweep |
| **L4** Twin Spin (2 hits) | J after L3 | 8 | 10 (hits f8, f13) | 18 | 8+8 | 10+10 | ARC(2.5, 360°, 0.2–2.0) | flinch, 1.0 m | 3 each | →L5, →K = Raven Rain |
| **L5** Falling Moon (overhead) · HW | J after L4 | 12 | 5 | 28 | 24 | 40 | ARC(2.7, 70°, 0–2.2) + SPH(fwd 1.8, up 0.3, r 1.2) | knockdown, 3.0 m | 6 | jump on hit; nothing else |
| **H1** Cleave · HW | K | 14 | 6 | 22 | 24 | 35 | ARC(2.7, 150°, 0.2–2.0) | stagger, 1.5 m | 6 | →H2 |
| **H2** Reverse Cleave · HW | K after H1 | 14 | 6 | 22 | 24 | 35 | ARC(2.7, 150°, 0.2–2.0) | stagger, 1.5 m | 6 | →H3 |
| **H3** Earthsplitter · HW | K after H2 | 20 | 6 | 34 | 36 (+20 shock) | 50 | ARC(2.8, 60°, 0–2.2). Shock: SPH(fwd 2.0, up 0, r 3.0), hits only targets with feet < 0.5 m. | knockdown, 3.5 m radial | 8 | jump on hit |
| **Rising Crow** launcher · HW | L1 → K | 10 | 5 | 18 | 18 | 30 | ARC(2.3, 70°, 0–2.4) | **launch**: target vy = +11 m/s, 0.5 m fwd | 5 | **jump-cancel from f15** into Chase Jump (vy 11.5, auto-faces target). Holding K through f15 does the Chase Jump automatically. |
| **Crescent Sweep** · HW | L2/L3 → K | 12 | 8 | 22 | 26 | 45 | ARC(2.9, 360°, 0–1.8) | knockdown, 3.0 m radial | 7 | — |
| **Raven Rain** flurry | L4 → K | 8 | 30 (6 hits, every 5 f) + final at f38 | 24 | 5×5 + 18 final (HW) | 8 each / 40 final | CAP(fwd 0.3→2.6, up 1.1, r 1.0) | flinch ×6, then stagger 2.5 m | 2 each, 7 final | — |
| **Gale Thrust** dash attack · HW | J after running ≥ 0.35 s | 8 | 8 | 18 | 16 | 30 | CAP(fwd 0.3→2.4, up 1.1, r 0.6). Player slides 4.0 m over f0–f16. | stagger, 2.0 m | 5 | →L2 |

Heavy while running = H1 (there is no separate running heavy).

#### Air
| Move | Input | S | A | R | Dmg | Imp | Hit volume | Reaction | HS | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| **AL1–AL3** Air Cuts | J in air (max 3 per airtime) | 5 | 4 | 10 | 8 each | 10 | ARC(2.2, 120°, −0.8…+1.4 relative to player pelvis) | **air flinch**: airborne target gets vy = +2.0 and gravity ×0.3 for 0.35 s | 3 | Player **hangs** from startup to the end of recovery: vy = max(vy, 0.5), gravity ×0.25. After AL3, gravity is normal until landing. |
| **Thunderfall Drop** (grab-slam) · HW | K in air while an **airborne** enemy is within 2.2 m (grab-immune: brute, boss) | grab at f4 | — | 12 on land | **60** target + 20 AoE | — | Grab needs no hitbox. Impact AoE: SPH(fwd 0, up 0, r 3.0) around the landing point, other enemies only. | target: knockdown (dies if HP ≤ 0). AoE: knockdown, 2.5 m radial | 10 on impact | **Invulnerable from f0 to landing + 12 f.** Timeline: f0–f6 grab (both snap together, target in front of player, facing it) → f6–f27 rise 1.5 m while spinning (720° yaw) → head-down fall at 18 m/s until ground → impact. Total ≈ 0.8 s. |
| **Kestrel Strike** (jump-slash) · HW | K in air, target 2.5–9 m inside a 45° half-angle cone, and not grabbable | 6 | travel ≤ 22 f | 16 (after arriving) | 30 | 40 | CAP along the travel path, r 0.9 at chest height | stagger, 2.0 m | 6 | Flies to target at **24 m/s**, ends 1.2 m in front of it. **No i-frames**: grunts may block it (35 %) and the boss may counter it. On hit, cancel into L1 on landing. |
| **Plunge** | K in air, nothing else valid | 6 (hover) | until landing | 20 | 26 on contact / 20 shock | 40 | Falling: CAP(fwd 0→0.8, up −0.5, r 0.8). Landing shock: SPH(0, 0, r 2.5). | knockdown, 2.5 m radial | 6 | Falls at 22 m/s. Dodge-cancel from landing + 8 f. |

Air heavy priority: **Thunderfall > Kestrel > Plunge.**

#### Defense & specials
| Move | Input | Timing | Effect |
|---|---|---|---|
| **Guard** | hold Q | active from 2 f after press | Blocks every **non-red** hit from the front 180° (projectiles included). Blocked hit: 0 damage, **guard meter −(damage × 2.5)**, player pushed 0.4 m, 3 f hitstop, clang sparks. Meter is 100 and regenerates 30/s after 0.8 s without blocking. At 0 → **Guard Break**: 1.0 s helpless stagger, the meter refills to 100 afterward. A red attack against guard means Guard Break **and** full damage. An orange tint appears on the player when the meter is below 35. |
| **Parry** (perfect guard) | fresh Q press **≤ 8 f (0.133 s)** before a blockable **melee** hit arrives | anti-mash: a press within 20 f of the previous press opens no window | Attacker is **staggered 1.0 s** (boss 0.6 s). 8 f hitstop, 0.5× slow-mo for 0.2 s, cyan burst, raven +8, no guard-meter loss. Parrying a kunai destroys it. **Riposte**: J or K within 0.5 s → S5 A4 R18, **35 dmg**, Imp 60, HW, ARC(2.4, 90°, 0–2.2), stagger 1.5 m, HS 8, then →L2. |
| **Dodge** | Shift / L | §3.1 | I-frames f1–f16. |
| **Just Dodge** | an enemy hit volume (or a projectile within 1.0 m) touches the player's hurt capsule while the player is in dodge frames **f1–f10** | cooldown 0.8 s | **Enemies run at time scale 0.3 for 0.5 s of real time.** The player keeps 1.0. A white-blue after-image appears and `:dodge` plays pitched up. Raven +8. Works on red attacks. **Mirage Counter**: J or K during the slow-mo (or 6 f after it) → player warps to the attacker (≤ 6 m) in 6 f, then A4 R16, **30 dmg**, Imp 60, HW, SPH(at target, r 1.2), stagger 0.9 s (boss too), HS 8, raven +6. Chain →L2 from `A_end`. |
| **Raven Burst** | E with gauge ≥ **40** (grounded or airborne) | S6 A4 R12, i-frames f0–f21 | 30 dmg, Imp 80, SPH(0, 1.0, r 4.0), knockdown 4 m radial, HS 6, then 0.4× slow-mo for 0.25 s. **Enters Raven Form.** Pressing E during Raven Form ends it immediately (gauge kept). |
| **Raven Form** | — | lasts while gauge > 0; drains **10/s** | Blade becomes a crimson blood-blade (mesh length ×1.8, emissive). **RL1–RL4** use L1–L4 timings with **dmg ×1.5, Imp ×2, arc radius +0.9 m**, all HW, all **guard-breaking** (a blocking enemy is staggered 0.8 s). Air cuts get the same buffs. **Heavy becomes Crimson Lance**: S12 A6 R22, **45 dmg**, Imp 90, HW, CAP(fwd 0.3→6.0, up 1.1, r 0.8), pierces everything, stagger 1.0 s, HS 8. It can repeat (K →Crimson Lance from `A_end + 4`). The L-string enders (Rising Crow, Crescent Sweep, Raven Rain) keep their base shapes with the ×1.5 buff. **Raven Break**: any Raven Form hit on an enemy that is in a **red windup** cancels the attack, deals +20 bonus damage and staggers it **1.5 s** (boss 1.2 s; add +0.5 s if the windup was > 70 % complete). **Raven Guard**: in Raven Form, guard blocks red attacks for **15 gauge** each (0 damage, no guard-meter loss). No gauge is gained while in Raven Form except from Obliterate (+10). |
| **Obliterate** | K while a **crippled** enemy is ≤ 3.0 m away, within 100° of the stick or facing (else the nearest crippled one ≤ 3.0 m), player grounded and not in hit reaction | fixed 45 f (0.75 s) | Takes priority over any heavy. **Invulnerable** for the whole move + 12 f. f0–f6 warp to 1.2 m in front of the target, facing it. f6–f15 wind-up. **f15 cut**: the target dies (bisected: its upper-body parts detach), 12 f hitstop, then enemies run at 0.25× for 0.4 s real time. f15–f45 follow-through and blade flick. Reward: **raven +25**, **HP +12** (3 blue orbs), 2 gold orbs, +1 Obliteration stat. Other enemies may not start attacks during the move. Their current attacks continue at slow-mo speed, but the player is invulnerable. |

### 3.3 Raven gauge (0–100)
| Source | Gain |
|---|---|
| Light / air hit | +2 |
| HW hit | +4 |
| Kill (any) | +3 |
| Parry / Just Dodge | +8 each |
| Riposte / Mirage Counter hit | +6 |
| **Obliterate** | **+25** (+10 in Raven Form) |
| Gold essence orb | +5 |
| Passive (not in Raven Form) | +1/s |

Activation threshold 40. In Raven Form it drains 10/s, and Raven Guard costs 15 per block. From full, Raven Form lasts ~10 s. Expect 2–3 activations per wave and 3–4 during the boss.

### 3.4 Soft-lock / auto-target
- Target selection runs **at frame 0 of every attack**.
- **Direction.** Use the input direction (camera-relative) if the stick is above 0.3 or a key is held. Otherwise use player facing.
- **Candidates.** Living enemies within **7 m** (ground attacks) inside a **60° half-angle** cone around the direction. With no input, the cone is 90° and the range 4.5 m.
- **Score** = distance + 0.05 × angle in degrees. Lowest wins. The lock-on target (if any) always wins when it is in range.
- **Snap.** Player yaw snaps to the target at f0.
- **Magnetism.** If the target is farther than (move reach − 0.3 m), the player slides toward it during startup. Lights may slide ≤ 1.5 m, heavies/HW ≤ 2.0 m, Gale Thrust ≤ 4.0 m.
- **No target.** The attack goes in the input direction, or facing.

### 3.5 Player hit reactions
| Incoming | Reaction | Push | After-invuln |
|---|---|---|---|
| dmg ≤ 15, not flagged | **flinch** 15 f | 0.5 m | 10 f |
| 16–29 dmg | **stagger** 30 f | 1.2 m | 15 f |
| ≥ 30 dmg or knockdown flag (all red attacks) | **knockdown**: 0.35 s airborne back 3 m → 0.5 s down → 0.4 s getup | 3 m | invulnerable from hit + 12 f until getup ends |
| Guard break | 60 f helpless | 0.4 m | — |

- **Tech roll.** Dodge within 9 f of landing from a knockdown → dodge roll (skips down and getup).
- **Anti-juggle.** The player can take at most **2 damaging hits per 1.0 s window**. Further hits in that window do no damage and no reaction.
- **Death.** HP 0 → 0.3× slow-mo for 1.2 s → Game Over screen.

---

## 4. Combat system rules

### 4.1 Hit reactions (enemies)
| Reaction | Duration | Notes |
|---|---|---|
| flinch | 18 f | Interrupts startup of normal (non-red) attacks. |
| stagger | 42 f | Interrupts any non-red attack. |
| knockdown | 0.4 s airborne + 0.9 s down + 0.5 s getup | Downed enemies take **×0.6 damage** and cannot be launched. 0.3 s invulnerable at the start of getup. |
| launch | ballistic, **gravity 22 m/s²** | Air hits float the target (§3.2). On landing: 0.6 s down, then getup. |
| crumple (crippled) | 60 f | §4.4 |
| guard-hit / guard-break | 8 f / 48 f | Grunts and the boss only. |

**Poise / super armor.** Each enemy has poise P. Each hit subtracts its Imp. If poise is still > 0 → **armored hit**: damage applies, the enemy flashes and gets **half hitstop**, but has no reaction. If poise ≤ 0 → the move's full reaction plays and poise resets to max. Poise regenerates to full 1.5 s after the last hit.
- **Red windups have hyper armor** (infinite poise). Only a Raven Break, a parry (melee red can't be parried) or death interrupts them.
- **Thunderfall and Obliterate ignore poise.**

### 4.2 Hitstop (frozen frames on attacker + victim; global sim freeze)
Implementation: during hitstop the **whole gameplay sim is frozen** (dt = 0). FX, rain, camera shake and UI keep running.
| Event | Frames |
|---|---|
| Light / air hit | 3 |
| Blocked by enemy / by player | 3 |
| Launcher, dash, Kestrel, heavy H1/H2 | 5–6 (per table) |
| Enders (L5, H3, sweep, flurry final) | 6–8 (per table) |
| Parry, Riposte, Mirage, Crimson Lance | 8 |
| Thunderfall impact | 10 |
| Obliterate cut | 12 |
| Killing blow (any) | +3 on top |
| Player hit by light / heavy / red | 4 / 7 / 9 |
| Armored (no reaction) hit | half, rounded down, min 2 |

If two hitstop events land in the same frame, take the **max**, not the sum.

### 4.3 Damage values
There are **no floating damage numbers**. Feedback is flash, mist, sound and the combo counter. Every number in the frame data is final (no crits, no randomness). Damage to downed enemies is ×0.6.

### 4.4 Crippling & finishers
- **Cripple rule.** If a **HW** hit leaves an enemy at **0 < HP ≤ 30 % of max** (brute: 25 %), that enemy becomes **crippled**. Light hits can take HP below the threshold without crippling. The next HW hit then cripples (or kills, if its damage ≥ remaining HP).
- **Visual.** The enemy's weapon-arm part (upper arm, lower arm, hand and weapon) detaches as a physics debris piece with a crimson mist burst. The enemy then plays **crumple** (60 f).
- **Crippled behaviour.** The enemy crawls toward the player at 1.2 m/s for 3.0 s. Then it does **Death Grip**: red telegraph 0.8 s, lunge 3 m, **30 dmg**, knockdown, unblockable. The enemy dies afterward and drops nothing. Death Grip needs no aggression token.
- **Other kills.** Any hit on a crippled enemy kills it (normal drops). Obliterate kills it with the premium reward (§3.2).
- **Prompt.** `OBLITERATE [K]` (or `[Y]` on gamepad) appears above the best crippled target when it is within 4 m. It is actionable at 3 m.
- **Boss.** Never crippled. At 0 HP it kneels **BROKEN** with an infinite-duration OBLITERATE prompt (auto-triggers after 6 s). The finisher is a 1.5 s cinematic (§5.4).

### 4.5 Red (unblockable) attacks
- **Telegraph.** All of the enemy's parts are tinted **#FF1A1A at 55 %**, pulsing at 8 Hz, plus a red glint sprite on the weapon. `:warn` plays at windup start.
- **Ground marker.** AoE red attacks also draw a red ground ring (alpha 0.4) at the impact area for the whole windup.
- **Minimum windup** is **0.8 s** (48 f). Phase 2 of the boss is the exception: 0.7 s.
- **Counters.** Red attacks cannot be blocked or parried (guard → Guard Break + full damage). Answer them with a **dodge** (i-frames or distance), a **Raven Break**, or **Raven Guard**.
- **Rules.** All red attacks cause knockdown. They never need more than one dodge to avoid: no delayed second hit without a fresh telegraph.

### 4.6 Aggression tokens (the "NG-aggressive but fair" model)
| Rule | Value |
|---|---|
| Melee tokens | **2** (the boss ignores tokens) |
| Ranged tokens | **1** |
| Token held | from windup start to recovery end |
| Global re-issue delay after a token returns | 0.25 s |
| Per-enemy attack cooldown | grunt 1.6 ± 0.4 s · thrower 2.8 ± 0.5 s · brute 3.0 ± 0.5 s · boss 0.8–1.4 s (P1) / 0.5–1.0 s (P2) |
| **Punish rule** | If the player is in **≥ 14 f of recovery** (heavies, enders, whiffed Kestrel) and an enemy with a ready cooldown is ≤ 2.5 m away, it may take a free token (a 3rd melee token, allowed once per 1.5 s) with windup ×0.8. |
| **Off-screen rule** | An attacker outside the camera view (screen x outside ±1.0) adds **+10 f windup**, plays `:warn` and shows a red chevron at the screen edge pointing toward it. |
| Hit cap | At most 2 damaging hits on the player per 1.0 s (§3.5). |
| Pause attacks | During player Obliterate, Thunderfall, Raven Burst startup and getup-invuln, no new attack windups start. |
| Enemies without a token | Circle / strafe on their ring (§5). 20 % of the time they do a **feint step** (0.3 s lunge-in and back, no hitbox) to keep pressure visible. |

### 4.7 Invulnerability summary
- Dodge f1–f16 (air f1–f10).
- Raven Burst f0–f21.
- Thunderfall (whole move + 12 f).
- Obliterate (whole move + 12 f).
- Mirage Counter warp and active frames.
- Knockdown from hit + 12 f until getup ends.
- Post-flinch / stagger windows (§3.5).
- Player on respawn: 2.0 s.
- Enemies: spawn drop-in, until landing + 0.3 s.
- Boss: phase transition (2.0 s) and intro.

### 4.8 Separation & physics
- Characters are capsules that push each other apart. The player pushes enemies at 50 % strength and enemies push the player at 30 %.
- Props are static boxes and cylinders (§6.2).
- The arena boundary is invisible walls at |x|, |z| = 17.6, up to 4 m tall. Launched enemies are clamped inside too.

---

## 5. Enemy roster

All enemies use the shared humanoid rig (§11.1), scaled. "Windup" = startup; the red ones are §4.5 telegraphs.

### 5.1 RAINBLADE — sword grunt
**Look.** 1.78 m. Olive-drab lamellar armour, a bone-white oni half-mask with red eye slits, a straight sword 0.9 m, and a tattered grey waist cloth. The silhouette is broad shoulder plates (0.62 m wide) and a slight forward hunch.
**Stats.** HP **60** · poise 10 (reacts to every hit) · walk 3.0, run 5.5 m/s · turn 360°/s.

| Move | Trigger | Windup | Active | Recovery | Dmg | Hit volume | Notes |
|---|---|---|---|---|---|---|---|
| Slash | dist ≤ 2.2 m | 27 f (0.45 s). Blade raised; a white glint appears at f18. | 7 f | 36 f | 14 | ARC(2.0, 90°, 0.3–2.0) | 50 % weight |
| Double Slash | ≤ 2.2 m | 24 f, hit, then 15 f gap, hit | 7 + 7 | 40 | 12 + 12 | same | 30 %. 2nd hit is cancelled if the 1st is parried. |
| Lunge Thrust | 3.5–6 m | 30 f (sword pulled back at the hip) | 15 f dash 5 m | 42 | 18 | CAP(fwd 0→1.6, up 1.1, r 0.5) | 20 % (100 % if the player stays at 3.5–6 m for > 2 s) |
| Block | player's light attack incoming from the front 120°, grunt not attacking | instant | holds 0.6 s | — | — | — | **35 %** chance per player string (rolled on the first hit). Blocks lights, AL and Kestrel. HW hits cause guard-break stagger 48 f. Raven hits cause guard-break. |
| Escape | after 6 consecutive flinches without a launch | — | backflip 3 m, 18 f, invulnerable | — | — | — | 50 % chance |
| Death Grip | crippled | 48 f red | 12 f lunge 3 m | — | 30 | CAP(0→1.2, r 0.6) | §4.4 |

**AI states.**
- `SPAWN` (drop-in) → `APPROACH`: run to a point on the 4.5 m ring around the player.
- `CIRCLE`: strafe tangentially at 2.2 m/s, keep 3.5–5.0 m, flip direction every 1.2–2.5 s, always face the player.
- `REQUEST_TOKEN` when the cooldown is ready. Got it → `ENGAGE`: run in to 2.0 m, taking at most 1.5 s, else give up the token → `ATTACK` (pick by distance and weights).
- `RECOVER` → 40 % `RETREAT` (backstep 1.5 m in 18 f) → `CIRCLE`.
- Reactions interrupt any state. After a reaction → `CIRCLE`.

### 5.2 NEEDLER — kunai thrower
**Look.** 1.70 m, slim (widths ×0.85). Dark indigo hooded suit, a single glowing cyan lens eye, two kunai bandoliers crossed on the chest, and a short blade on the left forearm.
**Stats.** HP **45** · poise 5 · run 4.5 m/s · keeps **8–12 m** from the player.

| Move | Trigger | Windup | Active | Recovery | Dmg | Details |
|---|---|---|---|---|---|---|
| Kunai Fan | ranged token, 6–14 m, line of sight | 30 f (right arm back, a cyan glint on the hand at f20) | release at f30 | 30 f | 8 each | 3 kunai at −10°, 0°, +10° aimed at the player's position in 0.2 s (lead). Speed **22 m/s**, hit radius 0.25 m, life 1.2 s. Blockable and parryable. A player attack's active volume destroys kunai it touches (`:clang`). |
| Blast Kunai (**red**) | 30 % of throws | 48 f red | release at f48 | 36 f | 20 | Single kunai at 16 m/s. It sticks to the ground at the player's position when thrown, shows a red ground ring r 2.5, then detonates **0.9 s** after sticking: SPH r 2.5, knockdown. |
| Knife Swipe | player within 3 m | 18 f | 6 f | 30 f | 10 | ARC(1.8, 90°). Always followed by **Backflip**: 30 f, 5 m away from the player, invulnerable f0–f18. |

**AI.**
- `SPAWN` → `REPOSITION`: move to 10 m from the player, preferring points in the player's camera view (screen x within ±0.8).
- `HOLD`: strafe at 1.5 m/s. If the player is closer than 6 m → `RETREAT` at 4.5 m/s to 10 m (stays 1 m inside the arena walls). If cornered, → Knife Swipe.
- `THROW` when the ranged token and cooldown are ready.

### 5.3 OXHEAD — heavy brute
**Look.** **2.6 m**, 1.3 m shoulder width. Hunched, with a massive chest box (1.2 × 0.9 × 0.7 m), small head with long pale ox horns (0.5 m each, angled forward). Dark iron-brown hide and armour with red war-paint stripes. Carries a two-handed iron maul: handle 1.6 m, head 0.6 × 0.45 × 0.45 m. The maul head gets a glowing red core during red moves.
**Stats.** HP **220** · **poise 60** (super armor versus lights) · walk 2.8 m/s · turn 180°/s (slow, so you can flank him) · cripple at 25 %. Immune to grab (Thunderfall becomes Plunge-like damage: 30).

| Move | Trigger | Windup | Active | Recovery | Dmg | Hit volume | Notes |
|---|---|---|---|---|---|---|---|
| Maul Swing | ≤ 3.2 m | 42 f | 12 f | 54 f | 22 | ARC(3.2, 140°, 0–2.6) | stagger, 2 m. Blockable. |
| **Crushing Slam (red)** | ≤ 4 m | **54 f** red, maul raised overhead | 9 f | **84 f** (big punish window) | 35 | SPH(fwd 2.0, up 0, r 3.5) | knockdown. `:brute-slam`, big shake. |
| **Bull Charge (red)** | 5–14 m | 48 f red (paws the ground) | up to 1.2 s at 10 m/s (12 m) | 48 f; **90 f stunned** if it hits a prop or wall | 30 | CAP(fwd 0→1.0, up 1.2, r 0.9) moving | knockdown. Charge is straight-line (no homing after f48). |
| Stomp | player within 1.8 m (or behind him) for > 1.0 s | 24 f | 6 f | 30 f | 10 | SPH(0, 0, r 2.2) | pushes the player 3 m. Blockable. |
| Rampage (crippled) | crippled | — | — | — | — | — | Maul arm lost. Chains red Bull Charges (cooldown 1.0 s) until obliterated or killed. |

**AI.**
- `APPROACH`: walks straight in, no circling.
- In range with the token → `ATTACK`. Weights: Swing 50, Slam 50 at ≤ 3.2 m. Charge at > 5 m.
- After 2 attacks → `TAUNT` (roar pose, 1.0 s, open for a beating).

### 5.4 ENRA, THE CRIMSON GENERAL — boss (2 phases)
**Look.** **2.4 m**. Crimson lacquered ō-yoroi with gold trim, a horned kabuto (two 0.45 m horns swept back), a black face mask with glowing amber eyes, and a tattered dark-crimson cape (three hanging plates, 1.2 m). Carries a **2.0 m ōdachi** that gets a red edge glow in phase 2. Wide shoulder guards (0.8 m total width) give a triangular silhouette.
**Stats.** HP **1400** · poise 90 · walk 3.5 m/s · dash-step 6 m in 15 f · turn 540°/s · immune to grab/crippling (Thunderfall = 30 dmg plunge) · ignores tokens.

**Phase 1 (100 %→50 %)**
| Move | Trigger (dist) | Windup | Active | Recovery | Dmg | Hit volume | Notes |
|---|---|---|---|---|---|---|---|
| Iai Dash | 5–12 m | 30 f (crouched, hand on hilt) | 12 f: dashes 8 m and slashes along the path | 48 f | 22 | CAP(path, up 1.2, r 1.0) | stagger. Blockable, parryable. |
| Triple Cut | ≤ 3 m | 27 f | hits at f27, f48, f69 (4 f each) | 60 f | 16 / 16 / 24 | ARC(3.0, 120°, 0–2.4) ×3 | 3rd hit knockdown. Parrying any hit stops the chain. |
| **Crimson Crescent (red)** | player ≤ 3.5 m for > 1.5 s | **48 f** red | 8 f spin | 72 f | 38 | ARC(4.0, 360°, 0–2.0) + red ring r 4.0 | knockdown |
| Guard / Counter-shove | idle, facing player, light attacks incoming | instant | — | — | 18 (counter) | ARC(2.2, 90°) | Blocks 60 % of light strings (HW hits stagger his guard 30 f, Raven hits break it). After **3 blocked hits** he immediately does a 15 f windup shove-slash (blockable, parryable). |
| Blade Wave | > 8 m | 36 f | projectile | 36 f | 20 | Crescent projectile 3.0 m wide × 1.0 m tall, 18 m/s, life 1.5 s | Blockable. Destroyed by Crimson Lance. |

**Transition at 50 %.** Hard cut: HP clamps at 700 and he is invulnerable for 2.0 s. Kneel (0.4 s) → **roar** (`:boss-roar`, shake 1.0 s): a shockwave pushes the player out to 6 m (no damage). Armour cracks glow **#FF1E3C**, a red aura of particles starts, the blade edge glows. The world runs at 0.3× slow-mo for 1.0 s. Rain density ×1.5. Music switches to the boss phase-2 layer.

**Phase 2 (50 %→0 %)**
- All windups ×0.85, walk 4.2 m/s, cooldown 0.5–1.0 s. Red telegraph minimum 42 f (0.7 s).
- He keeps the phase-1 moves. Iai Dash becomes **Iai ×2** (a second dash chains after 20 f, re-aimed).
- New: **Bloodrain Leap (red)** at 6–15 m. 54 f red crouch → leaps to the player's position *at the end of windup* (0.8 s arc, a red ground ring r 3.0 marks the landing) → lands with SPH r 3.0, **40 dmg**, knockdown → 60 f recovery.
- New: **Summon** once at 35 % HP. 1.0 s point gesture; 2 RAINBLADEs drop in at (−8, −15) and (8, −15).

**Boss AI.**
- `STALK`: walks toward the player in guard stance, stops at 3.5 m. Every 0.8–1.4 s picks a move by distance (weights: ≤ 3 m: Triple 45 / Crescent 25 (if its condition is met) / shove-feint 10 / backstep 20; 3–8 m: Iai 60 / walk-in 40; > 8 m: Blade Wave 50 / Iai 50 / Leap (P2) 40).
- After any recovery, 30 % chance of a **backstep** (dash-step 4 m back).
- He never attacks during the player's getup-invuln.

**Defeat.** At 0 HP: kneels **BROKEN**, drops his sword, prompt shows. Obliterate cinematic 1.5 s. Camera orbits 90° to side-on at 3.5 m. Enemies run at 0.2× for 0.8 s. One diagonal cut, the boss's upper body parts separate, crimson burst of 150 particles, `:obliterate`, then 1.0 s real-time pause → Victory.

---

## 6. Encounter & level flow

### 6.1 Flow
`TITLE` → (Enter/Start) → `INTRO` (2.0 s: camera sweeps from the skyline to REN at (0, 0, 8) facing north, "RAVEN EDGE" letterbox) → `WAVE 1` → `WAVE 2` → `WAVE 3` → `BOSS INTRO` (3.0 s) → `BOSS` → `VICTORY` (3.0 s, REN flicks blood off the blade) → `RESULTS` → Title.

- **Wave clear.** When the last enemy dies: 0.3× slow-mo for 0.8 s, banner `WAVE CLEAR` (1.5 s). The player heals **+25 % max HP** and the checkpoint is saved (HP, gauge). Then the next wave banner (1.5 s) and spawn.
- **Before the boss:** full heal, and the gauge is set to at least 40.
- **Fail.** HP 0 → death slow-mo → `YOU HAVE FALLEN` with the options **RETRY WAVE** / **QUIT TO TITLE**. Retry restores the checkpoint with HP = max(checkpoint HP, 60 % max). Retrying clears the current wave's enemies and restarts it (the boss restarts from 100 %). The timer keeps running, and any retry caps the rank at A.

### 6.2 Arena (36 × 36 m rooftop, y = 0)
| Prop | Centre (x, z) | Size w(x) × h × d(z) | Collision | Notes |
|---|---|---|---|---|
| Parapet walls | edges at x = ±18, z = ±18 | 0.4 thick × 1.1 h | invisible walls at ±17.6 (4 m tall) | concrete #4A4E58, a thin top cap in lighter #5E6370 |
| AC unit A | (−11, −9) | 2.4 × 1.6 × 1.6 | box | fan disc r 0.6 on top, spinning 3 rev/s |
| AC unit B | (−7.5, −9) | 2.4 × 1.6 × 1.6 | box | |
| AC unit C | (11, 6) | 1.6 × 1.6 × 2.4 | box | |
| AC unit D | (11, 9.5) | 1.6 × 1.6 × 2.4 | box | |
| Water tank | (−12, 12) | 4 legs 0.2 × 1.8 at ±1.2; tank cyl r 1.7, y 1.8–4.4; cone roof h 0.6 | cylinder r 1.8 | rust #7A5A3E, amber lamp at (−12, 3, 10.2) |
| Stair housing | (12, −12) | 4.0 × 3.0 × 3.5 | box | dark door rect on the south face, amber light on top |
| Antenna mast | (15, 15) | cyl r 0.15, h 9 | cylinder r 0.3 | red beacon at the top, blinks 1 Hz |
| Helipad ring | (0, 0) | ring r 6.0, width 0.25, y = 0.005 | none | yellow #C9A227 |
| Puddles ×8 | (−4, 3), (5, −5), (−8, −2), (2, 11), (9, −1), (−3, −10), (7, 13), (−13, 5) | discs r 0.8–1.6, y = 0.003 | none | #2A3350, reflect neon tint |
| Neon billboard N | x −8…8 at z = −19.5 | 16 × 5 board, y 2.5–7.5, on 2 posts | none (outside) | magenta emissive frame + 3 horizontal glyph bars |
| Neon sign E | x = 19.3, z −1…1 | 9 tall (y 1–10) × 2 wide | none | cyan emissive, vertical glyph blocks, flickers (5 % chance per 0.1 s to dim 50 % for 0.1 s) |
| Skyline | ring radius 45–180 m | 70 boxes (seed 1337), footprint 8–25 m, tops −30…+70 m relative to the roof, base y = −60 | none | dark #0E1220–#1A2034 with emissive window strips (#FFD89A 40 %, #7FE9FF 30 %, #FF6AD5 30 %). 2 towers (height +110 m) at (−90, −140) and (120, −60) with red blinkers. |

Player spawn: **(0, 0, 8)**, facing north (−Z). The camera starts behind at +Z.

### 6.3 Waves
Enemies **drop in** from y = 6 at their spawn point (flip, 0.6 s, invulnerable) and start AI 0.3 s after landing. Maximum alive at once: **6** (the boss fight excluded).

| Wave | Initial spawn | Reinforcements (trigger: alive ≤ 2) | Total | Target duration |
|---|---|---|---|---|
| **1** — "THE RAIN LEGION" | 4 × RAINBLADE at (−6, −14), (6, −14), (−15, −2), (15, −2) | — | 4 | ~45 s |
| **2** — "NEEDLES IN THE DARK" | RAINBLADE at (−4, −15), (4, −15), (−15, 4). NEEDLER at (−14, −14), (14, −14). | RAINBLADE at (15, 5), (0, 15) | 7 | ~70 s |
| **3** — "THE OX WALKS" | OXHEAD at (0, −14) (lands with a harmless shockwave, shake 0.25). RAINBLADE at (−14, −6), (14, −6). NEEDLER at (0, 16). | RAINBLADE at (−10, 14), (10, 14). NEEDLER at (−15, 0). | 8 | ~90 s |
| **BOSS** — "ENRA, THE CRIMSON GENERAL" | ENRA drops from y = 20 to (0, −10). Intro: land 0.6 s → rise → roar 1.2 s → name banner. | 2 × RAINBLADE at 35 % HP (§5.4) | 1 + 2 | ~120 s |

### 6.4 Results & rank
Score = `kills×50 + maxCombo×20 + obliterations×100 + max(0, 600 − seconds)×10 − damageTaken×5`.

Ranks:
- **S ≥ 6000**
- **A ≥ 4500**
- **B ≥ 3000**
- **C** below that

Any retry caps the rank at A.

---

## 7. Feel & feedback

### 7.1 Slow-mo events (time scale on the gameplay sim; hitstop is separate, see §4.2)
| Event | Scale | Real duration | Applies to |
|---|---|---|---|
| Just Dodge | 0.3 | 0.5 s | enemies and projectiles only (player 1.0) |
| Parry | 0.5 | 0.2 s | all |
| Raven Burst | 0.4 | 0.25 s | all |
| Obliterate | 0.25 | 0.4 s | enemies only |
| Last kill of a wave | 0.3 | 0.8 s | all |
| Boss phase change | 0.3 | 1.0 s | all |
| Boss finisher | 0.2 | 0.8 s | all |
| Player death | 0.3 | 1.2 s | all |

Ease back to 1.0 over the last 0.1 s. When events overlap, the lowest scale wins.

### 7.2 Camera shake (random offset of camera position; 30 Hz noise, linear decay; always real-time)
| Event | Amplitude (m) | Duration (s) |
|---|---|---|
| Light hit | 0.03 | 0.10 |
| HW hit | 0.08 | 0.18 |
| Ender / Thunderfall / Plunge land | 0.20 | 0.35 |
| Brute slam / charge hit wall | 0.25 | 0.40 |
| Player hurt | 0.10 | 0.20 |
| Guard break | 0.12 | 0.25 |
| Raven Burst | 0.18 | 0.30 |
| Obliterate cut | 0.15 | 0.25 |
| Boss roar | 0.12 | 1.00 |
| Boss/brute landing | 0.20 | 0.30 |

Concurrent shakes: take the max amplitude. There is also a global multiplier knob (§12).

### 7.3 Flashes & screen effects
- **Hit flash.** The victim's vertex colours lerp **70 % to white** for 3 real frames, or for the hitstop duration if that is longer.
- **Player hurt.** Red screen-edge flash, alpha 0.35 → 0 over 0.2 s.
- **Red telegraph.** §4.5.
- **Raven Form.** Crimson vignette #5A0010 at 35 % alpha, radial falloff from 55 % of the screen radius. FOV punch 62° → 70° → 62° over 0.4 s on activation. The player's scarf and eye glow turn #FF1E3C. Black feather quads spawn around the player at 8/s.
- **Low HP (< 25 %).** Red vignette pulsing 1.1 Hz, alpha 0.15↔0.35.
- **Parry.** A white-cyan ring expands from the contact point, r 0 → 1.5 m over 0.15 s.
- **Just Dodge.** 3 after-image copies of the player rig in #9FC8FF at 40 % alpha, fading over 0.3 s. Slight desaturation (skip if costly).

### 7.4 Particles (budget ≤ 2000 live, rain separate)
| Event | Count | Colour | Speed | Life | Size |
|---|---|---|---|---|---|
| Light hit (flesh) | 10 | crimson mist #B3122E → #5A0010 | 3–5 m/s in a cone along the swing direction | 0.35 s | 0.06–0.12 |
| HW hit | 22 | same | 4–7 | 0.45 | 0.08–0.16 |
| Cripple (limb off) | 35 + limb debris | same | 5–8 | 0.6 | 0.1–0.2 |
| Obliterate | 60 (boss 150) | same + 10 dark chunks #3A0008 | 6–10 | 0.8 | 0.1–0.25 |
| Block / clang | 12 | #FFE08A sparks, stretched along velocity | 6–9 | 0.20 | 0.03 |
| Parry | 24 | #9FF6FF | 7–11 | 0.25 | 0.04 |
| Kunai hit / destroyed | 6 | #FFE08A | 4–6 | 0.15 | 0.03 |
| Ground shock (L5/H3/Plunge/slam) | 30 dust #6A7080 + ring | outward | 3–5 | 0.5 | 0.15 |
| Death dissolve | parts fly (see below) | — | — | — | — |
| Essence orb | 3–6 per kill: **gold #FFC23D** (raven +5) 60 %, **blue #3FA9FF** (HP +4) 40 %. Obliterate: 3 blue (HP +4 each) + 2 gold. | | Burst 2 m/s, then after 0.4 s home in at 12 m/s (magnet radius 8 m). Absorbed within 0.6 m. | 6 s | 0.14 glowing cube |

**Enemy death.** Each rigid part detaches with a random velocity (1–4 m/s, plus 3 m/s up) and a random angular velocity (±360°/s). Parts fall with gravity, bounce on the roof once (restitution 0.3), then shrink to 0 over 0.4 s after 2.0 s.

### 7.5 Sword trail
- **Shape.** A ribbon between the blade base (0.25 m from the grip) and the tip. Keep **10 samples at 60 Hz**. Emit only during active frames + 3 f.
- **Rendering.** Additive, alpha falls off linearly from newest to oldest.
- **Base colours.** Core #E8F4FF → tail #5B8CFF. HW moves draw the ribbon 1.3× wider (extend the base toward the grip).
- **Raven Form.** #FF1E3C → #5A0010.

### 7.6 Rain
- **Streaks.** 1500 streaks in a 30 × 20 × 30 m box that follows the camera. Fall speed 18 m/s. Wind (1.5, 0, 0.5) m/s. Length 0.5 m. Colour #9FB4D0 at 35 % alpha. Streaks wrap around the box.
- **Splashes.** 40/s tiny rings on the roof within 15 m, r 0 → 0.25 m over 0.25 s, alpha 0.3.
- **Boss phase 2.** Density ×1.5 and a crimson tint #D07080.

### 7.7 Camera
| Param | Value |
|---|---|
| Type | Third-person orbit around pivot = player pos + (0, 1.5, 0) |
| Distance | 5.5 m. Rises to 6.5 m when any enemy is ≤ 12 m. Boss fight: 7.0 m. |
| Pitch | default 15° looking down, clamp −10° … +55°. Yaw is free. |
| FOV | 62° vertical |
| Follow lag | pivot smoothing, exponential: k = 12/s horizontal, 8/s vertical. Jumps: vertical k = 4/s while airborne. |
| Auto-yaw | no camera input for 1.5 s while running → yaw eases behind the movement direction at ≤ 60°/s. It only does this if the movement is within 120° of camera forward. |
| Threat framing | no input for 1.0 s, and an enemy holding a token is outside screen x ±0.6 → yaw toward it at ≤ 90°/s |
| Collision | none. Clamp camera y ≥ 0.4. |
| Lock-on | Tab/F/R3 toggles the target nearest screen centre within 20 m. While locked: pivot = lerp(player, target, 0.35), yaw eases (k = 8/s) so that the player→target direction sits 10° right of centre, distance = clamp(5.5 + 0.4 × separation, 6, 9). If the target dies, retarget the nearest within 12 m, else unlock. A diamond reticle #FF2BD6 is drawn on the target. |
| Obliterate / Thunderfall | Obliterate: camera eases in 0.15 s to a side angle (90° off the attack direction, distance 3.5, height 1.2), holds, returns in 0.3 s. Thunderfall: pull back to distance 7.5 and raise pitch to 30°, then return. |

---

## 8. HUD & screens

Coordinates are fractions of the screen (x, y from the top-left; w, h). All text is uppercase in the bitmap font.

| Element | Rect / anchor | Details |
|---|---|---|
| Player HP | (0.03, 0.04, 0.30, 0.022) | Fill #E8E8E8. **Damage trail** #B3122E: holds for 0.5 s, then drains at 60 HP/s. Background #101018 at 70 %. Under 25 % the fill turns #FF4A4A and pulses. |
| Raven gauge | (0.03, 0.074, 0.24, 0.014) | Fill #FF1E3C. Tick at 40 %. Pulses when ≥ 40 %. A small diamond emblem sits left of the bar at x 0.012. `[E] RAVEN` appears at (0.28, 0.070), scale 1, when ≥ 40 and not active. |
| Guard meter | ring segment under the player's feet, world-space | Visible only while guarding and the meter is < 100. Orange #FF9A3C below 35. |
| Combo | right-aligned at (0.95, 0.30) | `37` at scale 5 + `HITS` at scale 2. Rating below at scale 2: ≥ 10 `GOOD` (#C8D0DA), ≥ 25 `GREAT` (#19E6FF), ≥ 50 `BRUTAL` (#FF2BD6), ≥ 80 `RAVEN` (#FF1E3C). Resets 2.5 s after the last hit, or when the player is damaged. The number punches in (scale 1.3 → 1.0 over 0.1 s) on each hit. |
| Enemy HP | world-space, 0.35 m above the head, 0.06 × 0.006 screen | Shown for 3 s after the enemy is damaged. Crippled enemies show the bar as #FF1E3C with a pulsing outline. |
| Boss bar | (0.20, 0.90, 0.60, 0.020) | Name above at (0.20, 0.87): `ENRA, THE CRIMSON GENERAL`. Tick at 50 %. Same damage trail as the player bar. |
| Wave banner | centre (0.5, 0.35) | `WAVE 1` at scale 6 + wave name at scale 2 below. Slides in from x+0.1 with alpha over 0.3 s, holds 1.2 s, out 0.3 s. `WAVE CLEAR` uses the same animation. |
| Prompt | world-space above the crippled target (+0.5 m) | `OBLITERATE [K]` (`[Y]` on gamepad), #FFFFFF with a #FF1E3C shadow, scale pulse 1.0↔1.15 at 4 Hz |
| Off-screen threat | screen edge | Red chevron pointing at the attacker (§4.6), 0.6 s |
| Timer | (0.95, 0.04) right-aligned, scale 1.5 | `03:12.4`, #C8D0DA |

**Screens**
- **TITLE.**
  - `RAVEN EDGE` centred at y 0.32, scale 8, #FFFFFF with a 2 px #FF1E3C offset shadow.
  - Subtitle `A RAIN-SOAKED BLADE` at y 0.42, scale 2, #9FB4D0.
  - Menu at y 0.58 / 0.64: `START`, `CONTROLS`. The selected item gets `>` markers and #FF2BD6.
  - Footer at y 0.92, scale 1: `CLICK TO CAPTURE MOUSE   J/LMB LIGHT  K/RMB HEAVY  SPACE JUMP  SHIFT DODGE  Q GUARD  E RAVEN`.
  - Background: slow camera orbit of the arena with rain.
- **CONTROLS.** A two-column list of §2, then `ESC BACK`.
- **PAUSE.** Dim 60 %. `PAUSED` at scale 5. Menu: `RESUME` / `RETRY WAVE` / `CONTROLS` / `QUIT TO TITLE`. The sim is frozen and the rain keeps falling.
- **GAME OVER.** `YOU HAVE FALLEN` at scale 5, #B3122E. Then `RETRY WAVE` / `QUIT TO TITLE`.
- **RESULTS.**
  - `MISSION COMPLETE` at the top.
  - Rows animate in one by one every 0.25 s (with `:ui-move`): `TIME 06:41.2`, `KILLS 22`, `MAX COMBO 64`, `OBLITERATIONS 11`, `DAMAGE TAKEN 143`, `RETRIES 0`, `SCORE 5320`.
  - Then a big rank letter at (0.75, 0.5), scale 16: S #FFC23D, A #FF2BD6, B #19E6FF, C #9FB4D0. It punches in with a shake.
  - `ENTER - TITLE`.

---

## 9. Art direction

### 9.1 Palette
| Use | Hex |
|---|---|
| Sky zenith / horizon glow | #070A14 / #2A1F3F |
| Fog (linear, start 25 m, end 140 m) | #1A1E30 |
| Roof concrete (wet) / parapet / cap | #3A3F4A / #4A4E58 / #5E6370 |
| Puddle | #2A3350 |
| AC units / fan | #6B7078 / #2A2D33 |
| Water tank rust | #7A5A3E |
| Skyline buildings | #0E1220 … #1A2034 |
| Neon magenta / cyan / amber / beacon red | #FF2BD6 / #19E6FF / #FF9A3C / #FF2A2A |
| Window lights | #FFD89A, #7FE9FF, #FF6AD5 |
| **Player** suit / armour plates / steel bracers | #15171D / #3C4250 / #A9B4C2 |
| Player scarf / visor glow | #C0142B / #7FF3FF |
| Katana blade / tsuba / hilt | #DDE6F0 / #C9A24A / #2A1A12 |
| **Rainblade** armour / under / mask / eyes / sword | #4A5140 / #23262E / #D8D2C4 / #FF3030 / #9AA3AD |
| **Needler** suit / lens / kunai | #262B4A / #19E6FF / #C8D0DA |
| **Oxhead** hide / armour / horns / paint / maul | #3A2A26 / #4A4440 / #E6DCC8 / #C21A1A / #5A5F66 |
| **Enra** lacquer / gold trim / under / horns / eyes / cape / blade / P2 glow | #9E0F1C / #D4A437 / #120A0C / #F0E6D0 / #FFB02E / #3A0A10 / #E8E0E0 / #FF1E3C |
| Blood mist / dark blood | #B3122E / #5A0010 |
| Essence gold / blue | #FFC23D / #3FA9FF |
| Red telegraph | #FF1A1A |
| Parry / just-dodge | #9FF6FF / #9FC8FF |
| Sparks | #FFE08A |
| UI text / dim | #FFFFFF / #9FB4D0 |

### 9.2 Lighting (flat-shaded, per-vertex colour × light)
- **Moon (directional).** Direction (−0.4, −1.0, −0.3), normalised. Colour #7F93C9, intensity 0.55.
- **Hemisphere ambient.** Sky #1B2440, ground #0B0B12, intensity 0.6.
- **Point lights** (max 4, quadratic falloff to 0 at the given radius):
  1. Magenta billboard: (0, 4, −17), #FF2BD6, r 14, intensity 1.2.
  2. Cyan sign: (17.5, 5, 0), #19E6FF, r 12, intensity 1.0. Flickers with the sign.
  3. Amber tank lamp: (−12, 3, 10.2), #FF9A3C, r 8, intensity 0.8.
  4. Red beacon: (15, 9, 15), #FF2A2A, r 10, intensity 0 ↔ 0.9 (1 Hz square wave).
- **Emissive materials** (neon, windows, eyes, raven blade) skip lighting: colour × 1.0.
- **Rim hint** (cheap, optional). Add 0.15 × (1 − N·V)² × #9FB4D0 on characters so silhouettes read against the dark roof.

### 9.3 Proportions (standing height)
| Character | Height | Rig scale | Width multiplier | Notes |
|---|---|---|---|---|
| REN | 1.80 m | 1.00 | 1.00 | lean, long scarf: 2 trailing boxes 0.5 m, lag-follow the chest |
| RAINBLADE | 1.78 m | 0.99 | 1.10 | broad shoulder plates |
| NEEDLER | 1.70 m | 0.94 | 0.85 | hood |
| OXHEAD | 2.60 m | 1.44 | 1.45 (chest 1.8) | hunched: spine flex +20 in all poses |
| ENRA | 2.40 m | 1.33 | 1.20 | shoulder guards 0.8 m total |

---

## 10. Audio cue map
| Key | Triggered by |
|---|---|
| `:slash-light` | Start of the active frames of L1–L4, AL1–3, RL1–4, Riposte (pitch +10 % per string step) |
| `:slash-heavy` | Start of the active frames of L5, H1–H3, launcher, sweep, flurry final, Gale Thrust, Kestrel, Crimson Lance, Mirage Counter |
| `:hit-flesh` | Any player hit on an enemy (light/air). Enemy hit on the player (light). |
| `:hit-heavy` | HW hit connects; Thunderfall impact; enemy heavy/red hit on the player |
| `:clang` | Any block (player or enemy), kunai destroyed by a slash, guard break (2× volume), armored hit on the brute |
| `:parry` | Parry success, Raven Break |
| `:dodge` | Dodge start (just dodge: same key, pitch +30 %) |
| `:jump` | Jump, Chase Jump, enemy backflip |
| `:land` | Landing after > 0.3 s airborne; enemy drop-in landing; Plunge landing (with `:hit-heavy`) |
| `:footstep` | Player run cadence (0.25 s); brute steps (pitch −40 %) |
| `:kunai-throw` | Each kunai release (fan: once) |
| `:kunai-hit` | Kunai hits the player or the ground; blast kunai sticks |
| `:enemy-death` | Any enemy death (not Obliterate) |
| `:obliterate` | Obliterate cut frame (f15); boss finisher cut |
| `:raven-burst` | Raven Burst activation; Raven Form ends (pitch −30 %, half volume) |
| `:player-hurt` | Player takes damage |
| `:brute-slam` | Crushing Slam impact; Bull Charge hitting a wall; blast-kunai detonation |
| `:warn` | Start of any red windup; off-screen attacker (§4.6) |
| `:boss-roar` | Boss intro roar, phase-2 roar |
| `:ui-move` | Menu cursor move; result rows appearing |
| `:ui-select` | Menu confirm; pause open/close |
| `:wave-start` | Wave banner appear (including the boss banner) |
| `:victory` | Victory state entered |
| `:game-over` | Game-over screen appears |
| Rain loop | Always on. Title 0.6 volume, gameplay 0.45, pause 0.3. Boss P2 ×1.3. |
| Music | Title: ambient pad. Waves: combat loop 150 BPM, drums enter at wave 2. Boss P1: 170 BPM loop. Boss P2: + lead layer. Victory: sting then silence. Duck music −6 dB for 0.3 s on `:obliterate`. |

---

## 11. Rig & animation

### 11.1 Humanoid rig (REN, 1.80 m). Other characters scale this rig (§9.3).
Rest pose: standing straight, arms hanging along the body, legs straight, facing fwd.
Joint positions are **offsets from the parent joint in rest pose** (right, up, fwd), in metres. Mirror for _L (right → −right).

| Joint | Parent | Offset (r, u, f) | Bone length / child dir | Part mesh (box w×h×d, centred along the bone unless noted) · colour |
|---|---|---|---|---|
| pelvis (root) | — | (0, **0.98**, 0) world | — | 0.34 × 0.18 × 0.22 · armour |
| spine | pelvis | (0, 0.08, 0) | 0.22 up | 0.30 × 0.22 × 0.19 · suit |
| chest | spine | (0, 0.22, 0) | 0.22 up | 0.42 × 0.26 × 0.24 · armour (+ scarf root) |
| neck | chest | (0, 0.20, 0) | 0.08 up | cyl r 0.06 h 0.08 · suit |
| head | neck | (0, 0.08, 0) | 0.24 up (top at 1.80) | 0.21 × 0.24 × 0.23 · suit; visor slit 0.16 × 0.03 at the front · glow |
| shoulder_R | chest | (0.20, 0.14, 0) | — (pivot) | pad 0.16 × 0.08 × 0.18 · steel |
| upper_arm_R | shoulder_R | (0.02, 0, 0) | 0.30 down | 0.10 × 0.30 × 0.10 · suit |
| lower_arm_R | upper_arm_R | (0, −0.30, 0) | 0.27 down | 0.09 × 0.27 × 0.09 · steel bracer |
| hand_R | lower_arm_R | (0, −0.27, 0) | 0.09 down | 0.08 × 0.09 × 0.08 · suit |
| weapon_R | hand_R | (0, −0.05, 0) | blade points **fwd** in rest (perpendicular to the forearm) | grip 0.25 back from the pivot · hilt; tsuba 0.08 × 0.02 × 0.08 at 0; blade 0.03 × 0.02 × 0.95 fwd from 0.02 (tip at **0.97**) · blade |
| thigh_R | pelvis | (0.10, −0.05, 0) | 0.44 down | 0.14 × 0.44 × 0.15 · suit |
| shin_R | thigh_R | (0, −0.44, 0) | 0.43 down | 0.11 × 0.43 × 0.12 · armour (greave) |
| foot_R | shin_R | (0, −0.43, 0) | ankle height 0.06; foot extends 0.20 fwd, 0.05 back | 0.10 × 0.07 × 0.25 · suit |
| scarf_1, scarf_2 | chest | (−0.05, 0.18, −0.12) | 0.25 each, trailing back | 0.14 × 0.02 × 0.25 · scarf. Procedural: lag behind chest velocity, spring k = 40, damping 8. |

Enemies use the same joints. Weapon swap: Rainblade sword 0.9 m; Needler has no weapon_R (kunai spawn at hand_R) and a forearm blade on lower_arm_L. Oxhead maul held two-handed: weapon on hand_R, and hand_L follows via a pose only, no IK. Enra ōdachi 2.0 m.

### 11.2 Rotation channels (per joint, degrees, in the parent's frame; applied twist → flex → side)
- **flex** (about the joint's right axis):
  - `+` = forward flexion: torso and neck bend forward, arms and thighs swing forward/up.
  - Elbow `+` folds the forearm up toward the shoulder. Knee `+` folds the shin back (knees only accept 0…150).
- **twist** (about the bone axis / vertical for torso): `+` = rotate toward the character's LEFT (CCW seen from above).
- **side** (about the fwd axis): `+` = abduct away from the body midline for limbs (mirrored for L/R). For the torso and head, `+` = lean to the character's left.
- **Root.** pelvis position offset (r, u, f) in metres, and pelvis yaw.
- **Blade elevation.** For quick authoring, the blade's pitch above horizontal ≈ `shoulder.flex + elbow.flex + hand.flex` (in the sagittal plane). *Hitboxes do not depend on animation*, so tune poses by eye.
- **Interpolation.** Keys interpolate with smoothstep by default. Keys marked `!` are **linear snaps**: use them for strike frames so blades whip. Joints not listed in a key hold the previous key's value. A clip's first key defaults to the **STANCE** pose unless stated.
- **Blending.** Cross-fade 4 f between clips. Attack clips start with no blend (snappy). Hit reactions blend 2 f.

### 11.3 Base poses
- **STANCE** (combat idle; also the base of all attacks)
  - Pelvis u −0.06, twist +15.
  - Spine flex 8. Chest twist −10. Head twist −5.
  - Arm R: shoulder flex 25, side 20. Elbow 50. Hand flex −45 (blade forward-up ~30°, pointing at the enemy's chest).
  - Arm L: shoulder flex 15, side 15. Elbow 40 (open hand, guarding).
  - Legs: thigh R flex −10, side 8. Thigh L flex 25, side 5. Knees R 25, L 30.
  - Breathing: chest flex +2 at 1 s, loop 2.0 s.
- **RUN** (loop 0.50 s; keys at 0, 0.125, 0.25, 0.375)
  - Spine flex 25 (forward lean). Arm R holds the blade trailing back (shoulder flex −30, side 25, elbow 20, hand flex 60, so the blade points backward-down). Arm L swings ±35 opposite to the legs.
  - Thighs: flex +50 / −35 alternating. Knees: 90 at passing, 15 at contact. Pelvis u −0.04 at contact, +0.03 at passing.
  - Footstep events at 0 and 0.25.

### 11.4 REN clip list (durations = frame data)
| Clip | Dur | Key poses (time s: changes vs STANCE) |
|---|---|---|
| idle | 2.0 loop | STANCE + breathing |
| run | 0.50 loop | RUN |
| jump_up | 0.34 | 0: knees 60, thighs 50, arms flex 40. 0.34: legs tucked, knees 90, thighs 70. |
| fall | loop | legs knees 30, thighs 20, arms side 45 |
| land | 0.07 | pelvis u −0.18, knees 70, spine flex 25 |
| dodge_roll | 0.35 | 0: crouch (pelvis u −0.3, spine flex 45). **Root pitch rotates 0→360° over 0.03–0.28 s** with thighs 110, knees 130, spine flex 70, head flex 40 (tucked ball). 0.35: STANCE. |
| air_dash | 0.25 | spine flex 30, arms side 60 back, legs trailing (thighs −20, knees 60) |
| guard | hold | Arm R: shoulder flex 75, side 10, twist +20, elbow 70, hand flex −60 (blade horizontal across the body at face height, tip to the left). Arm L: shoulder flex 70, elbow 90 (hand on the blade spine). Knees 40, pelvis u −0.1. |
| block_hit | 0.13 | 0: guard. 0.05!: spine flex −8, pelvis f −0.1. 0.13: guard. |
| guard_break | 1.0 | 0.05!: arms flung (shoulders side 70, flex 40), spine flex −20. 0.4: stumble, spine flex 30, knees 50. 1.0: STANCE. |
| parry | 0.25 | 0.03!: blade whips outward: arm R side 60, twist −40, hand flex 0. Chest twist +30. 0.25: STANCE. |
| riposte | 0.45 | 0: arm R flex 110, elbow 40 (blade above the right shoulder). 0.08!: diagonal down-left cut: chest twist +40, arm R flex 40, side −10, hand flex 10. 0.45: STANCE. |
| **L1** | 0.40 | 0: chest twist −40, arm R side 80, flex 20, elbow 20, hand flex 0 (blade horizontal, cocked right). 0.10!: chest twist +45, arm R side 10, flex 70, twist +40 (blade sweeps across). 0.17: follow-through, blade left, arm R flex 60, side −20. 0.40: STANCE. |
| **L2** | 0.40 | 0: L1 end pose. 0.10!: chest twist −45, arm R side 85, flex 40, twist −30 (backhand, blade to the right). 0.40: STANCE. |
| **L3** | 0.45 | 0: crouch (pelvis u −0.12), arm R flex −20, side 30 (blade low right, hand flex 40). 0.12!: rise, pelvis u 0. Arm R flex 150, side 20, hand flex −30 (blade up-left). Chest twist +25. 0.45: STANCE. |
| **L4** | 0.60 | 0: arm R side 85, flex 0 (blade out right). **0.13–0.30: root twist +720°** (two full spins), knees 35, arm R held out. 0.60: STANCE. |
| **L5** | 0.75 | 0: arm R flex 170, elbow 30, hand flex −20 (blade over head, pointing back). Arm L joins (flex 160). Spine flex −15. 0.20!: spine flex 45, arms flex 30, pelvis u −0.25, knees 70 (blade into the ground ahead). 0.45: hold. 0.75: STANCE. |
| **H1** | 0.70 | 0: chest twist −60, spine side −10, arm R side 90, flex 0, elbow 10; weight on the back leg (thigh R flex −25). 0.23!: chest twist +70, arm R flex 80, twist +50; step fwd (pelvis f +0.4). 0.33: hold. 0.70: STANCE. |
| **H2** | 0.70 | mirror of H1 (start at twist +60 with the blade left, end at twist −70) |
| **H3** | 1.00 | 0: small hop, pelvis u +0.25, arms flex 175 (two-handed overhead). 0.33!: slam, pelvis u −0.35, spine flex 55, arms flex 20, knees 90. 0.50: hold, blade in the ground. 1.00: STANCE. |
| rising_crow | 0.55 | 0: pelvis u −0.25, arm R flex −30, hand flex 60 (blade low back). 0.17!: arm R flex 170, spine flex −20, pelvis u +0.1, hand flex −40 (vertical upward cut). 0.55: STANCE. |
| crescent_sweep | 0.70 | 0: crouch, pelvis u −0.35, arm R side 90, flex 10. **0.20–0.33: root twist +360°**, spine flex 20. 0.70: STANCE. |
| raven_rain | 1.03 | 0.13–0.63: alternate every 0.083 s between "arm R flex 90, side 60, twist −40" and "arm R flex 90, side −10, twist +40" (flurry). Chest twist ±20 in sync. 0.63: wind-up, arm R flex 170. 0.65!: down cut, arm R flex 30. 1.03: STANCE. |
| gale_thrust | 0.57 | 0: arm R flex 60, elbow 110, hand flex −60 (blade horizontal at the hip, pointing fwd), spine flex 20. 0.13!: arm R flex 90, elbow 0, hand flex −90 (full thrust), thigh L flex 60, pelvis u −0.15. 0.57: STANCE. |
| chase_jump | 0.40 | jump_up with arm R flex 150 (blade up) |
| air_L1/L2/L3 | 0.32 each | L1 / L2 / L3 upper-body keys, with legs tucked (thighs 60, knees 90) |
| thunderfall | 0.80 | 0: arms flex 100 (grab). 0.10–0.45: root twist +720°, body inverted: **root pitch 0→180°** by 0.45. 0.45–0.65: head-down dive. 0.65!: impact, root pitch 180 → 0 snap, crouch pelvis u −0.35, knees 90. 0.80: STANCE. |
| plunge | 0.10 / loop / 0.33 | start: arms flex 170 (blade overhead, pointing down via hand flex 90). loop: same, legs straight. land: kneel (knee R 120, thigh R flex −30, thigh L flex 90), blade in the ground. |
| kestrel | 0.10 / loop / 0.27 | start: spine flex 45, arm R side 90 back. loop: body horizontal (root pitch 70), arm R trailing. end!: arm R sweeps fwd (flex 90, twist +60), land crouch. |
| mirage_counter | 0.43 | 0: vanish (hide the rig for 6 f, spawn after-images). 0.10: appear, arm R flex 170. 0.15!: arm R flex 30, chest twist +30. 0.43: STANCE. |
| raven_burst | 0.37 | 0: crouch, arms crossed (shoulder flex 60, side −30, elbows 120). 0.10!: arms flung out (side 90, flex 20), spine flex −25, head flex −20. 0.37: STANCE. |
| crimson_lance | 0.67 | 0: arm R flex 50, elbow 120, blade pulled back (hand flex −60), chest twist −35. 0.20!: full thrust: arm R flex 90, elbow 0, chest twist +20, pelvis f +0.5. 0.67: STANCE. |
| obliterate | 0.75 | 0: dash lean (spine flex 30). 0.10: chest twist −70, arm R flex 170, elbow 20 (blade cocked high right). 0.25!: diagonal cut down-left, chest twist +60, arm R flex 20, side −30, pelvis u −0.3. 0.45: hold. 0.60: blade flick (hand flex +40 → −45). 0.75: STANCE. |
| hurt_flinch | 0.25 | 0.03!: spine flex −15, head flex −20, chest twist 10. 0.25: STANCE. |
| hurt_stagger | 0.50 | 0.05!: spine flex −25, arms side 40. 0.25: stumble back (pelvis f −0.4), knees 40. 0.50: STANCE. |
| knockdown | 0.35 / 0.5 / 0.4 | air: root pitch −70 (falling backward), arms flex 90. down: lying on the back (root pitch −90, pelvis u −0.85). getup: crouch → STANCE. |
| death | 1.2 | knees buckle (knees 90 by 0.4), spine flex 50, then root pitch +80 (fall forward) by 1.0 |
| victory | 1.2 | chiburui: 0.3!: arm R side 70 flick (hand flex +60 → −40), 0.8: sheathe-pose (arm R flex 10, blade down), head flex 10 |

### 11.5 Enemy clips
Shared humanoid clips (all enemies, scaled): idle 2.0 · walk 0.9 loop · run 0.6 loop · strafe_L / strafe_R 0.8 loop (sidesteps, thighs side ±20) · backstep 0.3 · flinch 0.30 · stagger 0.70 · knockdown air/down/getup · launched (root pitch −40, limbs loose) · crumple 1.0 (knees 120, spine flex 60, missing-arm side) · crawl 0.8 loop (prone, root pitch 80, left arm reaching flex 160) · drop_in 0.6 (root pitch 0→360 forward flip) · guard (weapon across the body) · guard_hit 0.13 · guard_break 0.8.

| Enemy | Clip | Dur | Key poses |
|---|---|---|---|
| Rainblade | slash | 1.17 | 0: arm R flex 150, side 30 (sword over the right shoulder). 0.30: glint. 0.45!: diagonal down, arm R flex 40, side −10, chest twist +35. 1.17: stance. |
| | double_slash | 1.55 | as slash, but the 1st strike is at 0.40!. 0.77!: backhand, chest twist −35, arm R side 80. 1.55: stance. |
| | lunge | 1.45 | 0: sword at the hip, pointing fwd (arm R flex 40, elbow 100, hand flex −50), spine flex 20. 0.50!: arm R flex 90, elbow 0, thigh L flex 70, pelvis u −0.2 (held during the dash). |
| | death_grip | 1.00 | crawl → 0.8!: lunge, left arm flex 170 reaching |
| Needler | throw_fan | 1.00 | 0: arm R flex −40, side 60, elbow 90 (cocked behind). 0.33: glint. 0.50!: arm R flex 110, side 20, elbow 0 (release), chest twist +40. |
| | throw_blast | 1.40 | as throw_fan, with the 0.80 s windup held, body glowing red |
| | swipe + backflip | 0.90 + 0.50 | swipe: left forearm blade, arm L side 70 → −10 at 0.30!. backflip: root pitch 0 → −360 over 0.45, pelvis arcs 1.2 m up |
| Oxhead | swing | 1.80 | 0: maul over the right shoulder (both arms flex 150, twist −40), chest twist −50. 0.70!: chest twist +60, arms flex 60. 1.80: stance. |
| | red_slam | 2.45 | 0–0.85: maul rises to vertical overhead (arms flex 180), spine flex −20, pelvis u +0.1, red glow. 0.90!: spine flex 60, arms flex 20, knees 70. 0.90–2.45: stuck, pull maul out. |
| | red_charge | 0.80 + loop + 0.80 | windup: head down (neck flex 50), right foot scrapes (thigh R flex −30 ↔ 10 ×3). loop: run with spine flex 45, horns first. stunned: sway, head flex 40, 1.5 s. |
| | stomp | 1.00 | 0.40!: thigh R flex 90 → 0 stomp, pelvis u −0.1 |
| Enra | iai_dash | 1.50 | 0: crouch, pelvis u −0.3, hand R on the hilt at the left hip (arm R flex 40, side −30, twist +60). 0.50!: dash and draw: arm R side 90, flex 40, twist −60, chest twist −50. 1.50: stance (ōdachi high guard). |
| | triple_cut | 2.22 | 0.45!: diagonal R→L. 0.80!: diagonal L→R. 1.15!: overhead vertical (arms flex 170 → 20). |
| | crimson_crescent | 2.13 | 0–0.80: coil, chest twist −90, blade trailing back low, red glow. 0.80–0.93: root twist +360°. 0.93–2.13: off-balance recovery (spine flex 30, blade tip on the ground). |
| | blade_wave | 1.20 | 0.60!: rising vertical cut releasing the projectile |
| | counter_shove | 0.60 | 0.25!: left palm shove (arm L flex 90, elbow 0) + short cut |
| | roar | 2.00 | kneel 0.4, rise, arms side 60, head flex −40, chest flex −20 |
| | bloodrain_leap | 0.90 + 0.80 + 1.00 | crouch deep (pelvis u −0.5), leap with the blade over the head, land with a downward stab (arms flex 10, knee R 120) |
| | broken | loop | kneeling on the right knee, sword dropped, head flex 40, left arm on the knee |

---

## 12. Tuning knobs & cut list

### 12.1 Tuning knobs (define as `defparameter` in the owning module)
| Knob | Default | Sensible range |
|---|---|---|
| `*player-max-hp*` | 200 | 150–300 |
| `*run-speed*` / `*accel*` | 7.5 / 60 | 6–9 / 40–90 |
| `*jump-vy*` / `*gravity*` | 9.5 / 28 | 8–11 / 22–34 |
| `*dodge-dist*` / `*dodge-iframes*` | 5.0 / f1–f16 | 4–6 / 10–20 f |
| `*just-dodge-window*` | 10 f | 6–14 |
| `*parry-window*` | 8 f | 5–12 |
| `*input-buffer*` | 12 f | 6–15 |
| `*guard-cost-mult*` / `*guard-regen*` | 2.5 / 30 per s | 1.5–4 / 15–50 |
| `*raven-threshold*` / `*raven-drain*` | 40 / 10 per s | 25–60 / 6–15 |
| `*raven-dmg-mult*` | 1.5 | 1.25–2.0 |
| `*cripple-frac*` | 0.30 | 0.2–0.4 |
| `*death-grip-delay*` | 3.0 s | 2–5 |
| `*melee-tokens*` / `*ranged-tokens*` | 2 / 1 | 1–3 / 1–2 |
| `*enemy-cooldown-mult*` | 1.0 | 0.6–1.5 (difficulty dial) |
| `*enemy-dmg-mult*` | 1.0 | 0.5–1.5 (difficulty dial) |
| `*red-windup-min*` | 48 f | 36–60 |
| `*hitstop-mult*` | 1.0 | 0–1.5 |
| `*shake-mult*` | 1.0 | 0–1.5 |
| `*softlock-range*` / `*softlock-angle*` | 7 m / 60° | 4–10 / 30–90 |
| `*magnet-light*` / `*magnet-heavy*` | 1.5 / 2.0 m | 0–3 |
| `*cam-dist*` / `*cam-fov*` | 5.5 / 62° | 4–8 / 55–75 |
| `*rain-count*` | 1500 | 0–3000 (perf) |
| `*boss-hp*` | 1400 | 900–2000 |
| enemy HP (grunt / thrower / brute) | 60 / 45 / 220 | ±40 % |

**Difficulty.** A single "NORMAL". If testers struggle, set `*enemy-dmg-mult*` to 0.7 and `*enemy-cooldown-mult*` to 1.3 (a Hero-like assist). Do not build a menu for it.

### 12.2 Cut list (drop from the top first)
1. Lock-on (soft-lock covers it). Keep the Tab key as a no-op.
2. Threat-framing auto-yaw. Keep only auto-yaw behind movement.
3. Just Dodge after-images and desaturation (keep the slow-mo and the Mirage Counter).
4. Boss Summon at 35 %, and Iai ×2 in phase 2.
5. Needler Blast Kunai (red). Then brute Stomp.
6. Raven Rain flurry ender. Use L4 → K = Crescent Sweep.
7. Air string reduced to AL1 only (keep Thunderfall and Kestrel, which are signature).
8. Riposte (parry still staggers, and you follow up with the normal string).
9. Scarf springs, AC fan spin, sign flicker, puddles.
10. Wave 3 reinforcements. Then wave 2 reinforcements.
11. Results rank formula: show stats only.

**Never cut:**
- Light string L1–L4 + launcher + Thunderfall.
- Heavy H1–H3.
- Guard + parry.
- Dodge with i-frames.
- Red telegraph + Raven Form + Raven Break.
- Cripple + Obliterate.
- Hitstop, sparks/mist, rain.
- The 3 enemy types + boss P1/P2.
- Title / Game Over / Results.

### 12.3 Out of scope (explicitly)
- Wall run.
- Ultimate-Technique-style charge attack. It is the first stretch goal if time is left: hold K 0.8 s → 360° triple spin, 80 dmg, i-frames.
- Ninpo / magic.
- Shuriken.
- Multiple weapons.
- Difficulty menu.
- Stealth.
- Save data.
