#!/usr/bin/env bash
# tests/scripted/run_broderbund_splash_test.sh
# P2.3a.6 Brøderbund splash test runner.
# Runs at REAL SPEED for Jay to observe logos on screen.
# Both Brøderbund logo sprites should be visible after driver loads.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== P2.3a.6 Broderbund Splash Test ==="
cd "$REPO_ROOT"

echo "--- Step 1: ASSEMBLE ---"
lwasm --decb \
    -o tests/scripted/broderbund_splash_driver.bin \
    tests/scripted/broderbund_splash_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/broderbund_splash_driver.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tools/lib" "$CAPTURE_DIR/dumps"
cp tests/scripted/broderbund_splash_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/broderbund_splash_test.lua   "$CAPTURE_DIR/tools/"
cp tools/lib/framebuffer_dump.lua              "$CAPTURE_DIR/tools/lib/"
echo "STAGE: done"

echo "--- Step 3: RUN (MAME CoCo3 — real speed for visual observation) ---"
echo "Jay: watch the MAME window."
echo "  Brøderbund logo (two elements) should appear on black screen."
echo "  Logo 2 (wider, 'Broderbund' text): row 88, byte col 26"
echo "  Logo 1 (narrower, 'B' mark):      row 72, byte col 35"
echo "  Colors: orange, blue, white pixels on black background."
echo "MAME will run for ~35 seconds total (5s BASIC boot + 30s observation)."
mkdir -p build
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 10 \
    -autoboot_script tools\broderbund_splash_test.lua" \
    > build/logs/scenes/broderbund_splash_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/broderbund_splash_test.log" ] && \
    cp "$CAPTURE_DIR/tools/broderbund_splash_test.log" build/ || true
for dump in "$CAPTURE_DIR/dumps/broderbund_splash_shot"*.bin; do
    [ -f "$dump" ] && cp "$dump" build/ && echo "  collected $(basename "$dump")" || true
done

if [ -f build/logs/scenes/broderbund_splash_test.log ]; then
    echo "=== broderbund_splash_test.log ==="
    cat build/logs/scenes/broderbund_splash_test.log
fi

if ls build/broderbund_splash_shot*_frameA.bin 1>/dev/null 2>&1; then
    echo ""
    echo "=== Framebuffer decode ==="
    python3 tools/decode_framebuffer.py build/broderbund_splash_shot001_frameA.bin
fi

echo ""
echo "=== P2.3a.6 Broderbund Splash Test COMPLETE ==="
echo "Review MAME screenshots in snap/coco3/ and verify V1-V4 predictions."
echo "Framebuffer dump: build/broderbund_splash_shot001_frameA.bin"
