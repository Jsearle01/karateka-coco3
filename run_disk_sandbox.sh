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
FIX_FI="$ROOT/build/fixtures/fullimage_test.dsk"
LOG="$ROOT/build/logs/unit/disk_sandbox.log"
LOG_FI="$ROOT/build/logs/unit/disk_fullimage.log"
SRC="$ROOT/tests/scripted/disk_sandbox_driver.s"
BIN="$ROOT/tests/scripted/disk_sandbox.bin"
LUA="$ROOT/tests/scripted/disk_sandbox.lua"
LUA_FI="$ROOT/tests/scripted/disk_fullimage.lua"
mkdir -p "$ROOT/build/logs/unit"
echo "--- fixtures ---"
bash "$ROOT/tools/make_test_dsk.sh" "$FIX"
bash "$ROOT/tools/make_fullimage_dsk.sh" "$FIX_FI"
# run <fixture> <lua> <seconds_to_run>
run() { "$MAME" coco3 -ext fdc -flop1 "$1" -rompath "$ROMS" -window -nomaximize \
        -seconds_to_run "${3:-34}" -autoboot_script "$2" -nothrottle >/dev/null 2>&1; }

echo "=== (default) regressions ==="
"$LWASM" --decb -I "$ROOT/src/hal/coco3-dsk" -o "$BIN" "$SRC"
run "$FIX" "$LUA"; grep -E "single-sector|RANGE|OFF-END" "$LOG"
grep -q 'PASS\[\$2200\]=\$A5' "$LOG" && grep -q 'RANGE PASS\[\$2206\]=\$A5' "$LOG" \
  && echo "REGRESSIONS: PASS" || { echo "REGRESSIONS: FAIL"; exit 1; }

echo "=== (READJUMP) read-and-jump ==="
"$LWASM" --decb -D READJUMP -I "$ROOT/src/hal/coco3-dsk" -o "$BIN" "$SRC"
run "$FIX" "$LUA"; grep -E "guard|JUMP proof|payload" "$LOG"
grep -q 'signature \$2500=\$CAFE' "$LOG" && grep -q 'guard\[\$220B\]=\$A5' "$LOG" \
  && echo "READ-AND-JUMP: PASS" || { echo "READ-AND-JUMP: FAIL"; exit 1; }

echo "=== (FULLIMAGE) full-image-sized single-session multi-read (m=1 compat + load-time) ==="
"$LWASM" --decb -D FULLIMAGE -I "$ROOT/src/hal/coco3-dsk" -o "$ROOT/tests/scripted/disk_sandbox_fi.bin" "$SRC"
run "$FIX_FI" "$LUA_FI" 22; grep -E "chunks completed|LOAD TIME|host wall|STALL|FDC cmd" "$LOG_FI"
grep -q 'FI_DONE\[\$2521\]=8 of 8' "$LOG_FI" && grep -q 'match FI_MATCH\[\$2522\]=\$A5' "$LOG_FI" \
  && echo "FULL-IMAGE READ: PASS (m=1 survives a full-image read in one session)" \
  || echo "FULL-IMAGE READ: DID NOT COMPLETE — compatibility finding (see log; 25.3-H divergence)"
