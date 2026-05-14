# karateka-coco3 — project state

## Current state

- Methodology version: Claude-Orchestrated Development Methodology v0.2
- Project phase: P1.0 (repository setup, in progress)
- Last update: 2026-05-13

## Phase status

- P0: complete (karateka_dissasembly_claude M1/M2 closure provided
  the intro-time reference oracle; P0b ongoing for gameplay-state
  coverage)
- P1.0: complete (commit c4b06ec, 2026-05-13)
- P1.1: complete (2026-05-13)
    - P1.2: complete (this commit, 2026-05-13)
    - P1.2-P1.6: not started
- P2-P5: not started

## Calibration phase tracking

Per methodology Section 9, the first 10-20 tasks of karateka-coco3
are calibration. Higher human gate involvement, criteria
refinement expected.

Calibration task counter: 4

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
