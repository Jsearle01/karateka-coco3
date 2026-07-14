#!/usr/bin/env python3
"""
render_square.py — STANDING square-pixel (1:1, no aspect stretch) PNG renderer for
oracle-vs-port visual matching. Fixes the stretched-render problem: MAME renders apple2e
at 560x192 (each logical HGR dot = 2 horizontal pixels -> ~2.9:1, badly stretched); the
native HGR framebuffer is 280x192. This tool emits 1:1 square-pixel PNGs at native
logical resolution, optionally uniform integer-scaled (NO fractional scaling).

  --apple2e <560x192.png>   -> halve width to native 280x192 (recovers doubled columns),
                               square pixels. (560 is 280 doubled: ~97% identical col-pairs.)
  --coco3 <15360-byte dump> -> decode 2bpp MSB-first (80 bytes/row x 192) to 320x192.

  --scale N (default 1)      -> uniform integer upscale (NEAREST); pixels stay square.
  --out PATH

Palette (shared so oracle/port are color-consistent for by-eye match; = MAME apple2e):
  0 black (0,0,0)  1 orange (230,111,0)  2 blue (25,144,255)  3 white (255,255,255)
Pixel aspect is 1:1 LOGICAL (not 4:3 hardware-corrected) — the same convention both targets,
so a feature at apple2e px X lines up with coco3 px X (+20 port centering).
"""
import argparse, sys
from PIL import Image

PAL = [(0, 0, 0), (230, 111, 0), (25, 144, 255), (255, 255, 255)]
COCO3_COLS = 80      # bytes/row
COCO3_ROWS = 192
COCO3_W = COCO3_COLS * 4   # 320 logical px


def coco3_dump_to_img(path):
    data = open(path, 'rb').read()
    need = COCO3_COLS * COCO3_ROWS
    if len(data) < need:
        sys.exit(f"coco3 dump too small: {len(data)} < {need}")
    img = Image.new('RGB', (COCO3_W, COCO3_ROWS))
    px = img.load()
    for row in range(COCO3_ROWS):
        for col in range(COCO3_COLS):
            b = data[row * COCO3_COLS + col]
            for p in range(4):
                idx = (b >> (6 - p * 2)) & 3
                px[col * 4 + p, row] = PAL[idx]
    return img


def apple2e_snap_to_img(path):
    im = Image.open(path).convert('RGB')
    W, H = im.size
    if W % 2 != 0:
        sys.exit(f"apple2e snap width {W} not even; expected 560 (280 doubled)")
    # halve width: take the left column of each pair (they are ~identical); box-resize
    # would blend NTSC fringes, NEAREST at half preserves the logical dot.
    return im.resize((W // 2, H), Image.NEAREST)


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--coco3', metavar='DUMP')
    g.add_argument('--apple2e', metavar='PNG560')
    ap.add_argument('--scale', type=int, default=1)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    img = coco3_dump_to_img(a.coco3) if a.coco3 else apple2e_snap_to_img(a.apple2e)
    native = img.size
    if a.scale != 1:
        img = img.resize((img.width * a.scale, img.height * a.scale), Image.NEAREST)
    img.save(a.out)
    print(f"wrote {a.out}  native={native[0]}x{native[1]} (1:1 square)  "
          f"output={img.size[0]}x{img.size[1]} (scale x{a.scale})")


if __name__ == '__main__':
    main()
