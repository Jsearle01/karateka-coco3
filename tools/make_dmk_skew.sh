#!/usr/bin/env bash
# make_dmk_skew.sh <interleave> [output.dmk] — worst-case 8-track fixture as a DMK
# image with a CHOSEN physical sector INTERLEAVE (imgtool coco_dmk_rsdos --interleave,
# 0-17). Same position-encoded payload as the JVC worstcase fixture
#     byte[g][i] = (g + i) & 0xFF     where g = track*18 + (sector-1)  (global ordinal)
# written by logical sector ID via `writesector`, so the m=1 read (IDs 1..18/track) and
# its byte-for-byte verify are IDENTICAL across interleaves (HS-4/HS-5: interleave is
# latency-only). ONLY the physical angular placement of each ID changes with --interleave.
# .dmk output is gitignored; this generator is tracked. INVESTIGATION probe — no primitive
# change, no prod change.
set -euo pipefail
IL="${1:?usage: make_dmk_skew.sh <interleave 0-17> [out.dmk]}"
OUT="${2:-build/fixtures/worstcase_il${IL}.dmk}"
IMG="${IMGTOOL:-/c/mame/imgtool.exe}"
NTRACK=8; SPT=18
mkdir -p "$(dirname "$OUT")" build/tmp
rm -f "$OUT"
"$IMG" create coco_dmk_rsdos "$OUT" --tracks=35 --sectors=$SPT --sectorlength=256 --interleave="$IL" >/dev/null
python3 - "$OUT" "$IMG" "$NTRACK" "$SPT" <<'PY'
import sys, subprocess
out, img, ntrack, spt = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
tmp = "build/tmp/sec.bin"
for t in range(ntrack):
    for s in range(1, spt+1):
        g = t*spt + (s-1)
        open(tmp, "wb").write(bytes((g+i) & 0xFF for i in range(256)))
        subprocess.run([img, "writesector", "coco_dmk_rsdos", out, str(t), "0", str(s), tmp],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(f"populated {ntrack} tracks x {spt} sectors (g=track*18+(s-1), byte[g][i]=(g+i)&0xFF)")
PY
echo "DMK fixture: $OUT (interleave=$IL, $(stat -c%s "$OUT") bytes)"
