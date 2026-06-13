r"""
sprite_convert.py — Apple II hi-res sprite → CoCo3 4-color packed bytes.

Reads a karateka_dissasembly_claude src/*.s file, extracts the sprite
record starting at a given ca65 label, and writes a CoCo3-ready lwasm .s file.

Apple II sprite format (as documented in sprite_data_0400.s):
  byte 0: height (rows)
  byte 1: width (bytes per row; 7 pixels per byte, bit 7 = color-set)
  bytes 2+: bitmap data, row-major

CoCo3 output format (4 pixels per byte, 2 bits each, MSB-first):
  byte 0: height
  byte 1: coco3_width (bytes per row; ceil(width_pixels/4))
  bytes 2+: packed bitmap, row-major

Color model — empirically derived from MAME Apple II ground truth:
  [ref: MAME apple2e snaps 0082-0085 in C:\karateka-capture\snap\apple2e\]
  [ref: TASK 1/2 gate 2026-05-16 — screen-col parity; TASK 4 gate 2026-05-16 — leading-edge chroma]

  4-category model (113/113 leading + 110/110 parity validated against snap 0083):

  For each pixel at sprite-local column x, with sprite at screen col start_col:
    screen_col = start_col + x

    - pixel OFF                                                    → palette 0 (Black)
    - pixel ON  + isolated + bit7=1 + screen_col even              → palette 2 (Blue)   [MAME]
    - pixel ON  + isolated + bit7=1 + screen_col odd               → palette 1 (Orange) [MAME]
    - pixel ON  + leading of adjacent run + gap_before==1          → palette 2/1 per parity [MAME]
    - pixel ON  + leading of adjacent run + gap_before>=2          → palette 3 (White)
    - pixel ON  + interior or trailing of adjacent run             → palette 3 (White)
    - pixel ON  + isolated + bit7=0 (Green/Violet)                 → palette 2 (Blue)   [predicted]

  gap_before threshold: 113/113 gap=1 → chroma; 120/120 gap>=2 → White. Binary cutoff.
  Simplification accepted: uniform gap==1 rule; sparse sprites naturally show less chroma.

  COLOR-CELL FILL (P4 engine-sandbox gate, 2026-06-13): a SOLID color region
  is an alternating-dot pattern (1010...) on the Apple II — the dark dot
  between two same-chroma dots is part of the color cell (NTSC merges them
  into a solid bar), NOT background. After per-dot classification, any Black
  dot flanked by the SAME chroma (Orange/Blue) on both sides is filled with
  that chroma. Without this, solid fills render as color/black vertical
  stripes. White runs and isolated thin color features are untouched.

  Screen-col parity: (start_col + local_col) % 2. Not local-col parity alone.
  Karateka: Logo 1 start_col=119, Logo 2 start_col=84.

CoCo3 4-color palette:
  0 = Black   (background)
  1 = Orange  (bit7=1, odd screen col) [MAME validated]
  2 = Blue    (bit7=1, even screen col; also Green/Violet quantized) [MAME validated]
  3 = White   (adjacent ON, interior/trailing/leading-gap>=2)
"""

import re
import os
import sys
import argparse


def parse_byte_directive(line):
    """Parse a single ca65 .byte line; return list of byte values."""
    line = re.sub(r';.*$', '', line)
    m = re.search(r'\.byte\s+(.+)$', line, re.IGNORECASE)
    if not m:
        return []
    values = []
    for v in re.split(r',\s*', m.group(1).strip()):
        v = v.strip()
        if not v:
            continue
        if v.startswith('$'):
            values.append(int(v[1:], 16))
        elif v.startswith('%'):
            values.append(int(v[1:], 2))
        elif re.match(r'^\d+$', v):
            values.append(int(v))
    return values


def extract_sprite_bytes(source_path, label):
    """
    Scan source_path for label, then collect all .byte values until
    the next label or end of file.
    """
    with open(source_path, 'r') as f:
        lines = f.readlines()

    label_pattern = re.compile(r'^' + re.escape(label) + r'\s*:')
    collecting = False
    raw = []

    for line in lines:
        if label_pattern.match(line):
            collecting = True
            continue
        if collecting:
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*\s*:', line):
                break
            raw.extend(parse_byte_directive(line))

    if not collecting:
        raise ValueError(f"Label '{label}' not found in {source_path}")
    if len(raw) < 2:
        raise ValueError(f"Label '{label}': too few bytes ({len(raw)}) for valid sprite header")

    return raw


def _classify_row_convert(row_bytes, width_pixels):
    """Pre-scan a row; return col_info mapping ON pixel col -> (pos_in_run, run_len, gap_before, pal_bit)."""
    col_info = {}
    in_run = False
    run_start = 0
    prev_run_end = None

    for col in range(width_pixels + 1):
        if col < width_pixels:
            byte_idx = col // 7
            bit_pos  = col % 7
            p = (row_bytes[byte_idx] >> bit_pos) & 1 if byte_idx < len(row_bytes) else 0
        else:
            p = 0

        if p and not in_run:
            in_run = True
            run_start = col
        elif not p and in_run:
            run_end = col - 1
            run_len = run_end - run_start + 1
            gap = (run_start - prev_run_end - 1) if prev_run_end is not None else run_start
            pal_bit = (row_bytes[run_start // 7] >> 7) & 1 if run_start // 7 < len(row_bytes) else 0
            for i in range(run_len):
                col_info[run_start + i] = (i, run_len, gap, pal_bit)
            prev_run_end = run_end
            in_run = False

    return col_info


def convert_sprite_to_coco3(apple_ii_bytes, height, apple_width_bytes, start_col=0):
    """
    Apple II sprite bitmap → CoCo3 4-color packed bytes.

    4-category color model (TASK 4 gate, 2026-05-16):
      isolated → screen-col parity color
      leading of run + gap==1 → screen-col parity color
      leading of run + gap>=2 → White
      interior/trailing → White
    [ref: MAME snap 0083; 113/113 gap=1 chroma, 120/120 gap>=2 White]

    Args:
      apple_ii_bytes: flat list of bitmap bytes (height * apple_width_bytes)
      height: rows
      apple_width_bytes: Apple II bytes per row (7 pixels each)
      start_col: Apple II screen pixel column of sprite left edge
                 Karateka: Logo 1 = 119, Logo 2 = 84

    Returns:
      (coco3_bitmap: bytearray, coco3_width: int)
    """
    width_pixels = apple_width_bytes * 7
    coco3_width = (width_pixels + 3) // 4
    coco3_bitmap = bytearray()

    for row in range(height):
        row_bytes = apple_ii_bytes[row * apple_width_bytes:(row + 1) * apple_width_bytes]
        col_info = _classify_row_convert(row_bytes, width_pixels)

        row_indices = [0] * width_pixels  # default Black
        for col in range(width_pixels):
            if col in col_info:
                pos_in_run, run_len, gap, pal_bit = col_info[col]
                screen_col = start_col + col

                if run_len == 1:
                    # Isolated pixel: chroma at this col.
                    row_indices[col] = (2 if screen_col % 2 == 0 else 1) if pal_bit == 1 else 2

                elif pos_in_run == 0 and gap == 1 and col > 0:
                    # NTSC chroma: attributed to this ON pixel, painted at col-1
                    # (-1 sub-pixel render offset). Color from ON pixel's screen col.
                    sc = start_col + col
                    chroma_idx = (2 if sc % 2 == 0 else 1) if pal_bit == 1 else 2
                    row_indices[col - 1] = chroma_idx  # overwrite col-1 (was Black)
                    row_indices[col] = 3               # this ON pixel is White

                else:
                    row_indices[col] = 3  # White (interior/trailing/leading gap>=2)
            # OFF pixel: remains 0 (Black, already set)

        # Color-cell fill (Apple II artifact color): a SOLID color region is
        # drawn as an alternating-dot pattern (1010...), so the OFF dot between
        # two same-color ON dots is part of the color cell, not background —
        # the NTSC display merges them into a solid color bar. The naive 1:1
        # dot map leaves those gaps Black, producing vertical color/black
        # striping on solid fills (P4 engine-sandbox gate, 2026-06-13: Akuma
        # orange/blue bodies). Fill any Black dot flanked by the SAME chroma
        # (Orange=1 / Blue=2) on both sides. White (3) runs and isolated thin
        # color features (a lone dot with no same-color neighbor two cells out)
        # are left untouched.
        src_indices = list(row_indices)
        for c in range(1, width_pixels - 1):
            if src_indices[c] == 0:
                left = src_indices[c - 1]
                if left in (1, 2) and left == src_indices[c + 1]:
                    row_indices[c] = left

        for byte_idx in range(coco3_width):
            packed = 0
            for pix_idx in range(4):
                src = byte_idx * 4 + pix_idx
                if src < len(row_indices):
                    packed |= row_indices[src] << (6 - pix_idx * 2)
            coco3_bitmap.append(packed)

    return coco3_bitmap, coco3_width


def write_s_file(output_path, label, height, coco3_width, coco3_bitmap,
                 source_ref, apple_label, start_col=0):
    """Write CoCo3 sprite data as a lwasm .s file (fcb directives)."""
    coco_label = label if label else (apple_label + '_coco3')
    lines = [
        f"* {os.path.basename(output_path)}",
        f"* CoCo3 sprite data — converted from Apple II source.",
        f"*",
        f"* ORIGIN: {source_ref}",
        f"*         Apple II label: {apple_label}",
        f"* Color model: adjacency + screen-col parity + color-cell fill (MAME-verified",
        f"*   TASK 1/2 gate 2026-05-16; color-cell fill P4 gate 2026-06-13).",
        f"*   0=Black 1=Orange(odd screen col) 2=Blue(even screen col) 3=White",
        f"*   start_col={start_col}",
        f"* [ref: karateka-coco3 docs/karateka-coco3-design-v0.1.md §6.7]",
        f"",
        f"{coco_label}:",
        f"        fcb     {height},{coco3_width}"
        f"  ; height={height} rows, coco3_width={coco3_width} bytes/row (4px/byte)",
    ]
    for row in range(height):
        row_bytes = coco3_bitmap[row * coco3_width:(row + 1) * coco3_width]
        hex_vals = ','.join(f'${b:02X}' for b in row_bytes)
        lines.append(f"        fcb     {hex_vals}  ; row {row}")

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')


def main():
    parser = argparse.ArgumentParser(description='Apple II sprite → CoCo3 converter')
    parser.add_argument('--source', required=True, help='Path to ca65 .s source file')
    parser.add_argument('--label', required=True, help='Starting label of the sprite record')
    parser.add_argument('--output', required=True, help='Output .s file path')
    parser.add_argument('--coco-label', default=None,
                        help='CoCo3 assembly label (default: <label>_coco3)')
    parser.add_argument('--start-col', type=int, default=0,
                        help='Apple II screen pixel column of sprite left edge '
                             '(required for correct isolated-pixel color). '
                             'Karateka: Logo1=119, Logo2=84.')
    args = parser.parse_args()

    coco_label = args.coco_label or (args.label + '_coco3')
    raw = extract_sprite_bytes(args.source, args.label)
    height = raw[0]
    apple_width = raw[1]
    expected_data = height * apple_width
    bitmap_bytes = raw[2:]

    if len(bitmap_bytes) < expected_data:
        print(f"WARNING: expected {expected_data} bitmap bytes, got {len(bitmap_bytes)}; padding")
        bitmap_bytes += [0] * (expected_data - len(bitmap_bytes))

    coco3_bitmap, coco3_width = convert_sprite_to_coco3(bitmap_bytes, height, apple_width,
                                                         args.start_col)

    # Trim trailing and leading all-zero byte columns (P2.3a.11-followup-2)
    original_width = coco3_width
    if coco3_width > 0:
        col_has_content = [
            any(coco3_bitmap[row * coco3_width + col] != 0 for row in range(height))
            for col in range(coco3_width)
        ]
        L = next((i for i in range(coco3_width) if col_has_content[i]), 0)
        R = next((i for i in range(coco3_width - 1, -1, -1) if col_has_content[i]), coco3_width - 1)
        trimmed_width = R - L + 1
        leading_stripped = L
        trailing_stripped = coco3_width - R - 1
        if trimmed_width < coco3_width:
            new_bitmap = bytearray()
            for row in range(height):
                new_bitmap.extend(coco3_bitmap[row * coco3_width + L:row * coco3_width + R + 1])
            coco3_bitmap = new_bitmap
            coco3_width = trimmed_width
            print(f"Trim: original_W={original_width} lead_stripped={leading_stripped} "
                  f"trail_stripped={trailing_stripped} -> trimmed_W={coco3_width}")

    source_ref = f"{os.path.basename(args.source)}"
    write_s_file(args.output, coco_label, height, coco3_width, coco3_bitmap,
                 source_ref, args.label, args.start_col)

    expected_size = height * coco3_width
    print(f"Converted '{args.label}': H={height} apple_W={apple_width} "
          f"coco3_W={coco3_width} -> {expected_size} bitmap bytes")
    print(f"Written: {args.output}")


if __name__ == '__main__':
    main()
