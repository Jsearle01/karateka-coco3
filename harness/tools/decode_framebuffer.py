#!/usr/bin/env python3
"""
decode_framebuffer.py — CoCo3 framebuffer dump decoder.

Reads a 15360-byte Frame A/B dump (192 rows × 80 bytes).
Each byte encodes 4 pixels at 2 bits each, MSB-first:
  bits 7:6 = pixel 0, bits 5:4 = pixel 1,
  bits 3:2 = pixel 2, bits 1:0 = pixel 3
  Values 0-3 are palette indices: 0=black, 1=orange, 2=blue, 3=white

Output (always):
  - Overall pixel-index distribution (counts + percentages)
  - Per-row summary (rows with non-zero index-1, -2, or -3)

Optional flags:
  --ascii     ASCII art (one char per byte; space=idx0 .=idx1 +=idx2 #=idx3)
  --region r0,c0,r1,c1  per-region statistics (byte-column units, inclusive)

Usage:
  python3 tools/decode_framebuffer.py <dump.bin>
  python3 tools/decode_framebuffer.py <dump.bin> --ascii
  python3 tools/decode_framebuffer.py <dump.bin> --region 48,0,95,79
  python3 tools/decode_framebuffer.py <dump.bin> --ascii --region 72,26,100,62

[ref: docs/project/methodology.md §framebuffer-dump-as-canonical-input-signal]
[ref: P2.3a.7 — framebuffer dump harness capability]
"""

import sys
import argparse

ROWS       = 192
COLS       = 80        # bytes per row
PX_PER_ROW = COLS * 4  # 320 pixels per row
FRAME_BYTES = ROWS * COLS  # 15360

INDEX_CHARS = ' .+#'   # 0=space 1=dot 2=plus 3=hash
INDEX_NAMES = ['0 (black)', '1 (orange)', '2 (blue)', '3 (white)']


def byte_to_indices(b):
    return ((b >> 6) & 3, (b >> 4) & 3, (b >> 2) & 3, b & 3)


def count_bytes(data):
    counts = [0, 0, 0, 0]
    for b in data:
        for px in byte_to_indices(b):
            counts[px] += 1
    return counts


def main():
    parser = argparse.ArgumentParser(
        description='CoCo3 framebuffer dump decoder (192×80 bytes, 2bpp MSB-first)')
    parser.add_argument('dump', help='Path to 15360-byte framebuffer dump')
    parser.add_argument('--ascii', action='store_true',
                        help='Print ASCII art (80 chars/row, space=idx0 .=idx1 +=idx2 #=idx3)')
    parser.add_argument('--region', metavar='r0,c0,r1,c1',
                        help='Limit region analysis to rows r0-r1, byte-cols c0-c1 (inclusive)')
    args = parser.parse_args()

    with open(args.dump, 'rb') as f:
        data = f.read()

    if len(data) != FRAME_BYTES:
        print(f'WARNING: expected {FRAME_BYTES} bytes, got {len(data)}; '
              f'truncating/padding to {FRAME_BYTES}')
        data = (data + bytes(FRAME_BYTES))[:FRAME_BYTES]

    total_px = FRAME_BYTES * 4

    # === Overall distribution ===
    counts = count_bytes(data)
    print(f'File : {args.dump}')
    print(f'Frame: {ROWS} rows × {COLS} bytes/row = {FRAME_BYTES} bytes / {total_px} pixels')
    print()
    print('=== Overall pixel-index distribution ===')
    for idx in range(4):
        bar = '#' * int(counts[idx] / total_px * 40)
        print(f'  Index {INDEX_NAMES[idx]:12s}: {counts[idx]:7d} px  '
              f'({counts[idx]/total_px*100:5.1f}%)  {bar}')
    print()

    # === Per-row summary (non-black rows only) ===
    print('=== Per-row summary (rows with index-1, -2, or -3 pixels) ===')
    any_nonblack = False
    for row in range(ROWS):
        row_data = data[row * COLS:(row + 1) * COLS]
        rc = count_bytes(row_data)
        if rc[1] + rc[2] + rc[3] == 0:
            continue
        any_nonblack = True
        parts = []
        for idx in range(4):
            if rc[idx] > 0:
                parts.append(f'idx{idx}={rc[idx]}px({rc[idx]/PX_PER_ROW*100:.0f}%)')
        print(f'  Row {row:3d}: {" | ".join(parts)}')
    if not any_nonblack:
        print('  (all rows are index-0 only)')
    print()

    # === Region analysis ===
    if args.region:
        r0, c0, r1, c1 = map(int, args.region.split(','))
        r1 = min(r1, ROWS - 1)
        c1 = min(c1, COLS - 1)
        region_data = bytearray()
        for row in range(r0, r1 + 1):
            region_data.extend(data[row * COLS + c0:row * COLS + c1 + 1])
        rc = count_bytes(region_data)
        reg_total = sum(rc)
        print(f'=== Region rows {r0}-{r1}, byte-cols {c0}-{c1} '
              f'({r1-r0+1} rows × {c1-c0+1} bytes = {reg_total//4} px) ===')
        for idx in range(4):
            pct = rc[idx] / reg_total * 100 if reg_total else 0
            print(f'  Index {INDEX_NAMES[idx]:12s}: {rc[idx]:6d} px  ({pct:5.1f}%)')
        print()

    # === ASCII art ===
    if args.ascii:
        print('=== ASCII art (80 chars/row; space=idx0  .=idx1  +=idx2  #=idx3) ===')
        for row in range(ROWS):
            row_data = data[row * COLS:(row + 1) * COLS]
            # One char per byte: use dominant pixel (first pixel = bits 7:6)
            line = ''.join(INDEX_CHARS[(b >> 6) & 3] for b in row_data)
            print(line)
        print()


if __name__ == '__main__':
    main()
