"""
palette_derive.py — CoCo3 GIME palette derivation for karateka-coco3.

Outputs a 4-byte binary: one GIME color code (0-63) per palette entry.

Index semantics (v1.0 global palette):
  0: background  = GIME black (0)
  1: foreground  = GIME white (63)
  2: reserved    = mid-gray-1 (21)
  3: reserved    = mid-gray-2 (42)

Per-scene mechanism: content/palettes/ directory holds one .bin per
palette. v1.0 build uses global.bin only. Future scene-specific files
(scene1.bin, throne_room.bin, etc.) selected at scene-load time.
"""

import argparse

GLOBAL_PALETTE = [
    0,    # 0: background = black
    63,   # 1: foreground = white
    21,   # 2: reserved = mid-gray-1
    42,   # 3: reserved = mid-gray-2
]


def write_palette(path, palette=GLOBAL_PALETTE):
    with open(path, 'wb') as f:
        f.write(bytes(palette))
    print(f"Palette written: {path} ({len(palette)} entries: {palette})")


def main():
    parser = argparse.ArgumentParser(description='CoCo3 GIME palette derivation')
    parser.add_argument('--output', required=True, help='Output .bin path')
    parser.add_argument('--palette', default='global', choices=['global'],
                        help='Palette preset to use (default: global)')
    args = parser.parse_args()
    write_palette(args.output)


if __name__ == '__main__':
    main()
