#!/usr/bin/env bash
# tests/scripted/run_r_boot_debugtrace.sh
# Instruction-level trace run — MAME 0.281 -debug -debugscript.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"

echo "=== R-boot instruction-level trace ==="
echo "$(date '+%Y-%m-%d %H:%M:%S')  binary: build/karateka.bin ($(wc -c < "$REPO_ROOT/build/karateka.bin") bytes)"
echo "MAME 0.281  -debug -debugscript boot_trace_bpset.dbg"
echo ""

cd "$REPO_ROOT"
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
mkdir -p "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tests"
cp build/karateka.bin                              "$CAPTURE_DIR/tests/"
cp tests/scripted/r_boot_debugtrace.lua            "$CAPTURE_DIR/tools/"
cp tests/scripted/boot_trace_bpset.dbg             "$CAPTURE_DIR/tools/"
rm -f "$CAPTURE_DIR/tools/instrtrace.log"
echo "Staged."

cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 30 \
    -debug \
    -debugscript tools\boot_trace_bpset.dbg \
    -autoboot_script tools\r_boot_debugtrace.lua" \
    > build/logs/engine/debugtrace_mame.log 2>&1 || true

echo ""
echo "--- Trace result ---"
if [ -f "$CAPTURE_DIR/tools/instrtrace.log" ]; then
    cp "$CAPTURE_DIR/tools/instrtrace.log" build/
    echo "instrtrace.log: $(wc -l < build/logs/engine/instrtrace.log) lines"
    echo ""
    echo "--- First 120 lines ---"
    head -120 build/logs/engine/instrtrace.log
    echo ""
    echo "--- Last 60 lines ---"
    tail -60 build/logs/engine/instrtrace.log
else
    echo "No trace log produced — check build/logs/engine/debugtrace_mame.log:"
    tail -20 build/logs/engine/debugtrace_mame.log 2>/dev/null || true
fi
echo ""
echo "=== Trace done ==="
