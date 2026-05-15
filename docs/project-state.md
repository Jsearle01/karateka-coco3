# karateka-coco3 — project state

## Current state

- Methodology version: Claude-Orchestrated Development Methodology v0.2
- Project phase: P2 IN PROGRESS (verification kit complete; P2.1 timer/frame-sync next)
- Last update: 2026-05-14

## Phase status

- P0: complete (karateka_dissasembly_claude M1/M2 closure provided
  the intro-time reference oracle; P0b ongoing for gameplay-state
  coverage)
- P1.0: complete (commit c4b06ec, 2026-05-13)
- P1.1: complete (commit 71c6894, 2026-05-13)
- P1.2: complete (commit 88ffb27, 2026-05-13; follow-up: aa5753a/381bc43)
- P1.3: complete (commit b319e42, 2026-05-13; follow-up: a97d41c)
- P1.4: complete (commit ba88652, 2026-05-13)
- P1.5: DEFERRED TO P2 (pattern bootstrap; populates during P2 engine porting)
- P1.6: complete (commit e921889, 2026-05-13)
- P1: PHASE COMPLETE (2026-05-14); P1.5 deferred to P2
- P2.0a: complete (2026-05-14; commit 396a293 in karateka_dissasembly_claude)
- P2.0b: complete (2026-05-14; this commit)
- P2.1-P5: not started

## Calibration phase tracking

Per methodology Section 9, the first 10-20 tasks of karateka-coco3
are calibration. Higher human gate involvement, criteria
refinement expected.

Calibration task counter: 11
(P2.0a = task #10, committed to karateka_dissasembly_claude 2026-05-14;
 P2.0b = task #11, this commit; P2.0a increment batched here per option-b.
 Both are karateka-coco3 phase tasks even though P2.0a commits to the ref repo.)

## Cross-project coordination

External resources (consumed via path/URL reference, no git
coupling):
- `../karateka_dissasembly_claude/` — reference oracle
- `../6502-6809-conversion-patterns/` — shared porting patterns
- `../apple2-disasm-patterns/` — disassembly methodology patterns

Pattern repo updates: monitor commits in those repos; consume
patterns when relevant to a task. No version pinning.

Reference oracle updates: when karateka_dissasembly_claude
advances substantively (new gameplay-state dumps disassembled),
capture a sync-point commit per design doc Section 11.6.

## Methodology lessons (will accumulate)

None yet.

## Open questions (will accumulate)

See `docs/open-questions.md` (to be created as questions surface).
