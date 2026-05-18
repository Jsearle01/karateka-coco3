#!/usr/bin/env bash
# tests/scripted/run_broderbund_presents_scene.sh
# Combined Brøderbund scene test: Logo 2 + Logo 1 + "presents" text.
# Static display — no delays, just draw everything and spin.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== Combined Brøderbund Presents Scene Test ==="
cd "$REPO_ROOT"

echo "--- Step 1: ASSEMBLE ---"
lwasm --decb \
    -o tests/scripted/broderbund_presents_scene_driver.bin \
    tests/scripted/broderbund_presents_scene_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/broderbund_presents_scene_driver.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tools/lib" "$CAPTURE_DIR/dumps"
cp tests/scripted/broderbund_presents_scene_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/broderbund_presents_scene_test.lua   "$CAPTURE_DIR/tools/"
cp tools/lib/framebuffer_dump.lua                      "$CAPTURE_DIR/tools/lib/"
echo "STAGE: done"

echo "--- Step 3: RUN (MAME CoCo3) ---"
echo "Jay: watch the MAME window."
echo "  Expect: Brøderbund logos at upper portion of screen"
echo "          'presents' text at row 110"
echo "  Logo 2 (wordmark): col=26, row=88"
echo "  Logo 1 (badge):    col=35, row=72"
echo "  presents:          byte cols 33-52, row 110"
mkdir -p build
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 35 \
    -autoboot_script tools\broderbund_presents_scene_test.lua" \
    > build/broderbund_presents_scene_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/broderbund_presents_scene_test.log" ] && \
    cp "$CAPTURE_DIR/tools/broderbund_presents_scene_test.log" build/ || true
for dump in "$CAPTURE_DIR/dumps/broderbund_presents_scene_shot"*.bin; do
    [ -f "$dump" ] && cp "$dump" build/ && echo "  collected $(basename "$dump")" || true
done

if [ -f build/broderbund_presents_scene_test.log ]; then
    echo "=== broderbund_presents_scene_test.log ==="
    cat build/broderbund_presents_scene_test.log
fi

if ls build/broderbund_presents_scene_shot*_frameA.bin 1>/dev/null 2>&1; then
    echo ""
    echo "=== Framebuffer decode ==="
    python3 tools/decode_framebuffer.py \
        build/broderbund_presents_scene_shot001_frameA.bin

    echo ""
    echo "=== Region: Logo 1 (rows 72-85, cols 35-44) ==="
    python3 tools/decode_framebuffer.py \
        build/broderbund_presents_scene_shot001_frameA.bin \
        --region 72,35,85,44

    echo ""
    echo "=== Region: Logo 2 (rows 88-97, cols 26-42) ==="
    python3 tools/decode_framebuffer.py \
        build/broderbund_presents_scene_shot001_frameA.bin \
        --region 88,26,97,42

    echo ""
    echo "=== Region: presents (rows 108-122, cols 30-55) ==="
    python3 tools/decode_framebuffer.py \
        build/broderbund_presents_scene_shot001_frameA.bin \
        --region 108,30,122,55
fi

echo ""
echo "=== Combined Scene Test COMPLETE ==="
