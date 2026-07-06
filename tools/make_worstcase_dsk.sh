#!/usr/bin/env bash
# make_worstcase_dsk.sh — worst-case single scene-load fixture for BUILD
# #3b-1-REDUX. Bounds the max live loadable working set: 32 KB = 4 x 8 KB GIME
# blocks (the memory-structure target). The disk reads in WHOLE TRACKS (18
# sectors), not blocks, so cover the 32 KB / 4-block target with 8 WHOLE TRACKS
# (144 sectors = 36 KB) to keep the m=1 read clean (no deferred partial-track
# path, HS-4). Tracks 0-7 each carry a contiguous position-encoded pattern
#     byte[T][S][i] = (T*18 + (S-1) + i) & 0xFF
# where (T*18 + (S-1)) is the GLOBAL sector ordinal g (0..143), so any
# gap / dup / reorder across ANY of the 8 tracks is byte-detectable. This is
# 3b-1's chunk 0 (proven clean) at full worst-case SIZE — NOT the real karateka
# bytes (HS-7), read in ONE disk_read_range call (one Restore, HS-3). The .dsk
# output is gitignored (under build/); this generator is tracked.
# image offset for (T,S) on 35x18x256 = (T*18 + (S-1))*256.
set -euo pipefail
IMGTOOL="${IMGTOOL:-/c/mame/imgtool.exe}"
OUT="${1:-build/fixtures/worstcase_test.dsk}"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
"$IMGTOOL" create coco_jvc_rsdos "$OUT"
python3 - "$OUT" <<'PY'
import sys
out = sys.argv[1]
SPT    = 18
NTRACK = 8                          # 8 whole tracks = 144 sectors = 36 KB (covers 32 KB/4 blocks)
def off(track, sector):             # sector 1-based
    return (track*SPT + (sector-1))*256
with open(out, "r+b") as f:
    for t in range(NTRACK):         # tracks 0..7
        for s in range(1, SPT+1):
            g = t*SPT + (s-1)       # global sector ordinal 0..143
            f.seek(off(t, s))
            f.write(bytes((g + i) & 0xFF for i in range(256)))
    print(f"worst-case fixture: {NTRACK} whole tracks (0..{NTRACK-1}), {NTRACK*SPT} sectors "
          f"= {NTRACK*SPT*256} B (36 KB, covers 32 KB / 4x8KB blocks); "
          f"pattern byte[g][i]=(g+i)&0xFF (g=global sector ordinal)")
PY
echo "fixture: $OUT ($(stat -c%s "$OUT") bytes)"
