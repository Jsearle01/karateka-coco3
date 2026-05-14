"""
sprite_convert.py — Apple II hi-res sprite → CoCo3 4-color packed bytes.

Reads a karateka_dissasembly_claude src/*.s file, extracts the sprite
record starting at a given ca65 label, and writes a CoCo3-ready binary.

Apple II sprite format (as documented in sprite_data_0400.s):
  byte 0: height (rows)
  byte 1: width (bytes per row; 7 pixels per byte, bit 7 = color-set)
  bytes 2+: bitmap data, row-major

CoCo3 output format:
  byte 0: height
  byte 1: coco3_width (bytes per row; 4 pixels per byte, 2 bits each)
  bytes 2+: packed bitmap, row-major, MSB-first per pixel

Color mapping (v1.0 monochrome):
  Apple II pixel ON  (bits 0-6) → CoCo3 palette index 1 (foreground)
  Apple II pixel OFF             → CoCo3 palette index 0 (background)
"""

import re
import sys
import argparse


def parse_byte_directive(line):
    """Parse a single .byte line; return list of byte values."""
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
            # Stop at the next label (any identifier followed by colon)
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*\s*:', line):
                break
            raw.extend(parse_byte_directive(line))

    if not collecting:
        raise ValueError(f"Label '{label}' not found in {source_path}")
    if len(raw) < 2:
        raise ValueError(f"Label '{label}': too few bytes ({len(raw)}) to form a valid sprite header")

    return raw


def convert_sprite_to_coco3(apple_ii_bytes, height, apple_width_bytes):
    """
    Apple II sprite bitmap → CoCo3 4-color packed bytes.

    Apple II: width_bytes bytes per row, 7 pixels per byte
              (bit 7 is color-set selector; ignored for v1.0)
    CoCo3:    ceil(width_pixels/4) bytes per row, 4 pixels per byte
              at 2 bits each, MSB-first per pixel

    Color mapping (v1.0 monochrome):
      Apple II pixel ON  → CoCo3 palette 1
      Apple II pixel OFF → CoCo3 palette 0
    """
    width_pixels = apple_width_bytes * 7
    coco3_width = (width_pixels + 3) // 4
    coco3_bitmap = bytearray()

    for row in range(height):
        row_pixels = []
        for b in range(apple_width_bytes):
            apple_byte = apple_ii_bytes[row * apple_width_bytes + b]
            for bit in range(7):
                row_pixels.append((apple_byte >> bit) & 1)

        for byte_idx in range(coco3_width):
            packed = 0
            for pix_idx in range(4):
                src = byte_idx * 4 + pix_idx
                if src < len(row_pixels):
                    packed |= row_pixels[src] << (6 - pix_idx * 2)
            coco3_bitmap.append(packed)

    return coco3_bitmap, coco3_width


def main():
    parser = argparse.ArgumentParser(description='Apple II sprite → CoCo3 converter')
    parser.add_argument('--source', required=True, help='Path to ca65 .s source file')
    parser.add_argument('--label', required=True, help='Starting label of the sprite record')
    parser.add_argument('--output', required=True, help='Output binary path')
    args = parser.parse_args()

    raw = extract_sprite_bytes(args.source, args.label)
    height = raw[0]
    apple_width = raw[1]
    expected_data = height * apple_width
    bitmap_bytes = raw[2:]

    if len(bitmap_bytes) < expected_data:
        print(f"WARNING: expected {expected_data} bitmap bytes, got {len(bitmap_bytes)}; padding with zeros")
        bitmap_bytes += [0] * (expected_data - len(bitmap_bytes))

    coco3_bitmap, coco3_width = convert_sprite_to_coco3(bitmap_bytes, height, apple_width)

    output = bytes([height, coco3_width]) + bytes(coco3_bitmap)
    with open(args.output, 'wb') as f:
        f.write(output)

    expected_size = 2 + height * coco3_width
    print(f"Converted '{args.label}': H={height} apple_W={apple_width} coco3_W={coco3_width} "
          f"-> {len(output)} bytes (expected {expected_size})")


if __name__ == '__main__':
    main()
