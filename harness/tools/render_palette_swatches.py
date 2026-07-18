#!/usr/bin/env python3
"""
render_palette_swatches.py — cand-3 palette blue/orange swatches beside the oracle's SAMPLED colours
(and the current entries for reference). COLOURS, not a scene (Jay's ask). REPORT ONLY, nothing applied.

All RGBs are MAME's ACTUALLY-RENDERED values (composite decode) sampled in the palette study — filling
a swatch with them is the honest representation. Solid fills, integer NEAREST scaling (stated) so no
blending shifts hue at swatch edges (HS-B3). Each swatch labeled with RGB + (port) GIME index; each
non-oracle swatch labeled with its euclidean distance to the oracle target.
"""
import os, math
from PIL import Image, ImageDraw

# (label, gime_index_or_None, rgb)
BLUE = [
    ("current $1B", "$1B", (94, 44, 255)),
    ("cand-3  $1C", "$1C", (16, 94, 233)),
    ("ORACLE (sampled)", None, (25, 144, 255)),
]
ORANGE = [
    ("current $26", "$26", (245, 115, 58)),
    ("cand-3  $16", "$16", (182, 52, 2)),
    ("ORACLE (sampled)", None, (230, 111, 0)),
]

SW = 96      # swatch native size (px)
GAP = 8
PADX, PADTOP = 12, 26
LBLH = 46    # label strip under each swatch
SCALE = 3    # integer NEAREST upscale (square pixels)


def dist(a, b):
    return round(math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b))))


def render_row(draw, x0, y0, entries, oracle_rgb):
    for i, (label, idx, rgb) in enumerate(entries):
        x = x0 + i * (SW + GAP)
        draw.rectangle([x, y0, x + SW - 1, y0 + SW - 1], fill=rgb, outline=(90, 90, 90))
        d = draw
        d.text((x + 2, y0 + SW + 2), label, fill=(230, 230, 230))
        d.text((x + 2, y0 + SW + 13), f"rgb{rgb}", fill=(190, 190, 190))
        if idx and oracle_rgb is not None:
            d.text((x + 2, y0 + SW + 24), f"GIME {idx}  d={dist(rgb, oracle_rgb)}", fill=(190, 190, 190))
        elif idx:
            d.text((x + 2, y0 + SW + 24), f"GIME {idx}", fill=(190, 190, 190))


def main():
    outdir = "C:/Projects/karateka_coco3/build/palette_study"
    os.makedirs(outdir, exist_ok=True)
    roww = PADX * 2 + 3 * SW + 2 * GAP
    roww = max(roww, 340)
    W = roww
    H = PADTOP + (SW + LBLH) * 2 + 24 + 10
    img = Image.new('RGB', (W, H), (20, 20, 20))
    d = ImageDraw.Draw(img)
    oracle_blue = (25, 144, 255)
    oracle_orange = (230, 111, 0)
    d.text((PADX, 6), "BLUE   current -> cand-3 -> ORACLE   (index-2 / $FFB2)", fill=(255, 255, 255))
    render_row(d, PADX, PADTOP, BLUE, oracle_blue)
    y2 = PADTOP + SW + LBLH + 18
    d.text((PADX, y2 - 18), "ORANGE current -> cand-3 -> ORACLE   (index-1 / $FFB1)", fill=(255, 255, 255))
    render_row(d, PADX, y2, ORANGE, oracle_orange)
    img = img.resize((W * SCALE, H * SCALE), Image.NEAREST)
    out = os.path.join(outdir, "cand3_swatches_vs_oracle.png")
    img.save(out)
    print(f"wrote {out}  native={W}x{H}  scale x{SCALE} NEAREST (solid fills, exact)")
    print(f"BLUE   distances to oracle: current $1B d={dist((94,44,255),oracle_blue)}  "
          f"cand-3 $1C d={dist((16,94,233),oracle_blue)}")
    print(f"ORANGE distances to oracle: current $26 d={dist((245,115,58),oracle_orange)}  "
          f"cand-3 $16 d={dist((182,52,2),oracle_orange)}")


if __name__ == '__main__':
    main()
