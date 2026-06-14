#!/usr/bin/env bash
# tests/scripted/run_sprite_engine_princess.sh
# Princess controller sandbox — the scene-5 walk-in, isolated.
# Builds by LINKING the REAL engine + controller + HAL (single source); boot.s
# is NOT in this build (boot-excluded, AC-7). Automated pass = -nothrottle
# pr_leg/pr_x trace + 2 static snapshots. Live AC-5/AC-6 gate is a separate
# throttled invocation (printed below).
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/c/karateka-capture"
[ -d "$CAPTURE_DIR" ] || CAPTURE_DIR="/mnt/c/karateka-capture"
cd "$REPO_ROOT"

echo "=== Princess controller sandbox (walk-in) ==="
echo "--- Step 1: ASSEMBLE (real engine + controller + HAL, include build) ---"
lwasm --decb -o tests/scripted/sprite_engine_princess.bin tests/scripted/sprite_engine_princess_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/sprite_engine_princess.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools"
cp tests/scripted/sprite_engine_princess.bin "$CAPTURE_DIR/tests/"
cp tests/scripted/princess_trace.lua         "$CAPTURE_DIR/tools/"
cp tests/scripted/princess_live.lua          "$CAPTURE_DIR/tools/" 2>/dev/null || true
rm -f "$CAPTURE_DIR/princess_trace.log"

echo "--- Step 3: RUN (MAME coco3, -nothrottle: pr_leg/pr_x trace + snapshots) ---"
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
cmd.exe /c "cd /d C:\\karateka-capture && C:\\mame\\mame.exe coco3 \
    -rompath C:\\mame\\roms -window -nothrottle \
    -seconds_to_run 20 \
    -autoboot_script tools\\princess_trace.lua" \
    > build/logs/engine/princess_mame.log 2>&1 || true

echo "--- Step 4: COLLECT ---"
[ -f "$CAPTURE_DIR/princess_trace.log" ] && cp "$CAPTURE_DIR/princess_trace.log" build/logs/engine/ || true
if [ -f build/logs/engine/princess_trace.log ]; then
    echo "=== princess_trace.log ==="
    cat build/logs/engine/princess_trace.log
fi

echo ""
echo "=== LIVE AC-5/AC-6 GATE (Jay, real 60fps) ==="
echo "Watch the walk-in (motion + colors); close the window when done:"
echo "  cmd.exe /c \"cd /d C:\\karateka-capture && C:\\mame\\mame.exe coco3 \\"
echo "      -rompath C:\\mame\\roms -window \\"
echo "      -autoboot_script tools\\princess_live.lua\""
echo "=== princess sandbox COMPLETE ==="
