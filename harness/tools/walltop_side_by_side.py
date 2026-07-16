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
PAL = {'w': (255, 255, 255), 'b': (0, 0, 0)}
SKY = (25, 144, 255)
# Jay's gated post (w/b/t); rail = post col 3 (= horizontal bands: white rows 2&7, black rows 3&4)
POST = ["wbbt", "wbbt", "wbbw", "bbbb", "bbbb", "wbbt", "wbbt", "wbbw"]
RAIL = [r[3] for r in POST]

POST_ROW = 100                      # wall-top top row
BAND = (94, 116)                    # crop rows for the comparison
P2_PX, P3_PX, PW = 186, 270, 4      # byte 46/67 sub 2 -> px; post width 4
GAP0, GAP1 = P2_PX + PW, P3_PX      # rail span px [190, 270)


def port_preview():
    im = Image.new('RGB', (320, 192), SKY)
    px = im.load()
    def stamp_post(x0):
        for dy, row in enumerate(POST):
            for dx, c in enumerate(row):
                if c == 't':
                    continue
                px[x0 + dx, POST_ROW + dy] = PAL[c]
    stamp_post(P2_PX); stamp_post(P3_PX)               # post 1 (col-11) DROPPED
    for dy, c in enumerate(RAIL):                       # rail = horizontal bands across the gap
        if c == 't':
            continue
        for x in range(GAP0, GAP1):
            px[x, POST_ROW + dy] = PAL[c]
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
        d.text((2, yp - LBL), f"PORT placement PREVIEW: posts @px186/270 (byte46/67 sub2), rail fills,"
                              f" col-11 DROPPED  x{scale}", fill=(255, 255, 255))
        c.paste(prt.resize((320 * scale, bandH * scale), Image.NEAREST), (0, yp + RULER))
        ruler(yp)
        out = os.path.join(REPO, '..', 'build', 'walltop_ref', name)
        c.save(out); print("wrote", out, c.size)

    build(Z, 'walltop_oracle_vs_port_x%d.png' % Z)
    build(1, 'walltop_oracle_vs_port_1to1.png')


if __name__ == '__main__':
    main()
