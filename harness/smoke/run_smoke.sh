#!/bin/bash
# harness/smoke/run_smoke.sh — CoCo3 smoke test runner.
# Stages Lua script to C:\karateka-capture\tools\, launches MAME via
# cmd.exe (same pattern as karateka_dissasembly_claude smoke test),
# then retrieves result sentinels.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"
LUA_SRC="$REPO_ROOT/harness/smoke/smoke_test.lua"

PASS_WIN="$CAPTURE_DIR/tools/coco3_smoke_PASS"
FAIL_WIN="$CAPTURE_DIR/tools/coco3_smoke_FAIL"
LOG_WIN="$CAPTURE_DIR/tools/coco3_smoke.log"

echo "[run_smoke] karateka-coco3 P1.1 smoke test"
echo "[run_smoke] staging Lua script..."

cp "$LUA_SRC" "$CAPTURE_DIR/tools/coco3_smoke_test.lua"
rm -f "$PASS_WIN" "$FAIL_WIN"

echo "[run_smoke] launching CoCo3 under MAME..."
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -nothrottle \
    -seconds_to_run 10 \
    -autoboot_script tools\coco3_smoke_test.lua" > /dev/null 2>&1 || true

# Retrieve results
[ -f "$LOG_WIN" ] && cp "$LOG_WIN" "$REPO_ROOT/harness/smoke/last-run.log" || true

if [ -f "$PASS_WIN" ]; then
    [ -f "$LOG_WIN" ] && grep -E "PASS|FAIL|snapshot|EXIT" "$LOG_WIN" | sed 's/^/  /' || true
    echo "[run_smoke] PASS"
    exit 0
else
    echo "[run_smoke] FAILURE"
    [ -f "$REPO_ROOT/harness/smoke/last-run.log" ] && cat "$REPO_ROOT/harness/smoke/last-run.log" || true
    exit 1
fi
