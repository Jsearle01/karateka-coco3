#!/usr/bin/env bash
# tests/scripted/run_visual_smoke_test.sh
# P2.3a.5 visual smoke test runner.
# Runs at REAL SPEED (no -nothrottle) so Jay can observe animation.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== P2.3a.5 Visual Smoke Test ==="
cd "$REPO_ROOT"

echo "--- Step 1: ASSEMBLE ---"
lwasm --decb \
    -o tests/scripted/visual_smoke_driver.bin \
    tests/scripted/visual_smoke_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/visual_smoke_driver.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools"
cp tests/scripted/visual_smoke_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/visual_smoke_test.lua   "$CAPTURE_DIR/tools/"
echo "STAGE: done"

echo "--- Step 3: RUN (MAME CoCo3 — REAL SPEED for visual observation) ---"
echo "Jay: watch the MAME window for alternating white squares."
echo "MAME will run for ~25 seconds total (5s BASIC boot + 20s observation)."
mkdir -p build
# NOTE: -nothrottle intentionally OMITTED so animation is visible in real time
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 30 \
    -autoboot_script tools\visual_smoke_test.lua" \
    > build/smoketest_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/smoketest.log" ] && cp "$CAPTURE_DIR/tools/smoketest.log" build/ || true

if [ -f build/smoketest.log ]; then
    echo "=== smoketest.log ==="
    cat build/smoketest.log
fi

echo ""
echo "=== P2.3a.5 Visual Smoke Test COMPLETE ==="
echo "Review smoketest.log and MAME screenshots in snap/coco3/"
