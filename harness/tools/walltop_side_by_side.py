#!/usr/bin/env python3
"""
walltop_side_by_side.py — STANDING coordinate-reconciled oracle<->port wall-top comparison.
The grounded pixel-position tool this arc lacked. ONE coordinate system (CoCo3 320-px space);
integer NEAREST only; stacked (oracle top, port bottom) column-aligned + byte ruler; 1:1 + magnified.

COORDINATE MAPPING (stated on the image + in the report):
  Apple HGR is 280 logical px (7 px/byte); CoCo3 is 320 px (4 px/byte). Bridge = the established
  +20 centering: CoCo3_px = Apple_px + 20  ((320-280)/2). The native oracle square render is 280
  wide (560 MAME snap halved); pad it left by 20 (right by 20) -> 320, so Apple content lands at
  its CoCo3 column. Port target posts: byte 46/67, sub 2 -> px 46*4+2=186, 67*4+2=270 (== oracle
  cols 23/35 sh5 -> Apple 166/250 +20 = 186/270). Sub 2 is exactly what aligns them.

PORT side is a PLACEMENT PREVIEW (Python, not the built driver — placement blit is deferred to the
primitive dispatch): gated post art at px 186 & 270, rail fills between, spurious col-11 post DROPPED.
"""
import os, argparse
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..'))
PALI = [(0, 0, 0), (230, 111, 0), (25, 144, 255), (255, 255, 255)]   # coco3 4-index
BAND = (94, 116)                    # crop rows for the comparison


def port_preview():
    """Decode the ACTUAL variant framebuffer dump (build/logs/fb_wt.bin, 15360B, 2bpp) -> 320x192,
    so the port side is exactly what the driver renders (incl. any sub-byte edge artifact)."""
    p = os.path.join(REPO, '..', 'build', 'logs', 'fb_wt.bin')
    data = open(p, 'rb').read()
    im = Image.new('RGB', (320, 192))
    px = im.load()
    for row in range(192):
        for col in range(80):
            b = data[row * 80 + col]
            for k in range(4):
                px[col * 4 + k, row] = PALI[(b >> (6 - k * 2)) & 3]
    return im


def load_oracle_native():
    p = os.path.join(REPO, '..', 'build', 'walltop_ref', 'oracle_climb_anim06_square.png')
    im = Image.open(p).convert('RGB')
    if im.size != (280, 192):
        im = im.resize((280, 192), Image.NEAREST)      # de-scale to native 1:1
    # reconcile to CoCo3 320-space: pad +20 each side (Apple_px -> Apple_px+20)
    canv = Image.new('RGB', (320, 192), (18, 18, 18))
    canv.paste(im, (20, 0))
    return canv


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--zoom', type=int, default=8)
    args = ap.parse_args()
    y0, y1 = BAND
    orc = load_oracle_native().crop((0, y0, 320, y1))
    prt = port_preview().crop((0, y0, 320, y1))
    Z = args.zoom
    bandH = y1 - y0

    def build(scale, name):
        RULER, LBL, GAPY = 16, 16, 8
        W = 320 * scale
        H = LBL + RULER + bandH * scale + GAPY + LBL + bandH * scale + RULER + 6
        c = Image.new('RGB', (W, H), (28, 28, 28))
        d = ImageDraw.Draw(c)
        def ruler(y):
            for bx in range(0, 321, 4):                # CoCo3 byte boundaries (every 4px)
                x = bx * scale
                col = (90, 90, 90)
                if bx in (44, 45, 46, 47, 48, 66, 67, 68, 69):
                    col = (255, 90, 90)                # mark target byte cols 46 & 67
                d.line([(x, y), (x, y + RULER)], fill=col)
            d.text((2, y + 2), "byte grid (4px); red = target bytes 46 & 67 (sub 2 -> px186/270)",
                   fill=(200, 200, 200))
        yo = LBL
        d.text((2, 0), f"ORACLE apple2e wall-top (Apple 280 +20 -> CoCo3 320-space)  NEAREST x{scale}",
               fill=(255, 255, 255))
        c.paste(orc.resize((320 * scale, bandH * scale), Image.NEAREST), (0, yo + RULER))
        ruler(yo)
        yp = yo + RULER + bandH * scale + GAPY
        d.text((2, yp - LBL), f"PORT variant FRAMEBUFFER: posts byte46/67 sub2 (px186/270), rail fills,"
                              f" col-11 dropped  x{scale}", fill=(255, 255, 255))
        c.paste(prt.resize((320 * scale, bandH * scale), Image.NEAREST), (0, yp + RULER))
        ruler(yp)
        out = os.path.join(REPO, '..', 'build', 'walltop_ref', name)
        c.save(out); print("wrote", out, c.size)

    build(Z, 'walltop_oracle_vs_port_x%d.png' % Z)
    build(1, 'walltop_oracle_vs_port_1to1.png')

    # SEPARATE layers for overlay: identical geometry (same crop, same 320-space, same zoom) so
    # pixel (x,y) corresponds 1:1 between them. No labels/ruler baked in -> clean overlay.
    outdir = os.path.join(REPO, '..', 'build', 'walltop_ref')
    for name, img in (('walltop_LAYER_oracle', orc), ('walltop_LAYER_port', prt)):
        big = img.resize((320 * Z, bandH * Z), Image.NEAREST)
        p = os.path.join(outdir, f'{name}_x{Z}.png')
        big.save(p); print("wrote", p, big.size, "(rows %d-%d, CoCo3 320-space x%d)" % (y0, y1, Z))


if __name__ == '__main__':
    main()
