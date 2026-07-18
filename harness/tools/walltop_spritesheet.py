#!/usr/bin/env python3
"""
walltop_spritesheet.py — render the candidate TOP-OF-WALL cels on a sky-blue background
so Jay can identify which are posts / rails / floor / etc. Each cel is decoded from its
converted.s (CoCo3 4-color) and drawn with index-0 (black) TRANSPARENT to the sky-blue
sheet, so the sprite's real shape shows. PNG is a diagnostic artifact for Jay's review.
"""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
from PIL import Image, ImageDraw

import sys as _sys
SKY  = (105, 170, 255)          # sky-blue sheet background
OPAQUE = ('--opaque' in _sys.argv)   # black shown solid (else transparent to sky)
BLACK0 = (0, 0, 0) if OPAQUE else SKY
PAL  = {0: BLACK0, 1: (255, 140, 0), 2: (0, 0, 255), 3: (255, 255, 255)}
SCALE = 6

# (label, converted.s path) — the top-of-wall candidates + a couple of neighbours.
CANDS = [
    ("AA23 post",  "content/scenery/scene6_cliff_AA23/converted.s"),
    ("AA31 post",  "content/scenery/scene6_cliff_AA31/converted.s"),
    ("AB94 rail",  "content/scenery/scene6_cliff_AB94/converted.s"),
    ("AB7C rail",  "content/scenery/scene6_cliff_AB7C/converted.s"),
    ("AB4A rail",  "content/scenery/scene6_cliff_AB4A/converted.s"),
    ("AB8E strip", "content/scenery/scene6_cliff_AB8E/converted.s"),
    ("AA7D base",  "content/scenery/scene6_cliff_AA7D/converted.s"),
    ("AA11 floor", "content/background/scene6_bg_AA11/converted.s"),
    ("AA23 fl.blk","content/background/scene6_bg_AA23/converted.s"),
    ("AA31 bg",    "content/background/scene6_bg_AA31/converted.s"),
]


def decode(path):
    h = w = None; rows = []
    for line in open(path, encoding='utf-8', errors='replace'):
        m = re.search(r'fcb\s+(\d+),(\d+)\s*;\s*height', line)
        if m: h, w = int(m.group(1)), int(m.group(2)); continue
        m = re.search(r'fcb\s+([$0-9A-Fa-f,]+)\s*;\s*row', line)
        if m and w:
            vals = [int(x.strip().lstrip('$'), 16) for x in m.group(1).split(',') if x.strip()]
            px = []
            for byte in vals:
                for p in range(4): px.append((byte >> (6 - p * 2)) & 3)
            rows.append(px[:w * 4])
    return (w * 4 if w else 0), h, rows


def render(path):
    wpx, h, rows = decode(path)
    if not rows or not wpx: return None, 0, 0
    im = Image.new('RGB', (wpx, h), SKY)
    for y, row in enumerate(rows):
        for x, v in enumerate(row[:wpx]):
            im.putpixel((x, y), PAL.get(v, (255, 0, 255)))
    return im.resize((wpx * SCALE, h * SCALE), Image.NEAREST), wpx, h


def main():
    cells = []
    for label, rel in CANDS:
        p = os.path.join(REPO, rel)
        if not os.path.isfile(p):
            cells.append((None, f"{label} (missing)", 0, 0)); continue
        im, wpx, h = render(p)
        cells.append((im, f"{label}  {wpx}x{h}px", wpx, h))
    PAD = 14; LBL = 16
    cw = max((im.width if im else 40) for im, _, _, _ in cells) + PAD * 2
    ch = max((im.height if im else 20) for im, _, _, _ in cells) + PAD * 2 + LBL
    ncol = 5
    nrow = (len(cells) + ncol - 1) // ncol
    W, H = ncol * cw, nrow * ch + 24
    sheet = Image.new('RGB', (W, H), SKY)
    d = ImageDraw.Draw(sheet)
    title = ("TOP-OF-WALL candidate cels (index-0 black = OPAQUE / solid)" if OPAQUE
             else "TOP-OF-WALL candidate cels (index-0 black = transparent to sky)")
    d.text((6, 6), title, fill=(0, 0, 0))
    for i, (im, lbl, wpx, h) in enumerate(cells):
        cx, cy = (i % ncol) * cw, 24 + (i // ncol) * ch
        if im: sheet.paste(im, (cx + PAD, cy + PAD))
        d.text((cx + PAD, cy + (im.height if im else 20) + PAD), lbl, fill=(0, 0, 0))
    out = os.path.join(REPO, 'build',
                       'walltop_spritesheet_opaque.png' if OPAQUE else 'walltop_spritesheet.png')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out)
    print("wrote", out)


if __name__ == '__main__':
    main()
