"""
sprite_visualize.py — Render CoCo3 4-color packed sprite to PNG.

Independent decoder for the CoCo3 side of the karateka-coco3
sprite conversion pipeline. Used with sprite_render_apple2.py to
verify conversion correctness.

CoCo3 4-color: 4 pixels per byte, 2 bits each, MSB-first per pixel.
Reads either a binary (.bin) or a lwasm .s file (fcb directives).

Palette — matches C# reference converter:
  [ref: /mnt/c/Projects/appleiitococo3 - Copy/MainForm.cs coco3Palette4]
  0 = Black   (0,   0,   0)   background
  1 = Orange  (255, 140, 0)   odd-column isolated pixel
  2 = Blue    (0,   0, 255)   even-column isolated pixel
  3 = White   (255, 255, 255) adjacent pixel pair

Note: updated from prior placeholder (White/Black/Red/Blue) to match C# reference.
Red in output now indicates an encoding error (value > 3); no valid conversion
produces Red.
"""

import argparse
import re
import sys

try:
    from PIL import Image
except ImportError:
    print("ERROR: PIL/Pillow required. Install: pip install Pillow")
    sys.exit(1)

# [ref: MainForm.cs coco3Palette4 — Black, Orange, Blue, White]
PALETTE = {
    0: (  0,   0,   0),   # Black   — background
    1: (255, 140,   0),   # Orange  — odd column isolated
    2: (  0,   0, 255),   # Blue    — even column isolated
    3: (255, 255, 255),   # White   — adjacent pair
}
_INVALID_COLOR = (255, 0, 0)  # Red — encoding error, should not appear


def _parse_fcb_directive(line):
    """Parse a single lwasm fcb line; return list of byte values."""
    line = re.sub(r';.*$', '', line)
    m = re.search(r'\bfcb\b\s+(.+)$', line, re.IGNORECASE)
    if not m:
        return []
    values = []
    for v in re.split(r',\s*', m.group(1).strip()):
        v = v.strip()
        if not v:
            continue
        if v.startswith('$'):
            values.append(int(v[1:], 16))
        elif re.match(r'^\d+$', v):
            values.append(int(v))
    return values


def _load_s_file(path):
    """Load CoCo3 sprite from a lwasm .s file (fcb format). Returns raw bytes."""
    raw = []
    collecting = False
    with open(path) as f:
        for line in f:
            stripped = line.strip()
            # Start collecting after any non-comment, non-blank line containing 'fcb'
            if not collecting:
                if re.search(r'\bfcb\b', stripped, re.IGNORECASE) and not stripped.startswith('*'):
                    collecting = True
            if collecting:
                if stripped.startswith('*') or stripped == '':
                    continue
                raw.extend(_parse_fcb_directive(stripped))
    return raw


def _load_binary(path):
    """Load CoCo3 sprite from a binary file. Returns raw bytes as a list."""
    with open(path, 'rb') as f:
        return list(f.read())


def load_sprite(path):
    """Auto-detect format (.s vs binary) and load sprite data."""
    if path.endswith('.s'):
        raw = _load_s_file(path)
    else:
        raw = _load_binary(path)
    if len(raw) < 2:
        raise ValueError(f"File too short: {path}")
    height = raw[0]
    coco3_width = raw[1]
    bitmap = raw[2:]
    if len(bitmap) < height * coco3_width:
        raise ValueError(
            f"Bitmap mismatch: expected {height * coco3_width}, got {len(bitmap)}")
    return height, coco3_width, bitmap


def render(height, coco3_width, bitmap, output_path, scale=8):
    """Render CoCo3 packed sprite using the C# reference palette."""
    width_pixels = coco3_width * 4
    img = Image.new('RGB', (width_pixels * scale, height * scale), PALETTE[0])
    px = img.load()

    for row in range(height):
        for b in range(coco3_width):
            byte_val = bitmap[row * coco3_width + b]
            for pix in range(4):
                shift = 6 - pix * 2
                idx = (byte_val >> shift) & 0b11
                color = PALETTE.get(idx, _INVALID_COLOR)
                x0 = (b * 4 + pix) * scale
                y0 = row * scale
                for dy in range(scale):
                    for dx in range(scale):
                        px[x0 + dx, y0 + dy] = color

    img.save(output_path)
    print(f"CoCo3 render:    {output_path}  ({width_pixels}×{height} logical px, scale {scale}×)")


def main():
    p = argparse.ArgumentParser(description='Render CoCo3 sprite binary or .s to PNG')
    p.add_argument('--source', required=True, help='.bin or .s file')
    p.add_argument('--output', required=True)
    p.add_argument('--scale', type=int, default=8)
    args = p.parse_args()
    height, coco3_width, bitmap = load_sprite(args.source)
    render(height, coco3_width, bitmap, args.output, args.scale)


if __name__ == '__main__':
    main()
