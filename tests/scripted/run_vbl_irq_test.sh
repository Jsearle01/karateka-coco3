#!/usr/bin/env bash
# tests/scripted/run_vbl_irq_test.sh
# R-vbl VBL IRQ test runner.
# Verifies real GIME VBL interrupt fires at ~60 Hz after opt-in.
# X5 V-counter-rate, V-mem-read, V-cc-trace, V-monotonic.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== R-vbl VBL IRQ test ==="

# ---------------------------------------------------------------------------
# Step 1: Assemble the test driver
# ---------------------------------------------------------------------------
echo "--- Step 1: ASSEMBLE ---"
cd "$REPO_ROOT"
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
lwasm --decb \
    -o tests/scripted/vbl_irq_test_driver.bin \
    tests/scripted/vbl_irq_test_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/vbl_irq_test_driver.bin) bytes)"

# ---------------------------------------------------------------------------
# Step 2: Stage files
# ---------------------------------------------------------------------------
echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tests"
cp tests/scripted/vbl_irq_test_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/vbl_irq_test.lua        "$CAPTURE_DIR/tools/"
# Stage framebuffer_dump lib (required by dofile at top of test script)
cp tools/lib/framebuffer_dump.lua         "$CAPTURE_DIR/tools/lib/" 2>/dev/null || \
    mkdir -p "$CAPTURE_DIR/tools/lib" && \
    cp tools/lib/framebuffer_dump.lua "$CAPTURE_DIR/tools/lib/" 2>/dev/null || true
rm -f "$CAPTURE_DIR/tools/vbltest_PASS" "$CAPTURE_DIR/tools/vbltest_FAIL"
echo "STAGE: binary + Lua script staged"

# ---------------------------------------------------------------------------
# Step 3: Run under MAME (~65 seconds: 300 boot + 65 measurement frames)
# ---------------------------------------------------------------------------
echo "--- Step 3: RUN (MAME CoCo3) ---"
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window -nothrottle \
    -seconds_to_run 15 \
    -autoboot_script tools\vbl_irq_test.lua" \
    > build/logs/unit/vbltest_mame.log 2>&1 || true

# ---------------------------------------------------------------------------
# Step 4: Collect results
# ---------------------------------------------------------------------------
echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/vbltest.log" ] && cp "$CAPTURE_DIR/tools/vbltest.log" build/ || true

if [ -f "$CAPTURE_DIR/tools/vbltest_PASS" ]; then
    echo "MAME TEST: PASS"
    grep -E "PASS|FAIL|delta|counter|FF90|010C|sys_init" build/logs/unit/vbltest.log 2>/dev/null || true
elif [ -f "$CAPTURE_DIR/tools/vbltest_FAIL" ]; then
    echo "MAME TEST: FAIL"
    cat build/logs/unit/vbltest.log 2>/dev/null
    exit 1
else
    echo "MAME TEST: NO RESULT (check build/logs/unit/vbltest_mame.log)"
    cat build/logs/unit/vbltest_mame.log 2>/dev/null | tail -20
    exit 1
fi

echo ""
echo "=== R-vbl MAME TEST: PASS ==="
