#!/usr/bin/env bash
# tests/scripted/run_palette_test.sh
# P2.3a.6-followup-1 palette diagnostic runner.
# Displays 4 solid-color bands (one per palette index) for visual verification.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== Palette Diagnostic Test (4-band) ==="
cd "$REPO_ROOT"

echo "--- Step 1: ASSEMBLE ---"
lwasm --decb \
    -o tests/scripted/palette_test_driver.bin \
    tests/scripted/palette_test_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/palette_test_driver.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tools/lib" "$CAPTURE_DIR/dumps"
cp tests/scripted/palette_test_driver.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/palette_test.lua        "$CAPTURE_DIR/tools/"
cp tools/lib/framebuffer_dump.lua         "$CAPTURE_DIR/tools/lib/"
echo "STAGE: done"

echo "--- Step 3: RUN (MAME CoCo3 — real speed) ---"
echo "Jay: observe 4 horizontal bands on screen."
echo "  Band 0 (top quarter):    index 0 = \$FFB0=\$00 = expected BLACK"
echo "  Band 1 (2nd quarter):    index 1 = \$FFB1=\$26 = expected ORANGE"
echo "  Band 2 (3rd quarter):    index 2 = \$FFB2=\$1B = expected BLUE"
echo "  Band 3 (bottom quarter): index 3 = \$FFB3=\$3F = expected WHITE"
mkdir -p build
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 35 \
    -autoboot_script tools\palette_test.lua" \
    > build/logs/unit/palette_test_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/palette_test.log" ] && \
    cp "$CAPTURE_DIR/tools/palette_test.log" build/ || true
for dump in "$CAPTURE_DIR/dumps/palette_test_shot"*.bin; do
    [ -f "$dump" ] && cp "$dump" build/ && echo "  collected $(basename "$dump")" || true
done

[ -f build/logs/unit/palette_test.log ] && cat build/logs/unit/palette_test.log

if ls build/palette_test_shot*_frameA.bin 1>/dev/null 2>&1; then
    echo ""
    echo "=== Framebuffer decode ==="
    python3 tools/decode_framebuffer.py build/palette_test_shot001_frameA.bin
fi

echo "=== Palette Diagnostic Test COMPLETE ==="
echo "Framebuffer dump: build/palette_test_shot001_frameA.bin"
echo "  Expected: Band 0 rows 0-47 all idx-0; Band 1 rows 48-95 all idx-1;"
echo "            Band 2 rows 96-143 all idx-2; Band 3 rows 144-191 all idx-3"
