# FORM B — Princess sandbox cleanup (regression + all-frames + fall-shadow + chain), oracle-verified

**Dispatch:** Princess sandbox cleanup · **Executor:** Clyde · **Gate:** Jay · **Date:** 2026-06-14
Follows `2026-06-14-princess-controller-sandbox.md` (the original port). Closes its
five "Remaining" follow-ups (1 all-frames, 2 run_* regression, 3 fall-shadow, 4 pre-stand hold).

## Outcome
The princess controller now plays the **full in-game imprisonment chain** in the boot-excluded
sandbox, Jay-gated end-to-end:

> **STAND** (`$1DD7` rest legs + `$1D00` torso) → **WALK-IN** → **BOW** (`$1867` head-bow) →
> **TURN** (`1530`→`1588`→`1611`→`169A`) → **COLLAPSE** (`16CC`→`175E`→`17D3`→`1829`) → floor → loop

All wired through the ONE shared `HAL_gfx_blit_sprite` leaf (multi-animator model). The two
previously-missing frames (`$1DD7`, `$1867`) are converted, registered, and wired with
oracle-measured timing.

## AC-by-AC (cleanup dispatch)
- **AC-0 regression — PASS.** Built prod at HEAD vs pre-opaque (`git show 6b71e9d~1:…gfx.s`),
  snapshotted scenes 1–4 at fixed frames {120,360,640,920,1180} (`prod_boot_snap.lua`), byte-compared
  (`cmp`): **all 5 snapshots BYTE-IDENTICAL.** Static proof too — `sprite_engine.s` is not in the prod
  boot path and opcode `$13` (`blit_opaque`) is unused by prod code. Pre-opaque prod = 7359;
  HEAD prod = **7634** (the +275B is exactly the additive opaque-blit table/entry).
- **AC-1 all-frames — DONE + DISCOVERY.** `$1DD7` (pre-walk rest legs) converted by-address from
  `dump05_imprison.bin` and wired as leg-table idx 4 (composites with torso `$1D00`). `$1867`
  (head-bow) wired as a single full-figure pose. **Discovery:** the `$16xx` cluster
  (tbl_princess idx 20–25) is the **score display** (`draw_score_display` + `tbl_score_data`),
  NOT princess poses — correctly out of scope (it reduces the literal "27-frame" target). Every
  real princess animation frame now renders.
- **AC-2 fall-shadow oracle-check — DONE.** `draw_princess_frame` draws idx7 (`$1CC4` shadow) for
  `$39`=`$0F`/`$10` (`16CC`/`175E`) but branches early (no shadow) for `$39`=`$11`/`$12`
  (`17D3`/`1829`). Wired faithfully: shadow on collapse frames 0,1 only.
- **AC-3 fall-shadow wired — DONE** (frames 0,1; oracle-exact, above).
- **AC-4 Jay re-gate — PASS.** Full chain gated "looks great." Rest-pose torso/leg registration
  tuned live to **+4px** (`$1DD7` align), confirmed by Jay.
- **AC-5 build/isolation — DONE.** `build.bat` clean; **prod stays 7634** (controller changes are
  sandbox-only, boot-excluded); commit + push + this Form B.

## What was added (controller)
- **Full chain state machine** — new `STATE_STAND` (4) + `STATE_BOW` (5) on top of WALK/TURN/FALL,
  with auto-transitions (STAND→WALK→BOW→TURN→COLLAPSE→loop). The walk in the chain glides to a turn
  spot then bows (`pr_fullseq`=1); the isolated walk-loop (`pr_fullseq`=0) still wraps for separate
  tuning (tap a key toggles).
- **16-bit hold counter** (`pr_holdctr` `$4D/$4E`) — the oracle pre-walk stand is 383 VBLs (> 255).
- **`$1DD7` registration** — leg align +4px (Jay-gated) so the rest torso/legs line up.
- **`$1867` pose** — full-figure, top-aligned, with the idx7 shadow (oracle draws it for the bow).

## Timing — oracle vs demo (honest split)
The per-frame **animation cadences are oracle-measured**: walk legs `PR_CAD`=13 VBLs, turn/collapse
`PR_POSE_CAD`=11 VBLs. The **static rest-holds are demo-shortened** for sandbox watchability (a faithful
~22 s loop is tedious to gate); each oracle value is preserved in a code comment for the scene-5
integration to restore:

| Hold | Demo | Oracle (VBLs / s) |
|---|---|---|
| Pre-walk stand (`$1DD7`, `$39`=0) | 60 | 383 / ~6.4 s |
| Turn frame-0 (`1530`, `$39`=8) | 40 | 173 / ~2.9 s |
| Facing-left delay (`169A`, `$39`=12) | 75 | 173 / ~2.9 s |
| Head-bow (`$1867`, `$39`=$13) | 30 (made visible) | 4 (flash) |
| Floor hold | 60 | — |

A headless state-trace (`princess_state_trace.lua`) confirmed the chain progresses
STAND→WALK→BOW→TURN→FALL→loop at the **full oracle holds** before the demo-shortening — proving the
timing logic, not just the demo values.

## Discoveries
1. **`$16xx` cluster = score display**, not princess poses (`draw_score_display`). Corrects the
   original "27 frames" scope.
2. **MAME `coco3` frame counter is 2×/VBL** — `frame_number()` advances twice per 60 Hz VBL, so a
   383-VBL hold reads as ~766 screen-frames in traces. Real-time durations are unaffected; relevant
   only when reading frame-numbered traces.
3. **The chain must be the boot default for the live gate** — relying on a key-tap to enter it was
   unreliable at the gate; the sandbox now boots straight into the chain (key toggles to walk-loop).

## Files
- `src/engine/princess_controller.s` — STAND/BOW states, full chain, 16-bit hold, `$1DD7` align +4,
  `$1867` pose + shadow.
- `tests/scripted/sprite_engine_princess_driver.s` — boots into the chain; `$1DD7`/`$1867` includes.
- `content/princess/fig_1DD7/converted.s` — NEW (by-address from `dump05_imprison.bin`).
- `tests/scripted/prod_boot_snap.lua` — the regression A/B harness.

## Build
```
build/karateka.bin              7634 bytes  (prod; unchanged — boot-excluded controller changes)
sprite_engine_princess.bin      4632 bytes  (sandbox: full chain + $1DD7/$1867)
```

## Remaining (next increment)
- **Scene-5 integration** (pass one): scenery, `$3B` wrapper, halt, princess as `$3B` driver;
  restore the full oracle holds; real-position colors; sound (INT-3).

## Commit: see hash below (pushed).
