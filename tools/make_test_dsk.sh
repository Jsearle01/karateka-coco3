#!/usr/bin/env bash
# make_test_dsk.sh — generate the disk-read sandbox fixture (tracked generator;
# the .dsk output is gitignored under build/). 35x18x256 DD RSDOS disk with:
#   (1) Build #1 single-sector pattern  byte[i]=i         at track 2 / sector 5
#   (2) Build #2 multi-track pattern     byte[k][i]=(k+i)  across tracks 5-6
#       (k = 0-based sector ordinal across the range; first byte of sector k = k,
#        so any gap / dup / reorder across the TRACK BOUNDARY is detectable).
#   image offset for (T,S) on 35x18x256 = (T*18 + (S-1))*256
set -euo pipefail
IMGTOOL="${IMGTOOL:-/c/mame/imgtool.exe}"
OUT="${1:-build/fixtures/disk_test.dsk}"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
"$IMGTOOL" create coco_jvc_rsdos "$OUT"
python3 - "$OUT" <<'PY'
import sys
out = sys.argv[1]
SPT = 18
def off(track, sector):        # sector 1-based
    return (track*SPT + (sector-1))*256
with open(out, "r+b") as f:
    # (1) single-sector regression: track 2 / sector 5, byte[i]=i
    f.seek(off(2,5)); f.write(bytes(range(256)))
    # (2) multi-track: tracks 5 and 6, all sectors; ordinal k across the range
    START = 5; NTRACK = 2
    for t in range(START, START+NTRACK):
        for s in range(1, SPT+1):
            k = (t-START)*SPT + (s-1)          # 0..35
            f.seek(off(t,s))
            f.write(bytes((k+i) & 0xFF for i in range(256)))
    print(f"single-sector @T2/S5 (off {off(2,5)}); range tracks {START}-{START+NTRACK-1} "
          f"({NTRACK*SPT} sectors, off {off(START,1)}..{off(START+NTRACK-1,SPT)+255})")
PY
echo "fixture: $OUT ($(stat -c%s "$OUT") bytes)"
