#!/usr/bin/env bash
# tests/scripted/run_scene5_composite.sh
# SCENE-5 throne stage + composite layer (the STATIC guard). Builds the throne
# module + the scene-5 composite (guard) by include; boot-excluded (AC-6).
# Live AC-5 gate is the throttled invocation printed below.
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/c/karateka-capture"; [ -d "$CAPTURE_DIR" ] || CAPTURE_DIR="/mnt/c/karateka-capture"
cd "$REPO_ROOT"; export PATH="$PATH:/c/WIN_LWTools"
echo "--- ASSEMBLE (throne module + scene-5 composite/guard) ---"
lwasm --decb -o tests/scripted/scene5_composite.bin tests/scripted/scene5_composite_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/scene5_composite.bin) bytes)"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools"
cp tests/scripted/scene5_composite.bin "$CAPTURE_DIR/tests/"
cp tools/comp_live.lua tools/comp_snap.lua "$CAPTURE_DIR/tools/" 2>/dev/null || true
echo ""
echo "=== LIVE AC-5 GATE (Jay): -prescale 3 ==="
echo "  cmd.exe /c \"cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \\"
echo "      -rompath C:\mame\roms -window -prescale 3 -resolution 1920x1152 \\"
echo "      -autoboot_script tools\comp_live.lua\""
echo "=== scene-5 composite COMPLETE ==="
