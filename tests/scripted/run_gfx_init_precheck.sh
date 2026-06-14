#!/usr/bin/env bash
# tests/scripted/run_gfx_init_precheck.sh
# §2.2 pre-binary validation — P2.3a remediation attempt 2.
# Boots CoCo3 to BASIC-ready state WITHOUT loading any binary.
# Confirms post-BASIC ZP and MMU state is suitable for gfx_init_driver.bin.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== P2.3a pre-binary BASIC-state validation ==="
cd "$REPO_ROOT"

echo "--- STAGE ---"
mkdir -p "$CAPTURE_DIR/tools"
cp tests/scripted/gfx_init_precheck.lua "$CAPTURE_DIR/tools/"
rm -f "$CAPTURE_DIR/tools/gfxprecheck_PASS" "$CAPTURE_DIR/tools/gfxprecheck_FAIL"
echo "STAGE: gfx_init_precheck.lua staged"

echo "--- RUN (MAME CoCo3, no binary) ---"
mkdir -p build
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window -nothrottle \
    -seconds_to_run 40 \
    -autoboot_script tools\gfx_init_precheck.lua" \
    > build/logs/unit/gfxprecheck_mame.log 2>&1 || true

echo "--- COLLECT ---"
[ -f "$CAPTURE_DIR/tools/gfxprecheck.log" ] && cp "$CAPTURE_DIR/tools/gfxprecheck.log" build/ || true

if [ -f "$CAPTURE_DIR/tools/gfxprecheck_PASS" ]; then
    echo "PRE-CHECK: PASS"
    grep -E "RESULT|BASIC-ready|FFA|FF91|FF90" build/logs/unit/gfxprecheck.log 2>/dev/null || true
elif [ -f "$CAPTURE_DIR/tools/gfxprecheck_FAIL" ]; then
    echo "PRE-CHECK: FAIL"
    cat build/logs/unit/gfxprecheck.log 2>/dev/null
    exit 1
else
    echo "PRE-CHECK: NO RESULT"
    tail -20 build/logs/unit/gfxprecheck_mame.log 2>/dev/null
    exit 1
fi

echo ""
echo "=== P2.3a PRE-CHECK DONE ==="
