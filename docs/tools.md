# karateka-coco3 — asset conversion tooling

Python tooling for converting Apple II assets from
karateka_dissasembly_claude src/ into CoCo3-ready binaries.

## Sprite converter

`tools/sprite_convert.py` — Apple II hi-res sprite → CoCo3 4-color
packed bytes.

Usage:

    python3 tools/sprite_convert.py \
        --source ../karateka_dissasembly_claude/src/<file>.s \
        --label <sprite_label> \
        --output content/sprites/<output>.bin

Conversion: Apple II hi-res 7-pixels-per-byte → CoCo3 4-pixels-per-byte
(2 bits each, MSB-first). High bit of each Apple II byte (color-set
selector) is ignored for v1.0 monochrome use.

Color mapping (v1.0): pixel ON → palette index 1 (foreground);
pixel OFF → palette index 0 (background).

Output format: height byte + coco3_width byte + packed bitmap.

## Sound converter

`tools/sound_convert.py` — Apple II PCM/tone data → CoCo3 6-bit
DAC format.

Usage:

    python3 tools/sound_convert.py \
        --source ../karateka_dissasembly_claude/src/sound_data_0e00.s \
        --section [pcm|tone] \
        --output content/sound/<output>.bin

PCM mode: right-shift 8-bit unsigned → 6-bit (lose 2 LSBs; max output 63).
Tone mode: pass-through (data-driven format compatible with CoCo3).

## Palette derivation

`tools/palette_derive.py` — produces 4-color global GIME palette.

Usage:

    python3 tools/palette_derive.py --output content/palettes/global.bin

Output: 4 bytes (GIME color codes 0-63): black (0), white (63),
mid-gray-1 (21), mid-gray-2 (42).

Per-scene palette mechanism: scaffolded via content/palettes/ directory.
v1.0 uses global.bin only. Future scene-specific palettes selected at
scene-load time by engine code.

## Sprite visualization

Two independent decoders for visual verification of conversion
correctness.

`tools/sprite_render_apple2.py` — render Apple II source sprite to PNG.

`tools/sprite_visualize.py` — render CoCo3 converted sprite binary to PNG.

Usage:

    python3 tools/sprite_render_apple2.py \
        --source ../karateka_dissasembly_claude/src/<file>.s \
        --label <sprite_label> \
        --output viz/<name>_apple2.png

    python3 tools/sprite_visualize.py \
        --source content/sprites/<name>.bin \
        --output viz/<name>_coco3.png

Visual comparison: open both PNGs side-by-side. Conversion is verified
if shapes match. The CoCo3 image will be 2 pixels wider on the right
when Apple II width (multiples of 7px) doesn't divide evenly into CoCo3
bytes (multiples of 4px) — this is expected padding.

Color scheme:
- Apple II render: black = pixel ON, white = pixel OFF
- CoCo3 render: palette 0 = white, 1 = black, 2 = red, 3 = blue
  (red/blue indicate misuse of reserved palette indices)

Both tools support `--scale` (default 8×) for pixel zoom.

## Dependencies

Python 3.12.3. Pillow required for visualization tools only
(`pip install Pillow`). Converters use standard library only.

## Testing

Unit tests in `tests/`. Run with:

    python3 -m unittest discover tests/
