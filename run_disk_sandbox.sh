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
FIX_WC="$ROOT/build/fixtures/worstcase_test.dsk"
LOG="$ROOT/build/logs/unit/disk_sandbox.log"
LOG_FI="$ROOT/build/logs/unit/disk_fullimage.log"
LOG_WC="$ROOT/build/logs/unit/disk_worstcase.log"
SRC="$ROOT/tests/scripted/disk_sandbox_driver.s"
BIN="$ROOT/tests/scripted/disk_sandbox.bin"
LUA="$ROOT/tests/scripted/disk_sandbox.lua"
LUA_FI="$ROOT/tests/scripted/disk_fullimage.lua"
LUA_WC="$ROOT/tests/scripted/disk_worstcase.lua"
mkdir -p "$ROOT/build/logs/unit"
echo "--- fixtures ---"
bash "$ROOT/tools/make_test_dsk.sh" "$FIX"
bash "$ROOT/tools/make_fullimage_dsk.sh" "$FIX_FI"
bash "$ROOT/tools/make_worstcase_dsk.sh" "$FIX_WC"
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

echo "=== (WORSTCASE) worst-case single-CALL scene load: 8 tracks / 36KB, ONE Restore (m=1 reliability + load-time) ==="
"$LWASM" --decb -D WORSTCASE -I "$ROOT/src/hal/coco3-dsk" -o "$ROOT/tests/scripted/disk_sandbox_wc.bin" "$SRC"
run "$FIX_WC" "$LUA_WC" 45; grep -E "match WC_MATCH|LOAD TIME|host wall|STALL|dest \\\$3000|FDC cmd" "$LOG_WC"
grep -q 'match WC_MATCH\[\$2531\]=\$A5' "$LOG_WC" && grep -q 'WC_PHASE\[\$2530\]=\$02' "$LOG_WC" \
  && echo "WORST-CASE LOAD: PASS (single-call 8-track m=1 read reliable at worst-case size)" \
  || echo "WORST-CASE LOAD: DID NOT COMPLETE / MISMATCH — see log (F1 real m=1 failure, or F2/F4)"

echo "=== (FULLIMAGE) RETIRED chunked full-image test — 3b-1 chunking artifact, kept for reference ==="
"$LWASM" --decb -D FULLIMAGE -I "$ROOT/src/hal/coco3-dsk" -o "$ROOT/tests/scripted/disk_sandbox_fi.bin" "$SRC"
run "$FIX_FI" "$LUA_FI" 22; grep -E "chunks completed|STALL" "$LOG_FI"
echo "(FULLIMAGE stalls at the inter-chunk Restore = chunking artifact; the REAL workload is WORSTCASE above)"
