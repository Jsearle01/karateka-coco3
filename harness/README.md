# karateka-coco3 test harness

MAME-based test harness for the CoCo3 port. Three rigor levels:

| Level    | Status              | Purpose                              |
|----------|---------------------|--------------------------------------|
| smoke    | ACTIVE (P1.1)       | Boot test; minimum viability         |
| demo     | scaffolding         | Automated playback through known paths |
| scripted | scaffolding         | Frame-accurate test scenarios        |

## Running the smoke test

    ./harness/smoke/run_smoke.sh

Exit code 0 = PASS; non-zero = FAIL.

Verified: CoCo3 boots to Color BASIC at $A7D5 (PC in $8000-$FFFF
at frame 300). MAME v0.281, driver `coco3`.

See `harness/lib/coco3_primitives.lua` for reusable Lua
instrumentation primitives.

## Requirements

- MAME v0.281 at `C:\MAME\mame.exe`
- CoCo3 ROMs at `C:\mame\roms\` (`coco3.zip` with `coco3.rom`)
  FDC extension ROMs optional; not needed for boot test
- Staging directory: `C:\karateka-capture\` (must exist)
- WSL2 environment with `cmd.exe` accessible

## Adding new tests

1. Choose rigor level (smoke/demo/scripted) based on scope
2. Add `.lua` script using primitives from `harness/lib/`
3. Add `run_<test>.sh` wrapper following `run_smoke.sh` pattern
4. Update this README's test inventory

## Pattern source

Adapted from `../karateka_dissasembly_claude/scripts/smoke_test.sh`
(three-step build + byte-identity + boot test; Apple II).
P1.1 uses boot-test pattern only; build and byte-identity steps
added in later phases when game binary exists.
