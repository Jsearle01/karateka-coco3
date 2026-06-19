#!/usr/bin/env bash
# tests/scripted/run_princess_gate1.sh
# SCENE-5 1b GATE 1 — princess walk-in composited on the THRONE stage, driving
# the REAL scene clock ($3B analog). Builds by LINKING the real engine +
# controller + HAL + the gated 1a throne stage (scene5_throne_stage.s); boot.s
# is NOT in this build (boot-excluded, AC-5). Automated pass = the $3B-drive
# trace (HS-1) + 3 snapshots (stand / mid-walk / at-the-doorway). The LIVE
# AC-4 visual gate is the throttled invocation printed at the end.
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/c/karateka-capture"
[ -d "$CAPTURE_DIR" ] || CAPTURE_DIR="/mnt/c/karateka-capture"
cd "$REPO_ROOT"
export PATH="$PATH:/c/WIN_LWTools"

echo "=== Scene-5 1b Gate 1 (princess walk-in on the throne stage) ==="
echo "--- Step 1: ASSEMBLE (real engine + controller + HAL + throne stage) ---"
lwasm --decb -o tests/scripted/princess_gate1.bin tests/scripted/princess_gate1_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/princess_gate1.bin) bytes)"

echo "--- Step 2: STAGE ---"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools"
cp tests/scripted/princess_gate1.bin "$CAPTURE_DIR/tests/"
cp tools/gate1_trace.lua "$CAPTURE_DIR/tools/" 2>/dev/null || true
cp tools/gate1_snap.lua  "$CAPTURE_DIR/tools/" 2>/dev/null || true
cp tools/gate1_live.lua  "$CAPTURE_DIR/tools/" 2>/dev/null || true

echo "--- Step 3: RUN (MAME coco3, -nothrottle: the \$3B-drive trace, HS-1) ---"
cmd.exe /c "cd /d C:\\karateka-capture && C:\\mame\\mame.exe coco3 \
    -rompath C:\\mame\\roms -window -nothrottle -seconds_to_run 44 \
    -autoboot_script tools\\gate1_trace.lua" > /dev/null 2>&1 || true
[ -f "$CAPTURE_DIR/gate1.log" ] && { echo "=== \$3B-drive trace (gate1.log) ==="; cat "$CAPTURE_DIR/gate1.log"; }

echo ""
echo "=== LIVE AC-4 GATE (Jay, real 60fps; -prescale 3 for a 3x window) ==="
echo "  cmd.exe /c \"cd /d C:\\karateka-capture && C:\\mame\\mame.exe coco3 \\"
echo "      -rompath C:\\mame\\roms -window -prescale 3 -resolution 1920x1152 \\"
echo "      -autoboot_script tools\\gate1_live.lua\""
echo "  (add -speed 2 to fast-forward the oracle-cadence walk for viewing)"
echo "=== Gate 1 COMPLETE ==="
