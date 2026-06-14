# FORM B — Princess controller: sandbox port (walk-in + turn→collapse), oracle-verified

**Dispatch:** Princess controller sandbox port · **Executor:** Clyde · **Gate:** Jay · **Date:** 2026-06-14
**C-35:** stamp `t0=2026-06-14T17:21:35Z` · target 6809 (no 6309) · gated by
`verification-plan_princess-controller-sandbox.md`

## Outcome
The princess is ported as **her own controller** (`src/engine/princess_controller.s`) driving the
**ONE shared `HAL_gfx_blit_sprite` leaf** (multi-animator model), exercised isolated in a
boot-excluded sandbox. Jay-gated and **oracle-timing-verified**. Implemented states:
- **WALK-IN** — leg cycle (1→4) + smooth position glide + torso (`$1D00`) composite + opaque
  black shadow (`$1CC4`) leading her toes.
- **TURN** — `1530→1588→1611→(1611+169A)` (the facing-left frame composites a `1611` base + a
  `169A` torso overlay, per the oracle) + shadow under her.
- **COLLAPSE** — `16CC→175E→17D3→1829`, bottom-aligned so she sinks to the floor.
- **CHAIN** — turn → delay → collapse → hold → loop (the in-game flow), tap-key vs the walk loop.

This **exceeds** the original dispatch (which asked only for the walk-in + a leg/body composite):
it adds the turn, the collapse, the chain, a new HAL opaque-blit primitive, and oracle-measured
timing. The remaining gap is the literal "all 27 static frames render" (a few unconverted/rest
frames) + a regression pass + the fall shadow.

## AC-by-AC (vs the original dispatch)
- **AC-0 [E] gates — DONE.** GATE 1 (`$3A`/`$10`): the Apple `$10` is a sub-byte pixel index
  (7-case shift, byte-packing artifact); cadence is a uniform 8 Apple-px/cycle → CoCo3
  native-integer (2 byte-cols/cycle). GATE 2: dirty-rect = reuse `eng_clear_box`. No HS-1 halt.
- **AC-1 [E] controller → shared leaf — DONE (and beyond).** Cadence, position, per-frame
  registration, compositing, all via the shared leaf (no second render path). PARTIAL only on the
  literal "27-frame table": every *animating* frame is wired (walk legs ×4 + torso + shadow; turn
  ×4; collapse ×4); not wired = `$1867` (head-bowed pose) and ~7 unconverted frames (`$1DD7` rest +
  the `$16xx` floor-level cluster).
- **AC-2 [E] (HS-2) dirty-rect — DONE.** `eng_clear_box` (parameterized with `eng_fillval` so the
  dirty-rect restores a colored floor); no smear. Single fill primitive.
- **AC-3 [E]/P1 frames render — PARTIAL.** All walk/turn/collapse frames render correctly
  (snapshots + live); the unconverted `$16xx`/`$1DD7` + `$1867` are not yet rendered.
- **AC-4 [T]/P2 cadence — DONE + EXCEEDED.** Not just `$39` 1→4 + position; the cadence is now
  **oracle-measured** (apple2e `$39`/`$3B` trace): walk legs 13 VBLs; turn & collapse 11 VBLs;
  facing-left hold 173 VBLs (~2.9s). The port matches.
- **AC-5 [H]/P3 walk live — PASS (Jay).** "looks good" after tuning (legs-only → smooth glide →
  oracle cadence → torso registration). Turn + collapse + chain also Jay-gated.
- **AC-6 [H]/P4 colors — PASS (Jay)** for the walk/turn frames at the game-parity column.
- **AC-7 [E] isolation/build — DONE (with a noted prod-size change).** `pr_px` free-runs/wraps;
  sandbox boot-excluded; `build.bat` clean; **prod boot 7359 → 7634** (+275B from the opaque-blit
  table/entry — an intentional HAL feature, additive, existing transparent callers unchanged).
  Cast sandbox un-regressed (assembles 5586, `eng_idx` still cycles). Full `run_*` suite pass
  still TODO.

## Beyond the dispatch — new HAL feature
**`HAL_gfx_blit_sprite_opaque`** (`gfx.s`): the blit was transparency-keyed on index-0, so a black
(index-0) shadow couldn't be drawn against a (partially black) floor. Added an opaque mode that
selects an all-`$FF` mask table → plain store (index-0 included) — faithful to the oracle's
`$0F`-selected store blend (`video.s routine_1927`). Additive: `HAL_gfx_blit_sprite` clears the
flag. `eng_clear_box` parameterized (`eng_fillval`) so the dirty-rect can restore a floor color.

## Discoveries (corrections to the model / oracle facts found)
1. **`$1CC4` is the shadow** — 100% index-0 (black), not a body part; needs the opaque blit. It
   was mislabeled "unidentified" in `content/unsorted/`. **`$1CD4` (blue-C) is NOT the princess**
   (Jay ID) — excluded though `draw_princess` references it.
2. **Converter trims each frame's blanks independently**, breaking shared registration — frames
   lurch unless re-registered. Fixed with per-frame X-offset tables (legs `[0,4,3,1]`, turn
   `[0,-6,-7,-7]`, fall `[0,0,5,3]`); the cause is now a known issue for all multi-frame actors.
3. **Poses use a separate drawer, `draw_princess_frame` ($7F8B)** (not `draw_princess`). The
   facing-left frame composites **`$1611` (idx $0B) + `$169A`** at the same origin (`tbl_x`=0,
   `tbl_y`=$24) — `169A` torso overlaid on the `1611` body. (We clear `1611`'s flying-hair region
   before overlaying `169A` so the hair reads as settled.)
4. **The "turn → delay → collapse" is one `$39` sweep 8→19** in `fight_round_main`'s fall code
   (`ldx #$08 stx $39` then `inc $39` to `$13`). Oracle-measured timing (apple2e trace): rest
   poses held **~173 VBLs** (`$39`=8 standing, `$39`=12 facing-left = the inter-delay), transition
   frames **~11 VBLs**. The princess "drives" `$3B` via her walk (pre-flight) — that scene-driver
   role is pass one.
5. **`$10`/`$3A` sub-byte is a 7px-byte packing artifact** — on CoCo3 (4px/byte) the mod-7
   machinery drops out; native-integer advance suffices (GATE-1 payoff).

## Files
- `src/engine/princess_controller.s` — NEW controller (state machine: walk/turn/fall + chain;
  per-frame registration; pose drawer; shadow; floor-restore dirty-rect).
- `src/hal/coco3-dsk/gfx.s` + `src/hal.inc` — `HAL_gfx_blit_sprite_opaque` + opaque table.
- `src/engine/globals.s` + `src/engine/sprite_engine.s` — `eng_fillval`-parameterized `eng_clear_box`.
- `tests/scripted/sprite_engine_princess_driver.s` — boot-excluded sandbox (tap-key: walk ↔ chain).
- `tests/scripted/{princess_trace,princess_live,parts_live}.lua`, `sprite_engine_parts_driver.s`,
  `run_sprite_engine_princess.sh` — trace/live/parts-inspector harness.
- `content/princess/` — frames (incl. `$1CC4`/`$1CD4` moved from `unsorted/`).
- Oracle (read-only, not committed): `tools/trace_princess_anim.lua` (the timing trace).

## Build (25.1)
```
build/karateka.bin              7634 bytes  (prod; +275B opaque feature, builds clean)
sprite_engine_sandbox.bin       5586 bytes  (cast — un-regressed, eng_idx cycles)
sprite_engine_princess.bin      4208 bytes
```
**25.2:** N/A (Apple→CoCo3 transform); correctness = the oracle cadence-match trace (AC-4) + Jay's
visual gates (AC-5/6).

## Remaining (follow-up increment)
1. **All-27 static render** (AC-1/AC-3 literal): wire `$1867`; convert + render `$1DD7` + the
   `$16xx` cluster (by-address from `dump05_imprison.bin`).
2. **Full `run_*` regression pass** (AC-7) for the shared-HAL changes.
3. **Fall shadow** — removed pending the oracle check on its shape/position.
4. *(Optional)* pre-stand hold (~173 VBLs standing before the turn) for full fidelity.
5. **Scene-5 integration** (pass one): scenery, `$3B` wrapper, halt, the princess as `$3B` driver;
   real-position colors; sound (INT-3).

## Commit: see hash below (pushed).
