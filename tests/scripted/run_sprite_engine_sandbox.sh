#!/usr/bin/env bash
# tests/scripted/run_sprite_engine_sandbox.sh
# R-engine sprite/animation sandbox runner.
# Builds by LINKING THE REAL ENGINE + REAL HAL (single source); boot.s is
# NOT in this build (AC-5: boot-excluded). Automated pass uses -nothrottle
# for the P2 static snapshot + P3 memory trace (eng_idx/page_register
# cadence + flip). Live P4 gate is a separate throttled invocation (below).
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== R-engine sprite/animation sandbox ==="
cd "$REPO_ROOT"

echo "--- Step 1: ASSEMBLE (real engine + real HAL, single-file include build) ---"
lwasm --decb -o tests/scripted/sprite_engine_trace.bin   tests/scripted/sprite_engine_trace_driver.s   2>&1
lwasm --decb -o tests/scripted/sprite_engine_sandbox.bin tests/scripted/sprite_engine_sandbox_driver.s 2>&1
echo "ASSEMBLE: PASS (sandbox $(wc -c < tests/scripted/sprite_engine_sandbox.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools"
cp tests/scripted/sprite_engine_trace.bin        "$CAPTURE_DIR/tests/"
cp tests/scripted/sprite_engine_sandbox.bin      "$CAPTURE_DIR/tests/"
cp tests/scripted/sprite_engine_sandbox.lua      "$CAPTURE_DIR/tools/"
cp tests/scripted/sprite_engine_sandbox_live.lua "$CAPTURE_DIR/tools/"
rm -f "$CAPTURE_DIR/tools/sprite_engine_sandbox.log"
echo "STAGE: done"

echo "--- Step 3: RUN (MAME CoCo3, -nothrottle: automated P2/P3 trace) ---"
mkdir -p build
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window -nothrottle \
    -seconds_to_run 14 \
    -autoboot_script tools\sprite_engine_sandbox.lua" \
    > build/sprite_engine_sandbox_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/tools/sprite_engine_sandbox.log" ] && cp "$CAPTURE_DIR/tools/sprite_engine_sandbox.log" build/ || true
if [ -f build/sprite_engine_sandbox.log ]; then
    echo "=== sprite_engine_sandbox.log ==="
    cat build/sprite_engine_sandbox.log
fi

echo ""
echo "=== LIVE P4 GATE (Jay, real-time) ==="
echo "Run interactively to watch the animation + single-step (tap any key):"
echo "  cmd.exe /c \"cd /d C:\\karateka-capture && C:\\mame\\mame.exe coco3 \\"
echo "      -rompath C:\\mame\\roms -window \\"
echo "      -autoboot_script tools\\sprite_engine_sandbox_live.lua\""
echo "(No -nothrottle = real 60fps. Close the MAME window when done.)"
echo "=== R-engine sandbox COMPLETE ==="
