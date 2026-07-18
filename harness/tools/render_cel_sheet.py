#!/usr/bin/env python3
"""
render_cel_sheet.py — decode the CLIMB cels straight from their converted bytes
(content/player/scene6_*/converted.s) and paint a labeled sprite sheet. A test that can FALSIFY the
"orange is in anim_02's cel data" claim: render the DATA (not a frame crop), all 7 poses + settle, so
Jay can compare anim_02 against its neighbours. REPORT ONLY — nothing fixed, nothing concluded.

Decode: `fcb height,width` then height rows of width bytes; each byte = 4 px, 2bpp MSB-first.
No separate mask plane in these cels — transparency is index-0-keyed by the HAL blit, so index 0 is
painted as a NON-palette gray checkerboard (idiom 11c: the cel palette includes index 2/blue, so a
sky bg would be ambiguous). Real PORT scene palette for the opaque indices:
  1 orange $26 -> (245,115,58)   2 blue $1B -> (94,44,255)   3 white $3F -> (255,255,255)
Square-pixel, integer NEAREST, no smoothing. Emits 1:1 and magnified sheets + prints per-cel index-1
(orange) counts. NO annotation on the image beyond the required address+pose labels (Jay identifies).
"""
import os, re
from PIL import Image, ImageDraw

CONTENT = "C:/Projects/karateka_coco3/content/player"
# port-rendered RGB (composite) for opaque indices; index 0 = transparent (checkerboard)
PAL = {1: (245, 115, 58), 2: (94, 44, 255), 3: (255, 255, 255)}
CHK = [(96, 96, 96), (140, 140, 140)]   # transparency checkerboard (non-palette gray)

# pose -> list of (address, dir) back-to-front as in cl_frames (legs/lower first)
POSES = [
    ("anim_00", [("A3E9", "scene6_climb_A3E9"), ("A3C5", "scene6_climb_A3C5")]),
    ("anim_01", [("A40B", "scene6_climb_A40B"), ("A425", "scene6_climb_A425")]),
    ("anim_02", [("A45A", "scene6_climb_A45A"), ("A4A4", "scene6_climb_A4A4")]),
    ("anim_03", [("A4D2", "scene6_climb_A4D2"), ("A4F2", "scene6_climb_A4F2")]),
    ("anim_04", [("A548", "scene6_climb_A548"), ("A572", "scene6_climb_A572")]),
    ("anim_05", [("A5CC", "scene6_climb_A5CC"), ("A5DC", "scene6_climb_A5DC")]),
    ("anim_06_settle", [("899C", "scene6_player_899C"), ("8ACB", "scene6_player_8ACB"),
                         ("8E9B", "scene6_player_8E9B")]),
]


def parse_cel(dirname):
    """Return (height, width, [rows of bytes]) parsed from converted.s."""
    path = os.path.join(CONTENT, dirname, "converted.s")
    lines = open(path).read().splitlines()
    # first fcb after the label = height,width ; subsequent fcb = row bytes
    fcb = [l for l in lines if re.search(r'^\s*fcb\s', l)]
    hdr = re.findall(r'\d+', fcb[0].split(';')[0])
    h, w = int(hdr[0]), int(hdr[1])
    rows = []
    for l in fcb[1:1 + h]:
        payload = l.split(';')[0]
        vals = re.findall(r'\$([0-9A-Fa-f]{2})', payload)
        rows.append([int(v, 16) for v in vals])
        assert len(vals) == w, f"{dirname}: row width {len(vals)} != {w}"
    assert len(rows) == h, f"{dirname}: {len(rows)} rows != {h}"
    return h, w, rows


def decode_pixels(h, w, rows):
    """Return a 2D list [row][col] of index 0..3 (col in 0..w*4-1)."""
    grid = []
    for r in range(h):
        line = []
        for b in rows[r]:
            for p in range(4):
                line.append((b >> (6 - p * 2)) & 3)
        grid.append(line)
    return grid


def cel_to_img(grid):
    h = len(grid)
    w = len(grid[0])
    img = Image.new('RGB', (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            idx = grid[y][x]
            if idx == 0:
                px[x, y] = CHK[(x // 2 + y // 2) % 2]   # 2px checker
            else:
                px[x, y] = PAL[idx]
    return img


def count_orange(grid):
    return sum(1 for row in grid for v in row if v == 1)


def main():
    outdir = "C:/Projects/karateka_coco3/build/climb_cel_sheet"
    os.makedirs(outdir, exist_ok=True)
    cels = {}          # addr -> (img, grid)
    counts = []        # (pose, addr, orange_px, w, h)
    for pose, parts in POSES:
        for addr, d in parts:
            h, w, rows = parse_cel(d)
            grid = decode_pixels(h, w, rows)
            cels[addr] = cel_to_img(grid)
            counts.append((pose, addr, count_orange(grid), w * 4, h))

    # ---- compose one sheet: one row per pose, cels side by side, labeled ----
    PAD, LBL, GAP, COLGAP = 6, 16, 10, 40
    SCALE = 8
    # native layout sizes
    row_imgs = []
    for pose, parts in POSES:
        imgs = [cels[a] for a, _ in parts]
        rw = sum(i.width for i in imgs) + GAP * (len(imgs) - 1)
        rh = max(i.height for i in imgs)
        row_imgs.append((pose, [a for a, _ in parts], imgs, rw, rh))
    sheet_w = PAD * 2 + max(r[3] for r in row_imgs)
    sheet_h = PAD + sum(r[4] + LBL + GAP for r in row_imgs)

    def build(scale, magnify_labels):
        img = Image.new('RGB', (sheet_w, sheet_h), (24, 24, 24))
        d = ImageDraw.Draw(img)
        y = PAD
        for pose, addrs, imgs, rw, rh in row_imgs:
            x = PAD
            for a, ci in zip(addrs, imgs):
                img.paste(ci, (x, y + LBL))
                d.text((x, y), f"${a} {pose}", fill=(235, 235, 235))
                x += ci.width + GAP
            y += rh + LBL + GAP
        if scale != 1:
            img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        return img

    one = build(1, False)
    p1 = os.path.join(outdir, "climb_cel_sheet_1x1.png")
    one.save(p1)
    mag = one.resize((one.width * SCALE, one.height * SCALE), Image.NEAREST)
    p8 = os.path.join(outdir, f"climb_cel_sheet_x{SCALE}.png")
    mag.save(p8)

    print(f"wrote {p1}  ({one.width}x{one.height}, 1:1 square)")
    print(f"wrote {p8}  (x{SCALE} NEAREST)")
    print()
    print("per-cel index-1 (orange = $26 -> RGB(245,115,58)) pixel counts, decoded from converted.s:")
    bypose = {}
    for pose, addr, orange, w, h in counts:
        print(f"  {pose:16s} ${addr}  {w}x{h}  orange_index1_px={orange}")
        bypose[pose] = bypose.get(pose, 0) + orange
    print()
    print("per-POSE totals (sum of the pose's cels):")
    for pose in bypose:
        print(f"  {pose:16s} orange_index1_px={bypose[pose]}")


if __name__ == '__main__':
    main()
