#!/usr/bin/env bash
# make_fullimage_dsk.sh — full-image-SIZED fixture for BUILD #3b-1 (m=1
# compatibility + load-time AT SCALE). 32 of 35 tracks carry data (matches the
# space-budget recon: docs/project/fdc-read-primitive.md:259). Tracks 0-31 each
# carry a position-encoded pattern
#     byte[T][S][i] = (T*18 + (S-1) + i) & 0xFF
# where (T*18 + (S-1)) is the GLOBAL sector ordinal g (0..575), so any
# gap / dup / reorder across ANY track boundary is byte-detectable. Tracks 32-34
# are left blank (the 3 non-data tracks). This is the full-image SIZE, NOT the
# real karateka bytes (HS-4) — it isolates the long-read compatibility + timing
# question. The .dsk output is gitignored (under build/); this generator is
# tracked. image offset for (T,S) on 35x18x256 = (T*18 + (S-1))*256.
set -euo pipefail
IMGTOOL="${IMGTOOL:-/c/mame/imgtool.exe}"
OUT="${1:-build/fixtures/fullimage_test.dsk}"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
"$IMGTOOL" create coco_jvc_rsdos "$OUT"
python3 - "$OUT" <<'PY'
import sys
out = sys.argv[1]
SPT   = 18
NDATA = 32                          # 32 of 35 tracks carry data (space-budget recon)
def off(track, sector):             # sector 1-based
    return (track*SPT + (sector-1))*256
with open(out, "r+b") as f:
    for t in range(NDATA):          # tracks 0..31
        for s in range(1, SPT+1):
            g = t*SPT + (s-1)       # global sector ordinal 0..575
            f.seek(off(t, s))
            f.write(bytes((g + i) & 0xFF for i in range(256)))
    print(f"full-image fixture: {NDATA} data tracks (0..{NDATA-1}), {NDATA*SPT} sectors, "
          f"pattern byte[g][i]=(g+i)&0xFF (g=global sector ordinal); tracks {NDATA}..34 blank")
PY
echo "fixture: $OUT ($(stat -c%s "$OUT") bytes)"
