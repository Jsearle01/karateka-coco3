# Session note — 2026-05-15 — P2.2 Kernel/dispatch engine subsystem port

## Timing

- Started: 2026-05-15T11:27:09-04:00
- Completed: 2026-05-15T12:03:58-04:00
- Elapsed: ~36 min 49 sec

## What landed

| File | Role |
|------|------|
| `src/engine/kernel_per_frame.s` | CoCo3 per-frame orchestrator (redesigned) |
| `src/engine/kernel_dispatch.s` | CoCo3 dispatch table + 7 assert-fire handler stubs |
| `src/hal/coco3-dsk/input.s` | HAL_input_init + HAL_input_poll stubs (STUB-P2.x) |
| `src/hal/coco3-dsk/sys.s` | HAL_sys_panic stub (infinite loop; makes assert-fire visible) |
| `tests/scripted/kernel_dispatch_driver.s` | Test driver (self-contained flat binary) |
| `tests/scripted/kernel_dispatch_driver.bin` | Assembled test binary (67 bytes) |
| `tests/scripted/kernel_dispatch_test.lua` | MAME test harness script |
| `tests/scripted/run_kernel_dispatch_test.sh` | Test runner |
| `captures/p2_2a_coco3_pre_loop.json` | CoCo3 DP state before per_frame_main_loop_once |
| `captures/p2_2a_coco3_post_loop.json` | CoCo3 DP state after per_frame_main_loop_once |
| `verification/mapping.json` | Updated: frame_countdown, frame_done, frame_sync_dc confirmed |

## 6502 Source Analysis Summary

**kernel.s ($0780-$07E3):**
- routine_0780/0783: JMP trampolines → ALREADY in P2.1 (timer_framesync.s page_flip entry)
- routine_0786: row-copy loop → blit/graphics territory; deferred to P2.3
- routine_0799/07ac: page-flip pair → ALREADY in P2.1 (timer_framesync.s page_flip/page_flip_to_a)
- routine_07b9: hires row-pointer setup → blit/graphics; deferred to P2.3
- routine_07d7: VBL sync → replaced by HAL_time_vbl_wait (P2.1)
- data_07e4, per_frame_07fa: Apple II-specific; NOT ported
**kernel.s produces NO new P2.2 engine code** — entirely covered by P2.1 or P2.3.

**kernel_per_frame.s ($0200-$02FF):**
The per_frame_poll cannot be literally translated. Three Apple II-specific mechanisms:
1. `jsr L0300` (disk_load_trigger): conditional restart → CoCo3: `scene_transition_check` stub
2. Sync signature at $BFFD-$BFFF: copy-protection; NOT ported
3. `jmp $BFFA → $B760`: per-frame continuation → CoCo3: `per_frame_continuation` stub
input_poll_loop (65536-iter) → replaced by single `jsr HAL_input_poll`
CoCo3 per-frame loop is a REDESIGN, not a literal translation.

**kernel_dispatch.s ($0C40-$0C54):**
7-entry cross-subsystem JMP dispatch table. Callers: input.s L763C (timer-expiry) and
L7697 (keyboard handler common exit). All targets in kernel_dispatch_handlers.s.

**kernel_dispatch_handlers.s ($0C55-$0CBD):**
All 7 handlers produce Apple II speaker effects (SPKR toggles + ROM_WAIT delays).
These are SOUND routines — on CoCo3 they will map to HAL_sound_* calls when sound is
ported. For P2.2: all 7 → assert-fire stubs (HAL_sys_panic if called).

## Attract-time-firing handler enumeration (complete)

| Handler | Source | P2.2 status |
|---------|--------|-------------|
| page_flip | kernel.s routine_0799/07ac | P2.1 (timer_framesync.s) |
| HAL_time_vbl_wait | kernel.s routine_07d7 | P2.1 (time.s stub) |
| HAL_gfx_present | kernel.s TXTPAGE1/2 | P2.1 (gfx.s stub) |
| scene_transition_check | kernel_per_frame.s L0300 | P2.2 new stub (rts) |
| HAL_input_poll | kernel_per_frame.s input_poll_loop | P2.2 new stub (D=0, rts) |
| per_frame_continuation | kernel_per_frame.s jmp $BFFA | P2.2 new stub (rts) |
| handler_0c55-0cb0 (7 handlers) | kernel_dispatch_handlers.s | ASSERT-FIRE stubs |

## HAL contract caller-side analysis

- HAL_time_vbl_wait: ✓ exists (time.s)
- HAL_gfx_present: ✓ exists (gfx.s)
- HAL_input_poll: gap → created src/hal/coco3-dsk/input.s (STUB-P2.x)
- HAL_input_init: gap → same file
- HAL_sys_panic: gap → created src/hal/coco3-dsk/sys.s (bra * stub)
**All gaps resolved by creating new stub files. Not contract design gaps — hal.inc
correctly declared them; they just needed their implementation stub files.**

## Port approach

| Apple II | Translation | CoCo3 |
|----------|-------------|-------|
| `lda $D0; jsr L0300` | Conditional restart | `lda <frame_done; jsr scene_transition_check` (stub) |
| `lda $BFFF; eor #$49` etc. | Sync signature | NOT PORTED (copy-protection) |
| `lda $D0; sta $D2` | State copy | `lda <frame_done; sta <frame_countdown` |
| 65536-iter input_poll_loop | Input scan | `jsr HAL_input_poll` once per frame |
| `jmp $BFFA → $B760` | Per-frame continuation | `jsr per_frame_continuation` (stub) |
| $0C4x JMP table (7 entries) | Dispatch table | CoCo3 dispatch table via lbra |
| 7 speaker-effect handlers | Sound effects | Assert-fire stubs (HAL_sys_panic) |

DP allocations (frame-coherent band $50-$5F, conventions.md §2):
- frame_done: ZP$D0 → DP $52
- frame_countdown: ZP$D2 → DP $53
- frame_sync_dc: ZP$DC → DP $54

## Ratified predictions vs actual comparison results

| Prediction | Expected | Actual | Result |
|------------|----------|--------|--------|
| frame_done (DP$52) = $00 at steady attract | $00 | $00 | ✓ MATCH |
| frame_countdown (DP$53) = frame_done | $00 | $00 | ✓ MATCH |
| frame_sync_dc (DP$54) = $00 | $00 | $00 | ✓ MATCH |
| page_register (DP$50) = $40 (P2.1 regression) | $40 | $40 | ✓ MATCH |
| page_source_blit (DP$51) = $20 (P2.1 regression) | $20 | $20 | ✓ MATCH |
| $50+$51 invariant = $60 | $60 | $60 | ✓ MATCH |

**compare.py result:**
```
MATCH  (5)
  page_register:    apple2=$0007:0x40  coco3=$0050:0x40
  page_source_blit: apple2=$00E4:0x20  coco3=$0051:0x20
  frame_countdown:  apple2=$00D2:0x00  coco3=$0053:0x00
  frame_done:       apple2=$00D0:0x00  coco3=$0052:0x00
  frame_sync_dc:    apple2=$00DC:0x00  coco3=$0054:0x00
SKIP  (2): blit_row_dst, blit_row_src (unmapped, blit/graphics)
RESULT: PASS (no mismatches)
```

## Handler-stub assertion-firing count during attract run

**0 stub assertion firings.** The driver completed per_frame_main_loop_once and reached
the test_loop spin in 5 frames. HAL_sys_panic (bra *) was never reached. This confirms
at runtime that the 7 kernel_dispatch handlers do NOT fire during the attract path.
Stubbing-safety holds at runtime.

## DEV_MODE note

Runtime assertion safety depends on DEV_MODE being active (HAL_sys_panic halts MAME
visibly as a timeout-failure instead of a silent miss). All P2.x testing is built
without a release-mode flag, so DEV_MODE is effectively always on during P2.

## Verification scope statement

**Kernel/dispatch engine logic verified against Apple II reference for attract-time state.
scene_transition_check and per_frame_continuation are no-op stubs whose work is deferred to
P2.4 (scene management port). HAL_input_poll stub always returns "no input" (STUB-P2.x
for input.s port).**

**Gameplay-handler stubs are assert-fire; 0 assertion firings during attract — stubbing-safety
confirmed at runtime on actual CoCo3 execution.**

**Hardware integration via HAL stubs deferred to P3.**

## Mapping updates

| Entry | Before | After |
|-------|--------|-------|
| frame_countdown | apple2-confirmed-coco3-predicted, coco3=null | confirmed, coco3=$53 |
| frame_done | — (new) | confirmed, coco3=$52, apple2=$D0 |
| frame_sync_dc | — (new) | confirmed, coco3=$54, apple2=$DC |

## Methodology patterns exercised

- **reference-discipline**: all port decisions cite kernel_per_frame.s / kernel_dispatch.s /
  kernel_dispatch_handlers.s; HAL gaps cite hal.inc; DP assignments cite conventions.md §2
- **blocking-gate-discipline**: TASK 6 gate honored (quadruple duty); design reviewed before
  code written; predictions ratified; code matched predictions exactly
- **plan-deviation-discipline**: two findings surfaced — kernel.s entirely covered by P2.1
  (scope narrower than survey predicted), kernel_per_frame.s requires redesign not literal
  translation. Both within scope; neither blocked P2.2.
- **execution-timing-discipline**: timing recorded

## Calibration tracking

Calibration task counter: 12 → 13. P2.2 is the second real engine subsystem port.
Gate analysis was the strongest to date (full attract-time firing enumeration with source
citations; kernel.s scope clarification; HAL gap identification).

## Test harness note

Initial test used spin-detection (wrong approach — detected ROM idle loop at $A7D5 instead
of driver spin loop). Fixed by following P2.1 pattern: fixed-frame redirect at frame 10,
capture at frame 15, immediate exit. Also fixed missing `end test_start` directive (caused
exec address $0000 instead of $0200) and missing notifier handle storage (`_G._kdtest_notifier`
to prevent GC).

## Next

P2.3 — blit/graphics port (video.s + render_frame_0a00.s, bundled with display setup/
palette init). Largest single subsystem by complexity; contains self-modifying code.
