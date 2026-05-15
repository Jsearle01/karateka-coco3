# Session: 2026-05-14 — P2.0b CoCo3 Verification Kit

## What landed

| Deliverable | File | Summary |
|-------------|------|---------|
| Variable mapping | `verification/mapping.json` | 5 entries; timer_frame_sync + scene_management seed |
| Test fixtures | `verification/test_fixtures.json` | 4 fixture entries; separate from production mapping |
| Comparison tool | `verification/compare.py` | Reads both capture JSONs; handles endianness; pending/skip |
| Synthetic CoCo3 capture | `verification/synthetic_coco3_capture.json` | Proof-of-concept capture with deliberate mismatch |
| Test template | `verification/test-template.md` | Per-subsystem P2.x test workflow |
| Verification README | `verification/README.md` | Kit overview, endianness rule, usage |
| CoCo3 capture module | `harness/lib/coco3_capture.lua` | MAME Lua; frame-boundary + write_tap; identical schema to P2.0a |

## Gate decision (TASK 4)

Variable mapping structure approved at TASK 4 gate.

User recommendation acted on: test fixtures moved to separate
`verification/test_fixtures.json` rather than mixing into `mapping.json`.
Production mapping stays a pure record of real engine variables.

User double-checks resolved:
- `frame_countdown` (ZP $D2): reassigned from `timer_frame_sync` to
  `scene_management`. Rationale: $D2 drives scene duration and the
  disk_load_trigger ($0300) at zero — semantically a scene timer, not VBL/page-flip.
  It co-resides with the page-flip code in the per-frame loop but is a different
  concern.
- `coco3.size`: confirmed as bytes-in-memory on both sides. 6809 register width
  is irrelevant; the 2-byte `blit_row_dst` stores 2 bytes in memory (BE hi/lo).

## Comparison tool proof (TASK 8)

End-to-end verification via `python3 verification/compare.py --self-test`:

```
MATCH  (2)
  _test_fixture_match: apple2=$0007:0x40  coco3=$0020:0x40
  _test_fixture_word_endian: apple2=$00E0:[0x09 0x0A](LE=0x0A09)  coco3=$0022:[0x0A 0x09](BE=0x0A09)
MISMATCH  (1)
  _test_fixture_mismatch: apple2=$00E4:0x20  coco3=$0021:0xFF
PENDING  (1)
  _test_fixture_pending

SELF-TEST PASS: detected exactly 1 mismatch as expected.
```

All four cases verified: match, mismatch, word endianness (byte-swap), pending.

## Corrected VBL understanding carried from P2.0a

The mapping seed correctly uses the attract-loop VBL path, not $779A:
- `$779A` (vbl_sync, display_7700.s) = fight-scene VBL path via per-frame dispatch $7C4A
- Attract loop uses `routine_07d7` ($07D7, kernel.s) via `routine_0799`
- ZP $07 (page_register) = the attract-loop page-flip indicator; confirmed by P2.0a write-trap
- P2.0a write-tap capture: ZP[$07]=0x40 at first game-phase write (~frame 650)

## Calibration tracking

Calibration task counter: 9 → 11.
- Task #10: P2.0a (2026-05-14; commit 396a293 in karateka_dissasembly_claude)
- Task #11: P2.0b (2026-05-14; this commit)
- P2.0a increment was batched here per option-b decision from P2.0a session.
- Both are karateka-coco3 phase tasks even though P2.0a commits to the reference repo.

Reasoning: counter tracks calibration-phase substantive deliverables. P2.0a
is karateka-coco3 phase work (building its verification infrastructure), so
it counts even though it committed to a sibling repo.

## Methodology patterns exercised

- **reference-discipline**: all mapping entries cite karateka_dissasembly_claude
  docs (Apple II side) or `[no-ref:]`; CoCo3 citations reference
  `conventions.md §2`, `memory-map.md`, `hal.inc`
- **blocking-gate-discipline**: TASK 4 gate honored; waited for approval
  before writing mapping file
- **plan-deviation-discipline**: no new deviations beyond P2.0a's (carried
  into the mapping seed correctly)
- **execution-timing-discipline**: timing reported (see session timing)

## Open items carried to P2.1

- All mapping entries are `apple2-confirmed-coco3-predicted` (CoCo3 addresses null)
- P2.1 timer/frame-sync port: pins the page_register, page_source_blit,
  blit_row_dst, blit_row_src CoCo3 addresses; changes entries to "confirmed"
- frame_countdown (scene_management) confirmed during P2.x scene management port
- Real CoCo3 capture first produced during P2.1 (no engine code exists yet)

## Next

P2.1 — timer/frame-sync engine subsystem port. Needs: CoCo3 equivalent of
the page-flip/VBL-sync cycle (routine_0799 / routine_07d7), DP variable
assignments, and a CoCo3 capture to run through compare.py.
