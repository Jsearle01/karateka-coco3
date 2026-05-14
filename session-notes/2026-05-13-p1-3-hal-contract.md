# Session: 2026-05-13 — P1.3 HAL contract design

## What landed

src/hal.inc and docs/hal.md establishing the HAL contract for
karateka-coco3.

Detailed subsystems (function-by-function specs):
- Graphics: HAL_gfx_init, shutdown, clear, blit_sprite,
  set_palette, present (6 functions)
- Time: HAL_time_init, vbl_wait, frame_count, delay (4 functions)
- Sound: HAL_sound_init, shutdown, dac_sample, tone_start,
  tone_stop, play_event (6 functions)

Skeleton subsystems (detailed during P2):
- Memory: HAL_mem_size_detect (1 function)
- Input: HAL_input_init, poll (2 functions)
- File: HAL_file_init, file_load (2 functions)
- System: HAL_sys_cpu, target, panic (3 functions)

Total: 21 functions (vs pop-coco3's 27; simpler memory, file,
and sound models).

## Reference citations

Documented [ref:]: 0 (P1.3 is a contract skeleton; implementation
citations land during P2 when HAL bodies are written).

Unverified [no-ref:]: 8 items:
1. GIME 320×192×4 mode setup (CRES/HRES bits) — resolve from GIME-RM
2. GIME palette register addresses (~$FFB0-$FFBF) — resolve from GIME-RM §3.x
3. VBL detection mechanism (poll vs interrupt) — resolve from CC3-TR, GIME-RM
4. Frame buffer MMU slot assignments — resolve from GIME-RM, P1.6
5. DAC register address — resolve from CC3-TR
6. CoCo3 keyboard matrix registers — resolve from CC3-TR
7. CoCo3 system DP usage at $80-$FF — resolve from CC3-TR
8. GIME color 6-bit encoding — resolve from GIME-RM §3.x

When resolved, citations use [ref: GIME-RM §3.x] format per
design doc Section 6.6.

## Pop-coco3 inheritance

Shape inherited from pop-coco3-design v0.7 Section 6.11.
Six karateka-specific divergences (no shape ID system; no
hal_gfx_draw_text; no dynamic memory allocation; richer sound
primitives replacing event-only dispatch; single-call file load;
uppercase HAL_ prefix naming).

## Pre-noted reference conflict

CC3-TR (expected: palette writes unrestricted) vs Sockmaster-GIME
(empirical: writes during active scanline cause artifact). Logged
in docs/hal.md §6 conflicts section for when it surfaces in P2.

## HAL_sound_play_event stability note

Retained in contract per user direction; docs/hal.md §5.3
documents that it may be removed in P2 if engine-side sound
dispatch makes the HAL event-routing layer redundant.

## Methodology patterns exercised

- G.1 reference-discipline: all CoCo3-specific decisions either
  [ref:] or [no-ref:] marked with resolve-from guidance
- blocking-gate-discipline: TASK 5 design checkpoint and TASK 8
  review gate both respected; awaited user confirmation before
  proceeding
- plan-deviation-discipline: pop-coco3 design doc located in
  docs/ (not expected sibling path); no plan deviation required

## Calibration tracking

Task 6 of calibration phase complete.

## Next session

P1.4 (engine conventions) or P1.6 (memory map) are natural next
P1 deliverables. P2 (engine port) cannot begin until HAL contract
holds and memory map is defined.
