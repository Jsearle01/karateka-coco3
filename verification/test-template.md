# Subsystem Behavioral Test Template

karateka-coco3 P2.0b. Each P2.x engine subsystem port uses this template
to verify that the ported CoCo3 subsystem produces the same observable
state as the Apple II reference.

---

## Template

Replace `<SUBSYSTEM>` and `<P2.x>` throughout.

### `<SUBSYSTEM>` behavioral test — <P2.x>

**Subsystem:** `<SUBSYSTEM>` (e.g., `timer_frame_sync`)
**P2 task:** `<P2.x>` (e.g., `P2.1`)
**Reference capture:** `../karateka_dissasembly_claude/captures/<apple2_capture>.json`
**Mapping entries:** all entries with `"subsystem": "<SUBSYSTEM>"` in `verification/mapping.json`

#### Step 1: Add Apple II capture points

If the subsystem does not already have a reference capture in
`karateka_dissasembly_claude/captures/`, extend `tools/capture_p2_0a.lua`
(or create `tools/capture_p2_<x>.lua`) with the appropriate trigger:

```lua
-- Capture DP $00-$FF at frame-boundary or write-tap when subsystem state is stable.
cr.capture_at_frame(<target_frame>, 0x0000, 0x00FF, "p2_<x>_<subsystem>_zp")
-- OR for a specific event:
cr.capture_at_write_tap(<watch_addr>, 0x0000, 0x00FF, "p2_<x>_<subsystem>_wtap", <min_frame>)
```

Run `scripts/capture_reference.sh` to produce the JSON.

Reference-discipline: the trigger address must be cited to
`karateka_dissasembly_claude` docs, or `[no-ref:]` if unverified.

#### Step 2: Port the subsystem

Implement the CoCo3 engine subsystem in `src/engine/<subsystem>.s`.
Map each Apple II ZP variable to its CoCo3 DP address.
Update `verification/mapping.json`: set each entry's `coco3.address`
and change `status` from `"apple2-confirmed-coco3-predicted"` to
`"confirmed"` once the address is pinned.

#### Step 3: Add CoCo3 capture to the test harness

Create (or extend) a test script in `harness/scripted/<subsystem>_test.lua`:

```lua
-- harness/scripted/<subsystem>_test.lua
_G.COCO3_CAPTURE_OUTPUT_DIR = "captures/"
_G.COCO3_CAPTURE_EXIT_FRAME = <exit_frame>
dofile("harness/lib/coco3_capture.lua")
local cc = _G.coco3_capture

-- Match the Apple II trigger type and approximate game state.
cc.capture_at_frame(<target_frame>, 0x0000, 0x00FF, "p2_<x>_<subsystem>_coco3_zp")
-- OR:
cc.capture_at_write_tap(<coco3_watch_addr>, 0x0000, 0x00FF,
    "p2_<x>_<subsystem>_coco3_wtap", <min_frame>)

cc.install_notifier()
```

Run via a script that invokes MAME coco3 with the test harness.

#### Step 4: Compare

```bash
python3 verification/compare.py \
    ../karateka_dissasembly_claude/captures/p2_<x>_<subsystem>_zp.json \
    captures/p2_<x>_<subsystem>_coco3_zp.json \
    verification/mapping.json
```

Expected result: `RESULT: PASS (no mismatches)`.
Pending entries (`"apple2-confirmed-coco3-predicted"`) are expected for
subsystems not yet fully mapped; they do not fail the run.

#### Step 5: Iterate

For each mismatch:
1. Check if the ported code correctly writes the CoCo3 variable.
2. Check if the mapping entry's `coco3.address` is correct.
3. Fix the code or the mapping; re-capture; re-compare.

A subsystem port is behaviorally verified when the comparison returns
PASS with all subsystem entries either `MATCH` or `PENDING`.

---

## Example: timer_frame_sync (P2.1)

This is the first subsystem to be ported.

**Apple II reference capture:** `p2_0a_write_tap_zp07_zp.json`
(write-trap on ZP $07 at first page-flip after frame 650; produced by
`tools/capture_p2_0a.lua` in P2.0a).

**Mapping entries:** `page_register`, `page_source_blit`, `blit_row_dst`,
`blit_row_src` in `verification/mapping.json`.

**CoCo3 trigger:** write-tap on the CoCo3 DP page-flip register (assigned
during P2.1 as part of porting the page-flip/VBL subsystem).

**Endianness note:** `blit_row_dst` and `blit_row_src` are 2-byte entries.
compare.py will byte-swap the CoCo3 BE bytes to match the Apple II LE value.

**Verification acceptance criteria:** `page_register` MATCH; pointer entries
may remain PENDING until the blit loop is ported in P2.1.

---

## Mapping update procedure

When a subsystem port pins a CoCo3 address:

```json
// Before:
{ "status": "apple2-confirmed-coco3-predicted", "coco3": {"address": null, "size": 1} }

// After:
{ "status": "confirmed", "coco3": {"address": 32, "size": 1},
  "citation": { "coco3": "[ref: src/engine/<subsystem>.s line N — DP$20 = page_register]" } }
```

Update `citation.coco3` with the source citation (file + label, or `[no-ref:]`).
