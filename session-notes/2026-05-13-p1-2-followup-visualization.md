# Session: 2026-05-13 — P1.2 follow-up: sprite visualization verification

## What landed

Two independent sprite renderers:
- tools/sprite_render_apple2.py — Apple II hi-res → PNG
- tools/sprite_visualize.py — CoCo3 packed bytes → PNG

Sample sprite from P1.2 (label: sprite_0400, letter 'a', H=10 W=2)
rendered from both sides. Visual comparison: MATCH.

Apple II: 14×10 logical px (2 bytes × 7px). CoCo3: 16×10 logical
px (4 bytes × 4px). 2-pixel right-side padding from ceil(14/4)=4
is expected and correct. Glyph shape and silhouette identical.

## Methodology lesson

P1.2's "pixel-by-pixel verification" compared Apple II source bytes
against CoCo3 output bytes using the same decoder assumptions for
both sides. This is self-consistency verification, not correctness
verification. A converter with wrong bit-ordering or wrong palette
mapping would still pass because the same wrong assumptions apply
to both decoded sides.

Correctness verification requires independent decoders:
- Apple II decoder: 7 pixels per byte (bits 0-6), bit 7 ignored
- CoCo3 decoder: 4 pixels per byte, 2 bits each, MSB-first
- Visual outputs compared by human observer who knows the content

Going forward: sprite conversion verification uses both renderers.
Single-decoder pixel-by-pixel is inadequate for claims of
correctness.

## Calibration tracking

Task 4 of calibration phase complete.

## Open items

- Bulk visualization of all sprite banks is P4 work
- The same tools can serve pre-port visual review of all
  karateka_dissasembly_claude sprite banks
