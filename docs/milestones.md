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
- P2.2 — Kernel/dispatch engine subsystem port: COMPLETE (2026-05-15)
- P2.3 — Blit/graphics engine port (INT-1 scope): COMPLETE per audit 2026-05-17
- P2.4+ — Remaining subsystems per scoping survey trajectory

### Integration milestones (INT-N)

Convergence checkpoints where P2.x + P3.x + content conversion combine into a running
deliverable. Naming uses INT-N to distinguish from karateka_dissasembly_claude's M1/M2/M3/M4.

- INT-1 — First scene displays correctly: IN PROGRESS
  Requires: scene management, display setup, palette, blit/graphics engine ports +
  real HAL; first-scene assets converted (Brøderbund logo + palette).
  Content-asset preconditions: SUBSTANTIALLY COMPLETE (2026-05-17 — logos converted,
  6 "presents" glyphs converted (INT-1 minimum met), positions proven via visible-
  extent formula, palette verified; full 30-glyph font and font-metrics regeneration
  not yet done — see project-state.md §Execution history).
  CLOSED blockers: R-vbl (CONFIRMED 2026-05-21, commit d687e01),
  R-boot (CONFIRMED 2026-05-21, commit ee3fa08). R-p23 closed 2026-05-17.
  Remaining blocker: R-p24 (canonical intro.s scene-1 path, P2.4) — controller
  CONFIRMED on agent-verifiable criteria (2026-06-13); INT-1 close pending Jay's
  MAME visual gate (AC-10). R-p24 ports the linear scene-1 controller +
  per-frame polled-input hold runner; halts at the scene-1→scene-2 cut ($B798).
  jmptable_b760 continuation + intro_prelude_b769 prelude deferred (beyond cut).
- INT-2 — Logo → title → cliff scene sequence with transitions: IN PROGRESS
  Adds: scene-transition machinery; additional scenes' content assets.
  Content Wave 2 COMPLETE (2026-06-13): scene-2 (Mechner credit, 10 font
  glyphs) + scene-3 (karateka title, 7 sprites + copyright) assets converted
  to CoCo3 format. Reference captures done (scene2_mechner_ref / scene3_title_ref).
  R-p25 RENDER PORT CONFIRMED (2026-06-13, incl. Jay visual gates): scenes
  1→2→3 render controllers + shared "pressed" early-break; halts at scene-3→4
  cut. Scene-2 spacing = oracle font metrics; scene-3 title leading-strip
  compensation + flourish tuned; copyright flash fixed. Scene 4 (cliff) closes
  INT-2 later (R-p26+).
  Content Wave 3 COMPLETE (2026-06-13): the 11 scene-4 scroll glyphs converted
  (7 letters f,i,k,l,u,v,w + 4 punctuation period,comma,colon,hyphen), extents
  generated (§22.4b), 11 PNG previews. Scene-4 scroll references captured
  (scene4_scroll_a/b). Per-asset Wave-3 visual gate PASSED (Jay, 2026-06-13 —
  glyph fidelity confirmed; positioning evaluated at render time in R-p26).
  R-p26 (scene-4 scroll port) ATTEMPTED + HARD-STOPPED (2026-06-13): the
  option-2 VOFFSET ring does not fit stock 128K (a seamless duplicate-zone
  ring needs ~2*(window+line_height) rows, which collides with the $FF00 GIME
  I/O — the 392-row combined buffers are ~10-14 rows short). Bake tool, text
  tables, and the full-region blit are validated + committed; scene4_scroll.s
  is HELD (not built). Buffer-architecture ruling pending (memmove-on-wrap /
  lower-bank / 512K). See project-state.md §R-p26.
- INT-3 — Full attract cycle including sound, cutscenes: NOT STARTED
  Adds: sound HAL, tone-record interpreter, cutscene machinery, Akuma throne room.
  = P2 target deliverable: bootable disk looping the complete attract sequence.

## P3 — HAL implementations (P3.1 COMPLETE)

Status: P3.1 COMPLETE (2026-05-21)
- R-vbl — real GIME VBL IRQ handler: COMPLETE (2026-05-21, commit d687e01)
- R-boot — Brøderbund splash boot integration: COMPLETE (2026-05-21, commit ee3fa08)
- P3.2+: not started

## P4 — Integration + content

Status: NOT STARTED

## P5 — Release prep

Status: NOT STARTED
