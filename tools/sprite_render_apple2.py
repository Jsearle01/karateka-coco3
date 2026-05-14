"""
sprite_render_apple2.py — Render Apple II hi-res sprite source to PNG.

Independent decoder for the Apple II side of the karateka-coco3
sprite conversion pipeline. Used with sprite_visualize.py to verify
conversion correctness via visual comparison.

Apple II hi-res: 7 pixels per byte (bits 0-6); bit 7 = color-set
selector (ignored for v1.0 monochrome). Pixel ON = black, OFF = white.
"""

import argparse
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERROR: PIL/Pillow required. Install: pip install Pillow")
    sys.exit(1)


def parse_byte_directive(line):
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


def extract_sprite(source_path, label):
    with open(source_path) as f:
        lines = f.readlines()

    label_re = re.compile(r'^' + re.escape(label) + r'\s*:')
    collecting = False
    raw = []

    for line in lines:
        if label_re.match(line):
            collecting = True
            continue
        if collecting:
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*\s*:', line):
                break
            raw.extend(parse_byte_directive(line))

    if not collecting:
        raise ValueError(f"Label '{label}' not found")
    if len(raw) < 2:
        raise ValueError(f"Too few bytes for '{label}'")

    height, width_bytes = raw[0], raw[1]
    bitmap = raw[2:2 + height * width_bytes]
    return height, width_bytes, bitmap


def render(height, width_bytes, bitmap, output_path, scale=8):
    width_pixels = width_bytes * 7
    img = Image.new('RGB', (width_pixels * scale, height * scale), (255, 255, 255))
    px = img.load()

    for row in range(height):
        for b in range(width_bytes):
            byte_val = bitmap[row * width_bytes + b]
            for bit in range(7):
                on = (byte_val >> bit) & 1
                color = (0, 0, 0) if on else (255, 255, 255)
                x0 = (b * 7 + bit) * scale
                y0 = row * scale
                for dy in range(scale):
                    for dx in range(scale):
                        px[x0 + dx, y0 + dy] = color

    img.save(output_path)
    print(f"Apple II render: {output_path}  ({width_pixels}×{height} logical px, scale {scale}×)")


def main():
    p = argparse.ArgumentParser(description='Render Apple II sprite to PNG')
    p.add_argument('--source', required=True)
    p.add_argument('--label',  required=True)
    p.add_argument('--output', required=True)
    p.add_argument('--scale', type=int, default=8)
    args = p.parse_args()

    height, width_bytes, bitmap = extract_sprite(args.source, args.label)
    render(height, width_bytes, bitmap, args.output, args.scale)


if __name__ == '__main__':
    main()
