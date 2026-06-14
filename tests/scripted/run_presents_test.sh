#!/usr/bin/env bash
# tests/scripted/run_presents_test.sh
# P2.3a.11 "presents" text test runner.
# Runs at REAL SPEED for Jay to observe "presents" text on screen.
# Eight glyphs (p-r-e-s-e-n-t-s) should appear at row 110.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== P2.3a.11 Presents Text Test ==="
cd "$REPO_ROOT"

echo "--- Step 1: ASSEMBLE ---"
lwasm --decb \
    -o tests/scripted/presents_test_driver.bin \
    tests/scripted/presents_test_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/presents_test_driver.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tools/lib" "$CAPTURE_DIR/dumps"
cp tests/scripted/presents_test_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/presents_test.lua        "$CAPTURE_DIR/tools/"
cp tools/lib/framebuffer_dump.lua          "$CAPTURE_DIR/tools/lib/"
echo "STAGE: done"

echo "--- Step 3: RUN (MAME CoCo3 — real speed for visual observation) ---"
echo "Jay: watch the MAME window."
echo "  'presents' text should appear at approximately row 110."
echo "  Eight letters: p-r-e-s-e-n-t-s"
echo "  Byte columns:  30,33,35,38,40,42,44,47"
echo "  Colors: white letter strokes with chromatic fringing on black background."
echo "MAME will run for ~35 seconds total (5s BASIC boot + 30s observation)."
mkdir -p build
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 35 \
    -autoboot_script tools\presents_test.lua" \
    > build/logs/scenes/presents_test_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/presents_test.log" ] && \
    cp "$CAPTURE_DIR/tools/presents_test.log" build/ || true
for dump in "$CAPTURE_DIR/dumps/presents_shot"*.bin; do
    [ -f "$dump" ] && cp "$dump" build/ && echo "  collected $(basename "$dump")" || true
done

if [ -f build/logs/scenes/presents_test.log ]; then
    echo "=== presents_test.log ==="
    cat build/logs/scenes/presents_test.log
fi

if ls build/presents_shot*_frameA.bin 1>/dev/null 2>&1; then
    echo ""
    echo "=== Framebuffer decode ==="
    python3 tools/decode_framebuffer.py build/presents_shot001_frameA.bin
    echo ""
    echo "=== Region: expected glyph area (rows 110-121, cols 30-51) ==="
    python3 tools/decode_framebuffer.py build/presents_shot001_frameA.bin \
        --region 110,30,121,51
fi

echo ""
echo "=== P2.3a.11 Presents Test COMPLETE ==="
echo "Framebuffer dump: build/presents_shot001_frameA.bin"
echo "Expected: 8 glyphs (p-r-e-s-e-n-t-s) at row 110, byte cols 30-47"
