#!/usr/bin/env bash
# run_disk_sandbox.sh — build + run the HALT disk-read sandbox (BUILD #1).
# Generates the DD test fixture, assembles the standalone sandbox, runs it in
# MAME against the fixture, and reports the PASS/status/NMI/RNF results.
# Prod karateka.bin is NOT touched (standalone unit).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
LWASM="${LWASM:-/c/WIN_LWTools/lwasm}"
MAME="${MAME:-/c/mame/mame.exe}"
ROMS="${ROMS:-/c/mame/roms}"
FIX="$ROOT/build/fixtures/disk_test.dsk"
LOG="$ROOT/build/logs/unit/disk_sandbox.log"
mkdir -p "$ROOT/build/logs/unit"
echo "--- fixture ---";  bash "$ROOT/tools/make_test_dsk.sh" "$FIX"
echo "--- assemble ---"; "$LWASM" --decb -I "$ROOT/src/hal/coco3-dsk" \
    -o "$ROOT/tests/scripted/disk_sandbox.bin" "$ROOT/tests/scripted/disk_sandbox_driver.s"
echo "--- MAME run ---"
"$MAME" coco3 -ext fdc -flop1 "$FIX" -rompath "$ROMS" -window -nomaximize \
    -seconds_to_run 20 -autoboot_script "$ROOT/tests/scripted/disk_sandbox.lua" -nothrottle >/dev/null 2>&1
echo "--- result ($LOG) ---"; cat "$LOG"
grep -q 'PASS\[\$2200\]=\$A5' "$LOG" && echo "SANDBOX: PASS" || { echo "SANDBOX: FAIL"; exit 1; }
