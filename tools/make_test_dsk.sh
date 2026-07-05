#!/usr/bin/env bash
# make_test_dsk.sh — generate the disk-read sandbox fixture (tracked generator;
# the .dsk output is gitignored under build/). Creates a 35x18x256 DD RSDOS disk
# and pokes the incrementing pattern byte[i]=i at track 2 / sector 5.
#   image offset for (T,S) on 35x18x256 = (T*18 + (S-1))*256
set -euo pipefail
IMGTOOL="${IMGTOOL:-/c/mame/imgtool.exe}"
OUT="${1:-build/fixtures/disk_test.dsk}"
TRACK=2 ; SECTOR=5
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
"$IMGTOOL" create coco_jvc_rsdos "$OUT"
python3 - "$OUT" "$TRACK" "$SECTOR" <<'PY'
import sys
out, track, sector = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
off = (track*18 + (sector-1))*256
data = bytes(range(256))
with open(out, "r+b") as f:
    f.seek(off); f.write(data)
print(f"poked 256-byte pattern at track {track} sector {sector} (offset {off})")
PY
echo "fixture: $OUT ($(stat -c%s "$OUT") bytes)"
