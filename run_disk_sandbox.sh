#!/usr/bin/env bash
# run_disk_sandbox.sh — build + run the HALT disk-read sandbox.
# Two configs against one fixture:
#   (default)   Build #1/#2 + off-end correction regressions.
#   (READJUMP)  Build #3a read-and-jump, in a CLEAN FDC state (a separate build so
#               MAME's coco_fdc m=1-after-Restore-sequence state quirk does not mask
#               the mechanism). Prod karateka.bin is NOT touched (standalone unit).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
LWASM="${LWASM:-/c/WIN_LWTools/lwasm}"
MAME="${MAME:-/c/mame/mame.exe}"
ROMS="${ROMS:-/c/mame/roms}"
FIX="$ROOT/build/fixtures/disk_test.dsk"
LOG="$ROOT/build/logs/unit/disk_sandbox.log"
SRC="$ROOT/tests/scripted/disk_sandbox_driver.s"
BIN="$ROOT/tests/scripted/disk_sandbox.bin"
LUA="$ROOT/tests/scripted/disk_sandbox.lua"
mkdir -p "$ROOT/build/logs/unit"
echo "--- fixture ---"; bash "$ROOT/tools/make_test_dsk.sh" "$FIX"
run() { "$MAME" coco3 -ext fdc -flop1 "$FIX" -rompath "$ROMS" -window -nomaximize \
        -seconds_to_run 34 -autoboot_script "$LUA" -nothrottle >/dev/null 2>&1; }

echo "=== (default) regressions ==="
"$LWASM" --decb -I "$ROOT/src/hal/coco3-dsk" -o "$BIN" "$SRC"
run; grep -E "single-sector|RANGE|OFF-END" "$LOG"
grep -q 'PASS\[\$2200\]=\$A5' "$LOG" && grep -q 'RANGE PASS\[\$2206\]=\$A5' "$LOG" \
  && echo "REGRESSIONS: PASS" || { echo "REGRESSIONS: FAIL"; exit 1; }

echo "=== (READJUMP) read-and-jump ==="
"$LWASM" --decb -D READJUMP -I "$ROOT/src/hal/coco3-dsk" -o "$BIN" "$SRC"
run; grep -E "guard|JUMP proof|payload" "$LOG"
grep -q 'signature \$2500=\$CAFE' "$LOG" && grep -q 'guard\[\$220B\]=\$A5' "$LOG" \
  && echo "READ-AND-JUMP: PASS" || { echo "READ-AND-JUMP: FAIL"; exit 1; }
