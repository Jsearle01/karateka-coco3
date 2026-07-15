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

# render RGB (t shown distinctly so Jay SEES transparency vs opaque black)
RGB  = {'w': (255, 255, 255), 'b': (0, 0, 0)}
TRANSPARENT_MARK = (200, 40, 200)          # magenta = mask-out (sheet only)
BG_SKY = (25, 144, 255)                    # composite bg so t reads as background-shows


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


def render_cell_grid(grid, scale, mark_transparent):
    h = len(grid); w = len(grid[0])
    im = Image.new('RGB', (w, h), BG_SKY)
    px = im.load()
    for y, row in enumerate(grid):
        for x, c in enumerate(row):
            px[x, y] = TRANSPARENT_MARK if (c == 't' and mark_transparent) else \
                       (BG_SKY if c == 't' else RGB[c])
    return im.resize((w * scale, h * scale), Image.NEAREST)


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

    # --- gate renders (HS-10) ---
    s = args.scale
    post_im = render_cell_grid(POST, s, mark_transparent=True)
    rail_im = render_cell_grid([[c] for c in RAIL], s, mark_transparent=True)
    outdir = os.path.join(REPO, '..', 'build', 'wall_ref')
    os.makedirs(outdir, exist_ok=True)
    # sheet
    PAD = s
    sheet = Image.new('RGB', (post_im.width + rail_im.width + PAD * 4, post_im.height + PAD * 3),
                      (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    sheet.paste(post_im, (PAD, PAD * 2)); sheet.paste(rail_im, (post_im.width + PAD * 3, PAD * 2))
    d.text((PAD, 2), "POST 4x8 (magenta=transparent)", fill=(255, 255, 255))
    d.text((post_im.width + PAD * 3, 2), "RAIL(=col3)", fill=(255, 255, 255))
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
    comp = comp.resize((W_full * s, len(POST) * s), Image.NEAREST)
    comp.save(os.path.join(outdir, 'wall_composite_true_spacing.png'))
    print(f"\nrendered build/wall_ref/wall_post_rail_sheet.png + wall_composite_true_spacing.png "
          f"(composite span={W_full}px at true G={G})")


if __name__ == '__main__':
    main()
