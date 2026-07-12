#!/usr/bin/env python3
"""
floodfill_bg_sky.py — fix the scene-6 background cels so opaque blitting is clean.

The converter leaves the sky/edge/transition areas as index-0 (black) at the cel
bounding-box edges (trim boundary) — indistinguishable from the mountain's real
interior black. Blitting OPAQUE (so the mountain's black is solid) then paints
those edge blacks as unwanted vertical black bands (Jay's gate).

Fix (Jay: "fix the cel data"; the area left black = trans, the other = opaque):
flood-fill from the cel BORDER through {index-0 black, index-2 blue}. The black
REACHED from the border is the mountain's OUTLINE/EDGE and stays index-0 (opaque
solid black). The black NOT reached — walled off by index-3 (white), i.e. the
INTERIOR sky-holes — is converted to index-2 (blue) so it reads as sky. After
this, an OPAQUE blit renders the mountain's edge black solid and the interior
sky-holes as blue (blend into the sky / transparent look).

Overwrites content/background/scene6_bg_<cel>/converted.s in place. Idempotent.
"""
import os, re, sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from sprite_convert import write_s_file

REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
FUJI = ['A948', 'A976', 'A9B8', 'A9E2']  # the 4 backdrop Fuji cels


def parse(path):
    h = w = None
    rows = []
    label = None
    for line in open(path, encoding='utf-8', errors='replace'):
        m = re.match(r'(\w+):', line)
        if m and label is None and not m.group(1).startswith('fcb'):
            label = m.group(1)
        m = re.search(r'fcb\s+(\d+),(\d+)\s*;\s*height', line)
        if m:
            h, w = int(m.group(1)), int(m.group(2))
            continue
        m = re.search(r'fcb\s+([$0-9A-Fa-f,]+)\s*;\s*row', line)
        if m and w:
            vals = [int(x.strip().lstrip('$'), 16) for x in m.group(1).split(',') if x.strip()]
            px = []
            for b in vals:
                for p in range(4):
                    px.append((b >> (6 - p * 2)) & 3)
            rows.append(px[:w * 4])
    return label, h, w, rows


def floodfill(rows, wpx, h):
    """Flood from the border through {0,2}; convert reached 0-pixels to 2."""
    seen = [[False] * wpx for _ in range(h)]
    q = deque()

    def push(r, c):
        if 0 <= r < h and 0 <= c < wpx and not seen[r][c] and rows[r][c] in (0, 2):
            seen[r][c] = True
            q.append((r, c))

    for c in range(wpx):
        push(0, c); push(h - 1, c)
    for r in range(h):
        push(r, 0); push(r, wpx - 1)
    while q:
        r, c = q.popleft()
        push(r - 1, c); push(r + 1, c); push(r, c - 1); push(r, c + 1)
    # Jay's ruling: the EDGE-connected black (reached from the border) is the
    # mountain's outline/edge and must stay OPAQUE (solid black); the INTERIOR
    # black (white-surrounded, NOT reached) is a sky-hole and must read as
    # TRANSPARENT -> convert it to blue so the opaque blit shows sky there.
    converted = 0
    for r in range(h):
        for c in range(wpx):
            if rows[r][c] == 0 and not seen[r][c]:
                rows[r][c] = 2  # interior sky-hole black -> blue
                converted += 1
    # Vertical-bar removal (Jay: the vertical bars should be transparent): a
    # FULLY-black column is the cel bounding-box / trim-boundary edge artifact,
    # not the mountain (a real slope varies row-to-row) — convert it to blue.
    for c in range(wpx):
        if all(rows[r][c] == 0 for r in range(h)):
            for r in range(h):
                rows[r][c] = 2
                converted += 1
    return converted


def pack(rows, wpx, h):
    cw = (wpx + 3) // 4
    out = bytearray()
    for r in range(h):
        for byte_idx in range(cw):
            b = 0
            for p in range(4):
                src = byte_idx * 4 + p
                if src < len(rows[r]):
                    b |= rows[r][src] << (6 - p * 2)
            out.append(b)
    return out, cw


def main():
    for cel in FUJI:
        d = os.path.join(REPO, 'content', 'background', f'scene6_bg_{cel}')
        p = os.path.join(d, 'converted.s')
        label, h, w, rows = parse(p)
        wpx = w * 4
        n = floodfill(rows, wpx, h)
        packed, cw = pack(rows, wpx, h)
        write_s_file(p, label, h, cw, packed, 'dump05_imprison.bin (sky floodfill)',
                     f'addr_{cel}', start_col=0)
        print(f"scene6_bg_{cel}: flood-filled {n} sky/edge black px -> blue "
              f"({h}x{cw}, {wpx}px)")


if __name__ == '__main__':
    main()
