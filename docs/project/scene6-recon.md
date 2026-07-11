# Scene-6 Oracle Recon — the attract fight-demo (motion-layer + cast spec)

**Execution-grounded recon.** Scene 6 (the CoCo port's next scene) = the Apple oracle's
**attract "one fight" demo** (intro-cycle scene 8: hero vs one guard, scripted, hero wins).
Scene 6 is **past the scene-4 oracle wall**, so the spine is: **the running game is authority;
the oracle `.s` labels are a HYPOTHESIS source** — used here only to *name* execution-localized
sources. Every entry is tagged `[CONFIRMED]` (execution-observed) or `[HYP]` (oracle
label / bank cross-ref, pending Jay's live-MAME adjudication). Identity/color/position is
**Jay's call** (HS-4); this doc LOCALIZES (source→object→frame) and hands Jay a targeted list.
**t0:** 2026-07-06T21:35:09. Read-only (oracle repo + prod `88eba89…` untouched; no
conversion into the port, no code/build). Trace tools (untracked in the oracle repo):
`tools/scene6_layer_separate.lua` (this pass — bank-classified draw-entry tap),
`tools/attract_scene6_trace.lua`, `tools/scene6_sprite_localize.lua` (prior passes).

> **CORRECTION (this pass, from Jay's live-MAME gate).** The prior recon mislabeled the
> **scrolling background** (`$A684`-bank tiles) as "the dominant MOVER / likely the hero,"
> and hypothesized the `$0B1x` cluster as a "second combatant." Both were the "moving =
> actor" trap: per-frame `$03/$04` sampling caught the *most-drawn* thing (the scroll) and
> mid-blit ZP noise, not the cast. **This pass classifies by sprite-BANK at the actual draw
> entry `L1903` ($1903)** — which separates the three real motion layers cleanly and finds
> the characters via their oracle labels. See "Superseded findings" at the end.

---

## The three motion layers `[CONFIRMED by bank-classified draw tap]`

Method: read-tap `L1903` ($1903, the video.s sprite-draw entry — the blit reads `$03/$04`
as the source, per the ZP-tap-vs-blit-entry note). Over the fight window (f6400-7400,
deterministic single run), every draw's source `$04·256+$03` is bucketed by bank. Draw
counts are per-window totals.

### Layer 1 — LOCKED SCROLL (player-driven background) `[CONFIRMED]`
The `$A400-$ACFF` bank, drawn **hundreds-to-thousands of times per window** — a tiled layer
redrawn every frame across the play width (the signature of a scrolling floor/scenery group,
NOT a single actor):

| source | frames | draws | oracle label `[HYP]` |
|--------|--------|------:|---|
| `$A684` | f6528-7392 | **2756** | `sprite_A684` (a400 bank, "unidentified") — dominant scroll tile |
| `$A68A` | f6519-7400 | 1113 | `sprite_A68A` |
| `$A703` | f6519-7384 | 988 | `sprite_A703` |
| `$A85F` | f6519-7168 | 280 | `sprite_A85F` |
| `$AB8E` | f6421-6573 | 252 | a400 floor pattern |
| `$AA11 / $AA23 / $AA31` | f6455-7166 | 216/86/84 | a400 floor patterns |

This is the layer Jay described as one **locked group** that stays still while the player
moves through a **dead-band**, then scrolls once he passes the margin. The lock/dead-band
*mechanism* is a Stage-2 (scroll-engine) concern — not built here — but the layer is now
correctly identified as the scroll, not the hero. (27 distinct scroll sources total.)

### Layer 2 — INDEPENDENT CHARACTERS (the real cast) `[CONFIRMED sources; identity HYP]`
Combatant figures in the `$8xxx/$9xxx` sprite banks, drawn a **handful of times each** (one
figure, not a tiled fill), reconciled to oracle labels (HS-4 — by structure, not draw-count):

> **JAY VISUAL GATE — AC-6 / 25.3 — 2026-07-08 `[CONFIRMED by Jay]`** (off the trace-driven
> preview sheet `build/scene6-cast-preview/`; overrides oracle labels per §2/§4). Decisive
> reclassification of the f6000-7400 window:
> - **All the parity-STABLE (non-crossing) candidates are PLAYER sprites** — parts of the
>   player multi-part composite that **need compositing** (legs + torso + shadow + body cels
>   assembled into one figure). This **SUPERSEDES** the oracle "`enemy_head_8E9B`" /
>   "`feet_shadow_8EC1`" labels and this doc's prior GUARD hypothesis for `$8E9B`/`$8EC1`:
>   they are player parts, not the guard. `$9A2A`/`$83A8`/`$90D7`/`$81BD` + the `player_run_*`
>   cluster are all player composite parts. (Jay: this window is **AFTER the climb phase** —
>   the climb is an EARLIER window that needs its own trace. **No enemy/guard has appeared yet**
>   in f6000-7400 — that is why none was found; the guard enters a LATER window. Both are
>   separate trace dispatches.)
> - **The three parity-CROSSERS `$942A`/`$93AB`/`$9A18` "look correct"** (the F1 flag was
>   right) — **except the last, `$9A18`, is likely part of the PLAYER DEATH composite** (a
>   player-death cel, not a standalone crosser). Its parity-crossing is consistent with being
>   a composite part drawn across positions.
> **Consequence:** the scene-6 near-term cast is a PLAYER multi-part composite; the next step is
> COMPOSITING the traced parts (per-part `$05·7+$10` column + `$06` Y-row give the relative
> registration), not more per-cel conversion. Guard localization = a later-window trace.


**PLAYER — run cycle `[HYP: oracle player_run_* labels]`** (early in the window, f6423-6613):
| source | frames | oracle label |
|--------|--------|---|
| `$9B00 $9B6B $9BE5 $9C1B $9CAF $9CD7` | f6423-6612 | `player_run_legs_*` (8-frame leg cycle, `$9B00-$9D1E`) |
| `$9D68 $9D97 $9DD5 $9E05` | f6438-6613 | `player_run_torso_*` (8-frame torso cycle, `$9D68-$9EB7`) |

The player is a **composite** (legs + torso drawn as separate cels), consistent with the
oracle bank map ("separate leg sprites composited with torso below"). Companion parts
`$83A8 $81BD $90D7` draw in lockstep with the later character cluster (f6733+).

**ENEMY / GUARD `[HYP: oracle enemy_head label]`** (present throughout, right side):
| source | frames | draws | oracle label |
|--------|--------|------:|---|
| `$8E9B` | f6424-7386 | 62 | `enemy_head_8E9B` — "enemy head/body variant" |
| `$8EC1` | f6424-7386 | 62 | `feet_shadow_8EC1` (the enemy's feet-shadow) |

The enemy head+shadow persist the entire window at the right (`$51≈$FE` at first sighting),
matching Jay's "GUARD enters from the right, moves independently of the scroll."

**EFFECTS (gameplay sprites — confirm a real fight) `[HYP]`:**
`feet_shadow_930F / 9323 / 942A` (shadows under the combatants) and `hit_marker_93AB`
(impact spark, appears f7246 in the contact phase) — both hardcoded in `gameplay_7000.s`.

**AMBIGUOUS — cluster-L dominant `[HYP: oracle 'visual ambiguous']`:**
`$9A2A` (34 draws, f6733-7352, `$51≈$1B`) + `$9A18` — oracle `sprite_9a2a/9a18` (chain-2,
labeled "visual ambiguous", also used in scene 5). The most-drawn *character* source in the
contact phase; whether it's a player pose, the guard's body, or a shared prop is **Jay's call**.

> **Not characters, despite the `$9xxx` bank:** `$9524 $9550 $958E $95B8` are `floor_pattern_*`
> (scenery that lives in the `$95xx` region) — reconciled out by label, not swept in by range.

### Layer 3 — STATIC BACKDROP `[HYP]`
The Mt-Fuji stack + blue sky Jay described is a **fixed background fill**, not a per-frame
`L1903` sprite blit (it did not appear as a high-count draw source) — so it is NOT in the
draw-tap inventory above; it is drawn once/rarely as a background. Flagged for Jay to confirm
it is fixed (no scroll coupling) during the live gate.

---

## Corrections / superseded findings
- **`$A684` is the SCROLL, not the hero.** 2756 draws/window = a tiled redraw, the scroll
  layer's signature. The prior "dominant mover = hero" was the moving-object trap.
- **The `$0B1x` cluster is NOT a combatant.** `handler_0b35/0b7c` (which set `$03/$04=$0B12`
  and draw that 7×1 element `$B6`/`$B7` times) **fired 0 times** in the fight window — they
  are gameplay-state handlers, not attract. The prior "second combatant / $0B1x" was
  per-frame ZP noise. (The disassembly's "$B6 enemy / $B7 player sprite" comments are
  Hypothesis/TBD and do NOT describe the attract cast.)
- **Method fix:** classify by bank at the `L1903` draw entry, then reconcile to oracle labels
  — do not rank by per-frame `$03/$04` dwell (which is dominated by the scroll + mid-blit noise).

---

## Repeatability `[CONFIRMED]` — HS-2 gate PASSES (deterministic)
3 runs land byte-identical at the fight-demo onset (f≈6480, ~108 s). The attract cycle plays
frame-for-frame with no RNG, so the reach is fully repeatable (boot `apple2e -flop1
dumps/karateka.dsk`, wait to ~108 s) and one run's timing IS the timing.

---

## TARGETED adjudication list for Jay (HS-8)
Run the demo (boot, wait to ~108 s, watch ~108-125 s; operator-gate flags `-window -speed
0.5 -prescale 3`) and adjudicate — see `build/scene6-id-sheet/scene6-id-sheet.png` for the
rough character cels (shape-only; colors/registration not trustworthy):
1. **PLAYER** = the `player_run_legs/torso` composite (run cycle, f6423-6613): correct
   character? which side does he run in from, and which cel = which action?
2. **GUARD** = `enemy_head_8E9B` (+ its feet-shadow), right side, present throughout:
   correct? Does he move independently of the scroll (as expected)?
3. **AMBIGUOUS `$9A2A`** (dominant in the contact phase, f6733+): player pose, guard body,
   or a shared/transition sprite?
4. **SCROLL** = the `$A684` tile group — confirm it is the moving *background* (not a
   character), and describe the dead-band (player moves / scroll still → then scrolls)?
5. **BACKDROP** — is the Mt-Fuji + sky stack fixed (no scroll coupling)?
6. Any on-screen object NOT above (a prop, a UI element, a second enemy)?

---

## Exhaustive fight-animation search — action space + seed-sweep to saturation `[CONFIRMED 2026-07-11]`
`harness/tools/scene6_full_descriptor.lua` (now with seed-poke), 12-seed sweep × all-4-entries ×
no-filter, each run full-span f6484→f9443.
- **Action space (AC-1) — N = 4 selectors:** `fight_ai_a000` picks the animation via prob-tier
  (tables `$A087`/`$A08C`/`$A091`/`$A096`, indexed by combat state `$33` 0-7): **`$9B`** (approach,
  `$70`=`$13`/`$2F` paths), **`$C5`** (tier-2), **`$D7`** (tier-3), **`$00`/idle** (tier-1/fall);
  `$29` codes `$00`/`$01`/`$FF`. The RNG is the LCG `$59=$59×5+$13`. **`$6540` (the dispatch that
  maps selector→cel-seq) is UN-DISASSEMBLED** → per-action cel attribution is blocked statically
  (a reported limitation, not a trace gap).
- **Seed-sweep SATURATED (AC-2):** poking `$59` across 12 seeds, the combat-cel union grew
  103 (one fight) → **106**, then **plateaued for 7 consecutive seeds** (added 0). Saturation
  reached. **The seed axis was necessary:** 3 cels appear ONLY under seed variation, absent from
  the baseline single fight.
- **The 3 seed-only rare cels:** **`$87B3`** (14×5, guard/By) + **`$88C5`** (14×6, guard/By, one
  seed only) + **`$8962`** (14×4, player/A) — rare strike/body variants a single-fight trace misses.
- **Both combatants covered:** entry A (player) 7640 draws / By (guard) 7272 draws across the sweep.
- **Coverage verdict (AC-4) — TABLE AXIS NOW EXHAUSTED via debugger-bp force `[CLOSED for the row
  axis]`:** the action selector has TWO inputs — RNG `$59` (seed-swept ✓, saturated) **and state
  `$33` = the prob-table ROW index.** The attract reaches the `$33`-table path (`$5E`=01, `$2F`=00
  → `LA049`) with **`$33` naturally ∈ {7, 9, 11}** (rows 8, 10 never naturally reached). The
  tap-based `$33` pokes (frame-notifier + write-tap) **both no-op'd** (stomped by `gameplay_7000
  L70C3 sta $33`). **SOLUTION that worked: a MAME debugger breakpoint at `$A03D` (`ldx $33`)** that
  overrides `$33` at the AI read, then `go` (with `manager.machine.debugger.execution_state="run"`
  to unpause the `-debug` startup). Forcing **every reachable row 7-11 each DIVERGED the fight** and
  surfaced **2 cels the seed-sweep MISSED — `$8EA5`, `$8EB3`**. **Union 106 → 108.** The row axis is
  now covered (rows 0-6 clamp to X=7; `$33`≥12 = idle → no table).
- **WHAT the forced rows revealed = the PLAYER FALL/LOSE animation `[Jay-ID + confirmed]`:** Jay
  identified the table-force pose as the **player fall (lose) sprites.** Confirmed decisively:
  **`$8EA5`/`$8EB3` appear in 0 of 12 natural seed-sweep runs** — genuinely UNREACHABLE in the demo.
  This IS the dispatch's **"unreachable-under-win-weighting"** category, now **proven not
  hypothesized**: the player-lose animation **exists in the game data** but the attract (player
  always wins) **structurally never plays it** — no seed-sweep can reach it; only forcing the
  prob-table row (overriding the win-biased selection) reveals it. Directly ties to the
  **always-wins enforcement weighting** — the suppressed outcome is the player losing.
- **FULL SATURATION (AC-4 fully CLOSED) — row×seed cross-product, 30 runs `[CONFIRMED 2026-07-11]`:**
  every prob-table row (7-11) × a 6-seed spread, each forced via the debugger bp + seed poke. **Union
  saturated at 110 combat cels** (15-run plateau at the end). The cross was necessary — it found 2
  beyond the row-force-alone 108. **The 4 cels beyond the natural seed-sweep 106 are ALL 0/12 natural
  (unreachable-under-win-weighting), and they are the complete LOSING OUTCOME both combatants:**
  - **PLAYER FALL/LOSE** (via A): `$8EA5`, `$8EB3` — the player defeated.
  - **GUARD WIN/VICTORY** (via By): `$8000` (25×2 body), `$9043` — the guard's victory when the
    player loses.
  So the demo (player always wins) never plays *either* — forcing the table row+seed reveals both.
  **COVERAGE: REACHABLE = 106 (seed-sweep saturation); UNREACHABLE-under-win = 4 (the losing outcome,
  both sides), captured by table×seed force.** Total action-animation space = **110 cels**, saturated.
  Composited: player-lose `scene6-tableforce-pose.png`, guard-win `scene6-guardwin-pose.png`.

## `$6540` action dispatcher DISASSEMBLED — the full control→render pipeline `[CONFIRMED 2026-07-11]`
**CORRECTION:** `$6540` is NOT un-disassembled — the `fight_engine.s:104` note was stale. `$6540`
is fully in **`gameplay_6000.s L6540`** (the "Action execution dispatcher", ~7000 fires); my earlier
"per-action attribution blocked by `$6540` un-disassembly" was wrong. Disassembled the live loaded
code (MAME `dasm` via debugger bp) to confirm, then read the oracle.
- **`$6540` = action dispatcher:** checks `$2F` (active-action flag), then dispatches the action
  code A to **6 handlers** — `$D1`→`L65F4`, `$D7`→`L6618`, `$C5`→`L667E`, `$C6`→`L6717`,
  `$9B`→`L66C3`, `$C2`→`L66FE`. **So the action space is 6 codes, not the 4 I read from `fight_ai`**
  (fight_ai passes `$9B`/`$C5`/`$D7`; `$D1`/`$C6`/`$C2` come from other state paths).
- **`L6811` (action-indexed combatant draw) reads `$20`** → selects + draws the cel for that frame.

### CLOSE 1.2 — the `$6540` dispatch OBSERVED EXECUTING (not re-read) `[VERIFIED 2026-07-11]`
Tool `harness/tools/scene6_dispatch_trace.lua`: a **debugger breakpoint at `$6540`** (opcode-fetch
level — read-taps false-0 on 6502 fetch) that `tracelog`s A/`$2F`/`$20` per fire into a bounded
instruction trace, so the branch **actually taken** is visible in the executed stream. Unreached
codes forced by setting register A (+`$2F`) at the bp. **Ground truth = the execution trace**, not
the static `dasm6540.asm` read.
- **Action→handler branch TAKEN, all 6 observed jumping (cross-check vs `dasm6540.asm`: MATCH):**
  `$D1`→`6548 jmp $65F4` · `$D7`→`654F jmp $6618` · `$C5`→`6556 jmp $667E` · `$C6`→`655D jmp $6717`
  · `$9B`→`6564 jmp $66C3` · `$C2`→`656F jmp $66FE`. The static handler MAP is correct.
- **FINDING A — the dispatch is `$2F`-GATED (a conditional the flat 6-way read hid):** `6540 ldx $2f;
  6542 bne $6559`. When **`$2F`==0** (every observed natural dispatch) it checks `$D1/$D7/$C5/$C6/$9B`
  and the `cmp #$C2` at `$656B` is **never reached** — `$C2`→`$66FE` is unreachable. `$C2`→`$66FE`
  fires **only when `$2F`≠0** (verified by forcing `$2F=1`: reaches `656B cmp #$c2` → `656F jmp
  $66fe`). The attract demo holds `$2F`==0 at dispatch, so **`$C2` never fires naturally** — same
  unreachable-under-win-weighting pattern as the player-lose / guard-win cels.
- **FINDING B — secondary "idle" tail at `$6567`-`$65B3` (omitted by the 6-handler summary):** when
  A matches none of the 5 movement codes (**A=`$00` = ~59% of natural fires**, the idle action),
  `$6540` does NOT no-op — it runs `6567 ldx $2f; 6572 lda $2f; 65B3 lda $29(action); 65B5 beq $6590
  rts`, i.e. an `$2F`/action-code-keyed routine, dominant at runtime.
- **CORRECTION to "each handler SETS `$20`":** the handlers **read** `$20`(WNDLFT)/`$21`(WNDWDTH)/
  `$24`(CH)/`$2F` to branch, then merge into the `$6572` tail and `rts`; **no handler writes `$20`**.
  `$20` is written by **`$7081`/`$709D`** (gameplay_7000 per-frame state/anim update) + **`$645B`/
  `$6493`** (the `$6400` anim-prep sub the main loop calls after dispatch) — verified by a write
  watchpoint on `$20`. (MAME shows these ZP as Apple-monitor names: `$20`=WNDLFT, `$29`=BASH.)
- **THE FULL FIGHT PIPELINE (control→render), corrected:** `fight_ai_a000` (LCG `$59` + prob-tables
  by state `$33`) → **action code `$29`** → **`$6540`** dispatches to a **window/collision handler**
  (reads `$20`+window vars, `$2F`-gated) **||** `$20` anim-frame **written by the `$7000` state
  machine + `$6400` prep** → **`L6811` draws cel[`$20`]** → `$1903`-family blit.

### Fight TIMING — VBLs-per-pose measured against the VBL timebase `[VERIFIED 2026-07-11]`
Tool `harness/tools/scene6_pose_timing.lua`: taps the draw entries, reads `$20` (the active
combatant's anim frame) at each combatant-cel draw, computes pose dwell = VBL gap between a
combatant's figure redraws. Measured, not read from a table (there is none — see below).
- **VBL timebase (AC-1):** the game syncs on **`vbl_sync` ($779A: `lda $C019` / `bmi` spin on
  the RDVBL bit7)** — the hottest routine in the project. **MAME frame == one VBL** (one vblank
  per emulated NTSC frame), so pose dwell is counted in MAME frames = VBLs. NB `vbl_sync` fires
  only ~230× over the 960-VBL fight (~2 per figure redraw, double-buffered) — the **game main
  loop is compute-bound at ~14 Hz, NOT 60 Hz**; distinguish the display VBL (the transferable
  timebase) from the game-loop tick.
- **`$20` is per-combatant context (`$20-$2F` = active-combatant register file):**
  `save/restore_combatant_a/b` ($708F/$709B) swap the 16-byte block `$20-$2F` in/out of save
  slots `$60-$6F` (A) / `$70-$7F` (B). So `$20` read at each combatant's OWN draw is that
  combatant's frame. Player head `$8E9B` / guard `$8ECB` redraw on **0 shared frames** —
  interleaved, never simultaneous.
- **VBLs-per-pose (AC-2), pooled player, natural + 2 seeds (21 handles covered $20=01-06,0E-11,
  14-1B,1F-21):**
  - **BASE poses ≈ 1 tick (~12-14 VBL):** `$20`=01(11.9) 05(12.4) 06(14.2) 14(13.6) — walk/run/
    approach/idle.
  - **MID (~15-18 VBL):** `$20`=15 17 18.
  - **EXTENDED ≈ 2 ticks (~20-25 VBL):** `$20`=02(21) 03(19) 16(20) 19(21) 1A(23) 1B(24.5)
    1F(21.7) 20(19) 21(21.3) — strike / impact / recovery / held poses.
  - fight-wide: 175 pose-steps, **mean 16.1 VBL, median 15, base-tick mode ~13 VBL** (11-14
    spread = 6502 per-frame compute jitter). Guard mirrors the player split.
- **Cadence STRUCTURE (AC-3):** **one animation tick ≈ 11-14 VBL** (the compute-bound main loop),
  and each pose is **held an integer number of ticks** — 1 for base, ~2 for strikes/impacts —
  chosen by a **countdown timer inside the `$20-$2F` context** (state-dependent). NOT a fixed
  VBLs/frame; NOT a static per-move table.
- **Seed-invariance (HS-3):** the **structure is seed-invariant** — base-tick length and the
  base/extended split hold across seeds; per-handle mean is consistent ±2-3 VBL. *Which* poses
  occur is seed-dependent (e.g. `$20=16` absent under seed 0xD5). Per-handle dwell carries
  state-dependent variance (a pose's hold-count can extend with fight state) — **partial F2**:
  dwell is state-coupled, not a pure per-handle constant.
- **Oracle-table cross-check (AC-4) → F3 (NO timing table):** grep found no duration/dwell/
  frames-per table; the `$7000` advance uses only `tbl_action_class` (**classification**, sets
  `$32`), and the dwell is a **computed countdown** in the context block. The deferred A1
  "oracle timing table vs traced dwell" premise is **refuted — there is no table to validate;
  the trace is the sole timing authority.**
- **Port note:** VBL is VBL (~60 Hz both machines) so the per-pose VBL budget transfers, BUT the
  budget = (tick-count × tick-length) and tick-length is the port's compute-bound loop rate — the
  port must reproduce the ~13 VBL base tick (or scale the hold-counts) to preserve pacing.

#### Timing — extended coverage beyond the fight window `[VERIFIED 2026-07-11]`
The fight-window pass (above) covered only f7240-8200. Follow-up wide run (f6000-9450) +
state-forced runs (rows 8/10):
- **INTRO — climb** (`$A3C5-$A5DC` cels, f6019-6105, brief): ~17 VBL/step (only ~6 steps).
- **INTRO — walk-in / guard-approach** (player `$8E9B`, f6105-7245): mean **22.6 VBL** (slower
  than the fight; long holds up to 311 VBL = the pre-fight ready/wait, a phase-boundary gap not a
  single pose).
- **VICTORY / walk-off** (f8146-9450): player `$8E9B` mean **15.5 VBL**; victory-specific cels
  `$8F0E`/`$8E83`/`$8DA9` (absent from the fight) ~**18 VBL**, `$9290` ~**9 VBL** (a faster
  element). Guard head `$8ECB` **absent** — the guard is defeated.
- **WIN-SUPPRESSED (player-lose / guard-win) — NOT TIMED (honest gap).** Forcing the AI prob-table
  row `$33`=8/10 at `$A03D` **diverges** the fight (different action sequence, confirmed) but the
  lose heads `$8EA5`/`$8EB3` (and guard-win `$8000`/`$9043`) **never draw** — verified over both
  the fight window AND the full span f6484-9450 (4783 draws, 0 lose cels; only `$8E9B`/`$8EC1`/
  `$8ECB`). Row-forcing changes action *selection* but does not produce a player-LOSS *outcome*
  (health→0), which is what plays the lose animation. So the win-suppressed set's VBL dwell is
  **unmeasured** — timing it needs an actual driven loss (a mechanics/Track-M question), or the
  exact saturation seed+row combo that first surfaced those cels. Flagged, not smoothed over.

## Fight MECHANICS — the behavioral model (execution-confirmed) `[VERIFIED 2026-07-11]`
Tool `harness/tools/scene6_mechanics_trace.lua`: bp @ `$A03D` (the AI's `ldx $33`) logs the
selection inputs; bp @ `$6540` logs the selected action `$29`. Each claim marked **[C]**
confirmed-in-trace or **[I]** inferred-from-disasm (HS-1/HS-2).
- **M2 — DISTANCE is the state index [C]:** `update_range_flag` ($70BA) computes **`$33 = $72 −
  $62`**; `save_combatant_a/b` copy the active context `$20-$2F` into `$60-$6F` (A) / `$70-$7F`
  (B), so **`$62`/`$72` are the two combatants' position byte (`$22`)** and **`$33` = the
  inter-combatant DISTANCE**. Confirmed in every AI decision (e.g. `72=1A 62=0F → 33=0B` ✓);
  `$62`=0F held constant, `$72` swept 16→1A, `$33` tracked 07→0B. The flagged `$22` distance ZP
  is **CONFIRMED** (it is the per-combatant position; distance is `$72-$62`).
- **M2 — RANGE GATES the action [C]:** `fight_ai_a000` ($A03D): `ldx $33; cpx #$0C; bcs idle` →
  **`$33 ≥ $0C` ⇒ IDLE (out of range)**. Confirmed by forcing: `$33`=03 → 35 attacks vs 23 idle;
  `$33`=10 → 42 idle vs 12 attacks. Distance **weights** aggression — **not a hard cutoff** (a
  few attacks leak past `$0C`, in-progress).
- **M1 — action SELECTED by distance + LCG each AI tick [C]:** natural distance→action:
  **`$33`=07 (close)→`$29`=D7** (19/27), **`$33`=09 (mid)→`$29`=C5** (10/15), **`$33`=0B
  (far)→`$29`=00 idle** (19/21). fight_ai fires ~63× over the fight; each call re-selects `$29`
  from distance + LCG, so a pose HOLDS while the distance band + LCG keep re-picking it — **the
  timing pass's "dwell = how long the AI re-selects" coupling, now mechanistic.**
- **M3 — weighting is distance-indexed prob-tables [C-structure/C-frequency]:** index
  `X = clamp($33, ≥7)`; a 4-tier LCG threshold compare — `cmp $DB; bcs idle` (aggression gate)
  then `LA087,x` / `tbl_combat_prob_a08c,x` / `LA091,x` / `LA096,x` (distance-indexed) select the
  action. Action weighting depends on **range** (M2↔M3 coupled through `$33`).
- **M3 — the always-wins SUPPRESSION [C]:** `LA013: lda $2F; beq LA030` — **`$2F`==0 (every
  natural AI decision) → normal path; `$2F`≠0 → a different, suppressed branch** (→ the `$2F`-
  gated `$C2` dispatch, force-observed executing in the 1.2 pass). **Player-win is enforced by
  `$2F` held at 0** — the guard's winning branch is a *state never entered*, closer to
  **F-M3a (a gate)** than pure weighting at the branch level, while the *action* choice within
  the normal path IS weighted. Both true at different layers.
- **PARTIAL / inferred [I]:** player-vs-guard attribution (`$62` vs `$72`) not resolved this
  pass. **Hit→react causality (M2.3):** fight_ai does NOT select a react as a `$29` action (no
  react code appears), so a recoil is **likely hit-triggered outside fight_ai** (causal, not
  AI-selected) — but that path was **not traced**; inferred, not asserted (possible F-M2b). The
  `$70==$13` special case and exact prob-table row semantics are inferred.
- **Coupling (AC-S.2):** M1 re-selection sets pose dwell (timing); M2 distance `$33` is the
  shared index that both **gates** action (range) and **indexes** the M3 weighting; M3's `$2F`
  gate suppresses the guard-win branch. Port reproduces the RULES (distance = pos−pos;
  `$33≥$0C` idle; distance-indexed LCG weighting; `$2F`=0 suppression), not a timeline.

### Closing the 4 inferred Track-M items `[VERIFIED 2026-07-11]`
Tools `harness/tools/scene6_mechanics_trace.lua` + `c2_poke.lua` / `c3_2f.lua` / `c1_force.lua`
(poke-differential + branch forcing).
- **C1 — state-transition table → F-C1 (stateless decision function) [C-structure]:** the
  "`$7000` state machine" is **not** a stored-state FSM with tabulable transitions — it is a
  **per-tick stateless decision function** recomputed each fight_ai call from live inputs
  (distance `$33`, gates `$2F`/`$5E`, opponent-frame `$70`, LCG). Confirmed branches: **in-range
  attack** (`$33`∈[7,0B]→D7 close/C5 mid, [C natural+forced]); **out-of-range idle**
  (`$33`≥`$0C`→00, [C forced 0x10]); **suppressed** (`$2F`≠0→`$9B`/`$C2`, [C forced]). Forcing
  single inputs confirms each is LIVE (`$5E`=0 surfaces `$29`=D1; `$70`=`$13` surfaces FF/01/9B)
  but does **not** cleanly select one branch (multi-input + LCG interact) — so **a clean 1:1
  transition table is not extractable; residual marked [I], not forced** (HS-2). PARTIAL, as
  expected.
- **C2 — `$22`/`$4A`/`$72` roles → F-C2 (computed delta) [C]:** no single byte is "the distance";
  the operative distance is the **computed delta `$33 = $72 − $62`**. Poke-differential confirms:
  forcing `$72`=0x14 → `$33`=05-07 → attacks; forcing `$72`=0x30 → `$33`=0x21 → zero attacks (all
  idle/01). Roles: **`$72` = combatant-B position** (poke-confirmed), **`$22` = active-combatant
  position** (context byte-2; = `$62` for A), **`$4A` = a distance threshold** (compared vs
  `$72−$22` in the `$2F`≠0 branch only).
- **C3 — suppression mechanism → UNREACHED-STATE, not zero-row [C]:** the prob-tables
  (`LA087`/`tbl_a08c`/`LA091`/`LA096`) live in the normal `$2F`==0 path and select the **active
  combatant's attacks** (`LA077`→`$D7`, `LA07C`→`$C5`, `LA081`→`$01`) — there is **no guard-win
  row**. The guard-win is the separate **`$2F`≠0 branch**, gated by `$2F` held at 0 (a state never
  entered). Forcing `$2F`=1 opens it (action `$9B` appears, 31×, absent naturally; the 1.2 pass
  showed `$C2`→`$66FE` executes with `$2F` forced at the dispatch). So the always-wins is an
  **unreached-state gate**, not a zero-weighted probability.
- **C4 — cross-actor hit→react write → NOT CAPTURED [I] (honest):** M2's causality was **asserted,
  never traced**. Attempt: the hit-marker `$93AB` draws 13× over the fight, but its candidate
  gate bytes `$97`/`$9A` get **0 writes** in the window — so the exact attacker-resolution PC that
  writes the opponent's state was **not isolated** this pass. **M2 hit→react causality stays
  [I] inferred** (fight_ai emits no react `$29` code, so a recoil is *likely* hit-triggered
  outside fight_ai — but unproven). **The one trace that would close it:** bp at the `$93AB` draw,
  step back to the guard byte that led there, watchpoint that byte, and confirm its writer PC is
  in the attacker's routine (not the victim's AI) with a react cel following.

## Scene-6 HEALTH / VITALITY system (execution-confirmed) `[VERIFIED 2026-07-11]`
Tools `harness/tools/h2_zpdiff.lua` / `h2_watch.lua` / `h4_force.lua` / `h5_read.lua` /
`h1_cel.lua`. The whole subsystem is one low-RAM routine `$0B0C` (jmptable `$0B00`), called
per-frame from `$7292`. Each claim **[C]** confirmed / **[I]** inferred.
- **H2 — two count bytes [C]:** **`$B6` = PLAYER count, `$B7` = GUARD count** — two DISTINCT
  adjacent bytes (not one shared), found by ZP-diff (they drop over the fight) + write-watch.
  **Both start at `$0D` = 13 → EQUAL, even in the demo** (F6 does NOT fire; Jay's "equal in the
  first fight" holds). The two regen thresholds mirror them: **`$B8` (player) / `$B9` (guard)**.
- **H3 — damage [C]:** `$0BC1` (player: `lda $b6; beq; lda #0; sta $5b; dec $b6`) and `$0BD2`
  (guard: `... sta $5c; dec $b7`) — **`dec` the count on a landed hit, floored at 0, and RESET
  the combatant's regen timer (`$5B` player / `$5C` guard).** It's a **separate per-frame health
  routine** gated by the hit event, **not literally the C4 react-write** (F3-partial: damage and
  react are decoupled routines sharing the same hit trigger).
- **H4 — regen [C, forced]:** timers `$5B`/`$5C` **increment each frame** (`$0BE3 inc $5b` /
  `$0BF2 inc $5c`), are **reset to 0 on every hit** (H3), and at threshold (`cmp $B8`/`cmp $B9`)
  the count is **incremented by ONE** (`$0C1E inc $b7`). **Model = one-arrow-at-a-time on a
  repeating timer, reset-on-hit** (NOT refill-to-full). **Naturally `$B8`=`$B9`=`$FF` (255-frame
  threshold) → regen NEVER fires in the busy attract demo (F4)** — the demo is tuned so it can't,
  like the win-weighting. Confirmed by forcing `$B9`=04: `$B7` then oscillates up (`0C→0D→0E`,
  regen via `$0C1E`) and down (damage) — the regen path executes.
- **H5 — draw is count-driven [C]:** the `$0B35` loop `ldx #0; jsr $1903; inx; cpx $b6; bcc`
  **draws exactly `$B6` arrows** (redraw-N each refresh, X += 3 per arrow), player at **`$05`=0
  (LEFT)**, **Y=`$B9`=185 (bottom)**, flip `$0F`=`$01`. Not a delta-blit — a count-driven redraw.
- **H1 — arrow cel [C-partial / Jay-gate]:** the arrow cel is **`$0B12`** (a low-RAM cel;
  `$03=$12/$04=$0B` in the draw loop). Player arrows drawn LEFT (confirmed). **Guard-side draw +
  the mirror check are NOT cleanly captured** [I] — the `$1903` read-tap didn't fire on the
  arrow-draw `jsr` (the 6502 read-tap subtlety), so guard-right + same-cel-mirrored is a
  **follow-up**; the cel *bitmap* ID is **Jay's visual gate** (AC-H1.3 pending Jay).
- **Coupling / port:** the port reproduces the rules — two counts (`$B6`/`$B7`) start-equal at 13;
  damage `dec`-on-hit floored at 0 + resets the regen timer; regen = per-frame timer, reset-on-hit,
  +1 at threshold (`$B8`/`$B9`, set to 255 = off in the demo); count-driven arrow redraw (cel
  `$0B12`, player-left, bottom row).
- **PER-FRAME animation map CAPTURED (`$20`→cels, via L6811):** each anim-frame `$20` value draws a
  distinct cel set (body pose + head `$8EC1`/`$8E9B`|`$8ECB` + feet `$90D7`). Frames 01-06, 14-21+
  captured — e.g. `$20=02`→`$8244` (winning-blow), `$20=16`→`$8654`/`$8714`/`$876B` (strike/punch).
  So per-action/per-frame attribution is **fully tractable via `$20`** (the transient `$2F` reads 00
  at draw time — use `$20`, the anim index). Attribution is **no longer an open item**. **Composited per-frame animation sheet** (16 player anim-frames `$20`=01-06/14-21 as full figures): `build/scene6-cast-preview/scene6-anim-frames.png`. **Guard** animation sheet (15 frames `$20`=01/03-06/14-21, By/h-flipped): `build/scene6-cast-preview/scene6-guard-anim-frames.png` (one fewer frame than the player — no `$20=02`).
- **HARNESS BUG CAUGHT:** the first sweep was a no-op — `scene6_full_descriptor.lua` lacked the
  seed-poke (it lived only in `scene6_fight_control.lua`), so 8 "sweep" runs were identical. Added
  the poke; re-ran; verified divergence. (The seed axis silently doing nothing = the exact axis-miss
  the exhaustive-search framing guards against.)
- Seed-only rare poses (untracked, **composited full figures**):
  `build/scene6-cast-preview/scene6-rare-poses-composited.png` — `$87B3`/`$88C5` guard (By, mirror)
  + `$8962` player, each assembled with its co-occurring head/torso/legs/feet at traced (X,Y).

## Full-span fight THROUGH the loop-back — combat poses found `[CONFIRMED 2026-07-11]`
`harness/tools/scene6_full_descriptor.lua` (all-entry), window **f6484-9600**, run-length raised
to reach the loop. **Root cause of "missing combat poses": prior CEL captures capped at f7400** —
the fight itself was never in the cel window (a coverage gap, not an untapped path).
- **Frame-accountability (AC-1/2):** first captured **f6484**, last captured **f9443** (=loop-back
  to the Broderbund title, `$0400` font + logo). Continuous coverage f6484→f9443; the tap fired
  the whole span. **The fight is f7246-8145** (hit-markers `$93AB` fire across it); **victory /
  walk-off f8145-9443**; loop f9439-9443. Prior windows (f6000-7400) caught only the first 3
  hit-markers — the bulk (f7607-8145) was uncaptured.
- **Hit-markers `$93AB` = working control (HS-4):** ✓ fire f7246-8145 at **both** combatants
  (X104 player / X139 guard) — the tap works where it fires; **no fallback needed** (strikes come
  through the `$1903`-family tap, entries A + By, same as everything).
- **Strike poses (high-kick / high-punch) = SHARED cels:** `$876B` `$8654` `$8592` `$85F3` `$86EB`
  `$86B5` `$821E` `$804D` — each drawn via **A (player, left) AND By (guard, right, mirrored)**.
  Confirms the two karateka share pose shapes; combatant = the draw-entry (facing), not the cel.
- **Victory / walk-off (player wins):** post-f8145 — `$8DA9` + the player run cels (`$9B00-$9DD5`
  via A). Player-only resolution (guard defeated; no player death — scripted win).
- **Both heads interleave through the fight:** player `$8E9B` and guard `$8ECB` fire alternately
  f7246-8145 (both combatants present + striking).
- **Composited fight poses + Jay's IDs (AC-6) `[CONFIRMED by Jay]`** (full-figure composites,
  `build/scene6-cast-preview/scene6-fight-poses-composited.png`):
  - **PLAYER HIGH PUNCH** = the f7602-7608 pose (via A): strike cel `$8654`/`$8714` + torso `$9A2A`
    + head `$8EC1`/`$8E9B` + feet `$90D7`.
  - **GUARD PUNCH** (mid-or-high unclear) = f7604-7610 (via By, mirrored): `$876B` + `$8654` +
    head `$8ECB`.
  - **PLAYER READY/FIGHTING stance** (NOT victory) = f8304-8316 (via A) — the neutral combat stance.
  - **GUARD KICK** (likely MID KICK) = f8306-8308 (via By): `$804D` + `$821E` + head `$8ECB`.
  - **PLAYER VICTORY** = a distinct **HELD** pose held f8370-8412 (~42 frames), via A. **`$891B` is
    oracle-labeled "player torso, arm raised, VICTORY pose, no head" (NOT a mask** — Jay's
    scene-5-Akuma-stencil hypothesis refuted by the oracle label). Full figure = `$891B` (torso+arm)
    + head `$8EC1`/`$8E9B` + legs `$81BD` + feet `$90D7`. **Compositing nuance:** `$891B` is a body
    **silhouette** (every row starts `$80`=black) — black-keyed-transparent strips the torso body
    (reads mask-like); it needs **opaque-black** (the `'f'` opaque-black model, see
    [[hal-opaque-blit-mode-needed]] / opaque-black-f-refactor-plan). The earlier composite also
    wrongly included the prior-frame ready-torso `$9A2A` overlapping it. `$8244` (f8141) = the
    winning-blow pose. Rebuilt: `build/scene6-cast-preview/scene6-victory-pose.png` (transparent vs
    opaque-black variants).
  - **WINNING-BLOW** = `$8244` (21×8 body) + `$809A` + head + feet, f8141 (via A). `build/scene6-cast-preview/scene6-blow-and-fall.png`.
  - **GUARD FALL/DEATH** = `$8D0A` (oracle "player_death" cel, **reused** for the guard) + `$8E31`
    (enemy-head) + head `$8ECB`, single-frame **f8371** (via By, mirrored) — a crouched/falling pose
    at Y140-156 (no full floor-collapse). **Coincides with the player's victory hold** (guard falls
    the same frame the victory `$891B` begins).
  - Fight resolution TIMELINE: last hit-marker f8145 → **winning-blow f8141** → **guard falls +
    player victory hold f8371** (~42 frames) → player runs off (run cycle f8647+) → last actor draw
    f9148 → loop-back f9443.
  - **OPAQUE-BLACK — the HAL CAPABILITY ALREADY SHIPS (reconciliation 2026-07-11, corrects the
    "first concrete case for a refactor" framing):** the victory torso `$891B` (and the blow/fall
    body cels) are **mixed figures** — interior black (part of the silhouette → opaque) + exterior
    black (background → transparent) + colored pixels — so neither whole-sprite mode fits (opaque
    black-boxes the exterior; transparent holes the interior). **But the per-pixel path already
    exists in the HAL, regression-proven:**
    - `HAL_gfx_blit_sprite_opaque` (`$13` flag → all-`$FF` table, stores index-0 verbatim) — added
      for the **scene-5 princess shadow `$1CC4`** (100% index-0 black); **that was the first opaque
      case, and it shipped** (scenes 1-4 byte-identical).
    - `HAL_gfx_blit_sprite_masked` — **per-pixel** trans-vs-opaque *within a cel*: a caller mask
      byte per column, pair `11`=opaque / `00`=keep-dest, "a column can be opaque on some pixels
      and transparent on others." Plus `_mixed` (per-region) and `_stencil_punch` (per-pixel 2D) —
      the same masked/stencil path used for **scene-5 Akuma**.
    - The standard transparent blit already builds a per-pixel mask from the source ("11 per
      non-black pixel pair, 00 per black").
    **VERDICT:** the "opaque-black HAL refactor" is **NOT a blocking dependency and NOT a build** —
    the capability is present. The scene-6 figures render via the **existing `HAL_gfx_blit_sprite_masked`**
    with a **per-cel opacity mask authored** (a content/sandbox task, like Akuma's `$974B`), NOT a
    HAL change. The `'f'`=opaque-black 4bpp model ([[hal-opaque-blit-mode-needed]],
    opaque-black-f-refactor-plan) is a **cleaner future option** (bake opacity into the cel, drop
    the separate mask) — an optimization, deferrable, **not required** for scene 6. Item STRUCK as
    a HAL build; reframed as content-side mask authoring. (Jay to confirm the strike, AC-6.)

## Fight: control model (A2) + determinism + scroll (B) `[CONFIRMED by multi-run + seed-poke 2026-07-10]`
`harness/tools/scene6_fight_control.lua`; window f6400-9500; 5 runs + 2 seed-perturbation runs.

### Determinism / §M-RUN — the reconciliation with "it varies run-to-run"
- **5 runs from a fixed headless boot are BYTE-IDENTICAL** (control CSV). **But the fight IS
  stochastic** — the LCG seed `$59` takes **101 distinct values** over the window and the action
  code `$29` is written **only** by `fight_ai_a000`. The reconciliation: **the fight is LCG-driven
  stochastic, but DETERMINISTIC FROM A FIXED SEED.** From an identical boot the seed sequence
  repeats → identical fight. **Jay's run-to-run variance = SEED variance** (real/interactive entry
  advances `$59` a different number of times before the fight). Not a contradiction — both true.
- **Seed-perturbation PROOF:** poking `$59` at f6484 diverges the fight **~6034 CSV lines** from
  baseline (for two different poke values) → the fight is **seed(`$59`)-driven**, not a fixed
  timeline script. (F-A2b refuted: it IS the RNG, not a canned script.)
- **HS-1 tap-bypass CATCH:** read-taps on `$A000`/`$A0A2` returned **0 fires — a FALSE negative**
  (6502 opcode-fetches bypass MAME read-taps). The reliable evidence the AI runs is the **seed
  `$59` evolving + `$29` written only by fight_ai + the poke divergence**, not the (bypassed) tap.

### A2 — action-control behavioral model `[execution-confirmed, HS-8]`
- **RNG = LCG at `$A0A2` (`lcg_step_a0a2`): `$59 = $59×5 + $13 (mod 256)`, single-byte seed ZP
  `$59`.** (`combat_state_a0af` also steps the LCG and sets `$2A` = `$FF`/`$00`/`$01` via `$55`/
  `$AA` thresholds — a random direction/choice.)
- **Selector = `fight_ai_a000` ($A000)**, called from `routine_b69a` ($B6E2, scene_dispatch).
  Reads combatant state, steps the LCG (×2), compares the random byte against **4-tier probability
  tables** (`$A087`/`$A08C`/`$A091`/`$A096`, indexed by combatant state `$33` 0-7), and sets the
  **action code `$29`** (`$00`/`$01`/`$FF`, + loads a cel-sequence ptr `$9B`/`$C5`/`$D7`), then
  tail-calls the **action dispatch `$6540`**.
- **Action/state ZP map:** `$29` action code (written only by fight_ai) · `$2A` random choice ·
  `$33` combatant state (0-11) · `$59` LCG seed · `$70`/`$2F`/`$5E` combat-state flags · `$DB`
  per-combatant threshold · `$22`/`$4A`/`$72` distance/position.
- **Code path (traced):** `routine_b69a $B6E2 → fight_ai_a000 $A000 → lcg_step $A0A2 (advance $59)
  + combat_state_a0af → prob-table compare → set $29 → jmp $6540 (dispatch) → cel-seq → $1903-blit`.
- **OUT OF SCOPE (named follow-up):** the player-always-wins **enforcement weighting** — the
  stochastic model + seed map are here; *why the player wins* is a later task. No death-anim assumed.

### A1 — fight playback / animation union
- **A real scripted-by-RNG fight occurs** (not just the approach): fight cels `$8DA9`/`$8F0E`/
  `$8E83` (31× each) + `$9290` (62×), hit-marker `$93AB` (13×), feet_shadow `$942A` (13×). 103-cel
  actor union in one run.
- **UNION NUANCE (HS-7):** a fixed boot = **one seed = one fight**, so this union is one sample.
  The TRUE animation union needs **multiple SEEDS** (poke different `$59`), NOT multiple identical
  boots. (The AA/3C poke runs already surface additional cels — a seed-sweep is the way to the union.)
- Loop-back to the Broderbund title at ~f9443 (font `$0400` + logo `$BBEC`).

### B — background scroll verification `[per-frame ΔX]`
- **Midground `$A684`: SCROLLS** — X span **94** (238→332) over the window. ✓
- **"Upper background" `$A7xx` (Y<70): ALSO SCROLLS — span 94, identical to the midground.**
  `$A82B`/`$A7D1`/`$A707`/`$A763`/`$A703`/`$A857` all span 94. **F-Ba fired:** these are NOT a
  fixed layer — the `$A7xx` cels are **scrolling midground**, not the fixed backdrop. **[SEE THE
  RE-VERIFY BELOW — the fixed sky/Fuji layer WAS found, just not in the `$1903` span; F-Ba was a
  mislabel of the scrolling midground, not evidence the backdrop moves.]**

### B (re-verify) — THREE background layers, fixed backdrop FOUND `[CONFIRMED 2026-07-11]`
Jay's eye (watched scene 6 ×3): **sky + Mt-Fuji never move** — ground truth. Re-verify
(`harness/tools/scene6_bg_layers.lua`, f6000-7400): classify `$Axxx` cels by X-span + tap the
non-`$1903` `$0A00` FILL family. **The scene-6 background is THREE layers:**
1. **FIXED backdrop — Δ=0 `[CONFIRMED]`:**
   - **Mt-Fuji = a 4-sprite STACK, all Xspan=0 (fixed):** peak **`$A948` (X126, Y81)** → **`$A976`
     (X112, Y92)** → **`$A9B8` (X105, Y100)** → base **`$A9E2` (X84, Y108)**. (Jay's correction:
     the earlier pass showed only the base `$A9B8`/`$A9E2`; the **TOP/peak `$A948`/`$A976` draw
     just 2× at scene entry (f6012) and PERSIST**, so they were buried in the draw-count list —
     now surfaced by sorting fixed cels by Y.) The full stack spans Y81→Y108, does not move.
   - **Sky = `$0A00` fill `passA r0-104 c0-40 pat$D5`** — a **full-width fill of the top 104 rows,
     laid once at scene entry (f6003-6062)** and persisting; fixed vertical position.
   - **OCCLUSION-REPAIR mechanism (Q1) `[CONFIRMED — PORT REQUIREMENT]`:** the base draws 35×
     vs the peak 2× because of **occlusion, X-scoped**: at the **peak's position (X112-168,
     Y81-99) overpaint = 0** → drawn 2× at entry, persists. At the **base's position (X84-189,
     Y100-111) the scrolling FLOOR `$AA` tiles overpaint (94 draws)** → the game **repair-blits**
     the lower stack 35× to keep it visible. **The fixed backdrop is NOT draw-once** — the lower
     stack (rows overlapping the scrolling floor/midground) needs **repair-blitting after
     overpaint**; the peak (above the floor line) can be draw-once. (Confirms Jay's read.)
   - **The 4th-sprite vertical gap (Q2) = CASE B `[CONFIRMED]`:** heights `$A948`=11 / `$A976`=8
     / `$A9B8`=4 / `$A9E2`=3 leave **rows Y104-107 uncovered in the sprite stack** — a real gap.
     **Case A refuted:** all four draw via **entry A (`$1903` base, no Y-offset)** — not a
     composite Y-offset artifact. **Case B confirmed:** the gap rows Y104-107 are the **floor
     zone** — the scrolling floor `$AA11` (Y104, tiled across X) **fills them on-screen**; the
     plain Fuji-sprite composite omitted the floor, showing a gap the screen fills. Re-composite
     with the floor layered in reads continuous (`build/scene6-cast-preview/scene6-fuji-gapfill.png`);
     on-screen-vs-sheet is Jay's oracle call (HS-3).
2. **SCROLLING midground — Xspan≈88 `[CONFIRMED]`:** the `$A684`-bank tiles (`$A684`/`$A68A`/
   `$A703`/`$A85F`/`$A7xx`/…) — 24 cels, all span ≈88. This is what F-Ba measured and mislabeled.
3. **ACTORS:** `$8xxx/$9xxx` (player/guard).
- **Root of F-Ba:** the prior pass measured X-span only on the `$1903` scroll stream and never
  captured the fixed layer (constant-X sprites + the `$0A00` fill). The fixed backdrop was
  invisible to that measurement, not absent. **Corrected: there IS a fixed sky/Fuji layer** (Δ=0),
  separate from the scrolling midground — matching Jay's eye.
- Preview (untracked): `build/scene6-cast-preview/scene6-bg-layers.png`.

## Draw-entry map + facing + recovered parts `[CONFIRMED by all-entry re-trace 2026-07-09]`

> **JAY GATE — AC-6 — 2026-07-10 `[CONFIRMED by Jay]`** (off the corrected sheet): the **draw-B
> h-flip is confirmed — the guard now faces LEFT** (Case 2 validated; the facing mechanism is the
> draw-entry, port-relevant). The **lower-body composite (recovered Ay `$1906` second-tiles) is
> decent** — but the **FEET area still needs work**. As with the walk/climb/guard, **composite
> refinement moves to the animation sandbox**, not another recon trace. Trace-side findings
> (entry map, facing = draw-B mirror, Ay lower-tiles) are accepted.

All-entry re-trace of f6000-7400 (`harness/tools/scene6_full_descriptor.lua`, taps all four
jmptable entries; deterministic ×2; CSV `build/logs/allent.csv`). Resolves the guard-facing +
walk-feet-band threads — both were the same root: `$1903`-only coverage.
- **Entry map (per-entry fire counts, f6000-7400):** draw-A `$1903`=**362**, draw-A-Yoffset
  `$1906`=**22**, draw-B `$1909`=**10**, draw-B-Yoffset `$190C`=**299**. The `$1903`-only passes
  missed ~331 draws (Ay+B+By). The two draw *variants*: `$1903`/`$1906`=draw-A (`routine_1927`),
  `$1909`/`$190C`=draw-B (`routine_1af4`).
- **FACING = CASE 2 (real h-mirror mechanism the composite dropped — PORT-RELEVANT) `[CONFIRMED
  by code]`:** draw-B (`routine_1af4`) opens with `$10 = 7 - $10` + `dec $05` — a horizontal
  sub-byte MIRROR. The `$0F` flip bit is **identical per-cel** for player and guard (e.g. `$8EC1`
  is FLIP in both), so **facing is encoded by the ENTRY (draw-A vs draw-B), not `$0F`.** The guard
  draws via `$190C` (draw-B) = mirrored → faces left toward the player; the player via `$1903`
  (draw-A) = normal. My composites used the orientation-blind converter and **dropped the draw-B
  mirror** → guard faced wrong. **Port must render draw-B (`$1909`/`$190C`) sprites h-flipped.**
- **FEET-BAND = recovered Ay parts (H-parts CONFIRMED) `[CONFIRMED]`:** `$1906` (draw-A Y-offset)
  "draws a second sprite tile BELOW the first" (oracle). The player's lower body — legs (`$83DE/
  $843F/$84A0/$84DE`, Y143) + feet (`$90D7/$92DF`, Y159) — draws via **Ay `$1906`** (X154-193,
  f7153+), which the `$1903`-only walk composite **omitted** → the incomplete feet-band. (Early-walk
  feet via `$1903` were present, so registration may also contribute — but the missing Ay
  second-tiles are a real, recovered cause.)
- **Per-phase model refinement (HS-8):** the figures use **multiple entries**, not just `$1903` —
  draw-A for the primary tiles, **draw-A-Yoffset (`$1906`) for lower second-tiles**, draw-B
  (`$190C`) for the mirrored guard. A faithful composite must tap all four and honor the draw-B
  mirror. This refines the earlier `$1903`-only "walk 4-band / climb 2-part / guard single-frame".
- Corrected preview (untracked): `build/scene6-cast-preview/scene6-corrected-composited.png`
  (guard as-was vs draw-B-flipped; walk with recovered Ay lower tiles).

## Guard entry + opening exchange `[CONFIRMED by all-entry trace 2026-07-09]`

> **JAY GATE — AC-7 — 2026-07-09 `[CONFIRMED by Jay]`** (off the guard sheets): **all the
> orange sprites EXCEPT the guard's head are PLAYER RUN ANIMATION.** So the right-side (via-By)
> figure IS the guard, but its **body is reused player-run-animation cels** — only the **head
> `$8ECB` is a guard-distinct sprite**. The body cels I clustered as "guard" (`$8EC1`, `$9A18`,
> `$899C`, `$8ACB`, `$90F5` — all ODD→orange) are **shared player-run cels**, not guard-specific.
> **CEL-IDENTITY ≠ ACTOR-IDENTITY** — this is exactly the HS-9 shared-shape case: the sort by
> entry-path/X-side correctly found the guard *figure*, but cel labels/data are shared, so the
> guard's cast contribution is **just its head** ($8ECB, blue); the rest is the player's run set
> drawn at the guard's position. (Supersedes the scene-5 cast-map "$899C/$8ACB = guard body" and
> my body-cel attribution — §2/§4, Jay's visual gate is authority.)
> **Consequence:** the actor discriminator is the **head + position**, NOT the body cels (which
> the two karateka share). Guard-distinct asset to convert = the head `$8ECB` (+ any head variants);
> the body reuses the already-known player run animation.

Traced `harness/tools/scene6_full_descriptor.lua` (now taps ALL FOUR jmptable_1900 draw entries);
window f6450-7000; deterministic ×2; CSV `build/logs/guard.csv`.
- **CRITICAL CORRECTION — the guard is drawn via draw-B Y-offset `$190C`, NOT `$1903`.** Every
  prior scene-6 trace tapped only draw-A `$1903` and so **missed the guard entirely** (a false
  "no second figure"). The four entries fire (f6000-9500): `$1903`(A), `$1906`(Ay), `$1909`(B),
  **`$190C`(By)=832×**. Tapping all four is mandatory. (HS-1/HS-7: the tap must catch *all* draws.)
- **The guard ENTERS FROM THE RIGHT** — head `$8ECB` at X314 (f6487) approaching left steadily to
  X196 (f6715): X314→304→294→284→…→196. Exactly Jay's motion model.
- **Two actors CO-OCCUR** (the decisive multi-actor signal): frame f6487 draws BOTH — PLAYER
  (entry A, X120-132, left) and GUARD (entry By, X307-314, right) in one frame. Clean separation:
  **entry-path + X-side + head-signature all agree** (no HS-9 conflict).
- **Head-signature discriminates the actors:** both share the FLIP half `$8EC1`, but the norm half
  differs — **player = `$8E9B`, guard = `$8ECB`**. The norm-half is the identity key.
- **Guard cluster (structural):** head `$8EC1`+`$8ECB`, body `$899C` (torso) + `$8ACB`
  (below-torso) + `$9A18`, feet `$90F5` — matches the scene-5 cast-map guard body (`$899C`/`$8ACB`).
  Oracle labels mislead again (`$8ECB` = "feet_shadow" but is the guard HEAD). All Jay's call (HS-5).
- **Guard compositing model:** mostly **single-frame** (f6487 draws head+torso+below-torso+`$9A18`
  together via By) + feet `$90F5` on adjacent frames — closer to the climb's single-frame poses
  than the walk's accumulation. (Per-cluster model, HS-8.)
- **Convergence zone flagged (HS-9):** By-draws at middle X (167-203) — where the approaching guard
  and the rightward-walking player overlap — are **kept OUT of the strict guard cluster** (reported,
  not force-assigned).
- **Caveat on the prior walk/climb composites:** they used `$1903` only, so any Y-offset parts
  drawn via `$1906`/`$190C` were omitted — a possible source of the walk's "feet band needs work"
  (Y-offset feet may draw via `$190C`). Flag for the animation-sandbox refinement.
- Preview artifacts (untracked): `build/scene6-cast-preview/scene6-guard-{raw,composited}.png`.

## Player compositing model `[CONFIRMED by full-descriptor trace 2026-07-09]`

> **JAY GATE — AC-6 — 2026-07-09 `[CONFIRMED by Jay]`** (off the raw + composited sheets in
> `build/scene6-cast-preview/`): the composited reconstruction is **a good first pass — the
> compositing METHOD is validated** (band-accumulation at traced positions reads as the player).
> **Open:** the **feet band needs work** (Y153-159 — the feet/shadow cels don't sit right).
> **Refinement moves to the animation sandbox** — not another recon trace. Method green-lit to
> scale to the guard (later-window) and climb (earlier-window) traces.

From the L1903 full-descriptor trace over f6000-7400 (`tools/scene6_full_descriptor.lua`,
deterministic ×2, 352 non-scroll draws; per-draw CSV `build/logs/scene6_draws.csv`):
- **The player is drawn DIRTY-RECT, not whole-figure-per-frame.** Draws-per-frame histogram:
  110 frames ×1, 31 ×2, 52 ×3, 6 ×4 — **each frame redraws only 2-4 Y-bands**, and the parts
  **persist + accumulate** on the framebuffer. So single-frame co-occurrence gives a PARTIAL
  figure; the **full figure = short-window accumulation** (latest draw per band within ~16
  frames). This refines the prior "co-occurring cels = one figure" assumption — it's
  accumulation, not one frame.
- **Four Y-bands** (the composite structure): **head** Y116-121, **torso** Y123-129, **legs**
  Y138-143, **feet** Y153-159. Each band's cel swaps per animation frame; X co-steps to hold
  parity (movers stay one hue). 7/8 sampled anchors assemble all four bands; gaps (a band not
  redrawn in-window) are real, not missing data.
- **The head is a MIRROR PAIR:** `$8EC1` (blend=FLIP) + `$8E9B` (blend=normal) are drawn at the
  **same X,Y every time** → a symmetric head built from one cel + its h-flip. This is why the
  oracle "`feet_shadow_8EC1`"/"`enemy_head_8E9B`" labels mislead — together they are the player's
  head (consistent with Jay's gate: player parts, not enemy). Blend/flip `$0F` per cel is in the
  descriptor (`FLIP`=reversed/h-flip, `norm`, `skip`).
- **Draw order** within a frame is stable (head-pair first, then body cels); cross-frame
  accumulation paints chronologically (last drawn on top = framebuffer order). Bands barely
  overlap, so occlusion is minor.
- Preview artifacts (untracked): raw part-cel sheet + accumulated-figure sheet in
  `build/scene6-cast-preview/scene6-player-{raw,composited}.png`.

## Climb phase `[CONFIRMED by full-descriptor trace 2026-07-09]`

> **JAY GATE — AC-6 — 2026-07-09 `[CONFIRMED by Jay]`** (off the climb raw + composited sheets):
> the composite is **pretty good — method validated**. **Tweaking deferred to the animation
> sandbox.** Caveat Jay flagged: **the Y-change (ascent) can't be judged from static sheets —
> needs the background + animation** to confirm the climb motion reads right (a sandbox check, not
> a recon trace). Player-recon now closed both phases (fight + climb); **guard** is the remaining
> cast item (later-window trace).

Located + traced (`harness/tools/scene6_full_descriptor.lua`, env window + refined exclusion;
deterministic ×2; CSV `build/logs/climb.csv`):
- **Window (AC-1):** scene 5 (imprison) ends ~f5995; **CLIMB = f6019 (intro pose) + 5 active
  steps f6077/6084/6091/6098/6105**; **climb→walk boundary f6105→f6110** (the `$8xxx/$9xxx`
  walk begins f6110). This pins the phase boundary the prior verdicts left open.
- **The climber is the `$A3C5-$A649` "Climbing-animation sprite chain"** (oracle
  `sprite_data_a400.s`; 12 cels) — it lives IN the `$A400` bank but is **NOT scroll**. The prior
  f6000-7400 trace excluded `$A400-$ACFF` wholesale and so **hid the climb** — the refined
  exclusion is `$A64A-$ACFF` (scroll tiles `$A684+` / cliff `$AA7D` / floor), keeping
  `$A3C5-$A649` as the captured climber. (HS-4 trap: climber and scroll share a bank.)
- **Motion (HS-8 CONFIRMED):** the climber **translates UP** — Y 158→120 (upper) / 141→127
  (lower) over f6019-6105, at X63-84 (lower-left). Positions MOVE per pose; there are **no fixed
  Y-bands** (that model was walk-specific).
- **Compositing model — DIFFERENT from the walk:** each climb pose **redraws BOTH parts in one
  frame** (single-frame co-occurrence, blend=skip), so a pose composites directly from its frame's
  2 cels at traced positions — **no cross-frame accumulation needed** (the walk needed it; the
  climb does not). The **mirror-head pair is ABSENT** — the climb uses a compact 2-part figure
  (upper + lower), not the walk's head/torso/legs/feet band stack.
- **Cels:** 10 labeled (`sprite_A40B/A425/A45A/A4A4/A4D2/A4F2/A548/A572/A5CC/A5DC`) converted;
  the f6019 **intro pose `$A3C5`/`$A3E9` is split across `fight_engine.s` (header) + `$A400`
  (bitmap tail) with no clean label — OMITTED as a reported gap** (HS-6), not filled.
- Preview artifacts (untracked): `build/scene6-cast-preview/scene6-climb-{raw,composited}.png`
  (raw cels + 5 pose panels + ascent overlay).

## Status / open items
- **25.3-V — PARTIALLY CLOSED (2026-07-08):** Jay's visual gate (block in Layer 2) confirmed the
  f6000-7400 cast is the **PLAYER multi-part composite** (parity-stable candidates = player parts
  needing compositing; `$9A18` ≈ player-death cel). This **supersedes** the `$8E9B`/`$8EC1`
  enemy/guard hypothesis. STILL OPEN: (a) **compositing** the player parts into the assembled
  figure (next step — traced per-part column/row give registration; the current rough composite
  `build/scene6-cast-preview/scene6-player-composite.png` is a decent start but needs more work —
  Jay); (b) **CLIMB phase** — an EARLIER-window trace (before f6000; this window is post-climb);
  (c) **GUARD/enemy** — a LATER-window trace (the enemy has not appeared by f7400); (d) per-parity
  **variant ruling** for any true crosser (`$9A18` folds into the player-death composite instead).
  Items (a)/(b)/(c) are follow-up dispatches (Jay to discuss with the orchestrator).
- **25.3-V is the core gate:** Jay's live-MAME adjudication is the SOURCE of asset identity;
  the remaining `[HYP]` entries stay open until he watches the demo and answers the list above.
- **Stage 1 scope (this pass):** find + classify the motion layers and localize the cast.
  Delivered. **NOT done (later stages):** conversion into the port, the sequence-timing epic,
  the scroll-engine (dead-band/lock) build, the scene-6 CoCo hook — this recon is their spec.
- **Data-location `[HYP]`:** cast data lives in the `$8300`/`$8c67`/`$9b00`/`$A400` oracle
  banks (labels above) — mark CONFIRMED only once a conversion-time trace confirms the source
  address IS the sprite data at draw time.
