# karateka-coco3 — MAME Test Harness

Version: 0.2 (P2.3a.2, 2026-05-16)

## Overview

MAME Lua-based behavioral test harness. Tests load DECB binaries into the
CoCo3 emulator, execute them, and capture memory state for comparison
against Apple II reference captures via `verification/compare.py`.

MAME version in use: **0.281**. CoCo3 driver: `coco3`.

---

## Harness files

| File | Purpose |
|------|---------|
| `harness/lib/coco3_primitives.lua` | Low-level MAME Lua helpers (peek/poke, snapshot, frame number) |
| `harness/lib/coco3_capture.lua` | Capture library: frame-boundary and write-tap triggered JSON snapshots |
| `harness/smoke/smoke_test.lua` | P1.1 boot smoke test (PC in ROM at frame 300) |
| `tests/scripted/timer_framesync_test.lua` | P2.1 page_register behavioral test |
| `tests/scripted/kernel_dispatch_test.lua` | P2.2 kernel dispatch behavioral test |
| `tests/scripted/gfx_init_test.lua` | P2.3a HAL_gfx_init behavioral test |
| `tests/scripted/gfx_init_precheck.lua` | P2.3a §2.2 pre-binary BASIC-state validation |

---

## Boot context

**All scripted tests must load binaries after BASIC is fully initialized.**

CoCo3 Color/Disk BASIC reaches the "OK" prompt at approximately frame 300
(PC=$A7D5). Before this point, the GIME MMU task registers (FFA0-FFA7) have
NOT been set to the P1.6 memory map values by the ROM init code.

Tests that switch GIME mode (`$FF90=$4C`) must run AFTER frame 300. Tests
that stay in COCO mode (no `$FF90` write) may load earlier, but frame 300+
is the safe default.

**Detection pattern used in scripted tests:**
```lua
if frame >= 300 and pc >= 0x8000 then
    -- BASIC is at "OK" prompt; safe to load binary
end
```

Historical defect: `timer_framesync_test` and `kernel_dispatch_test` loaded
at frame 10. This worked because they stay in COCO mode. The `gfx_init_test`
originally also loaded at frame 10; this caused failures because `$FF90=$4C`
activated the GIME MMU before task registers were initialized. Fixed in
P2.3a remediation attempt 2 (2026-05-16).

---

## Write-tap timing defect and fix (P2.3a.2)

### Defect description

MAME Lua `space:install_write_tap(addr, addr, name, callback)` fires the
callback **before** the underlying RAM array is updated. This is the standard
MAME address-space tap behavior: the tap intercepts the bus write at the
address-decode phase, prior to the memory handler committing data.

**Source:** MAME address space implementation (src/emu/addrspace.cpp). Taps
are installed as pass-through handlers that wrap the underlying handler. The
tap fires, then the original handler (RAM write) executes. MAME version 0.281.

**Consequence:** Reading `mem:read_u8(tapped_addr)` inside the write-tap
callback returns the **pre-write** value from RAM, not the value being
written. The `data` parameter in the callback carries the value on the bus,
but RAM has not been updated.

**Evidence (P2.3a remediation attempt 2, 2026-05-16):**
```
write_tap fired: $0012 <- $01  frame=317
DP$12 gfx_initialized = $00   ← RAM still has BASIC's pre-init $00
```
Reading $0012 inside the callback returned $00 (BASIC's previous value),
not $01 (the value being written).

### Fix: deferred-frame read (plan §A2(a))

When the tap fires, **only set a flag and record the frame number.** Do NOT
read memory inside the callback. The frame notifier fires on the next frame
boundary; at that point:

1. The tapped write has committed to physical RAM.
2. Any CPU instructions following the tapped write have executed (including
   post-init driver code that sets other DP variables).

**Pattern (in frame notifier):**
```lua
-- Tap callback: flag only
function(offset, data, mask)
    if done then return end
    done      = true
    tap_frame = screen:frame_number()
    pcall(function() tap_ref[1]:remove() end)
    -- NO memory reads here
end

-- Frame notifier: deferred reads
if done and tap_frame > 0 and frame > tap_frame then
    tap_frame = -1  -- one-shot
    -- Read all state here — write has committed
    local val = mem:read_u8(tapped_addr)   -- now correct
    ...
end
```

**Applied in:**
- `tests/scripted/gfx_init_test.lua` — inline tap, deferred reads in notifier
- `harness/lib/coco3_capture.lua` — library `capture_at_write_tap()` defers
  to frame notifier via `cap.pending`/`cap.tap_frame` fields

### Critical pitfall for future harness authors

**Never read memory inside a write-tap callback.** The `data` parameter
gives the value being written (correct), but `mem:read_u8()` for ANY address
inside the callback may return stale values if the address is involved in the
current write transaction. Read all memory state from a frame notifier at or
after the next frame boundary.

---

## Frame-notifier reads (unaffected by defect)

`timer_framesync_test.lua` and `kernel_dispatch_test.lua` use only frame
notifiers (no write-taps). Their reads happen at a fixed frame offset after
binary execution; no tap timing issues apply. Their `confirmed` entries in
`mapping.json` were not affected by the write-tap defect.

---

## Capture output format

JSON files in `captures/` with schema:
```json
{
  "platform": "coco3",
  "trigger": {"type": "frame|write_tap", "value": N},
  "region": {"start": "0xXXXX", "end": "0xXXXX"},
  "frame": N,
  "bytes": ["0xXX", ...]
}
```

Identical to Apple II capture schema (platform field differs). `compare.py`
reads both sides for behavioral comparison.

---

## Cross-references

- Capture comparison: `verification/compare.py`, `verification/mapping.json`
- MAME invocation: each `run_*.sh` in `tests/scripted/`
- Boot context validation: `tests/scripted/gfx_init_precheck.lua`
