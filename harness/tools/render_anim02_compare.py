#!/usr/bin/env python3
"""
render_anim02_compare.py — oracle vs port, in-scene, at climb pose anim_02. REPORT ONLY.

Oracle: apple2e MAME snapshot (560x192, artifact colour as MAME renders it) -> halve to 280 native
(left col of each pair, per render_square). Port: coco3 anim_02 framebuffer dump (pose_2.bin, 15360B)
-> 320x192, decoded in the ACTUAL PORT (GIME composite) colours. ONE coordinate system:
CoCo3_px = Apple_px + 20 (280->320 centering) — the oracle is placed at x=20 in a 320-wide canvas so a
column traces straight down between the two. Square-pixel, integer NEAREST, no smoothing (factor stated
on-image). Stacked oracle-over-port, column-aligned. Full frame + lower-body ("butt area") crop.
Also emits a per-pixel colour-index map for the lower-body region (structured text, both sides).
NO annotation/interpretation on the image — Jay identifies.
"""
import os, sys
from PIL import Image, ImageDraw

# each side in ITS OWN real colours (HS-A3)
APPLE = [(0, 0, 0), (230, 111, 0), (25, 144, 255), (255, 255, 255)]     # MAME apple2e artifact
PORT = [(0, 0, 0), (245, 115, 58), (94, 44, 255), (255, 255, 255)]      # GIME composite ($00/$26/$1B/$3F)
NAMES = ['black', 'orange', 'blue', 'white']

ORACLE_PNG = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/oracle_anim02/apple2e/0000.png"
PORT_BIN = "C:/Users/jayse/AppData/Local/Temp/claude/c--Projects-karateka-coco3/9c840854-3b22-46e9-bd4c-86d1cdf76afe/scratchpad/climb_poses/pose_2.bin"
OUTDIR = "C:/Projects/karateka_coco3/build/anim02_compare"
XOFF = 20          # CoCo3_px = Apple_px + 20
CANVAS_W = 320

def load_oracle_280():
    im = Image.open(ORACLE_PNG).convert('RGB')
    W, H = im.size
    return im.resize((W // 2, H), Image.NEAREST)      # 560 -> 280 native square

def port_index_grid():
    d = open(PORT_BIN, 'rb').read()
    return [[(d[r*80+c] >> (6 - p*2)) & 3 for c in range(80) for p in range(4)] for r in range(192)]

def oracle_index_grid(o280):
    px = o280.load(); W, H = o280.size
    def nearest(rgb):
        return min(range(4), key=lambda i: sum((a-b)**2 for a, b in zip(rgb, APPLE[i])))
    return [[nearest(px[x, y]) for x in range(W)] for y in range(H)]

def canvas_from_port(grid):
    img = Image.new('RGB', (CANVAS_W, 192), (18, 18, 18))
    px = img.load()
    for y in range(192):
        for x in range(320):
            px[x, y] = PORT[grid[y][x]]
    return img

def canvas_from_oracle(o280):
    img = Image.new('RGB', (CANVAS_W, 192), (18, 18, 18))
    img.paste(o280, (XOFF, 0))       # apple px X -> canvas X+20
    return img

def label(img, text):
    bar = 15
    out = Image.new('RGB', (img.width, img.height + bar), (0, 0, 0))
    out.paste(img, (0, bar))
    ImageDraw.Draw(out).text((3, 3), text, fill=(240, 240, 240))
    return out

def stack(top, bot, scale, tlabel, blabel):
    t = label(top, tlabel); b = label(bot, blabel)
    gap = 6
    out = Image.new('RGB', (max(t.width, b.width), t.height + gap + b.height), (18, 18, 18))
    out.paste(t, (0, 0)); out.paste(b, (0, t.height + gap))
    if scale != 1:
        out = out.resize((out.width * scale, out.height * scale), Image.NEAREST)
    return out

def main():
    os.makedirs(OUTDIR, exist_ok=True)
    o280 = load_oracle_280()
    pgrid = port_index_grid()
    ogrid = oracle_index_grid(o280)
    oc = canvas_from_oracle(o280)
    pc = canvas_from_port(pgrid)

    TL = "ORACLE anim_02  apple2e f6084 page2  280->canvas+20  (artifact colour)"
    BL = "PORT   anim_02  coco3 pose_2  320  (GIME composite $26/$1B)  CoCo3px=Applepx+20"

    full = stack(oc, pc, 3, TL, BL)
    fp = os.path.join(OUTDIR, "anim02_oracle_vs_port_full_x3.png")
    full.save(fp)

    # lower-body crop: canvas x[64,144) rows[128,176)  (port cols ~16..36, the butt band)
    cx0, cx1, cy0, cy1 = 64, 144, 128, 176
    oc_c = oc.crop((cx0, cy0, cx1, cy1)); pc_c = pc.crop((cx0, cy0, cx1, cy1))
    crop = stack(oc_c, pc_c, 8, TL + "  [crop]", BL + "  [crop]")
    cp = os.path.join(OUTDIR, "anim02_oracle_vs_port_lowerbody_x8.png")
    crop.save(cp)

    print(f"wrote {fp}  (full, x3 NEAREST)")
    print(f"wrote {cp}  (lower-body crop x[{cx0},{cx1}) rows[{cy0},{cy1}), x8 NEAREST)")

    # ---- per-pixel colour facts for the lower-body band, ALIGNED (canvas coords) ----
    # canvas col X: port index = pgrid[y][X]; oracle index = ogrid[y][X-20] (X>=20)
    print("\n=== per-pixel colour facts, lower-body band (canvas cols 72..112, rows 150..167) ===")
    print("(each side classified to {black/orange/blue/white}; oracle offset +20 already applied)")
    for y in range(150, 168):
        prow = ''.join('.oBw'[pgrid[y][x]] for x in range(72, 113))
        orow = ''.join('.oBw'[ogrid[y][x-20]] if 0 <= x-20 < 280 else ' ' for x in range(72, 113))
        print(f" row{y}: ORACLE {orow}")
        print(f"        PORT   {prow}")
    print("\nlegend: '.'=black  'o'=orange  'B'=blue  'w'=white")

if __name__ == '__main__':
    main()
