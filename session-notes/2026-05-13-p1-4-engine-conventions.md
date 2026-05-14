# Session: 2026-05-13 — P1.4 engine conventions

## What landed

docs/conventions.md establishing engine code rules for karateka-coco3.

Sections: overview (inheritance audit), DP allocation, calling
conventions, stack discipline, error handling, naming, comment
style, file organization, DEV_MODE, formatting, endianness,
karateka architectural patterns (multi-dump tagging, scene dispatch,
sprite composition), toolchain conventions (lwasm vs ca65), linter
deferral, reference citations, cross-references.

## Pop-coco3 inheritance

Shape from pop-coco3-design v0.7 Section 6.12. Nine subsections
inherited (§§6.12.3, .5, .6, .8, .9, .10, .11, .12, .16).

NOT inherited: §§6.12.1-.2 (absorbed into overview), §6.12.4 (POP
DP layout replaced by karateka layout), §6.12.7 (POP streaming/
shape-cache not applicable), §§6.12.13-.15 (linter deferred to P2).

## ZP allocation note

$20-$2F, $60-$6F, $70-$7F clusters observed from
karateka_dissasembly_claude Apple II source. $30-$5F partitioning
is predicted (no observed ZP usage in that range from Apple II
source); explicitly flagged as subject to revision in §2.

## P1.3 follow-up surfaced

src/hal.inc (P1.3) has no debug/trace subsystem. Pop-coco3's
hal_debug_trace_event (always-on, for harness) was referenced in
conventions §4 (DEV_MODE) but does not exist in the P1.3 contract.
Filed as P1.3 follow-up in conventions.md §9 before P2 begins.

## Reference citations

Documented [ref:]: 2 items
- [ref: MC6809 §4.5] stack discipline (§4)
- [ref: MC6809 §4] instruction mnemonics (§13)

Unverified [no-ref:]: 2 items
- [no-ref: CoCo3 system DP at $80-$FF] — carried from hal.inc P1.3
- [no-ref: lwasm conditional assembly syntax] — verify from lwasm
  manual during P2

## Linter

Deferred to P2. Conventions.md §14 defines target rules and
references pop-coco3 linter as implementation model.

## Methodology patterns exercised

- G.1 reference-discipline: 2 [ref:] citations, 2 [no-ref:] items
- blocking-gate-discipline: TASK 4 design checkpoint respected;
  three notes addressed before writing the document
- plan-deviation-discipline: no deviations required

## Calibration tracking

Task 7 of calibration phase complete.

## Next session

P1.3 follow-up (debug/trace HAL subsystem) should be filed before
P2. P1.5 (pattern library bootstrap) or P1.6 (memory map) are
the remaining P1 deliverables.
