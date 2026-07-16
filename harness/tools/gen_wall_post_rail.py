#!/usr/bin/env python3
"""
gen_wall_post_rail.py — HAND-AUTHOR the scene-6 wall from Jay's RATIFIED 9x7 spec, and derive the
build decomposition. NO converter, NO parity (Jay's palette indices direct).

Jay's POST (9 rows x 7 cols; w=white=idx3, b=black=idx0, t=transparent):
  w w b b b b t      col 6 (rightmost) = t,t,w,b,b,b,t,t,w  == the RAIL cross-section.
  w w b b b b t
  w w b b b b w      DECOMPOSITION (verified by assert):
  b b b b b b b        * cols 0-5 contain NO 't' -> a 6x9 FULLY OPAQUE block (no per-pixel mask)
  b b b b b b b        * col 6 == the rail column -> drawn as DIRECT ROW-FILLS, not a tiled cel
  b b b b b b b      => wall-top = 5 horizontal rail fills + 2 opaque 6x9 blocks stamped on top.
  w w b b b b t
  w w b b b b t      Placement: opaque blocks at CoCo3 bytes 46 & 67, SUB 2 (px 186 & 270), row 100.
  w w b b b b w      The opaque path (HAL_gfx_blit_sprite_opaque) DOES sub-byte shift 0-3 (shares
                     blit_dispatch) -> NO new primitive. (Caveat: opaque+shift writes the shifted-in
                     leading 2px as black, idiom 9a -> handle/flag the left edge.)

Supersedes the prior 4x8 art. Emits the opaque BLOCK (cols 0-5) as content (no mask) + a sky-bg
preview of the full 9x7 + the rail-fill descriptor + geometry.
"""
import os, argparse
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__)); REPO = os.path.abspath(os.path.join(HERE, '..'))
# Jay's revised 11x7 (2026-07-16): 3 sky / white / 3 black / 3 sky / white. Placement row 99, sub 1.
POST = ["wwbbbbt", "wwbbbbt", "wwbbbbt", "wwbbbbw",
        "bbbbbbb", "bbbbbbb", "bbbbbbb",
        "wwbbbbt", "wwbbbbt", "wwbbbbt", "wwbbbbw"]
RAIL = [row[6] for row in POST]          # DERIVED: rail = post col 6 (code-enforced single-source)
BLOCK = [row[0:6] for row in POST]       # DERIVED: opaque block = cols 0-5
POST_ROW = 99                            # placement row (grows upward from the 9x7's 100)

IDX = {'w': 3, 'b': 0, 't': 0}
PALETTE = {0: (0, 0, 0), 1: (230, 111, 0), 2: (25, 144, 255), 3: (255, 255, 255)}
SKY = PALETTE[2]


def pack_rowbytes(cells):
    """Pack a row of cells into ceil(len/4) bytes, 2bpp MSB-first (pixel 0 = top 2 bits)."""
    wb = (len(cells) + 3) // 4
    out = []
    for byi in range(wb):
        b = 0
        for i in range(4):
            ci = byi * 4 + i
            v = IDX[cells[ci]] if ci < len(cells) else 0
            b |= (v & 3) << (6 - i * 2)
        out.append(b)
    return out


def emit_block(path):
    h = len(BLOCK); w = len(BLOCK[0]); wb = (w + 3) // 4
    L = ["* scene6_wall_post — HAND-AUTHORED opaque block (cols 0-5 of Jay's 9x7 post).",
         "* w=3(white) b=0(black); NO 't' in this block -> fully OPAQUE (no mask plane needed).",
         "* col 6 (rail) is NOT here — it is drawn as direct row-fills. Placement: byte 46/67 sub 2,",
         "* row 100, via HAL_gfx_blit_sprite_opaque (sub-byte shift 2).",
         f"* {w}px wide x {h} tall; {wb} byte/row.", "",
         "scene6_wall_post:",
         f"        fcb     {h},{wb}                  ; height, width(bytes)"]
    for r in BLOCK:
        bs = pack_rowbytes(r)
        L.append("        fcb     " + ",".join(f"${b:02X}" for b in bs) + f"          ; {' '.join(r)}")
    L.append("")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write('\n'.join(L) + '\n')


def emit_rail(path):
    """Rail-fill descriptor: the row-runs derived from col 6 (single-source)."""
    L = ["* scene6_wall_rail — the rail is DIRECT ROW-FILLS (post col 6 = t,t,w,b,b,b,t,t,w),",
         "* NOT a tiled cel/sprite. Row-runs (relative to the post top row 100):"]
    for i, c in enumerate(RAIL):
        if c != 't':
            L.append(f"* rail_band row+{i} (CoCo3 row {100+i}): {'WHITE $FF' if c=='w' else 'BLACK $00'}")
    L.append("* rows +0/+1/+6/+7 = nothing (sky). Drawn across the derived span between the placed posts.")
    L.append("")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write('\n'.join(L) + '\n')


def render_full(scale, bg='sky'):
    """Preview of the FULL 9x7 (block + rail col): w->white, b->black, t->sky (HS-10 default)."""
    h = len(POST); w = len(POST[0])
    im = Image.new('RGB', (w, h))
    px = im.load()
    for y, row in enumerate(POST):
        for x, c in enumerate(row):
            px[x, y] = SKY if (c == 't') else PALETTE[IDX[c]]
    return im.resize((w * scale, h * scale), Image.NEAREST) if scale != 1 else im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scale', type=int, default=24)
    ap.add_argument('--emit', action='store_true')
    args = ap.parse_args()

    assert RAIL == [r[6] for r in POST], "rail must be post col 6"
    assert all('t' not in r for r in BLOCK), "block (cols 0-5) must contain no transparent"
    assert len(POST) == 11 and all(len(r) == 7 for r in POST), "post must be 11x7"

    if args.emit:
        emit_block(os.path.join(REPO, '..', 'content', 'scenery', 'scene6_wall_post', 'authored.s'))
        emit_rail(os.path.join(REPO, '..', 'content', 'scenery', 'scene6_wall_rail', 'authored.s'))
        print("emitted content/scenery/scene6_wall_{post(6x9 opaque block),rail(fill descriptor)}")

    # geometry — positions fixed; rail is fills so no tiling/W. Re-derive the SPAN from placed posts.
    P2, P3 = 46 * 4 + 1, 67 * 4 + 1       # sub 1 -> px 185, 269 (Jay's side-by-side 1px-left read)
    BW = 6                                 # opaque block width (cols 0-5)
    print(f"\n=== GEOMETRY (11x7 model, row {POST_ROW}, sub 1) ===")
    print(f"post blocks: byte 46 sub 1 = px {P2}; byte 67 sub 1 = px {P3}; block width {BW}px; row {POST_ROW}")
    print(f"post pitch = {P3-P2}px (84); RAIL = direct fills (no tile/W; old G=80/W=8 SUPERSEDED)")
    print(f"rail span (derived, between placed posts): px {P2} .. {P3+BW} "
          f"(left block left edge .. right block right edge) = {P3+BW-P2}px  [I] extent past outer posts unknown")
    print(f"rail bands: white rows {[POST_ROW+i for i,c in enumerate(RAIL) if c=='w']}, "
          f"black rows {[POST_ROW+i for i,c in enumerate(RAIL) if c=='b']}")

    # preview
    outdir = os.path.join(REPO, '..', 'build', 'wall_ref'); os.makedirs(outdir, exist_ok=True)
    Z = args.scale
    post_z, post_1 = render_full(Z), render_full(1)
    PAD, TXT = Z, 34
    sheet = Image.new('RGB', (post_z.width + PAD * 2, TXT + post_z.height + PAD + 20), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    d.text((4, 2), f"WALL POST 9x7 (Jay spec) — w=white b=black t=SKY; NEAREST x{Z}; cols0-5=opaque "
                   f"block, col6=rail", fill=(255, 255, 255))
    sheet.paste(post_z, (PAD, TXT)); sheet.paste(post_1, (PAD, TXT + post_z.height + 6))
    d.text((PAD + post_1.width + 6, TXT + post_z.height + 4), "1:1", fill=(160, 160, 160))
    sheet.save(os.path.join(outdir, 'wall_post_9x7_sheet.png'))
    print("\nrendered build/wall_ref/wall_post_9x7_sheet.png")


if __name__ == '__main__':
    main()
