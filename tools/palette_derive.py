"""
palette_derive.py — CoCo3 GIME palette derivation for karateka-coco3.

Outputs a 4-byte binary: one GIME color code (0-63) per palette entry.

Palette index order matches the C# reference converter and sprite_convert.py:
  [ref: /mnt/c/Projects/appleiitococo3 - Copy/MainForm.cs coco3Palette4]
  0: Black   — background (GIME 0)
  1: Orange  — isolated odd-column pixel (GIME 44 = $2C)
  2: Blue    — isolated even-column pixel (GIME 3 = $03)
  3: White   — adjacent pixel pair (GIME 63 = $3F)

GIME 6-bit color format (bits 5-4=GG, 3-2=RR, 1-0=BB; each pair → 0,85,170,255):
  [ref: docs/project/karateka-coco3-design-v0.1.md §5.1 Gate K.1.2 (GIME target)]
  [no-ref: exact GIME §3.2 color codes — verify from GIME-RM during P3 HAL]
  Black  = GIME 0  (GG=0,RR=0,BB=0) = (0,0,0)         exact
  White  = GIME 63 (GG=3,RR=3,BB=3) = (255,255,255)   exact
  Blue   = GIME 3  (GG=0,RR=0,BB=3) = (0,0,255)       exact
  Orange = GIME 44 (GG=2,RR=3,BB=0) = (255,170,0) ≈ (255,140,0)
           [approximation: GIME cannot represent R=255,G=140; nearest is GG=2=170]

Per-scene mechanism: content/palettes/ holds one .bin per palette.
"""

import argparse

# C# reference palette order: Black, Orange, Blue, White
# [ref: MainForm.cs coco3Palette4]
SCENE1_PALETTE = [
    0,    # 0: Black  = GIME 0   (background)
    44,   # 1: Orange = GIME 44  (GG=2,RR=3,BB=0) ≈ RGB(255,170,0); nearest to C# (255,140,0)
    3,    # 2: Blue   = GIME 3   (GG=0,RR=0,BB=3) = RGB(0,0,255)   exact
    63,   # 3: White  = GIME 63  (GG=3,RR=3,BB=3) = RGB(255,255,255) exact
]

GLOBAL_PALETTE = SCENE1_PALETTE  # scene1 is the default (global v1.0 palette)

PRESETS = {
    'global': GLOBAL_PALETTE,
    'scene1': SCENE1_PALETTE,
}


def write_palette_bin(path, palette):
    with open(path, 'wb') as f:
        f.write(bytes(palette))
    print(f"Palette written: {path} ({len(palette)} entries: {palette})")


def write_palette_s(path, palette, label='initial_palette_coco3'):
    """Write palette as lwasm .s file (fcb format)."""
    lines = [
        f"* {path}",
        f"* CoCo3 GIME 4-color palette (scene1 / global v1.0).",
        f"* Index order: 0=Black 1=Orange 2=Blue 3=White",
        f"* [ref: /mnt/c/Projects/appleiitococo3 - Copy/MainForm.cs coco3Palette4]",
        f"",
        f"{label}:",
        f"        fcb     {','.join(str(c) for c in palette)}"
        f"  ; GIME codes: black,orange(~),blue,white",
    ]
    with open(path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print(f"Palette written: {path}")


def main():
    parser = argparse.ArgumentParser(description='CoCo3 GIME palette derivation')
    parser.add_argument('--output', required=True, help='Output .s or .bin path')
    parser.add_argument('--palette', default='scene1', choices=list(PRESETS.keys()),
                        help='Palette preset (default: scene1)')
    args = parser.parse_args()

    palette = PRESETS[args.palette]
    if args.output.endswith('.s'):
        write_palette_s(args.output, palette)
    else:
        write_palette_bin(args.output, palette)


if __name__ == '__main__':
    main()
