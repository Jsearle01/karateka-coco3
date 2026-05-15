# karateka-coco3 — milestones

See `karateka-coco3-design-v0.1.md` Section 7 for the full phase
plan. This document tracks current status.

## P1 — Foundations — COMPLETE (2026-05-14)

Status: COMPLETE

- P1.0 — Project state setup: COMPLETE (2026-05-13)
- P1.1 — MAME test harness: COMPLETE (2026-05-13)
- P1.2 — Asset conversion tooling: COMPLETE (2026-05-13)
- P1.3 — HAL contract: COMPLETE (2026-05-13; follow-up adds debug/trace subsystem)
- P1.4 — Engine conventions: COMPLETE (2026-05-13)
- P1.5 — Pattern library bootstrap: DEFERRED TO P2 — karateka Category C patterns are speculative without engine code; they populate during P2 engine porting as patterns surface
- P1.6 — Memory map: COMPLETE (2026-05-13)

## P2 — Engine port

Status: IN PROGRESS

Three converging workstreams per design doc Section 7.4.2: P2.x engine ports (against
smart HAL stubs), P3.x real HAL implementations (interleaves after P2.2 lands), and
content conversion (waves scoped to integration milestones). Target deliverable:
bootable CoCo3 disk running the complete intro/attract sequence (INT-3).

### P2 subsystem ports (P2.x)

- P2.0a — Apple II reference-capture instrumentation: COMPLETE (2026-05-14, commit 396a293 in karateka_dissasembly_claude)
- P2.0b — CoCo3 verification kit: COMPLETE (2026-05-14)
- P2.1 — Timer/frame-sync engine subsystem port: COMPLETE (2026-05-14)
- P2.2+ — Remaining subsystems TBD (scoping pass next)

### Integration milestones (INT-N)

Convergence checkpoints where P2.x + P3.x + content conversion combine into a running
deliverable. Naming uses INT-N to distinguish from karateka_dissasembly_claude's M1/M2/M3/M4.

- INT-1 — First scene displays correctly: NOT STARTED
  Requires: scene management, display setup, palette, blit/graphics engine ports +
  real HAL; first-scene assets converted (Brøderbund logo + palette).
- INT-2 — Logo → title → cliff scene sequence with transitions: NOT STARTED
  Adds: scene-transition machinery; additional scenes' content assets.
- INT-3 — Full attract cycle including sound, cutscenes: NOT STARTED
  Adds: sound HAL, tone-record interpreter, cutscene machinery, Akuma throne room.
  = P2 target deliverable: bootable disk looping the complete attract sequence.

## P3 — HAL implementations

Status: NOT STARTED (begins interleaving after P2.2 lands)

## P4 — Integration + content

Status: NOT STARTED

## P5 — Release prep

Status: NOT STARTED
