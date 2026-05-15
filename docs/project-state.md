# karateka-coco3 — project state

## Current state

- Methodology version: Claude-Orchestrated Development Methodology v0.2
- Project phase: P2 IN PROGRESS (P2.1 complete; scoping survey filed; P2.2 next)
- Last update: 2026-05-15

## P2 trajectory

**P2 target deliverable:** bootable CoCo3 disk running the complete intro/attract
sequence (Brøderbund logo → title → cliff approach → demo combat → Akuma throne
room cutscene → loop). Corresponds to integration milestone INT-3.

**Three workstreams:**
- P2.x engine ports against smart HAL stubs (P2.1 complete; P2.2+ scoped per milestone)
- P3.x real HAL implementations (interleaves after P2.2 lands)
- Content conversion in waves scoped to integration milestones; each wave uses the
  visual-verification protocol (design doc Section 6.7)

**Integration milestones:** INT-1 (first scene), INT-2 (logo→title→cliff sequence),
INT-3 (full attract cycle) — see milestones.md for detail.

**Next:** P2.2 (kernel/dispatch per scoping survey recommendation) + first content-conversion
wave (INT-1 assets per docs/p2-scoping-survey.md §5); both can run in parallel.

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
- P2.0b: complete (2026-05-14)
- P2.1: complete (2026-05-14; commit e7a1e6b)
- P2.2-P5: not started

## Calibration phase tracking

Per methodology Section 9, the first 10-20 tasks of karateka-coco3
are calibration. Higher human gate involvement, criteria
refinement expected.

Calibration task counter: 12
(P2.0a = task #10; P2.0b = task #11; P2.1 = task #12; doc update = bookkeeping, no increment)

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
