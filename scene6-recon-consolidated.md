# Scene 6 — Consolidated Build-Ready Recon

**Status:** Orchestrator consolidation of the scene-6 attract-fight recon arc, assembled
from the verdict record — **BUILD-COMPLETE** (the recon has reached its honest floor: every
layer from distance → collision → hit → referee → damage/health → win → sound is execution-
grounded; the remaining open items are C1 residual edges, sandbox visual gates, and
controlled-player-phase deferrals — none blocking a first scene-6 build). **This is the single
source of truth for building scene 6** — each finding is stated **once, current**, superseding
its earlier versions (the dead versions are in §9, the Superseded Ledger, so they are not
re-derived). Awaiting Clyde's repo-reconciliation pass (§11) as the verification layer.

**Provenance caveat (read first):** this is authored from Orchestrator **verdicts**, not a
fresh repo read. Findings here are *the record, organized* — where a finding was
Orchestrator-verdicted, this consolidation reflects that verdict, it does not
independently re-verify it. **Clyde's repo-reconciliation pass (separate dispatch) is the
verification layer** — addresses/labels below must be ground-truthed against the live
`scene6-recon.md` + code before the build leans on them. Confidence tags: **[C]**
execution-confirmed in a verdict · **[I]** inferred (honestly open) · **[J]** pending
Jay's visual gate.

**Scope:** scene 6 = the attract "one fight" demo: player climbs cliff → walks/scrolls
right → guard enters from right → fight (LCG-stochastic, player wins) → victory → loop
back to Brøderbund title. Timeline (seed-deterministic): climb f6019–6105 → walk/scroll
f6110–6484 → guard enters f6484 → strike exchange f7246–8145 → winning-blow f8141 →
guard-fall + victory hold f8371 → run-off → last draw f9148 → loop-back f9443.

---

## 1. Cast (sprites) — [C] unless marked

All combat cels are **shared** between combatants; the discriminator is the **head
norm-half** + the **draw entry** (facing), NOT the body-cel shape.

- **Player climb:** chain `$A3C5–$A649` (single-frame 2-part poses; translates up Y158→120),
  inside the `$A400` bank. Climb cels observed: `$A3C5 $A3E9 $A40B $A425 $A45A $A4A4 $A4D2
  $A4F2 $A548 $A572 $A5CC $A5DC`.
- **Player walk/run body:** `$9B00–$9EB7` + `$83xx` tiles; head-pair `$8EC1` + `$8E9B`.
- **Guard:** reuses the **player-run body** cels + a **distinct head `$8ECB`**. Guard draws
  via **draw-B** (`$190C`, h-mirror) — faces left. *(Supersedes the scene-5 cast-map's
  `$899C`/`$8ACB` = guard-body attribution — see §9.)*
- **Head discriminator:** `$8E9B` = player norm-half · `$8ECB` = guard norm-half.
- **Combat cels (provisional move names — Jay names in sandbox):** player high-punch
  `$8654`/`$8714`; guard punch/kick `$876B` / `$804D`+`$821E`; player victory `$891B`;
  winning-blow `$8244`; guard-fall `$8D0A` **[I]** (label "player_death" is a HYP — cel reuse,
  no death in the demo).
- **Action space:** **110 cels, SATURATED** (15-run seed-sweep plateau). **106 reachable**
  (normal player-win fight) + **4 unreachable-under-win-weighting** (the entire losing
  outcome: player-lose `$8EA5`/`$8EB3`, guard-win `$8000`/`$9043` — reachable only by forcing
  the prob-table row).
- **Health arrows:** cel `$0B12` **[C]**, drawn player-LEFT bottom-row; guard-side = same cel MIRRORED via draw-B `$1909` at X=`$26` RIGHT (`$0B7C`) **[C]**. Cel bitmap ID + **palette group (blue/orange, not-monochrome) Jay-confirmed [C, gate 2026-07-12: "look correct"]**. **NOT resolved by this gate: the arrow's on-screen COLUMN PARITY — subject to the known color-swap converter defect** (blind column-origin bug; see `docs/project/known-issues.md`).

---

## 2. Draw model — [C]

- **2×2 model:** facing (draw-A / draw-B) × tile (base / Y-offset).
  - draw-A `$1903` (normal) · draw-A `$1906` (Y-offset, lower tile)
  - draw-B `$1909` (h-mirror) · draw-B `$190C` (Y-offset mirror)
- **Facing lives in the draw ENTRY, not a flip bit** — draw-B mirrors via `$10 = 7 − $10`.
  A `$1903`-only renderer **truncates the lower band** (the `$1906`/`$190C` Y-offset draws
  the "second tile below").
- **X = `$05·7 + $10`**, Y = `$06`, flip = `$0F`.
- **Cel-identity ≠ actor-identity** (shared cels; discriminate by head norm-half + entry).

---

## 3. Background — [C]

Three layers:
1. **Fixed backdrop** — Mt-Fuji 4-sprite stack: `$A948` (peak, Y81) → `$A976` → `$A9B8` →
   `$A9E2` (base, Y108) + `$0A00` sky fill. **NOT draw-once** — the lower Fuji is
   **repair-blitted** where the scrolling floor `$AA11` overpaints it (peak un-occluded,
   drawn 2×; X-scoped overpaint peak=0 / base=94). 4th-sprite vertical gap = real gap filled
   on-screen by floor tile `$AA11`.
2. **Scrolling midground** — `$A684`-bank (24 tiles, span ≈ 88).
3. **Actors** — the combatants (§1).

- **Bottom seam** deferred to sandbox **[J]**.

---

## 4. Action selection — [C]

The fight is **LCG-stochastic, seed-deterministic** (variance is seed variance, not
non-determinism):
```
LCG  $59 = $59×5 + $13
  → fight_ai_a000 ($A000)
  → 4-tier prob-tables $A087/$A08C/$A091/$A096, indexed by state $33 (= distance, see §6)
  → action $29
  → $6540 dispatch (6-way, $2F-gated)
  → handler → sets/reads anim-frame $20
  → L6811 (action-indexed draw) → $1903-family blit
```
- **`$6540` dispatch** [C, execution-confirmed]: 6 codes `$9B/$C5/$D7/$D1/$C6/$C2` →
  handlers `$65F4-$6717`. **Observed executing** (branch-taken trace), targets match the
  static map. **`$C2→$66FE` is `$2F`-gated** — unreachable while `$2F`==0 (every natural
  fire); it's the win-suppressed path, not a flat 7th compare.
- **`$6540` is real executing code in `gameplay_6000.s`** (not un-disassembled — the stale
  `fight_engine.s` "attribution blocked" note was wrong).

---

## 5. Timing — [C]

**Event-driven — there is NO timing table** (this superseded the "look up the dwell"
premise; see §9):
- `$20` (anim-frame) **advances 1 frame per `$6540` dispatch tick**.
- A pose **holds for as many VBLs as the AI keeps re-selecting that action** — VBLs-per-pose
  is **emergent**, not stored.
- **Per-tick advance rate: seed-INVARIANT.** **Absolute VBLs-per-pose: seed-VARIABLE** (holds
  as long as re-selected).
- **`$20` is written by the `$7000` state machine (`$7081`/`$709D`) + `$6400` prep
  (`$645B`/`$6493`) — NOT the `$6540` handlers** (the handlers *consume* `$20`). *(Supersedes
  "each handler sets `$20`" — see §9.)*
- Measured dwells (means, VBL): intro climb ~17/step (6 steps); walk-in `$8E9B` 22.6; victory
  `$8E9B` 15.5, victory cels `$8F0E`/`$8E83`/`$8DA9` ~18, `$9290` ~9. (Phase-boundary gaps —
  walk-in max 311, victory max 136 — are transitions, not single-pose dwells.)
- **Port consequence:** reproduce the **rule** (advance `$20` 1 frame/dispatch-tick, hold
  while the action persists), **NOT** a stored per-pose dwell table — a fixed-dwell port
  desyncs from the AI.

---

## 6. Fight mechanics — [C] unless marked

- **Distance `$33` = `$72 − $62`** [C] (combatant-B position `$72` minus active-combatant
  position `$62`; `$22` = active-combatant position context; `$4A` = a distance threshold used
  only on the `$2F`≠0 branch). The range gate is a **computed delta**, not a single "distance
  byte."
- **Range gate:** `$33 ≥ $0C` ⇒ idle (out of range); index clamps ≥7 for the table. Weighting,
  not a hard cutoff.
- **The `$7000` "state machine" is a STATELESS per-tick decision function** [C] — recomputed
  each `fight_ai` call from live inputs (`$33` distance, `$2F`/`$5E` gates, `$70` opponent-
  frame, LCG), NOT a stored FSM. A clean 1:1 transition table is **not extractable** (multi-
  input + LCG interact); the branch table is dispositioned but has an **[I] residual** (C1 —
  see §8).
- **Hit→react causality: REFEREE-MEDIATED** [C]. A landed hit carries a per-combatant **event
  code `$40` (player) / `$41` (guard)**. The referee `$B584` each cycle computes each
  combatant's event **from its own state** (`$41`←`$70`, `$40`←`$60`, symmetric, via `$7366`);
  `combat_round_manager` (`$7207`) applies **three effects sharing the one trigger**: react
  (`trigger_action`), damage (`$0B09`/`$0B0C`), regen-reset (`$5B`/`$5C`→0). **NOT a direct
  attacker→victim write** (that framing superseded — §9) and **NOT independent actors**
  (causally linked via the referee).
- **Collision → hit-state: a clean RANGE/REACH test** [C]. `hit_detection_7366` compares an
  attack's **reach** (indexed by action class, `$32`) to the **distance** `$33` — a strike
  connects when reach ≈ distance → writes the hit-state → event `$40`/`$41`. **Clean range
  model, not a per-cel pixel tangle.** The full chain: `$33` → `hit_detection_7366` → event
  `$40`/`$41` → referee `$B584` → manager `$7207` → damage/react/regen → counts `$B6`/`$B7`.
- **Collision is NEUTRAL — the guard DOES land hits on the player** [C] (`$B6` 13→8 in the
  demo). The player is hittable; the win is **not** rigged at collision.
- **Always-wins = DOWNSTREAM + MULTI-LAYER** [C], pinned to a single authored input:
  - **PRIMARY = a damage-race effectiveness bias from AUTHORED start geometry.** The player's
    combatant starts **close/left-cornered** (`$62`≈`$0F`), the guard **far-right** (`$72`=`$30`,
    advancing to distance 7). The player's close-range attacks (`$D7`) connect **~2×** more than
    the guard's mid-range (`$C5`) from the farther position → the player wins the damage race
    (guard `$B7` 13→2 vs player `$B6` 13→8).
  - **The engine is otherwise SYMMETRIC/EMERGENT** [C]: movement AI is **one shared routine**
    (`check_position_a`/`_b` structurally identical, parameterized by combatant — no role
    branch); action weighting is **one shared distance-indexed table** (`ldx $33`, **not**
    combatant-indexed). So the win **emerges** from the authored positions + the shared engine —
    there is **no** per-combatant AI or per-combatant weighting.
  - **SECONDARY = the `$2F` unreached-state gate** [C], a belt-and-suspenders safeguard: the
    guard-win line is the `$2F`≠0 branch, `$2F` held at 0 (never entered naturally); forcing
    `$2F`=1 opens it (`$9B` appears, `$C2→$66FE` executes) — but the damage race already prevents
    the guard win long before this gate matters.
  - **Port consequence:** reproduce **one** authored input (the start positions); implement
    movement + weighting as **one shared engine**; the win **emerges** — no per-combatant tuning.
  - **[I] open (→ Rider 2):** whether the authored start positions are *level-tuned* like the
    starting counts (a progression readout) — a Rider-2 question, not open here.

---

## 7. Health / vitality system — [C] unless marked

- **Two count bytes** [C]: `$B6` = player, `$B7` = guard (adjacent, **distinct — not one
  shared**). **Starting count = 14 for both (`$0E`; source `lda #$0E` — the earlier "13" was a post-first-hit read) — EQUAL, incl. in the demo.**
- **Whole subsystem** = one low-RAM routine `$0B0C` (jmptable `$0B00`), called per-frame from
  `$7292`.
- **Damage** [C]: `$0BC1` (player) / `$0BD2` (guard) — decrement the count on a hit, **floored
  at 0**, and **reset the regen timer**. Triggered by the event code `$40`/`$41` (§6).
- **Regeneration** [C, forced]: timers `$5B`/`$5C` increment per frame, **reset to 0 on every
  hit**, and at threshold (`$B8` player / `$B9` guard) **increment the count by ONE** (`$0C1E`).
  **Model = one-arrow-at-a-time on a repeating timer, reset-on-hit** (not refill-to-full).
  **Threshold `$B8`=`$B9`=`$FF` (255 VBL) → regen is OFF in the busy demo** (demo-tuned, like
  the win-weighting); forced `$B9`=04 → `$B7` oscillates (regen path executes).
- **Draw** [C]: `$0B35` loop draws exactly `$B6` arrows (`jsr $1903`, X += 3/arrow), player at
  `$05`=0 (LEFT), bottom row. **Redraw-N each refresh, count-driven** (not delta-blit).
- **Low-health blink** [I, from Jay]: arrows blink at low count (1–2) — threshold + cadence
  **not yet traced** (follow-up).
- **Starting-count SEAM = `$B0`/`$B1`** [C, Rider 2]: the working counts `$B6`/`$B7` are copied
  from **`$B0` (player) / `$B1` (guard)** (`routine_b73f`: `lda $b0; sta $b6` / `routine_b72e`:
  `lda $b1; sta $b7`) at scene-6 init — so `$B0`/`$B1` are the starting-count register pair, **the
  progression injection point** (where a real game's per-level table would write). In the attract
  they are set by a **hardcoded immediate `lda #$0E`** (`scene_dispatch.s:315-318`) → **F1 =
  CONSTANT** (14/14), not a table-index, not a formula; positions are likewise hardcoded in the
  same init block. **No shared runtime progression index in the demo.**
- **Progression sweep** [I, from Jay — deferred]: player-start decreases / guard-start increases
  over real-game levels — the seam is located (above), but the **sweep is DEFERRED to controlled-
  player** (the one-fight demo can't exercise the level-indexed load into `$B0`/`$B1`).

---

## 7a. Sound — [C] unless marked

Scene 6 is **voiced** (the attract-is-silent conclusion was refuted by operator ground truth —
§9). There are **TWO distinct sound mechanisms → TWO port hooks:**

**Mechanism 1 — record-engine TUNES** [C, PC-confirmed]: the `$1000` jumptable loads a
sound-record pointer (`$F7`/`$F8`) and routes through `handler_tail $101C` — `lda $4F; and $86;
beq skip; jmp $0D00` — voicing at `$0D00` iff `($4F AND $86)!=0` ("always-called, conditionally-
voiced"). → port hook **`HAL_sound_trigger(record_id)`** (the scene-5 R4 interface, now
PC-confirmed). Carries: intro/title music, the **cliff-top tune `$118C`**, the **victory yell
`$110B`**.

**Mechanism 2 — SPKR direct-toggle CLICKS** [C]: the `$C030` speaker-toggle dispatch (`$0C40` →
handlers `$0C55-$0CB0`, countdown-loop speaker toggles). → a **second port hook** (genuinely
different mechanism — **no CoCo3 1-bit-speaker analog; needs reimplementation** on the CoCo3
DAC/PIA). Carries: **hit** clicks (both combatants), **footstep** clicks.

**The four scene-6 sounds — placement table** (build inserts hooks from this):

| Sound | Hook / ID | Build landmark | Exact position |
|---|---|---|---|
| Hit-click | SPKR `$0C55`(player)/`$0C64`,`$0C74`(guard)/`$0C84`(common impact) | hit-resolution seq | **after `$93AB` marker, before the `$0BC1`/`$0BD2` decrement** (marker→sound→damage); both combatants |
| Footstep | SPKR `$0CB0` | locomotion cycle | **`$20`=24 foot-plant**; 0 in fight |
| Cliff-top tune | record `HAL_sound_trigger($118C)` | climb-completion | **~9 frames after** the last climb-cel (f6105→f6114) |
| Victory yell | record `HAL_sound_trigger($110B)` | victory pose | **mid-pose `$20`=06** (~f8416), not on entry |

- **Footstep run-vs-walk** [I → controlled-player]: the trace shows the footstep on **every**
  locomotion foot-plant incl. the walk-window, and found **no distinct walk gait** — but Jay
  recalls footsteps on **running only**. The attract likely exercises only one gait (the run/walk
  *choice* is a controlled-player distinction — the same run/walk scene-skip mechanic), so the
  trace **can't** resolve this. **Build-safe:** hook the foot-plant now; **defer the run-vs-walk
  conditionality** to controlled-player.
- **Fight-event coverage** [C]: the four above are Jay's complete recalled set (hit/run/cliff/
  victory) — no SPKR sweep for more needed.
- **Sound gate is BUILD-PHASE, not recon-phase** [deferred]: there is **no meaningful Jay
  audio-gate now** — a handler ID can't be matched to memory; the confirm-by-ear gate requires
  the CoCo3 sound engine playing it back, so it lives in the **sound-engine build phase**, not
  here. (This corrects the earlier phantom "PENDING JAY audio" — §9.)

## 8. Port-relevant summary (what the build reproduces)

- **One sprite/animation engine** (CoCo3-native port of the oracle's `$1903`-family), the 2×2
  draw model (facing = entry, Y-offset = lower tile). All animated scenes call it; the sandbox
  exercises the real engine.
- **Facing via draw entry** (draw-A/draw-B mirror), not a flip bit.
- **Event-driven timing** — advance `$20` 1 frame/dispatch-tick, hold while re-selected; **no
  dwell table**.
- **Referee-mediated hit resolution** — event code `$40`/`$41` → `combat_round_manager` applies
  react + damage-decrement + regen-reset; the referee computes each actor's event from its own
  state. **Collision** is a clean **range/reach test** (`hit_detection_7366`: reach-by-action-
  class vs distance `$33`) — the connect mechanic.
- **Always-wins via authored start geometry + emergent race** — reproduce the **authored start
  positions** (player close `$0F` / guard far `$30`→7); movement + weighting are **one shared
  engine** (no per-combatant AI/tables); the ~2:1 damage-race win **emerges**. The `$2F` gate is
  a secondary safeguard.
- **Sound = two hooks** — record-engine `HAL_sound_trigger(record_id)` (tunes: cliff `$118C`,
  victory `$110B`) + a SPKR-click hook (hit/footstep; **needs CoCo3 reimplementation**, no
  1-bit-speaker analog). Placement table in §7a; hooks placed **during the build** at the named
  landmarks (spec, not yet implemented).
- **Health** — two counts (`$B6`/`$B7`), decrement-floored-on-hit, regen one-at-a-time on a
  reset-on-hit timer (threshold a **tunable data value**), count-driven arrow redraw (cel
  `$0B12`, mirrored guard-side).
- **Progression injection point = `$B0`/`$B1`** — the starting-count register pair copied into
  `$B6`/`$B7` at init. **Constant (14/14) in a scene-6-only build** (`lda #$0E`); a full game's
  **per-level table** would write `$B0`/`$B1` (+ the start positions in the same init block). The
  level-table and the player-down/guard-up sweep are a **controlled-player addition**, not the demo.
- **Opaque-black already ships in HAL** (`HAL_gfx_blit_sprite_opaque` + `_masked`/`_stencil`
  from scene-5) — scene-6 mixed silhouettes use the existing `_masked` path with an authored
  per-cel mask (content-side, **NOT** a HAL refactor). *(Item struck — see §9.)*
- **Background = 3 layers** — fixed backdrop (repair-blitted), scrolling midground, actors.
- **Stock 128KB / 6809** — VBL is VBL (~60Hz both machines), so VBL budgets transfer.

---

## 9. SUPERSEDED LEDGER (dead findings — do NOT re-derive)

Each entry: the **dead** version → the **current** version (and where it lives above).

1. **"Each `$6540` handler sets/advances `$20`"** → **DEAD.** Handlers **consume** `$20`; it's
   written by `$7000` (`$7081`/`$709D`) + `$6400` prep (`$645B`/`$6493`). → §5.
2. **"`$6540` attribution is blocked / un-disassembled"** → **DEAD.** `$6540` is real executing
   code in `gameplay_6000.s`; the `fight_engine.s` note was stale. → §4.
3. **Timing = "a stored dwell table (fixed / per-move / state-dependent)"** → **DEAD.** No
   timing table; timing is event-driven (advance-per-tick × re-selection persistence). → §5.
4. **M2 causality = "attacker writes opponent state directly"** → **DEAD** (my over-specified
   framing, corrected twice). Also **NOT** "independent actors." → **Referee-mediated event
   system** (`$B584`/`$40`/`$41`/`$7366`). → §6.
5. **Always-wins = "a zero-weighted prob-table row"** → **DEAD.** It's an **unreached-state
   gate** (`$2F` held at 0). → §6.
6. **Scene-5 cast-map: `$899C`/`$8ACB` = guard-body** → **DEAD/superseded.** Guard reuses the
   player-run body; only the head `$8ECB` is guard-distinct. → §1.
7. **Guard-fall `$8D0A` = "player_death"** → **HELD AS HYP [I]**, not a confirmed label (cel
   reuse; no death in the demo). → §1.
8. **Fuji backdrop = "draw-once"** → **DEAD.** Repair-blitted where the scroll overpaints. → §3.
9. **Opaque-black = "a HAL refactor blocker"** → **STRUCK.** Already ships in HAL; content-side
   mask authoring only. → §8.
10. **Health regen = "absent in the demo"** → **REFINED.** Present but demo-tuned OFF
    (threshold `$FF`); forced-confirmed. → §7.
11. **Collision→hit-state feed = "[I], un-traced"** → **CLOSED.** It's a clean range/reach test
    (`hit_detection_7366`, reach vs `$33`), collision-neutral (guard lands hits). → §6.
12. **Always-wins = "unreached-state gate (`$2F`) alone"** → **REFINED to multi-layer.** `$2F` is
    the *secondary* safeguard; the *primary* rig is the **authored-start-geometry damage-race
    bias**, engine otherwise symmetric/emergent. (`$2F`-alone was the *first-found* gate, not the
    origin — HS-2 of the collision pass caught it.) → §6.
13. **Positional bias = "authored vs emergent, [I]"** → **RESOLVED: authored at ONE layer**
    (start geometry); movement + weighting symmetric/shared → win emerges. → §6.
14. **Scene-6 attract fight = "silent-by-no-trigger (F2)"** → **DEAD/REFUTED** (operator ground
    truth — Jay hears the sounds). The prior pass tapped only the `$1000` record engine; the
    fight sounds are on the **`$C030` SPKR click path** it missed. → §7a.
15. **"PENDING JAY audio-gate now"** → **CORRECTED.** No audio gate is possible pre-engine (a
    handler ID can't be ear-matched); the confirm-by-ear gate is **deferred to the sound-engine
    build phase**. → §7a.
16. **Sound = "one shared `HAL_sound_trigger` interface"** → **CORRECTED to TWO hooks** (record-
    engine tunes + SPKR clicks — distinct mechanisms). → §7a/§8.

---

## 10. GAP AUDIT (what's open going into the build)

### 10a. Inferred [I] — execution-open, may need closing before the port builds on them
- **C1 residual state-transition edges** — the stateless decision function's edges not force-
  reachable; **disposition each to {now-confirmed, deferred-to-controlled-player, confirmed-
  nonexistent}** (C1-closure dispatch, pending). Deferred-to-controlled-player is a valid
  close. (§6)
- **Low-health blink** threshold + cadence — not traced (follow-up, batches with guard-mirror).
  (§7)
- **Health guard-side arrow draw + mirror** — read-tap missed; re-run with bp. (§1/§7)
- *(The collision→hit-state feed is now CLOSED — §6/§9-11 — no longer [I].)*

### 10a-build. CoCo3 build tasks flagged by recon (not recon-open, but pre-flagged)
- **SPKR click path needs CoCo3 reimplementation** — hit/footstep clicks are Apple II 1-bit
  speaker toggles with **no CoCo3 analog**; produce equivalent sounds via the CoCo3 DAC/PIA
  behind the second sound hook. (§7a)
- **Sound hooks placed during the build** — the placement table (§7a) is the spec; the actual
  `HAL_sound_trigger` / SPKR-hook insertions happen when the scene-6 code is written, at the
  named landmarks/frames.

### 10b. Pending Jay's visual gate [J] — resolve in the sandbox
- Arrow cel `$0B12` — bitmap ID + palette group (blue/orange) **RESOLVED 2026-07-12** (Jay gate:
  "look correct"; §1). **On-screen column parity NOT resolved by this gate** — tracked under the
  color-swap converter defect (`known-issues.md`), not here.
- Move names (the 110-cel action space; combat poses) — provisional until sandbox.
- Feet-bands, climb Y-ascent, Fuji bottom seam (deferred to sandbox).
- Guard-mirror visual confirm.

### 10b-audio. Pending Jay's audio gate — deferred to the SOUND-ENGINE BUILD PHASE
- Confirm the located sounds (hit/footstep/cliff/victory) match Jay's ear — **only possible once
  the CoCo3 sound engine plays them back** (a handler ID can't be ear-matched at recon time).
  Not a recon-phase or first-build-phase gate. (§7a)

### 10c. Deferred to controlled-player phase (needs the input-playback harness)
- **Starting-count progression sweep** (player-down/guard-up over levels) — **seam LOCATED at
  `$B0`/`$B1`** (constant 14/14 in the demo, `lda #$0E`); the **sweep + the real-game level-table
  are deferred to controlled-player** (needs multi-fight input). §7/§8.
- **Start-position level-tuning** — whether the authored start positions (§6) are level-tuned
  like the counts (a Rider-2-adjacent question).
- **Run/walk scene-skip** (running loads fewer fight scenes) — a scene-sequencer branch reading
  a run/walk-derived value; differential input trace, first scene-index divergence.
- **Footstep run-vs-walk conditionality** — whether running adds footsteps walking lacks (the
  attract shows one gait; ties to the run/walk distinction above). Hook the foot-plant now, gate
  later. (§7a)
- **Fight-event sound record IDs** — the fight *tunes'* IDs beyond the four found are real-play/
  Jay; the four recalled sounds are covered (§7a). *(Superseded by the retrace — the four ARE
  found; this line is only for any beyond-the-four that real-play might add.)*
- **C1 edges** that only fire under player input.

### 10d. Tooling prerequisites for 10c
- **Reproducible player-input playback** (MAME recorded-input / `natkeyboard` scripting, or a
  state-force input harness) — gates the entire controlled-player phase.

---

## 11. Reconciliation checklist for Clyde (the verification layer)

This document is authored from the verdict record. Before the build leans on it, Clyde should
ground-truth against the live repo:
- Every **address/label** in §1–§7a vs `scene6-recon.md` + the code (flag any drift) — including
  the new §6 collision (`hit_detection_7366`, reach `$32` vs `$33`), the always-wins layers
  (`$62`/`$72` start positions, `check_position_a/_b`, `$2F`), and the §7a sound addresses
  (`$1000`/`$0D00`/`$101C` record path; `$C030`/`$0C40`/`$0C55-$0CB0` SPKR path; record IDs
  `$118C`/`$110B`; the placement-table frames).
- The **superseded ledger** (§9, now 16 entries) — confirm the *current* version is what's in the
  doc, the dead version is not lingering anywhere as fact (esp. the refuted "attract silent" and
  the corrected one-hook→two-hook sound spec).
- The **[I] items** (§10a) — confirm they're still open (not silently closed by a later pass).
- Fill any address-level specifics the verdict record left implicit (e.g. exact `$7366` inputs,
  the `$C030` handler→event correlations, the placement-table `$20` frames).
- Report per-section: matches / drifted / needs-address — additive corrections gate to Jay per
  the standing rules.
