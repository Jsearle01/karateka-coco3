#!/usr/bin/env bash
# run_dmk_sweep.sh — reproduce the interleave sweep (INVESTIGATION: interleave
# realization in MAME). Builds the WORSTCASE unit, generates DMK fixtures at each
# interleave (tools/make_dmk_skew.sh), reads each in MAME with the decomposition
# harness, and prints load time + byte-for-byte correctness per interleave.
# Result (see docs/project/interleave-realization-mame.md): sequential (il=0/17) is
# optimal at ~10.66s (2.5x vs JVC 26.65s); interleave monotonically worsens it.
# Primitive UNCHANGED; prod byte-identical; .dmk gitignored.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
LWASM="${LWASM:-/c/WIN_LWTools/lwasm}"
MAME="${MAME:-/c/mame/mame.exe}"
ROMS="${ROMS:-/c/mame/roms}"
LUA="$ROOT/tests/scripted/disk_worstcase_decomp.lua"
mkdir -p "$ROOT/build/logs/unit"
"$LWASM" --decb -D WORSTCASE -I "$ROOT/src/hal/coco3-dsk" \
  -o "$ROOT/tests/scripted/disk_sandbox_wc.bin" "$ROOT/tests/scripted/disk_sandbox_driver.s"
echo "il  load_s   ms/trk  correctness"
for il in 0 1 2 4 6 9 13 17; do
  D="$ROOT/build/fixtures/worstcase_il$il.dmk"
  bash "$ROOT/tools/make_dmk_skew.sh" "$il" "$D" >/dev/null 2>&1
  LOG="$ROOT/build/logs/unit/decomp_dmk_il$il.log"
  DECOMP_SKEW="dmk-il$il" DECOMP_LOG="$LOG" \
    "$MAME" coco3 -ext fdc -flop1 "$D" -rompath "$ROMS" -window -nomaximize \
    -seconds_to_run 45 -autoboot_script "$LUA" -nothrottle >/dev/null 2>&1
  T=$(grep -oE "WHOLE-OP load time.*: [0-9.]+ s" "$LOG" | grep -oE "[0-9.]+" | head -1)
  MATCH=$(grep -c 'WC_MATCH\[\$2531\]=\$A5' "$LOG")
  printf "%-3s %-8s %-7s %s\n" "$il" "$T" "$(python3 -c "print('%.0f'%(float('${T:-0}')*1000/8))")" \
    "$([ "$MATCH" = 1 ] && echo 'byte-for-byte OK' || echo 'MISMATCH')"
done
echo "(sequential il=0/17 optimal; JVC baseline 26.65s; see docs/project/interleave-realization-mame.md)"
