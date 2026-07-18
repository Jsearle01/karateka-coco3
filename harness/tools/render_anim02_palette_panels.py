#!/usr/bin/env python3
"""
render_anim02_palette_panels.py — in-scene palette comparison at climb anim_02 (Jay's ask). REPORT ONLY.
Four aligned panels: ORACLE | current | cand-3 | C1, all the SAME anim_02 frame.

The oracle panel is the apple2e MAME snapshot (artifact colour), placed at +20 (CoCo3=Apple+20).
The three port panels are the SAME captured anim_02 index-frame (pose_2.bin) re-coloured under each
palette's MEASURED MAME-composite RGB (from pal_sweep) — i.e. exactly what a preview build with those
$FFB1/$FFB2 registers would DISPLAY, since a GIME palette change is a pure index->RGB remap of an
unchanged framebuffer. NOTHING is built, promoted, or applied to the shipped build (HS-B3): the shipped
fallback's indices are identical in every panel; only the palette RGB differs.
Tuned-for output: MAME composite (per the palette study). Square-pixel integer NEAREST, factor stated.
"""
import os
from PIL import Image, ImageDraw

APPLE = [(0, 0, 0), (230, 111, 0), (25, 144, 255), (255, 255, 255)]
# port palettes: index -> RGB (0 blk, 1 orange=$FFB1, 2 blue=$FFB2, 3 white). MAME-composite measured.
CURRENT = [(0, 0, 0), (245, 115, 58), (94, 44, 255), (255, 255, 255)]   # $26 / $1B (violet)
CAND3   = [(0, 0, 0), (182, 52, 2),   (16, 94, 233),  (255, 255, 255)]  # $16 / $1C
C1      = [(0, 0, 0), (221, 140, 1),  (54, 179, 247), (255, 255, 255)]  # $25 / $2D

ORACLE_PNG = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/oracle_anim02/apple2e/0000.png"
PORT_BIN = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/climb_poses/pose_2.bin"
OUTDIR = "C:/Projects/karateka_coco3/build/anim02_compare"
XOFF, CW = 20, 320

def port_grid():
    d = open(PORT_BIN, 'rb').read()
    return [[(d[r*80+c] >> (6 - p*2)) & 3 for c in range(80) for p in range(4)] for r in range(192)]

def port_canvas(grid, pal):
    img = Image.new('RGB', (CW, 192), (18, 18, 18)); px = img.load()
    for y in range(192):
        for x in range(320):
            px[x, y] = pal[grid[y][x]]
    return img

def oracle_canvas():
    im = Image.open(ORACLE_PNG).convert('RGB'); W, H = im.size
    o = im.resize((W // 2, H), Image.NEAREST)
    c = Image.new('RGB', (CW, 192), (18, 18, 18)); c.paste(o, (XOFF, 0))
    return c

def label(img, text):
    bar = 15
    out = Image.new('RGB', (img.width, img.height + bar), (0, 0, 0))
    out.paste(img, (0, bar)); ImageDraw.Draw(out).text((3, 3), text, fill=(240, 240, 240))
    return out

def stack(panels, scale):
    labeled = [label(im, t) for im, t in panels]
    gap = 6
    W = max(p.width for p in labeled)
    H = sum(p.height for p in labeled) + gap * (len(labeled) - 1)
    out = Image.new('RGB', (W, H), (18, 18, 18)); y = 0
    for p in labeled:
        out.paste(p, (0, y)); y += p.height + gap
    if scale != 1:
        out = out.resize((out.width * scale, out.height * scale), Image.NEAREST)
    return out

def main():
    os.makedirs(OUTDIR, exist_ok=True)
    g = port_grid()
    oc = oracle_canvas()
    cur = port_canvas(g, CURRENT); c3 = port_canvas(g, CAND3); c1 = port_canvas(g, C1)
    L_or = "ORACLE anim_02 (apple2e, artifact blue(25,144,255)/orange(230,111,0)) +20"
    L_cur = "current   blue $1B(94,44,255) violet  orange $26(245,115,58)"
    L_c3 = "cand-3    blue $1C(16,94,233) d55      orange $16(182,52,2) d76"
    L_c1 = "C1        blue $2D(54,179,247) d46     orange $25(221,140,1) d30"
    panels = [(oc, L_or), (cur, L_cur), (c3, L_c3), (c1, L_c1)]

    full = stack(panels, 3)
    fp = os.path.join(OUTDIR, "anim02_palette_panels_full_x3.png")
    full.save(fp)

    cx0, cx1, cy0, cy1 = 64, 144, 128, 176
    cpanels = [(im.crop((cx0, cy0, cx1, cy1)), t + " [crop]") for im, t in panels]
    crop = stack(cpanels, 8)
    cp = os.path.join(OUTDIR, "anim02_palette_panels_lowerbody_x8.png")
    crop.save(cp)

    print(f"wrote {fp}  (4 panels oracle|current|cand-3|C1, x3 NEAREST)")
    print(f"wrote {cp}  (lower-body crop, x8 NEAREST)")
    print("panels = captured anim_02 index-frame re-coloured per palette (preview render); "
          "shipped build unchanged, nothing promoted; tuned-for output = MAME composite")

if __name__ == '__main__':
    main()
