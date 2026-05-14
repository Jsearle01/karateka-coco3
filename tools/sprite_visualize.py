"""
sprite_visualize.py — Render CoCo3 4-color packed sprite to PNG.

Independent decoder for the CoCo3 side of the karateka-coco3
sprite conversion pipeline. Used with sprite_render_apple2.py to
verify conversion correctness.

CoCo3 4-color: 4 pixels per byte, 2 bits each, MSB-first per pixel.
Palette: 0=white(bg), 1=black(fg), 2=red(reserved), 3=blue(reserved).
Red or blue in output indicates misuse of reserved palette indices.
"""

import argparse
import sys

try:
    from PIL import Image
except ImportError:
    print("ERROR: PIL/Pillow required. Install: pip install Pillow")
    sys.exit(1)

PALETTE = {
    0: (255, 255, 255),  # background = white
    1: (0,   0,   0  ),  # foreground = black
    2: (255, 0,   0  ),  # reserved — should not appear in v1.0
    3: (0,   0,   255),  # reserved — should not appear in v1.0
}


def render(sprite_path, output_path, scale=8):
    with open(sprite_path, 'rb') as f:
        data = f.read()

    if len(data) < 2:
        raise ValueError("File too short")

    height     = data[0]
    coco3_width = data[1]
    bitmap     = data[2:]

    if len(bitmap) != height * coco3_width:
        raise ValueError(f"Bitmap mismatch: expected {height * coco3_width}, got {len(bitmap)}")

    width_pixels = coco3_width * 4
    img = Image.new('RGB', (width_pixels * scale, height * scale), (255, 255, 255))
    px = img.load()

    for row in range(height):
        for b in range(coco3_width):
            byte_val = bitmap[row * coco3_width + b]
            for pix in range(4):
                shift = 6 - pix * 2
                idx = (byte_val >> shift) & 0b11
                color = PALETTE[idx]
                x0 = (b * 4 + pix) * scale
                y0 = row * scale
                for dy in range(scale):
                    for dx in range(scale):
                        px[x0 + dx, y0 + dy] = color

    img.save(output_path)
    print(f"CoCo3 render:    {output_path}  ({width_pixels}×{height} logical px, scale {scale}×)")


def main():
    p = argparse.ArgumentParser(description='Render CoCo3 sprite binary to PNG')
    p.add_argument('--source', required=True)
    p.add_argument('--output', required=True)
    p.add_argument('--scale', type=int, default=8)
    args = p.parse_args()
    render(args.source, args.output, args.scale)


if __name__ == '__main__':
    main()
