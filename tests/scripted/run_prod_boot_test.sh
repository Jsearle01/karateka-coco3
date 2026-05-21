#!/usr/bin/env bash
# tests/scripted/run_prod_boot_test.sh
# R-boot production boot integration test runner.
# Loads build/karateka.bin; verifies Broderbund scene + real-VBL timing.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== R-boot production boot integration test ==="

# ---------------------------------------------------------------------------
# Step 1: Build production binary
# ---------------------------------------------------------------------------
echo "--- Step 1: BUILD ---"
cd "$REPO_ROOT"
make karateka.bin 2>&1
echo "BUILD: PASS ($(wc -c < build/karateka.bin) bytes)"

# ---------------------------------------------------------------------------
# Step 2: Stage files
# ---------------------------------------------------------------------------
echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tests"
cp build/karateka.bin              "$CAPTURE_DIR/tests/"
cp tests/scripted/prod_boot_test.lua "$CAPTURE_DIR/tools/"
rm -f "$CAPTURE_DIR/tools/prod_boot_test.log"
echo "STAGE: karateka.bin + Lua script staged"

# ---------------------------------------------------------------------------
# Step 3: Run under MAME (~18 seconds: 300 boot + 900 observe frames)
# ---------------------------------------------------------------------------
echo "--- Step 3: RUN (MAME CoCo3) ---"
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window -nothrottle \
    -seconds_to_run 18 \
    -autoboot_script tools\prod_boot_test.lua" \
    > build/prod_boot_mame.log 2>&1 || true

# ---------------------------------------------------------------------------
# Step 4: Collect results
# ---------------------------------------------------------------------------
echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/prod_boot_test.log" ] && \
    cp "$CAPTURE_DIR/tools/prod_boot_test.log" build/ || true

if [ -f "build/prod_boot_test.log" ]; then
    grep -E "PASS|FAIL|counter-rate|SCREENSHOT|page_register|elapsed" \
        build/prod_boot_test.log 2>/dev/null || true
    echo "=== R-boot MAME TEST COMPLETE ==="
else
    echo "NO RESULT (check build/prod_boot_mame.log)"
    cat build/prod_boot_mame.log 2>/dev/null | tail -20
    exit 1
fi
