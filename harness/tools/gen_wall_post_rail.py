#!/usr/bin/env python3
"""
gen_wall_post_rail.py — HAND-AUTHOR the scene-6 wall post + rail sprites (art + masks)
and compute the post-gap geometry. NO converter, NO parity (HS-9): Jay's palette indices
emitted directly. The RAIL is DERIVED from POST COLUMN 3 (HS-1), single-sourced.

Jay's spec (w=white, b=opaque-black, t=transparent-black/mask-out):
POST 4x8:                RAIL 1x8 (= post col 3):
  w b b t                  t
  w b b t                  t
  w b b w                  w
  b b b b                  b
  b b b b                  b
  w b b t                  t
  w b b t                  t
  w b b w                  w

Palette indices (CoCo3 explicit, no column-parity): w=3 (white), b=0 (black), t=0 (black,
but MASKED OUT). Color plane can't distinguish b from t (both black index 0) -> a per-pixel
MASK plane marks opaque(11) vs transparent(00). Post needs PER-ROW-varying transparency
(col 3 alternates t/opaque by row) -> the mask MUST be per-pixel/2D, NOT per-column.

Emits content .s (color plane + mask plane) + a sheet + a true-spacing composite for Jay's gate.
"""
import os, sys, argparse
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..'))

# --- SINGLE SOURCE OF TRUTH: the post grid (rows of 4 cells) ---
POST = [
    "wbbt",
    "wbbt",
    "wbbw",
    "bbbb",
    "bbbb",
    "wbbt",
    "wbbt",
    "wbbw",
]
# RAIL = post column 3 (index 3), DERIVED — never authored independently (HS-1).
RAIL = [row[3] for row in POST]            # -> ['t','t','w','b','b','t','t','w']

IDX  = {'w': 3, 'b': 0, 't': 0}            # color index; t is black-index but masked out
MASKBITS = {'w': 3, 'b': 3, 't': 0}        # mask pixel-pair: 11=opaque, 00=transparent

# REAL 4-index GIME scene palette (the climb tableau's colours) — MAME-authoritative RGB.
PALETTE = {0: (0, 0, 0),        # index 0 black  (b, opaque)
           1: (230, 111, 0),    # index 1 orange
           2: (25, 144, 255),   # index 2 blue (sky)
           3: (255, 255, 255)}  # index 3 white  (w)
RGB  = {'w': (255, 255, 255), 'b': (0, 0, 0)}
BG_SKY = PALETTE[2]                         # composite bg (sky) so t reads as background-shows
# Transparency in the INDIVIDUAL sheet = a gray CHECKERBOARD (NOT a palette colour, so it can't be
# mistaken for art). b=0 and t=0 share colour index 0 — distinguished ONLY by the mask plane, so the
# sheet decodes the MASK: mask 00 -> checker (transparent), mask 11 -> PALETTE[colour].
CK_A, CK_B = (64, 64, 64), (128, 128, 128)


def checker(x, y):
    return CK_A if ((x ^ y) & 1) else CK_B


def pack_row(cells, valmap):
    """Pack up to 4 cells into one 2bpp byte (MSB-first, pixel 0 = top 2 bits)."""
    b = 0
    for i in range(4):
        v = valmap[cells[i]] if i < len(cells) else 0
        b |= (v & 3) << (6 - i * 2)
    return b


def emit_s(label, grid, path):
    h = len(grid); w_cells = len(grid[0]); wbytes = (w_cells + 3) // 4
    L = [f"* {label} — HAND-AUTHORED wall sprite (gen_wall_post_rail.py). NOT converted (HS-9).",
         f"* color plane: w=3(white) b=0(black) t=0(black,masked). mask: 11=opaque 00=transparent.",
         f"* {w_cells}px wide x {h} tall; {wbytes} byte/row.", ""]
    L.append(f"{label}:")
    L.append(f"        fcb     {h},{wbytes}                  ; height, width(bytes)")
    for r in grid:
        L.append(f"        fcb     ${pack_row(r, IDX):02X}                    ; {' '.join(r)}")
    L.append("")
    L.append(f"{label}_mask:                        ; per-pixel 2D mask (11=opaque 00=transparent)")
    for r in grid:
        L.append(f"        fcb     ${pack_row(r, MASKBITS):02X}                    ; {' '.join(r)}")
    L.append("")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write('\n'.join(L) + '\n')
    return h, w_cells


def render_from_planes(grid, scale):
    """Render the individual cel by DECODING the authored color+mask bytes (faithful to what
    ships): mask pixel-pair 00 -> transparent (gray checker); 11 -> PALETTE[color pixel-pair].
    NEAREST integer scale. Also asserts the decode matches Jay's grid (validates the packing)."""
    h = len(grid); w = len(grid[0])
    im = Image.new('RGB', (w, h), (24, 24, 24))
    px = im.load()
    for y, row in enumerate(grid):
        cbyte = pack_row(row, IDX)          # color plane byte for this row
        mbyte = pack_row(row, MASKBITS)     # mask plane byte for this row
        for x in range(w):
            col2 = (cbyte >> (6 - 2 * x)) & 3
            msk2 = (mbyte >> (6 - 2 * x)) & 3
            cell = row[x]
            # validation: decoded transparency/colour must equal Jay's authored cell
            assert (msk2 == 0) == (cell == 't'), f"mask/grid mismatch at ({x},{y})"
            px[x, y] = checker(x, y) if msk2 == 0 else PALETTE[col2]
    if scale != 1:
        im = im.resize((w * scale, h * scale), Image.NEAREST)
    return im


def divisors(n):
    return [d for d in range(1, n + 1) if n % d == 0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scale', type=int, default=16)
    ap.add_argument('--emit', action='store_true', help='write content .s files')
    args = ap.parse_args()

    # sanity: rail == post col 3 (HS-1 single-source proof)
    assert RAIL == [r[3] for r in POST], "rail must be post col 3"

    if args.emit:
        emit_s("scene6_wall_post", POST,
               os.path.join(REPO, '..', 'content', 'scenery', 'scene6_wall_post', 'authored.s'))
        emit_s("scene6_wall_rail", [c for c in [[x] for x in RAIL]],
               os.path.join(REPO, '..', 'content', 'scenery', 'scene6_wall_rail', 'authored.s'))
        print("emitted content/scenery/scene6_wall_{post,rail}/authored.s")

    # --- geometry (HS-5): posts 2 & 3 (oracle-matching); post 1 known-bad, excluded ---
    # scene6_cliff.s front-layer (AA23) byte cols, sub 0, 4px/byte:
    X2, X3, PW = 46 * 4, 67 * 4, 4          # px 184, 268; post width 4
    G = X3 - (X2 + PW)
    divs = divisors(G)
    print(f"\n=== GEOMETRY (HS-5) — from posts 2/3 (post 1 excluded, HS-4) ===")
    print(f"post2 X={X2}px  post3 X={X3}px  pitch={X3-X2}px  post_width={PW}px")
    print(f"G (gap) = X3 - (X2+{PW}) = {G} px = {G/4:g} bytes")
    print(f"divisors of {G}: {divs}")
    print(f"byte-aligned (W%4==0): {[d for d in divs if d % 4 == 0]}")
    print(f"multi-segment byte-aligned (exclude W={G}): "
          f"{[d for d in divs if d % 4 == 0 and d != G]}")

    # --- gate renders (HS-2/3/4/5): individual cels in the REAL palette, transparent=checker,
    #     integer NEAREST, BOTH 1:1 and magnified. Rendered by DECODING the authored planes. ---
    Z = args.scale
    RAILG = [[c] for c in RAIL]
    post_1, post_z = render_from_planes(POST, 1), render_from_planes(POST, Z)
    rail_1, rail_z = render_from_planes(RAILG, 1), render_from_planes(RAILG, Z)
    outdir = os.path.join(REPO, '..', 'build', 'wall_ref')
    os.makedirs(outdir, exist_ok=True)
    PAD, TXT = Z, 34
    colW = max(post_z.width, 120)
    sheetW = PAD + colW + PAD * 3 + max(rail_z.width, 120) + PAD
    sheetH = TXT + post_z.height + PAD + 30
    sheet = Image.new('RGB', (sheetW, sheetH), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    d.text((4, 2), f"WALL CELS — real 4-idx palette; transparent = GRAY CHECKER; NEAREST x{Z} + 1:1;"
                   f" art bytes UNCHANGED", fill=(255, 255, 255))
    d.text((PAD, TXT - 14), f"POST 4x8  (x{Z})", fill=(200, 200, 200))
    sheet.paste(post_z, (PAD, TXT))
    sheet.paste(post_1, (PAD, TXT + post_z.height + 6))           # 1:1 beneath
    d.text((PAD + post_1.width + 6, TXT + post_z.height + 4), "1:1", fill=(160, 160, 160))
    rx = PAD + colW + PAD * 3
    d.text((rx, TXT - 14), f"RAIL 1x8 (=post col3)  (x{Z})", fill=(200, 200, 200))
    sheet.paste(rail_z, (rx, TXT))
    sheet.paste(rail_1, (rx, TXT + rail_z.height + 6))
    d.text((rx + rail_1.width + 6, TXT + rail_z.height + 4), "1:1", fill=(160, 160, 160))
    sheet.save(os.path.join(outdir, 'wall_post_rail_sheet.png'))

    # composite: two posts + rail filling the TRUE gap G, at scale, on sky bg (HS-10)
    W_full = PW + G + PW                    # post | gap | post  (= pitch + post width)
    comp = Image.new('RGB', (W_full, len(POST)), BG_SKY)
    cpx = comp.load()
    def stamp(grid, x0):
        for y, row in enumerate(grid):
            for x, c in enumerate(row):
                if c == 't':
                    continue               # transparent -> leave bg
                cpx[x0 + x, y] = RGB[c]
    stamp(POST, 0)                          # post A
    for gx in range(G):                     # rail tiled across the gap (1px unit repeated)
        stamp([[c] for c in RAIL], PW + gx)
    stamp(POST, PW + G)                     # post B
    comp = comp.resize((W_full * Z, len(POST) * Z), Image.NEAREST)
    comp.save(os.path.join(outdir, 'wall_composite_true_spacing.png'))
    print(f"\nrendered build/wall_ref/wall_post_rail_sheet.png + wall_composite_true_spacing.png "
          f"(composite span={W_full}px at true G={G})")


if __name__ == '__main__':
    main()
