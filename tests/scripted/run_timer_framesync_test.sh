#!/usr/bin/env bash
# tests/scripted/run_timer_framesync_test.sh
# P2.1 timer/frame-sync behavioral test runner.
# Loads the assembled test binary into CoCo3 via MAME, captures DP
# state, and verifies the behavioral predictions from the TASK 5 gate.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== P2.1 timer/frame-sync test ==="

# ---------------------------------------------------------------------------
# Step 1: Assemble the test driver
# ---------------------------------------------------------------------------
echo "--- Step 1: ASSEMBLE ---"
cd "$REPO_ROOT"
lwasm --decb \
    -I src/engine -I src/hal/coco3-dsk \
    -o tests/scripted/timer_framesync_driver.bin \
    tests/scripted/timer_framesync_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/timer_framesync_driver.bin) bytes)"

# ---------------------------------------------------------------------------
# Step 2: Stage files to C:\karateka-capture
# ---------------------------------------------------------------------------
echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/captures" "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tests"
cp tests/scripted/timer_framesync_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/timer_framesync_test.lua  "$CAPTURE_DIR/tools/"
rm -f "$CAPTURE_DIR/tools/tftest_PASS" "$CAPTURE_DIR/tools/tftest_FAIL"
echo "STAGE: binary + Lua script staged"

# ---------------------------------------------------------------------------
# Step 3: Run under MAME
# ---------------------------------------------------------------------------
echo "--- Step 3: RUN (MAME CoCo3) ---"
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window -nothrottle \
    -seconds_to_run 5 \
    -autoboot_script tools\timer_framesync_test.lua" \
    > build/tftest_mame.log 2>&1 || true

# ---------------------------------------------------------------------------
# Step 4: Collect results
# ---------------------------------------------------------------------------
echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/tftest.log" ] && cp "$CAPTURE_DIR/tools/tftest.log" build/ || true
for json in "$CAPTURE_DIR/captures/p2_1a_coco3_"*.json; do
    [ -f "$json" ] && cp "$json" captures/ && echo "  $(basename "$json")" || true
done

if [ -f "$CAPTURE_DIR/tools/tftest_PASS" ]; then
    echo "MAME TEST: PASS"
    cat build/tftest.log 2>/dev/null | grep -E "RESULT|DP\$|invariant" || true
elif [ -f "$CAPTURE_DIR/tools/tftest_FAIL" ]; then
    echo "MAME TEST: FAIL"
    cat build/tftest.log 2>/dev/null
    exit 1
else
    echo "MAME TEST: NO RESULT (check build/tftest_mame.log)"
    cat build/tftest_mame.log 2>/dev/null | tail -20
    exit 1
fi

echo ""
echo "=== P2.1 MAME TEST: PASS ==="
