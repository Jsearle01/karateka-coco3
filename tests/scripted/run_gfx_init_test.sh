#!/usr/bin/env bash
# tests/scripted/run_gfx_init_test.sh
# P2.3a HAL graphics init behavioral test runner.
# Assembles gfx_init_driver.bin, stages to C:\karateka-capture,
# runs under MAME CoCo3, and collects results.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== P2.3a HAL gfx_init test ==="

# ---------------------------------------------------------------------------
# Step 1: Assemble the test driver
# ---------------------------------------------------------------------------
echo "--- Step 1: ASSEMBLE ---"
cd "$REPO_ROOT"
lwasm --decb \
    -o tests/scripted/gfx_init_driver.bin \
    tests/scripted/gfx_init_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/gfx_init_driver.bin) bytes)"

# ---------------------------------------------------------------------------
# Step 2: Stage files to C:\karateka-capture
# ---------------------------------------------------------------------------
echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/captures" "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tests"
cp tests/scripted/gfx_init_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/gfx_init_test.lua   "$CAPTURE_DIR/tools/"
rm -f "$CAPTURE_DIR/tools/gfxtest_PASS" "$CAPTURE_DIR/tools/gfxtest_FAIL"
echo "STAGE: binary + Lua script staged"

# ---------------------------------------------------------------------------
# Step 3: Run under MAME
# ---------------------------------------------------------------------------
echo "--- Step 3: RUN (MAME CoCo3) ---"
mkdir -p build
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window -nothrottle \
    -seconds_to_run 40 \
    -autoboot_script tools\gfx_init_test.lua" \
    > build/logs/unit/gfxtest_mame.log 2>&1 || true

# ---------------------------------------------------------------------------
# Step 4: Collect results
# ---------------------------------------------------------------------------
echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/gfxtest.log" ] && cp "$CAPTURE_DIR/tools/gfxtest.log" build/ || true
for json in "$CAPTURE_DIR/captures/p2_3a_coco3_"*.json; do
    [ -f "$json" ] && cp "$json" captures/ && echo "  $(basename "$json")" || true
done

if [ -f "$CAPTURE_DIR/tools/gfxtest_PASS" ]; then
    echo "MAME TEST: PASS"
    grep -E "RESULT|DP\$|frame_count|\$8000|\$BBFF|\$C000|\$FBFF" build/logs/unit/gfxtest.log 2>/dev/null || true
elif [ -f "$CAPTURE_DIR/tools/gfxtest_FAIL" ]; then
    echo "MAME TEST: FAIL"
    cat build/logs/unit/gfxtest.log 2>/dev/null
    exit 1
else
    echo "MAME TEST: NO RESULT (check build/logs/unit/gfxtest_mame.log)"
    tail -20 build/logs/unit/gfxtest_mame.log 2>/dev/null
    exit 1
fi

echo ""
echo "=== P2.3a MAME TEST: PASS ==="
