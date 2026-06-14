# Session note — 2026-05-15 — Doc update: P2 strategy + visual-verification protocol

## Session type

Bookkeeping commit. Captures planning-conversation decisions into durable project
documentation. No code changes. Calibration counter stays at 12.

## Timing

- Started: 2026-05-15T10:42:34-04:00
- Completed: 2026-05-15T10:51:00-04:00
- Elapsed: ~8 min 26 sec

## Decisions captured

### P2 target deliverable

A bootable CoCo3 disk running the complete intro/attract sequence:
Brøderbund logo → title screen → cliff approach scene → demo combat →
Akuma throne room cutscene → loop. Matches Apple IIe behavior within
unavoidable cross-platform differences (4-color GIME palette, DAC sound,
GIME timing).

### Strategy β

Per-subsystem verification preserved via P2.0 infrastructure
(Apple II capture + CoCo3 capture + compare.py against mapping.json).
Integration milestones define when subsystems converge into running deliverables.
No subsystem isolation is lost; the milestones add convergence structure.

### Three converging workstreams

- **P2.x** — engine subsystem ports against smart HAL stubs. P2.1 (timer/frame-sync)
  complete. P2.2+ ordering determined by scoping pass before each milestone.
- **P3.x** — real HAL implementations replacing stubs. Promoted from "after P2" to
  "interleaves with P2 starting after P2.2 lands." Rationale: P2.2 surfaces any
  remaining HAL contract gaps before real implementations commit.
- **Content conversion** — Apple II assets → CoCo3 assemblable form. Waves scoped
  to integration milestones (convert what's needed, not all-at-once). Visual
  verification protocol (Section 6.7) governs each wave.

### Integration milestones (INT-N naming)

Named INT-N to avoid collision with karateka_dissasembly_claude's M1/M2/M3/M4
disassembly milestone naming.

- INT-1: first scene displays correctly
- INT-2: logo → title → cliff sequence with transitions
- INT-3: full attract cycle including sound + cutscenes (= P2 target deliverable)

### Corrected portable-subsystems list

The original P2 framing underestimated the portable surface. The entire intro/attract
sequence is covered by P0a (M1/M2 disassembly), which includes:

**Portable now (P0a coverage):**
- Timer/frame-sync (P2.1 complete)
- Blit/graphics
- Sound (attract music + demo SFX)
- Scene management + scene transitions
- Display setup / palette
- Basic keyboard scan (attract→gameplay break-out poll)
- Combat animation playback (demo fight visuals)
- Sprite composition / body-part assembly (Akuma throne pose)
- Cutscene machinery (Akuma throne room cutscene)
- Kernel/dispatch

Corrections from original planning: cliff approach is in attract (not gameplay-only);
Akuma throne room cutscene is in attract; basic keyboard scan exists for the
attract→gameplay break-out; scene transitions happen during attract.

**Waiting for P0b:**
- Combat input mapping
- Player-driven scene state machines
- Win/lose ending sequences
- Code paths reached only via player decisions

### Content-conversion visual-verification protocol

Documented in design doc Section 6.7. Per-asset artifacts: Apple II reference PNG +
CoCo3 converted PNG + CoCo3 assemblable .s file. Human visual review at conversion
time (before .s file committed for engine use). Sound exception: WAV pairs instead
of PNGs.

**Pattern promotion candidate:** after the first content-conversion wave exercises
this protocol, it is a candidate for promotion to a shared pattern in
6502-6809-conversion-patterns, transferable to pop-coco3.

## Methodology patterns exercised

- **plan-deviation-discipline:** all items were mechanical captures; no substantive
  design questions surfaced requiring a STOP.
- **execution-timing-discipline:** start timestamp recorded at TASK 0.
- **bookkeeping commit precedent:** calibration counter not incremented (per
  P1-closure precedent for documentation-only commits).

## Files changed

- `docs/project/karateka-coco3-design-v0.1.md` — Section 6.7 added; Section 7.4 restructured
  with sub-sections 7.4.1–7.4.4
- `docs/project/milestones.md` — P2 section expanded with workstream structure + INT-N milestones
- `docs/project/project-state.md` — P2 trajectory section added; current-state updated

## Next

Scoping pass: identify P2.2 subsystem selection + INT-1 content wave (which assets
are needed for the first scene to display). Then P2.2.
