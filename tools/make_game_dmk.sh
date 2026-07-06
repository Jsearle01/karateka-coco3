#!/usr/bin/env bash
# make_game_dmk.sh [out.dmk] — lay the REAL prod game image (build/karateka.bin,
# 88eba89..., the PAYLOAD — byte-identical, read-only) on raw 1:1-SEQUENTIAL DMK
# tracks for the boot loader (BUILD #3b-2). The game is 3 DECB segments
# ($0100/18B, $0200/8238B, $223E/9702B) spanning $0100-$4823; this builds the
# CONTIGUOUS memory image from $0100 (each segment placed at addr-$0100, inter-
# segment gaps = $00 — they are stack/scratch/pad, not loaded by DECB either),
# padded to whole tracks (4 tracks = 72 sectors = 18432 B -> $0100-$48FF), and
# writes it by logical sector ID (writesector) onto a --interleave=0 DMK (the
# validated fast layout). The boot loader single-call m=1 reads tracks 0-3 into
# $0100. NO DECB directory/FAT/LOADM (next build). .dmk gitignored; game unchanged.
set -euo pipefail
IMG="${IMGTOOL:-/c/mame/imgtool.exe}"
GAME="${GAME:-build/karateka.bin}"
OUT="${1:-build/fixtures/game.dmk}"
BASE=0x0100; NTRACK=4; SPT=18
mkdir -p "$(dirname "$OUT")" build/tmp
rm -f "$OUT"
"$IMG" create coco_dmk_rsdos "$OUT" --tracks=35 --sectors=$SPT --sectorlength=256 --interleave=0 >/dev/null
python3 - "$OUT" "$IMG" "$GAME" "$NTRACK" "$SPT" <<'PY'
import sys, subprocess
out, img, game, ntrack, spt = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5])
BASE = 0x0100
IMGLEN = ntrack*spt*256                       # 18432
d = open(game,'rb').read()
# parse DECB segments
i=0; segs=[]; entry=None
while i < len(d):
    t=d[i]
    if t==0x00:
        n=(d[i+1]<<8)|d[i+2]; a=(d[i+3]<<8)|d[i+4]; segs.append((a,d[i+5:i+5+n])); i=i+5+n
    elif t==0xFF:
        entry=(d[i+3]<<8)|d[i+4]; break
    else: raise SystemExit("bad DECB byte")
mem = bytearray(IMGLEN)                        # contiguous image from $0100, gaps=$00
for a,data in segs:
    off = a-BASE
    if off < 0 or off+len(data) > IMGLEN: raise SystemExit(f"seg ${a:04X} outside image")
    mem[off:off+len(data)] = data
# write by logical sector: track t sector s (1-based) -> image[(t*spt+(s-1))*256 ..]
tmp="build/tmp/gsec.bin"
for t in range(ntrack):
    for s in range(1, spt+1):
        o=(t*spt+(s-1))*256
        open(tmp,'wb').write(mem[o:o+256])
        subprocess.run([img,"writesector","coco_dmk_rsdos",out,str(t),"0",str(s),tmp],
                       check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
lo=min(a for a,_ in segs); hi=max(a+len(x) for a,x in segs)
print(f"game: {len(segs)} segs, span ${lo:04X}-${hi-1:04X}, entry ${entry:04X}; "
      f"laid {ntrack} tracks ($0100-${BASE+IMGLEN-1:04X}) 1:1 DMK")
PY
echo "game DMK: $OUT ($(stat -c%s "$OUT") bytes, interleave=0)"
