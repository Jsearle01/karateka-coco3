#!/usr/bin/env bash
# tests/scripted/run_r_boot_trace.sh
# Execution trace run — normal throttle, diagnostic Lua.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== R-boot execution trace ==="
echo "$(date '+%Y-%m-%d %H:%M:%S')  binary: build/karateka.bin ($(wc -c < "$REPO_ROOT/build/karateka.bin") bytes)"
echo ""

cd "$REPO_ROOT"
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
mkdir -p "$CAPTURE_DIR/tools/lib" "$CAPTURE_DIR/tests"
cp build/karateka.bin                       "$CAPTURE_DIR/tests/"
cp tests/scripted/r_boot_trace.lua          "$CAPTURE_DIR/tools/"
cp tools/lib/framebuffer_dump.lua           "$CAPTURE_DIR/tools/lib/"
rm -f "$CAPTURE_DIR/tools/rboot_trace.log"
echo "Staged."

cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 30 \
    -autoboot_script tools\r_boot_trace.lua" \
    > build/logs/engine/trace_mame.log 2>&1 || true

echo ""
echo "--- Trace output ---"
if [ -f "$CAPTURE_DIR/tools/rboot_trace.log" ]; then
    cp "$CAPTURE_DIR/tools/rboot_trace.log" build/
    cat build/logs/engine/rboot_trace.log
else
    echo "No trace log produced — check build/logs/engine/trace_mame.log:"
    tail -20 build/logs/engine/trace_mame.log 2>/dev/null || true
fi
echo ""
echo "=== Trace done ==="
