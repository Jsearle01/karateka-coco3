# Verification Kit — karateka-coco3 P2.0b

Behavioral comparison infrastructure for the CoCo3 port. Enables per-subsystem
verification that the ported engine produces the same observable memory state
as the Apple II reference.

---

## How it works

```
Apple II (karateka_dissasembly_claude)       CoCo3 (karateka-coco3)
─────────────────────────────────────       ──────────────────────
tools/capture_regions.lua                   harness/lib/coco3_capture.lua
    └─ produces captures/*.json                 └─ produces captures/*.json
            │                                           │
            └──────────────┬────────────────────────────┘
                           │
                    compare.py  <──  mapping.json
                           │
                    MATCH / MISMATCH / PENDING
```

The P2.0a Apple II captures are the reference baseline. The CoCo3 captures
are produced after each subsystem is ported. `compare.py` reads both and
`mapping.json` as the variable translation table.

---

## Files

| File | Role |
|------|------|
| `mapping.json` | Apple II ↔ CoCo3 variable mapping (the Rosetta Stone) |
| `test_fixtures.json` | Same schema; used by `compare.py --self-test` only |
| `compare.py` | Comparison tool; handles endianness, pending entries |
| `synthetic_coco3_capture.json` | Synthetic capture for `--self-test` proof |
| `test-template.md` | Per-subsystem test workflow template |
| `../harness/lib/coco3_capture.lua` | CoCo3 MAME capture module |

---

## mapping.json — The Rosetta Stone

Each entry maps one semantic variable from Apple II ZP to CoCo3 DP:

```json
{
  "semantic_name": "page_register",
  "subsystem": "timer_frame_sync",
  "apple2": { "address": 7,    "size": 1 },
  "coco3":  { "address": null, "size": 1 },
  "status": "apple2-confirmed-coco3-predicted",
  "citation": { "apple2": "[ref: ...]", "coco3": "[no-ref: TBD-P2.1]" }
}
```

`status` drives compare.py behavior:
- `"confirmed"` — comparison runs
- `"apple2-confirmed-coco3-predicted"` — reported as PENDING (not MISMATCH)
- `"unmapped"` — silently skipped

Entries graduate from `apple2-confirmed-coco3-predicted` → `confirmed`
as each subsystem is ported and CoCo3 addresses are pinned.

---

## Endianness rule

6502 = **little-endian** (lo byte at lower address).
6809 = **big-endian** (hi byte at lower address).

For `"size": 2` mapping entries, `compare.py` converts both sides to integer
values before comparing:

```
Apple II value = bytes[addr] | (bytes[addr+1] << 8)   # LE
CoCo3 value   = (bytes[addr] << 8) | bytes[addr+1]    # BE
```

Raw byte order will differ between platforms; that is expected. Only the
integer values are compared. `size` always means bytes-in-memory.

---

## compare.py

```bash
# Production comparison:
python3 verification/compare.py \
    ../karateka_dissasembly_claude/captures/<apple2>.json \
    captures/<coco3>.json \
    verification/mapping.json

# Self-test (proves match + mismatch + endianness + pending):
python3 verification/compare.py --self-test
```

Exit codes: 0 = no mismatches, 1 = one or more mismatches.

---

## harness/lib/coco3_capture.lua

CoCo3 MAME Lua module for producing JSON captures in the identical schema
as the Apple II `capture_regions.lua`. Usage from a test script:

```lua
_G.COCO3_CAPTURE_OUTPUT_DIR = "captures/"
_G.COCO3_CAPTURE_EXIT_FRAME = 500
dofile("harness/lib/coco3_capture.lua")
local cc = _G.coco3_capture
cc.capture_at_frame(400, 0x0000, 0x00FF, "my_capture")
cc.install_notifier()
```

The `"platform": "coco3"` field distinguishes CoCo3 captures from Apple II
captures; all other fields are identical to the P2.0a schema.

---

## Per-subsystem test workflow

See `verification/test-template.md` for the full workflow. In brief:

1. Produce Apple II reference capture (P2.0a tooling or new trigger)
2. Port the CoCo3 subsystem in `src/engine/<subsystem>.s`
3. Update `mapping.json`: set `coco3.address`, change status to `"confirmed"`
4. Produce CoCo3 capture via `harness/lib/coco3_capture.lua`
5. Run `compare.py` — iterate until PASS

---

## Current state (P2.0b)

All mapping entries are `"apple2-confirmed-coco3-predicted"` (CoCo3 addresses
TBD). The kit is structurally complete and proven end-to-end via synthetic
test. Real comparisons begin at P2.1 (timer/frame-sync port).

P2.0a Apple II captures in `../karateka_dissasembly_claude/captures/`:
- `p2_0a_frame_700_zp.json`, `p2_0a_frame_800_zp.json`, `p2_0a_frame_900_zp.json`
- `p2_0a_write_tap_zp07_zp.json` — first game-phase write to ZP $07 (~frame 650)
