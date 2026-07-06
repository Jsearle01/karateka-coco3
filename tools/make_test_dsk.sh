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
    # (2) multi-track: the LAST two tracks (33-34), all sectors; ordinal k across
    #     the range. At the disk edge so the advance-bound test reads real data
    #     tracks then crosses off-end (track 35) — no blank-track m=1 read.
    START = 33; NTRACK = 2
    for t in range(START, START+NTRACK):
        for s in range(1, SPT+1):
            k = (t-START)*SPT + (s-1)          # 0..35
            f.seek(off(t,s))
            f.write(bytes((k+i) & 0xFF for i in range(256)))
    # (3) Build #3a read-and-jump payload: tracks 5-6 (whole-track-aligned).
    #     First bytes = a 6809 stub (loaded at $3000) that PROVES IT RAN:
    #       ldd #$CAFE ; std $2500 ; lda #$A5 ; sta $2502 ; bra * (halt at $300B)
    #     rest = $EE filler (so the whole-payload load is byte-verifiable).
    STUB = bytes([0xCC,0xCA,0xFE, 0xFD,0x25,0x00, 0x86,0xA5, 0xB7,0x25,0x02, 0x20,0xFE])
    PSTART = 5; PNTRACK = 2
    payload = STUB + bytes([0xEE]) * (PNTRACK*SPT*256 - len(STUB))
    f.seek(off(PSTART,1)); f.write(payload)
    print(f"single-sector @T2/S5 (off {off(2,5)}); range tracks {START}-{START+NTRACK-1} "
          f"({NTRACK*SPT} sectors, off {off(START,1)}..{off(START+NTRACK-1,SPT)+255})")
    print(f"read-and-jump payload @tracks {PSTART}-{PSTART+PNTRACK-1} (off {off(PSTART,1)}), "
          f"stub {len(STUB)}B + $EE filler = {len(payload)}B")
PY
echo "fixture: $OUT ($(stat -c%s "$OUT") bytes)"
