#!/usr/bin/env bash
# tests/scripted/run_sys_init_test.sh
# P2.3a.0 HAL_sys_init behavioral test runner.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== P2.3a.0 HAL_sys_init test ==="
cd "$REPO_ROOT"

echo "--- Step 1: ASSEMBLE sys_init_driver ---"
lwasm --decb \
    -o tests/scripted/sys_init_driver.bin \
    tests/scripted/sys_init_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/sys_init_driver.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/captures" "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tests"
cp tests/scripted/sys_init_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/sys_init_test.lua   "$CAPTURE_DIR/tools/"
rm -f "$CAPTURE_DIR/tools/sysinittest_PASS" "$CAPTURE_DIR/tools/sysinittest_FAIL"
echo "STAGE: binary + Lua script staged"

echo "--- Step 3: RUN (MAME CoCo3) ---"
mkdir -p build
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window -nothrottle \
    -seconds_to_run 40 \
    -autoboot_script tools\sys_init_test.lua" \
    > build/logs/unit/sysinittest_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/sysinittest.log" ] && cp "$CAPTURE_DIR/tools/sysinittest.log" build/ || true

if [ -f "$CAPTURE_DIR/tools/sysinittest_PASS" ]; then
    echo "MAME TEST: PASS"
    grep -E "RESULT|CC_mask|FFA|DISPATCH" build/logs/unit/sysinittest.log 2>/dev/null | head -20 || true
elif [ -f "$CAPTURE_DIR/tools/sysinittest_FAIL" ]; then
    echo "MAME TEST: FAIL"
    cat build/logs/unit/sysinittest.log 2>/dev/null
    exit 1
else
    echo "MAME TEST: NO RESULT"
    tail -20 build/logs/unit/sysinittest_mame.log 2>/dev/null
    exit 1
fi
echo ""
echo "=== P2.3a.0 sys_init TEST DONE ==="
