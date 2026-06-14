#!/usr/bin/env bash
# tests/scripted/run_prod_boot_visual.sh
# Visual verification run for IEN-fixed karateka.bin.
# NORMAL THROTTLE (no -nothrottle). No Lua harness callbacks after load.
# Expected visible sequence:
#   ~0-2.7 sec: Broderbund logos + "presents" visible
#   ~2.7-4.0 sec: blank screen (clear + 80-frame transition)
#   ~4.0 sec+: halted — window stays open until -seconds_to_run expires
set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/mnt/c/karateka-capture"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

echo "=== R-boot visual verification run ==="
echo "Timestamp : $TIMESTAMP"
echo "Binary    : build/karateka.bin"
echo "Throttle  : NORMAL (60 Hz real-time)"
echo "Duration  : 30 seconds"
echo ""
echo "Jay: watch the MAME window."
echo "  ~0-2.7 sec: Broderbund splash (logos + 'presents')"
echo "  ~2.7-4.0 sec: blank screen"
echo "  ~4.0 sec+: halted (blank)"
echo ""

# ---------------------------------------------------------------------------
# Stage
# ---------------------------------------------------------------------------
cd "$REPO_ROOT"
mkdir -p build/logs/engine build/logs/scenes build/logs/unit build/logs/snapshots
mkdir -p "$CAPTURE_DIR/tools" "$CAPTURE_DIR/tests"
cp build/karateka.bin                              "$CAPTURE_DIR/tests/"
cp tests/scripted/prod_boot_loader_minimal.lua     "$CAPTURE_DIR/tools/"

echo "Staged karateka.bin ($(wc -c < build/karateka.bin) bytes)"
echo "Running MAME..."
echo ""

# ---------------------------------------------------------------------------
# Run MAME — NORMAL THROTTLE (no -nothrottle), minimal Lua loader only
# ---------------------------------------------------------------------------
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms \
    -window \
    -seconds_to_run 30 \
    -autoboot_script tools\prod_boot_loader_minimal.lua" \
    > build/logs/scenes/visual_run.log 2>&1 || true

echo "MAME run complete."
echo ""
echo "Console output:"
cat build/logs/scenes/visual_run.log 2>/dev/null | head -20 || true
echo ""
echo "=== Visual run done. Jay: report what you observed. ==="
