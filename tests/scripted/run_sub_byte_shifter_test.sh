#!/usr/bin/env bash
# tests/scripted/run_sub_byte_shifter_test.sh
# P2.4.1 sub-byte shifter unit test runner.
# Verifies HAL_gfx_blit_sprite runtime shift at subbytes 0, 1, 2, 3.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== P2.4.1 Sub-Byte Shifter Test ==="
cd "$REPO_ROOT"

echo "--- Step 1: ASSEMBLE ---"
lwasm --decb \
    -o tests/scripted/sub_byte_shifter_test_driver.bin \
    tests/scripted/sub_byte_shifter_test_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/sub_byte_shifter_test_driver.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tools/lib" "$CAPTURE_DIR/dumps"
cp tests/scripted/sub_byte_shifter_test_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/sub_byte_shifter_test.lua        "$CAPTURE_DIR/tools/"
cp tools/lib/framebuffer_dump.lua                  "$CAPTURE_DIR/tools/lib/"
echo "STAGE: done"

echo "--- Step 3: RUN (MAME CoCo3 — real speed) ---"
echo "Jay: watch the MAME window."
echo "  Expect 4 horizontal white bands at rows 20, 35, 50, 65."
echo "  Each band should be shifted 1 pixel further right than the previous:"
echo "    Row 20 (subbyte=0): left edge at pixel 40 (byte boundary)"
echo "    Row 35 (subbyte=1): left edge at pixel 41"
echo "    Row 50 (subbyte=2): left edge at pixel 42"
echo "    Row 65 (subbyte=3): left edge at pixel 43"
mkdir -p build
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 35 \
    -autoboot_script tools\sub_byte_shifter_test.lua" \
    > build/sub_byte_shifter_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/sub_byte_shifter_test.log" ] && \
    cp "$CAPTURE_DIR/tools/sub_byte_shifter_test.log" build/ || true
for dump in "$CAPTURE_DIR/dumps/sb_shifter_shot"*.bin; do
    [ -f "$dump" ] && cp "$dump" build/ && echo "  collected $(basename "$dump")" || true
done

if [ -f build/sub_byte_shifter_test.log ]; then
    echo "=== sub_byte_shifter_test.log ==="
    cat build/sub_byte_shifter_test.log
fi

if ls build/sb_shifter_shot*_frameA.bin 1>/dev/null 2>&1; then
    echo ""
    echo "=== Framebuffer decode — overall ==="
    python3 tools/decode_framebuffer.py build/sb_shifter_shot001_frameA.bin
    echo ""
    echo "=== Region: subbyte=0 (rows 20-27, cols 9-14) ==="
    python3 tools/decode_framebuffer.py build/sb_shifter_shot001_frameA.bin \
        --region 20,9,27,14
    echo ""
    echo "=== Region: subbyte=1 (rows 35-42, cols 9-14) ==="
    python3 tools/decode_framebuffer.py build/sb_shifter_shot001_frameA.bin \
        --region 35,9,42,14
    echo ""
    echo "=== Region: subbyte=2 (rows 50-57, cols 9-14) ==="
    python3 tools/decode_framebuffer.py build/sb_shifter_shot001_frameA.bin \
        --region 50,9,57,14
    echo ""
    echo "=== Region: subbyte=3 (rows 65-72, cols 9-14) ==="
    python3 tools/decode_framebuffer.py build/sb_shifter_shot001_frameA.bin \
        --region 65,9,72,14
fi

echo ""
echo "=== P2.4.1 Sub-Byte Shifter Test COMPLETE ==="
echo "Expected framebuffer byte values at byte col 10-12:"
echo "  subbyte=0: \$FF \$FF \$00  (no shift, no overflow)"
echo "  subbyte=1: \$3F \$FF \$C0  (2-bit shift)"
echo "  subbyte=2: \$0F \$FF \$F0  (4-bit shift)"
echo "  subbyte=3: \$03 \$FF \$FC  (6-bit shift)"
