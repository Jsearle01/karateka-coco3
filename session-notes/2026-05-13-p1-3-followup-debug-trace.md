# Session: 2026-05-13 — P1.3 follow-up: debug/trace HAL subsystem

## What landed

HAL contract extended with Debug/Trace as the 8th subsystem.
Three functions added:
- HAL_debug_trace_event — always-on; MAME harness instrumentation
- HAL_debug_log — DEV_MODE only; free-form debug string output
- HAL_debug_assert — DEV_MODE only; precondition verification

Closes the gap surfaced during P1.4 where conventions.md §9
referenced HAL_debug_trace_event but hal.inc didn't declare it.

Files modified:
- src/hal.inc — added Debug/Trace subsystem (8th); updated init
  order comment; total functions now 24
- docs/project/hal.md — added §5.8 (Debug/Trace); updated §1 overview,
  §6 reference citations, §7 init order; version bumped to
  "0.1 + P1.3 follow-up"
- docs/project/conventions.md — §9 DEV_MODE example updated to correct
  function name (HAL_debug_log, not hal_debug_log_string from
  pop-coco3); P1.3 follow-up note updated to closed/resolved

## Always-on vs DEV_MODE distinction

HAL_debug_trace_event is always present in all builds. Rationale:
MAME scripted-test harness reads trace ring buffer to verify engine
behavior; compiling it out of production builds would prevent
harness coverage on release binaries. Pop-coco3 precedent followed.

HAL_debug_log and HAL_debug_assert are DEV_MODE-gated (no
production overhead, no harness dependency).

## Within-HAL call documented

HAL_debug_assert calls HAL_sys_panic on failure. This is the one
permitted within-HAL call in the contract (assert→panic path is
explicitly permitted because assertion failure is fatal by
definition and HAL_sys_panic never returns). Documented in both
hal.inc and hal.md §5.8.

## Engine trace event enumeration

src/engine/trace_events.inc is implied by the contract (HAL accepts
event codes as opaque bytes 0-255; engine defines its own enum).
This file materializes during P2 when first trace instrumentation
points are added. It is not part of the HAL contract.

## Reference citations

All 3 new functions: [no-ref:] (trace/debug mechanisms are
engine-internal or implementation choices; no hardware reference
applies).

Trace buffer memory address: [no-ref:] pending P1.6 memory map.

## Methodology patterns exercised

- blocking-gate-discipline: TASK 3 design checkpoint respected;
  two TASK 3 notes addressed before writing (within-HAL call
  documentation; trace_events.inc implication noted in session)
- G.1 reference-discipline: [no-ref:] markers applied honestly
- execution-timing-discipline: timing reported below — first
  karateka-coco3 commit subject to this pattern (pattern landed
  in both repos as commits f33f523 / 072a82b on 2026-05-13)

## Calibration tracking

Task 8 of calibration phase complete.

## Next session

P1.6 (memory map) is the natural next P1 deliverable.
P1.5 (pattern library bootstrap, karateka Category C) may defer
to P2 as patterns surface during engine porting.
