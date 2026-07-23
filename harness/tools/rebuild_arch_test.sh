#!/usr/bin/env bash
# rebuild_arch_test.sh — regenerate the arch codegens from the LATEST tool edits, then assemble the
# standalone static arch test. Run this before every "rebuild and show" so stencils/placement can
# never be stale relative to content/scene6_placement.txt + the cels' opacity.s sidecars.
set -e
cd "$(dirname "$0")/../.."          # repo root

echo "--- regenerate the arch composite table + opacity stencils from current edits ---"
python harness/tools/gen_scene6_placement.py >/dev/null   # scene6_arch_gen.s (arch: table)
python harness/tools/gen_arch_opacity.py                   # scene6_arch_opacity_gen.s (opaque stencils)

echo "--- assemble the static arch test ---"
lwasm --decb -o tests/scripted/scene6_arch_test.bin tests/scripted/scene6_arch_test.s
ls -la tests/scripted/scene6_arch_test.bin | awk '{print "  scene6_arch_test.bin " $5 " bytes"}'
echo "OK — launch with:"
echo "  S_BIN=\$(pwd)/tests/scripted/scene6_arch_test.bin MONITOR=1 mame coco3 -rompath C:/mame/roms \\"
echo "    -window -nomaximize -prescale 3 -resolution 1280x960 -autoboot_script harness/tools/climb_live.lua"
