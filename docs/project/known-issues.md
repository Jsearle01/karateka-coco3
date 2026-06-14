# Known Issues

Tracked defects in the CoCo3 port and their resolution status. Most recent first.

---

## RESOLVED — Sprite blue/orange column-parity reversal (cast)
**Date:** 2026-06-14 · **Area:** `tools/sprite_convert.py`, scene-5 cast content

### Symptom
Several scene-5 cast sprites rendered with blue and orange **swapped** versus the
Apple II original (e.g. Akuma's robe/head came out blue instead of orange; the
eagle's body came out orange instead of blue).

### Root cause
The converter derives each chroma pixel's hue (orange vs blue) from the Apple II
**screen-column parity** of that pixel: for a palette-1 (orange/blue) dot,
`even screen column → blue (index 2)`, `odd → orange (index 1)`. The screen column
is computed as `start_col + col`, so the entire hue assignment hinges on the
`--start-col` passed at conversion time. Cast sprites converted at an assumed
column origin whose parity differed from the sprite's true on-screen column came
out with **every** blue/orange reversed. Because CoCo3 is palette-indexed (not
parity-derived like Apple II hi-res), this reversal is baked permanently into the
converted data — it is not a runtime artifact.

### Fix
1. Added `--flip-parity` to `tools/sprite_convert.py` — XORs the parity test
   (`(screen_col % 2 == 0) ^ parity_flip`), a **color-only** swap with no shape
   change. Use when a sprite was converted at the wrong column parity.
2. For the scene-5 `fig_*` cast (converted "by address" with no clean source `.s`),
   added `tools/flip_parity_inplace.py`, which swaps the 2-bit pixel fields
   `01<->10` directly on an already-converted `.s`. Verified **byte-identical** to
   re-running the converter with `--flip-parity` (oracle: `eagle_body_9FC4`).

### Verification
Jay visual gate against Apple II reference snapshots of the imprisonment scene
(`C:\karateka-capture\snap\apple2e\0097-0102.png`, frames 4000-6000, `$3D=$01`).
All flagged sprites flipped and re-confirmed: Akuma (gloat + throne, orange),
eagle body (blue), princess body/walk/poses, guard, and floor/props. Cast colors
PASS; remaining sprites may surface as the full scene is assembled.

---

## RESOLVED — Karateka logo vertical-line striping
**Date:** 2026-06-13/14 · **Area:** `tools/sprite_convert.py` color-cell fill, scene 3

### Symptom
The KARATEKA title logo (scene 3) showed thin vertical black lines striping the
otherwise-solid letterforms.

### Root cause
Apple II hi-res color-cell fill: a black dot flanked by the same chroma on both
sides reads as solid color. The converter was leaving those interior gap dots
black, producing vertical striping in solid letter strokes.

### Fix
Color-cell fill in `convert_sprite_to_coco3` fills a Black dot when flanked by the
same chroma (index 1 or 2) on both sides. The title logo content
(`content/title/title_*/converted.s`) was re-converted through the fixed converter; the
only diff is gap-filled bytes (e.g. R-A connector row `$11 -> $15`) — geometry
unchanged. The R-A connector position was then hand-tuned to byte 32 / row 111.

### Verification
Jay visual gate, scene 3: striping gone, connector position PASS.
