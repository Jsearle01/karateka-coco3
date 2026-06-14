# FORM B — Princess controller: sandbox port (prove the walk-in, isolated)

**Dispatch:** Princess controller sandbox port · **Executor:** Clyde · **Gate:** Jay · **Date:** 2026-06-14
**C-35:** stamp `t0=2026-06-14T17:21:35Z` · target 6809 (no 6309) · no-6309 verified
**Gated by:** `verification-plan_princess-controller-sandbox.md` (P1–P4)

## AC-0 GATE OUTCOMES (resolved first — they shaped the build; no HS-1 halt)

**GATE 1 (cadence fork) → CoCo3-native integer advance.** `$10`(`:=$3A`) is the Apple-II
**sub-byte pixel index 0-6** — the 7-case within-byte shift packing pixels into a 7px hires
byte (`video.s` L1A84). A **byte-packing artifact**, not a speed fraction. The cadence nets a
**uniform 8 Apple-px per 4-frame cycle** (the `$3A` mod-7 + extra-`$3B` is byte/subpixel
bookkeeping). Converter is 1:1 px, CoCo3 is 4px/byte → **8 Apple-px = exactly 2 CoCo3
byte-cols**. Port = clean **+2 byte-cols/cycle, subbyte 0** — mod-7 machinery vanishes. No
fixed-point. **Branch taken: native-integer.**

**GATE 2 (dirty-rect) → reuse `eng_clear_box`.** `draw_princess_bg` = `render_pass_a`
single-colour, cols `[$3B-1..$3B+4]`, rows `$77-$A3`, pattern `$80`. The engine's existing
`eng_clear_box` (zeros a w×h box at col,row in the back buffer) **is** that primitive —
applied over her moving band each frame. **Single fill (HS-2 satisfied by reuse).**

**Inventory:** 14 princess frames in `content/princess/`. **Discovery:** body parts
`$1CC4`/`$1CD4` (draw_princess composite idx 6/7) were mislabeled "unidentified" in
`content/unsorted/` — **moved to `content/princess/`** (they're princess). `$1DD7` (`$39=0`
rest frame) unconverted, but not drawn in the walk (`$39=1→4`) → out of walk-in scope.
Parity: princess frames flipped in the color-fix gate (Jay PASS); AC-6 re-confirms.

## Summary
The princess walk-in is ported as **her own controller** (`src/engine/princess_controller.s`)
driving the **shared** `HAL_gfx_blit_sprite` leaf (multi-animator model). Runs isolated in a
boot-excluded sandbox. Cadence + render + dirty-rect + position are **agent-confirmed**; the
walk *fidelity* (composite alignment) + colors are Jay's live gate.

## Files
- `src/engine/princess_controller.s` — NEW. State (`pr_leg`/`pr_x`/`pr_cadctr` @ ZP $43-45);
  `pr_tick` (leg 1→4, `pr_x += 2` on cycle-wrap); `pr_render` (dirty-rect `eng_clear_box` →
  4-sprite composite via the shared leaf → present → flip). `pr_leg_ptr` indexes the 4 legs.
- `tests/scripted/sprite_engine_princess_driver.s` — NEW. Boot-excluded sandbox; VBL-locked
  loop `pr_tick`; includes real engine + controller + HAL + princess content.
- `tests/scripted/princess_trace.lua` / `princess_live.lua` — NEW. Auto pr_leg/pr_x trace +
  snapshots; live throttled gate.
- `tests/scripted/run_sprite_engine_princess.sh` — NEW. Build + stage + auto-trace (logs to
  `build/logs/engine/`) + prints the live-gate command.
- `content/princess/fig_1CC4`, `fig_1CD4` — moved from `unsorted/` (composite parts).

## AC-by-AC
- **AC-0 [E]** — DONE (both gates above; no HS-1).
- **AC-1 [E]** — Controller ported (cadence native-integer, position, leg table, 4-sprite
  composite) driving the **shared leaf** (not a second path). Assembles (1963 B).
- **AC-2 [E] (HS-2)** — Dirty-rect via reused `eng_clear_box`; **no smear** (SNAP2 shows clean
  background as she moves pr_x 10→22). Single fill primitive.
- **AC-3 [E] / P1** — Renders: snapshots show the composite (white body/legs + blue/orange
  head) at her position. (Full 27-frame static render = the existing set-select sandbox; the
  walk-in uses the 7 composite frames.)
- **AC-4 [T] / P2** — Cadence trace **PASS**: `pr_leg` cycles 0→1→2→3→0; `pr_x` steps **+2 on
  each leg-wrap** (2→4→…→32 = 8px/cycle, oracle effective speed); `page_register` `$20↔$40`
  each render; ~8 VBLs/leg. (`build/logs/engine/princess_trace.log`.)
- **AC-5 [H] / P3** — **PASS (Jay live gate, "that looks great").** Reached via a tuning
  loop: (1) **legs-only** — the leg frames ARE the walking figure (white dress + orange
  feet); the `$1D00`/`$1CD4`/`$1CC4` composite parts rendered as a "white box + blue C"
  jumble at the crude `tbl_y` offsets, so deferred. (2) **continuous sub-pixel glide** —
  render every VBL, advance via a `PR_PXNUM/PR_PXDEN` fractional accumulator (was discrete
  +2-byte hops/cycle → stutter). (3) **oracle-measured cadence** `PR_CAD=13` (recon trace:
  ~52 VBLs/walk-cycle ≈ 9px/sec) — Jay's "too fast" → set to the measured rate. (4) **torso
  registration** `pr_leg_align=[0,4,3,1]` — the converter trims each frame's blanks
  independently, so the torso-left was `[5,1,2,4]`px → the figure lurched ~4px backward on
  `1D5A`; offsets re-align the body so only the legs swing.
- **AC-6 [H] / P4** — colors render white body + orange feet (princess set flipped in the
  color-fix gate); awaiting Jay's explicit game-parity confirm.
- **AC-7 [E]** — `pr_x` free-runs + wraps (no fall — isolated); sandbox **boot-excluded** (not
  in `build.bat`); `build.bat` clean, **prod boot 7359 B unregressed**.

## Reasoning (key decisions)
- **Native-integer cadence** (GATE 1): the Apple mod-7 is 7px-byte packing; CoCo3 4px/byte makes
  the 8px/cycle advance a clean +2 byte-cols — simpler AND faithful (visual speed preserved).
- **Composite offsets** from `tbl_princess_y` deltas (body/part6 +0, leg +26, part7 +41 rows);
  X all ≈ her column. These are the one piece the **AC-5 live gate tunes** (the plan reserves
  composite fidelity for Jay).
- **Reused `eng_clear_box`** for the dirty-rect (HS-2) — no second fill.

## 25.1 (fresh build, verbatim)
```
build/karateka.bin (7359 bytes)          ; prod unregressed
=== BUILD COMPLETE ===
sprite_engine_princess.bin: 1963 bytes   ; sandbox assembles
princess_trace.log: pr_leg 0→3 cycling, pr_x 2→4→…→32 (+2/cycle), page $20↔$40
```
**25.2:** N/A (Apple→CoCo3 transform); correctness = the cadence-match trace (AC-4) + the
visual gates (AC-5/6, pending Jay).

## Deviations / uncertainty
- **R4-style discovery:** `$1CC4`/`$1CD4` were mislabeled in `unsorted/` — corrected.
- `$1CC4` is 2×13 (wide/short) — likely a shadow/floor element; composited at the tbl-derived
  offset but **flagged for the AC-5 gate** (may need re-positioning or is a ground bar).
- Composite X/Y offsets are principled (from tbl_y) but **not yet visually tuned** — AC-5.
- AC-5/AC-6 are Jay's live gates; agent ACs (0/1/2/3/4/7) confirmed on trace+snapshot+build.

## User interaction
Pre-flight "v" keystroke clarified; dispatch then issued. AC-5/AC-6 await Jay's live gate.

## Candidates captured: **None** (no seed infra in repo; controller is the deliverable).

## Commit: see hash below (pushed).
