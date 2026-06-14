# Session: 2026-05-13 — P1.2 asset conversion tooling

## What landed

Three Python tools for asset conversion:
- tools/sprite_convert.py — Apple II hi-res → CoCo3 4-color
- tools/sound_convert.py — Apple II PCM/tone → CoCo3 6-bit DAC
- tools/palette_derive.py — global 4-color palette

Sample conversions validate pipeline:
- content/sprites/sample.bin (sprite_0400, letter 'a', 42 bytes)
- content/sound/pcm_samples.bin (256 bytes PCM, max=63 confirmed)
- content/sound/tone_records.bin (256 bytes tone records, pass-through)
- content/palettes/global.bin (4 bytes: [0, 63, 21, 42])

Tests in tests/:
- test_sprite_convert.py (9 tests)
- test_sound_convert.py (4 tests)
All 13 PASS.

Documentation: docs/project/tools.md

## Per-scene palette decision

Per design doc Gate K.1.1 + user direction (2026-05-13): per-scene
palette mechanism scaffolded via content/palettes/ directory
structure but only global.bin populated for v1.0. Karateka's
visual content is effectively monochrome (Apple II hi-res with
minimal color use). Per-scene infrastructure preserved for
pop-coco3 HAL compatibility but minimally exercised.

## Sprite format notes

Apple II hi-res: 7 pixels per byte, high bit = color-set selector.
For v1.0 monochrome conversion, high bit is ignored.

CoCo3 320×192×4: 4 pixels per byte (2 bits each), MSB-first per
pixel. Per-row byte count = ceil(width_pixels / 4).

Verified: sprite_0400 (letter 'a', H=10 W=2) → H=10 coco3_W=4,
42 bytes. Row pixel values spot-checked against source .byte data.

Bulk conversion of all sprite banks deferred to P4.

## Pattern library note

No existing D-hal patterns cover sprite-pixel-packing or PCM
downsampling. Candidate future patterns:
- Apple II 7-px/byte → CoCo3 4-px/byte packing algorithm
- 8-bit → 6-bit PCM right-shift for CoCo3 DAC

Will contribute to 6502-6809-conversion-patterns when patterns
stabilize across P2 work.

## Calibration tracking

Task 3 of calibration phase complete.

## Open items for next session

- P1.3 (HAL contract) is the natural next task
- Bulk asset conversion (all sprite banks, all sound assets)
  deferred to P4
