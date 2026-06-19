#!/usr/bin/env bash
# tests/scripted/run_princess_gate2.sh
# SCENE-5 1b GATE 2 — the princess arc back half (throne->cell transition +
# door-triggered turn + collapse). Builds by LINKING the real engine +
# controller + HAL + the gated throne & cell stages; boot-excluded (AC-6).
# Automated pass = the clock/phase/transition trace + snapshots. Live AC-5
# gate is the throttled invocation printed below.
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CAPTURE_DIR="/c/karateka-capture"; [ -d "$CAPTURE_DIR" ] || CAPTURE_DIR="/mnt/c/karateka-capture"
cd "$REPO_ROOT"; export PATH="$PATH:/c/WIN_LWTools"
echo "--- ASSEMBLE (engine + controller + HAL + throne + cell stages) ---"
lwasm --decb -o tests/scripted/princess_gate2.bin tests/scripted/princess_gate2_driver.s 2>&1
echo "ASSEMBLE: PASS ($(wc -c < tests/scripted/princess_gate2.bin) bytes)"
mkdir -p "$CAPTURE_DIR/tests" "$CAPTURE_DIR/tools"
cp tests/scripted/princess_gate2.bin "$CAPTURE_DIR/tests/"
cp tools/gate2_trace.lua tools/gate2_live.lua "$CAPTURE_DIR/tools/" 2>/dev/null || true
echo "--- RUN (clock/phase/transition trace + snapshots) ---"
cmd.exe /c "cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \
    -rompath C:\mame\roms -window -nothrottle -seconds_to_run 62 \
    -autoboot_script tools\gate2_trace.lua" > /dev/null 2>&1 || true
[ -f "$CAPTURE_DIR/gate2.log" ] && { echo "=== gate2.log ==="; cat "$CAPTURE_DIR/gate2.log"; }
echo ""
echo "=== LIVE AC-5 GATE (Jay): -speed 4 -prescale 3 ==="
echo "  cmd.exe /c \"cd /d C:\karateka-capture && C:\mame\mame.exe coco3 \\"
echo "      -rompath C:\mame\roms -window -prescale 3 -resolution 1920x1152 -speed 4 \\"
echo "      -autoboot_script tools\gate2_live.lua\""
echo "=== Gate 2 COMPLETE ==="
