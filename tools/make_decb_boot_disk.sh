#!/usr/bin/env bash
# make_decb_boot_disk.sh [out.dmk] — the raw-underlayer DECB boot disk (BUILD #3b-3).
# A DECB-format 1:1-sequential DMK whose DIRECTORY holds ONE LOADM-able file (BOOT.BIN =
# the 3b-2 bootloader, a DECB binary load/exec $8000), with the REAL game bulk laid as
# FAT-RESERVED raw tracks the bootloader reads by track/sector (NOT a DECB file — keeps
# the single-call/one-Restore load). Boot: BASIC -> LOADM"BOOT":EXEC -> bootloader ->
# reads game tracks 1-4 -> $0100 -> jmp $0200 -> render.
#
# Layout (verified, docs/project/decb-loadm-boot-gates.md):
#   granule 0 (track 0 s1-9) = BOOT.BIN (imgtool put, allocates lowest granule)
#   granules 2-9 (tracks 1-4) = raw game, FAT-RESERVED $C9 (G1: FREE/allocator honor FAT;
#     DIR ignores unowned granules) — CLEAR of track 17 (directory) per HS-4
#   track 17 = DECB directory + FAT (untouched)
# The game bytes = build/karateka.bin (88eba89, the payload — byte-identical, read-only).
set -euo pipefail
IMG="${IMGTOOL:-/c/mame/imgtool.exe}"
GAME="${GAME:-build/karateka.bin}"
BOOT="${BOOT:-tests/scripted/bootloader.bin}"
OUT="${1:-build/fixtures/boot_disk.dmk}"
GAME_TRACK=1; NTRACK=4; SPT=18
mkdir -p "$(dirname "$OUT")" build/tmp
# HS-4: game tracks must not span track 17
if [ $((GAME_TRACK+NTRACK-1)) -ge 17 ]; then echo "FATAL HS-4: game tracks $GAME_TRACK-$((GAME_TRACK+NTRACK-1)) span track 17"; exit 1; fi
rm -f "$OUT"
"$IMG" create coco_dmk_rsdos "$OUT" --tracks=35 --sectors=$SPT --sectorlength=256 --interleave=0 >/dev/null
"$IMG" put coco_dmk_rsdos "$OUT" "$BOOT" BOOT.BIN --ftype=binary >/dev/null   # -> granule 0 / track 0
# reserve the game granules (2 per track): tracks 1..4 -> granules (t*2)..(t*2+1)
"$IMG" readsector coco_dmk_rsdos "$OUT" 17 0 2 build/tmp/fat.bin >/dev/null
python3 - "$OUT" "$IMG" "$GAME" "$GAME_TRACK" "$NTRACK" "$SPT" <<'PY'
import sys, subprocess
out,img,game,gt,ntrack,spt = sys.argv[1],sys.argv[2],sys.argv[3],int(sys.argv[4]),int(sys.argv[5]),int(sys.argv[6])
# --- reserve granules for tracks gt..gt+ntrack-1 (granule g -> FAT offset g) ---
fat = bytearray(open("build/tmp/fat.bin","rb").read())
reserved=[]
for t in range(gt, gt+ntrack):
    for g in (t*2, t*2+1):
        fat[g] = 0xC9   # last-granule, 9 sectors (terminal; no dangling link) — G1 best practice
        reserved.append(g)
open("build/tmp/fat.bin","wb").write(fat)
subprocess.run([img,"writesector","coco_dmk_rsdos",out,"17","0","2","build/tmp/fat.bin"],check=True,
               stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
# --- lay the game contiguous from $0100, gaps=$00, onto tracks gt..gt+ntrack-1 (1:1) ---
BASE=0x0100; IMGLEN=ntrack*spt*256
d=open(game,'rb').read(); i=0; segs=[]; entry=None
while i<len(d):
    tb=d[i]
    if tb==0x00: n=(d[i+1]<<8)|d[i+2]; a=(d[i+3]<<8)|d[i+4]; segs.append((a,d[i+5:i+5+n])); i+=5+n
    elif tb==0xFF: entry=(d[i+3]<<8)|d[i+4]; break
    else: raise SystemExit("bad DECB")
mem=bytearray(IMGLEN)
for a,data in segs:
    off=a-BASE
    if off<0 or off+len(data)>IMGLEN: raise SystemExit(f"seg ${a:04X} outside image")
    mem[off:off+len(data)]=data
tmp="build/tmp/gsec.bin"
for k in range(ntrack):
    t=gt+k
    for s in range(1,spt+1):
        o=(k*spt+(s-1))*256
        open(tmp,'wb').write(mem[o:o+256])
        subprocess.run([img,"writesector","coco_dmk_rsdos",out,str(t),"0",str(s),tmp],check=True,
                       stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
lo=min(a for a,_ in segs); hi=max(a+len(x) for a,x in segs)
print(f"reserved granules {reserved} (tracks {gt}-{gt+ntrack-1}); game span ${lo:04X}-${hi-1:04X} entry ${entry:04X}")
PY
echo "=== DIR + FREE (consistency, AC-2) ==="; "$IMG" dir coco_dmk_rsdos "$OUT" 2>&1 | grep -E "BOOT|File|free"
echo "boot disk: $OUT ($(stat -c%s "$OUT") bytes, interleave=0, game tracks $GAME_TRACK-$((GAME_TRACK+NTRACK-1)))"
